Example run:

1. In terminal window TERM_SIM
    $ cd  $(PICCOLO)/builds/RV32ACIMU_Piccolo_DM_verilator
    $ ./exe_HW_sim  +v1  +tohost

    Listens on TCP port 30000.
    Can be Bluesim, Verilator sim, IVerilog sim, ...
    +v1 (verbosity 1) is optional: prints instruction trace
    +tohost is optional: monitors 'tohost' address used by ISA tests to indicate PASS/FAIL
        For this to work, you must have a 'symbol_table.txt' file that specifies
	the address of the 'tohost' location.

2. In terminal window TERM_GDBSTUB
    $ cd  $(PICCOLO)/src_Testbench/gdbstub_tcp_tcp
    $ exe_gdbstub_tcp_tcp

    Opens connection to TCP port 30000 (Piccolo simulation).
        In TERM_SIM, simulation starts running in an infinite trap loop.
    Listens on TCP port 31000.

3. In terminal window TERM_GDB
    $ cd  $(PICCOLO)/src_Testbench/gdbstub_tcp_tcp
    $ make -f Example_GDB_start.mk

    This runs GDB with an example script:
        riscv64-unknown-elf-gdb -x  Example_GDB_script.gdb

    The script uses GDB 'remote' command to connect to TCP port 31000,
        (this causes gdbstub to halt the CPU)
    loads an ELF file (ISA test rv32ui-p-add),
    sets a breakpoint,
    runs the program (which runs and stops at breakpoint),
        In TERM_SIM it shows an instruction trace and PASS before the breakpoint
    enters interactive GDB
    where you can read and write PC, GPRs, FPRs, CSRs and memory,
    load another ELF file,
    set another breakpoint,
    run ('continue'), single-step RISC-V instructions ('stepi')
    single-step C statements ('step', etc.),
    etc.

Currently, TCP hostname and port numbers are compiled into the code:
    localhost (127.0.0.1)
    ports 31000 and 30000
We can edit the code and recompile for different hostname/port numbers.
