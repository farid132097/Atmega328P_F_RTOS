

 ; File          : kernel.S
 ; Author        : MD. Faridul Islam (faridmdislam@gmail.com)
 ; Description   : AVR kernel for tickless (asynchronous) RTOS
 ; Created       : Jul 27, 2025, 09:30 PM
 ; Last Modified : Jul 30, 2026, 11:08 AM




#include "kernel.h"




;;============================define user address or macro starting=========================;; 
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
.global    KerINTST                                       ;declare space for interrupt state   
KerINTST:  .skip 1                                        ;single byte for storing curr state  
.global    KerSleep                                       ;declare space for task sleep time   
KerSleep:  .skip KER_MX_NTSK*1                            ;single byte for each task           
.global    KerPrio                                        ;declare space for task priority     
KerPrio:   .skip KER_MX_NTSK*1                            ;single byte for each task           
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
.global  Kernel_Vars_Init                                                                      
.global  Kernel_Init                                                                           
.global  Kernel_Task_Sleep
.global  Kernel_Task_Create
.global  Kernel_Start_Tasks
;;================================define global functions end===============================;; 

                                                                  




.macro  KER_DEBUG_PIN_INIT                                ;total 0.5uS @8MHz      (  4 clocks) 
        #ifdef KER_DBG_ENABLE                                                                  
		CBI   KER_DBG_PORT       , KER_DBG_PIN            ;clear port bit         (  2 clocks) 
		SBI   KER_DBG_DDR        , KER_DBG_PIN            ;set bit in DDR         (  2 clocks) 
		#endif                                                                                 
.endm                                                                                          






.macro  KER_DEBUG_PIN_SET                                 ;total 0.25uS @8MHz     (  2 clocks) 
        #ifdef KER_DBG_ENABLE                                                                  
        SBI   KER_DBG_PORT       , KER_DBG_PIN            ;set gpio               (  2 clocks) 
		#endif                                                                                 
.endm                                                                                          






.macro  KER_DEBUG_PIN_CLEAR                               ;total 0.25uS @8MHz     (  2 clocks) 
        #ifdef KER_DBG_ENABLE                                                                  
		CBI   KER_DBG_PORT       , KER_DBG_PIN            ;clear gpio             (  2 clocks) 
		#endif                                                                                 
.endm                                                                                          






.macro  KER_INTERRUPT_STATE_SAVE                          ;total 0.375uS @8MHz    (  3 clocks) 
        IN    R18                , IOSREG                 ;load val               (  1 clock ) 
		STS   KerINTST           , R18                    ;store val              (  2 clocks) 
.endm                                                                                          






.macro  KER_INTERRUPT_STATE_RESTORE                       ;total 0.625uS @8MHz    (  5 clocks) 
        LDS   R18                , KerINTST               ;load interrupt state   (  2 clocks) 
		SBRC  R18                , 0x07                   ;check bit7 (I bit)     (  2 clocks) 
		SEI                                               ;enable interrupt       (  1 clock ) 
.endm                                                                                          






.macro  KER_TIMER_INIT                                    ;~9.13uS @8MHz          (~73 clocks) 
		KER_INTERRUPT_STATE_SAVE                          ;save interrupt state   (  3 clocks) 
        CLI                                               ;disable interrupts     (  1 clock ) 
		LDI   R18                , 0x00                   ;clear interrupt enbits (  1 clock ) 
		STS   SRTIMSK2           , R18                    ;set val to TIMSK2      (  2 clocks) 
		STS   SRTCCR2A           , R18                    ;set val to TCCR2A      (  2 clocks) 
		STS   SRTCCR2B           , R18                    ;set val to TCCR2B      (  2 clocks) 
		STS   SRASSR             , R18                    ;set val to ASSR        (  2 clocks) 
		STS   SRTCNT2            , R18                    ;clear TCNT2            (  2 clocks) 
		LDI   R18                , 0x20                   ;set AS2 bit            (  1 clock ) 
		STS   SRASSR             , R18                    ;set val to ASSR        (  2 clocks) 
		LDI   R18                , 0x03                   ;prescaler 32           (  1 clock ) 
		STS   SRTCCR2B           , R18                    ;set prescaler          (  2 clocks) 
	KER_TCR2AUB\@:                                                                             
	    LDS   R18                , SRASSR                 ;load ASSR              (  2 clocks) 
        ANDI  R18                , 0x02                   ;check bit TCR2AUB      (  1 clock ) 
		BRNE  KER_TCR2AUB\@                               ;wait until AUB cleared (  2 clocks) 
	KER_TCR2BUB\@:                                                                             
	    LDS   R18                , SRASSR                 ;load ASSR              (  2 clocks) 
        ANDI  R18                , 0x01                   ;check bit TCR2BUB      (  1 clock ) 
		BRNE  KER_TCR2BUB\@                               ;wait until BUB cleared (  2 clocks) 
	KER_TCN2UB\@:                                                                              
	    LDS   R18                , SRASSR                 ;load ASSR              (  2 clocks) 
        ANDI  R18                , 0x10                   ;check bit TCNT2UB      (  1 clock ) 
		BRNE  KER_TCN2UB\@                                ;wait until UB cleared  (  2 clocks) 
		LDI   R18                , 0x01                   ;set bit                (  1 clock ) 
		STS   SRTIFR2            , R18                    ;set val                (  2 clocks) 
		LDI   R18                , 0x02                   ;set bit                (  1 clock ) 
		STS   SRTIFR2            , R18                    ;set val                (  2 clocks) 
		LDI   R18                , 0x04                   ;set bit                (  1 clock ) 
		STS   SRTIFR2            , R18                    ;set val                (  2 clocks) 
		KER_INTERRUPT_STATE_RESTORE                       ;restore interrupt      (  5 clocks) 
