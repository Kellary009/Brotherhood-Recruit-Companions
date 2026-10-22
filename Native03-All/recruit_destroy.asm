pushfd
pushad
mov edx,{slots}
scan:
cmp [edx+4],ecx
je found
add edx,16
cmp edx,{slots_end}
jb scan
jmp done
found:
mov dword ptr [edx],0
mov dword ptr [edx+4],0
mov dword ptr [edx+8],0
mov dword ptr [edx+12],0
done:
popad
popfd
push ebp
mov ebp,esp
push -1
jmp {destroy_resume}