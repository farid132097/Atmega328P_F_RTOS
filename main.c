

#include <avr/io.h>
#include <cstdint>
#include <util/delay.h>
#include <avr/interrupt.h>
#include "kernel.h"
#include "tasks.h"



void Delay(uint32_t val){
	val *= 1024;
	val /= 1000;
	Kernel_Manual_Sleep(val - 1);
}


int main(void) {
    
    
	Kernel_Init();
	Kernel_Timer_Init();
    Kernel_Task_Create(Tasks_Task1,0);
    Kernel_Task_Create(Tasks_Task2,1);
	Kernel_Task_Create(Tasks_Task3,2);
	Kernel_Task_Create(Tasks_Task1,0);
    Kernel_Task_Create(Tasks_Task2,1);
	Kernel_Task_Create(Tasks_Task3,2);
	Kernel_Task_Create(Tasks_Task1,0);
    Kernel_Task_Create(Tasks_Task2,1);
	Kernel_Task_Create(Tasks_Task3,2);
	Kernel_Start_Tasks();
	
    while(1){
		
		//Nothing to do here
		//All tasks are handled by kernel
        
    }
}



