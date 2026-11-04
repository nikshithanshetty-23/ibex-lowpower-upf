#=====================================================================
# ibex_soc_signoff.sdc - SIGNOFF constraints (post-CTS / post-route)
# Same as ibex_soc.sdc, except:
#   1. clock uncertainty reduced (real clock skew is now analysed)
#   2. clock is PROPAGATED (real delay through the clock-tree buffers)
#   3. no set_clock_transition (real clock slew comes from the tree)
#=====================================================================
set PERIOD 5.0

# ---------------- clock ----------------
create_clock -name clk -period $PERIOD [get_ports clk_i]
set_clock_uncertainty -setup 0.10 [get_clocks clk]
set_clock_uncertainty -hold  0.05 [get_clocks clk]
set_propagated_clock [all_clocks]

# ---------------- I/O delays (20% of period) ----------------
set IN_PORTS [remove_from_collection [all_inputs] [get_ports clk_i]]
set_input_delay  [expr {0.2*$PERIOD}] -clock clk $IN_PORTS
set_output_delay [expr {0.2*$PERIOD}] -clock clk [all_outputs]

# ---------------- boundary conditions ----------------
set_driving_cell -lib_cell BUFX2 $IN_PORTS
set_load 0.01 [all_outputs]

# ---------------- exceptions ----------------
set_false_path -from [get_ports rst_ni]

# ---------------- design rules ----------------
set_max_transition 0.5 [current_design]
set_max_fanout 32 [current_design]
