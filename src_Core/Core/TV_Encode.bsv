// Copyright (c) 2013-2018 Bluespec, Inc. All Rights Reserved.

package TV_Encode;

// ================================================================
// module mkTV_Encode is a transforming FIFO
// converting Trace_Data into encoded byte vectors

// ================================================================
// BSV lib imports

import Vector       :: *;
import FIFOF        :: *;
import GetPut       :: *;
import ClientServer :: *;
import Connectable  :: *;

// ----------------
// BSV additional libs

import GetPut_Aux :: *;

// ================================================================
// Project imports

import ISA_Decls  :: *;
import TV_Info    :: *;

// ================================================================

interface TV_Encode_IFC;
   method Action reset;

   // This module receives Trace_Data structs from the CPU and Debug Module
   interface Put #(Trace_Data)  trace_data_in;

   // This module produces tuples (n,vb),
   // where 'vb' is a vector of bytes
   // with relevant bytes in locations [0]..[n-1]
   interface Get #(Tuple2 #(Bit #(32), TV_Vec_Bytes)) tv_vb_out;
endinterface

// ================================================================

(* synthesize *)
module mkTV_Encode (TV_Encode_IFC);

   Reg #(Bool) rg_reset_done <- mkReg (False);

   // Keep track of last PC for more efficient encoding of incremented PCs
   // TODO: currently always sending full PC
   Reg #(Bit #(64)) rg_last_pc <- mkReg (0);

   FIFOF #(Trace_Data)                        f_trace_data <- mkFIFOF;
   FIFOF #(Tuple2 #(Bit #(32), TV_Vec_Bytes)) f_vb         <- mkFIFOF;

   // ----------------------------------------------------------------
   // BEHAVIOR

   rule rl_log_trace_RESET (rg_reset_done && (f_trace_data.first.op == TRACE_RESET));
      let td <- pop (f_trace_data);

      // Encode the td into a Byte Vec
      Vector #(1, Byte) vb_first = replicate (te_op_begin_group);
      Vector #(1, Byte) vb1      = replicate (te_op_mem_hart_reset);
      Vector #(1, Byte) vb_last  = replicate (te_op_end_group);

      match { .nn0, .x0 } = vsubst ( ?,   0,  vb_first, 1);
      match { .nn1, .x1 } = vsubst (x0, nn0,  vb1, 1);
      match { .nn2, .x2 } = vsubst (x1, nn1,  vb_last, 1);

      let n  = nn2;
      let vb = x2;

      f_vb.enq (tuple2 (n, vb));
   endrule

   rule rl_log_trace_MIP (rg_reset_done && (f_trace_data.first.op == TRACE_MIP));
      let td <- pop (f_trace_data);

      // Encode the td into a Byte Vec
      match { .n, .vb } = encode_reg (fv_csr_regnum (csr_mip), td.word1);

      f_vb.enq (tuple2 (n, vb));
   endrule

   rule rl_log_trace_OTHER (rg_reset_done && (f_trace_data.first.op == TRACE_OTHER));
      let td <- pop (f_trace_data);

      // Encode the td into a Byte Vec
      Vector #(1, Byte) vb_first = replicate (te_op_begin_group);
      match { .n1, .vb1 } = encode_reg (fv_csr_regnum (csr_addr_dpc), td.pc);
      match { .n2, .vb2 } = encode_instr (td.instr_sz, td.instr);
      Vector #(1, Byte) vb_last = replicate (te_op_end_group);

      match { .nn0, .x0 } = vsubst ( ?,   0,  vb_first, 1);
      match { .nn1, .x1 } = vsubst (x0, nn0,  vb1, n1);
      match { .nn2, .x2 } = vsubst (x1, nn1,  vb2, n2);
      match { .nn3, .x3 } = vsubst (x2, nn2,  vb_last, 1);

      let n  = nn3;
      let vb = x3;

      f_vb.enq (tuple2 (n, vb));
   endrule

   rule rl_log_trace_I_RD (rg_reset_done && (f_trace_data.first.op == TRACE_I_RD));
      let td <- pop (f_trace_data);

      // Encode the td into a Byte Vec
      Vector #(1, Byte) vb_first = replicate (te_op_begin_group);
      match { .n1, .vb1 } = encode_reg (fv_csr_regnum (csr_addr_dpc), td.pc);
      match { .n2, .vb2 } = encode_instr (td.instr_sz, td.instr);
      match { .n3, .vb3 } = encode_reg (fv_gpr_regnum (td.rd), td.word1);
      Vector #(1, Byte) vb_last = replicate (te_op_end_group);

      match { .nn0, .x0 } = vsubst ( ?,   0,  vb_first, 1);
      match { .nn1, .x1 } = vsubst (x0, nn0,  vb1, n1);
      match { .nn2, .x2 } = vsubst (x1, nn1,  vb2, n2);
      match { .nn3, .x3 } = vsubst (x2, nn2,  vb3, n3);
      match { .nn4, .x4 } = vsubst (x3, nn3,  vb_last, 1);

      let n  = nn4;
      let vb = x4;

      f_vb.enq (tuple2 (n, vb));
   endrule

   rule rl_log_trace_F_RD (rg_reset_done && (f_trace_data.first.op == TRACE_F_RD));
      let td <- pop (f_trace_data);

      // Encode the td into a Byte Vec
      Vector #(1, Byte) vb_first = replicate (te_op_begin_group);
      match { .n1, .vb1 } = encode_reg (fv_csr_regnum (csr_addr_dpc), td.pc);
      match { .n2, .vb2 } = encode_instr (td.instr_sz, td.instr);
      match { .n3, .vb3 } = encode_reg (fv_fpr_regnum (td.rd), td.word1);
      Vector #(1, Byte) vb_last = replicate (te_op_end_group);

      match { .nn0, .x0 } = vsubst ( ?,   0,  vb_first, 1);
      match { .nn1, .x1 } = vsubst (x0, nn0,  vb1, n1);
      match { .nn2, .x2 } = vsubst (x1, nn1,  vb2, n2);
      match { .nn3, .x3 } = vsubst (x2, nn2,  vb_last, 1);

      let n  = nn3;
      let vb = x3;

      f_vb.enq (tuple2 (n, vb));
   endrule

   rule rl_log_trace_I_LOAD (rg_reset_done && (f_trace_data.first.op == TRACE_I_LOAD));
      let td <- pop (f_trace_data);

      // Encode the td into a Byte Vec
      Vector #(1, Byte) vb_first = replicate (te_op_begin_group);
      match { .n1, .vb1 } = encode_reg (fv_csr_regnum (csr_addr_dpc), td.pc);
      match { .n2, .vb2 } = encode_instr (td.instr_sz, td.instr);
      match { .n3, .vb3 } = encode_reg (fv_gpr_regnum (td.rd), td.word1);
      match { .n4, .vb4 } = encode_eaddr (td.word3);
      Vector #(1, Byte) vb_last = replicate (te_op_end_group);

      match { .nn0, .x0 } = vsubst ( ?,   0,  vb_first, 1);
      match { .nn1, .x1 } = vsubst (x0, nn0,  vb1, n1);
      match { .nn2, .x2 } = vsubst (x1, nn1,  vb2, n2);
      match { .nn3, .x3 } = vsubst (x2, nn2,  vb3, n3);
      match { .nn4, .x4 } = vsubst (x3, nn3,  vb4, n4);
      match { .nn5, .x5 } = vsubst (x4, nn4,  vb_last, 1);

      let n  = nn5;
      let vb = x5;

      f_vb.enq (tuple2 (n, vb));
   endrule

   rule rl_log_trace_F_LOAD (rg_reset_done && (f_trace_data.first.op == TRACE_F_LOAD));
      let td <- pop (f_trace_data);

      // Encode the td into a Byte Vec
      Vector #(1, Byte) vb_first = replicate (te_op_begin_group);
      match { .n1, .vb1 } = encode_reg (fv_csr_regnum (csr_addr_dpc), td.pc);
      match { .n2, .vb2 } = encode_instr (td.instr_sz, td.instr);
      match { .n3, .vb3 } = encode_reg (fv_fpr_regnum (td.rd), td.word1);
      match { .n4, .vb4 } = encode_eaddr (td.word3);
      Vector #(1, Byte) vb_last = replicate (te_op_end_group);

      match { .nn0, .x0 } = vsubst ( ?,   0,  vb_first, 1);
      match { .nn1, .x1 } = vsubst (x0, nn0,  vb1, n1);
      match { .nn2, .x2 } = vsubst (x1, nn1,  vb2, n2);
      match { .nn3, .x3 } = vsubst (x2, nn2,  vb3, n3);
      match { .nn4, .x4 } = vsubst (x3, nn3,  vb4, n4);
      match { .nn5, .x5 } = vsubst (x4, nn4,  vb_last, 1);

      let n  = nn5;
      let vb = x5;

      f_vb.enq (tuple2 (n, vb));
   endrule

   rule rl_log_trace_STORE (rg_reset_done && (f_trace_data.first.op == TRACE_STORE));
      let td <- pop (f_trace_data);

      let funct3 = instr_funct3 (td.instr);    // TODO: what if it's a 16b instr?
      let mem_req_size = funct3 [1:0];

      // Encode the td into a Byte Vec
      Vector #(1, Byte) vb_first = replicate (te_op_begin_group);
      match { .n1, .vb1 } = encode_reg (fv_csr_regnum (csr_addr_dpc), td.pc);
      match { .n2, .vb2 } = encode_instr (td.instr_sz, td.instr);
      match { .n3, .vb3 } = encode_stval (mem_req_size, td.word2);
      match { .n4, .vb4 } = encode_eaddr (td.word3);
      Vector #(1, Byte) vb_last = replicate (te_op_end_group);

      match { .nn0, .x0 } = vsubst ( ?,   0,  vb_first, 1);
      match { .nn1, .x1 } = vsubst (x0, nn0,  vb1, n1);
      match { .nn2, .x2 } = vsubst (x1, nn1,  vb2, n2);
      match { .nn3, .x3 } = vsubst (x2, nn2,  vb3, n3);
      match { .nn4, .x4 } = vsubst (x3, nn3,  vb4, n4);
      match { .nn5, .x5 } = vsubst (x4, nn4,  vb_last, 1);

      let n  = nn5;
      let vb = x5;

      f_vb.enq (tuple2 (n, vb));
   endrule

   rule rl_log_trace_AMO (rg_reset_done && (f_trace_data.first.op == TRACE_AMO));
      let td <- pop (f_trace_data);

      let funct3 = instr_funct3 (td.instr);    // TODO: what if it's a 16b instr?
      let mem_req_size = funct3 [1:0];

      // Encode the td into a Byte Vec
      Vector #(1, Byte) vb_first = replicate (te_op_begin_group);
      match { .n1, .vb1 } = encode_reg (fv_csr_regnum (csr_addr_dpc), td.pc);
      match { .n2, .vb2 } = encode_instr (td.instr_sz, td.instr);
      match { .n3, .vb3 } = encode_reg (fv_gpr_regnum (td.rd), td.word1);
      match { .n4, .vb4 } = encode_stval (mem_req_size, td.word2);
      match { .n5, .vb5 } = encode_eaddr (td.word3);
      Vector #(1, Byte) vb_last = replicate (te_op_end_group);

      match { .nn0, .x0 } = vsubst ( ?,   0,  vb_first, 1);
      match { .nn1, .x1 } = vsubst (x0, nn0,  vb1, n1);
      match { .nn2, .x2 } = vsubst (x1, nn1,  vb2, n2);
      match { .nn3, .x3 } = vsubst (x2, nn2,  vb3, n3);
      match { .nn4, .x4 } = vsubst (x3, nn3,  vb4, n4);
      match { .nn5, .x5 } = vsubst (x4, nn4,  vb5, n5);
      match { .nn6, .x6 } = vsubst (x5, nn5,  vb_last, 1);

      let n  = nn6;
      let vb = x6;

      f_vb.enq (tuple2 (n, vb));
   endrule

   rule rl_log_trace_CSRRX (rg_reset_done && (f_trace_data.first.op == TRACE_CSRRX));
      let td <- pop (f_trace_data);

      // Encode the td into a Byte Vec
      Vector #(1, Byte) vb_first = replicate (te_op_begin_group);
      match { .n1, .vb1 } = encode_reg (fv_csr_regnum (csr_addr_dpc), td.pc);
      match { .n2, .vb2 } = encode_instr (td.instr_sz, td.instr);
      match { .n3, .vb3 } = encode_reg (fv_gpr_regnum (td.rd), td.word1);
      match { .n4, .vb4 } = ((td.word2 == 0)
			     ? tuple2 (0, ?)    // CSR was not written
			     : encode_reg (fv_csr_regnum (truncate (td.word3)), td.word4));
      Vector #(1, Byte) vb_last = replicate (te_op_end_group);

      match { .nn0, .x0 } = vsubst ( ?,   0,  vb_first, 1);
      match { .nn1, .x1 } = vsubst (x0, nn0,  vb1, n1);
      match { .nn2, .x2 } = vsubst (x1, nn1,  vb2, n2);
      match { .nn3, .x3 } = vsubst (x2, nn2,  vb3, n3);
      match { .nn4, .x4 } = vsubst (x3, nn3,  vb4, n4);
      match { .nn5, .x5 } = vsubst (x4, nn4,  vb_last, 1);

      let n  = nn5;
      let vb = x5;

      f_vb.enq (tuple2 (n, vb));
   endrule

   rule rl_log_trace_TRAP (rg_reset_done && (f_trace_data.first.op == TRACE_TRAP));
      let td <- pop (f_trace_data);

      // Encode the td into a Byte Vec
      Vector #(1, Byte) vb_first = replicate (te_op_begin_group);
      match { .n1, .vb1 } = encode_reg (fv_csr_regnum (csr_addr_dpc), td.pc);
      match { .n2, .vb2 } = encode_instr (td.instr_sz, td.instr);
      match { .n3, .vb3 } = encode_priv (td.rd);
      match { .n4, .vb4 } = encode_reg (fv_csr_regnum (csr_addr_mstatus), td.word1);
      match { .n5, .vb5 } = encode_reg (fv_csr_regnum (csr_mcause),  td.word2);
      match { .n6, .vb6 } = encode_reg (fv_csr_regnum (csr_mepc),    td.word3);
      match { .n7, .vb7 } = encode_reg (fv_csr_regnum (csr_mtval),   td.word4);
      Vector #(1, Byte) vb_last = replicate (te_op_end_group);

      match { .nn0, .x0 } = vsubst ( ?,   0,  vb_first, 1);
      match { .nn1, .x1 } = vsubst (x0, nn0,  vb1, n1);
      match { .nn2, .x2 } = vsubst (x1, nn1,  vb2, n2);
      match { .nn3, .x3 } = vsubst (x2, nn2,  vb3, n3);
      match { .nn4, .x4 } = vsubst (x3, nn3,  vb4, n4);
      match { .nn5, .x5 } = vsubst (x4, nn4,  vb5, n5);
      match { .nn6, .x6 } = vsubst (x5, nn5,  vb6, n6);
      match { .nn7, .x7 } = vsubst (x6, nn6,  vb7, n7);
      match { .nn8, .x8 } = vsubst (x7, nn7,  vb_last, 1);

      let n  = nn8;
      let vb = x8;
      
      f_vb.enq (tuple2 (n, vb));
   endrule

   rule rl_log_trace_INTR (rg_reset_done && (f_trace_data.first.op == TRACE_INTR));
      let td <- pop (f_trace_data);

      // Encode the td into a Byte Vec
      Vector #(1, Byte) vb_first = replicate (te_op_begin_group);
      match { .n1, .vb1 } = encode_reg (fv_csr_regnum (csr_addr_dpc), td.pc);
      match { .n2, .vb2 } = encode_priv (td.rd);
      match { .n3, .vb3 } = encode_reg (fv_csr_regnum (csr_addr_mstatus), td.word1);
      match { .n4, .vb4 } = encode_reg (fv_csr_regnum (csr_mcause),  td.word2);
      match { .n5, .vb5 } = encode_reg (fv_csr_regnum (csr_mepc),    td.word3);
      match { .n6, .vb6 } = encode_reg (fv_csr_regnum (csr_mtval),   td.word4);
      Vector #(1, Byte) vb_last = replicate (te_op_end_group);

      match { .nn0, .x0 } = vsubst ( ?,   0,  vb_first, 1);
      match { .nn1, .x1 } = vsubst (x0, nn0,  vb1, n1);
      match { .nn2, .x2 } = vsubst (x1, nn1,  vb2, n2);
      match { .nn3, .x3 } = vsubst (x2, nn2,  vb3, n3);
      match { .nn4, .x4 } = vsubst (x3, nn3,  vb4, n4);
      match { .nn5, .x5 } = vsubst (x4, nn4,  vb5, n5);
      match { .nn6, .x6 } = vsubst (x5, nn5,  vb6, n6);
      match { .nn7, .x7 } = vsubst (x6, nn6,  vb_last, 1);

      let n  = nn7;
      let vb = x7;
      
      f_vb.enq (tuple2 (n, vb));
   endrule

   rule rl_log_trace_RET (rg_reset_done && (f_trace_data.first.op == TRACE_RET));
      let td <- pop (f_trace_data);

      // Encode the td into a Byte Vec
      Vector #(1, Byte) vb_first = replicate (te_op_begin_group);
      match { .n1, .vb1 } = encode_reg (fv_csr_regnum (csr_addr_dpc), td.pc);
      match { .n2, .vb2 } = encode_instr (td.instr_sz, td.instr);
      match { .n3, .vb3 } = encode_priv (td.rd);
      match { .n4, .vb4 } = encode_reg (fv_csr_regnum (csr_addr_mstatus), td.word1);
      Vector #(1, Byte) vb_last = replicate (te_op_end_group);

      match { .nn0, .x0 } = vsubst ( ?,   0,  vb_first, 1);
      match { .nn1, .x1 } = vsubst (x0, nn0,  vb1, n1);
      match { .nn2, .x2 } = vsubst (x1, nn1,  vb2, n2);
      match { .nn3, .x3 } = vsubst (x2, nn2,  vb3, n3);
      match { .nn4, .x4 } = vsubst (x3, nn3,  vb4, n4);
      match { .nn5, .x5 } = vsubst (x4, nn4,  vb_last, 1);

      let n  = nn5;
      let vb = x5;
      
      f_vb.enq (tuple2 (n, vb));
   endrule

   // ----------------------------------------------------------------
   // INTERFACE

   method Action reset () if (! rg_reset_done);
      f_trace_data.clear;
      f_vb.clear;
      rg_reset_done <= True;
   endmethod

   interface Put trace_data_in = toPut (f_trace_data);
   interface Get tv_vb_out     = toGet (f_vb);
