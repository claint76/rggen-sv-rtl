module rggen_bit_field_ro #(
  parameter int WIDTH = 8
)(
  rggen_bit_field_if.bit_field  bit_field_if,
  input logic [WIDTH-1:0]       i_value
);
  assign  bit_field_if.read_data  = i_value;
  assign  bit_field_if.value      = i_value;
endmodule
