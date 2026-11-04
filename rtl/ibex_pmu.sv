// ===========================================================================
// ibex_pmu.sv - power management unit for the switchable core domain PD_CORE
//   (lives in the always-on domain PD_TOP)
//
//   power-down : core_sleep (WFI) -> isolate -> hold reset -> switch OFF
//   power-up   : wake_i            -> switch ON -> wait ramp -> de-isolate
//                                  -> release core reset (core re-boots)
//
//   pso_o = 1  : header switches (HSWX1.PSO) OFF -> VDD_CORE collapses
//   iso_o = 1  : isolation cells clamp all core outputs to 0
// ===========================================================================
module ibex_pmu #(
  parameter int unsigned SLEEP_FILTER = 8,    // cycles core_sleep must be stable
  parameter int unsigned RAMP_CYCLES  = 16    // VDD_CORE ramp-up wait
) (
  input  logic clk_i,
  input  logic rst_ni,
  input  logic core_sleep_i,   // from core (isolated: reads 0 while OFF)
  input  logic wake_i,         // wake-up request (level, sampled)
  output logic pso_o,          // power shut-off: 1 = core supply OFF
  output logic iso_o,          // isolation enable: 1 = clamp core outputs
  output logic core_rst_no,    // core reset, active low
  output logic core_off_o      // status: core domain is OFF
);

  typedef enum logic [2:0] {S_ON, S_ISO, S_OFF, S_RAMP, S_DEISO} state_t;
  state_t      state_q, state_d;
  logic [7:0]  cnt_q,   cnt_d;
  logic [1:0]  wake_sync;           // wake_i comes from outside -> synchronise

  always_ff @(posedge clk_i or negedge rst_ni)
    if (!rst_ni) wake_sync <= '0;
    else         wake_sync <= {wake_sync[0], wake_i};

  always_comb begin
    state_d = state_q;
    cnt_d   = cnt_q;
    unique case (state_q)
      S_ON:    begin                                   // core running
                 if (core_sleep_i) cnt_d = cnt_q + 1'b1;
                 else              cnt_d = '0;
                 if (cnt_q == SLEEP_FILTER[7:0]) begin state_d = S_ISO; cnt_d = '0; end
               end
      S_ISO:   state_d = S_OFF;                        // 1 cycle: iso + reset before cut
      S_OFF:   if (wake_sync[1]) begin state_d = S_RAMP; cnt_d = '0; end
      S_RAMP:  begin                                   // supply ramping up
                 cnt_d = cnt_q + 1'b1;
                 if (cnt_q == RAMP_CYCLES[7:0]) state_d = S_DEISO;
               end
      S_DEISO: state_d = S_ON;                         // remove iso, then release reset
      default: state_d = S_ON;
    endcase
  end

  always_ff @(posedge clk_i or negedge rst_ni)
    if (!rst_ni) begin
      state_q <= S_ON;
      cnt_q   <= '0;
    end else begin
      state_q <= state_d;
      cnt_q   <= cnt_d;
    end

  // registered outputs (glitch-free control of switches / isolation / reset)
  always_ff @(posedge clk_i or negedge rst_ni)
    if (!rst_ni) begin
      pso_o       <= 1'b0;
      iso_o       <= 1'b0;
      core_rst_no <= 1'b0;
    end else begin
      pso_o       <= (state_d == S_OFF);
      iso_o       <= (state_d == S_ISO) || (state_d == S_OFF) || (state_d == S_RAMP);
      core_rst_no <= (state_d == S_ON);
    end

  assign core_off_o = (state_q == S_OFF);

endmodule
