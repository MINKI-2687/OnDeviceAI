/*
 * DispService.h
 *
 *  Created on: 2026. 5. 6.
 *      Author: kccistc
 */

#ifndef SRC_AP_DISPSERVICE_DISPSERVICE_H_
#define SRC_AP_DISPSERVICE_DISPSERVICE_H_

#include "../../driver/FND/FND.h"
#include "../../driver/Led/Led.h"

enum {
	DISP_TIME_CLOCK, DISP_UP_COUNTER
};
enum {
	DISP_TIME_HHMM, DISP_TIME_SSMS
};

void Disp_SetMode(int mode);
void Disp_SetTimeMode(int mode);
void Disp_Init();
void Disp_SetShiftMode();
void Disp_TimeHHMM();
void Disp_TimeSSMS();
void Disp_UpCounter(uint16_t num);
void Disp_TimeClock(uint16_t num);
void Disp_ISR_Execute();
void Disp_ShiftLed(int mode);

#endif /* SRC_AP_DISPSERVICE_DISPSERVICE_H_ */