endmodule

// ****************************************************************
// ****************************************************************
// ****************************************************************
// Encoding Trace_Data into Byte vectors

// ================================================================
// Encodings
// cf. "Trace Protocol Specification Version 2018-09-12, Darius Rad, Bluespec, Inc."

Bit #(8) te_op_begin_group     = 1;
Bit #(8) te_op_end_group       = 2;
Bit #(8) te_op_incr_pc         = 3;
Bit #(8) te_op_full_reg        = 4;
Bit #(8) te_op_incr_reg        = 5;
Bit #(8) te_op_incr_reg_OR     = 6;
Bit #(8) te_op_microarch_state = 7;
Bit #(8) te_op_mem_req         = 8;
Bit #(8) te_op_mem_rsp         = 9;
Bit #(8) te_op_mem_hart_reset  = 10;
Bit #(8) te_op_mem_state_init  = 11;
Bit #(8) te_op_16b_instr       = 16;
Bit #(8) te_op_32b_instr       = 17;

Bit #(4) te_mem_req_size_8     = 0;
Bit #(4) te_mem_req_size_16    = 1;
Bit #(4) te_mem_req_size_32    = 2;
Bit #(4) te_mem_req_size_64    = 3;

Bit #(4) te_mem_req_op_Load       = 0;
Bit #(4) te_mem_req_op_Store      = 1;
Bit #(4) te_mem_req_op_LR         = 2;
Bit #(4) te_mem_req_op_SC         = 3;
Bit #(4) te_mem_req_op_AMO_swap   = 4;
Bit #(4) te_mem_req_op_AMO_add    = 5;
Bit #(4) te_mem_req_op_AMO_xor    = 6;
Bit #(4) te_mem_req_op_AMO_and    = 7;
Bit #(4) te_mem_req_op_AMO_or     = 8;
Bit #(4) te_mem_req_op_AMO_min    = 9;
Bit #(4) te_mem_req_op_AMO_max    = 10;
Bit #(4) te_mem_req_op_AMO_minu   = 11;
Bit #(4) te_mem_req_op_AMO_maxu   = 12;
Bit #(4) te_mem_req_op_AMO_ifetch = 13;

