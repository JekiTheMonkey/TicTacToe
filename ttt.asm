%include "kernel.inc"
%include "pcall.inc"

global 		_start

section		.data
xsign			db		'x'
osign			db		'o'
bsign			db		'#'
space			db		' '
nw				db		10
player_turn		db		0
turn			db		1
turn_msg		db		"Turn player "
turn_msglen		equ		$-turn_msg
ask_input_msg	db		"Please enter your input: "
ask_input_msglen	equ	$-ask_input_msg
out_of_range_msg	db	"Out of range!", 10, 0
out_of_range_msglen	equ	$-out_of_range_msg
cell_occupied_msg	db	"Cell is already occupied!", 10, 0
cell_occupied_msglen	equ	$-out_of_range_msg
win_msg			db		"The winner is player ", 0
win_msglen		equ		$-win_msg
draw_msg		db		"Draw."
draw_msglen		equ		$-draw_msg

section		.bss
area			resb	9
buf				resb	1

section .text
;;
;; reset area
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
reset_area:
			push	ebp
			mov		ebp, esp

			mov		eax, area
			mov		ecx, 9
.lp:		mov		byte [eax], 0		; each element = 0
			inc		eax
			loop	.lp

			mov		esp, ebp
			pop		ebp
			ret

;;
;; print line
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
print_line:
			push	ebp
			push	ebx
			mov		ebp, esp

			mov		ebx, 5
.lp:		kernel	4, 1, bsign, 1
			dec		ebx
			jnz		.lp

			mov		esp, ebp
			pop		ebx
			pop		ebp
			ret

;;
;; print line with signs 
;; [ebp+8] is area line index
;; 0 = ' ', 1 = 'o', 2 = 'x'
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
print_ls:
			push	ebp
			mov		ebp, esp
			push	esi
			sub		esp, 4

			mov		eax, [ebp+8]
			mov		ecx, 3
			mul		ecx
			lea		esi, [area+eax]		; area address
			mov		dword [ebp-8], 5	; loop counter

.lp:		test	byte [ebp-8], 1		; counter % 2
			jnz		.if					;   != 0
			kernel	4, 1, bsign, 1		; print #
			jmp		.lp_r
.if:
			mov		al, [esi]			; read character

			cmp		al, 2
			jne		.not_x
			kernel	4, 1, xsign, 1		; print x
			jmp		.if_q
.not_x:		cmp		al, 1
			jne		.not_o
			kernel	4, 1, osign, 1		; print o
			jmp		.if_q
.not_o:		kernel	4, 1, space, 1		; print space
			jmp		.if_q

.if_q:		
			inc		esi					; increase address
.lp_r:		
			dec		dword [ebp-8]		; decrease counter			
			jnz		.lp

			pop		esi
			mov		esp, ebp
			pop		ebp
			ret

;;
;; print area
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
print_area:
			pcall 	print_ls, 0		; print v#v#v
			kernel	4, 1, nw, 1		; newline

			call	print_line		; print #####
			kernel	4, 1, nw, 1		; newline

			pcall 	print_ls, 1		; print v#v#v
			kernel	4, 1, nw, 1		; newline

			call	print_line		; print #####
			kernel	4, 1, nw, 1		; newline

			pcall 	print_ls, 2		; print v#v#v
			kernel	4, 1, nw, 1		; newline

			ret						; return

;;
;; get_input
;; returns result in al
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
get_input:
			push	ebp
			mov		ebp, esp
			push	ebx

			kernel	3, 0, buf, 1
			mov		bl, [buf]

.lp:		kernel	3, 0, buf, 1	; "stdin flush"
			cmp		eax, -1
			je		.quit
			cmp		byte [buf], 10
			je		.quit
			jmp		.lp

.quit:		mov		al, bl
			pop		ebx
			mov		esp, ebp
			pop		ebp
			ret

;;
;; check if there is a winner of a draw
;; return result in eax
;; 0 - game continues or draw
;; 1 - current player won
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
check_game_result:
			push	ebp
			mov		ebp, esp
			push	esi
			push	ebx
			sub		esp, 4

			mov		esi, area			; get base area address
			mov		bl, [player_turn]	; get player index
			inc		bl					; increase it to 1 or 2 depending on player

			; vertical checks
			mov		ecx, 3				; outer loop counter
.lp_v:		lea		eax, [esi+ecx-1]	; get offset address

			mov		edx, 3				; inner loop counter
