// Copyright (c) 2019 Bluespec, Inc.

// This file is a plug-compatible replacement for the "real" mkJtagTap.v
// (which is compiled from BSV).  This version ignores the jtag ports, and
// provides DMI ports using a vpi connection through imported C functions.

`define DEFAULT_DEBUG_PORT_VPI 5555

module mkJtagTap(
		 input 		 CLK,
		 input 		 RST_N,

		 input           jtag_tdi,
		 input     	 jtag_tms,
		 input           jtag_tclk,
		 output          jtag_tdo,

		 input 		 dmi_req_ready,
		 output reg 	 dmi_req_valid,
		 output reg [6:0]  dmi_req_addr,
		 output reg [31:0] dmi_req_data,
		 output reg [1:0]  dmi_req_op,

		 output reg 	 dmi_rsp_ready,
		 input 		 dmi_rsp_valid,
		 input [31:0] 	 dmi_rsp_data,
		 input [1:0] 	 dmi_rsp_response,

		 output CLK_jtag_tclk_out,
		 output CLK_GATE_jtag_tclk_out
		 );

   int 				 port;
   int 				 sock;
   int 				 fd;
   int 				 err;

   import "DPI-C" function int socket_open(input int port);
   import "DPI-C" function int socket_accept(input int fd);
   import "DPI-C" function int socket_putchar(input int fd, input int c);
   import "DPI-C" function int socket_getchar(input int fd);

   import "DPI-C" function int vpidmi_request(input int fd, output int addr, output int data, output int op);
   import "DPI-C" function int vpidmi_response(input int fd, input int data, input int response);

   initial begin
      fd = -1;

      if ($value$plusargs("vpi_port=%d", port) == 0)
	port = `DEFAULT_DEBUG_PORT_VPI;

      $display("using debug port (vpi) :%d", port);

      sock = socket_open(port);
      if (sock < 0) begin
	 $display("ERROR: socket_open(%d) returned %d", port, sock);
	 $finish;
      end
   end

   always @(posedge CLK) begin
      if (!RST_N) begin
	 dmi_req_valid <= 0;
	 dmi_req_addr <= 0;
	 dmi_req_data <= 0;
	 dmi_req_op <= 0;
	 dmi_rsp_ready <= 0;
      end
   end

   always @(posedge CLK) begin
      if (RST_N) begin
	 if (fd >= 0) begin
	    dmi_rsp_ready <= 1;

	    if (dmi_rsp_valid && dmi_rsp_ready) begin
	       int data;
	       int response;
	       data = dmi_rsp_data;
	       response = {30'd0, dmi_rsp_response};
	       err = vpidmi_response(fd, data, response);
	       if (err < 0) begin
		  $display("ERROR: vpidmi_response() returned %d", err);
		  $finish;
	       end
	    end

	    if (!dmi_req_valid || dmi_req_ready) begin
	       int addr;
	       int data;
	       int op;
	       err = vpidmi_request(fd, addr, data, op);
	       if (err < 0) begin
		  $display("ERROR: vpidmi_req_uest() returned %d", err);
		  $finish;
	       end
	       else if (err > 0) begin
		  dmi_req_valid <= 1;
		  dmi_req_addr <= addr[6:0];
		  dmi_req_data <= data;
		  dmi_req_op <= op[1:0];
	       end
	       else
		 dmi_req_valid <= 0;
	    end
	 end
	 else begin
	    fd = socket_accept(sock);
	 end
      end
   end

endmodule
