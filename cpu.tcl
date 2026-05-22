read_libs /home/install/FOUNDRY/digital/90nm/dig/lib/slow.lib
read_hdl cpu_core.v
elaborate
read_sdc cpu.sdc
set_db syn_generic_effort medium 
set_db syn_map_effort medium 
set_db syn_opt_effort medium 
syn_generic
syn_map
syn_opt
report_timing > cpu_timing.rep
report_area > cpu_area.rep
report_power > cpu_pwr.rep
write_hdl > cpu_net.v
write_sdc > cpuop.sdc
gui_show
