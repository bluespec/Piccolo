// vim: tw=80:tabstop=8:softtabstop=3:shiftwidth=3:expandtab:
// Copyright (c) 2013-2018 Bluespec, Inc. All Rights Reserved

package FPU;

// ================================================================
// Project Imports
import ISA_Decls :: *;

// ================================================================
// This package implements a floating point unit (FPU). Single and
// double precision computation are supported.

// ================================================================
// FPU interface

interface FPU_IFC;
   method Action                    req_reset;
   method ActionValue #(Bit #(0))   rsp_reset;

   // FPU request
   (* always_ready *)
   method Action                    req (
        Bit #(7)  f7
      , Bit #(3)  f3
      , Bit #(2)  f2
      , Bit #(3)  rm
      , WordXL    fv1
      , WordXL    fv2
      , WordXL    fv3
      , WordXL    gv1
   );

   // FPU response
   (* always_ready *)
   method Bool                      result_valid;

   (* always_ready *)
   method Tuple2 #(WordXL, Bit#(5)) result_value;
endinterface

(* synthesize *)
module mkFPU (FPU_IFC);

   Reg   # (Bit #(5))      rg_fflags         <- mkRegU;
   Reg   # (WordXL)        rg_result         <- mkRegU;
   Reg   # (Bool)          rg_result_valid   <- mkReg (False);

   // ----------------
   // INTERFACE
   method Action req_reset;
      noAction;
   endmethod

   method ActionValue #(Bit #(0)) rsp_reset;
      return (?);
   endmethod

   method Action req (
        Bit #(7)  f7
      , Bit #(3)  f3
      , Bit #(2)  f2
      , Bit #(3)  rm
      , WordXL    fv1
      , WordXL    fv2
      , WordXL    fv3
      , WordXL    gv1
   );
      noAction;
   endmethod

   method Bool result_valid;
      return (rg_result_valid);
   endmethod

   method Tuple2 #(WordXL, Bit #(5)) result_value;
      return tuple2 (rg_result, rg_fflags);
   endmethod
endmodule
endpackage
