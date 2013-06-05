
_ls:     file format elf32-i386


Disassembly of section .text:

00000000 <fmtname>:
#include "user.h"
#include "fs.h"

char*
fmtname(char *path)
{
   0:	55                   	push   %ebp
   1:	89 e5                	mov    %esp,%ebp
   3:	53                   	push   %ebx
   4:	83 ec 24             	sub    $0x24,%esp
  static char buf[DIRSIZ+1];
  char *p;
  
  // Find first character after last slash.
  for(p=path+strlen(path); p >= path && *p != '/'; p--)
   7:	8b 45 08             	mov    0x8(%ebp),%eax
   a:	89 04 24             	mov    %eax,(%esp)
   d:	e8 dc 03 00 00       	call   3ee <strlen>
  12:	03 45 08             	add    0x8(%ebp),%eax
  15:	89 45 f4             	mov    %eax,-0xc(%ebp)
  18:	eb 04                	jmp    1e <fmtname+0x1e>
  1a:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
  1e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  21:	3b 45 08             	cmp    0x8(%ebp),%eax
  24:	72 0a                	jb     30 <fmtname+0x30>
  26:	8b 45 f4             	mov    -0xc(%ebp),%eax
  29:	0f b6 00             	movzbl (%eax),%eax
  2c:	3c 2f                	cmp    $0x2f,%al
  2e:	75 ea                	jne    1a <fmtname+0x1a>
    ;
  p++;
  30:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  
  // Return blank-padded name.
  if(strlen(p) >= DIRSIZ)
  34:	8b 45 f4             	mov    -0xc(%ebp),%eax
  37:	89 04 24             	mov    %eax,(%esp)
  3a:	e8 af 03 00 00       	call   3ee <strlen>
  3f:	83 f8 0d             	cmp    $0xd,%eax
  42:	76 05                	jbe    49 <fmtname+0x49>
    return p;
  44:	8b 45 f4             	mov    -0xc(%ebp),%eax
  47:	eb 5f                	jmp    a8 <fmtname+0xa8>
  memmove(buf, p, strlen(p));
  49:	8b 45 f4             	mov    -0xc(%ebp),%eax
  4c:	89 04 24             	mov    %eax,(%esp)
  4f:	e8 9a 03 00 00       	call   3ee <strlen>
  54:	89 44 24 08          	mov    %eax,0x8(%esp)
  58:	8b 45 f4             	mov    -0xc(%ebp),%eax
  5b:	89 44 24 04          	mov    %eax,0x4(%esp)
  5f:	c7 04 24 30 0e 00 00 	movl   $0xe30,(%esp)
  66:	e8 07 05 00 00       	call   572 <memmove>
  memset(buf+strlen(p), ' ', DIRSIZ-strlen(p));
  6b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  6e:	89 04 24             	mov    %eax,(%esp)
  71:	e8 78 03 00 00       	call   3ee <strlen>
  76:	ba 0e 00 00 00       	mov    $0xe,%edx
  7b:	89 d3                	mov    %edx,%ebx
  7d:	29 c3                	sub    %eax,%ebx
  7f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  82:	89 04 24             	mov    %eax,(%esp)
  85:	e8 64 03 00 00       	call   3ee <strlen>
  8a:	05 30 0e 00 00       	add    $0xe30,%eax
  8f:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  93:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
  9a:	00 
  9b:	89 04 24             	mov    %eax,(%esp)
  9e:	e8 70 03 00 00       	call   413 <memset>
  return buf;
  a3:	b8 30 0e 00 00       	mov    $0xe30,%eax
}
  a8:	83 c4 24             	add    $0x24,%esp
  ab:	5b                   	pop    %ebx
  ac:	5d                   	pop    %ebp
  ad:	c3                   	ret    

000000ae <ls>:

