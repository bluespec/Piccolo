// Copyright (c) 2016-2019 Bluespec, Inc. All Rights Reserved

package CPU_Stage1;

// ================================================================
// This is Stage 1 of the "Piccolo" CPU.
// It contains the IF, RD, and EX functionality.
// IF: "Instruction Fetch".
// RD: "Register Read"
// EX: "Execute"

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
`ifdef ISA_F
import FPR_RegFile      :: *;
`endif
import CSR_RegFile      :: *;
import EX_ALU_functions :: *;

`ifdef ISA_C
// 'C' extension (16b compressed instructions)
import CPU_Decode_C     :: *;
`endif

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
endinterface

// ================================================================
// Implementation module

module mkCPU_Stage1 #(Bit #(4)         verbosity,
		      GPR_RegFile_IFC  gpr_regfile,
		      Bypass           bypass_from_stage2,
		      Bypass           bypass_from_stage3,
`ifdef ISA_F
		      FPR_RegFile_IFC  fpr_regfile,
		      FBypass          fbypass_from_stage2,
		      FBypass          fbypass_from_stage3,
`endif
		      CSR_RegFile_IFC  csr_regfile,
		      IMem_IFC         imem,
		      Priv_Mode        cur_priv)
                    (CPU_Stage1_IFC);

   FIFOF #(Token) f_reset_reqs <- mkFIFOF;
   FIFOF #(Token) f_reset_rsps <- mkFIFOF;

   Reg #(Bool) rg_full  <- mkReg (False);

   MISA misa   = csr_regfile.read_misa;
   Bit #(2) xl = ((xlen == 32) ? misa_mxl_32 : misa_mxl_64);

   // ----------------------------------------------------------------
   // BEHAVIOR

   rule rl_reset;
      f_reset_reqs.deq;
      rg_full <= False;
      f_reset_rsps.enq (?);
   endrule

   // ----------------
   // ALU

   let   pc             = imem.pc;
   let   is_i32_not_i16 = imem.is_i32_not_i16;
   Instr instr          = imem.instr;
`ifdef ISA_C
   Instr_C instr_C = instr [15:0];
   if (! is_i32_not_i16)
      instr = fv_decode_C (misa, xl, instr_C);
`endif
   let decoded_instr  = fv_decode (instr);
   let funct3         = decoded_instr.funct3;

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

