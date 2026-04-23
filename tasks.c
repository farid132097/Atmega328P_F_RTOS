

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
  
  DDRC |= (1<<1);
  
  while(1){
    
    //atomic toggle, otherwise another task may interfare
    cli();
    PORTC |= (1<<1);
    _delay_us(500);
    PORTC &=~ (1<<1);
    sei();

    //Kernel_Task_Sleep(50);
    
  }
}

void Tasks_Task2(void){
  
  DDRC |= (1<<2);
  
  while(1){
    
    //atomic toggle, otherwise another task may interfare
    cli();
    PORTC ^= (1<<2);
    sei();
    
    //Kernel_Task_Sleep(100);
    
  }
}

void Tasks_Task3(void){
  
  DDRC |= (1<<3);
  
  while(1){
    
    //atomic toggle, otherwise another task may interfare
    cli();
    PORTC ^= (1<<3);
    sei();

    //Kernel_Task_Sleep(150);
    
  }
}

void Tasks_Task4(void){
  
  DDRC |= (1<<3);
  
  while(1){
    
    //atomic toggle, otherwise another task may interfare
    cli();
    PORTC ^= (1<<3);
    sei();
    
    //Kernel_Task_Sleep(20000/KER_TICK_TIME);
    
  }
}


uint8_t tid, hiprtid, prio[5], hiprio, sleep[5], lst=5, ntask=5;

void Tasks_Task5(void){
  hiprio = 0xff;
  hiprtid = 0;
  for(uint8_t i=0; i<ntask; i++){
    if(sleep[i]){
      sleep[i]-=lst;
      if((sleep[i] == 0) && (prio[i] < hiprio)){
        hiprio = prio[i];
        hiprtid = i;
      }
    }
    else{
      if(prio[i] < hiprio){
        hiprio = prio[i];
        hiprtid = i;
      }
    }
  }
  

  while(1){

  }
}


