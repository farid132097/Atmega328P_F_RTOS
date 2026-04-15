

 ; File          : kernel.S
 ; Author        : MD. Faridul Islam (faridmdislam@gmail.com)
 ; Description   : AVR kernel for bare-metal RTOS
 ; Created       : Jul 27, 2025, 09:30 PM
 ; Last Modified : Feb 19, 2026, 11:39 AM




#include <avr/io.h>
#include "kernel.h"



;;============================define user address or macro starting=========================;; 
.equ     KER_RLD,         0x00                            ;KER_RLD=0xFF-(F_CPU/KER_PRS/KER_TR) 
.equ     KER_STK_SZ,      128                             ;stack size in bytes for each task   
.equ     KER_MX_NTSK,     KER_MAX_TASK+1                  ;max number of tasks                 
;;==============================define user address or macro end============================;; 


;;===============================define data offsets starting===============================;; 
.equ     OFT_STS  ,       0x00                            ;offset from KerTCB task status      
.equ     OFT_SLP  ,       0x01                            ;offset from KerTCB sleep duration   
.equ     OFT_PRIO ,       0x02                            ;offset from KerTCB task priority    
.equ     OFT_PSP  ,       0x03                            ;offset from KerTCB task PSP         
.equ     OFB_CTSK ,       0x00                            ;offset from KerBase curr task       
.equ     OFB_NTSK ,       0x01                            ;offset from KerBase next task       
.equ     OFB_TTSK ,       0x02                            ;offset from KerBase total tasks     
;;==================================define data offsets end=================================;; 



;;===========================define hardware reg address starting===========================;; 
;SRAM Mapped Addresses, LDS/STS can be used                                                    
.equ     SRASSR  ,        0xB6                            ;manually defined ASSR in SRAM       
.equ     SROCR2B ,        0xB4                            ;manually defined OCR2B in SRAM      
.equ     SROCR2A ,        0xB3                            ;manually defined OCR2A in SRAM      
.equ     SRTCNT2 ,        0xB2                            ;manually defined TNCT2 in SRAM      
.equ     SRTCCR2B,        0xB1                            ;manually defined TCCR2B in SRAM     
.equ     SRTCCR2A,        0xB0                            ;manually defined TCCR2A in SRAM     
.equ     SRADMUX ,        0x7C                            ;manually defined ADMUX in SRAM      
.equ     SRADCSRA,        0x7A                            ;manually defined ADCSRA in SRAM     
.equ     SRTIMSK2,        0x70                            ;manually defined TIMSK2 in SRAM     
.equ     SRCLKPR ,        0x61                            ;manually defined CLKPR in SRAM      
.equ     SRWDTCSR,        0x60                            ;manually defined WDTCSR in SRAM     
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
.global    KerBase                                        ;space for kernel base               
KerBase:   .skip 10                                       ;allocate space                      
.global    KerTCB                                         ;space for stack                     
KerTCB:    .skip KER_STK_SZ*KER_MX_NTSK                   ;KER_STK_SZ bytes for each task      
;;==============================define global variables end=================================;; 





;;===============================define text section starting===============================;; 
.section .text                                                                                 
;;==================================define text section end=================================;; 





;;==============================define global functions starting============================;; 
.global  Kernel_Init                                                                           
;;================================define global functions end===============================;; 





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
		LDI   R18                , KER_RLD                ;clear reg              (  1 clock ) 
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




;;===================================save r0~r31 starting===================================;; 
;used registers          : R0~R31                                                              
;arg registers           : None                                                                
;return registers        : None                                                                
;unsafe access registers : None                                                                
.macro  KER_SAVE_R0_R31                                   ;total 7.88uS @8MHz     ( 63 clocks) 
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
.endm                                                                                          
;;======================================save r0~r31 end=====================================;; 





;;=================================restore r0~r31 starting==================================;; 
;used registers          : R0~R31                                                              
;arg registers           : None                                                                
;return registers        : None                                                                
;unsafe access registers : None                                                                
.macro  KER_RESTORE_R0_R31                                ;total 8.38uS @8MHz     ( 62 clocks) 
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
		SEI                                               ;enable interrupt       (  1 clock ) 
.endm                                                                                          
;;====================================restore r0~r31 end====================================;; 


;;=====================================save psp starting====================================;; 
;used registers          : R0~R31                                                              
;arg registers           : None                                                                
;return registers        : None                                                                
;unsafe access registers : None                                                                
.macro  KER_SAVE_PSP                                      ;total 7.88uS @8MHz     ( 63 clocks) 
        
	    LDI   R30                , lo8(KerTCB+OFB_PSP)    ;fetch task_id          (  2 clocks) 
		LDI   R31                , hi8(KerTCB+OFB_PSP)    ;fetch task_id          (  2 clocks) 
		
        SEI                                               ;enable interrupt       (  1 clock ) 
.endm                                                                                          
;;======================================save r0~r31 end=====================================;; 



.global  __vector_9                                                                            
    __vector_9:                                           ;total 40.00uS @8MHz    (344 clocks) 
	    KER_DEBUG_PIN_SET                                 ;debug pin set          (  2 clocks) 
		KER_SAVE_R0_R31


		LDI   R18                , 0xFF                   ;clear reg              (  1 clock ) 
		STS   SRTCNT2            , R18                    ;clear TCNT2            (  2 clocks) 


		KER_RESTORE_R0_R31
	    KER_DEBUG_PIN_CLEAR                               ;debug pin clear        (  2 clocks) 
		RETI                                              ;return from interrupt  (  4 clocks) 





;;===================================kernel init starting===================================;; 
;used registers          : R1, R18, R19, R22, R24, R25, R26(XL), R27(XH), R30(ZL), R31(ZH)     
;arg registers           : None                                                                
;return registers        : None                                                                
;unsafe access registers : R1, R18, R19, R22, R24, R25, R26(XL), R27(XH), R30(ZL), R31(ZH)     
Kernel_Init:                                              ;total 39.75uS @8MHz    (318 clocks) 
		CLR   R1                                          ;gcc expects            (  1 clock ) 
        KER_DEBUG_PIN_INIT
		KER_TIMER2_ASYNC_INIT
		SEI
		RET                                               ;return from subroutine (  4 clocks) 
;;======================================kernel init end=====================================;; 