void
ls(char *path)
{
  ae:	55                   	push   %ebp
  af:	89 e5                	mov    %esp,%ebp
  b1:	57                   	push   %edi
  b2:	56                   	push   %esi
  b3:	53                   	push   %ebx
  b4:	81 ec 5c 02 00 00    	sub    $0x25c,%esp
  char buf[512], *p;
  int fd;
  struct dirent de;
  struct stat st;
  
  if((fd = open(path, 0)) < 0){
  ba:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  c1:	00 
  c2:	8b 45 08             	mov    0x8(%ebp),%eax
  c5:	89 04 24             	mov    %eax,(%esp)
  c8:	e8 2b 05 00 00       	call   5f8 <open>
  cd:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  d0:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  d4:	79 20                	jns    f6 <ls+0x48>
    printf(2, "ls: cannot open %s\n", path);
  d6:	8b 45 08             	mov    0x8(%ebp),%eax
  d9:	89 44 24 08          	mov    %eax,0x8(%esp)
  dd:	c7 44 24 04 3b 0b 00 	movl   $0xb3b,0x4(%esp)
  e4:	00 
  e5:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
  ec:	e8 86 06 00 00       	call   777 <printf>
    return;
  f1:	e9 01 02 00 00       	jmp    2f7 <ls+0x249>
  }
  
  if(fstat(fd, &st) < 0){
  f6:	8d 85 bc fd ff ff    	lea    -0x244(%ebp),%eax
  fc:	89 44 24 04          	mov    %eax,0x4(%esp)
 100:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 103:	89 04 24             	mov    %eax,(%esp)
 106:	e8 05 05 00 00       	call   610 <fstat>
 10b:	85 c0                	test   %eax,%eax
 10d:	79 2b                	jns    13a <ls+0x8c>
    printf(2, "ls: cannot stat %s\n", path);
 10f:	8b 45 08             	mov    0x8(%ebp),%eax
 112:	89 44 24 08          	mov    %eax,0x8(%esp)
 116:	c7 44 24 04 4f 0b 00 	movl   $0xb4f,0x4(%esp)
 11d:	00 
 11e:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
 125:	e8 4d 06 00 00       	call   777 <printf>
    close(fd);
 12a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 12d:	89 04 24             	mov    %eax,(%esp)
 130:	e8 ab 04 00 00       	call   5e0 <close>
    return;
 135:	e9 bd 01 00 00       	jmp    2f7 <ls+0x249>
  }
  
  switch(st.type){
 13a:	0f b7 85 bc fd ff ff 	movzwl -0x244(%ebp),%eax
 141:	98                   	cwtl   
 142:	83 f8 01             	cmp    $0x1,%eax
 145:	74 53                	je     19a <ls+0xec>
 147:	83 f8 02             	cmp    $0x2,%eax
 14a:	0f 85 9c 01 00 00    	jne    2ec <ls+0x23e>
  case T_FILE:
    printf(1, "%s %d %d %d\n", fmtname(path), st.type, st.ino, st.size);
 150:	8b bd cc fd ff ff    	mov    -0x234(%ebp),%edi
 156:	8b b5 c4 fd ff ff    	mov    -0x23c(%ebp),%esi
 15c:	0f b7 85 bc fd ff ff 	movzwl -0x244(%ebp),%eax
 163:	0f bf d8             	movswl %ax,%ebx
 166:	8b 45 08             	mov    0x8(%ebp),%eax
 169:	89 04 24             	mov    %eax,(%esp)
 16c:	e8 8f fe ff ff       	call   0 <fmtname>
 171:	89 7c 24 14          	mov    %edi,0x14(%esp)
 175:	89 74 24 10          	mov    %esi,0x10(%esp)
 179:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
 17d:	89 44 24 08          	mov    %eax,0x8(%esp)
 181:	c7 44 24 04 63 0b 00 	movl   $0xb63,0x4(%esp)
 188:	00 
 189:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
 190:	e8 e2 05 00 00       	call   777 <printf>
    break;
 195:	e9 52 01 00 00       	jmp    2ec <ls+0x23e>
  
  case T_DIR:
    if(strlen(path) + 1 + DIRSIZ + 1 > sizeof buf){
 19a:	8b 45 08             	mov    0x8(%ebp),%eax
 19d:	89 04 24             	mov    %eax,(%esp)
 1a0:	e8 49 02 00 00       	call   3ee <strlen>
 1a5:	83 c0 10             	add    $0x10,%eax
 1a8:	3d 00 02 00 00       	cmp    $0x200,%eax
 1ad:	76 19                	jbe    1c8 <ls+0x11a>
      printf(1, "ls: path too long\n");
 1af:	c7 44 24 04 70 0b 00 	movl   $0xb70,0x4(%esp)
 1b6:	00 
 1b7:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
 1be:	e8 b4 05 00 00       	call   777 <printf>
      break;
 1c3:	e9 24 01 00 00       	jmp    2ec <ls+0x23e>
    }
    strcpy(buf, path);
 1c8:	8b 45 08             	mov    0x8(%ebp),%eax
 1cb:	89 44 24 04          	mov    %eax,0x4(%esp)
 1cf:	8d 85 e0 fd ff ff    	lea    -0x220(%ebp),%eax
 1d5:	89 04 24             	mov    %eax,(%esp)
 1d8:	e8 9c 01 00 00       	call   379 <strcpy>
    p = buf+strlen(buf);
 1dd:	8d 85 e0 fd ff ff    	lea    -0x220(%ebp),%eax
 1e3:	89 04 24             	mov    %eax,(%esp)
 1e6:	e8 03 02 00 00       	call   3ee <strlen>
 1eb:	8d 95 e0 fd ff ff    	lea    -0x220(%ebp),%edx
 1f1:	01 d0                	add    %edx,%eax
 1f3:	89 45 e0             	mov    %eax,-0x20(%ebp)
    *p++ = '/';
 1f6:	8b 45 e0             	mov    -0x20(%ebp),%eax
 1f9:	c6 00 2f             	movb   $0x2f,(%eax)
 1fc:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
    while(read(fd, &de, sizeof(de)) == sizeof(de)){
 200:	e9 c0 00 00 00       	jmp    2c5 <ls+0x217>
      if(de.inum == 0)
 205:	0f b7 85 d0 fd ff ff 	movzwl -0x230(%ebp),%eax
 20c:	66 85 c0             	test   %ax,%ax
 20f:	0f 84 af 00 00 00    	je     2c4 <ls+0x216>
        continue;
      memmove(p, de.name, DIRSIZ);
 215:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
 21c:	00 
 21d:	8d 85 d0 fd ff ff    	lea    -0x230(%ebp),%eax
 223:	83 c0 02             	add    $0x2,%eax
 226:	89 44 24 04          	mov    %eax,0x4(%esp)
 22a:	8b 45 e0             	mov    -0x20(%ebp),%eax
 22d:	89 04 24             	mov    %eax,(%esp)
 230:	e8 3d 03 00 00       	call   572 <memmove>
      p[DIRSIZ] = 0;
 235:	8b 45 e0             	mov    -0x20(%ebp),%eax
 238:	83 c0 0e             	add    $0xe,%eax
 23b:	c6 00 00             	movb   $0x0,(%eax)
      if(stat(buf, &st) < 0){
 23e:	8d 85 bc fd ff ff    	lea    -0x244(%ebp),%eax
 244:	89 44 24 04          	mov    %eax,0x4(%esp)
 248:	8d 85 e0 fd ff ff    	lea    -0x220(%ebp),%eax
 24e:	89 04 24             	mov    %eax,(%esp)
 251:	e8 83 02 00 00       	call   4d9 <stat>
 256:	85 c0                	test   %eax,%eax
 258:	79 20                	jns    27a <ls+0x1cc>
        printf(1, "ls: cannot stat %s\n", buf);
 25a:	8d 85 e0 fd ff ff    	lea    -0x220(%ebp),%eax
 260:	89 44 24 08          	mov    %eax,0x8(%esp)
 264:	c7 44 24 04 4f 0b 00 	movl   $0xb4f,0x4(%esp)
 26b:	00 
 26c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
 273:	e8 ff 04 00 00       	call   777 <printf>
        continue;
 278:	eb 4b                	jmp    2c5 <ls+0x217>
      }
      printf(1, "%s %d %d %d\n", fmtname(buf), st.type, st.ino, st.size);
 27a:	8b bd cc fd ff ff    	mov    -0x234(%ebp),%edi
 280:	8b b5 c4 fd ff ff    	mov    -0x23c(%ebp),%esi
 286:	0f b7 85 bc fd ff ff 	movzwl -0x244(%ebp),%eax
 28d:	0f bf d8             	movswl %ax,%ebx
 290:	8d 85 e0 fd ff ff    	lea    -0x220(%ebp),%eax
 296:	89 04 24             	mov    %eax,(%esp)
 299:	e8 62 fd ff ff       	call   0 <fmtname>
 29e:	89 7c 24 14          	mov    %edi,0x14(%esp)
 2a2:	89 74 24 10          	mov    %esi,0x10(%esp)
 2a6:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
 2aa:	89 44 24 08          	mov    %eax,0x8(%esp)
 2ae:	c7 44 24 04 63 0b 00 	movl   $0xb63,0x4(%esp)
 2b5:	00 
 2b6:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
 2bd:	e8 b5 04 00 00       	call   777 <printf>
 2c2:	eb 01                	jmp    2c5 <ls+0x217>
    strcpy(buf, path);
    p = buf+strlen(buf);
    *p++ = '/';
    while(read(fd, &de, sizeof(de)) == sizeof(de)){
      if(de.inum == 0)
        continue;
 2c4:	90                   	nop
      break;
    }
    strcpy(buf, path);
    p = buf+strlen(buf);
    *p++ = '/';
    while(read(fd, &de, sizeof(de)) == sizeof(de)){
 2c5:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
 2cc:	00 
 2cd:	8d 85 d0 fd ff ff    	lea    -0x230(%ebp),%eax
 2d3:	89 44 24 04          	mov    %eax,0x4(%esp)
 2d7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 2da:	89 04 24             	mov    %eax,(%esp)
 2dd:	e8 ee 02 00 00       	call   5d0 <read>
 2e2:	83 f8 10             	cmp    $0x10,%eax
 2e5:	0f 84 1a ff ff ff    	je     205 <ls+0x157>
        printf(1, "ls: cannot stat %s\n", buf);
        continue;
      }
      printf(1, "%s %d %d %d\n", fmtname(buf), st.type, st.ino, st.size);
    }
    break;
 2eb:	90                   	nop
  }
  close(fd);
 2ec:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 2ef:	89 04 24             	mov    %eax,(%esp)
 2f2:	e8 e9 02 00 00       	call   5e0 <close>
}
 2f7:	81 c4 5c 02 00 00    	add    $0x25c,%esp
 2fd:	5b                   	pop    %ebx
 2fe:	5e                   	pop    %esi
 2ff:	5f                   	pop    %edi
 300:	5d                   	pop    %ebp
 301:	c3                   	ret    

00000302 <main>:

