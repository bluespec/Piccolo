Copyright (c) 2018 Bluespec, Inc. All Rights Reserved

With the Makefile in this directory you can run a regression on all the standard RISC-V ISA tests.

At the top of the Makefile, SIM_EXE_FILE is defined to point at one of
three simulators (Bluesim, Verilator or IVerilog).

'make test1' will run a single test (TEST), pre-defined to be rv32ui-p-add
'make test1_v1' will run it with verbosity 1 (shows an instruction trace)
'make test1_v2' will run it with verbosity 2 (also shows pipeline state)

'make rv32-all' will run all tests in the following collections:
    rv32ui-p-*    (RV32I base)
    rv32um-p-*    (RV32I + 'M' extension)
    rv32mi-p-*    (RV32I + Machine Privilege)

The Makefile defines many more groups of tests (see the Makefile); if
you build a CPU simulator that has more features (e.g., 'A', RV64,
Privilege S) you can also execute the corresponding groups of tests.
If you execute ISA tests for a feature outside what you've built into
Piccolo, it will likely get stuck in an illegal-instruction loop.
