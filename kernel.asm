
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
80100028:	bc e0 d6 10 80       	mov    $0x8010d6e0,%esp

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $main, %eax
8010002d:	b8 43 3c 10 80       	mov    $0x80103c43,%eax
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
8010003a:	c7 44 24 04 f4 96 10 	movl   $0x801096f4,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 e0 d6 10 80 	movl   $0x8010d6e0,(%esp)
80100049:	e8 48 5b 00 00       	call   80105b96 <initlock>

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
8010004e:	c7 05 10 ec 10 80 04 	movl   $0x8010ec04,0x8010ec10
80100055:	ec 10 80 
  bcache.head.next = &bcache.head;
80100058:	c7 05 14 ec 10 80 04 	movl   $0x8010ec04,0x8010ec14
8010005f:	ec 10 80 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
80100062:	c7 45 f4 14 d7 10 80 	movl   $0x8010d714,-0xc(%ebp)
80100069:	eb 3a                	jmp    801000a5 <binit+0x71>
    b->next = bcache.head.next;
8010006b:	8b 15 14 ec 10 80    	mov    0x8010ec14,%edx
80100071:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100074:	89 50 10             	mov    %edx,0x10(%eax)
    b->prev = &bcache.head;
80100077:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010007a:	c7 40 0c 04 ec 10 80 	movl   $0x8010ec04,0xc(%eax)
    b->dev = -1;
80100081:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100084:	c7 40 04 ff ff ff ff 	movl   $0xffffffff,0x4(%eax)
    bcache.head.next->prev = b;
8010008b:	a1 14 ec 10 80       	mov    0x8010ec14,%eax
80100090:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100093:	89 50 0c             	mov    %edx,0xc(%eax)
    bcache.head.next = b;
80100096:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100099:	a3 14 ec 10 80       	mov    %eax,0x8010ec14

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
  bcache.head.next = &bcache.head;
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
8010009e:	81 45 f4 18 02 00 00 	addl   $0x218,-0xc(%ebp)
801000a5:	81 7d f4 04 ec 10 80 	cmpl   $0x8010ec04,-0xc(%ebp)
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
801000b6:	c7 04 24 e0 d6 10 80 	movl   $0x8010d6e0,(%esp)
801000bd:	e8 f5 5a 00 00       	call   80105bb7 <acquire>

 loop:
  // Is the sector already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
801000c2:	a1 14 ec 10 80       	mov    0x8010ec14,%eax
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
801000fd:	c7 04 24 e0 d6 10 80 	movl   $0x8010d6e0,(%esp)
80100104:	e8 49 5b 00 00       	call   80105c52 <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 e0 d6 10 	movl   $0x8010d6e0,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 21 56 00 00       	call   80105745 <sleep>
      goto loop;
80100124:	eb 9c                	jmp    801000c2 <bget+0x12>

  acquire(&bcache.lock);

 loop:
  // Is the sector already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
80100126:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100129:	8b 40 10             	mov    0x10(%eax),%eax
8010012c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010012f:	81 7d f4 04 ec 10 80 	cmpl   $0x8010ec04,-0xc(%ebp)
80100136:	75 94                	jne    801000cc <bget+0x1c>
      goto loop;
    }
  }

  // Not cached; recycle some non-busy and clean buffer.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100138:	a1 10 ec 10 80       	mov    0x8010ec10,%eax
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
80100175:	c7 04 24 e0 d6 10 80 	movl   $0x8010d6e0,(%esp)
8010017c:	e8 d1 5a 00 00       	call   80105c52 <release>
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
8010018f:	81 7d f4 04 ec 10 80 	cmpl   $0x8010ec04,-0xc(%ebp)
80100196:	75 aa                	jne    80100142 <bget+0x92>
      b->flags = B_BUSY;
      release(&bcache.lock);
      return b;
    }
  }
  panic("bget: no buffers");
80100198:	c7 04 24 fb 96 10 80 	movl   $0x801096fb,(%esp)
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
801001ef:	c7 04 24 0c 97 10 80 	movl   $0x8010970c,(%esp)
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
80100229:	c7 04 24 13 97 10 80 	movl   $0x80109713,(%esp)
80100230:	e8 08 03 00 00       	call   8010053d <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 e0 d6 10 80 	movl   $0x8010d6e0,(%esp)
8010023c:	e8 76 59 00 00       	call   80105bb7 <acquire>

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
8010025f:	8b 15 14 ec 10 80    	mov    0x8010ec14,%edx
80100265:	8b 45 08             	mov    0x8(%ebp),%eax
80100268:	89 50 10             	mov    %edx,0x10(%eax)
  b->prev = &bcache.head;
8010026b:	8b 45 08             	mov    0x8(%ebp),%eax
8010026e:	c7 40 0c 04 ec 10 80 	movl   $0x8010ec04,0xc(%eax)
  bcache.head.next->prev = b;
80100275:	a1 14 ec 10 80       	mov    0x8010ec14,%eax
8010027a:	8b 55 08             	mov    0x8(%ebp),%edx
8010027d:	89 50 0c             	mov    %edx,0xc(%eax)
  bcache.head.next = b;
80100280:	8b 45 08             	mov    0x8(%ebp),%eax
80100283:	a3 14 ec 10 80       	mov    %eax,0x8010ec14

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
8010029d:	e8 15 56 00 00       	call   801058b7 <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 e0 d6 10 80 	movl   $0x8010d6e0,(%esp)
801002a9:	e8 a4 59 00 00       	call   80105c52 <release>
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
801003bc:	e8 f6 57 00 00       	call   80105bb7 <acquire>

  if (fmt == 0)
801003c1:	8b 45 08             	mov    0x8(%ebp),%eax
801003c4:	85 c0                	test   %eax,%eax
801003c6:	75 0c                	jne    801003d4 <cprintf+0x33>
    panic("null fmt");
801003c8:	c7 04 24 1a 97 10 80 	movl   $0x8010971a,(%esp)
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
801004af:	c7 45 ec 23 97 10 80 	movl   $0x80109723,-0x14(%ebp)
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
80100536:	e8 17 57 00 00       	call   80105c52 <release>
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
80100562:	c7 04 24 2a 97 10 80 	movl   $0x8010972a,(%esp)
80100569:	e8 33 fe ff ff       	call   801003a1 <cprintf>
  cprintf(s);
8010056e:	8b 45 08             	mov    0x8(%ebp),%eax
80100571:	89 04 24             	mov    %eax,(%esp)
80100574:	e8 28 fe ff ff       	call   801003a1 <cprintf>
  cprintf("\n");
80100579:	c7 04 24 39 97 10 80 	movl   $0x80109739,(%esp)
80100580:	e8 1c fe ff ff       	call   801003a1 <cprintf>
  getcallerpcs(&s, pcs);
80100585:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100588:	89 44 24 04          	mov    %eax,0x4(%esp)
8010058c:	8d 45 08             	lea    0x8(%ebp),%eax
8010058f:	89 04 24             	mov    %eax,(%esp)
80100592:	e8 0a 57 00 00       	call   80105ca1 <getcallerpcs>
  for(i=0; i<10; i++)
80100597:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010059e:	eb 1b                	jmp    801005bb <panic+0x7e>
    cprintf(" %p", pcs[i]);
801005a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005a3:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005a7:	89 44 24 04          	mov    %eax,0x4(%esp)
801005ab:	c7 04 24 3b 97 10 80 	movl   $0x8010973b,(%esp)
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
801006b2:	e8 5a 58 00 00       	call   80105f11 <memmove>
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
801006e1:	e8 58 57 00 00       	call   80105e3e <memset>
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
80100776:	e8 de 75 00 00       	call   80107d59 <uartputc>
8010077b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80100782:	e8 d2 75 00 00       	call   80107d59 <uartputc>
80100787:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
8010078e:	e8 c6 75 00 00       	call   80107d59 <uartputc>
80100793:	eb 0b                	jmp    801007a0 <consputc+0x50>
  } else
    uartputc(c);
80100795:	8b 45 08             	mov    0x8(%ebp),%eax
80100798:	89 04 24             	mov    %eax,(%esp)
8010079b:	e8 b9 75 00 00       	call   80107d59 <uartputc>
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
801007b3:	c7 04 24 20 ee 10 80 	movl   $0x8010ee20,(%esp)
801007ba:	e8 f8 53 00 00       	call   80105bb7 <acquire>
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
801007ea:	e8 91 51 00 00       	call   80105980 <procdump>
      break;
801007ef:	e9 11 01 00 00       	jmp    80100905 <consoleintr+0x158>
    case C('U'):  // Kill line.
      while(input.e != input.w &&
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
801007f4:	a1 dc ee 10 80       	mov    0x8010eedc,%eax
801007f9:	83 e8 01             	sub    $0x1,%eax
801007fc:	a3 dc ee 10 80       	mov    %eax,0x8010eedc
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
80100810:	8b 15 dc ee 10 80    	mov    0x8010eedc,%edx
80100816:	a1 d8 ee 10 80       	mov    0x8010eed8,%eax
8010081b:	39 c2                	cmp    %eax,%edx
8010081d:	0f 84 db 00 00 00    	je     801008fe <consoleintr+0x151>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
80100823:	a1 dc ee 10 80       	mov    0x8010eedc,%eax
80100828:	83 e8 01             	sub    $0x1,%eax
8010082b:	83 e0 7f             	and    $0x7f,%eax
8010082e:	0f b6 80 54 ee 10 80 	movzbl -0x7fef11ac(%eax),%eax
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
8010083e:	8b 15 dc ee 10 80    	mov    0x8010eedc,%edx
80100844:	a1 d8 ee 10 80       	mov    0x8010eed8,%eax
80100849:	39 c2                	cmp    %eax,%edx
8010084b:	0f 84 b0 00 00 00    	je     80100901 <consoleintr+0x154>
        input.e--;
80100851:	a1 dc ee 10 80       	mov    0x8010eedc,%eax
80100856:	83 e8 01             	sub    $0x1,%eax
80100859:	a3 dc ee 10 80       	mov    %eax,0x8010eedc
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
80100879:	8b 15 dc ee 10 80    	mov    0x8010eedc,%edx
8010087f:	a1 d4 ee 10 80       	mov    0x8010eed4,%eax
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
801008a2:	a1 dc ee 10 80       	mov    0x8010eedc,%eax
801008a7:	89 c1                	mov    %eax,%ecx
801008a9:	83 e1 7f             	and    $0x7f,%ecx
801008ac:	8b 55 f4             	mov    -0xc(%ebp),%edx
801008af:	88 91 54 ee 10 80    	mov    %dl,-0x7fef11ac(%ecx)
801008b5:	83 c0 01             	add    $0x1,%eax
801008b8:	a3 dc ee 10 80       	mov    %eax,0x8010eedc
        consputc(c);
801008bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801008c0:	89 04 24             	mov    %eax,(%esp)
801008c3:	e8 88 fe ff ff       	call   80100750 <consputc>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
801008c8:	83 7d f4 0a          	cmpl   $0xa,-0xc(%ebp)
801008cc:	74 18                	je     801008e6 <consoleintr+0x139>
801008ce:	83 7d f4 04          	cmpl   $0x4,-0xc(%ebp)
801008d2:	74 12                	je     801008e6 <consoleintr+0x139>
801008d4:	a1 dc ee 10 80       	mov    0x8010eedc,%eax
801008d9:	8b 15 d4 ee 10 80    	mov    0x8010eed4,%edx
801008df:	83 ea 80             	sub    $0xffffff80,%edx
801008e2:	39 d0                	cmp    %edx,%eax
801008e4:	75 1e                	jne    80100904 <consoleintr+0x157>
          input.w = input.e;
801008e6:	a1 dc ee 10 80       	mov    0x8010eedc,%eax
801008eb:	a3 d8 ee 10 80       	mov    %eax,0x8010eed8
          wakeup(&input.r);
801008f0:	c7 04 24 d4 ee 10 80 	movl   $0x8010eed4,(%esp)
801008f7:	e8 bb 4f 00 00       	call   801058b7 <wakeup>
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
80100917:	c7 04 24 20 ee 10 80 	movl   $0x8010ee20,(%esp)
8010091e:	e8 2f 53 00 00       	call   80105c52 <release>
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
8010093c:	c7 04 24 20 ee 10 80 	movl   $0x8010ee20,(%esp)
80100943:	e8 6f 52 00 00       	call   80105bb7 <acquire>
  while(n > 0){
80100948:	e9 a8 00 00 00       	jmp    801009f5 <consoleread+0xd0>
    while(input.r == input.w){
      if(proc->killed){
8010094d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100953:	8b 40 24             	mov    0x24(%eax),%eax
80100956:	85 c0                	test   %eax,%eax
80100958:	74 21                	je     8010097b <consoleread+0x56>
        release(&input.lock);
8010095a:	c7 04 24 20 ee 10 80 	movl   $0x8010ee20,(%esp)
80100961:	e8 ec 52 00 00       	call   80105c52 <release>
        ilock(ip);
80100966:	8b 45 08             	mov    0x8(%ebp),%eax
80100969:	89 04 24             	mov    %eax,(%esp)
8010096c:	e8 f7 0e 00 00       	call   80101868 <ilock>
        return -1;
80100971:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100976:	e9 a9 00 00 00       	jmp    80100a24 <consoleread+0xff>
      }
      sleep(&input.r, &input.lock);
8010097b:	c7 44 24 04 20 ee 10 	movl   $0x8010ee20,0x4(%esp)
80100982:	80 
80100983:	c7 04 24 d4 ee 10 80 	movl   $0x8010eed4,(%esp)
8010098a:	e8 b6 4d 00 00       	call   80105745 <sleep>
8010098f:	eb 01                	jmp    80100992 <consoleread+0x6d>

  iunlock(ip);
  target = n;
  acquire(&input.lock);
  while(n > 0){
    while(input.r == input.w){
80100991:	90                   	nop
80100992:	8b 15 d4 ee 10 80    	mov    0x8010eed4,%edx
80100998:	a1 d8 ee 10 80       	mov    0x8010eed8,%eax
8010099d:	39 c2                	cmp    %eax,%edx
8010099f:	74 ac                	je     8010094d <consoleread+0x28>
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &input.lock);
    }
    c = input.buf[input.r++ % INPUT_BUF];
801009a1:	a1 d4 ee 10 80       	mov    0x8010eed4,%eax
801009a6:	89 c2                	mov    %eax,%edx
801009a8:	83 e2 7f             	and    $0x7f,%edx
801009ab:	0f b6 92 54 ee 10 80 	movzbl -0x7fef11ac(%edx),%edx
801009b2:	0f be d2             	movsbl %dl,%edx
801009b5:	89 55 f0             	mov    %edx,-0x10(%ebp)
801009b8:	83 c0 01             	add    $0x1,%eax
801009bb:	a3 d4 ee 10 80       	mov    %eax,0x8010eed4
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
801009ce:	a1 d4 ee 10 80       	mov    0x8010eed4,%eax
801009d3:	83 e8 01             	sub    $0x1,%eax
801009d6:	a3 d4 ee 10 80       	mov    %eax,0x8010eed4
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
80100a01:	c7 04 24 20 ee 10 80 	movl   $0x8010ee20,(%esp)
80100a08:	e8 45 52 00 00       	call   80105c52 <release>
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
80100a3e:	e8 74 51 00 00       	call   80105bb7 <acquire>
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
80100a78:	e8 d5 51 00 00       	call   80105c52 <release>
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
80100a93:	c7 44 24 04 3f 97 10 	movl   $0x8010973f,0x4(%esp)
80100a9a:	80 
80100a9b:	c7 04 24 e0 c5 10 80 	movl   $0x8010c5e0,(%esp)
80100aa2:	e8 ef 50 00 00       	call   80105b96 <initlock>
  initlock(&input.lock, "input");
80100aa7:	c7 44 24 04 47 97 10 	movl   $0x80109747,0x4(%esp)
80100aae:	80 
80100aaf:	c7 04 24 20 ee 10 80 	movl   $0x8010ee20,(%esp)
80100ab6:	e8 db 50 00 00       	call   80105b96 <initlock>

  devsw[CONSOLE].write = consolewrite;
80100abb:	c7 05 8c f8 10 80 26 	movl   $0x80100a26,0x8010f88c
80100ac2:	0a 10 80 
  devsw[CONSOLE].read = consoleread;
80100ac5:	c7 05 88 f8 10 80 25 	movl   $0x80100925,0x8010f888
80100acc:	09 10 80 
  cons.locking = 1;
80100acf:	c7 05 14 c6 10 80 01 	movl   $0x1,0x8010c614
80100ad6:	00 00 00 

  picenable(IRQ_KBD);
80100ad9:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100ae0:	e8 18 38 00 00       	call   801042fd <picenable>
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
80100b74:	c7 04 24 10 2b 10 80 	movl   $0x80102b10,(%esp)
80100b7b:	e8 1d 83 00 00       	call   80108e9d <setupkvm>
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
80100c14:	e8 56 86 00 00       	call   8010926f <allocuvm>
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
80100c51:	e8 2a 85 00 00       	call   80109180 <loaduvm>
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
80100cbc:	e8 ae 85 00 00       	call   8010926f <allocuvm>
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
80100ce0:	e8 ae 87 00 00       	call   80109493 <clearpteu>
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
80100d0f:	e8 a8 53 00 00       	call   801060bc <strlen>
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
80100d2d:	e8 8a 53 00 00       	call   801060bc <strlen>
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
80100d57:	e8 eb 88 00 00       	call   80109647 <copyout>
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
80100df7:	e8 4b 88 00 00       	call   80109647 <copyout>
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
80100e4e:	e8 1b 52 00 00       	call   8010606e <safestrcpy>

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
80100ea0:	e8 e9 80 00 00       	call   80108f8e <switchuvm>
  freevm(oldpgdir);
80100ea5:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100ea8:	89 04 24             	mov    %eax,(%esp)
80100eab:	e8 55 85 00 00       	call   80109405 <freevm>
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
80100ee2:	e8 1e 85 00 00       	call   80109405 <freevm>
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
80100f06:	c7 44 24 04 4d 97 10 	movl   $0x8010974d,0x4(%esp)
80100f0d:	80 
80100f0e:	c7 04 24 e0 ee 10 80 	movl   $0x8010eee0,(%esp)
80100f15:	e8 7c 4c 00 00       	call   80105b96 <initlock>
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
80100f22:	c7 04 24 e0 ee 10 80 	movl   $0x8010eee0,(%esp)
80100f29:	e8 89 4c 00 00       	call   80105bb7 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100f2e:	c7 45 f4 14 ef 10 80 	movl   $0x8010ef14,-0xc(%ebp)
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
80100f4b:	c7 04 24 e0 ee 10 80 	movl   $0x8010eee0,(%esp)
80100f52:	e8 fb 4c 00 00       	call   80105c52 <release>
      return f;
80100f57:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f5a:	eb 1e                	jmp    80100f7a <filealloc+0x5e>
filealloc(void)
{
  struct file *f;

  acquire(&ftable.lock);
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100f5c:	83 45 f4 18          	addl   $0x18,-0xc(%ebp)
80100f60:	81 7d f4 74 f8 10 80 	cmpl   $0x8010f874,-0xc(%ebp)
80100f67:	72 ce                	jb     80100f37 <filealloc+0x1b>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
80100f69:	c7 04 24 e0 ee 10 80 	movl   $0x8010eee0,(%esp)
80100f70:	e8 dd 4c 00 00       	call   80105c52 <release>
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
80100f82:	c7 04 24 e0 ee 10 80 	movl   $0x8010eee0,(%esp)
80100f89:	e8 29 4c 00 00       	call   80105bb7 <acquire>
  if(f->ref < 1)
80100f8e:	8b 45 08             	mov    0x8(%ebp),%eax
80100f91:	8b 40 04             	mov    0x4(%eax),%eax
80100f94:	85 c0                	test   %eax,%eax
80100f96:	7f 0c                	jg     80100fa4 <filedup+0x28>
    panic("filedup");
80100f98:	c7 04 24 54 97 10 80 	movl   $0x80109754,(%esp)
80100f9f:	e8 99 f5 ff ff       	call   8010053d <panic>
  f->ref++;
80100fa4:	8b 45 08             	mov    0x8(%ebp),%eax
80100fa7:	8b 40 04             	mov    0x4(%eax),%eax
80100faa:	8d 50 01             	lea    0x1(%eax),%edx
80100fad:	8b 45 08             	mov    0x8(%ebp),%eax
80100fb0:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
80100fb3:	c7 04 24 e0 ee 10 80 	movl   $0x8010eee0,(%esp)
80100fba:	e8 93 4c 00 00       	call   80105c52 <release>
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
80100fca:	c7 04 24 e0 ee 10 80 	movl   $0x8010eee0,(%esp)
80100fd1:	e8 e1 4b 00 00       	call   80105bb7 <acquire>
  if(f->ref < 1)
80100fd6:	8b 45 08             	mov    0x8(%ebp),%eax
80100fd9:	8b 40 04             	mov    0x4(%eax),%eax
80100fdc:	85 c0                	test   %eax,%eax
80100fde:	7f 0c                	jg     80100fec <fileclose+0x28>
    panic("fileclose");
80100fe0:	c7 04 24 5c 97 10 80 	movl   $0x8010975c,(%esp)
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
80101005:	c7 04 24 e0 ee 10 80 	movl   $0x8010eee0,(%esp)
8010100c:	e8 41 4c 00 00       	call   80105c52 <release>
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
8010104f:	c7 04 24 e0 ee 10 80 	movl   $0x8010eee0,(%esp)
80101056:	e8 f7 4b 00 00       	call   80105c52 <release>
  
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
80101074:	e8 3e 35 00 00       	call   801045b7 <pipeclose>
80101079:	eb 1d                	jmp    80101098 <fileclose+0xd4>
  else if(ff.type == FD_INODE){
8010107b:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010107e:	83 f8 02             	cmp    $0x2,%eax
80101081:	75 15                	jne    80101098 <fileclose+0xd4>
    begin_trans();
80101083:	e8 d1 29 00 00       	call   80103a59 <begin_trans>
    iput(ff.ip);
80101088:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010108b:	89 04 24             	mov    %eax,(%esp)
8010108e:	e8 88 09 00 00       	call   80101a1b <iput>
    commit_trans();
80101093:	e8 0a 2a 00 00       	call   80103aa2 <commit_trans>
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
80101125:	e8 0f 36 00 00       	call   80104739 <piperead>
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
80101197:	c7 04 24 66 97 10 80 	movl   $0x80109766,(%esp)
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
801011e2:	e8 62 34 00 00       	call   80104649 <pipewrite>
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
8010122a:	e8 2a 28 00 00       	call   80103a59 <begin_trans>
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
80101290:	e8 0d 28 00 00       	call   80103aa2 <commit_trans>

      if(r < 0)
80101295:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80101299:	78 28                	js     801012c3 <filewrite+0x11e>
        break;
      if(r != n1)
8010129b:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010129e:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801012a1:	74 0c                	je     801012af <filewrite+0x10a>
        panic("short filewrite");
801012a3:	c7 04 24 6f 97 10 80 	movl   $0x8010976f,(%esp)
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
801012d8:	c7 04 24 7f 97 10 80 	movl   $0x8010977f,(%esp)
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
80101320:	e8 ec 4b 00 00       	call   80105f11 <memmove>
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
80101366:	e8 d3 4a 00 00       	call   80105e3e <memset>
  log_write(bp);
8010136b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010136e:	89 04 24             	mov    %eax,(%esp)
80101371:	e8 84 27 00 00       	call   80103afa <log_write>
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
80101457:	e8 9e 26 00 00       	call   80103afa <log_write>
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
801014ce:	c7 04 24 89 97 10 80 	movl   $0x80109789,(%esp)
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
80101565:	c7 04 24 9f 97 10 80 	movl   $0x8010979f,(%esp)
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
8010159d:	e8 58 25 00 00       	call   80103afa <log_write>
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
801015b9:	c7 44 24 04 b2 97 10 	movl   $0x801097b2,0x4(%esp)
801015c0:	80 
801015c1:	c7 04 24 e0 f8 10 80 	movl   $0x8010f8e0,(%esp)
801015c8:	e8 c9 45 00 00       	call   80105b96 <initlock>
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
8010164a:	e8 ef 47 00 00       	call   80105e3e <memset>
      dip->type = type;
8010164f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101652:	0f b7 55 d4          	movzwl -0x2c(%ebp),%edx
80101656:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
80101659:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010165c:	89 04 24             	mov    %eax,(%esp)
8010165f:	e8 96 24 00 00       	call   80103afa <log_write>
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
801016a0:	c7 04 24 b9 97 10 80 	movl   $0x801097b9,(%esp)
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
80101747:	e8 c5 47 00 00       	call   80105f11 <memmove>
  log_write(bp);
8010174c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010174f:	89 04 24             	mov    %eax,(%esp)
80101752:	e8 a3 23 00 00       	call   80103afa <log_write>
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
8010176a:	c7 04 24 e0 f8 10 80 	movl   $0x8010f8e0,(%esp)
80101771:	e8 41 44 00 00       	call   80105bb7 <acquire>

  // Is the inode already cached?
  empty = 0;
80101776:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
8010177d:	c7 45 f4 14 f9 10 80 	movl   $0x8010f914,-0xc(%ebp)
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
801017b4:	c7 04 24 e0 f8 10 80 	movl   $0x8010f8e0,(%esp)
801017bb:	e8 92 44 00 00       	call   80105c52 <release>
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
801017df:	81 7d f4 b4 08 11 80 	cmpl   $0x801108b4,-0xc(%ebp)
801017e6:	72 9e                	jb     80101786 <iget+0x22>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
      empty = ip;
  }

  // Recycle an inode cache entry.
  if(empty == 0)
801017e8:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801017ec:	75 0c                	jne    801017fa <iget+0x96>
    panic("iget: no inodes");
801017ee:	c7 04 24 cb 97 10 80 	movl   $0x801097cb,(%esp)
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
80101825:	c7 04 24 e0 f8 10 80 	movl   $0x8010f8e0,(%esp)
8010182c:	e8 21 44 00 00       	call   80105c52 <release>

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
8010183c:	c7 04 24 e0 f8 10 80 	movl   $0x8010f8e0,(%esp)
80101843:	e8 6f 43 00 00       	call   80105bb7 <acquire>
  ip->ref++;
80101848:	8b 45 08             	mov    0x8(%ebp),%eax
8010184b:	8b 40 08             	mov    0x8(%eax),%eax
8010184e:	8d 50 01             	lea    0x1(%eax),%edx
80101851:	8b 45 08             	mov    0x8(%ebp),%eax
80101854:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101857:	c7 04 24 e0 f8 10 80 	movl   $0x8010f8e0,(%esp)
8010185e:	e8 ef 43 00 00       	call   80105c52 <release>
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
8010187e:	c7 04 24 db 97 10 80 	movl   $0x801097db,(%esp)
80101885:	e8 b3 ec ff ff       	call   8010053d <panic>

  acquire(&icache.lock);
8010188a:	c7 04 24 e0 f8 10 80 	movl   $0x8010f8e0,(%esp)
80101891:	e8 21 43 00 00       	call   80105bb7 <acquire>
  while(ip->flags & I_BUSY)
80101896:	eb 13                	jmp    801018ab <ilock+0x43>
    sleep(ip, &icache.lock);
80101898:	c7 44 24 04 e0 f8 10 	movl   $0x8010f8e0,0x4(%esp)
8010189f:	80 
801018a0:	8b 45 08             	mov    0x8(%ebp),%eax
801018a3:	89 04 24             	mov    %eax,(%esp)
801018a6:	e8 9a 3e 00 00       	call   80105745 <sleep>

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
801018c9:	c7 04 24 e0 f8 10 80 	movl   $0x8010f8e0,(%esp)
801018d0:	e8 7d 43 00 00       	call   80105c52 <release>

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
8010197b:	e8 91 45 00 00       	call   80105f11 <memmove>
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
801019a8:	c7 04 24 e1 97 10 80 	movl   $0x801097e1,(%esp)
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
801019d9:	c7 04 24 f0 97 10 80 	movl   $0x801097f0,(%esp)
801019e0:	e8 58 eb ff ff       	call   8010053d <panic>
  acquire(&icache.lock);
801019e5:	c7 04 24 e0 f8 10 80 	movl   $0x8010f8e0,(%esp)
801019ec:	e8 c6 41 00 00       	call   80105bb7 <acquire>
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
80101a08:	e8 aa 3e 00 00       	call   801058b7 <wakeup>
  release(&icache.lock);
80101a0d:	c7 04 24 e0 f8 10 80 	movl   $0x8010f8e0,(%esp)
80101a14:	e8 39 42 00 00       	call   80105c52 <release>
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
80101a21:	c7 04 24 e0 f8 10 80 	movl   $0x8010f8e0,(%esp)
80101a28:	e8 8a 41 00 00       	call   80105bb7 <acquire>
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
80101a66:	c7 04 24 f8 97 10 80 	movl   $0x801097f8,(%esp)
80101a6d:	e8 cb ea ff ff       	call   8010053d <panic>
    ip->flags |= I_BUSY;
80101a72:	8b 45 08             	mov    0x8(%ebp),%eax
80101a75:	8b 40 0c             	mov    0xc(%eax),%eax
80101a78:	89 c2                	mov    %eax,%edx
80101a7a:	83 ca 01             	or     $0x1,%edx
80101a7d:	8b 45 08             	mov    0x8(%ebp),%eax
80101a80:	89 50 0c             	mov    %edx,0xc(%eax)
    release(&icache.lock);
80101a83:	c7 04 24 e0 f8 10 80 	movl   $0x8010f8e0,(%esp)
80101a8a:	e8 c3 41 00 00       	call   80105c52 <release>
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
80101aae:	c7 04 24 e0 f8 10 80 	movl   $0x8010f8e0,(%esp)
80101ab5:	e8 fd 40 00 00       	call   80105bb7 <acquire>
    ip->flags = 0;
80101aba:	8b 45 08             	mov    0x8(%ebp),%eax
80101abd:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
80101ac4:	8b 45 08             	mov    0x8(%ebp),%eax
80101ac7:	89 04 24             	mov    %eax,(%esp)
80101aca:	e8 e8 3d 00 00       	call   801058b7 <wakeup>
  }
  ip->ref--;
80101acf:	8b 45 08             	mov    0x8(%ebp),%eax
80101ad2:	8b 40 08             	mov    0x8(%eax),%eax
80101ad5:	8d 50 ff             	lea    -0x1(%eax),%edx
80101ad8:	8b 45 08             	mov    0x8(%ebp),%eax
80101adb:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101ade:	c7 04 24 e0 f8 10 80 	movl   $0x8010f8e0,(%esp)
80101ae5:	e8 68 41 00 00       	call   80105c52 <release>
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
80101be5:	e8 10 1f 00 00       	call   80103afa <log_write>
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
80101bfa:	c7 04 24 02 98 10 80 	movl   $0x80109802,(%esp)
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
80101d93:	8b 04 c5 80 f8 10 80 	mov    -0x7fef0780(,%eax,8),%eax
80101d9a:	85 c0                	test   %eax,%eax
80101d9c:	75 0a                	jne    80101da8 <readi+0x4a>
      return -1;
80101d9e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101da3:	e9 1b 01 00 00       	jmp    80101ec3 <readi+0x165>
    return devsw[ip->major].read(ip, dst, n);
80101da8:	8b 45 08             	mov    0x8(%ebp),%eax
80101dab:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101daf:	98                   	cwtl   
80101db0:	8b 14 c5 80 f8 10 80 	mov    -0x7fef0780(,%eax,8),%edx
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
80101e92:	e8 7a 40 00 00       	call   80105f11 <memmove>
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
80101efe:	8b 04 c5 84 f8 10 80 	mov    -0x7fef077c(,%eax,8),%eax
80101f05:	85 c0                	test   %eax,%eax
80101f07:	75 0a                	jne    80101f13 <writei+0x4a>
      return -1;
80101f09:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101f0e:	e9 46 01 00 00       	jmp    80102059 <writei+0x190>
    return devsw[ip->major].write(ip, src, n);
80101f13:	8b 45 08             	mov    0x8(%ebp),%eax
80101f16:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101f1a:	98                   	cwtl   
80101f1b:	8b 14 c5 84 f8 10 80 	mov    -0x7fef077c(,%eax,8),%edx
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
80101ff8:	e8 14 3f 00 00       	call   80105f11 <memmove>
    log_write(bp);
80101ffd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102000:	89 04 24             	mov    %eax,(%esp)
80102003:	e8 f2 1a 00 00       	call   80103afa <log_write>
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
8010207a:	e8 36 3f 00 00       	call   80105fb5 <strncmp>
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
80102094:	c7 04 24 15 98 10 80 	movl   $0x80109815,(%esp)
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
801020d2:	c7 04 24 27 98 10 80 	movl   $0x80109827,(%esp)
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
801021b6:	c7 04 24 27 98 10 80 	movl   $0x80109827,(%esp)
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
801021fc:	e8 0c 3e 00 00       	call   8010600d <strncpy>
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
8010222e:	c7 04 24 34 98 10 80 	movl   $0x80109834,(%esp)
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
801022b5:	e8 57 3c 00 00       	call   80105f11 <memmove>
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
801022d0:	e8 3c 3c 00 00       	call   80105f11 <memmove>
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
80102532:	c7 44 24 04 3c 98 10 	movl   $0x8010983c,0x4(%esp)
80102539:	80 
8010253a:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
80102541:	e8 50 36 00 00       	call   80105b96 <initlock>
  picenable(IRQ_IDE);
80102546:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
8010254d:	e8 ab 1d 00 00       	call   801042fd <picenable>
  ioapicenable(IRQ_IDE, ncpu - 1);
80102552:	a1 20 77 12 80       	mov    0x80127720,%eax
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
801025de:	c7 04 24 40 98 10 80 	movl   $0x80109840,(%esp)
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
80102704:	e8 ae 34 00 00       	call   80105bb7 <acquire>
  if((b = idequeue) == 0){
80102709:	a1 54 c6 10 80       	mov    0x8010c654,%eax
8010270e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102711:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102715:	75 11                	jne    80102728 <ideintr+0x31>
    release(&idelock);
80102717:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
8010271e:	e8 2f 35 00 00       	call   80105c52 <release>
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
801027a8:	e8 a5 34 00 00       	call   80105c52 <release>
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
801027c1:	c7 04 24 49 98 10 80 	movl   $0x80109849,(%esp)
801027c8:	e8 70 dd ff ff       	call   8010053d <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
801027cd:	8b 45 08             	mov    0x8(%ebp),%eax
801027d0:	8b 00                	mov    (%eax),%eax
801027d2:	83 e0 06             	and    $0x6,%eax
801027d5:	83 f8 02             	cmp    $0x2,%eax
801027d8:	75 0c                	jne    801027e6 <iderw+0x37>
    panic("iderw: nothing to do");
801027da:	c7 04 24 5d 98 10 80 	movl   $0x8010985d,(%esp)
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
801027f9:	c7 04 24 72 98 10 80 	movl   $0x80109872,(%esp)
80102800:	e8 38 dd ff ff       	call   8010053d <panic>

  acquire(&idelock);  //DOC: acquire-lock
80102805:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
8010280c:	e8 a6 33 00 00       	call   80105bb7 <acquire>

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
8010285e:	e8 ef 33 00 00       	call   80105c52 <release>
	sti();
80102863:	e8 7a fc ff ff       	call   801024e2 <sti>
	acquire(&idelock); 
80102868:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
8010286f:	e8 43 33 00 00       	call   80105bb7 <acquire>
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
	release(&idelock);
	sti();
	acquire(&idelock); 
    }
    
    release(&idelock);
80102884:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
8010288b:	e8 c2 33 00 00       	call   80105c52 <release>
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
80102897:	a1 b4 08 11 80       	mov    0x801108b4,%eax
8010289c:	8b 55 08             	mov    0x8(%ebp),%edx
8010289f:	89 10                	mov    %edx,(%eax)
  return ioapic->data;
801028a1:	a1 b4 08 11 80       	mov    0x801108b4,%eax
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
801028ae:	a1 b4 08 11 80       	mov    0x801108b4,%eax
801028b3:	8b 55 08             	mov    0x8(%ebp),%edx
801028b6:	89 10                	mov    %edx,(%eax)
  ioapic->data = data;
801028b8:	a1 b4 08 11 80       	mov    0x801108b4,%eax
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
801028cb:	a1 24 71 12 80       	mov    0x80127124,%eax
801028d0:	85 c0                	test   %eax,%eax
801028d2:	0f 84 9f 00 00 00    	je     80102977 <ioapicinit+0xb2>
    return;

  ioapic = (volatile struct ioapic*)IOAPIC;
801028d8:	c7 05 b4 08 11 80 00 	movl   $0xfec00000,0x801108b4
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
8010290b:	0f b6 05 20 71 12 80 	movzbl 0x80127120,%eax
80102912:	0f b6 c0             	movzbl %al,%eax
80102915:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80102918:	74 0c                	je     80102926 <ioapicinit+0x61>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
8010291a:	c7 04 24 90 98 10 80 	movl   $0x80109890,(%esp)
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
80102980:	a1 24 71 12 80       	mov    0x80127124,%eax
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

801029d5 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
801029d5:	55                   	push   %ebp
801029d6:	89 e5                	mov    %esp,%ebp
801029d8:	8b 45 08             	mov    0x8(%ebp),%eax
801029db:	05 00 00 00 80       	add    $0x80000000,%eax
801029e0:	5d                   	pop    %ebp
801029e1:	c3                   	ret    

801029e2 <kinit1>:
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
801029e2:	55                   	push   %ebp
801029e3:	89 e5                	mov    %esp,%ebp
801029e5:	83 ec 18             	sub    $0x18,%esp
  initlock(&kmem.lock, "kmem");
801029e8:	c7 44 24 04 c4 98 10 	movl   $0x801098c4,0x4(%esp)
801029ef:	80 
801029f0:	c7 04 24 c0 08 11 80 	movl   $0x801108c0,(%esp)
801029f7:	e8 9a 31 00 00       	call   80105b96 <initlock>
  kmem.use_lock = 0;
801029fc:	c7 05 f4 08 11 80 00 	movl   $0x0,0x801108f4
80102a03:	00 00 00 
  freerange(vstart, vend);
80102a06:	8b 45 0c             	mov    0xc(%ebp),%eax
80102a09:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a0d:	8b 45 08             	mov    0x8(%ebp),%eax
80102a10:	89 04 24             	mov    %eax,(%esp)
80102a13:	e8 26 00 00 00       	call   80102a3e <freerange>
}
80102a18:	c9                   	leave  
80102a19:	c3                   	ret    

80102a1a <kinit2>:

void
kinit2(void *vstart, void *vend)
{
80102a1a:	55                   	push   %ebp
80102a1b:	89 e5                	mov    %esp,%ebp
80102a1d:	83 ec 18             	sub    $0x18,%esp
  freerange(vstart, vend);
80102a20:	8b 45 0c             	mov    0xc(%ebp),%eax
80102a23:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a27:	8b 45 08             	mov    0x8(%ebp),%eax
80102a2a:	89 04 24             	mov    %eax,(%esp)
80102a2d:	e8 0c 00 00 00       	call   80102a3e <freerange>
  kmem.use_lock = 1;
80102a32:	c7 05 f4 08 11 80 01 	movl   $0x1,0x801108f4
80102a39:	00 00 00 
}
80102a3c:	c9                   	leave  
80102a3d:	c3                   	ret    

80102a3e <freerange>:

void
freerange(void *vstart, void *vend)
{
80102a3e:	55                   	push   %ebp
80102a3f:	89 e5                	mov    %esp,%ebp
80102a41:	83 ec 28             	sub    $0x28,%esp
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
80102a44:	8b 45 08             	mov    0x8(%ebp),%eax
80102a47:	05 ff 0f 00 00       	add    $0xfff,%eax
80102a4c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80102a51:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102a54:	eb 12                	jmp    80102a68 <freerange+0x2a>
    kfree(p);
80102a56:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a59:	89 04 24             	mov    %eax,(%esp)
80102a5c:	e8 16 00 00 00       	call   80102a77 <kfree>
void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102a61:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80102a68:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a6b:	05 00 10 00 00       	add    $0x1000,%eax
80102a70:	3b 45 0c             	cmp    0xc(%ebp),%eax
80102a73:	76 e1                	jbe    80102a56 <freerange+0x18>
    kfree(p);
}
80102a75:	c9                   	leave  
80102a76:	c3                   	ret    

80102a77 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
80102a77:	55                   	push   %ebp
80102a78:	89 e5                	mov    %esp,%ebp
80102a7a:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if((uint)v % PGSIZE || v < end || v2p(v) >= PHYSTOP)
80102a7d:	8b 45 08             	mov    0x8(%ebp),%eax
80102a80:	25 ff 0f 00 00       	and    $0xfff,%eax
80102a85:	85 c0                	test   %eax,%eax
80102a87:	75 1b                	jne    80102aa4 <kfree+0x2d>
80102a89:	81 7d 08 1c a4 12 80 	cmpl   $0x8012a41c,0x8(%ebp)
80102a90:	72 12                	jb     80102aa4 <kfree+0x2d>
80102a92:	8b 45 08             	mov    0x8(%ebp),%eax
80102a95:	89 04 24             	mov    %eax,(%esp)
80102a98:	e8 2b ff ff ff       	call   801029c8 <v2p>
80102a9d:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80102aa2:	76 0c                	jbe    80102ab0 <kfree+0x39>
    panic("kfree");
80102aa4:	c7 04 24 c9 98 10 80 	movl   $0x801098c9,(%esp)
80102aab:	e8 8d da ff ff       	call   8010053d <panic>

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80102ab0:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80102ab7:	00 
80102ab8:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102abf:	00 
80102ac0:	8b 45 08             	mov    0x8(%ebp),%eax
80102ac3:	89 04 24             	mov    %eax,(%esp)
80102ac6:	e8 73 33 00 00       	call   80105e3e <memset>

  if(kmem.use_lock)
80102acb:	a1 f4 08 11 80       	mov    0x801108f4,%eax
80102ad0:	85 c0                	test   %eax,%eax
80102ad2:	74 0c                	je     80102ae0 <kfree+0x69>
    acquire(&kmem.lock);
80102ad4:	c7 04 24 c0 08 11 80 	movl   $0x801108c0,(%esp)
80102adb:	e8 d7 30 00 00       	call   80105bb7 <acquire>
  r = (struct run*)v;
80102ae0:	8b 45 08             	mov    0x8(%ebp),%eax
80102ae3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
80102ae6:	8b 15 f8 08 11 80    	mov    0x801108f8,%edx
80102aec:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102aef:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
80102af1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102af4:	a3 f8 08 11 80       	mov    %eax,0x801108f8
  if(kmem.use_lock)
80102af9:	a1 f4 08 11 80       	mov    0x801108f4,%eax
80102afe:	85 c0                	test   %eax,%eax
80102b00:	74 0c                	je     80102b0e <kfree+0x97>
    release(&kmem.lock);
80102b02:	c7 04 24 c0 08 11 80 	movl   $0x801108c0,(%esp)
80102b09:	e8 44 31 00 00       	call   80105c52 <release>
}
80102b0e:	c9                   	leave  
80102b0f:	c3                   	ret    

80102b10 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
80102b10:	55                   	push   %ebp
80102b11:	89 e5                	mov    %esp,%ebp
80102b13:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if(kmem.use_lock)
80102b16:	a1 f4 08 11 80       	mov    0x801108f4,%eax
80102b1b:	85 c0                	test   %eax,%eax
80102b1d:	74 0c                	je     80102b2b <kalloc+0x1b>
    acquire(&kmem.lock);
80102b1f:	c7 04 24 c0 08 11 80 	movl   $0x801108c0,(%esp)
80102b26:	e8 8c 30 00 00       	call   80105bb7 <acquire>
  r = kmem.freelist;
80102b2b:	a1 f8 08 11 80       	mov    0x801108f8,%eax
80102b30:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
80102b33:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102b37:	74 0a                	je     80102b43 <kalloc+0x33>
    kmem.freelist = r->next;
80102b39:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b3c:	8b 00                	mov    (%eax),%eax
80102b3e:	a3 f8 08 11 80       	mov    %eax,0x801108f8
  if(kmem.use_lock)
80102b43:	a1 f4 08 11 80       	mov    0x801108f4,%eax
80102b48:	85 c0                	test   %eax,%eax
80102b4a:	74 0c                	je     80102b58 <kalloc+0x48>
    release(&kmem.lock);
80102b4c:	c7 04 24 c0 08 11 80 	movl   $0x801108c0,(%esp)
80102b53:	e8 fa 30 00 00       	call   80105c52 <release>
  return (char*)r;
80102b58:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102b5b:	c9                   	leave  
80102b5c:	c3                   	ret    

80102b5d <shmget>:


int 
shmget(int key, uint size, int shmflg)
{
80102b5d:	55                   	push   %ebp
80102b5e:	89 e5                	mov    %esp,%ebp
80102b60:	83 ec 38             	sub    $0x38,%esp
  int numOfPages,i,j,ans;
  uint sz;
  if(key < 0 || key > 1023)
80102b63:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102b67:	78 09                	js     80102b72 <shmget+0x15>
80102b69:	81 7d 08 ff 03 00 00 	cmpl   $0x3ff,0x8(%ebp)
80102b70:	7e 16                	jle    80102b88 <shmget+0x2b>
  {
    cprintf("Illegal key exception, value must be between 0-1023\n");
80102b72:	c7 04 24 d0 98 10 80 	movl   $0x801098d0,(%esp)
80102b79:	e8 23 d8 ff ff       	call   801003a1 <cprintf>
    return -1;
80102b7e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102b83:	e9 77 01 00 00       	jmp    80102cff <shmget+0x1a2>
  }
  
  switch(shmflg)
80102b88:	8b 45 10             	mov    0x10(%ebp),%eax
80102b8b:	83 f8 14             	cmp    $0x14,%eax
80102b8e:	74 0e                	je     80102b9e <shmget+0x41>
80102b90:	83 f8 15             	cmp    $0x15,%eax
80102b93:	0f 84 2e 01 00 00    	je     80102cc7 <shmget+0x16a>
80102b99:	e9 5e 01 00 00       	jmp    80102cfc <shmget+0x19f>
  {
    case CREAT:
      if(shm.refs[key][1][64] == 0)
80102b9e:	8b 45 08             	mov    0x8(%ebp),%eax
80102ba1:	c1 e0 03             	shl    $0x3,%eax
80102ba4:	89 c2                	mov    %eax,%edx
80102ba6:	c1 e2 06             	shl    $0x6,%edx
80102ba9:	01 d0                	add    %edx,%eax
80102bab:	05 44 a7 11 80       	add    $0x8011a744,%eax
80102bb0:	8b 00                	mov    (%eax),%eax
80102bb2:	85 c0                	test   %eax,%eax
80102bb4:	0f 85 f8 00 00 00    	jne    80102cb2 <shmget+0x155>
      {cprintf("before for 1\n");
80102bba:	c7 04 24 05 99 10 80 	movl   $0x80109905,(%esp)
80102bc1:	e8 db d7 ff ff       	call   801003a1 <cprintf>
	sz = PGROUNDUP(size);
80102bc6:	8b 45 0c             	mov    0xc(%ebp),%eax
80102bc9:	05 ff 0f 00 00       	add    $0xfff,%eax
80102bce:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80102bd3:	89 45 e8             	mov    %eax,-0x18(%ebp)
	numOfPages = sz/PGSIZE;
80102bd6:	8b 45 e8             	mov    -0x18(%ebp),%eax
80102bd9:	c1 e8 0c             	shr    $0xc,%eax
80102bdc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(i=0;i<numOfPages;i++)
80102bdf:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102be6:	eb 2d                	jmp    80102c15 <shmget+0xb8>
	{
	  if((shm.seg[key][i] = kalloc()) == 0)
80102be8:	e8 23 ff ff ff       	call   80102b10 <kalloc>
80102bed:	8b 55 08             	mov    0x8(%ebp),%edx
80102bf0:	6b d2 64             	imul   $0x64,%edx,%edx
80102bf3:	03 55 f4             	add    -0xc(%ebp),%edx
80102bf6:	89 04 95 00 09 11 80 	mov    %eax,-0x7feef700(,%edx,4)
80102bfd:	8b 45 08             	mov    0x8(%ebp),%eax
80102c00:	6b c0 64             	imul   $0x64,%eax,%eax
80102c03:	03 45 f4             	add    -0xc(%ebp),%eax
80102c06:	8b 04 85 00 09 11 80 	mov    -0x7feef700(,%eax,4),%eax
80102c0d:	85 c0                	test   %eax,%eax
80102c0f:	74 0e                	je     80102c1f <shmget+0xc2>
    case CREAT:
      if(shm.refs[key][1][64] == 0)
      {cprintf("before for 1\n");
	sz = PGROUNDUP(size);
	numOfPages = sz/PGSIZE;
	for(i=0;i<numOfPages;i++)
80102c11:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102c15:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c18:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
80102c1b:	7c cb                	jl     80102be8 <shmget+0x8b>
80102c1d:	eb 01                	jmp    80102c20 <shmget+0xc3>
	{
	  if((shm.seg[key][i] = kalloc()) == 0)
	    break;
80102c1f:	90                   	nop
	}
	cprintf("after for 1\n");
80102c20:	c7 04 24 13 99 10 80 	movl   $0x80109913,(%esp)
80102c27:	e8 75 d7 ff ff       	call   801003a1 <cprintf>
	if(i == numOfPages)
80102c2c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c2f:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
80102c32:	75 3c                	jne    80102c70 <shmget+0x113>
	{cprintf("in if 1\n");
80102c34:	c7 04 24 20 99 10 80 	movl   $0x80109920,(%esp)
80102c3b:	e8 61 d7 ff ff       	call   801003a1 <cprintf>
	  ans = (int)shm.seg[key][0];
80102c40:	8b 45 08             	mov    0x8(%ebp),%eax
80102c43:	69 c0 90 01 00 00    	imul   $0x190,%eax,%eax
80102c49:	05 00 09 11 80       	add    $0x80110900,%eax
80102c4e:	8b 00                	mov    (%eax),%eax
80102c50:	89 45 ec             	mov    %eax,-0x14(%ebp)
	  shm.refs[key][1][64] = numOfPages;
80102c53:	8b 45 08             	mov    0x8(%ebp),%eax
80102c56:	c1 e0 03             	shl    $0x3,%eax
80102c59:	89 c2                	mov    %eax,%edx
80102c5b:	c1 e2 06             	shl    $0x6,%edx
80102c5e:	01 d0                	add    %edx,%eax
80102c60:	8d 90 44 a7 11 80    	lea    -0x7fee58bc(%eax),%edx
80102c66:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102c69:	89 02                	mov    %eax,(%edx)
      else
      {
	cprintf("in else 2\n");
	ans = -1;
      }
      break;
80102c6b:	e9 8c 00 00 00       	jmp    80102cfc <shmget+0x19f>
	{cprintf("in if 1\n");
	  ans = (int)shm.seg[key][0];
	  shm.refs[key][1][64] = numOfPages;
	}
	else
	{cprintf("in else 1\n");
80102c70:	c7 04 24 29 99 10 80 	movl   $0x80109929,(%esp)
80102c77:	e8 25 d7 ff ff       	call   801003a1 <cprintf>
	  for(j=0;j<i;j++)
80102c7c:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80102c83:	eb 1c                	jmp    80102ca1 <shmget+0x144>
	    kfree(shm.seg[key][j]);
80102c85:	8b 45 08             	mov    0x8(%ebp),%eax
80102c88:	6b c0 64             	imul   $0x64,%eax,%eax
80102c8b:	03 45 f0             	add    -0x10(%ebp),%eax
80102c8e:	8b 04 85 00 09 11 80 	mov    -0x7feef700(,%eax,4),%eax
80102c95:	89 04 24             	mov    %eax,(%esp)
80102c98:	e8 da fd ff ff       	call   80102a77 <kfree>
	  ans = (int)shm.seg[key][0];
	  shm.refs[key][1][64] = numOfPages;
	}
	else
	{cprintf("in else 1\n");
	  for(j=0;j<i;j++)
80102c9d:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80102ca1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102ca4:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80102ca7:	7c dc                	jl     80102c85 <shmget+0x128>
	    kfree(shm.seg[key][j]);
	  ans = -1;
80102ca9:	c7 45 ec ff ff ff ff 	movl   $0xffffffff,-0x14(%ebp)
      else
      {
	cprintf("in else 2\n");
	ans = -1;
      }
      break;
80102cb0:	eb 4a                	jmp    80102cfc <shmget+0x19f>
	  ans = -1;
	}
      }
      else
      {
	cprintf("in else 2\n");
80102cb2:	c7 04 24 34 99 10 80 	movl   $0x80109934,(%esp)
80102cb9:	e8 e3 d6 ff ff       	call   801003a1 <cprintf>
	ans = -1;
80102cbe:	c7 45 ec ff ff ff ff 	movl   $0xffffffff,-0x14(%ebp)
      }
      break;
80102cc5:	eb 35                	jmp    80102cfc <shmget+0x19f>
    case GET:
      if(!shm.refs[key][1][64])
80102cc7:	8b 45 08             	mov    0x8(%ebp),%eax
80102cca:	c1 e0 03             	shl    $0x3,%eax
80102ccd:	89 c2                	mov    %eax,%edx
80102ccf:	c1 e2 06             	shl    $0x6,%edx
80102cd2:	01 d0                	add    %edx,%eax
80102cd4:	05 44 a7 11 80       	add    $0x8011a744,%eax
80102cd9:	8b 00                	mov    (%eax),%eax
80102cdb:	85 c0                	test   %eax,%eax
80102cdd:	75 09                	jne    80102ce8 <shmget+0x18b>
	ans = -1;
80102cdf:	c7 45 ec ff ff ff ff 	movl   $0xffffffff,-0x14(%ebp)
      else
	ans = (int)shm.seg[key][0];
      break;
80102ce6:	eb 13                	jmp    80102cfb <shmget+0x19e>
      break;
    case GET:
      if(!shm.refs[key][1][64])
	ans = -1;
      else
	ans = (int)shm.seg[key][0];
80102ce8:	8b 45 08             	mov    0x8(%ebp),%eax
80102ceb:	69 c0 90 01 00 00    	imul   $0x190,%eax,%eax
80102cf1:	05 00 09 11 80       	add    $0x80110900,%eax
80102cf6:	8b 00                	mov    (%eax),%eax
80102cf8:	89 45 ec             	mov    %eax,-0x14(%ebp)
      break;
80102cfb:	90                   	nop
  }
  return ans;
80102cfc:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
80102cff:	c9                   	leave  
80102d00:	c3                   	ret    

80102d01 <shmdel>:

int 
shmdel(int shmid)
{
80102d01:	55                   	push   %ebp
80102d02:	89 e5                	mov    %esp,%ebp
80102d04:	83 ec 28             	sub    $0x28,%esp
  int key,ans = -1,numOfPages,i;
80102d07:	c7 45 f0 ff ff ff ff 	movl   $0xffffffff,-0x10(%ebp)
  for(key = 0;key<numOfSegs;key++)
80102d0e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102d15:	e9 b0 00 00 00       	jmp    80102dca <shmdel+0xc9>
  {
    if(shmid == (int)shm.seg[key][0])
80102d1a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d1d:	69 c0 90 01 00 00    	imul   $0x190,%eax,%eax
80102d23:	05 00 09 11 80       	add    $0x80110900,%eax
80102d28:	8b 00                	mov    (%eax),%eax
80102d2a:	3b 45 08             	cmp    0x8(%ebp),%eax
80102d2d:	0f 85 93 00 00 00    	jne    80102dc6 <shmdel+0xc5>
    {
      if(shm.refs[key][0][64]>0)
80102d33:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d36:	c1 e0 03             	shl    $0x3,%eax
80102d39:	89 c2                	mov    %eax,%edx
80102d3b:	c1 e2 06             	shl    $0x6,%edx
80102d3e:	01 d0                	add    %edx,%eax
80102d40:	05 40 a6 11 80       	add    $0x8011a640,%eax
80102d45:	8b 00                	mov    (%eax),%eax
80102d47:	85 c0                	test   %eax,%eax
80102d49:	0f 8f 87 00 00 00    	jg     80102dd6 <shmdel+0xd5>
      {
	break;
      }
      else
      {
	numOfPages=shm.refs[key][1][64];
80102d4f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d52:	c1 e0 03             	shl    $0x3,%eax
80102d55:	89 c2                	mov    %eax,%edx
80102d57:	c1 e2 06             	shl    $0x6,%edx
80102d5a:	01 d0                	add    %edx,%eax
80102d5c:	05 44 a7 11 80       	add    $0x8011a744,%eax
80102d61:	8b 00                	mov    (%eax),%eax
80102d63:	89 45 e8             	mov    %eax,-0x18(%ebp)
	for(i=0;i<numOfPages;i++)
80102d66:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80102d6d:	eb 47                	jmp    80102db6 <shmdel+0xb5>
	{
	    kfree(shm.seg[key][i]);
80102d6f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d72:	6b c0 64             	imul   $0x64,%eax,%eax
80102d75:	03 45 ec             	add    -0x14(%ebp),%eax
80102d78:	8b 04 85 00 09 11 80 	mov    -0x7feef700(,%eax,4),%eax
80102d7f:	89 04 24             	mov    %eax,(%esp)
80102d82:	e8 f0 fc ff ff       	call   80102a77 <kfree>
	    shm.refs[key][1][64]--;
80102d87:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d8a:	c1 e0 03             	shl    $0x3,%eax
80102d8d:	89 c2                	mov    %eax,%edx
80102d8f:	c1 e2 06             	shl    $0x6,%edx
80102d92:	01 d0                	add    %edx,%eax
80102d94:	05 44 a7 11 80       	add    $0x8011a744,%eax
80102d99:	8b 00                	mov    (%eax),%eax
80102d9b:	8d 50 ff             	lea    -0x1(%eax),%edx
80102d9e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102da1:	c1 e0 03             	shl    $0x3,%eax
80102da4:	89 c1                	mov    %eax,%ecx
80102da6:	c1 e1 06             	shl    $0x6,%ecx
80102da9:	01 c8                	add    %ecx,%eax
80102dab:	05 44 a7 11 80       	add    $0x8011a744,%eax
80102db0:	89 10                	mov    %edx,(%eax)
	break;
      }
      else
      {
	numOfPages=shm.refs[key][1][64];
	for(i=0;i<numOfPages;i++)
80102db2:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
80102db6:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102db9:	3b 45 e8             	cmp    -0x18(%ebp),%eax
80102dbc:	7c b1                	jl     80102d6f <shmdel+0x6e>
	{
	    kfree(shm.seg[key][i]);
	    shm.refs[key][1][64]--;
	}
      }
      ans = numOfPages;
80102dbe:	8b 45 e8             	mov    -0x18(%ebp),%eax
80102dc1:	89 45 f0             	mov    %eax,-0x10(%ebp)
      break;
80102dc4:	eb 11                	jmp    80102dd7 <shmdel+0xd6>

int 
shmdel(int shmid)
{
  int key,ans = -1,numOfPages,i;
  for(key = 0;key<numOfSegs;key++)
80102dc6:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102dca:	83 7d f4 63          	cmpl   $0x63,-0xc(%ebp)
80102dce:	0f 8e 46 ff ff ff    	jle    80102d1a <shmdel+0x19>
80102dd4:	eb 01                	jmp    80102dd7 <shmdel+0xd6>
  {
    if(shmid == (int)shm.seg[key][0])
    {
      if(shm.refs[key][0][64]>0)
      {
	break;
80102dd6:	90                   	nop
      }
      ans = numOfPages;
      break;
    }
  }  
  return ans;
80102dd7:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80102dda:	c9                   	leave  
80102ddb:	c3                   	ret    

80102ddc <shmat>:

void *
shmat(int shmid, int shmflg)
{
80102ddc:	55                   	push   %ebp
80102ddd:	89 e5                	mov    %esp,%ebp
80102ddf:	83 ec 48             	sub    $0x48,%esp
  int i,key,forFlag=0;
80102de2:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  void* ans = (void*)-1;
80102de9:	c7 45 e8 ff ff ff ff 	movl   $0xffffffff,-0x18(%ebp)
  char* mem;
  uint a;

  acquire(&shm.lock);
80102df0:	c7 04 24 60 70 12 80 	movl   $0x80127060,(%esp)
80102df7:	e8 bb 2d 00 00       	call   80105bb7 <acquire>
  for(key = 0;key<numOfSegs;key++)
80102dfc:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80102e03:	e9 ce 01 00 00       	jmp    80102fd6 <shmat+0x1fa>
  {
    if(shmid == (int)shm.seg[key][0])
80102e08:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102e0b:	69 c0 90 01 00 00    	imul   $0x190,%eax,%eax
80102e11:	05 00 09 11 80       	add    $0x80110900,%eax
80102e16:	8b 00                	mov    (%eax),%eax
80102e18:	3b 45 08             	cmp    0x8(%ebp),%eax
80102e1b:	0f 85 b1 01 00 00    	jne    80102fd2 <shmat+0x1f6>
    {
      if(shm.refs[key][1][64]>0)
80102e21:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102e24:	c1 e0 03             	shl    $0x3,%eax
80102e27:	89 c2                	mov    %eax,%edx
80102e29:	c1 e2 06             	shl    $0x6,%edx
80102e2c:	01 d0                	add    %edx,%eax
80102e2e:	05 44 a7 11 80       	add    $0x8011a744,%eax
80102e33:	8b 00                	mov    (%eax),%eax
80102e35:	85 c0                	test   %eax,%eax
80102e37:	0f 8e a5 01 00 00    	jle    80102fe2 <shmat+0x206>
      {
	a = PGROUNDUP(proc->sz);
80102e3d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80102e43:	8b 00                	mov    (%eax),%eax
80102e45:	05 ff 0f 00 00       	add    $0xfff,%eax
80102e4a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80102e4f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ans = (void*)a;
80102e52:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102e55:	89 45 e8             	mov    %eax,-0x18(%ebp)
	if(a + PGSIZE >= KERNBASE)
80102e58:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102e5b:	05 00 10 00 00       	add    $0x1000,%eax
80102e60:	85 c0                	test   %eax,%eax
80102e62:	79 0c                	jns    80102e70 <shmat+0x94>
	{
	  ans = (void*)-1;
80102e64:	c7 45 e8 ff ff ff ff 	movl   $0xffffffff,-0x18(%ebp)
	  break;
80102e6b:	e9 73 01 00 00       	jmp    80102fe3 <shmat+0x207>
	}
	
	shm.refs[key][0][64]++;
80102e70:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102e73:	c1 e0 03             	shl    $0x3,%eax
80102e76:	89 c2                	mov    %eax,%edx
80102e78:	c1 e2 06             	shl    $0x6,%edx
80102e7b:	01 d0                	add    %edx,%eax
80102e7d:	05 40 a6 11 80       	add    $0x8011a640,%eax
80102e82:	8b 00                	mov    (%eax),%eax
80102e84:	8d 50 01             	lea    0x1(%eax),%edx
80102e87:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102e8a:	c1 e0 03             	shl    $0x3,%eax
80102e8d:	89 c1                	mov    %eax,%ecx
80102e8f:	c1 e1 06             	shl    $0x6,%ecx
80102e92:	01 c8                	add    %ecx,%eax
80102e94:	05 40 a6 11 80       	add    $0x8011a640,%eax
80102e99:	89 10                	mov    %edx,(%eax)
	shm.refs[key][0][proc->pid] = 1;
80102e9b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80102ea1:	8b 50 10             	mov    0x10(%eax),%edx
80102ea4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102ea7:	01 c0                	add    %eax,%eax
80102ea9:	89 c1                	mov    %eax,%ecx
80102eab:	c1 e1 06             	shl    $0x6,%ecx
80102eae:	01 c8                	add    %ecx,%eax
80102eb0:	01 d0                	add    %edx,%eax
80102eb2:	05 10 27 00 00       	add    $0x2710,%eax
80102eb7:	c7 04 85 00 09 11 80 	movl   $0x1,-0x7feef700(,%eax,4)
80102ebe:	01 00 00 00 
	proc->has_shm++;
80102ec2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80102ec8:	8b 90 8c 00 00 00    	mov    0x8c(%eax),%edx
80102ece:	83 c2 01             	add    $0x1,%edx
80102ed1:	89 90 8c 00 00 00    	mov    %edx,0x8c(%eax)
	
	for(i = 0;i < shm.refs[key][1][64] && a < KERNBASE;i++,a += PGSIZE)
80102ed7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102ede:	e9 af 00 00 00       	jmp    80102f92 <shmat+0x1b6>
	{
	    forFlag = 1;
80102ee3:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
	    mem = shm.seg[key][i];
80102eea:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102eed:	6b c0 64             	imul   $0x64,%eax,%eax
80102ef0:	03 45 f4             	add    -0xc(%ebp),%eax
80102ef3:	8b 04 85 00 09 11 80 	mov    -0x7feef700(,%eax,4),%eax
80102efa:	89 45 e0             	mov    %eax,-0x20(%ebp)
	    switch(shmflg)
80102efd:	8b 45 0c             	mov    0xc(%ebp),%eax
80102f00:	83 f8 16             	cmp    $0x16,%eax
80102f03:	74 07                	je     80102f0c <shmat+0x130>
80102f05:	83 f8 17             	cmp    $0x17,%eax
80102f08:	74 3c                	je     80102f46 <shmat+0x16a>
80102f0a:	eb 74                	jmp    80102f80 <shmat+0x1a4>
	    {
	      case SHM_RDONLY:
		mappages(proc->pgdir, (char*)a, PGSIZE, v2p(mem), PTE_U);
80102f0c:	8b 45 e0             	mov    -0x20(%ebp),%eax
80102f0f:	89 04 24             	mov    %eax,(%esp)
80102f12:	e8 b1 fa ff ff       	call   801029c8 <v2p>
80102f17:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80102f1a:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80102f21:	8b 52 04             	mov    0x4(%edx),%edx
80102f24:	c7 44 24 10 04 00 00 	movl   $0x4,0x10(%esp)
80102f2b:	00 
80102f2c:	89 44 24 0c          	mov    %eax,0xc(%esp)
80102f30:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80102f37:	00 
80102f38:	89 4c 24 04          	mov    %ecx,0x4(%esp)
80102f3c:	89 14 24             	mov    %edx,(%esp)
80102f3f:	e8 c5 5e 00 00       	call   80108e09 <mappages>
		break;
80102f44:	eb 41                	jmp    80102f87 <shmat+0x1ab>
	      case SHM_RDWR:
		mappages(proc->pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
80102f46:	8b 45 e0             	mov    -0x20(%ebp),%eax
80102f49:	89 04 24             	mov    %eax,(%esp)
80102f4c:	e8 77 fa ff ff       	call   801029c8 <v2p>
80102f51:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80102f54:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80102f5b:	8b 52 04             	mov    0x4(%edx),%edx
80102f5e:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80102f65:	00 
80102f66:	89 44 24 0c          	mov    %eax,0xc(%esp)
80102f6a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80102f71:	00 
80102f72:	89 4c 24 04          	mov    %ecx,0x4(%esp)
80102f76:	89 14 24             	mov    %edx,(%esp)
80102f79:	e8 8b 5e 00 00       	call   80108e09 <mappages>
		break;
80102f7e:	eb 07                	jmp    80102f87 <shmat+0x1ab>
	      default:
		forFlag = 0;
80102f80:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	
	shm.refs[key][0][64]++;
	shm.refs[key][0][proc->pid] = 1;
	proc->has_shm++;
	
	for(i = 0;i < shm.refs[key][1][64] && a < KERNBASE;i++,a += PGSIZE)
80102f87:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102f8b:	81 45 e4 00 10 00 00 	addl   $0x1000,-0x1c(%ebp)
80102f92:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102f95:	c1 e0 03             	shl    $0x3,%eax
80102f98:	89 c2                	mov    %eax,%edx
80102f9a:	c1 e2 06             	shl    $0x6,%edx
80102f9d:	01 d0                	add    %edx,%eax
80102f9f:	05 44 a7 11 80       	add    $0x8011a744,%eax
80102fa4:	8b 00                	mov    (%eax),%eax
80102fa6:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80102fa9:	7e 0b                	jle    80102fb6 <shmat+0x1da>
80102fab:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102fae:	85 c0                	test   %eax,%eax
80102fb0:	0f 89 2d ff ff ff    	jns    80102ee3 <shmat+0x107>
		break;
	      default:
		forFlag = 0;
	    } 
	}
	if(forFlag)
80102fb6:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80102fba:	74 0d                	je     80102fc9 <shmat+0x1ed>
	  proc->sz = a;
80102fbc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80102fc2:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80102fc5:	89 10                	mov    %edx,(%eax)
	else
	  ans = (void*)-1;
	break;
80102fc7:	eb 1a                	jmp    80102fe3 <shmat+0x207>
	    } 
	}
	if(forFlag)
	  proc->sz = a;
	else
	  ans = (void*)-1;
80102fc9:	c7 45 e8 ff ff ff ff 	movl   $0xffffffff,-0x18(%ebp)
	break;
80102fd0:	eb 11                	jmp    80102fe3 <shmat+0x207>
  void* ans = (void*)-1;
  char* mem;
  uint a;

  acquire(&shm.lock);
  for(key = 0;key<numOfSegs;key++)
80102fd2:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80102fd6:	83 7d f0 63          	cmpl   $0x63,-0x10(%ebp)
80102fda:	0f 8e 28 fe ff ff    	jle    80102e08 <shmat+0x2c>
80102fe0:	eb 01                	jmp    80102fe3 <shmat+0x207>
	else
	  ans = (void*)-1;
	break;
      }
      else
      	break;
80102fe2:	90                   	nop
    }
  }
  release(&shm.lock);
80102fe3:	c7 04 24 60 70 12 80 	movl   $0x80127060,(%esp)
80102fea:	e8 63 2c 00 00       	call   80105c52 <release>
  return ans;
80102fef:	8b 45 e8             	mov    -0x18(%ebp),%eax
}
80102ff2:	c9                   	leave  
80102ff3:	c3                   	ret    

80102ff4 <shmdt>:

int 
shmdt(const void *shmaddr)
{
80102ff4:	55                   	push   %ebp
80102ff5:	89 e5                	mov    %esp,%ebp
80102ff7:	83 ec 38             	sub    $0x38,%esp
  pte_t *pte;
  uint r, numOfPages;
  int key,found;
  pte = walkpgdir(proc->pgdir, (char*)shmaddr, 0);
80102ffa:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80103000:	8b 40 04             	mov    0x4(%eax),%eax
80103003:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010300a:	00 
8010300b:	8b 55 08             	mov    0x8(%ebp),%edx
8010300e:	89 54 24 04          	mov    %edx,0x4(%esp)
80103012:	89 04 24             	mov    %eax,(%esp)
80103015:	e8 59 5d 00 00       	call   80108d73 <walkpgdir>
8010301a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  r = (int)p2v(PTE_ADDR(*pte)) ;
8010301d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80103020:	8b 00                	mov    (%eax),%eax
80103022:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80103027:	89 04 24             	mov    %eax,(%esp)
8010302a:	e8 a6 f9 ff ff       	call   801029d5 <p2v>
8010302f:	89 45 e0             	mov    %eax,-0x20(%ebp)
  acquire(&shm.lock);
80103032:	c7 04 24 60 70 12 80 	movl   $0x80127060,(%esp)
80103039:	e8 79 2b 00 00       	call   80105bb7 <acquire>
  for(found = 0,key = 0;key<numOfSegs;key++)
8010303e:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80103045:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
8010304c:	e9 04 01 00 00       	jmp    80103155 <shmdt+0x161>
  {    
    if((int)shm.seg[key][0] == r)
80103051:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103054:	69 c0 90 01 00 00    	imul   $0x190,%eax,%eax
8010305a:	05 00 09 11 80       	add    $0x80110900,%eax
8010305f:	8b 00                	mov    (%eax),%eax
80103061:	3b 45 e0             	cmp    -0x20(%ebp),%eax
80103064:	0f 85 e7 00 00 00    	jne    80103151 <shmdt+0x15d>
    {  
      if(shm.refs[key][1][64]>0)
8010306a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010306d:	c1 e0 03             	shl    $0x3,%eax
80103070:	89 c2                	mov    %eax,%edx
80103072:	c1 e2 06             	shl    $0x6,%edx
80103075:	01 d0                	add    %edx,%eax
80103077:	05 44 a7 11 80       	add    $0x8011a744,%eax
8010307c:	8b 00                	mov    (%eax),%eax
8010307e:	85 c0                	test   %eax,%eax
80103080:	0f 8e b5 00 00 00    	jle    8010313b <shmdt+0x147>
      { 
	if(shm.refs[key][0][64] <= 0)
80103086:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103089:	c1 e0 03             	shl    $0x3,%eax
8010308c:	89 c2                	mov    %eax,%edx
8010308e:	c1 e2 06             	shl    $0x6,%edx
80103091:	01 d0                	add    %edx,%eax
80103093:	05 40 a6 11 80       	add    $0x8011a640,%eax
80103098:	8b 00                	mov    (%eax),%eax
8010309a:	85 c0                	test   %eax,%eax
8010309c:	7f 16                	jg     801030b4 <shmdt+0xc0>
	{
	  cprintf("shmdt exception - trying to detach a segment with no references\n");
8010309e:	c7 04 24 40 99 10 80 	movl   $0x80109940,(%esp)
801030a5:	e8 f7 d2 ff ff       	call   801003a1 <cprintf>
	  return -1;
801030aa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801030af:	e9 1f 01 00 00       	jmp    801031d3 <shmdt+0x1df>
	}
	shm.refs[key][0][64]--;
801030b4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801030b7:	c1 e0 03             	shl    $0x3,%eax
801030ba:	89 c2                	mov    %eax,%edx
801030bc:	c1 e2 06             	shl    $0x6,%edx
801030bf:	01 d0                	add    %edx,%eax
801030c1:	05 40 a6 11 80       	add    $0x8011a640,%eax
801030c6:	8b 00                	mov    (%eax),%eax
801030c8:	8d 50 ff             	lea    -0x1(%eax),%edx
801030cb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801030ce:	c1 e0 03             	shl    $0x3,%eax
801030d1:	89 c1                	mov    %eax,%ecx
801030d3:	c1 e1 06             	shl    $0x6,%ecx
801030d6:	01 c8                	add    %ecx,%eax
801030d8:	05 40 a6 11 80       	add    $0x8011a640,%eax
801030dd:	89 10                	mov    %edx,(%eax)
	shm.refs[key][0][proc->pid] = 0;
801030df:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801030e5:	8b 50 10             	mov    0x10(%eax),%edx
801030e8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801030eb:	01 c0                	add    %eax,%eax
801030ed:	89 c1                	mov    %eax,%ecx
801030ef:	c1 e1 06             	shl    $0x6,%ecx
801030f2:	01 c8                	add    %ecx,%eax
801030f4:	01 d0                	add    %edx,%eax
801030f6:	05 10 27 00 00       	add    $0x2710,%eax
801030fb:	c7 04 85 00 09 11 80 	movl   $0x0,-0x7feef700(,%eax,4)
80103102:	00 00 00 00 
	proc->has_shm--;
80103106:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010310c:	8b 90 8c 00 00 00    	mov    0x8c(%eax),%edx
80103112:	83 ea 01             	sub    $0x1,%edx
80103115:	89 90 8c 00 00 00    	mov    %edx,0x8c(%eax)
	numOfPages = shm.refs[key][1][64];
8010311b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010311e:	c1 e0 03             	shl    $0x3,%eax
80103121:	89 c2                	mov    %eax,%edx
80103123:	c1 e2 06             	shl    $0x6,%edx
80103126:	01 d0                	add    %edx,%eax
80103128:	05 44 a7 11 80       	add    $0x8011a744,%eax
8010312d:	8b 00                	mov    (%eax),%eax
8010312f:	89 45 f4             	mov    %eax,-0xc(%ebp)
	found = 1;
80103132:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
	break;
80103139:	eb 24                	jmp    8010315f <shmdt+0x16b>
      }
      else
      {
	cprintf("shmdt exception - trying to detach a segment with no pages\n");
8010313b:	c7 04 24 84 99 10 80 	movl   $0x80109984,(%esp)
80103142:	e8 5a d2 ff ff       	call   801003a1 <cprintf>
	return -1;
80103147:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010314c:	e9 82 00 00 00       	jmp    801031d3 <shmdt+0x1df>
  uint r, numOfPages;
  int key,found;
  pte = walkpgdir(proc->pgdir, (char*)shmaddr, 0);
  r = (int)p2v(PTE_ADDR(*pte)) ;
  acquire(&shm.lock);
  for(found = 0,key = 0;key<numOfSegs;key++)
80103151:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80103155:	83 7d f0 63          	cmpl   $0x63,-0x10(%ebp)
80103159:	0f 8e f2 fe ff ff    	jle    80103051 <shmdt+0x5d>
	cprintf("shmdt exception - trying to detach a segment with no pages\n");
	return -1;
      }
    }
  }
  release(&shm.lock);
8010315f:	c7 04 24 60 70 12 80 	movl   $0x80127060,(%esp)
80103166:	e8 e7 2a 00 00       	call   80105c52 <release>
  
  if(!found)
8010316b:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
8010316f:	75 07                	jne    80103178 <shmdt+0x184>
    return -1;
80103171:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103176:	eb 5b                	jmp    801031d3 <shmdt+0x1df>

  void *shmaddr2 = (void*)shmaddr;
80103178:	8b 45 08             	mov    0x8(%ebp),%eax
8010317b:	89 45 e8             	mov    %eax,-0x18(%ebp)

  for(; shmaddr2  < shmaddr + numOfPages*PGSIZE; shmaddr2 += PGSIZE)
8010317e:	eb 40                	jmp    801031c0 <shmdt+0x1cc>
  {
    pte = walkpgdir(proc->pgdir, (char*)shmaddr2, 0);
80103180:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80103186:	8b 40 04             	mov    0x4(%eax),%eax
80103189:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80103190:	00 
80103191:	8b 55 e8             	mov    -0x18(%ebp),%edx
80103194:	89 54 24 04          	mov    %edx,0x4(%esp)
80103198:	89 04 24             	mov    %eax,(%esp)
8010319b:	e8 d3 5b 00 00       	call   80108d73 <walkpgdir>
801031a0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(!pte)
801031a3:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
801031a7:	75 07                	jne    801031b0 <shmdt+0x1bc>
      shmaddr2 += (NPTENTRIES - 1) * PGSIZE;
801031a9:	81 45 e8 00 f0 3f 00 	addl   $0x3ff000,-0x18(%ebp)
    *pte = 0;
801031b0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801031b3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  if(!found)
    return -1;

  void *shmaddr2 = (void*)shmaddr;

  for(; shmaddr2  < shmaddr + numOfPages*PGSIZE; shmaddr2 += PGSIZE)
801031b9:	81 45 e8 00 10 00 00 	addl   $0x1000,-0x18(%ebp)
801031c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801031c3:	c1 e0 0c             	shl    $0xc,%eax
801031c6:	03 45 08             	add    0x8(%ebp),%eax
801031c9:	3b 45 e8             	cmp    -0x18(%ebp),%eax
801031cc:	77 b2                	ja     80103180 <shmdt+0x18c>
    if(!pte)
      shmaddr2 += (NPTENTRIES - 1) * PGSIZE;
    *pte = 0;
  }

  return 0;
801031ce:	b8 00 00 00 00       	mov    $0x0,%eax
}
801031d3:	c9                   	leave  
801031d4:	c3                   	ret    

801031d5 <deallocshm>:

void 
deallocshm(int pid)
{
801031d5:	55                   	push   %ebp
801031d6:	89 e5                	mov    %esp,%ebp
801031d8:	83 ec 38             	sub    $0x38,%esp
  uint a = 0;
801031db:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  int key, pa, numOfPages;
  pte_t *pte;
  
  acquire(&shm.lock);
801031e2:	c7 04 24 60 70 12 80 	movl   $0x80127060,(%esp)
801031e9:	e8 c9 29 00 00       	call   80105bb7 <acquire>
  for(key = 0;key<numOfSegs;key++)
801031ee:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
801031f5:	e9 74 01 00 00       	jmp    8010336e <deallocshm+0x199>
  {    
    if(shm.refs[key][0][proc->pid])
801031fa:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80103200:	8b 50 10             	mov    0x10(%eax),%edx
80103203:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103206:	01 c0                	add    %eax,%eax
80103208:	89 c1                	mov    %eax,%ecx
8010320a:	c1 e1 06             	shl    $0x6,%ecx
8010320d:	01 c8                	add    %ecx,%eax
8010320f:	01 d0                	add    %edx,%eax
80103211:	05 10 27 00 00       	add    $0x2710,%eax
80103216:	8b 04 85 00 09 11 80 	mov    -0x7feef700(,%eax,4),%eax
8010321d:	85 c0                	test   %eax,%eax
8010321f:	0f 84 45 01 00 00    	je     8010336a <deallocshm+0x195>
    {
      for(; a  < proc->sz; a += PGSIZE)
80103225:	e9 2c 01 00 00       	jmp    80103356 <deallocshm+0x181>
      {
	pte = walkpgdir(proc->pgdir, (char*)a, 0);
8010322a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010322d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80103233:	8b 40 04             	mov    0x4(%eax),%eax
80103236:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010323d:	00 
8010323e:	89 54 24 04          	mov    %edx,0x4(%esp)
80103242:	89 04 24             	mov    %eax,(%esp)
80103245:	e8 29 5b 00 00       	call   80108d73 <walkpgdir>
8010324a:	89 45 e8             	mov    %eax,-0x18(%ebp)
	if(!pte)
8010324d:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80103251:	75 0c                	jne    8010325f <deallocshm+0x8a>
	  a += (NPTENTRIES - 1) * PGSIZE;
80103253:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
8010325a:	e9 f0 00 00 00       	jmp    8010334f <deallocshm+0x17a>
	else if((*pte & PTE_P) != 0)
8010325f:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103262:	8b 00                	mov    (%eax),%eax
80103264:	83 e0 01             	and    $0x1,%eax
80103267:	84 c0                	test   %al,%al
80103269:	0f 84 e0 00 00 00    	je     8010334f <deallocshm+0x17a>
	{
	  pa = (int)p2v(PTE_ADDR(*pte));
8010326f:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103272:	8b 00                	mov    (%eax),%eax
80103274:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80103279:	89 04 24             	mov    %eax,(%esp)
8010327c:	e8 54 f7 ff ff       	call   801029d5 <p2v>
80103281:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	  if((int)shm.seg[key][0] == pa)
80103284:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103287:	69 c0 90 01 00 00    	imul   $0x190,%eax,%eax
8010328d:	05 00 09 11 80       	add    $0x80110900,%eax
80103292:	8b 00                	mov    (%eax),%eax
80103294:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
80103297:	0f 85 b2 00 00 00    	jne    8010334f <deallocshm+0x17a>
	  {
	    void *b = (void*)a;
8010329d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032a0:	89 45 ec             	mov    %eax,-0x14(%ebp)
	    numOfPages = shm.refs[key][1][64];
801032a3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801032a6:	c1 e0 03             	shl    $0x3,%eax
801032a9:	89 c2                	mov    %eax,%edx
801032ab:	c1 e2 06             	shl    $0x6,%edx
801032ae:	01 d0                	add    %edx,%eax
801032b0:	05 44 a7 11 80       	add    $0x8011a744,%eax
801032b5:	8b 00                	mov    (%eax),%eax
801032b7:	89 45 e0             	mov    %eax,-0x20(%ebp)
	    for(; b  < (void*)a + numOfPages*PGSIZE; b += PGSIZE)
801032ba:	eb 40                	jmp    801032fc <deallocshm+0x127>
	    {
	      pte = walkpgdir(proc->pgdir, (char*)b, 0);
801032bc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801032c2:	8b 40 04             	mov    0x4(%eax),%eax
801032c5:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801032cc:	00 
801032cd:	8b 55 ec             	mov    -0x14(%ebp),%edx
801032d0:	89 54 24 04          	mov    %edx,0x4(%esp)
801032d4:	89 04 24             	mov    %eax,(%esp)
801032d7:	e8 97 5a 00 00       	call   80108d73 <walkpgdir>
801032dc:	89 45 e8             	mov    %eax,-0x18(%ebp)
	      if(!pte)
801032df:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801032e3:	75 07                	jne    801032ec <deallocshm+0x117>
		b += (NPTENTRIES - 1) * PGSIZE;
801032e5:	81 45 ec 00 f0 3f 00 	addl   $0x3ff000,-0x14(%ebp)
	      *pte = 0;
801032ec:	8b 45 e8             	mov    -0x18(%ebp),%eax
801032ef:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	  pa = (int)p2v(PTE_ADDR(*pte));
	  if((int)shm.seg[key][0] == pa)
	  {
	    void *b = (void*)a;
	    numOfPages = shm.refs[key][1][64];
	    for(; b  < (void*)a + numOfPages*PGSIZE; b += PGSIZE)
801032f5:	81 45 ec 00 10 00 00 	addl   $0x1000,-0x14(%ebp)
801032fc:	8b 45 e0             	mov    -0x20(%ebp),%eax
801032ff:	c1 e0 0c             	shl    $0xc,%eax
80103302:	03 45 f4             	add    -0xc(%ebp),%eax
80103305:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103308:	77 b2                	ja     801032bc <deallocshm+0xe7>
	      pte = walkpgdir(proc->pgdir, (char*)b, 0);
	      if(!pte)
		b += (NPTENTRIES - 1) * PGSIZE;
	      *pte = 0;
	    }
	    if(shm.refs[key][0][64]>0)
8010330a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010330d:	c1 e0 03             	shl    $0x3,%eax
80103310:	89 c2                	mov    %eax,%edx
80103312:	c1 e2 06             	shl    $0x6,%edx
80103315:	01 d0                	add    %edx,%eax
80103317:	05 40 a6 11 80       	add    $0x8011a640,%eax
8010331c:	8b 00                	mov    (%eax),%eax
8010331e:	85 c0                	test   %eax,%eax
80103320:	7e 47                	jle    80103369 <deallocshm+0x194>
	      shm.refs[key][0][64]--;
80103322:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103325:	c1 e0 03             	shl    $0x3,%eax
80103328:	89 c2                	mov    %eax,%edx
8010332a:	c1 e2 06             	shl    $0x6,%edx
8010332d:	01 d0                	add    %edx,%eax
8010332f:	05 40 a6 11 80       	add    $0x8011a640,%eax
80103334:	8b 00                	mov    (%eax),%eax
80103336:	8d 50 ff             	lea    -0x1(%eax),%edx
80103339:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010333c:	c1 e0 03             	shl    $0x3,%eax
8010333f:	89 c1                	mov    %eax,%ecx
80103341:	c1 e1 06             	shl    $0x6,%ecx
80103344:	01 c8                	add    %ecx,%eax
80103346:	05 40 a6 11 80       	add    $0x8011a640,%eax
8010334b:	89 10                	mov    %edx,(%eax)
	    break;
8010334d:	eb 1a                	jmp    80103369 <deallocshm+0x194>
  acquire(&shm.lock);
  for(key = 0;key<numOfSegs;key++)
  {    
    if(shm.refs[key][0][proc->pid])
    {
      for(; a  < proc->sz; a += PGSIZE)
8010334f:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80103356:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010335c:	8b 00                	mov    (%eax),%eax
8010335e:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103361:	0f 87 c3 fe ff ff    	ja     8010322a <deallocshm+0x55>
80103367:	eb 01                	jmp    8010336a <deallocshm+0x195>
		b += (NPTENTRIES - 1) * PGSIZE;
	      *pte = 0;
	    }
	    if(shm.refs[key][0][64]>0)
	      shm.refs[key][0][64]--;
	    break;
80103369:	90                   	nop
  uint a = 0;
  int key, pa, numOfPages;
  pte_t *pte;
  
  acquire(&shm.lock);
  for(key = 0;key<numOfSegs;key++)
8010336a:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
8010336e:	83 7d f0 63          	cmpl   $0x63,-0x10(%ebp)
80103372:	0f 8e 82 fe ff ff    	jle    801031fa <deallocshm+0x25>
	  }
	}
      }
    }
  }
  release(&shm.lock);
80103378:	c7 04 24 60 70 12 80 	movl   $0x80127060,(%esp)
8010337f:	e8 ce 28 00 00       	call   80105c52 <release>
}
80103384:	c9                   	leave  
80103385:	c3                   	ret    
	...

80103388 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80103388:	55                   	push   %ebp
80103389:	89 e5                	mov    %esp,%ebp
8010338b:	53                   	push   %ebx
8010338c:	83 ec 14             	sub    $0x14,%esp
8010338f:	8b 45 08             	mov    0x8(%ebp),%eax
80103392:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80103396:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
8010339a:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
8010339e:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
801033a2:	ec                   	in     (%dx),%al
801033a3:	89 c3                	mov    %eax,%ebx
801033a5:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
801033a8:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
801033ac:	83 c4 14             	add    $0x14,%esp
801033af:	5b                   	pop    %ebx
801033b0:	5d                   	pop    %ebp
801033b1:	c3                   	ret    

801033b2 <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
801033b2:	55                   	push   %ebp
801033b3:	89 e5                	mov    %esp,%ebp
801033b5:	83 ec 14             	sub    $0x14,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
801033b8:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
801033bf:	e8 c4 ff ff ff       	call   80103388 <inb>
801033c4:	0f b6 c0             	movzbl %al,%eax
801033c7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
801033ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
801033cd:	83 e0 01             	and    $0x1,%eax
801033d0:	85 c0                	test   %eax,%eax
801033d2:	75 0a                	jne    801033de <kbdgetc+0x2c>
    return -1;
801033d4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801033d9:	e9 23 01 00 00       	jmp    80103501 <kbdgetc+0x14f>
  data = inb(KBDATAP);
801033de:	c7 04 24 60 00 00 00 	movl   $0x60,(%esp)
801033e5:	e8 9e ff ff ff       	call   80103388 <inb>
801033ea:	0f b6 c0             	movzbl %al,%eax
801033ed:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
801033f0:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
801033f7:	75 17                	jne    80103410 <kbdgetc+0x5e>
    shift |= E0ESC;
801033f9:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
801033fe:	83 c8 40             	or     $0x40,%eax
80103401:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
    return 0;
80103406:	b8 00 00 00 00       	mov    $0x0,%eax
8010340b:	e9 f1 00 00 00       	jmp    80103501 <kbdgetc+0x14f>
  } else if(data & 0x80){
80103410:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103413:	25 80 00 00 00       	and    $0x80,%eax
80103418:	85 c0                	test   %eax,%eax
8010341a:	74 45                	je     80103461 <kbdgetc+0xaf>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
8010341c:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103421:	83 e0 40             	and    $0x40,%eax
80103424:	85 c0                	test   %eax,%eax
80103426:	75 08                	jne    80103430 <kbdgetc+0x7e>
80103428:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010342b:	83 e0 7f             	and    $0x7f,%eax
8010342e:	eb 03                	jmp    80103433 <kbdgetc+0x81>
80103430:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103433:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
80103436:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103439:	05 20 a0 10 80       	add    $0x8010a020,%eax
8010343e:	0f b6 00             	movzbl (%eax),%eax
80103441:	83 c8 40             	or     $0x40,%eax
80103444:	0f b6 c0             	movzbl %al,%eax
80103447:	f7 d0                	not    %eax
80103449:	89 c2                	mov    %eax,%edx
8010344b:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103450:	21 d0                	and    %edx,%eax
80103452:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
    return 0;
80103457:	b8 00 00 00 00       	mov    $0x0,%eax
8010345c:	e9 a0 00 00 00       	jmp    80103501 <kbdgetc+0x14f>
  } else if(shift & E0ESC){
80103461:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103466:	83 e0 40             	and    $0x40,%eax
80103469:	85 c0                	test   %eax,%eax
8010346b:	74 14                	je     80103481 <kbdgetc+0xcf>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
8010346d:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
80103474:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103479:	83 e0 bf             	and    $0xffffffbf,%eax
8010347c:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
  }

  shift |= shiftcode[data];
80103481:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103484:	05 20 a0 10 80       	add    $0x8010a020,%eax
80103489:	0f b6 00             	movzbl (%eax),%eax
8010348c:	0f b6 d0             	movzbl %al,%edx
8010348f:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103494:	09 d0                	or     %edx,%eax
80103496:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
  shift ^= togglecode[data];
8010349b:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010349e:	05 20 a1 10 80       	add    $0x8010a120,%eax
801034a3:	0f b6 00             	movzbl (%eax),%eax
801034a6:	0f b6 d0             	movzbl %al,%edx
801034a9:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
801034ae:	31 d0                	xor    %edx,%eax
801034b0:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
  c = charcode[shift & (CTL | SHIFT)][data];
801034b5:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
801034ba:	83 e0 03             	and    $0x3,%eax
801034bd:	8b 04 85 20 a5 10 80 	mov    -0x7fef5ae0(,%eax,4),%eax
801034c4:	03 45 fc             	add    -0x4(%ebp),%eax
801034c7:	0f b6 00             	movzbl (%eax),%eax
801034ca:	0f b6 c0             	movzbl %al,%eax
801034cd:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
801034d0:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
801034d5:	83 e0 08             	and    $0x8,%eax
801034d8:	85 c0                	test   %eax,%eax
801034da:	74 22                	je     801034fe <kbdgetc+0x14c>
    if('a' <= c && c <= 'z')
801034dc:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
801034e0:	76 0c                	jbe    801034ee <kbdgetc+0x13c>
801034e2:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
801034e6:	77 06                	ja     801034ee <kbdgetc+0x13c>
      c += 'A' - 'a';
801034e8:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
801034ec:	eb 10                	jmp    801034fe <kbdgetc+0x14c>
    else if('A' <= c && c <= 'Z')
801034ee:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
801034f2:	76 0a                	jbe    801034fe <kbdgetc+0x14c>
801034f4:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
801034f8:	77 04                	ja     801034fe <kbdgetc+0x14c>
      c += 'a' - 'A';
801034fa:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
801034fe:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103501:	c9                   	leave  
80103502:	c3                   	ret    

80103503 <kbdintr>:

void
kbdintr(void)
{
80103503:	55                   	push   %ebp
80103504:	89 e5                	mov    %esp,%ebp
80103506:	83 ec 18             	sub    $0x18,%esp
  consoleintr(kbdgetc);
80103509:	c7 04 24 b2 33 10 80 	movl   $0x801033b2,(%esp)
80103510:	e8 98 d2 ff ff       	call   801007ad <consoleintr>
}
80103515:	c9                   	leave  
80103516:	c3                   	ret    
	...

80103518 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103518:	55                   	push   %ebp
80103519:	89 e5                	mov    %esp,%ebp
8010351b:	83 ec 08             	sub    $0x8,%esp
8010351e:	8b 55 08             	mov    0x8(%ebp),%edx
80103521:	8b 45 0c             	mov    0xc(%ebp),%eax
80103524:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103528:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010352b:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
8010352f:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103533:	ee                   	out    %al,(%dx)
}
80103534:	c9                   	leave  
80103535:	c3                   	ret    

80103536 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80103536:	55                   	push   %ebp
80103537:	89 e5                	mov    %esp,%ebp
80103539:	53                   	push   %ebx
8010353a:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
8010353d:	9c                   	pushf  
8010353e:	5b                   	pop    %ebx
8010353f:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80103542:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103545:	83 c4 10             	add    $0x10,%esp
80103548:	5b                   	pop    %ebx
80103549:	5d                   	pop    %ebp
8010354a:	c3                   	ret    

8010354b <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
8010354b:	55                   	push   %ebp
8010354c:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
8010354e:	a1 94 70 12 80       	mov    0x80127094,%eax
80103553:	8b 55 08             	mov    0x8(%ebp),%edx
80103556:	c1 e2 02             	shl    $0x2,%edx
80103559:	01 c2                	add    %eax,%edx
8010355b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010355e:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
80103560:	a1 94 70 12 80       	mov    0x80127094,%eax
80103565:	83 c0 20             	add    $0x20,%eax
80103568:	8b 00                	mov    (%eax),%eax
}
8010356a:	5d                   	pop    %ebp
8010356b:	c3                   	ret    

8010356c <lapicinit>:
//PAGEBREAK!

void
lapicinit(int c)
{
8010356c:	55                   	push   %ebp
8010356d:	89 e5                	mov    %esp,%ebp
8010356f:	83 ec 08             	sub    $0x8,%esp
  if(!lapic) 
80103572:	a1 94 70 12 80       	mov    0x80127094,%eax
80103577:	85 c0                	test   %eax,%eax
80103579:	0f 84 47 01 00 00    	je     801036c6 <lapicinit+0x15a>
    return;

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
8010357f:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
80103586:	00 
80103587:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
8010358e:	e8 b8 ff ff ff       	call   8010354b <lapicw>

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.  
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
80103593:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
8010359a:	00 
8010359b:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
801035a2:	e8 a4 ff ff ff       	call   8010354b <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
801035a7:	c7 44 24 04 20 00 02 	movl   $0x20020,0x4(%esp)
801035ae:	00 
801035af:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
801035b6:	e8 90 ff ff ff       	call   8010354b <lapicw>
  lapicw(TICR, 10000000); 
801035bb:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
801035c2:	00 
801035c3:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
801035ca:	e8 7c ff ff ff       	call   8010354b <lapicw>

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
801035cf:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
801035d6:	00 
801035d7:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
801035de:	e8 68 ff ff ff       	call   8010354b <lapicw>
  lapicw(LINT1, MASKED);
801035e3:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
801035ea:	00 
801035eb:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
801035f2:	e8 54 ff ff ff       	call   8010354b <lapicw>

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
801035f7:	a1 94 70 12 80       	mov    0x80127094,%eax
801035fc:	83 c0 30             	add    $0x30,%eax
801035ff:	8b 00                	mov    (%eax),%eax
80103601:	c1 e8 10             	shr    $0x10,%eax
80103604:	25 ff 00 00 00       	and    $0xff,%eax
80103609:	83 f8 03             	cmp    $0x3,%eax
8010360c:	76 14                	jbe    80103622 <lapicinit+0xb6>
    lapicw(PCINT, MASKED);
8010360e:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103615:	00 
80103616:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
8010361d:	e8 29 ff ff ff       	call   8010354b <lapicw>

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
80103622:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
80103629:	00 
8010362a:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
80103631:	e8 15 ff ff ff       	call   8010354b <lapicw>

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
80103636:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010363d:	00 
8010363e:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103645:	e8 01 ff ff ff       	call   8010354b <lapicw>
  lapicw(ESR, 0);
8010364a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103651:	00 
80103652:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103659:	e8 ed fe ff ff       	call   8010354b <lapicw>

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
8010365e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103665:	00 
80103666:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
8010366d:	e8 d9 fe ff ff       	call   8010354b <lapicw>

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
80103672:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103679:	00 
8010367a:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80103681:	e8 c5 fe ff ff       	call   8010354b <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
80103686:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
8010368d:	00 
8010368e:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103695:	e8 b1 fe ff ff       	call   8010354b <lapicw>
  while(lapic[ICRLO] & DELIVS)
8010369a:	90                   	nop
8010369b:	a1 94 70 12 80       	mov    0x80127094,%eax
801036a0:	05 00 03 00 00       	add    $0x300,%eax
801036a5:	8b 00                	mov    (%eax),%eax
801036a7:	25 00 10 00 00       	and    $0x1000,%eax
801036ac:	85 c0                	test   %eax,%eax
801036ae:	75 eb                	jne    8010369b <lapicinit+0x12f>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
801036b0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801036b7:	00 
801036b8:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
801036bf:	e8 87 fe ff ff       	call   8010354b <lapicw>
801036c4:	eb 01                	jmp    801036c7 <lapicinit+0x15b>

void
lapicinit(int c)
{
  if(!lapic) 
    return;
801036c6:	90                   	nop
  while(lapic[ICRLO] & DELIVS)
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
}
801036c7:	c9                   	leave  
801036c8:	c3                   	ret    

801036c9 <cpunum>:

int
cpunum(void)
{
801036c9:	55                   	push   %ebp
801036ca:	89 e5                	mov    %esp,%ebp
801036cc:	83 ec 18             	sub    $0x18,%esp
  // Cannot call cpu when interrupts are enabled:
  // result not guaranteed to last long enough to be used!
  // Would prefer to panic but even printing is chancy here:
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
801036cf:	e8 62 fe ff ff       	call   80103536 <readeflags>
801036d4:	25 00 02 00 00       	and    $0x200,%eax
801036d9:	85 c0                	test   %eax,%eax
801036db:	74 29                	je     80103706 <cpunum+0x3d>
    static int n;
    if(n++ == 0)
801036dd:	a1 60 c6 10 80       	mov    0x8010c660,%eax
801036e2:	85 c0                	test   %eax,%eax
801036e4:	0f 94 c2             	sete   %dl
801036e7:	83 c0 01             	add    $0x1,%eax
801036ea:	a3 60 c6 10 80       	mov    %eax,0x8010c660
801036ef:	84 d2                	test   %dl,%dl
801036f1:	74 13                	je     80103706 <cpunum+0x3d>
      cprintf("cpu called from %x with interrupts enabled\n",
801036f3:	8b 45 04             	mov    0x4(%ebp),%eax
801036f6:	89 44 24 04          	mov    %eax,0x4(%esp)
801036fa:	c7 04 24 c0 99 10 80 	movl   $0x801099c0,(%esp)
80103701:	e8 9b cc ff ff       	call   801003a1 <cprintf>
        __builtin_return_address(0));
  }

  if(lapic)
80103706:	a1 94 70 12 80       	mov    0x80127094,%eax
8010370b:	85 c0                	test   %eax,%eax
8010370d:	74 0f                	je     8010371e <cpunum+0x55>
    return lapic[ID]>>24;
8010370f:	a1 94 70 12 80       	mov    0x80127094,%eax
80103714:	83 c0 20             	add    $0x20,%eax
80103717:	8b 00                	mov    (%eax),%eax
80103719:	c1 e8 18             	shr    $0x18,%eax
8010371c:	eb 05                	jmp    80103723 <cpunum+0x5a>
  return 0;
8010371e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103723:	c9                   	leave  
80103724:	c3                   	ret    

80103725 <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
80103725:	55                   	push   %ebp
80103726:	89 e5                	mov    %esp,%ebp
80103728:	83 ec 08             	sub    $0x8,%esp
  if(lapic)
8010372b:	a1 94 70 12 80       	mov    0x80127094,%eax
80103730:	85 c0                	test   %eax,%eax
80103732:	74 14                	je     80103748 <lapiceoi+0x23>
    lapicw(EOI, 0);
80103734:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010373b:	00 
8010373c:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80103743:	e8 03 fe ff ff       	call   8010354b <lapicw>
}
80103748:	c9                   	leave  
80103749:	c3                   	ret    

8010374a <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
8010374a:	55                   	push   %ebp
8010374b:	89 e5                	mov    %esp,%ebp
}
8010374d:	5d                   	pop    %ebp
8010374e:	c3                   	ret    

8010374f <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
8010374f:	55                   	push   %ebp
80103750:	89 e5                	mov    %esp,%ebp
80103752:	83 ec 1c             	sub    $0x1c,%esp
80103755:	8b 45 08             	mov    0x8(%ebp),%eax
80103758:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;
  
  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
8010375b:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80103762:	00 
80103763:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
8010376a:	e8 a9 fd ff ff       	call   80103518 <outb>
  outb(IO_RTC+1, 0x0A);
8010376f:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80103776:	00 
80103777:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
8010377e:	e8 95 fd ff ff       	call   80103518 <outb>
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
80103783:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
8010378a:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010378d:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
80103792:	8b 45 f8             	mov    -0x8(%ebp),%eax
80103795:	8d 50 02             	lea    0x2(%eax),%edx
80103798:	8b 45 0c             	mov    0xc(%ebp),%eax
8010379b:	c1 e8 04             	shr    $0x4,%eax
8010379e:	66 89 02             	mov    %ax,(%edx)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
801037a1:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
801037a5:	c1 e0 18             	shl    $0x18,%eax
801037a8:	89 44 24 04          	mov    %eax,0x4(%esp)
801037ac:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
801037b3:	e8 93 fd ff ff       	call   8010354b <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
801037b8:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
801037bf:	00 
801037c0:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801037c7:	e8 7f fd ff ff       	call   8010354b <lapicw>
  microdelay(200);
801037cc:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
801037d3:	e8 72 ff ff ff       	call   8010374a <microdelay>
  lapicw(ICRLO, INIT | LEVEL);
801037d8:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
801037df:	00 
801037e0:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801037e7:	e8 5f fd ff ff       	call   8010354b <lapicw>
  microdelay(100);    // should be 10ms, but too slow in Bochs!
801037ec:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
801037f3:	e8 52 ff ff ff       	call   8010374a <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
801037f8:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801037ff:	eb 40                	jmp    80103841 <lapicstartap+0xf2>
    lapicw(ICRHI, apicid<<24);
80103801:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80103805:	c1 e0 18             	shl    $0x18,%eax
80103808:	89 44 24 04          	mov    %eax,0x4(%esp)
8010380c:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80103813:	e8 33 fd ff ff       	call   8010354b <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
80103818:	8b 45 0c             	mov    0xc(%ebp),%eax
8010381b:	c1 e8 0c             	shr    $0xc,%eax
8010381e:	80 cc 06             	or     $0x6,%ah
80103821:	89 44 24 04          	mov    %eax,0x4(%esp)
80103825:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
8010382c:	e8 1a fd ff ff       	call   8010354b <lapicw>
    microdelay(200);
80103831:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103838:	e8 0d ff ff ff       	call   8010374a <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
8010383d:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103841:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
80103845:	7e ba                	jle    80103801 <lapicstartap+0xb2>
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
80103847:	c9                   	leave  
80103848:	c3                   	ret    
80103849:	00 00                	add    %al,(%eax)
	...

8010384c <initlog>:

static void recover_from_log(void);

void
initlog(void)
{
8010384c:	55                   	push   %ebp
8010384d:	89 e5                	mov    %esp,%ebp
8010384f:	83 ec 28             	sub    $0x28,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
80103852:	c7 44 24 04 ec 99 10 	movl   $0x801099ec,0x4(%esp)
80103859:	80 
8010385a:	c7 04 24 a0 70 12 80 	movl   $0x801270a0,(%esp)
80103861:	e8 30 23 00 00       	call   80105b96 <initlock>
  readsb(ROOTDEV, &sb);
80103866:	8d 45 e8             	lea    -0x18(%ebp),%eax
80103869:	89 44 24 04          	mov    %eax,0x4(%esp)
8010386d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103874:	e8 73 da ff ff       	call   801012ec <readsb>
  log.start = sb.size - sb.nlog;
80103879:	8b 55 e8             	mov    -0x18(%ebp),%edx
8010387c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010387f:	89 d1                	mov    %edx,%ecx
80103881:	29 c1                	sub    %eax,%ecx
80103883:	89 c8                	mov    %ecx,%eax
80103885:	a3 d4 70 12 80       	mov    %eax,0x801270d4
  log.size = sb.nlog;
8010388a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010388d:	a3 d8 70 12 80       	mov    %eax,0x801270d8
  log.dev = ROOTDEV;
80103892:	c7 05 e0 70 12 80 01 	movl   $0x1,0x801270e0
80103899:	00 00 00 
  recover_from_log();
8010389c:	e8 97 01 00 00       	call   80103a38 <recover_from_log>
}
801038a1:	c9                   	leave  
801038a2:	c3                   	ret    

801038a3 <install_trans>:

// Copy committed blocks from log to their home location
static void 
install_trans(void)
{
801038a3:	55                   	push   %ebp
801038a4:	89 e5                	mov    %esp,%ebp
801038a6:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801038a9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801038b0:	e9 89 00 00 00       	jmp    8010393e <install_trans+0x9b>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
801038b5:	a1 d4 70 12 80       	mov    0x801270d4,%eax
801038ba:	03 45 f4             	add    -0xc(%ebp),%eax
801038bd:	83 c0 01             	add    $0x1,%eax
801038c0:	89 c2                	mov    %eax,%edx
801038c2:	a1 e0 70 12 80       	mov    0x801270e0,%eax
801038c7:	89 54 24 04          	mov    %edx,0x4(%esp)
801038cb:	89 04 24             	mov    %eax,(%esp)
801038ce:	e8 d3 c8 ff ff       	call   801001a6 <bread>
801038d3:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.sector[tail]); // read dst
801038d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801038d9:	83 c0 10             	add    $0x10,%eax
801038dc:	8b 04 85 a8 70 12 80 	mov    -0x7fed8f58(,%eax,4),%eax
801038e3:	89 c2                	mov    %eax,%edx
801038e5:	a1 e0 70 12 80       	mov    0x801270e0,%eax
801038ea:	89 54 24 04          	mov    %edx,0x4(%esp)
801038ee:	89 04 24             	mov    %eax,(%esp)
801038f1:	e8 b0 c8 ff ff       	call   801001a6 <bread>
801038f6:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
801038f9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801038fc:	8d 50 18             	lea    0x18(%eax),%edx
801038ff:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103902:	83 c0 18             	add    $0x18,%eax
80103905:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
8010390c:	00 
8010390d:	89 54 24 04          	mov    %edx,0x4(%esp)
80103911:	89 04 24             	mov    %eax,(%esp)
80103914:	e8 f8 25 00 00       	call   80105f11 <memmove>
    bwrite(dbuf);  // write dst to disk
80103919:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010391c:	89 04 24             	mov    %eax,(%esp)
8010391f:	e8 b9 c8 ff ff       	call   801001dd <bwrite>
    brelse(lbuf); 
80103924:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103927:	89 04 24             	mov    %eax,(%esp)
8010392a:	e8 e8 c8 ff ff       	call   80100217 <brelse>
    brelse(dbuf);
8010392f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103932:	89 04 24             	mov    %eax,(%esp)
80103935:	e8 dd c8 ff ff       	call   80100217 <brelse>
static void 
install_trans(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
8010393a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010393e:	a1 e4 70 12 80       	mov    0x801270e4,%eax
80103943:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103946:	0f 8f 69 ff ff ff    	jg     801038b5 <install_trans+0x12>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    bwrite(dbuf);  // write dst to disk
    brelse(lbuf); 
    brelse(dbuf);
  }
}
8010394c:	c9                   	leave  
8010394d:	c3                   	ret    

8010394e <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
8010394e:	55                   	push   %ebp
8010394f:	89 e5                	mov    %esp,%ebp
80103951:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80103954:	a1 d4 70 12 80       	mov    0x801270d4,%eax
80103959:	89 c2                	mov    %eax,%edx
8010395b:	a1 e0 70 12 80       	mov    0x801270e0,%eax
80103960:	89 54 24 04          	mov    %edx,0x4(%esp)
80103964:	89 04 24             	mov    %eax,(%esp)
80103967:	e8 3a c8 ff ff       	call   801001a6 <bread>
8010396c:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
8010396f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103972:	83 c0 18             	add    $0x18,%eax
80103975:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
80103978:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010397b:	8b 00                	mov    (%eax),%eax
8010397d:	a3 e4 70 12 80       	mov    %eax,0x801270e4
  for (i = 0; i < log.lh.n; i++) {
80103982:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103989:	eb 1b                	jmp    801039a6 <read_head+0x58>
    log.lh.sector[i] = lh->sector[i];
8010398b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010398e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103991:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
80103995:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103998:	83 c2 10             	add    $0x10,%edx
8010399b:	89 04 95 a8 70 12 80 	mov    %eax,-0x7fed8f58(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
801039a2:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801039a6:	a1 e4 70 12 80       	mov    0x801270e4,%eax
801039ab:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801039ae:	7f db                	jg     8010398b <read_head+0x3d>
    log.lh.sector[i] = lh->sector[i];
  }
  brelse(buf);
801039b0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801039b3:	89 04 24             	mov    %eax,(%esp)
801039b6:	e8 5c c8 ff ff       	call   80100217 <brelse>
}
801039bb:	c9                   	leave  
801039bc:	c3                   	ret    

801039bd <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
801039bd:	55                   	push   %ebp
801039be:	89 e5                	mov    %esp,%ebp
801039c0:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
801039c3:	a1 d4 70 12 80       	mov    0x801270d4,%eax
801039c8:	89 c2                	mov    %eax,%edx
801039ca:	a1 e0 70 12 80       	mov    0x801270e0,%eax
801039cf:	89 54 24 04          	mov    %edx,0x4(%esp)
801039d3:	89 04 24             	mov    %eax,(%esp)
801039d6:	e8 cb c7 ff ff       	call   801001a6 <bread>
801039db:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
801039de:	8b 45 f0             	mov    -0x10(%ebp),%eax
801039e1:	83 c0 18             	add    $0x18,%eax
801039e4:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
801039e7:	8b 15 e4 70 12 80    	mov    0x801270e4,%edx
801039ed:	8b 45 ec             	mov    -0x14(%ebp),%eax
801039f0:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
801039f2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801039f9:	eb 1b                	jmp    80103a16 <write_head+0x59>
    hb->sector[i] = log.lh.sector[i];
801039fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039fe:	83 c0 10             	add    $0x10,%eax
80103a01:	8b 0c 85 a8 70 12 80 	mov    -0x7fed8f58(,%eax,4),%ecx
80103a08:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103a0b:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103a0e:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
80103a12:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103a16:	a1 e4 70 12 80       	mov    0x801270e4,%eax
80103a1b:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103a1e:	7f db                	jg     801039fb <write_head+0x3e>
    hb->sector[i] = log.lh.sector[i];
  }
  bwrite(buf);
80103a20:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a23:	89 04 24             	mov    %eax,(%esp)
80103a26:	e8 b2 c7 ff ff       	call   801001dd <bwrite>
  brelse(buf);
80103a2b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a2e:	89 04 24             	mov    %eax,(%esp)
80103a31:	e8 e1 c7 ff ff       	call   80100217 <brelse>
}
80103a36:	c9                   	leave  
80103a37:	c3                   	ret    

80103a38 <recover_from_log>:

static void
recover_from_log(void)
{
80103a38:	55                   	push   %ebp
80103a39:	89 e5                	mov    %esp,%ebp
80103a3b:	83 ec 08             	sub    $0x8,%esp
  read_head();      
80103a3e:	e8 0b ff ff ff       	call   8010394e <read_head>
  install_trans(); // if committed, copy from log to disk
80103a43:	e8 5b fe ff ff       	call   801038a3 <install_trans>
  log.lh.n = 0;
80103a48:	c7 05 e4 70 12 80 00 	movl   $0x0,0x801270e4
80103a4f:	00 00 00 
  write_head(); // clear the log
80103a52:	e8 66 ff ff ff       	call   801039bd <write_head>
}
80103a57:	c9                   	leave  
80103a58:	c3                   	ret    

80103a59 <begin_trans>:

void
begin_trans(void)
{
80103a59:	55                   	push   %ebp
80103a5a:	89 e5                	mov    %esp,%ebp
80103a5c:	83 ec 18             	sub    $0x18,%esp
  acquire(&log.lock);
80103a5f:	c7 04 24 a0 70 12 80 	movl   $0x801270a0,(%esp)
80103a66:	e8 4c 21 00 00       	call   80105bb7 <acquire>
  while (log.busy) {
80103a6b:	eb 14                	jmp    80103a81 <begin_trans+0x28>
  sleep(&log, &log.lock);
80103a6d:	c7 44 24 04 a0 70 12 	movl   $0x801270a0,0x4(%esp)
80103a74:	80 
80103a75:	c7 04 24 a0 70 12 80 	movl   $0x801270a0,(%esp)
80103a7c:	e8 c4 1c 00 00       	call   80105745 <sleep>

void
begin_trans(void)
{
  acquire(&log.lock);
  while (log.busy) {
80103a81:	a1 dc 70 12 80       	mov    0x801270dc,%eax
80103a86:	85 c0                	test   %eax,%eax
80103a88:	75 e3                	jne    80103a6d <begin_trans+0x14>
  sleep(&log, &log.lock);
  }
  log.busy = 1;
80103a8a:	c7 05 dc 70 12 80 01 	movl   $0x1,0x801270dc
80103a91:	00 00 00 
  release(&log.lock);
80103a94:	c7 04 24 a0 70 12 80 	movl   $0x801270a0,(%esp)
80103a9b:	e8 b2 21 00 00       	call   80105c52 <release>
}
80103aa0:	c9                   	leave  
80103aa1:	c3                   	ret    

80103aa2 <commit_trans>:

void
commit_trans(void)
{
80103aa2:	55                   	push   %ebp
80103aa3:	89 e5                	mov    %esp,%ebp
80103aa5:	83 ec 18             	sub    $0x18,%esp
  if (log.lh.n > 0) {
80103aa8:	a1 e4 70 12 80       	mov    0x801270e4,%eax
80103aad:	85 c0                	test   %eax,%eax
80103aaf:	7e 19                	jle    80103aca <commit_trans+0x28>
    write_head();    // Write header to disk -- the real commit
80103ab1:	e8 07 ff ff ff       	call   801039bd <write_head>
    install_trans(); // Now install writes to home locations
80103ab6:	e8 e8 fd ff ff       	call   801038a3 <install_trans>
    log.lh.n = 0; 
80103abb:	c7 05 e4 70 12 80 00 	movl   $0x0,0x801270e4
80103ac2:	00 00 00 
    write_head();    // Erase the transaction from the log
80103ac5:	e8 f3 fe ff ff       	call   801039bd <write_head>
  }
  
  acquire(&log.lock);
80103aca:	c7 04 24 a0 70 12 80 	movl   $0x801270a0,(%esp)
80103ad1:	e8 e1 20 00 00       	call   80105bb7 <acquire>
  log.busy = 0;
80103ad6:	c7 05 dc 70 12 80 00 	movl   $0x0,0x801270dc
80103add:	00 00 00 
  wakeup(&log);
80103ae0:	c7 04 24 a0 70 12 80 	movl   $0x801270a0,(%esp)
80103ae7:	e8 cb 1d 00 00       	call   801058b7 <wakeup>
  release(&log.lock);
80103aec:	c7 04 24 a0 70 12 80 	movl   $0x801270a0,(%esp)
80103af3:	e8 5a 21 00 00       	call   80105c52 <release>
}
80103af8:	c9                   	leave  
80103af9:	c3                   	ret    

80103afa <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80103afa:	55                   	push   %ebp
80103afb:	89 e5                	mov    %esp,%ebp
80103afd:	83 ec 28             	sub    $0x28,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80103b00:	a1 e4 70 12 80       	mov    0x801270e4,%eax
80103b05:	83 f8 09             	cmp    $0x9,%eax
80103b08:	7f 12                	jg     80103b1c <log_write+0x22>
80103b0a:	a1 e4 70 12 80       	mov    0x801270e4,%eax
80103b0f:	8b 15 d8 70 12 80    	mov    0x801270d8,%edx
80103b15:	83 ea 01             	sub    $0x1,%edx
80103b18:	39 d0                	cmp    %edx,%eax
80103b1a:	7c 0c                	jl     80103b28 <log_write+0x2e>
    panic("too big a transaction");
80103b1c:	c7 04 24 f0 99 10 80 	movl   $0x801099f0,(%esp)
80103b23:	e8 15 ca ff ff       	call   8010053d <panic>
  if (!log.busy)
80103b28:	a1 dc 70 12 80       	mov    0x801270dc,%eax
80103b2d:	85 c0                	test   %eax,%eax
80103b2f:	75 0c                	jne    80103b3d <log_write+0x43>
    panic("write outside of trans");
80103b31:	c7 04 24 06 9a 10 80 	movl   $0x80109a06,(%esp)
80103b38:	e8 00 ca ff ff       	call   8010053d <panic>

  for (i = 0; i < log.lh.n; i++) {
80103b3d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103b44:	eb 1d                	jmp    80103b63 <log_write+0x69>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
80103b46:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b49:	83 c0 10             	add    $0x10,%eax
80103b4c:	8b 04 85 a8 70 12 80 	mov    -0x7fed8f58(,%eax,4),%eax
80103b53:	89 c2                	mov    %eax,%edx
80103b55:	8b 45 08             	mov    0x8(%ebp),%eax
80103b58:	8b 40 08             	mov    0x8(%eax),%eax
80103b5b:	39 c2                	cmp    %eax,%edx
80103b5d:	74 10                	je     80103b6f <log_write+0x75>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    panic("too big a transaction");
  if (!log.busy)
    panic("write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
80103b5f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103b63:	a1 e4 70 12 80       	mov    0x801270e4,%eax
80103b68:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103b6b:	7f d9                	jg     80103b46 <log_write+0x4c>
80103b6d:	eb 01                	jmp    80103b70 <log_write+0x76>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
      break;
80103b6f:	90                   	nop
  }
  log.lh.sector[i] = b->sector;
80103b70:	8b 45 08             	mov    0x8(%ebp),%eax
80103b73:	8b 40 08             	mov    0x8(%eax),%eax
80103b76:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103b79:	83 c2 10             	add    $0x10,%edx
80103b7c:	89 04 95 a8 70 12 80 	mov    %eax,-0x7fed8f58(,%edx,4)
  struct buf *lbuf = bread(b->dev, log.start+i+1);
80103b83:	a1 d4 70 12 80       	mov    0x801270d4,%eax
80103b88:	03 45 f4             	add    -0xc(%ebp),%eax
80103b8b:	83 c0 01             	add    $0x1,%eax
80103b8e:	89 c2                	mov    %eax,%edx
80103b90:	8b 45 08             	mov    0x8(%ebp),%eax
80103b93:	8b 40 04             	mov    0x4(%eax),%eax
80103b96:	89 54 24 04          	mov    %edx,0x4(%esp)
80103b9a:	89 04 24             	mov    %eax,(%esp)
80103b9d:	e8 04 c6 ff ff       	call   801001a6 <bread>
80103ba2:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(lbuf->data, b->data, BSIZE);
80103ba5:	8b 45 08             	mov    0x8(%ebp),%eax
80103ba8:	8d 50 18             	lea    0x18(%eax),%edx
80103bab:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103bae:	83 c0 18             	add    $0x18,%eax
80103bb1:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80103bb8:	00 
80103bb9:	89 54 24 04          	mov    %edx,0x4(%esp)
80103bbd:	89 04 24             	mov    %eax,(%esp)
80103bc0:	e8 4c 23 00 00       	call   80105f11 <memmove>
  bwrite(lbuf);
80103bc5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103bc8:	89 04 24             	mov    %eax,(%esp)
80103bcb:	e8 0d c6 ff ff       	call   801001dd <bwrite>
  brelse(lbuf);
80103bd0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103bd3:	89 04 24             	mov    %eax,(%esp)
80103bd6:	e8 3c c6 ff ff       	call   80100217 <brelse>
  if (i == log.lh.n)
80103bdb:	a1 e4 70 12 80       	mov    0x801270e4,%eax
80103be0:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103be3:	75 0d                	jne    80103bf2 <log_write+0xf8>
    log.lh.n++;
80103be5:	a1 e4 70 12 80       	mov    0x801270e4,%eax
80103bea:	83 c0 01             	add    $0x1,%eax
80103bed:	a3 e4 70 12 80       	mov    %eax,0x801270e4
  b->flags |= B_DIRTY; // XXX prevent eviction
80103bf2:	8b 45 08             	mov    0x8(%ebp),%eax
80103bf5:	8b 00                	mov    (%eax),%eax
80103bf7:	89 c2                	mov    %eax,%edx
80103bf9:	83 ca 04             	or     $0x4,%edx
80103bfc:	8b 45 08             	mov    0x8(%ebp),%eax
80103bff:	89 10                	mov    %edx,(%eax)
}
80103c01:	c9                   	leave  
80103c02:	c3                   	ret    
	...

80103c04 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80103c04:	55                   	push   %ebp
80103c05:	89 e5                	mov    %esp,%ebp
80103c07:	8b 45 08             	mov    0x8(%ebp),%eax
80103c0a:	05 00 00 00 80       	add    $0x80000000,%eax
80103c0f:	5d                   	pop    %ebp
80103c10:	c3                   	ret    

80103c11 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80103c11:	55                   	push   %ebp
80103c12:	89 e5                	mov    %esp,%ebp
80103c14:	8b 45 08             	mov    0x8(%ebp),%eax
80103c17:	05 00 00 00 80       	add    $0x80000000,%eax
80103c1c:	5d                   	pop    %ebp
80103c1d:	c3                   	ret    

80103c1e <xchg>:
  asm volatile("sti");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
80103c1e:	55                   	push   %ebp
80103c1f:	89 e5                	mov    %esp,%ebp
80103c21:	53                   	push   %ebx
80103c22:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
80103c25:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80103c28:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
80103c2b:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80103c2e:	89 c3                	mov    %eax,%ebx
80103c30:	89 d8                	mov    %ebx,%eax
80103c32:	f0 87 02             	lock xchg %eax,(%edx)
80103c35:	89 c3                	mov    %eax,%ebx
80103c37:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80103c3a:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103c3d:	83 c4 10             	add    $0x10,%esp
80103c40:	5b                   	pop    %ebx
80103c41:	5d                   	pop    %ebp
80103c42:	c3                   	ret    

80103c43 <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
80103c43:	55                   	push   %ebp
80103c44:	89 e5                	mov    %esp,%ebp
80103c46:	83 e4 f0             	and    $0xfffffff0,%esp
80103c49:	83 ec 10             	sub    $0x10,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80103c4c:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
80103c53:	80 
80103c54:	c7 04 24 1c a4 12 80 	movl   $0x8012a41c,(%esp)
80103c5b:	e8 82 ed ff ff       	call   801029e2 <kinit1>
  kvmalloc();      // kernel page table
80103c60:	e8 f5 52 00 00       	call   80108f5a <kvmalloc>
  mpinit();        // collect info about this machine
80103c65:	e8 63 04 00 00       	call   801040cd <mpinit>
  lapicinit(mpbcpu());
80103c6a:	e8 2e 02 00 00       	call   80103e9d <mpbcpu>
80103c6f:	89 04 24             	mov    %eax,(%esp)
80103c72:	e8 f5 f8 ff ff       	call   8010356c <lapicinit>
  seginit();       // set up segments
80103c77:	e8 81 4c 00 00       	call   801088fd <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
80103c7c:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103c82:	0f b6 00             	movzbl (%eax),%eax
80103c85:	0f b6 c0             	movzbl %al,%eax
80103c88:	89 44 24 04          	mov    %eax,0x4(%esp)
80103c8c:	c7 04 24 1d 9a 10 80 	movl   $0x80109a1d,(%esp)
80103c93:	e8 09 c7 ff ff       	call   801003a1 <cprintf>
  picinit();       // interrupt controller
80103c98:	e8 95 06 00 00       	call   80104332 <picinit>
  ioapicinit();    // another interrupt controller
80103c9d:	e8 23 ec ff ff       	call   801028c5 <ioapicinit>
  consoleinit();   // I/O devices & their interrupts
80103ca2:	e8 e6 cd ff ff       	call   80100a8d <consoleinit>
  uartinit();      // serial port
80103ca7:	e8 9c 3f 00 00       	call   80107c48 <uartinit>
  pinit();         // process table
80103cac:	e8 a3 0b 00 00       	call   80104854 <pinit>
  tvinit();        // trap vectors
80103cb1:	e8 35 3b 00 00       	call   801077eb <tvinit>
  binit();         // buffer cache
80103cb6:	e8 79 c3 ff ff       	call   80100034 <binit>
  fileinit();      // file table
80103cbb:	e8 40 d2 ff ff       	call   80100f00 <fileinit>
  iinit();         // inode cache
80103cc0:	e8 ee d8 ff ff       	call   801015b3 <iinit>
  ideinit();       // disk
80103cc5:	e8 62 e8 ff ff       	call   8010252c <ideinit>
  if(!ismp)
80103cca:	a1 24 71 12 80       	mov    0x80127124,%eax
80103ccf:	85 c0                	test   %eax,%eax
80103cd1:	75 05                	jne    80103cd8 <main+0x95>
    timerinit();   // uniprocessor timer
80103cd3:	e8 56 3a 00 00       	call   8010772e <timerinit>
  startothers();   // start other processors
80103cd8:	e8 87 00 00 00       	call   80103d64 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80103cdd:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
80103ce4:	8e 
80103ce5:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
80103cec:	e8 29 ed ff ff       	call   80102a1a <kinit2>
  userinit();      // first user process
80103cf1:	e8 72 12 00 00       	call   80104f68 <userinit>
  // Finish setting up this processor in mpmain.
  mpmain();
80103cf6:	e8 22 00 00 00       	call   80103d1d <mpmain>

80103cfb <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
80103cfb:	55                   	push   %ebp
80103cfc:	89 e5                	mov    %esp,%ebp
80103cfe:	83 ec 18             	sub    $0x18,%esp
  switchkvm(); 
80103d01:	e8 6b 52 00 00       	call   80108f71 <switchkvm>
  seginit();
80103d06:	e8 f2 4b 00 00       	call   801088fd <seginit>
  lapicinit(cpunum());
80103d0b:	e8 b9 f9 ff ff       	call   801036c9 <cpunum>
80103d10:	89 04 24             	mov    %eax,(%esp)
80103d13:	e8 54 f8 ff ff       	call   8010356c <lapicinit>
  mpmain();
80103d18:	e8 00 00 00 00       	call   80103d1d <mpmain>

80103d1d <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
80103d1d:	55                   	push   %ebp
80103d1e:	89 e5                	mov    %esp,%ebp
80103d20:	83 ec 18             	sub    $0x18,%esp
  cprintf("cpu%d: starting\n", cpu->id);
80103d23:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103d29:	0f b6 00             	movzbl (%eax),%eax
80103d2c:	0f b6 c0             	movzbl %al,%eax
80103d2f:	89 44 24 04          	mov    %eax,0x4(%esp)
80103d33:	c7 04 24 34 9a 10 80 	movl   $0x80109a34,(%esp)
80103d3a:	e8 62 c6 ff ff       	call   801003a1 <cprintf>
  idtinit();       // load idt register
80103d3f:	e8 1b 3c 00 00       	call   8010795f <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
80103d44:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103d4a:	05 a8 00 00 00       	add    $0xa8,%eax
80103d4f:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80103d56:	00 
80103d57:	89 04 24             	mov    %eax,(%esp)
80103d5a:	e8 bf fe ff ff       	call   80103c1e <xchg>
  scheduler();     // start running processes
80103d5f:	e8 35 18 00 00       	call   80105599 <scheduler>

80103d64 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80103d64:	55                   	push   %ebp
80103d65:	89 e5                	mov    %esp,%ebp
80103d67:	53                   	push   %ebx
80103d68:	83 ec 24             	sub    $0x24,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
80103d6b:	c7 04 24 00 70 00 00 	movl   $0x7000,(%esp)
80103d72:	e8 9a fe ff ff       	call   80103c11 <p2v>
80103d77:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80103d7a:	b8 8a 00 00 00       	mov    $0x8a,%eax
80103d7f:	89 44 24 08          	mov    %eax,0x8(%esp)
80103d83:	c7 44 24 04 2c c5 10 	movl   $0x8010c52c,0x4(%esp)
80103d8a:	80 
80103d8b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d8e:	89 04 24             	mov    %eax,(%esp)
80103d91:	e8 7b 21 00 00       	call   80105f11 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80103d96:	c7 45 f4 40 71 12 80 	movl   $0x80127140,-0xc(%ebp)
80103d9d:	e9 86 00 00 00       	jmp    80103e28 <startothers+0xc4>
    if(c == cpus+cpunum())  // We've started already.
80103da2:	e8 22 f9 ff ff       	call   801036c9 <cpunum>
80103da7:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103dad:	05 40 71 12 80       	add    $0x80127140,%eax
80103db2:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103db5:	74 69                	je     80103e20 <startothers+0xbc>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what 
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
80103db7:	e8 54 ed ff ff       	call   80102b10 <kalloc>
80103dbc:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
80103dbf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103dc2:	83 e8 04             	sub    $0x4,%eax
80103dc5:	8b 55 ec             	mov    -0x14(%ebp),%edx
80103dc8:	81 c2 00 10 00 00    	add    $0x1000,%edx
80103dce:	89 10                	mov    %edx,(%eax)
    *(void**)(code-8) = mpenter;
80103dd0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103dd3:	83 e8 08             	sub    $0x8,%eax
80103dd6:	c7 00 fb 3c 10 80    	movl   $0x80103cfb,(%eax)
    *(int**)(code-12) = (void *) v2p(entrypgdir);
80103ddc:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103ddf:	8d 58 f4             	lea    -0xc(%eax),%ebx
80103de2:	c7 04 24 00 b0 10 80 	movl   $0x8010b000,(%esp)
80103de9:	e8 16 fe ff ff       	call   80103c04 <v2p>
80103dee:	89 03                	mov    %eax,(%ebx)

    lapicstartap(c->id, v2p(code));
80103df0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103df3:	89 04 24             	mov    %eax,(%esp)
80103df6:	e8 09 fe ff ff       	call   80103c04 <v2p>
80103dfb:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103dfe:	0f b6 12             	movzbl (%edx),%edx
80103e01:	0f b6 d2             	movzbl %dl,%edx
80103e04:	89 44 24 04          	mov    %eax,0x4(%esp)
80103e08:	89 14 24             	mov    %edx,(%esp)
80103e0b:	e8 3f f9 ff ff       	call   8010374f <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80103e10:	90                   	nop
80103e11:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103e14:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
80103e1a:	85 c0                	test   %eax,%eax
80103e1c:	74 f3                	je     80103e11 <startothers+0xad>
80103e1e:	eb 01                	jmp    80103e21 <startothers+0xbd>
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
    if(c == cpus+cpunum())  // We've started already.
      continue;
80103e20:	90                   	nop
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
80103e21:	81 45 f4 bc 00 00 00 	addl   $0xbc,-0xc(%ebp)
80103e28:	a1 20 77 12 80       	mov    0x80127720,%eax
80103e2d:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103e33:	05 40 71 12 80       	add    $0x80127140,%eax
80103e38:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103e3b:	0f 87 61 ff ff ff    	ja     80103da2 <startothers+0x3e>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;
  }
}
80103e41:	83 c4 24             	add    $0x24,%esp
80103e44:	5b                   	pop    %ebx
80103e45:	5d                   	pop    %ebp
80103e46:	c3                   	ret    
	...

80103e48 <p2v>:
80103e48:	55                   	push   %ebp
80103e49:	89 e5                	mov    %esp,%ebp
80103e4b:	8b 45 08             	mov    0x8(%ebp),%eax
80103e4e:	05 00 00 00 80       	add    $0x80000000,%eax
80103e53:	5d                   	pop    %ebp
80103e54:	c3                   	ret    

80103e55 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80103e55:	55                   	push   %ebp
80103e56:	89 e5                	mov    %esp,%ebp
80103e58:	53                   	push   %ebx
80103e59:	83 ec 14             	sub    $0x14,%esp
80103e5c:	8b 45 08             	mov    0x8(%ebp),%eax
80103e5f:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80103e63:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80103e67:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80103e6b:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80103e6f:	ec                   	in     (%dx),%al
80103e70:	89 c3                	mov    %eax,%ebx
80103e72:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80103e75:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80103e79:	83 c4 14             	add    $0x14,%esp
80103e7c:	5b                   	pop    %ebx
80103e7d:	5d                   	pop    %ebp
80103e7e:	c3                   	ret    

80103e7f <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103e7f:	55                   	push   %ebp
80103e80:	89 e5                	mov    %esp,%ebp
80103e82:	83 ec 08             	sub    $0x8,%esp
80103e85:	8b 55 08             	mov    0x8(%ebp),%edx
80103e88:	8b 45 0c             	mov    0xc(%ebp),%eax
80103e8b:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103e8f:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103e92:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103e96:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103e9a:	ee                   	out    %al,(%dx)
}
80103e9b:	c9                   	leave  
80103e9c:	c3                   	ret    

80103e9d <mpbcpu>:
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
80103e9d:	55                   	push   %ebp
80103e9e:	89 e5                	mov    %esp,%ebp
  return bcpu-cpus;
80103ea0:	a1 64 c6 10 80       	mov    0x8010c664,%eax
80103ea5:	89 c2                	mov    %eax,%edx
80103ea7:	b8 40 71 12 80       	mov    $0x80127140,%eax
80103eac:	89 d1                	mov    %edx,%ecx
80103eae:	29 c1                	sub    %eax,%ecx
80103eb0:	89 c8                	mov    %ecx,%eax
80103eb2:	c1 f8 02             	sar    $0x2,%eax
80103eb5:	69 c0 cf 46 7d 67    	imul   $0x677d46cf,%eax,%eax
}
80103ebb:	5d                   	pop    %ebp
80103ebc:	c3                   	ret    

80103ebd <sum>:

static uchar
sum(uchar *addr, int len)
{
80103ebd:	55                   	push   %ebp
80103ebe:	89 e5                	mov    %esp,%ebp
80103ec0:	83 ec 10             	sub    $0x10,%esp
  int i, sum;
  
  sum = 0;
80103ec3:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
80103eca:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80103ed1:	eb 13                	jmp    80103ee6 <sum+0x29>
    sum += addr[i];
80103ed3:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103ed6:	03 45 08             	add    0x8(%ebp),%eax
80103ed9:	0f b6 00             	movzbl (%eax),%eax
80103edc:	0f b6 c0             	movzbl %al,%eax
80103edf:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
80103ee2:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103ee6:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103ee9:	3b 45 0c             	cmp    0xc(%ebp),%eax
80103eec:	7c e5                	jl     80103ed3 <sum+0x16>
    sum += addr[i];
  return sum;
80103eee:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103ef1:	c9                   	leave  
80103ef2:	c3                   	ret    

80103ef3 <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80103ef3:	55                   	push   %ebp
80103ef4:	89 e5                	mov    %esp,%ebp
80103ef6:	83 ec 28             	sub    $0x28,%esp
  uchar *e, *p, *addr;

  addr = p2v(a);
80103ef9:	8b 45 08             	mov    0x8(%ebp),%eax
80103efc:	89 04 24             	mov    %eax,(%esp)
80103eff:	e8 44 ff ff ff       	call   80103e48 <p2v>
80103f04:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
80103f07:	8b 45 0c             	mov    0xc(%ebp),%eax
80103f0a:	03 45 f0             	add    -0x10(%ebp),%eax
80103f0d:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
80103f10:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103f13:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103f16:	eb 3f                	jmp    80103f57 <mpsearch1+0x64>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80103f18:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80103f1f:	00 
80103f20:	c7 44 24 04 48 9a 10 	movl   $0x80109a48,0x4(%esp)
80103f27:	80 
80103f28:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f2b:	89 04 24             	mov    %eax,(%esp)
80103f2e:	e8 82 1f 00 00       	call   80105eb5 <memcmp>
80103f33:	85 c0                	test   %eax,%eax
80103f35:	75 1c                	jne    80103f53 <mpsearch1+0x60>
80103f37:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
80103f3e:	00 
80103f3f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f42:	89 04 24             	mov    %eax,(%esp)
80103f45:	e8 73 ff ff ff       	call   80103ebd <sum>
80103f4a:	84 c0                	test   %al,%al
80103f4c:	75 05                	jne    80103f53 <mpsearch1+0x60>
      return (struct mp*)p;
80103f4e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f51:	eb 11                	jmp    80103f64 <mpsearch1+0x71>
{
  uchar *e, *p, *addr;

  addr = p2v(a);
  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
80103f53:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80103f57:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f5a:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103f5d:	72 b9                	jb     80103f18 <mpsearch1+0x25>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
80103f5f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103f64:	c9                   	leave  
80103f65:	c3                   	ret    

80103f66 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80103f66:	55                   	push   %ebp
80103f67:	89 e5                	mov    %esp,%ebp
80103f69:	83 ec 28             	sub    $0x28,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
80103f6c:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80103f73:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f76:	83 c0 0f             	add    $0xf,%eax
80103f79:	0f b6 00             	movzbl (%eax),%eax
80103f7c:	0f b6 c0             	movzbl %al,%eax
80103f7f:	89 c2                	mov    %eax,%edx
80103f81:	c1 e2 08             	shl    $0x8,%edx
80103f84:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f87:	83 c0 0e             	add    $0xe,%eax
80103f8a:	0f b6 00             	movzbl (%eax),%eax
80103f8d:	0f b6 c0             	movzbl %al,%eax
80103f90:	09 d0                	or     %edx,%eax
80103f92:	c1 e0 04             	shl    $0x4,%eax
80103f95:	89 45 f0             	mov    %eax,-0x10(%ebp)
80103f98:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103f9c:	74 21                	je     80103fbf <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
80103f9e:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80103fa5:	00 
80103fa6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103fa9:	89 04 24             	mov    %eax,(%esp)
80103fac:	e8 42 ff ff ff       	call   80103ef3 <mpsearch1>
80103fb1:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103fb4:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103fb8:	74 50                	je     8010400a <mpsearch+0xa4>
      return mp;
80103fba:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103fbd:	eb 5f                	jmp    8010401e <mpsearch+0xb8>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80103fbf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103fc2:	83 c0 14             	add    $0x14,%eax
80103fc5:	0f b6 00             	movzbl (%eax),%eax
80103fc8:	0f b6 c0             	movzbl %al,%eax
80103fcb:	89 c2                	mov    %eax,%edx
80103fcd:	c1 e2 08             	shl    $0x8,%edx
80103fd0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103fd3:	83 c0 13             	add    $0x13,%eax
80103fd6:	0f b6 00             	movzbl (%eax),%eax
80103fd9:	0f b6 c0             	movzbl %al,%eax
80103fdc:	09 d0                	or     %edx,%eax
80103fde:	c1 e0 0a             	shl    $0xa,%eax
80103fe1:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
80103fe4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103fe7:	2d 00 04 00 00       	sub    $0x400,%eax
80103fec:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80103ff3:	00 
80103ff4:	89 04 24             	mov    %eax,(%esp)
80103ff7:	e8 f7 fe ff ff       	call   80103ef3 <mpsearch1>
80103ffc:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103fff:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80104003:	74 05                	je     8010400a <mpsearch+0xa4>
      return mp;
80104005:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104008:	eb 14                	jmp    8010401e <mpsearch+0xb8>
  }
  return mpsearch1(0xF0000, 0x10000);
8010400a:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80104011:	00 
80104012:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
80104019:	e8 d5 fe ff ff       	call   80103ef3 <mpsearch1>
}
8010401e:	c9                   	leave  
8010401f:	c3                   	ret    

80104020 <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80104020:	55                   	push   %ebp
80104021:	89 e5                	mov    %esp,%ebp
80104023:	83 ec 28             	sub    $0x28,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80104026:	e8 3b ff ff ff       	call   80103f66 <mpsearch>
8010402b:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010402e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104032:	74 0a                	je     8010403e <mpconfig+0x1e>
80104034:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104037:	8b 40 04             	mov    0x4(%eax),%eax
8010403a:	85 c0                	test   %eax,%eax
8010403c:	75 0a                	jne    80104048 <mpconfig+0x28>
    return 0;
8010403e:	b8 00 00 00 00       	mov    $0x0,%eax
80104043:	e9 83 00 00 00       	jmp    801040cb <mpconfig+0xab>
  conf = (struct mpconf*) p2v((uint) mp->physaddr);
80104048:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010404b:	8b 40 04             	mov    0x4(%eax),%eax
8010404e:	89 04 24             	mov    %eax,(%esp)
80104051:	e8 f2 fd ff ff       	call   80103e48 <p2v>
80104056:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
80104059:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80104060:	00 
80104061:	c7 44 24 04 4d 9a 10 	movl   $0x80109a4d,0x4(%esp)
80104068:	80 
80104069:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010406c:	89 04 24             	mov    %eax,(%esp)
8010406f:	e8 41 1e 00 00       	call   80105eb5 <memcmp>
80104074:	85 c0                	test   %eax,%eax
80104076:	74 07                	je     8010407f <mpconfig+0x5f>
    return 0;
80104078:	b8 00 00 00 00       	mov    $0x0,%eax
8010407d:	eb 4c                	jmp    801040cb <mpconfig+0xab>
  if(conf->version != 1 && conf->version != 4)
8010407f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104082:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80104086:	3c 01                	cmp    $0x1,%al
80104088:	74 12                	je     8010409c <mpconfig+0x7c>
8010408a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010408d:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80104091:	3c 04                	cmp    $0x4,%al
80104093:	74 07                	je     8010409c <mpconfig+0x7c>
    return 0;
80104095:	b8 00 00 00 00       	mov    $0x0,%eax
8010409a:	eb 2f                	jmp    801040cb <mpconfig+0xab>
  if(sum((uchar*)conf, conf->length) != 0)
8010409c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010409f:	0f b7 40 04          	movzwl 0x4(%eax),%eax
801040a3:	0f b7 c0             	movzwl %ax,%eax
801040a6:	89 44 24 04          	mov    %eax,0x4(%esp)
801040aa:	8b 45 f0             	mov    -0x10(%ebp),%eax
801040ad:	89 04 24             	mov    %eax,(%esp)
801040b0:	e8 08 fe ff ff       	call   80103ebd <sum>
801040b5:	84 c0                	test   %al,%al
801040b7:	74 07                	je     801040c0 <mpconfig+0xa0>
    return 0;
801040b9:	b8 00 00 00 00       	mov    $0x0,%eax
801040be:	eb 0b                	jmp    801040cb <mpconfig+0xab>
  *pmp = mp;
801040c0:	8b 45 08             	mov    0x8(%ebp),%eax
801040c3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801040c6:	89 10                	mov    %edx,(%eax)
  return conf;
801040c8:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
801040cb:	c9                   	leave  
801040cc:	c3                   	ret    

801040cd <mpinit>:

void
mpinit(void)
{
801040cd:	55                   	push   %ebp
801040ce:	89 e5                	mov    %esp,%ebp
801040d0:	83 ec 38             	sub    $0x38,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
801040d3:	c7 05 64 c6 10 80 40 	movl   $0x80127140,0x8010c664
801040da:	71 12 80 
  if((conf = mpconfig(&mp)) == 0)
801040dd:	8d 45 e0             	lea    -0x20(%ebp),%eax
801040e0:	89 04 24             	mov    %eax,(%esp)
801040e3:	e8 38 ff ff ff       	call   80104020 <mpconfig>
801040e8:	89 45 f0             	mov    %eax,-0x10(%ebp)
801040eb:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801040ef:	0f 84 9c 01 00 00    	je     80104291 <mpinit+0x1c4>
    return;
  ismp = 1;
801040f5:	c7 05 24 71 12 80 01 	movl   $0x1,0x80127124
801040fc:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
801040ff:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104102:	8b 40 24             	mov    0x24(%eax),%eax
80104105:	a3 94 70 12 80       	mov    %eax,0x80127094
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
8010410a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010410d:	83 c0 2c             	add    $0x2c,%eax
80104110:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104113:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104116:	0f b7 40 04          	movzwl 0x4(%eax),%eax
8010411a:	0f b7 c0             	movzwl %ax,%eax
8010411d:	03 45 f0             	add    -0x10(%ebp),%eax
80104120:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104123:	e9 f4 00 00 00       	jmp    8010421c <mpinit+0x14f>
    switch(*p){
80104128:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010412b:	0f b6 00             	movzbl (%eax),%eax
8010412e:	0f b6 c0             	movzbl %al,%eax
80104131:	83 f8 04             	cmp    $0x4,%eax
80104134:	0f 87 bf 00 00 00    	ja     801041f9 <mpinit+0x12c>
8010413a:	8b 04 85 90 9a 10 80 	mov    -0x7fef6570(,%eax,4),%eax
80104141:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
80104143:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104146:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(ncpu != proc->apicid){
80104149:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010414c:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80104150:	0f b6 d0             	movzbl %al,%edx
80104153:	a1 20 77 12 80       	mov    0x80127720,%eax
80104158:	39 c2                	cmp    %eax,%edx
8010415a:	74 2d                	je     80104189 <mpinit+0xbc>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
8010415c:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010415f:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80104163:	0f b6 d0             	movzbl %al,%edx
80104166:	a1 20 77 12 80       	mov    0x80127720,%eax
8010416b:	89 54 24 08          	mov    %edx,0x8(%esp)
8010416f:	89 44 24 04          	mov    %eax,0x4(%esp)
80104173:	c7 04 24 52 9a 10 80 	movl   $0x80109a52,(%esp)
8010417a:	e8 22 c2 ff ff       	call   801003a1 <cprintf>
        ismp = 0;
8010417f:	c7 05 24 71 12 80 00 	movl   $0x0,0x80127124
80104186:	00 00 00 
      }
      if(proc->flags & MPBOOT)
80104189:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010418c:	0f b6 40 03          	movzbl 0x3(%eax),%eax
80104190:	0f b6 c0             	movzbl %al,%eax
80104193:	83 e0 02             	and    $0x2,%eax
80104196:	85 c0                	test   %eax,%eax
80104198:	74 15                	je     801041af <mpinit+0xe2>
        bcpu = &cpus[ncpu];
8010419a:	a1 20 77 12 80       	mov    0x80127720,%eax
8010419f:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801041a5:	05 40 71 12 80       	add    $0x80127140,%eax
801041aa:	a3 64 c6 10 80       	mov    %eax,0x8010c664
      cpus[ncpu].id = ncpu;
801041af:	8b 15 20 77 12 80    	mov    0x80127720,%edx
801041b5:	a1 20 77 12 80       	mov    0x80127720,%eax
801041ba:	69 d2 bc 00 00 00    	imul   $0xbc,%edx,%edx
801041c0:	81 c2 40 71 12 80    	add    $0x80127140,%edx
801041c6:	88 02                	mov    %al,(%edx)
      ncpu++;
801041c8:	a1 20 77 12 80       	mov    0x80127720,%eax
801041cd:	83 c0 01             	add    $0x1,%eax
801041d0:	a3 20 77 12 80       	mov    %eax,0x80127720
      p += sizeof(struct mpproc);
801041d5:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
801041d9:	eb 41                	jmp    8010421c <mpinit+0x14f>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
801041db:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041de:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      ioapicid = ioapic->apicno;
801041e1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801041e4:	0f b6 40 01          	movzbl 0x1(%eax),%eax
801041e8:	a2 20 71 12 80       	mov    %al,0x80127120
      p += sizeof(struct mpioapic);
801041ed:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
801041f1:	eb 29                	jmp    8010421c <mpinit+0x14f>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
801041f3:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
801041f7:	eb 23                	jmp    8010421c <mpinit+0x14f>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
801041f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041fc:	0f b6 00             	movzbl (%eax),%eax
801041ff:	0f b6 c0             	movzbl %al,%eax
80104202:	89 44 24 04          	mov    %eax,0x4(%esp)
80104206:	c7 04 24 70 9a 10 80 	movl   $0x80109a70,(%esp)
8010420d:	e8 8f c1 ff ff       	call   801003a1 <cprintf>
      ismp = 0;
80104212:	c7 05 24 71 12 80 00 	movl   $0x0,0x80127124
80104219:	00 00 00 
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
8010421c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010421f:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80104222:	0f 82 00 ff ff ff    	jb     80104128 <mpinit+0x5b>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
      ismp = 0;
    }
  }
  if(!ismp){
80104228:	a1 24 71 12 80       	mov    0x80127124,%eax
8010422d:	85 c0                	test   %eax,%eax
8010422f:	75 1d                	jne    8010424e <mpinit+0x181>
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
80104231:	c7 05 20 77 12 80 01 	movl   $0x1,0x80127720
80104238:	00 00 00 
    lapic = 0;
8010423b:	c7 05 94 70 12 80 00 	movl   $0x0,0x80127094
80104242:	00 00 00 
    ioapicid = 0;
80104245:	c6 05 20 71 12 80 00 	movb   $0x0,0x80127120
    return;
8010424c:	eb 44                	jmp    80104292 <mpinit+0x1c5>
  }

  if(mp->imcrp){
8010424e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104251:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
80104255:	84 c0                	test   %al,%al
80104257:	74 39                	je     80104292 <mpinit+0x1c5>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
80104259:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
80104260:	00 
80104261:	c7 04 24 22 00 00 00 	movl   $0x22,(%esp)
80104268:	e8 12 fc ff ff       	call   80103e7f <outb>
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
8010426d:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80104274:	e8 dc fb ff ff       	call   80103e55 <inb>
80104279:	83 c8 01             	or     $0x1,%eax
8010427c:	0f b6 c0             	movzbl %al,%eax
8010427f:	89 44 24 04          	mov    %eax,0x4(%esp)
80104283:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
8010428a:	e8 f0 fb ff ff       	call   80103e7f <outb>
8010428f:	eb 01                	jmp    80104292 <mpinit+0x1c5>
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
80104291:	90                   	nop
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
  }
}
80104292:	c9                   	leave  
80104293:	c3                   	ret    

80104294 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80104294:	55                   	push   %ebp
80104295:	89 e5                	mov    %esp,%ebp
80104297:	83 ec 08             	sub    $0x8,%esp
8010429a:	8b 55 08             	mov    0x8(%ebp),%edx
8010429d:	8b 45 0c             	mov    0xc(%ebp),%eax
801042a0:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801042a4:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801042a7:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801042ab:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801042af:	ee                   	out    %al,(%dx)
}
801042b0:	c9                   	leave  
801042b1:	c3                   	ret    

801042b2 <picsetmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static ushort irqmask = 0xFFFF & ~(1<<IRQ_SLAVE);

static void
picsetmask(ushort mask)
{
801042b2:	55                   	push   %ebp
801042b3:	89 e5                	mov    %esp,%ebp
801042b5:	83 ec 0c             	sub    $0xc,%esp
801042b8:	8b 45 08             	mov    0x8(%ebp),%eax
801042bb:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  irqmask = mask;
801042bf:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
801042c3:	66 a3 00 c0 10 80    	mov    %ax,0x8010c000
  outb(IO_PIC1+1, mask);
801042c9:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
801042cd:	0f b6 c0             	movzbl %al,%eax
801042d0:	89 44 24 04          	mov    %eax,0x4(%esp)
801042d4:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
801042db:	e8 b4 ff ff ff       	call   80104294 <outb>
  outb(IO_PIC2+1, mask >> 8);
801042e0:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
801042e4:	66 c1 e8 08          	shr    $0x8,%ax
801042e8:	0f b6 c0             	movzbl %al,%eax
801042eb:	89 44 24 04          	mov    %eax,0x4(%esp)
801042ef:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
801042f6:	e8 99 ff ff ff       	call   80104294 <outb>
}
801042fb:	c9                   	leave  
801042fc:	c3                   	ret    

801042fd <picenable>:

void
picenable(int irq)
{
801042fd:	55                   	push   %ebp
801042fe:	89 e5                	mov    %esp,%ebp
80104300:	53                   	push   %ebx
80104301:	83 ec 04             	sub    $0x4,%esp
  picsetmask(irqmask & ~(1<<irq));
80104304:	8b 45 08             	mov    0x8(%ebp),%eax
80104307:	ba 01 00 00 00       	mov    $0x1,%edx
8010430c:	89 d3                	mov    %edx,%ebx
8010430e:	89 c1                	mov    %eax,%ecx
80104310:	d3 e3                	shl    %cl,%ebx
80104312:	89 d8                	mov    %ebx,%eax
80104314:	89 c2                	mov    %eax,%edx
80104316:	f7 d2                	not    %edx
80104318:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
8010431f:	21 d0                	and    %edx,%eax
80104321:	0f b7 c0             	movzwl %ax,%eax
80104324:	89 04 24             	mov    %eax,(%esp)
80104327:	e8 86 ff ff ff       	call   801042b2 <picsetmask>
}
8010432c:	83 c4 04             	add    $0x4,%esp
8010432f:	5b                   	pop    %ebx
80104330:	5d                   	pop    %ebp
80104331:	c3                   	ret    

80104332 <picinit>:

// Initialize the 8259A interrupt controllers.
void
picinit(void)
{
80104332:	55                   	push   %ebp
80104333:	89 e5                	mov    %esp,%ebp
80104335:	83 ec 08             	sub    $0x8,%esp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
80104338:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
8010433f:	00 
80104340:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104347:	e8 48 ff ff ff       	call   80104294 <outb>
  outb(IO_PIC2+1, 0xFF);
8010434c:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80104353:	00 
80104354:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
8010435b:	e8 34 ff ff ff       	call   80104294 <outb>

  // ICW1:  0001g0hi
  //    g:  0 = edge triggering, 1 = level triggering
  //    h:  0 = cascaded PICs, 1 = master only
  //    i:  0 = no ICW4, 1 = ICW4 required
  outb(IO_PIC1, 0x11);
80104360:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80104367:	00 
80104368:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010436f:	e8 20 ff ff ff       	call   80104294 <outb>

  // ICW2:  Vector offset
  outb(IO_PIC1+1, T_IRQ0);
80104374:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
8010437b:	00 
8010437c:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104383:	e8 0c ff ff ff       	call   80104294 <outb>

  // ICW3:  (master PIC) bit mask of IR lines connected to slaves
  //        (slave PIC) 3-bit # of slave's connection to master
  outb(IO_PIC1+1, 1<<IRQ_SLAVE);
80104388:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
8010438f:	00 
80104390:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104397:	e8 f8 fe ff ff       	call   80104294 <outb>
  //    m:  0 = slave PIC, 1 = master PIC
  //      (ignored when b is 0, as the master/slave role
  //      can be hardwired).
  //    a:  1 = Automatic EOI mode
  //    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
  outb(IO_PIC1+1, 0x3);
8010439c:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
801043a3:	00 
801043a4:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
801043ab:	e8 e4 fe ff ff       	call   80104294 <outb>

  // Set up slave (8259A-2)
  outb(IO_PIC2, 0x11);                  // ICW1
801043b0:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
801043b7:	00 
801043b8:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
801043bf:	e8 d0 fe ff ff       	call   80104294 <outb>
  outb(IO_PIC2+1, T_IRQ0 + 8);      // ICW2
801043c4:	c7 44 24 04 28 00 00 	movl   $0x28,0x4(%esp)
801043cb:	00 
801043cc:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
801043d3:	e8 bc fe ff ff       	call   80104294 <outb>
  outb(IO_PIC2+1, IRQ_SLAVE);           // ICW3
801043d8:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
801043df:	00 
801043e0:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
801043e7:	e8 a8 fe ff ff       	call   80104294 <outb>
  // NB Automatic EOI mode doesn't tend to work on the slave.
  // Linux source code says it's "to be investigated".
  outb(IO_PIC2+1, 0x3);                 // ICW4
801043ec:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
801043f3:	00 
801043f4:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
801043fb:	e8 94 fe ff ff       	call   80104294 <outb>

  // OCW3:  0ef01prs
  //   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
  //    p:  0 = no polling, 1 = polling mode
  //   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
  outb(IO_PIC1, 0x68);             // clear specific mask
80104400:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80104407:	00 
80104408:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010440f:	e8 80 fe ff ff       	call   80104294 <outb>
  outb(IO_PIC1, 0x0a);             // read IRR by default
80104414:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
8010441b:	00 
8010441c:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80104423:	e8 6c fe ff ff       	call   80104294 <outb>

  outb(IO_PIC2, 0x68);             // OCW3
80104428:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
8010442f:	00 
80104430:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104437:	e8 58 fe ff ff       	call   80104294 <outb>
  outb(IO_PIC2, 0x0a);             // OCW3
8010443c:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80104443:	00 
80104444:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
8010444b:	e8 44 fe ff ff       	call   80104294 <outb>

  if(irqmask != 0xFFFF)
80104450:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
80104457:	66 83 f8 ff          	cmp    $0xffff,%ax
8010445b:	74 12                	je     8010446f <picinit+0x13d>
    picsetmask(irqmask);
8010445d:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
80104464:	0f b7 c0             	movzwl %ax,%eax
80104467:	89 04 24             	mov    %eax,(%esp)
8010446a:	e8 43 fe ff ff       	call   801042b2 <picsetmask>
}
8010446f:	c9                   	leave  
80104470:	c3                   	ret    
80104471:	00 00                	add    %al,(%eax)
	...

80104474 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80104474:	55                   	push   %ebp
80104475:	89 e5                	mov    %esp,%ebp
80104477:	83 ec 28             	sub    $0x28,%esp
  struct pipe *p;

  p = 0;
8010447a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
80104481:	8b 45 0c             	mov    0xc(%ebp),%eax
80104484:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
8010448a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010448d:	8b 10                	mov    (%eax),%edx
8010448f:	8b 45 08             	mov    0x8(%ebp),%eax
80104492:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80104494:	e8 83 ca ff ff       	call   80100f1c <filealloc>
80104499:	8b 55 08             	mov    0x8(%ebp),%edx
8010449c:	89 02                	mov    %eax,(%edx)
8010449e:	8b 45 08             	mov    0x8(%ebp),%eax
801044a1:	8b 00                	mov    (%eax),%eax
801044a3:	85 c0                	test   %eax,%eax
801044a5:	0f 84 c8 00 00 00    	je     80104573 <pipealloc+0xff>
801044ab:	e8 6c ca ff ff       	call   80100f1c <filealloc>
801044b0:	8b 55 0c             	mov    0xc(%ebp),%edx
801044b3:	89 02                	mov    %eax,(%edx)
801044b5:	8b 45 0c             	mov    0xc(%ebp),%eax
801044b8:	8b 00                	mov    (%eax),%eax
801044ba:	85 c0                	test   %eax,%eax
801044bc:	0f 84 b1 00 00 00    	je     80104573 <pipealloc+0xff>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
801044c2:	e8 49 e6 ff ff       	call   80102b10 <kalloc>
801044c7:	89 45 f4             	mov    %eax,-0xc(%ebp)
801044ca:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801044ce:	0f 84 9e 00 00 00    	je     80104572 <pipealloc+0xfe>
    goto bad;
  p->readopen = 1;
801044d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044d7:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
801044de:	00 00 00 
  p->writeopen = 1;
801044e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044e4:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
801044eb:	00 00 00 
  p->nwrite = 0;
801044ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044f1:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
801044f8:	00 00 00 
  p->nread = 0;
801044fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044fe:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80104505:	00 00 00 
  initlock(&p->lock, "pipe");
80104508:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010450b:	c7 44 24 04 a4 9a 10 	movl   $0x80109aa4,0x4(%esp)
80104512:	80 
80104513:	89 04 24             	mov    %eax,(%esp)
80104516:	e8 7b 16 00 00       	call   80105b96 <initlock>
  (*f0)->type = FD_PIPE;
8010451b:	8b 45 08             	mov    0x8(%ebp),%eax
8010451e:	8b 00                	mov    (%eax),%eax
80104520:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80104526:	8b 45 08             	mov    0x8(%ebp),%eax
80104529:	8b 00                	mov    (%eax),%eax
8010452b:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
8010452f:	8b 45 08             	mov    0x8(%ebp),%eax
80104532:	8b 00                	mov    (%eax),%eax
80104534:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80104538:	8b 45 08             	mov    0x8(%ebp),%eax
8010453b:	8b 00                	mov    (%eax),%eax
8010453d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104540:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
80104543:	8b 45 0c             	mov    0xc(%ebp),%eax
80104546:	8b 00                	mov    (%eax),%eax
80104548:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
8010454e:	8b 45 0c             	mov    0xc(%ebp),%eax
80104551:	8b 00                	mov    (%eax),%eax
80104553:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80104557:	8b 45 0c             	mov    0xc(%ebp),%eax
8010455a:	8b 00                	mov    (%eax),%eax
8010455c:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80104560:	8b 45 0c             	mov    0xc(%ebp),%eax
80104563:	8b 00                	mov    (%eax),%eax
80104565:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104568:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
8010456b:	b8 00 00 00 00       	mov    $0x0,%eax
80104570:	eb 43                	jmp    801045b5 <pipealloc+0x141>
  p = 0;
  *f0 = *f1 = 0;
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
    goto bad;
80104572:	90                   	nop
  (*f1)->pipe = p;
  return 0;

//PAGEBREAK: 20
 bad:
  if(p)
80104573:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104577:	74 0b                	je     80104584 <pipealloc+0x110>
    kfree((char*)p);
80104579:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010457c:	89 04 24             	mov    %eax,(%esp)
8010457f:	e8 f3 e4 ff ff       	call   80102a77 <kfree>
  if(*f0)
80104584:	8b 45 08             	mov    0x8(%ebp),%eax
80104587:	8b 00                	mov    (%eax),%eax
80104589:	85 c0                	test   %eax,%eax
8010458b:	74 0d                	je     8010459a <pipealloc+0x126>
    fileclose(*f0);
8010458d:	8b 45 08             	mov    0x8(%ebp),%eax
80104590:	8b 00                	mov    (%eax),%eax
80104592:	89 04 24             	mov    %eax,(%esp)
80104595:	e8 2a ca ff ff       	call   80100fc4 <fileclose>
  if(*f1)
8010459a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010459d:	8b 00                	mov    (%eax),%eax
8010459f:	85 c0                	test   %eax,%eax
801045a1:	74 0d                	je     801045b0 <pipealloc+0x13c>
    fileclose(*f1);
801045a3:	8b 45 0c             	mov    0xc(%ebp),%eax
801045a6:	8b 00                	mov    (%eax),%eax
801045a8:	89 04 24             	mov    %eax,(%esp)
801045ab:	e8 14 ca ff ff       	call   80100fc4 <fileclose>
  return -1;
801045b0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801045b5:	c9                   	leave  
801045b6:	c3                   	ret    

801045b7 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
801045b7:	55                   	push   %ebp
801045b8:	89 e5                	mov    %esp,%ebp
801045ba:	83 ec 18             	sub    $0x18,%esp
  acquire(&p->lock);
801045bd:	8b 45 08             	mov    0x8(%ebp),%eax
801045c0:	89 04 24             	mov    %eax,(%esp)
801045c3:	e8 ef 15 00 00       	call   80105bb7 <acquire>
  if(writable){
801045c8:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801045cc:	74 1f                	je     801045ed <pipeclose+0x36>
    p->writeopen = 0;
801045ce:	8b 45 08             	mov    0x8(%ebp),%eax
801045d1:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
801045d8:	00 00 00 
    wakeup(&p->nread);
801045db:	8b 45 08             	mov    0x8(%ebp),%eax
801045de:	05 34 02 00 00       	add    $0x234,%eax
801045e3:	89 04 24             	mov    %eax,(%esp)
801045e6:	e8 cc 12 00 00       	call   801058b7 <wakeup>
801045eb:	eb 1d                	jmp    8010460a <pipeclose+0x53>
  } else {
    p->readopen = 0;
801045ed:	8b 45 08             	mov    0x8(%ebp),%eax
801045f0:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
801045f7:	00 00 00 
    wakeup(&p->nwrite);
801045fa:	8b 45 08             	mov    0x8(%ebp),%eax
801045fd:	05 38 02 00 00       	add    $0x238,%eax
80104602:	89 04 24             	mov    %eax,(%esp)
80104605:	e8 ad 12 00 00       	call   801058b7 <wakeup>
  }
  if(p->readopen == 0 && p->writeopen == 0){
8010460a:	8b 45 08             	mov    0x8(%ebp),%eax
8010460d:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80104613:	85 c0                	test   %eax,%eax
80104615:	75 25                	jne    8010463c <pipeclose+0x85>
80104617:	8b 45 08             	mov    0x8(%ebp),%eax
8010461a:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80104620:	85 c0                	test   %eax,%eax
80104622:	75 18                	jne    8010463c <pipeclose+0x85>
    release(&p->lock);
80104624:	8b 45 08             	mov    0x8(%ebp),%eax
80104627:	89 04 24             	mov    %eax,(%esp)
8010462a:	e8 23 16 00 00       	call   80105c52 <release>
    kfree((char*)p);
8010462f:	8b 45 08             	mov    0x8(%ebp),%eax
80104632:	89 04 24             	mov    %eax,(%esp)
80104635:	e8 3d e4 ff ff       	call   80102a77 <kfree>
8010463a:	eb 0b                	jmp    80104647 <pipeclose+0x90>
  } else
    release(&p->lock);
8010463c:	8b 45 08             	mov    0x8(%ebp),%eax
8010463f:	89 04 24             	mov    %eax,(%esp)
80104642:	e8 0b 16 00 00       	call   80105c52 <release>
}
80104647:	c9                   	leave  
80104648:	c3                   	ret    

80104649 <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
80104649:	55                   	push   %ebp
8010464a:	89 e5                	mov    %esp,%ebp
8010464c:	53                   	push   %ebx
8010464d:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80104650:	8b 45 08             	mov    0x8(%ebp),%eax
80104653:	89 04 24             	mov    %eax,(%esp)
80104656:	e8 5c 15 00 00       	call   80105bb7 <acquire>
  for(i = 0; i < n; i++){
8010465b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104662:	e9 a6 00 00 00       	jmp    8010470d <pipewrite+0xc4>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
      if(p->readopen == 0 || proc->killed){
80104667:	8b 45 08             	mov    0x8(%ebp),%eax
8010466a:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80104670:	85 c0                	test   %eax,%eax
80104672:	74 0d                	je     80104681 <pipewrite+0x38>
80104674:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010467a:	8b 40 24             	mov    0x24(%eax),%eax
8010467d:	85 c0                	test   %eax,%eax
8010467f:	74 15                	je     80104696 <pipewrite+0x4d>
        release(&p->lock);
80104681:	8b 45 08             	mov    0x8(%ebp),%eax
80104684:	89 04 24             	mov    %eax,(%esp)
80104687:	e8 c6 15 00 00       	call   80105c52 <release>
        return -1;
8010468c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104691:	e9 9d 00 00 00       	jmp    80104733 <pipewrite+0xea>
      }
      wakeup(&p->nread);
80104696:	8b 45 08             	mov    0x8(%ebp),%eax
80104699:	05 34 02 00 00       	add    $0x234,%eax
8010469e:	89 04 24             	mov    %eax,(%esp)
801046a1:	e8 11 12 00 00       	call   801058b7 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
801046a6:	8b 45 08             	mov    0x8(%ebp),%eax
801046a9:	8b 55 08             	mov    0x8(%ebp),%edx
801046ac:	81 c2 38 02 00 00    	add    $0x238,%edx
801046b2:	89 44 24 04          	mov    %eax,0x4(%esp)
801046b6:	89 14 24             	mov    %edx,(%esp)
801046b9:	e8 87 10 00 00       	call   80105745 <sleep>
801046be:	eb 01                	jmp    801046c1 <pipewrite+0x78>
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
801046c0:	90                   	nop
801046c1:	8b 45 08             	mov    0x8(%ebp),%eax
801046c4:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
801046ca:	8b 45 08             	mov    0x8(%ebp),%eax
801046cd:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
801046d3:	05 00 02 00 00       	add    $0x200,%eax
801046d8:	39 c2                	cmp    %eax,%edx
801046da:	74 8b                	je     80104667 <pipewrite+0x1e>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
801046dc:	8b 45 08             	mov    0x8(%ebp),%eax
801046df:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
801046e5:	89 c3                	mov    %eax,%ebx
801046e7:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
801046ed:	8b 55 f4             	mov    -0xc(%ebp),%edx
801046f0:	03 55 0c             	add    0xc(%ebp),%edx
801046f3:	0f b6 0a             	movzbl (%edx),%ecx
801046f6:	8b 55 08             	mov    0x8(%ebp),%edx
801046f9:	88 4c 1a 34          	mov    %cl,0x34(%edx,%ebx,1)
801046fd:	8d 50 01             	lea    0x1(%eax),%edx
80104700:	8b 45 08             	mov    0x8(%ebp),%eax
80104703:	89 90 38 02 00 00    	mov    %edx,0x238(%eax)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
80104709:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010470d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104710:	3b 45 10             	cmp    0x10(%ebp),%eax
80104713:	7c ab                	jl     801046c0 <pipewrite+0x77>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
80104715:	8b 45 08             	mov    0x8(%ebp),%eax
80104718:	05 34 02 00 00       	add    $0x234,%eax
8010471d:	89 04 24             	mov    %eax,(%esp)
80104720:	e8 92 11 00 00       	call   801058b7 <wakeup>
  release(&p->lock);
80104725:	8b 45 08             	mov    0x8(%ebp),%eax
80104728:	89 04 24             	mov    %eax,(%esp)
8010472b:	e8 22 15 00 00       	call   80105c52 <release>
  return n;
80104730:	8b 45 10             	mov    0x10(%ebp),%eax
}
80104733:	83 c4 24             	add    $0x24,%esp
80104736:	5b                   	pop    %ebx
80104737:	5d                   	pop    %ebp
80104738:	c3                   	ret    

80104739 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
80104739:	55                   	push   %ebp
8010473a:	89 e5                	mov    %esp,%ebp
8010473c:	53                   	push   %ebx
8010473d:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80104740:	8b 45 08             	mov    0x8(%ebp),%eax
80104743:	89 04 24             	mov    %eax,(%esp)
80104746:	e8 6c 14 00 00       	call   80105bb7 <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
8010474b:	eb 3a                	jmp    80104787 <piperead+0x4e>
    if(proc->killed){
8010474d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104753:	8b 40 24             	mov    0x24(%eax),%eax
80104756:	85 c0                	test   %eax,%eax
80104758:	74 15                	je     8010476f <piperead+0x36>
      release(&p->lock);
8010475a:	8b 45 08             	mov    0x8(%ebp),%eax
8010475d:	89 04 24             	mov    %eax,(%esp)
80104760:	e8 ed 14 00 00       	call   80105c52 <release>
      return -1;
80104765:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010476a:	e9 b6 00 00 00       	jmp    80104825 <piperead+0xec>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
8010476f:	8b 45 08             	mov    0x8(%ebp),%eax
80104772:	8b 55 08             	mov    0x8(%ebp),%edx
80104775:	81 c2 34 02 00 00    	add    $0x234,%edx
8010477b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010477f:	89 14 24             	mov    %edx,(%esp)
80104782:	e8 be 0f 00 00       	call   80105745 <sleep>
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80104787:	8b 45 08             	mov    0x8(%ebp),%eax
8010478a:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80104790:	8b 45 08             	mov    0x8(%ebp),%eax
80104793:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104799:	39 c2                	cmp    %eax,%edx
8010479b:	75 0d                	jne    801047aa <piperead+0x71>
8010479d:	8b 45 08             	mov    0x8(%ebp),%eax
801047a0:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
801047a6:	85 c0                	test   %eax,%eax
801047a8:	75 a3                	jne    8010474d <piperead+0x14>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801047aa:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801047b1:	eb 49                	jmp    801047fc <piperead+0xc3>
    if(p->nread == p->nwrite)
801047b3:	8b 45 08             	mov    0x8(%ebp),%eax
801047b6:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
801047bc:	8b 45 08             	mov    0x8(%ebp),%eax
801047bf:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
801047c5:	39 c2                	cmp    %eax,%edx
801047c7:	74 3d                	je     80104806 <piperead+0xcd>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
801047c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047cc:	89 c2                	mov    %eax,%edx
801047ce:	03 55 0c             	add    0xc(%ebp),%edx
801047d1:	8b 45 08             	mov    0x8(%ebp),%eax
801047d4:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
801047da:	89 c3                	mov    %eax,%ebx
801047dc:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
801047e2:	8b 4d 08             	mov    0x8(%ebp),%ecx
801047e5:	0f b6 4c 19 34       	movzbl 0x34(%ecx,%ebx,1),%ecx
801047ea:	88 0a                	mov    %cl,(%edx)
801047ec:	8d 50 01             	lea    0x1(%eax),%edx
801047ef:	8b 45 08             	mov    0x8(%ebp),%eax
801047f2:	89 90 34 02 00 00    	mov    %edx,0x234(%eax)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801047f8:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801047fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047ff:	3b 45 10             	cmp    0x10(%ebp),%eax
80104802:	7c af                	jl     801047b3 <piperead+0x7a>
80104804:	eb 01                	jmp    80104807 <piperead+0xce>
    if(p->nread == p->nwrite)
      break;
80104806:	90                   	nop
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
80104807:	8b 45 08             	mov    0x8(%ebp),%eax
8010480a:	05 38 02 00 00       	add    $0x238,%eax
8010480f:	89 04 24             	mov    %eax,(%esp)
80104812:	e8 a0 10 00 00       	call   801058b7 <wakeup>
  release(&p->lock);
80104817:	8b 45 08             	mov    0x8(%ebp),%eax
8010481a:	89 04 24             	mov    %eax,(%esp)
8010481d:	e8 30 14 00 00       	call   80105c52 <release>
  return i;
80104822:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104825:	83 c4 24             	add    $0x24,%esp
80104828:	5b                   	pop    %ebx
80104829:	5d                   	pop    %ebp
8010482a:	c3                   	ret    
	...

8010482c <p2v>:
8010482c:	55                   	push   %ebp
8010482d:	89 e5                	mov    %esp,%ebp
8010482f:	8b 45 08             	mov    0x8(%ebp),%eax
80104832:	05 00 00 00 80       	add    $0x80000000,%eax
80104837:	5d                   	pop    %ebp
80104838:	c3                   	ret    

80104839 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80104839:	55                   	push   %ebp
8010483a:	89 e5                	mov    %esp,%ebp
8010483c:	53                   	push   %ebx
8010483d:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80104840:	9c                   	pushf  
80104841:	5b                   	pop    %ebx
80104842:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80104845:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80104848:	83 c4 10             	add    $0x10,%esp
8010484b:	5b                   	pop    %ebx
8010484c:	5d                   	pop    %ebp
8010484d:	c3                   	ret    

8010484e <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
8010484e:	55                   	push   %ebp
8010484f:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80104851:	fb                   	sti    
}
80104852:	5d                   	pop    %ebp
80104853:	c3                   	ret    

80104854 <pinit>:

static void wakeup1(void *chan);

void
pinit(void)
{
80104854:	55                   	push   %ebp
80104855:	89 e5                	mov    %esp,%ebp
80104857:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
8010485a:	c7 44 24 04 a9 9a 10 	movl   $0x80109aa9,0x4(%esp)
80104861:	80 
80104862:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
80104869:	e8 28 13 00 00       	call   80105b96 <initlock>
  initlock(&swaplock, "swaplock");
8010486e:	c7 44 24 04 b0 9a 10 	movl   $0x80109ab0,0x4(%esp)
80104875:	80 
80104876:	c7 04 24 a0 c6 10 80 	movl   $0x8010c6a0,(%esp)
8010487d:	e8 14 13 00 00       	call   80105b96 <initlock>
}
80104882:	c9                   	leave  
80104883:	c3                   	ret    

80104884 <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
80104884:	55                   	push   %ebp
80104885:	89 e5                	mov    %esp,%ebp
80104887:	83 ec 38             	sub    $0x38,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
8010488a:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
80104891:	e8 21 13 00 00       	call   80105bb7 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104896:	c7 45 f4 74 77 12 80 	movl   $0x80127774,-0xc(%ebp)
8010489d:	eb 11                	jmp    801048b0 <allocproc+0x2c>
    if(p->state == UNUSED)
8010489f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048a2:	8b 40 0c             	mov    0xc(%eax),%eax
801048a5:	85 c0                	test   %eax,%eax
801048a7:	74 26                	je     801048cf <allocproc+0x4b>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801048a9:	81 45 f4 90 00 00 00 	addl   $0x90,-0xc(%ebp)
801048b0:	81 7d f4 74 9b 12 80 	cmpl   $0x80129b74,-0xc(%ebp)
801048b7:	72 e6                	jb     8010489f <allocproc+0x1b>
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
801048b9:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
801048c0:	e8 8d 13 00 00       	call   80105c52 <release>
  return 0;
801048c5:	b8 00 00 00 00       	mov    $0x0,%eax
801048ca:	e9 5a 01 00 00       	jmp    80104a29 <allocproc+0x1a5>
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
    if(p->state == UNUSED)
      goto found;
801048cf:	90                   	nop
  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
801048d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048d3:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
  p->pid = nextpid++;
801048da:	a1 04 c0 10 80       	mov    0x8010c004,%eax
801048df:	8b 55 f4             	mov    -0xc(%ebp),%edx
801048e2:	89 42 10             	mov    %eax,0x10(%edx)
801048e5:	83 c0 01             	add    $0x1,%eax
801048e8:	a3 04 c0 10 80       	mov    %eax,0x8010c004
  release(&ptable.lock);
801048ed:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
801048f4:	e8 59 13 00 00       	call   80105c52 <release>

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
801048f9:	e8 12 e2 ff ff       	call   80102b10 <kalloc>
801048fe:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104901:	89 42 08             	mov    %eax,0x8(%edx)
80104904:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104907:	8b 40 08             	mov    0x8(%eax),%eax
8010490a:	85 c0                	test   %eax,%eax
8010490c:	75 14                	jne    80104922 <allocproc+0x9e>
    p->state = UNUSED;
8010490e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104911:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return 0;
80104918:	b8 00 00 00 00       	mov    $0x0,%eax
8010491d:	e9 07 01 00 00       	jmp    80104a29 <allocproc+0x1a5>
  }
  sp = p->kstack + KSTACKSIZE;
80104922:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104925:	8b 40 08             	mov    0x8(%eax),%eax
80104928:	05 00 10 00 00       	add    $0x1000,%eax
8010492d:	89 45 f0             	mov    %eax,-0x10(%ebp)
  
  // Leave room for trap frame.
  sp -= sizeof *p->tf;
80104930:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
  p->tf = (struct trapframe*)sp;
80104934:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104937:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010493a:	89 50 18             	mov    %edx,0x18(%eax)
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
8010493d:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
  *(uint*)sp = (uint)trapret;
80104941:	ba a0 77 10 80       	mov    $0x801077a0,%edx
80104946:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104949:	89 10                	mov    %edx,(%eax)

  sp -= sizeof *p->context;
8010494b:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
  p->context = (struct context*)sp;
8010494f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104952:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104955:	89 50 1c             	mov    %edx,0x1c(%eax)
  memset(p->context, 0, sizeof *p->context);
80104958:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010495b:	8b 40 1c             	mov    0x1c(%eax),%eax
8010495e:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80104965:	00 
80104966:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010496d:	00 
8010496e:	89 04 24             	mov    %eax,(%esp)
80104971:	e8 c8 14 00 00       	call   80105e3e <memset>
  p->context->eip = (uint)forkret;
80104976:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104979:	8b 40 1c             	mov    0x1c(%eax),%eax
8010497c:	ba 19 57 10 80       	mov    $0x80105719,%edx
80104981:	89 50 10             	mov    %edx,0x10(%eax)
  int i = 0;
80104984:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  char name[8];
  name[2] = '.'; name[3] = 's'; name[4] = 'w'; name[5] = 'a'; name[6] = 'p'; name[7] = 0;
8010498b:	c6 45 e6 2e          	movb   $0x2e,-0x1a(%ebp)
8010498f:	c6 45 e7 73          	movb   $0x73,-0x19(%ebp)
80104993:	c6 45 e8 77          	movb   $0x77,-0x18(%ebp)
80104997:	c6 45 e9 61          	movb   $0x61,-0x17(%ebp)
8010499b:	c6 45 ea 70          	movb   $0x70,-0x16(%ebp)
8010499f:	c6 45 eb 00          	movb   $0x0,-0x15(%ebp)
  name[1] = (char)(((int)'0')+p->pid % 10);
801049a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049a6:	8b 48 10             	mov    0x10(%eax),%ecx
801049a9:	ba 67 66 66 66       	mov    $0x66666667,%edx
801049ae:	89 c8                	mov    %ecx,%eax
801049b0:	f7 ea                	imul   %edx
801049b2:	c1 fa 02             	sar    $0x2,%edx
801049b5:	89 c8                	mov    %ecx,%eax
801049b7:	c1 f8 1f             	sar    $0x1f,%eax
801049ba:	29 c2                	sub    %eax,%edx
801049bc:	89 d0                	mov    %edx,%eax
801049be:	c1 e0 02             	shl    $0x2,%eax
801049c1:	01 d0                	add    %edx,%eax
801049c3:	01 c0                	add    %eax,%eax
801049c5:	89 ca                	mov    %ecx,%edx
801049c7:	29 c2                	sub    %eax,%edx
801049c9:	89 d0                	mov    %edx,%eax
801049cb:	83 c0 30             	add    $0x30,%eax
801049ce:	88 45 e5             	mov    %al,-0x1b(%ebp)
  if((i=p->pid/10) == 0)
801049d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049d4:	8b 48 10             	mov    0x10(%eax),%ecx
801049d7:	ba 67 66 66 66       	mov    $0x66666667,%edx
801049dc:	89 c8                	mov    %ecx,%eax
801049de:	f7 ea                	imul   %edx
801049e0:	c1 fa 02             	sar    $0x2,%edx
801049e3:	89 c8                	mov    %ecx,%eax
801049e5:	c1 f8 1f             	sar    $0x1f,%eax
801049e8:	89 d1                	mov    %edx,%ecx
801049ea:	29 c1                	sub    %eax,%ecx
801049ec:	89 c8                	mov    %ecx,%eax
801049ee:	89 45 ec             	mov    %eax,-0x14(%ebp)
801049f1:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801049f5:	75 06                	jne    801049fd <allocproc+0x179>
    name[0] = '0';
801049f7:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
801049fb:	eb 09                	jmp    80104a06 <allocproc+0x182>
  else
    name[0] = (char)(((int)'0')+i);
801049fd:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104a00:	83 c0 30             	add    $0x30,%eax
80104a03:	88 45 e4             	mov    %al,-0x1c(%ebp)
  //release(&ptable.lock);
  safestrcpy(p->swapFileName, name, sizeof(name));
80104a06:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a09:	8d 90 80 00 00 00    	lea    0x80(%eax),%edx
80104a0f:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
80104a16:	00 
80104a17:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80104a1a:	89 44 24 04          	mov    %eax,0x4(%esp)
80104a1e:	89 14 24             	mov    %edx,(%esp)
80104a21:	e8 48 16 00 00       	call   8010606e <safestrcpy>
  return p;
80104a26:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104a29:	c9                   	leave  
80104a2a:	c3                   	ret    

80104a2b <createInternalProcess>:


void createInternalProcess(const char *name, void (*entrypoint)())
{
80104a2b:	55                   	push   %ebp
80104a2c:	89 e5                	mov    %esp,%ebp
80104a2e:	83 ec 28             	sub    $0x28,%esp
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
80104a31:	e8 4e fe ff ff       	call   80104884 <allocproc>
80104a36:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104a39:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104a3d:	0f 84 f7 00 00 00    	je     80104b3a <createInternalProcess+0x10f>
    return;

  // Copy process state from p.
  if((np->pgdir = setupkvm(kalloc)) == 0)
80104a43:	c7 04 24 10 2b 10 80 	movl   $0x80102b10,(%esp)
80104a4a:	e8 4e 44 00 00       	call   80108e9d <setupkvm>
80104a4f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104a52:	89 42 04             	mov    %eax,0x4(%edx)
80104a55:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a58:	8b 40 04             	mov    0x4(%eax),%eax
80104a5b:	85 c0                	test   %eax,%eax
80104a5d:	75 0c                	jne    80104a6b <createInternalProcess+0x40>
      panic("inswapper: out of memory?");
80104a5f:	c7 04 24 b9 9a 10 80 	movl   $0x80109ab9,(%esp)
80104a66:	e8 d2 ba ff ff       	call   8010053d <panic>

  np->sz = PGSIZE;
80104a6b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a6e:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  np->parent = initproc;
80104a74:	8b 15 88 c6 10 80    	mov    0x8010c688,%edx
80104a7a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a7d:	89 50 14             	mov    %edx,0x14(%eax)
  memset(np->tf, 0, sizeof(*np->tf));
80104a80:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a83:	8b 40 18             	mov    0x18(%eax),%eax
80104a86:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
80104a8d:	00 
80104a8e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104a95:	00 
80104a96:	89 04 24             	mov    %eax,(%esp)
80104a99:	e8 a0 13 00 00       	call   80105e3e <memset>
  np->tf->cs = (SEG_KCODE << 3)|0;
80104a9e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104aa1:	8b 40 18             	mov    0x18(%eax),%eax
80104aa4:	66 c7 40 3c 08 00    	movw   $0x8,0x3c(%eax)
  np->tf->ds = (SEG_KDATA << 3)|0;
80104aaa:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104aad:	8b 40 18             	mov    0x18(%eax),%eax
80104ab0:	66 c7 40 2c 10 00    	movw   $0x10,0x2c(%eax)
  np->tf->es = np->tf->ds;
80104ab6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ab9:	8b 40 18             	mov    0x18(%eax),%eax
80104abc:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104abf:	8b 52 18             	mov    0x18(%edx),%edx
80104ac2:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104ac6:	66 89 50 28          	mov    %dx,0x28(%eax)
  np->tf->ss = np->tf->ds;
80104aca:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104acd:	8b 40 18             	mov    0x18(%eax),%eax
80104ad0:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104ad3:	8b 52 18             	mov    0x18(%edx),%edx
80104ad6:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104ada:	66 89 50 48          	mov    %dx,0x48(%eax)
  np->tf->eflags = FL_IF;
80104ade:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ae1:	8b 40 18             	mov    0x18(%eax),%eax
80104ae4:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  //np->tf->esp = (uint)entrypoint+PGSIZE;
  //np->tf->eip = (uint)entrypoint;
  np->context->eip = (uint)entrypoint;
80104aeb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104aee:	8b 40 1c             	mov    0x1c(%eax),%eax
80104af1:	8b 55 0c             	mov    0xc(%ebp),%edx
80104af4:	89 50 10             	mov    %edx,0x10(%eax)

  inswapper = np;
80104af7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104afa:	a3 8c c6 10 80       	mov    %eax,0x8010c68c
  np->cwd = namei("/");
80104aff:	c7 04 24 d3 9a 10 80 	movl   $0x80109ad3,(%esp)
80104b06:	e8 ff d8 ff ff       	call   8010240a <namei>
80104b0b:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104b0e:	89 42 68             	mov    %eax,0x68(%edx)
  safestrcpy(np->name, name, sizeof(name));
80104b11:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b14:	8d 50 6c             	lea    0x6c(%eax),%edx
80104b17:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80104b1e:	00 
80104b1f:	8b 45 08             	mov    0x8(%ebp),%eax
80104b22:	89 44 24 04          	mov    %eax,0x4(%esp)
80104b26:	89 14 24             	mov    %edx,(%esp)
80104b29:	e8 40 15 00 00       	call   8010606e <safestrcpy>
  np->state = RUNNABLE;
80104b2e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b31:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
80104b38:	eb 01                	jmp    80104b3b <createInternalProcess+0x110>
{
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
    return;
80104b3a:	90                   	nop

  inswapper = np;
  np->cwd = namei("/");
  safestrcpy(np->name, name, sizeof(name));
  np->state = RUNNABLE;
}
80104b3b:	c9                   	leave  
80104b3c:	c3                   	ret    

80104b3d <swapIn>:

void swapIn()
{
80104b3d:	55                   	push   %ebp
80104b3e:	89 e5                	mov    %esp,%ebp
80104b40:	83 ec 38             	sub    $0x38,%esp
  struct proc* t;
  for(;;)
  {
swapin:
    for(t = ptable.proc; t < &ptable.proc[NPROC]; t++)
80104b43:	c7 45 f4 74 77 12 80 	movl   $0x80127774,-0xc(%ebp)
80104b4a:	e9 ff 01 00 00       	jmp    80104d4e <swapIn+0x211>
    {
      if(t->state != RUNNABLE_SUSPENDED)
80104b4f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b52:	8b 40 0c             	mov    0xc(%eax),%eax
80104b55:	83 f8 07             	cmp    $0x7,%eax
80104b58:	0f 85 e8 01 00 00    	jne    80104d46 <swapIn+0x209>
	continue;
      
      //open file pid.swap
      if(holding(&ptable.lock))
80104b5e:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
80104b65:	e8 a4 11 00 00       	call   80105d0e <holding>
80104b6a:	85 c0                	test   %eax,%eax
80104b6c:	74 0c                	je     80104b7a <swapIn+0x3d>
	release(&ptable.lock);
80104b6e:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
80104b75:	e8 d8 10 00 00       	call   80105c52 <release>
      if((t->swap = fileopen(t->swapFileName,O_RDONLY)) == 0)
80104b7a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b7d:	83 e8 80             	sub    $0xffffff80,%eax
80104b80:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104b87:	00 
80104b88:	89 04 24             	mov    %eax,(%esp)
80104b8b:	e8 8f 21 00 00       	call   80106d1f <fileopen>
80104b90:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104b93:	89 42 7c             	mov    %eax,0x7c(%edx)
80104b96:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b99:	8b 40 7c             	mov    0x7c(%eax),%eax
80104b9c:	85 c0                	test   %eax,%eax
80104b9e:	75 1d                	jne    80104bbd <swapIn+0x80>
      {
	cprintf("fileopen failed\n");
80104ba0:	c7 04 24 d5 9a 10 80 	movl   $0x80109ad5,(%esp)
80104ba7:	e8 f5 b7 ff ff       	call   801003a1 <cprintf>
	acquire(&ptable.lock);
80104bac:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
80104bb3:	e8 ff 0f 00 00       	call   80105bb7 <acquire>
	break;
80104bb8:	e9 9e 01 00 00       	jmp    80104d5b <swapIn+0x21e>
      }
      acquire(&ptable.lock);
80104bbd:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
80104bc4:	e8 ee 0f 00 00       	call   80105bb7 <acquire>
            
      // allocate virtual memory
      if((t->pgdir = setupkvm(kalloc)) == 0)
80104bc9:	c7 04 24 10 2b 10 80 	movl   $0x80102b10,(%esp)
80104bd0:	e8 c8 42 00 00       	call   80108e9d <setupkvm>
80104bd5:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104bd8:	89 42 04             	mov    %eax,0x4(%edx)
80104bdb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104bde:	8b 40 04             	mov    0x4(%eax),%eax
80104be1:	85 c0                	test   %eax,%eax
80104be3:	75 0c                	jne    80104bf1 <swapIn+0xb4>
	panic("inswapper: out of memory?");
80104be5:	c7 04 24 b9 9a 10 80 	movl   $0x80109ab9,(%esp)
80104bec:	e8 4c b9 ff ff       	call   8010053d <panic>
      if(!allocuvm(t->pgdir, 0, t->sz))
80104bf1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104bf4:	8b 10                	mov    (%eax),%edx
80104bf6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104bf9:	8b 40 04             	mov    0x4(%eax),%eax
80104bfc:	89 54 24 08          	mov    %edx,0x8(%esp)
80104c00:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104c07:	00 
80104c08:	89 04 24             	mov    %eax,(%esp)
80104c0b:	e8 5f 46 00 00       	call   8010926f <allocuvm>
80104c10:	85 c0                	test   %eax,%eax
80104c12:	75 11                	jne    80104c25 <swapIn+0xe8>
      {
	cprintf("allocuvm failed\n");
80104c14:	c7 04 24 e6 9a 10 80 	movl   $0x80109ae6,(%esp)
80104c1b:	e8 81 b7 ff ff       	call   801003a1 <cprintf>
	break;
80104c20:	e9 36 01 00 00       	jmp    80104d5b <swapIn+0x21e>
      }
      
      if(holding(&ptable.lock))
80104c25:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
80104c2c:	e8 dd 10 00 00       	call   80105d0e <holding>
80104c31:	85 c0                	test   %eax,%eax
80104c33:	74 0c                	je     80104c41 <swapIn+0x104>
	release(&ptable.lock);
80104c35:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
80104c3c:	e8 11 10 00 00       	call   80105c52 <release>
      loaduvm(t->pgdir,0,t->swap->ip,0,t->sz);
80104c41:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c44:	8b 08                	mov    (%eax),%ecx
80104c46:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c49:	8b 40 7c             	mov    0x7c(%eax),%eax
80104c4c:	8b 50 10             	mov    0x10(%eax),%edx
80104c4f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c52:	8b 40 04             	mov    0x4(%eax),%eax
80104c55:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80104c59:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80104c60:	00 
80104c61:	89 54 24 08          	mov    %edx,0x8(%esp)
80104c65:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104c6c:	00 
80104c6d:	89 04 24             	mov    %eax,(%esp)
80104c70:	e8 0b 45 00 00       	call   80109180 <loaduvm>
      
      t->isSwapped = 0;
80104c75:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c78:	c7 80 88 00 00 00 00 	movl   $0x0,0x88(%eax)
80104c7f:	00 00 00 
      int fd;
      for(fd = 0; fd < NOFILE; fd++)
80104c82:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80104c89:	eb 60                	jmp    80104ceb <swapIn+0x1ae>
      {
	//cprintf("fd = %d, t->ofile[fd] = %d, t->swap = %d\n",fd,proc->ofile[fd], t->swap);
	if(proc->ofile[fd] && proc->ofile[fd] == t->swap)
80104c8b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c91:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104c94:	83 c2 08             	add    $0x8,%edx
80104c97:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104c9b:	85 c0                	test   %eax,%eax
80104c9d:	74 48                	je     80104ce7 <swapIn+0x1aa>
80104c9f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ca5:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104ca8:	83 c2 08             	add    $0x8,%edx
80104cab:	8b 54 90 08          	mov    0x8(%eax,%edx,4),%edx
80104caf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104cb2:	8b 40 7c             	mov    0x7c(%eax),%eax
80104cb5:	39 c2                	cmp    %eax,%edx
80104cb7:	75 2e                	jne    80104ce7 <swapIn+0x1aa>
	{
	  //cprintf("fileclose swap in\n");
	  fileclose(proc->ofile[fd]);
80104cb9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104cbf:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104cc2:	83 c2 08             	add    $0x8,%edx
80104cc5:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104cc9:	89 04 24             	mov    %eax,(%esp)
80104ccc:	e8 f3 c2 ff ff       	call   80100fc4 <fileclose>
	  proc->ofile[fd] = 0;
80104cd1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104cd7:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104cda:	83 c2 08             	add    $0x8,%edx
80104cdd:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80104ce4:	00 
	  break;
80104ce5:	eb 0a                	jmp    80104cf1 <swapIn+0x1b4>
	release(&ptable.lock);
      loaduvm(t->pgdir,0,t->swap->ip,0,t->sz);
      
      t->isSwapped = 0;
      int fd;
      for(fd = 0; fd < NOFILE; fd++)
80104ce7:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80104ceb:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
80104cef:	7e 9a                	jle    80104c8b <swapIn+0x14e>
	  fileclose(proc->ofile[fd]);
	  proc->ofile[fd] = 0;
	  break;
	}
      }
      t->swap=0;
80104cf1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104cf4:	c7 40 7c 00 00 00 00 	movl   $0x0,0x7c(%eax)
      unlink(t->swapFileName);
80104cfb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104cfe:	83 e8 80             	sub    $0xffffff80,%eax
80104d01:	89 04 24             	mov    %eax,(%esp)
80104d04:	e8 d1 1a 00 00       	call   801067da <unlink>
      
      acquire(&ptable.lock);
80104d09:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
80104d10:	e8 a2 0e 00 00       	call   80105bb7 <acquire>
      t->state = RUNNABLE;
80104d15:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d18:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      
      acquire(&swaplock);
80104d1f:	c7 04 24 a0 c6 10 80 	movl   $0x8010c6a0,(%esp)
80104d26:	e8 8c 0e 00 00       	call   80105bb7 <acquire>
      swappedout--;
80104d2b:	a1 84 c6 10 80       	mov    0x8010c684,%eax
80104d30:	83 e8 01             	sub    $0x1,%eax
80104d33:	a3 84 c6 10 80       	mov    %eax,0x8010c684
      release(&swaplock);
80104d38:	c7 04 24 a0 c6 10 80 	movl   $0x8010c6a0,(%esp)
80104d3f:	e8 0e 0f 00 00       	call   80105c52 <release>
80104d44:	eb 01                	jmp    80104d47 <swapIn+0x20a>
  {
swapin:
    for(t = ptable.proc; t < &ptable.proc[NPROC]; t++)
    {
      if(t->state != RUNNABLE_SUSPENDED)
	continue;
80104d46:	90                   	nop
{
  struct proc* t;
  for(;;)
  {
swapin:
    for(t = ptable.proc; t < &ptable.proc[NPROC]; t++)
80104d47:	81 45 f4 90 00 00 00 	addl   $0x90,-0xc(%ebp)
80104d4e:	81 7d f4 74 9b 12 80 	cmpl   $0x80129b74,-0xc(%ebp)
80104d55:	0f 82 f4 fd ff ff    	jb     80104b4f <swapIn+0x12>
      acquire(&swaplock);
      swappedout--;
      release(&swaplock);
    }
   
    acquire(&swaplock);
80104d5b:	c7 04 24 a0 c6 10 80 	movl   $0x8010c6a0,(%esp)
80104d62:	e8 50 0e 00 00       	call   80105bb7 <acquire>
    if(swappedout > 0)
80104d67:	a1 84 c6 10 80       	mov    0x8010c684,%eax
80104d6c:	85 c0                	test   %eax,%eax
80104d6e:	7e 11                	jle    80104d81 <swapIn+0x244>
    {
      release(&swaplock);
80104d70:	c7 04 24 a0 c6 10 80 	movl   $0x8010c6a0,(%esp)
80104d77:	e8 d6 0e 00 00       	call   80105c52 <release>
      goto swapin;
80104d7c:	e9 c2 fd ff ff       	jmp    80104b43 <swapIn+0x6>
    }
    else
      release(&swaplock);
80104d81:	c7 04 24 a0 c6 10 80 	movl   $0x8010c6a0,(%esp)
80104d88:	e8 c5 0e 00 00       	call   80105c52 <release>

    proc->chan = inswapper;
80104d8d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d93:	8b 15 8c c6 10 80    	mov    0x8010c68c,%edx
80104d99:	89 50 20             	mov    %edx,0x20(%eax)
    proc->state = SLEEPING;
80104d9c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104da2:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
     
     sched();
80104da9:	e8 87 08 00 00       	call   80105635 <sched>
     proc->chan = 0;
80104dae:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104db4:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)
  }
80104dbb:	e9 83 fd ff ff       	jmp    80104b43 <swapIn+0x6>

80104dc0 <swapOut>:
}

void
swapOut()
{
80104dc0:	55                   	push   %ebp
80104dc1:	89 e5                	mov    %esp,%ebp
80104dc3:	53                   	push   %ebx
80104dc4:	83 ec 24             	sub    $0x24,%esp
    proc->swap = fileopen(proc->swapFileName,(O_CREATE | O_RDWR));
80104dc7:	65 8b 1d 04 00 00 00 	mov    %gs:0x4,%ebx
80104dce:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104dd4:	83 e8 80             	sub    $0xffffff80,%eax
80104dd7:	c7 44 24 04 02 02 00 	movl   $0x202,0x4(%esp)
80104dde:	00 
80104ddf:	89 04 24             	mov    %eax,(%esp)
80104de2:	e8 38 1f 00 00       	call   80106d1f <fileopen>
80104de7:	89 43 7c             	mov    %eax,0x7c(%ebx)
    pte_t *pte;
    uint pa, j;
    for(j = 0; j < proc->sz; j += PGSIZE)
80104dea:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104df1:	e9 9a 00 00 00       	jmp    80104e90 <swapOut+0xd0>
    {
      if((pte = walkpgdir(proc->pgdir, (void *) j, 0)) == 0)
80104df6:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104df9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104dff:	8b 40 04             	mov    0x4(%eax),%eax
80104e02:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80104e09:	00 
80104e0a:	89 54 24 04          	mov    %edx,0x4(%esp)
80104e0e:	89 04 24             	mov    %eax,(%esp)
80104e11:	e8 5d 3f 00 00       	call   80108d73 <walkpgdir>
80104e16:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104e19:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80104e1d:	75 0c                	jne    80104e2b <swapOut+0x6b>
	panic("walkpgdir: pte should exist");
80104e1f:	c7 04 24 f7 9a 10 80 	movl   $0x80109af7,(%esp)
80104e26:	e8 12 b7 ff ff       	call   8010053d <panic>
      if(!(*pte & PTE_P))
80104e2b:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104e2e:	8b 00                	mov    (%eax),%eax
80104e30:	83 e0 01             	and    $0x1,%eax
80104e33:	85 c0                	test   %eax,%eax
80104e35:	75 0c                	jne    80104e43 <swapOut+0x83>
	panic("walkpgdir: page not present");
80104e37:	c7 04 24 13 9b 10 80 	movl   $0x80109b13,(%esp)
80104e3e:	e8 fa b6 ff ff       	call   8010053d <panic>
      pa = PTE_ADDR(*pte);
80104e43:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104e46:	8b 00                	mov    (%eax),%eax
80104e48:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80104e4d:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(filewrite(proc->swap, (char*)p2v(pa), PGSIZE) < 0)
80104e50:	8b 45 e8             	mov    -0x18(%ebp),%eax
80104e53:	89 04 24             	mov    %eax,(%esp)
80104e56:	e8 d1 f9 ff ff       	call   8010482c <p2v>
80104e5b:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104e62:	8b 52 7c             	mov    0x7c(%edx),%edx
80104e65:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80104e6c:	00 
80104e6d:	89 44 24 04          	mov    %eax,0x4(%esp)
80104e71:	89 14 24             	mov    %edx,(%esp)
80104e74:	e8 2c c3 ff ff       	call   801011a5 <filewrite>
80104e79:	85 c0                	test   %eax,%eax
80104e7b:	79 0c                	jns    80104e89 <swapOut+0xc9>
	panic("filewrite failed");
80104e7d:	c7 04 24 2f 9b 10 80 	movl   $0x80109b2f,(%esp)
80104e84:	e8 b4 b6 ff ff       	call   8010053d <panic>
swapOut()
{
    proc->swap = fileopen(proc->swapFileName,(O_CREATE | O_RDWR));
    pte_t *pte;
    uint pa, j;
    for(j = 0; j < proc->sz; j += PGSIZE)
80104e89:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80104e90:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e96:	8b 00                	mov    (%eax),%eax
80104e98:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104e9b:	0f 87 55 ff ff ff    	ja     80104df6 <swapOut+0x36>
      if(filewrite(proc->swap, (char*)p2v(pa), PGSIZE) < 0)
	panic("filewrite failed");
    }

    int fd;
    for(fd = 0; fd < NOFILE; fd++)
80104ea1:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80104ea8:	eb 63                	jmp    80104f0d <swapOut+0x14d>
    {
      if(proc->ofile[fd] && proc->ofile[fd] == proc->swap)
80104eaa:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104eb0:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104eb3:	83 c2 08             	add    $0x8,%edx
80104eb6:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104eba:	85 c0                	test   %eax,%eax
80104ebc:	74 4b                	je     80104f09 <swapOut+0x149>
80104ebe:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ec4:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104ec7:	83 c2 08             	add    $0x8,%edx
80104eca:	8b 54 90 08          	mov    0x8(%eax,%edx,4),%edx
80104ece:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ed4:	8b 40 7c             	mov    0x7c(%eax),%eax
80104ed7:	39 c2                	cmp    %eax,%edx
80104ed9:	75 2e                	jne    80104f09 <swapOut+0x149>
      {
	fileclose(proc->ofile[fd]);
80104edb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ee1:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104ee4:	83 c2 08             	add    $0x8,%edx
80104ee7:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104eeb:	89 04 24             	mov    %eax,(%esp)
80104eee:	e8 d1 c0 ff ff       	call   80100fc4 <fileclose>
	proc->ofile[fd] = 0;
80104ef3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ef9:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104efc:	83 c2 08             	add    $0x8,%edx
80104eff:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80104f06:	00 
	break;
80104f07:	eb 0a                	jmp    80104f13 <swapOut+0x153>
      if(filewrite(proc->swap, (char*)p2v(pa), PGSIZE) < 0)
	panic("filewrite failed");
    }

    int fd;
    for(fd = 0; fd < NOFILE; fd++)
80104f09:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80104f0d:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
80104f11:	7e 97                	jle    80104eaa <swapOut+0xea>
	fileclose(proc->ofile[fd]);
	proc->ofile[fd] = 0;
	break;
      }
    }
    proc->swap=0;
80104f13:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f19:	c7 40 7c 00 00 00 00 	movl   $0x0,0x7c(%eax)
    //freevm(proc->pgdir);
    deallocuvm(proc->pgdir,proc->sz,0);
80104f20:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f26:	8b 10                	mov    (%eax),%edx
80104f28:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f2e:	8b 40 04             	mov    0x4(%eax),%eax
80104f31:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80104f38:	00 
80104f39:	89 54 24 04          	mov    %edx,0x4(%esp)
80104f3d:	89 04 24             	mov    %eax,(%esp)
80104f40:	e8 04 44 00 00       	call   80109349 <deallocuvm>
    proc->state = SLEEPING_SUSPENDED;
80104f45:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f4b:	c7 40 0c 06 00 00 00 	movl   $0x6,0xc(%eax)
    proc->isSwapped = 1;
80104f52:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f58:	c7 80 88 00 00 00 01 	movl   $0x1,0x88(%eax)
80104f5f:	00 00 00 
}
80104f62:	83 c4 24             	add    $0x24,%esp
80104f65:	5b                   	pop    %ebx
80104f66:	5d                   	pop    %ebp
80104f67:	c3                   	ret    

80104f68 <userinit>:

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
80104f68:	55                   	push   %ebp
80104f69:	89 e5                	mov    %esp,%ebp
80104f6b:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
80104f6e:	e8 11 f9 ff ff       	call   80104884 <allocproc>
80104f73:	89 45 f4             	mov    %eax,-0xc(%ebp)
  initproc = p;
80104f76:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f79:	a3 88 c6 10 80       	mov    %eax,0x8010c688
  if((p->pgdir = setupkvm(kalloc)) == 0)
80104f7e:	c7 04 24 10 2b 10 80 	movl   $0x80102b10,(%esp)
80104f85:	e8 13 3f 00 00       	call   80108e9d <setupkvm>
80104f8a:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104f8d:	89 42 04             	mov    %eax,0x4(%edx)
80104f90:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f93:	8b 40 04             	mov    0x4(%eax),%eax
80104f96:	85 c0                	test   %eax,%eax
80104f98:	75 0c                	jne    80104fa6 <userinit+0x3e>
    panic("userinit: out of memory?");
80104f9a:	c7 04 24 40 9b 10 80 	movl   $0x80109b40,(%esp)
80104fa1:	e8 97 b5 ff ff       	call   8010053d <panic>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80104fa6:	ba 2c 00 00 00       	mov    $0x2c,%edx
80104fab:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104fae:	8b 40 04             	mov    0x4(%eax),%eax
80104fb1:	89 54 24 08          	mov    %edx,0x8(%esp)
80104fb5:	c7 44 24 04 00 c5 10 	movl   $0x8010c500,0x4(%esp)
80104fbc:	80 
80104fbd:	89 04 24             	mov    %eax,(%esp)
80104fc0:	e8 30 41 00 00       	call   801090f5 <inituvm>
  p->sz = PGSIZE;
80104fc5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104fc8:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  memset(p->tf, 0, sizeof(*p->tf));
80104fce:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104fd1:	8b 40 18             	mov    0x18(%eax),%eax
80104fd4:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
80104fdb:	00 
80104fdc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104fe3:	00 
80104fe4:	89 04 24             	mov    %eax,(%esp)
80104fe7:	e8 52 0e 00 00       	call   80105e3e <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
80104fec:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104fef:	8b 40 18             	mov    0x18(%eax),%eax
80104ff2:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
80104ff8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ffb:	8b 40 18             	mov    0x18(%eax),%eax
80104ffe:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
  p->tf->es = p->tf->ds;
80105004:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105007:	8b 40 18             	mov    0x18(%eax),%eax
8010500a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010500d:	8b 52 18             	mov    0x18(%edx),%edx
80105010:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80105014:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
80105018:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010501b:	8b 40 18             	mov    0x18(%eax),%eax
8010501e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105021:	8b 52 18             	mov    0x18(%edx),%edx
80105024:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80105028:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
8010502c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010502f:	8b 40 18             	mov    0x18(%eax),%eax
80105032:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
80105039:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010503c:	8b 40 18             	mov    0x18(%eax),%eax
8010503f:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
80105046:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105049:	8b 40 18             	mov    0x18(%eax),%eax
8010504c:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
80105053:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105056:	83 c0 6c             	add    $0x6c,%eax
80105059:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80105060:	00 
80105061:	c7 44 24 04 59 9b 10 	movl   $0x80109b59,0x4(%esp)
80105068:	80 
80105069:	89 04 24             	mov    %eax,(%esp)
8010506c:	e8 fd 0f 00 00       	call   8010606e <safestrcpy>
  p->cwd = namei("/");
80105071:	c7 04 24 d3 9a 10 80 	movl   $0x80109ad3,(%esp)
80105078:	e8 8d d3 ff ff       	call   8010240a <namei>
8010507d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105080:	89 42 68             	mov    %eax,0x68(%edx)

  p->state = RUNNABLE;
80105083:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105086:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)

  createInternalProcess("inswapper", swapIn);
8010508d:	c7 44 24 04 3d 4b 10 	movl   $0x80104b3d,0x4(%esp)
80105094:	80 
80105095:	c7 04 24 62 9b 10 80 	movl   $0x80109b62,(%esp)
8010509c:	e8 8a f9 ff ff       	call   80104a2b <createInternalProcess>
}
801050a1:	c9                   	leave  
801050a2:	c3                   	ret    

801050a3 <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
801050a3:	55                   	push   %ebp
801050a4:	89 e5                	mov    %esp,%ebp
801050a6:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  
  sz = proc->sz;
801050a9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050af:	8b 00                	mov    (%eax),%eax
801050b1:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
801050b4:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801050b8:	7e 34                	jle    801050ee <growproc+0x4b>
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
801050ba:	8b 45 08             	mov    0x8(%ebp),%eax
801050bd:	89 c2                	mov    %eax,%edx
801050bf:	03 55 f4             	add    -0xc(%ebp),%edx
801050c2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050c8:	8b 40 04             	mov    0x4(%eax),%eax
801050cb:	89 54 24 08          	mov    %edx,0x8(%esp)
801050cf:	8b 55 f4             	mov    -0xc(%ebp),%edx
801050d2:	89 54 24 04          	mov    %edx,0x4(%esp)
801050d6:	89 04 24             	mov    %eax,(%esp)
801050d9:	e8 91 41 00 00       	call   8010926f <allocuvm>
801050de:	89 45 f4             	mov    %eax,-0xc(%ebp)
801050e1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801050e5:	75 41                	jne    80105128 <growproc+0x85>
      return -1;
801050e7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801050ec:	eb 58                	jmp    80105146 <growproc+0xa3>
  } else if(n < 0){
801050ee:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801050f2:	79 34                	jns    80105128 <growproc+0x85>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
801050f4:	8b 45 08             	mov    0x8(%ebp),%eax
801050f7:	89 c2                	mov    %eax,%edx
801050f9:	03 55 f4             	add    -0xc(%ebp),%edx
801050fc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105102:	8b 40 04             	mov    0x4(%eax),%eax
80105105:	89 54 24 08          	mov    %edx,0x8(%esp)
80105109:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010510c:	89 54 24 04          	mov    %edx,0x4(%esp)
80105110:	89 04 24             	mov    %eax,(%esp)
80105113:	e8 31 42 00 00       	call   80109349 <deallocuvm>
80105118:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010511b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010511f:	75 07                	jne    80105128 <growproc+0x85>
      return -1;
80105121:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105126:	eb 1e                	jmp    80105146 <growproc+0xa3>
  }
  proc->sz = sz;
80105128:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010512e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105131:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
80105133:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105139:	89 04 24             	mov    %eax,(%esp)
8010513c:	e8 4d 3e 00 00       	call   80108f8e <switchuvm>
  return 0;
80105141:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105146:	c9                   	leave  
80105147:	c3                   	ret    

80105148 <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
80105148:	55                   	push   %ebp
80105149:	89 e5                	mov    %esp,%ebp
8010514b:	57                   	push   %edi
8010514c:	56                   	push   %esi
8010514d:	53                   	push   %ebx
8010514e:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
80105151:	e8 2e f7 ff ff       	call   80104884 <allocproc>
80105156:	89 45 e0             	mov    %eax,-0x20(%ebp)
80105159:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
8010515d:	75 0a                	jne    80105169 <fork+0x21>
    return -1;
8010515f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105164:	e9 3a 01 00 00       	jmp    801052a3 <fork+0x15b>
  
  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
80105169:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010516f:	8b 10                	mov    (%eax),%edx
80105171:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105177:	8b 40 04             	mov    0x4(%eax),%eax
8010517a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010517e:	89 04 24             	mov    %eax,(%esp)
80105181:	e8 53 43 00 00       	call   801094d9 <copyuvm>
80105186:	8b 55 e0             	mov    -0x20(%ebp),%edx
80105189:	89 42 04             	mov    %eax,0x4(%edx)
8010518c:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010518f:	8b 40 04             	mov    0x4(%eax),%eax
80105192:	85 c0                	test   %eax,%eax
80105194:	75 2c                	jne    801051c2 <fork+0x7a>
    kfree(np->kstack);
80105196:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105199:	8b 40 08             	mov    0x8(%eax),%eax
8010519c:	89 04 24             	mov    %eax,(%esp)
8010519f:	e8 d3 d8 ff ff       	call   80102a77 <kfree>
    np->kstack = 0;
801051a4:	8b 45 e0             	mov    -0x20(%ebp),%eax
801051a7:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
801051ae:	8b 45 e0             	mov    -0x20(%ebp),%eax
801051b1:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
801051b8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801051bd:	e9 e1 00 00 00       	jmp    801052a3 <fork+0x15b>
  }
  np->sz = proc->sz;
801051c2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801051c8:	8b 10                	mov    (%eax),%edx
801051ca:	8b 45 e0             	mov    -0x20(%ebp),%eax
801051cd:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
801051cf:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801051d6:	8b 45 e0             	mov    -0x20(%ebp),%eax
801051d9:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *proc->tf;
801051dc:	8b 45 e0             	mov    -0x20(%ebp),%eax
801051df:	8b 50 18             	mov    0x18(%eax),%edx
801051e2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801051e8:	8b 40 18             	mov    0x18(%eax),%eax
801051eb:	89 c3                	mov    %eax,%ebx
801051ed:	b8 13 00 00 00       	mov    $0x13,%eax
801051f2:	89 d7                	mov    %edx,%edi
801051f4:	89 de                	mov    %ebx,%esi
801051f6:	89 c1                	mov    %eax,%ecx
801051f8:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
801051fa:	8b 45 e0             	mov    -0x20(%ebp),%eax
801051fd:	8b 40 18             	mov    0x18(%eax),%eax
80105200:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
80105207:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
8010520e:	eb 3d                	jmp    8010524d <fork+0x105>
    if(proc->ofile[i])
80105210:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105216:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80105219:	83 c2 08             	add    $0x8,%edx
8010521c:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105220:	85 c0                	test   %eax,%eax
80105222:	74 25                	je     80105249 <fork+0x101>
      np->ofile[i] = filedup(proc->ofile[i]);
80105224:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010522a:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010522d:	83 c2 08             	add    $0x8,%edx
80105230:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105234:	89 04 24             	mov    %eax,(%esp)
80105237:	e8 40 bd ff ff       	call   80100f7c <filedup>
8010523c:	8b 55 e0             	mov    -0x20(%ebp),%edx
8010523f:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80105242:	83 c1 08             	add    $0x8,%ecx
80105245:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
80105249:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
8010524d:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
80105251:	7e bd                	jle    80105210 <fork+0xc8>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
80105253:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105259:	8b 40 68             	mov    0x68(%eax),%eax
8010525c:	89 04 24             	mov    %eax,(%esp)
8010525f:	e8 d2 c5 ff ff       	call   80101836 <idup>
80105264:	8b 55 e0             	mov    -0x20(%ebp),%edx
80105267:	89 42 68             	mov    %eax,0x68(%edx)
 
  pid = np->pid;
8010526a:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010526d:	8b 40 10             	mov    0x10(%eax),%eax
80105270:	89 45 dc             	mov    %eax,-0x24(%ebp)
  np->state = RUNNABLE;
80105273:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105276:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  safestrcpy(np->name, proc->name, sizeof(proc->name));
8010527d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105283:	8d 50 6c             	lea    0x6c(%eax),%edx
80105286:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105289:	83 c0 6c             	add    $0x6c,%eax
8010528c:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80105293:	00 
80105294:	89 54 24 04          	mov    %edx,0x4(%esp)
80105298:	89 04 24             	mov    %eax,(%esp)
8010529b:	e8 ce 0d 00 00       	call   8010606e <safestrcpy>
  return pid;
801052a0:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
801052a3:	83 c4 2c             	add    $0x2c,%esp
801052a6:	5b                   	pop    %ebx
801052a7:	5e                   	pop    %esi
801052a8:	5f                   	pop    %edi
801052a9:	5d                   	pop    %ebp
801052aa:	c3                   	ret    

801052ab <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
801052ab:	55                   	push   %ebp
801052ac:	89 e5                	mov    %esp,%ebp
801052ae:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int fd;

  if(proc == initproc)
801052b1:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801052b8:	a1 88 c6 10 80       	mov    0x8010c688,%eax
801052bd:	39 c2                	cmp    %eax,%edx
801052bf:	75 0c                	jne    801052cd <exit+0x22>
    panic("init exiting");
801052c1:	c7 04 24 6c 9b 10 80 	movl   $0x80109b6c,(%esp)
801052c8:	e8 70 b2 ff ff       	call   8010053d <panic>

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
801052cd:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
801052d4:	eb 44                	jmp    8010531a <exit+0x6f>
    if(proc->ofile[fd]){
801052d6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801052dc:	8b 55 f0             	mov    -0x10(%ebp),%edx
801052df:	83 c2 08             	add    $0x8,%edx
801052e2:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801052e6:	85 c0                	test   %eax,%eax
801052e8:	74 2c                	je     80105316 <exit+0x6b>
      fileclose(proc->ofile[fd]);
801052ea:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801052f0:	8b 55 f0             	mov    -0x10(%ebp),%edx
801052f3:	83 c2 08             	add    $0x8,%edx
801052f6:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801052fa:	89 04 24             	mov    %eax,(%esp)
801052fd:	e8 c2 bc ff ff       	call   80100fc4 <fileclose>
      proc->ofile[fd] = 0;
80105302:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105308:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010530b:	83 c2 08             	add    $0x8,%edx
8010530e:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80105315:	00 

  if(proc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80105316:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
8010531a:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
8010531e:	7e b6                	jle    801052d6 <exit+0x2b>
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  iput(proc->cwd);
80105320:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105326:	8b 40 68             	mov    0x68(%eax),%eax
80105329:	89 04 24             	mov    %eax,(%esp)
8010532c:	e8 ea c6 ff ff       	call   80101a1b <iput>
  proc->cwd = 0;
80105331:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105337:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)
  
  if(proc->has_shm)
8010533e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105344:	8b 80 8c 00 00 00    	mov    0x8c(%eax),%eax
8010534a:	85 c0                	test   %eax,%eax
8010534c:	74 11                	je     8010535f <exit+0xb4>
    deallocshm(proc->pid);		//deallocate any shared memory segments proc did not shmdt
8010534e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105354:	8b 40 10             	mov    0x10(%eax),%eax
80105357:	89 04 24             	mov    %eax,(%esp)
8010535a:	e8 76 de ff ff       	call   801031d5 <deallocshm>
  
  acquire(&ptable.lock);
8010535f:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
80105366:	e8 4c 08 00 00       	call   80105bb7 <acquire>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);
8010536b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105371:	8b 40 14             	mov    0x14(%eax),%eax
80105374:	89 04 24             	mov    %eax,(%esp)
80105377:	e8 98 04 00 00       	call   80105814 <wakeup1>

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010537c:	c7 45 f4 74 77 12 80 	movl   $0x80127774,-0xc(%ebp)
80105383:	eb 3b                	jmp    801053c0 <exit+0x115>
    if(p->parent == proc){
80105385:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105388:	8b 50 14             	mov    0x14(%eax),%edx
8010538b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105391:	39 c2                	cmp    %eax,%edx
80105393:	75 24                	jne    801053b9 <exit+0x10e>
      p->parent = initproc;
80105395:	8b 15 88 c6 10 80    	mov    0x8010c688,%edx
8010539b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010539e:	89 50 14             	mov    %edx,0x14(%eax)
      if(p->state == ZOMBIE)
801053a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053a4:	8b 40 0c             	mov    0xc(%eax),%eax
801053a7:	83 f8 05             	cmp    $0x5,%eax
801053aa:	75 0d                	jne    801053b9 <exit+0x10e>
        wakeup1(initproc);
801053ac:	a1 88 c6 10 80       	mov    0x8010c688,%eax
801053b1:	89 04 24             	mov    %eax,(%esp)
801053b4:	e8 5b 04 00 00       	call   80105814 <wakeup1>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801053b9:	81 45 f4 90 00 00 00 	addl   $0x90,-0xc(%ebp)
801053c0:	81 7d f4 74 9b 12 80 	cmpl   $0x80129b74,-0xc(%ebp)
801053c7:	72 bc                	jb     80105385 <exit+0xda>
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  proc->state = ZOMBIE;
801053c9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801053cf:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
  sched();
801053d6:	e8 5a 02 00 00       	call   80105635 <sched>
  panic("zombie exit");
801053db:	c7 04 24 79 9b 10 80 	movl   $0x80109b79,(%esp)
801053e2:	e8 56 b1 ff ff       	call   8010053d <panic>

801053e7 <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
801053e7:	55                   	push   %ebp
801053e8:	89 e5                	mov    %esp,%ebp
801053ea:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
801053ed:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
801053f4:	e8 be 07 00 00       	call   80105bb7 <acquire>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
801053f9:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105400:	c7 45 f4 74 77 12 80 	movl   $0x80127774,-0xc(%ebp)
80105407:	e9 9d 00 00 00       	jmp    801054a9 <wait+0xc2>
      if(p->parent != proc)
8010540c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010540f:	8b 50 14             	mov    0x14(%eax),%edx
80105412:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105418:	39 c2                	cmp    %eax,%edx
8010541a:	0f 85 81 00 00 00    	jne    801054a1 <wait+0xba>
        continue;
      havekids = 1;
80105420:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
      if(p->state == ZOMBIE){
80105427:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010542a:	8b 40 0c             	mov    0xc(%eax),%eax
8010542d:	83 f8 05             	cmp    $0x5,%eax
80105430:	75 70                	jne    801054a2 <wait+0xbb>
        // Found one.
        pid = p->pid;
80105432:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105435:	8b 40 10             	mov    0x10(%eax),%eax
80105438:	89 45 ec             	mov    %eax,-0x14(%ebp)
        kfree(p->kstack);
8010543b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010543e:	8b 40 08             	mov    0x8(%eax),%eax
80105441:	89 04 24             	mov    %eax,(%esp)
80105444:	e8 2e d6 ff ff       	call   80102a77 <kfree>
        p->kstack = 0;
80105449:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010544c:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
        freevm(p->pgdir);
80105453:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105456:	8b 40 04             	mov    0x4(%eax),%eax
80105459:	89 04 24             	mov    %eax,(%esp)
8010545c:	e8 a4 3f 00 00       	call   80109405 <freevm>
        p->state = UNUSED;
80105461:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105464:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        p->pid = 0;
8010546b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010546e:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
        p->parent = 0;
80105475:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105478:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
        p->name[0] = 0;
8010547f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105482:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)
        p->killed = 0;
80105486:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105489:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
        release(&ptable.lock);
80105490:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
80105497:	e8 b6 07 00 00       	call   80105c52 <release>
        return pid;
8010549c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010549f:	eb 56                	jmp    801054f7 <wait+0x110>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->parent != proc)
        continue;
801054a1:	90                   	nop

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801054a2:	81 45 f4 90 00 00 00 	addl   $0x90,-0xc(%ebp)
801054a9:	81 7d f4 74 9b 12 80 	cmpl   $0x80129b74,-0xc(%ebp)
801054b0:	0f 82 56 ff ff ff    	jb     8010540c <wait+0x25>
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
801054b6:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801054ba:	74 0d                	je     801054c9 <wait+0xe2>
801054bc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054c2:	8b 40 24             	mov    0x24(%eax),%eax
801054c5:	85 c0                	test   %eax,%eax
801054c7:	74 13                	je     801054dc <wait+0xf5>
      release(&ptable.lock);
801054c9:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
801054d0:	e8 7d 07 00 00       	call   80105c52 <release>
      return -1;
801054d5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801054da:	eb 1b                	jmp    801054f7 <wait+0x110>
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
801054dc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054e2:	c7 44 24 04 40 77 12 	movl   $0x80127740,0x4(%esp)
801054e9:	80 
801054ea:	89 04 24             	mov    %eax,(%esp)
801054ed:	e8 53 02 00 00       	call   80105745 <sleep>
  }
801054f2:	e9 02 ff ff ff       	jmp    801053f9 <wait+0x12>
}
801054f7:	c9                   	leave  
801054f8:	c3                   	ret    

801054f9 <register_handler>:

void
register_handler(sighandler_t sighandler)
{
801054f9:	55                   	push   %ebp
801054fa:	89 e5                	mov    %esp,%ebp
801054fc:	83 ec 28             	sub    $0x28,%esp
  char* addr = uva2ka(proc->pgdir, (char*)proc->tf->esp);
801054ff:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105505:	8b 40 18             	mov    0x18(%eax),%eax
80105508:	8b 40 44             	mov    0x44(%eax),%eax
8010550b:	89 c2                	mov    %eax,%edx
8010550d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105513:	8b 40 04             	mov    0x4(%eax),%eax
80105516:	89 54 24 04          	mov    %edx,0x4(%esp)
8010551a:	89 04 24             	mov    %eax,(%esp)
8010551d:	e8 c8 40 00 00       	call   801095ea <uva2ka>
80105522:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if ((proc->tf->esp & 0xFFF) == 0)
80105525:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010552b:	8b 40 18             	mov    0x18(%eax),%eax
8010552e:	8b 40 44             	mov    0x44(%eax),%eax
80105531:	25 ff 0f 00 00       	and    $0xfff,%eax
80105536:	85 c0                	test   %eax,%eax
80105538:	75 0c                	jne    80105546 <register_handler+0x4d>
    panic("esp_offset == 0");
8010553a:	c7 04 24 85 9b 10 80 	movl   $0x80109b85,(%esp)
80105541:	e8 f7 af ff ff       	call   8010053d <panic>

    /* open a new frame */
  *(int*)(addr + ((proc->tf->esp - 4) & 0xFFF))
80105546:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010554c:	8b 40 18             	mov    0x18(%eax),%eax
8010554f:	8b 40 44             	mov    0x44(%eax),%eax
80105552:	83 e8 04             	sub    $0x4,%eax
80105555:	25 ff 0f 00 00       	and    $0xfff,%eax
8010555a:	03 45 f4             	add    -0xc(%ebp),%eax
          = proc->tf->eip;
8010555d:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80105564:	8b 52 18             	mov    0x18(%edx),%edx
80105567:	8b 52 38             	mov    0x38(%edx),%edx
8010556a:	89 10                	mov    %edx,(%eax)
  proc->tf->esp -= 4;
8010556c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105572:	8b 40 18             	mov    0x18(%eax),%eax
80105575:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
8010557c:	8b 52 18             	mov    0x18(%edx),%edx
8010557f:	8b 52 44             	mov    0x44(%edx),%edx
80105582:	83 ea 04             	sub    $0x4,%edx
80105585:	89 50 44             	mov    %edx,0x44(%eax)

    /* update eip */
  proc->tf->eip = (uint)sighandler;
80105588:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010558e:	8b 40 18             	mov    0x18(%eax),%eax
80105591:	8b 55 08             	mov    0x8(%ebp),%edx
80105594:	89 50 38             	mov    %edx,0x38(%eax)
}
80105597:	c9                   	leave  
80105598:	c3                   	ret    

80105599 <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
80105599:	55                   	push   %ebp
8010559a:	89 e5                	mov    %esp,%ebp
8010559c:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  
  for(;;){
    // Enable interrupts on this processor.
    sti();
8010559f:	e8 aa f2 ff ff       	call   8010484e <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
801055a4:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
801055ab:	e8 07 06 00 00       	call   80105bb7 <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801055b0:	c7 45 f4 74 77 12 80 	movl   $0x80127774,-0xc(%ebp)
801055b7:	eb 62                	jmp    8010561b <scheduler+0x82>
      if(p->state != RUNNABLE)
801055b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055bc:	8b 40 0c             	mov    0xc(%eax),%eax
801055bf:	83 f8 03             	cmp    $0x3,%eax
801055c2:	75 4f                	jne    80105613 <scheduler+0x7a>
        continue;
    
      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
801055c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055c7:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
      switchuvm(p);
801055cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055d0:	89 04 24             	mov    %eax,(%esp)
801055d3:	e8 b6 39 00 00       	call   80108f8e <switchuvm>
      p->state = RUNNING;
801055d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055db:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      swtch(&cpu->scheduler, proc->context);
801055e2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801055e8:	8b 40 1c             	mov    0x1c(%eax),%eax
801055eb:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801055f2:	83 c2 04             	add    $0x4,%edx
801055f5:	89 44 24 04          	mov    %eax,0x4(%esp)
801055f9:	89 14 24             	mov    %edx,(%esp)
801055fc:	e8 e3 0a 00 00       	call   801060e4 <swtch>
      switchkvm();
80105601:	e8 6b 39 00 00       	call   80108f71 <switchkvm>
                 
      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
80105606:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
8010560d:	00 00 00 00 
80105611:	eb 01                	jmp    80105614 <scheduler+0x7b>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->state != RUNNABLE)
        continue;
80105613:	90                   	nop
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105614:	81 45 f4 90 00 00 00 	addl   $0x90,-0xc(%ebp)
8010561b:	81 7d f4 74 9b 12 80 	cmpl   $0x80129b74,-0xc(%ebp)
80105622:	72 95                	jb     801055b9 <scheduler+0x20>
                 
      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
80105624:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
8010562b:	e8 22 06 00 00       	call   80105c52 <release>

  }
80105630:	e9 6a ff ff ff       	jmp    8010559f <scheduler+0x6>

80105635 <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
80105635:	55                   	push   %ebp
80105636:	89 e5                	mov    %esp,%ebp
80105638:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
8010563b:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
80105642:	e8 c7 06 00 00       	call   80105d0e <holding>
80105647:	85 c0                	test   %eax,%eax
80105649:	75 0c                	jne    80105657 <sched+0x22>
    panic("sched ptable.lock");
8010564b:	c7 04 24 95 9b 10 80 	movl   $0x80109b95,(%esp)
80105652:	e8 e6 ae ff ff       	call   8010053d <panic>
  if(cpu->ncli != 1)
80105657:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010565d:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105663:	83 f8 01             	cmp    $0x1,%eax
80105666:	74 0c                	je     80105674 <sched+0x3f>
    panic("sched locks");
80105668:	c7 04 24 a7 9b 10 80 	movl   $0x80109ba7,(%esp)
8010566f:	e8 c9 ae ff ff       	call   8010053d <panic>
  if(proc->state == RUNNING)
80105674:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010567a:	8b 40 0c             	mov    0xc(%eax),%eax
8010567d:	83 f8 04             	cmp    $0x4,%eax
80105680:	75 0c                	jne    8010568e <sched+0x59>
    panic("sched running");
80105682:	c7 04 24 b3 9b 10 80 	movl   $0x80109bb3,(%esp)
80105689:	e8 af ae ff ff       	call   8010053d <panic>
  if(readeflags()&FL_IF)
8010568e:	e8 a6 f1 ff ff       	call   80104839 <readeflags>
80105693:	25 00 02 00 00       	and    $0x200,%eax
80105698:	85 c0                	test   %eax,%eax
8010569a:	74 0c                	je     801056a8 <sched+0x73>
    panic("sched interruptible");
8010569c:	c7 04 24 c1 9b 10 80 	movl   $0x80109bc1,(%esp)
801056a3:	e8 95 ae ff ff       	call   8010053d <panic>
  intena = cpu->intena;
801056a8:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801056ae:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
801056b4:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->context, cpu->scheduler);
801056b7:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801056bd:	8b 40 04             	mov    0x4(%eax),%eax
801056c0:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801056c7:	83 c2 1c             	add    $0x1c,%edx
801056ca:	89 44 24 04          	mov    %eax,0x4(%esp)
801056ce:	89 14 24             	mov    %edx,(%esp)
801056d1:	e8 0e 0a 00 00       	call   801060e4 <swtch>
  cpu->intena = intena;
801056d6:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801056dc:	8b 55 f4             	mov    -0xc(%ebp),%edx
801056df:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
801056e5:	c9                   	leave  
801056e6:	c3                   	ret    

801056e7 <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
801056e7:	55                   	push   %ebp
801056e8:	89 e5                	mov    %esp,%ebp
801056ea:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
801056ed:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
801056f4:	e8 be 04 00 00       	call   80105bb7 <acquire>
  proc->state = RUNNABLE;
801056f9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801056ff:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
80105706:	e8 2a ff ff ff       	call   80105635 <sched>
  release(&ptable.lock);
8010570b:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
80105712:	e8 3b 05 00 00       	call   80105c52 <release>
}
80105717:	c9                   	leave  
80105718:	c3                   	ret    

80105719 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
80105719:	55                   	push   %ebp
8010571a:	89 e5                	mov    %esp,%ebp
8010571c:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
8010571f:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
80105726:	e8 27 05 00 00       	call   80105c52 <release>

  if (first) {
8010572b:	a1 20 c0 10 80       	mov    0x8010c020,%eax
80105730:	85 c0                	test   %eax,%eax
80105732:	74 0f                	je     80105743 <forkret+0x2a>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
80105734:	c7 05 20 c0 10 80 00 	movl   $0x0,0x8010c020
8010573b:	00 00 00 
    initlog();
8010573e:	e8 09 e1 ff ff       	call   8010384c <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
80105743:	c9                   	leave  
80105744:	c3                   	ret    

80105745 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
80105745:	55                   	push   %ebp
80105746:	89 e5                	mov    %esp,%ebp
80105748:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
8010574b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105751:	85 c0                	test   %eax,%eax
80105753:	75 0c                	jne    80105761 <sleep+0x1c>
    panic("sleep");
80105755:	c7 04 24 d5 9b 10 80 	movl   $0x80109bd5,(%esp)
8010575c:	e8 dc ad ff ff       	call   8010053d <panic>

  if(lk == 0)
80105761:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80105765:	75 0c                	jne    80105773 <sleep+0x2e>
    panic("sleep without lk");
80105767:	c7 04 24 db 9b 10 80 	movl   $0x80109bdb,(%esp)
8010576e:	e8 ca ad ff ff       	call   8010053d <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
80105773:	81 7d 0c 40 77 12 80 	cmpl   $0x80127740,0xc(%ebp)
8010577a:	74 17                	je     80105793 <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
8010577c:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
80105783:	e8 2f 04 00 00       	call   80105bb7 <acquire>
    release(lk);
80105788:	8b 45 0c             	mov    0xc(%ebp),%eax
8010578b:	89 04 24             	mov    %eax,(%esp)
8010578e:	e8 bf 04 00 00       	call   80105c52 <release>
  }

  // Go to sleep.
  proc->chan = chan;
80105793:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105799:	8b 55 08             	mov    0x8(%ebp),%edx
8010579c:	89 50 20             	mov    %edx,0x20(%eax)
  proc->state = SLEEPING;
8010579f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801057a5:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)

  // Swap out
  if(swapFlag)
801057ac:	a1 80 c6 10 80       	mov    0x8010c680,%eax
801057b1:	85 c0                	test   %eax,%eax
801057b3:	74 2b                	je     801057e0 <sleep+0x9b>
  {
    if(proc->pid > 3)
801057b5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801057bb:	8b 40 10             	mov    0x10(%eax),%eax
801057be:	83 f8 03             	cmp    $0x3,%eax
801057c1:	7e 1d                	jle    801057e0 <sleep+0x9b>
    {
      release(&ptable.lock);
801057c3:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
801057ca:	e8 83 04 00 00       	call   80105c52 <release>
      swapOut();
801057cf:	e8 ec f5 ff ff       	call   80104dc0 <swapOut>
      acquire(&ptable.lock);
801057d4:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
801057db:	e8 d7 03 00 00       	call   80105bb7 <acquire>
    }
  }
  
  sched();
801057e0:	e8 50 fe ff ff       	call   80105635 <sched>
  
  // Tidy up.
  proc->chan = 0;
801057e5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801057eb:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
801057f2:	81 7d 0c 40 77 12 80 	cmpl   $0x80127740,0xc(%ebp)
801057f9:	74 17                	je     80105812 <sleep+0xcd>
    release(&ptable.lock);
801057fb:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
80105802:	e8 4b 04 00 00       	call   80105c52 <release>
    acquire(lk);
80105807:	8b 45 0c             	mov    0xc(%ebp),%eax
8010580a:	89 04 24             	mov    %eax,(%esp)
8010580d:	e8 a5 03 00 00       	call   80105bb7 <acquire>
  }
}
80105812:	c9                   	leave  
80105813:	c3                   	ret    

80105814 <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80105814:	55                   	push   %ebp
80105815:	89 e5                	mov    %esp,%ebp
80105817:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int found_suspended = 0;
8010581a:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80105821:	c7 45 f4 74 77 12 80 	movl   $0x80127774,-0xc(%ebp)
80105828:	eb 7e                	jmp    801058a8 <wakeup1+0x94>
  {
    if(p->state == SLEEPING && p->chan == chan)
8010582a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010582d:	8b 40 0c             	mov    0xc(%eax),%eax
80105830:	83 f8 02             	cmp    $0x2,%eax
80105833:	75 15                	jne    8010584a <wakeup1+0x36>
80105835:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105838:	8b 40 20             	mov    0x20(%eax),%eax
8010583b:	3b 45 08             	cmp    0x8(%ebp),%eax
8010583e:	75 0a                	jne    8010584a <wakeup1+0x36>
      p->state = RUNNABLE;
80105840:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105843:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
    if(p->state == SLEEPING_SUSPENDED && p->chan == chan && !found_suspended)
8010584a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010584d:	8b 40 0c             	mov    0xc(%eax),%eax
80105850:	83 f8 06             	cmp    $0x6,%eax
80105853:	75 4c                	jne    801058a1 <wakeup1+0x8d>
80105855:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105858:	8b 40 20             	mov    0x20(%eax),%eax
8010585b:	3b 45 08             	cmp    0x8(%ebp),%eax
8010585e:	75 41                	jne    801058a1 <wakeup1+0x8d>
80105860:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105864:	75 3b                	jne    801058a1 <wakeup1+0x8d>
    {
      acquire(&swaplock);
80105866:	c7 04 24 a0 c6 10 80 	movl   $0x8010c6a0,(%esp)
8010586d:	e8 45 03 00 00       	call   80105bb7 <acquire>
      swappedout++;
80105872:	a1 84 c6 10 80       	mov    0x8010c684,%eax
80105877:	83 c0 01             	add    $0x1,%eax
8010587a:	a3 84 c6 10 80       	mov    %eax,0x8010c684
      p->state = RUNNABLE_SUSPENDED;
8010587f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105882:	c7 40 0c 07 00 00 00 	movl   $0x7,0xc(%eax)
      inswapper->state = RUNNABLE;
80105889:	a1 8c c6 10 80       	mov    0x8010c68c,%eax
8010588e:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      release(&swaplock);
80105895:	c7 04 24 a0 c6 10 80 	movl   $0x8010c6a0,(%esp)
8010589c:	e8 b1 03 00 00       	call   80105c52 <release>
wakeup1(void *chan)
{
  struct proc *p;
  int found_suspended = 0;
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801058a1:	81 45 f4 90 00 00 00 	addl   $0x90,-0xc(%ebp)
801058a8:	81 7d f4 74 9b 12 80 	cmpl   $0x80129b74,-0xc(%ebp)
801058af:	0f 82 75 ff ff ff    	jb     8010582a <wakeup1+0x16>
      p->state = RUNNABLE_SUSPENDED;
      inswapper->state = RUNNABLE;
      release(&swaplock);
    }
  }
}
801058b5:	c9                   	leave  
801058b6:	c3                   	ret    

801058b7 <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
801058b7:	55                   	push   %ebp
801058b8:	89 e5                	mov    %esp,%ebp
801058ba:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);
801058bd:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
801058c4:	e8 ee 02 00 00       	call   80105bb7 <acquire>
  wakeup1(chan);
801058c9:	8b 45 08             	mov    0x8(%ebp),%eax
801058cc:	89 04 24             	mov    %eax,(%esp)
801058cf:	e8 40 ff ff ff       	call   80105814 <wakeup1>
  release(&ptable.lock);
801058d4:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
801058db:	e8 72 03 00 00       	call   80105c52 <release>
}
801058e0:	c9                   	leave  
801058e1:	c3                   	ret    

801058e2 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
801058e2:	55                   	push   %ebp
801058e3:	89 e5                	mov    %esp,%ebp
801058e5:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  acquire(&ptable.lock);
801058e8:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
801058ef:	e8 c3 02 00 00       	call   80105bb7 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801058f4:	c7 45 f4 74 77 12 80 	movl   $0x80127774,-0xc(%ebp)
801058fb:	eb 67                	jmp    80105964 <kill+0x82>
    if(p->pid == pid){
801058fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105900:	8b 40 10             	mov    0x10(%eax),%eax
80105903:	3b 45 08             	cmp    0x8(%ebp),%eax
80105906:	75 55                	jne    8010595d <kill+0x7b>
      p->killed = 1;
80105908:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010590b:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80105912:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105915:	8b 40 0c             	mov    0xc(%eax),%eax
80105918:	83 f8 02             	cmp    $0x2,%eax
8010591b:	75 0c                	jne    80105929 <kill+0x47>
        p->state = RUNNABLE;
8010591d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105920:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
80105927:	eb 21                	jmp    8010594a <kill+0x68>
      else if(p->state == SLEEPING_SUSPENDED)
80105929:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010592c:	8b 40 0c             	mov    0xc(%eax),%eax
8010592f:	83 f8 06             	cmp    $0x6,%eax
80105932:	75 16                	jne    8010594a <kill+0x68>
      {
        p->state = RUNNABLE_SUSPENDED;
80105934:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105937:	c7 40 0c 07 00 00 00 	movl   $0x7,0xc(%eax)
	inswapper->state = RUNNABLE;
8010593e:	a1 8c c6 10 80       	mov    0x8010c68c,%eax
80105943:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      }
      release(&ptable.lock);
8010594a:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
80105951:	e8 fc 02 00 00       	call   80105c52 <release>
      return 0;
80105956:	b8 00 00 00 00       	mov    $0x0,%eax
8010595b:	eb 21                	jmp    8010597e <kill+0x9c>
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010595d:	81 45 f4 90 00 00 00 	addl   $0x90,-0xc(%ebp)
80105964:	81 7d f4 74 9b 12 80 	cmpl   $0x80129b74,-0xc(%ebp)
8010596b:	72 90                	jb     801058fd <kill+0x1b>
      }
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
8010596d:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
80105974:	e8 d9 02 00 00       	call   80105c52 <release>
  return -1;
80105979:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010597e:	c9                   	leave  
8010597f:	c3                   	ret    

80105980 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80105980:	55                   	push   %ebp
80105981:	89 e5                	mov    %esp,%ebp
80105983:	83 ec 58             	sub    $0x58,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105986:	c7 45 f0 74 77 12 80 	movl   $0x80127774,-0x10(%ebp)
8010598d:	e9 db 00 00 00       	jmp    80105a6d <procdump+0xed>
    if(p->state == UNUSED)
80105992:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105995:	8b 40 0c             	mov    0xc(%eax),%eax
80105998:	85 c0                	test   %eax,%eax
8010599a:	0f 84 c5 00 00 00    	je     80105a65 <procdump+0xe5>
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
801059a0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801059a3:	8b 40 0c             	mov    0xc(%eax),%eax
801059a6:	83 f8 05             	cmp    $0x5,%eax
801059a9:	77 23                	ja     801059ce <procdump+0x4e>
801059ab:	8b 45 f0             	mov    -0x10(%ebp),%eax
801059ae:	8b 40 0c             	mov    0xc(%eax),%eax
801059b1:	8b 04 85 08 c0 10 80 	mov    -0x7fef3ff8(,%eax,4),%eax
801059b8:	85 c0                	test   %eax,%eax
801059ba:	74 12                	je     801059ce <procdump+0x4e>
      state = states[p->state];
801059bc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801059bf:	8b 40 0c             	mov    0xc(%eax),%eax
801059c2:	8b 04 85 08 c0 10 80 	mov    -0x7fef3ff8(,%eax,4),%eax
801059c9:	89 45 ec             	mov    %eax,-0x14(%ebp)
801059cc:	eb 07                	jmp    801059d5 <procdump+0x55>
    else
      state = "???";
801059ce:	c7 45 ec ec 9b 10 80 	movl   $0x80109bec,-0x14(%ebp)
    cprintf("%d %s %s", p->pid, state, p->name);
801059d5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801059d8:	8d 50 6c             	lea    0x6c(%eax),%edx
801059db:	8b 45 f0             	mov    -0x10(%ebp),%eax
801059de:	8b 40 10             	mov    0x10(%eax),%eax
801059e1:	89 54 24 0c          	mov    %edx,0xc(%esp)
801059e5:	8b 55 ec             	mov    -0x14(%ebp),%edx
801059e8:	89 54 24 08          	mov    %edx,0x8(%esp)
801059ec:	89 44 24 04          	mov    %eax,0x4(%esp)
801059f0:	c7 04 24 f0 9b 10 80 	movl   $0x80109bf0,(%esp)
801059f7:	e8 a5 a9 ff ff       	call   801003a1 <cprintf>
    if(p->state == SLEEPING){
801059fc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801059ff:	8b 40 0c             	mov    0xc(%eax),%eax
80105a02:	83 f8 02             	cmp    $0x2,%eax
80105a05:	75 50                	jne    80105a57 <procdump+0xd7>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80105a07:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a0a:	8b 40 1c             	mov    0x1c(%eax),%eax
80105a0d:	8b 40 0c             	mov    0xc(%eax),%eax
80105a10:	83 c0 08             	add    $0x8,%eax
80105a13:	8d 55 c4             	lea    -0x3c(%ebp),%edx
80105a16:	89 54 24 04          	mov    %edx,0x4(%esp)
80105a1a:	89 04 24             	mov    %eax,(%esp)
80105a1d:	e8 7f 02 00 00       	call   80105ca1 <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80105a22:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80105a29:	eb 1b                	jmp    80105a46 <procdump+0xc6>
        cprintf(" %p", pc[i]);
80105a2b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a2e:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80105a32:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a36:	c7 04 24 f9 9b 10 80 	movl   $0x80109bf9,(%esp)
80105a3d:	e8 5f a9 ff ff       	call   801003a1 <cprintf>
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
80105a42:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80105a46:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
80105a4a:	7f 0b                	jg     80105a57 <procdump+0xd7>
80105a4c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a4f:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80105a53:	85 c0                	test   %eax,%eax
80105a55:	75 d4                	jne    80105a2b <procdump+0xab>
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80105a57:	c7 04 24 fd 9b 10 80 	movl   $0x80109bfd,(%esp)
80105a5e:	e8 3e a9 ff ff       	call   801003a1 <cprintf>
80105a63:	eb 01                	jmp    80105a66 <procdump+0xe6>
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
80105a65:	90                   	nop
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105a66:	81 45 f0 90 00 00 00 	addl   $0x90,-0x10(%ebp)
80105a6d:	81 7d f0 74 9b 12 80 	cmpl   $0x80129b74,-0x10(%ebp)
80105a74:	0f 82 18 ff ff ff    	jb     80105992 <procdump+0x12>
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}
80105a7a:	c9                   	leave  
80105a7b:	c3                   	ret    

80105a7c <getAllocatedPages>:

int getAllocatedPages(int pid) {
80105a7c:	55                   	push   %ebp
80105a7d:	89 e5                	mov    %esp,%ebp
80105a7f:	83 ec 38             	sub    $0x38,%esp
  struct proc* p;
  acquire(&ptable.lock);
80105a82:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
80105a89:	e8 29 01 00 00       	call   80105bb7 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105a8e:	c7 45 f4 74 77 12 80 	movl   $0x80127774,-0xc(%ebp)
80105a95:	eb 12                	jmp    80105aa9 <getAllocatedPages+0x2d>
    if(p->pid == pid){
80105a97:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a9a:	8b 40 10             	mov    0x10(%eax),%eax
80105a9d:	3b 45 08             	cmp    0x8(%ebp),%eax
80105aa0:	74 12                	je     80105ab4 <getAllocatedPages+0x38>
}

int getAllocatedPages(int pid) {
  struct proc* p;
  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105aa2:	81 45 f4 90 00 00 00 	addl   $0x90,-0xc(%ebp)
80105aa9:	81 7d f4 74 9b 12 80 	cmpl   $0x80129b74,-0xc(%ebp)
80105ab0:	72 e5                	jb     80105a97 <getAllocatedPages+0x1b>
80105ab2:	eb 01                	jmp    80105ab5 <getAllocatedPages+0x39>
    if(p->pid == pid){
     break;
80105ab4:	90                   	nop
    }
  }
  release(&ptable.lock);
80105ab5:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
80105abc:	e8 91 01 00 00       	call   80105c52 <release>
   int count= 0, j, k;
80105ac1:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   for (j=0; j<1024; j++) {
80105ac8:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80105acf:	eb 71                	jmp    80105b42 <getAllocatedPages+0xc6>
      if(p->pgdir){ 
80105ad1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ad4:	8b 40 04             	mov    0x4(%eax),%eax
80105ad7:	85 c0                	test   %eax,%eax
80105ad9:	74 63                	je     80105b3e <getAllocatedPages+0xc2>
	if (p->pgdir[j] & PTE_P) {
80105adb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ade:	8b 40 04             	mov    0x4(%eax),%eax
80105ae1:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105ae4:	c1 e2 02             	shl    $0x2,%edx
80105ae7:	01 d0                	add    %edx,%eax
80105ae9:	8b 00                	mov    (%eax),%eax
80105aeb:	83 e0 01             	and    $0x1,%eax
80105aee:	84 c0                	test   %al,%al
80105af0:	74 4c                	je     80105b3e <getAllocatedPages+0xc2>
	  pte_t* pte= (pte_t*)p2v(PTE_ADDR(p->pgdir[j]));
80105af2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105af5:	8b 40 04             	mov    0x4(%eax),%eax
80105af8:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105afb:	c1 e2 02             	shl    $0x2,%edx
80105afe:	01 d0                	add    %edx,%eax
80105b00:	8b 00                	mov    (%eax),%eax
80105b02:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80105b07:	89 04 24             	mov    %eax,(%esp)
80105b0a:	e8 1d ed ff ff       	call   8010482c <p2v>
80105b0f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	  for (k=0; k<1024; k++) {
80105b12:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
80105b19:	eb 1a                	jmp    80105b35 <getAllocatedPages+0xb9>
	      if ( pte[k] & PTE_U )
80105b1b:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105b1e:	c1 e0 02             	shl    $0x2,%eax
80105b21:	03 45 e4             	add    -0x1c(%ebp),%eax
80105b24:	8b 00                	mov    (%eax),%eax
80105b26:	83 e0 04             	and    $0x4,%eax
80105b29:	85 c0                	test   %eax,%eax
80105b2b:	74 04                	je     80105b31 <getAllocatedPages+0xb5>
		count++;
80105b2d:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   int count= 0, j, k;
   for (j=0; j<1024; j++) {
      if(p->pgdir){ 
	if (p->pgdir[j] & PTE_P) {
	  pte_t* pte= (pte_t*)p2v(PTE_ADDR(p->pgdir[j]));
	  for (k=0; k<1024; k++) {
80105b31:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
80105b35:	81 7d e8 ff 03 00 00 	cmpl   $0x3ff,-0x18(%ebp)
80105b3c:	7e dd                	jle    80105b1b <getAllocatedPages+0x9f>
     break;
    }
  }
  release(&ptable.lock);
   int count= 0, j, k;
   for (j=0; j<1024; j++) {
80105b3e:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
80105b42:	81 7d ec ff 03 00 00 	cmpl   $0x3ff,-0x14(%ebp)
80105b49:	7e 86                	jle    80105ad1 <getAllocatedPages+0x55>
		count++;
	  }
	}
      }
   }
   return count;
80105b4b:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80105b4e:	c9                   	leave  
80105b4f:	c3                   	ret    

80105b50 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80105b50:	55                   	push   %ebp
80105b51:	89 e5                	mov    %esp,%ebp
80105b53:	53                   	push   %ebx
80105b54:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80105b57:	9c                   	pushf  
80105b58:	5b                   	pop    %ebx
80105b59:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80105b5c:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80105b5f:	83 c4 10             	add    $0x10,%esp
80105b62:	5b                   	pop    %ebx
80105b63:	5d                   	pop    %ebp
80105b64:	c3                   	ret    

80105b65 <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
80105b65:	55                   	push   %ebp
80105b66:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
80105b68:	fa                   	cli    
}
80105b69:	5d                   	pop    %ebp
80105b6a:	c3                   	ret    

80105b6b <sti>:

static inline void
sti(void)
{
80105b6b:	55                   	push   %ebp
80105b6c:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80105b6e:	fb                   	sti    
}
80105b6f:	5d                   	pop    %ebp
80105b70:	c3                   	ret    

80105b71 <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
80105b71:	55                   	push   %ebp
80105b72:	89 e5                	mov    %esp,%ebp
80105b74:	53                   	push   %ebx
80105b75:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
80105b78:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80105b7b:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
80105b7e:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80105b81:	89 c3                	mov    %eax,%ebx
80105b83:	89 d8                	mov    %ebx,%eax
80105b85:	f0 87 02             	lock xchg %eax,(%edx)
80105b88:	89 c3                	mov    %eax,%ebx
80105b8a:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80105b8d:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80105b90:	83 c4 10             	add    $0x10,%esp
80105b93:	5b                   	pop    %ebx
80105b94:	5d                   	pop    %ebp
80105b95:	c3                   	ret    

80105b96 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80105b96:	55                   	push   %ebp
80105b97:	89 e5                	mov    %esp,%ebp
  lk->name = name;
80105b99:	8b 45 08             	mov    0x8(%ebp),%eax
80105b9c:	8b 55 0c             	mov    0xc(%ebp),%edx
80105b9f:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80105ba2:	8b 45 08             	mov    0x8(%ebp),%eax
80105ba5:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80105bab:	8b 45 08             	mov    0x8(%ebp),%eax
80105bae:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80105bb5:	5d                   	pop    %ebp
80105bb6:	c3                   	ret    

80105bb7 <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
80105bb7:	55                   	push   %ebp
80105bb8:	89 e5                	mov    %esp,%ebp
80105bba:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80105bbd:	e8 76 01 00 00       	call   80105d38 <pushcli>
  if(holding(lk))
80105bc2:	8b 45 08             	mov    0x8(%ebp),%eax
80105bc5:	89 04 24             	mov    %eax,(%esp)
80105bc8:	e8 41 01 00 00       	call   80105d0e <holding>
80105bcd:	85 c0                	test   %eax,%eax
80105bcf:	74 45                	je     80105c16 <acquire+0x5f>
  {
    cprintf("lock = %s\n",lk->name);
80105bd1:	8b 45 08             	mov    0x8(%ebp),%eax
80105bd4:	8b 40 04             	mov    0x4(%eax),%eax
80105bd7:	89 44 24 04          	mov    %eax,0x4(%esp)
80105bdb:	c7 04 24 29 9c 10 80 	movl   $0x80109c29,(%esp)
80105be2:	e8 ba a7 ff ff       	call   801003a1 <cprintf>
    if(proc)
80105be7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105bed:	85 c0                	test   %eax,%eax
80105bef:	74 19                	je     80105c0a <acquire+0x53>
      cprintf("pid = %d\n",proc->pid);
80105bf1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105bf7:	8b 40 10             	mov    0x10(%eax),%eax
80105bfa:	89 44 24 04          	mov    %eax,0x4(%esp)
80105bfe:	c7 04 24 34 9c 10 80 	movl   $0x80109c34,(%esp)
80105c05:	e8 97 a7 ff ff       	call   801003a1 <cprintf>
    panic("acquire");
80105c0a:	c7 04 24 3e 9c 10 80 	movl   $0x80109c3e,(%esp)
80105c11:	e8 27 a9 ff ff       	call   8010053d <panic>
  }

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
80105c16:	90                   	nop
80105c17:	8b 45 08             	mov    0x8(%ebp),%eax
80105c1a:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80105c21:	00 
80105c22:	89 04 24             	mov    %eax,(%esp)
80105c25:	e8 47 ff ff ff       	call   80105b71 <xchg>
80105c2a:	85 c0                	test   %eax,%eax
80105c2c:	75 e9                	jne    80105c17 <acquire+0x60>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
80105c2e:	8b 45 08             	mov    0x8(%ebp),%eax
80105c31:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80105c38:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
80105c3b:	8b 45 08             	mov    0x8(%ebp),%eax
80105c3e:	83 c0 0c             	add    $0xc,%eax
80105c41:	89 44 24 04          	mov    %eax,0x4(%esp)
80105c45:	8d 45 08             	lea    0x8(%ebp),%eax
80105c48:	89 04 24             	mov    %eax,(%esp)
80105c4b:	e8 51 00 00 00       	call   80105ca1 <getcallerpcs>
}
80105c50:	c9                   	leave  
80105c51:	c3                   	ret    

80105c52 <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
80105c52:	55                   	push   %ebp
80105c53:	89 e5                	mov    %esp,%ebp
80105c55:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
80105c58:	8b 45 08             	mov    0x8(%ebp),%eax
80105c5b:	89 04 24             	mov    %eax,(%esp)
80105c5e:	e8 ab 00 00 00       	call   80105d0e <holding>
80105c63:	85 c0                	test   %eax,%eax
80105c65:	75 0c                	jne    80105c73 <release+0x21>
    panic("release");
80105c67:	c7 04 24 46 9c 10 80 	movl   $0x80109c46,(%esp)
80105c6e:	e8 ca a8 ff ff       	call   8010053d <panic>

  lk->pcs[0] = 0;
80105c73:	8b 45 08             	mov    0x8(%ebp),%eax
80105c76:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
80105c7d:	8b 45 08             	mov    0x8(%ebp),%eax
80105c80:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
80105c87:	8b 45 08             	mov    0x8(%ebp),%eax
80105c8a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105c91:	00 
80105c92:	89 04 24             	mov    %eax,(%esp)
80105c95:	e8 d7 fe ff ff       	call   80105b71 <xchg>

  popcli();
80105c9a:	e8 e1 00 00 00       	call   80105d80 <popcli>
}
80105c9f:	c9                   	leave  
80105ca0:	c3                   	ret    

80105ca1 <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80105ca1:	55                   	push   %ebp
80105ca2:	89 e5                	mov    %esp,%ebp
80105ca4:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
80105ca7:	8b 45 08             	mov    0x8(%ebp),%eax
80105caa:	83 e8 08             	sub    $0x8,%eax
80105cad:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
80105cb0:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
80105cb7:	eb 32                	jmp    80105ceb <getcallerpcs+0x4a>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80105cb9:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
80105cbd:	74 47                	je     80105d06 <getcallerpcs+0x65>
80105cbf:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
80105cc6:	76 3e                	jbe    80105d06 <getcallerpcs+0x65>
80105cc8:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
80105ccc:	74 38                	je     80105d06 <getcallerpcs+0x65>
      break;
    pcs[i] = ebp[1];     // saved %eip
80105cce:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105cd1:	c1 e0 02             	shl    $0x2,%eax
80105cd4:	03 45 0c             	add    0xc(%ebp),%eax
80105cd7:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105cda:	8b 52 04             	mov    0x4(%edx),%edx
80105cdd:	89 10                	mov    %edx,(%eax)
    ebp = (uint*)ebp[0]; // saved %ebp
80105cdf:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105ce2:	8b 00                	mov    (%eax),%eax
80105ce4:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
80105ce7:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105ceb:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105cef:	7e c8                	jle    80105cb9 <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105cf1:	eb 13                	jmp    80105d06 <getcallerpcs+0x65>
    pcs[i] = 0;
80105cf3:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105cf6:	c1 e0 02             	shl    $0x2,%eax
80105cf9:	03 45 0c             	add    0xc(%ebp),%eax
80105cfc:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105d02:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105d06:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105d0a:	7e e7                	jle    80105cf3 <getcallerpcs+0x52>
    pcs[i] = 0;
}
80105d0c:	c9                   	leave  
80105d0d:	c3                   	ret    

80105d0e <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
80105d0e:	55                   	push   %ebp
80105d0f:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
80105d11:	8b 45 08             	mov    0x8(%ebp),%eax
80105d14:	8b 00                	mov    (%eax),%eax
80105d16:	85 c0                	test   %eax,%eax
80105d18:	74 17                	je     80105d31 <holding+0x23>
80105d1a:	8b 45 08             	mov    0x8(%ebp),%eax
80105d1d:	8b 50 08             	mov    0x8(%eax),%edx
80105d20:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105d26:	39 c2                	cmp    %eax,%edx
80105d28:	75 07                	jne    80105d31 <holding+0x23>
80105d2a:	b8 01 00 00 00       	mov    $0x1,%eax
80105d2f:	eb 05                	jmp    80105d36 <holding+0x28>
80105d31:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105d36:	5d                   	pop    %ebp
80105d37:	c3                   	ret    

80105d38 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80105d38:	55                   	push   %ebp
80105d39:	89 e5                	mov    %esp,%ebp
80105d3b:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
80105d3e:	e8 0d fe ff ff       	call   80105b50 <readeflags>
80105d43:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
80105d46:	e8 1a fe ff ff       	call   80105b65 <cli>
  if(cpu->ncli++ == 0)
80105d4b:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105d51:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80105d57:	85 d2                	test   %edx,%edx
80105d59:	0f 94 c1             	sete   %cl
80105d5c:	83 c2 01             	add    $0x1,%edx
80105d5f:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80105d65:	84 c9                	test   %cl,%cl
80105d67:	74 15                	je     80105d7e <pushcli+0x46>
    cpu->intena = eflags & FL_IF;
80105d69:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105d6f:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105d72:	81 e2 00 02 00 00    	and    $0x200,%edx
80105d78:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80105d7e:	c9                   	leave  
80105d7f:	c3                   	ret    

80105d80 <popcli>:

void
popcli(void)
{
80105d80:	55                   	push   %ebp
80105d81:	89 e5                	mov    %esp,%ebp
80105d83:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
80105d86:	e8 c5 fd ff ff       	call   80105b50 <readeflags>
80105d8b:	25 00 02 00 00       	and    $0x200,%eax
80105d90:	85 c0                	test   %eax,%eax
80105d92:	74 0c                	je     80105da0 <popcli+0x20>
    panic("popcli - interruptible");
80105d94:	c7 04 24 4e 9c 10 80 	movl   $0x80109c4e,(%esp)
80105d9b:	e8 9d a7 ff ff       	call   8010053d <panic>
  if(--cpu->ncli < 0)
80105da0:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105da6:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80105dac:	83 ea 01             	sub    $0x1,%edx
80105daf:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80105db5:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105dbb:	85 c0                	test   %eax,%eax
80105dbd:	79 0c                	jns    80105dcb <popcli+0x4b>
    panic("popcli");
80105dbf:	c7 04 24 65 9c 10 80 	movl   $0x80109c65,(%esp)
80105dc6:	e8 72 a7 ff ff       	call   8010053d <panic>
  if(cpu->ncli == 0 && cpu->intena)
80105dcb:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105dd1:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105dd7:	85 c0                	test   %eax,%eax
80105dd9:	75 15                	jne    80105df0 <popcli+0x70>
80105ddb:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105de1:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80105de7:	85 c0                	test   %eax,%eax
80105de9:	74 05                	je     80105df0 <popcli+0x70>
    sti();
80105deb:	e8 7b fd ff ff       	call   80105b6b <sti>
}
80105df0:	c9                   	leave  
80105df1:	c3                   	ret    
	...

80105df4 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
80105df4:	55                   	push   %ebp
80105df5:	89 e5                	mov    %esp,%ebp
80105df7:	57                   	push   %edi
80105df8:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
80105df9:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105dfc:	8b 55 10             	mov    0x10(%ebp),%edx
80105dff:	8b 45 0c             	mov    0xc(%ebp),%eax
80105e02:	89 cb                	mov    %ecx,%ebx
80105e04:	89 df                	mov    %ebx,%edi
80105e06:	89 d1                	mov    %edx,%ecx
80105e08:	fc                   	cld    
80105e09:	f3 aa                	rep stos %al,%es:(%edi)
80105e0b:	89 ca                	mov    %ecx,%edx
80105e0d:	89 fb                	mov    %edi,%ebx
80105e0f:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105e12:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105e15:	5b                   	pop    %ebx
80105e16:	5f                   	pop    %edi
80105e17:	5d                   	pop    %ebp
80105e18:	c3                   	ret    

80105e19 <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
80105e19:	55                   	push   %ebp
80105e1a:	89 e5                	mov    %esp,%ebp
80105e1c:	57                   	push   %edi
80105e1d:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
80105e1e:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105e21:	8b 55 10             	mov    0x10(%ebp),%edx
80105e24:	8b 45 0c             	mov    0xc(%ebp),%eax
80105e27:	89 cb                	mov    %ecx,%ebx
80105e29:	89 df                	mov    %ebx,%edi
80105e2b:	89 d1                	mov    %edx,%ecx
80105e2d:	fc                   	cld    
80105e2e:	f3 ab                	rep stos %eax,%es:(%edi)
80105e30:	89 ca                	mov    %ecx,%edx
80105e32:	89 fb                	mov    %edi,%ebx
80105e34:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105e37:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105e3a:	5b                   	pop    %ebx
80105e3b:	5f                   	pop    %edi
80105e3c:	5d                   	pop    %ebp
80105e3d:	c3                   	ret    

80105e3e <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80105e3e:	55                   	push   %ebp
80105e3f:	89 e5                	mov    %esp,%ebp
80105e41:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
80105e44:	8b 45 08             	mov    0x8(%ebp),%eax
80105e47:	83 e0 03             	and    $0x3,%eax
80105e4a:	85 c0                	test   %eax,%eax
80105e4c:	75 49                	jne    80105e97 <memset+0x59>
80105e4e:	8b 45 10             	mov    0x10(%ebp),%eax
80105e51:	83 e0 03             	and    $0x3,%eax
80105e54:	85 c0                	test   %eax,%eax
80105e56:	75 3f                	jne    80105e97 <memset+0x59>
    c &= 0xFF;
80105e58:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80105e5f:	8b 45 10             	mov    0x10(%ebp),%eax
80105e62:	c1 e8 02             	shr    $0x2,%eax
80105e65:	89 c2                	mov    %eax,%edx
80105e67:	8b 45 0c             	mov    0xc(%ebp),%eax
80105e6a:	89 c1                	mov    %eax,%ecx
80105e6c:	c1 e1 18             	shl    $0x18,%ecx
80105e6f:	8b 45 0c             	mov    0xc(%ebp),%eax
80105e72:	c1 e0 10             	shl    $0x10,%eax
80105e75:	09 c1                	or     %eax,%ecx
80105e77:	8b 45 0c             	mov    0xc(%ebp),%eax
80105e7a:	c1 e0 08             	shl    $0x8,%eax
80105e7d:	09 c8                	or     %ecx,%eax
80105e7f:	0b 45 0c             	or     0xc(%ebp),%eax
80105e82:	89 54 24 08          	mov    %edx,0x8(%esp)
80105e86:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e8a:	8b 45 08             	mov    0x8(%ebp),%eax
80105e8d:	89 04 24             	mov    %eax,(%esp)
80105e90:	e8 84 ff ff ff       	call   80105e19 <stosl>
80105e95:	eb 19                	jmp    80105eb0 <memset+0x72>
  } else
    stosb(dst, c, n);
80105e97:	8b 45 10             	mov    0x10(%ebp),%eax
80105e9a:	89 44 24 08          	mov    %eax,0x8(%esp)
80105e9e:	8b 45 0c             	mov    0xc(%ebp),%eax
80105ea1:	89 44 24 04          	mov    %eax,0x4(%esp)
80105ea5:	8b 45 08             	mov    0x8(%ebp),%eax
80105ea8:	89 04 24             	mov    %eax,(%esp)
80105eab:	e8 44 ff ff ff       	call   80105df4 <stosb>
  return dst;
80105eb0:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105eb3:	c9                   	leave  
80105eb4:	c3                   	ret    

80105eb5 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80105eb5:	55                   	push   %ebp
80105eb6:	89 e5                	mov    %esp,%ebp
80105eb8:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
80105ebb:	8b 45 08             	mov    0x8(%ebp),%eax
80105ebe:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
80105ec1:	8b 45 0c             	mov    0xc(%ebp),%eax
80105ec4:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
80105ec7:	eb 32                	jmp    80105efb <memcmp+0x46>
    if(*s1 != *s2)
80105ec9:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105ecc:	0f b6 10             	movzbl (%eax),%edx
80105ecf:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105ed2:	0f b6 00             	movzbl (%eax),%eax
80105ed5:	38 c2                	cmp    %al,%dl
80105ed7:	74 1a                	je     80105ef3 <memcmp+0x3e>
      return *s1 - *s2;
80105ed9:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105edc:	0f b6 00             	movzbl (%eax),%eax
80105edf:	0f b6 d0             	movzbl %al,%edx
80105ee2:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105ee5:	0f b6 00             	movzbl (%eax),%eax
80105ee8:	0f b6 c0             	movzbl %al,%eax
80105eeb:	89 d1                	mov    %edx,%ecx
80105eed:	29 c1                	sub    %eax,%ecx
80105eef:	89 c8                	mov    %ecx,%eax
80105ef1:	eb 1c                	jmp    80105f0f <memcmp+0x5a>
    s1++, s2++;
80105ef3:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105ef7:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80105efb:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105eff:	0f 95 c0             	setne  %al
80105f02:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105f06:	84 c0                	test   %al,%al
80105f08:	75 bf                	jne    80105ec9 <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
80105f0a:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105f0f:	c9                   	leave  
80105f10:	c3                   	ret    

80105f11 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80105f11:	55                   	push   %ebp
80105f12:	89 e5                	mov    %esp,%ebp
80105f14:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
80105f17:	8b 45 0c             	mov    0xc(%ebp),%eax
80105f1a:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
80105f1d:	8b 45 08             	mov    0x8(%ebp),%eax
80105f20:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
80105f23:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105f26:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105f29:	73 54                	jae    80105f7f <memmove+0x6e>
80105f2b:	8b 45 10             	mov    0x10(%ebp),%eax
80105f2e:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105f31:	01 d0                	add    %edx,%eax
80105f33:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105f36:	76 47                	jbe    80105f7f <memmove+0x6e>
    s += n;
80105f38:	8b 45 10             	mov    0x10(%ebp),%eax
80105f3b:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
80105f3e:	8b 45 10             	mov    0x10(%ebp),%eax
80105f41:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
80105f44:	eb 13                	jmp    80105f59 <memmove+0x48>
      *--d = *--s;
80105f46:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
80105f4a:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
80105f4e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105f51:	0f b6 10             	movzbl (%eax),%edx
80105f54:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105f57:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
80105f59:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105f5d:	0f 95 c0             	setne  %al
80105f60:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105f64:	84 c0                	test   %al,%al
80105f66:	75 de                	jne    80105f46 <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80105f68:	eb 25                	jmp    80105f8f <memmove+0x7e>
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
      *d++ = *s++;
80105f6a:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105f6d:	0f b6 10             	movzbl (%eax),%edx
80105f70:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105f73:	88 10                	mov    %dl,(%eax)
80105f75:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105f79:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105f7d:	eb 01                	jmp    80105f80 <memmove+0x6f>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
80105f7f:	90                   	nop
80105f80:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105f84:	0f 95 c0             	setne  %al
80105f87:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105f8b:	84 c0                	test   %al,%al
80105f8d:	75 db                	jne    80105f6a <memmove+0x59>
      *d++ = *s++;

  return dst;
80105f8f:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105f92:	c9                   	leave  
80105f93:	c3                   	ret    

80105f94 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80105f94:	55                   	push   %ebp
80105f95:	89 e5                	mov    %esp,%ebp
80105f97:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
80105f9a:	8b 45 10             	mov    0x10(%ebp),%eax
80105f9d:	89 44 24 08          	mov    %eax,0x8(%esp)
80105fa1:	8b 45 0c             	mov    0xc(%ebp),%eax
80105fa4:	89 44 24 04          	mov    %eax,0x4(%esp)
80105fa8:	8b 45 08             	mov    0x8(%ebp),%eax
80105fab:	89 04 24             	mov    %eax,(%esp)
80105fae:	e8 5e ff ff ff       	call   80105f11 <memmove>
}
80105fb3:	c9                   	leave  
80105fb4:	c3                   	ret    

80105fb5 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80105fb5:	55                   	push   %ebp
80105fb6:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
80105fb8:	eb 0c                	jmp    80105fc6 <strncmp+0x11>
    n--, p++, q++;
80105fba:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105fbe:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105fc2:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
80105fc6:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105fca:	74 1a                	je     80105fe6 <strncmp+0x31>
80105fcc:	8b 45 08             	mov    0x8(%ebp),%eax
80105fcf:	0f b6 00             	movzbl (%eax),%eax
80105fd2:	84 c0                	test   %al,%al
80105fd4:	74 10                	je     80105fe6 <strncmp+0x31>
80105fd6:	8b 45 08             	mov    0x8(%ebp),%eax
80105fd9:	0f b6 10             	movzbl (%eax),%edx
80105fdc:	8b 45 0c             	mov    0xc(%ebp),%eax
80105fdf:	0f b6 00             	movzbl (%eax),%eax
80105fe2:	38 c2                	cmp    %al,%dl
80105fe4:	74 d4                	je     80105fba <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
80105fe6:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105fea:	75 07                	jne    80105ff3 <strncmp+0x3e>
    return 0;
80105fec:	b8 00 00 00 00       	mov    $0x0,%eax
80105ff1:	eb 18                	jmp    8010600b <strncmp+0x56>
  return (uchar)*p - (uchar)*q;
80105ff3:	8b 45 08             	mov    0x8(%ebp),%eax
80105ff6:	0f b6 00             	movzbl (%eax),%eax
80105ff9:	0f b6 d0             	movzbl %al,%edx
80105ffc:	8b 45 0c             	mov    0xc(%ebp),%eax
80105fff:	0f b6 00             	movzbl (%eax),%eax
80106002:	0f b6 c0             	movzbl %al,%eax
80106005:	89 d1                	mov    %edx,%ecx
80106007:	29 c1                	sub    %eax,%ecx
80106009:	89 c8                	mov    %ecx,%eax
}
8010600b:	5d                   	pop    %ebp
8010600c:	c3                   	ret    

8010600d <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
8010600d:	55                   	push   %ebp
8010600e:	89 e5                	mov    %esp,%ebp
80106010:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80106013:	8b 45 08             	mov    0x8(%ebp),%eax
80106016:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
80106019:	90                   	nop
8010601a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010601e:	0f 9f c0             	setg   %al
80106021:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80106025:	84 c0                	test   %al,%al
80106027:	74 30                	je     80106059 <strncpy+0x4c>
80106029:	8b 45 0c             	mov    0xc(%ebp),%eax
8010602c:	0f b6 10             	movzbl (%eax),%edx
8010602f:	8b 45 08             	mov    0x8(%ebp),%eax
80106032:	88 10                	mov    %dl,(%eax)
80106034:	8b 45 08             	mov    0x8(%ebp),%eax
80106037:	0f b6 00             	movzbl (%eax),%eax
8010603a:	84 c0                	test   %al,%al
8010603c:	0f 95 c0             	setne  %al
8010603f:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80106043:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
80106047:	84 c0                	test   %al,%al
80106049:	75 cf                	jne    8010601a <strncpy+0xd>
    ;
  while(n-- > 0)
8010604b:	eb 0c                	jmp    80106059 <strncpy+0x4c>
    *s++ = 0;
8010604d:	8b 45 08             	mov    0x8(%ebp),%eax
80106050:	c6 00 00             	movb   $0x0,(%eax)
80106053:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80106057:	eb 01                	jmp    8010605a <strncpy+0x4d>
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
80106059:	90                   	nop
8010605a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010605e:	0f 9f c0             	setg   %al
80106061:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80106065:	84 c0                	test   %al,%al
80106067:	75 e4                	jne    8010604d <strncpy+0x40>
    *s++ = 0;
  return os;
80106069:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
8010606c:	c9                   	leave  
8010606d:	c3                   	ret    

8010606e <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
8010606e:	55                   	push   %ebp
8010606f:	89 e5                	mov    %esp,%ebp
80106071:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80106074:	8b 45 08             	mov    0x8(%ebp),%eax
80106077:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
8010607a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010607e:	7f 05                	jg     80106085 <safestrcpy+0x17>
    return os;
80106080:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106083:	eb 35                	jmp    801060ba <safestrcpy+0x4c>
  while(--n > 0 && (*s++ = *t++) != 0)
80106085:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80106089:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010608d:	7e 22                	jle    801060b1 <safestrcpy+0x43>
8010608f:	8b 45 0c             	mov    0xc(%ebp),%eax
80106092:	0f b6 10             	movzbl (%eax),%edx
80106095:	8b 45 08             	mov    0x8(%ebp),%eax
80106098:	88 10                	mov    %dl,(%eax)
8010609a:	8b 45 08             	mov    0x8(%ebp),%eax
8010609d:	0f b6 00             	movzbl (%eax),%eax
801060a0:	84 c0                	test   %al,%al
801060a2:	0f 95 c0             	setne  %al
801060a5:	83 45 08 01          	addl   $0x1,0x8(%ebp)
801060a9:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
801060ad:	84 c0                	test   %al,%al
801060af:	75 d4                	jne    80106085 <safestrcpy+0x17>
    ;
  *s = 0;
801060b1:	8b 45 08             	mov    0x8(%ebp),%eax
801060b4:	c6 00 00             	movb   $0x0,(%eax)
  return os;
801060b7:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801060ba:	c9                   	leave  
801060bb:	c3                   	ret    

801060bc <strlen>:

int
strlen(const char *s)
{
801060bc:	55                   	push   %ebp
801060bd:	89 e5                	mov    %esp,%ebp
801060bf:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
801060c2:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801060c9:	eb 04                	jmp    801060cf <strlen+0x13>
801060cb:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801060cf:	8b 45 fc             	mov    -0x4(%ebp),%eax
801060d2:	03 45 08             	add    0x8(%ebp),%eax
801060d5:	0f b6 00             	movzbl (%eax),%eax
801060d8:	84 c0                	test   %al,%al
801060da:	75 ef                	jne    801060cb <strlen+0xf>
    ;
  return n;
801060dc:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801060df:	c9                   	leave  
801060e0:	c3                   	ret    
801060e1:	00 00                	add    %al,(%eax)
	...

801060e4 <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
801060e4:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
801060e8:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
801060ec:	55                   	push   %ebp
  pushl %ebx
801060ed:	53                   	push   %ebx
  pushl %esi
801060ee:	56                   	push   %esi
  pushl %edi
801060ef:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
801060f0:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
801060f2:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
801060f4:	5f                   	pop    %edi
  popl %esi
801060f5:	5e                   	pop    %esi
  popl %ebx
801060f6:	5b                   	pop    %ebx
  popl %ebp
801060f7:	5d                   	pop    %ebp
  ret
801060f8:	c3                   	ret    
801060f9:	00 00                	add    %al,(%eax)
	...

801060fc <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from process p.
int
fetchint(struct proc *p, uint addr, int *ip)
{
801060fc:	55                   	push   %ebp
801060fd:	89 e5                	mov    %esp,%ebp
  if(addr >= p->sz || addr+4 > p->sz)
801060ff:	8b 45 08             	mov    0x8(%ebp),%eax
80106102:	8b 00                	mov    (%eax),%eax
80106104:	3b 45 0c             	cmp    0xc(%ebp),%eax
80106107:	76 0f                	jbe    80106118 <fetchint+0x1c>
80106109:	8b 45 0c             	mov    0xc(%ebp),%eax
8010610c:	8d 50 04             	lea    0x4(%eax),%edx
8010610f:	8b 45 08             	mov    0x8(%ebp),%eax
80106112:	8b 00                	mov    (%eax),%eax
80106114:	39 c2                	cmp    %eax,%edx
80106116:	76 07                	jbe    8010611f <fetchint+0x23>
    return -1;
80106118:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010611d:	eb 0f                	jmp    8010612e <fetchint+0x32>
  *ip = *(int*)(addr);
8010611f:	8b 45 0c             	mov    0xc(%ebp),%eax
80106122:	8b 10                	mov    (%eax),%edx
80106124:	8b 45 10             	mov    0x10(%ebp),%eax
80106127:	89 10                	mov    %edx,(%eax)
  return 0;
80106129:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010612e:	5d                   	pop    %ebp
8010612f:	c3                   	ret    

80106130 <fetchstr>:
// Fetch the nul-terminated string at addr from process p.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(struct proc *p, uint addr, char **pp)
{
80106130:	55                   	push   %ebp
80106131:	89 e5                	mov    %esp,%ebp
80106133:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= p->sz)
80106136:	8b 45 08             	mov    0x8(%ebp),%eax
80106139:	8b 00                	mov    (%eax),%eax
8010613b:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010613e:	77 07                	ja     80106147 <fetchstr+0x17>
    return -1;
80106140:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106145:	eb 45                	jmp    8010618c <fetchstr+0x5c>
  *pp = (char*)addr;
80106147:	8b 55 0c             	mov    0xc(%ebp),%edx
8010614a:	8b 45 10             	mov    0x10(%ebp),%eax
8010614d:	89 10                	mov    %edx,(%eax)
  ep = (char*)p->sz;
8010614f:	8b 45 08             	mov    0x8(%ebp),%eax
80106152:	8b 00                	mov    (%eax),%eax
80106154:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
80106157:	8b 45 10             	mov    0x10(%ebp),%eax
8010615a:	8b 00                	mov    (%eax),%eax
8010615c:	89 45 fc             	mov    %eax,-0x4(%ebp)
8010615f:	eb 1e                	jmp    8010617f <fetchstr+0x4f>
    if(*s == 0)
80106161:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106164:	0f b6 00             	movzbl (%eax),%eax
80106167:	84 c0                	test   %al,%al
80106169:	75 10                	jne    8010617b <fetchstr+0x4b>
      return s - *pp;
8010616b:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010616e:	8b 45 10             	mov    0x10(%ebp),%eax
80106171:	8b 00                	mov    (%eax),%eax
80106173:	89 d1                	mov    %edx,%ecx
80106175:	29 c1                	sub    %eax,%ecx
80106177:	89 c8                	mov    %ecx,%eax
80106179:	eb 11                	jmp    8010618c <fetchstr+0x5c>

  if(addr >= p->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)p->sz;
  for(s = *pp; s < ep; s++)
8010617b:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010617f:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106182:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80106185:	72 da                	jb     80106161 <fetchstr+0x31>
    if(*s == 0)
      return s - *pp;
  return -1;
80106187:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010618c:	c9                   	leave  
8010618d:	c3                   	ret    

8010618e <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
8010618e:	55                   	push   %ebp
8010618f:	89 e5                	mov    %esp,%ebp
80106191:	83 ec 0c             	sub    $0xc,%esp
  return fetchint(proc, proc->tf->esp + 4 + 4*n, ip);
80106194:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010619a:	8b 40 18             	mov    0x18(%eax),%eax
8010619d:	8b 50 44             	mov    0x44(%eax),%edx
801061a0:	8b 45 08             	mov    0x8(%ebp),%eax
801061a3:	c1 e0 02             	shl    $0x2,%eax
801061a6:	01 d0                	add    %edx,%eax
801061a8:	8d 48 04             	lea    0x4(%eax),%ecx
801061ab:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801061b1:	8b 55 0c             	mov    0xc(%ebp),%edx
801061b4:	89 54 24 08          	mov    %edx,0x8(%esp)
801061b8:	89 4c 24 04          	mov    %ecx,0x4(%esp)
801061bc:	89 04 24             	mov    %eax,(%esp)
801061bf:	e8 38 ff ff ff       	call   801060fc <fetchint>
}
801061c4:	c9                   	leave  
801061c5:	c3                   	ret    

801061c6 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
801061c6:	55                   	push   %ebp
801061c7:	89 e5                	mov    %esp,%ebp
801061c9:	83 ec 18             	sub    $0x18,%esp
  int i;

  if(argint(n, &i) < 0)
801061cc:	8d 45 fc             	lea    -0x4(%ebp),%eax
801061cf:	89 44 24 04          	mov    %eax,0x4(%esp)
801061d3:	8b 45 08             	mov    0x8(%ebp),%eax
801061d6:	89 04 24             	mov    %eax,(%esp)
801061d9:	e8 b0 ff ff ff       	call   8010618e <argint>
801061de:	85 c0                	test   %eax,%eax
801061e0:	79 07                	jns    801061e9 <argptr+0x23>
    return -1;
801061e2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061e7:	eb 3d                	jmp    80106226 <argptr+0x60>

  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
801061e9:	8b 45 fc             	mov    -0x4(%ebp),%eax
801061ec:	89 c2                	mov    %eax,%edx
801061ee:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801061f4:	8b 00                	mov    (%eax),%eax
801061f6:	39 c2                	cmp    %eax,%edx
801061f8:	73 16                	jae    80106210 <argptr+0x4a>
801061fa:	8b 45 fc             	mov    -0x4(%ebp),%eax
801061fd:	89 c2                	mov    %eax,%edx
801061ff:	8b 45 10             	mov    0x10(%ebp),%eax
80106202:	01 c2                	add    %eax,%edx
80106204:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010620a:	8b 00                	mov    (%eax),%eax
8010620c:	39 c2                	cmp    %eax,%edx
8010620e:	76 07                	jbe    80106217 <argptr+0x51>
    return -1;
80106210:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106215:	eb 0f                	jmp    80106226 <argptr+0x60>
  *pp = (char*)i;
80106217:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010621a:	89 c2                	mov    %eax,%edx
8010621c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010621f:	89 10                	mov    %edx,(%eax)
  return 0;
80106221:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106226:	c9                   	leave  
80106227:	c3                   	ret    

80106228 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80106228:	55                   	push   %ebp
80106229:	89 e5                	mov    %esp,%ebp
8010622b:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  if(argint(n, &addr) < 0)
8010622e:	8d 45 fc             	lea    -0x4(%ebp),%eax
80106231:	89 44 24 04          	mov    %eax,0x4(%esp)
80106235:	8b 45 08             	mov    0x8(%ebp),%eax
80106238:	89 04 24             	mov    %eax,(%esp)
8010623b:	e8 4e ff ff ff       	call   8010618e <argint>
80106240:	85 c0                	test   %eax,%eax
80106242:	79 07                	jns    8010624b <argstr+0x23>
    return -1;
80106244:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106249:	eb 1e                	jmp    80106269 <argstr+0x41>
  return fetchstr(proc, addr, pp);
8010624b:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010624e:	89 c2                	mov    %eax,%edx
80106250:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106256:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80106259:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010625d:	89 54 24 04          	mov    %edx,0x4(%esp)
80106261:	89 04 24             	mov    %eax,(%esp)
80106264:	e8 c7 fe ff ff       	call   80106130 <fetchstr>
}
80106269:	c9                   	leave  
8010626a:	c3                   	ret    

8010626b <syscall>:
[SYS_shmdt]	sys_shmdt,
};

void
syscall(void)
{
8010626b:	55                   	push   %ebp
8010626c:	89 e5                	mov    %esp,%ebp
8010626e:	53                   	push   %ebx
8010626f:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->tf->eax;
80106272:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106278:	8b 40 18             	mov    0x18(%eax),%eax
8010627b:	8b 40 1c             	mov    0x1c(%eax),%eax
8010627e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num >= 0 && num < SYS_open && syscalls[num]) {
80106281:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106285:	78 2e                	js     801062b5 <syscall+0x4a>
80106287:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
8010628b:	7f 28                	jg     801062b5 <syscall+0x4a>
8010628d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106290:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
80106297:	85 c0                	test   %eax,%eax
80106299:	74 1a                	je     801062b5 <syscall+0x4a>
    proc->tf->eax = syscalls[num]();
8010629b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801062a1:	8b 58 18             	mov    0x18(%eax),%ebx
801062a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062a7:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
801062ae:	ff d0                	call   *%eax
801062b0:	89 43 1c             	mov    %eax,0x1c(%ebx)
801062b3:	eb 73                	jmp    80106328 <syscall+0xbd>
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
801062b5:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
801062b9:	7e 30                	jle    801062eb <syscall+0x80>
801062bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062be:	83 f8 1e             	cmp    $0x1e,%eax
801062c1:	77 28                	ja     801062eb <syscall+0x80>
801062c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062c6:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
801062cd:	85 c0                	test   %eax,%eax
801062cf:	74 1a                	je     801062eb <syscall+0x80>
    proc->tf->eax = syscalls[num]();
801062d1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801062d7:	8b 58 18             	mov    0x18(%eax),%ebx
801062da:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062dd:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
801062e4:	ff d0                	call   *%eax
801062e6:	89 43 1c             	mov    %eax,0x1c(%ebx)
801062e9:	eb 3d                	jmp    80106328 <syscall+0xbd>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
801062eb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801062f1:	8d 48 6c             	lea    0x6c(%eax),%ecx
801062f4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  if(num >= 0 && num < SYS_open && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
801062fa:	8b 40 10             	mov    0x10(%eax),%eax
801062fd:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106300:	89 54 24 0c          	mov    %edx,0xc(%esp)
80106304:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106308:	89 44 24 04          	mov    %eax,0x4(%esp)
8010630c:	c7 04 24 6c 9c 10 80 	movl   $0x80109c6c,(%esp)
80106313:	e8 89 a0 ff ff       	call   801003a1 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
80106318:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010631e:	8b 40 18             	mov    0x18(%eax),%eax
80106321:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
80106328:	83 c4 24             	add    $0x24,%esp
8010632b:	5b                   	pop    %ebx
8010632c:	5d                   	pop    %ebp
8010632d:	c3                   	ret    
	...

80106330 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
80106330:	55                   	push   %ebp
80106331:	89 e5                	mov    %esp,%ebp
80106333:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
80106336:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106339:	89 44 24 04          	mov    %eax,0x4(%esp)
8010633d:	8b 45 08             	mov    0x8(%ebp),%eax
80106340:	89 04 24             	mov    %eax,(%esp)
80106343:	e8 46 fe ff ff       	call   8010618e <argint>
80106348:	85 c0                	test   %eax,%eax
8010634a:	79 07                	jns    80106353 <argfd+0x23>
    return -1;
8010634c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106351:	eb 50                	jmp    801063a3 <argfd+0x73>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
80106353:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106356:	85 c0                	test   %eax,%eax
80106358:	78 21                	js     8010637b <argfd+0x4b>
8010635a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010635d:	83 f8 0f             	cmp    $0xf,%eax
80106360:	7f 19                	jg     8010637b <argfd+0x4b>
80106362:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106368:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010636b:	83 c2 08             	add    $0x8,%edx
8010636e:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80106372:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106375:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106379:	75 07                	jne    80106382 <argfd+0x52>
    return -1;
8010637b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106380:	eb 21                	jmp    801063a3 <argfd+0x73>
  if(pfd)
80106382:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80106386:	74 08                	je     80106390 <argfd+0x60>
    *pfd = fd;
80106388:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010638b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010638e:	89 10                	mov    %edx,(%eax)
  if(pf)
80106390:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80106394:	74 08                	je     8010639e <argfd+0x6e>
    *pf = f;
80106396:	8b 45 10             	mov    0x10(%ebp),%eax
80106399:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010639c:	89 10                	mov    %edx,(%eax)
  return 0;
8010639e:	b8 00 00 00 00       	mov    $0x0,%eax
}
801063a3:	c9                   	leave  
801063a4:	c3                   	ret    

801063a5 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
801063a5:	55                   	push   %ebp
801063a6:	89 e5                	mov    %esp,%ebp
801063a8:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
801063ab:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801063b2:	eb 30                	jmp    801063e4 <fdalloc+0x3f>
    if(proc->ofile[fd] == 0){
801063b4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801063ba:	8b 55 fc             	mov    -0x4(%ebp),%edx
801063bd:	83 c2 08             	add    $0x8,%edx
801063c0:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801063c4:	85 c0                	test   %eax,%eax
801063c6:	75 18                	jne    801063e0 <fdalloc+0x3b>
      proc->ofile[fd] = f;
801063c8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801063ce:	8b 55 fc             	mov    -0x4(%ebp),%edx
801063d1:	8d 4a 08             	lea    0x8(%edx),%ecx
801063d4:	8b 55 08             	mov    0x8(%ebp),%edx
801063d7:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
801063db:	8b 45 fc             	mov    -0x4(%ebp),%eax
801063de:	eb 0f                	jmp    801063ef <fdalloc+0x4a>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
801063e0:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801063e4:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
801063e8:	7e ca                	jle    801063b4 <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
801063ea:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801063ef:	c9                   	leave  
801063f0:	c3                   	ret    

801063f1 <sys_dup>:

int
sys_dup(void)
{
801063f1:	55                   	push   %ebp
801063f2:	89 e5                	mov    %esp,%ebp
801063f4:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
801063f7:	8d 45 f0             	lea    -0x10(%ebp),%eax
801063fa:	89 44 24 08          	mov    %eax,0x8(%esp)
801063fe:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106405:	00 
80106406:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010640d:	e8 1e ff ff ff       	call   80106330 <argfd>
80106412:	85 c0                	test   %eax,%eax
80106414:	79 07                	jns    8010641d <sys_dup+0x2c>
    return -1;
80106416:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010641b:	eb 29                	jmp    80106446 <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
8010641d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106420:	89 04 24             	mov    %eax,(%esp)
80106423:	e8 7d ff ff ff       	call   801063a5 <fdalloc>
80106428:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010642b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010642f:	79 07                	jns    80106438 <sys_dup+0x47>
    return -1;
80106431:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106436:	eb 0e                	jmp    80106446 <sys_dup+0x55>
  filedup(f);
80106438:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010643b:	89 04 24             	mov    %eax,(%esp)
8010643e:	e8 39 ab ff ff       	call   80100f7c <filedup>
  return fd;
80106443:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80106446:	c9                   	leave  
80106447:	c3                   	ret    

80106448 <sys_read>:

int
sys_read(void)
{
80106448:	55                   	push   %ebp
80106449:	89 e5                	mov    %esp,%ebp
8010644b:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
8010644e:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106451:	89 44 24 08          	mov    %eax,0x8(%esp)
80106455:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010645c:	00 
8010645d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106464:	e8 c7 fe ff ff       	call   80106330 <argfd>
80106469:	85 c0                	test   %eax,%eax
8010646b:	78 35                	js     801064a2 <sys_read+0x5a>
8010646d:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106470:	89 44 24 04          	mov    %eax,0x4(%esp)
80106474:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
8010647b:	e8 0e fd ff ff       	call   8010618e <argint>
80106480:	85 c0                	test   %eax,%eax
80106482:	78 1e                	js     801064a2 <sys_read+0x5a>
80106484:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106487:	89 44 24 08          	mov    %eax,0x8(%esp)
8010648b:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010648e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106492:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106499:	e8 28 fd ff ff       	call   801061c6 <argptr>
8010649e:	85 c0                	test   %eax,%eax
801064a0:	79 07                	jns    801064a9 <sys_read+0x61>
    return -1;
801064a2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801064a7:	eb 19                	jmp    801064c2 <sys_read+0x7a>
  return fileread(f, p, n);
801064a9:	8b 4d f0             	mov    -0x10(%ebp),%ecx
801064ac:	8b 55 ec             	mov    -0x14(%ebp),%edx
801064af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064b2:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801064b6:	89 54 24 04          	mov    %edx,0x4(%esp)
801064ba:	89 04 24             	mov    %eax,(%esp)
801064bd:	e8 27 ac ff ff       	call   801010e9 <fileread>
}
801064c2:	c9                   	leave  
801064c3:	c3                   	ret    

801064c4 <sys_write>:

int
sys_write(void)
{
801064c4:	55                   	push   %ebp
801064c5:	89 e5                	mov    %esp,%ebp
801064c7:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801064ca:	8d 45 f4             	lea    -0xc(%ebp),%eax
801064cd:	89 44 24 08          	mov    %eax,0x8(%esp)
801064d1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801064d8:	00 
801064d9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801064e0:	e8 4b fe ff ff       	call   80106330 <argfd>
801064e5:	85 c0                	test   %eax,%eax
801064e7:	78 35                	js     8010651e <sys_write+0x5a>
801064e9:	8d 45 f0             	lea    -0x10(%ebp),%eax
801064ec:	89 44 24 04          	mov    %eax,0x4(%esp)
801064f0:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801064f7:	e8 92 fc ff ff       	call   8010618e <argint>
801064fc:	85 c0                	test   %eax,%eax
801064fe:	78 1e                	js     8010651e <sys_write+0x5a>
80106500:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106503:	89 44 24 08          	mov    %eax,0x8(%esp)
80106507:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010650a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010650e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106515:	e8 ac fc ff ff       	call   801061c6 <argptr>
8010651a:	85 c0                	test   %eax,%eax
8010651c:	79 07                	jns    80106525 <sys_write+0x61>
    return -1;
8010651e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106523:	eb 19                	jmp    8010653e <sys_write+0x7a>
  return filewrite(f, p, n);
80106525:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80106528:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010652b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010652e:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106532:	89 54 24 04          	mov    %edx,0x4(%esp)
80106536:	89 04 24             	mov    %eax,(%esp)
80106539:	e8 67 ac ff ff       	call   801011a5 <filewrite>
}
8010653e:	c9                   	leave  
8010653f:	c3                   	ret    

80106540 <sys_close>:

int
sys_close(void)
{
80106540:	55                   	push   %ebp
80106541:	89 e5                	mov    %esp,%ebp
80106543:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
80106546:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106549:	89 44 24 08          	mov    %eax,0x8(%esp)
8010654d:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106550:	89 44 24 04          	mov    %eax,0x4(%esp)
80106554:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010655b:	e8 d0 fd ff ff       	call   80106330 <argfd>
80106560:	85 c0                	test   %eax,%eax
80106562:	79 07                	jns    8010656b <sys_close+0x2b>
    return -1;
80106564:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106569:	eb 24                	jmp    8010658f <sys_close+0x4f>
  proc->ofile[fd] = 0;
8010656b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106571:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106574:	83 c2 08             	add    $0x8,%edx
80106577:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
8010657e:	00 
  fileclose(f);
8010657f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106582:	89 04 24             	mov    %eax,(%esp)
80106585:	e8 3a aa ff ff       	call   80100fc4 <fileclose>
  return 0;
8010658a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010658f:	c9                   	leave  
80106590:	c3                   	ret    

80106591 <sys_fstat>:

int
sys_fstat(void)
{
80106591:	55                   	push   %ebp
80106592:	89 e5                	mov    %esp,%ebp
80106594:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
80106597:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010659a:	89 44 24 08          	mov    %eax,0x8(%esp)
8010659e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801065a5:	00 
801065a6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801065ad:	e8 7e fd ff ff       	call   80106330 <argfd>
801065b2:	85 c0                	test   %eax,%eax
801065b4:	78 1f                	js     801065d5 <sys_fstat+0x44>
801065b6:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
801065bd:	00 
801065be:	8d 45 f0             	lea    -0x10(%ebp),%eax
801065c1:	89 44 24 04          	mov    %eax,0x4(%esp)
801065c5:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801065cc:	e8 f5 fb ff ff       	call   801061c6 <argptr>
801065d1:	85 c0                	test   %eax,%eax
801065d3:	79 07                	jns    801065dc <sys_fstat+0x4b>
    return -1;
801065d5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801065da:	eb 12                	jmp    801065ee <sys_fstat+0x5d>
  return filestat(f, st);
801065dc:	8b 55 f0             	mov    -0x10(%ebp),%edx
801065df:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065e2:	89 54 24 04          	mov    %edx,0x4(%esp)
801065e6:	89 04 24             	mov    %eax,(%esp)
801065e9:	e8 ac aa ff ff       	call   8010109a <filestat>
}
801065ee:	c9                   	leave  
801065ef:	c3                   	ret    

801065f0 <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
801065f0:	55                   	push   %ebp
801065f1:	89 e5                	mov    %esp,%ebp
801065f3:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
801065f6:	8d 45 d8             	lea    -0x28(%ebp),%eax
801065f9:	89 44 24 04          	mov    %eax,0x4(%esp)
801065fd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106604:	e8 1f fc ff ff       	call   80106228 <argstr>
80106609:	85 c0                	test   %eax,%eax
8010660b:	78 17                	js     80106624 <sys_link+0x34>
8010660d:	8d 45 dc             	lea    -0x24(%ebp),%eax
80106610:	89 44 24 04          	mov    %eax,0x4(%esp)
80106614:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010661b:	e8 08 fc ff ff       	call   80106228 <argstr>
80106620:	85 c0                	test   %eax,%eax
80106622:	79 0a                	jns    8010662e <sys_link+0x3e>
    return -1;
80106624:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106629:	e9 3c 01 00 00       	jmp    8010676a <sys_link+0x17a>
  if((ip = namei(old)) == 0)
8010662e:	8b 45 d8             	mov    -0x28(%ebp),%eax
80106631:	89 04 24             	mov    %eax,(%esp)
80106634:	e8 d1 bd ff ff       	call   8010240a <namei>
80106639:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010663c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106640:	75 0a                	jne    8010664c <sys_link+0x5c>
    return -1;
80106642:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106647:	e9 1e 01 00 00       	jmp    8010676a <sys_link+0x17a>

  begin_trans();
8010664c:	e8 08 d4 ff ff       	call   80103a59 <begin_trans>

  ilock(ip);
80106651:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106654:	89 04 24             	mov    %eax,(%esp)
80106657:	e8 0c b2 ff ff       	call   80101868 <ilock>
  if(ip->type == T_DIR){
8010665c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010665f:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106663:	66 83 f8 01          	cmp    $0x1,%ax
80106667:	75 1a                	jne    80106683 <sys_link+0x93>
    iunlockput(ip);
80106669:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010666c:	89 04 24             	mov    %eax,(%esp)
8010666f:	e8 78 b4 ff ff       	call   80101aec <iunlockput>
    commit_trans();
80106674:	e8 29 d4 ff ff       	call   80103aa2 <commit_trans>
    return -1;
80106679:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010667e:	e9 e7 00 00 00       	jmp    8010676a <sys_link+0x17a>
  }

  ip->nlink++;
80106683:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106686:	0f b7 40 16          	movzwl 0x16(%eax),%eax
8010668a:	8d 50 01             	lea    0x1(%eax),%edx
8010668d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106690:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80106694:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106697:	89 04 24             	mov    %eax,(%esp)
8010669a:	e8 0d b0 ff ff       	call   801016ac <iupdate>
  iunlock(ip);
8010669f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066a2:	89 04 24             	mov    %eax,(%esp)
801066a5:	e8 0c b3 ff ff       	call   801019b6 <iunlock>

  if((dp = nameiparent(new, name)) == 0)
801066aa:	8b 45 dc             	mov    -0x24(%ebp),%eax
801066ad:	8d 55 e2             	lea    -0x1e(%ebp),%edx
801066b0:	89 54 24 04          	mov    %edx,0x4(%esp)
801066b4:	89 04 24             	mov    %eax,(%esp)
801066b7:	e8 70 bd ff ff       	call   8010242c <nameiparent>
801066bc:	89 45 f0             	mov    %eax,-0x10(%ebp)
801066bf:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801066c3:	74 68                	je     8010672d <sys_link+0x13d>
    goto bad;
  ilock(dp);
801066c5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801066c8:	89 04 24             	mov    %eax,(%esp)
801066cb:	e8 98 b1 ff ff       	call   80101868 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
801066d0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801066d3:	8b 10                	mov    (%eax),%edx
801066d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066d8:	8b 00                	mov    (%eax),%eax
801066da:	39 c2                	cmp    %eax,%edx
801066dc:	75 20                	jne    801066fe <sys_link+0x10e>
801066de:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066e1:	8b 40 04             	mov    0x4(%eax),%eax
801066e4:	89 44 24 08          	mov    %eax,0x8(%esp)
801066e8:	8d 45 e2             	lea    -0x1e(%ebp),%eax
801066eb:	89 44 24 04          	mov    %eax,0x4(%esp)
801066ef:	8b 45 f0             	mov    -0x10(%ebp),%eax
801066f2:	89 04 24             	mov    %eax,(%esp)
801066f5:	e8 4f ba ff ff       	call   80102149 <dirlink>
801066fa:	85 c0                	test   %eax,%eax
801066fc:	79 0d                	jns    8010670b <sys_link+0x11b>
    iunlockput(dp);
801066fe:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106701:	89 04 24             	mov    %eax,(%esp)
80106704:	e8 e3 b3 ff ff       	call   80101aec <iunlockput>
    goto bad;
80106709:	eb 23                	jmp    8010672e <sys_link+0x13e>
  }
  iunlockput(dp);
8010670b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010670e:	89 04 24             	mov    %eax,(%esp)
80106711:	e8 d6 b3 ff ff       	call   80101aec <iunlockput>
  iput(ip);
80106716:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106719:	89 04 24             	mov    %eax,(%esp)
8010671c:	e8 fa b2 ff ff       	call   80101a1b <iput>

  commit_trans();
80106721:	e8 7c d3 ff ff       	call   80103aa2 <commit_trans>

  return 0;
80106726:	b8 00 00 00 00       	mov    $0x0,%eax
8010672b:	eb 3d                	jmp    8010676a <sys_link+0x17a>
  ip->nlink++;
  iupdate(ip);
  iunlock(ip);

  if((dp = nameiparent(new, name)) == 0)
    goto bad;
8010672d:	90                   	nop
  commit_trans();

  return 0;

bad:
  ilock(ip);
8010672e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106731:	89 04 24             	mov    %eax,(%esp)
80106734:	e8 2f b1 ff ff       	call   80101868 <ilock>
  ip->nlink--;
80106739:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010673c:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106740:	8d 50 ff             	lea    -0x1(%eax),%edx
80106743:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106746:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
8010674a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010674d:	89 04 24             	mov    %eax,(%esp)
80106750:	e8 57 af ff ff       	call   801016ac <iupdate>
  iunlockput(ip);
80106755:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106758:	89 04 24             	mov    %eax,(%esp)
8010675b:	e8 8c b3 ff ff       	call   80101aec <iunlockput>
  commit_trans();
80106760:	e8 3d d3 ff ff       	call   80103aa2 <commit_trans>
  return -1;
80106765:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010676a:	c9                   	leave  
8010676b:	c3                   	ret    

8010676c <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
8010676c:	55                   	push   %ebp
8010676d:	89 e5                	mov    %esp,%ebp
8010676f:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80106772:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
80106779:	eb 4b                	jmp    801067c6 <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010677b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010677e:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80106785:	00 
80106786:	89 44 24 08          	mov    %eax,0x8(%esp)
8010678a:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010678d:	89 44 24 04          	mov    %eax,0x4(%esp)
80106791:	8b 45 08             	mov    0x8(%ebp),%eax
80106794:	89 04 24             	mov    %eax,(%esp)
80106797:	e8 c2 b5 ff ff       	call   80101d5e <readi>
8010679c:	83 f8 10             	cmp    $0x10,%eax
8010679f:	74 0c                	je     801067ad <isdirempty+0x41>
      panic("isdirempty: readi");
801067a1:	c7 04 24 88 9c 10 80 	movl   $0x80109c88,(%esp)
801067a8:	e8 90 9d ff ff       	call   8010053d <panic>
    if(de.inum != 0)
801067ad:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
801067b1:	66 85 c0             	test   %ax,%ax
801067b4:	74 07                	je     801067bd <isdirempty+0x51>
      return 0;
801067b6:	b8 00 00 00 00       	mov    $0x0,%eax
801067bb:	eb 1b                	jmp    801067d8 <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801067bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067c0:	83 c0 10             	add    $0x10,%eax
801067c3:	89 45 f4             	mov    %eax,-0xc(%ebp)
801067c6:	8b 55 f4             	mov    -0xc(%ebp),%edx
801067c9:	8b 45 08             	mov    0x8(%ebp),%eax
801067cc:	8b 40 18             	mov    0x18(%eax),%eax
801067cf:	39 c2                	cmp    %eax,%edx
801067d1:	72 a8                	jb     8010677b <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
801067d3:	b8 01 00 00 00       	mov    $0x1,%eax
}
801067d8:	c9                   	leave  
801067d9:	c3                   	ret    

801067da <unlink>:


int
unlink(char* path)
{
801067da:	55                   	push   %ebp
801067db:	89 e5                	mov    %esp,%ebp
801067dd:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ];
  uint off;

  if((dp = nameiparent(path, name)) == 0)
801067e0:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801067e3:	89 44 24 04          	mov    %eax,0x4(%esp)
801067e7:	8b 45 08             	mov    0x8(%ebp),%eax
801067ea:	89 04 24             	mov    %eax,(%esp)
801067ed:	e8 3a bc ff ff       	call   8010242c <nameiparent>
801067f2:	89 45 f4             	mov    %eax,-0xc(%ebp)
801067f5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801067f9:	75 0a                	jne    80106805 <unlink+0x2b>
    return -1;
801067fb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106800:	e9 85 01 00 00       	jmp    8010698a <unlink+0x1b0>

  begin_trans();
80106805:	e8 4f d2 ff ff       	call   80103a59 <begin_trans>

  ilock(dp);
8010680a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010680d:	89 04 24             	mov    %eax,(%esp)
80106810:	e8 53 b0 ff ff       	call   80101868 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80106815:	c7 44 24 04 9a 9c 10 	movl   $0x80109c9a,0x4(%esp)
8010681c:	80 
8010681d:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80106820:	89 04 24             	mov    %eax,(%esp)
80106823:	e8 37 b8 ff ff       	call   8010205f <namecmp>
80106828:	85 c0                	test   %eax,%eax
8010682a:	0f 84 45 01 00 00    	je     80106975 <unlink+0x19b>
80106830:	c7 44 24 04 9c 9c 10 	movl   $0x80109c9c,0x4(%esp)
80106837:	80 
80106838:	8d 45 d2             	lea    -0x2e(%ebp),%eax
8010683b:	89 04 24             	mov    %eax,(%esp)
8010683e:	e8 1c b8 ff ff       	call   8010205f <namecmp>
80106843:	85 c0                	test   %eax,%eax
80106845:	0f 84 2a 01 00 00    	je     80106975 <unlink+0x19b>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
8010684b:	8d 45 cc             	lea    -0x34(%ebp),%eax
8010684e:	89 44 24 08          	mov    %eax,0x8(%esp)
80106852:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80106855:	89 44 24 04          	mov    %eax,0x4(%esp)
80106859:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010685c:	89 04 24             	mov    %eax,(%esp)
8010685f:	e8 1d b8 ff ff       	call   80102081 <dirlookup>
80106864:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106867:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010686b:	0f 84 03 01 00 00    	je     80106974 <unlink+0x19a>
    goto bad;
  ilock(ip);
80106871:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106874:	89 04 24             	mov    %eax,(%esp)
80106877:	e8 ec af ff ff       	call   80101868 <ilock>

  if(ip->nlink < 1)
8010687c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010687f:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106883:	66 85 c0             	test   %ax,%ax
80106886:	7f 0c                	jg     80106894 <unlink+0xba>
    panic("unlink: nlink < 1");
80106888:	c7 04 24 9f 9c 10 80 	movl   $0x80109c9f,(%esp)
8010688f:	e8 a9 9c ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80106894:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106897:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010689b:	66 83 f8 01          	cmp    $0x1,%ax
8010689f:	75 1f                	jne    801068c0 <unlink+0xe6>
801068a1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801068a4:	89 04 24             	mov    %eax,(%esp)
801068a7:	e8 c0 fe ff ff       	call   8010676c <isdirempty>
801068ac:	85 c0                	test   %eax,%eax
801068ae:	75 10                	jne    801068c0 <unlink+0xe6>
    iunlockput(ip);
801068b0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801068b3:	89 04 24             	mov    %eax,(%esp)
801068b6:	e8 31 b2 ff ff       	call   80101aec <iunlockput>
    goto bad;
801068bb:	e9 b5 00 00 00       	jmp    80106975 <unlink+0x19b>
  }

  memset(&de, 0, sizeof(de));
801068c0:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
801068c7:	00 
801068c8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801068cf:	00 
801068d0:	8d 45 e0             	lea    -0x20(%ebp),%eax
801068d3:	89 04 24             	mov    %eax,(%esp)
801068d6:	e8 63 f5 ff ff       	call   80105e3e <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801068db:	8b 45 cc             	mov    -0x34(%ebp),%eax
801068de:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801068e5:	00 
801068e6:	89 44 24 08          	mov    %eax,0x8(%esp)
801068ea:	8d 45 e0             	lea    -0x20(%ebp),%eax
801068ed:	89 44 24 04          	mov    %eax,0x4(%esp)
801068f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068f4:	89 04 24             	mov    %eax,(%esp)
801068f7:	e8 cd b5 ff ff       	call   80101ec9 <writei>
801068fc:	83 f8 10             	cmp    $0x10,%eax
801068ff:	74 0c                	je     8010690d <unlink+0x133>
    panic("unlink: writei");
80106901:	c7 04 24 b1 9c 10 80 	movl   $0x80109cb1,(%esp)
80106908:	e8 30 9c ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR){
8010690d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106910:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106914:	66 83 f8 01          	cmp    $0x1,%ax
80106918:	75 1c                	jne    80106936 <unlink+0x15c>
    dp->nlink--;
8010691a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010691d:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106921:	8d 50 ff             	lea    -0x1(%eax),%edx
80106924:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106927:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
8010692b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010692e:	89 04 24             	mov    %eax,(%esp)
80106931:	e8 76 ad ff ff       	call   801016ac <iupdate>
  }
  iunlockput(dp);
80106936:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106939:	89 04 24             	mov    %eax,(%esp)
8010693c:	e8 ab b1 ff ff       	call   80101aec <iunlockput>

  ip->nlink--;
80106941:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106944:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106948:	8d 50 ff             	lea    -0x1(%eax),%edx
8010694b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010694e:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80106952:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106955:	89 04 24             	mov    %eax,(%esp)
80106958:	e8 4f ad ff ff       	call   801016ac <iupdate>
  iunlockput(ip);
8010695d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106960:	89 04 24             	mov    %eax,(%esp)
80106963:	e8 84 b1 ff ff       	call   80101aec <iunlockput>

  commit_trans();
80106968:	e8 35 d1 ff ff       	call   80103aa2 <commit_trans>

  return 0;
8010696d:	b8 00 00 00 00       	mov    $0x0,%eax
80106972:	eb 16                	jmp    8010698a <unlink+0x1b0>
  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    goto bad;
80106974:	90                   	nop
  commit_trans();

  return 0;

bad:
  iunlockput(dp);
80106975:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106978:	89 04 24             	mov    %eax,(%esp)
8010697b:	e8 6c b1 ff ff       	call   80101aec <iunlockput>
  commit_trans();
80106980:	e8 1d d1 ff ff       	call   80103aa2 <commit_trans>
  return -1;
80106985:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010698a:	c9                   	leave  
8010698b:	c3                   	ret    

8010698c <sys_unlink>:


//PAGEBREAK!
int
sys_unlink(void)
{
8010698c:	55                   	push   %ebp
8010698d:	89 e5                	mov    %esp,%ebp
8010698f:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
80106992:	8d 45 cc             	lea    -0x34(%ebp),%eax
80106995:	89 44 24 04          	mov    %eax,0x4(%esp)
80106999:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801069a0:	e8 83 f8 ff ff       	call   80106228 <argstr>
801069a5:	85 c0                	test   %eax,%eax
801069a7:	79 0a                	jns    801069b3 <sys_unlink+0x27>
    return -1;
801069a9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801069ae:	e9 aa 01 00 00       	jmp    80106b5d <sys_unlink+0x1d1>
  if((dp = nameiparent(path, name)) == 0)
801069b3:	8b 45 cc             	mov    -0x34(%ebp),%eax
801069b6:	8d 55 d2             	lea    -0x2e(%ebp),%edx
801069b9:	89 54 24 04          	mov    %edx,0x4(%esp)
801069bd:	89 04 24             	mov    %eax,(%esp)
801069c0:	e8 67 ba ff ff       	call   8010242c <nameiparent>
801069c5:	89 45 f4             	mov    %eax,-0xc(%ebp)
801069c8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801069cc:	75 0a                	jne    801069d8 <sys_unlink+0x4c>
    return -1;
801069ce:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801069d3:	e9 85 01 00 00       	jmp    80106b5d <sys_unlink+0x1d1>

  begin_trans();
801069d8:	e8 7c d0 ff ff       	call   80103a59 <begin_trans>

  ilock(dp);
801069dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069e0:	89 04 24             	mov    %eax,(%esp)
801069e3:	e8 80 ae ff ff       	call   80101868 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
801069e8:	c7 44 24 04 9a 9c 10 	movl   $0x80109c9a,0x4(%esp)
801069ef:	80 
801069f0:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801069f3:	89 04 24             	mov    %eax,(%esp)
801069f6:	e8 64 b6 ff ff       	call   8010205f <namecmp>
801069fb:	85 c0                	test   %eax,%eax
801069fd:	0f 84 45 01 00 00    	je     80106b48 <sys_unlink+0x1bc>
80106a03:	c7 44 24 04 9c 9c 10 	movl   $0x80109c9c,0x4(%esp)
80106a0a:	80 
80106a0b:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80106a0e:	89 04 24             	mov    %eax,(%esp)
80106a11:	e8 49 b6 ff ff       	call   8010205f <namecmp>
80106a16:	85 c0                	test   %eax,%eax
80106a18:	0f 84 2a 01 00 00    	je     80106b48 <sys_unlink+0x1bc>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
80106a1e:	8d 45 c8             	lea    -0x38(%ebp),%eax
80106a21:	89 44 24 08          	mov    %eax,0x8(%esp)
80106a25:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80106a28:	89 44 24 04          	mov    %eax,0x4(%esp)
80106a2c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a2f:	89 04 24             	mov    %eax,(%esp)
80106a32:	e8 4a b6 ff ff       	call   80102081 <dirlookup>
80106a37:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106a3a:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106a3e:	0f 84 03 01 00 00    	je     80106b47 <sys_unlink+0x1bb>
    goto bad;
  ilock(ip);
80106a44:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106a47:	89 04 24             	mov    %eax,(%esp)
80106a4a:	e8 19 ae ff ff       	call   80101868 <ilock>

  if(ip->nlink < 1)
80106a4f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106a52:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106a56:	66 85 c0             	test   %ax,%ax
80106a59:	7f 0c                	jg     80106a67 <sys_unlink+0xdb>
    panic("unlink: nlink < 1");
80106a5b:	c7 04 24 9f 9c 10 80 	movl   $0x80109c9f,(%esp)
80106a62:	e8 d6 9a ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80106a67:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106a6a:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106a6e:	66 83 f8 01          	cmp    $0x1,%ax
80106a72:	75 1f                	jne    80106a93 <sys_unlink+0x107>
80106a74:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106a77:	89 04 24             	mov    %eax,(%esp)
80106a7a:	e8 ed fc ff ff       	call   8010676c <isdirempty>
80106a7f:	85 c0                	test   %eax,%eax
80106a81:	75 10                	jne    80106a93 <sys_unlink+0x107>
    iunlockput(ip);
80106a83:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106a86:	89 04 24             	mov    %eax,(%esp)
80106a89:	e8 5e b0 ff ff       	call   80101aec <iunlockput>
    goto bad;
80106a8e:	e9 b5 00 00 00       	jmp    80106b48 <sys_unlink+0x1bc>
  }

  memset(&de, 0, sizeof(de));
80106a93:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80106a9a:	00 
80106a9b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106aa2:	00 
80106aa3:	8d 45 e0             	lea    -0x20(%ebp),%eax
80106aa6:	89 04 24             	mov    %eax,(%esp)
80106aa9:	e8 90 f3 ff ff       	call   80105e3e <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80106aae:	8b 45 c8             	mov    -0x38(%ebp),%eax
80106ab1:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80106ab8:	00 
80106ab9:	89 44 24 08          	mov    %eax,0x8(%esp)
80106abd:	8d 45 e0             	lea    -0x20(%ebp),%eax
80106ac0:	89 44 24 04          	mov    %eax,0x4(%esp)
80106ac4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ac7:	89 04 24             	mov    %eax,(%esp)
80106aca:	e8 fa b3 ff ff       	call   80101ec9 <writei>
80106acf:	83 f8 10             	cmp    $0x10,%eax
80106ad2:	74 0c                	je     80106ae0 <sys_unlink+0x154>
    panic("unlink: writei");
80106ad4:	c7 04 24 b1 9c 10 80 	movl   $0x80109cb1,(%esp)
80106adb:	e8 5d 9a ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR){
80106ae0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ae3:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106ae7:	66 83 f8 01          	cmp    $0x1,%ax
80106aeb:	75 1c                	jne    80106b09 <sys_unlink+0x17d>
    dp->nlink--;
80106aed:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106af0:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106af4:	8d 50 ff             	lea    -0x1(%eax),%edx
80106af7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106afa:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80106afe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b01:	89 04 24             	mov    %eax,(%esp)
80106b04:	e8 a3 ab ff ff       	call   801016ac <iupdate>
  }
  iunlockput(dp);
80106b09:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b0c:	89 04 24             	mov    %eax,(%esp)
80106b0f:	e8 d8 af ff ff       	call   80101aec <iunlockput>

  ip->nlink--;
80106b14:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b17:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106b1b:	8d 50 ff             	lea    -0x1(%eax),%edx
80106b1e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b21:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80106b25:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b28:	89 04 24             	mov    %eax,(%esp)
80106b2b:	e8 7c ab ff ff       	call   801016ac <iupdate>
  iunlockput(ip);
80106b30:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b33:	89 04 24             	mov    %eax,(%esp)
80106b36:	e8 b1 af ff ff       	call   80101aec <iunlockput>

  commit_trans();
80106b3b:	e8 62 cf ff ff       	call   80103aa2 <commit_trans>

  return 0;
80106b40:	b8 00 00 00 00       	mov    $0x0,%eax
80106b45:	eb 16                	jmp    80106b5d <sys_unlink+0x1d1>
  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    goto bad;
80106b47:	90                   	nop
  commit_trans();

  return 0;

bad:
  iunlockput(dp);
80106b48:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b4b:	89 04 24             	mov    %eax,(%esp)
80106b4e:	e8 99 af ff ff       	call   80101aec <iunlockput>
  commit_trans();
80106b53:	e8 4a cf ff ff       	call   80103aa2 <commit_trans>
  return -1;
80106b58:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80106b5d:	c9                   	leave  
80106b5e:	c3                   	ret    

80106b5f <create>:

static struct inode*
create(char *path, short type, short major, short minor)
{
80106b5f:	55                   	push   %ebp
80106b60:	89 e5                	mov    %esp,%ebp
80106b62:	83 ec 48             	sub    $0x48,%esp
80106b65:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80106b68:	8b 55 10             	mov    0x10(%ebp),%edx
80106b6b:	8b 45 14             	mov    0x14(%ebp),%eax
80106b6e:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
80106b72:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
80106b76:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];
  if((dp = nameiparent(path, name)) == 0)
80106b7a:	8d 45 de             	lea    -0x22(%ebp),%eax
80106b7d:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b81:	8b 45 08             	mov    0x8(%ebp),%eax
80106b84:	89 04 24             	mov    %eax,(%esp)
80106b87:	e8 a0 b8 ff ff       	call   8010242c <nameiparent>
80106b8c:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106b8f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106b93:	75 0a                	jne    80106b9f <create+0x40>
    return 0;
80106b95:	b8 00 00 00 00       	mov    $0x0,%eax
80106b9a:	e9 7e 01 00 00       	jmp    80106d1d <create+0x1be>
  ilock(dp);
80106b9f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ba2:	89 04 24             	mov    %eax,(%esp)
80106ba5:	e8 be ac ff ff       	call   80101868 <ilock>
  if((ip = dirlookup(dp, name, &off)) != 0){
80106baa:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106bad:	89 44 24 08          	mov    %eax,0x8(%esp)
80106bb1:	8d 45 de             	lea    -0x22(%ebp),%eax
80106bb4:	89 44 24 04          	mov    %eax,0x4(%esp)
80106bb8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106bbb:	89 04 24             	mov    %eax,(%esp)
80106bbe:	e8 be b4 ff ff       	call   80102081 <dirlookup>
80106bc3:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106bc6:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106bca:	74 47                	je     80106c13 <create+0xb4>
    iunlockput(dp);
80106bcc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106bcf:	89 04 24             	mov    %eax,(%esp)
80106bd2:	e8 15 af ff ff       	call   80101aec <iunlockput>
    ilock(ip);
80106bd7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106bda:	89 04 24             	mov    %eax,(%esp)
80106bdd:	e8 86 ac ff ff       	call   80101868 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
80106be2:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
80106be7:	75 15                	jne    80106bfe <create+0x9f>
80106be9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106bec:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106bf0:	66 83 f8 02          	cmp    $0x2,%ax
80106bf4:	75 08                	jne    80106bfe <create+0x9f>
      return ip;
80106bf6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106bf9:	e9 1f 01 00 00       	jmp    80106d1d <create+0x1be>
    iunlockput(ip);
80106bfe:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c01:	89 04 24             	mov    %eax,(%esp)
80106c04:	e8 e3 ae ff ff       	call   80101aec <iunlockput>
    return 0;
80106c09:	b8 00 00 00 00       	mov    $0x0,%eax
80106c0e:	e9 0a 01 00 00       	jmp    80106d1d <create+0x1be>
  }
  if((ip = ialloc(dp->dev, type)) == 0)
80106c13:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
80106c17:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c1a:	8b 00                	mov    (%eax),%eax
80106c1c:	89 54 24 04          	mov    %edx,0x4(%esp)
80106c20:	89 04 24             	mov    %eax,(%esp)
80106c23:	e8 a7 a9 ff ff       	call   801015cf <ialloc>
80106c28:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106c2b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106c2f:	75 0c                	jne    80106c3d <create+0xde>
    panic("create: ialloc");
80106c31:	c7 04 24 c0 9c 10 80 	movl   $0x80109cc0,(%esp)
80106c38:	e8 00 99 ff ff       	call   8010053d <panic>
  ilock(ip);
80106c3d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c40:	89 04 24             	mov    %eax,(%esp)
80106c43:	e8 20 ac ff ff       	call   80101868 <ilock>
  ip->major = major;
80106c48:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c4b:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
80106c4f:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
80106c53:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c56:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
80106c5a:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
80106c5e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c61:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
80106c67:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c6a:	89 04 24             	mov    %eax,(%esp)
80106c6d:	e8 3a aa ff ff       	call   801016ac <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
80106c72:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
80106c77:	75 6a                	jne    80106ce3 <create+0x184>
    dp->nlink++;  // for ".."
80106c79:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c7c:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106c80:	8d 50 01             	lea    0x1(%eax),%edx
80106c83:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c86:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80106c8a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c8d:	89 04 24             	mov    %eax,(%esp)
80106c90:	e8 17 aa ff ff       	call   801016ac <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80106c95:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c98:	8b 40 04             	mov    0x4(%eax),%eax
80106c9b:	89 44 24 08          	mov    %eax,0x8(%esp)
80106c9f:	c7 44 24 04 9a 9c 10 	movl   $0x80109c9a,0x4(%esp)
80106ca6:	80 
80106ca7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106caa:	89 04 24             	mov    %eax,(%esp)
80106cad:	e8 97 b4 ff ff       	call   80102149 <dirlink>
80106cb2:	85 c0                	test   %eax,%eax
80106cb4:	78 21                	js     80106cd7 <create+0x178>
80106cb6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106cb9:	8b 40 04             	mov    0x4(%eax),%eax
80106cbc:	89 44 24 08          	mov    %eax,0x8(%esp)
80106cc0:	c7 44 24 04 9c 9c 10 	movl   $0x80109c9c,0x4(%esp)
80106cc7:	80 
80106cc8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ccb:	89 04 24             	mov    %eax,(%esp)
80106cce:	e8 76 b4 ff ff       	call   80102149 <dirlink>
80106cd3:	85 c0                	test   %eax,%eax
80106cd5:	79 0c                	jns    80106ce3 <create+0x184>
      panic("create dots");
80106cd7:	c7 04 24 cf 9c 10 80 	movl   $0x80109ccf,(%esp)
80106cde:	e8 5a 98 ff ff       	call   8010053d <panic>
  }
  if(dirlink(dp, name, ip->inum) < 0)
80106ce3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ce6:	8b 40 04             	mov    0x4(%eax),%eax
80106ce9:	89 44 24 08          	mov    %eax,0x8(%esp)
80106ced:	8d 45 de             	lea    -0x22(%ebp),%eax
80106cf0:	89 44 24 04          	mov    %eax,0x4(%esp)
80106cf4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106cf7:	89 04 24             	mov    %eax,(%esp)
80106cfa:	e8 4a b4 ff ff       	call   80102149 <dirlink>
80106cff:	85 c0                	test   %eax,%eax
80106d01:	79 0c                	jns    80106d0f <create+0x1b0>
    panic("create: dirlink");
80106d03:	c7 04 24 db 9c 10 80 	movl   $0x80109cdb,(%esp)
80106d0a:	e8 2e 98 ff ff       	call   8010053d <panic>
  iunlockput(dp);
80106d0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d12:	89 04 24             	mov    %eax,(%esp)
80106d15:	e8 d2 ad ff ff       	call   80101aec <iunlockput>

  return ip;
80106d1a:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80106d1d:	c9                   	leave  
80106d1e:	c3                   	ret    

80106d1f <fileopen>:

struct file*
fileopen(char *path, int omode)
{
80106d1f:	55                   	push   %ebp
80106d20:	89 e5                	mov    %esp,%ebp
80106d22:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  struct inode *ip;

  if(omode & O_CREATE){
80106d25:	8b 45 0c             	mov    0xc(%ebp),%eax
80106d28:	25 00 02 00 00       	and    $0x200,%eax
80106d2d:	85 c0                	test   %eax,%eax
80106d2f:	74 40                	je     80106d71 <fileopen+0x52>
    begin_trans();
80106d31:	e8 23 cd ff ff       	call   80103a59 <begin_trans>
    ip = create(path, T_FILE, 0, 0);
80106d36:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106d3d:	00 
80106d3e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106d45:	00 
80106d46:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80106d4d:	00 
80106d4e:	8b 45 08             	mov    0x8(%ebp),%eax
80106d51:	89 04 24             	mov    %eax,(%esp)
80106d54:	e8 06 fe ff ff       	call   80106b5f <create>
80106d59:	89 45 f4             	mov    %eax,-0xc(%ebp)
    commit_trans();
80106d5c:	e8 41 cd ff ff       	call   80103aa2 <commit_trans>
    if(ip == 0)
80106d61:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106d65:	75 5b                	jne    80106dc2 <fileopen+0xa3>
      return 0;
80106d67:	b8 00 00 00 00       	mov    $0x0,%eax
80106d6c:	e9 f9 00 00 00       	jmp    80106e6a <fileopen+0x14b>
  } else {
    if((ip = namei(path)) == 0)
80106d71:	8b 45 08             	mov    0x8(%ebp),%eax
80106d74:	89 04 24             	mov    %eax,(%esp)
80106d77:	e8 8e b6 ff ff       	call   8010240a <namei>
80106d7c:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106d7f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106d83:	75 0a                	jne    80106d8f <fileopen+0x70>
      return 0;
80106d85:	b8 00 00 00 00       	mov    $0x0,%eax
80106d8a:	e9 db 00 00 00       	jmp    80106e6a <fileopen+0x14b>
    ilock(ip);
80106d8f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d92:	89 04 24             	mov    %eax,(%esp)
80106d95:	e8 ce aa ff ff       	call   80101868 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80106d9a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d9d:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106da1:	66 83 f8 01          	cmp    $0x1,%ax
80106da5:	75 1b                	jne    80106dc2 <fileopen+0xa3>
80106da7:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80106dab:	74 15                	je     80106dc2 <fileopen+0xa3>
      iunlockput(ip);
80106dad:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106db0:	89 04 24             	mov    %eax,(%esp)
80106db3:	e8 34 ad ff ff       	call   80101aec <iunlockput>
      return 0;
80106db8:	b8 00 00 00 00       	mov    $0x0,%eax
80106dbd:	e9 a8 00 00 00       	jmp    80106e6a <fileopen+0x14b>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80106dc2:	e8 55 a1 ff ff       	call   80100f1c <filealloc>
80106dc7:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106dca:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106dce:	74 14                	je     80106de4 <fileopen+0xc5>
80106dd0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106dd3:	89 04 24             	mov    %eax,(%esp)
80106dd6:	e8 ca f5 ff ff       	call   801063a5 <fdalloc>
80106ddb:	89 45 ec             	mov    %eax,-0x14(%ebp)
80106dde:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80106de2:	79 23                	jns    80106e07 <fileopen+0xe8>
    if(f)
80106de4:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106de8:	74 0b                	je     80106df5 <fileopen+0xd6>
      fileclose(f);
80106dea:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ded:	89 04 24             	mov    %eax,(%esp)
80106df0:	e8 cf a1 ff ff       	call   80100fc4 <fileclose>
    iunlockput(ip);
80106df5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106df8:	89 04 24             	mov    %eax,(%esp)
80106dfb:	e8 ec ac ff ff       	call   80101aec <iunlockput>
    return 0;
80106e00:	b8 00 00 00 00       	mov    $0x0,%eax
80106e05:	eb 63                	jmp    80106e6a <fileopen+0x14b>
  }
  iunlock(ip);
80106e07:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e0a:	89 04 24             	mov    %eax,(%esp)
80106e0d:	e8 a4 ab ff ff       	call   801019b6 <iunlock>

  f->type = FD_INODE;
80106e12:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106e15:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80106e1b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106e1e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106e21:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
80106e24:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106e27:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80106e2e:	8b 45 0c             	mov    0xc(%ebp),%eax
80106e31:	83 e0 01             	and    $0x1,%eax
80106e34:	85 c0                	test   %eax,%eax
80106e36:	0f 94 c2             	sete   %dl
80106e39:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106e3c:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80106e3f:	8b 45 0c             	mov    0xc(%ebp),%eax
80106e42:	83 e0 01             	and    $0x1,%eax
80106e45:	84 c0                	test   %al,%al
80106e47:	75 0a                	jne    80106e53 <fileopen+0x134>
80106e49:	8b 45 0c             	mov    0xc(%ebp),%eax
80106e4c:	83 e0 02             	and    $0x2,%eax
80106e4f:	85 c0                	test   %eax,%eax
80106e51:	74 07                	je     80106e5a <fileopen+0x13b>
80106e53:	b8 01 00 00 00       	mov    $0x1,%eax
80106e58:	eb 05                	jmp    80106e5f <fileopen+0x140>
80106e5a:	b8 00 00 00 00       	mov    $0x0,%eax
80106e5f:	89 c2                	mov    %eax,%edx
80106e61:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106e64:	88 50 09             	mov    %dl,0x9(%eax)
  return f;
80106e67:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80106e6a:	c9                   	leave  
80106e6b:	c3                   	ret    

80106e6c <sys_open>:

int
sys_open(void)
{
80106e6c:	55                   	push   %ebp
80106e6d:	89 e5                	mov    %esp,%ebp
80106e6f:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80106e72:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106e75:	89 44 24 04          	mov    %eax,0x4(%esp)
80106e79:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106e80:	e8 a3 f3 ff ff       	call   80106228 <argstr>
80106e85:	85 c0                	test   %eax,%eax
80106e87:	78 17                	js     80106ea0 <sys_open+0x34>
80106e89:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106e8c:	89 44 24 04          	mov    %eax,0x4(%esp)
80106e90:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106e97:	e8 f2 f2 ff ff       	call   8010618e <argint>
80106e9c:	85 c0                	test   %eax,%eax
80106e9e:	79 0a                	jns    80106eaa <sys_open+0x3e>
    return -1;
80106ea0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106ea5:	e9 46 01 00 00       	jmp    80106ff0 <sys_open+0x184>
  if(omode & O_CREATE){
80106eaa:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106ead:	25 00 02 00 00       	and    $0x200,%eax
80106eb2:	85 c0                	test   %eax,%eax
80106eb4:	74 40                	je     80106ef6 <sys_open+0x8a>
    begin_trans();
80106eb6:	e8 9e cb ff ff       	call   80103a59 <begin_trans>
    ip = create(path, T_FILE, 0, 0);
80106ebb:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106ebe:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106ec5:	00 
80106ec6:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106ecd:	00 
80106ece:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80106ed5:	00 
80106ed6:	89 04 24             	mov    %eax,(%esp)
80106ed9:	e8 81 fc ff ff       	call   80106b5f <create>
80106ede:	89 45 f4             	mov    %eax,-0xc(%ebp)
    commit_trans();
80106ee1:	e8 bc cb ff ff       	call   80103aa2 <commit_trans>
    if(ip == 0)
80106ee6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106eea:	75 5c                	jne    80106f48 <sys_open+0xdc>
      return -1;
80106eec:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106ef1:	e9 fa 00 00 00       	jmp    80106ff0 <sys_open+0x184>
  } else {
    if((ip = namei(path)) == 0)
80106ef6:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106ef9:	89 04 24             	mov    %eax,(%esp)
80106efc:	e8 09 b5 ff ff       	call   8010240a <namei>
80106f01:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106f04:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106f08:	75 0a                	jne    80106f14 <sys_open+0xa8>
      return -1;
80106f0a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106f0f:	e9 dc 00 00 00       	jmp    80106ff0 <sys_open+0x184>
    ilock(ip);
80106f14:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f17:	89 04 24             	mov    %eax,(%esp)
80106f1a:	e8 49 a9 ff ff       	call   80101868 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80106f1f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f22:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106f26:	66 83 f8 01          	cmp    $0x1,%ax
80106f2a:	75 1c                	jne    80106f48 <sys_open+0xdc>
80106f2c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106f2f:	85 c0                	test   %eax,%eax
80106f31:	74 15                	je     80106f48 <sys_open+0xdc>
      iunlockput(ip);
80106f33:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f36:	89 04 24             	mov    %eax,(%esp)
80106f39:	e8 ae ab ff ff       	call   80101aec <iunlockput>
      return -1;
80106f3e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106f43:	e9 a8 00 00 00       	jmp    80106ff0 <sys_open+0x184>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80106f48:	e8 cf 9f ff ff       	call   80100f1c <filealloc>
80106f4d:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106f50:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106f54:	74 14                	je     80106f6a <sys_open+0xfe>
80106f56:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106f59:	89 04 24             	mov    %eax,(%esp)
80106f5c:	e8 44 f4 ff ff       	call   801063a5 <fdalloc>
80106f61:	89 45 ec             	mov    %eax,-0x14(%ebp)
80106f64:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80106f68:	79 23                	jns    80106f8d <sys_open+0x121>
    if(f)
80106f6a:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106f6e:	74 0b                	je     80106f7b <sys_open+0x10f>
      fileclose(f);
80106f70:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106f73:	89 04 24             	mov    %eax,(%esp)
80106f76:	e8 49 a0 ff ff       	call   80100fc4 <fileclose>
    iunlockput(ip);
80106f7b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f7e:	89 04 24             	mov    %eax,(%esp)
80106f81:	e8 66 ab ff ff       	call   80101aec <iunlockput>
    return -1;
80106f86:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106f8b:	eb 63                	jmp    80106ff0 <sys_open+0x184>
  }
  iunlock(ip);
80106f8d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f90:	89 04 24             	mov    %eax,(%esp)
80106f93:	e8 1e aa ff ff       	call   801019b6 <iunlock>

  f->type = FD_INODE;
80106f98:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106f9b:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80106fa1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106fa4:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106fa7:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
80106faa:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106fad:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80106fb4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106fb7:	83 e0 01             	and    $0x1,%eax
80106fba:	85 c0                	test   %eax,%eax
80106fbc:	0f 94 c2             	sete   %dl
80106fbf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106fc2:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80106fc5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106fc8:	83 e0 01             	and    $0x1,%eax
80106fcb:	84 c0                	test   %al,%al
80106fcd:	75 0a                	jne    80106fd9 <sys_open+0x16d>
80106fcf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106fd2:	83 e0 02             	and    $0x2,%eax
80106fd5:	85 c0                	test   %eax,%eax
80106fd7:	74 07                	je     80106fe0 <sys_open+0x174>
80106fd9:	b8 01 00 00 00       	mov    $0x1,%eax
80106fde:	eb 05                	jmp    80106fe5 <sys_open+0x179>
80106fe0:	b8 00 00 00 00       	mov    $0x0,%eax
80106fe5:	89 c2                	mov    %eax,%edx
80106fe7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106fea:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
80106fed:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
80106ff0:	c9                   	leave  
80106ff1:	c3                   	ret    

80106ff2 <sys_mkdir>:

int
sys_mkdir(void)
{
80106ff2:	55                   	push   %ebp
80106ff3:	89 e5                	mov    %esp,%ebp
80106ff5:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_trans();
80106ff8:	e8 5c ca ff ff       	call   80103a59 <begin_trans>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80106ffd:	8d 45 f0             	lea    -0x10(%ebp),%eax
80107000:	89 44 24 04          	mov    %eax,0x4(%esp)
80107004:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010700b:	e8 18 f2 ff ff       	call   80106228 <argstr>
80107010:	85 c0                	test   %eax,%eax
80107012:	78 2c                	js     80107040 <sys_mkdir+0x4e>
80107014:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107017:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
8010701e:	00 
8010701f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80107026:	00 
80107027:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010702e:	00 
8010702f:	89 04 24             	mov    %eax,(%esp)
80107032:	e8 28 fb ff ff       	call   80106b5f <create>
80107037:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010703a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010703e:	75 0c                	jne    8010704c <sys_mkdir+0x5a>
    commit_trans();
80107040:	e8 5d ca ff ff       	call   80103aa2 <commit_trans>
    return -1;
80107045:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010704a:	eb 15                	jmp    80107061 <sys_mkdir+0x6f>
  }
  iunlockput(ip);
8010704c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010704f:	89 04 24             	mov    %eax,(%esp)
80107052:	e8 95 aa ff ff       	call   80101aec <iunlockput>
  commit_trans();
80107057:	e8 46 ca ff ff       	call   80103aa2 <commit_trans>
  return 0;
8010705c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107061:	c9                   	leave  
80107062:	c3                   	ret    

80107063 <sys_mknod>:

int
sys_mknod(void)
{
80107063:	55                   	push   %ebp
80107064:	89 e5                	mov    %esp,%ebp
80107066:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
80107069:	e8 eb c9 ff ff       	call   80103a59 <begin_trans>
  if((len=argstr(0, &path)) < 0 ||
8010706e:	8d 45 ec             	lea    -0x14(%ebp),%eax
80107071:	89 44 24 04          	mov    %eax,0x4(%esp)
80107075:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010707c:	e8 a7 f1 ff ff       	call   80106228 <argstr>
80107081:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107084:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80107088:	78 5e                	js     801070e8 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
8010708a:	8d 45 e8             	lea    -0x18(%ebp),%eax
8010708d:	89 44 24 04          	mov    %eax,0x4(%esp)
80107091:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80107098:	e8 f1 f0 ff ff       	call   8010618e <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
8010709d:	85 c0                	test   %eax,%eax
8010709f:	78 47                	js     801070e8 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
801070a1:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801070a4:	89 44 24 04          	mov    %eax,0x4(%esp)
801070a8:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801070af:	e8 da f0 ff ff       	call   8010618e <argint>
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
801070b4:	85 c0                	test   %eax,%eax
801070b6:	78 30                	js     801070e8 <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
801070b8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801070bb:	0f bf c8             	movswl %ax,%ecx
801070be:	8b 45 e8             	mov    -0x18(%ebp),%eax
801070c1:	0f bf d0             	movswl %ax,%edx
801070c4:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
801070c7:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
801070cb:	89 54 24 08          	mov    %edx,0x8(%esp)
801070cf:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
801070d6:	00 
801070d7:	89 04 24             	mov    %eax,(%esp)
801070da:	e8 80 fa ff ff       	call   80106b5f <create>
801070df:	89 45 f0             	mov    %eax,-0x10(%ebp)
801070e2:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801070e6:	75 0c                	jne    801070f4 <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    commit_trans();
801070e8:	e8 b5 c9 ff ff       	call   80103aa2 <commit_trans>
    return -1;
801070ed:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801070f2:	eb 15                	jmp    80107109 <sys_mknod+0xa6>
  }
  iunlockput(ip);
801070f4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801070f7:	89 04 24             	mov    %eax,(%esp)
801070fa:	e8 ed a9 ff ff       	call   80101aec <iunlockput>
  commit_trans();
801070ff:	e8 9e c9 ff ff       	call   80103aa2 <commit_trans>
  return 0;
80107104:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107109:	c9                   	leave  
8010710a:	c3                   	ret    

8010710b <sys_chdir>:

int
sys_chdir(void)
{
8010710b:	55                   	push   %ebp
8010710c:	89 e5                	mov    %esp,%ebp
8010710e:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0)
80107111:	8d 45 f0             	lea    -0x10(%ebp),%eax
80107114:	89 44 24 04          	mov    %eax,0x4(%esp)
80107118:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010711f:	e8 04 f1 ff ff       	call   80106228 <argstr>
80107124:	85 c0                	test   %eax,%eax
80107126:	78 14                	js     8010713c <sys_chdir+0x31>
80107128:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010712b:	89 04 24             	mov    %eax,(%esp)
8010712e:	e8 d7 b2 ff ff       	call   8010240a <namei>
80107133:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107136:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010713a:	75 07                	jne    80107143 <sys_chdir+0x38>
    return -1;
8010713c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107141:	eb 57                	jmp    8010719a <sys_chdir+0x8f>
  ilock(ip);
80107143:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107146:	89 04 24             	mov    %eax,(%esp)
80107149:	e8 1a a7 ff ff       	call   80101868 <ilock>
  if(ip->type != T_DIR){
8010714e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107151:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80107155:	66 83 f8 01          	cmp    $0x1,%ax
80107159:	74 12                	je     8010716d <sys_chdir+0x62>
    iunlockput(ip);
8010715b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010715e:	89 04 24             	mov    %eax,(%esp)
80107161:	e8 86 a9 ff ff       	call   80101aec <iunlockput>
    return -1;
80107166:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010716b:	eb 2d                	jmp    8010719a <sys_chdir+0x8f>
  }
  iunlock(ip);
8010716d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107170:	89 04 24             	mov    %eax,(%esp)
80107173:	e8 3e a8 ff ff       	call   801019b6 <iunlock>
  iput(proc->cwd);
80107178:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010717e:	8b 40 68             	mov    0x68(%eax),%eax
80107181:	89 04 24             	mov    %eax,(%esp)
80107184:	e8 92 a8 ff ff       	call   80101a1b <iput>
  proc->cwd = ip;
80107189:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010718f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80107192:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
80107195:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010719a:	c9                   	leave  
8010719b:	c3                   	ret    

8010719c <sys_exec>:

int
sys_exec(void)
{
8010719c:	55                   	push   %ebp
8010719d:	89 e5                	mov    %esp,%ebp
8010719f:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
801071a5:	8d 45 f0             	lea    -0x10(%ebp),%eax
801071a8:	89 44 24 04          	mov    %eax,0x4(%esp)
801071ac:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801071b3:	e8 70 f0 ff ff       	call   80106228 <argstr>
801071b8:	85 c0                	test   %eax,%eax
801071ba:	78 1a                	js     801071d6 <sys_exec+0x3a>
801071bc:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
801071c2:	89 44 24 04          	mov    %eax,0x4(%esp)
801071c6:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801071cd:	e8 bc ef ff ff       	call   8010618e <argint>
801071d2:	85 c0                	test   %eax,%eax
801071d4:	79 0a                	jns    801071e0 <sys_exec+0x44>
    return -1;
801071d6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801071db:	e9 e2 00 00 00       	jmp    801072c2 <sys_exec+0x126>
  }
  memset(argv, 0, sizeof(argv));
801071e0:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
801071e7:	00 
801071e8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801071ef:	00 
801071f0:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
801071f6:	89 04 24             	mov    %eax,(%esp)
801071f9:	e8 40 ec ff ff       	call   80105e3e <memset>
  for(i=0;; i++){
801071fe:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
80107205:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107208:	83 f8 1f             	cmp    $0x1f,%eax
8010720b:	76 0a                	jbe    80107217 <sys_exec+0x7b>
      return -1;
8010720d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107212:	e9 ab 00 00 00       	jmp    801072c2 <sys_exec+0x126>
    if(fetchint(proc, uargv+4*i, (int*)&uarg) < 0)
80107217:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010721a:	c1 e0 02             	shl    $0x2,%eax
8010721d:	89 c2                	mov    %eax,%edx
8010721f:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80107225:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
80107228:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010722e:	8d 95 68 ff ff ff    	lea    -0x98(%ebp),%edx
80107234:	89 54 24 08          	mov    %edx,0x8(%esp)
80107238:	89 4c 24 04          	mov    %ecx,0x4(%esp)
8010723c:	89 04 24             	mov    %eax,(%esp)
8010723f:	e8 b8 ee ff ff       	call   801060fc <fetchint>
80107244:	85 c0                	test   %eax,%eax
80107246:	79 07                	jns    8010724f <sys_exec+0xb3>
      return -1;
80107248:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010724d:	eb 73                	jmp    801072c2 <sys_exec+0x126>
    if(uarg == 0){
8010724f:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80107255:	85 c0                	test   %eax,%eax
80107257:	75 26                	jne    8010727f <sys_exec+0xe3>
      argv[i] = 0;
80107259:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010725c:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
80107263:	00 00 00 00 
      break;
80107267:	90                   	nop
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
80107268:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010726b:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
80107271:	89 54 24 04          	mov    %edx,0x4(%esp)
80107275:	89 04 24             	mov    %eax,(%esp)
80107278:	e8 7f 98 ff ff       	call   80100afc <exec>
8010727d:	eb 43                	jmp    801072c2 <sys_exec+0x126>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
8010727f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107282:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80107289:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
8010728f:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
80107292:	8b 95 68 ff ff ff    	mov    -0x98(%ebp),%edx
80107298:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010729e:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801072a2:	89 54 24 04          	mov    %edx,0x4(%esp)
801072a6:	89 04 24             	mov    %eax,(%esp)
801072a9:	e8 82 ee ff ff       	call   80106130 <fetchstr>
801072ae:	85 c0                	test   %eax,%eax
801072b0:	79 07                	jns    801072b9 <sys_exec+0x11d>
      return -1;
801072b2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801072b7:	eb 09                	jmp    801072c2 <sys_exec+0x126>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
801072b9:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
801072bd:	e9 43 ff ff ff       	jmp    80107205 <sys_exec+0x69>
  return exec(path, argv);
}
801072c2:	c9                   	leave  
801072c3:	c3                   	ret    

801072c4 <sys_pipe>:

int
sys_pipe(void)
{
801072c4:	55                   	push   %ebp
801072c5:	89 e5                	mov    %esp,%ebp
801072c7:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
801072ca:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
801072d1:	00 
801072d2:	8d 45 ec             	lea    -0x14(%ebp),%eax
801072d5:	89 44 24 04          	mov    %eax,0x4(%esp)
801072d9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801072e0:	e8 e1 ee ff ff       	call   801061c6 <argptr>
801072e5:	85 c0                	test   %eax,%eax
801072e7:	79 0a                	jns    801072f3 <sys_pipe+0x2f>
    return -1;
801072e9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801072ee:	e9 9b 00 00 00       	jmp    8010738e <sys_pipe+0xca>
  if(pipealloc(&rf, &wf) < 0)
801072f3:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801072f6:	89 44 24 04          	mov    %eax,0x4(%esp)
801072fa:	8d 45 e8             	lea    -0x18(%ebp),%eax
801072fd:	89 04 24             	mov    %eax,(%esp)
80107300:	e8 6f d1 ff ff       	call   80104474 <pipealloc>
80107305:	85 c0                	test   %eax,%eax
80107307:	79 07                	jns    80107310 <sys_pipe+0x4c>
    return -1;
80107309:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010730e:	eb 7e                	jmp    8010738e <sys_pipe+0xca>
  fd0 = -1;
80107310:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80107317:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010731a:	89 04 24             	mov    %eax,(%esp)
8010731d:	e8 83 f0 ff ff       	call   801063a5 <fdalloc>
80107322:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107325:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80107329:	78 14                	js     8010733f <sys_pipe+0x7b>
8010732b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010732e:	89 04 24             	mov    %eax,(%esp)
80107331:	e8 6f f0 ff ff       	call   801063a5 <fdalloc>
80107336:	89 45 f0             	mov    %eax,-0x10(%ebp)
80107339:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010733d:	79 37                	jns    80107376 <sys_pipe+0xb2>
    if(fd0 >= 0)
8010733f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80107343:	78 14                	js     80107359 <sys_pipe+0x95>
      proc->ofile[fd0] = 0;
80107345:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010734b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010734e:	83 c2 08             	add    $0x8,%edx
80107351:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80107358:	00 
    fileclose(rf);
80107359:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010735c:	89 04 24             	mov    %eax,(%esp)
8010735f:	e8 60 9c ff ff       	call   80100fc4 <fileclose>
    fileclose(wf);
80107364:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80107367:	89 04 24             	mov    %eax,(%esp)
8010736a:	e8 55 9c ff ff       	call   80100fc4 <fileclose>
    return -1;
8010736f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107374:	eb 18                	jmp    8010738e <sys_pipe+0xca>
  }
  fd[0] = fd0;
80107376:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107379:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010737c:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
8010737e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107381:	8d 50 04             	lea    0x4(%eax),%edx
80107384:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107387:	89 02                	mov    %eax,(%edx)
  return 0;
80107389:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010738e:	c9                   	leave  
8010738f:	c3                   	ret    

80107390 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80107390:	55                   	push   %ebp
80107391:	89 e5                	mov    %esp,%ebp
80107393:	83 ec 08             	sub    $0x8,%esp
  return fork();
80107396:	e8 ad dd ff ff       	call   80105148 <fork>
}
8010739b:	c9                   	leave  
8010739c:	c3                   	ret    

8010739d <sys_exit>:

int
sys_exit(void)
{
8010739d:	55                   	push   %ebp
8010739e:	89 e5                	mov    %esp,%ebp
801073a0:	83 ec 08             	sub    $0x8,%esp
  exit();
801073a3:	e8 03 df ff ff       	call   801052ab <exit>
  return 0;  // not reached
801073a8:	b8 00 00 00 00       	mov    $0x0,%eax
}
801073ad:	c9                   	leave  
801073ae:	c3                   	ret    

801073af <sys_wait>:

int
sys_wait(void)
{
801073af:	55                   	push   %ebp
801073b0:	89 e5                	mov    %esp,%ebp
801073b2:	83 ec 08             	sub    $0x8,%esp
  return wait();
801073b5:	e8 2d e0 ff ff       	call   801053e7 <wait>
}
801073ba:	c9                   	leave  
801073bb:	c3                   	ret    

801073bc <sys_kill>:

int
sys_kill(void)
{
801073bc:	55                   	push   %ebp
801073bd:	89 e5                	mov    %esp,%ebp
801073bf:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
801073c2:	8d 45 f4             	lea    -0xc(%ebp),%eax
801073c5:	89 44 24 04          	mov    %eax,0x4(%esp)
801073c9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801073d0:	e8 b9 ed ff ff       	call   8010618e <argint>
801073d5:	85 c0                	test   %eax,%eax
801073d7:	79 07                	jns    801073e0 <sys_kill+0x24>
    return -1;
801073d9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801073de:	eb 0b                	jmp    801073eb <sys_kill+0x2f>
  return kill(pid);
801073e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801073e3:	89 04 24             	mov    %eax,(%esp)
801073e6:	e8 f7 e4 ff ff       	call   801058e2 <kill>
}
801073eb:	c9                   	leave  
801073ec:	c3                   	ret    

801073ed <sys_getpid>:

int
sys_getpid(void)
{
801073ed:	55                   	push   %ebp
801073ee:	89 e5                	mov    %esp,%ebp
  return proc->pid;
801073f0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801073f6:	8b 40 10             	mov    0x10(%eax),%eax
}
801073f9:	5d                   	pop    %ebp
801073fa:	c3                   	ret    

801073fb <sys_sbrk>:

int
sys_sbrk(void)
{
801073fb:	55                   	push   %ebp
801073fc:	89 e5                	mov    %esp,%ebp
801073fe:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80107401:	8d 45 f0             	lea    -0x10(%ebp),%eax
80107404:	89 44 24 04          	mov    %eax,0x4(%esp)
80107408:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010740f:	e8 7a ed ff ff       	call   8010618e <argint>
80107414:	85 c0                	test   %eax,%eax
80107416:	79 07                	jns    8010741f <sys_sbrk+0x24>
    return -1;
80107418:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010741d:	eb 24                	jmp    80107443 <sys_sbrk+0x48>
  addr = proc->sz;
8010741f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107425:	8b 00                	mov    (%eax),%eax
80107427:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
8010742a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010742d:	89 04 24             	mov    %eax,(%esp)
80107430:	e8 6e dc ff ff       	call   801050a3 <growproc>
80107435:	85 c0                	test   %eax,%eax
80107437:	79 07                	jns    80107440 <sys_sbrk+0x45>
    return -1;
80107439:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010743e:	eb 03                	jmp    80107443 <sys_sbrk+0x48>
  return addr;
80107440:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80107443:	c9                   	leave  
80107444:	c3                   	ret    

80107445 <sys_sleep>:

int
sys_sleep(void)
{
80107445:	55                   	push   %ebp
80107446:	89 e5                	mov    %esp,%ebp
80107448:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
8010744b:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010744e:	89 44 24 04          	mov    %eax,0x4(%esp)
80107452:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107459:	e8 30 ed ff ff       	call   8010618e <argint>
8010745e:	85 c0                	test   %eax,%eax
80107460:	79 07                	jns    80107469 <sys_sleep+0x24>
    return -1;
80107462:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107467:	eb 6c                	jmp    801074d5 <sys_sleep+0x90>
  acquire(&tickslock);
80107469:	c7 04 24 80 9b 12 80 	movl   $0x80129b80,(%esp)
80107470:	e8 42 e7 ff ff       	call   80105bb7 <acquire>
  ticks0 = ticks;
80107475:	a1 c0 a3 12 80       	mov    0x8012a3c0,%eax
8010747a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
8010747d:	eb 34                	jmp    801074b3 <sys_sleep+0x6e>
    if(proc->killed){
8010747f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107485:	8b 40 24             	mov    0x24(%eax),%eax
80107488:	85 c0                	test   %eax,%eax
8010748a:	74 13                	je     8010749f <sys_sleep+0x5a>
      release(&tickslock);
8010748c:	c7 04 24 80 9b 12 80 	movl   $0x80129b80,(%esp)
80107493:	e8 ba e7 ff ff       	call   80105c52 <release>
      return -1;
80107498:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010749d:	eb 36                	jmp    801074d5 <sys_sleep+0x90>
    }
    sleep(&ticks, &tickslock);
8010749f:	c7 44 24 04 80 9b 12 	movl   $0x80129b80,0x4(%esp)
801074a6:	80 
801074a7:	c7 04 24 c0 a3 12 80 	movl   $0x8012a3c0,(%esp)
801074ae:	e8 92 e2 ff ff       	call   80105745 <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
801074b3:	a1 c0 a3 12 80       	mov    0x8012a3c0,%eax
801074b8:	89 c2                	mov    %eax,%edx
801074ba:	2b 55 f4             	sub    -0xc(%ebp),%edx
801074bd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801074c0:	39 c2                	cmp    %eax,%edx
801074c2:	72 bb                	jb     8010747f <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
801074c4:	c7 04 24 80 9b 12 80 	movl   $0x80129b80,(%esp)
801074cb:	e8 82 e7 ff ff       	call   80105c52 <release>
  return 0;
801074d0:	b8 00 00 00 00       	mov    $0x0,%eax
}
801074d5:	c9                   	leave  
801074d6:	c3                   	ret    

801074d7 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
801074d7:	55                   	push   %ebp
801074d8:	89 e5                	mov    %esp,%ebp
801074da:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
801074dd:	c7 04 24 80 9b 12 80 	movl   $0x80129b80,(%esp)
801074e4:	e8 ce e6 ff ff       	call   80105bb7 <acquire>
  xticks = ticks;
801074e9:	a1 c0 a3 12 80       	mov    0x8012a3c0,%eax
801074ee:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
801074f1:	c7 04 24 80 9b 12 80 	movl   $0x80129b80,(%esp)
801074f8:	e8 55 e7 ff ff       	call   80105c52 <release>
  return xticks;
801074fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80107500:	c9                   	leave  
80107501:	c3                   	ret    

80107502 <sys_enableSwapping>:

void
sys_enableSwapping(void)
{
80107502:	55                   	push   %ebp
80107503:	89 e5                	mov    %esp,%ebp
  swapFlag = 1;
80107505:	c7 05 80 c6 10 80 01 	movl   $0x1,0x8010c680
8010750c:	00 00 00 
}
8010750f:	5d                   	pop    %ebp
80107510:	c3                   	ret    

80107511 <sys_disableSwapping>:

void
sys_disableSwapping(void)
{
80107511:	55                   	push   %ebp
80107512:	89 e5                	mov    %esp,%ebp
  swapFlag = 0;
80107514:	c7 05 80 c6 10 80 00 	movl   $0x0,0x8010c680
8010751b:	00 00 00 
}
8010751e:	5d                   	pop    %ebp
8010751f:	c3                   	ret    

80107520 <sys_sleep2>:

int
sys_sleep2(void)
{
80107520:	55                   	push   %ebp
80107521:	89 e5                	mov    %esp,%ebp
80107523:	83 ec 18             	sub    $0x18,%esp
  acquire(&tickslock);
80107526:	c7 04 24 80 9b 12 80 	movl   $0x80129b80,(%esp)
8010752d:	e8 85 e6 ff ff       	call   80105bb7 <acquire>
  if(proc->killed){
80107532:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107538:	8b 40 24             	mov    0x24(%eax),%eax
8010753b:	85 c0                	test   %eax,%eax
8010753d:	74 13                	je     80107552 <sys_sleep2+0x32>
    release(&tickslock);
8010753f:	c7 04 24 80 9b 12 80 	movl   $0x80129b80,(%esp)
80107546:	e8 07 e7 ff ff       	call   80105c52 <release>
    return -1;
8010754b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107550:	eb 25                	jmp    80107577 <sys_sleep2+0x57>
  }
  sleep(&swapFlag, &tickslock);
80107552:	c7 44 24 04 80 9b 12 	movl   $0x80129b80,0x4(%esp)
80107559:	80 
8010755a:	c7 04 24 80 c6 10 80 	movl   $0x8010c680,(%esp)
80107561:	e8 df e1 ff ff       	call   80105745 <sleep>
  release(&tickslock);
80107566:	c7 04 24 80 9b 12 80 	movl   $0x80129b80,(%esp)
8010756d:	e8 e0 e6 ff ff       	call   80105c52 <release>
  return 0;
80107572:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107577:	c9                   	leave  
80107578:	c3                   	ret    

80107579 <sys_wakeup2>:

int
sys_wakeup2(void)
{
80107579:	55                   	push   %ebp
8010757a:	89 e5                	mov    %esp,%ebp
8010757c:	83 ec 18             	sub    $0x18,%esp
  wakeup(&swapFlag);
8010757f:	c7 04 24 80 c6 10 80 	movl   $0x8010c680,(%esp)
80107586:	e8 2c e3 ff ff       	call   801058b7 <wakeup>
  return 0;
8010758b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107590:	c9                   	leave  
80107591:	c3                   	ret    

80107592 <sys_getAllocatedPages>:

int
sys_getAllocatedPages(void)
{
80107592:	55                   	push   %ebp
80107593:	89 e5                	mov    %esp,%ebp
80107595:	83 ec 28             	sub    $0x28,%esp
  int pid;
  if(argint(0, &pid) < 0)
80107598:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010759b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010759f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801075a6:	e8 e3 eb ff ff       	call   8010618e <argint>
801075ab:	85 c0                	test   %eax,%eax
801075ad:	79 07                	jns    801075b6 <sys_getAllocatedPages+0x24>
    return -1;
801075af:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801075b4:	eb 0b                	jmp    801075c1 <sys_getAllocatedPages+0x2f>
  return getAllocatedPages(pid);
801075b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075b9:	89 04 24             	mov    %eax,(%esp)
801075bc:	e8 bb e4 ff ff       	call   80105a7c <getAllocatedPages>
}
801075c1:	c9                   	leave  
801075c2:	c3                   	ret    

801075c3 <sys_shmget>:

int 
sys_shmget(void)
{
801075c3:	55                   	push   %ebp
801075c4:	89 e5                	mov    %esp,%ebp
801075c6:	83 ec 28             	sub    $0x28,%esp
  int key,size, shmflg;
  
  if(argint(0, &key) < 0)
801075c9:	8d 45 f4             	lea    -0xc(%ebp),%eax
801075cc:	89 44 24 04          	mov    %eax,0x4(%esp)
801075d0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801075d7:	e8 b2 eb ff ff       	call   8010618e <argint>
801075dc:	85 c0                	test   %eax,%eax
801075de:	79 07                	jns    801075e7 <sys_shmget+0x24>
    return -1;
801075e0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801075e5:	eb 65                	jmp    8010764c <sys_shmget+0x89>
  
  if(argint(1, &size) < 0)
801075e7:	8d 45 f0             	lea    -0x10(%ebp),%eax
801075ea:	89 44 24 04          	mov    %eax,0x4(%esp)
801075ee:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801075f5:	e8 94 eb ff ff       	call   8010618e <argint>
801075fa:	85 c0                	test   %eax,%eax
801075fc:	79 07                	jns    80107605 <sys_shmget+0x42>
    return -1;
801075fe:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107603:	eb 47                	jmp    8010764c <sys_shmget+0x89>
  if(size<0)
80107605:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107608:	85 c0                	test   %eax,%eax
8010760a:	79 07                	jns    80107613 <sys_shmget+0x50>
    return -1;
8010760c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107611:	eb 39                	jmp    8010764c <sys_shmget+0x89>
  
  if(argint(2, &shmflg) < 0)
80107613:	8d 45 ec             	lea    -0x14(%ebp),%eax
80107616:	89 44 24 04          	mov    %eax,0x4(%esp)
8010761a:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80107621:	e8 68 eb ff ff       	call   8010618e <argint>
80107626:	85 c0                	test   %eax,%eax
80107628:	79 07                	jns    80107631 <sys_shmget+0x6e>
    return -1;
8010762a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010762f:	eb 1b                	jmp    8010764c <sys_shmget+0x89>
  
  return shmget(key, (uint)size,shmflg);
80107631:	8b 4d ec             	mov    -0x14(%ebp),%ecx
80107634:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107637:	89 c2                	mov    %eax,%edx
80107639:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010763c:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80107640:	89 54 24 04          	mov    %edx,0x4(%esp)
80107644:	89 04 24             	mov    %eax,(%esp)
80107647:	e8 11 b5 ff ff       	call   80102b5d <shmget>
}
8010764c:	c9                   	leave  
8010764d:	c3                   	ret    

8010764e <sys_shmdel>:

int 
sys_shmdel(void)
{
8010764e:	55                   	push   %ebp
8010764f:	89 e5                	mov    %esp,%ebp
80107651:	83 ec 28             	sub    $0x28,%esp
  int shmid;
  if(argint(0, &shmid) < 0)
80107654:	8d 45 f4             	lea    -0xc(%ebp),%eax
80107657:	89 44 24 04          	mov    %eax,0x4(%esp)
8010765b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107662:	e8 27 eb ff ff       	call   8010618e <argint>
80107667:	85 c0                	test   %eax,%eax
80107669:	79 07                	jns    80107672 <sys_shmdel+0x24>
    return -1;
8010766b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107670:	eb 0b                	jmp    8010767d <sys_shmdel+0x2f>
  
  return shmdel(shmid);
80107672:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107675:	89 04 24             	mov    %eax,(%esp)
80107678:	e8 84 b6 ff ff       	call   80102d01 <shmdel>
}
8010767d:	c9                   	leave  
8010767e:	c3                   	ret    

8010767f <sys_shmat>:

void *
sys_shmat(void)
{
8010767f:	55                   	push   %ebp
80107680:	89 e5                	mov    %esp,%ebp
80107682:	83 ec 28             	sub    $0x28,%esp
  int shmid,shmflg;
  
  if(argint(0, &shmid) < 0)
80107685:	8d 45 f4             	lea    -0xc(%ebp),%eax
80107688:	89 44 24 04          	mov    %eax,0x4(%esp)
8010768c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107693:	e8 f6 ea ff ff       	call   8010618e <argint>
80107698:	85 c0                	test   %eax,%eax
8010769a:	79 07                	jns    801076a3 <sys_shmat+0x24>
    return (void*)-1;
8010769c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801076a1:	eb 30                	jmp    801076d3 <sys_shmat+0x54>
  
  if(argint(1, &shmflg) < 0)
801076a3:	8d 45 f0             	lea    -0x10(%ebp),%eax
801076a6:	89 44 24 04          	mov    %eax,0x4(%esp)
801076aa:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801076b1:	e8 d8 ea ff ff       	call   8010618e <argint>
801076b6:	85 c0                	test   %eax,%eax
801076b8:	79 07                	jns    801076c1 <sys_shmat+0x42>
    return (void*)-1;
801076ba:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801076bf:	eb 12                	jmp    801076d3 <sys_shmat+0x54>
  
  return shmat(shmid,shmflg);
801076c1:	8b 55 f0             	mov    -0x10(%ebp),%edx
801076c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076c7:	89 54 24 04          	mov    %edx,0x4(%esp)
801076cb:	89 04 24             	mov    %eax,(%esp)
801076ce:	e8 09 b7 ff ff       	call   80102ddc <shmat>
}
801076d3:	c9                   	leave  
801076d4:	c3                   	ret    

801076d5 <sys_shmdt>:

int 
sys_shmdt(void)
{
801076d5:	55                   	push   %ebp
801076d6:	89 e5                	mov    %esp,%ebp
801076d8:	83 ec 28             	sub    $0x28,%esp
  void* shmaddr;
  if(argptr(0, (void*)&shmaddr,sizeof(void*)) < 0)
801076db:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
801076e2:	00 
801076e3:	8d 45 f4             	lea    -0xc(%ebp),%eax
801076e6:	89 44 24 04          	mov    %eax,0x4(%esp)
801076ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801076f1:	e8 d0 ea ff ff       	call   801061c6 <argptr>
801076f6:	85 c0                	test   %eax,%eax
801076f8:	79 07                	jns    80107701 <sys_shmdt+0x2c>
    return -1;
801076fa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801076ff:	eb 0b                	jmp    8010770c <sys_shmdt+0x37>
  return shmdt(shmaddr);
80107701:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107704:	89 04 24             	mov    %eax,(%esp)
80107707:	e8 e8 b8 ff ff       	call   80102ff4 <shmdt>
}
8010770c:	c9                   	leave  
8010770d:	c3                   	ret    
	...

80107710 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80107710:	55                   	push   %ebp
80107711:	89 e5                	mov    %esp,%ebp
80107713:	83 ec 08             	sub    $0x8,%esp
80107716:	8b 55 08             	mov    0x8(%ebp),%edx
80107719:	8b 45 0c             	mov    0xc(%ebp),%eax
8010771c:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80107720:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80107723:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80107727:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
8010772b:	ee                   	out    %al,(%dx)
}
8010772c:	c9                   	leave  
8010772d:	c3                   	ret    

8010772e <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
8010772e:	55                   	push   %ebp
8010772f:	89 e5                	mov    %esp,%ebp
80107731:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
80107734:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
8010773b:	00 
8010773c:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
80107743:	e8 c8 ff ff ff       	call   80107710 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
80107748:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
8010774f:	00 
80107750:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
80107757:	e8 b4 ff ff ff       	call   80107710 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
8010775c:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
80107763:	00 
80107764:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
8010776b:	e8 a0 ff ff ff       	call   80107710 <outb>
  picenable(IRQ_TIMER);
80107770:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107777:	e8 81 cb ff ff       	call   801042fd <picenable>
}
8010777c:	c9                   	leave  
8010777d:	c3                   	ret    
	...

80107780 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80107780:	1e                   	push   %ds
  pushl %es
80107781:	06                   	push   %es
  pushl %fs
80107782:	0f a0                	push   %fs
  pushl %gs
80107784:	0f a8                	push   %gs
  pushal
80107786:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
80107787:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
8010778b:	8e d8                	mov    %eax,%ds
  movw %ax, %es
8010778d:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
8010778f:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
80107793:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
80107795:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
80107797:	54                   	push   %esp
  call trap
80107798:	e8 de 01 00 00       	call   8010797b <trap>
  addl $4, %esp
8010779d:	83 c4 04             	add    $0x4,%esp

801077a0 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
801077a0:	61                   	popa   
  popl %gs
801077a1:	0f a9                	pop    %gs
  popl %fs
801077a3:	0f a1                	pop    %fs
  popl %es
801077a5:	07                   	pop    %es
  popl %ds
801077a6:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
801077a7:	83 c4 08             	add    $0x8,%esp
  iret
801077aa:	cf                   	iret   
	...

801077ac <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
801077ac:	55                   	push   %ebp
801077ad:	89 e5                	mov    %esp,%ebp
801077af:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
801077b2:	8b 45 0c             	mov    0xc(%ebp),%eax
801077b5:	83 e8 01             	sub    $0x1,%eax
801077b8:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
801077bc:	8b 45 08             	mov    0x8(%ebp),%eax
801077bf:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
801077c3:	8b 45 08             	mov    0x8(%ebp),%eax
801077c6:	c1 e8 10             	shr    $0x10,%eax
801077c9:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
801077cd:	8d 45 fa             	lea    -0x6(%ebp),%eax
801077d0:	0f 01 18             	lidtl  (%eax)
}
801077d3:	c9                   	leave  
801077d4:	c3                   	ret    

801077d5 <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
801077d5:	55                   	push   %ebp
801077d6:	89 e5                	mov    %esp,%ebp
801077d8:	53                   	push   %ebx
801077d9:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
801077dc:	0f 20 d3             	mov    %cr2,%ebx
801077df:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return val;
801077e2:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
801077e5:	83 c4 10             	add    $0x10,%esp
801077e8:	5b                   	pop    %ebx
801077e9:	5d                   	pop    %ebp
801077ea:	c3                   	ret    

801077eb <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
801077eb:	55                   	push   %ebp
801077ec:	89 e5                	mov    %esp,%ebp
801077ee:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
801077f1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801077f8:	e9 c3 00 00 00       	jmp    801078c0 <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
801077fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107800:	8b 04 85 bc c0 10 80 	mov    -0x7fef3f44(,%eax,4),%eax
80107807:	89 c2                	mov    %eax,%edx
80107809:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010780c:	66 89 14 c5 c0 9b 12 	mov    %dx,-0x7fed6440(,%eax,8)
80107813:	80 
80107814:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107817:	66 c7 04 c5 c2 9b 12 	movw   $0x8,-0x7fed643e(,%eax,8)
8010781e:	80 08 00 
80107821:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107824:	0f b6 14 c5 c4 9b 12 	movzbl -0x7fed643c(,%eax,8),%edx
8010782b:	80 
8010782c:	83 e2 e0             	and    $0xffffffe0,%edx
8010782f:	88 14 c5 c4 9b 12 80 	mov    %dl,-0x7fed643c(,%eax,8)
80107836:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107839:	0f b6 14 c5 c4 9b 12 	movzbl -0x7fed643c(,%eax,8),%edx
80107840:	80 
80107841:	83 e2 1f             	and    $0x1f,%edx
80107844:	88 14 c5 c4 9b 12 80 	mov    %dl,-0x7fed643c(,%eax,8)
8010784b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010784e:	0f b6 14 c5 c5 9b 12 	movzbl -0x7fed643b(,%eax,8),%edx
80107855:	80 
80107856:	83 e2 f0             	and    $0xfffffff0,%edx
80107859:	83 ca 0e             	or     $0xe,%edx
8010785c:	88 14 c5 c5 9b 12 80 	mov    %dl,-0x7fed643b(,%eax,8)
80107863:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107866:	0f b6 14 c5 c5 9b 12 	movzbl -0x7fed643b(,%eax,8),%edx
8010786d:	80 
8010786e:	83 e2 ef             	and    $0xffffffef,%edx
80107871:	88 14 c5 c5 9b 12 80 	mov    %dl,-0x7fed643b(,%eax,8)
80107878:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010787b:	0f b6 14 c5 c5 9b 12 	movzbl -0x7fed643b(,%eax,8),%edx
80107882:	80 
80107883:	83 e2 9f             	and    $0xffffff9f,%edx
80107886:	88 14 c5 c5 9b 12 80 	mov    %dl,-0x7fed643b(,%eax,8)
8010788d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107890:	0f b6 14 c5 c5 9b 12 	movzbl -0x7fed643b(,%eax,8),%edx
80107897:	80 
80107898:	83 ca 80             	or     $0xffffff80,%edx
8010789b:	88 14 c5 c5 9b 12 80 	mov    %dl,-0x7fed643b(,%eax,8)
801078a2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078a5:	8b 04 85 bc c0 10 80 	mov    -0x7fef3f44(,%eax,4),%eax
801078ac:	c1 e8 10             	shr    $0x10,%eax
801078af:	89 c2                	mov    %eax,%edx
801078b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078b4:	66 89 14 c5 c6 9b 12 	mov    %dx,-0x7fed643a(,%eax,8)
801078bb:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
801078bc:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801078c0:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
801078c7:	0f 8e 30 ff ff ff    	jle    801077fd <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
801078cd:	a1 bc c1 10 80       	mov    0x8010c1bc,%eax
801078d2:	66 a3 c0 9d 12 80    	mov    %ax,0x80129dc0
801078d8:	66 c7 05 c2 9d 12 80 	movw   $0x8,0x80129dc2
801078df:	08 00 
801078e1:	0f b6 05 c4 9d 12 80 	movzbl 0x80129dc4,%eax
801078e8:	83 e0 e0             	and    $0xffffffe0,%eax
801078eb:	a2 c4 9d 12 80       	mov    %al,0x80129dc4
801078f0:	0f b6 05 c4 9d 12 80 	movzbl 0x80129dc4,%eax
801078f7:	83 e0 1f             	and    $0x1f,%eax
801078fa:	a2 c4 9d 12 80       	mov    %al,0x80129dc4
801078ff:	0f b6 05 c5 9d 12 80 	movzbl 0x80129dc5,%eax
80107906:	83 c8 0f             	or     $0xf,%eax
80107909:	a2 c5 9d 12 80       	mov    %al,0x80129dc5
8010790e:	0f b6 05 c5 9d 12 80 	movzbl 0x80129dc5,%eax
80107915:	83 e0 ef             	and    $0xffffffef,%eax
80107918:	a2 c5 9d 12 80       	mov    %al,0x80129dc5
8010791d:	0f b6 05 c5 9d 12 80 	movzbl 0x80129dc5,%eax
80107924:	83 c8 60             	or     $0x60,%eax
80107927:	a2 c5 9d 12 80       	mov    %al,0x80129dc5
8010792c:	0f b6 05 c5 9d 12 80 	movzbl 0x80129dc5,%eax
80107933:	83 c8 80             	or     $0xffffff80,%eax
80107936:	a2 c5 9d 12 80       	mov    %al,0x80129dc5
8010793b:	a1 bc c1 10 80       	mov    0x8010c1bc,%eax
80107940:	c1 e8 10             	shr    $0x10,%eax
80107943:	66 a3 c6 9d 12 80    	mov    %ax,0x80129dc6
  
  initlock(&tickslock, "time");
80107949:	c7 44 24 04 ec 9c 10 	movl   $0x80109cec,0x4(%esp)
80107950:	80 
80107951:	c7 04 24 80 9b 12 80 	movl   $0x80129b80,(%esp)
80107958:	e8 39 e2 ff ff       	call   80105b96 <initlock>
}
8010795d:	c9                   	leave  
8010795e:	c3                   	ret    

8010795f <idtinit>:

void
idtinit(void)
{
8010795f:	55                   	push   %ebp
80107960:	89 e5                	mov    %esp,%ebp
80107962:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
80107965:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
8010796c:	00 
8010796d:	c7 04 24 c0 9b 12 80 	movl   $0x80129bc0,(%esp)
80107974:	e8 33 fe ff ff       	call   801077ac <lidt>
}
80107979:	c9                   	leave  
8010797a:	c3                   	ret    

8010797b <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
8010797b:	55                   	push   %ebp
8010797c:	89 e5                	mov    %esp,%ebp
8010797e:	57                   	push   %edi
8010797f:	56                   	push   %esi
80107980:	53                   	push   %ebx
80107981:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
80107984:	8b 45 08             	mov    0x8(%ebp),%eax
80107987:	8b 40 30             	mov    0x30(%eax),%eax
8010798a:	83 f8 40             	cmp    $0x40,%eax
8010798d:	75 3e                	jne    801079cd <trap+0x52>
    if(proc->killed)
8010798f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107995:	8b 40 24             	mov    0x24(%eax),%eax
80107998:	85 c0                	test   %eax,%eax
8010799a:	74 05                	je     801079a1 <trap+0x26>
      exit();
8010799c:	e8 0a d9 ff ff       	call   801052ab <exit>
    proc->tf = tf;
801079a1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801079a7:	8b 55 08             	mov    0x8(%ebp),%edx
801079aa:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
801079ad:	e8 b9 e8 ff ff       	call   8010626b <syscall>
    if(proc->killed)
801079b2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801079b8:	8b 40 24             	mov    0x24(%eax),%eax
801079bb:	85 c0                	test   %eax,%eax
801079bd:	0f 84 34 02 00 00    	je     80107bf7 <trap+0x27c>
      exit();
801079c3:	e8 e3 d8 ff ff       	call   801052ab <exit>
    return;
801079c8:	e9 2a 02 00 00       	jmp    80107bf7 <trap+0x27c>
  }

  switch(tf->trapno){
801079cd:	8b 45 08             	mov    0x8(%ebp),%eax
801079d0:	8b 40 30             	mov    0x30(%eax),%eax
801079d3:	83 e8 20             	sub    $0x20,%eax
801079d6:	83 f8 1f             	cmp    $0x1f,%eax
801079d9:	0f 87 bc 00 00 00    	ja     80107a9b <trap+0x120>
801079df:	8b 04 85 94 9d 10 80 	mov    -0x7fef626c(,%eax,4),%eax
801079e6:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
801079e8:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801079ee:	0f b6 00             	movzbl (%eax),%eax
801079f1:	84 c0                	test   %al,%al
801079f3:	75 31                	jne    80107a26 <trap+0xab>
      acquire(&tickslock);
801079f5:	c7 04 24 80 9b 12 80 	movl   $0x80129b80,(%esp)
801079fc:	e8 b6 e1 ff ff       	call   80105bb7 <acquire>
      ticks++;
80107a01:	a1 c0 a3 12 80       	mov    0x8012a3c0,%eax
80107a06:	83 c0 01             	add    $0x1,%eax
80107a09:	a3 c0 a3 12 80       	mov    %eax,0x8012a3c0
      wakeup(&ticks);
80107a0e:	c7 04 24 c0 a3 12 80 	movl   $0x8012a3c0,(%esp)
80107a15:	e8 9d de ff ff       	call   801058b7 <wakeup>
      release(&tickslock);
80107a1a:	c7 04 24 80 9b 12 80 	movl   $0x80129b80,(%esp)
80107a21:	e8 2c e2 ff ff       	call   80105c52 <release>
    }
    lapiceoi();
80107a26:	e8 fa bc ff ff       	call   80103725 <lapiceoi>
    break;
80107a2b:	e9 41 01 00 00       	jmp    80107b71 <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
80107a30:	e8 c2 ac ff ff       	call   801026f7 <ideintr>
    lapiceoi();
80107a35:	e8 eb bc ff ff       	call   80103725 <lapiceoi>
    break;
80107a3a:	e9 32 01 00 00       	jmp    80107b71 <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
80107a3f:	e8 bf ba ff ff       	call   80103503 <kbdintr>
    lapiceoi();
80107a44:	e8 dc bc ff ff       	call   80103725 <lapiceoi>
    break;
80107a49:	e9 23 01 00 00       	jmp    80107b71 <trap+0x1f6>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
80107a4e:	e8 a9 03 00 00       	call   80107dfc <uartintr>
    lapiceoi();
80107a53:	e8 cd bc ff ff       	call   80103725 <lapiceoi>
    break;
80107a58:	e9 14 01 00 00       	jmp    80107b71 <trap+0x1f6>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
            cpu->id, tf->cs, tf->eip);
80107a5d:	8b 45 08             	mov    0x8(%ebp),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80107a60:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
80107a63:	8b 45 08             	mov    0x8(%ebp),%eax
80107a66:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80107a6a:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
80107a6d:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107a73:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80107a76:	0f b6 c0             	movzbl %al,%eax
80107a79:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80107a7d:	89 54 24 08          	mov    %edx,0x8(%esp)
80107a81:	89 44 24 04          	mov    %eax,0x4(%esp)
80107a85:	c7 04 24 f4 9c 10 80 	movl   $0x80109cf4,(%esp)
80107a8c:	e8 10 89 ff ff       	call   801003a1 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
80107a91:	e8 8f bc ff ff       	call   80103725 <lapiceoi>
    break;
80107a96:	e9 d6 00 00 00       	jmp    80107b71 <trap+0x1f6>
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
80107a9b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107aa1:	85 c0                	test   %eax,%eax
80107aa3:	74 11                	je     80107ab6 <trap+0x13b>
80107aa5:	8b 45 08             	mov    0x8(%ebp),%eax
80107aa8:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80107aac:	0f b7 c0             	movzwl %ax,%eax
80107aaf:	83 e0 03             	and    $0x3,%eax
80107ab2:	85 c0                	test   %eax,%eax
80107ab4:	75 46                	jne    80107afc <trap+0x181>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80107ab6:	e8 1a fd ff ff       	call   801077d5 <rcr2>
              tf->trapno, cpu->id, tf->eip, rcr2());
80107abb:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80107abe:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
80107ac1:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107ac8:	0f b6 12             	movzbl (%edx),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80107acb:	0f b6 ca             	movzbl %dl,%ecx
              tf->trapno, cpu->id, tf->eip, rcr2());
80107ace:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80107ad1:	8b 52 30             	mov    0x30(%edx),%edx
80107ad4:	89 44 24 10          	mov    %eax,0x10(%esp)
80107ad8:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
80107adc:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80107ae0:	89 54 24 04          	mov    %edx,0x4(%esp)
80107ae4:	c7 04 24 18 9d 10 80 	movl   $0x80109d18,(%esp)
80107aeb:	e8 b1 88 ff ff       	call   801003a1 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
80107af0:	c7 04 24 4a 9d 10 80 	movl   $0x80109d4a,(%esp)
80107af7:	e8 41 8a ff ff       	call   8010053d <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107afc:	e8 d4 fc ff ff       	call   801077d5 <rcr2>
80107b01:	89 c2                	mov    %eax,%edx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107b03:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107b06:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107b09:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107b0f:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107b12:	0f b6 f0             	movzbl %al,%esi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107b15:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107b18:	8b 58 34             	mov    0x34(%eax),%ebx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107b1b:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107b1e:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107b21:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107b27:	83 c0 6c             	add    $0x6c,%eax
80107b2a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80107b2d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107b33:	8b 40 10             	mov    0x10(%eax),%eax
80107b36:	89 54 24 1c          	mov    %edx,0x1c(%esp)
80107b3a:	89 7c 24 18          	mov    %edi,0x18(%esp)
80107b3e:	89 74 24 14          	mov    %esi,0x14(%esp)
80107b42:	89 5c 24 10          	mov    %ebx,0x10(%esp)
80107b46:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80107b4a:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80107b4d:	89 54 24 08          	mov    %edx,0x8(%esp)
80107b51:	89 44 24 04          	mov    %eax,0x4(%esp)
80107b55:	c7 04 24 50 9d 10 80 	movl   $0x80109d50,(%esp)
80107b5c:	e8 40 88 ff ff       	call   801003a1 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
80107b61:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107b67:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
80107b6e:	eb 01                	jmp    80107b71 <trap+0x1f6>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
80107b70:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80107b71:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107b77:	85 c0                	test   %eax,%eax
80107b79:	74 24                	je     80107b9f <trap+0x224>
80107b7b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107b81:	8b 40 24             	mov    0x24(%eax),%eax
80107b84:	85 c0                	test   %eax,%eax
80107b86:	74 17                	je     80107b9f <trap+0x224>
80107b88:	8b 45 08             	mov    0x8(%ebp),%eax
80107b8b:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80107b8f:	0f b7 c0             	movzwl %ax,%eax
80107b92:	83 e0 03             	and    $0x3,%eax
80107b95:	83 f8 03             	cmp    $0x3,%eax
80107b98:	75 05                	jne    80107b9f <trap+0x224>
    exit();
80107b9a:	e8 0c d7 ff ff       	call   801052ab <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
80107b9f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107ba5:	85 c0                	test   %eax,%eax
80107ba7:	74 1e                	je     80107bc7 <trap+0x24c>
80107ba9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107baf:	8b 40 0c             	mov    0xc(%eax),%eax
80107bb2:	83 f8 04             	cmp    $0x4,%eax
80107bb5:	75 10                	jne    80107bc7 <trap+0x24c>
80107bb7:	8b 45 08             	mov    0x8(%ebp),%eax
80107bba:	8b 40 30             	mov    0x30(%eax),%eax
80107bbd:	83 f8 20             	cmp    $0x20,%eax
80107bc0:	75 05                	jne    80107bc7 <trap+0x24c>
    yield();
80107bc2:	e8 20 db ff ff       	call   801056e7 <yield>

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80107bc7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107bcd:	85 c0                	test   %eax,%eax
80107bcf:	74 27                	je     80107bf8 <trap+0x27d>
80107bd1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107bd7:	8b 40 24             	mov    0x24(%eax),%eax
80107bda:	85 c0                	test   %eax,%eax
80107bdc:	74 1a                	je     80107bf8 <trap+0x27d>
80107bde:	8b 45 08             	mov    0x8(%ebp),%eax
80107be1:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80107be5:	0f b7 c0             	movzwl %ax,%eax
80107be8:	83 e0 03             	and    $0x3,%eax
80107beb:	83 f8 03             	cmp    $0x3,%eax
80107bee:	75 08                	jne    80107bf8 <trap+0x27d>
    exit();
80107bf0:	e8 b6 d6 ff ff       	call   801052ab <exit>
80107bf5:	eb 01                	jmp    80107bf8 <trap+0x27d>
      exit();
    proc->tf = tf;
    syscall();
    if(proc->killed)
      exit();
    return;
80107bf7:	90                   	nop
    yield();

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
    exit();
}
80107bf8:	83 c4 3c             	add    $0x3c,%esp
80107bfb:	5b                   	pop    %ebx
80107bfc:	5e                   	pop    %esi
80107bfd:	5f                   	pop    %edi
80107bfe:	5d                   	pop    %ebp
80107bff:	c3                   	ret    

80107c00 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80107c00:	55                   	push   %ebp
80107c01:	89 e5                	mov    %esp,%ebp
80107c03:	53                   	push   %ebx
80107c04:	83 ec 14             	sub    $0x14,%esp
80107c07:	8b 45 08             	mov    0x8(%ebp),%eax
80107c0a:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80107c0e:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80107c12:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80107c16:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80107c1a:	ec                   	in     (%dx),%al
80107c1b:	89 c3                	mov    %eax,%ebx
80107c1d:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80107c20:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80107c24:	83 c4 14             	add    $0x14,%esp
80107c27:	5b                   	pop    %ebx
80107c28:	5d                   	pop    %ebp
80107c29:	c3                   	ret    

80107c2a <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80107c2a:	55                   	push   %ebp
80107c2b:	89 e5                	mov    %esp,%ebp
80107c2d:	83 ec 08             	sub    $0x8,%esp
80107c30:	8b 55 08             	mov    0x8(%ebp),%edx
80107c33:	8b 45 0c             	mov    0xc(%ebp),%eax
80107c36:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80107c3a:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80107c3d:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80107c41:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80107c45:	ee                   	out    %al,(%dx)
}
80107c46:	c9                   	leave  
80107c47:	c3                   	ret    

80107c48 <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
80107c48:	55                   	push   %ebp
80107c49:	89 e5                	mov    %esp,%ebp
80107c4b:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
80107c4e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107c55:	00 
80107c56:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80107c5d:	e8 c8 ff ff ff       	call   80107c2a <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
80107c62:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
80107c69:	00 
80107c6a:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80107c71:	e8 b4 ff ff ff       	call   80107c2a <outb>
  outb(COM1+0, 115200/9600);
80107c76:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
80107c7d:	00 
80107c7e:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107c85:	e8 a0 ff ff ff       	call   80107c2a <outb>
  outb(COM1+1, 0);
80107c8a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107c91:	00 
80107c92:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80107c99:	e8 8c ff ff ff       	call   80107c2a <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
80107c9e:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80107ca5:	00 
80107ca6:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80107cad:	e8 78 ff ff ff       	call   80107c2a <outb>
  outb(COM1+4, 0);
80107cb2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107cb9:	00 
80107cba:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
80107cc1:	e8 64 ff ff ff       	call   80107c2a <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
80107cc6:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80107ccd:	00 
80107cce:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80107cd5:	e8 50 ff ff ff       	call   80107c2a <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
80107cda:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80107ce1:	e8 1a ff ff ff       	call   80107c00 <inb>
80107ce6:	3c ff                	cmp    $0xff,%al
80107ce8:	74 6c                	je     80107d56 <uartinit+0x10e>
    return;
  uart = 1;
80107cea:	c7 05 d4 c6 10 80 01 	movl   $0x1,0x8010c6d4
80107cf1:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
80107cf4:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80107cfb:	e8 00 ff ff ff       	call   80107c00 <inb>
  inb(COM1+0);
80107d00:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107d07:	e8 f4 fe ff ff       	call   80107c00 <inb>
  picenable(IRQ_COM1);
80107d0c:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80107d13:	e8 e5 c5 ff ff       	call   801042fd <picenable>
  ioapicenable(IRQ_COM1, 0);
80107d18:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107d1f:	00 
80107d20:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80107d27:	e8 4e ac ff ff       	call   8010297a <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80107d2c:	c7 45 f4 14 9e 10 80 	movl   $0x80109e14,-0xc(%ebp)
80107d33:	eb 15                	jmp    80107d4a <uartinit+0x102>
    uartputc(*p);
80107d35:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d38:	0f b6 00             	movzbl (%eax),%eax
80107d3b:	0f be c0             	movsbl %al,%eax
80107d3e:	89 04 24             	mov    %eax,(%esp)
80107d41:	e8 13 00 00 00       	call   80107d59 <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80107d46:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107d4a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d4d:	0f b6 00             	movzbl (%eax),%eax
80107d50:	84 c0                	test   %al,%al
80107d52:	75 e1                	jne    80107d35 <uartinit+0xed>
80107d54:	eb 01                	jmp    80107d57 <uartinit+0x10f>
  outb(COM1+4, 0);
  outb(COM1+1, 0x01);    // Enable receive interrupts.

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
    return;
80107d56:	90                   	nop
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
    uartputc(*p);
}
80107d57:	c9                   	leave  
80107d58:	c3                   	ret    

80107d59 <uartputc>:

void
uartputc(int c)
{
80107d59:	55                   	push   %ebp
80107d5a:	89 e5                	mov    %esp,%ebp
80107d5c:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
80107d5f:	a1 d4 c6 10 80       	mov    0x8010c6d4,%eax
80107d64:	85 c0                	test   %eax,%eax
80107d66:	74 4d                	je     80107db5 <uartputc+0x5c>
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80107d68:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80107d6f:	eb 10                	jmp    80107d81 <uartputc+0x28>
    microdelay(10);
80107d71:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
80107d78:	e8 cd b9 ff ff       	call   8010374a <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80107d7d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107d81:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
80107d85:	7f 16                	jg     80107d9d <uartputc+0x44>
80107d87:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80107d8e:	e8 6d fe ff ff       	call   80107c00 <inb>
80107d93:	0f b6 c0             	movzbl %al,%eax
80107d96:	83 e0 20             	and    $0x20,%eax
80107d99:	85 c0                	test   %eax,%eax
80107d9b:	74 d4                	je     80107d71 <uartputc+0x18>
    microdelay(10);
  outb(COM1+0, c);
80107d9d:	8b 45 08             	mov    0x8(%ebp),%eax
80107da0:	0f b6 c0             	movzbl %al,%eax
80107da3:	89 44 24 04          	mov    %eax,0x4(%esp)
80107da7:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107dae:	e8 77 fe ff ff       	call   80107c2a <outb>
80107db3:	eb 01                	jmp    80107db6 <uartputc+0x5d>
uartputc(int c)
{
  int i;

  if(!uart)
    return;
80107db5:	90                   	nop
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
    microdelay(10);
  outb(COM1+0, c);
}
80107db6:	c9                   	leave  
80107db7:	c3                   	ret    

80107db8 <uartgetc>:

static int
uartgetc(void)
{
80107db8:	55                   	push   %ebp
80107db9:	89 e5                	mov    %esp,%ebp
80107dbb:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
80107dbe:	a1 d4 c6 10 80       	mov    0x8010c6d4,%eax
80107dc3:	85 c0                	test   %eax,%eax
80107dc5:	75 07                	jne    80107dce <uartgetc+0x16>
    return -1;
80107dc7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107dcc:	eb 2c                	jmp    80107dfa <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
80107dce:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80107dd5:	e8 26 fe ff ff       	call   80107c00 <inb>
80107dda:	0f b6 c0             	movzbl %al,%eax
80107ddd:	83 e0 01             	and    $0x1,%eax
80107de0:	85 c0                	test   %eax,%eax
80107de2:	75 07                	jne    80107deb <uartgetc+0x33>
    return -1;
80107de4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107de9:	eb 0f                	jmp    80107dfa <uartgetc+0x42>
  return inb(COM1+0);
80107deb:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107df2:	e8 09 fe ff ff       	call   80107c00 <inb>
80107df7:	0f b6 c0             	movzbl %al,%eax
}
80107dfa:	c9                   	leave  
80107dfb:	c3                   	ret    

80107dfc <uartintr>:

void
uartintr(void)
{
80107dfc:	55                   	push   %ebp
80107dfd:	89 e5                	mov    %esp,%ebp
80107dff:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
80107e02:	c7 04 24 b8 7d 10 80 	movl   $0x80107db8,(%esp)
80107e09:	e8 9f 89 ff ff       	call   801007ad <consoleintr>
}
80107e0e:	c9                   	leave  
80107e0f:	c3                   	ret    

80107e10 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80107e10:	6a 00                	push   $0x0
  pushl $0
80107e12:	6a 00                	push   $0x0
  jmp alltraps
80107e14:	e9 67 f9 ff ff       	jmp    80107780 <alltraps>

80107e19 <vector1>:
.globl vector1
vector1:
  pushl $0
80107e19:	6a 00                	push   $0x0
  pushl $1
80107e1b:	6a 01                	push   $0x1
  jmp alltraps
80107e1d:	e9 5e f9 ff ff       	jmp    80107780 <alltraps>

80107e22 <vector2>:
.globl vector2
vector2:
  pushl $0
80107e22:	6a 00                	push   $0x0
  pushl $2
80107e24:	6a 02                	push   $0x2
  jmp alltraps
80107e26:	e9 55 f9 ff ff       	jmp    80107780 <alltraps>

80107e2b <vector3>:
.globl vector3
vector3:
  pushl $0
80107e2b:	6a 00                	push   $0x0
  pushl $3
80107e2d:	6a 03                	push   $0x3
  jmp alltraps
80107e2f:	e9 4c f9 ff ff       	jmp    80107780 <alltraps>

80107e34 <vector4>:
.globl vector4
vector4:
  pushl $0
80107e34:	6a 00                	push   $0x0
  pushl $4
80107e36:	6a 04                	push   $0x4
  jmp alltraps
80107e38:	e9 43 f9 ff ff       	jmp    80107780 <alltraps>

80107e3d <vector5>:
.globl vector5
vector5:
  pushl $0
80107e3d:	6a 00                	push   $0x0
  pushl $5
80107e3f:	6a 05                	push   $0x5
  jmp alltraps
80107e41:	e9 3a f9 ff ff       	jmp    80107780 <alltraps>

80107e46 <vector6>:
.globl vector6
vector6:
  pushl $0
80107e46:	6a 00                	push   $0x0
  pushl $6
80107e48:	6a 06                	push   $0x6
  jmp alltraps
80107e4a:	e9 31 f9 ff ff       	jmp    80107780 <alltraps>

80107e4f <vector7>:
.globl vector7
vector7:
  pushl $0
80107e4f:	6a 00                	push   $0x0
  pushl $7
80107e51:	6a 07                	push   $0x7
  jmp alltraps
80107e53:	e9 28 f9 ff ff       	jmp    80107780 <alltraps>

80107e58 <vector8>:
.globl vector8
vector8:
  pushl $8
80107e58:	6a 08                	push   $0x8
  jmp alltraps
80107e5a:	e9 21 f9 ff ff       	jmp    80107780 <alltraps>

80107e5f <vector9>:
.globl vector9
vector9:
  pushl $0
80107e5f:	6a 00                	push   $0x0
  pushl $9
80107e61:	6a 09                	push   $0x9
  jmp alltraps
80107e63:	e9 18 f9 ff ff       	jmp    80107780 <alltraps>

80107e68 <vector10>:
.globl vector10
vector10:
  pushl $10
80107e68:	6a 0a                	push   $0xa
  jmp alltraps
80107e6a:	e9 11 f9 ff ff       	jmp    80107780 <alltraps>

80107e6f <vector11>:
.globl vector11
vector11:
  pushl $11
80107e6f:	6a 0b                	push   $0xb
  jmp alltraps
80107e71:	e9 0a f9 ff ff       	jmp    80107780 <alltraps>

80107e76 <vector12>:
.globl vector12
vector12:
  pushl $12
80107e76:	6a 0c                	push   $0xc
  jmp alltraps
80107e78:	e9 03 f9 ff ff       	jmp    80107780 <alltraps>

80107e7d <vector13>:
.globl vector13
vector13:
  pushl $13
80107e7d:	6a 0d                	push   $0xd
  jmp alltraps
80107e7f:	e9 fc f8 ff ff       	jmp    80107780 <alltraps>

80107e84 <vector14>:
.globl vector14
vector14:
  pushl $14
80107e84:	6a 0e                	push   $0xe
  jmp alltraps
80107e86:	e9 f5 f8 ff ff       	jmp    80107780 <alltraps>

80107e8b <vector15>:
.globl vector15
vector15:
  pushl $0
80107e8b:	6a 00                	push   $0x0
  pushl $15
80107e8d:	6a 0f                	push   $0xf
  jmp alltraps
80107e8f:	e9 ec f8 ff ff       	jmp    80107780 <alltraps>

80107e94 <vector16>:
.globl vector16
vector16:
  pushl $0
80107e94:	6a 00                	push   $0x0
  pushl $16
80107e96:	6a 10                	push   $0x10
  jmp alltraps
80107e98:	e9 e3 f8 ff ff       	jmp    80107780 <alltraps>

80107e9d <vector17>:
.globl vector17
vector17:
  pushl $17
80107e9d:	6a 11                	push   $0x11
  jmp alltraps
80107e9f:	e9 dc f8 ff ff       	jmp    80107780 <alltraps>

80107ea4 <vector18>:
.globl vector18
vector18:
  pushl $0
80107ea4:	6a 00                	push   $0x0
  pushl $18
80107ea6:	6a 12                	push   $0x12
  jmp alltraps
80107ea8:	e9 d3 f8 ff ff       	jmp    80107780 <alltraps>

80107ead <vector19>:
.globl vector19
vector19:
  pushl $0
80107ead:	6a 00                	push   $0x0
  pushl $19
80107eaf:	6a 13                	push   $0x13
  jmp alltraps
80107eb1:	e9 ca f8 ff ff       	jmp    80107780 <alltraps>

80107eb6 <vector20>:
.globl vector20
vector20:
  pushl $0
80107eb6:	6a 00                	push   $0x0
  pushl $20
80107eb8:	6a 14                	push   $0x14
  jmp alltraps
80107eba:	e9 c1 f8 ff ff       	jmp    80107780 <alltraps>

80107ebf <vector21>:
.globl vector21
vector21:
  pushl $0
80107ebf:	6a 00                	push   $0x0
  pushl $21
80107ec1:	6a 15                	push   $0x15
  jmp alltraps
80107ec3:	e9 b8 f8 ff ff       	jmp    80107780 <alltraps>

80107ec8 <vector22>:
.globl vector22
vector22:
  pushl $0
80107ec8:	6a 00                	push   $0x0
  pushl $22
80107eca:	6a 16                	push   $0x16
  jmp alltraps
80107ecc:	e9 af f8 ff ff       	jmp    80107780 <alltraps>

80107ed1 <vector23>:
.globl vector23
vector23:
  pushl $0
80107ed1:	6a 00                	push   $0x0
  pushl $23
80107ed3:	6a 17                	push   $0x17
  jmp alltraps
80107ed5:	e9 a6 f8 ff ff       	jmp    80107780 <alltraps>

80107eda <vector24>:
.globl vector24
vector24:
  pushl $0
80107eda:	6a 00                	push   $0x0
  pushl $24
80107edc:	6a 18                	push   $0x18
  jmp alltraps
80107ede:	e9 9d f8 ff ff       	jmp    80107780 <alltraps>

80107ee3 <vector25>:
.globl vector25
vector25:
  pushl $0
80107ee3:	6a 00                	push   $0x0
  pushl $25
80107ee5:	6a 19                	push   $0x19
  jmp alltraps
80107ee7:	e9 94 f8 ff ff       	jmp    80107780 <alltraps>

80107eec <vector26>:
.globl vector26
vector26:
  pushl $0
80107eec:	6a 00                	push   $0x0
  pushl $26
80107eee:	6a 1a                	push   $0x1a
  jmp alltraps
80107ef0:	e9 8b f8 ff ff       	jmp    80107780 <alltraps>

80107ef5 <vector27>:
.globl vector27
vector27:
  pushl $0
80107ef5:	6a 00                	push   $0x0
  pushl $27
80107ef7:	6a 1b                	push   $0x1b
  jmp alltraps
80107ef9:	e9 82 f8 ff ff       	jmp    80107780 <alltraps>

80107efe <vector28>:
.globl vector28
vector28:
  pushl $0
80107efe:	6a 00                	push   $0x0
  pushl $28
80107f00:	6a 1c                	push   $0x1c
  jmp alltraps
80107f02:	e9 79 f8 ff ff       	jmp    80107780 <alltraps>

80107f07 <vector29>:
.globl vector29
vector29:
  pushl $0
80107f07:	6a 00                	push   $0x0
  pushl $29
80107f09:	6a 1d                	push   $0x1d
  jmp alltraps
80107f0b:	e9 70 f8 ff ff       	jmp    80107780 <alltraps>

80107f10 <vector30>:
.globl vector30
vector30:
  pushl $0
80107f10:	6a 00                	push   $0x0
  pushl $30
80107f12:	6a 1e                	push   $0x1e
  jmp alltraps
80107f14:	e9 67 f8 ff ff       	jmp    80107780 <alltraps>

80107f19 <vector31>:
.globl vector31
vector31:
  pushl $0
80107f19:	6a 00                	push   $0x0
  pushl $31
80107f1b:	6a 1f                	push   $0x1f
  jmp alltraps
80107f1d:	e9 5e f8 ff ff       	jmp    80107780 <alltraps>

80107f22 <vector32>:
.globl vector32
vector32:
  pushl $0
80107f22:	6a 00                	push   $0x0
  pushl $32
80107f24:	6a 20                	push   $0x20
  jmp alltraps
80107f26:	e9 55 f8 ff ff       	jmp    80107780 <alltraps>

80107f2b <vector33>:
.globl vector33
vector33:
  pushl $0
80107f2b:	6a 00                	push   $0x0
  pushl $33
80107f2d:	6a 21                	push   $0x21
  jmp alltraps
80107f2f:	e9 4c f8 ff ff       	jmp    80107780 <alltraps>

80107f34 <vector34>:
.globl vector34
vector34:
  pushl $0
80107f34:	6a 00                	push   $0x0
  pushl $34
80107f36:	6a 22                	push   $0x22
  jmp alltraps
80107f38:	e9 43 f8 ff ff       	jmp    80107780 <alltraps>

80107f3d <vector35>:
.globl vector35
vector35:
  pushl $0
80107f3d:	6a 00                	push   $0x0
  pushl $35
80107f3f:	6a 23                	push   $0x23
  jmp alltraps
80107f41:	e9 3a f8 ff ff       	jmp    80107780 <alltraps>

80107f46 <vector36>:
.globl vector36
vector36:
  pushl $0
80107f46:	6a 00                	push   $0x0
  pushl $36
80107f48:	6a 24                	push   $0x24
  jmp alltraps
80107f4a:	e9 31 f8 ff ff       	jmp    80107780 <alltraps>

80107f4f <vector37>:
.globl vector37
vector37:
  pushl $0
80107f4f:	6a 00                	push   $0x0
  pushl $37
80107f51:	6a 25                	push   $0x25
  jmp alltraps
80107f53:	e9 28 f8 ff ff       	jmp    80107780 <alltraps>

80107f58 <vector38>:
.globl vector38
vector38:
  pushl $0
80107f58:	6a 00                	push   $0x0
  pushl $38
80107f5a:	6a 26                	push   $0x26
  jmp alltraps
80107f5c:	e9 1f f8 ff ff       	jmp    80107780 <alltraps>

80107f61 <vector39>:
.globl vector39
vector39:
  pushl $0
80107f61:	6a 00                	push   $0x0
  pushl $39
80107f63:	6a 27                	push   $0x27
  jmp alltraps
80107f65:	e9 16 f8 ff ff       	jmp    80107780 <alltraps>

80107f6a <vector40>:
.globl vector40
vector40:
  pushl $0
80107f6a:	6a 00                	push   $0x0
  pushl $40
80107f6c:	6a 28                	push   $0x28
  jmp alltraps
80107f6e:	e9 0d f8 ff ff       	jmp    80107780 <alltraps>

80107f73 <vector41>:
.globl vector41
vector41:
  pushl $0
80107f73:	6a 00                	push   $0x0
  pushl $41
80107f75:	6a 29                	push   $0x29
  jmp alltraps
80107f77:	e9 04 f8 ff ff       	jmp    80107780 <alltraps>

80107f7c <vector42>:
.globl vector42
vector42:
  pushl $0
80107f7c:	6a 00                	push   $0x0
  pushl $42
80107f7e:	6a 2a                	push   $0x2a
  jmp alltraps
80107f80:	e9 fb f7 ff ff       	jmp    80107780 <alltraps>

80107f85 <vector43>:
.globl vector43
vector43:
  pushl $0
80107f85:	6a 00                	push   $0x0
  pushl $43
80107f87:	6a 2b                	push   $0x2b
  jmp alltraps
80107f89:	e9 f2 f7 ff ff       	jmp    80107780 <alltraps>

80107f8e <vector44>:
.globl vector44
vector44:
  pushl $0
80107f8e:	6a 00                	push   $0x0
  pushl $44
80107f90:	6a 2c                	push   $0x2c
  jmp alltraps
80107f92:	e9 e9 f7 ff ff       	jmp    80107780 <alltraps>

80107f97 <vector45>:
.globl vector45
vector45:
  pushl $0
80107f97:	6a 00                	push   $0x0
  pushl $45
80107f99:	6a 2d                	push   $0x2d
  jmp alltraps
80107f9b:	e9 e0 f7 ff ff       	jmp    80107780 <alltraps>

80107fa0 <vector46>:
.globl vector46
vector46:
  pushl $0
80107fa0:	6a 00                	push   $0x0
  pushl $46
80107fa2:	6a 2e                	push   $0x2e
  jmp alltraps
80107fa4:	e9 d7 f7 ff ff       	jmp    80107780 <alltraps>

80107fa9 <vector47>:
.globl vector47
vector47:
  pushl $0
80107fa9:	6a 00                	push   $0x0
  pushl $47
80107fab:	6a 2f                	push   $0x2f
  jmp alltraps
80107fad:	e9 ce f7 ff ff       	jmp    80107780 <alltraps>

80107fb2 <vector48>:
.globl vector48
vector48:
  pushl $0
80107fb2:	6a 00                	push   $0x0
  pushl $48
80107fb4:	6a 30                	push   $0x30
  jmp alltraps
80107fb6:	e9 c5 f7 ff ff       	jmp    80107780 <alltraps>

80107fbb <vector49>:
.globl vector49
vector49:
  pushl $0
80107fbb:	6a 00                	push   $0x0
  pushl $49
80107fbd:	6a 31                	push   $0x31
  jmp alltraps
80107fbf:	e9 bc f7 ff ff       	jmp    80107780 <alltraps>

80107fc4 <vector50>:
.globl vector50
vector50:
  pushl $0
80107fc4:	6a 00                	push   $0x0
  pushl $50
80107fc6:	6a 32                	push   $0x32
  jmp alltraps
80107fc8:	e9 b3 f7 ff ff       	jmp    80107780 <alltraps>

80107fcd <vector51>:
.globl vector51
vector51:
  pushl $0
80107fcd:	6a 00                	push   $0x0
  pushl $51
80107fcf:	6a 33                	push   $0x33
  jmp alltraps
80107fd1:	e9 aa f7 ff ff       	jmp    80107780 <alltraps>

80107fd6 <vector52>:
.globl vector52
vector52:
  pushl $0
80107fd6:	6a 00                	push   $0x0
  pushl $52
80107fd8:	6a 34                	push   $0x34
  jmp alltraps
80107fda:	e9 a1 f7 ff ff       	jmp    80107780 <alltraps>

80107fdf <vector53>:
.globl vector53
vector53:
  pushl $0
80107fdf:	6a 00                	push   $0x0
  pushl $53
80107fe1:	6a 35                	push   $0x35
  jmp alltraps
80107fe3:	e9 98 f7 ff ff       	jmp    80107780 <alltraps>

80107fe8 <vector54>:
.globl vector54
vector54:
  pushl $0
80107fe8:	6a 00                	push   $0x0
  pushl $54
80107fea:	6a 36                	push   $0x36
  jmp alltraps
80107fec:	e9 8f f7 ff ff       	jmp    80107780 <alltraps>

80107ff1 <vector55>:
.globl vector55
vector55:
  pushl $0
80107ff1:	6a 00                	push   $0x0
  pushl $55
80107ff3:	6a 37                	push   $0x37
  jmp alltraps
80107ff5:	e9 86 f7 ff ff       	jmp    80107780 <alltraps>

80107ffa <vector56>:
.globl vector56
vector56:
  pushl $0
80107ffa:	6a 00                	push   $0x0
  pushl $56
80107ffc:	6a 38                	push   $0x38
  jmp alltraps
80107ffe:	e9 7d f7 ff ff       	jmp    80107780 <alltraps>

80108003 <vector57>:
.globl vector57
vector57:
  pushl $0
80108003:	6a 00                	push   $0x0
  pushl $57
80108005:	6a 39                	push   $0x39
  jmp alltraps
80108007:	e9 74 f7 ff ff       	jmp    80107780 <alltraps>

8010800c <vector58>:
.globl vector58
vector58:
  pushl $0
8010800c:	6a 00                	push   $0x0
  pushl $58
8010800e:	6a 3a                	push   $0x3a
  jmp alltraps
80108010:	e9 6b f7 ff ff       	jmp    80107780 <alltraps>

80108015 <vector59>:
.globl vector59
vector59:
  pushl $0
80108015:	6a 00                	push   $0x0
  pushl $59
80108017:	6a 3b                	push   $0x3b
  jmp alltraps
80108019:	e9 62 f7 ff ff       	jmp    80107780 <alltraps>

8010801e <vector60>:
.globl vector60
vector60:
  pushl $0
8010801e:	6a 00                	push   $0x0
  pushl $60
80108020:	6a 3c                	push   $0x3c
  jmp alltraps
80108022:	e9 59 f7 ff ff       	jmp    80107780 <alltraps>

80108027 <vector61>:
.globl vector61
vector61:
  pushl $0
80108027:	6a 00                	push   $0x0
  pushl $61
80108029:	6a 3d                	push   $0x3d
  jmp alltraps
8010802b:	e9 50 f7 ff ff       	jmp    80107780 <alltraps>

80108030 <vector62>:
.globl vector62
vector62:
  pushl $0
80108030:	6a 00                	push   $0x0
  pushl $62
80108032:	6a 3e                	push   $0x3e
  jmp alltraps
80108034:	e9 47 f7 ff ff       	jmp    80107780 <alltraps>

80108039 <vector63>:
.globl vector63
vector63:
  pushl $0
80108039:	6a 00                	push   $0x0
  pushl $63
8010803b:	6a 3f                	push   $0x3f
  jmp alltraps
8010803d:	e9 3e f7 ff ff       	jmp    80107780 <alltraps>

80108042 <vector64>:
.globl vector64
vector64:
  pushl $0
80108042:	6a 00                	push   $0x0
  pushl $64
80108044:	6a 40                	push   $0x40
  jmp alltraps
80108046:	e9 35 f7 ff ff       	jmp    80107780 <alltraps>

8010804b <vector65>:
.globl vector65
vector65:
  pushl $0
8010804b:	6a 00                	push   $0x0
  pushl $65
8010804d:	6a 41                	push   $0x41
  jmp alltraps
8010804f:	e9 2c f7 ff ff       	jmp    80107780 <alltraps>

80108054 <vector66>:
.globl vector66
vector66:
  pushl $0
80108054:	6a 00                	push   $0x0
  pushl $66
80108056:	6a 42                	push   $0x42
  jmp alltraps
80108058:	e9 23 f7 ff ff       	jmp    80107780 <alltraps>

8010805d <vector67>:
.globl vector67
vector67:
  pushl $0
8010805d:	6a 00                	push   $0x0
  pushl $67
8010805f:	6a 43                	push   $0x43
  jmp alltraps
80108061:	e9 1a f7 ff ff       	jmp    80107780 <alltraps>

80108066 <vector68>:
.globl vector68
vector68:
  pushl $0
80108066:	6a 00                	push   $0x0
  pushl $68
80108068:	6a 44                	push   $0x44
  jmp alltraps
8010806a:	e9 11 f7 ff ff       	jmp    80107780 <alltraps>

8010806f <vector69>:
.globl vector69
vector69:
  pushl $0
8010806f:	6a 00                	push   $0x0
  pushl $69
80108071:	6a 45                	push   $0x45
  jmp alltraps
80108073:	e9 08 f7 ff ff       	jmp    80107780 <alltraps>

80108078 <vector70>:
.globl vector70
vector70:
  pushl $0
80108078:	6a 00                	push   $0x0
  pushl $70
8010807a:	6a 46                	push   $0x46
  jmp alltraps
8010807c:	e9 ff f6 ff ff       	jmp    80107780 <alltraps>

80108081 <vector71>:
.globl vector71
vector71:
  pushl $0
80108081:	6a 00                	push   $0x0
  pushl $71
80108083:	6a 47                	push   $0x47
  jmp alltraps
80108085:	e9 f6 f6 ff ff       	jmp    80107780 <alltraps>

8010808a <vector72>:
.globl vector72
vector72:
  pushl $0
8010808a:	6a 00                	push   $0x0
  pushl $72
8010808c:	6a 48                	push   $0x48
  jmp alltraps
8010808e:	e9 ed f6 ff ff       	jmp    80107780 <alltraps>

80108093 <vector73>:
.globl vector73
vector73:
  pushl $0
80108093:	6a 00                	push   $0x0
  pushl $73
80108095:	6a 49                	push   $0x49
  jmp alltraps
80108097:	e9 e4 f6 ff ff       	jmp    80107780 <alltraps>

8010809c <vector74>:
.globl vector74
vector74:
  pushl $0
8010809c:	6a 00                	push   $0x0
  pushl $74
8010809e:	6a 4a                	push   $0x4a
  jmp alltraps
801080a0:	e9 db f6 ff ff       	jmp    80107780 <alltraps>

801080a5 <vector75>:
.globl vector75
vector75:
  pushl $0
801080a5:	6a 00                	push   $0x0
  pushl $75
801080a7:	6a 4b                	push   $0x4b
  jmp alltraps
801080a9:	e9 d2 f6 ff ff       	jmp    80107780 <alltraps>

801080ae <vector76>:
.globl vector76
vector76:
  pushl $0
801080ae:	6a 00                	push   $0x0
  pushl $76
801080b0:	6a 4c                	push   $0x4c
  jmp alltraps
801080b2:	e9 c9 f6 ff ff       	jmp    80107780 <alltraps>

801080b7 <vector77>:
.globl vector77
vector77:
  pushl $0
801080b7:	6a 00                	push   $0x0
  pushl $77
801080b9:	6a 4d                	push   $0x4d
  jmp alltraps
801080bb:	e9 c0 f6 ff ff       	jmp    80107780 <alltraps>

801080c0 <vector78>:
.globl vector78
vector78:
  pushl $0
801080c0:	6a 00                	push   $0x0
  pushl $78
801080c2:	6a 4e                	push   $0x4e
  jmp alltraps
801080c4:	e9 b7 f6 ff ff       	jmp    80107780 <alltraps>

801080c9 <vector79>:
.globl vector79
vector79:
  pushl $0
801080c9:	6a 00                	push   $0x0
  pushl $79
801080cb:	6a 4f                	push   $0x4f
  jmp alltraps
801080cd:	e9 ae f6 ff ff       	jmp    80107780 <alltraps>

801080d2 <vector80>:
.globl vector80
vector80:
  pushl $0
801080d2:	6a 00                	push   $0x0
  pushl $80
801080d4:	6a 50                	push   $0x50
  jmp alltraps
801080d6:	e9 a5 f6 ff ff       	jmp    80107780 <alltraps>

801080db <vector81>:
.globl vector81
vector81:
  pushl $0
801080db:	6a 00                	push   $0x0
  pushl $81
801080dd:	6a 51                	push   $0x51
  jmp alltraps
801080df:	e9 9c f6 ff ff       	jmp    80107780 <alltraps>

801080e4 <vector82>:
.globl vector82
vector82:
  pushl $0
801080e4:	6a 00                	push   $0x0
  pushl $82
801080e6:	6a 52                	push   $0x52
  jmp alltraps
801080e8:	e9 93 f6 ff ff       	jmp    80107780 <alltraps>

801080ed <vector83>:
.globl vector83
vector83:
  pushl $0
801080ed:	6a 00                	push   $0x0
  pushl $83
801080ef:	6a 53                	push   $0x53
  jmp alltraps
801080f1:	e9 8a f6 ff ff       	jmp    80107780 <alltraps>

801080f6 <vector84>:
.globl vector84
vector84:
  pushl $0
801080f6:	6a 00                	push   $0x0
  pushl $84
801080f8:	6a 54                	push   $0x54
  jmp alltraps
801080fa:	e9 81 f6 ff ff       	jmp    80107780 <alltraps>

801080ff <vector85>:
.globl vector85
vector85:
  pushl $0
801080ff:	6a 00                	push   $0x0
  pushl $85
80108101:	6a 55                	push   $0x55
  jmp alltraps
80108103:	e9 78 f6 ff ff       	jmp    80107780 <alltraps>

80108108 <vector86>:
.globl vector86
vector86:
  pushl $0
80108108:	6a 00                	push   $0x0
  pushl $86
8010810a:	6a 56                	push   $0x56
  jmp alltraps
8010810c:	e9 6f f6 ff ff       	jmp    80107780 <alltraps>

80108111 <vector87>:
.globl vector87
vector87:
  pushl $0
80108111:	6a 00                	push   $0x0
  pushl $87
80108113:	6a 57                	push   $0x57
  jmp alltraps
80108115:	e9 66 f6 ff ff       	jmp    80107780 <alltraps>

8010811a <vector88>:
.globl vector88
vector88:
  pushl $0
8010811a:	6a 00                	push   $0x0
  pushl $88
8010811c:	6a 58                	push   $0x58
  jmp alltraps
8010811e:	e9 5d f6 ff ff       	jmp    80107780 <alltraps>

80108123 <vector89>:
.globl vector89
vector89:
  pushl $0
80108123:	6a 00                	push   $0x0
  pushl $89
80108125:	6a 59                	push   $0x59
  jmp alltraps
80108127:	e9 54 f6 ff ff       	jmp    80107780 <alltraps>

8010812c <vector90>:
.globl vector90
vector90:
  pushl $0
8010812c:	6a 00                	push   $0x0
  pushl $90
8010812e:	6a 5a                	push   $0x5a
  jmp alltraps
80108130:	e9 4b f6 ff ff       	jmp    80107780 <alltraps>

80108135 <vector91>:
.globl vector91
vector91:
  pushl $0
80108135:	6a 00                	push   $0x0
  pushl $91
80108137:	6a 5b                	push   $0x5b
  jmp alltraps
80108139:	e9 42 f6 ff ff       	jmp    80107780 <alltraps>

8010813e <vector92>:
.globl vector92
vector92:
  pushl $0
8010813e:	6a 00                	push   $0x0
  pushl $92
80108140:	6a 5c                	push   $0x5c
  jmp alltraps
80108142:	e9 39 f6 ff ff       	jmp    80107780 <alltraps>

80108147 <vector93>:
.globl vector93
vector93:
  pushl $0
80108147:	6a 00                	push   $0x0
  pushl $93
80108149:	6a 5d                	push   $0x5d
  jmp alltraps
8010814b:	e9 30 f6 ff ff       	jmp    80107780 <alltraps>

80108150 <vector94>:
.globl vector94
vector94:
  pushl $0
80108150:	6a 00                	push   $0x0
  pushl $94
80108152:	6a 5e                	push   $0x5e
  jmp alltraps
80108154:	e9 27 f6 ff ff       	jmp    80107780 <alltraps>

80108159 <vector95>:
.globl vector95
vector95:
  pushl $0
80108159:	6a 00                	push   $0x0
  pushl $95
8010815b:	6a 5f                	push   $0x5f
  jmp alltraps
8010815d:	e9 1e f6 ff ff       	jmp    80107780 <alltraps>

80108162 <vector96>:
.globl vector96
vector96:
  pushl $0
80108162:	6a 00                	push   $0x0
  pushl $96
80108164:	6a 60                	push   $0x60
  jmp alltraps
80108166:	e9 15 f6 ff ff       	jmp    80107780 <alltraps>

8010816b <vector97>:
.globl vector97
vector97:
  pushl $0
8010816b:	6a 00                	push   $0x0
  pushl $97
8010816d:	6a 61                	push   $0x61
  jmp alltraps
8010816f:	e9 0c f6 ff ff       	jmp    80107780 <alltraps>

80108174 <vector98>:
.globl vector98
vector98:
  pushl $0
80108174:	6a 00                	push   $0x0
  pushl $98
80108176:	6a 62                	push   $0x62
  jmp alltraps
80108178:	e9 03 f6 ff ff       	jmp    80107780 <alltraps>

8010817d <vector99>:
.globl vector99
vector99:
  pushl $0
8010817d:	6a 00                	push   $0x0
  pushl $99
8010817f:	6a 63                	push   $0x63
  jmp alltraps
80108181:	e9 fa f5 ff ff       	jmp    80107780 <alltraps>

80108186 <vector100>:
.globl vector100
vector100:
  pushl $0
80108186:	6a 00                	push   $0x0
  pushl $100
80108188:	6a 64                	push   $0x64
  jmp alltraps
8010818a:	e9 f1 f5 ff ff       	jmp    80107780 <alltraps>

8010818f <vector101>:
.globl vector101
vector101:
  pushl $0
8010818f:	6a 00                	push   $0x0
  pushl $101
80108191:	6a 65                	push   $0x65
  jmp alltraps
80108193:	e9 e8 f5 ff ff       	jmp    80107780 <alltraps>

80108198 <vector102>:
.globl vector102
vector102:
  pushl $0
80108198:	6a 00                	push   $0x0
  pushl $102
8010819a:	6a 66                	push   $0x66
  jmp alltraps
8010819c:	e9 df f5 ff ff       	jmp    80107780 <alltraps>

801081a1 <vector103>:
.globl vector103
vector103:
  pushl $0
801081a1:	6a 00                	push   $0x0
  pushl $103
801081a3:	6a 67                	push   $0x67
  jmp alltraps
801081a5:	e9 d6 f5 ff ff       	jmp    80107780 <alltraps>

801081aa <vector104>:
.globl vector104
vector104:
  pushl $0
801081aa:	6a 00                	push   $0x0
  pushl $104
801081ac:	6a 68                	push   $0x68
  jmp alltraps
801081ae:	e9 cd f5 ff ff       	jmp    80107780 <alltraps>

801081b3 <vector105>:
.globl vector105
vector105:
  pushl $0
801081b3:	6a 00                	push   $0x0
  pushl $105
801081b5:	6a 69                	push   $0x69
  jmp alltraps
801081b7:	e9 c4 f5 ff ff       	jmp    80107780 <alltraps>

801081bc <vector106>:
.globl vector106
vector106:
  pushl $0
801081bc:	6a 00                	push   $0x0
  pushl $106
801081be:	6a 6a                	push   $0x6a
  jmp alltraps
801081c0:	e9 bb f5 ff ff       	jmp    80107780 <alltraps>

801081c5 <vector107>:
.globl vector107
vector107:
  pushl $0
801081c5:	6a 00                	push   $0x0
  pushl $107
801081c7:	6a 6b                	push   $0x6b
  jmp alltraps
801081c9:	e9 b2 f5 ff ff       	jmp    80107780 <alltraps>

801081ce <vector108>:
.globl vector108
vector108:
  pushl $0
801081ce:	6a 00                	push   $0x0
  pushl $108
801081d0:	6a 6c                	push   $0x6c
  jmp alltraps
801081d2:	e9 a9 f5 ff ff       	jmp    80107780 <alltraps>

801081d7 <vector109>:
.globl vector109
vector109:
  pushl $0
801081d7:	6a 00                	push   $0x0
  pushl $109
801081d9:	6a 6d                	push   $0x6d
  jmp alltraps
801081db:	e9 a0 f5 ff ff       	jmp    80107780 <alltraps>

801081e0 <vector110>:
.globl vector110
vector110:
  pushl $0
801081e0:	6a 00                	push   $0x0
  pushl $110
801081e2:	6a 6e                	push   $0x6e
  jmp alltraps
801081e4:	e9 97 f5 ff ff       	jmp    80107780 <alltraps>

801081e9 <vector111>:
.globl vector111
vector111:
  pushl $0
801081e9:	6a 00                	push   $0x0
  pushl $111
801081eb:	6a 6f                	push   $0x6f
  jmp alltraps
801081ed:	e9 8e f5 ff ff       	jmp    80107780 <alltraps>

801081f2 <vector112>:
.globl vector112
vector112:
  pushl $0
801081f2:	6a 00                	push   $0x0
  pushl $112
801081f4:	6a 70                	push   $0x70
  jmp alltraps
801081f6:	e9 85 f5 ff ff       	jmp    80107780 <alltraps>

801081fb <vector113>:
.globl vector113
vector113:
  pushl $0
801081fb:	6a 00                	push   $0x0
  pushl $113
801081fd:	6a 71                	push   $0x71
  jmp alltraps
801081ff:	e9 7c f5 ff ff       	jmp    80107780 <alltraps>

80108204 <vector114>:
.globl vector114
vector114:
  pushl $0
80108204:	6a 00                	push   $0x0
  pushl $114
80108206:	6a 72                	push   $0x72
  jmp alltraps
80108208:	e9 73 f5 ff ff       	jmp    80107780 <alltraps>

8010820d <vector115>:
.globl vector115
vector115:
  pushl $0
8010820d:	6a 00                	push   $0x0
  pushl $115
8010820f:	6a 73                	push   $0x73
  jmp alltraps
80108211:	e9 6a f5 ff ff       	jmp    80107780 <alltraps>

80108216 <vector116>:
.globl vector116
vector116:
  pushl $0
80108216:	6a 00                	push   $0x0
  pushl $116
80108218:	6a 74                	push   $0x74
  jmp alltraps
8010821a:	e9 61 f5 ff ff       	jmp    80107780 <alltraps>

8010821f <vector117>:
.globl vector117
vector117:
  pushl $0
8010821f:	6a 00                	push   $0x0
  pushl $117
80108221:	6a 75                	push   $0x75
  jmp alltraps
80108223:	e9 58 f5 ff ff       	jmp    80107780 <alltraps>

80108228 <vector118>:
.globl vector118
vector118:
  pushl $0
80108228:	6a 00                	push   $0x0
  pushl $118
8010822a:	6a 76                	push   $0x76
  jmp alltraps
8010822c:	e9 4f f5 ff ff       	jmp    80107780 <alltraps>

80108231 <vector119>:
.globl vector119
vector119:
  pushl $0
80108231:	6a 00                	push   $0x0
  pushl $119
80108233:	6a 77                	push   $0x77
  jmp alltraps
80108235:	e9 46 f5 ff ff       	jmp    80107780 <alltraps>

8010823a <vector120>:
.globl vector120
vector120:
  pushl $0
8010823a:	6a 00                	push   $0x0
  pushl $120
8010823c:	6a 78                	push   $0x78
  jmp alltraps
8010823e:	e9 3d f5 ff ff       	jmp    80107780 <alltraps>

80108243 <vector121>:
.globl vector121
vector121:
  pushl $0
80108243:	6a 00                	push   $0x0
  pushl $121
80108245:	6a 79                	push   $0x79
  jmp alltraps
80108247:	e9 34 f5 ff ff       	jmp    80107780 <alltraps>

8010824c <vector122>:
.globl vector122
vector122:
  pushl $0
8010824c:	6a 00                	push   $0x0
  pushl $122
8010824e:	6a 7a                	push   $0x7a
  jmp alltraps
80108250:	e9 2b f5 ff ff       	jmp    80107780 <alltraps>

80108255 <vector123>:
.globl vector123
vector123:
  pushl $0
80108255:	6a 00                	push   $0x0
  pushl $123
80108257:	6a 7b                	push   $0x7b
  jmp alltraps
80108259:	e9 22 f5 ff ff       	jmp    80107780 <alltraps>

8010825e <vector124>:
.globl vector124
vector124:
  pushl $0
8010825e:	6a 00                	push   $0x0
  pushl $124
80108260:	6a 7c                	push   $0x7c
  jmp alltraps
80108262:	e9 19 f5 ff ff       	jmp    80107780 <alltraps>

80108267 <vector125>:
.globl vector125
vector125:
  pushl $0
80108267:	6a 00                	push   $0x0
  pushl $125
80108269:	6a 7d                	push   $0x7d
  jmp alltraps
8010826b:	e9 10 f5 ff ff       	jmp    80107780 <alltraps>

80108270 <vector126>:
.globl vector126
vector126:
  pushl $0
80108270:	6a 00                	push   $0x0
  pushl $126
80108272:	6a 7e                	push   $0x7e
  jmp alltraps
80108274:	e9 07 f5 ff ff       	jmp    80107780 <alltraps>

80108279 <vector127>:
.globl vector127
vector127:
  pushl $0
80108279:	6a 00                	push   $0x0
  pushl $127
8010827b:	6a 7f                	push   $0x7f
  jmp alltraps
8010827d:	e9 fe f4 ff ff       	jmp    80107780 <alltraps>

80108282 <vector128>:
.globl vector128
vector128:
  pushl $0
80108282:	6a 00                	push   $0x0
  pushl $128
80108284:	68 80 00 00 00       	push   $0x80
  jmp alltraps
80108289:	e9 f2 f4 ff ff       	jmp    80107780 <alltraps>

8010828e <vector129>:
.globl vector129
vector129:
  pushl $0
8010828e:	6a 00                	push   $0x0
  pushl $129
80108290:	68 81 00 00 00       	push   $0x81
  jmp alltraps
80108295:	e9 e6 f4 ff ff       	jmp    80107780 <alltraps>

8010829a <vector130>:
.globl vector130
vector130:
  pushl $0
8010829a:	6a 00                	push   $0x0
  pushl $130
8010829c:	68 82 00 00 00       	push   $0x82
  jmp alltraps
801082a1:	e9 da f4 ff ff       	jmp    80107780 <alltraps>

801082a6 <vector131>:
.globl vector131
vector131:
  pushl $0
801082a6:	6a 00                	push   $0x0
  pushl $131
801082a8:	68 83 00 00 00       	push   $0x83
  jmp alltraps
801082ad:	e9 ce f4 ff ff       	jmp    80107780 <alltraps>

801082b2 <vector132>:
.globl vector132
vector132:
  pushl $0
801082b2:	6a 00                	push   $0x0
  pushl $132
801082b4:	68 84 00 00 00       	push   $0x84
  jmp alltraps
801082b9:	e9 c2 f4 ff ff       	jmp    80107780 <alltraps>

801082be <vector133>:
.globl vector133
vector133:
  pushl $0
801082be:	6a 00                	push   $0x0
  pushl $133
801082c0:	68 85 00 00 00       	push   $0x85
  jmp alltraps
801082c5:	e9 b6 f4 ff ff       	jmp    80107780 <alltraps>

801082ca <vector134>:
.globl vector134
vector134:
  pushl $0
801082ca:	6a 00                	push   $0x0
  pushl $134
801082cc:	68 86 00 00 00       	push   $0x86
  jmp alltraps
801082d1:	e9 aa f4 ff ff       	jmp    80107780 <alltraps>

801082d6 <vector135>:
.globl vector135
vector135:
  pushl $0
801082d6:	6a 00                	push   $0x0
  pushl $135
801082d8:	68 87 00 00 00       	push   $0x87
  jmp alltraps
801082dd:	e9 9e f4 ff ff       	jmp    80107780 <alltraps>

801082e2 <vector136>:
.globl vector136
vector136:
  pushl $0
801082e2:	6a 00                	push   $0x0
  pushl $136
801082e4:	68 88 00 00 00       	push   $0x88
  jmp alltraps
801082e9:	e9 92 f4 ff ff       	jmp    80107780 <alltraps>

801082ee <vector137>:
.globl vector137
vector137:
  pushl $0
801082ee:	6a 00                	push   $0x0
  pushl $137
801082f0:	68 89 00 00 00       	push   $0x89
  jmp alltraps
801082f5:	e9 86 f4 ff ff       	jmp    80107780 <alltraps>

801082fa <vector138>:
.globl vector138
vector138:
  pushl $0
801082fa:	6a 00                	push   $0x0
  pushl $138
801082fc:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80108301:	e9 7a f4 ff ff       	jmp    80107780 <alltraps>

80108306 <vector139>:
.globl vector139
vector139:
  pushl $0
80108306:	6a 00                	push   $0x0
  pushl $139
80108308:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
8010830d:	e9 6e f4 ff ff       	jmp    80107780 <alltraps>

80108312 <vector140>:
.globl vector140
vector140:
  pushl $0
80108312:	6a 00                	push   $0x0
  pushl $140
80108314:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
80108319:	e9 62 f4 ff ff       	jmp    80107780 <alltraps>

8010831e <vector141>:
.globl vector141
vector141:
  pushl $0
8010831e:	6a 00                	push   $0x0
  pushl $141
80108320:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80108325:	e9 56 f4 ff ff       	jmp    80107780 <alltraps>

8010832a <vector142>:
.globl vector142
vector142:
  pushl $0
8010832a:	6a 00                	push   $0x0
  pushl $142
8010832c:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80108331:	e9 4a f4 ff ff       	jmp    80107780 <alltraps>

80108336 <vector143>:
.globl vector143
vector143:
  pushl $0
80108336:	6a 00                	push   $0x0
  pushl $143
80108338:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
8010833d:	e9 3e f4 ff ff       	jmp    80107780 <alltraps>

80108342 <vector144>:
.globl vector144
vector144:
  pushl $0
80108342:	6a 00                	push   $0x0
  pushl $144
80108344:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80108349:	e9 32 f4 ff ff       	jmp    80107780 <alltraps>

8010834e <vector145>:
.globl vector145
vector145:
  pushl $0
8010834e:	6a 00                	push   $0x0
  pushl $145
80108350:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80108355:	e9 26 f4 ff ff       	jmp    80107780 <alltraps>

8010835a <vector146>:
.globl vector146
vector146:
  pushl $0
8010835a:	6a 00                	push   $0x0
  pushl $146
8010835c:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80108361:	e9 1a f4 ff ff       	jmp    80107780 <alltraps>

80108366 <vector147>:
.globl vector147
vector147:
  pushl $0
80108366:	6a 00                	push   $0x0
  pushl $147
80108368:	68 93 00 00 00       	push   $0x93
  jmp alltraps
8010836d:	e9 0e f4 ff ff       	jmp    80107780 <alltraps>

80108372 <vector148>:
.globl vector148
vector148:
  pushl $0
80108372:	6a 00                	push   $0x0
  pushl $148
80108374:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80108379:	e9 02 f4 ff ff       	jmp    80107780 <alltraps>

8010837e <vector149>:
.globl vector149
vector149:
  pushl $0
8010837e:	6a 00                	push   $0x0
  pushl $149
80108380:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80108385:	e9 f6 f3 ff ff       	jmp    80107780 <alltraps>

8010838a <vector150>:
.globl vector150
vector150:
  pushl $0
8010838a:	6a 00                	push   $0x0
  pushl $150
8010838c:	68 96 00 00 00       	push   $0x96
  jmp alltraps
80108391:	e9 ea f3 ff ff       	jmp    80107780 <alltraps>

80108396 <vector151>:
.globl vector151
vector151:
  pushl $0
80108396:	6a 00                	push   $0x0
  pushl $151
80108398:	68 97 00 00 00       	push   $0x97
  jmp alltraps
8010839d:	e9 de f3 ff ff       	jmp    80107780 <alltraps>

801083a2 <vector152>:
.globl vector152
vector152:
  pushl $0
801083a2:	6a 00                	push   $0x0
  pushl $152
801083a4:	68 98 00 00 00       	push   $0x98
  jmp alltraps
801083a9:	e9 d2 f3 ff ff       	jmp    80107780 <alltraps>

801083ae <vector153>:
.globl vector153
vector153:
  pushl $0
801083ae:	6a 00                	push   $0x0
  pushl $153
801083b0:	68 99 00 00 00       	push   $0x99
  jmp alltraps
801083b5:	e9 c6 f3 ff ff       	jmp    80107780 <alltraps>

801083ba <vector154>:
.globl vector154
vector154:
  pushl $0
801083ba:	6a 00                	push   $0x0
  pushl $154
801083bc:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
801083c1:	e9 ba f3 ff ff       	jmp    80107780 <alltraps>

801083c6 <vector155>:
.globl vector155
vector155:
  pushl $0
801083c6:	6a 00                	push   $0x0
  pushl $155
801083c8:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
801083cd:	e9 ae f3 ff ff       	jmp    80107780 <alltraps>

801083d2 <vector156>:
.globl vector156
vector156:
  pushl $0
801083d2:	6a 00                	push   $0x0
  pushl $156
801083d4:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
801083d9:	e9 a2 f3 ff ff       	jmp    80107780 <alltraps>

801083de <vector157>:
.globl vector157
vector157:
  pushl $0
801083de:	6a 00                	push   $0x0
  pushl $157
801083e0:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
801083e5:	e9 96 f3 ff ff       	jmp    80107780 <alltraps>

801083ea <vector158>:
.globl vector158
vector158:
  pushl $0
801083ea:	6a 00                	push   $0x0
  pushl $158
801083ec:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
801083f1:	e9 8a f3 ff ff       	jmp    80107780 <alltraps>

801083f6 <vector159>:
.globl vector159
vector159:
  pushl $0
801083f6:	6a 00                	push   $0x0
  pushl $159
801083f8:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
801083fd:	e9 7e f3 ff ff       	jmp    80107780 <alltraps>

80108402 <vector160>:
.globl vector160
vector160:
  pushl $0
80108402:	6a 00                	push   $0x0
  pushl $160
80108404:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80108409:	e9 72 f3 ff ff       	jmp    80107780 <alltraps>

8010840e <vector161>:
.globl vector161
vector161:
  pushl $0
8010840e:	6a 00                	push   $0x0
  pushl $161
80108410:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80108415:	e9 66 f3 ff ff       	jmp    80107780 <alltraps>

8010841a <vector162>:
.globl vector162
vector162:
  pushl $0
8010841a:	6a 00                	push   $0x0
  pushl $162
8010841c:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80108421:	e9 5a f3 ff ff       	jmp    80107780 <alltraps>

80108426 <vector163>:
.globl vector163
vector163:
  pushl $0
80108426:	6a 00                	push   $0x0
  pushl $163
80108428:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
8010842d:	e9 4e f3 ff ff       	jmp    80107780 <alltraps>

80108432 <vector164>:
.globl vector164
vector164:
  pushl $0
80108432:	6a 00                	push   $0x0
  pushl $164
80108434:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80108439:	e9 42 f3 ff ff       	jmp    80107780 <alltraps>

8010843e <vector165>:
.globl vector165
vector165:
  pushl $0
8010843e:	6a 00                	push   $0x0
  pushl $165
80108440:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80108445:	e9 36 f3 ff ff       	jmp    80107780 <alltraps>

8010844a <vector166>:
.globl vector166
vector166:
  pushl $0
8010844a:	6a 00                	push   $0x0
  pushl $166
8010844c:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80108451:	e9 2a f3 ff ff       	jmp    80107780 <alltraps>

80108456 <vector167>:
.globl vector167
vector167:
  pushl $0
80108456:	6a 00                	push   $0x0
  pushl $167
80108458:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
8010845d:	e9 1e f3 ff ff       	jmp    80107780 <alltraps>

80108462 <vector168>:
.globl vector168
vector168:
  pushl $0
80108462:	6a 00                	push   $0x0
  pushl $168
80108464:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80108469:	e9 12 f3 ff ff       	jmp    80107780 <alltraps>

8010846e <vector169>:
.globl vector169
vector169:
  pushl $0
8010846e:	6a 00                	push   $0x0
  pushl $169
80108470:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80108475:	e9 06 f3 ff ff       	jmp    80107780 <alltraps>

8010847a <vector170>:
.globl vector170
vector170:
  pushl $0
8010847a:	6a 00                	push   $0x0
  pushl $170
8010847c:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80108481:	e9 fa f2 ff ff       	jmp    80107780 <alltraps>

80108486 <vector171>:
.globl vector171
vector171:
  pushl $0
80108486:	6a 00                	push   $0x0
  pushl $171
80108488:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
8010848d:	e9 ee f2 ff ff       	jmp    80107780 <alltraps>

80108492 <vector172>:
.globl vector172
vector172:
  pushl $0
80108492:	6a 00                	push   $0x0
  pushl $172
80108494:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80108499:	e9 e2 f2 ff ff       	jmp    80107780 <alltraps>

8010849e <vector173>:
.globl vector173
vector173:
  pushl $0
8010849e:	6a 00                	push   $0x0
  pushl $173
801084a0:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
801084a5:	e9 d6 f2 ff ff       	jmp    80107780 <alltraps>

801084aa <vector174>:
.globl vector174
vector174:
  pushl $0
801084aa:	6a 00                	push   $0x0
  pushl $174
801084ac:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
801084b1:	e9 ca f2 ff ff       	jmp    80107780 <alltraps>

801084b6 <vector175>:
.globl vector175
vector175:
  pushl $0
801084b6:	6a 00                	push   $0x0
  pushl $175
801084b8:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
801084bd:	e9 be f2 ff ff       	jmp    80107780 <alltraps>

801084c2 <vector176>:
.globl vector176
vector176:
  pushl $0
801084c2:	6a 00                	push   $0x0
  pushl $176
801084c4:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
801084c9:	e9 b2 f2 ff ff       	jmp    80107780 <alltraps>

801084ce <vector177>:
.globl vector177
vector177:
  pushl $0
801084ce:	6a 00                	push   $0x0
  pushl $177
801084d0:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
801084d5:	e9 a6 f2 ff ff       	jmp    80107780 <alltraps>

801084da <vector178>:
.globl vector178
vector178:
  pushl $0
801084da:	6a 00                	push   $0x0
  pushl $178
801084dc:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
801084e1:	e9 9a f2 ff ff       	jmp    80107780 <alltraps>

801084e6 <vector179>:
.globl vector179
vector179:
  pushl $0
801084e6:	6a 00                	push   $0x0
  pushl $179
801084e8:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
801084ed:	e9 8e f2 ff ff       	jmp    80107780 <alltraps>

801084f2 <vector180>:
.globl vector180
vector180:
  pushl $0
801084f2:	6a 00                	push   $0x0
  pushl $180
801084f4:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
801084f9:	e9 82 f2 ff ff       	jmp    80107780 <alltraps>

801084fe <vector181>:
.globl vector181
vector181:
  pushl $0
801084fe:	6a 00                	push   $0x0
  pushl $181
80108500:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80108505:	e9 76 f2 ff ff       	jmp    80107780 <alltraps>

8010850a <vector182>:
.globl vector182
vector182:
  pushl $0
8010850a:	6a 00                	push   $0x0
  pushl $182
8010850c:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80108511:	e9 6a f2 ff ff       	jmp    80107780 <alltraps>

80108516 <vector183>:
.globl vector183
vector183:
  pushl $0
80108516:	6a 00                	push   $0x0
  pushl $183
80108518:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
8010851d:	e9 5e f2 ff ff       	jmp    80107780 <alltraps>

80108522 <vector184>:
.globl vector184
vector184:
  pushl $0
80108522:	6a 00                	push   $0x0
  pushl $184
80108524:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80108529:	e9 52 f2 ff ff       	jmp    80107780 <alltraps>

8010852e <vector185>:
.globl vector185
vector185:
  pushl $0
8010852e:	6a 00                	push   $0x0
  pushl $185
80108530:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80108535:	e9 46 f2 ff ff       	jmp    80107780 <alltraps>

8010853a <vector186>:
.globl vector186
vector186:
  pushl $0
8010853a:	6a 00                	push   $0x0
  pushl $186
8010853c:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80108541:	e9 3a f2 ff ff       	jmp    80107780 <alltraps>

80108546 <vector187>:
.globl vector187
vector187:
  pushl $0
80108546:	6a 00                	push   $0x0
  pushl $187
80108548:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
8010854d:	e9 2e f2 ff ff       	jmp    80107780 <alltraps>

80108552 <vector188>:
.globl vector188
vector188:
  pushl $0
80108552:	6a 00                	push   $0x0
  pushl $188
80108554:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80108559:	e9 22 f2 ff ff       	jmp    80107780 <alltraps>

8010855e <vector189>:
.globl vector189
vector189:
  pushl $0
8010855e:	6a 00                	push   $0x0
  pushl $189
80108560:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80108565:	e9 16 f2 ff ff       	jmp    80107780 <alltraps>

8010856a <vector190>:
.globl vector190
vector190:
  pushl $0
8010856a:	6a 00                	push   $0x0
  pushl $190
8010856c:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80108571:	e9 0a f2 ff ff       	jmp    80107780 <alltraps>

80108576 <vector191>:
.globl vector191
vector191:
  pushl $0
80108576:	6a 00                	push   $0x0
  pushl $191
80108578:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
8010857d:	e9 fe f1 ff ff       	jmp    80107780 <alltraps>

80108582 <vector192>:
.globl vector192
vector192:
  pushl $0
80108582:	6a 00                	push   $0x0
  pushl $192
80108584:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80108589:	e9 f2 f1 ff ff       	jmp    80107780 <alltraps>

8010858e <vector193>:
.globl vector193
vector193:
  pushl $0
8010858e:	6a 00                	push   $0x0
  pushl $193
80108590:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80108595:	e9 e6 f1 ff ff       	jmp    80107780 <alltraps>

8010859a <vector194>:
.globl vector194
vector194:
  pushl $0
8010859a:	6a 00                	push   $0x0
  pushl $194
8010859c:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
801085a1:	e9 da f1 ff ff       	jmp    80107780 <alltraps>

801085a6 <vector195>:
.globl vector195
vector195:
  pushl $0
801085a6:	6a 00                	push   $0x0
  pushl $195
801085a8:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
801085ad:	e9 ce f1 ff ff       	jmp    80107780 <alltraps>

801085b2 <vector196>:
.globl vector196
vector196:
  pushl $0
801085b2:	6a 00                	push   $0x0
  pushl $196
801085b4:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
801085b9:	e9 c2 f1 ff ff       	jmp    80107780 <alltraps>

801085be <vector197>:
.globl vector197
vector197:
  pushl $0
801085be:	6a 00                	push   $0x0
  pushl $197
801085c0:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
801085c5:	e9 b6 f1 ff ff       	jmp    80107780 <alltraps>

801085ca <vector198>:
.globl vector198
vector198:
  pushl $0
801085ca:	6a 00                	push   $0x0
  pushl $198
801085cc:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
801085d1:	e9 aa f1 ff ff       	jmp    80107780 <alltraps>

801085d6 <vector199>:
.globl vector199
vector199:
  pushl $0
801085d6:	6a 00                	push   $0x0
  pushl $199
801085d8:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
801085dd:	e9 9e f1 ff ff       	jmp    80107780 <alltraps>

801085e2 <vector200>:
.globl vector200
vector200:
  pushl $0
801085e2:	6a 00                	push   $0x0
  pushl $200
801085e4:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
801085e9:	e9 92 f1 ff ff       	jmp    80107780 <alltraps>

801085ee <vector201>:
.globl vector201
vector201:
  pushl $0
801085ee:	6a 00                	push   $0x0
  pushl $201
801085f0:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
801085f5:	e9 86 f1 ff ff       	jmp    80107780 <alltraps>

801085fa <vector202>:
.globl vector202
vector202:
  pushl $0
801085fa:	6a 00                	push   $0x0
  pushl $202
801085fc:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80108601:	e9 7a f1 ff ff       	jmp    80107780 <alltraps>

80108606 <vector203>:
.globl vector203
vector203:
  pushl $0
80108606:	6a 00                	push   $0x0
  pushl $203
80108608:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
8010860d:	e9 6e f1 ff ff       	jmp    80107780 <alltraps>

80108612 <vector204>:
.globl vector204
vector204:
  pushl $0
80108612:	6a 00                	push   $0x0
  pushl $204
80108614:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80108619:	e9 62 f1 ff ff       	jmp    80107780 <alltraps>

8010861e <vector205>:
.globl vector205
vector205:
  pushl $0
8010861e:	6a 00                	push   $0x0
  pushl $205
80108620:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80108625:	e9 56 f1 ff ff       	jmp    80107780 <alltraps>

8010862a <vector206>:
.globl vector206
vector206:
  pushl $0
8010862a:	6a 00                	push   $0x0
  pushl $206
8010862c:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80108631:	e9 4a f1 ff ff       	jmp    80107780 <alltraps>

80108636 <vector207>:
.globl vector207
vector207:
  pushl $0
80108636:	6a 00                	push   $0x0
  pushl $207
80108638:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
8010863d:	e9 3e f1 ff ff       	jmp    80107780 <alltraps>

80108642 <vector208>:
.globl vector208
vector208:
  pushl $0
80108642:	6a 00                	push   $0x0
  pushl $208
80108644:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80108649:	e9 32 f1 ff ff       	jmp    80107780 <alltraps>

8010864e <vector209>:
.globl vector209
vector209:
  pushl $0
8010864e:	6a 00                	push   $0x0
  pushl $209
80108650:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80108655:	e9 26 f1 ff ff       	jmp    80107780 <alltraps>

8010865a <vector210>:
.globl vector210
vector210:
  pushl $0
8010865a:	6a 00                	push   $0x0
  pushl $210
8010865c:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80108661:	e9 1a f1 ff ff       	jmp    80107780 <alltraps>

80108666 <vector211>:
.globl vector211
vector211:
  pushl $0
80108666:	6a 00                	push   $0x0
  pushl $211
80108668:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
8010866d:	e9 0e f1 ff ff       	jmp    80107780 <alltraps>

80108672 <vector212>:
.globl vector212
vector212:
  pushl $0
80108672:	6a 00                	push   $0x0
  pushl $212
80108674:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80108679:	e9 02 f1 ff ff       	jmp    80107780 <alltraps>

8010867e <vector213>:
.globl vector213
vector213:
  pushl $0
8010867e:	6a 00                	push   $0x0
  pushl $213
80108680:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80108685:	e9 f6 f0 ff ff       	jmp    80107780 <alltraps>

8010868a <vector214>:
.globl vector214
vector214:
  pushl $0
8010868a:	6a 00                	push   $0x0
  pushl $214
8010868c:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80108691:	e9 ea f0 ff ff       	jmp    80107780 <alltraps>

80108696 <vector215>:
.globl vector215
vector215:
  pushl $0
80108696:	6a 00                	push   $0x0
  pushl $215
80108698:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
8010869d:	e9 de f0 ff ff       	jmp    80107780 <alltraps>

801086a2 <vector216>:
.globl vector216
vector216:
  pushl $0
801086a2:	6a 00                	push   $0x0
  pushl $216
801086a4:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
801086a9:	e9 d2 f0 ff ff       	jmp    80107780 <alltraps>

801086ae <vector217>:
.globl vector217
vector217:
  pushl $0
801086ae:	6a 00                	push   $0x0
  pushl $217
801086b0:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
801086b5:	e9 c6 f0 ff ff       	jmp    80107780 <alltraps>

801086ba <vector218>:
.globl vector218
vector218:
  pushl $0
801086ba:	6a 00                	push   $0x0
  pushl $218
801086bc:	68 da 00 00 00       	push   $0xda
  jmp alltraps
801086c1:	e9 ba f0 ff ff       	jmp    80107780 <alltraps>

801086c6 <vector219>:
.globl vector219
vector219:
  pushl $0
801086c6:	6a 00                	push   $0x0
  pushl $219
801086c8:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
801086cd:	e9 ae f0 ff ff       	jmp    80107780 <alltraps>

801086d2 <vector220>:
.globl vector220
vector220:
  pushl $0
801086d2:	6a 00                	push   $0x0
  pushl $220
801086d4:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
801086d9:	e9 a2 f0 ff ff       	jmp    80107780 <alltraps>

801086de <vector221>:
.globl vector221
vector221:
  pushl $0
801086de:	6a 00                	push   $0x0
  pushl $221
801086e0:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
801086e5:	e9 96 f0 ff ff       	jmp    80107780 <alltraps>

801086ea <vector222>:
.globl vector222
vector222:
  pushl $0
801086ea:	6a 00                	push   $0x0
  pushl $222
801086ec:	68 de 00 00 00       	push   $0xde
  jmp alltraps
801086f1:	e9 8a f0 ff ff       	jmp    80107780 <alltraps>

801086f6 <vector223>:
.globl vector223
vector223:
  pushl $0
801086f6:	6a 00                	push   $0x0
  pushl $223
801086f8:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
801086fd:	e9 7e f0 ff ff       	jmp    80107780 <alltraps>

80108702 <vector224>:
.globl vector224
vector224:
  pushl $0
80108702:	6a 00                	push   $0x0
  pushl $224
80108704:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80108709:	e9 72 f0 ff ff       	jmp    80107780 <alltraps>

8010870e <vector225>:
.globl vector225
vector225:
  pushl $0
8010870e:	6a 00                	push   $0x0
  pushl $225
80108710:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80108715:	e9 66 f0 ff ff       	jmp    80107780 <alltraps>

8010871a <vector226>:
.globl vector226
vector226:
  pushl $0
8010871a:	6a 00                	push   $0x0
  pushl $226
8010871c:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80108721:	e9 5a f0 ff ff       	jmp    80107780 <alltraps>

80108726 <vector227>:
.globl vector227
vector227:
  pushl $0
80108726:	6a 00                	push   $0x0
  pushl $227
80108728:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
8010872d:	e9 4e f0 ff ff       	jmp    80107780 <alltraps>

80108732 <vector228>:
.globl vector228
vector228:
  pushl $0
80108732:	6a 00                	push   $0x0
  pushl $228
80108734:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80108739:	e9 42 f0 ff ff       	jmp    80107780 <alltraps>

8010873e <vector229>:
.globl vector229
vector229:
  pushl $0
8010873e:	6a 00                	push   $0x0
  pushl $229
80108740:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80108745:	e9 36 f0 ff ff       	jmp    80107780 <alltraps>

8010874a <vector230>:
.globl vector230
vector230:
  pushl $0
8010874a:	6a 00                	push   $0x0
  pushl $230
8010874c:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80108751:	e9 2a f0 ff ff       	jmp    80107780 <alltraps>

80108756 <vector231>:
.globl vector231
vector231:
  pushl $0
80108756:	6a 00                	push   $0x0
  pushl $231
80108758:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
8010875d:	e9 1e f0 ff ff       	jmp    80107780 <alltraps>

80108762 <vector232>:
.globl vector232
vector232:
  pushl $0
80108762:	6a 00                	push   $0x0
  pushl $232
80108764:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80108769:	e9 12 f0 ff ff       	jmp    80107780 <alltraps>

8010876e <vector233>:
.globl vector233
vector233:
  pushl $0
8010876e:	6a 00                	push   $0x0
  pushl $233
80108770:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80108775:	e9 06 f0 ff ff       	jmp    80107780 <alltraps>

8010877a <vector234>:
.globl vector234
vector234:
  pushl $0
8010877a:	6a 00                	push   $0x0
  pushl $234
8010877c:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80108781:	e9 fa ef ff ff       	jmp    80107780 <alltraps>

80108786 <vector235>:
.globl vector235
vector235:
  pushl $0
80108786:	6a 00                	push   $0x0
  pushl $235
80108788:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
8010878d:	e9 ee ef ff ff       	jmp    80107780 <alltraps>

80108792 <vector236>:
.globl vector236
vector236:
  pushl $0
80108792:	6a 00                	push   $0x0
  pushl $236
80108794:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80108799:	e9 e2 ef ff ff       	jmp    80107780 <alltraps>

8010879e <vector237>:
.globl vector237
vector237:
  pushl $0
8010879e:	6a 00                	push   $0x0
  pushl $237
801087a0:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
801087a5:	e9 d6 ef ff ff       	jmp    80107780 <alltraps>

801087aa <vector238>:
.globl vector238
vector238:
  pushl $0
801087aa:	6a 00                	push   $0x0
  pushl $238
801087ac:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
801087b1:	e9 ca ef ff ff       	jmp    80107780 <alltraps>

801087b6 <vector239>:
.globl vector239
vector239:
  pushl $0
801087b6:	6a 00                	push   $0x0
  pushl $239
801087b8:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
801087bd:	e9 be ef ff ff       	jmp    80107780 <alltraps>

801087c2 <vector240>:
.globl vector240
vector240:
  pushl $0
801087c2:	6a 00                	push   $0x0
  pushl $240
801087c4:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
801087c9:	e9 b2 ef ff ff       	jmp    80107780 <alltraps>

801087ce <vector241>:
.globl vector241
vector241:
  pushl $0
801087ce:	6a 00                	push   $0x0
  pushl $241
801087d0:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
801087d5:	e9 a6 ef ff ff       	jmp    80107780 <alltraps>

801087da <vector242>:
.globl vector242
vector242:
  pushl $0
801087da:	6a 00                	push   $0x0
  pushl $242
801087dc:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
801087e1:	e9 9a ef ff ff       	jmp    80107780 <alltraps>

801087e6 <vector243>:
.globl vector243
vector243:
  pushl $0
801087e6:	6a 00                	push   $0x0
  pushl $243
801087e8:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
801087ed:	e9 8e ef ff ff       	jmp    80107780 <alltraps>

801087f2 <vector244>:
.globl vector244
vector244:
  pushl $0
801087f2:	6a 00                	push   $0x0
  pushl $244
801087f4:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
801087f9:	e9 82 ef ff ff       	jmp    80107780 <alltraps>

801087fe <vector245>:
.globl vector245
vector245:
  pushl $0
801087fe:	6a 00                	push   $0x0
  pushl $245
80108800:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80108805:	e9 76 ef ff ff       	jmp    80107780 <alltraps>

8010880a <vector246>:
.globl vector246
vector246:
  pushl $0
8010880a:	6a 00                	push   $0x0
  pushl $246
8010880c:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80108811:	e9 6a ef ff ff       	jmp    80107780 <alltraps>

80108816 <vector247>:
.globl vector247
vector247:
  pushl $0
80108816:	6a 00                	push   $0x0
  pushl $247
80108818:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
8010881d:	e9 5e ef ff ff       	jmp    80107780 <alltraps>

80108822 <vector248>:
.globl vector248
vector248:
  pushl $0
80108822:	6a 00                	push   $0x0
  pushl $248
80108824:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80108829:	e9 52 ef ff ff       	jmp    80107780 <alltraps>

8010882e <vector249>:
.globl vector249
vector249:
  pushl $0
8010882e:	6a 00                	push   $0x0
  pushl $249
80108830:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80108835:	e9 46 ef ff ff       	jmp    80107780 <alltraps>

8010883a <vector250>:
.globl vector250
vector250:
  pushl $0
8010883a:	6a 00                	push   $0x0
  pushl $250
8010883c:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80108841:	e9 3a ef ff ff       	jmp    80107780 <alltraps>

80108846 <vector251>:
.globl vector251
vector251:
  pushl $0
80108846:	6a 00                	push   $0x0
  pushl $251
80108848:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
8010884d:	e9 2e ef ff ff       	jmp    80107780 <alltraps>

80108852 <vector252>:
.globl vector252
vector252:
  pushl $0
80108852:	6a 00                	push   $0x0
  pushl $252
80108854:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80108859:	e9 22 ef ff ff       	jmp    80107780 <alltraps>

8010885e <vector253>:
.globl vector253
vector253:
  pushl $0
8010885e:	6a 00                	push   $0x0
  pushl $253
80108860:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80108865:	e9 16 ef ff ff       	jmp    80107780 <alltraps>

8010886a <vector254>:
.globl vector254
vector254:
  pushl $0
8010886a:	6a 00                	push   $0x0
  pushl $254
8010886c:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80108871:	e9 0a ef ff ff       	jmp    80107780 <alltraps>

80108876 <vector255>:
.globl vector255
vector255:
  pushl $0
80108876:	6a 00                	push   $0x0
  pushl $255
80108878:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
8010887d:	e9 fe ee ff ff       	jmp    80107780 <alltraps>
	...

80108884 <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
80108884:	55                   	push   %ebp
80108885:	89 e5                	mov    %esp,%ebp
80108887:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
8010888a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010888d:	83 e8 01             	sub    $0x1,%eax
80108890:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80108894:	8b 45 08             	mov    0x8(%ebp),%eax
80108897:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
8010889b:	8b 45 08             	mov    0x8(%ebp),%eax
8010889e:	c1 e8 10             	shr    $0x10,%eax
801088a1:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
801088a5:	8d 45 fa             	lea    -0x6(%ebp),%eax
801088a8:	0f 01 10             	lgdtl  (%eax)
}
801088ab:	c9                   	leave  
801088ac:	c3                   	ret    

801088ad <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
801088ad:	55                   	push   %ebp
801088ae:	89 e5                	mov    %esp,%ebp
801088b0:	83 ec 04             	sub    $0x4,%esp
801088b3:	8b 45 08             	mov    0x8(%ebp),%eax
801088b6:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
801088ba:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
801088be:	0f 00 d8             	ltr    %ax
}
801088c1:	c9                   	leave  
801088c2:	c3                   	ret    

801088c3 <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
801088c3:	55                   	push   %ebp
801088c4:	89 e5                	mov    %esp,%ebp
801088c6:	83 ec 04             	sub    $0x4,%esp
801088c9:	8b 45 08             	mov    0x8(%ebp),%eax
801088cc:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
801088d0:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
801088d4:	8e e8                	mov    %eax,%gs
}
801088d6:	c9                   	leave  
801088d7:	c3                   	ret    

801088d8 <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
801088d8:	55                   	push   %ebp
801088d9:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
801088db:	8b 45 08             	mov    0x8(%ebp),%eax
801088de:	0f 22 d8             	mov    %eax,%cr3
}
801088e1:	5d                   	pop    %ebp
801088e2:	c3                   	ret    

801088e3 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
801088e3:	55                   	push   %ebp
801088e4:	89 e5                	mov    %esp,%ebp
801088e6:	8b 45 08             	mov    0x8(%ebp),%eax
801088e9:	05 00 00 00 80       	add    $0x80000000,%eax
801088ee:	5d                   	pop    %ebp
801088ef:	c3                   	ret    

801088f0 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
801088f0:	55                   	push   %ebp
801088f1:	89 e5                	mov    %esp,%ebp
801088f3:	8b 45 08             	mov    0x8(%ebp),%eax
801088f6:	05 00 00 00 80       	add    $0x80000000,%eax
801088fb:	5d                   	pop    %ebp
801088fc:	c3                   	ret    

801088fd <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
801088fd:	55                   	push   %ebp
801088fe:	89 e5                	mov    %esp,%ebp
80108900:	53                   	push   %ebx
80108901:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
80108904:	e8 c0 ad ff ff       	call   801036c9 <cpunum>
80108909:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
8010890f:	05 40 71 12 80       	add    $0x80127140,%eax
80108914:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80108917:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010891a:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
80108920:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108923:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
80108929:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010892c:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
80108930:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108933:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108937:	83 e2 f0             	and    $0xfffffff0,%edx
8010893a:	83 ca 0a             	or     $0xa,%edx
8010893d:	88 50 7d             	mov    %dl,0x7d(%eax)
80108940:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108943:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108947:	83 ca 10             	or     $0x10,%edx
8010894a:	88 50 7d             	mov    %dl,0x7d(%eax)
8010894d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108950:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108954:	83 e2 9f             	and    $0xffffff9f,%edx
80108957:	88 50 7d             	mov    %dl,0x7d(%eax)
8010895a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010895d:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108961:	83 ca 80             	or     $0xffffff80,%edx
80108964:	88 50 7d             	mov    %dl,0x7d(%eax)
80108967:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010896a:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010896e:	83 ca 0f             	or     $0xf,%edx
80108971:	88 50 7e             	mov    %dl,0x7e(%eax)
80108974:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108977:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010897b:	83 e2 ef             	and    $0xffffffef,%edx
8010897e:	88 50 7e             	mov    %dl,0x7e(%eax)
80108981:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108984:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108988:	83 e2 df             	and    $0xffffffdf,%edx
8010898b:	88 50 7e             	mov    %dl,0x7e(%eax)
8010898e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108991:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108995:	83 ca 40             	or     $0x40,%edx
80108998:	88 50 7e             	mov    %dl,0x7e(%eax)
8010899b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010899e:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801089a2:	83 ca 80             	or     $0xffffff80,%edx
801089a5:	88 50 7e             	mov    %dl,0x7e(%eax)
801089a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089ab:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
801089af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089b2:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
801089b9:	ff ff 
801089bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089be:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
801089c5:	00 00 
801089c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089ca:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
801089d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089d4:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801089db:	83 e2 f0             	and    $0xfffffff0,%edx
801089de:	83 ca 02             	or     $0x2,%edx
801089e1:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801089e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089ea:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801089f1:	83 ca 10             	or     $0x10,%edx
801089f4:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801089fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089fd:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80108a04:	83 e2 9f             	and    $0xffffff9f,%edx
80108a07:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80108a0d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a10:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80108a17:	83 ca 80             	or     $0xffffff80,%edx
80108a1a:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80108a20:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a23:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108a2a:	83 ca 0f             	or     $0xf,%edx
80108a2d:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108a33:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a36:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108a3d:	83 e2 ef             	and    $0xffffffef,%edx
80108a40:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108a46:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a49:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108a50:	83 e2 df             	and    $0xffffffdf,%edx
80108a53:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108a59:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a5c:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108a63:	83 ca 40             	or     $0x40,%edx
80108a66:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108a6c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a6f:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108a76:	83 ca 80             	or     $0xffffff80,%edx
80108a79:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108a7f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a82:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80108a89:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a8c:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
80108a93:	ff ff 
80108a95:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a98:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
80108a9f:	00 00 
80108aa1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108aa4:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
80108aab:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108aae:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80108ab5:	83 e2 f0             	and    $0xfffffff0,%edx
80108ab8:	83 ca 0a             	or     $0xa,%edx
80108abb:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80108ac1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ac4:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80108acb:	83 ca 10             	or     $0x10,%edx
80108ace:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80108ad4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ad7:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80108ade:	83 ca 60             	or     $0x60,%edx
80108ae1:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80108ae7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108aea:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80108af1:	83 ca 80             	or     $0xffffff80,%edx
80108af4:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80108afa:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108afd:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108b04:	83 ca 0f             	or     $0xf,%edx
80108b07:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108b0d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b10:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108b17:	83 e2 ef             	and    $0xffffffef,%edx
80108b1a:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108b20:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b23:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108b2a:	83 e2 df             	and    $0xffffffdf,%edx
80108b2d:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108b33:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b36:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108b3d:	83 ca 40             	or     $0x40,%edx
80108b40:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108b46:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b49:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108b50:	83 ca 80             	or     $0xffffff80,%edx
80108b53:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108b59:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b5c:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80108b63:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b66:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
80108b6d:	ff ff 
80108b6f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b72:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
80108b79:	00 00 
80108b7b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b7e:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
80108b85:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b88:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108b8f:	83 e2 f0             	and    $0xfffffff0,%edx
80108b92:	83 ca 02             	or     $0x2,%edx
80108b95:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108b9b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b9e:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108ba5:	83 ca 10             	or     $0x10,%edx
80108ba8:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108bae:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108bb1:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108bb8:	83 ca 60             	or     $0x60,%edx
80108bbb:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108bc1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108bc4:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108bcb:	83 ca 80             	or     $0xffffff80,%edx
80108bce:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108bd4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108bd7:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108bde:	83 ca 0f             	or     $0xf,%edx
80108be1:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108be7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108bea:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108bf1:	83 e2 ef             	and    $0xffffffef,%edx
80108bf4:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108bfa:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108bfd:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108c04:	83 e2 df             	and    $0xffffffdf,%edx
80108c07:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108c0d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c10:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108c17:	83 ca 40             	or     $0x40,%edx
80108c1a:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108c20:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c23:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108c2a:	83 ca 80             	or     $0xffffff80,%edx
80108c2d:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108c33:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c36:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
80108c3d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c40:	05 b4 00 00 00       	add    $0xb4,%eax
80108c45:	89 c3                	mov    %eax,%ebx
80108c47:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c4a:	05 b4 00 00 00       	add    $0xb4,%eax
80108c4f:	c1 e8 10             	shr    $0x10,%eax
80108c52:	89 c1                	mov    %eax,%ecx
80108c54:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c57:	05 b4 00 00 00       	add    $0xb4,%eax
80108c5c:	c1 e8 18             	shr    $0x18,%eax
80108c5f:	89 c2                	mov    %eax,%edx
80108c61:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c64:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
80108c6b:	00 00 
80108c6d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c70:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
80108c77:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c7a:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
80108c80:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c83:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108c8a:	83 e1 f0             	and    $0xfffffff0,%ecx
80108c8d:	83 c9 02             	or     $0x2,%ecx
80108c90:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108c96:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c99:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108ca0:	83 c9 10             	or     $0x10,%ecx
80108ca3:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108ca9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108cac:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108cb3:	83 e1 9f             	and    $0xffffff9f,%ecx
80108cb6:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108cbc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108cbf:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108cc6:	83 c9 80             	or     $0xffffff80,%ecx
80108cc9:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108ccf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108cd2:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108cd9:	83 e1 f0             	and    $0xfffffff0,%ecx
80108cdc:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108ce2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ce5:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108cec:	83 e1 ef             	and    $0xffffffef,%ecx
80108cef:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108cf5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108cf8:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108cff:	83 e1 df             	and    $0xffffffdf,%ecx
80108d02:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108d08:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d0b:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108d12:	83 c9 40             	or     $0x40,%ecx
80108d15:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108d1b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d1e:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108d25:	83 c9 80             	or     $0xffffff80,%ecx
80108d28:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108d2e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d31:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
80108d37:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d3a:	83 c0 70             	add    $0x70,%eax
80108d3d:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
80108d44:	00 
80108d45:	89 04 24             	mov    %eax,(%esp)
80108d48:	e8 37 fb ff ff       	call   80108884 <lgdt>
  loadgs(SEG_KCPU << 3);
80108d4d:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
80108d54:	e8 6a fb ff ff       	call   801088c3 <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
80108d59:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d5c:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
80108d62:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80108d69:	00 00 00 00 
}
80108d6d:	83 c4 24             	add    $0x24,%esp
80108d70:	5b                   	pop    %ebx
80108d71:	5d                   	pop    %ebp
80108d72:	c3                   	ret    

80108d73 <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80108d73:	55                   	push   %ebp
80108d74:	89 e5                	mov    %esp,%ebp
80108d76:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80108d79:	8b 45 0c             	mov    0xc(%ebp),%eax
80108d7c:	c1 e8 16             	shr    $0x16,%eax
80108d7f:	c1 e0 02             	shl    $0x2,%eax
80108d82:	03 45 08             	add    0x8(%ebp),%eax
80108d85:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
80108d88:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108d8b:	8b 00                	mov    (%eax),%eax
80108d8d:	83 e0 01             	and    $0x1,%eax
80108d90:	84 c0                	test   %al,%al
80108d92:	74 17                	je     80108dab <walkpgdir+0x38>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
80108d94:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108d97:	8b 00                	mov    (%eax),%eax
80108d99:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108d9e:	89 04 24             	mov    %eax,(%esp)
80108da1:	e8 4a fb ff ff       	call   801088f0 <p2v>
80108da6:	89 45 f4             	mov    %eax,-0xc(%ebp)
80108da9:	eb 4b                	jmp    80108df6 <walkpgdir+0x83>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
80108dab:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80108daf:	74 0e                	je     80108dbf <walkpgdir+0x4c>
80108db1:	e8 5a 9d ff ff       	call   80102b10 <kalloc>
80108db6:	89 45 f4             	mov    %eax,-0xc(%ebp)
80108db9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80108dbd:	75 07                	jne    80108dc6 <walkpgdir+0x53>
      return 0;
80108dbf:	b8 00 00 00 00       	mov    $0x0,%eax
80108dc4:	eb 41                	jmp    80108e07 <walkpgdir+0x94>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
80108dc6:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108dcd:	00 
80108dce:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108dd5:	00 
80108dd6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108dd9:	89 04 24             	mov    %eax,(%esp)
80108ddc:	e8 5d d0 ff ff       	call   80105e3e <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
80108de1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108de4:	89 04 24             	mov    %eax,(%esp)
80108de7:	e8 f7 fa ff ff       	call   801088e3 <v2p>
80108dec:	89 c2                	mov    %eax,%edx
80108dee:	83 ca 07             	or     $0x7,%edx
80108df1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108df4:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
80108df6:	8b 45 0c             	mov    0xc(%ebp),%eax
80108df9:	c1 e8 0c             	shr    $0xc,%eax
80108dfc:	25 ff 03 00 00       	and    $0x3ff,%eax
80108e01:	c1 e0 02             	shl    $0x2,%eax
80108e04:	03 45 f4             	add    -0xc(%ebp),%eax
}
80108e07:	c9                   	leave  
80108e08:	c3                   	ret    

80108e09 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80108e09:	55                   	push   %ebp
80108e0a:	89 e5                	mov    %esp,%ebp
80108e0c:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
80108e0f:	8b 45 0c             	mov    0xc(%ebp),%eax
80108e12:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108e17:	89 45 f4             	mov    %eax,-0xc(%ebp)
  //cprintf("mappages: a = %p\n",a);
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80108e1a:	8b 45 0c             	mov    0xc(%ebp),%eax
80108e1d:	03 45 10             	add    0x10(%ebp),%eax
80108e20:	83 e8 01             	sub    $0x1,%eax
80108e23:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108e28:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80108e2b:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80108e32:	00 
80108e33:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e36:	89 44 24 04          	mov    %eax,0x4(%esp)
80108e3a:	8b 45 08             	mov    0x8(%ebp),%eax
80108e3d:	89 04 24             	mov    %eax,(%esp)
80108e40:	e8 2e ff ff ff       	call   80108d73 <walkpgdir>
80108e45:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108e48:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108e4c:	75 07                	jne    80108e55 <mappages+0x4c>
      return -1;
80108e4e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108e53:	eb 46                	jmp    80108e9b <mappages+0x92>
    if(*pte & PTE_P)
80108e55:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108e58:	8b 00                	mov    (%eax),%eax
80108e5a:	83 e0 01             	and    $0x1,%eax
80108e5d:	84 c0                	test   %al,%al
80108e5f:	74 0c                	je     80108e6d <mappages+0x64>
      panic("remap");
80108e61:	c7 04 24 1c 9e 10 80 	movl   $0x80109e1c,(%esp)
80108e68:	e8 d0 76 ff ff       	call   8010053d <panic>
    *pte = pa | perm | PTE_P;
80108e6d:	8b 45 18             	mov    0x18(%ebp),%eax
80108e70:	0b 45 14             	or     0x14(%ebp),%eax
80108e73:	89 c2                	mov    %eax,%edx
80108e75:	83 ca 01             	or     $0x1,%edx
80108e78:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108e7b:	89 10                	mov    %edx,(%eax)
   //cprintf("mappages: pte = %p\n",pte);
    if(a == last)
80108e7d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e80:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80108e83:	74 10                	je     80108e95 <mappages+0x8c>
      break;
    a += PGSIZE;
80108e85:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
80108e8c:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
80108e93:	eb 96                	jmp    80108e2b <mappages+0x22>
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
   //cprintf("mappages: pte = %p\n",pte);
    if(a == last)
      break;
80108e95:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
80108e96:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108e9b:	c9                   	leave  
80108e9c:	c3                   	ret    

80108e9d <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm()
{
80108e9d:	55                   	push   %ebp
80108e9e:	89 e5                	mov    %esp,%ebp
80108ea0:	53                   	push   %ebx
80108ea1:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
80108ea4:	e8 67 9c ff ff       	call   80102b10 <kalloc>
80108ea9:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108eac:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108eb0:	75 0a                	jne    80108ebc <setupkvm+0x1f>
    return 0;
80108eb2:	b8 00 00 00 00       	mov    $0x0,%eax
80108eb7:	e9 98 00 00 00       	jmp    80108f54 <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
80108ebc:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108ec3:	00 
80108ec4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108ecb:	00 
80108ecc:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108ecf:	89 04 24             	mov    %eax,(%esp)
80108ed2:	e8 67 cf ff ff       	call   80105e3e <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
80108ed7:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
80108ede:	e8 0d fa ff ff       	call   801088f0 <p2v>
80108ee3:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
80108ee8:	76 0c                	jbe    80108ef6 <setupkvm+0x59>
    panic("PHYSTOP too high");
80108eea:	c7 04 24 22 9e 10 80 	movl   $0x80109e22,(%esp)
80108ef1:	e8 47 76 ff ff       	call   8010053d <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80108ef6:	c7 45 f4 c0 c4 10 80 	movl   $0x8010c4c0,-0xc(%ebp)
80108efd:	eb 49                	jmp    80108f48 <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
80108eff:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80108f02:	8b 48 0c             	mov    0xc(%eax),%ecx
                (uint)k->phys_start, k->perm) < 0)
80108f05:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80108f08:	8b 50 04             	mov    0x4(%eax),%edx
80108f0b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108f0e:	8b 58 08             	mov    0x8(%eax),%ebx
80108f11:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108f14:	8b 40 04             	mov    0x4(%eax),%eax
80108f17:	29 c3                	sub    %eax,%ebx
80108f19:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108f1c:	8b 00                	mov    (%eax),%eax
80108f1e:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80108f22:	89 54 24 0c          	mov    %edx,0xc(%esp)
80108f26:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80108f2a:	89 44 24 04          	mov    %eax,0x4(%esp)
80108f2e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108f31:	89 04 24             	mov    %eax,(%esp)
80108f34:	e8 d0 fe ff ff       	call   80108e09 <mappages>
80108f39:	85 c0                	test   %eax,%eax
80108f3b:	79 07                	jns    80108f44 <setupkvm+0xa7>
                (uint)k->phys_start, k->perm) < 0)
      return 0;
80108f3d:	b8 00 00 00 00       	mov    $0x0,%eax
80108f42:	eb 10                	jmp    80108f54 <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80108f44:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80108f48:	81 7d f4 00 c5 10 80 	cmpl   $0x8010c500,-0xc(%ebp)
80108f4f:	72 ae                	jb     80108eff <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
      return 0;
  return pgdir;
80108f51:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80108f54:	83 c4 34             	add    $0x34,%esp
80108f57:	5b                   	pop    %ebx
80108f58:	5d                   	pop    %ebp
80108f59:	c3                   	ret    

80108f5a <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
void
kvmalloc(void)
{
80108f5a:	55                   	push   %ebp
80108f5b:	89 e5                	mov    %esp,%ebp
80108f5d:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80108f60:	e8 38 ff ff ff       	call   80108e9d <setupkvm>
80108f65:	a3 18 a4 12 80       	mov    %eax,0x8012a418
  switchkvm();
80108f6a:	e8 02 00 00 00       	call   80108f71 <switchkvm>
}
80108f6f:	c9                   	leave  
80108f70:	c3                   	ret    

80108f71 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80108f71:	55                   	push   %ebp
80108f72:	89 e5                	mov    %esp,%ebp
80108f74:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
80108f77:	a1 18 a4 12 80       	mov    0x8012a418,%eax
80108f7c:	89 04 24             	mov    %eax,(%esp)
80108f7f:	e8 5f f9 ff ff       	call   801088e3 <v2p>
80108f84:	89 04 24             	mov    %eax,(%esp)
80108f87:	e8 4c f9 ff ff       	call   801088d8 <lcr3>
}
80108f8c:	c9                   	leave  
80108f8d:	c3                   	ret    

80108f8e <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80108f8e:	55                   	push   %ebp
80108f8f:	89 e5                	mov    %esp,%ebp
80108f91:	53                   	push   %ebx
80108f92:	83 ec 14             	sub    $0x14,%esp
  pushcli();
80108f95:	e8 9e cd ff ff       	call   80105d38 <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
80108f9a:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108fa0:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108fa7:	83 c2 08             	add    $0x8,%edx
80108faa:	89 d3                	mov    %edx,%ebx
80108fac:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108fb3:	83 c2 08             	add    $0x8,%edx
80108fb6:	c1 ea 10             	shr    $0x10,%edx
80108fb9:	89 d1                	mov    %edx,%ecx
80108fbb:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108fc2:	83 c2 08             	add    $0x8,%edx
80108fc5:	c1 ea 18             	shr    $0x18,%edx
80108fc8:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
80108fcf:	67 00 
80108fd1:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
80108fd8:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
80108fde:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108fe5:	83 e1 f0             	and    $0xfffffff0,%ecx
80108fe8:	83 c9 09             	or     $0x9,%ecx
80108feb:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108ff1:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108ff8:	83 c9 10             	or     $0x10,%ecx
80108ffb:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80109001:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80109008:	83 e1 9f             	and    $0xffffff9f,%ecx
8010900b:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80109011:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80109018:	83 c9 80             	or     $0xffffff80,%ecx
8010901b:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80109021:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80109028:	83 e1 f0             	and    $0xfffffff0,%ecx
8010902b:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80109031:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80109038:	83 e1 ef             	and    $0xffffffef,%ecx
8010903b:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80109041:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80109048:	83 e1 df             	and    $0xffffffdf,%ecx
8010904b:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80109051:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80109058:	83 c9 40             	or     $0x40,%ecx
8010905b:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80109061:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80109068:	83 e1 7f             	and    $0x7f,%ecx
8010906b:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80109071:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
80109077:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010907d:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
80109084:	83 e2 ef             	and    $0xffffffef,%edx
80109087:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
8010908d:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80109093:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
80109099:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010909f:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801090a6:	8b 52 08             	mov    0x8(%edx),%edx
801090a9:	81 c2 00 10 00 00    	add    $0x1000,%edx
801090af:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
801090b2:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
801090b9:	e8 ef f7 ff ff       	call   801088ad <ltr>
  if(p->pgdir == 0)
801090be:	8b 45 08             	mov    0x8(%ebp),%eax
801090c1:	8b 40 04             	mov    0x4(%eax),%eax
801090c4:	85 c0                	test   %eax,%eax
801090c6:	75 0c                	jne    801090d4 <switchuvm+0x146>
    panic("switchuvm: no pgdir");
801090c8:	c7 04 24 33 9e 10 80 	movl   $0x80109e33,(%esp)
801090cf:	e8 69 74 ff ff       	call   8010053d <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
801090d4:	8b 45 08             	mov    0x8(%ebp),%eax
801090d7:	8b 40 04             	mov    0x4(%eax),%eax
801090da:	89 04 24             	mov    %eax,(%esp)
801090dd:	e8 01 f8 ff ff       	call   801088e3 <v2p>
801090e2:	89 04 24             	mov    %eax,(%esp)
801090e5:	e8 ee f7 ff ff       	call   801088d8 <lcr3>
  popcli();
801090ea:	e8 91 cc ff ff       	call   80105d80 <popcli>
}
801090ef:	83 c4 14             	add    $0x14,%esp
801090f2:	5b                   	pop    %ebx
801090f3:	5d                   	pop    %ebp
801090f4:	c3                   	ret    

801090f5 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
801090f5:	55                   	push   %ebp
801090f6:	89 e5                	mov    %esp,%ebp
801090f8:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
801090fb:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
80109102:	76 0c                	jbe    80109110 <inituvm+0x1b>
    panic("inituvm: more than a page");
80109104:	c7 04 24 47 9e 10 80 	movl   $0x80109e47,(%esp)
8010910b:	e8 2d 74 ff ff       	call   8010053d <panic>
  mem = kalloc();
80109110:	e8 fb 99 ff ff       	call   80102b10 <kalloc>
80109115:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
80109118:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010911f:	00 
80109120:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80109127:	00 
80109128:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010912b:	89 04 24             	mov    %eax,(%esp)
8010912e:	e8 0b cd ff ff       	call   80105e3e <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
80109133:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109136:	89 04 24             	mov    %eax,(%esp)
80109139:	e8 a5 f7 ff ff       	call   801088e3 <v2p>
8010913e:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80109145:	00 
80109146:	89 44 24 0c          	mov    %eax,0xc(%esp)
8010914a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80109151:	00 
80109152:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80109159:	00 
8010915a:	8b 45 08             	mov    0x8(%ebp),%eax
8010915d:	89 04 24             	mov    %eax,(%esp)
80109160:	e8 a4 fc ff ff       	call   80108e09 <mappages>
  memmove(mem, init, sz);
80109165:	8b 45 10             	mov    0x10(%ebp),%eax
80109168:	89 44 24 08          	mov    %eax,0x8(%esp)
8010916c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010916f:	89 44 24 04          	mov    %eax,0x4(%esp)
80109173:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109176:	89 04 24             	mov    %eax,(%esp)
80109179:	e8 93 cd ff ff       	call   80105f11 <memmove>
}
8010917e:	c9                   	leave  
8010917f:	c3                   	ret    

80109180 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80109180:	55                   	push   %ebp
80109181:	89 e5                	mov    %esp,%ebp
80109183:	53                   	push   %ebx
80109184:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;
  if((uint) addr % PGSIZE != 0)
80109187:	8b 45 0c             	mov    0xc(%ebp),%eax
8010918a:	25 ff 0f 00 00       	and    $0xfff,%eax
8010918f:	85 c0                	test   %eax,%eax
80109191:	74 0c                	je     8010919f <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
80109193:	c7 04 24 64 9e 10 80 	movl   $0x80109e64,(%esp)
8010919a:	e8 9e 73 ff ff       	call   8010053d <panic>
  for(i = 0; i < sz; i += PGSIZE){
8010919f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801091a6:	e9 ad 00 00 00       	jmp    80109258 <loaduvm+0xd8>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
801091ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801091ae:	8b 55 0c             	mov    0xc(%ebp),%edx
801091b1:	01 d0                	add    %edx,%eax
801091b3:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801091ba:	00 
801091bb:	89 44 24 04          	mov    %eax,0x4(%esp)
801091bf:	8b 45 08             	mov    0x8(%ebp),%eax
801091c2:	89 04 24             	mov    %eax,(%esp)
801091c5:	e8 a9 fb ff ff       	call   80108d73 <walkpgdir>
801091ca:	89 45 ec             	mov    %eax,-0x14(%ebp)
801091cd:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801091d1:	75 0c                	jne    801091df <loaduvm+0x5f>
      panic("loaduvm: address should exist");
801091d3:	c7 04 24 87 9e 10 80 	movl   $0x80109e87,(%esp)
801091da:	e8 5e 73 ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
801091df:	8b 45 ec             	mov    -0x14(%ebp),%eax
801091e2:	8b 00                	mov    (%eax),%eax
801091e4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801091e9:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
801091ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
801091ef:	8b 55 18             	mov    0x18(%ebp),%edx
801091f2:	89 d1                	mov    %edx,%ecx
801091f4:	29 c1                	sub    %eax,%ecx
801091f6:	89 c8                	mov    %ecx,%eax
801091f8:	3d ff 0f 00 00       	cmp    $0xfff,%eax
801091fd:	77 11                	ja     80109210 <loaduvm+0x90>
      n = sz - i;
801091ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109202:	8b 55 18             	mov    0x18(%ebp),%edx
80109205:	89 d1                	mov    %edx,%ecx
80109207:	29 c1                	sub    %eax,%ecx
80109209:	89 c8                	mov    %ecx,%eax
8010920b:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010920e:	eb 07                	jmp    80109217 <loaduvm+0x97>
    else
      n = PGSIZE;
80109210:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
80109217:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010921a:	8b 55 14             	mov    0x14(%ebp),%edx
8010921d:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80109220:	8b 45 e8             	mov    -0x18(%ebp),%eax
80109223:	89 04 24             	mov    %eax,(%esp)
80109226:	e8 c5 f6 ff ff       	call   801088f0 <p2v>
8010922b:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010922e:	89 54 24 0c          	mov    %edx,0xc(%esp)
80109232:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80109236:	89 44 24 04          	mov    %eax,0x4(%esp)
8010923a:	8b 45 10             	mov    0x10(%ebp),%eax
8010923d:	89 04 24             	mov    %eax,(%esp)
80109240:	e8 19 8b ff ff       	call   80101d5e <readi>
80109245:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80109248:	74 07                	je     80109251 <loaduvm+0xd1>
      return -1;
8010924a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010924f:	eb 18                	jmp    80109269 <loaduvm+0xe9>
{
  uint i, pa, n;
  pte_t *pte;
  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80109251:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80109258:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010925b:	3b 45 18             	cmp    0x18(%ebp),%eax
8010925e:	0f 82 47 ff ff ff    	jb     801091ab <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
80109264:	b8 00 00 00 00       	mov    $0x0,%eax
}
80109269:	83 c4 24             	add    $0x24,%esp
8010926c:	5b                   	pop    %ebx
8010926d:	5d                   	pop    %ebp
8010926e:	c3                   	ret    

8010926f <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
8010926f:	55                   	push   %ebp
80109270:	89 e5                	mov    %esp,%ebp
80109272:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  uint a;

  if(newsz >= KERNBASE)
80109275:	8b 45 10             	mov    0x10(%ebp),%eax
80109278:	85 c0                	test   %eax,%eax
8010927a:	79 0a                	jns    80109286 <allocuvm+0x17>
    return 0;
8010927c:	b8 00 00 00 00       	mov    $0x0,%eax
80109281:	e9 c1 00 00 00       	jmp    80109347 <allocuvm+0xd8>
  if(newsz < oldsz)
80109286:	8b 45 10             	mov    0x10(%ebp),%eax
80109289:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010928c:	73 08                	jae    80109296 <allocuvm+0x27>
    return oldsz;
8010928e:	8b 45 0c             	mov    0xc(%ebp),%eax
80109291:	e9 b1 00 00 00       	jmp    80109347 <allocuvm+0xd8>
  a = PGROUNDUP(oldsz);
80109296:	8b 45 0c             	mov    0xc(%ebp),%eax
80109299:	05 ff 0f 00 00       	add    $0xfff,%eax
8010929e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801092a3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
801092a6:	e9 8d 00 00 00       	jmp    80109338 <allocuvm+0xc9>
    mem = kalloc();
801092ab:	e8 60 98 ff ff       	call   80102b10 <kalloc>
801092b0:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(mem == 0){
801092b3:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801092b7:	75 2c                	jne    801092e5 <allocuvm+0x76>
      cprintf("allocuvm out of memory\n");
801092b9:	c7 04 24 a5 9e 10 80 	movl   $0x80109ea5,(%esp)
801092c0:	e8 dc 70 ff ff       	call   801003a1 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
801092c5:	8b 45 0c             	mov    0xc(%ebp),%eax
801092c8:	89 44 24 08          	mov    %eax,0x8(%esp)
801092cc:	8b 45 10             	mov    0x10(%ebp),%eax
801092cf:	89 44 24 04          	mov    %eax,0x4(%esp)
801092d3:	8b 45 08             	mov    0x8(%ebp),%eax
801092d6:	89 04 24             	mov    %eax,(%esp)
801092d9:	e8 6b 00 00 00       	call   80109349 <deallocuvm>
      return 0;
801092de:	b8 00 00 00 00       	mov    $0x0,%eax
801092e3:	eb 62                	jmp    80109347 <allocuvm+0xd8>
    }
    memset(mem, 0, PGSIZE);
801092e5:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801092ec:	00 
801092ed:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801092f4:	00 
801092f5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801092f8:	89 04 24             	mov    %eax,(%esp)
801092fb:	e8 3e cb ff ff       	call   80105e3e <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
80109300:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109303:	89 04 24             	mov    %eax,(%esp)
80109306:	e8 d8 f5 ff ff       	call   801088e3 <v2p>
8010930b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010930e:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80109315:	00 
80109316:	89 44 24 0c          	mov    %eax,0xc(%esp)
8010931a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80109321:	00 
80109322:	89 54 24 04          	mov    %edx,0x4(%esp)
80109326:	8b 45 08             	mov    0x8(%ebp),%eax
80109329:	89 04 24             	mov    %eax,(%esp)
8010932c:	e8 d8 fa ff ff       	call   80108e09 <mappages>
  if(newsz >= KERNBASE)
    return 0;
  if(newsz < oldsz)
    return oldsz;
  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
80109331:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80109338:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010933b:	3b 45 10             	cmp    0x10(%ebp),%eax
8010933e:	0f 82 67 ff ff ff    	jb     801092ab <allocuvm+0x3c>
      return 0;
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
  }
  return newsz;
80109344:	8b 45 10             	mov    0x10(%ebp),%eax
}
80109347:	c9                   	leave  
80109348:	c3                   	ret    

80109349 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80109349:	55                   	push   %ebp
8010934a:	89 e5                	mov    %esp,%ebp
8010934c:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
8010934f:	8b 45 10             	mov    0x10(%ebp),%eax
80109352:	3b 45 0c             	cmp    0xc(%ebp),%eax
80109355:	72 08                	jb     8010935f <deallocuvm+0x16>
    return oldsz;
80109357:	8b 45 0c             	mov    0xc(%ebp),%eax
8010935a:	e9 a4 00 00 00       	jmp    80109403 <deallocuvm+0xba>

  a = PGROUNDUP(newsz);
8010935f:	8b 45 10             	mov    0x10(%ebp),%eax
80109362:	05 ff 0f 00 00       	add    $0xfff,%eax
80109367:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010936c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
8010936f:	e9 80 00 00 00       	jmp    801093f4 <deallocuvm+0xab>
    pte = walkpgdir(pgdir, (char*)a, 0);
80109374:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109377:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010937e:	00 
8010937f:	89 44 24 04          	mov    %eax,0x4(%esp)
80109383:	8b 45 08             	mov    0x8(%ebp),%eax
80109386:	89 04 24             	mov    %eax,(%esp)
80109389:	e8 e5 f9 ff ff       	call   80108d73 <walkpgdir>
8010938e:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(!pte)
80109391:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80109395:	75 09                	jne    801093a0 <deallocuvm+0x57>
      a += (NPTENTRIES - 1) * PGSIZE;
80109397:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
8010939e:	eb 4d                	jmp    801093ed <deallocuvm+0xa4>
    else if((*pte & PTE_P) != 0){
801093a0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801093a3:	8b 00                	mov    (%eax),%eax
801093a5:	83 e0 01             	and    $0x1,%eax
801093a8:	84 c0                	test   %al,%al
801093aa:	74 41                	je     801093ed <deallocuvm+0xa4>
      pa = PTE_ADDR(*pte);
801093ac:	8b 45 f0             	mov    -0x10(%ebp),%eax
801093af:	8b 00                	mov    (%eax),%eax
801093b1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801093b6:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if(pa == 0)
801093b9:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801093bd:	75 0c                	jne    801093cb <deallocuvm+0x82>
        panic("kfree");
801093bf:	c7 04 24 bd 9e 10 80 	movl   $0x80109ebd,(%esp)
801093c6:	e8 72 71 ff ff       	call   8010053d <panic>
      char *v = p2v(pa);
801093cb:	8b 45 ec             	mov    -0x14(%ebp),%eax
801093ce:	89 04 24             	mov    %eax,(%esp)
801093d1:	e8 1a f5 ff ff       	call   801088f0 <p2v>
801093d6:	89 45 e8             	mov    %eax,-0x18(%ebp)
      kfree(v);
801093d9:	8b 45 e8             	mov    -0x18(%ebp),%eax
801093dc:	89 04 24             	mov    %eax,(%esp)
801093df:	e8 93 96 ff ff       	call   80102a77 <kfree>
      *pte = 0;
801093e4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801093e7:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
801093ed:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801093f4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801093f7:	3b 45 0c             	cmp    0xc(%ebp),%eax
801093fa:	0f 82 74 ff ff ff    	jb     80109374 <deallocuvm+0x2b>
      char *v = p2v(pa);
      kfree(v);
      *pte = 0;
    }
  }
  return newsz;
80109400:	8b 45 10             	mov    0x10(%ebp),%eax
}
80109403:	c9                   	leave  
80109404:	c3                   	ret    

80109405 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
80109405:	55                   	push   %ebp
80109406:	89 e5                	mov    %esp,%ebp
80109408:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
8010940b:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010940f:	75 0c                	jne    8010941d <freevm+0x18>
    panic("freevm: no pgdir");
80109411:	c7 04 24 c3 9e 10 80 	movl   $0x80109ec3,(%esp)
80109418:	e8 20 71 ff ff       	call   8010053d <panic>
  deallocuvm(pgdir, KERNBASE, 0);
8010941d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80109424:	00 
80109425:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
8010942c:	80 
8010942d:	8b 45 08             	mov    0x8(%ebp),%eax
80109430:	89 04 24             	mov    %eax,(%esp)
80109433:	e8 11 ff ff ff       	call   80109349 <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
80109438:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010943f:	eb 3c                	jmp    8010947d <freevm+0x78>
    if(pgdir[i] & PTE_P){
80109441:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109444:	c1 e0 02             	shl    $0x2,%eax
80109447:	03 45 08             	add    0x8(%ebp),%eax
8010944a:	8b 00                	mov    (%eax),%eax
8010944c:	83 e0 01             	and    $0x1,%eax
8010944f:	84 c0                	test   %al,%al
80109451:	74 26                	je     80109479 <freevm+0x74>
      char * v = p2v(PTE_ADDR(pgdir[i]));
80109453:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109456:	c1 e0 02             	shl    $0x2,%eax
80109459:	03 45 08             	add    0x8(%ebp),%eax
8010945c:	8b 00                	mov    (%eax),%eax
8010945e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109463:	89 04 24             	mov    %eax,(%esp)
80109466:	e8 85 f4 ff ff       	call   801088f0 <p2v>
8010946b:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
8010946e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109471:	89 04 24             	mov    %eax,(%esp)
80109474:	e8 fe 95 ff ff       	call   80102a77 <kfree>
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
  for(i = 0; i < NPDENTRIES; i++){
80109479:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010947d:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
80109484:	76 bb                	jbe    80109441 <freevm+0x3c>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
80109486:	8b 45 08             	mov    0x8(%ebp),%eax
80109489:	89 04 24             	mov    %eax,(%esp)
8010948c:	e8 e6 95 ff ff       	call   80102a77 <kfree>
}
80109491:	c9                   	leave  
80109492:	c3                   	ret    

80109493 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80109493:	55                   	push   %ebp
80109494:	89 e5                	mov    %esp,%ebp
80109496:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80109499:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801094a0:	00 
801094a1:	8b 45 0c             	mov    0xc(%ebp),%eax
801094a4:	89 44 24 04          	mov    %eax,0x4(%esp)
801094a8:	8b 45 08             	mov    0x8(%ebp),%eax
801094ab:	89 04 24             	mov    %eax,(%esp)
801094ae:	e8 c0 f8 ff ff       	call   80108d73 <walkpgdir>
801094b3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
801094b6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801094ba:	75 0c                	jne    801094c8 <clearpteu+0x35>
    panic("clearpteu");
801094bc:	c7 04 24 d4 9e 10 80 	movl   $0x80109ed4,(%esp)
801094c3:	e8 75 70 ff ff       	call   8010053d <panic>
  *pte &= ~PTE_U;
801094c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801094cb:	8b 00                	mov    (%eax),%eax
801094cd:	89 c2                	mov    %eax,%edx
801094cf:	83 e2 fb             	and    $0xfffffffb,%edx
801094d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801094d5:	89 10                	mov    %edx,(%eax)
}
801094d7:	c9                   	leave  
801094d8:	c3                   	ret    

801094d9 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
801094d9:	55                   	push   %ebp
801094da:	89 e5                	mov    %esp,%ebp
801094dc:	83 ec 48             	sub    $0x48,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
801094df:	e8 b9 f9 ff ff       	call   80108e9d <setupkvm>
801094e4:	89 45 f0             	mov    %eax,-0x10(%ebp)
801094e7:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801094eb:	75 0a                	jne    801094f7 <copyuvm+0x1e>
    return 0;
801094ed:	b8 00 00 00 00       	mov    $0x0,%eax
801094f2:	e9 f1 00 00 00       	jmp    801095e8 <copyuvm+0x10f>
  for(i = 0; i < sz; i += PGSIZE){
801094f7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801094fe:	e9 c0 00 00 00       	jmp    801095c3 <copyuvm+0xea>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
80109503:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109506:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010950d:	00 
8010950e:	89 44 24 04          	mov    %eax,0x4(%esp)
80109512:	8b 45 08             	mov    0x8(%ebp),%eax
80109515:	89 04 24             	mov    %eax,(%esp)
80109518:	e8 56 f8 ff ff       	call   80108d73 <walkpgdir>
8010951d:	89 45 ec             	mov    %eax,-0x14(%ebp)
80109520:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80109524:	75 0c                	jne    80109532 <copyuvm+0x59>
      panic("copyuvm: pte should exist");
80109526:	c7 04 24 de 9e 10 80 	movl   $0x80109ede,(%esp)
8010952d:	e8 0b 70 ff ff       	call   8010053d <panic>
    if(!(*pte & PTE_P))
80109532:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109535:	8b 00                	mov    (%eax),%eax
80109537:	83 e0 01             	and    $0x1,%eax
8010953a:	85 c0                	test   %eax,%eax
8010953c:	75 0c                	jne    8010954a <copyuvm+0x71>
      panic("copyuvm: page not present");
8010953e:	c7 04 24 f8 9e 10 80 	movl   $0x80109ef8,(%esp)
80109545:	e8 f3 6f ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
8010954a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010954d:	8b 00                	mov    (%eax),%eax
8010954f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109554:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if((mem = kalloc()) == 0)
80109557:	e8 b4 95 ff ff       	call   80102b10 <kalloc>
8010955c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010955f:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80109563:	74 6f                	je     801095d4 <copyuvm+0xfb>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
80109565:	8b 45 e8             	mov    -0x18(%ebp),%eax
80109568:	89 04 24             	mov    %eax,(%esp)
8010956b:	e8 80 f3 ff ff       	call   801088f0 <p2v>
80109570:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80109577:	00 
80109578:	89 44 24 04          	mov    %eax,0x4(%esp)
8010957c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010957f:	89 04 24             	mov    %eax,(%esp)
80109582:	e8 8a c9 ff ff       	call   80105f11 <memmove>
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
80109587:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010958a:	89 04 24             	mov    %eax,(%esp)
8010958d:	e8 51 f3 ff ff       	call   801088e3 <v2p>
80109592:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109595:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
8010959c:	00 
8010959d:	89 44 24 0c          	mov    %eax,0xc(%esp)
801095a1:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801095a8:	00 
801095a9:	89 54 24 04          	mov    %edx,0x4(%esp)
801095ad:	8b 45 f0             	mov    -0x10(%ebp),%eax
801095b0:	89 04 24             	mov    %eax,(%esp)
801095b3:	e8 51 f8 ff ff       	call   80108e09 <mappages>
801095b8:	85 c0                	test   %eax,%eax
801095ba:	78 1b                	js     801095d7 <copyuvm+0xfe>
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
801095bc:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801095c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801095c6:	3b 45 0c             	cmp    0xc(%ebp),%eax
801095c9:	0f 82 34 ff ff ff    	jb     80109503 <copyuvm+0x2a>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
  }
  return d;
801095cf:	8b 45 f0             	mov    -0x10(%ebp),%eax
801095d2:	eb 14                	jmp    801095e8 <copyuvm+0x10f>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
    if((mem = kalloc()) == 0)
      goto bad;
801095d4:	90                   	nop
801095d5:	eb 01                	jmp    801095d8 <copyuvm+0xff>
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
801095d7:	90                   	nop
  }
  return d;

bad:
  freevm(d);
801095d8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801095db:	89 04 24             	mov    %eax,(%esp)
801095de:	e8 22 fe ff ff       	call   80109405 <freevm>
  return 0;
801095e3:	b8 00 00 00 00       	mov    $0x0,%eax
}
801095e8:	c9                   	leave  
801095e9:	c3                   	ret    

801095ea <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
801095ea:	55                   	push   %ebp
801095eb:	89 e5                	mov    %esp,%ebp
801095ed:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801095f0:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801095f7:	00 
801095f8:	8b 45 0c             	mov    0xc(%ebp),%eax
801095fb:	89 44 24 04          	mov    %eax,0x4(%esp)
801095ff:	8b 45 08             	mov    0x8(%ebp),%eax
80109602:	89 04 24             	mov    %eax,(%esp)
80109605:	e8 69 f7 ff ff       	call   80108d73 <walkpgdir>
8010960a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
8010960d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109610:	8b 00                	mov    (%eax),%eax
80109612:	83 e0 01             	and    $0x1,%eax
80109615:	85 c0                	test   %eax,%eax
80109617:	75 07                	jne    80109620 <uva2ka+0x36>
    return 0;
80109619:	b8 00 00 00 00       	mov    $0x0,%eax
8010961e:	eb 25                	jmp    80109645 <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
80109620:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109623:	8b 00                	mov    (%eax),%eax
80109625:	83 e0 04             	and    $0x4,%eax
80109628:	85 c0                	test   %eax,%eax
8010962a:	75 07                	jne    80109633 <uva2ka+0x49>
    return 0;
8010962c:	b8 00 00 00 00       	mov    $0x0,%eax
80109631:	eb 12                	jmp    80109645 <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
80109633:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109636:	8b 00                	mov    (%eax),%eax
80109638:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010963d:	89 04 24             	mov    %eax,(%esp)
80109640:	e8 ab f2 ff ff       	call   801088f0 <p2v>
}
80109645:	c9                   	leave  
80109646:	c3                   	ret    

80109647 <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
80109647:	55                   	push   %ebp
80109648:	89 e5                	mov    %esp,%ebp
8010964a:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
8010964d:	8b 45 10             	mov    0x10(%ebp),%eax
80109650:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
80109653:	e9 8b 00 00 00       	jmp    801096e3 <copyout+0x9c>
    va0 = (uint)PGROUNDDOWN(va);
80109658:	8b 45 0c             	mov    0xc(%ebp),%eax
8010965b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109660:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
80109663:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109666:	89 44 24 04          	mov    %eax,0x4(%esp)
8010966a:	8b 45 08             	mov    0x8(%ebp),%eax
8010966d:	89 04 24             	mov    %eax,(%esp)
80109670:	e8 75 ff ff ff       	call   801095ea <uva2ka>
80109675:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
80109678:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
8010967c:	75 07                	jne    80109685 <copyout+0x3e>
      return -1;
8010967e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80109683:	eb 6d                	jmp    801096f2 <copyout+0xab>
    n = PGSIZE - (va - va0);
80109685:	8b 45 0c             	mov    0xc(%ebp),%eax
80109688:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010968b:	89 d1                	mov    %edx,%ecx
8010968d:	29 c1                	sub    %eax,%ecx
8010968f:	89 c8                	mov    %ecx,%eax
80109691:	05 00 10 00 00       	add    $0x1000,%eax
80109696:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
80109699:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010969c:	3b 45 14             	cmp    0x14(%ebp),%eax
8010969f:	76 06                	jbe    801096a7 <copyout+0x60>
      n = len;
801096a1:	8b 45 14             	mov    0x14(%ebp),%eax
801096a4:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
801096a7:	8b 45 ec             	mov    -0x14(%ebp),%eax
801096aa:	8b 55 0c             	mov    0xc(%ebp),%edx
801096ad:	89 d1                	mov    %edx,%ecx
801096af:	29 c1                	sub    %eax,%ecx
801096b1:	89 c8                	mov    %ecx,%eax
801096b3:	03 45 e8             	add    -0x18(%ebp),%eax
801096b6:	8b 55 f0             	mov    -0x10(%ebp),%edx
801096b9:	89 54 24 08          	mov    %edx,0x8(%esp)
801096bd:	8b 55 f4             	mov    -0xc(%ebp),%edx
801096c0:	89 54 24 04          	mov    %edx,0x4(%esp)
801096c4:	89 04 24             	mov    %eax,(%esp)
801096c7:	e8 45 c8 ff ff       	call   80105f11 <memmove>
    len -= n;
801096cc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801096cf:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
801096d2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801096d5:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
801096d8:	8b 45 ec             	mov    -0x14(%ebp),%eax
801096db:	05 00 10 00 00       	add    $0x1000,%eax
801096e0:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
801096e3:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
801096e7:	0f 85 6b ff ff ff    	jne    80109658 <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
801096ed:	b8 00 00 00 00       	mov    $0x0,%eax
}
801096f2:	c9                   	leave  
801096f3:	c3                   	ret    
