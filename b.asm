BITS 32
  
     ; B0 40 corresponds to mov al, 4. Org is chosen to embed this instruction
     ; in the programm memory address
     ; the default value here would be 0x08048000, but anything in bottom half 
     ; is valid (0x0~0x80000000) top half is heap, stack, etc.         
                org     0x04b00000 
  
  ehdr:                                                 ; Elf32 header     	**	Bytes |	Total Bytes
                db      0x7F, "ELF", 1, 1, 1, 0         ;   e_ident         	**	8  	8

     ; 8 bytes of padding in header ident. Reserved for future use.
     ; Currently ignored by linux. We can store code here
     ;   times 8 db	0
		db	0		;					**	1	9
_start:		mov	ecx, msg	;					**    	5	14
		jmp short cont1		;					**	2	16
     	        
                dw      2		;   e_type				**	2	18
                dw      3		;   e_machine				**	2	20
                dd      1		;   e_version				**	4	24
                dd      _start		;   e_entry				**	4	28
                dd      phdr - $$	;   e_phoff				**	4	32
	        dd      0		;   e_shoff				**	4	36
                dd      0		;   e_flags				**	4	40
                dw      ehdrsize	;   e_ehsize				**	2	42
                dw      phdrsize	;   e_phentsize				**	2	44

  ;  end of elf header and start of program header are identical
  ;  note: this is only the case for little endian encoding
   phdr:                                  ;---o  ; ELF32 program header
                dw      1                 ; | v  ;  e_phnum,     ptype LWord	**	2	46
                dw      0                 ; | e  ;  e_shentsize, ptype HWord	**	2	48
                dw      0	          ; | r  ;  e_shnum,     p_offset LWord	**	2	50
 		dw	0	     	  ; | l  ;  e_shstrndx,  p_offset HWord	**	2	52
   ehdrsize     equ     $ - ehdr          ; | a  ;  size = here - ehdr
                                          ;---p

	;  dd	$$		   ;   p_vaddr
        ;      =
        ;  dd   0x04B00000  ; (org)        
             ; thanks to org, this is equivalent:
 		dw	0	   ; p_vaddr LWord				**	2	54              
 cont1:         mov	al,4	   ; System call Nr.4 = sys_write 		**	2	56
 
  ; physical address paddr is ignored and its contents are unspecified
  ; these 4 bytes can be used to execute 2 bytes of instructions and 
  ; 1 four byte jmp
        	mov	dl,len		;   (paddr)				**	2	58	
		jmp short cont2	   	;   (paddr)				**	2	60

		dd	filesize	;   p_filesz				**	4	64
                dd      filesize	;   p_memsz				**	4	68
  ; since we are writing to memory in an xor below (xor [ecx],al)
  ; the program memory needs to be writable. Normally the code 
  ; would be read+executable and data memory read+writable
  ; This would require two program table entries
  ; r__ = 4 (100), r_x = 5 (101), rwx = 7 (111)  
                dd      7		;   p_flags (rwx)			**	4	72
                dd      0x1000		;   p_align				**	4	76
  
  phdrsize      equ     $ - phdr

 cont2:
		xor     ebx,ebx		; 					**	2	78
  		inc     ebx		; 1st parameter, stdout = 1		**	1	79
                        		; eax = 4, edx = 2 done in elf header above 

   ; the value to be printed is "encrypted" with our secret key, 
   ; which happens to be the value of al
		xor	[ecx],al	;					**	2	81
		int	0x80	       	; System call!				**	2	83
					; sys_write, eax = 0x04
					; parameter ebx = file descriptor
					; parameter ecx = buffer pointer
					; parameter edx = length 

		xor     eax,eax		; eax = 1 in two steps: eax = 0		**	2	85
		xchg	eax, ebx        ; after: ebx = 0, eax =1		**	1	86
		int	0x80		; System call!!				**	2	88
					; sys_exit, eax = 0x01 
					; parameter ebx = exit code

msg     db      'ƿ',0x0A        ; "upside down questionmark XORed with al = 4"	**	3	91
;  = 	db 0xc6, 0xbf, 0x0a	;  0x0A LF (line feed)
len	equ	$ - msg 	; (n Bytes)
filesize	equ 	$ - $$
