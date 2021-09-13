# GDB should be path to a GDB that knows about the RISC-V ISA
# E.g, the one you get by cloning and building:
#     https://github.com/riscv/riscv-gnu-toolchain

GDB    ?= ~/git_clones/RISCV_Gnu_Toolchain/installation/bin/riscv64-unknown-elf-gdb

SCRIPT ?= Example_GDB_script.gdb

.PHONY: test
test:
	rm -f  log_gdb_remote.txt  log_gdb.txt
	$(GDB) -x  $(SCRIPT)

.PHONY: clean
clean:
	rm -f  log_gdb_remote.txt  log_gdb.txt
