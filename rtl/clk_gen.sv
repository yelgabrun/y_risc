`timescale 1ns/100ps
module clk_gen (output reg clk);
    
/* verilator lint_off INFINITELOOP */
/* verilator lint_off STMTDLY */
    always begin
        
      clk = 0;
      forever #5  clk = ~clk;
    end
/* verilator lint_on STMTDLY */
/* verilator lint_on INFINITELOOP */

endmodule
