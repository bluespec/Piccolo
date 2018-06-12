// Copyright (c) 2016-2018 Bluespec, Inc. All Rights Reserved

package CPU;

// ================================================================
// This is the "Piccolo_V3" CPU, implementing the RISC-V ISA.
// RV32I, Privilege Levels U and M.
// This is a simple 3-stage in order pipeline.

// ================================================================
// Exports

export mkCPU;

// ================================================================
// BSV library imports

import Memory       :: *;
import FIFOF        :: *;
import SpecialFIFOs :: *;
import GetPut       :: *;
import ClientServer :: *;
import Connectable  :: *;
import ConfigReg    :: *;

// ----------------
// BSV additional libs

import Cur_Cycle  :: *;
import GetPut_Aux :: *;
import Semi_FIFOF :: *;

// ================================================================
// Project imports

import AXI4_Lite_Types :: *;

import ISA_Decls :: *;

`ifdef INCLUDE_TANDEM_VERIF
import TV_Info   :: *;
`endif

import GPR_RegFile :: *;
import CSR_RegFile :: *;
import CPU_Globals :: *;
import CPU_IFC     :: *;

import CPU_Stage1 :: *;
import CPU_Stage2 :: *;
import CPU_Stage3 :: *;

import Near_Mem_IFC :: *;    // Caches or TCM

`ifdef Near_Mem_Caches
import Near_Mem_Caches :: *;
`endif

`ifdef Near_Mem_TCM
import Near_Mem_TCM :: *;
`endif

`ifdef INCLUDE_GDB_CONTROL
import Debug_Module :: *;
`endif

// ================================================================
// Major States of CPU

typedef enum {CPU_RESET1,
	      CPU_RESET2,

`ifdef INCLUDE_GDB_CONTROL
	      CPU_GDB_PAUSING,  // On GDB breakpoint, while waiting for fence completion
	      CPU_DEBUG_MODE,   // Stopped for debugger
`endif
	      CPU_RUNNING,      // Normal operation
	      CPU_CSRRX_STALL,
	      CPU_FENCE_I,      // While waiting for FENCE.I to complete in Near_Mem
	      CPU_FENCE,        // While waiting for FENCE to complete in Near_Mem

	      CPU_WFI_PAUSED    // On WFI pause
   } CPU_State
deriving (Eq, Bits, FShow);

function Bool fn_is_running (CPU_State  cpu_state);
   return (   (cpu_state == CPU_RUNNING)
	   || (cpu_state == CPU_FENCE_I)
	   || (cpu_state == CPU_FENCE)
	   );
endfunction

// ================================================================

(* synthesize *)
module mkCPU #(parameter Bit #(64)  pc_reset_value)  (CPU_IFC);

   // ----------------
   // General purpose registers and CSRs
   GPR_RegFile_IFC  gpr_regfile  <- mkGPR_RegFile;
   CSR_RegFile_IFC  csr_regfile  <- mkCSR_RegFile;

   // Near mem (caches or TCM, for example)
   Near_Mem_IFC  near_mem <- mkNear_Mem;

   // ----------------
   // For debugging

`ifdef CPU_VERBOSITY_1
   Bit #(4) initial_verbosity = 1;
`else
   Bit #(4) initial_verbosity = 0;
`endif

   // Verbosity: 0=quiet; 1=instruction trace; 2=more detail
   Reg #(Bit #(4))  cfg_verbosity <- mkConfigReg (initial_verbosity);

   // Verbosity is 0 as long as # of instrs retired is <= cfg_logdelay
   Reg #(Bit #(64))  cfg_logdelay <- mkConfigReg (0);

   // Current verbosity, taking into account log delay
   Bit #(4)  cur_verbosity = (  (csr_regfile.read_csr_minstret < cfg_logdelay)
			      ? 0
			      : cfg_verbosity);

   // 'inum': instruction number.
   // Should be equal to eventual 'instret' (instructions retired) number
   // for an instruction.

   Reg #(Bit #(64))  rg_inum <- mkRegU;

   // ----------------
   // Major CPU states
   Reg #(CPU_State)  rg_state    <- mkReg (CPU_RESET1);
   Reg #(Priv_Mode)  rg_cur_priv <- mkRegU;

   // ----------------
   // Pipeline stages
   CPU_Stage3_IFC stage3 <- mkCPU_Stage3 (cur_verbosity, gpr_regfile, csr_regfile);
   CPU_Stage2_IFC stage2 <- mkCPU_Stage2 (cur_verbosity, csr_regfile, near_mem.dmem);
   CPU_Stage1_IFC  stage1 <- mkCPU_Stage1 (cur_verbosity,
					   gpr_regfile,
					   csr_regfile,
					   near_mem.imem,
					   stage2.out.bypass,
					   stage3.out.bypass,
					   rg_cur_priv);

   // ----------------
   // Halt requests (interrupts, debugger stop-request, or dcsr.step step-request).
   // We set this flag on an instruction Fetch and handle it on the next instruction-fetch.
   // When this flag is set, Stage1 is "frozen", i.e., its instruction
   // is not moved forward.  Once Stage2 and Stage3 have drained
   // (OSTATUS_EMPTY), the halt-request is handled.

   Reg #(Bool)  rg_halt <- mkReg (False);

   // Interrupt pending based on current priv, mstatus.ie, mie and mip registers
   Bool interrupt_pending = isValid (csr_regfile.interrupt_pending (rg_cur_priv));

   // ----------------
   // Reset requests and responses

   FIFOF #(Token)  f_reset_reqs <- mkFIFOF;
   FIFOF #(Token)  f_reset_rsps <- mkFIFOF;

   // ----------------
   // Communication to/from External debug module

`ifdef INCLUDE_GDB_CONTROL

   // Debugger run-control
   FIFOF #(Bool)  f_run_halt_reqs <- mkFIFOF;
   FIFOF #(Bool)  f_run_halt_rsps <- mkFIFOF;

   Reg #(Bool)  rg_stop_req      <- mkReg (False);    // stop-request from debugger
   Reg #(Bool)  rg_step_req      <- mkReg (False);    // step-request from dcsr.step
   Reg #(Bool)  rg_self_stop_req <- mkReg (False);    // self-stop-request on infinite loop

   // Debugger GPR read/write request/response
   FIFOF #(MemoryRequest  #(5,  XLEN)) f_gpr_reqs <- mkFIFOF1;
   FIFOF #(MemoryResponse #(    XLEN)) f_gpr_rsps <- mkFIFOF1;

   // Debugger CSR read/write request/response
   FIFOF #(MemoryRequest  #(12, XLEN)) f_csr_reqs <- mkFIFOF1;
   FIFOF #(MemoryResponse #(    XLEN)) f_csr_rsps <- mkFIFOF1;

