###  -*-Makefile-*-

# Copyright (c) 2018 Bluespec, Inc. All Rights Reserved

# Makefile to run all the standard RISC-V isa tests, singly or in groups

# SIM_EXE_FILE = ../sim_Bluesim/exe_HW_sim
SIM_EXE_FILE ?= ../sim_verilator/exe_HW_sim
# SIM_EXE_FILE = ../sim_iverilog/exe_HW_sim

ISA_TESTS_DIR = ./isa

# Default single test

TEST ?= rv32ui-p-add

# ================================================================
# Help

.PHONY: help
help:
	@echo  "make  test1       for a single test quietly (verbosity 0)"
	@echo  "make  test1_v1    for a single test with verbosity 1 (+ instruction trace)"
	@echo  "make  test1_v2    for a single test with verbosity 2 (+ pipeline details)"
	@echo  "make  rv32ui-p    to run the group of all base RV32I ISA tests"
	@echo  "                      (see Makefile for many other ISA groups)"
	@echo  "make  rv32-all    to run a collection of rv32 tests (see details in Makefile)"

# ================================================================
# Conversion of ELF file to Mem Hex file

ELF_TO_HEX = ./elf_to_hex/elf_to_hex

# ================================================================
# Run one test quietly, with verbosity 1, with verbosity 2

.PHONY: Mem_hex
Mem_hex:
	rm -f  Mem.hex
	$(ELF_TO_HEX)  $(ISA_TESTS_DIR)/$(TEST)  Mem.hex

.PHONY: test1
test1: Mem_hex
	$(SIM_EXE_FILE)  +tohost

.PHONY: test1_v1
test1_v1: Mem_hex
	$(SIM_EXE_FILE)  +tohost  +v1

.PHONY: test1_v2
test1_v2: Mem_hex
	$(SIM_EXE_FILE)  +tohost  +v2

# ================================================================
# RV32 tests

.PHONY: rv32-all
rv32-all:
	make  rv32ui-p    # Base integer instructions
	make  rv32um-p    # 'M' extension (integer multiply/divide)
	make  rv32mi-p    # Privilege M (machine)
#	make  rv32ua-p    # 'A' extension (atomic mem ops)
#	make  rv32uf-p    # 'F' extension (single precision floating point)
#	make  rv32ud-p    # 'D' extension (double precision floating point)
#	make  rv32uc-p    # 'C' extension (compressed instructions)

#	make  rv32ui-v    # Privilege S (supervisor)
#	make  rv32si-p    # Privilege S (supervisor)
#	make  rv32um-v    # Privilege S (supervisor) + 'M' extension
#	make  rv32ua-v    # Privilege S (supervisor) + 'A' extension
#	make  rv32uf-v    # Privilege S (supervisor) + 'F' extension
#	make  rv32ud-v    # Privilege S (supervisor) + 'D' extension
#	make  rv32uc-v    # Privilege S (supervisor) + 'C' extension

.PHONY: rv32ui-p
rv32ui-p:
	make  TEST=rv32ui-p-add  test1 
	make  TEST=rv32ui-p-addi  test1
	make  TEST=rv32ui-p-and  test1
	make  TEST=rv32ui-p-andi  test1
	make  TEST=rv32ui-p-auipc  test1
	make  TEST=rv32ui-p-beq  test1
	make  TEST=rv32ui-p-bge  test1
	make  TEST=rv32ui-p-bgeu  test1
	make  TEST=rv32ui-p-blt  test1
	make  TEST=rv32ui-p-bltu  test1
	make  TEST=rv32ui-p-bne  test1
	make  TEST=rv32ui-p-fence_i  test1
	make  TEST=rv32ui-p-jal  test1
	make  TEST=rv32ui-p-jalr  test1
	make  TEST=rv32ui-p-lb  test1
	make  TEST=rv32ui-p-lbu  test1
	make  TEST=rv32ui-p-lh  test1
	make  TEST=rv32ui-p-lhu  test1
	make  TEST=rv32ui-p-lui  test1
	make  TEST=rv32ui-p-lw  test1
	make  TEST=rv32ui-p-or  test1
	make  TEST=rv32ui-p-ori  test1
	make  TEST=rv32ui-p-sb  test1
	make  TEST=rv32ui-p-sh  test1
	make  TEST=rv32ui-p-simple  test1
	make  TEST=rv32ui-p-sll  test1
	make  TEST=rv32ui-p-slli  test1
	make  TEST=rv32ui-p-slt  test1
	make  TEST=rv32ui-p-slti  test1
	make  TEST=rv32ui-p-sltiu  test1
	make  TEST=rv32ui-p-sltu  test1
	make  TEST=rv32ui-p-sra  test1
	make  TEST=rv32ui-p-srai  test1
	make  TEST=rv32ui-p-srl  test1
	make  TEST=rv32ui-p-srli  test1
	make  TEST=rv32ui-p-sub  test1
	make  TEST=rv32ui-p-sw  test1
	make  TEST=rv32ui-p-xor  test1
	make  TEST=rv32ui-p-xori  test1
	@echo  "Finished  39  rv32ui-p  tests"

