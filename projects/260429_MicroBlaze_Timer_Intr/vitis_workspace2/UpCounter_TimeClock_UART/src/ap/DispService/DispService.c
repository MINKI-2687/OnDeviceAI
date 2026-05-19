/*
 * DispService.c
 *
 *  Created on: 2026. 5. 6.
 *      Author: kccistc
 */

#include "DispService.h"

hLed hLedUpCounterMode;
hLed hLedTimeClockMode;
hLed hLedTimeMode_hhmm;
hLed hLedTimeMode_ssms;
hLed hLedShift;

void Disp_SetMode(int mode) {
	if (mode == DISP_TIME_CLOCK) {
		LED_On(&hLedTimeClockMode);
		LED_Off(&hLedUpCounterMode);
	} else if (mode == DISP_UP_COUNTER) {
		LED_On(&hLedUpCounterMode);
		LED_Off(&hLedTimeClockMode);
	}
}

void Disp_SetTimeMode(int mode) {
	if (mode == DISP_TIME_HHMM) {
		LED_On(&hLedTimeMode_hhmm);
		LED_Off(&hLedTimeMode_ssms);
	} else {
		LED_Off(&hLedTimeMode_hhmm);
		LED_On(&hLedTimeMode_ssms);
	}
}

void Disp_Init() {
	FND_Init();
	Led_Init(&hLedTimeClockMode, LED_MODE_TIME_CLOCK_PORT,
	LED_MODE_TIME_CLOCK_PIN);
	Led_Init(&hLedUpCounterMode, LED_MODE_UP_COUNTER_PORT,
	LED_MODE_UP_COUNTER_PIN);
	Led_Init(&hLedTimeMode_hhmm, LED_TIME_MODE_HH_MM_PORT,
	LED_TIME_MODE_HH_MM_PIN);
	Led_Init(&hLedTimeMode_ssms, LED_TIME_MODE_SS_MS_PORT,
	LED_TIME_MODE_SS_MS_PIN);
	Led_Init(&hLedShift, LED_TIME_MODE_SS_MS_PORT, GPIO_PIN_0);
	Led_Init(&hLedShift, LED_TIME_MODE_SS_MS_PORT, GPIO_PIN_1);
	Led_Init(&hLedShift, LED_TIME_MODE_SS_MS_PORT, GPIO_PIN_2);
	Led_Init(&hLedShift, LED_TIME_MODE_SS_MS_PORT, GPIO_PIN_3);

	Disp_SetMode(DISP_TIME_CLOCK);
	Disp_SetTimeMode(DISP_TIME_HHMM);
}

void Disp_SetShiftMode() {

}

void Disp_TimeHHMM() {

}

void Disp_TimeSSMS() {

}

void Disp_UpCounter(uint16_t num) {
	FND_SetNum(num);
}

void Disp_TimeClock(uint16_t num) {
	FND_SetNum(num);
}

void Disp_ISR_Execute() {
	FND_DispDigit();
}

void Disp_ShiftLed(int mode) {
	static uint8_t ledShiftPosData = 1;
	uint8_t ledPortData;
	uint8_t ledOutData;

	if (mode == DISP_TIME_CLOCK) {
		ledShiftPosData = (ledShiftPosData << 3) | (ledShiftPosData >> 1);
	} else {
		ledShiftPosData = (ledShiftPosData >> 3) | (ledShiftPosData << 1);
	}
	ledPortData = hLedShift.GPIOx->ODR;
	ledOutData = (ledPortData & 0xf0) | (ledShiftPosData & 0x0f);
	LED_WritePort(&hLedShift, ledOutData);
}
