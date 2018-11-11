// Copyright (c) 2016-2018 Bluespec, Inc. All Rights Reserved

package CPU_Decode_C;

// ================================================================
// This is a function that decodes and expands a 16-bit "compressed"
// RISC-V instruction ('C' extension) into its full 32-bit equivalent.

// ================================================================
// Exports

// TODO: fill in

// ================================================================
// BSV library imports

// None

// ----------------
// BSV additional libs

// None

// ================================================================
// Project imports

import ISA_Decls   :: *;
import CPU_Globals :: *;

// ================================================================
// 'C' Extension Stack-Pointer-Based Loads

// LWSP: expands into LW
function Maybe #(Instr) fv_decode_C_LWSP (MISA  misa, Bit #(2)  xl, Instr_C  instr_C);
   begin
      // Instr fields: I-type
      match { .funct3, .imm_at_12, .rd, .imm_at_6_2, .op } = fv_ifields_CI_type (instr_C);
      Bit #(8) offset = { imm_at_6_2 [1:0], imm_at_12, imm_at_6_2 [4:2], 2'b0};

      Bool is_legal = ((misa.c == 1'b1)
		       && (op == opcode_C2)
		       && (rd != 0)
		       && (funct3 == funct3_C_LWSP));

      RegName rs1   = reg_sp;
      let     instr = mkInstr_I_type (zeroExtend (offset),  rs1,  f3_LW,  rd,  op_LOAD);

      return (is_legal ? tagged Valid instr : tagged Invalid);
   end
endfunction

`ifdef RV64
// LDSP: expands into LD
function Maybe #(Instr) fv_decode_C_LDSP (MISA  misa, Bit #(2)  xl, Instr_C  instr_C);
   begin
      // Instr fields: I-type
      match { .funct3, .imm_at_12, .rd, .imm_at_6_2, .op } = fv_ifields_CI_type  (instr_C);
      Bit #(9) offset = { imm_at_6_2 [2:0], imm_at_12, imm_at_6_2 [4:3], 3'b0 };

      Bool is_legal = ((misa.c == 1'b1)
		       && (op == opcode_C2)
		       && (rd != 0)
		       && (funct3 == funct3_C_LDSP)
		       && (   (xl == misa_mxl_64)
			   || (xl == misa_mxl_128)));

      RegName rs1   = reg_sp;
      let     instr = mkInstr_I_type (zeroExtend (offset),  rs1,  f3_LD,  rd,  op_LOAD);

      return (is_legal ? tagged Valid instr : tagged Invalid);
   end
endfunction
`endif

`ifdef RV128
// LQSP: expands into LQ
function Maybe #(Instr) fv_decode_C_LQSP (MISA  misa, Bit #(2)  xl, Instr_C  instr_C);
   begin
      // Instr fields: I-type
      match { .funct3, .imm_at_12, .rd, .imm_at_6_2, .op } = fv_ifields_CI_type  (instr_C);
      Bit #(10) offset = { imm_at_6_2 [3:0], imm_at_12, imm_at_6_2 [4], 4'b0 };

      Bool is_legal = ((misa.c == 1'b1)
		       && (op == opcode_C2)
		       && (rd != 0)
		       && (funct3 == funct3_C_LQSP)
		       && (xl == misa_mxl_128));

      RegName rs1   = reg_sp;
      let     instr = mkInstr_I_type (zeroExtend (offset),  rs1,  f3_LQ,  rd,  op_LOAD);

      return (is_legal ? tagged Valid instr : tagged Invalid);
   end
endfunction
`endif

`ifdef ISA_F
// FLWSP: expands into FLW
function Maybe #(Instr) fv_decode_C_FLWSP (MISA  misa, Bit #(2)  xl, Instr_C  instr_C);
   begin
      // Instr fields: I-type
      match { .funct3, .imm_at_12, .rd, .imm_at_6_2, .op } = fv_ifields_CI_type  (instr_C);
      Bit #(8) offset = { imm_at_6_2 [1:0], imm_at_12, imm_at_6_2 [4:2], 2'b0 };

      Bool is_legal = ((misa.c == 1'b1)
		       && (op == opcode_C2)
		       && (rd != 0)
		       && (funct3 == funct3_C_FLWSP)
		       && (misa.f == 1'b1));

      RegName rs1   = reg_sp;
      let     instr = mkInstr_I_type (zeroExtend (offset),  rs1,  f3_FLW,  rd,  op_LOAD_FP);

      return (is_legal ? tagged Valid instr : tagged Invalid);
   end
endfunction
`endif

`ifdef ISA_D
// FLDSP: expands into FLD
function Maybe #(Instr) fv_decode_C_FLDSP (MISA  misa,  Bit #(2) xl, Instr_C  instr_C);
   begin
      // Instr fields: I-type
      match { .funct3, .imm_at_12, .rd, .imm_at_6_2, .op } = fv_ifields_CI_type  (instr_C);
      Bit #(9) offset = { imm_at_6_2 [2:0], imm_at_12, imm_at_6_2 [4:3], 3'b0 };

      Bool is_legal = ((misa.c == 1'b1)
		       && (op == opcode_C2)
		       && (rd != 0)
		       && (funct3 == funct3_C_FLDSP)
		       && (misa.d == 1'b1)
		       && (   (xl == misa_mxl_64)
			   || (xl == misa_mxl_128)));

      RegName rs1   = reg_sp;
      let     instr = mkInstr_I_type (zeroExtend (offset),  rs1,  f3_FLD,  rd,  op_LOAD_FP);

      return (is_legal ? tagged Valid instr : tagged Invalid);
   end
endfunction
`endif

// ================================================================
// 'C' Extension Stack-Pointer-Based Stores

// SWSP: expands to SW
function Maybe #(Instr) fv_decode_C_SWSP (MISA  misa,  Bit #(2)  xl, Instr_C  instr_C);
   begin
      // Instr fields: CSS-type
      match { .funct3, .imm_at_12_7, .rs2, .op } = fv_ifields_CSS_type (instr_C);
      Bit #(8) offset = { imm_at_12_7 [1:0], imm_at_12_7 [5:2], 2'b0 };

      Bool is_legal = ((misa.c == 1'b1)
		       && (op == opcode_C2)
		       && (funct3 == funct3_C_SWSP));

      RegName   rs1   = reg_sp;
      let       instr = mkInstr_S_type (zeroExtend (offset), rs2, rs1, f3_SW, op_STORE);

      return (is_legal ? tagged Valid instr : tagged Invalid);
   end
endfunction

`ifdef RV64
// SDSP: expands to SD
function Maybe #(Instr) fv_decode_C_SDSP (MISA  misa,  Bit #(2)  xl, Instr_C  instr_C);
   begin
      // Instr fields: CSS-type
      match { .funct3, .imm_at_12_7, .rs2, .op } = fv_ifields_CSS_type (instr_C);
      Bit #(9) offset = { imm_at_12_7 [2:0], imm_at_12_7 [5:3], 3'b0 };

      Bool is_legal = ((misa.c == 1'b1)
		       && (op == opcode_C2)
		       && (funct3 == funct3_C_SDSP)
		       && (   (xl == misa_mxl_64)
			   || (xl == misa_mxl_128)));

      RegName   rs1   = reg_sp;
      let       instr = mkInstr_S_type (zeroExtend (offset), rs2, rs1, f3_SD, op_STORE);

      return (is_legal ? tagged Valid instr : tagged Invalid);
   end
endfunction
`endif

`ifdef RV128
// SQSP: expands to SQ
function Maybe #(Instr) fv_decode_C_SQSP (MISA  misa,  Bit #(2)  xl, Instr_C  instr_C);
   begin
      // Instr fields: CSS-type
      match { .funct3, .imm_at_12_7, .rs2, .op } = fv_ifields_CSS_type (instr_C);
      Bit #(10) offset = { imm_at_12_7 [3:0], imm_at_12_7 [5:4], 4'b0 };

      Bool is_legal = ((misa.c == 1'b1)
		       && (op == opcode_C2)
		       && (funct3 == funct3_C_SQSP)
		       && (xl == misa_mxl_128));

      RegName   rs1   = reg_sp;
      let       instr = mkInstr_S_type (zeroExtend (offset), rs2, rs1, f3_SQ, op_STORE);

      return (is_legal ? tagged Valid instr : tagged Invalid);
   end
endfunction
`endif

`ifdef ISA_F
// FSWSP: expands to FSW
function Maybe #(Instr) fv_decode_C_FSWSP (MISA  misa,  Bit #(2)  xl, Instr_C  instr_C);
   begin
      // Instr fields: CSS-type
      match { .funct3, .imm_at_12_7, .rs2, .op } = fv_ifields_CSS_type (instr_C);
      Bit #(8) offset = { imm_at_12_7 [1:0], imm_at_12_7 [5:2], 2'b0 };

      Bool is_legal = ((misa.c == 1'b1)
		       && (op == opcode_C2)
		       && (funct3 == funct3_C_FSWSP));

      RegName   rs1   = reg_sp;
      let       instr = mkInstr_S_type (zeroExtend (offset), rs2, rs1, f3_FSW, op_STORE_FP);

      return (is_legal ? tagged Valid instr : tagged Invalid);
   end
endfunction
`endif

`ifdef ISA_D
// FSDSP: expands to FSD
function Maybe #(Instr) fv_decode_C_FSDSP (MISA  misa,  Bit #(2)  xl, Instr_C  instr_C);
   begin
      // Instr fields: CSS-type
      match { .funct3, .imm_at_12_7, .rs2, .op } = fv_ifields_CSS_type (instr_C);
      Bit #(9) offset = { imm_at_12_7 [2:0], imm_at_12_7 [5:3], 3'b0 };

      Bool is_legal = ((misa.c == 1'b1)
		       && (op == opcode_C2)
		       && (funct3 == funct3_C_FSDSP)
		       && (   (xl == misa_mxl_64)
			   || (xl == misa_mxl_128)));

      RegName   rs1   = reg_sp;
      let       instr = mkInstr_S_type (zeroExtend (offset), rs2, rs1, f3_FSD, op_STORE_FP);

      return (is_legal ? tagged Valid instr : tagged Invalid);
   end
endfunction
`endif

// ================================================================
// 'C' Extension Register-Based Loads

// C_LW: expands to LW
function Maybe #(Instr) fv_decode_C_LW (MISA  misa,  Bit #(2)  xl,  Instr_C  instr_C);
   begin
      // Instr fields: CL-type
      match { .funct3, .imm_at_12_10, .rs1, .imm_at_6_5, .rd, .op } = fv_ifields_CL_type (instr_C);
      Bit #(7) offset = { imm_at_6_5 [0], imm_at_12_10, imm_at_6_5 [1], 2'b0 };

      Bool is_legal = ((misa.c == 1'b1)
		       && (op == opcode_C0)
		       && (funct3 == funct3_C_LW));

      let instr = mkInstr_I_type (zeroExtend (offset),  rs1,  f3_LW,  rd,  op_LOAD);

      return (is_legal ? tagged Valid instr : tagged Invalid);
   end
endfunction

`ifdef RV64
// C_LD: expands to LD
function Maybe #(Instr) fv_decode_C_LD (MISA  misa,  Bit #(2)  xl,  Instr_C  instr_C);
   begin
      // Instr fields: CL-type
      match { .funct3, .imm_at_12_10, .rs1, .imm_at_6_5, .rd, .op } = fv_ifields_CL_type (instr_C);
      Bit #(8) offset = { imm_at_6_5, imm_at_12_10, 3'b0 };

      Bool is_legal = ((misa.c == 1'b1)
		       && (op == opcode_C0)
		       && (funct3 == funct3_C_LD)
		       && (   (xl == misa_mxl_64)
			   || (xl == misa_mxl_128)));

      let instr = mkInstr_I_type (zeroExtend (offset),  rs1,  f3_LD,  rd,  op_LOAD);

      return (is_legal ? tagged Valid instr : tagged Invalid);
   end
endfunction
`endif

`ifdef RV128
// C_LQ: expands to LQ
function Maybe #(Instr) fv_decode_C_LQ (MISA  misa,  Bit #(2)  xl,  Instr_C  instr_C);
   begin
      // Instr fields: CL-type
      match { .funct3, .imm_at_12_10, .rs1, .imm_at_6_5, .rd, .op } = fv_ifields_CL_type (instr_C);
      Bit #(9) offset = { imm_at_12_10 [0], imm_at_6_5, imm_at_12_10 [2], imm_at_12_10 [1], 4'b0 };

      Bool is_legal = ((misa.c == 1'b1)
		       && (op == opcode_C0)
		       && (funct3 == funct3_C_LQ)
		       && (xl == misa_mxl_128));

      let     instr = mkInstr_I_type (zeroExtend (offset),  rs1,  f3_LQ,  rd,  op_LOAD);

      return (is_legal ? tagged Valid instr : tagged Invalid);
   end
endfunction
`endif

`ifdef ISA_F
// C_FLW: expands to FLW
function Maybe #(Instr) fv_decode_C_FLW (MISA  misa,  Bit #(2)  xl,  Instr_C  instr_C);
   begin
      // Instr fields: CL-type
      match { .funct3, .imm_at_12_10, .rs1, .imm_at_6_5, .rd, .op } = fv_ifields_CL_type (instr_C);
      Bit #(7) offset = { imm_at_6_5 [0], imm_at_12_10, imm_at_6_5 [1], 2'b0 };

      Bool is_legal = ((misa.c == 1'b1)
		       && (op == opcode_C0)
		       && (funct3 == funct3_C_FLW));

      let     instr = mkInstr_I_type (zeroExtend (offset),  rs1,  f3_FLW,  rd,  op_LOAD);

      return (is_legal ? tagged Valid instr : tagged Invalid);
   end
endfunction
`endif

`ifdef ISA_D
// C_FLD: expands to FLD
function Maybe #(Instr) fv_decode_C_FLD (MISA  misa,  Bit #(2)  xl,  Instr_C  instr_C);
   begin
      // Instr fields: CL-type
      match { .funct3, .imm_at_12_10, .rs1, .imm_at_6_5, .rd, .op } = fv_ifields_CL_type (instr_C);
      Bit #(8) offset = { imm_at_6_5, imm_at_12_10, 3'b0 };

      Bool is_legal = ((misa.c == 1'b1)
		       && (op == opcode_C0)
		       && (funct3 == funct3_C_FLD)
		       && (   (xl == misa_mxl_64)
			   || (xl == misa_mxl_128)));

      let     instr = mkInstr_I_type (zeroExtend (offset),  rs1,  f3_FLD,  rd,  op_LOAD);

      return (is_legal ? tagged Valid instr : tagged Invalid);
   end
endfunction
`endif

// ================================================================
// 'C' Extension Register-Based Stores

// C_SW: expands to SW
function Maybe #(Instr) fv_decode_C_SW (MISA  misa,  Bit #(2)  xl,  Instr_C  instr_C);
   begin
      // Instr fields: CS-type
      match { .funct3, .imm_at_12_10, .rs1, .imm_at_6_5, .rs2, .op } = fv_ifields_CS_type (instr_C);
      Bit #(7) offset = { imm_at_6_5 [0], imm_at_12_10, imm_at_6_5 [1], 2'b0 };

      Bool is_legal = ((misa.c == 1'b1)
		       && (op == opcode_C0)
		       && (funct3 == funct3_C_SW));

      let instr = mkInstr_S_type (zeroExtend (offset), rs2, rs1, f3_SW, op_STORE);
      
      return (is_legal ? tagged Valid instr : tagged Invalid);
   end
endfunction

`ifdef RV64
// C_SD: expands to SD
function Maybe #(Instr) fv_decode_C_SD (MISA  misa,  Bit #(2)  xl,  Instr_C  instr_C);
   begin
      // Instr fields: CS-type
      match { .funct3, .imm_at_12_10, .rs1, .imm_at_6_5, .rs2, .op } = fv_ifields_CS_type (instr_C);
      Bit #(8) offset = { imm_at_6_5, imm_at_12_10, 3'b0 };

      Bool is_legal = ((misa.c == 1'b1)
		       && (op == opcode_C0)
		       && (funct3 == funct3_C_SD));

      let instr = mkInstr_S_type (zeroExtend (offset), rs2, rs1, f3_SD, op_STORE);
      
      return (is_legal ? tagged Valid instr : tagged Invalid);
   end
endfunction
`endif

`ifdef RV128
// C_SQ: expands to SQ
function Maybe #(Instr) fv_decode_C_SQ (MISA  misa,  Bit #(2)  xl,  Instr_C  instr_C);
   begin
      // Instr fields: CS-type
      match { .funct3, .imm_at_12_10, .rs1, .imm_at_6_5, .rs2, .op } = fv_ifields_CS_type (instr_C);
      Bit #(9) offset = { imm_at_12_10 [0], imm_at_6_5, imm_at_12_10 [2], imm_at_12_10 [1], 4'b0 };

      Bool is_legal = ((misa.c == 1'b1)
		       && (op == opcode_C0)
		       && (funct3 == funct3_C_SQ));

      let instr = mkInstr_S_type (zeroExtend (offset), rs2, rs1, f3_SQ, op_STORE);
      
      return (is_legal ? tagged Valid instr : tagged Invalid);
   end
endfunction
`endif

`ifdef ISA_F
// C_FSW: expands to FSW
function Maybe #(Instr) fv_decode_C_FSW (MISA  misa,  Bit #(2)  xl,  Instr_C  instr_C);
   begin
      // Instr fields: CS-type
      match { .funct3, .imm_at_12_10, .rs1, .imm_at_6_5, .rs2, .op } = fv_ifields_CS_type (instr_C);
      Bit #(7) offset = { imm_at_6_5 [0], imm_at_12_10, imm_at_6_5 [1], 2'b0 };

      Bool is_legal = ((misa.c == 1'b1)
		       && (op == opcode_C0)
		       && (funct3 == funct3_C_FSW));

      let instr = mkInstr_S_type (zeroExtend (offset), rs2, rs1, f3_FSW, op_STORE_FP);
      
      return (is_legal ? tagged Valid instr : tagged Invalid);
   end
endfunction
`endif

`ifdef ISA_D
// C_FSD: expands to FSD
function Maybe #(Instr) fv_decode_C_FSD (MISA  misa,  Bit #(2)  xl,  Instr_C  instr_C);
   begin
      // Instr fields: CS-type
      match { .funct3, .imm_at_12_10, .rs1, .imm_at_6_5, .rs2, .op } = fv_ifields_CS_type (instr_C);
      Bit #(8) offset = { imm_at_6_5, imm_at_12_10, 3'b0 };

      Bool is_legal = ((misa.c == 1'b1)
		       && (op == opcode_C0)
		       && (funct3 == funct3_C_FSD));

      let instr = mkInstr_S_type (zeroExtend (offset), rs2, rs1, f3_FSD, op_STORE_FP);
      
      return (is_legal ? tagged Valid instr : tagged Invalid);
   end
endfunction
`endif

// ================================================================
// 'C' Extension Control Transfer
// C.J, C.JAL, C.JR, C.JALR, C.BEQZ, C.BNEZ

// C.J: expands to JAL
function Maybe #(Instr) fv_decode_C_J (MISA  misa,  Bit #(2)  xl,  Instr_C  instr_C);
   begin
      // Instr fields: CJ-type
      match { .funct3, .imm_at_12_2, .op } = fv_ifields_CJ_type (instr_C);
      Bit #(12) offset = {imm_at_12_2 [10],
			  imm_at_12_2 [6],
			  imm_at_12_2 [8:7],
			  imm_at_12_2 [4],
			  imm_at_12_2 [5],
			  imm_at_12_2 [0],
			  imm_at_12_2 [9],
			  imm_at_12_2 [3:1],
			  1'b0};

      Bool is_legal = ((misa.c == 1'b1)
		       && (op == opcode_C1)
		       && (funct3 == funct3_C_J));

      RegName   rd    = reg_zero;
      Bit #(21) imm21 = signExtend (offset);
      let       instr = mkInstr_J_type (imm21, rd, op_JAL);
      
      return (is_legal ? tagged Valid instr : tagged Invalid);
   end
endfunction

// C.JAL: expands to JAL
function Maybe #(Instr) fv_decode_C_JAL (MISA  misa,  Bit #(2)  xl,  Instr_C  instr_C);
   begin
      // Instr fields: CJ-type
      match { .funct3, .imm_at_12_2, .op } = fv_ifields_CJ_type (instr_C);
      Bit #(12) offset = {imm_at_12_2 [10],
			  imm_at_12_2 [6],
			  imm_at_12_2 [8:7],
			  imm_at_12_2 [4],
			  imm_at_12_2 [5],
			  imm_at_12_2 [0],
			  imm_at_12_2 [9],
			  imm_at_12_2 [3:1],
			  1'b0};

      Bool is_legal = ((misa.c == 1'b1)
		       && (op == opcode_C1)
		       && (funct3 == funct3_C_JAL)
		       && (xl == misa_mxl_32));

      RegName   rd    = reg_ra;
      Bit #(21) imm21 = signExtend (offset);
      let       instr = mkInstr_J_type  (imm21,  rd,  op_JAL);
      
      return (is_legal ? tagged Valid instr : tagged Invalid);
   end
endfunction

// C.JR: expands to JALR
function Maybe #(Instr) fv_decode_C_JR (MISA  misa,  Bit #(2)  xl,  Instr_C  instr_C);
   begin
      // Instr fields: CR-type
      match { .funct4, .rs1, .rs2, .op } = fv_ifields_CR_type (instr_C);

      Bool is_legal = ((misa.c == 1'b1)
		       && (op == opcode_C2)
		       && (funct4 == funct4_C_JR)
		       && (rs1 != 0)
		       && (rs2 == 0));

      RegName   rd    = reg_zero;
      Bit #(12) imm12 = 0;
      let       instr = mkInstr_I_type (imm12, rs1, funct3_JALR, rd, op_JALR);
      return (is_legal ? tagged Valid instr : tagged Invalid);
   end
endfunction

// C.JALR: expands to JALR
function Maybe #(Instr) fv_decode_C_JALR (MISA  misa,  Bit #(2)  xl,  Instr_C  instr_C);
   begin
      // Instr fields: CR-type
      match { .funct4, .rs1, .rs2, .op } = fv_ifields_CR_type (instr_C);

      Bool is_legal = ((misa.c == 1'b1)
		       && (op == opcode_C2)
		       && (funct4 == funct4_C_JALR)
		       && (rs1 != 0)
		       && (rs2 == 0));

      RegName   rd    = reg_ra;
      Bit #(12) imm12 = 0;
      let       instr = mkInstr_I_type (imm12, rs1, funct3_JALR, rd, op_JALR);

      return (is_legal ? tagged Valid instr : tagged Invalid);
   end
endfunction

// C.BEQZ: expands to BEQ
function Maybe #(Instr) fv_decode_C_BEQZ (MISA  misa,  Bit #(2)  xl,  Instr_C  instr_C);
   begin
      // Instr fields: CB-type
      match { .funct3, .imm_at_12_10, .rs1, .imm_at_6_2, .op } = fv_ifields_CB_type (instr_C);
      Bit #(9) offset = { imm_at_12_10 [2], imm_at_6_2 [4:3], imm_at_6_2 [0], imm_at_12_10 [1:0], imm_at_6_2 [2:1], 1'b0 };
      
      Bool is_legal = ((misa.c == 1'b1)
		       && (op == opcode_C1)
		       && (funct3 == funct3_C_BEQZ));

      RegName   rs2   = reg_zero;
      Bit #(13) imm13 = signExtend (offset);
      let       instr = mkInstr_B_type (imm13, rs2, rs1, f3_BEQ, op_BRANCH);

      return (is_legal ? tagged Valid instr : tagged Invalid);
   end
endfunction

// C.BNEZ: expands to BNE
function Maybe #(Instr) fv_decode_C_BNEZ (MISA  misa,  Bit #(2)  xl,  Instr_C  instr_C);
   begin
      // Instr fields: CB-type
      match { .funct3, .imm_at_12_10, .rs1, .imm_at_6_2, .op } = fv_ifields_CB_type (instr_C);
      Bit #(9) offset = { imm_at_12_10 [2], imm_at_6_2 [4:3], imm_at_6_2 [0], imm_at_12_10 [1:0], imm_at_6_2 [2:1], 1'b0 };
      
      Bool is_legal = ((misa.c == 1'b1)
		       && (op == opcode_C1)
		       && (funct3 == funct3_C_BNEZ));

      RegName   rs2   = reg_zero;
      Bit #(13) imm13 = signExtend (offset);
      let       instr = mkInstr_B_type (imm13, rs2, rs1, f3_BNE, op_BRANCH);

      return (is_legal ? tagged Valid instr : tagged Invalid);
   end
endfunction

// ================================================================
// 'C' Extension Integer Constant-Generation

// C.LI: expands to ADDI
function Maybe #(Instr) fv_decode_C_LI (MISA  misa,  Bit #(2)  xl,  Instr_C  instr_C);
   begin
      // Instr fields: CI-type
      match { .funct3, .imm_at_12, .rd, .imm_at_6_2, .op } = fv_ifields_CI_type (instr_C);
      Bit #(6) imm6 = { imm_at_12, imm_at_6_2 };

      Bool is_legal = ((misa.c == 1'b1)
		       && (op == opcode_C1)
		       && (funct3 == funct3_C_LI)
		       && (rd != 0));

      RegName   rs1   = reg_zero;
      Bit #(12) imm12 = signExtend (imm6);
      let       instr = mkInstr_I_type (imm12, rs1, f3_ADDI, rd, op_OP_IMM);

      return (is_legal ? tagged Valid instr : tagged Invalid);
   end
endfunction

// C.LUI: expands to LUI
function Maybe #(Instr) fv_decode_C_LUI (MISA  misa,  Bit #(2)  xl,  Instr_C  instr_C);
   begin
      // Instr fields: CI-type
      match { .funct3, .imm_at_12, .rd, .imm_at_6_2, .op } = fv_ifields_CI_type (instr_C);
      Bit #(18) nzimm18 = { imm_at_12, imm_at_6_2, 12'b0 };

      Bool is_legal = ((misa.c == 1'b1)
		       && (op == opcode_C1)
		       && (funct3 == funct3_C_LUI)
		       && (rd != 0)
		       && (rd != 2)
		       && (nzimm18 != 0));

      Bit #(20) imm20 = signExtend (nzimm18);
      let       instr = mkInstr_U_type (imm20, rd, op_LUI);

      return (is_legal ? tagged Valid instr : tagged Invalid);
   end
endfunction

// ================================================================
// 'C' Extension Integer Register-Immediate Operations

// C.ADDI: expands to ADDI
function Maybe #(Instr) fv_decode_C_ADDI (MISA  misa,  Bit #(2)  xl,  Instr_C  instr_C);
   begin
      // Instr fields: CI-type
      match { .funct3, .imm_at_12, .rd_rs1, .imm_at_6_2, .op } = fv_ifields_CI_type (instr_C);
      Bit #(6) nzimm6 = { imm_at_12, imm_at_6_2 };

      Bool is_legal = ((misa.c == 1'b1)
		       && (op == opcode_C1)
		       && (funct3 == funct3_C_ADDI)
		       && (rd_rs1 != 0)
		       && (nzimm6 != 0));

      Bit #(12) imm12 = signExtend (nzimm6);
      let       instr = mkInstr_I_type (imm12, rd_rs1, f3_ADDI, rd_rs1, op_OP_IMM);

      return (is_legal ? tagged Valid instr : tagged Invalid);
   end
endfunction

// C.NOP: expands to ADDI
function Maybe #(Instr) fv_decode_C_NOP (MISA  misa,  Bit #(2)  xl,  Instr_C  instr_C);
   begin
      // Instr fields: CI-type
      match { .funct3, .imm_at_12, .rd_rs1, .imm_at_6_2, .op } = fv_ifields_CI_type (instr_C);
      Bit #(6) nzimm6 = { imm_at_12, imm_at_6_2 };

      Bool is_legal = ((misa.c == 1'b1)
		       && (op == opcode_C1)
		       && (funct3 == funct3_C_NOP)
		       && (rd_rs1 == 0)
		       && (nzimm6 == 0));

      Bit #(12) imm12 = signExtend (nzimm6);
      let       instr = mkInstr_I_type (imm12, rd_rs1, f3_ADDI, rd_rs1, op_OP_IMM);

      return (is_legal ? tagged Valid instr : tagged Invalid);
   end
endfunction

// C.ADDIW: expands to ADDIW
function Maybe #(Instr) fv_decode_C_ADDIW (MISA  misa,  Bit #(2)  xl,  Instr_C  instr_C);
   begin
      // Instr fields: CI-type
      match { .funct3, .imm_at_12, .rd_rs1, .imm_at_6_2, .op } = fv_ifields_CI_type (instr_C);
      Bit #(6) imm6 = { imm_at_12, imm_at_6_2 };

      Bool is_legal = ((misa.c == 1'b1)
		       && (op == opcode_C1)
		       && (funct3 == funct3_C_ADDIW)
		       && (rd_rs1 != 0)
		       && (   (xl == misa_mxl_64)
			   || (xl == misa_mxl_128)));

      Bit #(12) imm12 = signExtend (imm6);
      let       instr = mkInstr_I_type (imm12, rd_rs1, f3_ADDIW, rd_rs1, op_OP_IMM_32);

      return (is_legal ? tagged Valid instr : tagged Invalid);
   end
endfunction

// C.ADDI16SP: expands to ADDI
function Maybe #(Instr) fv_decode_C_ADDI16SP (MISA  misa,  Bit #(2)  xl,  Instr_C  instr_C);
   begin
      // Instr fields: CI-type
      match { .funct3, .imm_at_12, .rd_rs1, .imm_at_6_2, .op } = fv_ifields_CI_type (instr_C);
      Bit #(10) nzimm10 = { imm_at_12, imm_at_6_2 [2:1], imm_at_6_2 [3], imm_at_6_2 [0], imm_at_6_2 [4], 4'b0 };

      Bool is_legal = ((misa.c == 1'b1)
		       && (op == opcode_C1)
		       && (funct3 == funct3_C_ADDI16SP)
		       && (rd_rs1 == reg_sp)
		       && (nzimm10 != 0));

      Bit #(12) imm12 = signExtend (nzimm10);
      let       instr = mkInstr_I_type (imm12, rd_rs1, f3_ADDI, rd_rs1, op_OP_IMM);

      return (is_legal ? tagged Valid instr : tagged Invalid);
   end
endfunction

// C.ADDI4SPN: expands to ADDI
function Maybe #(Instr) fv_decode_C_ADDI4SPN (MISA  misa,  Bit #(2)  xl,  Instr_C  instr_C);
   begin
      // Instr fields: CIW-type
      match { .funct3, .imm_at_12_5, .rd, .op } = fv_ifields_CIW_type (instr_C);
      Bit #(10) nzimm10 = { imm_at_12_5 [5:2], imm_at_12_5 [7:6], imm_at_12_5 [0], imm_at_12_5 [1], 2'b0 };

      Bool is_legal = ((misa.c == 1'b1)
		       && (op == opcode_C0)
		       && (funct3 == funct3_C_ADDI4SPN)
		       && (nzimm10 != 0));

      RegName   rs1   = reg_sp;
      Bit #(12) imm12 = signExtend (nzimm10);
      let       instr = mkInstr_I_type (imm12, rs1, f3_ADDI, rd, op_OP_IMM);

      return (is_legal ? tagged Valid instr : tagged Invalid);
   end
endfunction

// C.SLLI: expands to SLLI
function Maybe #(Instr) fv_decode_C_SLLI (MISA  misa,  Bit #(2)  xl,  Instr_C  instr_C);
   begin
      // Instr fields: CI-type
      match { .funct3, .imm_at_12, .rd_rs1, .imm_at_6_2, .op } = fv_ifields_CI_type (instr_C);
      Bit #(6) shamt6 = { imm_at_12, imm_at_6_2 };

      Bool is_legal = ((misa.c == 1'b1)
		       && (op == opcode_C2)
		       && (funct3 == funct3_C_SLLI)
		       && (rd_rs1 != 0)
                       && (shamt6 != 0)
		       && ((xl == misa_mxl_32) ? (imm_at_12 == 0) : True));

      Bit #(12) imm12 = (  (xl == misa_mxl_32)
			 ? { msbs7_SLLI, imm_at_6_2 }
			 : { msbs6_SLLI, shamt6 } );
      let       instr = mkInstr_I_type (imm12, rd_rs1, f3_SLLI, rd_rs1, op_OP_IMM);

      return (is_legal ? tagged Valid instr : tagged Invalid);
   end
endfunction

// C.SRLI: expands to SRLI
function Maybe #(Instr) fv_decode_C_SRLI (MISA  misa,  Bit #(2)  xl,  Instr_C  instr_C);
   begin
      // Instr fields: CB-type
      match { .funct3, .imm_at_12_10, .rd_rs1, .imm_at_6_2, .op } = fv_ifields_CB_type (instr_C);
      Bit #(1) shamt6_5 = imm_at_12_10 [2];
      Bit #(2) funct2   = imm_at_12_10 [1:0];
      Bit #(6) shamt6   = { shamt6_5, imm_at_6_2 };

      Bool is_legal = ((misa.c == 1'b1)
		       && (op == opcode_C1)
		       && (funct3 == funct3_C_SRLI)
		       && (funct2 == funct2_C_SRLI)
		       && (rd_rs1 != 0)
                       && (shamt6 != 0)
		       && ((xl == misa_mxl_32) ? (shamt6_5 == 0) : True));

      Bit #(12) imm12 = (  (xl == misa_mxl_32)
			 ? { msbs7_SRLI, imm_at_6_2 }
			 : { msbs6_SRLI, shamt6 } );
      let       instr = mkInstr_I_type (imm12, rd_rs1, f3_SRLI, rd_rs1, op_OP_IMM);

      return (is_legal ? tagged Valid instr : tagged Invalid);
   end
endfunction

// C.SRAI: expands to SRAI
function Maybe #(Instr) fv_decode_C_SRAI (MISA  misa,  Bit #(2)  xl,  Instr_C  instr_C);
   begin
      // Instr fields: CB-type
      match { .funct3, .imm_at_12_10, .rd_rs1, .imm_at_6_2, .op } = fv_ifields_CB_type (instr_C);
      Bit #(1) shamt6_5 = imm_at_12_10 [2];
      Bit #(2) funct2   = imm_at_12_10 [1:0];
      Bit #(6) shamt6   = { shamt6_5, imm_at_6_2 };

      Bool is_legal = ((misa.c == 1'b1)
		       && (op == opcode_C1)
		       && (funct3 == funct3_C_SRAI)
		       && (funct2 == funct2_C_SRAI)
		       && (rd_rs1 != 0)
                       && (shamt6 != 0)
		       && ((xl == misa_mxl_32) ? (shamt6_5 == 0) : True));

      Bit #(12) imm12 = (  (xl == misa_mxl_32)
			 ? { msbs7_SRAI, imm_at_6_2 }
			 : { msbs6_SRAI, shamt6 } );
      let       instr = mkInstr_I_type (imm12, rd_rs1, f3_SRAI, rd_rs1, op_OP_IMM);

      return (is_legal ? tagged Valid instr : tagged Invalid);
   end
endfunction

// C.ANDI: expands to ANDI
function Maybe #(Instr) fv_decode_C_ANDI (MISA  misa,  Bit #(2)  xl,  Instr_C  instr_C);
   begin
      // Instr fields: CB-type
      match { .funct3, .imm_at_12_10, .rd_rs1, .imm_at_6_2, .op } = fv_ifields_CB_type (instr_C);
      Bit #(1) imm6_5 = imm_at_12_10 [2];
      Bit #(6) imm6   = { imm6_5, imm_at_6_2 };
      Bit #(2) funct2 = imm_at_12_10 [1:0];

      Bool is_legal = ((misa.c == 1'b1)
		       && (op == opcode_C1)
		       && (funct3 == funct3_C_ANDI)
		       && (funct2 == funct2_C_ANDI));

      Bit #(12) imm12 = signExtend (imm6);
      let       instr = mkInstr_I_type (imm12, rd_rs1, f3_ANDI, rd_rs1, op_OP_IMM);

      return (is_legal ? tagged Valid instr : tagged Invalid);
   end
endfunction

// ================================================================
// 'C' Extension Integer Register-Register Operations

// C.MV: expands to ADD
function Maybe #(Instr) fv_decode_C_MV (MISA  misa,  Bit #(2)  xl,  Instr_C  instr_C);
   begin
      match { .funct4, .rd_rs1, .rs2, .op } = fv_ifields_CR_type (instr_C);

      Bool is_legal = ((misa.c == 1'b1)
		       && (op == opcode_C2)
		       && (funct4 == funct4_C_MV)
		       && (rd_rs1 != 0)
		       && (rs2 != 0));

      RegName rs1   = reg_zero;
      let     instr = mkInstr_R_type (funct7_ADD, rs2, rs1, funct3_ADD, rd_rs1, op_OP);

      return (is_legal ? tagged Valid instr : tagged Invalid);
   end
endfunction

// C.ADD: expands to ADD
function Maybe #(Instr) fv_decode_C_ADD (MISA  misa,  Bit #(2)  xl,  Instr_C  instr_C);
   begin
      match { .funct4, .rd_rs1, .rs2, .op } = fv_ifields_CR_type (instr_C);

      Bool is_legal = ((misa.c == 1'b1)
		       && (op == opcode_C2)
		       && (funct4 == funct4_C_ADD)
		       && (rd_rs1 != 0)
		       && (rs2 != 0));

      let     instr = mkInstr_R_type (funct7_ADD, rs2, rd_rs1, funct3_ADD, rd_rs1, op_OP);

      return (is_legal ? tagged Valid instr : tagged Invalid);
   end
endfunction

// C.AND: expands to AND
function Maybe #(Instr) fv_decode_C_AND (MISA  misa,  Bit #(2)  xl,  Instr_C  instr_C);
   begin
      // Instr fields: CS-type
      match { .funct3, .imm_at_12_10, .rd_rs1, .imm_at_6_5, .rs2, .op } = fv_ifields_CS_type (instr_C);
      Bit #(6) funct6 = { funct3, imm_at_12_10 };
      Bit #(2) funct2 = imm_at_6_5;

      Bool is_legal = ((misa.c == 1'b1)
		       && (op == opcode_C1)
		       && (funct6 == funct6_C_AND)
		       && (funct2 == funct2_C_AND));

      let instr = mkInstr_R_type (funct7_AND, rs2, rd_rs1, funct3_AND, rd_rs1, op_OP);

      return (is_legal ? tagged Valid instr : tagged Invalid);
   end
endfunction

// C.OR: expands to OR
function Maybe #(Instr) fv_decode_C_OR (MISA  misa,  Bit #(2)  xl,  Instr_C  instr_C);
   begin
      // Instr fields: CS-type
      match { .funct3, .imm_at_12_10, .rd_rs1, .imm_at_6_5, .rs2, .op } = fv_ifields_CS_type (instr_C);
      Bit #(6) funct6 = { funct3, imm_at_12_10 };
      Bit #(2) funct2 = imm_at_6_5;

      Bool is_legal = ((misa.c == 1'b1)
		       && (op == opcode_C1)
		       && (funct6 == funct6_C_OR)
		       && (funct2 == funct2_C_OR));

      let instr = mkInstr_R_type (funct7_OR, rs2, rd_rs1, funct3_OR, rd_rs1, op_OP);

      return (is_legal ? tagged Valid instr : tagged Invalid);
   end
endfunction

// C.XOR: expands to XOR
function Maybe #(Instr) fv_decode_C_XOR (MISA  misa,  Bit #(2)  xl,  Instr_C  instr_C);
   begin
      // Instr fields: CS-type
      match { .funct3, .imm_at_12_10, .rd_rs1, .imm_at_6_5, .rs2, .op } = fv_ifields_CS_type (instr_C);
      Bit #(6) funct6 = { funct3, imm_at_12_10 };
      Bit #(2) funct2 = imm_at_6_5;

      Bool is_legal = ((misa.c == 1'b1)
		       && (op == opcode_C1)
		       && (funct6 == funct6_C_XOR)
		       && (funct2 == funct2_C_XOR));

      let instr = mkInstr_R_type (funct7_XOR, rs2, rd_rs1, funct3_XOR, rd_rs1, op_OP);

      return (is_legal ? tagged Valid instr : tagged Invalid);
   end
endfunction

// C.SUB: expands to SUB
function Maybe #(Instr) fv_decode_C_SUB (MISA  misa,  Bit #(2)  xl,  Instr_C  instr_C);
   begin
      // Instr fields: CS-type
      match { .funct3, .imm_at_12_10, .rd_rs1, .imm_at_6_5, .rs2, .op } = fv_ifields_CS_type (instr_C);
      Bit #(6) funct6 = { funct3, imm_at_12_10 };
      Bit #(2) funct2 = imm_at_6_5;

      Bool is_legal = ((misa.c == 1'b1)
		       && (op == opcode_C1)
		       && (funct6 == funct6_C_SUB)
		       && (funct2 == funct2_C_SUB));

      let instr = mkInstr_R_type (funct7_SUB, rs2, rd_rs1, funct3_SUB, rd_rs1, op_OP);

      return (is_legal ? tagged Valid instr : tagged Invalid);
   end
endfunction

// C.ADDW: expands to ADDW
function Maybe #(Instr) fv_decode_C_ADDW (MISA  misa,  Bit #(2)  xl,  Instr_C  instr_C);
   begin
      // Instr fields: CS-type
      match { .funct3, .imm_at_12_10, .rd_rs1, .imm_at_6_5, .rs2, .op } = fv_ifields_CS_type (instr_C);
      Bit #(6) funct6 = { funct3, imm_at_12_10 };
      Bit #(2) funct2 = imm_at_6_5;

      Bool is_legal = ((misa.c == 1'b1)
		       && (op == opcode_C1)
		       && (funct6 == funct6_C_ADDW)
		       && (funct2 == funct2_C_ADDW)
		       && (   (xl == misa_mxl_64)
			   || (xl == misa_mxl_128)));

      let instr = mkInstr_R_type (funct7_ADDW, rs2, rd_rs1, funct3_ADDW, rd_rs1, op_OP_32);

      return (is_legal ? tagged Valid instr : tagged Invalid);
   end
endfunction

// C.SUBW: expands to SUBW
function Maybe #(Instr) fv_decode_C_SUBW (MISA  misa,  Bit #(2)  xl,  Instr_C  instr_C);
   begin
      // Instr fields: CS-type
      match { .funct3, .imm_at_12_10, .rd_rs1, .imm_at_6_5, .rs2, .op } = fv_ifields_CS_type (instr_C);
      Bit #(6) funct6 = { funct3, imm_at_12_10 };
      Bit #(2) funct2 = imm_at_6_5;

      Bool is_legal = ((misa.c == 1'b1)
		       && (op == opcode_C1)
		       && (funct6 == funct6_C_SUBW)
		       && (funct2 == funct2_C_SUBW)
		       && (   (xl == misa_mxl_64)
			   || (xl == misa_mxl_128)));

      let instr = mkInstr_R_type (funct7_SUBW, rs2, rd_rs1, funct3_SUBW, rd_rs1, op_OP_32);

      return (is_legal ? tagged Valid instr : tagged Invalid);
   end
endfunction

// ================================================================
// 'C' Extension EBREAK

// C.EBREAK: expands to EBREAK
function Maybe #(Instr) fv_decode_C_EBREAK (MISA  misa,  Bit #(2)  xl,  Instr_C  instr_C);
   begin
      // Instr fields: CR-type
      match { .funct4, .rd_rs1, .rs2, .op } = fv_ifields_CR_type (instr_C);

      Bool is_legal = ((misa.c == 1'b1)
		       && (op == opcode_C2)
		       && (funct4 == funct4_C_EBREAK)
		       && (rd_rs1 == 0)
		       && (rs2 == 0));

      Bit #(12) imm12 = f12_EBREAK;
      let       instr = mkInstr_I_type (imm12, rd_rs1, f3_PRIV,  rd_rs1, op_SYSTEM);

      return (is_legal ? tagged Valid instr : tagged Invalid);
   end
endfunction

// ================================================================

endpackage
