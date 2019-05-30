// Copyright (c) 2016-2019 Bluespec, Inc. All Rights Reserved.

package SoC_Top;

// ================================================================
// This package is the SoC "top-level".

// (Note: there will be further layer(s) above this for
//    simulation top-level, FPGA top-level, etc.)

// ================================================================
// Exports

export SoC_Top_IFC (..), mkSoC_Top;

// ================================================================
// BSV library imports

import FIFOF         :: *;
import GetPut        :: *;
import ClientServer  :: *;
import Connectable   :: *;
import Memory        :: *;
import Vector        :: *;

// ----------------
// BSV additional libs

import Cur_Cycle   :: *;
import GetPut_Aux  :: *;
import Routable    :: *;
import AXI4        :: *;

// ================================================================
// Project imports

import Fabric_Defs :: *;
import SoC_Map     :: *;

// SoC components (CPU, mem, and IPs)

import Core_IFC :: *;
import Core     :: *;
import PLIC     :: *;    // For interface to PLIC interrupt sources, in Core_IFC

import Boot_ROM       :: *;
import Mem_Controller :: *;
import UART_Model     :: *;

`ifdef INCLUDE_CAMERA_MODEL
import Camera_Model   :: *;
`endif

`ifdef INCLUDE_ACCEL0
import Accel_AES      :: *;
`endif

`ifdef INCLUDE_TANDEM_VERIF
import TV_Info :: *;
`endif

`ifdef INCLUDE_GDB_CONTROL
import External_Control :: *;    // Control requests/responses from HSFE
import Debug_Module     :: *;
`endif

// ================================================================
// The outermost interface of the SoC

interface SoC_Top_IFC;
   // Set core's verbosity
   method Action  set_verbosity (Bit #(4)  verbosity, Bit #(64)  logdelay);

`ifdef INCLUDE_GDB_CONTROL
   // To external controller (E.g., GDB)
   interface Server #(Control_Req, Control_Rsp) server_external_control;
`endif

`ifdef INCLUDE_TANDEM_VERIF
   // To tandem verifier
   interface Get #(Info_CPU_to_Verifier) tv_verifier_info_get;
`endif

   // External real memory
   interface MemoryClient #(Bits_per_Raw_Mem_Addr, Bits_per_Raw_Mem_Word)  to_raw_mem;

   // UART0 to external console
   interface Get #(Bit #(8)) get_to_console;
   interface Put #(Bit #(8)) put_from_console;

   // Catch-all status; return-value can identify the origin (0 = none)
   (* always_ready *)
   method Bit #(8) status;

   // For ISA tests: watch memory writes to <tohost> addr
   method Action set_watch_tohost (Bool  watch_tohost, Fabric_Addr  tohost_addr);
endinterface

// ================================================================
// Local types and constants

typedef enum {SOC_START,
	      SOC_RESETTING,
`ifdef INCLUDE_GDB_CONTROL
	      SOC_RESETTING_NDM,
`endif
	      SOC_IDLE} SoC_State
deriving (Bits, Eq, FShow);

// ================================================================
// The module

(* synthesize *)
module mkSoC_Top (SoC_Top_IFC);
   Integer verbosity = 0;    // Normally 0; non-zero for debugging

   Reg #(SoC_State) rg_state <- mkReg (SOC_START);

   // SoC address map specifying base and limit for memories, IPs, etc.
   SoC_Map_IFC soc_map <- mkSoC_Map;

   // Core: CPU + Near_Mem_IO (CLINT) + PLIC + Debug module (optional) + TV (optional)
   Core_IFC #(N_External_Interrupt_Sources)  core <- mkCore;

   // SoC Boot ROM
   Boot_ROM_IFC  boot_rom <- mkBoot_ROM;
   // AXI4 Deburster in front of Boot_ROM
   AXI4_Shim#(Wd_SId, Wd_Addr, Wd_Data,
              Wd_AW_User, Wd_W_User, Wd_B_User, Wd_AR_User, Wd_R_User)
              boot_rom_axi4_deburster <- mkBurstToNoBurst;

   // SoC Memory
   Mem_Controller_IFC  mem0_controller <- mkMem_Controller;
   // AXI4 Deburster in front of SoC Memory
   AXI4_Shim#(Wd_SId, Wd_Addr, Wd_Data,
              Wd_AW_User, Wd_W_User, Wd_B_User, Wd_AR_User, Wd_R_User)
              mem0_controller_axi4_deburster <- mkBurstToNoBurst;

   // SoC IPs
   UART_IFC   uart0  <- mkUART;

