//
// Generated by Bluespec Compiler, version 2018.10.beta1 (build e1df8052c, 2018-10-17)
//
// On Tue Jul  9 16:18:36 BST 2019
//
//
// Ports:
// Name                         I/O  size props
// fv_read                        O    32
// fav_write                      O    32
// CLK                            I     1 clock
// RST_N                          I     1 reset
// fav_write_misa                 I    28
// fav_write_wordxl               I    32
// EN_reset                       I     1
// EN_fav_write                   I     1
//
// Combinational paths from inputs to outputs:
//   (fav_write_misa, fav_write_wordxl) -> fav_write
//
//

`ifdef BSV_ASSIGNMENT_DELAY
`else
  `define BSV_ASSIGNMENT_DELAY
`endif

`ifdef BSV_POSITIVE_RESET
  `define BSV_RESET_VALUE 1'b1
  `define BSV_RESET_EDGE posedge
`else
  `define BSV_RESET_VALUE 1'b0
  `define BSV_RESET_EDGE negedge
`endif

module mkCSR_MIE(CLK,
		 RST_N,

		 EN_reset,

		 fv_read,

		 fav_write_misa,
		 fav_write_wordxl,
		 EN_fav_write,
		 fav_write);
  input  CLK;
  input  RST_N;

  // action method reset
  input  EN_reset;

  // value method fv_read
  output [31 : 0] fv_read;

  // actionvalue method fav_write
  input  [27 : 0] fav_write_misa;
  input  [31 : 0] fav_write_wordxl;
  input  EN_fav_write;
  output [31 : 0] fav_write;

  // signals for module outputs
  wire [31 : 0] fav_write, fv_read;

  // register rg_mie
  reg [11 : 0] rg_mie;
  wire [11 : 0] rg_mie$D_IN;
  wire rg_mie$EN;

  // rule scheduling signals
  wire CAN_FIRE_fav_write,
       CAN_FIRE_reset,
       WILL_FIRE_fav_write,
       WILL_FIRE_reset;

  // remaining internal signals
  wire [11 : 0] mie__h88;
  wire seie__h119, ssie__h113, stie__h116, ueie__h118, usie__h112, utie__h115;

  // action method reset
  assign CAN_FIRE_reset = 1'd1 ;
  assign WILL_FIRE_reset = EN_reset ;

  // value method fv_read
  assign fv_read = { 20'd0, rg_mie } ;

  // actionvalue method fav_write
  assign fav_write = { 20'd0, mie__h88 } ;
  assign CAN_FIRE_fav_write = 1'd1 ;
  assign WILL_FIRE_fav_write = EN_fav_write ;

  // register rg_mie
  assign rg_mie$D_IN = EN_fav_write ? mie__h88 : 12'd0 ;
  assign rg_mie$EN = EN_fav_write || EN_reset ;

  // remaining internal signals
  assign mie__h88 =
	     { fav_write_wordxl[11],
	       1'b0,
	       seie__h119,
	       ueie__h118,
	       fav_write_wordxl[7],
	       1'b0,
	       stie__h116,
	       utie__h115,
	       fav_write_wordxl[3],
	       1'b0,
	       ssie__h113,
	       usie__h112 } ;
  assign seie__h119 = fav_write_misa[18] && fav_write_wordxl[9] ;
  assign ssie__h113 = fav_write_misa[18] && fav_write_wordxl[1] ;
  assign stie__h116 = fav_write_misa[18] && fav_write_wordxl[5] ;
  assign ueie__h118 = fav_write_misa[13] && fav_write_wordxl[8] ;
  assign usie__h112 = fav_write_misa[13] && fav_write_wordxl[0] ;
  assign utie__h115 = fav_write_misa[13] && fav_write_wordxl[4] ;

  // handling of inlined registers

  always@(posedge CLK)
  begin
    if (RST_N == `BSV_RESET_VALUE)
      begin
        rg_mie <= `BSV_ASSIGNMENT_DELAY 12'd0;
      end
    else
      begin
        if (rg_mie$EN) rg_mie <= `BSV_ASSIGNMENT_DELAY rg_mie$D_IN;
      end
  end

  // synopsys translate_off
  `ifdef BSV_NO_INITIAL_BLOCKS
  `else // not BSV_NO_INITIAL_BLOCKS
  initial
  begin
    rg_mie = 12'hAAA;
  end
  `endif // BSV_NO_INITIAL_BLOCKS
  // synopsys translate_on
endmodule  // mkCSR_MIE

