`timescale 1ns/100ps

//==============================================================================
// tb_check.sv : self-checking testbench for y_risc (RV32I)
//
// How it works
//   1. Snapshots the program the DUT loaded into its memory (time 0 + 1ns).
//   2. Runs that program on a reference model: a small RV32I instruction-set
//      simulator written in this file. This gives the expected final state.
//   3. Lets the DUT run for (reference instructions * CPI_MAX + EXTRA_CYCLES)
//      clock cycles. The slack covers start-up and pipeline fill/drain.
//   4. Compares the 32 registers (and optionally the memory) of the DUT with
//      the reference model and prints TEST PASSED or TEST FAILED.
//
// End of program
//   The reference model stops at the first word it does not execute, e.g.
//   0x00000000 (an illegal instruction in RISC-V) or any non-RV32I word.
//   Whatever follows the program must not change architectural state in the
//   DUT, because the DUT keeps running for a few cycles after the program ends.
//
// Memory model
//   Unified instruction/data memory of MEM_WORDS 32-bit words. Address bits
//   above log2(MEM_WORDS)+1 are ignored (wrap). Misaligned loads/stores/jumps
//   are not modelled: the reference model stops there.
//
// Run (from sim/):
//   iverilog -g2012 -s tb_check -o a.out ../rtl/*.sv ../tb/tb_check.sv
//   vvp a.out              (add +TRACE for a per-instruction reference log)
//
// DUT hookup
//   Everything design-specific is the three `DUT_* macros below plus the
//   cpu_top instance. Edit them here, or override with -DDUT_REGS=... etc.
//==============================================================================

`ifndef DUT_CLK
  `define DUT_CLK  cpu_top_inst.sysclk                       // clock seen by the DUT
`endif
`ifndef DUT_REGS
  `define DUT_REGS cpu_top_inst.i_decode.regfile_inst.x      // register array x[0:31]
`endif
`ifndef DUT_MEM
  `define DUT_MEM  cpu_top_inst.i_main_memory.main_mem       // memory array (32-bit words)
