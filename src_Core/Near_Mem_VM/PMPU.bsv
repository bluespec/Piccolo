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
   return (addr & truncate (mask));
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

typedef enum {PMP_MATCH_NULL,                // NA = not applicable
	      PMP_MATCH_SUCCEED,
	      PMP_MATCH_FAIL
   } PMP_Match
deriving (Eq, Bits, FShow);

(* synthesize *)
module mkPMPU (PMPU_IFC);

   Integer verbosity = 1;    // For debugging only

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
   // For debugging only

   function Action fa_display_pmps ();
      action
`ifdef RV32
	 for (Integer k = 0; k < num_pmp_regions; k = k + 4) begin
	    $write ("    pmpcfg [%0d] = 0x", (k / 4));
	    for (Integer kk = 3; kk >= 0; kk = kk - 1)
	       $write ("_%02h", vrg_pmpcfg [k + kk]);
	    $display ("");
	 end
`elsif RV64
	 for (Integer k = 0; k < num_pmp_regions; k = k + 8) begin
	    $write ("    pmpcfg [%0d] = 0x", ((k/8)*2));
	    for (Integer kk = 7; kk >= 0; kk = kk - 1)
	       $write ("_%02h", vrg_pmpcfg [(k/8)*8 + kk]);
	    $display ("");
	 end
`endif

	 for (Integer k = 0; k < num_pmp_regions; k = k + 1)
	    $display ("    pmpaddr [%0d] = 0x%08h", k, vrg_pmpaddr [k]);
      endaction
   endfunction

   // ----------------------------------------------------------------

   function ActionValue #(Bool) fav_permitted (PA          phys_addr_lo,
					       MemReqSize  req_size,
					       Priv_Mode   priv,
					       Access_RWX  rwx);
      actionvalue
	 Bit #(4) req_size_bytes = ((req_size == f3_SIZE_B) ? 1
				    : ((req_size == f3_SIZE_H) ? 2
				       : ((req_size == f3_SIZE_W) ? 4
					  : 8)));
	 PA  phys_addr_hi      = phys_addr_lo + zeroExtend (req_size_bytes - 1);

	 WordXL phys_addr_lo_msbs = fn_pmpaddr_msbs (truncateLSB (phys_addr_lo));
	 WordXL phys_addr_hi_msbs = fn_pmpaddr_msbs (truncateLSB (phys_addr_hi));

	 function ActionValue #(PMP_Match) fav_addr_match (Integer j);
	    actionvalue
	       let  cfg_j        = vrg_pmpcfg [j];
	       let  cfg_j_locked = (fn_pmpcfg_L (cfg_j) == 1'b1);
	       let  cfg_j_A      = fn_pmpcfg_A (cfg_j);
	       let  cfg_j_R      = fn_pmpcfg_R (cfg_j);
	       let  cfg_j_W      = fn_pmpcfg_W (cfg_j);
	       let  cfg_j_X      = fn_pmpcfg_X (cfg_j);

	       let  region_hi_msbs = fn_pmpaddr_msbs (vrg_pmpaddr [j]);
               let  region_lo_msbs = ((cfg_j_A == pmpcfg_A_OFF) ? 0    // don't care
				      : (  (cfg_j_A == pmpcfg_A_TOR) ? ((j == 0) ? 0 : fn_pmpaddr_msbs (vrg_pmpaddr [j-1]))
					 : region_hi_msbs));

	       if (verbosity != 0)
		  $display ("    fav_addr_match (%0d) region_hi_msbs 0x%0h  region_lo_msbs 0x%0h ",
			    j, region_hi_msbs, region_lo_msbs);

	       // Do any bytes of the access lie in the pmp region?
	       Bool addr_overlap  = ((phys_addr_lo_msbs == region_hi_msbs) || (phys_addr_hi_msbs == region_hi_msbs));

	       // Do all bytes of the access lie in the pmp region?
	       Bool addr_in_range = ((phys_addr_lo_msbs == region_hi_msbs) && (phys_addr_hi_msbs == region_hi_msbs));

	       if (verbosity != 0)
		  $display ("        addr_overlap = %0d  addr_in_range = %0d",  addr_overlap, addr_in_range);

	       PMP_Match pmp_match = PMP_MATCH_NULL;
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
	       if (verbosity != 0)
		  $display ("        result ", fshow (pmp_match));
	       return pmp_match;
	    endactionvalue
	 endfunction

	 // Scan match results sequentially for first match-succeed or match-fail, if any.
	 PMP_Match pmp_match = PMP_MATCH_NULL;
	 for (Integer j = 0; j < num_pmp_regions; j = j + 1) begin
	    PMP_Match match_j <- fav_addr_match (j);
	    if ((pmp_match == PMP_MATCH_NULL) && (match_j != PMP_MATCH_NULL))
	       pmp_match = match_j;
	 end
	 if (verbosity != 0)
	    $display ("    fav_permitted () pmp_match = ", fshow (pmp_match));

	 Bool permitted = False;
	 if (priv == m_Priv_Mode)
	    permitted = ((pmp_match == PMP_MATCH_NULL) || (pmp_match == PMP_MATCH_SUCCEED));
	 else begin
	    // S or U privilege
	    if (pmp_match == PMP_MATCH_NULL)
	       permitted = (num_pmp_regions == 0);
	    else
	       permitted = (pmp_match == PMP_MATCH_SUCCEED);
	 end
   
	 return permitted;
      endactionvalue
   endfunction

   rule rl_reset;
      let tok <- pop (f_reset_reqs);
      writeVReg (vrg_pmpcfg, replicate (0));
      f_reset_rsps.enq (tok);
      if (verbosity != 0)
	 $display ("%0d: %m.rl_reset: PMPU has %0d regions with granularity G=%0d",
		   cur_cycle, num_pmp_regions, pmp_G);
   endrule

   // ----------------------------------------------------------------
   // INTERFACE

   // Reset request/response
   interface server_reset = toGPServer (f_reset_reqs, f_reset_rsps);

   method Bit #(5) m_num_pmp_regions;    // 0..16
      return fromInteger (num_pmp_regions);
   endmethod

   method ActionValue #(Bool) permitted (PA          phys_addr,
					 MemReqSize  req_size,
					 Priv_Mode   priv,
					 Access_RWX  rwx);
      if (verbosity != 0) begin
	 $display ("%0d: %m.permitted (phys_addr 0x%0h  size %0d  priv %0d  access_rwx %0d)",
		   cur_cycle, phys_addr, req_size, priv, rwx);
	 fa_display_pmps ();
      end

      Bool result <- fav_permitted (phys_addr, req_size, priv, rwx);

      if (verbosity != 0)
	 $display ("    result = %0d", result);
      return result;
   endmethod

   interface PMPU_CSR_IFC  pmp_csrs;

      // ----------------
      method WordXL pmpcfg_read   (Bit #(2) j);    // j = 0..3
	 WordXL result = 0;

`ifdef RV32
	 // Assemble the 32-bit result from four 8-bit registers; j = {0,1,2,3}
         Bit #(4) k_init   = { j, 2'b0 };    // k_init = 0, 4, 8, 12
	 for (Integer k = 0; k < 4; k = k + 1) begin
	    Bit #(4) kk = k_init + fromInteger (k);
	    Bit #(8) cfg_kk = ((kk <= fromInteger (num_pmp_regions-1)) ? vrg_pmpcfg [kk] : 0);
	    result = { cfg_kk, result [31:8] };
	 end
