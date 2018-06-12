// Copyright (c) 2016-2018 Bluespec, Inc. All Rights Reserved

package CPU_Stage1;

// ================================================================
// This is Stage 1 of the "Piccolo" CPU.
// It contains the IF, RD, and EX functionality.
// IF: "Instruction Fetch".
// RD: "Register Read"
// EX: "Execute"

// Note: $displays are indented by (stage num x 4) spaces.
// for traditional pipeline display
//     IF
//         DM
//             WB
// i.e., 4 spaces for this stage.

// ================================================================
// Exports

export
CPU_Stage1_IFC (..),
mkCPU_Stage1;

// ================================================================
// BSV library imports

import FIFOF        :: *;
import GetPut       :: *;
import ClientServer :: *;
import ConfigReg    :: *;

// ----------------
// BSV additional libs

import Cur_Cycle :: *;

// ================================================================
// Project imports

import ISA_Decls        :: *;
import CPU_Globals      :: *;
import Near_Mem_IFC     :: *;
import GPR_RegFile      :: *;
import CSR_RegFile      :: *;
import EX_ALU_functions :: *;

// ================================================================
// Interface

interface CPU_Stage1_IFC;
   // ---- Reset
   interface Server #(Token, Token) server_reset;

   // ---- Output
   (* always_ready *)
   method Output_Stage1 out;

   (* always_ready *)
   method Action deq;

   // ---- Input
   (* always_ready *)
   method Action enq (Addr next_pc, Priv_Mode priv, Bit #(1) sstatus_SUM, Bit #(1) mstatus_MXR, WordXL satp);

   (* always_ready *)
   method Action set_full (Bool full);

   // Debugging
   method Action show_state;
endinterface

// ================================================================
// Implementation module

module mkCPU_Stage1 #(Bit #(4)         verbosity,
		      GPR_RegFile_IFC  gpr_regfile,
		      CSR_RegFile_IFC  csr_regfile,
		      IMem_IFC         icache,
		      Bypass           bypass_from_stage2,
		      Bypass           bypass_from_stage3,
		      Priv_Mode        cur_priv)
                    (CPU_Stage1_IFC);

   Reg #(Stage_Run_State) rg_run_state  <- mkReg (STAGE_RUNNING);

   FIFOF #(Token) f_reset_reqs <- mkFIFOF;
   FIFOF #(Token) f_reset_rsps <- mkFIFOF;

   Reg #(Bool) rg_full  <- mkReg (False);

   // ----------------------------------------------------------------
   // BEHAVIOR

   rule rl_reset;
      f_reset_reqs.deq;
      rg_full <= False;
      f_reset_rsps.enq (?);
      rg_run_state <= STAGE_RUNNING;
   endrule

   // ----------------
   // Combinational output function

   function Output_Stage1 fv_out;
      let pc            = icache.pc;
      let instr         = icache.instr;
      let decoded_instr = fv_decode (instr);
      let funct3        = decoded_instr.funct3;
      let csr           = decoded_instr.csr;
   
      // Register rs1 read and bypass
      let rs1 = decoded_instr.rs1;
      let rs1_val = gpr_regfile.read_rs1 (rs1);
      match { .busy1a, .rs1a } = fn_gpr_bypass (bypass_from_stage3, rs1, rs1_val);
      match { .busy1b, .rs1b } = fn_gpr_bypass (bypass_from_stage2, rs1, rs1a);
      Bool rs1_busy = (busy1a || busy1b);
      Word rs1_val_bypassed = ((rs1 == 0) ? 0 : rs1b);

      // Register rs2 read and bypass
      let rs2 = decoded_instr.rs2;
      let rs2_val = gpr_regfile.read_rs2 (rs2);
      match { .busy2a, .rs2a } = fn_gpr_bypass (bypass_from_stage3, rs2, rs2_val);
      match { .busy2b, .rs2b } = fn_gpr_bypass (bypass_from_stage2, rs2, rs2a);
      Bool rs2_busy = (busy2a || busy2b);
      Word rs2_val_bypassed = ((rs2 == 0) ? 0 : rs2b);

      // CSR address-based protection checks
      Bool is_csrrx          = (   (decoded_instr.opcode == op_SYSTEM)
                                && f3_is_CSRR_any (funct3));
      Bool csr_priv_fault    = (is_csrrx && (cur_priv < csr [9:8]));        // wrong privilege

      // When accessing the performance counters, the MCounteren register bits
      // should be factored in before declaring a CSR privilege fault
      let mc = csr_regfile.read_csr_mcounteren;
      Bool csr_ctr_fault     = (   csr_priv_fault
                                && (   (csr == csr_mcycle) && (mc.cy == 1'b0)
				    || (csr == csr_minstret) && (mc.ir == 1'b0)
`ifdef RV32
				    || (csr == csr_mcycleh) && (mc.cy == 1'b0)
				    || (csr == csr_minstreth) && (mc.ir == 1'b0)
`endif
				   ));
      Bool csr_ctr_access    = (   is_csrrx
                                && (   (csr == csr_mcycle)
				    || (csr == csr_minstret)
`ifdef RV32
				    || (csr == csr_minstreth)
				    || (csr == csr_mcycleh)
`endif
				   ));

      csr_priv_fault = csr_ctr_access ? csr_ctr_fault : csr_priv_fault;

      Bool csr_write_fault   = (   is_csrrx
				&& (f3_is_CSRR_W (funct3) || (rs1 != 0))    // attempting write
				&& (csr [11:10] == 2'b11));                 // read-only csr

      // CSR reads
      // Note: csr should not be read for CSRRW[I] if Rd=0 (i.e., don't cause its side-effects).
      // But currently csr_reads are pure (no side effects), so we omit this check.
      let m_csr_val = csr_regfile.read_csr (csr);
      let csr_valid = (   isValid (m_csr_val)
		       && (! csr_priv_fault)
		       && (!csr_write_fault));

      let csr_val   = fromMaybe (?, m_csr_val);

      // ALU function
      let alu_inputs = ALU_Inputs {cur_priv:       cur_priv,
				   pc:             pc,
				   instr:          instr,
				   decoded_instr:  decoded_instr,
				   rs1_val:        rs1_val_bypassed,
				   rs2_val:        rs2_val_bypassed,
				   csr_valid:      csr_valid,
				   csr_val:        csr_val };
      let alu_outputs = fv_ALU (alu_inputs);

      Output_Stage1 output_stage1 = ?;

      // This stage is empty
      if (! rg_full) begin
	 output_stage1.ostatus = OSTATUS_EMPTY;
      end

      // Stall if ICache not ready
      else if (! icache.valid) begin
	 output_stage1.ostatus = OSTATUS_BUSY;
      end

      // Stall if bypass pending for rs1 or rs2
      else if (rs1_busy || rs2_busy) begin
	 output_stage1.ostatus = OSTATUS_BUSY;
      end

      // Trap on ICache exception
      else if (icache.exc) begin
	 output_stage1.ostatus   = OSTATUS_NONPIPE;
	 output_stage1.control   = CONTROL_TRAP;
	 output_stage1.trap_info = Trap_Info {epc:      pc,
					      exc_code: icache.exc_code,
					      badaddr:  pc};    // TODO: '?', perhaps?
      end

      // Trap on CSR access fault
      else if (csr_priv_fault || csr_write_fault)
	 begin
	    output_stage1.ostatus   = OSTATUS_NONPIPE;
	    output_stage1.control   = CONTROL_TRAP;
	    output_stage1.trap_info = Trap_Info {epc:      pc,
						 exc_code: exc_code_ILLEGAL_INSTRUCTION,
						 badaddr:  zeroExtend(instr)}; // v1.10 - mtval
	 end

      // ALU outputs: normal, trap, and non-pipe instrs (CSR, MRET, FENCE.I, FENCE, WPI)
      else begin
	 let ostatus = (  (   (alu_outputs.control == CONTROL_STRAIGHT)
			   || (alu_outputs.control == CONTROL_BRANCH))
			? OSTATUS_PIPE
			: OSTATUS_NONPIPE);

	 // TODO: change name 'badaddr' to 'tval'
	 let badaddr = 0;
	 if (alu_outputs.exc_code == exc_code_ILLEGAL_INSTRUCTION)
	    badaddr = zeroExtend (instr);
	 else if (alu_outputs.exc_code == exc_code_INSTR_ADDR_MISALIGNED)
	    badaddr = alu_outputs.addr;    // branch target pc
	 let trap_info = Trap_Info {epc:      pc,
				    exc_code: alu_outputs.exc_code,
				    badaddr:  badaddr};  // v1.10 - mtval

	 let next_pc = ((alu_outputs.control == CONTROL_BRANCH) ? alu_outputs.addr : pc + 4);

	 let data_to_stage2 = Data_Stage1_to_Stage2 {priv:      cur_priv,
						     pc:        pc,
						     instr:     instr,
						     op_stage2: alu_outputs.op_stage2,
						     rd:        alu_outputs.rd,
						     csr_valid: alu_outputs.csr_valid,
						     addr:      alu_outputs.addr,
						     val1:      alu_outputs.val1,
						     val2:      alu_outputs.val2 };

	 output_stage1.ostatus        = ostatus;
	 output_stage1.trap_info      = trap_info;
	 output_stage1.control        = alu_outputs.control;
	 output_stage1.next_pc        = next_pc;
	 output_stage1.data_to_stage2 = data_to_stage2;
      end

      return output_stage1;
   endfunction: fv_out

   // ================================================================
   // INTERFACE

   // ---- Reset
   interface server_reset = toGPServer (f_reset_reqs, f_reset_rsps);

   // ---- Output
   method Output_Stage1 out;
      return fv_out;
   endmethod

   method Action deq ();
      // Writeback CSR if valid
      let data_to_stage2 = fv_out.data_to_stage2;

      Bool wrote_csr_minstret = False;
      if (data_to_stage2.csr_valid) begin
	 CSR_Addr csr_addr = truncate (data_to_stage2.addr);
	 WordXL   csr_val  = data_to_stage2.val2;
	 csr_regfile.write_csr (csr_addr, csr_val);
	 wrote_csr_minstret = ((csr_addr == csr_minstret) || (csr_addr == csr_minstreth));
	 if (verbosity > 1)
	    $display ("    S1: write CSR 0x%0h, val 0x%0h", csr_addr, csr_val);
      end
   endmethod

   // ---- Input
   method Action enq (Addr next_pc, Priv_Mode priv, Bit #(1) sstatus_SUM, Bit #(1) mstatus_MXR, WordXL satp);
      icache.req (f3_LW, next_pc, priv, sstatus_SUM, mstatus_MXR, satp);

      if (verbosity > 1)
	 $display ("    S1.enq: 0x%08x", next_pc);
   endmethod

   method Action set_full (Bool full);
      rg_full <= full;
   endmethod

   method Action show_state;
      if (rg_full)
	 $display ("    S1: pc ", fshow (icache.pc));
      else
	 $display ("    S1: empty");
   endmethod
endmodule

// ================================================================

endpackage
