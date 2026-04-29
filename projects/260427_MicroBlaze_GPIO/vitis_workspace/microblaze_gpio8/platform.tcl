# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct D:\kmk\OnDeviceAI_Git\projects\260427_MicroBlaze_GPIO\vitis_workspace\microblaze_gpio8\platform.tcl
# 
# OR launch xsct and run below command.
# source D:\kmk\OnDeviceAI_Git\projects\260427_MicroBlaze_GPIO\vitis_workspace\microblaze_gpio8\platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {microblaze_gpio8}\
-hw {D:\kmk\OnDeviceAI_Git\projects\260427_MicroBlaze_GPIO\XSA\microblaze_gpio8.xsa}\
-fsbl-target {psu_cortexa53_0} -out {D:/kmk/OnDeviceAI_Git/projects/260427_MicroBlaze_GPIO/vitis_workspace}

platform write
domain create -name {standalone_microblaze_0} -display-name {standalone_microblaze_0} -os {standalone} -proc {microblaze_0} -runtime {cpp} -arch {32-bit} -support-app {empty_application}
platform generate -domains 
platform active {microblaze_gpio8}
platform generate -quick
platform generate
platform generate -domains standalone_microblaze_0 
