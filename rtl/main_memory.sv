`timescale 1ns/100ps

module  main_memory(
  input              clk_i,
  input  wire [31:0] instruction_address_i,
  input  wire [31:0] data_address_i,
  input  wire        data_read_en_i,
  output reg  [31:0] instruction_o, 
  output reg  [31:0] load_data_o 
);

  reg [31:0] main_mem [0:4096]; // 16KB instruction memory.

  initial begin
    $readmemb("main.mem", main_mem);
  end

  // memory read process
  always @(posedge clk_i)
  begin
//    instruction_o = 32'd0;
//    load_data_o   = 32'd0;
    instruction_o <= main_mem[instruction_address_i[9:2]]; // Instructions always aligned
    if (data_read_en_i)
    begin
      load_data_o   <= main_mem[data_address_i[9:0]]; // Data can be byte/HW/W-aligned
    end
  end

endmodule

