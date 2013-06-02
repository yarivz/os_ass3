
kernel:     file format elf32-i386


Disassembly of section .text:

80100000 <multiboot_header>:
80100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
80100006:	00 00                	add    %al,(%eax)
80100008:	fe 4f 52             	decb   0x52(%edi)
8010000b:	e4 0f                	in     $0xf,%al

8010000c <entry>:

# Entering xv6 on boot processor, with paging off.
.globl entry
entry:
  # Turn on page size extension for 4Mbyte pages
  movl    %cr4, %eax
8010000c:	0f 20 e0             	mov    %cr4,%eax
  orl     $(CR4_PSE), %eax
8010000f:	83 c8 10             	or     $0x10,%eax
  movl    %eax, %cr4
80100012:	0f 22 e0             	mov    %eax,%cr4
  # Set page directory
  movl    $(V2P_WO(entrypgdir)), %eax
80100015:	b8 00 a0 10 00       	mov    $0x10a000,%eax
  movl    %eax, %cr3
8010001a:	0f 22 d8             	mov    %eax,%cr3
  # Turn on paging.
  movl    %cr0, %eax
8010001d:	0f 20 c0             	mov    %cr0,%eax
  orl     $(CR0_PG|CR0_WP), %eax
80100020:	0d 00 00 01 80       	or     $0x80010000,%eax
  movl    %eax, %cr0
80100025:	0f 22 c0             	mov    %eax,%cr0

  # Set up the stack pointer.
  movl $(stack + KSTACKSIZE), %esp
80100028:	bc 60 c6 10 80       	mov    $0x8010c660,%esp

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $main, %eax
8010002d:	b8 13 34 10 80       	mov    $0x80103413,%eax
  jmp *%eax
80100032:	ff e0                	jmp    *%eax

80100034 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
80100034:	55                   	push   %ebp
80100035:	89 e5                	mov    %esp,%ebp
80100037:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  initlock(&bcache.lock, "bcache");
8010003a:	c7 44 24 04 54 88 10 	movl   $0x80108854,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
80100049:	e8 48 50 00 00       	call   80105096 <initlock>

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
8010004e:	c7 05 90 db 10 80 84 	movl   $0x8010db84,0x8010db90
80100055:	db 10 80 
  bcache.head.next = &bcache.head;
80100058:	c7 05 94 db 10 80 84 	movl   $0x8010db84,0x8010db94
8010005f:	db 10 80 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
80100062:	c7 45 f4 94 c6 10 80 	movl   $0x8010c694,-0xc(%ebp)
80100069:	eb 3a                	jmp    801000a5 <binit+0x71>
    b->next = bcache.head.next;
8010006b:	8b 15 94 db 10 80    	mov    0x8010db94,%edx
80100071:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100074:	89 50 10             	mov    %edx,0x10(%eax)
    b->prev = &bcache.head;
80100077:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010007a:	c7 40 0c 84 db 10 80 	movl   $0x8010db84,0xc(%eax)
    b->dev = -1;
80100081:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100084:	c7 40 04 ff ff ff ff 	movl   $0xffffffff,0x4(%eax)
    bcache.head.next->prev = b;
8010008b:	a1 94 db 10 80       	mov    0x8010db94,%eax
80100090:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100093:	89 50 0c             	mov    %edx,0xc(%eax)
    bcache.head.next = b;
80100096:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100099:	a3 94 db 10 80       	mov    %eax,0x8010db94

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
  bcache.head.next = &bcache.head;
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
8010009e:	81 45 f4 18 02 00 00 	addl   $0x218,-0xc(%ebp)
801000a5:	81 7d f4 84 db 10 80 	cmpl   $0x8010db84,-0xc(%ebp)
801000ac:	72 bd                	jb     8010006b <binit+0x37>
    b->prev = &bcache.head;
    b->dev = -1;
    bcache.head.next->prev = b;
    bcache.head.next = b;
  }
}
801000ae:	c9                   	leave  
801000af:	c3                   	ret    

801000b0 <bget>:
// Look through buffer cache for sector on device dev.
// If not found, allocate fresh block.
// In either case, return B_BUSY buffer.
static struct buf*
bget(uint dev, uint sector)
{
801000b0:	55                   	push   %ebp
801000b1:	89 e5                	mov    %esp,%ebp
801000b3:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  acquire(&bcache.lock);
801000b6:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
801000bd:	e8 f5 4f 00 00       	call   801050b7 <acquire>

 loop:
  // Is the sector already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
801000c2:	a1 94 db 10 80       	mov    0x8010db94,%eax
801000c7:	89 45 f4             	mov    %eax,-0xc(%ebp)
801000ca:	eb 63                	jmp    8010012f <bget+0x7f>
    if(b->dev == dev && b->sector == sector){
801000cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000cf:	8b 40 04             	mov    0x4(%eax),%eax
801000d2:	3b 45 08             	cmp    0x8(%ebp),%eax
801000d5:	75 4f                	jne    80100126 <bget+0x76>
801000d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000da:	8b 40 08             	mov    0x8(%eax),%eax
801000dd:	3b 45 0c             	cmp    0xc(%ebp),%eax
801000e0:	75 44                	jne    80100126 <bget+0x76>
      if(!(b->flags & B_BUSY)){
801000e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000e5:	8b 00                	mov    (%eax),%eax
801000e7:	83 e0 01             	and    $0x1,%eax
801000ea:	85 c0                	test   %eax,%eax
801000ec:	75 23                	jne    80100111 <bget+0x61>
        b->flags |= B_BUSY;
801000ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000f1:	8b 00                	mov    (%eax),%eax
801000f3:	89 c2                	mov    %eax,%edx
801000f5:	83 ca 01             	or     $0x1,%edx
801000f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000fb:	89 10                	mov    %edx,(%eax)
        release(&bcache.lock);
801000fd:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
80100104:	e8 49 50 00 00       	call   80105152 <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 60 c6 10 	movl   $0x8010c660,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 26 4c 00 00       	call   80104d4a <sleep>
      goto loop;
80100124:	eb 9c                	jmp    801000c2 <bget+0x12>

  acquire(&bcache.lock);

 loop:
  // Is the sector already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
80100126:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100129:	8b 40 10             	mov    0x10(%eax),%eax
8010012c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010012f:	81 7d f4 84 db 10 80 	cmpl   $0x8010db84,-0xc(%ebp)
80100136:	75 94                	jne    801000cc <bget+0x1c>
      goto loop;
    }
  }

  // Not cached; recycle some non-busy and clean buffer.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100138:	a1 90 db 10 80       	mov    0x8010db90,%eax
8010013d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100140:	eb 4d                	jmp    8010018f <bget+0xdf>
    if((b->flags & B_BUSY) == 0 && (b->flags & B_DIRTY) == 0){
80100142:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100145:	8b 00                	mov    (%eax),%eax
80100147:	83 e0 01             	and    $0x1,%eax
8010014a:	85 c0                	test   %eax,%eax
8010014c:	75 38                	jne    80100186 <bget+0xd6>
8010014e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100151:	8b 00                	mov    (%eax),%eax
80100153:	83 e0 04             	and    $0x4,%eax
80100156:	85 c0                	test   %eax,%eax
80100158:	75 2c                	jne    80100186 <bget+0xd6>
      b->dev = dev;
8010015a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010015d:	8b 55 08             	mov    0x8(%ebp),%edx
80100160:	89 50 04             	mov    %edx,0x4(%eax)
      b->sector = sector;
80100163:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100166:	8b 55 0c             	mov    0xc(%ebp),%edx
80100169:	89 50 08             	mov    %edx,0x8(%eax)
      b->flags = B_BUSY;
8010016c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010016f:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
      release(&bcache.lock);
80100175:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
8010017c:	e8 d1 4f 00 00       	call   80105152 <release>
      return b;
80100181:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100184:	eb 1e                	jmp    801001a4 <bget+0xf4>
      goto loop;
    }
  }

  // Not cached; recycle some non-busy and clean buffer.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100186:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100189:	8b 40 0c             	mov    0xc(%eax),%eax
8010018c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010018f:	81 7d f4 84 db 10 80 	cmpl   $0x8010db84,-0xc(%ebp)
80100196:	75 aa                	jne    80100142 <bget+0x92>
      b->flags = B_BUSY;
      release(&bcache.lock);
      return b;
    }
  }
  panic("bget: no buffers");
80100198:	c7 04 24 5b 88 10 80 	movl   $0x8010885b,(%esp)
8010019f:	e8 99 03 00 00       	call   8010053d <panic>
}
801001a4:	c9                   	leave  
801001a5:	c3                   	ret    

801001a6 <bread>:

// Return a B_BUSY buf with the contents of the indicated disk sector.
struct buf*
bread(uint dev, uint sector)
{
801001a6:	55                   	push   %ebp
801001a7:	89 e5                	mov    %esp,%ebp
801001a9:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  b = bget(dev, sector);
801001ac:	8b 45 0c             	mov    0xc(%ebp),%eax
801001af:	89 44 24 04          	mov    %eax,0x4(%esp)
801001b3:	8b 45 08             	mov    0x8(%ebp),%eax
801001b6:	89 04 24             	mov    %eax,(%esp)
801001b9:	e8 f2 fe ff ff       	call   801000b0 <bget>
801001be:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(!(b->flags & B_VALID))
801001c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801001c4:	8b 00                	mov    (%eax),%eax
801001c6:	83 e0 02             	and    $0x2,%eax
801001c9:	85 c0                	test   %eax,%eax
801001cb:	75 0b                	jne    801001d8 <bread+0x32>
    iderw(b);
801001cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801001d0:	89 04 24             	mov    %eax,(%esp)
801001d3:	e8 d1 25 00 00       	call   801027a9 <iderw>
  return b;
801001d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801001db:	c9                   	leave  
801001dc:	c3                   	ret    

801001dd <bwrite>:

// Write b's contents to disk.  Must be B_BUSY.
void
bwrite(struct buf *b)
{
801001dd:	55                   	push   %ebp
801001de:	89 e5                	mov    %esp,%ebp
801001e0:	83 ec 18             	sub    $0x18,%esp
  if((b->flags & B_BUSY) == 0)
801001e3:	8b 45 08             	mov    0x8(%ebp),%eax
801001e6:	8b 00                	mov    (%eax),%eax
801001e8:	83 e0 01             	and    $0x1,%eax
801001eb:	85 c0                	test   %eax,%eax
801001ed:	75 0c                	jne    801001fb <bwrite+0x1e>
    panic("bwrite");
801001ef:	c7 04 24 6c 88 10 80 	movl   $0x8010886c,(%esp)
801001f6:	e8 42 03 00 00       	call   8010053d <panic>
  b->flags |= B_DIRTY;
801001fb:	8b 45 08             	mov    0x8(%ebp),%eax
801001fe:	8b 00                	mov    (%eax),%eax
80100200:	89 c2                	mov    %eax,%edx
80100202:	83 ca 04             	or     $0x4,%edx
80100205:	8b 45 08             	mov    0x8(%ebp),%eax
80100208:	89 10                	mov    %edx,(%eax)
  iderw(b);
8010020a:	8b 45 08             	mov    0x8(%ebp),%eax
8010020d:	89 04 24             	mov    %eax,(%esp)
80100210:	e8 94 25 00 00       	call   801027a9 <iderw>
}
80100215:	c9                   	leave  
80100216:	c3                   	ret    

80100217 <brelse>:

// Release a B_BUSY buffer.
// Move to the head of the MRU list.
void
brelse(struct buf *b)
{
80100217:	55                   	push   %ebp
80100218:	89 e5                	mov    %esp,%ebp
8010021a:	83 ec 18             	sub    $0x18,%esp
  if((b->flags & B_BUSY) == 0)
8010021d:	8b 45 08             	mov    0x8(%ebp),%eax
80100220:	8b 00                	mov    (%eax),%eax
80100222:	83 e0 01             	and    $0x1,%eax
80100225:	85 c0                	test   %eax,%eax
80100227:	75 0c                	jne    80100235 <brelse+0x1e>
    panic("brelse");
80100229:	c7 04 24 73 88 10 80 	movl   $0x80108873,(%esp)
80100230:	e8 08 03 00 00       	call   8010053d <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
8010023c:	e8 76 4e 00 00       	call   801050b7 <acquire>

  b->next->prev = b->prev;
80100241:	8b 45 08             	mov    0x8(%ebp),%eax
80100244:	8b 40 10             	mov    0x10(%eax),%eax
80100247:	8b 55 08             	mov    0x8(%ebp),%edx
8010024a:	8b 52 0c             	mov    0xc(%edx),%edx
8010024d:	89 50 0c             	mov    %edx,0xc(%eax)
  b->prev->next = b->next;
80100250:	8b 45 08             	mov    0x8(%ebp),%eax
80100253:	8b 40 0c             	mov    0xc(%eax),%eax
80100256:	8b 55 08             	mov    0x8(%ebp),%edx
80100259:	8b 52 10             	mov    0x10(%edx),%edx
8010025c:	89 50 10             	mov    %edx,0x10(%eax)
  b->next = bcache.head.next;
8010025f:	8b 15 94 db 10 80    	mov    0x8010db94,%edx
80100265:	8b 45 08             	mov    0x8(%ebp),%eax
80100268:	89 50 10             	mov    %edx,0x10(%eax)
  b->prev = &bcache.head;
8010026b:	8b 45 08             	mov    0x8(%ebp),%eax
8010026e:	c7 40 0c 84 db 10 80 	movl   $0x8010db84,0xc(%eax)
  bcache.head.next->prev = b;
80100275:	a1 94 db 10 80       	mov    0x8010db94,%eax
8010027a:	8b 55 08             	mov    0x8(%ebp),%edx
8010027d:	89 50 0c             	mov    %edx,0xc(%eax)
  bcache.head.next = b;
80100280:	8b 45 08             	mov    0x8(%ebp),%eax
80100283:	a3 94 db 10 80       	mov    %eax,0x8010db94

  b->flags &= ~B_BUSY;
80100288:	8b 45 08             	mov    0x8(%ebp),%eax
8010028b:	8b 00                	mov    (%eax),%eax
8010028d:	89 c2                	mov    %eax,%edx
8010028f:	83 e2 fe             	and    $0xfffffffe,%edx
80100292:	8b 45 08             	mov    0x8(%ebp),%eax
80100295:	89 10                	mov    %edx,(%eax)
  wakeup(b);
80100297:	8b 45 08             	mov    0x8(%ebp),%eax
8010029a:	89 04 24             	mov    %eax,(%esp)
8010029d:	e8 0b 4c 00 00       	call   80104ead <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
801002a9:	e8 a4 4e 00 00       	call   80105152 <release>
}
801002ae:	c9                   	leave  
801002af:	c3                   	ret    

801002b0 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801002b0:	55                   	push   %ebp
801002b1:	89 e5                	mov    %esp,%ebp
801002b3:	53                   	push   %ebx
801002b4:	83 ec 14             	sub    $0x14,%esp
801002b7:	8b 45 08             	mov    0x8(%ebp),%eax
801002ba:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801002be:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
801002c2:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
801002c6:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
801002ca:	ec                   	in     (%dx),%al
801002cb:	89 c3                	mov    %eax,%ebx
801002cd:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
801002d0:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
801002d4:	83 c4 14             	add    $0x14,%esp
801002d7:	5b                   	pop    %ebx
801002d8:	5d                   	pop    %ebp
801002d9:	c3                   	ret    

801002da <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801002da:	55                   	push   %ebp
801002db:	89 e5                	mov    %esp,%ebp
801002dd:	83 ec 08             	sub    $0x8,%esp
801002e0:	8b 55 08             	mov    0x8(%ebp),%edx
801002e3:	8b 45 0c             	mov    0xc(%ebp),%eax
801002e6:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801002ea:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801002ed:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801002f1:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801002f5:	ee                   	out    %al,(%dx)
}
801002f6:	c9                   	leave  
801002f7:	c3                   	ret    

801002f8 <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
801002f8:	55                   	push   %ebp
801002f9:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
801002fb:	fa                   	cli    
}
801002fc:	5d                   	pop    %ebp
801002fd:	c3                   	ret    

801002fe <printint>:
  int locking;
} cons;

static void
printint(int xx, int base, int sign)
{
801002fe:	55                   	push   %ebp
801002ff:	89 e5                	mov    %esp,%ebp
80100301:	83 ec 48             	sub    $0x48,%esp
  static char digits[] = "0123456789abcdef";
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
80100304:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80100308:	74 19                	je     80100323 <printint+0x25>
8010030a:	8b 45 08             	mov    0x8(%ebp),%eax
8010030d:	c1 e8 1f             	shr    $0x1f,%eax
80100310:	89 45 10             	mov    %eax,0x10(%ebp)
80100313:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80100317:	74 0a                	je     80100323 <printint+0x25>
    x = -xx;
80100319:	8b 45 08             	mov    0x8(%ebp),%eax
8010031c:	f7 d8                	neg    %eax
8010031e:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100321:	eb 06                	jmp    80100329 <printint+0x2b>
  else
    x = xx;
80100323:	8b 45 08             	mov    0x8(%ebp),%eax
80100326:	89 45 f0             	mov    %eax,-0x10(%ebp)

  i = 0;
80100329:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  do{
    buf[i++] = digits[x % base];
80100330:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80100333:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100336:	ba 00 00 00 00       	mov    $0x0,%edx
8010033b:	f7 f1                	div    %ecx
8010033d:	89 d0                	mov    %edx,%eax
8010033f:	0f b6 90 04 90 10 80 	movzbl -0x7fef6ffc(%eax),%edx
80100346:	8d 45 e0             	lea    -0x20(%ebp),%eax
80100349:	03 45 f4             	add    -0xc(%ebp),%eax
8010034c:	88 10                	mov    %dl,(%eax)
8010034e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  }while((x /= base) != 0);
80100352:	8b 55 0c             	mov    0xc(%ebp),%edx
80100355:	89 55 d4             	mov    %edx,-0x2c(%ebp)
80100358:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010035b:	ba 00 00 00 00       	mov    $0x0,%edx
80100360:	f7 75 d4             	divl   -0x2c(%ebp)
80100363:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100366:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010036a:	75 c4                	jne    80100330 <printint+0x32>

  if(sign)
8010036c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80100370:	74 23                	je     80100395 <printint+0x97>
    buf[i++] = '-';
80100372:	8d 45 e0             	lea    -0x20(%ebp),%eax
80100375:	03 45 f4             	add    -0xc(%ebp),%eax
80100378:	c6 00 2d             	movb   $0x2d,(%eax)
8010037b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)

  while(--i >= 0)
8010037f:	eb 14                	jmp    80100395 <printint+0x97>
    consputc(buf[i]);
80100381:	8d 45 e0             	lea    -0x20(%ebp),%eax
80100384:	03 45 f4             	add    -0xc(%ebp),%eax
80100387:	0f b6 00             	movzbl (%eax),%eax
8010038a:	0f be c0             	movsbl %al,%eax
8010038d:	89 04 24             	mov    %eax,(%esp)
80100390:	e8 bb 03 00 00       	call   80100750 <consputc>
  }while((x /= base) != 0);

  if(sign)
    buf[i++] = '-';

  while(--i >= 0)
80100395:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
80100399:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010039d:	79 e2                	jns    80100381 <printint+0x83>
    consputc(buf[i]);
}
8010039f:	c9                   	leave  
801003a0:	c3                   	ret    

801003a1 <cprintf>:
//PAGEBREAK: 50

// Print to the console. only understands %d, %x, %p, %s.
void
cprintf(char *fmt, ...)
{
801003a1:	55                   	push   %ebp
801003a2:	89 e5                	mov    %esp,%ebp
801003a4:	83 ec 38             	sub    $0x38,%esp
  int i, c, locking;
  uint *argp;
  char *s;

  locking = cons.locking;
801003a7:	a1 f4 b5 10 80       	mov    0x8010b5f4,%eax
801003ac:	89 45 e8             	mov    %eax,-0x18(%ebp)
  if(locking)
801003af:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801003b3:	74 0c                	je     801003c1 <cprintf+0x20>
    acquire(&cons.lock);
801003b5:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
801003bc:	e8 f6 4c 00 00       	call   801050b7 <acquire>

  if (fmt == 0)
801003c1:	8b 45 08             	mov    0x8(%ebp),%eax
801003c4:	85 c0                	test   %eax,%eax
801003c6:	75 0c                	jne    801003d4 <cprintf+0x33>
    panic("null fmt");
801003c8:	c7 04 24 7a 88 10 80 	movl   $0x8010887a,(%esp)
801003cf:	e8 69 01 00 00       	call   8010053d <panic>

  argp = (uint*)(void*)(&fmt + 1);
801003d4:	8d 45 0c             	lea    0xc(%ebp),%eax
801003d7:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
801003da:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801003e1:	e9 20 01 00 00       	jmp    80100506 <cprintf+0x165>
    if(c != '%'){
801003e6:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
801003ea:	74 10                	je     801003fc <cprintf+0x5b>
      consputc(c);
801003ec:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801003ef:	89 04 24             	mov    %eax,(%esp)
801003f2:	e8 59 03 00 00       	call   80100750 <consputc>
      continue;
801003f7:	e9 06 01 00 00       	jmp    80100502 <cprintf+0x161>
    }
    c = fmt[++i] & 0xff;
801003fc:	8b 55 08             	mov    0x8(%ebp),%edx
801003ff:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100403:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100406:	01 d0                	add    %edx,%eax
80100408:	0f b6 00             	movzbl (%eax),%eax
8010040b:	0f be c0             	movsbl %al,%eax
8010040e:	25 ff 00 00 00       	and    $0xff,%eax
80100413:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(c == 0)
80100416:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
8010041a:	0f 84 08 01 00 00    	je     80100528 <cprintf+0x187>
      break;
    switch(c){
80100420:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100423:	83 f8 70             	cmp    $0x70,%eax
80100426:	74 4d                	je     80100475 <cprintf+0xd4>
80100428:	83 f8 70             	cmp    $0x70,%eax
8010042b:	7f 13                	jg     80100440 <cprintf+0x9f>
8010042d:	83 f8 25             	cmp    $0x25,%eax
80100430:	0f 84 a6 00 00 00    	je     801004dc <cprintf+0x13b>
80100436:	83 f8 64             	cmp    $0x64,%eax
80100439:	74 14                	je     8010044f <cprintf+0xae>
8010043b:	e9 aa 00 00 00       	jmp    801004ea <cprintf+0x149>
80100440:	83 f8 73             	cmp    $0x73,%eax
80100443:	74 53                	je     80100498 <cprintf+0xf7>
80100445:	83 f8 78             	cmp    $0x78,%eax
80100448:	74 2b                	je     80100475 <cprintf+0xd4>
8010044a:	e9 9b 00 00 00       	jmp    801004ea <cprintf+0x149>
    case 'd':
      printint(*argp++, 10, 1);
8010044f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100452:	8b 00                	mov    (%eax),%eax
80100454:	83 45 f0 04          	addl   $0x4,-0x10(%ebp)
80100458:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
8010045f:	00 
80100460:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80100467:	00 
80100468:	89 04 24             	mov    %eax,(%esp)
8010046b:	e8 8e fe ff ff       	call   801002fe <printint>
      break;
80100470:	e9 8d 00 00 00       	jmp    80100502 <cprintf+0x161>
    case 'x':
    case 'p':
      printint(*argp++, 16, 0);
80100475:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100478:	8b 00                	mov    (%eax),%eax
8010047a:	83 45 f0 04          	addl   $0x4,-0x10(%ebp)
8010047e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80100485:	00 
80100486:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
8010048d:	00 
8010048e:	89 04 24             	mov    %eax,(%esp)
80100491:	e8 68 fe ff ff       	call   801002fe <printint>
      break;
80100496:	eb 6a                	jmp    80100502 <cprintf+0x161>
    case 's':
      if((s = (char*)*argp++) == 0)
80100498:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010049b:	8b 00                	mov    (%eax),%eax
8010049d:	89 45 ec             	mov    %eax,-0x14(%ebp)
801004a0:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801004a4:	0f 94 c0             	sete   %al
801004a7:	83 45 f0 04          	addl   $0x4,-0x10(%ebp)
801004ab:	84 c0                	test   %al,%al
801004ad:	74 20                	je     801004cf <cprintf+0x12e>
        s = "(null)";
801004af:	c7 45 ec 83 88 10 80 	movl   $0x80108883,-0x14(%ebp)
      for(; *s; s++)
801004b6:	eb 17                	jmp    801004cf <cprintf+0x12e>
        consputc(*s);
801004b8:	8b 45 ec             	mov    -0x14(%ebp),%eax
801004bb:	0f b6 00             	movzbl (%eax),%eax
801004be:	0f be c0             	movsbl %al,%eax
801004c1:	89 04 24             	mov    %eax,(%esp)
801004c4:	e8 87 02 00 00       	call   80100750 <consputc>
      printint(*argp++, 16, 0);
      break;
    case 's':
      if((s = (char*)*argp++) == 0)
        s = "(null)";
      for(; *s; s++)
801004c9:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
801004cd:	eb 01                	jmp    801004d0 <cprintf+0x12f>
801004cf:	90                   	nop
801004d0:	8b 45 ec             	mov    -0x14(%ebp),%eax
801004d3:	0f b6 00             	movzbl (%eax),%eax
801004d6:	84 c0                	test   %al,%al
801004d8:	75 de                	jne    801004b8 <cprintf+0x117>
        consputc(*s);
      break;
801004da:	eb 26                	jmp    80100502 <cprintf+0x161>
    case '%':
      consputc('%');
801004dc:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
801004e3:	e8 68 02 00 00       	call   80100750 <consputc>
      break;
801004e8:	eb 18                	jmp    80100502 <cprintf+0x161>
    default:
      // Print unknown % sequence to draw attention.
      consputc('%');
801004ea:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
801004f1:	e8 5a 02 00 00       	call   80100750 <consputc>
      consputc(c);
801004f6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801004f9:	89 04 24             	mov    %eax,(%esp)
801004fc:	e8 4f 02 00 00       	call   80100750 <consputc>
      break;
80100501:	90                   	nop

  if (fmt == 0)
    panic("null fmt");

  argp = (uint*)(void*)(&fmt + 1);
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
80100502:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100506:	8b 55 08             	mov    0x8(%ebp),%edx
80100509:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010050c:	01 d0                	add    %edx,%eax
8010050e:	0f b6 00             	movzbl (%eax),%eax
80100511:	0f be c0             	movsbl %al,%eax
80100514:	25 ff 00 00 00       	and    $0xff,%eax
80100519:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010051c:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80100520:	0f 85 c0 fe ff ff    	jne    801003e6 <cprintf+0x45>
80100526:	eb 01                	jmp    80100529 <cprintf+0x188>
      consputc(c);
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
80100528:	90                   	nop
      consputc(c);
      break;
    }
  }

  if(locking)
80100529:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
8010052d:	74 0c                	je     8010053b <cprintf+0x19a>
    release(&cons.lock);
8010052f:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100536:	e8 17 4c 00 00       	call   80105152 <release>
}
8010053b:	c9                   	leave  
8010053c:	c3                   	ret    

8010053d <panic>:

void
panic(char *s)
{
8010053d:	55                   	push   %ebp
8010053e:	89 e5                	mov    %esp,%ebp
80100540:	83 ec 48             	sub    $0x48,%esp
  int i;
  uint pcs[10];
  
  cli();
80100543:	e8 b0 fd ff ff       	call   801002f8 <cli>
  cons.locking = 0;
80100548:	c7 05 f4 b5 10 80 00 	movl   $0x0,0x8010b5f4
8010054f:	00 00 00 
  cprintf("cpu%d: panic: ", cpu->id);
80100552:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80100558:	0f b6 00             	movzbl (%eax),%eax
8010055b:	0f b6 c0             	movzbl %al,%eax
8010055e:	89 44 24 04          	mov    %eax,0x4(%esp)
80100562:	c7 04 24 8a 88 10 80 	movl   $0x8010888a,(%esp)
80100569:	e8 33 fe ff ff       	call   801003a1 <cprintf>
  cprintf(s);
8010056e:	8b 45 08             	mov    0x8(%ebp),%eax
80100571:	89 04 24             	mov    %eax,(%esp)
80100574:	e8 28 fe ff ff       	call   801003a1 <cprintf>
  cprintf("\n");
80100579:	c7 04 24 99 88 10 80 	movl   $0x80108899,(%esp)
80100580:	e8 1c fe ff ff       	call   801003a1 <cprintf>
  getcallerpcs(&s, pcs);
80100585:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100588:	89 44 24 04          	mov    %eax,0x4(%esp)
8010058c:	8d 45 08             	lea    0x8(%ebp),%eax
8010058f:	89 04 24             	mov    %eax,(%esp)
80100592:	e8 0a 4c 00 00       	call   801051a1 <getcallerpcs>
  for(i=0; i<10; i++)
80100597:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010059e:	eb 1b                	jmp    801005bb <panic+0x7e>
    cprintf(" %p", pcs[i]);
801005a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005a3:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005a7:	89 44 24 04          	mov    %eax,0x4(%esp)
801005ab:	c7 04 24 9b 88 10 80 	movl   $0x8010889b,(%esp)
801005b2:	e8 ea fd ff ff       	call   801003a1 <cprintf>
  cons.locking = 0;
  cprintf("cpu%d: panic: ", cpu->id);
  cprintf(s);
  cprintf("\n");
  getcallerpcs(&s, pcs);
  for(i=0; i<10; i++)
801005b7:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801005bb:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
801005bf:	7e df                	jle    801005a0 <panic+0x63>
    cprintf(" %p", pcs[i]);
  panicked = 1; // freeze other CPU
801005c1:	c7 05 a0 b5 10 80 01 	movl   $0x1,0x8010b5a0
801005c8:	00 00 00 
  for(;;)
    ;
801005cb:	eb fe                	jmp    801005cb <panic+0x8e>

801005cd <cgaputc>:
#define CRTPORT 0x3d4
static ushort *crt = (ushort*)P2V(0xb8000);  // CGA memory

static void
cgaputc(int c)
{
801005cd:	55                   	push   %ebp
801005ce:	89 e5                	mov    %esp,%ebp
801005d0:	83 ec 28             	sub    $0x28,%esp
  int pos;
  
  // Cursor position: col + 80*row.
  outb(CRTPORT, 14);
801005d3:	c7 44 24 04 0e 00 00 	movl   $0xe,0x4(%esp)
801005da:	00 
801005db:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
801005e2:	e8 f3 fc ff ff       	call   801002da <outb>
  pos = inb(CRTPORT+1) << 8;
801005e7:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
801005ee:	e8 bd fc ff ff       	call   801002b0 <inb>
801005f3:	0f b6 c0             	movzbl %al,%eax
801005f6:	c1 e0 08             	shl    $0x8,%eax
801005f9:	89 45 f4             	mov    %eax,-0xc(%ebp)
  outb(CRTPORT, 15);
801005fc:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80100603:	00 
80100604:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
8010060b:	e8 ca fc ff ff       	call   801002da <outb>
  pos |= inb(CRTPORT+1);
80100610:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
80100617:	e8 94 fc ff ff       	call   801002b0 <inb>
8010061c:	0f b6 c0             	movzbl %al,%eax
8010061f:	09 45 f4             	or     %eax,-0xc(%ebp)

  if(c == '\n')
80100622:	83 7d 08 0a          	cmpl   $0xa,0x8(%ebp)
80100626:	75 30                	jne    80100658 <cgaputc+0x8b>
    pos += 80 - pos%80;
80100628:	8b 4d f4             	mov    -0xc(%ebp),%ecx
8010062b:	ba 67 66 66 66       	mov    $0x66666667,%edx
80100630:	89 c8                	mov    %ecx,%eax
80100632:	f7 ea                	imul   %edx
80100634:	c1 fa 05             	sar    $0x5,%edx
80100637:	89 c8                	mov    %ecx,%eax
80100639:	c1 f8 1f             	sar    $0x1f,%eax
8010063c:	29 c2                	sub    %eax,%edx
8010063e:	89 d0                	mov    %edx,%eax
80100640:	c1 e0 02             	shl    $0x2,%eax
80100643:	01 d0                	add    %edx,%eax
80100645:	c1 e0 04             	shl    $0x4,%eax
80100648:	89 ca                	mov    %ecx,%edx
8010064a:	29 c2                	sub    %eax,%edx
8010064c:	b8 50 00 00 00       	mov    $0x50,%eax
80100651:	29 d0                	sub    %edx,%eax
80100653:	01 45 f4             	add    %eax,-0xc(%ebp)
80100656:	eb 32                	jmp    8010068a <cgaputc+0xbd>
  else if(c == BACKSPACE){
80100658:	81 7d 08 00 01 00 00 	cmpl   $0x100,0x8(%ebp)
8010065f:	75 0c                	jne    8010066d <cgaputc+0xa0>
    if(pos > 0) --pos;
80100661:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100665:	7e 23                	jle    8010068a <cgaputc+0xbd>
80100667:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
8010066b:	eb 1d                	jmp    8010068a <cgaputc+0xbd>
  } else
    crt[pos++] = (c&0xff) | 0x0700;  // black on white
8010066d:	a1 00 90 10 80       	mov    0x80109000,%eax
80100672:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100675:	01 d2                	add    %edx,%edx
80100677:	01 c2                	add    %eax,%edx
80100679:	8b 45 08             	mov    0x8(%ebp),%eax
8010067c:	66 25 ff 00          	and    $0xff,%ax
80100680:	80 cc 07             	or     $0x7,%ah
80100683:	66 89 02             	mov    %ax,(%edx)
80100686:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  
  if((pos/80) >= 24){  // Scroll up.
8010068a:	81 7d f4 7f 07 00 00 	cmpl   $0x77f,-0xc(%ebp)
80100691:	7e 53                	jle    801006e6 <cgaputc+0x119>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
80100693:	a1 00 90 10 80       	mov    0x80109000,%eax
80100698:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
8010069e:	a1 00 90 10 80       	mov    0x80109000,%eax
801006a3:	c7 44 24 08 60 0e 00 	movl   $0xe60,0x8(%esp)
801006aa:	00 
801006ab:	89 54 24 04          	mov    %edx,0x4(%esp)
801006af:	89 04 24             	mov    %eax,(%esp)
801006b2:	e8 5a 4d 00 00       	call   80105411 <memmove>
    pos -= 80;
801006b7:	83 6d f4 50          	subl   $0x50,-0xc(%ebp)
    memset(crt+pos, 0, sizeof(crt[0])*(24*80 - pos));
801006bb:	b8 80 07 00 00       	mov    $0x780,%eax
801006c0:	2b 45 f4             	sub    -0xc(%ebp),%eax
801006c3:	01 c0                	add    %eax,%eax
801006c5:	8b 15 00 90 10 80    	mov    0x80109000,%edx
801006cb:	8b 4d f4             	mov    -0xc(%ebp),%ecx
801006ce:	01 c9                	add    %ecx,%ecx
801006d0:	01 ca                	add    %ecx,%edx
801006d2:	89 44 24 08          	mov    %eax,0x8(%esp)
801006d6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801006dd:	00 
801006de:	89 14 24             	mov    %edx,(%esp)
801006e1:	e8 58 4c 00 00       	call   8010533e <memset>
  }
  
  outb(CRTPORT, 14);
801006e6:	c7 44 24 04 0e 00 00 	movl   $0xe,0x4(%esp)
801006ed:	00 
801006ee:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
801006f5:	e8 e0 fb ff ff       	call   801002da <outb>
  outb(CRTPORT+1, pos>>8);
801006fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801006fd:	c1 f8 08             	sar    $0x8,%eax
80100700:	0f b6 c0             	movzbl %al,%eax
80100703:	89 44 24 04          	mov    %eax,0x4(%esp)
80100707:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
8010070e:	e8 c7 fb ff ff       	call   801002da <outb>
  outb(CRTPORT, 15);
80100713:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
8010071a:	00 
8010071b:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
80100722:	e8 b3 fb ff ff       	call   801002da <outb>
  outb(CRTPORT+1, pos);
80100727:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010072a:	0f b6 c0             	movzbl %al,%eax
8010072d:	89 44 24 04          	mov    %eax,0x4(%esp)
80100731:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
80100738:	e8 9d fb ff ff       	call   801002da <outb>
  crt[pos] = ' ' | 0x0700;
8010073d:	a1 00 90 10 80       	mov    0x80109000,%eax
80100742:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100745:	01 d2                	add    %edx,%edx
80100747:	01 d0                	add    %edx,%eax
80100749:	66 c7 00 20 07       	movw   $0x720,(%eax)
}
8010074e:	c9                   	leave  
8010074f:	c3                   	ret    

80100750 <consputc>:

void
consputc(int c)
{
80100750:	55                   	push   %ebp
80100751:	89 e5                	mov    %esp,%ebp
80100753:	83 ec 18             	sub    $0x18,%esp
  if(panicked){
80100756:	a1 a0 b5 10 80       	mov    0x8010b5a0,%eax
8010075b:	85 c0                	test   %eax,%eax
8010075d:	74 07                	je     80100766 <consputc+0x16>
    cli();
8010075f:	e8 94 fb ff ff       	call   801002f8 <cli>
    for(;;)
      ;
80100764:	eb fe                	jmp    80100764 <consputc+0x14>
  }

  if(c == BACKSPACE){
80100766:	81 7d 08 00 01 00 00 	cmpl   $0x100,0x8(%ebp)
8010076d:	75 26                	jne    80100795 <consputc+0x45>
    uartputc('\b'); uartputc(' '); uartputc('\b');
8010076f:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100776:	e8 3e 67 00 00       	call   80106eb9 <uartputc>
8010077b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80100782:	e8 32 67 00 00       	call   80106eb9 <uartputc>
80100787:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
8010078e:	e8 26 67 00 00       	call   80106eb9 <uartputc>
80100793:	eb 0b                	jmp    801007a0 <consputc+0x50>
  } else
    uartputc(c);
80100795:	8b 45 08             	mov    0x8(%ebp),%eax
80100798:	89 04 24             	mov    %eax,(%esp)
8010079b:	e8 19 67 00 00       	call   80106eb9 <uartputc>
  cgaputc(c);
801007a0:	8b 45 08             	mov    0x8(%ebp),%eax
801007a3:	89 04 24             	mov    %eax,(%esp)
801007a6:	e8 22 fe ff ff       	call   801005cd <cgaputc>
}
801007ab:	c9                   	leave  
801007ac:	c3                   	ret    

801007ad <consoleintr>:

#define C(x)  ((x)-'@')  // Control-x

void
consoleintr(int (*getc)(void))
{
801007ad:	55                   	push   %ebp
801007ae:	89 e5                	mov    %esp,%ebp
801007b0:	83 ec 28             	sub    $0x28,%esp
  int c;

  acquire(&input.lock);
801007b3:	c7 04 24 a0 dd 10 80 	movl   $0x8010dda0,(%esp)
801007ba:	e8 f8 48 00 00       	call   801050b7 <acquire>
  while((c = getc()) >= 0){
801007bf:	e9 41 01 00 00       	jmp    80100905 <consoleintr+0x158>
    switch(c){
801007c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801007c7:	83 f8 10             	cmp    $0x10,%eax
801007ca:	74 1e                	je     801007ea <consoleintr+0x3d>
801007cc:	83 f8 10             	cmp    $0x10,%eax
801007cf:	7f 0a                	jg     801007db <consoleintr+0x2e>
801007d1:	83 f8 08             	cmp    $0x8,%eax
801007d4:	74 68                	je     8010083e <consoleintr+0x91>
801007d6:	e9 94 00 00 00       	jmp    8010086f <consoleintr+0xc2>
801007db:	83 f8 15             	cmp    $0x15,%eax
801007de:	74 2f                	je     8010080f <consoleintr+0x62>
801007e0:	83 f8 7f             	cmp    $0x7f,%eax
801007e3:	74 59                	je     8010083e <consoleintr+0x91>
801007e5:	e9 85 00 00 00       	jmp    8010086f <consoleintr+0xc2>
    case C('P'):  // Process listing.
      procdump();
801007ea:	e8 64 47 00 00       	call   80104f53 <procdump>
      break;
801007ef:	e9 11 01 00 00       	jmp    80100905 <consoleintr+0x158>
    case C('U'):  // Kill line.
      while(input.e != input.w &&
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
801007f4:	a1 5c de 10 80       	mov    0x8010de5c,%eax
801007f9:	83 e8 01             	sub    $0x1,%eax
801007fc:	a3 5c de 10 80       	mov    %eax,0x8010de5c
        consputc(BACKSPACE);
80100801:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
80100808:	e8 43 ff ff ff       	call   80100750 <consputc>
8010080d:	eb 01                	jmp    80100810 <consoleintr+0x63>
    switch(c){
    case C('P'):  // Process listing.
      procdump();
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
8010080f:	90                   	nop
80100810:	8b 15 5c de 10 80    	mov    0x8010de5c,%edx
80100816:	a1 58 de 10 80       	mov    0x8010de58,%eax
8010081b:	39 c2                	cmp    %eax,%edx
8010081d:	0f 84 db 00 00 00    	je     801008fe <consoleintr+0x151>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
80100823:	a1 5c de 10 80       	mov    0x8010de5c,%eax
80100828:	83 e8 01             	sub    $0x1,%eax
8010082b:	83 e0 7f             	and    $0x7f,%eax
8010082e:	0f b6 80 d4 dd 10 80 	movzbl -0x7fef222c(%eax),%eax
    switch(c){
    case C('P'):  // Process listing.
      procdump();
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
80100835:	3c 0a                	cmp    $0xa,%al
80100837:	75 bb                	jne    801007f4 <consoleintr+0x47>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
        consputc(BACKSPACE);
      }
      break;
80100839:	e9 c0 00 00 00       	jmp    801008fe <consoleintr+0x151>
    case C('H'): case '\x7f':  // Backspace
      if(input.e != input.w){
8010083e:	8b 15 5c de 10 80    	mov    0x8010de5c,%edx
80100844:	a1 58 de 10 80       	mov    0x8010de58,%eax
80100849:	39 c2                	cmp    %eax,%edx
8010084b:	0f 84 b0 00 00 00    	je     80100901 <consoleintr+0x154>
        input.e--;
80100851:	a1 5c de 10 80       	mov    0x8010de5c,%eax
80100856:	83 e8 01             	sub    $0x1,%eax
80100859:	a3 5c de 10 80       	mov    %eax,0x8010de5c
        consputc(BACKSPACE);
8010085e:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
80100865:	e8 e6 fe ff ff       	call   80100750 <consputc>
      }
      break;
8010086a:	e9 92 00 00 00       	jmp    80100901 <consoleintr+0x154>
    default:
      if(c != 0 && input.e-input.r < INPUT_BUF){
8010086f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100873:	0f 84 8b 00 00 00    	je     80100904 <consoleintr+0x157>
80100879:	8b 15 5c de 10 80    	mov    0x8010de5c,%edx
8010087f:	a1 54 de 10 80       	mov    0x8010de54,%eax
80100884:	89 d1                	mov    %edx,%ecx
80100886:	29 c1                	sub    %eax,%ecx
80100888:	89 c8                	mov    %ecx,%eax
8010088a:	83 f8 7f             	cmp    $0x7f,%eax
8010088d:	77 75                	ja     80100904 <consoleintr+0x157>
        c = (c == '\r') ? '\n' : c;
8010088f:	83 7d f4 0d          	cmpl   $0xd,-0xc(%ebp)
80100893:	74 05                	je     8010089a <consoleintr+0xed>
80100895:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100898:	eb 05                	jmp    8010089f <consoleintr+0xf2>
8010089a:	b8 0a 00 00 00       	mov    $0xa,%eax
8010089f:	89 45 f4             	mov    %eax,-0xc(%ebp)
        input.buf[input.e++ % INPUT_BUF] = c;
801008a2:	a1 5c de 10 80       	mov    0x8010de5c,%eax
801008a7:	89 c1                	mov    %eax,%ecx
801008a9:	83 e1 7f             	and    $0x7f,%ecx
801008ac:	8b 55 f4             	mov    -0xc(%ebp),%edx
801008af:	88 91 d4 dd 10 80    	mov    %dl,-0x7fef222c(%ecx)
801008b5:	83 c0 01             	add    $0x1,%eax
801008b8:	a3 5c de 10 80       	mov    %eax,0x8010de5c
        consputc(c);
801008bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801008c0:	89 04 24             	mov    %eax,(%esp)
801008c3:	e8 88 fe ff ff       	call   80100750 <consputc>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
801008c8:	83 7d f4 0a          	cmpl   $0xa,-0xc(%ebp)
801008cc:	74 18                	je     801008e6 <consoleintr+0x139>
801008ce:	83 7d f4 04          	cmpl   $0x4,-0xc(%ebp)
801008d2:	74 12                	je     801008e6 <consoleintr+0x139>
801008d4:	a1 5c de 10 80       	mov    0x8010de5c,%eax
801008d9:	8b 15 54 de 10 80    	mov    0x8010de54,%edx
801008df:	83 ea 80             	sub    $0xffffff80,%edx
801008e2:	39 d0                	cmp    %edx,%eax
801008e4:	75 1e                	jne    80100904 <consoleintr+0x157>
          input.w = input.e;
801008e6:	a1 5c de 10 80       	mov    0x8010de5c,%eax
801008eb:	a3 58 de 10 80       	mov    %eax,0x8010de58
          wakeup(&input.r);
801008f0:	c7 04 24 54 de 10 80 	movl   $0x8010de54,(%esp)
801008f7:	e8 b1 45 00 00       	call   80104ead <wakeup>
        }
      }
      break;
801008fc:	eb 06                	jmp    80100904 <consoleintr+0x157>
      while(input.e != input.w &&
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
        consputc(BACKSPACE);
      }
      break;
801008fe:	90                   	nop
801008ff:	eb 04                	jmp    80100905 <consoleintr+0x158>
    case C('H'): case '\x7f':  // Backspace
      if(input.e != input.w){
        input.e--;
        consputc(BACKSPACE);
      }
      break;
80100901:	90                   	nop
80100902:	eb 01                	jmp    80100905 <consoleintr+0x158>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
          input.w = input.e;
          wakeup(&input.r);
        }
      }
      break;
80100904:	90                   	nop
consoleintr(int (*getc)(void))
{
  int c;

  acquire(&input.lock);
  while((c = getc()) >= 0){
80100905:	8b 45 08             	mov    0x8(%ebp),%eax
80100908:	ff d0                	call   *%eax
8010090a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010090d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100911:	0f 89 ad fe ff ff    	jns    801007c4 <consoleintr+0x17>
        }
      }
      break;
    }
  }
  release(&input.lock);
80100917:	c7 04 24 a0 dd 10 80 	movl   $0x8010dda0,(%esp)
8010091e:	e8 2f 48 00 00       	call   80105152 <release>
}
80100923:	c9                   	leave  
80100924:	c3                   	ret    

80100925 <consoleread>:

int
consoleread(struct inode *ip, char *dst, int n)
{
80100925:	55                   	push   %ebp
80100926:	89 e5                	mov    %esp,%ebp
80100928:	83 ec 28             	sub    $0x28,%esp
  uint target;
  int c;

  iunlock(ip);
8010092b:	8b 45 08             	mov    0x8(%ebp),%eax
8010092e:	89 04 24             	mov    %eax,(%esp)
80100931:	e8 80 10 00 00       	call   801019b6 <iunlock>
  target = n;
80100936:	8b 45 10             	mov    0x10(%ebp),%eax
80100939:	89 45 f4             	mov    %eax,-0xc(%ebp)
  acquire(&input.lock);
8010093c:	c7 04 24 a0 dd 10 80 	movl   $0x8010dda0,(%esp)
80100943:	e8 6f 47 00 00       	call   801050b7 <acquire>
  while(n > 0){
80100948:	e9 a8 00 00 00       	jmp    801009f5 <consoleread+0xd0>
    while(input.r == input.w){
      if(proc->killed){
8010094d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100953:	8b 40 24             	mov    0x24(%eax),%eax
80100956:	85 c0                	test   %eax,%eax
80100958:	74 21                	je     8010097b <consoleread+0x56>
        release(&input.lock);
8010095a:	c7 04 24 a0 dd 10 80 	movl   $0x8010dda0,(%esp)
80100961:	e8 ec 47 00 00       	call   80105152 <release>
        ilock(ip);
80100966:	8b 45 08             	mov    0x8(%ebp),%eax
80100969:	89 04 24             	mov    %eax,(%esp)
8010096c:	e8 f7 0e 00 00       	call   80101868 <ilock>
        return -1;
80100971:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100976:	e9 a9 00 00 00       	jmp    80100a24 <consoleread+0xff>
      }
      sleep(&input.r, &input.lock);
8010097b:	c7 44 24 04 a0 dd 10 	movl   $0x8010dda0,0x4(%esp)
80100982:	80 
80100983:	c7 04 24 54 de 10 80 	movl   $0x8010de54,(%esp)
8010098a:	e8 bb 43 00 00       	call   80104d4a <sleep>
8010098f:	eb 01                	jmp    80100992 <consoleread+0x6d>

  iunlock(ip);
  target = n;
  acquire(&input.lock);
  while(n > 0){
    while(input.r == input.w){
80100991:	90                   	nop
80100992:	8b 15 54 de 10 80    	mov    0x8010de54,%edx
80100998:	a1 58 de 10 80       	mov    0x8010de58,%eax
8010099d:	39 c2                	cmp    %eax,%edx
8010099f:	74 ac                	je     8010094d <consoleread+0x28>
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &input.lock);
    }
    c = input.buf[input.r++ % INPUT_BUF];
801009a1:	a1 54 de 10 80       	mov    0x8010de54,%eax
801009a6:	89 c2                	mov    %eax,%edx
801009a8:	83 e2 7f             	and    $0x7f,%edx
801009ab:	0f b6 92 d4 dd 10 80 	movzbl -0x7fef222c(%edx),%edx
801009b2:	0f be d2             	movsbl %dl,%edx
801009b5:	89 55 f0             	mov    %edx,-0x10(%ebp)
801009b8:	83 c0 01             	add    $0x1,%eax
801009bb:	a3 54 de 10 80       	mov    %eax,0x8010de54
    if(c == C('D')){  // EOF
801009c0:	83 7d f0 04          	cmpl   $0x4,-0x10(%ebp)
801009c4:	75 17                	jne    801009dd <consoleread+0xb8>
      if(n < target){
801009c6:	8b 45 10             	mov    0x10(%ebp),%eax
801009c9:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801009cc:	73 2f                	jae    801009fd <consoleread+0xd8>
        // Save ^D for next time, to make sure
        // caller gets a 0-byte result.
        input.r--;
801009ce:	a1 54 de 10 80       	mov    0x8010de54,%eax
801009d3:	83 e8 01             	sub    $0x1,%eax
801009d6:	a3 54 de 10 80       	mov    %eax,0x8010de54
      }
      break;
801009db:	eb 20                	jmp    801009fd <consoleread+0xd8>
    }
    *dst++ = c;
801009dd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801009e0:	89 c2                	mov    %eax,%edx
801009e2:	8b 45 0c             	mov    0xc(%ebp),%eax
801009e5:	88 10                	mov    %dl,(%eax)
801009e7:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
    --n;
801009eb:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
    if(c == '\n')
801009ef:	83 7d f0 0a          	cmpl   $0xa,-0x10(%ebp)
801009f3:	74 0b                	je     80100a00 <consoleread+0xdb>
  int c;

  iunlock(ip);
  target = n;
  acquire(&input.lock);
  while(n > 0){
801009f5:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801009f9:	7f 96                	jg     80100991 <consoleread+0x6c>
801009fb:	eb 04                	jmp    80100a01 <consoleread+0xdc>
      if(n < target){
        // Save ^D for next time, to make sure
        // caller gets a 0-byte result.
        input.r--;
      }
      break;
801009fd:	90                   	nop
801009fe:	eb 01                	jmp    80100a01 <consoleread+0xdc>
    }
    *dst++ = c;
    --n;
    if(c == '\n')
      break;
80100a00:	90                   	nop
  }
  release(&input.lock);
80100a01:	c7 04 24 a0 dd 10 80 	movl   $0x8010dda0,(%esp)
80100a08:	e8 45 47 00 00       	call   80105152 <release>
  ilock(ip);
80100a0d:	8b 45 08             	mov    0x8(%ebp),%eax
80100a10:	89 04 24             	mov    %eax,(%esp)
80100a13:	e8 50 0e 00 00       	call   80101868 <ilock>

  return target - n;
80100a18:	8b 45 10             	mov    0x10(%ebp),%eax
80100a1b:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100a1e:	89 d1                	mov    %edx,%ecx
80100a20:	29 c1                	sub    %eax,%ecx
80100a22:	89 c8                	mov    %ecx,%eax
}
80100a24:	c9                   	leave  
80100a25:	c3                   	ret    

80100a26 <consolewrite>:

int
consolewrite(struct inode *ip, char *buf, int n)
{
80100a26:	55                   	push   %ebp
80100a27:	89 e5                	mov    %esp,%ebp
80100a29:	83 ec 28             	sub    $0x28,%esp
  int i;

  iunlock(ip);
80100a2c:	8b 45 08             	mov    0x8(%ebp),%eax
80100a2f:	89 04 24             	mov    %eax,(%esp)
80100a32:	e8 7f 0f 00 00       	call   801019b6 <iunlock>
  acquire(&cons.lock);
80100a37:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100a3e:	e8 74 46 00 00       	call   801050b7 <acquire>
  for(i = 0; i < n; i++)
80100a43:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80100a4a:	eb 1d                	jmp    80100a69 <consolewrite+0x43>
    consputc(buf[i] & 0xff);
80100a4c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100a4f:	03 45 0c             	add    0xc(%ebp),%eax
80100a52:	0f b6 00             	movzbl (%eax),%eax
80100a55:	0f be c0             	movsbl %al,%eax
80100a58:	25 ff 00 00 00       	and    $0xff,%eax
80100a5d:	89 04 24             	mov    %eax,(%esp)
80100a60:	e8 eb fc ff ff       	call   80100750 <consputc>
{
  int i;

  iunlock(ip);
  acquire(&cons.lock);
  for(i = 0; i < n; i++)
80100a65:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100a69:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100a6c:	3b 45 10             	cmp    0x10(%ebp),%eax
80100a6f:	7c db                	jl     80100a4c <consolewrite+0x26>
    consputc(buf[i] & 0xff);
  release(&cons.lock);
80100a71:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100a78:	e8 d5 46 00 00       	call   80105152 <release>
  ilock(ip);
80100a7d:	8b 45 08             	mov    0x8(%ebp),%eax
80100a80:	89 04 24             	mov    %eax,(%esp)
80100a83:	e8 e0 0d 00 00       	call   80101868 <ilock>

  return n;
80100a88:	8b 45 10             	mov    0x10(%ebp),%eax
}
80100a8b:	c9                   	leave  
80100a8c:	c3                   	ret    

80100a8d <consoleinit>:

void
consoleinit(void)
{
80100a8d:	55                   	push   %ebp
80100a8e:	89 e5                	mov    %esp,%ebp
80100a90:	83 ec 18             	sub    $0x18,%esp
  initlock(&cons.lock, "console");
80100a93:	c7 44 24 04 9f 88 10 	movl   $0x8010889f,0x4(%esp)
80100a9a:	80 
80100a9b:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100aa2:	e8 ef 45 00 00       	call   80105096 <initlock>
  initlock(&input.lock, "input");
80100aa7:	c7 44 24 04 a7 88 10 	movl   $0x801088a7,0x4(%esp)
80100aae:	80 
80100aaf:	c7 04 24 a0 dd 10 80 	movl   $0x8010dda0,(%esp)
80100ab6:	e8 db 45 00 00       	call   80105096 <initlock>

  devsw[CONSOLE].write = consolewrite;
80100abb:	c7 05 0c e8 10 80 26 	movl   $0x80100a26,0x8010e80c
80100ac2:	0a 10 80 
  devsw[CONSOLE].read = consoleread;
80100ac5:	c7 05 08 e8 10 80 25 	movl   $0x80100925,0x8010e808
80100acc:	09 10 80 
  cons.locking = 1;
80100acf:	c7 05 f4 b5 10 80 01 	movl   $0x1,0x8010b5f4
80100ad6:	00 00 00 

  picenable(IRQ_KBD);
80100ad9:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100ae0:	e8 e8 2f 00 00       	call   80103acd <picenable>
  ioapicenable(IRQ_KBD, 0);
80100ae5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80100aec:	00 
80100aed:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100af4:	e8 89 1e 00 00       	call   80102982 <ioapicenable>
}
80100af9:	c9                   	leave  
80100afa:	c3                   	ret    
	...

80100afc <exec>:
#include "x86.h"
#include "elf.h"

int
exec(char *path, char **argv)
{
80100afc:	55                   	push   %ebp
80100afd:	89 e5                	mov    %esp,%ebp
80100aff:	81 ec 38 01 00 00    	sub    $0x138,%esp
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pde_t *pgdir, *oldpgdir;

  if((ip = namei(path)) == 0)
80100b05:	8b 45 08             	mov    0x8(%ebp),%eax
80100b08:	89 04 24             	mov    %eax,(%esp)
80100b0b:	e8 fa 18 00 00       	call   8010240a <namei>
80100b10:	89 45 d8             	mov    %eax,-0x28(%ebp)
80100b13:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100b17:	75 0a                	jne    80100b23 <exec+0x27>
    return -1;
80100b19:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100b1e:	e9 da 03 00 00       	jmp    80100efd <exec+0x401>
  ilock(ip);
80100b23:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100b26:	89 04 24             	mov    %eax,(%esp)
80100b29:	e8 3a 0d 00 00       	call   80101868 <ilock>
  pgdir = 0;
80100b2e:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) < sizeof(elf))
80100b35:	c7 44 24 0c 34 00 00 	movl   $0x34,0xc(%esp)
80100b3c:	00 
80100b3d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80100b44:	00 
80100b45:	8d 85 0c ff ff ff    	lea    -0xf4(%ebp),%eax
80100b4b:	89 44 24 04          	mov    %eax,0x4(%esp)
80100b4f:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100b52:	89 04 24             	mov    %eax,(%esp)
80100b55:	e8 04 12 00 00       	call   80101d5e <readi>
80100b5a:	83 f8 33             	cmp    $0x33,%eax
80100b5d:	0f 86 54 03 00 00    	jbe    80100eb7 <exec+0x3bb>
    goto bad;
  if(elf.magic != ELF_MAGIC)
80100b63:	8b 85 0c ff ff ff    	mov    -0xf4(%ebp),%eax
80100b69:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
80100b6e:	0f 85 46 03 00 00    	jne    80100eba <exec+0x3be>
    goto bad;

  if((pgdir = setupkvm(kalloc)) == 0)
80100b74:	c7 04 24 0b 2b 10 80 	movl   $0x80102b0b,(%esp)
80100b7b:	e8 7d 74 00 00       	call   80107ffd <setupkvm>
80100b80:	89 45 d4             	mov    %eax,-0x2c(%ebp)
80100b83:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100b87:	0f 84 30 03 00 00    	je     80100ebd <exec+0x3c1>
    goto bad;

  // Load program into memory.
  sz = 0;
80100b8d:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100b94:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80100b9b:	8b 85 28 ff ff ff    	mov    -0xd8(%ebp),%eax
80100ba1:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100ba4:	e9 c5 00 00 00       	jmp    80100c6e <exec+0x172>
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
80100ba9:	8b 45 e8             	mov    -0x18(%ebp),%eax
80100bac:	c7 44 24 0c 20 00 00 	movl   $0x20,0xc(%esp)
80100bb3:	00 
80100bb4:	89 44 24 08          	mov    %eax,0x8(%esp)
80100bb8:	8d 85 ec fe ff ff    	lea    -0x114(%ebp),%eax
80100bbe:	89 44 24 04          	mov    %eax,0x4(%esp)
80100bc2:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100bc5:	89 04 24             	mov    %eax,(%esp)
80100bc8:	e8 91 11 00 00       	call   80101d5e <readi>
80100bcd:	83 f8 20             	cmp    $0x20,%eax
80100bd0:	0f 85 ea 02 00 00    	jne    80100ec0 <exec+0x3c4>
      goto bad;
    if(ph.type != ELF_PROG_LOAD)
80100bd6:	8b 85 ec fe ff ff    	mov    -0x114(%ebp),%eax
80100bdc:	83 f8 01             	cmp    $0x1,%eax
80100bdf:	75 7f                	jne    80100c60 <exec+0x164>
      continue;
    if(ph.memsz < ph.filesz)
80100be1:	8b 95 00 ff ff ff    	mov    -0x100(%ebp),%edx
80100be7:	8b 85 fc fe ff ff    	mov    -0x104(%ebp),%eax
80100bed:	39 c2                	cmp    %eax,%edx
80100bef:	0f 82 ce 02 00 00    	jb     80100ec3 <exec+0x3c7>
      goto bad;
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
80100bf5:	8b 95 f4 fe ff ff    	mov    -0x10c(%ebp),%edx
80100bfb:	8b 85 00 ff ff ff    	mov    -0x100(%ebp),%eax
80100c01:	01 d0                	add    %edx,%eax
80100c03:	89 44 24 08          	mov    %eax,0x8(%esp)
80100c07:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100c0a:	89 44 24 04          	mov    %eax,0x4(%esp)
80100c0e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100c11:	89 04 24             	mov    %eax,(%esp)
80100c14:	e8 b6 77 00 00       	call   801083cf <allocuvm>
80100c19:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100c1c:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100c20:	0f 84 a0 02 00 00    	je     80100ec6 <exec+0x3ca>
      goto bad;
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
80100c26:	8b 8d fc fe ff ff    	mov    -0x104(%ebp),%ecx
80100c2c:	8b 95 f0 fe ff ff    	mov    -0x110(%ebp),%edx
80100c32:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
80100c38:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80100c3c:	89 54 24 0c          	mov    %edx,0xc(%esp)
80100c40:	8b 55 d8             	mov    -0x28(%ebp),%edx
80100c43:	89 54 24 08          	mov    %edx,0x8(%esp)
80100c47:	89 44 24 04          	mov    %eax,0x4(%esp)
80100c4b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100c4e:	89 04 24             	mov    %eax,(%esp)
80100c51:	e8 8a 76 00 00       	call   801082e0 <loaduvm>
80100c56:	85 c0                	test   %eax,%eax
80100c58:	0f 88 6b 02 00 00    	js     80100ec9 <exec+0x3cd>
80100c5e:	eb 01                	jmp    80100c61 <exec+0x165>
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
      goto bad;
    if(ph.type != ELF_PROG_LOAD)
      continue;
80100c60:	90                   	nop
  if((pgdir = setupkvm(kalloc)) == 0)
    goto bad;

  // Load program into memory.
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100c61:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
80100c65:	8b 45 e8             	mov    -0x18(%ebp),%eax
80100c68:	83 c0 20             	add    $0x20,%eax
80100c6b:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100c6e:	0f b7 85 38 ff ff ff 	movzwl -0xc8(%ebp),%eax
80100c75:	0f b7 c0             	movzwl %ax,%eax
80100c78:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80100c7b:	0f 8f 28 ff ff ff    	jg     80100ba9 <exec+0xad>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
      goto bad;
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
      goto bad;
  }
  iunlockput(ip);
80100c81:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100c84:	89 04 24             	mov    %eax,(%esp)
80100c87:	e8 60 0e 00 00       	call   80101aec <iunlockput>
  ip = 0;
80100c8c:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)

  // Allocate two pages at the next page boundary.
  // Make the first inaccessible.  Use the second as the user stack.
  sz = PGROUNDUP(sz);
80100c93:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100c96:	05 ff 0f 00 00       	add    $0xfff,%eax
80100c9b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80100ca0:	89 45 e0             	mov    %eax,-0x20(%ebp)
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80100ca3:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100ca6:	05 00 20 00 00       	add    $0x2000,%eax
80100cab:	89 44 24 08          	mov    %eax,0x8(%esp)
80100caf:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100cb2:	89 44 24 04          	mov    %eax,0x4(%esp)
80100cb6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100cb9:	89 04 24             	mov    %eax,(%esp)
80100cbc:	e8 0e 77 00 00       	call   801083cf <allocuvm>
80100cc1:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100cc4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100cc8:	0f 84 fe 01 00 00    	je     80100ecc <exec+0x3d0>
    goto bad;
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100cce:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100cd1:	2d 00 20 00 00       	sub    $0x2000,%eax
80100cd6:	89 44 24 04          	mov    %eax,0x4(%esp)
80100cda:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100cdd:	89 04 24             	mov    %eax,(%esp)
80100ce0:	e8 0e 79 00 00       	call   801085f3 <clearpteu>
  sp = sz;
80100ce5:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100ce8:	89 45 dc             	mov    %eax,-0x24(%ebp)

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100ceb:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80100cf2:	e9 81 00 00 00       	jmp    80100d78 <exec+0x27c>
    if(argc >= MAXARG)
80100cf7:	83 7d e4 1f          	cmpl   $0x1f,-0x1c(%ebp)
80100cfb:	0f 87 ce 01 00 00    	ja     80100ecf <exec+0x3d3>
      goto bad;
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
80100d01:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d04:	c1 e0 02             	shl    $0x2,%eax
80100d07:	03 45 0c             	add    0xc(%ebp),%eax
80100d0a:	8b 00                	mov    (%eax),%eax
80100d0c:	89 04 24             	mov    %eax,(%esp)
80100d0f:	e8 a8 48 00 00       	call   801055bc <strlen>
80100d14:	f7 d0                	not    %eax
80100d16:	03 45 dc             	add    -0x24(%ebp),%eax
80100d19:	83 e0 fc             	and    $0xfffffffc,%eax
80100d1c:	89 45 dc             	mov    %eax,-0x24(%ebp)
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100d1f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d22:	c1 e0 02             	shl    $0x2,%eax
80100d25:	03 45 0c             	add    0xc(%ebp),%eax
80100d28:	8b 00                	mov    (%eax),%eax
80100d2a:	89 04 24             	mov    %eax,(%esp)
80100d2d:	e8 8a 48 00 00       	call   801055bc <strlen>
80100d32:	83 c0 01             	add    $0x1,%eax
80100d35:	89 c2                	mov    %eax,%edx
80100d37:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d3a:	c1 e0 02             	shl    $0x2,%eax
80100d3d:	03 45 0c             	add    0xc(%ebp),%eax
80100d40:	8b 00                	mov    (%eax),%eax
80100d42:	89 54 24 0c          	mov    %edx,0xc(%esp)
80100d46:	89 44 24 08          	mov    %eax,0x8(%esp)
80100d4a:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100d4d:	89 44 24 04          	mov    %eax,0x4(%esp)
80100d51:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100d54:	89 04 24             	mov    %eax,(%esp)
80100d57:	e8 4b 7a 00 00       	call   801087a7 <copyout>
80100d5c:	85 c0                	test   %eax,%eax
80100d5e:	0f 88 6e 01 00 00    	js     80100ed2 <exec+0x3d6>
      goto bad;
    ustack[3+argc] = sp;
80100d64:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d67:	8d 50 03             	lea    0x3(%eax),%edx
80100d6a:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100d6d:	89 84 95 40 ff ff ff 	mov    %eax,-0xc0(%ebp,%edx,4)
    goto bad;
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
  sp = sz;

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100d74:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80100d78:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d7b:	c1 e0 02             	shl    $0x2,%eax
80100d7e:	03 45 0c             	add    0xc(%ebp),%eax
80100d81:	8b 00                	mov    (%eax),%eax
80100d83:	85 c0                	test   %eax,%eax
80100d85:	0f 85 6c ff ff ff    	jne    80100cf7 <exec+0x1fb>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
    ustack[3+argc] = sp;
  }
  ustack[3+argc] = 0;
80100d8b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d8e:	83 c0 03             	add    $0x3,%eax
80100d91:	c7 84 85 40 ff ff ff 	movl   $0x0,-0xc0(%ebp,%eax,4)
80100d98:	00 00 00 00 

  ustack[0] = 0xffffffff;  // fake return PC
80100d9c:	c7 85 40 ff ff ff ff 	movl   $0xffffffff,-0xc0(%ebp)
80100da3:	ff ff ff 
  ustack[1] = argc;
80100da6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100da9:	89 85 44 ff ff ff    	mov    %eax,-0xbc(%ebp)
  ustack[2] = sp - (argc+1)*4;  // argv pointer
80100daf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100db2:	83 c0 01             	add    $0x1,%eax
80100db5:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100dbc:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100dbf:	29 d0                	sub    %edx,%eax
80100dc1:	89 85 48 ff ff ff    	mov    %eax,-0xb8(%ebp)

  sp -= (3+argc+1) * 4;
80100dc7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dca:	83 c0 04             	add    $0x4,%eax
80100dcd:	c1 e0 02             	shl    $0x2,%eax
80100dd0:	29 45 dc             	sub    %eax,-0x24(%ebp)
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
80100dd3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dd6:	83 c0 04             	add    $0x4,%eax
80100dd9:	c1 e0 02             	shl    $0x2,%eax
80100ddc:	89 44 24 0c          	mov    %eax,0xc(%esp)
80100de0:	8d 85 40 ff ff ff    	lea    -0xc0(%ebp),%eax
80100de6:	89 44 24 08          	mov    %eax,0x8(%esp)
80100dea:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100ded:	89 44 24 04          	mov    %eax,0x4(%esp)
80100df1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100df4:	89 04 24             	mov    %eax,(%esp)
80100df7:	e8 ab 79 00 00       	call   801087a7 <copyout>
80100dfc:	85 c0                	test   %eax,%eax
80100dfe:	0f 88 d1 00 00 00    	js     80100ed5 <exec+0x3d9>
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100e04:	8b 45 08             	mov    0x8(%ebp),%eax
80100e07:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100e0a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e0d:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100e10:	eb 17                	jmp    80100e29 <exec+0x32d>
    if(*s == '/')
80100e12:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e15:	0f b6 00             	movzbl (%eax),%eax
80100e18:	3c 2f                	cmp    $0x2f,%al
80100e1a:	75 09                	jne    80100e25 <exec+0x329>
      last = s+1;
80100e1c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e1f:	83 c0 01             	add    $0x1,%eax
80100e22:	89 45 f0             	mov    %eax,-0x10(%ebp)
  sp -= (3+argc+1) * 4;
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100e25:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100e29:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e2c:	0f b6 00             	movzbl (%eax),%eax
80100e2f:	84 c0                	test   %al,%al
80100e31:	75 df                	jne    80100e12 <exec+0x316>
    if(*s == '/')
      last = s+1;
  safestrcpy(proc->name, last, sizeof(proc->name));
80100e33:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e39:	8d 50 6c             	lea    0x6c(%eax),%edx
80100e3c:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80100e43:	00 
80100e44:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100e47:	89 44 24 04          	mov    %eax,0x4(%esp)
80100e4b:	89 14 24             	mov    %edx,(%esp)
80100e4e:	e8 1b 47 00 00       	call   8010556e <safestrcpy>

  // Commit to the user image.
  oldpgdir = proc->pgdir;
80100e53:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e59:	8b 40 04             	mov    0x4(%eax),%eax
80100e5c:	89 45 d0             	mov    %eax,-0x30(%ebp)
  proc->pgdir = pgdir;
80100e5f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e65:	8b 55 d4             	mov    -0x2c(%ebp),%edx
80100e68:	89 50 04             	mov    %edx,0x4(%eax)
  proc->sz = sz;
80100e6b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e71:	8b 55 e0             	mov    -0x20(%ebp),%edx
80100e74:	89 10                	mov    %edx,(%eax)
  proc->tf->eip = elf.entry;  // main
80100e76:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e7c:	8b 40 18             	mov    0x18(%eax),%eax
80100e7f:	8b 95 24 ff ff ff    	mov    -0xdc(%ebp),%edx
80100e85:	89 50 38             	mov    %edx,0x38(%eax)
  proc->tf->esp = sp;
80100e88:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e8e:	8b 40 18             	mov    0x18(%eax),%eax
80100e91:	8b 55 dc             	mov    -0x24(%ebp),%edx
80100e94:	89 50 44             	mov    %edx,0x44(%eax)
  switchuvm(proc);
80100e97:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e9d:	89 04 24             	mov    %eax,(%esp)
80100ea0:	e8 49 72 00 00       	call   801080ee <switchuvm>
  freevm(oldpgdir);
80100ea5:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100ea8:	89 04 24             	mov    %eax,(%esp)
80100eab:	e8 b5 76 00 00       	call   80108565 <freevm>
  return 0;
80100eb0:	b8 00 00 00 00       	mov    $0x0,%eax
80100eb5:	eb 46                	jmp    80100efd <exec+0x401>
  ilock(ip);
  pgdir = 0;

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) < sizeof(elf))
    goto bad;
80100eb7:	90                   	nop
80100eb8:	eb 1c                	jmp    80100ed6 <exec+0x3da>
  if(elf.magic != ELF_MAGIC)
    goto bad;
80100eba:	90                   	nop
80100ebb:	eb 19                	jmp    80100ed6 <exec+0x3da>

  if((pgdir = setupkvm(kalloc)) == 0)
    goto bad;
80100ebd:	90                   	nop
80100ebe:	eb 16                	jmp    80100ed6 <exec+0x3da>

  // Load program into memory.
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
      goto bad;
80100ec0:	90                   	nop
80100ec1:	eb 13                	jmp    80100ed6 <exec+0x3da>
    if(ph.type != ELF_PROG_LOAD)
      continue;
    if(ph.memsz < ph.filesz)
      goto bad;
80100ec3:	90                   	nop
80100ec4:	eb 10                	jmp    80100ed6 <exec+0x3da>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
      goto bad;
80100ec6:	90                   	nop
80100ec7:	eb 0d                	jmp    80100ed6 <exec+0x3da>
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
      goto bad;
80100ec9:	90                   	nop
80100eca:	eb 0a                	jmp    80100ed6 <exec+0x3da>

  // Allocate two pages at the next page boundary.
  // Make the first inaccessible.  Use the second as the user stack.
  sz = PGROUNDUP(sz);
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
    goto bad;
80100ecc:	90                   	nop
80100ecd:	eb 07                	jmp    80100ed6 <exec+0x3da>
  sp = sz;

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
    if(argc >= MAXARG)
      goto bad;
80100ecf:	90                   	nop
80100ed0:	eb 04                	jmp    80100ed6 <exec+0x3da>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
80100ed2:	90                   	nop
80100ed3:	eb 01                	jmp    80100ed6 <exec+0x3da>
  ustack[1] = argc;
  ustack[2] = sp - (argc+1)*4;  // argv pointer

  sp -= (3+argc+1) * 4;
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
    goto bad;
80100ed5:	90                   	nop
  switchuvm(proc);
  freevm(oldpgdir);
  return 0;

 bad:
  if(pgdir)
80100ed6:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100eda:	74 0b                	je     80100ee7 <exec+0x3eb>
    freevm(pgdir);
80100edc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100edf:	89 04 24             	mov    %eax,(%esp)
80100ee2:	e8 7e 76 00 00       	call   80108565 <freevm>
  if(ip)
80100ee7:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100eeb:	74 0b                	je     80100ef8 <exec+0x3fc>
    iunlockput(ip);
80100eed:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100ef0:	89 04 24             	mov    %eax,(%esp)
80100ef3:	e8 f4 0b 00 00       	call   80101aec <iunlockput>
  return -1;
80100ef8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80100efd:	c9                   	leave  
80100efe:	c3                   	ret    
	...

80100f00 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
80100f00:	55                   	push   %ebp
80100f01:	89 e5                	mov    %esp,%ebp
80100f03:	83 ec 18             	sub    $0x18,%esp
  initlock(&ftable.lock, "ftable");
80100f06:	c7 44 24 04 ad 88 10 	movl   $0x801088ad,0x4(%esp)
80100f0d:	80 
80100f0e:	c7 04 24 60 de 10 80 	movl   $0x8010de60,(%esp)
80100f15:	e8 7c 41 00 00       	call   80105096 <initlock>
}
80100f1a:	c9                   	leave  
80100f1b:	c3                   	ret    

80100f1c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
80100f1c:	55                   	push   %ebp
80100f1d:	89 e5                	mov    %esp,%ebp
80100f1f:	83 ec 28             	sub    $0x28,%esp
  struct file *f;

  acquire(&ftable.lock);
80100f22:	c7 04 24 60 de 10 80 	movl   $0x8010de60,(%esp)
80100f29:	e8 89 41 00 00       	call   801050b7 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100f2e:	c7 45 f4 94 de 10 80 	movl   $0x8010de94,-0xc(%ebp)
80100f35:	eb 29                	jmp    80100f60 <filealloc+0x44>
    if(f->ref == 0){
80100f37:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f3a:	8b 40 04             	mov    0x4(%eax),%eax
80100f3d:	85 c0                	test   %eax,%eax
80100f3f:	75 1b                	jne    80100f5c <filealloc+0x40>
      f->ref = 1;
80100f41:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f44:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
      release(&ftable.lock);
80100f4b:	c7 04 24 60 de 10 80 	movl   $0x8010de60,(%esp)
80100f52:	e8 fb 41 00 00       	call   80105152 <release>
      return f;
80100f57:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f5a:	eb 1e                	jmp    80100f7a <filealloc+0x5e>
filealloc(void)
{
  struct file *f;

  acquire(&ftable.lock);
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100f5c:	83 45 f4 18          	addl   $0x18,-0xc(%ebp)
80100f60:	81 7d f4 f4 e7 10 80 	cmpl   $0x8010e7f4,-0xc(%ebp)
80100f67:	72 ce                	jb     80100f37 <filealloc+0x1b>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
80100f69:	c7 04 24 60 de 10 80 	movl   $0x8010de60,(%esp)
80100f70:	e8 dd 41 00 00       	call   80105152 <release>
  return 0;
80100f75:	b8 00 00 00 00       	mov    $0x0,%eax
}
80100f7a:	c9                   	leave  
80100f7b:	c3                   	ret    

80100f7c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
80100f7c:	55                   	push   %ebp
80100f7d:	89 e5                	mov    %esp,%ebp
80100f7f:	83 ec 18             	sub    $0x18,%esp
  acquire(&ftable.lock);
80100f82:	c7 04 24 60 de 10 80 	movl   $0x8010de60,(%esp)
80100f89:	e8 29 41 00 00       	call   801050b7 <acquire>
  if(f->ref < 1)
80100f8e:	8b 45 08             	mov    0x8(%ebp),%eax
80100f91:	8b 40 04             	mov    0x4(%eax),%eax
80100f94:	85 c0                	test   %eax,%eax
80100f96:	7f 0c                	jg     80100fa4 <filedup+0x28>
    panic("filedup");
80100f98:	c7 04 24 b4 88 10 80 	movl   $0x801088b4,(%esp)
80100f9f:	e8 99 f5 ff ff       	call   8010053d <panic>
  f->ref++;
80100fa4:	8b 45 08             	mov    0x8(%ebp),%eax
80100fa7:	8b 40 04             	mov    0x4(%eax),%eax
80100faa:	8d 50 01             	lea    0x1(%eax),%edx
80100fad:	8b 45 08             	mov    0x8(%ebp),%eax
80100fb0:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
80100fb3:	c7 04 24 60 de 10 80 	movl   $0x8010de60,(%esp)
80100fba:	e8 93 41 00 00       	call   80105152 <release>
  return f;
80100fbf:	8b 45 08             	mov    0x8(%ebp),%eax
}
80100fc2:	c9                   	leave  
80100fc3:	c3                   	ret    

80100fc4 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
80100fc4:	55                   	push   %ebp
80100fc5:	89 e5                	mov    %esp,%ebp
80100fc7:	83 ec 38             	sub    $0x38,%esp
  struct file ff;

  acquire(&ftable.lock);
80100fca:	c7 04 24 60 de 10 80 	movl   $0x8010de60,(%esp)
80100fd1:	e8 e1 40 00 00       	call   801050b7 <acquire>
  if(f->ref < 1)
80100fd6:	8b 45 08             	mov    0x8(%ebp),%eax
80100fd9:	8b 40 04             	mov    0x4(%eax),%eax
80100fdc:	85 c0                	test   %eax,%eax
80100fde:	7f 0c                	jg     80100fec <fileclose+0x28>
    panic("fileclose");
80100fe0:	c7 04 24 bc 88 10 80 	movl   $0x801088bc,(%esp)
80100fe7:	e8 51 f5 ff ff       	call   8010053d <panic>
  if(--f->ref > 0){
80100fec:	8b 45 08             	mov    0x8(%ebp),%eax
80100fef:	8b 40 04             	mov    0x4(%eax),%eax
80100ff2:	8d 50 ff             	lea    -0x1(%eax),%edx
80100ff5:	8b 45 08             	mov    0x8(%ebp),%eax
80100ff8:	89 50 04             	mov    %edx,0x4(%eax)
80100ffb:	8b 45 08             	mov    0x8(%ebp),%eax
80100ffe:	8b 40 04             	mov    0x4(%eax),%eax
80101001:	85 c0                	test   %eax,%eax
80101003:	7e 11                	jle    80101016 <fileclose+0x52>
    release(&ftable.lock);
80101005:	c7 04 24 60 de 10 80 	movl   $0x8010de60,(%esp)
8010100c:	e8 41 41 00 00       	call   80105152 <release>
    return;
80101011:	e9 82 00 00 00       	jmp    80101098 <fileclose+0xd4>
  }
  ff = *f;
80101016:	8b 45 08             	mov    0x8(%ebp),%eax
80101019:	8b 10                	mov    (%eax),%edx
8010101b:	89 55 e0             	mov    %edx,-0x20(%ebp)
8010101e:	8b 50 04             	mov    0x4(%eax),%edx
80101021:	89 55 e4             	mov    %edx,-0x1c(%ebp)
80101024:	8b 50 08             	mov    0x8(%eax),%edx
80101027:	89 55 e8             	mov    %edx,-0x18(%ebp)
8010102a:	8b 50 0c             	mov    0xc(%eax),%edx
8010102d:	89 55 ec             	mov    %edx,-0x14(%ebp)
80101030:	8b 50 10             	mov    0x10(%eax),%edx
80101033:	89 55 f0             	mov    %edx,-0x10(%ebp)
80101036:	8b 40 14             	mov    0x14(%eax),%eax
80101039:	89 45 f4             	mov    %eax,-0xc(%ebp)
  f->ref = 0;
8010103c:	8b 45 08             	mov    0x8(%ebp),%eax
8010103f:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
  f->type = FD_NONE;
80101046:	8b 45 08             	mov    0x8(%ebp),%eax
80101049:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  release(&ftable.lock);
8010104f:	c7 04 24 60 de 10 80 	movl   $0x8010de60,(%esp)
80101056:	e8 f7 40 00 00       	call   80105152 <release>
  
  if(ff.type == FD_PIPE)
8010105b:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010105e:	83 f8 01             	cmp    $0x1,%eax
80101061:	75 18                	jne    8010107b <fileclose+0xb7>
    pipeclose(ff.pipe, ff.writable);
80101063:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
80101067:	0f be d0             	movsbl %al,%edx
8010106a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010106d:	89 54 24 04          	mov    %edx,0x4(%esp)
80101071:	89 04 24             	mov    %eax,(%esp)
80101074:	e8 0e 2d 00 00       	call   80103d87 <pipeclose>
80101079:	eb 1d                	jmp    80101098 <fileclose+0xd4>
  else if(ff.type == FD_INODE){
8010107b:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010107e:	83 f8 02             	cmp    $0x2,%eax
80101081:	75 15                	jne    80101098 <fileclose+0xd4>
    begin_trans();
80101083:	e8 a1 21 00 00       	call   80103229 <begin_trans>
    iput(ff.ip);
80101088:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010108b:	89 04 24             	mov    %eax,(%esp)
8010108e:	e8 88 09 00 00       	call   80101a1b <iput>
    commit_trans();
80101093:	e8 da 21 00 00       	call   80103272 <commit_trans>
  }
}
80101098:	c9                   	leave  
80101099:	c3                   	ret    

8010109a <filestat>:

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
8010109a:	55                   	push   %ebp
8010109b:	89 e5                	mov    %esp,%ebp
8010109d:	83 ec 18             	sub    $0x18,%esp
  if(f->type == FD_INODE){
801010a0:	8b 45 08             	mov    0x8(%ebp),%eax
801010a3:	8b 00                	mov    (%eax),%eax
801010a5:	83 f8 02             	cmp    $0x2,%eax
801010a8:	75 38                	jne    801010e2 <filestat+0x48>
    ilock(f->ip);
801010aa:	8b 45 08             	mov    0x8(%ebp),%eax
801010ad:	8b 40 10             	mov    0x10(%eax),%eax
801010b0:	89 04 24             	mov    %eax,(%esp)
801010b3:	e8 b0 07 00 00       	call   80101868 <ilock>
    stati(f->ip, st);
801010b8:	8b 45 08             	mov    0x8(%ebp),%eax
801010bb:	8b 40 10             	mov    0x10(%eax),%eax
801010be:	8b 55 0c             	mov    0xc(%ebp),%edx
801010c1:	89 54 24 04          	mov    %edx,0x4(%esp)
801010c5:	89 04 24             	mov    %eax,(%esp)
801010c8:	e8 4c 0c 00 00       	call   80101d19 <stati>
    iunlock(f->ip);
801010cd:	8b 45 08             	mov    0x8(%ebp),%eax
801010d0:	8b 40 10             	mov    0x10(%eax),%eax
801010d3:	89 04 24             	mov    %eax,(%esp)
801010d6:	e8 db 08 00 00       	call   801019b6 <iunlock>
    return 0;
801010db:	b8 00 00 00 00       	mov    $0x0,%eax
801010e0:	eb 05                	jmp    801010e7 <filestat+0x4d>
  }
  return -1;
801010e2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801010e7:	c9                   	leave  
801010e8:	c3                   	ret    

801010e9 <fileread>:

// Read from file f.
int
fileread(struct file *f, char *addr, int n)
{
801010e9:	55                   	push   %ebp
801010ea:	89 e5                	mov    %esp,%ebp
801010ec:	83 ec 28             	sub    $0x28,%esp
  int r;

  if(f->readable == 0)
801010ef:	8b 45 08             	mov    0x8(%ebp),%eax
801010f2:	0f b6 40 08          	movzbl 0x8(%eax),%eax
801010f6:	84 c0                	test   %al,%al
801010f8:	75 0a                	jne    80101104 <fileread+0x1b>
    return -1;
801010fa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801010ff:	e9 9f 00 00 00       	jmp    801011a3 <fileread+0xba>
  if(f->type == FD_PIPE)
80101104:	8b 45 08             	mov    0x8(%ebp),%eax
80101107:	8b 00                	mov    (%eax),%eax
80101109:	83 f8 01             	cmp    $0x1,%eax
8010110c:	75 1e                	jne    8010112c <fileread+0x43>
    return piperead(f->pipe, addr, n);
8010110e:	8b 45 08             	mov    0x8(%ebp),%eax
80101111:	8b 40 0c             	mov    0xc(%eax),%eax
80101114:	8b 55 10             	mov    0x10(%ebp),%edx
80101117:	89 54 24 08          	mov    %edx,0x8(%esp)
8010111b:	8b 55 0c             	mov    0xc(%ebp),%edx
8010111e:	89 54 24 04          	mov    %edx,0x4(%esp)
80101122:	89 04 24             	mov    %eax,(%esp)
80101125:	e8 df 2d 00 00       	call   80103f09 <piperead>
8010112a:	eb 77                	jmp    801011a3 <fileread+0xba>
  if(f->type == FD_INODE){
8010112c:	8b 45 08             	mov    0x8(%ebp),%eax
8010112f:	8b 00                	mov    (%eax),%eax
80101131:	83 f8 02             	cmp    $0x2,%eax
80101134:	75 61                	jne    80101197 <fileread+0xae>
    ilock(f->ip);
80101136:	8b 45 08             	mov    0x8(%ebp),%eax
80101139:	8b 40 10             	mov    0x10(%eax),%eax
8010113c:	89 04 24             	mov    %eax,(%esp)
8010113f:	e8 24 07 00 00       	call   80101868 <ilock>
    if((r = readi(f->ip, addr, f->off, n)) > 0)
80101144:	8b 4d 10             	mov    0x10(%ebp),%ecx
80101147:	8b 45 08             	mov    0x8(%ebp),%eax
8010114a:	8b 50 14             	mov    0x14(%eax),%edx
8010114d:	8b 45 08             	mov    0x8(%ebp),%eax
80101150:	8b 40 10             	mov    0x10(%eax),%eax
80101153:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80101157:	89 54 24 08          	mov    %edx,0x8(%esp)
8010115b:	8b 55 0c             	mov    0xc(%ebp),%edx
8010115e:	89 54 24 04          	mov    %edx,0x4(%esp)
80101162:	89 04 24             	mov    %eax,(%esp)
80101165:	e8 f4 0b 00 00       	call   80101d5e <readi>
8010116a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010116d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101171:	7e 11                	jle    80101184 <fileread+0x9b>
      f->off += r;
80101173:	8b 45 08             	mov    0x8(%ebp),%eax
80101176:	8b 50 14             	mov    0x14(%eax),%edx
80101179:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010117c:	01 c2                	add    %eax,%edx
8010117e:	8b 45 08             	mov    0x8(%ebp),%eax
80101181:	89 50 14             	mov    %edx,0x14(%eax)
    iunlock(f->ip);
80101184:	8b 45 08             	mov    0x8(%ebp),%eax
80101187:	8b 40 10             	mov    0x10(%eax),%eax
8010118a:	89 04 24             	mov    %eax,(%esp)
8010118d:	e8 24 08 00 00       	call   801019b6 <iunlock>
    return r;
80101192:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101195:	eb 0c                	jmp    801011a3 <fileread+0xba>
  }
  panic("fileread");
80101197:	c7 04 24 c6 88 10 80 	movl   $0x801088c6,(%esp)
8010119e:	e8 9a f3 ff ff       	call   8010053d <panic>
}
801011a3:	c9                   	leave  
801011a4:	c3                   	ret    

801011a5 <filewrite>:

//PAGEBREAK!
// Write to file f.
int
filewrite(struct file *f, char *addr, int n)
{
801011a5:	55                   	push   %ebp
801011a6:	89 e5                	mov    %esp,%ebp
801011a8:	53                   	push   %ebx
801011a9:	83 ec 24             	sub    $0x24,%esp
  int r;

  if(f->writable == 0)
801011ac:	8b 45 08             	mov    0x8(%ebp),%eax
801011af:	0f b6 40 09          	movzbl 0x9(%eax),%eax
801011b3:	84 c0                	test   %al,%al
801011b5:	75 0a                	jne    801011c1 <filewrite+0x1c>
    return -1;
801011b7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801011bc:	e9 23 01 00 00       	jmp    801012e4 <filewrite+0x13f>
  if(f->type == FD_PIPE)
801011c1:	8b 45 08             	mov    0x8(%ebp),%eax
801011c4:	8b 00                	mov    (%eax),%eax
801011c6:	83 f8 01             	cmp    $0x1,%eax
801011c9:	75 21                	jne    801011ec <filewrite+0x47>
    return pipewrite(f->pipe, addr, n);
801011cb:	8b 45 08             	mov    0x8(%ebp),%eax
801011ce:	8b 40 0c             	mov    0xc(%eax),%eax
801011d1:	8b 55 10             	mov    0x10(%ebp),%edx
801011d4:	89 54 24 08          	mov    %edx,0x8(%esp)
801011d8:	8b 55 0c             	mov    0xc(%ebp),%edx
801011db:	89 54 24 04          	mov    %edx,0x4(%esp)
801011df:	89 04 24             	mov    %eax,(%esp)
801011e2:	e8 32 2c 00 00       	call   80103e19 <pipewrite>
801011e7:	e9 f8 00 00 00       	jmp    801012e4 <filewrite+0x13f>
  if(f->type == FD_INODE){
801011ec:	8b 45 08             	mov    0x8(%ebp),%eax
801011ef:	8b 00                	mov    (%eax),%eax
801011f1:	83 f8 02             	cmp    $0x2,%eax
801011f4:	0f 85 de 00 00 00    	jne    801012d8 <filewrite+0x133>
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
801011fa:	c7 45 ec 00 06 00 00 	movl   $0x600,-0x14(%ebp)
    int i = 0;
80101201:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while(i < n){
80101208:	e9 a8 00 00 00       	jmp    801012b5 <filewrite+0x110>
      int n1 = n - i;
8010120d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101210:	8b 55 10             	mov    0x10(%ebp),%edx
80101213:	89 d1                	mov    %edx,%ecx
80101215:	29 c1                	sub    %eax,%ecx
80101217:	89 c8                	mov    %ecx,%eax
80101219:	89 45 f0             	mov    %eax,-0x10(%ebp)
      if(n1 > max)
8010121c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010121f:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80101222:	7e 06                	jle    8010122a <filewrite+0x85>
        n1 = max;
80101224:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101227:	89 45 f0             	mov    %eax,-0x10(%ebp)

      begin_trans();
8010122a:	e8 fa 1f 00 00       	call   80103229 <begin_trans>
      ilock(f->ip);
8010122f:	8b 45 08             	mov    0x8(%ebp),%eax
80101232:	8b 40 10             	mov    0x10(%eax),%eax
80101235:	89 04 24             	mov    %eax,(%esp)
80101238:	e8 2b 06 00 00       	call   80101868 <ilock>
      if ((r = writei(f->ip, addr + i, f->off, n1)) > 0)
8010123d:	8b 5d f0             	mov    -0x10(%ebp),%ebx
80101240:	8b 45 08             	mov    0x8(%ebp),%eax
80101243:	8b 48 14             	mov    0x14(%eax),%ecx
80101246:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101249:	89 c2                	mov    %eax,%edx
8010124b:	03 55 0c             	add    0xc(%ebp),%edx
8010124e:	8b 45 08             	mov    0x8(%ebp),%eax
80101251:	8b 40 10             	mov    0x10(%eax),%eax
80101254:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
80101258:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010125c:	89 54 24 04          	mov    %edx,0x4(%esp)
80101260:	89 04 24             	mov    %eax,(%esp)
80101263:	e8 61 0c 00 00       	call   80101ec9 <writei>
80101268:	89 45 e8             	mov    %eax,-0x18(%ebp)
8010126b:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
8010126f:	7e 11                	jle    80101282 <filewrite+0xdd>
        f->off += r;
80101271:	8b 45 08             	mov    0x8(%ebp),%eax
80101274:	8b 50 14             	mov    0x14(%eax),%edx
80101277:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010127a:	01 c2                	add    %eax,%edx
8010127c:	8b 45 08             	mov    0x8(%ebp),%eax
8010127f:	89 50 14             	mov    %edx,0x14(%eax)
      iunlock(f->ip);
80101282:	8b 45 08             	mov    0x8(%ebp),%eax
80101285:	8b 40 10             	mov    0x10(%eax),%eax
80101288:	89 04 24             	mov    %eax,(%esp)
8010128b:	e8 26 07 00 00       	call   801019b6 <iunlock>
      commit_trans();
80101290:	e8 dd 1f 00 00       	call   80103272 <commit_trans>

      if(r < 0)
80101295:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80101299:	78 28                	js     801012c3 <filewrite+0x11e>
        break;
      if(r != n1)
8010129b:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010129e:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801012a1:	74 0c                	je     801012af <filewrite+0x10a>
        panic("short filewrite");
801012a3:	c7 04 24 cf 88 10 80 	movl   $0x801088cf,(%esp)
801012aa:	e8 8e f2 ff ff       	call   8010053d <panic>
      i += r;
801012af:	8b 45 e8             	mov    -0x18(%ebp),%eax
801012b2:	01 45 f4             	add    %eax,-0xc(%ebp)
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
    int i = 0;
    while(i < n){
801012b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801012b8:	3b 45 10             	cmp    0x10(%ebp),%eax
801012bb:	0f 8c 4c ff ff ff    	jl     8010120d <filewrite+0x68>
801012c1:	eb 01                	jmp    801012c4 <filewrite+0x11f>
        f->off += r;
      iunlock(f->ip);
      commit_trans();

      if(r < 0)
        break;
801012c3:	90                   	nop
      if(r != n1)
        panic("short filewrite");
      i += r;
    }
    return i == n ? n : -1;
801012c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801012c7:	3b 45 10             	cmp    0x10(%ebp),%eax
801012ca:	75 05                	jne    801012d1 <filewrite+0x12c>
801012cc:	8b 45 10             	mov    0x10(%ebp),%eax
801012cf:	eb 05                	jmp    801012d6 <filewrite+0x131>
801012d1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801012d6:	eb 0c                	jmp    801012e4 <filewrite+0x13f>
  }
  panic("filewrite");
801012d8:	c7 04 24 df 88 10 80 	movl   $0x801088df,(%esp)
801012df:	e8 59 f2 ff ff       	call   8010053d <panic>
}
801012e4:	83 c4 24             	add    $0x24,%esp
801012e7:	5b                   	pop    %ebx
801012e8:	5d                   	pop    %ebp
801012e9:	c3                   	ret    
	...

801012ec <readsb>:
static void itrunc(struct inode*);

// Read the super block.
void
readsb(int dev, struct superblock *sb)
{
801012ec:	55                   	push   %ebp
801012ed:	89 e5                	mov    %esp,%ebp
801012ef:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, 1);
801012f2:	8b 45 08             	mov    0x8(%ebp),%eax
801012f5:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801012fc:	00 
801012fd:	89 04 24             	mov    %eax,(%esp)
80101300:	e8 a1 ee ff ff       	call   801001a6 <bread>
80101305:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memmove(sb, bp->data, sizeof(*sb));
80101308:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010130b:	83 c0 18             	add    $0x18,%eax
8010130e:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80101315:	00 
80101316:	89 44 24 04          	mov    %eax,0x4(%esp)
8010131a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010131d:	89 04 24             	mov    %eax,(%esp)
80101320:	e8 ec 40 00 00       	call   80105411 <memmove>
  brelse(bp);
80101325:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101328:	89 04 24             	mov    %eax,(%esp)
8010132b:	e8 e7 ee ff ff       	call   80100217 <brelse>
}
80101330:	c9                   	leave  
80101331:	c3                   	ret    

80101332 <bzero>:

// Zero a block.
static void
bzero(int dev, int bno)
{
80101332:	55                   	push   %ebp
80101333:	89 e5                	mov    %esp,%ebp
80101335:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, bno);
80101338:	8b 55 0c             	mov    0xc(%ebp),%edx
8010133b:	8b 45 08             	mov    0x8(%ebp),%eax
8010133e:	89 54 24 04          	mov    %edx,0x4(%esp)
80101342:	89 04 24             	mov    %eax,(%esp)
80101345:	e8 5c ee ff ff       	call   801001a6 <bread>
8010134a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(bp->data, 0, BSIZE);
8010134d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101350:	83 c0 18             	add    $0x18,%eax
80101353:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
8010135a:	00 
8010135b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80101362:	00 
80101363:	89 04 24             	mov    %eax,(%esp)
80101366:	e8 d3 3f 00 00       	call   8010533e <memset>
  log_write(bp);
8010136b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010136e:	89 04 24             	mov    %eax,(%esp)
80101371:	e8 54 1f 00 00       	call   801032ca <log_write>
  brelse(bp);
80101376:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101379:	89 04 24             	mov    %eax,(%esp)
8010137c:	e8 96 ee ff ff       	call   80100217 <brelse>
}
80101381:	c9                   	leave  
80101382:	c3                   	ret    

80101383 <balloc>:
// Blocks. 

// Allocate a zeroed disk block.
static uint
balloc(uint dev)
{
80101383:	55                   	push   %ebp
80101384:	89 e5                	mov    %esp,%ebp
80101386:	53                   	push   %ebx
80101387:	83 ec 34             	sub    $0x34,%esp
  int b, bi, m;
  struct buf *bp;
  struct superblock sb;

  bp = 0;
8010138a:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  readsb(dev, &sb);
80101391:	8b 45 08             	mov    0x8(%ebp),%eax
80101394:	8d 55 d8             	lea    -0x28(%ebp),%edx
80101397:	89 54 24 04          	mov    %edx,0x4(%esp)
8010139b:	89 04 24             	mov    %eax,(%esp)
8010139e:	e8 49 ff ff ff       	call   801012ec <readsb>
  for(b = 0; b < sb.size; b += BPB){
801013a3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801013aa:	e9 11 01 00 00       	jmp    801014c0 <balloc+0x13d>
    bp = bread(dev, BBLOCK(b, sb.ninodes));
801013af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013b2:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
801013b8:	85 c0                	test   %eax,%eax
801013ba:	0f 48 c2             	cmovs  %edx,%eax
801013bd:	c1 f8 0c             	sar    $0xc,%eax
801013c0:	8b 55 e0             	mov    -0x20(%ebp),%edx
801013c3:	c1 ea 03             	shr    $0x3,%edx
801013c6:	01 d0                	add    %edx,%eax
801013c8:	83 c0 03             	add    $0x3,%eax
801013cb:	89 44 24 04          	mov    %eax,0x4(%esp)
801013cf:	8b 45 08             	mov    0x8(%ebp),%eax
801013d2:	89 04 24             	mov    %eax,(%esp)
801013d5:	e8 cc ed ff ff       	call   801001a6 <bread>
801013da:	89 45 ec             	mov    %eax,-0x14(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
801013dd:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
801013e4:	e9 a7 00 00 00       	jmp    80101490 <balloc+0x10d>
      m = 1 << (bi % 8);
801013e9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801013ec:	89 c2                	mov    %eax,%edx
801013ee:	c1 fa 1f             	sar    $0x1f,%edx
801013f1:	c1 ea 1d             	shr    $0x1d,%edx
801013f4:	01 d0                	add    %edx,%eax
801013f6:	83 e0 07             	and    $0x7,%eax
801013f9:	29 d0                	sub    %edx,%eax
801013fb:	ba 01 00 00 00       	mov    $0x1,%edx
80101400:	89 d3                	mov    %edx,%ebx
80101402:	89 c1                	mov    %eax,%ecx
80101404:	d3 e3                	shl    %cl,%ebx
80101406:	89 d8                	mov    %ebx,%eax
80101408:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if((bp->data[bi/8] & m) == 0){  // Is block free?
8010140b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010140e:	8d 50 07             	lea    0x7(%eax),%edx
80101411:	85 c0                	test   %eax,%eax
80101413:	0f 48 c2             	cmovs  %edx,%eax
80101416:	c1 f8 03             	sar    $0x3,%eax
80101419:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010141c:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
80101421:	0f b6 c0             	movzbl %al,%eax
80101424:	23 45 e8             	and    -0x18(%ebp),%eax
80101427:	85 c0                	test   %eax,%eax
80101429:	75 61                	jne    8010148c <balloc+0x109>
        bp->data[bi/8] |= m;  // Mark block in use.
8010142b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010142e:	8d 50 07             	lea    0x7(%eax),%edx
80101431:	85 c0                	test   %eax,%eax
80101433:	0f 48 c2             	cmovs  %edx,%eax
80101436:	c1 f8 03             	sar    $0x3,%eax
80101439:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010143c:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
80101441:	89 d1                	mov    %edx,%ecx
80101443:	8b 55 e8             	mov    -0x18(%ebp),%edx
80101446:	09 ca                	or     %ecx,%edx
80101448:	89 d1                	mov    %edx,%ecx
8010144a:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010144d:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
        log_write(bp);
80101451:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101454:	89 04 24             	mov    %eax,(%esp)
80101457:	e8 6e 1e 00 00       	call   801032ca <log_write>
        brelse(bp);
8010145c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010145f:	89 04 24             	mov    %eax,(%esp)
80101462:	e8 b0 ed ff ff       	call   80100217 <brelse>
        bzero(dev, b + bi);
80101467:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010146a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010146d:	01 c2                	add    %eax,%edx
8010146f:	8b 45 08             	mov    0x8(%ebp),%eax
80101472:	89 54 24 04          	mov    %edx,0x4(%esp)
80101476:	89 04 24             	mov    %eax,(%esp)
80101479:	e8 b4 fe ff ff       	call   80101332 <bzero>
        return b + bi;
8010147e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101481:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101484:	01 d0                	add    %edx,%eax
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
}
80101486:	83 c4 34             	add    $0x34,%esp
80101489:	5b                   	pop    %ebx
8010148a:	5d                   	pop    %ebp
8010148b:	c3                   	ret    

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
    bp = bread(dev, BBLOCK(b, sb.ninodes));
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
8010148c:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80101490:	81 7d f0 ff 0f 00 00 	cmpl   $0xfff,-0x10(%ebp)
80101497:	7f 15                	jg     801014ae <balloc+0x12b>
80101499:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010149c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010149f:	01 d0                	add    %edx,%eax
801014a1:	89 c2                	mov    %eax,%edx
801014a3:	8b 45 d8             	mov    -0x28(%ebp),%eax
801014a6:	39 c2                	cmp    %eax,%edx
801014a8:	0f 82 3b ff ff ff    	jb     801013e9 <balloc+0x66>
        brelse(bp);
        bzero(dev, b + bi);
        return b + bi;
      }
    }
    brelse(bp);
801014ae:	8b 45 ec             	mov    -0x14(%ebp),%eax
801014b1:	89 04 24             	mov    %eax,(%esp)
801014b4:	e8 5e ed ff ff       	call   80100217 <brelse>
  struct buf *bp;
  struct superblock sb;

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
801014b9:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801014c0:	8b 55 f4             	mov    -0xc(%ebp),%edx
801014c3:	8b 45 d8             	mov    -0x28(%ebp),%eax
801014c6:	39 c2                	cmp    %eax,%edx
801014c8:	0f 82 e1 fe ff ff    	jb     801013af <balloc+0x2c>
        return b + bi;
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
801014ce:	c7 04 24 e9 88 10 80 	movl   $0x801088e9,(%esp)
801014d5:	e8 63 f0 ff ff       	call   8010053d <panic>

801014da <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
801014da:	55                   	push   %ebp
801014db:	89 e5                	mov    %esp,%ebp
801014dd:	53                   	push   %ebx
801014de:	83 ec 34             	sub    $0x34,%esp
  struct buf *bp;
  struct superblock sb;
  int bi, m;

  readsb(dev, &sb);
801014e1:	8d 45 dc             	lea    -0x24(%ebp),%eax
801014e4:	89 44 24 04          	mov    %eax,0x4(%esp)
801014e8:	8b 45 08             	mov    0x8(%ebp),%eax
801014eb:	89 04 24             	mov    %eax,(%esp)
801014ee:	e8 f9 fd ff ff       	call   801012ec <readsb>
  bp = bread(dev, BBLOCK(b, sb.ninodes));
801014f3:	8b 45 0c             	mov    0xc(%ebp),%eax
801014f6:	89 c2                	mov    %eax,%edx
801014f8:	c1 ea 0c             	shr    $0xc,%edx
801014fb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801014fe:	c1 e8 03             	shr    $0x3,%eax
80101501:	01 d0                	add    %edx,%eax
80101503:	8d 50 03             	lea    0x3(%eax),%edx
80101506:	8b 45 08             	mov    0x8(%ebp),%eax
80101509:	89 54 24 04          	mov    %edx,0x4(%esp)
8010150d:	89 04 24             	mov    %eax,(%esp)
80101510:	e8 91 ec ff ff       	call   801001a6 <bread>
80101515:	89 45 f4             	mov    %eax,-0xc(%ebp)
  bi = b % BPB;
80101518:	8b 45 0c             	mov    0xc(%ebp),%eax
8010151b:	25 ff 0f 00 00       	and    $0xfff,%eax
80101520:	89 45 f0             	mov    %eax,-0x10(%ebp)
  m = 1 << (bi % 8);
80101523:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101526:	89 c2                	mov    %eax,%edx
80101528:	c1 fa 1f             	sar    $0x1f,%edx
8010152b:	c1 ea 1d             	shr    $0x1d,%edx
8010152e:	01 d0                	add    %edx,%eax
80101530:	83 e0 07             	and    $0x7,%eax
80101533:	29 d0                	sub    %edx,%eax
80101535:	ba 01 00 00 00       	mov    $0x1,%edx
8010153a:	89 d3                	mov    %edx,%ebx
8010153c:	89 c1                	mov    %eax,%ecx
8010153e:	d3 e3                	shl    %cl,%ebx
80101540:	89 d8                	mov    %ebx,%eax
80101542:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((bp->data[bi/8] & m) == 0)
80101545:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101548:	8d 50 07             	lea    0x7(%eax),%edx
8010154b:	85 c0                	test   %eax,%eax
8010154d:	0f 48 c2             	cmovs  %edx,%eax
80101550:	c1 f8 03             	sar    $0x3,%eax
80101553:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101556:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
8010155b:	0f b6 c0             	movzbl %al,%eax
8010155e:	23 45 ec             	and    -0x14(%ebp),%eax
80101561:	85 c0                	test   %eax,%eax
80101563:	75 0c                	jne    80101571 <bfree+0x97>
    panic("freeing free block");
80101565:	c7 04 24 ff 88 10 80 	movl   $0x801088ff,(%esp)
8010156c:	e8 cc ef ff ff       	call   8010053d <panic>
  bp->data[bi/8] &= ~m;
80101571:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101574:	8d 50 07             	lea    0x7(%eax),%edx
80101577:	85 c0                	test   %eax,%eax
80101579:	0f 48 c2             	cmovs  %edx,%eax
8010157c:	c1 f8 03             	sar    $0x3,%eax
8010157f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101582:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
80101587:	8b 4d ec             	mov    -0x14(%ebp),%ecx
8010158a:	f7 d1                	not    %ecx
8010158c:	21 ca                	and    %ecx,%edx
8010158e:	89 d1                	mov    %edx,%ecx
80101590:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101593:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
  log_write(bp);
80101597:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010159a:	89 04 24             	mov    %eax,(%esp)
8010159d:	e8 28 1d 00 00       	call   801032ca <log_write>
  brelse(bp);
801015a2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801015a5:	89 04 24             	mov    %eax,(%esp)
801015a8:	e8 6a ec ff ff       	call   80100217 <brelse>
}
801015ad:	83 c4 34             	add    $0x34,%esp
801015b0:	5b                   	pop    %ebx
801015b1:	5d                   	pop    %ebp
801015b2:	c3                   	ret    

801015b3 <iinit>:
  struct inode inode[NINODE];
} icache;

void
iinit(void)
{
801015b3:	55                   	push   %ebp
801015b4:	89 e5                	mov    %esp,%ebp
801015b6:	83 ec 18             	sub    $0x18,%esp
  initlock(&icache.lock, "icache");
801015b9:	c7 44 24 04 12 89 10 	movl   $0x80108912,0x4(%esp)
801015c0:	80 
801015c1:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
801015c8:	e8 c9 3a 00 00       	call   80105096 <initlock>
}
801015cd:	c9                   	leave  
801015ce:	c3                   	ret    

801015cf <ialloc>:
//PAGEBREAK!
// Allocate a new inode with the given type on device dev.
// A free inode has a type of zero.
struct inode*
ialloc(uint dev, short type)
{
801015cf:	55                   	push   %ebp
801015d0:	89 e5                	mov    %esp,%ebp
801015d2:	83 ec 48             	sub    $0x48,%esp
801015d5:	8b 45 0c             	mov    0xc(%ebp),%eax
801015d8:	66 89 45 d4          	mov    %ax,-0x2c(%ebp)
  int inum;
  struct buf *bp;
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);
801015dc:	8b 45 08             	mov    0x8(%ebp),%eax
801015df:	8d 55 dc             	lea    -0x24(%ebp),%edx
801015e2:	89 54 24 04          	mov    %edx,0x4(%esp)
801015e6:	89 04 24             	mov    %eax,(%esp)
801015e9:	e8 fe fc ff ff       	call   801012ec <readsb>

  for(inum = 1; inum < sb.ninodes; inum++){
801015ee:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
801015f5:	e9 98 00 00 00       	jmp    80101692 <ialloc+0xc3>
    bp = bread(dev, IBLOCK(inum));
801015fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801015fd:	c1 e8 03             	shr    $0x3,%eax
80101600:	83 c0 02             	add    $0x2,%eax
80101603:	89 44 24 04          	mov    %eax,0x4(%esp)
80101607:	8b 45 08             	mov    0x8(%ebp),%eax
8010160a:	89 04 24             	mov    %eax,(%esp)
8010160d:	e8 94 eb ff ff       	call   801001a6 <bread>
80101612:	89 45 f0             	mov    %eax,-0x10(%ebp)
    dip = (struct dinode*)bp->data + inum%IPB;
80101615:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101618:	8d 50 18             	lea    0x18(%eax),%edx
8010161b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010161e:	83 e0 07             	and    $0x7,%eax
80101621:	c1 e0 06             	shl    $0x6,%eax
80101624:	01 d0                	add    %edx,%eax
80101626:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(dip->type == 0){  // a free inode
80101629:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010162c:	0f b7 00             	movzwl (%eax),%eax
8010162f:	66 85 c0             	test   %ax,%ax
80101632:	75 4f                	jne    80101683 <ialloc+0xb4>
      memset(dip, 0, sizeof(*dip));
80101634:	c7 44 24 08 40 00 00 	movl   $0x40,0x8(%esp)
8010163b:	00 
8010163c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80101643:	00 
80101644:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101647:	89 04 24             	mov    %eax,(%esp)
8010164a:	e8 ef 3c 00 00       	call   8010533e <memset>
      dip->type = type;
8010164f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101652:	0f b7 55 d4          	movzwl -0x2c(%ebp),%edx
80101656:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
80101659:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010165c:	89 04 24             	mov    %eax,(%esp)
8010165f:	e8 66 1c 00 00       	call   801032ca <log_write>
      brelse(bp);
80101664:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101667:	89 04 24             	mov    %eax,(%esp)
8010166a:	e8 a8 eb ff ff       	call   80100217 <brelse>
      return iget(dev, inum);
8010166f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101672:	89 44 24 04          	mov    %eax,0x4(%esp)
80101676:	8b 45 08             	mov    0x8(%ebp),%eax
80101679:	89 04 24             	mov    %eax,(%esp)
8010167c:	e8 e3 00 00 00       	call   80101764 <iget>
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
}
80101681:	c9                   	leave  
80101682:	c3                   	ret    
      dip->type = type;
      log_write(bp);   // mark it allocated on the disk
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
80101683:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101686:	89 04 24             	mov    %eax,(%esp)
80101689:	e8 89 eb ff ff       	call   80100217 <brelse>
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);

  for(inum = 1; inum < sb.ninodes; inum++){
8010168e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101692:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101695:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101698:	39 c2                	cmp    %eax,%edx
8010169a:	0f 82 5a ff ff ff    	jb     801015fa <ialloc+0x2b>
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
801016a0:	c7 04 24 19 89 10 80 	movl   $0x80108919,(%esp)
801016a7:	e8 91 ee ff ff       	call   8010053d <panic>

801016ac <iupdate>:
}

// Copy a modified in-memory inode to disk.
void
iupdate(struct inode *ip)
{
801016ac:	55                   	push   %ebp
801016ad:	89 e5                	mov    %esp,%ebp
801016af:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  bp = bread(ip->dev, IBLOCK(ip->inum));
801016b2:	8b 45 08             	mov    0x8(%ebp),%eax
801016b5:	8b 40 04             	mov    0x4(%eax),%eax
801016b8:	c1 e8 03             	shr    $0x3,%eax
801016bb:	8d 50 02             	lea    0x2(%eax),%edx
801016be:	8b 45 08             	mov    0x8(%ebp),%eax
801016c1:	8b 00                	mov    (%eax),%eax
801016c3:	89 54 24 04          	mov    %edx,0x4(%esp)
801016c7:	89 04 24             	mov    %eax,(%esp)
801016ca:	e8 d7 ea ff ff       	call   801001a6 <bread>
801016cf:	89 45 f4             	mov    %eax,-0xc(%ebp)
  dip = (struct dinode*)bp->data + ip->inum%IPB;
801016d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801016d5:	8d 50 18             	lea    0x18(%eax),%edx
801016d8:	8b 45 08             	mov    0x8(%ebp),%eax
801016db:	8b 40 04             	mov    0x4(%eax),%eax
801016de:	83 e0 07             	and    $0x7,%eax
801016e1:	c1 e0 06             	shl    $0x6,%eax
801016e4:	01 d0                	add    %edx,%eax
801016e6:	89 45 f0             	mov    %eax,-0x10(%ebp)
  dip->type = ip->type;
801016e9:	8b 45 08             	mov    0x8(%ebp),%eax
801016ec:	0f b7 50 10          	movzwl 0x10(%eax),%edx
801016f0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801016f3:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
801016f6:	8b 45 08             	mov    0x8(%ebp),%eax
801016f9:	0f b7 50 12          	movzwl 0x12(%eax),%edx
801016fd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101700:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
80101704:	8b 45 08             	mov    0x8(%ebp),%eax
80101707:	0f b7 50 14          	movzwl 0x14(%eax),%edx
8010170b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010170e:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
80101712:	8b 45 08             	mov    0x8(%ebp),%eax
80101715:	0f b7 50 16          	movzwl 0x16(%eax),%edx
80101719:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010171c:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
80101720:	8b 45 08             	mov    0x8(%ebp),%eax
80101723:	8b 50 18             	mov    0x18(%eax),%edx
80101726:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101729:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
8010172c:	8b 45 08             	mov    0x8(%ebp),%eax
8010172f:	8d 50 1c             	lea    0x1c(%eax),%edx
80101732:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101735:	83 c0 0c             	add    $0xc,%eax
80101738:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
8010173f:	00 
80101740:	89 54 24 04          	mov    %edx,0x4(%esp)
80101744:	89 04 24             	mov    %eax,(%esp)
80101747:	e8 c5 3c 00 00       	call   80105411 <memmove>
  log_write(bp);
8010174c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010174f:	89 04 24             	mov    %eax,(%esp)
80101752:	e8 73 1b 00 00       	call   801032ca <log_write>
  brelse(bp);
80101757:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010175a:	89 04 24             	mov    %eax,(%esp)
8010175d:	e8 b5 ea ff ff       	call   80100217 <brelse>
}
80101762:	c9                   	leave  
80101763:	c3                   	ret    

80101764 <iget>:
// Find the inode with number inum on device dev
// and return the in-memory copy. Does not lock
// the inode and does not read it from disk.
static struct inode*
iget(uint dev, uint inum)
{
80101764:	55                   	push   %ebp
80101765:	89 e5                	mov    %esp,%ebp
80101767:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *empty;

  acquire(&icache.lock);
8010176a:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
80101771:	e8 41 39 00 00       	call   801050b7 <acquire>

  // Is the inode already cached?
  empty = 0;
80101776:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
8010177d:	c7 45 f4 94 e8 10 80 	movl   $0x8010e894,-0xc(%ebp)
80101784:	eb 59                	jmp    801017df <iget+0x7b>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
80101786:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101789:	8b 40 08             	mov    0x8(%eax),%eax
8010178c:	85 c0                	test   %eax,%eax
8010178e:	7e 35                	jle    801017c5 <iget+0x61>
80101790:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101793:	8b 00                	mov    (%eax),%eax
80101795:	3b 45 08             	cmp    0x8(%ebp),%eax
80101798:	75 2b                	jne    801017c5 <iget+0x61>
8010179a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010179d:	8b 40 04             	mov    0x4(%eax),%eax
801017a0:	3b 45 0c             	cmp    0xc(%ebp),%eax
801017a3:	75 20                	jne    801017c5 <iget+0x61>
      ip->ref++;
801017a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017a8:	8b 40 08             	mov    0x8(%eax),%eax
801017ab:	8d 50 01             	lea    0x1(%eax),%edx
801017ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017b1:	89 50 08             	mov    %edx,0x8(%eax)
      release(&icache.lock);
801017b4:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
801017bb:	e8 92 39 00 00       	call   80105152 <release>
      return ip;
801017c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017c3:	eb 6f                	jmp    80101834 <iget+0xd0>
    }
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
801017c5:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801017c9:	75 10                	jne    801017db <iget+0x77>
801017cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017ce:	8b 40 08             	mov    0x8(%eax),%eax
801017d1:	85 c0                	test   %eax,%eax
801017d3:	75 06                	jne    801017db <iget+0x77>
      empty = ip;
801017d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017d8:	89 45 f0             	mov    %eax,-0x10(%ebp)

  acquire(&icache.lock);

  // Is the inode already cached?
  empty = 0;
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801017db:	83 45 f4 50          	addl   $0x50,-0xc(%ebp)
801017df:	81 7d f4 34 f8 10 80 	cmpl   $0x8010f834,-0xc(%ebp)
801017e6:	72 9e                	jb     80101786 <iget+0x22>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
      empty = ip;
  }

  // Recycle an inode cache entry.
  if(empty == 0)
801017e8:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801017ec:	75 0c                	jne    801017fa <iget+0x96>
    panic("iget: no inodes");
801017ee:	c7 04 24 2b 89 10 80 	movl   $0x8010892b,(%esp)
801017f5:	e8 43 ed ff ff       	call   8010053d <panic>

  ip = empty;
801017fa:	8b 45 f0             	mov    -0x10(%ebp),%eax
801017fd:	89 45 f4             	mov    %eax,-0xc(%ebp)
  ip->dev = dev;
80101800:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101803:	8b 55 08             	mov    0x8(%ebp),%edx
80101806:	89 10                	mov    %edx,(%eax)
  ip->inum = inum;
80101808:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010180b:	8b 55 0c             	mov    0xc(%ebp),%edx
8010180e:	89 50 04             	mov    %edx,0x4(%eax)
  ip->ref = 1;
80101811:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101814:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
  ip->flags = 0;
8010181b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010181e:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  release(&icache.lock);
80101825:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
8010182c:	e8 21 39 00 00       	call   80105152 <release>

  return ip;
80101831:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80101834:	c9                   	leave  
80101835:	c3                   	ret    

80101836 <idup>:

// Increment reference count for ip.
// Returns ip to enable ip = idup(ip1) idiom.
struct inode*
idup(struct inode *ip)
{
80101836:	55                   	push   %ebp
80101837:	89 e5                	mov    %esp,%ebp
80101839:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
8010183c:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
80101843:	e8 6f 38 00 00       	call   801050b7 <acquire>
  ip->ref++;
80101848:	8b 45 08             	mov    0x8(%ebp),%eax
8010184b:	8b 40 08             	mov    0x8(%eax),%eax
8010184e:	8d 50 01             	lea    0x1(%eax),%edx
80101851:	8b 45 08             	mov    0x8(%ebp),%eax
80101854:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101857:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
8010185e:	e8 ef 38 00 00       	call   80105152 <release>
  return ip;
80101863:	8b 45 08             	mov    0x8(%ebp),%eax
}
80101866:	c9                   	leave  
80101867:	c3                   	ret    

80101868 <ilock>:

// Lock the given inode.
// Reads the inode from disk if necessary.
void
ilock(struct inode *ip)
{
80101868:	55                   	push   %ebp
80101869:	89 e5                	mov    %esp,%ebp
8010186b:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  if(ip == 0 || ip->ref < 1)
8010186e:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80101872:	74 0a                	je     8010187e <ilock+0x16>
80101874:	8b 45 08             	mov    0x8(%ebp),%eax
80101877:	8b 40 08             	mov    0x8(%eax),%eax
8010187a:	85 c0                	test   %eax,%eax
8010187c:	7f 0c                	jg     8010188a <ilock+0x22>
    panic("ilock");
8010187e:	c7 04 24 3b 89 10 80 	movl   $0x8010893b,(%esp)
80101885:	e8 b3 ec ff ff       	call   8010053d <panic>

  acquire(&icache.lock);
8010188a:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
80101891:	e8 21 38 00 00       	call   801050b7 <acquire>
  while(ip->flags & I_BUSY)
80101896:	eb 13                	jmp    801018ab <ilock+0x43>
    sleep(ip, &icache.lock);
80101898:	c7 44 24 04 60 e8 10 	movl   $0x8010e860,0x4(%esp)
8010189f:	80 
801018a0:	8b 45 08             	mov    0x8(%ebp),%eax
801018a3:	89 04 24             	mov    %eax,(%esp)
801018a6:	e8 9f 34 00 00       	call   80104d4a <sleep>

  if(ip == 0 || ip->ref < 1)
    panic("ilock");

  acquire(&icache.lock);
  while(ip->flags & I_BUSY)
801018ab:	8b 45 08             	mov    0x8(%ebp),%eax
801018ae:	8b 40 0c             	mov    0xc(%eax),%eax
801018b1:	83 e0 01             	and    $0x1,%eax
801018b4:	84 c0                	test   %al,%al
801018b6:	75 e0                	jne    80101898 <ilock+0x30>
    sleep(ip, &icache.lock);
  ip->flags |= I_BUSY;
801018b8:	8b 45 08             	mov    0x8(%ebp),%eax
801018bb:	8b 40 0c             	mov    0xc(%eax),%eax
801018be:	89 c2                	mov    %eax,%edx
801018c0:	83 ca 01             	or     $0x1,%edx
801018c3:	8b 45 08             	mov    0x8(%ebp),%eax
801018c6:	89 50 0c             	mov    %edx,0xc(%eax)
  release(&icache.lock);
801018c9:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
801018d0:	e8 7d 38 00 00       	call   80105152 <release>

  if(!(ip->flags & I_VALID)){
801018d5:	8b 45 08             	mov    0x8(%ebp),%eax
801018d8:	8b 40 0c             	mov    0xc(%eax),%eax
801018db:	83 e0 02             	and    $0x2,%eax
801018de:	85 c0                	test   %eax,%eax
801018e0:	0f 85 ce 00 00 00    	jne    801019b4 <ilock+0x14c>
    bp = bread(ip->dev, IBLOCK(ip->inum));
801018e6:	8b 45 08             	mov    0x8(%ebp),%eax
801018e9:	8b 40 04             	mov    0x4(%eax),%eax
801018ec:	c1 e8 03             	shr    $0x3,%eax
801018ef:	8d 50 02             	lea    0x2(%eax),%edx
801018f2:	8b 45 08             	mov    0x8(%ebp),%eax
801018f5:	8b 00                	mov    (%eax),%eax
801018f7:	89 54 24 04          	mov    %edx,0x4(%esp)
801018fb:	89 04 24             	mov    %eax,(%esp)
801018fe:	e8 a3 e8 ff ff       	call   801001a6 <bread>
80101903:	89 45 f4             	mov    %eax,-0xc(%ebp)
    dip = (struct dinode*)bp->data + ip->inum%IPB;
80101906:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101909:	8d 50 18             	lea    0x18(%eax),%edx
8010190c:	8b 45 08             	mov    0x8(%ebp),%eax
8010190f:	8b 40 04             	mov    0x4(%eax),%eax
80101912:	83 e0 07             	and    $0x7,%eax
80101915:	c1 e0 06             	shl    $0x6,%eax
80101918:	01 d0                	add    %edx,%eax
8010191a:	89 45 f0             	mov    %eax,-0x10(%ebp)
    ip->type = dip->type;
8010191d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101920:	0f b7 10             	movzwl (%eax),%edx
80101923:	8b 45 08             	mov    0x8(%ebp),%eax
80101926:	66 89 50 10          	mov    %dx,0x10(%eax)
    ip->major = dip->major;
8010192a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010192d:	0f b7 50 02          	movzwl 0x2(%eax),%edx
80101931:	8b 45 08             	mov    0x8(%ebp),%eax
80101934:	66 89 50 12          	mov    %dx,0x12(%eax)
    ip->minor = dip->minor;
80101938:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010193b:	0f b7 50 04          	movzwl 0x4(%eax),%edx
8010193f:	8b 45 08             	mov    0x8(%ebp),%eax
80101942:	66 89 50 14          	mov    %dx,0x14(%eax)
    ip->nlink = dip->nlink;
80101946:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101949:	0f b7 50 06          	movzwl 0x6(%eax),%edx
8010194d:	8b 45 08             	mov    0x8(%ebp),%eax
80101950:	66 89 50 16          	mov    %dx,0x16(%eax)
    ip->size = dip->size;
80101954:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101957:	8b 50 08             	mov    0x8(%eax),%edx
8010195a:	8b 45 08             	mov    0x8(%ebp),%eax
8010195d:	89 50 18             	mov    %edx,0x18(%eax)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
80101960:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101963:	8d 50 0c             	lea    0xc(%eax),%edx
80101966:	8b 45 08             	mov    0x8(%ebp),%eax
80101969:	83 c0 1c             	add    $0x1c,%eax
8010196c:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
80101973:	00 
80101974:	89 54 24 04          	mov    %edx,0x4(%esp)
80101978:	89 04 24             	mov    %eax,(%esp)
8010197b:	e8 91 3a 00 00       	call   80105411 <memmove>
    brelse(bp);
80101980:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101983:	89 04 24             	mov    %eax,(%esp)
80101986:	e8 8c e8 ff ff       	call   80100217 <brelse>
    ip->flags |= I_VALID;
8010198b:	8b 45 08             	mov    0x8(%ebp),%eax
8010198e:	8b 40 0c             	mov    0xc(%eax),%eax
80101991:	89 c2                	mov    %eax,%edx
80101993:	83 ca 02             	or     $0x2,%edx
80101996:	8b 45 08             	mov    0x8(%ebp),%eax
80101999:	89 50 0c             	mov    %edx,0xc(%eax)
    if(ip->type == 0)
8010199c:	8b 45 08             	mov    0x8(%ebp),%eax
8010199f:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801019a3:	66 85 c0             	test   %ax,%ax
801019a6:	75 0c                	jne    801019b4 <ilock+0x14c>
      panic("ilock: no type");
801019a8:	c7 04 24 41 89 10 80 	movl   $0x80108941,(%esp)
801019af:	e8 89 eb ff ff       	call   8010053d <panic>
  }
}
801019b4:	c9                   	leave  
801019b5:	c3                   	ret    

801019b6 <iunlock>:

// Unlock the given inode.
void
iunlock(struct inode *ip)
{
801019b6:	55                   	push   %ebp
801019b7:	89 e5                	mov    %esp,%ebp
801019b9:	83 ec 18             	sub    $0x18,%esp
  if(ip == 0 || !(ip->flags & I_BUSY) || ip->ref < 1)
801019bc:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801019c0:	74 17                	je     801019d9 <iunlock+0x23>
801019c2:	8b 45 08             	mov    0x8(%ebp),%eax
801019c5:	8b 40 0c             	mov    0xc(%eax),%eax
801019c8:	83 e0 01             	and    $0x1,%eax
801019cb:	85 c0                	test   %eax,%eax
801019cd:	74 0a                	je     801019d9 <iunlock+0x23>
801019cf:	8b 45 08             	mov    0x8(%ebp),%eax
801019d2:	8b 40 08             	mov    0x8(%eax),%eax
801019d5:	85 c0                	test   %eax,%eax
801019d7:	7f 0c                	jg     801019e5 <iunlock+0x2f>
    panic("iunlock");
801019d9:	c7 04 24 50 89 10 80 	movl   $0x80108950,(%esp)
801019e0:	e8 58 eb ff ff       	call   8010053d <panic>
  acquire(&icache.lock);
801019e5:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
801019ec:	e8 c6 36 00 00       	call   801050b7 <acquire>
  ip->flags &= ~I_BUSY;
801019f1:	8b 45 08             	mov    0x8(%ebp),%eax
801019f4:	8b 40 0c             	mov    0xc(%eax),%eax
801019f7:	89 c2                	mov    %eax,%edx
801019f9:	83 e2 fe             	and    $0xfffffffe,%edx
801019fc:	8b 45 08             	mov    0x8(%ebp),%eax
801019ff:	89 50 0c             	mov    %edx,0xc(%eax)
  wakeup(ip);
80101a02:	8b 45 08             	mov    0x8(%ebp),%eax
80101a05:	89 04 24             	mov    %eax,(%esp)
80101a08:	e8 a0 34 00 00       	call   80104ead <wakeup>
  release(&icache.lock);
80101a0d:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
80101a14:	e8 39 37 00 00       	call   80105152 <release>
}
80101a19:	c9                   	leave  
80101a1a:	c3                   	ret    

80101a1b <iput>:
// be recycled.
// If that was the last reference and the inode has no links
// to it, free the inode (and its content) on disk.
void
iput(struct inode *ip)
{
80101a1b:	55                   	push   %ebp
80101a1c:	89 e5                	mov    %esp,%ebp
80101a1e:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
80101a21:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
80101a28:	e8 8a 36 00 00       	call   801050b7 <acquire>
  if(ip->ref == 1 && (ip->flags & I_VALID) && ip->nlink == 0){
80101a2d:	8b 45 08             	mov    0x8(%ebp),%eax
80101a30:	8b 40 08             	mov    0x8(%eax),%eax
80101a33:	83 f8 01             	cmp    $0x1,%eax
80101a36:	0f 85 93 00 00 00    	jne    80101acf <iput+0xb4>
80101a3c:	8b 45 08             	mov    0x8(%ebp),%eax
80101a3f:	8b 40 0c             	mov    0xc(%eax),%eax
80101a42:	83 e0 02             	and    $0x2,%eax
80101a45:	85 c0                	test   %eax,%eax
80101a47:	0f 84 82 00 00 00    	je     80101acf <iput+0xb4>
80101a4d:	8b 45 08             	mov    0x8(%ebp),%eax
80101a50:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80101a54:	66 85 c0             	test   %ax,%ax
80101a57:	75 76                	jne    80101acf <iput+0xb4>
    // inode has no links: truncate and free inode.
    if(ip->flags & I_BUSY)
80101a59:	8b 45 08             	mov    0x8(%ebp),%eax
80101a5c:	8b 40 0c             	mov    0xc(%eax),%eax
80101a5f:	83 e0 01             	and    $0x1,%eax
80101a62:	84 c0                	test   %al,%al
80101a64:	74 0c                	je     80101a72 <iput+0x57>
      panic("iput busy");
80101a66:	c7 04 24 58 89 10 80 	movl   $0x80108958,(%esp)
80101a6d:	e8 cb ea ff ff       	call   8010053d <panic>
    ip->flags |= I_BUSY;
80101a72:	8b 45 08             	mov    0x8(%ebp),%eax
80101a75:	8b 40 0c             	mov    0xc(%eax),%eax
80101a78:	89 c2                	mov    %eax,%edx
80101a7a:	83 ca 01             	or     $0x1,%edx
80101a7d:	8b 45 08             	mov    0x8(%ebp),%eax
80101a80:	89 50 0c             	mov    %edx,0xc(%eax)
    release(&icache.lock);
80101a83:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
80101a8a:	e8 c3 36 00 00       	call   80105152 <release>
    itrunc(ip);
80101a8f:	8b 45 08             	mov    0x8(%ebp),%eax
80101a92:	89 04 24             	mov    %eax,(%esp)
80101a95:	e8 72 01 00 00       	call   80101c0c <itrunc>
    ip->type = 0;
80101a9a:	8b 45 08             	mov    0x8(%ebp),%eax
80101a9d:	66 c7 40 10 00 00    	movw   $0x0,0x10(%eax)
    iupdate(ip);
80101aa3:	8b 45 08             	mov    0x8(%ebp),%eax
80101aa6:	89 04 24             	mov    %eax,(%esp)
80101aa9:	e8 fe fb ff ff       	call   801016ac <iupdate>
    acquire(&icache.lock);
80101aae:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
80101ab5:	e8 fd 35 00 00       	call   801050b7 <acquire>
    ip->flags = 0;
80101aba:	8b 45 08             	mov    0x8(%ebp),%eax
80101abd:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
80101ac4:	8b 45 08             	mov    0x8(%ebp),%eax
80101ac7:	89 04 24             	mov    %eax,(%esp)
80101aca:	e8 de 33 00 00       	call   80104ead <wakeup>
  }
  ip->ref--;
80101acf:	8b 45 08             	mov    0x8(%ebp),%eax
80101ad2:	8b 40 08             	mov    0x8(%eax),%eax
80101ad5:	8d 50 ff             	lea    -0x1(%eax),%edx
80101ad8:	8b 45 08             	mov    0x8(%ebp),%eax
80101adb:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101ade:	c7 04 24 60 e8 10 80 	movl   $0x8010e860,(%esp)
80101ae5:	e8 68 36 00 00       	call   80105152 <release>
}
80101aea:	c9                   	leave  
80101aeb:	c3                   	ret    

80101aec <iunlockput>:

// Common idiom: unlock, then put.
void
iunlockput(struct inode *ip)
{
80101aec:	55                   	push   %ebp
80101aed:	89 e5                	mov    %esp,%ebp
80101aef:	83 ec 18             	sub    $0x18,%esp
  iunlock(ip);
80101af2:	8b 45 08             	mov    0x8(%ebp),%eax
80101af5:	89 04 24             	mov    %eax,(%esp)
80101af8:	e8 b9 fe ff ff       	call   801019b6 <iunlock>
  iput(ip);
80101afd:	8b 45 08             	mov    0x8(%ebp),%eax
80101b00:	89 04 24             	mov    %eax,(%esp)
80101b03:	e8 13 ff ff ff       	call   80101a1b <iput>
}
80101b08:	c9                   	leave  
80101b09:	c3                   	ret    

80101b0a <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
80101b0a:	55                   	push   %ebp
80101b0b:	89 e5                	mov    %esp,%ebp
80101b0d:	53                   	push   %ebx
80101b0e:	83 ec 24             	sub    $0x24,%esp
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
80101b11:	83 7d 0c 0b          	cmpl   $0xb,0xc(%ebp)
80101b15:	77 3e                	ja     80101b55 <bmap+0x4b>
    if((addr = ip->addrs[bn]) == 0)
80101b17:	8b 45 08             	mov    0x8(%ebp),%eax
80101b1a:	8b 55 0c             	mov    0xc(%ebp),%edx
80101b1d:	83 c2 04             	add    $0x4,%edx
80101b20:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101b24:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101b27:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101b2b:	75 20                	jne    80101b4d <bmap+0x43>
      ip->addrs[bn] = addr = balloc(ip->dev);
80101b2d:	8b 45 08             	mov    0x8(%ebp),%eax
80101b30:	8b 00                	mov    (%eax),%eax
80101b32:	89 04 24             	mov    %eax,(%esp)
80101b35:	e8 49 f8 ff ff       	call   80101383 <balloc>
80101b3a:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101b3d:	8b 45 08             	mov    0x8(%ebp),%eax
80101b40:	8b 55 0c             	mov    0xc(%ebp),%edx
80101b43:	8d 4a 04             	lea    0x4(%edx),%ecx
80101b46:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101b49:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
    return addr;
80101b4d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101b50:	e9 b1 00 00 00       	jmp    80101c06 <bmap+0xfc>
  }
  bn -= NDIRECT;
80101b55:	83 6d 0c 0c          	subl   $0xc,0xc(%ebp)

  if(bn < NINDIRECT){
80101b59:	83 7d 0c 7f          	cmpl   $0x7f,0xc(%ebp)
80101b5d:	0f 87 97 00 00 00    	ja     80101bfa <bmap+0xf0>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
80101b63:	8b 45 08             	mov    0x8(%ebp),%eax
80101b66:	8b 40 4c             	mov    0x4c(%eax),%eax
80101b69:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101b6c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101b70:	75 19                	jne    80101b8b <bmap+0x81>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
80101b72:	8b 45 08             	mov    0x8(%ebp),%eax
80101b75:	8b 00                	mov    (%eax),%eax
80101b77:	89 04 24             	mov    %eax,(%esp)
80101b7a:	e8 04 f8 ff ff       	call   80101383 <balloc>
80101b7f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101b82:	8b 45 08             	mov    0x8(%ebp),%eax
80101b85:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101b88:	89 50 4c             	mov    %edx,0x4c(%eax)
    bp = bread(ip->dev, addr);
80101b8b:	8b 45 08             	mov    0x8(%ebp),%eax
80101b8e:	8b 00                	mov    (%eax),%eax
80101b90:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101b93:	89 54 24 04          	mov    %edx,0x4(%esp)
80101b97:	89 04 24             	mov    %eax,(%esp)
80101b9a:	e8 07 e6 ff ff       	call   801001a6 <bread>
80101b9f:	89 45 f0             	mov    %eax,-0x10(%ebp)
    a = (uint*)bp->data;
80101ba2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ba5:	83 c0 18             	add    $0x18,%eax
80101ba8:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if((addr = a[bn]) == 0){
80101bab:	8b 45 0c             	mov    0xc(%ebp),%eax
80101bae:	c1 e0 02             	shl    $0x2,%eax
80101bb1:	03 45 ec             	add    -0x14(%ebp),%eax
80101bb4:	8b 00                	mov    (%eax),%eax
80101bb6:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101bb9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101bbd:	75 2b                	jne    80101bea <bmap+0xe0>
      a[bn] = addr = balloc(ip->dev);
80101bbf:	8b 45 0c             	mov    0xc(%ebp),%eax
80101bc2:	c1 e0 02             	shl    $0x2,%eax
80101bc5:	89 c3                	mov    %eax,%ebx
80101bc7:	03 5d ec             	add    -0x14(%ebp),%ebx
80101bca:	8b 45 08             	mov    0x8(%ebp),%eax
80101bcd:	8b 00                	mov    (%eax),%eax
80101bcf:	89 04 24             	mov    %eax,(%esp)
80101bd2:	e8 ac f7 ff ff       	call   80101383 <balloc>
80101bd7:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101bda:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101bdd:	89 03                	mov    %eax,(%ebx)
      log_write(bp);
80101bdf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101be2:	89 04 24             	mov    %eax,(%esp)
80101be5:	e8 e0 16 00 00       	call   801032ca <log_write>
    }
    brelse(bp);
80101bea:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101bed:	89 04 24             	mov    %eax,(%esp)
80101bf0:	e8 22 e6 ff ff       	call   80100217 <brelse>
    return addr;
80101bf5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101bf8:	eb 0c                	jmp    80101c06 <bmap+0xfc>
  }

  panic("bmap: out of range");
80101bfa:	c7 04 24 62 89 10 80 	movl   $0x80108962,(%esp)
80101c01:	e8 37 e9 ff ff       	call   8010053d <panic>
}
80101c06:	83 c4 24             	add    $0x24,%esp
80101c09:	5b                   	pop    %ebx
80101c0a:	5d                   	pop    %ebp
80101c0b:	c3                   	ret    

80101c0c <itrunc>:
// to it (no directory entries referring to it)
// and has no in-memory reference to it (is
// not an open file or current directory).
static void
itrunc(struct inode *ip)
{
80101c0c:	55                   	push   %ebp
80101c0d:	89 e5                	mov    %esp,%ebp
80101c0f:	83 ec 28             	sub    $0x28,%esp
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101c12:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101c19:	eb 44                	jmp    80101c5f <itrunc+0x53>
    if(ip->addrs[i]){
80101c1b:	8b 45 08             	mov    0x8(%ebp),%eax
80101c1e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c21:	83 c2 04             	add    $0x4,%edx
80101c24:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101c28:	85 c0                	test   %eax,%eax
80101c2a:	74 2f                	je     80101c5b <itrunc+0x4f>
      bfree(ip->dev, ip->addrs[i]);
80101c2c:	8b 45 08             	mov    0x8(%ebp),%eax
80101c2f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c32:	83 c2 04             	add    $0x4,%edx
80101c35:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80101c39:	8b 45 08             	mov    0x8(%ebp),%eax
80101c3c:	8b 00                	mov    (%eax),%eax
80101c3e:	89 54 24 04          	mov    %edx,0x4(%esp)
80101c42:	89 04 24             	mov    %eax,(%esp)
80101c45:	e8 90 f8 ff ff       	call   801014da <bfree>
      ip->addrs[i] = 0;
80101c4a:	8b 45 08             	mov    0x8(%ebp),%eax
80101c4d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c50:	83 c2 04             	add    $0x4,%edx
80101c53:	c7 44 90 0c 00 00 00 	movl   $0x0,0xc(%eax,%edx,4)
80101c5a:	00 
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101c5b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101c5f:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
80101c63:	7e b6                	jle    80101c1b <itrunc+0xf>
      bfree(ip->dev, ip->addrs[i]);
      ip->addrs[i] = 0;
    }
  }
  
  if(ip->addrs[NDIRECT]){
80101c65:	8b 45 08             	mov    0x8(%ebp),%eax
80101c68:	8b 40 4c             	mov    0x4c(%eax),%eax
80101c6b:	85 c0                	test   %eax,%eax
80101c6d:	0f 84 8f 00 00 00    	je     80101d02 <itrunc+0xf6>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
80101c73:	8b 45 08             	mov    0x8(%ebp),%eax
80101c76:	8b 50 4c             	mov    0x4c(%eax),%edx
80101c79:	8b 45 08             	mov    0x8(%ebp),%eax
80101c7c:	8b 00                	mov    (%eax),%eax
80101c7e:	89 54 24 04          	mov    %edx,0x4(%esp)
80101c82:	89 04 24             	mov    %eax,(%esp)
80101c85:	e8 1c e5 ff ff       	call   801001a6 <bread>
80101c8a:	89 45 ec             	mov    %eax,-0x14(%ebp)
    a = (uint*)bp->data;
80101c8d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101c90:	83 c0 18             	add    $0x18,%eax
80101c93:	89 45 e8             	mov    %eax,-0x18(%ebp)
    for(j = 0; j < NINDIRECT; j++){
80101c96:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80101c9d:	eb 2f                	jmp    80101cce <itrunc+0xc2>
      if(a[j])
80101c9f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ca2:	c1 e0 02             	shl    $0x2,%eax
80101ca5:	03 45 e8             	add    -0x18(%ebp),%eax
80101ca8:	8b 00                	mov    (%eax),%eax
80101caa:	85 c0                	test   %eax,%eax
80101cac:	74 1c                	je     80101cca <itrunc+0xbe>
        bfree(ip->dev, a[j]);
80101cae:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101cb1:	c1 e0 02             	shl    $0x2,%eax
80101cb4:	03 45 e8             	add    -0x18(%ebp),%eax
80101cb7:	8b 10                	mov    (%eax),%edx
80101cb9:	8b 45 08             	mov    0x8(%ebp),%eax
80101cbc:	8b 00                	mov    (%eax),%eax
80101cbe:	89 54 24 04          	mov    %edx,0x4(%esp)
80101cc2:	89 04 24             	mov    %eax,(%esp)
80101cc5:	e8 10 f8 ff ff       	call   801014da <bfree>
  }
  
  if(ip->addrs[NDIRECT]){
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    a = (uint*)bp->data;
    for(j = 0; j < NINDIRECT; j++){
80101cca:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80101cce:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101cd1:	83 f8 7f             	cmp    $0x7f,%eax
80101cd4:	76 c9                	jbe    80101c9f <itrunc+0x93>
      if(a[j])
        bfree(ip->dev, a[j]);
    }
    brelse(bp);
80101cd6:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101cd9:	89 04 24             	mov    %eax,(%esp)
80101cdc:	e8 36 e5 ff ff       	call   80100217 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
80101ce1:	8b 45 08             	mov    0x8(%ebp),%eax
80101ce4:	8b 50 4c             	mov    0x4c(%eax),%edx
80101ce7:	8b 45 08             	mov    0x8(%ebp),%eax
80101cea:	8b 00                	mov    (%eax),%eax
80101cec:	89 54 24 04          	mov    %edx,0x4(%esp)
80101cf0:	89 04 24             	mov    %eax,(%esp)
80101cf3:	e8 e2 f7 ff ff       	call   801014da <bfree>
    ip->addrs[NDIRECT] = 0;
80101cf8:	8b 45 08             	mov    0x8(%ebp),%eax
80101cfb:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
  }

  ip->size = 0;
80101d02:	8b 45 08             	mov    0x8(%ebp),%eax
80101d05:	c7 40 18 00 00 00 00 	movl   $0x0,0x18(%eax)
  iupdate(ip);
80101d0c:	8b 45 08             	mov    0x8(%ebp),%eax
80101d0f:	89 04 24             	mov    %eax,(%esp)
80101d12:	e8 95 f9 ff ff       	call   801016ac <iupdate>
}
80101d17:	c9                   	leave  
80101d18:	c3                   	ret    

80101d19 <stati>:

// Copy stat information from inode.
void
stati(struct inode *ip, struct stat *st)
{
80101d19:	55                   	push   %ebp
80101d1a:	89 e5                	mov    %esp,%ebp
  st->dev = ip->dev;
80101d1c:	8b 45 08             	mov    0x8(%ebp),%eax
80101d1f:	8b 00                	mov    (%eax),%eax
80101d21:	89 c2                	mov    %eax,%edx
80101d23:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d26:	89 50 04             	mov    %edx,0x4(%eax)
  st->ino = ip->inum;
80101d29:	8b 45 08             	mov    0x8(%ebp),%eax
80101d2c:	8b 50 04             	mov    0x4(%eax),%edx
80101d2f:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d32:	89 50 08             	mov    %edx,0x8(%eax)
  st->type = ip->type;
80101d35:	8b 45 08             	mov    0x8(%ebp),%eax
80101d38:	0f b7 50 10          	movzwl 0x10(%eax),%edx
80101d3c:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d3f:	66 89 10             	mov    %dx,(%eax)
  st->nlink = ip->nlink;
80101d42:	8b 45 08             	mov    0x8(%ebp),%eax
80101d45:	0f b7 50 16          	movzwl 0x16(%eax),%edx
80101d49:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d4c:	66 89 50 0c          	mov    %dx,0xc(%eax)
  st->size = ip->size;
80101d50:	8b 45 08             	mov    0x8(%ebp),%eax
80101d53:	8b 50 18             	mov    0x18(%eax),%edx
80101d56:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d59:	89 50 10             	mov    %edx,0x10(%eax)
}
80101d5c:	5d                   	pop    %ebp
80101d5d:	c3                   	ret    

80101d5e <readi>:

//PAGEBREAK!
// Read data from inode.
int
readi(struct inode *ip, char *dst, uint off, uint n)
{
80101d5e:	55                   	push   %ebp
80101d5f:	89 e5                	mov    %esp,%ebp
80101d61:	53                   	push   %ebx
80101d62:	83 ec 24             	sub    $0x24,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80101d65:	8b 45 08             	mov    0x8(%ebp),%eax
80101d68:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101d6c:	66 83 f8 03          	cmp    $0x3,%ax
80101d70:	75 60                	jne    80101dd2 <readi+0x74>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
80101d72:	8b 45 08             	mov    0x8(%ebp),%eax
80101d75:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101d79:	66 85 c0             	test   %ax,%ax
80101d7c:	78 20                	js     80101d9e <readi+0x40>
80101d7e:	8b 45 08             	mov    0x8(%ebp),%eax
80101d81:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101d85:	66 83 f8 09          	cmp    $0x9,%ax
80101d89:	7f 13                	jg     80101d9e <readi+0x40>
80101d8b:	8b 45 08             	mov    0x8(%ebp),%eax
80101d8e:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101d92:	98                   	cwtl   
80101d93:	8b 04 c5 00 e8 10 80 	mov    -0x7fef1800(,%eax,8),%eax
80101d9a:	85 c0                	test   %eax,%eax
80101d9c:	75 0a                	jne    80101da8 <readi+0x4a>
      return -1;
80101d9e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101da3:	e9 1b 01 00 00       	jmp    80101ec3 <readi+0x165>
    return devsw[ip->major].read(ip, dst, n);
80101da8:	8b 45 08             	mov    0x8(%ebp),%eax
80101dab:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101daf:	98                   	cwtl   
80101db0:	8b 14 c5 00 e8 10 80 	mov    -0x7fef1800(,%eax,8),%edx
80101db7:	8b 45 14             	mov    0x14(%ebp),%eax
80101dba:	89 44 24 08          	mov    %eax,0x8(%esp)
80101dbe:	8b 45 0c             	mov    0xc(%ebp),%eax
80101dc1:	89 44 24 04          	mov    %eax,0x4(%esp)
80101dc5:	8b 45 08             	mov    0x8(%ebp),%eax
80101dc8:	89 04 24             	mov    %eax,(%esp)
80101dcb:	ff d2                	call   *%edx
80101dcd:	e9 f1 00 00 00       	jmp    80101ec3 <readi+0x165>
  }

  if(off > ip->size || off + n < off)
80101dd2:	8b 45 08             	mov    0x8(%ebp),%eax
80101dd5:	8b 40 18             	mov    0x18(%eax),%eax
80101dd8:	3b 45 10             	cmp    0x10(%ebp),%eax
80101ddb:	72 0d                	jb     80101dea <readi+0x8c>
80101ddd:	8b 45 14             	mov    0x14(%ebp),%eax
80101de0:	8b 55 10             	mov    0x10(%ebp),%edx
80101de3:	01 d0                	add    %edx,%eax
80101de5:	3b 45 10             	cmp    0x10(%ebp),%eax
80101de8:	73 0a                	jae    80101df4 <readi+0x96>
    return -1;
80101dea:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101def:	e9 cf 00 00 00       	jmp    80101ec3 <readi+0x165>
  if(off + n > ip->size)
80101df4:	8b 45 14             	mov    0x14(%ebp),%eax
80101df7:	8b 55 10             	mov    0x10(%ebp),%edx
80101dfa:	01 c2                	add    %eax,%edx
80101dfc:	8b 45 08             	mov    0x8(%ebp),%eax
80101dff:	8b 40 18             	mov    0x18(%eax),%eax
80101e02:	39 c2                	cmp    %eax,%edx
80101e04:	76 0c                	jbe    80101e12 <readi+0xb4>
    n = ip->size - off;
80101e06:	8b 45 08             	mov    0x8(%ebp),%eax
80101e09:	8b 40 18             	mov    0x18(%eax),%eax
80101e0c:	2b 45 10             	sub    0x10(%ebp),%eax
80101e0f:	89 45 14             	mov    %eax,0x14(%ebp)

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101e12:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101e19:	e9 96 00 00 00       	jmp    80101eb4 <readi+0x156>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80101e1e:	8b 45 10             	mov    0x10(%ebp),%eax
80101e21:	c1 e8 09             	shr    $0x9,%eax
80101e24:	89 44 24 04          	mov    %eax,0x4(%esp)
80101e28:	8b 45 08             	mov    0x8(%ebp),%eax
80101e2b:	89 04 24             	mov    %eax,(%esp)
80101e2e:	e8 d7 fc ff ff       	call   80101b0a <bmap>
80101e33:	8b 55 08             	mov    0x8(%ebp),%edx
80101e36:	8b 12                	mov    (%edx),%edx
80101e38:	89 44 24 04          	mov    %eax,0x4(%esp)
80101e3c:	89 14 24             	mov    %edx,(%esp)
80101e3f:	e8 62 e3 ff ff       	call   801001a6 <bread>
80101e44:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80101e47:	8b 45 10             	mov    0x10(%ebp),%eax
80101e4a:	89 c2                	mov    %eax,%edx
80101e4c:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80101e52:	b8 00 02 00 00       	mov    $0x200,%eax
80101e57:	89 c1                	mov    %eax,%ecx
80101e59:	29 d1                	sub    %edx,%ecx
80101e5b:	89 ca                	mov    %ecx,%edx
80101e5d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101e60:	8b 4d 14             	mov    0x14(%ebp),%ecx
80101e63:	89 cb                	mov    %ecx,%ebx
80101e65:	29 c3                	sub    %eax,%ebx
80101e67:	89 d8                	mov    %ebx,%eax
80101e69:	39 c2                	cmp    %eax,%edx
80101e6b:	0f 46 c2             	cmovbe %edx,%eax
80101e6e:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dst, bp->data + off%BSIZE, m);
80101e71:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101e74:	8d 50 18             	lea    0x18(%eax),%edx
80101e77:	8b 45 10             	mov    0x10(%ebp),%eax
80101e7a:	25 ff 01 00 00       	and    $0x1ff,%eax
80101e7f:	01 c2                	add    %eax,%edx
80101e81:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101e84:	89 44 24 08          	mov    %eax,0x8(%esp)
80101e88:	89 54 24 04          	mov    %edx,0x4(%esp)
80101e8c:	8b 45 0c             	mov    0xc(%ebp),%eax
80101e8f:	89 04 24             	mov    %eax,(%esp)
80101e92:	e8 7a 35 00 00       	call   80105411 <memmove>
    brelse(bp);
80101e97:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101e9a:	89 04 24             	mov    %eax,(%esp)
80101e9d:	e8 75 e3 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101ea2:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101ea5:	01 45 f4             	add    %eax,-0xc(%ebp)
80101ea8:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101eab:	01 45 10             	add    %eax,0x10(%ebp)
80101eae:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101eb1:	01 45 0c             	add    %eax,0xc(%ebp)
80101eb4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101eb7:	3b 45 14             	cmp    0x14(%ebp),%eax
80101eba:	0f 82 5e ff ff ff    	jb     80101e1e <readi+0xc0>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    memmove(dst, bp->data + off%BSIZE, m);
    brelse(bp);
  }
  return n;
80101ec0:	8b 45 14             	mov    0x14(%ebp),%eax
}
80101ec3:	83 c4 24             	add    $0x24,%esp
80101ec6:	5b                   	pop    %ebx
80101ec7:	5d                   	pop    %ebp
80101ec8:	c3                   	ret    

80101ec9 <writei>:

// PAGEBREAK!
// Write data to inode.
int
writei(struct inode *ip, char *src, uint off, uint n)
{
80101ec9:	55                   	push   %ebp
80101eca:	89 e5                	mov    %esp,%ebp
80101ecc:	53                   	push   %ebx
80101ecd:	83 ec 24             	sub    $0x24,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80101ed0:	8b 45 08             	mov    0x8(%ebp),%eax
80101ed3:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101ed7:	66 83 f8 03          	cmp    $0x3,%ax
80101edb:	75 60                	jne    80101f3d <writei+0x74>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
80101edd:	8b 45 08             	mov    0x8(%ebp),%eax
80101ee0:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101ee4:	66 85 c0             	test   %ax,%ax
80101ee7:	78 20                	js     80101f09 <writei+0x40>
80101ee9:	8b 45 08             	mov    0x8(%ebp),%eax
80101eec:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101ef0:	66 83 f8 09          	cmp    $0x9,%ax
80101ef4:	7f 13                	jg     80101f09 <writei+0x40>
80101ef6:	8b 45 08             	mov    0x8(%ebp),%eax
80101ef9:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101efd:	98                   	cwtl   
80101efe:	8b 04 c5 04 e8 10 80 	mov    -0x7fef17fc(,%eax,8),%eax
80101f05:	85 c0                	test   %eax,%eax
80101f07:	75 0a                	jne    80101f13 <writei+0x4a>
      return -1;
80101f09:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101f0e:	e9 46 01 00 00       	jmp    80102059 <writei+0x190>
    return devsw[ip->major].write(ip, src, n);
80101f13:	8b 45 08             	mov    0x8(%ebp),%eax
80101f16:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101f1a:	98                   	cwtl   
80101f1b:	8b 14 c5 04 e8 10 80 	mov    -0x7fef17fc(,%eax,8),%edx
80101f22:	8b 45 14             	mov    0x14(%ebp),%eax
80101f25:	89 44 24 08          	mov    %eax,0x8(%esp)
80101f29:	8b 45 0c             	mov    0xc(%ebp),%eax
80101f2c:	89 44 24 04          	mov    %eax,0x4(%esp)
80101f30:	8b 45 08             	mov    0x8(%ebp),%eax
80101f33:	89 04 24             	mov    %eax,(%esp)
80101f36:	ff d2                	call   *%edx
80101f38:	e9 1c 01 00 00       	jmp    80102059 <writei+0x190>
  }

  if(off > ip->size || off + n < off)
80101f3d:	8b 45 08             	mov    0x8(%ebp),%eax
80101f40:	8b 40 18             	mov    0x18(%eax),%eax
80101f43:	3b 45 10             	cmp    0x10(%ebp),%eax
80101f46:	72 0d                	jb     80101f55 <writei+0x8c>
80101f48:	8b 45 14             	mov    0x14(%ebp),%eax
80101f4b:	8b 55 10             	mov    0x10(%ebp),%edx
80101f4e:	01 d0                	add    %edx,%eax
80101f50:	3b 45 10             	cmp    0x10(%ebp),%eax
80101f53:	73 0a                	jae    80101f5f <writei+0x96>
    return -1;
80101f55:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101f5a:	e9 fa 00 00 00       	jmp    80102059 <writei+0x190>
  if(off + n > MAXFILE*BSIZE)
80101f5f:	8b 45 14             	mov    0x14(%ebp),%eax
80101f62:	8b 55 10             	mov    0x10(%ebp),%edx
80101f65:	01 d0                	add    %edx,%eax
80101f67:	3d 00 18 01 00       	cmp    $0x11800,%eax
80101f6c:	76 0a                	jbe    80101f78 <writei+0xaf>
    return -1;
80101f6e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101f73:	e9 e1 00 00 00       	jmp    80102059 <writei+0x190>

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80101f78:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101f7f:	e9 a1 00 00 00       	jmp    80102025 <writei+0x15c>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80101f84:	8b 45 10             	mov    0x10(%ebp),%eax
80101f87:	c1 e8 09             	shr    $0x9,%eax
80101f8a:	89 44 24 04          	mov    %eax,0x4(%esp)
80101f8e:	8b 45 08             	mov    0x8(%ebp),%eax
80101f91:	89 04 24             	mov    %eax,(%esp)
80101f94:	e8 71 fb ff ff       	call   80101b0a <bmap>
80101f99:	8b 55 08             	mov    0x8(%ebp),%edx
80101f9c:	8b 12                	mov    (%edx),%edx
80101f9e:	89 44 24 04          	mov    %eax,0x4(%esp)
80101fa2:	89 14 24             	mov    %edx,(%esp)
80101fa5:	e8 fc e1 ff ff       	call   801001a6 <bread>
80101faa:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80101fad:	8b 45 10             	mov    0x10(%ebp),%eax
80101fb0:	89 c2                	mov    %eax,%edx
80101fb2:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80101fb8:	b8 00 02 00 00       	mov    $0x200,%eax
80101fbd:	89 c1                	mov    %eax,%ecx
80101fbf:	29 d1                	sub    %edx,%ecx
80101fc1:	89 ca                	mov    %ecx,%edx
80101fc3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101fc6:	8b 4d 14             	mov    0x14(%ebp),%ecx
80101fc9:	89 cb                	mov    %ecx,%ebx
80101fcb:	29 c3                	sub    %eax,%ebx
80101fcd:	89 d8                	mov    %ebx,%eax
80101fcf:	39 c2                	cmp    %eax,%edx
80101fd1:	0f 46 c2             	cmovbe %edx,%eax
80101fd4:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(bp->data + off%BSIZE, src, m);
80101fd7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101fda:	8d 50 18             	lea    0x18(%eax),%edx
80101fdd:	8b 45 10             	mov    0x10(%ebp),%eax
80101fe0:	25 ff 01 00 00       	and    $0x1ff,%eax
80101fe5:	01 c2                	add    %eax,%edx
80101fe7:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101fea:	89 44 24 08          	mov    %eax,0x8(%esp)
80101fee:	8b 45 0c             	mov    0xc(%ebp),%eax
80101ff1:	89 44 24 04          	mov    %eax,0x4(%esp)
80101ff5:	89 14 24             	mov    %edx,(%esp)
80101ff8:	e8 14 34 00 00       	call   80105411 <memmove>
    log_write(bp);
80101ffd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102000:	89 04 24             	mov    %eax,(%esp)
80102003:	e8 c2 12 00 00       	call   801032ca <log_write>
    brelse(bp);
80102008:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010200b:	89 04 24             	mov    %eax,(%esp)
8010200e:	e8 04 e2 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > MAXFILE*BSIZE)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80102013:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102016:	01 45 f4             	add    %eax,-0xc(%ebp)
80102019:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010201c:	01 45 10             	add    %eax,0x10(%ebp)
8010201f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102022:	01 45 0c             	add    %eax,0xc(%ebp)
80102025:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102028:	3b 45 14             	cmp    0x14(%ebp),%eax
8010202b:	0f 82 53 ff ff ff    	jb     80101f84 <writei+0xbb>
    memmove(bp->data + off%BSIZE, src, m);
    log_write(bp);
    brelse(bp);
  }

  if(n > 0 && off > ip->size){
80102031:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
80102035:	74 1f                	je     80102056 <writei+0x18d>
80102037:	8b 45 08             	mov    0x8(%ebp),%eax
8010203a:	8b 40 18             	mov    0x18(%eax),%eax
8010203d:	3b 45 10             	cmp    0x10(%ebp),%eax
80102040:	73 14                	jae    80102056 <writei+0x18d>
    ip->size = off;
80102042:	8b 45 08             	mov    0x8(%ebp),%eax
80102045:	8b 55 10             	mov    0x10(%ebp),%edx
80102048:	89 50 18             	mov    %edx,0x18(%eax)
    iupdate(ip);
8010204b:	8b 45 08             	mov    0x8(%ebp),%eax
8010204e:	89 04 24             	mov    %eax,(%esp)
80102051:	e8 56 f6 ff ff       	call   801016ac <iupdate>
  }
  return n;
80102056:	8b 45 14             	mov    0x14(%ebp),%eax
}
80102059:	83 c4 24             	add    $0x24,%esp
8010205c:	5b                   	pop    %ebx
8010205d:	5d                   	pop    %ebp
8010205e:	c3                   	ret    

8010205f <namecmp>:
//PAGEBREAK!
// Directories

int
namecmp(const char *s, const char *t)
{
8010205f:	55                   	push   %ebp
80102060:	89 e5                	mov    %esp,%ebp
80102062:	83 ec 18             	sub    $0x18,%esp
  return strncmp(s, t, DIRSIZ);
80102065:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
8010206c:	00 
8010206d:	8b 45 0c             	mov    0xc(%ebp),%eax
80102070:	89 44 24 04          	mov    %eax,0x4(%esp)
80102074:	8b 45 08             	mov    0x8(%ebp),%eax
80102077:	89 04 24             	mov    %eax,(%esp)
8010207a:	e8 36 34 00 00       	call   801054b5 <strncmp>
}
8010207f:	c9                   	leave  
80102080:	c3                   	ret    

80102081 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
80102081:	55                   	push   %ebp
80102082:	89 e5                	mov    %esp,%ebp
80102084:	83 ec 38             	sub    $0x38,%esp
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
80102087:	8b 45 08             	mov    0x8(%ebp),%eax
8010208a:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010208e:	66 83 f8 01          	cmp    $0x1,%ax
80102092:	74 0c                	je     801020a0 <dirlookup+0x1f>
    panic("dirlookup not DIR");
80102094:	c7 04 24 75 89 10 80 	movl   $0x80108975,(%esp)
8010209b:	e8 9d e4 ff ff       	call   8010053d <panic>

  for(off = 0; off < dp->size; off += sizeof(de)){
801020a0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801020a7:	e9 87 00 00 00       	jmp    80102133 <dirlookup+0xb2>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801020ac:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801020b3:	00 
801020b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801020b7:	89 44 24 08          	mov    %eax,0x8(%esp)
801020bb:	8d 45 e0             	lea    -0x20(%ebp),%eax
801020be:	89 44 24 04          	mov    %eax,0x4(%esp)
801020c2:	8b 45 08             	mov    0x8(%ebp),%eax
801020c5:	89 04 24             	mov    %eax,(%esp)
801020c8:	e8 91 fc ff ff       	call   80101d5e <readi>
801020cd:	83 f8 10             	cmp    $0x10,%eax
801020d0:	74 0c                	je     801020de <dirlookup+0x5d>
      panic("dirlink read");
801020d2:	c7 04 24 87 89 10 80 	movl   $0x80108987,(%esp)
801020d9:	e8 5f e4 ff ff       	call   8010053d <panic>
    if(de.inum == 0)
801020de:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801020e2:	66 85 c0             	test   %ax,%ax
801020e5:	74 47                	je     8010212e <dirlookup+0xad>
      continue;
    if(namecmp(name, de.name) == 0){
801020e7:	8d 45 e0             	lea    -0x20(%ebp),%eax
801020ea:	83 c0 02             	add    $0x2,%eax
801020ed:	89 44 24 04          	mov    %eax,0x4(%esp)
801020f1:	8b 45 0c             	mov    0xc(%ebp),%eax
801020f4:	89 04 24             	mov    %eax,(%esp)
801020f7:	e8 63 ff ff ff       	call   8010205f <namecmp>
801020fc:	85 c0                	test   %eax,%eax
801020fe:	75 2f                	jne    8010212f <dirlookup+0xae>
      // entry matches path element
      if(poff)
80102100:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80102104:	74 08                	je     8010210e <dirlookup+0x8d>
        *poff = off;
80102106:	8b 45 10             	mov    0x10(%ebp),%eax
80102109:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010210c:	89 10                	mov    %edx,(%eax)
      inum = de.inum;
8010210e:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102112:	0f b7 c0             	movzwl %ax,%eax
80102115:	89 45 f0             	mov    %eax,-0x10(%ebp)
      return iget(dp->dev, inum);
80102118:	8b 45 08             	mov    0x8(%ebp),%eax
8010211b:	8b 00                	mov    (%eax),%eax
8010211d:	8b 55 f0             	mov    -0x10(%ebp),%edx
80102120:	89 54 24 04          	mov    %edx,0x4(%esp)
80102124:	89 04 24             	mov    %eax,(%esp)
80102127:	e8 38 f6 ff ff       	call   80101764 <iget>
8010212c:	eb 19                	jmp    80102147 <dirlookup+0xc6>

  for(off = 0; off < dp->size; off += sizeof(de)){
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
    if(de.inum == 0)
      continue;
8010212e:	90                   	nop
  struct dirent de;

  if(dp->type != T_DIR)
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
8010212f:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80102133:	8b 45 08             	mov    0x8(%ebp),%eax
80102136:	8b 40 18             	mov    0x18(%eax),%eax
80102139:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010213c:	0f 87 6a ff ff ff    	ja     801020ac <dirlookup+0x2b>
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
80102142:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102147:	c9                   	leave  
80102148:	c3                   	ret    

80102149 <dirlink>:

// Write a new directory entry (name, inum) into the directory dp.
int
dirlink(struct inode *dp, char *name, uint inum)
{
80102149:	55                   	push   %ebp
8010214a:	89 e5                	mov    %esp,%ebp
8010214c:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;
  struct inode *ip;

  // Check that name is not present.
  if((ip = dirlookup(dp, name, 0)) != 0){
8010214f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80102156:	00 
80102157:	8b 45 0c             	mov    0xc(%ebp),%eax
8010215a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010215e:	8b 45 08             	mov    0x8(%ebp),%eax
80102161:	89 04 24             	mov    %eax,(%esp)
80102164:	e8 18 ff ff ff       	call   80102081 <dirlookup>
80102169:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010216c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80102170:	74 15                	je     80102187 <dirlink+0x3e>
    iput(ip);
80102172:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102175:	89 04 24             	mov    %eax,(%esp)
80102178:	e8 9e f8 ff ff       	call   80101a1b <iput>
    return -1;
8010217d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102182:	e9 b8 00 00 00       	jmp    8010223f <dirlink+0xf6>
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
80102187:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010218e:	eb 44                	jmp    801021d4 <dirlink+0x8b>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102190:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102193:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
8010219a:	00 
8010219b:	89 44 24 08          	mov    %eax,0x8(%esp)
8010219f:	8d 45 e0             	lea    -0x20(%ebp),%eax
801021a2:	89 44 24 04          	mov    %eax,0x4(%esp)
801021a6:	8b 45 08             	mov    0x8(%ebp),%eax
801021a9:	89 04 24             	mov    %eax,(%esp)
801021ac:	e8 ad fb ff ff       	call   80101d5e <readi>
801021b1:	83 f8 10             	cmp    $0x10,%eax
801021b4:	74 0c                	je     801021c2 <dirlink+0x79>
      panic("dirlink read");
801021b6:	c7 04 24 87 89 10 80 	movl   $0x80108987,(%esp)
801021bd:	e8 7b e3 ff ff       	call   8010053d <panic>
    if(de.inum == 0)
801021c2:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801021c6:	66 85 c0             	test   %ax,%ax
801021c9:	74 18                	je     801021e3 <dirlink+0x9a>
    iput(ip);
    return -1;
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
801021cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801021ce:	83 c0 10             	add    $0x10,%eax
801021d1:	89 45 f4             	mov    %eax,-0xc(%ebp)
801021d4:	8b 55 f4             	mov    -0xc(%ebp),%edx
801021d7:	8b 45 08             	mov    0x8(%ebp),%eax
801021da:	8b 40 18             	mov    0x18(%eax),%eax
801021dd:	39 c2                	cmp    %eax,%edx
801021df:	72 af                	jb     80102190 <dirlink+0x47>
801021e1:	eb 01                	jmp    801021e4 <dirlink+0x9b>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
    if(de.inum == 0)
      break;
801021e3:	90                   	nop
  }

  strncpy(de.name, name, DIRSIZ);
801021e4:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
801021eb:	00 
801021ec:	8b 45 0c             	mov    0xc(%ebp),%eax
801021ef:	89 44 24 04          	mov    %eax,0x4(%esp)
801021f3:	8d 45 e0             	lea    -0x20(%ebp),%eax
801021f6:	83 c0 02             	add    $0x2,%eax
801021f9:	89 04 24             	mov    %eax,(%esp)
801021fc:	e8 0c 33 00 00       	call   8010550d <strncpy>
  de.inum = inum;
80102201:	8b 45 10             	mov    0x10(%ebp),%eax
80102204:	66 89 45 e0          	mov    %ax,-0x20(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102208:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010220b:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102212:	00 
80102213:	89 44 24 08          	mov    %eax,0x8(%esp)
80102217:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010221a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010221e:	8b 45 08             	mov    0x8(%ebp),%eax
80102221:	89 04 24             	mov    %eax,(%esp)
80102224:	e8 a0 fc ff ff       	call   80101ec9 <writei>
80102229:	83 f8 10             	cmp    $0x10,%eax
8010222c:	74 0c                	je     8010223a <dirlink+0xf1>
    panic("dirlink");
8010222e:	c7 04 24 94 89 10 80 	movl   $0x80108994,(%esp)
80102235:	e8 03 e3 ff ff       	call   8010053d <panic>
  
  return 0;
8010223a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010223f:	c9                   	leave  
80102240:	c3                   	ret    

80102241 <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
80102241:	55                   	push   %ebp
80102242:	89 e5                	mov    %esp,%ebp
80102244:	83 ec 28             	sub    $0x28,%esp
  char *s;
  int len;

  while(*path == '/')
80102247:	eb 04                	jmp    8010224d <skipelem+0xc>
    path++;
80102249:	83 45 08 01          	addl   $0x1,0x8(%ebp)
skipelem(char *path, char *name)
{
  char *s;
  int len;

  while(*path == '/')
8010224d:	8b 45 08             	mov    0x8(%ebp),%eax
80102250:	0f b6 00             	movzbl (%eax),%eax
80102253:	3c 2f                	cmp    $0x2f,%al
80102255:	74 f2                	je     80102249 <skipelem+0x8>
    path++;
  if(*path == 0)
80102257:	8b 45 08             	mov    0x8(%ebp),%eax
8010225a:	0f b6 00             	movzbl (%eax),%eax
8010225d:	84 c0                	test   %al,%al
8010225f:	75 0a                	jne    8010226b <skipelem+0x2a>
    return 0;
80102261:	b8 00 00 00 00       	mov    $0x0,%eax
80102266:	e9 86 00 00 00       	jmp    801022f1 <skipelem+0xb0>
  s = path;
8010226b:	8b 45 08             	mov    0x8(%ebp),%eax
8010226e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(*path != '/' && *path != 0)
80102271:	eb 04                	jmp    80102277 <skipelem+0x36>
    path++;
80102273:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  while(*path == '/')
    path++;
  if(*path == 0)
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
80102277:	8b 45 08             	mov    0x8(%ebp),%eax
8010227a:	0f b6 00             	movzbl (%eax),%eax
8010227d:	3c 2f                	cmp    $0x2f,%al
8010227f:	74 0a                	je     8010228b <skipelem+0x4a>
80102281:	8b 45 08             	mov    0x8(%ebp),%eax
80102284:	0f b6 00             	movzbl (%eax),%eax
80102287:	84 c0                	test   %al,%al
80102289:	75 e8                	jne    80102273 <skipelem+0x32>
    path++;
  len = path - s;
8010228b:	8b 55 08             	mov    0x8(%ebp),%edx
8010228e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102291:	89 d1                	mov    %edx,%ecx
80102293:	29 c1                	sub    %eax,%ecx
80102295:	89 c8                	mov    %ecx,%eax
80102297:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(len >= DIRSIZ)
8010229a:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
8010229e:	7e 1c                	jle    801022bc <skipelem+0x7b>
    memmove(name, s, DIRSIZ);
801022a0:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
801022a7:	00 
801022a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801022ab:	89 44 24 04          	mov    %eax,0x4(%esp)
801022af:	8b 45 0c             	mov    0xc(%ebp),%eax
801022b2:	89 04 24             	mov    %eax,(%esp)
801022b5:	e8 57 31 00 00       	call   80105411 <memmove>
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
801022ba:	eb 28                	jmp    801022e4 <skipelem+0xa3>
    path++;
  len = path - s;
  if(len >= DIRSIZ)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
801022bc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801022bf:	89 44 24 08          	mov    %eax,0x8(%esp)
801022c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801022c6:	89 44 24 04          	mov    %eax,0x4(%esp)
801022ca:	8b 45 0c             	mov    0xc(%ebp),%eax
801022cd:	89 04 24             	mov    %eax,(%esp)
801022d0:	e8 3c 31 00 00       	call   80105411 <memmove>
    name[len] = 0;
801022d5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801022d8:	03 45 0c             	add    0xc(%ebp),%eax
801022db:	c6 00 00             	movb   $0x0,(%eax)
  }
  while(*path == '/')
801022de:	eb 04                	jmp    801022e4 <skipelem+0xa3>
    path++;
801022e0:	83 45 08 01          	addl   $0x1,0x8(%ebp)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
801022e4:	8b 45 08             	mov    0x8(%ebp),%eax
801022e7:	0f b6 00             	movzbl (%eax),%eax
801022ea:	3c 2f                	cmp    $0x2f,%al
801022ec:	74 f2                	je     801022e0 <skipelem+0x9f>
    path++;
  return path;
801022ee:	8b 45 08             	mov    0x8(%ebp),%eax
}
801022f1:	c9                   	leave  
801022f2:	c3                   	ret    

801022f3 <namex>:
// Look up and return the inode for a path name.
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
static struct inode*
namex(char *path, int nameiparent, char *name)
{
801022f3:	55                   	push   %ebp
801022f4:	89 e5                	mov    %esp,%ebp
801022f6:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *next;
  if(*path == '/')
801022f9:	8b 45 08             	mov    0x8(%ebp),%eax
801022fc:	0f b6 00             	movzbl (%eax),%eax
801022ff:	3c 2f                	cmp    $0x2f,%al
80102301:	75 1c                	jne    8010231f <namex+0x2c>
    ip = iget(ROOTDEV, ROOTINO);
80102303:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010230a:	00 
8010230b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102312:	e8 4d f4 ff ff       	call   80101764 <iget>
80102317:	89 45 f4             	mov    %eax,-0xc(%ebp)
  else
    ip = idup(proc->cwd);
  while((path = skipelem(path, name)) != 0){
8010231a:	e9 af 00 00 00       	jmp    801023ce <namex+0xdb>
{
  struct inode *ip, *next;
  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);
8010231f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80102325:	8b 40 68             	mov    0x68(%eax),%eax
80102328:	89 04 24             	mov    %eax,(%esp)
8010232b:	e8 06 f5 ff ff       	call   80101836 <idup>
80102330:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while((path = skipelem(path, name)) != 0){
80102333:	e9 96 00 00 00       	jmp    801023ce <namex+0xdb>
    ilock(ip);
80102338:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010233b:	89 04 24             	mov    %eax,(%esp)
8010233e:	e8 25 f5 ff ff       	call   80101868 <ilock>
    if(ip->type != T_DIR){
80102343:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102346:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010234a:	66 83 f8 01          	cmp    $0x1,%ax
8010234e:	74 15                	je     80102365 <namex+0x72>
      iunlockput(ip);
80102350:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102353:	89 04 24             	mov    %eax,(%esp)
80102356:	e8 91 f7 ff ff       	call   80101aec <iunlockput>
      return 0;
8010235b:	b8 00 00 00 00       	mov    $0x0,%eax
80102360:	e9 a3 00 00 00       	jmp    80102408 <namex+0x115>
    }
    if(nameiparent && *path == '\0'){
80102365:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102369:	74 1d                	je     80102388 <namex+0x95>
8010236b:	8b 45 08             	mov    0x8(%ebp),%eax
8010236e:	0f b6 00             	movzbl (%eax),%eax
80102371:	84 c0                	test   %al,%al
80102373:	75 13                	jne    80102388 <namex+0x95>
      // Stop one level early.
      iunlock(ip);
80102375:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102378:	89 04 24             	mov    %eax,(%esp)
8010237b:	e8 36 f6 ff ff       	call   801019b6 <iunlock>
      return ip;
80102380:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102383:	e9 80 00 00 00       	jmp    80102408 <namex+0x115>
    }
    if((next = dirlookup(ip, name, 0)) == 0){
80102388:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010238f:	00 
80102390:	8b 45 10             	mov    0x10(%ebp),%eax
80102393:	89 44 24 04          	mov    %eax,0x4(%esp)
80102397:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010239a:	89 04 24             	mov    %eax,(%esp)
8010239d:	e8 df fc ff ff       	call   80102081 <dirlookup>
801023a2:	89 45 f0             	mov    %eax,-0x10(%ebp)
801023a5:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801023a9:	75 12                	jne    801023bd <namex+0xca>
      iunlockput(ip);
801023ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023ae:	89 04 24             	mov    %eax,(%esp)
801023b1:	e8 36 f7 ff ff       	call   80101aec <iunlockput>
      return 0;
801023b6:	b8 00 00 00 00       	mov    $0x0,%eax
801023bb:	eb 4b                	jmp    80102408 <namex+0x115>
    }
    iunlockput(ip);
801023bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023c0:	89 04 24             	mov    %eax,(%esp)
801023c3:	e8 24 f7 ff ff       	call   80101aec <iunlockput>
    ip = next;
801023c8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801023cb:	89 45 f4             	mov    %eax,-0xc(%ebp)
  struct inode *ip, *next;
  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);
  while((path = skipelem(path, name)) != 0){
801023ce:	8b 45 10             	mov    0x10(%ebp),%eax
801023d1:	89 44 24 04          	mov    %eax,0x4(%esp)
801023d5:	8b 45 08             	mov    0x8(%ebp),%eax
801023d8:	89 04 24             	mov    %eax,(%esp)
801023db:	e8 61 fe ff ff       	call   80102241 <skipelem>
801023e0:	89 45 08             	mov    %eax,0x8(%ebp)
801023e3:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801023e7:	0f 85 4b ff ff ff    	jne    80102338 <namex+0x45>
      return 0;
    }
    iunlockput(ip);
    ip = next;
  }
  if(nameiparent){
801023ed:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801023f1:	74 12                	je     80102405 <namex+0x112>
    iput(ip);
801023f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023f6:	89 04 24             	mov    %eax,(%esp)
801023f9:	e8 1d f6 ff ff       	call   80101a1b <iput>
    return 0;
801023fe:	b8 00 00 00 00       	mov    $0x0,%eax
80102403:	eb 03                	jmp    80102408 <namex+0x115>
  }
  return ip;
80102405:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102408:	c9                   	leave  
80102409:	c3                   	ret    

8010240a <namei>:

struct inode*
namei(char *path)
{
8010240a:	55                   	push   %ebp
8010240b:	89 e5                	mov    %esp,%ebp
8010240d:	83 ec 28             	sub    $0x28,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
80102410:	8d 45 ea             	lea    -0x16(%ebp),%eax
80102413:	89 44 24 08          	mov    %eax,0x8(%esp)
80102417:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010241e:	00 
8010241f:	8b 45 08             	mov    0x8(%ebp),%eax
80102422:	89 04 24             	mov    %eax,(%esp)
80102425:	e8 c9 fe ff ff       	call   801022f3 <namex>
}
8010242a:	c9                   	leave  
8010242b:	c3                   	ret    

8010242c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
8010242c:	55                   	push   %ebp
8010242d:	89 e5                	mov    %esp,%ebp
8010242f:	83 ec 18             	sub    $0x18,%esp
  return namex(path, 1, name);
80102432:	8b 45 0c             	mov    0xc(%ebp),%eax
80102435:	89 44 24 08          	mov    %eax,0x8(%esp)
80102439:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102440:	00 
80102441:	8b 45 08             	mov    0x8(%ebp),%eax
80102444:	89 04 24             	mov    %eax,(%esp)
80102447:	e8 a7 fe ff ff       	call   801022f3 <namex>
}
8010244c:	c9                   	leave  
8010244d:	c3                   	ret    
	...

80102450 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102450:	55                   	push   %ebp
80102451:	89 e5                	mov    %esp,%ebp
80102453:	53                   	push   %ebx
80102454:	83 ec 14             	sub    $0x14,%esp
80102457:	8b 45 08             	mov    0x8(%ebp),%eax
8010245a:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010245e:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80102462:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80102466:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
8010246a:	ec                   	in     (%dx),%al
8010246b:	89 c3                	mov    %eax,%ebx
8010246d:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80102470:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80102474:	83 c4 14             	add    $0x14,%esp
80102477:	5b                   	pop    %ebx
80102478:	5d                   	pop    %ebp
80102479:	c3                   	ret    

8010247a <insl>:

static inline void
insl(int port, void *addr, int cnt)
{
8010247a:	55                   	push   %ebp
8010247b:	89 e5                	mov    %esp,%ebp
8010247d:	57                   	push   %edi
8010247e:	53                   	push   %ebx
  asm volatile("cld; rep insl" :
8010247f:	8b 55 08             	mov    0x8(%ebp),%edx
80102482:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80102485:	8b 45 10             	mov    0x10(%ebp),%eax
80102488:	89 cb                	mov    %ecx,%ebx
8010248a:	89 df                	mov    %ebx,%edi
8010248c:	89 c1                	mov    %eax,%ecx
8010248e:	fc                   	cld    
8010248f:	f3 6d                	rep insl (%dx),%es:(%edi)
80102491:	89 c8                	mov    %ecx,%eax
80102493:	89 fb                	mov    %edi,%ebx
80102495:	89 5d 0c             	mov    %ebx,0xc(%ebp)
80102498:	89 45 10             	mov    %eax,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "memory", "cc");
}
8010249b:	5b                   	pop    %ebx
8010249c:	5f                   	pop    %edi
8010249d:	5d                   	pop    %ebp
8010249e:	c3                   	ret    

8010249f <outb>:

static inline void
outb(ushort port, uchar data)
{
8010249f:	55                   	push   %ebp
801024a0:	89 e5                	mov    %esp,%ebp
801024a2:	83 ec 08             	sub    $0x8,%esp
801024a5:	8b 55 08             	mov    0x8(%ebp),%edx
801024a8:	8b 45 0c             	mov    0xc(%ebp),%eax
801024ab:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801024af:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801024b2:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801024b6:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801024ba:	ee                   	out    %al,(%dx)
}
801024bb:	c9                   	leave  
801024bc:	c3                   	ret    

801024bd <outsl>:
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
}

static inline void
outsl(int port, const void *addr, int cnt)
{
801024bd:	55                   	push   %ebp
801024be:	89 e5                	mov    %esp,%ebp
801024c0:	56                   	push   %esi
801024c1:	53                   	push   %ebx
  asm volatile("cld; rep outsl" :
801024c2:	8b 55 08             	mov    0x8(%ebp),%edx
801024c5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801024c8:	8b 45 10             	mov    0x10(%ebp),%eax
801024cb:	89 cb                	mov    %ecx,%ebx
801024cd:	89 de                	mov    %ebx,%esi
801024cf:	89 c1                	mov    %eax,%ecx
801024d1:	fc                   	cld    
801024d2:	f3 6f                	rep outsl %ds:(%esi),(%dx)
801024d4:	89 c8                	mov    %ecx,%eax
801024d6:	89 f3                	mov    %esi,%ebx
801024d8:	89 5d 0c             	mov    %ebx,0xc(%ebp)
801024db:	89 45 10             	mov    %eax,0x10(%ebp)
               "=S" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "cc");
}
801024de:	5b                   	pop    %ebx
801024df:	5e                   	pop    %esi
801024e0:	5d                   	pop    %ebp
801024e1:	c3                   	ret    

801024e2 <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
801024e2:	55                   	push   %ebp
801024e3:	89 e5                	mov    %esp,%ebp
801024e5:	83 ec 14             	sub    $0x14,%esp
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY) 
801024e8:	90                   	nop
801024e9:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801024f0:	e8 5b ff ff ff       	call   80102450 <inb>
801024f5:	0f b6 c0             	movzbl %al,%eax
801024f8:	89 45 fc             	mov    %eax,-0x4(%ebp)
801024fb:	8b 45 fc             	mov    -0x4(%ebp),%eax
801024fe:	25 c0 00 00 00       	and    $0xc0,%eax
80102503:	83 f8 40             	cmp    $0x40,%eax
80102506:	75 e1                	jne    801024e9 <idewait+0x7>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
80102508:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010250c:	74 11                	je     8010251f <idewait+0x3d>
8010250e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102511:	83 e0 21             	and    $0x21,%eax
80102514:	85 c0                	test   %eax,%eax
80102516:	74 07                	je     8010251f <idewait+0x3d>
    return -1;
80102518:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010251d:	eb 05                	jmp    80102524 <idewait+0x42>
  return 0;
8010251f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102524:	c9                   	leave  
80102525:	c3                   	ret    

80102526 <ideinit>:

void
ideinit(void)
{
80102526:	55                   	push   %ebp
80102527:	89 e5                	mov    %esp,%ebp
80102529:	83 ec 28             	sub    $0x28,%esp
  int i;

  initlock(&idelock, "ide");
8010252c:	c7 44 24 04 9c 89 10 	movl   $0x8010899c,0x4(%esp)
80102533:	80 
80102534:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
8010253b:	e8 56 2b 00 00       	call   80105096 <initlock>
  picenable(IRQ_IDE);
80102540:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
80102547:	e8 81 15 00 00       	call   80103acd <picenable>
  ioapicenable(IRQ_IDE, ncpu - 1);
8010254c:	a1 00 ff 10 80       	mov    0x8010ff00,%eax
80102551:	83 e8 01             	sub    $0x1,%eax
80102554:	89 44 24 04          	mov    %eax,0x4(%esp)
80102558:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
8010255f:	e8 1e 04 00 00       	call   80102982 <ioapicenable>
  idewait(0);
80102564:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010256b:	e8 72 ff ff ff       	call   801024e2 <idewait>
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
80102570:	c7 44 24 04 f0 00 00 	movl   $0xf0,0x4(%esp)
80102577:	00 
80102578:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
8010257f:	e8 1b ff ff ff       	call   8010249f <outb>
  for(i=0; i<1000; i++){
80102584:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010258b:	eb 20                	jmp    801025ad <ideinit+0x87>
    if(inb(0x1f7) != 0){
8010258d:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102594:	e8 b7 fe ff ff       	call   80102450 <inb>
80102599:	84 c0                	test   %al,%al
8010259b:	74 0c                	je     801025a9 <ideinit+0x83>
      havedisk1 = 1;
8010259d:	c7 05 38 b6 10 80 01 	movl   $0x1,0x8010b638
801025a4:	00 00 00 
      break;
801025a7:	eb 0d                	jmp    801025b6 <ideinit+0x90>
  ioapicenable(IRQ_IDE, ncpu - 1);
  idewait(0);
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
  for(i=0; i<1000; i++){
801025a9:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801025ad:	81 7d f4 e7 03 00 00 	cmpl   $0x3e7,-0xc(%ebp)
801025b4:	7e d7                	jle    8010258d <ideinit+0x67>
      break;
    }
  }
  
  // Switch back to disk 0.
  outb(0x1f6, 0xe0 | (0<<4));
801025b6:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
801025bd:	00 
801025be:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
801025c5:	e8 d5 fe ff ff       	call   8010249f <outb>
}
801025ca:	c9                   	leave  
801025cb:	c3                   	ret    

801025cc <idestart>:

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
801025cc:	55                   	push   %ebp
801025cd:	89 e5                	mov    %esp,%ebp
801025cf:	83 ec 18             	sub    $0x18,%esp
  if(b == 0)
801025d2:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801025d6:	75 0c                	jne    801025e4 <idestart+0x18>
    panic("idestart");
801025d8:	c7 04 24 a0 89 10 80 	movl   $0x801089a0,(%esp)
801025df:	e8 59 df ff ff       	call   8010053d <panic>

  idewait(0);
801025e4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801025eb:	e8 f2 fe ff ff       	call   801024e2 <idewait>
  outb(0x3f6, 0);  // generate interrupt
801025f0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801025f7:	00 
801025f8:	c7 04 24 f6 03 00 00 	movl   $0x3f6,(%esp)
801025ff:	e8 9b fe ff ff       	call   8010249f <outb>
  outb(0x1f2, 1);  // number of sectors
80102604:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010260b:	00 
8010260c:	c7 04 24 f2 01 00 00 	movl   $0x1f2,(%esp)
80102613:	e8 87 fe ff ff       	call   8010249f <outb>
  outb(0x1f3, b->sector & 0xff);
80102618:	8b 45 08             	mov    0x8(%ebp),%eax
8010261b:	8b 40 08             	mov    0x8(%eax),%eax
8010261e:	0f b6 c0             	movzbl %al,%eax
80102621:	89 44 24 04          	mov    %eax,0x4(%esp)
80102625:	c7 04 24 f3 01 00 00 	movl   $0x1f3,(%esp)
8010262c:	e8 6e fe ff ff       	call   8010249f <outb>
  outb(0x1f4, (b->sector >> 8) & 0xff);
80102631:	8b 45 08             	mov    0x8(%ebp),%eax
80102634:	8b 40 08             	mov    0x8(%eax),%eax
80102637:	c1 e8 08             	shr    $0x8,%eax
8010263a:	0f b6 c0             	movzbl %al,%eax
8010263d:	89 44 24 04          	mov    %eax,0x4(%esp)
80102641:	c7 04 24 f4 01 00 00 	movl   $0x1f4,(%esp)
80102648:	e8 52 fe ff ff       	call   8010249f <outb>
  outb(0x1f5, (b->sector >> 16) & 0xff);
8010264d:	8b 45 08             	mov    0x8(%ebp),%eax
80102650:	8b 40 08             	mov    0x8(%eax),%eax
80102653:	c1 e8 10             	shr    $0x10,%eax
80102656:	0f b6 c0             	movzbl %al,%eax
80102659:	89 44 24 04          	mov    %eax,0x4(%esp)
8010265d:	c7 04 24 f5 01 00 00 	movl   $0x1f5,(%esp)
80102664:	e8 36 fe ff ff       	call   8010249f <outb>
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((b->sector>>24)&0x0f));
80102669:	8b 45 08             	mov    0x8(%ebp),%eax
8010266c:	8b 40 04             	mov    0x4(%eax),%eax
8010266f:	83 e0 01             	and    $0x1,%eax
80102672:	89 c2                	mov    %eax,%edx
80102674:	c1 e2 04             	shl    $0x4,%edx
80102677:	8b 45 08             	mov    0x8(%ebp),%eax
8010267a:	8b 40 08             	mov    0x8(%eax),%eax
8010267d:	c1 e8 18             	shr    $0x18,%eax
80102680:	83 e0 0f             	and    $0xf,%eax
80102683:	09 d0                	or     %edx,%eax
80102685:	83 c8 e0             	or     $0xffffffe0,%eax
80102688:	0f b6 c0             	movzbl %al,%eax
8010268b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010268f:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102696:	e8 04 fe ff ff       	call   8010249f <outb>
  if(b->flags & B_DIRTY){
8010269b:	8b 45 08             	mov    0x8(%ebp),%eax
8010269e:	8b 00                	mov    (%eax),%eax
801026a0:	83 e0 04             	and    $0x4,%eax
801026a3:	85 c0                	test   %eax,%eax
801026a5:	74 34                	je     801026db <idestart+0x10f>
    outb(0x1f7, IDE_CMD_WRITE);
801026a7:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
801026ae:	00 
801026af:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801026b6:	e8 e4 fd ff ff       	call   8010249f <outb>
    outsl(0x1f0, b->data, 512/4);
801026bb:	8b 45 08             	mov    0x8(%ebp),%eax
801026be:	83 c0 18             	add    $0x18,%eax
801026c1:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
801026c8:	00 
801026c9:	89 44 24 04          	mov    %eax,0x4(%esp)
801026cd:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
801026d4:	e8 e4 fd ff ff       	call   801024bd <outsl>
801026d9:	eb 14                	jmp    801026ef <idestart+0x123>
  } else {
    outb(0x1f7, IDE_CMD_READ);
801026db:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
801026e2:	00 
801026e3:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801026ea:	e8 b0 fd ff ff       	call   8010249f <outb>
  }
}
801026ef:	c9                   	leave  
801026f0:	c3                   	ret    

801026f1 <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
801026f1:	55                   	push   %ebp
801026f2:	89 e5                	mov    %esp,%ebp
801026f4:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
801026f7:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
801026fe:	e8 b4 29 00 00       	call   801050b7 <acquire>
  if((b = idequeue) == 0){
80102703:	a1 34 b6 10 80       	mov    0x8010b634,%eax
80102708:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010270b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010270f:	75 11                	jne    80102722 <ideintr+0x31>
    release(&idelock);
80102711:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102718:	e8 35 2a 00 00       	call   80105152 <release>
    // cprintf("spurious IDE interrupt\n");
    return;
8010271d:	e9 85 00 00 00       	jmp    801027a7 <ideintr+0xb6>
  }
  idequeue = b->qnext;
80102722:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102725:	8b 40 14             	mov    0x14(%eax),%eax
80102728:	a3 34 b6 10 80       	mov    %eax,0x8010b634

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
8010272d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102730:	8b 00                	mov    (%eax),%eax
80102732:	83 e0 04             	and    $0x4,%eax
80102735:	85 c0                	test   %eax,%eax
80102737:	75 2e                	jne    80102767 <ideintr+0x76>
80102739:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102740:	e8 9d fd ff ff       	call   801024e2 <idewait>
80102745:	85 c0                	test   %eax,%eax
80102747:	78 1e                	js     80102767 <ideintr+0x76>
    insl(0x1f0, b->data, 512/4);
80102749:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010274c:	83 c0 18             	add    $0x18,%eax
8010274f:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80102756:	00 
80102757:	89 44 24 04          	mov    %eax,0x4(%esp)
8010275b:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
80102762:	e8 13 fd ff ff       	call   8010247a <insl>
  
  // Wake process waiting for this buf.
  b->flags |= B_VALID;
80102767:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010276a:	8b 00                	mov    (%eax),%eax
8010276c:	89 c2                	mov    %eax,%edx
8010276e:	83 ca 02             	or     $0x2,%edx
80102771:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102774:	89 10                	mov    %edx,(%eax)
  b->flags &= ~B_DIRTY;
80102776:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102779:	8b 00                	mov    (%eax),%eax
8010277b:	89 c2                	mov    %eax,%edx
8010277d:	83 e2 fb             	and    $0xfffffffb,%edx
80102780:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102783:	89 10                	mov    %edx,(%eax)
  //wakeup(b);
  
  // Start disk on next buf in queue.
  if(idequeue != 0)
80102785:	a1 34 b6 10 80       	mov    0x8010b634,%eax
8010278a:	85 c0                	test   %eax,%eax
8010278c:	74 0d                	je     8010279b <ideintr+0xaa>
    idestart(idequeue);
8010278e:	a1 34 b6 10 80       	mov    0x8010b634,%eax
80102793:	89 04 24             	mov    %eax,(%esp)
80102796:	e8 31 fe ff ff       	call   801025cc <idestart>

  release(&idelock);
8010279b:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
801027a2:	e8 ab 29 00 00       	call   80105152 <release>
}
801027a7:	c9                   	leave  
801027a8:	c3                   	ret    

801027a9 <iderw>:
// Sync buf with disk. 
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
801027a9:	55                   	push   %ebp
801027aa:	89 e5                	mov    %esp,%ebp
801027ac:	83 ec 28             	sub    $0x28,%esp
  struct buf **pp;

  if(!(b->flags & B_BUSY))
801027af:	8b 45 08             	mov    0x8(%ebp),%eax
801027b2:	8b 00                	mov    (%eax),%eax
801027b4:	83 e0 01             	and    $0x1,%eax
801027b7:	85 c0                	test   %eax,%eax
801027b9:	75 0c                	jne    801027c7 <iderw+0x1e>
    panic("iderw: buf not busy");
801027bb:	c7 04 24 a9 89 10 80 	movl   $0x801089a9,(%esp)
801027c2:	e8 76 dd ff ff       	call   8010053d <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
801027c7:	8b 45 08             	mov    0x8(%ebp),%eax
801027ca:	8b 00                	mov    (%eax),%eax
801027cc:	83 e0 06             	and    $0x6,%eax
801027cf:	83 f8 02             	cmp    $0x2,%eax
801027d2:	75 0c                	jne    801027e0 <iderw+0x37>
    panic("iderw: nothing to do");
801027d4:	c7 04 24 bd 89 10 80 	movl   $0x801089bd,(%esp)
801027db:	e8 5d dd ff ff       	call   8010053d <panic>
  if(b->dev != 0 && !havedisk1)
801027e0:	8b 45 08             	mov    0x8(%ebp),%eax
801027e3:	8b 40 04             	mov    0x4(%eax),%eax
801027e6:	85 c0                	test   %eax,%eax
801027e8:	74 15                	je     801027ff <iderw+0x56>
801027ea:	a1 38 b6 10 80       	mov    0x8010b638,%eax
801027ef:	85 c0                	test   %eax,%eax
801027f1:	75 0c                	jne    801027ff <iderw+0x56>
    panic("iderw: ide disk 1 not present");
801027f3:	c7 04 24 d2 89 10 80 	movl   $0x801089d2,(%esp)
801027fa:	e8 3e dd ff ff       	call   8010053d <panic>

  acquire(&idelock);  //DOC: acquire-lock
801027ff:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102806:	e8 ac 28 00 00       	call   801050b7 <acquire>

  // Append b to idequeue.
  b->qnext = 0;
8010280b:	8b 45 08             	mov    0x8(%ebp),%eax
8010280e:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC: insert-queue
80102815:	c7 45 f4 34 b6 10 80 	movl   $0x8010b634,-0xc(%ebp)
8010281c:	eb 0b                	jmp    80102829 <iderw+0x80>
8010281e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102821:	8b 00                	mov    (%eax),%eax
80102823:	83 c0 14             	add    $0x14,%eax
80102826:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102829:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010282c:	8b 00                	mov    (%eax),%eax
8010282e:	85 c0                	test   %eax,%eax
80102830:	75 ec                	jne    8010281e <iderw+0x75>
    ;
  *pp = b;
80102832:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102835:	8b 55 08             	mov    0x8(%ebp),%edx
80102838:	89 10                	mov    %edx,(%eax)
  
  // Start disk if necessary.
  if(idequeue == b)
8010283a:	a1 34 b6 10 80       	mov    0x8010b634,%eax
8010283f:	3b 45 08             	cmp    0x8(%ebp),%eax
80102842:	75 2b                	jne    8010286f <iderw+0xc6>
    idestart(b);
80102844:	8b 45 08             	mov    0x8(%ebp),%eax
80102847:	89 04 24             	mov    %eax,(%esp)
8010284a:	e8 7d fd ff ff       	call   801025cc <idestart>
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
8010284f:	eb 1e                	jmp    8010286f <iderw+0xc6>
    if(holding(&idelock))
80102851:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102858:	e8 b1 29 00 00       	call   8010520e <holding>
8010285d:	85 c0                	test   %eax,%eax
8010285f:	74 0f                	je     80102870 <iderw+0xc7>
      release(&idelock);
80102861:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102868:	e8 e5 28 00 00       	call   80105152 <release>
8010286d:	eb 01                	jmp    80102870 <iderw+0xc7>
  // Start disk if necessary.
  if(idequeue == b)
    idestart(b);
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
8010286f:	90                   	nop
80102870:	8b 45 08             	mov    0x8(%ebp),%eax
80102873:	8b 00                	mov    (%eax),%eax
80102875:	83 e0 06             	and    $0x6,%eax
80102878:	83 f8 02             	cmp    $0x2,%eax
8010287b:	75 d4                	jne    80102851 <iderw+0xa8>
    if(holding(&idelock))
      release(&idelock);
    //sleep(b, &idelock);
  }

  if(holding(&idelock))
8010287d:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102884:	e8 85 29 00 00       	call   8010520e <holding>
80102889:	85 c0                	test   %eax,%eax
8010288b:	74 0c                	je     80102899 <iderw+0xf0>
    release(&idelock);
8010288d:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102894:	e8 b9 28 00 00       	call   80105152 <release>
}
80102899:	c9                   	leave  
8010289a:	c3                   	ret    
	...

8010289c <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
8010289c:	55                   	push   %ebp
8010289d:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
8010289f:	a1 34 f8 10 80       	mov    0x8010f834,%eax
801028a4:	8b 55 08             	mov    0x8(%ebp),%edx
801028a7:	89 10                	mov    %edx,(%eax)
  return ioapic->data;
801028a9:	a1 34 f8 10 80       	mov    0x8010f834,%eax
801028ae:	8b 40 10             	mov    0x10(%eax),%eax
}
801028b1:	5d                   	pop    %ebp
801028b2:	c3                   	ret    

801028b3 <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
801028b3:	55                   	push   %ebp
801028b4:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
801028b6:	a1 34 f8 10 80       	mov    0x8010f834,%eax
801028bb:	8b 55 08             	mov    0x8(%ebp),%edx
801028be:	89 10                	mov    %edx,(%eax)
  ioapic->data = data;
801028c0:	a1 34 f8 10 80       	mov    0x8010f834,%eax
801028c5:	8b 55 0c             	mov    0xc(%ebp),%edx
801028c8:	89 50 10             	mov    %edx,0x10(%eax)
}
801028cb:	5d                   	pop    %ebp
801028cc:	c3                   	ret    

801028cd <ioapicinit>:

void
ioapicinit(void)
{
801028cd:	55                   	push   %ebp
801028ce:	89 e5                	mov    %esp,%ebp
801028d0:	83 ec 28             	sub    $0x28,%esp
  int i, id, maxintr;

  if(!ismp)
801028d3:	a1 04 f9 10 80       	mov    0x8010f904,%eax
801028d8:	85 c0                	test   %eax,%eax
801028da:	0f 84 9f 00 00 00    	je     8010297f <ioapicinit+0xb2>
    return;

  ioapic = (volatile struct ioapic*)IOAPIC;
801028e0:	c7 05 34 f8 10 80 00 	movl   $0xfec00000,0x8010f834
801028e7:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
801028ea:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801028f1:	e8 a6 ff ff ff       	call   8010289c <ioapicread>
801028f6:	c1 e8 10             	shr    $0x10,%eax
801028f9:	25 ff 00 00 00       	and    $0xff,%eax
801028fe:	89 45 f0             	mov    %eax,-0x10(%ebp)
  id = ioapicread(REG_ID) >> 24;
80102901:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102908:	e8 8f ff ff ff       	call   8010289c <ioapicread>
8010290d:	c1 e8 18             	shr    $0x18,%eax
80102910:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(id != ioapicid)
80102913:	0f b6 05 00 f9 10 80 	movzbl 0x8010f900,%eax
8010291a:	0f b6 c0             	movzbl %al,%eax
8010291d:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80102920:	74 0c                	je     8010292e <ioapicinit+0x61>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80102922:	c7 04 24 f0 89 10 80 	movl   $0x801089f0,(%esp)
80102929:	e8 73 da ff ff       	call   801003a1 <cprintf>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
8010292e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102935:	eb 3e                	jmp    80102975 <ioapicinit+0xa8>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
80102937:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010293a:	83 c0 20             	add    $0x20,%eax
8010293d:	0d 00 00 01 00       	or     $0x10000,%eax
80102942:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102945:	83 c2 08             	add    $0x8,%edx
80102948:	01 d2                	add    %edx,%edx
8010294a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010294e:	89 14 24             	mov    %edx,(%esp)
80102951:	e8 5d ff ff ff       	call   801028b3 <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
80102956:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102959:	83 c0 08             	add    $0x8,%eax
8010295c:	01 c0                	add    %eax,%eax
8010295e:	83 c0 01             	add    $0x1,%eax
80102961:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102968:	00 
80102969:	89 04 24             	mov    %eax,(%esp)
8010296c:	e8 42 ff ff ff       	call   801028b3 <ioapicwrite>
  if(id != ioapicid)
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80102971:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102975:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102978:	3b 45 f0             	cmp    -0x10(%ebp),%eax
8010297b:	7e ba                	jle    80102937 <ioapicinit+0x6a>
8010297d:	eb 01                	jmp    80102980 <ioapicinit+0xb3>
ioapicinit(void)
{
  int i, id, maxintr;

  if(!ismp)
    return;
8010297f:	90                   	nop
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
    ioapicwrite(REG_TABLE+2*i+1, 0);
  }
}
80102980:	c9                   	leave  
80102981:	c3                   	ret    

80102982 <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
80102982:	55                   	push   %ebp
80102983:	89 e5                	mov    %esp,%ebp
80102985:	83 ec 08             	sub    $0x8,%esp
  if(!ismp)
80102988:	a1 04 f9 10 80       	mov    0x8010f904,%eax
8010298d:	85 c0                	test   %eax,%eax
8010298f:	74 39                	je     801029ca <ioapicenable+0x48>
    return;

  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
80102991:	8b 45 08             	mov    0x8(%ebp),%eax
80102994:	83 c0 20             	add    $0x20,%eax
80102997:	8b 55 08             	mov    0x8(%ebp),%edx
8010299a:	83 c2 08             	add    $0x8,%edx
8010299d:	01 d2                	add    %edx,%edx
8010299f:	89 44 24 04          	mov    %eax,0x4(%esp)
801029a3:	89 14 24             	mov    %edx,(%esp)
801029a6:	e8 08 ff ff ff       	call   801028b3 <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
801029ab:	8b 45 0c             	mov    0xc(%ebp),%eax
801029ae:	c1 e0 18             	shl    $0x18,%eax
801029b1:	8b 55 08             	mov    0x8(%ebp),%edx
801029b4:	83 c2 08             	add    $0x8,%edx
801029b7:	01 d2                	add    %edx,%edx
801029b9:	83 c2 01             	add    $0x1,%edx
801029bc:	89 44 24 04          	mov    %eax,0x4(%esp)
801029c0:	89 14 24             	mov    %edx,(%esp)
801029c3:	e8 eb fe ff ff       	call   801028b3 <ioapicwrite>
801029c8:	eb 01                	jmp    801029cb <ioapicenable+0x49>

void
ioapicenable(int irq, int cpunum)
{
  if(!ismp)
    return;
801029ca:	90                   	nop
  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
}
801029cb:	c9                   	leave  
801029cc:	c3                   	ret    
801029cd:	00 00                	add    %al,(%eax)
	...

801029d0 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
801029d0:	55                   	push   %ebp
801029d1:	89 e5                	mov    %esp,%ebp
801029d3:	8b 45 08             	mov    0x8(%ebp),%eax
801029d6:	05 00 00 00 80       	add    $0x80000000,%eax
801029db:	5d                   	pop    %ebp
801029dc:	c3                   	ret    

801029dd <kinit1>:
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
801029dd:	55                   	push   %ebp
801029de:	89 e5                	mov    %esp,%ebp
801029e0:	83 ec 18             	sub    $0x18,%esp
  initlock(&kmem.lock, "kmem");
801029e3:	c7 44 24 04 22 8a 10 	movl   $0x80108a22,0x4(%esp)
801029ea:	80 
801029eb:	c7 04 24 40 f8 10 80 	movl   $0x8010f840,(%esp)
801029f2:	e8 9f 26 00 00       	call   80105096 <initlock>
  kmem.use_lock = 0;
801029f7:	c7 05 74 f8 10 80 00 	movl   $0x0,0x8010f874
801029fe:	00 00 00 
  freerange(vstart, vend);
80102a01:	8b 45 0c             	mov    0xc(%ebp),%eax
80102a04:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a08:	8b 45 08             	mov    0x8(%ebp),%eax
80102a0b:	89 04 24             	mov    %eax,(%esp)
80102a0e:	e8 26 00 00 00       	call   80102a39 <freerange>
}
80102a13:	c9                   	leave  
80102a14:	c3                   	ret    

80102a15 <kinit2>:

void
kinit2(void *vstart, void *vend)
{
80102a15:	55                   	push   %ebp
80102a16:	89 e5                	mov    %esp,%ebp
80102a18:	83 ec 18             	sub    $0x18,%esp
  freerange(vstart, vend);
80102a1b:	8b 45 0c             	mov    0xc(%ebp),%eax
80102a1e:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a22:	8b 45 08             	mov    0x8(%ebp),%eax
80102a25:	89 04 24             	mov    %eax,(%esp)
80102a28:	e8 0c 00 00 00       	call   80102a39 <freerange>
  kmem.use_lock = 1;
80102a2d:	c7 05 74 f8 10 80 01 	movl   $0x1,0x8010f874
80102a34:	00 00 00 
}
80102a37:	c9                   	leave  
80102a38:	c3                   	ret    

80102a39 <freerange>:

void
freerange(void *vstart, void *vend)
{
80102a39:	55                   	push   %ebp
80102a3a:	89 e5                	mov    %esp,%ebp
80102a3c:	83 ec 28             	sub    $0x28,%esp
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
80102a3f:	8b 45 08             	mov    0x8(%ebp),%eax
80102a42:	05 ff 0f 00 00       	add    $0xfff,%eax
80102a47:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80102a4c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102a4f:	eb 12                	jmp    80102a63 <freerange+0x2a>
    kfree(p);
80102a51:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a54:	89 04 24             	mov    %eax,(%esp)
80102a57:	e8 16 00 00 00       	call   80102a72 <kfree>
void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102a5c:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80102a63:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a66:	05 00 10 00 00       	add    $0x1000,%eax
80102a6b:	3b 45 0c             	cmp    0xc(%ebp),%eax
80102a6e:	76 e1                	jbe    80102a51 <freerange+0x18>
    kfree(p);
}
80102a70:	c9                   	leave  
80102a71:	c3                   	ret    

80102a72 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
80102a72:	55                   	push   %ebp
80102a73:	89 e5                	mov    %esp,%ebp
80102a75:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if((uint)v % PGSIZE || v < end || v2p(v) >= PHYSTOP)
80102a78:	8b 45 08             	mov    0x8(%ebp),%eax
80102a7b:	25 ff 0f 00 00       	and    $0xfff,%eax
80102a80:	85 c0                	test   %eax,%eax
80102a82:	75 1b                	jne    80102a9f <kfree+0x2d>
80102a84:	81 7d 08 fc 2a 11 80 	cmpl   $0x80112afc,0x8(%ebp)
80102a8b:	72 12                	jb     80102a9f <kfree+0x2d>
80102a8d:	8b 45 08             	mov    0x8(%ebp),%eax
80102a90:	89 04 24             	mov    %eax,(%esp)
80102a93:	e8 38 ff ff ff       	call   801029d0 <v2p>
80102a98:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80102a9d:	76 0c                	jbe    80102aab <kfree+0x39>
    panic("kfree");
80102a9f:	c7 04 24 27 8a 10 80 	movl   $0x80108a27,(%esp)
80102aa6:	e8 92 da ff ff       	call   8010053d <panic>

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80102aab:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80102ab2:	00 
80102ab3:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102aba:	00 
80102abb:	8b 45 08             	mov    0x8(%ebp),%eax
80102abe:	89 04 24             	mov    %eax,(%esp)
80102ac1:	e8 78 28 00 00       	call   8010533e <memset>

  if(kmem.use_lock)
80102ac6:	a1 74 f8 10 80       	mov    0x8010f874,%eax
80102acb:	85 c0                	test   %eax,%eax
80102acd:	74 0c                	je     80102adb <kfree+0x69>
    acquire(&kmem.lock);
80102acf:	c7 04 24 40 f8 10 80 	movl   $0x8010f840,(%esp)
80102ad6:	e8 dc 25 00 00       	call   801050b7 <acquire>
  r = (struct run*)v;
80102adb:	8b 45 08             	mov    0x8(%ebp),%eax
80102ade:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
80102ae1:	8b 15 78 f8 10 80    	mov    0x8010f878,%edx
80102ae7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102aea:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
80102aec:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102aef:	a3 78 f8 10 80       	mov    %eax,0x8010f878
  if(kmem.use_lock)
80102af4:	a1 74 f8 10 80       	mov    0x8010f874,%eax
80102af9:	85 c0                	test   %eax,%eax
80102afb:	74 0c                	je     80102b09 <kfree+0x97>
    release(&kmem.lock);
80102afd:	c7 04 24 40 f8 10 80 	movl   $0x8010f840,(%esp)
80102b04:	e8 49 26 00 00       	call   80105152 <release>
}
80102b09:	c9                   	leave  
80102b0a:	c3                   	ret    

80102b0b <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
80102b0b:	55                   	push   %ebp
80102b0c:	89 e5                	mov    %esp,%ebp
80102b0e:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if(kmem.use_lock)
80102b11:	a1 74 f8 10 80       	mov    0x8010f874,%eax
80102b16:	85 c0                	test   %eax,%eax
80102b18:	74 0c                	je     80102b26 <kalloc+0x1b>
    acquire(&kmem.lock);
80102b1a:	c7 04 24 40 f8 10 80 	movl   $0x8010f840,(%esp)
80102b21:	e8 91 25 00 00       	call   801050b7 <acquire>
  r = kmem.freelist;
80102b26:	a1 78 f8 10 80       	mov    0x8010f878,%eax
80102b2b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
80102b2e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102b32:	74 0a                	je     80102b3e <kalloc+0x33>
    kmem.freelist = r->next;
80102b34:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b37:	8b 00                	mov    (%eax),%eax
80102b39:	a3 78 f8 10 80       	mov    %eax,0x8010f878
  if(kmem.use_lock)
80102b3e:	a1 74 f8 10 80       	mov    0x8010f874,%eax
80102b43:	85 c0                	test   %eax,%eax
80102b45:	74 0c                	je     80102b53 <kalloc+0x48>
    release(&kmem.lock);
80102b47:	c7 04 24 40 f8 10 80 	movl   $0x8010f840,(%esp)
80102b4e:	e8 ff 25 00 00       	call   80105152 <release>
  return (char*)r;
80102b53:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102b56:	c9                   	leave  
80102b57:	c3                   	ret    

80102b58 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102b58:	55                   	push   %ebp
80102b59:	89 e5                	mov    %esp,%ebp
80102b5b:	53                   	push   %ebx
80102b5c:	83 ec 14             	sub    $0x14,%esp
80102b5f:	8b 45 08             	mov    0x8(%ebp),%eax
80102b62:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102b66:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80102b6a:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80102b6e:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80102b72:	ec                   	in     (%dx),%al
80102b73:	89 c3                	mov    %eax,%ebx
80102b75:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80102b78:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80102b7c:	83 c4 14             	add    $0x14,%esp
80102b7f:	5b                   	pop    %ebx
80102b80:	5d                   	pop    %ebp
80102b81:	c3                   	ret    

80102b82 <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
80102b82:	55                   	push   %ebp
80102b83:	89 e5                	mov    %esp,%ebp
80102b85:	83 ec 14             	sub    $0x14,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
80102b88:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80102b8f:	e8 c4 ff ff ff       	call   80102b58 <inb>
80102b94:	0f b6 c0             	movzbl %al,%eax
80102b97:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
80102b9a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b9d:	83 e0 01             	and    $0x1,%eax
80102ba0:	85 c0                	test   %eax,%eax
80102ba2:	75 0a                	jne    80102bae <kbdgetc+0x2c>
    return -1;
80102ba4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102ba9:	e9 23 01 00 00       	jmp    80102cd1 <kbdgetc+0x14f>
  data = inb(KBDATAP);
80102bae:	c7 04 24 60 00 00 00 	movl   $0x60,(%esp)
80102bb5:	e8 9e ff ff ff       	call   80102b58 <inb>
80102bba:	0f b6 c0             	movzbl %al,%eax
80102bbd:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
80102bc0:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
80102bc7:	75 17                	jne    80102be0 <kbdgetc+0x5e>
    shift |= E0ESC;
80102bc9:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102bce:	83 c8 40             	or     $0x40,%eax
80102bd1:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
    return 0;
80102bd6:	b8 00 00 00 00       	mov    $0x0,%eax
80102bdb:	e9 f1 00 00 00       	jmp    80102cd1 <kbdgetc+0x14f>
  } else if(data & 0x80){
80102be0:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102be3:	25 80 00 00 00       	and    $0x80,%eax
80102be8:	85 c0                	test   %eax,%eax
80102bea:	74 45                	je     80102c31 <kbdgetc+0xaf>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
80102bec:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102bf1:	83 e0 40             	and    $0x40,%eax
80102bf4:	85 c0                	test   %eax,%eax
80102bf6:	75 08                	jne    80102c00 <kbdgetc+0x7e>
80102bf8:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102bfb:	83 e0 7f             	and    $0x7f,%eax
80102bfe:	eb 03                	jmp    80102c03 <kbdgetc+0x81>
80102c00:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102c03:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
80102c06:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102c09:	05 20 90 10 80       	add    $0x80109020,%eax
80102c0e:	0f b6 00             	movzbl (%eax),%eax
80102c11:	83 c8 40             	or     $0x40,%eax
80102c14:	0f b6 c0             	movzbl %al,%eax
80102c17:	f7 d0                	not    %eax
80102c19:	89 c2                	mov    %eax,%edx
80102c1b:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c20:	21 d0                	and    %edx,%eax
80102c22:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
    return 0;
80102c27:	b8 00 00 00 00       	mov    $0x0,%eax
80102c2c:	e9 a0 00 00 00       	jmp    80102cd1 <kbdgetc+0x14f>
  } else if(shift & E0ESC){
80102c31:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c36:	83 e0 40             	and    $0x40,%eax
80102c39:	85 c0                	test   %eax,%eax
80102c3b:	74 14                	je     80102c51 <kbdgetc+0xcf>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80102c3d:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
80102c44:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c49:	83 e0 bf             	and    $0xffffffbf,%eax
80102c4c:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
  }

  shift |= shiftcode[data];
80102c51:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102c54:	05 20 90 10 80       	add    $0x80109020,%eax
80102c59:	0f b6 00             	movzbl (%eax),%eax
80102c5c:	0f b6 d0             	movzbl %al,%edx
80102c5f:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c64:	09 d0                	or     %edx,%eax
80102c66:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
  shift ^= togglecode[data];
80102c6b:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102c6e:	05 20 91 10 80       	add    $0x80109120,%eax
80102c73:	0f b6 00             	movzbl (%eax),%eax
80102c76:	0f b6 d0             	movzbl %al,%edx
80102c79:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c7e:	31 d0                	xor    %edx,%eax
80102c80:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
  c = charcode[shift & (CTL | SHIFT)][data];
80102c85:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c8a:	83 e0 03             	and    $0x3,%eax
80102c8d:	8b 04 85 20 95 10 80 	mov    -0x7fef6ae0(,%eax,4),%eax
80102c94:	03 45 fc             	add    -0x4(%ebp),%eax
80102c97:	0f b6 00             	movzbl (%eax),%eax
80102c9a:	0f b6 c0             	movzbl %al,%eax
80102c9d:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
80102ca0:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102ca5:	83 e0 08             	and    $0x8,%eax
80102ca8:	85 c0                	test   %eax,%eax
80102caa:	74 22                	je     80102cce <kbdgetc+0x14c>
    if('a' <= c && c <= 'z')
80102cac:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
80102cb0:	76 0c                	jbe    80102cbe <kbdgetc+0x13c>
80102cb2:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
80102cb6:	77 06                	ja     80102cbe <kbdgetc+0x13c>
      c += 'A' - 'a';
80102cb8:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
80102cbc:	eb 10                	jmp    80102cce <kbdgetc+0x14c>
    else if('A' <= c && c <= 'Z')
80102cbe:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
80102cc2:	76 0a                	jbe    80102cce <kbdgetc+0x14c>
80102cc4:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
80102cc8:	77 04                	ja     80102cce <kbdgetc+0x14c>
      c += 'a' - 'A';
80102cca:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
80102cce:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80102cd1:	c9                   	leave  
80102cd2:	c3                   	ret    

80102cd3 <kbdintr>:

void
kbdintr(void)
{
80102cd3:	55                   	push   %ebp
80102cd4:	89 e5                	mov    %esp,%ebp
80102cd6:	83 ec 18             	sub    $0x18,%esp
  consoleintr(kbdgetc);
80102cd9:	c7 04 24 82 2b 10 80 	movl   $0x80102b82,(%esp)
80102ce0:	e8 c8 da ff ff       	call   801007ad <consoleintr>
}
80102ce5:	c9                   	leave  
80102ce6:	c3                   	ret    
	...

80102ce8 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80102ce8:	55                   	push   %ebp
80102ce9:	89 e5                	mov    %esp,%ebp
80102ceb:	83 ec 08             	sub    $0x8,%esp
80102cee:	8b 55 08             	mov    0x8(%ebp),%edx
80102cf1:	8b 45 0c             	mov    0xc(%ebp),%eax
80102cf4:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80102cf8:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102cfb:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80102cff:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80102d03:	ee                   	out    %al,(%dx)
}
80102d04:	c9                   	leave  
80102d05:	c3                   	ret    

80102d06 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80102d06:	55                   	push   %ebp
80102d07:	89 e5                	mov    %esp,%ebp
80102d09:	53                   	push   %ebx
80102d0a:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80102d0d:	9c                   	pushf  
80102d0e:	5b                   	pop    %ebx
80102d0f:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80102d12:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80102d15:	83 c4 10             	add    $0x10,%esp
80102d18:	5b                   	pop    %ebx
80102d19:	5d                   	pop    %ebp
80102d1a:	c3                   	ret    

80102d1b <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
80102d1b:	55                   	push   %ebp
80102d1c:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
80102d1e:	a1 7c f8 10 80       	mov    0x8010f87c,%eax
80102d23:	8b 55 08             	mov    0x8(%ebp),%edx
80102d26:	c1 e2 02             	shl    $0x2,%edx
80102d29:	01 c2                	add    %eax,%edx
80102d2b:	8b 45 0c             	mov    0xc(%ebp),%eax
80102d2e:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
80102d30:	a1 7c f8 10 80       	mov    0x8010f87c,%eax
80102d35:	83 c0 20             	add    $0x20,%eax
80102d38:	8b 00                	mov    (%eax),%eax
}
80102d3a:	5d                   	pop    %ebp
80102d3b:	c3                   	ret    

80102d3c <lapicinit>:
//PAGEBREAK!

void
lapicinit(int c)
{
80102d3c:	55                   	push   %ebp
80102d3d:	89 e5                	mov    %esp,%ebp
80102d3f:	83 ec 08             	sub    $0x8,%esp
  if(!lapic) 
80102d42:	a1 7c f8 10 80       	mov    0x8010f87c,%eax
80102d47:	85 c0                	test   %eax,%eax
80102d49:	0f 84 47 01 00 00    	je     80102e96 <lapicinit+0x15a>
    return;

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
80102d4f:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
80102d56:	00 
80102d57:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
80102d5e:	e8 b8 ff ff ff       	call   80102d1b <lapicw>

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.  
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
80102d63:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
80102d6a:	00 
80102d6b:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
80102d72:	e8 a4 ff ff ff       	call   80102d1b <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
80102d77:	c7 44 24 04 20 00 02 	movl   $0x20020,0x4(%esp)
80102d7e:	00 
80102d7f:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80102d86:	e8 90 ff ff ff       	call   80102d1b <lapicw>
  lapicw(TICR, 10000000); 
80102d8b:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
80102d92:	00 
80102d93:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
80102d9a:	e8 7c ff ff ff       	call   80102d1b <lapicw>

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
80102d9f:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102da6:	00 
80102da7:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
80102dae:	e8 68 ff ff ff       	call   80102d1b <lapicw>
  lapicw(LINT1, MASKED);
80102db3:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102dba:	00 
80102dbb:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
80102dc2:	e8 54 ff ff ff       	call   80102d1b <lapicw>

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
80102dc7:	a1 7c f8 10 80       	mov    0x8010f87c,%eax
80102dcc:	83 c0 30             	add    $0x30,%eax
80102dcf:	8b 00                	mov    (%eax),%eax
80102dd1:	c1 e8 10             	shr    $0x10,%eax
80102dd4:	25 ff 00 00 00       	and    $0xff,%eax
80102dd9:	83 f8 03             	cmp    $0x3,%eax
80102ddc:	76 14                	jbe    80102df2 <lapicinit+0xb6>
    lapicw(PCINT, MASKED);
80102dde:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102de5:	00 
80102de6:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
80102ded:	e8 29 ff ff ff       	call   80102d1b <lapicw>

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
80102df2:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
80102df9:	00 
80102dfa:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
80102e01:	e8 15 ff ff ff       	call   80102d1b <lapicw>

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
80102e06:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102e0d:	00 
80102e0e:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80102e15:	e8 01 ff ff ff       	call   80102d1b <lapicw>
  lapicw(ESR, 0);
80102e1a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102e21:	00 
80102e22:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80102e29:	e8 ed fe ff ff       	call   80102d1b <lapicw>

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
80102e2e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102e35:	00 
80102e36:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80102e3d:	e8 d9 fe ff ff       	call   80102d1b <lapicw>

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
80102e42:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102e49:	00 
80102e4a:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80102e51:	e8 c5 fe ff ff       	call   80102d1b <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
80102e56:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
80102e5d:	00 
80102e5e:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80102e65:	e8 b1 fe ff ff       	call   80102d1b <lapicw>
  while(lapic[ICRLO] & DELIVS)
80102e6a:	90                   	nop
80102e6b:	a1 7c f8 10 80       	mov    0x8010f87c,%eax
80102e70:	05 00 03 00 00       	add    $0x300,%eax
80102e75:	8b 00                	mov    (%eax),%eax
80102e77:	25 00 10 00 00       	and    $0x1000,%eax
80102e7c:	85 c0                	test   %eax,%eax
80102e7e:	75 eb                	jne    80102e6b <lapicinit+0x12f>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
80102e80:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102e87:	00 
80102e88:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80102e8f:	e8 87 fe ff ff       	call   80102d1b <lapicw>
80102e94:	eb 01                	jmp    80102e97 <lapicinit+0x15b>

void
lapicinit(int c)
{
  if(!lapic) 
    return;
80102e96:	90                   	nop
  while(lapic[ICRLO] & DELIVS)
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
}
80102e97:	c9                   	leave  
80102e98:	c3                   	ret    

80102e99 <cpunum>:

int
cpunum(void)
{
80102e99:	55                   	push   %ebp
80102e9a:	89 e5                	mov    %esp,%ebp
80102e9c:	83 ec 18             	sub    $0x18,%esp
  // Cannot call cpu when interrupts are enabled:
  // result not guaranteed to last long enough to be used!
  // Would prefer to panic but even printing is chancy here:
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
80102e9f:	e8 62 fe ff ff       	call   80102d06 <readeflags>
80102ea4:	25 00 02 00 00       	and    $0x200,%eax
80102ea9:	85 c0                	test   %eax,%eax
80102eab:	74 29                	je     80102ed6 <cpunum+0x3d>
    static int n;
    if(n++ == 0)
80102ead:	a1 40 b6 10 80       	mov    0x8010b640,%eax
80102eb2:	85 c0                	test   %eax,%eax
80102eb4:	0f 94 c2             	sete   %dl
80102eb7:	83 c0 01             	add    $0x1,%eax
80102eba:	a3 40 b6 10 80       	mov    %eax,0x8010b640
80102ebf:	84 d2                	test   %dl,%dl
80102ec1:	74 13                	je     80102ed6 <cpunum+0x3d>
      cprintf("cpu called from %x with interrupts enabled\n",
80102ec3:	8b 45 04             	mov    0x4(%ebp),%eax
80102ec6:	89 44 24 04          	mov    %eax,0x4(%esp)
80102eca:	c7 04 24 30 8a 10 80 	movl   $0x80108a30,(%esp)
80102ed1:	e8 cb d4 ff ff       	call   801003a1 <cprintf>
        __builtin_return_address(0));
  }

  if(lapic)
80102ed6:	a1 7c f8 10 80       	mov    0x8010f87c,%eax
80102edb:	85 c0                	test   %eax,%eax
80102edd:	74 0f                	je     80102eee <cpunum+0x55>
    return lapic[ID]>>24;
80102edf:	a1 7c f8 10 80       	mov    0x8010f87c,%eax
80102ee4:	83 c0 20             	add    $0x20,%eax
80102ee7:	8b 00                	mov    (%eax),%eax
80102ee9:	c1 e8 18             	shr    $0x18,%eax
80102eec:	eb 05                	jmp    80102ef3 <cpunum+0x5a>
  return 0;
80102eee:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102ef3:	c9                   	leave  
80102ef4:	c3                   	ret    

80102ef5 <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
80102ef5:	55                   	push   %ebp
80102ef6:	89 e5                	mov    %esp,%ebp
80102ef8:	83 ec 08             	sub    $0x8,%esp
  if(lapic)
80102efb:	a1 7c f8 10 80       	mov    0x8010f87c,%eax
80102f00:	85 c0                	test   %eax,%eax
80102f02:	74 14                	je     80102f18 <lapiceoi+0x23>
    lapicw(EOI, 0);
80102f04:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102f0b:	00 
80102f0c:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80102f13:	e8 03 fe ff ff       	call   80102d1b <lapicw>
}
80102f18:	c9                   	leave  
80102f19:	c3                   	ret    

80102f1a <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
80102f1a:	55                   	push   %ebp
80102f1b:	89 e5                	mov    %esp,%ebp
}
80102f1d:	5d                   	pop    %ebp
80102f1e:	c3                   	ret    

80102f1f <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
80102f1f:	55                   	push   %ebp
80102f20:	89 e5                	mov    %esp,%ebp
80102f22:	83 ec 1c             	sub    $0x1c,%esp
80102f25:	8b 45 08             	mov    0x8(%ebp),%eax
80102f28:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;
  
  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
80102f2b:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80102f32:	00 
80102f33:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
80102f3a:	e8 a9 fd ff ff       	call   80102ce8 <outb>
  outb(IO_RTC+1, 0x0A);
80102f3f:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80102f46:	00 
80102f47:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
80102f4e:	e8 95 fd ff ff       	call   80102ce8 <outb>
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
80102f53:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
80102f5a:	8b 45 f8             	mov    -0x8(%ebp),%eax
80102f5d:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
80102f62:	8b 45 f8             	mov    -0x8(%ebp),%eax
80102f65:	8d 50 02             	lea    0x2(%eax),%edx
80102f68:	8b 45 0c             	mov    0xc(%ebp),%eax
80102f6b:	c1 e8 04             	shr    $0x4,%eax
80102f6e:	66 89 02             	mov    %ax,(%edx)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
80102f71:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80102f75:	c1 e0 18             	shl    $0x18,%eax
80102f78:	89 44 24 04          	mov    %eax,0x4(%esp)
80102f7c:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80102f83:	e8 93 fd ff ff       	call   80102d1b <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
80102f88:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
80102f8f:	00 
80102f90:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80102f97:	e8 7f fd ff ff       	call   80102d1b <lapicw>
  microdelay(200);
80102f9c:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80102fa3:	e8 72 ff ff ff       	call   80102f1a <microdelay>
  lapicw(ICRLO, INIT | LEVEL);
80102fa8:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
80102faf:	00 
80102fb0:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80102fb7:	e8 5f fd ff ff       	call   80102d1b <lapicw>
  microdelay(100);    // should be 10ms, but too slow in Bochs!
80102fbc:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80102fc3:	e8 52 ff ff ff       	call   80102f1a <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80102fc8:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80102fcf:	eb 40                	jmp    80103011 <lapicstartap+0xf2>
    lapicw(ICRHI, apicid<<24);
80102fd1:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80102fd5:	c1 e0 18             	shl    $0x18,%eax
80102fd8:	89 44 24 04          	mov    %eax,0x4(%esp)
80102fdc:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80102fe3:	e8 33 fd ff ff       	call   80102d1b <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
80102fe8:	8b 45 0c             	mov    0xc(%ebp),%eax
80102feb:	c1 e8 0c             	shr    $0xc,%eax
80102fee:	80 cc 06             	or     $0x6,%ah
80102ff1:	89 44 24 04          	mov    %eax,0x4(%esp)
80102ff5:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80102ffc:	e8 1a fd ff ff       	call   80102d1b <lapicw>
    microdelay(200);
80103001:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103008:	e8 0d ff ff ff       	call   80102f1a <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
8010300d:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103011:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
80103015:	7e ba                	jle    80102fd1 <lapicstartap+0xb2>
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
80103017:	c9                   	leave  
80103018:	c3                   	ret    
80103019:	00 00                	add    %al,(%eax)
	...

8010301c <initlog>:

static void recover_from_log(void);

void
initlog(void)
{
8010301c:	55                   	push   %ebp
8010301d:	89 e5                	mov    %esp,%ebp
8010301f:	83 ec 28             	sub    $0x28,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
80103022:	c7 44 24 04 5c 8a 10 	movl   $0x80108a5c,0x4(%esp)
80103029:	80 
8010302a:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
80103031:	e8 60 20 00 00       	call   80105096 <initlock>
  readsb(ROOTDEV, &sb);
80103036:	8d 45 e8             	lea    -0x18(%ebp),%eax
80103039:	89 44 24 04          	mov    %eax,0x4(%esp)
8010303d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103044:	e8 a3 e2 ff ff       	call   801012ec <readsb>
  log.start = sb.size - sb.nlog;
80103049:	8b 55 e8             	mov    -0x18(%ebp),%edx
8010304c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010304f:	89 d1                	mov    %edx,%ecx
80103051:	29 c1                	sub    %eax,%ecx
80103053:	89 c8                	mov    %ecx,%eax
80103055:	a3 b4 f8 10 80       	mov    %eax,0x8010f8b4
  log.size = sb.nlog;
8010305a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010305d:	a3 b8 f8 10 80       	mov    %eax,0x8010f8b8
  log.dev = ROOTDEV;
80103062:	c7 05 c0 f8 10 80 01 	movl   $0x1,0x8010f8c0
80103069:	00 00 00 
  recover_from_log();
8010306c:	e8 97 01 00 00       	call   80103208 <recover_from_log>
}
80103071:	c9                   	leave  
80103072:	c3                   	ret    

80103073 <install_trans>:

// Copy committed blocks from log to their home location
static void 
install_trans(void)
{
80103073:	55                   	push   %ebp
80103074:	89 e5                	mov    %esp,%ebp
80103076:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103079:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103080:	e9 89 00 00 00       	jmp    8010310e <install_trans+0x9b>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
80103085:	a1 b4 f8 10 80       	mov    0x8010f8b4,%eax
8010308a:	03 45 f4             	add    -0xc(%ebp),%eax
8010308d:	83 c0 01             	add    $0x1,%eax
80103090:	89 c2                	mov    %eax,%edx
80103092:	a1 c0 f8 10 80       	mov    0x8010f8c0,%eax
80103097:	89 54 24 04          	mov    %edx,0x4(%esp)
8010309b:	89 04 24             	mov    %eax,(%esp)
8010309e:	e8 03 d1 ff ff       	call   801001a6 <bread>
801030a3:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.sector[tail]); // read dst
801030a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801030a9:	83 c0 10             	add    $0x10,%eax
801030ac:	8b 04 85 88 f8 10 80 	mov    -0x7fef0778(,%eax,4),%eax
801030b3:	89 c2                	mov    %eax,%edx
801030b5:	a1 c0 f8 10 80       	mov    0x8010f8c0,%eax
801030ba:	89 54 24 04          	mov    %edx,0x4(%esp)
801030be:	89 04 24             	mov    %eax,(%esp)
801030c1:	e8 e0 d0 ff ff       	call   801001a6 <bread>
801030c6:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
801030c9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801030cc:	8d 50 18             	lea    0x18(%eax),%edx
801030cf:	8b 45 ec             	mov    -0x14(%ebp),%eax
801030d2:	83 c0 18             	add    $0x18,%eax
801030d5:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
801030dc:	00 
801030dd:	89 54 24 04          	mov    %edx,0x4(%esp)
801030e1:	89 04 24             	mov    %eax,(%esp)
801030e4:	e8 28 23 00 00       	call   80105411 <memmove>
    bwrite(dbuf);  // write dst to disk
801030e9:	8b 45 ec             	mov    -0x14(%ebp),%eax
801030ec:	89 04 24             	mov    %eax,(%esp)
801030ef:	e8 e9 d0 ff ff       	call   801001dd <bwrite>
    brelse(lbuf); 
801030f4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801030f7:	89 04 24             	mov    %eax,(%esp)
801030fa:	e8 18 d1 ff ff       	call   80100217 <brelse>
    brelse(dbuf);
801030ff:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103102:	89 04 24             	mov    %eax,(%esp)
80103105:	e8 0d d1 ff ff       	call   80100217 <brelse>
static void 
install_trans(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
8010310a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010310e:	a1 c4 f8 10 80       	mov    0x8010f8c4,%eax
80103113:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103116:	0f 8f 69 ff ff ff    	jg     80103085 <install_trans+0x12>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    bwrite(dbuf);  // write dst to disk
    brelse(lbuf); 
    brelse(dbuf);
  }
}
8010311c:	c9                   	leave  
8010311d:	c3                   	ret    

8010311e <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
8010311e:	55                   	push   %ebp
8010311f:	89 e5                	mov    %esp,%ebp
80103121:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80103124:	a1 b4 f8 10 80       	mov    0x8010f8b4,%eax
80103129:	89 c2                	mov    %eax,%edx
8010312b:	a1 c0 f8 10 80       	mov    0x8010f8c0,%eax
80103130:	89 54 24 04          	mov    %edx,0x4(%esp)
80103134:	89 04 24             	mov    %eax,(%esp)
80103137:	e8 6a d0 ff ff       	call   801001a6 <bread>
8010313c:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
8010313f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103142:	83 c0 18             	add    $0x18,%eax
80103145:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
80103148:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010314b:	8b 00                	mov    (%eax),%eax
8010314d:	a3 c4 f8 10 80       	mov    %eax,0x8010f8c4
  for (i = 0; i < log.lh.n; i++) {
80103152:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103159:	eb 1b                	jmp    80103176 <read_head+0x58>
    log.lh.sector[i] = lh->sector[i];
8010315b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010315e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103161:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
80103165:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103168:	83 c2 10             	add    $0x10,%edx
8010316b:	89 04 95 88 f8 10 80 	mov    %eax,-0x7fef0778(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
80103172:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103176:	a1 c4 f8 10 80       	mov    0x8010f8c4,%eax
8010317b:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010317e:	7f db                	jg     8010315b <read_head+0x3d>
    log.lh.sector[i] = lh->sector[i];
  }
  brelse(buf);
80103180:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103183:	89 04 24             	mov    %eax,(%esp)
80103186:	e8 8c d0 ff ff       	call   80100217 <brelse>
}
8010318b:	c9                   	leave  
8010318c:	c3                   	ret    

8010318d <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
8010318d:	55                   	push   %ebp
8010318e:	89 e5                	mov    %esp,%ebp
80103190:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80103193:	a1 b4 f8 10 80       	mov    0x8010f8b4,%eax
80103198:	89 c2                	mov    %eax,%edx
8010319a:	a1 c0 f8 10 80       	mov    0x8010f8c0,%eax
8010319f:	89 54 24 04          	mov    %edx,0x4(%esp)
801031a3:	89 04 24             	mov    %eax,(%esp)
801031a6:	e8 fb cf ff ff       	call   801001a6 <bread>
801031ab:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
801031ae:	8b 45 f0             	mov    -0x10(%ebp),%eax
801031b1:	83 c0 18             	add    $0x18,%eax
801031b4:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
801031b7:	8b 15 c4 f8 10 80    	mov    0x8010f8c4,%edx
801031bd:	8b 45 ec             	mov    -0x14(%ebp),%eax
801031c0:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
801031c2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801031c9:	eb 1b                	jmp    801031e6 <write_head+0x59>
    hb->sector[i] = log.lh.sector[i];
801031cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801031ce:	83 c0 10             	add    $0x10,%eax
801031d1:	8b 0c 85 88 f8 10 80 	mov    -0x7fef0778(,%eax,4),%ecx
801031d8:	8b 45 ec             	mov    -0x14(%ebp),%eax
801031db:	8b 55 f4             	mov    -0xc(%ebp),%edx
801031de:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
801031e2:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801031e6:	a1 c4 f8 10 80       	mov    0x8010f8c4,%eax
801031eb:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801031ee:	7f db                	jg     801031cb <write_head+0x3e>
    hb->sector[i] = log.lh.sector[i];
  }
  bwrite(buf);
801031f0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801031f3:	89 04 24             	mov    %eax,(%esp)
801031f6:	e8 e2 cf ff ff       	call   801001dd <bwrite>
  brelse(buf);
801031fb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801031fe:	89 04 24             	mov    %eax,(%esp)
80103201:	e8 11 d0 ff ff       	call   80100217 <brelse>
}
80103206:	c9                   	leave  
80103207:	c3                   	ret    

80103208 <recover_from_log>:

static void
recover_from_log(void)
{
80103208:	55                   	push   %ebp
80103209:	89 e5                	mov    %esp,%ebp
8010320b:	83 ec 08             	sub    $0x8,%esp
  read_head();      
8010320e:	e8 0b ff ff ff       	call   8010311e <read_head>
  install_trans(); // if committed, copy from log to disk
80103213:	e8 5b fe ff ff       	call   80103073 <install_trans>
  log.lh.n = 0;
80103218:	c7 05 c4 f8 10 80 00 	movl   $0x0,0x8010f8c4
8010321f:	00 00 00 
  write_head(); // clear the log
80103222:	e8 66 ff ff ff       	call   8010318d <write_head>
}
80103227:	c9                   	leave  
80103228:	c3                   	ret    

80103229 <begin_trans>:

void
begin_trans(void)
{
80103229:	55                   	push   %ebp
8010322a:	89 e5                	mov    %esp,%ebp
8010322c:	83 ec 18             	sub    $0x18,%esp
  acquire(&log.lock);
8010322f:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
80103236:	e8 7c 1e 00 00       	call   801050b7 <acquire>
  while (log.busy) {
8010323b:	eb 14                	jmp    80103251 <begin_trans+0x28>
  sleep(&log, &log.lock);
8010323d:	c7 44 24 04 80 f8 10 	movl   $0x8010f880,0x4(%esp)
80103244:	80 
80103245:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
8010324c:	e8 f9 1a 00 00       	call   80104d4a <sleep>

void
begin_trans(void)
{
  acquire(&log.lock);
  while (log.busy) {
80103251:	a1 bc f8 10 80       	mov    0x8010f8bc,%eax
80103256:	85 c0                	test   %eax,%eax
80103258:	75 e3                	jne    8010323d <begin_trans+0x14>
  sleep(&log, &log.lock);
  }
  log.busy = 1;
8010325a:	c7 05 bc f8 10 80 01 	movl   $0x1,0x8010f8bc
80103261:	00 00 00 
  release(&log.lock);
80103264:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
8010326b:	e8 e2 1e 00 00       	call   80105152 <release>
}
80103270:	c9                   	leave  
80103271:	c3                   	ret    

80103272 <commit_trans>:

void
commit_trans(void)
{
80103272:	55                   	push   %ebp
80103273:	89 e5                	mov    %esp,%ebp
80103275:	83 ec 18             	sub    $0x18,%esp
  if (log.lh.n > 0) {
80103278:	a1 c4 f8 10 80       	mov    0x8010f8c4,%eax
8010327d:	85 c0                	test   %eax,%eax
8010327f:	7e 19                	jle    8010329a <commit_trans+0x28>
    write_head();    // Write header to disk -- the real commit
80103281:	e8 07 ff ff ff       	call   8010318d <write_head>
    install_trans(); // Now install writes to home locations
80103286:	e8 e8 fd ff ff       	call   80103073 <install_trans>
    log.lh.n = 0; 
8010328b:	c7 05 c4 f8 10 80 00 	movl   $0x0,0x8010f8c4
80103292:	00 00 00 
    write_head();    // Erase the transaction from the log
80103295:	e8 f3 fe ff ff       	call   8010318d <write_head>
  }
  
  acquire(&log.lock);
8010329a:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
801032a1:	e8 11 1e 00 00       	call   801050b7 <acquire>
  log.busy = 0;
801032a6:	c7 05 bc f8 10 80 00 	movl   $0x0,0x8010f8bc
801032ad:	00 00 00 
  wakeup(&log);
801032b0:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
801032b7:	e8 f1 1b 00 00       	call   80104ead <wakeup>
  release(&log.lock);
801032bc:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
801032c3:	e8 8a 1e 00 00       	call   80105152 <release>
}
801032c8:	c9                   	leave  
801032c9:	c3                   	ret    

801032ca <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
801032ca:	55                   	push   %ebp
801032cb:	89 e5                	mov    %esp,%ebp
801032cd:	83 ec 28             	sub    $0x28,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
801032d0:	a1 c4 f8 10 80       	mov    0x8010f8c4,%eax
801032d5:	83 f8 09             	cmp    $0x9,%eax
801032d8:	7f 12                	jg     801032ec <log_write+0x22>
801032da:	a1 c4 f8 10 80       	mov    0x8010f8c4,%eax
801032df:	8b 15 b8 f8 10 80    	mov    0x8010f8b8,%edx
801032e5:	83 ea 01             	sub    $0x1,%edx
801032e8:	39 d0                	cmp    %edx,%eax
801032ea:	7c 0c                	jl     801032f8 <log_write+0x2e>
    panic("too big a transaction");
801032ec:	c7 04 24 60 8a 10 80 	movl   $0x80108a60,(%esp)
801032f3:	e8 45 d2 ff ff       	call   8010053d <panic>
  if (!log.busy)
801032f8:	a1 bc f8 10 80       	mov    0x8010f8bc,%eax
801032fd:	85 c0                	test   %eax,%eax
801032ff:	75 0c                	jne    8010330d <log_write+0x43>
    panic("write outside of trans");
80103301:	c7 04 24 76 8a 10 80 	movl   $0x80108a76,(%esp)
80103308:	e8 30 d2 ff ff       	call   8010053d <panic>

  for (i = 0; i < log.lh.n; i++) {
8010330d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103314:	eb 1d                	jmp    80103333 <log_write+0x69>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
80103316:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103319:	83 c0 10             	add    $0x10,%eax
8010331c:	8b 04 85 88 f8 10 80 	mov    -0x7fef0778(,%eax,4),%eax
80103323:	89 c2                	mov    %eax,%edx
80103325:	8b 45 08             	mov    0x8(%ebp),%eax
80103328:	8b 40 08             	mov    0x8(%eax),%eax
8010332b:	39 c2                	cmp    %eax,%edx
8010332d:	74 10                	je     8010333f <log_write+0x75>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    panic("too big a transaction");
  if (!log.busy)
    panic("write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
8010332f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103333:	a1 c4 f8 10 80       	mov    0x8010f8c4,%eax
80103338:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010333b:	7f d9                	jg     80103316 <log_write+0x4c>
8010333d:	eb 01                	jmp    80103340 <log_write+0x76>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
      break;
8010333f:	90                   	nop
  }
  log.lh.sector[i] = b->sector;
80103340:	8b 45 08             	mov    0x8(%ebp),%eax
80103343:	8b 40 08             	mov    0x8(%eax),%eax
80103346:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103349:	83 c2 10             	add    $0x10,%edx
8010334c:	89 04 95 88 f8 10 80 	mov    %eax,-0x7fef0778(,%edx,4)
  struct buf *lbuf = bread(b->dev, log.start+i+1);
80103353:	a1 b4 f8 10 80       	mov    0x8010f8b4,%eax
80103358:	03 45 f4             	add    -0xc(%ebp),%eax
8010335b:	83 c0 01             	add    $0x1,%eax
8010335e:	89 c2                	mov    %eax,%edx
80103360:	8b 45 08             	mov    0x8(%ebp),%eax
80103363:	8b 40 04             	mov    0x4(%eax),%eax
80103366:	89 54 24 04          	mov    %edx,0x4(%esp)
8010336a:	89 04 24             	mov    %eax,(%esp)
8010336d:	e8 34 ce ff ff       	call   801001a6 <bread>
80103372:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(lbuf->data, b->data, BSIZE);
80103375:	8b 45 08             	mov    0x8(%ebp),%eax
80103378:	8d 50 18             	lea    0x18(%eax),%edx
8010337b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010337e:	83 c0 18             	add    $0x18,%eax
80103381:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80103388:	00 
80103389:	89 54 24 04          	mov    %edx,0x4(%esp)
8010338d:	89 04 24             	mov    %eax,(%esp)
80103390:	e8 7c 20 00 00       	call   80105411 <memmove>
  bwrite(lbuf);
80103395:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103398:	89 04 24             	mov    %eax,(%esp)
8010339b:	e8 3d ce ff ff       	call   801001dd <bwrite>
  brelse(lbuf);
801033a0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801033a3:	89 04 24             	mov    %eax,(%esp)
801033a6:	e8 6c ce ff ff       	call   80100217 <brelse>
  if (i == log.lh.n)
801033ab:	a1 c4 f8 10 80       	mov    0x8010f8c4,%eax
801033b0:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801033b3:	75 0d                	jne    801033c2 <log_write+0xf8>
    log.lh.n++;
801033b5:	a1 c4 f8 10 80       	mov    0x8010f8c4,%eax
801033ba:	83 c0 01             	add    $0x1,%eax
801033bd:	a3 c4 f8 10 80       	mov    %eax,0x8010f8c4
  b->flags |= B_DIRTY; // XXX prevent eviction
801033c2:	8b 45 08             	mov    0x8(%ebp),%eax
801033c5:	8b 00                	mov    (%eax),%eax
801033c7:	89 c2                	mov    %eax,%edx
801033c9:	83 ca 04             	or     $0x4,%edx
801033cc:	8b 45 08             	mov    0x8(%ebp),%eax
801033cf:	89 10                	mov    %edx,(%eax)
}
801033d1:	c9                   	leave  
801033d2:	c3                   	ret    
	...

801033d4 <v2p>:
801033d4:	55                   	push   %ebp
801033d5:	89 e5                	mov    %esp,%ebp
801033d7:	8b 45 08             	mov    0x8(%ebp),%eax
801033da:	05 00 00 00 80       	add    $0x80000000,%eax
801033df:	5d                   	pop    %ebp
801033e0:	c3                   	ret    

801033e1 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
801033e1:	55                   	push   %ebp
801033e2:	89 e5                	mov    %esp,%ebp
801033e4:	8b 45 08             	mov    0x8(%ebp),%eax
801033e7:	05 00 00 00 80       	add    $0x80000000,%eax
801033ec:	5d                   	pop    %ebp
801033ed:	c3                   	ret    

801033ee <xchg>:
  asm volatile("sti");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
801033ee:	55                   	push   %ebp
801033ef:	89 e5                	mov    %esp,%ebp
801033f1:	53                   	push   %ebx
801033f2:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
801033f5:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
801033f8:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
801033fb:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
801033fe:	89 c3                	mov    %eax,%ebx
80103400:	89 d8                	mov    %ebx,%eax
80103402:	f0 87 02             	lock xchg %eax,(%edx)
80103405:	89 c3                	mov    %eax,%ebx
80103407:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
8010340a:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
8010340d:	83 c4 10             	add    $0x10,%esp
80103410:	5b                   	pop    %ebx
80103411:	5d                   	pop    %ebp
80103412:	c3                   	ret    

80103413 <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
80103413:	55                   	push   %ebp
80103414:	89 e5                	mov    %esp,%ebp
80103416:	83 e4 f0             	and    $0xfffffff0,%esp
80103419:	83 ec 10             	sub    $0x10,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
8010341c:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
80103423:	80 
80103424:	c7 04 24 fc 2a 11 80 	movl   $0x80112afc,(%esp)
8010342b:	e8 ad f5 ff ff       	call   801029dd <kinit1>
  kvmalloc();      // kernel page table
80103430:	e8 85 4c 00 00       	call   801080ba <kvmalloc>
  mpinit();        // collect info about this machine
80103435:	e8 63 04 00 00       	call   8010389d <mpinit>
  lapicinit(mpbcpu());
8010343a:	e8 2e 02 00 00       	call   8010366d <mpbcpu>
8010343f:	89 04 24             	mov    %eax,(%esp)
80103442:	e8 f5 f8 ff ff       	call   80102d3c <lapicinit>
  seginit();       // set up segments
80103447:	e8 11 46 00 00       	call   80107a5d <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
8010344c:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103452:	0f b6 00             	movzbl (%eax),%eax
80103455:	0f b6 c0             	movzbl %al,%eax
80103458:	89 44 24 04          	mov    %eax,0x4(%esp)
8010345c:	c7 04 24 8d 8a 10 80 	movl   $0x80108a8d,(%esp)
80103463:	e8 39 cf ff ff       	call   801003a1 <cprintf>
  picinit();       // interrupt controller
80103468:	e8 95 06 00 00       	call   80103b02 <picinit>
  ioapicinit();    // another interrupt controller
8010346d:	e8 5b f4 ff ff       	call   801028cd <ioapicinit>
  consoleinit();   // I/O devices & their interrupts
80103472:	e8 16 d6 ff ff       	call   80100a8d <consoleinit>
  uartinit();      // serial port
80103477:	e8 2c 39 00 00       	call   80106da8 <uartinit>
  pinit();         // process table
8010347c:	e8 a3 0b 00 00       	call   80104024 <pinit>
  tvinit();        // trap vectors
80103481:	e8 c5 34 00 00       	call   8010694b <tvinit>
  binit();         // buffer cache
80103486:	e8 a9 cb ff ff       	call   80100034 <binit>
  fileinit();      // file table
8010348b:	e8 70 da ff ff       	call   80100f00 <fileinit>
  iinit();         // inode cache
80103490:	e8 1e e1 ff ff       	call   801015b3 <iinit>
  ideinit();       // disk
80103495:	e8 8c f0 ff ff       	call   80102526 <ideinit>
  if(!ismp)
8010349a:	a1 04 f9 10 80       	mov    0x8010f904,%eax
8010349f:	85 c0                	test   %eax,%eax
801034a1:	75 05                	jne    801034a8 <main+0x95>
    timerinit();   // uniprocessor timer
801034a3:	e8 e6 33 00 00       	call   8010688e <timerinit>
  startothers();   // start other processors
801034a8:	e8 87 00 00 00       	call   80103534 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
801034ad:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
801034b4:	8e 
801034b5:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
801034bc:	e8 54 f5 ff ff       	call   80102a15 <kinit2>
  userinit();      // first user process
801034c1:	e8 96 10 00 00       	call   8010455c <userinit>
  // Finish setting up this processor in mpmain.
  mpmain();
801034c6:	e8 22 00 00 00       	call   801034ed <mpmain>

801034cb <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
801034cb:	55                   	push   %ebp
801034cc:	89 e5                	mov    %esp,%ebp
801034ce:	83 ec 18             	sub    $0x18,%esp
  switchkvm(); 
801034d1:	e8 fb 4b 00 00       	call   801080d1 <switchkvm>
  seginit();
801034d6:	e8 82 45 00 00       	call   80107a5d <seginit>
  lapicinit(cpunum());
801034db:	e8 b9 f9 ff ff       	call   80102e99 <cpunum>
801034e0:	89 04 24             	mov    %eax,(%esp)
801034e3:	e8 54 f8 ff ff       	call   80102d3c <lapicinit>
  mpmain();
801034e8:	e8 00 00 00 00       	call   801034ed <mpmain>

801034ed <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
801034ed:	55                   	push   %ebp
801034ee:	89 e5                	mov    %esp,%ebp
801034f0:	83 ec 18             	sub    $0x18,%esp
  cprintf("cpu%d: starting\n", cpu->id);
801034f3:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801034f9:	0f b6 00             	movzbl (%eax),%eax
801034fc:	0f b6 c0             	movzbl %al,%eax
801034ff:	89 44 24 04          	mov    %eax,0x4(%esp)
80103503:	c7 04 24 a4 8a 10 80 	movl   $0x80108aa4,(%esp)
8010350a:	e8 92 ce ff ff       	call   801003a1 <cprintf>
  idtinit();       // load idt register
8010350f:	e8 ab 35 00 00       	call   80106abf <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
80103514:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010351a:	05 a8 00 00 00       	add    $0xa8,%eax
8010351f:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80103526:	00 
80103527:	89 04 24             	mov    %eax,(%esp)
8010352a:	e8 bf fe ff ff       	call   801033ee <xchg>
  scheduler();     // start running processes
8010352f:	e8 38 16 00 00       	call   80104b6c <scheduler>

80103534 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80103534:	55                   	push   %ebp
80103535:	89 e5                	mov    %esp,%ebp
80103537:	53                   	push   %ebx
80103538:	83 ec 24             	sub    $0x24,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
8010353b:	c7 04 24 00 70 00 00 	movl   $0x7000,(%esp)
80103542:	e8 9a fe ff ff       	call   801033e1 <p2v>
80103547:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
8010354a:	b8 8a 00 00 00       	mov    $0x8a,%eax
8010354f:	89 44 24 08          	mov    %eax,0x8(%esp)
80103553:	c7 44 24 04 0c b5 10 	movl   $0x8010b50c,0x4(%esp)
8010355a:	80 
8010355b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010355e:	89 04 24             	mov    %eax,(%esp)
80103561:	e8 ab 1e 00 00       	call   80105411 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80103566:	c7 45 f4 20 f9 10 80 	movl   $0x8010f920,-0xc(%ebp)
8010356d:	e9 86 00 00 00       	jmp    801035f8 <startothers+0xc4>
    if(c == cpus+cpunum())  // We've started already.
80103572:	e8 22 f9 ff ff       	call   80102e99 <cpunum>
80103577:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
8010357d:	05 20 f9 10 80       	add    $0x8010f920,%eax
80103582:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103585:	74 69                	je     801035f0 <startothers+0xbc>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what 
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
80103587:	e8 7f f5 ff ff       	call   80102b0b <kalloc>
8010358c:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
8010358f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103592:	83 e8 04             	sub    $0x4,%eax
80103595:	8b 55 ec             	mov    -0x14(%ebp),%edx
80103598:	81 c2 00 10 00 00    	add    $0x1000,%edx
8010359e:	89 10                	mov    %edx,(%eax)
    *(void**)(code-8) = mpenter;
801035a0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801035a3:	83 e8 08             	sub    $0x8,%eax
801035a6:	c7 00 cb 34 10 80    	movl   $0x801034cb,(%eax)
    *(int**)(code-12) = (void *) v2p(entrypgdir);
801035ac:	8b 45 f0             	mov    -0x10(%ebp),%eax
801035af:	8d 58 f4             	lea    -0xc(%eax),%ebx
801035b2:	c7 04 24 00 a0 10 80 	movl   $0x8010a000,(%esp)
801035b9:	e8 16 fe ff ff       	call   801033d4 <v2p>
801035be:	89 03                	mov    %eax,(%ebx)

    lapicstartap(c->id, v2p(code));
801035c0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801035c3:	89 04 24             	mov    %eax,(%esp)
801035c6:	e8 09 fe ff ff       	call   801033d4 <v2p>
801035cb:	8b 55 f4             	mov    -0xc(%ebp),%edx
801035ce:	0f b6 12             	movzbl (%edx),%edx
801035d1:	0f b6 d2             	movzbl %dl,%edx
801035d4:	89 44 24 04          	mov    %eax,0x4(%esp)
801035d8:	89 14 24             	mov    %edx,(%esp)
801035db:	e8 3f f9 ff ff       	call   80102f1f <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
801035e0:	90                   	nop
801035e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801035e4:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
801035ea:	85 c0                	test   %eax,%eax
801035ec:	74 f3                	je     801035e1 <startothers+0xad>
801035ee:	eb 01                	jmp    801035f1 <startothers+0xbd>
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
    if(c == cpus+cpunum())  // We've started already.
      continue;
801035f0:	90                   	nop
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
801035f1:	81 45 f4 bc 00 00 00 	addl   $0xbc,-0xc(%ebp)
801035f8:	a1 00 ff 10 80       	mov    0x8010ff00,%eax
801035fd:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103603:	05 20 f9 10 80       	add    $0x8010f920,%eax
80103608:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010360b:	0f 87 61 ff ff ff    	ja     80103572 <startothers+0x3e>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;
  }
}
80103611:	83 c4 24             	add    $0x24,%esp
80103614:	5b                   	pop    %ebx
80103615:	5d                   	pop    %ebp
80103616:	c3                   	ret    
	...

80103618 <p2v>:
80103618:	55                   	push   %ebp
80103619:	89 e5                	mov    %esp,%ebp
8010361b:	8b 45 08             	mov    0x8(%ebp),%eax
8010361e:	05 00 00 00 80       	add    $0x80000000,%eax
80103623:	5d                   	pop    %ebp
80103624:	c3                   	ret    

80103625 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80103625:	55                   	push   %ebp
80103626:	89 e5                	mov    %esp,%ebp
80103628:	53                   	push   %ebx
80103629:	83 ec 14             	sub    $0x14,%esp
8010362c:	8b 45 08             	mov    0x8(%ebp),%eax
8010362f:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80103633:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80103637:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
8010363b:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
8010363f:	ec                   	in     (%dx),%al
80103640:	89 c3                	mov    %eax,%ebx
80103642:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80103645:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80103649:	83 c4 14             	add    $0x14,%esp
8010364c:	5b                   	pop    %ebx
8010364d:	5d                   	pop    %ebp
8010364e:	c3                   	ret    

8010364f <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
8010364f:	55                   	push   %ebp
80103650:	89 e5                	mov    %esp,%ebp
80103652:	83 ec 08             	sub    $0x8,%esp
80103655:	8b 55 08             	mov    0x8(%ebp),%edx
80103658:	8b 45 0c             	mov    0xc(%ebp),%eax
8010365b:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
8010365f:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103662:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103666:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
8010366a:	ee                   	out    %al,(%dx)
}
8010366b:	c9                   	leave  
8010366c:	c3                   	ret    

8010366d <mpbcpu>:
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
8010366d:	55                   	push   %ebp
8010366e:	89 e5                	mov    %esp,%ebp
  return bcpu-cpus;
80103670:	a1 44 b6 10 80       	mov    0x8010b644,%eax
80103675:	89 c2                	mov    %eax,%edx
80103677:	b8 20 f9 10 80       	mov    $0x8010f920,%eax
8010367c:	89 d1                	mov    %edx,%ecx
8010367e:	29 c1                	sub    %eax,%ecx
80103680:	89 c8                	mov    %ecx,%eax
80103682:	c1 f8 02             	sar    $0x2,%eax
80103685:	69 c0 cf 46 7d 67    	imul   $0x677d46cf,%eax,%eax
}
8010368b:	5d                   	pop    %ebp
8010368c:	c3                   	ret    

8010368d <sum>:

static uchar
sum(uchar *addr, int len)
{
8010368d:	55                   	push   %ebp
8010368e:	89 e5                	mov    %esp,%ebp
80103690:	83 ec 10             	sub    $0x10,%esp
  int i, sum;
  
  sum = 0;
80103693:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
8010369a:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801036a1:	eb 13                	jmp    801036b6 <sum+0x29>
    sum += addr[i];
801036a3:	8b 45 fc             	mov    -0x4(%ebp),%eax
801036a6:	03 45 08             	add    0x8(%ebp),%eax
801036a9:	0f b6 00             	movzbl (%eax),%eax
801036ac:	0f b6 c0             	movzbl %al,%eax
801036af:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
801036b2:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801036b6:	8b 45 fc             	mov    -0x4(%ebp),%eax
801036b9:	3b 45 0c             	cmp    0xc(%ebp),%eax
801036bc:	7c e5                	jl     801036a3 <sum+0x16>
    sum += addr[i];
  return sum;
801036be:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
801036c1:	c9                   	leave  
801036c2:	c3                   	ret    

801036c3 <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
801036c3:	55                   	push   %ebp
801036c4:	89 e5                	mov    %esp,%ebp
801036c6:	83 ec 28             	sub    $0x28,%esp
  uchar *e, *p, *addr;

  addr = p2v(a);
801036c9:	8b 45 08             	mov    0x8(%ebp),%eax
801036cc:	89 04 24             	mov    %eax,(%esp)
801036cf:	e8 44 ff ff ff       	call   80103618 <p2v>
801036d4:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
801036d7:	8b 45 0c             	mov    0xc(%ebp),%eax
801036da:	03 45 f0             	add    -0x10(%ebp),%eax
801036dd:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
801036e0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801036e3:	89 45 f4             	mov    %eax,-0xc(%ebp)
801036e6:	eb 3f                	jmp    80103727 <mpsearch1+0x64>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
801036e8:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
801036ef:	00 
801036f0:	c7 44 24 04 b8 8a 10 	movl   $0x80108ab8,0x4(%esp)
801036f7:	80 
801036f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801036fb:	89 04 24             	mov    %eax,(%esp)
801036fe:	e8 b2 1c 00 00       	call   801053b5 <memcmp>
80103703:	85 c0                	test   %eax,%eax
80103705:	75 1c                	jne    80103723 <mpsearch1+0x60>
80103707:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
8010370e:	00 
8010370f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103712:	89 04 24             	mov    %eax,(%esp)
80103715:	e8 73 ff ff ff       	call   8010368d <sum>
8010371a:	84 c0                	test   %al,%al
8010371c:	75 05                	jne    80103723 <mpsearch1+0x60>
      return (struct mp*)p;
8010371e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103721:	eb 11                	jmp    80103734 <mpsearch1+0x71>
{
  uchar *e, *p, *addr;

  addr = p2v(a);
  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
80103723:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80103727:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010372a:	3b 45 ec             	cmp    -0x14(%ebp),%eax
8010372d:	72 b9                	jb     801036e8 <mpsearch1+0x25>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
8010372f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103734:	c9                   	leave  
80103735:	c3                   	ret    

80103736 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80103736:	55                   	push   %ebp
80103737:	89 e5                	mov    %esp,%ebp
80103739:	83 ec 28             	sub    $0x28,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
8010373c:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80103743:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103746:	83 c0 0f             	add    $0xf,%eax
80103749:	0f b6 00             	movzbl (%eax),%eax
8010374c:	0f b6 c0             	movzbl %al,%eax
8010374f:	89 c2                	mov    %eax,%edx
80103751:	c1 e2 08             	shl    $0x8,%edx
80103754:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103757:	83 c0 0e             	add    $0xe,%eax
8010375a:	0f b6 00             	movzbl (%eax),%eax
8010375d:	0f b6 c0             	movzbl %al,%eax
80103760:	09 d0                	or     %edx,%eax
80103762:	c1 e0 04             	shl    $0x4,%eax
80103765:	89 45 f0             	mov    %eax,-0x10(%ebp)
80103768:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010376c:	74 21                	je     8010378f <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
8010376e:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80103775:	00 
80103776:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103779:	89 04 24             	mov    %eax,(%esp)
8010377c:	e8 42 ff ff ff       	call   801036c3 <mpsearch1>
80103781:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103784:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103788:	74 50                	je     801037da <mpsearch+0xa4>
      return mp;
8010378a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010378d:	eb 5f                	jmp    801037ee <mpsearch+0xb8>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
8010378f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103792:	83 c0 14             	add    $0x14,%eax
80103795:	0f b6 00             	movzbl (%eax),%eax
80103798:	0f b6 c0             	movzbl %al,%eax
8010379b:	89 c2                	mov    %eax,%edx
8010379d:	c1 e2 08             	shl    $0x8,%edx
801037a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801037a3:	83 c0 13             	add    $0x13,%eax
801037a6:	0f b6 00             	movzbl (%eax),%eax
801037a9:	0f b6 c0             	movzbl %al,%eax
801037ac:	09 d0                	or     %edx,%eax
801037ae:	c1 e0 0a             	shl    $0xa,%eax
801037b1:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
801037b4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801037b7:	2d 00 04 00 00       	sub    $0x400,%eax
801037bc:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
801037c3:	00 
801037c4:	89 04 24             	mov    %eax,(%esp)
801037c7:	e8 f7 fe ff ff       	call   801036c3 <mpsearch1>
801037cc:	89 45 ec             	mov    %eax,-0x14(%ebp)
801037cf:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801037d3:	74 05                	je     801037da <mpsearch+0xa4>
      return mp;
801037d5:	8b 45 ec             	mov    -0x14(%ebp),%eax
801037d8:	eb 14                	jmp    801037ee <mpsearch+0xb8>
  }
  return mpsearch1(0xF0000, 0x10000);
801037da:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
801037e1:	00 
801037e2:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
801037e9:	e8 d5 fe ff ff       	call   801036c3 <mpsearch1>
}
801037ee:	c9                   	leave  
801037ef:	c3                   	ret    

801037f0 <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
801037f0:	55                   	push   %ebp
801037f1:	89 e5                	mov    %esp,%ebp
801037f3:	83 ec 28             	sub    $0x28,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
801037f6:	e8 3b ff ff ff       	call   80103736 <mpsearch>
801037fb:	89 45 f4             	mov    %eax,-0xc(%ebp)
801037fe:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103802:	74 0a                	je     8010380e <mpconfig+0x1e>
80103804:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103807:	8b 40 04             	mov    0x4(%eax),%eax
8010380a:	85 c0                	test   %eax,%eax
8010380c:	75 0a                	jne    80103818 <mpconfig+0x28>
    return 0;
8010380e:	b8 00 00 00 00       	mov    $0x0,%eax
80103813:	e9 83 00 00 00       	jmp    8010389b <mpconfig+0xab>
  conf = (struct mpconf*) p2v((uint) mp->physaddr);
80103818:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010381b:	8b 40 04             	mov    0x4(%eax),%eax
8010381e:	89 04 24             	mov    %eax,(%esp)
80103821:	e8 f2 fd ff ff       	call   80103618 <p2v>
80103826:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
80103829:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80103830:	00 
80103831:	c7 44 24 04 bd 8a 10 	movl   $0x80108abd,0x4(%esp)
80103838:	80 
80103839:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010383c:	89 04 24             	mov    %eax,(%esp)
8010383f:	e8 71 1b 00 00       	call   801053b5 <memcmp>
80103844:	85 c0                	test   %eax,%eax
80103846:	74 07                	je     8010384f <mpconfig+0x5f>
    return 0;
80103848:	b8 00 00 00 00       	mov    $0x0,%eax
8010384d:	eb 4c                	jmp    8010389b <mpconfig+0xab>
  if(conf->version != 1 && conf->version != 4)
8010384f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103852:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80103856:	3c 01                	cmp    $0x1,%al
80103858:	74 12                	je     8010386c <mpconfig+0x7c>
8010385a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010385d:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80103861:	3c 04                	cmp    $0x4,%al
80103863:	74 07                	je     8010386c <mpconfig+0x7c>
    return 0;
80103865:	b8 00 00 00 00       	mov    $0x0,%eax
8010386a:	eb 2f                	jmp    8010389b <mpconfig+0xab>
  if(sum((uchar*)conf, conf->length) != 0)
8010386c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010386f:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80103873:	0f b7 c0             	movzwl %ax,%eax
80103876:	89 44 24 04          	mov    %eax,0x4(%esp)
8010387a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010387d:	89 04 24             	mov    %eax,(%esp)
80103880:	e8 08 fe ff ff       	call   8010368d <sum>
80103885:	84 c0                	test   %al,%al
80103887:	74 07                	je     80103890 <mpconfig+0xa0>
    return 0;
80103889:	b8 00 00 00 00       	mov    $0x0,%eax
8010388e:	eb 0b                	jmp    8010389b <mpconfig+0xab>
  *pmp = mp;
80103890:	8b 45 08             	mov    0x8(%ebp),%eax
80103893:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103896:	89 10                	mov    %edx,(%eax)
  return conf;
80103898:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
8010389b:	c9                   	leave  
8010389c:	c3                   	ret    

8010389d <mpinit>:

void
mpinit(void)
{
8010389d:	55                   	push   %ebp
8010389e:	89 e5                	mov    %esp,%ebp
801038a0:	83 ec 38             	sub    $0x38,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
801038a3:	c7 05 44 b6 10 80 20 	movl   $0x8010f920,0x8010b644
801038aa:	f9 10 80 
  if((conf = mpconfig(&mp)) == 0)
801038ad:	8d 45 e0             	lea    -0x20(%ebp),%eax
801038b0:	89 04 24             	mov    %eax,(%esp)
801038b3:	e8 38 ff ff ff       	call   801037f0 <mpconfig>
801038b8:	89 45 f0             	mov    %eax,-0x10(%ebp)
801038bb:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801038bf:	0f 84 9c 01 00 00    	je     80103a61 <mpinit+0x1c4>
    return;
  ismp = 1;
801038c5:	c7 05 04 f9 10 80 01 	movl   $0x1,0x8010f904
801038cc:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
801038cf:	8b 45 f0             	mov    -0x10(%ebp),%eax
801038d2:	8b 40 24             	mov    0x24(%eax),%eax
801038d5:	a3 7c f8 10 80       	mov    %eax,0x8010f87c
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
801038da:	8b 45 f0             	mov    -0x10(%ebp),%eax
801038dd:	83 c0 2c             	add    $0x2c,%eax
801038e0:	89 45 f4             	mov    %eax,-0xc(%ebp)
801038e3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801038e6:	0f b7 40 04          	movzwl 0x4(%eax),%eax
801038ea:	0f b7 c0             	movzwl %ax,%eax
801038ed:	03 45 f0             	add    -0x10(%ebp),%eax
801038f0:	89 45 ec             	mov    %eax,-0x14(%ebp)
801038f3:	e9 f4 00 00 00       	jmp    801039ec <mpinit+0x14f>
    switch(*p){
801038f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801038fb:	0f b6 00             	movzbl (%eax),%eax
801038fe:	0f b6 c0             	movzbl %al,%eax
80103901:	83 f8 04             	cmp    $0x4,%eax
80103904:	0f 87 bf 00 00 00    	ja     801039c9 <mpinit+0x12c>
8010390a:	8b 04 85 00 8b 10 80 	mov    -0x7fef7500(,%eax,4),%eax
80103911:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
80103913:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103916:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(ncpu != proc->apicid){
80103919:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010391c:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103920:	0f b6 d0             	movzbl %al,%edx
80103923:	a1 00 ff 10 80       	mov    0x8010ff00,%eax
80103928:	39 c2                	cmp    %eax,%edx
8010392a:	74 2d                	je     80103959 <mpinit+0xbc>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
8010392c:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010392f:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103933:	0f b6 d0             	movzbl %al,%edx
80103936:	a1 00 ff 10 80       	mov    0x8010ff00,%eax
8010393b:	89 54 24 08          	mov    %edx,0x8(%esp)
8010393f:	89 44 24 04          	mov    %eax,0x4(%esp)
80103943:	c7 04 24 c2 8a 10 80 	movl   $0x80108ac2,(%esp)
8010394a:	e8 52 ca ff ff       	call   801003a1 <cprintf>
        ismp = 0;
8010394f:	c7 05 04 f9 10 80 00 	movl   $0x0,0x8010f904
80103956:	00 00 00 
      }
      if(proc->flags & MPBOOT)
80103959:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010395c:	0f b6 40 03          	movzbl 0x3(%eax),%eax
80103960:	0f b6 c0             	movzbl %al,%eax
80103963:	83 e0 02             	and    $0x2,%eax
80103966:	85 c0                	test   %eax,%eax
80103968:	74 15                	je     8010397f <mpinit+0xe2>
        bcpu = &cpus[ncpu];
8010396a:	a1 00 ff 10 80       	mov    0x8010ff00,%eax
8010396f:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103975:	05 20 f9 10 80       	add    $0x8010f920,%eax
8010397a:	a3 44 b6 10 80       	mov    %eax,0x8010b644
      cpus[ncpu].id = ncpu;
8010397f:	8b 15 00 ff 10 80    	mov    0x8010ff00,%edx
80103985:	a1 00 ff 10 80       	mov    0x8010ff00,%eax
8010398a:	69 d2 bc 00 00 00    	imul   $0xbc,%edx,%edx
80103990:	81 c2 20 f9 10 80    	add    $0x8010f920,%edx
80103996:	88 02                	mov    %al,(%edx)
      ncpu++;
80103998:	a1 00 ff 10 80       	mov    0x8010ff00,%eax
8010399d:	83 c0 01             	add    $0x1,%eax
801039a0:	a3 00 ff 10 80       	mov    %eax,0x8010ff00
      p += sizeof(struct mpproc);
801039a5:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
801039a9:	eb 41                	jmp    801039ec <mpinit+0x14f>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
801039ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039ae:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      ioapicid = ioapic->apicno;
801039b1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801039b4:	0f b6 40 01          	movzbl 0x1(%eax),%eax
801039b8:	a2 00 f9 10 80       	mov    %al,0x8010f900
      p += sizeof(struct mpioapic);
801039bd:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
801039c1:	eb 29                	jmp    801039ec <mpinit+0x14f>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
801039c3:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
801039c7:	eb 23                	jmp    801039ec <mpinit+0x14f>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
801039c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039cc:	0f b6 00             	movzbl (%eax),%eax
801039cf:	0f b6 c0             	movzbl %al,%eax
801039d2:	89 44 24 04          	mov    %eax,0x4(%esp)
801039d6:	c7 04 24 e0 8a 10 80 	movl   $0x80108ae0,(%esp)
801039dd:	e8 bf c9 ff ff       	call   801003a1 <cprintf>
      ismp = 0;
801039e2:	c7 05 04 f9 10 80 00 	movl   $0x0,0x8010f904
801039e9:	00 00 00 
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
801039ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039ef:	3b 45 ec             	cmp    -0x14(%ebp),%eax
801039f2:	0f 82 00 ff ff ff    	jb     801038f8 <mpinit+0x5b>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
      ismp = 0;
    }
  }
  if(!ismp){
801039f8:	a1 04 f9 10 80       	mov    0x8010f904,%eax
801039fd:	85 c0                	test   %eax,%eax
801039ff:	75 1d                	jne    80103a1e <mpinit+0x181>
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
80103a01:	c7 05 00 ff 10 80 01 	movl   $0x1,0x8010ff00
80103a08:	00 00 00 
    lapic = 0;
80103a0b:	c7 05 7c f8 10 80 00 	movl   $0x0,0x8010f87c
80103a12:	00 00 00 
    ioapicid = 0;
80103a15:	c6 05 00 f9 10 80 00 	movb   $0x0,0x8010f900
    return;
80103a1c:	eb 44                	jmp    80103a62 <mpinit+0x1c5>
  }

  if(mp->imcrp){
80103a1e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80103a21:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
80103a25:	84 c0                	test   %al,%al
80103a27:	74 39                	je     80103a62 <mpinit+0x1c5>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
80103a29:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
80103a30:	00 
80103a31:	c7 04 24 22 00 00 00 	movl   $0x22,(%esp)
80103a38:	e8 12 fc ff ff       	call   8010364f <outb>
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80103a3d:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80103a44:	e8 dc fb ff ff       	call   80103625 <inb>
80103a49:	83 c8 01             	or     $0x1,%eax
80103a4c:	0f b6 c0             	movzbl %al,%eax
80103a4f:	89 44 24 04          	mov    %eax,0x4(%esp)
80103a53:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80103a5a:	e8 f0 fb ff ff       	call   8010364f <outb>
80103a5f:	eb 01                	jmp    80103a62 <mpinit+0x1c5>
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
80103a61:	90                   	nop
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
  }
}
80103a62:	c9                   	leave  
80103a63:	c3                   	ret    

80103a64 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103a64:	55                   	push   %ebp
80103a65:	89 e5                	mov    %esp,%ebp
80103a67:	83 ec 08             	sub    $0x8,%esp
80103a6a:	8b 55 08             	mov    0x8(%ebp),%edx
80103a6d:	8b 45 0c             	mov    0xc(%ebp),%eax
80103a70:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103a74:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103a77:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103a7b:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103a7f:	ee                   	out    %al,(%dx)
}
80103a80:	c9                   	leave  
80103a81:	c3                   	ret    

80103a82 <picsetmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static ushort irqmask = 0xFFFF & ~(1<<IRQ_SLAVE);

static void
picsetmask(ushort mask)
{
80103a82:	55                   	push   %ebp
80103a83:	89 e5                	mov    %esp,%ebp
80103a85:	83 ec 0c             	sub    $0xc,%esp
80103a88:	8b 45 08             	mov    0x8(%ebp),%eax
80103a8b:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  irqmask = mask;
80103a8f:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103a93:	66 a3 00 b0 10 80    	mov    %ax,0x8010b000
  outb(IO_PIC1+1, mask);
80103a99:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103a9d:	0f b6 c0             	movzbl %al,%eax
80103aa0:	89 44 24 04          	mov    %eax,0x4(%esp)
80103aa4:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103aab:	e8 b4 ff ff ff       	call   80103a64 <outb>
  outb(IO_PIC2+1, mask >> 8);
80103ab0:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103ab4:	66 c1 e8 08          	shr    $0x8,%ax
80103ab8:	0f b6 c0             	movzbl %al,%eax
80103abb:	89 44 24 04          	mov    %eax,0x4(%esp)
80103abf:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103ac6:	e8 99 ff ff ff       	call   80103a64 <outb>
}
80103acb:	c9                   	leave  
80103acc:	c3                   	ret    

80103acd <picenable>:

void
picenable(int irq)
{
80103acd:	55                   	push   %ebp
80103ace:	89 e5                	mov    %esp,%ebp
80103ad0:	53                   	push   %ebx
80103ad1:	83 ec 04             	sub    $0x4,%esp
  picsetmask(irqmask & ~(1<<irq));
80103ad4:	8b 45 08             	mov    0x8(%ebp),%eax
80103ad7:	ba 01 00 00 00       	mov    $0x1,%edx
80103adc:	89 d3                	mov    %edx,%ebx
80103ade:	89 c1                	mov    %eax,%ecx
80103ae0:	d3 e3                	shl    %cl,%ebx
80103ae2:	89 d8                	mov    %ebx,%eax
80103ae4:	89 c2                	mov    %eax,%edx
80103ae6:	f7 d2                	not    %edx
80103ae8:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
80103aef:	21 d0                	and    %edx,%eax
80103af1:	0f b7 c0             	movzwl %ax,%eax
80103af4:	89 04 24             	mov    %eax,(%esp)
80103af7:	e8 86 ff ff ff       	call   80103a82 <picsetmask>
}
80103afc:	83 c4 04             	add    $0x4,%esp
80103aff:	5b                   	pop    %ebx
80103b00:	5d                   	pop    %ebp
80103b01:	c3                   	ret    

80103b02 <picinit>:

// Initialize the 8259A interrupt controllers.
void
picinit(void)
{
80103b02:	55                   	push   %ebp
80103b03:	89 e5                	mov    %esp,%ebp
80103b05:	83 ec 08             	sub    $0x8,%esp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
80103b08:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80103b0f:	00 
80103b10:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103b17:	e8 48 ff ff ff       	call   80103a64 <outb>
  outb(IO_PIC2+1, 0xFF);
80103b1c:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80103b23:	00 
80103b24:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103b2b:	e8 34 ff ff ff       	call   80103a64 <outb>

  // ICW1:  0001g0hi
  //    g:  0 = edge triggering, 1 = level triggering
  //    h:  0 = cascaded PICs, 1 = master only
  //    i:  0 = no ICW4, 1 = ICW4 required
  outb(IO_PIC1, 0x11);
80103b30:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80103b37:	00 
80103b38:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103b3f:	e8 20 ff ff ff       	call   80103a64 <outb>

  // ICW2:  Vector offset
  outb(IO_PIC1+1, T_IRQ0);
80103b44:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
80103b4b:	00 
80103b4c:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103b53:	e8 0c ff ff ff       	call   80103a64 <outb>

  // ICW3:  (master PIC) bit mask of IR lines connected to slaves
  //        (slave PIC) 3-bit # of slave's connection to master
  outb(IO_PIC1+1, 1<<IRQ_SLAVE);
80103b58:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
80103b5f:	00 
80103b60:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103b67:	e8 f8 fe ff ff       	call   80103a64 <outb>
  //    m:  0 = slave PIC, 1 = master PIC
  //      (ignored when b is 0, as the master/slave role
  //      can be hardwired).
  //    a:  1 = Automatic EOI mode
  //    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
  outb(IO_PIC1+1, 0x3);
80103b6c:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80103b73:	00 
80103b74:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103b7b:	e8 e4 fe ff ff       	call   80103a64 <outb>

  // Set up slave (8259A-2)
  outb(IO_PIC2, 0x11);                  // ICW1
80103b80:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80103b87:	00 
80103b88:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103b8f:	e8 d0 fe ff ff       	call   80103a64 <outb>
  outb(IO_PIC2+1, T_IRQ0 + 8);      // ICW2
80103b94:	c7 44 24 04 28 00 00 	movl   $0x28,0x4(%esp)
80103b9b:	00 
80103b9c:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103ba3:	e8 bc fe ff ff       	call   80103a64 <outb>
  outb(IO_PIC2+1, IRQ_SLAVE);           // ICW3
80103ba8:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80103baf:	00 
80103bb0:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103bb7:	e8 a8 fe ff ff       	call   80103a64 <outb>
  // NB Automatic EOI mode doesn't tend to work on the slave.
  // Linux source code says it's "to be investigated".
  outb(IO_PIC2+1, 0x3);                 // ICW4
80103bbc:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80103bc3:	00 
80103bc4:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103bcb:	e8 94 fe ff ff       	call   80103a64 <outb>

  // OCW3:  0ef01prs
  //   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
  //    p:  0 = no polling, 1 = polling mode
  //   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
  outb(IO_PIC1, 0x68);             // clear specific mask
80103bd0:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80103bd7:	00 
80103bd8:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103bdf:	e8 80 fe ff ff       	call   80103a64 <outb>
  outb(IO_PIC1, 0x0a);             // read IRR by default
80103be4:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80103beb:	00 
80103bec:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103bf3:	e8 6c fe ff ff       	call   80103a64 <outb>

  outb(IO_PIC2, 0x68);             // OCW3
80103bf8:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80103bff:	00 
80103c00:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103c07:	e8 58 fe ff ff       	call   80103a64 <outb>
  outb(IO_PIC2, 0x0a);             // OCW3
80103c0c:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80103c13:	00 
80103c14:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103c1b:	e8 44 fe ff ff       	call   80103a64 <outb>

  if(irqmask != 0xFFFF)
80103c20:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
80103c27:	66 83 f8 ff          	cmp    $0xffff,%ax
80103c2b:	74 12                	je     80103c3f <picinit+0x13d>
    picsetmask(irqmask);
80103c2d:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
80103c34:	0f b7 c0             	movzwl %ax,%eax
80103c37:	89 04 24             	mov    %eax,(%esp)
80103c3a:	e8 43 fe ff ff       	call   80103a82 <picsetmask>
}
80103c3f:	c9                   	leave  
80103c40:	c3                   	ret    
80103c41:	00 00                	add    %al,(%eax)
	...

80103c44 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80103c44:	55                   	push   %ebp
80103c45:	89 e5                	mov    %esp,%ebp
80103c47:	83 ec 28             	sub    $0x28,%esp
  struct pipe *p;

  p = 0;
80103c4a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
80103c51:	8b 45 0c             	mov    0xc(%ebp),%eax
80103c54:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
80103c5a:	8b 45 0c             	mov    0xc(%ebp),%eax
80103c5d:	8b 10                	mov    (%eax),%edx
80103c5f:	8b 45 08             	mov    0x8(%ebp),%eax
80103c62:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80103c64:	e8 b3 d2 ff ff       	call   80100f1c <filealloc>
80103c69:	8b 55 08             	mov    0x8(%ebp),%edx
80103c6c:	89 02                	mov    %eax,(%edx)
80103c6e:	8b 45 08             	mov    0x8(%ebp),%eax
80103c71:	8b 00                	mov    (%eax),%eax
80103c73:	85 c0                	test   %eax,%eax
80103c75:	0f 84 c8 00 00 00    	je     80103d43 <pipealloc+0xff>
80103c7b:	e8 9c d2 ff ff       	call   80100f1c <filealloc>
80103c80:	8b 55 0c             	mov    0xc(%ebp),%edx
80103c83:	89 02                	mov    %eax,(%edx)
80103c85:	8b 45 0c             	mov    0xc(%ebp),%eax
80103c88:	8b 00                	mov    (%eax),%eax
80103c8a:	85 c0                	test   %eax,%eax
80103c8c:	0f 84 b1 00 00 00    	je     80103d43 <pipealloc+0xff>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
80103c92:	e8 74 ee ff ff       	call   80102b0b <kalloc>
80103c97:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103c9a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103c9e:	0f 84 9e 00 00 00    	je     80103d42 <pipealloc+0xfe>
    goto bad;
  p->readopen = 1;
80103ca4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ca7:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80103cae:	00 00 00 
  p->writeopen = 1;
80103cb1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103cb4:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80103cbb:	00 00 00 
  p->nwrite = 0;
80103cbe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103cc1:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80103cc8:	00 00 00 
  p->nread = 0;
80103ccb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103cce:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80103cd5:	00 00 00 
  initlock(&p->lock, "pipe");
80103cd8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103cdb:	c7 44 24 04 14 8b 10 	movl   $0x80108b14,0x4(%esp)
80103ce2:	80 
80103ce3:	89 04 24             	mov    %eax,(%esp)
80103ce6:	e8 ab 13 00 00       	call   80105096 <initlock>
  (*f0)->type = FD_PIPE;
80103ceb:	8b 45 08             	mov    0x8(%ebp),%eax
80103cee:	8b 00                	mov    (%eax),%eax
80103cf0:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80103cf6:	8b 45 08             	mov    0x8(%ebp),%eax
80103cf9:	8b 00                	mov    (%eax),%eax
80103cfb:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80103cff:	8b 45 08             	mov    0x8(%ebp),%eax
80103d02:	8b 00                	mov    (%eax),%eax
80103d04:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80103d08:	8b 45 08             	mov    0x8(%ebp),%eax
80103d0b:	8b 00                	mov    (%eax),%eax
80103d0d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103d10:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
80103d13:	8b 45 0c             	mov    0xc(%ebp),%eax
80103d16:	8b 00                	mov    (%eax),%eax
80103d18:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80103d1e:	8b 45 0c             	mov    0xc(%ebp),%eax
80103d21:	8b 00                	mov    (%eax),%eax
80103d23:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80103d27:	8b 45 0c             	mov    0xc(%ebp),%eax
80103d2a:	8b 00                	mov    (%eax),%eax
80103d2c:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80103d30:	8b 45 0c             	mov    0xc(%ebp),%eax
80103d33:	8b 00                	mov    (%eax),%eax
80103d35:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103d38:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
80103d3b:	b8 00 00 00 00       	mov    $0x0,%eax
80103d40:	eb 43                	jmp    80103d85 <pipealloc+0x141>
  p = 0;
  *f0 = *f1 = 0;
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
    goto bad;
80103d42:	90                   	nop
  (*f1)->pipe = p;
  return 0;

//PAGEBREAK: 20
 bad:
  if(p)
80103d43:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103d47:	74 0b                	je     80103d54 <pipealloc+0x110>
    kfree((char*)p);
80103d49:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d4c:	89 04 24             	mov    %eax,(%esp)
80103d4f:	e8 1e ed ff ff       	call   80102a72 <kfree>
  if(*f0)
80103d54:	8b 45 08             	mov    0x8(%ebp),%eax
80103d57:	8b 00                	mov    (%eax),%eax
80103d59:	85 c0                	test   %eax,%eax
80103d5b:	74 0d                	je     80103d6a <pipealloc+0x126>
    fileclose(*f0);
80103d5d:	8b 45 08             	mov    0x8(%ebp),%eax
80103d60:	8b 00                	mov    (%eax),%eax
80103d62:	89 04 24             	mov    %eax,(%esp)
80103d65:	e8 5a d2 ff ff       	call   80100fc4 <fileclose>
  if(*f1)
80103d6a:	8b 45 0c             	mov    0xc(%ebp),%eax
80103d6d:	8b 00                	mov    (%eax),%eax
80103d6f:	85 c0                	test   %eax,%eax
80103d71:	74 0d                	je     80103d80 <pipealloc+0x13c>
    fileclose(*f1);
80103d73:	8b 45 0c             	mov    0xc(%ebp),%eax
80103d76:	8b 00                	mov    (%eax),%eax
80103d78:	89 04 24             	mov    %eax,(%esp)
80103d7b:	e8 44 d2 ff ff       	call   80100fc4 <fileclose>
  return -1;
80103d80:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80103d85:	c9                   	leave  
80103d86:	c3                   	ret    

80103d87 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80103d87:	55                   	push   %ebp
80103d88:	89 e5                	mov    %esp,%ebp
80103d8a:	83 ec 18             	sub    $0x18,%esp
  acquire(&p->lock);
80103d8d:	8b 45 08             	mov    0x8(%ebp),%eax
80103d90:	89 04 24             	mov    %eax,(%esp)
80103d93:	e8 1f 13 00 00       	call   801050b7 <acquire>
  if(writable){
80103d98:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80103d9c:	74 1f                	je     80103dbd <pipeclose+0x36>
    p->writeopen = 0;
80103d9e:	8b 45 08             	mov    0x8(%ebp),%eax
80103da1:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
80103da8:	00 00 00 
    wakeup(&p->nread);
80103dab:	8b 45 08             	mov    0x8(%ebp),%eax
80103dae:	05 34 02 00 00       	add    $0x234,%eax
80103db3:	89 04 24             	mov    %eax,(%esp)
80103db6:	e8 f2 10 00 00       	call   80104ead <wakeup>
80103dbb:	eb 1d                	jmp    80103dda <pipeclose+0x53>
  } else {
    p->readopen = 0;
80103dbd:	8b 45 08             	mov    0x8(%ebp),%eax
80103dc0:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
80103dc7:	00 00 00 
    wakeup(&p->nwrite);
80103dca:	8b 45 08             	mov    0x8(%ebp),%eax
80103dcd:	05 38 02 00 00       	add    $0x238,%eax
80103dd2:	89 04 24             	mov    %eax,(%esp)
80103dd5:	e8 d3 10 00 00       	call   80104ead <wakeup>
  }
  if(p->readopen == 0 && p->writeopen == 0){
80103dda:	8b 45 08             	mov    0x8(%ebp),%eax
80103ddd:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80103de3:	85 c0                	test   %eax,%eax
80103de5:	75 25                	jne    80103e0c <pipeclose+0x85>
80103de7:	8b 45 08             	mov    0x8(%ebp),%eax
80103dea:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80103df0:	85 c0                	test   %eax,%eax
80103df2:	75 18                	jne    80103e0c <pipeclose+0x85>
    release(&p->lock);
80103df4:	8b 45 08             	mov    0x8(%ebp),%eax
80103df7:	89 04 24             	mov    %eax,(%esp)
80103dfa:	e8 53 13 00 00       	call   80105152 <release>
    kfree((char*)p);
80103dff:	8b 45 08             	mov    0x8(%ebp),%eax
80103e02:	89 04 24             	mov    %eax,(%esp)
80103e05:	e8 68 ec ff ff       	call   80102a72 <kfree>
80103e0a:	eb 0b                	jmp    80103e17 <pipeclose+0x90>
  } else
    release(&p->lock);
80103e0c:	8b 45 08             	mov    0x8(%ebp),%eax
80103e0f:	89 04 24             	mov    %eax,(%esp)
80103e12:	e8 3b 13 00 00       	call   80105152 <release>
}
80103e17:	c9                   	leave  
80103e18:	c3                   	ret    

80103e19 <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
80103e19:	55                   	push   %ebp
80103e1a:	89 e5                	mov    %esp,%ebp
80103e1c:	53                   	push   %ebx
80103e1d:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80103e20:	8b 45 08             	mov    0x8(%ebp),%eax
80103e23:	89 04 24             	mov    %eax,(%esp)
80103e26:	e8 8c 12 00 00       	call   801050b7 <acquire>
  for(i = 0; i < n; i++){
80103e2b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103e32:	e9 a6 00 00 00       	jmp    80103edd <pipewrite+0xc4>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
      if(p->readopen == 0 || proc->killed){
80103e37:	8b 45 08             	mov    0x8(%ebp),%eax
80103e3a:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80103e40:	85 c0                	test   %eax,%eax
80103e42:	74 0d                	je     80103e51 <pipewrite+0x38>
80103e44:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80103e4a:	8b 40 24             	mov    0x24(%eax),%eax
80103e4d:	85 c0                	test   %eax,%eax
80103e4f:	74 15                	je     80103e66 <pipewrite+0x4d>
        release(&p->lock);
80103e51:	8b 45 08             	mov    0x8(%ebp),%eax
80103e54:	89 04 24             	mov    %eax,(%esp)
80103e57:	e8 f6 12 00 00       	call   80105152 <release>
        return -1;
80103e5c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103e61:	e9 9d 00 00 00       	jmp    80103f03 <pipewrite+0xea>
      }
      wakeup(&p->nread);
80103e66:	8b 45 08             	mov    0x8(%ebp),%eax
80103e69:	05 34 02 00 00       	add    $0x234,%eax
80103e6e:	89 04 24             	mov    %eax,(%esp)
80103e71:	e8 37 10 00 00       	call   80104ead <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
80103e76:	8b 45 08             	mov    0x8(%ebp),%eax
80103e79:	8b 55 08             	mov    0x8(%ebp),%edx
80103e7c:	81 c2 38 02 00 00    	add    $0x238,%edx
80103e82:	89 44 24 04          	mov    %eax,0x4(%esp)
80103e86:	89 14 24             	mov    %edx,(%esp)
80103e89:	e8 bc 0e 00 00       	call   80104d4a <sleep>
80103e8e:	eb 01                	jmp    80103e91 <pipewrite+0x78>
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80103e90:	90                   	nop
80103e91:	8b 45 08             	mov    0x8(%ebp),%eax
80103e94:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
80103e9a:	8b 45 08             	mov    0x8(%ebp),%eax
80103e9d:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80103ea3:	05 00 02 00 00       	add    $0x200,%eax
80103ea8:	39 c2                	cmp    %eax,%edx
80103eaa:	74 8b                	je     80103e37 <pipewrite+0x1e>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
80103eac:	8b 45 08             	mov    0x8(%ebp),%eax
80103eaf:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80103eb5:	89 c3                	mov    %eax,%ebx
80103eb7:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
80103ebd:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103ec0:	03 55 0c             	add    0xc(%ebp),%edx
80103ec3:	0f b6 0a             	movzbl (%edx),%ecx
80103ec6:	8b 55 08             	mov    0x8(%ebp),%edx
80103ec9:	88 4c 1a 34          	mov    %cl,0x34(%edx,%ebx,1)
80103ecd:	8d 50 01             	lea    0x1(%eax),%edx
80103ed0:	8b 45 08             	mov    0x8(%ebp),%eax
80103ed3:	89 90 38 02 00 00    	mov    %edx,0x238(%eax)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
80103ed9:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103edd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ee0:	3b 45 10             	cmp    0x10(%ebp),%eax
80103ee3:	7c ab                	jl     80103e90 <pipewrite+0x77>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
80103ee5:	8b 45 08             	mov    0x8(%ebp),%eax
80103ee8:	05 34 02 00 00       	add    $0x234,%eax
80103eed:	89 04 24             	mov    %eax,(%esp)
80103ef0:	e8 b8 0f 00 00       	call   80104ead <wakeup>
  release(&p->lock);
80103ef5:	8b 45 08             	mov    0x8(%ebp),%eax
80103ef8:	89 04 24             	mov    %eax,(%esp)
80103efb:	e8 52 12 00 00       	call   80105152 <release>
  return n;
80103f00:	8b 45 10             	mov    0x10(%ebp),%eax
}
80103f03:	83 c4 24             	add    $0x24,%esp
80103f06:	5b                   	pop    %ebx
80103f07:	5d                   	pop    %ebp
80103f08:	c3                   	ret    

80103f09 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
80103f09:	55                   	push   %ebp
80103f0a:	89 e5                	mov    %esp,%ebp
80103f0c:	53                   	push   %ebx
80103f0d:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80103f10:	8b 45 08             	mov    0x8(%ebp),%eax
80103f13:	89 04 24             	mov    %eax,(%esp)
80103f16:	e8 9c 11 00 00       	call   801050b7 <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80103f1b:	eb 3a                	jmp    80103f57 <piperead+0x4e>
    if(proc->killed){
80103f1d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80103f23:	8b 40 24             	mov    0x24(%eax),%eax
80103f26:	85 c0                	test   %eax,%eax
80103f28:	74 15                	je     80103f3f <piperead+0x36>
      release(&p->lock);
80103f2a:	8b 45 08             	mov    0x8(%ebp),%eax
80103f2d:	89 04 24             	mov    %eax,(%esp)
80103f30:	e8 1d 12 00 00       	call   80105152 <release>
      return -1;
80103f35:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103f3a:	e9 b6 00 00 00       	jmp    80103ff5 <piperead+0xec>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
80103f3f:	8b 45 08             	mov    0x8(%ebp),%eax
80103f42:	8b 55 08             	mov    0x8(%ebp),%edx
80103f45:	81 c2 34 02 00 00    	add    $0x234,%edx
80103f4b:	89 44 24 04          	mov    %eax,0x4(%esp)
80103f4f:	89 14 24             	mov    %edx,(%esp)
80103f52:	e8 f3 0d 00 00       	call   80104d4a <sleep>
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80103f57:	8b 45 08             	mov    0x8(%ebp),%eax
80103f5a:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80103f60:	8b 45 08             	mov    0x8(%ebp),%eax
80103f63:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80103f69:	39 c2                	cmp    %eax,%edx
80103f6b:	75 0d                	jne    80103f7a <piperead+0x71>
80103f6d:	8b 45 08             	mov    0x8(%ebp),%eax
80103f70:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80103f76:	85 c0                	test   %eax,%eax
80103f78:	75 a3                	jne    80103f1d <piperead+0x14>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80103f7a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103f81:	eb 49                	jmp    80103fcc <piperead+0xc3>
    if(p->nread == p->nwrite)
80103f83:	8b 45 08             	mov    0x8(%ebp),%eax
80103f86:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80103f8c:	8b 45 08             	mov    0x8(%ebp),%eax
80103f8f:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80103f95:	39 c2                	cmp    %eax,%edx
80103f97:	74 3d                	je     80103fd6 <piperead+0xcd>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
80103f99:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f9c:	89 c2                	mov    %eax,%edx
80103f9e:	03 55 0c             	add    0xc(%ebp),%edx
80103fa1:	8b 45 08             	mov    0x8(%ebp),%eax
80103fa4:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80103faa:	89 c3                	mov    %eax,%ebx
80103fac:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
80103fb2:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103fb5:	0f b6 4c 19 34       	movzbl 0x34(%ecx,%ebx,1),%ecx
80103fba:	88 0a                	mov    %cl,(%edx)
80103fbc:	8d 50 01             	lea    0x1(%eax),%edx
80103fbf:	8b 45 08             	mov    0x8(%ebp),%eax
80103fc2:	89 90 34 02 00 00    	mov    %edx,0x234(%eax)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80103fc8:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103fcc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103fcf:	3b 45 10             	cmp    0x10(%ebp),%eax
80103fd2:	7c af                	jl     80103f83 <piperead+0x7a>
80103fd4:	eb 01                	jmp    80103fd7 <piperead+0xce>
    if(p->nread == p->nwrite)
      break;
80103fd6:	90                   	nop
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
80103fd7:	8b 45 08             	mov    0x8(%ebp),%eax
80103fda:	05 38 02 00 00       	add    $0x238,%eax
80103fdf:	89 04 24             	mov    %eax,(%esp)
80103fe2:	e8 c6 0e 00 00       	call   80104ead <wakeup>
  release(&p->lock);
80103fe7:	8b 45 08             	mov    0x8(%ebp),%eax
80103fea:	89 04 24             	mov    %eax,(%esp)
80103fed:	e8 60 11 00 00       	call   80105152 <release>
  return i;
80103ff2:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80103ff5:	83 c4 24             	add    $0x24,%esp
80103ff8:	5b                   	pop    %ebx
80103ff9:	5d                   	pop    %ebp
80103ffa:	c3                   	ret    
	...

80103ffc <p2v>:
80103ffc:	55                   	push   %ebp
80103ffd:	89 e5                	mov    %esp,%ebp
80103fff:	8b 45 08             	mov    0x8(%ebp),%eax
80104002:	05 00 00 00 80       	add    $0x80000000,%eax
80104007:	5d                   	pop    %ebp
80104008:	c3                   	ret    

80104009 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80104009:	55                   	push   %ebp
8010400a:	89 e5                	mov    %esp,%ebp
8010400c:	53                   	push   %ebx
8010400d:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80104010:	9c                   	pushf  
80104011:	5b                   	pop    %ebx
80104012:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80104015:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80104018:	83 c4 10             	add    $0x10,%esp
8010401b:	5b                   	pop    %ebx
8010401c:	5d                   	pop    %ebp
8010401d:	c3                   	ret    

8010401e <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
8010401e:	55                   	push   %ebp
8010401f:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80104021:	fb                   	sti    
}
80104022:	5d                   	pop    %ebp
80104023:	c3                   	ret    

80104024 <pinit>:

static void wakeup1(void *chan);

void
pinit(void)
{
80104024:	55                   	push   %ebp
80104025:	89 e5                	mov    %esp,%ebp
80104027:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
8010402a:	c7 44 24 04 19 8b 10 	movl   $0x80108b19,0x4(%esp)
80104031:	80 
80104032:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104039:	e8 58 10 00 00       	call   80105096 <initlock>
}
8010403e:	c9                   	leave  
8010403f:	c3                   	ret    

80104040 <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
80104040:	55                   	push   %ebp
80104041:	89 e5                	mov    %esp,%ebp
80104043:	83 ec 38             	sub    $0x38,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
80104046:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
8010404d:	e8 65 10 00 00       	call   801050b7 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104052:	c7 45 f4 54 ff 10 80 	movl   $0x8010ff54,-0xc(%ebp)
80104059:	eb 11                	jmp    8010406c <allocproc+0x2c>
    if(p->state == UNUSED)
8010405b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010405e:	8b 40 0c             	mov    0xc(%eax),%eax
80104061:	85 c0                	test   %eax,%eax
80104063:	74 26                	je     8010408b <allocproc+0x4b>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104065:	81 45 f4 8c 00 00 00 	addl   $0x8c,-0xc(%ebp)
8010406c:	81 7d f4 54 22 11 80 	cmpl   $0x80112254,-0xc(%ebp)
80104073:	72 e6                	jb     8010405b <allocproc+0x1b>
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
80104075:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
8010407c:	e8 d1 10 00 00       	call   80105152 <release>
  return 0;
80104081:	b8 00 00 00 00       	mov    $0x0,%eax
80104086:	e9 5a 01 00 00       	jmp    801041e5 <allocproc+0x1a5>
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
    if(p->state == UNUSED)
      goto found;
8010408b:	90                   	nop
  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
8010408c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010408f:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
  p->pid = nextpid++;
80104096:	a1 04 b0 10 80       	mov    0x8010b004,%eax
8010409b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010409e:	89 42 10             	mov    %eax,0x10(%edx)
801040a1:	83 c0 01             	add    $0x1,%eax
801040a4:	a3 04 b0 10 80       	mov    %eax,0x8010b004
  release(&ptable.lock);
801040a9:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
801040b0:	e8 9d 10 00 00       	call   80105152 <release>

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
801040b5:	e8 51 ea ff ff       	call   80102b0b <kalloc>
801040ba:	8b 55 f4             	mov    -0xc(%ebp),%edx
801040bd:	89 42 08             	mov    %eax,0x8(%edx)
801040c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801040c3:	8b 40 08             	mov    0x8(%eax),%eax
801040c6:	85 c0                	test   %eax,%eax
801040c8:	75 14                	jne    801040de <allocproc+0x9e>
    p->state = UNUSED;
801040ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
801040cd:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return 0;
801040d4:	b8 00 00 00 00       	mov    $0x0,%eax
801040d9:	e9 07 01 00 00       	jmp    801041e5 <allocproc+0x1a5>
  }
  sp = p->kstack + KSTACKSIZE;
801040de:	8b 45 f4             	mov    -0xc(%ebp),%eax
801040e1:	8b 40 08             	mov    0x8(%eax),%eax
801040e4:	05 00 10 00 00       	add    $0x1000,%eax
801040e9:	89 45 f0             	mov    %eax,-0x10(%ebp)
  
  // Leave room for trap frame.
  sp -= sizeof *p->tf;
801040ec:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
  p->tf = (struct trapframe*)sp;
801040f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801040f3:	8b 55 f0             	mov    -0x10(%ebp),%edx
801040f6:	89 50 18             	mov    %edx,0x18(%eax)
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
801040f9:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
  *(uint*)sp = (uint)trapret;
801040fd:	ba 00 69 10 80       	mov    $0x80106900,%edx
80104102:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104105:	89 10                	mov    %edx,(%eax)

  sp -= sizeof *p->context;
80104107:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
  p->context = (struct context*)sp;
8010410b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010410e:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104111:	89 50 1c             	mov    %edx,0x1c(%eax)
  memset(p->context, 0, sizeof *p->context);
80104114:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104117:	8b 40 1c             	mov    0x1c(%eax),%eax
8010411a:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80104121:	00 
80104122:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104129:	00 
8010412a:	89 04 24             	mov    %eax,(%esp)
8010412d:	e8 0c 12 00 00       	call   8010533e <memset>
  p->context->eip = (uint)forkret;
80104132:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104135:	8b 40 1c             	mov    0x1c(%eax),%eax
80104138:	ba 1e 4d 10 80       	mov    $0x80104d1e,%edx
8010413d:	89 50 10             	mov    %edx,0x10(%eax)
  int i = 0;
80104140:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  char name[8];
  name[2] = '.'; name[3] = 's'; name[4] = 'w'; name[5] = 'a'; name[6] = 'p'; name[7] = 0;
80104147:	c6 45 e6 2e          	movb   $0x2e,-0x1a(%ebp)
8010414b:	c6 45 e7 73          	movb   $0x73,-0x19(%ebp)
8010414f:	c6 45 e8 77          	movb   $0x77,-0x18(%ebp)
80104153:	c6 45 e9 61          	movb   $0x61,-0x17(%ebp)
80104157:	c6 45 ea 70          	movb   $0x70,-0x16(%ebp)
8010415b:	c6 45 eb 00          	movb   $0x0,-0x15(%ebp)
  name[1] = (char)(((int)'0')+p->pid % 10);
8010415f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104162:	8b 48 10             	mov    0x10(%eax),%ecx
80104165:	ba 67 66 66 66       	mov    $0x66666667,%edx
8010416a:	89 c8                	mov    %ecx,%eax
8010416c:	f7 ea                	imul   %edx
8010416e:	c1 fa 02             	sar    $0x2,%edx
80104171:	89 c8                	mov    %ecx,%eax
80104173:	c1 f8 1f             	sar    $0x1f,%eax
80104176:	29 c2                	sub    %eax,%edx
80104178:	89 d0                	mov    %edx,%eax
8010417a:	c1 e0 02             	shl    $0x2,%eax
8010417d:	01 d0                	add    %edx,%eax
8010417f:	01 c0                	add    %eax,%eax
80104181:	89 ca                	mov    %ecx,%edx
80104183:	29 c2                	sub    %eax,%edx
80104185:	89 d0                	mov    %edx,%eax
80104187:	83 c0 30             	add    $0x30,%eax
8010418a:	88 45 e5             	mov    %al,-0x1b(%ebp)
  if((i=p->pid/10) == 0)
8010418d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104190:	8b 48 10             	mov    0x10(%eax),%ecx
80104193:	ba 67 66 66 66       	mov    $0x66666667,%edx
80104198:	89 c8                	mov    %ecx,%eax
8010419a:	f7 ea                	imul   %edx
8010419c:	c1 fa 02             	sar    $0x2,%edx
8010419f:	89 c8                	mov    %ecx,%eax
801041a1:	c1 f8 1f             	sar    $0x1f,%eax
801041a4:	89 d1                	mov    %edx,%ecx
801041a6:	29 c1                	sub    %eax,%ecx
801041a8:	89 c8                	mov    %ecx,%eax
801041aa:	89 45 ec             	mov    %eax,-0x14(%ebp)
801041ad:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801041b1:	75 06                	jne    801041b9 <allocproc+0x179>
    name[0] = '0';
801041b3:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
801041b7:	eb 09                	jmp    801041c2 <allocproc+0x182>
  else
    name[0] = (char)(((int)'0')+i);
801041b9:	8b 45 ec             	mov    -0x14(%ebp),%eax
801041bc:	83 c0 30             	add    $0x30,%eax
801041bf:	88 45 e4             	mov    %al,-0x1c(%ebp)
  //release(&ptable.lock);
  safestrcpy(p->swapFileName, name, sizeof(name));
801041c2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041c5:	8d 90 80 00 00 00    	lea    0x80(%eax),%edx
801041cb:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
801041d2:	00 
801041d3:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801041d6:	89 44 24 04          	mov    %eax,0x4(%esp)
801041da:	89 14 24             	mov    %edx,(%esp)
801041dd:	e8 8c 13 00 00       	call   8010556e <safestrcpy>
  return p;
801041e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801041e5:	c9                   	leave  
801041e6:	c3                   	ret    

801041e7 <createInternalProcess>:


void createInternalProcess(const char *name, void (*entrypoint)())
{
801041e7:	55                   	push   %ebp
801041e8:	89 e5                	mov    %esp,%ebp
801041ea:	83 ec 28             	sub    $0x28,%esp
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
801041ed:	e8 4e fe ff ff       	call   80104040 <allocproc>
801041f2:	89 45 f4             	mov    %eax,-0xc(%ebp)
801041f5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801041f9:	0f 84 f7 00 00 00    	je     801042f6 <createInternalProcess+0x10f>
    return;

  // Copy process state from p.
  if((np->pgdir = setupkvm(kalloc)) == 0)
801041ff:	c7 04 24 0b 2b 10 80 	movl   $0x80102b0b,(%esp)
80104206:	e8 f2 3d 00 00       	call   80107ffd <setupkvm>
8010420b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010420e:	89 42 04             	mov    %eax,0x4(%edx)
80104211:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104214:	8b 40 04             	mov    0x4(%eax),%eax
80104217:	85 c0                	test   %eax,%eax
80104219:	75 0c                	jne    80104227 <createInternalProcess+0x40>
      panic("inswapper: out of memory?");
8010421b:	c7 04 24 20 8b 10 80 	movl   $0x80108b20,(%esp)
80104222:	e8 16 c3 ff ff       	call   8010053d <panic>

  np->sz = PGSIZE;
80104227:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010422a:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  np->parent = initproc;
80104230:	8b 15 48 b6 10 80    	mov    0x8010b648,%edx
80104236:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104239:	89 50 14             	mov    %edx,0x14(%eax)
  memset(np->tf, 0, sizeof(*np->tf));
8010423c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010423f:	8b 40 18             	mov    0x18(%eax),%eax
80104242:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
80104249:	00 
8010424a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104251:	00 
80104252:	89 04 24             	mov    %eax,(%esp)
80104255:	e8 e4 10 00 00       	call   8010533e <memset>
  np->tf->cs = (SEG_KCODE << 3) | DPL_USER;
8010425a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010425d:	8b 40 18             	mov    0x18(%eax),%eax
80104260:	66 c7 40 3c 0b 00    	movw   $0xb,0x3c(%eax)
  np->tf->ds = (SEG_KDATA << 3) | DPL_USER;
80104266:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104269:	8b 40 18             	mov    0x18(%eax),%eax
8010426c:	66 c7 40 2c 13 00    	movw   $0x13,0x2c(%eax)
  np->tf->es = np->tf->ds;
80104272:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104275:	8b 40 18             	mov    0x18(%eax),%eax
80104278:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010427b:	8b 52 18             	mov    0x18(%edx),%edx
8010427e:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104282:	66 89 50 28          	mov    %dx,0x28(%eax)
  np->tf->ss = np->tf->ds;
80104286:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104289:	8b 40 18             	mov    0x18(%eax),%eax
8010428c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010428f:	8b 52 18             	mov    0x18(%edx),%edx
80104292:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104296:	66 89 50 48          	mov    %dx,0x48(%eax)
  np->tf->eflags = FL_IF;
8010429a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010429d:	8b 40 18             	mov    0x18(%eax),%eax
801042a0:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  //np->tf->esp = (uint)entrypoint+PGSIZE;
  //np->tf->eip = (uint)entrypoint;
  np->context->eip = (uint)entrypoint;
801042a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042aa:	8b 40 1c             	mov    0x1c(%eax),%eax
801042ad:	8b 55 0c             	mov    0xc(%ebp),%edx
801042b0:	89 50 10             	mov    %edx,0x10(%eax)

  inswapper = np;
801042b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042b6:	a3 4c b6 10 80       	mov    %eax,0x8010b64c
  np->cwd = namei("/");
801042bb:	c7 04 24 3a 8b 10 80 	movl   $0x80108b3a,(%esp)
801042c2:	e8 43 e1 ff ff       	call   8010240a <namei>
801042c7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801042ca:	89 42 68             	mov    %eax,0x68(%edx)
  safestrcpy(np->name, name, sizeof(name));
801042cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042d0:	8d 50 6c             	lea    0x6c(%eax),%edx
801042d3:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
801042da:	00 
801042db:	8b 45 08             	mov    0x8(%ebp),%eax
801042de:	89 44 24 04          	mov    %eax,0x4(%esp)
801042e2:	89 14 24             	mov    %edx,(%esp)
801042e5:	e8 84 12 00 00       	call   8010556e <safestrcpy>
  np->state = RUNNABLE;
801042ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042ed:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
801042f4:	eb 01                	jmp    801042f7 <createInternalProcess+0x110>
{
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
    return;
801042f6:	90                   	nop

  inswapper = np;
  np->cwd = namei("/");
  safestrcpy(np->name, name, sizeof(name));
  np->state = RUNNABLE;
}
801042f7:	c9                   	leave  
801042f8:	c3                   	ret    

801042f9 <swapIn>:

void swapIn()
{
801042f9:	55                   	push   %ebp
801042fa:	89 e5                	mov    %esp,%ebp
801042fc:	81 ec 28 10 00 00    	sub    $0x1028,%esp
  struct proc* t;
  //
  for(;;)
  {
    for(t = ptable.proc; t < &ptable.proc[NPROC]; t++)
80104302:	c7 45 f4 54 ff 10 80 	movl   $0x8010ff54,-0xc(%ebp)
80104309:	e9 26 01 00 00       	jmp    80104434 <swapIn+0x13b>
    {
      if(t->state != RUNNABLE_SUSPENDED)
8010430e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104311:	8b 40 0c             	mov    0xc(%eax),%eax
80104314:	83 f8 07             	cmp    $0x7,%eax
80104317:	0f 85 0f 01 00 00    	jne    8010442c <swapIn+0x133>
	continue;
      cprintf("swapin %s\n",t->swapFileName);
8010431d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104320:	83 e8 80             	sub    $0xffffff80,%eax
80104323:	89 44 24 04          	mov    %eax,0x4(%esp)
80104327:	c7 04 24 3c 8b 10 80 	movl   $0x80108b3c,(%esp)
8010432e:	e8 6e c0 ff ff       	call   801003a1 <cprintf>
      //open file pid.swap
      t->swap = fileopen(t->swapFileName,O_RDONLY);
80104333:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104336:	83 e8 80             	sub    $0xffffff80,%eax
80104339:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104340:	00 
80104341:	89 04 24             	mov    %eax,(%esp)
80104344:	e8 24 1d 00 00       	call   8010606d <fileopen>
80104349:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010434c:	89 42 7c             	mov    %eax,0x7c(%edx)
      char buf[PGSIZE];
      int read=0;
8010434f:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
      
      // allocate virtual memory
      if(!allocuvm(t->pgdir, 0, t->sz))
80104356:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104359:	8b 10                	mov    (%eax),%edx
8010435b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010435e:	8b 40 04             	mov    0x4(%eax),%eax
80104361:	89 54 24 08          	mov    %edx,0x8(%esp)
80104365:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010436c:	00 
8010436d:	89 04 24             	mov    %eax,(%esp)
80104370:	e8 5a 40 00 00       	call   801083cf <allocuvm>
80104375:	85 c0                	test   %eax,%eax
80104377:	75 11                	jne    8010438a <swapIn+0x91>
      {
	cprintf("allocuvm failed\n");
80104379:	c7 04 24 47 8b 10 80 	movl   $0x80108b47,(%esp)
80104380:	e8 1c c0 ff ff       	call   801003a1 <cprintf>
	break;
80104385:	e9 b7 00 00 00       	jmp    80104441 <swapIn+0x148>
      }
      
      uint a = 0;
8010438a:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
      for(; a < t->sz; a += PGSIZE)
80104391:	eb 68                	jmp    801043fb <swapIn+0x102>
      {
	if((read = fileread(t->swap, buf, PGSIZE)) > 0)
80104393:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104396:	8b 40 7c             	mov    0x7c(%eax),%eax
80104399:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801043a0:	00 
801043a1:	8d 95 ec ef ff ff    	lea    -0x1014(%ebp),%edx
801043a7:	89 54 24 04          	mov    %edx,0x4(%esp)
801043ab:	89 04 24             	mov    %eax,(%esp)
801043ae:	e8 36 cd ff ff       	call   801010e9 <fileread>
801043b3:	89 45 ec             	mov    %eax,-0x14(%ebp)
801043b6:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801043ba:	7e 38                	jle    801043f4 <swapIn+0xfb>
	{
	  if(copyout(t->pgdir,a, buf, read) < 0)
801043bc:	8b 55 ec             	mov    -0x14(%ebp),%edx
801043bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043c2:	8b 40 04             	mov    0x4(%eax),%eax
801043c5:	89 54 24 0c          	mov    %edx,0xc(%esp)
801043c9:	8d 95 ec ef ff ff    	lea    -0x1014(%ebp),%edx
801043cf:	89 54 24 08          	mov    %edx,0x8(%esp)
801043d3:	8b 55 f0             	mov    -0x10(%ebp),%edx
801043d6:	89 54 24 04          	mov    %edx,0x4(%esp)
801043da:	89 04 24             	mov    %eax,(%esp)
801043dd:	e8 c5 43 00 00       	call   801087a7 <copyout>
801043e2:	85 c0                	test   %eax,%eax
801043e4:	79 0e                	jns    801043f4 <swapIn+0xfb>
	  {
	    cprintf("copyout failed\n");
801043e6:	c7 04 24 58 8b 10 80 	movl   $0x80108b58,(%esp)
801043ed:	e8 af bf ff ff       	call   801003a1 <cprintf>
	    break;
801043f2:	eb 11                	jmp    80104405 <swapIn+0x10c>
	cprintf("allocuvm failed\n");
	break;
      }
      
      uint a = 0;
      for(; a < t->sz; a += PGSIZE)
801043f4:	81 45 f0 00 10 00 00 	addl   $0x1000,-0x10(%ebp)
801043fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043fe:	8b 00                	mov    (%eax),%eax
80104400:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80104403:	77 8e                	ja     80104393 <swapIn+0x9a>
	    cprintf("copyout failed\n");
	    break;
	  }
	}
      }
      t->isSwapped = 0;
80104405:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104408:	c7 80 88 00 00 00 00 	movl   $0x0,0x88(%eax)
8010440f:	00 00 00 
      fileclose(t->swap);
80104412:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104415:	8b 40 7c             	mov    0x7c(%eax),%eax
80104418:	89 04 24             	mov    %eax,(%esp)
8010441b:	e8 a4 cb ff ff       	call   80100fc4 <fileclose>
      t->state = RUNNABLE;
80104420:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104423:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
8010442a:	eb 01                	jmp    8010442d <swapIn+0x134>
  for(;;)
  {
    for(t = ptable.proc; t < &ptable.proc[NPROC]; t++)
    {
      if(t->state != RUNNABLE_SUSPENDED)
	continue;
8010442c:	90                   	nop
{
  struct proc* t;
  //
  for(;;)
  {
    for(t = ptable.proc; t < &ptable.proc[NPROC]; t++)
8010442d:	81 45 f4 8c 00 00 00 	addl   $0x8c,-0xc(%ebp)
80104434:	81 7d f4 54 22 11 80 	cmpl   $0x80112254,-0xc(%ebp)
8010443b:	0f 82 cd fe ff ff    	jb     8010430e <swapIn+0x15>
      
      //release(&ptable.lock);
      // delete fild pid.swap
    }
    
    proc->state = SLEEPING;
80104441:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104447:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
    sched();
8010444e:	e8 e7 07 00 00       	call   80104c3a <sched>
  }
80104453:	e9 aa fe ff ff       	jmp    80104302 <swapIn+0x9>

80104458 <swapOut>:
}

void
swapOut()
{
80104458:	55                   	push   %ebp
80104459:	89 e5                	mov    %esp,%ebp
8010445b:	53                   	push   %ebx
8010445c:	83 ec 24             	sub    $0x24,%esp
    proc->swap = fileopen(proc->swapFileName,(O_CREATE | O_RDWR));
8010445f:	65 8b 1d 04 00 00 00 	mov    %gs:0x4,%ebx
80104466:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010446c:	83 e8 80             	sub    $0xffffff80,%eax
8010446f:	c7 44 24 04 02 02 00 	movl   $0x202,0x4(%esp)
80104476:	00 
80104477:	89 04 24             	mov    %eax,(%esp)
8010447a:	e8 ee 1b 00 00       	call   8010606d <fileopen>
8010447f:	89 43 7c             	mov    %eax,0x7c(%ebx)
    pte_t *pte;
    uint pa, j;
    for(j = 0; j < proc->sz; j += PGSIZE)
80104482:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104489:	e9 9a 00 00 00       	jmp    80104528 <swapOut+0xd0>
    {
      if((pte = walkpgdir(proc->pgdir, (void *) j, 0)) == 0)
8010448e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104491:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104497:	8b 40 04             	mov    0x4(%eax),%eax
8010449a:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801044a1:	00 
801044a2:	89 54 24 04          	mov    %edx,0x4(%esp)
801044a6:	89 04 24             	mov    %eax,(%esp)
801044a9:	e8 25 3a 00 00       	call   80107ed3 <walkpgdir>
801044ae:	89 45 f0             	mov    %eax,-0x10(%ebp)
801044b1:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801044b5:	75 0c                	jne    801044c3 <swapOut+0x6b>
	panic("walkpgdir: pte should exist");
801044b7:	c7 04 24 68 8b 10 80 	movl   $0x80108b68,(%esp)
801044be:	e8 7a c0 ff ff       	call   8010053d <panic>
      if(!(*pte & PTE_P))
801044c3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801044c6:	8b 00                	mov    (%eax),%eax
801044c8:	83 e0 01             	and    $0x1,%eax
801044cb:	85 c0                	test   %eax,%eax
801044cd:	75 0c                	jne    801044db <swapOut+0x83>
	panic("walkpgdir: page not present");
801044cf:	c7 04 24 84 8b 10 80 	movl   $0x80108b84,(%esp)
801044d6:	e8 62 c0 ff ff       	call   8010053d <panic>
      pa = PTE_ADDR(*pte);
801044db:	8b 45 f0             	mov    -0x10(%ebp),%eax
801044de:	8b 00                	mov    (%eax),%eax
801044e0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801044e5:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if(filewrite(proc->swap, (char*)p2v(pa), PGSIZE) < 0)
801044e8:	8b 45 ec             	mov    -0x14(%ebp),%eax
801044eb:	89 04 24             	mov    %eax,(%esp)
801044ee:	e8 09 fb ff ff       	call   80103ffc <p2v>
801044f3:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801044fa:	8b 52 7c             	mov    0x7c(%edx),%edx
801044fd:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80104504:	00 
80104505:	89 44 24 04          	mov    %eax,0x4(%esp)
80104509:	89 14 24             	mov    %edx,(%esp)
8010450c:	e8 94 cc ff ff       	call   801011a5 <filewrite>
80104511:	85 c0                	test   %eax,%eax
80104513:	79 0c                	jns    80104521 <swapOut+0xc9>
	panic("filewrite failed");
80104515:	c7 04 24 a0 8b 10 80 	movl   $0x80108ba0,(%esp)
8010451c:	e8 1c c0 ff ff       	call   8010053d <panic>
swapOut()
{
    proc->swap = fileopen(proc->swapFileName,(O_CREATE | O_RDWR));
    pte_t *pte;
    uint pa, j;
    for(j = 0; j < proc->sz; j += PGSIZE)
80104521:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80104528:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010452e:	8b 00                	mov    (%eax),%eax
80104530:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104533:	0f 87 55 ff ff ff    	ja     8010448e <swapOut+0x36>
	panic("walkpgdir: page not present");
      pa = PTE_ADDR(*pte);
      if(filewrite(proc->swap, (char*)p2v(pa), PGSIZE) < 0)
	panic("filewrite failed");
    }
    proc->state = SLEEPING_SUSPENDED;
80104539:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010453f:	c7 40 0c 06 00 00 00 	movl   $0x6,0xc(%eax)
    proc->isSwapped = 1;
80104546:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010454c:	c7 80 88 00 00 00 01 	movl   $0x1,0x88(%eax)
80104553:	00 00 00 
}
80104556:	83 c4 24             	add    $0x24,%esp
80104559:	5b                   	pop    %ebx
8010455a:	5d                   	pop    %ebp
8010455b:	c3                   	ret    

8010455c <userinit>:

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
8010455c:	55                   	push   %ebp
8010455d:	89 e5                	mov    %esp,%ebp
8010455f:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
80104562:	e8 d9 fa ff ff       	call   80104040 <allocproc>
80104567:	89 45 f4             	mov    %eax,-0xc(%ebp)
  initproc = p;
8010456a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010456d:	a3 48 b6 10 80       	mov    %eax,0x8010b648
  if((p->pgdir = setupkvm(kalloc)) == 0)
80104572:	c7 04 24 0b 2b 10 80 	movl   $0x80102b0b,(%esp)
80104579:	e8 7f 3a 00 00       	call   80107ffd <setupkvm>
8010457e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104581:	89 42 04             	mov    %eax,0x4(%edx)
80104584:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104587:	8b 40 04             	mov    0x4(%eax),%eax
8010458a:	85 c0                	test   %eax,%eax
8010458c:	75 0c                	jne    8010459a <userinit+0x3e>
    panic("userinit: out of memory?");
8010458e:	c7 04 24 b1 8b 10 80 	movl   $0x80108bb1,(%esp)
80104595:	e8 a3 bf ff ff       	call   8010053d <panic>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
8010459a:	ba 2c 00 00 00       	mov    $0x2c,%edx
8010459f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045a2:	8b 40 04             	mov    0x4(%eax),%eax
801045a5:	89 54 24 08          	mov    %edx,0x8(%esp)
801045a9:	c7 44 24 04 e0 b4 10 	movl   $0x8010b4e0,0x4(%esp)
801045b0:	80 
801045b1:	89 04 24             	mov    %eax,(%esp)
801045b4:	e8 9c 3c 00 00       	call   80108255 <inituvm>
  p->sz = PGSIZE;
801045b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045bc:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  memset(p->tf, 0, sizeof(*p->tf));
801045c2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045c5:	8b 40 18             	mov    0x18(%eax),%eax
801045c8:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
801045cf:	00 
801045d0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801045d7:	00 
801045d8:	89 04 24             	mov    %eax,(%esp)
801045db:	e8 5e 0d 00 00       	call   8010533e <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
801045e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045e3:	8b 40 18             	mov    0x18(%eax),%eax
801045e6:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
801045ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045ef:	8b 40 18             	mov    0x18(%eax),%eax
801045f2:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
  p->tf->es = p->tf->ds;
801045f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045fb:	8b 40 18             	mov    0x18(%eax),%eax
801045fe:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104601:	8b 52 18             	mov    0x18(%edx),%edx
80104604:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104608:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
8010460c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010460f:	8b 40 18             	mov    0x18(%eax),%eax
80104612:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104615:	8b 52 18             	mov    0x18(%edx),%edx
80104618:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
8010461c:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
80104620:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104623:	8b 40 18             	mov    0x18(%eax),%eax
80104626:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
8010462d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104630:	8b 40 18             	mov    0x18(%eax),%eax
80104633:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
8010463a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010463d:	8b 40 18             	mov    0x18(%eax),%eax
80104640:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
80104647:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010464a:	83 c0 6c             	add    $0x6c,%eax
8010464d:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104654:	00 
80104655:	c7 44 24 04 ca 8b 10 	movl   $0x80108bca,0x4(%esp)
8010465c:	80 
8010465d:	89 04 24             	mov    %eax,(%esp)
80104660:	e8 09 0f 00 00       	call   8010556e <safestrcpy>
  p->cwd = namei("/");
80104665:	c7 04 24 3a 8b 10 80 	movl   $0x80108b3a,(%esp)
8010466c:	e8 99 dd ff ff       	call   8010240a <namei>
80104671:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104674:	89 42 68             	mov    %eax,0x68(%edx)

  p->state = RUNNABLE;
80104677:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010467a:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)

  createInternalProcess("inswapper", swapIn);
80104681:	c7 44 24 04 f9 42 10 	movl   $0x801042f9,0x4(%esp)
80104688:	80 
80104689:	c7 04 24 d3 8b 10 80 	movl   $0x80108bd3,(%esp)
80104690:	e8 52 fb ff ff       	call   801041e7 <createInternalProcess>
}
80104695:	c9                   	leave  
80104696:	c3                   	ret    

80104697 <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
80104697:	55                   	push   %ebp
80104698:	89 e5                	mov    %esp,%ebp
8010469a:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  
  sz = proc->sz;
8010469d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801046a3:	8b 00                	mov    (%eax),%eax
801046a5:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
801046a8:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801046ac:	7e 34                	jle    801046e2 <growproc+0x4b>
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
801046ae:	8b 45 08             	mov    0x8(%ebp),%eax
801046b1:	89 c2                	mov    %eax,%edx
801046b3:	03 55 f4             	add    -0xc(%ebp),%edx
801046b6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801046bc:	8b 40 04             	mov    0x4(%eax),%eax
801046bf:	89 54 24 08          	mov    %edx,0x8(%esp)
801046c3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801046c6:	89 54 24 04          	mov    %edx,0x4(%esp)
801046ca:	89 04 24             	mov    %eax,(%esp)
801046cd:	e8 fd 3c 00 00       	call   801083cf <allocuvm>
801046d2:	89 45 f4             	mov    %eax,-0xc(%ebp)
801046d5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801046d9:	75 41                	jne    8010471c <growproc+0x85>
      return -1;
801046db:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801046e0:	eb 58                	jmp    8010473a <growproc+0xa3>
  } else if(n < 0){
801046e2:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801046e6:	79 34                	jns    8010471c <growproc+0x85>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
801046e8:	8b 45 08             	mov    0x8(%ebp),%eax
801046eb:	89 c2                	mov    %eax,%edx
801046ed:	03 55 f4             	add    -0xc(%ebp),%edx
801046f0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801046f6:	8b 40 04             	mov    0x4(%eax),%eax
801046f9:	89 54 24 08          	mov    %edx,0x8(%esp)
801046fd:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104700:	89 54 24 04          	mov    %edx,0x4(%esp)
80104704:	89 04 24             	mov    %eax,(%esp)
80104707:	e8 9d 3d 00 00       	call   801084a9 <deallocuvm>
8010470c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010470f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104713:	75 07                	jne    8010471c <growproc+0x85>
      return -1;
80104715:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010471a:	eb 1e                	jmp    8010473a <growproc+0xa3>
  }
  proc->sz = sz;
8010471c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104722:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104725:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
80104727:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010472d:	89 04 24             	mov    %eax,(%esp)
80104730:	e8 b9 39 00 00       	call   801080ee <switchuvm>
  return 0;
80104735:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010473a:	c9                   	leave  
8010473b:	c3                   	ret    

8010473c <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
8010473c:	55                   	push   %ebp
8010473d:	89 e5                	mov    %esp,%ebp
8010473f:	57                   	push   %edi
80104740:	56                   	push   %esi
80104741:	53                   	push   %ebx
80104742:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
80104745:	e8 f6 f8 ff ff       	call   80104040 <allocproc>
8010474a:	89 45 e0             	mov    %eax,-0x20(%ebp)
8010474d:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80104751:	75 0a                	jne    8010475d <fork+0x21>
    return -1;
80104753:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104758:	e9 3a 01 00 00       	jmp    80104897 <fork+0x15b>
  
  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
8010475d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104763:	8b 10                	mov    (%eax),%edx
80104765:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010476b:	8b 40 04             	mov    0x4(%eax),%eax
8010476e:	89 54 24 04          	mov    %edx,0x4(%esp)
80104772:	89 04 24             	mov    %eax,(%esp)
80104775:	e8 bf 3e 00 00       	call   80108639 <copyuvm>
8010477a:	8b 55 e0             	mov    -0x20(%ebp),%edx
8010477d:	89 42 04             	mov    %eax,0x4(%edx)
80104780:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104783:	8b 40 04             	mov    0x4(%eax),%eax
80104786:	85 c0                	test   %eax,%eax
80104788:	75 2c                	jne    801047b6 <fork+0x7a>
    kfree(np->kstack);
8010478a:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010478d:	8b 40 08             	mov    0x8(%eax),%eax
80104790:	89 04 24             	mov    %eax,(%esp)
80104793:	e8 da e2 ff ff       	call   80102a72 <kfree>
    np->kstack = 0;
80104798:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010479b:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
801047a2:	8b 45 e0             	mov    -0x20(%ebp),%eax
801047a5:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
801047ac:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801047b1:	e9 e1 00 00 00       	jmp    80104897 <fork+0x15b>
  }
  np->sz = proc->sz;
801047b6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047bc:	8b 10                	mov    (%eax),%edx
801047be:	8b 45 e0             	mov    -0x20(%ebp),%eax
801047c1:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
801047c3:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801047ca:	8b 45 e0             	mov    -0x20(%ebp),%eax
801047cd:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *proc->tf;
801047d0:	8b 45 e0             	mov    -0x20(%ebp),%eax
801047d3:	8b 50 18             	mov    0x18(%eax),%edx
801047d6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047dc:	8b 40 18             	mov    0x18(%eax),%eax
801047df:	89 c3                	mov    %eax,%ebx
801047e1:	b8 13 00 00 00       	mov    $0x13,%eax
801047e6:	89 d7                	mov    %edx,%edi
801047e8:	89 de                	mov    %ebx,%esi
801047ea:	89 c1                	mov    %eax,%ecx
801047ec:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
801047ee:	8b 45 e0             	mov    -0x20(%ebp),%eax
801047f1:	8b 40 18             	mov    0x18(%eax),%eax
801047f4:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
801047fb:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80104802:	eb 3d                	jmp    80104841 <fork+0x105>
    if(proc->ofile[i])
80104804:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010480a:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010480d:	83 c2 08             	add    $0x8,%edx
80104810:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104814:	85 c0                	test   %eax,%eax
80104816:	74 25                	je     8010483d <fork+0x101>
      np->ofile[i] = filedup(proc->ofile[i]);
80104818:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010481e:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104821:	83 c2 08             	add    $0x8,%edx
80104824:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104828:	89 04 24             	mov    %eax,(%esp)
8010482b:	e8 4c c7 ff ff       	call   80100f7c <filedup>
80104830:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104833:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80104836:	83 c1 08             	add    $0x8,%ecx
80104839:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
8010483d:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80104841:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
80104845:	7e bd                	jle    80104804 <fork+0xc8>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
80104847:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010484d:	8b 40 68             	mov    0x68(%eax),%eax
80104850:	89 04 24             	mov    %eax,(%esp)
80104853:	e8 de cf ff ff       	call   80101836 <idup>
80104858:	8b 55 e0             	mov    -0x20(%ebp),%edx
8010485b:	89 42 68             	mov    %eax,0x68(%edx)
 
  pid = np->pid;
8010485e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104861:	8b 40 10             	mov    0x10(%eax),%eax
80104864:	89 45 dc             	mov    %eax,-0x24(%ebp)
  np->state = RUNNABLE;
80104867:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010486a:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  safestrcpy(np->name, proc->name, sizeof(proc->name));
80104871:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104877:	8d 50 6c             	lea    0x6c(%eax),%edx
8010487a:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010487d:	83 c0 6c             	add    $0x6c,%eax
80104880:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104887:	00 
80104888:	89 54 24 04          	mov    %edx,0x4(%esp)
8010488c:	89 04 24             	mov    %eax,(%esp)
8010488f:	e8 da 0c 00 00       	call   8010556e <safestrcpy>
  return pid;
80104894:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
80104897:	83 c4 2c             	add    $0x2c,%esp
8010489a:	5b                   	pop    %ebx
8010489b:	5e                   	pop    %esi
8010489c:	5f                   	pop    %edi
8010489d:	5d                   	pop    %ebp
8010489e:	c3                   	ret    

8010489f <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
8010489f:	55                   	push   %ebp
801048a0:	89 e5                	mov    %esp,%ebp
801048a2:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int fd;

  if(proc == initproc)
801048a5:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801048ac:	a1 48 b6 10 80       	mov    0x8010b648,%eax
801048b1:	39 c2                	cmp    %eax,%edx
801048b3:	75 0c                	jne    801048c1 <exit+0x22>
    panic("init exiting");
801048b5:	c7 04 24 dd 8b 10 80 	movl   $0x80108bdd,(%esp)
801048bc:	e8 7c bc ff ff       	call   8010053d <panic>

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
801048c1:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
801048c8:	eb 44                	jmp    8010490e <exit+0x6f>
    if(proc->ofile[fd]){
801048ca:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048d0:	8b 55 f0             	mov    -0x10(%ebp),%edx
801048d3:	83 c2 08             	add    $0x8,%edx
801048d6:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801048da:	85 c0                	test   %eax,%eax
801048dc:	74 2c                	je     8010490a <exit+0x6b>
      fileclose(proc->ofile[fd]);
801048de:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048e4:	8b 55 f0             	mov    -0x10(%ebp),%edx
801048e7:	83 c2 08             	add    $0x8,%edx
801048ea:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801048ee:	89 04 24             	mov    %eax,(%esp)
801048f1:	e8 ce c6 ff ff       	call   80100fc4 <fileclose>
      proc->ofile[fd] = 0;
801048f6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048fc:	8b 55 f0             	mov    -0x10(%ebp),%edx
801048ff:	83 c2 08             	add    $0x8,%edx
80104902:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80104909:	00 

  if(proc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
8010490a:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
8010490e:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
80104912:	7e b6                	jle    801048ca <exit+0x2b>
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  iput(proc->cwd);
80104914:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010491a:	8b 40 68             	mov    0x68(%eax),%eax
8010491d:	89 04 24             	mov    %eax,(%esp)
80104920:	e8 f6 d0 ff ff       	call   80101a1b <iput>
  proc->cwd = 0;
80104925:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010492b:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)

  acquire(&ptable.lock);
80104932:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104939:	e8 79 07 00 00       	call   801050b7 <acquire>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);
8010493e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104944:	8b 40 14             	mov    0x14(%eax),%eax
80104947:	89 04 24             	mov    %eax,(%esp)
8010494a:	e8 f1 04 00 00       	call   80104e40 <wakeup1>

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010494f:	c7 45 f4 54 ff 10 80 	movl   $0x8010ff54,-0xc(%ebp)
80104956:	eb 3b                	jmp    80104993 <exit+0xf4>
    if(p->parent == proc){
80104958:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010495b:	8b 50 14             	mov    0x14(%eax),%edx
8010495e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104964:	39 c2                	cmp    %eax,%edx
80104966:	75 24                	jne    8010498c <exit+0xed>
      p->parent = initproc;
80104968:	8b 15 48 b6 10 80    	mov    0x8010b648,%edx
8010496e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104971:	89 50 14             	mov    %edx,0x14(%eax)
      if(p->state == ZOMBIE)
80104974:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104977:	8b 40 0c             	mov    0xc(%eax),%eax
8010497a:	83 f8 05             	cmp    $0x5,%eax
8010497d:	75 0d                	jne    8010498c <exit+0xed>
        wakeup1(initproc);
8010497f:	a1 48 b6 10 80       	mov    0x8010b648,%eax
80104984:	89 04 24             	mov    %eax,(%esp)
80104987:	e8 b4 04 00 00       	call   80104e40 <wakeup1>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010498c:	81 45 f4 8c 00 00 00 	addl   $0x8c,-0xc(%ebp)
80104993:	81 7d f4 54 22 11 80 	cmpl   $0x80112254,-0xc(%ebp)
8010499a:	72 bc                	jb     80104958 <exit+0xb9>
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  proc->state = ZOMBIE;
8010499c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801049a2:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
  sched();
801049a9:	e8 8c 02 00 00       	call   80104c3a <sched>
  panic("zombie exit");
801049ae:	c7 04 24 ea 8b 10 80 	movl   $0x80108bea,(%esp)
801049b5:	e8 83 bb ff ff       	call   8010053d <panic>

801049ba <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
801049ba:	55                   	push   %ebp
801049bb:	89 e5                	mov    %esp,%ebp
801049bd:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
801049c0:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
801049c7:	e8 eb 06 00 00       	call   801050b7 <acquire>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
801049cc:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801049d3:	c7 45 f4 54 ff 10 80 	movl   $0x8010ff54,-0xc(%ebp)
801049da:	e9 9d 00 00 00       	jmp    80104a7c <wait+0xc2>
      if(p->parent != proc)
801049df:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049e2:	8b 50 14             	mov    0x14(%eax),%edx
801049e5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801049eb:	39 c2                	cmp    %eax,%edx
801049ed:	0f 85 81 00 00 00    	jne    80104a74 <wait+0xba>
        continue;
      havekids = 1;
801049f3:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
      if(p->state == ZOMBIE){
801049fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049fd:	8b 40 0c             	mov    0xc(%eax),%eax
80104a00:	83 f8 05             	cmp    $0x5,%eax
80104a03:	75 70                	jne    80104a75 <wait+0xbb>
        // Found one.
        pid = p->pid;
80104a05:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a08:	8b 40 10             	mov    0x10(%eax),%eax
80104a0b:	89 45 ec             	mov    %eax,-0x14(%ebp)
        kfree(p->kstack);
80104a0e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a11:	8b 40 08             	mov    0x8(%eax),%eax
80104a14:	89 04 24             	mov    %eax,(%esp)
80104a17:	e8 56 e0 ff ff       	call   80102a72 <kfree>
        p->kstack = 0;
80104a1c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a1f:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
        freevm(p->pgdir);
80104a26:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a29:	8b 40 04             	mov    0x4(%eax),%eax
80104a2c:	89 04 24             	mov    %eax,(%esp)
80104a2f:	e8 31 3b 00 00       	call   80108565 <freevm>
        p->state = UNUSED;
80104a34:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a37:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        p->pid = 0;
80104a3e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a41:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
        p->parent = 0;
80104a48:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a4b:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
        p->name[0] = 0;
80104a52:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a55:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)
        p->killed = 0;
80104a59:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a5c:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
        release(&ptable.lock);
80104a63:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104a6a:	e8 e3 06 00 00       	call   80105152 <release>
        return pid;
80104a6f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104a72:	eb 56                	jmp    80104aca <wait+0x110>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->parent != proc)
        continue;
80104a74:	90                   	nop

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104a75:	81 45 f4 8c 00 00 00 	addl   $0x8c,-0xc(%ebp)
80104a7c:	81 7d f4 54 22 11 80 	cmpl   $0x80112254,-0xc(%ebp)
80104a83:	0f 82 56 ff ff ff    	jb     801049df <wait+0x25>
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
80104a89:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80104a8d:	74 0d                	je     80104a9c <wait+0xe2>
80104a8f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104a95:	8b 40 24             	mov    0x24(%eax),%eax
80104a98:	85 c0                	test   %eax,%eax
80104a9a:	74 13                	je     80104aaf <wait+0xf5>
      release(&ptable.lock);
80104a9c:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104aa3:	e8 aa 06 00 00       	call   80105152 <release>
      return -1;
80104aa8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104aad:	eb 1b                	jmp    80104aca <wait+0x110>
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
80104aaf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ab5:	c7 44 24 04 20 ff 10 	movl   $0x8010ff20,0x4(%esp)
80104abc:	80 
80104abd:	89 04 24             	mov    %eax,(%esp)
80104ac0:	e8 85 02 00 00       	call   80104d4a <sleep>
  }
80104ac5:	e9 02 ff ff ff       	jmp    801049cc <wait+0x12>
}
80104aca:	c9                   	leave  
80104acb:	c3                   	ret    

80104acc <register_handler>:

void
register_handler(sighandler_t sighandler)
{
80104acc:	55                   	push   %ebp
80104acd:	89 e5                	mov    %esp,%ebp
80104acf:	83 ec 28             	sub    $0x28,%esp
  char* addr = uva2ka(proc->pgdir, (char*)proc->tf->esp);
80104ad2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ad8:	8b 40 18             	mov    0x18(%eax),%eax
80104adb:	8b 40 44             	mov    0x44(%eax),%eax
80104ade:	89 c2                	mov    %eax,%edx
80104ae0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ae6:	8b 40 04             	mov    0x4(%eax),%eax
80104ae9:	89 54 24 04          	mov    %edx,0x4(%esp)
80104aed:	89 04 24             	mov    %eax,(%esp)
80104af0:	e8 55 3c 00 00       	call   8010874a <uva2ka>
80104af5:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if ((proc->tf->esp & 0xFFF) == 0)
80104af8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104afe:	8b 40 18             	mov    0x18(%eax),%eax
80104b01:	8b 40 44             	mov    0x44(%eax),%eax
80104b04:	25 ff 0f 00 00       	and    $0xfff,%eax
80104b09:	85 c0                	test   %eax,%eax
80104b0b:	75 0c                	jne    80104b19 <register_handler+0x4d>
    panic("esp_offset == 0");
80104b0d:	c7 04 24 f6 8b 10 80 	movl   $0x80108bf6,(%esp)
80104b14:	e8 24 ba ff ff       	call   8010053d <panic>

    /* open a new frame */
  *(int*)(addr + ((proc->tf->esp - 4) & 0xFFF))
80104b19:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b1f:	8b 40 18             	mov    0x18(%eax),%eax
80104b22:	8b 40 44             	mov    0x44(%eax),%eax
80104b25:	83 e8 04             	sub    $0x4,%eax
80104b28:	25 ff 0f 00 00       	and    $0xfff,%eax
80104b2d:	03 45 f4             	add    -0xc(%ebp),%eax
          = proc->tf->eip;
80104b30:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104b37:	8b 52 18             	mov    0x18(%edx),%edx
80104b3a:	8b 52 38             	mov    0x38(%edx),%edx
80104b3d:	89 10                	mov    %edx,(%eax)
  proc->tf->esp -= 4;
80104b3f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b45:	8b 40 18             	mov    0x18(%eax),%eax
80104b48:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104b4f:	8b 52 18             	mov    0x18(%edx),%edx
80104b52:	8b 52 44             	mov    0x44(%edx),%edx
80104b55:	83 ea 04             	sub    $0x4,%edx
80104b58:	89 50 44             	mov    %edx,0x44(%eax)

    /* update eip */
  proc->tf->eip = (uint)sighandler;
80104b5b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b61:	8b 40 18             	mov    0x18(%eax),%eax
80104b64:	8b 55 08             	mov    0x8(%ebp),%edx
80104b67:	89 50 38             	mov    %edx,0x38(%eax)
}
80104b6a:	c9                   	leave  
80104b6b:	c3                   	ret    

80104b6c <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
80104b6c:	55                   	push   %ebp
80104b6d:	89 e5                	mov    %esp,%ebp
80104b6f:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  
  for(;;){
    // Enable interrupts on this processor.
    sti();
80104b72:	e8 a7 f4 ff ff       	call   8010401e <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
80104b77:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104b7e:	e8 34 05 00 00       	call   801050b7 <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104b83:	c7 45 f4 54 ff 10 80 	movl   $0x8010ff54,-0xc(%ebp)
80104b8a:	e9 8d 00 00 00       	jmp    80104c1c <scheduler+0xb0>
      if(p->state != RUNNABLE)
80104b8f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b92:	8b 40 0c             	mov    0xc(%eax),%eax
80104b95:	83 f8 03             	cmp    $0x3,%eax
80104b98:	75 7a                	jne    80104c14 <scheduler+0xa8>
        continue;
    
      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
80104b9a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b9d:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
      switchuvm(p);
80104ba3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ba6:	89 04 24             	mov    %eax,(%esp)
80104ba9:	e8 40 35 00 00       	call   801080ee <switchuvm>
      p->state = RUNNING;
80104bae:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104bb1:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      swtch(&cpu->scheduler, proc->context);
80104bb8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104bbe:	8b 40 1c             	mov    0x1c(%eax),%eax
80104bc1:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80104bc8:	83 c2 04             	add    $0x4,%edx
80104bcb:	89 44 24 04          	mov    %eax,0x4(%esp)
80104bcf:	89 14 24             	mov    %edx,(%esp)
80104bd2:	e8 0d 0a 00 00       	call   801055e4 <swtch>
      switchkvm();
80104bd7:	e8 f5 34 00 00       	call   801080d1 <switchkvm>
      
      if(proc && proc->isSwapped)
80104bdc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104be2:	85 c0                	test   %eax,%eax
80104be4:	74 21                	je     80104c07 <scheduler+0x9b>
80104be6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104bec:	8b 80 88 00 00 00    	mov    0x88(%eax),%eax
80104bf2:	85 c0                	test   %eax,%eax
80104bf4:	74 11                	je     80104c07 <scheduler+0x9b>
	freevm(proc->pgdir);
80104bf6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104bfc:	8b 40 04             	mov    0x4(%eax),%eax
80104bff:	89 04 24             	mov    %eax,(%esp)
80104c02:	e8 5e 39 00 00       	call   80108565 <freevm>
      
      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
80104c07:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80104c0e:	00 00 00 00 
80104c12:	eb 01                	jmp    80104c15 <scheduler+0xa9>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->state != RUNNABLE)
        continue;
80104c14:	90                   	nop
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104c15:	81 45 f4 8c 00 00 00 	addl   $0x8c,-0xc(%ebp)
80104c1c:	81 7d f4 54 22 11 80 	cmpl   $0x80112254,-0xc(%ebp)
80104c23:	0f 82 66 ff ff ff    	jb     80104b8f <scheduler+0x23>
      
      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
80104c29:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104c30:	e8 1d 05 00 00       	call   80105152 <release>

  }
80104c35:	e9 38 ff ff ff       	jmp    80104b72 <scheduler+0x6>

80104c3a <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
80104c3a:	55                   	push   %ebp
80104c3b:	89 e5                	mov    %esp,%ebp
80104c3d:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
80104c40:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104c47:	e8 c2 05 00 00       	call   8010520e <holding>
80104c4c:	85 c0                	test   %eax,%eax
80104c4e:	75 0c                	jne    80104c5c <sched+0x22>
    panic("sched ptable.lock");
80104c50:	c7 04 24 06 8c 10 80 	movl   $0x80108c06,(%esp)
80104c57:	e8 e1 b8 ff ff       	call   8010053d <panic>
  if(cpu->ncli != 1)
80104c5c:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104c62:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80104c68:	83 f8 01             	cmp    $0x1,%eax
80104c6b:	74 0c                	je     80104c79 <sched+0x3f>
    panic("sched locks");
80104c6d:	c7 04 24 18 8c 10 80 	movl   $0x80108c18,(%esp)
80104c74:	e8 c4 b8 ff ff       	call   8010053d <panic>
  if(proc->state == RUNNING)
80104c79:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c7f:	8b 40 0c             	mov    0xc(%eax),%eax
80104c82:	83 f8 04             	cmp    $0x4,%eax
80104c85:	75 0c                	jne    80104c93 <sched+0x59>
    panic("sched running");
80104c87:	c7 04 24 24 8c 10 80 	movl   $0x80108c24,(%esp)
80104c8e:	e8 aa b8 ff ff       	call   8010053d <panic>
  if(readeflags()&FL_IF)
80104c93:	e8 71 f3 ff ff       	call   80104009 <readeflags>
80104c98:	25 00 02 00 00       	and    $0x200,%eax
80104c9d:	85 c0                	test   %eax,%eax
80104c9f:	74 0c                	je     80104cad <sched+0x73>
    panic("sched interruptible");
80104ca1:	c7 04 24 32 8c 10 80 	movl   $0x80108c32,(%esp)
80104ca8:	e8 90 b8 ff ff       	call   8010053d <panic>
  intena = cpu->intena;
80104cad:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104cb3:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80104cb9:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->context, cpu->scheduler);
80104cbc:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104cc2:	8b 40 04             	mov    0x4(%eax),%eax
80104cc5:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104ccc:	83 c2 1c             	add    $0x1c,%edx
80104ccf:	89 44 24 04          	mov    %eax,0x4(%esp)
80104cd3:	89 14 24             	mov    %edx,(%esp)
80104cd6:	e8 09 09 00 00       	call   801055e4 <swtch>
  cpu->intena = intena;
80104cdb:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104ce1:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104ce4:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80104cea:	c9                   	leave  
80104ceb:	c3                   	ret    

80104cec <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
80104cec:	55                   	push   %ebp
80104ced:	89 e5                	mov    %esp,%ebp
80104cef:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
80104cf2:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104cf9:	e8 b9 03 00 00       	call   801050b7 <acquire>
  proc->state = RUNNABLE;
80104cfe:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d04:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
80104d0b:	e8 2a ff ff ff       	call   80104c3a <sched>
  release(&ptable.lock);
80104d10:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104d17:	e8 36 04 00 00       	call   80105152 <release>
}
80104d1c:	c9                   	leave  
80104d1d:	c3                   	ret    

80104d1e <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
80104d1e:	55                   	push   %ebp
80104d1f:	89 e5                	mov    %esp,%ebp
80104d21:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
80104d24:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104d2b:	e8 22 04 00 00       	call   80105152 <release>

  if (first) {
80104d30:	a1 24 b0 10 80       	mov    0x8010b024,%eax
80104d35:	85 c0                	test   %eax,%eax
80104d37:	74 0f                	je     80104d48 <forkret+0x2a>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
80104d39:	c7 05 24 b0 10 80 00 	movl   $0x0,0x8010b024
80104d40:	00 00 00 
    initlog();
80104d43:	e8 d4 e2 ff ff       	call   8010301c <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
80104d48:	c9                   	leave  
80104d49:	c3                   	ret    

80104d4a <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
80104d4a:	55                   	push   %ebp
80104d4b:	89 e5                	mov    %esp,%ebp
80104d4d:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
80104d50:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d56:	85 c0                	test   %eax,%eax
80104d58:	75 0c                	jne    80104d66 <sleep+0x1c>
    panic("sleep");
80104d5a:	c7 04 24 46 8c 10 80 	movl   $0x80108c46,(%esp)
80104d61:	e8 d7 b7 ff ff       	call   8010053d <panic>

  if(lk == 0)
80104d66:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80104d6a:	75 0c                	jne    80104d78 <sleep+0x2e>
    panic("sleep without lk");
80104d6c:	c7 04 24 4c 8c 10 80 	movl   $0x80108c4c,(%esp)
80104d73:	e8 c5 b7 ff ff       	call   8010053d <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
80104d78:	81 7d 0c 20 ff 10 80 	cmpl   $0x8010ff20,0xc(%ebp)
80104d7f:	74 17                	je     80104d98 <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
80104d81:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104d88:	e8 2a 03 00 00       	call   801050b7 <acquire>
    release(lk);
80104d8d:	8b 45 0c             	mov    0xc(%ebp),%eax
80104d90:	89 04 24             	mov    %eax,(%esp)
80104d93:	e8 ba 03 00 00       	call   80105152 <release>
  }

  // Go to sleep.
  proc->chan = chan;
80104d98:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d9e:	8b 55 08             	mov    0x8(%ebp),%edx
80104da1:	89 50 20             	mov    %edx,0x20(%eax)
  proc->state = SLEEPING;
80104da4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104daa:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)

  // Swap out
  if(swapFlag)
80104db1:	a1 08 b0 10 80       	mov    0x8010b008,%eax
80104db6:	85 c0                	test   %eax,%eax
80104db8:	74 2b                	je     80104de5 <sleep+0x9b>
  {
    if(proc->pid > 3)
80104dba:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104dc0:	8b 40 10             	mov    0x10(%eax),%eax
80104dc3:	83 f8 03             	cmp    $0x3,%eax
80104dc6:	7e 1d                	jle    80104de5 <sleep+0x9b>
    {
      release(&ptable.lock);
80104dc8:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104dcf:	e8 7e 03 00 00       	call   80105152 <release>
      swapOut();
80104dd4:	e8 7f f6 ff ff       	call   80104458 <swapOut>
      acquire(&ptable.lock);
80104dd9:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104de0:	e8 d2 02 00 00       	call   801050b7 <acquire>
    }
  }
  
  sched();
80104de5:	e8 50 fe ff ff       	call   80104c3a <sched>
  if(proc->pid>3)
80104dea:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104df0:	8b 40 10             	mov    0x10(%eax),%eax
80104df3:	83 f8 03             	cmp    $0x3,%eax
80104df6:	7e 19                	jle    80104e11 <sleep+0xc7>
    cprintf("pid = %d, after waking up\n",proc->pid);
80104df8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104dfe:	8b 40 10             	mov    0x10(%eax),%eax
80104e01:	89 44 24 04          	mov    %eax,0x4(%esp)
80104e05:	c7 04 24 5d 8c 10 80 	movl   $0x80108c5d,(%esp)
80104e0c:	e8 90 b5 ff ff       	call   801003a1 <cprintf>
  // Tidy up.
  proc->chan = 0;
80104e11:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e17:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
80104e1e:	81 7d 0c 20 ff 10 80 	cmpl   $0x8010ff20,0xc(%ebp)
80104e25:	74 17                	je     80104e3e <sleep+0xf4>
    release(&ptable.lock);
80104e27:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104e2e:	e8 1f 03 00 00       	call   80105152 <release>
    acquire(lk);
80104e33:	8b 45 0c             	mov    0xc(%ebp),%eax
80104e36:	89 04 24             	mov    %eax,(%esp)
80104e39:	e8 79 02 00 00       	call   801050b7 <acquire>
  }
}
80104e3e:	c9                   	leave  
80104e3f:	c3                   	ret    

80104e40 <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80104e40:	55                   	push   %ebp
80104e41:	89 e5                	mov    %esp,%ebp
80104e43:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104e46:	c7 45 fc 54 ff 10 80 	movl   $0x8010ff54,-0x4(%ebp)
80104e4d:	eb 53                	jmp    80104ea2 <wakeup1+0x62>
  {
    if(p->state == SLEEPING && p->chan == chan)
80104e4f:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104e52:	8b 40 0c             	mov    0xc(%eax),%eax
80104e55:	83 f8 02             	cmp    $0x2,%eax
80104e58:	75 15                	jne    80104e6f <wakeup1+0x2f>
80104e5a:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104e5d:	8b 40 20             	mov    0x20(%eax),%eax
80104e60:	3b 45 08             	cmp    0x8(%ebp),%eax
80104e63:	75 0a                	jne    80104e6f <wakeup1+0x2f>
      p->state = RUNNABLE;
80104e65:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104e68:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
    if(p->state == SLEEPING_SUSPENDED && p->chan == chan)
80104e6f:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104e72:	8b 40 0c             	mov    0xc(%eax),%eax
80104e75:	83 f8 06             	cmp    $0x6,%eax
80104e78:	75 21                	jne    80104e9b <wakeup1+0x5b>
80104e7a:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104e7d:	8b 40 20             	mov    0x20(%eax),%eax
80104e80:	3b 45 08             	cmp    0x8(%ebp),%eax
80104e83:	75 16                	jne    80104e9b <wakeup1+0x5b>
    {
      p->state = RUNNABLE_SUSPENDED;
80104e85:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104e88:	c7 40 0c 07 00 00 00 	movl   $0x7,0xc(%eax)
      inswapper->state = RUNNABLE;
80104e8f:	a1 4c b6 10 80       	mov    0x8010b64c,%eax
80104e94:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104e9b:	81 45 fc 8c 00 00 00 	addl   $0x8c,-0x4(%ebp)
80104ea2:	81 7d fc 54 22 11 80 	cmpl   $0x80112254,-0x4(%ebp)
80104ea9:	72 a4                	jb     80104e4f <wakeup1+0xf>
    {
      p->state = RUNNABLE_SUSPENDED;
      inswapper->state = RUNNABLE;
    }
  }
}
80104eab:	c9                   	leave  
80104eac:	c3                   	ret    

80104ead <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80104ead:	55                   	push   %ebp
80104eae:	89 e5                	mov    %esp,%ebp
80104eb0:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);
80104eb3:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104eba:	e8 f8 01 00 00       	call   801050b7 <acquire>
  wakeup1(chan);
80104ebf:	8b 45 08             	mov    0x8(%ebp),%eax
80104ec2:	89 04 24             	mov    %eax,(%esp)
80104ec5:	e8 76 ff ff ff       	call   80104e40 <wakeup1>
  release(&ptable.lock);
80104eca:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104ed1:	e8 7c 02 00 00       	call   80105152 <release>
}
80104ed6:	c9                   	leave  
80104ed7:	c3                   	ret    

80104ed8 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80104ed8:	55                   	push   %ebp
80104ed9:	89 e5                	mov    %esp,%ebp
80104edb:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  acquire(&ptable.lock);
80104ede:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104ee5:	e8 cd 01 00 00       	call   801050b7 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104eea:	c7 45 f4 54 ff 10 80 	movl   $0x8010ff54,-0xc(%ebp)
80104ef1:	eb 44                	jmp    80104f37 <kill+0x5f>
    if(p->pid == pid){
80104ef3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ef6:	8b 40 10             	mov    0x10(%eax),%eax
80104ef9:	3b 45 08             	cmp    0x8(%ebp),%eax
80104efc:	75 32                	jne    80104f30 <kill+0x58>
      p->killed = 1;
80104efe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f01:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80104f08:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f0b:	8b 40 0c             	mov    0xc(%eax),%eax
80104f0e:	83 f8 02             	cmp    $0x2,%eax
80104f11:	75 0a                	jne    80104f1d <kill+0x45>
        p->state = RUNNABLE;
80104f13:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f16:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      release(&ptable.lock);
80104f1d:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104f24:	e8 29 02 00 00       	call   80105152 <release>
      return 0;
80104f29:	b8 00 00 00 00       	mov    $0x0,%eax
80104f2e:	eb 21                	jmp    80104f51 <kill+0x79>
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104f30:	81 45 f4 8c 00 00 00 	addl   $0x8c,-0xc(%ebp)
80104f37:	81 7d f4 54 22 11 80 	cmpl   $0x80112254,-0xc(%ebp)
80104f3e:	72 b3                	jb     80104ef3 <kill+0x1b>
        p->state = RUNNABLE;
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
80104f40:	c7 04 24 20 ff 10 80 	movl   $0x8010ff20,(%esp)
80104f47:	e8 06 02 00 00       	call   80105152 <release>
  return -1;
80104f4c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104f51:	c9                   	leave  
80104f52:	c3                   	ret    

80104f53 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80104f53:	55                   	push   %ebp
80104f54:	89 e5                	mov    %esp,%ebp
80104f56:	83 ec 58             	sub    $0x58,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104f59:	c7 45 f0 54 ff 10 80 	movl   $0x8010ff54,-0x10(%ebp)
80104f60:	e9 db 00 00 00       	jmp    80105040 <procdump+0xed>
    if(p->state == UNUSED)
80104f65:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104f68:	8b 40 0c             	mov    0xc(%eax),%eax
80104f6b:	85 c0                	test   %eax,%eax
80104f6d:	0f 84 c5 00 00 00    	je     80105038 <procdump+0xe5>
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80104f73:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104f76:	8b 40 0c             	mov    0xc(%eax),%eax
80104f79:	83 f8 05             	cmp    $0x5,%eax
80104f7c:	77 23                	ja     80104fa1 <procdump+0x4e>
80104f7e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104f81:	8b 40 0c             	mov    0xc(%eax),%eax
80104f84:	8b 04 85 0c b0 10 80 	mov    -0x7fef4ff4(,%eax,4),%eax
80104f8b:	85 c0                	test   %eax,%eax
80104f8d:	74 12                	je     80104fa1 <procdump+0x4e>
      state = states[p->state];
80104f8f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104f92:	8b 40 0c             	mov    0xc(%eax),%eax
80104f95:	8b 04 85 0c b0 10 80 	mov    -0x7fef4ff4(,%eax,4),%eax
80104f9c:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104f9f:	eb 07                	jmp    80104fa8 <procdump+0x55>
    else
      state = "???";
80104fa1:	c7 45 ec 78 8c 10 80 	movl   $0x80108c78,-0x14(%ebp)
    cprintf("%d %s %s", p->pid, state, p->name);
80104fa8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104fab:	8d 50 6c             	lea    0x6c(%eax),%edx
80104fae:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104fb1:	8b 40 10             	mov    0x10(%eax),%eax
80104fb4:	89 54 24 0c          	mov    %edx,0xc(%esp)
80104fb8:	8b 55 ec             	mov    -0x14(%ebp),%edx
80104fbb:	89 54 24 08          	mov    %edx,0x8(%esp)
80104fbf:	89 44 24 04          	mov    %eax,0x4(%esp)
80104fc3:	c7 04 24 7c 8c 10 80 	movl   $0x80108c7c,(%esp)
80104fca:	e8 d2 b3 ff ff       	call   801003a1 <cprintf>
    if(p->state == SLEEPING){
80104fcf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104fd2:	8b 40 0c             	mov    0xc(%eax),%eax
80104fd5:	83 f8 02             	cmp    $0x2,%eax
80104fd8:	75 50                	jne    8010502a <procdump+0xd7>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80104fda:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104fdd:	8b 40 1c             	mov    0x1c(%eax),%eax
80104fe0:	8b 40 0c             	mov    0xc(%eax),%eax
80104fe3:	83 c0 08             	add    $0x8,%eax
80104fe6:	8d 55 c4             	lea    -0x3c(%ebp),%edx
80104fe9:	89 54 24 04          	mov    %edx,0x4(%esp)
80104fed:	89 04 24             	mov    %eax,(%esp)
80104ff0:	e8 ac 01 00 00       	call   801051a1 <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80104ff5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104ffc:	eb 1b                	jmp    80105019 <procdump+0xc6>
        cprintf(" %p", pc[i]);
80104ffe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105001:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80105005:	89 44 24 04          	mov    %eax,0x4(%esp)
80105009:	c7 04 24 85 8c 10 80 	movl   $0x80108c85,(%esp)
80105010:	e8 8c b3 ff ff       	call   801003a1 <cprintf>
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
80105015:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80105019:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
8010501d:	7f 0b                	jg     8010502a <procdump+0xd7>
8010501f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105022:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80105026:	85 c0                	test   %eax,%eax
80105028:	75 d4                	jne    80104ffe <procdump+0xab>
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
8010502a:	c7 04 24 89 8c 10 80 	movl   $0x80108c89,(%esp)
80105031:	e8 6b b3 ff ff       	call   801003a1 <cprintf>
80105036:	eb 01                	jmp    80105039 <procdump+0xe6>
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
80105038:	90                   	nop
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105039:	81 45 f0 8c 00 00 00 	addl   $0x8c,-0x10(%ebp)
80105040:	81 7d f0 54 22 11 80 	cmpl   $0x80112254,-0x10(%ebp)
80105047:	0f 82 18 ff ff ff    	jb     80104f65 <procdump+0x12>
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}
8010504d:	c9                   	leave  
8010504e:	c3                   	ret    
	...

80105050 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80105050:	55                   	push   %ebp
80105051:	89 e5                	mov    %esp,%ebp
80105053:	53                   	push   %ebx
80105054:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80105057:	9c                   	pushf  
80105058:	5b                   	pop    %ebx
80105059:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
8010505c:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
8010505f:	83 c4 10             	add    $0x10,%esp
80105062:	5b                   	pop    %ebx
80105063:	5d                   	pop    %ebp
80105064:	c3                   	ret    

80105065 <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
80105065:	55                   	push   %ebp
80105066:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
80105068:	fa                   	cli    
}
80105069:	5d                   	pop    %ebp
8010506a:	c3                   	ret    

8010506b <sti>:

static inline void
sti(void)
{
8010506b:	55                   	push   %ebp
8010506c:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
8010506e:	fb                   	sti    
}
8010506f:	5d                   	pop    %ebp
80105070:	c3                   	ret    

80105071 <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
80105071:	55                   	push   %ebp
80105072:	89 e5                	mov    %esp,%ebp
80105074:	53                   	push   %ebx
80105075:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
80105078:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
8010507b:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
8010507e:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80105081:	89 c3                	mov    %eax,%ebx
80105083:	89 d8                	mov    %ebx,%eax
80105085:	f0 87 02             	lock xchg %eax,(%edx)
80105088:	89 c3                	mov    %eax,%ebx
8010508a:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
8010508d:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80105090:	83 c4 10             	add    $0x10,%esp
80105093:	5b                   	pop    %ebx
80105094:	5d                   	pop    %ebp
80105095:	c3                   	ret    

80105096 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80105096:	55                   	push   %ebp
80105097:	89 e5                	mov    %esp,%ebp
  lk->name = name;
80105099:	8b 45 08             	mov    0x8(%ebp),%eax
8010509c:	8b 55 0c             	mov    0xc(%ebp),%edx
8010509f:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
801050a2:	8b 45 08             	mov    0x8(%ebp),%eax
801050a5:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
801050ab:	8b 45 08             	mov    0x8(%ebp),%eax
801050ae:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
801050b5:	5d                   	pop    %ebp
801050b6:	c3                   	ret    

801050b7 <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
801050b7:	55                   	push   %ebp
801050b8:	89 e5                	mov    %esp,%ebp
801050ba:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
801050bd:	e8 76 01 00 00       	call   80105238 <pushcli>
  if(holding(lk))
801050c2:	8b 45 08             	mov    0x8(%ebp),%eax
801050c5:	89 04 24             	mov    %eax,(%esp)
801050c8:	e8 41 01 00 00       	call   8010520e <holding>
801050cd:	85 c0                	test   %eax,%eax
801050cf:	74 45                	je     80105116 <acquire+0x5f>
  {
    cprintf("lock = %s\n",lk->name);
801050d1:	8b 45 08             	mov    0x8(%ebp),%eax
801050d4:	8b 40 04             	mov    0x4(%eax),%eax
801050d7:	89 44 24 04          	mov    %eax,0x4(%esp)
801050db:	c7 04 24 b5 8c 10 80 	movl   $0x80108cb5,(%esp)
801050e2:	e8 ba b2 ff ff       	call   801003a1 <cprintf>
    if(proc)
801050e7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050ed:	85 c0                	test   %eax,%eax
801050ef:	74 19                	je     8010510a <acquire+0x53>
      cprintf("pid = %d\n",proc->pid);
801050f1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050f7:	8b 40 10             	mov    0x10(%eax),%eax
801050fa:	89 44 24 04          	mov    %eax,0x4(%esp)
801050fe:	c7 04 24 c0 8c 10 80 	movl   $0x80108cc0,(%esp)
80105105:	e8 97 b2 ff ff       	call   801003a1 <cprintf>
    panic("acquire");
8010510a:	c7 04 24 ca 8c 10 80 	movl   $0x80108cca,(%esp)
80105111:	e8 27 b4 ff ff       	call   8010053d <panic>
  }

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
80105116:	90                   	nop
80105117:	8b 45 08             	mov    0x8(%ebp),%eax
8010511a:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80105121:	00 
80105122:	89 04 24             	mov    %eax,(%esp)
80105125:	e8 47 ff ff ff       	call   80105071 <xchg>
8010512a:	85 c0                	test   %eax,%eax
8010512c:	75 e9                	jne    80105117 <acquire+0x60>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
8010512e:	8b 45 08             	mov    0x8(%ebp),%eax
80105131:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80105138:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
8010513b:	8b 45 08             	mov    0x8(%ebp),%eax
8010513e:	83 c0 0c             	add    $0xc,%eax
80105141:	89 44 24 04          	mov    %eax,0x4(%esp)
80105145:	8d 45 08             	lea    0x8(%ebp),%eax
80105148:	89 04 24             	mov    %eax,(%esp)
8010514b:	e8 51 00 00 00       	call   801051a1 <getcallerpcs>
}
80105150:	c9                   	leave  
80105151:	c3                   	ret    

80105152 <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
80105152:	55                   	push   %ebp
80105153:	89 e5                	mov    %esp,%ebp
80105155:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
80105158:	8b 45 08             	mov    0x8(%ebp),%eax
8010515b:	89 04 24             	mov    %eax,(%esp)
8010515e:	e8 ab 00 00 00       	call   8010520e <holding>
80105163:	85 c0                	test   %eax,%eax
80105165:	75 0c                	jne    80105173 <release+0x21>
    panic("release");
80105167:	c7 04 24 d2 8c 10 80 	movl   $0x80108cd2,(%esp)
8010516e:	e8 ca b3 ff ff       	call   8010053d <panic>

  lk->pcs[0] = 0;
80105173:	8b 45 08             	mov    0x8(%ebp),%eax
80105176:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
8010517d:	8b 45 08             	mov    0x8(%ebp),%eax
80105180:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
80105187:	8b 45 08             	mov    0x8(%ebp),%eax
8010518a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105191:	00 
80105192:	89 04 24             	mov    %eax,(%esp)
80105195:	e8 d7 fe ff ff       	call   80105071 <xchg>

  popcli();
8010519a:	e8 e1 00 00 00       	call   80105280 <popcli>
}
8010519f:	c9                   	leave  
801051a0:	c3                   	ret    

801051a1 <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
801051a1:	55                   	push   %ebp
801051a2:	89 e5                	mov    %esp,%ebp
801051a4:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
801051a7:	8b 45 08             	mov    0x8(%ebp),%eax
801051aa:	83 e8 08             	sub    $0x8,%eax
801051ad:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
801051b0:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
801051b7:	eb 32                	jmp    801051eb <getcallerpcs+0x4a>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
801051b9:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
801051bd:	74 47                	je     80105206 <getcallerpcs+0x65>
801051bf:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
801051c6:	76 3e                	jbe    80105206 <getcallerpcs+0x65>
801051c8:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
801051cc:	74 38                	je     80105206 <getcallerpcs+0x65>
      break;
    pcs[i] = ebp[1];     // saved %eip
801051ce:	8b 45 f8             	mov    -0x8(%ebp),%eax
801051d1:	c1 e0 02             	shl    $0x2,%eax
801051d4:	03 45 0c             	add    0xc(%ebp),%eax
801051d7:	8b 55 fc             	mov    -0x4(%ebp),%edx
801051da:	8b 52 04             	mov    0x4(%edx),%edx
801051dd:	89 10                	mov    %edx,(%eax)
    ebp = (uint*)ebp[0]; // saved %ebp
801051df:	8b 45 fc             	mov    -0x4(%ebp),%eax
801051e2:	8b 00                	mov    (%eax),%eax
801051e4:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
801051e7:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
801051eb:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
801051ef:	7e c8                	jle    801051b9 <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
801051f1:	eb 13                	jmp    80105206 <getcallerpcs+0x65>
    pcs[i] = 0;
801051f3:	8b 45 f8             	mov    -0x8(%ebp),%eax
801051f6:	c1 e0 02             	shl    $0x2,%eax
801051f9:	03 45 0c             	add    0xc(%ebp),%eax
801051fc:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105202:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105206:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
8010520a:	7e e7                	jle    801051f3 <getcallerpcs+0x52>
    pcs[i] = 0;
}
8010520c:	c9                   	leave  
8010520d:	c3                   	ret    

8010520e <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
8010520e:	55                   	push   %ebp
8010520f:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
80105211:	8b 45 08             	mov    0x8(%ebp),%eax
80105214:	8b 00                	mov    (%eax),%eax
80105216:	85 c0                	test   %eax,%eax
80105218:	74 17                	je     80105231 <holding+0x23>
8010521a:	8b 45 08             	mov    0x8(%ebp),%eax
8010521d:	8b 50 08             	mov    0x8(%eax),%edx
80105220:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105226:	39 c2                	cmp    %eax,%edx
80105228:	75 07                	jne    80105231 <holding+0x23>
8010522a:	b8 01 00 00 00       	mov    $0x1,%eax
8010522f:	eb 05                	jmp    80105236 <holding+0x28>
80105231:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105236:	5d                   	pop    %ebp
80105237:	c3                   	ret    

80105238 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80105238:	55                   	push   %ebp
80105239:	89 e5                	mov    %esp,%ebp
8010523b:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
8010523e:	e8 0d fe ff ff       	call   80105050 <readeflags>
80105243:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
80105246:	e8 1a fe ff ff       	call   80105065 <cli>
  if(cpu->ncli++ == 0)
8010524b:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105251:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80105257:	85 d2                	test   %edx,%edx
80105259:	0f 94 c1             	sete   %cl
8010525c:	83 c2 01             	add    $0x1,%edx
8010525f:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80105265:	84 c9                	test   %cl,%cl
80105267:	74 15                	je     8010527e <pushcli+0x46>
    cpu->intena = eflags & FL_IF;
80105269:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010526f:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105272:	81 e2 00 02 00 00    	and    $0x200,%edx
80105278:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
8010527e:	c9                   	leave  
8010527f:	c3                   	ret    

80105280 <popcli>:

void
popcli(void)
{
80105280:	55                   	push   %ebp
80105281:	89 e5                	mov    %esp,%ebp
80105283:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
80105286:	e8 c5 fd ff ff       	call   80105050 <readeflags>
8010528b:	25 00 02 00 00       	and    $0x200,%eax
80105290:	85 c0                	test   %eax,%eax
80105292:	74 0c                	je     801052a0 <popcli+0x20>
    panic("popcli - interruptible");
80105294:	c7 04 24 da 8c 10 80 	movl   $0x80108cda,(%esp)
8010529b:	e8 9d b2 ff ff       	call   8010053d <panic>
  if(--cpu->ncli < 0)
801052a0:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801052a6:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
801052ac:	83 ea 01             	sub    $0x1,%edx
801052af:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
801052b5:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
801052bb:	85 c0                	test   %eax,%eax
801052bd:	79 0c                	jns    801052cb <popcli+0x4b>
    panic("popcli");
801052bf:	c7 04 24 f1 8c 10 80 	movl   $0x80108cf1,(%esp)
801052c6:	e8 72 b2 ff ff       	call   8010053d <panic>
  if(cpu->ncli == 0 && cpu->intena)
801052cb:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801052d1:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
801052d7:	85 c0                	test   %eax,%eax
801052d9:	75 15                	jne    801052f0 <popcli+0x70>
801052db:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801052e1:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
801052e7:	85 c0                	test   %eax,%eax
801052e9:	74 05                	je     801052f0 <popcli+0x70>
    sti();
801052eb:	e8 7b fd ff ff       	call   8010506b <sti>
}
801052f0:	c9                   	leave  
801052f1:	c3                   	ret    
	...

801052f4 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
801052f4:	55                   	push   %ebp
801052f5:	89 e5                	mov    %esp,%ebp
801052f7:	57                   	push   %edi
801052f8:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
801052f9:	8b 4d 08             	mov    0x8(%ebp),%ecx
801052fc:	8b 55 10             	mov    0x10(%ebp),%edx
801052ff:	8b 45 0c             	mov    0xc(%ebp),%eax
80105302:	89 cb                	mov    %ecx,%ebx
80105304:	89 df                	mov    %ebx,%edi
80105306:	89 d1                	mov    %edx,%ecx
80105308:	fc                   	cld    
80105309:	f3 aa                	rep stos %al,%es:(%edi)
8010530b:	89 ca                	mov    %ecx,%edx
8010530d:	89 fb                	mov    %edi,%ebx
8010530f:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105312:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105315:	5b                   	pop    %ebx
80105316:	5f                   	pop    %edi
80105317:	5d                   	pop    %ebp
80105318:	c3                   	ret    

80105319 <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
80105319:	55                   	push   %ebp
8010531a:	89 e5                	mov    %esp,%ebp
8010531c:	57                   	push   %edi
8010531d:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
8010531e:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105321:	8b 55 10             	mov    0x10(%ebp),%edx
80105324:	8b 45 0c             	mov    0xc(%ebp),%eax
80105327:	89 cb                	mov    %ecx,%ebx
80105329:	89 df                	mov    %ebx,%edi
8010532b:	89 d1                	mov    %edx,%ecx
8010532d:	fc                   	cld    
8010532e:	f3 ab                	rep stos %eax,%es:(%edi)
80105330:	89 ca                	mov    %ecx,%edx
80105332:	89 fb                	mov    %edi,%ebx
80105334:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105337:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
8010533a:	5b                   	pop    %ebx
8010533b:	5f                   	pop    %edi
8010533c:	5d                   	pop    %ebp
8010533d:	c3                   	ret    

8010533e <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
8010533e:	55                   	push   %ebp
8010533f:	89 e5                	mov    %esp,%ebp
80105341:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
80105344:	8b 45 08             	mov    0x8(%ebp),%eax
80105347:	83 e0 03             	and    $0x3,%eax
8010534a:	85 c0                	test   %eax,%eax
8010534c:	75 49                	jne    80105397 <memset+0x59>
8010534e:	8b 45 10             	mov    0x10(%ebp),%eax
80105351:	83 e0 03             	and    $0x3,%eax
80105354:	85 c0                	test   %eax,%eax
80105356:	75 3f                	jne    80105397 <memset+0x59>
    c &= 0xFF;
80105358:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
8010535f:	8b 45 10             	mov    0x10(%ebp),%eax
80105362:	c1 e8 02             	shr    $0x2,%eax
80105365:	89 c2                	mov    %eax,%edx
80105367:	8b 45 0c             	mov    0xc(%ebp),%eax
8010536a:	89 c1                	mov    %eax,%ecx
8010536c:	c1 e1 18             	shl    $0x18,%ecx
8010536f:	8b 45 0c             	mov    0xc(%ebp),%eax
80105372:	c1 e0 10             	shl    $0x10,%eax
80105375:	09 c1                	or     %eax,%ecx
80105377:	8b 45 0c             	mov    0xc(%ebp),%eax
8010537a:	c1 e0 08             	shl    $0x8,%eax
8010537d:	09 c8                	or     %ecx,%eax
8010537f:	0b 45 0c             	or     0xc(%ebp),%eax
80105382:	89 54 24 08          	mov    %edx,0x8(%esp)
80105386:	89 44 24 04          	mov    %eax,0x4(%esp)
8010538a:	8b 45 08             	mov    0x8(%ebp),%eax
8010538d:	89 04 24             	mov    %eax,(%esp)
80105390:	e8 84 ff ff ff       	call   80105319 <stosl>
80105395:	eb 19                	jmp    801053b0 <memset+0x72>
  } else
    stosb(dst, c, n);
80105397:	8b 45 10             	mov    0x10(%ebp),%eax
8010539a:	89 44 24 08          	mov    %eax,0x8(%esp)
8010539e:	8b 45 0c             	mov    0xc(%ebp),%eax
801053a1:	89 44 24 04          	mov    %eax,0x4(%esp)
801053a5:	8b 45 08             	mov    0x8(%ebp),%eax
801053a8:	89 04 24             	mov    %eax,(%esp)
801053ab:	e8 44 ff ff ff       	call   801052f4 <stosb>
  return dst;
801053b0:	8b 45 08             	mov    0x8(%ebp),%eax
}
801053b3:	c9                   	leave  
801053b4:	c3                   	ret    

801053b5 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
801053b5:	55                   	push   %ebp
801053b6:	89 e5                	mov    %esp,%ebp
801053b8:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
801053bb:	8b 45 08             	mov    0x8(%ebp),%eax
801053be:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
801053c1:	8b 45 0c             	mov    0xc(%ebp),%eax
801053c4:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
801053c7:	eb 32                	jmp    801053fb <memcmp+0x46>
    if(*s1 != *s2)
801053c9:	8b 45 fc             	mov    -0x4(%ebp),%eax
801053cc:	0f b6 10             	movzbl (%eax),%edx
801053cf:	8b 45 f8             	mov    -0x8(%ebp),%eax
801053d2:	0f b6 00             	movzbl (%eax),%eax
801053d5:	38 c2                	cmp    %al,%dl
801053d7:	74 1a                	je     801053f3 <memcmp+0x3e>
      return *s1 - *s2;
801053d9:	8b 45 fc             	mov    -0x4(%ebp),%eax
801053dc:	0f b6 00             	movzbl (%eax),%eax
801053df:	0f b6 d0             	movzbl %al,%edx
801053e2:	8b 45 f8             	mov    -0x8(%ebp),%eax
801053e5:	0f b6 00             	movzbl (%eax),%eax
801053e8:	0f b6 c0             	movzbl %al,%eax
801053eb:	89 d1                	mov    %edx,%ecx
801053ed:	29 c1                	sub    %eax,%ecx
801053ef:	89 c8                	mov    %ecx,%eax
801053f1:	eb 1c                	jmp    8010540f <memcmp+0x5a>
    s1++, s2++;
801053f3:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801053f7:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
801053fb:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801053ff:	0f 95 c0             	setne  %al
80105402:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105406:	84 c0                	test   %al,%al
80105408:	75 bf                	jne    801053c9 <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
8010540a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010540f:	c9                   	leave  
80105410:	c3                   	ret    

80105411 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80105411:	55                   	push   %ebp
80105412:	89 e5                	mov    %esp,%ebp
80105414:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
80105417:	8b 45 0c             	mov    0xc(%ebp),%eax
8010541a:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
8010541d:	8b 45 08             	mov    0x8(%ebp),%eax
80105420:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
80105423:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105426:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105429:	73 54                	jae    8010547f <memmove+0x6e>
8010542b:	8b 45 10             	mov    0x10(%ebp),%eax
8010542e:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105431:	01 d0                	add    %edx,%eax
80105433:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105436:	76 47                	jbe    8010547f <memmove+0x6e>
    s += n;
80105438:	8b 45 10             	mov    0x10(%ebp),%eax
8010543b:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
8010543e:	8b 45 10             	mov    0x10(%ebp),%eax
80105441:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
80105444:	eb 13                	jmp    80105459 <memmove+0x48>
      *--d = *--s;
80105446:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
8010544a:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
8010544e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105451:	0f b6 10             	movzbl (%eax),%edx
80105454:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105457:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
80105459:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010545d:	0f 95 c0             	setne  %al
80105460:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105464:	84 c0                	test   %al,%al
80105466:	75 de                	jne    80105446 <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80105468:	eb 25                	jmp    8010548f <memmove+0x7e>
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
      *d++ = *s++;
8010546a:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010546d:	0f b6 10             	movzbl (%eax),%edx
80105470:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105473:	88 10                	mov    %dl,(%eax)
80105475:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105479:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010547d:	eb 01                	jmp    80105480 <memmove+0x6f>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
8010547f:	90                   	nop
80105480:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105484:	0f 95 c0             	setne  %al
80105487:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
8010548b:	84 c0                	test   %al,%al
8010548d:	75 db                	jne    8010546a <memmove+0x59>
      *d++ = *s++;

  return dst;
8010548f:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105492:	c9                   	leave  
80105493:	c3                   	ret    

80105494 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80105494:	55                   	push   %ebp
80105495:	89 e5                	mov    %esp,%ebp
80105497:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
8010549a:	8b 45 10             	mov    0x10(%ebp),%eax
8010549d:	89 44 24 08          	mov    %eax,0x8(%esp)
801054a1:	8b 45 0c             	mov    0xc(%ebp),%eax
801054a4:	89 44 24 04          	mov    %eax,0x4(%esp)
801054a8:	8b 45 08             	mov    0x8(%ebp),%eax
801054ab:	89 04 24             	mov    %eax,(%esp)
801054ae:	e8 5e ff ff ff       	call   80105411 <memmove>
}
801054b3:	c9                   	leave  
801054b4:	c3                   	ret    

801054b5 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
801054b5:	55                   	push   %ebp
801054b6:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
801054b8:	eb 0c                	jmp    801054c6 <strncmp+0x11>
    n--, p++, q++;
801054ba:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801054be:	83 45 08 01          	addl   $0x1,0x8(%ebp)
801054c2:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
801054c6:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801054ca:	74 1a                	je     801054e6 <strncmp+0x31>
801054cc:	8b 45 08             	mov    0x8(%ebp),%eax
801054cf:	0f b6 00             	movzbl (%eax),%eax
801054d2:	84 c0                	test   %al,%al
801054d4:	74 10                	je     801054e6 <strncmp+0x31>
801054d6:	8b 45 08             	mov    0x8(%ebp),%eax
801054d9:	0f b6 10             	movzbl (%eax),%edx
801054dc:	8b 45 0c             	mov    0xc(%ebp),%eax
801054df:	0f b6 00             	movzbl (%eax),%eax
801054e2:	38 c2                	cmp    %al,%dl
801054e4:	74 d4                	je     801054ba <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
801054e6:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801054ea:	75 07                	jne    801054f3 <strncmp+0x3e>
    return 0;
801054ec:	b8 00 00 00 00       	mov    $0x0,%eax
801054f1:	eb 18                	jmp    8010550b <strncmp+0x56>
  return (uchar)*p - (uchar)*q;
801054f3:	8b 45 08             	mov    0x8(%ebp),%eax
801054f6:	0f b6 00             	movzbl (%eax),%eax
801054f9:	0f b6 d0             	movzbl %al,%edx
801054fc:	8b 45 0c             	mov    0xc(%ebp),%eax
801054ff:	0f b6 00             	movzbl (%eax),%eax
80105502:	0f b6 c0             	movzbl %al,%eax
80105505:	89 d1                	mov    %edx,%ecx
80105507:	29 c1                	sub    %eax,%ecx
80105509:	89 c8                	mov    %ecx,%eax
}
8010550b:	5d                   	pop    %ebp
8010550c:	c3                   	ret    

8010550d <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
8010550d:	55                   	push   %ebp
8010550e:	89 e5                	mov    %esp,%ebp
80105510:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105513:	8b 45 08             	mov    0x8(%ebp),%eax
80105516:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
80105519:	90                   	nop
8010551a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010551e:	0f 9f c0             	setg   %al
80105521:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105525:	84 c0                	test   %al,%al
80105527:	74 30                	je     80105559 <strncpy+0x4c>
80105529:	8b 45 0c             	mov    0xc(%ebp),%eax
8010552c:	0f b6 10             	movzbl (%eax),%edx
8010552f:	8b 45 08             	mov    0x8(%ebp),%eax
80105532:	88 10                	mov    %dl,(%eax)
80105534:	8b 45 08             	mov    0x8(%ebp),%eax
80105537:	0f b6 00             	movzbl (%eax),%eax
8010553a:	84 c0                	test   %al,%al
8010553c:	0f 95 c0             	setne  %al
8010553f:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105543:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
80105547:	84 c0                	test   %al,%al
80105549:	75 cf                	jne    8010551a <strncpy+0xd>
    ;
  while(n-- > 0)
8010554b:	eb 0c                	jmp    80105559 <strncpy+0x4c>
    *s++ = 0;
8010554d:	8b 45 08             	mov    0x8(%ebp),%eax
80105550:	c6 00 00             	movb   $0x0,(%eax)
80105553:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105557:	eb 01                	jmp    8010555a <strncpy+0x4d>
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
80105559:	90                   	nop
8010555a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010555e:	0f 9f c0             	setg   %al
80105561:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105565:	84 c0                	test   %al,%al
80105567:	75 e4                	jne    8010554d <strncpy+0x40>
    *s++ = 0;
  return os;
80105569:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
8010556c:	c9                   	leave  
8010556d:	c3                   	ret    

8010556e <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
8010556e:	55                   	push   %ebp
8010556f:	89 e5                	mov    %esp,%ebp
80105571:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105574:	8b 45 08             	mov    0x8(%ebp),%eax
80105577:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
8010557a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010557e:	7f 05                	jg     80105585 <safestrcpy+0x17>
    return os;
80105580:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105583:	eb 35                	jmp    801055ba <safestrcpy+0x4c>
  while(--n > 0 && (*s++ = *t++) != 0)
80105585:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105589:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010558d:	7e 22                	jle    801055b1 <safestrcpy+0x43>
8010558f:	8b 45 0c             	mov    0xc(%ebp),%eax
80105592:	0f b6 10             	movzbl (%eax),%edx
80105595:	8b 45 08             	mov    0x8(%ebp),%eax
80105598:	88 10                	mov    %dl,(%eax)
8010559a:	8b 45 08             	mov    0x8(%ebp),%eax
8010559d:	0f b6 00             	movzbl (%eax),%eax
801055a0:	84 c0                	test   %al,%al
801055a2:	0f 95 c0             	setne  %al
801055a5:	83 45 08 01          	addl   $0x1,0x8(%ebp)
801055a9:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
801055ad:	84 c0                	test   %al,%al
801055af:	75 d4                	jne    80105585 <safestrcpy+0x17>
    ;
  *s = 0;
801055b1:	8b 45 08             	mov    0x8(%ebp),%eax
801055b4:	c6 00 00             	movb   $0x0,(%eax)
  return os;
801055b7:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801055ba:	c9                   	leave  
801055bb:	c3                   	ret    

801055bc <strlen>:

int
strlen(const char *s)
{
801055bc:	55                   	push   %ebp
801055bd:	89 e5                	mov    %esp,%ebp
801055bf:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
801055c2:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801055c9:	eb 04                	jmp    801055cf <strlen+0x13>
801055cb:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801055cf:	8b 45 fc             	mov    -0x4(%ebp),%eax
801055d2:	03 45 08             	add    0x8(%ebp),%eax
801055d5:	0f b6 00             	movzbl (%eax),%eax
801055d8:	84 c0                	test   %al,%al
801055da:	75 ef                	jne    801055cb <strlen+0xf>
    ;
  return n;
801055dc:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801055df:	c9                   	leave  
801055e0:	c3                   	ret    
801055e1:	00 00                	add    %al,(%eax)
	...

801055e4 <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
801055e4:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
801055e8:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
801055ec:	55                   	push   %ebp
  pushl %ebx
801055ed:	53                   	push   %ebx
  pushl %esi
801055ee:	56                   	push   %esi
  pushl %edi
801055ef:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
801055f0:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
801055f2:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
801055f4:	5f                   	pop    %edi
  popl %esi
801055f5:	5e                   	pop    %esi
  popl %ebx
801055f6:	5b                   	pop    %ebx
  popl %ebp
801055f7:	5d                   	pop    %ebp
  ret
801055f8:	c3                   	ret    
801055f9:	00 00                	add    %al,(%eax)
	...

801055fc <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from process p.
int
fetchint(struct proc *p, uint addr, int *ip)
{
801055fc:	55                   	push   %ebp
801055fd:	89 e5                	mov    %esp,%ebp
  if(addr >= p->sz || addr+4 > p->sz)
801055ff:	8b 45 08             	mov    0x8(%ebp),%eax
80105602:	8b 00                	mov    (%eax),%eax
80105604:	3b 45 0c             	cmp    0xc(%ebp),%eax
80105607:	76 0f                	jbe    80105618 <fetchint+0x1c>
80105609:	8b 45 0c             	mov    0xc(%ebp),%eax
8010560c:	8d 50 04             	lea    0x4(%eax),%edx
8010560f:	8b 45 08             	mov    0x8(%ebp),%eax
80105612:	8b 00                	mov    (%eax),%eax
80105614:	39 c2                	cmp    %eax,%edx
80105616:	76 07                	jbe    8010561f <fetchint+0x23>
    return -1;
80105618:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010561d:	eb 0f                	jmp    8010562e <fetchint+0x32>
  *ip = *(int*)(addr);
8010561f:	8b 45 0c             	mov    0xc(%ebp),%eax
80105622:	8b 10                	mov    (%eax),%edx
80105624:	8b 45 10             	mov    0x10(%ebp),%eax
80105627:	89 10                	mov    %edx,(%eax)
  return 0;
80105629:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010562e:	5d                   	pop    %ebp
8010562f:	c3                   	ret    

80105630 <fetchstr>:
// Fetch the nul-terminated string at addr from process p.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(struct proc *p, uint addr, char **pp)
{
80105630:	55                   	push   %ebp
80105631:	89 e5                	mov    %esp,%ebp
80105633:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= p->sz)
80105636:	8b 45 08             	mov    0x8(%ebp),%eax
80105639:	8b 00                	mov    (%eax),%eax
8010563b:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010563e:	77 07                	ja     80105647 <fetchstr+0x17>
    return -1;
80105640:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105645:	eb 45                	jmp    8010568c <fetchstr+0x5c>
  *pp = (char*)addr;
80105647:	8b 55 0c             	mov    0xc(%ebp),%edx
8010564a:	8b 45 10             	mov    0x10(%ebp),%eax
8010564d:	89 10                	mov    %edx,(%eax)
  ep = (char*)p->sz;
8010564f:	8b 45 08             	mov    0x8(%ebp),%eax
80105652:	8b 00                	mov    (%eax),%eax
80105654:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
80105657:	8b 45 10             	mov    0x10(%ebp),%eax
8010565a:	8b 00                	mov    (%eax),%eax
8010565c:	89 45 fc             	mov    %eax,-0x4(%ebp)
8010565f:	eb 1e                	jmp    8010567f <fetchstr+0x4f>
    if(*s == 0)
80105661:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105664:	0f b6 00             	movzbl (%eax),%eax
80105667:	84 c0                	test   %al,%al
80105669:	75 10                	jne    8010567b <fetchstr+0x4b>
      return s - *pp;
8010566b:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010566e:	8b 45 10             	mov    0x10(%ebp),%eax
80105671:	8b 00                	mov    (%eax),%eax
80105673:	89 d1                	mov    %edx,%ecx
80105675:	29 c1                	sub    %eax,%ecx
80105677:	89 c8                	mov    %ecx,%eax
80105679:	eb 11                	jmp    8010568c <fetchstr+0x5c>

  if(addr >= p->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)p->sz;
  for(s = *pp; s < ep; s++)
8010567b:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010567f:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105682:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105685:	72 da                	jb     80105661 <fetchstr+0x31>
    if(*s == 0)
      return s - *pp;
  return -1;
80105687:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010568c:	c9                   	leave  
8010568d:	c3                   	ret    

8010568e <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
8010568e:	55                   	push   %ebp
8010568f:	89 e5                	mov    %esp,%ebp
80105691:	83 ec 0c             	sub    $0xc,%esp
  return fetchint(proc, proc->tf->esp + 4 + 4*n, ip);
80105694:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010569a:	8b 40 18             	mov    0x18(%eax),%eax
8010569d:	8b 50 44             	mov    0x44(%eax),%edx
801056a0:	8b 45 08             	mov    0x8(%ebp),%eax
801056a3:	c1 e0 02             	shl    $0x2,%eax
801056a6:	01 d0                	add    %edx,%eax
801056a8:	8d 48 04             	lea    0x4(%eax),%ecx
801056ab:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801056b1:	8b 55 0c             	mov    0xc(%ebp),%edx
801056b4:	89 54 24 08          	mov    %edx,0x8(%esp)
801056b8:	89 4c 24 04          	mov    %ecx,0x4(%esp)
801056bc:	89 04 24             	mov    %eax,(%esp)
801056bf:	e8 38 ff ff ff       	call   801055fc <fetchint>
}
801056c4:	c9                   	leave  
801056c5:	c3                   	ret    

801056c6 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
801056c6:	55                   	push   %ebp
801056c7:	89 e5                	mov    %esp,%ebp
801056c9:	83 ec 18             	sub    $0x18,%esp
  int i;
  
  if(argint(n, &i) < 0)
801056cc:	8d 45 fc             	lea    -0x4(%ebp),%eax
801056cf:	89 44 24 04          	mov    %eax,0x4(%esp)
801056d3:	8b 45 08             	mov    0x8(%ebp),%eax
801056d6:	89 04 24             	mov    %eax,(%esp)
801056d9:	e8 b0 ff ff ff       	call   8010568e <argint>
801056de:	85 c0                	test   %eax,%eax
801056e0:	79 07                	jns    801056e9 <argptr+0x23>
    return -1;
801056e2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801056e7:	eb 3d                	jmp    80105726 <argptr+0x60>
  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
801056e9:	8b 45 fc             	mov    -0x4(%ebp),%eax
801056ec:	89 c2                	mov    %eax,%edx
801056ee:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801056f4:	8b 00                	mov    (%eax),%eax
801056f6:	39 c2                	cmp    %eax,%edx
801056f8:	73 16                	jae    80105710 <argptr+0x4a>
801056fa:	8b 45 fc             	mov    -0x4(%ebp),%eax
801056fd:	89 c2                	mov    %eax,%edx
801056ff:	8b 45 10             	mov    0x10(%ebp),%eax
80105702:	01 c2                	add    %eax,%edx
80105704:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010570a:	8b 00                	mov    (%eax),%eax
8010570c:	39 c2                	cmp    %eax,%edx
8010570e:	76 07                	jbe    80105717 <argptr+0x51>
    return -1;
80105710:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105715:	eb 0f                	jmp    80105726 <argptr+0x60>
  *pp = (char*)i;
80105717:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010571a:	89 c2                	mov    %eax,%edx
8010571c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010571f:	89 10                	mov    %edx,(%eax)
  return 0;
80105721:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105726:	c9                   	leave  
80105727:	c3                   	ret    

80105728 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80105728:	55                   	push   %ebp
80105729:	89 e5                	mov    %esp,%ebp
8010572b:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  if(argint(n, &addr) < 0)
8010572e:	8d 45 fc             	lea    -0x4(%ebp),%eax
80105731:	89 44 24 04          	mov    %eax,0x4(%esp)
80105735:	8b 45 08             	mov    0x8(%ebp),%eax
80105738:	89 04 24             	mov    %eax,(%esp)
8010573b:	e8 4e ff ff ff       	call   8010568e <argint>
80105740:	85 c0                	test   %eax,%eax
80105742:	79 07                	jns    8010574b <argstr+0x23>
    return -1;
80105744:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105749:	eb 1e                	jmp    80105769 <argstr+0x41>
  return fetchstr(proc, addr, pp);
8010574b:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010574e:	89 c2                	mov    %eax,%edx
80105750:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105756:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80105759:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010575d:	89 54 24 04          	mov    %edx,0x4(%esp)
80105761:	89 04 24             	mov    %eax,(%esp)
80105764:	e8 c7 fe ff ff       	call   80105630 <fetchstr>
}
80105769:	c9                   	leave  
8010576a:	c3                   	ret    

8010576b <syscall>:
[SYS_disableSwapping]	sys_disableSwapping,
};

void
syscall(void)
{
8010576b:	55                   	push   %ebp
8010576c:	89 e5                	mov    %esp,%ebp
8010576e:	53                   	push   %ebx
8010576f:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->tf->eax;
80105772:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105778:	8b 40 18             	mov    0x18(%eax),%eax
8010577b:	8b 40 1c             	mov    0x1c(%eax),%eax
8010577e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num >= 0 && num < SYS_open && syscalls[num]) {
80105781:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105785:	78 2e                	js     801057b5 <syscall+0x4a>
80105787:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
8010578b:	7f 28                	jg     801057b5 <syscall+0x4a>
8010578d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105790:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
80105797:	85 c0                	test   %eax,%eax
80105799:	74 1a                	je     801057b5 <syscall+0x4a>
    proc->tf->eax = syscalls[num]();
8010579b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801057a1:	8b 58 18             	mov    0x18(%eax),%ebx
801057a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057a7:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
801057ae:	ff d0                	call   *%eax
801057b0:	89 43 1c             	mov    %eax,0x1c(%ebx)
801057b3:	eb 73                	jmp    80105828 <syscall+0xbd>
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
801057b5:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
801057b9:	7e 30                	jle    801057eb <syscall+0x80>
801057bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057be:	83 f8 17             	cmp    $0x17,%eax
801057c1:	77 28                	ja     801057eb <syscall+0x80>
801057c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057c6:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
801057cd:	85 c0                	test   %eax,%eax
801057cf:	74 1a                	je     801057eb <syscall+0x80>
    proc->tf->eax = syscalls[num]();
801057d1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801057d7:	8b 58 18             	mov    0x18(%eax),%ebx
801057da:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057dd:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
801057e4:	ff d0                	call   *%eax
801057e6:	89 43 1c             	mov    %eax,0x1c(%ebx)
801057e9:	eb 3d                	jmp    80105828 <syscall+0xbd>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
801057eb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801057f1:	8d 48 6c             	lea    0x6c(%eax),%ecx
801057f4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  if(num >= 0 && num < SYS_open && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
801057fa:	8b 40 10             	mov    0x10(%eax),%eax
801057fd:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105800:	89 54 24 0c          	mov    %edx,0xc(%esp)
80105804:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105808:	89 44 24 04          	mov    %eax,0x4(%esp)
8010580c:	c7 04 24 f8 8c 10 80 	movl   $0x80108cf8,(%esp)
80105813:	e8 89 ab ff ff       	call   801003a1 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
80105818:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010581e:	8b 40 18             	mov    0x18(%eax),%eax
80105821:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
80105828:	83 c4 24             	add    $0x24,%esp
8010582b:	5b                   	pop    %ebx
8010582c:	5d                   	pop    %ebp
8010582d:	c3                   	ret    
	...

80105830 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
80105830:	55                   	push   %ebp
80105831:	89 e5                	mov    %esp,%ebp
80105833:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
80105836:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105839:	89 44 24 04          	mov    %eax,0x4(%esp)
8010583d:	8b 45 08             	mov    0x8(%ebp),%eax
80105840:	89 04 24             	mov    %eax,(%esp)
80105843:	e8 46 fe ff ff       	call   8010568e <argint>
80105848:	85 c0                	test   %eax,%eax
8010584a:	79 07                	jns    80105853 <argfd+0x23>
    return -1;
8010584c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105851:	eb 50                	jmp    801058a3 <argfd+0x73>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
80105853:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105856:	85 c0                	test   %eax,%eax
80105858:	78 21                	js     8010587b <argfd+0x4b>
8010585a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010585d:	83 f8 0f             	cmp    $0xf,%eax
80105860:	7f 19                	jg     8010587b <argfd+0x4b>
80105862:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105868:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010586b:	83 c2 08             	add    $0x8,%edx
8010586e:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105872:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105875:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105879:	75 07                	jne    80105882 <argfd+0x52>
    return -1;
8010587b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105880:	eb 21                	jmp    801058a3 <argfd+0x73>
  if(pfd)
80105882:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80105886:	74 08                	je     80105890 <argfd+0x60>
    *pfd = fd;
80105888:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010588b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010588e:	89 10                	mov    %edx,(%eax)
  if(pf)
80105890:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105894:	74 08                	je     8010589e <argfd+0x6e>
    *pf = f;
80105896:	8b 45 10             	mov    0x10(%ebp),%eax
80105899:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010589c:	89 10                	mov    %edx,(%eax)
  return 0;
8010589e:	b8 00 00 00 00       	mov    $0x0,%eax
}
801058a3:	c9                   	leave  
801058a4:	c3                   	ret    

801058a5 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
801058a5:	55                   	push   %ebp
801058a6:	89 e5                	mov    %esp,%ebp
801058a8:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
801058ab:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801058b2:	eb 30                	jmp    801058e4 <fdalloc+0x3f>
    if(proc->ofile[fd] == 0){
801058b4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801058ba:	8b 55 fc             	mov    -0x4(%ebp),%edx
801058bd:	83 c2 08             	add    $0x8,%edx
801058c0:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801058c4:	85 c0                	test   %eax,%eax
801058c6:	75 18                	jne    801058e0 <fdalloc+0x3b>
      proc->ofile[fd] = f;
801058c8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801058ce:	8b 55 fc             	mov    -0x4(%ebp),%edx
801058d1:	8d 4a 08             	lea    0x8(%edx),%ecx
801058d4:	8b 55 08             	mov    0x8(%ebp),%edx
801058d7:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
801058db:	8b 45 fc             	mov    -0x4(%ebp),%eax
801058de:	eb 0f                	jmp    801058ef <fdalloc+0x4a>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
801058e0:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801058e4:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
801058e8:	7e ca                	jle    801058b4 <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
801058ea:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801058ef:	c9                   	leave  
801058f0:	c3                   	ret    

801058f1 <sys_dup>:

int
sys_dup(void)
{
801058f1:	55                   	push   %ebp
801058f2:	89 e5                	mov    %esp,%ebp
801058f4:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
801058f7:	8d 45 f0             	lea    -0x10(%ebp),%eax
801058fa:	89 44 24 08          	mov    %eax,0x8(%esp)
801058fe:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105905:	00 
80105906:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010590d:	e8 1e ff ff ff       	call   80105830 <argfd>
80105912:	85 c0                	test   %eax,%eax
80105914:	79 07                	jns    8010591d <sys_dup+0x2c>
    return -1;
80105916:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010591b:	eb 29                	jmp    80105946 <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
8010591d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105920:	89 04 24             	mov    %eax,(%esp)
80105923:	e8 7d ff ff ff       	call   801058a5 <fdalloc>
80105928:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010592b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010592f:	79 07                	jns    80105938 <sys_dup+0x47>
    return -1;
80105931:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105936:	eb 0e                	jmp    80105946 <sys_dup+0x55>
  filedup(f);
80105938:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010593b:	89 04 24             	mov    %eax,(%esp)
8010593e:	e8 39 b6 ff ff       	call   80100f7c <filedup>
  return fd;
80105943:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80105946:	c9                   	leave  
80105947:	c3                   	ret    

80105948 <sys_read>:

int
sys_read(void)
{
80105948:	55                   	push   %ebp
80105949:	89 e5                	mov    %esp,%ebp
8010594b:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
8010594e:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105951:	89 44 24 08          	mov    %eax,0x8(%esp)
80105955:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010595c:	00 
8010595d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105964:	e8 c7 fe ff ff       	call   80105830 <argfd>
80105969:	85 c0                	test   %eax,%eax
8010596b:	78 35                	js     801059a2 <sys_read+0x5a>
8010596d:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105970:	89 44 24 04          	mov    %eax,0x4(%esp)
80105974:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
8010597b:	e8 0e fd ff ff       	call   8010568e <argint>
80105980:	85 c0                	test   %eax,%eax
80105982:	78 1e                	js     801059a2 <sys_read+0x5a>
80105984:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105987:	89 44 24 08          	mov    %eax,0x8(%esp)
8010598b:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010598e:	89 44 24 04          	mov    %eax,0x4(%esp)
80105992:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105999:	e8 28 fd ff ff       	call   801056c6 <argptr>
8010599e:	85 c0                	test   %eax,%eax
801059a0:	79 07                	jns    801059a9 <sys_read+0x61>
    return -1;
801059a2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801059a7:	eb 19                	jmp    801059c2 <sys_read+0x7a>
  return fileread(f, p, n);
801059a9:	8b 4d f0             	mov    -0x10(%ebp),%ecx
801059ac:	8b 55 ec             	mov    -0x14(%ebp),%edx
801059af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059b2:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801059b6:	89 54 24 04          	mov    %edx,0x4(%esp)
801059ba:	89 04 24             	mov    %eax,(%esp)
801059bd:	e8 27 b7 ff ff       	call   801010e9 <fileread>
}
801059c2:	c9                   	leave  
801059c3:	c3                   	ret    

801059c4 <sys_write>:

int
sys_write(void)
{
801059c4:	55                   	push   %ebp
801059c5:	89 e5                	mov    %esp,%ebp
801059c7:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801059ca:	8d 45 f4             	lea    -0xc(%ebp),%eax
801059cd:	89 44 24 08          	mov    %eax,0x8(%esp)
801059d1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801059d8:	00 
801059d9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801059e0:	e8 4b fe ff ff       	call   80105830 <argfd>
801059e5:	85 c0                	test   %eax,%eax
801059e7:	78 35                	js     80105a1e <sys_write+0x5a>
801059e9:	8d 45 f0             	lea    -0x10(%ebp),%eax
801059ec:	89 44 24 04          	mov    %eax,0x4(%esp)
801059f0:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801059f7:	e8 92 fc ff ff       	call   8010568e <argint>
801059fc:	85 c0                	test   %eax,%eax
801059fe:	78 1e                	js     80105a1e <sys_write+0x5a>
80105a00:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a03:	89 44 24 08          	mov    %eax,0x8(%esp)
80105a07:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105a0a:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a0e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105a15:	e8 ac fc ff ff       	call   801056c6 <argptr>
80105a1a:	85 c0                	test   %eax,%eax
80105a1c:	79 07                	jns    80105a25 <sys_write+0x61>
    return -1;
80105a1e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105a23:	eb 19                	jmp    80105a3e <sys_write+0x7a>
  return filewrite(f, p, n);
80105a25:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80105a28:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105a2b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a2e:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105a32:	89 54 24 04          	mov    %edx,0x4(%esp)
80105a36:	89 04 24             	mov    %eax,(%esp)
80105a39:	e8 67 b7 ff ff       	call   801011a5 <filewrite>
}
80105a3e:	c9                   	leave  
80105a3f:	c3                   	ret    

80105a40 <sys_close>:

int
sys_close(void)
{
80105a40:	55                   	push   %ebp
80105a41:	89 e5                	mov    %esp,%ebp
80105a43:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
80105a46:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105a49:	89 44 24 08          	mov    %eax,0x8(%esp)
80105a4d:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105a50:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a54:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105a5b:	e8 d0 fd ff ff       	call   80105830 <argfd>
80105a60:	85 c0                	test   %eax,%eax
80105a62:	79 07                	jns    80105a6b <sys_close+0x2b>
    return -1;
80105a64:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105a69:	eb 24                	jmp    80105a8f <sys_close+0x4f>
  proc->ofile[fd] = 0;
80105a6b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105a71:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105a74:	83 c2 08             	add    $0x8,%edx
80105a77:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80105a7e:	00 
  fileclose(f);
80105a7f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a82:	89 04 24             	mov    %eax,(%esp)
80105a85:	e8 3a b5 ff ff       	call   80100fc4 <fileclose>
  return 0;
80105a8a:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105a8f:	c9                   	leave  
80105a90:	c3                   	ret    

80105a91 <sys_fstat>:

int
sys_fstat(void)
{
80105a91:	55                   	push   %ebp
80105a92:	89 e5                	mov    %esp,%ebp
80105a94:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
80105a97:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105a9a:	89 44 24 08          	mov    %eax,0x8(%esp)
80105a9e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105aa5:	00 
80105aa6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105aad:	e8 7e fd ff ff       	call   80105830 <argfd>
80105ab2:	85 c0                	test   %eax,%eax
80105ab4:	78 1f                	js     80105ad5 <sys_fstat+0x44>
80105ab6:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80105abd:	00 
80105abe:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105ac1:	89 44 24 04          	mov    %eax,0x4(%esp)
80105ac5:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105acc:	e8 f5 fb ff ff       	call   801056c6 <argptr>
80105ad1:	85 c0                	test   %eax,%eax
80105ad3:	79 07                	jns    80105adc <sys_fstat+0x4b>
    return -1;
80105ad5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105ada:	eb 12                	jmp    80105aee <sys_fstat+0x5d>
  return filestat(f, st);
80105adc:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105adf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ae2:	89 54 24 04          	mov    %edx,0x4(%esp)
80105ae6:	89 04 24             	mov    %eax,(%esp)
80105ae9:	e8 ac b5 ff ff       	call   8010109a <filestat>
}
80105aee:	c9                   	leave  
80105aef:	c3                   	ret    

80105af0 <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
80105af0:	55                   	push   %ebp
80105af1:	89 e5                	mov    %esp,%ebp
80105af3:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
80105af6:	8d 45 d8             	lea    -0x28(%ebp),%eax
80105af9:	89 44 24 04          	mov    %eax,0x4(%esp)
80105afd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105b04:	e8 1f fc ff ff       	call   80105728 <argstr>
80105b09:	85 c0                	test   %eax,%eax
80105b0b:	78 17                	js     80105b24 <sys_link+0x34>
80105b0d:	8d 45 dc             	lea    -0x24(%ebp),%eax
80105b10:	89 44 24 04          	mov    %eax,0x4(%esp)
80105b14:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105b1b:	e8 08 fc ff ff       	call   80105728 <argstr>
80105b20:	85 c0                	test   %eax,%eax
80105b22:	79 0a                	jns    80105b2e <sys_link+0x3e>
    return -1;
80105b24:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105b29:	e9 3c 01 00 00       	jmp    80105c6a <sys_link+0x17a>
  if((ip = namei(old)) == 0)
80105b2e:	8b 45 d8             	mov    -0x28(%ebp),%eax
80105b31:	89 04 24             	mov    %eax,(%esp)
80105b34:	e8 d1 c8 ff ff       	call   8010240a <namei>
80105b39:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105b3c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105b40:	75 0a                	jne    80105b4c <sys_link+0x5c>
    return -1;
80105b42:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105b47:	e9 1e 01 00 00       	jmp    80105c6a <sys_link+0x17a>

  begin_trans();
80105b4c:	e8 d8 d6 ff ff       	call   80103229 <begin_trans>

  ilock(ip);
80105b51:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b54:	89 04 24             	mov    %eax,(%esp)
80105b57:	e8 0c bd ff ff       	call   80101868 <ilock>
  if(ip->type == T_DIR){
80105b5c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b5f:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105b63:	66 83 f8 01          	cmp    $0x1,%ax
80105b67:	75 1a                	jne    80105b83 <sys_link+0x93>
    iunlockput(ip);
80105b69:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b6c:	89 04 24             	mov    %eax,(%esp)
80105b6f:	e8 78 bf ff ff       	call   80101aec <iunlockput>
    commit_trans();
80105b74:	e8 f9 d6 ff ff       	call   80103272 <commit_trans>
    return -1;
80105b79:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105b7e:	e9 e7 00 00 00       	jmp    80105c6a <sys_link+0x17a>
  }

  ip->nlink++;
80105b83:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b86:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105b8a:	8d 50 01             	lea    0x1(%eax),%edx
80105b8d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b90:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80105b94:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b97:	89 04 24             	mov    %eax,(%esp)
80105b9a:	e8 0d bb ff ff       	call   801016ac <iupdate>
  iunlock(ip);
80105b9f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ba2:	89 04 24             	mov    %eax,(%esp)
80105ba5:	e8 0c be ff ff       	call   801019b6 <iunlock>

  if((dp = nameiparent(new, name)) == 0)
80105baa:	8b 45 dc             	mov    -0x24(%ebp),%eax
80105bad:	8d 55 e2             	lea    -0x1e(%ebp),%edx
80105bb0:	89 54 24 04          	mov    %edx,0x4(%esp)
80105bb4:	89 04 24             	mov    %eax,(%esp)
80105bb7:	e8 70 c8 ff ff       	call   8010242c <nameiparent>
80105bbc:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105bbf:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105bc3:	74 68                	je     80105c2d <sys_link+0x13d>
    goto bad;
  ilock(dp);
80105bc5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105bc8:	89 04 24             	mov    %eax,(%esp)
80105bcb:	e8 98 bc ff ff       	call   80101868 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
80105bd0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105bd3:	8b 10                	mov    (%eax),%edx
80105bd5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105bd8:	8b 00                	mov    (%eax),%eax
80105bda:	39 c2                	cmp    %eax,%edx
80105bdc:	75 20                	jne    80105bfe <sys_link+0x10e>
80105bde:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105be1:	8b 40 04             	mov    0x4(%eax),%eax
80105be4:	89 44 24 08          	mov    %eax,0x8(%esp)
80105be8:	8d 45 e2             	lea    -0x1e(%ebp),%eax
80105beb:	89 44 24 04          	mov    %eax,0x4(%esp)
80105bef:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105bf2:	89 04 24             	mov    %eax,(%esp)
80105bf5:	e8 4f c5 ff ff       	call   80102149 <dirlink>
80105bfa:	85 c0                	test   %eax,%eax
80105bfc:	79 0d                	jns    80105c0b <sys_link+0x11b>
    iunlockput(dp);
80105bfe:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c01:	89 04 24             	mov    %eax,(%esp)
80105c04:	e8 e3 be ff ff       	call   80101aec <iunlockput>
    goto bad;
80105c09:	eb 23                	jmp    80105c2e <sys_link+0x13e>
  }
  iunlockput(dp);
80105c0b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c0e:	89 04 24             	mov    %eax,(%esp)
80105c11:	e8 d6 be ff ff       	call   80101aec <iunlockput>
  iput(ip);
80105c16:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c19:	89 04 24             	mov    %eax,(%esp)
80105c1c:	e8 fa bd ff ff       	call   80101a1b <iput>

  commit_trans();
80105c21:	e8 4c d6 ff ff       	call   80103272 <commit_trans>

  return 0;
80105c26:	b8 00 00 00 00       	mov    $0x0,%eax
80105c2b:	eb 3d                	jmp    80105c6a <sys_link+0x17a>
  ip->nlink++;
  iupdate(ip);
  iunlock(ip);

  if((dp = nameiparent(new, name)) == 0)
    goto bad;
80105c2d:	90                   	nop
  commit_trans();

  return 0;

bad:
  ilock(ip);
80105c2e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c31:	89 04 24             	mov    %eax,(%esp)
80105c34:	e8 2f bc ff ff       	call   80101868 <ilock>
  ip->nlink--;
80105c39:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c3c:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105c40:	8d 50 ff             	lea    -0x1(%eax),%edx
80105c43:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c46:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80105c4a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c4d:	89 04 24             	mov    %eax,(%esp)
80105c50:	e8 57 ba ff ff       	call   801016ac <iupdate>
  iunlockput(ip);
80105c55:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c58:	89 04 24             	mov    %eax,(%esp)
80105c5b:	e8 8c be ff ff       	call   80101aec <iunlockput>
  commit_trans();
80105c60:	e8 0d d6 ff ff       	call   80103272 <commit_trans>
  return -1;
80105c65:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105c6a:	c9                   	leave  
80105c6b:	c3                   	ret    

80105c6c <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
80105c6c:	55                   	push   %ebp
80105c6d:	89 e5                	mov    %esp,%ebp
80105c6f:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80105c72:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
80105c79:	eb 4b                	jmp    80105cc6 <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80105c7b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c7e:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80105c85:	00 
80105c86:	89 44 24 08          	mov    %eax,0x8(%esp)
80105c8a:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105c8d:	89 44 24 04          	mov    %eax,0x4(%esp)
80105c91:	8b 45 08             	mov    0x8(%ebp),%eax
80105c94:	89 04 24             	mov    %eax,(%esp)
80105c97:	e8 c2 c0 ff ff       	call   80101d5e <readi>
80105c9c:	83 f8 10             	cmp    $0x10,%eax
80105c9f:	74 0c                	je     80105cad <isdirempty+0x41>
      panic("isdirempty: readi");
80105ca1:	c7 04 24 14 8d 10 80 	movl   $0x80108d14,(%esp)
80105ca8:	e8 90 a8 ff ff       	call   8010053d <panic>
    if(de.inum != 0)
80105cad:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
80105cb1:	66 85 c0             	test   %ax,%ax
80105cb4:	74 07                	je     80105cbd <isdirempty+0x51>
      return 0;
80105cb6:	b8 00 00 00 00       	mov    $0x0,%eax
80105cbb:	eb 1b                	jmp    80105cd8 <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80105cbd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105cc0:	83 c0 10             	add    $0x10,%eax
80105cc3:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105cc6:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105cc9:	8b 45 08             	mov    0x8(%ebp),%eax
80105ccc:	8b 40 18             	mov    0x18(%eax),%eax
80105ccf:	39 c2                	cmp    %eax,%edx
80105cd1:	72 a8                	jb     80105c7b <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
80105cd3:	b8 01 00 00 00       	mov    $0x1,%eax
}
80105cd8:	c9                   	leave  
80105cd9:	c3                   	ret    

80105cda <sys_unlink>:

//PAGEBREAK!
int
sys_unlink(void)
{
80105cda:	55                   	push   %ebp
80105cdb:	89 e5                	mov    %esp,%ebp
80105cdd:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
80105ce0:	8d 45 cc             	lea    -0x34(%ebp),%eax
80105ce3:	89 44 24 04          	mov    %eax,0x4(%esp)
80105ce7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105cee:	e8 35 fa ff ff       	call   80105728 <argstr>
80105cf3:	85 c0                	test   %eax,%eax
80105cf5:	79 0a                	jns    80105d01 <sys_unlink+0x27>
    return -1;
80105cf7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105cfc:	e9 aa 01 00 00       	jmp    80105eab <sys_unlink+0x1d1>
  if((dp = nameiparent(path, name)) == 0)
80105d01:	8b 45 cc             	mov    -0x34(%ebp),%eax
80105d04:	8d 55 d2             	lea    -0x2e(%ebp),%edx
80105d07:	89 54 24 04          	mov    %edx,0x4(%esp)
80105d0b:	89 04 24             	mov    %eax,(%esp)
80105d0e:	e8 19 c7 ff ff       	call   8010242c <nameiparent>
80105d13:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105d16:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105d1a:	75 0a                	jne    80105d26 <sys_unlink+0x4c>
    return -1;
80105d1c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105d21:	e9 85 01 00 00       	jmp    80105eab <sys_unlink+0x1d1>

  begin_trans();
80105d26:	e8 fe d4 ff ff       	call   80103229 <begin_trans>

  ilock(dp);
80105d2b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d2e:	89 04 24             	mov    %eax,(%esp)
80105d31:	e8 32 bb ff ff       	call   80101868 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80105d36:	c7 44 24 04 26 8d 10 	movl   $0x80108d26,0x4(%esp)
80105d3d:	80 
80105d3e:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105d41:	89 04 24             	mov    %eax,(%esp)
80105d44:	e8 16 c3 ff ff       	call   8010205f <namecmp>
80105d49:	85 c0                	test   %eax,%eax
80105d4b:	0f 84 45 01 00 00    	je     80105e96 <sys_unlink+0x1bc>
80105d51:	c7 44 24 04 28 8d 10 	movl   $0x80108d28,0x4(%esp)
80105d58:	80 
80105d59:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105d5c:	89 04 24             	mov    %eax,(%esp)
80105d5f:	e8 fb c2 ff ff       	call   8010205f <namecmp>
80105d64:	85 c0                	test   %eax,%eax
80105d66:	0f 84 2a 01 00 00    	je     80105e96 <sys_unlink+0x1bc>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
80105d6c:	8d 45 c8             	lea    -0x38(%ebp),%eax
80105d6f:	89 44 24 08          	mov    %eax,0x8(%esp)
80105d73:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105d76:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d7a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d7d:	89 04 24             	mov    %eax,(%esp)
80105d80:	e8 fc c2 ff ff       	call   80102081 <dirlookup>
80105d85:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105d88:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105d8c:	0f 84 03 01 00 00    	je     80105e95 <sys_unlink+0x1bb>
    goto bad;
  ilock(ip);
80105d92:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d95:	89 04 24             	mov    %eax,(%esp)
80105d98:	e8 cb ba ff ff       	call   80101868 <ilock>

  if(ip->nlink < 1)
80105d9d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105da0:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105da4:	66 85 c0             	test   %ax,%ax
80105da7:	7f 0c                	jg     80105db5 <sys_unlink+0xdb>
    panic("unlink: nlink < 1");
80105da9:	c7 04 24 2b 8d 10 80 	movl   $0x80108d2b,(%esp)
80105db0:	e8 88 a7 ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80105db5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105db8:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105dbc:	66 83 f8 01          	cmp    $0x1,%ax
80105dc0:	75 1f                	jne    80105de1 <sys_unlink+0x107>
80105dc2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105dc5:	89 04 24             	mov    %eax,(%esp)
80105dc8:	e8 9f fe ff ff       	call   80105c6c <isdirempty>
80105dcd:	85 c0                	test   %eax,%eax
80105dcf:	75 10                	jne    80105de1 <sys_unlink+0x107>
    iunlockput(ip);
80105dd1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105dd4:	89 04 24             	mov    %eax,(%esp)
80105dd7:	e8 10 bd ff ff       	call   80101aec <iunlockput>
    goto bad;
80105ddc:	e9 b5 00 00 00       	jmp    80105e96 <sys_unlink+0x1bc>
  }

  memset(&de, 0, sizeof(de));
80105de1:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80105de8:	00 
80105de9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105df0:	00 
80105df1:	8d 45 e0             	lea    -0x20(%ebp),%eax
80105df4:	89 04 24             	mov    %eax,(%esp)
80105df7:	e8 42 f5 ff ff       	call   8010533e <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80105dfc:	8b 45 c8             	mov    -0x38(%ebp),%eax
80105dff:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80105e06:	00 
80105e07:	89 44 24 08          	mov    %eax,0x8(%esp)
80105e0b:	8d 45 e0             	lea    -0x20(%ebp),%eax
80105e0e:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e12:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e15:	89 04 24             	mov    %eax,(%esp)
80105e18:	e8 ac c0 ff ff       	call   80101ec9 <writei>
80105e1d:	83 f8 10             	cmp    $0x10,%eax
80105e20:	74 0c                	je     80105e2e <sys_unlink+0x154>
    panic("unlink: writei");
80105e22:	c7 04 24 3d 8d 10 80 	movl   $0x80108d3d,(%esp)
80105e29:	e8 0f a7 ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR){
80105e2e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e31:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105e35:	66 83 f8 01          	cmp    $0x1,%ax
80105e39:	75 1c                	jne    80105e57 <sys_unlink+0x17d>
    dp->nlink--;
80105e3b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e3e:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105e42:	8d 50 ff             	lea    -0x1(%eax),%edx
80105e45:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e48:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80105e4c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e4f:	89 04 24             	mov    %eax,(%esp)
80105e52:	e8 55 b8 ff ff       	call   801016ac <iupdate>
  }
  iunlockput(dp);
80105e57:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e5a:	89 04 24             	mov    %eax,(%esp)
80105e5d:	e8 8a bc ff ff       	call   80101aec <iunlockput>

  ip->nlink--;
80105e62:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e65:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105e69:	8d 50 ff             	lea    -0x1(%eax),%edx
80105e6c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e6f:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80105e73:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e76:	89 04 24             	mov    %eax,(%esp)
80105e79:	e8 2e b8 ff ff       	call   801016ac <iupdate>
  iunlockput(ip);
80105e7e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e81:	89 04 24             	mov    %eax,(%esp)
80105e84:	e8 63 bc ff ff       	call   80101aec <iunlockput>

  commit_trans();
80105e89:	e8 e4 d3 ff ff       	call   80103272 <commit_trans>

  return 0;
80105e8e:	b8 00 00 00 00       	mov    $0x0,%eax
80105e93:	eb 16                	jmp    80105eab <sys_unlink+0x1d1>
  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    goto bad;
80105e95:	90                   	nop
  commit_trans();

  return 0;

bad:
  iunlockput(dp);
80105e96:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e99:	89 04 24             	mov    %eax,(%esp)
80105e9c:	e8 4b bc ff ff       	call   80101aec <iunlockput>
  commit_trans();
80105ea1:	e8 cc d3 ff ff       	call   80103272 <commit_trans>
  return -1;
80105ea6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105eab:	c9                   	leave  
80105eac:	c3                   	ret    

80105ead <create>:

static struct inode*
create(char *path, short type, short major, short minor)
{
80105ead:	55                   	push   %ebp
80105eae:	89 e5                	mov    %esp,%ebp
80105eb0:	83 ec 48             	sub    $0x48,%esp
80105eb3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80105eb6:	8b 55 10             	mov    0x10(%ebp),%edx
80105eb9:	8b 45 14             	mov    0x14(%ebp),%eax
80105ebc:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
80105ec0:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
80105ec4:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];
  if((dp = nameiparent(path, name)) == 0)
80105ec8:	8d 45 de             	lea    -0x22(%ebp),%eax
80105ecb:	89 44 24 04          	mov    %eax,0x4(%esp)
80105ecf:	8b 45 08             	mov    0x8(%ebp),%eax
80105ed2:	89 04 24             	mov    %eax,(%esp)
80105ed5:	e8 52 c5 ff ff       	call   8010242c <nameiparent>
80105eda:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105edd:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105ee1:	75 0a                	jne    80105eed <create+0x40>
    return 0;
80105ee3:	b8 00 00 00 00       	mov    $0x0,%eax
80105ee8:	e9 7e 01 00 00       	jmp    8010606b <create+0x1be>
  ilock(dp);
80105eed:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ef0:	89 04 24             	mov    %eax,(%esp)
80105ef3:	e8 70 b9 ff ff       	call   80101868 <ilock>
  if((ip = dirlookup(dp, name, &off)) != 0){
80105ef8:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105efb:	89 44 24 08          	mov    %eax,0x8(%esp)
80105eff:	8d 45 de             	lea    -0x22(%ebp),%eax
80105f02:	89 44 24 04          	mov    %eax,0x4(%esp)
80105f06:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f09:	89 04 24             	mov    %eax,(%esp)
80105f0c:	e8 70 c1 ff ff       	call   80102081 <dirlookup>
80105f11:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105f14:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105f18:	74 47                	je     80105f61 <create+0xb4>
    iunlockput(dp);
80105f1a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f1d:	89 04 24             	mov    %eax,(%esp)
80105f20:	e8 c7 bb ff ff       	call   80101aec <iunlockput>
    ilock(ip);
80105f25:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f28:	89 04 24             	mov    %eax,(%esp)
80105f2b:	e8 38 b9 ff ff       	call   80101868 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
80105f30:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
80105f35:	75 15                	jne    80105f4c <create+0x9f>
80105f37:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f3a:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105f3e:	66 83 f8 02          	cmp    $0x2,%ax
80105f42:	75 08                	jne    80105f4c <create+0x9f>
      return ip;
80105f44:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f47:	e9 1f 01 00 00       	jmp    8010606b <create+0x1be>
    iunlockput(ip);
80105f4c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f4f:	89 04 24             	mov    %eax,(%esp)
80105f52:	e8 95 bb ff ff       	call   80101aec <iunlockput>
    return 0;
80105f57:	b8 00 00 00 00       	mov    $0x0,%eax
80105f5c:	e9 0a 01 00 00       	jmp    8010606b <create+0x1be>
  }
  if((ip = ialloc(dp->dev, type)) == 0)
80105f61:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
80105f65:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f68:	8b 00                	mov    (%eax),%eax
80105f6a:	89 54 24 04          	mov    %edx,0x4(%esp)
80105f6e:	89 04 24             	mov    %eax,(%esp)
80105f71:	e8 59 b6 ff ff       	call   801015cf <ialloc>
80105f76:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105f79:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105f7d:	75 0c                	jne    80105f8b <create+0xde>
    panic("create: ialloc");
80105f7f:	c7 04 24 4c 8d 10 80 	movl   $0x80108d4c,(%esp)
80105f86:	e8 b2 a5 ff ff       	call   8010053d <panic>
  ilock(ip);
80105f8b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f8e:	89 04 24             	mov    %eax,(%esp)
80105f91:	e8 d2 b8 ff ff       	call   80101868 <ilock>
  ip->major = major;
80105f96:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f99:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
80105f9d:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
80105fa1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105fa4:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
80105fa8:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
80105fac:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105faf:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
80105fb5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105fb8:	89 04 24             	mov    %eax,(%esp)
80105fbb:	e8 ec b6 ff ff       	call   801016ac <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
80105fc0:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
80105fc5:	75 6a                	jne    80106031 <create+0x184>
    dp->nlink++;  // for ".."
80105fc7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105fca:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105fce:	8d 50 01             	lea    0x1(%eax),%edx
80105fd1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105fd4:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80105fd8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105fdb:	89 04 24             	mov    %eax,(%esp)
80105fde:	e8 c9 b6 ff ff       	call   801016ac <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80105fe3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105fe6:	8b 40 04             	mov    0x4(%eax),%eax
80105fe9:	89 44 24 08          	mov    %eax,0x8(%esp)
80105fed:	c7 44 24 04 26 8d 10 	movl   $0x80108d26,0x4(%esp)
80105ff4:	80 
80105ff5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ff8:	89 04 24             	mov    %eax,(%esp)
80105ffb:	e8 49 c1 ff ff       	call   80102149 <dirlink>
80106000:	85 c0                	test   %eax,%eax
80106002:	78 21                	js     80106025 <create+0x178>
80106004:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106007:	8b 40 04             	mov    0x4(%eax),%eax
8010600a:	89 44 24 08          	mov    %eax,0x8(%esp)
8010600e:	c7 44 24 04 28 8d 10 	movl   $0x80108d28,0x4(%esp)
80106015:	80 
80106016:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106019:	89 04 24             	mov    %eax,(%esp)
8010601c:	e8 28 c1 ff ff       	call   80102149 <dirlink>
80106021:	85 c0                	test   %eax,%eax
80106023:	79 0c                	jns    80106031 <create+0x184>
      panic("create dots");
80106025:	c7 04 24 5b 8d 10 80 	movl   $0x80108d5b,(%esp)
8010602c:	e8 0c a5 ff ff       	call   8010053d <panic>
  }
  if(dirlink(dp, name, ip->inum) < 0)
80106031:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106034:	8b 40 04             	mov    0x4(%eax),%eax
80106037:	89 44 24 08          	mov    %eax,0x8(%esp)
8010603b:	8d 45 de             	lea    -0x22(%ebp),%eax
8010603e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106042:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106045:	89 04 24             	mov    %eax,(%esp)
80106048:	e8 fc c0 ff ff       	call   80102149 <dirlink>
8010604d:	85 c0                	test   %eax,%eax
8010604f:	79 0c                	jns    8010605d <create+0x1b0>
    panic("create: dirlink");
80106051:	c7 04 24 67 8d 10 80 	movl   $0x80108d67,(%esp)
80106058:	e8 e0 a4 ff ff       	call   8010053d <panic>
  iunlockput(dp);
8010605d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106060:	89 04 24             	mov    %eax,(%esp)
80106063:	e8 84 ba ff ff       	call   80101aec <iunlockput>

  return ip;
80106068:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
8010606b:	c9                   	leave  
8010606c:	c3                   	ret    

8010606d <fileopen>:

struct file*
fileopen(char *path, int omode)
{
8010606d:	55                   	push   %ebp
8010606e:	89 e5                	mov    %esp,%ebp
80106070:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  struct inode *ip;

  if(omode & O_CREATE){
80106073:	8b 45 0c             	mov    0xc(%ebp),%eax
80106076:	25 00 02 00 00       	and    $0x200,%eax
8010607b:	85 c0                	test   %eax,%eax
8010607d:	74 40                	je     801060bf <fileopen+0x52>
    begin_trans();
8010607f:	e8 a5 d1 ff ff       	call   80103229 <begin_trans>
    ip = create(path, T_FILE, 0, 0);
80106084:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
8010608b:	00 
8010608c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106093:	00 
80106094:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
8010609b:	00 
8010609c:	8b 45 08             	mov    0x8(%ebp),%eax
8010609f:	89 04 24             	mov    %eax,(%esp)
801060a2:	e8 06 fe ff ff       	call   80105ead <create>
801060a7:	89 45 f4             	mov    %eax,-0xc(%ebp)
    commit_trans();
801060aa:	e8 c3 d1 ff ff       	call   80103272 <commit_trans>
    if(ip == 0)
801060af:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801060b3:	75 5b                	jne    80106110 <fileopen+0xa3>
      return 0;
801060b5:	b8 00 00 00 00       	mov    $0x0,%eax
801060ba:	e9 f9 00 00 00       	jmp    801061b8 <fileopen+0x14b>
  } else {
    if((ip = namei(path)) == 0)
801060bf:	8b 45 08             	mov    0x8(%ebp),%eax
801060c2:	89 04 24             	mov    %eax,(%esp)
801060c5:	e8 40 c3 ff ff       	call   8010240a <namei>
801060ca:	89 45 f4             	mov    %eax,-0xc(%ebp)
801060cd:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801060d1:	75 0a                	jne    801060dd <fileopen+0x70>
      return 0;
801060d3:	b8 00 00 00 00       	mov    $0x0,%eax
801060d8:	e9 db 00 00 00       	jmp    801061b8 <fileopen+0x14b>
    ilock(ip);
801060dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801060e0:	89 04 24             	mov    %eax,(%esp)
801060e3:	e8 80 b7 ff ff       	call   80101868 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
801060e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801060eb:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801060ef:	66 83 f8 01          	cmp    $0x1,%ax
801060f3:	75 1b                	jne    80106110 <fileopen+0xa3>
801060f5:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801060f9:	74 15                	je     80106110 <fileopen+0xa3>
      iunlockput(ip);
801060fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801060fe:	89 04 24             	mov    %eax,(%esp)
80106101:	e8 e6 b9 ff ff       	call   80101aec <iunlockput>
      return 0;
80106106:	b8 00 00 00 00       	mov    $0x0,%eax
8010610b:	e9 a8 00 00 00       	jmp    801061b8 <fileopen+0x14b>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80106110:	e8 07 ae ff ff       	call   80100f1c <filealloc>
80106115:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106118:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010611c:	74 14                	je     80106132 <fileopen+0xc5>
8010611e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106121:	89 04 24             	mov    %eax,(%esp)
80106124:	e8 7c f7 ff ff       	call   801058a5 <fdalloc>
80106129:	89 45 ec             	mov    %eax,-0x14(%ebp)
8010612c:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80106130:	79 23                	jns    80106155 <fileopen+0xe8>
    if(f)
80106132:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106136:	74 0b                	je     80106143 <fileopen+0xd6>
      fileclose(f);
80106138:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010613b:	89 04 24             	mov    %eax,(%esp)
8010613e:	e8 81 ae ff ff       	call   80100fc4 <fileclose>
    iunlockput(ip);
80106143:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106146:	89 04 24             	mov    %eax,(%esp)
80106149:	e8 9e b9 ff ff       	call   80101aec <iunlockput>
    return 0;
8010614e:	b8 00 00 00 00       	mov    $0x0,%eax
80106153:	eb 63                	jmp    801061b8 <fileopen+0x14b>
  }
  iunlock(ip);
80106155:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106158:	89 04 24             	mov    %eax,(%esp)
8010615b:	e8 56 b8 ff ff       	call   801019b6 <iunlock>

  f->type = FD_INODE;
80106160:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106163:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80106169:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010616c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010616f:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
80106172:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106175:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
8010617c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010617f:	83 e0 01             	and    $0x1,%eax
80106182:	85 c0                	test   %eax,%eax
80106184:	0f 94 c2             	sete   %dl
80106187:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010618a:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
8010618d:	8b 45 0c             	mov    0xc(%ebp),%eax
80106190:	83 e0 01             	and    $0x1,%eax
80106193:	84 c0                	test   %al,%al
80106195:	75 0a                	jne    801061a1 <fileopen+0x134>
80106197:	8b 45 0c             	mov    0xc(%ebp),%eax
8010619a:	83 e0 02             	and    $0x2,%eax
8010619d:	85 c0                	test   %eax,%eax
8010619f:	74 07                	je     801061a8 <fileopen+0x13b>
801061a1:	b8 01 00 00 00       	mov    $0x1,%eax
801061a6:	eb 05                	jmp    801061ad <fileopen+0x140>
801061a8:	b8 00 00 00 00       	mov    $0x0,%eax
801061ad:	89 c2                	mov    %eax,%edx
801061af:	8b 45 f0             	mov    -0x10(%ebp),%eax
801061b2:	88 50 09             	mov    %dl,0x9(%eax)
  return f;
801061b5:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
801061b8:	c9                   	leave  
801061b9:	c3                   	ret    

801061ba <sys_open>:

int
sys_open(void)
{
801061ba:	55                   	push   %ebp
801061bb:	89 e5                	mov    %esp,%ebp
801061bd:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
801061c0:	8d 45 e8             	lea    -0x18(%ebp),%eax
801061c3:	89 44 24 04          	mov    %eax,0x4(%esp)
801061c7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801061ce:	e8 55 f5 ff ff       	call   80105728 <argstr>
801061d3:	85 c0                	test   %eax,%eax
801061d5:	78 17                	js     801061ee <sys_open+0x34>
801061d7:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801061da:	89 44 24 04          	mov    %eax,0x4(%esp)
801061de:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801061e5:	e8 a4 f4 ff ff       	call   8010568e <argint>
801061ea:	85 c0                	test   %eax,%eax
801061ec:	79 0a                	jns    801061f8 <sys_open+0x3e>
    return -1;
801061ee:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061f3:	e9 46 01 00 00       	jmp    8010633e <sys_open+0x184>
  if(omode & O_CREATE){
801061f8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801061fb:	25 00 02 00 00       	and    $0x200,%eax
80106200:	85 c0                	test   %eax,%eax
80106202:	74 40                	je     80106244 <sys_open+0x8a>
    begin_trans();
80106204:	e8 20 d0 ff ff       	call   80103229 <begin_trans>
    ip = create(path, T_FILE, 0, 0);
80106209:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010620c:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106213:	00 
80106214:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010621b:	00 
8010621c:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80106223:	00 
80106224:	89 04 24             	mov    %eax,(%esp)
80106227:	e8 81 fc ff ff       	call   80105ead <create>
8010622c:	89 45 f4             	mov    %eax,-0xc(%ebp)
    commit_trans();
8010622f:	e8 3e d0 ff ff       	call   80103272 <commit_trans>
    if(ip == 0)
80106234:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106238:	75 5c                	jne    80106296 <sys_open+0xdc>
      return -1;
8010623a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010623f:	e9 fa 00 00 00       	jmp    8010633e <sys_open+0x184>
  } else {
    if((ip = namei(path)) == 0)
80106244:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106247:	89 04 24             	mov    %eax,(%esp)
8010624a:	e8 bb c1 ff ff       	call   8010240a <namei>
8010624f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106252:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106256:	75 0a                	jne    80106262 <sys_open+0xa8>
      return -1;
80106258:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010625d:	e9 dc 00 00 00       	jmp    8010633e <sys_open+0x184>
    ilock(ip);
80106262:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106265:	89 04 24             	mov    %eax,(%esp)
80106268:	e8 fb b5 ff ff       	call   80101868 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
8010626d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106270:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106274:	66 83 f8 01          	cmp    $0x1,%ax
80106278:	75 1c                	jne    80106296 <sys_open+0xdc>
8010627a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010627d:	85 c0                	test   %eax,%eax
8010627f:	74 15                	je     80106296 <sys_open+0xdc>
      iunlockput(ip);
80106281:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106284:	89 04 24             	mov    %eax,(%esp)
80106287:	e8 60 b8 ff ff       	call   80101aec <iunlockput>
      return -1;
8010628c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106291:	e9 a8 00 00 00       	jmp    8010633e <sys_open+0x184>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80106296:	e8 81 ac ff ff       	call   80100f1c <filealloc>
8010629b:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010629e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801062a2:	74 14                	je     801062b8 <sys_open+0xfe>
801062a4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801062a7:	89 04 24             	mov    %eax,(%esp)
801062aa:	e8 f6 f5 ff ff       	call   801058a5 <fdalloc>
801062af:	89 45 ec             	mov    %eax,-0x14(%ebp)
801062b2:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801062b6:	79 23                	jns    801062db <sys_open+0x121>
    if(f)
801062b8:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801062bc:	74 0b                	je     801062c9 <sys_open+0x10f>
      fileclose(f);
801062be:	8b 45 f0             	mov    -0x10(%ebp),%eax
801062c1:	89 04 24             	mov    %eax,(%esp)
801062c4:	e8 fb ac ff ff       	call   80100fc4 <fileclose>
    iunlockput(ip);
801062c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062cc:	89 04 24             	mov    %eax,(%esp)
801062cf:	e8 18 b8 ff ff       	call   80101aec <iunlockput>
    return -1;
801062d4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801062d9:	eb 63                	jmp    8010633e <sys_open+0x184>
  }
  iunlock(ip);
801062db:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062de:	89 04 24             	mov    %eax,(%esp)
801062e1:	e8 d0 b6 ff ff       	call   801019b6 <iunlock>

  f->type = FD_INODE;
801062e6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801062e9:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
801062ef:	8b 45 f0             	mov    -0x10(%ebp),%eax
801062f2:	8b 55 f4             	mov    -0xc(%ebp),%edx
801062f5:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
801062f8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801062fb:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80106302:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106305:	83 e0 01             	and    $0x1,%eax
80106308:	85 c0                	test   %eax,%eax
8010630a:	0f 94 c2             	sete   %dl
8010630d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106310:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80106313:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106316:	83 e0 01             	and    $0x1,%eax
80106319:	84 c0                	test   %al,%al
8010631b:	75 0a                	jne    80106327 <sys_open+0x16d>
8010631d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106320:	83 e0 02             	and    $0x2,%eax
80106323:	85 c0                	test   %eax,%eax
80106325:	74 07                	je     8010632e <sys_open+0x174>
80106327:	b8 01 00 00 00       	mov    $0x1,%eax
8010632c:	eb 05                	jmp    80106333 <sys_open+0x179>
8010632e:	b8 00 00 00 00       	mov    $0x0,%eax
80106333:	89 c2                	mov    %eax,%edx
80106335:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106338:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
8010633b:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
8010633e:	c9                   	leave  
8010633f:	c3                   	ret    

80106340 <sys_mkdir>:

int
sys_mkdir(void)
{
80106340:	55                   	push   %ebp
80106341:	89 e5                	mov    %esp,%ebp
80106343:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_trans();
80106346:	e8 de ce ff ff       	call   80103229 <begin_trans>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
8010634b:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010634e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106352:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106359:	e8 ca f3 ff ff       	call   80105728 <argstr>
8010635e:	85 c0                	test   %eax,%eax
80106360:	78 2c                	js     8010638e <sys_mkdir+0x4e>
80106362:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106365:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
8010636c:	00 
8010636d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106374:	00 
80106375:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010637c:	00 
8010637d:	89 04 24             	mov    %eax,(%esp)
80106380:	e8 28 fb ff ff       	call   80105ead <create>
80106385:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106388:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010638c:	75 0c                	jne    8010639a <sys_mkdir+0x5a>
    commit_trans();
8010638e:	e8 df ce ff ff       	call   80103272 <commit_trans>
    return -1;
80106393:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106398:	eb 15                	jmp    801063af <sys_mkdir+0x6f>
  }
  iunlockput(ip);
8010639a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010639d:	89 04 24             	mov    %eax,(%esp)
801063a0:	e8 47 b7 ff ff       	call   80101aec <iunlockput>
  commit_trans();
801063a5:	e8 c8 ce ff ff       	call   80103272 <commit_trans>
  return 0;
801063aa:	b8 00 00 00 00       	mov    $0x0,%eax
}
801063af:	c9                   	leave  
801063b0:	c3                   	ret    

801063b1 <sys_mknod>:

int
sys_mknod(void)
{
801063b1:	55                   	push   %ebp
801063b2:	89 e5                	mov    %esp,%ebp
801063b4:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
801063b7:	e8 6d ce ff ff       	call   80103229 <begin_trans>
  if((len=argstr(0, &path)) < 0 ||
801063bc:	8d 45 ec             	lea    -0x14(%ebp),%eax
801063bf:	89 44 24 04          	mov    %eax,0x4(%esp)
801063c3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801063ca:	e8 59 f3 ff ff       	call   80105728 <argstr>
801063cf:	89 45 f4             	mov    %eax,-0xc(%ebp)
801063d2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801063d6:	78 5e                	js     80106436 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
801063d8:	8d 45 e8             	lea    -0x18(%ebp),%eax
801063db:	89 44 24 04          	mov    %eax,0x4(%esp)
801063df:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801063e6:	e8 a3 f2 ff ff       	call   8010568e <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
801063eb:	85 c0                	test   %eax,%eax
801063ed:	78 47                	js     80106436 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
801063ef:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801063f2:	89 44 24 04          	mov    %eax,0x4(%esp)
801063f6:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801063fd:	e8 8c f2 ff ff       	call   8010568e <argint>
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
80106402:	85 c0                	test   %eax,%eax
80106404:	78 30                	js     80106436 <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
80106406:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106409:	0f bf c8             	movswl %ax,%ecx
8010640c:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010640f:	0f bf d0             	movswl %ax,%edx
80106412:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80106415:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106419:	89 54 24 08          	mov    %edx,0x8(%esp)
8010641d:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80106424:	00 
80106425:	89 04 24             	mov    %eax,(%esp)
80106428:	e8 80 fa ff ff       	call   80105ead <create>
8010642d:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106430:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106434:	75 0c                	jne    80106442 <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    commit_trans();
80106436:	e8 37 ce ff ff       	call   80103272 <commit_trans>
    return -1;
8010643b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106440:	eb 15                	jmp    80106457 <sys_mknod+0xa6>
  }
  iunlockput(ip);
80106442:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106445:	89 04 24             	mov    %eax,(%esp)
80106448:	e8 9f b6 ff ff       	call   80101aec <iunlockput>
  commit_trans();
8010644d:	e8 20 ce ff ff       	call   80103272 <commit_trans>
  return 0;
80106452:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106457:	c9                   	leave  
80106458:	c3                   	ret    

80106459 <sys_chdir>:

int
sys_chdir(void)
{
80106459:	55                   	push   %ebp
8010645a:	89 e5                	mov    %esp,%ebp
8010645c:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0)
8010645f:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106462:	89 44 24 04          	mov    %eax,0x4(%esp)
80106466:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010646d:	e8 b6 f2 ff ff       	call   80105728 <argstr>
80106472:	85 c0                	test   %eax,%eax
80106474:	78 14                	js     8010648a <sys_chdir+0x31>
80106476:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106479:	89 04 24             	mov    %eax,(%esp)
8010647c:	e8 89 bf ff ff       	call   8010240a <namei>
80106481:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106484:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106488:	75 07                	jne    80106491 <sys_chdir+0x38>
    return -1;
8010648a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010648f:	eb 57                	jmp    801064e8 <sys_chdir+0x8f>
  ilock(ip);
80106491:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106494:	89 04 24             	mov    %eax,(%esp)
80106497:	e8 cc b3 ff ff       	call   80101868 <ilock>
  if(ip->type != T_DIR){
8010649c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010649f:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801064a3:	66 83 f8 01          	cmp    $0x1,%ax
801064a7:	74 12                	je     801064bb <sys_chdir+0x62>
    iunlockput(ip);
801064a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064ac:	89 04 24             	mov    %eax,(%esp)
801064af:	e8 38 b6 ff ff       	call   80101aec <iunlockput>
    return -1;
801064b4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801064b9:	eb 2d                	jmp    801064e8 <sys_chdir+0x8f>
  }
  iunlock(ip);
801064bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064be:	89 04 24             	mov    %eax,(%esp)
801064c1:	e8 f0 b4 ff ff       	call   801019b6 <iunlock>
  iput(proc->cwd);
801064c6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801064cc:	8b 40 68             	mov    0x68(%eax),%eax
801064cf:	89 04 24             	mov    %eax,(%esp)
801064d2:	e8 44 b5 ff ff       	call   80101a1b <iput>
  proc->cwd = ip;
801064d7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801064dd:	8b 55 f4             	mov    -0xc(%ebp),%edx
801064e0:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
801064e3:	b8 00 00 00 00       	mov    $0x0,%eax
}
801064e8:	c9                   	leave  
801064e9:	c3                   	ret    

801064ea <sys_exec>:

int
sys_exec(void)
{
801064ea:	55                   	push   %ebp
801064eb:	89 e5                	mov    %esp,%ebp
801064ed:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
801064f3:	8d 45 f0             	lea    -0x10(%ebp),%eax
801064f6:	89 44 24 04          	mov    %eax,0x4(%esp)
801064fa:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106501:	e8 22 f2 ff ff       	call   80105728 <argstr>
80106506:	85 c0                	test   %eax,%eax
80106508:	78 1a                	js     80106524 <sys_exec+0x3a>
8010650a:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80106510:	89 44 24 04          	mov    %eax,0x4(%esp)
80106514:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010651b:	e8 6e f1 ff ff       	call   8010568e <argint>
80106520:	85 c0                	test   %eax,%eax
80106522:	79 0a                	jns    8010652e <sys_exec+0x44>
    return -1;
80106524:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106529:	e9 e2 00 00 00       	jmp    80106610 <sys_exec+0x126>
  }
  memset(argv, 0, sizeof(argv));
8010652e:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80106535:	00 
80106536:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010653d:	00 
8010653e:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106544:	89 04 24             	mov    %eax,(%esp)
80106547:	e8 f2 ed ff ff       	call   8010533e <memset>
  for(i=0;; i++){
8010654c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
80106553:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106556:	83 f8 1f             	cmp    $0x1f,%eax
80106559:	76 0a                	jbe    80106565 <sys_exec+0x7b>
      return -1;
8010655b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106560:	e9 ab 00 00 00       	jmp    80106610 <sys_exec+0x126>
    if(fetchint(proc, uargv+4*i, (int*)&uarg) < 0)
80106565:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106568:	c1 e0 02             	shl    $0x2,%eax
8010656b:	89 c2                	mov    %eax,%edx
8010656d:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80106573:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
80106576:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010657c:	8d 95 68 ff ff ff    	lea    -0x98(%ebp),%edx
80106582:	89 54 24 08          	mov    %edx,0x8(%esp)
80106586:	89 4c 24 04          	mov    %ecx,0x4(%esp)
8010658a:	89 04 24             	mov    %eax,(%esp)
8010658d:	e8 6a f0 ff ff       	call   801055fc <fetchint>
80106592:	85 c0                	test   %eax,%eax
80106594:	79 07                	jns    8010659d <sys_exec+0xb3>
      return -1;
80106596:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010659b:	eb 73                	jmp    80106610 <sys_exec+0x126>
    if(uarg == 0){
8010659d:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
801065a3:	85 c0                	test   %eax,%eax
801065a5:	75 26                	jne    801065cd <sys_exec+0xe3>
      argv[i] = 0;
801065a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065aa:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
801065b1:	00 00 00 00 
      break;
801065b5:	90                   	nop
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
801065b6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065b9:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
801065bf:	89 54 24 04          	mov    %edx,0x4(%esp)
801065c3:	89 04 24             	mov    %eax,(%esp)
801065c6:	e8 31 a5 ff ff       	call   80100afc <exec>
801065cb:	eb 43                	jmp    80106610 <sys_exec+0x126>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
801065cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065d0:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801065d7:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
801065dd:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
801065e0:	8b 95 68 ff ff ff    	mov    -0x98(%ebp),%edx
801065e6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801065ec:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801065f0:	89 54 24 04          	mov    %edx,0x4(%esp)
801065f4:	89 04 24             	mov    %eax,(%esp)
801065f7:	e8 34 f0 ff ff       	call   80105630 <fetchstr>
801065fc:	85 c0                	test   %eax,%eax
801065fe:	79 07                	jns    80106607 <sys_exec+0x11d>
      return -1;
80106600:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106605:	eb 09                	jmp    80106610 <sys_exec+0x126>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
80106607:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
8010660b:	e9 43 ff ff ff       	jmp    80106553 <sys_exec+0x69>
  return exec(path, argv);
}
80106610:	c9                   	leave  
80106611:	c3                   	ret    

80106612 <sys_pipe>:

int
sys_pipe(void)
{
80106612:	55                   	push   %ebp
80106613:	89 e5                	mov    %esp,%ebp
80106615:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80106618:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
8010661f:	00 
80106620:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106623:	89 44 24 04          	mov    %eax,0x4(%esp)
80106627:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010662e:	e8 93 f0 ff ff       	call   801056c6 <argptr>
80106633:	85 c0                	test   %eax,%eax
80106635:	79 0a                	jns    80106641 <sys_pipe+0x2f>
    return -1;
80106637:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010663c:	e9 9b 00 00 00       	jmp    801066dc <sys_pipe+0xca>
  if(pipealloc(&rf, &wf) < 0)
80106641:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106644:	89 44 24 04          	mov    %eax,0x4(%esp)
80106648:	8d 45 e8             	lea    -0x18(%ebp),%eax
8010664b:	89 04 24             	mov    %eax,(%esp)
8010664e:	e8 f1 d5 ff ff       	call   80103c44 <pipealloc>
80106653:	85 c0                	test   %eax,%eax
80106655:	79 07                	jns    8010665e <sys_pipe+0x4c>
    return -1;
80106657:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010665c:	eb 7e                	jmp    801066dc <sys_pipe+0xca>
  fd0 = -1;
8010665e:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80106665:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106668:	89 04 24             	mov    %eax,(%esp)
8010666b:	e8 35 f2 ff ff       	call   801058a5 <fdalloc>
80106670:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106673:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106677:	78 14                	js     8010668d <sys_pipe+0x7b>
80106679:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010667c:	89 04 24             	mov    %eax,(%esp)
8010667f:	e8 21 f2 ff ff       	call   801058a5 <fdalloc>
80106684:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106687:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010668b:	79 37                	jns    801066c4 <sys_pipe+0xb2>
    if(fd0 >= 0)
8010668d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106691:	78 14                	js     801066a7 <sys_pipe+0x95>
      proc->ofile[fd0] = 0;
80106693:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106699:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010669c:	83 c2 08             	add    $0x8,%edx
8010669f:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
801066a6:	00 
    fileclose(rf);
801066a7:	8b 45 e8             	mov    -0x18(%ebp),%eax
801066aa:	89 04 24             	mov    %eax,(%esp)
801066ad:	e8 12 a9 ff ff       	call   80100fc4 <fileclose>
    fileclose(wf);
801066b2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801066b5:	89 04 24             	mov    %eax,(%esp)
801066b8:	e8 07 a9 ff ff       	call   80100fc4 <fileclose>
    return -1;
801066bd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801066c2:	eb 18                	jmp    801066dc <sys_pipe+0xca>
  }
  fd[0] = fd0;
801066c4:	8b 45 ec             	mov    -0x14(%ebp),%eax
801066c7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801066ca:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
801066cc:	8b 45 ec             	mov    -0x14(%ebp),%eax
801066cf:	8d 50 04             	lea    0x4(%eax),%edx
801066d2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801066d5:	89 02                	mov    %eax,(%edx)
  return 0;
801066d7:	b8 00 00 00 00       	mov    $0x0,%eax
}
801066dc:	c9                   	leave  
801066dd:	c3                   	ret    
	...

801066e0 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
801066e0:	55                   	push   %ebp
801066e1:	89 e5                	mov    %esp,%ebp
801066e3:	83 ec 08             	sub    $0x8,%esp
  return fork();
801066e6:	e8 51 e0 ff ff       	call   8010473c <fork>
}
801066eb:	c9                   	leave  
801066ec:	c3                   	ret    

801066ed <sys_exit>:

int
sys_exit(void)
{
801066ed:	55                   	push   %ebp
801066ee:	89 e5                	mov    %esp,%ebp
801066f0:	83 ec 08             	sub    $0x8,%esp
  exit();
801066f3:	e8 a7 e1 ff ff       	call   8010489f <exit>
  return 0;  // not reached
801066f8:	b8 00 00 00 00       	mov    $0x0,%eax
}
801066fd:	c9                   	leave  
801066fe:	c3                   	ret    

801066ff <sys_wait>:

int
sys_wait(void)
{
801066ff:	55                   	push   %ebp
80106700:	89 e5                	mov    %esp,%ebp
80106702:	83 ec 08             	sub    $0x8,%esp
  return wait();
80106705:	e8 b0 e2 ff ff       	call   801049ba <wait>
}
8010670a:	c9                   	leave  
8010670b:	c3                   	ret    

8010670c <sys_kill>:

int
sys_kill(void)
{
8010670c:	55                   	push   %ebp
8010670d:	89 e5                	mov    %esp,%ebp
8010670f:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
80106712:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106715:	89 44 24 04          	mov    %eax,0x4(%esp)
80106719:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106720:	e8 69 ef ff ff       	call   8010568e <argint>
80106725:	85 c0                	test   %eax,%eax
80106727:	79 07                	jns    80106730 <sys_kill+0x24>
    return -1;
80106729:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010672e:	eb 0b                	jmp    8010673b <sys_kill+0x2f>
  return kill(pid);
80106730:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106733:	89 04 24             	mov    %eax,(%esp)
80106736:	e8 9d e7 ff ff       	call   80104ed8 <kill>
}
8010673b:	c9                   	leave  
8010673c:	c3                   	ret    

8010673d <sys_getpid>:

int
sys_getpid(void)
{
8010673d:	55                   	push   %ebp
8010673e:	89 e5                	mov    %esp,%ebp
  return proc->pid;
80106740:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106746:	8b 40 10             	mov    0x10(%eax),%eax
}
80106749:	5d                   	pop    %ebp
8010674a:	c3                   	ret    

8010674b <sys_sbrk>:

int
sys_sbrk(void)
{
8010674b:	55                   	push   %ebp
8010674c:	89 e5                	mov    %esp,%ebp
8010674e:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80106751:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106754:	89 44 24 04          	mov    %eax,0x4(%esp)
80106758:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010675f:	e8 2a ef ff ff       	call   8010568e <argint>
80106764:	85 c0                	test   %eax,%eax
80106766:	79 07                	jns    8010676f <sys_sbrk+0x24>
    return -1;
80106768:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010676d:	eb 24                	jmp    80106793 <sys_sbrk+0x48>
  addr = proc->sz;
8010676f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106775:	8b 00                	mov    (%eax),%eax
80106777:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
8010677a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010677d:	89 04 24             	mov    %eax,(%esp)
80106780:	e8 12 df ff ff       	call   80104697 <growproc>
80106785:	85 c0                	test   %eax,%eax
80106787:	79 07                	jns    80106790 <sys_sbrk+0x45>
    return -1;
80106789:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010678e:	eb 03                	jmp    80106793 <sys_sbrk+0x48>
  return addr;
80106790:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80106793:	c9                   	leave  
80106794:	c3                   	ret    

80106795 <sys_sleep>:

int
sys_sleep(void)
{
80106795:	55                   	push   %ebp
80106796:	89 e5                	mov    %esp,%ebp
80106798:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
8010679b:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010679e:	89 44 24 04          	mov    %eax,0x4(%esp)
801067a2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801067a9:	e8 e0 ee ff ff       	call   8010568e <argint>
801067ae:	85 c0                	test   %eax,%eax
801067b0:	79 07                	jns    801067b9 <sys_sleep+0x24>
    return -1;
801067b2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801067b7:	eb 6c                	jmp    80106825 <sys_sleep+0x90>
  acquire(&tickslock);
801067b9:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
801067c0:	e8 f2 e8 ff ff       	call   801050b7 <acquire>
  ticks0 = ticks;
801067c5:	a1 a0 2a 11 80       	mov    0x80112aa0,%eax
801067ca:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
801067cd:	eb 34                	jmp    80106803 <sys_sleep+0x6e>
    if(proc->killed){
801067cf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801067d5:	8b 40 24             	mov    0x24(%eax),%eax
801067d8:	85 c0                	test   %eax,%eax
801067da:	74 13                	je     801067ef <sys_sleep+0x5a>
      release(&tickslock);
801067dc:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
801067e3:	e8 6a e9 ff ff       	call   80105152 <release>
      return -1;
801067e8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801067ed:	eb 36                	jmp    80106825 <sys_sleep+0x90>
    }
    sleep(&ticks, &tickslock);
801067ef:	c7 44 24 04 60 22 11 	movl   $0x80112260,0x4(%esp)
801067f6:	80 
801067f7:	c7 04 24 a0 2a 11 80 	movl   $0x80112aa0,(%esp)
801067fe:	e8 47 e5 ff ff       	call   80104d4a <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
80106803:	a1 a0 2a 11 80       	mov    0x80112aa0,%eax
80106808:	89 c2                	mov    %eax,%edx
8010680a:	2b 55 f4             	sub    -0xc(%ebp),%edx
8010680d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106810:	39 c2                	cmp    %eax,%edx
80106812:	72 bb                	jb     801067cf <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
80106814:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
8010681b:	e8 32 e9 ff ff       	call   80105152 <release>
  return 0;
80106820:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106825:	c9                   	leave  
80106826:	c3                   	ret    

80106827 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80106827:	55                   	push   %ebp
80106828:	89 e5                	mov    %esp,%ebp
8010682a:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
8010682d:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
80106834:	e8 7e e8 ff ff       	call   801050b7 <acquire>
  xticks = ticks;
80106839:	a1 a0 2a 11 80       	mov    0x80112aa0,%eax
8010683e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
80106841:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
80106848:	e8 05 e9 ff ff       	call   80105152 <release>
  return xticks;
8010684d:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80106850:	c9                   	leave  
80106851:	c3                   	ret    

80106852 <sys_enableSwapping>:

void
sys_enableSwapping(void)
{
80106852:	55                   	push   %ebp
80106853:	89 e5                	mov    %esp,%ebp
  swapFlag = 1;
80106855:	c7 05 08 b0 10 80 01 	movl   $0x1,0x8010b008
8010685c:	00 00 00 
}
8010685f:	5d                   	pop    %ebp
80106860:	c3                   	ret    

80106861 <sys_disableSwapping>:

void
sys_disableSwapping(void)
{
80106861:	55                   	push   %ebp
80106862:	89 e5                	mov    %esp,%ebp
  swapFlag = 0;
80106864:	c7 05 08 b0 10 80 00 	movl   $0x0,0x8010b008
8010686b:	00 00 00 
}
8010686e:	5d                   	pop    %ebp
8010686f:	c3                   	ret    

80106870 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80106870:	55                   	push   %ebp
80106871:	89 e5                	mov    %esp,%ebp
80106873:	83 ec 08             	sub    $0x8,%esp
80106876:	8b 55 08             	mov    0x8(%ebp),%edx
80106879:	8b 45 0c             	mov    0xc(%ebp),%eax
8010687c:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80106880:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80106883:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80106887:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
8010688b:	ee                   	out    %al,(%dx)
}
8010688c:	c9                   	leave  
8010688d:	c3                   	ret    

8010688e <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
8010688e:	55                   	push   %ebp
8010688f:	89 e5                	mov    %esp,%ebp
80106891:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
80106894:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
8010689b:	00 
8010689c:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
801068a3:	e8 c8 ff ff ff       	call   80106870 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
801068a8:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
801068af:	00 
801068b0:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
801068b7:	e8 b4 ff ff ff       	call   80106870 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
801068bc:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
801068c3:	00 
801068c4:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
801068cb:	e8 a0 ff ff ff       	call   80106870 <outb>
  picenable(IRQ_TIMER);
801068d0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801068d7:	e8 f1 d1 ff ff       	call   80103acd <picenable>
}
801068dc:	c9                   	leave  
801068dd:	c3                   	ret    
	...

801068e0 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
801068e0:	1e                   	push   %ds
  pushl %es
801068e1:	06                   	push   %es
  pushl %fs
801068e2:	0f a0                	push   %fs
  pushl %gs
801068e4:	0f a8                	push   %gs
  pushal
801068e6:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
801068e7:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
801068eb:	8e d8                	mov    %eax,%ds
  movw %ax, %es
801068ed:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
801068ef:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
801068f3:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
801068f5:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
801068f7:	54                   	push   %esp
  call trap
801068f8:	e8 de 01 00 00       	call   80106adb <trap>
  addl $4, %esp
801068fd:	83 c4 04             	add    $0x4,%esp

80106900 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80106900:	61                   	popa   
  popl %gs
80106901:	0f a9                	pop    %gs
  popl %fs
80106903:	0f a1                	pop    %fs
  popl %es
80106905:	07                   	pop    %es
  popl %ds
80106906:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80106907:	83 c4 08             	add    $0x8,%esp
  iret
8010690a:	cf                   	iret   
	...

8010690c <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
8010690c:	55                   	push   %ebp
8010690d:	89 e5                	mov    %esp,%ebp
8010690f:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80106912:	8b 45 0c             	mov    0xc(%ebp),%eax
80106915:	83 e8 01             	sub    $0x1,%eax
80106918:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
8010691c:	8b 45 08             	mov    0x8(%ebp),%eax
8010691f:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80106923:	8b 45 08             	mov    0x8(%ebp),%eax
80106926:	c1 e8 10             	shr    $0x10,%eax
80106929:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
8010692d:	8d 45 fa             	lea    -0x6(%ebp),%eax
80106930:	0f 01 18             	lidtl  (%eax)
}
80106933:	c9                   	leave  
80106934:	c3                   	ret    

80106935 <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
80106935:	55                   	push   %ebp
80106936:	89 e5                	mov    %esp,%ebp
80106938:	53                   	push   %ebx
80106939:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
8010693c:	0f 20 d3             	mov    %cr2,%ebx
8010693f:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return val;
80106942:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80106945:	83 c4 10             	add    $0x10,%esp
80106948:	5b                   	pop    %ebx
80106949:	5d                   	pop    %ebp
8010694a:	c3                   	ret    

8010694b <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
8010694b:	55                   	push   %ebp
8010694c:	89 e5                	mov    %esp,%ebp
8010694e:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
80106951:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80106958:	e9 c3 00 00 00       	jmp    80106a20 <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
8010695d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106960:	8b 04 85 a0 b0 10 80 	mov    -0x7fef4f60(,%eax,4),%eax
80106967:	89 c2                	mov    %eax,%edx
80106969:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010696c:	66 89 14 c5 a0 22 11 	mov    %dx,-0x7feedd60(,%eax,8)
80106973:	80 
80106974:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106977:	66 c7 04 c5 a2 22 11 	movw   $0x8,-0x7feedd5e(,%eax,8)
8010697e:	80 08 00 
80106981:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106984:	0f b6 14 c5 a4 22 11 	movzbl -0x7feedd5c(,%eax,8),%edx
8010698b:	80 
8010698c:	83 e2 e0             	and    $0xffffffe0,%edx
8010698f:	88 14 c5 a4 22 11 80 	mov    %dl,-0x7feedd5c(,%eax,8)
80106996:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106999:	0f b6 14 c5 a4 22 11 	movzbl -0x7feedd5c(,%eax,8),%edx
801069a0:	80 
801069a1:	83 e2 1f             	and    $0x1f,%edx
801069a4:	88 14 c5 a4 22 11 80 	mov    %dl,-0x7feedd5c(,%eax,8)
801069ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069ae:	0f b6 14 c5 a5 22 11 	movzbl -0x7feedd5b(,%eax,8),%edx
801069b5:	80 
801069b6:	83 e2 f0             	and    $0xfffffff0,%edx
801069b9:	83 ca 0e             	or     $0xe,%edx
801069bc:	88 14 c5 a5 22 11 80 	mov    %dl,-0x7feedd5b(,%eax,8)
801069c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069c6:	0f b6 14 c5 a5 22 11 	movzbl -0x7feedd5b(,%eax,8),%edx
801069cd:	80 
801069ce:	83 e2 ef             	and    $0xffffffef,%edx
801069d1:	88 14 c5 a5 22 11 80 	mov    %dl,-0x7feedd5b(,%eax,8)
801069d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069db:	0f b6 14 c5 a5 22 11 	movzbl -0x7feedd5b(,%eax,8),%edx
801069e2:	80 
801069e3:	83 e2 9f             	and    $0xffffff9f,%edx
801069e6:	88 14 c5 a5 22 11 80 	mov    %dl,-0x7feedd5b(,%eax,8)
801069ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069f0:	0f b6 14 c5 a5 22 11 	movzbl -0x7feedd5b(,%eax,8),%edx
801069f7:	80 
801069f8:	83 ca 80             	or     $0xffffff80,%edx
801069fb:	88 14 c5 a5 22 11 80 	mov    %dl,-0x7feedd5b(,%eax,8)
80106a02:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a05:	8b 04 85 a0 b0 10 80 	mov    -0x7fef4f60(,%eax,4),%eax
80106a0c:	c1 e8 10             	shr    $0x10,%eax
80106a0f:	89 c2                	mov    %eax,%edx
80106a11:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a14:	66 89 14 c5 a6 22 11 	mov    %dx,-0x7feedd5a(,%eax,8)
80106a1b:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
80106a1c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106a20:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
80106a27:	0f 8e 30 ff ff ff    	jle    8010695d <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80106a2d:	a1 a0 b1 10 80       	mov    0x8010b1a0,%eax
80106a32:	66 a3 a0 24 11 80    	mov    %ax,0x801124a0
80106a38:	66 c7 05 a2 24 11 80 	movw   $0x8,0x801124a2
80106a3f:	08 00 
80106a41:	0f b6 05 a4 24 11 80 	movzbl 0x801124a4,%eax
80106a48:	83 e0 e0             	and    $0xffffffe0,%eax
80106a4b:	a2 a4 24 11 80       	mov    %al,0x801124a4
80106a50:	0f b6 05 a4 24 11 80 	movzbl 0x801124a4,%eax
80106a57:	83 e0 1f             	and    $0x1f,%eax
80106a5a:	a2 a4 24 11 80       	mov    %al,0x801124a4
80106a5f:	0f b6 05 a5 24 11 80 	movzbl 0x801124a5,%eax
80106a66:	83 c8 0f             	or     $0xf,%eax
80106a69:	a2 a5 24 11 80       	mov    %al,0x801124a5
80106a6e:	0f b6 05 a5 24 11 80 	movzbl 0x801124a5,%eax
80106a75:	83 e0 ef             	and    $0xffffffef,%eax
80106a78:	a2 a5 24 11 80       	mov    %al,0x801124a5
80106a7d:	0f b6 05 a5 24 11 80 	movzbl 0x801124a5,%eax
80106a84:	83 c8 60             	or     $0x60,%eax
80106a87:	a2 a5 24 11 80       	mov    %al,0x801124a5
80106a8c:	0f b6 05 a5 24 11 80 	movzbl 0x801124a5,%eax
80106a93:	83 c8 80             	or     $0xffffff80,%eax
80106a96:	a2 a5 24 11 80       	mov    %al,0x801124a5
80106a9b:	a1 a0 b1 10 80       	mov    0x8010b1a0,%eax
80106aa0:	c1 e8 10             	shr    $0x10,%eax
80106aa3:	66 a3 a6 24 11 80    	mov    %ax,0x801124a6
  
  initlock(&tickslock, "time");
80106aa9:	c7 44 24 04 78 8d 10 	movl   $0x80108d78,0x4(%esp)
80106ab0:	80 
80106ab1:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
80106ab8:	e8 d9 e5 ff ff       	call   80105096 <initlock>
}
80106abd:	c9                   	leave  
80106abe:	c3                   	ret    

80106abf <idtinit>:

void
idtinit(void)
{
80106abf:	55                   	push   %ebp
80106ac0:	89 e5                	mov    %esp,%ebp
80106ac2:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
80106ac5:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
80106acc:	00 
80106acd:	c7 04 24 a0 22 11 80 	movl   $0x801122a0,(%esp)
80106ad4:	e8 33 fe ff ff       	call   8010690c <lidt>
}
80106ad9:	c9                   	leave  
80106ada:	c3                   	ret    

80106adb <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
80106adb:	55                   	push   %ebp
80106adc:	89 e5                	mov    %esp,%ebp
80106ade:	57                   	push   %edi
80106adf:	56                   	push   %esi
80106ae0:	53                   	push   %ebx
80106ae1:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
80106ae4:	8b 45 08             	mov    0x8(%ebp),%eax
80106ae7:	8b 40 30             	mov    0x30(%eax),%eax
80106aea:	83 f8 40             	cmp    $0x40,%eax
80106aed:	75 3e                	jne    80106b2d <trap+0x52>
    if(proc->killed)
80106aef:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106af5:	8b 40 24             	mov    0x24(%eax),%eax
80106af8:	85 c0                	test   %eax,%eax
80106afa:	74 05                	je     80106b01 <trap+0x26>
      exit();
80106afc:	e8 9e dd ff ff       	call   8010489f <exit>
    proc->tf = tf;
80106b01:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106b07:	8b 55 08             	mov    0x8(%ebp),%edx
80106b0a:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
80106b0d:	e8 59 ec ff ff       	call   8010576b <syscall>
    if(proc->killed)
80106b12:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106b18:	8b 40 24             	mov    0x24(%eax),%eax
80106b1b:	85 c0                	test   %eax,%eax
80106b1d:	0f 84 34 02 00 00    	je     80106d57 <trap+0x27c>
      exit();
80106b23:	e8 77 dd ff ff       	call   8010489f <exit>
    return;
80106b28:	e9 2a 02 00 00       	jmp    80106d57 <trap+0x27c>
  }

  switch(tf->trapno){
80106b2d:	8b 45 08             	mov    0x8(%ebp),%eax
80106b30:	8b 40 30             	mov    0x30(%eax),%eax
80106b33:	83 e8 20             	sub    $0x20,%eax
80106b36:	83 f8 1f             	cmp    $0x1f,%eax
80106b39:	0f 87 bc 00 00 00    	ja     80106bfb <trap+0x120>
80106b3f:	8b 04 85 20 8e 10 80 	mov    -0x7fef71e0(,%eax,4),%eax
80106b46:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
80106b48:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80106b4e:	0f b6 00             	movzbl (%eax),%eax
80106b51:	84 c0                	test   %al,%al
80106b53:	75 31                	jne    80106b86 <trap+0xab>
      acquire(&tickslock);
80106b55:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
80106b5c:	e8 56 e5 ff ff       	call   801050b7 <acquire>
      ticks++;
80106b61:	a1 a0 2a 11 80       	mov    0x80112aa0,%eax
80106b66:	83 c0 01             	add    $0x1,%eax
80106b69:	a3 a0 2a 11 80       	mov    %eax,0x80112aa0
      wakeup(&ticks);
80106b6e:	c7 04 24 a0 2a 11 80 	movl   $0x80112aa0,(%esp)
80106b75:	e8 33 e3 ff ff       	call   80104ead <wakeup>
      release(&tickslock);
80106b7a:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
80106b81:	e8 cc e5 ff ff       	call   80105152 <release>
    }
    lapiceoi();
80106b86:	e8 6a c3 ff ff       	call   80102ef5 <lapiceoi>
    break;
80106b8b:	e9 41 01 00 00       	jmp    80106cd1 <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
80106b90:	e8 5c bb ff ff       	call   801026f1 <ideintr>
    lapiceoi();
80106b95:	e8 5b c3 ff ff       	call   80102ef5 <lapiceoi>
    break;
80106b9a:	e9 32 01 00 00       	jmp    80106cd1 <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
80106b9f:	e8 2f c1 ff ff       	call   80102cd3 <kbdintr>
    lapiceoi();
80106ba4:	e8 4c c3 ff ff       	call   80102ef5 <lapiceoi>
    break;
80106ba9:	e9 23 01 00 00       	jmp    80106cd1 <trap+0x1f6>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
80106bae:	e8 a9 03 00 00       	call   80106f5c <uartintr>
    lapiceoi();
80106bb3:	e8 3d c3 ff ff       	call   80102ef5 <lapiceoi>
    break;
80106bb8:	e9 14 01 00 00       	jmp    80106cd1 <trap+0x1f6>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
            cpu->id, tf->cs, tf->eip);
80106bbd:	8b 45 08             	mov    0x8(%ebp),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80106bc0:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
80106bc3:	8b 45 08             	mov    0x8(%ebp),%eax
80106bc6:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80106bca:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
80106bcd:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80106bd3:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80106bd6:	0f b6 c0             	movzbl %al,%eax
80106bd9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106bdd:	89 54 24 08          	mov    %edx,0x8(%esp)
80106be1:	89 44 24 04          	mov    %eax,0x4(%esp)
80106be5:	c7 04 24 80 8d 10 80 	movl   $0x80108d80,(%esp)
80106bec:	e8 b0 97 ff ff       	call   801003a1 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
80106bf1:	e8 ff c2 ff ff       	call   80102ef5 <lapiceoi>
    break;
80106bf6:	e9 d6 00 00 00       	jmp    80106cd1 <trap+0x1f6>
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
80106bfb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106c01:	85 c0                	test   %eax,%eax
80106c03:	74 11                	je     80106c16 <trap+0x13b>
80106c05:	8b 45 08             	mov    0x8(%ebp),%eax
80106c08:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106c0c:	0f b7 c0             	movzwl %ax,%eax
80106c0f:	83 e0 03             	and    $0x3,%eax
80106c12:	85 c0                	test   %eax,%eax
80106c14:	75 46                	jne    80106c5c <trap+0x181>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80106c16:	e8 1a fd ff ff       	call   80106935 <rcr2>
              tf->trapno, cpu->id, tf->eip, rcr2());
80106c1b:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80106c1e:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
80106c21:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80106c28:	0f b6 12             	movzbl (%edx),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80106c2b:	0f b6 ca             	movzbl %dl,%ecx
              tf->trapno, cpu->id, tf->eip, rcr2());
80106c2e:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80106c31:	8b 52 30             	mov    0x30(%edx),%edx
80106c34:	89 44 24 10          	mov    %eax,0x10(%esp)
80106c38:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
80106c3c:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106c40:	89 54 24 04          	mov    %edx,0x4(%esp)
80106c44:	c7 04 24 a4 8d 10 80 	movl   $0x80108da4,(%esp)
80106c4b:	e8 51 97 ff ff       	call   801003a1 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
80106c50:	c7 04 24 d6 8d 10 80 	movl   $0x80108dd6,(%esp)
80106c57:	e8 e1 98 ff ff       	call   8010053d <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106c5c:	e8 d4 fc ff ff       	call   80106935 <rcr2>
80106c61:	89 c2                	mov    %eax,%edx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80106c63:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106c66:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80106c69:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80106c6f:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106c72:	0f b6 f0             	movzbl %al,%esi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80106c75:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106c78:	8b 58 34             	mov    0x34(%eax),%ebx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80106c7b:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106c7e:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80106c81:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106c87:	83 c0 6c             	add    $0x6c,%eax
80106c8a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80106c8d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106c93:	8b 40 10             	mov    0x10(%eax),%eax
80106c96:	89 54 24 1c          	mov    %edx,0x1c(%esp)
80106c9a:	89 7c 24 18          	mov    %edi,0x18(%esp)
80106c9e:	89 74 24 14          	mov    %esi,0x14(%esp)
80106ca2:	89 5c 24 10          	mov    %ebx,0x10(%esp)
80106ca6:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106caa:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80106cad:	89 54 24 08          	mov    %edx,0x8(%esp)
80106cb1:	89 44 24 04          	mov    %eax,0x4(%esp)
80106cb5:	c7 04 24 dc 8d 10 80 	movl   $0x80108ddc,(%esp)
80106cbc:	e8 e0 96 ff ff       	call   801003a1 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
80106cc1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106cc7:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
80106cce:	eb 01                	jmp    80106cd1 <trap+0x1f6>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
80106cd0:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80106cd1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106cd7:	85 c0                	test   %eax,%eax
80106cd9:	74 24                	je     80106cff <trap+0x224>
80106cdb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106ce1:	8b 40 24             	mov    0x24(%eax),%eax
80106ce4:	85 c0                	test   %eax,%eax
80106ce6:	74 17                	je     80106cff <trap+0x224>
80106ce8:	8b 45 08             	mov    0x8(%ebp),%eax
80106ceb:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106cef:	0f b7 c0             	movzwl %ax,%eax
80106cf2:	83 e0 03             	and    $0x3,%eax
80106cf5:	83 f8 03             	cmp    $0x3,%eax
80106cf8:	75 05                	jne    80106cff <trap+0x224>
    exit();
80106cfa:	e8 a0 db ff ff       	call   8010489f <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
80106cff:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106d05:	85 c0                	test   %eax,%eax
80106d07:	74 1e                	je     80106d27 <trap+0x24c>
80106d09:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106d0f:	8b 40 0c             	mov    0xc(%eax),%eax
80106d12:	83 f8 04             	cmp    $0x4,%eax
80106d15:	75 10                	jne    80106d27 <trap+0x24c>
80106d17:	8b 45 08             	mov    0x8(%ebp),%eax
80106d1a:	8b 40 30             	mov    0x30(%eax),%eax
80106d1d:	83 f8 20             	cmp    $0x20,%eax
80106d20:	75 05                	jne    80106d27 <trap+0x24c>
    yield();
80106d22:	e8 c5 df ff ff       	call   80104cec <yield>

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80106d27:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106d2d:	85 c0                	test   %eax,%eax
80106d2f:	74 27                	je     80106d58 <trap+0x27d>
80106d31:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106d37:	8b 40 24             	mov    0x24(%eax),%eax
80106d3a:	85 c0                	test   %eax,%eax
80106d3c:	74 1a                	je     80106d58 <trap+0x27d>
80106d3e:	8b 45 08             	mov    0x8(%ebp),%eax
80106d41:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106d45:	0f b7 c0             	movzwl %ax,%eax
80106d48:	83 e0 03             	and    $0x3,%eax
80106d4b:	83 f8 03             	cmp    $0x3,%eax
80106d4e:	75 08                	jne    80106d58 <trap+0x27d>
    exit();
80106d50:	e8 4a db ff ff       	call   8010489f <exit>
80106d55:	eb 01                	jmp    80106d58 <trap+0x27d>
      exit();
    proc->tf = tf;
    syscall();
    if(proc->killed)
      exit();
    return;
80106d57:	90                   	nop
    yield();

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
    exit();
}
80106d58:	83 c4 3c             	add    $0x3c,%esp
80106d5b:	5b                   	pop    %ebx
80106d5c:	5e                   	pop    %esi
80106d5d:	5f                   	pop    %edi
80106d5e:	5d                   	pop    %ebp
80106d5f:	c3                   	ret    

80106d60 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80106d60:	55                   	push   %ebp
80106d61:	89 e5                	mov    %esp,%ebp
80106d63:	53                   	push   %ebx
80106d64:	83 ec 14             	sub    $0x14,%esp
80106d67:	8b 45 08             	mov    0x8(%ebp),%eax
80106d6a:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80106d6e:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80106d72:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80106d76:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80106d7a:	ec                   	in     (%dx),%al
80106d7b:	89 c3                	mov    %eax,%ebx
80106d7d:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80106d80:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80106d84:	83 c4 14             	add    $0x14,%esp
80106d87:	5b                   	pop    %ebx
80106d88:	5d                   	pop    %ebp
80106d89:	c3                   	ret    

80106d8a <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80106d8a:	55                   	push   %ebp
80106d8b:	89 e5                	mov    %esp,%ebp
80106d8d:	83 ec 08             	sub    $0x8,%esp
80106d90:	8b 55 08             	mov    0x8(%ebp),%edx
80106d93:	8b 45 0c             	mov    0xc(%ebp),%eax
80106d96:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80106d9a:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80106d9d:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80106da1:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80106da5:	ee                   	out    %al,(%dx)
}
80106da6:	c9                   	leave  
80106da7:	c3                   	ret    

80106da8 <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
80106da8:	55                   	push   %ebp
80106da9:	89 e5                	mov    %esp,%ebp
80106dab:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
80106dae:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106db5:	00 
80106db6:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80106dbd:	e8 c8 ff ff ff       	call   80106d8a <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
80106dc2:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
80106dc9:	00 
80106dca:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80106dd1:	e8 b4 ff ff ff       	call   80106d8a <outb>
  outb(COM1+0, 115200/9600);
80106dd6:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
80106ddd:	00 
80106dde:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106de5:	e8 a0 ff ff ff       	call   80106d8a <outb>
  outb(COM1+1, 0);
80106dea:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106df1:	00 
80106df2:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80106df9:	e8 8c ff ff ff       	call   80106d8a <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
80106dfe:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80106e05:	00 
80106e06:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80106e0d:	e8 78 ff ff ff       	call   80106d8a <outb>
  outb(COM1+4, 0);
80106e12:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106e19:	00 
80106e1a:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
80106e21:	e8 64 ff ff ff       	call   80106d8a <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
80106e26:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80106e2d:	00 
80106e2e:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80106e35:	e8 50 ff ff ff       	call   80106d8a <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
80106e3a:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106e41:	e8 1a ff ff ff       	call   80106d60 <inb>
80106e46:	3c ff                	cmp    $0xff,%al
80106e48:	74 6c                	je     80106eb6 <uartinit+0x10e>
    return;
  uart = 1;
80106e4a:	c7 05 50 b6 10 80 01 	movl   $0x1,0x8010b650
80106e51:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
80106e54:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80106e5b:	e8 00 ff ff ff       	call   80106d60 <inb>
  inb(COM1+0);
80106e60:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106e67:	e8 f4 fe ff ff       	call   80106d60 <inb>
  picenable(IRQ_COM1);
80106e6c:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80106e73:	e8 55 cc ff ff       	call   80103acd <picenable>
  ioapicenable(IRQ_COM1, 0);
80106e78:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106e7f:	00 
80106e80:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80106e87:	e8 f6 ba ff ff       	call   80102982 <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80106e8c:	c7 45 f4 a0 8e 10 80 	movl   $0x80108ea0,-0xc(%ebp)
80106e93:	eb 15                	jmp    80106eaa <uartinit+0x102>
    uartputc(*p);
80106e95:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e98:	0f b6 00             	movzbl (%eax),%eax
80106e9b:	0f be c0             	movsbl %al,%eax
80106e9e:	89 04 24             	mov    %eax,(%esp)
80106ea1:	e8 13 00 00 00       	call   80106eb9 <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80106ea6:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106eaa:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ead:	0f b6 00             	movzbl (%eax),%eax
80106eb0:	84 c0                	test   %al,%al
80106eb2:	75 e1                	jne    80106e95 <uartinit+0xed>
80106eb4:	eb 01                	jmp    80106eb7 <uartinit+0x10f>
  outb(COM1+4, 0);
  outb(COM1+1, 0x01);    // Enable receive interrupts.

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
    return;
80106eb6:	90                   	nop
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
    uartputc(*p);
}
80106eb7:	c9                   	leave  
80106eb8:	c3                   	ret    

80106eb9 <uartputc>:

void
uartputc(int c)
{
80106eb9:	55                   	push   %ebp
80106eba:	89 e5                	mov    %esp,%ebp
80106ebc:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
80106ebf:	a1 50 b6 10 80       	mov    0x8010b650,%eax
80106ec4:	85 c0                	test   %eax,%eax
80106ec6:	74 4d                	je     80106f15 <uartputc+0x5c>
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80106ec8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80106ecf:	eb 10                	jmp    80106ee1 <uartputc+0x28>
    microdelay(10);
80106ed1:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
80106ed8:	e8 3d c0 ff ff       	call   80102f1a <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80106edd:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106ee1:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
80106ee5:	7f 16                	jg     80106efd <uartputc+0x44>
80106ee7:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106eee:	e8 6d fe ff ff       	call   80106d60 <inb>
80106ef3:	0f b6 c0             	movzbl %al,%eax
80106ef6:	83 e0 20             	and    $0x20,%eax
80106ef9:	85 c0                	test   %eax,%eax
80106efb:	74 d4                	je     80106ed1 <uartputc+0x18>
    microdelay(10);
  outb(COM1+0, c);
80106efd:	8b 45 08             	mov    0x8(%ebp),%eax
80106f00:	0f b6 c0             	movzbl %al,%eax
80106f03:	89 44 24 04          	mov    %eax,0x4(%esp)
80106f07:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106f0e:	e8 77 fe ff ff       	call   80106d8a <outb>
80106f13:	eb 01                	jmp    80106f16 <uartputc+0x5d>
uartputc(int c)
{
  int i;

  if(!uart)
    return;
80106f15:	90                   	nop
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
    microdelay(10);
  outb(COM1+0, c);
}
80106f16:	c9                   	leave  
80106f17:	c3                   	ret    

80106f18 <uartgetc>:

static int
uartgetc(void)
{
80106f18:	55                   	push   %ebp
80106f19:	89 e5                	mov    %esp,%ebp
80106f1b:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
80106f1e:	a1 50 b6 10 80       	mov    0x8010b650,%eax
80106f23:	85 c0                	test   %eax,%eax
80106f25:	75 07                	jne    80106f2e <uartgetc+0x16>
    return -1;
80106f27:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106f2c:	eb 2c                	jmp    80106f5a <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
80106f2e:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106f35:	e8 26 fe ff ff       	call   80106d60 <inb>
80106f3a:	0f b6 c0             	movzbl %al,%eax
80106f3d:	83 e0 01             	and    $0x1,%eax
80106f40:	85 c0                	test   %eax,%eax
80106f42:	75 07                	jne    80106f4b <uartgetc+0x33>
    return -1;
80106f44:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106f49:	eb 0f                	jmp    80106f5a <uartgetc+0x42>
  return inb(COM1+0);
80106f4b:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106f52:	e8 09 fe ff ff       	call   80106d60 <inb>
80106f57:	0f b6 c0             	movzbl %al,%eax
}
80106f5a:	c9                   	leave  
80106f5b:	c3                   	ret    

80106f5c <uartintr>:

void
uartintr(void)
{
80106f5c:	55                   	push   %ebp
80106f5d:	89 e5                	mov    %esp,%ebp
80106f5f:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
80106f62:	c7 04 24 18 6f 10 80 	movl   $0x80106f18,(%esp)
80106f69:	e8 3f 98 ff ff       	call   801007ad <consoleintr>
}
80106f6e:	c9                   	leave  
80106f6f:	c3                   	ret    

80106f70 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80106f70:	6a 00                	push   $0x0
  pushl $0
80106f72:	6a 00                	push   $0x0
  jmp alltraps
80106f74:	e9 67 f9 ff ff       	jmp    801068e0 <alltraps>

80106f79 <vector1>:
.globl vector1
vector1:
  pushl $0
80106f79:	6a 00                	push   $0x0
  pushl $1
80106f7b:	6a 01                	push   $0x1
  jmp alltraps
80106f7d:	e9 5e f9 ff ff       	jmp    801068e0 <alltraps>

80106f82 <vector2>:
.globl vector2
vector2:
  pushl $0
80106f82:	6a 00                	push   $0x0
  pushl $2
80106f84:	6a 02                	push   $0x2
  jmp alltraps
80106f86:	e9 55 f9 ff ff       	jmp    801068e0 <alltraps>

80106f8b <vector3>:
.globl vector3
vector3:
  pushl $0
80106f8b:	6a 00                	push   $0x0
  pushl $3
80106f8d:	6a 03                	push   $0x3
  jmp alltraps
80106f8f:	e9 4c f9 ff ff       	jmp    801068e0 <alltraps>

80106f94 <vector4>:
.globl vector4
vector4:
  pushl $0
80106f94:	6a 00                	push   $0x0
  pushl $4
80106f96:	6a 04                	push   $0x4
  jmp alltraps
80106f98:	e9 43 f9 ff ff       	jmp    801068e0 <alltraps>

80106f9d <vector5>:
.globl vector5
vector5:
  pushl $0
80106f9d:	6a 00                	push   $0x0
  pushl $5
80106f9f:	6a 05                	push   $0x5
  jmp alltraps
80106fa1:	e9 3a f9 ff ff       	jmp    801068e0 <alltraps>

80106fa6 <vector6>:
.globl vector6
vector6:
  pushl $0
80106fa6:	6a 00                	push   $0x0
  pushl $6
80106fa8:	6a 06                	push   $0x6
  jmp alltraps
80106faa:	e9 31 f9 ff ff       	jmp    801068e0 <alltraps>

80106faf <vector7>:
.globl vector7
vector7:
  pushl $0
80106faf:	6a 00                	push   $0x0
  pushl $7
80106fb1:	6a 07                	push   $0x7
  jmp alltraps
80106fb3:	e9 28 f9 ff ff       	jmp    801068e0 <alltraps>

80106fb8 <vector8>:
.globl vector8
vector8:
  pushl $8
80106fb8:	6a 08                	push   $0x8
  jmp alltraps
80106fba:	e9 21 f9 ff ff       	jmp    801068e0 <alltraps>

80106fbf <vector9>:
.globl vector9
vector9:
  pushl $0
80106fbf:	6a 00                	push   $0x0
  pushl $9
80106fc1:	6a 09                	push   $0x9
  jmp alltraps
80106fc3:	e9 18 f9 ff ff       	jmp    801068e0 <alltraps>

80106fc8 <vector10>:
.globl vector10
vector10:
  pushl $10
80106fc8:	6a 0a                	push   $0xa
  jmp alltraps
80106fca:	e9 11 f9 ff ff       	jmp    801068e0 <alltraps>

80106fcf <vector11>:
.globl vector11
vector11:
  pushl $11
80106fcf:	6a 0b                	push   $0xb
  jmp alltraps
80106fd1:	e9 0a f9 ff ff       	jmp    801068e0 <alltraps>

80106fd6 <vector12>:
.globl vector12
vector12:
  pushl $12
80106fd6:	6a 0c                	push   $0xc
  jmp alltraps
80106fd8:	e9 03 f9 ff ff       	jmp    801068e0 <alltraps>

80106fdd <vector13>:
.globl vector13
vector13:
  pushl $13
80106fdd:	6a 0d                	push   $0xd
  jmp alltraps
80106fdf:	e9 fc f8 ff ff       	jmp    801068e0 <alltraps>

80106fe4 <vector14>:
.globl vector14
vector14:
  pushl $14
80106fe4:	6a 0e                	push   $0xe
  jmp alltraps
80106fe6:	e9 f5 f8 ff ff       	jmp    801068e0 <alltraps>

80106feb <vector15>:
.globl vector15
vector15:
  pushl $0
80106feb:	6a 00                	push   $0x0
  pushl $15
80106fed:	6a 0f                	push   $0xf
  jmp alltraps
80106fef:	e9 ec f8 ff ff       	jmp    801068e0 <alltraps>

80106ff4 <vector16>:
.globl vector16
vector16:
  pushl $0
80106ff4:	6a 00                	push   $0x0
  pushl $16
80106ff6:	6a 10                	push   $0x10
  jmp alltraps
80106ff8:	e9 e3 f8 ff ff       	jmp    801068e0 <alltraps>

80106ffd <vector17>:
.globl vector17
vector17:
  pushl $17
80106ffd:	6a 11                	push   $0x11
  jmp alltraps
80106fff:	e9 dc f8 ff ff       	jmp    801068e0 <alltraps>

80107004 <vector18>:
.globl vector18
vector18:
  pushl $0
80107004:	6a 00                	push   $0x0
  pushl $18
80107006:	6a 12                	push   $0x12
  jmp alltraps
80107008:	e9 d3 f8 ff ff       	jmp    801068e0 <alltraps>

8010700d <vector19>:
.globl vector19
vector19:
  pushl $0
8010700d:	6a 00                	push   $0x0
  pushl $19
8010700f:	6a 13                	push   $0x13
  jmp alltraps
80107011:	e9 ca f8 ff ff       	jmp    801068e0 <alltraps>

80107016 <vector20>:
.globl vector20
vector20:
  pushl $0
80107016:	6a 00                	push   $0x0
  pushl $20
80107018:	6a 14                	push   $0x14
  jmp alltraps
8010701a:	e9 c1 f8 ff ff       	jmp    801068e0 <alltraps>

8010701f <vector21>:
.globl vector21
vector21:
  pushl $0
8010701f:	6a 00                	push   $0x0
  pushl $21
80107021:	6a 15                	push   $0x15
  jmp alltraps
80107023:	e9 b8 f8 ff ff       	jmp    801068e0 <alltraps>

80107028 <vector22>:
.globl vector22
vector22:
  pushl $0
80107028:	6a 00                	push   $0x0
  pushl $22
8010702a:	6a 16                	push   $0x16
  jmp alltraps
8010702c:	e9 af f8 ff ff       	jmp    801068e0 <alltraps>

80107031 <vector23>:
.globl vector23
vector23:
  pushl $0
80107031:	6a 00                	push   $0x0
  pushl $23
80107033:	6a 17                	push   $0x17
  jmp alltraps
80107035:	e9 a6 f8 ff ff       	jmp    801068e0 <alltraps>

8010703a <vector24>:
.globl vector24
vector24:
  pushl $0
8010703a:	6a 00                	push   $0x0
  pushl $24
8010703c:	6a 18                	push   $0x18
  jmp alltraps
8010703e:	e9 9d f8 ff ff       	jmp    801068e0 <alltraps>

80107043 <vector25>:
.globl vector25
vector25:
  pushl $0
80107043:	6a 00                	push   $0x0
  pushl $25
80107045:	6a 19                	push   $0x19
  jmp alltraps
80107047:	e9 94 f8 ff ff       	jmp    801068e0 <alltraps>

8010704c <vector26>:
.globl vector26
vector26:
  pushl $0
8010704c:	6a 00                	push   $0x0
  pushl $26
8010704e:	6a 1a                	push   $0x1a
  jmp alltraps
80107050:	e9 8b f8 ff ff       	jmp    801068e0 <alltraps>

80107055 <vector27>:
.globl vector27
vector27:
  pushl $0
80107055:	6a 00                	push   $0x0
  pushl $27
80107057:	6a 1b                	push   $0x1b
  jmp alltraps
80107059:	e9 82 f8 ff ff       	jmp    801068e0 <alltraps>

8010705e <vector28>:
.globl vector28
vector28:
  pushl $0
8010705e:	6a 00                	push   $0x0
  pushl $28
80107060:	6a 1c                	push   $0x1c
  jmp alltraps
80107062:	e9 79 f8 ff ff       	jmp    801068e0 <alltraps>

80107067 <vector29>:
.globl vector29
vector29:
  pushl $0
80107067:	6a 00                	push   $0x0
  pushl $29
80107069:	6a 1d                	push   $0x1d
  jmp alltraps
8010706b:	e9 70 f8 ff ff       	jmp    801068e0 <alltraps>

80107070 <vector30>:
.globl vector30
vector30:
  pushl $0
80107070:	6a 00                	push   $0x0
  pushl $30
80107072:	6a 1e                	push   $0x1e
  jmp alltraps
80107074:	e9 67 f8 ff ff       	jmp    801068e0 <alltraps>

80107079 <vector31>:
.globl vector31
vector31:
  pushl $0
80107079:	6a 00                	push   $0x0
  pushl $31
8010707b:	6a 1f                	push   $0x1f
  jmp alltraps
8010707d:	e9 5e f8 ff ff       	jmp    801068e0 <alltraps>

80107082 <vector32>:
.globl vector32
vector32:
  pushl $0
80107082:	6a 00                	push   $0x0
  pushl $32
80107084:	6a 20                	push   $0x20
  jmp alltraps
80107086:	e9 55 f8 ff ff       	jmp    801068e0 <alltraps>

8010708b <vector33>:
.globl vector33
vector33:
  pushl $0
8010708b:	6a 00                	push   $0x0
  pushl $33
8010708d:	6a 21                	push   $0x21
  jmp alltraps
8010708f:	e9 4c f8 ff ff       	jmp    801068e0 <alltraps>

80107094 <vector34>:
.globl vector34
vector34:
  pushl $0
80107094:	6a 00                	push   $0x0
  pushl $34
80107096:	6a 22                	push   $0x22
  jmp alltraps
80107098:	e9 43 f8 ff ff       	jmp    801068e0 <alltraps>

8010709d <vector35>:
.globl vector35
vector35:
  pushl $0
8010709d:	6a 00                	push   $0x0
  pushl $35
8010709f:	6a 23                	push   $0x23
  jmp alltraps
801070a1:	e9 3a f8 ff ff       	jmp    801068e0 <alltraps>

801070a6 <vector36>:
.globl vector36
vector36:
  pushl $0
801070a6:	6a 00                	push   $0x0
  pushl $36
801070a8:	6a 24                	push   $0x24
  jmp alltraps
801070aa:	e9 31 f8 ff ff       	jmp    801068e0 <alltraps>

801070af <vector37>:
.globl vector37
vector37:
  pushl $0
801070af:	6a 00                	push   $0x0
  pushl $37
801070b1:	6a 25                	push   $0x25
  jmp alltraps
801070b3:	e9 28 f8 ff ff       	jmp    801068e0 <alltraps>

801070b8 <vector38>:
.globl vector38
vector38:
  pushl $0
801070b8:	6a 00                	push   $0x0
  pushl $38
801070ba:	6a 26                	push   $0x26
  jmp alltraps
801070bc:	e9 1f f8 ff ff       	jmp    801068e0 <alltraps>

801070c1 <vector39>:
.globl vector39
vector39:
  pushl $0
801070c1:	6a 00                	push   $0x0
  pushl $39
801070c3:	6a 27                	push   $0x27
  jmp alltraps
801070c5:	e9 16 f8 ff ff       	jmp    801068e0 <alltraps>

801070ca <vector40>:
.globl vector40
vector40:
  pushl $0
801070ca:	6a 00                	push   $0x0
  pushl $40
801070cc:	6a 28                	push   $0x28
  jmp alltraps
801070ce:	e9 0d f8 ff ff       	jmp    801068e0 <alltraps>

801070d3 <vector41>:
.globl vector41
vector41:
  pushl $0
801070d3:	6a 00                	push   $0x0
  pushl $41
801070d5:	6a 29                	push   $0x29
  jmp alltraps
801070d7:	e9 04 f8 ff ff       	jmp    801068e0 <alltraps>

801070dc <vector42>:
.globl vector42
vector42:
  pushl $0
801070dc:	6a 00                	push   $0x0
  pushl $42
801070de:	6a 2a                	push   $0x2a
  jmp alltraps
801070e0:	e9 fb f7 ff ff       	jmp    801068e0 <alltraps>

801070e5 <vector43>:
.globl vector43
vector43:
  pushl $0
801070e5:	6a 00                	push   $0x0
  pushl $43
801070e7:	6a 2b                	push   $0x2b
  jmp alltraps
801070e9:	e9 f2 f7 ff ff       	jmp    801068e0 <alltraps>

801070ee <vector44>:
.globl vector44
vector44:
  pushl $0
801070ee:	6a 00                	push   $0x0
  pushl $44
801070f0:	6a 2c                	push   $0x2c
  jmp alltraps
801070f2:	e9 e9 f7 ff ff       	jmp    801068e0 <alltraps>

801070f7 <vector45>:
.globl vector45
vector45:
  pushl $0
801070f7:	6a 00                	push   $0x0
  pushl $45
801070f9:	6a 2d                	push   $0x2d
  jmp alltraps
801070fb:	e9 e0 f7 ff ff       	jmp    801068e0 <alltraps>

80107100 <vector46>:
.globl vector46
vector46:
  pushl $0
80107100:	6a 00                	push   $0x0
  pushl $46
80107102:	6a 2e                	push   $0x2e
  jmp alltraps
80107104:	e9 d7 f7 ff ff       	jmp    801068e0 <alltraps>

80107109 <vector47>:
.globl vector47
vector47:
  pushl $0
80107109:	6a 00                	push   $0x0
  pushl $47
8010710b:	6a 2f                	push   $0x2f
  jmp alltraps
8010710d:	e9 ce f7 ff ff       	jmp    801068e0 <alltraps>

80107112 <vector48>:
.globl vector48
vector48:
  pushl $0
80107112:	6a 00                	push   $0x0
  pushl $48
80107114:	6a 30                	push   $0x30
  jmp alltraps
80107116:	e9 c5 f7 ff ff       	jmp    801068e0 <alltraps>

8010711b <vector49>:
.globl vector49
vector49:
  pushl $0
8010711b:	6a 00                	push   $0x0
  pushl $49
8010711d:	6a 31                	push   $0x31
  jmp alltraps
8010711f:	e9 bc f7 ff ff       	jmp    801068e0 <alltraps>

80107124 <vector50>:
.globl vector50
vector50:
  pushl $0
80107124:	6a 00                	push   $0x0
  pushl $50
80107126:	6a 32                	push   $0x32
  jmp alltraps
80107128:	e9 b3 f7 ff ff       	jmp    801068e0 <alltraps>

8010712d <vector51>:
.globl vector51
vector51:
  pushl $0
8010712d:	6a 00                	push   $0x0
  pushl $51
8010712f:	6a 33                	push   $0x33
  jmp alltraps
80107131:	e9 aa f7 ff ff       	jmp    801068e0 <alltraps>

80107136 <vector52>:
.globl vector52
vector52:
  pushl $0
80107136:	6a 00                	push   $0x0
  pushl $52
80107138:	6a 34                	push   $0x34
  jmp alltraps
8010713a:	e9 a1 f7 ff ff       	jmp    801068e0 <alltraps>

8010713f <vector53>:
.globl vector53
vector53:
  pushl $0
8010713f:	6a 00                	push   $0x0
  pushl $53
80107141:	6a 35                	push   $0x35
  jmp alltraps
80107143:	e9 98 f7 ff ff       	jmp    801068e0 <alltraps>

80107148 <vector54>:
.globl vector54
vector54:
  pushl $0
80107148:	6a 00                	push   $0x0
  pushl $54
8010714a:	6a 36                	push   $0x36
  jmp alltraps
8010714c:	e9 8f f7 ff ff       	jmp    801068e0 <alltraps>

80107151 <vector55>:
.globl vector55
vector55:
  pushl $0
80107151:	6a 00                	push   $0x0
  pushl $55
80107153:	6a 37                	push   $0x37
  jmp alltraps
80107155:	e9 86 f7 ff ff       	jmp    801068e0 <alltraps>

8010715a <vector56>:
.globl vector56
vector56:
  pushl $0
8010715a:	6a 00                	push   $0x0
  pushl $56
8010715c:	6a 38                	push   $0x38
  jmp alltraps
8010715e:	e9 7d f7 ff ff       	jmp    801068e0 <alltraps>

80107163 <vector57>:
.globl vector57
vector57:
  pushl $0
80107163:	6a 00                	push   $0x0
  pushl $57
80107165:	6a 39                	push   $0x39
  jmp alltraps
80107167:	e9 74 f7 ff ff       	jmp    801068e0 <alltraps>

8010716c <vector58>:
.globl vector58
vector58:
  pushl $0
8010716c:	6a 00                	push   $0x0
  pushl $58
8010716e:	6a 3a                	push   $0x3a
  jmp alltraps
80107170:	e9 6b f7 ff ff       	jmp    801068e0 <alltraps>

80107175 <vector59>:
.globl vector59
vector59:
  pushl $0
80107175:	6a 00                	push   $0x0
  pushl $59
80107177:	6a 3b                	push   $0x3b
  jmp alltraps
80107179:	e9 62 f7 ff ff       	jmp    801068e0 <alltraps>

8010717e <vector60>:
.globl vector60
vector60:
  pushl $0
8010717e:	6a 00                	push   $0x0
  pushl $60
80107180:	6a 3c                	push   $0x3c
  jmp alltraps
80107182:	e9 59 f7 ff ff       	jmp    801068e0 <alltraps>

80107187 <vector61>:
.globl vector61
vector61:
  pushl $0
80107187:	6a 00                	push   $0x0
  pushl $61
80107189:	6a 3d                	push   $0x3d
  jmp alltraps
8010718b:	e9 50 f7 ff ff       	jmp    801068e0 <alltraps>

80107190 <vector62>:
.globl vector62
vector62:
  pushl $0
80107190:	6a 00                	push   $0x0
  pushl $62
80107192:	6a 3e                	push   $0x3e
  jmp alltraps
80107194:	e9 47 f7 ff ff       	jmp    801068e0 <alltraps>

80107199 <vector63>:
.globl vector63
vector63:
  pushl $0
80107199:	6a 00                	push   $0x0
  pushl $63
8010719b:	6a 3f                	push   $0x3f
  jmp alltraps
8010719d:	e9 3e f7 ff ff       	jmp    801068e0 <alltraps>

801071a2 <vector64>:
.globl vector64
vector64:
  pushl $0
801071a2:	6a 00                	push   $0x0
  pushl $64
801071a4:	6a 40                	push   $0x40
  jmp alltraps
801071a6:	e9 35 f7 ff ff       	jmp    801068e0 <alltraps>

801071ab <vector65>:
.globl vector65
vector65:
  pushl $0
801071ab:	6a 00                	push   $0x0
  pushl $65
801071ad:	6a 41                	push   $0x41
  jmp alltraps
801071af:	e9 2c f7 ff ff       	jmp    801068e0 <alltraps>

801071b4 <vector66>:
.globl vector66
vector66:
  pushl $0
801071b4:	6a 00                	push   $0x0
  pushl $66
801071b6:	6a 42                	push   $0x42
  jmp alltraps
801071b8:	e9 23 f7 ff ff       	jmp    801068e0 <alltraps>

801071bd <vector67>:
.globl vector67
vector67:
  pushl $0
801071bd:	6a 00                	push   $0x0
  pushl $67
801071bf:	6a 43                	push   $0x43
  jmp alltraps
801071c1:	e9 1a f7 ff ff       	jmp    801068e0 <alltraps>

801071c6 <vector68>:
.globl vector68
vector68:
  pushl $0
801071c6:	6a 00                	push   $0x0
  pushl $68
801071c8:	6a 44                	push   $0x44
  jmp alltraps
801071ca:	e9 11 f7 ff ff       	jmp    801068e0 <alltraps>

801071cf <vector69>:
.globl vector69
vector69:
  pushl $0
801071cf:	6a 00                	push   $0x0
  pushl $69
801071d1:	6a 45                	push   $0x45
  jmp alltraps
801071d3:	e9 08 f7 ff ff       	jmp    801068e0 <alltraps>

801071d8 <vector70>:
.globl vector70
vector70:
  pushl $0
801071d8:	6a 00                	push   $0x0
  pushl $70
801071da:	6a 46                	push   $0x46
  jmp alltraps
801071dc:	e9 ff f6 ff ff       	jmp    801068e0 <alltraps>

801071e1 <vector71>:
.globl vector71
vector71:
  pushl $0
801071e1:	6a 00                	push   $0x0
  pushl $71
801071e3:	6a 47                	push   $0x47
  jmp alltraps
801071e5:	e9 f6 f6 ff ff       	jmp    801068e0 <alltraps>

801071ea <vector72>:
.globl vector72
vector72:
  pushl $0
801071ea:	6a 00                	push   $0x0
  pushl $72
801071ec:	6a 48                	push   $0x48
  jmp alltraps
801071ee:	e9 ed f6 ff ff       	jmp    801068e0 <alltraps>

801071f3 <vector73>:
.globl vector73
vector73:
  pushl $0
801071f3:	6a 00                	push   $0x0
  pushl $73
801071f5:	6a 49                	push   $0x49
  jmp alltraps
801071f7:	e9 e4 f6 ff ff       	jmp    801068e0 <alltraps>

801071fc <vector74>:
.globl vector74
vector74:
  pushl $0
801071fc:	6a 00                	push   $0x0
  pushl $74
801071fe:	6a 4a                	push   $0x4a
  jmp alltraps
80107200:	e9 db f6 ff ff       	jmp    801068e0 <alltraps>

80107205 <vector75>:
.globl vector75
vector75:
  pushl $0
80107205:	6a 00                	push   $0x0
  pushl $75
80107207:	6a 4b                	push   $0x4b
  jmp alltraps
80107209:	e9 d2 f6 ff ff       	jmp    801068e0 <alltraps>

8010720e <vector76>:
.globl vector76
vector76:
  pushl $0
8010720e:	6a 00                	push   $0x0
  pushl $76
80107210:	6a 4c                	push   $0x4c
  jmp alltraps
80107212:	e9 c9 f6 ff ff       	jmp    801068e0 <alltraps>

80107217 <vector77>:
.globl vector77
vector77:
  pushl $0
80107217:	6a 00                	push   $0x0
  pushl $77
80107219:	6a 4d                	push   $0x4d
  jmp alltraps
8010721b:	e9 c0 f6 ff ff       	jmp    801068e0 <alltraps>

80107220 <vector78>:
.globl vector78
vector78:
  pushl $0
80107220:	6a 00                	push   $0x0
  pushl $78
80107222:	6a 4e                	push   $0x4e
  jmp alltraps
80107224:	e9 b7 f6 ff ff       	jmp    801068e0 <alltraps>

80107229 <vector79>:
.globl vector79
vector79:
  pushl $0
80107229:	6a 00                	push   $0x0
  pushl $79
8010722b:	6a 4f                	push   $0x4f
  jmp alltraps
8010722d:	e9 ae f6 ff ff       	jmp    801068e0 <alltraps>

80107232 <vector80>:
.globl vector80
vector80:
  pushl $0
80107232:	6a 00                	push   $0x0
  pushl $80
80107234:	6a 50                	push   $0x50
  jmp alltraps
80107236:	e9 a5 f6 ff ff       	jmp    801068e0 <alltraps>

8010723b <vector81>:
.globl vector81
vector81:
  pushl $0
8010723b:	6a 00                	push   $0x0
  pushl $81
8010723d:	6a 51                	push   $0x51
  jmp alltraps
8010723f:	e9 9c f6 ff ff       	jmp    801068e0 <alltraps>

80107244 <vector82>:
.globl vector82
vector82:
  pushl $0
80107244:	6a 00                	push   $0x0
  pushl $82
80107246:	6a 52                	push   $0x52
  jmp alltraps
80107248:	e9 93 f6 ff ff       	jmp    801068e0 <alltraps>

8010724d <vector83>:
.globl vector83
vector83:
  pushl $0
8010724d:	6a 00                	push   $0x0
  pushl $83
8010724f:	6a 53                	push   $0x53
  jmp alltraps
80107251:	e9 8a f6 ff ff       	jmp    801068e0 <alltraps>

80107256 <vector84>:
.globl vector84
vector84:
  pushl $0
80107256:	6a 00                	push   $0x0
  pushl $84
80107258:	6a 54                	push   $0x54
  jmp alltraps
8010725a:	e9 81 f6 ff ff       	jmp    801068e0 <alltraps>

8010725f <vector85>:
.globl vector85
vector85:
  pushl $0
8010725f:	6a 00                	push   $0x0
  pushl $85
80107261:	6a 55                	push   $0x55
  jmp alltraps
80107263:	e9 78 f6 ff ff       	jmp    801068e0 <alltraps>

80107268 <vector86>:
.globl vector86
vector86:
  pushl $0
80107268:	6a 00                	push   $0x0
  pushl $86
8010726a:	6a 56                	push   $0x56
  jmp alltraps
8010726c:	e9 6f f6 ff ff       	jmp    801068e0 <alltraps>

80107271 <vector87>:
.globl vector87
vector87:
  pushl $0
80107271:	6a 00                	push   $0x0
  pushl $87
80107273:	6a 57                	push   $0x57
  jmp alltraps
80107275:	e9 66 f6 ff ff       	jmp    801068e0 <alltraps>

8010727a <vector88>:
.globl vector88
vector88:
  pushl $0
8010727a:	6a 00                	push   $0x0
  pushl $88
8010727c:	6a 58                	push   $0x58
  jmp alltraps
8010727e:	e9 5d f6 ff ff       	jmp    801068e0 <alltraps>

80107283 <vector89>:
.globl vector89
vector89:
  pushl $0
80107283:	6a 00                	push   $0x0
  pushl $89
80107285:	6a 59                	push   $0x59
  jmp alltraps
80107287:	e9 54 f6 ff ff       	jmp    801068e0 <alltraps>

8010728c <vector90>:
.globl vector90
vector90:
  pushl $0
8010728c:	6a 00                	push   $0x0
  pushl $90
8010728e:	6a 5a                	push   $0x5a
  jmp alltraps
80107290:	e9 4b f6 ff ff       	jmp    801068e0 <alltraps>

80107295 <vector91>:
.globl vector91
vector91:
  pushl $0
80107295:	6a 00                	push   $0x0
  pushl $91
80107297:	6a 5b                	push   $0x5b
  jmp alltraps
80107299:	e9 42 f6 ff ff       	jmp    801068e0 <alltraps>

8010729e <vector92>:
.globl vector92
vector92:
  pushl $0
8010729e:	6a 00                	push   $0x0
  pushl $92
801072a0:	6a 5c                	push   $0x5c
  jmp alltraps
801072a2:	e9 39 f6 ff ff       	jmp    801068e0 <alltraps>

801072a7 <vector93>:
.globl vector93
vector93:
  pushl $0
801072a7:	6a 00                	push   $0x0
  pushl $93
801072a9:	6a 5d                	push   $0x5d
  jmp alltraps
801072ab:	e9 30 f6 ff ff       	jmp    801068e0 <alltraps>

801072b0 <vector94>:
.globl vector94
vector94:
  pushl $0
801072b0:	6a 00                	push   $0x0
  pushl $94
801072b2:	6a 5e                	push   $0x5e
  jmp alltraps
801072b4:	e9 27 f6 ff ff       	jmp    801068e0 <alltraps>

801072b9 <vector95>:
.globl vector95
vector95:
  pushl $0
801072b9:	6a 00                	push   $0x0
  pushl $95
801072bb:	6a 5f                	push   $0x5f
  jmp alltraps
801072bd:	e9 1e f6 ff ff       	jmp    801068e0 <alltraps>

801072c2 <vector96>:
.globl vector96
vector96:
  pushl $0
801072c2:	6a 00                	push   $0x0
  pushl $96
801072c4:	6a 60                	push   $0x60
  jmp alltraps
801072c6:	e9 15 f6 ff ff       	jmp    801068e0 <alltraps>

801072cb <vector97>:
.globl vector97
vector97:
  pushl $0
801072cb:	6a 00                	push   $0x0
  pushl $97
801072cd:	6a 61                	push   $0x61
  jmp alltraps
801072cf:	e9 0c f6 ff ff       	jmp    801068e0 <alltraps>

801072d4 <vector98>:
.globl vector98
vector98:
  pushl $0
801072d4:	6a 00                	push   $0x0
  pushl $98
801072d6:	6a 62                	push   $0x62
  jmp alltraps
801072d8:	e9 03 f6 ff ff       	jmp    801068e0 <alltraps>

801072dd <vector99>:
.globl vector99
vector99:
  pushl $0
801072dd:	6a 00                	push   $0x0
  pushl $99
801072df:	6a 63                	push   $0x63
  jmp alltraps
801072e1:	e9 fa f5 ff ff       	jmp    801068e0 <alltraps>

801072e6 <vector100>:
.globl vector100
vector100:
  pushl $0
801072e6:	6a 00                	push   $0x0
  pushl $100
801072e8:	6a 64                	push   $0x64
  jmp alltraps
801072ea:	e9 f1 f5 ff ff       	jmp    801068e0 <alltraps>

801072ef <vector101>:
.globl vector101
vector101:
  pushl $0
801072ef:	6a 00                	push   $0x0
  pushl $101
801072f1:	6a 65                	push   $0x65
  jmp alltraps
801072f3:	e9 e8 f5 ff ff       	jmp    801068e0 <alltraps>

801072f8 <vector102>:
.globl vector102
vector102:
  pushl $0
801072f8:	6a 00                	push   $0x0
  pushl $102
801072fa:	6a 66                	push   $0x66
  jmp alltraps
801072fc:	e9 df f5 ff ff       	jmp    801068e0 <alltraps>

80107301 <vector103>:
.globl vector103
vector103:
  pushl $0
80107301:	6a 00                	push   $0x0
  pushl $103
80107303:	6a 67                	push   $0x67
  jmp alltraps
80107305:	e9 d6 f5 ff ff       	jmp    801068e0 <alltraps>

8010730a <vector104>:
.globl vector104
vector104:
  pushl $0
8010730a:	6a 00                	push   $0x0
  pushl $104
8010730c:	6a 68                	push   $0x68
  jmp alltraps
8010730e:	e9 cd f5 ff ff       	jmp    801068e0 <alltraps>

80107313 <vector105>:
.globl vector105
vector105:
  pushl $0
80107313:	6a 00                	push   $0x0
  pushl $105
80107315:	6a 69                	push   $0x69
  jmp alltraps
80107317:	e9 c4 f5 ff ff       	jmp    801068e0 <alltraps>

8010731c <vector106>:
.globl vector106
vector106:
  pushl $0
8010731c:	6a 00                	push   $0x0
  pushl $106
8010731e:	6a 6a                	push   $0x6a
  jmp alltraps
80107320:	e9 bb f5 ff ff       	jmp    801068e0 <alltraps>

80107325 <vector107>:
.globl vector107
vector107:
  pushl $0
80107325:	6a 00                	push   $0x0
  pushl $107
80107327:	6a 6b                	push   $0x6b
  jmp alltraps
80107329:	e9 b2 f5 ff ff       	jmp    801068e0 <alltraps>

8010732e <vector108>:
.globl vector108
vector108:
  pushl $0
8010732e:	6a 00                	push   $0x0
  pushl $108
80107330:	6a 6c                	push   $0x6c
  jmp alltraps
80107332:	e9 a9 f5 ff ff       	jmp    801068e0 <alltraps>

80107337 <vector109>:
.globl vector109
vector109:
  pushl $0
80107337:	6a 00                	push   $0x0
  pushl $109
80107339:	6a 6d                	push   $0x6d
  jmp alltraps
8010733b:	e9 a0 f5 ff ff       	jmp    801068e0 <alltraps>

80107340 <vector110>:
.globl vector110
vector110:
  pushl $0
80107340:	6a 00                	push   $0x0
  pushl $110
80107342:	6a 6e                	push   $0x6e
  jmp alltraps
80107344:	e9 97 f5 ff ff       	jmp    801068e0 <alltraps>

80107349 <vector111>:
.globl vector111
vector111:
  pushl $0
80107349:	6a 00                	push   $0x0
  pushl $111
8010734b:	6a 6f                	push   $0x6f
  jmp alltraps
8010734d:	e9 8e f5 ff ff       	jmp    801068e0 <alltraps>

80107352 <vector112>:
.globl vector112
vector112:
  pushl $0
80107352:	6a 00                	push   $0x0
  pushl $112
80107354:	6a 70                	push   $0x70
  jmp alltraps
80107356:	e9 85 f5 ff ff       	jmp    801068e0 <alltraps>

8010735b <vector113>:
.globl vector113
vector113:
  pushl $0
8010735b:	6a 00                	push   $0x0
  pushl $113
8010735d:	6a 71                	push   $0x71
  jmp alltraps
8010735f:	e9 7c f5 ff ff       	jmp    801068e0 <alltraps>

80107364 <vector114>:
.globl vector114
vector114:
  pushl $0
80107364:	6a 00                	push   $0x0
  pushl $114
80107366:	6a 72                	push   $0x72
  jmp alltraps
80107368:	e9 73 f5 ff ff       	jmp    801068e0 <alltraps>

8010736d <vector115>:
.globl vector115
vector115:
  pushl $0
8010736d:	6a 00                	push   $0x0
  pushl $115
8010736f:	6a 73                	push   $0x73
  jmp alltraps
80107371:	e9 6a f5 ff ff       	jmp    801068e0 <alltraps>

80107376 <vector116>:
.globl vector116
vector116:
  pushl $0
80107376:	6a 00                	push   $0x0
  pushl $116
80107378:	6a 74                	push   $0x74
  jmp alltraps
8010737a:	e9 61 f5 ff ff       	jmp    801068e0 <alltraps>

8010737f <vector117>:
.globl vector117
vector117:
  pushl $0
8010737f:	6a 00                	push   $0x0
  pushl $117
80107381:	6a 75                	push   $0x75
  jmp alltraps
80107383:	e9 58 f5 ff ff       	jmp    801068e0 <alltraps>

80107388 <vector118>:
.globl vector118
vector118:
  pushl $0
80107388:	6a 00                	push   $0x0
  pushl $118
8010738a:	6a 76                	push   $0x76
  jmp alltraps
8010738c:	e9 4f f5 ff ff       	jmp    801068e0 <alltraps>

80107391 <vector119>:
.globl vector119
vector119:
  pushl $0
80107391:	6a 00                	push   $0x0
  pushl $119
80107393:	6a 77                	push   $0x77
  jmp alltraps
80107395:	e9 46 f5 ff ff       	jmp    801068e0 <alltraps>

8010739a <vector120>:
.globl vector120
vector120:
  pushl $0
8010739a:	6a 00                	push   $0x0
  pushl $120
8010739c:	6a 78                	push   $0x78
  jmp alltraps
8010739e:	e9 3d f5 ff ff       	jmp    801068e0 <alltraps>

801073a3 <vector121>:
.globl vector121
vector121:
  pushl $0
801073a3:	6a 00                	push   $0x0
  pushl $121
801073a5:	6a 79                	push   $0x79
  jmp alltraps
801073a7:	e9 34 f5 ff ff       	jmp    801068e0 <alltraps>

801073ac <vector122>:
.globl vector122
vector122:
  pushl $0
801073ac:	6a 00                	push   $0x0
  pushl $122
801073ae:	6a 7a                	push   $0x7a
  jmp alltraps
801073b0:	e9 2b f5 ff ff       	jmp    801068e0 <alltraps>

801073b5 <vector123>:
.globl vector123
vector123:
  pushl $0
801073b5:	6a 00                	push   $0x0
  pushl $123
801073b7:	6a 7b                	push   $0x7b
  jmp alltraps
801073b9:	e9 22 f5 ff ff       	jmp    801068e0 <alltraps>

801073be <vector124>:
.globl vector124
vector124:
  pushl $0
801073be:	6a 00                	push   $0x0
  pushl $124
801073c0:	6a 7c                	push   $0x7c
  jmp alltraps
801073c2:	e9 19 f5 ff ff       	jmp    801068e0 <alltraps>

801073c7 <vector125>:
.globl vector125
vector125:
  pushl $0
801073c7:	6a 00                	push   $0x0
  pushl $125
801073c9:	6a 7d                	push   $0x7d
  jmp alltraps
801073cb:	e9 10 f5 ff ff       	jmp    801068e0 <alltraps>

801073d0 <vector126>:
.globl vector126
vector126:
  pushl $0
801073d0:	6a 00                	push   $0x0
  pushl $126
801073d2:	6a 7e                	push   $0x7e
  jmp alltraps
801073d4:	e9 07 f5 ff ff       	jmp    801068e0 <alltraps>

801073d9 <vector127>:
.globl vector127
vector127:
  pushl $0
801073d9:	6a 00                	push   $0x0
  pushl $127
801073db:	6a 7f                	push   $0x7f
  jmp alltraps
801073dd:	e9 fe f4 ff ff       	jmp    801068e0 <alltraps>

801073e2 <vector128>:
.globl vector128
vector128:
  pushl $0
801073e2:	6a 00                	push   $0x0
  pushl $128
801073e4:	68 80 00 00 00       	push   $0x80
  jmp alltraps
801073e9:	e9 f2 f4 ff ff       	jmp    801068e0 <alltraps>

801073ee <vector129>:
.globl vector129
vector129:
  pushl $0
801073ee:	6a 00                	push   $0x0
  pushl $129
801073f0:	68 81 00 00 00       	push   $0x81
  jmp alltraps
801073f5:	e9 e6 f4 ff ff       	jmp    801068e0 <alltraps>

801073fa <vector130>:
.globl vector130
vector130:
  pushl $0
801073fa:	6a 00                	push   $0x0
  pushl $130
801073fc:	68 82 00 00 00       	push   $0x82
  jmp alltraps
80107401:	e9 da f4 ff ff       	jmp    801068e0 <alltraps>

80107406 <vector131>:
.globl vector131
vector131:
  pushl $0
80107406:	6a 00                	push   $0x0
  pushl $131
80107408:	68 83 00 00 00       	push   $0x83
  jmp alltraps
8010740d:	e9 ce f4 ff ff       	jmp    801068e0 <alltraps>

80107412 <vector132>:
.globl vector132
vector132:
  pushl $0
80107412:	6a 00                	push   $0x0
  pushl $132
80107414:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80107419:	e9 c2 f4 ff ff       	jmp    801068e0 <alltraps>

8010741e <vector133>:
.globl vector133
vector133:
  pushl $0
8010741e:	6a 00                	push   $0x0
  pushl $133
80107420:	68 85 00 00 00       	push   $0x85
  jmp alltraps
80107425:	e9 b6 f4 ff ff       	jmp    801068e0 <alltraps>

8010742a <vector134>:
.globl vector134
vector134:
  pushl $0
8010742a:	6a 00                	push   $0x0
  pushl $134
8010742c:	68 86 00 00 00       	push   $0x86
  jmp alltraps
80107431:	e9 aa f4 ff ff       	jmp    801068e0 <alltraps>

80107436 <vector135>:
.globl vector135
vector135:
  pushl $0
80107436:	6a 00                	push   $0x0
  pushl $135
80107438:	68 87 00 00 00       	push   $0x87
  jmp alltraps
8010743d:	e9 9e f4 ff ff       	jmp    801068e0 <alltraps>

80107442 <vector136>:
.globl vector136
vector136:
  pushl $0
80107442:	6a 00                	push   $0x0
  pushl $136
80107444:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80107449:	e9 92 f4 ff ff       	jmp    801068e0 <alltraps>

8010744e <vector137>:
.globl vector137
vector137:
  pushl $0
8010744e:	6a 00                	push   $0x0
  pushl $137
80107450:	68 89 00 00 00       	push   $0x89
  jmp alltraps
80107455:	e9 86 f4 ff ff       	jmp    801068e0 <alltraps>

8010745a <vector138>:
.globl vector138
vector138:
  pushl $0
8010745a:	6a 00                	push   $0x0
  pushl $138
8010745c:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80107461:	e9 7a f4 ff ff       	jmp    801068e0 <alltraps>

80107466 <vector139>:
.globl vector139
vector139:
  pushl $0
80107466:	6a 00                	push   $0x0
  pushl $139
80107468:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
8010746d:	e9 6e f4 ff ff       	jmp    801068e0 <alltraps>

80107472 <vector140>:
.globl vector140
vector140:
  pushl $0
80107472:	6a 00                	push   $0x0
  pushl $140
80107474:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
80107479:	e9 62 f4 ff ff       	jmp    801068e0 <alltraps>

8010747e <vector141>:
.globl vector141
vector141:
  pushl $0
8010747e:	6a 00                	push   $0x0
  pushl $141
80107480:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80107485:	e9 56 f4 ff ff       	jmp    801068e0 <alltraps>

8010748a <vector142>:
.globl vector142
vector142:
  pushl $0
8010748a:	6a 00                	push   $0x0
  pushl $142
8010748c:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80107491:	e9 4a f4 ff ff       	jmp    801068e0 <alltraps>

80107496 <vector143>:
.globl vector143
vector143:
  pushl $0
80107496:	6a 00                	push   $0x0
  pushl $143
80107498:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
8010749d:	e9 3e f4 ff ff       	jmp    801068e0 <alltraps>

801074a2 <vector144>:
.globl vector144
vector144:
  pushl $0
801074a2:	6a 00                	push   $0x0
  pushl $144
801074a4:	68 90 00 00 00       	push   $0x90
  jmp alltraps
801074a9:	e9 32 f4 ff ff       	jmp    801068e0 <alltraps>

801074ae <vector145>:
.globl vector145
vector145:
  pushl $0
801074ae:	6a 00                	push   $0x0
  pushl $145
801074b0:	68 91 00 00 00       	push   $0x91
  jmp alltraps
801074b5:	e9 26 f4 ff ff       	jmp    801068e0 <alltraps>

801074ba <vector146>:
.globl vector146
vector146:
  pushl $0
801074ba:	6a 00                	push   $0x0
  pushl $146
801074bc:	68 92 00 00 00       	push   $0x92
  jmp alltraps
801074c1:	e9 1a f4 ff ff       	jmp    801068e0 <alltraps>

801074c6 <vector147>:
.globl vector147
vector147:
  pushl $0
801074c6:	6a 00                	push   $0x0
  pushl $147
801074c8:	68 93 00 00 00       	push   $0x93
  jmp alltraps
801074cd:	e9 0e f4 ff ff       	jmp    801068e0 <alltraps>

801074d2 <vector148>:
.globl vector148
vector148:
  pushl $0
801074d2:	6a 00                	push   $0x0
  pushl $148
801074d4:	68 94 00 00 00       	push   $0x94
  jmp alltraps
801074d9:	e9 02 f4 ff ff       	jmp    801068e0 <alltraps>

801074de <vector149>:
.globl vector149
vector149:
  pushl $0
801074de:	6a 00                	push   $0x0
  pushl $149
801074e0:	68 95 00 00 00       	push   $0x95
  jmp alltraps
801074e5:	e9 f6 f3 ff ff       	jmp    801068e0 <alltraps>

801074ea <vector150>:
.globl vector150
vector150:
  pushl $0
801074ea:	6a 00                	push   $0x0
  pushl $150
801074ec:	68 96 00 00 00       	push   $0x96
  jmp alltraps
801074f1:	e9 ea f3 ff ff       	jmp    801068e0 <alltraps>

801074f6 <vector151>:
.globl vector151
vector151:
  pushl $0
801074f6:	6a 00                	push   $0x0
  pushl $151
801074f8:	68 97 00 00 00       	push   $0x97
  jmp alltraps
801074fd:	e9 de f3 ff ff       	jmp    801068e0 <alltraps>

80107502 <vector152>:
.globl vector152
vector152:
  pushl $0
80107502:	6a 00                	push   $0x0
  pushl $152
80107504:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80107509:	e9 d2 f3 ff ff       	jmp    801068e0 <alltraps>

8010750e <vector153>:
.globl vector153
vector153:
  pushl $0
8010750e:	6a 00                	push   $0x0
  pushl $153
80107510:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80107515:	e9 c6 f3 ff ff       	jmp    801068e0 <alltraps>

8010751a <vector154>:
.globl vector154
vector154:
  pushl $0
8010751a:	6a 00                	push   $0x0
  pushl $154
8010751c:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80107521:	e9 ba f3 ff ff       	jmp    801068e0 <alltraps>

80107526 <vector155>:
.globl vector155
vector155:
  pushl $0
80107526:	6a 00                	push   $0x0
  pushl $155
80107528:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
8010752d:	e9 ae f3 ff ff       	jmp    801068e0 <alltraps>

80107532 <vector156>:
.globl vector156
vector156:
  pushl $0
80107532:	6a 00                	push   $0x0
  pushl $156
80107534:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80107539:	e9 a2 f3 ff ff       	jmp    801068e0 <alltraps>

8010753e <vector157>:
.globl vector157
vector157:
  pushl $0
8010753e:	6a 00                	push   $0x0
  pushl $157
80107540:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80107545:	e9 96 f3 ff ff       	jmp    801068e0 <alltraps>

8010754a <vector158>:
.globl vector158
vector158:
  pushl $0
8010754a:	6a 00                	push   $0x0
  pushl $158
8010754c:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80107551:	e9 8a f3 ff ff       	jmp    801068e0 <alltraps>

80107556 <vector159>:
.globl vector159
vector159:
  pushl $0
80107556:	6a 00                	push   $0x0
  pushl $159
80107558:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
8010755d:	e9 7e f3 ff ff       	jmp    801068e0 <alltraps>

80107562 <vector160>:
.globl vector160
vector160:
  pushl $0
80107562:	6a 00                	push   $0x0
  pushl $160
80107564:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80107569:	e9 72 f3 ff ff       	jmp    801068e0 <alltraps>

8010756e <vector161>:
.globl vector161
vector161:
  pushl $0
8010756e:	6a 00                	push   $0x0
  pushl $161
80107570:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80107575:	e9 66 f3 ff ff       	jmp    801068e0 <alltraps>

8010757a <vector162>:
.globl vector162
vector162:
  pushl $0
8010757a:	6a 00                	push   $0x0
  pushl $162
8010757c:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80107581:	e9 5a f3 ff ff       	jmp    801068e0 <alltraps>

80107586 <vector163>:
.globl vector163
vector163:
  pushl $0
80107586:	6a 00                	push   $0x0
  pushl $163
80107588:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
8010758d:	e9 4e f3 ff ff       	jmp    801068e0 <alltraps>

80107592 <vector164>:
.globl vector164
vector164:
  pushl $0
80107592:	6a 00                	push   $0x0
  pushl $164
80107594:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80107599:	e9 42 f3 ff ff       	jmp    801068e0 <alltraps>

8010759e <vector165>:
.globl vector165
vector165:
  pushl $0
8010759e:	6a 00                	push   $0x0
  pushl $165
801075a0:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
801075a5:	e9 36 f3 ff ff       	jmp    801068e0 <alltraps>

801075aa <vector166>:
.globl vector166
vector166:
  pushl $0
801075aa:	6a 00                	push   $0x0
  pushl $166
801075ac:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
801075b1:	e9 2a f3 ff ff       	jmp    801068e0 <alltraps>

801075b6 <vector167>:
.globl vector167
vector167:
  pushl $0
801075b6:	6a 00                	push   $0x0
  pushl $167
801075b8:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
801075bd:	e9 1e f3 ff ff       	jmp    801068e0 <alltraps>

801075c2 <vector168>:
.globl vector168
vector168:
  pushl $0
801075c2:	6a 00                	push   $0x0
  pushl $168
801075c4:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
801075c9:	e9 12 f3 ff ff       	jmp    801068e0 <alltraps>

801075ce <vector169>:
.globl vector169
vector169:
  pushl $0
801075ce:	6a 00                	push   $0x0
  pushl $169
801075d0:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
801075d5:	e9 06 f3 ff ff       	jmp    801068e0 <alltraps>

801075da <vector170>:
.globl vector170
vector170:
  pushl $0
801075da:	6a 00                	push   $0x0
  pushl $170
801075dc:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
801075e1:	e9 fa f2 ff ff       	jmp    801068e0 <alltraps>

801075e6 <vector171>:
.globl vector171
vector171:
  pushl $0
801075e6:	6a 00                	push   $0x0
  pushl $171
801075e8:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
801075ed:	e9 ee f2 ff ff       	jmp    801068e0 <alltraps>

801075f2 <vector172>:
.globl vector172
vector172:
  pushl $0
801075f2:	6a 00                	push   $0x0
  pushl $172
801075f4:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
801075f9:	e9 e2 f2 ff ff       	jmp    801068e0 <alltraps>

801075fe <vector173>:
.globl vector173
vector173:
  pushl $0
801075fe:	6a 00                	push   $0x0
  pushl $173
80107600:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80107605:	e9 d6 f2 ff ff       	jmp    801068e0 <alltraps>

8010760a <vector174>:
.globl vector174
vector174:
  pushl $0
8010760a:	6a 00                	push   $0x0
  pushl $174
8010760c:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80107611:	e9 ca f2 ff ff       	jmp    801068e0 <alltraps>

80107616 <vector175>:
.globl vector175
vector175:
  pushl $0
80107616:	6a 00                	push   $0x0
  pushl $175
80107618:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
8010761d:	e9 be f2 ff ff       	jmp    801068e0 <alltraps>

80107622 <vector176>:
.globl vector176
vector176:
  pushl $0
80107622:	6a 00                	push   $0x0
  pushl $176
80107624:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80107629:	e9 b2 f2 ff ff       	jmp    801068e0 <alltraps>

8010762e <vector177>:
.globl vector177
vector177:
  pushl $0
8010762e:	6a 00                	push   $0x0
  pushl $177
80107630:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80107635:	e9 a6 f2 ff ff       	jmp    801068e0 <alltraps>

8010763a <vector178>:
.globl vector178
vector178:
  pushl $0
8010763a:	6a 00                	push   $0x0
  pushl $178
8010763c:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80107641:	e9 9a f2 ff ff       	jmp    801068e0 <alltraps>

80107646 <vector179>:
.globl vector179
vector179:
  pushl $0
80107646:	6a 00                	push   $0x0
  pushl $179
80107648:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
8010764d:	e9 8e f2 ff ff       	jmp    801068e0 <alltraps>

80107652 <vector180>:
.globl vector180
vector180:
  pushl $0
80107652:	6a 00                	push   $0x0
  pushl $180
80107654:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80107659:	e9 82 f2 ff ff       	jmp    801068e0 <alltraps>

8010765e <vector181>:
.globl vector181
vector181:
  pushl $0
8010765e:	6a 00                	push   $0x0
  pushl $181
80107660:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80107665:	e9 76 f2 ff ff       	jmp    801068e0 <alltraps>

8010766a <vector182>:
.globl vector182
vector182:
  pushl $0
8010766a:	6a 00                	push   $0x0
  pushl $182
8010766c:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80107671:	e9 6a f2 ff ff       	jmp    801068e0 <alltraps>

80107676 <vector183>:
.globl vector183
vector183:
  pushl $0
80107676:	6a 00                	push   $0x0
  pushl $183
80107678:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
8010767d:	e9 5e f2 ff ff       	jmp    801068e0 <alltraps>

80107682 <vector184>:
.globl vector184
vector184:
  pushl $0
80107682:	6a 00                	push   $0x0
  pushl $184
80107684:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80107689:	e9 52 f2 ff ff       	jmp    801068e0 <alltraps>

8010768e <vector185>:
.globl vector185
vector185:
  pushl $0
8010768e:	6a 00                	push   $0x0
  pushl $185
80107690:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80107695:	e9 46 f2 ff ff       	jmp    801068e0 <alltraps>

8010769a <vector186>:
.globl vector186
vector186:
  pushl $0
8010769a:	6a 00                	push   $0x0
  pushl $186
8010769c:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
801076a1:	e9 3a f2 ff ff       	jmp    801068e0 <alltraps>

801076a6 <vector187>:
.globl vector187
vector187:
  pushl $0
801076a6:	6a 00                	push   $0x0
  pushl $187
801076a8:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
801076ad:	e9 2e f2 ff ff       	jmp    801068e0 <alltraps>

801076b2 <vector188>:
.globl vector188
vector188:
  pushl $0
801076b2:	6a 00                	push   $0x0
  pushl $188
801076b4:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
801076b9:	e9 22 f2 ff ff       	jmp    801068e0 <alltraps>

801076be <vector189>:
.globl vector189
vector189:
  pushl $0
801076be:	6a 00                	push   $0x0
  pushl $189
801076c0:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
801076c5:	e9 16 f2 ff ff       	jmp    801068e0 <alltraps>

801076ca <vector190>:
.globl vector190
vector190:
  pushl $0
801076ca:	6a 00                	push   $0x0
  pushl $190
801076cc:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
801076d1:	e9 0a f2 ff ff       	jmp    801068e0 <alltraps>

801076d6 <vector191>:
.globl vector191
vector191:
  pushl $0
801076d6:	6a 00                	push   $0x0
  pushl $191
801076d8:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
801076dd:	e9 fe f1 ff ff       	jmp    801068e0 <alltraps>

801076e2 <vector192>:
.globl vector192
vector192:
  pushl $0
801076e2:	6a 00                	push   $0x0
  pushl $192
801076e4:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
801076e9:	e9 f2 f1 ff ff       	jmp    801068e0 <alltraps>

801076ee <vector193>:
.globl vector193
vector193:
  pushl $0
801076ee:	6a 00                	push   $0x0
  pushl $193
801076f0:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
801076f5:	e9 e6 f1 ff ff       	jmp    801068e0 <alltraps>

801076fa <vector194>:
.globl vector194
vector194:
  pushl $0
801076fa:	6a 00                	push   $0x0
  pushl $194
801076fc:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80107701:	e9 da f1 ff ff       	jmp    801068e0 <alltraps>

80107706 <vector195>:
.globl vector195
vector195:
  pushl $0
80107706:	6a 00                	push   $0x0
  pushl $195
80107708:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
8010770d:	e9 ce f1 ff ff       	jmp    801068e0 <alltraps>

80107712 <vector196>:
.globl vector196
vector196:
  pushl $0
80107712:	6a 00                	push   $0x0
  pushl $196
80107714:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80107719:	e9 c2 f1 ff ff       	jmp    801068e0 <alltraps>

8010771e <vector197>:
.globl vector197
vector197:
  pushl $0
8010771e:	6a 00                	push   $0x0
  pushl $197
80107720:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80107725:	e9 b6 f1 ff ff       	jmp    801068e0 <alltraps>

8010772a <vector198>:
.globl vector198
vector198:
  pushl $0
8010772a:	6a 00                	push   $0x0
  pushl $198
8010772c:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80107731:	e9 aa f1 ff ff       	jmp    801068e0 <alltraps>

80107736 <vector199>:
.globl vector199
vector199:
  pushl $0
80107736:	6a 00                	push   $0x0
  pushl $199
80107738:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
8010773d:	e9 9e f1 ff ff       	jmp    801068e0 <alltraps>

80107742 <vector200>:
.globl vector200
vector200:
  pushl $0
80107742:	6a 00                	push   $0x0
  pushl $200
80107744:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80107749:	e9 92 f1 ff ff       	jmp    801068e0 <alltraps>

8010774e <vector201>:
.globl vector201
vector201:
  pushl $0
8010774e:	6a 00                	push   $0x0
  pushl $201
80107750:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80107755:	e9 86 f1 ff ff       	jmp    801068e0 <alltraps>

8010775a <vector202>:
.globl vector202
vector202:
  pushl $0
8010775a:	6a 00                	push   $0x0
  pushl $202
8010775c:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80107761:	e9 7a f1 ff ff       	jmp    801068e0 <alltraps>

80107766 <vector203>:
.globl vector203
vector203:
  pushl $0
80107766:	6a 00                	push   $0x0
  pushl $203
80107768:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
8010776d:	e9 6e f1 ff ff       	jmp    801068e0 <alltraps>

80107772 <vector204>:
.globl vector204
vector204:
  pushl $0
80107772:	6a 00                	push   $0x0
  pushl $204
80107774:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80107779:	e9 62 f1 ff ff       	jmp    801068e0 <alltraps>

8010777e <vector205>:
.globl vector205
vector205:
  pushl $0
8010777e:	6a 00                	push   $0x0
  pushl $205
80107780:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80107785:	e9 56 f1 ff ff       	jmp    801068e0 <alltraps>

8010778a <vector206>:
.globl vector206
vector206:
  pushl $0
8010778a:	6a 00                	push   $0x0
  pushl $206
8010778c:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80107791:	e9 4a f1 ff ff       	jmp    801068e0 <alltraps>

80107796 <vector207>:
.globl vector207
vector207:
  pushl $0
80107796:	6a 00                	push   $0x0
  pushl $207
80107798:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
8010779d:	e9 3e f1 ff ff       	jmp    801068e0 <alltraps>

801077a2 <vector208>:
.globl vector208
vector208:
  pushl $0
801077a2:	6a 00                	push   $0x0
  pushl $208
801077a4:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
801077a9:	e9 32 f1 ff ff       	jmp    801068e0 <alltraps>

801077ae <vector209>:
.globl vector209
vector209:
  pushl $0
801077ae:	6a 00                	push   $0x0
  pushl $209
801077b0:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
801077b5:	e9 26 f1 ff ff       	jmp    801068e0 <alltraps>

801077ba <vector210>:
.globl vector210
vector210:
  pushl $0
801077ba:	6a 00                	push   $0x0
  pushl $210
801077bc:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
801077c1:	e9 1a f1 ff ff       	jmp    801068e0 <alltraps>

801077c6 <vector211>:
.globl vector211
vector211:
  pushl $0
801077c6:	6a 00                	push   $0x0
  pushl $211
801077c8:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
801077cd:	e9 0e f1 ff ff       	jmp    801068e0 <alltraps>

801077d2 <vector212>:
.globl vector212
vector212:
  pushl $0
801077d2:	6a 00                	push   $0x0
  pushl $212
801077d4:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
801077d9:	e9 02 f1 ff ff       	jmp    801068e0 <alltraps>

801077de <vector213>:
.globl vector213
vector213:
  pushl $0
801077de:	6a 00                	push   $0x0
  pushl $213
801077e0:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
801077e5:	e9 f6 f0 ff ff       	jmp    801068e0 <alltraps>

801077ea <vector214>:
.globl vector214
vector214:
  pushl $0
801077ea:	6a 00                	push   $0x0
  pushl $214
801077ec:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
801077f1:	e9 ea f0 ff ff       	jmp    801068e0 <alltraps>

801077f6 <vector215>:
.globl vector215
vector215:
  pushl $0
801077f6:	6a 00                	push   $0x0
  pushl $215
801077f8:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
801077fd:	e9 de f0 ff ff       	jmp    801068e0 <alltraps>

80107802 <vector216>:
.globl vector216
vector216:
  pushl $0
80107802:	6a 00                	push   $0x0
  pushl $216
80107804:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80107809:	e9 d2 f0 ff ff       	jmp    801068e0 <alltraps>

8010780e <vector217>:
.globl vector217
vector217:
  pushl $0
8010780e:	6a 00                	push   $0x0
  pushl $217
80107810:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80107815:	e9 c6 f0 ff ff       	jmp    801068e0 <alltraps>

8010781a <vector218>:
.globl vector218
vector218:
  pushl $0
8010781a:	6a 00                	push   $0x0
  pushl $218
8010781c:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80107821:	e9 ba f0 ff ff       	jmp    801068e0 <alltraps>

80107826 <vector219>:
.globl vector219
vector219:
  pushl $0
80107826:	6a 00                	push   $0x0
  pushl $219
80107828:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
8010782d:	e9 ae f0 ff ff       	jmp    801068e0 <alltraps>

80107832 <vector220>:
.globl vector220
vector220:
  pushl $0
80107832:	6a 00                	push   $0x0
  pushl $220
80107834:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80107839:	e9 a2 f0 ff ff       	jmp    801068e0 <alltraps>

8010783e <vector221>:
.globl vector221
vector221:
  pushl $0
8010783e:	6a 00                	push   $0x0
  pushl $221
80107840:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80107845:	e9 96 f0 ff ff       	jmp    801068e0 <alltraps>

8010784a <vector222>:
.globl vector222
vector222:
  pushl $0
8010784a:	6a 00                	push   $0x0
  pushl $222
8010784c:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80107851:	e9 8a f0 ff ff       	jmp    801068e0 <alltraps>

80107856 <vector223>:
.globl vector223
vector223:
  pushl $0
80107856:	6a 00                	push   $0x0
  pushl $223
80107858:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
8010785d:	e9 7e f0 ff ff       	jmp    801068e0 <alltraps>

80107862 <vector224>:
.globl vector224
vector224:
  pushl $0
80107862:	6a 00                	push   $0x0
  pushl $224
80107864:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80107869:	e9 72 f0 ff ff       	jmp    801068e0 <alltraps>

8010786e <vector225>:
.globl vector225
vector225:
  pushl $0
8010786e:	6a 00                	push   $0x0
  pushl $225
80107870:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80107875:	e9 66 f0 ff ff       	jmp    801068e0 <alltraps>

8010787a <vector226>:
.globl vector226
vector226:
  pushl $0
8010787a:	6a 00                	push   $0x0
  pushl $226
8010787c:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80107881:	e9 5a f0 ff ff       	jmp    801068e0 <alltraps>

80107886 <vector227>:
.globl vector227
vector227:
  pushl $0
80107886:	6a 00                	push   $0x0
  pushl $227
80107888:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
8010788d:	e9 4e f0 ff ff       	jmp    801068e0 <alltraps>

80107892 <vector228>:
.globl vector228
vector228:
  pushl $0
80107892:	6a 00                	push   $0x0
  pushl $228
80107894:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80107899:	e9 42 f0 ff ff       	jmp    801068e0 <alltraps>

8010789e <vector229>:
.globl vector229
vector229:
  pushl $0
8010789e:	6a 00                	push   $0x0
  pushl $229
801078a0:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
801078a5:	e9 36 f0 ff ff       	jmp    801068e0 <alltraps>

801078aa <vector230>:
.globl vector230
vector230:
  pushl $0
801078aa:	6a 00                	push   $0x0
  pushl $230
801078ac:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
801078b1:	e9 2a f0 ff ff       	jmp    801068e0 <alltraps>

801078b6 <vector231>:
.globl vector231
vector231:
  pushl $0
801078b6:	6a 00                	push   $0x0
  pushl $231
801078b8:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
801078bd:	e9 1e f0 ff ff       	jmp    801068e0 <alltraps>

801078c2 <vector232>:
.globl vector232
vector232:
  pushl $0
801078c2:	6a 00                	push   $0x0
  pushl $232
801078c4:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
801078c9:	e9 12 f0 ff ff       	jmp    801068e0 <alltraps>

801078ce <vector233>:
.globl vector233
vector233:
  pushl $0
801078ce:	6a 00                	push   $0x0
  pushl $233
801078d0:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
801078d5:	e9 06 f0 ff ff       	jmp    801068e0 <alltraps>

801078da <vector234>:
.globl vector234
vector234:
  pushl $0
801078da:	6a 00                	push   $0x0
  pushl $234
801078dc:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
801078e1:	e9 fa ef ff ff       	jmp    801068e0 <alltraps>

801078e6 <vector235>:
.globl vector235
vector235:
  pushl $0
801078e6:	6a 00                	push   $0x0
  pushl $235
801078e8:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
801078ed:	e9 ee ef ff ff       	jmp    801068e0 <alltraps>

801078f2 <vector236>:
.globl vector236
vector236:
  pushl $0
801078f2:	6a 00                	push   $0x0
  pushl $236
801078f4:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
801078f9:	e9 e2 ef ff ff       	jmp    801068e0 <alltraps>

801078fe <vector237>:
.globl vector237
vector237:
  pushl $0
801078fe:	6a 00                	push   $0x0
  pushl $237
80107900:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80107905:	e9 d6 ef ff ff       	jmp    801068e0 <alltraps>

8010790a <vector238>:
.globl vector238
vector238:
  pushl $0
8010790a:	6a 00                	push   $0x0
  pushl $238
8010790c:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80107911:	e9 ca ef ff ff       	jmp    801068e0 <alltraps>

80107916 <vector239>:
.globl vector239
vector239:
  pushl $0
80107916:	6a 00                	push   $0x0
  pushl $239
80107918:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
8010791d:	e9 be ef ff ff       	jmp    801068e0 <alltraps>

80107922 <vector240>:
.globl vector240
vector240:
  pushl $0
80107922:	6a 00                	push   $0x0
  pushl $240
80107924:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80107929:	e9 b2 ef ff ff       	jmp    801068e0 <alltraps>

8010792e <vector241>:
.globl vector241
vector241:
  pushl $0
8010792e:	6a 00                	push   $0x0
  pushl $241
80107930:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80107935:	e9 a6 ef ff ff       	jmp    801068e0 <alltraps>

8010793a <vector242>:
.globl vector242
vector242:
  pushl $0
8010793a:	6a 00                	push   $0x0
  pushl $242
8010793c:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80107941:	e9 9a ef ff ff       	jmp    801068e0 <alltraps>

80107946 <vector243>:
.globl vector243
vector243:
  pushl $0
80107946:	6a 00                	push   $0x0
  pushl $243
80107948:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
8010794d:	e9 8e ef ff ff       	jmp    801068e0 <alltraps>

80107952 <vector244>:
.globl vector244
vector244:
  pushl $0
80107952:	6a 00                	push   $0x0
  pushl $244
80107954:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80107959:	e9 82 ef ff ff       	jmp    801068e0 <alltraps>

8010795e <vector245>:
.globl vector245
vector245:
  pushl $0
8010795e:	6a 00                	push   $0x0
  pushl $245
80107960:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80107965:	e9 76 ef ff ff       	jmp    801068e0 <alltraps>

8010796a <vector246>:
.globl vector246
vector246:
  pushl $0
8010796a:	6a 00                	push   $0x0
  pushl $246
8010796c:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80107971:	e9 6a ef ff ff       	jmp    801068e0 <alltraps>

80107976 <vector247>:
.globl vector247
vector247:
  pushl $0
80107976:	6a 00                	push   $0x0
  pushl $247
80107978:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
8010797d:	e9 5e ef ff ff       	jmp    801068e0 <alltraps>

80107982 <vector248>:
.globl vector248
vector248:
  pushl $0
80107982:	6a 00                	push   $0x0
  pushl $248
80107984:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80107989:	e9 52 ef ff ff       	jmp    801068e0 <alltraps>

8010798e <vector249>:
.globl vector249
vector249:
  pushl $0
8010798e:	6a 00                	push   $0x0
  pushl $249
80107990:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80107995:	e9 46 ef ff ff       	jmp    801068e0 <alltraps>

8010799a <vector250>:
.globl vector250
vector250:
  pushl $0
8010799a:	6a 00                	push   $0x0
  pushl $250
8010799c:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
801079a1:	e9 3a ef ff ff       	jmp    801068e0 <alltraps>

801079a6 <vector251>:
.globl vector251
vector251:
  pushl $0
801079a6:	6a 00                	push   $0x0
  pushl $251
801079a8:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
801079ad:	e9 2e ef ff ff       	jmp    801068e0 <alltraps>

801079b2 <vector252>:
.globl vector252
vector252:
  pushl $0
801079b2:	6a 00                	push   $0x0
  pushl $252
801079b4:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
801079b9:	e9 22 ef ff ff       	jmp    801068e0 <alltraps>

801079be <vector253>:
.globl vector253
vector253:
  pushl $0
801079be:	6a 00                	push   $0x0
  pushl $253
801079c0:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
801079c5:	e9 16 ef ff ff       	jmp    801068e0 <alltraps>

801079ca <vector254>:
.globl vector254
vector254:
  pushl $0
801079ca:	6a 00                	push   $0x0
  pushl $254
801079cc:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
801079d1:	e9 0a ef ff ff       	jmp    801068e0 <alltraps>

801079d6 <vector255>:
.globl vector255
vector255:
  pushl $0
801079d6:	6a 00                	push   $0x0
  pushl $255
801079d8:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
801079dd:	e9 fe ee ff ff       	jmp    801068e0 <alltraps>
	...

801079e4 <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
801079e4:	55                   	push   %ebp
801079e5:	89 e5                	mov    %esp,%ebp
801079e7:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
801079ea:	8b 45 0c             	mov    0xc(%ebp),%eax
801079ed:	83 e8 01             	sub    $0x1,%eax
801079f0:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
801079f4:	8b 45 08             	mov    0x8(%ebp),%eax
801079f7:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
801079fb:	8b 45 08             	mov    0x8(%ebp),%eax
801079fe:	c1 e8 10             	shr    $0x10,%eax
80107a01:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
80107a05:	8d 45 fa             	lea    -0x6(%ebp),%eax
80107a08:	0f 01 10             	lgdtl  (%eax)
}
80107a0b:	c9                   	leave  
80107a0c:	c3                   	ret    

80107a0d <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
80107a0d:	55                   	push   %ebp
80107a0e:	89 e5                	mov    %esp,%ebp
80107a10:	83 ec 04             	sub    $0x4,%esp
80107a13:	8b 45 08             	mov    0x8(%ebp),%eax
80107a16:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
80107a1a:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80107a1e:	0f 00 d8             	ltr    %ax
}
80107a21:	c9                   	leave  
80107a22:	c3                   	ret    

80107a23 <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
80107a23:	55                   	push   %ebp
80107a24:	89 e5                	mov    %esp,%ebp
80107a26:	83 ec 04             	sub    $0x4,%esp
80107a29:	8b 45 08             	mov    0x8(%ebp),%eax
80107a2c:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
80107a30:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80107a34:	8e e8                	mov    %eax,%gs
}
80107a36:	c9                   	leave  
80107a37:	c3                   	ret    

80107a38 <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
80107a38:	55                   	push   %ebp
80107a39:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
80107a3b:	8b 45 08             	mov    0x8(%ebp),%eax
80107a3e:	0f 22 d8             	mov    %eax,%cr3
}
80107a41:	5d                   	pop    %ebp
80107a42:	c3                   	ret    

80107a43 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80107a43:	55                   	push   %ebp
80107a44:	89 e5                	mov    %esp,%ebp
80107a46:	8b 45 08             	mov    0x8(%ebp),%eax
80107a49:	05 00 00 00 80       	add    $0x80000000,%eax
80107a4e:	5d                   	pop    %ebp
80107a4f:	c3                   	ret    

80107a50 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80107a50:	55                   	push   %ebp
80107a51:	89 e5                	mov    %esp,%ebp
80107a53:	8b 45 08             	mov    0x8(%ebp),%eax
80107a56:	05 00 00 00 80       	add    $0x80000000,%eax
80107a5b:	5d                   	pop    %ebp
80107a5c:	c3                   	ret    

80107a5d <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
80107a5d:	55                   	push   %ebp
80107a5e:	89 e5                	mov    %esp,%ebp
80107a60:	53                   	push   %ebx
80107a61:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
80107a64:	e8 30 b4 ff ff       	call   80102e99 <cpunum>
80107a69:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80107a6f:	05 20 f9 10 80       	add    $0x8010f920,%eax
80107a74:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80107a77:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a7a:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
80107a80:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a83:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
80107a89:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a8c:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
80107a90:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a93:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107a97:	83 e2 f0             	and    $0xfffffff0,%edx
80107a9a:	83 ca 0a             	or     $0xa,%edx
80107a9d:	88 50 7d             	mov    %dl,0x7d(%eax)
80107aa0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107aa3:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107aa7:	83 ca 10             	or     $0x10,%edx
80107aaa:	88 50 7d             	mov    %dl,0x7d(%eax)
80107aad:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ab0:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107ab4:	83 e2 9f             	and    $0xffffff9f,%edx
80107ab7:	88 50 7d             	mov    %dl,0x7d(%eax)
80107aba:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107abd:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107ac1:	83 ca 80             	or     $0xffffff80,%edx
80107ac4:	88 50 7d             	mov    %dl,0x7d(%eax)
80107ac7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107aca:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107ace:	83 ca 0f             	or     $0xf,%edx
80107ad1:	88 50 7e             	mov    %dl,0x7e(%eax)
80107ad4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ad7:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107adb:	83 e2 ef             	and    $0xffffffef,%edx
80107ade:	88 50 7e             	mov    %dl,0x7e(%eax)
80107ae1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ae4:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107ae8:	83 e2 df             	and    $0xffffffdf,%edx
80107aeb:	88 50 7e             	mov    %dl,0x7e(%eax)
80107aee:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107af1:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107af5:	83 ca 40             	or     $0x40,%edx
80107af8:	88 50 7e             	mov    %dl,0x7e(%eax)
80107afb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107afe:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107b02:	83 ca 80             	or     $0xffffff80,%edx
80107b05:	88 50 7e             	mov    %dl,0x7e(%eax)
80107b08:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b0b:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80107b0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b12:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
80107b19:	ff ff 
80107b1b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b1e:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
80107b25:	00 00 
80107b27:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b2a:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
80107b31:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b34:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107b3b:	83 e2 f0             	and    $0xfffffff0,%edx
80107b3e:	83 ca 02             	or     $0x2,%edx
80107b41:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107b47:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b4a:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107b51:	83 ca 10             	or     $0x10,%edx
80107b54:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107b5a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b5d:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107b64:	83 e2 9f             	and    $0xffffff9f,%edx
80107b67:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107b6d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b70:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107b77:	83 ca 80             	or     $0xffffff80,%edx
80107b7a:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107b80:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b83:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107b8a:	83 ca 0f             	or     $0xf,%edx
80107b8d:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107b93:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b96:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107b9d:	83 e2 ef             	and    $0xffffffef,%edx
80107ba0:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107ba6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ba9:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107bb0:	83 e2 df             	and    $0xffffffdf,%edx
80107bb3:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107bb9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107bbc:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107bc3:	83 ca 40             	or     $0x40,%edx
80107bc6:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107bcc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107bcf:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107bd6:	83 ca 80             	or     $0xffffff80,%edx
80107bd9:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107bdf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107be2:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80107be9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107bec:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
80107bf3:	ff ff 
80107bf5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107bf8:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
80107bff:	00 00 
80107c01:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c04:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
80107c0b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c0e:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107c15:	83 e2 f0             	and    $0xfffffff0,%edx
80107c18:	83 ca 0a             	or     $0xa,%edx
80107c1b:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107c21:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c24:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107c2b:	83 ca 10             	or     $0x10,%edx
80107c2e:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107c34:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c37:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107c3e:	83 ca 60             	or     $0x60,%edx
80107c41:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107c47:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c4a:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107c51:	83 ca 80             	or     $0xffffff80,%edx
80107c54:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107c5a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c5d:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107c64:	83 ca 0f             	or     $0xf,%edx
80107c67:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107c6d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c70:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107c77:	83 e2 ef             	and    $0xffffffef,%edx
80107c7a:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107c80:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c83:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107c8a:	83 e2 df             	and    $0xffffffdf,%edx
80107c8d:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107c93:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c96:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107c9d:	83 ca 40             	or     $0x40,%edx
80107ca0:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107ca6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ca9:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107cb0:	83 ca 80             	or     $0xffffff80,%edx
80107cb3:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107cb9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107cbc:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80107cc3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107cc6:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
80107ccd:	ff ff 
80107ccf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107cd2:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
80107cd9:	00 00 
80107cdb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107cde:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
80107ce5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ce8:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107cef:	83 e2 f0             	and    $0xfffffff0,%edx
80107cf2:	83 ca 02             	or     $0x2,%edx
80107cf5:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107cfb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107cfe:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107d05:	83 ca 10             	or     $0x10,%edx
80107d08:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107d0e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d11:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107d18:	83 ca 60             	or     $0x60,%edx
80107d1b:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107d21:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d24:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107d2b:	83 ca 80             	or     $0xffffff80,%edx
80107d2e:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107d34:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d37:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107d3e:	83 ca 0f             	or     $0xf,%edx
80107d41:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107d47:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d4a:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107d51:	83 e2 ef             	and    $0xffffffef,%edx
80107d54:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107d5a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d5d:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107d64:	83 e2 df             	and    $0xffffffdf,%edx
80107d67:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107d6d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d70:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107d77:	83 ca 40             	or     $0x40,%edx
80107d7a:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107d80:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d83:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107d8a:	83 ca 80             	or     $0xffffff80,%edx
80107d8d:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107d93:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d96:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
80107d9d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107da0:	05 b4 00 00 00       	add    $0xb4,%eax
80107da5:	89 c3                	mov    %eax,%ebx
80107da7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107daa:	05 b4 00 00 00       	add    $0xb4,%eax
80107daf:	c1 e8 10             	shr    $0x10,%eax
80107db2:	89 c1                	mov    %eax,%ecx
80107db4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107db7:	05 b4 00 00 00       	add    $0xb4,%eax
80107dbc:	c1 e8 18             	shr    $0x18,%eax
80107dbf:	89 c2                	mov    %eax,%edx
80107dc1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107dc4:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
80107dcb:	00 00 
80107dcd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107dd0:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
80107dd7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107dda:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
80107de0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107de3:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107dea:	83 e1 f0             	and    $0xfffffff0,%ecx
80107ded:	83 c9 02             	or     $0x2,%ecx
80107df0:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107df6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107df9:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107e00:	83 c9 10             	or     $0x10,%ecx
80107e03:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107e09:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e0c:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107e13:	83 e1 9f             	and    $0xffffff9f,%ecx
80107e16:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107e1c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e1f:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107e26:	83 c9 80             	or     $0xffffff80,%ecx
80107e29:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107e2f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e32:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107e39:	83 e1 f0             	and    $0xfffffff0,%ecx
80107e3c:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107e42:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e45:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107e4c:	83 e1 ef             	and    $0xffffffef,%ecx
80107e4f:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107e55:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e58:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107e5f:	83 e1 df             	and    $0xffffffdf,%ecx
80107e62:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107e68:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e6b:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107e72:	83 c9 40             	or     $0x40,%ecx
80107e75:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107e7b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e7e:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107e85:	83 c9 80             	or     $0xffffff80,%ecx
80107e88:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107e8e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e91:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
80107e97:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e9a:	83 c0 70             	add    $0x70,%eax
80107e9d:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
80107ea4:	00 
80107ea5:	89 04 24             	mov    %eax,(%esp)
80107ea8:	e8 37 fb ff ff       	call   801079e4 <lgdt>
  loadgs(SEG_KCPU << 3);
80107ead:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
80107eb4:	e8 6a fb ff ff       	call   80107a23 <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
80107eb9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ebc:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
80107ec2:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80107ec9:	00 00 00 00 
}
80107ecd:	83 c4 24             	add    $0x24,%esp
80107ed0:	5b                   	pop    %ebx
80107ed1:	5d                   	pop    %ebp
80107ed2:	c3                   	ret    

80107ed3 <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80107ed3:	55                   	push   %ebp
80107ed4:	89 e5                	mov    %esp,%ebp
80107ed6:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80107ed9:	8b 45 0c             	mov    0xc(%ebp),%eax
80107edc:	c1 e8 16             	shr    $0x16,%eax
80107edf:	c1 e0 02             	shl    $0x2,%eax
80107ee2:	03 45 08             	add    0x8(%ebp),%eax
80107ee5:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
80107ee8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107eeb:	8b 00                	mov    (%eax),%eax
80107eed:	83 e0 01             	and    $0x1,%eax
80107ef0:	84 c0                	test   %al,%al
80107ef2:	74 17                	je     80107f0b <walkpgdir+0x38>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
80107ef4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107ef7:	8b 00                	mov    (%eax),%eax
80107ef9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107efe:	89 04 24             	mov    %eax,(%esp)
80107f01:	e8 4a fb ff ff       	call   80107a50 <p2v>
80107f06:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107f09:	eb 4b                	jmp    80107f56 <walkpgdir+0x83>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
80107f0b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80107f0f:	74 0e                	je     80107f1f <walkpgdir+0x4c>
80107f11:	e8 f5 ab ff ff       	call   80102b0b <kalloc>
80107f16:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107f19:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80107f1d:	75 07                	jne    80107f26 <walkpgdir+0x53>
      return 0;
80107f1f:	b8 00 00 00 00       	mov    $0x0,%eax
80107f24:	eb 41                	jmp    80107f67 <walkpgdir+0x94>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
80107f26:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107f2d:	00 
80107f2e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107f35:	00 
80107f36:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f39:	89 04 24             	mov    %eax,(%esp)
80107f3c:	e8 fd d3 ff ff       	call   8010533e <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
80107f41:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f44:	89 04 24             	mov    %eax,(%esp)
80107f47:	e8 f7 fa ff ff       	call   80107a43 <v2p>
80107f4c:	89 c2                	mov    %eax,%edx
80107f4e:	83 ca 07             	or     $0x7,%edx
80107f51:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107f54:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
80107f56:	8b 45 0c             	mov    0xc(%ebp),%eax
80107f59:	c1 e8 0c             	shr    $0xc,%eax
80107f5c:	25 ff 03 00 00       	and    $0x3ff,%eax
80107f61:	c1 e0 02             	shl    $0x2,%eax
80107f64:	03 45 f4             	add    -0xc(%ebp),%eax
}
80107f67:	c9                   	leave  
80107f68:	c3                   	ret    

80107f69 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80107f69:	55                   	push   %ebp
80107f6a:	89 e5                	mov    %esp,%ebp
80107f6c:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
80107f6f:	8b 45 0c             	mov    0xc(%ebp),%eax
80107f72:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107f77:	89 45 f4             	mov    %eax,-0xc(%ebp)
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80107f7a:	8b 45 0c             	mov    0xc(%ebp),%eax
80107f7d:	03 45 10             	add    0x10(%ebp),%eax
80107f80:	83 e8 01             	sub    $0x1,%eax
80107f83:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107f88:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80107f8b:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80107f92:	00 
80107f93:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f96:	89 44 24 04          	mov    %eax,0x4(%esp)
80107f9a:	8b 45 08             	mov    0x8(%ebp),%eax
80107f9d:	89 04 24             	mov    %eax,(%esp)
80107fa0:	e8 2e ff ff ff       	call   80107ed3 <walkpgdir>
80107fa5:	89 45 ec             	mov    %eax,-0x14(%ebp)
80107fa8:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80107fac:	75 07                	jne    80107fb5 <mappages+0x4c>
      return -1;
80107fae:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107fb3:	eb 46                	jmp    80107ffb <mappages+0x92>
    if(*pte & PTE_P)
80107fb5:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107fb8:	8b 00                	mov    (%eax),%eax
80107fba:	83 e0 01             	and    $0x1,%eax
80107fbd:	84 c0                	test   %al,%al
80107fbf:	74 0c                	je     80107fcd <mappages+0x64>
      panic("remap");
80107fc1:	c7 04 24 a8 8e 10 80 	movl   $0x80108ea8,(%esp)
80107fc8:	e8 70 85 ff ff       	call   8010053d <panic>
    *pte = pa | perm | PTE_P;
80107fcd:	8b 45 18             	mov    0x18(%ebp),%eax
80107fd0:	0b 45 14             	or     0x14(%ebp),%eax
80107fd3:	89 c2                	mov    %eax,%edx
80107fd5:	83 ca 01             	or     $0x1,%edx
80107fd8:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107fdb:	89 10                	mov    %edx,(%eax)
    if(a == last)
80107fdd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fe0:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80107fe3:	74 10                	je     80107ff5 <mappages+0x8c>
      break;
    a += PGSIZE;
80107fe5:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
80107fec:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
80107ff3:	eb 96                	jmp    80107f8b <mappages+0x22>
      return -1;
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
80107ff5:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
80107ff6:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107ffb:	c9                   	leave  
80107ffc:	c3                   	ret    

80107ffd <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm()
{
80107ffd:	55                   	push   %ebp
80107ffe:	89 e5                	mov    %esp,%ebp
80108000:	53                   	push   %ebx
80108001:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
80108004:	e8 02 ab ff ff       	call   80102b0b <kalloc>
80108009:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010800c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108010:	75 0a                	jne    8010801c <setupkvm+0x1f>
    return 0;
80108012:	b8 00 00 00 00       	mov    $0x0,%eax
80108017:	e9 98 00 00 00       	jmp    801080b4 <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
8010801c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108023:	00 
80108024:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010802b:	00 
8010802c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010802f:	89 04 24             	mov    %eax,(%esp)
80108032:	e8 07 d3 ff ff       	call   8010533e <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
80108037:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
8010803e:	e8 0d fa ff ff       	call   80107a50 <p2v>
80108043:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
80108048:	76 0c                	jbe    80108056 <setupkvm+0x59>
    panic("PHYSTOP too high");
8010804a:	c7 04 24 ae 8e 10 80 	movl   $0x80108eae,(%esp)
80108051:	e8 e7 84 ff ff       	call   8010053d <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80108056:	c7 45 f4 a0 b4 10 80 	movl   $0x8010b4a0,-0xc(%ebp)
8010805d:	eb 49                	jmp    801080a8 <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
8010805f:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80108062:	8b 48 0c             	mov    0xc(%eax),%ecx
                (uint)k->phys_start, k->perm) < 0)
80108065:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80108068:	8b 50 04             	mov    0x4(%eax),%edx
8010806b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010806e:	8b 58 08             	mov    0x8(%eax),%ebx
80108071:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108074:	8b 40 04             	mov    0x4(%eax),%eax
80108077:	29 c3                	sub    %eax,%ebx
80108079:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010807c:	8b 00                	mov    (%eax),%eax
8010807e:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80108082:	89 54 24 0c          	mov    %edx,0xc(%esp)
80108086:	89 5c 24 08          	mov    %ebx,0x8(%esp)
8010808a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010808e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108091:	89 04 24             	mov    %eax,(%esp)
80108094:	e8 d0 fe ff ff       	call   80107f69 <mappages>
80108099:	85 c0                	test   %eax,%eax
8010809b:	79 07                	jns    801080a4 <setupkvm+0xa7>
                (uint)k->phys_start, k->perm) < 0)
      return 0;
8010809d:	b8 00 00 00 00       	mov    $0x0,%eax
801080a2:	eb 10                	jmp    801080b4 <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
801080a4:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
801080a8:	81 7d f4 e0 b4 10 80 	cmpl   $0x8010b4e0,-0xc(%ebp)
801080af:	72 ae                	jb     8010805f <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
      return 0;
  return pgdir;
801080b1:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
801080b4:	83 c4 34             	add    $0x34,%esp
801080b7:	5b                   	pop    %ebx
801080b8:	5d                   	pop    %ebp
801080b9:	c3                   	ret    

801080ba <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
void
kvmalloc(void)
{
801080ba:	55                   	push   %ebp
801080bb:	89 e5                	mov    %esp,%ebp
801080bd:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
801080c0:	e8 38 ff ff ff       	call   80107ffd <setupkvm>
801080c5:	a3 f8 2a 11 80       	mov    %eax,0x80112af8
  switchkvm();
801080ca:	e8 02 00 00 00       	call   801080d1 <switchkvm>
}
801080cf:	c9                   	leave  
801080d0:	c3                   	ret    

801080d1 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
801080d1:	55                   	push   %ebp
801080d2:	89 e5                	mov    %esp,%ebp
801080d4:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
801080d7:	a1 f8 2a 11 80       	mov    0x80112af8,%eax
801080dc:	89 04 24             	mov    %eax,(%esp)
801080df:	e8 5f f9 ff ff       	call   80107a43 <v2p>
801080e4:	89 04 24             	mov    %eax,(%esp)
801080e7:	e8 4c f9 ff ff       	call   80107a38 <lcr3>
}
801080ec:	c9                   	leave  
801080ed:	c3                   	ret    

801080ee <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
801080ee:	55                   	push   %ebp
801080ef:	89 e5                	mov    %esp,%ebp
801080f1:	53                   	push   %ebx
801080f2:	83 ec 14             	sub    $0x14,%esp
  pushcli();
801080f5:	e8 3e d1 ff ff       	call   80105238 <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
801080fa:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108100:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108107:	83 c2 08             	add    $0x8,%edx
8010810a:	89 d3                	mov    %edx,%ebx
8010810c:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108113:	83 c2 08             	add    $0x8,%edx
80108116:	c1 ea 10             	shr    $0x10,%edx
80108119:	89 d1                	mov    %edx,%ecx
8010811b:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108122:	83 c2 08             	add    $0x8,%edx
80108125:	c1 ea 18             	shr    $0x18,%edx
80108128:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
8010812f:	67 00 
80108131:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
80108138:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
8010813e:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108145:	83 e1 f0             	and    $0xfffffff0,%ecx
80108148:	83 c9 09             	or     $0x9,%ecx
8010814b:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108151:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108158:	83 c9 10             	or     $0x10,%ecx
8010815b:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108161:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108168:	83 e1 9f             	and    $0xffffff9f,%ecx
8010816b:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108171:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108178:	83 c9 80             	or     $0xffffff80,%ecx
8010817b:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108181:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108188:	83 e1 f0             	and    $0xfffffff0,%ecx
8010818b:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108191:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108198:	83 e1 ef             	and    $0xffffffef,%ecx
8010819b:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
801081a1:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
801081a8:	83 e1 df             	and    $0xffffffdf,%ecx
801081ab:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
801081b1:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
801081b8:	83 c9 40             	or     $0x40,%ecx
801081bb:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
801081c1:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
801081c8:	83 e1 7f             	and    $0x7f,%ecx
801081cb:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
801081d1:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
801081d7:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801081dd:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
801081e4:	83 e2 ef             	and    $0xffffffef,%edx
801081e7:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
801081ed:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801081f3:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
801081f9:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801081ff:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80108206:	8b 52 08             	mov    0x8(%edx),%edx
80108209:	81 c2 00 10 00 00    	add    $0x1000,%edx
8010820f:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
80108212:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
80108219:	e8 ef f7 ff ff       	call   80107a0d <ltr>
  if(p->pgdir == 0)
8010821e:	8b 45 08             	mov    0x8(%ebp),%eax
80108221:	8b 40 04             	mov    0x4(%eax),%eax
80108224:	85 c0                	test   %eax,%eax
80108226:	75 0c                	jne    80108234 <switchuvm+0x146>
    panic("switchuvm: no pgdir");
80108228:	c7 04 24 bf 8e 10 80 	movl   $0x80108ebf,(%esp)
8010822f:	e8 09 83 ff ff       	call   8010053d <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
80108234:	8b 45 08             	mov    0x8(%ebp),%eax
80108237:	8b 40 04             	mov    0x4(%eax),%eax
8010823a:	89 04 24             	mov    %eax,(%esp)
8010823d:	e8 01 f8 ff ff       	call   80107a43 <v2p>
80108242:	89 04 24             	mov    %eax,(%esp)
80108245:	e8 ee f7 ff ff       	call   80107a38 <lcr3>
  popcli();
8010824a:	e8 31 d0 ff ff       	call   80105280 <popcli>
}
8010824f:	83 c4 14             	add    $0x14,%esp
80108252:	5b                   	pop    %ebx
80108253:	5d                   	pop    %ebp
80108254:	c3                   	ret    

80108255 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80108255:	55                   	push   %ebp
80108256:	89 e5                	mov    %esp,%ebp
80108258:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
8010825b:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
80108262:	76 0c                	jbe    80108270 <inituvm+0x1b>
    panic("inituvm: more than a page");
80108264:	c7 04 24 d3 8e 10 80 	movl   $0x80108ed3,(%esp)
8010826b:	e8 cd 82 ff ff       	call   8010053d <panic>
  mem = kalloc();
80108270:	e8 96 a8 ff ff       	call   80102b0b <kalloc>
80108275:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
80108278:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010827f:	00 
80108280:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108287:	00 
80108288:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010828b:	89 04 24             	mov    %eax,(%esp)
8010828e:	e8 ab d0 ff ff       	call   8010533e <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
80108293:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108296:	89 04 24             	mov    %eax,(%esp)
80108299:	e8 a5 f7 ff ff       	call   80107a43 <v2p>
8010829e:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
801082a5:	00 
801082a6:	89 44 24 0c          	mov    %eax,0xc(%esp)
801082aa:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801082b1:	00 
801082b2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801082b9:	00 
801082ba:	8b 45 08             	mov    0x8(%ebp),%eax
801082bd:	89 04 24             	mov    %eax,(%esp)
801082c0:	e8 a4 fc ff ff       	call   80107f69 <mappages>
  memmove(mem, init, sz);
801082c5:	8b 45 10             	mov    0x10(%ebp),%eax
801082c8:	89 44 24 08          	mov    %eax,0x8(%esp)
801082cc:	8b 45 0c             	mov    0xc(%ebp),%eax
801082cf:	89 44 24 04          	mov    %eax,0x4(%esp)
801082d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082d6:	89 04 24             	mov    %eax,(%esp)
801082d9:	e8 33 d1 ff ff       	call   80105411 <memmove>
}
801082de:	c9                   	leave  
801082df:	c3                   	ret    

801082e0 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
801082e0:	55                   	push   %ebp
801082e1:	89 e5                	mov    %esp,%ebp
801082e3:	53                   	push   %ebx
801082e4:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
801082e7:	8b 45 0c             	mov    0xc(%ebp),%eax
801082ea:	25 ff 0f 00 00       	and    $0xfff,%eax
801082ef:	85 c0                	test   %eax,%eax
801082f1:	74 0c                	je     801082ff <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
801082f3:	c7 04 24 f0 8e 10 80 	movl   $0x80108ef0,(%esp)
801082fa:	e8 3e 82 ff ff       	call   8010053d <panic>
  for(i = 0; i < sz; i += PGSIZE){
801082ff:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108306:	e9 ad 00 00 00       	jmp    801083b8 <loaduvm+0xd8>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
8010830b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010830e:	8b 55 0c             	mov    0xc(%ebp),%edx
80108311:	01 d0                	add    %edx,%eax
80108313:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010831a:	00 
8010831b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010831f:	8b 45 08             	mov    0x8(%ebp),%eax
80108322:	89 04 24             	mov    %eax,(%esp)
80108325:	e8 a9 fb ff ff       	call   80107ed3 <walkpgdir>
8010832a:	89 45 ec             	mov    %eax,-0x14(%ebp)
8010832d:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108331:	75 0c                	jne    8010833f <loaduvm+0x5f>
      panic("loaduvm: address should exist");
80108333:	c7 04 24 13 8f 10 80 	movl   $0x80108f13,(%esp)
8010833a:	e8 fe 81 ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
8010833f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108342:	8b 00                	mov    (%eax),%eax
80108344:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108349:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
8010834c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010834f:	8b 55 18             	mov    0x18(%ebp),%edx
80108352:	89 d1                	mov    %edx,%ecx
80108354:	29 c1                	sub    %eax,%ecx
80108356:	89 c8                	mov    %ecx,%eax
80108358:	3d ff 0f 00 00       	cmp    $0xfff,%eax
8010835d:	77 11                	ja     80108370 <loaduvm+0x90>
      n = sz - i;
8010835f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108362:	8b 55 18             	mov    0x18(%ebp),%edx
80108365:	89 d1                	mov    %edx,%ecx
80108367:	29 c1                	sub    %eax,%ecx
80108369:	89 c8                	mov    %ecx,%eax
8010836b:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010836e:	eb 07                	jmp    80108377 <loaduvm+0x97>
    else
      n = PGSIZE;
80108370:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
80108377:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010837a:	8b 55 14             	mov    0x14(%ebp),%edx
8010837d:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80108380:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108383:	89 04 24             	mov    %eax,(%esp)
80108386:	e8 c5 f6 ff ff       	call   80107a50 <p2v>
8010838b:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010838e:	89 54 24 0c          	mov    %edx,0xc(%esp)
80108392:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80108396:	89 44 24 04          	mov    %eax,0x4(%esp)
8010839a:	8b 45 10             	mov    0x10(%ebp),%eax
8010839d:	89 04 24             	mov    %eax,(%esp)
801083a0:	e8 b9 99 ff ff       	call   80101d5e <readi>
801083a5:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801083a8:	74 07                	je     801083b1 <loaduvm+0xd1>
      return -1;
801083aa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801083af:	eb 18                	jmp    801083c9 <loaduvm+0xe9>
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
801083b1:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801083b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083bb:	3b 45 18             	cmp    0x18(%ebp),%eax
801083be:	0f 82 47 ff ff ff    	jb     8010830b <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
801083c4:	b8 00 00 00 00       	mov    $0x0,%eax
}
801083c9:	83 c4 24             	add    $0x24,%esp
801083cc:	5b                   	pop    %ebx
801083cd:	5d                   	pop    %ebp
801083ce:	c3                   	ret    

801083cf <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
801083cf:	55                   	push   %ebp
801083d0:	89 e5                	mov    %esp,%ebp
801083d2:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  uint a;

  if(newsz >= KERNBASE)
801083d5:	8b 45 10             	mov    0x10(%ebp),%eax
801083d8:	85 c0                	test   %eax,%eax
801083da:	79 0a                	jns    801083e6 <allocuvm+0x17>
    return 0;
801083dc:	b8 00 00 00 00       	mov    $0x0,%eax
801083e1:	e9 c1 00 00 00       	jmp    801084a7 <allocuvm+0xd8>
  if(newsz < oldsz)
801083e6:	8b 45 10             	mov    0x10(%ebp),%eax
801083e9:	3b 45 0c             	cmp    0xc(%ebp),%eax
801083ec:	73 08                	jae    801083f6 <allocuvm+0x27>
    return oldsz;
801083ee:	8b 45 0c             	mov    0xc(%ebp),%eax
801083f1:	e9 b1 00 00 00       	jmp    801084a7 <allocuvm+0xd8>
  a = PGROUNDUP(oldsz);
801083f6:	8b 45 0c             	mov    0xc(%ebp),%eax
801083f9:	05 ff 0f 00 00       	add    $0xfff,%eax
801083fe:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108403:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
80108406:	e9 8d 00 00 00       	jmp    80108498 <allocuvm+0xc9>
    mem = kalloc();
8010840b:	e8 fb a6 ff ff       	call   80102b0b <kalloc>
80108410:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(mem == 0){
80108413:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108417:	75 2c                	jne    80108445 <allocuvm+0x76>
      cprintf("allocuvm out of memory\n");
80108419:	c7 04 24 31 8f 10 80 	movl   $0x80108f31,(%esp)
80108420:	e8 7c 7f ff ff       	call   801003a1 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80108425:	8b 45 0c             	mov    0xc(%ebp),%eax
80108428:	89 44 24 08          	mov    %eax,0x8(%esp)
8010842c:	8b 45 10             	mov    0x10(%ebp),%eax
8010842f:	89 44 24 04          	mov    %eax,0x4(%esp)
80108433:	8b 45 08             	mov    0x8(%ebp),%eax
80108436:	89 04 24             	mov    %eax,(%esp)
80108439:	e8 6b 00 00 00       	call   801084a9 <deallocuvm>
      return 0;
8010843e:	b8 00 00 00 00       	mov    $0x0,%eax
80108443:	eb 62                	jmp    801084a7 <allocuvm+0xd8>
    }
    memset(mem, 0, PGSIZE);
80108445:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010844c:	00 
8010844d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108454:	00 
80108455:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108458:	89 04 24             	mov    %eax,(%esp)
8010845b:	e8 de ce ff ff       	call   8010533e <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
80108460:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108463:	89 04 24             	mov    %eax,(%esp)
80108466:	e8 d8 f5 ff ff       	call   80107a43 <v2p>
8010846b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010846e:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80108475:	00 
80108476:	89 44 24 0c          	mov    %eax,0xc(%esp)
8010847a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108481:	00 
80108482:	89 54 24 04          	mov    %edx,0x4(%esp)
80108486:	8b 45 08             	mov    0x8(%ebp),%eax
80108489:	89 04 24             	mov    %eax,(%esp)
8010848c:	e8 d8 fa ff ff       	call   80107f69 <mappages>
  if(newsz >= KERNBASE)
    return 0;
  if(newsz < oldsz)
    return oldsz;
  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
80108491:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108498:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010849b:	3b 45 10             	cmp    0x10(%ebp),%eax
8010849e:	0f 82 67 ff ff ff    	jb     8010840b <allocuvm+0x3c>
      return 0;
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
  }
  return newsz;
801084a4:	8b 45 10             	mov    0x10(%ebp),%eax
}
801084a7:	c9                   	leave  
801084a8:	c3                   	ret    

801084a9 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
801084a9:	55                   	push   %ebp
801084aa:	89 e5                	mov    %esp,%ebp
801084ac:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
801084af:	8b 45 10             	mov    0x10(%ebp),%eax
801084b2:	3b 45 0c             	cmp    0xc(%ebp),%eax
801084b5:	72 08                	jb     801084bf <deallocuvm+0x16>
    return oldsz;
801084b7:	8b 45 0c             	mov    0xc(%ebp),%eax
801084ba:	e9 a4 00 00 00       	jmp    80108563 <deallocuvm+0xba>

  a = PGROUNDUP(newsz);
801084bf:	8b 45 10             	mov    0x10(%ebp),%eax
801084c2:	05 ff 0f 00 00       	add    $0xfff,%eax
801084c7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801084cc:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
801084cf:	e9 80 00 00 00       	jmp    80108554 <deallocuvm+0xab>
    pte = walkpgdir(pgdir, (char*)a, 0);
801084d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084d7:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801084de:	00 
801084df:	89 44 24 04          	mov    %eax,0x4(%esp)
801084e3:	8b 45 08             	mov    0x8(%ebp),%eax
801084e6:	89 04 24             	mov    %eax,(%esp)
801084e9:	e8 e5 f9 ff ff       	call   80107ed3 <walkpgdir>
801084ee:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(!pte)
801084f1:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801084f5:	75 09                	jne    80108500 <deallocuvm+0x57>
      a += (NPTENTRIES - 1) * PGSIZE;
801084f7:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
801084fe:	eb 4d                	jmp    8010854d <deallocuvm+0xa4>
    else if((*pte & PTE_P) != 0){
80108500:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108503:	8b 00                	mov    (%eax),%eax
80108505:	83 e0 01             	and    $0x1,%eax
80108508:	84 c0                	test   %al,%al
8010850a:	74 41                	je     8010854d <deallocuvm+0xa4>
      pa = PTE_ADDR(*pte);
8010850c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010850f:	8b 00                	mov    (%eax),%eax
80108511:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108516:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if(pa == 0)
80108519:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
8010851d:	75 0c                	jne    8010852b <deallocuvm+0x82>
        panic("kfree");
8010851f:	c7 04 24 49 8f 10 80 	movl   $0x80108f49,(%esp)
80108526:	e8 12 80 ff ff       	call   8010053d <panic>
      char *v = p2v(pa);
8010852b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010852e:	89 04 24             	mov    %eax,(%esp)
80108531:	e8 1a f5 ff ff       	call   80107a50 <p2v>
80108536:	89 45 e8             	mov    %eax,-0x18(%ebp)
      kfree(v);
80108539:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010853c:	89 04 24             	mov    %eax,(%esp)
8010853f:	e8 2e a5 ff ff       	call   80102a72 <kfree>
      *pte = 0;
80108544:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108547:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
8010854d:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108554:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108557:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010855a:	0f 82 74 ff ff ff    	jb     801084d4 <deallocuvm+0x2b>
      char *v = p2v(pa);
      kfree(v);
      *pte = 0;
    }
  }
  return newsz;
80108560:	8b 45 10             	mov    0x10(%ebp),%eax
}
80108563:	c9                   	leave  
80108564:	c3                   	ret    

80108565 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
80108565:	55                   	push   %ebp
80108566:	89 e5                	mov    %esp,%ebp
80108568:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
8010856b:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010856f:	75 0c                	jne    8010857d <freevm+0x18>
    panic("freevm: no pgdir");
80108571:	c7 04 24 4f 8f 10 80 	movl   $0x80108f4f,(%esp)
80108578:	e8 c0 7f ff ff       	call   8010053d <panic>
  deallocuvm(pgdir, KERNBASE, 0);
8010857d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108584:	00 
80108585:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
8010858c:	80 
8010858d:	8b 45 08             	mov    0x8(%ebp),%eax
80108590:	89 04 24             	mov    %eax,(%esp)
80108593:	e8 11 ff ff ff       	call   801084a9 <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
80108598:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010859f:	eb 3c                	jmp    801085dd <freevm+0x78>
    if(pgdir[i] & PTE_P){
801085a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085a4:	c1 e0 02             	shl    $0x2,%eax
801085a7:	03 45 08             	add    0x8(%ebp),%eax
801085aa:	8b 00                	mov    (%eax),%eax
801085ac:	83 e0 01             	and    $0x1,%eax
801085af:	84 c0                	test   %al,%al
801085b1:	74 26                	je     801085d9 <freevm+0x74>
      char * v = p2v(PTE_ADDR(pgdir[i]));
801085b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085b6:	c1 e0 02             	shl    $0x2,%eax
801085b9:	03 45 08             	add    0x8(%ebp),%eax
801085bc:	8b 00                	mov    (%eax),%eax
801085be:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801085c3:	89 04 24             	mov    %eax,(%esp)
801085c6:	e8 85 f4 ff ff       	call   80107a50 <p2v>
801085cb:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
801085ce:	8b 45 f0             	mov    -0x10(%ebp),%eax
801085d1:	89 04 24             	mov    %eax,(%esp)
801085d4:	e8 99 a4 ff ff       	call   80102a72 <kfree>
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
  for(i = 0; i < NPDENTRIES; i++){
801085d9:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801085dd:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
801085e4:	76 bb                	jbe    801085a1 <freevm+0x3c>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
801085e6:	8b 45 08             	mov    0x8(%ebp),%eax
801085e9:	89 04 24             	mov    %eax,(%esp)
801085ec:	e8 81 a4 ff ff       	call   80102a72 <kfree>
}
801085f1:	c9                   	leave  
801085f2:	c3                   	ret    

801085f3 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
801085f3:	55                   	push   %ebp
801085f4:	89 e5                	mov    %esp,%ebp
801085f6:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801085f9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108600:	00 
80108601:	8b 45 0c             	mov    0xc(%ebp),%eax
80108604:	89 44 24 04          	mov    %eax,0x4(%esp)
80108608:	8b 45 08             	mov    0x8(%ebp),%eax
8010860b:	89 04 24             	mov    %eax,(%esp)
8010860e:	e8 c0 f8 ff ff       	call   80107ed3 <walkpgdir>
80108613:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
80108616:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010861a:	75 0c                	jne    80108628 <clearpteu+0x35>
    panic("clearpteu");
8010861c:	c7 04 24 60 8f 10 80 	movl   $0x80108f60,(%esp)
80108623:	e8 15 7f ff ff       	call   8010053d <panic>
  *pte &= ~PTE_U;
80108628:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010862b:	8b 00                	mov    (%eax),%eax
8010862d:	89 c2                	mov    %eax,%edx
8010862f:	83 e2 fb             	and    $0xfffffffb,%edx
80108632:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108635:	89 10                	mov    %edx,(%eax)
}
80108637:	c9                   	leave  
80108638:	c3                   	ret    

80108639 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
80108639:	55                   	push   %ebp
8010863a:	89 e5                	mov    %esp,%ebp
8010863c:	83 ec 48             	sub    $0x48,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
8010863f:	e8 b9 f9 ff ff       	call   80107ffd <setupkvm>
80108644:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108647:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010864b:	75 0a                	jne    80108657 <copyuvm+0x1e>
    return 0;
8010864d:	b8 00 00 00 00       	mov    $0x0,%eax
80108652:	e9 f1 00 00 00       	jmp    80108748 <copyuvm+0x10f>
  for(i = 0; i < sz; i += PGSIZE){
80108657:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010865e:	e9 c0 00 00 00       	jmp    80108723 <copyuvm+0xea>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
80108663:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108666:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010866d:	00 
8010866e:	89 44 24 04          	mov    %eax,0x4(%esp)
80108672:	8b 45 08             	mov    0x8(%ebp),%eax
80108675:	89 04 24             	mov    %eax,(%esp)
80108678:	e8 56 f8 ff ff       	call   80107ed3 <walkpgdir>
8010867d:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108680:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108684:	75 0c                	jne    80108692 <copyuvm+0x59>
      panic("copyuvm: pte should exist");
80108686:	c7 04 24 6a 8f 10 80 	movl   $0x80108f6a,(%esp)
8010868d:	e8 ab 7e ff ff       	call   8010053d <panic>
    if(!(*pte & PTE_P))
80108692:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108695:	8b 00                	mov    (%eax),%eax
80108697:	83 e0 01             	and    $0x1,%eax
8010869a:	85 c0                	test   %eax,%eax
8010869c:	75 0c                	jne    801086aa <copyuvm+0x71>
      panic("copyuvm: page not present");
8010869e:	c7 04 24 84 8f 10 80 	movl   $0x80108f84,(%esp)
801086a5:	e8 93 7e ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
801086aa:	8b 45 ec             	mov    -0x14(%ebp),%eax
801086ad:	8b 00                	mov    (%eax),%eax
801086af:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801086b4:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if((mem = kalloc()) == 0)
801086b7:	e8 4f a4 ff ff       	call   80102b0b <kalloc>
801086bc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801086bf:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
801086c3:	74 6f                	je     80108734 <copyuvm+0xfb>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
801086c5:	8b 45 e8             	mov    -0x18(%ebp),%eax
801086c8:	89 04 24             	mov    %eax,(%esp)
801086cb:	e8 80 f3 ff ff       	call   80107a50 <p2v>
801086d0:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801086d7:	00 
801086d8:	89 44 24 04          	mov    %eax,0x4(%esp)
801086dc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801086df:	89 04 24             	mov    %eax,(%esp)
801086e2:	e8 2a cd ff ff       	call   80105411 <memmove>
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
801086e7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801086ea:	89 04 24             	mov    %eax,(%esp)
801086ed:	e8 51 f3 ff ff       	call   80107a43 <v2p>
801086f2:	8b 55 f4             	mov    -0xc(%ebp),%edx
801086f5:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
801086fc:	00 
801086fd:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108701:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108708:	00 
80108709:	89 54 24 04          	mov    %edx,0x4(%esp)
8010870d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108710:	89 04 24             	mov    %eax,(%esp)
80108713:	e8 51 f8 ff ff       	call   80107f69 <mappages>
80108718:	85 c0                	test   %eax,%eax
8010871a:	78 1b                	js     80108737 <copyuvm+0xfe>
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
8010871c:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108723:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108726:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108729:	0f 82 34 ff ff ff    	jb     80108663 <copyuvm+0x2a>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
  }
  return d;
8010872f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108732:	eb 14                	jmp    80108748 <copyuvm+0x10f>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
    if((mem = kalloc()) == 0)
      goto bad;
80108734:	90                   	nop
80108735:	eb 01                	jmp    80108738 <copyuvm+0xff>
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
80108737:	90                   	nop
  }
  return d;

bad:
  freevm(d);
80108738:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010873b:	89 04 24             	mov    %eax,(%esp)
8010873e:	e8 22 fe ff ff       	call   80108565 <freevm>
  return 0;
80108743:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108748:	c9                   	leave  
80108749:	c3                   	ret    

8010874a <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
8010874a:	55                   	push   %ebp
8010874b:	89 e5                	mov    %esp,%ebp
8010874d:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80108750:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108757:	00 
80108758:	8b 45 0c             	mov    0xc(%ebp),%eax
8010875b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010875f:	8b 45 08             	mov    0x8(%ebp),%eax
80108762:	89 04 24             	mov    %eax,(%esp)
80108765:	e8 69 f7 ff ff       	call   80107ed3 <walkpgdir>
8010876a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
8010876d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108770:	8b 00                	mov    (%eax),%eax
80108772:	83 e0 01             	and    $0x1,%eax
80108775:	85 c0                	test   %eax,%eax
80108777:	75 07                	jne    80108780 <uva2ka+0x36>
    return 0;
80108779:	b8 00 00 00 00       	mov    $0x0,%eax
8010877e:	eb 25                	jmp    801087a5 <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
80108780:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108783:	8b 00                	mov    (%eax),%eax
80108785:	83 e0 04             	and    $0x4,%eax
80108788:	85 c0                	test   %eax,%eax
8010878a:	75 07                	jne    80108793 <uva2ka+0x49>
    return 0;
8010878c:	b8 00 00 00 00       	mov    $0x0,%eax
80108791:	eb 12                	jmp    801087a5 <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
80108793:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108796:	8b 00                	mov    (%eax),%eax
80108798:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010879d:	89 04 24             	mov    %eax,(%esp)
801087a0:	e8 ab f2 ff ff       	call   80107a50 <p2v>
}
801087a5:	c9                   	leave  
801087a6:	c3                   	ret    

801087a7 <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
801087a7:	55                   	push   %ebp
801087a8:	89 e5                	mov    %esp,%ebp
801087aa:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
801087ad:	8b 45 10             	mov    0x10(%ebp),%eax
801087b0:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
801087b3:	e9 8b 00 00 00       	jmp    80108843 <copyout+0x9c>
    va0 = (uint)PGROUNDDOWN(va);
801087b8:	8b 45 0c             	mov    0xc(%ebp),%eax
801087bb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801087c0:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
801087c3:	8b 45 ec             	mov    -0x14(%ebp),%eax
801087c6:	89 44 24 04          	mov    %eax,0x4(%esp)
801087ca:	8b 45 08             	mov    0x8(%ebp),%eax
801087cd:	89 04 24             	mov    %eax,(%esp)
801087d0:	e8 75 ff ff ff       	call   8010874a <uva2ka>
801087d5:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
801087d8:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801087dc:	75 07                	jne    801087e5 <copyout+0x3e>
      return -1;
801087de:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801087e3:	eb 6d                	jmp    80108852 <copyout+0xab>
    n = PGSIZE - (va - va0);
801087e5:	8b 45 0c             	mov    0xc(%ebp),%eax
801087e8:	8b 55 ec             	mov    -0x14(%ebp),%edx
801087eb:	89 d1                	mov    %edx,%ecx
801087ed:	29 c1                	sub    %eax,%ecx
801087ef:	89 c8                	mov    %ecx,%eax
801087f1:	05 00 10 00 00       	add    $0x1000,%eax
801087f6:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
801087f9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801087fc:	3b 45 14             	cmp    0x14(%ebp),%eax
801087ff:	76 06                	jbe    80108807 <copyout+0x60>
      n = len;
80108801:	8b 45 14             	mov    0x14(%ebp),%eax
80108804:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
80108807:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010880a:	8b 55 0c             	mov    0xc(%ebp),%edx
8010880d:	89 d1                	mov    %edx,%ecx
8010880f:	29 c1                	sub    %eax,%ecx
80108811:	89 c8                	mov    %ecx,%eax
80108813:	03 45 e8             	add    -0x18(%ebp),%eax
80108816:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108819:	89 54 24 08          	mov    %edx,0x8(%esp)
8010881d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108820:	89 54 24 04          	mov    %edx,0x4(%esp)
80108824:	89 04 24             	mov    %eax,(%esp)
80108827:	e8 e5 cb ff ff       	call   80105411 <memmove>
    len -= n;
8010882c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010882f:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
80108832:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108835:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
80108838:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010883b:	05 00 10 00 00       	add    $0x1000,%eax
80108840:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
80108843:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
80108847:	0f 85 6b ff ff ff    	jne    801087b8 <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
8010884d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108852:	c9                   	leave  
80108853:	c3                   	ret    
