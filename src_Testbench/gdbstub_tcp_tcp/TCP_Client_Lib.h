// Copyright (c) 2020-2021 Bluespec, Inc.  All Rights Reserved

// Please see TCP_Client_Lib.c for documentation

#pragma once

// ================================================================

#define   status_err      0
#define   status_ok       1
#define   status_unavail  2

// ================================================================

extern
uint32_t  tcp_client_open (const char *server_host, const uint16_t server_port);

extern
uint32_t  tcp_client_close (uint32_t dummy);

extern
uint32_t  tcp_client_send (const uint32_t data_size, const uint8_t *data);

extern
uint32_t  tcp_client_recv (bool do_poll, const uint32_t data_size, uint8_t *data);

// ================================================================
