

cmp dword ptr [{armed}],1
jne native
cmp dword ptr [{selection_returned}],0
je native
push ebp
mov ebp,esp
push esi
mov esi,[ebp+8]
lock inc dword ptr [{blocked_reinforcements}]
push 0
mov ecx,esi
call {array_ctor}
mov eax,esi
pop esi
pop ebp
ret 8
native:
jmp {select_recruits}