`timescale 1ns/100ps

module alu (
  input  wire [31:0] data1_i,
  input  wire [31:0] data2_i,
  input  wire [ 3:0] alu_op_i,
  output wire        zero_o,
  output reg [31:0]  result_o
);

//  typedef enum logic [4:0] {ADD, SUB, MUL, DIV, AND, OR, XOR, NOT, LEZ, LTZ, GTZ, EQT, NET} operation_t;
  localparam logic [4:0] ADD = 4'b0000;
  localparam logic [4:0] SUB = 4'b0001;
  localparam logic [4:0] MUL = 4'b0010;
  localparam logic [4:0] DIV = 4'b0011;
  localparam logic [4:0] AND = 4'b0100;
  localparam logic [4:0] OR  = 4'b0101;
  localparam logic [4:0] XOR = 4'b0110;
  localparam logic [4:0] NOT = 4'b0111;
  localparam logic [4:0] LEZ = 4'b1000;
  localparam logic [4:0] LTZ = 4'b1001;
  localparam logic [4:0] GTZ = 4'b1010;
  localparam logic [4:0] EQT = 4'b1011;
  localparam logic [4:0] NET = 4'b1100;

  always @(*) 
  begin
    case(alu_op_i)
      ADD:
        result_o = data1_i + data2_i; 
      SUB: 
        result_o = data1_i - data2_i; 
      MUL:
        result_o = data1_i * data2_i; 
      DIV:
        result_o = data1_i / data2_i; 
      AND:
        result_o = data1_i & data2_i; 
      OR:
        result_o = data1_i | data2_i; 
      XOR:
        result_o = data1_i ^ data2_i; 
      NOT:
        result_o = !data1_i; 
      LEZ:
        result_o = (data1_i <= 32'd0); 
      LTZ: 
        result_o = (data1_i < 32'd0); 
      GTZ:
        result_o = (data1_i > 32'd0); 
      EQT: 
        result_o = data1_i == data2_i; 
      NET:
        result_o = data1_i != data2_i; 
      default: 
        result_o = data1_i;
    endcase
      
  end

  assign zero_o = !(|result_o);

endmodule
