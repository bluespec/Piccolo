###  -*-Makefile-*-

# Copyright (c) 2018-2019 Bluespec, Inc. All Rights Reserved

# Build all the "standard" builds and test them
# (simple test only, not full regression)

.PHONY: help
help:
	@echo "    Usage:    make build_all"
	@echo ""
	@echo "    builds all 'standard' builds, i.e., all  combinations of:"
	@echo "            RV32IMU/ RV32ACIMSU/ RV64IMU/ RV64ACIMSU"
	@echo "         X  Bluesim/ iverilog/ verilator"
	@echo ""
	@echo "    (needs Bluespec bsc compiler/Bluesim simulator license)"

.PHONY: build_all
build_all:
	@echo  "Saving build logs in 'build_all.log'"
	logsave build_all.log  make -f Build_all.mk  build_all2
	@echo  "Counting PASS in build_all.log; expecting 12"
	grep  PASS  build_all.log | wc -l

.PHONY: build_all2
build_all2:
	make -C ../RV32IMU_Bluesim        all  test
	make -C ../RV32IMU_iverilog       all  test
	make -C ../RV32IMU_verilator      all  test
	make -C ../RV32ACIMSU_Bluesim     all  test
	make -C ../RV32ACIMSU_iverilog    all  test
	make -C ../RV32ACIMSU_verilator   all  test
	make -C ../RV64IMU_Bluesim        all  test
	make -C ../RV64IMU_iverilog       all  test
	make -C ../RV64IMU_verilator      all  test
	make -C ../RV64ACIMSU_Bluesim     all  test
	make -C ../RV64ACIMSU_iverilog    all  test
	make -C ../RV64ACIMSU_verilator   all  test

.PHONY: full_clean
full_clean:
	make -C ../RV32IMU_Bluesim        full_clean
	make -C ../RV32IMU_iverilog       full_clean
	make -C ../RV32IMU_verilator      full_clean
	make -C ../RV32ACIMSU_Bluesim     full_clean
	make -C ../RV32ACIMSU_iverilog    full_clean
	make -C ../RV32ACIMSU_verilator   full_clean
	make -C ../RV64IMU_Bluesim        full_clean
	make -C ../RV64IMU_iverilog       full_clean
	make -C ../RV64IMU_verilator      full_clean
	make -C ../RV64ACIMSU_Bluesim     full_clean
	make -C ../RV64ACIMSU_iverilog    full_clean
	make -C ../RV64ACIMSU_verilator   full_clean
