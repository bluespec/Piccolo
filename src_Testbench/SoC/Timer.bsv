// Copyright (c) 2016-2018 Bluespec, Inc. All Rights Reserved

package Timer;

// ================================================================
// This package implements a slave IP with two unrelated pieces of
// RISC-V functionality:
//
// - real-time timer:
//     Two 64-bit memory-mapped registers (rg_time and rg_timecmp).
//     Delivers an external interrupt whenever rg_timecmp >= rg_time.
//     The timer is cleared when rg_timecmp is written.
//     Can be used for the RISC-V v1.10 Privilege Spec 'mtime' and
//     'mtimecmp', and provides a memory-mapped API to access them.
//
//     Offset/Size        Name        Function
//     'h_4000/8 Bytes    mtimecmp    R/W the hart0 mtimecmp  register
//     'h_BFF8/8 Bytes    mtime       R/W the mtime     register
//
// - Memory-mapped location for software interrupts.
//
//     Offset/Size        Name        Function
//     'h_0000/8 Bytes    msip        R/W Writing LSB=1 generates a software interrupt to hart0
//
// ----------------
// This slave IP can be attached to fabrics with 32b- or 64b-wide data channels.
//    (NOTE: this is the width of the fabric, which can be chosen
//      independently of the native width of a CPU master on the
//      fabric (such as RV32/RV64 for a RISC-V CPU).
// When attached to 32b-wide fabric, 64-bit locations must be
// read/written in two 32b transaction, once for the lower 32b and
// once for the upper 32b.
//
// Some of the 'truncate()'s and 'zeroExtend()'s below are no-ops but
// necessary to satisfy type-checking.
// ================================================================

export Timer_IFC (..), mkTimer;

// ================================================================
// BSV library imports

import  Vector        :: *;
import  FIFOF         :: *;
import  GetPut        :: *;
import  ClientServer  :: *;
import  ConfigReg     :: *;

// ----------------
// BSV additional libs

import Cur_Cycle  :: *;
import GetPut_Aux :: *;
import Semi_FIFOF :: *;

// ================================================================
// Project imports

import Fabric_Defs     :: *;
import AXI4_Lite_Types :: *;

// ================================================================
// Local constants and types

// Module state
typedef enum {MODULE_STATE_START, MODULE_STATE_READY } Module_State
deriving (Bits, Eq, FShow);

// ================================================================
// Interface

interface Timer_IFC;
   // Reset
   interface Server #(Bit #(0), Bit #(0))  server_reset;

   // set_addr_map should be called after this module's reset
   method Action set_addr_map (Fabric_Addr addr_base, Fabric_Addr addr_lim);

   // Main Fabric Reqs/Rsps
   interface AXI4_Lite_Slave_IFC #(Wd_Addr, Wd_Data, Wd_User) slave;

   // External interrupt
   interface Get #(Bit #(0))  get_timer_interrupt_req;

   // Software interrupt
   interface Get #(Bit #(0))  get_sw_interrupt_req;
endinterface

// ================================================================

