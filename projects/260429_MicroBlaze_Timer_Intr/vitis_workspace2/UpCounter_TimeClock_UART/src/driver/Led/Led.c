/*
 * Led.c
 *
 *  Created on: 2026. 4. 30.
 *      Author: kccistc
 */
#include "Led.h"

void Led_Init(hLed *hled, GPIO_Typedef_t *GPIOx, uint32_t GPIO_Pin) {
	hled->GPIOx = GPIOx;
	hled->GPIO_Pin = GPIO_Pin;
	GPIO_SetMode(hled->GPIOx, GPIO_Pin, OUTPUT);
}

void LED_On(hLed *hled) // LED 1개 On
{
	GPIO_WritePin(hled->GPIOx, hled->GPIO_Pin, SET);
}

void LED_Off(hLed *hled) // LED 1개 Off
{
	GPIO_WritePin(hled->GPIOx, hled->GPIO_Pin, RESET);
}

void LED_Toggle(hLed *hled) // LED 1개 Toggle
{
	GPIO_TogglePin(hled->GPIOx, hled->GPIO_Pin);
}

void LED_WritePort(hLed *hled, uint8_t data) // LED GPIOC 8개의 pin과 연결되어 있음. GPIOC Port에 8개의 값을 동시에 Write. GPIO ODR 값 Write
{
	GPIO_WritePort(hled->GPIOx, data);
}

uint8_t LED_ReadPort(hLed *hled) // LED GPIOC 8개의 pin과 연결되어 있음. GPIOC Port에 8개의 값을 동시에 Read. GPIO ODR 값 read
{
	return (uint8_t) GPIO_ReadPort(hled->GPIOx);
}
