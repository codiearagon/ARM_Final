		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table
SYSTEMCALLTBL	EQU		0x20007B00 ; originally 0x20007500
SYS_EXIT		EQU		0x0		; address 20007B00
SYS_ALARM		EQU		0x1		; address 20007B04
SYS_SIGNAL		EQU		0x2		; address 20007B08
SYS_MALLOC		EQU		0x3		; address 20007B0C
SYS_FREE		EQU		0x4		; address 20007B10

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table Initialization
		EXPORT	_syscall_table_init
_syscall_table_init
		IMPORT _kfree
		IMPORT _kalloc
		IMPORT _signal_handler
		IMPORT _timer_start
			
		LDR R0, =SYSTEMCALLTBL
		LDR R1, =_timer_start
		LDR R2, =_signal_handler
		LDR R3, =_kalloc
		LDR R4, =_kfree
		
		; map the syscalltbl addresses to the function addresses
		STR R1, [R0, #4]
		STR R2, [R0, #8]
		STR R3, [R0, #12]
		STR R4, [R0, #16]
	
		MOV		pc, lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table Jump Routine
        EXPORT	_syscall_table_jump
_syscall_table_jump
		PUSH {LR}
		
		; don't use R0, R1, or R7 
		LDR R2, =SYSTEMCALLTBL
		
		; Set R0 to addr of function based on R7
		ADD R2, R2, R7, LSL #2
		LDR R3, [R2]
		
		; branch to function addr
		BLX R3
		
		POP 	{LR}
		MOV		pc, lr			
		
		END


		
