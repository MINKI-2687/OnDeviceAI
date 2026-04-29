#ifndef SRC_AP_AP_MAIN_H_
#define SRC_AP_AP_MAIN_H_

#include <stdint.h>

void ap_init();
void ap_execute();

typedef enum {
    MODE_UPCOUNTER,
    MODE_WATCH
} system_mode_t;

#endif /* SRC_AP_AP_MAIN_H_ */
