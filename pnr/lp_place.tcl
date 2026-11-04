#=====================================================================
# lp_place.tcl - placement + pre-CTS opt for power-gated Ibex
# Run from pnr/:  innovus -stylus -files lp_place.tcl -log lp_place
#=====================================================================
source ../scripts/setup.tcl
read_db lp_pg.db
file mkdir reports

# no NEW low-power cells during optimization (same rule as Genus)
foreach bc [get_db base_cells -regexp {^(RDFF|SRDFF|RTLAT|HSW|FSW|ISO|PBUF|PINV|LSHL|LSLH).*}] {
  set_db $bc .dont_use true
}
# keep the Genus isolation cells exactly as they are
set_db [get_db insts -if {.base_cell.base_name == ISOLX1_ON}] .dont_touch true

set_db place_global_place_io_pins true
place_opt_design

# ---------------- domain audit ----------------
set PDX0 515 ; set PDY0 40.47 ; set PDX1 695 ; set PDY1 488.49
proc inbox {i x0 y0 x1 y1} {
  lassign [lindex [get_db $i .bbox] 0] a b c d
  expr {$a >= $x0 && $c <= $x1 && $b >= $y0 && $d <= $y1}
}
set core_out 0 ; set top_in 0 ; set iso_in 0
foreach i [get_db insts -if {.is_macro == false}] {
  set nm [get_db $i .name]
  set in [inbox $i $PDX0 $PDY0 $PDX1 $PDY1]
  if {[string match u_core/* $nm]} { if {!$in} { incr core_out } } \
  elseif {[get_db $i .base_cell.base_name] eq "ISOLX1_ON"} { if {$in} { incr iso_in } } \
  elseif {![string match psoI_* $nm]} { if {$in} { incr top_in } }
}
puts "\n######## DOMAIN PLACEMENT AUDIT ########"
puts "  u_core cells OUTSIDE PD_CORE fence : $core_out   (want 0)"
puts "  ISOLX1_ON cells INSIDE PD_CORE     : $iso_in   (want 0)"
puts "  other PD_TOP cells INSIDE PD_CORE  : $top_in   (want 0)"
puts "  ISOLX1_ON total                    : [llength [get_db insts -if {.base_cell.base_name == ISOLX1_ON}]]"
puts "  HSWX1 total                        : [llength [get_db insts -if {.base_cell.base_name == HSWX1}]]"

check_place reports/lp_place.chk
eval_legacy {verifyPowerDomain -bind -isoNetPD reports/vpd_iso_pl.rpt -xNetPD reports/vpd_xnet_pl.rpt}
eval_legacy {verifyConnectivity -nets {VDD VDD_CORE VSS} -type special -noAntenna -error 1000 -warning 50 -report reports/pg_conn_pl.rpt}
time_design -pre_cts -report_dir reports/prects -report_prefix prects

write_db lp_place.db
puts "\n######## LP PLACEMENT DONE ########"