.lpi_v:		cmp		[eax], bl			; compare cell contents with player index
			jne		.lp_v_r
			add		eax, 3				; add a step of 3
			dec		edx					; decrease inner counter
			jnz		.lpi_v

			mov		eax, 1				; there is a victory
			jmp		.quit

.lp_v_r:	loop	.lp_v


			; horizontal checks
			mov		ecx, 3				; outer loop counter
.lp_h:		
			mov		eax, ecx
			mov		byte [buf], 3
			mul		byte [buf]
			sub		eax, 3
			lea		eax, [esi+eax]		; get offset address

			mov		edx, 3				; inner loop counter
.lpi_h:		cmp		[eax], bl			; compare cell contents with player index
			jne		.lp_h_r
			inc		eax					; add a step of 1
			dec		edx					; decrease inner counter
			jnz		.lpi_h

			mov		eax, 1				; there is a victory
			jmp		.quit

.lp_h_r:	loop	.lp_h


			; cross checks
			mov		ecx, 2				; outer loop counter
.lp_c:
			mov		eax, 2				; compute step
			mul		ecx					;   2*ecx(2)=4, 2*ecx(1)=2
			mov		[ebp-12], eax		; [ebp-12] = step
			mov		eax, esi

			cmp		ecx, 2
			je		.lp_c_cont
			add		eax, 2
.lp_c_cont:
			mov		edx, 3				; inner loop counter
.lpi_c:		cmp		[eax], bl			; compare cell ocntents with player index
			jne		.lp_c_r
			add		eax, [ebp-12]		; add the steo
			dec		edx					; decrease inner counter
			jnz		.lpi_c

			mov		eax, 1				; there is a victory
			jmp		.quit

.lp_c_r:	loop	.lp_c

			xor		eax, eax			; 0 = game continues
.quit:		
			add		esp, 4				; pop [ebp-12]
			pop		ebx					; restore values
			pop		esi
			mov		esp, ebp
			pop		ebp
			ret

;;
;; main
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
section	.text
_start:		
			pcall	reset_area								; reset area
.lp:		pcall	print_area								; print area

			kernel	4, 1, nw, 1
			kernel	4, 1, turn_msg, turn_msglen				; output msg about player turn

			mov		eax, [player_turn]
			add		eax, '1'
			mov		[buf], eax
			kernel	4, 1, buf, 1
			kernel	4, 1, nw, 1
.input:		kernel	4, 1, ask_input_msg, ask_input_msglen	; ask for input
			pcall	get_input								; take input

			cmp		al, '1'				; control 
			jnae	.out_of_range		;   if
			cmp		al, '9'				;     it is
			jnbe	.out_of_range		; ------in range

			mov		cl, al				; transform ascii number
			sub		cl, '1'				; --into byte representation

			mov		edi, area			; find area
			add		edi, ecx			;   memory byte
			cmp		byte [edi], 0		; ----to work with
			jnz		.occupied			; check if it's about to override

			mov		al, [player_turn]	; player index
			inc		al					; --to sign number
			mov		[edi], al			; put player's sign on the cell
			jmp		.input_q

.out_of_range:		
			kernel	4, 1, nw, 1								; print error msg and ask for input
			kernel	4, 1, out_of_range_msg, out_of_range_msglen
			jmp		.input
.occupied:	
			kernel	4, 1, nw, 1								; print error msg and ask for input
			kernel	4, 1, cell_occupied_msg, cell_occupied_msglen
			jmp		.input
.input_q:	

			pcall	check_game_result	; otherwise check if there is a winner
			cmp		eax, 1				; victory
			je		.victory			; jump on victory
			cmp		byte [turn], 9		; is draw?
			jne		.continue			; if not - continue
			jmp		.draw				; otherwise jump on draw


.continue:	xor		byte [player_turn], 1	; swap player turns
			inc		byte [turn]
			jmp		.lp
.victory:	
			kernel	4, 1, nw, 1
			pcall	print_area
			kernel	4, 1, win_msg, win_msglen				; print winner msg
			mov		eax, [player_turn]						; find current player index
			inc		eax
			add		eax, '0'
			mov		[buf], eax
			kernel	4, 1, buf, 1							; print the winner index
			kernel	4, 1, nw, 1
			jmp		.quit

.draw:
			kernel	4, 1, draw_msg, draw_msglen				; print draw msg
			kernel	4, 1, nw, 1
.quit:
			kernel	1, 0									; exit