.PHONY: rv32ui-v
rv32ui-v:
	make  TEST=rv32ui-v-add  test1
	make  TEST=rv32ui-v-addi  test1
	make  TEST=rv32ui-v-and  test1
	make  TEST=rv32ui-v-andi  test1
	make  TEST=rv32ui-v-auipc  test1
	make  TEST=rv32ui-v-beq  test1
	make  TEST=rv32ui-v-bge  test1
	make  TEST=rv32ui-v-bgeu  test1
	make  TEST=rv32ui-v-blt  test1
	make  TEST=rv32ui-v-bltu  test1
	make  TEST=rv32ui-v-bne  test1
	make  TEST=rv32ui-v-fence_i  test1
	make  TEST=rv32ui-v-jal  test1
	make  TEST=rv32ui-v-jalr  test1
	make  TEST=rv32ui-v-lb  test1
	make  TEST=rv32ui-v-lbu  test1
	make  TEST=rv32ui-v-lh  test1
	make  TEST=rv32ui-v-lhu  test1
	make  TEST=rv32ui-v-lui  test1
	make  TEST=rv32ui-v-lw  test1
	make  TEST=rv32ui-v-or  test1
	make  TEST=rv32ui-v-ori  test1
	make  TEST=rv32ui-v-sb  test1
	make  TEST=rv32ui-v-sh  test1
	make  TEST=rv32ui-v-simple  test1
	make  TEST=rv32ui-v-sll  test1
	make  TEST=rv32ui-v-slli  test1
	make  TEST=rv32ui-v-slt  test1
	make  TEST=rv32ui-v-slti  test1
	make  TEST=rv32ui-v-sltiu  test1
	make  TEST=rv32ui-v-sltu  test1
	make  TEST=rv32ui-v-sra  test1
	make  TEST=rv32ui-v-srai  test1
	make  TEST=rv32ui-v-srl  test1
	make  TEST=rv32ui-v-srli  test1
	make  TEST=rv32ui-v-sub  test1
	make  TEST=rv32ui-v-sw  test1
	make  TEST=rv32ui-v-xor  test1
	make  TEST=rv32ui-v-xori  test1
	@echo  "Finished  39  rv32ui-v  tests"

.PHONY: rv32um-p
rv32um-p:
	make  TEST=rv32um-p-div  test1
	make  TEST=rv32um-p-divu  test1
	make  TEST=rv32um-p-mul  test1
	make  TEST=rv32um-p-mulh  test1
	make  TEST=rv32um-p-mulhsu  test1
	make  TEST=rv32um-p-mulhu  test1
	make  TEST=rv32um-p-rem  test1
	make  TEST=rv32um-p-remu  test1
	@echo  "Finished  8  rv32um-p  tests"

.PHONY: rv32um-v
rv32um-v:
	make  TEST=rv32um-v-div  test1
	make  TEST=rv32um-v-divu  test1
	make  TEST=rv32um-v-mul  test1
	make  TEST=rv32um-v-mulh  test1
	make  TEST=rv32um-v-mulhsu  test1
	make  TEST=rv32um-v-mulhu  test1
	make  TEST=rv32um-v-rem  test1
	make  TEST=rv32um-v-remu  test1
	@echo  "Finished  8  rv32um-v  tests"

