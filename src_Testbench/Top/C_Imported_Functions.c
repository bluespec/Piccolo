// Copyright (c) 2013-2018 Bluespec, Inc.  All Rights Reserved

// ================================================================
// These are functions imported into BSV for terminal I/O during
// Bluesim or Verilog simulation.
// See ConsoleIO.bsv for the import declarations.
// ================================================================

#include <sys/types.h>        /*  socket types              */
#include <poll.h>

#include <unistd.h>           /*  misc. UNIX functions      */
#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <inttypes.h>
#include <string.h>

#include "C_Imported_Functions.h"

// ================================================================
// c_trygetchar()
// Returns next input character (ASCII code) from the console.
// Returns 0 if no input is available.

// The dummy arg is not used, and is present only to appease Verilog
// simulators which can be be finicky about zero-argument functions.

uint8_t c_trygetchar (uint8_t  dummy)
{
    uint8_t  ch;
    ssize_t  n;
    struct pollfd  x_pollfd;
    const int fd_stdin = 0;

    // ----------------
    // Poll for input
    x_pollfd.fd      = fd_stdin;
    x_pollfd.events  = POLLRDNORM;
    x_pollfd.revents = 0;
    poll (& x_pollfd, 1, 1);

    // printf ("INFO: c_trygetchar: Polling for input\n");
    if ((x_pollfd.revents & POLLRDNORM) == 0) {
	return 0;
    }

    // ----------------
    // Input is available

    n = read (fd_stdin, & ch, 1);
    if (n == 1) {
	return ch;
    }
    else {
	if (n == 0)
	    printf ("c_trygetchar: end of file\n");
	return 0xFF;
    }
}

// ----------------------------------------------------------------
// A small testbench for c_trygetchar

#ifdef TEST_TRYGETCHAR

char message[] = "Hello World!\n";

int main (int argc, char *argv)
{
    uint8_t ch;
    int j;

    for (j = 0; j < strlen (message); j++)
	c_putchar (message[j]);

    printf ("Polling for input\n");

    j = 0;
    while (1) {
	ch = c_trygetchar ();
	if (ch == 0xFF) break;
	if (ch != 0)
	    printf ("Received character %0d 0x%0x '%c'\n", ch, ch, ch);
	else {
	    printf ("\r%0d ", j);
	    fflush (stdout);
	    j++;
	    sleep (1);
	}
    }
    return 0;
}

#endif

// ================================================================
// Writes character to stdout

uint32_t c_putchar (uint8_t ch)
{
    int      status;
    uint32_t success = 0;

    if ((ch == 0) || (ch > 0x7F)) {
	// Discard non-printables
	success = 1;
    }
    else {
	if ((ch == '\n') || (' ' <= ch)) {
	    status = fprintf (stdout, "%c", ch);
	    if (status > 0)
		success = 1;
	}
	else {
	    status = fprintf (stdout, "[\\%0d]", ch);
	    if (status > 0)
		success = 1;
	}

	if (success == 1) {
	    status = fflush (stdout);
	    if (status != 0)
		success = 0;
	}
    }

    return success;
}

// ================================================================
// Trace file output

static char trace_file_name[] = "trace_data.dat";

static FILE *trace_file_stream;

static uint64_t trace_file_size   = 0;
static uint64_t trace_file_writes = 0;

#define BUFSIZE 1024
static uint8_t buf [BUFSIZE];

// ----------------
// import "BDPI"
// function Action c_trace_file_open (Bit #(8) dummy);

uint32_t c_trace_file_open (uint8_t dummy)
{
    uint32_t success = 0;

    trace_file_stream = fopen ("trace_out.dat", "w");
    if (trace_file_stream == NULL) {
	fprintf (stderr, "ERROR: c_trace_file_open: unable to open file '%s'.\n", trace_file_name);
	success = 0;
    }
    else {
	fprintf (stdout, "c_trace_file_stream: opened file '%s' for trace_data.\n", trace_file_name);
	success = 1;
    }
    return success;
}

// ----------------
// import "BDPI"
// function Action c_trace_file_load_byte_in_buffer (Bit #(32) j, Bit #(8) data);

uint32_t c_trace_file_load_byte_in_buffer (uint32_t j, uint8_t data)
{
    uint32_t success = 0;

    if (j >= BUFSIZE) {
	fprintf (stderr, "ERROR: c_trace_file_load_byte_in_buffer: index (%0d) out of bounds (%0d)\n",
		 j, BUFSIZE);
	success = 0;
    }
    else {
	buf [j] = data;
	success = 1;
    }
    return success;
}

// ----------------
// import "BDPI"
// function Action c_trace_file_load_word64_in_buffer (Bit #(32) byte_offset, Bit #(64) data);

uint32_t c_trace_file_load_word64_in_buffer (uint32_t byte_offset, uint64_t data)
{
    uint32_t success = 0;

    if ((byte_offset + 7) >= BUFSIZE) {
	fprintf (stderr, "ERROR: c_trace_file_load_word64_in_buffer: index (%0d) out of bounds (%0d)\n",
		 byte_offset, BUFSIZE);
	success = 0;
    }
    else {
	uint64_t *p = (uint64_t *) & (buf [byte_offset]);
	*p = data;
	success = 1;
    }
    return success;
}

// ----------------
// import "BDPI"
// function Action c_trace_file_write_buffer (Bit #(32)  n);

uint32_t c_trace_file_write_buffer (uint32_t n)
{
    uint32_t success = 0;

    size_t n_written = fwrite (buf, 1, n, trace_file_stream);
    if (n_written != n)
	success = 0;
    else {
	trace_file_size   += n;
	trace_file_writes += 1;
	success = 1;
    }
    return success;
}

// ----------------
// import "BDPI"
// function Action c_trace_file_close (Bit #(8) dummy);

uint32_t c_trace_file_close (uint8_t dummy)
{
    uint32_t success = 0;
    int      status;

    if (trace_file_stream == NULL)
	success = 1;
    else {
	status = fclose (trace_file_stream);
	if (status != 0) {
	    fprintf (stderr, "ERROR: c_trace_file_close: error in fclose()\n");
	    success = 0;
	}
	else {
	    fprintf (stdout, "c_trace_file_stream: closed file '%s' for trace_data.\n", trace_file_name);
	    fprintf (stdout, "    Trace file writes: %0" PRId64 "\n", trace_file_writes);
	    fprintf (stdout, "    Trace file size:   %0" PRId64 " bytes\n", trace_file_size);
	    success = 1;
	}
    }
    return success;
}

// ================================================================
