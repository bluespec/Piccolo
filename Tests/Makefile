###  -*-Makefile-*-

# Copyright (c) 2018 Bluespec, Inc. All Rights Reserved

# ================================================================
# Regression: run all ISA tests relevant for the chosen simulator

# ----------------
# Choose an architecture simulator

ARCH ?= RV32IMU
# ARCH ?= RV32AIMU
# ARCH ?= RV64AIMsU

# ----------------
# Choose a simulation engine

SIM ?= Bluesim
# SIM ?= iverilog
# SIM ?= verilator

# ----------------
SIM_DIR = ../builds/$(ARCH)_$(SIM)

# ================================================================

.PHONY: test
test:
	@echo "Running regressions; saving logs in Logs/"
	./Run_regression.py \
		$(SIM_DIR)/exe_HW_sim \
		./isa  ./Logs
	@echo "Finished running regressions; saved logs in Logs/"

# ================================================================

.PHONY: clean
clean:
	rm  *~

.PHONY: full_clean
full_clean:
	rm  -r -f  *~  Logs  *.log