.PHONY: rv32ua-p
rv32ua-p:
	make  TEST=rv32ua-p-amoadd_w  test1
	make  TEST=rv32ua-p-amoand_w  test1
	make  TEST=rv32ua-p-amomaxu_w  test1
	make  TEST=rv32ua-p-amomax_w  test1
	make  TEST=rv32ua-p-amominu_w  test1
	make  TEST=rv32ua-p-amomin_w  test1
	make  TEST=rv32ua-p-amoor_w  test1
	make  TEST=rv32ua-p-amoswap_w  test1
	make  TEST=rv32ua-p-amoxor_w  test1
	make  TEST=rv32ua-p-lrsc  test1
	@echo  "Finished  10  rv32ua-p  tests"

.PHONY: rv32ua-v
rv32ua-v:
	make  TEST=rv32ua-v-amoadd_w  test1
	make  TEST=rv32ua-v-amoand_w  test1
	make  TEST=rv32ua-v-amomaxu_w  test1
	make  TEST=rv32ua-v-amomax_w  test1
	make  TEST=rv32ua-v-amominu_w  test1
	make  TEST=rv32ua-v-amomin_w  test1
	make  TEST=rv32ua-v-amoor_w  test1
	make  TEST=rv32ua-v-amoswap_w  test1
	make  TEST=rv32ua-v-amoxor_w  test1
	make  TEST=rv32ua-v-lrsc  test1
	@echo  "Finished  10  rv32ua-v  tests"

.PHONY: rv32uf-p
rv32uf-p:
	make  TEST=rv32uf-p-fadd  test1
	make  TEST=rv32uf-p-fclass  test1
	make  TEST=rv32uf-p-fcmp  test1
	make  TEST=rv32uf-p-fcvt  test1
	make  TEST=rv32uf-p-fcvt_w  test1
	make  TEST=rv32uf-p-fdiv  test1
	make  TEST=rv32uf-p-fmadd  test1
	make  TEST=rv32uf-p-fmin  test1
	make  TEST=rv32uf-p-ldst  test1
	make  TEST=rv32uf-p-move  test1
	make  TEST=rv32uf-p-recoding  test1
	@echo  "Finished  11  rv32uf-p  tests"

.PHONY: rv32uf-v
rv32uf-v:
	make  TEST=rv32uf-v-fadd  test1
	make  TEST=rv32uf-v-fclass  test1
	make  TEST=rv32uf-v-fcmp  test1
	make  TEST=rv32uf-v-fcvt  test1
	make  TEST=rv32uf-v-fcvt_w  test1
	make  TEST=rv32uf-v-fdiv  test1
	make  TEST=rv32uf-v-fmadd  test1
	make  TEST=rv32uf-v-fmin  test1
	make  TEST=rv32uf-v-ldst  test1
	make  TEST=rv32uf-v-move  test1
	make  TEST=rv32uf-v-recoding  test1
	@echo  "Finished  11  rv32uf-v  tests"

.PHONY: rv32ud-p
rv32ud-p:
	make  TEST=rv32ud-p-fadd  test1
	make  TEST=rv32ud-p-fclass  test1
	make  TEST=rv32ud-p-fcmp  test1
	make  TEST=rv32ud-p-fcvt  test1
	make  TEST=rv32ud-p-fcvt_w  test1
	make  TEST=rv32ud-p-fdiv  test1
	make  TEST=rv32ud-p-fmadd  test1
	make  TEST=rv32ud-p-fmin  test1
	make  TEST=rv32ud-p-ldst  test1
	make  TEST=rv32ud-p-recoding  test1
	@echo  "Finished  10  rv32ud-p  tests"

.PHONY: rv32ud-v
rv32ud-v:
	make  TEST=rv32ud-v-fadd  test1
	make  TEST=rv32ud-v-fclass  test1
	make  TEST=rv32ud-v-fcmp  test1
	make  TEST=rv32ud-v-fcvt  test1
	make  TEST=rv32ud-v-fcvt_w  test1
	make  TEST=rv32ud-v-fdiv  test1
	make  TEST=rv32ud-v-fmadd  test1
	make  TEST=rv32ud-v-fmin  test1
	make  TEST=rv32ud-v-ldst  test1
	make  TEST=rv32ud-v-recoding  test1
	@echo  "Finished  10  rv32ud-v  tests"

