## Clock and reset (keep these as before)
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk -period 10.000 -waveform {0 5} [get_ports clk]

set_property PACKAGE_PIN U18 [get_ports rstn]
set_property IOSTANDARD LVCMOS33 [get_ports rstn]

## UART TX: map your top-level 'tx' port to A18 (FTDI on many Basys3 setups)
set_property PACKAGE_PIN A18 [get_ports tx]
set_property IOSTANDARD LVCMOS33 [get_ports tx]

## Generated clock for internal divider (if you have clk_div_inst)
create_generated_clock -name slow_clk -source [get_ports clk] [get_pins clk_div_inst/clk_out_reg/Q] -divide_by 4
