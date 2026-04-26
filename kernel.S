

 ; File          : kernel.S
 ; Author        : MD. Faridul Islam (faridmdislam@gmail.com)
 ; Description   : AVR kernel for bare-metal RTOS
 ; Created       : Jul 27, 2025, 09:30 PM
 ; Last Modified : Apr 22, 2026, 10:49 PM




#include <avr/io.h>
#include "kernel.h"


;;============================define user address or macro starting=========================;; 
.equ     KER_RLD,         0x00                            ;KER_RLD=0xFF-(F_CPU/KER_PRS/KER_TR) 
.equ     KER_STK_SZ,      128                             ;stack size in bytes for each task   
.equ     KER_MX_NTSK,     KER_MAX_TASK+1                  ;max number of tasks                 
;;==============================define user address or macro end============================;; 





;;===========================define hardware reg address starting===========================;; 
;SRAM Mapped Addresses, LDS/STS can be used                                                    
.equ     SRASSR  ,        0xB6                            ;manually defined ASSR in SRAM       
.equ     SROCR2B ,        0xB4                            ;manually defined OCR2B in SRAM      
.equ     SROCR2A ,        0xB3                            ;manually defined OCR2A in SRAM      
.equ     SRTCNT2 ,        0xB2                            ;manually defined TNCT2 in SRAM      
.equ     SRTCCR2B,        0xB1                            ;manually defined TCCR2B in SRAM     
.equ     SRTCCR2A,        0xB0                            ;manually defined TCCR2A in SRAM     
.equ     SRADCSRA,        0x7A                            ;manually defined ADCSRA in SRAM     
.equ     SRTIMSK2,        0x70                            ;manually defined TIMSK2 in SRAM     
.equ     SRCLKPR ,        0x61                            ;manually defined CLKPR in SRAM      
.equ     SRSREG  ,        0x5F                            ;manually defined SREG in SRAM       
.equ     SRSPH   ,        0x5E                            ;manually defined SPH in SRAM        
.equ     SRSPL   ,        0x5D                            ;manually defined SPL in SRAM        
.equ     SRMCUCR ,        0x55                            ;manually defined MCUCR in SRAM      
.equ     SRMCUSR ,        0x54                            ;manually defined MCUSR in SRAM      
.equ     SRSMCR  ,        0x53                            ;manually defined SMCR in SRAM       
.equ     SRACSR  ,        0x50                            ;manually defined ACSR in SRAM       
.equ     SRTIFR2 ,        0x37                            ;manually defined TIFR2 in SRAM      
;IO Mapped Addresses, IN/OUT commands can be used                                              
.equ     IOSREG  ,        0x3F                            ;manually defined SREG in IO         
.equ     IOSPH   ,        0x3E                            ;manually defined SPH in IO          
.equ     IOSPL   ,        0x3D                            ;manually defined SPL in IO          
.equ     IOMCUCR ,        0x35                            ;manually defined MCUCR in IO        
.equ     IOMCUSR ,        0x34                            ;manually defined MCUSR in IO        
.equ     IOSMCR  ,        0x33                            ;manually defined SMCR in IO         
.equ     IOTIFR2 ,        0x17                            ;manually defined TIFR2 in IO        
;;==============================define hardware reg address end=============================;; 





;;=============================define global variables starting=============================;; 
.section   .bss                                                                                
                                                                                               
.global    KerMSPZP                                       ;declare space for storing MSP, ZP   
KerMSPZP:  .skip 4                                        ;2 bytes for MSP, 2 bytes for ZP     
.global    KerTID                                         ;declare space for task id           
KerTID:    .skip 1                                        ;single byte, max 0xff tasks         
.global    KerHPTID                                       ;declare space for hi prio task id   
KerHPTID:  .skip 1                                        ;single byte, max 0xff tasks         
.global    KerNTSK                                        ;declare space for number of tasks   
KerNTSK:   .skip 1                                        ;single byte, max 0xff tasks         
.global    KerLST                                         ;declare space for lowest sleep time 
KerLST:    .skip 1                                        ;single byte, max 0xff unit sleep    
.global    KerSCHM                                        ;declare space for scheduler mode    
KerSCHM:   .skip 1                                        ;single byte, mode 0 isr, 1 thread   
.global    KerSleep                                       ;declare space for task sleep time   
KerSleep:  .skip KER_MX_NTSK*1                            ;singel byte for each task           
.global    KerPrio                                        ;declare space for task priority     
KerPrio:   .skip KER_MX_NTSK*1                            ;singel byte for each task           
.global    KerTSP                                         ;declare space for stack pointer     
KerTSP:    .skip KER_MX_NTSK*2                            ;2 bytes for each task               
.global    KerStack                                       ;declare global space for stack      
KerStack:  .skip KER_STK_SZ*KER_MX_NTSK                   ;KER_STK_SZ bytes for each task      
                                                                                               
;;==============================define global variables end=================================;; 





;;===============================define text section starting===============================;; 
.section .text                                                                                 
;;==================================define text section end=================================;; 





;;==============================define global functions starting============================;; 
.global  Kernel_Timer_Init                                                                     
.global  Kernel_Init                                                                           
.global  Kernel_Task_Sleep
.global  Kernel_Task_Create
.global  Kernel_Start_Tasks
;;================================define global functions end===============================;; 





