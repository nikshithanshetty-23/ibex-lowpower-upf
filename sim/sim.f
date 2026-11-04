// sim.f - RTL simulation file list (run from the sim/ folder)
// Uses the GENERIC behavioural clock gate (not the TLATNTSCAX2 wrapper)
// and the behavioural SRAM model.  SYNTHESIS is defined only to switch
// the lowRISC assertion macros off for this first bring-up.
+define+SYNTHESIS
+incdir+../rtl/ibex/vendor/lowrisc_ip/ip/prim/rtl
+incdir+../rtl/ibex/vendor/lowrisc_ip/dv/sv/dv_utils

../rtl/ibex/vendor/lowrisc_ip/ip/prim/rtl/prim_util_pkg.sv
../rtl/ibex/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_pkg.sv
../rtl/ibex/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi_pkg.sv
../rtl/ibex/vendor/lowrisc_ip/ip/prim/rtl/prim_cipher_pkg.sv
../rtl/ibex/vendor/lowrisc_ip/ip/prim/rtl/prim_count_pkg.sv
../rtl/ibex/vendor/lowrisc_ip/ip/prim_generic/rtl/prim_ram_1p_pkg.sv
../rtl/ibex/rtl/ibex_pkg.sv
../rtl/ibex/rtl/ibex_cheriot_pkg.sv

../rtl/ibex/vendor/lowrisc_ip/ip/prim_generic/rtl/prim_clock_gating.sv
../rtl/ibex/vendor/lowrisc_ip/ip/prim_generic/rtl/prim_buf.sv
../rtl/ibex/vendor/lowrisc_ip/ip/prim_generic/rtl/prim_flop.sv

../rtl/ibex/rtl/ibex_alu.sv
../rtl/ibex/rtl/ibex_compressed_decoder.sv
../rtl/ibex/rtl/ibex_controller.sv
../rtl/ibex/rtl/ibex_counter.sv
../rtl/ibex/rtl/ibex_csr.sv
../rtl/ibex/rtl/ibex_cs_registers.sv
../rtl/ibex/rtl/ibex_pmp.sv
../rtl/ibex/rtl/ibex_decoder.sv
../rtl/ibex/rtl/ibex_cheriot_ex.sv
../rtl/ibex/rtl/ibex_trvk.sv
../rtl/ibex/rtl/ibex_ex_block.sv
../rtl/ibex/rtl/ibex_id_stage.sv
../rtl/ibex/rtl/ibex_if_stage.sv
../rtl/ibex/rtl/ibex_load_store_unit.sv
../rtl/ibex/rtl/ibex_multdiv_slow.sv
../rtl/ibex/rtl/ibex_multdiv_fast.sv
../rtl/ibex/rtl/ibex_prefetch_buffer.sv
../rtl/ibex/rtl/ibex_fetch_fifo.sv
../rtl/ibex/rtl/ibex_register_file_ff.sv
../rtl/ibex/rtl/ibex_wb_stage.sv
../rtl/ibex/rtl/ibex_core.sv
../rtl/ibex/rtl/ibex_top.sv

../rtl/ibex_pmu.sv
../rtl/ibex_soc.sv
models/MEM1_1024X32_sim.v
tb_ibex_soc.sv
