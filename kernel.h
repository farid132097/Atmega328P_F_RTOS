
/*
 * File          : kernel.h
 * Author        : MD. Faridul Islam (faridmdislam@gmail.com)
 * Description   : AVR kernel for bare-metal RTOS
 * Created       : Jul 27, 2025, 9:30 PM
 * Last Modified : Apr 16, 2026, 12:31 PM
 */



#ifndef  _KERNEL_H_
#define  _KERNEL_H_



//Enable or disable kernel debug via gpio
#define  KER_DBG_ENABLE


//In idle time, cpu will be in sleep
#define  KER_IDLE_AS_SLEEP

//Before entering sleep, several peripherals needs to be disabled
//User can hook a function which will disable peripherals before sleep
//Add function by calling Kernel_PreSleep_Hook(func_name) before Kernel_Start_Tasks() 
//#define  KER_CALL_FUNC_BEFORE_SLEEP


//Define maximum number of task
//Higher numbers will allocate larger ram space
#define  KER_MAX_TASK    5

//Define IO address of the DDR & PORT for debug
#ifdef   KER_DBG_ENABLE
#define  KER_DBG_DDR     0x07   //DDRC IO address
#define  KER_DBG_PORT    0x08   //PORTC IO address
#define  KER_DBG_PIN     0x00   //PORTC0 pin
#endif






#ifndef __ASSEMBLER__           //Only accessible via C
extern void      Kernel_Timer_Init(void);
extern void      Kernel_Init(void);
extern void      Kernel_Task_Create(void (*func)(void), uint8_t priority);
extern void      Kernel_Start_Tasks(void);
extern void      Kernel_Task_Idle(void);
extern void      Kernel_Task_Sleep(uint8_t val);
extern void      Kernel_Manual_Sleep(uint8_t val);

#endif



#endif

