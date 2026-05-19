#ifndef SRC_AP_AP_MAIN_H_
#define SRC_AP_AP_MAIN_H_

#include <stdint.h>

typedef enum {
    MODE_TIMECLOCK,
    MODE_UPCOUNTER
} modeState_t;

void ap_init();
void ap_execute();

#endif /* SRC_AP_AP_MAIN_H_ */
