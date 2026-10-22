
pushfd
pushad
mov edx,{slots}
scan:
cmp [edx+8],ecx
je found
add edx,16
cmp edx,{slots_end}
jb scan
jmp done
found:
mov dword ptr [edx+12],0
lock inc dword ptr [{resumed}]
done:
popad
popfd
push esi
mov esi,ecx
mov eax,[esi+0x20]
jmp {activate_resume}