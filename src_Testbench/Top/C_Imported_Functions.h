// Copyright (c) 2016-2018 Bluespec, Inc.  All Rights Reserved

#pragma once

// ================================================================
// These are functions imported into BSV for terminal I/O during
// Bluesim or Verilog simulation.
// See ConsoleIO.bsv for the import declarations.
// ================================================================

#ifdef __cplusplus
extern "C" {
#endif

// ================================================================
// Returns next input character (ASCII code) from the console.
// Returns 0 if no input is available.

// The dummy arg is not used, and is present only to appease Verilog
// simulators which can be be finicky about zero-argument functions.

extern
uint8_t c_trygetchar (uint8_t  dummy);

// ================================================================
// Writes character to stdout

extern
uint32_t c_putchar (uint8_t ch);

// ================================================================
// Trace file outputs

extern
uint32_t c_trace_file_open (uint8_t dummy);

extern
uint32_t c_trace_file_load_byte_in_buffer (uint32_t j, uint8_t data);

extern
uint32_t c_trace_file_load_word64_in_buffer (uint32_t byte_offset, uint64_t data);

extern
uint32_t c_trace_file_write_buffer (uint32_t n);

extern
uint32_t c_trace_file_close (uint8_t dummy);

// ================================================================

#ifdef __cplusplus
}
#endif
