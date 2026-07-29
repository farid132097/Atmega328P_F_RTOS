

#include <avr/io.h>
#include <cstdint>
#include <util/delay.h>
#include <avr/interrupt.h>
#include "kernel.h"
#include "tasks.h"



int main(void) {
    
    
	Kernel_Timer_Init();
	//_delay_ms(1000);
	
    while(1){
		
		//Nothing to do here
		//All tasks are handled by kernel

		Kernel_Task_Sleep(250);

        
    }
}



