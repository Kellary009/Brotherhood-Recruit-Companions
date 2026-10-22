
push ebp
mov ebp,esp
push ebx
push esi
push edi
mov ebx,ecx
mov esi,[ebp+8]
mov edi,[ebp+12]
cmp dword ptr [{armed}],1
jne select_native
cmp dword ptr [{selection_returned}],0
jne blocked
mov edi,64
select_native:
mov [{selection_requested}],edi
lock inc dword ptr [{selection_calls}]
push edi
push esi
mov ecx,ebx
call {select_recruits}
movzx edx,word ptr [esi+6]
and edx,0x3fff
mov [{selection_returned}],edx
push eax
mov ecx,64
mov edi,{selected}
clear_selected:
mov dword ptr [edi],0
add edi,4
loop clear_selected
mov ecx,[{selection_returned}]
cmp ecx,64
jbe count_ok
mov ecx,64
count_ok:
mov edi,{selected}
mov edx,[esi]
copy_selected:
test ecx,ecx
jz copy_done
mov eax,[edx]
mov [edi],eax
add edi,4
add edx,4
dec ecx
jmp copy_selected
copy_done:
pop eax
jmp leave
blocked:
lock inc dword ptr [{blocked_spawns}]
push 0
mov ecx,esi
call {array_ctor}
mov eax,esi
leave:
pop edi
pop esi
pop ebx
pop ebp
ret 8