`elsif RV64
	 // Assemble the 64-bit result from eight 8-bit registers; j = {0,2}
	 Bit #(4) k_init   = { j[1], 3'b0 };    // k_init = 0, 8
	 for (Integer k = 0; k < 8; k = k + 1) begin
	    Bit #(4) kk = k_init + fromInteger (k);
	    Bit #(8) cfg_kk = ((kk <= fromInteger (num_pmp_regions-1)) ? vrg_pmpcfg [kk] : 0);
	    result = { cfg_kk, result [63:8] };
	 end
`endif

	 return result;
      endmethod

      // ----------------
      method ActionValue #(WordXL) pmpcfg_write  (Bit #(2) j, WordXL x);    // j = 0..3
	 if (verbosity != 0) begin
	    $display ("%0d: %m.pmpcfg_write (j %0d, x 0x%08h)", cur_cycle, j, x);
	    fa_display_pmps();
	 end

	 WordXL result = 0;

`ifdef RV32
	 result = x;
	 // Write four 8-bit registers from 32-bit x; j = {0,1,2,3}
	 Bit #(4) k_init = { j, 2'b0 };    // k_init = 0, 4, 8, 12
	 for (Integer k = 0; k < 4; k = k + 1) begin
	    Bit #(4) kk = k_init + fromInteger (k);
	    if (kk <= fromInteger (num_pmp_regions - 1))
	       if (fn_pmpcfg_L (vrg_pmpcfg [kk]) == 1'b0)    // is not locked
		  vrg_pmpcfg [kk] <= x [7:0];
	    x = { 8'b0, x [31:8] };
	 end
`elsif RV64
	 result = x;
	 // Write eight 8-bit registers from 64-bit x; j = {0,2}
	 Bit #(4) k_init = { j[1], 3'b0 };    // k_init = 0, 8
	 for (Integer k = 0; k < 8; k = k + 1) begin
	    Bit #(4) kk = k_init + fromInteger (k);
	    if (kk <= fromInteger (num_pmp_regions - 1))
	       if (fn_pmpcfg_L (vrg_pmpcfg [kk]) == 1'b0)    // is not locked
		  vrg_pmpcfg [kk] <= x [7:0];
	    x = { 8'b0, x [63:8] };
	 end
`endif

	 if (verbosity != 0) begin
	    $display ("    result = 0x%08h", result);
	 end

	 return result;
      endmethod

      // ----------------
      method WordXL pmpaddr_read  (Bit #(4) j);    // j = 0..15
	 WordXL result = ((j <= fromInteger (num_pmp_regions - 1)) ? vrg_pmpaddr [j] : 0);
	 return result;
      endmethod

      // ----------------
      method ActionValue #(WordXL) pmpaddr_write (Bit #(4) j, WordXL addr);    // j = 0..15
	 if (verbosity != 0) begin
	    $display ("%0d: %m.pmpaddr_write (%0d, 0x%08h)", cur_cycle, j, addr);
	    fa_display_pmps();
	 end

	 WordXL result = 0;
	 if (j <= (fromInteger (num_pmp_regions - 1))) begin
	    Bool locked = (fn_pmpcfg_L (vrg_pmpcfg [j]) == 1'b1);

	    Bool is_TOR_base = (   (j < fromInteger (num_pmp_regions - 1))
				&& (fn_pmpcfg_A (vrg_pmpcfg [j+1]) == pmpcfg_A_TOR));

	    if ((! locked) && (! is_TOR_base)) begin
	       vrg_pmpaddr [j] <= addr;
	       result = addr;
	    end
	    else if (verbosity != 0)
	       $display ("    Ignoring: locked = %0d, is_TOR_base = %0d", locked, is_TOR_base);
	 end

	 if (verbosity != 0)
	    $display ("    result = 0x%08h", result);

	 return result;
      endmethod
   endinterface

endmodule

// ================================================================

endpackage
