// Copyright (c) 2019 Bluespec, Inc. All Rights Reserved

package PMPU_IFC;

// ================================================================
// This defines the interface for a PMPU (Physical Memory Protection Unit)
// Reference:
//      "The RISC-V Instruction Set Manual"
//      Volume II: Privileged Architecture, Version 1.11-draft, October 1, 2018
//      Section 3.6.1

// ================================================================

export PMPU_IFC (..);
export PMPU_CSR_IFC (..);

// ================================================================
// BSV library imports

import GetPut       :: *;
import ClientServer :: *;

// BSV additional libs

// none

// ================================================================
// Project imports

import ISA_Decls :: *;

// ================================================================
// INTERFACE

interface PMPU_IFC;
   // Reset request/response
   interface Server #(Token, Token) server_reset;

   (* always_ready *)
   method Bit #(5) m_num_pmp_regions;    // 0..16

   // Access permitted?
   method ActionValue #(Bool) permitted (WordXL      phys_addr,
					 MemReqSize  req_size,
					 Priv_Mode   priv,
					 Access_RWX  rwx);

   // CSR reads and writes of PMPs (see decl below)
   interface PMPU_CSR_IFC  pmp_csrs;
endinterface

// ----------------

interface PMPU_CSR_IFC;
   // Reads and writes of PMPs (originating in CSRRx instructions)

   method WordXL                 pmpcfg_read   (Bit #(2) j);
   method ActionValue #(WordXL)  pmpcfg_write  (Bit #(2) j, WordXL x);

   method WordXL                 pmpaddr_read  (Bit #(4) j);
   method ActionValue #(WordXL)  pmpaddr_write (Bit #(4) j, WordXL addr);
endinterface

// ================================================================

endpackage