`ifdef INCLUDE_ACCEL0
   // Accel0 master to fabric
   Accel_AES_IFC  accel_aes0 <- mkAccel_AES;
`endif

   // ----------------
   // SoC fabric master connections
   // Note: see 'SoC_Map' for 'master_num' definitions

   Vector#(Num_Masters, AXI4_Master_Synth #(Wd_MId, Wd_Addr, Wd_Data,
                                            Wd_User, Wd_User, Wd_User,
                                            Wd_User, Wd_User))
                                            master_vector = newVector;

   // CPU IMem master to fabric
   master_vector[imem_master_num] = core.cpu_imem_master;

   // CPU DMem master to fabric
   master_vector[dmem_master_num] = core.cpu_dmem_master;

`ifdef INCLUDE_ACCEL0
   // accel_aes0 to fabric
   master_vector[accel0_master_num] = accel_aes0.master;
`endif

   // ----------------
   // SoC fabric slave connections
   // Note: see 'SoC_Map' for 'slave_num' definitions

   Vector#(Num_Slaves, AXI4_Slave_Synth #(Wd_SId, Wd_Addr, Wd_Data,
                                          Wd_User, Wd_User, Wd_User,
                                          Wd_User, Wd_User))
                                          slave_vector = newVector;
   Vector#(Num_Slaves, Range#(Wd_Addr))   route_vector = newVector;

   // Fabric to Boot ROM
   let br <- fromAXI4_Slave_Synth(boot_rom.slave);
   mkConnection(boot_rom_axi4_deburster.master, br);
   let ug_boot_rom_slave <- toUnguarded_AXI4_Slave(boot_rom_axi4_deburster.slave);
   slave_vector[boot_rom_slave_num] = toAXI4_Slave_Synth(ug_boot_rom_slave);
   route_vector[boot_rom_slave_num] = soc_map.m_boot_rom_addr_range;

   // Fabric to Mem Controller
   let mem <- fromAXI4_Slave_Synth(mem0_controller.slave);
   mkConnection(mem0_controller_axi4_deburster.master, mem);
   let ug_mem0_slave <- toUnguarded_AXI4_Slave(mem0_controller_axi4_deburster.slave);
   slave_vector[mem0_controller_slave_num] = toAXI4_Slave_Synth(ug_mem0_slave);
   route_vector[mem0_controller_slave_num] = soc_map.m_mem0_controller_addr_range;

   // Fabric to UART0
   slave_vector[uart0_slave_num] = uart0.slave;
   route_vector[uart0_slave_num] = soc_map.m_uart0_addr_range;

`ifdef INCLUDE_ACCEL0
   // Fabric to accel_aes0
   slave_vector[accel0_slave_num] = accel_aes0.slave);
   route_vector[accel0_slave_num] = soc_map.m_accel0_addr_range;
`endif

