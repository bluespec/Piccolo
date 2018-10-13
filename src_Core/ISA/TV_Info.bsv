// Copyright (c) 2013-2018 Bluespec, Inc. All Rights Reserved

// ================================================================
// Definition of Tandem Verifier Packets.
// The CPU sends out such a packet for each instruction retired.
// A Tandem Verifier contains a "golden model" simulator of the RISC-V
// ISA, and verifies that the information in the packet is correct,
// instruction by instruction.

// ================================================================

package TV_Info;

// ================================================================
// Bluespec library imports

import DefaultValue :: *;
import Vector       :: *;

// ================================================================
// Project imports

import ISA_Decls    :: *;

// ================================================================

typedef enum {TRACE_RESET,
	      TRACE_MIP,
	      TRACE_I_RD,   TRACE_F_RD,
 	      TRACE_I_LOAD,  TRACE_F_LOAD,
	      TRACE_STORE,
	      TRACE_AMO,
	      TRACE_OTHER,
	      TRACE_TRAP,
	      TRACE_INTR,
	      TRACE_RET,
	      TRACE_CSRRX
	      } Trace_Op
deriving (Bits, Eq, FShow);

typedef struct {
   Trace_Op   op;
   WordXL     pc;
   ISize      instr_sz;
   Bit #(32)  instr;
   RegName    rd;
   WordXL     word1;
   WordXL     word2;
   WordXL     word3;
   WordXL     word4;
   } Trace_Data
deriving (Bits);

// RESET
// op    pc    instr_sz    instr    rd    word1    word2    word3    word4
// x
function Trace_Data mkTrace_RESET ();
   Trace_Data td = ?;
   td.op       = TRACE_RESET;
   return td;
endfunction

// MIP
// op    pc    instr_sz    instr    rd    word1    word2    word3    word4
// x                                      mip
function Trace_Data mkTrace_MIP (WordXL mip);
   Trace_Data td = ?;
   td.op       = TRACE_MIP;
   td.word1    = mip;
   return td;
endfunction

