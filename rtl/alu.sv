`timescale 1ns/100ps

module alu (
  input              op_type_i,
  input  wire [31:0] rs1_data_i,
  input       [31:0] operand2_i,
  input  wire [ 2:0] funct3_i,
  input  wire [ 4:0] shamt_i,
  output reg  [31:0] alu_result_o
);

//  typedef enum logic [4:0] {ADD, SUB, MUL, DIV, AND, OR, XOR, NOT, LEZ, LTZ, GTZ, EQT, NET} operation_t;
//  parameter logic [6:0] RTYPE = 7'b0110011;
//  parameter logic [6:0] ITYPE = 7'b0010011;

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
    case (funct3_i)
      3'b000: alu_result_o = (op_type_i) ? (rs1_data_i - operand2_i) : (rs1_data_i + operand2_i); 
      3'b010: alu_result_o = { 31'd0, ($signed(rs1_data_i) < $signed(operand2_i)) }; 
      3'b011: alu_result_o = { 31'd0, (rs1_data_i < operand2_i) }; 
      3'b100: alu_result_o = rs1_data_i ^  operand2_i;
      3'b110: alu_result_o = rs1_data_i |  operand2_i;
      3'b111: alu_result_o = rs1_data_i &  operand2_i;  
      3'b001: alu_result_o = (rs1_data_i << shamt_i);
      3'b101: alu_result_o = (op_type_i) ? (rs1_data_i >>> shamt_i) : (rs1_data_i >> shamt_i);
      default:
        alu_result_o = 32'hDEADC0DE; 
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
 
//  assign zero_o = !(|alu_result_o);

endmodule
