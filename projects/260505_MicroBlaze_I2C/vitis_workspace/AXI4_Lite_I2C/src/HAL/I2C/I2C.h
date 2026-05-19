/*
 * SPI.h
 *
 *  Created on: 2026. 5. 4.
 *      Author: kccistc
 */

#ifndef SRC_HAL_I2C_I2C_H_
#define SRC_HAL_I2C_I2C_H_

#include <stdint.h>
#include "xparameters.h" // 베이스 주소를 가져오기 위함

// Vivado에서 설계한 4개의 32비트 레지스터 구조체 맵핑
typedef struct {
    volatile uint32_t CTRL;      // 0x00: slv_reg0 (cmd_start, write, read, stop, ack_in)
    volatile uint32_t TX_DATA;   // 0x04: slv_reg1 (tx_data)
    volatile uint32_t STATUS;    // 0x08: slv_reg2 (busy, done, ack_out)
    volatile uint32_t RX_DATA;   // 0x0C: slv_reg3 (rx_data)
} I2C_Typedef_t;

// xparameters.h에 나와있는 I2C_MASTER의 베이스 주소로 변경하세요!
#define I2C_BASE_ADDR 0x44A30000
#define I2C_PORT ((I2C_Typedef_t *) I2C_BASE_ADDR)

// 함수 프로토타입
void I2C_SendCmd(uint8_t start, uint8_t write, uint8_t read, uint8_t stop, uint8_t ack_in);
void I2C_SetTxData(uint8_t data);
uint8_t I2C_GetRxData(void);
uint8_t I2C_GetAckOut(void);

#endif /* SRC_HAL_I2C_I2C_H_ */
