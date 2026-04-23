

#include <avr/io.h>
#include <cstdint>
#include <util/delay.h>
#include <avr/interrupt.h>
#include "kernel.h"
#include "tasks.h"



void Delay(uint32_t val){
	val *= 1024;
	val /= 1000;
	Kernel_Manual_Sleep(val);
}


int main(void) {
    
    
	Kernel_Init();
    
    DDRC  |= (1<<1);
	PORTC &=~(1<<1);
	
    while(1){
		
		//Nothing to do here
		//All tasks are handled by kernel

        //PORTC ^= (1<<1);
        Delay(1);

        
    }
}



