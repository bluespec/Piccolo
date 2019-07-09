// Copyright (c) 2013-2019 Bluespec, Inc. All Rights Reserved

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

package SoC_Map;

// ================================================================
// This module defines the overall 'address map' of the SoC, showing
// the addresses serviced by each slave IP, and which addresses are
// memory vs. I/O.

// ***** WARNING! WARNING! WARNING! *****

// During system integration, this address map should be identical to
// the system interconnect settings (e.g., routing of requests between
// masters and slaves).  This map is also needed by software so that
// it knows how to address various IPs.

// This module contains no state; it just has constants, and so can be
// freely instantiated at multiple places in the SoC module hierarchy
// at no hardware cost.  It allows this map to be defined in one
// place and shared across the SoC.

// ================================================================
// This version of SoC_Map is for the DARPA SSITH GFE

// Our "Near_Mem_IO" corresponds to "CLINT" in Rocket

// ================================================================
// Exports

export  SoC_Map_IFC (..), mkSoC_Map;

export  N_External_Interrupt_Sources;
export  n_external_interrupt_sources;
export  irq_num_uart16550_0;

// ================================================================
// Bluespec library imports

import Routable :: *;

// ================================================================
// Project imports

import Fabric_Defs :: *;    // Only for type Fabric_Addr

// ================================================================

function Bool addr_function(Fabric_Addr base, Fabric_Addr size, Fabric_Addr addr);
   return (base <= addr) && (addr < (base + size));
endfunction

// ================================================================
// Interface and module for the address map

interface SoC_Map_IFC;
   (* always_ready *)   method  Range#(Wd_Addr)  m_plic_addr_range;
   (* always_ready *)   method  Range#(Wd_Addr)  m_near_mem_io_addr_range;

   /* REMOVED?
   (* always_ready *)   method  Fabric_Addr  m_pcie_ecam_slave_bridge_addr_base;
   (* always_ready *)   method  Fabric_Addr  m_pcie_ecam_slave_bridge_addr_size;
   (* always_ready *)   method  Fabric_Addr  m_pcie_ecam_slave_bridge_addr_lim;
   */

   (* always_ready *)   method  Range#(Wd_Addr)  m_flash_mem_addr_range;

   /* REMOVED?
   (* always_ready *)   method  Fabric_Addr  m_pcie_block_registers_addr_base;
   (* always_ready *)   method  Fabric_Addr  m_pcie_block_registers_addr_size;
   (* always_ready *)   method  Fabric_Addr  m_pcie_block_registers_addr_lim;
   */

   (* always_ready *)   method  Range#(Wd_Addr)  m_ethernet_0_addr_range;
   (* always_ready *)   method  Range#(Wd_Addr)  m_dma_0_addr_range;
   (* always_ready *)   method  Range#(Wd_Addr)  m_uart16550_0_addr_range;
   (* always_ready *)   method  Range#(Wd_Addr)  m_gpio_0_addr_range;
   (* always_ready *)   method  Range#(Wd_Addr)  m_boot_rom_addr_range;
   (* always_ready *)   method  Range#(Wd_Addr)  m_ddr4_0_uncached_addr_range;
   (* always_ready *)   method  Range#(Wd_Addr)  m_ddr4_0_cached_addr_range;

   (* always_ready *)
   method  Bool  m_is_mem_addr (Fabric_Addr addr);

   (* always_ready *)
   method  Bool  m_is_IO_addr (Fabric_Addr addr);

   (* always_ready *)
   method  Bool  m_is_near_mem_IO_addr (Fabric_Addr addr);

   (* always_ready *)   method  Bit #(64)  m_pc_reset_value;
   (* always_ready *)   method  Bit #(64)  m_mtvec_reset_value;
   (* always_ready *)   method  Bit #(64)  m_nmivec_reset_value;
endinterface

// ================================================================