.endm                                                                                          






.macro  KER_TIMER_RELOAD_MS                               ;0.75uS @8MHz           (  6 clocks) 
        LDS   R18                , KerLST                 ;fetch lowst sleep time (  2 clocks) 
		CPI   R18                , 0x15                   ;compare with 21        (  1 clock ) 
		BRCS  KER_TIMER_LOAD_TCNT2\@                      ;jmp to label           (  2 clocks) 
		CPI   R18                , 0x3F                   ;compare with 63        (  1 clock ) 
		BRCC  KER_TIMER_RLD_CMP105\@                      ;jmp to label           (  2 clocks) 
		SUBI  R18                , 0xFF                   ;add 1                  (  1 clock ) 
		RJMP  KER_TIMER_LOAD_TCNT2\@                      ;jmp to label           (  2 clocks) 
	KER_TIMER_RLD_CMP105\@:                                                                    
		CPI   R18                , 0x69                   ;compare with 105       (  1 clock ) 
		BRCC  KER_TIMER_RLD_CMP146\@                      ;jmp to label           (  2 clocks) 
		SUBI  R18                , 0xFE                   ;add 2                  (  1 clock ) 
		RJMP  KER_TIMER_LOAD_TCNT2\@                      ;jmp to label           (  2 clocks) 
	KER_TIMER_RLD_CMP146\@:                                                                    
		CPI   R18                , 0x92                   ;compare with 146       (  1 clock ) 
		BRCC  KER_TIMER_RLD_CMP188\@                      ;jmp to label           (  2 clocks) 
		SUBI  R18                , 0xFD                   ;add 3                  (  1 clock ) 
		RJMP  KER_TIMER_LOAD_TCNT2\@                      ;jmp to label           (  2 clocks) 
	KER_TIMER_RLD_CMP188\@:                                                                    
		CPI   R18                , 0xBC                   ;compare with 188       (  1 clock ) 
		BRCC  KER_TIMER_RLD_CMP230\@                      ;jmp to label           (  2 clocks) 
		SUBI  R18                , 0xFC                   ;add 4                  (  1 clock ) 
		RJMP  KER_TIMER_LOAD_TCNT2\@                      ;jmp to label           (  2 clocks) 
	KER_TIMER_RLD_CMP230\@:                                                                    
		CPI   R18                , 0xE6                   ;compare with 230       (  1 clock ) 
		BRCC  KER_TIMER_RLD_ELSE\@                        ;jmp to label           (  2 clocks) 
		SUBI  R18                , 0xFB                   ;add 5                  (  1 clock ) 
		RJMP  KER_TIMER_LOAD_TCNT2\@                      ;jmp to label           (  2 clocks) 
	KER_TIMER_RLD_ELSE\@:                                                                      
		SUBI  R18                , 0xFA                   ;add 6                  (  1 clock ) 
		RJMP  KER_TIMER_LOAD_TCNT2\@                      ;jmp to label           (  2 clocks) 
	KER_TIMER_LOAD_TCNT2\@:                                                                    
		NEG   R18                                         ;256-val                (  1 clock ) 
		STS   SRTCNT2            , R18                    ;set val                (  2 clocks) 
	KER_TIMER_LOAD_BSY\@:                                                                      
        LDS   R18                , SRASSR                 ;load ASSR              (  2 clocks) 
		SBRC  R18                , 0x04                   ;check bit4 TCN2UB      (  2 clocks) 
		RJMP  KER_TIMER_LOAD_BSY\@                        ;jmp to label           (  2 clocks) 
		LDI   R18                , 0x01                   ;load val               (  1 clock ) 
		STS   SRTIFR2            , R18                    ;clear flag             (  2 clocks) 
		STS   SRTIMSK2           , R18                    ;enable ovf interrupt   (  2 clocks) 
