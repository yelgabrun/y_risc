`timescale 1ns/100ps

module regfile #(parameter NUM_REGS=32)
(
  input          clk,     // Input clock
  input          rst_n,   // Reset (active-low)
  input          wr_en,   // Enable register write
  input   [ 4:0] rs1_i,   // Read source register 1
  input   [ 4:0] rs2_i,   // Read source register 2
  input   [ 4:0] wrs_i,   // Write register
  input   [31:0] wdata_i, // Write data in
  output  wire [31:0] rs1_o,   // Read data for RS1
  output  wire [31:0] rs2_o    // Read data for RS2
);
    

  reg [31:0] qout [0:NUM_REGS-1];
//  logic [31:0] din  [0:NUM_REGS-1];

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
    begin
//      din[wrs_i] <= 32'd0;
//      qout[wrs_i] <= 32'd0;
      qout[0] <= 32'd0;
      qout[1] <= 32'd0;
      qout[2] <= 32'd0;
      qout[3] <= 32'd0;
      qout[4] <= 32'd0;
      qout[5] <= 32'd0;
      qout[6] <= 32'd0;
      qout[7] <= 32'd0;
      qout[8] <= 32'd0;
      qout[9] <= 32'd0;
      qout[10] <= 32'd0;
      qout[11] <= 32'd0;
      qout[12] <= 32'd0;
      qout[13] <= 32'd0;
      qout[14] <= 32'd0;
      qout[15] <= 32'd0;
      qout[16] <= 32'd0;
      qout[17] <= 32'd0;
      qout[18] <= 32'd0;
      qout[19] <= 32'd0;
      qout[20] <= 32'd0;
      qout[21] <= 32'd0;
      qout[22] <= 32'd0;
      qout[23] <= 32'd0;
      qout[24] <= 32'd0;
      qout[25] <= 32'd0;
      qout[26] <= 32'd0;
      qout[27] <= 32'd0;
      qout[28] <= 32'd0;
      qout[29] <= 32'd0;
      qout[30] <= 32'd0;
      qout[31] <= 32'd0;
    end
    else if (wr_en && (wrs_i != 5'd0)) begin
//      din[wrs_i] <= wdata_i;
      qout[wrs_i] <= wdata_i;
    end
  end
    

  assign rs1_o = qout[rs1_i];
  assign rs2_o = qout[rs2_i];

endmodule
