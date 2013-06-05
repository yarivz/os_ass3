
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
80100015:	b8 00 b0 10 00       	mov    $0x10b000,%eax
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
80100028:	bc 80 d6 10 80       	mov    $0x8010d680,%esp

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $main, %eax
8010002d:	b8 53 36 10 80       	mov    $0x80103653,%eax
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
8010003a:	c7 44 24 04 b8 8f 10 	movl   $0x80108fb8,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
80100049:	e8 9c 54 00 00       	call   801054ea <initlock>

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
8010004e:	c7 05 b0 eb 10 80 a4 	movl   $0x8010eba4,0x8010ebb0
80100055:	eb 10 80 
  bcache.head.next = &bcache.head;
80100058:	c7 05 b4 eb 10 80 a4 	movl   $0x8010eba4,0x8010ebb4
8010005f:	eb 10 80 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
80100062:	c7 45 f4 b4 d6 10 80 	movl   $0x8010d6b4,-0xc(%ebp)
80100069:	eb 3a                	jmp    801000a5 <binit+0x71>
    b->next = bcache.head.next;
8010006b:	8b 15 b4 eb 10 80    	mov    0x8010ebb4,%edx
80100071:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100074:	89 50 10             	mov    %edx,0x10(%eax)
    b->prev = &bcache.head;
80100077:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010007a:	c7 40 0c a4 eb 10 80 	movl   $0x8010eba4,0xc(%eax)
    b->dev = -1;
80100081:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100084:	c7 40 04 ff ff ff ff 	movl   $0xffffffff,0x4(%eax)
    bcache.head.next->prev = b;
8010008b:	a1 b4 eb 10 80       	mov    0x8010ebb4,%eax
80100090:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100093:	89 50 0c             	mov    %edx,0xc(%eax)
    bcache.head.next = b;
80100096:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100099:	a3 b4 eb 10 80       	mov    %eax,0x8010ebb4

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
  bcache.head.next = &bcache.head;
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
8010009e:	81 45 f4 18 02 00 00 	addl   $0x218,-0xc(%ebp)
801000a5:	81 7d f4 a4 eb 10 80 	cmpl   $0x8010eba4,-0xc(%ebp)
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
801000b6:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
801000bd:	e8 49 54 00 00       	call   8010550b <acquire>

 loop:
  // Is the sector already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
801000c2:	a1 b4 eb 10 80       	mov    0x8010ebb4,%eax
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
801000fd:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
80100104:	e8 9d 54 00 00       	call   801055a6 <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 80 d6 10 	movl   $0x8010d680,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 ab 4f 00 00       	call   801050cf <sleep>
      goto loop;
80100124:	eb 9c                	jmp    801000c2 <bget+0x12>

  acquire(&bcache.lock);

 loop:
  // Is the sector already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
80100126:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100129:	8b 40 10             	mov    0x10(%eax),%eax
8010012c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010012f:	81 7d f4 a4 eb 10 80 	cmpl   $0x8010eba4,-0xc(%ebp)
80100136:	75 94                	jne    801000cc <bget+0x1c>
      goto loop;
    }
  }

  // Not cached; recycle some non-busy and clean buffer.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100138:	a1 b0 eb 10 80       	mov    0x8010ebb0,%eax
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
80100175:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
8010017c:	e8 25 54 00 00       	call   801055a6 <release>
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
8010018f:	81 7d f4 a4 eb 10 80 	cmpl   $0x8010eba4,-0xc(%ebp)
80100196:	75 aa                	jne    80100142 <bget+0x92>
      b->flags = B_BUSY;
      release(&bcache.lock);
      return b;
    }
  }
  panic("bget: no buffers");
80100198:	c7 04 24 bf 8f 10 80 	movl   $0x80108fbf,(%esp)
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
801001d3:	e8 d7 25 00 00       	call   801027af <iderw>
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
801001ef:	c7 04 24 d0 8f 10 80 	movl   $0x80108fd0,(%esp)
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
80100210:	e8 9a 25 00 00       	call   801027af <iderw>
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
80100229:	c7 04 24 d7 8f 10 80 	movl   $0x80108fd7,(%esp)
80100230:	e8 08 03 00 00       	call   8010053d <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
8010023c:	e8 ca 52 00 00       	call   8010550b <acquire>

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
8010025f:	8b 15 b4 eb 10 80    	mov    0x8010ebb4,%edx
80100265:	8b 45 08             	mov    0x8(%ebp),%eax
80100268:	89 50 10             	mov    %edx,0x10(%eax)
  b->prev = &bcache.head;
8010026b:	8b 45 08             	mov    0x8(%ebp),%eax
8010026e:	c7 40 0c a4 eb 10 80 	movl   $0x8010eba4,0xc(%eax)
  bcache.head.next->prev = b;
80100275:	a1 b4 eb 10 80       	mov    0x8010ebb4,%eax
8010027a:	8b 55 08             	mov    0x8(%ebp),%edx
8010027d:	89 50 0c             	mov    %edx,0xc(%eax)
  bcache.head.next = b;
80100280:	8b 45 08             	mov    0x8(%ebp),%eax
80100283:	a3 b4 eb 10 80       	mov    %eax,0x8010ebb4

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
8010029d:	e8 69 4f 00 00       	call   8010520b <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
801002a9:	e8 f8 52 00 00       	call   801055a6 <release>
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
8010033f:	0f b6 90 04 a0 10 80 	movzbl -0x7fef5ffc(%eax),%edx
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
801003a7:	a1 14 c6 10 80       	mov    0x8010c614,%eax
801003ac:	89 45 e8             	mov    %eax,-0x18(%ebp)
  if(locking)
801003af:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801003b3:	74 0c                	je     801003c1 <cprintf+0x20>
    acquire(&cons.lock);
801003b5:	c7 04 24 e0 c5 10 80 	movl   $0x8010c5e0,(%esp)
801003bc:	e8 4a 51 00 00       	call   8010550b <acquire>

  if (fmt == 0)
801003c1:	8b 45 08             	mov    0x8(%ebp),%eax
801003c4:	85 c0                	test   %eax,%eax
801003c6:	75 0c                	jne    801003d4 <cprintf+0x33>
    panic("null fmt");
801003c8:	c7 04 24 de 8f 10 80 	movl   $0x80108fde,(%esp)
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
801004af:	c7 45 ec e7 8f 10 80 	movl   $0x80108fe7,-0x14(%ebp)
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
8010052f:	c7 04 24 e0 c5 10 80 	movl   $0x8010c5e0,(%esp)
80100536:	e8 6b 50 00 00       	call   801055a6 <release>
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
80100548:	c7 05 14 c6 10 80 00 	movl   $0x0,0x8010c614
8010054f:	00 00 00 
  cprintf("cpu%d: panic: ", cpu->id);
80100552:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80100558:	0f b6 00             	movzbl (%eax),%eax
8010055b:	0f b6 c0             	movzbl %al,%eax
8010055e:	89 44 24 04          	mov    %eax,0x4(%esp)
80100562:	c7 04 24 ee 8f 10 80 	movl   $0x80108fee,(%esp)
80100569:	e8 33 fe ff ff       	call   801003a1 <cprintf>
  cprintf(s);
8010056e:	8b 45 08             	mov    0x8(%ebp),%eax
80100571:	89 04 24             	mov    %eax,(%esp)
80100574:	e8 28 fe ff ff       	call   801003a1 <cprintf>
  cprintf("\n");
80100579:	c7 04 24 fd 8f 10 80 	movl   $0x80108ffd,(%esp)
80100580:	e8 1c fe ff ff       	call   801003a1 <cprintf>
  getcallerpcs(&s, pcs);
80100585:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100588:	89 44 24 04          	mov    %eax,0x4(%esp)
8010058c:	8d 45 08             	lea    0x8(%ebp),%eax
8010058f:	89 04 24             	mov    %eax,(%esp)
80100592:	e8 5e 50 00 00       	call   801055f5 <getcallerpcs>
  for(i=0; i<10; i++)
80100597:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010059e:	eb 1b                	jmp    801005bb <panic+0x7e>
    cprintf(" %p", pcs[i]);
801005a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005a3:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005a7:	89 44 24 04          	mov    %eax,0x4(%esp)
801005ab:	c7 04 24 ff 8f 10 80 	movl   $0x80108fff,(%esp)
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
801005c1:	c7 05 c0 c5 10 80 01 	movl   $0x1,0x8010c5c0
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
8010066d:	a1 00 a0 10 80       	mov    0x8010a000,%eax
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
80100693:	a1 00 a0 10 80       	mov    0x8010a000,%eax
80100698:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
8010069e:	a1 00 a0 10 80       	mov    0x8010a000,%eax
801006a3:	c7 44 24 08 60 0e 00 	movl   $0xe60,0x8(%esp)
801006aa:	00 
801006ab:	89 54 24 04          	mov    %edx,0x4(%esp)
801006af:	89 04 24             	mov    %eax,(%esp)
801006b2:	e8 ae 51 00 00       	call   80105865 <memmove>
    pos -= 80;
801006b7:	83 6d f4 50          	subl   $0x50,-0xc(%ebp)
    memset(crt+pos, 0, sizeof(crt[0])*(24*80 - pos));
801006bb:	b8 80 07 00 00       	mov    $0x780,%eax
801006c0:	2b 45 f4             	sub    -0xc(%ebp),%eax
801006c3:	01 c0                	add    %eax,%eax
801006c5:	8b 15 00 a0 10 80    	mov    0x8010a000,%edx
801006cb:	8b 4d f4             	mov    -0xc(%ebp),%ecx
801006ce:	01 c9                	add    %ecx,%ecx
801006d0:	01 ca                	add    %ecx,%edx
801006d2:	89 44 24 08          	mov    %eax,0x8(%esp)
801006d6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801006dd:	00 
801006de:	89 14 24             	mov    %edx,(%esp)
801006e1:	e8 ac 50 00 00       	call   80105792 <memset>
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
8010073d:	a1 00 a0 10 80       	mov    0x8010a000,%eax
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
80100756:	a1 c0 c5 10 80       	mov    0x8010c5c0,%eax
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
80100776:	e8 a2 6e 00 00       	call   8010761d <uartputc>
8010077b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80100782:	e8 96 6e 00 00       	call   8010761d <uartputc>
80100787:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
8010078e:	e8 8a 6e 00 00       	call   8010761d <uartputc>
80100793:	eb 0b                	jmp    801007a0 <consputc+0x50>
  } else
    uartputc(c);
80100795:	8b 45 08             	mov    0x8(%ebp),%eax
80100798:	89 04 24             	mov    %eax,(%esp)
8010079b:	e8 7d 6e 00 00       	call   8010761d <uartputc>
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
801007b3:	c7 04 24 c0 ed 10 80 	movl   $0x8010edc0,(%esp)
801007ba:	e8 4c 4d 00 00       	call   8010550b <acquire>
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
801007ea:	e8 e5 4a 00 00       	call   801052d4 <procdump>
      break;
801007ef:	e9 11 01 00 00       	jmp    80100905 <consoleintr+0x158>
    case C('U'):  // Kill line.
      while(input.e != input.w &&
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
801007f4:	a1 7c ee 10 80       	mov    0x8010ee7c,%eax
801007f9:	83 e8 01             	sub    $0x1,%eax
801007fc:	a3 7c ee 10 80       	mov    %eax,0x8010ee7c
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
80100810:	8b 15 7c ee 10 80    	mov    0x8010ee7c,%edx
80100816:	a1 78 ee 10 80       	mov    0x8010ee78,%eax
8010081b:	39 c2                	cmp    %eax,%edx
8010081d:	0f 84 db 00 00 00    	je     801008fe <consoleintr+0x151>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
80100823:	a1 7c ee 10 80       	mov    0x8010ee7c,%eax
80100828:	83 e8 01             	sub    $0x1,%eax
8010082b:	83 e0 7f             	and    $0x7f,%eax
8010082e:	0f b6 80 f4 ed 10 80 	movzbl -0x7fef120c(%eax),%eax
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
8010083e:	8b 15 7c ee 10 80    	mov    0x8010ee7c,%edx
80100844:	a1 78 ee 10 80       	mov    0x8010ee78,%eax
80100849:	39 c2                	cmp    %eax,%edx
8010084b:	0f 84 b0 00 00 00    	je     80100901 <consoleintr+0x154>
        input.e--;
80100851:	a1 7c ee 10 80       	mov    0x8010ee7c,%eax
80100856:	83 e8 01             	sub    $0x1,%eax
80100859:	a3 7c ee 10 80       	mov    %eax,0x8010ee7c
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
80100879:	8b 15 7c ee 10 80    	mov    0x8010ee7c,%edx
8010087f:	a1 74 ee 10 80       	mov    0x8010ee74,%eax
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
801008a2:	a1 7c ee 10 80       	mov    0x8010ee7c,%eax
801008a7:	89 c1                	mov    %eax,%ecx
801008a9:	83 e1 7f             	and    $0x7f,%ecx
801008ac:	8b 55 f4             	mov    -0xc(%ebp),%edx
801008af:	88 91 f4 ed 10 80    	mov    %dl,-0x7fef120c(%ecx)
801008b5:	83 c0 01             	add    $0x1,%eax
801008b8:	a3 7c ee 10 80       	mov    %eax,0x8010ee7c
        consputc(c);
801008bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801008c0:	89 04 24             	mov    %eax,(%esp)
801008c3:	e8 88 fe ff ff       	call   80100750 <consputc>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
801008c8:	83 7d f4 0a          	cmpl   $0xa,-0xc(%ebp)
801008cc:	74 18                	je     801008e6 <consoleintr+0x139>
801008ce:	83 7d f4 04          	cmpl   $0x4,-0xc(%ebp)
801008d2:	74 12                	je     801008e6 <consoleintr+0x139>
801008d4:	a1 7c ee 10 80       	mov    0x8010ee7c,%eax
801008d9:	8b 15 74 ee 10 80    	mov    0x8010ee74,%edx
801008df:	83 ea 80             	sub    $0xffffff80,%edx
801008e2:	39 d0                	cmp    %edx,%eax
801008e4:	75 1e                	jne    80100904 <consoleintr+0x157>
          input.w = input.e;
801008e6:	a1 7c ee 10 80       	mov    0x8010ee7c,%eax
801008eb:	a3 78 ee 10 80       	mov    %eax,0x8010ee78
          wakeup(&input.r);
801008f0:	c7 04 24 74 ee 10 80 	movl   $0x8010ee74,(%esp)
801008f7:	e8 0f 49 00 00       	call   8010520b <wakeup>
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
80100917:	c7 04 24 c0 ed 10 80 	movl   $0x8010edc0,(%esp)
8010091e:	e8 83 4c 00 00       	call   801055a6 <release>
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
8010093c:	c7 04 24 c0 ed 10 80 	movl   $0x8010edc0,(%esp)
80100943:	e8 c3 4b 00 00       	call   8010550b <acquire>
  while(n > 0){
80100948:	e9 a8 00 00 00       	jmp    801009f5 <consoleread+0xd0>
    while(input.r == input.w){
      if(proc->killed){
8010094d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100953:	8b 40 24             	mov    0x24(%eax),%eax
80100956:	85 c0                	test   %eax,%eax
80100958:	74 21                	je     8010097b <consoleread+0x56>
        release(&input.lock);
8010095a:	c7 04 24 c0 ed 10 80 	movl   $0x8010edc0,(%esp)
80100961:	e8 40 4c 00 00       	call   801055a6 <release>
        ilock(ip);
80100966:	8b 45 08             	mov    0x8(%ebp),%eax
80100969:	89 04 24             	mov    %eax,(%esp)
8010096c:	e8 f7 0e 00 00       	call   80101868 <ilock>
        return -1;
80100971:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100976:	e9 a9 00 00 00       	jmp    80100a24 <consoleread+0xff>
      }
      sleep(&input.r, &input.lock);
8010097b:	c7 44 24 04 c0 ed 10 	movl   $0x8010edc0,0x4(%esp)
80100982:	80 
80100983:	c7 04 24 74 ee 10 80 	movl   $0x8010ee74,(%esp)
8010098a:	e8 40 47 00 00       	call   801050cf <sleep>
8010098f:	eb 01                	jmp    80100992 <consoleread+0x6d>

  iunlock(ip);
  target = n;
  acquire(&input.lock);
  while(n > 0){
    while(input.r == input.w){
80100991:	90                   	nop
80100992:	8b 15 74 ee 10 80    	mov    0x8010ee74,%edx
80100998:	a1 78 ee 10 80       	mov    0x8010ee78,%eax
8010099d:	39 c2                	cmp    %eax,%edx
8010099f:	74 ac                	je     8010094d <consoleread+0x28>
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &input.lock);
    }
    c = input.buf[input.r++ % INPUT_BUF];
801009a1:	a1 74 ee 10 80       	mov    0x8010ee74,%eax
801009a6:	89 c2                	mov    %eax,%edx
801009a8:	83 e2 7f             	and    $0x7f,%edx
801009ab:	0f b6 92 f4 ed 10 80 	movzbl -0x7fef120c(%edx),%edx
801009b2:	0f be d2             	movsbl %dl,%edx
801009b5:	89 55 f0             	mov    %edx,-0x10(%ebp)
801009b8:	83 c0 01             	add    $0x1,%eax
801009bb:	a3 74 ee 10 80       	mov    %eax,0x8010ee74
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
801009ce:	a1 74 ee 10 80       	mov    0x8010ee74,%eax
801009d3:	83 e8 01             	sub    $0x1,%eax
801009d6:	a3 74 ee 10 80       	mov    %eax,0x8010ee74
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
80100a01:	c7 04 24 c0 ed 10 80 	movl   $0x8010edc0,(%esp)
80100a08:	e8 99 4b 00 00       	call   801055a6 <release>
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
80100a37:	c7 04 24 e0 c5 10 80 	movl   $0x8010c5e0,(%esp)
80100a3e:	e8 c8 4a 00 00       	call   8010550b <acquire>
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
80100a71:	c7 04 24 e0 c5 10 80 	movl   $0x8010c5e0,(%esp)
80100a78:	e8 29 4b 00 00       	call   801055a6 <release>
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
80100a93:	c7 44 24 04 03 90 10 	movl   $0x80109003,0x4(%esp)
80100a9a:	80 
80100a9b:	c7 04 24 e0 c5 10 80 	movl   $0x8010c5e0,(%esp)
80100aa2:	e8 43 4a 00 00       	call   801054ea <initlock>
  initlock(&input.lock, "input");
80100aa7:	c7 44 24 04 0b 90 10 	movl   $0x8010900b,0x4(%esp)
80100aae:	80 
80100aaf:	c7 04 24 c0 ed 10 80 	movl   $0x8010edc0,(%esp)
80100ab6:	e8 2f 4a 00 00       	call   801054ea <initlock>

  devsw[CONSOLE].write = consolewrite;
80100abb:	c7 05 2c f8 10 80 26 	movl   $0x80100a26,0x8010f82c
80100ac2:	0a 10 80 
  devsw[CONSOLE].read = consoleread;
80100ac5:	c7 05 28 f8 10 80 25 	movl   $0x80100925,0x8010f828
80100acc:	09 10 80 
  cons.locking = 1;
80100acf:	c7 05 14 c6 10 80 01 	movl   $0x1,0x8010c614
80100ad6:	00 00 00 

  picenable(IRQ_KBD);
80100ad9:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100ae0:	e8 28 32 00 00       	call   80103d0d <picenable>
  ioapicenable(IRQ_KBD, 0);
80100ae5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80100aec:	00 
80100aed:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100af4:	e8 81 1e 00 00       	call   8010297a <ioapicenable>
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
80100b74:	c7 04 24 03 2b 10 80 	movl   $0x80102b03,(%esp)
80100b7b:	e8 e1 7b 00 00       	call   80108761 <setupkvm>
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
80100c14:	e8 1a 7f 00 00       	call   80108b33 <allocuvm>
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
80100c51:	e8 ee 7d 00 00       	call   80108a44 <loaduvm>
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
80100cbc:	e8 72 7e 00 00       	call   80108b33 <allocuvm>
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
80100ce0:	e8 72 80 00 00       	call   80108d57 <clearpteu>
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
80100d0f:	e8 fc 4c 00 00       	call   80105a10 <strlen>
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
80100d2d:	e8 de 4c 00 00       	call   80105a10 <strlen>
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
80100d57:	e8 af 81 00 00       	call   80108f0b <copyout>
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
80100df7:	e8 0f 81 00 00       	call   80108f0b <copyout>
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
80100e4e:	e8 6f 4b 00 00       	call   801059c2 <safestrcpy>

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
80100ea0:	e8 ad 79 00 00       	call   80108852 <switchuvm>
  freevm(oldpgdir);
80100ea5:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100ea8:	89 04 24             	mov    %eax,(%esp)
80100eab:	e8 19 7e 00 00       	call   80108cc9 <freevm>
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
80100ee2:	e8 e2 7d 00 00       	call   80108cc9 <freevm>
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
80100f06:	c7 44 24 04 11 90 10 	movl   $0x80109011,0x4(%esp)
80100f0d:	80 
80100f0e:	c7 04 24 80 ee 10 80 	movl   $0x8010ee80,(%esp)
80100f15:	e8 d0 45 00 00       	call   801054ea <initlock>
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
80100f22:	c7 04 24 80 ee 10 80 	movl   $0x8010ee80,(%esp)
80100f29:	e8 dd 45 00 00       	call   8010550b <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100f2e:	c7 45 f4 b4 ee 10 80 	movl   $0x8010eeb4,-0xc(%ebp)
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
80100f4b:	c7 04 24 80 ee 10 80 	movl   $0x8010ee80,(%esp)
80100f52:	e8 4f 46 00 00       	call   801055a6 <release>
      return f;
80100f57:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f5a:	eb 1e                	jmp    80100f7a <filealloc+0x5e>
filealloc(void)
{
  struct file *f;

  acquire(&ftable.lock);
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100f5c:	83 45 f4 18          	addl   $0x18,-0xc(%ebp)
80100f60:	81 7d f4 14 f8 10 80 	cmpl   $0x8010f814,-0xc(%ebp)
80100f67:	72 ce                	jb     80100f37 <filealloc+0x1b>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
80100f69:	c7 04 24 80 ee 10 80 	movl   $0x8010ee80,(%esp)
80100f70:	e8 31 46 00 00       	call   801055a6 <release>
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
80100f82:	c7 04 24 80 ee 10 80 	movl   $0x8010ee80,(%esp)
80100f89:	e8 7d 45 00 00       	call   8010550b <acquire>
  if(f->ref < 1)
80100f8e:	8b 45 08             	mov    0x8(%ebp),%eax
80100f91:	8b 40 04             	mov    0x4(%eax),%eax
80100f94:	85 c0                	test   %eax,%eax
80100f96:	7f 0c                	jg     80100fa4 <filedup+0x28>
    panic("filedup");
80100f98:	c7 04 24 18 90 10 80 	movl   $0x80109018,(%esp)
80100f9f:	e8 99 f5 ff ff       	call   8010053d <panic>
  f->ref++;
80100fa4:	8b 45 08             	mov    0x8(%ebp),%eax
80100fa7:	8b 40 04             	mov    0x4(%eax),%eax
80100faa:	8d 50 01             	lea    0x1(%eax),%edx
80100fad:	8b 45 08             	mov    0x8(%ebp),%eax
80100fb0:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
80100fb3:	c7 04 24 80 ee 10 80 	movl   $0x8010ee80,(%esp)
80100fba:	e8 e7 45 00 00       	call   801055a6 <release>
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
80100fca:	c7 04 24 80 ee 10 80 	movl   $0x8010ee80,(%esp)
80100fd1:	e8 35 45 00 00       	call   8010550b <acquire>
  if(f->ref < 1)
80100fd6:	8b 45 08             	mov    0x8(%ebp),%eax
80100fd9:	8b 40 04             	mov    0x4(%eax),%eax
80100fdc:	85 c0                	test   %eax,%eax
80100fde:	7f 0c                	jg     80100fec <fileclose+0x28>
    panic("fileclose");
80100fe0:	c7 04 24 20 90 10 80 	movl   $0x80109020,(%esp)
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
80101005:	c7 04 24 80 ee 10 80 	movl   $0x8010ee80,(%esp)
8010100c:	e8 95 45 00 00       	call   801055a6 <release>
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
8010104f:	c7 04 24 80 ee 10 80 	movl   $0x8010ee80,(%esp)
80101056:	e8 4b 45 00 00       	call   801055a6 <release>
  
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
80101074:	e8 4e 2f 00 00       	call   80103fc7 <pipeclose>
80101079:	eb 1d                	jmp    80101098 <fileclose+0xd4>
  else if(ff.type == FD_INODE){
8010107b:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010107e:	83 f8 02             	cmp    $0x2,%eax
80101081:	75 15                	jne    80101098 <fileclose+0xd4>
    begin_trans();
80101083:	e8 e1 23 00 00       	call   80103469 <begin_trans>
    iput(ff.ip);
80101088:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010108b:	89 04 24             	mov    %eax,(%esp)
8010108e:	e8 88 09 00 00       	call   80101a1b <iput>
    commit_trans();
80101093:	e8 1a 24 00 00       	call   801034b2 <commit_trans>
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
80101125:	e8 1f 30 00 00       	call   80104149 <piperead>
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
80101197:	c7 04 24 2a 90 10 80 	movl   $0x8010902a,(%esp)
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
801011e2:	e8 72 2e 00 00       	call   80104059 <pipewrite>
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
8010122a:	e8 3a 22 00 00       	call   80103469 <begin_trans>
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
80101290:	e8 1d 22 00 00       	call   801034b2 <commit_trans>

      if(r < 0)
80101295:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80101299:	78 28                	js     801012c3 <filewrite+0x11e>
        break;
      if(r != n1)
8010129b:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010129e:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801012a1:	74 0c                	je     801012af <filewrite+0x10a>
        panic("short filewrite");
801012a3:	c7 04 24 33 90 10 80 	movl   $0x80109033,(%esp)
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
801012d8:	c7 04 24 43 90 10 80 	movl   $0x80109043,(%esp)
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
80101320:	e8 40 45 00 00       	call   80105865 <memmove>
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
80101366:	e8 27 44 00 00       	call   80105792 <memset>
  log_write(bp);
8010136b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010136e:	89 04 24             	mov    %eax,(%esp)
80101371:	e8 94 21 00 00       	call   8010350a <log_write>
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
80101457:	e8 ae 20 00 00       	call   8010350a <log_write>
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
801014ce:	c7 04 24 4d 90 10 80 	movl   $0x8010904d,(%esp)
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
80101565:	c7 04 24 63 90 10 80 	movl   $0x80109063,(%esp)
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
8010159d:	e8 68 1f 00 00       	call   8010350a <log_write>
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
801015b9:	c7 44 24 04 76 90 10 	movl   $0x80109076,0x4(%esp)
801015c0:	80 
801015c1:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
801015c8:	e8 1d 3f 00 00       	call   801054ea <initlock>
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
8010164a:	e8 43 41 00 00       	call   80105792 <memset>
      dip->type = type;
8010164f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101652:	0f b7 55 d4          	movzwl -0x2c(%ebp),%edx
80101656:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
80101659:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010165c:	89 04 24             	mov    %eax,(%esp)
8010165f:	e8 a6 1e 00 00       	call   8010350a <log_write>
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
801016a0:	c7 04 24 7d 90 10 80 	movl   $0x8010907d,(%esp)
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
80101747:	e8 19 41 00 00       	call   80105865 <memmove>
  log_write(bp);
8010174c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010174f:	89 04 24             	mov    %eax,(%esp)
80101752:	e8 b3 1d 00 00       	call   8010350a <log_write>
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
8010176a:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
80101771:	e8 95 3d 00 00       	call   8010550b <acquire>

  // Is the inode already cached?
  empty = 0;
80101776:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
8010177d:	c7 45 f4 b4 f8 10 80 	movl   $0x8010f8b4,-0xc(%ebp)
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
801017b4:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
801017bb:	e8 e6 3d 00 00       	call   801055a6 <release>
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
801017df:	81 7d f4 54 08 11 80 	cmpl   $0x80110854,-0xc(%ebp)
801017e6:	72 9e                	jb     80101786 <iget+0x22>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
      empty = ip;
  }

  // Recycle an inode cache entry.
  if(empty == 0)
801017e8:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801017ec:	75 0c                	jne    801017fa <iget+0x96>
    panic("iget: no inodes");
801017ee:	c7 04 24 8f 90 10 80 	movl   $0x8010908f,(%esp)
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
80101825:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
8010182c:	e8 75 3d 00 00       	call   801055a6 <release>

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
8010183c:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
80101843:	e8 c3 3c 00 00       	call   8010550b <acquire>
  ip->ref++;
80101848:	8b 45 08             	mov    0x8(%ebp),%eax
8010184b:	8b 40 08             	mov    0x8(%eax),%eax
8010184e:	8d 50 01             	lea    0x1(%eax),%edx
80101851:	8b 45 08             	mov    0x8(%ebp),%eax
80101854:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101857:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
8010185e:	e8 43 3d 00 00       	call   801055a6 <release>
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
8010187e:	c7 04 24 9f 90 10 80 	movl   $0x8010909f,(%esp)
80101885:	e8 b3 ec ff ff       	call   8010053d <panic>

  acquire(&icache.lock);
8010188a:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
80101891:	e8 75 3c 00 00       	call   8010550b <acquire>
  while(ip->flags & I_BUSY)
80101896:	eb 13                	jmp    801018ab <ilock+0x43>
    sleep(ip, &icache.lock);
80101898:	c7 44 24 04 80 f8 10 	movl   $0x8010f880,0x4(%esp)
8010189f:	80 
801018a0:	8b 45 08             	mov    0x8(%ebp),%eax
801018a3:	89 04 24             	mov    %eax,(%esp)
801018a6:	e8 24 38 00 00       	call   801050cf <sleep>

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
801018c9:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
801018d0:	e8 d1 3c 00 00       	call   801055a6 <release>

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
8010197b:	e8 e5 3e 00 00       	call   80105865 <memmove>
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
801019a8:	c7 04 24 a5 90 10 80 	movl   $0x801090a5,(%esp)
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
801019d9:	c7 04 24 b4 90 10 80 	movl   $0x801090b4,(%esp)
801019e0:	e8 58 eb ff ff       	call   8010053d <panic>
  acquire(&icache.lock);
801019e5:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
801019ec:	e8 1a 3b 00 00       	call   8010550b <acquire>
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
80101a08:	e8 fe 37 00 00       	call   8010520b <wakeup>
  release(&icache.lock);
80101a0d:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
80101a14:	e8 8d 3b 00 00       	call   801055a6 <release>
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
80101a21:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
80101a28:	e8 de 3a 00 00       	call   8010550b <acquire>
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
80101a66:	c7 04 24 bc 90 10 80 	movl   $0x801090bc,(%esp)
80101a6d:	e8 cb ea ff ff       	call   8010053d <panic>
    ip->flags |= I_BUSY;
80101a72:	8b 45 08             	mov    0x8(%ebp),%eax
80101a75:	8b 40 0c             	mov    0xc(%eax),%eax
80101a78:	89 c2                	mov    %eax,%edx
80101a7a:	83 ca 01             	or     $0x1,%edx
80101a7d:	8b 45 08             	mov    0x8(%ebp),%eax
80101a80:	89 50 0c             	mov    %edx,0xc(%eax)
    release(&icache.lock);
80101a83:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
80101a8a:	e8 17 3b 00 00       	call   801055a6 <release>
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
80101aae:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
80101ab5:	e8 51 3a 00 00       	call   8010550b <acquire>
    ip->flags = 0;
80101aba:	8b 45 08             	mov    0x8(%ebp),%eax
80101abd:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
80101ac4:	8b 45 08             	mov    0x8(%ebp),%eax
80101ac7:	89 04 24             	mov    %eax,(%esp)
80101aca:	e8 3c 37 00 00       	call   8010520b <wakeup>
  }
  ip->ref--;
80101acf:	8b 45 08             	mov    0x8(%ebp),%eax
80101ad2:	8b 40 08             	mov    0x8(%eax),%eax
80101ad5:	8d 50 ff             	lea    -0x1(%eax),%edx
80101ad8:	8b 45 08             	mov    0x8(%ebp),%eax
80101adb:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101ade:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
80101ae5:	e8 bc 3a 00 00       	call   801055a6 <release>
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
80101be5:	e8 20 19 00 00       	call   8010350a <log_write>
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
80101bfa:	c7 04 24 c6 90 10 80 	movl   $0x801090c6,(%esp)
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
80101d93:	8b 04 c5 20 f8 10 80 	mov    -0x7fef07e0(,%eax,8),%eax
80101d9a:	85 c0                	test   %eax,%eax
80101d9c:	75 0a                	jne    80101da8 <readi+0x4a>
      return -1;
80101d9e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101da3:	e9 1b 01 00 00       	jmp    80101ec3 <readi+0x165>
    return devsw[ip->major].read(ip, dst, n);
80101da8:	8b 45 08             	mov    0x8(%ebp),%eax
80101dab:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101daf:	98                   	cwtl   
80101db0:	8b 14 c5 20 f8 10 80 	mov    -0x7fef07e0(,%eax,8),%edx
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
80101e92:	e8 ce 39 00 00       	call   80105865 <memmove>
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
80101efe:	8b 04 c5 24 f8 10 80 	mov    -0x7fef07dc(,%eax,8),%eax
80101f05:	85 c0                	test   %eax,%eax
80101f07:	75 0a                	jne    80101f13 <writei+0x4a>
      return -1;
80101f09:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101f0e:	e9 46 01 00 00       	jmp    80102059 <writei+0x190>
    return devsw[ip->major].write(ip, src, n);
80101f13:	8b 45 08             	mov    0x8(%ebp),%eax
80101f16:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101f1a:	98                   	cwtl   
80101f1b:	8b 14 c5 24 f8 10 80 	mov    -0x7fef07dc(,%eax,8),%edx
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
80101ff8:	e8 68 38 00 00       	call   80105865 <memmove>
    log_write(bp);
80101ffd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102000:	89 04 24             	mov    %eax,(%esp)
80102003:	e8 02 15 00 00       	call   8010350a <log_write>
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
8010207a:	e8 8a 38 00 00       	call   80105909 <strncmp>
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
80102094:	c7 04 24 d9 90 10 80 	movl   $0x801090d9,(%esp)
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
801020d2:	c7 04 24 eb 90 10 80 	movl   $0x801090eb,(%esp)
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
801021b6:	c7 04 24 eb 90 10 80 	movl   $0x801090eb,(%esp)
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
801021fc:	e8 60 37 00 00       	call   80105961 <strncpy>
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
8010222e:	c7 04 24 f8 90 10 80 	movl   $0x801090f8,(%esp)
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
801022b5:	e8 ab 35 00 00       	call   80105865 <memmove>
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
801022d0:	e8 90 35 00 00       	call   80105865 <memmove>
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

801024e2 <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
801024e2:	55                   	push   %ebp
801024e3:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
801024e5:	fb                   	sti    
}
801024e6:	5d                   	pop    %ebp
801024e7:	c3                   	ret    

801024e8 <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
801024e8:	55                   	push   %ebp
801024e9:	89 e5                	mov    %esp,%ebp
801024eb:	83 ec 14             	sub    $0x14,%esp
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY) 
801024ee:	90                   	nop
801024ef:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801024f6:	e8 55 ff ff ff       	call   80102450 <inb>
801024fb:	0f b6 c0             	movzbl %al,%eax
801024fe:	89 45 fc             	mov    %eax,-0x4(%ebp)
80102501:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102504:	25 c0 00 00 00       	and    $0xc0,%eax
80102509:	83 f8 40             	cmp    $0x40,%eax
8010250c:	75 e1                	jne    801024ef <idewait+0x7>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
8010250e:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102512:	74 11                	je     80102525 <idewait+0x3d>
80102514:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102517:	83 e0 21             	and    $0x21,%eax
8010251a:	85 c0                	test   %eax,%eax
8010251c:	74 07                	je     80102525 <idewait+0x3d>
    return -1;
8010251e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102523:	eb 05                	jmp    8010252a <idewait+0x42>
  return 0;
80102525:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010252a:	c9                   	leave  
8010252b:	c3                   	ret    

8010252c <ideinit>:

void
ideinit(void)
{
8010252c:	55                   	push   %ebp
8010252d:	89 e5                	mov    %esp,%ebp
8010252f:	83 ec 28             	sub    $0x28,%esp
  int i;

  initlock(&idelock, "ide");
80102532:	c7 44 24 04 00 91 10 	movl   $0x80109100,0x4(%esp)
80102539:	80 
8010253a:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
80102541:	e8 a4 2f 00 00       	call   801054ea <initlock>
  picenable(IRQ_IDE);
80102546:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
8010254d:	e8 bb 17 00 00       	call   80103d0d <picenable>
  ioapicenable(IRQ_IDE, ncpu - 1);
80102552:	a1 60 2f 11 80       	mov    0x80112f60,%eax
80102557:	83 e8 01             	sub    $0x1,%eax
8010255a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010255e:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
80102565:	e8 10 04 00 00       	call   8010297a <ioapicenable>
  idewait(0);
8010256a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102571:	e8 72 ff ff ff       	call   801024e8 <idewait>
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
80102576:	c7 44 24 04 f0 00 00 	movl   $0xf0,0x4(%esp)
8010257d:	00 
8010257e:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102585:	e8 15 ff ff ff       	call   8010249f <outb>
  for(i=0; i<1000; i++){
8010258a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102591:	eb 20                	jmp    801025b3 <ideinit+0x87>
    if(inb(0x1f7) != 0){
80102593:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
8010259a:	e8 b1 fe ff ff       	call   80102450 <inb>
8010259f:	84 c0                	test   %al,%al
801025a1:	74 0c                	je     801025af <ideinit+0x83>
      havedisk1 = 1;
801025a3:	c7 05 58 c6 10 80 01 	movl   $0x1,0x8010c658
801025aa:	00 00 00 
      break;
801025ad:	eb 0d                	jmp    801025bc <ideinit+0x90>
  ioapicenable(IRQ_IDE, ncpu - 1);
  idewait(0);
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
  for(i=0; i<1000; i++){
801025af:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801025b3:	81 7d f4 e7 03 00 00 	cmpl   $0x3e7,-0xc(%ebp)
801025ba:	7e d7                	jle    80102593 <ideinit+0x67>
      break;
    }
  }
  
  // Switch back to disk 0.
  outb(0x1f6, 0xe0 | (0<<4));
801025bc:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
801025c3:	00 
801025c4:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
801025cb:	e8 cf fe ff ff       	call   8010249f <outb>
}
801025d0:	c9                   	leave  
801025d1:	c3                   	ret    

801025d2 <idestart>:

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
801025d2:	55                   	push   %ebp
801025d3:	89 e5                	mov    %esp,%ebp
801025d5:	83 ec 18             	sub    $0x18,%esp
  if(b == 0)
801025d8:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801025dc:	75 0c                	jne    801025ea <idestart+0x18>
    panic("idestart");
801025de:	c7 04 24 04 91 10 80 	movl   $0x80109104,(%esp)
801025e5:	e8 53 df ff ff       	call   8010053d <panic>

  idewait(0);
801025ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801025f1:	e8 f2 fe ff ff       	call   801024e8 <idewait>
  outb(0x3f6, 0);  // generate interrupt
801025f6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801025fd:	00 
801025fe:	c7 04 24 f6 03 00 00 	movl   $0x3f6,(%esp)
80102605:	e8 95 fe ff ff       	call   8010249f <outb>
  outb(0x1f2, 1);  // number of sectors
8010260a:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102611:	00 
80102612:	c7 04 24 f2 01 00 00 	movl   $0x1f2,(%esp)
80102619:	e8 81 fe ff ff       	call   8010249f <outb>
  outb(0x1f3, b->sector & 0xff);
8010261e:	8b 45 08             	mov    0x8(%ebp),%eax
80102621:	8b 40 08             	mov    0x8(%eax),%eax
80102624:	0f b6 c0             	movzbl %al,%eax
80102627:	89 44 24 04          	mov    %eax,0x4(%esp)
8010262b:	c7 04 24 f3 01 00 00 	movl   $0x1f3,(%esp)
80102632:	e8 68 fe ff ff       	call   8010249f <outb>
  outb(0x1f4, (b->sector >> 8) & 0xff);
80102637:	8b 45 08             	mov    0x8(%ebp),%eax
8010263a:	8b 40 08             	mov    0x8(%eax),%eax
8010263d:	c1 e8 08             	shr    $0x8,%eax
80102640:	0f b6 c0             	movzbl %al,%eax
80102643:	89 44 24 04          	mov    %eax,0x4(%esp)
80102647:	c7 04 24 f4 01 00 00 	movl   $0x1f4,(%esp)
8010264e:	e8 4c fe ff ff       	call   8010249f <outb>
  outb(0x1f5, (b->sector >> 16) & 0xff);
80102653:	8b 45 08             	mov    0x8(%ebp),%eax
80102656:	8b 40 08             	mov    0x8(%eax),%eax
80102659:	c1 e8 10             	shr    $0x10,%eax
8010265c:	0f b6 c0             	movzbl %al,%eax
8010265f:	89 44 24 04          	mov    %eax,0x4(%esp)
80102663:	c7 04 24 f5 01 00 00 	movl   $0x1f5,(%esp)
8010266a:	e8 30 fe ff ff       	call   8010249f <outb>
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((b->sector>>24)&0x0f));
8010266f:	8b 45 08             	mov    0x8(%ebp),%eax
80102672:	8b 40 04             	mov    0x4(%eax),%eax
80102675:	83 e0 01             	and    $0x1,%eax
80102678:	89 c2                	mov    %eax,%edx
8010267a:	c1 e2 04             	shl    $0x4,%edx
8010267d:	8b 45 08             	mov    0x8(%ebp),%eax
80102680:	8b 40 08             	mov    0x8(%eax),%eax
80102683:	c1 e8 18             	shr    $0x18,%eax
80102686:	83 e0 0f             	and    $0xf,%eax
80102689:	09 d0                	or     %edx,%eax
8010268b:	83 c8 e0             	or     $0xffffffe0,%eax
8010268e:	0f b6 c0             	movzbl %al,%eax
80102691:	89 44 24 04          	mov    %eax,0x4(%esp)
80102695:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
8010269c:	e8 fe fd ff ff       	call   8010249f <outb>
  if(b->flags & B_DIRTY){
801026a1:	8b 45 08             	mov    0x8(%ebp),%eax
801026a4:	8b 00                	mov    (%eax),%eax
801026a6:	83 e0 04             	and    $0x4,%eax
801026a9:	85 c0                	test   %eax,%eax
801026ab:	74 34                	je     801026e1 <idestart+0x10f>
    outb(0x1f7, IDE_CMD_WRITE);
801026ad:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
801026b4:	00 
801026b5:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801026bc:	e8 de fd ff ff       	call   8010249f <outb>
    outsl(0x1f0, b->data, 512/4);
801026c1:	8b 45 08             	mov    0x8(%ebp),%eax
801026c4:	83 c0 18             	add    $0x18,%eax
801026c7:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
801026ce:	00 
801026cf:	89 44 24 04          	mov    %eax,0x4(%esp)
801026d3:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
801026da:	e8 de fd ff ff       	call   801024bd <outsl>
801026df:	eb 14                	jmp    801026f5 <idestart+0x123>
  } else {
    outb(0x1f7, IDE_CMD_READ);
801026e1:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
801026e8:	00 
801026e9:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801026f0:	e8 aa fd ff ff       	call   8010249f <outb>
  }
}
801026f5:	c9                   	leave  
801026f6:	c3                   	ret    

801026f7 <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
801026f7:	55                   	push   %ebp
801026f8:	89 e5                	mov    %esp,%ebp
801026fa:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
801026fd:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
80102704:	e8 02 2e 00 00       	call   8010550b <acquire>
  if((b = idequeue) == 0){
80102709:	a1 54 c6 10 80       	mov    0x8010c654,%eax
8010270e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102711:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102715:	75 11                	jne    80102728 <ideintr+0x31>
    release(&idelock);
80102717:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
8010271e:	e8 83 2e 00 00       	call   801055a6 <release>
    // cprintf("spurious IDE interrupt\n");
    return;
80102723:	e9 85 00 00 00       	jmp    801027ad <ideintr+0xb6>
  }
  idequeue = b->qnext;
80102728:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010272b:	8b 40 14             	mov    0x14(%eax),%eax
8010272e:	a3 54 c6 10 80       	mov    %eax,0x8010c654

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80102733:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102736:	8b 00                	mov    (%eax),%eax
80102738:	83 e0 04             	and    $0x4,%eax
8010273b:	85 c0                	test   %eax,%eax
8010273d:	75 2e                	jne    8010276d <ideintr+0x76>
8010273f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102746:	e8 9d fd ff ff       	call   801024e8 <idewait>
8010274b:	85 c0                	test   %eax,%eax
8010274d:	78 1e                	js     8010276d <ideintr+0x76>
    insl(0x1f0, b->data, 512/4);
8010274f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102752:	83 c0 18             	add    $0x18,%eax
80102755:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
8010275c:	00 
8010275d:	89 44 24 04          	mov    %eax,0x4(%esp)
80102761:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
80102768:	e8 0d fd ff ff       	call   8010247a <insl>
  
  // Wake process waiting for this buf.
  b->flags |= B_VALID;
8010276d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102770:	8b 00                	mov    (%eax),%eax
80102772:	89 c2                	mov    %eax,%edx
80102774:	83 ca 02             	or     $0x2,%edx
80102777:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010277a:	89 10                	mov    %edx,(%eax)
  b->flags &= ~B_DIRTY;
8010277c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010277f:	8b 00                	mov    (%eax),%eax
80102781:	89 c2                	mov    %eax,%edx
80102783:	83 e2 fb             	and    $0xfffffffb,%edx
80102786:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102789:	89 10                	mov    %edx,(%eax)
  //wakeup(b);
  
  // Start disk on next buf in queue.
  if(idequeue != 0)
8010278b:	a1 54 c6 10 80       	mov    0x8010c654,%eax
80102790:	85 c0                	test   %eax,%eax
80102792:	74 0d                	je     801027a1 <ideintr+0xaa>
    idestart(idequeue);
80102794:	a1 54 c6 10 80       	mov    0x8010c654,%eax
80102799:	89 04 24             	mov    %eax,(%esp)
8010279c:	e8 31 fe ff ff       	call   801025d2 <idestart>

  release(&idelock);
801027a1:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
801027a8:	e8 f9 2d 00 00       	call   801055a6 <release>
}
801027ad:	c9                   	leave  
801027ae:	c3                   	ret    

801027af <iderw>:
// Sync buf with disk. 
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
801027af:	55                   	push   %ebp
801027b0:	89 e5                	mov    %esp,%ebp
801027b2:	83 ec 28             	sub    $0x28,%esp
  struct buf **pp;

  if(!(b->flags & B_BUSY))
801027b5:	8b 45 08             	mov    0x8(%ebp),%eax
801027b8:	8b 00                	mov    (%eax),%eax
801027ba:	83 e0 01             	and    $0x1,%eax
801027bd:	85 c0                	test   %eax,%eax
801027bf:	75 0c                	jne    801027cd <iderw+0x1e>
    panic("iderw: buf not busy");
801027c1:	c7 04 24 0d 91 10 80 	movl   $0x8010910d,(%esp)
801027c8:	e8 70 dd ff ff       	call   8010053d <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
801027cd:	8b 45 08             	mov    0x8(%ebp),%eax
801027d0:	8b 00                	mov    (%eax),%eax
801027d2:	83 e0 06             	and    $0x6,%eax
801027d5:	83 f8 02             	cmp    $0x2,%eax
801027d8:	75 0c                	jne    801027e6 <iderw+0x37>
    panic("iderw: nothing to do");
801027da:	c7 04 24 21 91 10 80 	movl   $0x80109121,(%esp)
801027e1:	e8 57 dd ff ff       	call   8010053d <panic>
  if(b->dev != 0 && !havedisk1)
801027e6:	8b 45 08             	mov    0x8(%ebp),%eax
801027e9:	8b 40 04             	mov    0x4(%eax),%eax
801027ec:	85 c0                	test   %eax,%eax
801027ee:	74 15                	je     80102805 <iderw+0x56>
801027f0:	a1 58 c6 10 80       	mov    0x8010c658,%eax
801027f5:	85 c0                	test   %eax,%eax
801027f7:	75 0c                	jne    80102805 <iderw+0x56>
    panic("iderw: ide disk 1 not present");
801027f9:	c7 04 24 36 91 10 80 	movl   $0x80109136,(%esp)
80102800:	e8 38 dd ff ff       	call   8010053d <panic>

  acquire(&idelock);  //DOC: acquire-lock
80102805:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
8010280c:	e8 fa 2c 00 00       	call   8010550b <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80102811:	8b 45 08             	mov    0x8(%ebp),%eax
80102814:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC: insert-queue
8010281b:	c7 45 f4 54 c6 10 80 	movl   $0x8010c654,-0xc(%ebp)
80102822:	eb 0b                	jmp    8010282f <iderw+0x80>
80102824:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102827:	8b 00                	mov    (%eax),%eax
80102829:	83 c0 14             	add    $0x14,%eax
8010282c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010282f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102832:	8b 00                	mov    (%eax),%eax
80102834:	85 c0                	test   %eax,%eax
80102836:	75 ec                	jne    80102824 <iderw+0x75>
    ;
  *pp = b;
80102838:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010283b:	8b 55 08             	mov    0x8(%ebp),%edx
8010283e:	89 10                	mov    %edx,(%eax)
  
  // Start disk if necessary.
  if(idequeue == b)
80102840:	a1 54 c6 10 80       	mov    0x8010c654,%eax
80102845:	3b 45 08             	cmp    0x8(%ebp),%eax
80102848:	75 2c                	jne    80102876 <iderw+0xc7>
    idestart(b);
8010284a:	8b 45 08             	mov    0x8(%ebp),%eax
8010284d:	89 04 24             	mov    %eax,(%esp)
80102850:	e8 7d fd ff ff       	call   801025d2 <idestart>
  
  // Wait for request to finish.

    while((b->flags & (B_VALID|B_DIRTY)) != B_VALID) 
80102855:	eb 1f                	jmp    80102876 <iderw+0xc7>
    {
	release(&idelock);
80102857:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
8010285e:	e8 43 2d 00 00       	call   801055a6 <release>
	sti();
80102863:	e8 7a fc ff ff       	call   801024e2 <sti>
	acquire(&idelock); 
80102868:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
8010286f:	e8 97 2c 00 00       	call   8010550b <acquire>
80102874:	eb 01                	jmp    80102877 <iderw+0xc8>
  if(idequeue == b)
    idestart(b);
  
  // Wait for request to finish.

    while((b->flags & (B_VALID|B_DIRTY)) != B_VALID) 
80102876:	90                   	nop
80102877:	8b 45 08             	mov    0x8(%ebp),%eax
8010287a:	8b 00                	mov    (%eax),%eax
8010287c:	83 e0 06             	and    $0x6,%eax
8010287f:	83 f8 02             	cmp    $0x2,%eax
80102882:	75 d3                	jne    80102857 <iderw+0xa8>
    }
    
    
    //sleep(b, &idelock);

    release(&idelock);
80102884:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
8010288b:	e8 16 2d 00 00       	call   801055a6 <release>
}
80102890:	c9                   	leave  
80102891:	c3                   	ret    
	...

80102894 <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
80102894:	55                   	push   %ebp
80102895:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80102897:	a1 54 08 11 80       	mov    0x80110854,%eax
8010289c:	8b 55 08             	mov    0x8(%ebp),%edx
8010289f:	89 10                	mov    %edx,(%eax)
  return ioapic->data;
801028a1:	a1 54 08 11 80       	mov    0x80110854,%eax
801028a6:	8b 40 10             	mov    0x10(%eax),%eax
}
801028a9:	5d                   	pop    %ebp
801028aa:	c3                   	ret    

801028ab <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
801028ab:	55                   	push   %ebp
801028ac:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
801028ae:	a1 54 08 11 80       	mov    0x80110854,%eax
801028b3:	8b 55 08             	mov    0x8(%ebp),%edx
801028b6:	89 10                	mov    %edx,(%eax)
  ioapic->data = data;
801028b8:	a1 54 08 11 80       	mov    0x80110854,%eax
801028bd:	8b 55 0c             	mov    0xc(%ebp),%edx
801028c0:	89 50 10             	mov    %edx,0x10(%eax)
}
801028c3:	5d                   	pop    %ebp
801028c4:	c3                   	ret    

801028c5 <ioapicinit>:

void
ioapicinit(void)
{
801028c5:	55                   	push   %ebp
801028c6:	89 e5                	mov    %esp,%ebp
801028c8:	83 ec 28             	sub    $0x28,%esp
  int i, id, maxintr;

  if(!ismp)
801028cb:	a1 64 29 11 80       	mov    0x80112964,%eax
801028d0:	85 c0                	test   %eax,%eax
801028d2:	0f 84 9f 00 00 00    	je     80102977 <ioapicinit+0xb2>
    return;

  ioapic = (volatile struct ioapic*)IOAPIC;
801028d8:	c7 05 54 08 11 80 00 	movl   $0xfec00000,0x80110854
801028df:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
801028e2:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801028e9:	e8 a6 ff ff ff       	call   80102894 <ioapicread>
801028ee:	c1 e8 10             	shr    $0x10,%eax
801028f1:	25 ff 00 00 00       	and    $0xff,%eax
801028f6:	89 45 f0             	mov    %eax,-0x10(%ebp)
  id = ioapicread(REG_ID) >> 24;
801028f9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102900:	e8 8f ff ff ff       	call   80102894 <ioapicread>
80102905:	c1 e8 18             	shr    $0x18,%eax
80102908:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(id != ioapicid)
8010290b:	0f b6 05 60 29 11 80 	movzbl 0x80112960,%eax
80102912:	0f b6 c0             	movzbl %al,%eax
80102915:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80102918:	74 0c                	je     80102926 <ioapicinit+0x61>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
8010291a:	c7 04 24 54 91 10 80 	movl   $0x80109154,(%esp)
80102921:	e8 7b da ff ff       	call   801003a1 <cprintf>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80102926:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010292d:	eb 3e                	jmp    8010296d <ioapicinit+0xa8>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
8010292f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102932:	83 c0 20             	add    $0x20,%eax
80102935:	0d 00 00 01 00       	or     $0x10000,%eax
8010293a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010293d:	83 c2 08             	add    $0x8,%edx
80102940:	01 d2                	add    %edx,%edx
80102942:	89 44 24 04          	mov    %eax,0x4(%esp)
80102946:	89 14 24             	mov    %edx,(%esp)
80102949:	e8 5d ff ff ff       	call   801028ab <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
8010294e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102951:	83 c0 08             	add    $0x8,%eax
80102954:	01 c0                	add    %eax,%eax
80102956:	83 c0 01             	add    $0x1,%eax
80102959:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102960:	00 
80102961:	89 04 24             	mov    %eax,(%esp)
80102964:	e8 42 ff ff ff       	call   801028ab <ioapicwrite>
  if(id != ioapicid)
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80102969:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010296d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102970:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80102973:	7e ba                	jle    8010292f <ioapicinit+0x6a>
80102975:	eb 01                	jmp    80102978 <ioapicinit+0xb3>
ioapicinit(void)
{
  int i, id, maxintr;

  if(!ismp)
    return;
80102977:	90                   	nop
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
    ioapicwrite(REG_TABLE+2*i+1, 0);
  }
}
80102978:	c9                   	leave  
80102979:	c3                   	ret    

8010297a <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
8010297a:	55                   	push   %ebp
8010297b:	89 e5                	mov    %esp,%ebp
8010297d:	83 ec 08             	sub    $0x8,%esp
  if(!ismp)
80102980:	a1 64 29 11 80       	mov    0x80112964,%eax
80102985:	85 c0                	test   %eax,%eax
80102987:	74 39                	je     801029c2 <ioapicenable+0x48>
    return;

  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
80102989:	8b 45 08             	mov    0x8(%ebp),%eax
8010298c:	83 c0 20             	add    $0x20,%eax
8010298f:	8b 55 08             	mov    0x8(%ebp),%edx
80102992:	83 c2 08             	add    $0x8,%edx
80102995:	01 d2                	add    %edx,%edx
80102997:	89 44 24 04          	mov    %eax,0x4(%esp)
8010299b:	89 14 24             	mov    %edx,(%esp)
8010299e:	e8 08 ff ff ff       	call   801028ab <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
801029a3:	8b 45 0c             	mov    0xc(%ebp),%eax
801029a6:	c1 e0 18             	shl    $0x18,%eax
801029a9:	8b 55 08             	mov    0x8(%ebp),%edx
801029ac:	83 c2 08             	add    $0x8,%edx
801029af:	01 d2                	add    %edx,%edx
801029b1:	83 c2 01             	add    $0x1,%edx
801029b4:	89 44 24 04          	mov    %eax,0x4(%esp)
801029b8:	89 14 24             	mov    %edx,(%esp)
801029bb:	e8 eb fe ff ff       	call   801028ab <ioapicwrite>
801029c0:	eb 01                	jmp    801029c3 <ioapicenable+0x49>

void
ioapicenable(int irq, int cpunum)
{
  if(!ismp)
    return;
801029c2:	90                   	nop
  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
}
801029c3:	c9                   	leave  
801029c4:	c3                   	ret    
801029c5:	00 00                	add    %al,(%eax)
	...

801029c8 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
801029c8:	55                   	push   %ebp
801029c9:	89 e5                	mov    %esp,%ebp
801029cb:	8b 45 08             	mov    0x8(%ebp),%eax
801029ce:	05 00 00 00 80       	add    $0x80000000,%eax
801029d3:	5d                   	pop    %ebp
801029d4:	c3                   	ret    

801029d5 <kinit1>:
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
801029d5:	55                   	push   %ebp
801029d6:	89 e5                	mov    %esp,%ebp
801029d8:	83 ec 18             	sub    $0x18,%esp
  initlock(&kmem.lock, "kmem");
801029db:	c7 44 24 04 86 91 10 	movl   $0x80109186,0x4(%esp)
801029e2:	80 
801029e3:	c7 04 24 60 08 11 80 	movl   $0x80110860,(%esp)
801029ea:	e8 fb 2a 00 00       	call   801054ea <initlock>
  kmem.use_lock = 0;
801029ef:	c7 05 94 08 11 80 00 	movl   $0x0,0x80110894
801029f6:	00 00 00 
  freerange(vstart, vend);
801029f9:	8b 45 0c             	mov    0xc(%ebp),%eax
801029fc:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a00:	8b 45 08             	mov    0x8(%ebp),%eax
80102a03:	89 04 24             	mov    %eax,(%esp)
80102a06:	e8 26 00 00 00       	call   80102a31 <freerange>
}
80102a0b:	c9                   	leave  
80102a0c:	c3                   	ret    

80102a0d <kinit2>:

void
kinit2(void *vstart, void *vend)
{
80102a0d:	55                   	push   %ebp
80102a0e:	89 e5                	mov    %esp,%ebp
80102a10:	83 ec 18             	sub    $0x18,%esp
  freerange(vstart, vend);
80102a13:	8b 45 0c             	mov    0xc(%ebp),%eax
80102a16:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a1a:	8b 45 08             	mov    0x8(%ebp),%eax
80102a1d:	89 04 24             	mov    %eax,(%esp)
80102a20:	e8 0c 00 00 00       	call   80102a31 <freerange>
  kmem.use_lock = 1;
80102a25:	c7 05 94 08 11 80 01 	movl   $0x1,0x80110894
80102a2c:	00 00 00 
}
80102a2f:	c9                   	leave  
80102a30:	c3                   	ret    

80102a31 <freerange>:

void
freerange(void *vstart, void *vend)
{
80102a31:	55                   	push   %ebp
80102a32:	89 e5                	mov    %esp,%ebp
80102a34:	83 ec 28             	sub    $0x28,%esp
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
80102a37:	8b 45 08             	mov    0x8(%ebp),%eax
80102a3a:	05 ff 0f 00 00       	add    $0xfff,%eax
80102a3f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80102a44:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102a47:	eb 12                	jmp    80102a5b <freerange+0x2a>
    kfree(p);
80102a49:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a4c:	89 04 24             	mov    %eax,(%esp)
80102a4f:	e8 16 00 00 00       	call   80102a6a <kfree>
void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102a54:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80102a5b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a5e:	05 00 10 00 00       	add    $0x1000,%eax
80102a63:	3b 45 0c             	cmp    0xc(%ebp),%eax
80102a66:	76 e1                	jbe    80102a49 <freerange+0x18>
    kfree(p);
}
80102a68:	c9                   	leave  
80102a69:	c3                   	ret    

80102a6a <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
80102a6a:	55                   	push   %ebp
80102a6b:	89 e5                	mov    %esp,%ebp
80102a6d:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if((uint)v % PGSIZE || v < end || v2p(v) >= PHYSTOP)
80102a70:	8b 45 08             	mov    0x8(%ebp),%eax
80102a73:	25 ff 0f 00 00       	and    $0xfff,%eax
80102a78:	85 c0                	test   %eax,%eax
80102a7a:	75 1b                	jne    80102a97 <kfree+0x2d>
80102a7c:	81 7d 08 5c 5b 11 80 	cmpl   $0x80115b5c,0x8(%ebp)
80102a83:	72 12                	jb     80102a97 <kfree+0x2d>
80102a85:	8b 45 08             	mov    0x8(%ebp),%eax
80102a88:	89 04 24             	mov    %eax,(%esp)
80102a8b:	e8 38 ff ff ff       	call   801029c8 <v2p>
80102a90:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80102a95:	76 0c                	jbe    80102aa3 <kfree+0x39>
    panic("kfree");
80102a97:	c7 04 24 8b 91 10 80 	movl   $0x8010918b,(%esp)
80102a9e:	e8 9a da ff ff       	call   8010053d <panic>

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80102aa3:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80102aaa:	00 
80102aab:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102ab2:	00 
80102ab3:	8b 45 08             	mov    0x8(%ebp),%eax
80102ab6:	89 04 24             	mov    %eax,(%esp)
80102ab9:	e8 d4 2c 00 00       	call   80105792 <memset>

  if(kmem.use_lock)
80102abe:	a1 94 08 11 80       	mov    0x80110894,%eax
80102ac3:	85 c0                	test   %eax,%eax
80102ac5:	74 0c                	je     80102ad3 <kfree+0x69>
    acquire(&kmem.lock);
80102ac7:	c7 04 24 60 08 11 80 	movl   $0x80110860,(%esp)
80102ace:	e8 38 2a 00 00       	call   8010550b <acquire>
  r = (struct run*)v;
80102ad3:	8b 45 08             	mov    0x8(%ebp),%eax
80102ad6:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
80102ad9:	8b 15 98 08 11 80    	mov    0x80110898,%edx
80102adf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102ae2:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
80102ae4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102ae7:	a3 98 08 11 80       	mov    %eax,0x80110898
  if(kmem.use_lock)
80102aec:	a1 94 08 11 80       	mov    0x80110894,%eax
80102af1:	85 c0                	test   %eax,%eax
80102af3:	74 0c                	je     80102b01 <kfree+0x97>
    release(&kmem.lock);
80102af5:	c7 04 24 60 08 11 80 	movl   $0x80110860,(%esp)
80102afc:	e8 a5 2a 00 00       	call   801055a6 <release>
}
80102b01:	c9                   	leave  
80102b02:	c3                   	ret    

80102b03 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
80102b03:	55                   	push   %ebp
80102b04:	89 e5                	mov    %esp,%ebp
80102b06:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if(kmem.use_lock)
80102b09:	a1 94 08 11 80       	mov    0x80110894,%eax
80102b0e:	85 c0                	test   %eax,%eax
80102b10:	74 0c                	je     80102b1e <kalloc+0x1b>
    acquire(&kmem.lock);
80102b12:	c7 04 24 60 08 11 80 	movl   $0x80110860,(%esp)
80102b19:	e8 ed 29 00 00       	call   8010550b <acquire>
  r = kmem.freelist;
80102b1e:	a1 98 08 11 80       	mov    0x80110898,%eax
80102b23:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
80102b26:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102b2a:	74 0a                	je     80102b36 <kalloc+0x33>
    kmem.freelist = r->next;
80102b2c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b2f:	8b 00                	mov    (%eax),%eax
80102b31:	a3 98 08 11 80       	mov    %eax,0x80110898
  if(kmem.use_lock)
80102b36:	a1 94 08 11 80       	mov    0x80110894,%eax
80102b3b:	85 c0                	test   %eax,%eax
80102b3d:	74 0c                	je     80102b4b <kalloc+0x48>
    release(&kmem.lock);
80102b3f:	c7 04 24 60 08 11 80 	movl   $0x80110860,(%esp)
80102b46:	e8 5b 2a 00 00       	call   801055a6 <release>
  return (char*)r;
80102b4b:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102b4e:	c9                   	leave  
80102b4f:	c3                   	ret    

80102b50 <shmget>:


int shmget(int key, uint size, int shmflg)
{
80102b50:	55                   	push   %ebp
80102b51:	89 e5                	mov    %esp,%ebp
80102b53:	83 ec 28             	sub    $0x28,%esp
  int numOfPages,i,ans;
  if(kmem.use_lock)
80102b56:	a1 94 08 11 80       	mov    0x80110894,%eax
80102b5b:	85 c0                	test   %eax,%eax
80102b5d:	74 0c                	je     80102b6b <shmget+0x1b>
    acquire(&kmem.lock);
80102b5f:	c7 04 24 60 08 11 80 	movl   $0x80110860,(%esp)
80102b66:	e8 a0 29 00 00       	call   8010550b <acquire>
  switch(shmflg)
80102b6b:	8b 45 10             	mov    0x10(%ebp),%eax
80102b6e:	83 f8 14             	cmp    $0x14,%eax
80102b71:	74 0e                	je     80102b81 <shmget+0x31>
80102b73:	83 f8 15             	cmp    $0x15,%eax
80102b76:	0f 84 ca 00 00 00    	je     80102c46 <shmget+0xf6>
80102b7c:	e9 0b 01 00 00       	jmp    80102c8c <shmget+0x13c>
  {
    case CREAT:
      if(!shm.seg[key])
80102b81:	8b 45 08             	mov    0x8(%ebp),%eax
80102b84:	8b 04 85 a0 08 11 80 	mov    -0x7feef760(,%eax,4),%eax
80102b8b:	85 c0                	test   %eax,%eax
80102b8d:	0f 85 aa 00 00 00    	jne    80102c3d <shmget+0xed>
      {
	struct run* r = kmem.freelist;
80102b93:	a1 98 08 11 80       	mov    0x80110898,%eax
80102b98:	89 45 ec             	mov    %eax,-0x14(%ebp)
	size = PGROUNDUP(size);
80102b9b:	8b 45 0c             	mov    0xc(%ebp),%eax
80102b9e:	05 ff 0f 00 00       	add    $0xfff,%eax
80102ba3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80102ba8:	89 45 0c             	mov    %eax,0xc(%ebp)
	numOfPages = size/PGSIZE;
80102bab:	8b 45 0c             	mov    0xc(%ebp),%eax
80102bae:	c1 e8 0c             	shr    $0xc,%eax
80102bb1:	89 45 e8             	mov    %eax,-0x18(%ebp)
	shm.seg[key] = kmem.freelist;
80102bb4:	8b 15 98 08 11 80    	mov    0x80110898,%edx
80102bba:	8b 45 08             	mov    0x8(%ebp),%eax
80102bbd:	89 14 85 a0 08 11 80 	mov    %edx,-0x7feef760(,%eax,4)
	
	for(i=0;i<numOfPages;i++)
80102bc4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102bcb:	eb 0c                	jmp    80102bd9 <shmget+0x89>
	{
	  r = r->next;
80102bcd:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102bd0:	8b 00                	mov    (%eax),%eax
80102bd2:	89 45 ec             	mov    %eax,-0x14(%ebp)
	struct run* r = kmem.freelist;
	size = PGROUNDUP(size);
	numOfPages = size/PGSIZE;
	shm.seg[key] = kmem.freelist;
	
	for(i=0;i<numOfPages;i++)
80102bd5:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102bd9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102bdc:	3b 45 e8             	cmp    -0x18(%ebp),%eax
80102bdf:	7c ec                	jl     80102bcd <shmget+0x7d>
	{
	  r = r->next;
	}
	
	if(i == numOfPages-1)
80102be1:	8b 45 e8             	mov    -0x18(%ebp),%eax
80102be4:	83 e8 01             	sub    $0x1,%eax
80102be7:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80102bea:	75 3a                	jne    80102c26 <shmget+0xd6>
	{
	  kmem.freelist = r->next;
80102bec:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102bef:	8b 00                	mov    (%eax),%eax
80102bf1:	a3 98 08 11 80       	mov    %eax,0x80110898
	  ans = (int)shm.seg[key];
80102bf6:	8b 45 08             	mov    0x8(%ebp),%eax
80102bf9:	8b 04 85 a0 08 11 80 	mov    -0x7feef760(,%eax,4),%eax
80102c00:	89 45 f0             	mov    %eax,-0x10(%ebp)
	  shm.refs[key]++;
80102c03:	8b 45 08             	mov    0x8(%ebp),%eax
80102c06:	05 00 04 00 00       	add    $0x400,%eax
80102c0b:	8b 04 85 a0 08 11 80 	mov    -0x7feef760(,%eax,4),%eax
80102c12:	8d 50 01             	lea    0x1(%eax),%edx
80102c15:	8b 45 08             	mov    0x8(%ebp),%eax
80102c18:	05 00 04 00 00       	add    $0x400,%eax
80102c1d:	89 14 85 a0 08 11 80 	mov    %edx,-0x7feef760(,%eax,4)
	else
	{
	  shm.seg[key] = 0;
	  ans = -1;
	}
	break;
80102c24:	eb 66                	jmp    80102c8c <shmget+0x13c>
	  ans = (int)shm.seg[key];
	  shm.refs[key]++;
	}
	else
	{
	  shm.seg[key] = 0;
80102c26:	8b 45 08             	mov    0x8(%ebp),%eax
80102c29:	c7 04 85 a0 08 11 80 	movl   $0x0,-0x7feef760(,%eax,4)
80102c30:	00 00 00 00 
	  ans = -1;
80102c34:	c7 45 f0 ff ff ff ff 	movl   $0xffffffff,-0x10(%ebp)
	}
	break;
80102c3b:	eb 4f                	jmp    80102c8c <shmget+0x13c>
      }
      else
	ans = -1;
80102c3d:	c7 45 f0 ff ff ff ff 	movl   $0xffffffff,-0x10(%ebp)
      break;
80102c44:	eb 46                	jmp    80102c8c <shmget+0x13c>
    case GET:
      if(!shm.seg[key])
80102c46:	8b 45 08             	mov    0x8(%ebp),%eax
80102c49:	8b 04 85 a0 08 11 80 	mov    -0x7feef760(,%eax,4),%eax
80102c50:	85 c0                	test   %eax,%eax
80102c52:	75 09                	jne    80102c5d <shmget+0x10d>
	ans = -1;
80102c54:	c7 45 f0 ff ff ff ff 	movl   $0xffffffff,-0x10(%ebp)
      else
      {
	ans = (int)shm.seg[key];
	shm.refs[key]++;
      }
      break;
80102c5b:	eb 2e                	jmp    80102c8b <shmget+0x13b>
    case GET:
      if(!shm.seg[key])
	ans = -1;
      else
      {
	ans = (int)shm.seg[key];
80102c5d:	8b 45 08             	mov    0x8(%ebp),%eax
80102c60:	8b 04 85 a0 08 11 80 	mov    -0x7feef760(,%eax,4),%eax
80102c67:	89 45 f0             	mov    %eax,-0x10(%ebp)
	shm.refs[key]++;
80102c6a:	8b 45 08             	mov    0x8(%ebp),%eax
80102c6d:	05 00 04 00 00       	add    $0x400,%eax
80102c72:	8b 04 85 a0 08 11 80 	mov    -0x7feef760(,%eax,4),%eax
80102c79:	8d 50 01             	lea    0x1(%eax),%edx
80102c7c:	8b 45 08             	mov    0x8(%ebp),%eax
80102c7f:	05 00 04 00 00       	add    $0x400,%eax
80102c84:	89 14 85 a0 08 11 80 	mov    %edx,-0x7feef760(,%eax,4)
      }
      break;
80102c8b:	90                   	nop
  }
  if(kmem.use_lock)
80102c8c:	a1 94 08 11 80       	mov    0x80110894,%eax
80102c91:	85 c0                	test   %eax,%eax
80102c93:	74 0c                	je     80102ca1 <shmget+0x151>
    release(&kmem.lock);
80102c95:	c7 04 24 60 08 11 80 	movl   $0x80110860,(%esp)
80102c9c:	e8 05 29 00 00       	call   801055a6 <release>
  
  return ans;
80102ca1:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80102ca4:	c9                   	leave  
80102ca5:	c3                   	ret    

80102ca6 <shmdel>:

int shmdel(int shmid)
{
80102ca6:	55                   	push   %ebp
80102ca7:	89 e5                	mov    %esp,%ebp
80102ca9:	83 ec 38             	sub    $0x38,%esp
  int key,ans,numOfPages;
  struct run* r;
  if(kmem.use_lock)
80102cac:	a1 94 08 11 80       	mov    0x80110894,%eax
80102cb1:	85 c0                	test   %eax,%eax
80102cb3:	74 0c                	je     80102cc1 <shmdel+0x1b>
    acquire(&kmem.lock);
80102cb5:	c7 04 24 60 08 11 80 	movl   $0x80110860,(%esp)
80102cbc:	e8 4a 28 00 00       	call   8010550b <acquire>
  struct run* ptr;
  for(key = 0,ptr = shm.seg[0];ptr<shm.seg[1024];ptr += sizeof(struct run*),key++)
80102cc1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102cc8:	a1 a0 08 11 80       	mov    0x801108a0,%eax
80102ccd:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80102cd0:	e9 98 00 00 00       	jmp    80102d6d <shmdel+0xc7>
    if(shmid == (int)ptr)
80102cd5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102cd8:	3b 45 08             	cmp    0x8(%ebp),%eax
80102cdb:	0f 85 84 00 00 00    	jne    80102d65 <shmdel+0xbf>
    {
      if(shm.refs[key])
80102ce1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102ce4:	05 00 04 00 00       	add    $0x400,%eax
80102ce9:	8b 04 85 a0 08 11 80 	mov    -0x7feef760(,%eax,4),%eax
80102cf0:	85 c0                	test   %eax,%eax
80102cf2:	74 09                	je     80102cfd <shmdel+0x57>
	ans = -1;
80102cf4:	c7 45 f0 ff ff ff ff 	movl   $0xffffffff,-0x10(%ebp)
	  memset(r, 1, PGSIZE);
	r->next = kmem.freelist;
	kmem.freelist = shm.seg[key];
	ans = numOfPages;
      }
      break;
80102cfb:	eb 7e                	jmp    80102d7b <shmdel+0xd5>
    {
      if(shm.refs[key])
	ans = -1;
      else
      {
	for(r = shm.seg[key],numOfPages=0;r->next;r = r->next,numOfPages++)
80102cfd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d00:	8b 04 85 a0 08 11 80 	mov    -0x7feef760(,%eax,4),%eax
80102d07:	89 45 e8             	mov    %eax,-0x18(%ebp)
80102d0a:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80102d11:	eb 27                	jmp    80102d3a <shmdel+0x94>
	  // Fill with junk to catch dangling refs.
	  memset(r, 1, PGSIZE);
80102d13:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80102d1a:	00 
80102d1b:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102d22:	00 
80102d23:	8b 45 e8             	mov    -0x18(%ebp),%eax
80102d26:	89 04 24             	mov    %eax,(%esp)
80102d29:	e8 64 2a 00 00       	call   80105792 <memset>
    {
      if(shm.refs[key])
	ans = -1;
      else
      {
	for(r = shm.seg[key],numOfPages=0;r->next;r = r->next,numOfPages++)
80102d2e:	8b 45 e8             	mov    -0x18(%ebp),%eax
80102d31:	8b 00                	mov    (%eax),%eax
80102d33:	89 45 e8             	mov    %eax,-0x18(%ebp)
80102d36:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
80102d3a:	8b 45 e8             	mov    -0x18(%ebp),%eax
80102d3d:	8b 00                	mov    (%eax),%eax
80102d3f:	85 c0                	test   %eax,%eax
80102d41:	75 d0                	jne    80102d13 <shmdel+0x6d>
	  // Fill with junk to catch dangling refs.
	  memset(r, 1, PGSIZE);
	r->next = kmem.freelist;
80102d43:	8b 15 98 08 11 80    	mov    0x80110898,%edx
80102d49:	8b 45 e8             	mov    -0x18(%ebp),%eax
80102d4c:	89 10                	mov    %edx,(%eax)
	kmem.freelist = shm.seg[key];
80102d4e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d51:	8b 04 85 a0 08 11 80 	mov    -0x7feef760(,%eax,4),%eax
80102d58:	a3 98 08 11 80       	mov    %eax,0x80110898
	ans = numOfPages;
80102d5d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102d60:	89 45 f0             	mov    %eax,-0x10(%ebp)
      }
      break;
80102d63:	eb 16                	jmp    80102d7b <shmdel+0xd5>
  int key,ans,numOfPages;
  struct run* r;
  if(kmem.use_lock)
    acquire(&kmem.lock);
  struct run* ptr;
  for(key = 0,ptr = shm.seg[0];ptr<shm.seg[1024];ptr += sizeof(struct run*),key++)
80102d65:	83 45 e4 10          	addl   $0x10,-0x1c(%ebp)
80102d69:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102d6d:	a1 a0 18 11 80       	mov    0x801118a0,%eax
80102d72:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
80102d75:	0f 87 5a ff ff ff    	ja     80102cd5 <shmdel+0x2f>
	ans = numOfPages;
      }
      break;
    }
  
  if(kmem.use_lock)
80102d7b:	a1 94 08 11 80       	mov    0x80110894,%eax
80102d80:	85 c0                	test   %eax,%eax
80102d82:	74 0c                	je     80102d90 <shmdel+0xea>
    release(&kmem.lock);
80102d84:	c7 04 24 60 08 11 80 	movl   $0x80110860,(%esp)
80102d8b:	e8 16 28 00 00       	call   801055a6 <release>
  
  return ans;
80102d90:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80102d93:	c9                   	leave  
80102d94:	c3                   	ret    
80102d95:	00 00                	add    %al,(%eax)
	...

80102d98 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102d98:	55                   	push   %ebp
80102d99:	89 e5                	mov    %esp,%ebp
80102d9b:	53                   	push   %ebx
80102d9c:	83 ec 14             	sub    $0x14,%esp
80102d9f:	8b 45 08             	mov    0x8(%ebp),%eax
80102da2:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102da6:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80102daa:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80102dae:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80102db2:	ec                   	in     (%dx),%al
80102db3:	89 c3                	mov    %eax,%ebx
80102db5:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80102db8:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80102dbc:	83 c4 14             	add    $0x14,%esp
80102dbf:	5b                   	pop    %ebx
80102dc0:	5d                   	pop    %ebp
80102dc1:	c3                   	ret    

80102dc2 <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
80102dc2:	55                   	push   %ebp
80102dc3:	89 e5                	mov    %esp,%ebp
80102dc5:	83 ec 14             	sub    $0x14,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
80102dc8:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80102dcf:	e8 c4 ff ff ff       	call   80102d98 <inb>
80102dd4:	0f b6 c0             	movzbl %al,%eax
80102dd7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
80102dda:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102ddd:	83 e0 01             	and    $0x1,%eax
80102de0:	85 c0                	test   %eax,%eax
80102de2:	75 0a                	jne    80102dee <kbdgetc+0x2c>
    return -1;
80102de4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102de9:	e9 23 01 00 00       	jmp    80102f11 <kbdgetc+0x14f>
  data = inb(KBDATAP);
80102dee:	c7 04 24 60 00 00 00 	movl   $0x60,(%esp)
80102df5:	e8 9e ff ff ff       	call   80102d98 <inb>
80102dfa:	0f b6 c0             	movzbl %al,%eax
80102dfd:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
80102e00:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
80102e07:	75 17                	jne    80102e20 <kbdgetc+0x5e>
    shift |= E0ESC;
80102e09:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80102e0e:	83 c8 40             	or     $0x40,%eax
80102e11:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
    return 0;
80102e16:	b8 00 00 00 00       	mov    $0x0,%eax
80102e1b:	e9 f1 00 00 00       	jmp    80102f11 <kbdgetc+0x14f>
  } else if(data & 0x80){
80102e20:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102e23:	25 80 00 00 00       	and    $0x80,%eax
80102e28:	85 c0                	test   %eax,%eax
80102e2a:	74 45                	je     80102e71 <kbdgetc+0xaf>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
80102e2c:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80102e31:	83 e0 40             	and    $0x40,%eax
80102e34:	85 c0                	test   %eax,%eax
80102e36:	75 08                	jne    80102e40 <kbdgetc+0x7e>
80102e38:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102e3b:	83 e0 7f             	and    $0x7f,%eax
80102e3e:	eb 03                	jmp    80102e43 <kbdgetc+0x81>
80102e40:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102e43:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
80102e46:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102e49:	05 20 a0 10 80       	add    $0x8010a020,%eax
80102e4e:	0f b6 00             	movzbl (%eax),%eax
80102e51:	83 c8 40             	or     $0x40,%eax
80102e54:	0f b6 c0             	movzbl %al,%eax
80102e57:	f7 d0                	not    %eax
80102e59:	89 c2                	mov    %eax,%edx
80102e5b:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80102e60:	21 d0                	and    %edx,%eax
80102e62:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
    return 0;
80102e67:	b8 00 00 00 00       	mov    $0x0,%eax
80102e6c:	e9 a0 00 00 00       	jmp    80102f11 <kbdgetc+0x14f>
  } else if(shift & E0ESC){
80102e71:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80102e76:	83 e0 40             	and    $0x40,%eax
80102e79:	85 c0                	test   %eax,%eax
80102e7b:	74 14                	je     80102e91 <kbdgetc+0xcf>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80102e7d:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
80102e84:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80102e89:	83 e0 bf             	and    $0xffffffbf,%eax
80102e8c:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
  }

  shift |= shiftcode[data];
80102e91:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102e94:	05 20 a0 10 80       	add    $0x8010a020,%eax
80102e99:	0f b6 00             	movzbl (%eax),%eax
80102e9c:	0f b6 d0             	movzbl %al,%edx
80102e9f:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80102ea4:	09 d0                	or     %edx,%eax
80102ea6:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
  shift ^= togglecode[data];
80102eab:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102eae:	05 20 a1 10 80       	add    $0x8010a120,%eax
80102eb3:	0f b6 00             	movzbl (%eax),%eax
80102eb6:	0f b6 d0             	movzbl %al,%edx
80102eb9:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80102ebe:	31 d0                	xor    %edx,%eax
80102ec0:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
  c = charcode[shift & (CTL | SHIFT)][data];
80102ec5:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80102eca:	83 e0 03             	and    $0x3,%eax
80102ecd:	8b 04 85 20 a5 10 80 	mov    -0x7fef5ae0(,%eax,4),%eax
80102ed4:	03 45 fc             	add    -0x4(%ebp),%eax
80102ed7:	0f b6 00             	movzbl (%eax),%eax
80102eda:	0f b6 c0             	movzbl %al,%eax
80102edd:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
80102ee0:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80102ee5:	83 e0 08             	and    $0x8,%eax
80102ee8:	85 c0                	test   %eax,%eax
80102eea:	74 22                	je     80102f0e <kbdgetc+0x14c>
    if('a' <= c && c <= 'z')
80102eec:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
80102ef0:	76 0c                	jbe    80102efe <kbdgetc+0x13c>
80102ef2:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
80102ef6:	77 06                	ja     80102efe <kbdgetc+0x13c>
      c += 'A' - 'a';
80102ef8:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
80102efc:	eb 10                	jmp    80102f0e <kbdgetc+0x14c>
    else if('A' <= c && c <= 'Z')
80102efe:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
80102f02:	76 0a                	jbe    80102f0e <kbdgetc+0x14c>
80102f04:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
80102f08:	77 04                	ja     80102f0e <kbdgetc+0x14c>
      c += 'a' - 'A';
80102f0a:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
80102f0e:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80102f11:	c9                   	leave  
80102f12:	c3                   	ret    

80102f13 <kbdintr>:

void
kbdintr(void)
{
80102f13:	55                   	push   %ebp
80102f14:	89 e5                	mov    %esp,%ebp
80102f16:	83 ec 18             	sub    $0x18,%esp
  consoleintr(kbdgetc);
80102f19:	c7 04 24 c2 2d 10 80 	movl   $0x80102dc2,(%esp)
80102f20:	e8 88 d8 ff ff       	call   801007ad <consoleintr>
}
80102f25:	c9                   	leave  
80102f26:	c3                   	ret    
	...

80102f28 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80102f28:	55                   	push   %ebp
80102f29:	89 e5                	mov    %esp,%ebp
80102f2b:	83 ec 08             	sub    $0x8,%esp
80102f2e:	8b 55 08             	mov    0x8(%ebp),%edx
80102f31:	8b 45 0c             	mov    0xc(%ebp),%eax
80102f34:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80102f38:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102f3b:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80102f3f:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80102f43:	ee                   	out    %al,(%dx)
}
80102f44:	c9                   	leave  
80102f45:	c3                   	ret    

80102f46 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80102f46:	55                   	push   %ebp
80102f47:	89 e5                	mov    %esp,%ebp
80102f49:	53                   	push   %ebx
80102f4a:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80102f4d:	9c                   	pushf  
80102f4e:	5b                   	pop    %ebx
80102f4f:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80102f52:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80102f55:	83 c4 10             	add    $0x10,%esp
80102f58:	5b                   	pop    %ebx
80102f59:	5d                   	pop    %ebp
80102f5a:	c3                   	ret    

80102f5b <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
80102f5b:	55                   	push   %ebp
80102f5c:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
80102f5e:	a1 d4 28 11 80       	mov    0x801128d4,%eax
80102f63:	8b 55 08             	mov    0x8(%ebp),%edx
80102f66:	c1 e2 02             	shl    $0x2,%edx
80102f69:	01 c2                	add    %eax,%edx
80102f6b:	8b 45 0c             	mov    0xc(%ebp),%eax
80102f6e:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
80102f70:	a1 d4 28 11 80       	mov    0x801128d4,%eax
80102f75:	83 c0 20             	add    $0x20,%eax
80102f78:	8b 00                	mov    (%eax),%eax
}
80102f7a:	5d                   	pop    %ebp
80102f7b:	c3                   	ret    

80102f7c <lapicinit>:
//PAGEBREAK!

void
lapicinit(int c)
{
80102f7c:	55                   	push   %ebp
80102f7d:	89 e5                	mov    %esp,%ebp
80102f7f:	83 ec 08             	sub    $0x8,%esp
  if(!lapic) 
80102f82:	a1 d4 28 11 80       	mov    0x801128d4,%eax
80102f87:	85 c0                	test   %eax,%eax
80102f89:	0f 84 47 01 00 00    	je     801030d6 <lapicinit+0x15a>
    return;

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
80102f8f:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
80102f96:	00 
80102f97:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
80102f9e:	e8 b8 ff ff ff       	call   80102f5b <lapicw>

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.  
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
80102fa3:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
80102faa:	00 
80102fab:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
80102fb2:	e8 a4 ff ff ff       	call   80102f5b <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
80102fb7:	c7 44 24 04 20 00 02 	movl   $0x20020,0x4(%esp)
80102fbe:	00 
80102fbf:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80102fc6:	e8 90 ff ff ff       	call   80102f5b <lapicw>
  lapicw(TICR, 10000000); 
80102fcb:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
80102fd2:	00 
80102fd3:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
80102fda:	e8 7c ff ff ff       	call   80102f5b <lapicw>

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
80102fdf:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102fe6:	00 
80102fe7:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
80102fee:	e8 68 ff ff ff       	call   80102f5b <lapicw>
  lapicw(LINT1, MASKED);
80102ff3:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102ffa:	00 
80102ffb:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
80103002:	e8 54 ff ff ff       	call   80102f5b <lapicw>

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
80103007:	a1 d4 28 11 80       	mov    0x801128d4,%eax
8010300c:	83 c0 30             	add    $0x30,%eax
8010300f:	8b 00                	mov    (%eax),%eax
80103011:	c1 e8 10             	shr    $0x10,%eax
80103014:	25 ff 00 00 00       	and    $0xff,%eax
80103019:	83 f8 03             	cmp    $0x3,%eax
8010301c:	76 14                	jbe    80103032 <lapicinit+0xb6>
    lapicw(PCINT, MASKED);
8010301e:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103025:	00 
80103026:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
8010302d:	e8 29 ff ff ff       	call   80102f5b <lapicw>

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
80103032:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
80103039:	00 
8010303a:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
80103041:	e8 15 ff ff ff       	call   80102f5b <lapicw>

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
80103046:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010304d:	00 
8010304e:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103055:	e8 01 ff ff ff       	call   80102f5b <lapicw>
  lapicw(ESR, 0);
8010305a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103061:	00 
80103062:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103069:	e8 ed fe ff ff       	call   80102f5b <lapicw>

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
8010306e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103075:	00 
80103076:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
8010307d:	e8 d9 fe ff ff       	call   80102f5b <lapicw>

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
80103082:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103089:	00 
8010308a:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80103091:	e8 c5 fe ff ff       	call   80102f5b <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
80103096:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
8010309d:	00 
8010309e:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801030a5:	e8 b1 fe ff ff       	call   80102f5b <lapicw>
  while(lapic[ICRLO] & DELIVS)
801030aa:	90                   	nop
801030ab:	a1 d4 28 11 80       	mov    0x801128d4,%eax
801030b0:	05 00 03 00 00       	add    $0x300,%eax
801030b5:	8b 00                	mov    (%eax),%eax
801030b7:	25 00 10 00 00       	and    $0x1000,%eax
801030bc:	85 c0                	test   %eax,%eax
801030be:	75 eb                	jne    801030ab <lapicinit+0x12f>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
801030c0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801030c7:	00 
801030c8:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
801030cf:	e8 87 fe ff ff       	call   80102f5b <lapicw>
801030d4:	eb 01                	jmp    801030d7 <lapicinit+0x15b>

void
lapicinit(int c)
{
  if(!lapic) 
    return;
801030d6:	90                   	nop
  while(lapic[ICRLO] & DELIVS)
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
}
801030d7:	c9                   	leave  
801030d8:	c3                   	ret    

801030d9 <cpunum>:

int
cpunum(void)
{
801030d9:	55                   	push   %ebp
801030da:	89 e5                	mov    %esp,%ebp
801030dc:	83 ec 18             	sub    $0x18,%esp
  // Cannot call cpu when interrupts are enabled:
  // result not guaranteed to last long enough to be used!
  // Would prefer to panic but even printing is chancy here:
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
801030df:	e8 62 fe ff ff       	call   80102f46 <readeflags>
801030e4:	25 00 02 00 00       	and    $0x200,%eax
801030e9:	85 c0                	test   %eax,%eax
801030eb:	74 29                	je     80103116 <cpunum+0x3d>
    static int n;
    if(n++ == 0)
801030ed:	a1 60 c6 10 80       	mov    0x8010c660,%eax
801030f2:	85 c0                	test   %eax,%eax
801030f4:	0f 94 c2             	sete   %dl
801030f7:	83 c0 01             	add    $0x1,%eax
801030fa:	a3 60 c6 10 80       	mov    %eax,0x8010c660
801030ff:	84 d2                	test   %dl,%dl
80103101:	74 13                	je     80103116 <cpunum+0x3d>
      cprintf("cpu called from %x with interrupts enabled\n",
80103103:	8b 45 04             	mov    0x4(%ebp),%eax
80103106:	89 44 24 04          	mov    %eax,0x4(%esp)
8010310a:	c7 04 24 94 91 10 80 	movl   $0x80109194,(%esp)
80103111:	e8 8b d2 ff ff       	call   801003a1 <cprintf>
        __builtin_return_address(0));
  }

  if(lapic)
80103116:	a1 d4 28 11 80       	mov    0x801128d4,%eax
8010311b:	85 c0                	test   %eax,%eax
8010311d:	74 0f                	je     8010312e <cpunum+0x55>
    return lapic[ID]>>24;
8010311f:	a1 d4 28 11 80       	mov    0x801128d4,%eax
80103124:	83 c0 20             	add    $0x20,%eax
80103127:	8b 00                	mov    (%eax),%eax
80103129:	c1 e8 18             	shr    $0x18,%eax
8010312c:	eb 05                	jmp    80103133 <cpunum+0x5a>
  return 0;
8010312e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103133:	c9                   	leave  
80103134:	c3                   	ret    

80103135 <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
80103135:	55                   	push   %ebp
80103136:	89 e5                	mov    %esp,%ebp
80103138:	83 ec 08             	sub    $0x8,%esp
  if(lapic)
8010313b:	a1 d4 28 11 80       	mov    0x801128d4,%eax
80103140:	85 c0                	test   %eax,%eax
80103142:	74 14                	je     80103158 <lapiceoi+0x23>
    lapicw(EOI, 0);
80103144:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010314b:	00 
8010314c:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80103153:	e8 03 fe ff ff       	call   80102f5b <lapicw>
}
80103158:	c9                   	leave  
80103159:	c3                   	ret    

8010315a <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
8010315a:	55                   	push   %ebp
8010315b:	89 e5                	mov    %esp,%ebp
}
8010315d:	5d                   	pop    %ebp
8010315e:	c3                   	ret    

8010315f <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
8010315f:	55                   	push   %ebp
80103160:	89 e5                	mov    %esp,%ebp
80103162:	83 ec 1c             	sub    $0x1c,%esp
80103165:	8b 45 08             	mov    0x8(%ebp),%eax
80103168:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;
  
  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
8010316b:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80103172:	00 
80103173:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
8010317a:	e8 a9 fd ff ff       	call   80102f28 <outb>
  outb(IO_RTC+1, 0x0A);
8010317f:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80103186:	00 
80103187:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
8010318e:	e8 95 fd ff ff       	call   80102f28 <outb>
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
80103193:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
8010319a:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010319d:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
801031a2:	8b 45 f8             	mov    -0x8(%ebp),%eax
801031a5:	8d 50 02             	lea    0x2(%eax),%edx
801031a8:	8b 45 0c             	mov    0xc(%ebp),%eax
801031ab:	c1 e8 04             	shr    $0x4,%eax
801031ae:	66 89 02             	mov    %ax,(%edx)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
801031b1:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
801031b5:	c1 e0 18             	shl    $0x18,%eax
801031b8:	89 44 24 04          	mov    %eax,0x4(%esp)
801031bc:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
801031c3:	e8 93 fd ff ff       	call   80102f5b <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
801031c8:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
801031cf:	00 
801031d0:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801031d7:	e8 7f fd ff ff       	call   80102f5b <lapicw>
  microdelay(200);
801031dc:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
801031e3:	e8 72 ff ff ff       	call   8010315a <microdelay>
  lapicw(ICRLO, INIT | LEVEL);
801031e8:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
801031ef:	00 
801031f0:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801031f7:	e8 5f fd ff ff       	call   80102f5b <lapicw>
  microdelay(100);    // should be 10ms, but too slow in Bochs!
801031fc:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80103203:	e8 52 ff ff ff       	call   8010315a <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80103208:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
8010320f:	eb 40                	jmp    80103251 <lapicstartap+0xf2>
    lapicw(ICRHI, apicid<<24);
80103211:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80103215:	c1 e0 18             	shl    $0x18,%eax
80103218:	89 44 24 04          	mov    %eax,0x4(%esp)
8010321c:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80103223:	e8 33 fd ff ff       	call   80102f5b <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
80103228:	8b 45 0c             	mov    0xc(%ebp),%eax
8010322b:	c1 e8 0c             	shr    $0xc,%eax
8010322e:	80 cc 06             	or     $0x6,%ah
80103231:	89 44 24 04          	mov    %eax,0x4(%esp)
80103235:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
8010323c:	e8 1a fd ff ff       	call   80102f5b <lapicw>
    microdelay(200);
80103241:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103248:	e8 0d ff ff ff       	call   8010315a <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
8010324d:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103251:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
80103255:	7e ba                	jle    80103211 <lapicstartap+0xb2>
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
80103257:	c9                   	leave  
80103258:	c3                   	ret    
80103259:	00 00                	add    %al,(%eax)
	...

8010325c <initlog>:

static void recover_from_log(void);

void
initlog(void)
{
8010325c:	55                   	push   %ebp
8010325d:	89 e5                	mov    %esp,%ebp
8010325f:	83 ec 28             	sub    $0x28,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
80103262:	c7 44 24 04 c0 91 10 	movl   $0x801091c0,0x4(%esp)
80103269:	80 
8010326a:	c7 04 24 e0 28 11 80 	movl   $0x801128e0,(%esp)
80103271:	e8 74 22 00 00       	call   801054ea <initlock>
  readsb(ROOTDEV, &sb);
80103276:	8d 45 e8             	lea    -0x18(%ebp),%eax
80103279:	89 44 24 04          	mov    %eax,0x4(%esp)
8010327d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103284:	e8 63 e0 ff ff       	call   801012ec <readsb>
  log.start = sb.size - sb.nlog;
80103289:	8b 55 e8             	mov    -0x18(%ebp),%edx
8010328c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010328f:	89 d1                	mov    %edx,%ecx
80103291:	29 c1                	sub    %eax,%ecx
80103293:	89 c8                	mov    %ecx,%eax
80103295:	a3 14 29 11 80       	mov    %eax,0x80112914
  log.size = sb.nlog;
8010329a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010329d:	a3 18 29 11 80       	mov    %eax,0x80112918
  log.dev = ROOTDEV;
801032a2:	c7 05 20 29 11 80 01 	movl   $0x1,0x80112920
801032a9:	00 00 00 
  recover_from_log();
801032ac:	e8 97 01 00 00       	call   80103448 <recover_from_log>
}
801032b1:	c9                   	leave  
801032b2:	c3                   	ret    

801032b3 <install_trans>:

// Copy committed blocks from log to their home location
static void 
install_trans(void)
{
801032b3:	55                   	push   %ebp
801032b4:	89 e5                	mov    %esp,%ebp
801032b6:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801032b9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801032c0:	e9 89 00 00 00       	jmp    8010334e <install_trans+0x9b>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
801032c5:	a1 14 29 11 80       	mov    0x80112914,%eax
801032ca:	03 45 f4             	add    -0xc(%ebp),%eax
801032cd:	83 c0 01             	add    $0x1,%eax
801032d0:	89 c2                	mov    %eax,%edx
801032d2:	a1 20 29 11 80       	mov    0x80112920,%eax
801032d7:	89 54 24 04          	mov    %edx,0x4(%esp)
801032db:	89 04 24             	mov    %eax,(%esp)
801032de:	e8 c3 ce ff ff       	call   801001a6 <bread>
801032e3:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.sector[tail]); // read dst
801032e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032e9:	83 c0 10             	add    $0x10,%eax
801032ec:	8b 04 85 e8 28 11 80 	mov    -0x7feed718(,%eax,4),%eax
801032f3:	89 c2                	mov    %eax,%edx
801032f5:	a1 20 29 11 80       	mov    0x80112920,%eax
801032fa:	89 54 24 04          	mov    %edx,0x4(%esp)
801032fe:	89 04 24             	mov    %eax,(%esp)
80103301:	e8 a0 ce ff ff       	call   801001a6 <bread>
80103306:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
80103309:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010330c:	8d 50 18             	lea    0x18(%eax),%edx
8010330f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103312:	83 c0 18             	add    $0x18,%eax
80103315:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
8010331c:	00 
8010331d:	89 54 24 04          	mov    %edx,0x4(%esp)
80103321:	89 04 24             	mov    %eax,(%esp)
80103324:	e8 3c 25 00 00       	call   80105865 <memmove>
    bwrite(dbuf);  // write dst to disk
80103329:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010332c:	89 04 24             	mov    %eax,(%esp)
8010332f:	e8 a9 ce ff ff       	call   801001dd <bwrite>
    brelse(lbuf); 
80103334:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103337:	89 04 24             	mov    %eax,(%esp)
8010333a:	e8 d8 ce ff ff       	call   80100217 <brelse>
    brelse(dbuf);
8010333f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103342:	89 04 24             	mov    %eax,(%esp)
80103345:	e8 cd ce ff ff       	call   80100217 <brelse>
static void 
install_trans(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
8010334a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010334e:	a1 24 29 11 80       	mov    0x80112924,%eax
80103353:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103356:	0f 8f 69 ff ff ff    	jg     801032c5 <install_trans+0x12>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    bwrite(dbuf);  // write dst to disk
    brelse(lbuf); 
    brelse(dbuf);
  }
}
8010335c:	c9                   	leave  
8010335d:	c3                   	ret    

8010335e <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
8010335e:	55                   	push   %ebp
8010335f:	89 e5                	mov    %esp,%ebp
80103361:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80103364:	a1 14 29 11 80       	mov    0x80112914,%eax
80103369:	89 c2                	mov    %eax,%edx
8010336b:	a1 20 29 11 80       	mov    0x80112920,%eax
80103370:	89 54 24 04          	mov    %edx,0x4(%esp)
80103374:	89 04 24             	mov    %eax,(%esp)
80103377:	e8 2a ce ff ff       	call   801001a6 <bread>
8010337c:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
8010337f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103382:	83 c0 18             	add    $0x18,%eax
80103385:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
80103388:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010338b:	8b 00                	mov    (%eax),%eax
8010338d:	a3 24 29 11 80       	mov    %eax,0x80112924
  for (i = 0; i < log.lh.n; i++) {
80103392:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103399:	eb 1b                	jmp    801033b6 <read_head+0x58>
    log.lh.sector[i] = lh->sector[i];
8010339b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010339e:	8b 55 f4             	mov    -0xc(%ebp),%edx
801033a1:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
801033a5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801033a8:	83 c2 10             	add    $0x10,%edx
801033ab:	89 04 95 e8 28 11 80 	mov    %eax,-0x7feed718(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
801033b2:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801033b6:	a1 24 29 11 80       	mov    0x80112924,%eax
801033bb:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801033be:	7f db                	jg     8010339b <read_head+0x3d>
    log.lh.sector[i] = lh->sector[i];
  }
  brelse(buf);
801033c0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801033c3:	89 04 24             	mov    %eax,(%esp)
801033c6:	e8 4c ce ff ff       	call   80100217 <brelse>
}
801033cb:	c9                   	leave  
801033cc:	c3                   	ret    

801033cd <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
801033cd:	55                   	push   %ebp
801033ce:	89 e5                	mov    %esp,%ebp
801033d0:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
801033d3:	a1 14 29 11 80       	mov    0x80112914,%eax
801033d8:	89 c2                	mov    %eax,%edx
801033da:	a1 20 29 11 80       	mov    0x80112920,%eax
801033df:	89 54 24 04          	mov    %edx,0x4(%esp)
801033e3:	89 04 24             	mov    %eax,(%esp)
801033e6:	e8 bb cd ff ff       	call   801001a6 <bread>
801033eb:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
801033ee:	8b 45 f0             	mov    -0x10(%ebp),%eax
801033f1:	83 c0 18             	add    $0x18,%eax
801033f4:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
801033f7:	8b 15 24 29 11 80    	mov    0x80112924,%edx
801033fd:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103400:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
80103402:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103409:	eb 1b                	jmp    80103426 <write_head+0x59>
    hb->sector[i] = log.lh.sector[i];
8010340b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010340e:	83 c0 10             	add    $0x10,%eax
80103411:	8b 0c 85 e8 28 11 80 	mov    -0x7feed718(,%eax,4),%ecx
80103418:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010341b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010341e:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
80103422:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103426:	a1 24 29 11 80       	mov    0x80112924,%eax
8010342b:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010342e:	7f db                	jg     8010340b <write_head+0x3e>
    hb->sector[i] = log.lh.sector[i];
  }
  bwrite(buf);
80103430:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103433:	89 04 24             	mov    %eax,(%esp)
80103436:	e8 a2 cd ff ff       	call   801001dd <bwrite>
  brelse(buf);
8010343b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010343e:	89 04 24             	mov    %eax,(%esp)
80103441:	e8 d1 cd ff ff       	call   80100217 <brelse>
}
80103446:	c9                   	leave  
80103447:	c3                   	ret    

80103448 <recover_from_log>:

static void
recover_from_log(void)
{
80103448:	55                   	push   %ebp
80103449:	89 e5                	mov    %esp,%ebp
8010344b:	83 ec 08             	sub    $0x8,%esp
  read_head();      
8010344e:	e8 0b ff ff ff       	call   8010335e <read_head>
  install_trans(); // if committed, copy from log to disk
80103453:	e8 5b fe ff ff       	call   801032b3 <install_trans>
  log.lh.n = 0;
80103458:	c7 05 24 29 11 80 00 	movl   $0x0,0x80112924
8010345f:	00 00 00 
  write_head(); // clear the log
80103462:	e8 66 ff ff ff       	call   801033cd <write_head>
}
80103467:	c9                   	leave  
80103468:	c3                   	ret    

80103469 <begin_trans>:

void
begin_trans(void)
{
80103469:	55                   	push   %ebp
8010346a:	89 e5                	mov    %esp,%ebp
8010346c:	83 ec 18             	sub    $0x18,%esp
  acquire(&log.lock);
8010346f:	c7 04 24 e0 28 11 80 	movl   $0x801128e0,(%esp)
80103476:	e8 90 20 00 00       	call   8010550b <acquire>
  while (log.busy) {
8010347b:	eb 14                	jmp    80103491 <begin_trans+0x28>
  sleep(&log, &log.lock);
8010347d:	c7 44 24 04 e0 28 11 	movl   $0x801128e0,0x4(%esp)
80103484:	80 
80103485:	c7 04 24 e0 28 11 80 	movl   $0x801128e0,(%esp)
8010348c:	e8 3e 1c 00 00       	call   801050cf <sleep>

void
begin_trans(void)
{
  acquire(&log.lock);
  while (log.busy) {
80103491:	a1 1c 29 11 80       	mov    0x8011291c,%eax
80103496:	85 c0                	test   %eax,%eax
80103498:	75 e3                	jne    8010347d <begin_trans+0x14>
  sleep(&log, &log.lock);
  }
  log.busy = 1;
8010349a:	c7 05 1c 29 11 80 01 	movl   $0x1,0x8011291c
801034a1:	00 00 00 
  release(&log.lock);
801034a4:	c7 04 24 e0 28 11 80 	movl   $0x801128e0,(%esp)
801034ab:	e8 f6 20 00 00       	call   801055a6 <release>
}
801034b0:	c9                   	leave  
801034b1:	c3                   	ret    

801034b2 <commit_trans>:

void
commit_trans(void)
{
801034b2:	55                   	push   %ebp
801034b3:	89 e5                	mov    %esp,%ebp
801034b5:	83 ec 18             	sub    $0x18,%esp
  if (log.lh.n > 0) {
801034b8:	a1 24 29 11 80       	mov    0x80112924,%eax
801034bd:	85 c0                	test   %eax,%eax
801034bf:	7e 19                	jle    801034da <commit_trans+0x28>
    write_head();    // Write header to disk -- the real commit
801034c1:	e8 07 ff ff ff       	call   801033cd <write_head>
    install_trans(); // Now install writes to home locations
801034c6:	e8 e8 fd ff ff       	call   801032b3 <install_trans>
    log.lh.n = 0; 
801034cb:	c7 05 24 29 11 80 00 	movl   $0x0,0x80112924
801034d2:	00 00 00 
    write_head();    // Erase the transaction from the log
801034d5:	e8 f3 fe ff ff       	call   801033cd <write_head>
  }
  
  acquire(&log.lock);
801034da:	c7 04 24 e0 28 11 80 	movl   $0x801128e0,(%esp)
801034e1:	e8 25 20 00 00       	call   8010550b <acquire>
  log.busy = 0;
801034e6:	c7 05 1c 29 11 80 00 	movl   $0x0,0x8011291c
801034ed:	00 00 00 
  wakeup(&log);
801034f0:	c7 04 24 e0 28 11 80 	movl   $0x801128e0,(%esp)
801034f7:	e8 0f 1d 00 00       	call   8010520b <wakeup>
  release(&log.lock);
801034fc:	c7 04 24 e0 28 11 80 	movl   $0x801128e0,(%esp)
80103503:	e8 9e 20 00 00       	call   801055a6 <release>
}
80103508:	c9                   	leave  
80103509:	c3                   	ret    

8010350a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
8010350a:	55                   	push   %ebp
8010350b:	89 e5                	mov    %esp,%ebp
8010350d:	83 ec 28             	sub    $0x28,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80103510:	a1 24 29 11 80       	mov    0x80112924,%eax
80103515:	83 f8 09             	cmp    $0x9,%eax
80103518:	7f 12                	jg     8010352c <log_write+0x22>
8010351a:	a1 24 29 11 80       	mov    0x80112924,%eax
8010351f:	8b 15 18 29 11 80    	mov    0x80112918,%edx
80103525:	83 ea 01             	sub    $0x1,%edx
80103528:	39 d0                	cmp    %edx,%eax
8010352a:	7c 0c                	jl     80103538 <log_write+0x2e>
    panic("too big a transaction");
8010352c:	c7 04 24 c4 91 10 80 	movl   $0x801091c4,(%esp)
80103533:	e8 05 d0 ff ff       	call   8010053d <panic>
  if (!log.busy)
80103538:	a1 1c 29 11 80       	mov    0x8011291c,%eax
8010353d:	85 c0                	test   %eax,%eax
8010353f:	75 0c                	jne    8010354d <log_write+0x43>
    panic("write outside of trans");
80103541:	c7 04 24 da 91 10 80 	movl   $0x801091da,(%esp)
80103548:	e8 f0 cf ff ff       	call   8010053d <panic>

  for (i = 0; i < log.lh.n; i++) {
8010354d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103554:	eb 1d                	jmp    80103573 <log_write+0x69>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
80103556:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103559:	83 c0 10             	add    $0x10,%eax
8010355c:	8b 04 85 e8 28 11 80 	mov    -0x7feed718(,%eax,4),%eax
80103563:	89 c2                	mov    %eax,%edx
80103565:	8b 45 08             	mov    0x8(%ebp),%eax
80103568:	8b 40 08             	mov    0x8(%eax),%eax
8010356b:	39 c2                	cmp    %eax,%edx
8010356d:	74 10                	je     8010357f <log_write+0x75>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    panic("too big a transaction");
  if (!log.busy)
    panic("write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
8010356f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103573:	a1 24 29 11 80       	mov    0x80112924,%eax
80103578:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010357b:	7f d9                	jg     80103556 <log_write+0x4c>
8010357d:	eb 01                	jmp    80103580 <log_write+0x76>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
      break;
8010357f:	90                   	nop
  }
  log.lh.sector[i] = b->sector;
80103580:	8b 45 08             	mov    0x8(%ebp),%eax
80103583:	8b 40 08             	mov    0x8(%eax),%eax
80103586:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103589:	83 c2 10             	add    $0x10,%edx
8010358c:	89 04 95 e8 28 11 80 	mov    %eax,-0x7feed718(,%edx,4)
  struct buf *lbuf = bread(b->dev, log.start+i+1);
80103593:	a1 14 29 11 80       	mov    0x80112914,%eax
80103598:	03 45 f4             	add    -0xc(%ebp),%eax
8010359b:	83 c0 01             	add    $0x1,%eax
8010359e:	89 c2                	mov    %eax,%edx
801035a0:	8b 45 08             	mov    0x8(%ebp),%eax
801035a3:	8b 40 04             	mov    0x4(%eax),%eax
801035a6:	89 54 24 04          	mov    %edx,0x4(%esp)
801035aa:	89 04 24             	mov    %eax,(%esp)
801035ad:	e8 f4 cb ff ff       	call   801001a6 <bread>
801035b2:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(lbuf->data, b->data, BSIZE);
801035b5:	8b 45 08             	mov    0x8(%ebp),%eax
801035b8:	8d 50 18             	lea    0x18(%eax),%edx
801035bb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801035be:	83 c0 18             	add    $0x18,%eax
801035c1:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
801035c8:	00 
801035c9:	89 54 24 04          	mov    %edx,0x4(%esp)
801035cd:	89 04 24             	mov    %eax,(%esp)
801035d0:	e8 90 22 00 00       	call   80105865 <memmove>
  bwrite(lbuf);
801035d5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801035d8:	89 04 24             	mov    %eax,(%esp)
801035db:	e8 fd cb ff ff       	call   801001dd <bwrite>
  brelse(lbuf);
801035e0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801035e3:	89 04 24             	mov    %eax,(%esp)
801035e6:	e8 2c cc ff ff       	call   80100217 <brelse>
  if (i == log.lh.n)
801035eb:	a1 24 29 11 80       	mov    0x80112924,%eax
801035f0:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801035f3:	75 0d                	jne    80103602 <log_write+0xf8>
    log.lh.n++;
801035f5:	a1 24 29 11 80       	mov    0x80112924,%eax
801035fa:	83 c0 01             	add    $0x1,%eax
801035fd:	a3 24 29 11 80       	mov    %eax,0x80112924
  b->flags |= B_DIRTY; // XXX prevent eviction
80103602:	8b 45 08             	mov    0x8(%ebp),%eax
80103605:	8b 00                	mov    (%eax),%eax
80103607:	89 c2                	mov    %eax,%edx
80103609:	83 ca 04             	or     $0x4,%edx
8010360c:	8b 45 08             	mov    0x8(%ebp),%eax
8010360f:	89 10                	mov    %edx,(%eax)
}
80103611:	c9                   	leave  
80103612:	c3                   	ret    
	...

80103614 <v2p>:
80103614:	55                   	push   %ebp
80103615:	89 e5                	mov    %esp,%ebp
80103617:	8b 45 08             	mov    0x8(%ebp),%eax
8010361a:	05 00 00 00 80       	add    $0x80000000,%eax
8010361f:	5d                   	pop    %ebp
80103620:	c3                   	ret    

80103621 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80103621:	55                   	push   %ebp
80103622:	89 e5                	mov    %esp,%ebp
80103624:	8b 45 08             	mov    0x8(%ebp),%eax
80103627:	05 00 00 00 80       	add    $0x80000000,%eax
8010362c:	5d                   	pop    %ebp
8010362d:	c3                   	ret    

8010362e <xchg>:
  asm volatile("sti");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
8010362e:	55                   	push   %ebp
8010362f:	89 e5                	mov    %esp,%ebp
80103631:	53                   	push   %ebx
80103632:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
80103635:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80103638:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
8010363b:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
8010363e:	89 c3                	mov    %eax,%ebx
80103640:	89 d8                	mov    %ebx,%eax
80103642:	f0 87 02             	lock xchg %eax,(%edx)
80103645:	89 c3                	mov    %eax,%ebx
80103647:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
8010364a:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
8010364d:	83 c4 10             	add    $0x10,%esp
80103650:	5b                   	pop    %ebx
80103651:	5d                   	pop    %ebp
80103652:	c3                   	ret    

80103653 <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
80103653:	55                   	push   %ebp
80103654:	89 e5                	mov    %esp,%ebp
80103656:	83 e4 f0             	and    $0xfffffff0,%esp
80103659:	83 ec 10             	sub    $0x10,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
8010365c:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
80103663:	80 
80103664:	c7 04 24 5c 5b 11 80 	movl   $0x80115b5c,(%esp)
8010366b:	e8 65 f3 ff ff       	call   801029d5 <kinit1>
  kvmalloc();      // kernel page table
80103670:	e8 a9 51 00 00       	call   8010881e <kvmalloc>
  mpinit();        // collect info about this machine
80103675:	e8 63 04 00 00       	call   80103add <mpinit>
  lapicinit(mpbcpu());
8010367a:	e8 2e 02 00 00       	call   801038ad <mpbcpu>
8010367f:	89 04 24             	mov    %eax,(%esp)
80103682:	e8 f5 f8 ff ff       	call   80102f7c <lapicinit>
  seginit();       // set up segments
80103687:	e8 35 4b 00 00       	call   801081c1 <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
8010368c:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103692:	0f b6 00             	movzbl (%eax),%eax
80103695:	0f b6 c0             	movzbl %al,%eax
80103698:	89 44 24 04          	mov    %eax,0x4(%esp)
8010369c:	c7 04 24 f1 91 10 80 	movl   $0x801091f1,(%esp)
801036a3:	e8 f9 cc ff ff       	call   801003a1 <cprintf>
  picinit();       // interrupt controller
801036a8:	e8 95 06 00 00       	call   80103d42 <picinit>
  ioapicinit();    // another interrupt controller
801036ad:	e8 13 f2 ff ff       	call   801028c5 <ioapicinit>
  consoleinit();   // I/O devices & their interrupts
801036b2:	e8 d6 d3 ff ff       	call   80100a8d <consoleinit>
  uartinit();      // serial port
801036b7:	e8 50 3e 00 00       	call   8010750c <uartinit>
  pinit();         // process table
801036bc:	e8 a3 0b 00 00       	call   80104264 <pinit>
  tvinit();        // trap vectors
801036c1:	e8 e9 39 00 00       	call   801070af <tvinit>
  binit();         // buffer cache
801036c6:	e8 69 c9 ff ff       	call   80100034 <binit>
  fileinit();      // file table
801036cb:	e8 30 d8 ff ff       	call   80100f00 <fileinit>
  iinit();         // inode cache
801036d0:	e8 de de ff ff       	call   801015b3 <iinit>
  ideinit();       // disk
801036d5:	e8 52 ee ff ff       	call   8010252c <ideinit>
  if(!ismp)
801036da:	a1 64 29 11 80       	mov    0x80112964,%eax
801036df:	85 c0                	test   %eax,%eax
801036e1:	75 05                	jne    801036e8 <main+0x95>
    timerinit();   // uniprocessor timer
801036e3:	e8 0a 39 00 00       	call   80106ff2 <timerinit>
  startothers();   // start other processors
801036e8:	e8 87 00 00 00       	call   80103774 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
801036ed:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
801036f4:	8e 
801036f5:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
801036fc:	e8 0c f3 ff ff       	call   80102a0d <kinit2>
  userinit();      // first user process
80103701:	e8 0d 12 00 00       	call   80104913 <userinit>
  // Finish setting up this processor in mpmain.
  mpmain();
80103706:	e8 22 00 00 00       	call   8010372d <mpmain>

8010370b <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
8010370b:	55                   	push   %ebp
8010370c:	89 e5                	mov    %esp,%ebp
8010370e:	83 ec 18             	sub    $0x18,%esp
  switchkvm(); 
80103711:	e8 1f 51 00 00       	call   80108835 <switchkvm>
  seginit();
80103716:	e8 a6 4a 00 00       	call   801081c1 <seginit>
  lapicinit(cpunum());
8010371b:	e8 b9 f9 ff ff       	call   801030d9 <cpunum>
80103720:	89 04 24             	mov    %eax,(%esp)
80103723:	e8 54 f8 ff ff       	call   80102f7c <lapicinit>
  mpmain();
80103728:	e8 00 00 00 00       	call   8010372d <mpmain>

8010372d <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
8010372d:	55                   	push   %ebp
8010372e:	89 e5                	mov    %esp,%ebp
80103730:	83 ec 18             	sub    $0x18,%esp
  cprintf("cpu%d: starting\n", cpu->id);
80103733:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103739:	0f b6 00             	movzbl (%eax),%eax
8010373c:	0f b6 c0             	movzbl %al,%eax
8010373f:	89 44 24 04          	mov    %eax,0x4(%esp)
80103743:	c7 04 24 08 92 10 80 	movl   $0x80109208,(%esp)
8010374a:	e8 52 cc ff ff       	call   801003a1 <cprintf>
  idtinit();       // load idt register
8010374f:	e8 cf 3a 00 00       	call   80107223 <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
80103754:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010375a:	05 a8 00 00 00       	add    $0xa8,%eax
8010375f:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80103766:	00 
80103767:	89 04 24             	mov    %eax,(%esp)
8010376a:	e8 bf fe ff ff       	call   8010362e <xchg>
  scheduler();     // start running processes
8010376f:	e8 af 17 00 00       	call   80104f23 <scheduler>

80103774 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80103774:	55                   	push   %ebp
80103775:	89 e5                	mov    %esp,%ebp
80103777:	53                   	push   %ebx
80103778:	83 ec 24             	sub    $0x24,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
8010377b:	c7 04 24 00 70 00 00 	movl   $0x7000,(%esp)
80103782:	e8 9a fe ff ff       	call   80103621 <p2v>
80103787:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
8010378a:	b8 8a 00 00 00       	mov    $0x8a,%eax
8010378f:	89 44 24 08          	mov    %eax,0x8(%esp)
80103793:	c7 44 24 04 2c c5 10 	movl   $0x8010c52c,0x4(%esp)
8010379a:	80 
8010379b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010379e:	89 04 24             	mov    %eax,(%esp)
801037a1:	e8 bf 20 00 00       	call   80105865 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
801037a6:	c7 45 f4 80 29 11 80 	movl   $0x80112980,-0xc(%ebp)
801037ad:	e9 86 00 00 00       	jmp    80103838 <startothers+0xc4>
    if(c == cpus+cpunum())  // We've started already.
801037b2:	e8 22 f9 ff ff       	call   801030d9 <cpunum>
801037b7:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801037bd:	05 80 29 11 80       	add    $0x80112980,%eax
801037c2:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801037c5:	74 69                	je     80103830 <startothers+0xbc>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what 
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
801037c7:	e8 37 f3 ff ff       	call   80102b03 <kalloc>
801037cc:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
801037cf:	8b 45 f0             	mov    -0x10(%ebp),%eax
801037d2:	83 e8 04             	sub    $0x4,%eax
801037d5:	8b 55 ec             	mov    -0x14(%ebp),%edx
801037d8:	81 c2 00 10 00 00    	add    $0x1000,%edx
801037de:	89 10                	mov    %edx,(%eax)
    *(void**)(code-8) = mpenter;
801037e0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801037e3:	83 e8 08             	sub    $0x8,%eax
801037e6:	c7 00 0b 37 10 80    	movl   $0x8010370b,(%eax)
    *(int**)(code-12) = (void *) v2p(entrypgdir);
801037ec:	8b 45 f0             	mov    -0x10(%ebp),%eax
801037ef:	8d 58 f4             	lea    -0xc(%eax),%ebx
801037f2:	c7 04 24 00 b0 10 80 	movl   $0x8010b000,(%esp)
801037f9:	e8 16 fe ff ff       	call   80103614 <v2p>
801037fe:	89 03                	mov    %eax,(%ebx)

    lapicstartap(c->id, v2p(code));
80103800:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103803:	89 04 24             	mov    %eax,(%esp)
80103806:	e8 09 fe ff ff       	call   80103614 <v2p>
8010380b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010380e:	0f b6 12             	movzbl (%edx),%edx
80103811:	0f b6 d2             	movzbl %dl,%edx
80103814:	89 44 24 04          	mov    %eax,0x4(%esp)
80103818:	89 14 24             	mov    %edx,(%esp)
8010381b:	e8 3f f9 ff ff       	call   8010315f <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80103820:	90                   	nop
80103821:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103824:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
8010382a:	85 c0                	test   %eax,%eax
8010382c:	74 f3                	je     80103821 <startothers+0xad>
8010382e:	eb 01                	jmp    80103831 <startothers+0xbd>
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
    if(c == cpus+cpunum())  // We've started already.
      continue;
80103830:	90                   	nop
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
80103831:	81 45 f4 bc 00 00 00 	addl   $0xbc,-0xc(%ebp)
80103838:	a1 60 2f 11 80       	mov    0x80112f60,%eax
8010383d:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103843:	05 80 29 11 80       	add    $0x80112980,%eax
80103848:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010384b:	0f 87 61 ff ff ff    	ja     801037b2 <startothers+0x3e>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;
  }
}
80103851:	83 c4 24             	add    $0x24,%esp
80103854:	5b                   	pop    %ebx
80103855:	5d                   	pop    %ebp
80103856:	c3                   	ret    
	...

80103858 <p2v>:
80103858:	55                   	push   %ebp
80103859:	89 e5                	mov    %esp,%ebp
8010385b:	8b 45 08             	mov    0x8(%ebp),%eax
8010385e:	05 00 00 00 80       	add    $0x80000000,%eax
80103863:	5d                   	pop    %ebp
80103864:	c3                   	ret    

80103865 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80103865:	55                   	push   %ebp
80103866:	89 e5                	mov    %esp,%ebp
80103868:	53                   	push   %ebx
80103869:	83 ec 14             	sub    $0x14,%esp
8010386c:	8b 45 08             	mov    0x8(%ebp),%eax
8010386f:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80103873:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80103877:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
8010387b:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
8010387f:	ec                   	in     (%dx),%al
80103880:	89 c3                	mov    %eax,%ebx
80103882:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80103885:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80103889:	83 c4 14             	add    $0x14,%esp
8010388c:	5b                   	pop    %ebx
8010388d:	5d                   	pop    %ebp
8010388e:	c3                   	ret    

8010388f <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
8010388f:	55                   	push   %ebp
80103890:	89 e5                	mov    %esp,%ebp
80103892:	83 ec 08             	sub    $0x8,%esp
80103895:	8b 55 08             	mov    0x8(%ebp),%edx
80103898:	8b 45 0c             	mov    0xc(%ebp),%eax
8010389b:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
8010389f:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801038a2:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801038a6:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801038aa:	ee                   	out    %al,(%dx)
}
801038ab:	c9                   	leave  
801038ac:	c3                   	ret    

801038ad <mpbcpu>:
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
801038ad:	55                   	push   %ebp
801038ae:	89 e5                	mov    %esp,%ebp
  return bcpu-cpus;
801038b0:	a1 64 c6 10 80       	mov    0x8010c664,%eax
801038b5:	89 c2                	mov    %eax,%edx
801038b7:	b8 80 29 11 80       	mov    $0x80112980,%eax
801038bc:	89 d1                	mov    %edx,%ecx
801038be:	29 c1                	sub    %eax,%ecx
801038c0:	89 c8                	mov    %ecx,%eax
801038c2:	c1 f8 02             	sar    $0x2,%eax
801038c5:	69 c0 cf 46 7d 67    	imul   $0x677d46cf,%eax,%eax
}
801038cb:	5d                   	pop    %ebp
801038cc:	c3                   	ret    

801038cd <sum>:

static uchar
sum(uchar *addr, int len)
{
801038cd:	55                   	push   %ebp
801038ce:	89 e5                	mov    %esp,%ebp
801038d0:	83 ec 10             	sub    $0x10,%esp
  int i, sum;
  
  sum = 0;
801038d3:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
801038da:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801038e1:	eb 13                	jmp    801038f6 <sum+0x29>
    sum += addr[i];
801038e3:	8b 45 fc             	mov    -0x4(%ebp),%eax
801038e6:	03 45 08             	add    0x8(%ebp),%eax
801038e9:	0f b6 00             	movzbl (%eax),%eax
801038ec:	0f b6 c0             	movzbl %al,%eax
801038ef:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
801038f2:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801038f6:	8b 45 fc             	mov    -0x4(%ebp),%eax
801038f9:	3b 45 0c             	cmp    0xc(%ebp),%eax
801038fc:	7c e5                	jl     801038e3 <sum+0x16>
    sum += addr[i];
  return sum;
801038fe:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103901:	c9                   	leave  
80103902:	c3                   	ret    

80103903 <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80103903:	55                   	push   %ebp
80103904:	89 e5                	mov    %esp,%ebp
80103906:	83 ec 28             	sub    $0x28,%esp
  uchar *e, *p, *addr;

  addr = p2v(a);
80103909:	8b 45 08             	mov    0x8(%ebp),%eax
8010390c:	89 04 24             	mov    %eax,(%esp)
8010390f:	e8 44 ff ff ff       	call   80103858 <p2v>
80103914:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
80103917:	8b 45 0c             	mov    0xc(%ebp),%eax
8010391a:	03 45 f0             	add    -0x10(%ebp),%eax
8010391d:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
80103920:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103923:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103926:	eb 3f                	jmp    80103967 <mpsearch1+0x64>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80103928:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
8010392f:	00 
80103930:	c7 44 24 04 1c 92 10 	movl   $0x8010921c,0x4(%esp)
80103937:	80 
80103938:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010393b:	89 04 24             	mov    %eax,(%esp)
8010393e:	e8 c6 1e 00 00       	call   80105809 <memcmp>
80103943:	85 c0                	test   %eax,%eax
80103945:	75 1c                	jne    80103963 <mpsearch1+0x60>
80103947:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
8010394e:	00 
8010394f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103952:	89 04 24             	mov    %eax,(%esp)
80103955:	e8 73 ff ff ff       	call   801038cd <sum>
8010395a:	84 c0                	test   %al,%al
8010395c:	75 05                	jne    80103963 <mpsearch1+0x60>
      return (struct mp*)p;
8010395e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103961:	eb 11                	jmp    80103974 <mpsearch1+0x71>
{
  uchar *e, *p, *addr;

  addr = p2v(a);
  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
80103963:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80103967:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010396a:	3b 45 ec             	cmp    -0x14(%ebp),%eax
8010396d:	72 b9                	jb     80103928 <mpsearch1+0x25>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
8010396f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103974:	c9                   	leave  
80103975:	c3                   	ret    

80103976 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80103976:	55                   	push   %ebp
80103977:	89 e5                	mov    %esp,%ebp
80103979:	83 ec 28             	sub    $0x28,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
8010397c:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80103983:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103986:	83 c0 0f             	add    $0xf,%eax
80103989:	0f b6 00             	movzbl (%eax),%eax
8010398c:	0f b6 c0             	movzbl %al,%eax
8010398f:	89 c2                	mov    %eax,%edx
80103991:	c1 e2 08             	shl    $0x8,%edx
80103994:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103997:	83 c0 0e             	add    $0xe,%eax
8010399a:	0f b6 00             	movzbl (%eax),%eax
8010399d:	0f b6 c0             	movzbl %al,%eax
801039a0:	09 d0                	or     %edx,%eax
801039a2:	c1 e0 04             	shl    $0x4,%eax
801039a5:	89 45 f0             	mov    %eax,-0x10(%ebp)
801039a8:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801039ac:	74 21                	je     801039cf <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
801039ae:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
801039b5:	00 
801039b6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801039b9:	89 04 24             	mov    %eax,(%esp)
801039bc:	e8 42 ff ff ff       	call   80103903 <mpsearch1>
801039c1:	89 45 ec             	mov    %eax,-0x14(%ebp)
801039c4:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801039c8:	74 50                	je     80103a1a <mpsearch+0xa4>
      return mp;
801039ca:	8b 45 ec             	mov    -0x14(%ebp),%eax
801039cd:	eb 5f                	jmp    80103a2e <mpsearch+0xb8>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
801039cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039d2:	83 c0 14             	add    $0x14,%eax
801039d5:	0f b6 00             	movzbl (%eax),%eax
801039d8:	0f b6 c0             	movzbl %al,%eax
801039db:	89 c2                	mov    %eax,%edx
801039dd:	c1 e2 08             	shl    $0x8,%edx
801039e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039e3:	83 c0 13             	add    $0x13,%eax
801039e6:	0f b6 00             	movzbl (%eax),%eax
801039e9:	0f b6 c0             	movzbl %al,%eax
801039ec:	09 d0                	or     %edx,%eax
801039ee:	c1 e0 0a             	shl    $0xa,%eax
801039f1:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
801039f4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801039f7:	2d 00 04 00 00       	sub    $0x400,%eax
801039fc:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80103a03:	00 
80103a04:	89 04 24             	mov    %eax,(%esp)
80103a07:	e8 f7 fe ff ff       	call   80103903 <mpsearch1>
80103a0c:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103a0f:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103a13:	74 05                	je     80103a1a <mpsearch+0xa4>
      return mp;
80103a15:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103a18:	eb 14                	jmp    80103a2e <mpsearch+0xb8>
  }
  return mpsearch1(0xF0000, 0x10000);
80103a1a:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103a21:	00 
80103a22:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
80103a29:	e8 d5 fe ff ff       	call   80103903 <mpsearch1>
}
80103a2e:	c9                   	leave  
80103a2f:	c3                   	ret    

80103a30 <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80103a30:	55                   	push   %ebp
80103a31:	89 e5                	mov    %esp,%ebp
80103a33:	83 ec 28             	sub    $0x28,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80103a36:	e8 3b ff ff ff       	call   80103976 <mpsearch>
80103a3b:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103a3e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103a42:	74 0a                	je     80103a4e <mpconfig+0x1e>
80103a44:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a47:	8b 40 04             	mov    0x4(%eax),%eax
80103a4a:	85 c0                	test   %eax,%eax
80103a4c:	75 0a                	jne    80103a58 <mpconfig+0x28>
    return 0;
80103a4e:	b8 00 00 00 00       	mov    $0x0,%eax
80103a53:	e9 83 00 00 00       	jmp    80103adb <mpconfig+0xab>
  conf = (struct mpconf*) p2v((uint) mp->physaddr);
80103a58:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a5b:	8b 40 04             	mov    0x4(%eax),%eax
80103a5e:	89 04 24             	mov    %eax,(%esp)
80103a61:	e8 f2 fd ff ff       	call   80103858 <p2v>
80103a66:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
80103a69:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80103a70:	00 
80103a71:	c7 44 24 04 21 92 10 	movl   $0x80109221,0x4(%esp)
80103a78:	80 
80103a79:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a7c:	89 04 24             	mov    %eax,(%esp)
80103a7f:	e8 85 1d 00 00       	call   80105809 <memcmp>
80103a84:	85 c0                	test   %eax,%eax
80103a86:	74 07                	je     80103a8f <mpconfig+0x5f>
    return 0;
80103a88:	b8 00 00 00 00       	mov    $0x0,%eax
80103a8d:	eb 4c                	jmp    80103adb <mpconfig+0xab>
  if(conf->version != 1 && conf->version != 4)
80103a8f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a92:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80103a96:	3c 01                	cmp    $0x1,%al
80103a98:	74 12                	je     80103aac <mpconfig+0x7c>
80103a9a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a9d:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80103aa1:	3c 04                	cmp    $0x4,%al
80103aa3:	74 07                	je     80103aac <mpconfig+0x7c>
    return 0;
80103aa5:	b8 00 00 00 00       	mov    $0x0,%eax
80103aaa:	eb 2f                	jmp    80103adb <mpconfig+0xab>
  if(sum((uchar*)conf, conf->length) != 0)
80103aac:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103aaf:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80103ab3:	0f b7 c0             	movzwl %ax,%eax
80103ab6:	89 44 24 04          	mov    %eax,0x4(%esp)
80103aba:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103abd:	89 04 24             	mov    %eax,(%esp)
80103ac0:	e8 08 fe ff ff       	call   801038cd <sum>
80103ac5:	84 c0                	test   %al,%al
80103ac7:	74 07                	je     80103ad0 <mpconfig+0xa0>
    return 0;
80103ac9:	b8 00 00 00 00       	mov    $0x0,%eax
80103ace:	eb 0b                	jmp    80103adb <mpconfig+0xab>
  *pmp = mp;
80103ad0:	8b 45 08             	mov    0x8(%ebp),%eax
80103ad3:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103ad6:	89 10                	mov    %edx,(%eax)
  return conf;
80103ad8:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80103adb:	c9                   	leave  
80103adc:	c3                   	ret    

80103add <mpinit>:

void
mpinit(void)
{
80103add:	55                   	push   %ebp
80103ade:	89 e5                	mov    %esp,%ebp
80103ae0:	83 ec 38             	sub    $0x38,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
80103ae3:	c7 05 64 c6 10 80 80 	movl   $0x80112980,0x8010c664
80103aea:	29 11 80 
  if((conf = mpconfig(&mp)) == 0)
80103aed:	8d 45 e0             	lea    -0x20(%ebp),%eax
80103af0:	89 04 24             	mov    %eax,(%esp)
80103af3:	e8 38 ff ff ff       	call   80103a30 <mpconfig>
80103af8:	89 45 f0             	mov    %eax,-0x10(%ebp)
80103afb:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103aff:	0f 84 9c 01 00 00    	je     80103ca1 <mpinit+0x1c4>
    return;
  ismp = 1;
80103b05:	c7 05 64 29 11 80 01 	movl   $0x1,0x80112964
80103b0c:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
80103b0f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b12:	8b 40 24             	mov    0x24(%eax),%eax
80103b15:	a3 d4 28 11 80       	mov    %eax,0x801128d4
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80103b1a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b1d:	83 c0 2c             	add    $0x2c,%eax
80103b20:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103b23:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b26:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80103b2a:	0f b7 c0             	movzwl %ax,%eax
80103b2d:	03 45 f0             	add    -0x10(%ebp),%eax
80103b30:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103b33:	e9 f4 00 00 00       	jmp    80103c2c <mpinit+0x14f>
    switch(*p){
80103b38:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b3b:	0f b6 00             	movzbl (%eax),%eax
80103b3e:	0f b6 c0             	movzbl %al,%eax
80103b41:	83 f8 04             	cmp    $0x4,%eax
80103b44:	0f 87 bf 00 00 00    	ja     80103c09 <mpinit+0x12c>
80103b4a:	8b 04 85 64 92 10 80 	mov    -0x7fef6d9c(,%eax,4),%eax
80103b51:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
80103b53:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b56:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(ncpu != proc->apicid){
80103b59:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103b5c:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103b60:	0f b6 d0             	movzbl %al,%edx
80103b63:	a1 60 2f 11 80       	mov    0x80112f60,%eax
80103b68:	39 c2                	cmp    %eax,%edx
80103b6a:	74 2d                	je     80103b99 <mpinit+0xbc>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
80103b6c:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103b6f:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103b73:	0f b6 d0             	movzbl %al,%edx
80103b76:	a1 60 2f 11 80       	mov    0x80112f60,%eax
80103b7b:	89 54 24 08          	mov    %edx,0x8(%esp)
80103b7f:	89 44 24 04          	mov    %eax,0x4(%esp)
80103b83:	c7 04 24 26 92 10 80 	movl   $0x80109226,(%esp)
80103b8a:	e8 12 c8 ff ff       	call   801003a1 <cprintf>
        ismp = 0;
80103b8f:	c7 05 64 29 11 80 00 	movl   $0x0,0x80112964
80103b96:	00 00 00 
      }
      if(proc->flags & MPBOOT)
80103b99:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103b9c:	0f b6 40 03          	movzbl 0x3(%eax),%eax
80103ba0:	0f b6 c0             	movzbl %al,%eax
80103ba3:	83 e0 02             	and    $0x2,%eax
80103ba6:	85 c0                	test   %eax,%eax
80103ba8:	74 15                	je     80103bbf <mpinit+0xe2>
        bcpu = &cpus[ncpu];
80103baa:	a1 60 2f 11 80       	mov    0x80112f60,%eax
80103baf:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103bb5:	05 80 29 11 80       	add    $0x80112980,%eax
80103bba:	a3 64 c6 10 80       	mov    %eax,0x8010c664
      cpus[ncpu].id = ncpu;
80103bbf:	8b 15 60 2f 11 80    	mov    0x80112f60,%edx
80103bc5:	a1 60 2f 11 80       	mov    0x80112f60,%eax
80103bca:	69 d2 bc 00 00 00    	imul   $0xbc,%edx,%edx
80103bd0:	81 c2 80 29 11 80    	add    $0x80112980,%edx
80103bd6:	88 02                	mov    %al,(%edx)
      ncpu++;
80103bd8:	a1 60 2f 11 80       	mov    0x80112f60,%eax
80103bdd:	83 c0 01             	add    $0x1,%eax
80103be0:	a3 60 2f 11 80       	mov    %eax,0x80112f60
      p += sizeof(struct mpproc);
80103be5:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
80103be9:	eb 41                	jmp    80103c2c <mpinit+0x14f>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
80103beb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103bee:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      ioapicid = ioapic->apicno;
80103bf1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80103bf4:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103bf8:	a2 60 29 11 80       	mov    %al,0x80112960
      p += sizeof(struct mpioapic);
80103bfd:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80103c01:	eb 29                	jmp    80103c2c <mpinit+0x14f>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80103c03:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80103c07:	eb 23                	jmp    80103c2c <mpinit+0x14f>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
80103c09:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c0c:	0f b6 00             	movzbl (%eax),%eax
80103c0f:	0f b6 c0             	movzbl %al,%eax
80103c12:	89 44 24 04          	mov    %eax,0x4(%esp)
80103c16:	c7 04 24 44 92 10 80 	movl   $0x80109244,(%esp)
80103c1d:	e8 7f c7 ff ff       	call   801003a1 <cprintf>
      ismp = 0;
80103c22:	c7 05 64 29 11 80 00 	movl   $0x0,0x80112964
80103c29:	00 00 00 
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80103c2c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c2f:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103c32:	0f 82 00 ff ff ff    	jb     80103b38 <mpinit+0x5b>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
      ismp = 0;
    }
  }
  if(!ismp){
80103c38:	a1 64 29 11 80       	mov    0x80112964,%eax
80103c3d:	85 c0                	test   %eax,%eax
80103c3f:	75 1d                	jne    80103c5e <mpinit+0x181>
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
80103c41:	c7 05 60 2f 11 80 01 	movl   $0x1,0x80112f60
80103c48:	00 00 00 
    lapic = 0;
80103c4b:	c7 05 d4 28 11 80 00 	movl   $0x0,0x801128d4
80103c52:	00 00 00 
    ioapicid = 0;
80103c55:	c6 05 60 29 11 80 00 	movb   $0x0,0x80112960
    return;
80103c5c:	eb 44                	jmp    80103ca2 <mpinit+0x1c5>
  }

  if(mp->imcrp){
80103c5e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80103c61:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
80103c65:	84 c0                	test   %al,%al
80103c67:	74 39                	je     80103ca2 <mpinit+0x1c5>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
80103c69:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
80103c70:	00 
80103c71:	c7 04 24 22 00 00 00 	movl   $0x22,(%esp)
80103c78:	e8 12 fc ff ff       	call   8010388f <outb>
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80103c7d:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80103c84:	e8 dc fb ff ff       	call   80103865 <inb>
80103c89:	83 c8 01             	or     $0x1,%eax
80103c8c:	0f b6 c0             	movzbl %al,%eax
80103c8f:	89 44 24 04          	mov    %eax,0x4(%esp)
80103c93:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80103c9a:	e8 f0 fb ff ff       	call   8010388f <outb>
80103c9f:	eb 01                	jmp    80103ca2 <mpinit+0x1c5>
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
80103ca1:	90                   	nop
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
  }
}
80103ca2:	c9                   	leave  
80103ca3:	c3                   	ret    

80103ca4 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103ca4:	55                   	push   %ebp
80103ca5:	89 e5                	mov    %esp,%ebp
80103ca7:	83 ec 08             	sub    $0x8,%esp
80103caa:	8b 55 08             	mov    0x8(%ebp),%edx
80103cad:	8b 45 0c             	mov    0xc(%ebp),%eax
80103cb0:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103cb4:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103cb7:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103cbb:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103cbf:	ee                   	out    %al,(%dx)
}
80103cc0:	c9                   	leave  
80103cc1:	c3                   	ret    

80103cc2 <picsetmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static ushort irqmask = 0xFFFF & ~(1<<IRQ_SLAVE);

static void
picsetmask(ushort mask)
{
80103cc2:	55                   	push   %ebp
80103cc3:	89 e5                	mov    %esp,%ebp
80103cc5:	83 ec 0c             	sub    $0xc,%esp
80103cc8:	8b 45 08             	mov    0x8(%ebp),%eax
80103ccb:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  irqmask = mask;
80103ccf:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103cd3:	66 a3 00 c0 10 80    	mov    %ax,0x8010c000
  outb(IO_PIC1+1, mask);
80103cd9:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103cdd:	0f b6 c0             	movzbl %al,%eax
80103ce0:	89 44 24 04          	mov    %eax,0x4(%esp)
80103ce4:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103ceb:	e8 b4 ff ff ff       	call   80103ca4 <outb>
  outb(IO_PIC2+1, mask >> 8);
80103cf0:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103cf4:	66 c1 e8 08          	shr    $0x8,%ax
80103cf8:	0f b6 c0             	movzbl %al,%eax
80103cfb:	89 44 24 04          	mov    %eax,0x4(%esp)
80103cff:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103d06:	e8 99 ff ff ff       	call   80103ca4 <outb>
}
80103d0b:	c9                   	leave  
80103d0c:	c3                   	ret    

80103d0d <picenable>:

void
picenable(int irq)
{
80103d0d:	55                   	push   %ebp
80103d0e:	89 e5                	mov    %esp,%ebp
80103d10:	53                   	push   %ebx
80103d11:	83 ec 04             	sub    $0x4,%esp
  picsetmask(irqmask & ~(1<<irq));
80103d14:	8b 45 08             	mov    0x8(%ebp),%eax
80103d17:	ba 01 00 00 00       	mov    $0x1,%edx
80103d1c:	89 d3                	mov    %edx,%ebx
80103d1e:	89 c1                	mov    %eax,%ecx
80103d20:	d3 e3                	shl    %cl,%ebx
80103d22:	89 d8                	mov    %ebx,%eax
80103d24:	89 c2                	mov    %eax,%edx
80103d26:	f7 d2                	not    %edx
80103d28:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
80103d2f:	21 d0                	and    %edx,%eax
80103d31:	0f b7 c0             	movzwl %ax,%eax
80103d34:	89 04 24             	mov    %eax,(%esp)
80103d37:	e8 86 ff ff ff       	call   80103cc2 <picsetmask>
}
80103d3c:	83 c4 04             	add    $0x4,%esp
80103d3f:	5b                   	pop    %ebx
80103d40:	5d                   	pop    %ebp
80103d41:	c3                   	ret    

80103d42 <picinit>:

// Initialize the 8259A interrupt controllers.
void
picinit(void)
{
80103d42:	55                   	push   %ebp
80103d43:	89 e5                	mov    %esp,%ebp
80103d45:	83 ec 08             	sub    $0x8,%esp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
80103d48:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80103d4f:	00 
80103d50:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103d57:	e8 48 ff ff ff       	call   80103ca4 <outb>
  outb(IO_PIC2+1, 0xFF);
80103d5c:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80103d63:	00 
80103d64:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103d6b:	e8 34 ff ff ff       	call   80103ca4 <outb>

  // ICW1:  0001g0hi
  //    g:  0 = edge triggering, 1 = level triggering
  //    h:  0 = cascaded PICs, 1 = master only
  //    i:  0 = no ICW4, 1 = ICW4 required
  outb(IO_PIC1, 0x11);
80103d70:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80103d77:	00 
80103d78:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103d7f:	e8 20 ff ff ff       	call   80103ca4 <outb>

  // ICW2:  Vector offset
  outb(IO_PIC1+1, T_IRQ0);
80103d84:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
80103d8b:	00 
80103d8c:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103d93:	e8 0c ff ff ff       	call   80103ca4 <outb>

  // ICW3:  (master PIC) bit mask of IR lines connected to slaves
  //        (slave PIC) 3-bit # of slave's connection to master
  outb(IO_PIC1+1, 1<<IRQ_SLAVE);
80103d98:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
80103d9f:	00 
80103da0:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103da7:	e8 f8 fe ff ff       	call   80103ca4 <outb>
  //    m:  0 = slave PIC, 1 = master PIC
  //      (ignored when b is 0, as the master/slave role
  //      can be hardwired).
  //    a:  1 = Automatic EOI mode
  //    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
  outb(IO_PIC1+1, 0x3);
80103dac:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80103db3:	00 
80103db4:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103dbb:	e8 e4 fe ff ff       	call   80103ca4 <outb>

  // Set up slave (8259A-2)
  outb(IO_PIC2, 0x11);                  // ICW1
80103dc0:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80103dc7:	00 
80103dc8:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103dcf:	e8 d0 fe ff ff       	call   80103ca4 <outb>
  outb(IO_PIC2+1, T_IRQ0 + 8);      // ICW2
80103dd4:	c7 44 24 04 28 00 00 	movl   $0x28,0x4(%esp)
80103ddb:	00 
80103ddc:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103de3:	e8 bc fe ff ff       	call   80103ca4 <outb>
  outb(IO_PIC2+1, IRQ_SLAVE);           // ICW3
80103de8:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80103def:	00 
80103df0:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103df7:	e8 a8 fe ff ff       	call   80103ca4 <outb>
  // NB Automatic EOI mode doesn't tend to work on the slave.
  // Linux source code says it's "to be investigated".
  outb(IO_PIC2+1, 0x3);                 // ICW4
80103dfc:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80103e03:	00 
80103e04:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103e0b:	e8 94 fe ff ff       	call   80103ca4 <outb>

  // OCW3:  0ef01prs
  //   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
  //    p:  0 = no polling, 1 = polling mode
  //   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
  outb(IO_PIC1, 0x68);             // clear specific mask
80103e10:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80103e17:	00 
80103e18:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103e1f:	e8 80 fe ff ff       	call   80103ca4 <outb>
  outb(IO_PIC1, 0x0a);             // read IRR by default
80103e24:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80103e2b:	00 
80103e2c:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103e33:	e8 6c fe ff ff       	call   80103ca4 <outb>

  outb(IO_PIC2, 0x68);             // OCW3
80103e38:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80103e3f:	00 
80103e40:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103e47:	e8 58 fe ff ff       	call   80103ca4 <outb>
  outb(IO_PIC2, 0x0a);             // OCW3
80103e4c:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80103e53:	00 
80103e54:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103e5b:	e8 44 fe ff ff       	call   80103ca4 <outb>

  if(irqmask != 0xFFFF)
80103e60:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
80103e67:	66 83 f8 ff          	cmp    $0xffff,%ax
80103e6b:	74 12                	je     80103e7f <picinit+0x13d>
    picsetmask(irqmask);
80103e6d:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
80103e74:	0f b7 c0             	movzwl %ax,%eax
80103e77:	89 04 24             	mov    %eax,(%esp)
80103e7a:	e8 43 fe ff ff       	call   80103cc2 <picsetmask>
}
80103e7f:	c9                   	leave  
80103e80:	c3                   	ret    
80103e81:	00 00                	add    %al,(%eax)
	...

80103e84 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80103e84:	55                   	push   %ebp
80103e85:	89 e5                	mov    %esp,%ebp
80103e87:	83 ec 28             	sub    $0x28,%esp
  struct pipe *p;

  p = 0;
80103e8a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
80103e91:	8b 45 0c             	mov    0xc(%ebp),%eax
80103e94:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
80103e9a:	8b 45 0c             	mov    0xc(%ebp),%eax
80103e9d:	8b 10                	mov    (%eax),%edx
80103e9f:	8b 45 08             	mov    0x8(%ebp),%eax
80103ea2:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80103ea4:	e8 73 d0 ff ff       	call   80100f1c <filealloc>
80103ea9:	8b 55 08             	mov    0x8(%ebp),%edx
80103eac:	89 02                	mov    %eax,(%edx)
80103eae:	8b 45 08             	mov    0x8(%ebp),%eax
80103eb1:	8b 00                	mov    (%eax),%eax
80103eb3:	85 c0                	test   %eax,%eax
80103eb5:	0f 84 c8 00 00 00    	je     80103f83 <pipealloc+0xff>
80103ebb:	e8 5c d0 ff ff       	call   80100f1c <filealloc>
80103ec0:	8b 55 0c             	mov    0xc(%ebp),%edx
80103ec3:	89 02                	mov    %eax,(%edx)
80103ec5:	8b 45 0c             	mov    0xc(%ebp),%eax
80103ec8:	8b 00                	mov    (%eax),%eax
80103eca:	85 c0                	test   %eax,%eax
80103ecc:	0f 84 b1 00 00 00    	je     80103f83 <pipealloc+0xff>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
80103ed2:	e8 2c ec ff ff       	call   80102b03 <kalloc>
80103ed7:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103eda:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103ede:	0f 84 9e 00 00 00    	je     80103f82 <pipealloc+0xfe>
    goto bad;
  p->readopen = 1;
80103ee4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ee7:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80103eee:	00 00 00 
  p->writeopen = 1;
80103ef1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ef4:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80103efb:	00 00 00 
  p->nwrite = 0;
80103efe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f01:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80103f08:	00 00 00 
  p->nread = 0;
80103f0b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f0e:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80103f15:	00 00 00 
  initlock(&p->lock, "pipe");
80103f18:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f1b:	c7 44 24 04 78 92 10 	movl   $0x80109278,0x4(%esp)
80103f22:	80 
80103f23:	89 04 24             	mov    %eax,(%esp)
80103f26:	e8 bf 15 00 00       	call   801054ea <initlock>
  (*f0)->type = FD_PIPE;
80103f2b:	8b 45 08             	mov    0x8(%ebp),%eax
80103f2e:	8b 00                	mov    (%eax),%eax
80103f30:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80103f36:	8b 45 08             	mov    0x8(%ebp),%eax
80103f39:	8b 00                	mov    (%eax),%eax
80103f3b:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80103f3f:	8b 45 08             	mov    0x8(%ebp),%eax
80103f42:	8b 00                	mov    (%eax),%eax
80103f44:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80103f48:	8b 45 08             	mov    0x8(%ebp),%eax
80103f4b:	8b 00                	mov    (%eax),%eax
80103f4d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103f50:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
80103f53:	8b 45 0c             	mov    0xc(%ebp),%eax
80103f56:	8b 00                	mov    (%eax),%eax
80103f58:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80103f5e:	8b 45 0c             	mov    0xc(%ebp),%eax
80103f61:	8b 00                	mov    (%eax),%eax
80103f63:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80103f67:	8b 45 0c             	mov    0xc(%ebp),%eax
80103f6a:	8b 00                	mov    (%eax),%eax
80103f6c:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80103f70:	8b 45 0c             	mov    0xc(%ebp),%eax
80103f73:	8b 00                	mov    (%eax),%eax
80103f75:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103f78:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
80103f7b:	b8 00 00 00 00       	mov    $0x0,%eax
80103f80:	eb 43                	jmp    80103fc5 <pipealloc+0x141>
  p = 0;
  *f0 = *f1 = 0;
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
    goto bad;
80103f82:	90                   	nop
  (*f1)->pipe = p;
  return 0;

//PAGEBREAK: 20
 bad:
  if(p)
80103f83:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103f87:	74 0b                	je     80103f94 <pipealloc+0x110>
    kfree((char*)p);
80103f89:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f8c:	89 04 24             	mov    %eax,(%esp)
80103f8f:	e8 d6 ea ff ff       	call   80102a6a <kfree>
  if(*f0)
80103f94:	8b 45 08             	mov    0x8(%ebp),%eax
80103f97:	8b 00                	mov    (%eax),%eax
80103f99:	85 c0                	test   %eax,%eax
80103f9b:	74 0d                	je     80103faa <pipealloc+0x126>
    fileclose(*f0);
80103f9d:	8b 45 08             	mov    0x8(%ebp),%eax
80103fa0:	8b 00                	mov    (%eax),%eax
80103fa2:	89 04 24             	mov    %eax,(%esp)
80103fa5:	e8 1a d0 ff ff       	call   80100fc4 <fileclose>
  if(*f1)
80103faa:	8b 45 0c             	mov    0xc(%ebp),%eax
80103fad:	8b 00                	mov    (%eax),%eax
80103faf:	85 c0                	test   %eax,%eax
80103fb1:	74 0d                	je     80103fc0 <pipealloc+0x13c>
    fileclose(*f1);
80103fb3:	8b 45 0c             	mov    0xc(%ebp),%eax
80103fb6:	8b 00                	mov    (%eax),%eax
80103fb8:	89 04 24             	mov    %eax,(%esp)
80103fbb:	e8 04 d0 ff ff       	call   80100fc4 <fileclose>
  return -1;
80103fc0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80103fc5:	c9                   	leave  
80103fc6:	c3                   	ret    

80103fc7 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80103fc7:	55                   	push   %ebp
80103fc8:	89 e5                	mov    %esp,%ebp
80103fca:	83 ec 18             	sub    $0x18,%esp
  acquire(&p->lock);
80103fcd:	8b 45 08             	mov    0x8(%ebp),%eax
80103fd0:	89 04 24             	mov    %eax,(%esp)
80103fd3:	e8 33 15 00 00       	call   8010550b <acquire>
  if(writable){
80103fd8:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80103fdc:	74 1f                	je     80103ffd <pipeclose+0x36>
    p->writeopen = 0;
80103fde:	8b 45 08             	mov    0x8(%ebp),%eax
80103fe1:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
80103fe8:	00 00 00 
    wakeup(&p->nread);
80103feb:	8b 45 08             	mov    0x8(%ebp),%eax
80103fee:	05 34 02 00 00       	add    $0x234,%eax
80103ff3:	89 04 24             	mov    %eax,(%esp)
80103ff6:	e8 10 12 00 00       	call   8010520b <wakeup>
80103ffb:	eb 1d                	jmp    8010401a <pipeclose+0x53>
  } else {
    p->readopen = 0;
80103ffd:	8b 45 08             	mov    0x8(%ebp),%eax
80104000:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
80104007:	00 00 00 
    wakeup(&p->nwrite);
8010400a:	8b 45 08             	mov    0x8(%ebp),%eax
8010400d:	05 38 02 00 00       	add    $0x238,%eax
80104012:	89 04 24             	mov    %eax,(%esp)
80104015:	e8 f1 11 00 00       	call   8010520b <wakeup>
  }
  if(p->readopen == 0 && p->writeopen == 0){
8010401a:	8b 45 08             	mov    0x8(%ebp),%eax
8010401d:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80104023:	85 c0                	test   %eax,%eax
80104025:	75 25                	jne    8010404c <pipeclose+0x85>
80104027:	8b 45 08             	mov    0x8(%ebp),%eax
8010402a:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80104030:	85 c0                	test   %eax,%eax
80104032:	75 18                	jne    8010404c <pipeclose+0x85>
    release(&p->lock);
80104034:	8b 45 08             	mov    0x8(%ebp),%eax
80104037:	89 04 24             	mov    %eax,(%esp)
8010403a:	e8 67 15 00 00       	call   801055a6 <release>
    kfree((char*)p);
8010403f:	8b 45 08             	mov    0x8(%ebp),%eax
80104042:	89 04 24             	mov    %eax,(%esp)
80104045:	e8 20 ea ff ff       	call   80102a6a <kfree>
8010404a:	eb 0b                	jmp    80104057 <pipeclose+0x90>
  } else
    release(&p->lock);
8010404c:	8b 45 08             	mov    0x8(%ebp),%eax
8010404f:	89 04 24             	mov    %eax,(%esp)
80104052:	e8 4f 15 00 00       	call   801055a6 <release>
}
80104057:	c9                   	leave  
80104058:	c3                   	ret    

80104059 <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
80104059:	55                   	push   %ebp
8010405a:	89 e5                	mov    %esp,%ebp
8010405c:	53                   	push   %ebx
8010405d:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80104060:	8b 45 08             	mov    0x8(%ebp),%eax
80104063:	89 04 24             	mov    %eax,(%esp)
80104066:	e8 a0 14 00 00       	call   8010550b <acquire>
  for(i = 0; i < n; i++){
8010406b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104072:	e9 a6 00 00 00       	jmp    8010411d <pipewrite+0xc4>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
      if(p->readopen == 0 || proc->killed){
80104077:	8b 45 08             	mov    0x8(%ebp),%eax
8010407a:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80104080:	85 c0                	test   %eax,%eax
80104082:	74 0d                	je     80104091 <pipewrite+0x38>
80104084:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010408a:	8b 40 24             	mov    0x24(%eax),%eax
8010408d:	85 c0                	test   %eax,%eax
8010408f:	74 15                	je     801040a6 <pipewrite+0x4d>
        release(&p->lock);
80104091:	8b 45 08             	mov    0x8(%ebp),%eax
80104094:	89 04 24             	mov    %eax,(%esp)
80104097:	e8 0a 15 00 00       	call   801055a6 <release>
        return -1;
8010409c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801040a1:	e9 9d 00 00 00       	jmp    80104143 <pipewrite+0xea>
      }
      wakeup(&p->nread);
801040a6:	8b 45 08             	mov    0x8(%ebp),%eax
801040a9:	05 34 02 00 00       	add    $0x234,%eax
801040ae:	89 04 24             	mov    %eax,(%esp)
801040b1:	e8 55 11 00 00       	call   8010520b <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
801040b6:	8b 45 08             	mov    0x8(%ebp),%eax
801040b9:	8b 55 08             	mov    0x8(%ebp),%edx
801040bc:	81 c2 38 02 00 00    	add    $0x238,%edx
801040c2:	89 44 24 04          	mov    %eax,0x4(%esp)
801040c6:	89 14 24             	mov    %edx,(%esp)
801040c9:	e8 01 10 00 00       	call   801050cf <sleep>
801040ce:	eb 01                	jmp    801040d1 <pipewrite+0x78>
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
801040d0:	90                   	nop
801040d1:	8b 45 08             	mov    0x8(%ebp),%eax
801040d4:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
801040da:	8b 45 08             	mov    0x8(%ebp),%eax
801040dd:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
801040e3:	05 00 02 00 00       	add    $0x200,%eax
801040e8:	39 c2                	cmp    %eax,%edx
801040ea:	74 8b                	je     80104077 <pipewrite+0x1e>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
801040ec:	8b 45 08             	mov    0x8(%ebp),%eax
801040ef:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
801040f5:	89 c3                	mov    %eax,%ebx
801040f7:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
801040fd:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104100:	03 55 0c             	add    0xc(%ebp),%edx
80104103:	0f b6 0a             	movzbl (%edx),%ecx
80104106:	8b 55 08             	mov    0x8(%ebp),%edx
80104109:	88 4c 1a 34          	mov    %cl,0x34(%edx,%ebx,1)
8010410d:	8d 50 01             	lea    0x1(%eax),%edx
80104110:	8b 45 08             	mov    0x8(%ebp),%eax
80104113:	89 90 38 02 00 00    	mov    %edx,0x238(%eax)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
80104119:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010411d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104120:	3b 45 10             	cmp    0x10(%ebp),%eax
80104123:	7c ab                	jl     801040d0 <pipewrite+0x77>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
80104125:	8b 45 08             	mov    0x8(%ebp),%eax
80104128:	05 34 02 00 00       	add    $0x234,%eax
8010412d:	89 04 24             	mov    %eax,(%esp)
80104130:	e8 d6 10 00 00       	call   8010520b <wakeup>
  release(&p->lock);
80104135:	8b 45 08             	mov    0x8(%ebp),%eax
80104138:	89 04 24             	mov    %eax,(%esp)
8010413b:	e8 66 14 00 00       	call   801055a6 <release>
  return n;
80104140:	8b 45 10             	mov    0x10(%ebp),%eax
}
80104143:	83 c4 24             	add    $0x24,%esp
80104146:	5b                   	pop    %ebx
80104147:	5d                   	pop    %ebp
80104148:	c3                   	ret    

80104149 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
80104149:	55                   	push   %ebp
8010414a:	89 e5                	mov    %esp,%ebp
8010414c:	53                   	push   %ebx
8010414d:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80104150:	8b 45 08             	mov    0x8(%ebp),%eax
80104153:	89 04 24             	mov    %eax,(%esp)
80104156:	e8 b0 13 00 00       	call   8010550b <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
8010415b:	eb 3a                	jmp    80104197 <piperead+0x4e>
    if(proc->killed){
8010415d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104163:	8b 40 24             	mov    0x24(%eax),%eax
80104166:	85 c0                	test   %eax,%eax
80104168:	74 15                	je     8010417f <piperead+0x36>
      release(&p->lock);
8010416a:	8b 45 08             	mov    0x8(%ebp),%eax
8010416d:	89 04 24             	mov    %eax,(%esp)
80104170:	e8 31 14 00 00       	call   801055a6 <release>
      return -1;
80104175:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010417a:	e9 b6 00 00 00       	jmp    80104235 <piperead+0xec>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
8010417f:	8b 45 08             	mov    0x8(%ebp),%eax
80104182:	8b 55 08             	mov    0x8(%ebp),%edx
80104185:	81 c2 34 02 00 00    	add    $0x234,%edx
8010418b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010418f:	89 14 24             	mov    %edx,(%esp)
80104192:	e8 38 0f 00 00       	call   801050cf <sleep>
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80104197:	8b 45 08             	mov    0x8(%ebp),%eax
8010419a:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
801041a0:	8b 45 08             	mov    0x8(%ebp),%eax
801041a3:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
801041a9:	39 c2                	cmp    %eax,%edx
801041ab:	75 0d                	jne    801041ba <piperead+0x71>
801041ad:	8b 45 08             	mov    0x8(%ebp),%eax
801041b0:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
801041b6:	85 c0                	test   %eax,%eax
801041b8:	75 a3                	jne    8010415d <piperead+0x14>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801041ba:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801041c1:	eb 49                	jmp    8010420c <piperead+0xc3>
    if(p->nread == p->nwrite)
801041c3:	8b 45 08             	mov    0x8(%ebp),%eax
801041c6:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
801041cc:	8b 45 08             	mov    0x8(%ebp),%eax
801041cf:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
801041d5:	39 c2                	cmp    %eax,%edx
801041d7:	74 3d                	je     80104216 <piperead+0xcd>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
801041d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041dc:	89 c2                	mov    %eax,%edx
801041de:	03 55 0c             	add    0xc(%ebp),%edx
801041e1:	8b 45 08             	mov    0x8(%ebp),%eax
801041e4:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
801041ea:	89 c3                	mov    %eax,%ebx
801041ec:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
801041f2:	8b 4d 08             	mov    0x8(%ebp),%ecx
801041f5:	0f b6 4c 19 34       	movzbl 0x34(%ecx,%ebx,1),%ecx
801041fa:	88 0a                	mov    %cl,(%edx)
801041fc:	8d 50 01             	lea    0x1(%eax),%edx
801041ff:	8b 45 08             	mov    0x8(%ebp),%eax
80104202:	89 90 34 02 00 00    	mov    %edx,0x234(%eax)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80104208:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010420c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010420f:	3b 45 10             	cmp    0x10(%ebp),%eax
80104212:	7c af                	jl     801041c3 <piperead+0x7a>
80104214:	eb 01                	jmp    80104217 <piperead+0xce>
    if(p->nread == p->nwrite)
      break;
80104216:	90                   	nop
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
80104217:	8b 45 08             	mov    0x8(%ebp),%eax
8010421a:	05 38 02 00 00       	add    $0x238,%eax
8010421f:	89 04 24             	mov    %eax,(%esp)
80104222:	e8 e4 0f 00 00       	call   8010520b <wakeup>
  release(&p->lock);
80104227:	8b 45 08             	mov    0x8(%ebp),%eax
8010422a:	89 04 24             	mov    %eax,(%esp)
8010422d:	e8 74 13 00 00       	call   801055a6 <release>
  return i;
80104232:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104235:	83 c4 24             	add    $0x24,%esp
80104238:	5b                   	pop    %ebx
80104239:	5d                   	pop    %ebp
8010423a:	c3                   	ret    
	...

8010423c <p2v>:
8010423c:	55                   	push   %ebp
8010423d:	89 e5                	mov    %esp,%ebp
8010423f:	8b 45 08             	mov    0x8(%ebp),%eax
80104242:	05 00 00 00 80       	add    $0x80000000,%eax
80104247:	5d                   	pop    %ebp
80104248:	c3                   	ret    

80104249 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80104249:	55                   	push   %ebp
8010424a:	89 e5                	mov    %esp,%ebp
8010424c:	53                   	push   %ebx
8010424d:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80104250:	9c                   	pushf  
80104251:	5b                   	pop    %ebx
80104252:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80104255:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80104258:	83 c4 10             	add    $0x10,%esp
8010425b:	5b                   	pop    %ebx
8010425c:	5d                   	pop    %ebp
8010425d:	c3                   	ret    

8010425e <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
8010425e:	55                   	push   %ebp
8010425f:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80104261:	fb                   	sti    
}
80104262:	5d                   	pop    %ebp
80104263:	c3                   	ret    

80104264 <pinit>:

static void wakeup1(void *chan);

void
pinit(void)
{
80104264:	55                   	push   %ebp
80104265:	89 e5                	mov    %esp,%ebp
80104267:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
8010426a:	c7 44 24 04 7d 92 10 	movl   $0x8010927d,0x4(%esp)
80104271:	80 
80104272:	c7 04 24 80 2f 11 80 	movl   $0x80112f80,(%esp)
80104279:	e8 6c 12 00 00       	call   801054ea <initlock>
}
8010427e:	c9                   	leave  
8010427f:	c3                   	ret    

80104280 <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
80104280:	55                   	push   %ebp
80104281:	89 e5                	mov    %esp,%ebp
80104283:	83 ec 38             	sub    $0x38,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
80104286:	c7 04 24 80 2f 11 80 	movl   $0x80112f80,(%esp)
8010428d:	e8 79 12 00 00       	call   8010550b <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104292:	c7 45 f4 b4 2f 11 80 	movl   $0x80112fb4,-0xc(%ebp)
80104299:	eb 11                	jmp    801042ac <allocproc+0x2c>
    if(p->state == UNUSED)
8010429b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010429e:	8b 40 0c             	mov    0xc(%eax),%eax
801042a1:	85 c0                	test   %eax,%eax
801042a3:	74 26                	je     801042cb <allocproc+0x4b>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801042a5:	81 45 f4 8c 00 00 00 	addl   $0x8c,-0xc(%ebp)
801042ac:	81 7d f4 b4 52 11 80 	cmpl   $0x801152b4,-0xc(%ebp)
801042b3:	72 e6                	jb     8010429b <allocproc+0x1b>
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
801042b5:	c7 04 24 80 2f 11 80 	movl   $0x80112f80,(%esp)
801042bc:	e8 e5 12 00 00       	call   801055a6 <release>
  return 0;
801042c1:	b8 00 00 00 00       	mov    $0x0,%eax
801042c6:	e9 5a 01 00 00       	jmp    80104425 <allocproc+0x1a5>
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
    if(p->state == UNUSED)
      goto found;
801042cb:	90                   	nop
  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
801042cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042cf:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
  p->pid = nextpid++;
801042d6:	a1 04 c0 10 80       	mov    0x8010c004,%eax
801042db:	8b 55 f4             	mov    -0xc(%ebp),%edx
801042de:	89 42 10             	mov    %eax,0x10(%edx)
801042e1:	83 c0 01             	add    $0x1,%eax
801042e4:	a3 04 c0 10 80       	mov    %eax,0x8010c004
  release(&ptable.lock);
801042e9:	c7 04 24 80 2f 11 80 	movl   $0x80112f80,(%esp)
801042f0:	e8 b1 12 00 00       	call   801055a6 <release>

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
801042f5:	e8 09 e8 ff ff       	call   80102b03 <kalloc>
801042fa:	8b 55 f4             	mov    -0xc(%ebp),%edx
801042fd:	89 42 08             	mov    %eax,0x8(%edx)
80104300:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104303:	8b 40 08             	mov    0x8(%eax),%eax
80104306:	85 c0                	test   %eax,%eax
80104308:	75 14                	jne    8010431e <allocproc+0x9e>
    p->state = UNUSED;
8010430a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010430d:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return 0;
80104314:	b8 00 00 00 00       	mov    $0x0,%eax
80104319:	e9 07 01 00 00       	jmp    80104425 <allocproc+0x1a5>
  }
  sp = p->kstack + KSTACKSIZE;
8010431e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104321:	8b 40 08             	mov    0x8(%eax),%eax
80104324:	05 00 10 00 00       	add    $0x1000,%eax
80104329:	89 45 f0             	mov    %eax,-0x10(%ebp)
  
  // Leave room for trap frame.
  sp -= sizeof *p->tf;
8010432c:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
  p->tf = (struct trapframe*)sp;
80104330:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104333:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104336:	89 50 18             	mov    %edx,0x18(%eax)
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
80104339:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
  *(uint*)sp = (uint)trapret;
8010433d:	ba 64 70 10 80       	mov    $0x80107064,%edx
80104342:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104345:	89 10                	mov    %edx,(%eax)

  sp -= sizeof *p->context;
80104347:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
  p->context = (struct context*)sp;
8010434b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010434e:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104351:	89 50 1c             	mov    %edx,0x1c(%eax)
  memset(p->context, 0, sizeof *p->context);
80104354:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104357:	8b 40 1c             	mov    0x1c(%eax),%eax
8010435a:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80104361:	00 
80104362:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104369:	00 
8010436a:	89 04 24             	mov    %eax,(%esp)
8010436d:	e8 20 14 00 00       	call   80105792 <memset>
  p->context->eip = (uint)forkret;
80104372:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104375:	8b 40 1c             	mov    0x1c(%eax),%eax
80104378:	ba a3 50 10 80       	mov    $0x801050a3,%edx
8010437d:	89 50 10             	mov    %edx,0x10(%eax)
  int i = 0;
80104380:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  char name[8];
  name[2] = '.'; name[3] = 's'; name[4] = 'w'; name[5] = 'a'; name[6] = 'p'; name[7] = 0;
80104387:	c6 45 e6 2e          	movb   $0x2e,-0x1a(%ebp)
8010438b:	c6 45 e7 73          	movb   $0x73,-0x19(%ebp)
8010438f:	c6 45 e8 77          	movb   $0x77,-0x18(%ebp)
80104393:	c6 45 e9 61          	movb   $0x61,-0x17(%ebp)
80104397:	c6 45 ea 70          	movb   $0x70,-0x16(%ebp)
8010439b:	c6 45 eb 00          	movb   $0x0,-0x15(%ebp)
  name[1] = (char)(((int)'0')+p->pid % 10);
8010439f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043a2:	8b 48 10             	mov    0x10(%eax),%ecx
801043a5:	ba 67 66 66 66       	mov    $0x66666667,%edx
801043aa:	89 c8                	mov    %ecx,%eax
801043ac:	f7 ea                	imul   %edx
801043ae:	c1 fa 02             	sar    $0x2,%edx
801043b1:	89 c8                	mov    %ecx,%eax
801043b3:	c1 f8 1f             	sar    $0x1f,%eax
801043b6:	29 c2                	sub    %eax,%edx
801043b8:	89 d0                	mov    %edx,%eax
801043ba:	c1 e0 02             	shl    $0x2,%eax
801043bd:	01 d0                	add    %edx,%eax
801043bf:	01 c0                	add    %eax,%eax
801043c1:	89 ca                	mov    %ecx,%edx
801043c3:	29 c2                	sub    %eax,%edx
801043c5:	89 d0                	mov    %edx,%eax
801043c7:	83 c0 30             	add    $0x30,%eax
801043ca:	88 45 e5             	mov    %al,-0x1b(%ebp)
  if((i=p->pid/10) == 0)
801043cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043d0:	8b 48 10             	mov    0x10(%eax),%ecx
801043d3:	ba 67 66 66 66       	mov    $0x66666667,%edx
801043d8:	89 c8                	mov    %ecx,%eax
801043da:	f7 ea                	imul   %edx
801043dc:	c1 fa 02             	sar    $0x2,%edx
801043df:	89 c8                	mov    %ecx,%eax
801043e1:	c1 f8 1f             	sar    $0x1f,%eax
801043e4:	89 d1                	mov    %edx,%ecx
801043e6:	29 c1                	sub    %eax,%ecx
801043e8:	89 c8                	mov    %ecx,%eax
801043ea:	89 45 ec             	mov    %eax,-0x14(%ebp)
801043ed:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801043f1:	75 06                	jne    801043f9 <allocproc+0x179>
    name[0] = '0';
801043f3:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
801043f7:	eb 09                	jmp    80104402 <allocproc+0x182>
  else
    name[0] = (char)(((int)'0')+i);
801043f9:	8b 45 ec             	mov    -0x14(%ebp),%eax
801043fc:	83 c0 30             	add    $0x30,%eax
801043ff:	88 45 e4             	mov    %al,-0x1c(%ebp)
  //release(&ptable.lock);
  safestrcpy(p->swapFileName, name, sizeof(name));
80104402:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104405:	8d 90 80 00 00 00    	lea    0x80(%eax),%edx
8010440b:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
80104412:	00 
80104413:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80104416:	89 44 24 04          	mov    %eax,0x4(%esp)
8010441a:	89 14 24             	mov    %edx,(%esp)
8010441d:	e8 a0 15 00 00       	call   801059c2 <safestrcpy>
  return p;
80104422:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104425:	c9                   	leave  
80104426:	c3                   	ret    

80104427 <createInternalProcess>:


void createInternalProcess(const char *name, void (*entrypoint)())
{
80104427:	55                   	push   %ebp
80104428:	89 e5                	mov    %esp,%ebp
8010442a:	83 ec 28             	sub    $0x28,%esp
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
8010442d:	e8 4e fe ff ff       	call   80104280 <allocproc>
80104432:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104435:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104439:	0f 84 f7 00 00 00    	je     80104536 <createInternalProcess+0x10f>
    return;

  // Copy process state from p.
  if((np->pgdir = setupkvm(kalloc)) == 0)
8010443f:	c7 04 24 03 2b 10 80 	movl   $0x80102b03,(%esp)
80104446:	e8 16 43 00 00       	call   80108761 <setupkvm>
8010444b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010444e:	89 42 04             	mov    %eax,0x4(%edx)
80104451:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104454:	8b 40 04             	mov    0x4(%eax),%eax
80104457:	85 c0                	test   %eax,%eax
80104459:	75 0c                	jne    80104467 <createInternalProcess+0x40>
      panic("inswapper: out of memory?");
8010445b:	c7 04 24 84 92 10 80 	movl   $0x80109284,(%esp)
80104462:	e8 d6 c0 ff ff       	call   8010053d <panic>

  np->sz = PGSIZE;
80104467:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010446a:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  np->parent = initproc;
80104470:	8b 15 68 c6 10 80    	mov    0x8010c668,%edx
80104476:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104479:	89 50 14             	mov    %edx,0x14(%eax)
  memset(np->tf, 0, sizeof(*np->tf));
8010447c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010447f:	8b 40 18             	mov    0x18(%eax),%eax
80104482:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
80104489:	00 
8010448a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104491:	00 
80104492:	89 04 24             	mov    %eax,(%esp)
80104495:	e8 f8 12 00 00       	call   80105792 <memset>
  np->tf->cs = (SEG_KCODE << 3)|0;
8010449a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010449d:	8b 40 18             	mov    0x18(%eax),%eax
801044a0:	66 c7 40 3c 08 00    	movw   $0x8,0x3c(%eax)
  np->tf->ds = (SEG_KDATA << 3)|0;
801044a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044a9:	8b 40 18             	mov    0x18(%eax),%eax
801044ac:	66 c7 40 2c 10 00    	movw   $0x10,0x2c(%eax)
  np->tf->es = np->tf->ds;
801044b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044b5:	8b 40 18             	mov    0x18(%eax),%eax
801044b8:	8b 55 f4             	mov    -0xc(%ebp),%edx
801044bb:	8b 52 18             	mov    0x18(%edx),%edx
801044be:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
801044c2:	66 89 50 28          	mov    %dx,0x28(%eax)
  np->tf->ss = np->tf->ds;
801044c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044c9:	8b 40 18             	mov    0x18(%eax),%eax
801044cc:	8b 55 f4             	mov    -0xc(%ebp),%edx
801044cf:	8b 52 18             	mov    0x18(%edx),%edx
801044d2:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
801044d6:	66 89 50 48          	mov    %dx,0x48(%eax)
  np->tf->eflags = FL_IF;
801044da:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044dd:	8b 40 18             	mov    0x18(%eax),%eax
801044e0:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  //np->tf->esp = (uint)entrypoint+PGSIZE;
  //np->tf->eip = (uint)entrypoint;
  np->context->eip = (uint)entrypoint;
801044e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044ea:	8b 40 1c             	mov    0x1c(%eax),%eax
801044ed:	8b 55 0c             	mov    0xc(%ebp),%edx
801044f0:	89 50 10             	mov    %edx,0x10(%eax)

  inswapper = np;
801044f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044f6:	a3 6c c6 10 80       	mov    %eax,0x8010c66c
  np->cwd = namei("/");
801044fb:	c7 04 24 9e 92 10 80 	movl   $0x8010929e,(%esp)
80104502:	e8 03 df ff ff       	call   8010240a <namei>
80104507:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010450a:	89 42 68             	mov    %eax,0x68(%edx)
  safestrcpy(np->name, name, sizeof(name));
8010450d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104510:	8d 50 6c             	lea    0x6c(%eax),%edx
80104513:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
8010451a:	00 
8010451b:	8b 45 08             	mov    0x8(%ebp),%eax
8010451e:	89 44 24 04          	mov    %eax,0x4(%esp)
80104522:	89 14 24             	mov    %edx,(%esp)
80104525:	e8 98 14 00 00       	call   801059c2 <safestrcpy>
  np->state = RUNNABLE;
8010452a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010452d:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
80104534:	eb 01                	jmp    80104537 <createInternalProcess+0x110>
{
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
    return;
80104536:	90                   	nop

  inswapper = np;
  np->cwd = namei("/");
  safestrcpy(np->name, name, sizeof(name));
  np->state = RUNNABLE;
}
80104537:	c9                   	leave  
80104538:	c3                   	ret    

80104539 <swapIn>:

void swapIn()
{
80104539:	55                   	push   %ebp
8010453a:	89 e5                	mov    %esp,%ebp
8010453c:	83 ec 38             	sub    $0x38,%esp
  struct proc* t;
  for(;;)
  {
    for(t = ptable.proc; t < &ptable.proc[NPROC]; t++)
8010453f:	c7 45 f4 b4 2f 11 80 	movl   $0x80112fb4,-0xc(%ebp)
80104546:	e9 e0 01 00 00       	jmp    8010472b <swapIn+0x1f2>
    {
      if(t->state != RUNNABLE_SUSPENDED)
8010454b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010454e:	8b 40 0c             	mov    0xc(%eax),%eax
80104551:	83 f8 07             	cmp    $0x7,%eax
80104554:	0f 85 c9 01 00 00    	jne    80104723 <swapIn+0x1ea>
	continue;
      
      //open file pid.swap
      if(holding(&ptable.lock))
8010455a:	c7 04 24 80 2f 11 80 	movl   $0x80112f80,(%esp)
80104561:	e8 fc 10 00 00       	call   80105662 <holding>
80104566:	85 c0                	test   %eax,%eax
80104568:	74 0c                	je     80104576 <swapIn+0x3d>
	release(&ptable.lock);
8010456a:	c7 04 24 80 2f 11 80 	movl   $0x80112f80,(%esp)
80104571:	e8 30 10 00 00       	call   801055a6 <release>
      if((t->swap = fileopen(t->swapFileName,O_RDONLY)) == 0)
80104576:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104579:	83 e8 80             	sub    $0xffffff80,%eax
8010457c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104583:	00 
80104584:	89 04 24             	mov    %eax,(%esp)
80104587:	e8 e7 20 00 00       	call   80106673 <fileopen>
8010458c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010458f:	89 42 7c             	mov    %eax,0x7c(%edx)
80104592:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104595:	8b 40 7c             	mov    0x7c(%eax),%eax
80104598:	85 c0                	test   %eax,%eax
8010459a:	75 1d                	jne    801045b9 <swapIn+0x80>
      {
	cprintf("fileopen failed\n");
8010459c:	c7 04 24 a0 92 10 80 	movl   $0x801092a0,(%esp)
801045a3:	e8 f9 bd ff ff       	call   801003a1 <cprintf>
	acquire(&ptable.lock);
801045a8:	c7 04 24 80 2f 11 80 	movl   $0x80112f80,(%esp)
801045af:	e8 57 0f 00 00       	call   8010550b <acquire>
	break;
801045b4:	e9 7f 01 00 00       	jmp    80104738 <swapIn+0x1ff>
      }
      acquire(&ptable.lock);
801045b9:	c7 04 24 80 2f 11 80 	movl   $0x80112f80,(%esp)
801045c0:	e8 46 0f 00 00       	call   8010550b <acquire>
            
      // allocate virtual memory
      if((t->pgdir = setupkvm(kalloc)) == 0)
801045c5:	c7 04 24 03 2b 10 80 	movl   $0x80102b03,(%esp)
801045cc:	e8 90 41 00 00       	call   80108761 <setupkvm>
801045d1:	8b 55 f4             	mov    -0xc(%ebp),%edx
801045d4:	89 42 04             	mov    %eax,0x4(%edx)
801045d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045da:	8b 40 04             	mov    0x4(%eax),%eax
801045dd:	85 c0                	test   %eax,%eax
801045df:	75 0c                	jne    801045ed <swapIn+0xb4>
	panic("inswapper: out of memory?");
801045e1:	c7 04 24 84 92 10 80 	movl   $0x80109284,(%esp)
801045e8:	e8 50 bf ff ff       	call   8010053d <panic>
      if(!allocuvm(t->pgdir, 0, t->sz))
801045ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045f0:	8b 10                	mov    (%eax),%edx
801045f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045f5:	8b 40 04             	mov    0x4(%eax),%eax
801045f8:	89 54 24 08          	mov    %edx,0x8(%esp)
801045fc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104603:	00 
80104604:	89 04 24             	mov    %eax,(%esp)
80104607:	e8 27 45 00 00       	call   80108b33 <allocuvm>
8010460c:	85 c0                	test   %eax,%eax
8010460e:	75 11                	jne    80104621 <swapIn+0xe8>
      {
	cprintf("allocuvm failed\n");
80104610:	c7 04 24 b1 92 10 80 	movl   $0x801092b1,(%esp)
80104617:	e8 85 bd ff ff       	call   801003a1 <cprintf>
	break;
8010461c:	e9 17 01 00 00       	jmp    80104738 <swapIn+0x1ff>
      }
      
      if(holding(&ptable.lock))
80104621:	c7 04 24 80 2f 11 80 	movl   $0x80112f80,(%esp)
80104628:	e8 35 10 00 00       	call   80105662 <holding>
8010462d:	85 c0                	test   %eax,%eax
8010462f:	74 0c                	je     8010463d <swapIn+0x104>
	release(&ptable.lock);
80104631:	c7 04 24 80 2f 11 80 	movl   $0x80112f80,(%esp)
80104638:	e8 69 0f 00 00       	call   801055a6 <release>
      loaduvm(t->pgdir,0,t->swap->ip,0,t->sz);
8010463d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104640:	8b 08                	mov    (%eax),%ecx
80104642:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104645:	8b 40 7c             	mov    0x7c(%eax),%eax
80104648:	8b 50 10             	mov    0x10(%eax),%edx
8010464b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010464e:	8b 40 04             	mov    0x4(%eax),%eax
80104651:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80104655:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
8010465c:	00 
8010465d:	89 54 24 08          	mov    %edx,0x8(%esp)
80104661:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104668:	00 
80104669:	89 04 24             	mov    %eax,(%esp)
8010466c:	e8 d3 43 00 00       	call   80108a44 <loaduvm>
      
      t->isSwapped = 0;
80104671:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104674:	c7 80 88 00 00 00 00 	movl   $0x0,0x88(%eax)
8010467b:	00 00 00 
      int fd;
      for(fd = 0; fd < NOFILE; fd++)
8010467e:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80104685:	eb 63                	jmp    801046ea <swapIn+0x1b1>
      {
	if(proc->ofile[fd] && proc->ofile[fd] == proc->swap)
80104687:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010468d:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104690:	83 c2 08             	add    $0x8,%edx
80104693:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104697:	85 c0                	test   %eax,%eax
80104699:	74 4b                	je     801046e6 <swapIn+0x1ad>
8010469b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801046a1:	8b 55 f0             	mov    -0x10(%ebp),%edx
801046a4:	83 c2 08             	add    $0x8,%edx
801046a7:	8b 54 90 08          	mov    0x8(%eax,%edx,4),%edx
801046ab:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801046b1:	8b 40 7c             	mov    0x7c(%eax),%eax
801046b4:	39 c2                	cmp    %eax,%edx
801046b6:	75 2e                	jne    801046e6 <swapIn+0x1ad>
	{
	  fileclose(proc->ofile[fd]);
801046b8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801046be:	8b 55 f0             	mov    -0x10(%ebp),%edx
801046c1:	83 c2 08             	add    $0x8,%edx
801046c4:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801046c8:	89 04 24             	mov    %eax,(%esp)
801046cb:	e8 f4 c8 ff ff       	call   80100fc4 <fileclose>
	  proc->ofile[fd] = 0;
801046d0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801046d6:	8b 55 f0             	mov    -0x10(%ebp),%edx
801046d9:	83 c2 08             	add    $0x8,%edx
801046dc:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
801046e3:	00 
	  break;
801046e4:	eb 0a                	jmp    801046f0 <swapIn+0x1b7>
	release(&ptable.lock);
      loaduvm(t->pgdir,0,t->swap->ip,0,t->sz);
      
      t->isSwapped = 0;
      int fd;
      for(fd = 0; fd < NOFILE; fd++)
801046e6:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
801046ea:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
801046ee:	7e 97                	jle    80104687 <swapIn+0x14e>
	  fileclose(proc->ofile[fd]);
	  proc->ofile[fd] = 0;
	  break;
	}
      }
      proc->swap=0;
801046f0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801046f6:	c7 40 7c 00 00 00 00 	movl   $0x0,0x7c(%eax)
      unlink(t->swapFileName);
801046fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104700:	83 e8 80             	sub    $0xffffff80,%eax
80104703:	89 04 24             	mov    %eax,(%esp)
80104706:	e8 23 1a 00 00       	call   8010612e <unlink>
      acquire(&ptable.lock);
8010470b:	c7 04 24 80 2f 11 80 	movl   $0x80112f80,(%esp)
80104712:	e8 f4 0d 00 00       	call   8010550b <acquire>
      //cprintf("eip = %d\n",t->tf->eip);
      t->state = RUNNABLE;
80104717:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010471a:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
80104721:	eb 01                	jmp    80104724 <swapIn+0x1eb>
  for(;;)
  {
    for(t = ptable.proc; t < &ptable.proc[NPROC]; t++)
    {
      if(t->state != RUNNABLE_SUSPENDED)
	continue;
80104723:	90                   	nop
void swapIn()
{
  struct proc* t;
  for(;;)
  {
    for(t = ptable.proc; t < &ptable.proc[NPROC]; t++)
80104724:	81 45 f4 8c 00 00 00 	addl   $0x8c,-0xc(%ebp)
8010472b:	81 7d f4 b4 52 11 80 	cmpl   $0x801152b4,-0xc(%ebp)
80104732:	0f 82 13 fe ff ff    	jb     8010454b <swapIn+0x12>
      unlink(t->swapFileName);
      acquire(&ptable.lock);
      //cprintf("eip = %d\n",t->tf->eip);
      t->state = RUNNABLE;
    }
    proc->chan = inswapper;
80104738:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010473e:	8b 15 6c c6 10 80    	mov    0x8010c66c,%edx
80104744:	89 50 20             	mov    %edx,0x20(%eax)
    proc->state = SLEEPING;
80104747:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010474d:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
    sched();
80104754:	e8 66 08 00 00       	call   80104fbf <sched>
    proc->chan = 0;
80104759:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010475f:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)
  }
80104766:	e9 d4 fd ff ff       	jmp    8010453f <swapIn+0x6>

8010476b <swapOut>:
}

void
swapOut()
{
8010476b:	55                   	push   %ebp
8010476c:	89 e5                	mov    %esp,%ebp
8010476e:	53                   	push   %ebx
8010476f:	83 ec 24             	sub    $0x24,%esp
    proc->swap = fileopen(proc->swapFileName,(O_CREATE | O_RDWR));
80104772:	65 8b 1d 04 00 00 00 	mov    %gs:0x4,%ebx
80104779:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010477f:	83 e8 80             	sub    $0xffffff80,%eax
80104782:	c7 44 24 04 02 02 00 	movl   $0x202,0x4(%esp)
80104789:	00 
8010478a:	89 04 24             	mov    %eax,(%esp)
8010478d:	e8 e1 1e 00 00       	call   80106673 <fileopen>
80104792:	89 43 7c             	mov    %eax,0x7c(%ebx)
    pte_t *pte;
    uint pa, j;
    for(j = 0; j < proc->sz; j += PGSIZE)
80104795:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010479c:	e9 9a 00 00 00       	jmp    8010483b <swapOut+0xd0>
    {
      if((pte = walkpgdir(proc->pgdir, (void *) j, 0)) == 0)
801047a1:	8b 55 f4             	mov    -0xc(%ebp),%edx
801047a4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047aa:	8b 40 04             	mov    0x4(%eax),%eax
801047ad:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801047b4:	00 
801047b5:	89 54 24 04          	mov    %edx,0x4(%esp)
801047b9:	89 04 24             	mov    %eax,(%esp)
801047bc:	e8 76 3e 00 00       	call   80108637 <walkpgdir>
801047c1:	89 45 ec             	mov    %eax,-0x14(%ebp)
801047c4:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801047c8:	75 0c                	jne    801047d6 <swapOut+0x6b>
	panic("walkpgdir: pte should exist");
801047ca:	c7 04 24 c2 92 10 80 	movl   $0x801092c2,(%esp)
801047d1:	e8 67 bd ff ff       	call   8010053d <panic>
      if(!(*pte & PTE_P))
801047d6:	8b 45 ec             	mov    -0x14(%ebp),%eax
801047d9:	8b 00                	mov    (%eax),%eax
801047db:	83 e0 01             	and    $0x1,%eax
801047de:	85 c0                	test   %eax,%eax
801047e0:	75 0c                	jne    801047ee <swapOut+0x83>
	panic("walkpgdir: page not present");
801047e2:	c7 04 24 de 92 10 80 	movl   $0x801092de,(%esp)
801047e9:	e8 4f bd ff ff       	call   8010053d <panic>
      pa = PTE_ADDR(*pte);
801047ee:	8b 45 ec             	mov    -0x14(%ebp),%eax
801047f1:	8b 00                	mov    (%eax),%eax
801047f3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801047f8:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(filewrite(proc->swap, (char*)p2v(pa), PGSIZE) < 0)
801047fb:	8b 45 e8             	mov    -0x18(%ebp),%eax
801047fe:	89 04 24             	mov    %eax,(%esp)
80104801:	e8 36 fa ff ff       	call   8010423c <p2v>
80104806:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
8010480d:	8b 52 7c             	mov    0x7c(%edx),%edx
80104810:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80104817:	00 
80104818:	89 44 24 04          	mov    %eax,0x4(%esp)
8010481c:	89 14 24             	mov    %edx,(%esp)
8010481f:	e8 81 c9 ff ff       	call   801011a5 <filewrite>
80104824:	85 c0                	test   %eax,%eax
80104826:	79 0c                	jns    80104834 <swapOut+0xc9>
	panic("filewrite failed");
80104828:	c7 04 24 fa 92 10 80 	movl   $0x801092fa,(%esp)
8010482f:	e8 09 bd ff ff       	call   8010053d <panic>
swapOut()
{
    proc->swap = fileopen(proc->swapFileName,(O_CREATE | O_RDWR));
    pte_t *pte;
    uint pa, j;
    for(j = 0; j < proc->sz; j += PGSIZE)
80104834:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
8010483b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104841:	8b 00                	mov    (%eax),%eax
80104843:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104846:	0f 87 55 ff ff ff    	ja     801047a1 <swapOut+0x36>
      if(filewrite(proc->swap, (char*)p2v(pa), PGSIZE) < 0)
	panic("filewrite failed");
    }

    int fd;
    for(fd = 0; fd < NOFILE; fd++)
8010484c:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80104853:	eb 63                	jmp    801048b8 <swapOut+0x14d>
    {
      if(proc->ofile[fd] && proc->ofile[fd] == proc->swap)
80104855:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010485b:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010485e:	83 c2 08             	add    $0x8,%edx
80104861:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104865:	85 c0                	test   %eax,%eax
80104867:	74 4b                	je     801048b4 <swapOut+0x149>
80104869:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010486f:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104872:	83 c2 08             	add    $0x8,%edx
80104875:	8b 54 90 08          	mov    0x8(%eax,%edx,4),%edx
80104879:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010487f:	8b 40 7c             	mov    0x7c(%eax),%eax
80104882:	39 c2                	cmp    %eax,%edx
80104884:	75 2e                	jne    801048b4 <swapOut+0x149>
      {
	fileclose(proc->ofile[fd]);
80104886:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010488c:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010488f:	83 c2 08             	add    $0x8,%edx
80104892:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104896:	89 04 24             	mov    %eax,(%esp)
80104899:	e8 26 c7 ff ff       	call   80100fc4 <fileclose>
	proc->ofile[fd] = 0;
8010489e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048a4:	8b 55 f0             	mov    -0x10(%ebp),%edx
801048a7:	83 c2 08             	add    $0x8,%edx
801048aa:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
801048b1:	00 
	break;
801048b2:	eb 0a                	jmp    801048be <swapOut+0x153>
      if(filewrite(proc->swap, (char*)p2v(pa), PGSIZE) < 0)
	panic("filewrite failed");
    }

    int fd;
    for(fd = 0; fd < NOFILE; fd++)
801048b4:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
801048b8:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
801048bc:	7e 97                	jle    80104855 <swapOut+0xea>
	fileclose(proc->ofile[fd]);
	proc->ofile[fd] = 0;
	break;
      }
    }
    proc->swap=0;
801048be:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048c4:	c7 40 7c 00 00 00 00 	movl   $0x0,0x7c(%eax)
    //freevm(proc->pgdir);
    deallocuvm(proc->pgdir,proc->sz,0);
801048cb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048d1:	8b 10                	mov    (%eax),%edx
801048d3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048d9:	8b 40 04             	mov    0x4(%eax),%eax
801048dc:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801048e3:	00 
801048e4:	89 54 24 04          	mov    %edx,0x4(%esp)
801048e8:	89 04 24             	mov    %eax,(%esp)
801048eb:	e8 1d 43 00 00       	call   80108c0d <deallocuvm>
    proc->state = SLEEPING_SUSPENDED;
801048f0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048f6:	c7 40 0c 06 00 00 00 	movl   $0x6,0xc(%eax)
    proc->isSwapped = 1;
801048fd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104903:	c7 80 88 00 00 00 01 	movl   $0x1,0x88(%eax)
8010490a:	00 00 00 
}
8010490d:	83 c4 24             	add    $0x24,%esp
80104910:	5b                   	pop    %ebx
80104911:	5d                   	pop    %ebp
80104912:	c3                   	ret    

80104913 <userinit>:

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
80104913:	55                   	push   %ebp
80104914:	89 e5                	mov    %esp,%ebp
80104916:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
80104919:	e8 62 f9 ff ff       	call   80104280 <allocproc>
8010491e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  initproc = p;
80104921:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104924:	a3 68 c6 10 80       	mov    %eax,0x8010c668
  if((p->pgdir = setupkvm(kalloc)) == 0)
80104929:	c7 04 24 03 2b 10 80 	movl   $0x80102b03,(%esp)
80104930:	e8 2c 3e 00 00       	call   80108761 <setupkvm>
80104935:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104938:	89 42 04             	mov    %eax,0x4(%edx)
8010493b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010493e:	8b 40 04             	mov    0x4(%eax),%eax
80104941:	85 c0                	test   %eax,%eax
80104943:	75 0c                	jne    80104951 <userinit+0x3e>
    panic("userinit: out of memory?");
80104945:	c7 04 24 0b 93 10 80 	movl   $0x8010930b,(%esp)
8010494c:	e8 ec bb ff ff       	call   8010053d <panic>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80104951:	ba 2c 00 00 00       	mov    $0x2c,%edx
80104956:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104959:	8b 40 04             	mov    0x4(%eax),%eax
8010495c:	89 54 24 08          	mov    %edx,0x8(%esp)
80104960:	c7 44 24 04 00 c5 10 	movl   $0x8010c500,0x4(%esp)
80104967:	80 
80104968:	89 04 24             	mov    %eax,(%esp)
8010496b:	e8 49 40 00 00       	call   801089b9 <inituvm>
  p->sz = PGSIZE;
80104970:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104973:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  memset(p->tf, 0, sizeof(*p->tf));
80104979:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010497c:	8b 40 18             	mov    0x18(%eax),%eax
8010497f:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
80104986:	00 
80104987:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010498e:	00 
8010498f:	89 04 24             	mov    %eax,(%esp)
80104992:	e8 fb 0d 00 00       	call   80105792 <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
80104997:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010499a:	8b 40 18             	mov    0x18(%eax),%eax
8010499d:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
801049a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049a6:	8b 40 18             	mov    0x18(%eax),%eax
801049a9:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
  p->tf->es = p->tf->ds;
801049af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049b2:	8b 40 18             	mov    0x18(%eax),%eax
801049b5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801049b8:	8b 52 18             	mov    0x18(%edx),%edx
801049bb:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
801049bf:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
801049c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049c6:	8b 40 18             	mov    0x18(%eax),%eax
801049c9:	8b 55 f4             	mov    -0xc(%ebp),%edx
801049cc:	8b 52 18             	mov    0x18(%edx),%edx
801049cf:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
801049d3:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
801049d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049da:	8b 40 18             	mov    0x18(%eax),%eax
801049dd:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
801049e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049e7:	8b 40 18             	mov    0x18(%eax),%eax
801049ea:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
801049f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049f4:	8b 40 18             	mov    0x18(%eax),%eax
801049f7:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
801049fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a01:	83 c0 6c             	add    $0x6c,%eax
80104a04:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104a0b:	00 
80104a0c:	c7 44 24 04 24 93 10 	movl   $0x80109324,0x4(%esp)
80104a13:	80 
80104a14:	89 04 24             	mov    %eax,(%esp)
80104a17:	e8 a6 0f 00 00       	call   801059c2 <safestrcpy>
  p->cwd = namei("/");
80104a1c:	c7 04 24 9e 92 10 80 	movl   $0x8010929e,(%esp)
80104a23:	e8 e2 d9 ff ff       	call   8010240a <namei>
80104a28:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104a2b:	89 42 68             	mov    %eax,0x68(%edx)

  p->state = RUNNABLE;
80104a2e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a31:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)

  createInternalProcess("inswapper", swapIn);
80104a38:	c7 44 24 04 39 45 10 	movl   $0x80104539,0x4(%esp)
80104a3f:	80 
80104a40:	c7 04 24 2d 93 10 80 	movl   $0x8010932d,(%esp)
80104a47:	e8 db f9 ff ff       	call   80104427 <createInternalProcess>
}
80104a4c:	c9                   	leave  
80104a4d:	c3                   	ret    

80104a4e <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
80104a4e:	55                   	push   %ebp
80104a4f:	89 e5                	mov    %esp,%ebp
80104a51:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  
  sz = proc->sz;
80104a54:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104a5a:	8b 00                	mov    (%eax),%eax
80104a5c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
80104a5f:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80104a63:	7e 34                	jle    80104a99 <growproc+0x4b>
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
80104a65:	8b 45 08             	mov    0x8(%ebp),%eax
80104a68:	89 c2                	mov    %eax,%edx
80104a6a:	03 55 f4             	add    -0xc(%ebp),%edx
80104a6d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104a73:	8b 40 04             	mov    0x4(%eax),%eax
80104a76:	89 54 24 08          	mov    %edx,0x8(%esp)
80104a7a:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104a7d:	89 54 24 04          	mov    %edx,0x4(%esp)
80104a81:	89 04 24             	mov    %eax,(%esp)
80104a84:	e8 aa 40 00 00       	call   80108b33 <allocuvm>
80104a89:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104a8c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104a90:	75 41                	jne    80104ad3 <growproc+0x85>
      return -1;
80104a92:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104a97:	eb 58                	jmp    80104af1 <growproc+0xa3>
  } else if(n < 0){
80104a99:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80104a9d:	79 34                	jns    80104ad3 <growproc+0x85>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
80104a9f:	8b 45 08             	mov    0x8(%ebp),%eax
80104aa2:	89 c2                	mov    %eax,%edx
80104aa4:	03 55 f4             	add    -0xc(%ebp),%edx
80104aa7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104aad:	8b 40 04             	mov    0x4(%eax),%eax
80104ab0:	89 54 24 08          	mov    %edx,0x8(%esp)
80104ab4:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104ab7:	89 54 24 04          	mov    %edx,0x4(%esp)
80104abb:	89 04 24             	mov    %eax,(%esp)
80104abe:	e8 4a 41 00 00       	call   80108c0d <deallocuvm>
80104ac3:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104ac6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104aca:	75 07                	jne    80104ad3 <growproc+0x85>
      return -1;
80104acc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ad1:	eb 1e                	jmp    80104af1 <growproc+0xa3>
  }
  proc->sz = sz;
80104ad3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ad9:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104adc:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
80104ade:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ae4:	89 04 24             	mov    %eax,(%esp)
80104ae7:	e8 66 3d 00 00       	call   80108852 <switchuvm>
  return 0;
80104aec:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104af1:	c9                   	leave  
80104af2:	c3                   	ret    

80104af3 <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
80104af3:	55                   	push   %ebp
80104af4:	89 e5                	mov    %esp,%ebp
80104af6:	57                   	push   %edi
80104af7:	56                   	push   %esi
80104af8:	53                   	push   %ebx
80104af9:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
80104afc:	e8 7f f7 ff ff       	call   80104280 <allocproc>
80104b01:	89 45 e0             	mov    %eax,-0x20(%ebp)
80104b04:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80104b08:	75 0a                	jne    80104b14 <fork+0x21>
    return -1;
80104b0a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b0f:	e9 3a 01 00 00       	jmp    80104c4e <fork+0x15b>
  
  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
80104b14:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b1a:	8b 10                	mov    (%eax),%edx
80104b1c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b22:	8b 40 04             	mov    0x4(%eax),%eax
80104b25:	89 54 24 04          	mov    %edx,0x4(%esp)
80104b29:	89 04 24             	mov    %eax,(%esp)
80104b2c:	e8 6c 42 00 00       	call   80108d9d <copyuvm>
80104b31:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104b34:	89 42 04             	mov    %eax,0x4(%edx)
80104b37:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104b3a:	8b 40 04             	mov    0x4(%eax),%eax
80104b3d:	85 c0                	test   %eax,%eax
80104b3f:	75 2c                	jne    80104b6d <fork+0x7a>
    kfree(np->kstack);
80104b41:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104b44:	8b 40 08             	mov    0x8(%eax),%eax
80104b47:	89 04 24             	mov    %eax,(%esp)
80104b4a:	e8 1b df ff ff       	call   80102a6a <kfree>
    np->kstack = 0;
80104b4f:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104b52:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
80104b59:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104b5c:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
80104b63:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b68:	e9 e1 00 00 00       	jmp    80104c4e <fork+0x15b>
  }
  np->sz = proc->sz;
80104b6d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b73:	8b 10                	mov    (%eax),%edx
80104b75:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104b78:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
80104b7a:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104b81:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104b84:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *proc->tf;
80104b87:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104b8a:	8b 50 18             	mov    0x18(%eax),%edx
80104b8d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b93:	8b 40 18             	mov    0x18(%eax),%eax
80104b96:	89 c3                	mov    %eax,%ebx
80104b98:	b8 13 00 00 00       	mov    $0x13,%eax
80104b9d:	89 d7                	mov    %edx,%edi
80104b9f:	89 de                	mov    %ebx,%esi
80104ba1:	89 c1                	mov    %eax,%ecx
80104ba3:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
80104ba5:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104ba8:	8b 40 18             	mov    0x18(%eax),%eax
80104bab:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
80104bb2:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80104bb9:	eb 3d                	jmp    80104bf8 <fork+0x105>
    if(proc->ofile[i])
80104bbb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104bc1:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104bc4:	83 c2 08             	add    $0x8,%edx
80104bc7:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104bcb:	85 c0                	test   %eax,%eax
80104bcd:	74 25                	je     80104bf4 <fork+0x101>
      np->ofile[i] = filedup(proc->ofile[i]);
80104bcf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104bd5:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104bd8:	83 c2 08             	add    $0x8,%edx
80104bdb:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104bdf:	89 04 24             	mov    %eax,(%esp)
80104be2:	e8 95 c3 ff ff       	call   80100f7c <filedup>
80104be7:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104bea:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80104bed:	83 c1 08             	add    $0x8,%ecx
80104bf0:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
80104bf4:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80104bf8:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
80104bfc:	7e bd                	jle    80104bbb <fork+0xc8>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
80104bfe:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c04:	8b 40 68             	mov    0x68(%eax),%eax
80104c07:	89 04 24             	mov    %eax,(%esp)
80104c0a:	e8 27 cc ff ff       	call   80101836 <idup>
80104c0f:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104c12:	89 42 68             	mov    %eax,0x68(%edx)
 
  pid = np->pid;
80104c15:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104c18:	8b 40 10             	mov    0x10(%eax),%eax
80104c1b:	89 45 dc             	mov    %eax,-0x24(%ebp)
  np->state = RUNNABLE;
80104c1e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104c21:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  safestrcpy(np->name, proc->name, sizeof(proc->name));
80104c28:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c2e:	8d 50 6c             	lea    0x6c(%eax),%edx
80104c31:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104c34:	83 c0 6c             	add    $0x6c,%eax
80104c37:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104c3e:	00 
80104c3f:	89 54 24 04          	mov    %edx,0x4(%esp)
80104c43:	89 04 24             	mov    %eax,(%esp)
80104c46:	e8 77 0d 00 00       	call   801059c2 <safestrcpy>
  return pid;
80104c4b:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
80104c4e:	83 c4 2c             	add    $0x2c,%esp
80104c51:	5b                   	pop    %ebx
80104c52:	5e                   	pop    %esi
80104c53:	5f                   	pop    %edi
80104c54:	5d                   	pop    %ebp
80104c55:	c3                   	ret    

80104c56 <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
80104c56:	55                   	push   %ebp
80104c57:	89 e5                	mov    %esp,%ebp
80104c59:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int fd;

  if(proc == initproc)
80104c5c:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104c63:	a1 68 c6 10 80       	mov    0x8010c668,%eax
80104c68:	39 c2                	cmp    %eax,%edx
80104c6a:	75 0c                	jne    80104c78 <exit+0x22>
    panic("init exiting");
80104c6c:	c7 04 24 37 93 10 80 	movl   $0x80109337,(%esp)
80104c73:	e8 c5 b8 ff ff       	call   8010053d <panic>

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80104c78:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80104c7f:	eb 44                	jmp    80104cc5 <exit+0x6f>
    if(proc->ofile[fd]){
80104c81:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c87:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104c8a:	83 c2 08             	add    $0x8,%edx
80104c8d:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104c91:	85 c0                	test   %eax,%eax
80104c93:	74 2c                	je     80104cc1 <exit+0x6b>
      fileclose(proc->ofile[fd]);
80104c95:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c9b:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104c9e:	83 c2 08             	add    $0x8,%edx
80104ca1:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104ca5:	89 04 24             	mov    %eax,(%esp)
80104ca8:	e8 17 c3 ff ff       	call   80100fc4 <fileclose>
      proc->ofile[fd] = 0;
80104cad:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104cb3:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104cb6:	83 c2 08             	add    $0x8,%edx
80104cb9:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80104cc0:	00 

  if(proc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80104cc1:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80104cc5:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
80104cc9:	7e b6                	jle    80104c81 <exit+0x2b>
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  iput(proc->cwd);
80104ccb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104cd1:	8b 40 68             	mov    0x68(%eax),%eax
80104cd4:	89 04 24             	mov    %eax,(%esp)
80104cd7:	e8 3f cd ff ff       	call   80101a1b <iput>
  proc->cwd = 0;
80104cdc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ce2:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)

  acquire(&ptable.lock);
80104ce9:	c7 04 24 80 2f 11 80 	movl   $0x80112f80,(%esp)
80104cf0:	e8 16 08 00 00       	call   8010550b <acquire>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);
80104cf5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104cfb:	8b 40 14             	mov    0x14(%eax),%eax
80104cfe:	89 04 24             	mov    %eax,(%esp)
80104d01:	e8 98 04 00 00       	call   8010519e <wakeup1>

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104d06:	c7 45 f4 b4 2f 11 80 	movl   $0x80112fb4,-0xc(%ebp)
80104d0d:	eb 3b                	jmp    80104d4a <exit+0xf4>
    if(p->parent == proc){
80104d0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d12:	8b 50 14             	mov    0x14(%eax),%edx
80104d15:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d1b:	39 c2                	cmp    %eax,%edx
80104d1d:	75 24                	jne    80104d43 <exit+0xed>
      p->parent = initproc;
80104d1f:	8b 15 68 c6 10 80    	mov    0x8010c668,%edx
80104d25:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d28:	89 50 14             	mov    %edx,0x14(%eax)
      if(p->state == ZOMBIE)
80104d2b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d2e:	8b 40 0c             	mov    0xc(%eax),%eax
80104d31:	83 f8 05             	cmp    $0x5,%eax
80104d34:	75 0d                	jne    80104d43 <exit+0xed>
        wakeup1(initproc);
80104d36:	a1 68 c6 10 80       	mov    0x8010c668,%eax
80104d3b:	89 04 24             	mov    %eax,(%esp)
80104d3e:	e8 5b 04 00 00       	call   8010519e <wakeup1>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104d43:	81 45 f4 8c 00 00 00 	addl   $0x8c,-0xc(%ebp)
80104d4a:	81 7d f4 b4 52 11 80 	cmpl   $0x801152b4,-0xc(%ebp)
80104d51:	72 bc                	jb     80104d0f <exit+0xb9>
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  proc->state = ZOMBIE;
80104d53:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d59:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
  sched();
80104d60:	e8 5a 02 00 00       	call   80104fbf <sched>
  panic("zombie exit");
80104d65:	c7 04 24 44 93 10 80 	movl   $0x80109344,(%esp)
80104d6c:	e8 cc b7 ff ff       	call   8010053d <panic>

80104d71 <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
80104d71:	55                   	push   %ebp
80104d72:	89 e5                	mov    %esp,%ebp
80104d74:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
80104d77:	c7 04 24 80 2f 11 80 	movl   $0x80112f80,(%esp)
80104d7e:	e8 88 07 00 00       	call   8010550b <acquire>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
80104d83:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104d8a:	c7 45 f4 b4 2f 11 80 	movl   $0x80112fb4,-0xc(%ebp)
80104d91:	e9 9d 00 00 00       	jmp    80104e33 <wait+0xc2>
      if(p->parent != proc)
80104d96:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d99:	8b 50 14             	mov    0x14(%eax),%edx
80104d9c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104da2:	39 c2                	cmp    %eax,%edx
80104da4:	0f 85 81 00 00 00    	jne    80104e2b <wait+0xba>
        continue;
      havekids = 1;
80104daa:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
      if(p->state == ZOMBIE){
80104db1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104db4:	8b 40 0c             	mov    0xc(%eax),%eax
80104db7:	83 f8 05             	cmp    $0x5,%eax
80104dba:	75 70                	jne    80104e2c <wait+0xbb>
        // Found one.
        pid = p->pid;
80104dbc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104dbf:	8b 40 10             	mov    0x10(%eax),%eax
80104dc2:	89 45 ec             	mov    %eax,-0x14(%ebp)
        kfree(p->kstack);
80104dc5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104dc8:	8b 40 08             	mov    0x8(%eax),%eax
80104dcb:	89 04 24             	mov    %eax,(%esp)
80104dce:	e8 97 dc ff ff       	call   80102a6a <kfree>
        p->kstack = 0;
80104dd3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104dd6:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
        freevm(p->pgdir);
80104ddd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104de0:	8b 40 04             	mov    0x4(%eax),%eax
80104de3:	89 04 24             	mov    %eax,(%esp)
80104de6:	e8 de 3e 00 00       	call   80108cc9 <freevm>
        p->state = UNUSED;
80104deb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104dee:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        p->pid = 0;
80104df5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104df8:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
        p->parent = 0;
80104dff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e02:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
        p->name[0] = 0;
80104e09:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e0c:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)
        p->killed = 0;
80104e10:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e13:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
        release(&ptable.lock);
80104e1a:	c7 04 24 80 2f 11 80 	movl   $0x80112f80,(%esp)
80104e21:	e8 80 07 00 00       	call   801055a6 <release>
        return pid;
80104e26:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104e29:	eb 56                	jmp    80104e81 <wait+0x110>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->parent != proc)
        continue;
80104e2b:	90                   	nop

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104e2c:	81 45 f4 8c 00 00 00 	addl   $0x8c,-0xc(%ebp)
80104e33:	81 7d f4 b4 52 11 80 	cmpl   $0x801152b4,-0xc(%ebp)
80104e3a:	0f 82 56 ff ff ff    	jb     80104d96 <wait+0x25>
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
80104e40:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80104e44:	74 0d                	je     80104e53 <wait+0xe2>
80104e46:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e4c:	8b 40 24             	mov    0x24(%eax),%eax
80104e4f:	85 c0                	test   %eax,%eax
80104e51:	74 13                	je     80104e66 <wait+0xf5>
      release(&ptable.lock);
80104e53:	c7 04 24 80 2f 11 80 	movl   $0x80112f80,(%esp)
80104e5a:	e8 47 07 00 00       	call   801055a6 <release>
      return -1;
80104e5f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e64:	eb 1b                	jmp    80104e81 <wait+0x110>
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
80104e66:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e6c:	c7 44 24 04 80 2f 11 	movl   $0x80112f80,0x4(%esp)
80104e73:	80 
80104e74:	89 04 24             	mov    %eax,(%esp)
80104e77:	e8 53 02 00 00       	call   801050cf <sleep>
  }
80104e7c:	e9 02 ff ff ff       	jmp    80104d83 <wait+0x12>
}
80104e81:	c9                   	leave  
80104e82:	c3                   	ret    

80104e83 <register_handler>:

void
register_handler(sighandler_t sighandler)
{
80104e83:	55                   	push   %ebp
80104e84:	89 e5                	mov    %esp,%ebp
80104e86:	83 ec 28             	sub    $0x28,%esp
  char* addr = uva2ka(proc->pgdir, (char*)proc->tf->esp);
80104e89:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e8f:	8b 40 18             	mov    0x18(%eax),%eax
80104e92:	8b 40 44             	mov    0x44(%eax),%eax
80104e95:	89 c2                	mov    %eax,%edx
80104e97:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e9d:	8b 40 04             	mov    0x4(%eax),%eax
80104ea0:	89 54 24 04          	mov    %edx,0x4(%esp)
80104ea4:	89 04 24             	mov    %eax,(%esp)
80104ea7:	e8 02 40 00 00       	call   80108eae <uva2ka>
80104eac:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if ((proc->tf->esp & 0xFFF) == 0)
80104eaf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104eb5:	8b 40 18             	mov    0x18(%eax),%eax
80104eb8:	8b 40 44             	mov    0x44(%eax),%eax
80104ebb:	25 ff 0f 00 00       	and    $0xfff,%eax
80104ec0:	85 c0                	test   %eax,%eax
80104ec2:	75 0c                	jne    80104ed0 <register_handler+0x4d>
    panic("esp_offset == 0");
80104ec4:	c7 04 24 50 93 10 80 	movl   $0x80109350,(%esp)
80104ecb:	e8 6d b6 ff ff       	call   8010053d <panic>

    /* open a new frame */
  *(int*)(addr + ((proc->tf->esp - 4) & 0xFFF))
80104ed0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ed6:	8b 40 18             	mov    0x18(%eax),%eax
80104ed9:	8b 40 44             	mov    0x44(%eax),%eax
80104edc:	83 e8 04             	sub    $0x4,%eax
80104edf:	25 ff 0f 00 00       	and    $0xfff,%eax
80104ee4:	03 45 f4             	add    -0xc(%ebp),%eax
          = proc->tf->eip;
80104ee7:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104eee:	8b 52 18             	mov    0x18(%edx),%edx
80104ef1:	8b 52 38             	mov    0x38(%edx),%edx
80104ef4:	89 10                	mov    %edx,(%eax)
  proc->tf->esp -= 4;
80104ef6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104efc:	8b 40 18             	mov    0x18(%eax),%eax
80104eff:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104f06:	8b 52 18             	mov    0x18(%edx),%edx
80104f09:	8b 52 44             	mov    0x44(%edx),%edx
80104f0c:	83 ea 04             	sub    $0x4,%edx
80104f0f:	89 50 44             	mov    %edx,0x44(%eax)

    /* update eip */
  proc->tf->eip = (uint)sighandler;
80104f12:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f18:	8b 40 18             	mov    0x18(%eax),%eax
80104f1b:	8b 55 08             	mov    0x8(%ebp),%edx
80104f1e:	89 50 38             	mov    %edx,0x38(%eax)
}
80104f21:	c9                   	leave  
80104f22:	c3                   	ret    

80104f23 <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
80104f23:	55                   	push   %ebp
80104f24:	89 e5                	mov    %esp,%ebp
80104f26:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  
  for(;;){
    // Enable interrupts on this processor.
    sti();
80104f29:	e8 30 f3 ff ff       	call   8010425e <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
80104f2e:	c7 04 24 80 2f 11 80 	movl   $0x80112f80,(%esp)
80104f35:	e8 d1 05 00 00       	call   8010550b <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104f3a:	c7 45 f4 b4 2f 11 80 	movl   $0x80112fb4,-0xc(%ebp)
80104f41:	eb 62                	jmp    80104fa5 <scheduler+0x82>
      if(p->state != RUNNABLE)
80104f43:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f46:	8b 40 0c             	mov    0xc(%eax),%eax
80104f49:	83 f8 03             	cmp    $0x3,%eax
80104f4c:	75 4f                	jne    80104f9d <scheduler+0x7a>
        continue;
    
      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
80104f4e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f51:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
      switchuvm(p);
80104f57:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f5a:	89 04 24             	mov    %eax,(%esp)
80104f5d:	e8 f0 38 00 00       	call   80108852 <switchuvm>
      p->state = RUNNING;
80104f62:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f65:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      swtch(&cpu->scheduler, proc->context);
80104f6c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f72:	8b 40 1c             	mov    0x1c(%eax),%eax
80104f75:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80104f7c:	83 c2 04             	add    $0x4,%edx
80104f7f:	89 44 24 04          	mov    %eax,0x4(%esp)
80104f83:	89 14 24             	mov    %edx,(%esp)
80104f86:	e8 ad 0a 00 00       	call   80105a38 <swtch>
      switchkvm();
80104f8b:	e8 a5 38 00 00       	call   80108835 <switchkvm>
                 
      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
80104f90:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80104f97:	00 00 00 00 
80104f9b:	eb 01                	jmp    80104f9e <scheduler+0x7b>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->state != RUNNABLE)
        continue;
80104f9d:	90                   	nop
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104f9e:	81 45 f4 8c 00 00 00 	addl   $0x8c,-0xc(%ebp)
80104fa5:	81 7d f4 b4 52 11 80 	cmpl   $0x801152b4,-0xc(%ebp)
80104fac:	72 95                	jb     80104f43 <scheduler+0x20>
                 
      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
80104fae:	c7 04 24 80 2f 11 80 	movl   $0x80112f80,(%esp)
80104fb5:	e8 ec 05 00 00       	call   801055a6 <release>

  }
80104fba:	e9 6a ff ff ff       	jmp    80104f29 <scheduler+0x6>

80104fbf <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
80104fbf:	55                   	push   %ebp
80104fc0:	89 e5                	mov    %esp,%ebp
80104fc2:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
80104fc5:	c7 04 24 80 2f 11 80 	movl   $0x80112f80,(%esp)
80104fcc:	e8 91 06 00 00       	call   80105662 <holding>
80104fd1:	85 c0                	test   %eax,%eax
80104fd3:	75 0c                	jne    80104fe1 <sched+0x22>
    panic("sched ptable.lock");
80104fd5:	c7 04 24 60 93 10 80 	movl   $0x80109360,(%esp)
80104fdc:	e8 5c b5 ff ff       	call   8010053d <panic>
  if(cpu->ncli != 1)
80104fe1:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104fe7:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80104fed:	83 f8 01             	cmp    $0x1,%eax
80104ff0:	74 0c                	je     80104ffe <sched+0x3f>
    panic("sched locks");
80104ff2:	c7 04 24 72 93 10 80 	movl   $0x80109372,(%esp)
80104ff9:	e8 3f b5 ff ff       	call   8010053d <panic>
  if(proc->state == RUNNING)
80104ffe:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105004:	8b 40 0c             	mov    0xc(%eax),%eax
80105007:	83 f8 04             	cmp    $0x4,%eax
8010500a:	75 0c                	jne    80105018 <sched+0x59>
    panic("sched running");
8010500c:	c7 04 24 7e 93 10 80 	movl   $0x8010937e,(%esp)
80105013:	e8 25 b5 ff ff       	call   8010053d <panic>
  if(readeflags()&FL_IF)
80105018:	e8 2c f2 ff ff       	call   80104249 <readeflags>
8010501d:	25 00 02 00 00       	and    $0x200,%eax
80105022:	85 c0                	test   %eax,%eax
80105024:	74 0c                	je     80105032 <sched+0x73>
    panic("sched interruptible");
80105026:	c7 04 24 8c 93 10 80 	movl   $0x8010938c,(%esp)
8010502d:	e8 0b b5 ff ff       	call   8010053d <panic>
  intena = cpu->intena;
80105032:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105038:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
8010503e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->context, cpu->scheduler);
80105041:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105047:	8b 40 04             	mov    0x4(%eax),%eax
8010504a:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80105051:	83 c2 1c             	add    $0x1c,%edx
80105054:	89 44 24 04          	mov    %eax,0x4(%esp)
80105058:	89 14 24             	mov    %edx,(%esp)
8010505b:	e8 d8 09 00 00       	call   80105a38 <swtch>
  cpu->intena = intena;
80105060:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105066:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105069:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
8010506f:	c9                   	leave  
80105070:	c3                   	ret    

80105071 <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
80105071:	55                   	push   %ebp
80105072:	89 e5                	mov    %esp,%ebp
80105074:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
80105077:	c7 04 24 80 2f 11 80 	movl   $0x80112f80,(%esp)
8010507e:	e8 88 04 00 00       	call   8010550b <acquire>
  proc->state = RUNNABLE;
80105083:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105089:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
80105090:	e8 2a ff ff ff       	call   80104fbf <sched>
  release(&ptable.lock);
80105095:	c7 04 24 80 2f 11 80 	movl   $0x80112f80,(%esp)
8010509c:	e8 05 05 00 00       	call   801055a6 <release>
}
801050a1:	c9                   	leave  
801050a2:	c3                   	ret    

801050a3 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
801050a3:	55                   	push   %ebp
801050a4:	89 e5                	mov    %esp,%ebp
801050a6:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
801050a9:	c7 04 24 80 2f 11 80 	movl   $0x80112f80,(%esp)
801050b0:	e8 f1 04 00 00       	call   801055a6 <release>

  if (first) {
801050b5:	a1 24 c0 10 80       	mov    0x8010c024,%eax
801050ba:	85 c0                	test   %eax,%eax
801050bc:	74 0f                	je     801050cd <forkret+0x2a>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
801050be:	c7 05 24 c0 10 80 00 	movl   $0x0,0x8010c024
801050c5:	00 00 00 
    initlog();
801050c8:	e8 8f e1 ff ff       	call   8010325c <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
801050cd:	c9                   	leave  
801050ce:	c3                   	ret    

801050cf <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
801050cf:	55                   	push   %ebp
801050d0:	89 e5                	mov    %esp,%ebp
801050d2:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
801050d5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050db:	85 c0                	test   %eax,%eax
801050dd:	75 0c                	jne    801050eb <sleep+0x1c>
    panic("sleep");
801050df:	c7 04 24 a0 93 10 80 	movl   $0x801093a0,(%esp)
801050e6:	e8 52 b4 ff ff       	call   8010053d <panic>

  if(lk == 0)
801050eb:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801050ef:	75 0c                	jne    801050fd <sleep+0x2e>
    panic("sleep without lk");
801050f1:	c7 04 24 a6 93 10 80 	movl   $0x801093a6,(%esp)
801050f8:	e8 40 b4 ff ff       	call   8010053d <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
801050fd:	81 7d 0c 80 2f 11 80 	cmpl   $0x80112f80,0xc(%ebp)
80105104:	74 17                	je     8010511d <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
80105106:	c7 04 24 80 2f 11 80 	movl   $0x80112f80,(%esp)
8010510d:	e8 f9 03 00 00       	call   8010550b <acquire>
    release(lk);
80105112:	8b 45 0c             	mov    0xc(%ebp),%eax
80105115:	89 04 24             	mov    %eax,(%esp)
80105118:	e8 89 04 00 00       	call   801055a6 <release>
  }

  // Go to sleep.
  proc->chan = chan;
8010511d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105123:	8b 55 08             	mov    0x8(%ebp),%edx
80105126:	89 50 20             	mov    %edx,0x20(%eax)
  proc->state = SLEEPING;
80105129:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010512f:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)

  // Swap out
  if(swapFlag)
80105136:	a1 08 c0 10 80       	mov    0x8010c008,%eax
8010513b:	85 c0                	test   %eax,%eax
8010513d:	74 2b                	je     8010516a <sleep+0x9b>
  {
    if(proc->pid > 3)
8010513f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105145:	8b 40 10             	mov    0x10(%eax),%eax
80105148:	83 f8 03             	cmp    $0x3,%eax
8010514b:	7e 1d                	jle    8010516a <sleep+0x9b>
    {
      release(&ptable.lock);
8010514d:	c7 04 24 80 2f 11 80 	movl   $0x80112f80,(%esp)
80105154:	e8 4d 04 00 00       	call   801055a6 <release>
      swapOut();
80105159:	e8 0d f6 ff ff       	call   8010476b <swapOut>
      acquire(&ptable.lock);
8010515e:	c7 04 24 80 2f 11 80 	movl   $0x80112f80,(%esp)
80105165:	e8 a1 03 00 00       	call   8010550b <acquire>
    }
  }
  
  sched();
8010516a:	e8 50 fe ff ff       	call   80104fbf <sched>
  
  // Tidy up.
  proc->chan = 0;
8010516f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105175:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
8010517c:	81 7d 0c 80 2f 11 80 	cmpl   $0x80112f80,0xc(%ebp)
80105183:	74 17                	je     8010519c <sleep+0xcd>
    release(&ptable.lock);
80105185:	c7 04 24 80 2f 11 80 	movl   $0x80112f80,(%esp)
8010518c:	e8 15 04 00 00       	call   801055a6 <release>
    acquire(lk);
80105191:	8b 45 0c             	mov    0xc(%ebp),%eax
80105194:	89 04 24             	mov    %eax,(%esp)
80105197:	e8 6f 03 00 00       	call   8010550b <acquire>
  }
}
8010519c:	c9                   	leave  
8010519d:	c3                   	ret    

8010519e <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
8010519e:	55                   	push   %ebp
8010519f:	89 e5                	mov    %esp,%ebp
801051a1:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801051a4:	c7 45 fc b4 2f 11 80 	movl   $0x80112fb4,-0x4(%ebp)
801051ab:	eb 53                	jmp    80105200 <wakeup1+0x62>
  {
    if(p->state == SLEEPING && p->chan == chan)
801051ad:	8b 45 fc             	mov    -0x4(%ebp),%eax
801051b0:	8b 40 0c             	mov    0xc(%eax),%eax
801051b3:	83 f8 02             	cmp    $0x2,%eax
801051b6:	75 15                	jne    801051cd <wakeup1+0x2f>
801051b8:	8b 45 fc             	mov    -0x4(%ebp),%eax
801051bb:	8b 40 20             	mov    0x20(%eax),%eax
801051be:	3b 45 08             	cmp    0x8(%ebp),%eax
801051c1:	75 0a                	jne    801051cd <wakeup1+0x2f>
      p->state = RUNNABLE;
801051c3:	8b 45 fc             	mov    -0x4(%ebp),%eax
801051c6:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
    if(p->state == SLEEPING_SUSPENDED && p->chan == chan)
801051cd:	8b 45 fc             	mov    -0x4(%ebp),%eax
801051d0:	8b 40 0c             	mov    0xc(%eax),%eax
801051d3:	83 f8 06             	cmp    $0x6,%eax
801051d6:	75 21                	jne    801051f9 <wakeup1+0x5b>
801051d8:	8b 45 fc             	mov    -0x4(%ebp),%eax
801051db:	8b 40 20             	mov    0x20(%eax),%eax
801051de:	3b 45 08             	cmp    0x8(%ebp),%eax
801051e1:	75 16                	jne    801051f9 <wakeup1+0x5b>
    {
      p->state = RUNNABLE_SUSPENDED;
801051e3:	8b 45 fc             	mov    -0x4(%ebp),%eax
801051e6:	c7 40 0c 07 00 00 00 	movl   $0x7,0xc(%eax)
      inswapper->state = RUNNABLE;
801051ed:	a1 6c c6 10 80       	mov    0x8010c66c,%eax
801051f2:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801051f9:	81 45 fc 8c 00 00 00 	addl   $0x8c,-0x4(%ebp)
80105200:	81 7d fc b4 52 11 80 	cmpl   $0x801152b4,-0x4(%ebp)
80105207:	72 a4                	jb     801051ad <wakeup1+0xf>
    {
      p->state = RUNNABLE_SUSPENDED;
      inswapper->state = RUNNABLE;
    }
  }
}
80105209:	c9                   	leave  
8010520a:	c3                   	ret    

8010520b <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
8010520b:	55                   	push   %ebp
8010520c:	89 e5                	mov    %esp,%ebp
8010520e:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);
80105211:	c7 04 24 80 2f 11 80 	movl   $0x80112f80,(%esp)
80105218:	e8 ee 02 00 00       	call   8010550b <acquire>
  wakeup1(chan);
8010521d:	8b 45 08             	mov    0x8(%ebp),%eax
80105220:	89 04 24             	mov    %eax,(%esp)
80105223:	e8 76 ff ff ff       	call   8010519e <wakeup1>
  release(&ptable.lock);
80105228:	c7 04 24 80 2f 11 80 	movl   $0x80112f80,(%esp)
8010522f:	e8 72 03 00 00       	call   801055a6 <release>
}
80105234:	c9                   	leave  
80105235:	c3                   	ret    

80105236 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80105236:	55                   	push   %ebp
80105237:	89 e5                	mov    %esp,%ebp
80105239:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  acquire(&ptable.lock);
8010523c:	c7 04 24 80 2f 11 80 	movl   $0x80112f80,(%esp)
80105243:	e8 c3 02 00 00       	call   8010550b <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105248:	c7 45 f4 b4 2f 11 80 	movl   $0x80112fb4,-0xc(%ebp)
8010524f:	eb 67                	jmp    801052b8 <kill+0x82>
    if(p->pid == pid){
80105251:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105254:	8b 40 10             	mov    0x10(%eax),%eax
80105257:	3b 45 08             	cmp    0x8(%ebp),%eax
8010525a:	75 55                	jne    801052b1 <kill+0x7b>
      p->killed = 1;
8010525c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010525f:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80105266:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105269:	8b 40 0c             	mov    0xc(%eax),%eax
8010526c:	83 f8 02             	cmp    $0x2,%eax
8010526f:	75 0c                	jne    8010527d <kill+0x47>
        p->state = RUNNABLE;
80105271:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105274:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
8010527b:	eb 21                	jmp    8010529e <kill+0x68>
      else if(p->state == SLEEPING_SUSPENDED)
8010527d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105280:	8b 40 0c             	mov    0xc(%eax),%eax
80105283:	83 f8 06             	cmp    $0x6,%eax
80105286:	75 16                	jne    8010529e <kill+0x68>
      {
        p->state = RUNNABLE_SUSPENDED;
80105288:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010528b:	c7 40 0c 07 00 00 00 	movl   $0x7,0xc(%eax)
	inswapper->state = RUNNABLE;
80105292:	a1 6c c6 10 80       	mov    0x8010c66c,%eax
80105297:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      }
      release(&ptable.lock);
8010529e:	c7 04 24 80 2f 11 80 	movl   $0x80112f80,(%esp)
801052a5:	e8 fc 02 00 00       	call   801055a6 <release>
      return 0;
801052aa:	b8 00 00 00 00       	mov    $0x0,%eax
801052af:	eb 21                	jmp    801052d2 <kill+0x9c>
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801052b1:	81 45 f4 8c 00 00 00 	addl   $0x8c,-0xc(%ebp)
801052b8:	81 7d f4 b4 52 11 80 	cmpl   $0x801152b4,-0xc(%ebp)
801052bf:	72 90                	jb     80105251 <kill+0x1b>
      }
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
801052c1:	c7 04 24 80 2f 11 80 	movl   $0x80112f80,(%esp)
801052c8:	e8 d9 02 00 00       	call   801055a6 <release>
  return -1;
801052cd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801052d2:	c9                   	leave  
801052d3:	c3                   	ret    

801052d4 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
801052d4:	55                   	push   %ebp
801052d5:	89 e5                	mov    %esp,%ebp
801052d7:	83 ec 58             	sub    $0x58,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801052da:	c7 45 f0 b4 2f 11 80 	movl   $0x80112fb4,-0x10(%ebp)
801052e1:	e9 db 00 00 00       	jmp    801053c1 <procdump+0xed>
    if(p->state == UNUSED)
801052e6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801052e9:	8b 40 0c             	mov    0xc(%eax),%eax
801052ec:	85 c0                	test   %eax,%eax
801052ee:	0f 84 c5 00 00 00    	je     801053b9 <procdump+0xe5>
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
801052f4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801052f7:	8b 40 0c             	mov    0xc(%eax),%eax
801052fa:	83 f8 05             	cmp    $0x5,%eax
801052fd:	77 23                	ja     80105322 <procdump+0x4e>
801052ff:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105302:	8b 40 0c             	mov    0xc(%eax),%eax
80105305:	8b 04 85 0c c0 10 80 	mov    -0x7fef3ff4(,%eax,4),%eax
8010530c:	85 c0                	test   %eax,%eax
8010530e:	74 12                	je     80105322 <procdump+0x4e>
      state = states[p->state];
80105310:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105313:	8b 40 0c             	mov    0xc(%eax),%eax
80105316:	8b 04 85 0c c0 10 80 	mov    -0x7fef3ff4(,%eax,4),%eax
8010531d:	89 45 ec             	mov    %eax,-0x14(%ebp)
80105320:	eb 07                	jmp    80105329 <procdump+0x55>
    else
      state = "???";
80105322:	c7 45 ec b7 93 10 80 	movl   $0x801093b7,-0x14(%ebp)
    cprintf("%d %s %s", p->pid, state, p->name);
80105329:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010532c:	8d 50 6c             	lea    0x6c(%eax),%edx
8010532f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105332:	8b 40 10             	mov    0x10(%eax),%eax
80105335:	89 54 24 0c          	mov    %edx,0xc(%esp)
80105339:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010533c:	89 54 24 08          	mov    %edx,0x8(%esp)
80105340:	89 44 24 04          	mov    %eax,0x4(%esp)
80105344:	c7 04 24 bb 93 10 80 	movl   $0x801093bb,(%esp)
8010534b:	e8 51 b0 ff ff       	call   801003a1 <cprintf>
    if(p->state == SLEEPING){
80105350:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105353:	8b 40 0c             	mov    0xc(%eax),%eax
80105356:	83 f8 02             	cmp    $0x2,%eax
80105359:	75 50                	jne    801053ab <procdump+0xd7>
      getcallerpcs((uint*)p->context->ebp+2, pc);
8010535b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010535e:	8b 40 1c             	mov    0x1c(%eax),%eax
80105361:	8b 40 0c             	mov    0xc(%eax),%eax
80105364:	83 c0 08             	add    $0x8,%eax
80105367:	8d 55 c4             	lea    -0x3c(%ebp),%edx
8010536a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010536e:	89 04 24             	mov    %eax,(%esp)
80105371:	e8 7f 02 00 00       	call   801055f5 <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80105376:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010537d:	eb 1b                	jmp    8010539a <procdump+0xc6>
        cprintf(" %p", pc[i]);
8010537f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105382:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80105386:	89 44 24 04          	mov    %eax,0x4(%esp)
8010538a:	c7 04 24 c4 93 10 80 	movl   $0x801093c4,(%esp)
80105391:	e8 0b b0 ff ff       	call   801003a1 <cprintf>
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
80105396:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010539a:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
8010539e:	7f 0b                	jg     801053ab <procdump+0xd7>
801053a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053a3:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
801053a7:	85 c0                	test   %eax,%eax
801053a9:	75 d4                	jne    8010537f <procdump+0xab>
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
801053ab:	c7 04 24 c8 93 10 80 	movl   $0x801093c8,(%esp)
801053b2:	e8 ea af ff ff       	call   801003a1 <cprintf>
801053b7:	eb 01                	jmp    801053ba <procdump+0xe6>
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
801053b9:	90                   	nop
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801053ba:	81 45 f0 8c 00 00 00 	addl   $0x8c,-0x10(%ebp)
801053c1:	81 7d f0 b4 52 11 80 	cmpl   $0x801152b4,-0x10(%ebp)
801053c8:	0f 82 18 ff ff ff    	jb     801052e6 <procdump+0x12>
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}
801053ce:	c9                   	leave  
801053cf:	c3                   	ret    

801053d0 <getAllocatedPages>:

int getAllocatedPages(int pid) {
801053d0:	55                   	push   %ebp
801053d1:	89 e5                	mov    %esp,%ebp
801053d3:	83 ec 38             	sub    $0x38,%esp
  struct proc* p;
  acquire(&ptable.lock);
801053d6:	c7 04 24 80 2f 11 80 	movl   $0x80112f80,(%esp)
801053dd:	e8 29 01 00 00       	call   8010550b <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801053e2:	c7 45 f4 b4 2f 11 80 	movl   $0x80112fb4,-0xc(%ebp)
801053e9:	eb 12                	jmp    801053fd <getAllocatedPages+0x2d>
    if(p->pid == pid){
801053eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053ee:	8b 40 10             	mov    0x10(%eax),%eax
801053f1:	3b 45 08             	cmp    0x8(%ebp),%eax
801053f4:	74 12                	je     80105408 <getAllocatedPages+0x38>
}

int getAllocatedPages(int pid) {
  struct proc* p;
  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801053f6:	81 45 f4 8c 00 00 00 	addl   $0x8c,-0xc(%ebp)
801053fd:	81 7d f4 b4 52 11 80 	cmpl   $0x801152b4,-0xc(%ebp)
80105404:	72 e5                	jb     801053eb <getAllocatedPages+0x1b>
80105406:	eb 01                	jmp    80105409 <getAllocatedPages+0x39>
    if(p->pid == pid){
     break;
80105408:	90                   	nop
    }
  }
  release(&ptable.lock);
80105409:	c7 04 24 80 2f 11 80 	movl   $0x80112f80,(%esp)
80105410:	e8 91 01 00 00       	call   801055a6 <release>
   int count= 0, j, k;
80105415:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   for (j=0; j<1024; j++) {
8010541c:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80105423:	eb 71                	jmp    80105496 <getAllocatedPages+0xc6>
      if(p->pgdir){ 
80105425:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105428:	8b 40 04             	mov    0x4(%eax),%eax
8010542b:	85 c0                	test   %eax,%eax
8010542d:	74 63                	je     80105492 <getAllocatedPages+0xc2>
	if (p->pgdir[j] & PTE_P) {
8010542f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105432:	8b 40 04             	mov    0x4(%eax),%eax
80105435:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105438:	c1 e2 02             	shl    $0x2,%edx
8010543b:	01 d0                	add    %edx,%eax
8010543d:	8b 00                	mov    (%eax),%eax
8010543f:	83 e0 01             	and    $0x1,%eax
80105442:	84 c0                	test   %al,%al
80105444:	74 4c                	je     80105492 <getAllocatedPages+0xc2>
	  pte_t* pte= (pte_t*)p2v(PTE_ADDR(p->pgdir[j]));
80105446:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105449:	8b 40 04             	mov    0x4(%eax),%eax
8010544c:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010544f:	c1 e2 02             	shl    $0x2,%edx
80105452:	01 d0                	add    %edx,%eax
80105454:	8b 00                	mov    (%eax),%eax
80105456:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010545b:	89 04 24             	mov    %eax,(%esp)
8010545e:	e8 d9 ed ff ff       	call   8010423c <p2v>
80105463:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	  for (k=0; k<1024; k++) {
80105466:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
8010546d:	eb 1a                	jmp    80105489 <getAllocatedPages+0xb9>
	      if ( pte[k] & PTE_U )
8010546f:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105472:	c1 e0 02             	shl    $0x2,%eax
80105475:	03 45 e4             	add    -0x1c(%ebp),%eax
80105478:	8b 00                	mov    (%eax),%eax
8010547a:	83 e0 04             	and    $0x4,%eax
8010547d:	85 c0                	test   %eax,%eax
8010547f:	74 04                	je     80105485 <getAllocatedPages+0xb5>
		count++;
80105481:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   int count= 0, j, k;
   for (j=0; j<1024; j++) {
      if(p->pgdir){ 
	if (p->pgdir[j] & PTE_P) {
	  pte_t* pte= (pte_t*)p2v(PTE_ADDR(p->pgdir[j]));
	  for (k=0; k<1024; k++) {
80105485:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
80105489:	81 7d e8 ff 03 00 00 	cmpl   $0x3ff,-0x18(%ebp)
80105490:	7e dd                	jle    8010546f <getAllocatedPages+0x9f>
     break;
    }
  }
  release(&ptable.lock);
   int count= 0, j, k;
   for (j=0; j<1024; j++) {
80105492:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
80105496:	81 7d ec ff 03 00 00 	cmpl   $0x3ff,-0x14(%ebp)
8010549d:	7e 86                	jle    80105425 <getAllocatedPages+0x55>
		count++;
	  }
	}
      }
   }
   return count;
8010549f:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
801054a2:	c9                   	leave  
801054a3:	c3                   	ret    

801054a4 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
801054a4:	55                   	push   %ebp
801054a5:	89 e5                	mov    %esp,%ebp
801054a7:	53                   	push   %ebx
801054a8:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801054ab:	9c                   	pushf  
801054ac:	5b                   	pop    %ebx
801054ad:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
801054b0:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
801054b3:	83 c4 10             	add    $0x10,%esp
801054b6:	5b                   	pop    %ebx
801054b7:	5d                   	pop    %ebp
801054b8:	c3                   	ret    

801054b9 <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
801054b9:	55                   	push   %ebp
801054ba:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
801054bc:	fa                   	cli    
}
801054bd:	5d                   	pop    %ebp
801054be:	c3                   	ret    

801054bf <sti>:

static inline void
sti(void)
{
801054bf:	55                   	push   %ebp
801054c0:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
801054c2:	fb                   	sti    
}
801054c3:	5d                   	pop    %ebp
801054c4:	c3                   	ret    

801054c5 <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
801054c5:	55                   	push   %ebp
801054c6:	89 e5                	mov    %esp,%ebp
801054c8:	53                   	push   %ebx
801054c9:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
801054cc:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
801054cf:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
801054d2:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
801054d5:	89 c3                	mov    %eax,%ebx
801054d7:	89 d8                	mov    %ebx,%eax
801054d9:	f0 87 02             	lock xchg %eax,(%edx)
801054dc:	89 c3                	mov    %eax,%ebx
801054de:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
801054e1:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
801054e4:	83 c4 10             	add    $0x10,%esp
801054e7:	5b                   	pop    %ebx
801054e8:	5d                   	pop    %ebp
801054e9:	c3                   	ret    

801054ea <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
801054ea:	55                   	push   %ebp
801054eb:	89 e5                	mov    %esp,%ebp
  lk->name = name;
801054ed:	8b 45 08             	mov    0x8(%ebp),%eax
801054f0:	8b 55 0c             	mov    0xc(%ebp),%edx
801054f3:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
801054f6:	8b 45 08             	mov    0x8(%ebp),%eax
801054f9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
801054ff:	8b 45 08             	mov    0x8(%ebp),%eax
80105502:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80105509:	5d                   	pop    %ebp
8010550a:	c3                   	ret    

8010550b <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
8010550b:	55                   	push   %ebp
8010550c:	89 e5                	mov    %esp,%ebp
8010550e:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80105511:	e8 76 01 00 00       	call   8010568c <pushcli>
  if(holding(lk))
80105516:	8b 45 08             	mov    0x8(%ebp),%eax
80105519:	89 04 24             	mov    %eax,(%esp)
8010551c:	e8 41 01 00 00       	call   80105662 <holding>
80105521:	85 c0                	test   %eax,%eax
80105523:	74 45                	je     8010556a <acquire+0x5f>
  {
    cprintf("lock = %s\n",lk->name);
80105525:	8b 45 08             	mov    0x8(%ebp),%eax
80105528:	8b 40 04             	mov    0x4(%eax),%eax
8010552b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010552f:	c7 04 24 f4 93 10 80 	movl   $0x801093f4,(%esp)
80105536:	e8 66 ae ff ff       	call   801003a1 <cprintf>
    if(proc)
8010553b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105541:	85 c0                	test   %eax,%eax
80105543:	74 19                	je     8010555e <acquire+0x53>
      cprintf("pid = %d\n",proc->pid);
80105545:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010554b:	8b 40 10             	mov    0x10(%eax),%eax
8010554e:	89 44 24 04          	mov    %eax,0x4(%esp)
80105552:	c7 04 24 ff 93 10 80 	movl   $0x801093ff,(%esp)
80105559:	e8 43 ae ff ff       	call   801003a1 <cprintf>
    panic("acquire");
8010555e:	c7 04 24 09 94 10 80 	movl   $0x80109409,(%esp)
80105565:	e8 d3 af ff ff       	call   8010053d <panic>
  }

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
8010556a:	90                   	nop
8010556b:	8b 45 08             	mov    0x8(%ebp),%eax
8010556e:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80105575:	00 
80105576:	89 04 24             	mov    %eax,(%esp)
80105579:	e8 47 ff ff ff       	call   801054c5 <xchg>
8010557e:	85 c0                	test   %eax,%eax
80105580:	75 e9                	jne    8010556b <acquire+0x60>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
80105582:	8b 45 08             	mov    0x8(%ebp),%eax
80105585:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
8010558c:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
8010558f:	8b 45 08             	mov    0x8(%ebp),%eax
80105592:	83 c0 0c             	add    $0xc,%eax
80105595:	89 44 24 04          	mov    %eax,0x4(%esp)
80105599:	8d 45 08             	lea    0x8(%ebp),%eax
8010559c:	89 04 24             	mov    %eax,(%esp)
8010559f:	e8 51 00 00 00       	call   801055f5 <getcallerpcs>
}
801055a4:	c9                   	leave  
801055a5:	c3                   	ret    

801055a6 <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
801055a6:	55                   	push   %ebp
801055a7:	89 e5                	mov    %esp,%ebp
801055a9:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
801055ac:	8b 45 08             	mov    0x8(%ebp),%eax
801055af:	89 04 24             	mov    %eax,(%esp)
801055b2:	e8 ab 00 00 00       	call   80105662 <holding>
801055b7:	85 c0                	test   %eax,%eax
801055b9:	75 0c                	jne    801055c7 <release+0x21>
    panic("release");
801055bb:	c7 04 24 11 94 10 80 	movl   $0x80109411,(%esp)
801055c2:	e8 76 af ff ff       	call   8010053d <panic>

  lk->pcs[0] = 0;
801055c7:	8b 45 08             	mov    0x8(%ebp),%eax
801055ca:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
801055d1:	8b 45 08             	mov    0x8(%ebp),%eax
801055d4:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
801055db:	8b 45 08             	mov    0x8(%ebp),%eax
801055de:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801055e5:	00 
801055e6:	89 04 24             	mov    %eax,(%esp)
801055e9:	e8 d7 fe ff ff       	call   801054c5 <xchg>

  popcli();
801055ee:	e8 e1 00 00 00       	call   801056d4 <popcli>
}
801055f3:	c9                   	leave  
801055f4:	c3                   	ret    

801055f5 <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
801055f5:	55                   	push   %ebp
801055f6:	89 e5                	mov    %esp,%ebp
801055f8:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
801055fb:	8b 45 08             	mov    0x8(%ebp),%eax
801055fe:	83 e8 08             	sub    $0x8,%eax
80105601:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
80105604:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
8010560b:	eb 32                	jmp    8010563f <getcallerpcs+0x4a>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
8010560d:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
80105611:	74 47                	je     8010565a <getcallerpcs+0x65>
80105613:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
8010561a:	76 3e                	jbe    8010565a <getcallerpcs+0x65>
8010561c:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
80105620:	74 38                	je     8010565a <getcallerpcs+0x65>
      break;
    pcs[i] = ebp[1];     // saved %eip
80105622:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105625:	c1 e0 02             	shl    $0x2,%eax
80105628:	03 45 0c             	add    0xc(%ebp),%eax
8010562b:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010562e:	8b 52 04             	mov    0x4(%edx),%edx
80105631:	89 10                	mov    %edx,(%eax)
    ebp = (uint*)ebp[0]; // saved %ebp
80105633:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105636:	8b 00                	mov    (%eax),%eax
80105638:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
8010563b:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
8010563f:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105643:	7e c8                	jle    8010560d <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105645:	eb 13                	jmp    8010565a <getcallerpcs+0x65>
    pcs[i] = 0;
80105647:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010564a:	c1 e0 02             	shl    $0x2,%eax
8010564d:	03 45 0c             	add    0xc(%ebp),%eax
80105650:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105656:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
8010565a:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
8010565e:	7e e7                	jle    80105647 <getcallerpcs+0x52>
    pcs[i] = 0;
}
80105660:	c9                   	leave  
80105661:	c3                   	ret    

80105662 <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
80105662:	55                   	push   %ebp
80105663:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
80105665:	8b 45 08             	mov    0x8(%ebp),%eax
80105668:	8b 00                	mov    (%eax),%eax
8010566a:	85 c0                	test   %eax,%eax
8010566c:	74 17                	je     80105685 <holding+0x23>
8010566e:	8b 45 08             	mov    0x8(%ebp),%eax
80105671:	8b 50 08             	mov    0x8(%eax),%edx
80105674:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010567a:	39 c2                	cmp    %eax,%edx
8010567c:	75 07                	jne    80105685 <holding+0x23>
8010567e:	b8 01 00 00 00       	mov    $0x1,%eax
80105683:	eb 05                	jmp    8010568a <holding+0x28>
80105685:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010568a:	5d                   	pop    %ebp
8010568b:	c3                   	ret    

8010568c <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
8010568c:	55                   	push   %ebp
8010568d:	89 e5                	mov    %esp,%ebp
8010568f:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
80105692:	e8 0d fe ff ff       	call   801054a4 <readeflags>
80105697:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
8010569a:	e8 1a fe ff ff       	call   801054b9 <cli>
  if(cpu->ncli++ == 0)
8010569f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801056a5:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
801056ab:	85 d2                	test   %edx,%edx
801056ad:	0f 94 c1             	sete   %cl
801056b0:	83 c2 01             	add    $0x1,%edx
801056b3:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
801056b9:	84 c9                	test   %cl,%cl
801056bb:	74 15                	je     801056d2 <pushcli+0x46>
    cpu->intena = eflags & FL_IF;
801056bd:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801056c3:	8b 55 fc             	mov    -0x4(%ebp),%edx
801056c6:	81 e2 00 02 00 00    	and    $0x200,%edx
801056cc:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
801056d2:	c9                   	leave  
801056d3:	c3                   	ret    

801056d4 <popcli>:

void
popcli(void)
{
801056d4:	55                   	push   %ebp
801056d5:	89 e5                	mov    %esp,%ebp
801056d7:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
801056da:	e8 c5 fd ff ff       	call   801054a4 <readeflags>
801056df:	25 00 02 00 00       	and    $0x200,%eax
801056e4:	85 c0                	test   %eax,%eax
801056e6:	74 0c                	je     801056f4 <popcli+0x20>
    panic("popcli - interruptible");
801056e8:	c7 04 24 19 94 10 80 	movl   $0x80109419,(%esp)
801056ef:	e8 49 ae ff ff       	call   8010053d <panic>
  if(--cpu->ncli < 0)
801056f4:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801056fa:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80105700:	83 ea 01             	sub    $0x1,%edx
80105703:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80105709:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
8010570f:	85 c0                	test   %eax,%eax
80105711:	79 0c                	jns    8010571f <popcli+0x4b>
    panic("popcli");
80105713:	c7 04 24 30 94 10 80 	movl   $0x80109430,(%esp)
8010571a:	e8 1e ae ff ff       	call   8010053d <panic>
  if(cpu->ncli == 0 && cpu->intena)
8010571f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105725:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
8010572b:	85 c0                	test   %eax,%eax
8010572d:	75 15                	jne    80105744 <popcli+0x70>
8010572f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105735:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
8010573b:	85 c0                	test   %eax,%eax
8010573d:	74 05                	je     80105744 <popcli+0x70>
    sti();
8010573f:	e8 7b fd ff ff       	call   801054bf <sti>
}
80105744:	c9                   	leave  
80105745:	c3                   	ret    
	...

80105748 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
80105748:	55                   	push   %ebp
80105749:	89 e5                	mov    %esp,%ebp
8010574b:	57                   	push   %edi
8010574c:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
8010574d:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105750:	8b 55 10             	mov    0x10(%ebp),%edx
80105753:	8b 45 0c             	mov    0xc(%ebp),%eax
80105756:	89 cb                	mov    %ecx,%ebx
80105758:	89 df                	mov    %ebx,%edi
8010575a:	89 d1                	mov    %edx,%ecx
8010575c:	fc                   	cld    
8010575d:	f3 aa                	rep stos %al,%es:(%edi)
8010575f:	89 ca                	mov    %ecx,%edx
80105761:	89 fb                	mov    %edi,%ebx
80105763:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105766:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105769:	5b                   	pop    %ebx
8010576a:	5f                   	pop    %edi
8010576b:	5d                   	pop    %ebp
8010576c:	c3                   	ret    

8010576d <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
8010576d:	55                   	push   %ebp
8010576e:	89 e5                	mov    %esp,%ebp
80105770:	57                   	push   %edi
80105771:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
80105772:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105775:	8b 55 10             	mov    0x10(%ebp),%edx
80105778:	8b 45 0c             	mov    0xc(%ebp),%eax
8010577b:	89 cb                	mov    %ecx,%ebx
8010577d:	89 df                	mov    %ebx,%edi
8010577f:	89 d1                	mov    %edx,%ecx
80105781:	fc                   	cld    
80105782:	f3 ab                	rep stos %eax,%es:(%edi)
80105784:	89 ca                	mov    %ecx,%edx
80105786:	89 fb                	mov    %edi,%ebx
80105788:	89 5d 08             	mov    %ebx,0x8(%ebp)
8010578b:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
8010578e:	5b                   	pop    %ebx
8010578f:	5f                   	pop    %edi
80105790:	5d                   	pop    %ebp
80105791:	c3                   	ret    

80105792 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80105792:	55                   	push   %ebp
80105793:	89 e5                	mov    %esp,%ebp
80105795:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
80105798:	8b 45 08             	mov    0x8(%ebp),%eax
8010579b:	83 e0 03             	and    $0x3,%eax
8010579e:	85 c0                	test   %eax,%eax
801057a0:	75 49                	jne    801057eb <memset+0x59>
801057a2:	8b 45 10             	mov    0x10(%ebp),%eax
801057a5:	83 e0 03             	and    $0x3,%eax
801057a8:	85 c0                	test   %eax,%eax
801057aa:	75 3f                	jne    801057eb <memset+0x59>
    c &= 0xFF;
801057ac:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
801057b3:	8b 45 10             	mov    0x10(%ebp),%eax
801057b6:	c1 e8 02             	shr    $0x2,%eax
801057b9:	89 c2                	mov    %eax,%edx
801057bb:	8b 45 0c             	mov    0xc(%ebp),%eax
801057be:	89 c1                	mov    %eax,%ecx
801057c0:	c1 e1 18             	shl    $0x18,%ecx
801057c3:	8b 45 0c             	mov    0xc(%ebp),%eax
801057c6:	c1 e0 10             	shl    $0x10,%eax
801057c9:	09 c1                	or     %eax,%ecx
801057cb:	8b 45 0c             	mov    0xc(%ebp),%eax
801057ce:	c1 e0 08             	shl    $0x8,%eax
801057d1:	09 c8                	or     %ecx,%eax
801057d3:	0b 45 0c             	or     0xc(%ebp),%eax
801057d6:	89 54 24 08          	mov    %edx,0x8(%esp)
801057da:	89 44 24 04          	mov    %eax,0x4(%esp)
801057de:	8b 45 08             	mov    0x8(%ebp),%eax
801057e1:	89 04 24             	mov    %eax,(%esp)
801057e4:	e8 84 ff ff ff       	call   8010576d <stosl>
801057e9:	eb 19                	jmp    80105804 <memset+0x72>
  } else
    stosb(dst, c, n);
801057eb:	8b 45 10             	mov    0x10(%ebp),%eax
801057ee:	89 44 24 08          	mov    %eax,0x8(%esp)
801057f2:	8b 45 0c             	mov    0xc(%ebp),%eax
801057f5:	89 44 24 04          	mov    %eax,0x4(%esp)
801057f9:	8b 45 08             	mov    0x8(%ebp),%eax
801057fc:	89 04 24             	mov    %eax,(%esp)
801057ff:	e8 44 ff ff ff       	call   80105748 <stosb>
  return dst;
80105804:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105807:	c9                   	leave  
80105808:	c3                   	ret    

80105809 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80105809:	55                   	push   %ebp
8010580a:	89 e5                	mov    %esp,%ebp
8010580c:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
8010580f:	8b 45 08             	mov    0x8(%ebp),%eax
80105812:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
80105815:	8b 45 0c             	mov    0xc(%ebp),%eax
80105818:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
8010581b:	eb 32                	jmp    8010584f <memcmp+0x46>
    if(*s1 != *s2)
8010581d:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105820:	0f b6 10             	movzbl (%eax),%edx
80105823:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105826:	0f b6 00             	movzbl (%eax),%eax
80105829:	38 c2                	cmp    %al,%dl
8010582b:	74 1a                	je     80105847 <memcmp+0x3e>
      return *s1 - *s2;
8010582d:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105830:	0f b6 00             	movzbl (%eax),%eax
80105833:	0f b6 d0             	movzbl %al,%edx
80105836:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105839:	0f b6 00             	movzbl (%eax),%eax
8010583c:	0f b6 c0             	movzbl %al,%eax
8010583f:	89 d1                	mov    %edx,%ecx
80105841:	29 c1                	sub    %eax,%ecx
80105843:	89 c8                	mov    %ecx,%eax
80105845:	eb 1c                	jmp    80105863 <memcmp+0x5a>
    s1++, s2++;
80105847:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010584b:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
8010584f:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105853:	0f 95 c0             	setne  %al
80105856:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
8010585a:	84 c0                	test   %al,%al
8010585c:	75 bf                	jne    8010581d <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
8010585e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105863:	c9                   	leave  
80105864:	c3                   	ret    

80105865 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80105865:	55                   	push   %ebp
80105866:	89 e5                	mov    %esp,%ebp
80105868:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
8010586b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010586e:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
80105871:	8b 45 08             	mov    0x8(%ebp),%eax
80105874:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
80105877:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010587a:	3b 45 f8             	cmp    -0x8(%ebp),%eax
8010587d:	73 54                	jae    801058d3 <memmove+0x6e>
8010587f:	8b 45 10             	mov    0x10(%ebp),%eax
80105882:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105885:	01 d0                	add    %edx,%eax
80105887:	3b 45 f8             	cmp    -0x8(%ebp),%eax
8010588a:	76 47                	jbe    801058d3 <memmove+0x6e>
    s += n;
8010588c:	8b 45 10             	mov    0x10(%ebp),%eax
8010588f:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
80105892:	8b 45 10             	mov    0x10(%ebp),%eax
80105895:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
80105898:	eb 13                	jmp    801058ad <memmove+0x48>
      *--d = *--s;
8010589a:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
8010589e:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
801058a2:	8b 45 fc             	mov    -0x4(%ebp),%eax
801058a5:	0f b6 10             	movzbl (%eax),%edx
801058a8:	8b 45 f8             	mov    -0x8(%ebp),%eax
801058ab:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
801058ad:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801058b1:	0f 95 c0             	setne  %al
801058b4:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801058b8:	84 c0                	test   %al,%al
801058ba:	75 de                	jne    8010589a <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
801058bc:	eb 25                	jmp    801058e3 <memmove+0x7e>
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
      *d++ = *s++;
801058be:	8b 45 fc             	mov    -0x4(%ebp),%eax
801058c1:	0f b6 10             	movzbl (%eax),%edx
801058c4:	8b 45 f8             	mov    -0x8(%ebp),%eax
801058c7:	88 10                	mov    %dl,(%eax)
801058c9:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
801058cd:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801058d1:	eb 01                	jmp    801058d4 <memmove+0x6f>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
801058d3:	90                   	nop
801058d4:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801058d8:	0f 95 c0             	setne  %al
801058db:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801058df:	84 c0                	test   %al,%al
801058e1:	75 db                	jne    801058be <memmove+0x59>
      *d++ = *s++;

  return dst;
801058e3:	8b 45 08             	mov    0x8(%ebp),%eax
}
801058e6:	c9                   	leave  
801058e7:	c3                   	ret    

801058e8 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
801058e8:	55                   	push   %ebp
801058e9:	89 e5                	mov    %esp,%ebp
801058eb:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
801058ee:	8b 45 10             	mov    0x10(%ebp),%eax
801058f1:	89 44 24 08          	mov    %eax,0x8(%esp)
801058f5:	8b 45 0c             	mov    0xc(%ebp),%eax
801058f8:	89 44 24 04          	mov    %eax,0x4(%esp)
801058fc:	8b 45 08             	mov    0x8(%ebp),%eax
801058ff:	89 04 24             	mov    %eax,(%esp)
80105902:	e8 5e ff ff ff       	call   80105865 <memmove>
}
80105907:	c9                   	leave  
80105908:	c3                   	ret    

80105909 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80105909:	55                   	push   %ebp
8010590a:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
8010590c:	eb 0c                	jmp    8010591a <strncmp+0x11>
    n--, p++, q++;
8010590e:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105912:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105916:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
8010591a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010591e:	74 1a                	je     8010593a <strncmp+0x31>
80105920:	8b 45 08             	mov    0x8(%ebp),%eax
80105923:	0f b6 00             	movzbl (%eax),%eax
80105926:	84 c0                	test   %al,%al
80105928:	74 10                	je     8010593a <strncmp+0x31>
8010592a:	8b 45 08             	mov    0x8(%ebp),%eax
8010592d:	0f b6 10             	movzbl (%eax),%edx
80105930:	8b 45 0c             	mov    0xc(%ebp),%eax
80105933:	0f b6 00             	movzbl (%eax),%eax
80105936:	38 c2                	cmp    %al,%dl
80105938:	74 d4                	je     8010590e <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
8010593a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010593e:	75 07                	jne    80105947 <strncmp+0x3e>
    return 0;
80105940:	b8 00 00 00 00       	mov    $0x0,%eax
80105945:	eb 18                	jmp    8010595f <strncmp+0x56>
  return (uchar)*p - (uchar)*q;
80105947:	8b 45 08             	mov    0x8(%ebp),%eax
8010594a:	0f b6 00             	movzbl (%eax),%eax
8010594d:	0f b6 d0             	movzbl %al,%edx
80105950:	8b 45 0c             	mov    0xc(%ebp),%eax
80105953:	0f b6 00             	movzbl (%eax),%eax
80105956:	0f b6 c0             	movzbl %al,%eax
80105959:	89 d1                	mov    %edx,%ecx
8010595b:	29 c1                	sub    %eax,%ecx
8010595d:	89 c8                	mov    %ecx,%eax
}
8010595f:	5d                   	pop    %ebp
80105960:	c3                   	ret    

80105961 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80105961:	55                   	push   %ebp
80105962:	89 e5                	mov    %esp,%ebp
80105964:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105967:	8b 45 08             	mov    0x8(%ebp),%eax
8010596a:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
8010596d:	90                   	nop
8010596e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105972:	0f 9f c0             	setg   %al
80105975:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105979:	84 c0                	test   %al,%al
8010597b:	74 30                	je     801059ad <strncpy+0x4c>
8010597d:	8b 45 0c             	mov    0xc(%ebp),%eax
80105980:	0f b6 10             	movzbl (%eax),%edx
80105983:	8b 45 08             	mov    0x8(%ebp),%eax
80105986:	88 10                	mov    %dl,(%eax)
80105988:	8b 45 08             	mov    0x8(%ebp),%eax
8010598b:	0f b6 00             	movzbl (%eax),%eax
8010598e:	84 c0                	test   %al,%al
80105990:	0f 95 c0             	setne  %al
80105993:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105997:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
8010599b:	84 c0                	test   %al,%al
8010599d:	75 cf                	jne    8010596e <strncpy+0xd>
    ;
  while(n-- > 0)
8010599f:	eb 0c                	jmp    801059ad <strncpy+0x4c>
    *s++ = 0;
801059a1:	8b 45 08             	mov    0x8(%ebp),%eax
801059a4:	c6 00 00             	movb   $0x0,(%eax)
801059a7:	83 45 08 01          	addl   $0x1,0x8(%ebp)
801059ab:	eb 01                	jmp    801059ae <strncpy+0x4d>
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
801059ad:	90                   	nop
801059ae:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801059b2:	0f 9f c0             	setg   %al
801059b5:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801059b9:	84 c0                	test   %al,%al
801059bb:	75 e4                	jne    801059a1 <strncpy+0x40>
    *s++ = 0;
  return os;
801059bd:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801059c0:	c9                   	leave  
801059c1:	c3                   	ret    

801059c2 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
801059c2:	55                   	push   %ebp
801059c3:	89 e5                	mov    %esp,%ebp
801059c5:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
801059c8:	8b 45 08             	mov    0x8(%ebp),%eax
801059cb:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
801059ce:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801059d2:	7f 05                	jg     801059d9 <safestrcpy+0x17>
    return os;
801059d4:	8b 45 fc             	mov    -0x4(%ebp),%eax
801059d7:	eb 35                	jmp    80105a0e <safestrcpy+0x4c>
  while(--n > 0 && (*s++ = *t++) != 0)
801059d9:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801059dd:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801059e1:	7e 22                	jle    80105a05 <safestrcpy+0x43>
801059e3:	8b 45 0c             	mov    0xc(%ebp),%eax
801059e6:	0f b6 10             	movzbl (%eax),%edx
801059e9:	8b 45 08             	mov    0x8(%ebp),%eax
801059ec:	88 10                	mov    %dl,(%eax)
801059ee:	8b 45 08             	mov    0x8(%ebp),%eax
801059f1:	0f b6 00             	movzbl (%eax),%eax
801059f4:	84 c0                	test   %al,%al
801059f6:	0f 95 c0             	setne  %al
801059f9:	83 45 08 01          	addl   $0x1,0x8(%ebp)
801059fd:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
80105a01:	84 c0                	test   %al,%al
80105a03:	75 d4                	jne    801059d9 <safestrcpy+0x17>
    ;
  *s = 0;
80105a05:	8b 45 08             	mov    0x8(%ebp),%eax
80105a08:	c6 00 00             	movb   $0x0,(%eax)
  return os;
80105a0b:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105a0e:	c9                   	leave  
80105a0f:	c3                   	ret    

80105a10 <strlen>:

int
strlen(const char *s)
{
80105a10:	55                   	push   %ebp
80105a11:	89 e5                	mov    %esp,%ebp
80105a13:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
80105a16:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105a1d:	eb 04                	jmp    80105a23 <strlen+0x13>
80105a1f:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105a23:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105a26:	03 45 08             	add    0x8(%ebp),%eax
80105a29:	0f b6 00             	movzbl (%eax),%eax
80105a2c:	84 c0                	test   %al,%al
80105a2e:	75 ef                	jne    80105a1f <strlen+0xf>
    ;
  return n;
80105a30:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105a33:	c9                   	leave  
80105a34:	c3                   	ret    
80105a35:	00 00                	add    %al,(%eax)
	...

80105a38 <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
80105a38:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80105a3c:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
80105a40:	55                   	push   %ebp
  pushl %ebx
80105a41:	53                   	push   %ebx
  pushl %esi
80105a42:	56                   	push   %esi
  pushl %edi
80105a43:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80105a44:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80105a46:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
80105a48:	5f                   	pop    %edi
  popl %esi
80105a49:	5e                   	pop    %esi
  popl %ebx
80105a4a:	5b                   	pop    %ebx
  popl %ebp
80105a4b:	5d                   	pop    %ebp
  ret
80105a4c:	c3                   	ret    
80105a4d:	00 00                	add    %al,(%eax)
	...

80105a50 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from process p.
int
fetchint(struct proc *p, uint addr, int *ip)
{
80105a50:	55                   	push   %ebp
80105a51:	89 e5                	mov    %esp,%ebp
  if(addr >= p->sz || addr+4 > p->sz)
80105a53:	8b 45 08             	mov    0x8(%ebp),%eax
80105a56:	8b 00                	mov    (%eax),%eax
80105a58:	3b 45 0c             	cmp    0xc(%ebp),%eax
80105a5b:	76 0f                	jbe    80105a6c <fetchint+0x1c>
80105a5d:	8b 45 0c             	mov    0xc(%ebp),%eax
80105a60:	8d 50 04             	lea    0x4(%eax),%edx
80105a63:	8b 45 08             	mov    0x8(%ebp),%eax
80105a66:	8b 00                	mov    (%eax),%eax
80105a68:	39 c2                	cmp    %eax,%edx
80105a6a:	76 07                	jbe    80105a73 <fetchint+0x23>
    return -1;
80105a6c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105a71:	eb 0f                	jmp    80105a82 <fetchint+0x32>
  *ip = *(int*)(addr);
80105a73:	8b 45 0c             	mov    0xc(%ebp),%eax
80105a76:	8b 10                	mov    (%eax),%edx
80105a78:	8b 45 10             	mov    0x10(%ebp),%eax
80105a7b:	89 10                	mov    %edx,(%eax)
  return 0;
80105a7d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105a82:	5d                   	pop    %ebp
80105a83:	c3                   	ret    

80105a84 <fetchstr>:
// Fetch the nul-terminated string at addr from process p.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(struct proc *p, uint addr, char **pp)
{
80105a84:	55                   	push   %ebp
80105a85:	89 e5                	mov    %esp,%ebp
80105a87:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= p->sz)
80105a8a:	8b 45 08             	mov    0x8(%ebp),%eax
80105a8d:	8b 00                	mov    (%eax),%eax
80105a8f:	3b 45 0c             	cmp    0xc(%ebp),%eax
80105a92:	77 07                	ja     80105a9b <fetchstr+0x17>
    return -1;
80105a94:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105a99:	eb 45                	jmp    80105ae0 <fetchstr+0x5c>
  *pp = (char*)addr;
80105a9b:	8b 55 0c             	mov    0xc(%ebp),%edx
80105a9e:	8b 45 10             	mov    0x10(%ebp),%eax
80105aa1:	89 10                	mov    %edx,(%eax)
  ep = (char*)p->sz;
80105aa3:	8b 45 08             	mov    0x8(%ebp),%eax
80105aa6:	8b 00                	mov    (%eax),%eax
80105aa8:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
80105aab:	8b 45 10             	mov    0x10(%ebp),%eax
80105aae:	8b 00                	mov    (%eax),%eax
80105ab0:	89 45 fc             	mov    %eax,-0x4(%ebp)
80105ab3:	eb 1e                	jmp    80105ad3 <fetchstr+0x4f>
    if(*s == 0)
80105ab5:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105ab8:	0f b6 00             	movzbl (%eax),%eax
80105abb:	84 c0                	test   %al,%al
80105abd:	75 10                	jne    80105acf <fetchstr+0x4b>
      return s - *pp;
80105abf:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105ac2:	8b 45 10             	mov    0x10(%ebp),%eax
80105ac5:	8b 00                	mov    (%eax),%eax
80105ac7:	89 d1                	mov    %edx,%ecx
80105ac9:	29 c1                	sub    %eax,%ecx
80105acb:	89 c8                	mov    %ecx,%eax
80105acd:	eb 11                	jmp    80105ae0 <fetchstr+0x5c>

  if(addr >= p->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)p->sz;
  for(s = *pp; s < ep; s++)
80105acf:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105ad3:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105ad6:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105ad9:	72 da                	jb     80105ab5 <fetchstr+0x31>
    if(*s == 0)
      return s - *pp;
  return -1;
80105adb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105ae0:	c9                   	leave  
80105ae1:	c3                   	ret    

80105ae2 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
80105ae2:	55                   	push   %ebp
80105ae3:	89 e5                	mov    %esp,%ebp
80105ae5:	83 ec 0c             	sub    $0xc,%esp
  return fetchint(proc, proc->tf->esp + 4 + 4*n, ip);
80105ae8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105aee:	8b 40 18             	mov    0x18(%eax),%eax
80105af1:	8b 50 44             	mov    0x44(%eax),%edx
80105af4:	8b 45 08             	mov    0x8(%ebp),%eax
80105af7:	c1 e0 02             	shl    $0x2,%eax
80105afa:	01 d0                	add    %edx,%eax
80105afc:	8d 48 04             	lea    0x4(%eax),%ecx
80105aff:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105b05:	8b 55 0c             	mov    0xc(%ebp),%edx
80105b08:	89 54 24 08          	mov    %edx,0x8(%esp)
80105b0c:	89 4c 24 04          	mov    %ecx,0x4(%esp)
80105b10:	89 04 24             	mov    %eax,(%esp)
80105b13:	e8 38 ff ff ff       	call   80105a50 <fetchint>
}
80105b18:	c9                   	leave  
80105b19:	c3                   	ret    

80105b1a <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
80105b1a:	55                   	push   %ebp
80105b1b:	89 e5                	mov    %esp,%ebp
80105b1d:	83 ec 18             	sub    $0x18,%esp
  int i;
  
  if(argint(n, &i) < 0)
80105b20:	8d 45 fc             	lea    -0x4(%ebp),%eax
80105b23:	89 44 24 04          	mov    %eax,0x4(%esp)
80105b27:	8b 45 08             	mov    0x8(%ebp),%eax
80105b2a:	89 04 24             	mov    %eax,(%esp)
80105b2d:	e8 b0 ff ff ff       	call   80105ae2 <argint>
80105b32:	85 c0                	test   %eax,%eax
80105b34:	79 07                	jns    80105b3d <argptr+0x23>
    return -1;
80105b36:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105b3b:	eb 3d                	jmp    80105b7a <argptr+0x60>
  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
80105b3d:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105b40:	89 c2                	mov    %eax,%edx
80105b42:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105b48:	8b 00                	mov    (%eax),%eax
80105b4a:	39 c2                	cmp    %eax,%edx
80105b4c:	73 16                	jae    80105b64 <argptr+0x4a>
80105b4e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105b51:	89 c2                	mov    %eax,%edx
80105b53:	8b 45 10             	mov    0x10(%ebp),%eax
80105b56:	01 c2                	add    %eax,%edx
80105b58:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105b5e:	8b 00                	mov    (%eax),%eax
80105b60:	39 c2                	cmp    %eax,%edx
80105b62:	76 07                	jbe    80105b6b <argptr+0x51>
    return -1;
80105b64:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105b69:	eb 0f                	jmp    80105b7a <argptr+0x60>
  *pp = (char*)i;
80105b6b:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105b6e:	89 c2                	mov    %eax,%edx
80105b70:	8b 45 0c             	mov    0xc(%ebp),%eax
80105b73:	89 10                	mov    %edx,(%eax)
  return 0;
80105b75:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105b7a:	c9                   	leave  
80105b7b:	c3                   	ret    

80105b7c <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80105b7c:	55                   	push   %ebp
80105b7d:	89 e5                	mov    %esp,%ebp
80105b7f:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  if(argint(n, &addr) < 0)
80105b82:	8d 45 fc             	lea    -0x4(%ebp),%eax
80105b85:	89 44 24 04          	mov    %eax,0x4(%esp)
80105b89:	8b 45 08             	mov    0x8(%ebp),%eax
80105b8c:	89 04 24             	mov    %eax,(%esp)
80105b8f:	e8 4e ff ff ff       	call   80105ae2 <argint>
80105b94:	85 c0                	test   %eax,%eax
80105b96:	79 07                	jns    80105b9f <argstr+0x23>
    return -1;
80105b98:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105b9d:	eb 1e                	jmp    80105bbd <argstr+0x41>
  return fetchstr(proc, addr, pp);
80105b9f:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105ba2:	89 c2                	mov    %eax,%edx
80105ba4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105baa:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80105bad:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105bb1:	89 54 24 04          	mov    %edx,0x4(%esp)
80105bb5:	89 04 24             	mov    %eax,(%esp)
80105bb8:	e8 c7 fe ff ff       	call   80105a84 <fetchstr>
}
80105bbd:	c9                   	leave  
80105bbe:	c3                   	ret    

80105bbf <syscall>:
[SYS_shmdel]	sys_shmdel,
};

void
syscall(void)
{
80105bbf:	55                   	push   %ebp
80105bc0:	89 e5                	mov    %esp,%ebp
80105bc2:	53                   	push   %ebx
80105bc3:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->tf->eax;
80105bc6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105bcc:	8b 40 18             	mov    0x18(%eax),%eax
80105bcf:	8b 40 1c             	mov    0x1c(%eax),%eax
80105bd2:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num >= 0 && num < SYS_open && syscalls[num]) {
80105bd5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105bd9:	78 2e                	js     80105c09 <syscall+0x4a>
80105bdb:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
80105bdf:	7f 28                	jg     80105c09 <syscall+0x4a>
80105be1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105be4:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
80105beb:	85 c0                	test   %eax,%eax
80105bed:	74 1a                	je     80105c09 <syscall+0x4a>
    proc->tf->eax = syscalls[num]();
80105bef:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105bf5:	8b 58 18             	mov    0x18(%eax),%ebx
80105bf8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105bfb:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
80105c02:	ff d0                	call   *%eax
80105c04:	89 43 1c             	mov    %eax,0x1c(%ebx)
80105c07:	eb 73                	jmp    80105c7c <syscall+0xbd>
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
80105c09:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
80105c0d:	7e 30                	jle    80105c3f <syscall+0x80>
80105c0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c12:	83 f8 1c             	cmp    $0x1c,%eax
80105c15:	77 28                	ja     80105c3f <syscall+0x80>
80105c17:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c1a:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
80105c21:	85 c0                	test   %eax,%eax
80105c23:	74 1a                	je     80105c3f <syscall+0x80>
    proc->tf->eax = syscalls[num]();
80105c25:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105c2b:	8b 58 18             	mov    0x18(%eax),%ebx
80105c2e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c31:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
80105c38:	ff d0                	call   *%eax
80105c3a:	89 43 1c             	mov    %eax,0x1c(%ebx)
80105c3d:	eb 3d                	jmp    80105c7c <syscall+0xbd>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
80105c3f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105c45:	8d 48 6c             	lea    0x6c(%eax),%ecx
80105c48:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  if(num >= 0 && num < SYS_open && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
80105c4e:	8b 40 10             	mov    0x10(%eax),%eax
80105c51:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105c54:	89 54 24 0c          	mov    %edx,0xc(%esp)
80105c58:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105c5c:	89 44 24 04          	mov    %eax,0x4(%esp)
80105c60:	c7 04 24 37 94 10 80 	movl   $0x80109437,(%esp)
80105c67:	e8 35 a7 ff ff       	call   801003a1 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
80105c6c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105c72:	8b 40 18             	mov    0x18(%eax),%eax
80105c75:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
80105c7c:	83 c4 24             	add    $0x24,%esp
80105c7f:	5b                   	pop    %ebx
80105c80:	5d                   	pop    %ebp
80105c81:	c3                   	ret    
	...

80105c84 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
80105c84:	55                   	push   %ebp
80105c85:	89 e5                	mov    %esp,%ebp
80105c87:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
80105c8a:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105c8d:	89 44 24 04          	mov    %eax,0x4(%esp)
80105c91:	8b 45 08             	mov    0x8(%ebp),%eax
80105c94:	89 04 24             	mov    %eax,(%esp)
80105c97:	e8 46 fe ff ff       	call   80105ae2 <argint>
80105c9c:	85 c0                	test   %eax,%eax
80105c9e:	79 07                	jns    80105ca7 <argfd+0x23>
    return -1;
80105ca0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105ca5:	eb 50                	jmp    80105cf7 <argfd+0x73>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
80105ca7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105caa:	85 c0                	test   %eax,%eax
80105cac:	78 21                	js     80105ccf <argfd+0x4b>
80105cae:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105cb1:	83 f8 0f             	cmp    $0xf,%eax
80105cb4:	7f 19                	jg     80105ccf <argfd+0x4b>
80105cb6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105cbc:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105cbf:	83 c2 08             	add    $0x8,%edx
80105cc2:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105cc6:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105cc9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105ccd:	75 07                	jne    80105cd6 <argfd+0x52>
    return -1;
80105ccf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105cd4:	eb 21                	jmp    80105cf7 <argfd+0x73>
  if(pfd)
80105cd6:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80105cda:	74 08                	je     80105ce4 <argfd+0x60>
    *pfd = fd;
80105cdc:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105cdf:	8b 45 0c             	mov    0xc(%ebp),%eax
80105ce2:	89 10                	mov    %edx,(%eax)
  if(pf)
80105ce4:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105ce8:	74 08                	je     80105cf2 <argfd+0x6e>
    *pf = f;
80105cea:	8b 45 10             	mov    0x10(%ebp),%eax
80105ced:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105cf0:	89 10                	mov    %edx,(%eax)
  return 0;
80105cf2:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105cf7:	c9                   	leave  
80105cf8:	c3                   	ret    

80105cf9 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
80105cf9:	55                   	push   %ebp
80105cfa:	89 e5                	mov    %esp,%ebp
80105cfc:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80105cff:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105d06:	eb 30                	jmp    80105d38 <fdalloc+0x3f>
    if(proc->ofile[fd] == 0){
80105d08:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105d0e:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105d11:	83 c2 08             	add    $0x8,%edx
80105d14:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105d18:	85 c0                	test   %eax,%eax
80105d1a:	75 18                	jne    80105d34 <fdalloc+0x3b>
      proc->ofile[fd] = f;
80105d1c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105d22:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105d25:	8d 4a 08             	lea    0x8(%edx),%ecx
80105d28:	8b 55 08             	mov    0x8(%ebp),%edx
80105d2b:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
80105d2f:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105d32:	eb 0f                	jmp    80105d43 <fdalloc+0x4a>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80105d34:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105d38:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
80105d3c:	7e ca                	jle    80105d08 <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
80105d3e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105d43:	c9                   	leave  
80105d44:	c3                   	ret    

80105d45 <sys_dup>:

int
sys_dup(void)
{
80105d45:	55                   	push   %ebp
80105d46:	89 e5                	mov    %esp,%ebp
80105d48:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
80105d4b:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105d4e:	89 44 24 08          	mov    %eax,0x8(%esp)
80105d52:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105d59:	00 
80105d5a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105d61:	e8 1e ff ff ff       	call   80105c84 <argfd>
80105d66:	85 c0                	test   %eax,%eax
80105d68:	79 07                	jns    80105d71 <sys_dup+0x2c>
    return -1;
80105d6a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105d6f:	eb 29                	jmp    80105d9a <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
80105d71:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d74:	89 04 24             	mov    %eax,(%esp)
80105d77:	e8 7d ff ff ff       	call   80105cf9 <fdalloc>
80105d7c:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105d7f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105d83:	79 07                	jns    80105d8c <sys_dup+0x47>
    return -1;
80105d85:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105d8a:	eb 0e                	jmp    80105d9a <sys_dup+0x55>
  filedup(f);
80105d8c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d8f:	89 04 24             	mov    %eax,(%esp)
80105d92:	e8 e5 b1 ff ff       	call   80100f7c <filedup>
  return fd;
80105d97:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80105d9a:	c9                   	leave  
80105d9b:	c3                   	ret    

80105d9c <sys_read>:

int
sys_read(void)
{
80105d9c:	55                   	push   %ebp
80105d9d:	89 e5                	mov    %esp,%ebp
80105d9f:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80105da2:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105da5:	89 44 24 08          	mov    %eax,0x8(%esp)
80105da9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105db0:	00 
80105db1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105db8:	e8 c7 fe ff ff       	call   80105c84 <argfd>
80105dbd:	85 c0                	test   %eax,%eax
80105dbf:	78 35                	js     80105df6 <sys_read+0x5a>
80105dc1:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105dc4:	89 44 24 04          	mov    %eax,0x4(%esp)
80105dc8:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80105dcf:	e8 0e fd ff ff       	call   80105ae2 <argint>
80105dd4:	85 c0                	test   %eax,%eax
80105dd6:	78 1e                	js     80105df6 <sys_read+0x5a>
80105dd8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ddb:	89 44 24 08          	mov    %eax,0x8(%esp)
80105ddf:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105de2:	89 44 24 04          	mov    %eax,0x4(%esp)
80105de6:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105ded:	e8 28 fd ff ff       	call   80105b1a <argptr>
80105df2:	85 c0                	test   %eax,%eax
80105df4:	79 07                	jns    80105dfd <sys_read+0x61>
    return -1;
80105df6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105dfb:	eb 19                	jmp    80105e16 <sys_read+0x7a>
  return fileread(f, p, n);
80105dfd:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80105e00:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105e03:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e06:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105e0a:	89 54 24 04          	mov    %edx,0x4(%esp)
80105e0e:	89 04 24             	mov    %eax,(%esp)
80105e11:	e8 d3 b2 ff ff       	call   801010e9 <fileread>
}
80105e16:	c9                   	leave  
80105e17:	c3                   	ret    

80105e18 <sys_write>:

int
sys_write(void)
{
80105e18:	55                   	push   %ebp
80105e19:	89 e5                	mov    %esp,%ebp
80105e1b:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80105e1e:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105e21:	89 44 24 08          	mov    %eax,0x8(%esp)
80105e25:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105e2c:	00 
80105e2d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105e34:	e8 4b fe ff ff       	call   80105c84 <argfd>
80105e39:	85 c0                	test   %eax,%eax
80105e3b:	78 35                	js     80105e72 <sys_write+0x5a>
80105e3d:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105e40:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e44:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80105e4b:	e8 92 fc ff ff       	call   80105ae2 <argint>
80105e50:	85 c0                	test   %eax,%eax
80105e52:	78 1e                	js     80105e72 <sys_write+0x5a>
80105e54:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e57:	89 44 24 08          	mov    %eax,0x8(%esp)
80105e5b:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105e5e:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e62:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105e69:	e8 ac fc ff ff       	call   80105b1a <argptr>
80105e6e:	85 c0                	test   %eax,%eax
80105e70:	79 07                	jns    80105e79 <sys_write+0x61>
    return -1;
80105e72:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105e77:	eb 19                	jmp    80105e92 <sys_write+0x7a>
  return filewrite(f, p, n);
80105e79:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80105e7c:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105e7f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e82:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105e86:	89 54 24 04          	mov    %edx,0x4(%esp)
80105e8a:	89 04 24             	mov    %eax,(%esp)
80105e8d:	e8 13 b3 ff ff       	call   801011a5 <filewrite>
}
80105e92:	c9                   	leave  
80105e93:	c3                   	ret    

80105e94 <sys_close>:

int
sys_close(void)
{
80105e94:	55                   	push   %ebp
80105e95:	89 e5                	mov    %esp,%ebp
80105e97:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
80105e9a:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105e9d:	89 44 24 08          	mov    %eax,0x8(%esp)
80105ea1:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105ea4:	89 44 24 04          	mov    %eax,0x4(%esp)
80105ea8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105eaf:	e8 d0 fd ff ff       	call   80105c84 <argfd>
80105eb4:	85 c0                	test   %eax,%eax
80105eb6:	79 07                	jns    80105ebf <sys_close+0x2b>
    return -1;
80105eb8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105ebd:	eb 24                	jmp    80105ee3 <sys_close+0x4f>
  proc->ofile[fd] = 0;
80105ebf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105ec5:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105ec8:	83 c2 08             	add    $0x8,%edx
80105ecb:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80105ed2:	00 
  fileclose(f);
80105ed3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ed6:	89 04 24             	mov    %eax,(%esp)
80105ed9:	e8 e6 b0 ff ff       	call   80100fc4 <fileclose>
  return 0;
80105ede:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105ee3:	c9                   	leave  
80105ee4:	c3                   	ret    

80105ee5 <sys_fstat>:

int
sys_fstat(void)
{
80105ee5:	55                   	push   %ebp
80105ee6:	89 e5                	mov    %esp,%ebp
80105ee8:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
80105eeb:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105eee:	89 44 24 08          	mov    %eax,0x8(%esp)
80105ef2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105ef9:	00 
80105efa:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105f01:	e8 7e fd ff ff       	call   80105c84 <argfd>
80105f06:	85 c0                	test   %eax,%eax
80105f08:	78 1f                	js     80105f29 <sys_fstat+0x44>
80105f0a:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80105f11:	00 
80105f12:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105f15:	89 44 24 04          	mov    %eax,0x4(%esp)
80105f19:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105f20:	e8 f5 fb ff ff       	call   80105b1a <argptr>
80105f25:	85 c0                	test   %eax,%eax
80105f27:	79 07                	jns    80105f30 <sys_fstat+0x4b>
    return -1;
80105f29:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f2e:	eb 12                	jmp    80105f42 <sys_fstat+0x5d>
  return filestat(f, st);
80105f30:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105f33:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f36:	89 54 24 04          	mov    %edx,0x4(%esp)
80105f3a:	89 04 24             	mov    %eax,(%esp)
80105f3d:	e8 58 b1 ff ff       	call   8010109a <filestat>
}
80105f42:	c9                   	leave  
80105f43:	c3                   	ret    

80105f44 <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
80105f44:	55                   	push   %ebp
80105f45:	89 e5                	mov    %esp,%ebp
80105f47:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
80105f4a:	8d 45 d8             	lea    -0x28(%ebp),%eax
80105f4d:	89 44 24 04          	mov    %eax,0x4(%esp)
80105f51:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105f58:	e8 1f fc ff ff       	call   80105b7c <argstr>
80105f5d:	85 c0                	test   %eax,%eax
80105f5f:	78 17                	js     80105f78 <sys_link+0x34>
80105f61:	8d 45 dc             	lea    -0x24(%ebp),%eax
80105f64:	89 44 24 04          	mov    %eax,0x4(%esp)
80105f68:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105f6f:	e8 08 fc ff ff       	call   80105b7c <argstr>
80105f74:	85 c0                	test   %eax,%eax
80105f76:	79 0a                	jns    80105f82 <sys_link+0x3e>
    return -1;
80105f78:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f7d:	e9 3c 01 00 00       	jmp    801060be <sys_link+0x17a>
  if((ip = namei(old)) == 0)
80105f82:	8b 45 d8             	mov    -0x28(%ebp),%eax
80105f85:	89 04 24             	mov    %eax,(%esp)
80105f88:	e8 7d c4 ff ff       	call   8010240a <namei>
80105f8d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105f90:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105f94:	75 0a                	jne    80105fa0 <sys_link+0x5c>
    return -1;
80105f96:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f9b:	e9 1e 01 00 00       	jmp    801060be <sys_link+0x17a>

  begin_trans();
80105fa0:	e8 c4 d4 ff ff       	call   80103469 <begin_trans>

  ilock(ip);
80105fa5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105fa8:	89 04 24             	mov    %eax,(%esp)
80105fab:	e8 b8 b8 ff ff       	call   80101868 <ilock>
  if(ip->type == T_DIR){
80105fb0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105fb3:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105fb7:	66 83 f8 01          	cmp    $0x1,%ax
80105fbb:	75 1a                	jne    80105fd7 <sys_link+0x93>
    iunlockput(ip);
80105fbd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105fc0:	89 04 24             	mov    %eax,(%esp)
80105fc3:	e8 24 bb ff ff       	call   80101aec <iunlockput>
    commit_trans();
80105fc8:	e8 e5 d4 ff ff       	call   801034b2 <commit_trans>
    return -1;
80105fcd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105fd2:	e9 e7 00 00 00       	jmp    801060be <sys_link+0x17a>
  }

  ip->nlink++;
80105fd7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105fda:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105fde:	8d 50 01             	lea    0x1(%eax),%edx
80105fe1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105fe4:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80105fe8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105feb:	89 04 24             	mov    %eax,(%esp)
80105fee:	e8 b9 b6 ff ff       	call   801016ac <iupdate>
  iunlock(ip);
80105ff3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ff6:	89 04 24             	mov    %eax,(%esp)
80105ff9:	e8 b8 b9 ff ff       	call   801019b6 <iunlock>

  if((dp = nameiparent(new, name)) == 0)
80105ffe:	8b 45 dc             	mov    -0x24(%ebp),%eax
80106001:	8d 55 e2             	lea    -0x1e(%ebp),%edx
80106004:	89 54 24 04          	mov    %edx,0x4(%esp)
80106008:	89 04 24             	mov    %eax,(%esp)
8010600b:	e8 1c c4 ff ff       	call   8010242c <nameiparent>
80106010:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106013:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106017:	74 68                	je     80106081 <sys_link+0x13d>
    goto bad;
  ilock(dp);
80106019:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010601c:	89 04 24             	mov    %eax,(%esp)
8010601f:	e8 44 b8 ff ff       	call   80101868 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
80106024:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106027:	8b 10                	mov    (%eax),%edx
80106029:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010602c:	8b 00                	mov    (%eax),%eax
8010602e:	39 c2                	cmp    %eax,%edx
80106030:	75 20                	jne    80106052 <sys_link+0x10e>
80106032:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106035:	8b 40 04             	mov    0x4(%eax),%eax
80106038:	89 44 24 08          	mov    %eax,0x8(%esp)
8010603c:	8d 45 e2             	lea    -0x1e(%ebp),%eax
8010603f:	89 44 24 04          	mov    %eax,0x4(%esp)
80106043:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106046:	89 04 24             	mov    %eax,(%esp)
80106049:	e8 fb c0 ff ff       	call   80102149 <dirlink>
8010604e:	85 c0                	test   %eax,%eax
80106050:	79 0d                	jns    8010605f <sys_link+0x11b>
    iunlockput(dp);
80106052:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106055:	89 04 24             	mov    %eax,(%esp)
80106058:	e8 8f ba ff ff       	call   80101aec <iunlockput>
    goto bad;
8010605d:	eb 23                	jmp    80106082 <sys_link+0x13e>
  }
  iunlockput(dp);
8010605f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106062:	89 04 24             	mov    %eax,(%esp)
80106065:	e8 82 ba ff ff       	call   80101aec <iunlockput>
  iput(ip);
8010606a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010606d:	89 04 24             	mov    %eax,(%esp)
80106070:	e8 a6 b9 ff ff       	call   80101a1b <iput>

  commit_trans();
80106075:	e8 38 d4 ff ff       	call   801034b2 <commit_trans>

  return 0;
8010607a:	b8 00 00 00 00       	mov    $0x0,%eax
8010607f:	eb 3d                	jmp    801060be <sys_link+0x17a>
  ip->nlink++;
  iupdate(ip);
  iunlock(ip);

  if((dp = nameiparent(new, name)) == 0)
    goto bad;
80106081:	90                   	nop
  commit_trans();

  return 0;

bad:
  ilock(ip);
80106082:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106085:	89 04 24             	mov    %eax,(%esp)
80106088:	e8 db b7 ff ff       	call   80101868 <ilock>
  ip->nlink--;
8010608d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106090:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106094:	8d 50 ff             	lea    -0x1(%eax),%edx
80106097:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010609a:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
8010609e:	8b 45 f4             	mov    -0xc(%ebp),%eax
801060a1:	89 04 24             	mov    %eax,(%esp)
801060a4:	e8 03 b6 ff ff       	call   801016ac <iupdate>
  iunlockput(ip);
801060a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801060ac:	89 04 24             	mov    %eax,(%esp)
801060af:	e8 38 ba ff ff       	call   80101aec <iunlockput>
  commit_trans();
801060b4:	e8 f9 d3 ff ff       	call   801034b2 <commit_trans>
  return -1;
801060b9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801060be:	c9                   	leave  
801060bf:	c3                   	ret    

801060c0 <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
801060c0:	55                   	push   %ebp
801060c1:	89 e5                	mov    %esp,%ebp
801060c3:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801060c6:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
801060cd:	eb 4b                	jmp    8010611a <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801060cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801060d2:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801060d9:	00 
801060da:	89 44 24 08          	mov    %eax,0x8(%esp)
801060de:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801060e1:	89 44 24 04          	mov    %eax,0x4(%esp)
801060e5:	8b 45 08             	mov    0x8(%ebp),%eax
801060e8:	89 04 24             	mov    %eax,(%esp)
801060eb:	e8 6e bc ff ff       	call   80101d5e <readi>
801060f0:	83 f8 10             	cmp    $0x10,%eax
801060f3:	74 0c                	je     80106101 <isdirempty+0x41>
      panic("isdirempty: readi");
801060f5:	c7 04 24 53 94 10 80 	movl   $0x80109453,(%esp)
801060fc:	e8 3c a4 ff ff       	call   8010053d <panic>
    if(de.inum != 0)
80106101:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
80106105:	66 85 c0             	test   %ax,%ax
80106108:	74 07                	je     80106111 <isdirempty+0x51>
      return 0;
8010610a:	b8 00 00 00 00       	mov    $0x0,%eax
8010610f:	eb 1b                	jmp    8010612c <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80106111:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106114:	83 c0 10             	add    $0x10,%eax
80106117:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010611a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010611d:	8b 45 08             	mov    0x8(%ebp),%eax
80106120:	8b 40 18             	mov    0x18(%eax),%eax
80106123:	39 c2                	cmp    %eax,%edx
80106125:	72 a8                	jb     801060cf <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
80106127:	b8 01 00 00 00       	mov    $0x1,%eax
}
8010612c:	c9                   	leave  
8010612d:	c3                   	ret    

8010612e <unlink>:


int
unlink(char* path)
{
8010612e:	55                   	push   %ebp
8010612f:	89 e5                	mov    %esp,%ebp
80106131:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ];
  uint off;

  if((dp = nameiparent(path, name)) == 0)
80106134:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80106137:	89 44 24 04          	mov    %eax,0x4(%esp)
8010613b:	8b 45 08             	mov    0x8(%ebp),%eax
8010613e:	89 04 24             	mov    %eax,(%esp)
80106141:	e8 e6 c2 ff ff       	call   8010242c <nameiparent>
80106146:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106149:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010614d:	75 0a                	jne    80106159 <unlink+0x2b>
    return -1;
8010614f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106154:	e9 85 01 00 00       	jmp    801062de <unlink+0x1b0>

  begin_trans();
80106159:	e8 0b d3 ff ff       	call   80103469 <begin_trans>

  ilock(dp);
8010615e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106161:	89 04 24             	mov    %eax,(%esp)
80106164:	e8 ff b6 ff ff       	call   80101868 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80106169:	c7 44 24 04 65 94 10 	movl   $0x80109465,0x4(%esp)
80106170:	80 
80106171:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80106174:	89 04 24             	mov    %eax,(%esp)
80106177:	e8 e3 be ff ff       	call   8010205f <namecmp>
8010617c:	85 c0                	test   %eax,%eax
8010617e:	0f 84 45 01 00 00    	je     801062c9 <unlink+0x19b>
80106184:	c7 44 24 04 67 94 10 	movl   $0x80109467,0x4(%esp)
8010618b:	80 
8010618c:	8d 45 d2             	lea    -0x2e(%ebp),%eax
8010618f:	89 04 24             	mov    %eax,(%esp)
80106192:	e8 c8 be ff ff       	call   8010205f <namecmp>
80106197:	85 c0                	test   %eax,%eax
80106199:	0f 84 2a 01 00 00    	je     801062c9 <unlink+0x19b>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
8010619f:	8d 45 cc             	lea    -0x34(%ebp),%eax
801061a2:	89 44 24 08          	mov    %eax,0x8(%esp)
801061a6:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801061a9:	89 44 24 04          	mov    %eax,0x4(%esp)
801061ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061b0:	89 04 24             	mov    %eax,(%esp)
801061b3:	e8 c9 be ff ff       	call   80102081 <dirlookup>
801061b8:	89 45 f0             	mov    %eax,-0x10(%ebp)
801061bb:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801061bf:	0f 84 03 01 00 00    	je     801062c8 <unlink+0x19a>
    goto bad;
  ilock(ip);
801061c5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801061c8:	89 04 24             	mov    %eax,(%esp)
801061cb:	e8 98 b6 ff ff       	call   80101868 <ilock>

  if(ip->nlink < 1)
801061d0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801061d3:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801061d7:	66 85 c0             	test   %ax,%ax
801061da:	7f 0c                	jg     801061e8 <unlink+0xba>
    panic("unlink: nlink < 1");
801061dc:	c7 04 24 6a 94 10 80 	movl   $0x8010946a,(%esp)
801061e3:	e8 55 a3 ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
801061e8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801061eb:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801061ef:	66 83 f8 01          	cmp    $0x1,%ax
801061f3:	75 1f                	jne    80106214 <unlink+0xe6>
801061f5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801061f8:	89 04 24             	mov    %eax,(%esp)
801061fb:	e8 c0 fe ff ff       	call   801060c0 <isdirempty>
80106200:	85 c0                	test   %eax,%eax
80106202:	75 10                	jne    80106214 <unlink+0xe6>
    iunlockput(ip);
80106204:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106207:	89 04 24             	mov    %eax,(%esp)
8010620a:	e8 dd b8 ff ff       	call   80101aec <iunlockput>
    goto bad;
8010620f:	e9 b5 00 00 00       	jmp    801062c9 <unlink+0x19b>
  }

  memset(&de, 0, sizeof(de));
80106214:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
8010621b:	00 
8010621c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106223:	00 
80106224:	8d 45 e0             	lea    -0x20(%ebp),%eax
80106227:	89 04 24             	mov    %eax,(%esp)
8010622a:	e8 63 f5 ff ff       	call   80105792 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010622f:	8b 45 cc             	mov    -0x34(%ebp),%eax
80106232:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80106239:	00 
8010623a:	89 44 24 08          	mov    %eax,0x8(%esp)
8010623e:	8d 45 e0             	lea    -0x20(%ebp),%eax
80106241:	89 44 24 04          	mov    %eax,0x4(%esp)
80106245:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106248:	89 04 24             	mov    %eax,(%esp)
8010624b:	e8 79 bc ff ff       	call   80101ec9 <writei>
80106250:	83 f8 10             	cmp    $0x10,%eax
80106253:	74 0c                	je     80106261 <unlink+0x133>
    panic("unlink: writei");
80106255:	c7 04 24 7c 94 10 80 	movl   $0x8010947c,(%esp)
8010625c:	e8 dc a2 ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR){
80106261:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106264:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106268:	66 83 f8 01          	cmp    $0x1,%ax
8010626c:	75 1c                	jne    8010628a <unlink+0x15c>
    dp->nlink--;
8010626e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106271:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106275:	8d 50 ff             	lea    -0x1(%eax),%edx
80106278:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010627b:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
8010627f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106282:	89 04 24             	mov    %eax,(%esp)
80106285:	e8 22 b4 ff ff       	call   801016ac <iupdate>
  }
  iunlockput(dp);
8010628a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010628d:	89 04 24             	mov    %eax,(%esp)
80106290:	e8 57 b8 ff ff       	call   80101aec <iunlockput>

  ip->nlink--;
80106295:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106298:	0f b7 40 16          	movzwl 0x16(%eax),%eax
8010629c:	8d 50 ff             	lea    -0x1(%eax),%edx
8010629f:	8b 45 f0             	mov    -0x10(%ebp),%eax
801062a2:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801062a6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801062a9:	89 04 24             	mov    %eax,(%esp)
801062ac:	e8 fb b3 ff ff       	call   801016ac <iupdate>
  iunlockput(ip);
801062b1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801062b4:	89 04 24             	mov    %eax,(%esp)
801062b7:	e8 30 b8 ff ff       	call   80101aec <iunlockput>

  commit_trans();
801062bc:	e8 f1 d1 ff ff       	call   801034b2 <commit_trans>

  return 0;
801062c1:	b8 00 00 00 00       	mov    $0x0,%eax
801062c6:	eb 16                	jmp    801062de <unlink+0x1b0>
  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    goto bad;
801062c8:	90                   	nop
  commit_trans();

  return 0;

bad:
  iunlockput(dp);
801062c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062cc:	89 04 24             	mov    %eax,(%esp)
801062cf:	e8 18 b8 ff ff       	call   80101aec <iunlockput>
  commit_trans();
801062d4:	e8 d9 d1 ff ff       	call   801034b2 <commit_trans>
  return -1;
801062d9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801062de:	c9                   	leave  
801062df:	c3                   	ret    

801062e0 <sys_unlink>:


//PAGEBREAK!
int
sys_unlink(void)
{
801062e0:	55                   	push   %ebp
801062e1:	89 e5                	mov    %esp,%ebp
801062e3:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
801062e6:	8d 45 cc             	lea    -0x34(%ebp),%eax
801062e9:	89 44 24 04          	mov    %eax,0x4(%esp)
801062ed:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801062f4:	e8 83 f8 ff ff       	call   80105b7c <argstr>
801062f9:	85 c0                	test   %eax,%eax
801062fb:	79 0a                	jns    80106307 <sys_unlink+0x27>
    return -1;
801062fd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106302:	e9 aa 01 00 00       	jmp    801064b1 <sys_unlink+0x1d1>
  if((dp = nameiparent(path, name)) == 0)
80106307:	8b 45 cc             	mov    -0x34(%ebp),%eax
8010630a:	8d 55 d2             	lea    -0x2e(%ebp),%edx
8010630d:	89 54 24 04          	mov    %edx,0x4(%esp)
80106311:	89 04 24             	mov    %eax,(%esp)
80106314:	e8 13 c1 ff ff       	call   8010242c <nameiparent>
80106319:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010631c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106320:	75 0a                	jne    8010632c <sys_unlink+0x4c>
    return -1;
80106322:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106327:	e9 85 01 00 00       	jmp    801064b1 <sys_unlink+0x1d1>

  begin_trans();
8010632c:	e8 38 d1 ff ff       	call   80103469 <begin_trans>

  ilock(dp);
80106331:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106334:	89 04 24             	mov    %eax,(%esp)
80106337:	e8 2c b5 ff ff       	call   80101868 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
8010633c:	c7 44 24 04 65 94 10 	movl   $0x80109465,0x4(%esp)
80106343:	80 
80106344:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80106347:	89 04 24             	mov    %eax,(%esp)
8010634a:	e8 10 bd ff ff       	call   8010205f <namecmp>
8010634f:	85 c0                	test   %eax,%eax
80106351:	0f 84 45 01 00 00    	je     8010649c <sys_unlink+0x1bc>
80106357:	c7 44 24 04 67 94 10 	movl   $0x80109467,0x4(%esp)
8010635e:	80 
8010635f:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80106362:	89 04 24             	mov    %eax,(%esp)
80106365:	e8 f5 bc ff ff       	call   8010205f <namecmp>
8010636a:	85 c0                	test   %eax,%eax
8010636c:	0f 84 2a 01 00 00    	je     8010649c <sys_unlink+0x1bc>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
80106372:	8d 45 c8             	lea    -0x38(%ebp),%eax
80106375:	89 44 24 08          	mov    %eax,0x8(%esp)
80106379:	8d 45 d2             	lea    -0x2e(%ebp),%eax
8010637c:	89 44 24 04          	mov    %eax,0x4(%esp)
80106380:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106383:	89 04 24             	mov    %eax,(%esp)
80106386:	e8 f6 bc ff ff       	call   80102081 <dirlookup>
8010638b:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010638e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106392:	0f 84 03 01 00 00    	je     8010649b <sys_unlink+0x1bb>
    goto bad;
  ilock(ip);
80106398:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010639b:	89 04 24             	mov    %eax,(%esp)
8010639e:	e8 c5 b4 ff ff       	call   80101868 <ilock>

  if(ip->nlink < 1)
801063a3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801063a6:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801063aa:	66 85 c0             	test   %ax,%ax
801063ad:	7f 0c                	jg     801063bb <sys_unlink+0xdb>
    panic("unlink: nlink < 1");
801063af:	c7 04 24 6a 94 10 80 	movl   $0x8010946a,(%esp)
801063b6:	e8 82 a1 ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
801063bb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801063be:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801063c2:	66 83 f8 01          	cmp    $0x1,%ax
801063c6:	75 1f                	jne    801063e7 <sys_unlink+0x107>
801063c8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801063cb:	89 04 24             	mov    %eax,(%esp)
801063ce:	e8 ed fc ff ff       	call   801060c0 <isdirempty>
801063d3:	85 c0                	test   %eax,%eax
801063d5:	75 10                	jne    801063e7 <sys_unlink+0x107>
    iunlockput(ip);
801063d7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801063da:	89 04 24             	mov    %eax,(%esp)
801063dd:	e8 0a b7 ff ff       	call   80101aec <iunlockput>
    goto bad;
801063e2:	e9 b5 00 00 00       	jmp    8010649c <sys_unlink+0x1bc>
  }

  memset(&de, 0, sizeof(de));
801063e7:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
801063ee:	00 
801063ef:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801063f6:	00 
801063f7:	8d 45 e0             	lea    -0x20(%ebp),%eax
801063fa:	89 04 24             	mov    %eax,(%esp)
801063fd:	e8 90 f3 ff ff       	call   80105792 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80106402:	8b 45 c8             	mov    -0x38(%ebp),%eax
80106405:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
8010640c:	00 
8010640d:	89 44 24 08          	mov    %eax,0x8(%esp)
80106411:	8d 45 e0             	lea    -0x20(%ebp),%eax
80106414:	89 44 24 04          	mov    %eax,0x4(%esp)
80106418:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010641b:	89 04 24             	mov    %eax,(%esp)
8010641e:	e8 a6 ba ff ff       	call   80101ec9 <writei>
80106423:	83 f8 10             	cmp    $0x10,%eax
80106426:	74 0c                	je     80106434 <sys_unlink+0x154>
    panic("unlink: writei");
80106428:	c7 04 24 7c 94 10 80 	movl   $0x8010947c,(%esp)
8010642f:	e8 09 a1 ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR){
80106434:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106437:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010643b:	66 83 f8 01          	cmp    $0x1,%ax
8010643f:	75 1c                	jne    8010645d <sys_unlink+0x17d>
    dp->nlink--;
80106441:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106444:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106448:	8d 50 ff             	lea    -0x1(%eax),%edx
8010644b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010644e:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80106452:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106455:	89 04 24             	mov    %eax,(%esp)
80106458:	e8 4f b2 ff ff       	call   801016ac <iupdate>
  }
  iunlockput(dp);
8010645d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106460:	89 04 24             	mov    %eax,(%esp)
80106463:	e8 84 b6 ff ff       	call   80101aec <iunlockput>

  ip->nlink--;
80106468:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010646b:	0f b7 40 16          	movzwl 0x16(%eax),%eax
8010646f:	8d 50 ff             	lea    -0x1(%eax),%edx
80106472:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106475:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80106479:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010647c:	89 04 24             	mov    %eax,(%esp)
8010647f:	e8 28 b2 ff ff       	call   801016ac <iupdate>
  iunlockput(ip);
80106484:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106487:	89 04 24             	mov    %eax,(%esp)
8010648a:	e8 5d b6 ff ff       	call   80101aec <iunlockput>

  commit_trans();
8010648f:	e8 1e d0 ff ff       	call   801034b2 <commit_trans>

  return 0;
80106494:	b8 00 00 00 00       	mov    $0x0,%eax
80106499:	eb 16                	jmp    801064b1 <sys_unlink+0x1d1>
  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    goto bad;
8010649b:	90                   	nop
  commit_trans();

  return 0;

bad:
  iunlockput(dp);
8010649c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010649f:	89 04 24             	mov    %eax,(%esp)
801064a2:	e8 45 b6 ff ff       	call   80101aec <iunlockput>
  commit_trans();
801064a7:	e8 06 d0 ff ff       	call   801034b2 <commit_trans>
  return -1;
801064ac:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801064b1:	c9                   	leave  
801064b2:	c3                   	ret    

801064b3 <create>:

static struct inode*
create(char *path, short type, short major, short minor)
{
801064b3:	55                   	push   %ebp
801064b4:	89 e5                	mov    %esp,%ebp
801064b6:	83 ec 48             	sub    $0x48,%esp
801064b9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801064bc:	8b 55 10             	mov    0x10(%ebp),%edx
801064bf:	8b 45 14             	mov    0x14(%ebp),%eax
801064c2:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
801064c6:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
801064ca:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];
  if((dp = nameiparent(path, name)) == 0)
801064ce:	8d 45 de             	lea    -0x22(%ebp),%eax
801064d1:	89 44 24 04          	mov    %eax,0x4(%esp)
801064d5:	8b 45 08             	mov    0x8(%ebp),%eax
801064d8:	89 04 24             	mov    %eax,(%esp)
801064db:	e8 4c bf ff ff       	call   8010242c <nameiparent>
801064e0:	89 45 f4             	mov    %eax,-0xc(%ebp)
801064e3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801064e7:	75 0a                	jne    801064f3 <create+0x40>
    return 0;
801064e9:	b8 00 00 00 00       	mov    $0x0,%eax
801064ee:	e9 7e 01 00 00       	jmp    80106671 <create+0x1be>
  ilock(dp);
801064f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064f6:	89 04 24             	mov    %eax,(%esp)
801064f9:	e8 6a b3 ff ff       	call   80101868 <ilock>
  if((ip = dirlookup(dp, name, &off)) != 0){
801064fe:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106501:	89 44 24 08          	mov    %eax,0x8(%esp)
80106505:	8d 45 de             	lea    -0x22(%ebp),%eax
80106508:	89 44 24 04          	mov    %eax,0x4(%esp)
8010650c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010650f:	89 04 24             	mov    %eax,(%esp)
80106512:	e8 6a bb ff ff       	call   80102081 <dirlookup>
80106517:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010651a:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010651e:	74 47                	je     80106567 <create+0xb4>
    iunlockput(dp);
80106520:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106523:	89 04 24             	mov    %eax,(%esp)
80106526:	e8 c1 b5 ff ff       	call   80101aec <iunlockput>
    ilock(ip);
8010652b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010652e:	89 04 24             	mov    %eax,(%esp)
80106531:	e8 32 b3 ff ff       	call   80101868 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
80106536:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
8010653b:	75 15                	jne    80106552 <create+0x9f>
8010653d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106540:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106544:	66 83 f8 02          	cmp    $0x2,%ax
80106548:	75 08                	jne    80106552 <create+0x9f>
      return ip;
8010654a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010654d:	e9 1f 01 00 00       	jmp    80106671 <create+0x1be>
    iunlockput(ip);
80106552:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106555:	89 04 24             	mov    %eax,(%esp)
80106558:	e8 8f b5 ff ff       	call   80101aec <iunlockput>
    return 0;
8010655d:	b8 00 00 00 00       	mov    $0x0,%eax
80106562:	e9 0a 01 00 00       	jmp    80106671 <create+0x1be>
  }
  if((ip = ialloc(dp->dev, type)) == 0)
80106567:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
8010656b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010656e:	8b 00                	mov    (%eax),%eax
80106570:	89 54 24 04          	mov    %edx,0x4(%esp)
80106574:	89 04 24             	mov    %eax,(%esp)
80106577:	e8 53 b0 ff ff       	call   801015cf <ialloc>
8010657c:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010657f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106583:	75 0c                	jne    80106591 <create+0xde>
    panic("create: ialloc");
80106585:	c7 04 24 8b 94 10 80 	movl   $0x8010948b,(%esp)
8010658c:	e8 ac 9f ff ff       	call   8010053d <panic>
  ilock(ip);
80106591:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106594:	89 04 24             	mov    %eax,(%esp)
80106597:	e8 cc b2 ff ff       	call   80101868 <ilock>
  ip->major = major;
8010659c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010659f:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
801065a3:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
801065a7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065aa:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
801065ae:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
801065b2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065b5:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
801065bb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065be:	89 04 24             	mov    %eax,(%esp)
801065c1:	e8 e6 b0 ff ff       	call   801016ac <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
801065c6:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
801065cb:	75 6a                	jne    80106637 <create+0x184>
    dp->nlink++;  // for ".."
801065cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065d0:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801065d4:	8d 50 01             	lea    0x1(%eax),%edx
801065d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065da:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
801065de:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065e1:	89 04 24             	mov    %eax,(%esp)
801065e4:	e8 c3 b0 ff ff       	call   801016ac <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
801065e9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065ec:	8b 40 04             	mov    0x4(%eax),%eax
801065ef:	89 44 24 08          	mov    %eax,0x8(%esp)
801065f3:	c7 44 24 04 65 94 10 	movl   $0x80109465,0x4(%esp)
801065fa:	80 
801065fb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065fe:	89 04 24             	mov    %eax,(%esp)
80106601:	e8 43 bb ff ff       	call   80102149 <dirlink>
80106606:	85 c0                	test   %eax,%eax
80106608:	78 21                	js     8010662b <create+0x178>
8010660a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010660d:	8b 40 04             	mov    0x4(%eax),%eax
80106610:	89 44 24 08          	mov    %eax,0x8(%esp)
80106614:	c7 44 24 04 67 94 10 	movl   $0x80109467,0x4(%esp)
8010661b:	80 
8010661c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010661f:	89 04 24             	mov    %eax,(%esp)
80106622:	e8 22 bb ff ff       	call   80102149 <dirlink>
80106627:	85 c0                	test   %eax,%eax
80106629:	79 0c                	jns    80106637 <create+0x184>
      panic("create dots");
8010662b:	c7 04 24 9a 94 10 80 	movl   $0x8010949a,(%esp)
80106632:	e8 06 9f ff ff       	call   8010053d <panic>
  }
  if(dirlink(dp, name, ip->inum) < 0)
80106637:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010663a:	8b 40 04             	mov    0x4(%eax),%eax
8010663d:	89 44 24 08          	mov    %eax,0x8(%esp)
80106641:	8d 45 de             	lea    -0x22(%ebp),%eax
80106644:	89 44 24 04          	mov    %eax,0x4(%esp)
80106648:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010664b:	89 04 24             	mov    %eax,(%esp)
8010664e:	e8 f6 ba ff ff       	call   80102149 <dirlink>
80106653:	85 c0                	test   %eax,%eax
80106655:	79 0c                	jns    80106663 <create+0x1b0>
    panic("create: dirlink");
80106657:	c7 04 24 a6 94 10 80 	movl   $0x801094a6,(%esp)
8010665e:	e8 da 9e ff ff       	call   8010053d <panic>
  iunlockput(dp);
80106663:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106666:	89 04 24             	mov    %eax,(%esp)
80106669:	e8 7e b4 ff ff       	call   80101aec <iunlockput>

  return ip;
8010666e:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80106671:	c9                   	leave  
80106672:	c3                   	ret    

80106673 <fileopen>:

struct file*
fileopen(char *path, int omode)
{
80106673:	55                   	push   %ebp
80106674:	89 e5                	mov    %esp,%ebp
80106676:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  struct inode *ip;

  if(omode & O_CREATE){
80106679:	8b 45 0c             	mov    0xc(%ebp),%eax
8010667c:	25 00 02 00 00       	and    $0x200,%eax
80106681:	85 c0                	test   %eax,%eax
80106683:	74 40                	je     801066c5 <fileopen+0x52>
    begin_trans();
80106685:	e8 df cd ff ff       	call   80103469 <begin_trans>
    ip = create(path, T_FILE, 0, 0);
8010668a:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106691:	00 
80106692:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106699:	00 
8010669a:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
801066a1:	00 
801066a2:	8b 45 08             	mov    0x8(%ebp),%eax
801066a5:	89 04 24             	mov    %eax,(%esp)
801066a8:	e8 06 fe ff ff       	call   801064b3 <create>
801066ad:	89 45 f4             	mov    %eax,-0xc(%ebp)
    commit_trans();
801066b0:	e8 fd cd ff ff       	call   801034b2 <commit_trans>
    if(ip == 0)
801066b5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801066b9:	75 5b                	jne    80106716 <fileopen+0xa3>
      return 0;
801066bb:	b8 00 00 00 00       	mov    $0x0,%eax
801066c0:	e9 f9 00 00 00       	jmp    801067be <fileopen+0x14b>
  } else {
    if((ip = namei(path)) == 0)
801066c5:	8b 45 08             	mov    0x8(%ebp),%eax
801066c8:	89 04 24             	mov    %eax,(%esp)
801066cb:	e8 3a bd ff ff       	call   8010240a <namei>
801066d0:	89 45 f4             	mov    %eax,-0xc(%ebp)
801066d3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801066d7:	75 0a                	jne    801066e3 <fileopen+0x70>
      return 0;
801066d9:	b8 00 00 00 00       	mov    $0x0,%eax
801066de:	e9 db 00 00 00       	jmp    801067be <fileopen+0x14b>
    ilock(ip);
801066e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066e6:	89 04 24             	mov    %eax,(%esp)
801066e9:	e8 7a b1 ff ff       	call   80101868 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
801066ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066f1:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801066f5:	66 83 f8 01          	cmp    $0x1,%ax
801066f9:	75 1b                	jne    80106716 <fileopen+0xa3>
801066fb:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801066ff:	74 15                	je     80106716 <fileopen+0xa3>
      iunlockput(ip);
80106701:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106704:	89 04 24             	mov    %eax,(%esp)
80106707:	e8 e0 b3 ff ff       	call   80101aec <iunlockput>
      return 0;
8010670c:	b8 00 00 00 00       	mov    $0x0,%eax
80106711:	e9 a8 00 00 00       	jmp    801067be <fileopen+0x14b>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80106716:	e8 01 a8 ff ff       	call   80100f1c <filealloc>
8010671b:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010671e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106722:	74 14                	je     80106738 <fileopen+0xc5>
80106724:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106727:	89 04 24             	mov    %eax,(%esp)
8010672a:	e8 ca f5 ff ff       	call   80105cf9 <fdalloc>
8010672f:	89 45 ec             	mov    %eax,-0x14(%ebp)
80106732:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80106736:	79 23                	jns    8010675b <fileopen+0xe8>
    if(f)
80106738:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010673c:	74 0b                	je     80106749 <fileopen+0xd6>
      fileclose(f);
8010673e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106741:	89 04 24             	mov    %eax,(%esp)
80106744:	e8 7b a8 ff ff       	call   80100fc4 <fileclose>
    iunlockput(ip);
80106749:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010674c:	89 04 24             	mov    %eax,(%esp)
8010674f:	e8 98 b3 ff ff       	call   80101aec <iunlockput>
    return 0;
80106754:	b8 00 00 00 00       	mov    $0x0,%eax
80106759:	eb 63                	jmp    801067be <fileopen+0x14b>
  }
  iunlock(ip);
8010675b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010675e:	89 04 24             	mov    %eax,(%esp)
80106761:	e8 50 b2 ff ff       	call   801019b6 <iunlock>

  f->type = FD_INODE;
80106766:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106769:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
8010676f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106772:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106775:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
80106778:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010677b:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80106782:	8b 45 0c             	mov    0xc(%ebp),%eax
80106785:	83 e0 01             	and    $0x1,%eax
80106788:	85 c0                	test   %eax,%eax
8010678a:	0f 94 c2             	sete   %dl
8010678d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106790:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80106793:	8b 45 0c             	mov    0xc(%ebp),%eax
80106796:	83 e0 01             	and    $0x1,%eax
80106799:	84 c0                	test   %al,%al
8010679b:	75 0a                	jne    801067a7 <fileopen+0x134>
8010679d:	8b 45 0c             	mov    0xc(%ebp),%eax
801067a0:	83 e0 02             	and    $0x2,%eax
801067a3:	85 c0                	test   %eax,%eax
801067a5:	74 07                	je     801067ae <fileopen+0x13b>
801067a7:	b8 01 00 00 00       	mov    $0x1,%eax
801067ac:	eb 05                	jmp    801067b3 <fileopen+0x140>
801067ae:	b8 00 00 00 00       	mov    $0x0,%eax
801067b3:	89 c2                	mov    %eax,%edx
801067b5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801067b8:	88 50 09             	mov    %dl,0x9(%eax)
  return f;
801067bb:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
801067be:	c9                   	leave  
801067bf:	c3                   	ret    

801067c0 <sys_open>:

int
sys_open(void)
{
801067c0:	55                   	push   %ebp
801067c1:	89 e5                	mov    %esp,%ebp
801067c3:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
801067c6:	8d 45 e8             	lea    -0x18(%ebp),%eax
801067c9:	89 44 24 04          	mov    %eax,0x4(%esp)
801067cd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801067d4:	e8 a3 f3 ff ff       	call   80105b7c <argstr>
801067d9:	85 c0                	test   %eax,%eax
801067db:	78 17                	js     801067f4 <sys_open+0x34>
801067dd:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801067e0:	89 44 24 04          	mov    %eax,0x4(%esp)
801067e4:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801067eb:	e8 f2 f2 ff ff       	call   80105ae2 <argint>
801067f0:	85 c0                	test   %eax,%eax
801067f2:	79 0a                	jns    801067fe <sys_open+0x3e>
    return -1;
801067f4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801067f9:	e9 46 01 00 00       	jmp    80106944 <sys_open+0x184>
  if(omode & O_CREATE){
801067fe:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106801:	25 00 02 00 00       	and    $0x200,%eax
80106806:	85 c0                	test   %eax,%eax
80106808:	74 40                	je     8010684a <sys_open+0x8a>
    begin_trans();
8010680a:	e8 5a cc ff ff       	call   80103469 <begin_trans>
    ip = create(path, T_FILE, 0, 0);
8010680f:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106812:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106819:	00 
8010681a:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106821:	00 
80106822:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80106829:	00 
8010682a:	89 04 24             	mov    %eax,(%esp)
8010682d:	e8 81 fc ff ff       	call   801064b3 <create>
80106832:	89 45 f4             	mov    %eax,-0xc(%ebp)
    commit_trans();
80106835:	e8 78 cc ff ff       	call   801034b2 <commit_trans>
    if(ip == 0)
8010683a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010683e:	75 5c                	jne    8010689c <sys_open+0xdc>
      return -1;
80106840:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106845:	e9 fa 00 00 00       	jmp    80106944 <sys_open+0x184>
  } else {
    if((ip = namei(path)) == 0)
8010684a:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010684d:	89 04 24             	mov    %eax,(%esp)
80106850:	e8 b5 bb ff ff       	call   8010240a <namei>
80106855:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106858:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010685c:	75 0a                	jne    80106868 <sys_open+0xa8>
      return -1;
8010685e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106863:	e9 dc 00 00 00       	jmp    80106944 <sys_open+0x184>
    ilock(ip);
80106868:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010686b:	89 04 24             	mov    %eax,(%esp)
8010686e:	e8 f5 af ff ff       	call   80101868 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80106873:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106876:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010687a:	66 83 f8 01          	cmp    $0x1,%ax
8010687e:	75 1c                	jne    8010689c <sys_open+0xdc>
80106880:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106883:	85 c0                	test   %eax,%eax
80106885:	74 15                	je     8010689c <sys_open+0xdc>
      iunlockput(ip);
80106887:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010688a:	89 04 24             	mov    %eax,(%esp)
8010688d:	e8 5a b2 ff ff       	call   80101aec <iunlockput>
      return -1;
80106892:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106897:	e9 a8 00 00 00       	jmp    80106944 <sys_open+0x184>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
8010689c:	e8 7b a6 ff ff       	call   80100f1c <filealloc>
801068a1:	89 45 f0             	mov    %eax,-0x10(%ebp)
801068a4:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801068a8:	74 14                	je     801068be <sys_open+0xfe>
801068aa:	8b 45 f0             	mov    -0x10(%ebp),%eax
801068ad:	89 04 24             	mov    %eax,(%esp)
801068b0:	e8 44 f4 ff ff       	call   80105cf9 <fdalloc>
801068b5:	89 45 ec             	mov    %eax,-0x14(%ebp)
801068b8:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801068bc:	79 23                	jns    801068e1 <sys_open+0x121>
    if(f)
801068be:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801068c2:	74 0b                	je     801068cf <sys_open+0x10f>
      fileclose(f);
801068c4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801068c7:	89 04 24             	mov    %eax,(%esp)
801068ca:	e8 f5 a6 ff ff       	call   80100fc4 <fileclose>
    iunlockput(ip);
801068cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068d2:	89 04 24             	mov    %eax,(%esp)
801068d5:	e8 12 b2 ff ff       	call   80101aec <iunlockput>
    return -1;
801068da:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801068df:	eb 63                	jmp    80106944 <sys_open+0x184>
  }
  iunlock(ip);
801068e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068e4:	89 04 24             	mov    %eax,(%esp)
801068e7:	e8 ca b0 ff ff       	call   801019b6 <iunlock>

  f->type = FD_INODE;
801068ec:	8b 45 f0             	mov    -0x10(%ebp),%eax
801068ef:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
801068f5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801068f8:	8b 55 f4             	mov    -0xc(%ebp),%edx
801068fb:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
801068fe:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106901:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80106908:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010690b:	83 e0 01             	and    $0x1,%eax
8010690e:	85 c0                	test   %eax,%eax
80106910:	0f 94 c2             	sete   %dl
80106913:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106916:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80106919:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010691c:	83 e0 01             	and    $0x1,%eax
8010691f:	84 c0                	test   %al,%al
80106921:	75 0a                	jne    8010692d <sys_open+0x16d>
80106923:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106926:	83 e0 02             	and    $0x2,%eax
80106929:	85 c0                	test   %eax,%eax
8010692b:	74 07                	je     80106934 <sys_open+0x174>
8010692d:	b8 01 00 00 00       	mov    $0x1,%eax
80106932:	eb 05                	jmp    80106939 <sys_open+0x179>
80106934:	b8 00 00 00 00       	mov    $0x0,%eax
80106939:	89 c2                	mov    %eax,%edx
8010693b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010693e:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
80106941:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
80106944:	c9                   	leave  
80106945:	c3                   	ret    

80106946 <sys_mkdir>:

int
sys_mkdir(void)
{
80106946:	55                   	push   %ebp
80106947:	89 e5                	mov    %esp,%ebp
80106949:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_trans();
8010694c:	e8 18 cb ff ff       	call   80103469 <begin_trans>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80106951:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106954:	89 44 24 04          	mov    %eax,0x4(%esp)
80106958:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010695f:	e8 18 f2 ff ff       	call   80105b7c <argstr>
80106964:	85 c0                	test   %eax,%eax
80106966:	78 2c                	js     80106994 <sys_mkdir+0x4e>
80106968:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010696b:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106972:	00 
80106973:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010697a:	00 
8010697b:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80106982:	00 
80106983:	89 04 24             	mov    %eax,(%esp)
80106986:	e8 28 fb ff ff       	call   801064b3 <create>
8010698b:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010698e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106992:	75 0c                	jne    801069a0 <sys_mkdir+0x5a>
    commit_trans();
80106994:	e8 19 cb ff ff       	call   801034b2 <commit_trans>
    return -1;
80106999:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010699e:	eb 15                	jmp    801069b5 <sys_mkdir+0x6f>
  }
  iunlockput(ip);
801069a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069a3:	89 04 24             	mov    %eax,(%esp)
801069a6:	e8 41 b1 ff ff       	call   80101aec <iunlockput>
  commit_trans();
801069ab:	e8 02 cb ff ff       	call   801034b2 <commit_trans>
  return 0;
801069b0:	b8 00 00 00 00       	mov    $0x0,%eax
}
801069b5:	c9                   	leave  
801069b6:	c3                   	ret    

801069b7 <sys_mknod>:

int
sys_mknod(void)
{
801069b7:	55                   	push   %ebp
801069b8:	89 e5                	mov    %esp,%ebp
801069ba:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
801069bd:	e8 a7 ca ff ff       	call   80103469 <begin_trans>
  if((len=argstr(0, &path)) < 0 ||
801069c2:	8d 45 ec             	lea    -0x14(%ebp),%eax
801069c5:	89 44 24 04          	mov    %eax,0x4(%esp)
801069c9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801069d0:	e8 a7 f1 ff ff       	call   80105b7c <argstr>
801069d5:	89 45 f4             	mov    %eax,-0xc(%ebp)
801069d8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801069dc:	78 5e                	js     80106a3c <sys_mknod+0x85>
     argint(1, &major) < 0 ||
801069de:	8d 45 e8             	lea    -0x18(%ebp),%eax
801069e1:	89 44 24 04          	mov    %eax,0x4(%esp)
801069e5:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801069ec:	e8 f1 f0 ff ff       	call   80105ae2 <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
801069f1:	85 c0                	test   %eax,%eax
801069f3:	78 47                	js     80106a3c <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
801069f5:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801069f8:	89 44 24 04          	mov    %eax,0x4(%esp)
801069fc:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80106a03:	e8 da f0 ff ff       	call   80105ae2 <argint>
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
80106a08:	85 c0                	test   %eax,%eax
80106a0a:	78 30                	js     80106a3c <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
80106a0c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106a0f:	0f bf c8             	movswl %ax,%ecx
80106a12:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106a15:	0f bf d0             	movswl %ax,%edx
80106a18:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80106a1b:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106a1f:	89 54 24 08          	mov    %edx,0x8(%esp)
80106a23:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80106a2a:	00 
80106a2b:	89 04 24             	mov    %eax,(%esp)
80106a2e:	e8 80 fa ff ff       	call   801064b3 <create>
80106a33:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106a36:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106a3a:	75 0c                	jne    80106a48 <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    commit_trans();
80106a3c:	e8 71 ca ff ff       	call   801034b2 <commit_trans>
    return -1;
80106a41:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106a46:	eb 15                	jmp    80106a5d <sys_mknod+0xa6>
  }
  iunlockput(ip);
80106a48:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106a4b:	89 04 24             	mov    %eax,(%esp)
80106a4e:	e8 99 b0 ff ff       	call   80101aec <iunlockput>
  commit_trans();
80106a53:	e8 5a ca ff ff       	call   801034b2 <commit_trans>
  return 0;
80106a58:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106a5d:	c9                   	leave  
80106a5e:	c3                   	ret    

80106a5f <sys_chdir>:

int
sys_chdir(void)
{
80106a5f:	55                   	push   %ebp
80106a60:	89 e5                	mov    %esp,%ebp
80106a62:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0)
80106a65:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106a68:	89 44 24 04          	mov    %eax,0x4(%esp)
80106a6c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106a73:	e8 04 f1 ff ff       	call   80105b7c <argstr>
80106a78:	85 c0                	test   %eax,%eax
80106a7a:	78 14                	js     80106a90 <sys_chdir+0x31>
80106a7c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106a7f:	89 04 24             	mov    %eax,(%esp)
80106a82:	e8 83 b9 ff ff       	call   8010240a <namei>
80106a87:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106a8a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106a8e:	75 07                	jne    80106a97 <sys_chdir+0x38>
    return -1;
80106a90:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106a95:	eb 57                	jmp    80106aee <sys_chdir+0x8f>
  ilock(ip);
80106a97:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a9a:	89 04 24             	mov    %eax,(%esp)
80106a9d:	e8 c6 ad ff ff       	call   80101868 <ilock>
  if(ip->type != T_DIR){
80106aa2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106aa5:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106aa9:	66 83 f8 01          	cmp    $0x1,%ax
80106aad:	74 12                	je     80106ac1 <sys_chdir+0x62>
    iunlockput(ip);
80106aaf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ab2:	89 04 24             	mov    %eax,(%esp)
80106ab5:	e8 32 b0 ff ff       	call   80101aec <iunlockput>
    return -1;
80106aba:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106abf:	eb 2d                	jmp    80106aee <sys_chdir+0x8f>
  }
  iunlock(ip);
80106ac1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ac4:	89 04 24             	mov    %eax,(%esp)
80106ac7:	e8 ea ae ff ff       	call   801019b6 <iunlock>
  iput(proc->cwd);
80106acc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106ad2:	8b 40 68             	mov    0x68(%eax),%eax
80106ad5:	89 04 24             	mov    %eax,(%esp)
80106ad8:	e8 3e af ff ff       	call   80101a1b <iput>
  proc->cwd = ip;
80106add:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106ae3:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106ae6:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
80106ae9:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106aee:	c9                   	leave  
80106aef:	c3                   	ret    

80106af0 <sys_exec>:

int
sys_exec(void)
{
80106af0:	55                   	push   %ebp
80106af1:	89 e5                	mov    %esp,%ebp
80106af3:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80106af9:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106afc:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b00:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106b07:	e8 70 f0 ff ff       	call   80105b7c <argstr>
80106b0c:	85 c0                	test   %eax,%eax
80106b0e:	78 1a                	js     80106b2a <sys_exec+0x3a>
80106b10:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80106b16:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b1a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106b21:	e8 bc ef ff ff       	call   80105ae2 <argint>
80106b26:	85 c0                	test   %eax,%eax
80106b28:	79 0a                	jns    80106b34 <sys_exec+0x44>
    return -1;
80106b2a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106b2f:	e9 e2 00 00 00       	jmp    80106c16 <sys_exec+0x126>
  }
  memset(argv, 0, sizeof(argv));
80106b34:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80106b3b:	00 
80106b3c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106b43:	00 
80106b44:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106b4a:	89 04 24             	mov    %eax,(%esp)
80106b4d:	e8 40 ec ff ff       	call   80105792 <memset>
  for(i=0;; i++){
80106b52:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
80106b59:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b5c:	83 f8 1f             	cmp    $0x1f,%eax
80106b5f:	76 0a                	jbe    80106b6b <sys_exec+0x7b>
      return -1;
80106b61:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106b66:	e9 ab 00 00 00       	jmp    80106c16 <sys_exec+0x126>
    if(fetchint(proc, uargv+4*i, (int*)&uarg) < 0)
80106b6b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b6e:	c1 e0 02             	shl    $0x2,%eax
80106b71:	89 c2                	mov    %eax,%edx
80106b73:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80106b79:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
80106b7c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106b82:	8d 95 68 ff ff ff    	lea    -0x98(%ebp),%edx
80106b88:	89 54 24 08          	mov    %edx,0x8(%esp)
80106b8c:	89 4c 24 04          	mov    %ecx,0x4(%esp)
80106b90:	89 04 24             	mov    %eax,(%esp)
80106b93:	e8 b8 ee ff ff       	call   80105a50 <fetchint>
80106b98:	85 c0                	test   %eax,%eax
80106b9a:	79 07                	jns    80106ba3 <sys_exec+0xb3>
      return -1;
80106b9c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106ba1:	eb 73                	jmp    80106c16 <sys_exec+0x126>
    if(uarg == 0){
80106ba3:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80106ba9:	85 c0                	test   %eax,%eax
80106bab:	75 26                	jne    80106bd3 <sys_exec+0xe3>
      argv[i] = 0;
80106bad:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106bb0:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
80106bb7:	00 00 00 00 
      break;
80106bbb:	90                   	nop
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
80106bbc:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106bbf:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
80106bc5:	89 54 24 04          	mov    %edx,0x4(%esp)
80106bc9:	89 04 24             	mov    %eax,(%esp)
80106bcc:	e8 2b 9f ff ff       	call   80100afc <exec>
80106bd1:	eb 43                	jmp    80106c16 <sys_exec+0x126>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
80106bd3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106bd6:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80106bdd:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106be3:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
80106be6:	8b 95 68 ff ff ff    	mov    -0x98(%ebp),%edx
80106bec:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106bf2:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106bf6:	89 54 24 04          	mov    %edx,0x4(%esp)
80106bfa:	89 04 24             	mov    %eax,(%esp)
80106bfd:	e8 82 ee ff ff       	call   80105a84 <fetchstr>
80106c02:	85 c0                	test   %eax,%eax
80106c04:	79 07                	jns    80106c0d <sys_exec+0x11d>
      return -1;
80106c06:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106c0b:	eb 09                	jmp    80106c16 <sys_exec+0x126>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
80106c0d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
80106c11:	e9 43 ff ff ff       	jmp    80106b59 <sys_exec+0x69>
  return exec(path, argv);
}
80106c16:	c9                   	leave  
80106c17:	c3                   	ret    

80106c18 <sys_pipe>:

int
sys_pipe(void)
{
80106c18:	55                   	push   %ebp
80106c19:	89 e5                	mov    %esp,%ebp
80106c1b:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80106c1e:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
80106c25:	00 
80106c26:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106c29:	89 44 24 04          	mov    %eax,0x4(%esp)
80106c2d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106c34:	e8 e1 ee ff ff       	call   80105b1a <argptr>
80106c39:	85 c0                	test   %eax,%eax
80106c3b:	79 0a                	jns    80106c47 <sys_pipe+0x2f>
    return -1;
80106c3d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106c42:	e9 9b 00 00 00       	jmp    80106ce2 <sys_pipe+0xca>
  if(pipealloc(&rf, &wf) < 0)
80106c47:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106c4a:	89 44 24 04          	mov    %eax,0x4(%esp)
80106c4e:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106c51:	89 04 24             	mov    %eax,(%esp)
80106c54:	e8 2b d2 ff ff       	call   80103e84 <pipealloc>
80106c59:	85 c0                	test   %eax,%eax
80106c5b:	79 07                	jns    80106c64 <sys_pipe+0x4c>
    return -1;
80106c5d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106c62:	eb 7e                	jmp    80106ce2 <sys_pipe+0xca>
  fd0 = -1;
80106c64:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80106c6b:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106c6e:	89 04 24             	mov    %eax,(%esp)
80106c71:	e8 83 f0 ff ff       	call   80105cf9 <fdalloc>
80106c76:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106c79:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106c7d:	78 14                	js     80106c93 <sys_pipe+0x7b>
80106c7f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106c82:	89 04 24             	mov    %eax,(%esp)
80106c85:	e8 6f f0 ff ff       	call   80105cf9 <fdalloc>
80106c8a:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106c8d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106c91:	79 37                	jns    80106cca <sys_pipe+0xb2>
    if(fd0 >= 0)
80106c93:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106c97:	78 14                	js     80106cad <sys_pipe+0x95>
      proc->ofile[fd0] = 0;
80106c99:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106c9f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106ca2:	83 c2 08             	add    $0x8,%edx
80106ca5:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80106cac:	00 
    fileclose(rf);
80106cad:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106cb0:	89 04 24             	mov    %eax,(%esp)
80106cb3:	e8 0c a3 ff ff       	call   80100fc4 <fileclose>
    fileclose(wf);
80106cb8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106cbb:	89 04 24             	mov    %eax,(%esp)
80106cbe:	e8 01 a3 ff ff       	call   80100fc4 <fileclose>
    return -1;
80106cc3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106cc8:	eb 18                	jmp    80106ce2 <sys_pipe+0xca>
  }
  fd[0] = fd0;
80106cca:	8b 45 ec             	mov    -0x14(%ebp),%eax
80106ccd:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106cd0:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
80106cd2:	8b 45 ec             	mov    -0x14(%ebp),%eax
80106cd5:	8d 50 04             	lea    0x4(%eax),%edx
80106cd8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106cdb:	89 02                	mov    %eax,(%edx)
  return 0;
80106cdd:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106ce2:	c9                   	leave  
80106ce3:	c3                   	ret    

80106ce4 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80106ce4:	55                   	push   %ebp
80106ce5:	89 e5                	mov    %esp,%ebp
80106ce7:	83 ec 08             	sub    $0x8,%esp
  return fork();
80106cea:	e8 04 de ff ff       	call   80104af3 <fork>
}
80106cef:	c9                   	leave  
80106cf0:	c3                   	ret    

80106cf1 <sys_exit>:

int
sys_exit(void)
{
80106cf1:	55                   	push   %ebp
80106cf2:	89 e5                	mov    %esp,%ebp
80106cf4:	83 ec 08             	sub    $0x8,%esp
  exit();
80106cf7:	e8 5a df ff ff       	call   80104c56 <exit>
  return 0;  // not reached
80106cfc:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106d01:	c9                   	leave  
80106d02:	c3                   	ret    

80106d03 <sys_wait>:

int
sys_wait(void)
{
80106d03:	55                   	push   %ebp
80106d04:	89 e5                	mov    %esp,%ebp
80106d06:	83 ec 08             	sub    $0x8,%esp
  return wait();
80106d09:	e8 63 e0 ff ff       	call   80104d71 <wait>
}
80106d0e:	c9                   	leave  
80106d0f:	c3                   	ret    

80106d10 <sys_kill>:

int
sys_kill(void)
{
80106d10:	55                   	push   %ebp
80106d11:	89 e5                	mov    %esp,%ebp
80106d13:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
80106d16:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106d19:	89 44 24 04          	mov    %eax,0x4(%esp)
80106d1d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106d24:	e8 b9 ed ff ff       	call   80105ae2 <argint>
80106d29:	85 c0                	test   %eax,%eax
80106d2b:	79 07                	jns    80106d34 <sys_kill+0x24>
    return -1;
80106d2d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106d32:	eb 0b                	jmp    80106d3f <sys_kill+0x2f>
  return kill(pid);
80106d34:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d37:	89 04 24             	mov    %eax,(%esp)
80106d3a:	e8 f7 e4 ff ff       	call   80105236 <kill>
}
80106d3f:	c9                   	leave  
80106d40:	c3                   	ret    

80106d41 <sys_getpid>:

int
sys_getpid(void)
{
80106d41:	55                   	push   %ebp
80106d42:	89 e5                	mov    %esp,%ebp
  return proc->pid;
80106d44:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106d4a:	8b 40 10             	mov    0x10(%eax),%eax
}
80106d4d:	5d                   	pop    %ebp
80106d4e:	c3                   	ret    

80106d4f <sys_sbrk>:

int
sys_sbrk(void)
{
80106d4f:	55                   	push   %ebp
80106d50:	89 e5                	mov    %esp,%ebp
80106d52:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80106d55:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106d58:	89 44 24 04          	mov    %eax,0x4(%esp)
80106d5c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106d63:	e8 7a ed ff ff       	call   80105ae2 <argint>
80106d68:	85 c0                	test   %eax,%eax
80106d6a:	79 07                	jns    80106d73 <sys_sbrk+0x24>
    return -1;
80106d6c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106d71:	eb 24                	jmp    80106d97 <sys_sbrk+0x48>
  addr = proc->sz;
80106d73:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106d79:	8b 00                	mov    (%eax),%eax
80106d7b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
80106d7e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d81:	89 04 24             	mov    %eax,(%esp)
80106d84:	e8 c5 dc ff ff       	call   80104a4e <growproc>
80106d89:	85 c0                	test   %eax,%eax
80106d8b:	79 07                	jns    80106d94 <sys_sbrk+0x45>
    return -1;
80106d8d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106d92:	eb 03                	jmp    80106d97 <sys_sbrk+0x48>
  return addr;
80106d94:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80106d97:	c9                   	leave  
80106d98:	c3                   	ret    

80106d99 <sys_sleep>:

int
sys_sleep(void)
{
80106d99:	55                   	push   %ebp
80106d9a:	89 e5                	mov    %esp,%ebp
80106d9c:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
80106d9f:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106da2:	89 44 24 04          	mov    %eax,0x4(%esp)
80106da6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106dad:	e8 30 ed ff ff       	call   80105ae2 <argint>
80106db2:	85 c0                	test   %eax,%eax
80106db4:	79 07                	jns    80106dbd <sys_sleep+0x24>
    return -1;
80106db6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106dbb:	eb 6c                	jmp    80106e29 <sys_sleep+0x90>
  acquire(&tickslock);
80106dbd:	c7 04 24 c0 52 11 80 	movl   $0x801152c0,(%esp)
80106dc4:	e8 42 e7 ff ff       	call   8010550b <acquire>
  ticks0 = ticks;
80106dc9:	a1 00 5b 11 80       	mov    0x80115b00,%eax
80106dce:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
80106dd1:	eb 34                	jmp    80106e07 <sys_sleep+0x6e>
    if(proc->killed){
80106dd3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106dd9:	8b 40 24             	mov    0x24(%eax),%eax
80106ddc:	85 c0                	test   %eax,%eax
80106dde:	74 13                	je     80106df3 <sys_sleep+0x5a>
      release(&tickslock);
80106de0:	c7 04 24 c0 52 11 80 	movl   $0x801152c0,(%esp)
80106de7:	e8 ba e7 ff ff       	call   801055a6 <release>
      return -1;
80106dec:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106df1:	eb 36                	jmp    80106e29 <sys_sleep+0x90>
    }
    sleep(&ticks, &tickslock);
80106df3:	c7 44 24 04 c0 52 11 	movl   $0x801152c0,0x4(%esp)
80106dfa:	80 
80106dfb:	c7 04 24 00 5b 11 80 	movl   $0x80115b00,(%esp)
80106e02:	e8 c8 e2 ff ff       	call   801050cf <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
80106e07:	a1 00 5b 11 80       	mov    0x80115b00,%eax
80106e0c:	89 c2                	mov    %eax,%edx
80106e0e:	2b 55 f4             	sub    -0xc(%ebp),%edx
80106e11:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106e14:	39 c2                	cmp    %eax,%edx
80106e16:	72 bb                	jb     80106dd3 <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
80106e18:	c7 04 24 c0 52 11 80 	movl   $0x801152c0,(%esp)
80106e1f:	e8 82 e7 ff ff       	call   801055a6 <release>
  return 0;
80106e24:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106e29:	c9                   	leave  
80106e2a:	c3                   	ret    

80106e2b <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80106e2b:	55                   	push   %ebp
80106e2c:	89 e5                	mov    %esp,%ebp
80106e2e:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
80106e31:	c7 04 24 c0 52 11 80 	movl   $0x801152c0,(%esp)
80106e38:	e8 ce e6 ff ff       	call   8010550b <acquire>
  xticks = ticks;
80106e3d:	a1 00 5b 11 80       	mov    0x80115b00,%eax
80106e42:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
80106e45:	c7 04 24 c0 52 11 80 	movl   $0x801152c0,(%esp)
80106e4c:	e8 55 e7 ff ff       	call   801055a6 <release>
  return xticks;
80106e51:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80106e54:	c9                   	leave  
80106e55:	c3                   	ret    

80106e56 <sys_enableSwapping>:

void
sys_enableSwapping(void)
{
80106e56:	55                   	push   %ebp
80106e57:	89 e5                	mov    %esp,%ebp
  swapFlag = 1;
80106e59:	c7 05 08 c0 10 80 01 	movl   $0x1,0x8010c008
80106e60:	00 00 00 
}
80106e63:	5d                   	pop    %ebp
80106e64:	c3                   	ret    

80106e65 <sys_disableSwapping>:

void
sys_disableSwapping(void)
{
80106e65:	55                   	push   %ebp
80106e66:	89 e5                	mov    %esp,%ebp
  swapFlag = 0;
80106e68:	c7 05 08 c0 10 80 00 	movl   $0x0,0x8010c008
80106e6f:	00 00 00 
}
80106e72:	5d                   	pop    %ebp
80106e73:	c3                   	ret    

80106e74 <sys_sleep2>:

int
sys_sleep2(void)
{
80106e74:	55                   	push   %ebp
80106e75:	89 e5                	mov    %esp,%ebp
80106e77:	83 ec 18             	sub    $0x18,%esp
  acquire(&tickslock);
80106e7a:	c7 04 24 c0 52 11 80 	movl   $0x801152c0,(%esp)
80106e81:	e8 85 e6 ff ff       	call   8010550b <acquire>
  if(proc->killed){
80106e86:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106e8c:	8b 40 24             	mov    0x24(%eax),%eax
80106e8f:	85 c0                	test   %eax,%eax
80106e91:	74 13                	je     80106ea6 <sys_sleep2+0x32>
    release(&tickslock);
80106e93:	c7 04 24 c0 52 11 80 	movl   $0x801152c0,(%esp)
80106e9a:	e8 07 e7 ff ff       	call   801055a6 <release>
    return -1;
80106e9f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106ea4:	eb 25                	jmp    80106ecb <sys_sleep2+0x57>
  }
  sleep(&swapFlag, &tickslock);
80106ea6:	c7 44 24 04 c0 52 11 	movl   $0x801152c0,0x4(%esp)
80106ead:	80 
80106eae:	c7 04 24 08 c0 10 80 	movl   $0x8010c008,(%esp)
80106eb5:	e8 15 e2 ff ff       	call   801050cf <sleep>
  release(&tickslock);
80106eba:	c7 04 24 c0 52 11 80 	movl   $0x801152c0,(%esp)
80106ec1:	e8 e0 e6 ff ff       	call   801055a6 <release>
  return 0;
80106ec6:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106ecb:	c9                   	leave  
80106ecc:	c3                   	ret    

80106ecd <sys_wakeup2>:

int
sys_wakeup2(void)
{
80106ecd:	55                   	push   %ebp
80106ece:	89 e5                	mov    %esp,%ebp
80106ed0:	83 ec 18             	sub    $0x18,%esp
  wakeup(&swapFlag);
80106ed3:	c7 04 24 08 c0 10 80 	movl   $0x8010c008,(%esp)
80106eda:	e8 2c e3 ff ff       	call   8010520b <wakeup>
  return 0;
80106edf:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106ee4:	c9                   	leave  
80106ee5:	c3                   	ret    

80106ee6 <sys_getAllocatedPages>:

int
sys_getAllocatedPages(void)
{
80106ee6:	55                   	push   %ebp
80106ee7:	89 e5                	mov    %esp,%ebp
80106ee9:	83 ec 28             	sub    $0x28,%esp
  int pid;
  if(argint(0, &pid) < 0)
80106eec:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106eef:	89 44 24 04          	mov    %eax,0x4(%esp)
80106ef3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106efa:	e8 e3 eb ff ff       	call   80105ae2 <argint>
80106eff:	85 c0                	test   %eax,%eax
80106f01:	79 07                	jns    80106f0a <sys_getAllocatedPages+0x24>
    return -1;
80106f03:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106f08:	eb 0b                	jmp    80106f15 <sys_getAllocatedPages+0x2f>
  return getAllocatedPages(pid);
80106f0a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f0d:	89 04 24             	mov    %eax,(%esp)
80106f10:	e8 bb e4 ff ff       	call   801053d0 <getAllocatedPages>
}
80106f15:	c9                   	leave  
80106f16:	c3                   	ret    

80106f17 <sys_shmget>:

int 
sys_shmget(void)
{
80106f17:	55                   	push   %ebp
80106f18:	89 e5                	mov    %esp,%ebp
80106f1a:	83 ec 28             	sub    $0x28,%esp
  int key,size, shmflg;
  
  if(argint(0, &key) < 0)
80106f1d:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106f20:	89 44 24 04          	mov    %eax,0x4(%esp)
80106f24:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106f2b:	e8 b2 eb ff ff       	call   80105ae2 <argint>
80106f30:	85 c0                	test   %eax,%eax
80106f32:	79 07                	jns    80106f3b <sys_shmget+0x24>
    return -1;
80106f34:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106f39:	eb 65                	jmp    80106fa0 <sys_shmget+0x89>
  
  if(argint(0, &size) < 0)
80106f3b:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106f3e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106f42:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106f49:	e8 94 eb ff ff       	call   80105ae2 <argint>
80106f4e:	85 c0                	test   %eax,%eax
80106f50:	79 07                	jns    80106f59 <sys_shmget+0x42>
    return -1;
80106f52:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106f57:	eb 47                	jmp    80106fa0 <sys_shmget+0x89>
  if(size<0)
80106f59:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106f5c:	85 c0                	test   %eax,%eax
80106f5e:	79 07                	jns    80106f67 <sys_shmget+0x50>
    return -1;
80106f60:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106f65:	eb 39                	jmp    80106fa0 <sys_shmget+0x89>
  
  if(argint(0, &shmflg) < 0)
80106f67:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106f6a:	89 44 24 04          	mov    %eax,0x4(%esp)
80106f6e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106f75:	e8 68 eb ff ff       	call   80105ae2 <argint>
80106f7a:	85 c0                	test   %eax,%eax
80106f7c:	79 07                	jns    80106f85 <sys_shmget+0x6e>
    return -1;
80106f7e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106f83:	eb 1b                	jmp    80106fa0 <sys_shmget+0x89>
  
  return shmget(key, (uint)size,shmflg);
80106f85:	8b 4d ec             	mov    -0x14(%ebp),%ecx
80106f88:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106f8b:	89 c2                	mov    %eax,%edx
80106f8d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f90:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106f94:	89 54 24 04          	mov    %edx,0x4(%esp)
80106f98:	89 04 24             	mov    %eax,(%esp)
80106f9b:	e8 b0 bb ff ff       	call   80102b50 <shmget>
}
80106fa0:	c9                   	leave  
80106fa1:	c3                   	ret    

80106fa2 <sys_shmdel>:

int 
sys_shmdel(void)
{
80106fa2:	55                   	push   %ebp
80106fa3:	89 e5                	mov    %esp,%ebp
80106fa5:	83 ec 28             	sub    $0x28,%esp
  int shmid;
  if(argint(0, &shmid) < 0)
80106fa8:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106fab:	89 44 24 04          	mov    %eax,0x4(%esp)
80106faf:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106fb6:	e8 27 eb ff ff       	call   80105ae2 <argint>
80106fbb:	85 c0                	test   %eax,%eax
80106fbd:	79 07                	jns    80106fc6 <sys_shmdel+0x24>
    return -1;
80106fbf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106fc4:	eb 0b                	jmp    80106fd1 <sys_shmdel+0x2f>
  
  return shmdel(shmid);
80106fc6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106fc9:	89 04 24             	mov    %eax,(%esp)
80106fcc:	e8 d5 bc ff ff       	call   80102ca6 <shmdel>
}
80106fd1:	c9                   	leave  
80106fd2:	c3                   	ret    
	...

80106fd4 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80106fd4:	55                   	push   %ebp
80106fd5:	89 e5                	mov    %esp,%ebp
80106fd7:	83 ec 08             	sub    $0x8,%esp
80106fda:	8b 55 08             	mov    0x8(%ebp),%edx
80106fdd:	8b 45 0c             	mov    0xc(%ebp),%eax
80106fe0:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80106fe4:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80106fe7:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80106feb:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80106fef:	ee                   	out    %al,(%dx)
}
80106ff0:	c9                   	leave  
80106ff1:	c3                   	ret    

80106ff2 <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
80106ff2:	55                   	push   %ebp
80106ff3:	89 e5                	mov    %esp,%ebp
80106ff5:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
80106ff8:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
80106fff:	00 
80107000:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
80107007:	e8 c8 ff ff ff       	call   80106fd4 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
8010700c:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
80107013:	00 
80107014:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
8010701b:	e8 b4 ff ff ff       	call   80106fd4 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
80107020:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
80107027:	00 
80107028:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
8010702f:	e8 a0 ff ff ff       	call   80106fd4 <outb>
  picenable(IRQ_TIMER);
80107034:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010703b:	e8 cd cc ff ff       	call   80103d0d <picenable>
}
80107040:	c9                   	leave  
80107041:	c3                   	ret    
	...

80107044 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80107044:	1e                   	push   %ds
  pushl %es
80107045:	06                   	push   %es
  pushl %fs
80107046:	0f a0                	push   %fs
  pushl %gs
80107048:	0f a8                	push   %gs
  pushal
8010704a:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
8010704b:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
8010704f:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80107051:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
80107053:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
80107057:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
80107059:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
8010705b:	54                   	push   %esp
  call trap
8010705c:	e8 de 01 00 00       	call   8010723f <trap>
  addl $4, %esp
80107061:	83 c4 04             	add    $0x4,%esp

80107064 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80107064:	61                   	popa   
  popl %gs
80107065:	0f a9                	pop    %gs
  popl %fs
80107067:	0f a1                	pop    %fs
  popl %es
80107069:	07                   	pop    %es
  popl %ds
8010706a:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
8010706b:	83 c4 08             	add    $0x8,%esp
  iret
8010706e:	cf                   	iret   
	...

80107070 <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
80107070:	55                   	push   %ebp
80107071:	89 e5                	mov    %esp,%ebp
80107073:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80107076:	8b 45 0c             	mov    0xc(%ebp),%eax
80107079:	83 e8 01             	sub    $0x1,%eax
8010707c:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80107080:	8b 45 08             	mov    0x8(%ebp),%eax
80107083:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80107087:	8b 45 08             	mov    0x8(%ebp),%eax
8010708a:	c1 e8 10             	shr    $0x10,%eax
8010708d:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
80107091:	8d 45 fa             	lea    -0x6(%ebp),%eax
80107094:	0f 01 18             	lidtl  (%eax)
}
80107097:	c9                   	leave  
80107098:	c3                   	ret    

80107099 <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
80107099:	55                   	push   %ebp
8010709a:	89 e5                	mov    %esp,%ebp
8010709c:	53                   	push   %ebx
8010709d:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
801070a0:	0f 20 d3             	mov    %cr2,%ebx
801070a3:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return val;
801070a6:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
801070a9:	83 c4 10             	add    $0x10,%esp
801070ac:	5b                   	pop    %ebx
801070ad:	5d                   	pop    %ebp
801070ae:	c3                   	ret    

801070af <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
801070af:	55                   	push   %ebp
801070b0:	89 e5                	mov    %esp,%ebp
801070b2:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
801070b5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801070bc:	e9 c3 00 00 00       	jmp    80107184 <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
801070c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801070c4:	8b 04 85 b4 c0 10 80 	mov    -0x7fef3f4c(,%eax,4),%eax
801070cb:	89 c2                	mov    %eax,%edx
801070cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801070d0:	66 89 14 c5 00 53 11 	mov    %dx,-0x7feead00(,%eax,8)
801070d7:	80 
801070d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801070db:	66 c7 04 c5 02 53 11 	movw   $0x8,-0x7feeacfe(,%eax,8)
801070e2:	80 08 00 
801070e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801070e8:	0f b6 14 c5 04 53 11 	movzbl -0x7feeacfc(,%eax,8),%edx
801070ef:	80 
801070f0:	83 e2 e0             	and    $0xffffffe0,%edx
801070f3:	88 14 c5 04 53 11 80 	mov    %dl,-0x7feeacfc(,%eax,8)
801070fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801070fd:	0f b6 14 c5 04 53 11 	movzbl -0x7feeacfc(,%eax,8),%edx
80107104:	80 
80107105:	83 e2 1f             	and    $0x1f,%edx
80107108:	88 14 c5 04 53 11 80 	mov    %dl,-0x7feeacfc(,%eax,8)
8010710f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107112:	0f b6 14 c5 05 53 11 	movzbl -0x7feeacfb(,%eax,8),%edx
80107119:	80 
8010711a:	83 e2 f0             	and    $0xfffffff0,%edx
8010711d:	83 ca 0e             	or     $0xe,%edx
80107120:	88 14 c5 05 53 11 80 	mov    %dl,-0x7feeacfb(,%eax,8)
80107127:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010712a:	0f b6 14 c5 05 53 11 	movzbl -0x7feeacfb(,%eax,8),%edx
80107131:	80 
80107132:	83 e2 ef             	and    $0xffffffef,%edx
80107135:	88 14 c5 05 53 11 80 	mov    %dl,-0x7feeacfb(,%eax,8)
8010713c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010713f:	0f b6 14 c5 05 53 11 	movzbl -0x7feeacfb(,%eax,8),%edx
80107146:	80 
80107147:	83 e2 9f             	and    $0xffffff9f,%edx
8010714a:	88 14 c5 05 53 11 80 	mov    %dl,-0x7feeacfb(,%eax,8)
80107151:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107154:	0f b6 14 c5 05 53 11 	movzbl -0x7feeacfb(,%eax,8),%edx
8010715b:	80 
8010715c:	83 ca 80             	or     $0xffffff80,%edx
8010715f:	88 14 c5 05 53 11 80 	mov    %dl,-0x7feeacfb(,%eax,8)
80107166:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107169:	8b 04 85 b4 c0 10 80 	mov    -0x7fef3f4c(,%eax,4),%eax
80107170:	c1 e8 10             	shr    $0x10,%eax
80107173:	89 c2                	mov    %eax,%edx
80107175:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107178:	66 89 14 c5 06 53 11 	mov    %dx,-0x7feeacfa(,%eax,8)
8010717f:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
80107180:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107184:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
8010718b:	0f 8e 30 ff ff ff    	jle    801070c1 <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80107191:	a1 b4 c1 10 80       	mov    0x8010c1b4,%eax
80107196:	66 a3 00 55 11 80    	mov    %ax,0x80115500
8010719c:	66 c7 05 02 55 11 80 	movw   $0x8,0x80115502
801071a3:	08 00 
801071a5:	0f b6 05 04 55 11 80 	movzbl 0x80115504,%eax
801071ac:	83 e0 e0             	and    $0xffffffe0,%eax
801071af:	a2 04 55 11 80       	mov    %al,0x80115504
801071b4:	0f b6 05 04 55 11 80 	movzbl 0x80115504,%eax
801071bb:	83 e0 1f             	and    $0x1f,%eax
801071be:	a2 04 55 11 80       	mov    %al,0x80115504
801071c3:	0f b6 05 05 55 11 80 	movzbl 0x80115505,%eax
801071ca:	83 c8 0f             	or     $0xf,%eax
801071cd:	a2 05 55 11 80       	mov    %al,0x80115505
801071d2:	0f b6 05 05 55 11 80 	movzbl 0x80115505,%eax
801071d9:	83 e0 ef             	and    $0xffffffef,%eax
801071dc:	a2 05 55 11 80       	mov    %al,0x80115505
801071e1:	0f b6 05 05 55 11 80 	movzbl 0x80115505,%eax
801071e8:	83 c8 60             	or     $0x60,%eax
801071eb:	a2 05 55 11 80       	mov    %al,0x80115505
801071f0:	0f b6 05 05 55 11 80 	movzbl 0x80115505,%eax
801071f7:	83 c8 80             	or     $0xffffff80,%eax
801071fa:	a2 05 55 11 80       	mov    %al,0x80115505
801071ff:	a1 b4 c1 10 80       	mov    0x8010c1b4,%eax
80107204:	c1 e8 10             	shr    $0x10,%eax
80107207:	66 a3 06 55 11 80    	mov    %ax,0x80115506
  
  initlock(&tickslock, "time");
8010720d:	c7 44 24 04 b8 94 10 	movl   $0x801094b8,0x4(%esp)
80107214:	80 
80107215:	c7 04 24 c0 52 11 80 	movl   $0x801152c0,(%esp)
8010721c:	e8 c9 e2 ff ff       	call   801054ea <initlock>
}
80107221:	c9                   	leave  
80107222:	c3                   	ret    

80107223 <idtinit>:

void
idtinit(void)
{
80107223:	55                   	push   %ebp
80107224:	89 e5                	mov    %esp,%ebp
80107226:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
80107229:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
80107230:	00 
80107231:	c7 04 24 00 53 11 80 	movl   $0x80115300,(%esp)
80107238:	e8 33 fe ff ff       	call   80107070 <lidt>
}
8010723d:	c9                   	leave  
8010723e:	c3                   	ret    

8010723f <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
8010723f:	55                   	push   %ebp
80107240:	89 e5                	mov    %esp,%ebp
80107242:	57                   	push   %edi
80107243:	56                   	push   %esi
80107244:	53                   	push   %ebx
80107245:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
80107248:	8b 45 08             	mov    0x8(%ebp),%eax
8010724b:	8b 40 30             	mov    0x30(%eax),%eax
8010724e:	83 f8 40             	cmp    $0x40,%eax
80107251:	75 3e                	jne    80107291 <trap+0x52>
    if(proc->killed)
80107253:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107259:	8b 40 24             	mov    0x24(%eax),%eax
8010725c:	85 c0                	test   %eax,%eax
8010725e:	74 05                	je     80107265 <trap+0x26>
      exit();
80107260:	e8 f1 d9 ff ff       	call   80104c56 <exit>
    proc->tf = tf;
80107265:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010726b:	8b 55 08             	mov    0x8(%ebp),%edx
8010726e:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
80107271:	e8 49 e9 ff ff       	call   80105bbf <syscall>
    if(proc->killed)
80107276:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010727c:	8b 40 24             	mov    0x24(%eax),%eax
8010727f:	85 c0                	test   %eax,%eax
80107281:	0f 84 34 02 00 00    	je     801074bb <trap+0x27c>
      exit();
80107287:	e8 ca d9 ff ff       	call   80104c56 <exit>
    return;
8010728c:	e9 2a 02 00 00       	jmp    801074bb <trap+0x27c>
  }

  switch(tf->trapno){
80107291:	8b 45 08             	mov    0x8(%ebp),%eax
80107294:	8b 40 30             	mov    0x30(%eax),%eax
80107297:	83 e8 20             	sub    $0x20,%eax
8010729a:	83 f8 1f             	cmp    $0x1f,%eax
8010729d:	0f 87 bc 00 00 00    	ja     8010735f <trap+0x120>
801072a3:	8b 04 85 60 95 10 80 	mov    -0x7fef6aa0(,%eax,4),%eax
801072aa:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
801072ac:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801072b2:	0f b6 00             	movzbl (%eax),%eax
801072b5:	84 c0                	test   %al,%al
801072b7:	75 31                	jne    801072ea <trap+0xab>
      acquire(&tickslock);
801072b9:	c7 04 24 c0 52 11 80 	movl   $0x801152c0,(%esp)
801072c0:	e8 46 e2 ff ff       	call   8010550b <acquire>
      ticks++;
801072c5:	a1 00 5b 11 80       	mov    0x80115b00,%eax
801072ca:	83 c0 01             	add    $0x1,%eax
801072cd:	a3 00 5b 11 80       	mov    %eax,0x80115b00
      wakeup(&ticks);
801072d2:	c7 04 24 00 5b 11 80 	movl   $0x80115b00,(%esp)
801072d9:	e8 2d df ff ff       	call   8010520b <wakeup>
      release(&tickslock);
801072de:	c7 04 24 c0 52 11 80 	movl   $0x801152c0,(%esp)
801072e5:	e8 bc e2 ff ff       	call   801055a6 <release>
    }
    lapiceoi();
801072ea:	e8 46 be ff ff       	call   80103135 <lapiceoi>
    break;
801072ef:	e9 41 01 00 00       	jmp    80107435 <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
801072f4:	e8 fe b3 ff ff       	call   801026f7 <ideintr>
    lapiceoi();
801072f9:	e8 37 be ff ff       	call   80103135 <lapiceoi>
    break;
801072fe:	e9 32 01 00 00       	jmp    80107435 <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
80107303:	e8 0b bc ff ff       	call   80102f13 <kbdintr>
    lapiceoi();
80107308:	e8 28 be ff ff       	call   80103135 <lapiceoi>
    break;
8010730d:	e9 23 01 00 00       	jmp    80107435 <trap+0x1f6>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
80107312:	e8 a9 03 00 00       	call   801076c0 <uartintr>
    lapiceoi();
80107317:	e8 19 be ff ff       	call   80103135 <lapiceoi>
    break;
8010731c:	e9 14 01 00 00       	jmp    80107435 <trap+0x1f6>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
            cpu->id, tf->cs, tf->eip);
80107321:	8b 45 08             	mov    0x8(%ebp),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80107324:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
80107327:	8b 45 08             	mov    0x8(%ebp),%eax
8010732a:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
8010732e:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
80107331:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107337:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
8010733a:	0f b6 c0             	movzbl %al,%eax
8010733d:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80107341:	89 54 24 08          	mov    %edx,0x8(%esp)
80107345:	89 44 24 04          	mov    %eax,0x4(%esp)
80107349:	c7 04 24 c0 94 10 80 	movl   $0x801094c0,(%esp)
80107350:	e8 4c 90 ff ff       	call   801003a1 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
80107355:	e8 db bd ff ff       	call   80103135 <lapiceoi>
    break;
8010735a:	e9 d6 00 00 00       	jmp    80107435 <trap+0x1f6>
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
8010735f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107365:	85 c0                	test   %eax,%eax
80107367:	74 11                	je     8010737a <trap+0x13b>
80107369:	8b 45 08             	mov    0x8(%ebp),%eax
8010736c:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80107370:	0f b7 c0             	movzwl %ax,%eax
80107373:	83 e0 03             	and    $0x3,%eax
80107376:	85 c0                	test   %eax,%eax
80107378:	75 46                	jne    801073c0 <trap+0x181>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
8010737a:	e8 1a fd ff ff       	call   80107099 <rcr2>
              tf->trapno, cpu->id, tf->eip, rcr2());
8010737f:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80107382:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
80107385:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
8010738c:	0f b6 12             	movzbl (%edx),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
8010738f:	0f b6 ca             	movzbl %dl,%ecx
              tf->trapno, cpu->id, tf->eip, rcr2());
80107392:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80107395:	8b 52 30             	mov    0x30(%edx),%edx
80107398:	89 44 24 10          	mov    %eax,0x10(%esp)
8010739c:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
801073a0:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801073a4:	89 54 24 04          	mov    %edx,0x4(%esp)
801073a8:	c7 04 24 e4 94 10 80 	movl   $0x801094e4,(%esp)
801073af:	e8 ed 8f ff ff       	call   801003a1 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
801073b4:	c7 04 24 16 95 10 80 	movl   $0x80109516,(%esp)
801073bb:	e8 7d 91 ff ff       	call   8010053d <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801073c0:	e8 d4 fc ff ff       	call   80107099 <rcr2>
801073c5:	89 c2                	mov    %eax,%edx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801073c7:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801073ca:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801073cd:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801073d3:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801073d6:	0f b6 f0             	movzbl %al,%esi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801073d9:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801073dc:	8b 58 34             	mov    0x34(%eax),%ebx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801073df:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801073e2:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801073e5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801073eb:	83 c0 6c             	add    $0x6c,%eax
801073ee:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801073f1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801073f7:	8b 40 10             	mov    0x10(%eax),%eax
801073fa:	89 54 24 1c          	mov    %edx,0x1c(%esp)
801073fe:	89 7c 24 18          	mov    %edi,0x18(%esp)
80107402:	89 74 24 14          	mov    %esi,0x14(%esp)
80107406:	89 5c 24 10          	mov    %ebx,0x10(%esp)
8010740a:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
8010740e:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80107411:	89 54 24 08          	mov    %edx,0x8(%esp)
80107415:	89 44 24 04          	mov    %eax,0x4(%esp)
80107419:	c7 04 24 1c 95 10 80 	movl   $0x8010951c,(%esp)
80107420:	e8 7c 8f ff ff       	call   801003a1 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
80107425:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010742b:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
80107432:	eb 01                	jmp    80107435 <trap+0x1f6>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
80107434:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80107435:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010743b:	85 c0                	test   %eax,%eax
8010743d:	74 24                	je     80107463 <trap+0x224>
8010743f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107445:	8b 40 24             	mov    0x24(%eax),%eax
80107448:	85 c0                	test   %eax,%eax
8010744a:	74 17                	je     80107463 <trap+0x224>
8010744c:	8b 45 08             	mov    0x8(%ebp),%eax
8010744f:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80107453:	0f b7 c0             	movzwl %ax,%eax
80107456:	83 e0 03             	and    $0x3,%eax
80107459:	83 f8 03             	cmp    $0x3,%eax
8010745c:	75 05                	jne    80107463 <trap+0x224>
    exit();
8010745e:	e8 f3 d7 ff ff       	call   80104c56 <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
80107463:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107469:	85 c0                	test   %eax,%eax
8010746b:	74 1e                	je     8010748b <trap+0x24c>
8010746d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107473:	8b 40 0c             	mov    0xc(%eax),%eax
80107476:	83 f8 04             	cmp    $0x4,%eax
80107479:	75 10                	jne    8010748b <trap+0x24c>
8010747b:	8b 45 08             	mov    0x8(%ebp),%eax
8010747e:	8b 40 30             	mov    0x30(%eax),%eax
80107481:	83 f8 20             	cmp    $0x20,%eax
80107484:	75 05                	jne    8010748b <trap+0x24c>
    yield();
80107486:	e8 e6 db ff ff       	call   80105071 <yield>

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
8010748b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107491:	85 c0                	test   %eax,%eax
80107493:	74 27                	je     801074bc <trap+0x27d>
80107495:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010749b:	8b 40 24             	mov    0x24(%eax),%eax
8010749e:	85 c0                	test   %eax,%eax
801074a0:	74 1a                	je     801074bc <trap+0x27d>
801074a2:	8b 45 08             	mov    0x8(%ebp),%eax
801074a5:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
801074a9:	0f b7 c0             	movzwl %ax,%eax
801074ac:	83 e0 03             	and    $0x3,%eax
801074af:	83 f8 03             	cmp    $0x3,%eax
801074b2:	75 08                	jne    801074bc <trap+0x27d>
    exit();
801074b4:	e8 9d d7 ff ff       	call   80104c56 <exit>
801074b9:	eb 01                	jmp    801074bc <trap+0x27d>
      exit();
    proc->tf = tf;
    syscall();
    if(proc->killed)
      exit();
    return;
801074bb:	90                   	nop
    yield();

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
    exit();
}
801074bc:	83 c4 3c             	add    $0x3c,%esp
801074bf:	5b                   	pop    %ebx
801074c0:	5e                   	pop    %esi
801074c1:	5f                   	pop    %edi
801074c2:	5d                   	pop    %ebp
801074c3:	c3                   	ret    

801074c4 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801074c4:	55                   	push   %ebp
801074c5:	89 e5                	mov    %esp,%ebp
801074c7:	53                   	push   %ebx
801074c8:	83 ec 14             	sub    $0x14,%esp
801074cb:	8b 45 08             	mov    0x8(%ebp),%eax
801074ce:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801074d2:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
801074d6:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
801074da:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
801074de:	ec                   	in     (%dx),%al
801074df:	89 c3                	mov    %eax,%ebx
801074e1:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
801074e4:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
801074e8:	83 c4 14             	add    $0x14,%esp
801074eb:	5b                   	pop    %ebx
801074ec:	5d                   	pop    %ebp
801074ed:	c3                   	ret    

801074ee <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801074ee:	55                   	push   %ebp
801074ef:	89 e5                	mov    %esp,%ebp
801074f1:	83 ec 08             	sub    $0x8,%esp
801074f4:	8b 55 08             	mov    0x8(%ebp),%edx
801074f7:	8b 45 0c             	mov    0xc(%ebp),%eax
801074fa:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801074fe:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80107501:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80107505:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80107509:	ee                   	out    %al,(%dx)
}
8010750a:	c9                   	leave  
8010750b:	c3                   	ret    

8010750c <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
8010750c:	55                   	push   %ebp
8010750d:	89 e5                	mov    %esp,%ebp
8010750f:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
80107512:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107519:	00 
8010751a:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80107521:	e8 c8 ff ff ff       	call   801074ee <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
80107526:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
8010752d:	00 
8010752e:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80107535:	e8 b4 ff ff ff       	call   801074ee <outb>
  outb(COM1+0, 115200/9600);
8010753a:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
80107541:	00 
80107542:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107549:	e8 a0 ff ff ff       	call   801074ee <outb>
  outb(COM1+1, 0);
8010754e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107555:	00 
80107556:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
8010755d:	e8 8c ff ff ff       	call   801074ee <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
80107562:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80107569:	00 
8010756a:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80107571:	e8 78 ff ff ff       	call   801074ee <outb>
  outb(COM1+4, 0);
80107576:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010757d:	00 
8010757e:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
80107585:	e8 64 ff ff ff       	call   801074ee <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
8010758a:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80107591:	00 
80107592:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80107599:	e8 50 ff ff ff       	call   801074ee <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
8010759e:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
801075a5:	e8 1a ff ff ff       	call   801074c4 <inb>
801075aa:	3c ff                	cmp    $0xff,%al
801075ac:	74 6c                	je     8010761a <uartinit+0x10e>
    return;
  uart = 1;
801075ae:	c7 05 70 c6 10 80 01 	movl   $0x1,0x8010c670
801075b5:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
801075b8:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
801075bf:	e8 00 ff ff ff       	call   801074c4 <inb>
  inb(COM1+0);
801075c4:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
801075cb:	e8 f4 fe ff ff       	call   801074c4 <inb>
  picenable(IRQ_COM1);
801075d0:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
801075d7:	e8 31 c7 ff ff       	call   80103d0d <picenable>
  ioapicenable(IRQ_COM1, 0);
801075dc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801075e3:	00 
801075e4:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
801075eb:	e8 8a b3 ff ff       	call   8010297a <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
801075f0:	c7 45 f4 e0 95 10 80 	movl   $0x801095e0,-0xc(%ebp)
801075f7:	eb 15                	jmp    8010760e <uartinit+0x102>
    uartputc(*p);
801075f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075fc:	0f b6 00             	movzbl (%eax),%eax
801075ff:	0f be c0             	movsbl %al,%eax
80107602:	89 04 24             	mov    %eax,(%esp)
80107605:	e8 13 00 00 00       	call   8010761d <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
8010760a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010760e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107611:	0f b6 00             	movzbl (%eax),%eax
80107614:	84 c0                	test   %al,%al
80107616:	75 e1                	jne    801075f9 <uartinit+0xed>
80107618:	eb 01                	jmp    8010761b <uartinit+0x10f>
  outb(COM1+4, 0);
  outb(COM1+1, 0x01);    // Enable receive interrupts.

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
    return;
8010761a:	90                   	nop
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
    uartputc(*p);
}
8010761b:	c9                   	leave  
8010761c:	c3                   	ret    

8010761d <uartputc>:

void
uartputc(int c)
{
8010761d:	55                   	push   %ebp
8010761e:	89 e5                	mov    %esp,%ebp
80107620:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
80107623:	a1 70 c6 10 80       	mov    0x8010c670,%eax
80107628:	85 c0                	test   %eax,%eax
8010762a:	74 4d                	je     80107679 <uartputc+0x5c>
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
8010762c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80107633:	eb 10                	jmp    80107645 <uartputc+0x28>
    microdelay(10);
80107635:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
8010763c:	e8 19 bb ff ff       	call   8010315a <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80107641:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107645:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
80107649:	7f 16                	jg     80107661 <uartputc+0x44>
8010764b:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80107652:	e8 6d fe ff ff       	call   801074c4 <inb>
80107657:	0f b6 c0             	movzbl %al,%eax
8010765a:	83 e0 20             	and    $0x20,%eax
8010765d:	85 c0                	test   %eax,%eax
8010765f:	74 d4                	je     80107635 <uartputc+0x18>
    microdelay(10);
  outb(COM1+0, c);
80107661:	8b 45 08             	mov    0x8(%ebp),%eax
80107664:	0f b6 c0             	movzbl %al,%eax
80107667:	89 44 24 04          	mov    %eax,0x4(%esp)
8010766b:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107672:	e8 77 fe ff ff       	call   801074ee <outb>
80107677:	eb 01                	jmp    8010767a <uartputc+0x5d>
uartputc(int c)
{
  int i;

  if(!uart)
    return;
80107679:	90                   	nop
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
    microdelay(10);
  outb(COM1+0, c);
}
8010767a:	c9                   	leave  
8010767b:	c3                   	ret    

8010767c <uartgetc>:

static int
uartgetc(void)
{
8010767c:	55                   	push   %ebp
8010767d:	89 e5                	mov    %esp,%ebp
8010767f:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
80107682:	a1 70 c6 10 80       	mov    0x8010c670,%eax
80107687:	85 c0                	test   %eax,%eax
80107689:	75 07                	jne    80107692 <uartgetc+0x16>
    return -1;
8010768b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107690:	eb 2c                	jmp    801076be <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
80107692:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80107699:	e8 26 fe ff ff       	call   801074c4 <inb>
8010769e:	0f b6 c0             	movzbl %al,%eax
801076a1:	83 e0 01             	and    $0x1,%eax
801076a4:	85 c0                	test   %eax,%eax
801076a6:	75 07                	jne    801076af <uartgetc+0x33>
    return -1;
801076a8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801076ad:	eb 0f                	jmp    801076be <uartgetc+0x42>
  return inb(COM1+0);
801076af:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
801076b6:	e8 09 fe ff ff       	call   801074c4 <inb>
801076bb:	0f b6 c0             	movzbl %al,%eax
}
801076be:	c9                   	leave  
801076bf:	c3                   	ret    

801076c0 <uartintr>:

void
uartintr(void)
{
801076c0:	55                   	push   %ebp
801076c1:	89 e5                	mov    %esp,%ebp
801076c3:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
801076c6:	c7 04 24 7c 76 10 80 	movl   $0x8010767c,(%esp)
801076cd:	e8 db 90 ff ff       	call   801007ad <consoleintr>
}
801076d2:	c9                   	leave  
801076d3:	c3                   	ret    

801076d4 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
801076d4:	6a 00                	push   $0x0
  pushl $0
801076d6:	6a 00                	push   $0x0
  jmp alltraps
801076d8:	e9 67 f9 ff ff       	jmp    80107044 <alltraps>

801076dd <vector1>:
.globl vector1
vector1:
  pushl $0
801076dd:	6a 00                	push   $0x0
  pushl $1
801076df:	6a 01                	push   $0x1
  jmp alltraps
801076e1:	e9 5e f9 ff ff       	jmp    80107044 <alltraps>

801076e6 <vector2>:
.globl vector2
vector2:
  pushl $0
801076e6:	6a 00                	push   $0x0
  pushl $2
801076e8:	6a 02                	push   $0x2
  jmp alltraps
801076ea:	e9 55 f9 ff ff       	jmp    80107044 <alltraps>

801076ef <vector3>:
.globl vector3
vector3:
  pushl $0
801076ef:	6a 00                	push   $0x0
  pushl $3
801076f1:	6a 03                	push   $0x3
  jmp alltraps
801076f3:	e9 4c f9 ff ff       	jmp    80107044 <alltraps>

801076f8 <vector4>:
.globl vector4
vector4:
  pushl $0
801076f8:	6a 00                	push   $0x0
  pushl $4
801076fa:	6a 04                	push   $0x4
  jmp alltraps
801076fc:	e9 43 f9 ff ff       	jmp    80107044 <alltraps>

80107701 <vector5>:
.globl vector5
vector5:
  pushl $0
80107701:	6a 00                	push   $0x0
  pushl $5
80107703:	6a 05                	push   $0x5
  jmp alltraps
80107705:	e9 3a f9 ff ff       	jmp    80107044 <alltraps>

8010770a <vector6>:
.globl vector6
vector6:
  pushl $0
8010770a:	6a 00                	push   $0x0
  pushl $6
8010770c:	6a 06                	push   $0x6
  jmp alltraps
8010770e:	e9 31 f9 ff ff       	jmp    80107044 <alltraps>

80107713 <vector7>:
.globl vector7
vector7:
  pushl $0
80107713:	6a 00                	push   $0x0
  pushl $7
80107715:	6a 07                	push   $0x7
  jmp alltraps
80107717:	e9 28 f9 ff ff       	jmp    80107044 <alltraps>

8010771c <vector8>:
.globl vector8
vector8:
  pushl $8
8010771c:	6a 08                	push   $0x8
  jmp alltraps
8010771e:	e9 21 f9 ff ff       	jmp    80107044 <alltraps>

80107723 <vector9>:
.globl vector9
vector9:
  pushl $0
80107723:	6a 00                	push   $0x0
  pushl $9
80107725:	6a 09                	push   $0x9
  jmp alltraps
80107727:	e9 18 f9 ff ff       	jmp    80107044 <alltraps>

8010772c <vector10>:
.globl vector10
vector10:
  pushl $10
8010772c:	6a 0a                	push   $0xa
  jmp alltraps
8010772e:	e9 11 f9 ff ff       	jmp    80107044 <alltraps>

80107733 <vector11>:
.globl vector11
vector11:
  pushl $11
80107733:	6a 0b                	push   $0xb
  jmp alltraps
80107735:	e9 0a f9 ff ff       	jmp    80107044 <alltraps>

8010773a <vector12>:
.globl vector12
vector12:
  pushl $12
8010773a:	6a 0c                	push   $0xc
  jmp alltraps
8010773c:	e9 03 f9 ff ff       	jmp    80107044 <alltraps>

80107741 <vector13>:
.globl vector13
vector13:
  pushl $13
80107741:	6a 0d                	push   $0xd
  jmp alltraps
80107743:	e9 fc f8 ff ff       	jmp    80107044 <alltraps>

80107748 <vector14>:
.globl vector14
vector14:
  pushl $14
80107748:	6a 0e                	push   $0xe
  jmp alltraps
8010774a:	e9 f5 f8 ff ff       	jmp    80107044 <alltraps>

8010774f <vector15>:
.globl vector15
vector15:
  pushl $0
8010774f:	6a 00                	push   $0x0
  pushl $15
80107751:	6a 0f                	push   $0xf
  jmp alltraps
80107753:	e9 ec f8 ff ff       	jmp    80107044 <alltraps>

80107758 <vector16>:
.globl vector16
vector16:
  pushl $0
80107758:	6a 00                	push   $0x0
  pushl $16
8010775a:	6a 10                	push   $0x10
  jmp alltraps
8010775c:	e9 e3 f8 ff ff       	jmp    80107044 <alltraps>

80107761 <vector17>:
.globl vector17
vector17:
  pushl $17
80107761:	6a 11                	push   $0x11
  jmp alltraps
80107763:	e9 dc f8 ff ff       	jmp    80107044 <alltraps>

80107768 <vector18>:
.globl vector18
vector18:
  pushl $0
80107768:	6a 00                	push   $0x0
  pushl $18
8010776a:	6a 12                	push   $0x12
  jmp alltraps
8010776c:	e9 d3 f8 ff ff       	jmp    80107044 <alltraps>

80107771 <vector19>:
.globl vector19
vector19:
  pushl $0
80107771:	6a 00                	push   $0x0
  pushl $19
80107773:	6a 13                	push   $0x13
  jmp alltraps
80107775:	e9 ca f8 ff ff       	jmp    80107044 <alltraps>

8010777a <vector20>:
.globl vector20
vector20:
  pushl $0
8010777a:	6a 00                	push   $0x0
  pushl $20
8010777c:	6a 14                	push   $0x14
  jmp alltraps
8010777e:	e9 c1 f8 ff ff       	jmp    80107044 <alltraps>

80107783 <vector21>:
.globl vector21
vector21:
  pushl $0
80107783:	6a 00                	push   $0x0
  pushl $21
80107785:	6a 15                	push   $0x15
  jmp alltraps
80107787:	e9 b8 f8 ff ff       	jmp    80107044 <alltraps>

8010778c <vector22>:
.globl vector22
vector22:
  pushl $0
8010778c:	6a 00                	push   $0x0
  pushl $22
8010778e:	6a 16                	push   $0x16
  jmp alltraps
80107790:	e9 af f8 ff ff       	jmp    80107044 <alltraps>

80107795 <vector23>:
.globl vector23
vector23:
  pushl $0
80107795:	6a 00                	push   $0x0
  pushl $23
80107797:	6a 17                	push   $0x17
  jmp alltraps
80107799:	e9 a6 f8 ff ff       	jmp    80107044 <alltraps>

8010779e <vector24>:
.globl vector24
vector24:
  pushl $0
8010779e:	6a 00                	push   $0x0
  pushl $24
801077a0:	6a 18                	push   $0x18
  jmp alltraps
801077a2:	e9 9d f8 ff ff       	jmp    80107044 <alltraps>

801077a7 <vector25>:
.globl vector25
vector25:
  pushl $0
801077a7:	6a 00                	push   $0x0
  pushl $25
801077a9:	6a 19                	push   $0x19
  jmp alltraps
801077ab:	e9 94 f8 ff ff       	jmp    80107044 <alltraps>

801077b0 <vector26>:
.globl vector26
vector26:
  pushl $0
801077b0:	6a 00                	push   $0x0
  pushl $26
801077b2:	6a 1a                	push   $0x1a
  jmp alltraps
801077b4:	e9 8b f8 ff ff       	jmp    80107044 <alltraps>

801077b9 <vector27>:
.globl vector27
vector27:
  pushl $0
801077b9:	6a 00                	push   $0x0
  pushl $27
801077bb:	6a 1b                	push   $0x1b
  jmp alltraps
801077bd:	e9 82 f8 ff ff       	jmp    80107044 <alltraps>

801077c2 <vector28>:
.globl vector28
vector28:
  pushl $0
801077c2:	6a 00                	push   $0x0
  pushl $28
801077c4:	6a 1c                	push   $0x1c
  jmp alltraps
801077c6:	e9 79 f8 ff ff       	jmp    80107044 <alltraps>

801077cb <vector29>:
.globl vector29
vector29:
  pushl $0
801077cb:	6a 00                	push   $0x0
  pushl $29
801077cd:	6a 1d                	push   $0x1d
  jmp alltraps
801077cf:	e9 70 f8 ff ff       	jmp    80107044 <alltraps>

801077d4 <vector30>:
.globl vector30
vector30:
  pushl $0
801077d4:	6a 00                	push   $0x0
  pushl $30
801077d6:	6a 1e                	push   $0x1e
  jmp alltraps
801077d8:	e9 67 f8 ff ff       	jmp    80107044 <alltraps>

801077dd <vector31>:
.globl vector31
vector31:
  pushl $0
801077dd:	6a 00                	push   $0x0
  pushl $31
801077df:	6a 1f                	push   $0x1f
  jmp alltraps
801077e1:	e9 5e f8 ff ff       	jmp    80107044 <alltraps>

801077e6 <vector32>:
.globl vector32
vector32:
  pushl $0
801077e6:	6a 00                	push   $0x0
  pushl $32
801077e8:	6a 20                	push   $0x20
  jmp alltraps
801077ea:	e9 55 f8 ff ff       	jmp    80107044 <alltraps>

801077ef <vector33>:
.globl vector33
vector33:
  pushl $0
801077ef:	6a 00                	push   $0x0
  pushl $33
801077f1:	6a 21                	push   $0x21
  jmp alltraps
801077f3:	e9 4c f8 ff ff       	jmp    80107044 <alltraps>

801077f8 <vector34>:
.globl vector34
vector34:
  pushl $0
801077f8:	6a 00                	push   $0x0
  pushl $34
801077fa:	6a 22                	push   $0x22
  jmp alltraps
801077fc:	e9 43 f8 ff ff       	jmp    80107044 <alltraps>

80107801 <vector35>:
.globl vector35
vector35:
  pushl $0
80107801:	6a 00                	push   $0x0
  pushl $35
80107803:	6a 23                	push   $0x23
  jmp alltraps
80107805:	e9 3a f8 ff ff       	jmp    80107044 <alltraps>

8010780a <vector36>:
.globl vector36
vector36:
  pushl $0
8010780a:	6a 00                	push   $0x0
  pushl $36
8010780c:	6a 24                	push   $0x24
  jmp alltraps
8010780e:	e9 31 f8 ff ff       	jmp    80107044 <alltraps>

80107813 <vector37>:
.globl vector37
vector37:
  pushl $0
80107813:	6a 00                	push   $0x0
  pushl $37
80107815:	6a 25                	push   $0x25
  jmp alltraps
80107817:	e9 28 f8 ff ff       	jmp    80107044 <alltraps>

8010781c <vector38>:
.globl vector38
vector38:
  pushl $0
8010781c:	6a 00                	push   $0x0
  pushl $38
8010781e:	6a 26                	push   $0x26
  jmp alltraps
80107820:	e9 1f f8 ff ff       	jmp    80107044 <alltraps>

80107825 <vector39>:
.globl vector39
vector39:
  pushl $0
80107825:	6a 00                	push   $0x0
  pushl $39
80107827:	6a 27                	push   $0x27
  jmp alltraps
80107829:	e9 16 f8 ff ff       	jmp    80107044 <alltraps>

8010782e <vector40>:
.globl vector40
vector40:
  pushl $0
8010782e:	6a 00                	push   $0x0
  pushl $40
80107830:	6a 28                	push   $0x28
  jmp alltraps
80107832:	e9 0d f8 ff ff       	jmp    80107044 <alltraps>

80107837 <vector41>:
.globl vector41
vector41:
  pushl $0
80107837:	6a 00                	push   $0x0
  pushl $41
80107839:	6a 29                	push   $0x29
  jmp alltraps
8010783b:	e9 04 f8 ff ff       	jmp    80107044 <alltraps>

80107840 <vector42>:
.globl vector42
vector42:
  pushl $0
80107840:	6a 00                	push   $0x0
  pushl $42
80107842:	6a 2a                	push   $0x2a
  jmp alltraps
80107844:	e9 fb f7 ff ff       	jmp    80107044 <alltraps>

80107849 <vector43>:
.globl vector43
vector43:
  pushl $0
80107849:	6a 00                	push   $0x0
  pushl $43
8010784b:	6a 2b                	push   $0x2b
  jmp alltraps
8010784d:	e9 f2 f7 ff ff       	jmp    80107044 <alltraps>

80107852 <vector44>:
.globl vector44
vector44:
  pushl $0
80107852:	6a 00                	push   $0x0
  pushl $44
80107854:	6a 2c                	push   $0x2c
  jmp alltraps
80107856:	e9 e9 f7 ff ff       	jmp    80107044 <alltraps>

8010785b <vector45>:
.globl vector45
vector45:
  pushl $0
8010785b:	6a 00                	push   $0x0
  pushl $45
8010785d:	6a 2d                	push   $0x2d
  jmp alltraps
8010785f:	e9 e0 f7 ff ff       	jmp    80107044 <alltraps>

80107864 <vector46>:
.globl vector46
vector46:
  pushl $0
80107864:	6a 00                	push   $0x0
  pushl $46
80107866:	6a 2e                	push   $0x2e
  jmp alltraps
80107868:	e9 d7 f7 ff ff       	jmp    80107044 <alltraps>

8010786d <vector47>:
.globl vector47
vector47:
  pushl $0
8010786d:	6a 00                	push   $0x0
  pushl $47
8010786f:	6a 2f                	push   $0x2f
  jmp alltraps
80107871:	e9 ce f7 ff ff       	jmp    80107044 <alltraps>

80107876 <vector48>:
.globl vector48
vector48:
  pushl $0
80107876:	6a 00                	push   $0x0
  pushl $48
80107878:	6a 30                	push   $0x30
  jmp alltraps
8010787a:	e9 c5 f7 ff ff       	jmp    80107044 <alltraps>

8010787f <vector49>:
.globl vector49
vector49:
  pushl $0
8010787f:	6a 00                	push   $0x0
  pushl $49
80107881:	6a 31                	push   $0x31
  jmp alltraps
80107883:	e9 bc f7 ff ff       	jmp    80107044 <alltraps>

80107888 <vector50>:
.globl vector50
vector50:
  pushl $0
80107888:	6a 00                	push   $0x0
  pushl $50
8010788a:	6a 32                	push   $0x32
  jmp alltraps
8010788c:	e9 b3 f7 ff ff       	jmp    80107044 <alltraps>

80107891 <vector51>:
.globl vector51
vector51:
  pushl $0
80107891:	6a 00                	push   $0x0
  pushl $51
80107893:	6a 33                	push   $0x33
  jmp alltraps
80107895:	e9 aa f7 ff ff       	jmp    80107044 <alltraps>

8010789a <vector52>:
.globl vector52
vector52:
  pushl $0
8010789a:	6a 00                	push   $0x0
  pushl $52
8010789c:	6a 34                	push   $0x34
  jmp alltraps
8010789e:	e9 a1 f7 ff ff       	jmp    80107044 <alltraps>

801078a3 <vector53>:
.globl vector53
vector53:
  pushl $0
801078a3:	6a 00                	push   $0x0
  pushl $53
801078a5:	6a 35                	push   $0x35
  jmp alltraps
801078a7:	e9 98 f7 ff ff       	jmp    80107044 <alltraps>

801078ac <vector54>:
.globl vector54
vector54:
  pushl $0
801078ac:	6a 00                	push   $0x0
  pushl $54
801078ae:	6a 36                	push   $0x36
  jmp alltraps
801078b0:	e9 8f f7 ff ff       	jmp    80107044 <alltraps>

801078b5 <vector55>:
.globl vector55
vector55:
  pushl $0
801078b5:	6a 00                	push   $0x0
  pushl $55
801078b7:	6a 37                	push   $0x37
  jmp alltraps
801078b9:	e9 86 f7 ff ff       	jmp    80107044 <alltraps>

801078be <vector56>:
.globl vector56
vector56:
  pushl $0
801078be:	6a 00                	push   $0x0
  pushl $56
801078c0:	6a 38                	push   $0x38
  jmp alltraps
801078c2:	e9 7d f7 ff ff       	jmp    80107044 <alltraps>

801078c7 <vector57>:
.globl vector57
vector57:
  pushl $0
801078c7:	6a 00                	push   $0x0
  pushl $57
801078c9:	6a 39                	push   $0x39
  jmp alltraps
801078cb:	e9 74 f7 ff ff       	jmp    80107044 <alltraps>

801078d0 <vector58>:
.globl vector58
vector58:
  pushl $0
801078d0:	6a 00                	push   $0x0
  pushl $58
801078d2:	6a 3a                	push   $0x3a
  jmp alltraps
801078d4:	e9 6b f7 ff ff       	jmp    80107044 <alltraps>

801078d9 <vector59>:
.globl vector59
vector59:
  pushl $0
801078d9:	6a 00                	push   $0x0
  pushl $59
801078db:	6a 3b                	push   $0x3b
  jmp alltraps
801078dd:	e9 62 f7 ff ff       	jmp    80107044 <alltraps>

801078e2 <vector60>:
.globl vector60
vector60:
  pushl $0
801078e2:	6a 00                	push   $0x0
  pushl $60
801078e4:	6a 3c                	push   $0x3c
  jmp alltraps
801078e6:	e9 59 f7 ff ff       	jmp    80107044 <alltraps>

801078eb <vector61>:
.globl vector61
vector61:
  pushl $0
801078eb:	6a 00                	push   $0x0
  pushl $61
801078ed:	6a 3d                	push   $0x3d
  jmp alltraps
801078ef:	e9 50 f7 ff ff       	jmp    80107044 <alltraps>

801078f4 <vector62>:
.globl vector62
vector62:
  pushl $0
801078f4:	6a 00                	push   $0x0
  pushl $62
801078f6:	6a 3e                	push   $0x3e
  jmp alltraps
801078f8:	e9 47 f7 ff ff       	jmp    80107044 <alltraps>

801078fd <vector63>:
.globl vector63
vector63:
  pushl $0
801078fd:	6a 00                	push   $0x0
  pushl $63
801078ff:	6a 3f                	push   $0x3f
  jmp alltraps
80107901:	e9 3e f7 ff ff       	jmp    80107044 <alltraps>

80107906 <vector64>:
.globl vector64
vector64:
  pushl $0
80107906:	6a 00                	push   $0x0
  pushl $64
80107908:	6a 40                	push   $0x40
  jmp alltraps
8010790a:	e9 35 f7 ff ff       	jmp    80107044 <alltraps>

8010790f <vector65>:
.globl vector65
vector65:
  pushl $0
8010790f:	6a 00                	push   $0x0
  pushl $65
80107911:	6a 41                	push   $0x41
  jmp alltraps
80107913:	e9 2c f7 ff ff       	jmp    80107044 <alltraps>

80107918 <vector66>:
.globl vector66
vector66:
  pushl $0
80107918:	6a 00                	push   $0x0
  pushl $66
8010791a:	6a 42                	push   $0x42
  jmp alltraps
8010791c:	e9 23 f7 ff ff       	jmp    80107044 <alltraps>

80107921 <vector67>:
.globl vector67
vector67:
  pushl $0
80107921:	6a 00                	push   $0x0
  pushl $67
80107923:	6a 43                	push   $0x43
  jmp alltraps
80107925:	e9 1a f7 ff ff       	jmp    80107044 <alltraps>

8010792a <vector68>:
.globl vector68
vector68:
  pushl $0
8010792a:	6a 00                	push   $0x0
  pushl $68
8010792c:	6a 44                	push   $0x44
  jmp alltraps
8010792e:	e9 11 f7 ff ff       	jmp    80107044 <alltraps>

80107933 <vector69>:
.globl vector69
vector69:
  pushl $0
80107933:	6a 00                	push   $0x0
  pushl $69
80107935:	6a 45                	push   $0x45
  jmp alltraps
80107937:	e9 08 f7 ff ff       	jmp    80107044 <alltraps>

8010793c <vector70>:
.globl vector70
vector70:
  pushl $0
8010793c:	6a 00                	push   $0x0
  pushl $70
8010793e:	6a 46                	push   $0x46
  jmp alltraps
80107940:	e9 ff f6 ff ff       	jmp    80107044 <alltraps>

80107945 <vector71>:
.globl vector71
vector71:
  pushl $0
80107945:	6a 00                	push   $0x0
  pushl $71
80107947:	6a 47                	push   $0x47
  jmp alltraps
80107949:	e9 f6 f6 ff ff       	jmp    80107044 <alltraps>

8010794e <vector72>:
.globl vector72
vector72:
  pushl $0
8010794e:	6a 00                	push   $0x0
  pushl $72
80107950:	6a 48                	push   $0x48
  jmp alltraps
80107952:	e9 ed f6 ff ff       	jmp    80107044 <alltraps>

80107957 <vector73>:
.globl vector73
vector73:
  pushl $0
80107957:	6a 00                	push   $0x0
  pushl $73
80107959:	6a 49                	push   $0x49
  jmp alltraps
8010795b:	e9 e4 f6 ff ff       	jmp    80107044 <alltraps>

80107960 <vector74>:
.globl vector74
vector74:
  pushl $0
80107960:	6a 00                	push   $0x0
  pushl $74
80107962:	6a 4a                	push   $0x4a
  jmp alltraps
80107964:	e9 db f6 ff ff       	jmp    80107044 <alltraps>

80107969 <vector75>:
.globl vector75
vector75:
  pushl $0
80107969:	6a 00                	push   $0x0
  pushl $75
8010796b:	6a 4b                	push   $0x4b
  jmp alltraps
8010796d:	e9 d2 f6 ff ff       	jmp    80107044 <alltraps>

80107972 <vector76>:
.globl vector76
vector76:
  pushl $0
80107972:	6a 00                	push   $0x0
  pushl $76
80107974:	6a 4c                	push   $0x4c
  jmp alltraps
80107976:	e9 c9 f6 ff ff       	jmp    80107044 <alltraps>

8010797b <vector77>:
.globl vector77
vector77:
  pushl $0
8010797b:	6a 00                	push   $0x0
  pushl $77
8010797d:	6a 4d                	push   $0x4d
  jmp alltraps
8010797f:	e9 c0 f6 ff ff       	jmp    80107044 <alltraps>

80107984 <vector78>:
.globl vector78
vector78:
  pushl $0
80107984:	6a 00                	push   $0x0
  pushl $78
80107986:	6a 4e                	push   $0x4e
  jmp alltraps
80107988:	e9 b7 f6 ff ff       	jmp    80107044 <alltraps>

8010798d <vector79>:
.globl vector79
vector79:
  pushl $0
8010798d:	6a 00                	push   $0x0
  pushl $79
8010798f:	6a 4f                	push   $0x4f
  jmp alltraps
80107991:	e9 ae f6 ff ff       	jmp    80107044 <alltraps>

80107996 <vector80>:
.globl vector80
vector80:
  pushl $0
80107996:	6a 00                	push   $0x0
  pushl $80
80107998:	6a 50                	push   $0x50
  jmp alltraps
8010799a:	e9 a5 f6 ff ff       	jmp    80107044 <alltraps>

8010799f <vector81>:
.globl vector81
vector81:
  pushl $0
8010799f:	6a 00                	push   $0x0
  pushl $81
801079a1:	6a 51                	push   $0x51
  jmp alltraps
801079a3:	e9 9c f6 ff ff       	jmp    80107044 <alltraps>

801079a8 <vector82>:
.globl vector82
vector82:
  pushl $0
801079a8:	6a 00                	push   $0x0
  pushl $82
801079aa:	6a 52                	push   $0x52
  jmp alltraps
801079ac:	e9 93 f6 ff ff       	jmp    80107044 <alltraps>

801079b1 <vector83>:
.globl vector83
vector83:
  pushl $0
801079b1:	6a 00                	push   $0x0
  pushl $83
801079b3:	6a 53                	push   $0x53
  jmp alltraps
801079b5:	e9 8a f6 ff ff       	jmp    80107044 <alltraps>

801079ba <vector84>:
.globl vector84
vector84:
  pushl $0
801079ba:	6a 00                	push   $0x0
  pushl $84
801079bc:	6a 54                	push   $0x54
  jmp alltraps
801079be:	e9 81 f6 ff ff       	jmp    80107044 <alltraps>

801079c3 <vector85>:
.globl vector85
vector85:
  pushl $0
801079c3:	6a 00                	push   $0x0
  pushl $85
801079c5:	6a 55                	push   $0x55
  jmp alltraps
801079c7:	e9 78 f6 ff ff       	jmp    80107044 <alltraps>

801079cc <vector86>:
.globl vector86
vector86:
  pushl $0
801079cc:	6a 00                	push   $0x0
  pushl $86
801079ce:	6a 56                	push   $0x56
  jmp alltraps
801079d0:	e9 6f f6 ff ff       	jmp    80107044 <alltraps>

801079d5 <vector87>:
.globl vector87
vector87:
  pushl $0
801079d5:	6a 00                	push   $0x0
  pushl $87
801079d7:	6a 57                	push   $0x57
  jmp alltraps
801079d9:	e9 66 f6 ff ff       	jmp    80107044 <alltraps>

801079de <vector88>:
.globl vector88
vector88:
  pushl $0
801079de:	6a 00                	push   $0x0
  pushl $88
801079e0:	6a 58                	push   $0x58
  jmp alltraps
801079e2:	e9 5d f6 ff ff       	jmp    80107044 <alltraps>

801079e7 <vector89>:
.globl vector89
vector89:
  pushl $0
801079e7:	6a 00                	push   $0x0
  pushl $89
801079e9:	6a 59                	push   $0x59
  jmp alltraps
801079eb:	e9 54 f6 ff ff       	jmp    80107044 <alltraps>

801079f0 <vector90>:
.globl vector90
vector90:
  pushl $0
801079f0:	6a 00                	push   $0x0
  pushl $90
801079f2:	6a 5a                	push   $0x5a
  jmp alltraps
801079f4:	e9 4b f6 ff ff       	jmp    80107044 <alltraps>

801079f9 <vector91>:
.globl vector91
vector91:
  pushl $0
801079f9:	6a 00                	push   $0x0
  pushl $91
801079fb:	6a 5b                	push   $0x5b
  jmp alltraps
801079fd:	e9 42 f6 ff ff       	jmp    80107044 <alltraps>

80107a02 <vector92>:
.globl vector92
vector92:
  pushl $0
80107a02:	6a 00                	push   $0x0
  pushl $92
80107a04:	6a 5c                	push   $0x5c
  jmp alltraps
80107a06:	e9 39 f6 ff ff       	jmp    80107044 <alltraps>

80107a0b <vector93>:
.globl vector93
vector93:
  pushl $0
80107a0b:	6a 00                	push   $0x0
  pushl $93
80107a0d:	6a 5d                	push   $0x5d
  jmp alltraps
80107a0f:	e9 30 f6 ff ff       	jmp    80107044 <alltraps>

80107a14 <vector94>:
.globl vector94
vector94:
  pushl $0
80107a14:	6a 00                	push   $0x0
  pushl $94
80107a16:	6a 5e                	push   $0x5e
  jmp alltraps
80107a18:	e9 27 f6 ff ff       	jmp    80107044 <alltraps>

80107a1d <vector95>:
.globl vector95
vector95:
  pushl $0
80107a1d:	6a 00                	push   $0x0
  pushl $95
80107a1f:	6a 5f                	push   $0x5f
  jmp alltraps
80107a21:	e9 1e f6 ff ff       	jmp    80107044 <alltraps>

80107a26 <vector96>:
.globl vector96
vector96:
  pushl $0
80107a26:	6a 00                	push   $0x0
  pushl $96
80107a28:	6a 60                	push   $0x60
  jmp alltraps
80107a2a:	e9 15 f6 ff ff       	jmp    80107044 <alltraps>

80107a2f <vector97>:
.globl vector97
vector97:
  pushl $0
80107a2f:	6a 00                	push   $0x0
  pushl $97
80107a31:	6a 61                	push   $0x61
  jmp alltraps
80107a33:	e9 0c f6 ff ff       	jmp    80107044 <alltraps>

80107a38 <vector98>:
.globl vector98
vector98:
  pushl $0
80107a38:	6a 00                	push   $0x0
  pushl $98
80107a3a:	6a 62                	push   $0x62
  jmp alltraps
80107a3c:	e9 03 f6 ff ff       	jmp    80107044 <alltraps>

80107a41 <vector99>:
.globl vector99
vector99:
  pushl $0
80107a41:	6a 00                	push   $0x0
  pushl $99
80107a43:	6a 63                	push   $0x63
  jmp alltraps
80107a45:	e9 fa f5 ff ff       	jmp    80107044 <alltraps>

80107a4a <vector100>:
.globl vector100
vector100:
  pushl $0
80107a4a:	6a 00                	push   $0x0
  pushl $100
80107a4c:	6a 64                	push   $0x64
  jmp alltraps
80107a4e:	e9 f1 f5 ff ff       	jmp    80107044 <alltraps>

80107a53 <vector101>:
.globl vector101
vector101:
  pushl $0
80107a53:	6a 00                	push   $0x0
  pushl $101
80107a55:	6a 65                	push   $0x65
  jmp alltraps
80107a57:	e9 e8 f5 ff ff       	jmp    80107044 <alltraps>

80107a5c <vector102>:
.globl vector102
vector102:
  pushl $0
80107a5c:	6a 00                	push   $0x0
  pushl $102
80107a5e:	6a 66                	push   $0x66
  jmp alltraps
80107a60:	e9 df f5 ff ff       	jmp    80107044 <alltraps>

80107a65 <vector103>:
.globl vector103
vector103:
  pushl $0
80107a65:	6a 00                	push   $0x0
  pushl $103
80107a67:	6a 67                	push   $0x67
  jmp alltraps
80107a69:	e9 d6 f5 ff ff       	jmp    80107044 <alltraps>

80107a6e <vector104>:
.globl vector104
vector104:
  pushl $0
80107a6e:	6a 00                	push   $0x0
  pushl $104
80107a70:	6a 68                	push   $0x68
  jmp alltraps
80107a72:	e9 cd f5 ff ff       	jmp    80107044 <alltraps>

80107a77 <vector105>:
.globl vector105
vector105:
  pushl $0
80107a77:	6a 00                	push   $0x0
  pushl $105
80107a79:	6a 69                	push   $0x69
  jmp alltraps
80107a7b:	e9 c4 f5 ff ff       	jmp    80107044 <alltraps>

80107a80 <vector106>:
.globl vector106
vector106:
  pushl $0
80107a80:	6a 00                	push   $0x0
  pushl $106
80107a82:	6a 6a                	push   $0x6a
  jmp alltraps
80107a84:	e9 bb f5 ff ff       	jmp    80107044 <alltraps>

80107a89 <vector107>:
.globl vector107
vector107:
  pushl $0
80107a89:	6a 00                	push   $0x0
  pushl $107
80107a8b:	6a 6b                	push   $0x6b
  jmp alltraps
80107a8d:	e9 b2 f5 ff ff       	jmp    80107044 <alltraps>

80107a92 <vector108>:
.globl vector108
vector108:
  pushl $0
80107a92:	6a 00                	push   $0x0
  pushl $108
80107a94:	6a 6c                	push   $0x6c
  jmp alltraps
80107a96:	e9 a9 f5 ff ff       	jmp    80107044 <alltraps>

80107a9b <vector109>:
.globl vector109
vector109:
  pushl $0
80107a9b:	6a 00                	push   $0x0
  pushl $109
80107a9d:	6a 6d                	push   $0x6d
  jmp alltraps
80107a9f:	e9 a0 f5 ff ff       	jmp    80107044 <alltraps>

80107aa4 <vector110>:
.globl vector110
vector110:
  pushl $0
80107aa4:	6a 00                	push   $0x0
  pushl $110
80107aa6:	6a 6e                	push   $0x6e
  jmp alltraps
80107aa8:	e9 97 f5 ff ff       	jmp    80107044 <alltraps>

80107aad <vector111>:
.globl vector111
vector111:
  pushl $0
80107aad:	6a 00                	push   $0x0
  pushl $111
80107aaf:	6a 6f                	push   $0x6f
  jmp alltraps
80107ab1:	e9 8e f5 ff ff       	jmp    80107044 <alltraps>

80107ab6 <vector112>:
.globl vector112
vector112:
  pushl $0
80107ab6:	6a 00                	push   $0x0
  pushl $112
80107ab8:	6a 70                	push   $0x70
  jmp alltraps
80107aba:	e9 85 f5 ff ff       	jmp    80107044 <alltraps>

80107abf <vector113>:
.globl vector113
vector113:
  pushl $0
80107abf:	6a 00                	push   $0x0
  pushl $113
80107ac1:	6a 71                	push   $0x71
  jmp alltraps
80107ac3:	e9 7c f5 ff ff       	jmp    80107044 <alltraps>

80107ac8 <vector114>:
.globl vector114
vector114:
  pushl $0
80107ac8:	6a 00                	push   $0x0
  pushl $114
80107aca:	6a 72                	push   $0x72
  jmp alltraps
80107acc:	e9 73 f5 ff ff       	jmp    80107044 <alltraps>

80107ad1 <vector115>:
.globl vector115
vector115:
  pushl $0
80107ad1:	6a 00                	push   $0x0
  pushl $115
80107ad3:	6a 73                	push   $0x73
  jmp alltraps
80107ad5:	e9 6a f5 ff ff       	jmp    80107044 <alltraps>

80107ada <vector116>:
.globl vector116
vector116:
  pushl $0
80107ada:	6a 00                	push   $0x0
  pushl $116
80107adc:	6a 74                	push   $0x74
  jmp alltraps
80107ade:	e9 61 f5 ff ff       	jmp    80107044 <alltraps>

80107ae3 <vector117>:
.globl vector117
vector117:
  pushl $0
80107ae3:	6a 00                	push   $0x0
  pushl $117
80107ae5:	6a 75                	push   $0x75
  jmp alltraps
80107ae7:	e9 58 f5 ff ff       	jmp    80107044 <alltraps>

80107aec <vector118>:
.globl vector118
vector118:
  pushl $0
80107aec:	6a 00                	push   $0x0
  pushl $118
80107aee:	6a 76                	push   $0x76
  jmp alltraps
80107af0:	e9 4f f5 ff ff       	jmp    80107044 <alltraps>

80107af5 <vector119>:
.globl vector119
vector119:
  pushl $0
80107af5:	6a 00                	push   $0x0
  pushl $119
80107af7:	6a 77                	push   $0x77
  jmp alltraps
80107af9:	e9 46 f5 ff ff       	jmp    80107044 <alltraps>

80107afe <vector120>:
.globl vector120
vector120:
  pushl $0
80107afe:	6a 00                	push   $0x0
  pushl $120
80107b00:	6a 78                	push   $0x78
  jmp alltraps
80107b02:	e9 3d f5 ff ff       	jmp    80107044 <alltraps>

80107b07 <vector121>:
.globl vector121
vector121:
  pushl $0
80107b07:	6a 00                	push   $0x0
  pushl $121
80107b09:	6a 79                	push   $0x79
  jmp alltraps
80107b0b:	e9 34 f5 ff ff       	jmp    80107044 <alltraps>

80107b10 <vector122>:
.globl vector122
vector122:
  pushl $0
80107b10:	6a 00                	push   $0x0
  pushl $122
80107b12:	6a 7a                	push   $0x7a
  jmp alltraps
80107b14:	e9 2b f5 ff ff       	jmp    80107044 <alltraps>

80107b19 <vector123>:
.globl vector123
vector123:
  pushl $0
80107b19:	6a 00                	push   $0x0
  pushl $123
80107b1b:	6a 7b                	push   $0x7b
  jmp alltraps
80107b1d:	e9 22 f5 ff ff       	jmp    80107044 <alltraps>

80107b22 <vector124>:
.globl vector124
vector124:
  pushl $0
80107b22:	6a 00                	push   $0x0
  pushl $124
80107b24:	6a 7c                	push   $0x7c
  jmp alltraps
80107b26:	e9 19 f5 ff ff       	jmp    80107044 <alltraps>

80107b2b <vector125>:
.globl vector125
vector125:
  pushl $0
80107b2b:	6a 00                	push   $0x0
  pushl $125
80107b2d:	6a 7d                	push   $0x7d
  jmp alltraps
80107b2f:	e9 10 f5 ff ff       	jmp    80107044 <alltraps>

80107b34 <vector126>:
.globl vector126
vector126:
  pushl $0
80107b34:	6a 00                	push   $0x0
  pushl $126
80107b36:	6a 7e                	push   $0x7e
  jmp alltraps
80107b38:	e9 07 f5 ff ff       	jmp    80107044 <alltraps>

80107b3d <vector127>:
.globl vector127
vector127:
  pushl $0
80107b3d:	6a 00                	push   $0x0
  pushl $127
80107b3f:	6a 7f                	push   $0x7f
  jmp alltraps
80107b41:	e9 fe f4 ff ff       	jmp    80107044 <alltraps>

80107b46 <vector128>:
.globl vector128
vector128:
  pushl $0
80107b46:	6a 00                	push   $0x0
  pushl $128
80107b48:	68 80 00 00 00       	push   $0x80
  jmp alltraps
80107b4d:	e9 f2 f4 ff ff       	jmp    80107044 <alltraps>

80107b52 <vector129>:
.globl vector129
vector129:
  pushl $0
80107b52:	6a 00                	push   $0x0
  pushl $129
80107b54:	68 81 00 00 00       	push   $0x81
  jmp alltraps
80107b59:	e9 e6 f4 ff ff       	jmp    80107044 <alltraps>

80107b5e <vector130>:
.globl vector130
vector130:
  pushl $0
80107b5e:	6a 00                	push   $0x0
  pushl $130
80107b60:	68 82 00 00 00       	push   $0x82
  jmp alltraps
80107b65:	e9 da f4 ff ff       	jmp    80107044 <alltraps>

80107b6a <vector131>:
.globl vector131
vector131:
  pushl $0
80107b6a:	6a 00                	push   $0x0
  pushl $131
80107b6c:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80107b71:	e9 ce f4 ff ff       	jmp    80107044 <alltraps>

80107b76 <vector132>:
.globl vector132
vector132:
  pushl $0
80107b76:	6a 00                	push   $0x0
  pushl $132
80107b78:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80107b7d:	e9 c2 f4 ff ff       	jmp    80107044 <alltraps>

80107b82 <vector133>:
.globl vector133
vector133:
  pushl $0
80107b82:	6a 00                	push   $0x0
  pushl $133
80107b84:	68 85 00 00 00       	push   $0x85
  jmp alltraps
80107b89:	e9 b6 f4 ff ff       	jmp    80107044 <alltraps>

80107b8e <vector134>:
.globl vector134
vector134:
  pushl $0
80107b8e:	6a 00                	push   $0x0
  pushl $134
80107b90:	68 86 00 00 00       	push   $0x86
  jmp alltraps
80107b95:	e9 aa f4 ff ff       	jmp    80107044 <alltraps>

80107b9a <vector135>:
.globl vector135
vector135:
  pushl $0
80107b9a:	6a 00                	push   $0x0
  pushl $135
80107b9c:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80107ba1:	e9 9e f4 ff ff       	jmp    80107044 <alltraps>

80107ba6 <vector136>:
.globl vector136
vector136:
  pushl $0
80107ba6:	6a 00                	push   $0x0
  pushl $136
80107ba8:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80107bad:	e9 92 f4 ff ff       	jmp    80107044 <alltraps>

80107bb2 <vector137>:
.globl vector137
vector137:
  pushl $0
80107bb2:	6a 00                	push   $0x0
  pushl $137
80107bb4:	68 89 00 00 00       	push   $0x89
  jmp alltraps
80107bb9:	e9 86 f4 ff ff       	jmp    80107044 <alltraps>

80107bbe <vector138>:
.globl vector138
vector138:
  pushl $0
80107bbe:	6a 00                	push   $0x0
  pushl $138
80107bc0:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80107bc5:	e9 7a f4 ff ff       	jmp    80107044 <alltraps>

80107bca <vector139>:
.globl vector139
vector139:
  pushl $0
80107bca:	6a 00                	push   $0x0
  pushl $139
80107bcc:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80107bd1:	e9 6e f4 ff ff       	jmp    80107044 <alltraps>

80107bd6 <vector140>:
.globl vector140
vector140:
  pushl $0
80107bd6:	6a 00                	push   $0x0
  pushl $140
80107bd8:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
80107bdd:	e9 62 f4 ff ff       	jmp    80107044 <alltraps>

80107be2 <vector141>:
.globl vector141
vector141:
  pushl $0
80107be2:	6a 00                	push   $0x0
  pushl $141
80107be4:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80107be9:	e9 56 f4 ff ff       	jmp    80107044 <alltraps>

80107bee <vector142>:
.globl vector142
vector142:
  pushl $0
80107bee:	6a 00                	push   $0x0
  pushl $142
80107bf0:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80107bf5:	e9 4a f4 ff ff       	jmp    80107044 <alltraps>

80107bfa <vector143>:
.globl vector143
vector143:
  pushl $0
80107bfa:	6a 00                	push   $0x0
  pushl $143
80107bfc:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80107c01:	e9 3e f4 ff ff       	jmp    80107044 <alltraps>

80107c06 <vector144>:
.globl vector144
vector144:
  pushl $0
80107c06:	6a 00                	push   $0x0
  pushl $144
80107c08:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80107c0d:	e9 32 f4 ff ff       	jmp    80107044 <alltraps>

80107c12 <vector145>:
.globl vector145
vector145:
  pushl $0
80107c12:	6a 00                	push   $0x0
  pushl $145
80107c14:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80107c19:	e9 26 f4 ff ff       	jmp    80107044 <alltraps>

80107c1e <vector146>:
.globl vector146
vector146:
  pushl $0
80107c1e:	6a 00                	push   $0x0
  pushl $146
80107c20:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80107c25:	e9 1a f4 ff ff       	jmp    80107044 <alltraps>

80107c2a <vector147>:
.globl vector147
vector147:
  pushl $0
80107c2a:	6a 00                	push   $0x0
  pushl $147
80107c2c:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80107c31:	e9 0e f4 ff ff       	jmp    80107044 <alltraps>

80107c36 <vector148>:
.globl vector148
vector148:
  pushl $0
80107c36:	6a 00                	push   $0x0
  pushl $148
80107c38:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80107c3d:	e9 02 f4 ff ff       	jmp    80107044 <alltraps>

80107c42 <vector149>:
.globl vector149
vector149:
  pushl $0
80107c42:	6a 00                	push   $0x0
  pushl $149
80107c44:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80107c49:	e9 f6 f3 ff ff       	jmp    80107044 <alltraps>

80107c4e <vector150>:
.globl vector150
vector150:
  pushl $0
80107c4e:	6a 00                	push   $0x0
  pushl $150
80107c50:	68 96 00 00 00       	push   $0x96
  jmp alltraps
80107c55:	e9 ea f3 ff ff       	jmp    80107044 <alltraps>

80107c5a <vector151>:
.globl vector151
vector151:
  pushl $0
80107c5a:	6a 00                	push   $0x0
  pushl $151
80107c5c:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80107c61:	e9 de f3 ff ff       	jmp    80107044 <alltraps>

80107c66 <vector152>:
.globl vector152
vector152:
  pushl $0
80107c66:	6a 00                	push   $0x0
  pushl $152
80107c68:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80107c6d:	e9 d2 f3 ff ff       	jmp    80107044 <alltraps>

80107c72 <vector153>:
.globl vector153
vector153:
  pushl $0
80107c72:	6a 00                	push   $0x0
  pushl $153
80107c74:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80107c79:	e9 c6 f3 ff ff       	jmp    80107044 <alltraps>

80107c7e <vector154>:
.globl vector154
vector154:
  pushl $0
80107c7e:	6a 00                	push   $0x0
  pushl $154
80107c80:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80107c85:	e9 ba f3 ff ff       	jmp    80107044 <alltraps>

80107c8a <vector155>:
.globl vector155
vector155:
  pushl $0
80107c8a:	6a 00                	push   $0x0
  pushl $155
80107c8c:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80107c91:	e9 ae f3 ff ff       	jmp    80107044 <alltraps>

80107c96 <vector156>:
.globl vector156
vector156:
  pushl $0
80107c96:	6a 00                	push   $0x0
  pushl $156
80107c98:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80107c9d:	e9 a2 f3 ff ff       	jmp    80107044 <alltraps>

80107ca2 <vector157>:
.globl vector157
vector157:
  pushl $0
80107ca2:	6a 00                	push   $0x0
  pushl $157
80107ca4:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80107ca9:	e9 96 f3 ff ff       	jmp    80107044 <alltraps>

80107cae <vector158>:
.globl vector158
vector158:
  pushl $0
80107cae:	6a 00                	push   $0x0
  pushl $158
80107cb0:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80107cb5:	e9 8a f3 ff ff       	jmp    80107044 <alltraps>

80107cba <vector159>:
.globl vector159
vector159:
  pushl $0
80107cba:	6a 00                	push   $0x0
  pushl $159
80107cbc:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80107cc1:	e9 7e f3 ff ff       	jmp    80107044 <alltraps>

80107cc6 <vector160>:
.globl vector160
vector160:
  pushl $0
80107cc6:	6a 00                	push   $0x0
  pushl $160
80107cc8:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80107ccd:	e9 72 f3 ff ff       	jmp    80107044 <alltraps>

80107cd2 <vector161>:
.globl vector161
vector161:
  pushl $0
80107cd2:	6a 00                	push   $0x0
  pushl $161
80107cd4:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80107cd9:	e9 66 f3 ff ff       	jmp    80107044 <alltraps>

80107cde <vector162>:
.globl vector162
vector162:
  pushl $0
80107cde:	6a 00                	push   $0x0
  pushl $162
80107ce0:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80107ce5:	e9 5a f3 ff ff       	jmp    80107044 <alltraps>

80107cea <vector163>:
.globl vector163
vector163:
  pushl $0
80107cea:	6a 00                	push   $0x0
  pushl $163
80107cec:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80107cf1:	e9 4e f3 ff ff       	jmp    80107044 <alltraps>

80107cf6 <vector164>:
.globl vector164
vector164:
  pushl $0
80107cf6:	6a 00                	push   $0x0
  pushl $164
80107cf8:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80107cfd:	e9 42 f3 ff ff       	jmp    80107044 <alltraps>

80107d02 <vector165>:
.globl vector165
vector165:
  pushl $0
80107d02:	6a 00                	push   $0x0
  pushl $165
80107d04:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80107d09:	e9 36 f3 ff ff       	jmp    80107044 <alltraps>

80107d0e <vector166>:
.globl vector166
vector166:
  pushl $0
80107d0e:	6a 00                	push   $0x0
  pushl $166
80107d10:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80107d15:	e9 2a f3 ff ff       	jmp    80107044 <alltraps>

80107d1a <vector167>:
.globl vector167
vector167:
  pushl $0
80107d1a:	6a 00                	push   $0x0
  pushl $167
80107d1c:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80107d21:	e9 1e f3 ff ff       	jmp    80107044 <alltraps>

80107d26 <vector168>:
.globl vector168
vector168:
  pushl $0
80107d26:	6a 00                	push   $0x0
  pushl $168
80107d28:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80107d2d:	e9 12 f3 ff ff       	jmp    80107044 <alltraps>

80107d32 <vector169>:
.globl vector169
vector169:
  pushl $0
80107d32:	6a 00                	push   $0x0
  pushl $169
80107d34:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80107d39:	e9 06 f3 ff ff       	jmp    80107044 <alltraps>

80107d3e <vector170>:
.globl vector170
vector170:
  pushl $0
80107d3e:	6a 00                	push   $0x0
  pushl $170
80107d40:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80107d45:	e9 fa f2 ff ff       	jmp    80107044 <alltraps>

80107d4a <vector171>:
.globl vector171
vector171:
  pushl $0
80107d4a:	6a 00                	push   $0x0
  pushl $171
80107d4c:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80107d51:	e9 ee f2 ff ff       	jmp    80107044 <alltraps>

80107d56 <vector172>:
.globl vector172
vector172:
  pushl $0
80107d56:	6a 00                	push   $0x0
  pushl $172
80107d58:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80107d5d:	e9 e2 f2 ff ff       	jmp    80107044 <alltraps>

80107d62 <vector173>:
.globl vector173
vector173:
  pushl $0
80107d62:	6a 00                	push   $0x0
  pushl $173
80107d64:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80107d69:	e9 d6 f2 ff ff       	jmp    80107044 <alltraps>

80107d6e <vector174>:
.globl vector174
vector174:
  pushl $0
80107d6e:	6a 00                	push   $0x0
  pushl $174
80107d70:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80107d75:	e9 ca f2 ff ff       	jmp    80107044 <alltraps>

80107d7a <vector175>:
.globl vector175
vector175:
  pushl $0
80107d7a:	6a 00                	push   $0x0
  pushl $175
80107d7c:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80107d81:	e9 be f2 ff ff       	jmp    80107044 <alltraps>

80107d86 <vector176>:
.globl vector176
vector176:
  pushl $0
80107d86:	6a 00                	push   $0x0
  pushl $176
80107d88:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80107d8d:	e9 b2 f2 ff ff       	jmp    80107044 <alltraps>

80107d92 <vector177>:
.globl vector177
vector177:
  pushl $0
80107d92:	6a 00                	push   $0x0
  pushl $177
80107d94:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80107d99:	e9 a6 f2 ff ff       	jmp    80107044 <alltraps>

80107d9e <vector178>:
.globl vector178
vector178:
  pushl $0
80107d9e:	6a 00                	push   $0x0
  pushl $178
80107da0:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80107da5:	e9 9a f2 ff ff       	jmp    80107044 <alltraps>

80107daa <vector179>:
.globl vector179
vector179:
  pushl $0
80107daa:	6a 00                	push   $0x0
  pushl $179
80107dac:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80107db1:	e9 8e f2 ff ff       	jmp    80107044 <alltraps>

80107db6 <vector180>:
.globl vector180
vector180:
  pushl $0
80107db6:	6a 00                	push   $0x0
  pushl $180
80107db8:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80107dbd:	e9 82 f2 ff ff       	jmp    80107044 <alltraps>

80107dc2 <vector181>:
.globl vector181
vector181:
  pushl $0
80107dc2:	6a 00                	push   $0x0
  pushl $181
80107dc4:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80107dc9:	e9 76 f2 ff ff       	jmp    80107044 <alltraps>

80107dce <vector182>:
.globl vector182
vector182:
  pushl $0
80107dce:	6a 00                	push   $0x0
  pushl $182
80107dd0:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80107dd5:	e9 6a f2 ff ff       	jmp    80107044 <alltraps>

80107dda <vector183>:
.globl vector183
vector183:
  pushl $0
80107dda:	6a 00                	push   $0x0
  pushl $183
80107ddc:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80107de1:	e9 5e f2 ff ff       	jmp    80107044 <alltraps>

80107de6 <vector184>:
.globl vector184
vector184:
  pushl $0
80107de6:	6a 00                	push   $0x0
  pushl $184
80107de8:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80107ded:	e9 52 f2 ff ff       	jmp    80107044 <alltraps>

80107df2 <vector185>:
.globl vector185
vector185:
  pushl $0
80107df2:	6a 00                	push   $0x0
  pushl $185
80107df4:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80107df9:	e9 46 f2 ff ff       	jmp    80107044 <alltraps>

80107dfe <vector186>:
.globl vector186
vector186:
  pushl $0
80107dfe:	6a 00                	push   $0x0
  pushl $186
80107e00:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80107e05:	e9 3a f2 ff ff       	jmp    80107044 <alltraps>

80107e0a <vector187>:
.globl vector187
vector187:
  pushl $0
80107e0a:	6a 00                	push   $0x0
  pushl $187
80107e0c:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80107e11:	e9 2e f2 ff ff       	jmp    80107044 <alltraps>

80107e16 <vector188>:
.globl vector188
vector188:
  pushl $0
80107e16:	6a 00                	push   $0x0
  pushl $188
80107e18:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80107e1d:	e9 22 f2 ff ff       	jmp    80107044 <alltraps>

80107e22 <vector189>:
.globl vector189
vector189:
  pushl $0
80107e22:	6a 00                	push   $0x0
  pushl $189
80107e24:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80107e29:	e9 16 f2 ff ff       	jmp    80107044 <alltraps>

80107e2e <vector190>:
.globl vector190
vector190:
  pushl $0
80107e2e:	6a 00                	push   $0x0
  pushl $190
80107e30:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80107e35:	e9 0a f2 ff ff       	jmp    80107044 <alltraps>

80107e3a <vector191>:
.globl vector191
vector191:
  pushl $0
80107e3a:	6a 00                	push   $0x0
  pushl $191
80107e3c:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80107e41:	e9 fe f1 ff ff       	jmp    80107044 <alltraps>

80107e46 <vector192>:
.globl vector192
vector192:
  pushl $0
80107e46:	6a 00                	push   $0x0
  pushl $192
80107e48:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80107e4d:	e9 f2 f1 ff ff       	jmp    80107044 <alltraps>

80107e52 <vector193>:
.globl vector193
vector193:
  pushl $0
80107e52:	6a 00                	push   $0x0
  pushl $193
80107e54:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80107e59:	e9 e6 f1 ff ff       	jmp    80107044 <alltraps>

80107e5e <vector194>:
.globl vector194
vector194:
  pushl $0
80107e5e:	6a 00                	push   $0x0
  pushl $194
80107e60:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80107e65:	e9 da f1 ff ff       	jmp    80107044 <alltraps>

80107e6a <vector195>:
.globl vector195
vector195:
  pushl $0
80107e6a:	6a 00                	push   $0x0
  pushl $195
80107e6c:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80107e71:	e9 ce f1 ff ff       	jmp    80107044 <alltraps>

80107e76 <vector196>:
.globl vector196
vector196:
  pushl $0
80107e76:	6a 00                	push   $0x0
  pushl $196
80107e78:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80107e7d:	e9 c2 f1 ff ff       	jmp    80107044 <alltraps>

80107e82 <vector197>:
.globl vector197
vector197:
  pushl $0
80107e82:	6a 00                	push   $0x0
  pushl $197
80107e84:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80107e89:	e9 b6 f1 ff ff       	jmp    80107044 <alltraps>

80107e8e <vector198>:
.globl vector198
vector198:
  pushl $0
80107e8e:	6a 00                	push   $0x0
  pushl $198
80107e90:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80107e95:	e9 aa f1 ff ff       	jmp    80107044 <alltraps>

80107e9a <vector199>:
.globl vector199
vector199:
  pushl $0
80107e9a:	6a 00                	push   $0x0
  pushl $199
80107e9c:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80107ea1:	e9 9e f1 ff ff       	jmp    80107044 <alltraps>

80107ea6 <vector200>:
.globl vector200
vector200:
  pushl $0
80107ea6:	6a 00                	push   $0x0
  pushl $200
80107ea8:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80107ead:	e9 92 f1 ff ff       	jmp    80107044 <alltraps>

80107eb2 <vector201>:
.globl vector201
vector201:
  pushl $0
80107eb2:	6a 00                	push   $0x0
  pushl $201
80107eb4:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80107eb9:	e9 86 f1 ff ff       	jmp    80107044 <alltraps>

80107ebe <vector202>:
.globl vector202
vector202:
  pushl $0
80107ebe:	6a 00                	push   $0x0
  pushl $202
80107ec0:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80107ec5:	e9 7a f1 ff ff       	jmp    80107044 <alltraps>

80107eca <vector203>:
.globl vector203
vector203:
  pushl $0
80107eca:	6a 00                	push   $0x0
  pushl $203
80107ecc:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80107ed1:	e9 6e f1 ff ff       	jmp    80107044 <alltraps>

80107ed6 <vector204>:
.globl vector204
vector204:
  pushl $0
80107ed6:	6a 00                	push   $0x0
  pushl $204
80107ed8:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80107edd:	e9 62 f1 ff ff       	jmp    80107044 <alltraps>

80107ee2 <vector205>:
.globl vector205
vector205:
  pushl $0
80107ee2:	6a 00                	push   $0x0
  pushl $205
80107ee4:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80107ee9:	e9 56 f1 ff ff       	jmp    80107044 <alltraps>

80107eee <vector206>:
.globl vector206
vector206:
  pushl $0
80107eee:	6a 00                	push   $0x0
  pushl $206
80107ef0:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80107ef5:	e9 4a f1 ff ff       	jmp    80107044 <alltraps>

80107efa <vector207>:
.globl vector207
vector207:
  pushl $0
80107efa:	6a 00                	push   $0x0
  pushl $207
80107efc:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80107f01:	e9 3e f1 ff ff       	jmp    80107044 <alltraps>

80107f06 <vector208>:
.globl vector208
vector208:
  pushl $0
80107f06:	6a 00                	push   $0x0
  pushl $208
80107f08:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80107f0d:	e9 32 f1 ff ff       	jmp    80107044 <alltraps>

80107f12 <vector209>:
.globl vector209
vector209:
  pushl $0
80107f12:	6a 00                	push   $0x0
  pushl $209
80107f14:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80107f19:	e9 26 f1 ff ff       	jmp    80107044 <alltraps>

80107f1e <vector210>:
.globl vector210
vector210:
  pushl $0
80107f1e:	6a 00                	push   $0x0
  pushl $210
80107f20:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80107f25:	e9 1a f1 ff ff       	jmp    80107044 <alltraps>

80107f2a <vector211>:
.globl vector211
vector211:
  pushl $0
80107f2a:	6a 00                	push   $0x0
  pushl $211
80107f2c:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80107f31:	e9 0e f1 ff ff       	jmp    80107044 <alltraps>

80107f36 <vector212>:
.globl vector212
vector212:
  pushl $0
80107f36:	6a 00                	push   $0x0
  pushl $212
80107f38:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80107f3d:	e9 02 f1 ff ff       	jmp    80107044 <alltraps>

80107f42 <vector213>:
.globl vector213
vector213:
  pushl $0
80107f42:	6a 00                	push   $0x0
  pushl $213
80107f44:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80107f49:	e9 f6 f0 ff ff       	jmp    80107044 <alltraps>

80107f4e <vector214>:
.globl vector214
vector214:
  pushl $0
80107f4e:	6a 00                	push   $0x0
  pushl $214
80107f50:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80107f55:	e9 ea f0 ff ff       	jmp    80107044 <alltraps>

80107f5a <vector215>:
.globl vector215
vector215:
  pushl $0
80107f5a:	6a 00                	push   $0x0
  pushl $215
80107f5c:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80107f61:	e9 de f0 ff ff       	jmp    80107044 <alltraps>

80107f66 <vector216>:
.globl vector216
vector216:
  pushl $0
80107f66:	6a 00                	push   $0x0
  pushl $216
80107f68:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80107f6d:	e9 d2 f0 ff ff       	jmp    80107044 <alltraps>

80107f72 <vector217>:
.globl vector217
vector217:
  pushl $0
80107f72:	6a 00                	push   $0x0
  pushl $217
80107f74:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80107f79:	e9 c6 f0 ff ff       	jmp    80107044 <alltraps>

80107f7e <vector218>:
.globl vector218
vector218:
  pushl $0
80107f7e:	6a 00                	push   $0x0
  pushl $218
80107f80:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80107f85:	e9 ba f0 ff ff       	jmp    80107044 <alltraps>

80107f8a <vector219>:
.globl vector219
vector219:
  pushl $0
80107f8a:	6a 00                	push   $0x0
  pushl $219
80107f8c:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80107f91:	e9 ae f0 ff ff       	jmp    80107044 <alltraps>

80107f96 <vector220>:
.globl vector220
vector220:
  pushl $0
80107f96:	6a 00                	push   $0x0
  pushl $220
80107f98:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80107f9d:	e9 a2 f0 ff ff       	jmp    80107044 <alltraps>

80107fa2 <vector221>:
.globl vector221
vector221:
  pushl $0
80107fa2:	6a 00                	push   $0x0
  pushl $221
80107fa4:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80107fa9:	e9 96 f0 ff ff       	jmp    80107044 <alltraps>

80107fae <vector222>:
.globl vector222
vector222:
  pushl $0
80107fae:	6a 00                	push   $0x0
  pushl $222
80107fb0:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80107fb5:	e9 8a f0 ff ff       	jmp    80107044 <alltraps>

80107fba <vector223>:
.globl vector223
vector223:
  pushl $0
80107fba:	6a 00                	push   $0x0
  pushl $223
80107fbc:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80107fc1:	e9 7e f0 ff ff       	jmp    80107044 <alltraps>

80107fc6 <vector224>:
.globl vector224
vector224:
  pushl $0
80107fc6:	6a 00                	push   $0x0
  pushl $224
80107fc8:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80107fcd:	e9 72 f0 ff ff       	jmp    80107044 <alltraps>

80107fd2 <vector225>:
.globl vector225
vector225:
  pushl $0
80107fd2:	6a 00                	push   $0x0
  pushl $225
80107fd4:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80107fd9:	e9 66 f0 ff ff       	jmp    80107044 <alltraps>

80107fde <vector226>:
.globl vector226
vector226:
  pushl $0
80107fde:	6a 00                	push   $0x0
  pushl $226
80107fe0:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80107fe5:	e9 5a f0 ff ff       	jmp    80107044 <alltraps>

80107fea <vector227>:
.globl vector227
vector227:
  pushl $0
80107fea:	6a 00                	push   $0x0
  pushl $227
80107fec:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80107ff1:	e9 4e f0 ff ff       	jmp    80107044 <alltraps>

80107ff6 <vector228>:
.globl vector228
vector228:
  pushl $0
80107ff6:	6a 00                	push   $0x0
  pushl $228
80107ff8:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80107ffd:	e9 42 f0 ff ff       	jmp    80107044 <alltraps>

80108002 <vector229>:
.globl vector229
vector229:
  pushl $0
80108002:	6a 00                	push   $0x0
  pushl $229
80108004:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80108009:	e9 36 f0 ff ff       	jmp    80107044 <alltraps>

8010800e <vector230>:
.globl vector230
vector230:
  pushl $0
8010800e:	6a 00                	push   $0x0
  pushl $230
80108010:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80108015:	e9 2a f0 ff ff       	jmp    80107044 <alltraps>

8010801a <vector231>:
.globl vector231
vector231:
  pushl $0
8010801a:	6a 00                	push   $0x0
  pushl $231
8010801c:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80108021:	e9 1e f0 ff ff       	jmp    80107044 <alltraps>

80108026 <vector232>:
.globl vector232
vector232:
  pushl $0
80108026:	6a 00                	push   $0x0
  pushl $232
80108028:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
8010802d:	e9 12 f0 ff ff       	jmp    80107044 <alltraps>

80108032 <vector233>:
.globl vector233
vector233:
  pushl $0
80108032:	6a 00                	push   $0x0
  pushl $233
80108034:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80108039:	e9 06 f0 ff ff       	jmp    80107044 <alltraps>

8010803e <vector234>:
.globl vector234
vector234:
  pushl $0
8010803e:	6a 00                	push   $0x0
  pushl $234
80108040:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80108045:	e9 fa ef ff ff       	jmp    80107044 <alltraps>

8010804a <vector235>:
.globl vector235
vector235:
  pushl $0
8010804a:	6a 00                	push   $0x0
  pushl $235
8010804c:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80108051:	e9 ee ef ff ff       	jmp    80107044 <alltraps>

80108056 <vector236>:
.globl vector236
vector236:
  pushl $0
80108056:	6a 00                	push   $0x0
  pushl $236
80108058:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
8010805d:	e9 e2 ef ff ff       	jmp    80107044 <alltraps>

80108062 <vector237>:
.globl vector237
vector237:
  pushl $0
80108062:	6a 00                	push   $0x0
  pushl $237
80108064:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80108069:	e9 d6 ef ff ff       	jmp    80107044 <alltraps>

8010806e <vector238>:
.globl vector238
vector238:
  pushl $0
8010806e:	6a 00                	push   $0x0
  pushl $238
80108070:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80108075:	e9 ca ef ff ff       	jmp    80107044 <alltraps>

8010807a <vector239>:
.globl vector239
vector239:
  pushl $0
8010807a:	6a 00                	push   $0x0
  pushl $239
8010807c:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80108081:	e9 be ef ff ff       	jmp    80107044 <alltraps>

80108086 <vector240>:
.globl vector240
vector240:
  pushl $0
80108086:	6a 00                	push   $0x0
  pushl $240
80108088:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
8010808d:	e9 b2 ef ff ff       	jmp    80107044 <alltraps>

80108092 <vector241>:
.globl vector241
vector241:
  pushl $0
80108092:	6a 00                	push   $0x0
  pushl $241
80108094:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80108099:	e9 a6 ef ff ff       	jmp    80107044 <alltraps>

8010809e <vector242>:
.globl vector242
vector242:
  pushl $0
8010809e:	6a 00                	push   $0x0
  pushl $242
801080a0:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
801080a5:	e9 9a ef ff ff       	jmp    80107044 <alltraps>

801080aa <vector243>:
.globl vector243
vector243:
  pushl $0
801080aa:	6a 00                	push   $0x0
  pushl $243
801080ac:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
801080b1:	e9 8e ef ff ff       	jmp    80107044 <alltraps>

801080b6 <vector244>:
.globl vector244
vector244:
  pushl $0
801080b6:	6a 00                	push   $0x0
  pushl $244
801080b8:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
801080bd:	e9 82 ef ff ff       	jmp    80107044 <alltraps>

801080c2 <vector245>:
.globl vector245
vector245:
  pushl $0
801080c2:	6a 00                	push   $0x0
  pushl $245
801080c4:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
801080c9:	e9 76 ef ff ff       	jmp    80107044 <alltraps>

801080ce <vector246>:
.globl vector246
vector246:
  pushl $0
801080ce:	6a 00                	push   $0x0
  pushl $246
801080d0:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
801080d5:	e9 6a ef ff ff       	jmp    80107044 <alltraps>

801080da <vector247>:
.globl vector247
vector247:
  pushl $0
801080da:	6a 00                	push   $0x0
  pushl $247
801080dc:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
801080e1:	e9 5e ef ff ff       	jmp    80107044 <alltraps>

801080e6 <vector248>:
.globl vector248
vector248:
  pushl $0
801080e6:	6a 00                	push   $0x0
  pushl $248
801080e8:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
801080ed:	e9 52 ef ff ff       	jmp    80107044 <alltraps>

801080f2 <vector249>:
.globl vector249
vector249:
  pushl $0
801080f2:	6a 00                	push   $0x0
  pushl $249
801080f4:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
801080f9:	e9 46 ef ff ff       	jmp    80107044 <alltraps>

801080fe <vector250>:
.globl vector250
vector250:
  pushl $0
801080fe:	6a 00                	push   $0x0
  pushl $250
80108100:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80108105:	e9 3a ef ff ff       	jmp    80107044 <alltraps>

8010810a <vector251>:
.globl vector251
vector251:
  pushl $0
8010810a:	6a 00                	push   $0x0
  pushl $251
8010810c:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80108111:	e9 2e ef ff ff       	jmp    80107044 <alltraps>

80108116 <vector252>:
.globl vector252
vector252:
  pushl $0
80108116:	6a 00                	push   $0x0
  pushl $252
80108118:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
8010811d:	e9 22 ef ff ff       	jmp    80107044 <alltraps>

80108122 <vector253>:
.globl vector253
vector253:
  pushl $0
80108122:	6a 00                	push   $0x0
  pushl $253
80108124:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80108129:	e9 16 ef ff ff       	jmp    80107044 <alltraps>

8010812e <vector254>:
.globl vector254
vector254:
  pushl $0
8010812e:	6a 00                	push   $0x0
  pushl $254
80108130:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80108135:	e9 0a ef ff ff       	jmp    80107044 <alltraps>

8010813a <vector255>:
.globl vector255
vector255:
  pushl $0
8010813a:	6a 00                	push   $0x0
  pushl $255
8010813c:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80108141:	e9 fe ee ff ff       	jmp    80107044 <alltraps>
	...

80108148 <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
80108148:	55                   	push   %ebp
80108149:	89 e5                	mov    %esp,%ebp
8010814b:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
8010814e:	8b 45 0c             	mov    0xc(%ebp),%eax
80108151:	83 e8 01             	sub    $0x1,%eax
80108154:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80108158:	8b 45 08             	mov    0x8(%ebp),%eax
8010815b:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
8010815f:	8b 45 08             	mov    0x8(%ebp),%eax
80108162:	c1 e8 10             	shr    $0x10,%eax
80108165:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
80108169:	8d 45 fa             	lea    -0x6(%ebp),%eax
8010816c:	0f 01 10             	lgdtl  (%eax)
}
8010816f:	c9                   	leave  
80108170:	c3                   	ret    

80108171 <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
80108171:	55                   	push   %ebp
80108172:	89 e5                	mov    %esp,%ebp
80108174:	83 ec 04             	sub    $0x4,%esp
80108177:	8b 45 08             	mov    0x8(%ebp),%eax
8010817a:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
8010817e:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80108182:	0f 00 d8             	ltr    %ax
}
80108185:	c9                   	leave  
80108186:	c3                   	ret    

80108187 <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
80108187:	55                   	push   %ebp
80108188:	89 e5                	mov    %esp,%ebp
8010818a:	83 ec 04             	sub    $0x4,%esp
8010818d:	8b 45 08             	mov    0x8(%ebp),%eax
80108190:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
80108194:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80108198:	8e e8                	mov    %eax,%gs
}
8010819a:	c9                   	leave  
8010819b:	c3                   	ret    

8010819c <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
8010819c:	55                   	push   %ebp
8010819d:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
8010819f:	8b 45 08             	mov    0x8(%ebp),%eax
801081a2:	0f 22 d8             	mov    %eax,%cr3
}
801081a5:	5d                   	pop    %ebp
801081a6:	c3                   	ret    

801081a7 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
801081a7:	55                   	push   %ebp
801081a8:	89 e5                	mov    %esp,%ebp
801081aa:	8b 45 08             	mov    0x8(%ebp),%eax
801081ad:	05 00 00 00 80       	add    $0x80000000,%eax
801081b2:	5d                   	pop    %ebp
801081b3:	c3                   	ret    

801081b4 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
801081b4:	55                   	push   %ebp
801081b5:	89 e5                	mov    %esp,%ebp
801081b7:	8b 45 08             	mov    0x8(%ebp),%eax
801081ba:	05 00 00 00 80       	add    $0x80000000,%eax
801081bf:	5d                   	pop    %ebp
801081c0:	c3                   	ret    

801081c1 <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
801081c1:	55                   	push   %ebp
801081c2:	89 e5                	mov    %esp,%ebp
801081c4:	53                   	push   %ebx
801081c5:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
801081c8:	e8 0c af ff ff       	call   801030d9 <cpunum>
801081cd:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801081d3:	05 80 29 11 80       	add    $0x80112980,%eax
801081d8:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
801081db:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081de:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
801081e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081e7:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
801081ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081f0:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
801081f4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081f7:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801081fb:	83 e2 f0             	and    $0xfffffff0,%edx
801081fe:	83 ca 0a             	or     $0xa,%edx
80108201:	88 50 7d             	mov    %dl,0x7d(%eax)
80108204:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108207:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
8010820b:	83 ca 10             	or     $0x10,%edx
8010820e:	88 50 7d             	mov    %dl,0x7d(%eax)
80108211:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108214:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108218:	83 e2 9f             	and    $0xffffff9f,%edx
8010821b:	88 50 7d             	mov    %dl,0x7d(%eax)
8010821e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108221:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108225:	83 ca 80             	or     $0xffffff80,%edx
80108228:	88 50 7d             	mov    %dl,0x7d(%eax)
8010822b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010822e:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108232:	83 ca 0f             	or     $0xf,%edx
80108235:	88 50 7e             	mov    %dl,0x7e(%eax)
80108238:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010823b:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010823f:	83 e2 ef             	and    $0xffffffef,%edx
80108242:	88 50 7e             	mov    %dl,0x7e(%eax)
80108245:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108248:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010824c:	83 e2 df             	and    $0xffffffdf,%edx
8010824f:	88 50 7e             	mov    %dl,0x7e(%eax)
80108252:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108255:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108259:	83 ca 40             	or     $0x40,%edx
8010825c:	88 50 7e             	mov    %dl,0x7e(%eax)
8010825f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108262:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108266:	83 ca 80             	or     $0xffffff80,%edx
80108269:	88 50 7e             	mov    %dl,0x7e(%eax)
8010826c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010826f:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80108273:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108276:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
8010827d:	ff ff 
8010827f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108282:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
80108289:	00 00 
8010828b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010828e:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
80108295:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108298:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
8010829f:	83 e2 f0             	and    $0xfffffff0,%edx
801082a2:	83 ca 02             	or     $0x2,%edx
801082a5:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801082ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082ae:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801082b5:	83 ca 10             	or     $0x10,%edx
801082b8:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801082be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082c1:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801082c8:	83 e2 9f             	and    $0xffffff9f,%edx
801082cb:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801082d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082d4:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801082db:	83 ca 80             	or     $0xffffff80,%edx
801082de:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801082e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082e7:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801082ee:	83 ca 0f             	or     $0xf,%edx
801082f1:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801082f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082fa:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108301:	83 e2 ef             	and    $0xffffffef,%edx
80108304:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
8010830a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010830d:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108314:	83 e2 df             	and    $0xffffffdf,%edx
80108317:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
8010831d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108320:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108327:	83 ca 40             	or     $0x40,%edx
8010832a:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108330:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108333:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010833a:	83 ca 80             	or     $0xffffff80,%edx
8010833d:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108343:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108346:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
8010834d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108350:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
80108357:	ff ff 
80108359:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010835c:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
80108363:	00 00 
80108365:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108368:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
8010836f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108372:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80108379:	83 e2 f0             	and    $0xfffffff0,%edx
8010837c:	83 ca 0a             	or     $0xa,%edx
8010837f:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80108385:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108388:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
8010838f:	83 ca 10             	or     $0x10,%edx
80108392:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80108398:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010839b:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801083a2:	83 ca 60             	or     $0x60,%edx
801083a5:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801083ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083ae:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801083b5:	83 ca 80             	or     $0xffffff80,%edx
801083b8:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801083be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083c1:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801083c8:	83 ca 0f             	or     $0xf,%edx
801083cb:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801083d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083d4:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801083db:	83 e2 ef             	and    $0xffffffef,%edx
801083de:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801083e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083e7:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801083ee:	83 e2 df             	and    $0xffffffdf,%edx
801083f1:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801083f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083fa:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108401:	83 ca 40             	or     $0x40,%edx
80108404:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
8010840a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010840d:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108414:	83 ca 80             	or     $0xffffff80,%edx
80108417:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
8010841d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108420:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80108427:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010842a:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
80108431:	ff ff 
80108433:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108436:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
8010843d:	00 00 
8010843f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108442:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
80108449:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010844c:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108453:	83 e2 f0             	and    $0xfffffff0,%edx
80108456:	83 ca 02             	or     $0x2,%edx
80108459:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
8010845f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108462:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108469:	83 ca 10             	or     $0x10,%edx
8010846c:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108472:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108475:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
8010847c:	83 ca 60             	or     $0x60,%edx
8010847f:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108485:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108488:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
8010848f:	83 ca 80             	or     $0xffffff80,%edx
80108492:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108498:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010849b:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801084a2:	83 ca 0f             	or     $0xf,%edx
801084a5:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801084ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084ae:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801084b5:	83 e2 ef             	and    $0xffffffef,%edx
801084b8:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801084be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084c1:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801084c8:	83 e2 df             	and    $0xffffffdf,%edx
801084cb:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801084d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084d4:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801084db:	83 ca 40             	or     $0x40,%edx
801084de:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801084e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084e7:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801084ee:	83 ca 80             	or     $0xffffff80,%edx
801084f1:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801084f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084fa:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
80108501:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108504:	05 b4 00 00 00       	add    $0xb4,%eax
80108509:	89 c3                	mov    %eax,%ebx
8010850b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010850e:	05 b4 00 00 00       	add    $0xb4,%eax
80108513:	c1 e8 10             	shr    $0x10,%eax
80108516:	89 c1                	mov    %eax,%ecx
80108518:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010851b:	05 b4 00 00 00       	add    $0xb4,%eax
80108520:	c1 e8 18             	shr    $0x18,%eax
80108523:	89 c2                	mov    %eax,%edx
80108525:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108528:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
8010852f:	00 00 
80108531:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108534:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
8010853b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010853e:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
80108544:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108547:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
8010854e:	83 e1 f0             	and    $0xfffffff0,%ecx
80108551:	83 c9 02             	or     $0x2,%ecx
80108554:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
8010855a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010855d:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108564:	83 c9 10             	or     $0x10,%ecx
80108567:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
8010856d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108570:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108577:	83 e1 9f             	and    $0xffffff9f,%ecx
8010857a:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108580:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108583:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
8010858a:	83 c9 80             	or     $0xffffff80,%ecx
8010858d:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108593:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108596:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
8010859d:	83 e1 f0             	and    $0xfffffff0,%ecx
801085a0:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801085a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085a9:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801085b0:	83 e1 ef             	and    $0xffffffef,%ecx
801085b3:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801085b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085bc:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801085c3:	83 e1 df             	and    $0xffffffdf,%ecx
801085c6:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801085cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085cf:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801085d6:	83 c9 40             	or     $0x40,%ecx
801085d9:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801085df:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085e2:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801085e9:	83 c9 80             	or     $0xffffff80,%ecx
801085ec:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801085f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085f5:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
801085fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085fe:	83 c0 70             	add    $0x70,%eax
80108601:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
80108608:	00 
80108609:	89 04 24             	mov    %eax,(%esp)
8010860c:	e8 37 fb ff ff       	call   80108148 <lgdt>
  loadgs(SEG_KCPU << 3);
80108611:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
80108618:	e8 6a fb ff ff       	call   80108187 <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
8010861d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108620:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
80108626:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
8010862d:	00 00 00 00 
}
80108631:	83 c4 24             	add    $0x24,%esp
80108634:	5b                   	pop    %ebx
80108635:	5d                   	pop    %ebp
80108636:	c3                   	ret    

80108637 <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80108637:	55                   	push   %ebp
80108638:	89 e5                	mov    %esp,%ebp
8010863a:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
8010863d:	8b 45 0c             	mov    0xc(%ebp),%eax
80108640:	c1 e8 16             	shr    $0x16,%eax
80108643:	c1 e0 02             	shl    $0x2,%eax
80108646:	03 45 08             	add    0x8(%ebp),%eax
80108649:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
8010864c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010864f:	8b 00                	mov    (%eax),%eax
80108651:	83 e0 01             	and    $0x1,%eax
80108654:	84 c0                	test   %al,%al
80108656:	74 17                	je     8010866f <walkpgdir+0x38>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
80108658:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010865b:	8b 00                	mov    (%eax),%eax
8010865d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108662:	89 04 24             	mov    %eax,(%esp)
80108665:	e8 4a fb ff ff       	call   801081b4 <p2v>
8010866a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010866d:	eb 4b                	jmp    801086ba <walkpgdir+0x83>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
8010866f:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80108673:	74 0e                	je     80108683 <walkpgdir+0x4c>
80108675:	e8 89 a4 ff ff       	call   80102b03 <kalloc>
8010867a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010867d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80108681:	75 07                	jne    8010868a <walkpgdir+0x53>
      return 0;
80108683:	b8 00 00 00 00       	mov    $0x0,%eax
80108688:	eb 41                	jmp    801086cb <walkpgdir+0x94>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
8010868a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108691:	00 
80108692:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108699:	00 
8010869a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010869d:	89 04 24             	mov    %eax,(%esp)
801086a0:	e8 ed d0 ff ff       	call   80105792 <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
801086a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086a8:	89 04 24             	mov    %eax,(%esp)
801086ab:	e8 f7 fa ff ff       	call   801081a7 <v2p>
801086b0:	89 c2                	mov    %eax,%edx
801086b2:	83 ca 07             	or     $0x7,%edx
801086b5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801086b8:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
801086ba:	8b 45 0c             	mov    0xc(%ebp),%eax
801086bd:	c1 e8 0c             	shr    $0xc,%eax
801086c0:	25 ff 03 00 00       	and    $0x3ff,%eax
801086c5:	c1 e0 02             	shl    $0x2,%eax
801086c8:	03 45 f4             	add    -0xc(%ebp),%eax
}
801086cb:	c9                   	leave  
801086cc:	c3                   	ret    

801086cd <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
801086cd:	55                   	push   %ebp
801086ce:	89 e5                	mov    %esp,%ebp
801086d0:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
801086d3:	8b 45 0c             	mov    0xc(%ebp),%eax
801086d6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801086db:	89 45 f4             	mov    %eax,-0xc(%ebp)
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
801086de:	8b 45 0c             	mov    0xc(%ebp),%eax
801086e1:	03 45 10             	add    0x10(%ebp),%eax
801086e4:	83 e8 01             	sub    $0x1,%eax
801086e7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801086ec:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
801086ef:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
801086f6:	00 
801086f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086fa:	89 44 24 04          	mov    %eax,0x4(%esp)
801086fe:	8b 45 08             	mov    0x8(%ebp),%eax
80108701:	89 04 24             	mov    %eax,(%esp)
80108704:	e8 2e ff ff ff       	call   80108637 <walkpgdir>
80108709:	89 45 ec             	mov    %eax,-0x14(%ebp)
8010870c:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108710:	75 07                	jne    80108719 <mappages+0x4c>
      return -1;
80108712:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108717:	eb 46                	jmp    8010875f <mappages+0x92>
    if(*pte & PTE_P)
80108719:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010871c:	8b 00                	mov    (%eax),%eax
8010871e:	83 e0 01             	and    $0x1,%eax
80108721:	84 c0                	test   %al,%al
80108723:	74 0c                	je     80108731 <mappages+0x64>
      panic("remap");
80108725:	c7 04 24 e8 95 10 80 	movl   $0x801095e8,(%esp)
8010872c:	e8 0c 7e ff ff       	call   8010053d <panic>
    *pte = pa | perm | PTE_P;
80108731:	8b 45 18             	mov    0x18(%ebp),%eax
80108734:	0b 45 14             	or     0x14(%ebp),%eax
80108737:	89 c2                	mov    %eax,%edx
80108739:	83 ca 01             	or     $0x1,%edx
8010873c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010873f:	89 10                	mov    %edx,(%eax)
    if(a == last)
80108741:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108744:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80108747:	74 10                	je     80108759 <mappages+0x8c>
      break;
    a += PGSIZE;
80108749:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
80108750:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
80108757:	eb 96                	jmp    801086ef <mappages+0x22>
      return -1;
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
80108759:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
8010875a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010875f:	c9                   	leave  
80108760:	c3                   	ret    

80108761 <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm()
{
80108761:	55                   	push   %ebp
80108762:	89 e5                	mov    %esp,%ebp
80108764:	53                   	push   %ebx
80108765:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
80108768:	e8 96 a3 ff ff       	call   80102b03 <kalloc>
8010876d:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108770:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108774:	75 0a                	jne    80108780 <setupkvm+0x1f>
    return 0;
80108776:	b8 00 00 00 00       	mov    $0x0,%eax
8010877b:	e9 98 00 00 00       	jmp    80108818 <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
80108780:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108787:	00 
80108788:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010878f:	00 
80108790:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108793:	89 04 24             	mov    %eax,(%esp)
80108796:	e8 f7 cf ff ff       	call   80105792 <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
8010879b:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
801087a2:	e8 0d fa ff ff       	call   801081b4 <p2v>
801087a7:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
801087ac:	76 0c                	jbe    801087ba <setupkvm+0x59>
    panic("PHYSTOP too high");
801087ae:	c7 04 24 ee 95 10 80 	movl   $0x801095ee,(%esp)
801087b5:	e8 83 7d ff ff       	call   8010053d <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
801087ba:	c7 45 f4 c0 c4 10 80 	movl   $0x8010c4c0,-0xc(%ebp)
801087c1:	eb 49                	jmp    8010880c <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
801087c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
801087c6:	8b 48 0c             	mov    0xc(%eax),%ecx
                (uint)k->phys_start, k->perm) < 0)
801087c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
801087cc:	8b 50 04             	mov    0x4(%eax),%edx
801087cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087d2:	8b 58 08             	mov    0x8(%eax),%ebx
801087d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087d8:	8b 40 04             	mov    0x4(%eax),%eax
801087db:	29 c3                	sub    %eax,%ebx
801087dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087e0:	8b 00                	mov    (%eax),%eax
801087e2:	89 4c 24 10          	mov    %ecx,0x10(%esp)
801087e6:	89 54 24 0c          	mov    %edx,0xc(%esp)
801087ea:	89 5c 24 08          	mov    %ebx,0x8(%esp)
801087ee:	89 44 24 04          	mov    %eax,0x4(%esp)
801087f2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801087f5:	89 04 24             	mov    %eax,(%esp)
801087f8:	e8 d0 fe ff ff       	call   801086cd <mappages>
801087fd:	85 c0                	test   %eax,%eax
801087ff:	79 07                	jns    80108808 <setupkvm+0xa7>
                (uint)k->phys_start, k->perm) < 0)
      return 0;
80108801:	b8 00 00 00 00       	mov    $0x0,%eax
80108806:	eb 10                	jmp    80108818 <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80108808:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
8010880c:	81 7d f4 00 c5 10 80 	cmpl   $0x8010c500,-0xc(%ebp)
80108813:	72 ae                	jb     801087c3 <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
      return 0;
  return pgdir;
80108815:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80108818:	83 c4 34             	add    $0x34,%esp
8010881b:	5b                   	pop    %ebx
8010881c:	5d                   	pop    %ebp
8010881d:	c3                   	ret    

8010881e <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
void
kvmalloc(void)
{
8010881e:	55                   	push   %ebp
8010881f:	89 e5                	mov    %esp,%ebp
80108821:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80108824:	e8 38 ff ff ff       	call   80108761 <setupkvm>
80108829:	a3 58 5b 11 80       	mov    %eax,0x80115b58
  switchkvm();
8010882e:	e8 02 00 00 00       	call   80108835 <switchkvm>
}
80108833:	c9                   	leave  
80108834:	c3                   	ret    

80108835 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80108835:	55                   	push   %ebp
80108836:	89 e5                	mov    %esp,%ebp
80108838:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
8010883b:	a1 58 5b 11 80       	mov    0x80115b58,%eax
80108840:	89 04 24             	mov    %eax,(%esp)
80108843:	e8 5f f9 ff ff       	call   801081a7 <v2p>
80108848:	89 04 24             	mov    %eax,(%esp)
8010884b:	e8 4c f9 ff ff       	call   8010819c <lcr3>
}
80108850:	c9                   	leave  
80108851:	c3                   	ret    

80108852 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80108852:	55                   	push   %ebp
80108853:	89 e5                	mov    %esp,%ebp
80108855:	53                   	push   %ebx
80108856:	83 ec 14             	sub    $0x14,%esp
  pushcli();
80108859:	e8 2e ce ff ff       	call   8010568c <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
8010885e:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108864:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
8010886b:	83 c2 08             	add    $0x8,%edx
8010886e:	89 d3                	mov    %edx,%ebx
80108870:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108877:	83 c2 08             	add    $0x8,%edx
8010887a:	c1 ea 10             	shr    $0x10,%edx
8010887d:	89 d1                	mov    %edx,%ecx
8010887f:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108886:	83 c2 08             	add    $0x8,%edx
80108889:	c1 ea 18             	shr    $0x18,%edx
8010888c:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
80108893:	67 00 
80108895:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
8010889c:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
801088a2:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
801088a9:	83 e1 f0             	and    $0xfffffff0,%ecx
801088ac:	83 c9 09             	or     $0x9,%ecx
801088af:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
801088b5:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
801088bc:	83 c9 10             	or     $0x10,%ecx
801088bf:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
801088c5:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
801088cc:	83 e1 9f             	and    $0xffffff9f,%ecx
801088cf:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
801088d5:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
801088dc:	83 c9 80             	or     $0xffffff80,%ecx
801088df:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
801088e5:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
801088ec:	83 e1 f0             	and    $0xfffffff0,%ecx
801088ef:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
801088f5:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
801088fc:	83 e1 ef             	and    $0xffffffef,%ecx
801088ff:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108905:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
8010890c:	83 e1 df             	and    $0xffffffdf,%ecx
8010890f:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108915:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
8010891c:	83 c9 40             	or     $0x40,%ecx
8010891f:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108925:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
8010892c:	83 e1 7f             	and    $0x7f,%ecx
8010892f:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108935:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
8010893b:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108941:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
80108948:	83 e2 ef             	and    $0xffffffef,%edx
8010894b:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
80108951:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108957:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
8010895d:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108963:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
8010896a:	8b 52 08             	mov    0x8(%edx),%edx
8010896d:	81 c2 00 10 00 00    	add    $0x1000,%edx
80108973:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
80108976:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
8010897d:	e8 ef f7 ff ff       	call   80108171 <ltr>
  if(p->pgdir == 0)
80108982:	8b 45 08             	mov    0x8(%ebp),%eax
80108985:	8b 40 04             	mov    0x4(%eax),%eax
80108988:	85 c0                	test   %eax,%eax
8010898a:	75 0c                	jne    80108998 <switchuvm+0x146>
    panic("switchuvm: no pgdir");
8010898c:	c7 04 24 ff 95 10 80 	movl   $0x801095ff,(%esp)
80108993:	e8 a5 7b ff ff       	call   8010053d <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
80108998:	8b 45 08             	mov    0x8(%ebp),%eax
8010899b:	8b 40 04             	mov    0x4(%eax),%eax
8010899e:	89 04 24             	mov    %eax,(%esp)
801089a1:	e8 01 f8 ff ff       	call   801081a7 <v2p>
801089a6:	89 04 24             	mov    %eax,(%esp)
801089a9:	e8 ee f7 ff ff       	call   8010819c <lcr3>
  popcli();
801089ae:	e8 21 cd ff ff       	call   801056d4 <popcli>
}
801089b3:	83 c4 14             	add    $0x14,%esp
801089b6:	5b                   	pop    %ebx
801089b7:	5d                   	pop    %ebp
801089b8:	c3                   	ret    

801089b9 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
801089b9:	55                   	push   %ebp
801089ba:	89 e5                	mov    %esp,%ebp
801089bc:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
801089bf:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
801089c6:	76 0c                	jbe    801089d4 <inituvm+0x1b>
    panic("inituvm: more than a page");
801089c8:	c7 04 24 13 96 10 80 	movl   $0x80109613,(%esp)
801089cf:	e8 69 7b ff ff       	call   8010053d <panic>
  mem = kalloc();
801089d4:	e8 2a a1 ff ff       	call   80102b03 <kalloc>
801089d9:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
801089dc:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801089e3:	00 
801089e4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801089eb:	00 
801089ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089ef:	89 04 24             	mov    %eax,(%esp)
801089f2:	e8 9b cd ff ff       	call   80105792 <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
801089f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089fa:	89 04 24             	mov    %eax,(%esp)
801089fd:	e8 a5 f7 ff ff       	call   801081a7 <v2p>
80108a02:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80108a09:	00 
80108a0a:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108a0e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108a15:	00 
80108a16:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108a1d:	00 
80108a1e:	8b 45 08             	mov    0x8(%ebp),%eax
80108a21:	89 04 24             	mov    %eax,(%esp)
80108a24:	e8 a4 fc ff ff       	call   801086cd <mappages>
  memmove(mem, init, sz);
80108a29:	8b 45 10             	mov    0x10(%ebp),%eax
80108a2c:	89 44 24 08          	mov    %eax,0x8(%esp)
80108a30:	8b 45 0c             	mov    0xc(%ebp),%eax
80108a33:	89 44 24 04          	mov    %eax,0x4(%esp)
80108a37:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a3a:	89 04 24             	mov    %eax,(%esp)
80108a3d:	e8 23 ce ff ff       	call   80105865 <memmove>
}
80108a42:	c9                   	leave  
80108a43:	c3                   	ret    

80108a44 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80108a44:	55                   	push   %ebp
80108a45:	89 e5                	mov    %esp,%ebp
80108a47:	53                   	push   %ebx
80108a48:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;
  if((uint) addr % PGSIZE != 0)
80108a4b:	8b 45 0c             	mov    0xc(%ebp),%eax
80108a4e:	25 ff 0f 00 00       	and    $0xfff,%eax
80108a53:	85 c0                	test   %eax,%eax
80108a55:	74 0c                	je     80108a63 <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
80108a57:	c7 04 24 30 96 10 80 	movl   $0x80109630,(%esp)
80108a5e:	e8 da 7a ff ff       	call   8010053d <panic>
  for(i = 0; i < sz; i += PGSIZE){
80108a63:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108a6a:	e9 ad 00 00 00       	jmp    80108b1c <loaduvm+0xd8>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
80108a6f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a72:	8b 55 0c             	mov    0xc(%ebp),%edx
80108a75:	01 d0                	add    %edx,%eax
80108a77:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108a7e:	00 
80108a7f:	89 44 24 04          	mov    %eax,0x4(%esp)
80108a83:	8b 45 08             	mov    0x8(%ebp),%eax
80108a86:	89 04 24             	mov    %eax,(%esp)
80108a89:	e8 a9 fb ff ff       	call   80108637 <walkpgdir>
80108a8e:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108a91:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108a95:	75 0c                	jne    80108aa3 <loaduvm+0x5f>
      panic("loaduvm: address should exist");
80108a97:	c7 04 24 53 96 10 80 	movl   $0x80109653,(%esp)
80108a9e:	e8 9a 7a ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
80108aa3:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108aa6:	8b 00                	mov    (%eax),%eax
80108aa8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108aad:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
80108ab0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ab3:	8b 55 18             	mov    0x18(%ebp),%edx
80108ab6:	89 d1                	mov    %edx,%ecx
80108ab8:	29 c1                	sub    %eax,%ecx
80108aba:	89 c8                	mov    %ecx,%eax
80108abc:	3d ff 0f 00 00       	cmp    $0xfff,%eax
80108ac1:	77 11                	ja     80108ad4 <loaduvm+0x90>
      n = sz - i;
80108ac3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ac6:	8b 55 18             	mov    0x18(%ebp),%edx
80108ac9:	89 d1                	mov    %edx,%ecx
80108acb:	29 c1                	sub    %eax,%ecx
80108acd:	89 c8                	mov    %ecx,%eax
80108acf:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108ad2:	eb 07                	jmp    80108adb <loaduvm+0x97>
    else
      n = PGSIZE;
80108ad4:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
80108adb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ade:	8b 55 14             	mov    0x14(%ebp),%edx
80108ae1:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80108ae4:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108ae7:	89 04 24             	mov    %eax,(%esp)
80108aea:	e8 c5 f6 ff ff       	call   801081b4 <p2v>
80108aef:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108af2:	89 54 24 0c          	mov    %edx,0xc(%esp)
80108af6:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80108afa:	89 44 24 04          	mov    %eax,0x4(%esp)
80108afe:	8b 45 10             	mov    0x10(%ebp),%eax
80108b01:	89 04 24             	mov    %eax,(%esp)
80108b04:	e8 55 92 ff ff       	call   80101d5e <readi>
80108b09:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80108b0c:	74 07                	je     80108b15 <loaduvm+0xd1>
      return -1;
80108b0e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108b13:	eb 18                	jmp    80108b2d <loaduvm+0xe9>
{
  uint i, pa, n;
  pte_t *pte;
  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80108b15:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108b1c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b1f:	3b 45 18             	cmp    0x18(%ebp),%eax
80108b22:	0f 82 47 ff ff ff    	jb     80108a6f <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
80108b28:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108b2d:	83 c4 24             	add    $0x24,%esp
80108b30:	5b                   	pop    %ebx
80108b31:	5d                   	pop    %ebp
80108b32:	c3                   	ret    

80108b33 <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80108b33:	55                   	push   %ebp
80108b34:	89 e5                	mov    %esp,%ebp
80108b36:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  uint a;

  if(newsz >= KERNBASE)
80108b39:	8b 45 10             	mov    0x10(%ebp),%eax
80108b3c:	85 c0                	test   %eax,%eax
80108b3e:	79 0a                	jns    80108b4a <allocuvm+0x17>
    return 0;
80108b40:	b8 00 00 00 00       	mov    $0x0,%eax
80108b45:	e9 c1 00 00 00       	jmp    80108c0b <allocuvm+0xd8>
  if(newsz < oldsz)
80108b4a:	8b 45 10             	mov    0x10(%ebp),%eax
80108b4d:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108b50:	73 08                	jae    80108b5a <allocuvm+0x27>
    return oldsz;
80108b52:	8b 45 0c             	mov    0xc(%ebp),%eax
80108b55:	e9 b1 00 00 00       	jmp    80108c0b <allocuvm+0xd8>
  a = PGROUNDUP(oldsz);
80108b5a:	8b 45 0c             	mov    0xc(%ebp),%eax
80108b5d:	05 ff 0f 00 00       	add    $0xfff,%eax
80108b62:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108b67:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
80108b6a:	e9 8d 00 00 00       	jmp    80108bfc <allocuvm+0xc9>
    mem = kalloc();
80108b6f:	e8 8f 9f ff ff       	call   80102b03 <kalloc>
80108b74:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(mem == 0){
80108b77:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108b7b:	75 2c                	jne    80108ba9 <allocuvm+0x76>
      cprintf("allocuvm out of memory\n");
80108b7d:	c7 04 24 71 96 10 80 	movl   $0x80109671,(%esp)
80108b84:	e8 18 78 ff ff       	call   801003a1 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80108b89:	8b 45 0c             	mov    0xc(%ebp),%eax
80108b8c:	89 44 24 08          	mov    %eax,0x8(%esp)
80108b90:	8b 45 10             	mov    0x10(%ebp),%eax
80108b93:	89 44 24 04          	mov    %eax,0x4(%esp)
80108b97:	8b 45 08             	mov    0x8(%ebp),%eax
80108b9a:	89 04 24             	mov    %eax,(%esp)
80108b9d:	e8 6b 00 00 00       	call   80108c0d <deallocuvm>
      return 0;
80108ba2:	b8 00 00 00 00       	mov    $0x0,%eax
80108ba7:	eb 62                	jmp    80108c0b <allocuvm+0xd8>
    }
    memset(mem, 0, PGSIZE);
80108ba9:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108bb0:	00 
80108bb1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108bb8:	00 
80108bb9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108bbc:	89 04 24             	mov    %eax,(%esp)
80108bbf:	e8 ce cb ff ff       	call   80105792 <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
80108bc4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108bc7:	89 04 24             	mov    %eax,(%esp)
80108bca:	e8 d8 f5 ff ff       	call   801081a7 <v2p>
80108bcf:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108bd2:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80108bd9:	00 
80108bda:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108bde:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108be5:	00 
80108be6:	89 54 24 04          	mov    %edx,0x4(%esp)
80108bea:	8b 45 08             	mov    0x8(%ebp),%eax
80108bed:	89 04 24             	mov    %eax,(%esp)
80108bf0:	e8 d8 fa ff ff       	call   801086cd <mappages>
  if(newsz >= KERNBASE)
    return 0;
  if(newsz < oldsz)
    return oldsz;
  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
80108bf5:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108bfc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108bff:	3b 45 10             	cmp    0x10(%ebp),%eax
80108c02:	0f 82 67 ff ff ff    	jb     80108b6f <allocuvm+0x3c>
      return 0;
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
  }
  return newsz;
80108c08:	8b 45 10             	mov    0x10(%ebp),%eax
}
80108c0b:	c9                   	leave  
80108c0c:	c3                   	ret    

80108c0d <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80108c0d:	55                   	push   %ebp
80108c0e:	89 e5                	mov    %esp,%ebp
80108c10:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
80108c13:	8b 45 10             	mov    0x10(%ebp),%eax
80108c16:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108c19:	72 08                	jb     80108c23 <deallocuvm+0x16>
    return oldsz;
80108c1b:	8b 45 0c             	mov    0xc(%ebp),%eax
80108c1e:	e9 a4 00 00 00       	jmp    80108cc7 <deallocuvm+0xba>

  a = PGROUNDUP(newsz);
80108c23:	8b 45 10             	mov    0x10(%ebp),%eax
80108c26:	05 ff 0f 00 00       	add    $0xfff,%eax
80108c2b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108c30:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
80108c33:	e9 80 00 00 00       	jmp    80108cb8 <deallocuvm+0xab>
    pte = walkpgdir(pgdir, (char*)a, 0);
80108c38:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c3b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108c42:	00 
80108c43:	89 44 24 04          	mov    %eax,0x4(%esp)
80108c47:	8b 45 08             	mov    0x8(%ebp),%eax
80108c4a:	89 04 24             	mov    %eax,(%esp)
80108c4d:	e8 e5 f9 ff ff       	call   80108637 <walkpgdir>
80108c52:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(!pte)
80108c55:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108c59:	75 09                	jne    80108c64 <deallocuvm+0x57>
      a += (NPTENTRIES - 1) * PGSIZE;
80108c5b:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
80108c62:	eb 4d                	jmp    80108cb1 <deallocuvm+0xa4>
    else if((*pte & PTE_P) != 0){
80108c64:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108c67:	8b 00                	mov    (%eax),%eax
80108c69:	83 e0 01             	and    $0x1,%eax
80108c6c:	84 c0                	test   %al,%al
80108c6e:	74 41                	je     80108cb1 <deallocuvm+0xa4>
      pa = PTE_ADDR(*pte);
80108c70:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108c73:	8b 00                	mov    (%eax),%eax
80108c75:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108c7a:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if(pa == 0)
80108c7d:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108c81:	75 0c                	jne    80108c8f <deallocuvm+0x82>
        panic("kfree");
80108c83:	c7 04 24 89 96 10 80 	movl   $0x80109689,(%esp)
80108c8a:	e8 ae 78 ff ff       	call   8010053d <panic>
      char *v = p2v(pa);
80108c8f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108c92:	89 04 24             	mov    %eax,(%esp)
80108c95:	e8 1a f5 ff ff       	call   801081b4 <p2v>
80108c9a:	89 45 e8             	mov    %eax,-0x18(%ebp)
      kfree(v);
80108c9d:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108ca0:	89 04 24             	mov    %eax,(%esp)
80108ca3:	e8 c2 9d ff ff       	call   80102a6a <kfree>
      *pte = 0;
80108ca8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108cab:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
80108cb1:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108cb8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108cbb:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108cbe:	0f 82 74 ff ff ff    	jb     80108c38 <deallocuvm+0x2b>
      char *v = p2v(pa);
      kfree(v);
      *pte = 0;
    }
  }
  return newsz;
80108cc4:	8b 45 10             	mov    0x10(%ebp),%eax
}
80108cc7:	c9                   	leave  
80108cc8:	c3                   	ret    

80108cc9 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
80108cc9:	55                   	push   %ebp
80108cca:	89 e5                	mov    %esp,%ebp
80108ccc:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
80108ccf:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80108cd3:	75 0c                	jne    80108ce1 <freevm+0x18>
    panic("freevm: no pgdir");
80108cd5:	c7 04 24 8f 96 10 80 	movl   $0x8010968f,(%esp)
80108cdc:	e8 5c 78 ff ff       	call   8010053d <panic>
  deallocuvm(pgdir, KERNBASE, 0);
80108ce1:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108ce8:	00 
80108ce9:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
80108cf0:	80 
80108cf1:	8b 45 08             	mov    0x8(%ebp),%eax
80108cf4:	89 04 24             	mov    %eax,(%esp)
80108cf7:	e8 11 ff ff ff       	call   80108c0d <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
80108cfc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108d03:	eb 3c                	jmp    80108d41 <freevm+0x78>
    if(pgdir[i] & PTE_P){
80108d05:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d08:	c1 e0 02             	shl    $0x2,%eax
80108d0b:	03 45 08             	add    0x8(%ebp),%eax
80108d0e:	8b 00                	mov    (%eax),%eax
80108d10:	83 e0 01             	and    $0x1,%eax
80108d13:	84 c0                	test   %al,%al
80108d15:	74 26                	je     80108d3d <freevm+0x74>
      char * v = p2v(PTE_ADDR(pgdir[i]));
80108d17:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d1a:	c1 e0 02             	shl    $0x2,%eax
80108d1d:	03 45 08             	add    0x8(%ebp),%eax
80108d20:	8b 00                	mov    (%eax),%eax
80108d22:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108d27:	89 04 24             	mov    %eax,(%esp)
80108d2a:	e8 85 f4 ff ff       	call   801081b4 <p2v>
80108d2f:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
80108d32:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108d35:	89 04 24             	mov    %eax,(%esp)
80108d38:	e8 2d 9d ff ff       	call   80102a6a <kfree>
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
  for(i = 0; i < NPDENTRIES; i++){
80108d3d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80108d41:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
80108d48:	76 bb                	jbe    80108d05 <freevm+0x3c>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
80108d4a:	8b 45 08             	mov    0x8(%ebp),%eax
80108d4d:	89 04 24             	mov    %eax,(%esp)
80108d50:	e8 15 9d ff ff       	call   80102a6a <kfree>
}
80108d55:	c9                   	leave  
80108d56:	c3                   	ret    

80108d57 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80108d57:	55                   	push   %ebp
80108d58:	89 e5                	mov    %esp,%ebp
80108d5a:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80108d5d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108d64:	00 
80108d65:	8b 45 0c             	mov    0xc(%ebp),%eax
80108d68:	89 44 24 04          	mov    %eax,0x4(%esp)
80108d6c:	8b 45 08             	mov    0x8(%ebp),%eax
80108d6f:	89 04 24             	mov    %eax,(%esp)
80108d72:	e8 c0 f8 ff ff       	call   80108637 <walkpgdir>
80108d77:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
80108d7a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80108d7e:	75 0c                	jne    80108d8c <clearpteu+0x35>
    panic("clearpteu");
80108d80:	c7 04 24 a0 96 10 80 	movl   $0x801096a0,(%esp)
80108d87:	e8 b1 77 ff ff       	call   8010053d <panic>
  *pte &= ~PTE_U;
80108d8c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d8f:	8b 00                	mov    (%eax),%eax
80108d91:	89 c2                	mov    %eax,%edx
80108d93:	83 e2 fb             	and    $0xfffffffb,%edx
80108d96:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d99:	89 10                	mov    %edx,(%eax)
}
80108d9b:	c9                   	leave  
80108d9c:	c3                   	ret    

80108d9d <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
80108d9d:	55                   	push   %ebp
80108d9e:	89 e5                	mov    %esp,%ebp
80108da0:	83 ec 48             	sub    $0x48,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
80108da3:	e8 b9 f9 ff ff       	call   80108761 <setupkvm>
80108da8:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108dab:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108daf:	75 0a                	jne    80108dbb <copyuvm+0x1e>
    return 0;
80108db1:	b8 00 00 00 00       	mov    $0x0,%eax
80108db6:	e9 f1 00 00 00       	jmp    80108eac <copyuvm+0x10f>
  for(i = 0; i < sz; i += PGSIZE){
80108dbb:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108dc2:	e9 c0 00 00 00       	jmp    80108e87 <copyuvm+0xea>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
80108dc7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108dca:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108dd1:	00 
80108dd2:	89 44 24 04          	mov    %eax,0x4(%esp)
80108dd6:	8b 45 08             	mov    0x8(%ebp),%eax
80108dd9:	89 04 24             	mov    %eax,(%esp)
80108ddc:	e8 56 f8 ff ff       	call   80108637 <walkpgdir>
80108de1:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108de4:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108de8:	75 0c                	jne    80108df6 <copyuvm+0x59>
      panic("copyuvm: pte should exist");
80108dea:	c7 04 24 aa 96 10 80 	movl   $0x801096aa,(%esp)
80108df1:	e8 47 77 ff ff       	call   8010053d <panic>
    if(!(*pte & PTE_P))
80108df6:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108df9:	8b 00                	mov    (%eax),%eax
80108dfb:	83 e0 01             	and    $0x1,%eax
80108dfe:	85 c0                	test   %eax,%eax
80108e00:	75 0c                	jne    80108e0e <copyuvm+0x71>
      panic("copyuvm: page not present");
80108e02:	c7 04 24 c4 96 10 80 	movl   $0x801096c4,(%esp)
80108e09:	e8 2f 77 ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
80108e0e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108e11:	8b 00                	mov    (%eax),%eax
80108e13:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108e18:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if((mem = kalloc()) == 0)
80108e1b:	e8 e3 9c ff ff       	call   80102b03 <kalloc>
80108e20:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80108e23:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80108e27:	74 6f                	je     80108e98 <copyuvm+0xfb>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
80108e29:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108e2c:	89 04 24             	mov    %eax,(%esp)
80108e2f:	e8 80 f3 ff ff       	call   801081b4 <p2v>
80108e34:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108e3b:	00 
80108e3c:	89 44 24 04          	mov    %eax,0x4(%esp)
80108e40:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80108e43:	89 04 24             	mov    %eax,(%esp)
80108e46:	e8 1a ca ff ff       	call   80105865 <memmove>
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
80108e4b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80108e4e:	89 04 24             	mov    %eax,(%esp)
80108e51:	e8 51 f3 ff ff       	call   801081a7 <v2p>
80108e56:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108e59:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80108e60:	00 
80108e61:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108e65:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108e6c:	00 
80108e6d:	89 54 24 04          	mov    %edx,0x4(%esp)
80108e71:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108e74:	89 04 24             	mov    %eax,(%esp)
80108e77:	e8 51 f8 ff ff       	call   801086cd <mappages>
80108e7c:	85 c0                	test   %eax,%eax
80108e7e:	78 1b                	js     80108e9b <copyuvm+0xfe>
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
80108e80:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108e87:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e8a:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108e8d:	0f 82 34 ff ff ff    	jb     80108dc7 <copyuvm+0x2a>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
  }
  return d;
80108e93:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108e96:	eb 14                	jmp    80108eac <copyuvm+0x10f>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
    if((mem = kalloc()) == 0)
      goto bad;
80108e98:	90                   	nop
80108e99:	eb 01                	jmp    80108e9c <copyuvm+0xff>
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
80108e9b:	90                   	nop
  }
  return d;

bad:
  freevm(d);
80108e9c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108e9f:	89 04 24             	mov    %eax,(%esp)
80108ea2:	e8 22 fe ff ff       	call   80108cc9 <freevm>
  return 0;
80108ea7:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108eac:	c9                   	leave  
80108ead:	c3                   	ret    

80108eae <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
80108eae:	55                   	push   %ebp
80108eaf:	89 e5                	mov    %esp,%ebp
80108eb1:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80108eb4:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108ebb:	00 
80108ebc:	8b 45 0c             	mov    0xc(%ebp),%eax
80108ebf:	89 44 24 04          	mov    %eax,0x4(%esp)
80108ec3:	8b 45 08             	mov    0x8(%ebp),%eax
80108ec6:	89 04 24             	mov    %eax,(%esp)
80108ec9:	e8 69 f7 ff ff       	call   80108637 <walkpgdir>
80108ece:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
80108ed1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ed4:	8b 00                	mov    (%eax),%eax
80108ed6:	83 e0 01             	and    $0x1,%eax
80108ed9:	85 c0                	test   %eax,%eax
80108edb:	75 07                	jne    80108ee4 <uva2ka+0x36>
    return 0;
80108edd:	b8 00 00 00 00       	mov    $0x0,%eax
80108ee2:	eb 25                	jmp    80108f09 <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
80108ee4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ee7:	8b 00                	mov    (%eax),%eax
80108ee9:	83 e0 04             	and    $0x4,%eax
80108eec:	85 c0                	test   %eax,%eax
80108eee:	75 07                	jne    80108ef7 <uva2ka+0x49>
    return 0;
80108ef0:	b8 00 00 00 00       	mov    $0x0,%eax
80108ef5:	eb 12                	jmp    80108f09 <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
80108ef7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108efa:	8b 00                	mov    (%eax),%eax
80108efc:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108f01:	89 04 24             	mov    %eax,(%esp)
80108f04:	e8 ab f2 ff ff       	call   801081b4 <p2v>
}
80108f09:	c9                   	leave  
80108f0a:	c3                   	ret    

80108f0b <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
80108f0b:	55                   	push   %ebp
80108f0c:	89 e5                	mov    %esp,%ebp
80108f0e:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
80108f11:	8b 45 10             	mov    0x10(%ebp),%eax
80108f14:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
80108f17:	e9 8b 00 00 00       	jmp    80108fa7 <copyout+0x9c>
    va0 = (uint)PGROUNDDOWN(va);
80108f1c:	8b 45 0c             	mov    0xc(%ebp),%eax
80108f1f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108f24:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
80108f27:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108f2a:	89 44 24 04          	mov    %eax,0x4(%esp)
80108f2e:	8b 45 08             	mov    0x8(%ebp),%eax
80108f31:	89 04 24             	mov    %eax,(%esp)
80108f34:	e8 75 ff ff ff       	call   80108eae <uva2ka>
80108f39:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
80108f3c:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80108f40:	75 07                	jne    80108f49 <copyout+0x3e>
      return -1;
80108f42:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108f47:	eb 6d                	jmp    80108fb6 <copyout+0xab>
    n = PGSIZE - (va - va0);
80108f49:	8b 45 0c             	mov    0xc(%ebp),%eax
80108f4c:	8b 55 ec             	mov    -0x14(%ebp),%edx
80108f4f:	89 d1                	mov    %edx,%ecx
80108f51:	29 c1                	sub    %eax,%ecx
80108f53:	89 c8                	mov    %ecx,%eax
80108f55:	05 00 10 00 00       	add    $0x1000,%eax
80108f5a:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
80108f5d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108f60:	3b 45 14             	cmp    0x14(%ebp),%eax
80108f63:	76 06                	jbe    80108f6b <copyout+0x60>
      n = len;
80108f65:	8b 45 14             	mov    0x14(%ebp),%eax
80108f68:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
80108f6b:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108f6e:	8b 55 0c             	mov    0xc(%ebp),%edx
80108f71:	89 d1                	mov    %edx,%ecx
80108f73:	29 c1                	sub    %eax,%ecx
80108f75:	89 c8                	mov    %ecx,%eax
80108f77:	03 45 e8             	add    -0x18(%ebp),%eax
80108f7a:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108f7d:	89 54 24 08          	mov    %edx,0x8(%esp)
80108f81:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108f84:	89 54 24 04          	mov    %edx,0x4(%esp)
80108f88:	89 04 24             	mov    %eax,(%esp)
80108f8b:	e8 d5 c8 ff ff       	call   80105865 <memmove>
    len -= n;
80108f90:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108f93:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
80108f96:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108f99:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
80108f9c:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108f9f:	05 00 10 00 00       	add    $0x1000,%eax
80108fa4:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
80108fa7:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
80108fab:	0f 85 6b ff ff ff    	jne    80108f1c <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
80108fb1:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108fb6:	c9                   	leave  
80108fb7:	c3                   	ret    
