/*
 * SPI.c
 *
 *  Created on: 2026. 5. 4.
 *      Author: kccistc
 */
#include "I2C.h"
#include "../../common/common.h" // delay_ms 사용

void I2C_SendCmd(uint8_t start, uint8_t write, uint8_t read, uint8_t stop, uint8_t ack_in) {
    // 하드웨어로 보낼 명령어 비트 조합 (ack_in은 bit 4, stop은 bit 3...)
    uint32_t cmd = (ack_in << 4) | (stop << 3) | (read << 2) | (write << 1) | start;

    // AXI 버스를 통해 CTRL 레지스터에 쓰기 (Verilog에서 1클럭 후 자동 0으로 초기화됨)
    I2C_PORT->CTRL = cmd;

    // 하드웨어 FSM이 동작을 마칠 때까지 안전하게 1ms 대기
    // (100kHz I2C에서 1바이트 전송은 약 0.1ms가 소요되므로 1ms면 충분합니다)
    delay_ms(1);
}

void I2C_SetTxData(uint8_t data) {
    I2C_PORT->TX_DATA = (uint32_t)data;
}

uint8_t I2C_GetRxData(void) {
    return (uint8_t)(I2C_PORT->RX_DATA & 0xFF);
}

uint8_t I2C_GetAckOut(void) {
    // STATUS_REG의 2번 비트가 ack_out_in 이라 가정
    return (uint8_t)((I2C_PORT->STATUS >> 2) & 0x01);
}
