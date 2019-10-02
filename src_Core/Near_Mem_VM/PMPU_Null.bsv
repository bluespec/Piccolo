// Copyright (c) 2019 Bluespec, Inc. All Rights Reserved

package PMPU_Null;

// ================================================================
// This defines a module for a 'null' PMPU (Physical Memory Protection Unit)
// which contains no PMPs and does no PMP checks.
// Reference:
//      "The RISC-V Instruction Set Manual"
//      Volume II: Privileged Architecture, Version 1.11-draft, October 1, 2018
//      Section 3.6.1

// ================================================================

export mkPMPU;

// ================================================================
// BSV library imports

import Vector       :: *;
import FIFOF        :: *;
import GetPut       :: *;
import ClientServer :: *;

// BSV additional libs

import Cur_Cycle  :: *;
import GetPut_Aux :: *;

// ================================================================
// Project imports

import ISA_Decls   :: *;

import PMPU_Config :: *;
import PMPU_IFC    :: *;

// ================================================================
// MODULE

(* synthesize *)
module mkPMPU (PMPU_IFC);

   messageM ("INFO: mkPMPU is a null module (no PMPs)");

   // ----------------------------------------------------------------
   // Reset requests and responses
   FIFOF #(Token) f_reset_reqs <- mkFIFOF;
   FIFOF #(Token) f_reset_rsps <- mkFIFOF;

   rule rl_reset;
      let tok <- pop (f_reset_reqs);
      f_reset_rsps.enq (tok);
      $display ("%0d: %m: Null PMPU (no regions, no PMP checks)", cur_cycle);
   endrule

   // ----------------------------------------------------------------
   // INTERFACE

   // Reset request/response
   interface server_reset = toGPServer (f_reset_reqs, f_reset_rsps);

   method Bit #(5) m_num_pmp_regions;    // 0..16
      return 0;
   endmethod

   method ActionValue #(Bool) permitted (WordXL      phys_addr,
					 MemReqSize  req_size,
					 Priv_Mode   priv,
					 Access_RWX  rwx);
      return True;
   endmethod

   interface PMPU_CSR_IFC  pmp_csrs;

      // ----------------
      method WordXL pmpcfg_read   (Bit #(2) j);    // j = 0..3
	 return 0;
      endmethod

      // ----------------
      method ActionValue #(WordXL) pmpcfg_write  (Bit #(2) j, WordXL x);    // j = 0..3
	 return 0;
      endmethod

      // ----------------
      method WordXL pmpaddr_read  (Bit #(4) j);    // j = 0..15
	 return 0;
      endmethod

      // ----------------
      method ActionValue #(WordXL) pmpaddr_write (Bit #(4) j, WordXL addr);    // j = 0..15
	 return 0;
      endmethod
   endinterface

endmodule

// ================================================================

endpackage
