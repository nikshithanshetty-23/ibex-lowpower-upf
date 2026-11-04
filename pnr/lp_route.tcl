#=====================================================================
# lp_route.tcl - detail route + post-route opt for power-gated Ibex
# Run from pnr/:  innovus -stylus -files lp_route.tcl -log lp_route
#=====================================================================
source ../scripts/setup.tcl
read_db lp_cts.db
file mkdir reports

foreach bc [get_db base_cells -regexp {^(RDFF|SRDFF|RTLAT|HSW|FSW|ISO|PBUF|PINV|LSHL|LSLH).*}] {
  set_db $bc .dont_use true
}
set_db [get_db insts -if {.base_cell.base_name == ISOLX1_ON}] .dont_touch true

# ---------------- route ----------------
set_db route_design_with_timing_driven true
set_db route_design_with_si_driven     true
route_design

# ---------------- post-route analysis mode: OCV + CPPR + SI ----------------
set_db timing_analysis_type ocv
set_db timing_analysis_cppr both
set_db delaycal_enable_si   true
set_db opt_hold_target_slack 0.020
opt_design -post_route -setup -hold

write_db lp_route.db
puts "\n######## LP ROUTE SAVED ########"

# ---------------- checks (wrapped so they can't stop the script) ----------------
catch {check_drc -limit 1000 -out_file reports/route_drc.rpt}
catch {eval_legacy {verifyConnectivity -type regular -noAntenna -error 1000 -warning 50 -report reports/route_conn.rpt}}
catch {eval_legacy {verifyConnectivity -nets {VDD VDD_CORE VSS} -type special -noAntenna -error 1000 -warning 50 -report reports/route_pg.rpt}}
catch {eval_legacy {verifyProcessAntenna -report reports/route_ant.rpt}}
catch {eval_legacy {verifyPowerDomain -bind -isoNetPD reports/vpd_iso_rt.rpt -xNetPD reports/vpd_xnet_rt.rpt}}
catch {time_design -post_route       -report_dir reports/postroute -report_prefix postroute}
catch {time_design -post_route -hold -report_dir reports/postroute -report_prefix postroute_hold}
puts "\n######## LP ROUTE DONE ########"
