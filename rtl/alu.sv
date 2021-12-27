`timescale 1ns/100ps

module alu (
  input  wire [31:0] instruction_i,
  input  wire [31:0] rs1_data_i,
  input  wire [31:0] rs2_data_i,
//  input  wire [ 6:0] alu_opcode_i,
//  input  wire [ 2:0] alu_funct3_i,
//  input  wire [ 6:0] alu_funct7_i,
//  output wire        zero_o,
  output reg [31:0]  result_o
);

  wire [ 6:0] alu_opcode_s;
  wire [ 2:0] alu_funct3_s;
  wire [ 6:0] alu_funct7_s;
  reg  [ 4:0] shamt_s;
  wire [11:0] imm_s;
  reg  [31:0] operand2_s;
//  typedef enum logic [4:0] {ADD, SUB, MUL, DIV, AND, OR, XOR, NOT, LEZ, LTZ, GTZ, EQT, NET} operation_t;
  parameter logic [6:0] RTYPE = 7'b0110011;
  parameter logic [6:0] ITYPE = 7'b0010011;

//  localparam logic [2:0] SUB  = 3'b000; // Shared funct3
  parameter logic [2:0] ADD_SUB  = 3'b000; // Shared funct3
  parameter logic [2:0] SLL      = 3'b001;
  parameter logic [2:0] SLT      = 3'b010;
  parameter logic [2:0] SLTU     = 3'b011;
  parameter logic [2:0] XOR      = 3'b100;
  parameter logic [2:0] SRL_SRA  = 3'b101; // Shared funct3
  parameter logic [2:0] OR       = 3'b110;
  parameter logic [2:0] AND      = 3'b111;

  parameter logic [2:0] ADDI      = 3'b000;
  parameter logic [2:0] SLTI      = 3'b010;
  parameter logic [2:0] SLTIU     = 3'b011;
  parameter logic [2:0] XORI      = 3'b100;
  parameter logic [2:0] ORI       = 3'b110;
  parameter logic [2:0] ANDI      = 3'b111;

  parameter logic [2:0] SLLI      = 3'b001;
  parameter logic [2:0] SRLI_SRAI = 3'b101; // Shared funct3

  assign imm_s        = instruction_i[31:20];
  assign alu_opcode_s = instruction_i[ 6: 0];
  assign alu_funct3_s = instruction_i[14:12];

//
//funct7   rs2    rs1  funct3  rd  opcode
//0000000  rs2    rs1  000     rd  0110011  ADD
//0100000  rs2    rs1  000     rd  0110011  SUB
//0000000  rs2    rs1  001     rd  0110011  SLL
//0000000  rs2    rs1  010     rd  0110011  SLT
//0000000  rs2    rs1  011     rd  0110011  SLTU
//0000000  rs2    rs1  100     rd  0110011  XOR
//0000000  rs2    rs1  101     rd  0110011  SRL
//0100000  rs2    rs1  101     rd  0110011  SRA
//0000000  rs2    rs1  110     rd  0110011  OR
//0000000  rs2    rs1  111     rd  0110011  AND

  always @(*)
  begin
    operand2_s   = 32'd0;
    shamt_s      = 5'd0;
    case(alu_opcode_s)
      7'b0110011:
      begin
        operand2_s   = rs2_data_i;
        shamt_s      = rs2_data_i[4:0];
      end
      7'b0010011: 
      begin
        operand2_s   = {{20{imm_s[11]}}, imm_s};
        shamt_s      = instruction_i[24:20];
      end
      default: begin end
    endcase
  end

  always @(*) 
  begin
    case (alu_funct3_s)
      3'b000: result_o = (instruction_i[30]) ? (rs1_data_i - operand2_s) : (rs1_data_i + operand2_s); 
      3'b010: result_o = { 31'd0, ($signed(rs1_data_i) < $signed(operand2_s)) }; 
      3'b011: result_o = { 31'd0, (rs1_data_i < operand2_s) }; 
      3'b100: result_o = rs1_data_i ^  operand2_s;
      3'b110: result_o = rs1_data_i |  operand2_s;
      3'b111: result_o = rs1_data_i &  operand2_s;  
      3'b001: result_o = (rs1_data_i << shamt_s);
      3'b101: result_o = (instruction_i[30]) ? (rs1_data_i >>> shamt_s) : (rs1_data_i >> shamt_s);
      default:
        result_o = 32'hDEADC0DE; 
    endcase
  end

//Immediate      rs1  f3   rd  opcode
//imm[11:0]      rs1  000  rd  0010011  ADDI
//imm[11:0]      rs1  010  rd  0010011  SLTI
//imm[11:0]      rs1  011  rd  0010011  SLTIU
//imm[11:0]      rs1  100  rd  0010011  XORI
//imm[11:0]      rs1  110  rd  0010011  ORI
//imm[11:0]      rs1  111  rd  0010011  ANDI
//0000000 shamt  rs1  001  rd  0010011  SLLI
//0000000 shamt  rs1  101  rd  0010011  SRLI
//0100000 shamt  rs1  101  rd  0010011  SRAI
 
//  assign zero_o = !(|result_o);

endmodule
