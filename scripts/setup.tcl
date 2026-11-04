#=====================================================================
# setup.tcl  -  Ibex RTL-to-GDS project : common paths & settings
# Source this at the top of every Genus / Innovus / Tempus / Voltus script:
#     source ../scripts/setup.tcl
#=====================================================================

# ---------------- Project ----------------
set PROJ      /home/vlsi/Documents/LOWPOWER_IBEX

# ---------------- Kit roots ----------------
set G   /home/install/FOUNDRY/lan/flow/t1u1/reference_libs/GPDK045/gsclib045_all_v4.4
set T   $G/gsclib045/timing
set L   /home/install/FOUNDRY/digital/45nm/LIBS

# ---------------- Std cells (SVT, 1.2V nominal) ----------------
set LIB_SLOW      $T/slow_vdd1v2_basicCells.lib     ;# 1.08V 125C -> setup
set LIB_FAST      $T/fast_vdd1v2_basicCells.lib     ;# 1.32V   0C -> hold

# Multi-Vt (used later for Vt-swap ECO / leakage)
set LIB_SLOW_HVT  $G/gsclib045_hvt/timing/slow_vdd1v2_basicCells_hvt.lib
set LIB_FAST_HVT  $G/gsclib045_hvt/timing/fast_vdd1v2_basicCells_hvt.lib
set LIB_SLOW_LVT  $G/gsclib045_lvt/timing/slow_vdd1v2_basicCells_lvt.lib
set LIB_FAST_LVT  $G/gsclib045_lvt/timing/fast_vdd1v2_basicCells_lvt.lib

# ---------------- SRAM macros (single-port 1024x32 = 4KB) ----------------
# Only a slow (1.08V,125C) model exists -> reused in the fast view (note in report)
set MEM_NAME      MEM1_1024X32
set MEM_LIB       $L/lib/max/MEM1_1024X32_slow.lib
set MEM_LEF       $L/lef/MEM1_1024X32.lef          ;# 436.145 x 168.5 um, Metal1-6

# ---------------- Physical ----------------
set TECH_LEF      $G/gsclib045_tech/lef/gsclib045_tech.lef
set CELL_LEF      $G/gsclib045/lef/gsclib045_macro.lef
set LEF_LIST      [list $TECH_LEF $CELL_LEF $MEM_LEF]

# ---------------- RC / extraction ----------------
set CAP_WORST     $L/captbl/worst/capTable
set CAP_BEST      $L/captbl/best/capTable
set QRC_TECH      $G/gsclib045_tech/qrc/qx/gpdk045.tch

# ---------------- GDS (for final stream-out merge) ----------------
set CELL_GDS      $G/gsclib045/gds/gsclib045.gds
set CELL_GDS_HVT  $G/gsclib045_hvt/gds/gsclib045_hvt.gds
set CELL_GDS_LVT  $G/gsclib045_lvt/gds/gsclib045_lvt.gds
# SRAM GDS: not available -> macros stay black boxes in GDS/DRC/LVS

# ---------------- Clock gating cell (Ibex prim_clock_gating) ----------------
# TLATNTSCAX2 pins:  CK = clock in, E = enable, SE = test enable, ECK = gated clock out
set ICG_CELL      TLATNTSCAX2

# ---------------- Supply ----------------
set VDD_NOM       1.2
set PWR_NET       VDD
set GND_NET       VSS

# ---------------- Low-power cell libraries (Project 4) ----------------
set LIB_SLOW_LP $T/slow_vdd1v2_extvdd1v2.lib   ;# HSWX1, ISOLX1_ON, RDFF..., PBUF
set LIB_FAST_LP $T/fast_vdd1v2_extvdd1v2.lib