`endif

   // ----------------
   // Tandem Verification

`ifdef INCLUDE_TANDEM_VERIF
   FIFOF #(Info_CPU_to_Verifier)  f_to_verifier <- mkFIFOF;
`endif

   // ================================================================
   // Debugging: print instruction trace info

   function fa_emit_instr_trace (inum, pc, instr, priv);
      action
	 if (cur_verbosity == 1)
	    $display ("inum:%0d  PC:0x%0h  instr:0x%0h  priv:%0d", inum, pc, instr, priv);
      endaction
   endfunction

   // ================================================================
   // CPI measurement in each 'run' (from Debug Mode pause to Debug Mode pause)

   Reg #(Bit #(64))  rg_start_CPI_cycles <- mkRegU;
   Reg #(Bit #(64))  rg_start_CPI_instrs <- mkRegU;

   function Action fa_report_CPI;
      action
	 Bit #(64) delta_CPI_cycles = csr_regfile.read_csr_mcycle   - rg_start_CPI_cycles;
	 Bit #(64) delta_CPI_instrs = csr_regfile.read_csr_minstret - rg_start_CPI_instrs;
	 
	 // Make delta_CPI_instrs at least 1, to avoid divide-by-zero
	 if (delta_CPI_instrs == 0)
	    delta_CPI_instrs = delta_CPI_instrs + 1;

	 // Report CPI to 1 decimal place.
	 let x = (delta_CPI_cycles * 10) / delta_CPI_instrs;
	 let cpi     = x / 10;
	 let cpifrac = x % 10;
	 $display ("CPI: %0d.%0d = (%0d/%0d) since last 'continue'",
		   cpi, cpifrac, delta_CPI_cycles, delta_CPI_instrs);
      endaction
   endfunction

   // ================================================================
   // Feed a new PC into Stage1
   // Feed a new PC into IMem (to do an instruction fetch).
   // Set rg_halt on external interrupt request, debugger stop request,
   // or dcsr.step step request

   function Action fa_start_ifetch (Word next_pc, Priv_Mode priv);
      action
	 // Initiate the fetch
	 Bit #(1) sstatus_SUM = (csr_regfile.read_sstatus) [18];
	 Bit #(1) mstatus_MXR = (csr_regfile.read_mstatus) [19];
	 stage1.enq (next_pc, priv,
		     sstatus_SUM,
		     mstatus_MXR,
		     csr_regfile.read_satp);

	 // Set rg_halt if requested.
	 Bool take_interrupt = False;

	 // Interrupts
	 if (interrupt_pending && (cur_verbosity != 0))
	    $display ("    CPU.fa_start_ifetch: interrupt pending");

	 take_interrupt = (take_interrupt || interrupt_pending);

`ifdef INCLUDE_GDB_CONTROL
	 // Debugger stop-request
	 if ((! take_interrupt) && (rg_stop_req || rg_self_stop_req) && (cur_verbosity != 0))
	    $display ("    CPU.fa_start_ifetch: debugger/self stop-request: PC = 0x%08h", next_pc);

	 take_interrupt = (take_interrupt || rg_stop_req || rg_self_stop_req);

	 // dcsr.step step-request
	 if ((! take_interrupt) && rg_step_req && (cur_verbosity != 0))
	    $display ("    CPU.fa_start_ifetch: dcsr.step-request");

	 take_interrupt = (take_interrupt || rg_step_req);

	 // If single-step mode, set step-request to cause a stop at next fetch
	 if (csr_regfile.read_dcsr_step) begin
	    rg_step_req <= True;
	    if (cur_verbosity != 0)
	       $display ("    CPU: fa_start_ifetch: step request");
	 end
`endif

	 if (take_interrupt) begin
	    rg_halt <= True;
	    if (cur_verbosity != 0)
	       $display ("    CPU: fa_start_ifetch: setting rg_halt <= True");
	 end
      endaction
   endfunction

   // ================================================================
   // Actions to restart from Debug Mode (e.g., GDB 'continue' after a breakpoint)
   // We re-initialize CPI_instrs and CPI_cycles.

   function Action fa_restart (Addr resume_pc);
      action
	 fa_start_ifetch (resume_pc, rg_cur_priv);
	 stage1.set_full (True);
	 rg_state <= CPU_RUNNING;

`ifdef INCLUDE_GDB_CONTROL
	 // Notify debugger that we've started running
	 f_run_halt_rsps.enq (True);
`endif

	 rg_start_CPI_cycles <= csr_regfile.read_csr_mcycle;
	 rg_start_CPI_instrs <= csr_regfile.read_csr_minstret;

	 if (cur_verbosity != 0)
	    $display ("    restart with PC = 0x%0h", resume_pc);
      endaction
   endfunction

   // ================================================================
   // Debug tracing: show pipe state

   (* no_implicit_conditions, fire_when_enabled *)
   rule rl_show_pipe (   (cur_verbosity > 1)
		  && (   (rg_state == CPU_RUNNING)
		      || (rg_state == CPU_FENCE_I)
		      || (rg_state == CPU_FENCE)));
      let mstatus = csr_regfile.read_mstatus;
      $display ("================================================================");
      $display ("%0d: Pipeline State:  inum:%0d  cur_priv:%0d  mstatus:%0x", cur_cycle, rg_inum, rg_cur_priv, mstatus);
      $display ("    ", fshow (word_to_mstatus (mstatus)));

      $display ("    Bypass S1 <= S3: ", fshow (stage3.out.bypass));
      $display ("    S3: ", fshow (stage3.out));
      $display ("    Bypass S1 <= S2: ", fshow (stage2.out.bypass));

      $display ("    S2: pc 0x%08h instr 0x%08h priv %0d",
		stage2.out.data_to_stage3.pc,
		stage2.out.data_to_stage3.instr,
		stage2.out.data_to_stage3.priv);
      $display ("        ", fshow (stage2.out));

      $display ("    S1: pc 0x%08h instr 0x%08h priv %0d",
		stage1.out.data_to_stage2.pc,
		stage1.out.data_to_stage2.instr,
		stage1.out.data_to_stage2.priv);
      $display ("        ", fshow (stage1.out));
   endrule

   // ================================================================
   // Reset

   rule rl_reset_start (rg_state == CPU_RESET1);
      let req <- pop (f_reset_reqs);

`ifdef INCLUDE_GDB_CONTROL
      rg_stop_req <= False;
      rg_step_req <= False;
      rg_self_stop_req <= False;