;;=================================timer2 disable starting==================================;; 
;used registers          : R18                                                                 
;arg registers           : None                                                                
;return registers        : None                                                                
;unsafe access registers : R18                                                                 
.macro  KER_TIMER2_DISABLE                                ;1.75uS @8MHz           ( 14 clocks) 
		LDI   R18                , 0x00                   ;clear interrupt enbits (  1 clock ) 
		STS   SRTIMSK2           , R18                    ;set val to TIMSK2      (  2 clocks) 
		STS   SRTCCR2B           , R18                    ;set val to TCCR2B      (  2 clocks) 
		STS   SRASSR             , R18                    ;set val to ASSR        (  2 clocks) 
		STS   SROCR2B            , R18                    ;clear OCR2B            (  2 clocks) 
		STS   SRTCNT2            , R18                    ;clear TCNT2            (  2 clocks) 
.endm                                                                                          
;;==================================timer2 disable end======================================;; 




;;===============================timer2 async init starting=================================;; 
;used registers          : R18, R19                                                            
;arg registers           : None                                                                
;return registers        : None                                                                
;unsafe access registers : R18, R19                                                            
.macro  KER_TIMER2_ASYNC_INIT                             ;~9.13uS @8MHz          (~73 clocks) 
		LDI   R18                , 0x00                   ;clear interrupts       (  1 clock ) 
		STS   SRTCCR2B           , R18                    ;stop timer             (  2 clocks) 
		STS   SRTIMSK2           , R18                    ;clear TIMSK2           (  2 clocks) 
		LDI   R18                , 0x20                   ;set AS2 bit            (  1 clock ) 
		STS   SRASSR             , R18                    ;set val to ASSR        (  2 clocks) 
		LDI   R18                , 0x00                   ;clear interrupts       (  1 clock ) 
		STS   SROCR2A            , R18                    ;clear compare reg      (  2 clocks) 
		STS   SROCR2B            , R18                    ;clear compare reg      (  2 clocks) 
		STS   SRTCCR2A           , R18                    ;clear controlA reg     (  2 clocks) 
		LDI   R18                , 0x03                   ;prescaler 3            (  1 clock ) 
		STS   SRTCCR2B           , R18                    ;set prescaler          (  2 clocks) 
		LDI   R18                , 0x00                   ;clear reg              (  1 clock ) 
		STS   SRTCNT2            , R18                    ;clear TCNT2            (  2 clocks) 
	_KER_TC2_AUB\@:                                                                            
	    LDS   R18                , SRASSR                 ;load ASSR              (  2 clocks) 
        ANDI  R18                , 0x02                   ;check bit TCR2AUB      (  1 clock ) 
		BRNE  _KER_TC2_AUB\@                              ;wait until AUB cleared (  2 clocks) 
	_KER_TC2_BUB\@:                                                                            
	    LDS   R18                , SRASSR                 ;load ASSR              (  2 clocks) 
        ANDI  R18                , 0x01                   ;check bit TCR2BUB      (  1 clock ) 
		BRNE  _KER_TC2_BUB\@                              ;wait until BUB cleared (  2 clocks) 
	_KER_OC2_AUB\@:                                                                            
	    LDS   R18                , SRASSR                 ;load ASSR              (  2 clocks) 
        ANDI  R18                , 0x08                   ;check bit OR2AUB       (  1 clock ) 
		BRNE  _KER_OC2_AUB\@                              ;wait until AUB cleared (  2 clocks) 
	_KER_OC2_BUB\@:                                                                            
	    LDS   R18                , SRASSR                 ;load ASSR              (  2 clocks) 
        ANDI  R18                , 0x04                   ;check bit OCR2BUB      (  1 clock ) 
		BRNE  _KER_OC2_BUB\@                              ;wait until BUB cleared (  2 clocks) 
	_KER_TC2_UB\@:                                                                             
	    LDS   R18                , SRASSR                 ;load ASSR              (  2 clocks) 
        ANDI  R18                , 0x10                   ;check bit TCNT2UB      (  1 clock ) 
		BRNE  _KER_TC2_UB\@                               ;wait until UB cleared  (  2 clocks) 
	_KER_TC2_TOV2\@:                                                                           
	    LDS   R18                , SRTIFR2                ;load TIFR2             (  2 clocks) 
        ANDI  R18                , 0x01                   ;check bit TOV2         (  1 clock ) 
        BREQ  _KER_TC2_OCF2A\@                            ;bit cleared, jump next (  2 clocks) 
		LDI   R18                , 0x01                   ;set bit                (  1 clock ) 
		STS   SRTIFR2            , R18                    ;set val                (  2 clocks) 
    _KER_TC2_OCF2A\@:                                                                          
	    LDS   R18                , SRTIFR2                ;load TIFR2             (  2 clocks) 
        ANDI  R18                , 0x02                   ;check bit OCF2A        (  1 clock ) 
        BREQ  _KER_TC2_OCF2B\@                            ;bit cleared, jump next (  2 clocks) 
		LDI   R18                , 0x02                   ;set bit                (  1 clock ) 
		STS   SRTIFR2            , R18                    ;set val                (  2 clocks) 
	_KER_TC2_OCF2B\@:                                                                          
	    LDS   R18                , SRTIFR2                ;load TIFR2             (  2 clocks) 
        ANDI  R18                , 0x04                   ;check bit OCF2B        (  1 clock ) 
        BREQ  _KER_TC2_INTEN\@                            ;bit cleared, jump next (  2 clocks) 
		LDI   R18                , 0x04                   ;set bit                (  1 clock ) 
		STS   SRTIFR2            , R18                    ;set val                (  2 clocks) 
    _KER_TC2_INTEN\@:                                                                          
		LDI   R18                , 0x01                   ;set TOIE2 bit          (  1 clock ) 
		STS   SRTIMSK2           , R18                    ;set val to TIMSK2      (  2 clocks) 
