#include "ap_main.h"

#include "i2c_ap/i2c_ap.h"

void ap_init(void) {
	// 시스템 켜질 때 단 한 번, 통신 모듈 초기화 지시
	I2c_Ap_Init();
}

void ap_execute(void) {
	while (1) {
		// 무한 루프 내내 통신 시나리오 감시 및 실행
		I2c_Ap_Run();
	}
}
