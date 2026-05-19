# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct D:\kmk\OnDeviceAI_Git\projects\260505_MicroBlaze_I2C\vitis_workspace\AXI4_I2C_design_1_wrapper\platform.tcl
# 
# OR launch xsct and run below command.
# source D:\kmk\OnDeviceAI_Git\projects\260505_MicroBlaze_I2C\vitis_workspace\AXI4_I2C_design_1_wrapper\platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {AXI4_I2C_design_1_wrapper}\
-hw {D:\kmk\OnDeviceAI_Git\projects\260505_MicroBlaze_I2C\XSA\AXI4_I2C_design_1_wrapper.xsa}\
-fsbl-target {psu_cortexa53_0} -out {D:/kmk/OnDeviceAI_Git/projects/260505_MicroBlaze_I2C/vitis_workspace}

platform write
domain create -name {standalone_microblaze_0} -display-name {standalone_microblaze_0} -os {standalone} -proc {microblaze_0} -runtime {cpp} -arch {32-bit} -support-app {empty_application}
platform generate -domains 
platform active {AXI4_I2C_design_1_wrapper}
platform generate -quick
platform generate
