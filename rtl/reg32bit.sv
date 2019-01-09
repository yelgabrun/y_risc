`timescale 1ns/100ps

module reg32bit (
  input        clk,
  input        rst_n,
  input        wr_en,
  input  wire [31:0] reg_i,
  output reg  [31:0] reg_o
);

  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      reg_o <= 32'h00;
    else if (wr_en)
      reg_o <= reg_i;
    else
      reg_o <= reg_o;
  end
    
endmodule
