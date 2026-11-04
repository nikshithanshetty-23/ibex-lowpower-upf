# stream.tcl - write the final GDSII
source ../scripts/setup.tcl
read_db lp_route2.db
write_stream outputs/ibex_soc_lp.gds \
    -map_file streamOut_full.map \
    -lib_name DesignLib \
    -merge [list $CELL_GDS outputs/mem_stub_pins.gds] \
    -unit 2000 \
    -mode ALL
catch {write_netlist -include_pg_ports outputs/ibex_soc_lp_pg.v}
puts "\n######## LP GDS + PG NETLIST DONE ########"
exit