`endif

      $display ("================================================================");
      $display ("CPU: Bluespec  RISC-V  Piccolo  v3.0");
      $display ("Copyright (c) 2016-2018 Bluespec, Inc. All Rights Reserved.");
      $display ("================================================================");

      gpr_regfile.server_reset.request.put (?);
      csr_regfile.server_reset.request.put (?);
      near_mem.server_reset.request.put (?);

      stage1.server_reset.request.put (?);
      stage2.server_reset.request.put (?);
      stage3.server_reset.request.put (?);

      rg_cur_priv <= m_Priv_Mode;
      rg_halt     <= False;
      rg_state    <= CPU_RESET2;
      rg_inum     <= 1;

      Bool v1 <- $test$plusargs ("v1");
      Bool v2 <- $test$plusargs ("v2");
      cfg_verbosity <= ((v2 ? 2 : (v1 ? 1 : 0)));

      if (cur_verbosity != 0)
	 $display ("%0d: CPU.rl_reset_start", cur_cycle);

`ifdef INCLUDE_TANDEM_VERIF
      Info_CPU_to_Verifier to_verifier = ?;
      to_verifier.pc = fromInteger(pc_tv_cmd);
      to_verifier.instr = fromInteger(tv_cmd_reset);
      f_to_verifier.enq (to_verifier);
`endif
   endrule

   rule rl_reset_complete (rg_state == CPU_RESET2);
      let ack0 <- gpr_regfile.server_reset.response.get;
      let ack1 <- csr_regfile.server_reset.response.get;
      let ack2 <- near_mem.server_reset.response.get;
      let ack3 <- stage1.server_reset.response.get;
      let ack4 <- stage2.server_reset.response.get;
      let ack5 <- stage3.server_reset.response.get;

      f_reset_rsps.enq (?);

      if (cur_verbosity != 0)
	 $display ("%0d: CPU.reset_complete", cur_cycle);

`ifdef INCLUDE_GDB_CONTROL
      csr_regfile.write_dcsr_cause (DCSR_CAUSE_HALTREQ);
      rg_state <= CPU_DEBUG_MODE;

      if (cur_verbosity != 0)
	 $display ("    entering DEBUG_MODE");
`else
      WordXL dpc = truncate (pc_reset_value);
      fa_restart (dpc);
`endif
   endrule

   // ================================================================
   // Various conditions on the pipe

   Bool pipe_is_empty = (   (stage1.out.ostatus == OSTATUS_EMPTY)
			 && (stage2.out.ostatus == OSTATUS_EMPTY)
			 && (stage3.out.ostatus == OSTATUS_EMPTY));

   Bool pipe_has_busy = (   (stage1.out.ostatus == OSTATUS_BUSY)
			 || (stage2.out.ostatus == OSTATUS_BUSY)
			 || (stage3.out.ostatus == OSTATUS_BUSY));

   Bool pipe_has_nonpipe = (   (stage3.out.ostatus == OSTATUS_NONPIPE)
			    || (   (stage3.out.ostatus == OSTATUS_EMPTY)
				&& (stage2.out.ostatus == OSTATUS_NONPIPE))
			    || (   (stage3.out.ostatus == OSTATUS_EMPTY)
				&& (stage2.out.ostatus == OSTATUS_EMPTY)
				&& (stage1.out.ostatus == OSTATUS_NONPIPE)));

   Bool possible_ST_in_flight = (   (stage2.out.ostatus == OSTATUS_PIPE)
				 || (   (stage2.out.ostatus == OSTATUS_EMPTY)
				     && (stage3.out.ostatus == OSTATUS_PIPE)));

   Bool stage1_take_interrupt = (   rg_halt
				 && (   (stage1.out.ostatus == OSTATUS_PIPE)
				     || (stage1.out.ostatus == OSTATUS_NONPIPE))
				 && (stage2.out.ostatus == OSTATUS_EMPTY)
				 && (stage3.out.ostatus == OSTATUS_EMPTY));

   Bool stage1_is_csrrx = ((stage1.out.ostatus == OSTATUS_PIPE)
			   && fn_instr_is_csrrx (stage1.out.data_to_stage2.instr));

   // ================================================================
   // PIPELINE BEHAVIOR (excluding nonpipe special instructions and exceptions)

   // We do not attempt to manage CSR values in the pipeline like GPRs
   // (read reg, writeback, bypassing) because of complexity: too many
   // CSRs can change simultaneously.  A CSRRx instruction in stage1
   // is stalled until downstream stages are empty. Then, we delay for
   // a cycle before fetching the next instr, since the fetch may need
   // the just-written CSR value.

   (* fire_when_enabled *)
   rule rl_pipe (   (rg_state == CPU_RUNNING)
		 && (! pipe_is_empty)
		 && (! pipe_has_nonpipe)
		 && (! stage1_take_interrupt));

      Bool stage3_full = (stage3.out.ostatus != OSTATUS_EMPTY);
      Bool stage2_full = (stage2.out.ostatus != OSTATUS_EMPTY);
      Bool stage1_full = (stage1.out.ostatus != OSTATUS_EMPTY);

      // ----------------
      // Stage3 sink (does regfile writebacks)

      if (stage3.out.ostatus == OSTATUS_PIPE) begin
	 stage3.deq; stage3_full = False;
      end

      // ----------------
      // Move instruction from Stage2 to Stage3

      if ((! stage3_full) && (stage2.out.ostatus == OSTATUS_PIPE)) begin
	 stage2.deq;                              stage2_full = False;
	 stage3.enq (stage2.out.data_to_stage3);  stage3_full = True;

