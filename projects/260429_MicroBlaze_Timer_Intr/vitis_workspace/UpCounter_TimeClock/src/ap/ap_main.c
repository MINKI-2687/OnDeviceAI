#include "xil_printf.h"

#include "ap_main.h"
#include "../HAL/TMR/TMR.h"
#include "../driver/Button/Button.h"
#include "../driver/Led/Led.h"
#include "../common/common.h"

#include "DispService/DispService.h"
#include "UpCounter/UpCounter.h"
#include "TimeClock/TimeClock.h"
#include "interrupt.h"

static modeState_t modeState = MODE_TIMECLOCK;
static hBtn_t hbtnMode;

void ap_init() {
	Button_Init(&hbtnMode, GPIOA, GPIO_PIN_5);
	Disp_Init();

	UpCounter_Init();
	TimeClock_Init();
	SetupInterruptSystem();
	TMR0_Init();
	TMR1_Init();
	TMR2_Init();

}

void ap_execute() {
	while (1) {
		switch (modeState) {
		case MODE_TIMECLOCK:
			TimeClock_Execute();
			Disp_SetMode(DISP_TIME_CLOCK);
			if (Button_GetState(&hbtnMode) == ACT_RELEASED) {
				modeState = MODE_UPCOUNTER;
				FND_SetDp(FND_DIGIT_100, OFF);
			}
			break;
		case MODE_UPCOUNTER:
			UpCounter_Execute();
			Disp_SetMode(DISP_UP_COUNTER);
			if (Button_GetState(&hbtnMode) == ACT_RELEASED) {
				modeState = MODE_TIMECLOCK;
			}
			break;
		}
	}
}