.endm                                                                                          






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






.macro  KER_MSP_ZP_SAVE                                   ;total 1.25uS @8MHz     ( 10 clocks) 
        IN    R18                , IOSPL                  ;load SPL               (  1 clock ) 
		IN    R19                , IOSPH                  ;load SPH               (  1 clock ) 
		STS   KerMSPZP+0         , R18                    ;store SPL              (  2 clocks) 
		STS   KerMSPZP+1         , R19                    ;store SPH              (  2 clocks) 
		STS   KerMSPZP+2         , R30                    ;store ZL               (  2 clocks) 
		STS   KerMSPZP+3         , R31                    ;store ZH               (  2 clocks) 
.endm                                                                                          






.macro  KER_MSP_ZP_RESTORE                                ;total 1.25uS @8MHz     ( 10 clocks) 
		LDS   R31                , KerMSPZP+3             ;fetch ZH               (  2 clocks) 
		LDS   R30                , KerMSPZP+2             ;fetch ZL               (  2 clocks) 
		LDS   R19                , KerMSPZP+1             ;fetch SPH              (  2 clocks) 
		LDS   R18                , KerMSPZP+0             ;fetch SPL              (  2 clocks) 
		OUT   IOSPL              , R18                    ;load SPL               (  1 clock ) 
		OUT   IOSPH              , R19                    ;load SPH               (  1 clock ) 
.endm                                                                                          






.macro  KER_LOAD_TASK_ID_AND_SP                           ;total 1.75uS @8MHz     ( 14 clocks) 
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
.endm                                                                                          






.macro  KER_RUN_SCHEDULER                                 ;total 0.25uS @8MHz     (  2 clocks) 
		LDS   R18                , KerTID                 ;load val               (  2 clocks) 
		LDS   R19                , KerNTSK                ;load ntask             (  2 clocks) 
		LDI   R20                , 0x01                   ;set val                (  1 clock ) 
		ADD   R18                , R20                    ;increment val          (  1 clock ) 
		CP    R18                , R19                    ;compare val            (  1 clock ) 
		BRLO  KER_SCH_ASSN\@                                                                   
		LDI   R18                , 0x00                   ;roll back              (  1 clock ) 
	KER_SCH_ASSN\@:                                                                            
	    STS   KerTID             , R18                    ;save val               (  2 clocks) 
.endm                                                                                          






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






.macro KER_SLEEP_INIT                                     ;total 0.63uS @8MHz     (  5 clocks) 
    #ifdef KER_IDLE_AS_SLEEP                                                                   
		LDI   R18                , 0x06                   ;set SM[2:0] val        (  1 clock ) 
		STS   SRSMCR             , R18                    ;set sleep control val  (  2 clocks) 
	#endif                                                                                     
.endm                                                                                          






.macro KER_ENTER_SLEEP                                    ;total 0.75uS @8MHz     (  6 clocks) 
    #ifdef KER_IDLE_AS_SLEEP                                                                   
		LDS   R18                , SRSMCR                 ;load SMCR              (  2 clocks) 
		ORI   R18                , 0x01                   ;set SE bit             (  1 clock ) 
		STS   SRSMCR             , R18                    ;set val                (  2 clocks) 
		SLEEP                                             ;sleep cpu              (  1 clock ) 
	#endif                                                                                     
.endm                                                                                          







.macro KER_EXIT_SLEEP                                     ;total 0.63uS @8MHz     (  5 clocks) 
    #ifdef KER_IDLE_AS_SLEEP                                                                   
        LDS   R18                , SRSMCR                 ;load SMCR              (  2 clocks) 
		ANDI  R18                , 0xFE                   ;clear SE bit           (  1 clock ) 
		STS   SRSMCR             , R18                    ;set val                (  2 clocks) 
	#endif                                                                                     
.endm                                                                                          







