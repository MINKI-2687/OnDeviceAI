################################################################################
# Automatically-generated file. Do not edit!
################################################################################

-include ../makefile.init

RM := rm -rf

# All of the sources participating in the build are defined here
-include sources.mk
-include src/driver/FND/subdir.mk
-include src/driver/Button/subdir.mk
-include src/common/subdir.mk
-include src/ap/Watch/subdir.mk
-include src/ap/UpCounter/subdir.mk
-include src/ap/subdir.mk
-include src/HAL/GPIO/subdir.mk
-include src/subdir.mk
-include subdir.mk
-include objects.mk

ifneq ($(MAKECMDGOALS),clean)
ifneq ($(strip $(S_UPPER_DEPS)),)
-include $(S_UPPER_DEPS)
endif
ifneq ($(strip $(C_DEPS)),)
-include $(C_DEPS)
endif
endif

-include ../makefile.defs

# Add inputs and outputs from these tool invocations to the build variables 
ELFSIZE += \
fnd_upcounter.elf.size \


# All Target
all: fnd_upcounter.elf secondary-outputs

# Tool invocations
fnd_upcounter.elf: $(OBJS) ../src/lscript.ld $(USER_OBJS)
	@echo 'Building target: $@'
	@echo 'Invoking: MicroBlaze gcc linker'
	mb-gcc -Wl,-T -Wl,../src/lscript.ld -LD:/kmk/OnDeviceAI_Git/projects/260427_MicroBlaze_GPIO/vitis_workspace/microblaze_gpio8/export/microblaze_gpio8/sw/microblaze_gpio8/standalone_microblaze_0/bsplib/lib -mlittle-endian -mcpu=v11.0 -mxl-soft-mul -Wl,--no-relax -Wl,--gc-sections -o "fnd_upcounter.elf" $(OBJS) $(USER_OBJS) $(LIBS)
	@echo 'Finished building target: $@'
	@echo ' '

fnd_upcounter.elf.size: fnd_upcounter.elf
	@echo 'Invoking: MicroBlaze Print Size'
	mb-size fnd_upcounter.elf  |tee "fnd_upcounter.elf.size"
	@echo 'Finished building: $@'
	@echo ' '

# Other Targets
clean:
	-$(RM) $(EXECUTABLES)$(OBJS)$(S_UPPER_DEPS)$(C_DEPS)$(ELFSIZE) fnd_upcounter.elf
	-@echo ' '

secondary-outputs: $(ELFSIZE)

.PHONY: all clean dependents

-include ../makefile.targets
