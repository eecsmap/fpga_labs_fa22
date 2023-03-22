# synthesis
read_verilog -v z1top.v
read_xdc z1top.xdc
synth_design -top z1top -part xc7z020clg400-1

# implementation
opt_design
place_design
phys_opt_design
route_design
write_bitstream -force z1top.bit

# load program
open_hw
connect_hw_server -url localhost:3121
current_hw_target [get_hw_targets */xilinx_tcf/Digilent/*]
set_property PARAM.FREQUENCY 15000000 [get_hw_targets */xilinx_tcf/Digilent/*]
open_hw_target

current_hw_device [get_hw_devices xc7z*]
set_property PROBES.FILE {} [get_hw_devices xc7z*]
set_property FULL_PROBES.FILE {} [get_hw_devices xc7z*]

set_property PROGRAM.FILE z1top.bit [get_hw_devices xc7z*]
program_hw_devices [get_hw_devices xc7z*]
refresh_hw_device [get_hw_devices xc7z*]

close_hw