(* synthesize *)
module mkTimer (Timer_IFC);

   Reg #(Bit #(4)) cfg_verbosity <- mkConfigReg (0);

   Reg #(Module_State) rg_state     <- mkReg (MODULE_STATE_START);
   Reg #(Fabric_Addr)  rg_addr_base <- mkRegU;
   Reg #(Fabric_Addr)  rg_addr_lim  <- mkRegU;

   FIFOF #(Bit #(0)) f_reset_reqs <- mkFIFOF;
   FIFOF #(Bit #(0)) f_reset_rsps <- mkFIFOF;

   // ----------------
   // Connector to fabric

   AXI4_Lite_Slave_Xactor_IFC #(Wd_Addr, Wd_Data, Wd_User) slave_xactor <- mkAXI4_Lite_Slave_Xactor;

   // ----------------
   // Timer registers

   Reg #(Bit #(64)) crg_time [2]        <- mkCRegU (2);
   Reg #(Bit #(64)) crg_timecmp [2]     <- mkCRegU (2);
   Reg #(Bool)      crg_interrupted [2] <- mkCRegU (2);

   // Timer interrupt queue
   FIFOF #(Bit #(0)) f_timer_interrupt_req <- mkFIFOF;

   // ----------------
   // Software-interrupt registers

   // None: as soon as we write 1 to the MSIP addr, we enqueue a sw interrupt req.

   // Software interrupt queue
   FIFOF #(Bit #(0)) f_sw_interrupt_req <- mkFIFOF;

   // ================================================================
   // BEHAVIOR

   // ----------------------------------------------------------------
   // Reset

   // ns: 06/12/17 -- GDB reset bug fix
   // The explicit condition was preventing the Timer from being reset by GDB
   // after the initial hardware reset. This meant that on issuing a reset
   // command from GDB, control was never returned by hardware. The explicit
   // condition is not necessary as on a GDB reset, it's okay if the Timer
   // returns to its reset state irrespective of its current state
   // rule rl_reset (rg_state == MODULE_STATE_START);
   rule rl_reset;
      f_reset_reqs.deq;
      slave_xactor.reset;
      f_timer_interrupt_req.clear;
      f_sw_interrupt_req.clear;

      rg_state            <= MODULE_STATE_READY;
      crg_time [0]        <= 1;
      crg_timecmp [0]     <= 0;
      crg_interrupted [0] <= True;

      f_reset_rsps.enq (?);

      if (cfg_verbosity != 0)
	 $display ("%0d: Timer.rl_reset", cur_cycle);
   endrule

   // ----------------------------------------------------------------
   // Keep time and generate interrupt

   rule rl_always (rg_state == MODULE_STATE_READY);
      if ((! crg_interrupted [0]) && (crg_time [0] >= crg_timecmp [0])) begin
	 crg_interrupted [0] <= True;
	 f_timer_interrupt_req.enq (?);
	 if  (cfg_verbosity > 1)
	    $display ("%0d: Timer.rl_always: raising interrupt. time = %0d, timecmp = %0d",
		      cur_cycle, crg_time [0], crg_timecmp [0]);
      end

      // Increment time, but saturate, do not wrap-around
      if (crg_time [0] != '1)
	 crg_time [0] <= crg_time [0] + 1;
   endrule

   // ----------------------------------------------------------------
   // Handle fabric read requests

   rule rl_process_rd_req (rg_state == MODULE_STATE_READY);
      let rda <- pop_o (slave_xactor.o_rd_addr);

      let byte_addr = rda.araddr - rg_addr_base;

      Bit #(Wd_Data) rdata  = 0;
      AXI4_Lite_Resp rresp = AXI4_LITE_OKAY;

      case (byte_addr)
	 'h_0000: rdata = 0;                             // MSIP reads as zero
	 'h_4000: rdata = truncate (crg_timecmp [0]);    // truncates for 32b fabrics
	 'h_BFF8: rdata = truncate (crg_time [0]);       // truncates for 32b fabrics

	 // The following ALIGN4B reads are only needed for 32b fabrics
	 'h_0004: rdata = 0;    // MSIP reads as zero
	 'h_4004: rdata = zeroExtend (crg_timecmp [0] [63:32]);    // extends for 64b fabrics
	 'h_BFFC: rdata = zeroExtend (crg_time    [0] [63:32]);    // extends for 64b fabrics
	 default: begin
		     rresp = AXI4_LITE_SLVERR;

		     $display ("%0d: ERROR: Timer.rl_process_rd_req: unrecognized addr", cur_cycle);
		     $display ("            ", fshow (rda));
		  end
      endcase

      let rdr = AXI4_Lite_Rd_Data {rresp: rresp, rdata: rdata, ruser: rda.aruser};
      slave_xactor.i_rd_data.enq (rdr);

      if (cfg_verbosity > 1) begin
	 $display ("%0d: Timer.rl_process_rd_req: ", cur_cycle);
	 $display ("        ", fshow (rda));
	 $display ("     => ", fshow (rdr));
      end
   endrule

   // ----------------------------------------------------------------
   // Handle fabric write requests

   rule rl_process_wr_req (rg_state == MODULE_STATE_READY);
      let wra <- pop_o (slave_xactor.o_wr_addr);
      let wrd <- pop_o (slave_xactor.o_wr_data);

      let byte_addr = wra.awaddr - rg_addr_base;

      AXI4_Lite_Resp bresp = AXI4_LITE_OKAY;

      case (byte_addr)
	 'h_0000: if (wrd.wdata [0] == 1'b1) f_sw_interrupt_req.enq (?);
	 'h_4000: begin
		     if (valueOf (Wd_Data) == 32)
			// 32b fabric: data is only lower 32b
			crg_timecmp [1] <= { crg_timecmp [1] [63:32], wrd.wdata [31:0] };
		     else
			// 64b fabric: data is full 64b
			crg_timecmp [1] <= zeroExtend (wrd.wdata);
		     crg_interrupted [1] <= False;
		  end
	 'h_BFF8: begin
		     if (valueOf (Wd_Data) == 32)
			// 32b fabric: data is only lower 32b
			crg_time [1] <= { crg_time [1] [63:32], wrd.wdata [31:0] };
		     else
			// 64b fabric: data is full 64b
			crg_time [1] <= zeroExtend (wrd.wdata);
		       end

	 // The following ALIGN4B reads are only needed for 32b fabrics
	 'h_0004: noAction;
	 'h_4004: begin
		     crg_timecmp     [1] <= { wrd.wdata [31:0], crg_timecmp [1] [31:0] };
		     crg_interrupted [1] <= False;
		  end
	 'h_BFFC: begin
		     crg_time [1] <= { wrd.wdata [31:0], crg_time [1] [31:0] };
		  end

	 default: begin
		     $display ("%0d: ERROR: Timer.rl_process_wr_req: unrecognized addr", cur_cycle);
		     $display ("            ", fshow (wra));
		     $display ("            ", fshow (wrd));
		     bresp  = AXI4_LITE_SLVERR;
		  end
      endcase

      let wrr = AXI4_Lite_Wr_Resp {bresp: bresp, buser: wra.awuser};
			 
      slave_xactor.i_wr_resp.enq (wrr);

      if (cfg_verbosity > 1) begin
	 $display ("%0d: Timer.rl_process_wr_req", cur_cycle);
	 $display ("        ", fshow (wra));
	 $display ("        ", fshow (wrd));
	 $display ("     => ", fshow (wrr));
      end
   endrule

   // ================================================================
   // INTERFACE

   // Reset
   interface  server_reset = toGPServer (f_reset_reqs, f_reset_rsps);

   // set_addr_map should be called after this module's reset
   method Action  set_addr_map (Fabric_Addr addr_base, Fabric_Addr addr_lim);
      if (addr_base [1:0] != 0)
	 $display ("%0d: WARNING: Timer.set_addr_map: addr_base 0x%0h is not 4-Byte-aligned",
		   cur_cycle, addr_base);

      if (addr_lim [1:0] != 0)
	 $display ("%0d: WARNING: Timer.set_addr_map: addr_lim 0x%0h is not 4-Byte-aligned",
		   cur_cycle, addr_lim);

      rg_addr_base <= addr_base;
      rg_addr_lim  <= addr_lim;
   endmethod

   // Main Fabric Reqs/Rsps
   interface  slave = slave_xactor.axi_side;

   // External interrupt
   interface get_timer_interrupt_req = toGet (f_timer_interrupt_req);

   // Software interrupt
   interface get_sw_interrupt_req = toGet (f_sw_interrupt_req);
endmodule

// ================================================================

endpackage
