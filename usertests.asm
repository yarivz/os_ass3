
_usertests:     file format elf32-i386


Disassembly of section .text:

00000000 <opentest>:

// simple file system tests

void
opentest(void)
{
       0:	55                   	push   %ebp
       1:	89 e5                	mov    %esp,%ebp
       3:	83 ec 28             	sub    $0x28,%esp
  int fd;

  printf(stdout, "open test\n");
       6:	a1 14 5f 00 00       	mov    0x5f14,%eax
       b:	c7 44 24 04 d2 41 00 	movl   $0x41d2,0x4(%esp)
      12:	00 
      13:	89 04 24             	mov    %eax,(%esp)
      16:	e8 dc 3d 00 00       	call   3df7 <printf>
  fd = open("echo", 0);
      1b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
      22:	00 
      23:	c7 04 24 bc 41 00 00 	movl   $0x41bc,(%esp)
      2a:	e8 49 3c 00 00       	call   3c78 <open>
      2f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(fd < 0){
      32:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
      36:	79 1a                	jns    52 <opentest+0x52>
    printf(stdout, "open echo failed!\n");
      38:	a1 14 5f 00 00       	mov    0x5f14,%eax
      3d:	c7 44 24 04 dd 41 00 	movl   $0x41dd,0x4(%esp)
      44:	00 
      45:	89 04 24             	mov    %eax,(%esp)
      48:	e8 aa 3d 00 00       	call   3df7 <printf>
    exit();
      4d:	e8 e6 3b 00 00       	call   3c38 <exit>
  }
  close(fd);
      52:	8b 45 f4             	mov    -0xc(%ebp),%eax
      55:	89 04 24             	mov    %eax,(%esp)
      58:	e8 03 3c 00 00       	call   3c60 <close>
  fd = open("doesnotexist", 0);
      5d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
      64:	00 
      65:	c7 04 24 f0 41 00 00 	movl   $0x41f0,(%esp)
      6c:	e8 07 3c 00 00       	call   3c78 <open>
      71:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(fd >= 0){
      74:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
      78:	78 1a                	js     94 <opentest+0x94>
    printf(stdout, "open doesnotexist succeeded!\n");
      7a:	a1 14 5f 00 00       	mov    0x5f14,%eax
      7f:	c7 44 24 04 fd 41 00 	movl   $0x41fd,0x4(%esp)
      86:	00 
      87:	89 04 24             	mov    %eax,(%esp)
      8a:	e8 68 3d 00 00       	call   3df7 <printf>
    exit();
      8f:	e8 a4 3b 00 00       	call   3c38 <exit>
  }
  printf(stdout, "open test ok\n");
      94:	a1 14 5f 00 00       	mov    0x5f14,%eax
      99:	c7 44 24 04 1b 42 00 	movl   $0x421b,0x4(%esp)
      a0:	00 
      a1:	89 04 24             	mov    %eax,(%esp)
      a4:	e8 4e 3d 00 00       	call   3df7 <printf>
}
      a9:	c9                   	leave  
      aa:	c3                   	ret    

000000ab <writetest>:

void
writetest(void)
{
      ab:	55                   	push   %ebp
      ac:	89 e5                	mov    %esp,%ebp
      ae:	83 ec 28             	sub    $0x28,%esp
  int fd;
  int i;

  printf(stdout, "small file test\n");
      b1:	a1 14 5f 00 00       	mov    0x5f14,%eax
      b6:	c7 44 24 04 29 42 00 	movl   $0x4229,0x4(%esp)
      bd:	00 
      be:	89 04 24             	mov    %eax,(%esp)
      c1:	e8 31 3d 00 00       	call   3df7 <printf>
  fd = open("small", O_CREATE|O_RDWR);
      c6:	c7 44 24 04 02 02 00 	movl   $0x202,0x4(%esp)
      cd:	00 
      ce:	c7 04 24 3a 42 00 00 	movl   $0x423a,(%esp)
      d5:	e8 9e 3b 00 00       	call   3c78 <open>
      da:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(fd >= 0){
      dd:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
      e1:	78 21                	js     104 <writetest+0x59>
    printf(stdout, "creat small succeeded; ok\n");
      e3:	a1 14 5f 00 00       	mov    0x5f14,%eax
      e8:	c7 44 24 04 40 42 00 	movl   $0x4240,0x4(%esp)
      ef:	00 
      f0:	89 04 24             	mov    %eax,(%esp)
      f3:	e8 ff 3c 00 00       	call   3df7 <printf>
  } else {
    printf(stdout, "error: creat small failed!\n");
    exit();
  }
  for(i = 0; i < 100; i++){
      f8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
      ff:	e9 a0 00 00 00       	jmp    1a4 <writetest+0xf9>
  printf(stdout, "small file test\n");
  fd = open("small", O_CREATE|O_RDWR);
  if(fd >= 0){
    printf(stdout, "creat small succeeded; ok\n");
  } else {
    printf(stdout, "error: creat small failed!\n");
     104:	a1 14 5f 00 00       	mov    0x5f14,%eax
     109:	c7 44 24 04 5b 42 00 	movl   $0x425b,0x4(%esp)
     110:	00 
     111:	89 04 24             	mov    %eax,(%esp)
     114:	e8 de 3c 00 00       	call   3df7 <printf>
    exit();
     119:	e8 1a 3b 00 00       	call   3c38 <exit>
  }
  for(i = 0; i < 100; i++){
    if(write(fd, "aaaaaaaaaa", 10) != 10){
     11e:	c7 44 24 08 0a 00 00 	movl   $0xa,0x8(%esp)
     125:	00 
     126:	c7 44 24 04 77 42 00 	movl   $0x4277,0x4(%esp)
     12d:	00 
     12e:	8b 45 f0             	mov    -0x10(%ebp),%eax
     131:	89 04 24             	mov    %eax,(%esp)
     134:	e8 1f 3b 00 00       	call   3c58 <write>
     139:	83 f8 0a             	cmp    $0xa,%eax
     13c:	74 21                	je     15f <writetest+0xb4>
      printf(stdout, "error: write aa %d new file failed\n", i);
     13e:	a1 14 5f 00 00       	mov    0x5f14,%eax
     143:	8b 55 f4             	mov    -0xc(%ebp),%edx
     146:	89 54 24 08          	mov    %edx,0x8(%esp)
     14a:	c7 44 24 04 84 42 00 	movl   $0x4284,0x4(%esp)
     151:	00 
     152:	89 04 24             	mov    %eax,(%esp)
     155:	e8 9d 3c 00 00       	call   3df7 <printf>
      exit();
     15a:	e8 d9 3a 00 00       	call   3c38 <exit>
    }
    if(write(fd, "bbbbbbbbbb", 10) != 10){
     15f:	c7 44 24 08 0a 00 00 	movl   $0xa,0x8(%esp)
     166:	00 
     167:	c7 44 24 04 a8 42 00 	movl   $0x42a8,0x4(%esp)
     16e:	00 
     16f:	8b 45 f0             	mov    -0x10(%ebp),%eax
     172:	89 04 24             	mov    %eax,(%esp)
     175:	e8 de 3a 00 00       	call   3c58 <write>
     17a:	83 f8 0a             	cmp    $0xa,%eax
     17d:	74 21                	je     1a0 <writetest+0xf5>
      printf(stdout, "error: write bb %d new file failed\n", i);
     17f:	a1 14 5f 00 00       	mov    0x5f14,%eax
     184:	8b 55 f4             	mov    -0xc(%ebp),%edx
     187:	89 54 24 08          	mov    %edx,0x8(%esp)
     18b:	c7 44 24 04 b4 42 00 	movl   $0x42b4,0x4(%esp)
     192:	00 
     193:	89 04 24             	mov    %eax,(%esp)
     196:	e8 5c 3c 00 00       	call   3df7 <printf>
      exit();
     19b:	e8 98 3a 00 00       	call   3c38 <exit>
    printf(stdout, "creat small succeeded; ok\n");
  } else {
    printf(stdout, "error: creat small failed!\n");
    exit();
  }
  for(i = 0; i < 100; i++){
     1a0:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
     1a4:	83 7d f4 63          	cmpl   $0x63,-0xc(%ebp)
     1a8:	0f 8e 70 ff ff ff    	jle    11e <writetest+0x73>
    if(write(fd, "bbbbbbbbbb", 10) != 10){
      printf(stdout, "error: write bb %d new file failed\n", i);
      exit();
    }
  }
  printf(stdout, "writes ok\n");
     1ae:	a1 14 5f 00 00       	mov    0x5f14,%eax
     1b3:	c7 44 24 04 d8 42 00 	movl   $0x42d8,0x4(%esp)
     1ba:	00 
     1bb:	89 04 24             	mov    %eax,(%esp)
     1be:	e8 34 3c 00 00       	call   3df7 <printf>
  close(fd);
     1c3:	8b 45 f0             	mov    -0x10(%ebp),%eax
     1c6:	89 04 24             	mov    %eax,(%esp)
     1c9:	e8 92 3a 00 00       	call   3c60 <close>
  fd = open("small", O_RDONLY);
     1ce:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
     1d5:	00 
     1d6:	c7 04 24 3a 42 00 00 	movl   $0x423a,(%esp)
     1dd:	e8 96 3a 00 00       	call   3c78 <open>
     1e2:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(fd >= 0){
     1e5:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
     1e9:	78 3e                	js     229 <writetest+0x17e>
    printf(stdout, "open small succeeded ok\n");
     1eb:	a1 14 5f 00 00       	mov    0x5f14,%eax
     1f0:	c7 44 24 04 e3 42 00 	movl   $0x42e3,0x4(%esp)
     1f7:	00 
     1f8:	89 04 24             	mov    %eax,(%esp)
     1fb:	e8 f7 3b 00 00       	call   3df7 <printf>
  } else {
    printf(stdout, "error: open small failed!\n");
    exit();
  }
  i = read(fd, buf, 2000);
     200:	c7 44 24 08 d0 07 00 	movl   $0x7d0,0x8(%esp)
     207:	00 
     208:	c7 44 24 04 00 87 00 	movl   $0x8700,0x4(%esp)
     20f:	00 
     210:	8b 45 f0             	mov    -0x10(%ebp),%eax
     213:	89 04 24             	mov    %eax,(%esp)
     216:	e8 35 3a 00 00       	call   3c50 <read>
     21b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(i == 2000){
     21e:	81 7d f4 d0 07 00 00 	cmpl   $0x7d0,-0xc(%ebp)
     225:	74 1c                	je     243 <writetest+0x198>
     227:	eb 4c                	jmp    275 <writetest+0x1ca>
  close(fd);
  fd = open("small", O_RDONLY);
  if(fd >= 0){
    printf(stdout, "open small succeeded ok\n");
  } else {
    printf(stdout, "error: open small failed!\n");
     229:	a1 14 5f 00 00       	mov    0x5f14,%eax
     22e:	c7 44 24 04 fc 42 00 	movl   $0x42fc,0x4(%esp)
     235:	00 
     236:	89 04 24             	mov    %eax,(%esp)
     239:	e8 b9 3b 00 00       	call   3df7 <printf>
    exit();
     23e:	e8 f5 39 00 00       	call   3c38 <exit>
  }
  i = read(fd, buf, 2000);
  if(i == 2000){
    printf(stdout, "read succeeded ok\n");
     243:	a1 14 5f 00 00       	mov    0x5f14,%eax
     248:	c7 44 24 04 17 43 00 	movl   $0x4317,0x4(%esp)
     24f:	00 
     250:	89 04 24             	mov    %eax,(%esp)
     253:	e8 9f 3b 00 00       	call   3df7 <printf>
  } else {
    printf(stdout, "read failed\n");
    exit();
  }
  close(fd);
     258:	8b 45 f0             	mov    -0x10(%ebp),%eax
     25b:	89 04 24             	mov    %eax,(%esp)
     25e:	e8 fd 39 00 00       	call   3c60 <close>

  if(unlink("small") < 0){
     263:	c7 04 24 3a 42 00 00 	movl   $0x423a,(%esp)
     26a:	e8 19 3a 00 00       	call   3c88 <unlink>
     26f:	85 c0                	test   %eax,%eax
     271:	78 1c                	js     28f <writetest+0x1e4>
     273:	eb 34                	jmp    2a9 <writetest+0x1fe>
  }
  i = read(fd, buf, 2000);
  if(i == 2000){
    printf(stdout, "read succeeded ok\n");
  } else {
    printf(stdout, "read failed\n");
     275:	a1 14 5f 00 00       	mov    0x5f14,%eax
     27a:	c7 44 24 04 2a 43 00 	movl   $0x432a,0x4(%esp)
     281:	00 
     282:	89 04 24             	mov    %eax,(%esp)
     285:	e8 6d 3b 00 00       	call   3df7 <printf>
    exit();
     28a:	e8 a9 39 00 00       	call   3c38 <exit>
  }
  close(fd);

  if(unlink("small") < 0){
    printf(stdout, "unlink small failed\n");
     28f:	a1 14 5f 00 00       	mov    0x5f14,%eax
     294:	c7 44 24 04 37 43 00 	movl   $0x4337,0x4(%esp)
     29b:	00 
     29c:	89 04 24             	mov    %eax,(%esp)
     29f:	e8 53 3b 00 00       	call   3df7 <printf>
    exit();
     2a4:	e8 8f 39 00 00       	call   3c38 <exit>
  }
  printf(stdout, "small file test ok\n");
     2a9:	a1 14 5f 00 00       	mov    0x5f14,%eax
     2ae:	c7 44 24 04 4c 43 00 	movl   $0x434c,0x4(%esp)
     2b5:	00 
     2b6:	89 04 24             	mov    %eax,(%esp)
     2b9:	e8 39 3b 00 00       	call   3df7 <printf>
}
     2be:	c9                   	leave  
     2bf:	c3                   	ret    

000002c0 <writetest1>:

void
writetest1(void)
{
     2c0:	55                   	push   %ebp
     2c1:	89 e5                	mov    %esp,%ebp
     2c3:	83 ec 28             	sub    $0x28,%esp
  int i, fd, n;

  printf(stdout, "big files test\n");
     2c6:	a1 14 5f 00 00       	mov    0x5f14,%eax
     2cb:	c7 44 24 04 60 43 00 	movl   $0x4360,0x4(%esp)
     2d2:	00 
     2d3:	89 04 24             	mov    %eax,(%esp)
     2d6:	e8 1c 3b 00 00       	call   3df7 <printf>

  fd = open("big", O_CREATE|O_RDWR);
     2db:	c7 44 24 04 02 02 00 	movl   $0x202,0x4(%esp)
     2e2:	00 
     2e3:	c7 04 24 70 43 00 00 	movl   $0x4370,(%esp)
     2ea:	e8 89 39 00 00       	call   3c78 <open>
     2ef:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(fd < 0){
     2f2:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
     2f6:	79 1a                	jns    312 <writetest1+0x52>
    printf(stdout, "error: creat big failed!\n");
     2f8:	a1 14 5f 00 00       	mov    0x5f14,%eax
     2fd:	c7 44 24 04 74 43 00 	movl   $0x4374,0x4(%esp)
     304:	00 
     305:	89 04 24             	mov    %eax,(%esp)
     308:	e8 ea 3a 00 00       	call   3df7 <printf>
    exit();
     30d:	e8 26 39 00 00       	call   3c38 <exit>
  }

  for(i = 0; i < MAXFILE; i++){
     312:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
     319:	eb 51                	jmp    36c <writetest1+0xac>
    ((int*)buf)[0] = i;
     31b:	b8 00 87 00 00       	mov    $0x8700,%eax
     320:	8b 55 f4             	mov    -0xc(%ebp),%edx
     323:	89 10                	mov    %edx,(%eax)
    if(write(fd, buf, 512) != 512){
     325:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
     32c:	00 
     32d:	c7 44 24 04 00 87 00 	movl   $0x8700,0x4(%esp)
     334:	00 
     335:	8b 45 ec             	mov    -0x14(%ebp),%eax
     338:	89 04 24             	mov    %eax,(%esp)
     33b:	e8 18 39 00 00       	call   3c58 <write>
     340:	3d 00 02 00 00       	cmp    $0x200,%eax
     345:	74 21                	je     368 <writetest1+0xa8>
      printf(stdout, "error: write big file failed\n", i);
     347:	a1 14 5f 00 00       	mov    0x5f14,%eax
     34c:	8b 55 f4             	mov    -0xc(%ebp),%edx
     34f:	89 54 24 08          	mov    %edx,0x8(%esp)
     353:	c7 44 24 04 8e 43 00 	movl   $0x438e,0x4(%esp)
     35a:	00 
     35b:	89 04 24             	mov    %eax,(%esp)
     35e:	e8 94 3a 00 00       	call   3df7 <printf>
      exit();
     363:	e8 d0 38 00 00       	call   3c38 <exit>
  if(fd < 0){
    printf(stdout, "error: creat big failed!\n");
    exit();
  }

  for(i = 0; i < MAXFILE; i++){
     368:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
     36c:	8b 45 f4             	mov    -0xc(%ebp),%eax
     36f:	3d 8b 00 00 00       	cmp    $0x8b,%eax
     374:	76 a5                	jbe    31b <writetest1+0x5b>
      printf(stdout, "error: write big file failed\n", i);
      exit();
    }
  }

  close(fd);
     376:	8b 45 ec             	mov    -0x14(%ebp),%eax
     379:	89 04 24             	mov    %eax,(%esp)
     37c:	e8 df 38 00 00       	call   3c60 <close>

  fd = open("big", O_RDONLY);
     381:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
     388:	00 
     389:	c7 04 24 70 43 00 00 	movl   $0x4370,(%esp)
     390:	e8 e3 38 00 00       	call   3c78 <open>
     395:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(fd < 0){
     398:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
     39c:	79 1a                	jns    3b8 <writetest1+0xf8>
    printf(stdout, "error: open big failed!\n");
     39e:	a1 14 5f 00 00       	mov    0x5f14,%eax
     3a3:	c7 44 24 04 ac 43 00 	movl   $0x43ac,0x4(%esp)
     3aa:	00 
     3ab:	89 04 24             	mov    %eax,(%esp)
     3ae:	e8 44 3a 00 00       	call   3df7 <printf>
    exit();
     3b3:	e8 80 38 00 00       	call   3c38 <exit>
  }

  n = 0;
     3b8:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  for(;;){
    i = read(fd, buf, 512);
     3bf:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
     3c6:	00 
     3c7:	c7 44 24 04 00 87 00 	movl   $0x8700,0x4(%esp)
     3ce:	00 
     3cf:	8b 45 ec             	mov    -0x14(%ebp),%eax
     3d2:	89 04 24             	mov    %eax,(%esp)
     3d5:	e8 76 38 00 00       	call   3c50 <read>
     3da:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(i == 0){
     3dd:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
     3e1:	75 2e                	jne    411 <writetest1+0x151>
      if(n == MAXFILE - 1){
     3e3:	81 7d f0 8b 00 00 00 	cmpl   $0x8b,-0x10(%ebp)
     3ea:	0f 85 8c 00 00 00    	jne    47c <writetest1+0x1bc>
        printf(stdout, "read only %d blocks from big", n);
     3f0:	a1 14 5f 00 00       	mov    0x5f14,%eax
     3f5:	8b 55 f0             	mov    -0x10(%ebp),%edx
     3f8:	89 54 24 08          	mov    %edx,0x8(%esp)
     3fc:	c7 44 24 04 c5 43 00 	movl   $0x43c5,0x4(%esp)
     403:	00 
     404:	89 04 24             	mov    %eax,(%esp)
     407:	e8 eb 39 00 00       	call   3df7 <printf>
        exit();
     40c:	e8 27 38 00 00       	call   3c38 <exit>
      }
      break;
    } else if(i != 512){
     411:	81 7d f4 00 02 00 00 	cmpl   $0x200,-0xc(%ebp)
     418:	74 21                	je     43b <writetest1+0x17b>
      printf(stdout, "read failed %d\n", i);
     41a:	a1 14 5f 00 00       	mov    0x5f14,%eax
     41f:	8b 55 f4             	mov    -0xc(%ebp),%edx
     422:	89 54 24 08          	mov    %edx,0x8(%esp)
     426:	c7 44 24 04 e2 43 00 	movl   $0x43e2,0x4(%esp)
     42d:	00 
     42e:	89 04 24             	mov    %eax,(%esp)
     431:	e8 c1 39 00 00       	call   3df7 <printf>
      exit();
     436:	e8 fd 37 00 00       	call   3c38 <exit>
    }
    if(((int*)buf)[0] != n){
     43b:	b8 00 87 00 00       	mov    $0x8700,%eax
     440:	8b 00                	mov    (%eax),%eax
     442:	3b 45 f0             	cmp    -0x10(%ebp),%eax
     445:	74 2c                	je     473 <writetest1+0x1b3>
      printf(stdout, "read content of block %d is %d\n",
             n, ((int*)buf)[0]);
     447:	b8 00 87 00 00       	mov    $0x8700,%eax
    } else if(i != 512){
      printf(stdout, "read failed %d\n", i);
      exit();
    }
    if(((int*)buf)[0] != n){
      printf(stdout, "read content of block %d is %d\n",
     44c:	8b 10                	mov    (%eax),%edx
     44e:	a1 14 5f 00 00       	mov    0x5f14,%eax
     453:	89 54 24 0c          	mov    %edx,0xc(%esp)
     457:	8b 55 f0             	mov    -0x10(%ebp),%edx
     45a:	89 54 24 08          	mov    %edx,0x8(%esp)
     45e:	c7 44 24 04 f4 43 00 	movl   $0x43f4,0x4(%esp)
     465:	00 
     466:	89 04 24             	mov    %eax,(%esp)
     469:	e8 89 39 00 00       	call   3df7 <printf>
             n, ((int*)buf)[0]);
      exit();
     46e:	e8 c5 37 00 00       	call   3c38 <exit>
    }
    n++;
     473:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  }
     477:	e9 43 ff ff ff       	jmp    3bf <writetest1+0xff>
    if(i == 0){
      if(n == MAXFILE - 1){
        printf(stdout, "read only %d blocks from big", n);
        exit();
      }
      break;
     47c:	90                   	nop
             n, ((int*)buf)[0]);
      exit();
    }
    n++;
  }
  close(fd);
     47d:	8b 45 ec             	mov    -0x14(%ebp),%eax
     480:	89 04 24             	mov    %eax,(%esp)
     483:	e8 d8 37 00 00       	call   3c60 <close>
  if(unlink("big") < 0){
     488:	c7 04 24 70 43 00 00 	movl   $0x4370,(%esp)
     48f:	e8 f4 37 00 00       	call   3c88 <unlink>
     494:	85 c0                	test   %eax,%eax
     496:	79 1a                	jns    4b2 <writetest1+0x1f2>
    printf(stdout, "unlink big failed\n");
     498:	a1 14 5f 00 00       	mov    0x5f14,%eax
     49d:	c7 44 24 04 14 44 00 	movl   $0x4414,0x4(%esp)
     4a4:	00 
     4a5:	89 04 24             	mov    %eax,(%esp)
     4a8:	e8 4a 39 00 00       	call   3df7 <printf>
    exit();
     4ad:	e8 86 37 00 00       	call   3c38 <exit>
  }
  printf(stdout, "big files ok\n");
     4b2:	a1 14 5f 00 00       	mov    0x5f14,%eax
     4b7:	c7 44 24 04 27 44 00 	movl   $0x4427,0x4(%esp)
     4be:	00 
     4bf:	89 04 24             	mov    %eax,(%esp)
     4c2:	e8 30 39 00 00       	call   3df7 <printf>
}
     4c7:	c9                   	leave  
     4c8:	c3                   	ret    

000004c9 <createtest>:

void
createtest(void)
{
     4c9:	55                   	push   %ebp
     4ca:	89 e5                	mov    %esp,%ebp
     4cc:	83 ec 28             	sub    $0x28,%esp
  int i, fd;

  printf(stdout, "many creates, followed by unlink test\n");
     4cf:	a1 14 5f 00 00       	mov    0x5f14,%eax
     4d4:	c7 44 24 04 38 44 00 	movl   $0x4438,0x4(%esp)
     4db:	00 
     4dc:	89 04 24             	mov    %eax,(%esp)
     4df:	e8 13 39 00 00       	call   3df7 <printf>

  name[0] = 'a';
     4e4:	c6 05 00 a7 00 00 61 	movb   $0x61,0xa700
  name[2] = '\0';
     4eb:	c6 05 02 a7 00 00 00 	movb   $0x0,0xa702
  for(i = 0; i < 52; i++){
     4f2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
     4f9:	eb 31                	jmp    52c <createtest+0x63>
    name[1] = '0' + i;
     4fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
     4fe:	83 c0 30             	add    $0x30,%eax
     501:	a2 01 a7 00 00       	mov    %al,0xa701
    fd = open(name, O_CREATE|O_RDWR);
     506:	c7 44 24 04 02 02 00 	movl   $0x202,0x4(%esp)
     50d:	00 
     50e:	c7 04 24 00 a7 00 00 	movl   $0xa700,(%esp)
     515:	e8 5e 37 00 00       	call   3c78 <open>
     51a:	89 45 f0             	mov    %eax,-0x10(%ebp)
    close(fd);
     51d:	8b 45 f0             	mov    -0x10(%ebp),%eax
     520:	89 04 24             	mov    %eax,(%esp)
     523:	e8 38 37 00 00       	call   3c60 <close>

  printf(stdout, "many creates, followed by unlink test\n");

  name[0] = 'a';
  name[2] = '\0';
  for(i = 0; i < 52; i++){
     528:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
     52c:	83 7d f4 33          	cmpl   $0x33,-0xc(%ebp)
     530:	7e c9                	jle    4fb <createtest+0x32>
    name[1] = '0' + i;
    fd = open(name, O_CREATE|O_RDWR);
    close(fd);
  }
  name[0] = 'a';
     532:	c6 05 00 a7 00 00 61 	movb   $0x61,0xa700
  name[2] = '\0';
     539:	c6 05 02 a7 00 00 00 	movb   $0x0,0xa702
  for(i = 0; i < 52; i++){
     540:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
     547:	eb 1b                	jmp    564 <createtest+0x9b>
    name[1] = '0' + i;
     549:	8b 45 f4             	mov    -0xc(%ebp),%eax
     54c:	83 c0 30             	add    $0x30,%eax
     54f:	a2 01 a7 00 00       	mov    %al,0xa701
    unlink(name);
     554:	c7 04 24 00 a7 00 00 	movl   $0xa700,(%esp)
     55b:	e8 28 37 00 00       	call   3c88 <unlink>
    fd = open(name, O_CREATE|O_RDWR);
    close(fd);
  }
  name[0] = 'a';
  name[2] = '\0';
  for(i = 0; i < 52; i++){
     560:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
     564:	83 7d f4 33          	cmpl   $0x33,-0xc(%ebp)
     568:	7e df                	jle    549 <createtest+0x80>
    name[1] = '0' + i;
    unlink(name);
  }
  printf(stdout, "many creates, followed by unlink; ok\n");
     56a:	a1 14 5f 00 00       	mov    0x5f14,%eax
     56f:	c7 44 24 04 60 44 00 	movl   $0x4460,0x4(%esp)
     576:	00 
     577:	89 04 24             	mov    %eax,(%esp)
     57a:	e8 78 38 00 00       	call   3df7 <printf>
}
     57f:	c9                   	leave  
     580:	c3                   	ret    

00000581 <dirtest>:

void dirtest(void)
{
     581:	55                   	push   %ebp
     582:	89 e5                	mov    %esp,%ebp
     584:	83 ec 18             	sub    $0x18,%esp
  printf(stdout, "mkdir test\n");
     587:	a1 14 5f 00 00       	mov    0x5f14,%eax
     58c:	c7 44 24 04 86 44 00 	movl   $0x4486,0x4(%esp)
     593:	00 
     594:	89 04 24             	mov    %eax,(%esp)
     597:	e8 5b 38 00 00       	call   3df7 <printf>

  if(mkdir("dir0") < 0){
     59c:	c7 04 24 92 44 00 00 	movl   $0x4492,(%esp)
     5a3:	e8 f8 36 00 00       	call   3ca0 <mkdir>
     5a8:	85 c0                	test   %eax,%eax
     5aa:	79 1a                	jns    5c6 <dirtest+0x45>
    printf(stdout, "mkdir failed\n");
     5ac:	a1 14 5f 00 00       	mov    0x5f14,%eax
     5b1:	c7 44 24 04 97 44 00 	movl   $0x4497,0x4(%esp)
     5b8:	00 
     5b9:	89 04 24             	mov    %eax,(%esp)
     5bc:	e8 36 38 00 00       	call   3df7 <printf>
    exit();
     5c1:	e8 72 36 00 00       	call   3c38 <exit>
  }

  if(chdir("dir0") < 0){
     5c6:	c7 04 24 92 44 00 00 	movl   $0x4492,(%esp)
     5cd:	e8 d6 36 00 00       	call   3ca8 <chdir>
     5d2:	85 c0                	test   %eax,%eax
     5d4:	79 1a                	jns    5f0 <dirtest+0x6f>
    printf(stdout, "chdir dir0 failed\n");
     5d6:	a1 14 5f 00 00       	mov    0x5f14,%eax
     5db:	c7 44 24 04 a5 44 00 	movl   $0x44a5,0x4(%esp)
     5e2:	00 
     5e3:	89 04 24             	mov    %eax,(%esp)
     5e6:	e8 0c 38 00 00       	call   3df7 <printf>
    exit();
     5eb:	e8 48 36 00 00       	call   3c38 <exit>
  }

  if(chdir("..") < 0){
     5f0:	c7 04 24 b8 44 00 00 	movl   $0x44b8,(%esp)
     5f7:	e8 ac 36 00 00       	call   3ca8 <chdir>
     5fc:	85 c0                	test   %eax,%eax
     5fe:	79 1a                	jns    61a <dirtest+0x99>
    printf(stdout, "chdir .. failed\n");
     600:	a1 14 5f 00 00       	mov    0x5f14,%eax
     605:	c7 44 24 04 bb 44 00 	movl   $0x44bb,0x4(%esp)
     60c:	00 
     60d:	89 04 24             	mov    %eax,(%esp)
     610:	e8 e2 37 00 00       	call   3df7 <printf>
    exit();
     615:	e8 1e 36 00 00       	call   3c38 <exit>
  }

  if(unlink("dir0") < 0){
     61a:	c7 04 24 92 44 00 00 	movl   $0x4492,(%esp)
     621:	e8 62 36 00 00       	call   3c88 <unlink>
     626:	85 c0                	test   %eax,%eax
     628:	79 1a                	jns    644 <dirtest+0xc3>
    printf(stdout, "unlink dir0 failed\n");
     62a:	a1 14 5f 00 00       	mov    0x5f14,%eax
     62f:	c7 44 24 04 cc 44 00 	movl   $0x44cc,0x4(%esp)
     636:	00 
     637:	89 04 24             	mov    %eax,(%esp)
     63a:	e8 b8 37 00 00       	call   3df7 <printf>
    exit();
     63f:	e8 f4 35 00 00       	call   3c38 <exit>
  }
  printf(stdout, "mkdir test\n");
     644:	a1 14 5f 00 00       	mov    0x5f14,%eax
     649:	c7 44 24 04 86 44 00 	movl   $0x4486,0x4(%esp)
     650:	00 
     651:	89 04 24             	mov    %eax,(%esp)
     654:	e8 9e 37 00 00       	call   3df7 <printf>
}
     659:	c9                   	leave  
     65a:	c3                   	ret    

0000065b <exectest>:

void
exectest(void)
{
     65b:	55                   	push   %ebp
     65c:	89 e5                	mov    %esp,%ebp
     65e:	83 ec 18             	sub    $0x18,%esp
  printf(stdout, "exec test\n");
     661:	a1 14 5f 00 00       	mov    0x5f14,%eax
     666:	c7 44 24 04 e0 44 00 	movl   $0x44e0,0x4(%esp)
     66d:	00 
     66e:	89 04 24             	mov    %eax,(%esp)
     671:	e8 81 37 00 00       	call   3df7 <printf>
  if(exec("echo", echoargv) < 0){
     676:	c7 44 24 04 00 5f 00 	movl   $0x5f00,0x4(%esp)
     67d:	00 
     67e:	c7 04 24 bc 41 00 00 	movl   $0x41bc,(%esp)
     685:	e8 e6 35 00 00       	call   3c70 <exec>
     68a:	85 c0                	test   %eax,%eax
     68c:	79 1a                	jns    6a8 <exectest+0x4d>
    printf(stdout, "exec echo failed\n");
     68e:	a1 14 5f 00 00       	mov    0x5f14,%eax
     693:	c7 44 24 04 eb 44 00 	movl   $0x44eb,0x4(%esp)
     69a:	00 
     69b:	89 04 24             	mov    %eax,(%esp)
     69e:	e8 54 37 00 00       	call   3df7 <printf>
    exit();
     6a3:	e8 90 35 00 00       	call   3c38 <exit>
  }
}
     6a8:	c9                   	leave  
     6a9:	c3                   	ret    

000006aa <pipe1>:

// simple fork and pipe read/write

void
pipe1(void)
{
     6aa:	55                   	push   %ebp
     6ab:	89 e5                	mov    %esp,%ebp
     6ad:	83 ec 38             	sub    $0x38,%esp
  int fds[2], pid;
  int seq, i, n, cc, total;

  if(pipe(fds) != 0){
     6b0:	8d 45 d8             	lea    -0x28(%ebp),%eax
     6b3:	89 04 24             	mov    %eax,(%esp)
     6b6:	e8 8d 35 00 00       	call   3c48 <pipe>
     6bb:	85 c0                	test   %eax,%eax
     6bd:	74 19                	je     6d8 <pipe1+0x2e>
    printf(1, "pipe() failed\n");
     6bf:	c7 44 24 04 fd 44 00 	movl   $0x44fd,0x4(%esp)
     6c6:	00 
     6c7:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
     6ce:	e8 24 37 00 00       	call   3df7 <printf>
    exit();
     6d3:	e8 60 35 00 00       	call   3c38 <exit>
  }
  pid = fork();
     6d8:	e8 53 35 00 00       	call   3c30 <fork>
     6dd:	89 45 e0             	mov    %eax,-0x20(%ebp)
  seq = 0;
     6e0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  if(pid == 0){
     6e7:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
     6eb:	0f 85 86 00 00 00    	jne    777 <pipe1+0xcd>
    close(fds[0]);
     6f1:	8b 45 d8             	mov    -0x28(%ebp),%eax
     6f4:	89 04 24             	mov    %eax,(%esp)
     6f7:	e8 64 35 00 00       	call   3c60 <close>
    for(n = 0; n < 5; n++){
     6fc:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
     703:	eb 67                	jmp    76c <pipe1+0xc2>
      for(i = 0; i < 1033; i++)
     705:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
     70c:	eb 16                	jmp    724 <pipe1+0x7a>
        buf[i] = seq++;
     70e:	8b 45 f4             	mov    -0xc(%ebp),%eax
     711:	8b 55 f0             	mov    -0x10(%ebp),%edx
     714:	81 c2 00 87 00 00    	add    $0x8700,%edx
     71a:	88 02                	mov    %al,(%edx)
     71c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  pid = fork();
  seq = 0;
  if(pid == 0){
    close(fds[0]);
    for(n = 0; n < 5; n++){
      for(i = 0; i < 1033; i++)
     720:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
     724:	81 7d f0 08 04 00 00 	cmpl   $0x408,-0x10(%ebp)
     72b:	7e e1                	jle    70e <pipe1+0x64>
        buf[i] = seq++;
      if(write(fds[1], buf, 1033) != 1033){
     72d:	8b 45 dc             	mov    -0x24(%ebp),%eax
     730:	c7 44 24 08 09 04 00 	movl   $0x409,0x8(%esp)
     737:	00 
     738:	c7 44 24 04 00 87 00 	movl   $0x8700,0x4(%esp)
     73f:	00 
     740:	89 04 24             	mov    %eax,(%esp)
     743:	e8 10 35 00 00       	call   3c58 <write>
     748:	3d 09 04 00 00       	cmp    $0x409,%eax
     74d:	74 19                	je     768 <pipe1+0xbe>
        printf(1, "pipe1 oops 1\n");
     74f:	c7 44 24 04 0c 45 00 	movl   $0x450c,0x4(%esp)
     756:	00 
     757:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
     75e:	e8 94 36 00 00       	call   3df7 <printf>
        exit();
     763:	e8 d0 34 00 00       	call   3c38 <exit>
  }
  pid = fork();
  seq = 0;
  if(pid == 0){
    close(fds[0]);
    for(n = 0; n < 5; n++){
     768:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
     76c:	83 7d ec 04          	cmpl   $0x4,-0x14(%ebp)
     770:	7e 93                	jle    705 <pipe1+0x5b>
      if(write(fds[1], buf, 1033) != 1033){
        printf(1, "pipe1 oops 1\n");
        exit();
      }
    }
    exit();
     772:	e8 c1 34 00 00       	call   3c38 <exit>
  } else if(pid > 0){
     777:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
     77b:	0f 8e fc 00 00 00    	jle    87d <pipe1+0x1d3>
    close(fds[1]);
     781:	8b 45 dc             	mov    -0x24(%ebp),%eax
     784:	89 04 24             	mov    %eax,(%esp)
     787:	e8 d4 34 00 00       	call   3c60 <close>
    total = 0;
     78c:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
    cc = 1;
     793:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
    while((n = read(fds[0], buf, cc)) > 0){
     79a:	eb 6b                	jmp    807 <pipe1+0x15d>
      for(i = 0; i < n; i++){
     79c:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
     7a3:	eb 40                	jmp    7e5 <pipe1+0x13b>
        if((buf[i] & 0xff) != (seq++ & 0xff)){
     7a5:	8b 45 f0             	mov    -0x10(%ebp),%eax
     7a8:	05 00 87 00 00       	add    $0x8700,%eax
     7ad:	0f b6 00             	movzbl (%eax),%eax
     7b0:	0f be c0             	movsbl %al,%eax
     7b3:	33 45 f4             	xor    -0xc(%ebp),%eax
     7b6:	25 ff 00 00 00       	and    $0xff,%eax
     7bb:	85 c0                	test   %eax,%eax
     7bd:	0f 95 c0             	setne  %al
     7c0:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
     7c4:	84 c0                	test   %al,%al
     7c6:	74 19                	je     7e1 <pipe1+0x137>
          printf(1, "pipe1 oops 2\n");
     7c8:	c7 44 24 04 1a 45 00 	movl   $0x451a,0x4(%esp)
     7cf:	00 
     7d0:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
     7d7:	e8 1b 36 00 00       	call   3df7 <printf>
          return;
     7dc:	e9 b5 00 00 00       	jmp    896 <pipe1+0x1ec>
  } else if(pid > 0){
    close(fds[1]);
    total = 0;
    cc = 1;
    while((n = read(fds[0], buf, cc)) > 0){
      for(i = 0; i < n; i++){
     7e1:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
     7e5:	8b 45 f0             	mov    -0x10(%ebp),%eax
     7e8:	3b 45 ec             	cmp    -0x14(%ebp),%eax
     7eb:	7c b8                	jl     7a5 <pipe1+0xfb>
        if((buf[i] & 0xff) != (seq++ & 0xff)){
          printf(1, "pipe1 oops 2\n");
          return;
        }
      }
      total += n;
     7ed:	8b 45 ec             	mov    -0x14(%ebp),%eax
     7f0:	01 45 e4             	add    %eax,-0x1c(%ebp)
      cc = cc * 2;
     7f3:	d1 65 e8             	shll   -0x18(%ebp)
      if(cc > sizeof(buf))
     7f6:	8b 45 e8             	mov    -0x18(%ebp),%eax
     7f9:	3d 00 20 00 00       	cmp    $0x2000,%eax
     7fe:	76 07                	jbe    807 <pipe1+0x15d>
        cc = sizeof(buf);
     800:	c7 45 e8 00 20 00 00 	movl   $0x2000,-0x18(%ebp)
    exit();
  } else if(pid > 0){
    close(fds[1]);
    total = 0;
    cc = 1;
    while((n = read(fds[0], buf, cc)) > 0){
     807:	8b 45 d8             	mov    -0x28(%ebp),%eax
     80a:	8b 55 e8             	mov    -0x18(%ebp),%edx
     80d:	89 54 24 08          	mov    %edx,0x8(%esp)
     811:	c7 44 24 04 00 87 00 	movl   $0x8700,0x4(%esp)
     818:	00 
     819:	89 04 24             	mov    %eax,(%esp)
     81c:	e8 2f 34 00 00       	call   3c50 <read>
     821:	89 45 ec             	mov    %eax,-0x14(%ebp)
     824:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
     828:	0f 8f 6e ff ff ff    	jg     79c <pipe1+0xf2>
      total += n;
      cc = cc * 2;
      if(cc > sizeof(buf))
        cc = sizeof(buf);
    }
    if(total != 5 * 1033){
     82e:	81 7d e4 2d 14 00 00 	cmpl   $0x142d,-0x1c(%ebp)
     835:	74 20                	je     857 <pipe1+0x1ad>
      printf(1, "pipe1 oops 3 total %d\n", total);
     837:	8b 45 e4             	mov    -0x1c(%ebp),%eax
     83a:	89 44 24 08          	mov    %eax,0x8(%esp)
     83e:	c7 44 24 04 28 45 00 	movl   $0x4528,0x4(%esp)
     845:	00 
     846:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
     84d:	e8 a5 35 00 00       	call   3df7 <printf>
      exit();
     852:	e8 e1 33 00 00       	call   3c38 <exit>
    }
    close(fds[0]);
     857:	8b 45 d8             	mov    -0x28(%ebp),%eax
     85a:	89 04 24             	mov    %eax,(%esp)
     85d:	e8 fe 33 00 00       	call   3c60 <close>
    wait();
     862:	e8 d9 33 00 00       	call   3c40 <wait>
  } else {
    printf(1, "fork() failed\n");
    exit();
  }
  printf(1, "pipe1 ok\n");
     867:	c7 44 24 04 3f 45 00 	movl   $0x453f,0x4(%esp)
     86e:	00 
     86f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
     876:	e8 7c 35 00 00       	call   3df7 <printf>
     87b:	eb 19                	jmp    896 <pipe1+0x1ec>
      exit();
    }
    close(fds[0]);
    wait();
  } else {
    printf(1, "fork() failed\n");
     87d:	c7 44 24 04 49 45 00 	movl   $0x4549,0x4(%esp)
     884:	00 
     885:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
     88c:	e8 66 35 00 00       	call   3df7 <printf>
    exit();
     891:	e8 a2 33 00 00       	call   3c38 <exit>
  }
  printf(1, "pipe1 ok\n");
}
     896:	c9                   	leave  
     897:	c3                   	ret    

00000898 <preempt>:

// meant to be run w/ at most two CPUs
void
preempt(void)
{
     898:	55                   	push   %ebp
     899:	89 e5                	mov    %esp,%ebp
     89b:	83 ec 38             	sub    $0x38,%esp
  int pid1, pid2, pid3;
  int pfds[2];

  printf(1, "preempt: ");
     89e:	c7 44 24 04 58 45 00 	movl   $0x4558,0x4(%esp)
     8a5:	00 
     8a6:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
     8ad:	e8 45 35 00 00       	call   3df7 <printf>
  pid1 = fork();
     8b2:	e8 79 33 00 00       	call   3c30 <fork>
     8b7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pid1 == 0)
     8ba:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
     8be:	75 02                	jne    8c2 <preempt+0x2a>
    for(;;)
      ;
     8c0:	eb fe                	jmp    8c0 <preempt+0x28>

  pid2 = fork();
     8c2:	e8 69 33 00 00       	call   3c30 <fork>
     8c7:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(pid2 == 0)
     8ca:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
     8ce:	75 02                	jne    8d2 <preempt+0x3a>
    for(;;)
      ;
     8d0:	eb fe                	jmp    8d0 <preempt+0x38>

  pipe(pfds);
     8d2:	8d 45 e4             	lea    -0x1c(%ebp),%eax
     8d5:	89 04 24             	mov    %eax,(%esp)
     8d8:	e8 6b 33 00 00       	call   3c48 <pipe>
  pid3 = fork();
     8dd:	e8 4e 33 00 00       	call   3c30 <fork>
     8e2:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(pid3 == 0){
     8e5:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
     8e9:	75 4c                	jne    937 <preempt+0x9f>
    close(pfds[0]);
     8eb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
     8ee:	89 04 24             	mov    %eax,(%esp)
     8f1:	e8 6a 33 00 00       	call   3c60 <close>
    if(write(pfds[1], "x", 1) != 1)
     8f6:	8b 45 e8             	mov    -0x18(%ebp),%eax
     8f9:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
     900:	00 
     901:	c7 44 24 04 62 45 00 	movl   $0x4562,0x4(%esp)
     908:	00 
     909:	89 04 24             	mov    %eax,(%esp)
     90c:	e8 47 33 00 00       	call   3c58 <write>
     911:	83 f8 01             	cmp    $0x1,%eax
     914:	74 14                	je     92a <preempt+0x92>
      printf(1, "preempt write error");
     916:	c7 44 24 04 64 45 00 	movl   $0x4564,0x4(%esp)
     91d:	00 
     91e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
     925:	e8 cd 34 00 00       	call   3df7 <printf>
    close(pfds[1]);
     92a:	8b 45 e8             	mov    -0x18(%ebp),%eax
     92d:	89 04 24             	mov    %eax,(%esp)
     930:	e8 2b 33 00 00       	call   3c60 <close>
    for(;;)
      ;
     935:	eb fe                	jmp    935 <preempt+0x9d>
  }

  close(pfds[1]);
     937:	8b 45 e8             	mov    -0x18(%ebp),%eax
     93a:	89 04 24             	mov    %eax,(%esp)
     93d:	e8 1e 33 00 00       	call   3c60 <close>
  if(read(pfds[0], buf, sizeof(buf)) != 1){
     942:	8b 45 e4             	mov    -0x1c(%ebp),%eax
     945:	c7 44 24 08 00 20 00 	movl   $0x2000,0x8(%esp)
     94c:	00 
     94d:	c7 44 24 04 00 87 00 	movl   $0x8700,0x4(%esp)
     954:	00 
     955:	89 04 24             	mov    %eax,(%esp)
     958:	e8 f3 32 00 00       	call   3c50 <read>
     95d:	83 f8 01             	cmp    $0x1,%eax
     960:	74 16                	je     978 <preempt+0xe0>
    printf(1, "preempt read error");
     962:	c7 44 24 04 78 45 00 	movl   $0x4578,0x4(%esp)
     969:	00 
     96a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
     971:	e8 81 34 00 00       	call   3df7 <printf>
    return;
     976:	eb 77                	jmp    9ef <preempt+0x157>
  }
  close(pfds[0]);
     978:	8b 45 e4             	mov    -0x1c(%ebp),%eax
     97b:	89 04 24             	mov    %eax,(%esp)
     97e:	e8 dd 32 00 00       	call   3c60 <close>
  printf(1, "kill... ");
     983:	c7 44 24 04 8b 45 00 	movl   $0x458b,0x4(%esp)
     98a:	00 
     98b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
     992:	e8 60 34 00 00       	call   3df7 <printf>
  kill(pid1);
     997:	8b 45 f4             	mov    -0xc(%ebp),%eax
     99a:	89 04 24             	mov    %eax,(%esp)
     99d:	e8 c6 32 00 00       	call   3c68 <kill>
  kill(pid2);
     9a2:	8b 45 f0             	mov    -0x10(%ebp),%eax
     9a5:	89 04 24             	mov    %eax,(%esp)
     9a8:	e8 bb 32 00 00       	call   3c68 <kill>
  kill(pid3);
     9ad:	8b 45 ec             	mov    -0x14(%ebp),%eax
     9b0:	89 04 24             	mov    %eax,(%esp)
     9b3:	e8 b0 32 00 00       	call   3c68 <kill>
  printf(1, "wait... ");
     9b8:	c7 44 24 04 94 45 00 	movl   $0x4594,0x4(%esp)
     9bf:	00 
     9c0:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
     9c7:	e8 2b 34 00 00       	call   3df7 <printf>
  wait();
     9cc:	e8 6f 32 00 00       	call   3c40 <wait>
  wait();
     9d1:	e8 6a 32 00 00       	call   3c40 <wait>
  wait();
     9d6:	e8 65 32 00 00       	call   3c40 <wait>
  printf(1, "preempt ok\n");
     9db:	c7 44 24 04 9d 45 00 	movl   $0x459d,0x4(%esp)
     9e2:	00 
     9e3:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
     9ea:	e8 08 34 00 00       	call   3df7 <printf>
}
     9ef:	c9                   	leave  
     9f0:	c3                   	ret    

000009f1 <exitwait>:

// try to find any races between exit and wait
void
exitwait(void)
{
     9f1:	55                   	push   %ebp
     9f2:	89 e5                	mov    %esp,%ebp
     9f4:	83 ec 28             	sub    $0x28,%esp
  int i, pid;

  for(i = 0; i < 100; i++){
     9f7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
     9fe:	eb 53                	jmp    a53 <exitwait+0x62>
    pid = fork();
     a00:	e8 2b 32 00 00       	call   3c30 <fork>
     a05:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(pid < 0){
     a08:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
     a0c:	79 16                	jns    a24 <exitwait+0x33>
      printf(1, "fork failed\n");
     a0e:	c7 44 24 04 a9 45 00 	movl   $0x45a9,0x4(%esp)
     a15:	00 
     a16:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
     a1d:	e8 d5 33 00 00       	call   3df7 <printf>
      return;
     a22:	eb 49                	jmp    a6d <exitwait+0x7c>
    }
    if(pid){
     a24:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
     a28:	74 20                	je     a4a <exitwait+0x59>
      if(wait() != pid){
     a2a:	e8 11 32 00 00       	call   3c40 <wait>
     a2f:	3b 45 f0             	cmp    -0x10(%ebp),%eax
     a32:	74 1b                	je     a4f <exitwait+0x5e>
        printf(1, "wait wrong pid\n");
     a34:	c7 44 24 04 b6 45 00 	movl   $0x45b6,0x4(%esp)
     a3b:	00 
     a3c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
     a43:	e8 af 33 00 00       	call   3df7 <printf>
        return;
     a48:	eb 23                	jmp    a6d <exitwait+0x7c>
      }
    } else {
      exit();
     a4a:	e8 e9 31 00 00       	call   3c38 <exit>
void
exitwait(void)
{
  int i, pid;

  for(i = 0; i < 100; i++){
     a4f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
     a53:	83 7d f4 63          	cmpl   $0x63,-0xc(%ebp)
     a57:	7e a7                	jle    a00 <exitwait+0xf>
      }
    } else {
      exit();
    }
  }
  printf(1, "exitwait ok\n");
     a59:	c7 44 24 04 c6 45 00 	movl   $0x45c6,0x4(%esp)
     a60:	00 
     a61:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
     a68:	e8 8a 33 00 00       	call   3df7 <printf>
}
     a6d:	c9                   	leave  
     a6e:	c3                   	ret    

00000a6f <mem>:

void
mem(void)
{
     a6f:	55                   	push   %ebp
     a70:	89 e5                	mov    %esp,%ebp
     a72:	83 ec 28             	sub    $0x28,%esp
  void *m1, *m2;
  int pid, ppid;

  printf(1, "mem test\n");
     a75:	c7 44 24 04 d3 45 00 	movl   $0x45d3,0x4(%esp)
     a7c:	00 
     a7d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
     a84:	e8 6e 33 00 00       	call   3df7 <printf>
  ppid = getpid();
     a89:	e8 2a 32 00 00       	call   3cb8 <getpid>
     a8e:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if((pid = fork()) == 0){
     a91:	e8 9a 31 00 00       	call   3c30 <fork>
     a96:	89 45 ec             	mov    %eax,-0x14(%ebp)
     a99:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
     a9d:	0f 85 aa 00 00 00    	jne    b4d <mem+0xde>
    m1 = 0;
     aa3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while((m2 = malloc(10001)) != 0){
     aaa:	eb 0e                	jmp    aba <mem+0x4b>
      *(char**)m2 = m1;
     aac:	8b 45 e8             	mov    -0x18(%ebp),%eax
     aaf:	8b 55 f4             	mov    -0xc(%ebp),%edx
     ab2:	89 10                	mov    %edx,(%eax)
      m1 = m2;
     ab4:	8b 45 e8             	mov    -0x18(%ebp),%eax
     ab7:	89 45 f4             	mov    %eax,-0xc(%ebp)

  printf(1, "mem test\n");
  ppid = getpid();
  if((pid = fork()) == 0){
    m1 = 0;
    while((m2 = malloc(10001)) != 0){
     aba:	c7 04 24 11 27 00 00 	movl   $0x2711,(%esp)
     ac1:	e8 15 36 00 00       	call   40db <malloc>
     ac6:	89 45 e8             	mov    %eax,-0x18(%ebp)
     ac9:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
     acd:	75 dd                	jne    aac <mem+0x3d>
      *(char**)m2 = m1;
      m1 = m2;
    }
    while(m1){
     acf:	eb 19                	jmp    aea <mem+0x7b>
      m2 = *(char**)m1;
     ad1:	8b 45 f4             	mov    -0xc(%ebp),%eax
     ad4:	8b 00                	mov    (%eax),%eax
     ad6:	89 45 e8             	mov    %eax,-0x18(%ebp)
      free(m1);
     ad9:	8b 45 f4             	mov    -0xc(%ebp),%eax
     adc:	89 04 24             	mov    %eax,(%esp)
     adf:	e8 c8 34 00 00       	call   3fac <free>
      m1 = m2;
     ae4:	8b 45 e8             	mov    -0x18(%ebp),%eax
     ae7:	89 45 f4             	mov    %eax,-0xc(%ebp)
    m1 = 0;
    while((m2 = malloc(10001)) != 0){
      *(char**)m2 = m1;
      m1 = m2;
    }
    while(m1){
     aea:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
     aee:	75 e1                	jne    ad1 <mem+0x62>
      m2 = *(char**)m1;
      free(m1);
      m1 = m2;
    }
    m1 = malloc(1024*20);
     af0:	c7 04 24 00 50 00 00 	movl   $0x5000,(%esp)
     af7:	e8 df 35 00 00       	call   40db <malloc>
     afc:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(m1 == 0){
     aff:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
     b03:	75 24                	jne    b29 <mem+0xba>
      printf(1, "couldn't allocate mem?!!\n");
     b05:	c7 44 24 04 dd 45 00 	movl   $0x45dd,0x4(%esp)
     b0c:	00 
     b0d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
     b14:	e8 de 32 00 00       	call   3df7 <printf>
      kill(ppid);
     b19:	8b 45 f0             	mov    -0x10(%ebp),%eax
     b1c:	89 04 24             	mov    %eax,(%esp)
     b1f:	e8 44 31 00 00       	call   3c68 <kill>
      exit();
     b24:	e8 0f 31 00 00       	call   3c38 <exit>
    }
    free(m1);
     b29:	8b 45 f4             	mov    -0xc(%ebp),%eax
     b2c:	89 04 24             	mov    %eax,(%esp)
     b2f:	e8 78 34 00 00       	call   3fac <free>
    printf(1, "mem ok\n");
     b34:	c7 44 24 04 f7 45 00 	movl   $0x45f7,0x4(%esp)
     b3b:	00 
     b3c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
     b43:	e8 af 32 00 00       	call   3df7 <printf>
    exit();
     b48:	e8 eb 30 00 00       	call   3c38 <exit>
  } else {
    wait();
     b4d:	e8 ee 30 00 00       	call   3c40 <wait>
  }
}
     b52:	c9                   	leave  
     b53:	c3                   	ret    

00000b54 <sharedfd>:

// two processes write to the same file descriptor
// is the offset shared? does inode locking work?
void
sharedfd(void)
{
     b54:	55                   	push   %ebp
     b55:	89 e5                	mov    %esp,%ebp
     b57:	83 ec 48             	sub    $0x48,%esp
  int fd, pid, i, n, nc, np;
  char buf[10];

  printf(1, "sharedfd test\n");
     b5a:	c7 44 24 04 ff 45 00 	movl   $0x45ff,0x4(%esp)
     b61:	00 
     b62:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
     b69:	e8 89 32 00 00       	call   3df7 <printf>

  unlink("sharedfd");
     b6e:	c7 04 24 0e 46 00 00 	movl   $0x460e,(%esp)
     b75:	e8 0e 31 00 00       	call   3c88 <unlink>
  fd = open("sharedfd", O_CREATE|O_RDWR);
     b7a:	c7 44 24 04 02 02 00 	movl   $0x202,0x4(%esp)
     b81:	00 
     b82:	c7 04 24 0e 46 00 00 	movl   $0x460e,(%esp)
     b89:	e8 ea 30 00 00       	call   3c78 <open>
     b8e:	89 45 e8             	mov    %eax,-0x18(%ebp)
  if(fd < 0){
     b91:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
     b95:	79 19                	jns    bb0 <sharedfd+0x5c>
    printf(1, "fstests: cannot open sharedfd for writing");
     b97:	c7 44 24 04 18 46 00 	movl   $0x4618,0x4(%esp)
     b9e:	00 
     b9f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
     ba6:	e8 4c 32 00 00       	call   3df7 <printf>
    return;
     bab:	e9 9c 01 00 00       	jmp    d4c <sharedfd+0x1f8>
  }
  pid = fork();
     bb0:	e8 7b 30 00 00       	call   3c30 <fork>
     bb5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  memset(buf, pid==0?'c':'p', sizeof(buf));
     bb8:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
     bbc:	75 07                	jne    bc5 <sharedfd+0x71>
     bbe:	b8 63 00 00 00       	mov    $0x63,%eax
     bc3:	eb 05                	jmp    bca <sharedfd+0x76>
     bc5:	b8 70 00 00 00       	mov    $0x70,%eax
     bca:	c7 44 24 08 0a 00 00 	movl   $0xa,0x8(%esp)
     bd1:	00 
     bd2:	89 44 24 04          	mov    %eax,0x4(%esp)
     bd6:	8d 45 d6             	lea    -0x2a(%ebp),%eax
     bd9:	89 04 24             	mov    %eax,(%esp)
     bdc:	e8 b2 2e 00 00       	call   3a93 <memset>
  for(i = 0; i < 1000; i++){
     be1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
     be8:	eb 39                	jmp    c23 <sharedfd+0xcf>
    if(write(fd, buf, sizeof(buf)) != sizeof(buf)){
     bea:	c7 44 24 08 0a 00 00 	movl   $0xa,0x8(%esp)
     bf1:	00 
     bf2:	8d 45 d6             	lea    -0x2a(%ebp),%eax
     bf5:	89 44 24 04          	mov    %eax,0x4(%esp)
     bf9:	8b 45 e8             	mov    -0x18(%ebp),%eax
     bfc:	89 04 24             	mov    %eax,(%esp)
     bff:	e8 54 30 00 00       	call   3c58 <write>
     c04:	83 f8 0a             	cmp    $0xa,%eax
     c07:	74 16                	je     c1f <sharedfd+0xcb>
      printf(1, "fstests: write sharedfd failed\n");
     c09:	c7 44 24 04 44 46 00 	movl   $0x4644,0x4(%esp)
     c10:	00 
     c11:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
     c18:	e8 da 31 00 00       	call   3df7 <printf>
      break;
     c1d:	eb 0d                	jmp    c2c <sharedfd+0xd8>
    printf(1, "fstests: cannot open sharedfd for writing");
    return;
  }
  pid = fork();
  memset(buf, pid==0?'c':'p', sizeof(buf));
  for(i = 0; i < 1000; i++){
     c1f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
     c23:	81 7d f4 e7 03 00 00 	cmpl   $0x3e7,-0xc(%ebp)
     c2a:	7e be                	jle    bea <sharedfd+0x96>
    if(write(fd, buf, sizeof(buf)) != sizeof(buf)){
      printf(1, "fstests: write sharedfd failed\n");
      break;
    }
  }
  if(pid == 0)
     c2c:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
     c30:	75 05                	jne    c37 <sharedfd+0xe3>
    exit();
     c32:	e8 01 30 00 00       	call   3c38 <exit>
  else
    wait();
     c37:	e8 04 30 00 00       	call   3c40 <wait>
  close(fd);
     c3c:	8b 45 e8             	mov    -0x18(%ebp),%eax
     c3f:	89 04 24             	mov    %eax,(%esp)
     c42:	e8 19 30 00 00       	call   3c60 <close>
  fd = open("sharedfd", 0);
     c47:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
     c4e:	00 
     c4f:	c7 04 24 0e 46 00 00 	movl   $0x460e,(%esp)
     c56:	e8 1d 30 00 00       	call   3c78 <open>
     c5b:	89 45 e8             	mov    %eax,-0x18(%ebp)
  if(fd < 0){
     c5e:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
     c62:	79 19                	jns    c7d <sharedfd+0x129>
    printf(1, "fstests: cannot open sharedfd for reading\n");
     c64:	c7 44 24 04 64 46 00 	movl   $0x4664,0x4(%esp)
     c6b:	00 
     c6c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
     c73:	e8 7f 31 00 00       	call   3df7 <printf>
    return;
     c78:	e9 cf 00 00 00       	jmp    d4c <sharedfd+0x1f8>
  }
  nc = np = 0;
     c7d:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
     c84:	8b 45 ec             	mov    -0x14(%ebp),%eax
     c87:	89 45 f0             	mov    %eax,-0x10(%ebp)
  while((n = read(fd, buf, sizeof(buf))) > 0){
     c8a:	eb 37                	jmp    cc3 <sharedfd+0x16f>
    for(i = 0; i < sizeof(buf); i++){
     c8c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
     c93:	eb 26                	jmp    cbb <sharedfd+0x167>
      if(buf[i] == 'c')
     c95:	8d 45 d6             	lea    -0x2a(%ebp),%eax
     c98:	03 45 f4             	add    -0xc(%ebp),%eax
     c9b:	0f b6 00             	movzbl (%eax),%eax
     c9e:	3c 63                	cmp    $0x63,%al
     ca0:	75 04                	jne    ca6 <sharedfd+0x152>
        nc++;
     ca2:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
      if(buf[i] == 'p')
     ca6:	8d 45 d6             	lea    -0x2a(%ebp),%eax
     ca9:	03 45 f4             	add    -0xc(%ebp),%eax
     cac:	0f b6 00             	movzbl (%eax),%eax
     caf:	3c 70                	cmp    $0x70,%al
     cb1:	75 04                	jne    cb7 <sharedfd+0x163>
        np++;
     cb3:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
    printf(1, "fstests: cannot open sharedfd for reading\n");
    return;
  }
  nc = np = 0;
  while((n = read(fd, buf, sizeof(buf))) > 0){
    for(i = 0; i < sizeof(buf); i++){
     cb7:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
     cbb:	8b 45 f4             	mov    -0xc(%ebp),%eax
     cbe:	83 f8 09             	cmp    $0x9,%eax
     cc1:	76 d2                	jbe    c95 <sharedfd+0x141>
  if(fd < 0){
    printf(1, "fstests: cannot open sharedfd for reading\n");
    return;
  }
  nc = np = 0;
  while((n = read(fd, buf, sizeof(buf))) > 0){
     cc3:	c7 44 24 08 0a 00 00 	movl   $0xa,0x8(%esp)
     cca:	00 
     ccb:	8d 45 d6             	lea    -0x2a(%ebp),%eax
     cce:	89 44 24 04          	mov    %eax,0x4(%esp)
     cd2:	8b 45 e8             	mov    -0x18(%ebp),%eax
     cd5:	89 04 24             	mov    %eax,(%esp)
     cd8:	e8 73 2f 00 00       	call   3c50 <read>
     cdd:	89 45 e0             	mov    %eax,-0x20(%ebp)
     ce0:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
     ce4:	7f a6                	jg     c8c <sharedfd+0x138>
        nc++;
      if(buf[i] == 'p')
        np++;
    }
  }
  close(fd);
     ce6:	8b 45 e8             	mov    -0x18(%ebp),%eax
     ce9:	89 04 24             	mov    %eax,(%esp)
     cec:	e8 6f 2f 00 00       	call   3c60 <close>
  unlink("sharedfd");
     cf1:	c7 04 24 0e 46 00 00 	movl   $0x460e,(%esp)
     cf8:	e8 8b 2f 00 00       	call   3c88 <unlink>
  if(nc == 10000 && np == 10000){
     cfd:	81 7d f0 10 27 00 00 	cmpl   $0x2710,-0x10(%ebp)
     d04:	75 1f                	jne    d25 <sharedfd+0x1d1>
     d06:	81 7d ec 10 27 00 00 	cmpl   $0x2710,-0x14(%ebp)
     d0d:	75 16                	jne    d25 <sharedfd+0x1d1>
    printf(1, "sharedfd ok\n");
     d0f:	c7 44 24 04 8f 46 00 	movl   $0x468f,0x4(%esp)
     d16:	00 
     d17:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
     d1e:	e8 d4 30 00 00       	call   3df7 <printf>
     d23:	eb 27                	jmp    d4c <sharedfd+0x1f8>
  } else {
    printf(1, "sharedfd oops %d %d\n", nc, np);
     d25:	8b 45 ec             	mov    -0x14(%ebp),%eax
     d28:	89 44 24 0c          	mov    %eax,0xc(%esp)
     d2c:	8b 45 f0             	mov    -0x10(%ebp),%eax
     d2f:	89 44 24 08          	mov    %eax,0x8(%esp)
     d33:	c7 44 24 04 9c 46 00 	movl   $0x469c,0x4(%esp)
     d3a:	00 
     d3b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
     d42:	e8 b0 30 00 00       	call   3df7 <printf>
    exit();
     d47:	e8 ec 2e 00 00       	call   3c38 <exit>
  }
}
     d4c:	c9                   	leave  
     d4d:	c3                   	ret    

00000d4e <twofiles>:

// two processes write two different files at the same
// time, to test block allocation.
void
twofiles(void)
{
     d4e:	55                   	push   %ebp
     d4f:	89 e5                	mov    %esp,%ebp
     d51:	83 ec 38             	sub    $0x38,%esp
  int fd, pid, i, j, n, total;
  char *fname;

  printf(1, "twofiles test\n");
     d54:	c7 44 24 04 b1 46 00 	movl   $0x46b1,0x4(%esp)
     d5b:	00 
     d5c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
     d63:	e8 8f 30 00 00       	call   3df7 <printf>

  unlink("f1");
     d68:	c7 04 24 c0 46 00 00 	movl   $0x46c0,(%esp)
     d6f:	e8 14 2f 00 00       	call   3c88 <unlink>
  unlink("f2");
     d74:	c7 04 24 c3 46 00 00 	movl   $0x46c3,(%esp)
     d7b:	e8 08 2f 00 00       	call   3c88 <unlink>

  pid = fork();
     d80:	e8 ab 2e 00 00       	call   3c30 <fork>
     d85:	89 45 e8             	mov    %eax,-0x18(%ebp)
  if(pid < 0){
     d88:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
     d8c:	79 19                	jns    da7 <twofiles+0x59>
    printf(1, "fork failed\n");
     d8e:	c7 44 24 04 a9 45 00 	movl   $0x45a9,0x4(%esp)
     d95:	00 
     d96:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
     d9d:	e8 55 30 00 00       	call   3df7 <printf>
    exit();
     da2:	e8 91 2e 00 00       	call   3c38 <exit>
  }

  fname = pid ? "f1" : "f2";
     da7:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
     dab:	74 07                	je     db4 <twofiles+0x66>
     dad:	b8 c0 46 00 00       	mov    $0x46c0,%eax
     db2:	eb 05                	jmp    db9 <twofiles+0x6b>
     db4:	b8 c3 46 00 00       	mov    $0x46c3,%eax
     db9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  fd = open(fname, O_CREATE | O_RDWR);
     dbc:	c7 44 24 04 02 02 00 	movl   $0x202,0x4(%esp)
     dc3:	00 
     dc4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
     dc7:	89 04 24             	mov    %eax,(%esp)
     dca:	e8 a9 2e 00 00       	call   3c78 <open>
     dcf:	89 45 e0             	mov    %eax,-0x20(%ebp)
  if(fd < 0){
     dd2:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
     dd6:	79 19                	jns    df1 <twofiles+0xa3>
    printf(1, "create failed\n");
     dd8:	c7 44 24 04 c6 46 00 	movl   $0x46c6,0x4(%esp)
     ddf:	00 
     de0:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
     de7:	e8 0b 30 00 00       	call   3df7 <printf>
    exit();
     dec:	e8 47 2e 00 00       	call   3c38 <exit>
  }

  memset(buf, pid?'p':'c', 512);
     df1:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
     df5:	74 07                	je     dfe <twofiles+0xb0>
     df7:	b8 70 00 00 00       	mov    $0x70,%eax
     dfc:	eb 05                	jmp    e03 <twofiles+0xb5>
     dfe:	b8 63 00 00 00       	mov    $0x63,%eax
     e03:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
     e0a:	00 
     e0b:	89 44 24 04          	mov    %eax,0x4(%esp)
     e0f:	c7 04 24 00 87 00 00 	movl   $0x8700,(%esp)
     e16:	e8 78 2c 00 00       	call   3a93 <memset>
  for(i = 0; i < 12; i++){
     e1b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
     e22:	eb 4b                	jmp    e6f <twofiles+0x121>
    if((n = write(fd, buf, 500)) != 500){
     e24:	c7 44 24 08 f4 01 00 	movl   $0x1f4,0x8(%esp)
     e2b:	00 
     e2c:	c7 44 24 04 00 87 00 	movl   $0x8700,0x4(%esp)
     e33:	00 
     e34:	8b 45 e0             	mov    -0x20(%ebp),%eax
     e37:	89 04 24             	mov    %eax,(%esp)
     e3a:	e8 19 2e 00 00       	call   3c58 <write>
     e3f:	89 45 dc             	mov    %eax,-0x24(%ebp)
     e42:	81 7d dc f4 01 00 00 	cmpl   $0x1f4,-0x24(%ebp)
     e49:	74 20                	je     e6b <twofiles+0x11d>
      printf(1, "write failed %d\n", n);
     e4b:	8b 45 dc             	mov    -0x24(%ebp),%eax
     e4e:	89 44 24 08          	mov    %eax,0x8(%esp)
     e52:	c7 44 24 04 d5 46 00 	movl   $0x46d5,0x4(%esp)
     e59:	00 
     e5a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
     e61:	e8 91 2f 00 00       	call   3df7 <printf>
      exit();
     e66:	e8 cd 2d 00 00       	call   3c38 <exit>
    printf(1, "create failed\n");
    exit();
  }

  memset(buf, pid?'p':'c', 512);
  for(i = 0; i < 12; i++){
     e6b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
     e6f:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
     e73:	7e af                	jle    e24 <twofiles+0xd6>
    if((n = write(fd, buf, 500)) != 500){
      printf(1, "write failed %d\n", n);
      exit();
    }
  }
  close(fd);
     e75:	8b 45 e0             	mov    -0x20(%ebp),%eax
     e78:	89 04 24             	mov    %eax,(%esp)
     e7b:	e8 e0 2d 00 00       	call   3c60 <close>
  if(pid)
     e80:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
     e84:	74 11                	je     e97 <twofiles+0x149>
    wait();
     e86:	e8 b5 2d 00 00       	call   3c40 <wait>
  else
    exit();

  for(i = 0; i < 2; i++){
     e8b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
     e92:	e9 e7 00 00 00       	jmp    f7e <twofiles+0x230>
  }
  close(fd);
  if(pid)
    wait();
  else
    exit();
     e97:	e8 9c 2d 00 00       	call   3c38 <exit>

  for(i = 0; i < 2; i++){
    fd = open(i?"f1":"f2", 0);
     e9c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
     ea0:	74 07                	je     ea9 <twofiles+0x15b>
     ea2:	b8 c0 46 00 00       	mov    $0x46c0,%eax
     ea7:	eb 05                	jmp    eae <twofiles+0x160>
     ea9:	b8 c3 46 00 00       	mov    $0x46c3,%eax
     eae:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
     eb5:	00 
     eb6:	89 04 24             	mov    %eax,(%esp)
     eb9:	e8 ba 2d 00 00       	call   3c78 <open>
     ebe:	89 45 e0             	mov    %eax,-0x20(%ebp)
    total = 0;
     ec1:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
    while((n = read(fd, buf, sizeof(buf))) > 0){
     ec8:	eb 58                	jmp    f22 <twofiles+0x1d4>
      for(j = 0; j < n; j++){
     eca:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
     ed1:	eb 41                	jmp    f14 <twofiles+0x1c6>
        if(buf[j] != (i?'p':'c')){
     ed3:	8b 45 f0             	mov    -0x10(%ebp),%eax
     ed6:	05 00 87 00 00       	add    $0x8700,%eax
     edb:	0f b6 00             	movzbl (%eax),%eax
     ede:	0f be d0             	movsbl %al,%edx
     ee1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
     ee5:	74 07                	je     eee <twofiles+0x1a0>
     ee7:	b8 70 00 00 00       	mov    $0x70,%eax
     eec:	eb 05                	jmp    ef3 <twofiles+0x1a5>
     eee:	b8 63 00 00 00       	mov    $0x63,%eax
     ef3:	39 c2                	cmp    %eax,%edx
     ef5:	74 19                	je     f10 <twofiles+0x1c2>
          printf(1, "wrong char\n");
     ef7:	c7 44 24 04 e6 46 00 	movl   $0x46e6,0x4(%esp)
     efe:	00 
     eff:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
     f06:	e8 ec 2e 00 00       	call   3df7 <printf>
          exit();
     f0b:	e8 28 2d 00 00       	call   3c38 <exit>

  for(i = 0; i < 2; i++){
    fd = open(i?"f1":"f2", 0);
    total = 0;
    while((n = read(fd, buf, sizeof(buf))) > 0){
      for(j = 0; j < n; j++){
     f10:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
     f14:	8b 45 f0             	mov    -0x10(%ebp),%eax
     f17:	3b 45 dc             	cmp    -0x24(%ebp),%eax
     f1a:	7c b7                	jl     ed3 <twofiles+0x185>
        if(buf[j] != (i?'p':'c')){
          printf(1, "wrong char\n");
          exit();
        }
      }
      total += n;
     f1c:	8b 45 dc             	mov    -0x24(%ebp),%eax
     f1f:	01 45 ec             	add    %eax,-0x14(%ebp)
    exit();

  for(i = 0; i < 2; i++){
    fd = open(i?"f1":"f2", 0);
    total = 0;
    while((n = read(fd, buf, sizeof(buf))) > 0){
     f22:	c7 44 24 08 00 20 00 	movl   $0x2000,0x8(%esp)
     f29:	00 
     f2a:	c7 44 24 04 00 87 00 	movl   $0x8700,0x4(%esp)
     f31:	00 
     f32:	8b 45 e0             	mov    -0x20(%ebp),%eax
     f35:	89 04 24             	mov    %eax,(%esp)
     f38:	e8 13 2d 00 00       	call   3c50 <read>
     f3d:	89 45 dc             	mov    %eax,-0x24(%ebp)
     f40:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
     f44:	7f 84                	jg     eca <twofiles+0x17c>
          exit();
        }
      }
      total += n;
    }
    close(fd);
     f46:	8b 45 e0             	mov    -0x20(%ebp),%eax
     f49:	89 04 24             	mov    %eax,(%esp)
     f4c:	e8 0f 2d 00 00       	call   3c60 <close>
    if(total != 12*500){
     f51:	81 7d ec 70 17 00 00 	cmpl   $0x1770,-0x14(%ebp)
     f58:	74 20                	je     f7a <twofiles+0x22c>
      printf(1, "wrong length %d\n", total);
     f5a:	8b 45 ec             	mov    -0x14(%ebp),%eax
     f5d:	89 44 24 08          	mov    %eax,0x8(%esp)
     f61:	c7 44 24 04 f2 46 00 	movl   $0x46f2,0x4(%esp)
     f68:	00 
     f69:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
     f70:	e8 82 2e 00 00       	call   3df7 <printf>
      exit();
     f75:	e8 be 2c 00 00       	call   3c38 <exit>
  if(pid)
    wait();
  else
    exit();

  for(i = 0; i < 2; i++){
     f7a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
     f7e:	83 7d f4 01          	cmpl   $0x1,-0xc(%ebp)
     f82:	0f 8e 14 ff ff ff    	jle    e9c <twofiles+0x14e>
      printf(1, "wrong length %d\n", total);
      exit();
    }
  }

  unlink("f1");
     f88:	c7 04 24 c0 46 00 00 	movl   $0x46c0,(%esp)
     f8f:	e8 f4 2c 00 00       	call   3c88 <unlink>
  unlink("f2");
     f94:	c7 04 24 c3 46 00 00 	movl   $0x46c3,(%esp)
     f9b:	e8 e8 2c 00 00       	call   3c88 <unlink>

  printf(1, "twofiles ok\n");
     fa0:	c7 44 24 04 03 47 00 	movl   $0x4703,0x4(%esp)
     fa7:	00 
     fa8:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
     faf:	e8 43 2e 00 00       	call   3df7 <printf>
}
     fb4:	c9                   	leave  
     fb5:	c3                   	ret    

00000fb6 <createdelete>:

// two processes create and delete different files in same directory
void
createdelete(void)
{
     fb6:	55                   	push   %ebp
     fb7:	89 e5                	mov    %esp,%ebp
     fb9:	83 ec 48             	sub    $0x48,%esp
  enum { N = 20 };
  int pid, i, fd;
  char name[32];

  printf(1, "createdelete test\n");
     fbc:	c7 44 24 04 10 47 00 	movl   $0x4710,0x4(%esp)
     fc3:	00 
     fc4:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
     fcb:	e8 27 2e 00 00       	call   3df7 <printf>
  pid = fork();
     fd0:	e8 5b 2c 00 00       	call   3c30 <fork>
     fd5:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(pid < 0){
     fd8:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
     fdc:	79 19                	jns    ff7 <createdelete+0x41>
    printf(1, "fork failed\n");
     fde:	c7 44 24 04 a9 45 00 	movl   $0x45a9,0x4(%esp)
     fe5:	00 
     fe6:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
     fed:	e8 05 2e 00 00       	call   3df7 <printf>
    exit();
     ff2:	e8 41 2c 00 00       	call   3c38 <exit>
  }

  name[0] = pid ? 'p' : 'c';
     ff7:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
     ffb:	74 07                	je     1004 <createdelete+0x4e>
     ffd:	b8 70 00 00 00       	mov    $0x70,%eax
    1002:	eb 05                	jmp    1009 <createdelete+0x53>
    1004:	b8 63 00 00 00       	mov    $0x63,%eax
    1009:	88 45 cc             	mov    %al,-0x34(%ebp)
  name[2] = '\0';
    100c:	c6 45 ce 00          	movb   $0x0,-0x32(%ebp)
  for(i = 0; i < N; i++){
    1010:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    1017:	e9 97 00 00 00       	jmp    10b3 <createdelete+0xfd>
    name[1] = '0' + i;
    101c:	8b 45 f4             	mov    -0xc(%ebp),%eax
    101f:	83 c0 30             	add    $0x30,%eax
    1022:	88 45 cd             	mov    %al,-0x33(%ebp)
    fd = open(name, O_CREATE | O_RDWR);
    1025:	c7 44 24 04 02 02 00 	movl   $0x202,0x4(%esp)
    102c:	00 
    102d:	8d 45 cc             	lea    -0x34(%ebp),%eax
    1030:	89 04 24             	mov    %eax,(%esp)
    1033:	e8 40 2c 00 00       	call   3c78 <open>
    1038:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(fd < 0){
    103b:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
    103f:	79 19                	jns    105a <createdelete+0xa4>
      printf(1, "create failed\n");
    1041:	c7 44 24 04 c6 46 00 	movl   $0x46c6,0x4(%esp)
    1048:	00 
    1049:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    1050:	e8 a2 2d 00 00       	call   3df7 <printf>
      exit();
    1055:	e8 de 2b 00 00       	call   3c38 <exit>
    }
    close(fd);
    105a:	8b 45 ec             	mov    -0x14(%ebp),%eax
    105d:	89 04 24             	mov    %eax,(%esp)
    1060:	e8 fb 2b 00 00       	call   3c60 <close>
    if(i > 0 && (i % 2 ) == 0){
    1065:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
    1069:	7e 44                	jle    10af <createdelete+0xf9>
    106b:	8b 45 f4             	mov    -0xc(%ebp),%eax
    106e:	83 e0 01             	and    $0x1,%eax
    1071:	85 c0                	test   %eax,%eax
    1073:	75 3a                	jne    10af <createdelete+0xf9>
      name[1] = '0' + (i / 2);
    1075:	8b 45 f4             	mov    -0xc(%ebp),%eax
    1078:	89 c2                	mov    %eax,%edx
    107a:	c1 ea 1f             	shr    $0x1f,%edx
    107d:	01 d0                	add    %edx,%eax
    107f:	d1 f8                	sar    %eax
    1081:	83 c0 30             	add    $0x30,%eax
    1084:	88 45 cd             	mov    %al,-0x33(%ebp)
      if(unlink(name) < 0){
    1087:	8d 45 cc             	lea    -0x34(%ebp),%eax
    108a:	89 04 24             	mov    %eax,(%esp)
    108d:	e8 f6 2b 00 00       	call   3c88 <unlink>
    1092:	85 c0                	test   %eax,%eax
    1094:	79 19                	jns    10af <createdelete+0xf9>
        printf(1, "unlink failed\n");
    1096:	c7 44 24 04 23 47 00 	movl   $0x4723,0x4(%esp)
    109d:	00 
    109e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    10a5:	e8 4d 2d 00 00       	call   3df7 <printf>
        exit();
    10aa:	e8 89 2b 00 00       	call   3c38 <exit>
    exit();
  }

  name[0] = pid ? 'p' : 'c';
  name[2] = '\0';
  for(i = 0; i < N; i++){
    10af:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
    10b3:	83 7d f4 13          	cmpl   $0x13,-0xc(%ebp)
    10b7:	0f 8e 5f ff ff ff    	jle    101c <createdelete+0x66>
        exit();
      }
    }
  }

  if(pid==0)
    10bd:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
    10c1:	75 05                	jne    10c8 <createdelete+0x112>
    exit();
    10c3:	e8 70 2b 00 00       	call   3c38 <exit>
  else
    wait();
    10c8:	e8 73 2b 00 00       	call   3c40 <wait>

  for(i = 0; i < N; i++){
    10cd:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    10d4:	e9 34 01 00 00       	jmp    120d <createdelete+0x257>
    name[0] = 'p';
    10d9:	c6 45 cc 70          	movb   $0x70,-0x34(%ebp)
    name[1] = '0' + i;
    10dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
    10e0:	83 c0 30             	add    $0x30,%eax
    10e3:	88 45 cd             	mov    %al,-0x33(%ebp)
    fd = open(name, 0);
    10e6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
    10ed:	00 
    10ee:	8d 45 cc             	lea    -0x34(%ebp),%eax
    10f1:	89 04 24             	mov    %eax,(%esp)
    10f4:	e8 7f 2b 00 00       	call   3c78 <open>
    10f9:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if((i == 0 || i >= N/2) && fd < 0){
    10fc:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
    1100:	74 06                	je     1108 <createdelete+0x152>
    1102:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
    1106:	7e 26                	jle    112e <createdelete+0x178>
    1108:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
    110c:	79 20                	jns    112e <createdelete+0x178>
      printf(1, "oops createdelete %s didn't exist\n", name);
    110e:	8d 45 cc             	lea    -0x34(%ebp),%eax
    1111:	89 44 24 08          	mov    %eax,0x8(%esp)
    1115:	c7 44 24 04 34 47 00 	movl   $0x4734,0x4(%esp)
    111c:	00 
    111d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    1124:	e8 ce 2c 00 00       	call   3df7 <printf>
      exit();
    1129:	e8 0a 2b 00 00       	call   3c38 <exit>
    } else if((i >= 1 && i < N/2) && fd >= 0){
    112e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
    1132:	7e 2c                	jle    1160 <createdelete+0x1aa>
    1134:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
    1138:	7f 26                	jg     1160 <createdelete+0x1aa>
    113a:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
    113e:	78 20                	js     1160 <createdelete+0x1aa>
      printf(1, "oops createdelete %s did exist\n", name);
    1140:	8d 45 cc             	lea    -0x34(%ebp),%eax
    1143:	89 44 24 08          	mov    %eax,0x8(%esp)
    1147:	c7 44 24 04 58 47 00 	movl   $0x4758,0x4(%esp)
    114e:	00 
    114f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    1156:	e8 9c 2c 00 00       	call   3df7 <printf>
      exit();
    115b:	e8 d8 2a 00 00       	call   3c38 <exit>
    }
    if(fd >= 0)
    1160:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
    1164:	78 0b                	js     1171 <createdelete+0x1bb>
      close(fd);
    1166:	8b 45 ec             	mov    -0x14(%ebp),%eax
    1169:	89 04 24             	mov    %eax,(%esp)
    116c:	e8 ef 2a 00 00       	call   3c60 <close>

    name[0] = 'c';
    1171:	c6 45 cc 63          	movb   $0x63,-0x34(%ebp)
    name[1] = '0' + i;
    1175:	8b 45 f4             	mov    -0xc(%ebp),%eax
    1178:	83 c0 30             	add    $0x30,%eax
    117b:	88 45 cd             	mov    %al,-0x33(%ebp)
    fd = open(name, 0);
    117e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
    1185:	00 
    1186:	8d 45 cc             	lea    -0x34(%ebp),%eax
    1189:	89 04 24             	mov    %eax,(%esp)
    118c:	e8 e7 2a 00 00       	call   3c78 <open>
    1191:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if((i == 0 || i >= N/2) && fd < 0){
    1194:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
    1198:	74 06                	je     11a0 <createdelete+0x1ea>
    119a:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
    119e:	7e 26                	jle    11c6 <createdelete+0x210>
    11a0:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
    11a4:	79 20                	jns    11c6 <createdelete+0x210>
      printf(1, "oops createdelete %s didn't exist\n", name);
    11a6:	8d 45 cc             	lea    -0x34(%ebp),%eax
    11a9:	89 44 24 08          	mov    %eax,0x8(%esp)
    11ad:	c7 44 24 04 34 47 00 	movl   $0x4734,0x4(%esp)
    11b4:	00 
    11b5:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    11bc:	e8 36 2c 00 00       	call   3df7 <printf>
      exit();
    11c1:	e8 72 2a 00 00       	call   3c38 <exit>
    } else if((i >= 1 && i < N/2) && fd >= 0){
    11c6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
    11ca:	7e 2c                	jle    11f8 <createdelete+0x242>
    11cc:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
    11d0:	7f 26                	jg     11f8 <createdelete+0x242>
    11d2:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
    11d6:	78 20                	js     11f8 <createdelete+0x242>
      printf(1, "oops createdelete %s did exist\n", name);
    11d8:	8d 45 cc             	lea    -0x34(%ebp),%eax
    11db:	89 44 24 08          	mov    %eax,0x8(%esp)
    11df:	c7 44 24 04 58 47 00 	movl   $0x4758,0x4(%esp)
    11e6:	00 
    11e7:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    11ee:	e8 04 2c 00 00       	call   3df7 <printf>
      exit();
    11f3:	e8 40 2a 00 00       	call   3c38 <exit>
    }
    if(fd >= 0)
    11f8:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
    11fc:	78 0b                	js     1209 <createdelete+0x253>
      close(fd);
    11fe:	8b 45 ec             	mov    -0x14(%ebp),%eax
    1201:	89 04 24             	mov    %eax,(%esp)
    1204:	e8 57 2a 00 00       	call   3c60 <close>
  if(pid==0)
    exit();
  else
    wait();

  for(i = 0; i < N; i++){
    1209:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
    120d:	83 7d f4 13          	cmpl   $0x13,-0xc(%ebp)
    1211:	0f 8e c2 fe ff ff    	jle    10d9 <createdelete+0x123>
    }
    if(fd >= 0)
      close(fd);
  }

  for(i = 0; i < N; i++){
    1217:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    121e:	eb 2b                	jmp    124b <createdelete+0x295>
    name[0] = 'p';
    1220:	c6 45 cc 70          	movb   $0x70,-0x34(%ebp)
    name[1] = '0' + i;
    1224:	8b 45 f4             	mov    -0xc(%ebp),%eax
    1227:	83 c0 30             	add    $0x30,%eax
    122a:	88 45 cd             	mov    %al,-0x33(%ebp)
    unlink(name);
    122d:	8d 45 cc             	lea    -0x34(%ebp),%eax
    1230:	89 04 24             	mov    %eax,(%esp)
    1233:	e8 50 2a 00 00       	call   3c88 <unlink>
    name[0] = 'c';
    1238:	c6 45 cc 63          	movb   $0x63,-0x34(%ebp)
    unlink(name);
    123c:	8d 45 cc             	lea    -0x34(%ebp),%eax
    123f:	89 04 24             	mov    %eax,(%esp)
    1242:	e8 41 2a 00 00       	call   3c88 <unlink>
    }
    if(fd >= 0)
      close(fd);
  }

  for(i = 0; i < N; i++){
    1247:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
    124b:	83 7d f4 13          	cmpl   $0x13,-0xc(%ebp)
    124f:	7e cf                	jle    1220 <createdelete+0x26a>
    unlink(name);
    name[0] = 'c';
    unlink(name);
  }

  printf(1, "createdelete ok\n");
    1251:	c7 44 24 04 78 47 00 	movl   $0x4778,0x4(%esp)
    1258:	00 
    1259:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    1260:	e8 92 2b 00 00       	call   3df7 <printf>
}
    1265:	c9                   	leave  
    1266:	c3                   	ret    

00001267 <unlinkread>:

// can I unlink a file and still read it?
void
unlinkread(void)
{
    1267:	55                   	push   %ebp
    1268:	89 e5                	mov    %esp,%ebp
    126a:	83 ec 28             	sub    $0x28,%esp
  int fd, fd1;

  printf(1, "unlinkread test\n");
    126d:	c7 44 24 04 89 47 00 	movl   $0x4789,0x4(%esp)
    1274:	00 
    1275:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    127c:	e8 76 2b 00 00       	call   3df7 <printf>
  fd = open("unlinkread", O_CREATE | O_RDWR);
    1281:	c7 44 24 04 02 02 00 	movl   $0x202,0x4(%esp)
    1288:	00 
    1289:	c7 04 24 9a 47 00 00 	movl   $0x479a,(%esp)
    1290:	e8 e3 29 00 00       	call   3c78 <open>
    1295:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(fd < 0){
    1298:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
    129c:	79 19                	jns    12b7 <unlinkread+0x50>
    printf(1, "create unlinkread failed\n");
    129e:	c7 44 24 04 a5 47 00 	movl   $0x47a5,0x4(%esp)
    12a5:	00 
    12a6:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    12ad:	e8 45 2b 00 00       	call   3df7 <printf>
    exit();
    12b2:	e8 81 29 00 00       	call   3c38 <exit>
  }
  write(fd, "hello", 5);
    12b7:	c7 44 24 08 05 00 00 	movl   $0x5,0x8(%esp)
    12be:	00 
    12bf:	c7 44 24 04 bf 47 00 	movl   $0x47bf,0x4(%esp)
    12c6:	00 
    12c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
    12ca:	89 04 24             	mov    %eax,(%esp)
    12cd:	e8 86 29 00 00       	call   3c58 <write>
  close(fd);
    12d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
    12d5:	89 04 24             	mov    %eax,(%esp)
    12d8:	e8 83 29 00 00       	call   3c60 <close>

  fd = open("unlinkread", O_RDWR);
    12dd:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
    12e4:	00 
    12e5:	c7 04 24 9a 47 00 00 	movl   $0x479a,(%esp)
    12ec:	e8 87 29 00 00       	call   3c78 <open>
    12f1:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(fd < 0){
    12f4:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
    12f8:	79 19                	jns    1313 <unlinkread+0xac>
    printf(1, "open unlinkread failed\n");
    12fa:	c7 44 24 04 c5 47 00 	movl   $0x47c5,0x4(%esp)
    1301:	00 
    1302:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    1309:	e8 e9 2a 00 00       	call   3df7 <printf>
    exit();
    130e:	e8 25 29 00 00       	call   3c38 <exit>
  }
  if(unlink("unlinkread") != 0){
    1313:	c7 04 24 9a 47 00 00 	movl   $0x479a,(%esp)
    131a:	e8 69 29 00 00       	call   3c88 <unlink>
    131f:	85 c0                	test   %eax,%eax
    1321:	74 19                	je     133c <unlinkread+0xd5>
    printf(1, "unlink unlinkread failed\n");
    1323:	c7 44 24 04 dd 47 00 	movl   $0x47dd,0x4(%esp)
    132a:	00 
    132b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    1332:	e8 c0 2a 00 00       	call   3df7 <printf>
    exit();
    1337:	e8 fc 28 00 00       	call   3c38 <exit>
  }

  fd1 = open("unlinkread", O_CREATE | O_RDWR);
    133c:	c7 44 24 04 02 02 00 	movl   $0x202,0x4(%esp)
    1343:	00 
    1344:	c7 04 24 9a 47 00 00 	movl   $0x479a,(%esp)
    134b:	e8 28 29 00 00       	call   3c78 <open>
    1350:	89 45 f0             	mov    %eax,-0x10(%ebp)
  write(fd1, "yyy", 3);
    1353:	c7 44 24 08 03 00 00 	movl   $0x3,0x8(%esp)
    135a:	00 
    135b:	c7 44 24 04 f7 47 00 	movl   $0x47f7,0x4(%esp)
    1362:	00 
    1363:	8b 45 f0             	mov    -0x10(%ebp),%eax
    1366:	89 04 24             	mov    %eax,(%esp)
    1369:	e8 ea 28 00 00       	call   3c58 <write>
  close(fd1);
    136e:	8b 45 f0             	mov    -0x10(%ebp),%eax
    1371:	89 04 24             	mov    %eax,(%esp)
    1374:	e8 e7 28 00 00       	call   3c60 <close>

  if(read(fd, buf, sizeof(buf)) != 5){
    1379:	c7 44 24 08 00 20 00 	movl   $0x2000,0x8(%esp)
    1380:	00 
    1381:	c7 44 24 04 00 87 00 	movl   $0x8700,0x4(%esp)
    1388:	00 
    1389:	8b 45 f4             	mov    -0xc(%ebp),%eax
    138c:	89 04 24             	mov    %eax,(%esp)
    138f:	e8 bc 28 00 00       	call   3c50 <read>
    1394:	83 f8 05             	cmp    $0x5,%eax
    1397:	74 19                	je     13b2 <unlinkread+0x14b>
    printf(1, "unlinkread read failed");
    1399:	c7 44 24 04 fb 47 00 	movl   $0x47fb,0x4(%esp)
    13a0:	00 
    13a1:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    13a8:	e8 4a 2a 00 00       	call   3df7 <printf>
    exit();
    13ad:	e8 86 28 00 00       	call   3c38 <exit>
  }
  if(buf[0] != 'h'){
    13b2:	0f b6 05 00 87 00 00 	movzbl 0x8700,%eax
    13b9:	3c 68                	cmp    $0x68,%al
    13bb:	74 19                	je     13d6 <unlinkread+0x16f>
    printf(1, "unlinkread wrong data\n");
    13bd:	c7 44 24 04 12 48 00 	movl   $0x4812,0x4(%esp)
    13c4:	00 
    13c5:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    13cc:	e8 26 2a 00 00       	call   3df7 <printf>
    exit();
    13d1:	e8 62 28 00 00       	call   3c38 <exit>
  }
  if(write(fd, buf, 10) != 10){
    13d6:	c7 44 24 08 0a 00 00 	movl   $0xa,0x8(%esp)
    13dd:	00 
    13de:	c7 44 24 04 00 87 00 	movl   $0x8700,0x4(%esp)
    13e5:	00 
    13e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
    13e9:	89 04 24             	mov    %eax,(%esp)
    13ec:	e8 67 28 00 00       	call   3c58 <write>
    13f1:	83 f8 0a             	cmp    $0xa,%eax
    13f4:	74 19                	je     140f <unlinkread+0x1a8>
    printf(1, "unlinkread write failed\n");
    13f6:	c7 44 24 04 29 48 00 	movl   $0x4829,0x4(%esp)
    13fd:	00 
    13fe:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    1405:	e8 ed 29 00 00       	call   3df7 <printf>
    exit();
    140a:	e8 29 28 00 00       	call   3c38 <exit>
  }
  close(fd);
    140f:	8b 45 f4             	mov    -0xc(%ebp),%eax
    1412:	89 04 24             	mov    %eax,(%esp)
    1415:	e8 46 28 00 00       	call   3c60 <close>
  unlink("unlinkread");
    141a:	c7 04 24 9a 47 00 00 	movl   $0x479a,(%esp)
    1421:	e8 62 28 00 00       	call   3c88 <unlink>
  printf(1, "unlinkread ok\n");
    1426:	c7 44 24 04 42 48 00 	movl   $0x4842,0x4(%esp)
    142d:	00 
    142e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    1435:	e8 bd 29 00 00       	call   3df7 <printf>
}
    143a:	c9                   	leave  
    143b:	c3                   	ret    

0000143c <linktest>:

void
linktest(void)
{
    143c:	55                   	push   %ebp
    143d:	89 e5                	mov    %esp,%ebp
    143f:	83 ec 28             	sub    $0x28,%esp
  int fd;

  printf(1, "linktest\n");
    1442:	c7 44 24 04 51 48 00 	movl   $0x4851,0x4(%esp)
    1449:	00 
    144a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    1451:	e8 a1 29 00 00       	call   3df7 <printf>

  unlink("lf1");
    1456:	c7 04 24 5b 48 00 00 	movl   $0x485b,(%esp)
    145d:	e8 26 28 00 00       	call   3c88 <unlink>
  unlink("lf2");
    1462:	c7 04 24 5f 48 00 00 	movl   $0x485f,(%esp)
    1469:	e8 1a 28 00 00       	call   3c88 <unlink>

  fd = open("lf1", O_CREATE|O_RDWR);
    146e:	c7 44 24 04 02 02 00 	movl   $0x202,0x4(%esp)
    1475:	00 
    1476:	c7 04 24 5b 48 00 00 	movl   $0x485b,(%esp)
    147d:	e8 f6 27 00 00       	call   3c78 <open>
    1482:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(fd < 0){
    1485:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
    1489:	79 19                	jns    14a4 <linktest+0x68>
    printf(1, "create lf1 failed\n");
    148b:	c7 44 24 04 63 48 00 	movl   $0x4863,0x4(%esp)
    1492:	00 
    1493:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    149a:	e8 58 29 00 00       	call   3df7 <printf>
    exit();
    149f:	e8 94 27 00 00       	call   3c38 <exit>
  }
  if(write(fd, "hello", 5) != 5){
    14a4:	c7 44 24 08 05 00 00 	movl   $0x5,0x8(%esp)
    14ab:	00 
    14ac:	c7 44 24 04 bf 47 00 	movl   $0x47bf,0x4(%esp)
    14b3:	00 
    14b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
    14b7:	89 04 24             	mov    %eax,(%esp)
    14ba:	e8 99 27 00 00       	call   3c58 <write>
    14bf:	83 f8 05             	cmp    $0x5,%eax
    14c2:	74 19                	je     14dd <linktest+0xa1>
    printf(1, "write lf1 failed\n");
    14c4:	c7 44 24 04 76 48 00 	movl   $0x4876,0x4(%esp)
    14cb:	00 
    14cc:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    14d3:	e8 1f 29 00 00       	call   3df7 <printf>
    exit();
    14d8:	e8 5b 27 00 00       	call   3c38 <exit>
  }
  close(fd);
    14dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
    14e0:	89 04 24             	mov    %eax,(%esp)
    14e3:	e8 78 27 00 00       	call   3c60 <close>

  if(link("lf1", "lf2") < 0){
    14e8:	c7 44 24 04 5f 48 00 	movl   $0x485f,0x4(%esp)
    14ef:	00 
    14f0:	c7 04 24 5b 48 00 00 	movl   $0x485b,(%esp)
    14f7:	e8 9c 27 00 00       	call   3c98 <link>
    14fc:	85 c0                	test   %eax,%eax
    14fe:	79 19                	jns    1519 <linktest+0xdd>
    printf(1, "link lf1 lf2 failed\n");
    1500:	c7 44 24 04 88 48 00 	movl   $0x4888,0x4(%esp)
    1507:	00 
    1508:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    150f:	e8 e3 28 00 00       	call   3df7 <printf>
    exit();
    1514:	e8 1f 27 00 00       	call   3c38 <exit>
  }
  unlink("lf1");
    1519:	c7 04 24 5b 48 00 00 	movl   $0x485b,(%esp)
    1520:	e8 63 27 00 00       	call   3c88 <unlink>

  if(open("lf1", 0) >= 0){
    1525:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
    152c:	00 
    152d:	c7 04 24 5b 48 00 00 	movl   $0x485b,(%esp)
    1534:	e8 3f 27 00 00       	call   3c78 <open>
    1539:	85 c0                	test   %eax,%eax
    153b:	78 19                	js     1556 <linktest+0x11a>
    printf(1, "unlinked lf1 but it is still there!\n");
    153d:	c7 44 24 04 a0 48 00 	movl   $0x48a0,0x4(%esp)
    1544:	00 
    1545:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    154c:	e8 a6 28 00 00       	call   3df7 <printf>
    exit();
    1551:	e8 e2 26 00 00       	call   3c38 <exit>
  }

  fd = open("lf2", 0);
    1556:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
    155d:	00 
    155e:	c7 04 24 5f 48 00 00 	movl   $0x485f,(%esp)
    1565:	e8 0e 27 00 00       	call   3c78 <open>
    156a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(fd < 0){
    156d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
    1571:	79 19                	jns    158c <linktest+0x150>
    printf(1, "open lf2 failed\n");
    1573:	c7 44 24 04 c5 48 00 	movl   $0x48c5,0x4(%esp)
    157a:	00 
    157b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    1582:	e8 70 28 00 00       	call   3df7 <printf>
    exit();
    1587:	e8 ac 26 00 00       	call   3c38 <exit>
  }
  if(read(fd, buf, sizeof(buf)) != 5){
    158c:	c7 44 24 08 00 20 00 	movl   $0x2000,0x8(%esp)
    1593:	00 
    1594:	c7 44 24 04 00 87 00 	movl   $0x8700,0x4(%esp)
    159b:	00 
    159c:	8b 45 f4             	mov    -0xc(%ebp),%eax
    159f:	89 04 24             	mov    %eax,(%esp)
    15a2:	e8 a9 26 00 00       	call   3c50 <read>
    15a7:	83 f8 05             	cmp    $0x5,%eax
    15aa:	74 19                	je     15c5 <linktest+0x189>
    printf(1, "read lf2 failed\n");
    15ac:	c7 44 24 04 d6 48 00 	movl   $0x48d6,0x4(%esp)
    15b3:	00 
    15b4:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    15bb:	e8 37 28 00 00       	call   3df7 <printf>
    exit();
    15c0:	e8 73 26 00 00       	call   3c38 <exit>
  }
  close(fd);
    15c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
    15c8:	89 04 24             	mov    %eax,(%esp)
    15cb:	e8 90 26 00 00       	call   3c60 <close>

  if(link("lf2", "lf2") >= 0){
    15d0:	c7 44 24 04 5f 48 00 	movl   $0x485f,0x4(%esp)
    15d7:	00 
    15d8:	c7 04 24 5f 48 00 00 	movl   $0x485f,(%esp)
    15df:	e8 b4 26 00 00       	call   3c98 <link>
    15e4:	85 c0                	test   %eax,%eax
    15e6:	78 19                	js     1601 <linktest+0x1c5>
    printf(1, "link lf2 lf2 succeeded! oops\n");
    15e8:	c7 44 24 04 e7 48 00 	movl   $0x48e7,0x4(%esp)
    15ef:	00 
    15f0:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    15f7:	e8 fb 27 00 00       	call   3df7 <printf>
    exit();
    15fc:	e8 37 26 00 00       	call   3c38 <exit>
  }

  unlink("lf2");
    1601:	c7 04 24 5f 48 00 00 	movl   $0x485f,(%esp)
    1608:	e8 7b 26 00 00       	call   3c88 <unlink>
  if(link("lf2", "lf1") >= 0){
    160d:	c7 44 24 04 5b 48 00 	movl   $0x485b,0x4(%esp)
    1614:	00 
    1615:	c7 04 24 5f 48 00 00 	movl   $0x485f,(%esp)
    161c:	e8 77 26 00 00       	call   3c98 <link>
    1621:	85 c0                	test   %eax,%eax
    1623:	78 19                	js     163e <linktest+0x202>
    printf(1, "link non-existant succeeded! oops\n");
    1625:	c7 44 24 04 08 49 00 	movl   $0x4908,0x4(%esp)
    162c:	00 
    162d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    1634:	e8 be 27 00 00       	call   3df7 <printf>
    exit();
    1639:	e8 fa 25 00 00       	call   3c38 <exit>
  }

  if(link(".", "lf1") >= 0){
    163e:	c7 44 24 04 5b 48 00 	movl   $0x485b,0x4(%esp)
    1645:	00 
    1646:	c7 04 24 2b 49 00 00 	movl   $0x492b,(%esp)
    164d:	e8 46 26 00 00       	call   3c98 <link>
    1652:	85 c0                	test   %eax,%eax
    1654:	78 19                	js     166f <linktest+0x233>
    printf(1, "link . lf1 succeeded! oops\n");
    1656:	c7 44 24 04 2d 49 00 	movl   $0x492d,0x4(%esp)
    165d:	00 
    165e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    1665:	e8 8d 27 00 00       	call   3df7 <printf>
    exit();
    166a:	e8 c9 25 00 00       	call   3c38 <exit>
  }

  printf(1, "linktest ok\n");
    166f:	c7 44 24 04 49 49 00 	movl   $0x4949,0x4(%esp)
    1676:	00 
    1677:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    167e:	e8 74 27 00 00       	call   3df7 <printf>
}
    1683:	c9                   	leave  
    1684:	c3                   	ret    

00001685 <concreate>:

// test concurrent create/link/unlink of the same file
void
concreate(void)
{
    1685:	55                   	push   %ebp
    1686:	89 e5                	mov    %esp,%ebp
    1688:	83 ec 68             	sub    $0x68,%esp
  struct {
    ushort inum;
    char name[14];
  } de;

  printf(1, "concreate test\n");
    168b:	c7 44 24 04 56 49 00 	movl   $0x4956,0x4(%esp)
    1692:	00 
    1693:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    169a:	e8 58 27 00 00       	call   3df7 <printf>
  file[0] = 'C';
    169f:	c6 45 e5 43          	movb   $0x43,-0x1b(%ebp)
  file[2] = '\0';
    16a3:	c6 45 e7 00          	movb   $0x0,-0x19(%ebp)
  for(i = 0; i < 40; i++){
    16a7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    16ae:	e9 f7 00 00 00       	jmp    17aa <concreate+0x125>
    file[1] = '0' + i;
    16b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
    16b6:	83 c0 30             	add    $0x30,%eax
    16b9:	88 45 e6             	mov    %al,-0x1a(%ebp)
    unlink(file);
    16bc:	8d 45 e5             	lea    -0x1b(%ebp),%eax
    16bf:	89 04 24             	mov    %eax,(%esp)
    16c2:	e8 c1 25 00 00       	call   3c88 <unlink>
    pid = fork();
    16c7:	e8 64 25 00 00       	call   3c30 <fork>
    16cc:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(pid && (i % 3) == 1){
    16cf:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
    16d3:	74 3a                	je     170f <concreate+0x8a>
    16d5:	8b 4d f4             	mov    -0xc(%ebp),%ecx
    16d8:	ba 56 55 55 55       	mov    $0x55555556,%edx
    16dd:	89 c8                	mov    %ecx,%eax
    16df:	f7 ea                	imul   %edx
    16e1:	89 c8                	mov    %ecx,%eax
    16e3:	c1 f8 1f             	sar    $0x1f,%eax
    16e6:	29 c2                	sub    %eax,%edx
    16e8:	89 d0                	mov    %edx,%eax
    16ea:	01 c0                	add    %eax,%eax
    16ec:	01 d0                	add    %edx,%eax
    16ee:	89 ca                	mov    %ecx,%edx
    16f0:	29 c2                	sub    %eax,%edx
    16f2:	83 fa 01             	cmp    $0x1,%edx
    16f5:	75 18                	jne    170f <concreate+0x8a>
      link("C0", file);
    16f7:	8d 45 e5             	lea    -0x1b(%ebp),%eax
    16fa:	89 44 24 04          	mov    %eax,0x4(%esp)
    16fe:	c7 04 24 66 49 00 00 	movl   $0x4966,(%esp)
    1705:	e8 8e 25 00 00       	call   3c98 <link>
    170a:	e9 87 00 00 00       	jmp    1796 <concreate+0x111>
    } else if(pid == 0 && (i % 5) == 1){
    170f:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
    1713:	75 3a                	jne    174f <concreate+0xca>
    1715:	8b 4d f4             	mov    -0xc(%ebp),%ecx
    1718:	ba 67 66 66 66       	mov    $0x66666667,%edx
    171d:	89 c8                	mov    %ecx,%eax
    171f:	f7 ea                	imul   %edx
    1721:	d1 fa                	sar    %edx
    1723:	89 c8                	mov    %ecx,%eax
    1725:	c1 f8 1f             	sar    $0x1f,%eax
    1728:	29 c2                	sub    %eax,%edx
    172a:	89 d0                	mov    %edx,%eax
    172c:	c1 e0 02             	shl    $0x2,%eax
    172f:	01 d0                	add    %edx,%eax
    1731:	89 ca                	mov    %ecx,%edx
    1733:	29 c2                	sub    %eax,%edx
    1735:	83 fa 01             	cmp    $0x1,%edx
    1738:	75 15                	jne    174f <concreate+0xca>
      link("C0", file);
    173a:	8d 45 e5             	lea    -0x1b(%ebp),%eax
    173d:	89 44 24 04          	mov    %eax,0x4(%esp)
    1741:	c7 04 24 66 49 00 00 	movl   $0x4966,(%esp)
    1748:	e8 4b 25 00 00       	call   3c98 <link>
    174d:	eb 47                	jmp    1796 <concreate+0x111>
    } else {
      fd = open(file, O_CREATE | O_RDWR);
    174f:	c7 44 24 04 02 02 00 	movl   $0x202,0x4(%esp)
    1756:	00 
    1757:	8d 45 e5             	lea    -0x1b(%ebp),%eax
    175a:	89 04 24             	mov    %eax,(%esp)
    175d:	e8 16 25 00 00       	call   3c78 <open>
    1762:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(fd < 0){
    1765:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
    1769:	79 20                	jns    178b <concreate+0x106>
        printf(1, "concreate create %s failed\n", file);
    176b:	8d 45 e5             	lea    -0x1b(%ebp),%eax
    176e:	89 44 24 08          	mov    %eax,0x8(%esp)
    1772:	c7 44 24 04 69 49 00 	movl   $0x4969,0x4(%esp)
    1779:	00 
    177a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    1781:	e8 71 26 00 00       	call   3df7 <printf>
        exit();
    1786:	e8 ad 24 00 00       	call   3c38 <exit>
      }
      close(fd);
    178b:	8b 45 e8             	mov    -0x18(%ebp),%eax
    178e:	89 04 24             	mov    %eax,(%esp)
    1791:	e8 ca 24 00 00       	call   3c60 <close>
    }
    if(pid == 0)
    1796:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
    179a:	75 05                	jne    17a1 <concreate+0x11c>
      exit();
    179c:	e8 97 24 00 00       	call   3c38 <exit>
    else
      wait();
    17a1:	e8 9a 24 00 00       	call   3c40 <wait>
  } de;

  printf(1, "concreate test\n");
  file[0] = 'C';
  file[2] = '\0';
  for(i = 0; i < 40; i++){
    17a6:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
    17aa:	83 7d f4 27          	cmpl   $0x27,-0xc(%ebp)
    17ae:	0f 8e ff fe ff ff    	jle    16b3 <concreate+0x2e>
      exit();
    else
      wait();
  }

  memset(fa, 0, sizeof(fa));
    17b4:	c7 44 24 08 28 00 00 	movl   $0x28,0x8(%esp)
    17bb:	00 
    17bc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
    17c3:	00 
    17c4:	8d 45 bd             	lea    -0x43(%ebp),%eax
    17c7:	89 04 24             	mov    %eax,(%esp)
    17ca:	e8 c4 22 00 00       	call   3a93 <memset>
  fd = open(".", 0);
    17cf:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
    17d6:	00 
    17d7:	c7 04 24 2b 49 00 00 	movl   $0x492b,(%esp)
    17de:	e8 95 24 00 00       	call   3c78 <open>
    17e3:	89 45 e8             	mov    %eax,-0x18(%ebp)
  n = 0;
    17e6:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  while(read(fd, &de, sizeof(de)) > 0){
    17ed:	e9 9f 00 00 00       	jmp    1891 <concreate+0x20c>
    if(de.inum == 0)
    17f2:	0f b7 45 ac          	movzwl -0x54(%ebp),%eax
    17f6:	66 85 c0             	test   %ax,%ax
    17f9:	0f 84 91 00 00 00    	je     1890 <concreate+0x20b>
      continue;
    if(de.name[0] == 'C' && de.name[2] == '\0'){
    17ff:	0f b6 45 ae          	movzbl -0x52(%ebp),%eax
    1803:	3c 43                	cmp    $0x43,%al
    1805:	0f 85 86 00 00 00    	jne    1891 <concreate+0x20c>
    180b:	0f b6 45 b0          	movzbl -0x50(%ebp),%eax
    180f:	84 c0                	test   %al,%al
    1811:	75 7e                	jne    1891 <concreate+0x20c>
      i = de.name[1] - '0';
    1813:	0f b6 45 af          	movzbl -0x51(%ebp),%eax
    1817:	0f be c0             	movsbl %al,%eax
    181a:	83 e8 30             	sub    $0x30,%eax
    181d:	89 45 f4             	mov    %eax,-0xc(%ebp)
      if(i < 0 || i >= sizeof(fa)){
    1820:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
    1824:	78 08                	js     182e <concreate+0x1a9>
    1826:	8b 45 f4             	mov    -0xc(%ebp),%eax
    1829:	83 f8 27             	cmp    $0x27,%eax
    182c:	76 23                	jbe    1851 <concreate+0x1cc>
        printf(1, "concreate weird file %s\n", de.name);
    182e:	8d 45 ac             	lea    -0x54(%ebp),%eax
    1831:	83 c0 02             	add    $0x2,%eax
    1834:	89 44 24 08          	mov    %eax,0x8(%esp)
    1838:	c7 44 24 04 85 49 00 	movl   $0x4985,0x4(%esp)
    183f:	00 
    1840:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    1847:	e8 ab 25 00 00       	call   3df7 <printf>
        exit();
    184c:	e8 e7 23 00 00       	call   3c38 <exit>
      }
      if(fa[i]){
    1851:	8d 45 bd             	lea    -0x43(%ebp),%eax
    1854:	03 45 f4             	add    -0xc(%ebp),%eax
    1857:	0f b6 00             	movzbl (%eax),%eax
    185a:	84 c0                	test   %al,%al
    185c:	74 23                	je     1881 <concreate+0x1fc>
        printf(1, "concreate duplicate file %s\n", de.name);
    185e:	8d 45 ac             	lea    -0x54(%ebp),%eax
    1861:	83 c0 02             	add    $0x2,%eax
    1864:	89 44 24 08          	mov    %eax,0x8(%esp)
    1868:	c7 44 24 04 9e 49 00 	movl   $0x499e,0x4(%esp)
    186f:	00 
    1870:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    1877:	e8 7b 25 00 00       	call   3df7 <printf>
        exit();
    187c:	e8 b7 23 00 00       	call   3c38 <exit>
      }
      fa[i] = 1;
    1881:	8d 45 bd             	lea    -0x43(%ebp),%eax
    1884:	03 45 f4             	add    -0xc(%ebp),%eax
    1887:	c6 00 01             	movb   $0x1,(%eax)
      n++;
    188a:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
    188e:	eb 01                	jmp    1891 <concreate+0x20c>
  memset(fa, 0, sizeof(fa));
  fd = open(".", 0);
  n = 0;
  while(read(fd, &de, sizeof(de)) > 0){
    if(de.inum == 0)
      continue;
    1890:	90                   	nop
  }

  memset(fa, 0, sizeof(fa));
  fd = open(".", 0);
  n = 0;
  while(read(fd, &de, sizeof(de)) > 0){
    1891:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
    1898:	00 
    1899:	8d 45 ac             	lea    -0x54(%ebp),%eax
    189c:	89 44 24 04          	mov    %eax,0x4(%esp)
    18a0:	8b 45 e8             	mov    -0x18(%ebp),%eax
    18a3:	89 04 24             	mov    %eax,(%esp)
    18a6:	e8 a5 23 00 00       	call   3c50 <read>
    18ab:	85 c0                	test   %eax,%eax
    18ad:	0f 8f 3f ff ff ff    	jg     17f2 <concreate+0x16d>
      }
      fa[i] = 1;
      n++;
    }
  }
  close(fd);
    18b3:	8b 45 e8             	mov    -0x18(%ebp),%eax
    18b6:	89 04 24             	mov    %eax,(%esp)
    18b9:	e8 a2 23 00 00       	call   3c60 <close>

  if(n != 40){
    18be:	83 7d f0 28          	cmpl   $0x28,-0x10(%ebp)
    18c2:	74 19                	je     18dd <concreate+0x258>
    printf(1, "concreate not enough files in directory listing\n");
    18c4:	c7 44 24 04 bc 49 00 	movl   $0x49bc,0x4(%esp)
    18cb:	00 
    18cc:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    18d3:	e8 1f 25 00 00       	call   3df7 <printf>
    exit();
    18d8:	e8 5b 23 00 00       	call   3c38 <exit>
  }

  for(i = 0; i < 40; i++){
    18dd:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    18e4:	e9 2d 01 00 00       	jmp    1a16 <concreate+0x391>
    file[1] = '0' + i;
    18e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
    18ec:	83 c0 30             	add    $0x30,%eax
    18ef:	88 45 e6             	mov    %al,-0x1a(%ebp)
    pid = fork();
    18f2:	e8 39 23 00 00       	call   3c30 <fork>
    18f7:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(pid < 0){
    18fa:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
    18fe:	79 19                	jns    1919 <concreate+0x294>
      printf(1, "fork failed\n");
    1900:	c7 44 24 04 a9 45 00 	movl   $0x45a9,0x4(%esp)
    1907:	00 
    1908:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    190f:	e8 e3 24 00 00       	call   3df7 <printf>
      exit();
    1914:	e8 1f 23 00 00       	call   3c38 <exit>
    }
    if(((i % 3) == 0 && pid == 0) ||
    1919:	8b 4d f4             	mov    -0xc(%ebp),%ecx
    191c:	ba 56 55 55 55       	mov    $0x55555556,%edx
    1921:	89 c8                	mov    %ecx,%eax
    1923:	f7 ea                	imul   %edx
    1925:	89 c8                	mov    %ecx,%eax
    1927:	c1 f8 1f             	sar    $0x1f,%eax
    192a:	29 c2                	sub    %eax,%edx
    192c:	89 d0                	mov    %edx,%eax
    192e:	01 c0                	add    %eax,%eax
    1930:	01 d0                	add    %edx,%eax
    1932:	89 ca                	mov    %ecx,%edx
    1934:	29 c2                	sub    %eax,%edx
    1936:	85 d2                	test   %edx,%edx
    1938:	75 06                	jne    1940 <concreate+0x2bb>
    193a:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
    193e:	74 28                	je     1968 <concreate+0x2e3>
       ((i % 3) == 1 && pid != 0)){
    1940:	8b 4d f4             	mov    -0xc(%ebp),%ecx
    1943:	ba 56 55 55 55       	mov    $0x55555556,%edx
    1948:	89 c8                	mov    %ecx,%eax
    194a:	f7 ea                	imul   %edx
    194c:	89 c8                	mov    %ecx,%eax
    194e:	c1 f8 1f             	sar    $0x1f,%eax
    1951:	29 c2                	sub    %eax,%edx
    1953:	89 d0                	mov    %edx,%eax
    1955:	01 c0                	add    %eax,%eax
    1957:	01 d0                	add    %edx,%eax
    1959:	89 ca                	mov    %ecx,%edx
    195b:	29 c2                	sub    %eax,%edx
    pid = fork();
    if(pid < 0){
      printf(1, "fork failed\n");
      exit();
    }
    if(((i % 3) == 0 && pid == 0) ||
    195d:	83 fa 01             	cmp    $0x1,%edx
    1960:	75 74                	jne    19d6 <concreate+0x351>
       ((i % 3) == 1 && pid != 0)){
    1962:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
    1966:	74 6e                	je     19d6 <concreate+0x351>
      close(open(file, 0));
    1968:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
    196f:	00 
    1970:	8d 45 e5             	lea    -0x1b(%ebp),%eax
    1973:	89 04 24             	mov    %eax,(%esp)
    1976:	e8 fd 22 00 00       	call   3c78 <open>
    197b:	89 04 24             	mov    %eax,(%esp)
    197e:	e8 dd 22 00 00       	call   3c60 <close>
      close(open(file, 0));
    1983:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
    198a:	00 
    198b:	8d 45 e5             	lea    -0x1b(%ebp),%eax
    198e:	89 04 24             	mov    %eax,(%esp)
    1991:	e8 e2 22 00 00       	call   3c78 <open>
    1996:	89 04 24             	mov    %eax,(%esp)
    1999:	e8 c2 22 00 00       	call   3c60 <close>
      close(open(file, 0));
    199e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
    19a5:	00 
    19a6:	8d 45 e5             	lea    -0x1b(%ebp),%eax
    19a9:	89 04 24             	mov    %eax,(%esp)
    19ac:	e8 c7 22 00 00       	call   3c78 <open>
    19b1:	89 04 24             	mov    %eax,(%esp)
    19b4:	e8 a7 22 00 00       	call   3c60 <close>
      close(open(file, 0));
    19b9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
    19c0:	00 
    19c1:	8d 45 e5             	lea    -0x1b(%ebp),%eax
    19c4:	89 04 24             	mov    %eax,(%esp)
    19c7:	e8 ac 22 00 00       	call   3c78 <open>
    19cc:	89 04 24             	mov    %eax,(%esp)
    19cf:	e8 8c 22 00 00       	call   3c60 <close>
    19d4:	eb 2c                	jmp    1a02 <concreate+0x37d>
    } else {
      unlink(file);
    19d6:	8d 45 e5             	lea    -0x1b(%ebp),%eax
    19d9:	89 04 24             	mov    %eax,(%esp)
    19dc:	e8 a7 22 00 00       	call   3c88 <unlink>
      unlink(file);
    19e1:	8d 45 e5             	lea    -0x1b(%ebp),%eax
    19e4:	89 04 24             	mov    %eax,(%esp)
    19e7:	e8 9c 22 00 00       	call   3c88 <unlink>
      unlink(file);
    19ec:	8d 45 e5             	lea    -0x1b(%ebp),%eax
    19ef:	89 04 24             	mov    %eax,(%esp)
    19f2:	e8 91 22 00 00       	call   3c88 <unlink>
      unlink(file);
    19f7:	8d 45 e5             	lea    -0x1b(%ebp),%eax
    19fa:	89 04 24             	mov    %eax,(%esp)
    19fd:	e8 86 22 00 00       	call   3c88 <unlink>
    }
    if(pid == 0)
    1a02:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
    1a06:	75 05                	jne    1a0d <concreate+0x388>
      exit();
    1a08:	e8 2b 22 00 00       	call   3c38 <exit>
    else
      wait();
    1a0d:	e8 2e 22 00 00       	call   3c40 <wait>
  if(n != 40){
    printf(1, "concreate not enough files in directory listing\n");
    exit();
  }

  for(i = 0; i < 40; i++){
    1a12:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
    1a16:	83 7d f4 27          	cmpl   $0x27,-0xc(%ebp)
    1a1a:	0f 8e c9 fe ff ff    	jle    18e9 <concreate+0x264>
      exit();
    else
      wait();
  }

  printf(1, "concreate ok\n");
    1a20:	c7 44 24 04 ed 49 00 	movl   $0x49ed,0x4(%esp)
    1a27:	00 
    1a28:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    1a2f:	e8 c3 23 00 00       	call   3df7 <printf>
}
    1a34:	c9                   	leave  
    1a35:	c3                   	ret    

00001a36 <linkunlink>:

// another concurrent link/unlink/create test,
// to look for deadlocks.
void
linkunlink()
{
    1a36:	55                   	push   %ebp
    1a37:	89 e5                	mov    %esp,%ebp
    1a39:	83 ec 28             	sub    $0x28,%esp
  int pid, i;

  printf(1, "linkunlink test\n");
    1a3c:	c7 44 24 04 fb 49 00 	movl   $0x49fb,0x4(%esp)
    1a43:	00 
    1a44:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    1a4b:	e8 a7 23 00 00       	call   3df7 <printf>

  unlink("x");
    1a50:	c7 04 24 62 45 00 00 	movl   $0x4562,(%esp)
    1a57:	e8 2c 22 00 00       	call   3c88 <unlink>
  pid = fork();
    1a5c:	e8 cf 21 00 00       	call   3c30 <fork>
    1a61:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(pid < 0){
    1a64:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
    1a68:	79 19                	jns    1a83 <linkunlink+0x4d>
    printf(1, "fork failed\n");
    1a6a:	c7 44 24 04 a9 45 00 	movl   $0x45a9,0x4(%esp)
    1a71:	00 
    1a72:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    1a79:	e8 79 23 00 00       	call   3df7 <printf>
    exit();
    1a7e:	e8 b5 21 00 00       	call   3c38 <exit>
  }

  unsigned int x = (pid ? 1 : 97);
    1a83:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
    1a87:	74 07                	je     1a90 <linkunlink+0x5a>
    1a89:	b8 01 00 00 00       	mov    $0x1,%eax
    1a8e:	eb 05                	jmp    1a95 <linkunlink+0x5f>
    1a90:	b8 61 00 00 00       	mov    $0x61,%eax
    1a95:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(i = 0; i < 100; i++){
    1a98:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    1a9f:	e9 8e 00 00 00       	jmp    1b32 <linkunlink+0xfc>
    x = x * 1103515245 + 12345;
    1aa4:	8b 45 f0             	mov    -0x10(%ebp),%eax
    1aa7:	69 c0 6d 4e c6 41    	imul   $0x41c64e6d,%eax,%eax
    1aad:	05 39 30 00 00       	add    $0x3039,%eax
    1ab2:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((x % 3) == 0){
    1ab5:	8b 4d f0             	mov    -0x10(%ebp),%ecx
    1ab8:	ba ab aa aa aa       	mov    $0xaaaaaaab,%edx
    1abd:	89 c8                	mov    %ecx,%eax
    1abf:	f7 e2                	mul    %edx
    1ac1:	d1 ea                	shr    %edx
    1ac3:	89 d0                	mov    %edx,%eax
    1ac5:	01 c0                	add    %eax,%eax
    1ac7:	01 d0                	add    %edx,%eax
    1ac9:	89 ca                	mov    %ecx,%edx
    1acb:	29 c2                	sub    %eax,%edx
    1acd:	85 d2                	test   %edx,%edx
    1acf:	75 1e                	jne    1aef <linkunlink+0xb9>
      close(open("x", O_RDWR | O_CREATE));
    1ad1:	c7 44 24 04 02 02 00 	movl   $0x202,0x4(%esp)
    1ad8:	00 
    1ad9:	c7 04 24 62 45 00 00 	movl   $0x4562,(%esp)
    1ae0:	e8 93 21 00 00       	call   3c78 <open>
    1ae5:	89 04 24             	mov    %eax,(%esp)
    1ae8:	e8 73 21 00 00       	call   3c60 <close>
    1aed:	eb 3f                	jmp    1b2e <linkunlink+0xf8>
    } else if((x % 3) == 1){
    1aef:	8b 4d f0             	mov    -0x10(%ebp),%ecx
    1af2:	ba ab aa aa aa       	mov    $0xaaaaaaab,%edx
    1af7:	89 c8                	mov    %ecx,%eax
    1af9:	f7 e2                	mul    %edx
    1afb:	d1 ea                	shr    %edx
    1afd:	89 d0                	mov    %edx,%eax
    1aff:	01 c0                	add    %eax,%eax
    1b01:	01 d0                	add    %edx,%eax
    1b03:	89 ca                	mov    %ecx,%edx
    1b05:	29 c2                	sub    %eax,%edx
    1b07:	83 fa 01             	cmp    $0x1,%edx
    1b0a:	75 16                	jne    1b22 <linkunlink+0xec>
      link("cat", "x");
    1b0c:	c7 44 24 04 62 45 00 	movl   $0x4562,0x4(%esp)
    1b13:	00 
    1b14:	c7 04 24 0c 4a 00 00 	movl   $0x4a0c,(%esp)
    1b1b:	e8 78 21 00 00       	call   3c98 <link>
    1b20:	eb 0c                	jmp    1b2e <linkunlink+0xf8>
    } else {
      unlink("x");
    1b22:	c7 04 24 62 45 00 00 	movl   $0x4562,(%esp)
    1b29:	e8 5a 21 00 00       	call   3c88 <unlink>
    printf(1, "fork failed\n");
    exit();
  }

  unsigned int x = (pid ? 1 : 97);
  for(i = 0; i < 100; i++){
    1b2e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
    1b32:	83 7d f4 63          	cmpl   $0x63,-0xc(%ebp)
    1b36:	0f 8e 68 ff ff ff    	jle    1aa4 <linkunlink+0x6e>
    } else {
      unlink("x");
    }
  }

  if(pid)
    1b3c:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
    1b40:	74 1b                	je     1b5d <linkunlink+0x127>
    wait();
    1b42:	e8 f9 20 00 00       	call   3c40 <wait>
  else 
    exit();

  printf(1, "linkunlink ok\n");
    1b47:	c7 44 24 04 10 4a 00 	movl   $0x4a10,0x4(%esp)
    1b4e:	00 
    1b4f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    1b56:	e8 9c 22 00 00       	call   3df7 <printf>
}
    1b5b:	c9                   	leave  
    1b5c:	c3                   	ret    
  }

  if(pid)
    wait();
  else 
    exit();
    1b5d:	e8 d6 20 00 00       	call   3c38 <exit>

00001b62 <bigdir>:
}

// directory that uses indirect blocks
void
bigdir(void)
{
    1b62:	55                   	push   %ebp
    1b63:	89 e5                	mov    %esp,%ebp
    1b65:	83 ec 38             	sub    $0x38,%esp
  int i, fd;
  char name[10];

  printf(1, "bigdir test\n");
    1b68:	c7 44 24 04 1f 4a 00 	movl   $0x4a1f,0x4(%esp)
    1b6f:	00 
    1b70:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    1b77:	e8 7b 22 00 00       	call   3df7 <printf>
  unlink("bd");
    1b7c:	c7 04 24 2c 4a 00 00 	movl   $0x4a2c,(%esp)
    1b83:	e8 00 21 00 00       	call   3c88 <unlink>

  fd = open("bd", O_CREATE);
    1b88:	c7 44 24 04 00 02 00 	movl   $0x200,0x4(%esp)
    1b8f:	00 
    1b90:	c7 04 24 2c 4a 00 00 	movl   $0x4a2c,(%esp)
    1b97:	e8 dc 20 00 00       	call   3c78 <open>
    1b9c:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(fd < 0){
    1b9f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
    1ba3:	79 19                	jns    1bbe <bigdir+0x5c>
    printf(1, "bigdir create failed\n");
    1ba5:	c7 44 24 04 2f 4a 00 	movl   $0x4a2f,0x4(%esp)
    1bac:	00 
    1bad:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    1bb4:	e8 3e 22 00 00       	call   3df7 <printf>
    exit();
    1bb9:	e8 7a 20 00 00       	call   3c38 <exit>
  }
  close(fd);
    1bbe:	8b 45 f0             	mov    -0x10(%ebp),%eax
    1bc1:	89 04 24             	mov    %eax,(%esp)
    1bc4:	e8 97 20 00 00       	call   3c60 <close>

  for(i = 0; i < 500; i++){
    1bc9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    1bd0:	eb 68                	jmp    1c3a <bigdir+0xd8>
    name[0] = 'x';
    1bd2:	c6 45 e6 78          	movb   $0x78,-0x1a(%ebp)
    name[1] = '0' + (i / 64);
    1bd6:	8b 45 f4             	mov    -0xc(%ebp),%eax
    1bd9:	8d 50 3f             	lea    0x3f(%eax),%edx
    1bdc:	85 c0                	test   %eax,%eax
    1bde:	0f 48 c2             	cmovs  %edx,%eax
    1be1:	c1 f8 06             	sar    $0x6,%eax
    1be4:	83 c0 30             	add    $0x30,%eax
    1be7:	88 45 e7             	mov    %al,-0x19(%ebp)
    name[2] = '0' + (i % 64);
    1bea:	8b 45 f4             	mov    -0xc(%ebp),%eax
    1bed:	89 c2                	mov    %eax,%edx
    1bef:	c1 fa 1f             	sar    $0x1f,%edx
    1bf2:	c1 ea 1a             	shr    $0x1a,%edx
    1bf5:	01 d0                	add    %edx,%eax
    1bf7:	83 e0 3f             	and    $0x3f,%eax
    1bfa:	29 d0                	sub    %edx,%eax
    1bfc:	83 c0 30             	add    $0x30,%eax
    1bff:	88 45 e8             	mov    %al,-0x18(%ebp)
    name[3] = '\0';
    1c02:	c6 45 e9 00          	movb   $0x0,-0x17(%ebp)
    if(link("bd", name) != 0){
    1c06:	8d 45 e6             	lea    -0x1a(%ebp),%eax
    1c09:	89 44 24 04          	mov    %eax,0x4(%esp)
    1c0d:	c7 04 24 2c 4a 00 00 	movl   $0x4a2c,(%esp)
    1c14:	e8 7f 20 00 00       	call   3c98 <link>
    1c19:	85 c0                	test   %eax,%eax
    1c1b:	74 19                	je     1c36 <bigdir+0xd4>
      printf(1, "bigdir link failed\n");
    1c1d:	c7 44 24 04 45 4a 00 	movl   $0x4a45,0x4(%esp)
    1c24:	00 
    1c25:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    1c2c:	e8 c6 21 00 00       	call   3df7 <printf>
      exit();
    1c31:	e8 02 20 00 00       	call   3c38 <exit>
    printf(1, "bigdir create failed\n");
    exit();
  }
  close(fd);

  for(i = 0; i < 500; i++){
    1c36:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
    1c3a:	81 7d f4 f3 01 00 00 	cmpl   $0x1f3,-0xc(%ebp)
    1c41:	7e 8f                	jle    1bd2 <bigdir+0x70>
      printf(1, "bigdir link failed\n");
      exit();
    }
  }

  unlink("bd");
    1c43:	c7 04 24 2c 4a 00 00 	movl   $0x4a2c,(%esp)
    1c4a:	e8 39 20 00 00       	call   3c88 <unlink>
  for(i = 0; i < 500; i++){
    1c4f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    1c56:	eb 60                	jmp    1cb8 <bigdir+0x156>
    name[0] = 'x';
    1c58:	c6 45 e6 78          	movb   $0x78,-0x1a(%ebp)
    name[1] = '0' + (i / 64);
    1c5c:	8b 45 f4             	mov    -0xc(%ebp),%eax
    1c5f:	8d 50 3f             	lea    0x3f(%eax),%edx
    1c62:	85 c0                	test   %eax,%eax
    1c64:	0f 48 c2             	cmovs  %edx,%eax
    1c67:	c1 f8 06             	sar    $0x6,%eax
    1c6a:	83 c0 30             	add    $0x30,%eax
    1c6d:	88 45 e7             	mov    %al,-0x19(%ebp)
    name[2] = '0' + (i % 64);
    1c70:	8b 45 f4             	mov    -0xc(%ebp),%eax
    1c73:	89 c2                	mov    %eax,%edx
    1c75:	c1 fa 1f             	sar    $0x1f,%edx
    1c78:	c1 ea 1a             	shr    $0x1a,%edx
    1c7b:	01 d0                	add    %edx,%eax
    1c7d:	83 e0 3f             	and    $0x3f,%eax
    1c80:	29 d0                	sub    %edx,%eax
    1c82:	83 c0 30             	add    $0x30,%eax
    1c85:	88 45 e8             	mov    %al,-0x18(%ebp)
    name[3] = '\0';
    1c88:	c6 45 e9 00          	movb   $0x0,-0x17(%ebp)
    if(unlink(name) != 0){
    1c8c:	8d 45 e6             	lea    -0x1a(%ebp),%eax
    1c8f:	89 04 24             	mov    %eax,(%esp)
    1c92:	e8 f1 1f 00 00       	call   3c88 <unlink>
    1c97:	85 c0                	test   %eax,%eax
    1c99:	74 19                	je     1cb4 <bigdir+0x152>
      printf(1, "bigdir unlink failed");
    1c9b:	c7 44 24 04 59 4a 00 	movl   $0x4a59,0x4(%esp)
    1ca2:	00 
    1ca3:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    1caa:	e8 48 21 00 00       	call   3df7 <printf>
      exit();
    1caf:	e8 84 1f 00 00       	call   3c38 <exit>
      exit();
    }
  }

  unlink("bd");
  for(i = 0; i < 500; i++){
    1cb4:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
    1cb8:	81 7d f4 f3 01 00 00 	cmpl   $0x1f3,-0xc(%ebp)
    1cbf:	7e 97                	jle    1c58 <bigdir+0xf6>
      printf(1, "bigdir unlink failed");
      exit();
    }
  }

  printf(1, "bigdir ok\n");
    1cc1:	c7 44 24 04 6e 4a 00 	movl   $0x4a6e,0x4(%esp)
    1cc8:	00 
    1cc9:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    1cd0:	e8 22 21 00 00       	call   3df7 <printf>
}
    1cd5:	c9                   	leave  
    1cd6:	c3                   	ret    

00001cd7 <subdir>:

void
subdir(void)
{
    1cd7:	55                   	push   %ebp
    1cd8:	89 e5                	mov    %esp,%ebp
    1cda:	83 ec 28             	sub    $0x28,%esp
  int fd, cc;

  printf(1, "subdir test\n");
    1cdd:	c7 44 24 04 79 4a 00 	movl   $0x4a79,0x4(%esp)
    1ce4:	00 
    1ce5:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    1cec:	e8 06 21 00 00       	call   3df7 <printf>

  unlink("ff");
    1cf1:	c7 04 24 86 4a 00 00 	movl   $0x4a86,(%esp)
    1cf8:	e8 8b 1f 00 00       	call   3c88 <unlink>
  if(mkdir("dd") != 0){
    1cfd:	c7 04 24 89 4a 00 00 	movl   $0x4a89,(%esp)
    1d04:	e8 97 1f 00 00       	call   3ca0 <mkdir>
    1d09:	85 c0                	test   %eax,%eax
    1d0b:	74 19                	je     1d26 <subdir+0x4f>
    printf(1, "subdir mkdir dd failed\n");
    1d0d:	c7 44 24 04 8c 4a 00 	movl   $0x4a8c,0x4(%esp)
    1d14:	00 
    1d15:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    1d1c:	e8 d6 20 00 00       	call   3df7 <printf>
    exit();
    1d21:	e8 12 1f 00 00       	call   3c38 <exit>
  }

  fd = open("dd/ff", O_CREATE | O_RDWR);
    1d26:	c7 44 24 04 02 02 00 	movl   $0x202,0x4(%esp)
    1d2d:	00 
    1d2e:	c7 04 24 a4 4a 00 00 	movl   $0x4aa4,(%esp)
    1d35:	e8 3e 1f 00 00       	call   3c78 <open>
    1d3a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(fd < 0){
    1d3d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
    1d41:	79 19                	jns    1d5c <subdir+0x85>
    printf(1, "create dd/ff failed\n");
    1d43:	c7 44 24 04 aa 4a 00 	movl   $0x4aaa,0x4(%esp)
    1d4a:	00 
    1d4b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    1d52:	e8 a0 20 00 00       	call   3df7 <printf>
    exit();
    1d57:	e8 dc 1e 00 00       	call   3c38 <exit>
  }
  write(fd, "ff", 2);
    1d5c:	c7 44 24 08 02 00 00 	movl   $0x2,0x8(%esp)
    1d63:	00 
    1d64:	c7 44 24 04 86 4a 00 	movl   $0x4a86,0x4(%esp)
    1d6b:	00 
    1d6c:	8b 45 f4             	mov    -0xc(%ebp),%eax
    1d6f:	89 04 24             	mov    %eax,(%esp)
    1d72:	e8 e1 1e 00 00       	call   3c58 <write>
  close(fd);
    1d77:	8b 45 f4             	mov    -0xc(%ebp),%eax
    1d7a:	89 04 24             	mov    %eax,(%esp)
    1d7d:	e8 de 1e 00 00       	call   3c60 <close>
  
  if(unlink("dd") >= 0){
    1d82:	c7 04 24 89 4a 00 00 	movl   $0x4a89,(%esp)
    1d89:	e8 fa 1e 00 00       	call   3c88 <unlink>
    1d8e:	85 c0                	test   %eax,%eax
    1d90:	78 19                	js     1dab <subdir+0xd4>
    printf(1, "unlink dd (non-empty dir) succeeded!\n");
    1d92:	c7 44 24 04 c0 4a 00 	movl   $0x4ac0,0x4(%esp)
    1d99:	00 
    1d9a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    1da1:	e8 51 20 00 00       	call   3df7 <printf>
    exit();
    1da6:	e8 8d 1e 00 00       	call   3c38 <exit>
  }

  if(mkdir("/dd/dd") != 0){
    1dab:	c7 04 24 e6 4a 00 00 	movl   $0x4ae6,(%esp)
    1db2:	e8 e9 1e 00 00       	call   3ca0 <mkdir>
    1db7:	85 c0                	test   %eax,%eax
    1db9:	74 19                	je     1dd4 <subdir+0xfd>
    printf(1, "subdir mkdir dd/dd failed\n");
    1dbb:	c7 44 24 04 ed 4a 00 	movl   $0x4aed,0x4(%esp)
    1dc2:	00 
    1dc3:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    1dca:	e8 28 20 00 00       	call   3df7 <printf>
    exit();
    1dcf:	e8 64 1e 00 00       	call   3c38 <exit>
  }

  fd = open("dd/dd/ff", O_CREATE | O_RDWR);
    1dd4:	c7 44 24 04 02 02 00 	movl   $0x202,0x4(%esp)
    1ddb:	00 
    1ddc:	c7 04 24 08 4b 00 00 	movl   $0x4b08,(%esp)
    1de3:	e8 90 1e 00 00       	call   3c78 <open>
    1de8:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(fd < 0){
    1deb:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
    1def:	79 19                	jns    1e0a <subdir+0x133>
    printf(1, "create dd/dd/ff failed\n");
    1df1:	c7 44 24 04 11 4b 00 	movl   $0x4b11,0x4(%esp)
    1df8:	00 
    1df9:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    1e00:	e8 f2 1f 00 00       	call   3df7 <printf>
    exit();
    1e05:	e8 2e 1e 00 00       	call   3c38 <exit>
  }
  write(fd, "FF", 2);
    1e0a:	c7 44 24 08 02 00 00 	movl   $0x2,0x8(%esp)
    1e11:	00 
    1e12:	c7 44 24 04 29 4b 00 	movl   $0x4b29,0x4(%esp)
    1e19:	00 
    1e1a:	8b 45 f4             	mov    -0xc(%ebp),%eax
    1e1d:	89 04 24             	mov    %eax,(%esp)
    1e20:	e8 33 1e 00 00       	call   3c58 <write>
  close(fd);
    1e25:	8b 45 f4             	mov    -0xc(%ebp),%eax
    1e28:	89 04 24             	mov    %eax,(%esp)
    1e2b:	e8 30 1e 00 00       	call   3c60 <close>

  fd = open("dd/dd/../ff", 0);
    1e30:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
    1e37:	00 
    1e38:	c7 04 24 2c 4b 00 00 	movl   $0x4b2c,(%esp)
    1e3f:	e8 34 1e 00 00       	call   3c78 <open>
    1e44:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(fd < 0){
    1e47:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
    1e4b:	79 19                	jns    1e66 <subdir+0x18f>
    printf(1, "open dd/dd/../ff failed\n");
    1e4d:	c7 44 24 04 38 4b 00 	movl   $0x4b38,0x4(%esp)
    1e54:	00 
    1e55:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    1e5c:	e8 96 1f 00 00       	call   3df7 <printf>
    exit();
    1e61:	e8 d2 1d 00 00       	call   3c38 <exit>
  }
  cc = read(fd, buf, sizeof(buf));
    1e66:	c7 44 24 08 00 20 00 	movl   $0x2000,0x8(%esp)
    1e6d:	00 
    1e6e:	c7 44 24 04 00 87 00 	movl   $0x8700,0x4(%esp)
    1e75:	00 
    1e76:	8b 45 f4             	mov    -0xc(%ebp),%eax
    1e79:	89 04 24             	mov    %eax,(%esp)
    1e7c:	e8 cf 1d 00 00       	call   3c50 <read>
    1e81:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(cc != 2 || buf[0] != 'f'){
    1e84:	83 7d f0 02          	cmpl   $0x2,-0x10(%ebp)
    1e88:	75 0b                	jne    1e95 <subdir+0x1be>
    1e8a:	0f b6 05 00 87 00 00 	movzbl 0x8700,%eax
    1e91:	3c 66                	cmp    $0x66,%al
    1e93:	74 19                	je     1eae <subdir+0x1d7>
    printf(1, "dd/dd/../ff wrong content\n");
    1e95:	c7 44 24 04 51 4b 00 	movl   $0x4b51,0x4(%esp)
    1e9c:	00 
    1e9d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    1ea4:	e8 4e 1f 00 00       	call   3df7 <printf>
    exit();
    1ea9:	e8 8a 1d 00 00       	call   3c38 <exit>
  }
  close(fd);
    1eae:	8b 45 f4             	mov    -0xc(%ebp),%eax
    1eb1:	89 04 24             	mov    %eax,(%esp)
    1eb4:	e8 a7 1d 00 00       	call   3c60 <close>

  if(link("dd/dd/ff", "dd/dd/ffff") != 0){
    1eb9:	c7 44 24 04 6c 4b 00 	movl   $0x4b6c,0x4(%esp)
    1ec0:	00 
    1ec1:	c7 04 24 08 4b 00 00 	movl   $0x4b08,(%esp)
    1ec8:	e8 cb 1d 00 00       	call   3c98 <link>
    1ecd:	85 c0                	test   %eax,%eax
    1ecf:	74 19                	je     1eea <subdir+0x213>
    printf(1, "link dd/dd/ff dd/dd/ffff failed\n");
    1ed1:	c7 44 24 04 78 4b 00 	movl   $0x4b78,0x4(%esp)
    1ed8:	00 
    1ed9:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    1ee0:	e8 12 1f 00 00       	call   3df7 <printf>
    exit();
    1ee5:	e8 4e 1d 00 00       	call   3c38 <exit>
  }

  if(unlink("dd/dd/ff") != 0){
    1eea:	c7 04 24 08 4b 00 00 	movl   $0x4b08,(%esp)
    1ef1:	e8 92 1d 00 00       	call   3c88 <unlink>
    1ef6:	85 c0                	test   %eax,%eax
    1ef8:	74 19                	je     1f13 <subdir+0x23c>
    printf(1, "unlink dd/dd/ff failed\n");
    1efa:	c7 44 24 04 99 4b 00 	movl   $0x4b99,0x4(%esp)
    1f01:	00 
    1f02:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    1f09:	e8 e9 1e 00 00       	call   3df7 <printf>
    exit();
    1f0e:	e8 25 1d 00 00       	call   3c38 <exit>
  }
  if(open("dd/dd/ff", O_RDONLY) >= 0){
    1f13:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
    1f1a:	00 
    1f1b:	c7 04 24 08 4b 00 00 	movl   $0x4b08,(%esp)
    1f22:	e8 51 1d 00 00       	call   3c78 <open>
    1f27:	85 c0                	test   %eax,%eax
    1f29:	78 19                	js     1f44 <subdir+0x26d>
    printf(1, "open (unlinked) dd/dd/ff succeeded\n");
    1f2b:	c7 44 24 04 b4 4b 00 	movl   $0x4bb4,0x4(%esp)
    1f32:	00 
    1f33:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    1f3a:	e8 b8 1e 00 00       	call   3df7 <printf>
    exit();
    1f3f:	e8 f4 1c 00 00       	call   3c38 <exit>
  }

  if(chdir("dd") != 0){
    1f44:	c7 04 24 89 4a 00 00 	movl   $0x4a89,(%esp)
    1f4b:	e8 58 1d 00 00       	call   3ca8 <chdir>
    1f50:	85 c0                	test   %eax,%eax
    1f52:	74 19                	je     1f6d <subdir+0x296>
    printf(1, "chdir dd failed\n");
    1f54:	c7 44 24 04 d8 4b 00 	movl   $0x4bd8,0x4(%esp)
    1f5b:	00 
    1f5c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    1f63:	e8 8f 1e 00 00       	call   3df7 <printf>
    exit();
    1f68:	e8 cb 1c 00 00       	call   3c38 <exit>
  }
  if(chdir("dd/../../dd") != 0){
    1f6d:	c7 04 24 e9 4b 00 00 	movl   $0x4be9,(%esp)
    1f74:	e8 2f 1d 00 00       	call   3ca8 <chdir>
    1f79:	85 c0                	test   %eax,%eax
    1f7b:	74 19                	je     1f96 <subdir+0x2bf>
    printf(1, "chdir dd/../../dd failed\n");
    1f7d:	c7 44 24 04 f5 4b 00 	movl   $0x4bf5,0x4(%esp)
    1f84:	00 
    1f85:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    1f8c:	e8 66 1e 00 00       	call   3df7 <printf>
    exit();
    1f91:	e8 a2 1c 00 00       	call   3c38 <exit>
  }
  if(chdir("dd/../../../dd") != 0){
    1f96:	c7 04 24 0f 4c 00 00 	movl   $0x4c0f,(%esp)
    1f9d:	e8 06 1d 00 00       	call   3ca8 <chdir>
    1fa2:	85 c0                	test   %eax,%eax
    1fa4:	74 19                	je     1fbf <subdir+0x2e8>
    printf(1, "chdir dd/../../dd failed\n");
    1fa6:	c7 44 24 04 f5 4b 00 	movl   $0x4bf5,0x4(%esp)
    1fad:	00 
    1fae:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    1fb5:	e8 3d 1e 00 00       	call   3df7 <printf>
    exit();
    1fba:	e8 79 1c 00 00       	call   3c38 <exit>
  }
  if(chdir("./..") != 0){
    1fbf:	c7 04 24 1e 4c 00 00 	movl   $0x4c1e,(%esp)
    1fc6:	e8 dd 1c 00 00       	call   3ca8 <chdir>
    1fcb:	85 c0                	test   %eax,%eax
    1fcd:	74 19                	je     1fe8 <subdir+0x311>
    printf(1, "chdir ./.. failed\n");
    1fcf:	c7 44 24 04 23 4c 00 	movl   $0x4c23,0x4(%esp)
    1fd6:	00 
    1fd7:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    1fde:	e8 14 1e 00 00       	call   3df7 <printf>
    exit();
    1fe3:	e8 50 1c 00 00       	call   3c38 <exit>
  }

  fd = open("dd/dd/ffff", 0);
    1fe8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
    1fef:	00 
    1ff0:	c7 04 24 6c 4b 00 00 	movl   $0x4b6c,(%esp)
    1ff7:	e8 7c 1c 00 00       	call   3c78 <open>
    1ffc:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(fd < 0){
    1fff:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
    2003:	79 19                	jns    201e <subdir+0x347>
    printf(1, "open dd/dd/ffff failed\n");
    2005:	c7 44 24 04 36 4c 00 	movl   $0x4c36,0x4(%esp)
    200c:	00 
    200d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2014:	e8 de 1d 00 00       	call   3df7 <printf>
    exit();
    2019:	e8 1a 1c 00 00       	call   3c38 <exit>
  }
  if(read(fd, buf, sizeof(buf)) != 2){
    201e:	c7 44 24 08 00 20 00 	movl   $0x2000,0x8(%esp)
    2025:	00 
    2026:	c7 44 24 04 00 87 00 	movl   $0x8700,0x4(%esp)
    202d:	00 
    202e:	8b 45 f4             	mov    -0xc(%ebp),%eax
    2031:	89 04 24             	mov    %eax,(%esp)
    2034:	e8 17 1c 00 00       	call   3c50 <read>
    2039:	83 f8 02             	cmp    $0x2,%eax
    203c:	74 19                	je     2057 <subdir+0x380>
    printf(1, "read dd/dd/ffff wrong len\n");
    203e:	c7 44 24 04 4e 4c 00 	movl   $0x4c4e,0x4(%esp)
    2045:	00 
    2046:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    204d:	e8 a5 1d 00 00       	call   3df7 <printf>
    exit();
    2052:	e8 e1 1b 00 00       	call   3c38 <exit>
  }
  close(fd);
    2057:	8b 45 f4             	mov    -0xc(%ebp),%eax
    205a:	89 04 24             	mov    %eax,(%esp)
    205d:	e8 fe 1b 00 00       	call   3c60 <close>

  if(open("dd/dd/ff", O_RDONLY) >= 0){
    2062:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
    2069:	00 
    206a:	c7 04 24 08 4b 00 00 	movl   $0x4b08,(%esp)
    2071:	e8 02 1c 00 00       	call   3c78 <open>
    2076:	85 c0                	test   %eax,%eax
    2078:	78 19                	js     2093 <subdir+0x3bc>
    printf(1, "open (unlinked) dd/dd/ff succeeded!\n");
    207a:	c7 44 24 04 6c 4c 00 	movl   $0x4c6c,0x4(%esp)
    2081:	00 
    2082:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2089:	e8 69 1d 00 00       	call   3df7 <printf>
    exit();
    208e:	e8 a5 1b 00 00       	call   3c38 <exit>
  }

  if(open("dd/ff/ff", O_CREATE|O_RDWR) >= 0){
    2093:	c7 44 24 04 02 02 00 	movl   $0x202,0x4(%esp)
    209a:	00 
    209b:	c7 04 24 91 4c 00 00 	movl   $0x4c91,(%esp)
    20a2:	e8 d1 1b 00 00       	call   3c78 <open>
    20a7:	85 c0                	test   %eax,%eax
    20a9:	78 19                	js     20c4 <subdir+0x3ed>
    printf(1, "create dd/ff/ff succeeded!\n");
    20ab:	c7 44 24 04 9a 4c 00 	movl   $0x4c9a,0x4(%esp)
    20b2:	00 
    20b3:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    20ba:	e8 38 1d 00 00       	call   3df7 <printf>
    exit();
    20bf:	e8 74 1b 00 00       	call   3c38 <exit>
  }
  if(open("dd/xx/ff", O_CREATE|O_RDWR) >= 0){
    20c4:	c7 44 24 04 02 02 00 	movl   $0x202,0x4(%esp)
    20cb:	00 
    20cc:	c7 04 24 b6 4c 00 00 	movl   $0x4cb6,(%esp)
    20d3:	e8 a0 1b 00 00       	call   3c78 <open>
    20d8:	85 c0                	test   %eax,%eax
    20da:	78 19                	js     20f5 <subdir+0x41e>
    printf(1, "create dd/xx/ff succeeded!\n");
    20dc:	c7 44 24 04 bf 4c 00 	movl   $0x4cbf,0x4(%esp)
    20e3:	00 
    20e4:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    20eb:	e8 07 1d 00 00       	call   3df7 <printf>
    exit();
    20f0:	e8 43 1b 00 00       	call   3c38 <exit>
  }
  if(open("dd", O_CREATE) >= 0){
    20f5:	c7 44 24 04 00 02 00 	movl   $0x200,0x4(%esp)
    20fc:	00 
    20fd:	c7 04 24 89 4a 00 00 	movl   $0x4a89,(%esp)
    2104:	e8 6f 1b 00 00       	call   3c78 <open>
    2109:	85 c0                	test   %eax,%eax
    210b:	78 19                	js     2126 <subdir+0x44f>
    printf(1, "create dd succeeded!\n");
    210d:	c7 44 24 04 db 4c 00 	movl   $0x4cdb,0x4(%esp)
    2114:	00 
    2115:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    211c:	e8 d6 1c 00 00       	call   3df7 <printf>
    exit();
    2121:	e8 12 1b 00 00       	call   3c38 <exit>
  }
  if(open("dd", O_RDWR) >= 0){
    2126:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
    212d:	00 
    212e:	c7 04 24 89 4a 00 00 	movl   $0x4a89,(%esp)
    2135:	e8 3e 1b 00 00       	call   3c78 <open>
    213a:	85 c0                	test   %eax,%eax
    213c:	78 19                	js     2157 <subdir+0x480>
    printf(1, "open dd rdwr succeeded!\n");
    213e:	c7 44 24 04 f1 4c 00 	movl   $0x4cf1,0x4(%esp)
    2145:	00 
    2146:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    214d:	e8 a5 1c 00 00       	call   3df7 <printf>
    exit();
    2152:	e8 e1 1a 00 00       	call   3c38 <exit>
  }
  if(open("dd", O_WRONLY) >= 0){
    2157:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
    215e:	00 
    215f:	c7 04 24 89 4a 00 00 	movl   $0x4a89,(%esp)
    2166:	e8 0d 1b 00 00       	call   3c78 <open>
    216b:	85 c0                	test   %eax,%eax
    216d:	78 19                	js     2188 <subdir+0x4b1>
    printf(1, "open dd wronly succeeded!\n");
    216f:	c7 44 24 04 0a 4d 00 	movl   $0x4d0a,0x4(%esp)
    2176:	00 
    2177:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    217e:	e8 74 1c 00 00       	call   3df7 <printf>
    exit();
    2183:	e8 b0 1a 00 00       	call   3c38 <exit>
  }
  if(link("dd/ff/ff", "dd/dd/xx") == 0){
    2188:	c7 44 24 04 25 4d 00 	movl   $0x4d25,0x4(%esp)
    218f:	00 
    2190:	c7 04 24 91 4c 00 00 	movl   $0x4c91,(%esp)
    2197:	e8 fc 1a 00 00       	call   3c98 <link>
    219c:	85 c0                	test   %eax,%eax
    219e:	75 19                	jne    21b9 <subdir+0x4e2>
    printf(1, "link dd/ff/ff dd/dd/xx succeeded!\n");
    21a0:	c7 44 24 04 30 4d 00 	movl   $0x4d30,0x4(%esp)
    21a7:	00 
    21a8:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    21af:	e8 43 1c 00 00       	call   3df7 <printf>
    exit();
    21b4:	e8 7f 1a 00 00       	call   3c38 <exit>
  }
  if(link("dd/xx/ff", "dd/dd/xx") == 0){
    21b9:	c7 44 24 04 25 4d 00 	movl   $0x4d25,0x4(%esp)
    21c0:	00 
    21c1:	c7 04 24 b6 4c 00 00 	movl   $0x4cb6,(%esp)
    21c8:	e8 cb 1a 00 00       	call   3c98 <link>
    21cd:	85 c0                	test   %eax,%eax
    21cf:	75 19                	jne    21ea <subdir+0x513>
    printf(1, "link dd/xx/ff dd/dd/xx succeeded!\n");
    21d1:	c7 44 24 04 54 4d 00 	movl   $0x4d54,0x4(%esp)
    21d8:	00 
    21d9:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    21e0:	e8 12 1c 00 00       	call   3df7 <printf>
    exit();
    21e5:	e8 4e 1a 00 00       	call   3c38 <exit>
  }
  if(link("dd/ff", "dd/dd/ffff") == 0){
    21ea:	c7 44 24 04 6c 4b 00 	movl   $0x4b6c,0x4(%esp)
    21f1:	00 
    21f2:	c7 04 24 a4 4a 00 00 	movl   $0x4aa4,(%esp)
    21f9:	e8 9a 1a 00 00       	call   3c98 <link>
    21fe:	85 c0                	test   %eax,%eax
    2200:	75 19                	jne    221b <subdir+0x544>
    printf(1, "link dd/ff dd/dd/ffff succeeded!\n");
    2202:	c7 44 24 04 78 4d 00 	movl   $0x4d78,0x4(%esp)
    2209:	00 
    220a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2211:	e8 e1 1b 00 00       	call   3df7 <printf>
    exit();
    2216:	e8 1d 1a 00 00       	call   3c38 <exit>
  }
  if(mkdir("dd/ff/ff") == 0){
    221b:	c7 04 24 91 4c 00 00 	movl   $0x4c91,(%esp)
    2222:	e8 79 1a 00 00       	call   3ca0 <mkdir>
    2227:	85 c0                	test   %eax,%eax
    2229:	75 19                	jne    2244 <subdir+0x56d>
    printf(1, "mkdir dd/ff/ff succeeded!\n");
    222b:	c7 44 24 04 9a 4d 00 	movl   $0x4d9a,0x4(%esp)
    2232:	00 
    2233:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    223a:	e8 b8 1b 00 00       	call   3df7 <printf>
    exit();
    223f:	e8 f4 19 00 00       	call   3c38 <exit>
  }
  if(mkdir("dd/xx/ff") == 0){
    2244:	c7 04 24 b6 4c 00 00 	movl   $0x4cb6,(%esp)
    224b:	e8 50 1a 00 00       	call   3ca0 <mkdir>
    2250:	85 c0                	test   %eax,%eax
    2252:	75 19                	jne    226d <subdir+0x596>
    printf(1, "mkdir dd/xx/ff succeeded!\n");
    2254:	c7 44 24 04 b5 4d 00 	movl   $0x4db5,0x4(%esp)
    225b:	00 
    225c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2263:	e8 8f 1b 00 00       	call   3df7 <printf>
    exit();
    2268:	e8 cb 19 00 00       	call   3c38 <exit>
  }
  if(mkdir("dd/dd/ffff") == 0){
    226d:	c7 04 24 6c 4b 00 00 	movl   $0x4b6c,(%esp)
    2274:	e8 27 1a 00 00       	call   3ca0 <mkdir>
    2279:	85 c0                	test   %eax,%eax
    227b:	75 19                	jne    2296 <subdir+0x5bf>
    printf(1, "mkdir dd/dd/ffff succeeded!\n");
    227d:	c7 44 24 04 d0 4d 00 	movl   $0x4dd0,0x4(%esp)
    2284:	00 
    2285:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    228c:	e8 66 1b 00 00       	call   3df7 <printf>
    exit();
    2291:	e8 a2 19 00 00       	call   3c38 <exit>
  }
  if(unlink("dd/xx/ff") == 0){
    2296:	c7 04 24 b6 4c 00 00 	movl   $0x4cb6,(%esp)
    229d:	e8 e6 19 00 00       	call   3c88 <unlink>
    22a2:	85 c0                	test   %eax,%eax
    22a4:	75 19                	jne    22bf <subdir+0x5e8>
    printf(1, "unlink dd/xx/ff succeeded!\n");
    22a6:	c7 44 24 04 ed 4d 00 	movl   $0x4ded,0x4(%esp)
    22ad:	00 
    22ae:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    22b5:	e8 3d 1b 00 00       	call   3df7 <printf>
    exit();
    22ba:	e8 79 19 00 00       	call   3c38 <exit>
  }
  if(unlink("dd/ff/ff") == 0){
    22bf:	c7 04 24 91 4c 00 00 	movl   $0x4c91,(%esp)
    22c6:	e8 bd 19 00 00       	call   3c88 <unlink>
    22cb:	85 c0                	test   %eax,%eax
    22cd:	75 19                	jne    22e8 <subdir+0x611>
    printf(1, "unlink dd/ff/ff succeeded!\n");
    22cf:	c7 44 24 04 09 4e 00 	movl   $0x4e09,0x4(%esp)
    22d6:	00 
    22d7:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    22de:	e8 14 1b 00 00       	call   3df7 <printf>
    exit();
    22e3:	e8 50 19 00 00       	call   3c38 <exit>
  }
  if(chdir("dd/ff") == 0){
    22e8:	c7 04 24 a4 4a 00 00 	movl   $0x4aa4,(%esp)
    22ef:	e8 b4 19 00 00       	call   3ca8 <chdir>
    22f4:	85 c0                	test   %eax,%eax
    22f6:	75 19                	jne    2311 <subdir+0x63a>
    printf(1, "chdir dd/ff succeeded!\n");
    22f8:	c7 44 24 04 25 4e 00 	movl   $0x4e25,0x4(%esp)
    22ff:	00 
    2300:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2307:	e8 eb 1a 00 00       	call   3df7 <printf>
    exit();
    230c:	e8 27 19 00 00       	call   3c38 <exit>
  }
  if(chdir("dd/xx") == 0){
    2311:	c7 04 24 3d 4e 00 00 	movl   $0x4e3d,(%esp)
    2318:	e8 8b 19 00 00       	call   3ca8 <chdir>
    231d:	85 c0                	test   %eax,%eax
    231f:	75 19                	jne    233a <subdir+0x663>
    printf(1, "chdir dd/xx succeeded!\n");
    2321:	c7 44 24 04 43 4e 00 	movl   $0x4e43,0x4(%esp)
    2328:	00 
    2329:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2330:	e8 c2 1a 00 00       	call   3df7 <printf>
    exit();
    2335:	e8 fe 18 00 00       	call   3c38 <exit>
  }

  if(unlink("dd/dd/ffff") != 0){
    233a:	c7 04 24 6c 4b 00 00 	movl   $0x4b6c,(%esp)
    2341:	e8 42 19 00 00       	call   3c88 <unlink>
    2346:	85 c0                	test   %eax,%eax
    2348:	74 19                	je     2363 <subdir+0x68c>
    printf(1, "unlink dd/dd/ff failed\n");
    234a:	c7 44 24 04 99 4b 00 	movl   $0x4b99,0x4(%esp)
    2351:	00 
    2352:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2359:	e8 99 1a 00 00       	call   3df7 <printf>
    exit();
    235e:	e8 d5 18 00 00       	call   3c38 <exit>
  }
  if(unlink("dd/ff") != 0){
    2363:	c7 04 24 a4 4a 00 00 	movl   $0x4aa4,(%esp)
    236a:	e8 19 19 00 00       	call   3c88 <unlink>
    236f:	85 c0                	test   %eax,%eax
    2371:	74 19                	je     238c <subdir+0x6b5>
    printf(1, "unlink dd/ff failed\n");
    2373:	c7 44 24 04 5b 4e 00 	movl   $0x4e5b,0x4(%esp)
    237a:	00 
    237b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2382:	e8 70 1a 00 00       	call   3df7 <printf>
    exit();
    2387:	e8 ac 18 00 00       	call   3c38 <exit>
  }
  if(unlink("dd") == 0){
    238c:	c7 04 24 89 4a 00 00 	movl   $0x4a89,(%esp)
    2393:	e8 f0 18 00 00       	call   3c88 <unlink>
    2398:	85 c0                	test   %eax,%eax
    239a:	75 19                	jne    23b5 <subdir+0x6de>
    printf(1, "unlink non-empty dd succeeded!\n");
    239c:	c7 44 24 04 70 4e 00 	movl   $0x4e70,0x4(%esp)
    23a3:	00 
    23a4:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    23ab:	e8 47 1a 00 00       	call   3df7 <printf>
    exit();
    23b0:	e8 83 18 00 00       	call   3c38 <exit>
  }
  if(unlink("dd/dd") < 0){
    23b5:	c7 04 24 90 4e 00 00 	movl   $0x4e90,(%esp)
    23bc:	e8 c7 18 00 00       	call   3c88 <unlink>
    23c1:	85 c0                	test   %eax,%eax
    23c3:	79 19                	jns    23de <subdir+0x707>
    printf(1, "unlink dd/dd failed\n");
    23c5:	c7 44 24 04 96 4e 00 	movl   $0x4e96,0x4(%esp)
    23cc:	00 
    23cd:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    23d4:	e8 1e 1a 00 00       	call   3df7 <printf>
    exit();
    23d9:	e8 5a 18 00 00       	call   3c38 <exit>
  }
  if(unlink("dd") < 0){
    23de:	c7 04 24 89 4a 00 00 	movl   $0x4a89,(%esp)
    23e5:	e8 9e 18 00 00       	call   3c88 <unlink>
    23ea:	85 c0                	test   %eax,%eax
    23ec:	79 19                	jns    2407 <subdir+0x730>
    printf(1, "unlink dd failed\n");
    23ee:	c7 44 24 04 ab 4e 00 	movl   $0x4eab,0x4(%esp)
    23f5:	00 
    23f6:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    23fd:	e8 f5 19 00 00       	call   3df7 <printf>
    exit();
    2402:	e8 31 18 00 00       	call   3c38 <exit>
  }

  printf(1, "subdir ok\n");
    2407:	c7 44 24 04 bd 4e 00 	movl   $0x4ebd,0x4(%esp)
    240e:	00 
    240f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2416:	e8 dc 19 00 00       	call   3df7 <printf>
}
    241b:	c9                   	leave  
    241c:	c3                   	ret    

0000241d <bigwrite>:

// test writes that are larger than the log.
void
bigwrite(void)
{
    241d:	55                   	push   %ebp
    241e:	89 e5                	mov    %esp,%ebp
    2420:	83 ec 28             	sub    $0x28,%esp
  int fd, sz;

  printf(1, "bigwrite test\n");
    2423:	c7 44 24 04 c8 4e 00 	movl   $0x4ec8,0x4(%esp)
    242a:	00 
    242b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2432:	e8 c0 19 00 00       	call   3df7 <printf>

  unlink("bigwrite");
    2437:	c7 04 24 d7 4e 00 00 	movl   $0x4ed7,(%esp)
    243e:	e8 45 18 00 00       	call   3c88 <unlink>
  for(sz = 499; sz < 12*512; sz += 471){
    2443:	c7 45 f4 f3 01 00 00 	movl   $0x1f3,-0xc(%ebp)
    244a:	e9 b3 00 00 00       	jmp    2502 <bigwrite+0xe5>
    fd = open("bigwrite", O_CREATE | O_RDWR);
    244f:	c7 44 24 04 02 02 00 	movl   $0x202,0x4(%esp)
    2456:	00 
    2457:	c7 04 24 d7 4e 00 00 	movl   $0x4ed7,(%esp)
    245e:	e8 15 18 00 00       	call   3c78 <open>
    2463:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(fd < 0){
    2466:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
    246a:	79 19                	jns    2485 <bigwrite+0x68>
      printf(1, "cannot create bigwrite\n");
    246c:	c7 44 24 04 e0 4e 00 	movl   $0x4ee0,0x4(%esp)
    2473:	00 
    2474:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    247b:	e8 77 19 00 00       	call   3df7 <printf>
      exit();
    2480:	e8 b3 17 00 00       	call   3c38 <exit>
    }
    int i;
    for(i = 0; i < 2; i++){
    2485:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    248c:	eb 50                	jmp    24de <bigwrite+0xc1>
      int cc = write(fd, buf, sz);
    248e:	8b 45 f4             	mov    -0xc(%ebp),%eax
    2491:	89 44 24 08          	mov    %eax,0x8(%esp)
    2495:	c7 44 24 04 00 87 00 	movl   $0x8700,0x4(%esp)
    249c:	00 
    249d:	8b 45 ec             	mov    -0x14(%ebp),%eax
    24a0:	89 04 24             	mov    %eax,(%esp)
    24a3:	e8 b0 17 00 00       	call   3c58 <write>
    24a8:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(cc != sz){
    24ab:	8b 45 e8             	mov    -0x18(%ebp),%eax
    24ae:	3b 45 f4             	cmp    -0xc(%ebp),%eax
    24b1:	74 27                	je     24da <bigwrite+0xbd>
        printf(1, "write(%d) ret %d\n", sz, cc);
    24b3:	8b 45 e8             	mov    -0x18(%ebp),%eax
    24b6:	89 44 24 0c          	mov    %eax,0xc(%esp)
    24ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
    24bd:	89 44 24 08          	mov    %eax,0x8(%esp)
    24c1:	c7 44 24 04 f8 4e 00 	movl   $0x4ef8,0x4(%esp)
    24c8:	00 
    24c9:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    24d0:	e8 22 19 00 00       	call   3df7 <printf>
        exit();
    24d5:	e8 5e 17 00 00       	call   3c38 <exit>
    if(fd < 0){
      printf(1, "cannot create bigwrite\n");
      exit();
    }
    int i;
    for(i = 0; i < 2; i++){
    24da:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
    24de:	83 7d f0 01          	cmpl   $0x1,-0x10(%ebp)
    24e2:	7e aa                	jle    248e <bigwrite+0x71>
      if(cc != sz){
        printf(1, "write(%d) ret %d\n", sz, cc);
        exit();
      }
    }
    close(fd);
    24e4:	8b 45 ec             	mov    -0x14(%ebp),%eax
    24e7:	89 04 24             	mov    %eax,(%esp)
    24ea:	e8 71 17 00 00       	call   3c60 <close>
    unlink("bigwrite");
    24ef:	c7 04 24 d7 4e 00 00 	movl   $0x4ed7,(%esp)
    24f6:	e8 8d 17 00 00       	call   3c88 <unlink>
  int fd, sz;

  printf(1, "bigwrite test\n");

  unlink("bigwrite");
  for(sz = 499; sz < 12*512; sz += 471){
    24fb:	81 45 f4 d7 01 00 00 	addl   $0x1d7,-0xc(%ebp)
    2502:	81 7d f4 ff 17 00 00 	cmpl   $0x17ff,-0xc(%ebp)
    2509:	0f 8e 40 ff ff ff    	jle    244f <bigwrite+0x32>
    }
    close(fd);
    unlink("bigwrite");
  }

  printf(1, "bigwrite ok\n");
    250f:	c7 44 24 04 0a 4f 00 	movl   $0x4f0a,0x4(%esp)
    2516:	00 
    2517:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    251e:	e8 d4 18 00 00       	call   3df7 <printf>
}
    2523:	c9                   	leave  
    2524:	c3                   	ret    

00002525 <bigfile>:

void
bigfile(void)
{
    2525:	55                   	push   %ebp
    2526:	89 e5                	mov    %esp,%ebp
    2528:	83 ec 28             	sub    $0x28,%esp
  int fd, i, total, cc;

  printf(1, "bigfile test\n");
    252b:	c7 44 24 04 17 4f 00 	movl   $0x4f17,0x4(%esp)
    2532:	00 
    2533:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    253a:	e8 b8 18 00 00       	call   3df7 <printf>

  unlink("bigfile");
    253f:	c7 04 24 25 4f 00 00 	movl   $0x4f25,(%esp)
    2546:	e8 3d 17 00 00       	call   3c88 <unlink>
  fd = open("bigfile", O_CREATE | O_RDWR);
    254b:	c7 44 24 04 02 02 00 	movl   $0x202,0x4(%esp)
    2552:	00 
    2553:	c7 04 24 25 4f 00 00 	movl   $0x4f25,(%esp)
    255a:	e8 19 17 00 00       	call   3c78 <open>
    255f:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(fd < 0){
    2562:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
    2566:	79 19                	jns    2581 <bigfile+0x5c>
    printf(1, "cannot create bigfile");
    2568:	c7 44 24 04 2d 4f 00 	movl   $0x4f2d,0x4(%esp)
    256f:	00 
    2570:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2577:	e8 7b 18 00 00       	call   3df7 <printf>
    exit();
    257c:	e8 b7 16 00 00       	call   3c38 <exit>
  }
  for(i = 0; i < 20; i++){
    2581:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    2588:	eb 5a                	jmp    25e4 <bigfile+0xbf>
    memset(buf, i, 600);
    258a:	c7 44 24 08 58 02 00 	movl   $0x258,0x8(%esp)
    2591:	00 
    2592:	8b 45 f4             	mov    -0xc(%ebp),%eax
    2595:	89 44 24 04          	mov    %eax,0x4(%esp)
    2599:	c7 04 24 00 87 00 00 	movl   $0x8700,(%esp)
    25a0:	e8 ee 14 00 00       	call   3a93 <memset>
    if(write(fd, buf, 600) != 600){
    25a5:	c7 44 24 08 58 02 00 	movl   $0x258,0x8(%esp)
    25ac:	00 
    25ad:	c7 44 24 04 00 87 00 	movl   $0x8700,0x4(%esp)
    25b4:	00 
    25b5:	8b 45 ec             	mov    -0x14(%ebp),%eax
    25b8:	89 04 24             	mov    %eax,(%esp)
    25bb:	e8 98 16 00 00       	call   3c58 <write>
    25c0:	3d 58 02 00 00       	cmp    $0x258,%eax
    25c5:	74 19                	je     25e0 <bigfile+0xbb>
      printf(1, "write bigfile failed\n");
    25c7:	c7 44 24 04 43 4f 00 	movl   $0x4f43,0x4(%esp)
    25ce:	00 
    25cf:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    25d6:	e8 1c 18 00 00       	call   3df7 <printf>
      exit();
    25db:	e8 58 16 00 00       	call   3c38 <exit>
  fd = open("bigfile", O_CREATE | O_RDWR);
  if(fd < 0){
    printf(1, "cannot create bigfile");
    exit();
  }
  for(i = 0; i < 20; i++){
    25e0:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
    25e4:	83 7d f4 13          	cmpl   $0x13,-0xc(%ebp)
    25e8:	7e a0                	jle    258a <bigfile+0x65>
    if(write(fd, buf, 600) != 600){
      printf(1, "write bigfile failed\n");
      exit();
    }
  }
  close(fd);
    25ea:	8b 45 ec             	mov    -0x14(%ebp),%eax
    25ed:	89 04 24             	mov    %eax,(%esp)
    25f0:	e8 6b 16 00 00       	call   3c60 <close>

  fd = open("bigfile", 0);
    25f5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
    25fc:	00 
    25fd:	c7 04 24 25 4f 00 00 	movl   $0x4f25,(%esp)
    2604:	e8 6f 16 00 00       	call   3c78 <open>
    2609:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(fd < 0){
    260c:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
    2610:	79 19                	jns    262b <bigfile+0x106>
    printf(1, "cannot open bigfile\n");
    2612:	c7 44 24 04 59 4f 00 	movl   $0x4f59,0x4(%esp)
    2619:	00 
    261a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2621:	e8 d1 17 00 00       	call   3df7 <printf>
    exit();
    2626:	e8 0d 16 00 00       	call   3c38 <exit>
  }
  total = 0;
    262b:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  for(i = 0; ; i++){
    2632:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    cc = read(fd, buf, 300);
    2639:	c7 44 24 08 2c 01 00 	movl   $0x12c,0x8(%esp)
    2640:	00 
    2641:	c7 44 24 04 00 87 00 	movl   $0x8700,0x4(%esp)
    2648:	00 
    2649:	8b 45 ec             	mov    -0x14(%ebp),%eax
    264c:	89 04 24             	mov    %eax,(%esp)
    264f:	e8 fc 15 00 00       	call   3c50 <read>
    2654:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(cc < 0){
    2657:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
    265b:	79 19                	jns    2676 <bigfile+0x151>
      printf(1, "read bigfile failed\n");
    265d:	c7 44 24 04 6e 4f 00 	movl   $0x4f6e,0x4(%esp)
    2664:	00 
    2665:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    266c:	e8 86 17 00 00       	call   3df7 <printf>
      exit();
    2671:	e8 c2 15 00 00       	call   3c38 <exit>
    }
    if(cc == 0)
    2676:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
    267a:	74 7e                	je     26fa <bigfile+0x1d5>
      break;
    if(cc != 300){
    267c:	81 7d e8 2c 01 00 00 	cmpl   $0x12c,-0x18(%ebp)
    2683:	74 19                	je     269e <bigfile+0x179>
      printf(1, "short read bigfile\n");
    2685:	c7 44 24 04 83 4f 00 	movl   $0x4f83,0x4(%esp)
    268c:	00 
    268d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2694:	e8 5e 17 00 00       	call   3df7 <printf>
      exit();
    2699:	e8 9a 15 00 00       	call   3c38 <exit>
    }
    if(buf[0] != i/2 || buf[299] != i/2){
    269e:	0f b6 05 00 87 00 00 	movzbl 0x8700,%eax
    26a5:	0f be d0             	movsbl %al,%edx
    26a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
    26ab:	89 c1                	mov    %eax,%ecx
    26ad:	c1 e9 1f             	shr    $0x1f,%ecx
    26b0:	01 c8                	add    %ecx,%eax
    26b2:	d1 f8                	sar    %eax
    26b4:	39 c2                	cmp    %eax,%edx
    26b6:	75 1a                	jne    26d2 <bigfile+0x1ad>
    26b8:	0f b6 05 2b 88 00 00 	movzbl 0x882b,%eax
    26bf:	0f be d0             	movsbl %al,%edx
    26c2:	8b 45 f4             	mov    -0xc(%ebp),%eax
    26c5:	89 c1                	mov    %eax,%ecx
    26c7:	c1 e9 1f             	shr    $0x1f,%ecx
    26ca:	01 c8                	add    %ecx,%eax
    26cc:	d1 f8                	sar    %eax
    26ce:	39 c2                	cmp    %eax,%edx
    26d0:	74 19                	je     26eb <bigfile+0x1c6>
      printf(1, "read bigfile wrong data\n");
    26d2:	c7 44 24 04 97 4f 00 	movl   $0x4f97,0x4(%esp)
    26d9:	00 
    26da:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    26e1:	e8 11 17 00 00       	call   3df7 <printf>
      exit();
    26e6:	e8 4d 15 00 00       	call   3c38 <exit>
    }
    total += cc;
    26eb:	8b 45 e8             	mov    -0x18(%ebp),%eax
    26ee:	01 45 f0             	add    %eax,-0x10(%ebp)
  if(fd < 0){
    printf(1, "cannot open bigfile\n");
    exit();
  }
  total = 0;
  for(i = 0; ; i++){
    26f1:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
    if(buf[0] != i/2 || buf[299] != i/2){
      printf(1, "read bigfile wrong data\n");
      exit();
    }
    total += cc;
  }
    26f5:	e9 3f ff ff ff       	jmp    2639 <bigfile+0x114>
    if(cc < 0){
      printf(1, "read bigfile failed\n");
      exit();
    }
    if(cc == 0)
      break;
    26fa:	90                   	nop
      printf(1, "read bigfile wrong data\n");
      exit();
    }
    total += cc;
  }
  close(fd);
    26fb:	8b 45 ec             	mov    -0x14(%ebp),%eax
    26fe:	89 04 24             	mov    %eax,(%esp)
    2701:	e8 5a 15 00 00       	call   3c60 <close>
  if(total != 20*600){
    2706:	81 7d f0 e0 2e 00 00 	cmpl   $0x2ee0,-0x10(%ebp)
    270d:	74 19                	je     2728 <bigfile+0x203>
    printf(1, "read bigfile wrong total\n");
    270f:	c7 44 24 04 b0 4f 00 	movl   $0x4fb0,0x4(%esp)
    2716:	00 
    2717:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    271e:	e8 d4 16 00 00       	call   3df7 <printf>
    exit();
    2723:	e8 10 15 00 00       	call   3c38 <exit>
  }
  unlink("bigfile");
    2728:	c7 04 24 25 4f 00 00 	movl   $0x4f25,(%esp)
    272f:	e8 54 15 00 00       	call   3c88 <unlink>

  printf(1, "bigfile test ok\n");
    2734:	c7 44 24 04 ca 4f 00 	movl   $0x4fca,0x4(%esp)
    273b:	00 
    273c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2743:	e8 af 16 00 00       	call   3df7 <printf>
}
    2748:	c9                   	leave  
    2749:	c3                   	ret    

0000274a <fourteen>:

void
fourteen(void)
{
    274a:	55                   	push   %ebp
    274b:	89 e5                	mov    %esp,%ebp
    274d:	83 ec 28             	sub    $0x28,%esp
  int fd;

  // DIRSIZ is 14.
  printf(1, "fourteen test\n");
    2750:	c7 44 24 04 db 4f 00 	movl   $0x4fdb,0x4(%esp)
    2757:	00 
    2758:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    275f:	e8 93 16 00 00       	call   3df7 <printf>

  if(mkdir("12345678901234") != 0){
    2764:	c7 04 24 ea 4f 00 00 	movl   $0x4fea,(%esp)
    276b:	e8 30 15 00 00       	call   3ca0 <mkdir>
    2770:	85 c0                	test   %eax,%eax
    2772:	74 19                	je     278d <fourteen+0x43>
    printf(1, "mkdir 12345678901234 failed\n");
    2774:	c7 44 24 04 f9 4f 00 	movl   $0x4ff9,0x4(%esp)
    277b:	00 
    277c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2783:	e8 6f 16 00 00       	call   3df7 <printf>
    exit();
    2788:	e8 ab 14 00 00       	call   3c38 <exit>
  }
  if(mkdir("12345678901234/123456789012345") != 0){
    278d:	c7 04 24 18 50 00 00 	movl   $0x5018,(%esp)
    2794:	e8 07 15 00 00       	call   3ca0 <mkdir>
    2799:	85 c0                	test   %eax,%eax
    279b:	74 19                	je     27b6 <fourteen+0x6c>
    printf(1, "mkdir 12345678901234/123456789012345 failed\n");
    279d:	c7 44 24 04 38 50 00 	movl   $0x5038,0x4(%esp)
    27a4:	00 
    27a5:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    27ac:	e8 46 16 00 00       	call   3df7 <printf>
    exit();
    27b1:	e8 82 14 00 00       	call   3c38 <exit>
  }
  fd = open("123456789012345/123456789012345/123456789012345", O_CREATE);
    27b6:	c7 44 24 04 00 02 00 	movl   $0x200,0x4(%esp)
    27bd:	00 
    27be:	c7 04 24 68 50 00 00 	movl   $0x5068,(%esp)
    27c5:	e8 ae 14 00 00       	call   3c78 <open>
    27ca:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(fd < 0){
    27cd:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
    27d1:	79 19                	jns    27ec <fourteen+0xa2>
    printf(1, "create 123456789012345/123456789012345/123456789012345 failed\n");
    27d3:	c7 44 24 04 98 50 00 	movl   $0x5098,0x4(%esp)
    27da:	00 
    27db:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    27e2:	e8 10 16 00 00       	call   3df7 <printf>
    exit();
    27e7:	e8 4c 14 00 00       	call   3c38 <exit>
  }
  close(fd);
    27ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
    27ef:	89 04 24             	mov    %eax,(%esp)
    27f2:	e8 69 14 00 00       	call   3c60 <close>
  fd = open("12345678901234/12345678901234/12345678901234", 0);
    27f7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
    27fe:	00 
    27ff:	c7 04 24 d8 50 00 00 	movl   $0x50d8,(%esp)
    2806:	e8 6d 14 00 00       	call   3c78 <open>
    280b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(fd < 0){
    280e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
    2812:	79 19                	jns    282d <fourteen+0xe3>
    printf(1, "open 12345678901234/12345678901234/12345678901234 failed\n");
    2814:	c7 44 24 04 08 51 00 	movl   $0x5108,0x4(%esp)
    281b:	00 
    281c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2823:	e8 cf 15 00 00       	call   3df7 <printf>
    exit();
    2828:	e8 0b 14 00 00       	call   3c38 <exit>
  }
  close(fd);
    282d:	8b 45 f4             	mov    -0xc(%ebp),%eax
    2830:	89 04 24             	mov    %eax,(%esp)
    2833:	e8 28 14 00 00       	call   3c60 <close>

  if(mkdir("12345678901234/12345678901234") == 0){
    2838:	c7 04 24 42 51 00 00 	movl   $0x5142,(%esp)
    283f:	e8 5c 14 00 00       	call   3ca0 <mkdir>
    2844:	85 c0                	test   %eax,%eax
    2846:	75 19                	jne    2861 <fourteen+0x117>
    printf(1, "mkdir 12345678901234/12345678901234 succeeded!\n");
    2848:	c7 44 24 04 60 51 00 	movl   $0x5160,0x4(%esp)
    284f:	00 
    2850:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2857:	e8 9b 15 00 00       	call   3df7 <printf>
    exit();
    285c:	e8 d7 13 00 00       	call   3c38 <exit>
  }
  if(mkdir("123456789012345/12345678901234") == 0){
    2861:	c7 04 24 90 51 00 00 	movl   $0x5190,(%esp)
    2868:	e8 33 14 00 00       	call   3ca0 <mkdir>
    286d:	85 c0                	test   %eax,%eax
    286f:	75 19                	jne    288a <fourteen+0x140>
    printf(1, "mkdir 12345678901234/123456789012345 succeeded!\n");
    2871:	c7 44 24 04 b0 51 00 	movl   $0x51b0,0x4(%esp)
    2878:	00 
    2879:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2880:	e8 72 15 00 00       	call   3df7 <printf>
    exit();
    2885:	e8 ae 13 00 00       	call   3c38 <exit>
  }

  printf(1, "fourteen ok\n");
    288a:	c7 44 24 04 e1 51 00 	movl   $0x51e1,0x4(%esp)
    2891:	00 
    2892:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2899:	e8 59 15 00 00       	call   3df7 <printf>
}
    289e:	c9                   	leave  
    289f:	c3                   	ret    

000028a0 <rmdot>:

void
rmdot(void)
{
    28a0:	55                   	push   %ebp
    28a1:	89 e5                	mov    %esp,%ebp
    28a3:	83 ec 18             	sub    $0x18,%esp
  printf(1, "rmdot test\n");
    28a6:	c7 44 24 04 ee 51 00 	movl   $0x51ee,0x4(%esp)
    28ad:	00 
    28ae:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    28b5:	e8 3d 15 00 00       	call   3df7 <printf>
  if(mkdir("dots") != 0){
    28ba:	c7 04 24 fa 51 00 00 	movl   $0x51fa,(%esp)
    28c1:	e8 da 13 00 00       	call   3ca0 <mkdir>
    28c6:	85 c0                	test   %eax,%eax
    28c8:	74 19                	je     28e3 <rmdot+0x43>
    printf(1, "mkdir dots failed\n");
    28ca:	c7 44 24 04 ff 51 00 	movl   $0x51ff,0x4(%esp)
    28d1:	00 
    28d2:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    28d9:	e8 19 15 00 00       	call   3df7 <printf>
    exit();
    28de:	e8 55 13 00 00       	call   3c38 <exit>
  }
  if(chdir("dots") != 0){
    28e3:	c7 04 24 fa 51 00 00 	movl   $0x51fa,(%esp)
    28ea:	e8 b9 13 00 00       	call   3ca8 <chdir>
    28ef:	85 c0                	test   %eax,%eax
    28f1:	74 19                	je     290c <rmdot+0x6c>
    printf(1, "chdir dots failed\n");
    28f3:	c7 44 24 04 12 52 00 	movl   $0x5212,0x4(%esp)
    28fa:	00 
    28fb:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2902:	e8 f0 14 00 00       	call   3df7 <printf>
    exit();
    2907:	e8 2c 13 00 00       	call   3c38 <exit>
  }
  if(unlink(".") == 0){
    290c:	c7 04 24 2b 49 00 00 	movl   $0x492b,(%esp)
    2913:	e8 70 13 00 00       	call   3c88 <unlink>
    2918:	85 c0                	test   %eax,%eax
    291a:	75 19                	jne    2935 <rmdot+0x95>
    printf(1, "rm . worked!\n");
    291c:	c7 44 24 04 25 52 00 	movl   $0x5225,0x4(%esp)
    2923:	00 
    2924:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    292b:	e8 c7 14 00 00       	call   3df7 <printf>
    exit();
    2930:	e8 03 13 00 00       	call   3c38 <exit>
  }
  if(unlink("..") == 0){
    2935:	c7 04 24 b8 44 00 00 	movl   $0x44b8,(%esp)
    293c:	e8 47 13 00 00       	call   3c88 <unlink>
    2941:	85 c0                	test   %eax,%eax
    2943:	75 19                	jne    295e <rmdot+0xbe>
    printf(1, "rm .. worked!\n");
    2945:	c7 44 24 04 33 52 00 	movl   $0x5233,0x4(%esp)
    294c:	00 
    294d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2954:	e8 9e 14 00 00       	call   3df7 <printf>
    exit();
    2959:	e8 da 12 00 00       	call   3c38 <exit>
  }
  if(chdir("/") != 0){
    295e:	c7 04 24 42 52 00 00 	movl   $0x5242,(%esp)
    2965:	e8 3e 13 00 00       	call   3ca8 <chdir>
    296a:	85 c0                	test   %eax,%eax
    296c:	74 19                	je     2987 <rmdot+0xe7>
    printf(1, "chdir / failed\n");
    296e:	c7 44 24 04 44 52 00 	movl   $0x5244,0x4(%esp)
    2975:	00 
    2976:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    297d:	e8 75 14 00 00       	call   3df7 <printf>
    exit();
    2982:	e8 b1 12 00 00       	call   3c38 <exit>
  }
  if(unlink("dots/.") == 0){
    2987:	c7 04 24 54 52 00 00 	movl   $0x5254,(%esp)
    298e:	e8 f5 12 00 00       	call   3c88 <unlink>
    2993:	85 c0                	test   %eax,%eax
    2995:	75 19                	jne    29b0 <rmdot+0x110>
    printf(1, "unlink dots/. worked!\n");
    2997:	c7 44 24 04 5b 52 00 	movl   $0x525b,0x4(%esp)
    299e:	00 
    299f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    29a6:	e8 4c 14 00 00       	call   3df7 <printf>
    exit();
    29ab:	e8 88 12 00 00       	call   3c38 <exit>
  }
  if(unlink("dots/..") == 0){
    29b0:	c7 04 24 72 52 00 00 	movl   $0x5272,(%esp)
    29b7:	e8 cc 12 00 00       	call   3c88 <unlink>
    29bc:	85 c0                	test   %eax,%eax
    29be:	75 19                	jne    29d9 <rmdot+0x139>
    printf(1, "unlink dots/.. worked!\n");
    29c0:	c7 44 24 04 7a 52 00 	movl   $0x527a,0x4(%esp)
    29c7:	00 
    29c8:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    29cf:	e8 23 14 00 00       	call   3df7 <printf>
    exit();
    29d4:	e8 5f 12 00 00       	call   3c38 <exit>
  }
  if(unlink("dots") != 0){
    29d9:	c7 04 24 fa 51 00 00 	movl   $0x51fa,(%esp)
    29e0:	e8 a3 12 00 00       	call   3c88 <unlink>
    29e5:	85 c0                	test   %eax,%eax
    29e7:	74 19                	je     2a02 <rmdot+0x162>
    printf(1, "unlink dots failed!\n");
    29e9:	c7 44 24 04 92 52 00 	movl   $0x5292,0x4(%esp)
    29f0:	00 
    29f1:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    29f8:	e8 fa 13 00 00       	call   3df7 <printf>
    exit();
    29fd:	e8 36 12 00 00       	call   3c38 <exit>
  }
  printf(1, "rmdot ok\n");
    2a02:	c7 44 24 04 a7 52 00 	movl   $0x52a7,0x4(%esp)
    2a09:	00 
    2a0a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2a11:	e8 e1 13 00 00       	call   3df7 <printf>
}
    2a16:	c9                   	leave  
    2a17:	c3                   	ret    

00002a18 <dirfile>:

void
dirfile(void)
{
    2a18:	55                   	push   %ebp
    2a19:	89 e5                	mov    %esp,%ebp
    2a1b:	83 ec 28             	sub    $0x28,%esp
  int fd;

  printf(1, "dir vs file\n");
    2a1e:	c7 44 24 04 b1 52 00 	movl   $0x52b1,0x4(%esp)
    2a25:	00 
    2a26:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2a2d:	e8 c5 13 00 00       	call   3df7 <printf>

  fd = open("dirfile", O_CREATE);
    2a32:	c7 44 24 04 00 02 00 	movl   $0x200,0x4(%esp)
    2a39:	00 
    2a3a:	c7 04 24 be 52 00 00 	movl   $0x52be,(%esp)
    2a41:	e8 32 12 00 00       	call   3c78 <open>
    2a46:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(fd < 0){
    2a49:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
    2a4d:	79 19                	jns    2a68 <dirfile+0x50>
    printf(1, "create dirfile failed\n");
    2a4f:	c7 44 24 04 c6 52 00 	movl   $0x52c6,0x4(%esp)
    2a56:	00 
    2a57:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2a5e:	e8 94 13 00 00       	call   3df7 <printf>
    exit();
    2a63:	e8 d0 11 00 00       	call   3c38 <exit>
  }
  close(fd);
    2a68:	8b 45 f4             	mov    -0xc(%ebp),%eax
    2a6b:	89 04 24             	mov    %eax,(%esp)
    2a6e:	e8 ed 11 00 00       	call   3c60 <close>
  if(chdir("dirfile") == 0){
    2a73:	c7 04 24 be 52 00 00 	movl   $0x52be,(%esp)
    2a7a:	e8 29 12 00 00       	call   3ca8 <chdir>
    2a7f:	85 c0                	test   %eax,%eax
    2a81:	75 19                	jne    2a9c <dirfile+0x84>
    printf(1, "chdir dirfile succeeded!\n");
    2a83:	c7 44 24 04 dd 52 00 	movl   $0x52dd,0x4(%esp)
    2a8a:	00 
    2a8b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2a92:	e8 60 13 00 00       	call   3df7 <printf>
    exit();
    2a97:	e8 9c 11 00 00       	call   3c38 <exit>
  }
  fd = open("dirfile/xx", 0);
    2a9c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
    2aa3:	00 
    2aa4:	c7 04 24 f7 52 00 00 	movl   $0x52f7,(%esp)
    2aab:	e8 c8 11 00 00       	call   3c78 <open>
    2ab0:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(fd >= 0){
    2ab3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
    2ab7:	78 19                	js     2ad2 <dirfile+0xba>
    printf(1, "create dirfile/xx succeeded!\n");
    2ab9:	c7 44 24 04 02 53 00 	movl   $0x5302,0x4(%esp)
    2ac0:	00 
    2ac1:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2ac8:	e8 2a 13 00 00       	call   3df7 <printf>
    exit();
    2acd:	e8 66 11 00 00       	call   3c38 <exit>
  }
  fd = open("dirfile/xx", O_CREATE);
    2ad2:	c7 44 24 04 00 02 00 	movl   $0x200,0x4(%esp)
    2ad9:	00 
    2ada:	c7 04 24 f7 52 00 00 	movl   $0x52f7,(%esp)
    2ae1:	e8 92 11 00 00       	call   3c78 <open>
    2ae6:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(fd >= 0){
    2ae9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
    2aed:	78 19                	js     2b08 <dirfile+0xf0>
    printf(1, "create dirfile/xx succeeded!\n");
    2aef:	c7 44 24 04 02 53 00 	movl   $0x5302,0x4(%esp)
    2af6:	00 
    2af7:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2afe:	e8 f4 12 00 00       	call   3df7 <printf>
    exit();
    2b03:	e8 30 11 00 00       	call   3c38 <exit>
  }
  if(mkdir("dirfile/xx") == 0){
    2b08:	c7 04 24 f7 52 00 00 	movl   $0x52f7,(%esp)
    2b0f:	e8 8c 11 00 00       	call   3ca0 <mkdir>
    2b14:	85 c0                	test   %eax,%eax
    2b16:	75 19                	jne    2b31 <dirfile+0x119>
    printf(1, "mkdir dirfile/xx succeeded!\n");
    2b18:	c7 44 24 04 20 53 00 	movl   $0x5320,0x4(%esp)
    2b1f:	00 
    2b20:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2b27:	e8 cb 12 00 00       	call   3df7 <printf>
    exit();
    2b2c:	e8 07 11 00 00       	call   3c38 <exit>
  }
  if(unlink("dirfile/xx") == 0){
    2b31:	c7 04 24 f7 52 00 00 	movl   $0x52f7,(%esp)
    2b38:	e8 4b 11 00 00       	call   3c88 <unlink>
    2b3d:	85 c0                	test   %eax,%eax
    2b3f:	75 19                	jne    2b5a <dirfile+0x142>
    printf(1, "unlink dirfile/xx succeeded!\n");
    2b41:	c7 44 24 04 3d 53 00 	movl   $0x533d,0x4(%esp)
    2b48:	00 
    2b49:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2b50:	e8 a2 12 00 00       	call   3df7 <printf>
    exit();
    2b55:	e8 de 10 00 00       	call   3c38 <exit>
  }
  if(link("README", "dirfile/xx") == 0){
    2b5a:	c7 44 24 04 f7 52 00 	movl   $0x52f7,0x4(%esp)
    2b61:	00 
    2b62:	c7 04 24 5b 53 00 00 	movl   $0x535b,(%esp)
    2b69:	e8 2a 11 00 00       	call   3c98 <link>
    2b6e:	85 c0                	test   %eax,%eax
    2b70:	75 19                	jne    2b8b <dirfile+0x173>
    printf(1, "link to dirfile/xx succeeded!\n");
    2b72:	c7 44 24 04 64 53 00 	movl   $0x5364,0x4(%esp)
    2b79:	00 
    2b7a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2b81:	e8 71 12 00 00       	call   3df7 <printf>
    exit();
    2b86:	e8 ad 10 00 00       	call   3c38 <exit>
  }
  if(unlink("dirfile") != 0){
    2b8b:	c7 04 24 be 52 00 00 	movl   $0x52be,(%esp)
    2b92:	e8 f1 10 00 00       	call   3c88 <unlink>
    2b97:	85 c0                	test   %eax,%eax
    2b99:	74 19                	je     2bb4 <dirfile+0x19c>
    printf(1, "unlink dirfile failed!\n");
    2b9b:	c7 44 24 04 83 53 00 	movl   $0x5383,0x4(%esp)
    2ba2:	00 
    2ba3:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2baa:	e8 48 12 00 00       	call   3df7 <printf>
    exit();
    2baf:	e8 84 10 00 00       	call   3c38 <exit>
  }

  fd = open(".", O_RDWR);
    2bb4:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
    2bbb:	00 
    2bbc:	c7 04 24 2b 49 00 00 	movl   $0x492b,(%esp)
    2bc3:	e8 b0 10 00 00       	call   3c78 <open>
    2bc8:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(fd >= 0){
    2bcb:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
    2bcf:	78 19                	js     2bea <dirfile+0x1d2>
    printf(1, "open . for writing succeeded!\n");
    2bd1:	c7 44 24 04 9c 53 00 	movl   $0x539c,0x4(%esp)
    2bd8:	00 
    2bd9:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2be0:	e8 12 12 00 00       	call   3df7 <printf>
    exit();
    2be5:	e8 4e 10 00 00       	call   3c38 <exit>
  }
  fd = open(".", 0);
    2bea:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
    2bf1:	00 
    2bf2:	c7 04 24 2b 49 00 00 	movl   $0x492b,(%esp)
    2bf9:	e8 7a 10 00 00       	call   3c78 <open>
    2bfe:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(write(fd, "x", 1) > 0){
    2c01:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
    2c08:	00 
    2c09:	c7 44 24 04 62 45 00 	movl   $0x4562,0x4(%esp)
    2c10:	00 
    2c11:	8b 45 f4             	mov    -0xc(%ebp),%eax
    2c14:	89 04 24             	mov    %eax,(%esp)
    2c17:	e8 3c 10 00 00       	call   3c58 <write>
    2c1c:	85 c0                	test   %eax,%eax
    2c1e:	7e 19                	jle    2c39 <dirfile+0x221>
    printf(1, "write . succeeded!\n");
    2c20:	c7 44 24 04 bb 53 00 	movl   $0x53bb,0x4(%esp)
    2c27:	00 
    2c28:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2c2f:	e8 c3 11 00 00       	call   3df7 <printf>
    exit();
    2c34:	e8 ff 0f 00 00       	call   3c38 <exit>
  }
  close(fd);
    2c39:	8b 45 f4             	mov    -0xc(%ebp),%eax
    2c3c:	89 04 24             	mov    %eax,(%esp)
    2c3f:	e8 1c 10 00 00       	call   3c60 <close>

  printf(1, "dir vs file OK\n");
    2c44:	c7 44 24 04 cf 53 00 	movl   $0x53cf,0x4(%esp)
    2c4b:	00 
    2c4c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2c53:	e8 9f 11 00 00       	call   3df7 <printf>
}
    2c58:	c9                   	leave  
    2c59:	c3                   	ret    

00002c5a <iref>:

// test that iput() is called at the end of _namei()
void
iref(void)
{
    2c5a:	55                   	push   %ebp
    2c5b:	89 e5                	mov    %esp,%ebp
    2c5d:	83 ec 28             	sub    $0x28,%esp
  int i, fd;

  printf(1, "empty file name\n");
    2c60:	c7 44 24 04 df 53 00 	movl   $0x53df,0x4(%esp)
    2c67:	00 
    2c68:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2c6f:	e8 83 11 00 00       	call   3df7 <printf>

  // the 50 is NINODE
  for(i = 0; i < 50 + 1; i++){
    2c74:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    2c7b:	e9 d2 00 00 00       	jmp    2d52 <iref+0xf8>
    if(mkdir("irefd") != 0){
    2c80:	c7 04 24 f0 53 00 00 	movl   $0x53f0,(%esp)
    2c87:	e8 14 10 00 00       	call   3ca0 <mkdir>
    2c8c:	85 c0                	test   %eax,%eax
    2c8e:	74 19                	je     2ca9 <iref+0x4f>
      printf(1, "mkdir irefd failed\n");
    2c90:	c7 44 24 04 f6 53 00 	movl   $0x53f6,0x4(%esp)
    2c97:	00 
    2c98:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2c9f:	e8 53 11 00 00       	call   3df7 <printf>
      exit();
    2ca4:	e8 8f 0f 00 00       	call   3c38 <exit>
    }
    if(chdir("irefd") != 0){
    2ca9:	c7 04 24 f0 53 00 00 	movl   $0x53f0,(%esp)
    2cb0:	e8 f3 0f 00 00       	call   3ca8 <chdir>
    2cb5:	85 c0                	test   %eax,%eax
    2cb7:	74 19                	je     2cd2 <iref+0x78>
      printf(1, "chdir irefd failed\n");
    2cb9:	c7 44 24 04 0a 54 00 	movl   $0x540a,0x4(%esp)
    2cc0:	00 
    2cc1:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2cc8:	e8 2a 11 00 00       	call   3df7 <printf>
      exit();
    2ccd:	e8 66 0f 00 00       	call   3c38 <exit>
    }

    mkdir("");
    2cd2:	c7 04 24 1e 54 00 00 	movl   $0x541e,(%esp)
    2cd9:	e8 c2 0f 00 00       	call   3ca0 <mkdir>
    link("README", "");
    2cde:	c7 44 24 04 1e 54 00 	movl   $0x541e,0x4(%esp)
    2ce5:	00 
    2ce6:	c7 04 24 5b 53 00 00 	movl   $0x535b,(%esp)
    2ced:	e8 a6 0f 00 00       	call   3c98 <link>
    fd = open("", O_CREATE);
    2cf2:	c7 44 24 04 00 02 00 	movl   $0x200,0x4(%esp)
    2cf9:	00 
    2cfa:	c7 04 24 1e 54 00 00 	movl   $0x541e,(%esp)
    2d01:	e8 72 0f 00 00       	call   3c78 <open>
    2d06:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(fd >= 0)
    2d09:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
    2d0d:	78 0b                	js     2d1a <iref+0xc0>
      close(fd);
    2d0f:	8b 45 f0             	mov    -0x10(%ebp),%eax
    2d12:	89 04 24             	mov    %eax,(%esp)
    2d15:	e8 46 0f 00 00       	call   3c60 <close>
    fd = open("xx", O_CREATE);
    2d1a:	c7 44 24 04 00 02 00 	movl   $0x200,0x4(%esp)
    2d21:	00 
    2d22:	c7 04 24 1f 54 00 00 	movl   $0x541f,(%esp)
    2d29:	e8 4a 0f 00 00       	call   3c78 <open>
    2d2e:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(fd >= 0)
    2d31:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
    2d35:	78 0b                	js     2d42 <iref+0xe8>
      close(fd);
    2d37:	8b 45 f0             	mov    -0x10(%ebp),%eax
    2d3a:	89 04 24             	mov    %eax,(%esp)
    2d3d:	e8 1e 0f 00 00       	call   3c60 <close>
    unlink("xx");
    2d42:	c7 04 24 1f 54 00 00 	movl   $0x541f,(%esp)
    2d49:	e8 3a 0f 00 00       	call   3c88 <unlink>
  int i, fd;

  printf(1, "empty file name\n");

  // the 50 is NINODE
  for(i = 0; i < 50 + 1; i++){
    2d4e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
    2d52:	83 7d f4 32          	cmpl   $0x32,-0xc(%ebp)
    2d56:	0f 8e 24 ff ff ff    	jle    2c80 <iref+0x26>
    if(fd >= 0)
      close(fd);
    unlink("xx");
  }

  chdir("/");
    2d5c:	c7 04 24 42 52 00 00 	movl   $0x5242,(%esp)
    2d63:	e8 40 0f 00 00       	call   3ca8 <chdir>
  printf(1, "empty file name OK\n");
    2d68:	c7 44 24 04 22 54 00 	movl   $0x5422,0x4(%esp)
    2d6f:	00 
    2d70:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2d77:	e8 7b 10 00 00       	call   3df7 <printf>
}
    2d7c:	c9                   	leave  
    2d7d:	c3                   	ret    

00002d7e <forktest>:
// test that fork fails gracefully
// the forktest binary also does this, but it runs out of proc entries first.
// inside the bigger usertests binary, we run out of memory first.
void
forktest(void)
{
    2d7e:	55                   	push   %ebp
    2d7f:	89 e5                	mov    %esp,%ebp
    2d81:	83 ec 28             	sub    $0x28,%esp
  int n, pid;

  printf(1, "fork test\n");
    2d84:	c7 44 24 04 36 54 00 	movl   $0x5436,0x4(%esp)
    2d8b:	00 
    2d8c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2d93:	e8 5f 10 00 00       	call   3df7 <printf>

  for(n=0; n<1000; n++){
    2d98:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    2d9f:	eb 1d                	jmp    2dbe <forktest+0x40>
    pid = fork();
    2da1:	e8 8a 0e 00 00       	call   3c30 <fork>
    2da6:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(pid < 0)
    2da9:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
    2dad:	78 1a                	js     2dc9 <forktest+0x4b>
      break;
    if(pid == 0)
    2daf:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
    2db3:	75 05                	jne    2dba <forktest+0x3c>
      exit();
    2db5:	e8 7e 0e 00 00       	call   3c38 <exit>
{
  int n, pid;

  printf(1, "fork test\n");

  for(n=0; n<1000; n++){
    2dba:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
    2dbe:	81 7d f4 e7 03 00 00 	cmpl   $0x3e7,-0xc(%ebp)
    2dc5:	7e da                	jle    2da1 <forktest+0x23>
    2dc7:	eb 01                	jmp    2dca <forktest+0x4c>
    pid = fork();
    if(pid < 0)
      break;
    2dc9:	90                   	nop
    if(pid == 0)
      exit();
  }
  
  if(n == 1000){
    2dca:	81 7d f4 e8 03 00 00 	cmpl   $0x3e8,-0xc(%ebp)
    2dd1:	75 3f                	jne    2e12 <forktest+0x94>
    printf(1, "fork claimed to work 1000 times!\n");
    2dd3:	c7 44 24 04 44 54 00 	movl   $0x5444,0x4(%esp)
    2dda:	00 
    2ddb:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2de2:	e8 10 10 00 00       	call   3df7 <printf>
    exit();
    2de7:	e8 4c 0e 00 00       	call   3c38 <exit>
  }
  
  for(; n > 0; n--){
    if(wait() < 0){
    2dec:	e8 4f 0e 00 00       	call   3c40 <wait>
    2df1:	85 c0                	test   %eax,%eax
    2df3:	79 19                	jns    2e0e <forktest+0x90>
      printf(1, "wait stopped early\n");
    2df5:	c7 44 24 04 66 54 00 	movl   $0x5466,0x4(%esp)
    2dfc:	00 
    2dfd:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2e04:	e8 ee 0f 00 00       	call   3df7 <printf>
      exit();
    2e09:	e8 2a 0e 00 00       	call   3c38 <exit>
  if(n == 1000){
    printf(1, "fork claimed to work 1000 times!\n");
    exit();
  }
  
  for(; n > 0; n--){
    2e0e:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
    2e12:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
    2e16:	7f d4                	jg     2dec <forktest+0x6e>
      printf(1, "wait stopped early\n");
      exit();
    }
  }
  
  if(wait() != -1){
    2e18:	e8 23 0e 00 00       	call   3c40 <wait>
    2e1d:	83 f8 ff             	cmp    $0xffffffff,%eax
    2e20:	74 19                	je     2e3b <forktest+0xbd>
    printf(1, "wait got too many\n");
    2e22:	c7 44 24 04 7a 54 00 	movl   $0x547a,0x4(%esp)
    2e29:	00 
    2e2a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2e31:	e8 c1 0f 00 00       	call   3df7 <printf>
    exit();
    2e36:	e8 fd 0d 00 00       	call   3c38 <exit>
  }
  
  printf(1, "fork test OK\n");
    2e3b:	c7 44 24 04 8d 54 00 	movl   $0x548d,0x4(%esp)
    2e42:	00 
    2e43:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2e4a:	e8 a8 0f 00 00       	call   3df7 <printf>
}
    2e4f:	c9                   	leave  
    2e50:	c3                   	ret    

00002e51 <sbrktest>:

void
sbrktest(void)
{
    2e51:	55                   	push   %ebp
    2e52:	89 e5                	mov    %esp,%ebp
    2e54:	53                   	push   %ebx
    2e55:	81 ec 84 00 00 00    	sub    $0x84,%esp
  int fds[2], pid, pids[10], ppid;
  char *a, *b, *c, *lastaddr, *oldbrk, *p, scratch;
  uint amt;

  printf(stdout, "sbrk test\n");
    2e5b:	a1 14 5f 00 00       	mov    0x5f14,%eax
    2e60:	c7 44 24 04 9b 54 00 	movl   $0x549b,0x4(%esp)
    2e67:	00 
    2e68:	89 04 24             	mov    %eax,(%esp)
    2e6b:	e8 87 0f 00 00       	call   3df7 <printf>
  oldbrk = sbrk(0);
    2e70:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
    2e77:	e8 44 0e 00 00       	call   3cc0 <sbrk>
    2e7c:	89 45 ec             	mov    %eax,-0x14(%ebp)

  // can one sbrk() less than a page?
  a = sbrk(0);
    2e7f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
    2e86:	e8 35 0e 00 00       	call   3cc0 <sbrk>
    2e8b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  int i;
  for(i = 0; i < 5000; i++){ 
    2e8e:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    2e95:	eb 59                	jmp    2ef0 <sbrktest+0x9f>
    b = sbrk(1);
    2e97:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2e9e:	e8 1d 0e 00 00       	call   3cc0 <sbrk>
    2ea3:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(b != a){
    2ea6:	8b 45 e8             	mov    -0x18(%ebp),%eax
    2ea9:	3b 45 f4             	cmp    -0xc(%ebp),%eax
    2eac:	74 2f                	je     2edd <sbrktest+0x8c>
      printf(stdout, "sbrk test failed %d %x %x\n", i, a, b);
    2eae:	a1 14 5f 00 00       	mov    0x5f14,%eax
    2eb3:	8b 55 e8             	mov    -0x18(%ebp),%edx
    2eb6:	89 54 24 10          	mov    %edx,0x10(%esp)
    2eba:	8b 55 f4             	mov    -0xc(%ebp),%edx
    2ebd:	89 54 24 0c          	mov    %edx,0xc(%esp)
    2ec1:	8b 55 f0             	mov    -0x10(%ebp),%edx
    2ec4:	89 54 24 08          	mov    %edx,0x8(%esp)
    2ec8:	c7 44 24 04 a6 54 00 	movl   $0x54a6,0x4(%esp)
    2ecf:	00 
    2ed0:	89 04 24             	mov    %eax,(%esp)
    2ed3:	e8 1f 0f 00 00       	call   3df7 <printf>
      exit();
    2ed8:	e8 5b 0d 00 00       	call   3c38 <exit>
    }
    *b = 1;
    2edd:	8b 45 e8             	mov    -0x18(%ebp),%eax
    2ee0:	c6 00 01             	movb   $0x1,(%eax)
    a = b + 1;
    2ee3:	8b 45 e8             	mov    -0x18(%ebp),%eax
    2ee6:	83 c0 01             	add    $0x1,%eax
    2ee9:	89 45 f4             	mov    %eax,-0xc(%ebp)
  oldbrk = sbrk(0);

  // can one sbrk() less than a page?
  a = sbrk(0);
  int i;
  for(i = 0; i < 5000; i++){ 
    2eec:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
    2ef0:	81 7d f0 87 13 00 00 	cmpl   $0x1387,-0x10(%ebp)
    2ef7:	7e 9e                	jle    2e97 <sbrktest+0x46>
      exit();
    }
    *b = 1;
    a = b + 1;
  }
  pid = fork();
    2ef9:	e8 32 0d 00 00       	call   3c30 <fork>
    2efe:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  if(pid < 0){
    2f01:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
    2f05:	79 1a                	jns    2f21 <sbrktest+0xd0>
    printf(stdout, "sbrk test fork failed\n");
    2f07:	a1 14 5f 00 00       	mov    0x5f14,%eax
    2f0c:	c7 44 24 04 c1 54 00 	movl   $0x54c1,0x4(%esp)
    2f13:	00 
    2f14:	89 04 24             	mov    %eax,(%esp)
    2f17:	e8 db 0e 00 00       	call   3df7 <printf>
    exit();
    2f1c:	e8 17 0d 00 00       	call   3c38 <exit>
  }
  c = sbrk(1);
    2f21:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2f28:	e8 93 0d 00 00       	call   3cc0 <sbrk>
    2f2d:	89 45 e0             	mov    %eax,-0x20(%ebp)
  c = sbrk(1);
    2f30:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    2f37:	e8 84 0d 00 00       	call   3cc0 <sbrk>
    2f3c:	89 45 e0             	mov    %eax,-0x20(%ebp)
  if(c != a + 1){
    2f3f:	8b 45 f4             	mov    -0xc(%ebp),%eax
    2f42:	83 c0 01             	add    $0x1,%eax
    2f45:	3b 45 e0             	cmp    -0x20(%ebp),%eax
    2f48:	74 1a                	je     2f64 <sbrktest+0x113>
    printf(stdout, "sbrk test failed post-fork\n");
    2f4a:	a1 14 5f 00 00       	mov    0x5f14,%eax
    2f4f:	c7 44 24 04 d8 54 00 	movl   $0x54d8,0x4(%esp)
    2f56:	00 
    2f57:	89 04 24             	mov    %eax,(%esp)
    2f5a:	e8 98 0e 00 00       	call   3df7 <printf>
    exit();
    2f5f:	e8 d4 0c 00 00       	call   3c38 <exit>
  }
  if(pid == 0)
    2f64:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
    2f68:	75 05                	jne    2f6f <sbrktest+0x11e>
    exit();
    2f6a:	e8 c9 0c 00 00       	call   3c38 <exit>
  wait();
    2f6f:	e8 cc 0c 00 00       	call   3c40 <wait>

  // can one grow address space to something big?
#define BIG (100*1024*1024)
  a = sbrk(0);
    2f74:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
    2f7b:	e8 40 0d 00 00       	call   3cc0 <sbrk>
    2f80:	89 45 f4             	mov    %eax,-0xc(%ebp)
  amt = (BIG) - (uint)a;
    2f83:	8b 45 f4             	mov    -0xc(%ebp),%eax
    2f86:	ba 00 00 40 06       	mov    $0x6400000,%edx
    2f8b:	89 d1                	mov    %edx,%ecx
    2f8d:	29 c1                	sub    %eax,%ecx
    2f8f:	89 c8                	mov    %ecx,%eax
    2f91:	89 45 dc             	mov    %eax,-0x24(%ebp)
  p = sbrk(amt);
    2f94:	8b 45 dc             	mov    -0x24(%ebp),%eax
    2f97:	89 04 24             	mov    %eax,(%esp)
    2f9a:	e8 21 0d 00 00       	call   3cc0 <sbrk>
    2f9f:	89 45 d8             	mov    %eax,-0x28(%ebp)
  if (p != a) { 
    2fa2:	8b 45 d8             	mov    -0x28(%ebp),%eax
    2fa5:	3b 45 f4             	cmp    -0xc(%ebp),%eax
    2fa8:	74 1a                	je     2fc4 <sbrktest+0x173>
    printf(stdout, "sbrk test failed to grow big address space; enough phys mem?\n");
    2faa:	a1 14 5f 00 00       	mov    0x5f14,%eax
    2faf:	c7 44 24 04 f4 54 00 	movl   $0x54f4,0x4(%esp)
    2fb6:	00 
    2fb7:	89 04 24             	mov    %eax,(%esp)
    2fba:	e8 38 0e 00 00       	call   3df7 <printf>
    exit();
    2fbf:	e8 74 0c 00 00       	call   3c38 <exit>
  }
  lastaddr = (char*) (BIG-1);
    2fc4:	c7 45 d4 ff ff 3f 06 	movl   $0x63fffff,-0x2c(%ebp)
  *lastaddr = 99;
    2fcb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
    2fce:	c6 00 63             	movb   $0x63,(%eax)

  // can one de-allocate?
  a = sbrk(0);
    2fd1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
    2fd8:	e8 e3 0c 00 00       	call   3cc0 <sbrk>
    2fdd:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c = sbrk(-4096);
    2fe0:	c7 04 24 00 f0 ff ff 	movl   $0xfffff000,(%esp)
    2fe7:	e8 d4 0c 00 00       	call   3cc0 <sbrk>
    2fec:	89 45 e0             	mov    %eax,-0x20(%ebp)
  if(c == (char*)0xffffffff){
    2fef:	83 7d e0 ff          	cmpl   $0xffffffff,-0x20(%ebp)
    2ff3:	75 1a                	jne    300f <sbrktest+0x1be>
    printf(stdout, "sbrk could not deallocate\n");
    2ff5:	a1 14 5f 00 00       	mov    0x5f14,%eax
    2ffa:	c7 44 24 04 32 55 00 	movl   $0x5532,0x4(%esp)
    3001:	00 
    3002:	89 04 24             	mov    %eax,(%esp)
    3005:	e8 ed 0d 00 00       	call   3df7 <printf>
    exit();
    300a:	e8 29 0c 00 00       	call   3c38 <exit>
  }
  c = sbrk(0);
    300f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
    3016:	e8 a5 0c 00 00       	call   3cc0 <sbrk>
    301b:	89 45 e0             	mov    %eax,-0x20(%ebp)
  if(c != a - 4096){
    301e:	8b 45 f4             	mov    -0xc(%ebp),%eax
    3021:	2d 00 10 00 00       	sub    $0x1000,%eax
    3026:	3b 45 e0             	cmp    -0x20(%ebp),%eax
    3029:	74 28                	je     3053 <sbrktest+0x202>
    printf(stdout, "sbrk deallocation produced wrong address, a %x c %x\n", a, c);
    302b:	a1 14 5f 00 00       	mov    0x5f14,%eax
    3030:	8b 55 e0             	mov    -0x20(%ebp),%edx
    3033:	89 54 24 0c          	mov    %edx,0xc(%esp)
    3037:	8b 55 f4             	mov    -0xc(%ebp),%edx
    303a:	89 54 24 08          	mov    %edx,0x8(%esp)
    303e:	c7 44 24 04 50 55 00 	movl   $0x5550,0x4(%esp)
    3045:	00 
    3046:	89 04 24             	mov    %eax,(%esp)
    3049:	e8 a9 0d 00 00       	call   3df7 <printf>
    exit();
    304e:	e8 e5 0b 00 00       	call   3c38 <exit>
  }

  // can one re-allocate that page?
  a = sbrk(0);
    3053:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
    305a:	e8 61 0c 00 00       	call   3cc0 <sbrk>
    305f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c = sbrk(4096);
    3062:	c7 04 24 00 10 00 00 	movl   $0x1000,(%esp)
    3069:	e8 52 0c 00 00       	call   3cc0 <sbrk>
    306e:	89 45 e0             	mov    %eax,-0x20(%ebp)
  if(c != a || sbrk(0) != a + 4096){
    3071:	8b 45 e0             	mov    -0x20(%ebp),%eax
    3074:	3b 45 f4             	cmp    -0xc(%ebp),%eax
    3077:	75 19                	jne    3092 <sbrktest+0x241>
    3079:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
    3080:	e8 3b 0c 00 00       	call   3cc0 <sbrk>
    3085:	8b 55 f4             	mov    -0xc(%ebp),%edx
    3088:	81 c2 00 10 00 00    	add    $0x1000,%edx
    308e:	39 d0                	cmp    %edx,%eax
    3090:	74 28                	je     30ba <sbrktest+0x269>
    printf(stdout, "sbrk re-allocation failed, a %x c %x\n", a, c);
    3092:	a1 14 5f 00 00       	mov    0x5f14,%eax
    3097:	8b 55 e0             	mov    -0x20(%ebp),%edx
    309a:	89 54 24 0c          	mov    %edx,0xc(%esp)
    309e:	8b 55 f4             	mov    -0xc(%ebp),%edx
    30a1:	89 54 24 08          	mov    %edx,0x8(%esp)
    30a5:	c7 44 24 04 88 55 00 	movl   $0x5588,0x4(%esp)
    30ac:	00 
    30ad:	89 04 24             	mov    %eax,(%esp)
    30b0:	e8 42 0d 00 00       	call   3df7 <printf>
    exit();
    30b5:	e8 7e 0b 00 00       	call   3c38 <exit>
  }
  if(*lastaddr == 99){
    30ba:	8b 45 d4             	mov    -0x2c(%ebp),%eax
    30bd:	0f b6 00             	movzbl (%eax),%eax
    30c0:	3c 63                	cmp    $0x63,%al
    30c2:	75 1a                	jne    30de <sbrktest+0x28d>
    // should be zero
    printf(stdout, "sbrk de-allocation didn't really deallocate\n");
    30c4:	a1 14 5f 00 00       	mov    0x5f14,%eax
    30c9:	c7 44 24 04 b0 55 00 	movl   $0x55b0,0x4(%esp)
    30d0:	00 
    30d1:	89 04 24             	mov    %eax,(%esp)
    30d4:	e8 1e 0d 00 00       	call   3df7 <printf>
    exit();
    30d9:	e8 5a 0b 00 00       	call   3c38 <exit>
  }

  a = sbrk(0);
    30de:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
    30e5:	e8 d6 0b 00 00       	call   3cc0 <sbrk>
    30ea:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c = sbrk(-(sbrk(0) - oldbrk));
    30ed:	8b 5d ec             	mov    -0x14(%ebp),%ebx
    30f0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
    30f7:	e8 c4 0b 00 00       	call   3cc0 <sbrk>
    30fc:	89 da                	mov    %ebx,%edx
    30fe:	29 c2                	sub    %eax,%edx
    3100:	89 d0                	mov    %edx,%eax
    3102:	89 04 24             	mov    %eax,(%esp)
    3105:	e8 b6 0b 00 00       	call   3cc0 <sbrk>
    310a:	89 45 e0             	mov    %eax,-0x20(%ebp)
  if(c != a){
    310d:	8b 45 e0             	mov    -0x20(%ebp),%eax
    3110:	3b 45 f4             	cmp    -0xc(%ebp),%eax
    3113:	74 28                	je     313d <sbrktest+0x2ec>
    printf(stdout, "sbrk downsize failed, a %x c %x\n", a, c);
    3115:	a1 14 5f 00 00       	mov    0x5f14,%eax
    311a:	8b 55 e0             	mov    -0x20(%ebp),%edx
    311d:	89 54 24 0c          	mov    %edx,0xc(%esp)
    3121:	8b 55 f4             	mov    -0xc(%ebp),%edx
    3124:	89 54 24 08          	mov    %edx,0x8(%esp)
    3128:	c7 44 24 04 e0 55 00 	movl   $0x55e0,0x4(%esp)
    312f:	00 
    3130:	89 04 24             	mov    %eax,(%esp)
    3133:	e8 bf 0c 00 00       	call   3df7 <printf>
    exit();
    3138:	e8 fb 0a 00 00       	call   3c38 <exit>
  }
  
  // can we read the kernel's memory?
  for(a = (char*)(KERNBASE); a < (char*) (KERNBASE+2000000); a += 50000){
    313d:	c7 45 f4 00 00 00 80 	movl   $0x80000000,-0xc(%ebp)
    3144:	eb 7b                	jmp    31c1 <sbrktest+0x370>
    ppid = getpid();
    3146:	e8 6d 0b 00 00       	call   3cb8 <getpid>
    314b:	89 45 d0             	mov    %eax,-0x30(%ebp)
    pid = fork();
    314e:	e8 dd 0a 00 00       	call   3c30 <fork>
    3153:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(pid < 0){
    3156:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
    315a:	79 1a                	jns    3176 <sbrktest+0x325>
      printf(stdout, "fork failed\n");
    315c:	a1 14 5f 00 00       	mov    0x5f14,%eax
    3161:	c7 44 24 04 a9 45 00 	movl   $0x45a9,0x4(%esp)
    3168:	00 
    3169:	89 04 24             	mov    %eax,(%esp)
    316c:	e8 86 0c 00 00       	call   3df7 <printf>
      exit();
    3171:	e8 c2 0a 00 00       	call   3c38 <exit>
    }
    if(pid == 0){
    3176:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
    317a:	75 39                	jne    31b5 <sbrktest+0x364>
      printf(stdout, "oops could read %x = %x\n", a, *a);
    317c:	8b 45 f4             	mov    -0xc(%ebp),%eax
    317f:	0f b6 00             	movzbl (%eax),%eax
    3182:	0f be d0             	movsbl %al,%edx
    3185:	a1 14 5f 00 00       	mov    0x5f14,%eax
    318a:	89 54 24 0c          	mov    %edx,0xc(%esp)
    318e:	8b 55 f4             	mov    -0xc(%ebp),%edx
    3191:	89 54 24 08          	mov    %edx,0x8(%esp)
    3195:	c7 44 24 04 01 56 00 	movl   $0x5601,0x4(%esp)
    319c:	00 
    319d:	89 04 24             	mov    %eax,(%esp)
    31a0:	e8 52 0c 00 00       	call   3df7 <printf>
      kill(ppid);
    31a5:	8b 45 d0             	mov    -0x30(%ebp),%eax
    31a8:	89 04 24             	mov    %eax,(%esp)
    31ab:	e8 b8 0a 00 00       	call   3c68 <kill>
      exit();
    31b0:	e8 83 0a 00 00       	call   3c38 <exit>
    }
    wait();
    31b5:	e8 86 0a 00 00       	call   3c40 <wait>
    printf(stdout, "sbrk downsize failed, a %x c %x\n", a, c);
    exit();
  }
  
  // can we read the kernel's memory?
  for(a = (char*)(KERNBASE); a < (char*) (KERNBASE+2000000); a += 50000){
    31ba:	81 45 f4 50 c3 00 00 	addl   $0xc350,-0xc(%ebp)
    31c1:	81 7d f4 7f 84 1e 80 	cmpl   $0x801e847f,-0xc(%ebp)
    31c8:	0f 86 78 ff ff ff    	jbe    3146 <sbrktest+0x2f5>
    wait();
  }

  // if we run the system out of memory, does it clean up the last
  // failed allocation?
  if(pipe(fds) != 0){
    31ce:	8d 45 c8             	lea    -0x38(%ebp),%eax
    31d1:	89 04 24             	mov    %eax,(%esp)
    31d4:	e8 6f 0a 00 00       	call   3c48 <pipe>
    31d9:	85 c0                	test   %eax,%eax
    31db:	74 19                	je     31f6 <sbrktest+0x3a5>
    printf(1, "pipe() failed\n");
    31dd:	c7 44 24 04 fd 44 00 	movl   $0x44fd,0x4(%esp)
    31e4:	00 
    31e5:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    31ec:	e8 06 0c 00 00       	call   3df7 <printf>
    exit();
    31f1:	e8 42 0a 00 00       	call   3c38 <exit>
  }
  for(i = 0; i < sizeof(pids)/sizeof(pids[0]); i++){
    31f6:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    31fd:	e9 89 00 00 00       	jmp    328b <sbrktest+0x43a>
    if((pids[i] = fork()) == 0){
    3202:	e8 29 0a 00 00       	call   3c30 <fork>
    3207:	8b 55 f0             	mov    -0x10(%ebp),%edx
    320a:	89 44 95 a0          	mov    %eax,-0x60(%ebp,%edx,4)
    320e:	8b 45 f0             	mov    -0x10(%ebp),%eax
    3211:	8b 44 85 a0          	mov    -0x60(%ebp,%eax,4),%eax
    3215:	85 c0                	test   %eax,%eax
    3217:	75 48                	jne    3261 <sbrktest+0x410>
      // allocate a lot of memory
      sbrk(BIG - (uint)sbrk(0));
    3219:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
    3220:	e8 9b 0a 00 00       	call   3cc0 <sbrk>
    3225:	ba 00 00 40 06       	mov    $0x6400000,%edx
    322a:	89 d1                	mov    %edx,%ecx
    322c:	29 c1                	sub    %eax,%ecx
    322e:	89 c8                	mov    %ecx,%eax
    3230:	89 04 24             	mov    %eax,(%esp)
    3233:	e8 88 0a 00 00       	call   3cc0 <sbrk>
      write(fds[1], "x", 1);
    3238:	8b 45 cc             	mov    -0x34(%ebp),%eax
    323b:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
    3242:	00 
    3243:	c7 44 24 04 62 45 00 	movl   $0x4562,0x4(%esp)
    324a:	00 
    324b:	89 04 24             	mov    %eax,(%esp)
    324e:	e8 05 0a 00 00       	call   3c58 <write>
      // sit around until killed
      for(;;) sleep(1000);
    3253:	c7 04 24 e8 03 00 00 	movl   $0x3e8,(%esp)
    325a:	e8 69 0a 00 00       	call   3cc8 <sleep>
    325f:	eb f2                	jmp    3253 <sbrktest+0x402>
    }
    if(pids[i] != -1)
    3261:	8b 45 f0             	mov    -0x10(%ebp),%eax
    3264:	8b 44 85 a0          	mov    -0x60(%ebp,%eax,4),%eax
    3268:	83 f8 ff             	cmp    $0xffffffff,%eax
    326b:	74 1a                	je     3287 <sbrktest+0x436>
      read(fds[0], &scratch, 1);
    326d:	8b 45 c8             	mov    -0x38(%ebp),%eax
    3270:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
    3277:	00 
    3278:	8d 55 9f             	lea    -0x61(%ebp),%edx
    327b:	89 54 24 04          	mov    %edx,0x4(%esp)
    327f:	89 04 24             	mov    %eax,(%esp)
    3282:	e8 c9 09 00 00       	call   3c50 <read>
  // failed allocation?
  if(pipe(fds) != 0){
    printf(1, "pipe() failed\n");
    exit();
  }
  for(i = 0; i < sizeof(pids)/sizeof(pids[0]); i++){
    3287:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
    328b:	8b 45 f0             	mov    -0x10(%ebp),%eax
    328e:	83 f8 09             	cmp    $0x9,%eax
    3291:	0f 86 6b ff ff ff    	jbe    3202 <sbrktest+0x3b1>
    if(pids[i] != -1)
      read(fds[0], &scratch, 1);
  }
  // if those failed allocations freed up the pages they did allocate,
  // we'll be able to allocate here
  c = sbrk(4096);
    3297:	c7 04 24 00 10 00 00 	movl   $0x1000,(%esp)
    329e:	e8 1d 0a 00 00       	call   3cc0 <sbrk>
    32a3:	89 45 e0             	mov    %eax,-0x20(%ebp)
  for(i = 0; i < sizeof(pids)/sizeof(pids[0]); i++){
    32a6:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    32ad:	eb 27                	jmp    32d6 <sbrktest+0x485>
    if(pids[i] == -1)
    32af:	8b 45 f0             	mov    -0x10(%ebp),%eax
    32b2:	8b 44 85 a0          	mov    -0x60(%ebp,%eax,4),%eax
    32b6:	83 f8 ff             	cmp    $0xffffffff,%eax
    32b9:	74 16                	je     32d1 <sbrktest+0x480>
      continue;
    kill(pids[i]);
    32bb:	8b 45 f0             	mov    -0x10(%ebp),%eax
    32be:	8b 44 85 a0          	mov    -0x60(%ebp,%eax,4),%eax
    32c2:	89 04 24             	mov    %eax,(%esp)
    32c5:	e8 9e 09 00 00       	call   3c68 <kill>
    wait();
    32ca:	e8 71 09 00 00       	call   3c40 <wait>
    32cf:	eb 01                	jmp    32d2 <sbrktest+0x481>
  // if those failed allocations freed up the pages they did allocate,
  // we'll be able to allocate here
  c = sbrk(4096);
  for(i = 0; i < sizeof(pids)/sizeof(pids[0]); i++){
    if(pids[i] == -1)
      continue;
    32d1:	90                   	nop
      read(fds[0], &scratch, 1);
  }
  // if those failed allocations freed up the pages they did allocate,
  // we'll be able to allocate here
  c = sbrk(4096);
  for(i = 0; i < sizeof(pids)/sizeof(pids[0]); i++){
    32d2:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
    32d6:	8b 45 f0             	mov    -0x10(%ebp),%eax
    32d9:	83 f8 09             	cmp    $0x9,%eax
    32dc:	76 d1                	jbe    32af <sbrktest+0x45e>
    if(pids[i] == -1)
      continue;
    kill(pids[i]);
    wait();
  }
  if(c == (char*)0xffffffff){
    32de:	83 7d e0 ff          	cmpl   $0xffffffff,-0x20(%ebp)
    32e2:	75 1a                	jne    32fe <sbrktest+0x4ad>
    printf(stdout, "failed sbrk leaked memory\n");
    32e4:	a1 14 5f 00 00       	mov    0x5f14,%eax
    32e9:	c7 44 24 04 1a 56 00 	movl   $0x561a,0x4(%esp)
    32f0:	00 
    32f1:	89 04 24             	mov    %eax,(%esp)
    32f4:	e8 fe 0a 00 00       	call   3df7 <printf>
    exit();
    32f9:	e8 3a 09 00 00       	call   3c38 <exit>
  }

  if(sbrk(0) > oldbrk)
    32fe:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
    3305:	e8 b6 09 00 00       	call   3cc0 <sbrk>
    330a:	3b 45 ec             	cmp    -0x14(%ebp),%eax
    330d:	76 1d                	jbe    332c <sbrktest+0x4db>
    sbrk(-(sbrk(0) - oldbrk));
    330f:	8b 5d ec             	mov    -0x14(%ebp),%ebx
    3312:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
    3319:	e8 a2 09 00 00       	call   3cc0 <sbrk>
    331e:	89 da                	mov    %ebx,%edx
    3320:	29 c2                	sub    %eax,%edx
    3322:	89 d0                	mov    %edx,%eax
    3324:	89 04 24             	mov    %eax,(%esp)
    3327:	e8 94 09 00 00       	call   3cc0 <sbrk>

  printf(stdout, "sbrk test OK\n");
    332c:	a1 14 5f 00 00       	mov    0x5f14,%eax
    3331:	c7 44 24 04 35 56 00 	movl   $0x5635,0x4(%esp)
    3338:	00 
    3339:	89 04 24             	mov    %eax,(%esp)
    333c:	e8 b6 0a 00 00       	call   3df7 <printf>
}
    3341:	81 c4 84 00 00 00    	add    $0x84,%esp
    3347:	5b                   	pop    %ebx
    3348:	5d                   	pop    %ebp
    3349:	c3                   	ret    

0000334a <validateint>:

void
validateint(int *p)
{
    334a:	55                   	push   %ebp
    334b:	89 e5                	mov    %esp,%ebp
    334d:	56                   	push   %esi
    334e:	53                   	push   %ebx
    334f:	83 ec 14             	sub    $0x14,%esp
  int res;
  asm("mov %%esp, %%ebx\n\t"
    3352:	c7 45 e4 0d 00 00 00 	movl   $0xd,-0x1c(%ebp)
    3359:	8b 55 08             	mov    0x8(%ebp),%edx
    335c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
    335f:	89 d1                	mov    %edx,%ecx
    3361:	89 e3                	mov    %esp,%ebx
    3363:	89 cc                	mov    %ecx,%esp
    3365:	cd 40                	int    $0x40
    3367:	89 dc                	mov    %ebx,%esp
    3369:	89 c6                	mov    %eax,%esi
    336b:	89 75 f4             	mov    %esi,-0xc(%ebp)
      "int %2\n\t"
      "mov %%ebx, %%esp" :
      "=a" (res) :
      "a" (SYS_sleep), "n" (T_SYSCALL), "c" (p) :
      "ebx");
}
    336e:	83 c4 14             	add    $0x14,%esp
    3371:	5b                   	pop    %ebx
    3372:	5e                   	pop    %esi
    3373:	5d                   	pop    %ebp
    3374:	c3                   	ret    

00003375 <validatetest>:

void
validatetest(void)
{
    3375:	55                   	push   %ebp
    3376:	89 e5                	mov    %esp,%ebp
    3378:	83 ec 28             	sub    $0x28,%esp
  int hi, pid;
  uint p;

  printf(stdout, "validate test\n");
    337b:	a1 14 5f 00 00       	mov    0x5f14,%eax
    3380:	c7 44 24 04 43 56 00 	movl   $0x5643,0x4(%esp)
    3387:	00 
    3388:	89 04 24             	mov    %eax,(%esp)
    338b:	e8 67 0a 00 00       	call   3df7 <printf>
  hi = 1100*1024;
    3390:	c7 45 f0 00 30 11 00 	movl   $0x113000,-0x10(%ebp)

  for(p = 0; p <= (uint)hi; p += 4096){
    3397:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    339e:	eb 7f                	jmp    341f <validatetest+0xaa>
    if((pid = fork()) == 0){
    33a0:	e8 8b 08 00 00       	call   3c30 <fork>
    33a5:	89 45 ec             	mov    %eax,-0x14(%ebp)
    33a8:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
    33ac:	75 10                	jne    33be <validatetest+0x49>
      // try to crash the kernel by passing in a badly placed integer
      validateint((int*)p);
    33ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
    33b1:	89 04 24             	mov    %eax,(%esp)
    33b4:	e8 91 ff ff ff       	call   334a <validateint>
      exit();
    33b9:	e8 7a 08 00 00       	call   3c38 <exit>
    }
    sleep(0);
    33be:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
    33c5:	e8 fe 08 00 00       	call   3cc8 <sleep>
    sleep(0);
    33ca:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
    33d1:	e8 f2 08 00 00       	call   3cc8 <sleep>
    kill(pid);
    33d6:	8b 45 ec             	mov    -0x14(%ebp),%eax
    33d9:	89 04 24             	mov    %eax,(%esp)
    33dc:	e8 87 08 00 00       	call   3c68 <kill>
    wait();
    33e1:	e8 5a 08 00 00       	call   3c40 <wait>

    // try to crash the kernel by passing in a bad string pointer
    if(link("nosuchfile", (char*)p) != -1){
    33e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
    33e9:	89 44 24 04          	mov    %eax,0x4(%esp)
    33ed:	c7 04 24 52 56 00 00 	movl   $0x5652,(%esp)
    33f4:	e8 9f 08 00 00       	call   3c98 <link>
    33f9:	83 f8 ff             	cmp    $0xffffffff,%eax
    33fc:	74 1a                	je     3418 <validatetest+0xa3>
      printf(stdout, "link should not succeed\n");
    33fe:	a1 14 5f 00 00       	mov    0x5f14,%eax
    3403:	c7 44 24 04 5d 56 00 	movl   $0x565d,0x4(%esp)
    340a:	00 
    340b:	89 04 24             	mov    %eax,(%esp)
    340e:	e8 e4 09 00 00       	call   3df7 <printf>
      exit();
    3413:	e8 20 08 00 00       	call   3c38 <exit>
  uint p;

  printf(stdout, "validate test\n");
  hi = 1100*1024;

  for(p = 0; p <= (uint)hi; p += 4096){
    3418:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    341f:	8b 45 f0             	mov    -0x10(%ebp),%eax
    3422:	3b 45 f4             	cmp    -0xc(%ebp),%eax
    3425:	0f 83 75 ff ff ff    	jae    33a0 <validatetest+0x2b>
      printf(stdout, "link should not succeed\n");
      exit();
    }
  }

  printf(stdout, "validate ok\n");
    342b:	a1 14 5f 00 00       	mov    0x5f14,%eax
    3430:	c7 44 24 04 76 56 00 	movl   $0x5676,0x4(%esp)
    3437:	00 
    3438:	89 04 24             	mov    %eax,(%esp)
    343b:	e8 b7 09 00 00       	call   3df7 <printf>
}
    3440:	c9                   	leave  
    3441:	c3                   	ret    

00003442 <bsstest>:

// does unintialized data start out zero?
char uninit[10000];
void
bsstest(void)
{
    3442:	55                   	push   %ebp
    3443:	89 e5                	mov    %esp,%ebp
    3445:	83 ec 28             	sub    $0x28,%esp
  int i;

  printf(stdout, "bss test\n");
    3448:	a1 14 5f 00 00       	mov    0x5f14,%eax
    344d:	c7 44 24 04 83 56 00 	movl   $0x5683,0x4(%esp)
    3454:	00 
    3455:	89 04 24             	mov    %eax,(%esp)
    3458:	e8 9a 09 00 00       	call   3df7 <printf>
  for(i = 0; i < sizeof(uninit); i++){
    345d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    3464:	eb 2d                	jmp    3493 <bsstest+0x51>
    if(uninit[i] != '\0'){
    3466:	8b 45 f4             	mov    -0xc(%ebp),%eax
    3469:	05 e0 5f 00 00       	add    $0x5fe0,%eax
    346e:	0f b6 00             	movzbl (%eax),%eax
    3471:	84 c0                	test   %al,%al
    3473:	74 1a                	je     348f <bsstest+0x4d>
      printf(stdout, "bss test failed\n");
    3475:	a1 14 5f 00 00       	mov    0x5f14,%eax
    347a:	c7 44 24 04 8d 56 00 	movl   $0x568d,0x4(%esp)
    3481:	00 
    3482:	89 04 24             	mov    %eax,(%esp)
    3485:	e8 6d 09 00 00       	call   3df7 <printf>
      exit();
    348a:	e8 a9 07 00 00       	call   3c38 <exit>
bsstest(void)
{
  int i;

  printf(stdout, "bss test\n");
  for(i = 0; i < sizeof(uninit); i++){
    348f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
    3493:	8b 45 f4             	mov    -0xc(%ebp),%eax
    3496:	3d 0f 27 00 00       	cmp    $0x270f,%eax
    349b:	76 c9                	jbe    3466 <bsstest+0x24>
    if(uninit[i] != '\0'){
      printf(stdout, "bss test failed\n");
      exit();
    }
  }
  printf(stdout, "bss test ok\n");
    349d:	a1 14 5f 00 00       	mov    0x5f14,%eax
    34a2:	c7 44 24 04 9e 56 00 	movl   $0x569e,0x4(%esp)
    34a9:	00 
    34aa:	89 04 24             	mov    %eax,(%esp)
    34ad:	e8 45 09 00 00       	call   3df7 <printf>
}
    34b2:	c9                   	leave  
    34b3:	c3                   	ret    

000034b4 <bigargtest>:
// does exec return an error if the arguments
// are larger than a page? or does it write
// below the stack and wreck the instructions/data?
void
bigargtest(void)
{
    34b4:	55                   	push   %ebp
    34b5:	89 e5                	mov    %esp,%ebp
    34b7:	83 ec 28             	sub    $0x28,%esp
  int pid, fd;

  unlink("bigarg-ok");
    34ba:	c7 04 24 ab 56 00 00 	movl   $0x56ab,(%esp)
    34c1:	e8 c2 07 00 00       	call   3c88 <unlink>
  pid = fork();
    34c6:	e8 65 07 00 00       	call   3c30 <fork>
    34cb:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(pid == 0){
    34ce:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
    34d2:	0f 85 90 00 00 00    	jne    3568 <bigargtest+0xb4>
    static char *args[MAXARG];
    int i;
    for(i = 0; i < MAXARG-1; i++)
    34d8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    34df:	eb 12                	jmp    34f3 <bigargtest+0x3f>
      args[i] = "bigargs test: failed\n                                                                                                                                                                                                       ";
    34e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
    34e4:	c7 04 85 40 5f 00 00 	movl   $0x56b8,0x5f40(,%eax,4)
    34eb:	b8 56 00 00 
  unlink("bigarg-ok");
  pid = fork();
  if(pid == 0){
    static char *args[MAXARG];
    int i;
    for(i = 0; i < MAXARG-1; i++)
    34ef:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
    34f3:	83 7d f4 1e          	cmpl   $0x1e,-0xc(%ebp)
    34f7:	7e e8                	jle    34e1 <bigargtest+0x2d>
      args[i] = "bigargs test: failed\n                                                                                                                                                                                                       ";
    args[MAXARG-1] = 0;
    34f9:	c7 05 bc 5f 00 00 00 	movl   $0x0,0x5fbc
    3500:	00 00 00 
    printf(stdout, "bigarg test\n");
    3503:	a1 14 5f 00 00       	mov    0x5f14,%eax
    3508:	c7 44 24 04 95 57 00 	movl   $0x5795,0x4(%esp)
    350f:	00 
    3510:	89 04 24             	mov    %eax,(%esp)
    3513:	e8 df 08 00 00       	call   3df7 <printf>
    exec("echo", args);
    3518:	c7 44 24 04 40 5f 00 	movl   $0x5f40,0x4(%esp)
    351f:	00 
    3520:	c7 04 24 bc 41 00 00 	movl   $0x41bc,(%esp)
    3527:	e8 44 07 00 00       	call   3c70 <exec>
    printf(stdout, "bigarg test ok\n");
    352c:	a1 14 5f 00 00       	mov    0x5f14,%eax
    3531:	c7 44 24 04 a2 57 00 	movl   $0x57a2,0x4(%esp)
    3538:	00 
    3539:	89 04 24             	mov    %eax,(%esp)
    353c:	e8 b6 08 00 00       	call   3df7 <printf>
    fd = open("bigarg-ok", O_CREATE);
    3541:	c7 44 24 04 00 02 00 	movl   $0x200,0x4(%esp)
    3548:	00 
    3549:	c7 04 24 ab 56 00 00 	movl   $0x56ab,(%esp)
    3550:	e8 23 07 00 00       	call   3c78 <open>
    3555:	89 45 ec             	mov    %eax,-0x14(%ebp)
    close(fd);
    3558:	8b 45 ec             	mov    -0x14(%ebp),%eax
    355b:	89 04 24             	mov    %eax,(%esp)
    355e:	e8 fd 06 00 00       	call   3c60 <close>
    exit();
    3563:	e8 d0 06 00 00       	call   3c38 <exit>
  } else if(pid < 0){
    3568:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
    356c:	79 1a                	jns    3588 <bigargtest+0xd4>
    printf(stdout, "bigargtest: fork failed\n");
    356e:	a1 14 5f 00 00       	mov    0x5f14,%eax
    3573:	c7 44 24 04 b2 57 00 	movl   $0x57b2,0x4(%esp)
    357a:	00 
    357b:	89 04 24             	mov    %eax,(%esp)
    357e:	e8 74 08 00 00       	call   3df7 <printf>
    exit();
    3583:	e8 b0 06 00 00       	call   3c38 <exit>
  }
  wait();
    3588:	e8 b3 06 00 00       	call   3c40 <wait>
  fd = open("bigarg-ok", 0);
    358d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
    3594:	00 
    3595:	c7 04 24 ab 56 00 00 	movl   $0x56ab,(%esp)
    359c:	e8 d7 06 00 00       	call   3c78 <open>
    35a1:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(fd < 0){
    35a4:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
    35a8:	79 1a                	jns    35c4 <bigargtest+0x110>
    printf(stdout, "bigarg test failed!\n");
    35aa:	a1 14 5f 00 00       	mov    0x5f14,%eax
    35af:	c7 44 24 04 cb 57 00 	movl   $0x57cb,0x4(%esp)
    35b6:	00 
    35b7:	89 04 24             	mov    %eax,(%esp)
    35ba:	e8 38 08 00 00       	call   3df7 <printf>
    exit();
    35bf:	e8 74 06 00 00       	call   3c38 <exit>
  }
  close(fd);
    35c4:	8b 45 ec             	mov    -0x14(%ebp),%eax
    35c7:	89 04 24             	mov    %eax,(%esp)
    35ca:	e8 91 06 00 00       	call   3c60 <close>
  unlink("bigarg-ok");
    35cf:	c7 04 24 ab 56 00 00 	movl   $0x56ab,(%esp)
    35d6:	e8 ad 06 00 00       	call   3c88 <unlink>
}
    35db:	c9                   	leave  
    35dc:	c3                   	ret    

000035dd <fsfull>:

// what happens when the file system runs out of blocks?
// answer: balloc panics, so this test is not useful.
void
fsfull()
{
    35dd:	55                   	push   %ebp
    35de:	89 e5                	mov    %esp,%ebp
    35e0:	53                   	push   %ebx
    35e1:	83 ec 74             	sub    $0x74,%esp
  int nfiles;
  int fsblocks = 0;
    35e4:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)

  printf(1, "fsfull test\n");
    35eb:	c7 44 24 04 e0 57 00 	movl   $0x57e0,0x4(%esp)
    35f2:	00 
    35f3:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    35fa:	e8 f8 07 00 00       	call   3df7 <printf>

  for(nfiles = 0; ; nfiles++){
    35ff:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    char name[64];
    name[0] = 'f';
    3606:	c6 45 a4 66          	movb   $0x66,-0x5c(%ebp)
    name[1] = '0' + nfiles / 1000;
    360a:	8b 4d f4             	mov    -0xc(%ebp),%ecx
    360d:	ba d3 4d 62 10       	mov    $0x10624dd3,%edx
    3612:	89 c8                	mov    %ecx,%eax
    3614:	f7 ea                	imul   %edx
    3616:	c1 fa 06             	sar    $0x6,%edx
    3619:	89 c8                	mov    %ecx,%eax
    361b:	c1 f8 1f             	sar    $0x1f,%eax
    361e:	89 d1                	mov    %edx,%ecx
    3620:	29 c1                	sub    %eax,%ecx
    3622:	89 c8                	mov    %ecx,%eax
    3624:	83 c0 30             	add    $0x30,%eax
    3627:	88 45 a5             	mov    %al,-0x5b(%ebp)
    name[2] = '0' + (nfiles % 1000) / 100;
    362a:	8b 5d f4             	mov    -0xc(%ebp),%ebx
    362d:	ba d3 4d 62 10       	mov    $0x10624dd3,%edx
    3632:	89 d8                	mov    %ebx,%eax
    3634:	f7 ea                	imul   %edx
    3636:	c1 fa 06             	sar    $0x6,%edx
    3639:	89 d8                	mov    %ebx,%eax
    363b:	c1 f8 1f             	sar    $0x1f,%eax
    363e:	89 d1                	mov    %edx,%ecx
    3640:	29 c1                	sub    %eax,%ecx
    3642:	69 c1 e8 03 00 00    	imul   $0x3e8,%ecx,%eax
    3648:	89 d9                	mov    %ebx,%ecx
    364a:	29 c1                	sub    %eax,%ecx
    364c:	ba 1f 85 eb 51       	mov    $0x51eb851f,%edx
    3651:	89 c8                	mov    %ecx,%eax
    3653:	f7 ea                	imul   %edx
    3655:	c1 fa 05             	sar    $0x5,%edx
    3658:	89 c8                	mov    %ecx,%eax
    365a:	c1 f8 1f             	sar    $0x1f,%eax
    365d:	89 d1                	mov    %edx,%ecx
    365f:	29 c1                	sub    %eax,%ecx
    3661:	89 c8                	mov    %ecx,%eax
    3663:	83 c0 30             	add    $0x30,%eax
    3666:	88 45 a6             	mov    %al,-0x5a(%ebp)
    name[3] = '0' + (nfiles % 100) / 10;
    3669:	8b 5d f4             	mov    -0xc(%ebp),%ebx
    366c:	ba 1f 85 eb 51       	mov    $0x51eb851f,%edx
    3671:	89 d8                	mov    %ebx,%eax
    3673:	f7 ea                	imul   %edx
    3675:	c1 fa 05             	sar    $0x5,%edx
    3678:	89 d8                	mov    %ebx,%eax
    367a:	c1 f8 1f             	sar    $0x1f,%eax
    367d:	89 d1                	mov    %edx,%ecx
    367f:	29 c1                	sub    %eax,%ecx
    3681:	6b c1 64             	imul   $0x64,%ecx,%eax
    3684:	89 d9                	mov    %ebx,%ecx
    3686:	29 c1                	sub    %eax,%ecx
    3688:	ba 67 66 66 66       	mov    $0x66666667,%edx
    368d:	89 c8                	mov    %ecx,%eax
    368f:	f7 ea                	imul   %edx
    3691:	c1 fa 02             	sar    $0x2,%edx
    3694:	89 c8                	mov    %ecx,%eax
    3696:	c1 f8 1f             	sar    $0x1f,%eax
    3699:	89 d1                	mov    %edx,%ecx
    369b:	29 c1                	sub    %eax,%ecx
    369d:	89 c8                	mov    %ecx,%eax
    369f:	83 c0 30             	add    $0x30,%eax
    36a2:	88 45 a7             	mov    %al,-0x59(%ebp)
    name[4] = '0' + (nfiles % 10);
    36a5:	8b 4d f4             	mov    -0xc(%ebp),%ecx
    36a8:	ba 67 66 66 66       	mov    $0x66666667,%edx
    36ad:	89 c8                	mov    %ecx,%eax
    36af:	f7 ea                	imul   %edx
    36b1:	c1 fa 02             	sar    $0x2,%edx
    36b4:	89 c8                	mov    %ecx,%eax
    36b6:	c1 f8 1f             	sar    $0x1f,%eax
    36b9:	29 c2                	sub    %eax,%edx
    36bb:	89 d0                	mov    %edx,%eax
    36bd:	c1 e0 02             	shl    $0x2,%eax
    36c0:	01 d0                	add    %edx,%eax
    36c2:	01 c0                	add    %eax,%eax
    36c4:	89 ca                	mov    %ecx,%edx
    36c6:	29 c2                	sub    %eax,%edx
    36c8:	89 d0                	mov    %edx,%eax
    36ca:	83 c0 30             	add    $0x30,%eax
    36cd:	88 45 a8             	mov    %al,-0x58(%ebp)
    name[5] = '\0';
    36d0:	c6 45 a9 00          	movb   $0x0,-0x57(%ebp)
    printf(1, "writing %s\n", name);
    36d4:	8d 45 a4             	lea    -0x5c(%ebp),%eax
    36d7:	89 44 24 08          	mov    %eax,0x8(%esp)
    36db:	c7 44 24 04 ed 57 00 	movl   $0x57ed,0x4(%esp)
    36e2:	00 
    36e3:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    36ea:	e8 08 07 00 00       	call   3df7 <printf>
    int fd = open(name, O_CREATE|O_RDWR);
    36ef:	c7 44 24 04 02 02 00 	movl   $0x202,0x4(%esp)
    36f6:	00 
    36f7:	8d 45 a4             	lea    -0x5c(%ebp),%eax
    36fa:	89 04 24             	mov    %eax,(%esp)
    36fd:	e8 76 05 00 00       	call   3c78 <open>
    3702:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(fd < 0){
    3705:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
    3709:	79 1d                	jns    3728 <fsfull+0x14b>
      printf(1, "open %s failed\n", name);
    370b:	8d 45 a4             	lea    -0x5c(%ebp),%eax
    370e:	89 44 24 08          	mov    %eax,0x8(%esp)
    3712:	c7 44 24 04 f9 57 00 	movl   $0x57f9,0x4(%esp)
    3719:	00 
    371a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    3721:	e8 d1 06 00 00       	call   3df7 <printf>
      break;
    3726:	eb 71                	jmp    3799 <fsfull+0x1bc>
    }
    int total = 0;
    3728:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
    while(1){
      int cc = write(fd, buf, 512);
    372f:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
    3736:	00 
    3737:	c7 44 24 04 00 87 00 	movl   $0x8700,0x4(%esp)
    373e:	00 
    373f:	8b 45 e8             	mov    -0x18(%ebp),%eax
    3742:	89 04 24             	mov    %eax,(%esp)
    3745:	e8 0e 05 00 00       	call   3c58 <write>
    374a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      if(cc < 512)
    374d:	81 7d e4 ff 01 00 00 	cmpl   $0x1ff,-0x1c(%ebp)
    3754:	7e 0c                	jle    3762 <fsfull+0x185>
        break;
      total += cc;
    3756:	8b 45 e4             	mov    -0x1c(%ebp),%eax
    3759:	01 45 ec             	add    %eax,-0x14(%ebp)
      fsblocks++;
    375c:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
    }
    3760:	eb cd                	jmp    372f <fsfull+0x152>
    }
    int total = 0;
    while(1){
      int cc = write(fd, buf, 512);
      if(cc < 512)
        break;
    3762:	90                   	nop
      total += cc;
      fsblocks++;
    }
    printf(1, "wrote %d bytes\n", total);
    3763:	8b 45 ec             	mov    -0x14(%ebp),%eax
    3766:	89 44 24 08          	mov    %eax,0x8(%esp)
    376a:	c7 44 24 04 09 58 00 	movl   $0x5809,0x4(%esp)
    3771:	00 
    3772:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    3779:	e8 79 06 00 00       	call   3df7 <printf>
    close(fd);
    377e:	8b 45 e8             	mov    -0x18(%ebp),%eax
    3781:	89 04 24             	mov    %eax,(%esp)
    3784:	e8 d7 04 00 00       	call   3c60 <close>
    if(total == 0)
    3789:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
    378d:	74 09                	je     3798 <fsfull+0x1bb>
  int nfiles;
  int fsblocks = 0;

  printf(1, "fsfull test\n");

  for(nfiles = 0; ; nfiles++){
    378f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
    }
    printf(1, "wrote %d bytes\n", total);
    close(fd);
    if(total == 0)
      break;
  }
    3793:	e9 6e fe ff ff       	jmp    3606 <fsfull+0x29>
      fsblocks++;
    }
    printf(1, "wrote %d bytes\n", total);
    close(fd);
    if(total == 0)
      break;
    3798:	90                   	nop
  }

  while(nfiles >= 0){
    3799:	e9 dd 00 00 00       	jmp    387b <fsfull+0x29e>
    char name[64];
    name[0] = 'f';
    379e:	c6 45 a4 66          	movb   $0x66,-0x5c(%ebp)
    name[1] = '0' + nfiles / 1000;
    37a2:	8b 4d f4             	mov    -0xc(%ebp),%ecx
    37a5:	ba d3 4d 62 10       	mov    $0x10624dd3,%edx
    37aa:	89 c8                	mov    %ecx,%eax
    37ac:	f7 ea                	imul   %edx
    37ae:	c1 fa 06             	sar    $0x6,%edx
    37b1:	89 c8                	mov    %ecx,%eax
    37b3:	c1 f8 1f             	sar    $0x1f,%eax
    37b6:	89 d1                	mov    %edx,%ecx
    37b8:	29 c1                	sub    %eax,%ecx
    37ba:	89 c8                	mov    %ecx,%eax
    37bc:	83 c0 30             	add    $0x30,%eax
    37bf:	88 45 a5             	mov    %al,-0x5b(%ebp)
    name[2] = '0' + (nfiles % 1000) / 100;
    37c2:	8b 5d f4             	mov    -0xc(%ebp),%ebx
    37c5:	ba d3 4d 62 10       	mov    $0x10624dd3,%edx
    37ca:	89 d8                	mov    %ebx,%eax
    37cc:	f7 ea                	imul   %edx
    37ce:	c1 fa 06             	sar    $0x6,%edx
    37d1:	89 d8                	mov    %ebx,%eax
    37d3:	c1 f8 1f             	sar    $0x1f,%eax
    37d6:	89 d1                	mov    %edx,%ecx
    37d8:	29 c1                	sub    %eax,%ecx
    37da:	69 c1 e8 03 00 00    	imul   $0x3e8,%ecx,%eax
    37e0:	89 d9                	mov    %ebx,%ecx
    37e2:	29 c1                	sub    %eax,%ecx
    37e4:	ba 1f 85 eb 51       	mov    $0x51eb851f,%edx
    37e9:	89 c8                	mov    %ecx,%eax
    37eb:	f7 ea                	imul   %edx
    37ed:	c1 fa 05             	sar    $0x5,%edx
    37f0:	89 c8                	mov    %ecx,%eax
    37f2:	c1 f8 1f             	sar    $0x1f,%eax
    37f5:	89 d1                	mov    %edx,%ecx
    37f7:	29 c1                	sub    %eax,%ecx
    37f9:	89 c8                	mov    %ecx,%eax
    37fb:	83 c0 30             	add    $0x30,%eax
    37fe:	88 45 a6             	mov    %al,-0x5a(%ebp)
    name[3] = '0' + (nfiles % 100) / 10;
    3801:	8b 5d f4             	mov    -0xc(%ebp),%ebx
    3804:	ba 1f 85 eb 51       	mov    $0x51eb851f,%edx
    3809:	89 d8                	mov    %ebx,%eax
    380b:	f7 ea                	imul   %edx
    380d:	c1 fa 05             	sar    $0x5,%edx
    3810:	89 d8                	mov    %ebx,%eax
    3812:	c1 f8 1f             	sar    $0x1f,%eax
    3815:	89 d1                	mov    %edx,%ecx
    3817:	29 c1                	sub    %eax,%ecx
    3819:	6b c1 64             	imul   $0x64,%ecx,%eax
    381c:	89 d9                	mov    %ebx,%ecx
    381e:	29 c1                	sub    %eax,%ecx
    3820:	ba 67 66 66 66       	mov    $0x66666667,%edx
    3825:	89 c8                	mov    %ecx,%eax
    3827:	f7 ea                	imul   %edx
    3829:	c1 fa 02             	sar    $0x2,%edx
    382c:	89 c8                	mov    %ecx,%eax
    382e:	c1 f8 1f             	sar    $0x1f,%eax
    3831:	89 d1                	mov    %edx,%ecx
    3833:	29 c1                	sub    %eax,%ecx
    3835:	89 c8                	mov    %ecx,%eax
    3837:	83 c0 30             	add    $0x30,%eax
    383a:	88 45 a7             	mov    %al,-0x59(%ebp)
    name[4] = '0' + (nfiles % 10);
    383d:	8b 4d f4             	mov    -0xc(%ebp),%ecx
    3840:	ba 67 66 66 66       	mov    $0x66666667,%edx
    3845:	89 c8                	mov    %ecx,%eax
    3847:	f7 ea                	imul   %edx
    3849:	c1 fa 02             	sar    $0x2,%edx
    384c:	89 c8                	mov    %ecx,%eax
    384e:	c1 f8 1f             	sar    $0x1f,%eax
    3851:	29 c2                	sub    %eax,%edx
    3853:	89 d0                	mov    %edx,%eax
    3855:	c1 e0 02             	shl    $0x2,%eax
    3858:	01 d0                	add    %edx,%eax
    385a:	01 c0                	add    %eax,%eax
    385c:	89 ca                	mov    %ecx,%edx
    385e:	29 c2                	sub    %eax,%edx
    3860:	89 d0                	mov    %edx,%eax
    3862:	83 c0 30             	add    $0x30,%eax
    3865:	88 45 a8             	mov    %al,-0x58(%ebp)
    name[5] = '\0';
    3868:	c6 45 a9 00          	movb   $0x0,-0x57(%ebp)
    unlink(name);
    386c:	8d 45 a4             	lea    -0x5c(%ebp),%eax
    386f:	89 04 24             	mov    %eax,(%esp)
    3872:	e8 11 04 00 00       	call   3c88 <unlink>
    nfiles--;
    3877:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
    close(fd);
    if(total == 0)
      break;
  }

  while(nfiles >= 0){
    387b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
    387f:	0f 89 19 ff ff ff    	jns    379e <fsfull+0x1c1>
    name[5] = '\0';
    unlink(name);
    nfiles--;
  }

  printf(1, "fsfull test finished\n");
    3885:	c7 44 24 04 19 58 00 	movl   $0x5819,0x4(%esp)
    388c:	00 
    388d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    3894:	e8 5e 05 00 00       	call   3df7 <printf>
}
    3899:	83 c4 74             	add    $0x74,%esp
    389c:	5b                   	pop    %ebx
    389d:	5d                   	pop    %ebp
    389e:	c3                   	ret    

0000389f <rand>:

unsigned long randstate = 1;
unsigned int
rand()
{
    389f:	55                   	push   %ebp
    38a0:	89 e5                	mov    %esp,%ebp
  randstate = randstate * 1664525 + 1013904223;
    38a2:	a1 18 5f 00 00       	mov    0x5f18,%eax
    38a7:	69 c0 0d 66 19 00    	imul   $0x19660d,%eax,%eax
    38ad:	05 5f f3 6e 3c       	add    $0x3c6ef35f,%eax
    38b2:	a3 18 5f 00 00       	mov    %eax,0x5f18
  return randstate;
    38b7:	a1 18 5f 00 00       	mov    0x5f18,%eax
}
    38bc:	5d                   	pop    %ebp
    38bd:	c3                   	ret    

000038be <main>:

int
main(int argc, char *argv[])
{
    38be:	55                   	push   %ebp
    38bf:	89 e5                	mov    %esp,%ebp
    38c1:	83 e4 f0             	and    $0xfffffff0,%esp
    38c4:	83 ec 10             	sub    $0x10,%esp
  printf(1, "usertests starting\n");
    38c7:	c7 44 24 04 2f 58 00 	movl   $0x582f,0x4(%esp)
    38ce:	00 
    38cf:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    38d6:	e8 1c 05 00 00       	call   3df7 <printf>

  if(open("usertests.ran", 0) >= 0){
    38db:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
    38e2:	00 
    38e3:	c7 04 24 43 58 00 00 	movl   $0x5843,(%esp)
    38ea:	e8 89 03 00 00       	call   3c78 <open>
    38ef:	85 c0                	test   %eax,%eax
    38f1:	78 19                	js     390c <main+0x4e>
    printf(1, "already ran user tests -- rebuild fs.img\n");
    38f3:	c7 44 24 04 54 58 00 	movl   $0x5854,0x4(%esp)
    38fa:	00 
    38fb:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
    3902:	e8 f0 04 00 00       	call   3df7 <printf>
    exit();
    3907:	e8 2c 03 00 00       	call   3c38 <exit>
  }
  close(open("usertests.ran", O_CREATE));
    390c:	c7 44 24 04 00 02 00 	movl   $0x200,0x4(%esp)
    3913:	00 
    3914:	c7 04 24 43 58 00 00 	movl   $0x5843,(%esp)
    391b:	e8 58 03 00 00       	call   3c78 <open>
    3920:	89 04 24             	mov    %eax,(%esp)
    3923:	e8 38 03 00 00       	call   3c60 <close>
  
  enableSwapping();
    3928:	e8 ab 03 00 00       	call   3cd8 <enableSwapping>
  
  bigargtest();
    392d:	e8 82 fb ff ff       	call   34b4 <bigargtest>
  bigwrite();
    3932:	e8 e6 ea ff ff       	call   241d <bigwrite>
  bigargtest();
    3937:	e8 78 fb ff ff       	call   34b4 <bigargtest>
  bsstest();
    393c:	e8 01 fb ff ff       	call   3442 <bsstest>
  
  disableSwapping();
    3941:	e8 9a 03 00 00       	call   3ce0 <disableSwapping>
  sbrktest();
    3946:	e8 06 f5 ff ff       	call   2e51 <sbrktest>
  enableSwapping();
    394b:	e8 88 03 00 00       	call   3cd8 <enableSwapping>
  validatetest();
    3950:	e8 20 fa ff ff       	call   3375 <validatetest>

  opentest();
    3955:	e8 a6 c6 ff ff       	call   0 <opentest>
  writetest();
    395a:	e8 4c c7 ff ff       	call   ab <writetest>
  writetest1();
    395f:	e8 5c c9 ff ff       	call   2c0 <writetest1>
  createtest();
    3964:	e8 60 cb ff ff       	call   4c9 <createtest>

  mem();
    3969:	e8 01 d1 ff ff       	call   a6f <mem>
  pipe1();
    396e:	e8 37 cd ff ff       	call   6aa <pipe1>
  preempt();
    3973:	e8 20 cf ff ff       	call   898 <preempt>
  exitwait();
    3978:	e8 74 d0 ff ff       	call   9f1 <exitwait>

  rmdot();
    397d:	e8 1e ef ff ff       	call   28a0 <rmdot>
  fourteen();
    3982:	e8 c3 ed ff ff       	call   274a <fourteen>
  bigfile();
    3987:	e8 99 eb ff ff       	call   2525 <bigfile>
  subdir();
    398c:	e8 46 e3 ff ff       	call   1cd7 <subdir>
  concreate();
    3991:	e8 ef dc ff ff       	call   1685 <concreate>
  linkunlink();
    3996:	e8 9b e0 ff ff       	call   1a36 <linkunlink>
  linktest();
    399b:	e8 9c da ff ff       	call   143c <linktest>
  unlinkread();
    39a0:	e8 c2 d8 ff ff       	call   1267 <unlinkread>
  createdelete();
    39a5:	e8 0c d6 ff ff       	call   fb6 <createdelete>
  twofiles();
    39aa:	e8 9f d3 ff ff       	call   d4e <twofiles>
  sharedfd();
    39af:	e8 a0 d1 ff ff       	call   b54 <sharedfd>
  dirfile();
    39b4:	e8 5f f0 ff ff       	call   2a18 <dirfile>
  iref();
    39b9:	e8 9c f2 ff ff       	call   2c5a <iref>
  forktest();
    39be:	e8 bb f3 ff ff       	call   2d7e <forktest>
  bigdir(); // slow
    39c3:	e8 9a e1 ff ff       	call   1b62 <bigdir>

  exectest();
    39c8:	e8 8e cc ff ff       	call   65b <exectest>

  exit();
    39cd:	e8 66 02 00 00       	call   3c38 <exit>
    39d2:	90                   	nop
    39d3:	90                   	nop

000039d4 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
    39d4:	55                   	push   %ebp
    39d5:	89 e5                	mov    %esp,%ebp
    39d7:	57                   	push   %edi
    39d8:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
    39d9:	8b 4d 08             	mov    0x8(%ebp),%ecx
    39dc:	8b 55 10             	mov    0x10(%ebp),%edx
    39df:	8b 45 0c             	mov    0xc(%ebp),%eax
    39e2:	89 cb                	mov    %ecx,%ebx
    39e4:	89 df                	mov    %ebx,%edi
    39e6:	89 d1                	mov    %edx,%ecx
    39e8:	fc                   	cld    
    39e9:	f3 aa                	rep stos %al,%es:(%edi)
    39eb:	89 ca                	mov    %ecx,%edx
    39ed:	89 fb                	mov    %edi,%ebx
    39ef:	89 5d 08             	mov    %ebx,0x8(%ebp)
    39f2:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
    39f5:	5b                   	pop    %ebx
    39f6:	5f                   	pop    %edi
    39f7:	5d                   	pop    %ebp
    39f8:	c3                   	ret    

000039f9 <strcpy>:
#include "user.h"
#include "x86.h"

char*
strcpy(char *s, char *t)
{
    39f9:	55                   	push   %ebp
    39fa:	89 e5                	mov    %esp,%ebp
    39fc:	83 ec 10             	sub    $0x10,%esp
  char *os;

  os = s;
    39ff:	8b 45 08             	mov    0x8(%ebp),%eax
    3a02:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while((*s++ = *t++) != 0)
    3a05:	90                   	nop
    3a06:	8b 45 0c             	mov    0xc(%ebp),%eax
    3a09:	0f b6 10             	movzbl (%eax),%edx
    3a0c:	8b 45 08             	mov    0x8(%ebp),%eax
    3a0f:	88 10                	mov    %dl,(%eax)
    3a11:	8b 45 08             	mov    0x8(%ebp),%eax
    3a14:	0f b6 00             	movzbl (%eax),%eax
    3a17:	84 c0                	test   %al,%al
    3a19:	0f 95 c0             	setne  %al
    3a1c:	83 45 08 01          	addl   $0x1,0x8(%ebp)
    3a20:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
    3a24:	84 c0                	test   %al,%al
    3a26:	75 de                	jne    3a06 <strcpy+0xd>
    ;
  return os;
    3a28:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
    3a2b:	c9                   	leave  
    3a2c:	c3                   	ret    

00003a2d <strcmp>:

int
strcmp(const char *p, const char *q)
{
    3a2d:	55                   	push   %ebp
    3a2e:	89 e5                	mov    %esp,%ebp
  while(*p && *p == *q)
    3a30:	eb 08                	jmp    3a3a <strcmp+0xd>
    p++, q++;
    3a32:	83 45 08 01          	addl   $0x1,0x8(%ebp)
    3a36:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
  while(*p && *p == *q)
    3a3a:	8b 45 08             	mov    0x8(%ebp),%eax
    3a3d:	0f b6 00             	movzbl (%eax),%eax
    3a40:	84 c0                	test   %al,%al
    3a42:	74 10                	je     3a54 <strcmp+0x27>
    3a44:	8b 45 08             	mov    0x8(%ebp),%eax
    3a47:	0f b6 10             	movzbl (%eax),%edx
    3a4a:	8b 45 0c             	mov    0xc(%ebp),%eax
    3a4d:	0f b6 00             	movzbl (%eax),%eax
    3a50:	38 c2                	cmp    %al,%dl
    3a52:	74 de                	je     3a32 <strcmp+0x5>
    p++, q++;
  return (uchar)*p - (uchar)*q;
    3a54:	8b 45 08             	mov    0x8(%ebp),%eax
    3a57:	0f b6 00             	movzbl (%eax),%eax
    3a5a:	0f b6 d0             	movzbl %al,%edx
    3a5d:	8b 45 0c             	mov    0xc(%ebp),%eax
    3a60:	0f b6 00             	movzbl (%eax),%eax
    3a63:	0f b6 c0             	movzbl %al,%eax
    3a66:	89 d1                	mov    %edx,%ecx
    3a68:	29 c1                	sub    %eax,%ecx
    3a6a:	89 c8                	mov    %ecx,%eax
}
    3a6c:	5d                   	pop    %ebp
    3a6d:	c3                   	ret    

00003a6e <strlen>:

uint
strlen(char *s)
{
    3a6e:	55                   	push   %ebp
    3a6f:	89 e5                	mov    %esp,%ebp
    3a71:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
    3a74:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
    3a7b:	eb 04                	jmp    3a81 <strlen+0x13>
    3a7d:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
    3a81:	8b 45 fc             	mov    -0x4(%ebp),%eax
    3a84:	03 45 08             	add    0x8(%ebp),%eax
    3a87:	0f b6 00             	movzbl (%eax),%eax
    3a8a:	84 c0                	test   %al,%al
    3a8c:	75 ef                	jne    3a7d <strlen+0xf>
    ;
  return n;
    3a8e:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
    3a91:	c9                   	leave  
    3a92:	c3                   	ret    

00003a93 <memset>:

void*
memset(void *dst, int c, uint n)
{
    3a93:	55                   	push   %ebp
    3a94:	89 e5                	mov    %esp,%ebp
    3a96:	83 ec 0c             	sub    $0xc,%esp
  stosb(dst, c, n);
    3a99:	8b 45 10             	mov    0x10(%ebp),%eax
    3a9c:	89 44 24 08          	mov    %eax,0x8(%esp)
    3aa0:	8b 45 0c             	mov    0xc(%ebp),%eax
    3aa3:	89 44 24 04          	mov    %eax,0x4(%esp)
    3aa7:	8b 45 08             	mov    0x8(%ebp),%eax
    3aaa:	89 04 24             	mov    %eax,(%esp)
    3aad:	e8 22 ff ff ff       	call   39d4 <stosb>
  return dst;
    3ab2:	8b 45 08             	mov    0x8(%ebp),%eax
}
    3ab5:	c9                   	leave  
    3ab6:	c3                   	ret    

00003ab7 <strchr>:

char*
strchr(const char *s, char c)
{
    3ab7:	55                   	push   %ebp
    3ab8:	89 e5                	mov    %esp,%ebp
    3aba:	83 ec 04             	sub    $0x4,%esp
    3abd:	8b 45 0c             	mov    0xc(%ebp),%eax
    3ac0:	88 45 fc             	mov    %al,-0x4(%ebp)
  for(; *s; s++)
    3ac3:	eb 14                	jmp    3ad9 <strchr+0x22>
    if(*s == c)
    3ac5:	8b 45 08             	mov    0x8(%ebp),%eax
    3ac8:	0f b6 00             	movzbl (%eax),%eax
    3acb:	3a 45 fc             	cmp    -0x4(%ebp),%al
    3ace:	75 05                	jne    3ad5 <strchr+0x1e>
      return (char*)s;
    3ad0:	8b 45 08             	mov    0x8(%ebp),%eax
    3ad3:	eb 13                	jmp    3ae8 <strchr+0x31>
}

char*
strchr(const char *s, char c)
{
  for(; *s; s++)
    3ad5:	83 45 08 01          	addl   $0x1,0x8(%ebp)
    3ad9:	8b 45 08             	mov    0x8(%ebp),%eax
    3adc:	0f b6 00             	movzbl (%eax),%eax
    3adf:	84 c0                	test   %al,%al
    3ae1:	75 e2                	jne    3ac5 <strchr+0xe>
    if(*s == c)
      return (char*)s;
  return 0;
    3ae3:	b8 00 00 00 00       	mov    $0x0,%eax
}
    3ae8:	c9                   	leave  
    3ae9:	c3                   	ret    

00003aea <gets>:

char*
gets(char *buf, int max)
{
    3aea:	55                   	push   %ebp
    3aeb:	89 e5                	mov    %esp,%ebp
    3aed:	83 ec 28             	sub    $0x28,%esp
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
    3af0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    3af7:	eb 44                	jmp    3b3d <gets+0x53>
    cc = read(0, &c, 1);
    3af9:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
    3b00:	00 
    3b01:	8d 45 ef             	lea    -0x11(%ebp),%eax
    3b04:	89 44 24 04          	mov    %eax,0x4(%esp)
    3b08:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
    3b0f:	e8 3c 01 00 00       	call   3c50 <read>
    3b14:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(cc < 1)
    3b17:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
    3b1b:	7e 2d                	jle    3b4a <gets+0x60>
      break;
    buf[i++] = c;
    3b1d:	8b 45 f4             	mov    -0xc(%ebp),%eax
    3b20:	03 45 08             	add    0x8(%ebp),%eax
    3b23:	0f b6 55 ef          	movzbl -0x11(%ebp),%edx
    3b27:	88 10                	mov    %dl,(%eax)
    3b29:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
    if(c == '\n' || c == '\r')
    3b2d:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
    3b31:	3c 0a                	cmp    $0xa,%al
    3b33:	74 16                	je     3b4b <gets+0x61>
    3b35:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
    3b39:	3c 0d                	cmp    $0xd,%al
    3b3b:	74 0e                	je     3b4b <gets+0x61>
gets(char *buf, int max)
{
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
    3b3d:	8b 45 f4             	mov    -0xc(%ebp),%eax
    3b40:	83 c0 01             	add    $0x1,%eax
    3b43:	3b 45 0c             	cmp    0xc(%ebp),%eax
    3b46:	7c b1                	jl     3af9 <gets+0xf>
    3b48:	eb 01                	jmp    3b4b <gets+0x61>
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    3b4a:	90                   	nop
    buf[i++] = c;
    if(c == '\n' || c == '\r')
      break;
  }
  buf[i] = '\0';
    3b4b:	8b 45 f4             	mov    -0xc(%ebp),%eax
    3b4e:	03 45 08             	add    0x8(%ebp),%eax
    3b51:	c6 00 00             	movb   $0x0,(%eax)
  return buf;
    3b54:	8b 45 08             	mov    0x8(%ebp),%eax
}
    3b57:	c9                   	leave  
    3b58:	c3                   	ret    

00003b59 <stat>:

int
stat(char *n, struct stat *st)
{
    3b59:	55                   	push   %ebp
    3b5a:	89 e5                	mov    %esp,%ebp
    3b5c:	83 ec 28             	sub    $0x28,%esp
  int fd;
  int r;

  fd = open(n, O_RDONLY);
    3b5f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
    3b66:	00 
    3b67:	8b 45 08             	mov    0x8(%ebp),%eax
    3b6a:	89 04 24             	mov    %eax,(%esp)
    3b6d:	e8 06 01 00 00       	call   3c78 <open>
    3b72:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(fd < 0)
    3b75:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
    3b79:	79 07                	jns    3b82 <stat+0x29>
    return -1;
    3b7b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    3b80:	eb 23                	jmp    3ba5 <stat+0x4c>
  r = fstat(fd, st);
    3b82:	8b 45 0c             	mov    0xc(%ebp),%eax
    3b85:	89 44 24 04          	mov    %eax,0x4(%esp)
    3b89:	8b 45 f4             	mov    -0xc(%ebp),%eax
    3b8c:	89 04 24             	mov    %eax,(%esp)
    3b8f:	e8 fc 00 00 00       	call   3c90 <fstat>
    3b94:	89 45 f0             	mov    %eax,-0x10(%ebp)
  close(fd);
    3b97:	8b 45 f4             	mov    -0xc(%ebp),%eax
    3b9a:	89 04 24             	mov    %eax,(%esp)
    3b9d:	e8 be 00 00 00       	call   3c60 <close>
  return r;
    3ba2:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
    3ba5:	c9                   	leave  
    3ba6:	c3                   	ret    

00003ba7 <atoi>:

int
atoi(const char *s)
{
    3ba7:	55                   	push   %ebp
    3ba8:	89 e5                	mov    %esp,%ebp
    3baa:	83 ec 10             	sub    $0x10,%esp
  int n;

  n = 0;
    3bad:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  while('0' <= *s && *s <= '9')
    3bb4:	eb 23                	jmp    3bd9 <atoi+0x32>
    n = n*10 + *s++ - '0';
    3bb6:	8b 55 fc             	mov    -0x4(%ebp),%edx
    3bb9:	89 d0                	mov    %edx,%eax
    3bbb:	c1 e0 02             	shl    $0x2,%eax
    3bbe:	01 d0                	add    %edx,%eax
    3bc0:	01 c0                	add    %eax,%eax
    3bc2:	89 c2                	mov    %eax,%edx
    3bc4:	8b 45 08             	mov    0x8(%ebp),%eax
    3bc7:	0f b6 00             	movzbl (%eax),%eax
    3bca:	0f be c0             	movsbl %al,%eax
    3bcd:	01 d0                	add    %edx,%eax
    3bcf:	83 e8 30             	sub    $0x30,%eax
    3bd2:	89 45 fc             	mov    %eax,-0x4(%ebp)
    3bd5:	83 45 08 01          	addl   $0x1,0x8(%ebp)
atoi(const char *s)
{
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
    3bd9:	8b 45 08             	mov    0x8(%ebp),%eax
    3bdc:	0f b6 00             	movzbl (%eax),%eax
    3bdf:	3c 2f                	cmp    $0x2f,%al
    3be1:	7e 0a                	jle    3bed <atoi+0x46>
    3be3:	8b 45 08             	mov    0x8(%ebp),%eax
    3be6:	0f b6 00             	movzbl (%eax),%eax
    3be9:	3c 39                	cmp    $0x39,%al
    3beb:	7e c9                	jle    3bb6 <atoi+0xf>
    n = n*10 + *s++ - '0';
  return n;
    3bed:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
    3bf0:	c9                   	leave  
    3bf1:	c3                   	ret    

00003bf2 <memmove>:

void*
memmove(void *vdst, void *vsrc, int n)
{
    3bf2:	55                   	push   %ebp
    3bf3:	89 e5                	mov    %esp,%ebp
    3bf5:	83 ec 10             	sub    $0x10,%esp
  char *dst, *src;
  
  dst = vdst;
    3bf8:	8b 45 08             	mov    0x8(%ebp),%eax
    3bfb:	89 45 fc             	mov    %eax,-0x4(%ebp)
  src = vsrc;
    3bfe:	8b 45 0c             	mov    0xc(%ebp),%eax
    3c01:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0)
    3c04:	eb 13                	jmp    3c19 <memmove+0x27>
    *dst++ = *src++;
    3c06:	8b 45 f8             	mov    -0x8(%ebp),%eax
    3c09:	0f b6 10             	movzbl (%eax),%edx
    3c0c:	8b 45 fc             	mov    -0x4(%ebp),%eax
    3c0f:	88 10                	mov    %dl,(%eax)
    3c11:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
    3c15:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  char *dst, *src;
  
  dst = vdst;
  src = vsrc;
  while(n-- > 0)
    3c19:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
    3c1d:	0f 9f c0             	setg   %al
    3c20:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
    3c24:	84 c0                	test   %al,%al
    3c26:	75 de                	jne    3c06 <memmove+0x14>
    *dst++ = *src++;
  return vdst;
    3c28:	8b 45 08             	mov    0x8(%ebp),%eax
}
    3c2b:	c9                   	leave  
    3c2c:	c3                   	ret    
    3c2d:	90                   	nop
    3c2e:	90                   	nop
    3c2f:	90                   	nop

00003c30 <fork>:
  name: \
    movl $SYS_ ## name, %eax; \
    int $T_SYSCALL; \
    ret

SYSCALL(fork)
    3c30:	b8 01 00 00 00       	mov    $0x1,%eax
    3c35:	cd 40                	int    $0x40
    3c37:	c3                   	ret    

00003c38 <exit>:
SYSCALL(exit)
    3c38:	b8 02 00 00 00       	mov    $0x2,%eax
    3c3d:	cd 40                	int    $0x40
    3c3f:	c3                   	ret    

00003c40 <wait>:
SYSCALL(wait)
    3c40:	b8 03 00 00 00       	mov    $0x3,%eax
    3c45:	cd 40                	int    $0x40
    3c47:	c3                   	ret    

00003c48 <pipe>:
SYSCALL(pipe)
    3c48:	b8 04 00 00 00       	mov    $0x4,%eax
    3c4d:	cd 40                	int    $0x40
    3c4f:	c3                   	ret    

00003c50 <read>:
SYSCALL(read)
    3c50:	b8 05 00 00 00       	mov    $0x5,%eax
    3c55:	cd 40                	int    $0x40
    3c57:	c3                   	ret    

00003c58 <write>:
SYSCALL(write)
    3c58:	b8 10 00 00 00       	mov    $0x10,%eax
    3c5d:	cd 40                	int    $0x40
    3c5f:	c3                   	ret    

00003c60 <close>:
SYSCALL(close)
    3c60:	b8 15 00 00 00       	mov    $0x15,%eax
    3c65:	cd 40                	int    $0x40
    3c67:	c3                   	ret    

00003c68 <kill>:
SYSCALL(kill)
    3c68:	b8 06 00 00 00       	mov    $0x6,%eax
    3c6d:	cd 40                	int    $0x40
    3c6f:	c3                   	ret    

00003c70 <exec>:
SYSCALL(exec)
    3c70:	b8 07 00 00 00       	mov    $0x7,%eax
    3c75:	cd 40                	int    $0x40
    3c77:	c3                   	ret    

00003c78 <open>:
SYSCALL(open)
    3c78:	b8 0f 00 00 00       	mov    $0xf,%eax
    3c7d:	cd 40                	int    $0x40
    3c7f:	c3                   	ret    

00003c80 <mknod>:
SYSCALL(mknod)
    3c80:	b8 11 00 00 00       	mov    $0x11,%eax
    3c85:	cd 40                	int    $0x40
    3c87:	c3                   	ret    

00003c88 <unlink>:
SYSCALL(unlink)
    3c88:	b8 12 00 00 00       	mov    $0x12,%eax
    3c8d:	cd 40                	int    $0x40
    3c8f:	c3                   	ret    

00003c90 <fstat>:
SYSCALL(fstat)
    3c90:	b8 08 00 00 00       	mov    $0x8,%eax
    3c95:	cd 40                	int    $0x40
    3c97:	c3                   	ret    

00003c98 <link>:
SYSCALL(link)
    3c98:	b8 13 00 00 00       	mov    $0x13,%eax
    3c9d:	cd 40                	int    $0x40
    3c9f:	c3                   	ret    

00003ca0 <mkdir>:
SYSCALL(mkdir)
    3ca0:	b8 14 00 00 00       	mov    $0x14,%eax
    3ca5:	cd 40                	int    $0x40
    3ca7:	c3                   	ret    

00003ca8 <chdir>:
SYSCALL(chdir)
    3ca8:	b8 09 00 00 00       	mov    $0x9,%eax
    3cad:	cd 40                	int    $0x40
    3caf:	c3                   	ret    

00003cb0 <dup>:
SYSCALL(dup)
    3cb0:	b8 0a 00 00 00       	mov    $0xa,%eax
    3cb5:	cd 40                	int    $0x40
    3cb7:	c3                   	ret    

00003cb8 <getpid>:
SYSCALL(getpid)
    3cb8:	b8 0b 00 00 00       	mov    $0xb,%eax
    3cbd:	cd 40                	int    $0x40
    3cbf:	c3                   	ret    

00003cc0 <sbrk>:
SYSCALL(sbrk)
    3cc0:	b8 0c 00 00 00       	mov    $0xc,%eax
    3cc5:	cd 40                	int    $0x40
    3cc7:	c3                   	ret    

00003cc8 <sleep>:
SYSCALL(sleep)
    3cc8:	b8 0d 00 00 00       	mov    $0xd,%eax
    3ccd:	cd 40                	int    $0x40
    3ccf:	c3                   	ret    

00003cd0 <uptime>:
SYSCALL(uptime)
    3cd0:	b8 0e 00 00 00       	mov    $0xe,%eax
    3cd5:	cd 40                	int    $0x40
    3cd7:	c3                   	ret    

00003cd8 <enableSwapping>:
SYSCALL(enableSwapping)
    3cd8:	b8 16 00 00 00       	mov    $0x16,%eax
    3cdd:	cd 40                	int    $0x40
    3cdf:	c3                   	ret    

00003ce0 <disableSwapping>:
SYSCALL(disableSwapping)
    3ce0:	b8 17 00 00 00       	mov    $0x17,%eax
    3ce5:	cd 40                	int    $0x40
    3ce7:	c3                   	ret    

00003ce8 <sleep2>:
SYSCALL(sleep2)
    3ce8:	b8 18 00 00 00       	mov    $0x18,%eax
    3ced:	cd 40                	int    $0x40
    3cef:	c3                   	ret    

00003cf0 <wakeup2>:
SYSCALL(wakeup2)
    3cf0:	b8 19 00 00 00       	mov    $0x19,%eax
    3cf5:	cd 40                	int    $0x40
    3cf7:	c3                   	ret    

00003cf8 <getAllocatedPages>:
SYSCALL(getAllocatedPages)
    3cf8:	b8 1a 00 00 00       	mov    $0x1a,%eax
    3cfd:	cd 40                	int    $0x40
    3cff:	c3                   	ret    

00003d00 <shmget>:
SYSCALL(shmget)
    3d00:	b8 1b 00 00 00       	mov    $0x1b,%eax
    3d05:	cd 40                	int    $0x40
    3d07:	c3                   	ret    

00003d08 <shmdel>:
SYSCALL(shmdel)
    3d08:	b8 1c 00 00 00       	mov    $0x1c,%eax
    3d0d:	cd 40                	int    $0x40
    3d0f:	c3                   	ret    

00003d10 <shmat>:
SYSCALL(shmat)
    3d10:	b8 1d 00 00 00       	mov    $0x1d,%eax
    3d15:	cd 40                	int    $0x40
    3d17:	c3                   	ret    

00003d18 <shmdt>:
    3d18:	b8 1e 00 00 00       	mov    $0x1e,%eax
    3d1d:	cd 40                	int    $0x40
    3d1f:	c3                   	ret    

00003d20 <putc>:
#include "stat.h"
#include "user.h"

static void
putc(int fd, char c)
{
    3d20:	55                   	push   %ebp
    3d21:	89 e5                	mov    %esp,%ebp
    3d23:	83 ec 28             	sub    $0x28,%esp
    3d26:	8b 45 0c             	mov    0xc(%ebp),%eax
    3d29:	88 45 f4             	mov    %al,-0xc(%ebp)
  write(fd, &c, 1);
    3d2c:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
    3d33:	00 
    3d34:	8d 45 f4             	lea    -0xc(%ebp),%eax
    3d37:	89 44 24 04          	mov    %eax,0x4(%esp)
    3d3b:	8b 45 08             	mov    0x8(%ebp),%eax
    3d3e:	89 04 24             	mov    %eax,(%esp)
    3d41:	e8 12 ff ff ff       	call   3c58 <write>
}
    3d46:	c9                   	leave  
    3d47:	c3                   	ret    

00003d48 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
    3d48:	55                   	push   %ebp
    3d49:	89 e5                	mov    %esp,%ebp
    3d4b:	83 ec 48             	sub    $0x48,%esp
  static char digits[] = "0123456789ABCDEF";
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
    3d4e:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  if(sgn && xx < 0){
    3d55:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
    3d59:	74 17                	je     3d72 <printint+0x2a>
    3d5b:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
    3d5f:	79 11                	jns    3d72 <printint+0x2a>
    neg = 1;
    3d61:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
    x = -xx;
    3d68:	8b 45 0c             	mov    0xc(%ebp),%eax
    3d6b:	f7 d8                	neg    %eax
    3d6d:	89 45 ec             	mov    %eax,-0x14(%ebp)
    3d70:	eb 06                	jmp    3d78 <printint+0x30>
  } else {
    x = xx;
    3d72:	8b 45 0c             	mov    0xc(%ebp),%eax
    3d75:	89 45 ec             	mov    %eax,-0x14(%ebp)
  }

  i = 0;
    3d78:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  do{
    buf[i++] = digits[x % base];
    3d7f:	8b 4d 10             	mov    0x10(%ebp),%ecx
    3d82:	8b 45 ec             	mov    -0x14(%ebp),%eax
    3d85:	ba 00 00 00 00       	mov    $0x0,%edx
    3d8a:	f7 f1                	div    %ecx
    3d8c:	89 d0                	mov    %edx,%eax
    3d8e:	0f b6 90 1c 5f 00 00 	movzbl 0x5f1c(%eax),%edx
    3d95:	8d 45 dc             	lea    -0x24(%ebp),%eax
    3d98:	03 45 f4             	add    -0xc(%ebp),%eax
    3d9b:	88 10                	mov    %dl,(%eax)
    3d9d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  }while((x /= base) != 0);
    3da1:	8b 55 10             	mov    0x10(%ebp),%edx
    3da4:	89 55 d4             	mov    %edx,-0x2c(%ebp)
    3da7:	8b 45 ec             	mov    -0x14(%ebp),%eax
    3daa:	ba 00 00 00 00       	mov    $0x0,%edx
    3daf:	f7 75 d4             	divl   -0x2c(%ebp)
    3db2:	89 45 ec             	mov    %eax,-0x14(%ebp)
    3db5:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
    3db9:	75 c4                	jne    3d7f <printint+0x37>
  if(neg)
    3dbb:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
    3dbf:	74 2a                	je     3deb <printint+0xa3>
    buf[i++] = '-';
    3dc1:	8d 45 dc             	lea    -0x24(%ebp),%eax
    3dc4:	03 45 f4             	add    -0xc(%ebp),%eax
    3dc7:	c6 00 2d             	movb   $0x2d,(%eax)
    3dca:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)

  while(--i >= 0)
    3dce:	eb 1b                	jmp    3deb <printint+0xa3>
    putc(fd, buf[i]);
    3dd0:	8d 45 dc             	lea    -0x24(%ebp),%eax
    3dd3:	03 45 f4             	add    -0xc(%ebp),%eax
    3dd6:	0f b6 00             	movzbl (%eax),%eax
    3dd9:	0f be c0             	movsbl %al,%eax
    3ddc:	89 44 24 04          	mov    %eax,0x4(%esp)
    3de0:	8b 45 08             	mov    0x8(%ebp),%eax
    3de3:	89 04 24             	mov    %eax,(%esp)
    3de6:	e8 35 ff ff ff       	call   3d20 <putc>
    buf[i++] = digits[x % base];
  }while((x /= base) != 0);
  if(neg)
    buf[i++] = '-';

  while(--i >= 0)
    3deb:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
    3def:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
    3df3:	79 db                	jns    3dd0 <printint+0x88>
    putc(fd, buf[i]);
}
    3df5:	c9                   	leave  
    3df6:	c3                   	ret    

00003df7 <printf>:

// Print to the given fd. Only understands %d, %x, %p, %s.
void
printf(int fd, char *fmt, ...)
{
    3df7:	55                   	push   %ebp
    3df8:	89 e5                	mov    %esp,%ebp
    3dfa:	83 ec 38             	sub    $0x38,%esp
  char *s;
  int c, i, state;
  uint *ap;

  state = 0;
    3dfd:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  ap = (uint*)(void*)&fmt + 1;
    3e04:	8d 45 0c             	lea    0xc(%ebp),%eax
    3e07:	83 c0 04             	add    $0x4,%eax
    3e0a:	89 45 e8             	mov    %eax,-0x18(%ebp)
  for(i = 0; fmt[i]; i++){
    3e0d:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    3e14:	e9 7d 01 00 00       	jmp    3f96 <printf+0x19f>
    c = fmt[i] & 0xff;
    3e19:	8b 55 0c             	mov    0xc(%ebp),%edx
    3e1c:	8b 45 f0             	mov    -0x10(%ebp),%eax
    3e1f:	01 d0                	add    %edx,%eax
    3e21:	0f b6 00             	movzbl (%eax),%eax
    3e24:	0f be c0             	movsbl %al,%eax
    3e27:	25 ff 00 00 00       	and    $0xff,%eax
    3e2c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(state == 0){
    3e2f:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
    3e33:	75 2c                	jne    3e61 <printf+0x6a>
      if(c == '%'){
    3e35:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
    3e39:	75 0c                	jne    3e47 <printf+0x50>
        state = '%';
    3e3b:	c7 45 ec 25 00 00 00 	movl   $0x25,-0x14(%ebp)
    3e42:	e9 4b 01 00 00       	jmp    3f92 <printf+0x19b>
      } else {
        putc(fd, c);
    3e47:	8b 45 e4             	mov    -0x1c(%ebp),%eax
    3e4a:	0f be c0             	movsbl %al,%eax
    3e4d:	89 44 24 04          	mov    %eax,0x4(%esp)
    3e51:	8b 45 08             	mov    0x8(%ebp),%eax
    3e54:	89 04 24             	mov    %eax,(%esp)
    3e57:	e8 c4 fe ff ff       	call   3d20 <putc>
    3e5c:	e9 31 01 00 00       	jmp    3f92 <printf+0x19b>
      }
    } else if(state == '%'){
    3e61:	83 7d ec 25          	cmpl   $0x25,-0x14(%ebp)
    3e65:	0f 85 27 01 00 00    	jne    3f92 <printf+0x19b>
      if(c == 'd'){
    3e6b:	83 7d e4 64          	cmpl   $0x64,-0x1c(%ebp)
    3e6f:	75 2d                	jne    3e9e <printf+0xa7>
        printint(fd, *ap, 10, 1);
    3e71:	8b 45 e8             	mov    -0x18(%ebp),%eax
    3e74:	8b 00                	mov    (%eax),%eax
    3e76:	c7 44 24 0c 01 00 00 	movl   $0x1,0xc(%esp)
    3e7d:	00 
    3e7e:	c7 44 24 08 0a 00 00 	movl   $0xa,0x8(%esp)
    3e85:	00 
    3e86:	89 44 24 04          	mov    %eax,0x4(%esp)
    3e8a:	8b 45 08             	mov    0x8(%ebp),%eax
    3e8d:	89 04 24             	mov    %eax,(%esp)
    3e90:	e8 b3 fe ff ff       	call   3d48 <printint>
        ap++;
    3e95:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
    3e99:	e9 ed 00 00 00       	jmp    3f8b <printf+0x194>
      } else if(c == 'x' || c == 'p'){
    3e9e:	83 7d e4 78          	cmpl   $0x78,-0x1c(%ebp)
    3ea2:	74 06                	je     3eaa <printf+0xb3>
    3ea4:	83 7d e4 70          	cmpl   $0x70,-0x1c(%ebp)
    3ea8:	75 2d                	jne    3ed7 <printf+0xe0>
        printint(fd, *ap, 16, 0);
    3eaa:	8b 45 e8             	mov    -0x18(%ebp),%eax
    3ead:	8b 00                	mov    (%eax),%eax
    3eaf:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
    3eb6:	00 
    3eb7:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
    3ebe:	00 
    3ebf:	89 44 24 04          	mov    %eax,0x4(%esp)
    3ec3:	8b 45 08             	mov    0x8(%ebp),%eax
    3ec6:	89 04 24             	mov    %eax,(%esp)
    3ec9:	e8 7a fe ff ff       	call   3d48 <printint>
        ap++;
    3ece:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
    3ed2:	e9 b4 00 00 00       	jmp    3f8b <printf+0x194>
      } else if(c == 's'){
    3ed7:	83 7d e4 73          	cmpl   $0x73,-0x1c(%ebp)
    3edb:	75 46                	jne    3f23 <printf+0x12c>
        s = (char*)*ap;
    3edd:	8b 45 e8             	mov    -0x18(%ebp),%eax
    3ee0:	8b 00                	mov    (%eax),%eax
    3ee2:	89 45 f4             	mov    %eax,-0xc(%ebp)
        ap++;
    3ee5:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
        if(s == 0)
    3ee9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
    3eed:	75 27                	jne    3f16 <printf+0x11f>
          s = "(null)";
    3eef:	c7 45 f4 7e 58 00 00 	movl   $0x587e,-0xc(%ebp)
        while(*s != 0){
    3ef6:	eb 1e                	jmp    3f16 <printf+0x11f>
          putc(fd, *s);
    3ef8:	8b 45 f4             	mov    -0xc(%ebp),%eax
    3efb:	0f b6 00             	movzbl (%eax),%eax
    3efe:	0f be c0             	movsbl %al,%eax
    3f01:	89 44 24 04          	mov    %eax,0x4(%esp)
    3f05:	8b 45 08             	mov    0x8(%ebp),%eax
    3f08:	89 04 24             	mov    %eax,(%esp)
    3f0b:	e8 10 fe ff ff       	call   3d20 <putc>
          s++;
    3f10:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
    3f14:	eb 01                	jmp    3f17 <printf+0x120>
      } else if(c == 's'){
        s = (char*)*ap;
        ap++;
        if(s == 0)
          s = "(null)";
        while(*s != 0){
    3f16:	90                   	nop
    3f17:	8b 45 f4             	mov    -0xc(%ebp),%eax
    3f1a:	0f b6 00             	movzbl (%eax),%eax
    3f1d:	84 c0                	test   %al,%al
    3f1f:	75 d7                	jne    3ef8 <printf+0x101>
    3f21:	eb 68                	jmp    3f8b <printf+0x194>
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
    3f23:	83 7d e4 63          	cmpl   $0x63,-0x1c(%ebp)
    3f27:	75 1d                	jne    3f46 <printf+0x14f>
        putc(fd, *ap);
    3f29:	8b 45 e8             	mov    -0x18(%ebp),%eax
    3f2c:	8b 00                	mov    (%eax),%eax
    3f2e:	0f be c0             	movsbl %al,%eax
    3f31:	89 44 24 04          	mov    %eax,0x4(%esp)
    3f35:	8b 45 08             	mov    0x8(%ebp),%eax
    3f38:	89 04 24             	mov    %eax,(%esp)
    3f3b:	e8 e0 fd ff ff       	call   3d20 <putc>
        ap++;
    3f40:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
    3f44:	eb 45                	jmp    3f8b <printf+0x194>
      } else if(c == '%'){
    3f46:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
    3f4a:	75 17                	jne    3f63 <printf+0x16c>
        putc(fd, c);
    3f4c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
    3f4f:	0f be c0             	movsbl %al,%eax
    3f52:	89 44 24 04          	mov    %eax,0x4(%esp)
    3f56:	8b 45 08             	mov    0x8(%ebp),%eax
    3f59:	89 04 24             	mov    %eax,(%esp)
    3f5c:	e8 bf fd ff ff       	call   3d20 <putc>
    3f61:	eb 28                	jmp    3f8b <printf+0x194>
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
    3f63:	c7 44 24 04 25 00 00 	movl   $0x25,0x4(%esp)
    3f6a:	00 
    3f6b:	8b 45 08             	mov    0x8(%ebp),%eax
    3f6e:	89 04 24             	mov    %eax,(%esp)
    3f71:	e8 aa fd ff ff       	call   3d20 <putc>
        putc(fd, c);
    3f76:	8b 45 e4             	mov    -0x1c(%ebp),%eax
    3f79:	0f be c0             	movsbl %al,%eax
    3f7c:	89 44 24 04          	mov    %eax,0x4(%esp)
    3f80:	8b 45 08             	mov    0x8(%ebp),%eax
    3f83:	89 04 24             	mov    %eax,(%esp)
    3f86:	e8 95 fd ff ff       	call   3d20 <putc>
      }
      state = 0;
    3f8b:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  int c, i, state;
  uint *ap;

  state = 0;
  ap = (uint*)(void*)&fmt + 1;
  for(i = 0; fmt[i]; i++){
    3f92:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
    3f96:	8b 55 0c             	mov    0xc(%ebp),%edx
    3f99:	8b 45 f0             	mov    -0x10(%ebp),%eax
    3f9c:	01 d0                	add    %edx,%eax
    3f9e:	0f b6 00             	movzbl (%eax),%eax
    3fa1:	84 c0                	test   %al,%al
    3fa3:	0f 85 70 fe ff ff    	jne    3e19 <printf+0x22>
        putc(fd, c);
      }
      state = 0;
    }
  }
}
    3fa9:	c9                   	leave  
    3faa:	c3                   	ret    
    3fab:	90                   	nop

00003fac <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
    3fac:	55                   	push   %ebp
    3fad:	89 e5                	mov    %esp,%ebp
    3faf:	83 ec 10             	sub    $0x10,%esp
  Header *bp, *p;

  bp = (Header*)ap - 1;
    3fb2:	8b 45 08             	mov    0x8(%ebp),%eax
    3fb5:	83 e8 08             	sub    $0x8,%eax
    3fb8:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
    3fbb:	a1 c8 5f 00 00       	mov    0x5fc8,%eax
    3fc0:	89 45 fc             	mov    %eax,-0x4(%ebp)
    3fc3:	eb 24                	jmp    3fe9 <free+0x3d>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
    3fc5:	8b 45 fc             	mov    -0x4(%ebp),%eax
    3fc8:	8b 00                	mov    (%eax),%eax
    3fca:	3b 45 fc             	cmp    -0x4(%ebp),%eax
    3fcd:	77 12                	ja     3fe1 <free+0x35>
    3fcf:	8b 45 f8             	mov    -0x8(%ebp),%eax
    3fd2:	3b 45 fc             	cmp    -0x4(%ebp),%eax
    3fd5:	77 24                	ja     3ffb <free+0x4f>
    3fd7:	8b 45 fc             	mov    -0x4(%ebp),%eax
    3fda:	8b 00                	mov    (%eax),%eax
    3fdc:	3b 45 f8             	cmp    -0x8(%ebp),%eax
    3fdf:	77 1a                	ja     3ffb <free+0x4f>
free(void *ap)
{
  Header *bp, *p;

  bp = (Header*)ap - 1;
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
    3fe1:	8b 45 fc             	mov    -0x4(%ebp),%eax
    3fe4:	8b 00                	mov    (%eax),%eax
    3fe6:	89 45 fc             	mov    %eax,-0x4(%ebp)
    3fe9:	8b 45 f8             	mov    -0x8(%ebp),%eax
    3fec:	3b 45 fc             	cmp    -0x4(%ebp),%eax
    3fef:	76 d4                	jbe    3fc5 <free+0x19>
    3ff1:	8b 45 fc             	mov    -0x4(%ebp),%eax
    3ff4:	8b 00                	mov    (%eax),%eax
    3ff6:	3b 45 f8             	cmp    -0x8(%ebp),%eax
    3ff9:	76 ca                	jbe    3fc5 <free+0x19>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    3ffb:	8b 45 f8             	mov    -0x8(%ebp),%eax
    3ffe:	8b 40 04             	mov    0x4(%eax),%eax
    4001:	c1 e0 03             	shl    $0x3,%eax
    4004:	89 c2                	mov    %eax,%edx
    4006:	03 55 f8             	add    -0x8(%ebp),%edx
    4009:	8b 45 fc             	mov    -0x4(%ebp),%eax
    400c:	8b 00                	mov    (%eax),%eax
    400e:	39 c2                	cmp    %eax,%edx
    4010:	75 24                	jne    4036 <free+0x8a>
    bp->s.size += p->s.ptr->s.size;
    4012:	8b 45 f8             	mov    -0x8(%ebp),%eax
    4015:	8b 50 04             	mov    0x4(%eax),%edx
    4018:	8b 45 fc             	mov    -0x4(%ebp),%eax
    401b:	8b 00                	mov    (%eax),%eax
    401d:	8b 40 04             	mov    0x4(%eax),%eax
    4020:	01 c2                	add    %eax,%edx
    4022:	8b 45 f8             	mov    -0x8(%ebp),%eax
    4025:	89 50 04             	mov    %edx,0x4(%eax)
    bp->s.ptr = p->s.ptr->s.ptr;
    4028:	8b 45 fc             	mov    -0x4(%ebp),%eax
    402b:	8b 00                	mov    (%eax),%eax
    402d:	8b 10                	mov    (%eax),%edx
    402f:	8b 45 f8             	mov    -0x8(%ebp),%eax
    4032:	89 10                	mov    %edx,(%eax)
    4034:	eb 0a                	jmp    4040 <free+0x94>
  } else
    bp->s.ptr = p->s.ptr;
    4036:	8b 45 fc             	mov    -0x4(%ebp),%eax
    4039:	8b 10                	mov    (%eax),%edx
    403b:	8b 45 f8             	mov    -0x8(%ebp),%eax
    403e:	89 10                	mov    %edx,(%eax)
  if(p + p->s.size == bp){
    4040:	8b 45 fc             	mov    -0x4(%ebp),%eax
    4043:	8b 40 04             	mov    0x4(%eax),%eax
    4046:	c1 e0 03             	shl    $0x3,%eax
    4049:	03 45 fc             	add    -0x4(%ebp),%eax
    404c:	3b 45 f8             	cmp    -0x8(%ebp),%eax
    404f:	75 20                	jne    4071 <free+0xc5>
    p->s.size += bp->s.size;
    4051:	8b 45 fc             	mov    -0x4(%ebp),%eax
    4054:	8b 50 04             	mov    0x4(%eax),%edx
    4057:	8b 45 f8             	mov    -0x8(%ebp),%eax
    405a:	8b 40 04             	mov    0x4(%eax),%eax
    405d:	01 c2                	add    %eax,%edx
    405f:	8b 45 fc             	mov    -0x4(%ebp),%eax
    4062:	89 50 04             	mov    %edx,0x4(%eax)
    p->s.ptr = bp->s.ptr;
    4065:	8b 45 f8             	mov    -0x8(%ebp),%eax
    4068:	8b 10                	mov    (%eax),%edx
    406a:	8b 45 fc             	mov    -0x4(%ebp),%eax
    406d:	89 10                	mov    %edx,(%eax)
    406f:	eb 08                	jmp    4079 <free+0xcd>
  } else
    p->s.ptr = bp;
    4071:	8b 45 fc             	mov    -0x4(%ebp),%eax
    4074:	8b 55 f8             	mov    -0x8(%ebp),%edx
    4077:	89 10                	mov    %edx,(%eax)
  freep = p;
    4079:	8b 45 fc             	mov    -0x4(%ebp),%eax
    407c:	a3 c8 5f 00 00       	mov    %eax,0x5fc8
}
    4081:	c9                   	leave  
    4082:	c3                   	ret    

00004083 <morecore>:

static Header*
morecore(uint nu)
{
    4083:	55                   	push   %ebp
    4084:	89 e5                	mov    %esp,%ebp
    4086:	83 ec 28             	sub    $0x28,%esp
  char *p;
  Header *hp;

  if(nu < 4096)
    4089:	81 7d 08 ff 0f 00 00 	cmpl   $0xfff,0x8(%ebp)
    4090:	77 07                	ja     4099 <morecore+0x16>
    nu = 4096;
    4092:	c7 45 08 00 10 00 00 	movl   $0x1000,0x8(%ebp)
  p = sbrk(nu * sizeof(Header));
    4099:	8b 45 08             	mov    0x8(%ebp),%eax
    409c:	c1 e0 03             	shl    $0x3,%eax
    409f:	89 04 24             	mov    %eax,(%esp)
    40a2:	e8 19 fc ff ff       	call   3cc0 <sbrk>
    40a7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(p == (char*)-1)
    40aa:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
    40ae:	75 07                	jne    40b7 <morecore+0x34>
    return 0;
    40b0:	b8 00 00 00 00       	mov    $0x0,%eax
    40b5:	eb 22                	jmp    40d9 <morecore+0x56>
  hp = (Header*)p;
    40b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
    40ba:	89 45 f0             	mov    %eax,-0x10(%ebp)
  hp->s.size = nu;
    40bd:	8b 45 f0             	mov    -0x10(%ebp),%eax
    40c0:	8b 55 08             	mov    0x8(%ebp),%edx
    40c3:	89 50 04             	mov    %edx,0x4(%eax)
  free((void*)(hp + 1));
    40c6:	8b 45 f0             	mov    -0x10(%ebp),%eax
    40c9:	83 c0 08             	add    $0x8,%eax
    40cc:	89 04 24             	mov    %eax,(%esp)
    40cf:	e8 d8 fe ff ff       	call   3fac <free>
  return freep;
    40d4:	a1 c8 5f 00 00       	mov    0x5fc8,%eax
}
    40d9:	c9                   	leave  
    40da:	c3                   	ret    

000040db <malloc>:

void*
malloc(uint nbytes)
{
    40db:	55                   	push   %ebp
    40dc:	89 e5                	mov    %esp,%ebp
    40de:	83 ec 28             	sub    $0x28,%esp
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
    40e1:	8b 45 08             	mov    0x8(%ebp),%eax
    40e4:	83 c0 07             	add    $0x7,%eax
    40e7:	c1 e8 03             	shr    $0x3,%eax
    40ea:	83 c0 01             	add    $0x1,%eax
    40ed:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((prevp = freep) == 0){
    40f0:	a1 c8 5f 00 00       	mov    0x5fc8,%eax
    40f5:	89 45 f0             	mov    %eax,-0x10(%ebp)
    40f8:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
    40fc:	75 23                	jne    4121 <malloc+0x46>
    base.s.ptr = freep = prevp = &base;
    40fe:	c7 45 f0 c0 5f 00 00 	movl   $0x5fc0,-0x10(%ebp)
    4105:	8b 45 f0             	mov    -0x10(%ebp),%eax
    4108:	a3 c8 5f 00 00       	mov    %eax,0x5fc8
    410d:	a1 c8 5f 00 00       	mov    0x5fc8,%eax
    4112:	a3 c0 5f 00 00       	mov    %eax,0x5fc0
    base.s.size = 0;
    4117:	c7 05 c4 5f 00 00 00 	movl   $0x0,0x5fc4
    411e:	00 00 00 
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
    4121:	8b 45 f0             	mov    -0x10(%ebp),%eax
    4124:	8b 00                	mov    (%eax),%eax
    4126:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(p->s.size >= nunits){
    4129:	8b 45 f4             	mov    -0xc(%ebp),%eax
    412c:	8b 40 04             	mov    0x4(%eax),%eax
    412f:	3b 45 ec             	cmp    -0x14(%ebp),%eax
    4132:	72 4d                	jb     4181 <malloc+0xa6>
      if(p->s.size == nunits)
    4134:	8b 45 f4             	mov    -0xc(%ebp),%eax
    4137:	8b 40 04             	mov    0x4(%eax),%eax
    413a:	3b 45 ec             	cmp    -0x14(%ebp),%eax
    413d:	75 0c                	jne    414b <malloc+0x70>
        prevp->s.ptr = p->s.ptr;
    413f:	8b 45 f4             	mov    -0xc(%ebp),%eax
    4142:	8b 10                	mov    (%eax),%edx
    4144:	8b 45 f0             	mov    -0x10(%ebp),%eax
    4147:	89 10                	mov    %edx,(%eax)
    4149:	eb 26                	jmp    4171 <malloc+0x96>
      else {
        p->s.size -= nunits;
    414b:	8b 45 f4             	mov    -0xc(%ebp),%eax
    414e:	8b 40 04             	mov    0x4(%eax),%eax
    4151:	89 c2                	mov    %eax,%edx
    4153:	2b 55 ec             	sub    -0x14(%ebp),%edx
    4156:	8b 45 f4             	mov    -0xc(%ebp),%eax
    4159:	89 50 04             	mov    %edx,0x4(%eax)
        p += p->s.size;
    415c:	8b 45 f4             	mov    -0xc(%ebp),%eax
    415f:	8b 40 04             	mov    0x4(%eax),%eax
    4162:	c1 e0 03             	shl    $0x3,%eax
    4165:	01 45 f4             	add    %eax,-0xc(%ebp)
        p->s.size = nunits;
    4168:	8b 45 f4             	mov    -0xc(%ebp),%eax
    416b:	8b 55 ec             	mov    -0x14(%ebp),%edx
    416e:	89 50 04             	mov    %edx,0x4(%eax)
      }
      freep = prevp;
    4171:	8b 45 f0             	mov    -0x10(%ebp),%eax
    4174:	a3 c8 5f 00 00       	mov    %eax,0x5fc8
      return (void*)(p + 1);
    4179:	8b 45 f4             	mov    -0xc(%ebp),%eax
    417c:	83 c0 08             	add    $0x8,%eax
    417f:	eb 38                	jmp    41b9 <malloc+0xde>
    }
    if(p == freep)
    4181:	a1 c8 5f 00 00       	mov    0x5fc8,%eax
    4186:	39 45 f4             	cmp    %eax,-0xc(%ebp)
    4189:	75 1b                	jne    41a6 <malloc+0xcb>
      if((p = morecore(nunits)) == 0)
    418b:	8b 45 ec             	mov    -0x14(%ebp),%eax
    418e:	89 04 24             	mov    %eax,(%esp)
    4191:	e8 ed fe ff ff       	call   4083 <morecore>
    4196:	89 45 f4             	mov    %eax,-0xc(%ebp)
    4199:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
    419d:	75 07                	jne    41a6 <malloc+0xcb>
        return 0;
    419f:	b8 00 00 00 00       	mov    $0x0,%eax
    41a4:	eb 13                	jmp    41b9 <malloc+0xde>
  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
  if((prevp = freep) == 0){
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
    41a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
    41a9:	89 45 f0             	mov    %eax,-0x10(%ebp)
    41ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
    41af:	8b 00                	mov    (%eax),%eax
    41b1:	89 45 f4             	mov    %eax,-0xc(%ebp)
      return (void*)(p + 1);
    }
    if(p == freep)
      if((p = morecore(nunits)) == 0)
        return 0;
  }
    41b4:	e9 70 ff ff ff       	jmp    4129 <malloc+0x4e>
}
    41b9:	c9                   	leave  
    41ba:	c3                   	ret    
