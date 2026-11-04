// ===========================================================================
// ibex_soc.sv  -  Top level for RTL-to-GDS
//
//   ibex_top ("small" config: RV32IMC, 2-stage, fast mult, FF regfile)
//     instr bus -> IMEM : MEM1_1024X32 (4 KB)   @ 0x0000_0000
//     data  bus -> DMEM : MEM1_1024X32 (4 KB)   @ 0x0001_0000  (+ byte-write RMW)
//               -> GPIO : 32-bit register       @ 0x0002_0000
//
//   Boot: boot_addr = 0x0  ->  first instruction fetched from 0x0000_0080
//   IMEM loader port: while load_en_i=1 (keep fetch_en_i=0) words are written
//   into IMEM at load_addr_i. Then set fetch_en_i=1 to start the core.
//
//   SRAM (from .lib): synchronous, 1-cycle read, CE/WE assumed ACTIVE-HIGH,
//   no byte-write -> partial stores (sb/sh) use read-modify-write (2 cycles).
// ===========================================================================
module ibex_soc (
  input  logic        clk_i,
  input  logic        rst_ni,       // async, active-low
  input  logic        fetch_en_i,   // 1 = core runs
  input  logic        wake_i,       // wake-up request for the core domain
  // IMEM program loader
  input  logic        load_en_i,
  input  logic [9:0]  load_addr_i,  // word address
  input  logic [31:0] load_data_i,
  // outputs
  output logic [31:0] gpio_o,
  output logic        core_sleep_o,
  output logic        core_off_o    // 1 = core domain powered OFF
);

  import ibex_pkg::*;

  localparam logic [19:0] DMEM_PAGE = 20'h00010;  // addr[31:12] of 0x0001_0000
  localparam logic [19:0] GPIO_PAGE = 20'h00020;  // addr[31:12] of 0x0002_0000

  // ------------------------------------------------------------------
  // Core buses
  // ------------------------------------------------------------------
  logic        instr_req, instr_gnt, instr_rvalid;
  logic [31:0] instr_addr, instr_rdata;

  logic        data_req, data_gnt, data_rvalid, data_we;
  logic [3:0]  data_be;
  logic [31:0] data_addr, data_wdata, data_rdata;

  // ------------------------------------------------------------------
  // Ibex core
  // ------------------------------------------------------------------
  // ---------------- power management (always-on) ----------------
  logic core_rst_n, core_pso, core_iso, core_sleep;
  ibex_pmu u_pmu (
    .clk_i        (clk_i),
    .rst_ni       (rst_ni),
    .core_sleep_i (core_sleep),
    .wake_i       (wake_i),
    .pso_o        (core_pso),
    .iso_o        (core_iso),
    .core_rst_no  (core_rst_n),
    .core_off_o   (core_off_o)
  );
  assign core_sleep_o = core_sleep;

  ibex_top #(
    .PMPEnable        (1'b0),
    .MHPMCounterNum   (0),
    .RV32E            (1'b0),
    .RV32M            (ibex_pkg::RV32MFast),
    .RV32B            (ibex_pkg::RV32BNone),
    .RV32ZC           (ibex_pkg::RV32Zca),
    .RegFile          (ibex_pkg::RegFileFF),
    .BranchTargetALU  (1'b0),
    .WritebackStage   (1'b0),
    .ICache           (1'b0),
    .ICacheECC        (1'b0),
    .ICacheScramble   (1'b0),
    .BranchPredictor  (1'b0),
    .DbgTriggerEn     (1'b0),
    .SecureIbex       (1'b0)
  ) u_core (
    .clk_i                   (clk_i),
    .rst_ni                  (core_rst_n),
    .test_en_i               (1'b0),
    .ram_cfg_icache_tag_i    ('0),
    .ram_cfg_icache_tag_o    (),
    .ram_cfg_icache_data_i   ('0),
    .ram_cfg_icache_data_o   (),
    .cheriot_enable_i        (IbexMuBiOff),
    .hart_id_i               (32'h0),
    .boot_addr_i             (32'h0),
    .trvk_heap_base_addr_i   (32'h0),

    .instr_req_o             (instr_req),
    .instr_gnt_i             (instr_gnt),
    .instr_rvalid_i          (instr_rvalid),
    .instr_addr_o            (instr_addr),
    .instr_rdata_i           (instr_rdata),
    .instr_rdata_intg_i      (7'h0),
    .instr_err_i             (1'b0),

    .data_req_o              (data_req),
    .data_gnt_i              (data_gnt),
    .data_rvalid_i           (data_rvalid),
    .data_we_o               (data_we),
    .data_be_o               (data_be),
    .data_addr_o             (data_addr),
    .data_wdata_o            (data_wdata),
    .data_wdata_intg_o       (),
    .data_tag_o              (),
    .data_rdata_i            (data_rdata),
    .data_rdata_intg_i       (7'h0),
    .data_tag_i              (1'b0),
    .data_err_i              (1'b0),

    .trvk_revbm_req_o        (),
    .trvk_revbm_gnt_i        (1'b0),
    .trvk_revbm_rvalid_i     (1'b0),
    .trvk_revbm_addr_o       (),
    .trvk_revbm_rdata_i      (32'h0),
    .trvk_revbm_rdata_intg_i (7'h0),
    .trvk_revbm_err_i        (1'b0),

    .irq_software_i          (1'b0),
    .irq_timer_i             (1'b0),
    .irq_external_i          (1'b0),
    .irq_fast_i              (15'h0),
    .irq_nm_i                (1'b0),

    .scramble_key_valid_i    (1'b0),
    .scramble_key_i          ('0),
    .scramble_nonce_i        ('0),
    .scramble_req_o          (),

    .debug_req_i             (1'b0),
    .crash_dump_o            (),
    .double_fault_seen_o     (),

    .fetch_enable_i          (fetch_en_i ? IbexMuBiOn : IbexMuBiOff),
    .mcounteren_writable_i   (IbexMuBiOn),
    .alert_minor_o           (),
    .alert_major_internal_o  (),
    .alert_major_bus_o       (),
    .core_sleep_o            (core_sleep),

    .scan_rst_ni             (1'b1),

    .lockstep_cmp_en_o       (),
    .data_req_shadow_o       (),
    .data_we_shadow_o        (),
    .data_be_shadow_o        (),
    .data_addr_shadow_o      (),
    .data_wdata_shadow_o     (),
    .data_wdata_intg_shadow_o(),
    .instr_req_shadow_o      (),
    .instr_addr_shadow_o     ()
  );

  // ------------------------------------------------------------------
  // Instruction memory (IMEM)
  // ------------------------------------------------------------------
  logic        imem_ce, imem_we;
  logic [9:0]  imem_a;
  logic [31:0] imem_q;

  assign imem_ce   = load_en_i | instr_req;
  assign imem_we   = load_en_i;
  assign imem_a    = load_en_i ? load_addr_i : instr_addr[11:2];
  assign instr_gnt = instr_req & ~load_en_i;   // always ready unless loading

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) instr_rvalid <= 1'b0;
    else         instr_rvalid <= instr_gnt;    // data arrives 1 cycle later
  end

  assign instr_rdata = imem_q;

  MEM1_1024X32 u_imem (
    .CK (clk_i),
    .CE (imem_ce),
    .WE (imem_we),
    .A  (imem_a),
    .D  (load_data_i),
    .Q  (imem_q)
  );

  // ------------------------------------------------------------------
  // Data side: decode, DMEM with read-modify-write, GPIO
  // ------------------------------------------------------------------
  logic sel_dmem, sel_gpio, partial_wr;
  assign sel_dmem   = (data_addr[31:12] == DMEM_PAGE);
  assign sel_gpio   = (data_addr[31:12] == GPIO_PAGE);
  assign partial_wr = data_we & (data_be != 4'hF);   // sb / sh

  typedef enum logic {S_IDLE, S_RMW} state_e;
  state_e state_q, state_d;

  logic [9:0]  rmw_addr_q;
  logic [3:0]  rmw_be_q;
  logic [31:0] rmw_wdata_q;
  logic        rvalid_q, rsel_dmem_q, rsel_gpio_q;
  logic [31:0] gpio_q;

  // No new request accepted while the RMW write cycle is in progress
  assign data_gnt = data_req & (state_q == S_IDLE);

  logic        dmem_ce, dmem_we;
  logic [9:0]  dmem_a;
  logic [31:0] dmem_d, dmem_q, merged;

  // Merge new bytes into the word just read from DMEM
  always_comb begin
    for (int i = 0; i < 4; i++)
      merged[8*i +: 8] = rmw_be_q[i] ? rmw_wdata_q[8*i +: 8] : dmem_q[8*i +: 8];
  end

  always_comb begin
    dmem_ce = 1'b0;
    dmem_we = 1'b0;
    dmem_a  = data_addr[11:2];
    dmem_d  = data_wdata;
    state_d = state_q;
    if (state_q == S_RMW) begin
      // cycle 2 of a partial store: write merged word back
      dmem_ce = 1'b1;
      dmem_we = 1'b1;
      dmem_a  = rmw_addr_q;
      dmem_d  = merged;
      state_d = S_IDLE;
    end else if (data_gnt && sel_dmem) begin
      dmem_ce = 1'b1;
      dmem_we = data_we & ~partial_wr;  // full-word write directly
      if (partial_wr) state_d = S_RMW;  // partial: read now, write next cycle
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state_q     <= S_IDLE;
      rvalid_q    <= 1'b0;
      rsel_dmem_q <= 1'b0;
      rsel_gpio_q <= 1'b0;
      rmw_addr_q  <= '0;
      rmw_be_q    <= '0;
      rmw_wdata_q <= '0;
      gpio_q      <= '0;
    end else begin
      state_q  <= state_d;
      rvalid_q <= data_gnt & ~(sel_dmem & partial_wr);
      if (data_gnt) begin
        rsel_dmem_q <= sel_dmem;
        rsel_gpio_q <= sel_gpio;
      end
      if (data_gnt && sel_dmem && partial_wr) begin
        rmw_addr_q  <= data_addr[11:2];
        rmw_be_q    <= data_be;
        rmw_wdata_q <= data_wdata;
      end
      if (data_gnt && sel_gpio && data_we) begin
        for (int i = 0; i < 4; i++)
          if (data_be[i]) gpio_q[8*i +: 8] <= data_wdata[8*i +: 8];
      end
    end
  end

  assign data_rvalid = rvalid_q | (state_q == S_RMW);
  assign data_rdata  = rsel_dmem_q ? dmem_q :
                       rsel_gpio_q ? gpio_q : 32'h0;
  assign gpio_o      = gpio_q;

  MEM1_1024X32 u_dmem (
    .CK (clk_i),
    .CE (dmem_ce),
    .WE (dmem_we),
    .A  (dmem_a),
    .D  (dmem_d),
    .Q  (dmem_q)
  );

endmodule

