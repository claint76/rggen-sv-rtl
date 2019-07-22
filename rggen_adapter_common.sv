module rggen_adapter_common #(
  parameter int BUS_WIDTH = 32,
  parameter int REGISTERS = 1
)(
  input logic             i_clk,
  input logic             i_rst_n,
  rggen_bus_if.slave      bus_if,
  rggen_register_if.host  register_if[REGISTERS]
);
  import  rggen_rtl_pkg::*;

  genvar  i;

  //  State
  logic busy;

  always_ff @(posedge i_clk, negedge i_rst_n) begin
    if (!i_rst_n) begin
      busy  <= '0;
    end
    else if (bus_if.ready) begin
      busy  <= '0;
    end
    else if (bus_if.valid) begin
      busy  <= '1;
    end
  end

  //  Request
  generate for (i = 0;i < REGISTERS;++i) begin : g_request
    assign  register_if[i].valid      = (bus_if.valid && (!busy)) ? '1 : '0;
    assign  register_if[i].address    = bus_if.address;
    assign  register_if[i].write      = bus_if.write;
    assign  register_if[i].write_data = bus_if.write_data;
    assign  register_if[i].strobe     = bus_if.strobe;
  end endgenerate

  //  Response
  localparam  int STATUS_WIDTH  = $bits(rggen_status);

  logic [REGISTERS-0:0]     ready;
  logic [REGISTERS-1:0]     active;
  logic [STATUS_WIDTH-1:0]  status[REGISTERS+1];
  logic [BUS_WIDTH-1:0]     read_data[REGISTERS];

  assign  ready[REGISTERS]  = ~|active;
  assign  status[REGISTERS] = RGGEN_OKAY;

  generate for (i = 0;i < REGISTERS;++i) begin : g_response
    assign  ready[i]      = register_if[i].ready;
    assign  active[i]     = register_if[i].active;
    assign  status[i]     = register_if[i].status;
    assign  read_data[i]  = register_if[i].read_data;
  end endgenerate

  rggen_mux #(STATUS_WIDTH, REGISTERS + 1) u_status_mux();
  rggen_mux #(BUS_WIDTH   , REGISTERS + 0) u_read_data_mux();

  assign  bus_if.ready      = |ready;
  assign  bus_if.status     = rggen_status'(u_status_mux.mux(ready, status));
  assign  bus_if.read_data  = u_read_data_mux.mux(ready[REGISTERS-1:0], read_data);
endmodule