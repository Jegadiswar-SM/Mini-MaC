# ============================================================
# SDC Constraints — Mini-MaC MAC Subsystem @ 100 MHz (10 ns)
# ============================================================
set PERIOD 10.0

create_clock -name clk -period $PERIOD [get_ports clk]
set_clock_uncertainty 0.5 [get_clocks clk]
set_clock_transition  0.3 [get_clocks clk]
set_clock_latency     1.0 [get_clocks clk]

set_input_delay  -clock clk 5.0 [all_inputs]
set_output_delay -clock clk 5.0 [all_outputs]

set_false_path -reset_path [get_ports rst_n]

set_max_fanout 8 [current_design]
set_max_transition 0.5 [current_design]

set_operating_conditions -library sky130_fd_sc_hd__tt_025C_1v80
