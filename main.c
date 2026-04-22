

#include <avr/io.h>
#include <util/delay.h>
#include <avr/interrupt.h>
#include "kernel.h"
#include "tasks.h"


int main(void) {
    
    
	Kernel_Init();
    
    
	
    while(1){
		
		//Nothing to do here
		//All tasks are handled by kernel
        
    }
}



