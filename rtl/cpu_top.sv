`timescale 1ns/100ps

module cpu_top(
  input         rst_n,
  input         wr_en,
//  input  [ 4:0] rs1_i,
//  input  [ 4:0] rs2_i,
//  input  [ 4:0] wrs_i,
  input  [ 3:0] alu_op_i,
  input  [31:0] wdata_i,
  input  [31:0] mem_rdata_i,
  output [31:0] alu_result_o,
  output        z_flag_o

);

  wire sysclk;
  wire [31:0] rs1_data, rs2_data, instruction_s;

  // Instantiation of a clk_gen block
  clk_gen clk_gen_inst(.clk(sysclk));

  ifu ifu_inst(.clk(sysclk),
               .rst_n(rst_n),
               .instruction_o(instruction_s));

  // Instantiation of a reg32bit block
  regfile regfile_inst(.clk    (sysclk),
                       .rst_n  (rst_n),
                       .wr_en  (wr_en),
                       .rs1_i  (instruction_s[25:21]),
                       .rs2_i  (instruction_s[20:16]),
                       .wrs_i  (instruction_s[15:11]),
                       .wdata_i(wdata_i),
                       .rs1_o  (rs1_data),
                       .rs2_o  (rs2_data)
                       );

  alu alu_inst (
                .data1_i  (rs1_data),
                .data2_i  (rs2_data),
                .alu_op_i (alu_op_i),
                .zero_o   (z_flag_o),
                .result_o (alu_result_o)
               );

  endmodule