.PHONY: rv32uc-p
rv32uc-p:
	make  TEST=rv32uc-p-rvc  test1
	@echo  "Finished  1  rv32uc-p  tests"

.PHONY: rv32uc-v
rv32uc-v:
	make  TEST=rv32uc-v-rvc  test1
	@echo  "Finished  1  rv32uc-v  tests"

.PHONY: rv32mi-p
rv32mi-p:
	make  TEST=rv32mi-p-breakpoint  test1
	make  TEST=rv32mi-p-csr  test1
	make  TEST=rv32mi-p-illegal  test1
	make  TEST=rv32mi-p-ma_addr  test1
	make  TEST=rv32mi-p-ma_fetch  test1
	make  TEST=rv32mi-p-mcsr  test1
	make  TEST=rv32mi-p-sbreak  test1
	make  TEST=rv32mi-p-scall  test1
	make  TEST=rv32mi-p-shamt  test1
	@echo  "Finished  9  rv32mi-p  tests"

.PHONY: rv32si-p
rv32si-p:
	make  TEST=rv32si-p-csr  test1
	make  TEST=rv32si-p-dirty  test1
	make  TEST=rv32si-p-ma_fetch  test1
	make  TEST=rv32si-p-sbreak  test1
	make  TEST=rv32si-p-scall  test1
	make  TEST=rv32si-p-wfi  test1
	@echo  "Finished  6  rv32si-p  tests"

# ================================================================
# RV64 tests

.PHONY: rv64-all
rv64-all:
	make  rv64ui-p
	make  rv64ui-v
	make  rv64um-p
	make  rv64um-v
	make  rv64ua-p
	make  rv64ua-v
#	make  rv64uf-p
#	make  rv64uf-v
#	make  rv64ud-p
#	make  rv64ud-v
#	make  rv64uc-p
#	make  rv64uc-v
	make  rv64mi-p
	make  rv64si-p

.PHONY: rv64ui-p
rv64ui-p:
	make  RV=RV64  TEST=rv64ui-p-add  test1
	make  RV=RV64  TEST=rv64ui-p-addi  test1
	make  RV=RV64  TEST=rv64ui-p-addiw  test1
	make  RV=RV64  TEST=rv64ui-p-addw  test1
	make  RV=RV64  TEST=rv64ui-p-and  test1
	make  RV=RV64  TEST=rv64ui-p-andi  test1
	make  RV=RV64  TEST=rv64ui-p-auipc  test1
	make  RV=RV64  TEST=rv64ui-p-beq  test1
	make  RV=RV64  TEST=rv64ui-p-bge  test1
	make  RV=RV64  TEST=rv64ui-p-bgeu  test1
	make  RV=RV64  TEST=rv64ui-p-blt  test1
	make  RV=RV64  TEST=rv64ui-p-bltu  test1
	make  RV=RV64  TEST=rv64ui-p-bne  test1
	make  RV=RV64  TEST=rv64ui-p-fence_i  test1
	make  RV=RV64  TEST=rv64ui-p-jal  test1
	make  RV=RV64  TEST=rv64ui-p-jalr  test1
	make  RV=RV64  TEST=rv64ui-p-lb  test1
	make  RV=RV64  TEST=rv64ui-p-lbu  test1
	make  RV=RV64  TEST=rv64ui-p-ld  test1
	make  RV=RV64  TEST=rv64ui-p-lh  test1
	make  RV=RV64  TEST=rv64ui-p-lhu  test1
	make  RV=RV64  TEST=rv64ui-p-lui  test1
	make  RV=RV64  TEST=rv64ui-p-lw  test1
	make  RV=RV64  TEST=rv64ui-p-lwu  test1
	make  RV=RV64  TEST=rv64ui-p-or  test1
	make  RV=RV64  TEST=rv64ui-p-ori  test1
	make  RV=RV64  TEST=rv64ui-p-sb  test1
	make  RV=RV64  TEST=rv64ui-p-sd  test1
	make  RV=RV64  TEST=rv64ui-p-sh  test1
	make  RV=RV64  TEST=rv64ui-p-simple  test1
	make  RV=RV64  TEST=rv64ui-p-sll  test1
	make  RV=RV64  TEST=rv64ui-p-slli  test1
	make  RV=RV64  TEST=rv64ui-p-slliw  test1
	make  RV=RV64  TEST=rv64ui-p-sllw  test1
	make  RV=RV64  TEST=rv64ui-p-slt  test1
	make  RV=RV64  TEST=rv64ui-p-slti  test1
	make  RV=RV64  TEST=rv64ui-p-sltiu  test1
	make  RV=RV64  TEST=rv64ui-p-sltu  test1
	make  RV=RV64  TEST=rv64ui-p-sra  test1
	make  RV=RV64  TEST=rv64ui-p-srai  test1
	make  RV=RV64  TEST=rv64ui-p-sraiw  test1
	make  RV=RV64  TEST=rv64ui-p-sraw  test1
	make  RV=RV64  TEST=rv64ui-p-srl  test1
	make  RV=RV64  TEST=rv64ui-p-srli  test1
	make  RV=RV64  TEST=rv64ui-p-srliw  test1
	make  RV=RV64  TEST=rv64ui-p-srlw  test1
	make  RV=RV64  TEST=rv64ui-p-sub  test1
	make  RV=RV64  TEST=rv64ui-p-subw  test1
	make  RV=RV64  TEST=rv64ui-p-sw  test1
	make  RV=RV64  TEST=rv64ui-p-xor  test1
	make  RV=RV64  TEST=rv64ui-p-xori  test1
	@echo  "Finished  51  rv64ui-p  tests"

