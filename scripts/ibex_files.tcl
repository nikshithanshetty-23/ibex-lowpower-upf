#=====================================================================
# ibex_files.tcl  -  ordered RTL file list for SYNTHESIS (Genus)
# Needs setup.tcl sourced first (uses $PROJ)
#=====================================================================

set IBEX   $PROJ/rtl/ibex
set PRIM   $IBEX/vendor/lowrisc_ip/ip/prim/rtl
set PRIMG  $IBEX/vendor/lowrisc_ip/ip/prim_generic/rtl

# ---- Include directories (for `include "prim_assert.sv" / "dv_fcov_macros.svh") ----
set INC_DIRS [list \
  $PRIM \
  $IBEX/vendor/lowrisc_ip/dv/sv/dv_utils \
]

# prim_ram_1p_pkg.sv is not in prim/rtl -> locate it automatically
set RAM1P_PKG [lindex [exec find $IBEX/vendor -name prim_ram_1p_pkg.sv] 0]
if {$RAM1P_PKG eq ""} { error "prim_ram_1p_pkg.sv not found under $IBEX/vendor" }

# ---- Files, in dependency order: packages first, then leaf modules, top last ----
set RTL_FILES [list \
  $PRIM/prim_util_pkg.sv \
  $PRIM/prim_secded_pkg.sv \
  $RAM1P_PKG \
  $IBEX/rtl/ibex_pkg.sv \
  $IBEX/rtl/ibex_cheriot_pkg.sv \
  \
  $PROJ/rtl/tech/prim_clock_gating.sv \
  $PRIMG/prim_buf.sv \
  $PRIMG/prim_flop.sv \
  \
  $IBEX/rtl/ibex_alu.sv \
  $IBEX/rtl/ibex_compressed_decoder.sv \
  $IBEX/rtl/ibex_controller.sv \
  $IBEX/rtl/ibex_counter.sv \
  $IBEX/rtl/ibex_csr.sv \
  $IBEX/rtl/ibex_cs_registers.sv \
  $IBEX/rtl/ibex_pmp.sv \
  $IBEX/rtl/ibex_decoder.sv \
  $IBEX/rtl/ibex_cheriot_ex.sv \
  $IBEX/rtl/ibex_trvk.sv \
  $IBEX/rtl/ibex_ex_block.sv \
  $IBEX/rtl/ibex_id_stage.sv \
  $IBEX/rtl/ibex_if_stage.sv \
  $IBEX/rtl/ibex_load_store_unit.sv \
  $IBEX/rtl/ibex_multdiv_slow.sv \
  $IBEX/rtl/ibex_multdiv_fast.sv \
  $IBEX/rtl/ibex_prefetch_buffer.sv \
  $IBEX/rtl/ibex_fetch_fifo.sv \
  $IBEX/rtl/ibex_register_file_ff.sv \
  $IBEX/rtl/ibex_wb_stage.sv \
  $IBEX/rtl/ibex_core.sv \
  $IBEX/rtl/ibex_top.sv \
  \
  $PROJ/rtl/ibex_soc.sv \
]
# NOTE: the SRAM is a black box from $MEM_LIB in synthesis.
#       sim/models/MEM1_1024X32_sim.v is for
