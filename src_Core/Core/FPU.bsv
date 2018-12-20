// vim: tw=80:tabstop=8:softtabstop=3:shiftwidth=3:expandtab:
// Copyright (c) 2013-2018 Bluespec, Inc. All Rights Reserved

package FPU;

// ================================================================
// Project Imports
import ISA_Decls :: *;
import FloatingPoint :: *;

// ================================================================
// This package implements a floating point unit (FPU). Single and
// double precision computation are supported.

// ================================================================
// IEEE FP Type Definitions

typedef FloatingPoint#(11,52) FDouble;
typedef FloatingPoint#(8,23)  FSingle;
// ================================================================
// FPU interface

interface FPU_IFC;
   method Action                    req_reset;
   method ActionValue #(Bit #(0))   rsp_reset;

   // FPU request
   (* always_ready *)
   method Action req (
        Opcode    opcode
      , Bit #(7)  f7
      , RegName   rs2
      , Bit #(3)  rm
      , Bit #(64) v1
      , Bit #(64) v2
      , Bit #(64) v3
   );

   // FPU response
   (* always_ready *)
   method Bool result_valid;

   (* always_ready *)
   method Tuple2 #(Bit #(64), Bit#(5)) result_value;
endinterface

(* synthesize *)
module mkFPU (FPU_IFC);

   Reg   #(Bit #(5))       rg_fflags         <- mkRegU;
   Reg   #(Bit #(64))      rg_result         <- mkRegU;
   Reg   #(Bool)           rg_result_valid   <- mkReg (False);

   Reg   #(Maybe #(Tuple7 #(
      Opcode
      , Bit #(7)
      , RegName 
      , Bit #(3)
      , Bit #(64)
      , Bit #(64)
      , Bit #(64))))       rg_request        <- mkReg (tagged Invalid);

   // Functional Units
   Server#( Tuple4#(Maybe#(Double),Double,Double,RoundMode), FpuR ) fpu_madd   <- mkFloatingPointFusedMultiplyAccumulate;

   // ----------------
   // Behaviour
   // Decode signals (a direct lift from the spec)
   match {.opc, .f7, .rs2, .rm, .v1, .v2, .v3} = rg_request.Valid;
   Bit #(2) f2 = f7[1:0];
   let is_FMADD_D     = (opc == op_FMADD)  && (f2 == 1);
   let is_FMSUB_D     = (opc == op_FMSUB)  && (f2 == 1);
   let is_FNMADD_D    = (opc == op_FNMADD) && (f2 == 1);
   let is_FNMSUB_D    = (opc == op_FNMSUB) && (f2 == 1);
   let is_FADD_D      = (opc == op_FP) && (f7 == f7_FADD_D); 
   let is_FSUB_D      = (opc == op_FP) && (f7 == f7_FSUB_D);
   let is_FMUL_D      = (opc == op_FP) && (f7 == f7_FMUL_D);
   let is_FDIV_D      = (opc == op_FP) && (f7 == f7_FDIV_D);
   let is_FSQRT_D     = (opc == op_FP) && (f7 == f7_FSQRT_D);
   let is_FSGNJ_D     = (opc == op_FP) && (f7 == f7_FSGNJ_D) && (rm == 0);
   let is_FSGNJN_D    = (opc == op_FP) && (f7 == f7_FSGNJ_D) && (rm == 1);
   let is_FSGNJX_D    = (opc == op_FP) && (f7 == f7_FSGNJ_D) && (rm == 2);
   let is_FCVT_W_D    = (opc == op_FP) && (f7 == f7_FCVT_W_D)  && (rs2 == 0);
   let is_FCVT_WU_D   = (opc == op_FP) && (f7 == f7_FCVT_WU_D) && (rs2 == 1);
`ifdef RV64
   let is_FCVT_L_D    = (opc == op_FP) && (f7 == f7_FCVT_L_D)  && (rs2 == 2);
   let is_FCVT_LU_D   = (opc == op_FP) && (f7 == f7_FCVT_LU_D) && (rs2 == 3);
`endif
   let is_FCVT_D_W    = (opc == op_FP) && (f7 == f7_FCVT_D_W)  && (rs2 == 0);
   let is_FCVT_D_WU   = (opc == op_FP) && (f7 == f7_FCVT_D_WU) && (rs2 == 1);
