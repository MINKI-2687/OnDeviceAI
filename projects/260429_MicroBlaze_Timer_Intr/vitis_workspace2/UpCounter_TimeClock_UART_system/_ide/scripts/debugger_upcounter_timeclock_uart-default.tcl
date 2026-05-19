# Usage with Vitis IDE:
# In Vitis IDE create a Single Application Debug launch configuration,
# change the debug type to 'Attach to running target' and provide this 
# tcl script in 'Execute Script' option.
# Path of this script: D:\kmk\OnDeviceAI_Git\projects\260429_MicroBlaze_Timer_Intr\vitis_workspace2\UpCounter_TimeClock_UART_system\_ide\scripts\debugger_upcounter_timeclock_uart-default.tcl
# 
# 
# Usage with xsct:
# To debug using xsct, launch xsct and run below command
# source D:\kmk\OnDeviceAI_Git\projects\260429_MicroBlaze_Timer_Intr\vitis_workspace2\UpCounter_TimeClock_UART_system\_ide\scripts\debugger_upcounter_timeclock_uart-default.tcl
# 
connect -url tcp:127.0.0.1:3121
targets -set -filter {jtag_cable_name =~ "Digilent Basys3 210183BB79F9A" && level==0 && jtag_device_ctx=="jsn-Basys3-210183BB79F9A-0362d093-0"}
fpga -file D:/kmk/OnDeviceAI_Git/projects/260429_MicroBlaze_Timer_Intr/vitis_workspace2/UpCounter_TimeClock_UART/_ide/bitstream/design_1_wrapper_uart.bit
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
loadhw -hw D:/kmk/OnDeviceAI_Git/projects/260429_MicroBlaze_Timer_Intr/vitis_workspace2/design_1_wrapper_uart/export/design_1_wrapper_uart/hw/design_1_wrapper_uart.xsa -regs
configparams mdm-detect-bscan-mask 2
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
rst -system
after 3000
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
dow D:/kmk/OnDeviceAI_Git/projects/260429_MicroBlaze_Timer_Intr/vitis_workspace2/UpCounter_TimeClock_UART/Debug/UpCounter_TimeClock_UART.elf
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
con
