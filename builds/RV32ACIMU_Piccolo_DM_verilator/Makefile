###  -*-Makefile-*-

# *** DO NOT EDIT! ***
# *** This file is program-generated, not hand-written. ***
# ================================================================

REPO ?= ../..
ARCH ?= RV32ACIMU

# ================================================================
# RISC-V config macros passed into Bluespec 'bsc' compiler

BSC_COMPILATION_FLAGS += \
	-D RV32 \
	-D ISA_PRIV_M  -D ISA_PRIV_U  \
	-D ISA_I  -D ISA_M  -D ISA_A  -D ISA_C  \
	-D SHIFT_BARREL    \
	-D MULT_SYNTH    \
	-D Near_Mem_Caches    \
	-D FABRIC64    \
	-D INCLUDE_GDB_CONTROL


# Default ISA test

TEST ?= rv32ui-p-add

#================================================================
# Common boilerplate rules

include $(REPO)/builds/Resources/Include_Common.mk

#================================================================
# Makefile rules for building for specific simulator: verilator

include $(REPO)/builds/Resources/Include_verilator.mk

