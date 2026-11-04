#=====================================================================
# lp_sta.tcl - signoff STA of power-gated Ibex (OCV + CPPR + SI)
# Run from sta/:  tempus -stylus -files lp_sta.tcl -log lp_sta
#=====================================================================
source ../scripts/setup.tcl
file mkdir reports

read_mmmc lp_mmmc_sta.tcl
read_netlist lp_final.v -top ibex_soc
init_design

read_spef -rc_corner rc_worst lp_worst.spef
read_spef -rc_corner rc_best  lp_best.spef

set_db timing_analysis_type ocv
set_db timing_analysis_cppr both
set_db delaycal_enable_si   true
update_timing -full

catch {report_analysis_summary -late  > reports/lp_setup_summary.rpt}
catch {report_analysis_summary -early > reports/lp_hold_summary.rpt}
report_timing -late  -max_paths 1 > reports/lp_setup_worst.rpt
report_timing -early -max_paths 1 > reports/lp_hold_worst.rpt
catch {report_constraint -all_violators > reports/lp_violators.rpt}

# near-critical hold paths (< 20 ps), as in Project 1
set nh [llength [report_timing -early -max_paths 5000 -max_slack 0.020 -collection]]
puts "\n######## LP SIGNOFF STA ########"
puts "  hold paths with slack < 20 ps : $nh"
puts [exec grep -m1 -i "slack" reports/lp_setup_worst.rpt]
puts [exec grep -m1 -i "slack" reports/lp_hold_worst.rpt]
puts "######## LP STA DONE ########"