.global  __vector_9                                                                            
    __vector_9:                                           ;total 40.00uS @8MHz    (344 clocks) 
	    KER_DEBUG_PIN_SET                                 ;debug pin set          (  2 clocks) 
		KER_CONTEXT_SAVE                                  ;save context           ( 83 clocks) 

		LDI  R18,  0x00
		STS  SRTIMSK2, R18
		
		KER_RUN_SCHEDULER
		KER_LOAD_TASK_ID_AND_SP

		KER_CONTEXT_RESTORE                               ;save context           ( 81 clocks) 
	    KER_DEBUG_PIN_CLEAR                               ;debug pin clear        (  2 clocks) 
		RETI                                              ;return from interrupt  (  4 clocks) 






Kernel_Timer_Init:                                        ;total 11.50uS @8MHz    ( 92 clocks) 
		KER_TIMER_INIT                                    ;init timer             (          ) 
		RET                                               ;return from subroutine (  4 clocks) 


Kernel_Vars_Init:                                         ;total 1.875uS @8MHz    ( 15 clocks) 
		LDI   R18                , 0x00                   ;clear for carry prop   (  1 clock ) 
		STS   KerTID             , R18                    ;store task_id          (  2 clocks) 
		STS   KerHPTID           , R18                    ;store hi prio task_id  (  2 clocks) 
		STS   KerNTSK            , R18                    ;store ntask            (  2 clocks) 
		STS   KerLST             , R18                    ;store lowest sleep dur (  2 clocks) 
		STS   KerSCHM            , R18                    ;store scheduler mode   (  2 clocks) 
		RET                                               ;return from subroutine (  4 clocks) 



Kernel_Task_Create:                                       ;total 21.50uS @8MHz    (172 clocks) 
		KER_MSP_ZP_SAVE                                   ;push MSP and ZP        ( 18 clocks) 
		;set priority to KerPrio+task_id                                                       
		LDI   R30                , lo8(KerPrio)           ;load low byte          (  1 clock ) 
		LDI   R31                , hi8(KerPrio)           ;load high byte         (  1 clock ) 
		LDS   R18                , KerTID                 ;fetch task_id          (  2 clocks) 
		ADD   R30                , R18                    ;add offset to array    (  1 clock ) 
		LDI   R18                , 0x00                   ;clear for carry prop   (  1 clock ) 
		ADC   R31                , R18                    ;add carry if any       (  1 clock ) 
		ST    Z                  , R22                    ;save priority          (  2 clocks) 

		;set task status to KerSleep+task_id                                                  
		LDI   R30                , lo8(KerSleep)          ;load low byte          (  1 clock ) 
		LDI   R31                , hi8(KerSleep)          ;load high byte         (  1 clock ) 
		LDS   R18                , KerTID                 ;fetch task_id          (  2 clocks) 
		ADD   R30                , R18                    ;add offset to array    (  1 clock ) 
		LDI   R18                , 0x00                   ;clear for carry prop   (  1 clock ) 
		ADC   R31                , R18                    ;add carry if any       (  1 clock ) 
		ST    Z                  , R22                    ;save priority          (  2 clocks) 
		LDI   R18                , 0x00                   ;set sleep time->ready  (  1 clock ) 
		ST    Z                  , R18                    ;save status            (  2 clocks) 

		;stack pointer for current task (KerStack + KER_STK_SZ*(task_id+1) - 1) ->stack top    
		LDS   R18                , KerTID                 ;load task_id           (  2 clocks) 
		INC   R18                                         ;increment task_id      (  1 clock ) 
		LDI   R19                , KER_STK_SZ             ;load stack size        (  1 clock ) 
		MUL   R18                , R19                    ;multiply to get offset (  2 clocks) 
		MOV   R30                , R0                     ;load multiplied low    (  1 clocks) 
		MOV   R31                , R1                     ;load multiplied high   (  1 clocks) 
		SBIW  R30                , 0x01                   ;dec multiplied val-1   (  2 clocks) 
		CLR   R1                                          ;gcc expects cleared    (  1 clock ) 
		LDI   R18                , lo8(KerStack)          ;load base addr low     (  1 clock ) 
		LDI   R19                , hi8(KerStack)          ;load base addr high    (  1 clock ) 
		ADD   R30                , R18                    ;add low bytes          (  1 clock ) 
		ADC   R31                , R19                    ;add high bytes+carry   (  1 clock ) 
		OUT   IOSPL              , R30                    ;load SPL               (  1 clock ) 
        OUT   IOSPH              , R31                    ;load SPH               (  1 clock ) 
		;function argument directly returns word address                                       
	    PUSH  R24                                         ;push word addr low     (  2 clocks) 
		PUSH  R25                                         ;push word addr high    (  2 clocks) 
		;push context to stack of this task                                                    
		SEI                                               ;enable interrupt       (  1 clock ) 
		KER_CONTEXT_SAVE                                  ;save context           ( 68 clocks) 
		;read stack pointer of current task (necessary when restore)                           
		IN    R18                , IOSPL                  ;read SPL               (  1 clock ) 
        IN    R19                , IOSPH                  ;read SPH               (  1 clock ) 
		;calculate the address where current task's SP will be stored and store SP             
		LDS   R20                , KerTID                 ;load task_id           (  2 clocks) 
		LSL   R20                                         ;left shift to multiply (  1 clock ) 
		LDI   R30                , lo8(KerTSP)            ;fetch base pos low     (  1 clock ) 
		LDI   R31                , hi8(KerTSP)            ;fetch base pos high    (  1 clock ) 
		ADD   R30                , R20                    ;add offset to array    (  1 clock ) 
		LDI   R20                , 0x00                   ;clear reg              (  1 clock ) 
		ADC   R31                , R20                    ;add carry if any       (  1 clock ) 
		ST    Z+                 , R18                    ;SPL at KerTSP+offset   (  2 clocks) 
		ST    Z                  , R19                    ;SPH at KerTSP+offset   (  2 clocks) 
		;increment task_id                                                                     
		LDS   R18                , KerTID                 ;load task_id           (  2 clocks) 
		INC   R18                                         ;increment task_id      (  1 clock ) 
		STS   KerTID             , R18                    ;store task_id          (  2 clocks) 
		;increment ntask                                                                       
		LDS   R18                , KerNTSK                ;load ntask             (  2 clocks) 
		INC   R18                                         ;increment ntask        (  1 clock ) 
		STS   KerNTSK   , R18                             ;store ntask            (  2 clocks) 
		KER_MSP_ZP_RESTORE                                ;pop MSP and ZP         ( 18 clocks) 
		RET                                               ;return from subroutine (  4 clocks) 





