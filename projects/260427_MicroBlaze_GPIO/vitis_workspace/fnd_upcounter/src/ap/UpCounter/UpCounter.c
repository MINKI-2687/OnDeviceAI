#include "UpCounter.h"

hBtn_t hBtnRunStop, hBtnClear;
uint16_t counter = 0;

void UpCounter_Init()
{
    FND_Init();
    Button_Init(&hBtnRunStop, GPIOA, GPIO_PIN_4);
    Button_Init(&hBtnClear, GPIOA, GPIO_PIN_7);

    counter = 0;
}

void UpCounter_Execute()
{
    UpCounter_DispLoop();

    static upcounter_state_t upCounterState = UPCOUNTER_STOP;

    switch (upCounterState)
    {
        case UPCOUNTER_STOP:
            UpCounter_Stop();
            if (Button_GetState(&hBtnRunStop) == ACT_PUSHED) {
                upCounterState = UPCOUNTER_RUN;
            }
            else if (Button_GetState(&hBtnClear) == ACT_PUSHED) {
                upCounterState = UPCOUNTER_CLEAR;
            }
            break;
        case UPCOUNTER_RUN:
            UpCounter_Run();
            if (Button_GetState(&hBtnRunStop) == ACT_PUSHED) {
                upCounterState = UPCOUNTER_STOP;
            }
            break;
        case UPCOUNTER_CLEAR:
            UpCounter_Clear();
            upCounterState = UPCOUNTER_STOP;
            break;
        default:
            UpCounter_Stop();
            break;
    }
}

void UpCounter_DispLoop()
{
    FND_DispDigit();
}

void UpCounter_Run()
{
	static uint32_t prevTimeCounter = 0;
    
	if (millis() - prevTimeCounter < 100-1) {
        return;
    }
    prevTimeCounter = millis();
    
    FND_SetNum(counter++);
}

void UpCounter_Stop()
{
    FND_SetNum(counter);
}

void UpCounter_Clear()
{
    counter = 0;
    FND_SetNum(counter);
}
