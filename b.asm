BITS 32
  
     ; B0 40 corresponds to mov al, 4. Org is chosen to include this
     ; default value here would be 0x08048000, but anything in bottom half 
     ; is valid (0x0~0x80000000) top half is heap, stack, etc.         
                org     0x04b00000 
  
  ehdr:                                                 ; Elf32 header
                db      0x7F, "ELF", 1, 1, 1, 0         ;   e_ident
        times 8 db	0
	        
                dw      2                  ;   e_type
                dw      3                  ;   e_machine
                dd      1                  ;   e_version
                dd      _start             ;   e_entry
                dd      phdr - $$          ;   e_phoff
	        dd      0                  ;   e_shoff
                dd      0                  ;   e_flags
                dw      ehdrsize           ;   e_ehsize
                dw      phdrsize           ;   e_phentsize

  ;  end of elf header and start of program header are identical
  ;  note: this is only the case for little endian encoding
   phdr:                                  ;---o  ; ELF32 program header
                dw      1                 ; | v  ;  e_phnum,     ptype LWord
                dw      0                 ; | e  ;  e_shentsize, ptype HWord
                dw      0	          ; | r  ;  e_shnum,     p_offset LWord
 		dw	0	     	  ; | l  ;  e_shstrndx,  p_offset HWord
   ehdrsize     equ     $ - ehdr          ; | a  ;  size = here - ehdr
                                          ;---p

	;  dd	$$		   ;   p_vaddr
        ;      =
        ;  dd   0x04B00000  ; (org)        
             ; thanks to org, this is equivalent:
 		dw	0	   ; p_vaddr LWord	              
_start:         mov	al,4	   ; System call Nr.4 = sys_write 
 
  ; physical address paddr is ignored and its contents are unspecified
  ; these 4 bytes can be used to execute 2 bytes of instructions and 
  ; 1 four byte jmp
		xor     ebx,ebx    ;   (paddr)
		jmp short cont	   ;   (paddr)

		dd	filesize	   ;   p_filesz
                dd      filesize           ;   p_memsz
  ; since we are writing to memory in an xor below (xor [ecx],al)
  ; the program memory needs to be writable. Normally the code 
  ; would be read+executable and data memory read+writable
  ; This would require two program table entries
  ; r__ = 4 (100), r_x = 5 (101), rwx = 7 (111)  
                dd      7                  ;   p_flags (rwx)
                dd      0x1000             ;   p_align
  
  phdrsize      equ     $ - phdr

 cont:
 
        	mov	dl,len
  		inc     ebx     	; 1st parameter, stdout = 1
		mov	ecx,msg		; 2nd parameter,
                        	; eax = 4, edx = 2 done in elf header above 

   ; the value to be printed is "encrypted" with our secret key, 
   ; which happens to be the value of al
		xor	[ecx],al
		int	0x80	       	; System call!
					; sys_write, eax = 0x04
					; parameter ebx = file descriptor
					; parameter ecx = buffer pointer
					; parameter edx = length 

		xor     eax,eax		; eax = 1 in two steps: eax = 0
		xchg	eax, ebx        ; after: ebx = 0, eax =1
		int	0x80		; System call!!
					; sys_exit, eax = 0x01 
					; parameter ebx = exit code


msg     db      'ƿ',0x0A        ; "upside down questionmark XORed with al = 4"
			        ;  0x0A LF (line feed)
len	equ	$ - msg 	; (n Bytes)
filesize	equ 	$ - $$
