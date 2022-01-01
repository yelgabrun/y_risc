`timescale 1ns/100ps

module decode 
  (
    input              clk_i,
    input              rst_n_i,
    input              wr_en_i,
    input       [31:0] instruction_i,
    input       [31:0] alu_result_i,
    input       [31:0] load_data_i,
    output      [ 2:0] funct3_o,
    output             op_type_o,
    output      [11:0] imm_o,
    output reg  [ 4:0] shamt_o,
    output reg         load_en_o,
    output      [31:0] rs1_data_o,
    output reg  [31:0] operand2_o
  );

  wire [ 6:0] opcode_s;
  wire [31:0] rs2_data_s;
  reg [31:0] rf_wdata_q;
  // Decode: includes a regfile (minimal decode for now) TODO: improve decode
  // stage
  // Instantiation of a register file with 32x 32-bit registers
//  assign rf_wdata_q = load_en_o ? load_data_i : alu_result_i;

//  always @(posedge clk_i or negedge rst_n_i)
  always @*
  begin
//    if (!rst_n_i)
      rf_wdata_q = 32'd0;
//    else
      rf_wdata_q = load_en_o ? load_data_i : alu_result_i;
  end

  regfile regfile_inst(.clk    (clk_i),
                       .rst_n  (rst_n_i),
                       .wr_en  (wr_en_i),
                       .rs1_i  (instruction_i[19:15]),
                       .rs2_i  (instruction_i[24:20]),
                       .rd_i   (instruction_i[11: 7]),
                       .wdata_i(rf_wdata_q),
                       .rs1_o  (rs1_data_o),
                       .rs2_o  (rs2_data_s)
                       );

  assign op_type_o = instruction_i[31];
  assign imm_o     = instruction_i[31:20];
  assign opcode_s  = instruction_i[ 6: 0];
  assign funct3_o  = instruction_i[14:12];

  always @(*)
  begin
    operand2_o   = 32'd0;
    shamt_o      = 5'd0;
    load_en_o    = 1'b0;
    case(opcode_s)
      7'b0110011:
      begin
        operand2_o   = rs2_data_s;
        shamt_o      = rs2_data_s[4:0];
      end
      7'b0010011: 
      begin
        operand2_o   = {{20{imm_o[11]}}, imm_o};
        shamt_o      = instruction_i[24:20];
      end
      7'b0000011: 
      begin
        load_en_o   = 1'b1;
      end
      default: begin end
    endcase
  end
endmodule
