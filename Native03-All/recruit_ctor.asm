
push ebx
push esi
push edi
push ebp
mov esi,ecx
cmp dword ptr [{armed}],1
jne original
mov eax,[edi+0x20]
test eax,eax
jz original
mov ebx,[eax+0x68]
test ebx,ebx
jz original
mov edx,{selected}
selected_loop:
mov eax,[edx]
test eax,eax
jz selected_next
mov eax,[eax+0x40]
test eax,eax
jz selected_next
test dword ptr [eax+8],0x80000000
jz selected_next
cmp [eax],ebx
je selected_actor
selected_next:
add edx,4
cmp edx,{selected_end}
jb selected_loop
jmp original
selected_actor:
mov ebp,{slots}
find_slot:
cmp dword ptr [ebp],0
je slot_ready
add ebp,16
cmp ebp,{slots_end}
jb find_slot
jmp original
slot_ready:
mov ecx,[ebx+0x5c]
call {get_player}
test eax,eax
jz original
push eax
mov ecx,esi
call {simple_ctor}
mov esi,eax
pop eax
lea eax,[eax+0xbc]
push eax
mov ecx,esi
call {set_target}
push 1
push 0
push 6
push 2
mov ecx,esi
call {set_params}
mov dword ptr [esi+0x60],6
mov dword ptr [esi+0x6c],0x3f800000
mov [ebp],ebx
mov [ebp+4],edi
mov [ebp+8],esi
mov dword ptr [ebp+12],3
lock inc dword ptr [{installed}]
mov eax,esi
pop ebp
pop edi
pop esi
pop ebx
ret
original:
mov ecx,esi
pop ebp
pop edi
pop esi
pop ebx
jmp {flee_ctor}