`ifdef HTIF_MEMORY
   AXI4_Slave_IFC#(Wd_Id, Wd_Addr, Wd_Data, Wd_User) htif <- mkAxi4LRegFile(bytes_per_htif);

   slave_vector[htif_slave_num] = htif;
   route_vector[htif_slave_num] = soc_map.m_htif_addr_range;
`endif

   // SoC Fabric
   let bus <- mkAXI4Bus_Synth (routeFromMappingTable(route_vector),
                               master_vector, slave_vector);

   // ----------------
   // Connect interrupt sources for CPU external interrupt request inputs.

   // Reg #(Bool) rg_intr_prev <- mkReg (False);    // For debugging only

   (* fire_when_enabled, no_implicit_conditions *)
   rule rl_connect_external_interrupt_requests;
      Bool intr = uart0.intr;

      // UART
      core.core_external_interrupt_sources [irq_num_uart0].m_interrupt_req (intr);

      // Tie off remaining interrupt request lines (1..N)
      for (Integer j = 1; j < valueOf (N_External_Interrupt_Sources); j = j + 1)
	 core.core_external_interrupt_sources [j].m_interrupt_req (False);

      // Non-maskable interrupt request. [Tie-off; TODO: connect to genuine sources]
      core.nmi_req (False);

      /* For debugging only
      if ((! rg_intr_prev) && intr)
	 $display ("SoC_Top: intr posedge");
      else if (rg_intr_prev && (! intr))
	 $display ("SoC_Top: intr negedge");

      rg_intr_prev <= intr;
      */
   endrule

   // ================================================================
   // SOFT RESET

   function Action fa_reset_start_actions (Bool running);
      action
	 core.cpu_reset_server.request.put (running);
	 mem0_controller.server_reset.request.put (?);
	 uart0.server_reset.request.put (?);
      endaction
   endfunction

   function Action fa_reset_complete_actions ();
      action
	 let cpu_rsp             <- core.cpu_reset_server.response.get;
	 let mem0_controller_rsp <- mem0_controller.server_reset.response.get;
	 let uart0_rsp           <- uart0.server_reset.response.get;

	 // Initialize address maps of slave IPs
	 boot_rom.set_addr_map (rangeBase(soc_map.m_boot_rom_addr_range),
				rangeTop(soc_map.m_boot_rom_addr_range));

	 mem0_controller.set_addr_map (rangeBase(soc_map.m_mem0_controller_addr_range),
				       rangeTop(soc_map.m_mem0_controller_addr_range));

	 uart0.set_addr_map (rangeBase(soc_map.m_uart0_addr_range),
                             rangeTop(soc_map.m_uart0_addr_range));

	 if (verbosity != 0) begin
	    $display ("  SoC address map:");
	    $display ("  Boot ROM:        0x%0h .. 0x%0h",
		      rangeBase(soc_map.m_boot_rom_addr_range),
		      rangeTop(soc_map.m_boot_rom_addr_range));
	    $display ("  Mem0 Controller: 0x%0h .. 0x%0h",
		      rangeBase(soc_map.m_mem0_controller_addr_range),
		      rangeTop(soc_map.m_mem0_controller_addr_range));
	    $display ("  UART0:           0x%0h .. 0x%0h",
		      rangeBase(soc_map.m_uart0_addr_range),
		      rangeTop(soc_map.m_uart0_addr_range));
	 end
      endaction
   endfunction

   // ----------------
   // Initial reset

   rule rl_reset_start_initial (rg_state == SOC_START);
      Bool running = True;
      fa_reset_start_actions (running);
      rg_state <= SOC_RESETTING;

      $display ("%0d: SoC_Top. Reset start ...", cur_cycle);
   endrule

   rule rl_reset_complete_initial (rg_state == SOC_RESETTING);
      fa_reset_complete_actions;
      rg_state <= SOC_IDLE;

      $display ("%0d: SoC_Top. Reset complete ...", cur_cycle);
   endrule

   // ----------------
   // NDM (non-debug-module) reset (requested from Debug Module)

`ifdef INCLUDE_GDB_CONTROL
   Reg #(Bool) rg_running <- mkRegU;

   rule rl_ndm_reset_start (rg_state == SOC_IDLE);
      let running <- core.ndm_reset_client.request.get;
      rg_running <= running;

      fa_reset_start_actions (running);
      rg_state <= SOC_RESETTING_NDM;

      $display ("%0d: SoC_Top.rl_ndm_reset_start (non-debug-module) running = ...",
		cur_cycle, fshow (running));
   endrule

   rule rl_ndm_reset_complete (rg_state == SOC_RESETTING_NDM);
      fa_reset_complete_actions;
      rg_state <= SOC_IDLE;

      core.ndm_reset_client.response.put (rg_running);

      $display ("%0d: SoC_Top.rl_ndm_reset_complete (non-debug-module) running = ",
		cur_cycle, fshow (rg_running));
   endrule
`endif

   // ================================================================
   // BEHAVIOR WITH DEBUG MODULE

