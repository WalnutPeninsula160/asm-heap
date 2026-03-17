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

; rdi is the number of bytes to allocate
_alloc_mem:
	push	rbp
	mov	rbp,	rsp
	sub	rsp,	0x8
	xor	rax,	rax
	mov	al,	0x8
	not	rax
	and	rax,	rdi
	cmp	rax,	rdi
	je	_alloc_memJ0
	lea	rdi,	[rax+0x8]
_alloc_memJ0:
	mov	qword	[rbp-0x8],	rdi
	lea	rbx,	[start_heap_ptr]
	xor	rdx,	rdx
_alloc_memJ1:
	cmp	rbx,	qword	[end_heap_ptr]
	jae	_alloc_mem_brk
	mov	rdi,	qword	[rbx+0x8]
	add	rdi,	rdx
	cmp	rdi,	qword	[rbp-0x8]
	jge	_alloc_mem_alloc
	mov	rdx,	rdi
	add	rbx,	qword	[rbx+0x8]
	jmp	_alloc_memJ1
_alloc_mem_brk:
	lea	rdi,	[rbx+rdx]
	mov	rax,	0x0C
	syscall
	mov	rcx,	0x1
_alloc_mem_alloc:
	xor 	rax,	rax
	mov	qword	[rbx],	rax
	mov	qword	[rbx+0x8],	rdx
	test	rcx,	rcx
	jnz	
	jmp	_alloc_mem_ret
_alloc_mem_ret:
	mov	rsp,	rbp
	pop	rbp
	mov	rax,	rbx
	ret

; rdi is a pointer to the memory to be freed
_free_mem:
	push	rbp
	mov	rbp,	rsp
	cmp	qword	[rdi-0x10],	0x3
	je	_free_memJ2
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
	jmp	_free_memJ3
_free_memJ2:
	sub	rdi,	0x10
	mov	rsi,	qword	[rdi+0x8]
	mov	rax,	0xB
	syscall
_free_memJ3:
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
	mov	rdi,	4096
;	mov	rsi,	0x1
	xor	rsi,	rsi
	call	_alloc_mem
;	mov	rax,	rdi
;	call	_free_mem
	mov	rsp,	rbp
	pop	rbp
	ret
