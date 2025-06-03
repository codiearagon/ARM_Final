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
		BL		_ralloc
		POP 	{LR}
		MOV		pc, lr
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory De-allocation
; void free( void *ptr )
		EXPORT	_kfree
_kfree
		;; Implement by yourself
		PUSH {LR}
		
		; check if ptr addr is within heap addr
		LDR R1, =HEAP_TOP
		LDR R2, =HEAP_BOT
		CMP R0, R1
		BLT _kfree_done 
		CMP R0, R2
		BGT _kfree_done
		
		; get mcb addr
		; mcb_addr = mcb_top + (addr - heap_top) / 16
		LDR R1, =MCB_TOP
		LDR R2, =HEAP_TOP
		SUB R3, R0, R2
		MOV R3, R3, ASR #4
		ADD R1, R1, R3 
		
		BL _rfree
		
_kfree_done
		POP {LR}
		MOV	pc, lr					; return from rfree( )


;----ralloc-region-start----
		
_ralloc
		; R0 contains memory size, R1 has MCB_TOP, R2 has MCB_BOT
		PUSH {LR}
		LDR R3, =MCB_ENT_SZ
		
		; entire = right - left + entry size
		SUB R4, R2, R1 					
		ADD R4, R4, R3				
		
		; half of entire
		MOV R5, R4, ASR #1
		
		; midpoint
		ADD R6, R1, R5
		
		; heap_addr
		MOV R7, #-1
		
		; actual entire size
		MOV R8, R4, LSL #4
		
		; actual half size
		MOV R9, R5, LSL #4
		
		CMP R0, R9 ; compare malloc size to half size
		BLE _ralloc_left
		B _ralloc_found_chunk
		
_ralloc_left
		STMDB SP!, {R1-R6, R8-R9}
		SUB R2, R6, R3 ; midpoint - mcb_ent_sz as new left end point
		BL _ralloc
		LDMIA SP!, {R1-R6, R8-R9}
		
		CMP R7, #-1
		BEQ _ralloc_right
		B _ralloc_split_mcb
		
_ralloc_right
		STMDB SP!, {R1-R6, R8-R9}
		MOV R1, R6 ; midpoint as right start point
		BL _ralloc
		LDMIA SP!, {R1-R6, R8-R9}
		B _ralloc_done ; return

_ralloc_split_mcb
		LDR R10, [R6] ; load midpoint
		AND R10, R10, #0x01
		CMP R10, #0
		BEQ	_ralloc_split_mcb_set
		B 	_ralloc_done ; return
		
_ralloc_split_mcb_set
		STR	R9, [R6]
		B	_ralloc_done ; return
		
_ralloc_found_chunk
		LDR R10, [R1] ; load left address size
		AND R10, R10, #0x01
		CMP R10, #0
		BNE _ralloc_done ; return
		
		LDR R10, [R1]
		CMP R10, R8 ; compare chunk size to actual entire size
		BLT _ralloc_done ; return
		
		; if passed all checks, set mcb entry lsb to 1
		ORR	R11, R8, #0x01
		STR R11, [R1]
		
		; set heap addr
		LDR R7, =HEAP_TOP
		LDR R11, =MCB_TOP
		SUB	R10, R1, R11 ; left - MCB_TOP
		MOV R10, R10, LSL #4 ; * 16
		ADD R7, R7, R10 ; HEAP_TOP + (left - MCB_TOP)
		
_ralloc_done
		POP {LR}
		MOV R12, R7 ; mov heap_addr to return register
		MOV pc, lr

;----ralloc-region-end----

;----rfree-region-start----

_rfree
		PUSH {LR}
		LDR R1, =MCB_TOP
		
_rfree_done
		POP {LR}
		MOV pc, lr
		END
		
		
		
		
		