.endm                                                                                          
;;=================================timer2 async init end====================================;; 





;;=============================timer2 tcnt update busy starting=============================;; 
;used registers          : R18                                                                 
;arg registers           : None                                                                
;return registers        : None                                                                
;unsafe access registers : R18                                                                 
.macro  KER_TIMER2_TCNT2_UB                               ;~9.13uS @8MHz          (~73 clocks) 
	_KER_TMR2_UB\@:                                                                            
	    LDS   R18                , SRASSR                 ;load ASSR              (  2 clocks) 
        ANDI  R18                , 0x10                   ;check bit TCNT2UB      (  1 clock ) 
		BRNE  _KER_TMR2_UB\@                              ;wait until UB cleared  (  2 clocks) 
.endm                                                                                          
;;==============================timer2 tcnt update busy end==================================;; 





;;=================================timer reload starting====================================;; 
;used registers          : R18                                                                 
;arg registers           : None                                                                
;return registers        : None                                                                
;unsafe access registers : R18                                                                 
.macro  KER_TIMER_RELOAD                                  ;0.75uS @8MHz           (  6 clocks) 
        LDS   R18                , KerLST                 ;fetch lowst sleep time (  2 clocks) 
		LDI   R19                , 0xFF                   ;set max val            (  1 clock ) 
		SUB   R19                , R18                    ;subtract               (  1 clock ) 
		STS   SRTCNT2            , R19                    ;set val                (  2 clocks) 
.endm                                                                                          
;;===================================timer reload end=======================================;; 





;;====================================timer init starting===================================;; 
;used registers          : R18, R19                                                            
;arg registers           : None                                                                
;return registers        : None                                                                
;unsafe access registers : R18, R19                                                            
.macro  KER_TIMER_INIT                                    ;~9.13uS max @8MHz      (~73 clocks) 
        KER_TIMER2_DISABLE                                ;1.75uS @8MHz           ( 14 clocks) 
		KER_TIMER2_ASYNC_INIT                             ;total 1.5uS @8MHz      (~73 clocks) 
.endm                                                                                          
;;======================================timer init end======================================;; 





;;============================debug pin operation init starting=============================;; 
;used registers          : None                                                                
;arg registers           : None                                                                
;return registers        : None                                                                
;unsafe access registers : None                                                                
.macro  KER_DEBUG_PIN_INIT                                ;total 0.5uS @8MHz      (  4 clocks) 
        #ifdef KER_DBG_ENABLE                                                                  
		CBI   KER_DBG_PORT       , KER_DBG_PIN            ;clear port bit         (  2 clocks) 
		SBI   KER_DBG_DDR        , KER_DBG_PIN            ;set bit in DDR         (  2 clocks) 
		#endif                                                                                 
.endm                                                                                          
;;==============================debug pin operation init end================================;; 





;;===========================debug pin operation set starting===============================;; 
;used registers          : None                                                                
;arg registers           : None                                                                
;return registers        : None                                                                
;unsafe access registers : None                                                                
.macro  KER_DEBUG_PIN_SET                                 ;total 0.25uS @8MHz     (  2 clocks) 
        #ifdef KER_DBG_ENABLE                                                                  
        SBI   KER_DBG_PORT       , KER_DBG_PIN            ;set gpio               (  2 clocks) 
		#endif                                                                                 
.endm                                                                                          
;;==============================debug pin operation set end=================================;; 





;;===========================debug pin operation clear starting=============================;; 
;used registers          : None                                                                
;arg registers           : None                                                                
;return registers        : None                                                                
;unsafe access registers : None                                                                
.macro  KER_DEBUG_PIN_CLEAR                               ;total 0.25uS @8MHz     (  2 clocks) 
        #ifdef KER_DBG_ENABLE                                                                  
		CBI   KER_DBG_PORT       , KER_DBG_PIN            ;clear gpio             (  2 clocks) 
		#endif                                                                                 
.endm                                                                                          
;;==============================debug pin operation clear end===============================;; 






