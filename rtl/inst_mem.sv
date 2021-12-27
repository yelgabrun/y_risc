`timescale 1ns/100ps

module  instruction_memory(
  input  wire [31:0] address_i,
  output reg  [31:0] instruction_o 
);

  reg [31:0] imem [0:255]; // 1KB instruction memory.
  
  initial begin
    $readmemh("inst.mem", imem);
  end

  always @(*)
  begin
    instruction_o = 32'd0;
    instruction_o = imem[address_i[9:2]];
  end

endmodule

