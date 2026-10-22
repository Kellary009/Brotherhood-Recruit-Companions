pushfd
push eax
mov eax,[ecx+12]
cmp eax,[{guild}]
jne skip
call {worker}
skip:
pop eax
popfd
push ebp
mov ebp,esp
sub esp,8
jmp {tick_resume}