`ifdef INCLUDE_TANDEM_VERIF
	 // To Verifier
	 f_to_verifier.enq (stage2.out.to_verifier);
`endif

	 // Accounting
	 rg_inum <= rg_inum + 1;
	 fa_emit_instr_trace (rg_inum, stage2.out.data_to_stage3.pc, stage2.out.data_to_stage3.instr, rg_cur_priv);
      end

      // ----------------
      // Move instruction from Stage1 to Stage2
      // (but stall if Stage1 is CSRRx and rest of pipe is not empty)

      if (   (! rg_halt)
	  && (! stage2_full)
	  && (stage1.out.ostatus == OSTATUS_PIPE)
	  && (! (stage1_is_csrrx && (   (stage2.out.ostatus != OSTATUS_EMPTY)
				     || (stage3.out.ostatus != OSTATUS_EMPTY)))))
	 begin
	    stage1.deq;                              stage1_full = False;
	    stage2.enq (stage1.out.data_to_stage2);  stage2_full = True;

`ifdef INCLUDE_GDB_CONTROL
	    // Stop if we've hit a watch-point
	    let watch_n = csr_regfile.watchpoint_hit (stage1.out.data_to_stage2.addr);
	    if ((stage1.out.data_to_stage2.op_stage2 == OP_Stage2_ST) && (watch_n != 0)) begin
	       $display ("WATCHPOINT %0d: data is %h", watch_n, stage1.out.data_to_stage2.val2);
	       csr_regfile.set_watch_n (watch_n);
	       rg_stop_req <= True;
	    end
`endif
	 end
	  
      // ----------------
      // Feed Stage 1

      if (   (! rg_halt)
	  && (! stage1_full))
	 begin
	    if (stage1_is_csrrx) begin
	       // Delay for a clock if Stage1 is CSRRx, since fa_start_ifetch reads some
	       // CSRs, which may be stale w.r.t. CSRRx
	       // TODO: delay only if the CSRRx is writing certain CSRs read by fa_start_ifetch?
	       //       i.e., csr_satp/csr_mstatus/csr_sstatus?
	       rg_state <= CPU_CSRRX_STALL;
	    end
	    else begin
	       fa_start_ifetch (stage1.out.next_pc, rg_cur_priv);
	       stage1_full = True;
	    end
	 end

      stage3.set_full (stage3_full);
      stage2.set_full (stage2_full);
      stage1.set_full (stage1_full);
   endrule: rl_pipe

   // ================================================================
   // Restart the pipe after a CSRRX stall 

   rule rl_stage1_csrrx (rg_state == CPU_CSRRX_STALL);
      fa_start_ifetch (stage1.out.next_pc, rg_cur_priv);
      stage1.set_full (True);
      rg_state <= CPU_RUNNING;
   endrule

   // ================================================================
   // Stage2: nonpipe special: all stage2 nonpipe behaviors are traps

   rule rl_stage2_nonpipe (   (rg_state == CPU_RUNNING)
			   && (stage3.out.ostatus == OSTATUS_EMPTY)
			   && (stage2.out.ostatus == OSTATUS_NONPIPE));
      if (cur_verbosity > 1)
	 $display ("%0d: CPU.rl_stage2_nonpipe");

      let epc      = stage2.out.trap_info.epc;
      let exc_code = stage2.out.trap_info.exc_code;
      let badaddr  = stage2.out.trap_info.badaddr;
      let instr    = stage2.out.data_to_stage3.instr;

      // Take trap
      match {.next_pc,
	     .new_mstatus,
	     .mcause,
	     .new_priv}    <- csr_regfile.csr_trap_actions (rg_cur_priv,    // from priv
							    epc,
							    False,          // interrupt_req
							    exc_code,
							    badaddr);
      rg_cur_priv <= new_priv;

      fa_start_ifetch (next_pc, new_priv);
      stage1.set_full (True);
      stage2.set_full (False);

      // Accounting
      csr_regfile.csr_minstret_incr;
      rg_inum <= rg_inum + 1;

`ifdef INCLUDE_TANDEM_VERIF
      // Send trapping instr info to Tandem Verifier
      let to_verifier = Info_CPU_to_Verifier {exc_taken: True,
					      pc:        epc,
					      addr:      next_pc,
					      data1:     new_mstatus,
					      data2:     mcause,
					      instr_valid: True,
					      instr:     instr
					     };
      f_to_verifier.enq (to_verifier);
`endif

      fa_emit_instr_trace (rg_inum, epc, instr, rg_cur_priv);

      // Debug
      if (cur_verbosity != 0)
	 $display ("    mcause:0x%0h  epc 0x%0h  tval:0x%0h  new pc 0x%0h, new mstatus 0x%0h",
		   mcause, epc, badaddr, next_pc, new_mstatus);
   endrule : rl_stage2_nonpipe

   // ================================================================
   // Stage1: nonpipe special: MRET/SRET/URET

   rule rl_stage1_xRET (   (rg_state== CPU_RUNNING)
			&& (! rg_halt)
			&& (stage3.out.ostatus == OSTATUS_EMPTY)
			&& (stage2.out.ostatus == OSTATUS_EMPTY)
			&& (stage1.out.ostatus == OSTATUS_NONPIPE)
			&& (   (stage1.out.control == CONTROL_MRET)
			    || (stage1.out.control == CONTROL_SRET)
			    || (stage1.out.control == CONTROL_URET)));

      // Return-from-exception actions on CSRs
      Priv_Mode from_priv = ((stage1.out.control == CONTROL_MRET) ?
			     m_Priv_Mode : ((stage1.out.control == CONTROL_SRET) ?
					    s_Priv_Mode : u_Priv_Mode));
      match { .next_pc, .new_priv, .new_mstatus } <- csr_regfile.csr_ret_actions (from_priv);
      rg_cur_priv <= new_priv;

      // Redirect PC
      fa_start_ifetch (next_pc, new_priv);
      stage1.set_full (True);

      // Accounting
      csr_regfile.csr_minstret_incr;
      rg_inum <= rg_inum + 1;