.PHONY: rv64ui-v
rv64ui-v:
	make  RV=RV64  TEST=rv64ui-v-add  test1
	make  RV=RV64  TEST=rv64ui-v-addi  test1
	make  RV=RV64  TEST=rv64ui-v-addiw  test1
	make  RV=RV64  TEST=rv64ui-v-addw  test1
	make  RV=RV64  TEST=rv64ui-v-and  test1
	make  RV=RV64  TEST=rv64ui-v-andi  test1
	make  RV=RV64  TEST=rv64ui-v-auipc  test1
	make  RV=RV64  TEST=rv64ui-v-beq  test1
	make  RV=RV64  TEST=rv64ui-v-bge  test1
	make  RV=RV64  TEST=rv64ui-v-bgeu  test1
	make  RV=RV64  TEST=rv64ui-v-blt  test1
	make  RV=RV64  TEST=rv64ui-v-bltu  test1
	make  RV=RV64  TEST=rv64ui-v-bne  test1
	make  RV=RV64  TEST=rv64ui-v-fence_i  test1
	make  RV=RV64  TEST=rv64ui-v-jal  test1
	make  RV=RV64  TEST=rv64ui-v-jalr  test1
	make  RV=RV64  TEST=rv64ui-v-lb  test1
	make  RV=RV64  TEST=rv64ui-v-lbu  test1
	make  RV=RV64  TEST=rv64ui-v-ld  test1
	make  RV=RV64  TEST=rv64ui-v-lh  test1
	make  RV=RV64  TEST=rv64ui-v-lhu  test1
	make  RV=RV64  TEST=rv64ui-v-lui  test1
	make  RV=RV64  TEST=rv64ui-v-lw  test1
	make  RV=RV64  TEST=rv64ui-v-lwu  test1
	make  RV=RV64  TEST=rv64ui-v-or  test1
	make  RV=RV64  TEST=rv64ui-v-ori  test1
	make  RV=RV64  TEST=rv64ui-v-sb  test1
	make  RV=RV64  TEST=rv64ui-v-sd  test1
	make  RV=RV64  TEST=rv64ui-v-sh  test1
	make  RV=RV64  TEST=rv64ui-v-simple  test1
	make  RV=RV64  TEST=rv64ui-v-sll  test1
	make  RV=RV64  TEST=rv64ui-v-slli  test1
	make  RV=RV64  TEST=rv64ui-v-slliw  test1
	make  RV=RV64  TEST=rv64ui-v-sllw  test1
	make  RV=RV64  TEST=rv64ui-v-slt  test1
	make  RV=RV64  TEST=rv64ui-v-slti  test1
	make  RV=RV64  TEST=rv64ui-v-sltiu  test1
	make  RV=RV64  TEST=rv64ui-v-sltu  test1
	make  RV=RV64  TEST=rv64ui-v-sra  test1
	make  RV=RV64  TEST=rv64ui-v-srai  test1
	make  RV=RV64  TEST=rv64ui-v-sraiw  test1
	make  RV=RV64  TEST=rv64ui-v-sraw  test1
	make  RV=RV64  TEST=rv64ui-v-srl  test1
	make  RV=RV64  TEST=rv64ui-v-srli  test1
	make  RV=RV64  TEST=rv64ui-v-srliw  test1
	make  RV=RV64  TEST=rv64ui-v-srlw  test1
	make  RV=RV64  TEST=rv64ui-v-sub  test1
	make  RV=RV64  TEST=rv64ui-v-subw  test1
	make  RV=RV64  TEST=rv64ui-v-sw  test1
	make  RV=RV64  TEST=rv64ui-v-xor  test1
	make  RV=RV64  TEST=rv64ui-v-xori  test1
	@echo  "Finished  51  rv64ui-v  tests"