`ifdef ISA_F
   // FP Register rs1 read and bypass
   let frs1_val = fpr_regfile.read_rs1 (rs1);
   match { .fbusy1a, .frs1a } = fn_fpr_bypass (fbypass_from_stage3, rs1, frs1_val);
   match { .fbusy1b, .frs1b } = fn_fpr_bypass (fbypass_from_stage2, rs1, frs1a);
   Bool frs1_busy = (fbusy1a || fbusy1b);
   WordFL frs1_val_bypassed = frs1b;

   // FP Register rs2 read and bypass
   let frs2_val = fpr_regfile.read_rs2 (rs2);
   match { .fbusy2a, .frs2a } = fn_fpr_bypass (fbypass_from_stage3, rs2, frs2_val);
   match { .fbusy2b, .frs2b } = fn_fpr_bypass (fbypass_from_stage2, rs2, frs2a);
   Bool frs2_busy = (fbusy2a || fbusy2b);
   WordFL frs2_val_bypassed = frs2b;

   // FP Register rs3 read and bypass
   let rs3 = decoded_instr.rs3;
   let frs3_val = fpr_regfile.read_rs3 (rs3);
   match { .fbusy3a, .frs3a } = fn_fpr_bypass (fbypass_from_stage3, rs3, frs3_val);
   match { .fbusy3b, .frs3b } = fn_fpr_bypass (fbypass_from_stage2, rs3, frs3a);
   Bool frs3_busy = (fbusy3a || fbusy3b);
   WordFL frs3_val_bypassed = frs3b;
`endif

   // ALU function
   let alu_inputs = ALU_Inputs {cur_priv       : cur_priv,
				pc             : pc,
				is_i32_not_i16 : imem.is_i32_not_i16,
				instr          : instr,
`ifdef ISA_C
				instr_C        : instr_C,
`endif
				decoded_instr  : decoded_instr,
				rs1_val        : rs1_val_bypassed,
				rs2_val        : rs2_val_bypassed,
`ifdef ISA_F
				frs1_val       : frs1_val_bypassed,
				frs2_val       : frs2_val_bypassed,
				frs3_val       : frs3_val_bypassed,
				fcsr_frm       : csr_regfile.read_frm,
`endif
				mstatus        : csr_regfile.read_mstatus,
				misa           : csr_regfile.read_misa };

   let alu_outputs = fv_ALU (alu_inputs);

   let data_to_stage2 = Data_Stage1_to_Stage2 {pc            : pc,
					       instr         : instr,
					       op_stage2     : alu_outputs.op_stage2,
					       rd            : alu_outputs.rd,
					       addr          : alu_outputs.addr,
					       val1          : alu_outputs.val1,
					       val2          : alu_outputs.val2,
`ifdef ISA_F
					       val3          : alu_outputs.val3,
					       rd_in_fpr     : alu_outputs.rd_in_fpr,
					       rounding_mode : alu_outputs.rm,
`endif
`ifdef INCLUDE_TANDEM_VERIF
					       trace_data    : alu_outputs.trace_data,
`endif
					       priv          : cur_priv };

   // ----------------
   // Combinational output function

   function Output_Stage1 fv_out;
      Output_Stage1 output_stage1 = ?;

      // This stage is empty
      if (! rg_full) begin
	 output_stage1.ostatus = OSTATUS_EMPTY;
      end

      // Stall if IMem not ready
      else if (! imem.valid) begin
	 output_stage1.ostatus = OSTATUS_BUSY;
      end

      // Stall if bypass pending for rs1 or rs2
      else if (rs1_busy || rs2_busy) begin
	 output_stage1.ostatus = OSTATUS_BUSY;
      end

      // Trap on IMem exception
      else if (imem.exc) begin
	 output_stage1.ostatus   = OSTATUS_NONPIPE;
	 output_stage1.control   = CONTROL_TRAP;
	 output_stage1.trap_info = Trap_Info {epc:      pc,
					      exc_code: imem.exc_code,
					      tval:     imem.tval};
	 output_stage1.data_to_stage2 = data_to_stage2;
      end

      // ALU outputs: pipe (straight/branch)
      // and non-pipe (CSRR_W, CSRR_S_or_C, FENCE.I, FENCE, SFENCE_VMA, xRET, WFI, TRAP)
      else begin
	 let ostatus = (  (   (alu_outputs.control == CONTROL_STRAIGHT)
			   || (alu_outputs.control == CONTROL_BRANCH))
			? OSTATUS_PIPE
			: OSTATUS_NONPIPE);

	 // Compute MTVAL in case of traps
	 let tval = 0;
	 if (alu_outputs.exc_code == exc_code_ILLEGAL_INSTRUCTION)
	    tval = (is_i32_not_i16
		    ? zeroExtend (instr)
		    : zeroExtend (instr_C));                   // The instruction
	 else if (alu_outputs.exc_code == exc_code_INSTR_ADDR_MISALIGNED)
	    tval = alu_outputs.addr;                           // The branch target pc
	 else if (alu_outputs.exc_code == exc_code_BREAKPOINT)
	    tval = pc;                                         // The faulting virtual address

	 let trap_info = Trap_Info {epc:      pc,
				    exc_code: alu_outputs.exc_code,
				    tval:     tval};

	 let fall_through_pc = pc + (imem.is_i32_not_i16 ? 4 : 2);
	 let next_pc = ((alu_outputs.control == CONTROL_BRANCH)
			? alu_outputs.addr
			: fall_through_pc);

	 output_stage1.ostatus        = ostatus;
	 output_stage1.control        = alu_outputs.control;
	 output_stage1.trap_info      = trap_info;
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
   endmethod

   // ---- Input
   method Action enq (Addr next_pc, Priv_Mode priv, Bit #(1) sstatus_SUM, Bit #(1) mstatus_MXR, WordXL satp);
      imem.req (f3_LW, next_pc, priv, sstatus_SUM, mstatus_MXR, satp);

      if (verbosity > 1)
	 $display ("    CPU_Stage1.enq: 0x%08h", next_pc);
   endmethod

   method Action set_full (Bool full);
      rg_full <= full;
   endmethod
endmodule

// ================================================================

endpackage
