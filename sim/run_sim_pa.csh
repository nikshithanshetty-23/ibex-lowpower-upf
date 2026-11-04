#!/bin/csh -f
# run_sim_pa.csh - POWER-AWARE simulation (UPF) of ibex_soc in Xcelium
xrun -64bit -sv -timescale 1ns/1ps -access +rwc \
     -f sim.f -top tb_ibex_soc +define+PA_SIM \
     -lps_1801 ../upf/ibex_soc.upf -lps_dut_top tb_ibex_soc.dut \
     -lps_logfile lps.log -l xrun_pa.log $argv:q
