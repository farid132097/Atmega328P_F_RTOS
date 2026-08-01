

#include <avr/io.h>
#include <cstdint>
#include <util/delay.h>
#include <avr/interrupt.h>
#include "kernel.h"
#include "tasks.h"



int main(void) {
    
    
	//Kernel_Timer_Init();
	Kernel_Init();
	Kernel_Task_Create(Tasks_Task1, 0);
	Kernel_Task_Create(Tasks_Task2, 1);
	Kernel_Task_Create(Tasks_Task3, 2);
	Kernel_Start_Tasks();
	//_delay_ms(1000);
	
    while(1){
		
		//Nothing to do here
		//All tasks are handled by kernel

		//Kernel_Task_Sleep(100);

        
    }
}



