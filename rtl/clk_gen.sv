`timescale 1ns/100ps
module clk_gen (output reg clk);
    
    always begin
        
      clk = 0;

      forever #5  clk = ~clk;
    end

endmodule
