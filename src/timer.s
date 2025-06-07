		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Timer Definition
STCTRL		EQU		0xE000E010		; SysTick Control and Status Register
STRELOAD	EQU		0xE000E014		; SysTick Reload Value Register
STCURRENT	EQU		0xE000E018		; SysTick Current Value Register
	
STCTRL_STOP	EQU		0x00000004		; Bit 2 (CLK_SRC) = 1, Bit 1 (INT_EN) = 0, Bit 0 (ENABLE) = 0
STCTRL_GO	EQU		0x00000007		; Bit 2 (CLK_SRC) = 1, Bit 1 (INT_EN) = 1, Bit 0 (ENABLE) = 1
STRELOAD_MX	EQU		0x00FFFFFF		; MAX Value = 1/16MHz * 16M = 1 second
STCURR_CLR	EQU		0x00000000		; Clear STCURRENT and STCTRL.COUNT	
SIGALRM		EQU		14			; sig alarm

; System Variables
SECOND_LEFT	EQU		0x20007B80		; Secounds left for alarm( )
USR_HANDLER     EQU		0x20007B84		; Address of a user-given signal handler function	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer initialization
; void timer_init( )
		EXPORT		_timer_init
_timer_init
	;; Implement by yourself
	;Stop SysTick
        LDR     R0, =STCTRL         ; SysTick Control Register
        LDR     R1, =STCTRL_STOP    ; Bit 2 (CLK_SRC) = 1, Bit 1 (INT_EN) = 0, Bit 0 (ENABLE) = 0
        STR     R1, [R0]

	; Load maximum value to SYST_RVR (Reload Register)
		LDR     R0, =STRELOAD
		LDR		R1, =STRELOAD_MX 	
		STR     R1, [R0]

		MOV		pc, lr		; return to Reset_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer start
; int timer_start( int seconds )
		EXPORT		_timer_start
_timer_start
	;; Implement by yourself
		;(1) Retrieve the seconds parameter from memory address 0x20007B80
		LDR     R1, =SECOND_LEFT
		LDR     R2, [R1] ; R2 = previous seconds value

		;(2) Save a new seconds parameter from alarm( ) to memory address 0x20007B80.
		STR R0, [R1] ; R0 = int seconds put into R1

		;(3) Enable SysTick: Set SYST_CSR’s Bit 2 (CLK_SRC) = 1, Bit 1 (INT_EN) = 1, Bit 0 (ENABLE) = 1
		LDR     R4, =STCTRL  
    	LDR     R3, =STCTRL_GO  
    	STR     R3, [R4]

		;(4) Clear SYST_CVR: Set 0x00000000 in SYST_CVR
		LDR 	R4, =STCURRENT
		LDR 	R3, =STCURR_CLR
		STR 	R3, [R4]

		; Return previous time value to main( ) through R0
		MOV R0, R2

		MOV		pc, lr		; return to SVC_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer update
; void timer_update( )
		EXPORT		_timer_update
_timer_update
	; Read the value at address 0x20007B80
	LDR     R1, =SECOND_LEFT
	LDR     R2, [R1] ; R2 = seconds value
	; Decrement value by 1
	SUB     R2, R2, #1
	; Store new count 
	STR R2, [R1]
	; Branch to _timer_update_done if value isnt Zero
	CMP R2, #0
	BNE		_timer_update_done

	; Stop Timer
        LDR     R4, =STCTRL
        LDR     R3, =STCTRL_STOP
        STR     R3, [R4]

		PUSH {lr} ; Save return address
		
	;Invoke user function whose address is maintained in 0x20007B84
		LDR     R5, =USR_HANDLER   ; Address holding function pointer
        LDR     R5, [R5]     
        BLX     R5 ; Call function

        ; Restore original return address
        POP     {lr}
		
_timer_update_done
		MOV R0, R2
		MOV		pc, lr		; return to SysTick_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer update
; void* signal_handler( int signum, void* handler )
	    EXPORT	_signal_handler
_signal_handler
		; Load previous function
		LDR     R2, =USR_HANDLER
		LDR     R3, [R2]
	    ; Check if sig == SIGALRM (14)
        CMP     R0, #SIGALRM
        BNE     _signal_handler_done     ; If not valid, return

		STR     R1, [R2] ; Load new function in handler


_signal_handler_done
		; Return previous handler in R0
		MOV		R0, R3

		MOV		pc, lr		; return to Reset_Handler
		
		END		
