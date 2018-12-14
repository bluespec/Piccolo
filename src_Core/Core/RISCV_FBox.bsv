// vim: tw=80:tabstop=8:softtabstop=3:shiftwidth=3:expandtab:
// Copyright (c) 2016-2018 Bluespec, Inc. All Rights Reserved

package RISCV_FBox;

// ================================================================
// This package executes the 'F, D' extension instructions

// ================================================================
// Exports

export
RISCV_FBox_IFC (..),
FBoxResult (..),
mkRISCV_FBox;

// ================================================================
// BSV Library imports

import FIFO      :: *;
import Assert    :: *;
import ConfigReg :: *;
import FShow     :: *;

// ----------------
// BSV additional libs

import Cur_Cycle  :: *;
import GetPut_Aux :: *;

// ================================================================
// Project imports

import ISA_Decls :: *;
import FPU       :: *;

// ================================================================
// FBox interface

typedef struct {
   WordXL   word;                // The result rd
   Bit #(5) fflags;              // FCSR.FFLAGS update value
   Bool     to_GPR_not_FPR;      // rd is in GPR or FPR
} FBoxResult deriving (Bits, Eq, FShow);

interface RISCV_FBox_IFC;
   method Action set_verbosity (Bit #(4) verbosity);

   method Action                    req_reset;
   method ActionValue #(Bit #(0))   rsp_reset;

   // FBox interface: request
   (* always_ready *)
   method Action                    req (
        Bool      use_FPU_not_PNU
      , Bit #(7)  f7
      , Bit #(3)  f3
      , Bit #(2)  f2
      , Bit #(3)  rm
      , Bit #(5)  rs2
      , WordXL    fv1
      , WordXL    fv2
      , WordXL    fv3
      , WordXL    gv1
   );

   // MBox interface: response
   (* always_ready *)
   method Bool                      valid;
   (* always_ready *)
   method FBoxResult                word;
endinterface

// ================================================================

(* synthesize *)
module mkRISCV_FBox (RISCV_FBox_IFC);

   Reg   #(Bit #(4))       cfg_verbosity        <- mkConfigReg (0);

   Reg   #(Maybe #(Bool))  rg_frm_FPU_not_PNU   <- mkRegU;
   Reg   #(Maybe #(Bool))  rg_to_GPR_not_FPR    <- mkRegU;

   Reg   #(Bit #(3))       rg_f3                <- mkRegU;
   Reg   #(WordXL)         rg_v1                <- mkRegU;
   Reg   #(WordXL)         rg_v2                <- mkRegU;

   Reg   #(Bool)           dw_valid             <- mkDWire (False);
   Reg   #(FBoxResult)     dw_result            <- mkDWire (?);

   
   FPU_IFC                 fpu                  <- mkFPU;
   FPU_IFC                 pnu                  <- mkFPU;


   // =============================================================

   // =============================================================

   // INTERFACE
   method Action set_verbosity (Bit #(4) verbosity);
      cfg_verbosity <= verbosity;
   endmethod

   method Action req_reset;
      rg_frm_FPU_not_PNU <= tagged Invalid;
      rg_to_GPR_not_FPR <= tagged Invalid;

      fpu.req_reset;
      pnu.req_reset;
   endmethod

   method ActionValue #(Bit #(0)) rsp_reset;
      let frst <- fpu.rsp_reset;
      let prst <- pnu.rsp_reset;
      return (?);
   endmethod

   // FBox interface: request
   method Action req (
        Bool use_FPU_not_PNU
      , Bit #(7) f7
      , Bit #(3) f3
      , Bit #(2) f2
      , Bit #(3) rm
      , Bit #(5) rs2
      , WordXL fv1
      , WordXL fv2
      , WordXL fv3
      , WordXL gv1
   );

      // Is the result coming from the FPU or PNU
      rg_frm_FPU_not_PNU <= tagged Valid use_FPU_not_PNU;

      if (use_FPU_not_PNU)
         fpu.req (f7, f3, f2, rm, fv1, fv2, fv3, gv1);
      else
         pnu.req (f7, f3, f2, rm, fv1, fv2, fv3, gv1);

      // Should the result be written into the GPR or FPR
      rg_to_GPR_not_FPR <= tagged Valid (fv_is_rd_in_GPR (f7, rs2));

   endmethod

   // MBox interface: response
   method Bool  valid;
      return dw_valid;
   endmethod

   method FBoxResult  word;
      return dw_result;
   endmethod
endmodule

// ================================================================
// fv_is_rd_in_GPR: Checks if the request generates a result which
// should be written into to the GPR
function Bool fv_is_rd_in_GPR (Bit #(7) funct7, Bit #(5) rs2);

    let is_FCVT_W_D  =    (funct7 == f7_FCVT_W_D)
                       && (rs2 == 0);
    let is_FCVT_WU_D =    (funct7 == f7_FCVT_WU_D)
                       && (rs2 == 1);
`ifdef RV64
    let is_FCVT_L_D  =    (funct7 == f7_FCVT_L_D)
                       && (rs2 == 2);
    let is_FCVT_LU_D =    (funct7 == f7_FCVT_LU_D)
                       && (rs2 == 3);
`endif
    let is_FCVT_W_S  =    (funct7 == f7_FCVT_W_S)
                       && (rs2 == 0);
    let is_FCVT_WU_S =    (funct7 == f7_FCVT_WU_S)
                       && (rs2 == 1);
`ifdef RV64
    let is_FCVT_L_S  =    (funct7 == f7_FCVT_L_S)
                       && (rs2 == 2);
    let is_FCVT_LU_S =    (funct7 == f7_FCVT_LU_S)
                       && (rs2 == 3);
`endif

    return (   is_FCVT_W_D
            || is_FCVT_WU_D
`ifdef RV64
            || is_FCVT_L_D
            || is_FCVT_LU_D
            || is_FCVT_L_S
            || is_FCVT_LU_S
`endif
            || is_FCVT_W_S
            || is_FCVT_WU_S
           );
endfunction

// ================================================================

endpackage
