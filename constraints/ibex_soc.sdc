#=====================================================================
# ibex_soc.sdc  -  timing constraints for ibex_soc
# Units: time = ns, capacitance = pF (from the .lib)
#=====================================================================

# ---------------- Clock ----------------
set CLK_PERIOD 5.0                                ;# 200 MHz baseline (tighten later)

create_clock -name clk -period $CLK_PERIOD [get_ports clk_i]

# Pre-CTS margins: jitter + expected skew (clock tree doesn't exist yet)
set_clock_uncertainty -setup 0.30 [get_clocks clk]
set_clock_uncertainty -hold  0.10 [get_clocks clk]
set_clock_transition         0.10 [get_clocks clk]

# ---------------- I/O timing ----------------
# Assume the outside world uses 20% of the cycle on each side
set IN_DLY  [expr 0.2 * $CLK_PERIOD]
set OUT_DLY [expr 0.2 * $CLK_PERIOD]

set DATA_INPUTS [remove_from_collection [all_inputs] [get_ports clk_i]]

set_input_delay  -clock clk $IN_DLY  $DATA_INPUTS
set_output_delay -clock clk $OUT_DLY [all_outputs]

# ---------------- Boundary conditions ----------------
set_driving_cell -lib_cell BUFX2 $DATA_INPUTS
set_load 0.01 [all_outputs]

# ---------------- Exceptions ----------------
# Asynchronous active-low reset: not timed as a normal data path
set_false_path -from [get_ports rst_ni]

# ---------------- Design rules ----------------
set_max_transition 0.5 [current_design]
set_max_fanout     32  [current_design]
