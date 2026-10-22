cmp dword ptr [{guild}],0
je original
intercept_hold:


push ebp
mov ebp,esp
push esi
test dword ptr [ebp+12],0x8000
jnz done
mov esi,[ebp+8]
test esi,esi
jz done
push esi
mov ecx,[{allocation_metadata}]
call {allocation_info}
mov ecx,[{allocator}]
mov ecx,[ecx]
mov edx,[ecx]
push 0
push 0
push eax
push esi
push 4
call dword ptr [edx+0x14]
done:
lock inc dword ptr [{hold_commands}]
cmp dword ptr [{selection_returned}],0
je no_group
mov dword ptr [{pending_input}],1
no_group:
pop esi
xor al,al
pop ebp
ret 8
original:
jmp {consume_arrowstorm}