(* synthesize *)
module mkSoC_Map (SoC_Map_IFC);

   // ----------------------------------------------------------------
   // PLIC

   let plic_addr_range = Range {
      base: 'h_0C00_0000,
      size: 'h_0040_0000    // 4M
   };

   // ----------------------------------------------------------------
   // Near_Mem_IO (CLINT)

   let near_mem_io_addr_range = Range {
      base: 'h_1000_0000,
      size: 'h_0001_0000    // 64K
   };

   // ----------------------------------------------------------------
   // PCIE_ECAM_SLAVE_BRIDGE

   /* REMOVED?
   Fabric_Addr pcie_ecam_slave_bridge_addr_base = 'h_2000_0000;
   Fabric_Addr pcie_ecam_slave_bridge_addr_size = 'h_2000_0000;    // 512M
   Fabric_Addr pcie_ecam_slave_bridge_addr_lim  = (  pcie_ecam_slave_bridge_addr_base
						   + pcie_ecam_slave_bridge_addr_size);

   function Bool fn_is_pcie_ecam_slave_bridge_addr (Fabric_Addr addr);
      return ((pcie_ecam_slave_bridge_addr_base <= addr) && (addr < pcie_ecam_slave_bridge_addr_lim));
   endfunction
   */

   // ----------------------------------------------------------------
   // Flash Mem

   let flash_mem_addr_range = Range {
      base: 'h_4000_0000,
      size: 'h_0800_0000    // 128M
   };

   // ----------------------------------------------------------------
   // PCIe Block Registers

   /* REMOVED?
   Fabric_Addr pcie_block_registers_addr_base = 'h_6000_0000;
   Fabric_Addr pcie_block_registers_addr_size = 'h_0001_0000;    // 64K
   Fabric_Addr pcie_block_registers_addr_lim  = ( pcie_block_registers_addr_base
						 + pcie_block_registers_addr_size);

   function Bool fn_is_pcie_block_registers_addr (Fabric_Addr addr);
      return ((pcie_block_registers_addr_base <= addr) && (addr < pcie_block_registers_addr_lim));
   endfunction
   */

   // ----------------------------------------------------------------
   // Ethernet 0

   let ethernet_0_addr_range = Range {
      base: 'h_6210_0000,
      size: 'h_0004_0000    // 256K
   };

   // ----------------------------------------------------------------
   // DMA 0

   let dma_0_addr_range = Range {
      base: 'h_6220_0000,
      size: 'h_0001_0000    // 64K
   };

   // ----------------------------------------------------------------
   // UART 0

   let uart16550_0_addr_range = Range {
      base: 'h_6230_0000,
      size: 'h_0000_1000    // 4K
   };

   // ----------------------------------------------------------------
   // GPIO 0

   let gpio_0_addr_range = Range {
      base: 'h_6FFF_0000,
      size: 'h_0001_0000    // 64K
   };

   // ----------------------------------------------------------------
   // Boot ROM

   let boot_rom_addr_range = Range {
      base: 'h_7000_0000,
      size: 'h_0000_1000    // 4K
   };

   // ----------------------------------------------------------------
   // DDR memory 0 uncached

   let ddr4_0_uncached_addr_range = Range {
      base: 'h_8000_0000,
      size: 'h_4000_0000    // 1G
   };

   // ----------------------------------------------------------------
   // DDR memory 0 cached

   let ddr4_0_cached_addr_range = Range {
      base: 'h_C000_0000,
      size: 'h_4000_0000    // 1G
   };

   // ----------------------------------------------------------------

   let flash_addr_range = Range{base: 'h6240_0000, size: 'h1000};
   let uart1_addr_range = Range{base: 'h6230_0000, size: 'h1000};
   let i2c_addr_range = Range{base: 'h6231_0000, size: 'h1000};
   let spi_addr_range = Range{base: 'h6232_0000, size: 'h1000};
   let uart2_addr_range = Range{base: 'h6236_0000, size: 'h1000};
   let gpio1_addr_range = Range{base: 'h6233_0000, size: 'h1000};
   let gpio2_addr_range = Range{base: 'h6237_0000, size: 'h1000};

   // ----------------------------------------------------------------
   // Memory address predicate
   // Identifies memory addresses in the Fabric.
   // (Caches needs this information to cache these addresses.)

   function Bool fn_is_mem_addr (Fabric_Addr addr);
      return inRange (ddr4_0_cached_addr_range, addr);
   endfunction

   // ----------------------------------------------------------------
   // I/O address predicate
   // Identifies I/O addresses in the Fabric.
   // (Caches needs this information to avoid cacheing these addresses.)

   function Bool fn_is_IO_addr (Fabric_Addr addr);
      return (   inRange (plic_addr_range, addr)
	      || inRange (near_mem_io_addr_range, addr)
	   // || fn_is_pcie_ecam_slave_bridge_addr (addr)
	      || inRange (flash_mem_addr_range, addr)
	   // || fn_is_pcie_block_registers_addr (addr)
	      || inRange (ethernet_0_addr_range, addr)
	      || inRange (dma_0_addr_range, addr)
	      || inRange (uart16550_0_addr_range, addr)
	      || inRange (gpio_0_addr_range, addr)
	      || inRange (boot_rom_addr_range, addr)
	      || inRange (ddr4_0_uncached_addr_range, addr)
              || inRange (flash_addr_range, addr)
              || inRange (uart1_addr_range, addr)
              || inRange (i2c_addr_range, addr)
              || inRange (spi_addr_range, addr)
              || inRange (uart2_addr_range, addr)
              || inRange (gpio1_addr_range, addr)
              || inRange (gpio2_addr_range, addr)
             );
   endfunction

   // ----------------------------------------------------------------
   // PC, MTVEC and NMIVEC reset values

   Bit #(64) pc_reset_value     = rangeBase(boot_rom_addr_range);
   Bit #(64) mtvec_reset_value  = 'h1000;    // TODO
   Bit #(64) nmivec_reset_value = ?;         // TODO

   // ================================================================
   // INTERFACE

   method  Range#(Wd_Addr)  m_plic_addr_range = plic_addr_range;
   method  Range#(Wd_Addr)  m_near_mem_io_addr_range = near_mem_io_addr_range;

   /* REMOVED?
   method  Fabric_Addr  m_pcie_ecam_slave_bridge_addr_base = pcie_ecam_slave_bridge_addr_base;
   method  Fabric_Addr  m_pcie_ecam_slave_bridge_addr_size = pcie_ecam_slave_bridge_addr_size;
   method  Fabric_Addr  m_pcie_ecam_slave_bridge_addr_lim  = pcie_ecam_slave_bridge_addr_lim;
   */

   method  Range#(Wd_Addr)  m_flash_mem_addr_range = flash_mem_addr_range;

   /* REMOVED?
   method  Fabric_Addr  m_pcie_block_registers_addr_base = pcie_block_registers_addr_base;
   method  Fabric_Addr  m_pcie_block_registers_addr_size = pcie_block_registers_addr_size;
   method  Fabric_Addr  m_pcie_block_registers_addr_lim  = pcie_block_registers_addr_lim;
   */

   method  Range#(Wd_Addr)  m_ethernet_0_addr_range      = ethernet_0_addr_range;
   method  Range#(Wd_Addr)  m_dma_0_addr_range           = dma_0_addr_range;
   method  Range#(Wd_Addr)  m_uart16550_0_addr_range     = uart16550_0_addr_range;
   method  Range#(Wd_Addr)  m_gpio_0_addr_range          = gpio_0_addr_range;
   method  Range#(Wd_Addr)  m_boot_rom_addr_range        = boot_rom_addr_range;
   method  Range#(Wd_Addr)  m_ddr4_0_uncached_addr_range = ddr4_0_uncached_addr_range;
   method  Range#(Wd_Addr)  m_ddr4_0_cached_addr_range   = ddr4_0_cached_addr_range;

   method  Bool  m_is_mem_addr (Fabric_Addr addr) = fn_is_mem_addr (addr);

   method  Bool  m_is_IO_addr (Fabric_Addr addr) = fn_is_IO_addr (addr);

   method  Bool  m_is_near_mem_IO_addr (Fabric_Addr addr) = inRange(near_mem_io_addr_range, addr);

   method  Bit #(64)  m_pc_reset_value     = pc_reset_value;
   method  Bit #(64)  m_mtvec_reset_value  = mtvec_reset_value;
   method  Bit #(64)  m_nmivec_reset_value = nmivec_reset_value;
endmodule

// ================================================================
// Interrupt request numbers (== index in to vector of
// interrupt-request lines in Core)

typedef  16  N_External_Interrupt_Sources;
Integer  n_external_interrupt_sources = valueOf (N_External_Interrupt_Sources);

Integer irq_num_uart16550_0 = 0;

// ================================================================

endpackage