.PHONY: rv64um-p
rv64um-p:
	make  RV=RV64  TEST=rv64um-p-div  test1
	make  RV=RV64  TEST=rv64um-p-divu  test1
	make  RV=RV64  TEST=rv64um-p-divuw  test1
	make  RV=RV64  TEST=rv64um-p-divw  test1
	make  RV=RV64  TEST=rv64um-p-mul  test1
	make  RV=RV64  TEST=rv64um-p-mulh  test1
	make  RV=RV64  TEST=rv64um-p-mulhsu  test1
	make  RV=RV64  TEST=rv64um-p-mulhu  test1
	make  RV=RV64  TEST=rv64um-p-mulw  test1
	make  RV=RV64  TEST=rv64um-p-rem  test1
	make  RV=RV64  TEST=rv64um-p-remu  test1
	make  RV=RV64  TEST=rv64um-p-remuw  test1
	make  RV=RV64  TEST=rv64um-p-remw  test1
	@echo  "Finished  13  rv64um-p  tests"

.PHONY: rv64um-v
rv64um-v:
	make  RV=RV64  TEST=rv64um-v-div  test1
	make  RV=RV64  TEST=rv64um-v-divu  test1
	make  RV=RV64  TEST=rv64um-v-divuw  test1
	make  RV=RV64  TEST=rv64um-v-divw  test1
	make  RV=RV64  TEST=rv64um-v-mul  test1
	make  RV=RV64  TEST=rv64um-v-mulh  test1
	make  RV=RV64  TEST=rv64um-v-mulhsu  test1
	make  RV=RV64  TEST=rv64um-v-mulhu  test1
	make  RV=RV64  TEST=rv64um-v-mulw  test1
	make  RV=RV64  TEST=rv64um-v-rem  test1
	make  RV=RV64  TEST=rv64um-v-remu  test1
	make  RV=RV64  TEST=rv64um-v-remuw  test1
	make  RV=RV64  TEST=rv64um-v-remw  test1
	@echo  "Finished  13  rv64um-v  tests"

