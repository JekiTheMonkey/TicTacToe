%macro kernel 1-*
  %if %0 > 1
			push	ebx					; save values
    %if %0 > 4
			push	esi
			push	edi
			push	ebp
    %endif
  %endif

  %rep %0
    %rotate -1
			push	dword %1			; push all the passed values on stack
  %endrep

			pop	eax						; pop all passed values in corresponding registers
  %if %0 > 1
			pop	ebx
    %if %0 > 2
			pop	ecx
      %if %0 > 3
			pop	edx
      	%if %0 > 4
			pop	%esi
          %if %0 > 5
			pop	%edi
            %if %0 > 6
			pop	%ebp
              %if %0 > 7
                %error "Linux cannot handle syscalls with more than 6 parameters"
              %endif
            %endif
          %endif
        %endif
      %endif
    %endif
  %endif

			int	0x80					; syscall
			mov	ecx, eax				; ecx = error code
			and	ecx, 0xfffff000			; check if there
			cmp	ecx, 0xfffff000			;   was any error
			jne %%ok					; exit if not
  			mov	ecx, eax				; otherwise save it
			neg	ecx						;   in ecx
			mov	eax, -1					; clean up eax
			jmp	short %%q				; exit
  %%ok:		xor	ecx, ecx				; clean up ecx
  %%q:

  %if %0 > 1
    %if %0 > 4
			pop	ebp						; restore values
			pop	edi
			pop	esi
    %endif
			pop	ebx
  %endif
%endmacro