Kernel_Task_Idle:                                                                              
	    KER_SLEEP_INIT                                    ;sleep init             (  5 clocks) 
    IDLE_LOOP:                                            ;forever loop                        
	    ;KER_DISABLE_ANALOG_DOMAIN                         ;disable adc, ac        ( 10 clocks) 
		LDI   R24   , 100
		CALL  Kernel_Task_Sleep
		JMP   IDLE_LOOP                                   ;jump to loop start     (  2 clocks) 





Kernel_Init:                                              ;total 39.75uS @8MHz    (318 clocks) 
        CLI                                               ;clear interrupt        (  1 clock ) 
		KER_MSP_ZP_SAVE                                   ;push MSP and ZP        ( 18 clocks) 
		KER_DEBUG_PIN_INIT                                ;debug pin init         (  4 clocks) 
		CALL  Kernel_Vars_Init                            ;variables init         ( 15 clocks) 
		
		KER_MSP_ZP_RESTORE                                ;pop MSP and ZP         ( 18 clocks) 
		LDI   R24                , lo8(Kernel_Task_Idle)  ;load func addr low     (  1 clock ) 
		LDI   R25                , hi8(Kernel_Task_Idle)  ;load func addr high    (  1 clock ) 
		LSR   R25                                         ;right shift to divide  (  1 clock ) 
		ROR   R24                                         ;rotate right th carry  (  1 clock ) 
		LDI   R22                , 0xFF                   ;set max val            (  1 clock ) 
		CALL  Kernel_Task_Create
		RET                                               ;return from subroutine (  4 clocks) 






Kernel_Start_Tasks:                                       ;total 25.63uS @8MHz    (205 clocks) 
		LDI   R18                , 0x00                   ;clear for carry prop   (  1 clock ) 
		STS   KerTID             , R18                    ;store task_id          (  2 clocks) 
		KER_LOAD_TASK_ID_AND_SP                           ;load next task id, SP  ( 14 clocks) 
		KER_CONTEXT_RESTORE                               ;restore context        ( 68 clocks) 
		CALL  Kernel_Timer_Init                           ;timer init             (--- clocks) 
		SEI
		RET                                               ;return from subroutine (  4 clocks) 





Kernel_Task_Sleep:                                        ;total 37.25uS @8MHz    (298 clocks) 
		STS   KerLST             , R24                    ;store val              (  2 clocks) 
		KER_TIMER_RELOAD_MS                               ;reload val             (--- clocks) 
		KER_ENTER_SLEEP
		RET                                               ;return from subroutine (  4 clocks) 



