#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <tlhelp32.h>
#include <wincrypt.h>
#include <stdint.h>
#include <string.h>
typedef uint32_t U;
typedef struct {U offset,size;const BYTE *bytes;} Blob;
typedef struct {U offset;int game,code,data;} Reloc;
#include "recruit_blobs.h"
#include "exe_hash.h"
static HMODULE self;
static LONG started;
static HANDLE logFile;
static BYTE *code,*data;
static U delta;
static void logline(const char *s){DWORD n;if(logFile&&logFile!=INVALID_HANDLE_VALUE){WriteFile(logFile,s,(DWORD)strlen(s),&n,0);WriteFile(logFile,"\r\n",2,&n,0);}}
typedef struct {U va;BYTE old[8],patch[8];unsigned size;DWORD protection;} Patch;
static Patch patches[14];static unsigned patchCount;
static void relative(U va,const BYTE *expected,unsigned n,U destination,int call){
 Patch *p=&patches[patchCount++];p->va=va+delta;p->size=n;memcpy(p->old,expected,n);memset(p->patch,0x90,n);p->patch[0]=call?0xe8:0xe9;
 U rel=destination-p->va-5;memcpy(p->patch+1,&rel,4);
}
static void literal(U va,const BYTE *expected,const BYTE *replacement,unsigned n){Patch *p=&patches[patchCount++];p->va=va+delta;p->size=n;memcpy(p->old,expected,n);memcpy(p->patch,replacement,n);}
static void callsite(U va,U offset){BYTE expected[5]={0xe8,0,0,0,0};U rel=0xc0f170-va-5;memcpy(expected+1,&rel,4);relative(va,expected,5,(U)(uintptr_t)code+offset,1);}
static int prepare(void){
 code=VirtualAlloc(0,16384,MEM_COMMIT|MEM_RESERVE,PAGE_READWRITE);data=VirtualAlloc(0,4096,MEM_COMMIT|MEM_RESERVE,PAGE_READWRITE);if(!code||!data)return 0;
 for(unsigned i=0;i<sizeof(blobs)/sizeof(blobs[0]);i++)memcpy(code+blobs[i].offset,blobs[i].bytes,blobs[i].size);
 U cd=(U)(uintptr_t)code-0x10000000,dd=(U)(uintptr_t)data-0x20000000;
 for(unsigned i=0;i<sizeof(relocs)/sizeof(relocs[0]);i++){const Reloc *r=&relocs[i];U x;memcpy(&x,code+r->offset,4);x+=(U)r->game*delta+(U)r->code*cd+(U)r->data*dd;memcpy(code+r->offset,&x,4);}
 DWORD old;if(!VirtualProtect(code,16384,PAGE_EXECUTE_READ,&old))return 0;if(!FlushInstructionCache(GetCurrentProcess(),code,16384))return 0;
 U c=(U)(uintptr_t)code;
 relative(0x10c6c90,(BYTE[]){0x55,0x8b,0xec,0x6a,0xff},5,c,0);
 literal(0x10c6efe,(BYTE[]){0x75,0x0b},(BYTE[]){0xeb,0x0b},2);
 relative(0x9d7af0,(BYTE[]){0x8b,0x41,0x38,0x0f,0xb7,0x49,0x3e},7,c+6144,0);
 relative(0x10c6210,(BYTE[]){0x55,0x8b,0xec,0x83,0xec,0x08},6,c+4096,0);
 relative(0x1526d30,(BYTE[]){0x56,0x8b,0xf1,0x8b,0x46,0x20},6,c+4608,0);
 relative(0x14e10b0,(BYTE[]){0x55,0x8b,0xec,0x6a,0xff},5,c+6656,0);
 callsite(0x10d2a97,5120);callsite(0x10ca7ac,7168);
 literal(0x14e1c9a,(BYTE[]){0x6a,0x08},(BYTE[]){0x6a,0x10},2);
 literal(0x14e1c9c,(BYTE[]){0x68,0x80,0,0,0},(BYTE[]){0x68,0x90,0,0,0},5);
 literal(0x14e1cc1,(BYTE[]){0x68,0x80,0,0,0},(BYTE[]){0x68,0x90,0,0,0},5);
 BYTE ctor[5]={0xe8,0,0,0,0};U rel=0x14d7780 - 0x14e1cde - 5;memcpy(ctor+1,&rel,4);relative(0x14e1cde,ctor,5,c+5632,1);
 BYTE charge[5]={0xe8,0,0,0,0};rel=0xc0ad30 - 0x10d6075 - 5;memcpy(charge+1,&rel,4);relative(0x10d6075,charge,5,c+10240,1);
 BYTE hold[5]={0xe8,0,0,0,0};rel=0xc0af60 - 0x10d418c - 5;memcpy(hold+1,&rel,4);relative(0x10d418c,hold,5,c+10752,1);
 return patchCount==14;
}
static int install(void){
 HANDLE threads[256];unsigned count=0,suspended=0,protected=0;int ok=1;
 for(unsigned i=0;i<patchCount;i++)if(memcmp((void*)(uintptr_t)patches[i].va,patches[i].old,patches[i].size))return 0;
 HANDLE snap=CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD,0);if(snap==INVALID_HANDLE_VALUE)return 0;
 THREADENTRY32 te={0};te.dwSize=sizeof(te);
 if(Thread32First(snap,&te)){do{if(te.th32OwnerProcessID==GetCurrentProcessId()&&te.th32ThreadID!=GetCurrentThreadId()){
  if(count==256){ok=0;break;}HANDLE t=OpenThread(THREAD_SUSPEND_RESUME|THREAD_GET_CONTEXT,FALSE,te.th32ThreadID);if(!t){ok=0;break;}threads[count++]=t;
 }}while(Thread32Next(snap,&te));}CloseHandle(snap);
 if(ok)for(;protected<patchCount;protected++)if(!VirtualProtect((void*)(uintptr_t)patches[protected].va,patches[protected].size,PAGE_EXECUTE_READWRITE,&patches[protected].protection)){ok=0;break;}
 if(ok)for(;suspended<count;suspended++)if(SuspendThread(threads[suspended])==(DWORD)-1){ok=0;break;}
 if(ok)for(unsigned i=0;i<count;i++){CONTEXT c={0};c.ContextFlags=CONTEXT_CONTROL;if(!GetThreadContext(threads[i],&c)){ok=0;break;}for(unsigned j=0;j<patchCount;j++)if(c.Eip>=patches[j].va&&c.Eip<patches[j].va+patches[j].size)ok=0;}
 if(ok)for(unsigned i=0;i<patchCount;i++)if(memcmp((void*)(uintptr_t)patches[i].va,patches[i].old,patches[i].size))ok=0;
 if(ok){for(unsigned i=0;i<patchCount;i++)memcpy((void*)(uintptr_t)patches[i].va,patches[i].patch,patches[i].size);
  if(!FlushInstructionCache(GetCurrentProcess(),0,0)){for(unsigned i=0;i<patchCount;i++)memcpy((void*)(uintptr_t)patches[i].va,patches[i].old,patches[i].size);FlushInstructionCache(GetCurrentProcess(),0,0);ok=0;}}
 for(unsigned i=0;i<suspended;i++)ResumeThread(threads[i]);for(unsigned i=0;i<count;i++)CloseHandle(threads[i]);
 for(unsigned i=protected;i>0;i--){DWORD ignored;VirtualProtect((void*)(uintptr_t)patches[i-1].va,patches[i-1].size,patches[i-1].protection,&ignored);}
 return ok;
}
static DWORD WINAPI worker(void *arg){
 (void)arg;WCHAR path[MAX_PATH];GetModuleFileNameW(self,path,MAX_PATH);WCHAR *slash=wcsrchr(path,L'\\');if(slash)wcscpy(slash+1,L"RecruitCompanions.log");
 logFile=CreateFileW(path,GENERIC_WRITE,FILE_SHARE_READ,0,CREATE_ALWAYS,0,0);logline("RecruitCompanions 0.3 All Recruits (capacity 64): independent module, free call, native hold-T dismissal.");
 if(!hashMatches()){logline("Unsupported executable; no hooks installed.");return 0;}
 delta=(U)(uintptr_t)GetModuleHandleW(0)-0x400000;
 if(!prepare()){logline("Preparation failed; no hooks installed.");return 0;}
 int success=0;for(unsigned i=0;i<10&&!success;i++){success=install();if(!success)Sleep(100);}
 if(!success){logline("Original bytes or thread context differ; installation refused.");return 0;}
 logline("Ready. In Rome, T summons all available recruits (capacity 64); targeted T commands existing companions. Hold T dismisses the group. No test timeout.");
 for(;;){Sleep(10000);char line[384];U *d=(U*)data;unsigned live=0,follow=0,attack=0,dismissing=0;
 for(unsigned i=0;i<64;i++){U *slot=d+64+4*i;if(slot[0]){live++;if(slot[3]==1)follow++;if(slot[3]==2)attack++;if(slot[3]>=4)dismissing++;}}
 wsprintfA(line,"capacity=64 selected=%u live=%u following=%u attacking=%u dismissing=%u created=%u attacks=%u lookup_failures=%u returned=%u dismiss_pending=%u dismissed=%u free_calls=%u hold_commands=%u",d[29],live,follow,attack,dismissing,d[0],d[26],d[27],d[32],d[34],d[38],d[39],d[40]);logline(line);}

}
__declspec(dllexport) void __cdecl StartRecruitCompanions(void){if(InterlockedCompareExchange(&started,1,0)==0){HANDLE t=CreateThread(0,0,worker,0,0,0);if(t)CloseHandle(t);}}
BOOL WINAPI DllMain(HINSTANCE instance,DWORD reason,LPVOID reserved){(void)reserved;if(reason==DLL_PROCESS_ATTACH){self=instance;DisableThreadLibraryCalls(instance);}return TRUE;}

