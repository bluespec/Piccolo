# Copyright (c) 2021 Rishiyur S. Nikhil and Bluespec, Inc.

# ================================================================

.PHONY: help
help:
	@echo "Usage:"
	@echo "    make  XLEN=32/64  $(EXE)        Create gdbstub executable for RV32/RV64 CPUs"

#================================================================

ifndef GDBSTUB_REPO
  $(error ERROR: please define GDBSTUB_REPO:)
  $(error     path to clone of https://github.com/bluespec/RISCV_gdbstub)
else
  $(info  INFO: GDBSTUB_REPO = $(GDBSTUB_REPO))
endif

XLEN ?= 32

ifeq ($(XLEN),32)
  $(info  INFO: XLEN = $(XLEN))
else ifeq ($(XLEN),64)
  $(info  INFO: XLEN = $(XLEN))
else
  $(error ERROR: please define XLEN=32 or XLEN=64, for debugging RV32/RV64 CPUs)
endif

EXE = exe_gdbstub_tcp_tcp_RV$(XLEN)

# ================================================================

GDBSTUB_REPO_SRC = $(GDBSTUB_REPO)/src

INCLUDE_DIRS = -I $(GDBSTUB_REPO_SRC)

SRCS_H += TCP_Client_Lib.h
SRCS_H += $(GDBSTUB_REPO_SRC)/Elf_read.h
SRCS_H += $(GDBSTUB_REPO_SRC)/gdbstub_be.h
SRCS_H += $(GDBSTUB_REPO_SRC)/gdbstub_dmi.h
SRCS_H += $(GDBSTUB_REPO_SRC)/gdbstub_fe.h
SRCS_H += $(GDBSTUB_REPO_SRC)/gdbstub.h
SRCS_H += $(GDBSTUB_REPO_SRC)/RVDM.h

SRCS_C += gdbstub_tcp_tcp.c
SRCS_C += gdbstub_dmi.c
SRCS_C += TCP_Client_Lib.c
SRCS_C += $(GDBSTUB_REPO_SRC)/gdbstub_be.c
SRCS_C += $(GDBSTUB_REPO_SRC)/gdbstub.c
SRCS_C += $(GDBSTUB_REPO_SRC)/gdbstub_fe.c
SRCS_C += $(GDBSTUB_REPO_SRC)/RVDM.c
SRCS_C += $(GDBSTUB_REPO_SRC)/Elf_read.c

# ================================================================

$(EXE): $(SRCS_H) $(SRCS_C)
	$(info INFO: Making executable $(EXE) for gdbstub for RV$(XLEN) CPUs)
	$(CC) -Wall -g  -D RV$(XLEN) -o $@  $(INCLUDE_DIRS)  $(SRCS_C)  -lelf  -lpthread

# ================================================================

.PHONY: clean
clean:
	rm -f  *~

.PHONY: full_clean
full_clean:
	rm -f  *~  $(EXE)  log*.txt

# ================================================================
