		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table
HEAP_TOP	EQU		0x20001000
HEAP_BOT	EQU		0x20004FE0
MAX_SIZE	EQU		0x00004000		; 16KB = 2^14
MIN_SIZE	EQU		0x00000020		; 32B  = 2^5
	
MCB_TOP		EQU		0x20006800      	; 2^10B = 1K Space
MCB_BOT		EQU		0x20006BFE
MCB_ENT_SZ	EQU		0x00000002		; 2B per entry
MCB_TOTAL	EQU		512			; 2^9 = 512 entries
	
INVALID		EQU		-1			; an invalid id
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Memory Control Block Initialization
		EXPORT	_heap_init
_heap_init
		; initialize MCB to 0
		LDR		R0, =MCB_TOP
		LDR		R1, =MCB_BOT
		LDR		R2, =MCB_ENT_SZ
		LDR		R3, =MCB_TOTAL
		MOV		R4, #0
		
		; store 0x4000 to mcb[0]
		MOV		R5, #0x4000
		STR		R5, [R0]
		ADD		R0, R0, R2
		
		; begin loop at mcb[1]
_heap_init_loop
		CMP 	R0, R1
		BEQ 	_heap_init_done
		STR 	R4, [R0] ; init mcb addr to 0
		ADD 	R0, R0, R2 ; add entry size to current addr
		B 		_heap_init_loop
_heap_init_done
		MOV		pc, lr
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory Allocation
; void* _k_alloc( int size )
		EXPORT	_kalloc
_kalloc
	;; Implement by yourself
		PUSH 	{LR}
		
		; set size to minimum size if less than minimum size
		LDR		R1, =MIN_SIZE
		CMP		R0, R1
		BGE		_kalloc_min_size_met
		MOV		R0, R1

_kalloc_min_size_met
		LDR		R1, =MCB_TOP
		LDR		R2, =MCB_BOT
		LDR 	R3, =MCB_TOTAL
		BL		_ralloc
		POP 	{LR}
		MOV		pc, lr
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory De-allocation
; void free( void *ptr )
		EXPORT	_kfree
_kfree
	;; Implement by yourself
		MOV		pc, lr					; return from rfree( )
		
		
_ralloc
		; R0 contains memory size, R1 has MCB_TOP, R2 has MCB_BOT
		PUSH {LR}
		
		LDR R4, [R1] 					; R3 contains mcb[0]
		MOV R3, R3, ASR #1 				; half R3
		SUB R2, R2, R4			; half total size and put as right half
		
		BL _ralloc
		
		
		
		
		POP {LR}
		MOV pc, lr
		
		END
		
		
		
		
		
