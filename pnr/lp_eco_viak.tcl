 #=====================================================================
# lp_eco_viak.tcl - fix Pegasus VIAk.X.3/X.4 (stacked-via) results
# same method as Project 1: cap affected nets at Metal5 and reroute
# Run from pnr/:  innovus -stylus -files lp_eco_viak.tcl -log lp_eco_viak
#=====================================================================
source ../scripts/setup.tcl
read_db lp_final.db

# ---------- 1. nets at each Pegasus marker ----------
set fh [open reports/viak_xy.txt] ; set lines [split [read $fh] "\n"] ; close $fh
set nets {} ; set nbox 0
foreach l $lines {
  if {![regexp {x=\s*([0-9.]+)\.\.\s*([0-9.]+)\s+y=\s*([0-9.]+)\.\.\s*([0-9.]+)} $l -> x1 x2 y1 y2]} { continue }
  incr nbox
  set box [list [expr {$x1-0.15}] [expr {$y1-0.15}] [expr {$x2+0.15}] [expr {$y2+0.15}]]
  foreach v [get_obj_in_area -areas [list $box] -obj_type {via wire}] {
    set n [get_db $v .net.name]
    if {$n ne "" && [lsearch -exact {VDD VSS VDD_CORE} $n] < 0} { lappend nets $n }
  }
}
set nets [lsort -unique $nets]
puts "\n######## VIAk markers: $nbox   signal nets found: [llength $nets] ########"

# ---------- 2. cap at Metal5 + reroute ----------
foreach n $nets { set_db [get_db nets $n] .top_preferred_layer Metal5 }
delete_routes -net $nets
route_eco

write_db lp_final2.db
puts "######## LP FINAL2 SAVED ########"

# ---------- 3. checks ----------
catch {check_drc -limit 1000 -out_file reports/final2_drc.rpt}
catch {eval_legacy {verifyConnectivity -type regular -noAntenna -error 1000 -warning 50 -report reports/final2_conn.rpt}}
catch {time_design -post_route       -report_dir reports/final2 -report_prefix f2}
catch {time_design -post_route -hold -report_dir reports/final2 -report_prefix f2_hold}

# ---------- 4. GDS + PG netlist ----------
write_stream outputs/ibex_soc_lp.gds -map_file streamOut_full.map -lib_name DesignLib \
    -merge [list $CELL_GDS outputs/mem_stub_pins.gds] -unit 2000 -mode ALL
catch {write_netlist -include_pg_ports outputs/ibex_soc_lp_pg.v}
puts "\n######## LP ECO VIAk DONE ########"
exit
