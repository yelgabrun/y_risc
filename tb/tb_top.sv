`timescale 1ns/100ps

module tb_top;

  reg          rst_n;
  reg          wr_en    = 1'b0;
  reg   [ 4:0] rs1_i    = 5'd0;
  reg   [ 4:0] rs2_i    = 5'd0;
  reg   [ 4:0] wrd_i    = 5'd0;
  reg   [31:0] wdata_i  = 32'd0;
  reg   [ 6:0] alu_op_i = 4'd0;
  integer i;
      
  // Instantiation of a reg32bit block
  cpu_top cpu_top_inst(.rst_n_i(rst_n),
                       .wr_en_i(wr_en),
                       //.rs1_i(rs1_i),
                       //.rs2_i(rs2_i),
                       //.wrd_i(wrd_i),
                       .wdata_i(wdata_i),
                       .alu_op_i(alu_op_i),
                       .mem_rdata_i(32'd0),
                       .alu_result_o(),
                       .z_flag_o());

  // data signals
  //wire  [31:0] rs1_o;
  //wire  [31:0] rs2_o;

  // Generation of dumpfile for GTKWave
   initial begin
    $dumpfile("cpu_dump.vcd");
    $dumpvars(0, tb_top);//, clk_gen_inst, regfile_inst, reg_32bit_inst);
    for (i=0; i<32;i++)
      $dumpvars(0,cpu_top_inst.i_decode.regfile_inst.x[i]);
  end
 
  // Test procedure
  initial begin
    // reset
    rst_n = 1'b0;
    wdata_i  = 32'd0;
    #10
    rst_n = 1'b1;
    #1
    wr_en = 1'b1;
    
    #100
    #10000
//    wrd_i = 5'd13;
//    rs1_i = 5'd13;
//    wdata_i = 32'h00FF00FF;
//    #10
//    alu_op_i = 4'd4;
//    #10
//    wrd_i = 5'd10;
//    wdata_i = 32'h11FF11FF;
//    rs2_i = 5'd10;
//
//    #50
//    alu_op_i = 4'd9;
//    #20
//    wrd_i = 5'd23;
//    rs1_i = 5'd23;
//    wdata_i = 32'hFFFF0000;
//
//    #50
//    wdata_i = 32'hDEADBEEF;
//
//    #50
//    wrd_i = 5'd0;
//    rs1_i = 5'd0;
//    wdata_i = 32'hFFFF0000;

    #50
    rst_n = 1'b0;
    #100
    rst_n = 1'b1;
    #50

    $display("Vacuous Pass!"); // Yeah, that easy!
    $finish;
  end

endmodule
