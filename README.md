# Piccolo
RISC-V CPU, simple 3-stage pipeline, for low-end applications (e.g., embedded, IoT)

Piccolo is one of a family of free, open-source RISC-V CPUs created by Bluespec, Inc.

- [Piccolo](https://github.com/bluespec/Piccolo): 3-stage, in-order pipeline
- [Flute](https://github.com/bluespec/Flute): 5-stage, in-order pipeline

Piccolo is intended for low-end applications (Embedded Systems, IoT, microcontrollers, etc.).
The BSV source code is parameterized for

The pre-generated Verilog source files in this repository are for a specific configuration:

- RV32I with 'M' extension (integer multiply/divide)
- Privilege levels M (machine) and U (user)
- Supports external, timer and software interrupts

The BSV source code in this repository, from which the Verilog is
generated, is highly parameterized to allow many more configurations,
rich enough to boot a Linux kernel.  One will need a Bluespec `bsc`
compiler to generate these other variants [Note: Bluespec,
Inc. provides free licenses to academia and for non-profit research].
The BSV source code supports:

- RV32I or RV64I
- Optional serial shifter (smaller hardware, slower) or barrel shifter (more HW, faster) for shift instructions
- Optional 'M' (integer multiply/divide)
- Optional 'A' (Atomic Memory Ops)
- Privilege M (machine), S (supervisor) and U (user)
- For privilege S, MMUs for Sv32 Virtual Memory for RV32 and Sv39 Virtual Memory for RV64
- AXI4-Lite Fabric interfaces, with optional 32-bit or 64-bit datapaths (independent of RV32/RV64 choice)
- and several other localized options

This repository contains a simple testbench with which one can run
RISC-V binaries in simulation by loading standard mem hex files and
executing in Bluespec's Bluesim, Verilator simulation or iVerilog
simulation.  The testbench contains an AXI4-Lite interconnect fabric
that connects the CPU to boot ROM model, a memory model, a timer and a
UART for console I/O [Note: UART input not currently available in
iverilog build].

This repository contains three sample build directories, to build a
Bluespe Bluesim simulation, a Verilator Verilog simulation, and an
Icarus Verilog ("iverilog") simulation.

Bluespec also tests all this code regularly on Xilinx FPGAs.

#### Plans

- We will be adding the RISC-V 'C' option (compressed instructions). [Expected August 2018]
- We will be adding the RISC-V 'F' and 'D' options (single and double precision floating point). [Expected August 2018]
- Continuous micro-architectural improvements for performance and hardware area. [Ongoing]

----------------------------------------------------------------
## Source codes

This repository contains two levels of source code: Verilog and BSV.

**Verilog RTL** can be found in `sim_verilator/Verilog_RTL` and
  `sim_iverilog/Verilog_RTL`.  This is _synthesizable_ RTL (and hence
  acceptable to Verilator).  It can be simulated in any Verilog
  simulator (we provide Makefiles to build for Verilator and for
  Icarus Verilog (iverilog)).

The RTL represents RISC-V CPU RTL, plus a rudimentary surrounding SoC
enabling immediate simulation here, and which is rich enough to enable
booting a Linux kernel.  Users are free to use the CPU RTL in their
own Verilog system designs.  The top-level module for the CPU RTL is
`Verilog_RTL/mkBRVF_Core.v`.  The top-level module for the surrounding
SoC is `Verilog_RTL/mkTop_HW_Side.v`.  The SoC has an AXI4-Lite
fabric, a timer, a software-interrupt device, and a UART.  Additional
library RTL can be found in the directory `src_bsc_lib_RTL`.

**Bluespec BSV** source code can be found in:

- `src_Core/`, for the CPU core, with sub-directories:
   - `ISA/`:  generic types/constants/functions for the RISC-V ISA (not Piccolo-specific)
   - `RegFiles/`: generic register files for the GPRs (General-Purpose Registers) and CSRs (Control and Status Registers)
   - `Core/`: the Piccolo Core
   - `Near_Mem_VM/`: for the MMU and first-level cache.  In Piccolo,
        this is instantiated twice to provide completely separate
        channels (MMU and Cache) for instructions and data.
   - `BSV_Additional_Libs/`: generic utilities (not Piccolo-specific)

- `src_Testbench/`, for the surrounding testbench, with sub-directories:

   - `Top/`: The system top-level (`Top_HW_Side.bsv`), a memory model
       that loads from a memory hex file, and some imported C
       functions for polled reads from the console tty (not currently
       available for Icarus Verilog).

   - `SoC/`: An interconnect, a boot ROM, a memory controller, a timer
       and software-interrupt device, and a UART for console tty I/O.

   - `Fabrics/`: Generic AXI4-Lite code for the SoC fabric.

The BSV source code has a rich set of parameters, mentioned above. The
provided RTL source has been generated from the BSV source
automatically using Bluespec's `bsc` compiler, with one particular set
of choices for the various parameters.  The generated RTL is not
parameterized.

To generate Verilog variants with other parameter choices, the user will need Bluespec's `bsc` compiler.

In fact Piccolo can also support a standard RISC-V Debug Module, and a
"Tandem Verifier" to check it for correctness on an
instruction-by-instruction basis.  Please contact Bluespec, Inc. if
you are interested in such variants.

----------------------------------------------------------------
### Building and running, out of the box

- In the `sim_verilator/` or `sim_iverilog/` directories:
  - `$ make mkSim` will create a Verilog simulation executable using Verilator or iverilog, respectively

  - `$ make test` will run the executable on the standard RISC-V ISA
        test `rv32ui-p-add`, which is one of the tests in the
        `Tests/isa/` directory.  Examining the `test:` target in
        `Makefile`, we see that it first runs the program
        `Tests/elf_to_hex/elf_to_hex` on the `rv32ui-p-add` ELF file
        to create a `Mem.hex` file, and then runs the simulation
        executable which loads this `Mem.hex` file into its memory.

  - Following the pattern of `$ make test`, the user can run any of
    the other tests in the `Tests/isa/` directory by pointing at the
    chosen ELF file.  Note: the pre-generated Verilog will only
    successfully run ELF files compiled for RV32IM, privilege U and M;
    running it on any other ELF file will result in illegal
    instruction traps.

#### Tool dependencies:

We build with the following versions of iVerilog and Verilator.  Later
versions are probably ok; we have observed some problems with earlier
versions of both tools.

        $ iverilog -v
        Icarus Verilog version 10.1 (stable) ()

        $ verilator --version
        Verilator 3.922 2018-03-17 rev verilator_3_920-32-gdf3d1a4

----------------------------------------------------------------
### What you can build and run if you have Bluespec's `bsc` compiler

[Note: Bluespec, Inc. provides free licenses to academia and for non-profit research].

  - `$ cd sim_Bluesim`
  - `$ make compile link`

will compile and link a Bluesim executable.  Then,

  - `$ make test`

will run it on the `rv32ui-p-add` test.  This is one of the tests in
the `Tests/isa/` directory.  Examining the `test:` target in
`Makefile`, we see that it first runs the program
`Tests/elf_to_hex/elf_to_hex` on the `rv32ui-p-add` ELF file to create
a `Mem.hex` file, and then runs the simulation executable which loads
this `Mem.hex` file into its memory.

Following the pattern of `$ make test`, the user can run any of the
other tests in the `Tests/isa/` directory by pointing at the chosen
ELF file.  Note: the pre-generated Verilog will only successfully run
ELF files compiled for RV32IM, privilege U and M; running it on any
other ELF file will result in illegal instruction traps.

You can also regenerate the Verilog RTL in the `sim_verilator/` or `sim_iverilog/` directories:

  - `$ cd  sim_verilator`    or    `$ cd  sim_verilator`
  - `$ make gen_RTL`

In the `sim_Bluesim/`, `sim_verilator/` and `sim_iverilog/`
directories, you can edit the Makefile to pass different flags and
macros to `bsc` which will generate different variants of Piccolo as
described above (RV32I/64I, with/without M, with/without A,
with/without privilege S and MMUs, etc.)

A version generated for RV64IMA, privileges M,S,U and Sv39 virtual
memory has successfully booted the Linux kernel.

----------------------------------------------------------------