Bit #(4) te_mem_result_success    = 0;
Bit #(4) te_mem_result_failure    = 1;

Bit #(8) te_op_microarch_state_priv     = 1;
Bit #(8) te_op_microarch_state_paddr    = 2;
Bit #(8) te_op_microarch_state_eaddr    = 3;
Bit #(8) te_op_microarch_state_data8    = 4;
Bit #(8) te_op_microarch_state_data16   = 5;
Bit #(8) te_op_microarch_state_data32   = 6;
Bit #(8) te_op_microarch_state_data64   = 7;
Bit #(8) te_op_microarch_state_mtime    = 8;
Bit #(8) te_op_microarch_state_pc_paddr = 9;

// ================================================================
// Architectural register address encodings
// cf. "RISC-V External Debug Support"
//      2018-10-02_riscv_debug_spec_v0.13_DRAFT_f2873e71
//     "Table 3.3 Abstract Register Numbers"
// Note: the PC is numbered at fv_csr_regnum (csr_addr_dpc)

function Bit #(16) fv_csr_regnum (CSR_Addr  csr_addr);
   return zeroExtend (csr_addr);
endfunction

function Bit #(16) fv_gpr_regnum (RegName  gpr_addr);
   return 'h1000 + zeroExtend (gpr_addr);
endfunction

