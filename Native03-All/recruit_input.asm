pushfd
pushad
mov ebp,esp
sub esp,0x220
and esp,0xfffffff0
fxsave [esp]
sub esp,32
mov dword ptr [esp+28],0
mov eax,1
xchg [{busy}],eax
test eax,eax
jnz restore
cmp dword ptr [{pending_input}],0
je input_ready
mov dword ptr [esp+28],1
jmp finish
input_ready:
lock inc dword ptr [{calls}]
mov ecx,[ecx+12]
mov [{guild}],ecx
call {valid_target}
test al,al
jnz attack
mov dword ptr [{armed}],1
cmp dword ptr [{selection_returned}],0
je finish
mov dword ptr [esp+28],1
jmp finish
attack:
lea eax,[esp+8]
push eax
mov ecx,[{guild}]
add ecx,0x80
call {get_target_handle}
mov esi,{slots}
attack_loop:
cmp dword ptr [esi],0
je next_slot
mov dword ptr [esp+28],1
mov ebx,[esi+4]
mov eax,[esi]
cmp dword ptr [ebx],{trainee_vtable}
jne failed_attack
mov edx,[ebx+0x20]
test edx,edx
jz failed_attack
cmp [edx+0x68],eax
jne failed_attack
lea eax,[eax+0xbc]
push eax
mov ecx,[{guild}]
call {get_trainee}
test eax,eax
jz failed_attack
mov ebx,eax
mov dword ptr [esi+12],2
push 0
mov ecx,ebx
call {attack_mode}
lea eax,[esp+8]
push eax
mov ecx,ebx
call {trainee_target}
push 0
push dword ptr [{attack_event}]
mov ecx,ebx
call {dispatch}
lock inc dword ptr [{attack_sent}]
jmp next_slot
failed_attack:
lock inc dword ptr [{attack_failed}]
next_slot:
add esi,16
cmp esi,{slots_end}
jb attack_loop
lea ecx,[esp+8]
call {release_handle}
finish:
mov dword ptr [{busy}],0
restore:
cmp dword ptr [esp+28],0
jne consumed
add esp,32
fxrstor [esp]
mov esp,ebp
popad
popfd
push ebp
mov ebp,esp
push -1
jmp {resume}
consumed:
add esp,32
fxrstor [esp]
mov esp,ebp
popad
popfd
ret