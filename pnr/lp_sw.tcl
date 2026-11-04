#=====================================================================
# lp_sw.tcl - insert HSWX1 header switches in PD_CORE (daisy-chained)
# Run from pnr/:  innovus -stylus -files lp_sw.tcl -log lp_sw
#=====================================================================
source ../scripts/setup.tcl
read_db lp_fp.db

# ---------------- info: switch cell + enable net ----------------
puts "\n######## HSWX1 CELL ########"
set bc [get_db base_cells HSWX1]
catch {puts "  bbox        : [get_db $bc .bbox]"}
catch {puts "  signal pins : [get_db $bc .base_pins.base_name]"}
catch {puts "  pg pins     : [get_db $bc .pg_base_pins.base_name]"}
if {[llength [get_db nets core_pso]] == 0} {
  puts "  !! net core_pso NOT found. Candidates: [get_db [get_db nets *pso*] .name]"
} else {
  puts "  enable net core_pso found"
}

# ---------------- insert switches ----------------
eval_legacy {addPowerSwitch -column -powerDomain PD_CORE -globalSwitchCellName HSWX1 \
   -leftOffset 20 -horizontalPitch 45 -checkerBoard \
   -enablePinIn PSO -enablePinOut PSO_out -enableNetIn core_pso -enableNetOut core_pso_ack}

# ---------------- audit ----------------
set sws [get_db insts -if {.base_cell.base_name == HSWX1}]
set head 0 ; set chained 0
foreach s $sws {
  set drv ""
  catch {set drv [get_db [get_db pins [get_db $s .name]/PSO] .net.drivers.inst.base_cell.base_name]}
  if {[lsearch $drv HSWX1] >= 0} { incr chained } else { incr head }
}
puts "\n######## POWER SWITCH AUDIT ########"
puts "  HSWX1 inserted                   : [llength $sws]"
puts "  PSO driven by previous switch    : $chained  (daisy chain)"
puts "  PSO driven by PMU (chain heads)  : $head"
puts "  PG pins of first switch:"
catch {foreach pg [get_db [lindex $sws 0] .pg_pins] { puts "    [get_db $pg .name] -> [get_db $pg .net.name]" }}

write_db lp_sw.db
puts "\n######## POWER SWITCHES DONE ########"
