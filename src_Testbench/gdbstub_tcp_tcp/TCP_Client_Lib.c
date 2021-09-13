// Copyright (c) 2020-2021 Bluespec, Inc.  All Rights Reserved

// ================================================================
// Client communications over TCP/IP

// Sends and receives bytevecs over a TCP socket to/from a remote server

// ----------------
// Acknowledgement: portions of TCP code adapted from example ECHOSERV
//   ECHOSERV
//   (c) Paul Griffiths, 1999
//   http://www.paulgriffiths.net/program/c/echoserv.php

// ================================================================
// C lib includes

// General
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <stdbool.h>
#include <errno.h>

// For comms polling
#include <poll.h>
#include <sched.h>

// For TCP
#include <sys/socket.h>       /*  socket definitions        */
#include <sys/types.h>        /*  socket types              */
#include <arpa/inet.h>        /*  inet (3) funtions         */
#include <fcntl.h>            /* To set non-blocking mode   */

// ----------------
// Project includes

#include "TCP_Client_Lib.h"

// ================================================================
// The socket file descriptor

static int sockfd = 0;

// ================================================================
// Open a TCP socket as a client connected to specified remote
// listening server socket.
// Return status_err or status_ok.

uint32_t  tcp_client_open (const char *server_host, const uint16_t server_port)
{
    if (server_host == NULL) {
	fprintf (stdout, "tcp_client_open (): server_host is NULL\n");
	return status_err;
    }
    if (server_port == 0) {
	fprintf (stdout, "tcp_client_open (): server_port is 0\n");
	return status_err;
    }

    fprintf (stdout, "tcp_client_open: connecting to '%s' port %0d\n",
	     server_host, server_port);

    // Create the socket
    if ( (sockfd = socket (AF_INET, SOCK_STREAM, 0)) < 0 ) {
	fprintf (stdout, "tcp_client_open (): Error creating socket.\n");
	return status_err;
    }

    struct sockaddr_in servaddr;  // socket address structure

    // Initialize socket address structure
    memset (& servaddr, 0, sizeof (servaddr));
    servaddr.sin_family = AF_INET;
    servaddr.sin_port   = htons (server_port);

    // Set the remote IP address
    if (inet_aton (server_host, & servaddr.sin_addr) <= 0 ) {
	fprintf (stdout, "tcp_client_open (): Invalid remote IP address.\n");
	return status_err;
    }

    // connect() to the remote server
    if (connect (sockfd, (struct sockaddr *) &servaddr, sizeof(servaddr) ) < 0 ) {
	fprintf (stdout, "tcp_client_open (): Error calling connect()\n");
	return status_err;
    }

    fprintf (stdout, "tcp_client_open: connected\n");
    return status_ok;
}

// ================================================================
// Close the connection to the remote server.

uint32_t  tcp_client_close (uint32_t dummy)
{
    if (sockfd > 0)
	close (sockfd);

    return  status_ok;
}

// ================================================================
// Send a message

uint32_t  tcp_client_send (const uint32_t data_size, const uint8_t *data)
{
    int n;

    n = write (sockfd, data, data_size);

    if (n < 0) {
	fprintf (stdout, "ERROR: tcp_client_send() = %0d\n", n);
	return status_err;
    }
    return status_ok;
}

// ================================================================
// Recv a message
// Return status_ok or status_unavail (no input data available)

uint32_t  tcp_client_recv (bool do_poll, const uint32_t data_size, uint8_t *data)
{
    // Poll, if required
    if (do_poll) {
	struct pollfd  x_pollfd;
	x_pollfd.fd      = sockfd;
	x_pollfd.events  = POLLRDNORM;
	x_pollfd.revents = 0;

	int n = poll (& x_pollfd, 1, 0);

	if (n < 0) {
	    fprintf (stdout, "ERROR: tcp_client_recv (): poll () failed\n");
	    exit (1);
	}

	if ((x_pollfd.revents & POLLRDNORM) == 0) {
	    return status_unavail;
	}
    }

    // Read data
    int  n_recd = 0;
    while (n_recd < data_size) {
	int n = read (sockfd, & (data [n_recd]), (data_size - n_recd));
	if ((n < 0) && (errno != EAGAIN) && (errno != EWOULDBLOCK)) {
	    fprintf (stdout, "ERROR: tcp_client_recv (): read () failed on byte 0\n");
	    exit (1);
	}
	else if (n > 0) {
	    n_recd += n;
	}
    }
    return status_ok;
}

// ================================================================
