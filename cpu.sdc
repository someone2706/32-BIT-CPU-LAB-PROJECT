# CLOCK

create_clock -name clk -period 10 [get_ports clk]
set_clock_uncertainty 0.2 [get_clocks clk]


# RESET (ASYNC)
# Do not time reset path
set_false_path -from [get_ports rst_n]

# Provide proper drive for reset (removes warning)
set_driving_cell -lib_cell INVX1 [get_ports rst_n]

# INPUT DELAYS (ONLY DATA INPUTS)
set_input_delay 2 -clock clk \
[remove_from_collection [all_inputs] [get_ports {clk rst_n}]]


# OUTPUT DELAYS
set_output_delay 2 -clock clk [all_outputs]

# INPUT DRIVE (DATA INPUTS ONLY)
set_driving_cell -lib_cell INVX1 
[remove_from_collection [all_inputs] [get_ports {clk rst_n}]]

# OUTPUT LOAD
set_load 0.1 [all_outputs]

# DESIGN RULE CONSTRAINTS

set_max_transition 0.5 [current_design]
set_max_fanout 10 [current_design]
