;
; CS1022 Introduction to Computing II 2018/2019
; Chess Clock
;

T0IR			EQU	0xE0004000
T0TCR			EQU	0xE0004004
T0TC			EQU	0xE0004008
T0MR0			EQU	0xE0004018
T0MCR			EQU	0xE0004014
	
T1IR 			EQU 0xE0008000
T1TCR 			EQU 0xE0008004
T1TC 			EQU 0xE0008008
T1MR0 			EQU 0xE0008018
T1MCR 			EQU 0xE0008014

PINSEL4			EQU	0xE002C010

FIO2DIR1		EQU	0x3FFFC041
FIO2PIN1		EQU	0x3FFFC055

EXTINT			EQU	0xE01FC140
EXTMODE			EQU	0xE01FC148
EXTPOLAR		EQU	0xE01FC14C

VICIntSelect	EQU	0xFFFFF00C
VICIntEnable	EQU	0xFFFFF010
VICVectAddr0	EQU	0xFFFFF100
VICVectPri0		EQU	0xFFFFF200
VICVectAddr		EQU	0xFFFFFF00
VICIntEnClear 	EQU 0xFFFFF014

VICVectT0		EQU	4
VICVectT1 		EQU 5
	
VICVectEINT0	EQU	14
VICVectEINT1 	EQU 15

Irq_Stack_Size	EQU	0x80

Mode_USR        EQU     0x10
Mode_IRQ        EQU     0x12
I_Bit           EQU     0x80            ; when I bit is set, IRQ is disabled
F_Bit           EQU     0x40            ; when F bit is set, FIQ is disabled



	AREA	RESET, CODE, READONLY
	ENTRY

	; Exception Vectors

	B	Reset_Handler	; 0x00000000
	B	Undef_Handler	; 0x00000004
	B	SWI_Handler		; 0x00000008
	B	PAbt_Handler	; 0x0000000C
	B	DAbt_Handler	; 0x00000010
	NOP					; 0x00000014
	B	IRQ_Handler		; 0x00000018
	B	FIQ_Handler		; 0x0000001C