;;==================================context save starting===================================;; 
;used registers          : R0~R31                                                              
;arg registers           : None                                                                
;return registers        : None                                                                
;unsafe access registers : None                                                                
.macro  KER_CONTEXT_SAVE                                  ;total 7.88uS @8MHz     ( 83 clocks) 
        PUSH  R0                                          ;push R0                (  2 clocks) 
		IN    R0                 , IOSREG                 ;save SREG              (  1 clock ) 
		CLI                                               ;clear interrupt        (  1 clock ) 
		PUSH  R0                                          ;save SREG              (  2 clocks) 
		PUSH  R1                                          ;save R1                (  2 clocks) 
		CLR   R1                                          ;clear R1               (  1 clock ) 
		PUSH  R2                                          ;save R2                (  2 clocks) 
		PUSH  R3                                          ;save R3                (  2 clocks) 
		PUSH  R4                                          ;save R4                (  2 clocks) 
		PUSH  R5                                          ;save R5                (  2 clocks) 
		PUSH  R6                                          ;save R6                (  2 clocks) 
		PUSH  R7                                          ;save R7                (  2 clocks) 
		PUSH  R8                                          ;save R8                (  2 clocks) 
		PUSH  R9                                          ;save R9                (  2 clocks) 
		PUSH  R10                                         ;save R10               (  2 clocks) 
		PUSH  R11                                         ;save R11               (  2 clocks) 
		PUSH  R12                                         ;save R12               (  2 clocks) 
		PUSH  R13                                         ;save R13               (  2 clocks) 
		PUSH  R14                                         ;save R14               (  2 clocks) 
		PUSH  R15                                         ;save R15               (  2 clocks) 
		PUSH  R16                                         ;save R16               (  2 clocks) 
		PUSH  R17                                         ;save R17               (  2 clocks) 
		PUSH  R18                                         ;save R18               (  2 clocks) 
		PUSH  R19                                         ;save R19               (  2 clocks) 
		PUSH  R20                                         ;save R20               (  2 clocks) 
		PUSH  R21                                         ;save R21               (  2 clocks) 
		PUSH  R22                                         ;save R22               (  2 clocks) 
		PUSH  R23                                         ;save R23               (  2 clocks) 
		PUSH  R24                                         ;save R24               (  2 clocks) 
		PUSH  R25                                         ;save R25               (  2 clocks) 
		PUSH  R26                                         ;save R26               (  2 clocks) 
		PUSH  R27                                         ;save R27               (  2 clocks) 
		PUSH  R28                                         ;save R28               (  2 clocks) 
		PUSH  R29                                         ;save R29               (  2 clocks) 
		PUSH  R30                                         ;save R30               (  2 clocks) 
		PUSH  R31                                         ;save R31               (  2 clocks) 
		LDI   R30                , lo8(KerTSP)            ;fetch base pos low     (  1 clock ) 
		LDI   R31                , hi8(KerTSP)            ;fetch base pos high    (  1 clock ) 
		LDS   R18                , KerTID                 ;fetch task id          (  2 clocks) 
		LSL   R18                                         ;left shift to multiply (  1 clock ) 
		ADD   R30                , R18                    ;add offset to array    (  1 clock ) 
		LDI   R18                , 0x00                   ;clear for carry prop   (  1 clock ) 
		ADC   R31                , R18                    ;add carry if any       (  1 clock ) 
		IN    R18                , IOSPL                  ;fetch SPL0             (  1 clock ) 
		IN    R19                , IOSPH                  ;fetch SPH0             (  1 clock ) 
		STD   Z+0                , R18                    ;store SPL at ZP+0      (  2 clocks) 
		STD   Z+1                , R19                    ;store SPH at ZP+1      (  2 clocks) 
.endm                                                                                          
;;=====================================context save end=====================================;; 






;;=================================context restore starting=================================;; 
;used registers          : R0~R31                                                              
;arg registers           : None                                                                
;return registers        : None                                                                
;unsafe access registers : None                                                                
.macro  KER_CONTEXT_RESTORE                               ;total 8.38uS @8MHz     ( 81 clocks) 
        LDI   R30                , lo8(KerTSP)            ;fetch base pos low     (  1 clock ) 
		LDI   R31                , hi8(KerTSP)            ;fetch base pos high    (  1 clock ) 
		LDS   R18                , KerTID                 ;fetch task_id          (  2 clocks) 
		LSL   R18                                         ;left shift to multiply (  1 clock ) 
		ADD   R30                , R18                    ;add offset to array    (  1 clock ) 
		LDI   R18                , 0x00                   ;clear for carry prop   (  1 clock ) 
		ADC   R31                , R18                    ;add carry if any       (  1 clock ) 
		LDD   R18                , Z+0                    ;load SPL at ZP         (  2 clocks) 
		LDD   R19                , Z+1                    ;load SPH at ZP         (  2 clocks) 
		OUT   IOSPL              , R18                    ;load SPL0              (  1 clock ) 
		OUT   IOSPH              , R19                    ;load SPH0              (  1 clock ) 
		POP   R31                                         ;restore R31            (  2 clocks) 
		POP   R30                                         ;restore R30            (  2 clocks) 
		POP   R29                                         ;restore R29            (  2 clocks) 
		POP   R28                                         ;restore R28            (  2 clocks) 
		POP   R27                                         ;restore R27            (  2 clocks) 
		POP   R26                                         ;restore R26            (  2 clocks) 
		POP   R25                                         ;restore R25            (  2 clocks) 
		POP   R24                                         ;restore R24            (  2 clocks) 
		POP   R23                                         ;restore R23            (  2 clocks) 
		POP   R22                                         ;restore R22            (  2 clocks) 
		POP   R21                                         ;restore R21            (  2 clocks) 
		POP   R20                                         ;restore R20            (  2 clocks) 
		POP   R19                                         ;restore R19            (  2 clocks) 
		POP   R18                                         ;restore R18            (  2 clocks) 
		POP   R17                                         ;restore R17            (  2 clocks) 
		POP   R16                                         ;restore R16            (  2 clocks) 
		POP   R15                                         ;restore R15            (  2 clocks) 
		POP   R14                                         ;restore R14            (  2 clocks) 
		POP   R13                                         ;restore R13            (  2 clocks) 
		POP   R12                                         ;restore R12            (  2 clocks) 
		POP   R11                                         ;restore R11            (  2 clocks) 
		POP   R10                                         ;restore R10            (  2 clocks) 
		POP   R9                                          ;restore R9             (  2 clocks) 
		POP   R8                                          ;restore R8             (  2 clocks) 
		POP   R7                                          ;restore R7             (  2 clocks) 
		POP   R6                                          ;restore R6             (  2 clocks) 
		POP   R5                                          ;restore R5             (  2 clocks) 
		POP   R4                                          ;restore R4             (  2 clocks) 
		POP   R3                                          ;restore R3             (  2 clocks) 
		POP   R2                                          ;restore R2             (  2 clocks) 
		POP   R1                                          ;restore R1             (  2 clocks) 
		POP   R0                                          ;fetch SREG             (  2 clocks) 
		OUT   IOSREG             , R0                     ;load SREG              (  1 clock ) 
		POP   R0                                          ;restore R0             (  2 clocks) 
