################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../src/ap/UpCounter/UpCounter.c 

OBJS += \
./src/ap/UpCounter/UpCounter.o 

C_DEPS += \
./src/ap/UpCounter/UpCounter.d 


# Each subdirectory must supply rules for building sources it contributes
src/ap/UpCounter/%.o: ../src/ap/UpCounter/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: MicroBlaze gcc compiler'
	mb-gcc -Wall -O0 -g3 -c -fmessage-length=0 -MT"$@" -ID:/kmk/OnDeviceAI_Git/projects/260427_MicroBlaze_GPIO/vitis_workspace/microblaze_gpio8/export/microblaze_gpio8/sw/microblaze_gpio8/standalone_microblaze_0/bspinclude/include -mlittle-endian -mcpu=v11.0 -mxl-soft-mul -Wl,--no-relax -ffunction-sections -fdata-sections -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


