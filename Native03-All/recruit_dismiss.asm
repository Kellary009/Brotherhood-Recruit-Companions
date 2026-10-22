pushfd
pushad
mov ebp,esp
sub esp,0x220
and esp,0xfffffff0
fxsave [esp]
mov dword ptr [{armed}],0
mov esi,{slots}
scan:
mov edi,[esi+4]
test edi,edi
jz next_slot
cmp dword ptr [edi],{trainee_vtable}
jne next_slot
cmp dword ptr [esi+12],5
jae await_flee
mov eax,[edi+0x90]
cmp eax,[esi+8]
jne next_slot
cmp dword ptr [esi+12],4
je await_inactive

mov dword ptr [esi+12],4
push 0
push dword ptr [{native_follow_event}]
mov ecx,edi
call {dispatch}
jmp next_slot
await_inactive:
mov eax,[{flee_descriptor}]
movzx ecx,word ptr [eax+0x42]
mov edx,[edi+0x40]
bt [edx],ecx
jc next_slot


movzx ecx,word ptr [eax+0x3e]
mov edx,[edi+0x30]
mov eax,[esi+8]
cmp [edx+ecx*4],eax
jne next_slot
mov dword ptr [edx+ecx*4],0
mov ecx,edi
call {rebuild_flee}
mov eax,[edi+0x90]
mov [esi+8],eax
mov dword ptr [esi+12],5
push 0
push dword ptr [{flee_event}]
mov ecx,edi
call {dispatch}
jmp next_slot
await_flee:
mov eax,[{flee_descriptor}]
movzx ecx,word ptr [eax+0x42]
mov edx,[edi+0x40]
bt [edx],ecx
jc release_slot
cmp dword ptr [esi+12],5
je leave_native_follow
cmp dword ptr [esi+12],6
jne next_slot
mov dword ptr [esi+12],7
push 0
push dword ptr [{flee_event}]
mov ecx,edi
call {dispatch}
jmp next_slot
leave_native_follow:
mov dword ptr [esi+12],6
push 0
push dword ptr [{native_common_event}]
mov ecx,edi
call {dispatch}
jmp next_slot
release_slot:
mov dword ptr [esi],0
mov dword ptr [esi+4],0
mov dword ptr [esi+8],0
mov dword ptr [esi+12],0
lock inc dword ptr [{dismissed}]
next_slot:
add esi,16
cmp esi,{slots_end}
jb scan
mov esi,{slots}
remaining:
cmp dword ptr [esi],0
jne done
add esi,16
cmp esi,{slots_end}
jb remaining
mov dword ptr [{selection_returned}],0
mov dword ptr [{installed}],0
mov dword ptr [{pending_input}],0
done:
fxrstor [esp]
mov esp,ebp
popad
popfd
ret