`ifdef INCLUDE_TANDEM_VERIF
      // Send info Tandem Verifier
      let to_verifier = Info_CPU_to_Verifier {exc_taken:   False,
					      pc:          stage1.out.data_to_stage2.pc,
					      addr:        next_pc,
					      data1:       new_mstatus,
					      data2:       0,
					      instr_valid: True,
					      instr:       stage1.out.data_to_stage2.instr
					     };
      f_to_verifier.enq (to_verifier);
`endif

      // Debug
      fa_emit_instr_trace (rg_inum, stage1.out.data_to_stage2.pc, stage1.out.data_to_stage2.instr, rg_cur_priv);
      if (cur_verbosity != 0)
	 $display ("    xRET: next_pc:0x%0h  new mstatus:0x%0h  new priv:%0d", next_pc, new_mstatus, new_priv);
   endrule : rl_stage1_xRET

   // ================================================================
   // Stage1: nonpipe special: FENCE.I

   rule rl_stage1_FENCE_I (   (rg_state== CPU_RUNNING)
			   && (! rg_halt)
			   && (stage3.out.ostatus == OSTATUS_EMPTY)
			   && (stage2.out.ostatus == OSTATUS_EMPTY)
			   && (stage1.out.ostatus == OSTATUS_NONPIPE)
			   && (stage1.out.control == CONTROL_FENCE_I));
      rg_state <= CPU_FENCE_I;
      near_mem.server_fence_i.request.put (?);

      if (cur_verbosity > 1)
	 $display ("%0d: CPU.rl_stage1_FENCE_I", cur_cycle);
   endrule

   rule rl_finish_FENCE_I (rg_state == CPU_FENCE_I);
      // Await mem system FENCE.I completion
      let dummy <- near_mem.server_fence_i.response.get;

      // Resume pipe
      rg_state <= CPU_RUNNING;
      // nsharma: 2017-05-24 Bug fix
      // nsharma: Prevents PC from advancing after a FENCE
      // stage1.enq (stage1.out.data_to_stage2.pc);  stage1.set_full (True);
      fa_start_ifetch (stage1.out.next_pc, rg_cur_priv);
      stage1.set_full (True);

      // Accounting
      csr_regfile.csr_minstret_incr;
      rg_inum <= rg_inum + 1;

`ifdef INCLUDE_TANDEM_VERIF
      // Send info Tandem Verifier
      let to_verifier = Info_CPU_to_Verifier {exc_taken: False,
					      pc:        stage1.out.data_to_stage2.pc,
					      addr:      0,
					      data1:     0,
					      data2:     0,
					      instr_valid: True,
					      instr:     stage1.out.data_to_stage2.instr
                                             };
      f_to_verifier.enq (to_verifier);
`endif

      // Debug
      fa_emit_instr_trace (rg_inum, stage1.out.data_to_stage2.pc, stage1.out.data_to_stage2.instr, rg_cur_priv);
      if (cur_verbosity > 1)
	 $display ("    CPU.rl_finish_FENCE_I");
   endrule : rl_finish_FENCE_I

   // ================================================================
   // Stage1: nonpipe special: FENCE

   rule rl_stage1_FENCE (   (rg_state== CPU_RUNNING)
			 && (! rg_halt)
			 && (stage3.out.ostatus == OSTATUS_EMPTY)
			 && (stage2.out.ostatus == OSTATUS_EMPTY)
			 && (stage1.out.ostatus == OSTATUS_NONPIPE)
			 && (stage1.out.control == CONTROL_FENCE));
      rg_state <= CPU_FENCE;
      near_mem.server_fence.request.put (?);

      if (cur_verbosity > 1)
	 $display ("%0d: CPU.rl_stage1_FENCE", cur_cycle);
   endrule

   // Finish FENCE

   rule rl_finish_FENCE (rg_state == CPU_FENCE);
      // Await mem system FENCE.I completion
      let dummy <- near_mem.server_fence.response.get;

      // Resume pipe
      rg_state <= CPU_RUNNING;
      // nsharma: 2017-05-24 Bug fix
      // nsharma: Prevents PC from advancing after a FENCE
      // stage1.enq (stage1.out.data_to_stage2.pc);  stage1.set_full (True);
      fa_start_ifetch (stage1.out.next_pc, rg_cur_priv);
      stage1.set_full (True);

      // Accounting
      csr_regfile.csr_minstret_incr;
      rg_inum <= rg_inum + 1;

`ifdef INCLUDE_TANDEM_VERIF
      // Send info Tandem Verifier
      let to_verifier = Info_CPU_to_Verifier {exc_taken: False,
					      pc:        stage1.out.data_to_stage2.pc,
					      addr:      0,
					      data1:     0,
					      data2:     0,
					      instr_valid: True,
					      instr:     stage1.out.data_to_stage2.instr
                                             };
      f_to_verifier.enq (to_verifier);
`endif

      // Debug
      fa_emit_instr_trace (rg_inum, stage1.out.data_to_stage2.pc, stage1.out.data_to_stage2.instr, rg_cur_priv);
      if (cur_verbosity > 1)
	 $display ("    CPU.rl_finish_FENCE");
   endrule : rl_finish_FENCE

   // ================================================================
   // Stage1: nonpipe special: SFENCE.VMA

   rule rl_stage1_SFENCE_VMA (   (rg_state== CPU_RUNNING)
			      && (! rg_halt)
			      && (stage3.out.ostatus == OSTATUS_EMPTY)
			      && (stage2.out.ostatus == OSTATUS_EMPTY)
			      && (stage1.out.ostatus == OSTATUS_NONPIPE)
			      && (stage1.out.control == CONTROL_SFENCE_VMA));

      // Tell Near_Mem to do its SFENCE_VMA
      near_mem.sfence_vma;

      // Resume pipe
      rg_state <= CPU_RUNNING;
      fa_start_ifetch (stage1.out.next_pc, rg_cur_priv);
      stage1.set_full (True);

      // Accounting
      csr_regfile.csr_minstret_incr;
      rg_inum <= rg_inum + 1;