.PHONY: rv64ua-p
rv64ua-p:
	make  RV=RV64  TEST=rv64ua-p-amoadd_d  test1
	make  RV=RV64  TEST=rv64ua-p-amoadd_w  test1
	make  RV=RV64  TEST=rv64ua-p-amoand_d  test1
	make  RV=RV64  TEST=rv64ua-p-amoand_w  test1
	make  RV=RV64  TEST=rv64ua-p-amomax_d  test1
	make  RV=RV64  TEST=rv64ua-p-amomaxu_d  test1
	make  RV=RV64  TEST=rv64ua-p-amomaxu_w  test1
	make  RV=RV64  TEST=rv64ua-p-amomax_w  test1
	make  RV=RV64  TEST=rv64ua-p-amomin_d  test1
	make  RV=RV64  TEST=rv64ua-p-amominu_d  test1
	make  RV=RV64  TEST=rv64ua-p-amominu_w  test1
	make  RV=RV64  TEST=rv64ua-p-amomin_w  test1
	make  RV=RV64  TEST=rv64ua-p-amoor_d  test1
	make  RV=RV64  TEST=rv64ua-p-amoor_w  test1
	make  RV=RV64  TEST=rv64ua-p-amoswap_d  test1
	make  RV=RV64  TEST=rv64ua-p-amoswap_w  test1
	make  RV=RV64  TEST=rv64ua-p-amoxor_d  test1
	make  RV=RV64  TEST=rv64ua-p-amoxor_w  test1
	make  RV=RV64  TEST=rv64ua-p-lrsc  test1
	@echo  "Finished  19  rv64ua-p  tests"

.PHONY: rv64ua-v
rv64ua-v:
	make  RV=RV64  TEST=rv64ua-v-amoadd_d  test1
	make  RV=RV64  TEST=rv64ua-v-amoadd_w  test1
	make  RV=RV64  TEST=rv64ua-v-amoand_d  test1
	make  RV=RV64  TEST=rv64ua-v-amoand_w  test1
	make  RV=RV64  TEST=rv64ua-v-amomax_d  test1
	make  RV=RV64  TEST=rv64ua-v-amomaxu_d  test1
	make  RV=RV64  TEST=rv64ua-v-amomaxu_w  test1
	make  RV=RV64  TEST=rv64ua-v-amomax_w  test1
	make  RV=RV64  TEST=rv64ua-v-amomin_d  test1
	make  RV=RV64  TEST=rv64ua-v-amominu_d  test1
	make  RV=RV64  TEST=rv64ua-v-amominu_w  test1
	make  RV=RV64  TEST=rv64ua-v-amomin_w  test1
	make  RV=RV64  TEST=rv64ua-v-amoor_d  test1
	make  RV=RV64  TEST=rv64ua-v-amoor_w  test1
	make  RV=RV64  TEST=rv64ua-v-amoswap_d  test1
	make  RV=RV64  TEST=rv64ua-v-amoswap_w  test1
	make  RV=RV64  TEST=rv64ua-v-amoxor_d  test1
	make  RV=RV64  TEST=rv64ua-v-amoxor_w  test1
	make  RV=RV64  TEST=rv64ua-v-lrsc  test1
	@echo  "Finished  19  rv64ua-v  tests"

.PHONY: rv64uf-p
rv64uf-p:
	make  RV=RV64  TEST=rv64uf-p-fadd  test1
	make  RV=RV64  TEST=rv64uf-p-fclass  test1
	make  RV=RV64  TEST=rv64uf-p-fcmp  test1
	make  RV=RV64  TEST=rv64uf-p-fcvt  test1
	make  RV=RV64  TEST=rv64uf-p-fcvt_w  test1
	make  RV=RV64  TEST=rv64uf-p-fdiv  test1
	make  RV=RV64  TEST=rv64uf-p-fmadd  test1
	make  RV=RV64  TEST=rv64uf-p-fmin  test1
	make  RV=RV64  TEST=rv64uf-p-ldst  test1
	make  RV=RV64  TEST=rv64uf-p-move  test1
	make  RV=RV64  TEST=rv64uf-p-recoding  test1
	@echo  "Finished  11  rv64uf-p  tests"

.PHONY: rv64uf-v
rv64uf-v:
	make  RV=RV64  TEST=rv64uf-v-fadd  test1
	make  RV=RV64  TEST=rv64uf-v-fclass  test1
	make  RV=RV64  TEST=rv64uf-v-fcmp  test1
	make  RV=RV64  TEST=rv64uf-v-fcvt  test1
	make  RV=RV64  TEST=rv64uf-v-fcvt_w  test1
	make  RV=RV64  TEST=rv64uf-v-fdiv  test1
	make  RV=RV64  TEST=rv64uf-v-fmadd  test1
	make  RV=RV64  TEST=rv64uf-v-fmin  test1
	make  RV=RV64  TEST=rv64uf-v-ldst  test1
	make  RV=RV64  TEST=rv64uf-v-move  test1
	make  RV=RV64  TEST=rv64uf-v-recoding  test1
	@echo  "Finished  11  rv64uf-v  tests"

