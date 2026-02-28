default	rel
section	.data
fuck	db	"0x"
buf	times	0x10	db	"0"
hvals	dq  0x3736353433323130,0x4645444342413938
nl	db	0xA
start_heap_ptr	dq	0x0
end_heap_ptr	dq	0x0

section	.bss
start_bss:	resb	4096	; allocate 4KB on the bss segment for some reason;
end_bss:				; used to print the end of the bss segment (the start of the new heap segment)

section	.text
global	_start

; rdi is number of bytes to be allocated
; variables:
;	rbp-0x8: quadword storing the size needed for the allocation
;	rbp-0x10: quadword storing the address of the possibly available block of memory for allocation
_alloc_mem:
;	creating a new stack frame for variables (bc syscalls clobber registers)
	push	rbp
	mov	rbp,	rsp
	sub	rsp,	0x10	; whatever number of bytes is needed for this function
;	calculate the number of bytes to allocate (aligned to 8 bytes)
	add	rdi,	0x10	; 2 more quadwords are needed for flags and size checking
	mov	rax,	0xFFFFFFFFFFFFFFF8
	and	rax,	rdi
	cmp	rax,	rdi
	je	_alloc_mem.J0
	add	rax,	0x8
	mov	rdi,	rax
_alloc_mem.J0:
	mov	qword	[rbp-0x8],	rdi
;	scan through the heap segment
	mov	rax,	qword	[start_heap_ptr]
	mov	rbx,	rax
	mov	qword	[rbp-0x10],	rbx
_alloc_mem.J1:
	cmp	rbx,	qword	[end_heap_ptr]	; check if the program break has been reached
	jae	_alloc_mem.J3
	cmp	qword	[rbx],	0	; check if the memory block is free (full zeros means free block)
	jne	_alloc_mem.J2
	add	rdx,	qword	[rbx+0x8]
	cmp	rdx,	qword	[rbp-0x8]
	jbe	_alloc_mem.J4
	add	rbx,	qword	[rbx+0x8]
	jmp	_alloc_mem.J1
_alloc_mem.J2:
	add	rbx,	qword	[rbx+0x8]
	mov	qword	[rbp-0x10],	rbx
	xor	rdx,	rdx
	jmp	_alloc_mem.J1
_alloc_mem.J3:
	; extend the program break according to [rbp-0x8] and rdx
	mov	rdi,	qword	[rbp-0x8]
	sub	rdi,	rdx
	add	rdi,	qword	[end_heap_ptr]
	mov	rax,	0xC
	syscall
	mov	qword	[end_heap_ptr],	rax
_alloc_mem.J4:
;	allocate the memory
	mov	rax,	qword	[rbp-0x10]
	mov	rdi,	qword	[rbp-0x8]
	mov	qword	[rax],	0x1
	mov	qword	[rax+0x8],	rdi
	sub	rdx,	rdi
	cmp	rdx,	0x10
	jb	_alloc_mem.J5
	add	rax,	rdi
	mov	qword	[rax],	0x0
	mov	qword	[rax+0x8],	rdx
	jmp	_alloc_mem.J6	
_alloc_mem.J5:
	add	qword	[rax+0x8],	rdx
_alloc_mem.J6:
	mov	rax,	qword	[rbp-0x10]
	add	rax,	0x10
;	restore the stack to its state when the function was called
	mov	rsp,	rbp
	pop	rbp
	ret

; rdi is a pointer to the memory to be freed
_free_mem:
	xor	rax,	rax
	mov	qword	[rdi-0x10],	rax
	ret

_newline:
	mov	rax,	0x1
	xor	rdi,	rdi
	lea	rsi,	[nl]
	mov	rdx,	0x1
	syscall
	ret

_printhex:
    	mov rbx,    	15
    	printhexL1:
    	mov dl, sil
    	shl rdx,    	60	; get rid of extra half byte
    	shr rdx,    	60
	mov dil,   	 byte	[hvals+rdx]
	mov byte    	[buf+rbx],	dil
	dec rbx
	shr rsi,    	4
	cmp rbx,    	0
	jne printhexL1
	mov dil,    	byte	[hvals+rsi]
	mov byte    	[buf+rbx],	dil
	mov rsi,    	fuck
	mov rdx,    	18
	xor rdi,    	rdi
	mov rax,    	0x1
	syscall
	ret

_start:
;	before anything, make sure the heap starting addresss and the current system break is set and aligned to 8 bytes
	mov	rax,	0xFFFFFFFFFFFFFFF8
	and	rax,	end_bss
	cmp	rax,	end_bss
	je	_start.J0
	add	rax,	0x8
_start.J0:
	mov	rbp,	rsp
	sub	rsp,	0x18
	mov	qword	[start_heap_ptr],	rax
;	align the program break to an 8 byte boundary
	mov	rax,	0xC
	mov	rdi,	0
	syscall
	mov	rdi,	0xFFFFFFFFFFFFFFF8
	and	rdi,	rax
	mov	rax,	0xC
	syscall
	mov	qword	[end_heap_ptr],	rax
	mov	rbx,	qword	[start_heap_ptr]
	sub	rax,	rbx
	mov	qword	[rbx+0x8],	rax
	xor	rax,	rax
	xor	rbx,	rbx
;	actual program stuff
	mov	rdi,	0x20
	call	_alloc_mem
	;mov	rsi,	rax
	lea	rsi,	[rax-0x10]
	mov	qword	[rbp-0x8],	rax
	call	_printhex
	call	_newline
	mov	rdi,	0x10
	call	_alloc_mem
	;mov	rsi,	rax
	lea	rsi,	[rax-0x10]
	call	_printhex
	call	_newline
	mov	rdi,	qword	[rbp-0x8]
	call	_free_mem
	mov	rdi,	0x10
	call	_alloc_mem
	;mov	rsi,	rax
	lea	rsi,	[rax-0x10]
	call	_printhex
	call	_newline
	mov	rsi,	qword	[rbp-0x8]
	mov	rsi,	qword	[rsi-0x10]
	call	_printhex
	call	_newline
	mov	rsi,	qword	[rbp-0x8]
	mov	rsi,	qword	[rsi-0x8]
	call	_printhex
	call	_newline
;	reset stack and exit program
	mov	rsp,	rbp
	mov	rax,	0x3C
	syscall
