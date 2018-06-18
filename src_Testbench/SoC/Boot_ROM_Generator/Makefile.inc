# To be included into the HW Makefile
#
# Expects the following to be defined:
#
# GEN_BOOTROM_DIR
# RV or ISA_RV
# ISAOPTS or ISA_OPTS
# CXX
# CXXFLAGS (optional)
#
# ----------------------------------------------------------------

BUILD_DIR ?= build

# ----------------------------------------------------------------

# Use ISA_RV (from brvf_auto_build) as RV.
# If using Makefile_configs_V2, RV is used
ifneq ($(ISA_RV),)
RV=$(ISA_RV)
endif

# Use ISA_OPTS (from brvf_auto_build) as ISAOPTS.
# If using Makefile_configs_V2, ISAOPTS is used 
ifneq ($(ISA_OPTS),)
ISAOPTS=$(ISA_OPTS)
endif

$(info ISAOPTS = $(ISAOPTS))

ifneq (,$(findstring ISA_M,$(ISAOPTS)))
ISA_M = m
endif

ifneq (,$(findstring ISA_A,$(ISAOPTS)))
ISA_A = a
endif

ifneq (,$(findstring ISA_FD,$(ISAOPTS)))
ISA_FD = fd
endif

ifneq (,$(findstring ISA_C,$(ISAOPTS)))
ISA_C = c
endif

ifneq (,$(findstring ISA_PRIV_U,$(ISAOPTS)))
ISA_U = u
endif

ifneq (,$(findstring ISA_PRIV_S,$(ISAOPTS)))
ISA_S = s
endif

ISA_BASE = i

ISA_STRING = $(ISA_BASE)$(ISA_M)$(ISA_A)$(ISA_FD)$(ISA_C)$(ISA_U)$(ISA_S)

# ----------------------------------------------------------------

BSV_DEPENDENCIES += $(BUILD_DIR)/fn_read_ROM_$(RV).bsvi

$(BUILD_DIR)/fn_read_ROM_$(RV).bsvi: $(BUILD_DIR)  $(BUILD_DIR)/boot_ROM_$(RV).memhex  $(GEN_BOOTROM_DIR)/Gen_BSV_fn_read_ROM.py
	$(GEN_BOOTROM_DIR)/Gen_BSV_fn_read_ROM.py  $(BUILD_DIR)/boot_ROM_$(RV).memhex  $@

$(BUILD_DIR)/boot_ROM_$(RV).memhex: $(BUILD_DIR)  $(BUILD_DIR)/gen_bootrom_$(RV).exe
	$(BUILD_DIR)/gen_bootrom_$(RV).exe  "$(RV)"  "$(ISA_STRING)"  >  $@

$(BUILD_DIR)/gen_bootrom_$(RV).exe: $(BUILD_DIR)  $(GEN_BOOTROM_DIR)/gen_bootrom.cc
	$(CXX)  -o $@  $(CXXFLAGS)  -std=c++11  -D RV32  $(GEN_BOOTROM_DIR)/gen_bootrom.cc

# ----------------------------------------------------------------
