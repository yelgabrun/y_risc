`timescale 1ns/100ps

module regfile #(parameter NUM_REGS=32)
(
  input          clk,     // Input clock
  input          rst_n,   // Reset (active-low)
  input          wr_en,   // Enable register write
  input   [ 4:0] rs1_i,   // Read source register 1
  input   [ 4:0] rs2_i,   // Read source register 2
  input   [ 4:0] wrd_i,   // Write destination register
  input   [31:0] wdata_i, // Write data in
  output  wire [31:0] rs1_o,   // Read data for RS1
  output  wire [31:0] rs2_o    // Read data for RS2
);
    

  reg [31:0] x [0:NUM_REGS-1];
//  logic [31:0] din  [0:NUM_REGS-1];

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
    begin
//      din[wrd_i] <= 32'd0;
//      x[wrd_i] <= 32'd0;
      x[ 0] <= 32'd0;
      x[ 1] <= 32'd0;
      x[ 2] <= 32'd0;
      x[ 3] <= 32'd0;
      x[ 4] <= 32'd0;
      x[ 5] <= 32'd0;
      x[ 6] <= 32'd0;
      x[ 7] <= 32'd0;
      x[ 8] <= 32'd0;
      x[ 9] <= 32'd0;
      x[10] <= 32'd0;
      x[11] <= 32'd0;
      x[12] <= 32'd0;
      x[13] <= 32'd0;
      x[14] <= 32'd0;
      x[15] <= 32'd0;
      x[16] <= 32'd0;
      x[17] <= 32'd0;
      x[18] <= 32'd0;
      x[19] <= 32'd0;
      x[20] <= 32'd0;
      x[21] <= 32'd0;
      x[22] <= 32'd0;
      x[23] <= 32'd0;
      x[24] <= 32'd0;
      x[25] <= 32'd0;
      x[26] <= 32'd0;
      x[27] <= 32'd0;
      x[28] <= 32'd0;
      x[29] <= 32'd0;
      x[30] <= 32'd0;
      x[31] <= 32'd0;
    end
    else if (wr_en && (wrd_i != 5'd0)) begin
//      din[wrd_i] <= wdata_i;
      x[wrd_i] <= wdata_i;
    end
  end
    

  assign rs1_o = x[rs1_i];
  assign rs2_o = x[rs2_i];

endmodule
