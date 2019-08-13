// Copyright (c) 2018-2019 Bluespec, Inc. All Rights Reserved.

//-
// AXI (user fields) modifications:
//     Copyright (c) 2019 Alexandre Joannou
//     Copyright (c) 2019 Peter Rugg
//     Copyright (c) 2019 Jonathan Woodruff
//     All rights reserved.
//
//     This software was developed by SRI International and the University of
//     Cambridge Computer Laboratory (Department of Computer Science and
//     Technology) under DARPA contract HR0011-18-C-0016 ("ECATS"), as part of the
//     DARPA SSITH research programme.
//-

package Core;

// ================================================================
// This package defines:
//     Core_IFC
//     mkCore #(Core_IFC)
//
// mkCore instantiates:
//     - mkCPU (the RISC-V CPU)
//     - mkNear_Mem_IO_AXI4
//     - mkPLIC_16_2_7
//     - mkTV_Encode          (Tandem-Verification logic, optional: INCLUDE_TANDEM_VERIF)
//     - mkDebug_Module       (RISC-V Debug Module, optional: INCLUDE_GDB_CONTROL)
// and connects them all up.

// ================================================================
// BSV library imports

import Vector        :: *;
import FIFOF         :: *;
import GetPut        :: *;
import ClientServer  :: *;
import Connectable   :: *;

// ----------------
// BSV additional libs

import Cur_Cycle  :: *;
import GetPut_Aux :: *;
import Routable   :: *;
import AXI4       :: *;

// ================================================================
// Project imports

// Main fabric
import Fabric_Defs  :: *;    // for Wd_Id, Wd_Addr, Wd_Data...
import SoC_Map      :: *;

`ifdef INCLUDE_GDB_CONTROL
import Debug_Module     :: *;
`endif

import Core_IFC          :: *;
import CPU_IFC           :: *;
import CPU               :: *;
import Near_Mem_IO_AXI4  :: *;
import PLIC              :: *;
import PLIC_16_2_7       :: *;

`ifdef INCLUDE_TANDEM_VERIF
import TV_Info   :: *;
import TV_Encode :: *;
`endif

// TV_Taps needed when both GDB_CONTROL and TANDEM_VERIF are present
`ifdef INCLUDE_GDB_CONTROL
`ifdef INCLUDE_TANDEM_VERIF
import TV_Taps :: *;
`endif
`endif

// ================================================================
// The Core module

