// vim: tw=80:tabstop=8:softtabstop=3:shiftwidth=3:expandtab:
// Copyright (c) 2016-2018 Bluespec, Inc. All Rights Reserved

package RISCV_FBox;

// ================================================================
// This package executes the 'F, D' extension instructions

// ================================================================
// Exports

export
RISCV_FBox_IFC (..),
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
   Bit #(64)   value;            // The result rd
   Bit #(5)    flags;            // FCSR.FFLAGS update value
} FBoxResult deriving (Bits, Eq, FShow);

typedef enum {
   FBOX_READY,                   // Idle. Ready for request
   FBOX_BUSY,                    // FBox is busy processing a request
   FBOX_RESULT,                  // FBox result is ready
   FBOX_EXCEPTION_RSP            // Illegal instruction exception
} FBoxState deriving (Bits, Eq, FShow);

interface RISCV_FBox_IFC;
   method Action set_verbosity (Bit #(4) verbosity);

   method Action                    req_reset;
   method ActionValue #(Bit #(0))   rsp_reset;

   // FBox interface: request
   (* always_ready *)
   method Action req (
        Bool                        use_FPU_not_PNU
      , Opcode                      opcode
      , Bit #(7)                    f7
      , Bit #(3)                    rm
      , RegName                     rs2
      , Bit #(64)                   v1
      , Bit #(64)                   v2
      , Bit #(64)                   v3
   );

   // MBox interface: response
   (* always_ready *)
   method Bool valid;
   (* always_ready *)
   method Tuple2 #(Bit #(64), Bit #(5)) word;
   (* always_ready *)
   method Bool exc;
endinterface

// ================================================================

(* synthesize *)
module mkRISCV_FBox (RISCV_FBox_IFC);

   Reg   #(Bit #(4))       cfg_verbosity        <- mkConfigReg (0);

   Reg   #(Maybe #(Bool))  rg_frm_FPU_not_PNU   <- mkRegU;

   Reg   #(Bool)           dw_valid             <- mkDWire (False);
   Reg   #(Tuple2 #(Bit#(64), Bit$(5)) dw_result<- mkDWire (?);

   
   FPU_IFC                 fpu                  <- mkFPU;
   FPU_IFC                 pnu                  <- mkFPU;


   // =============================================================
   // ----------------------------------------------------------------
   // This rule drives an exception response until the FBox is put
   // into FBOX_BUSY state by the next request.

   // These rules drives the results from the FPU or PNU
   rule rl_drive_fpu_result (
         (rg_frm_FPU_not_PNU.Valid == True)
      && (fpu.result_valid));
      dw_valid    <= True;
      dw_result   <= fpu.result_value;
   endrule

   rule rl_drive_pnu_result (
         (rg_frm_FPU_not_PNU.Valid == False)
      && (pnu.result_valid));
      dw_valid    <= True;
      dw_result   <= pnu.result_value;
   endrule

   // =============================================================
   // INTERFACE
   method Action set_verbosity (Bit #(4) verbosity);
      cfg_verbosity <= verbosity;
   endmethod

   method Action req_reset;
      rg_frm_FPU_not_PNU <= tagged Invalid;

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
        Bool      use_FPU_not_PNU
      , Opcode    opcode
      , Bit #(7)  f7
      , Bit #(3)  rm
      , Bit #(5)  rs2
      , Bit #(64) v1
      , Bit #(64) v2
      , Bit #(64) v3
   );
      // Legal instruction
      if (use_FPU_not_PNU)
         fpu.req (opcode, f7, rs2, rm, v1, v2, v3);
      else
         pnu.req (opcode, f7, rs2, rm, v1, v2, v3);

      // Bookkeeping
      // Is the result coming from the FPU or PNU
      rg_frm_FPU_not_PNU <= tagged Valid use_FPU_not_PNU;
   endmethod

   // MBox interface: response
   method Bool valid;
      return dw_valid;
   endmethod

   method Tuple2#(Bit#(64), Bit#(5)) word;
      return dw_result;
   endmethod

   method Bool exc;
      return dw_exc;
   endmethod
endmodule

// ================================================================

endpackage
