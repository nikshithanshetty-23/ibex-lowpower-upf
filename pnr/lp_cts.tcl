#=====================================================================
# lp_cts.tcl - CTS + post-CTS hold fix for power-gated Ibex
# Run from pnr/:  innovus -stylus -files lp_cts.tcl -log lp_cts
#=====================================================================
source ../scripts/setup.tcl
read_db lp_place.db
file mkdir reports

foreach bc [get_db base_cells -regexp {^(RDFF|SRDFF|RTLAT|HSW|FSW|ISO|PBUF|PINV|LSHL|LSLH).*}] {
  set_db $bc .dont_use true
}
set_db [get_db insts -if {.base_cell.base_name == ISOLX1_ON}] .dont_touch true

# ---------------- CTS ----------------
set_db cts_buffer_cells   {CLKBUFX2 CLKBUFX3 CLKBUFX4 CLKBUFX6 CLKBUFX8 CLKBUFX12}
set_db cts_inverter_cells {CLKINVX2 CLKINVX3 CLKINVX4 CLKINVX6 CLKINVX8 CLKINVX12}
create_clock_tree_spec -out_file reports/lp_ccopt.spec
ccopt_design

# ---------------- post-CTS hold fix ----------------
set_db opt_hold_target_slack 0.020
opt_design -post_cts -hold

# ---------------- domain audit (same rules as placement) ----------------
set PDX0 515 ; set PDY0 40.47 ; set PDX1 695 ; set PDY1 488.49
proc inbox {i x0 y0 x1 y1} {
  lassign [lindex [get_db $i .bbox] 0] a b c d
  expr {$a >= $x0 && $c <= $x1 && $b >= $y0 && $d <= $y1}
}
set core_out 0 ; set top_in 0 ; set iso_in 0 ; set ck_core 0 ; set ck_top 0
foreach i [get_db insts -if {.is_macro == false}] {
  set nm [get_db $i .name] ; set bc [get_db $i .base_cell.base_name]
  set in [inbox $i $PDX0 $PDY0 $PDX1 $PDY1]
  if {[string match CLK* $bc]} { if {$in} { incr ck_core } else { incr ck_top } }
  if {[string match u_core/* $nm]} { if {!$in} { incr core_out } } \
  elseif {$bc eq "ISOLX1_ON"} { if {$in} { incr iso_in } } \
  elseif {![string match psoI_* $nm]} { if {$in} { incr top_in } }
}
puts "\n######## POST-CTS DOMAIN AUDIT ########"
puts "  u_core cells OUTSIDE PD_CORE fence : $core_out   (want 0)"
puts "  ISOLX1_ON cells INSIDE PD_CORE     : $iso_in   (want 0)"
puts "  PD_TOP cells INSIDE PD_CORE        : $top_in   (want 0)"
puts "  clock cells in PD_CORE / PD_TOP    : $ck_core / $ck_top"

report_clock_trees -summary -out_file reports/lp_cts_summary.rpt
report_skew_groups -summary -out_file reports/lp_skew.rpt
catch {puts [exec cat reports/lp_skew.rpt]}

check_place reports/lp_cts_place.chk
eval_legacy {verifyPowerDomain -bind -isoNetPD reports/vpd_iso_cts.rpt -xNetPD reports/vpd_xnet_cts.rpt}
time_design -post_cts        -report_dir reports/postcts -report_prefix postcts
time_design -post_cts -hold  -report_dir reports/postcts -report_prefix postcts_hold

write_db lp_cts.db
puts "\n######## LP CTS DONE ########"
