/*
 * Watch.h
 *
 *  Created on: 2026. 4. 28.
 *      Author: kccistc
 */

#ifndef SRC_AP_WATCH_WATCH_H_
#define SRC_AP_WATCH_WATCH_H_

#include "../../driver/FND/FND.h"
#include "../../driver/Button/Button.h"
#include "../../common/common.h"

typedef enum {
    WATCH_RUN,
    WATCH_CLEAR
} watch_state_t;

typedef struct {
    uint8_t hh;
    uint8_t mm;
    uint8_t ss;
    uint16_t ms;
} time_data_t;

void Watch_Init();
void Watch_Execute();
void Watch_DispLoop();
void Watch_Run();
void Watch_Clear();

#endif /* SRC_AP_WATCH_WATCH_H_ */