`ifdef INCLUDE_TANDEM_VERIF
      // Send info Tandem Verifier
      let to_verifier = Info_CPU_to_Verifier {exc_taken:   False,
					      pc:          stage1.out.data_to_stage2.pc,
					      addr:        0,
					      data1:       0,
					      data2:       0,
					      instr_valid: True,
					      instr:       stage1.out.data_to_stage2.instr
                                             };
      f_to_verifier.enq (to_verifier);
`endif

      // Debug
      fa_emit_instr_trace (rg_inum, stage1.out.data_to_stage2.pc, stage1.out.data_to_stage2.instr, rg_cur_priv);
      if (cur_verbosity > 1)
	 $display ("    CPU.rl_stage1_SFENCE_VMA");
   endrule: rl_stage1_SFENCE_VMA

   // ================================================================
   // Stage1: nonpipe special: WFI

   rule rl_stage1_WFI (   (rg_state== CPU_RUNNING)
		       && (! rg_halt)
		       && (stage3.out.ostatus == OSTATUS_EMPTY)
		       && (stage2.out.ostatus == OSTATUS_EMPTY)
		       && (stage1.out.ostatus == OSTATUS_NONPIPE)
		       && (stage1.out.control == CONTROL_WFI));
      rg_state <= CPU_WFI_PAUSED;

      // Debug
      fa_emit_instr_trace (rg_inum, stage1.out.data_to_stage2.pc, stage1.out.data_to_stage2.instr, rg_cur_priv);
      if (cur_verbosity > 1)
	 $display ("    CPU.rl_stage1_WFI");
   endrule: rl_stage1_WFI

   // ----------------

   rule rl_WFI_resume ((rg_state == CPU_WFI_PAUSED) && csr_regfile.wfi_resume);
      // Debug
      fa_emit_instr_trace (rg_inum, stage1.out.data_to_stage2.pc, stage1.out.data_to_stage2.instr, rg_cur_priv);
      if (cur_verbosity > 1)
	 $display ("    CPU.rl_WFI_resume at PC 0x%08h, priv %0d", stage1.out.next_pc, rg_cur_priv);

      // Resume pipe (it will handle the interrupt, if one is pending)
      rg_state <= CPU_RUNNING;
      fa_start_ifetch (stage1.out.next_pc, rg_cur_priv);
      stage1.set_full (True);

      // Accounting
      csr_regfile.csr_minstret_incr;
      rg_inum <= rg_inum + 1;

`ifdef INCLUDE_TANDEM_VERIF
      // Send info Tandem Verifier
      let to_verifier = Info_CPU_to_Verifier {exc_taken:   False,
					      pc:          stage1.out.data_to_stage2.pc,
					      addr:        0,
					      data1:       0,
					      data2:       0,
					      instr_valid: True,
					      instr:       stage1.out.data_to_stage2.instr
                                             };
      f_to_verifier.enq (to_verifier);
`endif
   endrule: rl_WFI_resume

   // ----------------
   rule rl_reset_from_WFI (   (rg_state == CPU_WFI_PAUSED)
			   && f_reset_reqs.notEmpty);
      rg_state <= CPU_RESET1;
   endrule : rl_reset_from_WFI

   // ================================================================
   // Stage1: nonpipe traps (except BREAKs that enter Debug Mode)

`ifdef INCLUDE_GDB_CONTROL
   Bool break_into_Debug_Mode = (   (stage1.out.trap_info.exc_code == exc_code_BREAKPOINT)
				 && csr_regfile.dcsr_break_enters_debug (rg_cur_priv));
`else
   Bool break_into_Debug_Mode = False;
`endif

   let machine_mode_BREAK = (   (rg_cur_priv == m_Priv_Mode)
			     && (stage1.out.trap_info.exc_code == exc_code_BREAKPOINT));

   rule rl_stage1_trap (   (rg_state == CPU_RUNNING)
			&& (! rg_halt)
			&& (stage3.out.ostatus == OSTATUS_EMPTY)
			&& (stage2.out.ostatus == OSTATUS_EMPTY)
			&& (stage1.out.ostatus == OSTATUS_NONPIPE)
			&& (stage1.out.control == CONTROL_TRAP)
			&& (! break_into_Debug_Mode));

      let epc      = stage1.out.trap_info.epc;
      let exc_code = stage1.out.trap_info.exc_code;
      let badaddr  = stage1.out.trap_info.badaddr;
      let instr    = stage1.out.data_to_stage2.instr;

      // Take trap
      match {.next_pc,
	     .new_mstatus,
	     .mcause,
	     .new_priv}    <- csr_regfile.csr_trap_actions (rg_cur_priv,    // from priv
							    epc,
							    False,          // interrupt_req,
							    exc_code,
							    badaddr);       // v1.10 - mtval
      rg_cur_priv <= new_priv;
      fa_start_ifetch (next_pc, new_priv);
      stage1.set_full (True);

      // Accounting
      csr_regfile.csr_minstret_incr;
      rg_inum <= rg_inum + 1;

`ifdef INCLUDE_TANDEM_VERIF
      // Send info on trapping instr Tandem Verifier
      let to_verifier = Info_CPU_to_Verifier {exc_taken: True,
					      pc:        epc,
					      addr:      next_pc,
					      data1:     new_mstatus,
					      data2:     mcause,
					      instr_valid: True,
					      instr:     instr
                                             };
      f_to_verifier.enq (to_verifier);
`endif

      // Simulation heuristic: finish if trap back to this instr
`ifndef INCLUDE_GDB_CONTROL
      if (epc == next_pc) begin
	 $display ("%0d: CPU.rl_stage1_trap: Tight infinite trap loop: pc 0x%0x instr 0x%08x", cur_cycle,
		   next_pc, instr);
	 fa_report_CPI;
	 $finish (0);
      end