.PHONY: rv64ud-p
rv64ud-p:
	make  RV=RV64  TEST=rv64ud-p-fadd  test1
	make  RV=RV64  TEST=rv64ud-p-fclass  test1
	make  RV=RV64  TEST=rv64ud-p-fcmp  test1
	make  RV=RV64  TEST=rv64ud-p-fcvt  test1
	make  RV=RV64  TEST=rv64ud-p-fcvt_w  test1
	make  RV=RV64  TEST=rv64ud-p-fdiv  test1
	make  RV=RV64  TEST=rv64ud-p-fmadd  test1
	make  RV=RV64  TEST=rv64ud-p-fmin  test1
	make  RV=RV64  TEST=rv64ud-p-ldst  test1
	make  RV=RV64  TEST=rv64ud-p-move  test1
	make  RV=RV64  TEST=rv64ud-p-recoding  test1
	make  RV=RV64  TEST=rv64ud-p-structural  test1
	@echo  "Finished  12  rv64ud-p  tests"

.PHONY: rv64ud-v
rv64ud-v:
	make  RV=RV64  TEST=rv64ud-v-fadd  test1
	make  RV=RV64  TEST=rv64ud-v-fclass  test1
	make  RV=RV64  TEST=rv64ud-v-fcmp  test1
	make  RV=RV64  TEST=rv64ud-v-fcvt  test1
	make  RV=RV64  TEST=rv64ud-v-fcvt_w  test1
	make  RV=RV64  TEST=rv64ud-v-fdiv  test1
	make  RV=RV64  TEST=rv64ud-v-fmadd  test1
	make  RV=RV64  TEST=rv64ud-v-fmin  test1
	make  RV=RV64  TEST=rv64ud-v-ldst  test1
	make  RV=RV64  TEST=rv64ud-v-move  test1
	make  RV=RV64  TEST=rv64ud-v-recoding  test1
	make  RV=RV64  TEST=rv64ud-v-structural  test1
	@echo  "Finished  12  rv64ud-v  tests"

.PHONY: rv64uc-p
rv64uc-p:
	make  RV=RV64  TEST=rv64uc-p-rvc  test1
	@echo  "Finished  1  rv64uc-p  test"

.PHONY: rv64uc-v
rv64uc-v:
	make  RV=RV64  TEST=rv64uc-v-rvc  test1
	@echo  "Finished  1  rv64uc-v  test"

.PHONY: rv64mi-p
rv64mi-p:
	make  RV=RV64  TEST=rv64mi-p-access  test1
	make  RV=RV64  TEST=rv64mi-p-breakpoint  test1
	make  RV=RV64  TEST=rv64mi-p-csr  test1
	make  RV=RV64  TEST=rv64mi-p-illegal  test1
	make  RV=RV64  TEST=rv64mi-p-ma_addr  test1
	make  RV=RV64  TEST=rv64mi-p-ma_fetch  test1
	make  RV=RV64  TEST=rv64mi-p-mcsr  test1
	make  RV=RV64  TEST=rv64mi-p-sbreak  test1
	make  RV=RV64  TEST=rv64mi-p-scall  test1
	@echo  "Finished  9  rv64mi-p  tests"

.PHONY: rv64si-p
rv64si-p:
	make  RV=RV64  TEST=rv64si-p-csr  test1
	make  RV=RV64  TEST=rv64si-p-dirty  test1
	make  RV=RV64  TEST=rv64si-p-ma_fetch  test1
	make  RV=RV64  TEST=rv64si-p-sbreak  test1
	make  RV=RV64  TEST=rv64si-p-scall  test1
	make  RV=RV64  TEST=rv64si-p-wfi  test1
	@echo  "Finished  6  rv64si-p  tests"
