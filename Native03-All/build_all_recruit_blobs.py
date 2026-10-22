"""Generate relocatable native hook blobs; verify against fresh assembly."""
import ast,sys,struct,random,json
from pathlib import Path
sys.path.insert(0,r'D:\Codex-Modding\Brotherhood-Animation-Hotkeys\work\pydeps')
sys.path.insert(0,r'D:\Codex-Modding\Apple-of-Eden\Current\work')
from keystone import Ks,KS_ARCH_X86,KS_MODE_32
from capstone import Cs,CS_ARCH_X86,CS_MODE_32
p=Path('work');out=Path(sys.argv[1]);out.mkdir(parents=True,exist_ok=True)
tree=ast.parse((p/'test_recruit_native.py').read_text())
a=next(n for n in ast.walk(tree) if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='values' for t in n.targets))
def values(game,code,data):
 v=eval(compile(ast.Expression(a.value),'values','eval'),dict(address=lambda x:x+game-0x400000,code=code,data=data,recover=0))
 v.update(deferred_count=data+64,deferred_actor=data+68,deferred_record=data+72,slots_end=data+1280,selected=data+1536,selected_end=data+1792)
 assert v['slots_end']<=v['selected'] and v['selected_end']<=data+4096
 return v
units=[('input',0),('worker',2048),('tick',4096),('activate',4608),('select',5120),('ctor',5632),('keeper',6144),('destroy',6656),('reinforce',7168),('dismiss',8192),('freecall',10240),('hold',10752)]
cs=Cs(CS_ARCH_X86,CS_MODE_32);cs.detail=True
blobs=[];relocs=[]
for name,offset in units:
 path=p/('recruit_squad_tick.asm' if name=='tick' else 'recruit_native_'+name+'.asm')
 template='\n'.join(l.split(';')[0] for l in path.read_text().splitlines())
 if name=='select':
  template=template.replace('mov edi,4','mov edi,64').replace('cmp ecx,4','cmp ecx,64').replace('mov ecx,4','mov ecx,64')
  template=template.replace('push eax\nmov ecx,edx', 'push eax\nmov ecx,64\nmov edi,{selected}\nclear_selected:\nmov dword ptr [edi],0\nadd edi,4\nloop clear_selected\nmov ecx,[{selection_returned}]')
 (out/('recruit_'+name+'.asm')).write_text(template)
 def assemble(g,c,d):return bytes(Ks(KS_ARCH_X86,KS_MODE_32).asm(template.format(**values(g,c,d)),addr=c+offset)[0])
 raw=assemble(0x400000,0x10000000,0x20000000)
 variants=[assemble(0x410000,0x10000000,0x20000000),assemble(0x400000,0x10010000,0x20000000),assemble(0x400000,0x10000000,0x20010000)]
 fields=set()
 for ins in cs.disasm(raw,0x10000000+offset):
  for field,size in [(ins.disp_offset,ins.disp_size),(ins.imm_offset,ins.imm_size)]:
   if field and size==4:fields.add(ins.address-(0x10000000+offset)+field)
 unit_reloc=[]
 for field in sorted(fields):
  original=struct.unpack_from('<I',raw,field)[0];coeff=[]
  for v in variants:
   diff=(struct.unpack_from('<I',v,field)[0]-original)&0xffffffff
   signed=diff if diff<0x80000000 else diff-0x100000000
   assert signed%65536==0
   coeff.append(signed//65536)
  if any(coeff):unit_reloc.append((field,*coeff));relocs.append((offset+field,*coeff))
 for g,c,d in [(0x1b0000,0x3910000,0x3920000),(0xb60000,0x73490000,0x6aaa0000),(0x400000,0x10100000,0x20110000)]:
  patched=bytearray(raw)
  for f,b,co,da in unit_reloc:
   n=struct.unpack_from('<I',patched,f)[0]+b*(g-0x400000)+co*(c-0x10000000)+da*(d-0x20000000)
   struct.pack_into('<I',patched,f,n&0xffffffff)
  assert patched==assemble(g,c,d),(name,'relocation mismatch')
 assert len(raw)<(2048 if name in ('input','worker','dismiss') else 512)
 blobs.append((name,offset,raw));print(name,len(raw),'relocation tests passed')
header=['/* Generated and relocation-verified. Do not edit. */']
for name,offset,raw in blobs:header.append('static const unsigned char blob_'+name+'[]={'+','.join(hex(x) for x in raw)+'};')
header.append('static const Blob blobs[]={'+','.join('{%d,sizeof(blob_%s),blob_%s}'%(o,n,n) for n,o,r in blobs)+'};')
header.append('static const Reloc relocs[]={'+','.join('{%d,%d,%d,%d}'%r for r in relocs)+'};')
(out/'recruit_blobs.h').write_text('\n'.join(header))

(out/'native_mod.def').write_text((p/'native_mod.def').read_text())
