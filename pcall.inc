%macro pcall 1-*
  %rep %0 - 1
    %rotate -1
			push	dword %1			; push all the arguments in the stack
  %endrep
  %rotate -1
			call	%1					; call function
			add		esp, (%0 - 1) * 4	; make the stack be as before
%endmacro
