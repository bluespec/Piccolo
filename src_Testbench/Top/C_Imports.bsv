// Copyright (c) 2013-2018 Bluespec, Inc.  All Rights Reserved

package C_Imports;

// ================================================================
// For Bluesim and Verilog simulation,
// declarations of imported C functions (hence only in simulation)
// to read and write chars to the console.
// See_C_Imports_Functions.{h,c} for implementation of these functions.

// Below, 'dummy' args are not used, and are present only to appease
// some Verilog simulators that are finicky about 0-arg functions.

// ================================================================
// BSV lib imports

import Vector :: *;

// ================================================================
//    extern  uint8_t c_trygetchar (void)
// If no input available on console, returns 0,
// else returns the the character.

import "BDPI"
function ActionValue #(Bit #(8)) c_trygetchar (Bit #(8) dummy);

// ================================================================
//    extern  void c_write (uint32_t bytecount, void *rsp)

import "BDPI"
function ActionValue #(Bit #(32)) c_putchar (Bit #(8) ch);

// ================================================================
// Writing to trace file (to log traces for tandem verification, etc.)
// We restrict ourselves to scalar args to the C functions
// for simplicity of linking to C.

//    extern uint32_t c_trace_file_open (uint8_t dummy)

import "BDPI"
function ActionValue #(Bit #(32)) c_trace_file_open (Bit #(8) dummy);

// ----------------
//    extern uint32_t c_trace_file_load_byte_in_buffer (uint32_t j, uint8_t data)

import "BDPI"
function ActionValue #(Bit #(32)) c_trace_file_load_byte_in_buffer (Bit #(32) j, Bit #(8) data);

// ----------------
//    extern uint32_t c_trace_file_load_word64_in_buffer (uint32_t byte_offset, uint64_t data)

import "BDPI"
function ActionValue #(Bit #(32)) c_trace_file_load_word64_in_buffer (Bit #(32) byte_offset, Bit #(64) data);

// ----------------
//    extern uint32_t c_trace_file_write_buffer (uint32_t n)

import "BDPI"
function ActionValue #(Bit #(32)) c_trace_file_write_buffer (Bit #(32)  n);

// ----------------
//    extern uint32_t c_trace_file_close (uint8_t dummy)

import "BDPI"
function ActionValue #(Bit #(32)) c_trace_file_close (Bit #(8) dummy);

// ================================================================

endpackage
