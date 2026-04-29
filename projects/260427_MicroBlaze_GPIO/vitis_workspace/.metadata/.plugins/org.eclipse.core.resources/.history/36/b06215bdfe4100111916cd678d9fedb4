#include <stdint.h>
#include "xparameters.h"
#include "sleep.h"
#include "xil_printf.h"

#define GPIOA_BASE_ADDR 0x44A00000
#define GPIOB_BASE_ADDR 0x44A10000

#define GPIOA_CR	(*(uint32_t *) (GPIOA_BASE_ADDR + 0x00))
#define GPIOA_IDR	(*(uint32_t *) (GPIOA_BASE_ADDR + 0x04))
#define GPIOA_ODR	(*(uint32_t *) (GPIOA_BASE_ADDR + 0x08))

#define GPIOB_CR	(*(uint32_t *) (GPIOB_BASE_ADDR + 0x00))
#define GPIOB_IDR	(*(uint32_t *) (GPIOB_BASE_ADDR + 0x04))
#define GPIOB_ODR	(*(uint32_t *) (GPIOB_BASE_ADDR + 0x08))

int main()
{
	GPIOA_CR = 0xff;
	GPIOB_CR = 0xff;

	while (1)
	{
		GPIOA_ODR = 0x00;
		GPIOB_ODR = 0x00;
		usleep(200000);
		GPIOA_ODR = 0xff;
		usleep(200000);
	}

	return 0;
}
