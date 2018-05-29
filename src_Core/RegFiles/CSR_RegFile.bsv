// Copyright (c) 2016-2018 Bluespec, Inc. All Rights Reserved

package CSR_RegFile;


// ================================================================
`ifdef CSR_REGFILE_MIN

// Minimal CSR RegFile: User-mode CSRs, plus just enough M-mode CSRs
// to support traps/interrupts.

import CSR_RegFile_Min :: *;
export CSR_RegFile_Min :: *;

// ================================================================
`else

// Default CSR RegFile: User-mode and Machine-Mode CSRs

import CSR_RegFile_UM :: *;
export CSR_RegFile_UM :: *;

// ================================================================
`endif

endpackage
