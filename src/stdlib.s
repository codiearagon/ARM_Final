		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void _bzero( void *s, int n )
; Parameters
;	s 		- pointer to the memory location to zero-initialize
;	n		- a number of bytes to zero-initialize
; Return value
;   none
		EXPORT	_bzero
_bzero
    PUSH    {R2, lr}           ; Save r2 and return address
    CMP     R1, #0             ; If n == 0, return
    BEQ     bzero_done

bzero_loop
    MOV     R2, #0             ; Clear byte
    STRB    R2, [R0], #1       ; Store byte and increment r0
    SUBS    R1, R1, #1         ; Decrement count
    BNE     bzero_loop         ; Continue if not done

bzero_done
    POP     {R2, pc}           ; Restore r2 and return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; char* _strncpy( char* dest, char* src, int size )
; Parameters
;   	dest 	- pointer to the buffer to copy to
;	src	- pointer to the zero-terminated string to copy from
;	size	- a total of n bytes
; Return value
;   dest
		EXPORT	_strncpy
_strncpy
    PUSH    {R3-R5, lr}        ; Save used registers and return addr
    MOV     R3, R0             ; Save dst to return later
    CMP     R2, #0             ; If len == 0, skip loop
    BEQ     strncpy_done

strncpy_loop
    LDRB    R4, [R1], #1       ; Load byte from src and post-increment
    STRB    R4, [R0], #1       ; Store to dst and post-increment
    SUBS    R2, R2, #1         ; Decrement len
    CMP     R4, #0             ; Check if null terminator
    BEQ     pad_nulls
    CMP     R2, #0             ; If len == 0, exit
    BNE     strncpy_loop
    B       strncpy_done

pad_nulls
    ; R2 still holds how many bytes are left to pad
pad_loop
    CMP     R2, #0
    BEQ     strncpy_done
    MOV     R5, #0
    STRB    R5, [R0], #1
    SUBS    R2, R2, #1
    B       pad_loop

strncpy_done
    MOV     R0, R3             ; Return original dst
    POP     {R3-R5, pc}
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void* _malloc( int size )
; Parameters
;	size	- #bytes to allocate
; Return value
;   	void*	a pointer to the allocated space
		EXPORT	_malloc
_malloc
			; save registers
			STMDB SP!, {LR, R0-R10, R12}
			
			; set the system call # to R7
			MOV		R7, #0x3
			SVC     #0x3
			
			; resume registers
			LDMIA SP!, {LR, R0-R10, R12}
			
			; MOV R11 to R0, [Codie] I'm personally using R11 as my return, but ARM uses R0 for return
			MOV R0, R11
			
			MOV		pc, lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void _free( void* addr )
; Parameters
;	size	- the address of a space to deallocate
; Return value
;   	none
		EXPORT	_free
_free
			; save registers
			STMDB SP!, {LR, R0-R10, R12}
			
			; set the system call # to R7
			MOV		R7, #0x4
			SVC     #0x4
			
			; resume registers
			LDMIA SP!, {LR, R0-R10, R12}
			
			; MOV R11 to R0, [Codie] I'm personally using R11 as my return, but ARM uses R0 for return
			MOV R0, R11
			
			MOV		pc, lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; unsigned int _alarm( unsigned int seconds )
; Parameters
;   seconds - seconds when a SIGALRM signal should be delivered to the calling program	
; Return value
;   unsigned int - the number of seconds remaining until any previously scheduled alarm
;                  was due to be delivered, or zero if there was no previously schedul-
;                  ed alarm. 
		EXPORT	_alarm
_alarm
		; save registers
		; set the system call # to R7
        	SVC     #0x0
		; resume registers	
		MOV		pc, lr		
			
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void* _signal( int signum, void *handler )
; Parameters
;   signum - a signal number (assumed to be 14 = SIGALRM)
;   handler - a pointer to a user-level signal handling function
; Return value
;   void*   - a pointer to the user-level signal handling function previously handled
;             (the same as the 2nd parameter in this project)
		EXPORT	_signal
_signal
		; save registers
		; set the system call # to R7
        	SVC     #0x0
		; resume registers
		MOV		pc, lr	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		END			
