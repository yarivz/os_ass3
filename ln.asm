
_ln:     file format elf32-i386


Disassembly of section .text:

00000000 <main>:
#include "stat.h"
#include "user.h"

int
main(int argc, char *argv[])
{
   0:	55                   	push   %ebp
   1:	89 e5                	mov    %esp,%ebp
   3:	83 e4 f0             	and    $0xfffffff0,%esp
   6:	83 ec 10             	sub    $0x10,%esp
  if(argc != 3){
   9:	83 7d 08 03          	cmpl   $0x3,0x8(%ebp)
   d:	74 19                	je     28 <main+0x28>
    printf(2, "Usage: ln old new\n");
   f:	c7 44 24 04 43 08 00 	movl   $0x843,0x4(%esp)
  16:	00 
  17:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
  1e:	e8 5c 04 00 00       	call   47f <printf>
    exit();
  23:	e8 b8 02 00 00       	call   2e0 <exit>
  }
  if(link(argv[1], argv[2]) < 0)
  28:	8b 45 0c             	mov    0xc(%ebp),%eax
  2b:	83 c0 08             	add    $0x8,%eax
  2e:	8b 10                	mov    (%eax),%edx
  30:	8b 45 0c             	mov    0xc(%ebp),%eax
  33:	83 c0 04             	add    $0x4,%eax
  36:	8b 00                	mov    (%eax),%eax
  38:	89 54 24 04          	mov    %edx,0x4(%esp)
  3c:	89 04 24             	mov    %eax,(%esp)
  3f:	e8 fc 02 00 00       	call   340 <link>
  44:	85 c0                	test   %eax,%eax
  46:	79 2c                	jns    74 <main+0x74>
    printf(2, "link %s %s: failed\n", argv[1], argv[2]);
  48:	8b 45 0c             	mov    0xc(%ebp),%eax
  4b:	83 c0 08             	add    $0x8,%eax
  4e:	8b 10                	mov    (%eax),%edx
  50:	8b 45 0c             	mov    0xc(%ebp),%eax
  53:	83 c0 04             	add    $0x4,%eax
  56:	8b 00                	mov    (%eax),%eax
  58:	89 54 24 0c          	mov    %edx,0xc(%esp)
  5c:	89 44 24 08          	mov    %eax,0x8(%esp)
  60:	c7 44 24 04 56 08 00 	movl   $0x856,0x4(%esp)
  67:	00 
  68:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
  6f:	e8 0b 04 00 00       	call   47f <printf>
  exit();
  74:	e8 67 02 00 00       	call   2e0 <exit>
  79:	90                   	nop
  7a:	90                   	nop
  7b:	90                   	nop

0000007c <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
  7c:	55                   	push   %ebp
  7d:	89 e5                	mov    %esp,%ebp
  7f:	57                   	push   %edi
  80:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
  81:	8b 4d 08             	mov    0x8(%ebp),%ecx
  84:	8b 55 10             	mov    0x10(%ebp),%edx
  87:	8b 45 0c             	mov    0xc(%ebp),%eax
  8a:	89 cb                	mov    %ecx,%ebx
  8c:	89 df                	mov    %ebx,%edi
  8e:	89 d1                	mov    %edx,%ecx
  90:	fc                   	cld    
  91:	f3 aa                	rep stos %al,%es:(%edi)
  93:	89 ca                	mov    %ecx,%edx
  95:	89 fb                	mov    %edi,%ebx
  97:	89 5d 08             	mov    %ebx,0x8(%ebp)
  9a:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
  9d:	5b                   	pop    %ebx
  9e:	5f                   	pop    %edi
  9f:	5d                   	pop    %ebp
  a0:	c3                   	ret    

000000a1 <strcpy>:
#include "user.h"
#include "x86.h"

char*
strcpy(char *s, char *t)
{
  a1:	55                   	push   %ebp
  a2:	89 e5                	mov    %esp,%ebp
  a4:	83 ec 10             	sub    $0x10,%esp
  char *os;

  os = s;
  a7:	8b 45 08             	mov    0x8(%ebp),%eax
  aa:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while((*s++ = *t++) != 0)
  ad:	90                   	nop
  ae:	8b 45 0c             	mov    0xc(%ebp),%eax
  b1:	0f b6 10             	movzbl (%eax),%edx
  b4:	8b 45 08             	mov    0x8(%ebp),%eax
  b7:	88 10                	mov    %dl,(%eax)
  b9:	8b 45 08             	mov    0x8(%ebp),%eax
  bc:	0f b6 00             	movzbl (%eax),%eax
  bf:	84 c0                	test   %al,%al
  c1:	0f 95 c0             	setne  %al
  c4:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  c8:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  cc:	84 c0                	test   %al,%al
  ce:	75 de                	jne    ae <strcpy+0xd>
    ;
  return os;
  d0:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  d3:	c9                   	leave  
  d4:	c3                   	ret    

000000d5 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  d5:	55                   	push   %ebp
  d6:	89 e5                	mov    %esp,%ebp
  while(*p && *p == *q)
  d8:	eb 08                	jmp    e2 <strcmp+0xd>
    p++, q++;
  da:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  de:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
  while(*p && *p == *q)
  e2:	8b 45 08             	mov    0x8(%ebp),%eax
  e5:	0f b6 00             	movzbl (%eax),%eax
  e8:	84 c0                	test   %al,%al
  ea:	74 10                	je     fc <strcmp+0x27>
  ec:	8b 45 08             	mov    0x8(%ebp),%eax
  ef:	0f b6 10             	movzbl (%eax),%edx
  f2:	8b 45 0c             	mov    0xc(%ebp),%eax
  f5:	0f b6 00             	movzbl (%eax),%eax
  f8:	38 c2                	cmp    %al,%dl
  fa:	74 de                	je     da <strcmp+0x5>
    p++, q++;
  return (uchar)*p - (uchar)*q;
  fc:	8b 45 08             	mov    0x8(%ebp),%eax
  ff:	0f b6 00             	movzbl (%eax),%eax
 102:	0f b6 d0             	movzbl %al,%edx
 105:	8b 45 0c             	mov    0xc(%ebp),%eax
 108:	0f b6 00             	movzbl (%eax),%eax
 10b:	0f b6 c0             	movzbl %al,%eax
 10e:	89 d1                	mov    %edx,%ecx
 110:	29 c1                	sub    %eax,%ecx
 112:	89 c8                	mov    %ecx,%eax
}
 114:	5d                   	pop    %ebp
 115:	c3                   	ret    

00000116 <strlen>:

uint
strlen(char *s)
{
 116:	55                   	push   %ebp
 117:	89 e5                	mov    %esp,%ebp
 119:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
 11c:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
 123:	eb 04                	jmp    129 <strlen+0x13>
 125:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
 129:	8b 45 fc             	mov    -0x4(%ebp),%eax
 12c:	03 45 08             	add    0x8(%ebp),%eax
 12f:	0f b6 00             	movzbl (%eax),%eax
 132:	84 c0                	test   %al,%al
 134:	75 ef                	jne    125 <strlen+0xf>
    ;
  return n;
 136:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
 139:	c9                   	leave  
 13a:	c3                   	ret    

0000013b <memset>:

void*
memset(void *dst, int c, uint n)
{
 13b:	55                   	push   %ebp
 13c:	89 e5                	mov    %esp,%ebp
 13e:	83 ec 0c             	sub    $0xc,%esp
  stosb(dst, c, n);
 141:	8b 45 10             	mov    0x10(%ebp),%eax
 144:	89 44 24 08          	mov    %eax,0x8(%esp)
 148:	8b 45 0c             	mov    0xc(%ebp),%eax
 14b:	89 44 24 04          	mov    %eax,0x4(%esp)
 14f:	8b 45 08             	mov    0x8(%ebp),%eax
 152:	89 04 24             	mov    %eax,(%esp)
 155:	e8 22 ff ff ff       	call   7c <stosb>
  return dst;
 15a:	8b 45 08             	mov    0x8(%ebp),%eax
}
 15d:	c9                   	leave  
 15e:	c3                   	ret    

0000015f <strchr>:

char*
strchr(const char *s, char c)
{
 15f:	55                   	push   %ebp
 160:	89 e5                	mov    %esp,%ebp
 162:	83 ec 04             	sub    $0x4,%esp
 165:	8b 45 0c             	mov    0xc(%ebp),%eax
 168:	88 45 fc             	mov    %al,-0x4(%ebp)
  for(; *s; s++)
 16b:	eb 14                	jmp    181 <strchr+0x22>
    if(*s == c)
 16d:	8b 45 08             	mov    0x8(%ebp),%eax
 170:	0f b6 00             	movzbl (%eax),%eax
 173:	3a 45 fc             	cmp    -0x4(%ebp),%al
 176:	75 05                	jne    17d <strchr+0x1e>
      return (char*)s;
 178:	8b 45 08             	mov    0x8(%ebp),%eax
 17b:	eb 13                	jmp    190 <strchr+0x31>
}

char*
strchr(const char *s, char c)
{
  for(; *s; s++)
 17d:	83 45 08 01          	addl   $0x1,0x8(%ebp)
 181:	8b 45 08             	mov    0x8(%ebp),%eax
 184:	0f b6 00             	movzbl (%eax),%eax
 187:	84 c0                	test   %al,%al
 189:	75 e2                	jne    16d <strchr+0xe>
    if(*s == c)
      return (char*)s;
  return 0;
 18b:	b8 00 00 00 00       	mov    $0x0,%eax
}
 190:	c9                   	leave  
 191:	c3                   	ret    

00000192 <gets>:

char*
gets(char *buf, int max)
{
 192:	55                   	push   %ebp
 193:	89 e5                	mov    %esp,%ebp
 195:	83 ec 28             	sub    $0x28,%esp
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 198:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
 19f:	eb 44                	jmp    1e5 <gets+0x53>
    cc = read(0, &c, 1);
 1a1:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
 1a8:	00 
 1a9:	8d 45 ef             	lea    -0x11(%ebp),%eax
 1ac:	89 44 24 04          	mov    %eax,0x4(%esp)
 1b0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
 1b7:	e8 3c 01 00 00       	call   2f8 <read>
 1bc:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(cc < 1)
 1bf:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 1c3:	7e 2d                	jle    1f2 <gets+0x60>
      break;
    buf[i++] = c;
 1c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
 1c8:	03 45 08             	add    0x8(%ebp),%eax
 1cb:	0f b6 55 ef          	movzbl -0x11(%ebp),%edx
 1cf:	88 10                	mov    %dl,(%eax)
 1d1:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
    if(c == '\n' || c == '\r')
 1d5:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 1d9:	3c 0a                	cmp    $0xa,%al
 1db:	74 16                	je     1f3 <gets+0x61>
 1dd:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 1e1:	3c 0d                	cmp    $0xd,%al
 1e3:	74 0e                	je     1f3 <gets+0x61>
gets(char *buf, int max)
{
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 1e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
 1e8:	83 c0 01             	add    $0x1,%eax
 1eb:	3b 45 0c             	cmp    0xc(%ebp),%eax
 1ee:	7c b1                	jl     1a1 <gets+0xf>
 1f0:	eb 01                	jmp    1f3 <gets+0x61>
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
 1f2:	90                   	nop
    buf[i++] = c;
    if(c == '\n' || c == '\r')
      break;
  }
  buf[i] = '\0';
 1f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
 1f6:	03 45 08             	add    0x8(%ebp),%eax
 1f9:	c6 00 00             	movb   $0x0,(%eax)
  return buf;
 1fc:	8b 45 08             	mov    0x8(%ebp),%eax
}
 1ff:	c9                   	leave  
 200:	c3                   	ret    

00000201 <stat>:

int
stat(char *n, struct stat *st)
{
 201:	55                   	push   %ebp
 202:	89 e5                	mov    %esp,%ebp
 204:	83 ec 28             	sub    $0x28,%esp
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 207:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
 20e:	00 
 20f:	8b 45 08             	mov    0x8(%ebp),%eax
 212:	89 04 24             	mov    %eax,(%esp)
 215:	e8 06 01 00 00       	call   320 <open>
 21a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(fd < 0)
 21d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 221:	79 07                	jns    22a <stat+0x29>
    return -1;
 223:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
 228:	eb 23                	jmp    24d <stat+0x4c>
  r = fstat(fd, st);
 22a:	8b 45 0c             	mov    0xc(%ebp),%eax
 22d:	89 44 24 04          	mov    %eax,0x4(%esp)
 231:	8b 45 f4             	mov    -0xc(%ebp),%eax
 234:	89 04 24             	mov    %eax,(%esp)
 237:	e8 fc 00 00 00       	call   338 <fstat>
 23c:	89 45 f0             	mov    %eax,-0x10(%ebp)
  close(fd);
 23f:	8b 45 f4             	mov    -0xc(%ebp),%eax
 242:	89 04 24             	mov    %eax,(%esp)
 245:	e8 be 00 00 00       	call   308 <close>
  return r;
 24a:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
 24d:	c9                   	leave  
 24e:	c3                   	ret    

0000024f <atoi>:

int
atoi(const char *s)
{
 24f:	55                   	push   %ebp
 250:	89 e5                	mov    %esp,%ebp
 252:	83 ec 10             	sub    $0x10,%esp
  int n;

  n = 0;
 255:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  while('0' <= *s && *s <= '9')
 25c:	eb 23                	jmp    281 <atoi+0x32>
    n = n*10 + *s++ - '0';
 25e:	8b 55 fc             	mov    -0x4(%ebp),%edx
 261:	89 d0                	mov    %edx,%eax
 263:	c1 e0 02             	shl    $0x2,%eax
 266:	01 d0                	add    %edx,%eax
 268:	01 c0                	add    %eax,%eax
 26a:	89 c2                	mov    %eax,%edx
 26c:	8b 45 08             	mov    0x8(%ebp),%eax
 26f:	0f b6 00             	movzbl (%eax),%eax
 272:	0f be c0             	movsbl %al,%eax
 275:	01 d0                	add    %edx,%eax
 277:	83 e8 30             	sub    $0x30,%eax
 27a:	89 45 fc             	mov    %eax,-0x4(%ebp)
 27d:	83 45 08 01          	addl   $0x1,0x8(%ebp)
atoi(const char *s)
{
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 281:	8b 45 08             	mov    0x8(%ebp),%eax
 284:	0f b6 00             	movzbl (%eax),%eax
 287:	3c 2f                	cmp    $0x2f,%al
 289:	7e 0a                	jle    295 <atoi+0x46>
 28b:	8b 45 08             	mov    0x8(%ebp),%eax
 28e:	0f b6 00             	movzbl (%eax),%eax
 291:	3c 39                	cmp    $0x39,%al
 293:	7e c9                	jle    25e <atoi+0xf>
    n = n*10 + *s++ - '0';
  return n;
 295:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
 298:	c9                   	leave  
 299:	c3                   	ret    

0000029a <memmove>:

void*
memmove(void *vdst, void *vsrc, int n)
{
 29a:	55                   	push   %ebp
 29b:	89 e5                	mov    %esp,%ebp
 29d:	83 ec 10             	sub    $0x10,%esp
  char *dst, *src;
  
  dst = vdst;
 2a0:	8b 45 08             	mov    0x8(%ebp),%eax
 2a3:	89 45 fc             	mov    %eax,-0x4(%ebp)
  src = vsrc;
 2a6:	8b 45 0c             	mov    0xc(%ebp),%eax
 2a9:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0)
 2ac:	eb 13                	jmp    2c1 <memmove+0x27>
    *dst++ = *src++;
 2ae:	8b 45 f8             	mov    -0x8(%ebp),%eax
 2b1:	0f b6 10             	movzbl (%eax),%edx
 2b4:	8b 45 fc             	mov    -0x4(%ebp),%eax
 2b7:	88 10                	mov    %dl,(%eax)
 2b9:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
 2bd:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  char *dst, *src;
  
  dst = vdst;
  src = vsrc;
  while(n-- > 0)
 2c1:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
 2c5:	0f 9f c0             	setg   %al
 2c8:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
 2cc:	84 c0                	test   %al,%al
 2ce:	75 de                	jne    2ae <memmove+0x14>
    *dst++ = *src++;
  return vdst;
 2d0:	8b 45 08             	mov    0x8(%ebp),%eax
}
 2d3:	c9                   	leave  
 2d4:	c3                   	ret    
 2d5:	90                   	nop
 2d6:	90                   	nop
 2d7:	90                   	nop

000002d8 <fork>:
  name: \
    movl $SYS_ ## name, %eax; \
    int $T_SYSCALL; \
    ret

SYSCALL(fork)
 2d8:	b8 01 00 00 00       	mov    $0x1,%eax
 2dd:	cd 40                	int    $0x40
 2df:	c3                   	ret    

000002e0 <exit>:
SYSCALL(exit)
 2e0:	b8 02 00 00 00       	mov    $0x2,%eax
 2e5:	cd 40                	int    $0x40
 2e7:	c3                   	ret    

000002e8 <wait>:
SYSCALL(wait)
 2e8:	b8 03 00 00 00       	mov    $0x3,%eax
 2ed:	cd 40                	int    $0x40
 2ef:	c3                   	ret    

000002f0 <pipe>:
SYSCALL(pipe)
 2f0:	b8 04 00 00 00       	mov    $0x4,%eax
 2f5:	cd 40                	int    $0x40
 2f7:	c3                   	ret    

000002f8 <read>:
SYSCALL(read)
 2f8:	b8 05 00 00 00       	mov    $0x5,%eax
 2fd:	cd 40                	int    $0x40
 2ff:	c3                   	ret    

00000300 <write>:
SYSCALL(write)
 300:	b8 10 00 00 00       	mov    $0x10,%eax
 305:	cd 40                	int    $0x40
 307:	c3                   	ret    

00000308 <close>:
SYSCALL(close)
 308:	b8 15 00 00 00       	mov    $0x15,%eax
 30d:	cd 40                	int    $0x40
 30f:	c3                   	ret    

00000310 <kill>:
SYSCALL(kill)
 310:	b8 06 00 00 00       	mov    $0x6,%eax
 315:	cd 40                	int    $0x40
 317:	c3                   	ret    

00000318 <exec>:
SYSCALL(exec)
 318:	b8 07 00 00 00       	mov    $0x7,%eax
 31d:	cd 40                	int    $0x40
 31f:	c3                   	ret    

00000320 <open>:
SYSCALL(open)
 320:	b8 0f 00 00 00       	mov    $0xf,%eax
 325:	cd 40                	int    $0x40
 327:	c3                   	ret    

00000328 <mknod>:
SYSCALL(mknod)
 328:	b8 11 00 00 00       	mov    $0x11,%eax
 32d:	cd 40                	int    $0x40
 32f:	c3                   	ret    

00000330 <unlink>:
SYSCALL(unlink)
 330:	b8 12 00 00 00       	mov    $0x12,%eax
 335:	cd 40                	int    $0x40
 337:	c3                   	ret    

00000338 <fstat>:
SYSCALL(fstat)
 338:	b8 08 00 00 00       	mov    $0x8,%eax
 33d:	cd 40                	int    $0x40
 33f:	c3                   	ret    

00000340 <link>:
SYSCALL(link)
 340:	b8 13 00 00 00       	mov    $0x13,%eax
 345:	cd 40                	int    $0x40
 347:	c3                   	ret    

00000348 <mkdir>:
SYSCALL(mkdir)
 348:	b8 14 00 00 00       	mov    $0x14,%eax
 34d:	cd 40                	int    $0x40
 34f:	c3                   	ret    

00000350 <chdir>:
SYSCALL(chdir)
 350:	b8 09 00 00 00       	mov    $0x9,%eax
 355:	cd 40                	int    $0x40
 357:	c3                   	ret    

00000358 <dup>:
SYSCALL(dup)
 358:	b8 0a 00 00 00       	mov    $0xa,%eax
 35d:	cd 40                	int    $0x40
 35f:	c3                   	ret    

00000360 <getpid>:
SYSCALL(getpid)
 360:	b8 0b 00 00 00       	mov    $0xb,%eax
 365:	cd 40                	int    $0x40
 367:	c3                   	ret    

00000368 <sbrk>:
SYSCALL(sbrk)
 368:	b8 0c 00 00 00       	mov    $0xc,%eax
 36d:	cd 40                	int    $0x40
 36f:	c3                   	ret    

00000370 <sleep>:
SYSCALL(sleep)
 370:	b8 0d 00 00 00       	mov    $0xd,%eax
 375:	cd 40                	int    $0x40
 377:	c3                   	ret    

00000378 <uptime>:
SYSCALL(uptime)
 378:	b8 0e 00 00 00       	mov    $0xe,%eax
 37d:	cd 40                	int    $0x40
 37f:	c3                   	ret    

00000380 <enableSwapping>:
SYSCALL(enableSwapping)
 380:	b8 16 00 00 00       	mov    $0x16,%eax
 385:	cd 40                	int    $0x40
 387:	c3                   	ret    

00000388 <disableSwapping>:
SYSCALL(disableSwapping)
 388:	b8 17 00 00 00       	mov    $0x17,%eax
 38d:	cd 40                	int    $0x40
 38f:	c3                   	ret    

00000390 <sleep2>:
SYSCALL(sleep2)
 390:	b8 18 00 00 00       	mov    $0x18,%eax
 395:	cd 40                	int    $0x40
 397:	c3                   	ret    

00000398 <wakeup2>:
SYSCALL(wakeup2)
 398:	b8 19 00 00 00       	mov    $0x19,%eax
 39d:	cd 40                	int    $0x40
 39f:	c3                   	ret    

000003a0 <getAllocatedPages>:
 3a0:	b8 1a 00 00 00       	mov    $0x1a,%eax
 3a5:	cd 40                	int    $0x40
 3a7:	c3                   	ret    

000003a8 <putc>:
#include "stat.h"
#include "user.h"

static void
putc(int fd, char c)
{
 3a8:	55                   	push   %ebp
 3a9:	89 e5                	mov    %esp,%ebp
 3ab:	83 ec 28             	sub    $0x28,%esp
 3ae:	8b 45 0c             	mov    0xc(%ebp),%eax
 3b1:	88 45 f4             	mov    %al,-0xc(%ebp)
  write(fd, &c, 1);
 3b4:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
 3bb:	00 
 3bc:	8d 45 f4             	lea    -0xc(%ebp),%eax
 3bf:	89 44 24 04          	mov    %eax,0x4(%esp)
 3c3:	8b 45 08             	mov    0x8(%ebp),%eax
 3c6:	89 04 24             	mov    %eax,(%esp)
 3c9:	e8 32 ff ff ff       	call   300 <write>
}
 3ce:	c9                   	leave  
 3cf:	c3                   	ret    

000003d0 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 3d0:	55                   	push   %ebp
 3d1:	89 e5                	mov    %esp,%ebp
 3d3:	83 ec 48             	sub    $0x48,%esp
  static char digits[] = "0123456789ABCDEF";
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
 3d6:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  if(sgn && xx < 0){
 3dd:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
 3e1:	74 17                	je     3fa <printint+0x2a>
 3e3:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
 3e7:	79 11                	jns    3fa <printint+0x2a>
    neg = 1;
 3e9:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
    x = -xx;
 3f0:	8b 45 0c             	mov    0xc(%ebp),%eax
 3f3:	f7 d8                	neg    %eax
 3f5:	89 45 ec             	mov    %eax,-0x14(%ebp)
 3f8:	eb 06                	jmp    400 <printint+0x30>
  } else {
    x = xx;
 3fa:	8b 45 0c             	mov    0xc(%ebp),%eax
 3fd:	89 45 ec             	mov    %eax,-0x14(%ebp)
  }

  i = 0;
 400:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  do{
    buf[i++] = digits[x % base];
 407:	8b 4d 10             	mov    0x10(%ebp),%ecx
 40a:	8b 45 ec             	mov    -0x14(%ebp),%eax
 40d:	ba 00 00 00 00       	mov    $0x0,%edx
 412:	f7 f1                	div    %ecx
 414:	89 d0                	mov    %edx,%eax
 416:	0f b6 90 b0 0a 00 00 	movzbl 0xab0(%eax),%edx
 41d:	8d 45 dc             	lea    -0x24(%ebp),%eax
 420:	03 45 f4             	add    -0xc(%ebp),%eax
 423:	88 10                	mov    %dl,(%eax)
 425:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  }while((x /= base) != 0);
 429:	8b 55 10             	mov    0x10(%ebp),%edx
 42c:	89 55 d4             	mov    %edx,-0x2c(%ebp)
 42f:	8b 45 ec             	mov    -0x14(%ebp),%eax
 432:	ba 00 00 00 00       	mov    $0x0,%edx
 437:	f7 75 d4             	divl   -0x2c(%ebp)
 43a:	89 45 ec             	mov    %eax,-0x14(%ebp)
 43d:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
 441:	75 c4                	jne    407 <printint+0x37>
  if(neg)
 443:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 447:	74 2a                	je     473 <printint+0xa3>
    buf[i++] = '-';
 449:	8d 45 dc             	lea    -0x24(%ebp),%eax
 44c:	03 45 f4             	add    -0xc(%ebp),%eax
 44f:	c6 00 2d             	movb   $0x2d,(%eax)
 452:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)

  while(--i >= 0)
 456:	eb 1b                	jmp    473 <printint+0xa3>
    putc(fd, buf[i]);
 458:	8d 45 dc             	lea    -0x24(%ebp),%eax
 45b:	03 45 f4             	add    -0xc(%ebp),%eax
 45e:	0f b6 00             	movzbl (%eax),%eax
 461:	0f be c0             	movsbl %al,%eax
 464:	89 44 24 04          	mov    %eax,0x4(%esp)
 468:	8b 45 08             	mov    0x8(%ebp),%eax
 46b:	89 04 24             	mov    %eax,(%esp)
 46e:	e8 35 ff ff ff       	call   3a8 <putc>
    buf[i++] = digits[x % base];
  }while((x /= base) != 0);
  if(neg)
    buf[i++] = '-';

  while(--i >= 0)
 473:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
 477:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 47b:	79 db                	jns    458 <printint+0x88>
    putc(fd, buf[i]);
}
 47d:	c9                   	leave  
 47e:	c3                   	ret    

0000047f <printf>:

// Print to the given fd. Only understands %d, %x, %p, %s.
void
printf(int fd, char *fmt, ...)
{
 47f:	55                   	push   %ebp
 480:	89 e5                	mov    %esp,%ebp
 482:	83 ec 38             	sub    $0x38,%esp
  char *s;
  int c, i, state;
  uint *ap;

  state = 0;
 485:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  ap = (uint*)(void*)&fmt + 1;
 48c:	8d 45 0c             	lea    0xc(%ebp),%eax
 48f:	83 c0 04             	add    $0x4,%eax
 492:	89 45 e8             	mov    %eax,-0x18(%ebp)
  for(i = 0; fmt[i]; i++){
 495:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
 49c:	e9 7d 01 00 00       	jmp    61e <printf+0x19f>
    c = fmt[i] & 0xff;
 4a1:	8b 55 0c             	mov    0xc(%ebp),%edx
 4a4:	8b 45 f0             	mov    -0x10(%ebp),%eax
 4a7:	01 d0                	add    %edx,%eax
 4a9:	0f b6 00             	movzbl (%eax),%eax
 4ac:	0f be c0             	movsbl %al,%eax
 4af:	25 ff 00 00 00       	and    $0xff,%eax
 4b4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(state == 0){
 4b7:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
 4bb:	75 2c                	jne    4e9 <printf+0x6a>
      if(c == '%'){
 4bd:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
 4c1:	75 0c                	jne    4cf <printf+0x50>
        state = '%';
 4c3:	c7 45 ec 25 00 00 00 	movl   $0x25,-0x14(%ebp)
 4ca:	e9 4b 01 00 00       	jmp    61a <printf+0x19b>
      } else {
        putc(fd, c);
 4cf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 4d2:	0f be c0             	movsbl %al,%eax
 4d5:	89 44 24 04          	mov    %eax,0x4(%esp)
 4d9:	8b 45 08             	mov    0x8(%ebp),%eax
 4dc:	89 04 24             	mov    %eax,(%esp)
 4df:	e8 c4 fe ff ff       	call   3a8 <putc>
 4e4:	e9 31 01 00 00       	jmp    61a <printf+0x19b>
      }
    } else if(state == '%'){
 4e9:	83 7d ec 25          	cmpl   $0x25,-0x14(%ebp)
 4ed:	0f 85 27 01 00 00    	jne    61a <printf+0x19b>
      if(c == 'd'){
 4f3:	83 7d e4 64          	cmpl   $0x64,-0x1c(%ebp)
 4f7:	75 2d                	jne    526 <printf+0xa7>
        printint(fd, *ap, 10, 1);
 4f9:	8b 45 e8             	mov    -0x18(%ebp),%eax
 4fc:	8b 00                	mov    (%eax),%eax
 4fe:	c7 44 24 0c 01 00 00 	movl   $0x1,0xc(%esp)
 505:	00 
 506:	c7 44 24 08 0a 00 00 	movl   $0xa,0x8(%esp)
 50d:	00 
 50e:	89 44 24 04          	mov    %eax,0x4(%esp)
 512:	8b 45 08             	mov    0x8(%ebp),%eax
 515:	89 04 24             	mov    %eax,(%esp)
 518:	e8 b3 fe ff ff       	call   3d0 <printint>
        ap++;
 51d:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 521:	e9 ed 00 00 00       	jmp    613 <printf+0x194>
      } else if(c == 'x' || c == 'p'){
 526:	83 7d e4 78          	cmpl   $0x78,-0x1c(%ebp)
 52a:	74 06                	je     532 <printf+0xb3>
 52c:	83 7d e4 70          	cmpl   $0x70,-0x1c(%ebp)
 530:	75 2d                	jne    55f <printf+0xe0>
        printint(fd, *ap, 16, 0);
 532:	8b 45 e8             	mov    -0x18(%ebp),%eax
 535:	8b 00                	mov    (%eax),%eax
 537:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
 53e:	00 
 53f:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
 546:	00 
 547:	89 44 24 04          	mov    %eax,0x4(%esp)
 54b:	8b 45 08             	mov    0x8(%ebp),%eax
 54e:	89 04 24             	mov    %eax,(%esp)
 551:	e8 7a fe ff ff       	call   3d0 <printint>
        ap++;
 556:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 55a:	e9 b4 00 00 00       	jmp    613 <printf+0x194>
      } else if(c == 's'){
 55f:	83 7d e4 73          	cmpl   $0x73,-0x1c(%ebp)
 563:	75 46                	jne    5ab <printf+0x12c>
        s = (char*)*ap;
 565:	8b 45 e8             	mov    -0x18(%ebp),%eax
 568:	8b 00                	mov    (%eax),%eax
 56a:	89 45 f4             	mov    %eax,-0xc(%ebp)
        ap++;
 56d:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
        if(s == 0)
 571:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 575:	75 27                	jne    59e <printf+0x11f>
          s = "(null)";
 577:	c7 45 f4 6a 08 00 00 	movl   $0x86a,-0xc(%ebp)
        while(*s != 0){
 57e:	eb 1e                	jmp    59e <printf+0x11f>
          putc(fd, *s);
 580:	8b 45 f4             	mov    -0xc(%ebp),%eax
 583:	0f b6 00             	movzbl (%eax),%eax
 586:	0f be c0             	movsbl %al,%eax
 589:	89 44 24 04          	mov    %eax,0x4(%esp)
 58d:	8b 45 08             	mov    0x8(%ebp),%eax
 590:	89 04 24             	mov    %eax,(%esp)
 593:	e8 10 fe ff ff       	call   3a8 <putc>
          s++;
 598:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
 59c:	eb 01                	jmp    59f <printf+0x120>
      } else if(c == 's'){
        s = (char*)*ap;
        ap++;
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 59e:	90                   	nop
 59f:	8b 45 f4             	mov    -0xc(%ebp),%eax
 5a2:	0f b6 00             	movzbl (%eax),%eax
 5a5:	84 c0                	test   %al,%al
 5a7:	75 d7                	jne    580 <printf+0x101>
 5a9:	eb 68                	jmp    613 <printf+0x194>
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 5ab:	83 7d e4 63          	cmpl   $0x63,-0x1c(%ebp)
 5af:	75 1d                	jne    5ce <printf+0x14f>
        putc(fd, *ap);
 5b1:	8b 45 e8             	mov    -0x18(%ebp),%eax
 5b4:	8b 00                	mov    (%eax),%eax
 5b6:	0f be c0             	movsbl %al,%eax
 5b9:	89 44 24 04          	mov    %eax,0x4(%esp)
 5bd:	8b 45 08             	mov    0x8(%ebp),%eax
 5c0:	89 04 24             	mov    %eax,(%esp)
 5c3:	e8 e0 fd ff ff       	call   3a8 <putc>
        ap++;
 5c8:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 5cc:	eb 45                	jmp    613 <printf+0x194>
      } else if(c == '%'){
 5ce:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
 5d2:	75 17                	jne    5eb <printf+0x16c>
        putc(fd, c);
 5d4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 5d7:	0f be c0             	movsbl %al,%eax
 5da:	89 44 24 04          	mov    %eax,0x4(%esp)
 5de:	8b 45 08             	mov    0x8(%ebp),%eax
 5e1:	89 04 24             	mov    %eax,(%esp)
 5e4:	e8 bf fd ff ff       	call   3a8 <putc>
 5e9:	eb 28                	jmp    613 <printf+0x194>
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 5eb:	c7 44 24 04 25 00 00 	movl   $0x25,0x4(%esp)
 5f2:	00 
 5f3:	8b 45 08             	mov    0x8(%ebp),%eax
 5f6:	89 04 24             	mov    %eax,(%esp)
 5f9:	e8 aa fd ff ff       	call   3a8 <putc>
        putc(fd, c);
 5fe:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 601:	0f be c0             	movsbl %al,%eax
 604:	89 44 24 04          	mov    %eax,0x4(%esp)
 608:	8b 45 08             	mov    0x8(%ebp),%eax
 60b:	89 04 24             	mov    %eax,(%esp)
 60e:	e8 95 fd ff ff       	call   3a8 <putc>
      }
      state = 0;
 613:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  int c, i, state;
  uint *ap;

  state = 0;
  ap = (uint*)(void*)&fmt + 1;
  for(i = 0; fmt[i]; i++){
 61a:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
 61e:	8b 55 0c             	mov    0xc(%ebp),%edx
 621:	8b 45 f0             	mov    -0x10(%ebp),%eax
 624:	01 d0                	add    %edx,%eax
 626:	0f b6 00             	movzbl (%eax),%eax
 629:	84 c0                	test   %al,%al
 62b:	0f 85 70 fe ff ff    	jne    4a1 <printf+0x22>
        putc(fd, c);
      }
      state = 0;
    }
  }
}
 631:	c9                   	leave  
 632:	c3                   	ret    
 633:	90                   	nop

00000634 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 634:	55                   	push   %ebp
 635:	89 e5                	mov    %esp,%ebp
 637:	83 ec 10             	sub    $0x10,%esp
  Header *bp, *p;

  bp = (Header*)ap - 1;
 63a:	8b 45 08             	mov    0x8(%ebp),%eax
 63d:	83 e8 08             	sub    $0x8,%eax
 640:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 643:	a1 cc 0a 00 00       	mov    0xacc,%eax
 648:	89 45 fc             	mov    %eax,-0x4(%ebp)
 64b:	eb 24                	jmp    671 <free+0x3d>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 64d:	8b 45 fc             	mov    -0x4(%ebp),%eax
 650:	8b 00                	mov    (%eax),%eax
 652:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 655:	77 12                	ja     669 <free+0x35>
 657:	8b 45 f8             	mov    -0x8(%ebp),%eax
 65a:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 65d:	77 24                	ja     683 <free+0x4f>
 65f:	8b 45 fc             	mov    -0x4(%ebp),%eax
 662:	8b 00                	mov    (%eax),%eax
 664:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 667:	77 1a                	ja     683 <free+0x4f>
free(void *ap)
{
  Header *bp, *p;

  bp = (Header*)ap - 1;
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 669:	8b 45 fc             	mov    -0x4(%ebp),%eax
 66c:	8b 00                	mov    (%eax),%eax
 66e:	89 45 fc             	mov    %eax,-0x4(%ebp)
 671:	8b 45 f8             	mov    -0x8(%ebp),%eax
 674:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 677:	76 d4                	jbe    64d <free+0x19>
 679:	8b 45 fc             	mov    -0x4(%ebp),%eax
 67c:	8b 00                	mov    (%eax),%eax
 67e:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 681:	76 ca                	jbe    64d <free+0x19>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
 683:	8b 45 f8             	mov    -0x8(%ebp),%eax
 686:	8b 40 04             	mov    0x4(%eax),%eax
 689:	c1 e0 03             	shl    $0x3,%eax
 68c:	89 c2                	mov    %eax,%edx
 68e:	03 55 f8             	add    -0x8(%ebp),%edx
 691:	8b 45 fc             	mov    -0x4(%ebp),%eax
 694:	8b 00                	mov    (%eax),%eax
 696:	39 c2                	cmp    %eax,%edx
 698:	75 24                	jne    6be <free+0x8a>
    bp->s.size += p->s.ptr->s.size;
 69a:	8b 45 f8             	mov    -0x8(%ebp),%eax
 69d:	8b 50 04             	mov    0x4(%eax),%edx
 6a0:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6a3:	8b 00                	mov    (%eax),%eax
 6a5:	8b 40 04             	mov    0x4(%eax),%eax
 6a8:	01 c2                	add    %eax,%edx
 6aa:	8b 45 f8             	mov    -0x8(%ebp),%eax
 6ad:	89 50 04             	mov    %edx,0x4(%eax)
    bp->s.ptr = p->s.ptr->s.ptr;
 6b0:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6b3:	8b 00                	mov    (%eax),%eax
 6b5:	8b 10                	mov    (%eax),%edx
 6b7:	8b 45 f8             	mov    -0x8(%ebp),%eax
 6ba:	89 10                	mov    %edx,(%eax)
 6bc:	eb 0a                	jmp    6c8 <free+0x94>
  } else
    bp->s.ptr = p->s.ptr;
 6be:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6c1:	8b 10                	mov    (%eax),%edx
 6c3:	8b 45 f8             	mov    -0x8(%ebp),%eax
 6c6:	89 10                	mov    %edx,(%eax)
  if(p + p->s.size == bp){
 6c8:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6cb:	8b 40 04             	mov    0x4(%eax),%eax
 6ce:	c1 e0 03             	shl    $0x3,%eax
 6d1:	03 45 fc             	add    -0x4(%ebp),%eax
 6d4:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 6d7:	75 20                	jne    6f9 <free+0xc5>
    p->s.size += bp->s.size;
 6d9:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6dc:	8b 50 04             	mov    0x4(%eax),%edx
 6df:	8b 45 f8             	mov    -0x8(%ebp),%eax
 6e2:	8b 40 04             	mov    0x4(%eax),%eax
 6e5:	01 c2                	add    %eax,%edx
 6e7:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6ea:	89 50 04             	mov    %edx,0x4(%eax)
    p->s.ptr = bp->s.ptr;
 6ed:	8b 45 f8             	mov    -0x8(%ebp),%eax
 6f0:	8b 10                	mov    (%eax),%edx
 6f2:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6f5:	89 10                	mov    %edx,(%eax)
 6f7:	eb 08                	jmp    701 <free+0xcd>
  } else
    p->s.ptr = bp;
 6f9:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6fc:	8b 55 f8             	mov    -0x8(%ebp),%edx
 6ff:	89 10                	mov    %edx,(%eax)
  freep = p;
 701:	8b 45 fc             	mov    -0x4(%ebp),%eax
 704:	a3 cc 0a 00 00       	mov    %eax,0xacc
}
 709:	c9                   	leave  
 70a:	c3                   	ret    

0000070b <morecore>:

static Header*
morecore(uint nu)
{
 70b:	55                   	push   %ebp
 70c:	89 e5                	mov    %esp,%ebp
 70e:	83 ec 28             	sub    $0x28,%esp
  char *p;
  Header *hp;

  if(nu < 4096)
 711:	81 7d 08 ff 0f 00 00 	cmpl   $0xfff,0x8(%ebp)
 718:	77 07                	ja     721 <morecore+0x16>
    nu = 4096;
 71a:	c7 45 08 00 10 00 00 	movl   $0x1000,0x8(%ebp)
  p = sbrk(nu * sizeof(Header));
 721:	8b 45 08             	mov    0x8(%ebp),%eax
 724:	c1 e0 03             	shl    $0x3,%eax
 727:	89 04 24             	mov    %eax,(%esp)
 72a:	e8 39 fc ff ff       	call   368 <sbrk>
 72f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(p == (char*)-1)
 732:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
 736:	75 07                	jne    73f <morecore+0x34>
    return 0;
 738:	b8 00 00 00 00       	mov    $0x0,%eax
 73d:	eb 22                	jmp    761 <morecore+0x56>
  hp = (Header*)p;
 73f:	8b 45 f4             	mov    -0xc(%ebp),%eax
 742:	89 45 f0             	mov    %eax,-0x10(%ebp)
  hp->s.size = nu;
 745:	8b 45 f0             	mov    -0x10(%ebp),%eax
 748:	8b 55 08             	mov    0x8(%ebp),%edx
 74b:	89 50 04             	mov    %edx,0x4(%eax)
  free((void*)(hp + 1));
 74e:	8b 45 f0             	mov    -0x10(%ebp),%eax
 751:	83 c0 08             	add    $0x8,%eax
 754:	89 04 24             	mov    %eax,(%esp)
 757:	e8 d8 fe ff ff       	call   634 <free>
  return freep;
 75c:	a1 cc 0a 00 00       	mov    0xacc,%eax
}
 761:	c9                   	leave  
 762:	c3                   	ret    

00000763 <malloc>:

void*
malloc(uint nbytes)
{
 763:	55                   	push   %ebp
 764:	89 e5                	mov    %esp,%ebp
 766:	83 ec 28             	sub    $0x28,%esp
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 769:	8b 45 08             	mov    0x8(%ebp),%eax
 76c:	83 c0 07             	add    $0x7,%eax
 76f:	c1 e8 03             	shr    $0x3,%eax
 772:	83 c0 01             	add    $0x1,%eax
 775:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((prevp = freep) == 0){
 778:	a1 cc 0a 00 00       	mov    0xacc,%eax
 77d:	89 45 f0             	mov    %eax,-0x10(%ebp)
 780:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 784:	75 23                	jne    7a9 <malloc+0x46>
    base.s.ptr = freep = prevp = &base;
 786:	c7 45 f0 c4 0a 00 00 	movl   $0xac4,-0x10(%ebp)
 78d:	8b 45 f0             	mov    -0x10(%ebp),%eax
 790:	a3 cc 0a 00 00       	mov    %eax,0xacc
 795:	a1 cc 0a 00 00       	mov    0xacc,%eax
 79a:	a3 c4 0a 00 00       	mov    %eax,0xac4
    base.s.size = 0;
 79f:	c7 05 c8 0a 00 00 00 	movl   $0x0,0xac8
 7a6:	00 00 00 
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7a9:	8b 45 f0             	mov    -0x10(%ebp),%eax
 7ac:	8b 00                	mov    (%eax),%eax
 7ae:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(p->s.size >= nunits){
 7b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
 7b4:	8b 40 04             	mov    0x4(%eax),%eax
 7b7:	3b 45 ec             	cmp    -0x14(%ebp),%eax
 7ba:	72 4d                	jb     809 <malloc+0xa6>
      if(p->s.size == nunits)
 7bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
 7bf:	8b 40 04             	mov    0x4(%eax),%eax
 7c2:	3b 45 ec             	cmp    -0x14(%ebp),%eax
 7c5:	75 0c                	jne    7d3 <malloc+0x70>
        prevp->s.ptr = p->s.ptr;
 7c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
 7ca:	8b 10                	mov    (%eax),%edx
 7cc:	8b 45 f0             	mov    -0x10(%ebp),%eax
 7cf:	89 10                	mov    %edx,(%eax)
 7d1:	eb 26                	jmp    7f9 <malloc+0x96>
      else {
        p->s.size -= nunits;
 7d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
 7d6:	8b 40 04             	mov    0x4(%eax),%eax
 7d9:	89 c2                	mov    %eax,%edx
 7db:	2b 55 ec             	sub    -0x14(%ebp),%edx
 7de:	8b 45 f4             	mov    -0xc(%ebp),%eax
 7e1:	89 50 04             	mov    %edx,0x4(%eax)
        p += p->s.size;
 7e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
 7e7:	8b 40 04             	mov    0x4(%eax),%eax
 7ea:	c1 e0 03             	shl    $0x3,%eax
 7ed:	01 45 f4             	add    %eax,-0xc(%ebp)
        p->s.size = nunits;
 7f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
 7f3:	8b 55 ec             	mov    -0x14(%ebp),%edx
 7f6:	89 50 04             	mov    %edx,0x4(%eax)
      }
      freep = prevp;
 7f9:	8b 45 f0             	mov    -0x10(%ebp),%eax
 7fc:	a3 cc 0a 00 00       	mov    %eax,0xacc
      return (void*)(p + 1);
 801:	8b 45 f4             	mov    -0xc(%ebp),%eax
 804:	83 c0 08             	add    $0x8,%eax
 807:	eb 38                	jmp    841 <malloc+0xde>
    }
    if(p == freep)
 809:	a1 cc 0a 00 00       	mov    0xacc,%eax
 80e:	39 45 f4             	cmp    %eax,-0xc(%ebp)
 811:	75 1b                	jne    82e <malloc+0xcb>
      if((p = morecore(nunits)) == 0)
 813:	8b 45 ec             	mov    -0x14(%ebp),%eax
 816:	89 04 24             	mov    %eax,(%esp)
 819:	e8 ed fe ff ff       	call   70b <morecore>
 81e:	89 45 f4             	mov    %eax,-0xc(%ebp)
 821:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 825:	75 07                	jne    82e <malloc+0xcb>
        return 0;
 827:	b8 00 00 00 00       	mov    $0x0,%eax
 82c:	eb 13                	jmp    841 <malloc+0xde>
  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
  if((prevp = freep) == 0){
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 82e:	8b 45 f4             	mov    -0xc(%ebp),%eax
 831:	89 45 f0             	mov    %eax,-0x10(%ebp)
 834:	8b 45 f4             	mov    -0xc(%ebp),%eax
 837:	8b 00                	mov    (%eax),%eax
 839:	89 45 f4             	mov    %eax,-0xc(%ebp)
      return (void*)(p + 1);
    }
    if(p == freep)
      if((p = morecore(nunits)) == 0)
        return 0;
  }
 83c:	e9 70 ff ff ff       	jmp    7b1 <malloc+0x4e>
}
 841:	c9                   	leave  
 842:	c3                   	ret    