(* synthesize *)
module mkCore (Core_IFC #(N_External_Interrupt_Sources));

   // ================================================================
   // STATE

   // System address map
   SoC_Map_IFC  soc_map  <- mkSoC_Map;

   // The CPU
   CPU_IFC  cpu <- mkCPU;

   // AXI4 shim for the default slave
   let shim <- mkAXI4ShimUGSizedFIFOF4;

   // Near_Mem_IO
   Near_Mem_IO_AXI4_IFC  near_mem_io <- mkNear_Mem_IO_AXI4;

   // PLIC (Platform-Level Interrupt Controller)
   PLIC_IFC_16_2_7  plic <- mkPLIC_16_2_7;

   // Reset requests from SoC and responses to SoC
   // 'Bool' is 'running' state
   FIFOF #(Bool) f_reset_reqs <- mkFIFOF;
   FIFOF #(Bool) f_reset_rsps <- mkFIFOF;

`ifdef INCLUDE_TANDEM_VERIF
   // The TV encoder transforms Trace_Data structures produced by the CPU and DM
   // into encoded byte vectors for transmission to the Tandem Verifier
   TV_Encode_IFC tv_encode <- mkTV_Encode;
`endif

`ifdef INCLUDE_GDB_CONTROL
   // Debug Module
   Debug_Module_IFC  debug_module <- mkDebug_Module;
`endif

   // ================================================================
   // RESET
   // There are two sources of reset requests to the CPU: externally
   // from the SoC and, optionally, the DM.  When both requestors are
   // present (i.e., DM is present), we merge the reset requests into
   // the CPU, and we remember which one was the requestor in
   // f_reset_requestor, so that we know whome to respond to.

   Bit #(1) reset_requestor_dm  = 0;
   Bit #(1) reset_requestor_soc = 1;
`ifdef INCLUDE_GDB_CONTROL
   FIFOF #(Bit #(1)) f_reset_requestor <- mkFIFOF;
`endif

   // Reset-hart0 request from SoC
   rule rl_cpu_hart0_reset_from_soc_start;
      let running <- pop (f_reset_reqs);

      cpu.hart0_server_reset.request.put (running);    // CPU
      near_mem_io.server_reset.request.put (?);        // Near_Mem_IO
      plic.server_reset.request.put (?);               // PLIC

`ifdef INCLUDE_GDB_CONTROL
      // Remember the requestor, so we can respond to it
      f_reset_requestor.enq (reset_requestor_soc);
`endif
      $display ("%0d: Core.rl_cpu_hart0_reset_from_soc_start", cur_cycle);
   endrule

`ifdef INCLUDE_GDB_CONTROL
   // Reset-hart0 from Debug Module
   rule rl_cpu_hart0_reset_from_dm_start;
      let running <- debug_module.hart0_reset_client.request.get;

      cpu.hart0_server_reset.request.put (running);    // CPU
      near_mem_io.server_reset.request.put (?);        // Near_Mem_IO
      plic.server_reset.request.put (?);               // PLIC

      // Remember the requestor, so we can respond to it
      f_reset_requestor.enq (reset_requestor_dm);
      $display ("%0d: Core.rl_cpu_hart0_reset_from_dm_start", cur_cycle);
   endrule
`endif

   rule rl_cpu_hart0_reset_complete;
      let running <- cpu.hart0_server_reset.response.get;      // CPU
      let rsp2    <- near_mem_io.server_reset.response.get;    // Near_Mem_IO
      let rsp3    <- plic.server_reset.response.get;           // PLIC

      near_mem_io.set_addr_map (rangeBase(soc_map.m_near_mem_io_addr_range),
			        rangeTop(soc_map.m_near_mem_io_addr_range));

      plic.set_addr_map (rangeBase(soc_map.m_plic_addr_range),
			 rangeTop(soc_map.m_plic_addr_range));

      Bit #(1) requestor = reset_requestor_soc;
`ifdef INCLUDE_GDB_CONTROL
      requestor <- pop (f_reset_requestor);
      if (requestor == reset_requestor_dm)
	 debug_module.hart0_reset_client.response.put (running);
`endif
      if (requestor == reset_requestor_soc)
	 f_reset_rsps.enq (running);

      $display ("%0d: Core.rl_cpu_hart0_reset_complete", cur_cycle);
   endrule

   // ================================================================
   // Direct DM-to-CPU connections

`ifdef INCLUDE_GDB_CONTROL
   // DM to CPU connections for run-control and other misc requests
   mkConnection (debug_module.hart0_client_run_halt, cpu.hart0_server_run_halt);
   mkConnection (debug_module.hart0_get_other_req,   cpu.hart0_put_other_req);
`endif

   // ================================================================
   // Other CPU/DM/TV connections
   // (depends on whether DM, TV or both are present)

`ifdef INCLUDE_GDB_CONTROL
`ifdef INCLUDE_TANDEM_VERIF
   // BEGIN SECTION: GDB and TV
   // ----------------------------------------------------------------
   // DM and TV both present. We instantiate 'taps' into connections
   // where the DM writes CPU GPRs, CPU FPRs, CPU CSRs, and main memory,
   // in order to produce corresponding writes for the Tandem Verifier.
   // Then, we merge the Trace_Data from these three taps with the
   // Trace_Data produced by the CPU.

   FIFOF #(Trace_Data) f_trace_data_merged <- mkFIFOF;

   // Connect merged trace data to trace encoder
   mkConnection (toGet (f_trace_data_merged), tv_encode.trace_data_in);

   // Merge-in CPU's trace data.
   // This is equivalent to:  mkConnection (cpu.trace_data_out, toPut (f_trace_data_merged))
   // but using a rule allows us to name it in scheduling attributes.
   rule merge_cpu_trace_data;
      let tmp <- cpu.trace_data_out.get;
      f_trace_data_merged.enq (tmp);
   endrule

   // Create a tap for DM's memory-writes to the bus, and merge-in the trace data.
   DM_Mem_Tap_IFC dm_mem_tap <- mkDM_Mem_Tap;
   mkConnection (debug_module.master, dm_mem_tap.slave);
   let dm_master_local = dm_mem_tap.master;

   rule merge_dm_mem_trace_data;
      let tmp <- dm_mem_tap.trace_data_out.get;
      f_trace_data_merged.enq (tmp);
   endrule

   // Create a tap for DM's GPR writes to the CPU, and merge-in the trace data.
   DM_GPR_Tap_IFC  dm_gpr_tap_ifc <- mkDM_GPR_Tap;
   mkConnection (debug_module.hart0_gpr_mem_client, dm_gpr_tap_ifc.server);
   mkConnection (dm_gpr_tap_ifc.client, cpu.hart0_gpr_mem_server);

   rule merge_dm_gpr_trace_data;
      let tmp <- dm_gpr_tap_ifc.trace_data_out.get;
      f_trace_data_merged.enq (tmp);
   endrule

`ifdef ISA_F_OR_D
   // Create a tap for DM's FPR writes to the CPU, and merge-in the trace data.
   DM_FPR_Tap_IFC  dm_fpr_tap_ifc <- mkDM_FPR_Tap;
   mkConnection (debug_module.hart0_fpr_mem_client, dm_fpr_tap_ifc.server);
   mkConnection (dm_fpr_tap_ifc.client, cpu.hart0_fpr_mem_server);

   rule merge_dm_fpr_trace_data;
      let tmp <- dm_fpr_tap_ifc.trace_data_out.get;
      f_trace_data_merged.enq (tmp);
   endrule
`endif
   // for ifdef ISA_F_OR_D

   // Create a tap for DM's CSR writes, and merge-in the trace data.
   DM_CSR_Tap_IFC  dm_csr_tap <- mkDM_CSR_Tap;
   mkConnection(debug_module.hart0_csr_mem_client, dm_csr_tap.server);
   mkConnection(dm_csr_tap.client, cpu.hart0_csr_mem_server);

`ifdef ISA_F_OR_D
   (* descending_urgency = "merge_dm_fpr_trace_data, merge_dm_gpr_trace_data" *)
`endif
   (* descending_urgency = "merge_dm_gpr_trace_data, merge_dm_csr_trace_data" *)
   (* descending_urgency = "merge_dm_csr_trace_data, merge_dm_mem_trace_data" *)
   (* descending_urgency = "merge_dm_mem_trace_data, merge_cpu_trace_data"    *)
   rule merge_dm_csr_trace_data;
      let tmp <- dm_csr_tap.trace_data_out.get;
      f_trace_data_merged.enq(tmp);
   endrule

   // END SECTION: GDB and TV
`else
   // for ifdef INCLUDE_TANDEM_VERIF
   // ----------------------------------------------------------------
   // BEGIN SECTION: GDB and no TV

   // Connect DM's GPR interface directly to CPU
   mkConnection (debug_module.hart0_gpr_mem_client, cpu.hart0_gpr_mem_server);

`ifdef ISA_F_OR_D
   // Connect DM's FPR interface directly to CPU
   mkConnection (debug_module.hart0_fpr_mem_client, cpu.hart0_fpr_mem_server);
`endif

   // Connect DM's CSR interface directly to CPU
   mkConnection (debug_module.hart0_csr_mem_client, cpu.hart0_csr_mem_server);

   // DM's bus master is directly the bus master
   let dm_master_local = debug_module.master;

   // END SECTION: GDB and no TV
`endif
   // for ifdef INCLUDE_TANDEM_VERIF

`else
   // for ifdef INCLUDE_GDB_CONTROL
   // BEGIN SECTION: no GDB

   // No DM, so 'DM bus master' is dummy
   let dm_master_local = culDeSac;

`ifdef INCLUDE_TANDEM_VERIF
   // ----------------------------------------------------------------
   // BEGIN SECTION: no GDB, TV

   // Connect CPU's TV out directly to TV encoder
   mkConnection (cpu.trace_data_out, tv_encode.trace_data_in);
   // END SECTION: no GDB, TV
`endif
`endif
   // for ifdef INCLUDE_GDB_CONTROL

   // ================================================================
   // Connect the local 2x3 fabric

   // Masters on the local 2x3 fabric
   Vector#(Num_Masters_2x3,
           AXI4_Master_Synth #(Wd_MId_2x3, Wd_Addr, Wd_Data,
                               Wd_AW_User, Wd_W_User, Wd_B_User,
                               Wd_AR_User, Wd_R_User))
                               master_vector = newVector;
   master_vector[cpu_dmem_master_num]         = cpu.dmem_master;
   master_vector[debug_module_sba_master_num] = dm_master_local;

   // Slaves on the local 2x3 fabric
   // default slave is forwarded out directly to the Core interface
   Vector#(Num_Slaves_2x3,
           AXI4_Slave_Synth #(Wd_SId_2x3, Wd_Addr, Wd_Data,
                              Wd_AW_User, Wd_W_User, Wd_B_User,
                              Wd_AR_User, Wd_R_User))
                              slave_vector = newVector;
   slave_vector[default_slave_num]     = toAXI4_Slave_Synth(shim.slave);
   slave_vector[near_mem_io_slave_num] = near_mem_io.axi4_slave;
   slave_vector[plic_slave_num]        = plic.axi4_slave;

   function Vector#(Num_Slaves_2x3, Bool) route_2x3 (Bit#(Wd_Addr) addr);
      Vector#(Num_Slaves_2x3, Bool) res = replicate(False);
      if (inRange(soc_map.m_near_mem_io_addr_range, addr))
        res[near_mem_io_slave_num] = True;
      else if (inRange(soc_map.m_plic_addr_range, addr))
        res[plic_slave_num] = True;
      else
        res[default_slave_num] = True;
      return res;
   endfunction

   mkAXI4Bus_Synth (route_2x3, master_vector, slave_vector);

   // ================================================================
   // Connect interrupt lines from near_mem_io and PLIC to CPU

   rule rl_relay_sw_interrupts;    // from Near_Mem_IO (CLINT)
      Bool x <- near_mem_io.get_sw_interrupt_req.get;
      cpu.software_interrupt_req (x);
      // $display ("%0d: Core.rl_relay_sw_interrupts: relaying: %d", cur_cycle, pack (x));
   endrule

   rule rl_relay_timer_interrupts;    // from Near_Mem_IO (CLINT)
      Bool x <- near_mem_io.get_timer_interrupt_req.get;
      cpu.timer_interrupt_req (x);

      // $display ("%0d: Core.rl_relay_timer_interrupts: relaying: %d", cur_cycle, pack (x));
   endrule

   rule rl_relay_external_interrupts;    // from PLIC
      Bool meip = plic.v_targets [0].m_eip;
      cpu.m_external_interrupt_req (meip);

      Bool seip = plic.v_targets [1].m_eip;
      cpu.s_external_interrupt_req (seip);

      // $display ("%0d: Core.rl_relay_external_interrupts: relaying: %d", cur_cycle, pack (x));
   endrule

   // ================================================================
   // INTERFACE

   // ----------------------------------------------------------------
   // Debugging: set core's verbosity

   method Action  set_verbosity (Bit #(4)  verbosity, Bit #(64)  logdelay);
      cpu.set_verbosity (verbosity, logdelay);
   endmethod

   // ----------------------------------------------------------------
   // Soft reset

   interface Server  cpu_reset_server = toGPServer (f_reset_reqs, f_reset_rsps);

   // ----------------------------------------------------------------
   // AXI4 Fabric interfaces

   // IMem to Fabric master interface
   interface cpu_imem_master = cpu.imem_master;

   // DMem to Fabric master interface
   interface cpu_dmem_master = toAXI4_Master_Synth(shim.master);

   // ----------------------------------------------------------------
   // External interrupt sources

   interface core_external_interrupt_sources = plic.v_sources;

   // ----------------------------------------------------------------
   // Non-maskable interrupt request

   method Action nmi_req (Bool set_not_clear);
      cpu.nmi_req (set_not_clear);
   endmethod

   // ----------------------------------------------------------------
   // Optional TV interface

`ifdef INCLUDE_TANDEM_VERIF
   interface Get tv_verifier_info_get;
      method ActionValue #(Info_CPU_to_Verifier) get();
         match { .n, .v } <- tv_encode.tv_vb_out.get;
         return (Info_CPU_to_Verifier { num_bytes: n, vec_bytes: v });
      endmethod
   endinterface
`endif

   // ----------------------------------------------------------------
   // Optional DM interfaces

`ifdef INCLUDE_GDB_CONTROL
   // ----------------
   // DMI (Debug Module Interface) facing remote debugger

   interface DMI  dm_dmi = debug_module.dmi;

   // ----------------
   // Facing Platform

   // Non-Debug-Module Reset (reset all except DM)
   interface Client ndm_reset_client = debug_module.ndm_reset_client;
`endif

endmodule: mkCore

// ================================================================
// 2x3 Fabric for this Core
// Masters: CPU DMem, Debug Module System Bus Access, External access

// ----------------
// Fabric port numbers for masters

Master_Num_2x3  cpu_dmem_master_num         = 0;
Master_Num_2x3  debug_module_sba_master_num = 1;

// ----------------
// Fabric port numbers for slaves

Slave_Num_2x3  default_slave_num     = 0;
Slave_Num_2x3  near_mem_io_slave_num = 1;
Slave_Num_2x3  plic_slave_num        = 2;

// ================================================================

endpackage