int
main(int argc, char *argv[])
{
 302:	55                   	push   %ebp
 303:	89 e5                	mov    %esp,%ebp
 305:	83 e4 f0             	and    $0xfffffff0,%esp
 308:	83 ec 20             	sub    $0x20,%esp
  int i;

  if(argc < 2){
 30b:	83 7d 08 01          	cmpl   $0x1,0x8(%ebp)
 30f:	7f 11                	jg     322 <main+0x20>
    ls(".");
 311:	c7 04 24 83 0b 00 00 	movl   $0xb83,(%esp)
 318:	e8 91 fd ff ff       	call   ae <ls>
    exit();
 31d:	e8 96 02 00 00       	call   5b8 <exit>
  }
  for(i=1; i<argc; i++)
 322:	c7 44 24 1c 01 00 00 	movl   $0x1,0x1c(%esp)
 329:	00 
 32a:	eb 19                	jmp    345 <main+0x43>
    ls(argv[i]);
 32c:	8b 44 24 1c          	mov    0x1c(%esp),%eax
 330:	c1 e0 02             	shl    $0x2,%eax
 333:	03 45 0c             	add    0xc(%ebp),%eax
 336:	8b 00                	mov    (%eax),%eax
 338:	89 04 24             	mov    %eax,(%esp)
 33b:	e8 6e fd ff ff       	call   ae <ls>

  if(argc < 2){
    ls(".");
    exit();
  }
  for(i=1; i<argc; i++)
 340:	83 44 24 1c 01       	addl   $0x1,0x1c(%esp)
 345:	8b 44 24 1c          	mov    0x1c(%esp),%eax
 349:	3b 45 08             	cmp    0x8(%ebp),%eax
 34c:	7c de                	jl     32c <main+0x2a>
    ls(argv[i]);
  exit();
 34e:	e8 65 02 00 00       	call   5b8 <exit>
 353:	90                   	nop

00000354 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
 354:	55                   	push   %ebp
 355:	89 e5                	mov    %esp,%ebp
 357:	57                   	push   %edi
 358:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
 359:	8b 4d 08             	mov    0x8(%ebp),%ecx
 35c:	8b 55 10             	mov    0x10(%ebp),%edx
 35f:	8b 45 0c             	mov    0xc(%ebp),%eax
 362:	89 cb                	mov    %ecx,%ebx
 364:	89 df                	mov    %ebx,%edi
 366:	89 d1                	mov    %edx,%ecx
 368:	fc                   	cld    
 369:	f3 aa                	rep stos %al,%es:(%edi)
 36b:	89 ca                	mov    %ecx,%edx
 36d:	89 fb                	mov    %edi,%ebx
 36f:	89 5d 08             	mov    %ebx,0x8(%ebp)
 372:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
 375:	5b                   	pop    %ebx
 376:	5f                   	pop    %edi
 377:	5d                   	pop    %ebp
 378:	c3                   	ret    

00000379 <strcpy>:
#include "user.h"
#include "x86.h"

char*
strcpy(char *s, char *t)
{
 379:	55                   	push   %ebp
 37a:	89 e5                	mov    %esp,%ebp
 37c:	83 ec 10             	sub    $0x10,%esp
  char *os;

  os = s;
 37f:	8b 45 08             	mov    0x8(%ebp),%eax
 382:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while((*s++ = *t++) != 0)
 385:	90                   	nop
 386:	8b 45 0c             	mov    0xc(%ebp),%eax
 389:	0f b6 10             	movzbl (%eax),%edx
 38c:	8b 45 08             	mov    0x8(%ebp),%eax
 38f:	88 10                	mov    %dl,(%eax)
 391:	8b 45 08             	mov    0x8(%ebp),%eax
 394:	0f b6 00             	movzbl (%eax),%eax
 397:	84 c0                	test   %al,%al
 399:	0f 95 c0             	setne  %al
 39c:	83 45 08 01          	addl   $0x1,0x8(%ebp)
 3a0:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
 3a4:	84 c0                	test   %al,%al
 3a6:	75 de                	jne    386 <strcpy+0xd>
    ;
  return os;
 3a8:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
 3ab:	c9                   	leave  
 3ac:	c3                   	ret    

000003ad <strcmp>:

int
strcmp(const char *p, const char *q)
{
 3ad:	55                   	push   %ebp
 3ae:	89 e5                	mov    %esp,%ebp
  while(*p && *p == *q)
 3b0:	eb 08                	jmp    3ba <strcmp+0xd>
    p++, q++;
 3b2:	83 45 08 01          	addl   $0x1,0x8(%ebp)
 3b6:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
  while(*p && *p == *q)
 3ba:	8b 45 08             	mov    0x8(%ebp),%eax
 3bd:	0f b6 00             	movzbl (%eax),%eax
 3c0:	84 c0                	test   %al,%al
 3c2:	74 10                	je     3d4 <strcmp+0x27>
 3c4:	8b 45 08             	mov    0x8(%ebp),%eax
 3c7:	0f b6 10             	movzbl (%eax),%edx
 3ca:	8b 45 0c             	mov    0xc(%ebp),%eax
 3cd:	0f b6 00             	movzbl (%eax),%eax
 3d0:	38 c2                	cmp    %al,%dl
 3d2:	74 de                	je     3b2 <strcmp+0x5>
    p++, q++;
  return (uchar)*p - (uchar)*q;
 3d4:	8b 45 08             	mov    0x8(%ebp),%eax
 3d7:	0f b6 00             	movzbl (%eax),%eax
 3da:	0f b6 d0             	movzbl %al,%edx
 3dd:	8b 45 0c             	mov    0xc(%ebp),%eax
 3e0:	0f b6 00             	movzbl (%eax),%eax
 3e3:	0f b6 c0             	movzbl %al,%eax
 3e6:	89 d1                	mov    %edx,%ecx
 3e8:	29 c1                	sub    %eax,%ecx
 3ea:	89 c8                	mov    %ecx,%eax
}
 3ec:	5d                   	pop    %ebp
 3ed:	c3                   	ret    

000003ee <strlen>:

uint
strlen(char *s)
{
 3ee:	55                   	push   %ebp
 3ef:	89 e5                	mov    %esp,%ebp
 3f1:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
 3f4:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
 3fb:	eb 04                	jmp    401 <strlen+0x13>
 3fd:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
 401:	8b 45 fc             	mov    -0x4(%ebp),%eax
 404:	03 45 08             	add    0x8(%ebp),%eax
 407:	0f b6 00             	movzbl (%eax),%eax
 40a:	84 c0                	test   %al,%al
 40c:	75 ef                	jne    3fd <strlen+0xf>
    ;
  return n;
 40e:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
 411:	c9                   	leave  
 412:	c3                   	ret    

00000413 <memset>:

void*
memset(void *dst, int c, uint n)
{
 413:	55                   	push   %ebp
 414:	89 e5                	mov    %esp,%ebp
 416:	83 ec 0c             	sub    $0xc,%esp
  stosb(dst, c, n);
 419:	8b 45 10             	mov    0x10(%ebp),%eax
 41c:	89 44 24 08          	mov    %eax,0x8(%esp)
 420:	8b 45 0c             	mov    0xc(%ebp),%eax
 423:	89 44 24 04          	mov    %eax,0x4(%esp)
 427:	8b 45 08             	mov    0x8(%ebp),%eax
 42a:	89 04 24             	mov    %eax,(%esp)
 42d:	e8 22 ff ff ff       	call   354 <stosb>
  return dst;
 432:	8b 45 08             	mov    0x8(%ebp),%eax
}
 435:	c9                   	leave  
 436:	c3                   	ret    

00000437 <strchr>:

char*
strchr(const char *s, char c)
{
 437:	55                   	push   %ebp
 438:	89 e5                	mov    %esp,%ebp
 43a:	83 ec 04             	sub    $0x4,%esp
 43d:	8b 45 0c             	mov    0xc(%ebp),%eax
 440:	88 45 fc             	mov    %al,-0x4(%ebp)
  for(; *s; s++)
 443:	eb 14                	jmp    459 <strchr+0x22>
    if(*s == c)
 445:	8b 45 08             	mov    0x8(%ebp),%eax
 448:	0f b6 00             	movzbl (%eax),%eax
 44b:	3a 45 fc             	cmp    -0x4(%ebp),%al
 44e:	75 05                	jne    455 <strchr+0x1e>
      return (char*)s;
 450:	8b 45 08             	mov    0x8(%ebp),%eax
 453:	eb 13                	jmp    468 <strchr+0x31>
}

char*
strchr(const char *s, char c)
{
  for(; *s; s++)
 455:	83 45 08 01          	addl   $0x1,0x8(%ebp)
 459:	8b 45 08             	mov    0x8(%ebp),%eax
 45c:	0f b6 00             	movzbl (%eax),%eax
 45f:	84 c0                	test   %al,%al
 461:	75 e2                	jne    445 <strchr+0xe>
    if(*s == c)
      return (char*)s;
  return 0;
 463:	b8 00 00 00 00       	mov    $0x0,%eax
}
 468:	c9                   	leave  
 469:	c3                   	ret    

0000046a <gets>:

char*
gets(char *buf, int max)
{
 46a:	55                   	push   %ebp
 46b:	89 e5                	mov    %esp,%ebp
 46d:	83 ec 28             	sub    $0x28,%esp
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 470:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
 477:	eb 44                	jmp    4bd <gets+0x53>
    cc = read(0, &c, 1);
 479:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
 480:	00 
 481:	8d 45 ef             	lea    -0x11(%ebp),%eax
 484:	89 44 24 04          	mov    %eax,0x4(%esp)
 488:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
 48f:	e8 3c 01 00 00       	call   5d0 <read>
 494:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(cc < 1)
 497:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 49b:	7e 2d                	jle    4ca <gets+0x60>
      break;
    buf[i++] = c;
 49d:	8b 45 f4             	mov    -0xc(%ebp),%eax
 4a0:	03 45 08             	add    0x8(%ebp),%eax
 4a3:	0f b6 55 ef          	movzbl -0x11(%ebp),%edx
 4a7:	88 10                	mov    %dl,(%eax)
 4a9:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
    if(c == '\n' || c == '\r')
 4ad:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 4b1:	3c 0a                	cmp    $0xa,%al
 4b3:	74 16                	je     4cb <gets+0x61>
 4b5:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 4b9:	3c 0d                	cmp    $0xd,%al
 4bb:	74 0e                	je     4cb <gets+0x61>
gets(char *buf, int max)
{
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 4bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
 4c0:	83 c0 01             	add    $0x1,%eax
 4c3:	3b 45 0c             	cmp    0xc(%ebp),%eax
 4c6:	7c b1                	jl     479 <gets+0xf>
 4c8:	eb 01                	jmp    4cb <gets+0x61>
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
 4ca:	90                   	nop
    buf[i++] = c;
    if(c == '\n' || c == '\r')
      break;
  }
  buf[i] = '\0';
 4cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
 4ce:	03 45 08             	add    0x8(%ebp),%eax
 4d1:	c6 00 00             	movb   $0x0,(%eax)
  return buf;
 4d4:	8b 45 08             	mov    0x8(%ebp),%eax
}
 4d7:	c9                   	leave  
 4d8:	c3                   	ret    

000004d9 <stat>:

int
stat(char *n, struct stat *st)
{
 4d9:	55                   	push   %ebp
 4da:	89 e5                	mov    %esp,%ebp
 4dc:	83 ec 28             	sub    $0x28,%esp
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 4df:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
 4e6:	00 
 4e7:	8b 45 08             	mov    0x8(%ebp),%eax
 4ea:	89 04 24             	mov    %eax,(%esp)
 4ed:	e8 06 01 00 00       	call   5f8 <open>
 4f2:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(fd < 0)
 4f5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 4f9:	79 07                	jns    502 <stat+0x29>
    return -1;
 4fb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
 500:	eb 23                	jmp    525 <stat+0x4c>
  r = fstat(fd, st);
 502:	8b 45 0c             	mov    0xc(%ebp),%eax
 505:	89 44 24 04          	mov    %eax,0x4(%esp)
 509:	8b 45 f4             	mov    -0xc(%ebp),%eax
 50c:	89 04 24             	mov    %eax,(%esp)
 50f:	e8 fc 00 00 00       	call   610 <fstat>
 514:	89 45 f0             	mov    %eax,-0x10(%ebp)
  close(fd);
 517:	8b 45 f4             	mov    -0xc(%ebp),%eax
 51a:	89 04 24             	mov    %eax,(%esp)
 51d:	e8 be 00 00 00       	call   5e0 <close>
  return r;
 522:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
 525:	c9                   	leave  
 526:	c3                   	ret    

00000527 <atoi>:

int
atoi(const char *s)
{
 527:	55                   	push   %ebp
 528:	89 e5                	mov    %esp,%ebp
 52a:	83 ec 10             	sub    $0x10,%esp
  int n;

  n = 0;
 52d:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  while('0' <= *s && *s <= '9')
 534:	eb 23                	jmp    559 <atoi+0x32>
    n = n*10 + *s++ - '0';
 536:	8b 55 fc             	mov    -0x4(%ebp),%edx
 539:	89 d0                	mov    %edx,%eax
 53b:	c1 e0 02             	shl    $0x2,%eax
 53e:	01 d0                	add    %edx,%eax
 540:	01 c0                	add    %eax,%eax
 542:	89 c2                	mov    %eax,%edx
 544:	8b 45 08             	mov    0x8(%ebp),%eax
 547:	0f b6 00             	movzbl (%eax),%eax
 54a:	0f be c0             	movsbl %al,%eax
 54d:	01 d0                	add    %edx,%eax
 54f:	83 e8 30             	sub    $0x30,%eax
 552:	89 45 fc             	mov    %eax,-0x4(%ebp)
 555:	83 45 08 01          	addl   $0x1,0x8(%ebp)
atoi(const char *s)
{
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 559:	8b 45 08             	mov    0x8(%ebp),%eax
 55c:	0f b6 00             	movzbl (%eax),%eax
 55f:	3c 2f                	cmp    $0x2f,%al
 561:	7e 0a                	jle    56d <atoi+0x46>
 563:	8b 45 08             	mov    0x8(%ebp),%eax
 566:	0f b6 00             	movzbl (%eax),%eax
 569:	3c 39                	cmp    $0x39,%al
 56b:	7e c9                	jle    536 <atoi+0xf>
    n = n*10 + *s++ - '0';
  return n;
 56d:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
 570:	c9                   	leave  
 571:	c3                   	ret    

00000572 <memmove>:

void*
memmove(void *vdst, void *vsrc, int n)
{
 572:	55                   	push   %ebp
 573:	89 e5                	mov    %esp,%ebp
 575:	83 ec 10             	sub    $0x10,%esp
  char *dst, *src;
  
  dst = vdst;
 578:	8b 45 08             	mov    0x8(%ebp),%eax
 57b:	89 45 fc             	mov    %eax,-0x4(%ebp)
  src = vsrc;
 57e:	8b 45 0c             	mov    0xc(%ebp),%eax
 581:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0)
 584:	eb 13                	jmp    599 <memmove+0x27>
    *dst++ = *src++;
 586:	8b 45 f8             	mov    -0x8(%ebp),%eax
 589:	0f b6 10             	movzbl (%eax),%edx
 58c:	8b 45 fc             	mov    -0x4(%ebp),%eax
 58f:	88 10                	mov    %dl,(%eax)
 591:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
 595:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  char *dst, *src;
  
  dst = vdst;
  src = vsrc;
  while(n-- > 0)
 599:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
 59d:	0f 9f c0             	setg   %al
 5a0:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
 5a4:	84 c0                	test   %al,%al
 5a6:	75 de                	jne    586 <memmove+0x14>
    *dst++ = *src++;
  return vdst;
 5a8:	8b 45 08             	mov    0x8(%ebp),%eax
}
 5ab:	c9                   	leave  
 5ac:	c3                   	ret    
 5ad:	90                   	nop
 5ae:	90                   	nop
 5af:	90                   	nop

000005b0 <fork>:
  name: \
    movl $SYS_ ## name, %eax; \
    int $T_SYSCALL; \
    ret

SYSCALL(fork)
 5b0:	b8 01 00 00 00       	mov    $0x1,%eax
 5b5:	cd 40                	int    $0x40
 5b7:	c3                   	ret    

000005b8 <exit>:
SYSCALL(exit)
 5b8:	b8 02 00 00 00       	mov    $0x2,%eax
 5bd:	cd 40                	int    $0x40
 5bf:	c3                   	ret    

000005c0 <wait>:
SYSCALL(wait)
 5c0:	b8 03 00 00 00       	mov    $0x3,%eax
 5c5:	cd 40                	int    $0x40
 5c7:	c3                   	ret    

000005c8 <pipe>:
SYSCALL(pipe)
 5c8:	b8 04 00 00 00       	mov    $0x4,%eax
 5cd:	cd 40                	int    $0x40
 5cf:	c3                   	ret    

000005d0 <read>:
SYSCALL(read)
 5d0:	b8 05 00 00 00       	mov    $0x5,%eax
 5d5:	cd 40                	int    $0x40
 5d7:	c3                   	ret    

000005d8 <write>:
SYSCALL(write)
 5d8:	b8 10 00 00 00       	mov    $0x10,%eax
 5dd:	cd 40                	int    $0x40
 5df:	c3                   	ret    

000005e0 <close>:
SYSCALL(close)
 5e0:	b8 15 00 00 00       	mov    $0x15,%eax
 5e5:	cd 40                	int    $0x40
 5e7:	c3                   	ret    

000005e8 <kill>:
SYSCALL(kill)
 5e8:	b8 06 00 00 00       	mov    $0x6,%eax
 5ed:	cd 40                	int    $0x40
 5ef:	c3                   	ret    

000005f0 <exec>:
SYSCALL(exec)
 5f0:	b8 07 00 00 00       	mov    $0x7,%eax
 5f5:	cd 40                	int    $0x40
 5f7:	c3                   	ret    

000005f8 <open>:
SYSCALL(open)
 5f8:	b8 0f 00 00 00       	mov    $0xf,%eax
 5fd:	cd 40                	int    $0x40
 5ff:	c3                   	ret    

00000600 <mknod>:
SYSCALL(mknod)
 600:	b8 11 00 00 00       	mov    $0x11,%eax
 605:	cd 40                	int    $0x40
 607:	c3                   	ret    

00000608 <unlink>:
SYSCALL(unlink)
 608:	b8 12 00 00 00       	mov    $0x12,%eax
 60d:	cd 40                	int    $0x40
 60f:	c3                   	ret    

00000610 <fstat>:
SYSCALL(fstat)
 610:	b8 08 00 00 00       	mov    $0x8,%eax
 615:	cd 40                	int    $0x40
 617:	c3                   	ret    

00000618 <link>:
SYSCALL(link)
 618:	b8 13 00 00 00       	mov    $0x13,%eax
 61d:	cd 40                	int    $0x40
 61f:	c3                   	ret    

00000620 <mkdir>:
SYSCALL(mkdir)
 620:	b8 14 00 00 00       	mov    $0x14,%eax
 625:	cd 40                	int    $0x40
 627:	c3                   	ret    

00000628 <chdir>:
SYSCALL(chdir)
 628:	b8 09 00 00 00       	mov    $0x9,%eax
 62d:	cd 40                	int    $0x40
 62f:	c3                   	ret    

00000630 <dup>:
SYSCALL(dup)
 630:	b8 0a 00 00 00       	mov    $0xa,%eax
 635:	cd 40                	int    $0x40
 637:	c3                   	ret    

00000638 <getpid>:
SYSCALL(getpid)
 638:	b8 0b 00 00 00       	mov    $0xb,%eax
 63d:	cd 40                	int    $0x40
 63f:	c3                   	ret    

00000640 <sbrk>:
SYSCALL(sbrk)
 640:	b8 0c 00 00 00       	mov    $0xc,%eax
 645:	cd 40                	int    $0x40
 647:	c3                   	ret    

00000648 <sleep>:
SYSCALL(sleep)
 648:	b8 0d 00 00 00       	mov    $0xd,%eax
 64d:	cd 40                	int    $0x40
 64f:	c3                   	ret    

00000650 <uptime>:
SYSCALL(uptime)
 650:	b8 0e 00 00 00       	mov    $0xe,%eax
 655:	cd 40                	int    $0x40
 657:	c3                   	ret    

00000658 <enableSwapping>:
SYSCALL(enableSwapping)
 658:	b8 16 00 00 00       	mov    $0x16,%eax
 65d:	cd 40                	int    $0x40
 65f:	c3                   	ret    

00000660 <disableSwapping>:
SYSCALL(disableSwapping)
 660:	b8 17 00 00 00       	mov    $0x17,%eax
 665:	cd 40                	int    $0x40
 667:	c3                   	ret    

00000668 <sleep2>:
SYSCALL(sleep2)
 668:	b8 18 00 00 00       	mov    $0x18,%eax
 66d:	cd 40                	int    $0x40
 66f:	c3                   	ret    

00000670 <wakeup2>:
SYSCALL(wakeup2)
 670:	b8 19 00 00 00       	mov    $0x19,%eax
 675:	cd 40                	int    $0x40
 677:	c3                   	ret    

00000678 <getAllocatedPages>:
SYSCALL(getAllocatedPages)
 678:	b8 1a 00 00 00       	mov    $0x1a,%eax
 67d:	cd 40                	int    $0x40
 67f:	c3                   	ret    

00000680 <shmget>:
SYSCALL(shmget)
 680:	b8 1b 00 00 00       	mov    $0x1b,%eax
 685:	cd 40                	int    $0x40
 687:	c3                   	ret    

00000688 <shmdel>:
SYSCALL(shmdel)
 688:	b8 1c 00 00 00       	mov    $0x1c,%eax
 68d:	cd 40                	int    $0x40
 68f:	c3                   	ret    

00000690 <shmat>:
SYSCALL(shmat)
 690:	b8 1d 00 00 00       	mov    $0x1d,%eax
 695:	cd 40                	int    $0x40
 697:	c3                   	ret    

00000698 <shmdt>:
 698:	b8 1e 00 00 00       	mov    $0x1e,%eax
 69d:	cd 40                	int    $0x40
 69f:	c3                   	ret    

000006a0 <putc>:
#include "stat.h"
#include "user.h"

static void
putc(int fd, char c)
{
 6a0:	55                   	push   %ebp
 6a1:	89 e5                	mov    %esp,%ebp
 6a3:	83 ec 28             	sub    $0x28,%esp
 6a6:	8b 45 0c             	mov    0xc(%ebp),%eax
 6a9:	88 45 f4             	mov    %al,-0xc(%ebp)
  write(fd, &c, 1);
 6ac:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
 6b3:	00 
 6b4:	8d 45 f4             	lea    -0xc(%ebp),%eax
 6b7:	89 44 24 04          	mov    %eax,0x4(%esp)
 6bb:	8b 45 08             	mov    0x8(%ebp),%eax
 6be:	89 04 24             	mov    %eax,(%esp)
 6c1:	e8 12 ff ff ff       	call   5d8 <write>
}
 6c6:	c9                   	leave  
 6c7:	c3                   	ret    

000006c8 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 6c8:	55                   	push   %ebp
 6c9:	89 e5                	mov    %esp,%ebp
 6cb:	83 ec 48             	sub    $0x48,%esp
  static char digits[] = "0123456789ABCDEF";
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
 6ce:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  if(sgn && xx < 0){
 6d5:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
 6d9:	74 17                	je     6f2 <printint+0x2a>
 6db:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
 6df:	79 11                	jns    6f2 <printint+0x2a>
    neg = 1;
 6e1:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
    x = -xx;
 6e8:	8b 45 0c             	mov    0xc(%ebp),%eax
 6eb:	f7 d8                	neg    %eax
 6ed:	89 45 ec             	mov    %eax,-0x14(%ebp)
 6f0:	eb 06                	jmp    6f8 <printint+0x30>
  } else {
    x = xx;
 6f2:	8b 45 0c             	mov    0xc(%ebp),%eax
 6f5:	89 45 ec             	mov    %eax,-0x14(%ebp)
  }

  i = 0;
 6f8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  do{
    buf[i++] = digits[x % base];
 6ff:	8b 4d 10             	mov    0x10(%ebp),%ecx
 702:	8b 45 ec             	mov    -0x14(%ebp),%eax
 705:	ba 00 00 00 00       	mov    $0x0,%edx
 70a:	f7 f1                	div    %ecx
 70c:	89 d0                	mov    %edx,%eax
 70e:	0f b6 90 1c 0e 00 00 	movzbl 0xe1c(%eax),%edx
 715:	8d 45 dc             	lea    -0x24(%ebp),%eax
 718:	03 45 f4             	add    -0xc(%ebp),%eax
 71b:	88 10                	mov    %dl,(%eax)
 71d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  }while((x /= base) != 0);
 721:	8b 55 10             	mov    0x10(%ebp),%edx
 724:	89 55 d4             	mov    %edx,-0x2c(%ebp)
 727:	8b 45 ec             	mov    -0x14(%ebp),%eax
 72a:	ba 00 00 00 00       	mov    $0x0,%edx
 72f:	f7 75 d4             	divl   -0x2c(%ebp)
 732:	89 45 ec             	mov    %eax,-0x14(%ebp)
 735:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
 739:	75 c4                	jne    6ff <printint+0x37>
  if(neg)
 73b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 73f:	74 2a                	je     76b <printint+0xa3>
    buf[i++] = '-';
 741:	8d 45 dc             	lea    -0x24(%ebp),%eax
 744:	03 45 f4             	add    -0xc(%ebp),%eax
 747:	c6 00 2d             	movb   $0x2d,(%eax)
 74a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)

  while(--i >= 0)
 74e:	eb 1b                	jmp    76b <printint+0xa3>
    putc(fd, buf[i]);
 750:	8d 45 dc             	lea    -0x24(%ebp),%eax
 753:	03 45 f4             	add    -0xc(%ebp),%eax
 756:	0f b6 00             	movzbl (%eax),%eax
 759:	0f be c0             	movsbl %al,%eax
 75c:	89 44 24 04          	mov    %eax,0x4(%esp)
 760:	8b 45 08             	mov    0x8(%ebp),%eax
 763:	89 04 24             	mov    %eax,(%esp)
 766:	e8 35 ff ff ff       	call   6a0 <putc>
    buf[i++] = digits[x % base];
  }while((x /= base) != 0);
  if(neg)
    buf[i++] = '-';

  while(--i >= 0)
 76b:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
 76f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 773:	79 db                	jns    750 <printint+0x88>
    putc(fd, buf[i]);
}
 775:	c9                   	leave  
 776:	c3                   	ret    

00000777 <printf>:

// Print to the given fd. Only understands %d, %x, %p, %s.
void
printf(int fd, char *fmt, ...)
{
 777:	55                   	push   %ebp
 778:	89 e5                	mov    %esp,%ebp
 77a:	83 ec 38             	sub    $0x38,%esp
  char *s;
  int c, i, state;
  uint *ap;

  state = 0;
 77d:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  ap = (uint*)(void*)&fmt + 1;
 784:	8d 45 0c             	lea    0xc(%ebp),%eax
 787:	83 c0 04             	add    $0x4,%eax
 78a:	89 45 e8             	mov    %eax,-0x18(%ebp)
  for(i = 0; fmt[i]; i++){
 78d:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
 794:	e9 7d 01 00 00       	jmp    916 <printf+0x19f>
    c = fmt[i] & 0xff;
 799:	8b 55 0c             	mov    0xc(%ebp),%edx
 79c:	8b 45 f0             	mov    -0x10(%ebp),%eax
 79f:	01 d0                	add    %edx,%eax
 7a1:	0f b6 00             	movzbl (%eax),%eax
 7a4:	0f be c0             	movsbl %al,%eax
 7a7:	25 ff 00 00 00       	and    $0xff,%eax
 7ac:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(state == 0){
 7af:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
 7b3:	75 2c                	jne    7e1 <printf+0x6a>
      if(c == '%'){
 7b5:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
 7b9:	75 0c                	jne    7c7 <printf+0x50>
        state = '%';
 7bb:	c7 45 ec 25 00 00 00 	movl   $0x25,-0x14(%ebp)
 7c2:	e9 4b 01 00 00       	jmp    912 <printf+0x19b>
      } else {
        putc(fd, c);
 7c7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 7ca:	0f be c0             	movsbl %al,%eax
 7cd:	89 44 24 04          	mov    %eax,0x4(%esp)
 7d1:	8b 45 08             	mov    0x8(%ebp),%eax
 7d4:	89 04 24             	mov    %eax,(%esp)
 7d7:	e8 c4 fe ff ff       	call   6a0 <putc>
 7dc:	e9 31 01 00 00       	jmp    912 <printf+0x19b>
      }
    } else if(state == '%'){
 7e1:	83 7d ec 25          	cmpl   $0x25,-0x14(%ebp)
 7e5:	0f 85 27 01 00 00    	jne    912 <printf+0x19b>
      if(c == 'd'){
 7eb:	83 7d e4 64          	cmpl   $0x64,-0x1c(%ebp)
 7ef:	75 2d                	jne    81e <printf+0xa7>
        printint(fd, *ap, 10, 1);
 7f1:	8b 45 e8             	mov    -0x18(%ebp),%eax
 7f4:	8b 00                	mov    (%eax),%eax
 7f6:	c7 44 24 0c 01 00 00 	movl   $0x1,0xc(%esp)
 7fd:	00 
 7fe:	c7 44 24 08 0a 00 00 	movl   $0xa,0x8(%esp)
 805:	00 
 806:	89 44 24 04          	mov    %eax,0x4(%esp)
 80a:	8b 45 08             	mov    0x8(%ebp),%eax
 80d:	89 04 24             	mov    %eax,(%esp)
 810:	e8 b3 fe ff ff       	call   6c8 <printint>
        ap++;
 815:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 819:	e9 ed 00 00 00       	jmp    90b <printf+0x194>
      } else if(c == 'x' || c == 'p'){
 81e:	83 7d e4 78          	cmpl   $0x78,-0x1c(%ebp)
 822:	74 06                	je     82a <printf+0xb3>
 824:	83 7d e4 70          	cmpl   $0x70,-0x1c(%ebp)
 828:	75 2d                	jne    857 <printf+0xe0>
        printint(fd, *ap, 16, 0);
 82a:	8b 45 e8             	mov    -0x18(%ebp),%eax
 82d:	8b 00                	mov    (%eax),%eax
 82f:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
 836:	00 
 837:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
 83e:	00 
 83f:	89 44 24 04          	mov    %eax,0x4(%esp)
 843:	8b 45 08             	mov    0x8(%ebp),%eax
 846:	89 04 24             	mov    %eax,(%esp)
 849:	e8 7a fe ff ff       	call   6c8 <printint>
        ap++;
 84e:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 852:	e9 b4 00 00 00       	jmp    90b <printf+0x194>
      } else if(c == 's'){
 857:	83 7d e4 73          	cmpl   $0x73,-0x1c(%ebp)
 85b:	75 46                	jne    8a3 <printf+0x12c>
        s = (char*)*ap;
 85d:	8b 45 e8             	mov    -0x18(%ebp),%eax
 860:	8b 00                	mov    (%eax),%eax
 862:	89 45 f4             	mov    %eax,-0xc(%ebp)
        ap++;
 865:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
        if(s == 0)
 869:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 86d:	75 27                	jne    896 <printf+0x11f>
          s = "(null)";
 86f:	c7 45 f4 85 0b 00 00 	movl   $0xb85,-0xc(%ebp)
        while(*s != 0){
 876:	eb 1e                	jmp    896 <printf+0x11f>
          putc(fd, *s);
 878:	8b 45 f4             	mov    -0xc(%ebp),%eax
 87b:	0f b6 00             	movzbl (%eax),%eax
 87e:	0f be c0             	movsbl %al,%eax
 881:	89 44 24 04          	mov    %eax,0x4(%esp)
 885:	8b 45 08             	mov    0x8(%ebp),%eax
 888:	89 04 24             	mov    %eax,(%esp)
 88b:	e8 10 fe ff ff       	call   6a0 <putc>
          s++;
 890:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
 894:	eb 01                	jmp    897 <printf+0x120>
      } else if(c == 's'){
        s = (char*)*ap;
        ap++;
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 896:	90                   	nop
 897:	8b 45 f4             	mov    -0xc(%ebp),%eax
 89a:	0f b6 00             	movzbl (%eax),%eax
 89d:	84 c0                	test   %al,%al
 89f:	75 d7                	jne    878 <printf+0x101>
 8a1:	eb 68                	jmp    90b <printf+0x194>
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 8a3:	83 7d e4 63          	cmpl   $0x63,-0x1c(%ebp)
 8a7:	75 1d                	jne    8c6 <printf+0x14f>
        putc(fd, *ap);
 8a9:	8b 45 e8             	mov    -0x18(%ebp),%eax
 8ac:	8b 00                	mov    (%eax),%eax
 8ae:	0f be c0             	movsbl %al,%eax
 8b1:	89 44 24 04          	mov    %eax,0x4(%esp)
 8b5:	8b 45 08             	mov    0x8(%ebp),%eax
 8b8:	89 04 24             	mov    %eax,(%esp)
 8bb:	e8 e0 fd ff ff       	call   6a0 <putc>
        ap++;
 8c0:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 8c4:	eb 45                	jmp    90b <printf+0x194>
      } else if(c == '%'){
 8c6:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
 8ca:	75 17                	jne    8e3 <printf+0x16c>
        putc(fd, c);
 8cc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 8cf:	0f be c0             	movsbl %al,%eax
 8d2:	89 44 24 04          	mov    %eax,0x4(%esp)
 8d6:	8b 45 08             	mov    0x8(%ebp),%eax
 8d9:	89 04 24             	mov    %eax,(%esp)
 8dc:	e8 bf fd ff ff       	call   6a0 <putc>
 8e1:	eb 28                	jmp    90b <printf+0x194>
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 8e3:	c7 44 24 04 25 00 00 	movl   $0x25,0x4(%esp)
 8ea:	00 
 8eb:	8b 45 08             	mov    0x8(%ebp),%eax
 8ee:	89 04 24             	mov    %eax,(%esp)
 8f1:	e8 aa fd ff ff       	call   6a0 <putc>
        putc(fd, c);
 8f6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 8f9:	0f be c0             	movsbl %al,%eax
 8fc:	89 44 24 04          	mov    %eax,0x4(%esp)
 900:	8b 45 08             	mov    0x8(%ebp),%eax
 903:	89 04 24             	mov    %eax,(%esp)
 906:	e8 95 fd ff ff       	call   6a0 <putc>
      }
      state = 0;
 90b:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  int c, i, state;
  uint *ap;

  state = 0;
  ap = (uint*)(void*)&fmt + 1;
  for(i = 0; fmt[i]; i++){
 912:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
 916:	8b 55 0c             	mov    0xc(%ebp),%edx
 919:	8b 45 f0             	mov    -0x10(%ebp),%eax
 91c:	01 d0                	add    %edx,%eax
 91e:	0f b6 00             	movzbl (%eax),%eax
 921:	84 c0                	test   %al,%al
 923:	0f 85 70 fe ff ff    	jne    799 <printf+0x22>
        putc(fd, c);
      }
      state = 0;
    }
  }
}
 929:	c9                   	leave  
 92a:	c3                   	ret    
 92b:	90                   	nop

0000092c <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 92c:	55                   	push   %ebp
 92d:	89 e5                	mov    %esp,%ebp
 92f:	83 ec 10             	sub    $0x10,%esp
  Header *bp, *p;

  bp = (Header*)ap - 1;
 932:	8b 45 08             	mov    0x8(%ebp),%eax
 935:	83 e8 08             	sub    $0x8,%eax
 938:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 93b:	a1 48 0e 00 00       	mov    0xe48,%eax
 940:	89 45 fc             	mov    %eax,-0x4(%ebp)
 943:	eb 24                	jmp    969 <free+0x3d>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 945:	8b 45 fc             	mov    -0x4(%ebp),%eax
 948:	8b 00                	mov    (%eax),%eax
 94a:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 94d:	77 12                	ja     961 <free+0x35>
 94f:	8b 45 f8             	mov    -0x8(%ebp),%eax
 952:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 955:	77 24                	ja     97b <free+0x4f>
 957:	8b 45 fc             	mov    -0x4(%ebp),%eax
 95a:	8b 00                	mov    (%eax),%eax
 95c:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 95f:	77 1a                	ja     97b <free+0x4f>
free(void *ap)
{
  Header *bp, *p;

  bp = (Header*)ap - 1;
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 961:	8b 45 fc             	mov    -0x4(%ebp),%eax
 964:	8b 00                	mov    (%eax),%eax
 966:	89 45 fc             	mov    %eax,-0x4(%ebp)
 969:	8b 45 f8             	mov    -0x8(%ebp),%eax
 96c:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 96f:	76 d4                	jbe    945 <free+0x19>
 971:	8b 45 fc             	mov    -0x4(%ebp),%eax
 974:	8b 00                	mov    (%eax),%eax
 976:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 979:	76 ca                	jbe    945 <free+0x19>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
 97b:	8b 45 f8             	mov    -0x8(%ebp),%eax
 97e:	8b 40 04             	mov    0x4(%eax),%eax
 981:	c1 e0 03             	shl    $0x3,%eax
 984:	89 c2                	mov    %eax,%edx
 986:	03 55 f8             	add    -0x8(%ebp),%edx
 989:	8b 45 fc             	mov    -0x4(%ebp),%eax
 98c:	8b 00                	mov    (%eax),%eax
 98e:	39 c2                	cmp    %eax,%edx
 990:	75 24                	jne    9b6 <free+0x8a>
    bp->s.size += p->s.ptr->s.size;
 992:	8b 45 f8             	mov    -0x8(%ebp),%eax
 995:	8b 50 04             	mov    0x4(%eax),%edx
 998:	8b 45 fc             	mov    -0x4(%ebp),%eax
 99b:	8b 00                	mov    (%eax),%eax
 99d:	8b 40 04             	mov    0x4(%eax),%eax
 9a0:	01 c2                	add    %eax,%edx
 9a2:	8b 45 f8             	mov    -0x8(%ebp),%eax
 9a5:	89 50 04             	mov    %edx,0x4(%eax)
    bp->s.ptr = p->s.ptr->s.ptr;
 9a8:	8b 45 fc             	mov    -0x4(%ebp),%eax
 9ab:	8b 00                	mov    (%eax),%eax
 9ad:	8b 10                	mov    (%eax),%edx
 9af:	8b 45 f8             	mov    -0x8(%ebp),%eax
 9b2:	89 10                	mov    %edx,(%eax)
 9b4:	eb 0a                	jmp    9c0 <free+0x94>
  } else
    bp->s.ptr = p->s.ptr;
 9b6:	8b 45 fc             	mov    -0x4(%ebp),%eax
 9b9:	8b 10                	mov    (%eax),%edx
 9bb:	8b 45 f8             	mov    -0x8(%ebp),%eax
 9be:	89 10                	mov    %edx,(%eax)
  if(p + p->s.size == bp){
 9c0:	8b 45 fc             	mov    -0x4(%ebp),%eax
 9c3:	8b 40 04             	mov    0x4(%eax),%eax
 9c6:	c1 e0 03             	shl    $0x3,%eax
 9c9:	03 45 fc             	add    -0x4(%ebp),%eax
 9cc:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 9cf:	75 20                	jne    9f1 <free+0xc5>
    p->s.size += bp->s.size;
 9d1:	8b 45 fc             	mov    -0x4(%ebp),%eax
 9d4:	8b 50 04             	mov    0x4(%eax),%edx
 9d7:	8b 45 f8             	mov    -0x8(%ebp),%eax
 9da:	8b 40 04             	mov    0x4(%eax),%eax
 9dd:	01 c2                	add    %eax,%edx
 9df:	8b 45 fc             	mov    -0x4(%ebp),%eax
 9e2:	89 50 04             	mov    %edx,0x4(%eax)
    p->s.ptr = bp->s.ptr;
 9e5:	8b 45 f8             	mov    -0x8(%ebp),%eax
 9e8:	8b 10                	mov    (%eax),%edx
 9ea:	8b 45 fc             	mov    -0x4(%ebp),%eax
 9ed:	89 10                	mov    %edx,(%eax)
 9ef:	eb 08                	jmp    9f9 <free+0xcd>
  } else
    p->s.ptr = bp;
 9f1:	8b 45 fc             	mov    -0x4(%ebp),%eax
 9f4:	8b 55 f8             	mov    -0x8(%ebp),%edx
 9f7:	89 10                	mov    %edx,(%eax)
  freep = p;
 9f9:	8b 45 fc             	mov    -0x4(%ebp),%eax
 9fc:	a3 48 0e 00 00       	mov    %eax,0xe48
}
 a01:	c9                   	leave  
 a02:	c3                   	ret    

00000a03 <morecore>:

static Header*
morecore(uint nu)
{
 a03:	55                   	push   %ebp
 a04:	89 e5                	mov    %esp,%ebp
 a06:	83 ec 28             	sub    $0x28,%esp
  char *p;
  Header *hp;

  if(nu < 4096)
 a09:	81 7d 08 ff 0f 00 00 	cmpl   $0xfff,0x8(%ebp)
 a10:	77 07                	ja     a19 <morecore+0x16>
    nu = 4096;
 a12:	c7 45 08 00 10 00 00 	movl   $0x1000,0x8(%ebp)
  p = sbrk(nu * sizeof(Header));
 a19:	8b 45 08             	mov    0x8(%ebp),%eax
 a1c:	c1 e0 03             	shl    $0x3,%eax
 a1f:	89 04 24             	mov    %eax,(%esp)
 a22:	e8 19 fc ff ff       	call   640 <sbrk>
 a27:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(p == (char*)-1)
 a2a:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
 a2e:	75 07                	jne    a37 <morecore+0x34>
    return 0;
 a30:	b8 00 00 00 00       	mov    $0x0,%eax
 a35:	eb 22                	jmp    a59 <morecore+0x56>
  hp = (Header*)p;
 a37:	8b 45 f4             	mov    -0xc(%ebp),%eax
 a3a:	89 45 f0             	mov    %eax,-0x10(%ebp)
  hp->s.size = nu;
 a3d:	8b 45 f0             	mov    -0x10(%ebp),%eax
 a40:	8b 55 08             	mov    0x8(%ebp),%edx
 a43:	89 50 04             	mov    %edx,0x4(%eax)
  free((void*)(hp + 1));
 a46:	8b 45 f0             	mov    -0x10(%ebp),%eax
 a49:	83 c0 08             	add    $0x8,%eax
 a4c:	89 04 24             	mov    %eax,(%esp)
 a4f:	e8 d8 fe ff ff       	call   92c <free>
  return freep;
 a54:	a1 48 0e 00 00       	mov    0xe48,%eax
}
 a59:	c9                   	leave  
 a5a:	c3                   	ret    

00000a5b <malloc>:

void*
malloc(uint nbytes)
{
 a5b:	55                   	push   %ebp
 a5c:	89 e5                	mov    %esp,%ebp
 a5e:	83 ec 28             	sub    $0x28,%esp
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 a61:	8b 45 08             	mov    0x8(%ebp),%eax
 a64:	83 c0 07             	add    $0x7,%eax
 a67:	c1 e8 03             	shr    $0x3,%eax
 a6a:	83 c0 01             	add    $0x1,%eax
 a6d:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((prevp = freep) == 0){
 a70:	a1 48 0e 00 00       	mov    0xe48,%eax
 a75:	89 45 f0             	mov    %eax,-0x10(%ebp)
 a78:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 a7c:	75 23                	jne    aa1 <malloc+0x46>
    base.s.ptr = freep = prevp = &base;
 a7e:	c7 45 f0 40 0e 00 00 	movl   $0xe40,-0x10(%ebp)
 a85:	8b 45 f0             	mov    -0x10(%ebp),%eax
 a88:	a3 48 0e 00 00       	mov    %eax,0xe48
 a8d:	a1 48 0e 00 00       	mov    0xe48,%eax
 a92:	a3 40 0e 00 00       	mov    %eax,0xe40
    base.s.size = 0;
 a97:	c7 05 44 0e 00 00 00 	movl   $0x0,0xe44
 a9e:	00 00 00 
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 aa1:	8b 45 f0             	mov    -0x10(%ebp),%eax
 aa4:	8b 00                	mov    (%eax),%eax
 aa6:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(p->s.size >= nunits){
 aa9:	8b 45 f4             	mov    -0xc(%ebp),%eax
 aac:	8b 40 04             	mov    0x4(%eax),%eax
 aaf:	3b 45 ec             	cmp    -0x14(%ebp),%eax
 ab2:	72 4d                	jb     b01 <malloc+0xa6>
      if(p->s.size == nunits)
 ab4:	8b 45 f4             	mov    -0xc(%ebp),%eax
 ab7:	8b 40 04             	mov    0x4(%eax),%eax
 aba:	3b 45 ec             	cmp    -0x14(%ebp),%eax
 abd:	75 0c                	jne    acb <malloc+0x70>
        prevp->s.ptr = p->s.ptr;
 abf:	8b 45 f4             	mov    -0xc(%ebp),%eax
 ac2:	8b 10                	mov    (%eax),%edx
 ac4:	8b 45 f0             	mov    -0x10(%ebp),%eax
 ac7:	89 10                	mov    %edx,(%eax)
 ac9:	eb 26                	jmp    af1 <malloc+0x96>
      else {
        p->s.size -= nunits;
 acb:	8b 45 f4             	mov    -0xc(%ebp),%eax
 ace:	8b 40 04             	mov    0x4(%eax),%eax
 ad1:	89 c2                	mov    %eax,%edx
 ad3:	2b 55 ec             	sub    -0x14(%ebp),%edx
 ad6:	8b 45 f4             	mov    -0xc(%ebp),%eax
 ad9:	89 50 04             	mov    %edx,0x4(%eax)
        p += p->s.size;
 adc:	8b 45 f4             	mov    -0xc(%ebp),%eax
 adf:	8b 40 04             	mov    0x4(%eax),%eax
 ae2:	c1 e0 03             	shl    $0x3,%eax
 ae5:	01 45 f4             	add    %eax,-0xc(%ebp)
        p->s.size = nunits;
 ae8:	8b 45 f4             	mov    -0xc(%ebp),%eax
 aeb:	8b 55 ec             	mov    -0x14(%ebp),%edx
 aee:	89 50 04             	mov    %edx,0x4(%eax)
      }
      freep = prevp;
 af1:	8b 45 f0             	mov    -0x10(%ebp),%eax
 af4:	a3 48 0e 00 00       	mov    %eax,0xe48
      return (void*)(p + 1);
 af9:	8b 45 f4             	mov    -0xc(%ebp),%eax
 afc:	83 c0 08             	add    $0x8,%eax
 aff:	eb 38                	jmp    b39 <malloc+0xde>
    }
    if(p == freep)
 b01:	a1 48 0e 00 00       	mov    0xe48,%eax
 b06:	39 45 f4             	cmp    %eax,-0xc(%ebp)
 b09:	75 1b                	jne    b26 <malloc+0xcb>
      if((p = morecore(nunits)) == 0)
 b0b:	8b 45 ec             	mov    -0x14(%ebp),%eax
 b0e:	89 04 24             	mov    %eax,(%esp)
 b11:	e8 ed fe ff ff       	call   a03 <morecore>
 b16:	89 45 f4             	mov    %eax,-0xc(%ebp)
 b19:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 b1d:	75 07                	jne    b26 <malloc+0xcb>
        return 0;
 b1f:	b8 00 00 00 00       	mov    $0x0,%eax
 b24:	eb 13                	jmp    b39 <malloc+0xde>
  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
  if((prevp = freep) == 0){
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 b26:	8b 45 f4             	mov    -0xc(%ebp),%eax
 b29:	89 45 f0             	mov    %eax,-0x10(%ebp)
 b2c:	8b 45 f4             	mov    -0xc(%ebp),%eax
 b2f:	8b 00                	mov    (%eax),%eax
 b31:	89 45 f4             	mov    %eax,-0xc(%ebp)
      return (void*)(p + 1);
    }
    if(p == freep)
      if((p = morecore(nunits)) == 0)
        return 0;
  }
 b34:	e9 70 ff ff ff       	jmp    aa9 <malloc+0x4e>
}
 b39:	c9                   	leave  
 b3a:	c3                   	ret    
