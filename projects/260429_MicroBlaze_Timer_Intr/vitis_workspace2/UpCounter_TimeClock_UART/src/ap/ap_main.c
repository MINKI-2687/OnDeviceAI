/*
 * ap_main.c
 *
 *  Created on: 2026. 4. 28.
 *      Author: kccistc
 */

#include "xil_printf.h"
#include <string.h>

#include "ap_main.h"
#include "../HAL/TMR/TMR.h"
#include "../driver/Button/Button.h"
#include "UpCounter/UpCounter.h"
#include "TimeClock/TimeClock.h"
#include "interrupt.h"


typedef struct {
   uint32_t SR;
   uint32_t TDR;
   uint32_t RDR;
   uint32_t CR;
}UART_Typedef_t;

#define UART_BASE_ADDR XPAR_UART_0_S00_AXI_BASEADDR
#define UART0         ((UART_Typedef_t *)(UART_BASE_ADDR))



uint8_t UART_IsSending(UART_Typedef_t *uart)
{
   return (uart->SR & 1U<<0) ? 0 : 1;
}

uint8_t UART_IsAvalable(UART_Typedef_t *uart)
{
   return (uart->SR & 1U<<1) ? 1 : 0;
}

void UART_SendByte(UART_Typedef_t *uart, uint8_t data)
{
   while(UART_IsSending(uart));
   uart->TDR = data;
}

uint8_t UART_RecvByte(UART_Typedef_t *uart)
{
   uint8_t rx_data;
   while(!UART_IsAvalable(uart));
   rx_data = uart->RDR;
   return rx_data;
}

void UART_send(UART_Typedef_t *uart, uint8_t *pData, uint16_t len)
{
   for(int i=0; i<len; i++) {
      UART_SendByte(uart, pData[i]);
   }
}

modeState_t modeState = DISP_TIME_CLOCK;
hBtn_t hbtnMode;

void ap_init() {
   Button_Init(&hbtnMode, GPIOA, GPIO_PIN_5);
   UpCounter_Init();
   TimeClock_Init();
   SetupInterruptSystem();

   // 1Mhz -> 1us 간격으로 count 증가, interrupt 발생 안함.
   TMR_SetPSC(TMR0, 100 - 1);
   TMR_SetARR(TMR0, 0xffffffff);
   TMR_StopIntr(TMR0);
   TMR_StartTimer(TMR0);

   // 1khz -> 1ms 간격으로 interrupt 발생
   TMR_SetPSC(TMR1, 100 - 1);
   TMR_SetARR(TMR1, 1000 - 1);
   TMR_StartIntr(TMR1);
   TMR_StartTimer(TMR1);

   // 100hz -> 10ms 간격으로 interrupt 발생
   TMR_SetPSC(TMR2, 100 - 1);
   TMR_SetARR(TMR2, 10000 - 1);
   TMR_StartIntr(TMR2);
   TMR_StartTimer(TMR2);
}

void ap_execute()
{
   //UART_Send(UART0, "Hello World KCCI STC\n", strlen("Hello World KCCI STC\n"));

   char str[] = {"Hello World KCCI STC\n"};
   uint8_t rxData;
   for (int i=0; i<strlen(str); i++) {
      UART_SendByte(UART0, str[i]);
      rxData = UART_RecvByte(UART0);
      xil_printf("%c", rxData);
   }



   while (1) {
      switch (modeState) {
      case DISP_TIME_CLOCK:
         TimeClock_Execute();
         if (Button_GetState(&hbtnMode) == ACT_RELEASED) {
            modeState = UPCOUNTER_RUN;
            FND_SetDp(FND_DIGIT_100, OFF);
         }
         break;
      case UPCOUNTER_RUN:
         UpCounter_Execute();
         if (Button_GetState(&hbtnMode) == ACT_RELEASED) {
            modeState = DISP_TIME_CLOCK;
         }
         break;
      }
   }
}
