// Copyright (c) 2019 Bluespec, Inc. All Rights Reserved

package PMPU_Config;

// ================================================================
// This defines configuration parameters for a PMPU (Physical Memory Protection Unit)
// Reference:
//      "The RISC-V Instruction Set Manual"
//      Volume II: Privileged Architecture, Version 1.11-draft, October 1, 2018
//      Section 3.6.1

// ================================================================
// Configuration constants: edit these as desired.

// ----------------
// Number of PMPs actually implemented.
// Spec: "If any PMP entries are implemented, then all PMP CSRs must
// be implemented, but all PMP CSR fields are WARL and may be
// hardwired to zero".
// Here,
//   Num_PMP_Regions = 0 means no PMP CSRs are implemented
//   Num_PMP_Regions = n (n in [1..6] means all 16 CSR sets are accessible, bug
//                     0..n-1 are R/W
//                     n..15 are hardwired to 0.

`ifdef INCLUDE_PMPS

// typedef  2  Num_PMP_Regions;
// typedef  4  Num_PMP_Regions;
// typedef  8  Num_PMP_Regions;
typedef 16  Num_PMP_Regions;

`else

typedef  0  Num_PMP_Regions;

`endif

Integer num_pmp_regions = valueOf (Num_PMP_Regions);

// ================================================================
// Region granularity

// "In general, the PMP grain is 2^{G+2} bytes and must be the same across all regions"

typedef  18  PMP_G;    // PMP region granularity is 2^{G+2}

Integer pmp_G = valueOf (PMP_G);

// ================================================================

endpackage
