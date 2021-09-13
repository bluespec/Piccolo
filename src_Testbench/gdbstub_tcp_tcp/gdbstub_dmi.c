// Copyright (c) 2016-2020 Bluespec, Inc. All Rights Reserved
// Author: Rishiyur Nikhil

// ================================================================
// Stub implementation of DMI read/write functions

// ================================================================
// C lib includes

#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>

// ----------------
// Project includes

#include  "RVDM.h"
#include  "TCP_Client_Lib.h"

// ================================================================

FILE *logfile_dmi = NULL;

#define  DMI_OP_READ           1
#define  DMI_OP_WRITE          2
#define  DMI_OP_SHUTDOWN       3
#define  DMI_OP_START_COMMAND  4

#define  DMI_STATUS_ERR      0
#define  DMI_STATUS_OK       1
#define  DMI_STATUS_UNAVAIL  2

// ================================================================
// DMI interface (gdbstub invokes these functions)
// These should be filled in with the appropriate mechanisms that
// perform the actual DMI read/write on the RISC-V Debug module.

void dmi_write (uint16_t addr, uint32_t data)
{
    fprintf (logfile_dmi, "        DMI Write addr %0x", addr);
    fprint_dm_addr_name (logfile_dmi, " (", addr, ")");
    fprintf (logfile_dmi, " data %0x\n", data);

    uint8_t *p_buf;

    // Compose 7-byte request: { 32'data, 16'addr, 8'op }
    uint64_t req = data;
    req = ((req << 24) | ((addr & 0xFFFF) << 8) | DMI_OP_WRITE);

    // Send 7-byte request
    p_buf = (uint8_t *) & req;
    tcp_client_send (7, p_buf);
}

uint32_t  dmi_read  (uint16_t addr)
{
    fprintf (logfile_dmi, "        DMI Read addr %0x", addr);
    fprint_dm_addr_name (logfile_dmi, " (", addr, ") ...");
    fflush (logfile_dmi);

    uint8_t *p_buf;

    // Compose 7-byte request: { 32'data, 16'addr, 8'op }
    uint64_t req = 0;
    req = (((addr & 0xFFFF) << 8) | DMI_OP_READ);

    // Send 7-byte request
    p_buf = (uint8_t *) & req;
    tcp_client_send (7, p_buf);

    // Recieve 4-byte response
    uint32_t data;
    p_buf = (uint8_t *) & data;
    while (true) {
	bool do_poll = true;
	uint32_t status = tcp_client_recv (do_poll, 4, p_buf);
	if (status == status_ok) break;
    }
    fprintf (logfile_dmi, " => data %0x\n", data);
    return data;
}
