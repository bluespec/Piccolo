//
// Generated by Bluespec Compiler, version 2019.05.beta2 (build a88bf40db, 2019-05-24)
//
//
//
//
// Ports:
// Name                         I/O  size props
// fn_target_max_prio_and_max_id0  O     8
// fn_target_max_prio_and_max_id0_vrg_source_ip  I    17
// fn_target_max_prio_and_max_id0_vvrg_ie  I    34
// fn_target_max_prio_and_max_id0_vrg_source_prio  I    51
// fn_target_max_prio_and_max_id0_target_id  I     5
//
// Combinational paths from inputs to outputs:
//   (fn_target_max_prio_and_max_id0_vrg_source_ip,
//    fn_target_max_prio_and_max_id0_vvrg_ie,
//    fn_target_max_prio_and_max_id0_vrg_source_prio,
//    fn_target_max_prio_and_max_id0_target_id) -> fn_target_max_prio_and_max_id0
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

module module_fn_target_max_prio_and_max_id0(fn_target_max_prio_and_max_id0_vrg_source_ip,
					     fn_target_max_prio_and_max_id0_vvrg_ie,
					     fn_target_max_prio_and_max_id0_vrg_source_prio,
					     fn_target_max_prio_and_max_id0_target_id,
					     fn_target_max_prio_and_max_id0);
  // value method fn_target_max_prio_and_max_id0
  input  [16 : 0] fn_target_max_prio_and_max_id0_vrg_source_ip;
  input  [33 : 0] fn_target_max_prio_and_max_id0_vvrg_ie;
  input  [50 : 0] fn_target_max_prio_and_max_id0_vrg_source_prio;
  input  [4 : 0] fn_target_max_prio_and_max_id0_target_id;
  output [7 : 0] fn_target_max_prio_and_max_id0;

  // signals for module outputs
  wire [7 : 0] fn_target_max_prio_and_max_id0;

  // remaining internal signals
  reg CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q1,
      CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q10,
      CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q11,
      CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q12,
      CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q13,
      CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q14,
      CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q15,
      CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q16,
      CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q2,
      CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q3,
      CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q4,
      CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q5,
      CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q6,
      CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q7,
      CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q8,
      CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q9;
  wire [7 : 0] IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d192,
	       IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d194,
	       IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d196,
	       IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d198,
	       IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d200,
	       IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d202,
	       IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d204,
	       IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d206;
  wire [2 : 0] IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d104,
	       IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d113,
	       IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d122,
	       IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d131,
	       IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d140,
	       IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d149,
	       IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d158,
	       IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d41,
	       IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d50,
	       IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d59,
	       IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d68,
	       IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d77,
	       IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d86,
	       IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d95;
  wire fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d103,
       fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d112,
       fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d121,
       fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d130,
       fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d139,
       fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d148,
       fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d157,
       fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d166,
       fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d49,
       fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d58,
       fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d67,
       fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d76,
       fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d85,
       fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d94;

  // value method fn_target_max_prio_and_max_id0
  assign fn_target_max_prio_and_max_id0 =
	     (fn_target_max_prio_and_max_id0_vrg_source_ip[16] &&
	      fn_target_max_prio_and_max_id0_vrg_source_prio[50:48] >
	      (fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d166 ?
		 fn_target_max_prio_and_max_id0_vrg_source_prio[47:45] :
		 IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d158) &&
	      CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q16) ?
	       { fn_target_max_prio_and_max_id0_vrg_source_prio[50:48],
		 5'd16 } :
	       IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d206 ;

  // remaining internal signals
  assign IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d104 =
	     fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d103 ?
	       fn_target_max_prio_and_max_id0_vrg_source_prio[26:24] :
	       IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d95 ;
  assign IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d113 =
	     fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d112 ?
	       fn_target_max_prio_and_max_id0_vrg_source_prio[29:27] :
	       IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d104 ;
  assign IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d122 =
	     fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d121 ?
	       fn_target_max_prio_and_max_id0_vrg_source_prio[32:30] :
	       IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d113 ;
  assign IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d131 =
	     fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d130 ?
	       fn_target_max_prio_and_max_id0_vrg_source_prio[35:33] :
	       IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d122 ;
  assign IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d140 =
	     fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d139 ?
	       fn_target_max_prio_and_max_id0_vrg_source_prio[38:36] :
	       IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d131 ;
  assign IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d149 =
	     fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d148 ?
	       fn_target_max_prio_and_max_id0_vrg_source_prio[41:39] :
	       IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d140 ;
  assign IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d158 =
	     fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d157 ?
	       fn_target_max_prio_and_max_id0_vrg_source_prio[44:42] :
	       IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d149 ;
  assign IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d192 =
	     (fn_target_max_prio_and_max_id0_vrg_source_ip[1] &&
	      fn_target_max_prio_and_max_id0_vrg_source_prio[5:3] != 3'd0 &&
	      CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q1) ?
	       { fn_target_max_prio_and_max_id0_vrg_source_prio[5:3], 5'd1 } :
	       8'd0 ;
  assign IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d194 =
	     fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d58 ?
	       { fn_target_max_prio_and_max_id0_vrg_source_prio[11:9],
		 5'd3 } :
	       (fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d49 ?
		  { fn_target_max_prio_and_max_id0_vrg_source_prio[8:6],
		    5'd2 } :
		  IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d192) ;
  assign IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d196 =
	     fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d76 ?
	       { fn_target_max_prio_and_max_id0_vrg_source_prio[17:15],
		 5'd5 } :
	       (fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d67 ?
		  { fn_target_max_prio_and_max_id0_vrg_source_prio[14:12],
		    5'd4 } :
		  IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d194) ;
  assign IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d198 =
	     fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d94 ?
	       { fn_target_max_prio_and_max_id0_vrg_source_prio[23:21],
		 5'd7 } :
	       (fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d85 ?
		  { fn_target_max_prio_and_max_id0_vrg_source_prio[20:18],
		    5'd6 } :
		  IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d196) ;
  assign IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d200 =
	     fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d112 ?
	       { fn_target_max_prio_and_max_id0_vrg_source_prio[29:27],
		 5'd9 } :
	       (fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d103 ?
		  { fn_target_max_prio_and_max_id0_vrg_source_prio[26:24],
		    5'd8 } :
		  IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d198) ;
  assign IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d202 =
	     fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d130 ?
	       { fn_target_max_prio_and_max_id0_vrg_source_prio[35:33],
		 5'd11 } :
	       (fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d121 ?
		  { fn_target_max_prio_and_max_id0_vrg_source_prio[32:30],
		    5'd10 } :
		  IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d200) ;
  assign IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d204 =
	     fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d148 ?
	       { fn_target_max_prio_and_max_id0_vrg_source_prio[41:39],
		 5'd13 } :
	       (fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d139 ?
		  { fn_target_max_prio_and_max_id0_vrg_source_prio[38:36],
		    5'd12 } :
		  IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d202) ;
  assign IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d206 =
	     fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d166 ?
	       { fn_target_max_prio_and_max_id0_vrg_source_prio[47:45],
		 5'd15 } :
	       (fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d157 ?
		  { fn_target_max_prio_and_max_id0_vrg_source_prio[44:42],
		    5'd14 } :
		  IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d204) ;
  assign IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d41 =
	     (fn_target_max_prio_and_max_id0_vrg_source_ip[1] &&
	      fn_target_max_prio_and_max_id0_vrg_source_prio[5:3] != 3'd0 &&
	      CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q1) ?
	       fn_target_max_prio_and_max_id0_vrg_source_prio[5:3] :
	       3'd0 ;
  assign IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d50 =
	     fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d49 ?
	       fn_target_max_prio_and_max_id0_vrg_source_prio[8:6] :
	       IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d41 ;
  assign IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d59 =
	     fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d58 ?
	       fn_target_max_prio_and_max_id0_vrg_source_prio[11:9] :
	       IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d50 ;
  assign IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d68 =
	     fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d67 ?
	       fn_target_max_prio_and_max_id0_vrg_source_prio[14:12] :
	       IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d59 ;
  assign IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d77 =
	     fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d76 ?
	       fn_target_max_prio_and_max_id0_vrg_source_prio[17:15] :
	       IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d68 ;
  assign IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d86 =
	     fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d85 ?
	       fn_target_max_prio_and_max_id0_vrg_source_prio[20:18] :
	       IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d77 ;
  assign IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d95 =
	     fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d94 ?
	       fn_target_max_prio_and_max_id0_vrg_source_prio[23:21] :
	       IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d86 ;
  assign fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d103 =
	     fn_target_max_prio_and_max_id0_vrg_source_ip[8] &&
	     fn_target_max_prio_and_max_id0_vrg_source_prio[26:24] >
	     IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d95 &&
	     CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q8 ;
  assign fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d112 =
	     fn_target_max_prio_and_max_id0_vrg_source_ip[9] &&
	     fn_target_max_prio_and_max_id0_vrg_source_prio[29:27] >
	     IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d104 &&
	     CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q9 ;
  assign fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d121 =
	     fn_target_max_prio_and_max_id0_vrg_source_ip[10] &&
	     fn_target_max_prio_and_max_id0_vrg_source_prio[32:30] >
	     IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d113 &&
	     CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q10 ;
  assign fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d130 =
	     fn_target_max_prio_and_max_id0_vrg_source_ip[11] &&
	     fn_target_max_prio_and_max_id0_vrg_source_prio[35:33] >
	     IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d122 &&
	     CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q11 ;
  assign fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d139 =
	     fn_target_max_prio_and_max_id0_vrg_source_ip[12] &&
	     fn_target_max_prio_and_max_id0_vrg_source_prio[38:36] >
	     IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d131 &&
	     CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q12 ;
  assign fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d148 =
	     fn_target_max_prio_and_max_id0_vrg_source_ip[13] &&
	     fn_target_max_prio_and_max_id0_vrg_source_prio[41:39] >
	     IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d140 &&
	     CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q13 ;
  assign fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d157 =
	     fn_target_max_prio_and_max_id0_vrg_source_ip[14] &&
	     fn_target_max_prio_and_max_id0_vrg_source_prio[44:42] >
	     IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d149 &&
	     CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q14 ;
  assign fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d166 =
	     fn_target_max_prio_and_max_id0_vrg_source_ip[15] &&
	     fn_target_max_prio_and_max_id0_vrg_source_prio[47:45] >
	     IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d158 &&
	     CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q15 ;
  assign fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d49 =
	     fn_target_max_prio_and_max_id0_vrg_source_ip[2] &&
	     fn_target_max_prio_and_max_id0_vrg_source_prio[8:6] >
	     IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d41 &&
	     CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q2 ;
  assign fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d58 =
	     fn_target_max_prio_and_max_id0_vrg_source_ip[3] &&
	     fn_target_max_prio_and_max_id0_vrg_source_prio[11:9] >
	     IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d50 &&
	     CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q3 ;
  assign fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d67 =
	     fn_target_max_prio_and_max_id0_vrg_source_ip[4] &&
	     fn_target_max_prio_and_max_id0_vrg_source_prio[14:12] >
	     IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d59 &&
	     CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q4 ;
  assign fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d76 =
	     fn_target_max_prio_and_max_id0_vrg_source_ip[5] &&
	     fn_target_max_prio_and_max_id0_vrg_source_prio[17:15] >
	     IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d68 &&
	     CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q5 ;
  assign fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d85 =
	     fn_target_max_prio_and_max_id0_vrg_source_ip[6] &&
	     fn_target_max_prio_and_max_id0_vrg_source_prio[20:18] >
	     IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d77 &&
	     CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q6 ;
  assign fn_target_max_prio_and_max_id0_vrg_source_ip_B_ETC___d94 =
	     fn_target_max_prio_and_max_id0_vrg_source_ip[7] &&
	     fn_target_max_prio_and_max_id0_vrg_source_prio[23:21] >
	     IF_fn_target_max_prio_and_max_id0_vrg_source_i_ETC___d86 &&
	     CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q7 ;
  always@(fn_target_max_prio_and_max_id0_target_id or
	  fn_target_max_prio_and_max_id0_vvrg_ie)
  begin
    case (fn_target_max_prio_and_max_id0_target_id)
      5'd0:
	  CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q1 =
	      fn_target_max_prio_and_max_id0_vvrg_ie[1];
      5'd1:
	  CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q1 =
	      fn_target_max_prio_and_max_id0_vvrg_ie[18];
      default: CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q1 =
		   1'b0 /* unspecified value */ ;
    endcase
  end
  always@(fn_target_max_prio_and_max_id0_target_id or
	  fn_target_max_prio_and_max_id0_vvrg_ie)
  begin
    case (fn_target_max_prio_and_max_id0_target_id)
      5'd0:
	  CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q2 =
	      fn_target_max_prio_and_max_id0_vvrg_ie[2];
      5'd1:
	  CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q2 =
	      fn_target_max_prio_and_max_id0_vvrg_ie[19];
      default: CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q2 =
		   1'b0 /* unspecified value */ ;
    endcase
  end
  always@(fn_target_max_prio_and_max_id0_target_id or
	  fn_target_max_prio_and_max_id0_vvrg_ie)
  begin
    case (fn_target_max_prio_and_max_id0_target_id)
      5'd0:
	  CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q3 =
	      fn_target_max_prio_and_max_id0_vvrg_ie[3];
      5'd1:
	  CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q3 =
	      fn_target_max_prio_and_max_id0_vvrg_ie[20];
      default: CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q3 =
		   1'b0 /* unspecified value */ ;
    endcase
  end
  always@(fn_target_max_prio_and_max_id0_target_id or
	  fn_target_max_prio_and_max_id0_vvrg_ie)
  begin
    case (fn_target_max_prio_and_max_id0_target_id)
      5'd0:
	  CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q4 =
	      fn_target_max_prio_and_max_id0_vvrg_ie[4];
      5'd1:
	  CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q4 =
	      fn_target_max_prio_and_max_id0_vvrg_ie[21];
      default: CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q4 =
		   1'b0 /* unspecified value */ ;
    endcase
  end
  always@(fn_target_max_prio_and_max_id0_target_id or
	  fn_target_max_prio_and_max_id0_vvrg_ie)
  begin
    case (fn_target_max_prio_and_max_id0_target_id)
      5'd0:
	  CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q5 =
	      fn_target_max_prio_and_max_id0_vvrg_ie[5];
      5'd1:
	  CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q5 =
	      fn_target_max_prio_and_max_id0_vvrg_ie[22];
      default: CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q5 =
		   1'b0 /* unspecified value */ ;
    endcase
  end
  always@(fn_target_max_prio_and_max_id0_target_id or
	  fn_target_max_prio_and_max_id0_vvrg_ie)
  begin
    case (fn_target_max_prio_and_max_id0_target_id)
      5'd0:
	  CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q6 =
	      fn_target_max_prio_and_max_id0_vvrg_ie[6];
      5'd1:
	  CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q6 =
	      fn_target_max_prio_and_max_id0_vvrg_ie[23];
      default: CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q6 =
		   1'b0 /* unspecified value */ ;
    endcase
  end
  always@(fn_target_max_prio_and_max_id0_target_id or
	  fn_target_max_prio_and_max_id0_vvrg_ie)
  begin
    case (fn_target_max_prio_and_max_id0_target_id)
      5'd0:
	  CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q7 =
	      fn_target_max_prio_and_max_id0_vvrg_ie[7];
      5'd1:
	  CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q7 =
	      fn_target_max_prio_and_max_id0_vvrg_ie[24];
      default: CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q7 =
		   1'b0 /* unspecified value */ ;
    endcase
  end
  always@(fn_target_max_prio_and_max_id0_target_id or
	  fn_target_max_prio_and_max_id0_vvrg_ie)
  begin
    case (fn_target_max_prio_and_max_id0_target_id)
      5'd0:
	  CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q8 =
	      fn_target_max_prio_and_max_id0_vvrg_ie[8];
      5'd1:
	  CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q8 =
	      fn_target_max_prio_and_max_id0_vvrg_ie[25];
      default: CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q8 =
		   1'b0 /* unspecified value */ ;
    endcase
  end
  always@(fn_target_max_prio_and_max_id0_target_id or
	  fn_target_max_prio_and_max_id0_vvrg_ie)
  begin
    case (fn_target_max_prio_and_max_id0_target_id)
      5'd0:
	  CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q9 =
	      fn_target_max_prio_and_max_id0_vvrg_ie[9];
      5'd1:
	  CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q9 =
	      fn_target_max_prio_and_max_id0_vvrg_ie[26];
      default: CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q9 =
		   1'b0 /* unspecified value */ ;
    endcase
  end
  always@(fn_target_max_prio_and_max_id0_target_id or
	  fn_target_max_prio_and_max_id0_vvrg_ie)
  begin
    case (fn_target_max_prio_and_max_id0_target_id)
      5'd0:
	  CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q10 =
	      fn_target_max_prio_and_max_id0_vvrg_ie[10];
      5'd1:
	  CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q10 =
	      fn_target_max_prio_and_max_id0_vvrg_ie[27];
      default: CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q10 =
		   1'b0 /* unspecified value */ ;
    endcase
  end
  always@(fn_target_max_prio_and_max_id0_target_id or
	  fn_target_max_prio_and_max_id0_vvrg_ie)
  begin
    case (fn_target_max_prio_and_max_id0_target_id)
      5'd0:
	  CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q11 =
	      fn_target_max_prio_and_max_id0_vvrg_ie[11];
      5'd1:
	  CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q11 =
	      fn_target_max_prio_and_max_id0_vvrg_ie[28];
      default: CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q11 =
		   1'b0 /* unspecified value */ ;
    endcase
  end
  always@(fn_target_max_prio_and_max_id0_target_id or
	  fn_target_max_prio_and_max_id0_vvrg_ie)
  begin
    case (fn_target_max_prio_and_max_id0_target_id)
      5'd0:
	  CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q12 =
	      fn_target_max_prio_and_max_id0_vvrg_ie[12];
      5'd1:
	  CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q12 =
	      fn_target_max_prio_and_max_id0_vvrg_ie[29];
      default: CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q12 =
		   1'b0 /* unspecified value */ ;
    endcase
  end
  always@(fn_target_max_prio_and_max_id0_target_id or
	  fn_target_max_prio_and_max_id0_vvrg_ie)
  begin
    case (fn_target_max_prio_and_max_id0_target_id)
      5'd0:
	  CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q13 =
	      fn_target_max_prio_and_max_id0_vvrg_ie[13];
      5'd1:
	  CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q13 =
	      fn_target_max_prio_and_max_id0_vvrg_ie[30];
      default: CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q13 =
		   1'b0 /* unspecified value */ ;
    endcase
  end
  always@(fn_target_max_prio_and_max_id0_target_id or
	  fn_target_max_prio_and_max_id0_vvrg_ie)
  begin
    case (fn_target_max_prio_and_max_id0_target_id)
      5'd0:
	  CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q14 =
	      fn_target_max_prio_and_max_id0_vvrg_ie[14];
      5'd1:
	  CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q14 =
	      fn_target_max_prio_and_max_id0_vvrg_ie[31];
      default: CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q14 =
		   1'b0 /* unspecified value */ ;
    endcase
  end
  always@(fn_target_max_prio_and_max_id0_target_id or
	  fn_target_max_prio_and_max_id0_vvrg_ie)
  begin
    case (fn_target_max_prio_and_max_id0_target_id)
      5'd0:
	  CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q15 =
	      fn_target_max_prio_and_max_id0_vvrg_ie[15];
      5'd1:
	  CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q15 =
	      fn_target_max_prio_and_max_id0_vvrg_ie[32];
      default: CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q15 =
		   1'b0 /* unspecified value */ ;
    endcase
  end
  always@(fn_target_max_prio_and_max_id0_target_id or
	  fn_target_max_prio_and_max_id0_vvrg_ie)
  begin
    case (fn_target_max_prio_and_max_id0_target_id)
      5'd0:
	  CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q16 =
	      fn_target_max_prio_and_max_id0_vvrg_ie[16];
      5'd1:
	  CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q16 =
	      fn_target_max_prio_and_max_id0_vvrg_ie[33];
      default: CASE_fn_target_max_prio_and_max_id0_target_id__ETC__q16 =
		   1'b0 /* unspecified value */ ;
    endcase
  end
endmodule  // module_fn_target_max_prio_and_max_id0