`ifdef RV64
   let is_FCVT_D_L    = (opc == op_FP) && (f7 == f7_FCVT_D_L)  && (rs2 == 2);
   let is_FCVT_D_LU   = (opc == op_FP) && (f7 == f7_FCVT_D_LU) && (rs2 == 3);
`endif
   let is_FCVT_D_S    = (opc == op_FP) && (f7 == f7_FCVT_D_S)  && (rs2 == 0);
   let is_FCVT_S_D    = (opc == op_FP) && (f7 == f7_FCVT_S_D)  && (rs2 == 1);
   let is_FMIN_D      = (opc == op_FP) && (f7 == f7_FMIN_D) && (rm == 0);
   let is_FMAX_D      = (opc == op_FP) && (f7 == f7_FMAX_D) && (rm == 1);
   let is_FLE_D       = (opc == op_FP) && (f7 == f7_FCMP_D) && (rm == 0);
   let is_FLT_D       = (opc == op_FP) && (f7 == f7_FCMP_D) && (rm == 1);
   let is_FEQ_D       = (opc == op_FP) && (f7 == f7_FCMP_D) && (rm == 2);
   let is_FMV_X_D     = (opc == op_FP) && (f7 == f7_FMV_X_D);
   let is_FMV_D_X     = (opc == op_FP) && (f7 == f7_FMV_D_X);
   let is_FCLASS_D    = (opc == op_FP) && (f7 == f7_FCLASS_D);

   let is_FMADD_S     = (opc == op_FMADD)  && (f2 == 0);
   let is_FMSUB_S     = (opc == op_FMSUB)  && (f2 == 0);
   let is_FNMADD_S    = (opc == op_FNMADD) && (f2 == 0);
   let is_FNMSUB_S    = (opc == op_FNMSUB) && (f2 == 0);
   let is_FADD_S      = (opc == op_FP) && (f7 == f7_FADD_S); 
   let is_FSUB_S      = (opc == op_FP) && (f7 == f7_FSUB_S);
   let is_FMUL_S      = (opc == op_FP) && (f7 == f7_FMUL_S);
   let is_FDIV_S      = (opc == op_FP) && (f7 == f7_FDIV_S);
   let is_FSQRT_S     = (opc == op_FP) && (f7 == f7_FSQRT_S);
   let is_FSGNJ_S     = (opc == op_FP) && (f7 == f7_FSGNJ_S) && (rm == 0);
   let is_FSGNJN_S    = (opc == op_FP) && (f7 == f7_FSGNJ_S) && (rm == 1);
   let is_FSGNJX_S    = (opc == op_FP) && (f7 == f7_FSGNJ_S) && (rm == 2);
   let is_FCVT_W_S    = (opc == op_FP) && (f7 == f7_FCVT_W_S)  && (rs2 == 0);
   let is_FCVT_WU_S   = (opc == op_FP) && (f7 == f7_FCVT_WU_S) && (rs2 == 1);
`ifdef RV64
   let is_FCVT_L_S    = (opc == op_FP) && (f7 == f7_FCVT_L_S)  && (rs2 == 2);
   let is_FCVT_LU_S   = (opc == op_FP) && (f7 == f7_FCVT_LU_S) && (rs2 == 3);
`endif
   let is_FCVT_S_W    = (opc == op_FP) && (f7 == f7_FCVT_S_W)  && (rs2 == 0);
   let is_FCVT_S_WU   = (opc == op_FP) && (f7 == f7_FCVT_S_WU) && (rs2 == 1);
`ifdef RV64
   let is_FCVT_S_L    = (opc == op_FP) && (f7 == f7_FCVT_S_L)  && (rs2 == 2);
   let is_FCVT_S_LU   = (opc == op_FP) && (f7 == f7_FCVT_S_LU) && (rs2 == 3);
`endif
   let is_FMIN_S      = (opc == op_FP) && (f7 == f7_FMIN_S) && (rm == 0);
   let is_FMAX_S      = (opc == op_FP) && (f7 == f7_FMAX_S) && (rm == 1);
   let is_FLE_S       = (opc == op_FP) && (f7 == f7_FCMP_S) && (rm == 0);
   let is_FLT_S       = (opc == op_FP) && (f7 == f7_FCMP_S) && (rm == 1);
   let is_FEQ_S       = (opc == op_FP) && (f7 == f7_FCMP_S) && (rm == 2);
   let is_FMV_X_W     = (opc == op_FP) && (f7 == f7_FMV_X_W);
   let is_FMV_W_X     = (opc == op_FP) && (f7 == f7_FMV_W_X);
   let is_FCLASS_S    = (opc == op_FP) && (f7 == f7_FCLASS_S);

//  rule rl_start_ADD_op_S (rg_request match tagged Valid);
//     if (is_FADD_S) 
//        FPAdd:   fpu_madd.request.put(  tuple4(Valid(opd1), opd2,         one(False), rmd) );
//        FPSub:   fpu_madd.request.put(  tuple4(Valid(opd1), negate(opd2), one(False), rmd) );
//        FPMul:   fpu_madd.request.put(  tuple4(Invalid,     opd1,         opd2,       rmd) );
//        FPMAdd:  fpu_madd.request.put(  tuple4(Valid(opd3),         opd1, opd2, rmd) );
//        FPMSub:  fpu_madd.request.put(  tuple4(Valid(negate(opd3)), opd1, opd2, rmd) );
//        FPNMAdd: fpu_madd.request.put(  tuple4(Valid(opd3),         opd1, opd2, rmd) );
//        FPNMSub: fpu_madd.request.put(  tuple4(Valid(negate(opd3)), opd1, opd2, rmd) );
//  endrule

   // ----------------
   // INTERFACE
   method Action req_reset;
      noAction;
   endmethod

   method ActionValue #(Bit #(0)) rsp_reset;
      return (?);
   endmethod

   method Action req (
        Opcode    opcode
      , Bit #(7)  f7
      , RegName   rs2
      , Bit #(3)  rm
      , Bit #(64) v1
      , Bit #(64) v2
      , Bit #(64) v3
   );
      rg_request <= tagged Valid (tuple7 (opcode, f7, rs2, rm, v1, v2, v3));
   endmethod

   method Bool result_valid;
      return (rg_result_valid);
   endmethod

   method Tuple2 #(Bit #(64), Bit #(5)) result_value;
      return tuple2 (rg_result, rg_fflags);
   endmethod
endmodule
endpackage
