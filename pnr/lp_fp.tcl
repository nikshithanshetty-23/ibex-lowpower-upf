#=====================================================================
# lp_fp.tcl - LOW-POWER Ibex: import with UPF, floorplan, PD_CORE region
# Run from pnr/:  innovus -stylus -files lp_fp.tcl -log lp_fp
#=====================================================================
source ../scripts/setup.tcl
file mkdir reports

# ---------------- import ----------------
set_db init_power_nets  {VDD VDD_CORE}
set_db init_ground_nets {VSS}
read_mmmc mmmc.tcl
read_physical -lef $LEF_LIST
read_netlist ../syn/outputs/ibex_soc_lp_syn.v -top ibex_soc
init_design
set genus_iso [get_db [get_db insts -if {.base_cell.base_name == ISOLX1_ON}] .name]

# ---------------- power intent ----------------
read_power_intent -1801 ../syn/outputs/ibex_soc_lp_syn1.upf
commit_power_intent

# ---------------- remove iso cells Innovus added on UNUSED core outputs ----------------
set removed 0
foreach i [get_db insts -if {.base_cell.base_name == ISOLX1_ON}] {
  set nm [get_db $i .name]
  if {[lsearch -exact $genus_iso $nm] >= 0} { continue }      ;# keep Genus cells
  set nld 0
  catch {set nld [llength [get_db [get_db pins $nm/Y] .net.loads]]}
  if {$nld == 0} { delete_inst -inst $nm ; incr removed }
}

# ---------------- floorplan: 680 x 478.8 um core, 25 um margins ----------------
eval_legacy {floorPlan -site CoreSite -s 680 478.8 25 25 25 25}

place_inst u_imem 35 35 MX -fixed
place_inst u_dmem 35 [expr {25 + 478.8 - 10 - 168.5}] R0 -fixed
create_place_halo -insts u_imem -halo_deltas {10 10 10 10}
create_place_halo -insts u_dmem -halo_deltas {10 10 10 10}

# ---------------- switchable domain fence (snapped to rows: 1.71 um) ----------------
eval_legacy {modifyPowerDomainAttr PD_CORE -box 515 40.47 695 488.49 -minGaps 2 2 2 2}

# ---------------- checks ----------------
puts "\n######## POWER DOMAINS ########"
foreach pd [get_db power_domains] { puts "  [get_db $pd .name]" }
eval_legacy {verifyPowerDomain -bind -isoNetPD reports/vpd_iso.rpt -xNetPD reports/vpd_xnet.rpt}

puts "\n######## ISOLATION SUMMARY ########"
puts "  ISOLX1_ON from Genus              : [llength $genus_iso]"
puts "  removed (Innovus-added, no load)  : $removed"
puts "  ISOLX1_ON now in design           : [llength [get_db insts -if {.base_cell.base_name == ISOLX1_ON}]]"

check_floorplan
write_db lp_fp.db
puts "\n######## LP FLOORPLAN DONE ########"
