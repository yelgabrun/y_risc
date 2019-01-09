
CC = iverilog

FLAGS = -Wall -Winfloop  #-g2012

library_input:  cpu_top.sv ifu.sv reg32bit.sv inst_mem.sv alu.sv regfile.sv clk_gen.sv  ../tb/tb_top.sv
	$(CC) $(FLAGS) -o verilog cpu_top.sv ifu.sv reg32bit.sv inst_mem.sv alu.sv regfile.sv clk_gen.sv ../tb/tb_top.sv

	vvp verilog
	gtkwave regfile_dump.vcd waves.gtkw  &
