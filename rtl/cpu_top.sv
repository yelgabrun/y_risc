`timescale 1ns/100ps

module cpu_top(
  input         rst_n,
  input         wr_en,
//  input  [ 4:0] rs1_i,
//  input  [ 4:0] rs2_i,
//  input  [ 4:0] wrd_i,
  input  [ 6:0] alu_op_i,
  input  [31:0] wdata_i,
  input  [31:0] mem_rdata_i,
  output [31:0] alu_result_o,
  output        z_flag_o

);

  wire sysclk;
  wire [31:0] rs1_data, rs2_data, instruction_s, alu_result_s;

  assign alu_result_o = alu_result_s;

  // Instantiation of a clk_gen block
  clk_gen clk_gen_inst(.clk(sysclk));

  // Fetch: includes PC + instruction memory
  ifu ifu_inst(.clk(sysclk),
               .rst_n(rst_n),
               .instruction_o(instruction_s));

  // Decode: includes a regfile (minimal decode for now) TODO: improve decode
  // stage
  // Instantiation of a register file with 32x 32-bit registers
  regfile regfile_inst(.clk    (sysclk),
                       .rst_n  (rst_n),
                       .wr_en  (wr_en),
                       .rs1_i  (instruction_s[19:15]),
                       .rs2_i  (instruction_s[24:20]),
                       .wrd_i  (instruction_s[11: 7]),
                       .wdata_i(alu_result_s),
                       .rs1_o  (rs1_data),
                       .rs2_o  (rs2_data)
                       );

  // Execute: includes ALU module
  alu alu_inst (
    .instruction_i(instruction_s),
    .rs1_data_i   (rs1_data),
    .rs2_data_i   (rs2_data),
    .result_o     (alu_result_s)
  );
endmodule
