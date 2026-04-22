# Usage with Vitis IDE:
# In Vitis IDE create a Single Application Debug launch configuration,
# change the debug type to 'Attach to running target' and provide this 
# tcl script in 'Execute Script' option.
# Path of this script: D:\kmk\OnDeviceAI_Git\projects\260422_AXI_GPIO\vitis_workspace\hello_gpio_system\_ide\scripts\debugger_hello_gpio-default.tcl
# 
# 
# Usage with xsct:
# To debug using xsct, launch xsct and run below command
# source D:\kmk\OnDeviceAI_Git\projects\260422_AXI_GPIO\vitis_workspace\hello_gpio_system\_ide\scripts\debugger_hello_gpio-default.tcl
# 
connect -url tcp:127.0.0.1:3121
targets -set -filter {jtag_cable_name =~ "Digilent Basys3 210183B822A5A" && level==0 && jtag_device_ctx=="jsn-Basys3-210183B822A5A-0362d093-0"}
fpga -file D:/kmk/OnDeviceAI_Git/projects/260422_AXI_GPIO/vitis_workspace/hello_gpio/_ide/bitstream/MicroBlaze_GPIO_design_1_wrapper.bit
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
loadhw -hw D:/kmk/OnDeviceAI_Git/projects/260422_AXI_GPIO/vitis_workspace/MicroBlaze_GPIO_design_1_wrapper/export/MicroBlaze_GPIO_design_1_wrapper/hw/MicroBlaze_GPIO_design_1_wrapper.xsa -regs
configparams mdm-detect-bscan-mask 2
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
rst -system
after 3000
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
dow D:/kmk/OnDeviceAI_Git/projects/260422_AXI_GPIO/vitis_workspace/hello_gpio/Debug/hello_gpio.elf
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
con
