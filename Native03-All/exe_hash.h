static int hashMatches(void){
 const BYTE expected[32]={0x45,0xbb,0xb4,0xaf,0x4d,0x50,0x19,0xee,0x38,0x70,0xd6,0x9a,0x3d,0xb8,0xa9,0x8f,0xcc,0x67,0xb1,0xe1,0x49,0x53,0x77,0x2b,0xd8,0x03,0xbc,0x7e,0xb5,0x1e,0xbf,0xe7};
 WCHAR path[MAX_PATH];HCRYPTPROV provider=0;HCRYPTHASH hash=0;HANDLE file=INVALID_HANDLE_VALUE;int ok=0;BYTE block[16384],digest[32];DWORD n,size=32;
 if(!GetModuleFileNameW(NULL,path,MAX_PATH))return 0;
 file=CreateFileW(path,GENERIC_READ,FILE_SHARE_READ,0,OPEN_EXISTING,0,0);
 if(file==INVALID_HANDLE_VALUE)goto end;
 if(!CryptAcquireContextW(&provider,0,0,PROV_RSA_AES,CRYPT_VERIFYCONTEXT)||!CryptCreateHash(provider,CALG_SHA_256,0,0,&hash))goto end;
 for(;;){if(!ReadFile(file,block,sizeof(block),&n,0))goto end;if(!n)break;if(!CryptHashData(hash,block,n,0))goto end;}
 ok=CryptGetHashParam(hash,HP_HASHVAL,digest,&size,0)&&size==32&&!memcmp(expected,digest,32);
end:if(hash)CryptDestroyHash(hash);if(provider)CryptReleaseContext(provider,0);if(file!=INVALID_HANDLE_VALUE)CloseHandle(file);return ok;
}
