###  -*-Makefile-*-

# Copyright (c) 2018 Bluespec, Inc. All Rights Reserved

# ================================================================

.PHONY: help
help:
	@echo '    make  compile        Recompile Core (CPU, caches)'
	@echo '    make  link           Link bsc-compiled objects into Bluesim executable'
	@echo '    make  all            Both'

.PHONY: all
all: compile  link

# ================================================================
# Compiling the system

# ----------------
# Search path for bsc for .bsv files

CORE_DIRS = ../src_Core/ISA:../src_Core/RegFiles:../src_Core/Core:../src_Core/Near_Mem_VM:../src_Core/BSV_Additional_Libs
TESTBENCH_DIRS  = ../src_Testbench/Top:../src_Testbench/SoC:../src_Testbench/Fabrics/AXI4_Lite
BSC_PATH = -p $(CORE_DIRS):$(TESTBENCH_DIRS):+

# ----------------
# Top-level file and module

TOPFILE   = ../src_Testbench/Top/Top_HW_Side.bsv
TOPMODULE = mkTop_HW_Side

#----------------
# bsc flags

BSC_FLAGS += -keep-fires -aggressive-conditions -no-warn-action-shadowing \
		-suppress-warnings G0020 \
		-D RV32 \
		-D FABRIC64 \
		-D ISA_PRIV_M \
		-D ISA_PRIV_U \
		-D ISA_M \
		-D Near_Mem_Caches \
		-D SHIFT_BARREL \
		-D CSR_REGFILE_UM \
		+RTS -K64M -RTS  -show-range-conflict

# ================================================================
# Make targets

TMP_DIRS  = -bdir build  -simdir build  -info-dir build

.PHONY: compile
compile:
	@echo "INFO: Re-compiling Core (CPU, Caches)"
	mkdir -p  build
	bsc -u -elab -sim  $(TMP_DIRS)  $(BSC_FLAGS)  $(BSC_PATH)  $(TOPFILE)
	@echo "INFO: Re-compiled  Core (CPU, Caches)"

BSIM_EXE_FILE = exe_HW_bsim

BSC_C_FLAGS += \
	-Xc++  -D_GLIBCXX_USE_CXX11_ABI=0 \
	-Xl -v \
	-Xc -O3 -Xc++ -O3 \

.PHONY: link
link:
	@echo "INFO: linking bsc-compiled objects into Bluesim executable"
	bsc -sim -parallel-sim-link 8 \
		$(TMP_DIRS) \
		-e $(TOPMODULE) -o ./$(BSIM_EXE_FILE) \
		$(BSC_C_FLAGS)
	@echo "INFO: linked bsc-compiled objects into Bluesim executable"

# ================================================================
# Test: run the iverilog executable on the standard 'add' RISCV ISA test

.PHONY: test
test:
	ln -f -s  ../Tests/isa/rv32ui-p-add.hex  Mem.hex
	./$(BSIM_EXE_FILE)  -m 2500  +v1

# ================================================================

.PHONY: clean
clean:
	rm -r -f  *~  build

.PHONY: full_clean
full_clean: clean
	rm -r -f  *~  $(BSIM_EXE_FILE)*  *.log  *.vcd  *.hex

# ================================================================
