# stream.tcl - write the final GDSII
source ../scripts/setup.tcl
read_db final.db
write_stream outputs/ibex_soc.gds \
    -map_file streamOut_full.map \
    -lib_name DesignLib \
    -merge [list $CELL_GDS outputs/mem_stub_pins.gds] \
    -unit 2000 \
    -mode ALL
puts "\n######## GDS DONE ########"
exit
