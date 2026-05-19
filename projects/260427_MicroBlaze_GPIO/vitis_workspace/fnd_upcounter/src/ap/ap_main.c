 #include "ap_main.h"
 #include "../common/common.h"
 #include "UpCounter/UpCounter.h"
 #include "Watch/Watch.h"

system_mode_t sysMode = MODE_WATCH;
hBtn_t hBtnMode;

 void ap_init()
 {
	UpCounter_Init();
    Watch_Init();
    Button_Init(&hBtnMode, GPIOA, GPIO_PIN_6);
 }

 void ap_execute()
 {
	while (1)
	{
        if (Button_GetState(&hBtnMode) == ACT_PUSHED)
        {
           if (sysMode == MODE_UPCOUNTER)
           {
                sysMode = MODE_WATCH;
           }
           else
           {
                sysMode = MODE_UPCOUNTER;
           }
           FND_DispAllOff();
           FND_SetDp(OFF);
        }
        
        switch (sysMode)
        {
            case MODE_UPCOUNTER:
                UpCounter_Execute();
                break;
            case MODE_WATCH:
                Watch_Execute();
                break;
        }
		millis_inc();
		delay_ms(1);
	}
 }
