// Copyright (c) 2019 Bluespec, Inc. All Rights Reserved

package PMPU;

// ================================================================
// This defines a module for a PMPU (Physical Memory Protection Unit)
// Reference:
//      "The RISC-V Instruction Set Manual"
//      Volume II: Privileged Architecture, Version 1.11-draft, October 1, 2018
//      Section 3.6.1

// Use this file only when actually implementing PMPs
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
// "Granularity"-related constants

// "Grain size" is not the same as protected-region size.
// Grain size is just about alignment of addresses of region boundaries.
// Region sizes are >= grain size.

// The grain size is fixed for a platform, i.e., a static parameter.
// (see email from Andrew Waterman on Aug 13, 2019)
// "G" is the grain-size parameter for a platform; grain size is 2^{G+2}

// ----------------
// When pmpcfg.A = {OFF, TOR}: when G>=1, pmpaddr[G-1:0] read as all zeros.
// This mask is 111..111_000..000    with G lsbs cleared.

Bit #(64) pmpaddr_mask_G = ((pmp_G >= 1) ? ('1 << pmp_G) : '1);

// ----------------
// When pmpcfg.A = {NA4, NAPOT}: when G>=2, pmpaddr[G-2:0] read as all ones
// This mask is 000...000_111..111    with G-1 lsbs set

Bit #(64) pmpaddr_mask_NAPOT = ((pmp_G >= 2) ? (~ ('1 << (pmp_G - 1))) : 0);

// ================================================================
// MODULE IMPLEMENTATION

// Note: physical addrs can be 32/34/56/64 bits depending on RV32/RV64
// and whether 'S' extension and Virtual Memory are supported or not.
// For uniformity, we represent everything using 64 bits and rely
// on hardware optimization to remove constant-zero registers and logic.

typedef enum {PMP_MATCH_NULL,                // NA = not applicable
	      PMP_MATCH_SUCCEED,
	      PMP_MATCH_FAIL
   } PMP_Match
deriving (Eq, Bits, FShow);

