#=====================================================================
# mmmc.tcl  -  Multi-Mode Multi-Corner setup for Innovus
# setup  : slow libs (1.08V,125C) + RC at 125C
# hold   : fast libs (1.32V,  0C) + RC at   0C
# NOTES:
#  - SRAM has only a slow model -> reused in the fast set
#  - LIBS captables have 9 layers but tech LEF has 11 -> use the QRC
#    tech file from the same kit as the tech LEF (gpdk045.tch)
#  - Use the hand-written SDC (Genus SDC names the slow library in
#    set_driving_cell, which breaks the hold view)
#=====================================================================

# ---- 1. Library sets ----
create_library_set -name libs_slow -timing [list $LIB_SLOW $LIB_SLOW_LP $MEM_LIB]
create_library_set -name libs_fast -timing [list $LIB_FAST $LIB_FAST_LP $MEM_LIB]

# ---- 2. Timing conditions ----
create_timing_condition -name tc_slow -library_sets libs_slow
create_timing_condition -name tc_fast -library_sets libs_fast

# ---- 3. RC corners (QRC tech file, matches the 11-layer tech LEF) ----
create_rc_corner -name rc_worst -qrc_tech $QRC_TECH -temperature 125
create_rc_corner -name rc_best  -qrc_tech $QRC_TECH -temperature 0

# ---- 4. Delay corners ----
create_delay_corner -name dc_slow -timing_condition tc_slow -rc_corner rc_worst
create_delay_corner -name dc_fast -timing_condition tc_fast -rc_corner rc_best

# ---- 5. Constraint mode = our hand-written SDC ----
create_constraint_mode -name func -sdc_files [list $PROJ/constraints/ibex_soc_signoff.sdc]

# ---- 6. Analysis views ----
create_analysis_view -name view_setup -constraint_mode func -delay_corner dc_slow
create_analysis_view -name view_hold  -constraint_mode func -delay_corner dc_fast

set_analysis_view -setup [list view_setup] -hold [list view_hold]
