package Debug_Triage;
// We assume that only one debug module transaction happens at a time, so e.g. there is never
// any danger of head-of-queue blocking.

// Lots more validity checking could be done.

import AXI4_Types ::*;
import Fabric_Defs ::*;
import ClientServer ::*;
import DM_CPU_Req_Rsp ::*;
import ISA_Decls ::*;
import Connectable ::*;
import GetPut ::*;
import Semi_FIFOF ::*;

interface Triage_Ifc;
   interface AXI4_Slave_IFC  #(Wd_Id, Wd_Addr, Wd_Data, Wd_User) server;
   interface AXI4_Master_IFC #(Wd_Id, Wd_Addr, Wd_Data, Wd_User) client;
endinterface

module mkDebugTriage #(Server #(Bool, Bool) reset_svr,
		       Server #(Bool, Bool) runHalt_svr,
		       Server #(DM_CPU_Req #(5,  XLEN), DM_CPU_Rsp #(XLEN))  gpr,
		       Server #(DM_CPU_Req #(12,  XLEN), DM_CPU_Rsp #(XLEN)) csr ) (Triage_Ifc);

   AXI4_Slave_Xactor_IFC  #(Wd_Id, Wd_Addr, Wd_Data, Wd_User)  input_Xactor <- mkAXI4_Slave_Xactor;
   AXI4_Master_Xactor_IFC #(Wd_Id, Wd_Addr, Wd_Data, Wd_User)  sbus_master  <- mkAXI4_Master_Xactor;

   Reg #(Bool) rg_writing <- mkRegU;

   rule read_req_rl;
      let read_req <- toGet(input_Xactor.o_rd_addr).get();
      case (read_req.arid)
	 0: /* to sbus */ sbus_master.i_rd_addr.enq(read_req);
	 1: /* reset */ begin
			   Bool running = (read_req.araddr[0] == 1);
			   reset_svr.request.put (running);
			end
	 2: /* run/halt */ begin
			      Bool running = (read_req.araddr[0] == 1);
			      runHalt_svr.request.put(running);
			   end
	 3: /* gpr read */ gpr.request.put(
	    DM_CPU_Req {write: False,
			address: truncate(read_req.araddr),
			data: (?)});
	 4: /* csr read */ csr.request.put(
	    DM_CPU_Req {write: False,
			address: truncate(read_req.araddr),
			data: (?)});
	 default: begin
		     $display("Invalid debug read request, arid = %0d", read_req.arid);
		     $finish(0);
		  end
      endcase
      rg_writing <= False;
   endrule

   // sbus response
   rule sbus_rsp_rl;
      let rsp <- toGet(sbus_master.o_rd_data).get();
      input_Xactor.i_rd_data.enq(rsp);
   endrule

   // reset response:
   rule reset_rsp_rl;
      let running <- reset_svr.response.get;
      input_Xactor.i_rd_data.enq(AXI4_Rd_Data {rid: 1, // for reset traffic
					       rdata: extend(pack(running)),
					       rresp: axi4_resp_okay,
					       rlast: True,
					       ruser: ?});
   endrule

   // run/halt response:
   rule runhalt_rsp_rl;
      let running <- runHalt_svr.response.get;
      input_Xactor.i_rd_data.enq(AXI4_Rd_Data {rid: 2, // for run/halt traffic
					       rdata: extend(pack(running)),
					       rresp: axi4_resp_okay,
					       rlast: True,
					       ruser: ?});
   endrule

   // gpr read response:
   rule gpr_rd_rsp_rl (!rg_writing);
      let x <- gpr.response.get;
      input_Xactor.i_rd_data.enq(AXI4_Rd_Data {rid: 3, // for gpr traffic
					       rdata: x.data,
					       rresp: axi4_resp_okay,
					       rlast: True,
					       ruser: ?});
   endrule

   // csr read response:
   rule csr_rd_rsp_rl (!rg_writing);
      let x <- csr.response.get;
      input_Xactor.i_rd_data.enq(AXI4_Rd_Data {rid: 4, // for csr traffic
					       rdata: x.data,
					       rresp: axi4_resp_okay,
					       rlast: True,
					       ruser: ?});
   endrule

   Reg #(Bool) rg_bursting <- mkReg(False);

   rule burst_tl (rg_bursting);
      let write_data <- toGet(input_Xactor.o_wr_data).get();
      sbus_master.i_wr_data.enq(write_data);
      rg_bursting <= ! write_data.wlast;
   endrule

   rule write_req_rl (!rg_bursting);
      let write_req  <- toGet(input_Xactor.o_wr_addr).get();
      let write_data <- toGet(input_Xactor.o_wr_data).get();
      case (write_req.awid)
	 0: /* to sbus */ begin
			     sbus_master.i_wr_addr.enq(write_req);
			     sbus_master.i_wr_data.enq(write_data);
			     rg_bursting <= ! write_data.wlast;
			  end
	 3: /* gpr write */ gpr.request.put(
	    DM_CPU_Req {write: True,
			address: truncate(write_req.awaddr),
			data: write_data.wdata});
	 4: /* csr write */ csr.request.put(
	    DM_CPU_Req {write: True,
			address: truncate(write_req.awaddr),
			data: write_data.wdata});
	 default: begin
		     $display("Invalid debug write request, awid = %0d", write_req.awid);
		     $finish(0);
		  end
      endcase
      rg_writing <= True;
   endrule

   // sbus response
   rule sbus_wr_rsp_rl;
      let rsp <- toGet(sbus_master.o_wr_resp).get();
      input_Xactor.i_wr_resp.enq(rsp);
   endrule

   // gpr write response:
   rule gpr_wr_rsp_rl (rg_writing);
      let x <- gpr.response.get;
      input_Xactor.i_wr_resp.enq(AXI4_Wr_Resp {bid: 3, // for gpr traffic
					       bresp: (x.ok ? axi4_resp_okay: axi4_resp_slverr),
					       buser: ?});
   endrule

   // csr write response:
   rule csr_wr_rsp_rl (rg_writing);
      let x <- csr.response.get;
      input_Xactor.i_wr_resp.enq(AXI4_Wr_Resp {bid: 4, // for csr traffic
					       bresp: (x.ok ? axi4_resp_okay: axi4_resp_slverr),
					       buser: ?});
   endrule

   interface server = input_Xactor.axi_side;
   interface client =  sbus_master.axi_side;
endmodule

endpackage
