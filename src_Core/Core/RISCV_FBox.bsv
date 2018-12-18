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
   Bit #(64)   value;            // The result rd
   Bit #(5)    flags;            // FCSR.FFLAGS update value
   Bool        to_GPR_not_FPR;   // rd is in GPR or FPR
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
      , Bool                        f_enabled
      , Bool                        d_enabled
      , Opcode                      opcode
      , Bit #(7)                    f7
      , Bit #(3)                    f3
      , Bit #(2)                    f2
      , Bit #(3)                    fcsr_frm
      , Bit #(5)                    rs2
      , Bit #(64)                   v1
      , Bit #(64)                   v2
      , Bit #(64)                   v3
   );

   // MBox interface: response
   (* always_ready *)
   method Bool valid;
   (* always_ready *)
   method FBoxResult word;
   (* always_ready *)
   method Bool exc;
endinterface

// ================================================================

(* synthesize *)
module mkRISCV_FBox (RISCV_FBox_IFC);

   Reg   #(Bit #(4))       cfg_verbosity        <- mkConfigReg (0);

   Reg   #(Maybe #(Bool))  rg_frm_FPU_not_PNU   <- mkRegU;
   Reg   #(Maybe #(Bool))  rg_to_GPR_not_FPR    <- mkRegU;

   Reg   #(FBoxResult)     rg_out               <- mkRegU;

   Reg   #(FBoxState)      rg_state             <- mkReg (FBOX_READY);
   Reg   #(Bool)           dw_valid             <- mkDWire (False);
   Reg   #(FBoxResult)     dw_result            <- mkDWire (?);
   Reg   #(Bool)           dw_exc               <- mkDWire (False);

   
   FPU_IFC                 fpu                  <- mkFPU;
   FPU_IFC                 pnu                  <- mkFPU;


   // =============================================================
   // ----------------------------------------------------------------
   // This rule drives an exception response until the FBox is put
   // into FBOX_BUSY state by the next request.

   rule rl_drive_exception_rsp (rg_state == FBOX_EXCEPTION_RSP);
      dw_valid    <= True;
      dw_exc      <= True;
   endrule

   // These rules drives the results from the FPU or PNU
   rule rl_drive_fpu_result (
         (rg_state == FBOX_BUSY)
      && (rg_frm_FPU_not_PNU.Valid == True)
      && (fpu.result_valid));
      match {.res, .flags} = fpu.result_value;
      let fbox_res = FBoxResult {
           value           : res
         , flags           : flags
         , to_GPR_not_FPR  : rg_to_GPR_not_FPR.Valid};

      dw_valid    <= True;
      dw_result   <= fbox_res;
   endrule

   rule rl_drive_pnu_result (
         (rg_state == FBOX_BUSY)
      && (rg_frm_FPU_not_PNU.Valid == False)
      && (pnu.result_valid));
      match {.res, .flags} = pnu.result_value;
      let fbox_res = FBoxResult {
           value           : res
         , flags           : flags
         , to_GPR_not_FPR  : rg_to_GPR_not_FPR.Valid};

      dw_valid    <= True;
      dw_result   <= fbox_res;
   endrule

   // Decode signals pertaining to legality checks

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
        Bool      use_FPU_not_PNU
      , Bool      f_enabled
      , Bool      d_enabled
      , Opcode    opcode
      , Bit #(7)  f7
      , Bit #(3)  f3
      , Bit #(2)  f2
      , Bit #(3)  fcsr_frm
      , Bit #(5)  rs2
      , Bit #(64) v1
      , Bit #(64) v2
      , Bit #(64) v3
   );

      // Is the rounding mode legal
      match {.rm, .rm_is_legal} = fv_rounding_mode_check  (f3, fcsr_frm);

      // Is the instruction legal
      let inst_is_legal = fv_is_instr_legal (f2, f_enabled, d_enabled);

      FBoxState nstate = FBOX_READY;

      // Legal instruction
      if (inst_is_legal && rm_is_legal) begin
         if (use_FPU_not_PNU)
            fpu.req (opcode, f7, rs2, rm, v1, v2, v3);
         else
            pnu.req (opcode, f7, rs2, rm, v1, v2, v3);

         // Bookkeeping
         // Should the result be written into the GPR or FPR
         rg_to_GPR_not_FPR <= tagged Valid (fv_is_rd_in_GPR (f7, rs2));

         // Is the result coming from the FPU or PNU
         rg_frm_FPU_not_PNU <= tagged Valid use_FPU_not_PNU;

         nstate = FBOX_BUSY;
      end

      // Instruction is illegal
      else 
         nstate = FBOX_EXCEPTION_RSP;

      rg_state <= nstate;
   endmethod

   // MBox interface: response
   method Bool valid;
      return dw_valid;
   endmethod

   method FBoxResult word;
      return dw_result;
   endmethod

   method Bool exc;
      return dw_exc;
   endmethod
endmodule

// ================================================================
// fv_rounding_mode_check
// Returns the correct rounding mode considering the values in the
// FCSR and the instruction and checks legality
function Tuple2# (Bit #(3), Bool) fv_rounding_mode_check (
   Bit #(3) inst_frm, Bit #(3) fcsr_frm);
   let rm = (inst_frm == 3'h7) ? fcsr_frm : inst_frm;
   let rm_is_legal  = (inst_frm == 3'h7) ? fv_fcsr_frm_valid (fcsr_frm)
                                         : fv_inst_frm_valid (inst_frm);
   return (tuple2 (rm, rm_is_legal));
endfunction


// A D instruction requires misa.f to be set as well as misa.d
function Bool fv_is_instr_legal (
   Bit #(2) f2, Bool f_enabled, Bool d_enabled);
   if (f2 == f2_S)
      return f_enabled;
   else if (f2 == f2_D)
      return (f_enabled && d_enabled);
   else
      return (False);
endfunction


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
