
`ifndef __SIM_SOCKET_VH__
`define __SIM_SOCKET_VH__

//module  header1()
   import "DPI-C" function int socket_open(input int port);
   import "DPI-C" function int socket_accept(input int fd);
   import "DPI-C" function int socket_putchar(input int fd, input int c);
   import "DPI-C" function int socket_getchar(input int fd);
//endmodule // header1

`endif
