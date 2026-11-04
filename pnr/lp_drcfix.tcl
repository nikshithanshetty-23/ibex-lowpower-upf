#=====================================================================
# lp_drcfix.tcl - keep std cells out from under the VDD Metal2 straps
# Run from pnr/:  innovus -stylus -files lp_drcfix.tcl -log lp_drcfix
#=====================================================================
source ../scripts/setup.tcl
read_db lp_route.db
file mkdir reports

foreach bc [get_db base_cells -regexp {^(RDFF|SRDFF|RTLAT|HSW|FSW|ISO|PBUF|PINV|LSHL|LSLH).*}] {
  set_db $bc .dont_use true
}
set_db [get_db insts -if {.base_cell.base_name == ISOLX1_ON}] .dont_touch true
set_db timing_analysis_type ocv
set_db timing_analysis_cppr both
set_db delaycal_enable_si   true
set_db opt_hold_target_slack 0.020

# ---------- 1. hard blockage under each strap pair ----------
set PDY0 40.47 ; set PDY1 488.49
set under 0
foreach x {535 580 625 670} {
  set xa [expr {$x + 3.2}] ; set xb [expr {$x + 6.6}]
  create_place_blockage -type hard -name strap_$x -area [list $xa $PDY0 $xb $PDY1]
  foreach i [get_db insts -if {.is_macro == false && .place_status != fixed}] {
    lassign [lindex [get_db $i .bbox] 0] a b c d
    if {$c > $xa && $a < $xb && $b >= $PDY0 && $d <= $PDY1} { incr under }
  }
}
puts "\n######## std cells under VDD straps before fix: $under ########"

# ---------- 2. legalize (moves only those cells) ----------
place_detail

# ---------- 3. reroute changed nets + incremental opt ----------
route_eco
opt_design -post_route -setup -hold

write_db lp_route2.db
puts "\n######## LP ROUTE2 SAVED ########"

# ---------- 4. checks ----------
catch {check_drc -limit 1000 -out_file reports/route2_drc.rpt}
catch {eval_legacy {verifyConnectivity -type regular -noAntenna -error 1000 -warning 50 -report reports/route2_conn.rpt}}
catch {eval_legacy {verifyConnectivity -nets {VDD VDD_CORE VSS} -type special -noAntenna -error 1000 -warning 50 -report reports/route2_pg.rpt}}
catch {eval_legacy {verifyPowerDomain -bind -isoNetPD reports/vpd_iso_rt2.rpt -xNetPD reports/vpd_xnet_rt2.rpt}}
catch {time_design -post_route       -report_dir reports/postroute2 -report_prefix pr2}
catch {time_design -post_route -hold -report_dir reports/postroute2 -report_prefix pr2_hold}
puts "\n######## LP DRC FIX DONE ########"

