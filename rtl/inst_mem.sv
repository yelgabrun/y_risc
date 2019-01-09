`timescale 1ns/100ps

module  instruction_memory(
  input  wire [31:0] address,
  output reg  [31:0] instruction 
);

  //reg [31:0] imem [0:1073741823];
  reg [31:0] imem [0:1023];
  
  initial begin
    $readmemh("inst.mem", imem);
  end

  always @(*)
  begin
    instruction = 32'd0;
    instruction = imem[address[31:0]];
  end

endmodule