`ifdef INCLUDE_GDB_CONTROL
   // ----------------------------------------------------------------
   // External debug requests and responses (e.g., GDB)

   FIFOF #(Control_Req) f_external_control_reqs <- mkFIFOF;
   FIFOF #(Control_Rsp) f_external_control_rsps <- mkFIFOF;

   Control_Req req = f_external_control_reqs.first;

   rule rl_handle_external_req_read_request (req.op == external_control_req_op_read_control_fabric);
      f_external_control_reqs.deq;
      core.dm_dmi.read_addr (truncate (req.arg1));
      if (verbosity != 0) begin
	 $display ("%0d: SoC_Top.rl_handle_external_req_read_request", cur_cycle);
         $display ("    ", fshow (req));
      end
   endrule

   rule rl_handle_external_req_read_response;
      let x <- core.dm_dmi.read_data;
      let rsp = Control_Rsp {status: external_control_rsp_status_ok, result: signExtend (x)};
      f_external_control_rsps.enq (rsp);
      if (verbosity != 0) begin
	 $display ("%0d: SoC_Top.rl_handle_external_req_read_response", cur_cycle);
         $display ("    ", fshow (rsp));
      end
   endrule

   rule rl_handle_external_req_write (req.op == external_control_req_op_write_control_fabric);
      f_external_control_reqs.deq;
      core.dm_dmi.write (truncate (req.arg1), truncate (req.arg2));
      // let rsp = Control_Rsp {status: external_control_rsp_status_ok, result: 0};
      // f_external_control_rsps.enq (rsp);
      if (verbosity != 0) begin
         $display ("%0d: SoC_Top.rl_handle_external_req_write", cur_cycle);
         $display ("    ", fshow (req));
      end
   endrule

   rule rl_handle_external_req_err (   (req.op != external_control_req_op_read_control_fabric)
				    && (req.op != external_control_req_op_write_control_fabric));
      f_external_control_reqs.deq;
      let rsp = Control_Rsp {status: external_control_rsp_status_err, result: 0};
      f_external_control_rsps.enq (rsp);

      $display ("%0d: SoC_Top.rl_handle_external_req_err: unknown req.op", cur_cycle);
      $display ("    ", fshow (req));
   endrule

   // ----------------------------------------------------------------
   // NDM reset (all except Debug Module) request from debug module

   rule rl_reset_start (rg_state != SOC_RESETTING);
      let req <- core.dm_ndm_reset_req_get.get;

      core.cpu_reset_server.request.put (?);
      mem0_controller.server_reset.request.put (?);
      uart0.server_reset.request.put (?);

      boot_rom_axi4_deburster.clear;
      mem0_controller_axi4_deburster.clear;

      rg_state <= SOC_RESETTING;

      $display ("%0d: SoC_Top.rl_reset_start (Debug Module NDM reset, all except debug module) ...",
		cur_cycle);
   endrule
`endif

   rule rl_reset_complete (rg_state == SOC_RESETTING);
      let cpu_rsp             <- core.cpu_reset_server.response.get;
      let mem0_controller_rsp <- mem0_controller.server_reset.response.get;
      let uart0_rsp           <- uart0.server_reset.response.get;

      // Initialize address maps of slave IPs
      boot_rom.set_addr_map (rangeBase(soc_map.m_boot_rom_addr_range),
			     rangeTop(soc_map.m_boot_rom_addr_range));

      mem0_controller.set_addr_map (rangeBase(soc_map.m_mem0_controller_addr_range),
				    rangeTop(soc_map.m_mem0_controller_addr_range));

      uart0.set_addr_map (rangeBase(soc_map.m_uart0_addr_range),
                          rangeTop(soc_map.m_uart0_addr_range));

      rg_state <= SOC_IDLE;

`ifdef INCLUDE_GDB_CONTROL
      $display ("%0d: SoC_Top: NDM reset complete (all except debug module)", cur_cycle);
`else
      $display ("%0d: SoC_Top. Reset complete ...", cur_cycle);
`endif

      if (verbosity != 0) begin
	 $display ("  SoC address map:");
	 $display ("  Boot ROM:        0x%0h .. 0x%0h",
		   rangeBase(soc_map.m_boot_rom_addr_range),
		   rangeTop(soc_map.m_boot_rom_addr_range));
	 $display ("  Mem0 Controller: 0x%0h .. 0x%0h",
		   rangeBase(soc_map.m_mem0_controller_addr_range),
		   rangeTop(soc_map.m_mem0_controller_addr_range));
	 $display ("  UART0:           0x%0h .. 0x%0h",
		   rangeBase(soc_map.m_uart0_addr_range),
		   rangeTop(soc_map.m_uart0_addr_range));
      end
   endrule

   // ================================================================
   // INTERFACE

   method Action  set_verbosity (Bit #(4)  verbosity1, Bit #(64)  logdelay);
      core.set_verbosity (verbosity1, logdelay);
   endmethod

   // To external controller (E.g., GDB)
`ifdef INCLUDE_GDB_CONTROL
   interface server_external_control = toGPServer (f_external_control_reqs, f_external_control_rsps);
`endif

`ifdef INCLUDE_TANDEM_VERIF
   // To tandem verifier
   interface tv_verifier_info_get = core.tv_verifier_info_get;
`endif

   // External real memory
   interface to_raw_mem = mem0_controller.to_raw_mem;

   // UART to external console
   interface get_to_console   = uart0.get_to_console;
   interface put_from_console = uart0.put_from_console;

   // Catch-all status; return-value can identify the origin (0 = none)
   method Bit #(8) status;
      return mem0_controller.status;
   endmethod

   // For ISA tests: watch memory writes to <tohost> addr
   method Action set_watch_tohost (Bool  watch_tohost, Fabric_Addr  tohost_addr);
      mem0_controller.set_watch_tohost (watch_tohost, tohost_addr);
   endmethod
endmodule: mkSoC_Top

// ================================================================

endpackage