.endm                                                                                          
;;===================================context restore end====================================;; 





;;===================================msp zp save starting===================================;; 
;used registers          : R18, R19, R30, R31                                                  
;arg registers           : None                                                                
;return registers        : None                                                                
;unsafe access registers : None                                                                
.macro  KER_MSP_ZP_SAVE                                   ;total 1.25uS @8MHz     ( 10 clocks) 
        IN    R18                , IOSPL                  ;load SPL               (  1 clock ) 
		IN    R19                , IOSPH                  ;load SPH               (  1 clock ) 
		STS   KerMSPZP+0         , R18                    ;store SPL              (  2 clocks) 
		STS   KerMSPZP+1         , R19                    ;store SPH              (  2 clocks) 
		STS   KerMSPZP+2         , R30                    ;store ZL               (  2 clocks) 
		STS   KerMSPZP+3         , R31                    ;store ZH               (  2 clocks) 
.endm                                                                                          
;;======================================msp zp save end=====================================;; 





;;==================================msp zp restore starting=================================;; 
;used registers          : R18, R19, R30, R31                                                  
;arg registers           : None                                                                
;return registers        : None                                                                
;unsafe access registers : None                                                                
.macro  KER_MSP_ZP_RESTORE                                ;total 1.25uS @8MHz     ( 10 clocks) 
		LDS   R31                , KerMSPZP+3             ;fetch ZH               (  2 clocks) 
		LDS   R30                , KerMSPZP+2             ;fetch ZL               (  2 clocks) 
		LDS   R19                , KerMSPZP+1             ;fetch SPH              (  2 clocks) 
		LDS   R18                , KerMSPZP+0             ;fetch SPL              (  2 clocks) 
		OUT   IOSPL              , R18                    ;load SPL               (  1 clock ) 
		OUT   IOSPH              , R19                    ;load SPH               (  1 clock ) 
.endm                                                                                          
;;====================================msp zp restore end====================================;; 





;;=================================set reload val starting==================================;; 
;used registers          : R1~R31                                                              
;arg registers           : None                                                                
;return registers        : None                                                                
;unsafe access registers : None                                                                
.macro  KER_RUN_SCHEDULER                                 ;total 0.25uS @8MHz     (  2 clocks) 
        PUSH  R16                                         ;save                   (  2 clocks) 
		PUSH  R17                                         ;save                   (  2 clocks) 
        LDI   R16                , 0x00                   ;tid loop counter       (  1 clock ) 
		LDS   R17                , KerNTSK                ;load max task number   (  2 clocks) 
		LDS   R18                , KerLST                 ;load val               (  2 clocks) 
		LDI   R19                , 0xFF                   ;local lowest time      (  1 clock ) 
		LDI   R20                , 0xFF                   ;local hi prio          (  1 clock ) 
        LDI   R21                , 0x00                   ;local hi prio tid      (  1 clock ) 
		LDS   R22                , KerSCHM                ;load scheduler mode    (  2 clocks) 
		LDI   R26                , lo8(KerPrio)           ;load prio reg low      (  1 clock ) 
		LDI   R27                , hi8(KerPrio)           ;load prio reg high     (  1 clock ) 
		LDI   R30                , lo8(KerSleep)          ;load sleep reg low     (  1 clock ) 
		LDI   R31                , hi8(KerSleep)          ;load sleep reg high    (  1 clock ) 
	_KER_SCH_LOOP\@:
	    LD    R23                , Z                      ;load curr sleep val    (  2 clocks) 
		LD    R24                , X                      ;load prio val          (  2 clocks) 
		TST   R23                                         ;check if zero          (  1 clock ) 
		BREQ  _KER_SCH_LST\@                              ;if not zero            (  2 clocks) 
		TST   R22                                         ;check scheduler mdoe   (  1 clock ) 
		BRNE  _KER_SCH_LST\@                              ;if not zero            (  2 clocks) 
		SUB   R23                , R18                    ;subtract low time      (  1 clock ) 
		ST    Z                  , R23                    ;store new val          (  2 clocks) 
	_KER_SCH_LST\@:
	    CP    R23                , R19                    ;compare                (  1 clock ) 
		BRSH  _KER_SCH_PRIO\@
		TST   R23                                         ;check if zero          (  1 clock ) 
		BREQ  _KER_SCH_PRIO\@
		MOV   R19                , R23                    ;assign new low val     (  1 clock ) 
	_KER_SCH_PRIO\@:
	    TST   R23                                         ;check if zero          (  1 clock ) 
		BRNE  _KER_SCH_LCI\@                              ;jump to loop inc       (  2 clocks) 
		CP    R24                , R20                    ;compare                (  1 clock ) 
		BRSH  _KER_SCH_LCI\@                             ;jump to loop inc       (  2 clocks) 
		MOV   R20                , R24                    ;assign new hi prio     (  1 clock ) 
		MOV   R21                , R16                    ;assign new hi prio tid (  1 clock ) 
    _KER_SCH_LCI\@:
	    ADIW  R26                , 0x01                   ;increment X pointer    (  2 clocks) 
		ADIW  R30                , 0x01                   ;increment Z pointer    (  2 clocks) 
	    INC   R16                                         ;increment              (  1 clock ) 
	    CP    R16                , R17                    ;compare with ntask     (  1 clocks) 
		BRLO  _KER_SCH_LOOP\@                             ;if task id<ntask       (  2 clocks) 
	_KER_SCH_EXIT\@:
	    STS   KerLST             , R19                    ;store new lowest time  (  2 clocks) 
		STS   KerTID             , R21                    ;store new HPTID        (  2 clocks) 
		POP   R17                                         ;restore                (  2 clocks) 
		POP   R16                                         ;restore                (  2 clocks) 
