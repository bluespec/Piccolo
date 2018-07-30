###  -*-Makefile-*-

# Copyright (c) 2018 Bluespec, Inc. All Rights Reserved

# ================================================================

.PHONY: help
help:
	@echo '    make  gen_RTL        Recompile Core (CPU, caches) into Verilog RTL (needs Bluespec bsc compiler)'
	@echo '    make  mkSim          Compiles and links Verilog files into an iverilog executable'
	@echo '    make  all            = make gen_RTL mkSim'
	@echo '    make  test           Run the executable on the standard RISC-V ISA test "rv32ui-p-add"'

.PHONY: all
all: gen_RTL  mkSim

# ================================================================
# Generate Verilog RTL from BSV sources (needs Bluespec 'bsc' compiler)

# ----------------
# Search path for bsc for .bsv files

REPO=..

CORE_DIRS = $(REPO)/src_Core/ISA:$(REPO)/src_Core/RegFiles:$(REPO)/src_Core/Core:$(REPO)/src_Core/Near_Mem_VM:$(REPO)/src_Core/BSV_Additional_Libs
TESTBENCH_DIRS  = $(REPO)/src_Testbench/Top:$(REPO)/src_Testbench/SoC:$(REPO)/src_Testbench/Fabrics/AXI4_Lite
BSC_PATH = -p $(CORE_DIRS):$(TESTBENCH_DIRS):+

# ----------------
# Top-level file and module

TOPFILE   = $(REPO)/src_Testbench/Top/Top_HW_Side.bsv
TOPMODULE = mkTop_HW_Side

#----------------
# bsc flags

BSC_FLAGS += -keep-fires -aggressive-conditions -no-warn-action-shadowing \
		-suppress-warnings G0020 \
		-D RV32 \
		-D SHIFT_BARREL \
		-D CSR_REGFILE_UM \
		-D ISA_PRIV_M \
		-D ISA_PRIV_U \
		-D ISA_M \
		-D Near_Mem_Caches \
		-D FABRIC64 \
		+RTS -K64M -RTS  -show-range-conflict

RTL_GEN_DIRS = -vdir Verilog_RTL  -bdir build  -info-dir build

build:
	mkdir -p $@

.PHONY: gen_RTL
gen_RTL:  build
	@echo  "INFO: Verilog RTL generation ..."
	bsc -u -elab -verilog  $(RTL_GEN_DIRS)  -D IVERILOG $(BSC_FLAGS)  $(BSC_PATH)  $(TOPFILE)
	@echo  "INFO: Verilog RTL generation finished"

# ================================================================
# Compile and link Verilog RTL sources into an iverilog executable

SIM_EXE_FILE = exe_HW_sim

.PHONY: mkSim
mkSim:
	@echo INFO: iVerilog linking start ...
	iverilog  -o ./$(SIM_EXE_FILE) \
		-y  Verilog_RTL \
		-y  $(REPO)/src_bsc_lib_RTL \
		-DTOP=$(TOPMODULE) \
		$(REPO)/src_bsc_lib_RTL/main.v
	@echo INFO: iVerilog linking finished

# ================================================================
# Test: run the executable on the standard 'add' RISCV ISA test

.PHONY: test
test:
	make -C  $(REPO)/Tests/elf_to_hex
	$(REPO)/Tests/elf_to_hex/elf_to_hex  $(REPO)/Tests/isa/rv32ui-p-add  Mem.hex
	./$(SIM_EXE_FILE)  +v1  +tohost

# ================================================================

.PHONY: clean
clean:
	rm -r -f  *~  build

.PHONY: full_clean
full_clean: clean
	rm -r -f  *~  $(SIM_EXE_FILE)*  *.log  *.vcd  *.hex

# ================================================================
