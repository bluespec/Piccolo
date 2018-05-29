// Copyright (c) 2013-2018 Bluespec, Inc. All Rights Reserved.

package Top_HW_Side;

// ================================================================
// mkTop_HW_Side is the top-level system for simulation.
// mkMem_Model is a memory model.

// ================================================================
// BSV lib imports

import GetPut       :: *;
import ClientServer :: *;
import Connectable  :: *;

// ----------------
// BSV additional libs

import Cur_Cycle  :: *;
import GetPut_Aux :: *;

// ================================================================
// Project imports

// From Factory
import ISA_Decls           :: *;

import SoC_Top             :: *;
import Mem_Controller      :: *;

// Factory wrapper
import Mem_Model           :: *;

// ================================================================
// Top-level module.
// Instantiates the SoC.
// Instantiates a memory model.

(* synthesize *)
module mkTop_HW_Side (Empty) ;

   SoC_Top_IFC    soc_top   <- mkSoC_Top;
   Mem_Model_IFC  mem_model <- mkMem_Model;

   // Connect SoC to raw memory
   let memCnx <- mkConnection (soc_top.to_raw_mem, mem_model.mem_server);

   // ----------------
   // BEHAVIOR

`ifdef INCLUDE_TANDEM_VERIF
   // Tandem verifier: drain and discard packets
   rule rl_drain_tandem;
      let tv_packet <- soc_top.verify_out.get;
      // $display ("%0d: Top_HW_Side.rl_drain_tandem: drained a TV packet", cur_cycle, fshow (tv_packet));
   endrule
`endif

   // UART console I/O: drain print output.
   rule rl_relay_console_out;
      let ch <- soc_top.get_to_console.get;

      if (   (ch == 'h8)    // BS
	  || (ch == 'h9)    // TAB
	  || (ch == 'hA)    // LF
	  || (ch == 'h15)   // CR
	  || (ch >= 'h20))  // printable
	 $write ("%c", ch);
      else
	 $write ("[ASCII 0x%h]", ch);
      $fflush (stdout);
   endrule

   Reg #(Bool) rg_banner_printed <- mkReg (False);

   // Display a banner
   rule rl_step0 (! rg_banner_printed);
      $display ("================================================================");
      $display ("Bluespec RISC-V standalone system simulation v1.1");
      $display ("Copyright (c) 2017-2018 Bluespec, Inc. All Rights Reserved.");
      $display ("================================================================");

      rg_banner_printed <= True;
   endrule

   // ----------------------------------------------------------------
   // INTERFACE

   //  None (this is top-level)

endmodule

// ================================================================

endpackage: Top_HW_Side
