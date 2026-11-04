#=====================================================================
# lp_power.tcl - static power (core ON) with hierarchy breakdown
# Run from power/:  voltus -stylus -files lp_power.tcl -log lp_power
#=====================================================================
source ../scripts/setup.tcl
read_db ../pnr/lp_route2.db
file mkdir on

eval_legacy {
  set_power_analysis_mode -reset
  set_power_analysis_mode -method static -analysis_view view_setup -corner max -create_binary_db false -write_static_currents false -honor_negative_energy true
  set_default_switching_activity -reset
  set_default_switching_activity -input_activity 0.2 -period 5.0
  set_power_output_dir ./on
  report_power -hierarchy 1 -outfile ./on/power_on.rpt
}
puts "\n######## POWER ON DONE ########"
