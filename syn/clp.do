// clp.do - Conformal Low Power check of the LP synthesized netlist (native 1801)
set log file clp.log -replace
set lowpower option -native_1801
read library -lp -statetable -liberty -both \
  /home/install/FOUNDRY/lan/flow/t1u1/reference_libs/GPDK045/gsclib045_all_v4.4/gsclib045/timing/slow_vdd1v2_basicCells.lib \
  /home/install/FOUNDRY/lan/flow/t1u1/reference_libs/GPDK045/gsclib045_all_v4.4/gsclib045/timing/slow_vdd1v2_extvdd1v2.lib \
  /home/install/FOUNDRY/digital/45nm/LIBS/lib/max/MEM1_1024X32_slow.lib
read design -verilog -golden  outputs/ibex_soc_lp_syn.v -root ibex_soc
read design -verilog -revised outputs/ibex_soc_lp_syn.v -root ibex_soc
set root module ibex_soc -both
read power intent -1801 -golden  outputs/ibex_soc_lp_syn1.upf
read power intent -1801 -revised outputs/ibex_soc_lp_syn1.upf
set root module ibex_soc -both
set system mode lec
compare power consistency
report rule check -lp   -summary
report rule check -1801 -summary
report rule check -lp   -verbose > clp_lp.rpt
report rule check -1801 -verbose > clp_1801.rpt
exit -force
