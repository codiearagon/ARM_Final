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
		BLT _kfree_null 
		CMP R0, R2
		BGT _kfree_null
		
		; get mcb addr
		; mcb_addr = mcb_top + (addr - heap_top) / 16
		LDR R1, =MCB_TOP
		LDR R2, =HEAP_TOP
		SUB R3, R0, R2 ; addr - heap top
		MOV R3, R3, ASR #4 ; / 16
		ADD R1, R1, R3 ; mcb_top +
		
		BL _rfree
		CMP R11, #0
		BNE _kfree_done
		
_kfree_null
		MOV R11, #-1 ; return null if r0 == 0
		
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
		MOV R11, R7 ; mov heap_addr to r11 (my return addr)
		MOV pc, lr

;----ralloc-region-end----

;----rfree-region-start----

_rfree
		; R1 has mcb_addr
		PUSH {LR}
		LDR R2, =MCB_TOP
		
		; mcb_contents
		LDR R3, [R1]
		
		; mcb_offset
		SUB R4, R1, R2
		
		; mcb_chunk
		MOV R5, R3, ASR #4
		MOV R3, R5 ; also set mcb_contents
		
		; my_size, clear used bit
		MOV R6, R3, LSL #4
		MOV R3, R6 ; also set mcb_contents
				
		; set mcb_addr's clear bit
		STR R3, [R1]
		
		; check if left or right
		SDIV R7, R4, R5
		AND R7, R7, #1 ; % 2
		CMP R7, #0
		BEQ _rfree_left
		B _rfree_right
	
_rfree_left
		LDR R7, =MCB_BOT
		ADD R8, R1, R5
		CMP R8, R7
		BGE _rfree_invalid ; buddy is beyond mcb_bot
		
		ADD R7, R1, R5
		
		; mcb_buddy
		LDR R7, [R7]
		
		AND R8, R7, #1
		CMP R8, #0 ; cmp buddy if being used
		BNE _rfree_done ; buddy is used
		
		; buddy is not used 
		MOV R7, R7, ASR #5
		MOV R7, R7, LSL #5 ; clear bits 4-0
		
		CMP R7, R6 ; cmp buddy size to my size
		BNE _rfree_done
		
		; buddy is not used AND has same size
		ADD R8, R1, R5
		MOV R9, #0
		STR R9, [R8] ; clear buddy
		LSL R6, R6, #1 ; multiple my size to 2
		STR R6, [R1] ; merge buddy
		
		BL _rfree
		B  _rfree_done

_rfree_right
		LDR R7, =MCB_TOP
		SUB R8, R1, R5
		CMP R8, R7
		BLT _rfree_invalid ; buddy is beyond mcb_bot
		
		SUB R7, R1, R5
		
		; mcb_buddy
		LDR R7, [R7]
		
		AND R8, R7, #1
		CMP R8, #0 ; cmp buddy if being used
		BNE _rfree_done ; buddy is used
		
		; buddy is not used 
		MOV R7, R7, ASR #5
		MOV R7, R7, LSL #5 ; clear bits 4-0
		
		CMP R7, R6 ; cmp buddy size to my size
		BNE _rfree_done
		
		; buddy is not used AND has same size
		MOV R9, #0
		STR R9, [R1] ; clear myself
		LSL R6, R6, #1 ; multiple my size to 2
		SUB R8, R1, R5
		STR R6, [R8] ; merge myself to buddy
		
		SUB R1, R1, R5
		
		BL _rfree
		B _rfree_done
		
_rfree_invalid
		MOV R1, #0

_rfree_done
		POP {LR}
		MOV R11, R1 ; return mcb_addr
		MOV pc, lr
		
		END
		
		
		
		
		
