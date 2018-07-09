# Piccolo
RISC-V CPU, simple 3-stage pipeline, for low-end applications (e.g., embedded, IoT)

Piccolo is one of a family of free, open-source RISC-V CPUs created by Bluespec, Inc.

- [Piccolo](https://github.com/bluespec/Piccolo): 3-stage, in-order pipeline
- [Flute](https://github.com/bluespec/Flute): 5-stage, in-order pipeline

Piccolo is intended for low-end applications (Embedded Systems, IoT, microcontrollers, etc.).
The BSV source code is parameterized for

- RV32I or RV64I
- Optional 'M' (integer multiply/divide)
- Optional 'A' (Atomic Memory Ops)
- Optional 'FD' (Single and Double Precision Floating Point (not yet available)
- Privilege U and M
- Optional Privilege S, with Sv32 Virtual Memory for RV32 and Sv39 Virtual Memory for RV64
- AXI4-Lite Fabric interfaces, with optional 32-bit or 64-bit datapaths (independent of RV32/RV64 choice)
- and several other localized options (e.g., serial shifter vs. barrel shifter for Shift instructions)

This repository contains a simple testbench with which you can run RISC-V binaries in simulation by loading standard mem hex files and executing in Bluespec's Bluesim, iVerilog simulation or Verilator simulation.  The testbench contains an AXI4-Lite interconnect fabric that connects the CPU to boot ROM model, a memory model, a timer and a UART for console I/O.

Bluespec also tests all this code regularly on Xilinx FPGAs.

----------------------------------------------------------------
### Source codes

This repository contains two levels of source code: Verilog and BSV.

**Verilog RTL** can be found in `sim_iverilog/Verilog_RTL` or `sim_verilator/Verilog_RTL` (the two are equivalent).  This is _synthesizable_ RTL (and hence acceptable to Verilator).  It can be simulated in any Verilog simulator (we provide Makefiles to build for iverilog and Verilator).  The CPU RTL can be used directly in other Verilog designs.

**Bluespec BSV** source code can be found in:
- for the CPU core in `src_Core/`, with sub-directories `ISA/`,
    `Core/`, and `RegFiles/` for the CPU itself and `Near_Mem_VM` for
    the MMUs and caches.
- for the testbench in `src_Testbench`, with various sub-directories.

The BSV source code has a rich set of parameters, mentioned above. The provided RTL source has been generated from the BSV source automatically using Bluespec's `bsc` compiler, with one particular set of choices for the various parameters.  The generated RTL is not parameterized.

To generate variants with other parameter choices, the user will need Bluespec's `bsc` compiler.  In fact Piccolo can also support a standard RISC-V Debug Module, and a "Tandem Verifier" to check it for correctness on an instruction-by-instruction basis.  Please contact Bluespec, Inc. if you are interested in such variants.

----------------------------------------------------------------
### What you can build and run, out of the box

- In the `sim_iverilog/` or `sim_verilator/` directories:
  - `$ make mkSim` will create a Verilog simulation executable using iverilog or Verilator, respectively

  - `$ make test` will run the executable on the standard RISC-V ISA test `rv32ui-p-add`, which is one of the tests in the
        `Tests/isa/` directory.  It runs the program `Tests/elf_to_hex/elf_to_hex` on the `rv32ui-p-add` ELF file
        to create a `Mem.hex` file which is loaded into the "memory model" of the executable.
        In the same way, you can run the test on any of the other tests in the `Tests/isa/` directory.

- If you have access to Bluespec's `bsc` compiler, you can also do the following:
  - In the `sim_Bluesim/` directory, `$ make compile link` will compile and link a Bluesim executable,
      and `$ make test` will run it on the `rv32ui-p-add` test.

  - In the `sim_iverilog/` or `sim_verilator/` directories, `$ make gen_RTL` will compile the BSV sources into fresh RTL.

#### Tool dependencies:

We build with the following versions of iVerilog and Verilator.  Later versions are probably ok; we have observed some problems with earlier versions.

        $ iverilog -v
        Icarus Verilog version 10.1 (stable) ()

        $ verilator --version
        Verilator 3.922 2018-03-17 rev verilator_3_920-32-gdf3d1a4

----------------------------------------------------------------
