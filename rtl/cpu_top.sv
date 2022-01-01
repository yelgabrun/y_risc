`timescale 1ns/100ps

module cpu_top(
  input         rst_n_i,
  input         wr_en_i,
//  input  [ 4:0] rs1_i,
//  input  [ 4:0] rs2_i,
//  input  [ 4:0] wrd_i,
  input  [ 6:0] alu_op_i,
  input  [31:0] wdata_i,
  input  [31:0] mem_rdata_i,
  output [31:0] alu_result_o,
  output        z_flag_o

);

  wire sysclk, op_type_s, data_read_en_s, load_en_s;
  wire [31:0] rs1_data_s, operand2_s, instruction_s, alu_result_s, ld_address_s;
  wire [ 4:0] shamt_s;
  wire [11:0] imm_s;
  wire [ 2:0] funct3_s;
  wire [31:0] pc_s, data_address_s, load_data_s;

  assign alu_result_o = alu_result_s;

  // Instantiation of a clk_gen block
  clk_gen i_clk_gen(.clk(sysclk));

  // Fetch: includes PC + instruction memory
  ifu i_ifu(
    .clk  (sysclk),
    .rst_n(rst_n_i),
    .pc_o (pc_s)
  );

  assign data_address_s = ld_address_s;
  assign data_read_en_s = load_en_s;
  main_memory i_main_memory(
    .clk_i                (sysclk),
    .instruction_address_i(pc_s),
    .data_address_i       (data_address_s),
    .data_read_en_i       (data_read_en_s),
    .instruction_o        (instruction_s),
    .load_data_o          (load_data_s)
  );

  decode i_decode(
    .clk_i         (sysclk),
    .rst_n_i       (rst_n_i),
    .wr_en_i       (wr_en_i),
    .instruction_i (instruction_s),
    .alu_result_i  (alu_result_s),
    .load_data_i   (load_data_s),
    .funct3_o      (funct3_s),
    .op_type_o     (op_type_s),
    .imm_o         (imm_s),
    .shamt_o       (shamt_s),
    .load_en_o     (load_en_s),
    .rs1_data_o    (rs1_data_s),
    .operand2_o    (operand2_s)
  );

  // Execute: includes ALU module
  alu i_alu(
    .op_type_i    (op_type_s),
    .rs1_data_i   (rs1_data_s),
    .operand2_i   (operand2_s),
    .funct3_i     (funct3_s),
    .shamt_i      (shamt_s),
    .alu_result_o (alu_result_s)
  );

  ld_st_unit i_ld_st_unit(
    .clk_i        (sysclk),
    .rst_n_i      (rst_n_i),
    .load_en_i    (load_en_s),
    .funct3_i     (funct3_s),
    .offset_i     (imm_s),
    .rs1_data_i   (rs1_data_s),
    .ld_address_o (ld_address_s)
  
  );

endmodule
