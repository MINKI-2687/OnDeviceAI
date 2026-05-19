/*
 * spi_ap.c
 *
 *  Created on: 2026. 5. 4.
 *      Author: kccistc
 */

#include "i2c_ap.h"
#include "../../common/common.h"
#include "../../driver/Switch/Switch.h"
#include "../../driver/Button/Button.h"
#include "../../driver/FND/FND.h"
#include "../../HAL/I2C/I2C.h"

// 4개의 제어 버튼 선언 (GPIO 핀은 하드웨어 설계에 맞게 변경하세요)
hBtn_t hbtnStart;
hBtn_t hbtnWrite;
hBtn_t hbtnRead;
hBtn_t hbtnStop;

// FND에 띄울 전역 변수
uint8_t current_rx_data = 0;

void I2c_Ap_Init() {
	// [수정됨] XDC 파일에 맞춰 버튼 핀 번호를 4, 5, 6, 7로 변경
	Button_Init(&hbtnStart, GPIOA, GPIO_PIN_4); // T18 (위쪽 버튼)   -> Start
	Button_Init(&hbtnWrite, GPIOA, GPIO_PIN_5); // W19 (왼쪽 버튼)   -> Write
	Button_Init(&hbtnRead, GPIOA, GPIO_PIN_6); // T17 (오른쪽 버튼) -> Read
	Button_Init(&hbtnStop, GPIOA, GPIO_PIN_7); // U17 (아래쪽 버튼) -> Stop

	// 스위치(GPIOC)와 FND(GPIOB, GPIOA 0~3) 초기화 코드는 그대로 유지
	Switch_Init();
	FND_Init();
	FND_SetNum(0);
}

//void I2c_Ap_Run() {
//	uint8_t sw_data = Switch_GetState(); // 현재 스위치 값 지속 읽기[cite: 7]
//
//	// ==========================================
//	// [수동 하드웨어 제어 시나리오 (버튼 FSM)]
//	// ==========================================
//
//	// 1. [START] 버튼이 눌렸을 때
//	if (Button_GetState(&hbtnStart) == ACT_PUSHED) {
//		I2C_SendCmd(1, 0, 0, 0, 0); // start=1
//	}
//
//	// 2. [WRITE] 버튼이 눌렸을 때
//	if (Button_GetState(&hbtnWrite) == ACT_PUSHED) {
//		I2C_SetTxData(sw_data);     // 스위치 값을 하드웨어 레지스터에 로드
//		I2C_SendCmd(0, 1, 0, 0, 0); // write=1
//	}
//
//	// 3. [READ] 버튼이 눌렸을 때
//	if (Button_GetState(&hbtnRead) == ACT_PUSHED) {
//		// NACK(1)를 보내어 수신 종료를 알리면서 1바이트 읽기
//		I2C_SendCmd(0, 0, 1, 0, 1); // read=1, ack_in=1
//		current_rx_data = I2C_GetRxData(); // 읽어온 값을 변수에 저장
//	}
//
//	// 4. [STOP] 버튼이 눌렸을 때
//	if (Button_GetState(&hbtnStop) == ACT_PUSHED) {
//		I2C_SendCmd(0, 0, 0, 1, 0); // stop=1
//	}
//
//	// ==========================================
//	// [디스플레이 (FND) 영역]
//	// ==========================================
//	// 왼쪽 2자리: 현재 스위치 값(전송 대기 데이터)
//	// 오른쪽 2자리: 수신된 데이터(RX Data)
//	uint16_t fnd_display_val = (sw_data * 100) + current_rx_data;
////	uint16_t fnd_display_val = (sw_data << 8) | current_rx_data;
//	FND_SetNum(fnd_display_val);
//
//	FND_DispDigit(); //[cite: 7]
//	delay_ms(1);     //[cite: 7]
//}

// 전역 변수로 모드 기억 (0: 스위치 화면, 1: 수신 데이터 화면)
static uint8_t display_mode = 0;

void I2c_Ap_Run() {
    uint8_t sw_data = Switch_GetState();

    // 1. [START]
    if (Button_GetState(&hbtnStart) == ACT_PUSHED) {
        I2C_SendCmd(1, 0, 0, 0, 0);
    }

    // 2. [WRITE]
    if (Button_GetState(&hbtnWrite) == ACT_PUSHED) {
        I2C_SetTxData(sw_data);
        I2C_SendCmd(0, 1, 0, 0, 0);
        display_mode = 0; // Write 누르면 스위치 값을 보여주는 모드로 자동 전환!
    }

    // 3. [READ]
    if (Button_GetState(&hbtnRead) == ACT_PUSHED) {
        I2C_SendCmd(0, 0, 1, 0, 1);
        current_rx_data = I2C_GetRxData();
        display_mode = 1; // Read 누르면 수신 값을 보여주는 모드로 자동 전환!
    }

    // 4. [STOP]
    if (Button_GetState(&hbtnStop) == ACT_PUSHED) {
        I2C_SendCmd(0, 0, 0, 1, 0);
    }

    // ==========================================
    // [디스플레이 (FND) 영역]
    // ==========================================
    uint16_t fnd_display_val = 0;

    if (display_mode == 0) {
        fnd_display_val = sw_data; // 0~255 숫자가 FND 4자리에 깔끔하게 출력됨
    } else {
        fnd_display_val = current_rx_data;
    }

    FND_SetNum(fnd_display_val);
    FND_DispDigit();
    delay_ms(1);
}
