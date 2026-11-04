#=====================================================================
# lp_final.tcl - pin fix + fillers + checks -> lp_final.db + GDS + PG netlist
# Run from pnr/:  innovus -stylus -files lp_final.tcl -log lp_final
#=====================================================================
source ../scripts/setup.tcl
read_db lp_route2.db

# ---------- 1. move load_addr_i[5] from Metal10 to Metal4, reroute it ----------
catch {edit_pin -pin {load_addr_i[5]} -layer Metal4 -assign {483.1 0} -side Bottom -fixed_pin 1 -snap track}
puts "load_addr_i\[5\] pin layer now: [get_db [get_db ports {load_addr_i[5]}] .physical_pins.layer_shapes.layer.name]"
route_eco

# ---------- 2. fillers everywhere (remove strap blockages first) ----------
puts "blockages before: [llength [get_db place_blockages]]"; delete_obj [get_db place_blockages strap_*]; puts "blockages after: [llength [get_db place_blockages]]"
set fills [lsort -dictionary -decreasing [get_db [get_db base_cells FILL*] .name]]
puts "filler cells: $fills"
set_db add_fillers_cells $fills
add_fillers -prefix FILLER
puts "######## fillers added: [llength [get_db insts FILLER*]] ########"

write_db lp_final.db
puts "######## LP FINAL SAVED ########"

# ---------- 3. checks ----------
catch {check_drc -limit 1000 -out_file reports/final_drc.rpt}
catch {eval_legacy {verifyConnectivity -type regular -noAntenna -error 1000 -warning 50 -report reports/final_conn.rpt}}
catch {eval_legacy {verifyConnectivity -nets {VDD VDD_CORE VSS} -type special -noAntenna -error 1000 -warning 50 -report reports/final_pg.rpt}}

# ---------- 4. GDS + PG netlist ----------
write_stream outputs/ibex_soc_lp.gds -map_file streamOut_full.map -lib_name DesignLib \
    -merge [list $CELL_GDS outputs/mem_stub_pins.gds] -unit 2000 -mode ALL
catch {write_netlist -include_pg_ports outputs/ibex_soc_lp_pg.v}
puts "\n######## LP FINAL DONE ########"
exit
