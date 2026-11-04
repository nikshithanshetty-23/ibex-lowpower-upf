#=====================================================================
# lp_pin_eco.tcl - move load_data_i pins into the channel between SRAMs
# Run from pnr/:  innovus -stylus -files lp_pin_eco.tcl -log lp_pin_eco
#=====================================================================
source ../scripts/setup.tcl
read_db lp_final2.db

set pins [get_db [get_db ports load_data_i*] .name]
puts "load_data pins: [llength $pins]"
set_db assign_pins_edit_in_batch true
edit_pin -pin $pins -side Left -layer Metal5 -spread_type range -start {0 230} -end {0 294} -fixed_pin 1 -snap track
set_db assign_pins_edit_in_batch false
foreach p {load_data_i\[0\] load_data_i\[31\]} {
  puts "PINQ $p : [get_db [get_db ports $p] .physical_pins.layer_shapes.layer.name] [get_db [get_db ports $p] .physical_pins.layer_shapes.shapes.rect]"
}
route_eco

write_db lp_final3.db
puts "######## LP FINAL3 SAVED ########"
catch {check_drc -limit 1000 -out_file reports/final3_drc.rpt}
catch {eval_legacy {verifyConnectivity -type regular -noAntenna -error 1000 -warning 50 -report reports/final3_conn.rpt}}
catch {time_design -post_route       -report_dir reports/final3 -report_prefix f3}
catch {time_design -post_route -hold -report_dir reports/final3 -report_prefix f3_hold}
write_stream outputs/ibex_soc_lp.gds -map_file streamOut_full.map -lib_name DesignLib \
    -merge [list $CELL_GDS outputs/mem_stub_pins.gds] -unit 2000 -mode ALL
catch {write_netlist -include_pg_ports outputs/ibex_soc_lp_pg.v}
puts "\n######## LP PIN ECO DONE ########"
exit
