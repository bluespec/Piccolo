###  -*-Makefile-*-

# Copyright (c) 2018-2019 Bluespec, Inc. All Rights Reserved

# This file is not a standalone Makefile, but 'include'd by 'Makefile' in the sub-directories

TESTS_DIR ?= $(REPO)/Tests

# ================================================================
# Test: run the executable on the standard RISCV ISA test specified in TEST

VERBOSITY ?= +v1

.PHONY: test
test:
	make -C  $(TESTS_DIR)/elf_to_hex
	$(TESTS_DIR)/elf_to_hex/elf_to_hex  $(TESTS_DIR)/isa/$(TEST)  Mem.hex
	./exe_HW_sim  $(VERBOSITY)  +tohost

# ================================================================
# ISA Regression testing

.PHONY: isa_tests
isa_tests:
	@echo "Running regressions on ISA tests; saving logs in Logs/"
	$(REPO)/Tests/Run_regression.py  ./exe_HW_sim  $(REPO)  ./Logs  $(ARCH)
	@echo "Finished running regressions; saved logs in Logs/"

# ================================================================

SHOW_TRACE_DATA_DIR=$(HOME)/Projects/RISCV/git_trace_protocol/Show_Trace_Data

.PHONY: showtrace
showtrace:
	$(SHOW_TRACE_DATA_DIR)/show_trace_data_RV32  trace_out.dat > trace_out.txt
	less  trace_out.txt

# ================================================================

.PHONY: clean
clean:
	rm -r -f  *~  build
	rm -r -f  obj_dir

.PHONY: full_clean
full_clean: clean
	rm -r -f  *~  $(SIM_EXE_FILE)*  *.log  *.vcd  *.hex  Logs/
	rm -r -f  obj_dir

# ================================================================
