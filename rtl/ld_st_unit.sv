`timescale 1ns/100ps

module ld_st_unit (
  input             clk_i,
  input             rst_n_i,
  input             load_en_i,
  input      [11:0] offset_i,
  input      [ 2:0] funct3_i,
  input      [31:0] rs1_data_i,
  output reg [31:0] ld_address_o
  );

//  assign ld_address_o = rs1_data_i + {{20{offset_i[11]}}, offset_i};
    
  always @(*)
  begin
    ld_address_o = 32'd0;
    if (load_en_i)
    begin
      case (funct3_i)
        3'b010: ld_address_o = rs1_data_i + {{20{offset_i[11]}}, offset_i}; 
//        3'b001: ld_address_o = ;
//        3'b010: ld_address_o = ; 
////        3'b011: ld_address_o = ; 
//        3'b100: ld_address_o = ;
//        3'b101: ld_address_o = ;
//        3'b110: ld_address_o = ;
//        3'b111: ld_address_o = ;  
//        3'b101: ld_address_o = ;
        default: begin end
      endcase
    end
  end


endmodule
