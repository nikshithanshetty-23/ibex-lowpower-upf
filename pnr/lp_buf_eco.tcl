#=====================================================================
# lp_buf_eco.tcl - one input buffer per load_data_i net (LVS anchor)
# Run from pnr/:  innovus -stylus -files lp_buf_eco.tcl -log lp_buf_eco
#=====================================================================
source ../scripts/setup.tcl
read_db lp_final3.db

# 1. remove fillers
set nf 0
foreach b {FILL64 FILL32 FILL16 FILL8 FILL4 FILL2 FILL1} {
  set f [get_db insts -if ".base_cell.base_name == $b"]
  incr nf [llength $f]
  if {[llength $f]} { delete_obj $f }
}
puts "BUFECO fillers removed: $nf"

# 2. one BUFX4 on each load_data_i net
set nb 0
for {set i 0} {$i < 32} {incr i} {
  set n "load_data_i\[$i\]"
  if {![catch {eval_legacy [list ecoAddRepeater -net $n -cell BUFX4]}]} { incr nb }
}
puts "BUFECO buffers added: $nb"

# 3. legalize, route, fillers back
place_detail
route_eco
set_db add_fillers_cells {FILL64 FILL32 FILL16 FILL8 FILL4 FILL2 FILL1}
add_fillers -prefix FILLER
write_db lp_final4.db
puts "BUFECO LP FINAL4 SAVED"

# 4. checks + outputs
catch {check_drc -limit 1000 -out_file reports/final4_drc.rpt}
catch {eval_legacy {verifyConnectivity -type regular -noAntenna -error 1000 -warning 50 -report reports/final4_conn.rpt}}
catch {eval_legacy {verifyConnectivity -nets {VDD VDD_CORE VSS} -type special -noAntenna -error 1000 -warning 50 -report reports/final4_pg.rpt}}
catch {time_design -post_route       -report_dir reports/final4 -report_prefix f4}
catch {time_design -post_route -hold -report_dir reports/final4 -report_prefix f4_hold}
write_stream outputs/ibex_soc_lp.gds -map_file streamOut_full.map -lib_name DesignLib \
    -merge [list $CELL_GDS outputs/mem_stub_pins.gds] -unit 2000 -mode ALL
catch {write_netlist -include_pg_ports outputs/ibex_soc_lp_pg.v}
puts "BUFECO DONE"
exit
