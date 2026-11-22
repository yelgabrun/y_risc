`timescale 1ns/100ps

module  main_memory(
  input              clk_i,
  input  wire [31:0] instruction_address_i,
  input  wire [31:0] data_address_i,
  input              data_read_en_i,
  input       [ 2:0] funct3_i,
  output reg  [31:0] instruction_o, 
  output reg  [31:0] load_data_o 
);

//  reg [31:0] main_mem [0:4095]; // 16KB instruction memory.
  reg [31:0] main_mem [0:1023]; // 4KB instruction memory.

  initial begin
    $readmemb("main.mem", main_mem);
  end

  // memory read process
//  always @(posedge clk_i)
  always_comb //@*
  begin
//    instruction_o = 32'd0;
    load_data_o   = 32'd0;
    instruction_o = main_mem[instruction_address_i[11:2]]; // Omitting bits 1:0 since instructions always aligned
    if (data_read_en_i)
    begin
      case (funct3_i)
        3'b000: load_data_o = {{24{1'b0}},main_mem[data_address_i[11:2]][7:0]}; // Data can be byte/HW/W-aligned
        3'b100: load_data_o = {{20{main_mem[11]}},main_mem[data_address_i[11:0]][7:0]}; // Data can be byte/HW/W-aligned
        3'b001: load_data_o = {{24{1'b0}},main_mem[data_address_i[11:1]][15:0]}; // Data can be byte/HW/W-aligned
        3'b101: load_data_o = {{20{main_mem[11]}},main_mem[data_address_i[11:1]][15:0]}; // Data can be byte/HW/W-aligned
        3'b010: load_data_o = main_mem[data_address_i[11:2]];
        default: load_data_o = 32'd0; 
      endcase
//      load_data_o = main_mem[data_address_i[11:0]]; // Data can be byte/HW/W-aligned
    end
  end

endmodule

