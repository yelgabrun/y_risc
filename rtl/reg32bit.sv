`timescale 1ns/100ps

module reg32bit (
  input        clk,
  input        rst_n,
  input [31:0] reset_value_i,
  input        wr_en_i,
  input  wire [31:0] reg_i,
  output reg  [31:0] reg_o
);


  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      reg_o <= reset_value_i;
    else if (wr_en_i)
      reg_o <= reg_i;
    else
      reg_o <= reg_o;
  end

endmodule
