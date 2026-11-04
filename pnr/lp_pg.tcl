#=====================================================================
# lp_pg.tcl - power grid for power-gated Ibex (VDD, VDD_CORE, VSS)
# Run from pnr/:  innovus -stylus -files lp_pg.tcl -log lp_pg
#=====================================================================
source ../scripts/setup.tcl
read_db lp_sw.db
file mkdir reports

# PD_CORE box (from lp_fp.tcl)
set PDX0 515 ; set PDY0 40.47 ; set PDX1 695 ; set PDY1 488.49

# ---------- 1. core ring: always-on VDD + VSS ----------
add_rings -nets {VDD VSS} -type core_rings -follow core \
  -layer {top Metal11 bottom Metal11 left Metal10 right Metal10} \
  -width 5 -spacing 1.5 -offset 2

eval_legacy {setAddStripeMode -skip_via_on_pin {Pad Cover}}
# ---------- 2. ExtVDD of every switch: VDD Metal2 over the HSWX1 pins ----------
add_stripes -nets VDD -layer Metal2 -direction vertical -width 0.6 \
  -over_pins 1 -master HSWX1 -pin_layer Metal1 \
  -area [list $PDX0 $PDY0 $PDX1 $PDY1]

# ---------- 3. PD_CORE vertical: VDD_CORE + VSS (kept away from switch columns) ----------
add_stripes -nets {VDD_CORE VSS} -layer Metal10 -direction vertical \
  -width 2 -spacing 1 -set_to_set_distance 45 -start_offset 40 \
  -area [list $PDX0 $PDY0 $PDX1 $PDY1]

# ---------- 4. PD_TOP vertical: VDD + VSS (left part + thin strip right of PD_CORE) ----------
add_stripes -nets {VDD VSS} -layer Metal10 -direction vertical \
  -width 2 -spacing 1 -set_to_set_distance 50 -start_offset 15 \
  -area {25 25.08 513 503.88}
add_stripes -nets {VDD VSS} -layer Metal10 -direction vertical \
  -width 2 -spacing 1 -set_to_set_distance 50 -start_offset 2 \
  -area {697 25.08 705 503.88}

eval_legacy {setAddStripeMode -skip_via_on_pin {Pad Cover Standardcell} -ignore_nondefault_domains true}
# ---------- 5. horizontal Metal11 VDD + VSS across the whole core, into the ring ----------
add_stripes -nets {VDD VSS} -layer Metal11 -direction horizontal \
  -width 3 -spacing 1.5 -set_to_set_distance 60 -start_offset 30 \
  -area {11 25.08 719 503.88}

# ---------- 6. followpins (NO extension -> no VDD/VDD_CORE short) + SRAM pins ----------
route_special -connect core_pin -nets {VDD VDD_CORE VSS} -core_pin_target none \
  -allow_jogging 0 -allow_layer_change 0
route_special -connect block_pin -nets {VDD VSS} -block_pin_target nearest_target

# ---------- 7. audit ----------
puts "\n######## PG WIRES (count per layer) ########"
foreach n {VDD VDD_CORE VSS} {
  set s "  $n :"
  foreach L {Metal1 Metal2 Metal10 Metal11} {
    append s "  $L=[llength [get_db [get_db nets $n] .special_wires -if ".layer.name == $L"]]"
  }
  puts $s
}
set m2 [get_db [get_db nets VDD] .special_wires -if {.layer.name == Metal2}]
puts "  first VDD Metal2 wires: [get_db [lrange $m2 0 2] .rect]"

eval_legacy {verifyConnectivity -nets {VDD VDD_CORE VSS} -type special -noAntenna -error 1000 -warning 50 -report reports/pg_conn.rpt}
puts [exec cat reports/pg_conn.rpt]
check_drc -limit 1000 -out_file reports/pg_drc.rpt

write_db lp_pg.db
puts "\n######## LP POWER GRID DONE ########"
