
_grep:     file format elf32-i386


Disassembly of section .text:

00000000 <grep>:
char buf[1024];
int match(char*, char*);

void
grep(char *pattern, int fd)
{
   0:	55                   	push   %ebp
   1:	89 e5                	mov    %esp,%ebp
   3:	83 ec 28             	sub    $0x28,%esp
  int n, m;
  char *p, *q;
  
  m = 0;
   6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  while((n = read(fd, buf+m, sizeof(buf)-m)) > 0){
   d:	e9 bf 00 00 00       	jmp    d1 <grep+0xd1>
    m += n;
  12:	8b 45 ec             	mov    -0x14(%ebp),%eax
  15:	01 45 f4             	add    %eax,-0xc(%ebp)
    p = buf;
  18:	c7 45 f0 80 0e 00 00 	movl   $0xe80,-0x10(%ebp)
    while((q = strchr(p, '\n')) != 0){
  1f:	eb 53                	jmp    74 <grep+0x74>
      *q = 0;
  21:	8b 45 e8             	mov    -0x18(%ebp),%eax
  24:	c6 00 00             	movb   $0x0,(%eax)
      if(match(pattern, p)){
  27:	8b 45 f0             	mov    -0x10(%ebp),%eax
  2a:	89 44 24 04          	mov    %eax,0x4(%esp)
  2e:	8b 45 08             	mov    0x8(%ebp),%eax
  31:	89 04 24             	mov    %eax,(%esp)
  34:	e8 af 01 00 00       	call   1e8 <match>
  39:	85 c0                	test   %eax,%eax
  3b:	74 2e                	je     6b <grep+0x6b>
        *q = '\n';
  3d:	8b 45 e8             	mov    -0x18(%ebp),%eax
  40:	c6 00 0a             	movb   $0xa,(%eax)
        write(1, p, q+1 - p);
  43:	8b 45 e8             	mov    -0x18(%ebp),%eax
  46:	83 c0 01             	add    $0x1,%eax
  49:	89 c2                	mov    %eax,%edx
  4b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  4e:	89 d1                	mov    %edx,%ecx
  50:	29 c1                	sub    %eax,%ecx
  52:	89 c8                	mov    %ecx,%eax
  54:	89 44 24 08          	mov    %eax,0x8(%esp)
  58:	8b 45 f0             	mov    -0x10(%ebp),%eax
  5b:	89 44 24 04          	mov    %eax,0x4(%esp)
  5f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  66:	e8 69 05 00 00       	call   5d4 <write>
      }
      p = q+1;
  6b:	8b 45 e8             	mov    -0x18(%ebp),%eax
  6e:	83 c0 01             	add    $0x1,%eax
  71:	89 45 f0             	mov    %eax,-0x10(%ebp)
  
  m = 0;
  while((n = read(fd, buf+m, sizeof(buf)-m)) > 0){
    m += n;
    p = buf;
    while((q = strchr(p, '\n')) != 0){
  74:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
  7b:	00 
  7c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  7f:	89 04 24             	mov    %eax,(%esp)
  82:	e8 ac 03 00 00       	call   433 <strchr>
  87:	89 45 e8             	mov    %eax,-0x18(%ebp)
  8a:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  8e:	75 91                	jne    21 <grep+0x21>
        *q = '\n';
        write(1, p, q+1 - p);
      }
      p = q+1;
    }
    if(p == buf)
  90:	81 7d f0 80 0e 00 00 	cmpl   $0xe80,-0x10(%ebp)
  97:	75 07                	jne    a0 <grep+0xa0>
      m = 0;
  99:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(m > 0){
  a0:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  a4:	7e 2b                	jle    d1 <grep+0xd1>
      m -= p - buf;
  a6:	ba 80 0e 00 00       	mov    $0xe80,%edx
  ab:	8b 45 f0             	mov    -0x10(%ebp),%eax
  ae:	89 d1                	mov    %edx,%ecx
  b0:	29 c1                	sub    %eax,%ecx
  b2:	89 c8                	mov    %ecx,%eax
  b4:	01 45 f4             	add    %eax,-0xc(%ebp)
      memmove(buf, p, m);
  b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
  ba:	89 44 24 08          	mov    %eax,0x8(%esp)
  be:	8b 45 f0             	mov    -0x10(%ebp),%eax
  c1:	89 44 24 04          	mov    %eax,0x4(%esp)
  c5:	c7 04 24 80 0e 00 00 	movl   $0xe80,(%esp)
  cc:	e8 9d 04 00 00       	call   56e <memmove>
{
  int n, m;
  char *p, *q;
  
  m = 0;
  while((n = read(fd, buf+m, sizeof(buf)-m)) > 0){
  d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
  d4:	ba 00 04 00 00       	mov    $0x400,%edx
  d9:	89 d1                	mov    %edx,%ecx
  db:	29 c1                	sub    %eax,%ecx
  dd:	89 c8                	mov    %ecx,%eax
  df:	8b 55 f4             	mov    -0xc(%ebp),%edx
  e2:	81 c2 80 0e 00 00    	add    $0xe80,%edx
  e8:	89 44 24 08          	mov    %eax,0x8(%esp)
  ec:	89 54 24 04          	mov    %edx,0x4(%esp)
  f0:	8b 45 0c             	mov    0xc(%ebp),%eax
  f3:	89 04 24             	mov    %eax,(%esp)
  f6:	e8 d1 04 00 00       	call   5cc <read>
  fb:	89 45 ec             	mov    %eax,-0x14(%ebp)
  fe:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
 102:	0f 8f 0a ff ff ff    	jg     12 <grep+0x12>
    if(m > 0){
      m -= p - buf;
      memmove(buf, p, m);
    }
  }
}
 108:	c9                   	leave  
 109:	c3                   	ret    

0000010a <main>:

int
main(int argc, char *argv[])
{
 10a:	55                   	push   %ebp
 10b:	89 e5                	mov    %esp,%ebp
 10d:	83 e4 f0             	and    $0xfffffff0,%esp
 110:	83 ec 20             	sub    $0x20,%esp
  int fd, i;
  char *pattern;
  
  if(argc <= 1){
 113:	83 7d 08 01          	cmpl   $0x1,0x8(%ebp)
 117:	7f 19                	jg     132 <main+0x28>
    printf(2, "usage: grep pattern [file ...]\n");
 119:	c7 44 24 04 38 0b 00 	movl   $0xb38,0x4(%esp)
 120:	00 
 121:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
 128:	e8 46 06 00 00       	call   773 <printf>
    exit();
 12d:	e8 82 04 00 00       	call   5b4 <exit>
  }
  pattern = argv[1];
 132:	8b 45 0c             	mov    0xc(%ebp),%eax
 135:	8b 40 04             	mov    0x4(%eax),%eax
 138:	89 44 24 18          	mov    %eax,0x18(%esp)
  
  if(argc <= 2){
 13c:	83 7d 08 02          	cmpl   $0x2,0x8(%ebp)
 140:	7f 19                	jg     15b <main+0x51>
    grep(pattern, 0);
 142:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
 149:	00 
 14a:	8b 44 24 18          	mov    0x18(%esp),%eax
 14e:	89 04 24             	mov    %eax,(%esp)
 151:	e8 aa fe ff ff       	call   0 <grep>
    exit();
 156:	e8 59 04 00 00       	call   5b4 <exit>
  }

  for(i = 2; i < argc; i++){
 15b:	c7 44 24 1c 02 00 00 	movl   $0x2,0x1c(%esp)
 162:	00 
 163:	eb 75                	jmp    1da <main+0xd0>
    if((fd = open(argv[i], 0)) < 0){
 165:	8b 44 24 1c          	mov    0x1c(%esp),%eax
 169:	c1 e0 02             	shl    $0x2,%eax
 16c:	03 45 0c             	add    0xc(%ebp),%eax
 16f:	8b 00                	mov    (%eax),%eax
 171:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
 178:	00 
 179:	89 04 24             	mov    %eax,(%esp)
 17c:	e8 73 04 00 00       	call   5f4 <open>
 181:	89 44 24 14          	mov    %eax,0x14(%esp)
 185:	83 7c 24 14 00       	cmpl   $0x0,0x14(%esp)
 18a:	79 29                	jns    1b5 <main+0xab>
      printf(1, "grep: cannot open %s\n", argv[i]);
 18c:	8b 44 24 1c          	mov    0x1c(%esp),%eax
 190:	c1 e0 02             	shl    $0x2,%eax
 193:	03 45 0c             	add    0xc(%ebp),%eax
 196:	8b 00                	mov    (%eax),%eax
 198:	89 44 24 08          	mov    %eax,0x8(%esp)
 19c:	c7 44 24 04 58 0b 00 	movl   $0xb58,0x4(%esp)
 1a3:	00 
 1a4:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
 1ab:	e8 c3 05 00 00       	call   773 <printf>
      exit();
 1b0:	e8 ff 03 00 00       	call   5b4 <exit>
    }
    grep(pattern, fd);
 1b5:	8b 44 24 14          	mov    0x14(%esp),%eax
 1b9:	89 44 24 04          	mov    %eax,0x4(%esp)
 1bd:	8b 44 24 18          	mov    0x18(%esp),%eax
 1c1:	89 04 24             	mov    %eax,(%esp)
 1c4:	e8 37 fe ff ff       	call   0 <grep>
    close(fd);
 1c9:	8b 44 24 14          	mov    0x14(%esp),%eax
 1cd:	89 04 24             	mov    %eax,(%esp)
 1d0:	e8 07 04 00 00       	call   5dc <close>
  if(argc <= 2){
    grep(pattern, 0);
    exit();
  }

  for(i = 2; i < argc; i++){
 1d5:	83 44 24 1c 01       	addl   $0x1,0x1c(%esp)
 1da:	8b 44 24 1c          	mov    0x1c(%esp),%eax
 1de:	3b 45 08             	cmp    0x8(%ebp),%eax
 1e1:	7c 82                	jl     165 <main+0x5b>
      exit();
    }
    grep(pattern, fd);
    close(fd);
  }
  exit();
 1e3:	e8 cc 03 00 00       	call   5b4 <exit>

000001e8 <match>:
int matchhere(char*, char*);
int matchstar(int, char*, char*);

int
match(char *re, char *text)
{
 1e8:	55                   	push   %ebp
 1e9:	89 e5                	mov    %esp,%ebp
 1eb:	83 ec 18             	sub    $0x18,%esp
  if(re[0] == '^')
 1ee:	8b 45 08             	mov    0x8(%ebp),%eax
 1f1:	0f b6 00             	movzbl (%eax),%eax
 1f4:	3c 5e                	cmp    $0x5e,%al
 1f6:	75 17                	jne    20f <match+0x27>
    return matchhere(re+1, text);
 1f8:	8b 45 08             	mov    0x8(%ebp),%eax
 1fb:	8d 50 01             	lea    0x1(%eax),%edx
 1fe:	8b 45 0c             	mov    0xc(%ebp),%eax
 201:	89 44 24 04          	mov    %eax,0x4(%esp)
 205:	89 14 24             	mov    %edx,(%esp)
 208:	e8 39 00 00 00       	call   246 <matchhere>
 20d:	eb 35                	jmp    244 <match+0x5c>
  do{  // must look at empty string
    if(matchhere(re, text))
 20f:	8b 45 0c             	mov    0xc(%ebp),%eax
 212:	89 44 24 04          	mov    %eax,0x4(%esp)
 216:	8b 45 08             	mov    0x8(%ebp),%eax
 219:	89 04 24             	mov    %eax,(%esp)
 21c:	e8 25 00 00 00       	call   246 <matchhere>
 221:	85 c0                	test   %eax,%eax
 223:	74 07                	je     22c <match+0x44>
      return 1;
 225:	b8 01 00 00 00       	mov    $0x1,%eax
 22a:	eb 18                	jmp    244 <match+0x5c>
  }while(*text++ != '\0');
 22c:	8b 45 0c             	mov    0xc(%ebp),%eax
 22f:	0f b6 00             	movzbl (%eax),%eax
 232:	84 c0                	test   %al,%al
 234:	0f 95 c0             	setne  %al
 237:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
 23b:	84 c0                	test   %al,%al
 23d:	75 d0                	jne    20f <match+0x27>
  return 0;
 23f:	b8 00 00 00 00       	mov    $0x0,%eax
}
 244:	c9                   	leave  
 245:	c3                   	ret    

00000246 <matchhere>:

// matchhere: search for re at beginning of text
int matchhere(char *re, char *text)
{
 246:	55                   	push   %ebp
 247:	89 e5                	mov    %esp,%ebp
 249:	83 ec 18             	sub    $0x18,%esp
  if(re[0] == '\0')
 24c:	8b 45 08             	mov    0x8(%ebp),%eax
 24f:	0f b6 00             	movzbl (%eax),%eax
 252:	84 c0                	test   %al,%al
 254:	75 0a                	jne    260 <matchhere+0x1a>
    return 1;
 256:	b8 01 00 00 00       	mov    $0x1,%eax
 25b:	e9 9b 00 00 00       	jmp    2fb <matchhere+0xb5>
  if(re[1] == '*')
 260:	8b 45 08             	mov    0x8(%ebp),%eax
 263:	83 c0 01             	add    $0x1,%eax
 266:	0f b6 00             	movzbl (%eax),%eax
 269:	3c 2a                	cmp    $0x2a,%al
 26b:	75 24                	jne    291 <matchhere+0x4b>
    return matchstar(re[0], re+2, text);
 26d:	8b 45 08             	mov    0x8(%ebp),%eax
 270:	8d 48 02             	lea    0x2(%eax),%ecx
 273:	8b 45 08             	mov    0x8(%ebp),%eax
 276:	0f b6 00             	movzbl (%eax),%eax
 279:	0f be c0             	movsbl %al,%eax
 27c:	8b 55 0c             	mov    0xc(%ebp),%edx
 27f:	89 54 24 08          	mov    %edx,0x8(%esp)
 283:	89 4c 24 04          	mov    %ecx,0x4(%esp)
 287:	89 04 24             	mov    %eax,(%esp)
 28a:	e8 6e 00 00 00       	call   2fd <matchstar>
 28f:	eb 6a                	jmp    2fb <matchhere+0xb5>
  if(re[0] == '$' && re[1] == '\0')
 291:	8b 45 08             	mov    0x8(%ebp),%eax
 294:	0f b6 00             	movzbl (%eax),%eax
 297:	3c 24                	cmp    $0x24,%al
 299:	75 1d                	jne    2b8 <matchhere+0x72>
 29b:	8b 45 08             	mov    0x8(%ebp),%eax
 29e:	83 c0 01             	add    $0x1,%eax
 2a1:	0f b6 00             	movzbl (%eax),%eax
 2a4:	84 c0                	test   %al,%al
 2a6:	75 10                	jne    2b8 <matchhere+0x72>
    return *text == '\0';
 2a8:	8b 45 0c             	mov    0xc(%ebp),%eax
 2ab:	0f b6 00             	movzbl (%eax),%eax
 2ae:	84 c0                	test   %al,%al
 2b0:	0f 94 c0             	sete   %al
 2b3:	0f b6 c0             	movzbl %al,%eax
 2b6:	eb 43                	jmp    2fb <matchhere+0xb5>
  if(*text!='\0' && (re[0]=='.' || re[0]==*text))
 2b8:	8b 45 0c             	mov    0xc(%ebp),%eax
 2bb:	0f b6 00             	movzbl (%eax),%eax
 2be:	84 c0                	test   %al,%al
 2c0:	74 34                	je     2f6 <matchhere+0xb0>
 2c2:	8b 45 08             	mov    0x8(%ebp),%eax
 2c5:	0f b6 00             	movzbl (%eax),%eax
 2c8:	3c 2e                	cmp    $0x2e,%al
 2ca:	74 10                	je     2dc <matchhere+0x96>
 2cc:	8b 45 08             	mov    0x8(%ebp),%eax
 2cf:	0f b6 10             	movzbl (%eax),%edx
 2d2:	8b 45 0c             	mov    0xc(%ebp),%eax
 2d5:	0f b6 00             	movzbl (%eax),%eax
 2d8:	38 c2                	cmp    %al,%dl
 2da:	75 1a                	jne    2f6 <matchhere+0xb0>
    return matchhere(re+1, text+1);
 2dc:	8b 45 0c             	mov    0xc(%ebp),%eax
 2df:	8d 50 01             	lea    0x1(%eax),%edx
 2e2:	8b 45 08             	mov    0x8(%ebp),%eax
 2e5:	83 c0 01             	add    $0x1,%eax
 2e8:	89 54 24 04          	mov    %edx,0x4(%esp)
 2ec:	89 04 24             	mov    %eax,(%esp)
 2ef:	e8 52 ff ff ff       	call   246 <matchhere>
 2f4:	eb 05                	jmp    2fb <matchhere+0xb5>
  return 0;
 2f6:	b8 00 00 00 00       	mov    $0x0,%eax
}
 2fb:	c9                   	leave  
 2fc:	c3                   	ret    

000002fd <matchstar>:

// matchstar: search for c*re at beginning of text
int matchstar(int c, char *re, char *text)
{
 2fd:	55                   	push   %ebp
 2fe:	89 e5                	mov    %esp,%ebp
 300:	83 ec 18             	sub    $0x18,%esp
  do{  // a * matches zero or more instances
    if(matchhere(re, text))
 303:	8b 45 10             	mov    0x10(%ebp),%eax
 306:	89 44 24 04          	mov    %eax,0x4(%esp)
 30a:	8b 45 0c             	mov    0xc(%ebp),%eax
 30d:	89 04 24             	mov    %eax,(%esp)
 310:	e8 31 ff ff ff       	call   246 <matchhere>
 315:	85 c0                	test   %eax,%eax
 317:	74 07                	je     320 <matchstar+0x23>
      return 1;
 319:	b8 01 00 00 00       	mov    $0x1,%eax
 31e:	eb 2c                	jmp    34c <matchstar+0x4f>
  }while(*text!='\0' && (*text++==c || c=='.'));
 320:	8b 45 10             	mov    0x10(%ebp),%eax
 323:	0f b6 00             	movzbl (%eax),%eax
 326:	84 c0                	test   %al,%al
 328:	74 1d                	je     347 <matchstar+0x4a>
 32a:	8b 45 10             	mov    0x10(%ebp),%eax
 32d:	0f b6 00             	movzbl (%eax),%eax
 330:	0f be c0             	movsbl %al,%eax
 333:	3b 45 08             	cmp    0x8(%ebp),%eax
 336:	0f 94 c0             	sete   %al
 339:	83 45 10 01          	addl   $0x1,0x10(%ebp)
 33d:	84 c0                	test   %al,%al
 33f:	75 c2                	jne    303 <matchstar+0x6>
 341:	83 7d 08 2e          	cmpl   $0x2e,0x8(%ebp)
 345:	74 bc                	je     303 <matchstar+0x6>
  return 0;
 347:	b8 00 00 00 00       	mov    $0x0,%eax
}
 34c:	c9                   	leave  
 34d:	c3                   	ret    
 34e:	90                   	nop
 34f:	90                   	nop

00000350 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
 350:	55                   	push   %ebp
 351:	89 e5                	mov    %esp,%ebp
 353:	57                   	push   %edi
 354:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
 355:	8b 4d 08             	mov    0x8(%ebp),%ecx
 358:	8b 55 10             	mov    0x10(%ebp),%edx
 35b:	8b 45 0c             	mov    0xc(%ebp),%eax
 35e:	89 cb                	mov    %ecx,%ebx
 360:	89 df                	mov    %ebx,%edi
 362:	89 d1                	mov    %edx,%ecx
 364:	fc                   	cld    
 365:	f3 aa                	rep stos %al,%es:(%edi)
 367:	89 ca                	mov    %ecx,%edx
 369:	89 fb                	mov    %edi,%ebx
 36b:	89 5d 08             	mov    %ebx,0x8(%ebp)
 36e:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
 371:	5b                   	pop    %ebx
 372:	5f                   	pop    %edi
 373:	5d                   	pop    %ebp
 374:	c3                   	ret    

00000375 <strcpy>:
#include "user.h"
#include "x86.h"

char*
strcpy(char *s, char *t)
{
 375:	55                   	push   %ebp
 376:	89 e5                	mov    %esp,%ebp
 378:	83 ec 10             	sub    $0x10,%esp
  char *os;

  os = s;
 37b:	8b 45 08             	mov    0x8(%ebp),%eax
 37e:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while((*s++ = *t++) != 0)
 381:	90                   	nop
 382:	8b 45 0c             	mov    0xc(%ebp),%eax
 385:	0f b6 10             	movzbl (%eax),%edx
 388:	8b 45 08             	mov    0x8(%ebp),%eax
 38b:	88 10                	mov    %dl,(%eax)
 38d:	8b 45 08             	mov    0x8(%ebp),%eax
 390:	0f b6 00             	movzbl (%eax),%eax
 393:	84 c0                	test   %al,%al
 395:	0f 95 c0             	setne  %al
 398:	83 45 08 01          	addl   $0x1,0x8(%ebp)
 39c:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
 3a0:	84 c0                	test   %al,%al
 3a2:	75 de                	jne    382 <strcpy+0xd>
    ;
  return os;
 3a4:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
 3a7:	c9                   	leave  
 3a8:	c3                   	ret    

000003a9 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 3a9:	55                   	push   %ebp
 3aa:	89 e5                	mov    %esp,%ebp
  while(*p && *p == *q)
 3ac:	eb 08                	jmp    3b6 <strcmp+0xd>
    p++, q++;
 3ae:	83 45 08 01          	addl   $0x1,0x8(%ebp)
 3b2:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
  while(*p && *p == *q)
 3b6:	8b 45 08             	mov    0x8(%ebp),%eax
 3b9:	0f b6 00             	movzbl (%eax),%eax
 3bc:	84 c0                	test   %al,%al
 3be:	74 10                	je     3d0 <strcmp+0x27>
 3c0:	8b 45 08             	mov    0x8(%ebp),%eax
 3c3:	0f b6 10             	movzbl (%eax),%edx
 3c6:	8b 45 0c             	mov    0xc(%ebp),%eax
 3c9:	0f b6 00             	movzbl (%eax),%eax
 3cc:	38 c2                	cmp    %al,%dl
 3ce:	74 de                	je     3ae <strcmp+0x5>
    p++, q++;
  return (uchar)*p - (uchar)*q;
 3d0:	8b 45 08             	mov    0x8(%ebp),%eax
 3d3:	0f b6 00             	movzbl (%eax),%eax
 3d6:	0f b6 d0             	movzbl %al,%edx
 3d9:	8b 45 0c             	mov    0xc(%ebp),%eax
 3dc:	0f b6 00             	movzbl (%eax),%eax
 3df:	0f b6 c0             	movzbl %al,%eax
 3e2:	89 d1                	mov    %edx,%ecx
 3e4:	29 c1                	sub    %eax,%ecx
 3e6:	89 c8                	mov    %ecx,%eax
}
 3e8:	5d                   	pop    %ebp
 3e9:	c3                   	ret    

000003ea <strlen>:

uint
strlen(char *s)
{
 3ea:	55                   	push   %ebp
 3eb:	89 e5                	mov    %esp,%ebp
 3ed:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
 3f0:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
 3f7:	eb 04                	jmp    3fd <strlen+0x13>
 3f9:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
 3fd:	8b 45 fc             	mov    -0x4(%ebp),%eax
 400:	03 45 08             	add    0x8(%ebp),%eax
 403:	0f b6 00             	movzbl (%eax),%eax
 406:	84 c0                	test   %al,%al
 408:	75 ef                	jne    3f9 <strlen+0xf>
    ;
  return n;
 40a:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
 40d:	c9                   	leave  
 40e:	c3                   	ret    

0000040f <memset>:

void*
memset(void *dst, int c, uint n)
{
 40f:	55                   	push   %ebp
 410:	89 e5                	mov    %esp,%ebp
 412:	83 ec 0c             	sub    $0xc,%esp
  stosb(dst, c, n);
 415:	8b 45 10             	mov    0x10(%ebp),%eax
 418:	89 44 24 08          	mov    %eax,0x8(%esp)
 41c:	8b 45 0c             	mov    0xc(%ebp),%eax
 41f:	89 44 24 04          	mov    %eax,0x4(%esp)
 423:	8b 45 08             	mov    0x8(%ebp),%eax
 426:	89 04 24             	mov    %eax,(%esp)
 429:	e8 22 ff ff ff       	call   350 <stosb>
  return dst;
 42e:	8b 45 08             	mov    0x8(%ebp),%eax
}
 431:	c9                   	leave  
 432:	c3                   	ret    

00000433 <strchr>:

char*
strchr(const char *s, char c)
{
 433:	55                   	push   %ebp
 434:	89 e5                	mov    %esp,%ebp
 436:	83 ec 04             	sub    $0x4,%esp
 439:	8b 45 0c             	mov    0xc(%ebp),%eax
 43c:	88 45 fc             	mov    %al,-0x4(%ebp)
  for(; *s; s++)
 43f:	eb 14                	jmp    455 <strchr+0x22>
    if(*s == c)
 441:	8b 45 08             	mov    0x8(%ebp),%eax
 444:	0f b6 00             	movzbl (%eax),%eax
 447:	3a 45 fc             	cmp    -0x4(%ebp),%al
 44a:	75 05                	jne    451 <strchr+0x1e>
      return (char*)s;
 44c:	8b 45 08             	mov    0x8(%ebp),%eax
 44f:	eb 13                	jmp    464 <strchr+0x31>
}

char*
strchr(const char *s, char c)
{
  for(; *s; s++)
 451:	83 45 08 01          	addl   $0x1,0x8(%ebp)
 455:	8b 45 08             	mov    0x8(%ebp),%eax
 458:	0f b6 00             	movzbl (%eax),%eax
 45b:	84 c0                	test   %al,%al
 45d:	75 e2                	jne    441 <strchr+0xe>
    if(*s == c)
      return (char*)s;
  return 0;
 45f:	b8 00 00 00 00       	mov    $0x0,%eax
}
 464:	c9                   	leave  
 465:	c3                   	ret    

00000466 <gets>:

char*
gets(char *buf, int max)
{
 466:	55                   	push   %ebp
 467:	89 e5                	mov    %esp,%ebp
 469:	83 ec 28             	sub    $0x28,%esp
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 46c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
 473:	eb 44                	jmp    4b9 <gets+0x53>
    cc = read(0, &c, 1);
 475:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
 47c:	00 
 47d:	8d 45 ef             	lea    -0x11(%ebp),%eax
 480:	89 44 24 04          	mov    %eax,0x4(%esp)
 484:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
 48b:	e8 3c 01 00 00       	call   5cc <read>
 490:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(cc < 1)
 493:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 497:	7e 2d                	jle    4c6 <gets+0x60>
      break;
    buf[i++] = c;
 499:	8b 45 f4             	mov    -0xc(%ebp),%eax
 49c:	03 45 08             	add    0x8(%ebp),%eax
 49f:	0f b6 55 ef          	movzbl -0x11(%ebp),%edx
 4a3:	88 10                	mov    %dl,(%eax)
 4a5:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
    if(c == '\n' || c == '\r')
 4a9:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 4ad:	3c 0a                	cmp    $0xa,%al
 4af:	74 16                	je     4c7 <gets+0x61>
 4b1:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 4b5:	3c 0d                	cmp    $0xd,%al
 4b7:	74 0e                	je     4c7 <gets+0x61>
gets(char *buf, int max)
{
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 4b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
 4bc:	83 c0 01             	add    $0x1,%eax
 4bf:	3b 45 0c             	cmp    0xc(%ebp),%eax
 4c2:	7c b1                	jl     475 <gets+0xf>
 4c4:	eb 01                	jmp    4c7 <gets+0x61>
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
 4c6:	90                   	nop
    buf[i++] = c;
    if(c == '\n' || c == '\r')
      break;
  }
  buf[i] = '\0';
 4c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
 4ca:	03 45 08             	add    0x8(%ebp),%eax
 4cd:	c6 00 00             	movb   $0x0,(%eax)
  return buf;
 4d0:	8b 45 08             	mov    0x8(%ebp),%eax
}
 4d3:	c9                   	leave  
 4d4:	c3                   	ret    

000004d5 <stat>:

int
stat(char *n, struct stat *st)
{
 4d5:	55                   	push   %ebp
 4d6:	89 e5                	mov    %esp,%ebp
 4d8:	83 ec 28             	sub    $0x28,%esp
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 4db:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
 4e2:	00 
 4e3:	8b 45 08             	mov    0x8(%ebp),%eax
 4e6:	89 04 24             	mov    %eax,(%esp)
 4e9:	e8 06 01 00 00       	call   5f4 <open>
 4ee:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(fd < 0)
 4f1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 4f5:	79 07                	jns    4fe <stat+0x29>
    return -1;
 4f7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
 4fc:	eb 23                	jmp    521 <stat+0x4c>
  r = fstat(fd, st);
 4fe:	8b 45 0c             	mov    0xc(%ebp),%eax
 501:	89 44 24 04          	mov    %eax,0x4(%esp)
 505:	8b 45 f4             	mov    -0xc(%ebp),%eax
 508:	89 04 24             	mov    %eax,(%esp)
 50b:	e8 fc 00 00 00       	call   60c <fstat>
 510:	89 45 f0             	mov    %eax,-0x10(%ebp)
  close(fd);
 513:	8b 45 f4             	mov    -0xc(%ebp),%eax
 516:	89 04 24             	mov    %eax,(%esp)
 519:	e8 be 00 00 00       	call   5dc <close>
  return r;
 51e:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
 521:	c9                   	leave  
 522:	c3                   	ret    

00000523 <atoi>:

int
atoi(const char *s)
{
 523:	55                   	push   %ebp
 524:	89 e5                	mov    %esp,%ebp
 526:	83 ec 10             	sub    $0x10,%esp
  int n;

  n = 0;
 529:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  while('0' <= *s && *s <= '9')
 530:	eb 23                	jmp    555 <atoi+0x32>
    n = n*10 + *s++ - '0';
 532:	8b 55 fc             	mov    -0x4(%ebp),%edx
 535:	89 d0                	mov    %edx,%eax
 537:	c1 e0 02             	shl    $0x2,%eax
 53a:	01 d0                	add    %edx,%eax
 53c:	01 c0                	add    %eax,%eax
 53e:	89 c2                	mov    %eax,%edx
 540:	8b 45 08             	mov    0x8(%ebp),%eax
 543:	0f b6 00             	movzbl (%eax),%eax
 546:	0f be c0             	movsbl %al,%eax
 549:	01 d0                	add    %edx,%eax
 54b:	83 e8 30             	sub    $0x30,%eax
 54e:	89 45 fc             	mov    %eax,-0x4(%ebp)
 551:	83 45 08 01          	addl   $0x1,0x8(%ebp)
atoi(const char *s)
{
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 555:	8b 45 08             	mov    0x8(%ebp),%eax
 558:	0f b6 00             	movzbl (%eax),%eax
 55b:	3c 2f                	cmp    $0x2f,%al
 55d:	7e 0a                	jle    569 <atoi+0x46>
 55f:	8b 45 08             	mov    0x8(%ebp),%eax
 562:	0f b6 00             	movzbl (%eax),%eax
 565:	3c 39                	cmp    $0x39,%al
 567:	7e c9                	jle    532 <atoi+0xf>
    n = n*10 + *s++ - '0';
  return n;
 569:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
 56c:	c9                   	leave  
 56d:	c3                   	ret    

0000056e <memmove>:

void*
memmove(void *vdst, void *vsrc, int n)
{
 56e:	55                   	push   %ebp
 56f:	89 e5                	mov    %esp,%ebp
 571:	83 ec 10             	sub    $0x10,%esp
  char *dst, *src;
  
  dst = vdst;
 574:	8b 45 08             	mov    0x8(%ebp),%eax
 577:	89 45 fc             	mov    %eax,-0x4(%ebp)
  src = vsrc;
 57a:	8b 45 0c             	mov    0xc(%ebp),%eax
 57d:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0)
 580:	eb 13                	jmp    595 <memmove+0x27>
    *dst++ = *src++;
 582:	8b 45 f8             	mov    -0x8(%ebp),%eax
 585:	0f b6 10             	movzbl (%eax),%edx
 588:	8b 45 fc             	mov    -0x4(%ebp),%eax
 58b:	88 10                	mov    %dl,(%eax)
 58d:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
 591:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  char *dst, *src;
  
  dst = vdst;
  src = vsrc;
  while(n-- > 0)
 595:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
 599:	0f 9f c0             	setg   %al
 59c:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
 5a0:	84 c0                	test   %al,%al
 5a2:	75 de                	jne    582 <memmove+0x14>
    *dst++ = *src++;
  return vdst;
 5a4:	8b 45 08             	mov    0x8(%ebp),%eax
}
 5a7:	c9                   	leave  
 5a8:	c3                   	ret    
 5a9:	90                   	nop
 5aa:	90                   	nop
 5ab:	90                   	nop

000005ac <fork>:
  name: \
    movl $SYS_ ## name, %eax; \
    int $T_SYSCALL; \
    ret

SYSCALL(fork)
 5ac:	b8 01 00 00 00       	mov    $0x1,%eax
 5b1:	cd 40                	int    $0x40
 5b3:	c3                   	ret    

000005b4 <exit>:
SYSCALL(exit)
 5b4:	b8 02 00 00 00       	mov    $0x2,%eax
 5b9:	cd 40                	int    $0x40
 5bb:	c3                   	ret    

000005bc <wait>:
SYSCALL(wait)
 5bc:	b8 03 00 00 00       	mov    $0x3,%eax
 5c1:	cd 40                	int    $0x40
 5c3:	c3                   	ret    

000005c4 <pipe>:
SYSCALL(pipe)
 5c4:	b8 04 00 00 00       	mov    $0x4,%eax
 5c9:	cd 40                	int    $0x40
 5cb:	c3                   	ret    

000005cc <read>:
SYSCALL(read)
 5cc:	b8 05 00 00 00       	mov    $0x5,%eax
 5d1:	cd 40                	int    $0x40
 5d3:	c3                   	ret    

000005d4 <write>:
SYSCALL(write)
 5d4:	b8 10 00 00 00       	mov    $0x10,%eax
 5d9:	cd 40                	int    $0x40
 5db:	c3                   	ret    

000005dc <close>:
SYSCALL(close)
 5dc:	b8 15 00 00 00       	mov    $0x15,%eax
 5e1:	cd 40                	int    $0x40
 5e3:	c3                   	ret    

000005e4 <kill>:
SYSCALL(kill)
 5e4:	b8 06 00 00 00       	mov    $0x6,%eax
 5e9:	cd 40                	int    $0x40
 5eb:	c3                   	ret    

000005ec <exec>:
SYSCALL(exec)
 5ec:	b8 07 00 00 00       	mov    $0x7,%eax
 5f1:	cd 40                	int    $0x40
 5f3:	c3                   	ret    

000005f4 <open>:
SYSCALL(open)
 5f4:	b8 0f 00 00 00       	mov    $0xf,%eax
 5f9:	cd 40                	int    $0x40
 5fb:	c3                   	ret    

000005fc <mknod>:
SYSCALL(mknod)
 5fc:	b8 11 00 00 00       	mov    $0x11,%eax
 601:	cd 40                	int    $0x40
 603:	c3                   	ret    

00000604 <unlink>:
SYSCALL(unlink)
 604:	b8 12 00 00 00       	mov    $0x12,%eax
 609:	cd 40                	int    $0x40
 60b:	c3                   	ret    

0000060c <fstat>:
SYSCALL(fstat)
 60c:	b8 08 00 00 00       	mov    $0x8,%eax
 611:	cd 40                	int    $0x40
 613:	c3                   	ret    

00000614 <link>:
SYSCALL(link)
 614:	b8 13 00 00 00       	mov    $0x13,%eax
 619:	cd 40                	int    $0x40
 61b:	c3                   	ret    

0000061c <mkdir>:
SYSCALL(mkdir)
 61c:	b8 14 00 00 00       	mov    $0x14,%eax
 621:	cd 40                	int    $0x40
 623:	c3                   	ret    

00000624 <chdir>:
SYSCALL(chdir)
 624:	b8 09 00 00 00       	mov    $0x9,%eax
 629:	cd 40                	int    $0x40
 62b:	c3                   	ret    

0000062c <dup>:
SYSCALL(dup)
 62c:	b8 0a 00 00 00       	mov    $0xa,%eax
 631:	cd 40                	int    $0x40
 633:	c3                   	ret    

00000634 <getpid>:
SYSCALL(getpid)
 634:	b8 0b 00 00 00       	mov    $0xb,%eax
 639:	cd 40                	int    $0x40
 63b:	c3                   	ret    

0000063c <sbrk>:
SYSCALL(sbrk)
 63c:	b8 0c 00 00 00       	mov    $0xc,%eax
 641:	cd 40                	int    $0x40
 643:	c3                   	ret    

00000644 <sleep>:
SYSCALL(sleep)
 644:	b8 0d 00 00 00       	mov    $0xd,%eax
 649:	cd 40                	int    $0x40
 64b:	c3                   	ret    

0000064c <uptime>:
SYSCALL(uptime)
 64c:	b8 0e 00 00 00       	mov    $0xe,%eax
 651:	cd 40                	int    $0x40
 653:	c3                   	ret    

00000654 <enableSwapping>:
SYSCALL(enableSwapping)
 654:	b8 16 00 00 00       	mov    $0x16,%eax
 659:	cd 40                	int    $0x40
 65b:	c3                   	ret    

0000065c <disableSwapping>:
SYSCALL(disableSwapping)
 65c:	b8 17 00 00 00       	mov    $0x17,%eax
 661:	cd 40                	int    $0x40
 663:	c3                   	ret    

00000664 <sleep2>:
SYSCALL(sleep2)
 664:	b8 18 00 00 00       	mov    $0x18,%eax
 669:	cd 40                	int    $0x40
 66b:	c3                   	ret    

0000066c <wakeup2>:
SYSCALL(wakeup2)
 66c:	b8 19 00 00 00       	mov    $0x19,%eax
 671:	cd 40                	int    $0x40
 673:	c3                   	ret    

00000674 <getAllocatedPages>:
SYSCALL(getAllocatedPages)
 674:	b8 1a 00 00 00       	mov    $0x1a,%eax
 679:	cd 40                	int    $0x40
 67b:	c3                   	ret    

0000067c <shmget>:
SYSCALL(shmget)
 67c:	b8 1b 00 00 00       	mov    $0x1b,%eax
 681:	cd 40                	int    $0x40
 683:	c3                   	ret    

00000684 <shmdel>:
SYSCALL(shmdel)
 684:	b8 1c 00 00 00       	mov    $0x1c,%eax
 689:	cd 40                	int    $0x40
 68b:	c3                   	ret    

0000068c <shmat>:
SYSCALL(shmat)
 68c:	b8 1d 00 00 00       	mov    $0x1d,%eax
 691:	cd 40                	int    $0x40
 693:	c3                   	ret    

00000694 <shmdt>:
 694:	b8 1e 00 00 00       	mov    $0x1e,%eax
 699:	cd 40                	int    $0x40
 69b:	c3                   	ret    

0000069c <putc>:
#include "stat.h"
#include "user.h"

static void
putc(int fd, char c)
{
 69c:	55                   	push   %ebp
 69d:	89 e5                	mov    %esp,%ebp
 69f:	83 ec 28             	sub    $0x28,%esp
 6a2:	8b 45 0c             	mov    0xc(%ebp),%eax
 6a5:	88 45 f4             	mov    %al,-0xc(%ebp)
  write(fd, &c, 1);
 6a8:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
 6af:	00 
 6b0:	8d 45 f4             	lea    -0xc(%ebp),%eax
 6b3:	89 44 24 04          	mov    %eax,0x4(%esp)
 6b7:	8b 45 08             	mov    0x8(%ebp),%eax
 6ba:	89 04 24             	mov    %eax,(%esp)
 6bd:	e8 12 ff ff ff       	call   5d4 <write>
}
 6c2:	c9                   	leave  
 6c3:	c3                   	ret    

000006c4 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 6c4:	55                   	push   %ebp
 6c5:	89 e5                	mov    %esp,%ebp
 6c7:	83 ec 48             	sub    $0x48,%esp
  static char digits[] = "0123456789ABCDEF";
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
 6ca:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  if(sgn && xx < 0){
 6d1:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
 6d5:	74 17                	je     6ee <printint+0x2a>
 6d7:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
 6db:	79 11                	jns    6ee <printint+0x2a>
    neg = 1;
 6dd:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
    x = -xx;
 6e4:	8b 45 0c             	mov    0xc(%ebp),%eax
 6e7:	f7 d8                	neg    %eax
 6e9:	89 45 ec             	mov    %eax,-0x14(%ebp)
 6ec:	eb 06                	jmp    6f4 <printint+0x30>
  } else {
    x = xx;
 6ee:	8b 45 0c             	mov    0xc(%ebp),%eax
 6f1:	89 45 ec             	mov    %eax,-0x14(%ebp)
  }

  i = 0;
 6f4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  do{
    buf[i++] = digits[x % base];
 6fb:	8b 4d 10             	mov    0x10(%ebp),%ecx
 6fe:	8b 45 ec             	mov    -0x14(%ebp),%eax
 701:	ba 00 00 00 00       	mov    $0x0,%edx
 706:	f7 f1                	div    %ecx
 708:	89 d0                	mov    %edx,%eax
 70a:	0f b6 90 34 0e 00 00 	movzbl 0xe34(%eax),%edx
 711:	8d 45 dc             	lea    -0x24(%ebp),%eax
 714:	03 45 f4             	add    -0xc(%ebp),%eax
 717:	88 10                	mov    %dl,(%eax)
 719:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  }while((x /= base) != 0);
 71d:	8b 55 10             	mov    0x10(%ebp),%edx
 720:	89 55 d4             	mov    %edx,-0x2c(%ebp)
 723:	8b 45 ec             	mov    -0x14(%ebp),%eax
 726:	ba 00 00 00 00       	mov    $0x0,%edx
 72b:	f7 75 d4             	divl   -0x2c(%ebp)
 72e:	89 45 ec             	mov    %eax,-0x14(%ebp)
 731:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
 735:	75 c4                	jne    6fb <printint+0x37>
  if(neg)
 737:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 73b:	74 2a                	je     767 <printint+0xa3>
    buf[i++] = '-';
 73d:	8d 45 dc             	lea    -0x24(%ebp),%eax
 740:	03 45 f4             	add    -0xc(%ebp),%eax
 743:	c6 00 2d             	movb   $0x2d,(%eax)
 746:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)

  while(--i >= 0)
 74a:	eb 1b                	jmp    767 <printint+0xa3>
    putc(fd, buf[i]);
 74c:	8d 45 dc             	lea    -0x24(%ebp),%eax
 74f:	03 45 f4             	add    -0xc(%ebp),%eax
 752:	0f b6 00             	movzbl (%eax),%eax
 755:	0f be c0             	movsbl %al,%eax
 758:	89 44 24 04          	mov    %eax,0x4(%esp)
 75c:	8b 45 08             	mov    0x8(%ebp),%eax
 75f:	89 04 24             	mov    %eax,(%esp)
 762:	e8 35 ff ff ff       	call   69c <putc>
    buf[i++] = digits[x % base];
  }while((x /= base) != 0);
  if(neg)
    buf[i++] = '-';

  while(--i >= 0)
 767:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
 76b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 76f:	79 db                	jns    74c <printint+0x88>
    putc(fd, buf[i]);
}
 771:	c9                   	leave  
 772:	c3                   	ret    

00000773 <printf>:

// Print to the given fd. Only understands %d, %x, %p, %s.
void
printf(int fd, char *fmt, ...)
{
 773:	55                   	push   %ebp
 774:	89 e5                	mov    %esp,%ebp
 776:	83 ec 38             	sub    $0x38,%esp
  char *s;
  int c, i, state;
  uint *ap;

  state = 0;
 779:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  ap = (uint*)(void*)&fmt + 1;
 780:	8d 45 0c             	lea    0xc(%ebp),%eax
 783:	83 c0 04             	add    $0x4,%eax
 786:	89 45 e8             	mov    %eax,-0x18(%ebp)
  for(i = 0; fmt[i]; i++){
 789:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
 790:	e9 7d 01 00 00       	jmp    912 <printf+0x19f>
    c = fmt[i] & 0xff;
 795:	8b 55 0c             	mov    0xc(%ebp),%edx
 798:	8b 45 f0             	mov    -0x10(%ebp),%eax
 79b:	01 d0                	add    %edx,%eax
 79d:	0f b6 00             	movzbl (%eax),%eax
 7a0:	0f be c0             	movsbl %al,%eax
 7a3:	25 ff 00 00 00       	and    $0xff,%eax
 7a8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(state == 0){
 7ab:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
 7af:	75 2c                	jne    7dd <printf+0x6a>
      if(c == '%'){
 7b1:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
 7b5:	75 0c                	jne    7c3 <printf+0x50>
        state = '%';
 7b7:	c7 45 ec 25 00 00 00 	movl   $0x25,-0x14(%ebp)
 7be:	e9 4b 01 00 00       	jmp    90e <printf+0x19b>
      } else {
        putc(fd, c);
 7c3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 7c6:	0f be c0             	movsbl %al,%eax
 7c9:	89 44 24 04          	mov    %eax,0x4(%esp)
 7cd:	8b 45 08             	mov    0x8(%ebp),%eax
 7d0:	89 04 24             	mov    %eax,(%esp)
 7d3:	e8 c4 fe ff ff       	call   69c <putc>
 7d8:	e9 31 01 00 00       	jmp    90e <printf+0x19b>
      }
    } else if(state == '%'){
 7dd:	83 7d ec 25          	cmpl   $0x25,-0x14(%ebp)
 7e1:	0f 85 27 01 00 00    	jne    90e <printf+0x19b>
      if(c == 'd'){
 7e7:	83 7d e4 64          	cmpl   $0x64,-0x1c(%ebp)
 7eb:	75 2d                	jne    81a <printf+0xa7>
        printint(fd, *ap, 10, 1);
 7ed:	8b 45 e8             	mov    -0x18(%ebp),%eax
 7f0:	8b 00                	mov    (%eax),%eax
 7f2:	c7 44 24 0c 01 00 00 	movl   $0x1,0xc(%esp)
 7f9:	00 
 7fa:	c7 44 24 08 0a 00 00 	movl   $0xa,0x8(%esp)
 801:	00 
 802:	89 44 24 04          	mov    %eax,0x4(%esp)
 806:	8b 45 08             	mov    0x8(%ebp),%eax
 809:	89 04 24             	mov    %eax,(%esp)
 80c:	e8 b3 fe ff ff       	call   6c4 <printint>
        ap++;
 811:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 815:	e9 ed 00 00 00       	jmp    907 <printf+0x194>
      } else if(c == 'x' || c == 'p'){
 81a:	83 7d e4 78          	cmpl   $0x78,-0x1c(%ebp)
 81e:	74 06                	je     826 <printf+0xb3>
 820:	83 7d e4 70          	cmpl   $0x70,-0x1c(%ebp)
 824:	75 2d                	jne    853 <printf+0xe0>
        printint(fd, *ap, 16, 0);
 826:	8b 45 e8             	mov    -0x18(%ebp),%eax
 829:	8b 00                	mov    (%eax),%eax
 82b:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
 832:	00 
 833:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
 83a:	00 
 83b:	89 44 24 04          	mov    %eax,0x4(%esp)
 83f:	8b 45 08             	mov    0x8(%ebp),%eax
 842:	89 04 24             	mov    %eax,(%esp)
 845:	e8 7a fe ff ff       	call   6c4 <printint>
        ap++;
 84a:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 84e:	e9 b4 00 00 00       	jmp    907 <printf+0x194>
      } else if(c == 's'){
 853:	83 7d e4 73          	cmpl   $0x73,-0x1c(%ebp)
 857:	75 46                	jne    89f <printf+0x12c>
        s = (char*)*ap;
 859:	8b 45 e8             	mov    -0x18(%ebp),%eax
 85c:	8b 00                	mov    (%eax),%eax
 85e:	89 45 f4             	mov    %eax,-0xc(%ebp)
        ap++;
 861:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
        if(s == 0)
 865:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 869:	75 27                	jne    892 <printf+0x11f>
          s = "(null)";
 86b:	c7 45 f4 6e 0b 00 00 	movl   $0xb6e,-0xc(%ebp)
        while(*s != 0){
 872:	eb 1e                	jmp    892 <printf+0x11f>
          putc(fd, *s);
 874:	8b 45 f4             	mov    -0xc(%ebp),%eax
 877:	0f b6 00             	movzbl (%eax),%eax
 87a:	0f be c0             	movsbl %al,%eax
 87d:	89 44 24 04          	mov    %eax,0x4(%esp)
 881:	8b 45 08             	mov    0x8(%ebp),%eax
 884:	89 04 24             	mov    %eax,(%esp)
 887:	e8 10 fe ff ff       	call   69c <putc>
          s++;
 88c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
 890:	eb 01                	jmp    893 <printf+0x120>
      } else if(c == 's'){
        s = (char*)*ap;
        ap++;
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 892:	90                   	nop
 893:	8b 45 f4             	mov    -0xc(%ebp),%eax
 896:	0f b6 00             	movzbl (%eax),%eax
 899:	84 c0                	test   %al,%al
 89b:	75 d7                	jne    874 <printf+0x101>
 89d:	eb 68                	jmp    907 <printf+0x194>
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 89f:	83 7d e4 63          	cmpl   $0x63,-0x1c(%ebp)
 8a3:	75 1d                	jne    8c2 <printf+0x14f>
        putc(fd, *ap);
 8a5:	8b 45 e8             	mov    -0x18(%ebp),%eax
 8a8:	8b 00                	mov    (%eax),%eax
 8aa:	0f be c0             	movsbl %al,%eax
 8ad:	89 44 24 04          	mov    %eax,0x4(%esp)
 8b1:	8b 45 08             	mov    0x8(%ebp),%eax
 8b4:	89 04 24             	mov    %eax,(%esp)
 8b7:	e8 e0 fd ff ff       	call   69c <putc>
        ap++;
 8bc:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 8c0:	eb 45                	jmp    907 <printf+0x194>
      } else if(c == '%'){
 8c2:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
 8c6:	75 17                	jne    8df <printf+0x16c>
        putc(fd, c);
 8c8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 8cb:	0f be c0             	movsbl %al,%eax
 8ce:	89 44 24 04          	mov    %eax,0x4(%esp)
 8d2:	8b 45 08             	mov    0x8(%ebp),%eax
 8d5:	89 04 24             	mov    %eax,(%esp)
 8d8:	e8 bf fd ff ff       	call   69c <putc>
 8dd:	eb 28                	jmp    907 <printf+0x194>
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 8df:	c7 44 24 04 25 00 00 	movl   $0x25,0x4(%esp)
 8e6:	00 
 8e7:	8b 45 08             	mov    0x8(%ebp),%eax
 8ea:	89 04 24             	mov    %eax,(%esp)
 8ed:	e8 aa fd ff ff       	call   69c <putc>
        putc(fd, c);
 8f2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 8f5:	0f be c0             	movsbl %al,%eax
 8f8:	89 44 24 04          	mov    %eax,0x4(%esp)
 8fc:	8b 45 08             	mov    0x8(%ebp),%eax
 8ff:	89 04 24             	mov    %eax,(%esp)
 902:	e8 95 fd ff ff       	call   69c <putc>
      }
      state = 0;
 907:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  int c, i, state;
  uint *ap;

  state = 0;
  ap = (uint*)(void*)&fmt + 1;
  for(i = 0; fmt[i]; i++){
 90e:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
 912:	8b 55 0c             	mov    0xc(%ebp),%edx
 915:	8b 45 f0             	mov    -0x10(%ebp),%eax
 918:	01 d0                	add    %edx,%eax
 91a:	0f b6 00             	movzbl (%eax),%eax
 91d:	84 c0                	test   %al,%al
 91f:	0f 85 70 fe ff ff    	jne    795 <printf+0x22>
        putc(fd, c);
      }
      state = 0;
    }
  }
}
 925:	c9                   	leave  
 926:	c3                   	ret    
 927:	90                   	nop

00000928 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 928:	55                   	push   %ebp
 929:	89 e5                	mov    %esp,%ebp
 92b:	83 ec 10             	sub    $0x10,%esp
  Header *bp, *p;

  bp = (Header*)ap - 1;
 92e:	8b 45 08             	mov    0x8(%ebp),%eax
 931:	83 e8 08             	sub    $0x8,%eax
 934:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 937:	a1 68 0e 00 00       	mov    0xe68,%eax
 93c:	89 45 fc             	mov    %eax,-0x4(%ebp)
 93f:	eb 24                	jmp    965 <free+0x3d>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 941:	8b 45 fc             	mov    -0x4(%ebp),%eax
 944:	8b 00                	mov    (%eax),%eax
 946:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 949:	77 12                	ja     95d <free+0x35>
 94b:	8b 45 f8             	mov    -0x8(%ebp),%eax
 94e:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 951:	77 24                	ja     977 <free+0x4f>
 953:	8b 45 fc             	mov    -0x4(%ebp),%eax
 956:	8b 00                	mov    (%eax),%eax
 958:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 95b:	77 1a                	ja     977 <free+0x4f>
free(void *ap)
{
  Header *bp, *p;

  bp = (Header*)ap - 1;
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 95d:	8b 45 fc             	mov    -0x4(%ebp),%eax
 960:	8b 00                	mov    (%eax),%eax
 962:	89 45 fc             	mov    %eax,-0x4(%ebp)
 965:	8b 45 f8             	mov    -0x8(%ebp),%eax
 968:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 96b:	76 d4                	jbe    941 <free+0x19>
 96d:	8b 45 fc             	mov    -0x4(%ebp),%eax
 970:	8b 00                	mov    (%eax),%eax
 972:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 975:	76 ca                	jbe    941 <free+0x19>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
 977:	8b 45 f8             	mov    -0x8(%ebp),%eax
 97a:	8b 40 04             	mov    0x4(%eax),%eax
 97d:	c1 e0 03             	shl    $0x3,%eax
 980:	89 c2                	mov    %eax,%edx
 982:	03 55 f8             	add    -0x8(%ebp),%edx
 985:	8b 45 fc             	mov    -0x4(%ebp),%eax
 988:	8b 00                	mov    (%eax),%eax
 98a:	39 c2                	cmp    %eax,%edx
 98c:	75 24                	jne    9b2 <free+0x8a>
    bp->s.size += p->s.ptr->s.size;
 98e:	8b 45 f8             	mov    -0x8(%ebp),%eax
 991:	8b 50 04             	mov    0x4(%eax),%edx
 994:	8b 45 fc             	mov    -0x4(%ebp),%eax
 997:	8b 00                	mov    (%eax),%eax
 999:	8b 40 04             	mov    0x4(%eax),%eax
 99c:	01 c2                	add    %eax,%edx
 99e:	8b 45 f8             	mov    -0x8(%ebp),%eax
 9a1:	89 50 04             	mov    %edx,0x4(%eax)
    bp->s.ptr = p->s.ptr->s.ptr;
 9a4:	8b 45 fc             	mov    -0x4(%ebp),%eax
 9a7:	8b 00                	mov    (%eax),%eax
 9a9:	8b 10                	mov    (%eax),%edx
 9ab:	8b 45 f8             	mov    -0x8(%ebp),%eax
 9ae:	89 10                	mov    %edx,(%eax)
 9b0:	eb 0a                	jmp    9bc <free+0x94>
  } else
    bp->s.ptr = p->s.ptr;
 9b2:	8b 45 fc             	mov    -0x4(%ebp),%eax
 9b5:	8b 10                	mov    (%eax),%edx
 9b7:	8b 45 f8             	mov    -0x8(%ebp),%eax
 9ba:	89 10                	mov    %edx,(%eax)
  if(p + p->s.size == bp){
 9bc:	8b 45 fc             	mov    -0x4(%ebp),%eax
 9bf:	8b 40 04             	mov    0x4(%eax),%eax
 9c2:	c1 e0 03             	shl    $0x3,%eax
 9c5:	03 45 fc             	add    -0x4(%ebp),%eax
 9c8:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 9cb:	75 20                	jne    9ed <free+0xc5>
    p->s.size += bp->s.size;
 9cd:	8b 45 fc             	mov    -0x4(%ebp),%eax
 9d0:	8b 50 04             	mov    0x4(%eax),%edx
 9d3:	8b 45 f8             	mov    -0x8(%ebp),%eax
 9d6:	8b 40 04             	mov    0x4(%eax),%eax
 9d9:	01 c2                	add    %eax,%edx
 9db:	8b 45 fc             	mov    -0x4(%ebp),%eax
 9de:	89 50 04             	mov    %edx,0x4(%eax)
    p->s.ptr = bp->s.ptr;
 9e1:	8b 45 f8             	mov    -0x8(%ebp),%eax
 9e4:	8b 10                	mov    (%eax),%edx
 9e6:	8b 45 fc             	mov    -0x4(%ebp),%eax
 9e9:	89 10                	mov    %edx,(%eax)
 9eb:	eb 08                	jmp    9f5 <free+0xcd>
  } else
    p->s.ptr = bp;
 9ed:	8b 45 fc             	mov    -0x4(%ebp),%eax
 9f0:	8b 55 f8             	mov    -0x8(%ebp),%edx
 9f3:	89 10                	mov    %edx,(%eax)
  freep = p;
 9f5:	8b 45 fc             	mov    -0x4(%ebp),%eax
 9f8:	a3 68 0e 00 00       	mov    %eax,0xe68
}
 9fd:	c9                   	leave  
 9fe:	c3                   	ret    

000009ff <morecore>:

static Header*
morecore(uint nu)
{
 9ff:	55                   	push   %ebp
 a00:	89 e5                	mov    %esp,%ebp
 a02:	83 ec 28             	sub    $0x28,%esp
  char *p;
  Header *hp;

  if(nu < 4096)
 a05:	81 7d 08 ff 0f 00 00 	cmpl   $0xfff,0x8(%ebp)
 a0c:	77 07                	ja     a15 <morecore+0x16>
    nu = 4096;
 a0e:	c7 45 08 00 10 00 00 	movl   $0x1000,0x8(%ebp)
  p = sbrk(nu * sizeof(Header));
 a15:	8b 45 08             	mov    0x8(%ebp),%eax
 a18:	c1 e0 03             	shl    $0x3,%eax
 a1b:	89 04 24             	mov    %eax,(%esp)
 a1e:	e8 19 fc ff ff       	call   63c <sbrk>
 a23:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(p == (char*)-1)
 a26:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
 a2a:	75 07                	jne    a33 <morecore+0x34>
    return 0;
 a2c:	b8 00 00 00 00       	mov    $0x0,%eax
 a31:	eb 22                	jmp    a55 <morecore+0x56>
  hp = (Header*)p;
 a33:	8b 45 f4             	mov    -0xc(%ebp),%eax
 a36:	89 45 f0             	mov    %eax,-0x10(%ebp)
  hp->s.size = nu;
 a39:	8b 45 f0             	mov    -0x10(%ebp),%eax
 a3c:	8b 55 08             	mov    0x8(%ebp),%edx
 a3f:	89 50 04             	mov    %edx,0x4(%eax)
  free((void*)(hp + 1));
 a42:	8b 45 f0             	mov    -0x10(%ebp),%eax
 a45:	83 c0 08             	add    $0x8,%eax
 a48:	89 04 24             	mov    %eax,(%esp)
 a4b:	e8 d8 fe ff ff       	call   928 <free>
  return freep;
 a50:	a1 68 0e 00 00       	mov    0xe68,%eax
}
 a55:	c9                   	leave  
 a56:	c3                   	ret    

00000a57 <malloc>:

void*
malloc(uint nbytes)
{
 a57:	55                   	push   %ebp
 a58:	89 e5                	mov    %esp,%ebp
 a5a:	83 ec 28             	sub    $0x28,%esp
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 a5d:	8b 45 08             	mov    0x8(%ebp),%eax
 a60:	83 c0 07             	add    $0x7,%eax
 a63:	c1 e8 03             	shr    $0x3,%eax
 a66:	83 c0 01             	add    $0x1,%eax
 a69:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((prevp = freep) == 0){
 a6c:	a1 68 0e 00 00       	mov    0xe68,%eax
 a71:	89 45 f0             	mov    %eax,-0x10(%ebp)
 a74:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 a78:	75 23                	jne    a9d <malloc+0x46>
    base.s.ptr = freep = prevp = &base;
 a7a:	c7 45 f0 60 0e 00 00 	movl   $0xe60,-0x10(%ebp)
 a81:	8b 45 f0             	mov    -0x10(%ebp),%eax
 a84:	a3 68 0e 00 00       	mov    %eax,0xe68
 a89:	a1 68 0e 00 00       	mov    0xe68,%eax
 a8e:	a3 60 0e 00 00       	mov    %eax,0xe60
    base.s.size = 0;
 a93:	c7 05 64 0e 00 00 00 	movl   $0x0,0xe64
 a9a:	00 00 00 
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 a9d:	8b 45 f0             	mov    -0x10(%ebp),%eax
 aa0:	8b 00                	mov    (%eax),%eax
 aa2:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(p->s.size >= nunits){
 aa5:	8b 45 f4             	mov    -0xc(%ebp),%eax
 aa8:	8b 40 04             	mov    0x4(%eax),%eax
 aab:	3b 45 ec             	cmp    -0x14(%ebp),%eax
 aae:	72 4d                	jb     afd <malloc+0xa6>
      if(p->s.size == nunits)
 ab0:	8b 45 f4             	mov    -0xc(%ebp),%eax
 ab3:	8b 40 04             	mov    0x4(%eax),%eax
 ab6:	3b 45 ec             	cmp    -0x14(%ebp),%eax
 ab9:	75 0c                	jne    ac7 <malloc+0x70>
        prevp->s.ptr = p->s.ptr;
 abb:	8b 45 f4             	mov    -0xc(%ebp),%eax
 abe:	8b 10                	mov    (%eax),%edx
 ac0:	8b 45 f0             	mov    -0x10(%ebp),%eax
 ac3:	89 10                	mov    %edx,(%eax)
 ac5:	eb 26                	jmp    aed <malloc+0x96>
      else {
        p->s.size -= nunits;
 ac7:	8b 45 f4             	mov    -0xc(%ebp),%eax
 aca:	8b 40 04             	mov    0x4(%eax),%eax
 acd:	89 c2                	mov    %eax,%edx
 acf:	2b 55 ec             	sub    -0x14(%ebp),%edx
 ad2:	8b 45 f4             	mov    -0xc(%ebp),%eax
 ad5:	89 50 04             	mov    %edx,0x4(%eax)
        p += p->s.size;
 ad8:	8b 45 f4             	mov    -0xc(%ebp),%eax
 adb:	8b 40 04             	mov    0x4(%eax),%eax
 ade:	c1 e0 03             	shl    $0x3,%eax
 ae1:	01 45 f4             	add    %eax,-0xc(%ebp)
        p->s.size = nunits;
 ae4:	8b 45 f4             	mov    -0xc(%ebp),%eax
 ae7:	8b 55 ec             	mov    -0x14(%ebp),%edx
 aea:	89 50 04             	mov    %edx,0x4(%eax)
      }
      freep = prevp;
 aed:	8b 45 f0             	mov    -0x10(%ebp),%eax
 af0:	a3 68 0e 00 00       	mov    %eax,0xe68
      return (void*)(p + 1);
 af5:	8b 45 f4             	mov    -0xc(%ebp),%eax
 af8:	83 c0 08             	add    $0x8,%eax
 afb:	eb 38                	jmp    b35 <malloc+0xde>
    }
    if(p == freep)
 afd:	a1 68 0e 00 00       	mov    0xe68,%eax
 b02:	39 45 f4             	cmp    %eax,-0xc(%ebp)
 b05:	75 1b                	jne    b22 <malloc+0xcb>
      if((p = morecore(nunits)) == 0)
 b07:	8b 45 ec             	mov    -0x14(%ebp),%eax
 b0a:	89 04 24             	mov    %eax,(%esp)
 b0d:	e8 ed fe ff ff       	call   9ff <morecore>
 b12:	89 45 f4             	mov    %eax,-0xc(%ebp)
 b15:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 b19:	75 07                	jne    b22 <malloc+0xcb>
        return 0;
 b1b:	b8 00 00 00 00       	mov    $0x0,%eax
 b20:	eb 13                	jmp    b35 <malloc+0xde>
  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
  if((prevp = freep) == 0){
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 b22:	8b 45 f4             	mov    -0xc(%ebp),%eax
 b25:	89 45 f0             	mov    %eax,-0x10(%ebp)
 b28:	8b 45 f4             	mov    -0xc(%ebp),%eax
 b2b:	8b 00                	mov    (%eax),%eax
 b2d:	89 45 f4             	mov    %eax,-0xc(%ebp)
      return (void*)(p + 1);
    }
    if(p == freep)
      if((p = morecore(nunits)) == 0)
        return 0;
  }
 b30:	e9 70 ff ff ff       	jmp    aa5 <malloc+0x4e>
}
 b35:	c9                   	leave  
 b36:	c3                   	ret    