.endm                                                                                          
;;===================================set reload val end=====================================;; 





;;===========================kernel disable analog domain starting==========================;; 
;used registers          : None                                                                
;arg registers           : None                                                                
;return registers        : None                                                                
;unsafe access registers : None                                                                
.macro KER_DISABLE_ANALOG_DOMAIN                          ;total 0.75uS @8MHz     ( 10 clocks) 
    #if defined(KER_IDLE_AS_SLEEP)
		LDS   R18                , SRADCSRA               ;load ADCSRA            (  2 clocks) 
		ANDI  R18                , 0x7F                   ;clear ADEN             (  1 clock ) 
		STS   SRADCSRA           , R18                    ;set val                (  2 clocks) 
		LDS   R18                , SRACSR                 ;load ACSR              (  2 clocks) 
		ORI   R18                , 0x80                   ;set ACD                (  1 clock ) 
		STS   SRACSR             , R18                    ;set val                (  2 clocks) 
	#endif                                                                                     
.endm                                                                                          
;;=============================kernel disable analog domain end=============================;; 





;;===============================kernel sleep config starting===============================;; 
;used registers          : R18                                                                 
;arg registers           : None                                                                
;return registers        : None                                                                
;unsafe access registers : R18                                                                 
.macro KER_SLEEP_INIT                                     ;total 0.63uS @8MHz     (  5 clocks) 
    #ifdef KER_IDLE_AS_SLEEP                                                                   
		LDI   R18                , 0x06                   ;set SM[2:0] val        (  1 clock ) 
		STS   SRSMCR             , R18                    ;set sleep control val  (  2 clocks) 
	#endif                                                                                     
.endm                                                                                          
;;================================kernel sleep config end===================================;; 





;;==============================kernel enter sleep mode starting============================;; 
;used registers          : None                                                                
;arg registers           : None                                                                
;return registers        : None                                                                
;unsafe access registers : None                                                                
.macro KER_ENTER_SLEEP                                    ;total 0.75uS @8MHz     (  6 clocks) 
    #ifdef KER_IDLE_AS_SLEEP                                                                   
		LDS   R18                , SRSMCR                 ;load SMCR              (  2 clocks) 
		ORI   R18                , 0x01                   ;set SE bit             (  1 clock ) 
		STS   SRSMCR             , R18                    ;set val                (  2 clocks) 
		SLEEP                                             ;sleep cpu              (  1 clock ) 
	#endif                                                                                     
.endm                                                                                          
;;================================kernel enter sleep mode end===============================;; 





;;===============================kernel exit sleep mode starting============================;; 
;used registers          : None                                                                
;arg registers           : None                                                                
;return registers        : None                                                                
;unsafe access registers : None                                                                
.macro KER_EXIT_SLEEP                                     ;total 0.63uS @8MHz     (  5 clocks) 
    #ifdef KER_IDLE_AS_SLEEP                                                                   
        LDS   R18                , SRSMCR                 ;load SMCR              (  2 clocks) 
		ANDI  R18                , 0xFE                   ;clear SE bit           (  1 clock ) 
		STS   SRSMCR             , R18                    ;set val                (  2 clocks) 
	#endif                                                                                     
.endm                                                                                          
;;=================================kernel exit sleep mode end===============================;; 





;;=================================ISR execution starting===================================;; 
.global  __vector_9                                                                            
    __vector_9:                                           ;total 40.00uS @8MHz    (344 clocks) 
	    KER_DEBUG_PIN_SET                                 ;debug pin set          (  2 clocks) 
		KER_CONTEXT_SAVE                                  ;save context           (          ) 
		;KER_EXIT_SLEEP                                    ;exit sleep if enabled  (  5 clocks) 
		LDI   R18                , 0x00                   ;handler mode           (  2 clocks) 
		STS   KerSCHM            , R18                    ;set val                (  2 clocks) 
		KER_RUN_SCHEDULER

		/*LDS  R18, KerTID
		LDS  R19, KerNTSK
		LDI  R20, 0x01
		ADD  R18, R20
		CP   R18, R19
		BRLO _VC_SKIP
		LDI  R18, 0x00
    _VC_SKIP:
	    STS  KerTID, R18*/

        KER_TIMER_RELOAD                                  ;reload timer           (  4 clocks) 
		KER_TIMER2_TCNT2_UB                               ;wait until update      (          )
		KER_CONTEXT_RESTORE                               ;restore context        (          ) 
	    KER_DEBUG_PIN_CLEAR                               ;debug pin clear        (  2 clocks) 
		RETI                                              ;return from interrupt  (  4 clocks) 
;;====================================ISR execution end=====================================;; 





