pushfd
pushad
mov ebp,esp
sub esp,0x220
and esp,0xfffffff0
fxsave [esp]
mov eax,1
xchg [{busy}],eax
test eax,eax
jnz restore
lock inc dword ptr [{ticks}]
cmp dword ptr [{pending_input}],0
je normal_work
call {dismiss_group}
jmp finish
normal_work:
mov esi,{slots}
scan:
cmp dword ptr [esi],0
je next_slot
cmp dword ptr [esi+12],2
je check_attack_finished
cmp dword ptr [esi+12],0
jne next_slot
mov edi,[esi+8]
cmp dword ptr [edi],{simple_vtable}
jne next_slot
mov dword ptr [esi+12],1
mov ecx,edi
call {start_follow}
mov ecx,edi
call {start_target}
lock inc dword ptr [{started}]
jmp next_slot
check_attack_finished:
mov edi,[esi+4]
cmp dword ptr [edi],{trainee_vtable}
jne next_slot

mov eax,[{assassinate_descriptor}]
movzx ecx,word ptr [eax+0x42]
mov eax,[edi+0x40]
bt [eax],ecx
jnc next_slot
mov eax,[edi+0x98]
test eax,eax
jz next_slot
mov eax,[eax+0x74]
test eax,eax
jz next_slot
test dword ptr [eax+8],0x80000000
jz return_to_hero
cmp dword ptr [eax],0
jne next_slot
return_to_hero:
mov eax,[esi]
mov ecx,[eax+0x5c]
call {get_player}
test eax,eax
jz next_slot
lea eax,[eax+0xbc]
push eax
mov ecx,edi
call {trainee_target}
mov dword ptr [esi+12],1
push 0
push dword ptr [{native_follow_event}]
mov ecx,edi
call {dispatch}
lock inc dword ptr [{returned_follow}]
next_slot:
add esi,16
cmp esi,{slots_end}
jb scan

cmp dword ptr [{installed}],0
je finish
mov eax,{slots}
remaining:
cmp dword ptr [eax],0
jne finish
add eax,16
cmp eax,{slots_end}
jb remaining
mov dword ptr [{selection_returned}],0
mov dword ptr [{installed}],0
mov dword ptr [{armed}],0
finish:
mov dword ptr [{busy}],0
restore:
fxrstor [esp]
mov esp,ebp
popad
popfd
ret