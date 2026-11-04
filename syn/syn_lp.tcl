#=====================================================================
# syn_lp.tcl - POWER-AWARE synthesis of ibex_soc with UPF (Genus)
# Run from syn/:   genus -files syn_lp.tcl -log syn_lp
#=====================================================================
source ../scripts/setup.tcl
source ../scripts/ibex_files.tcl
file mkdir reports outputs

# PMU must be compiled before ibex_soc (the last file in the list)
set RTL_FILES [linsert $RTL_FILES end-1 $PROJ/rtl/ibex_pmu.sv]

# ---- libraries: std cells + low-power cells (1.2V same-voltage lib) + SRAM
set LIB_SLOW_LP $T/slow_vdd1v2_extvdd1v2.lib
read_libs [list $LIB_SLOW $LIB_SLOW_LP $MEM_LIB]

# low-power cells must NOT be used for normal logic -> dont_use,
# except the isolation cell we want Genus to insert (ISOLX1_ON)
foreach c [get_db lib_cells] {
  set n [get_db $c .base_name]
  if {[regexp {^(RDFF|SRDFF|RTLAT|HSW|FSW|ISO|PBUF|PINV|LSHL|LSLH)} $n] && $n ne "ISOLX1_ON"} {
    set_db $c .dont_use true
  }
}
set_db [get_db lib_cells */ISOLX1_ON] .dont_use false

# ---- RTL
set_db init_hdl_search_path $INC_DIRS
read_hdl -language sv -define SYNTHESIS $RTL_FILES
elaborate ibex_soc

# ---- power intent
read_power_intent -1801 ../upf/ibex_soc_syn.upf -module ibex_soc
apply_power_intent
read_sdc ../constraints/ibex_soc.sdc
commit_power_intent

# ---- synthesis
syn_generic
syn_map
syn_opt

# ---- reports
report_timing -max_paths 5      > reports/lp_timing.rpt
report_area                     > reports/lp_area.rpt
report_power                    > reports/lp_power.rpt
report_qor                      > reports/lp_qor.rpt
puts "\n######## ISOLATION CELLS INSERTED ########"
set iso [get_db insts -if {.base_cell.base_name == ISOLX1_ON}]
puts "ISOLX1_ON instances: [llength $iso]"
foreach i [lrange $iso 0 4] { puts "  [get_db $i .name]" }

# ---- outputs: netlist + UPF for Innovus
write_hdl                       > outputs/ibex_soc_lp_syn.v
write_sdc                       > outputs/ibex_soc_lp_syn.sdc
write_power_intent -1801 -base_name outputs/ibex_soc_lp_syn
puts "\n######## LP SYNTHESIS DONE ########"
