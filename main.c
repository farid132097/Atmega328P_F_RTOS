

#include <avr/io.h>
#include <util/delay.h>
#include <avr/interrupt.h>
#include "kernel.h"
#include "debug.h"
#include "tasks.h"



int main(void) {
    
    
    //Enable prescaler 2
	//System frequency 4 MHz
	Kernel_Clock_Prescale(1);
    
	Kernel_Init();
    
	Kernel_Task_Create(Tasks_Task1,  0);
	Kernel_Task_Create(Tasks_Task2,  1);
	Kernel_Task_Create(Tasks_Task3,  2);
	Kernel_Task_Create(Tasks_Task4,  3);
	Kernel_Task_Create(Tasks_Task5,  4);
	Kernel_PreSleep_Hook(Tasks_Disable_Peripherals);
	
	Kernel_Start_Tasks();
	
    while(1){
		
		//Nothing to do here
		//All tasks are handled by kernel
        
    }
}