;;================================SysTick reg init starting=================================;; 
;used registers          : R18, R19, R22, R24, R26(XL), R27(XH), R30(ZL), R31(ZH)              
;arg registers           : R24(Prescaler), R22(ReloadVal)                                      
;return registers        : None                                                                
;unsafe access registers : R18, R19, R22, R24, R26(XL), R27(XH), R30(ZL), R31(ZH)              
Kernel_Timer_Init:                                        ;total 11.50uS @8MHz    ( 92 clocks) 
		KER_DEBUG_PIN_INIT                                ;debug pin init         (  4 clocks) 
		KER_TIMER_INIT                                    ;init timer             (          ) 
		LDI   R24                , 0x00                   ;set reload val         (  1 clock ) 
		STS   SRTCNT2            , R24                    ;assign reload val      (  2 clocks) 
		RET                                               ;return from subroutine (  4 clocks) 
;;===================================SysTick reg init end===================================;; 





;;===============================kernel task create starting================================;; 
;used registers          : R18, R19, R20, R22, R24, R25, R26(XL), R27(XH), R30(ZL), R31(ZH)    
;arg registers           : R25:R24(FuncPtr), R22(TaskPriority)                                 
;return registers        : None                                                                
;unsafe access registers : R18, R19, R20, R22, R24, R25, R26(XL), R27(XH), R30(ZL), R31(ZH)    
Kernel_Task_Create:                                       ;total 21.50uS @8MHz    (172 clocks) 
        KER_MSP_ZP_SAVE                                   ;push MSP and ZP        ( 10 clocks) 
		;set priority to KerPrio                                                               
		LDI   R30                , lo8(KerPrio)           ;load low byte          (  1 clock ) 
		LDI   R31                , hi8(KerPrio)           ;load high byte         (  1 clock ) 
		LDS   R18                , KerTID                 ;fetch task id          (  2 clocks) 
		ADD   R30                , R18                    ;add offset to array    (  1 clock ) 
		LDI   R18                , 0x00                   ;clear for carry prop   (  1 clock ) 
		ADC   R31                , R18                    ;add carry if any       (  1 clock ) 
		ST    Z                  , R22                    ;save priority          (  2 clocks) 
		;set sleep time to 0 in KerSleep to make the task ready                                
		LDI   R30                , lo8(KerSleep)          ;load low byte          (  1 clock ) 
		LDI   R31                , hi8(KerSleep)          ;load high byte         (  1 clock ) 
		LDS   R18                , KerTID                 ;fetch task id          (  2 clocks) 
		ADD   R30                , R18                    ;add offset to array    (  1 clock ) 
		LDI   R18                , 0x00                   ;clear for carry prop   (  1 clock ) 
		ADC   R31                , R18                    ;add carry if any       (  1 clock ) 
		LDI   R18                , 0x00                   ;set sleep val to 0     (  1 clock ) 
		ST    Z                  , R18                    ;save status            (  2 clocks) 
		;calculate stack top for current task (KerStack + KER_STK_SZ*(task id+1) - 1)          
		LDS   R18                , KerTID                 ;load task id           (  2 clocks) 
		INC   R18                                         ;increment task id      (  1 clock ) 
		LDI   R19                , KER_STK_SZ             ;load stack size        (  1 clock ) 
		MUL   R18                , R19                    ;multiply to get offset (  2 clocks) 
		MOV   R30                , R0                     ;load multiplied low    (  1 clocks) 
		MOV   R31                , R1                     ;load multiplied high   (  1 clocks) 
		CLR   R1                                          ;gcc expects cleared    (  1 clock ) 
		SBIW  R30                , 0x01                   ;dec multiplied val-1   (  2 clocks) 
		LDI   R18                , lo8(KerStack)          ;load base addr low     (  1 clock ) 
		LDI   R19                , hi8(KerStack)          ;load base addr high    (  1 clock ) 
		ADD   R30                , R18                    ;add low bytes          (  1 clock ) 
		ADC   R31                , R19                    ;add high bytes+carry   (  1 clock ) 
		;set stack pointer                                                                     
		OUT   IOSPL              , R30                    ;load SPL               (  1 clock ) 
        OUT   IOSPH              , R31                    ;load SPH               (  1 clock ) 
		;function argument directly returns word address                                       
	    PUSH  R24                                         ;push word addr low     (  2 clocks) 
		PUSH  R25                                         ;push word addr high    (  2 clocks) 
		;push context to stack of this task                                                    
		SEI                                               ;enable interrupt       (  1 clock )
		KER_CONTEXT_SAVE                                  ;save context           ( 68 clocks)
		CLI                                               ;disable interrupt      (  1 clock ) 
		;increment task_id                                                                     
		LDS   R18                , KerTID                 ;load task_id           (  2 clocks) 
		INC   R18                                         ;increment task_id      (  1 clock ) 
		STS   KerTID             , R18                    ;store task_id          (  2 clocks) 
		;increment ntask                                                                       
		LDS   R18                , KerNTSK                ;load ntask             (  2 clocks) 
		INC   R18                                         ;increment ntask        (  1 clock ) 
		STS   KerNTSK            , R18                    ;store ntask            (  2 clocks) 
		KER_MSP_ZP_RESTORE                                ;pop MSP and ZP         ( 10 clocks) 
		RET                                               ;return from subroutine (  4 clocks) 
;;==================================kernel task create end==================================;; 





