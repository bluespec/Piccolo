# -*- gdb-script -*-

# ================================================================

set logging file  log_gdb.txt
set logging overwrite
set logging on
show logging

set pagination off

set architecture riscv:rv32
file ../../../Tests/isa/rv32ui-p-add

# ================================================================

# set debug remote 1
# show debug remote

echo Recording interactions with gdbstub in log_gdb_remote.gdb\n
set remotelogfile  log_gdb_remote.txt
show remotelogfile

set remotetimeout 5000
show remotetimeout

echo Connecting gdbstub at port 31000\n
target remote  :31000
echo Connected\n

# ================================================================

echo Loading RISC-V ELF file ../../../Tests/isa/rv32ui-p-add\n
load ../../../Tests/isa/rv32ui-p-add

echo Examine PC (was set as part of ELF-file load)\n
p/x  $pc

echo Partial memory dump (16 words in hex from program memory at 0x_8000_0000)\n
x/16wx  0x80000000

echo Setting breakpoint just after final status is written 'tohost'\n
break  *0x80000048

echo Running the program\n
continue

echo Entering interactive mode.\n
echo We can examine/update PC, registers, memory, ...\n
echo We can run (continue), step instructions (stepi), step C statements (step), ...\n

# ================================================================
