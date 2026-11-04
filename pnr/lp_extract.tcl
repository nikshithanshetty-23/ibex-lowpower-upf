#=====================================================================
# lp_extract.tcl - SPEF (worst/best) + final netlist for Tempus
# Run from pnr/:  innovus -stylus -files lp_extract.tcl -log lp_extract
#=====================================================================
source ../scripts/setup.tcl
read_db lp_route2.db
file mkdir ../sta

set_db extract_rc_engine        post_route
set_db extract_rc_effort_level  medium
set_db extract_rc_coupled       true
extract_rc

write_parasitics -rc_corner rc_worst -spef_file ../sta/lp_worst.spef
write_parasitics -rc_corner rc_best  -spef_file ../sta/lp_best.spef
write_netlist ../sta/lp_final.v
puts "\n######## LP EXTRACT DONE ########"
exit
