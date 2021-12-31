`timescale 1ns/100ps
module clk_gen (output clk);
  reg clk_s; 
/* verilator lint_off INFINITELOOP */
/* verilator lint_off STMTDLY */
    always begin
        
      clk_s = 0;
      forever #5  clk_s = ~clk_s;
    end

   assign clk = clk_s;
/* verilator lint_on STMTDLY */
/* verilator lint_on INFINITELOOP */

endmodule