// OTHER
// op    pc    instr_sz    instr    rd    word1    word2    word3    word4
// x     x     x           x
function Trace_Data mkTrace_OTHER (WordXL pc, ISize isize, Bit #(32) instr);
   Trace_Data td = ?;
   td.op       = TRACE_OTHER;
   td.pc       = pc;
   td.instr_sz = isize;
   td.instr    = instr;
   return td;
endfunction

// I_RD
// op    pc    instr_sz    instr    rd    word1    word2    word3    word4
// x     x     x           x        x     rdval
function Trace_Data mkTrace_I_RD (WordXL pc, ISize isize, Bit #(32) instr, RegName rd, WordXL rdval);
   Trace_Data td = ?;
   td.op       = TRACE_I_RD;
   td.pc       = pc;
   td.instr_sz = isize;
   td.instr    = instr;
   td.rd       = rd;
   td.word1    = rdval;
   return td;
endfunction

// F_RD
// op    pc    instr_sz    instr    rd    word1    word2    word3    word4
// x     x     x           x        x     rdval
function Trace_Data mkTrace_F_RD (WordXL pc, ISize isize, Bit #(32) instr, RegName rd, WordXL rdval);
   Trace_Data td = ?;
   td.op       = TRACE_F_RD;
   td.pc       = pc;
   td.instr_sz = isize;
   td.instr    = instr;
   td.rd       = rd;
   td.word1    = rdval;
   return td;
endfunction

// I_LOAD
// op    pc    instr_sz    instr    rd    word1    word2    word3    word4
// x     x     x           x        x     rdval             eaddr
function Trace_Data mkTrace_I_LOAD (WordXL pc, ISize isize, Bit #(32) instr, RegName rd, WordXL rdval, WordXL eaddr);
   Trace_Data td = ?;
   td.op       = TRACE_I_LOAD;
   td.pc       = pc;
   td.instr_sz = isize;
   td.instr    = instr;
   td.rd       = rd;
   td.word1    = rdval;
   td.word3    = eaddr;
   return td;
endfunction

// F_LOAD
// op    pc    instr_sz    instr    rd    word1    word2    word3    word4
// x     x     x           x        x     rdval             eaddr
function Trace_Data mkTrace_F_LOAD (WordXL pc, ISize isize, Bit #(32) instr, RegName rd, WordXL rdval, WordXL eaddr);
   Trace_Data td = ?;
   td.op       = TRACE_F_LOAD;
   td.pc       = pc;
   td.instr_sz = isize;
   td.instr    = instr;
   td.rd       = rd;
   td.word1    = rdval;
   td.word3    = eaddr;
   return td;
endfunction

// STORE
// op    pc    instr_sz    instr    rd    word1    word2    word3    word4
// x     x     x           x                       stval    eaddr
function Trace_Data mkTrace_STORE (WordXL pc, ISize isize, Bit #(32) instr, WordXL stval, WordXL eaddr);
   Trace_Data td = ?;
   td.op       = TRACE_STORE;
   td.pc       = pc;
   td.instr_sz = isize;
   td.instr    = instr;
   td.word2    = stval;
   td.word3    = eaddr;
   return td;
endfunction

// AMO
// op    pc    instr_sz    instr    rd    word1    word2    word3    word4
// x     x     x           x        x     rdval    stval    eaddr
function Trace_Data mkTrace_AMO (WordXL pc, ISize isize, Bit #(32) instr,
				    RegName rd, WordXL rdval, WordXL stval, WordXL eaddr);
   Trace_Data td = ?;
   td.op       = TRACE_AMO;
   td.pc       = pc;
   td.instr_sz = isize;
   td.instr    = instr;
   td.rd       = rd;
   td.word1    = rdval;
   td.word2    = stval;
   td.word3    = eaddr;
   return td;
endfunction

// CSRRX
// op    pc    instr_sz    instr    rd    word1    word2    word3    word4
// x     x     x           x        x     rdval    csrvalid csraddr  csrval
function Trace_Data mkTrace_CSRRX (WordXL pc, ISize isize, Bit #(32) instr,
				   RegName rd, WordXL rdval, Bool csrvalid, CSR_Addr csraddr, WordXL csrval);
   Trace_Data td = ?;
   td.op       = TRACE_CSRRX;
   td.pc       = pc;
   td.instr_sz = isize;
   td.instr    = instr;
   td.rd       = rd;
   td.word1    = rdval;
   td.word2    = (csrvalid ? 1 : 0);
   td.word3    = zeroExtend (csraddr);
   td.word4    = csrval;
   return td;
endfunction

// TRAP
// op    pc    instr_sz    instr    rd    word1    word2    word3    word4
// x     x     x           x        priv  mstatus  mcause   mepc     mtval
function Trace_Data mkTrace_TRAP (WordXL pc, ISize isize, Bit #(32) instr,
				  Priv_Mode  priv, WordXL mstatus, WordXL mcause, WordXL mepc, WordXL mtval);
   Trace_Data td = ?;
   td.op       = TRACE_TRAP;
   td.pc       = pc;
   td.instr_sz = isize;
   td.instr    = instr;
   td.rd       = zeroExtend (priv);
   td.word1    = mstatus;
   td.word2    = mcause;
   td.word3    = mepc;
   td.word4    = mtval;
   return td;
endfunction

// INTR
// op    pc    instr_sz    instr    rd    word1    word2    word3    word4
// x     x                          priv  mstatus  mcause   mepc     mtval
function Trace_Data mkTrace_INTR (WordXL pc,
				  Priv_Mode  priv, WordXL mstatus, WordXL mcause, WordXL mepc, WordXL mtval);
   Trace_Data td = ?;
   td.op       = TRACE_INTR;
   td.pc       = pc;
   td.rd       = zeroExtend (priv);
   td.word1    = mstatus;
   td.word2    = mcause;
   td.word3    = mepc;
   td.word4    = mtval;
   return td;
endfunction

// RET
// op    pc    instr_sz    instr    rd    word1    word2    word3    word4
// x     x     x           x        priv  mstatus
function Trace_Data mkTrace_RET (WordXL pc, ISize isize, Bit #(32) instr, Priv_Mode  priv, WordXL mstatus);
   Trace_Data td = ?;
   td.op       = TRACE_RET;
   td.pc       = pc;
   td.instr_sz = isize;
   td.instr    = instr;
   td.rd       = zeroExtend (priv);
   td.word1    = mstatus;
   return td;
endfunction

// ================================================================
// Display of Trace_Data for debugging

instance FShow #(Trace_Data);
   function Fmt fshow (Trace_Data td);
      Fmt fmt = $format ("Trace_Data{", fshow (td.op));

      if (td.op == TRACE_RESET) begin
      end

      else if (td.op == TRACE_MIP)
	 fmt = fmt + $format (" %0h", td.word1);

      else begin
	 fmt = fmt + $format (" pc %0h", td.pc);

	 if (td.op != TRACE_INTR)
	    fmt = fmt + $format (" instr.%0d %0h:", pack (td.instr_sz), td.instr);

	 if ((td.op == TRACE_I_RD) || (td.op == TRACE_F_RD))
	    fmt = fmt + $format (" rd %0d  rdval %0h", td.rd, td.word1);

	 else if ((td.op == TRACE_I_LOAD) || (td.op == TRACE_F_LOAD))
	    fmt = fmt + $format (" rd %0d  rdval %0h  eaddr %0h",
				 td.rd, td.word1, td.word3);

	 else if (td.op == TRACE_STORE)
	    fmt = fmt + $format (" stval %0h  eaddr %0h", td.word2, td.word3);

	 else if (td.op == TRACE_AMO)
	    fmt = fmt + $format (" rd %0d  rdval %0h  stval %0h  eaddr %0h",
				 td.rd, td.word1, td.word2, td.word3);

	 else if (td.op == TRACE_CSRRX)
	    fmt = fmt + $format (" rd %0d  rdval %0h  csraddr %0h  csrval %0h",
				 td.rd, td.word1, td.word3, td.word4);

	 else if ((td.op == TRACE_TRAP) || (td.op == TRACE_INTR))
	    fmt = fmt + $format (" priv %0d  mstatus %0h  mcause %0h  mepc %0h  mtval %0h",
				 td.rd, td.word1, td.word2, td.word3, td.word4);

	 else if (td.op == TRACE_RET)
	    fmt = fmt + $format (" priv %0d  mstatus %0h", td.rd, td.word1);
      end

      fmt = fmt + $format ("}");
      return fmt;
   endfunction
endinstance

// ================================================================
// Trace_Data is encoded in module mkTV_Encode into vectors of bytes,
// which are eventually streamed out to an on-line tandem verifier/
// analyzer (or to a file for off-line tandem-verification/analysis).

// Various 'transactions' produce a Trace_Data struct (e.g., reset,
// each instruction retirement, each GDB write to registers or memory,
// etc.).  Each struct is encoded into a vector of bytes; the number
// of bytes depends on the kind of transaction and various encoding
// choices.

typedef 72   TV_VB_SIZE;    // max bytes needed for each transaction
typedef  Vector #(TV_VB_SIZE, Byte)  TV_Vec_Bytes;

// ================================================================

endpackage