function Bit #(16) fv_fpr_regnum (RegName  fpr_addr);
   return 'h1020 + zeroExtend (fpr_addr);
endfunction

// ================================================================
// vsubst substitutes vb1[j1:j1+j2-1] with vb2[0:j2-1]

function Tuple2 #(Bit #(32),
		  Vector #(TV_VB_SIZE, Byte))
   vsubst (Vector #(TV_VB_SIZE, Byte) vb1, Bit #(32) j1,
	   Vector #(m, Byte)     vb2, Bit #(32) j2);

   function Byte f (Integer j);
      Byte      x  = vb1 [j];
      Bit #(32) jj = fromInteger (j);
      if ((j1 <= jj) && (jj < j1 + j2))
	 x = vb2 [jj - j1];
      return x;
   endfunction

   return tuple2 (j1 + j2, genWith (f));
endfunction

// ================================================================
// Encoding of Trace_Data into byte vectors

function Tuple2 #(Bit #(32), Vector #(TV_VB_SIZE, Byte)) encode_instr (ISize isize, Bit #(32) instr);

   Vector #(TV_VB_SIZE, Byte) vb = newVector;
   Bit #(32)           n  = ((isize == ISIZE16BIT) ? 3 : 5);
   vb [0] = ((isize == ISIZE16BIT) ? te_op_16b_instr : te_op_32b_instr);
   vb [1] = instr [7:0];
   vb [2] = instr [15:8];
   vb [3] = instr [23:16];
   vb [4] = instr [31:24];
   return tuple2 (n, vb);
endfunction

function Tuple2 #(Bit #(32), Vector #(TV_VB_SIZE, Byte)) encode_reg (Bit #(16) regnum, WordXL word);
   Vector #(TV_VB_SIZE, Byte) vb = newVector;
   Bit #(32) n = 0;
   vb [0] = te_op_full_reg;
   vb [1] = regnum [7:0];
   vb [2] = regnum [15:8];
   vb [3] = word[7:0];
   vb [4] = word [15:8];
   vb [5] = word [23:16];
   vb [6] = word [31:24];
   n = 7;
`ifdef RV64
   vb [7] = word [39:32];
   vb [8] = word [47:40];
   vb [9] = word [55:48];
   vb [10] = word [63:56];
   n = 11;
`endif
   if (regnum == fv_gpr_regnum (0)) n = 0;
   return tuple2 (n, vb);
endfunction

function Tuple2 #(Bit #(32), Vector #(TV_VB_SIZE, Byte)) encode_priv (Bit #(5) priv);
   Vector #(TV_VB_SIZE, Byte) vb = newVector;
   vb [0] = te_op_microarch_state;
   vb [1] = te_op_microarch_state_priv;
   vb [2] = zeroExtend (priv);
   return tuple2 (3, vb);
endfunction

function Tuple2 #(Bit #(32), Vector #(TV_VB_SIZE, Byte)) encode_eaddr (WordXL word);
   Vector #(TV_VB_SIZE, Byte) vb = newVector;
   Bit #(32)            n;
   vb [0] = te_op_microarch_state;
   vb [1] = te_op_microarch_state_eaddr;
   vb [2] = word[7:0];
   vb [3] = word [15:8];
   vb [4] = word [23:16];
   vb [5] = word [31:24];
   n = 6;
`ifdef RV64
   vb [6] = word [39:32];
   vb [7] = word [47:40];
   vb [8] = word [55:48];
   vb [9] = word [63:56];
   n = 10;
`endif
   return tuple2 (n, vb);
endfunction

function Tuple2 #(Bit #(32), Vector #(TV_VB_SIZE, Byte)) encode_stval (MemReqSize mem_req_size, WordXL word);
   Vector #(TV_VB_SIZE, Byte) vb = newVector;
   Bit #(32)            n;
   vb [0] = te_op_microarch_state;
   vb [1] = case (mem_req_size)
	       f3_SIZE_B: te_op_microarch_state_data8;
	       f3_SIZE_H: te_op_microarch_state_data16;
	       f3_SIZE_W: te_op_microarch_state_data32;
	       f3_SIZE_D: te_op_microarch_state_data64;
	    endcase;
   vb [2] = word[7:0];
   vb [3] = word [15:8];
   vb [4] = word [23:16];
   vb [5] = word [31:24];
`ifdef RV64
   vb [6] = word [39:32];
   vb [7] = word [47:40];
   vb [8] = word [55:48];
   vb [9] = word [63:56];
`endif
   n = case (mem_req_size)
	  f3_SIZE_B: 2 + 1;
	  f3_SIZE_H: 2 + 2;
	  f3_SIZE_W: 2 + 4;
	  f3_SIZE_D: 2 + 8;
       endcase;
   return tuple2 (n, vb);
endfunction

// ================================================================

endpackage