`endif

      // Debug
      fa_emit_instr_trace (rg_inum, epc, instr, rg_cur_priv);
      if (cur_verbosity != 0) begin
	 $display ("%0d: CPU.rl_stage1_trap: priv:%0d  mcause:0x%0h  epc:0x%0h", cur_cycle, rg_cur_priv, mcause, epc);
	 $display ("    tval:0x%0h  new pc:0x%0h  new mstatus:0x%0h", badaddr, next_pc, new_mstatus);
      end
   endrule: rl_stage1_trap

   // ================================================================
   // Stage1: nonpipe trap: BREAK into Debug Mode when dcsr.ebreakm/s/u is set
   // TODO: We are supposed to set mtval on a machine mode BREAK. Not doing so as we are breaking to the debugger

`ifdef INCLUDE_GDB_CONTROL
   rule rl_trap_BREAK_to_Debug_Mode (   (rg_state == CPU_RUNNING)
				     && (! rg_halt)
				     && (stage3.out.ostatus == OSTATUS_EMPTY)
				     && (stage2.out.ostatus == OSTATUS_EMPTY)
				     && (stage1.out.ostatus == OSTATUS_NONPIPE)
				     && (stage1.out.control == CONTROL_TRAP)
				     && break_into_Debug_Mode);
      let pc    = stage1.out.data_to_stage2.pc;
      let instr = stage1.out.data_to_stage2.instr;

      $display ("%0d: CPU.rl_trap_BREAK_to_Debug_Mode: PC 0x%08h instr 0x%08h", cur_cycle, pc, instr);
      if (cur_verbosity > 1)
	 $display ("    Flushing caches");

      csr_regfile.write_dcsr_cause (DCSR_CAUSE_EBREAK);
      csr_regfile.write_dpc (pc);    // Where we'll resume on 'continue'
      rg_state <= CPU_GDB_PAUSING;

      // Flush both caches -- using the same interface as that used by FENCE_I
      near_mem.server_fence_i.request.put (?);

      // Notify debugger that we've halted
      f_run_halt_rsps.enq (False);
   endrule: rl_trap_BREAK_to_Debug_Mode

   // Handle the flush responses from the caches when the flush was initiated
   // on entering CPU_PAUSED state
   rule rl_BREAK_cache_flush_finish (rg_state == CPU_GDB_PAUSING);
      let ack <- near_mem.server_fence_i.response.get;
      rg_state <= CPU_DEBUG_MODE;

      fa_report_CPI;
   endrule

   // ----------------
   // Reset while in Debug Mode

   rule rl_reset_from_Debug_Mode (   (rg_state == CPU_DEBUG_MODE)
				  && f_reset_reqs.notEmpty);
      rg_state <= CPU_RESET1;
   endrule
`endif

   // ================================================================
   // EXTERNAL and GDB INTERRUPTS while running
   // We take an interrupt when on Stage1 is frozen
   // and Stage2 and Stage3 have drained, encapsulated
   // in condition 'stage1_take_interrupt'

   rule rl_stage1_interrupt (csr_regfile.interrupt_pending (rg_cur_priv) matches tagged Valid .exc_code
			     &&& (rg_state== CPU_RUNNING)
			     &&& stage1_take_interrupt);

      let epc   = stage1.out.data_to_stage2.pc;
      let instr = stage1.out.data_to_stage2.instr;

      // Take trap
      match {.next_pc,
	     .new_mstatus,
	     .mcause,
	     .new_priv}    <- csr_regfile.csr_trap_actions (rg_cur_priv,    // from priv
							    epc,
							    True,           // interrupt_req,
							    exc_code,
							    ?);             // badaddr
      rg_cur_priv <= new_priv;

      // Just enq the next_pc into stage1, and clear the rg_halt flag
      // as the interrupt is taken
      Bit #(1) sstatus_SUM = new_mstatus [18];    // TODO: project new_mstatus to new_sstatus?
      Bit #(1) mstatus_MXR = new_mstatus [19];
      stage1.enq (next_pc, new_priv,
		  sstatus_SUM,
		  mstatus_MXR,
		  csr_regfile.read_satp);
      stage1.set_full (True);
      rg_halt <= False;

      // Accounting: none (instruction is abandoned)

`ifdef INCLUDE_TANDEM_VERIF
      // Send info on trapping instr Tandem Verifier
      let to_verifier = Info_CPU_to_Verifier {exc_taken: True,
					      pc:        epc,
					      addr:      next_pc,
					      data1:     new_mstatus,
					      data2:     mcause,
					      instr_valid: True,
					      instr:     instr
                                             };
      f_to_verifier.enq (to_verifier);
`endif

      // Debug
      fa_emit_instr_trace (rg_inum, epc, instr, rg_cur_priv);
      if (cur_verbosity > 1)
	 $display ("    CPU.rl_stage1_interrupt; epc 0x%0h, next PC 0x%0h, new mstatus 0x%0h",
		   epc, next_pc, new_mstatus);
   endrule : rl_stage1_interrupt

   // ----------------
   // Stage1: Handle debugger stop-request and dcsr.step step-request while running
   // and no interrupt pending.
   // rg_halt should have allowed the pipeline to drain,
   // i.e., stage1 has completed its fetch,
   // and stage2 and stage3 are empty

`ifdef INCLUDE_GDB_CONTROL
   rule rl_stage1_stop (   (rg_state== CPU_RUNNING)
			&& stage1_take_interrupt
			&& (! interrupt_pending)
			&& (rg_stop_req || rg_step_req || rg_self_stop_req));

      let pc    = stage1.out.data_to_stage2.pc;    // We'll retry this instruction on 'continue'
      let instr = stage1.out.data_to_stage2.instr;

      // Report CPI only stop-req, but not on step-req (where it's not very useful)
      if (rg_stop_req || rg_self_stop_req) begin
	 $display ("%0d: CPU.rl_stop: Stop for debugger. inum %0d priv %0d: PC 0x%0h    instr 0x%0h",
		   cur_cycle, rg_inum, rg_cur_priv, pc, instr);
	 fa_report_CPI;
      end
      else begin
	 $display ("%0d: CPU.rl_stop: Stop after single-step. PC = 0x%08h", cur_cycle, pc);
      end

      DCSR_Cause cause= (rg_stop_req ? DCSR_CAUSE_HALTREQ : DCSR_CAUSE_STEP);
      csr_regfile.write_dcsr_cause (cause);
      csr_regfile.write_dpc (pc);    // We'll retry this instruction on 'continue'
      rg_state    <= CPU_GDB_PAUSING;
      rg_halt     <= False;
      rg_stop_req <= False;
      rg_self_stop_req <= False;
      rg_step_req <= False;

      // Notify debugger that we've halted
      f_run_halt_rsps.enq (False);

      // Flush both caches -- using the same interface as that used by FENCE_I
      near_mem.server_fence_i.request.put (?);

      // Accounting: none (instruction is abandoned)
   endrule: rl_stage1_stop
