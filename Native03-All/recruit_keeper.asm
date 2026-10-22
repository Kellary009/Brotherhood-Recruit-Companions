


push ebx
push esi
push edi
mov esi,[ecx+0x38]
movzx eax,word ptr [ecx+0x3e]
and eax,0x3fff
lea edi,[esi+eax*4]
queue_loop:
cmp esi,edi
je empty
mov ebx,[esi]
cmp dword ptr [ebx+12],1
jne next_record
cmp dword ptr [ebx+0x1c],4
jne eligible
mov eax,[ebx+0x24]
test eax,eax
jz eligible
test dword ptr [eax+8],0x80000000
jz eligible
mov edx,[eax]
test edx,edx
jz eligible
mov eax,[{world_singleton}]
test eax,eax
jz eligible
mov eax,[eax+0x50]
cmp eax,[edx+0x5c]
jne eligible
push esi
mov esi,{slots}
managed_loop:
cmp [esi],edx
je defer
add esi,16
cmp esi,{slots_end}
jb managed_loop
pop esi
jmp eligible
defer:
pop esi
lock inc dword ptr [{deferred_count}]
mov [{deferred_actor}],edx
mov [{deferred_record}],ebx
next_record:
add esi,4
jmp queue_loop
eligible:
mov eax,ebx
jmp leave
empty:
xor eax,eax
leave:
pop edi
pop esi
pop ebx
ret