// Copyright (c) 2019 Bluespec, Inc. All Rights Reserved

package PMPU;

// ================================================================
// This defines a module for a PMPU (Physical Memory Protection Unit)
// Reference:
//      "The RISC-V Instruction Set Manual"
//      Volume II: Privileged Architecture, Version 1.11-draft, October 1, 2018
//      Section 3.6.1

// Use this only when actually implementing PMPs
//      INCLUDE_PMPS macro is set and num_pmps is in [1..16]
// If not implementing PMPs, use PMPU_Null.bsv

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
// Select the msbs ([XLEN-1 : G]) of an address (G may be 0)

function WordXL fn_pmpaddr_msbs (WordXL addr);
   Bit #(TAdd #(XLEN, 1)) all_ones = '1;
   Bit #(TAdd #(XLEN, 1)) mask     = (all_ones << pmp_G);
   return (addr & (~ truncate (mask)));
endfunction

// ================================================================
// Other constants.

Bit #(2) pmpcfg_A_OFF   = 0;
Bit #(2) pmpcfg_A_TOR   = 1;
Bit #(2) pmpcfg_A_NA4   = 2;
Bit #(2) pmpcfg_A_NAPOT = 3;

Integer pmpcfg_L_bitpos = 7;
Integer pmpcfg_A_bitpos = 3;
Integer pmpcfg_X_bitpos = 2;
Integer pmpcfg_W_bitpos = 1;
Integer pmpcfg_R_bitpos = 0;

function Bit #(1) fn_pmpcfg_L (Bit #(8) cfg);
   return cfg [pmpcfg_L_bitpos];
endfunction

function Bit #(2) fn_pmpcfg_A (Bit #(8) cfg);
   return cfg [pmpcfg_A_bitpos + 1: pmpcfg_A_bitpos];
endfunction

function Bit #(1) fn_pmpcfg_R (Bit #(8) cfg);
   return cfg [pmpcfg_R_bitpos];
endfunction

function Bit #(1) fn_pmpcfg_W (Bit #(8) cfg);
   return cfg [pmpcfg_W_bitpos];
endfunction

function Bit #(1) fn_pmpcfg_X (Bit #(8) cfg);
   return cfg [pmpcfg_X_bitpos];
endfunction

// ================================================================
// MODULE

typedef enum {PMP_MATCH_NO,                // NA = not applicable
	      PMP_MATCH_SUCCEED,
	      PMP_MATCH_FAIL
   } PMP_Match
deriving (Eq, Bits, FShow);