;
; Reset Exception Handler
;
Reset_Handler

	;
	; Initialize Stack Pointers (SP) for each mode we are using
	;

	; Stack Top
	LDR	R0, =0x40010000

	; Enter irq mode and set initial SP
	MSR     CPSR_c, #Mode_IRQ:OR:I_Bit:OR:F_Bit
	MOV     SP, R0
	SUB     R0, R0, #Irq_Stack_Size

	; Enter user mode and set initial SP
	MSR     CPSR_c, #Mode_USR
	MOV		SP, R0

	;
	; your initialisation goes here
	;
	
	;
	; Configure TIMER0
	;

	; Stop and reset TIMER0 using Timer Control Register
	; Set bit 0 of TCR to 0 to stop TIMER
	; Set bit 1 of TCR to 1 to reset TIMER
	LDR	R5, =T0TCR
	LDR	R6, =0x2
	STRB R6, [R5]

	; Clear any previous TIMER0 interrupt by writing 0xFF to the TIMER0
	; Interrupt Register (T0IR)
	LDR	R5, =T0IR
	LDR	R6, =0xFF
	STRB R6, [R5]

	; Set match register for 15 secs using Match Register
	; Assuming a 1Mhz clock input to TIMER0, set MR
	; MR0 (0xE0004018) to 15,000,000
	LDR	R4, =T0MR0
	LDR	R5, =15000000
	STR	R5, [R4]

	; IRQ on match using Match Control Register
	; Set bit 0 of MCR to 1 to turn on interrupts
	; Set bit 1 of MCR to 0 so the counter doesn't reset when it matches
	; Set bit 2 of MCR to 1 to disable counter after match
	LDR	R4, =T0MCR
	LDR	R5, =0x05
	STRH R5, [R4]
	
	;
	; Configure VIC for TIMER0 interrupts
	;

	; Useful VIC vector numbers and masks for following code
	LDR	R3, =VICVectT0				; vector 4
	LDR	R4, =(1 << VICVectT0) 		; bit mask for vector 4

	; VICIntSelect - Clear bit 4 of VICIntSelect register to cause
	; channel 4 (TIMER0) to raise IRQs (not FIQs)
	LDR	R5, =VICIntSelect			; addr = VICVectSelect;
	LDR	R6, [R5]					; tmp = Memory.Word(addr);
	BIC	R6, R6, R4					; Clear bit for Vector 0x04
	STR	R6, [R5]					; Memory.Word(addr) = tmp;

	; Set Priority for VIC channel 4 (TIMER0) to lowest (15) by setting
	; VICVectPri4 to 15. Note: VICVectPri4 is the element at index 4 of an
	; array of 4-byte values that starts at VICVectPri0.
	; i.e. VICVectPri4=VICVectPri0+(4*4)
	LDR	R5, =VICVectPri0			; addr = VICVectPri0;
	MOV	R6, #15						; pri = 15;
	STR	R6, [R5, R3, LSL #2]		; Memory.Word(addr + vector * 4) = pri;

	; Set Handler routine address for VIC channel 4 (TIMER0) to address of
	; our handler routine (TimerHandler). Note: VICVectAddr4 is the element
	; at index 4 of an array of 4-byte values that starts at VICVectAddr0.
	; i.e. VICVectAddr4=VICVectAddr0+(4*4)
	LDR	R5, =VICVectAddr0			; addr = VICVectAddr0;
	LDR	R6, =Timer0_Handler			; handler = address of TimerHandler;
	STR	R6, [R5, R3, LSL #2]		; Memory.Word(addr + vector * 4) = handler

	; Enable VIC channel 4 (TIMER0) by writing a 1 to bit 4 of VICIntEnable
	LDR	R5, =VICIntEnable			; addr = VICIntEnable;
	STR	R4, [R5]					; enable interrupts for vector 0x4
	
	
	
	;
	; Configure TIMER1
	;
	
	; Stop and reset TIMER1 using Timer Control Register
	; Set bit 0 of TCR to 0 to stop TIMER
	; Set bit 1 of TCR to 1 to reset TIMER
	LDR	R5, =T1TCR
	LDR	R6, =0x2
	STRB R6, [R5]

	; Clear any previous TIMER1 interrupt by writing 0xFF to the TIMER1
	; Interrupt Register (T1IR)
	LDR	R5, =T1IR
	LDR	R6, =0xFF
	STRB R6, [R5]

	; Set match register for 15 secs using Match Register
	; Assuming a 1Mhz clock input to TIMER1, set MR
	; MR0 (0xE0004018) to 15,000,000
	LDR	R4, =T1MR0
	LDR	R5, =15000000
	STR	R5, [R4]

	; IRQ on match using Match Control Register
	; Set bit 0 of MCR to 1 to turn on interrupts
	; Set bit 1 of MCR to 0 so the counter doesn't reset when it matches
	; Set bit 2 of MCR to 1 to disable counter after match
	LDR	R4, =T1MCR
	LDR	R5, =0x05
	STRH R5, [R4]
	
	
	;
	; Configure VIC for TIMER1 interrupts
	;

	; Useful VIC vector numbers and masks for following code
	LDR	R3, =VICVectT1				; vector 5
	LDR	R4, =(1 << VICVectT1) 		; bit mask for vector 5

	; VICIntSelect - Clear bit 5 of VICIntSelect register to cause
	; channel 5 (TIMER0) to raise IRQs (not FIQs)
	LDR	R5, =VICIntSelect			; addr = VICVectSelect;
	LDR	R6, [R5]					; tmp = Memory.Word(addr);
	BIC	R6, R6, R4					; Clear bit for Vector 0x05
	STR	R6, [R5]					; Memory.Word(addr) = tmp;

	; Set Priority for VIC channel 5 (TIMER1) to lowest (15) by setting
	; VICVectPri5 to 15. Note: VICVectPri5 is the element at index 5 of an
	; array of 4-byte values that starts at VICVectPri0.
	; i.e. VICVectPri5=VICVectPri0+(5*4)
	LDR	R5, =VICVectPri0			; addr = VICVectPri0;
	MOV	R6, #15						; pri = 15;
	STR	R6, [R5, R3, LSL #2]		; Memory.Word(addr + vector * 4) = pri;

	; Set Handler routine address for VIC channel 5 (TIMER1) to address of
	; our handler routine (TimerHandler). Note: VICVectAddr5 is the element
	; at index 5 of an array of 4-byte values that starts at VICVectAddr0.
	; i.e. VICVectAddr4=VICVectAddr0+(5*4)
	LDR	R5, =VICVectAddr0			; addr = VICVectAddr0;
	LDR	R6, =Timer1_Handler			; handler = address of TimerHandler;
	STR	R6, [R5, R3, LSL #2]		; Memory.Word(addr + vector * 4) = handler

	; Enable VIC channel 5 (TIMER1) by writing a 1 to bit 5 of VICIntEnable
	LDR	R5, =VICIntEnable			; addr = VICIntEnable;
	STR	R4, [R5]					; enable interrupts for vector 5
	
	
	;
	; Configure EINT0
	;
	
	
	; Enable P2.10 for EINT0
	LDR	R4, =PINSEL4
	LDR	R5, [R4]					; read current value
	BIC	R5, #(0x03 << 20)			; clear bits 21:20
	ORR	R5, #(0x01 << 20)			; set bits 21:20 to 01
	STR	R5, [R4]					; write new value

	; Set edge-sensitive mode for EINT0
	LDR	R4, =EXTMODE
	LDR	R5, [R4]				
	ORR	R5, #1						
	STRB R5, [R4]				

	; Set rising-edge mode for EINT0
	LDR	R4, =EXTPOLAR
	LDR	R5, [R4]				
	BIC	R5, #1					
	STRB R5, [R4]			

	; Reset EINT0
	LDR	R4, =EXTINT
	MOV	R5, #1
	STRB R5, [R4]
	
	
	;
	; Configure VIC for EINT0 interrupts
	;

	; Useful VIC vector numbers and masks for following code
	LDR	R4, =VICVectEINT0			; vector 14
	LDR	R5, =(1 << VICVectEINT0) 	; bit mask for vector 14

	; VICIntSelect - Clear bit 14 of VICIntSelect register to cause
	; channel 14 (EINT0) to raise IRQs (not FIQs)
	LDR	R6, =VICIntSelect			; addr = VICVectSelect;
	LDR	R7, [R6]					; tmp = Memory.Word(addr);
	BIC	R7, R7, R5					; Clear bit for Vector 14
	STR	R7, [R6]					; Memory.Word(addr) = tmp;

	; Set Priority for VIC channel 14 (EINT0) to lowest (15) by setting
	; VICVectPri4 to 15. Note: VICVectPri4 is the element at index 14 of an
	; array of 4-byte values that starts at VICVectPri0.
	; i.e. VICVectPri14=VICVectPri0+(14*4)
	LDR	R6, =VICVectPri0			; addr = VICVectPri0;
	MOV	R7, #15						; pri = 15;
	STR	R7, [R6, R4, LSL #2]		; Memory.Word(addr + vector * 4) = pri;

	; Set Handler routine address for VIC channel 14 (EINT0) to address of
	; our handler routine (ButtonHandler). Note: VICVectAddr14 is the element
	; at index 14 of an array of 4-byte values that starts at VICVectAddr0.
	; i.e. VICVectAddr14=VICVectAddr0+(14*4)
	LDR	R6, =VICVectAddr0			; addr = VICVectAddr0;
	LDR	R7, =Button1_Handler		; handler = address of ButtonHandler;
	STR	R7, [R6, R4, LSL #2]		; Memory.Word(addr + vector * 4) = handler

	; Enable VIC channel 14 (EINT0) by writing a 1 to bit 14 of VICIntEnable
	LDR	R6, =VICIntEnable			; addr = VICIntEnable;
	STR	R5, [R6]					; enable interrupts for vector 14
	
	
	;
	; Configure EINT1
	;
	
	; Enable P2.11 for EINT1
	LDR	R4, =PINSEL4
	LDR	R5, [R4]					; read current value
	BIC	R5, #(0x03 << 22)			; clear bits 23:22
	ORR	R5, #(0x01 << 22)			; set bits 23:22 to 01
	STR	R5, [R4]					; write new value

	; Set edge-sensitive mode for EINT1
	LDR	R4, =EXTMODE
	LDR	R5, [R4]				
	ORR	R5, #1						
	STRB R5, [R4]			

	; Set rising-edge mode for EINT1
	LDR	R4, =EXTPOLAR
	LDR	R5, [R4]				
	BIC	R5, #1					
	STRB R5, [R4]			

	; Reset EINT1
	LDR	R4, =EXTINT
	MOV	R5, #1
	STRB	R5, [R4]
	
	
	
	;
	; Configure VIC for EINT1 interrupts
	;

	; Useful VIC vector numbers and masks for following code
	LDR	R4, =VICVectEINT1			; vector 15
	LDR	R5, =(1 << VICVectEINT1) 	; bit mask for vector 15

	; VICIntSelect - Clear bit 15 of VICIntSelect register to cause
	; channel 15 (EINT1) to raise IRQs (not FIQs)
	LDR	R6, =VICIntSelect			; addr = VICVectSelect;
	LDR	R7, [R6]					; tmp = Memory.Word(addr);
	BIC	R7, R7, R5					; Clear bit for Vector 15
	STR	R7, [R6]					; Memory.Word(addr) = tmp;

	; Set Priority for VIC channel 15 (EINT1) to lowest (15) by setting
	; VICVectPri4 to 15. Note: VICVectPri4 is the element at index 15 of an
	; array of 4-byte values that starts at VICVectPri0.
	; i.e. VICVectPri115=VICVectPri0+(15*4)
	LDR	R6, =VICVectPri0			; addr = VICVectPri0;
	MOV	R7, #15						; pri = 15;
	STR	R7, [R6, R4, LSL #2]		; Memory.Word(addr + vector * 4) = pri;

	; Set Handler routine address for VIC channel 15 (EINT1) to address of
	; our handler routine (ButtonHandler). Note: VICVectAddr15 is the element
	; at index 15 of an array of 4-byte values that starts at VICVectAddr0.
	; i.e. VICVectAddr15=VICVectAddr0+(15*4)
	LDR	R6, =VICVectAddr0			; addr = VICVectAddr0;
	LDR	R7, =Button2_Handler		; handler = address of ButtonHandler;
	STR	R7, [R6, R4, LSL #2]		; Memory.Word(addr + vector * 4) = handler

	; Enable VIC channel 15 (EINT0) by writing a 1 to bit 15 of VICIntEnable
	LDR	R6, =VICIntEnable			; addr = VICIntEnable;
	STR	R5, [R6]					; enable interrupts for vector 15
	
	
	
	; Start TIMER0 using the Timer Control Register
	; Set bit 0 of TCR (0xE0004004) to enable the timer
	LDR	R4, =T0TCR
	LDR	R5, =0x01
	STRB R5, [R4]

stop	B	stop


;
; TOP LEVEL EXCEPTION HANDLERS
;

;
; Software Interrupt Exception Handler
;
Undef_Handler
	B	Undef_Handler

;
; Software Interrupt Exception Handler
;
SWI_Handler
	B	SWI_Handler

;
; Prefetch Abort Exception Handler
;
PAbt_Handler
	B	PAbt_Handler

;
; Data Abort Exception Handler
;
DAbt_Handler
	B	DAbt_Handler

;
; Interrupt ReQuest (IRQ) Exception Handler (top level - all devices)
;
IRQ_Handler
	SUB	lr, lr, #4					; for IRQs, LR is always 4 more than the
									; real return address
	STMFD	sp!, {r0-r3,lr}			; save r0-r3 and lr

	LDR	r0, =VICVectAddr			; address of VIC Vector Address memory-
									; mapped register

	MOV	lr, pc						; raising the IRQ - we are manually BL - ing
	LDR	pc, [r0]	
					

	LDMFD	sp!, {r0-r3, pc}^ 		; restore r0-r3, lr and CPSR

;
; Fast Interrupt reQuest Exception Handler
;
FIQ_Handler
	B	FIQ_Handler


;
; write your interrupt handlers here
;


Button1_Handler

	STMFD	sp!, {r4-r6, lr}

	; Reset EINT0 interrupt by writing 1 to EXTINT register
	LDR	R4, =EXTINT
	MOV	R5, #0x3
	STRB R5, [R4]

	; Stop TIMER0 using Timer Control Register
	; Set bit 0 of TCR to 0 to stop TIMER
	LDR	R5, =T0TCR
	LDR	R6, =0x0
	STRB R6, [R5]
	
	; Start TIMER1 using the Timer Control Register
	; Set bit 0 of TCR (0xE0004004) to enable the timer
	LDR	R4, =T1TCR
	LDR	R5, =0x01
	STRB R5, [R4]

	;
	; Clear source of interrupt
	;
	LDR	R4, =VICVectAddr			; addr = VICVectAddr
	MOV	R5, #0						; tmp = 0
	STR	R5, [R4]					; Memory.Word(addr) = tmp
	

	LDMFD sp!, {r4-r6, pc}
	
Button2_Handler

	STMFD	sp!, {r4-r6, lr}

	; Reset EINT1 interrupt by writing 1 to EXTINT register
	LDR	R4, =EXTINT
	MOV	R5, #0x3
	STRB R5, [R4]

	; Stop TIMER1 using Timer Control Register
	; Set bit 0 of TCR to 0 to stop TIMER
	LDR	R5, =T1TCR
	LDR	R6, =0x0
	STRB R6, [R5]
	
	; Start TIMER0 using the Timer Control Register
	; Set bit 0 of TCR (0xE0004004) to enable the timer
	LDR	R4, =T0TCR
	LDR	R5, =0x01
	STRB R5, [R4]

	;
	; Clear source of interrupt
	;
	LDR	R4, =VICVectAddr			; addr = VICVectAddr
	MOV	R5, #0						; tmp = 0;
	STR	R5, [R4]					; Memory.Word(addr) = tmp;

	LDMFD sp!, {r4-r6, pc}
	
	
Timer0_Handler

	STMFD	sp!, {r4-r6, lr}

	; Reset TIMER0 interrupt by writing 0xFF to T0IR
	LDR	R4, =T0IR
	MOV	R5, #0xFF
	STRB R5, [R4]
	
	; Useful VIC vector mask for following code
	LDR	R4, =(1 << VICVectEINT0) 	; bit mask for vector 14	
	
	; Useful VIC vector mask for following code
	LDR	R5, =(1 << VICVectEINT1) 	; bit mask for vector 15
	
	; Setting bit which we are going to set to 1 to disable buttons
	ORR R6, R5, R4
	
	; VICIntEnClear - Clear bit 15 of VICIntSelect register to cause
	; channel 15 (EINT1) to stop raising interupts after time is over
	LDR	R4, =VICIntEnClear			; addr = VICVectSelect
	STR	R6, [R4]					; Memory.Word(addr) = tmp

	; Clear source of interrupt by writing 0 to VICVectAddr
	LDR	R4, =VICVectAddr
	MOV	R5, #0
	STR	R5, [R4]

	LDMFD sp!, {r4-r6, pc}
	
	
Timer1_Handler

	STMFD	sp!, {r4-r6, lr}

	; Reset TIMER0 interrupt by writing 0xFF to T0IR
	LDR	R4, =T0IR
	MOV	R5, #0xFF
	STRB R5, [R4]
	
	
	; Useful VIC vector mask for following code
	LDR	R4, =(1 << VICVectEINT0) 	; bit mask for vector 14	
	
	; Useful VIC vector mask for following code
	LDR	R5, =(1 << VICVectEINT1) 	; bit mask for vector 15
	
	; Setting bit which we are going to set to 1 to disable buttons
	ORR R6, R5, R4
	
	; VICIntEnClear - Clear bit 15 of VICIntSelect register to cause
	; channel 15 (EINT1) to stop raising interupts after time is over
	LDR	R4, =VICIntEnClear			; addr = VICVectSelect
	STR	R6, [R4]					; Memory.Word(addr) = tmp
	

	; Clear source of interrupt by writing 0 to VICVectAddr
	LDR	R4, =VICVectAddr
	MOV	R5, #0
	STR	R5, [R4]

	LDMFD sp!, {r4-r6, pc}

	END