(* synthesize *)
module mkPMPU (PMPU_IFC);

   messageM ("INFO: PMPU.bsv: compiling with PMPs");

   Integer verbosity = 0;    // For debugging only

   // ----------------
   // Reset requests and responses
   FIFOF #(Token) f_reset_reqs <- mkFIFOF;
   FIFOF #(Token) f_reset_rsps <- mkFIFOF;

   // ----------------
   // We keep pmpcfg regs in separate registers, combining them into
   // their CSR packed form as needed during CSR reads and writes.

   Vector #(Num_PMP_Regions, Reg #(Bit #(8)))   vrg_pmpcfg  <- replicateM (mkReg (0));

   Vector #(Num_PMP_Regions, Reg #(Bit #(64)))  vrg_pmpaddr <- replicateM (mkRegU);

   // We pre-compute address masks for NAPOT whenever the CSR is
   // updated, to avoid lengthening the critical path of memory
   // access by doing it during address checks.

   Vector #(Num_PMP_Regions, Reg #(Bit #(64)))  vrg_NAPOT_mask <- replicateM (mkRegU);

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

	 for (Integer j = 0; j < num_pmp_regions; j = j + 1)
	    $display ("    pmpaddr [%0d] = 0x%0h  NAPOT_mask = 0x%0h",
		      j, vrg_pmpaddr [j], vrg_NAPOT_mask [j]);
      endaction
   endfunction

   // ----------------------------------------------------------------
   // Check if addrs in the range lo..hi inclusive match PMP j

   function ActionValue #(PMP_Match) fav_addr_match (Integer     j,
						     Bit #(64)   addr_base,
						     Bit #(64)   addr_lim,
						     Priv_Mode   priv,
						     Access_RWX  rwx);
      actionvalue
	 let  cfg        = vrg_pmpcfg [j];
	 let  cfg_locked = (fn_pmpcfg_L (cfg) == 1'b1);
	 let  cfg_A      = fn_pmpcfg_A (cfg);
	 let  cfg_R      = fn_pmpcfg_R (cfg);
	 let  cfg_W      = fn_pmpcfg_W (cfg);
	 let  cfg_X      = fn_pmpcfg_X (cfg);

	 let  pmpaddr_prev = ((j == 0) ? 0 : vrg_pmpaddr [j-1]);
	 let  pmpaddr      = vrg_pmpaddr [j];

	 let  region_base  = (  (cfg_A == pmpcfg_A_TOR)
			      ? (pmpaddr_prev & pmpaddr_mask_G)
			      : (pmpaddr      & (~ (vrg_NAPOT_mask [j])))) << 2;
	 let  region_lim   = (  (cfg_A == pmpcfg_A_TOR)
			      ? (((pmpaddr & pmpaddr_mask_G) << 2) - 1)
			      : (((pmpaddr | vrg_NAPOT_mask [j]) << 2) | 'h3));
	 if (verbosity != 0)
	    $display ("    fav_addr_match [%0d]  cfg 0x%0h  cfg_A %0d  region_base 0x%0h  region_lim 0x%0h",
		      j, cfg, cfg_A, region_base, region_lim);

	 // Do any bytes of the access lie in the pmp region?
	 Bool addr_overlap  = ! ((addr_lim < region_base) || (region_lim < addr_base));

	 // Do all bytes of the access lie in the pmp region?
	 Bool addr_in_range = ((region_base <= addr_base) && (addr_lim <= region_lim));

	 if (verbosity != 0)
	    $display ("        addr_overlap = %0d  addr_in_range = %0d",  addr_overlap, addr_in_range);

	 PMP_Match pmp_match = PMP_MATCH_NULL;
	 if (cfg_A != pmpcfg_A_OFF) begin
	    if (addr_overlap) begin
	       pmp_match = PMP_MATCH_FAIL;
	       if (   (addr_in_range)
		   && (   ((! cfg_locked) && (priv == m_Priv_Mode))
		       || (   (cfg_locked || (priv == s_Priv_Mode) || (priv == u_Priv_Mode))
			   && (   ((cfg_R == 1'b1) && (rwx == Access_RWX_R))
			       || ((cfg_W == 1'b1) && (rwx == Access_RWX_W))
			       || ((cfg_X == 1'b1) && (rwx == Access_RWX_X))))))
		  pmp_match = PMP_MATCH_SUCCEED;
	    end
	 end
	 if (verbosity != 0)
	    $display ("        result ", fshow (pmp_match));
	 return pmp_match;
      endactionvalue
   endfunction: fav_addr_match

   // ----------------------------------------------------------------
   // Sequence through the PMPs to see if this access is permitted

   function ActionValue #(Bool) fav_permitted (PA          phys_addr,
					       MemReqSize  req_size,
					       Priv_Mode   priv,
					       Access_RWX  rwx);
      actionvalue
	 Bit #(4) req_size_bytes = ((req_size == f3_SIZE_B) ? 1
				    : ((req_size == f3_SIZE_H) ? 2
				       : ((req_size == f3_SIZE_W) ? 4
					  : 8)));
	 Bit #(64) addr_base = zeroExtend (phys_addr);
	 Bit #(64) addr_lim  = addr_base + zeroExtend (req_size_bytes - 1);

	 // Scan match results sequentially for first match-succeed or match-fail, if any.
	 PMP_Match pmp_match = PMP_MATCH_NULL;
	 for (Integer j = 0; j < num_pmp_regions; j = j + 1) begin
	    PMP_Match match_j <- fav_addr_match (j, addr_base, addr_lim, priv, rwx);
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
   endfunction: fav_permitted

   // ----------------------------------------------------------------

   rule rl_reset;
      let tok <- pop (f_reset_reqs);

      // Set PMP 0 (if it exists) to NAPOT, full memory
      if (num_pmp_regions != 0) begin
	 vrg_pmpcfg [0]     <= (  (zeroExtend (pmpcfg_A_NAPOT) << pmpcfg_A_bitpos)
				| (1              << pmpcfg_X_bitpos)
				| (1              << pmpcfg_W_bitpos)
				| (1              << pmpcfg_R_bitpos));
	 vrg_pmpaddr [0]    <= '1;
	 vrg_NAPOT_mask [0] <= '1;
      end

      // Switch off all remaining PMPs
      for (Integer j = 1; j < num_pmp_regions; j = j + 1)
	 vrg_pmpcfg [j] <= (zeroExtend (pmpcfg_A_OFF) << pmpcfg_A_bitpos);
	 
      f_reset_rsps.enq (tok);

      $display ("%0d: %m.rl_reset: PMPU has %0d regions with granularity parameter G=%0d (0x%0h bytes)",
		cur_cycle, num_pmp_regions, pmp_G, (2 ** (pmp_G + 2)));
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
	       if (fn_pmpcfg_L (vrg_pmpcfg [kk]) == 1'b0) begin    // is not locked
		  Bit #(8) cfg = x [7:0];
		  if ((pmp_G >= 1) && (fn_pmpcfg_A (cfg)== pmpcfg_A_NA4))
		     cfg = (cfg | (zeroExtend (pmpcfg_A_NAPOT) << pmpcfg_A_bitpos));
		  vrg_pmpcfg [kk] <= cfg;
	       end
	    x = { 8'b0, x [31:8] };
	 end
`elsif RV64
	 result = x;
	 // Write eight 8-bit registers from 64-bit x; j = {0,2}
	 Bit #(4) k_init = { j[1], 3'b0 };    // k_init = 0, 8
	 for (Integer k = 0; k < 8; k = k + 1) begin
	    Bit #(4) kk = k_init + fromInteger (k);
	    if (kk <= fromInteger (num_pmp_regions - 1))
	       if (fn_pmpcfg_L (vrg_pmpcfg [kk]) == 1'b0) begin   // is not locked
		  Bit #(8) cfg = x [7:0];
		  if ((pmp_G >= 1) && (fn_pmpcfg_A (cfg)== pmpcfg_A_NA4))
		     cfg = (cfg | (zeroExtend (pmpcfg_A_NAPOT) << pmpcfg_A_bitpos));
		  vrg_pmpcfg [kk] <= cfg;
	       end
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
	 Bit #(64) result = 0;
	 if (j <= fromInteger (num_pmp_regions - 1)) begin
	    let cfg  = fn_pmpcfg_A (vrg_pmpcfg [j]);
	    let addr = vrg_pmpaddr [j];
	    result = ((cfg [1] == 1'b0)
		      ? (addr & pmpaddr_mask_G)        // G   lsbs read as 0s
		      : addr  | pmpaddr_mask_NAPOT);   // G-1 lsbs read as 1s
	 end
	 return truncate (result);
      endmethod

      // ----------------
      method ActionValue #(WordXL) pmpaddr_write (Bit #(4) j, WordXL addr4);    // j = 0..15
	 if (verbosity != 0) begin
	    $display ("%0d: %m.pmpaddr_write (%0d, 0x%08h)", cur_cycle, j, addr4);
	    fa_display_pmps();
	 end

	 WordXL result = 0;
	 if (j <= (fromInteger (num_pmp_regions - 1))) begin
	    Bool locked = (fn_pmpcfg_L (vrg_pmpcfg [j]) == 1'b1);

	    Bool is_locked_TOR_base = (   (j < fromInteger (num_pmp_regions - 1))
				       && (fn_pmpcfg_A (vrg_pmpcfg [j+1]) == pmpcfg_A_TOR)
				       && (fn_pmpcfg_L (vrg_pmpcfg [j+1]) == 1'b1));

	    if (locked || is_locked_TOR_base) begin
	       if (verbosity != 0)
		  $display ("    Ignoring: locked = %0d, is_locked_TOR_base = %0d", locked, is_locked_TOR_base);
	    end
	    else begin
	       Bit #(64) x = zeroExtend (addr4);
	       vrg_pmpaddr    [j] <= x;
	       vrg_NAPOT_mask [j] <= (((x + 1) ^ x) | (~ pmpaddr_mask_G));
	       result = addr4;
	    end
	 end

	 if (verbosity != 0)
	    $display ("    result = 0x%08h", result);

	 return truncate (result);
      endmethod
   endinterface

endmodule

// ================================================================

endpackage
