// Copyright (c) 2013-2021 Bluespec, Inc. All Rights Reserved

// ================================================================
// ISA defs for UC Berkeley RISC V
//
// References (from riscv.org):
//     The RISC-V Instruction Set Manual
//     Volume I: Unprivileged ISA
//     Document Version 20181106-Base-Ratification
//     November 6, 2018
//
//     The RISC-V Instruction Set Manual
//     Volume II: Privileged Architecture
//     Document Version 20181203-Base-Ratification
//     December 3, 2018
//
// ================================================================

package ISA_Decls;

// ================================================================
// BSV library imports

import DefaultValue :: *;
import Vector       :: *;
import BuildVector  :: *;

// ================================================================
// BSV project imports

// None

// ================================================================

typedef 3 NO_OF_PRIVMODES;

// ================================================================
// XLEN and related constants

`ifdef RV32

typedef 32 XLEN;

`elsif RV64

typedef 64 XLEN;

`endif

typedef TMul #(2, XLEN)  XLEN_2;      // Double-width for multiplications
typedef TSub #(XLEN, 2)  XLEN_MINUS_2;// XLEN-2 for MTVEC base width

Integer xlen = valueOf (XLEN);

typedef enum { RV32, RV64 } RV_Version deriving (Eq, Bits);

RV_Version rv_version = ( (valueOf (XLEN) == 32) ? RV32 : RV64 );

// ----------------
// We're evolving the code to use WordXL/IntXL instead of Word/Word_S
// because of the widespread and inconsistent use of 'word' in the field.
// All existing uses of 'Word/Word_S' should migrate towards WordXL/IntXL.
// All new code should only use WordXL/IntXL
// Eventually, we should remove Word and Word_S

typedef  Bit #(XLEN)  WordXL;    // Raw (unsigned) register data
typedef  Int #(XLEN)  IntXL;     // Signed register data

typedef  Bit #(XLEN)  Word;      // Raw (unsigned) register data    // OLD: migrate to WordXL
typedef  Int #(XLEN)  Word_S;    // Signed register data            // OLD: migrate to IntXL

typedef  WordXL       Addr;      // addresses/pointers

// ----------------

typedef  8                                     Bits_per_Byte;
typedef  Bit #(Bits_per_Byte)                  Byte;

typedef  XLEN                                  Bits_per_Word;            // REDUNDANT to XLEN

typedef  TDiv #(Bits_per_Word, Bits_per_Byte)  Bytes_per_Word;           // OLD ('WordXL')
typedef  TLog #(Bytes_per_Word)                Bits_per_Byte_in_Word;    // OLD ('WordXL')
typedef  Bit #(Bits_per_Byte_in_Word)          Byte_in_Word;             // OLD ('WordXL')
typedef  Vector #(Bytes_per_Word, Byte)        Word_B;                   // OLD ('WordXL')

typedef  TDiv #(XLEN, Bits_per_Byte)           Bytes_per_WordXL;
typedef  TLog #(Bytes_per_WordXL)              Bits_per_Byte_in_WordXL;
typedef  Bit #(Bits_per_Byte_in_WordXL)        Byte_in_WordXL;
typedef  Vector #(Bytes_per_WordXL, Byte)      WordXL_B;

typedef  XLEN                                  Bits_per_Addr;
typedef  TDiv #(Bits_per_Addr, Bits_per_Byte)  Bytes_per_Addr;

Integer  bits_per_byte           = valueOf (Bits_per_Byte);

Integer  bytes_per_wordxl        = valueOf (Bytes_per_WordXL);
Integer  bits_per_byte_in_wordxl = valueOf (Bits_per_Byte_in_WordXL);

Integer  addr_lo_byte_in_wordxl = 0;
Integer  addr_hi_byte_in_wordxl = addr_lo_byte_in_wordxl + bits_per_byte_in_wordxl - 1;

function  Byte_in_Word  fn_addr_to_byte_in_wordxl (Addr a);
   return a [addr_hi_byte_in_wordxl : addr_lo_byte_in_wordxl ];
endfunction

// ================================================================
// FLEN and related constants, for floating point data
// Can have one or two fpu sizes (should they be merged sooner than later ?).

// ISA_D => ISA_F (ISA_D implies ISA_F)
// The combination ISA_D and !ISA_F is not permitted

// ISA_F - 32 bit FPU
// ISA_D - 64 bit FPU

`ifdef ISA_F

`ifdef ISA_D
typedef 64 FLEN;
Bool hasFpu32 = False;
Bool hasFpu64 = True;
`else
typedef 32 FLEN;
Bool hasFpu32 = True;
Bool hasFpu64 = False;
`endif

typedef  Bit #(FLEN) FP_Value;
typedef  Bit #(FLEN)  WordFL;    // Floating point data

typedef  TDiv #(FLEN, Bits_per_Byte)           Bytes_per_WordFL;
typedef  TLog #(Bytes_per_WordFL)              Bits_per_Byte_in_WordFL;
typedef  Bit #(Bits_per_Byte_in_WordFL)        Byte_in_WordFL;
typedef  Vector #(Bytes_per_WordFL, Byte)      WordFL_B;

`endif

// ================================================================

endpackage
