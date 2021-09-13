Copyright (c) 2021 Rishiyur S. Nikhil and Bluespec, Inc.

This directory, gdbstub_tcp_tcp, is for a standalone program that can
be used to connect GDB to a Piccolo/Flute/Toooba simulation.

    https://github.com/bluespec/Piccolo
    https://github.com/bluespec/Flute
    https://github.com/bluespec/Toooba

It is a wrapper for the core gdbstub code from the open-source repo:

    https://github.com/bluespec/RISCV_gdbstub

Each of the above systems must be compiled for simulation while giving
command-line argument '-D INCLUDE_GDB_CONTROL' to the 'bsc' compiler.

To use gdbstub_tcp_tcp, we start 3 processes (e.g., in 3 separate
terminal windows), which have the following relationship:

  GDB <------> |exe_gdbstub_tcp_tcp| <------> |Piccolo simulation
         TCP   |port               |    TCP   |port
               |31000              |          |30000

These processes must be started right-to-left, i.e., simulation,
gdbstub, GDB (listening socket before connecting socket).  This can be
scripted using standard Unix facilities.

See Example_run/README.txt for an example run with Piccolo.