(* synthesize *)
module mkPMPU (PMPU_IFC);

   // ----------------
   // Reset requests and responses
   FIFOF #(Token) f_reset_reqs <- mkFIFOF;
   FIFOF #(Token) f_reset_rsps <- mkFIFOF;

   // ----------------
   // We keep pmpcfg regs in separate registers, combining them into
   // their CSR packed form as needed during CSR reads and writes.

   messageM ("INFO: PMPU.bsv: compiling with PMPs");
   Vector #(Num_PMP_Regions, Reg #(Bit #(8))) vrg_pmpcfg  <- replicateM (mkReg (0));

   Vector #(Num_PMP_Regions, Reg #(WordXL))   vrg_pmpaddr <- replicateM (mkRegU);

   // ----------------------------------------------------------------

   function Bool fn_permitted (WordXL      phys_addr_lo,
			       MemReqSize  req_size,
			       Priv_Mode   priv,
			       Access_RWX  rwx);

      Bit #(4) req_size_bytes = ((req_size == f3_SIZE_B) ? 1
				 : ((req_size == f3_SIZE_H) ? 2
				    : ((req_size == f3_SIZE_W) ? 4
				       : 8)));

      WordXL phys_addr_hi        = phys_addr_lo + zeroExtend (req_size_bytes) - 1;
      WordXL phys_addr_lo_msbs = fn_pmpaddr_msbs (phys_addr_lo);
      WordXL phys_addr_hi_msbs = fn_pmpaddr_msbs (phys_addr_lo);

      function PMP_Match fn_addr_match (Integer j);
	 let  cfg_j        = vrg_pmpcfg [j];
	 let  cfg_j_locked = (fn_pmpcfg_L (cfg_j) == 1'b1);
	 let  cfg_j_A      = fn_pmpcfg_A (cfg_j);
	 let  cfg_j_R      = fn_pmpcfg_R (cfg_j);
	 let  cfg_j_W      = fn_pmpcfg_W (cfg_j);
	 let  cfg_j_X      = fn_pmpcfg_X (cfg_j);

	 let  region_hi_msbs = fn_pmpaddr_msbs (vrg_pmpaddr [j]);
         let  region_lo_msbs = ((cfg_j_A == pmpcfg_A_OFF) ? 0
				: (  (cfg_j_A == pmpcfg_A_TOR)
				   ? ((j == 0) ? 0 : fn_pmpaddr_msbs (vrg_pmpaddr [j-1]))
				   : region_hi_msbs));


	 // Do any bytes of the access lie in the pmp region?
	 Bool addr_overlap  = ((phys_addr_lo_msbs == region_hi_msbs) || (phys_addr_hi_msbs == region_hi_msbs));

	 // Do all bytes of the access lie in the pmp region?
	 Bool addr_in_range = ((phys_addr_lo_msbs == region_hi_msbs) && (phys_addr_hi_msbs == region_hi_msbs));

	 PMP_Match pmp_match = PMP_MATCH_NO;
	 if (cfg_j_A != pmpcfg_A_OFF) begin
	    if (addr_overlap) begin
	       pmp_match = PMP_MATCH_FAIL;
	       if (   (addr_in_range)
		   && (   ((! cfg_j_locked) && (priv == m_Priv_Mode))
		       || (   (cfg_j_locked || (priv == s_Priv_Mode) || (priv == u_Priv_Mode))
			   && (   ((cfg_j_R == 1'b1) && (rwx == Access_RWX_R))
			       || ((cfg_j_W == 1'b1) && (rwx == Access_RWX_W))
			       || ((cfg_j_X == 1'b1) && (rwx == Access_RWX_X))))))
		  pmp_match = PMP_MATCH_SUCCEED;
	    end
	 end
	 return pmp_match;
      endfunction

      // Check all PMP regions in parallel
      Vector #(Num_PMP_Regions, PMP_Match) v_matches = genWith  (fn_addr_match);

      // Scan match results sequentially for first match-succeed or match-fail, if any.
      PMP_Match pmp_match = PMP_MATCH_NO;
      for (Integer j = 0; j < num_pmp_regions; j = j + 1)
	 if ((pmp_match == PMP_MATCH_NO) && (v_matches [j] != PMP_MATCH_NO))
	    pmp_match = v_matches [j];

      Bool permitted = False;
      if (priv == m_Priv_Mode)
	 permitted = ((pmp_match == PMP_MATCH_NO) || (pmp_match == PMP_MATCH_SUCCEED));
      else begin
	 // S or U privilege
	 if (pmp_match == PMP_MATCH_NO)
	    permitted = (num_pmp_regions == 0);
	 else
	    permitted = (pmp_match == PMP_MATCH_SUCCEED);
      end
   
      return permitted;
   endfunction

   rule rl_reset;
      let tok <- pop (f_reset_reqs);
      writeVReg (vrg_pmpcfg, replicate (0));
      f_reset_rsps.enq (tok);
      $display ("%0d: %m: PMPU has %0d regions with granularity G=%0d", cur_cycle, num_pmp_regions, pmp_G);
   endrule

   // ----------------------------------------------------------------
   // INTERFACE

   // Reset request/response
   interface server_reset = toGPServer (f_reset_reqs, f_reset_rsps);

   method Bit #(5) m_num_pmp_regions;    // 0..16
      return fromInteger (num_pmp_regions);
   endmethod

   method ActionValue #(Bool) permitted (WordXL      phys_addr,
					 MemReqSize  req_size,
					 Priv_Mode   priv,
					 Access_RWX  rwx);
      return fn_permitted (phys_addr, req_size, priv, rwx);
   endmethod

   interface PMPU_CSR_IFC  pmp_csrs;

      // ----------------
      method WordXL pmpcfg_read   (Bit #(2) j);    // j = 0..3
	 WordXL result = 0;

`ifdef RV32
         Bit #(4) k_init   = { j, 2'b0 };    // k_init = 0, 4, 8, 12
	 for (Integer k = 0; k < 4; k = k + 1) begin
	    Bit #(4) kk = k_init + fromInteger (k);
	    Bit #(8) cfg_kk = ((kk <= fromInteger (num_pmp_regions-1)) ? vrg_pmpcfg [kk] : 0);
	    result = { cfg_kk, result [31:8] };
	 end
`endif

`ifdef RV64
	 Bit #(5) k_init   = { j, 3'b0 };    // k_init = 0, 8, 16, 24
	 for (Integer k = 0; k < 8; k = k + 1) begin
	    Bit #(5) kk = k_init + fromInteger (k);
	    Bit #(8) cfg_kk = ((kk <= fromInteger (num_pmp_regions-1)) ? vrg_pmpcfg [kk] : 0);
	    result = { cfg_kk, result [63:8] };
	 end
`endif

	 return result;
      endmethod

      // ----------------
      method ActionValue #(WordXL) pmpcfg_write  (Bit #(2) j, WordXL x);    // j = 0..3
	 WordXL result = x;

`ifdef RV32
	 if (xlen == 32) begin
	    Bit #(4) k_init = { j, 2'b0 };    // k_init = 0, 4, 8, 12
	    for (Integer k = 0; k < 4; k = k + 1) begin
	       Bit #(4) kk = k_init + fromInteger (k);
	       if (kk <= fromInteger (num_pmp_regions - 1))
		  if (fn_pmpcfg_L (vrg_pmpcfg [kk]) == 1'b0)    // is not locked
		     vrg_pmpcfg [kk] <= x [7:0];
	       x = { 8'b0, x [31:8] };
	    end
	 end
`endif

`ifdef RV64
	 if (xlen == 64) begin
	    Bit #(5) k_init = { j, 3'b0 };    // k_init = 0, 8, 16, 24
	    for (Integer k = 0; k < 8; k = k + 1) begin
	       Bit #(5) kk = k_init + fromInteger (k);
	       if (kk <= fromInteger (num_pmp_regions - 1))
		  if (fn_pmpcfg_L (vrg_pmpcfg [kk]) == 1'b0)    // is not locked
		     vrg_pmpcfg [kk] <= x [7:0];
	       x = { 8'b0, x [63:8] };
	    end
	 end
`endif

	 return x;
      endmethod

      // ----------------
      method WordXL pmpaddr_read  (Bit #(4) j);    // j = 0..15
	 WordXL result = 0;
	 result = ((j <= fromInteger (num_pmp_regions - 1)) ? vrg_pmpaddr [j] : 0);
	 return result;
      endmethod

      // ----------------
      method ActionValue #(WordXL) pmpaddr_write (Bit #(4) j, WordXL addr);    // j = 0..15
	 WordXL result = addr;
	 if (j <= (fromInteger (num_pmp_regions - 1))) begin
	    Bool locked = (fn_pmpcfg_L (vrg_pmpcfg [j]) == 1'b1);

	    Bool is_TOR_base = (   (j < fromInteger (num_pmp_regions - 1))
				&& (fn_pmpcfg_A (vrg_pmpcfg [j+1]) == pmpcfg_A_TOR));

	    if ((! locked) && (! is_TOR_base)) begin
	       vrg_pmpaddr [j] <= addr;
	    end
	 end
	 return addr;
      endmethod
   endinterface

endmodule

// ================================================================

endpackage
