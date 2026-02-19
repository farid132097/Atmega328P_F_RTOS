

#include <avr/io.h>
#include <util/delay.h>
#include <avr/interrupt.h>
#include "kernel.h"
#include "tasks.h"
#include "debug.h"


/*
  If some peripherals need to be disabled before
  sleep, add disabling tasks inside this function. 
*/
void Tasks_Disable_Peripherals(void){
  //ADC and Analog comparator will be
  //turned off automatically by the kernel
  //if KER_AUTO_DISABLE_ADC_AC_BEFORE_SLEEP is uncommented
  //in kernel.h
}


void Tasks_Task1(void){
  
  DDRD |= (1<<4);
  
  while(1){
    
    //atomic toggle, otherwise another task may interfare
    cli();
    PORTD |= (1<<4);
    _delay_us(1000);
    PORTD &=~ (1<<4);
    sei();

    Kernel_Task_Sleep(5000/KER_TICK_TIME);
    
  }
}

void Tasks_Task2(void){
  
  DDRC |= (1<<1);
  
  while(1){
    
    //atomic toggle, otherwise another task may interfare
    cli();
    PORTC ^= (1<<1);
    sei();
    
    Kernel_Task_Sleep(10000/KER_TICK_TIME);
    
  }
}

void Tasks_Task3(void){
  
  DDRC |= (1<<2);
  
  while(1){
    
    //atomic toggle, otherwise another task may interfare
    cli();
    PORTC ^= (1<<2);
    sei();

    Kernel_Task_Sleep(15000/KER_TICK_TIME);
    
  }
}

void Tasks_Task4(void){
  
  DDRC |= (1<<3);
  
  while(1){
    
    //atomic toggle, otherwise another task may interfare
    cli();
    PORTC ^= (1<<3);
    sei();
    
    Kernel_Task_Sleep(20000/KER_TICK_TIME);
    
  }
}

void Tasks_Task5(void){
  
  DDRC |= (1<<4);
  
  while(1){
    
    //atomic toggle, otherwise another task may interfare
    cli();
    PORTC ^= (1<<4);
    sei();
    
    Kernel_Task_Sleep(40000/KER_TICK_TIME);
    
  }
}


