# Piccolo
RISC-V CPU, simple 3-stage pipeline, for low-end applications (e.g., embedded, IoT)

Piccolo is one of a family of free, open-source CPUs created by Bluespec, Inc.
It is intended for low-end applications (Embedded Systems, IoT, microcontrollers, etc.).
Parameterized for
- RV32I or RV64I
- Optional 'M' (integer multiply/divide)
- Optional 'A' (Atomic Memory Ops)
- Optional 'FD' (Single and Double Precision Floating Point (not yet available)
- Privilege U and M
- Optional Privilege S, with Sv32 Virtual Memory for RV32 and Sv39 Virtual Memory for RV64
- AXI4-Lite Fabric interfaces, with optional 32-bit or 64-bit datapaths (independent of RV32/RV64 choice)
- and several other localized options (e.g., serial shifter vs. barrel shifter for Shift instructions)

Repository contains a simple testbench so that you can run RISC-V binaries in simulation by loading standard mem hex files and executing in Bluespec's Bluesim, iVerilog simulation or Verilator simulation.  The testbench contains an AXI4-Lite interconnect fabric that connects the CPU to boot ROM model, a memory model, a timer and a UART for console I/O.

Tested on Xilinx FPGAs

Repository contains:
- Bluespec BSV source code
- Verilog RTL generated from BSV source code by Bluespec's bsc compiler
- Makefile to regenerate RTL (need's a bsc compiler from Bluespec)
- Makefile to compile/link/execute the RTL with iVerilog and Verilator simulators
- Pre-built Mem Hex files for a subset of the standard RISC-V ISA tests