`endif

module tb_check;

  parameter RESET_PC     = 32'h0000_0000; // address of the first instruction
  parameter MEM_WORDS    = 1024;          // memory size in 32-bit words
  parameter CPI_MAX      = 1;             // worst-case cycles per instruction of the DUT
  parameter EXTRA_CYCLES = 8;             // slack for start-up / pipeline drain
  parameter MAX_INSTR    = 100000;        // reference-model runaway guard
  parameter CHECK_MEM    = 1;             // 1: also compare memory contents

  localparam AW = $clog2(MEM_WORDS);

  //----------------------------------------------------------------------------
  // DUT hookup
  //----------------------------------------------------------------------------
  reg rst_n;
  reg wr_en;

  cpu_top cpu_top_inst (
    .rst_n_i      (rst_n),
    .wr_en_i      (wr_en),
    .alu_result_o (),
    .z_flag_o     ()
  );

  //----------------------------------------------------------------------------
  // Reference model state
  //----------------------------------------------------------------------------
  reg [31:0] r_pc;
  reg [31:0] r_x   [0:31];
  reg [31:0] r_mem [0:MEM_WORDS-1];
  reg [31:0] cur_pc;
  reg [31:0] cur_inst;
  integer    iss_count;
  reg        iss_running;
  reg        iss_trace;
  reg        model_ok;
  integer    mismatches;
  integer    n_cycles;

  //----------------------------------------------------------------------------
  // Reference model: ALU (shared by OP and OP-IMM)
  //   alt = 1 selects SUB (f3=000) or SRA/SRAI (f3=101)
  //----------------------------------------------------------------------------
  function [31:0] alu_fn;
    input [2:0]  f3;
    input        alt;
    input [31:0] a;
    input [31:0] b;
    reg signed [31:0] sa;
    begin
      sa = a;
      case (f3)
        3'b000: begin
          if (alt) alu_fn = a - b;
          else     alu_fn = a + b;
        end
        3'b001: alu_fn = a << b[4:0];
        3'b010: alu_fn = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
        3'b011: alu_fn = (a < b) ? 32'd1 : 32'd0;
        3'b100: alu_fn = a ^ b;
        3'b101: begin
          if (alt) alu_fn = sa >>> b[4:0];
          else     alu_fn = a >> b[4:0];
        end
        3'b110: alu_fn = a | b;
        default: alu_fn = a & b;
      endcase
    end
  endfunction

  //----------------------------------------------------------------------------
  // Reference model: register write with optional trace
  //----------------------------------------------------------------------------
  task iss_write_rd;
    input [4:0]  rd;
    input [31:0] val;
    begin
      if (rd != 5'd0) r_x[rd] = val;
      if (iss_trace)
        $display("  [ref] pc=%08h inst=%08h  x%0d <- %08h",
                 cur_pc, cur_inst, rd, (rd != 5'd0) ? val : 32'd0);
    end
  endtask

  //----------------------------------------------------------------------------
  // Reference model: execute one instruction
  //----------------------------------------------------------------------------
  task iss_step;
    reg [6:0]  opc;
    reg [6:0]  f7;
    reg [4:0]  rd;
    reg [4:0]  rs1;
    reg [4:0]  rs2;
    reg [2:0]  f3;
    reg [31:0] imm_i;
    reg [31:0] imm_s;
    reg [31:0] imm_b;
    reg [31:0] imm_u;
    reg [31:0] imm_j;
    reg [31:0] a;
    reg [31:0] b;
    reg [31:0] ea;
    reg [31:0] w;
    reg [31:0] res;
    reg [31:0] npc;
    reg [7:0]  bt;
    reg [15:0] hf;
    reg        take;
    reg        ok;
    begin
      cur_pc   = r_pc;
      cur_inst = r_mem[r_pc[AW+1:2]];

      opc = cur_inst[6:0];
      rd  = cur_inst[11:7];
      f3  = cur_inst[14:12];
      rs1 = cur_inst[19:15];
      rs2 = cur_inst[24:20];
      f7  = cur_inst[31:25];

      imm_i = {{20{cur_inst[31]}}, cur_inst[31:20]};
      imm_s = {{20{cur_inst[31]}}, cur_inst[31:25], cur_inst[11:7]};
      imm_b = {{19{cur_inst[31]}}, cur_inst[31], cur_inst[7], cur_inst[30:25], cur_inst[11:8], 1'b0};
      imm_u = {cur_inst[31:12], 12'd0};
      imm_j = {{11{cur_inst[31]}}, cur_inst[31], cur_inst[19:12], cur_inst[20], cur_inst[30:21], 1'b0};

      a    = r_x[rs1];
      b    = r_x[rs2];
      npc  = r_pc + 32'd4;
      ok   = 1'b1;
      take = 1'b0;
      res  = 32'd0;
      w    = 32'd0;
      ea   = 32'd0;
      bt   = 8'd0;
      hf   = 16'd0;

      case (opc)
        //---------------------------------------------------------------- LUI
        7'b0110111: iss_write_rd(rd, imm_u);

        //-------------------------------------------------------------- AUIPC
        7'b0010111: iss_write_rd(rd, r_pc + imm_u);

        //---------------------------------------------------------------- JAL
        7'b1101111: begin
          iss_write_rd(rd, npc);
          npc = r_pc + imm_j;
        end

        //--------------------------------------------------------------- JALR
        7'b1100111: begin
          if (f3 != 3'b000) ok = 1'b0;
          else begin
            ea = (a + imm_i) & 32'hFFFF_FFFE;
            iss_write_rd(rd, npc);
            npc = ea;
          end
        end

        //------------------------------------------------------------- BRANCH
        7'b1100011: begin
          case (f3)
            3'b000:  take = (a == b);
            3'b001:  take = (a != b);
            3'b100:  take = ($signed(a) <  $signed(b));
            3'b101:  take = ($signed(a) >= $signed(b));
            3'b110:  take = (a <  b);
            3'b111:  take = (a >= b);
            default: ok = 1'b0;
          endcase
          if (ok && take) npc = r_pc + imm_b;
        end

        //--------------------------------------------------------------- LOAD
        7'b0000011: begin
          ea = a + imm_i;
          w  = r_mem[ea[AW+1:2]];
          case (ea[1:0])
            2'd0:    bt = w[7:0];
            2'd1:    bt = w[15:8];
            2'd2:    bt = w[23:16];
            default: bt = w[31:24];
          endcase
          hf = ea[1] ? w[31:16] : w[15:0];
          case (f3)
            3'b000: res = {{24{bt[7]}}, bt};                                  // LB
            3'b001: begin res = {{16{hf[15]}}, hf}; if (ea[0])     ok = 1'b0; end // LH
            3'b010: begin res = w;                  if (ea[1:0] != 2'b00) ok = 1'b0; end // LW
            3'b100: res = {24'd0, bt};                                        // LBU
            3'b101: begin res = {16'd0, hf};        if (ea[0])     ok = 1'b0; end // LHU
            default: ok = 1'b0;
          endcase
          if (ok) iss_write_rd(rd, res);
        end

        //-------------------------------------------------------------- STORE
        7'b0100011: begin
          ea = a + imm_s;
          w  = r_mem[ea[AW+1:2]];
          case (f3)
            3'b000: begin                                                     // SB
              case (ea[1:0])
                2'd0:    w[7:0]   = b[7:0];
                2'd1:    w[15:8]  = b[7:0];
                2'd2:    w[23:16] = b[7:0];
                default: w[31:24] = b[7:0];
              endcase
            end
            3'b001: begin                                                     // SH
              if (ea[0]) ok = 1'b0;
              if (ea[1]) w[31:16] = b[15:0];
              else       w[15:0]  = b[15:0];
            end
            3'b010: begin                                                     // SW
              if (ea[1:0] != 2'b00) ok = 1'b0;
              w = b;
            end
            default: ok = 1'b0;
          endcase
          if (ok) begin
            r_mem[ea[AW+1:2]] = w;
            if (iss_trace)
              $display("  [ref] pc=%08h inst=%08h  mem[%08h] <- %08h (word after write)",
                       cur_pc, cur_inst, ea, w);
          end
        end

        //------------------------------------------------------------- OP-IMM
        7'b0010011: begin
          if (f3 == 3'b001 && f7 != 7'b0000000)
            ok = 1'b0;
          else if (f3 == 3'b101 && f7 != 7'b0000000 && f7 != 7'b0100000)
            ok = 1'b0;
          else
            iss_write_rd(rd, alu_fn(f3, (f3 == 3'b101) & f7[5], a, imm_i));
        end

        //------------------------------------------------------------------ OP
        7'b0110011: begin
          if (!((f7 == 7'b0000000) ||
                (f7 == 7'b0100000 && (f3 == 3'b000 || f3 == 3'b101))))
            ok = 1'b0;
          else
            iss_write_rd(rd, alu_fn(f3, f7[5], a, b));
        end

        //------------------------------------------- anything else: stop here
        default: ok = 1'b0;
      endcase

      if (ok && (npc[1:0] != 2'b00)) ok = 1'b0;

      if (ok) begin
        if (iss_trace && (npc != r_pc + 32'd4))
          $display("  [ref] pc=%08h inst=%08h  control flow -> pc=%08h", cur_pc, cur_inst, npc);
        r_pc = npc;
      end else begin
        iss_running = 1'b0;
      end
    end
  endtask

  //----------------------------------------------------------------------------
  // Reference model: run until it hits a word it does not execute
  //----------------------------------------------------------------------------
  task run_reference_model;
    integer k;
    begin
      for (k = 0; k < 32; k = k + 1) r_x[k] = 32'd0;
      r_pc        = RESET_PC;
      iss_count   = 0;
      iss_running = 1'b1;
      while (iss_running && (iss_count < MAX_INSTR)) begin
        iss_step;
        if (iss_running) iss_count = iss_count + 1;
      end
      if (iss_running)
        $display("[tb] WARNING: reference model reached MAX_INSTR (%0d) without finding the end of the program", MAX_INSTR);
      else
        $display("[tb] reference model executed %0d instruction(s); end of program at pc=%08h (word %08h)",
                 iss_count, cur_pc, cur_inst);
    end
  endtask

  //----------------------------------------------------------------------------
  // Copy the DUT's initial memory image into the reference model
  //----------------------------------------------------------------------------
  task snapshot_memory;
    integer k;
    begin
      for (k = 0; k < MEM_WORDS; k = k + 1) r_mem[k] = `DUT_MEM[k];
    end
  endtask

  //----------------------------------------------------------------------------
  // A few known-answer vectors to check the reference model itself
  //----------------------------------------------------------------------------
  task selftest_model;
    begin
      model_ok = 1'b1;
      if (alu_fn(3'b101, 1'b1, 32'h8000_0000, 32'd4)  !== 32'hF800_0000) model_ok = 1'b0; // SRA
      if (alu_fn(3'b101, 1'b0, 32'h8000_0000, 32'd4)  !== 32'h0800_0000) model_ok = 1'b0; // SRL
      if (alu_fn(3'b010, 1'b0, 32'hFFFF_FFFF, 32'd1)  !== 32'd1)         model_ok = 1'b0; // SLT
      if (alu_fn(3'b011, 1'b0, 32'hFFFF_FFFF, 32'd1)  !== 32'd0)         model_ok = 1'b0; // SLTU
      if (alu_fn(3'b000, 1'b1, 32'd5, 32'd7)          !== 32'hFFFF_FFFE) model_ok = 1'b0; // SUB
      if (alu_fn(3'b000, 1'b0, 32'd5, 32'd7)          !== 32'd12)        model_ok = 1'b0; // ADD
      if (alu_fn(3'b001, 1'b0, 32'd1, 32'd31)         !== 32'h8000_0000) model_ok = 1'b0; // SLL
      if (alu_fn(3'b100, 1'b0, 32'hF0F0_F0F0, 32'hFF00_FF00) !== 32'h0FF0_0FF0) model_ok = 1'b0; // XOR
      if (model_ok)
        $display("[tb] reference-model self-check ok");
      else
        $display("[tb] INTERNAL ERROR: reference-model self-check failed - do not trust the results below");
    end
  endtask

  //----------------------------------------------------------------------------
  // Compare DUT state with the reference model and report
  //----------------------------------------------------------------------------
  task compare_state;
    integer k;
    integer mem_mis;
    begin
      mismatches = 0;
      mem_mis    = 0;

      for (k = 0; k < 32; k = k + 1) begin
        if (`DUT_REGS[k] !== r_x[k]) begin
          mismatches = mismatches + 1;
          $display("  MISMATCH x%0d: expected %08h, DUT has %08h", k, r_x[k], `DUT_REGS[k]);
        end
      end

      if (CHECK_MEM) begin
        for (k = 0; k < MEM_WORDS; k = k + 1) begin
          if (`DUT_MEM[k] !== r_mem[k]) begin
            mem_mis = mem_mis + 1;
            if (mem_mis <= 16)
              $display("  MISMATCH mem[%0d] (addr %08h): expected %08h, DUT has %08h",
                       k, k * 4, r_mem[k], `DUT_MEM[k]);
          end
        end
        if (mem_mis > 16)
          $display("  ... %0d memory word mismatches in total", mem_mis);
      end

      mismatches = mismatches + mem_mis;

      if (iss_count == 0)
        $display("TEST FAILED: the reference model executed no instructions, so nothing was checked");
      else if (mismatches == 0)
        $display("TEST PASSED: %0d instruction(s) checked over %0d cycle(s)", iss_count, n_cycles);
      else
        $display("TEST FAILED: %0d mismatch(es) after %0d reference instruction(s), %0d cycle(s)",
                 mismatches, iss_count, n_cycles);
    end
  endtask

  //----------------------------------------------------------------------------
  // Waveform dump (same file name as before)
  //----------------------------------------------------------------------------
`ifndef NO_DUMP
  integer di;
  initial begin
    $dumpfile("cpu_dump.vcd");
    $dumpvars(0, tb_check);
    for (di = 0; di < 32; di = di + 1)
      $dumpvars(0, `DUT_REGS[di]);
  end
`endif

  //----------------------------------------------------------------------------
  // Test sequence
  //----------------------------------------------------------------------------
  initial begin : run
    rst_n     = 1'b0;
    wr_en     = 1'b0;
    iss_trace = $test$plusargs("TRACE");

    #1;                      // let the DUT's memory initialisation finish
    snapshot_memory;
    selftest_model;
    run_reference_model;

    // reset: hold for 3 clocks, release (together with wr_en) on a falling edge
    repeat (3) @(posedge `DUT_CLK);
    @(negedge `DUT_CLK) begin
      rst_n = 1'b1;
      wr_en = 1'b1;
    end

    n_cycles = iss_count * CPI_MAX + EXTRA_CYCLES;
    repeat (n_cycles) @(posedge `DUT_CLK);
    @(negedge `DUT_CLK);     // everything has settled after the last rising edge

    compare_state;
    $finish;
  end

endmodule
