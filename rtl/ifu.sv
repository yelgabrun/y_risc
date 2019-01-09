`timescale 1ns/100ps

module ifu (
  input  wire clk,
  input  wire rst_n,
  output wire [31:0] instruction
);

  wire [31:0] next_pc;
  wire [31:0] pc;
  wire [31:0] inst;

  instruction_memory instruction_memory_inst(.address(pc),
                                             .instruction(instruction));

  reg32bit reg32bit_pc_inst(.clk  (clk),
                            .rst_n(rst_n),
                            .wr_en(1'b1),
                            .reg_i(next_pc),
                            .reg_o(pc));

  assign next_pc = pc + 32'd1;

//  regfile regfile_inst(.clk    (clk),
//                       .rst_n  (rst_n),
//                       .wr_en  (1'b1),
//                       .rs1_i  (instruction[25:21]),
//                       .rs2_i  (instruction[20:16]),
//                       .wrs_i  (instruction[15:11]),
//                       .wdata_i(instruction[15: 0]),
//                       .rs1_o  (),
//                       .rs2_o  ());

//  alu alu_inst(.(),
//               .(),
//               .(),
//               .());


endmodule
