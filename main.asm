default	rel
section	.data
fuck	db	"0x"
buf	times	0x10	db	"0"
hvals	dq  0x3736353433323130,0x4645444342413938
nl	db	0xA
start_heap_ptr	dq	0x0
end_heap_ptr	dq	0x0

section	.bss
start_bss:
end_bss:

section	.text
global	_start

_alloc_mem:
	push	rbp
	mov	rbp,	rsp
	sub	rsp,	0x10
	add	rdi,	0x10
	mov	rax,	0xFFFFFFFFFFFFFFF8
	and	rax,	rdi
	cmp	rax,	rdi
	je	_alloc_memJ0
	add	rax,	0x8
	mov	rdi,	rax
_alloc_memJ0:
	mov	qword	[rbp-0x8],	rdi
	mov	rbx,	qword	[start_heap_ptr]
	mov	qword	[rbp-0x10],	rbx
	xor	rdx,	rdx
_alloc_memJ1:
	cmp	rbx,	qword	[end_heap_ptr]
	jae	_alloc_memJ3
	cmp	qword	[rbx],	0
	jne	_alloc_memJ2
	add	rdx,	qword	[rbx+0x8]
	cmp	rdx,	qword	[rbp-0x8]
	jae	_alloc_memJ4
	add	rbx,	qword	[rbx+0x8]
	jmp	_alloc_memJ1
_alloc_memJ2:
	add	rbx,	qword	[rbx+0x8]
	mov	qword	[rbp-0x10],	rbx
	xor	rdx,	rdx
	jmp	_alloc_memJ1
_alloc_memJ3:
	mov	rdi,	qword	[rbp-0x8]
	sub	rdi,	rdx
	add	rdi,	qword	[end_heap_ptr]
	mov	rax,	0xC
	syscall
	mov	qword	[end_heap_ptr],	rax
_alloc_memJ4:
	mov	rax,	qword	[rbp-0x10]
	mov	rdi,	qword	[rbp-0x8]
	mov	qword	[rax],	0x1
	mov	qword	[rax+0x8],	rdi
	sub	rdx,	rdi
	cmp	rdx,	0x10
	jb	_alloc_memJ5
	add	rax,	rdi
	mov	qword	[rax],	0x0
	mov	qword	[rax+0x8],	rdx
	jmp	_alloc_memJ6	
_alloc_memJ5:
	add	qword	[rax+0x8],	rdx
_alloc_memJ6:
	mov	rax,	qword	[rbp-0x10]
	add	rax,	0x10
	mov	rsp,	rbp
	pop	rbp
	ret

; rdi is a pointer to the memory to be freed
_free_mem:
	push	rbp
	mov	rbp,	rsp
	sub	rsp,	0x10
	xor	rax,	rax
	sub	rdi,	0x10
	mov	qword	[rdi],	rax
	mov	qword	[rbp-0x8],	rdi
	mov	rbx,	qword	[rdi+0x8]
	mov	qword	[rbp-0x10],	rbx
	lea	rdx,	[rdi+rbx]
_free_memJ0:
	cmp	rdx,	qword	[end_heap_ptr]
	jae	_free_memJ1
	cmp	qword	[rdi+rbx],	0
	jne	_free_memJ1
	add	rbx,	qword	[rdx+0x8]
	lea	rdx,	[rdi+rbx]
	jmp	_free_memJ0
_free_memJ1:
	mov	qword	[rdi+0x8],	rbx
	jmp	_free_memJ2
_free_memJ2:
	mov	rsp,	rbp
	pop	rbp
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
	je	_startJ0
	add	rax,	0x8
_startJ0:
	mov	rbp,	rsp
	sub	rsp,	0x10
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
	call	main
	mov	rsp,	rbp
	mov	rax,	0x3C
	syscall

; main function bc im too lazy to remember where the actual code part starts in the _start function (even with a comment)
main:
	push	rbp
	mov	rbp,	rsp
	sub	rsp,	0x18
	mov	rsi,	qword	[end_heap_ptr]
	call	_printhex
	call	_newline
	mov	rdi,	qword	[end_heap_ptr]
	mov	rax,	qword	[start_heap_ptr]
	sub	rdi,	rax
	sub	rdi,	0xF
	;add	rdi,	0x20
	call	_alloc_mem
	mov	rsi,	rax
	mov	qword	[rbp-0x8],	rax
	call	_printhex
	call	_newline
	mov	rsi,	qword	[end_heap_ptr]
	call	_printhex
	call	_newline
	mov	rdi,	qword	[rbp-0x8]
	call	_free_mem
	mov	rsp,	rbp
	pop	rbp
	ret
