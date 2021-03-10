package DM_CPU_Ifc;

import GetPut         ::*;
import ClientServer   ::*;
import Connectable    ::*;
import DM_CPU_Req_Rsp ::*;
import ISA_Decls      ::*;

interface CPU_DM_Ifc;
   // run-control, other
   interface Server #(Bool, Bool)  hart_reset_server;
   interface Server #(Bool, Bool)  hart_server_run_halt;
   interface Put #(Bit #(4))       hart_put_other_req;

   // GPR access
   interface Server #(DM_CPU_Req #(5,  XLEN), DM_CPU_Rsp #(XLEN)) hart_gpr_mem_server;

`ifdef ISA_F
   // FPR access
   interface Server #(DM_CPU_Req #(5,  FLEN), DM_CPU_Rsp #(FLEN)) hart_fpr_mem_server;
`endif

   // CSR access
   interface Server #(DM_CPU_Req #(12, XLEN), DM_CPU_Rsp #(XLEN)) hart_csr_mem_server;
endinterface

interface DM_CPU_Ifc;
   // run-control, other
   interface Client #(Bool, Bool)  hart_reset_client;
   interface Client #(Bool, Bool)  hart_client_run_halt;
   interface Get #(Bit #(4))       hart_get_other_req;

   // GPR access
   interface Client #(DM_CPU_Req #(5,  XLEN), DM_CPU_Rsp #(XLEN)) hart_gpr_mem_client;

`ifdef ISA_F
   // FPR access
   interface Client #(DM_CPU_Req #(5,  FLEN), DM_CPU_Rsp #(FLEN)) hart_fpr_mem_client;
`endif

   // CSR access
   interface Client #(DM_CPU_Req #(12, XLEN), DM_CPU_Rsp #(XLEN)) hart_csr_mem_client;
endinterface

instance Connectable #(CPU_DM_Ifc, DM_CPU_Ifc);
   module mkConnection #(CPU_DM_Ifc c, DM_CPU_Ifc d) (Empty);
      let h0rs <- mkConnection(c.hart_reset_server,    d.hart_reset_client);
      let h0rh <- mkConnection(c.hart_server_run_halt, d.hart_client_run_halt);
      let h0po <- mkConnection(c.hart_put_other_req,   d.hart_get_other_req);
      let h0gp <- mkConnection(c.hart_gpr_mem_server,  d.hart_gpr_mem_client);
      let h0cs <- mkConnection(c.hart_csr_mem_server,  d.hart_csr_mem_client);
`ifdef ISA_F
      let h0fp <- mkConnection(c.hart_fpr_mem_server,  d.hart_fpr_mem_client);
`endif
   endmodule
endinstance

instance Connectable #(DM_CPU_Ifc, CPU_DM_Ifc);
   module mkConnection #(DM_CPU_Ifc d, CPU_DM_Ifc c) (Empty);
      let cnx <- mkConnection(c, d);
   endmodule
endinstance

endpackage
