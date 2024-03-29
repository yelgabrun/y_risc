`timescale 1ns/100ps

// Instruction Fetch Unit
module ifu (
  input   clk,
  input   rst_n,
  output  [31:0] pc_o
//  output  [31:0] instruction_o
);

  wire [31:0] next_pc;
//  wire [31:0] inst;

  // Program Counter 32-bit register
  reg32bit reg32bit_pc_inst(.clk  (clk),
                            .rst_n(rst_n),
                            //.reset_value_i(32'h80000180),
                            .reset_value_i(32'h00000000), // Location of first instruction
                            .wr_en_i(1'b1), // PC write_enable tied high for now
                            .reg_i(next_pc),
                            .reg_o(pc_o));

  assign next_pc = pc_o + 32'd4; // Add 4 bytes for the next instruction address



endmodule
