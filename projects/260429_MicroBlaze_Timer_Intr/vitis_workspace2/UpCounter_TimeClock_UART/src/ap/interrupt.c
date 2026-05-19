/*
 * interrupt.c
 *
 *  Created on: 2026. 4. 29.
 *      Author: kccistc
 */
#include "interrupt.h"

XIntc IntrController;

// 1kHz -> 1msec interrupt service routine
void TMR1_ISR(void *CallbackRef) {
	millis_inc();
	Disp_ISR_Execute();
//    UpCounter_DispLoop();
}

// 10msec interrupt service routine
void TMR2_ISR(void *CallbackRef) {
	TimeClock_IncTime();
}

void TMR0_Init()
{
	// 1MHz -> 1us 간격으로 count 증가, interrupt 발생 안함
	TMR_SetPSC(TMR0, 100 - 1);
	TMR_SetARR(TMR0, 0xffffffff);
	TMR_StopIntr(TMR0);
	TMR_StartTimer(TMR0);
}

void TMR1_Init()
{
	// 1kHz -> 1ms 간격으로 interrupt 발생
	TMR_SetPSC(TMR1, 100 - 1);
	TMR_SetARR(TMR1, 1000 - 1);
	TMR_StartIntr(TMR1);
	TMR_StartTimer(TMR1);
}

void TMR2_Init()
{
	// 100Hz -> 10ms 간격으로 interrupt 발생
	TMR_SetPSC(TMR2, 100 - 1);
	TMR_SetARR(TMR2, 10000 - 1);
	TMR_StartIntr(TMR2);
	TMR_StartTimer(TMR2);
}

int SetupInterruptSystem() {
	int status;

	// 1. 인터럽트 컨트롤러 초기화
	status = XIntc_Initialize(&IntrController, INTC_DEV_ID);
	if (status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	// 2-1. TMR1_ISR 함수를 Intc와 연결
	status = XIntc_Connect(&IntrController,
	TMR1_DEV_ID, (XInterruptHandler) TMR1_ISR, (void *) 0);
	if (status != XST_SUCCESS) {
		return XST_FAILURE;
	}
	// 2-2. TMR2_ISR 함수를 Intc와 연결
	status = XIntc_Connect(&IntrController,
	TMR2_DEV_ID, (XInterruptHandler) TMR2_ISR, (void *) 0);
	if (status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	// 3. Interrupt Controller 시작 (Hardware Mode)
	status = XIntc_Start(&IntrController, XIN_REAL_MODE);

	// 4. 각각의 인터럽트 채널 활성화
	XIntc_Enable(&IntrController, TMR1_DEV_ID);
	XIntc_Enable(&IntrController, TMR2_DEV_ID);

	// 5. MicroBlaze 의 Exception 초기화 및 활성화
	Xil_ExceptionInit();
	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
			(Xil_ExceptionHandler) XIntc_InterruptHandler, &IntrController);
	Xil_ExceptionEnable();

	return XST_SUCCESS;
}
