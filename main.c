

#include <avr/io.h>
#include <util/delay.h>
#include <avr/interrupt.h>
#include "kernel.h"



int main(void) {
    
    //Enable prescaler 2
	//System frequency 4 MHz
    
	Kernel_Init();

	
    while(1){
		
		//Nothing to do here
		//All tasks are handled by kernel
        
    }
}

