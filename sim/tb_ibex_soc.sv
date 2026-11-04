// ===========================================================================
// tb_ibex_soc.sv  -  self-checking testbench for ibex_soc
//
//  1. zero both SRAMs, then preload them from hex files
//       IMEM <- +IMEM=<file>  (default ../sw/imem.hex)
//       DMEM <- +DMEM=<file>  (default ../sw/dmem.hex)
//  2. reset, then fetch_en = 1 (core boots at 0x80)
//  3. watch GPIO:
//       0xC0DE_0000        -> PASS
//       0xC0DE_xxxx        -> FAIL, xxxx = bitmask of failed checks (see test.c)
//       0xDEAD_00cc        -> exception, cc = mcause
//  4. POWER GATING: after the 1st PASS the core executes WFI -> PMU switches
//     the core domain OFF -> TB pulses wake_i -> core re-boots -> 2nd PASS
//  Options:  +VCD  -> dump ibex_soc.vcd (switching activity for power analysis)
//            +MAXCYC=<n> -> timeout in cycles (default 200000)
// ===========================================================================
`timescale 1ns/1ps
module tb_ibex_soc;

  localparam real CLK_PERIOD = 10.0;   // 100 MHz: functional check only

  logic        clk = 1'b0;
  logic        rst_n = 1'b0;
  logic        fetch_en = 1'b0;
  logic [31:0] gpio;
  logic        core_sleep;
  logic        wake = 1'b0;
  logic        core_off;
  int          boot = 0;

  always #(CLK_PERIOD/2) clk = ~clk;

  ibex_soc dut (
    .clk_i        (clk),
    .rst_ni       (rst_n),
    .fetch_en_i   (fetch_en),
    .wake_i       (wake),
    .load_en_i    (1'b0),
    .load_addr_i  (10'h0),
    .load_data_i  (32'h0),
    .gpio_o       (gpio),
    .core_sleep_o (core_sleep),
    .core_off_o   (core_off)
  );

  // ---------------- load program ----------------
  string imem_file, dmem_file;
  int    max_cyc;

  initial begin
    if (!$value$plusargs("IMEM=%s", imem_file))  imem_file = "../sw/imem.hex";
    if (!$value$plusargs("DMEM=%s", dmem_file))  dmem_file = "../sw/dmem.hex";
    if (!$value$plusargs("MAXCYC=%d", max_cyc))  max_cyc   = 200000;

    for (int i = 0; i < 1024; i++) begin   // avoid X from uninitialised SRAM
      dut.u_imem.mem[i] = 32'h0;
      dut.u_dmem.mem[i] = 32'h0;
    end
    $readmemh(imem_file, dut.u_imem.mem);
    $readmemh(dmem_file, dut.u_dmem.mem);
    $display("[TB] IMEM <- %s   DMEM <- %s", imem_file, dmem_file);

    if ($test$plusargs("VCD")) begin
      $dumpfile("ibex_soc.vcd");
      $dumpvars(0, tb_ibex_soc);
    end

    repeat (5) @(posedge clk);
    rst_n = 1'b1;
    repeat (2) @(posedge clk);
    fetch_en = 1'b1;
    $display("[TB] reset released, core fetching from 0x80");
  end

  // ---------------- cycle counter / timeout ----------------
  int cycles = 0;
  always @(posedge clk) begin
    if (fetch_en) cycles <= cycles + 1;
    if (cycles >= max_cyc) begin
      $display("[TB] *** TIMEOUT after %0d cycles, GPIO = 0x%08h ***", cycles, gpio);
      $finish;
    end
  end

  // ---------------- result monitor ----------------
  logic [31:0] gpio_prev = 32'h0;
  always @(posedge clk) begin
    if (gpio !== gpio_prev) begin
      gpio_prev <= gpio;
      $display("[TB] cycle %0d : GPIO = 0x%08h", cycles, gpio);
      if (gpio[31:16] == 16'hC0DE) begin
        boot++;
        // boot 1: all checks pass (0x0000)
        // boot 2: .data is NOT reloaded (DMEM is in the always-on domain and
        //         kept init_val = 0x5A5B from boot 1) -> checks 0x0080 and
        //         0x0100 must fail, everything else must pass  => 0x0180
        if (gpio[15:0] != ((boot == 1) ? 16'h0000 : 16'h0180)) begin
          $display("\n[TB] ======== TEST FAILED (boot %0d), error bits = 0x%04h ========\n", boot, gpio[15:0]);
          $finish;
        end
        $display("[TB] boot %0d : result 0x%04h as expected (%0d cycles)", boot, gpio[15:0], cycles);
        if (boot == 2) begin
          $display("\n[TB] ======== POWER-GATING TEST PASSED ========");
          $display("[TB]   core ran -> WFI -> isolated + powered OFF -> wake -> re-boot -> ran again");
          $display("[TB]   DMEM (always-on) kept its data across the core power-down\n");
          repeat (5) @(posedge clk);
          $finish;
        end
      end
      if (gpio[31:16] == 16'hDEAD) begin
        $display("\n[TB] ======== EXCEPTION, mcause = %0d ========\n", gpio[7:0]);
        $finish;
      end
    end
  end
`ifdef PA_SIM
  // ---------------- power-aware simulation (UPF) ----------------
  // drive the top-level supply ports defined in ibex_soc.upf
  import UPF::*;
  initial begin
    void'(supply_on("tb_ibex_soc.dut.VDD", 1.2));
    void'(supply_on("tb_ibex_soc.dut.VSS", 0.0));
  end
  // while the core is OFF: its own outputs are corrupted (X),
  // the isolated copies seen by PD_TOP must be clamped to 0
  always @(posedge core_off) begin
    repeat (10) @(posedge clk);
    $display("[PA] core OFF: u_core.instr_req_o = %b (expect x)   isolated instr_req = %b (expect 0)",
             dut.u_core.instr_req_o, dut.instr_req);
    $display("[PA] core OFF: u_core.data_we_o   = %b (expect x)   isolated data_we   = %b (expect 0)",
             dut.u_core.data_we_o, dut.data_we);
  end
`endif
  // ---------------- power-gating sequence ----------------
  always @(posedge core_off) begin
    $display("[TB] cycle %0d : core domain powered OFF (PMU)", cycles);
    repeat (50) @(posedge clk);
    $display("[TB] cycle %0d : wake_i pulse", cycles);
    wake = 1'b1;  repeat (4) @(posedge clk);  wake = 1'b0;
  end
  always @(negedge core_off)
    if (cycles > 0) $display("[TB] cycle %0d : core domain powered back ON", cycles);

endmodule