`endif

   // ================================================================
   // ================================================================
   // ================================================================
   // DEBUGGER ACCESS

   // ----------------
   // Debug Module Run/Halt control

`ifdef INCLUDE_GDB_CONTROL
   rule rl_debug_run ((f_run_halt_reqs.first == True) && (rg_state == CPU_DEBUG_MODE));
      f_run_halt_reqs.deq;

      // Debugger 'resume' request (e.g., GDB 'continue' command)
      let dpc = csr_regfile.read_dpc;
      fa_restart (dpc);
      if (cur_verbosity > 1)
	 $display ("%0d: CPU.rl_debug_run: 'run' from dpc 0x%0h", cur_cycle, dpc);
   endrule

   rule rl_debug_run_ignore ((f_run_halt_reqs.first == True) && fn_is_running (rg_state));
      f_run_halt_reqs.deq;
      $display ("%0d: CPU.debug_run_ignore: ignoring 'run' command (CPU is not in Debug Mode)", cur_cycle);
   endrule

   rule rl_debug_halt ((f_run_halt_reqs.first == False) && fn_is_running (rg_state));
      f_run_halt_reqs.deq;

      // Debugger 'halt' request (e.g., GDB '^C' command)
      rg_stop_req <= True;
      if (cur_verbosity > 1)
	 $display ("%0d: CPU.rl_debug_halt", cur_cycle);
   endrule

   rule rl_debug_halt_ignore ((f_run_halt_reqs.first == False) && (! fn_is_running (rg_state)));
      f_run_halt_reqs.deq;

      $display ("%0d: CPU.rl_debug_halt_ignore: ignoring 'halt' (CPU already halted)", cur_cycle);
   endrule

   // ----------------
   // Debug Module GPR read/write

   rule rl_debug_read_gpr ((rg_state == CPU_DEBUG_MODE) && (! f_gpr_reqs.first.write));
      let req <- pop (f_gpr_reqs);
      Bit #(5) regname = req.address;
      let data = gpr_regfile.read_rs1_port2 (regname);
      let rsp = MemoryResponse {data: data};
      f_gpr_rsps.enq (rsp);
      if (cur_verbosity > 1)
	 $display ("%0d: CPU.rl_debug_read_gpr: Read reg %0d => 0x%0h", cur_cycle, regname, data);
   endrule

   rule rl_debug_write_gpr ((rg_state == CPU_DEBUG_MODE) && f_gpr_reqs.first.write);
      let req <- pop (f_gpr_reqs);
      Bit #(5) regname = req.address;
      let data = req.data;
      gpr_regfile.write_rd (regname, data);
      if (cur_verbosity > 1)
	 $display ("%0d: CPU.rl_debug_write_gpr: Write reg %0d => 0x%0h", cur_cycle, regname, data);
   endrule

   // ----------------
   // Debug Module CSR read/write

   rule rl_debug_read_csr ((rg_state == CPU_DEBUG_MODE) && (! f_csr_reqs.first.write));
      let req <- pop (f_csr_reqs);
      Bit #(12) csr_addr = req.address;
      let m_data = csr_regfile.read_csr_port2 (csr_addr);
      let data = fromMaybe (?, m_data);
      let rsp = MemoryResponse {data: data};
      f_csr_rsps.enq (rsp);
      if (cur_verbosity > 1)
	 $display ("%0d: CPU.rl_debug_read_csr: Read csr %0d => 0x%0h", cur_cycle, csr_addr, data);
   endrule

   rule rl_debug_write_csr ((rg_state == CPU_DEBUG_MODE) && f_csr_reqs.first.write);
      let req <- pop (f_csr_reqs);
      Bit #(12) csr_addr = req.address;
      let data = req.data;
      csr_regfile.write_csr (csr_addr, data);
      if (cur_verbosity > 1)
	 $display ("%0d: CPU.rl_debug_write_csr: Write csr %0d => 0x%0h", cur_cycle, csr_addr, data);
   endrule
`endif

   // ================================================================
   // ================================================================
   // ================================================================
   // INTERFACE

   // Reset
   interface Server  hart0_server_reset = toGPServer (f_reset_reqs, f_reset_rsps);

   // ----------------
   // SoC fabric connections

   // IMem to fabric master interface
   interface  imem_master = near_mem.imem_master;

   // DMem to fabric master interface
   interface  dmem_master = near_mem.dmem_master;

   // Near_Mem back door slave interface
   interface  near_mem_slave = near_mem.near_mem_slave;

   // ----------------
   // Interrupts

   method Action  external_interrupt_req  = csr_regfile.external_interrupt_req;
   method Action  software_interrupt_req  = csr_regfile.software_interrupt_req;
   method Action  timer_interrupt_req (x) = csr_regfile.timer_interrupt_req (x);

   // ----------------
   // Optional interface to Tandem Verifier

`ifdef INCLUDE_TANDEM_VERIF
   interface Get  to_verifier = toGet (f_to_verifier);
`endif

   // ----------------
   // Optional interface to Debug Module

`ifdef INCLUDE_GDB_CONTROL
   // run-control, other
   interface Server  hart0_server_run_halt = toGPServer (f_run_halt_reqs, f_run_halt_rsps);

   interface Put  hart0_put_other_req;
      method Action  put (Bit #(4) req);
	 cfg_verbosity <= req;
      endmethod
   endinterface

   // GPR access
   interface MemoryServer  hart0_gpr_mem_server = toGPServer (f_gpr_reqs, f_gpr_rsps);

   // CSR access
   interface MemoryServer  hart0_csr_mem_server = toGPServer (f_csr_reqs, f_csr_rsps);
`endif

endmodule: mkCPU

// ================================================================

endpackage
