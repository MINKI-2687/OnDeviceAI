/*
 * Watch.c
 *
 *  Created on: 2026. 4. 28.
 *      Author: kccistc
 */

#include "Watch.h"
#include "xil_printf.h"

// 변수
time_data_t watchTime;
uint32_t prevTimeWatch = 0;

static watch_state_t watchState = WATCH_RUN;
hBtn_t hBtnClear;

void Watch_Init()
{
    FND_Init();
    Button_Init(&hBtnClear, GPIOA, GPIO_PIN_7);

    watchTime.hh = 0;
    watchTime.mm = 0;
    watchTime.ss = 0;
    watchTime.ms = 0;
    prevTimeWatch = 0;
    watchState = WATCH_RUN;
}
void Watch_Execute()
{
    Watch_DispLoop();

    // 0.5s blink
    if ((millis() / 500) % 2 == 0) 
    {
        FND_SetDp(ON);
    }
    else 
    {
        FND_SetDp(OFF);
    }

    // state
    switch (watchState)
    {
        case WATCH_RUN:
            Watch_Run();
            break;
        case WATCH_CLEAR:
            Watch_Clear();
            watchState = WATCH_RUN;
            break;
    }
    // clear 버튼
    if (Button_GetState(&hBtnClear) == ACT_PUSHED) {
        watchState = WATCH_CLEAR;
    }
}

void Watch_DispLoop()
{
    FND_DispDigit();
}

void Watch_Run()
{   // 1000ms(1초)가 안지났으면 바로 함수 탈출
    if (millis() - prevTimeWatch < 1000) {
        return;
    }
    // 1초가 지났으므로 과거 시간 갱신
    prevTimeWatch = millis();

    // 60진법
    watchTime.ss++;
    if (watchTime.ss >= 60) {
        watchTime.ss = 0;
        watchTime.mm++;
        if (watchTime.mm >= 60) {
            watchTime.mm = 0;
            watchTime.hh++;
            if (watchTime.hh >= 24) {
                watchTime.hh = 0;
            }
        }
    }
    FND_SetNum((watchTime.mm * 100) + watchTime.ss);

    // %02d : 2자리로 맞추고, 빈칸은 0으로 | ex) 1 -> 01
    xil_printf("%02d:%02d:%02d\n\r", watchTime.hh, watchTime.mm, watchTime.ss);
}

void Watch_Clear()
{
    watchTime.hh = 0;
    watchTime.mm = 0;
    watchTime.ss = 0;
    watchTime.ms = 0;
    FND_SetNum(0);
}