;;=================================kernel idle task starting================================;; 
;used registers          : None                                                                
;arg registers           : None                                                                
;return registers        : None                                                                
;unsafe access registers : None                                                                
Kernel_Task_Idle:                                                                              
	    KER_SLEEP_INIT                                    ;sleep init             (  5 clocks) 
		
    _IDLE_LOOP:                                           ;forever loop                        
	    KER_DISABLE_ANALOG_DOMAIN                         ;disable adc, ac        ( 10 clocks) 
		;#ifdef KER_CALL_FUNC_BEFORE_SLEEP                                                      
		;CALL  Kernel_PreSleep_Hook                        ;call func before sleep (  8 clocks) 
		;#endif                                                                                 
	    ;KER_ENTER_SLEEP                                   ;enter sleep mode       (  6 clocks) 
		LDI   R24                , 0xFF                   ;load max sleep time    (  1 clock ) 
		CALL  Kernel_Task_Sleep                           ;set sleep to max       (  2 clocks) 
		JMP   _IDLE_LOOP                                  ;jump to loop start     (  2 clocks) 
;;==================================kernel idle task end====================================;; 





;;===================================kernel init starting===================================;; 
;used registers          : R1, R18, R19, R22, R24, R25, R26(XL), R27(XH), R30(ZL), R31(ZH)     
;arg registers           : None                                                                
;return registers        : None                                                                
;unsafe access registers : R1, R18, R19, R22, R24, R25, R26(XL), R27(XH), R30(ZL), R31(ZH)     
Kernel_Init:                                              ;total 39.75uS @8MHz    (318 clocks) 
		CLR   R1                                          ;gcc expects            (  1 clock ) 
		CLI                                               ;disable interrupts     (  1 clock ) 
		LDI   R18                , 0x00                   ;set zero               (  1 clock ) 
		STS   KerTID             , R18                    ;assign val             (  2 clocks) 
		STS   KerHPTID           , R18                    ;assign val             (  2 clocks) 
		STS   KerNTSK            , R18                    ;assign val             (  2 clocks) 
		STS   KerLST             , R18                    ;assign val             (  2 clocks) 
		;create idle task at task did 0, priority 0xFF (lowest)                                
		LDI   R24                , lo8(Kernel_Task_Idle)  ;load func addr low     (  1 clock ) 
		LDI   R25                , hi8(Kernel_Task_Idle)  ;load func addr high    (  1 clock ) 
		LSR   R25                                         ;right shift to divide  (  1 clock ) 
		ROR   R24                                         ;rotate right th carry  (  1 clock ) 
		LDI   R22                , 0xFF                   ;set max val            (  1 clock ) 
		CALL  Kernel_Task_Create                          ;init idle task         (172 clocks) 
		RET                                               ;return from subroutine (  4 clocks) 
;;======================================kernel init end=====================================;; 





;;=================================kernel start tasks starting==============================;; 
;used registers          : R0~R31                                                              
;arg registers           : None                                                                
;return registers        : None                                                                
;unsafe access registers : R18, R19, R20, R24, R25, R30(ZL), R31(ZH)                           
Kernel_Start_Tasks:                                       ;total 25.63uS @8MHz    (205 clocks) 
        LDI   R18                , 0x00                   ;set max val            (  1 clock ) 
		STS   KerTID             , R18                    ;set max val            (  1 clock ) 
		LDI   R18                , 0x01                   ;handler mode           (  2 clocks) 
		STS   KerSCHM            , R18                    ;set val                (  2 clocks) 
		KER_RUN_SCHEDULER                                 ;run scheduler          (106 clocks) 
		CALL  Kernel_Timer_Init                           ;init timer             ( 92 clocks) 
		KER_CONTEXT_RESTORE                               ;restore context        ( 68 clocks) 
		RET                                               ;return from subroutine (  4 clocks) 
;;==================================kernel start tasks end==================================;; 





;;================================kernel task sleep starting================================;; 
;used registers          : R0~R31                                                              
;arg registers           : R24(SleepTime)                                                      
;return registers        : None                                                                
;unsafe access registers : R18, R19, R20, R24, R25, R30(ZL), R31(ZH)                           
Kernel_Task_Sleep:                                        ;total 37.25uS @8MHz    (298 clocks) 
        ;save current context                                                                  
        KER_CONTEXT_SAVE                                  ;save context           ( 69 clocks) 
		;create next task wakeup time (arg R24)                                                
		LDI   R30                , lo8(KerSleep)          ;load low byte          (  1 clock ) 
		LDI   R31                , hi8(KerSleep)          ;load high byte         (  1 clock ) 
		LDS   R18                , KerTID                 ;fetch task id          (  2 clocks) 
		ADD   R30                , R18                    ;add offset to array    (  1 clock ) 
		LDI   R18                , 0x00                   ;clear for carry prop   (  1 clock ) 
		ADC   R31                , R18                    ;add carry if any       (  1 clock ) 
		STD   Z+0                , R24                    ;save sleep time low    (  2 clocks) 
		;run scheduler, load next task sp, restore context                                     
		;LDI   R18                , 0x01                   ;handler mode           (  2 clocks) 
		;STS   KerSCHM            , R18                    ;set val                (  2 clocks) 
		;KER_RUN_SCHEDULER                                 ;run scheduler          (106 clocks) 
		;KER_TIMER_RELOAD                                  ;reload timer           (  4 clocks) 
		;KER_TIMER2_TCNT2_UB                               ;wait until update      (          )
		KER_CONTEXT_RESTORE                               ;restore context        ( 68 clocks) 
		;SEI
		RET                                               ;return from subroutine (  4 clocks) 
;;=================================kernel task sleep end====================================;; 



