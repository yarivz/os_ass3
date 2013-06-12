
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
8010002d:	b8 07 3c 10 80       	mov    $0x80103c07,%eax
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
8010003a:	c7 44 24 04 d0 96 10 	movl   $0x801096d0,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 e0 d6 10 80 	movl   $0x8010d6e0,(%esp)
80100049:	e8 24 5b 00 00       	call   80105b72 <initlock>

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
801000bd:	e8 d1 5a 00 00       	call   80105b93 <acquire>

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
80100104:	e8 25 5b 00 00       	call   80105c2e <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 e0 d6 10 	movl   $0x8010d6e0,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 cf 55 00 00       	call   801056f3 <sleep>
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
8010017c:	e8 ad 5a 00 00       	call   80105c2e <release>
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
80100198:	c7 04 24 d7 96 10 80 	movl   $0x801096d7,(%esp)
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
801001ef:	c7 04 24 e8 96 10 80 	movl   $0x801096e8,(%esp)
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
80100229:	c7 04 24 ef 96 10 80 	movl   $0x801096ef,(%esp)
80100230:	e8 08 03 00 00       	call   8010053d <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 e0 d6 10 80 	movl   $0x8010d6e0,(%esp)
8010023c:	e8 52 59 00 00       	call   80105b93 <acquire>

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
8010029d:	e8 c3 55 00 00       	call   80105865 <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 e0 d6 10 80 	movl   $0x8010d6e0,(%esp)
801002a9:	e8 80 59 00 00       	call   80105c2e <release>
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
801003bc:	e8 d2 57 00 00       	call   80105b93 <acquire>

  if (fmt == 0)
801003c1:	8b 45 08             	mov    0x8(%ebp),%eax
801003c4:	85 c0                	test   %eax,%eax
801003c6:	75 0c                	jne    801003d4 <cprintf+0x33>
    panic("null fmt");
801003c8:	c7 04 24 f6 96 10 80 	movl   $0x801096f6,(%esp)
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
801004af:	c7 45 ec ff 96 10 80 	movl   $0x801096ff,-0x14(%ebp)
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
80100536:	e8 f3 56 00 00       	call   80105c2e <release>
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
80100562:	c7 04 24 06 97 10 80 	movl   $0x80109706,(%esp)
80100569:	e8 33 fe ff ff       	call   801003a1 <cprintf>
  cprintf(s);
8010056e:	8b 45 08             	mov    0x8(%ebp),%eax
80100571:	89 04 24             	mov    %eax,(%esp)
80100574:	e8 28 fe ff ff       	call   801003a1 <cprintf>
  cprintf("\n");
80100579:	c7 04 24 15 97 10 80 	movl   $0x80109715,(%esp)
80100580:	e8 1c fe ff ff       	call   801003a1 <cprintf>
  getcallerpcs(&s, pcs);
80100585:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100588:	89 44 24 04          	mov    %eax,0x4(%esp)
8010058c:	8d 45 08             	lea    0x8(%ebp),%eax
8010058f:	89 04 24             	mov    %eax,(%esp)
80100592:	e8 e6 56 00 00       	call   80105c7d <getcallerpcs>
  for(i=0; i<10; i++)
80100597:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010059e:	eb 1b                	jmp    801005bb <panic+0x7e>
    cprintf(" %p", pcs[i]);
801005a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005a3:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005a7:	89 44 24 04          	mov    %eax,0x4(%esp)
801005ab:	c7 04 24 17 97 10 80 	movl   $0x80109717,(%esp)
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
801006b2:	e8 36 58 00 00       	call   80105eed <memmove>
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
801006e1:	e8 34 57 00 00       	call   80105e1a <memset>
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
80100776:	e8 ba 75 00 00       	call   80107d35 <uartputc>
8010077b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80100782:	e8 ae 75 00 00       	call   80107d35 <uartputc>
80100787:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
8010078e:	e8 a2 75 00 00       	call   80107d35 <uartputc>
80100793:	eb 0b                	jmp    801007a0 <consputc+0x50>
  } else
    uartputc(c);
80100795:	8b 45 08             	mov    0x8(%ebp),%eax
80100798:	89 04 24             	mov    %eax,(%esp)
8010079b:	e8 95 75 00 00       	call   80107d35 <uartputc>
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
801007ba:	e8 d4 53 00 00       	call   80105b93 <acquire>
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
801007ea:	e8 6b 51 00 00       	call   8010595a <procdump>
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
801008f7:	e8 69 4f 00 00       	call   80105865 <wakeup>
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
8010091e:	e8 0b 53 00 00       	call   80105c2e <release>
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
80100943:	e8 4b 52 00 00       	call   80105b93 <acquire>
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
80100961:	e8 c8 52 00 00       	call   80105c2e <release>
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
8010098a:	e8 64 4d 00 00       	call   801056f3 <sleep>
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
80100a08:	e8 21 52 00 00       	call   80105c2e <release>
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
80100a3e:	e8 50 51 00 00       	call   80105b93 <acquire>
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
80100a78:	e8 b1 51 00 00       	call   80105c2e <release>
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
80100a93:	c7 44 24 04 1b 97 10 	movl   $0x8010971b,0x4(%esp)
80100a9a:	80 
80100a9b:	c7 04 24 e0 c5 10 80 	movl   $0x8010c5e0,(%esp)
80100aa2:	e8 cb 50 00 00       	call   80105b72 <initlock>
  initlock(&input.lock, "input");
80100aa7:	c7 44 24 04 23 97 10 	movl   $0x80109723,0x4(%esp)
80100aae:	80 
80100aaf:	c7 04 24 20 ee 10 80 	movl   $0x8010ee20,(%esp)
80100ab6:	e8 b7 50 00 00       	call   80105b72 <initlock>

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
80100ae0:	e8 dc 37 00 00       	call   801042c1 <picenable>
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
80100b7b:	e8 f9 82 00 00       	call   80108e79 <setupkvm>
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
80100c14:	e8 32 86 00 00       	call   8010924b <allocuvm>
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
80100c51:	e8 06 85 00 00       	call   8010915c <loaduvm>
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
80100cbc:	e8 8a 85 00 00       	call   8010924b <allocuvm>
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
80100ce0:	e8 8a 87 00 00       	call   8010946f <clearpteu>
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
80100d0f:	e8 84 53 00 00       	call   80106098 <strlen>
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
80100d2d:	e8 66 53 00 00       	call   80106098 <strlen>
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
80100d57:	e8 c7 88 00 00       	call   80109623 <copyout>
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
80100df7:	e8 27 88 00 00       	call   80109623 <copyout>
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
80100e4e:	e8 f7 51 00 00       	call   8010604a <safestrcpy>

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
80100ea0:	e8 c5 80 00 00       	call   80108f6a <switchuvm>
  freevm(oldpgdir);
80100ea5:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100ea8:	89 04 24             	mov    %eax,(%esp)
80100eab:	e8 31 85 00 00       	call   801093e1 <freevm>
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
80100ee2:	e8 fa 84 00 00       	call   801093e1 <freevm>
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
80100f06:	c7 44 24 04 29 97 10 	movl   $0x80109729,0x4(%esp)
80100f0d:	80 
80100f0e:	c7 04 24 e0 ee 10 80 	movl   $0x8010eee0,(%esp)
80100f15:	e8 58 4c 00 00       	call   80105b72 <initlock>
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
80100f29:	e8 65 4c 00 00       	call   80105b93 <acquire>
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
80100f52:	e8 d7 4c 00 00       	call   80105c2e <release>
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
80100f70:	e8 b9 4c 00 00       	call   80105c2e <release>
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
80100f89:	e8 05 4c 00 00       	call   80105b93 <acquire>
  if(f->ref < 1)
80100f8e:	8b 45 08             	mov    0x8(%ebp),%eax
80100f91:	8b 40 04             	mov    0x4(%eax),%eax
80100f94:	85 c0                	test   %eax,%eax
80100f96:	7f 0c                	jg     80100fa4 <filedup+0x28>
    panic("filedup");
80100f98:	c7 04 24 30 97 10 80 	movl   $0x80109730,(%esp)
80100f9f:	e8 99 f5 ff ff       	call   8010053d <panic>
  f->ref++;
80100fa4:	8b 45 08             	mov    0x8(%ebp),%eax
80100fa7:	8b 40 04             	mov    0x4(%eax),%eax
80100faa:	8d 50 01             	lea    0x1(%eax),%edx
80100fad:	8b 45 08             	mov    0x8(%ebp),%eax
80100fb0:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
80100fb3:	c7 04 24 e0 ee 10 80 	movl   $0x8010eee0,(%esp)
80100fba:	e8 6f 4c 00 00       	call   80105c2e <release>
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
80100fd1:	e8 bd 4b 00 00       	call   80105b93 <acquire>
  if(f->ref < 1)
80100fd6:	8b 45 08             	mov    0x8(%ebp),%eax
80100fd9:	8b 40 04             	mov    0x4(%eax),%eax
80100fdc:	85 c0                	test   %eax,%eax
80100fde:	7f 0c                	jg     80100fec <fileclose+0x28>
    panic("fileclose");
80100fe0:	c7 04 24 38 97 10 80 	movl   $0x80109738,(%esp)
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
8010100c:	e8 1d 4c 00 00       	call   80105c2e <release>
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
80101056:	e8 d3 4b 00 00       	call   80105c2e <release>
  
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
80101074:	e8 02 35 00 00       	call   8010457b <pipeclose>
80101079:	eb 1d                	jmp    80101098 <fileclose+0xd4>
  else if(ff.type == FD_INODE){
8010107b:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010107e:	83 f8 02             	cmp    $0x2,%eax
80101081:	75 15                	jne    80101098 <fileclose+0xd4>
    begin_trans();
80101083:	e8 97 29 00 00       	call   80103a1f <begin_trans>
    iput(ff.ip);
80101088:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010108b:	89 04 24             	mov    %eax,(%esp)
8010108e:	e8 88 09 00 00       	call   80101a1b <iput>
    commit_trans();
80101093:	e8 d9 29 00 00       	call   80103a71 <commit_trans>
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
80101125:	e8 d3 35 00 00       	call   801046fd <piperead>
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
80101197:	c7 04 24 42 97 10 80 	movl   $0x80109742,(%esp)
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
801011e2:	e8 26 34 00 00       	call   8010460d <pipewrite>
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
8010122a:	e8 f0 27 00 00       	call   80103a1f <begin_trans>
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
80101290:	e8 dc 27 00 00       	call   80103a71 <commit_trans>

      if(r < 0)
80101295:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80101299:	78 28                	js     801012c3 <filewrite+0x11e>
        break;
      if(r != n1)
8010129b:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010129e:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801012a1:	74 0c                	je     801012af <filewrite+0x10a>
        panic("short filewrite");
801012a3:	c7 04 24 4b 97 10 80 	movl   $0x8010974b,(%esp)
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
801012d8:	c7 04 24 5b 97 10 80 	movl   $0x8010975b,(%esp)
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
80101320:	e8 c8 4b 00 00       	call   80105eed <memmove>
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
80101366:	e8 af 4a 00 00       	call   80105e1a <memset>
  log_write(bp);
8010136b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010136e:	89 04 24             	mov    %eax,(%esp)
80101371:	e8 47 27 00 00       	call   80103abd <log_write>
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
80101457:	e8 61 26 00 00       	call   80103abd <log_write>
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
801014ce:	c7 04 24 65 97 10 80 	movl   $0x80109765,(%esp)
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
80101565:	c7 04 24 7b 97 10 80 	movl   $0x8010977b,(%esp)
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
8010159d:	e8 1b 25 00 00       	call   80103abd <log_write>
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
801015b9:	c7 44 24 04 8e 97 10 	movl   $0x8010978e,0x4(%esp)
801015c0:	80 
801015c1:	c7 04 24 e0 f8 10 80 	movl   $0x8010f8e0,(%esp)
801015c8:	e8 a5 45 00 00       	call   80105b72 <initlock>
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
8010164a:	e8 cb 47 00 00       	call   80105e1a <memset>
      dip->type = type;
8010164f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101652:	0f b7 55 d4          	movzwl -0x2c(%ebp),%edx
80101656:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
80101659:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010165c:	89 04 24             	mov    %eax,(%esp)
8010165f:	e8 59 24 00 00       	call   80103abd <log_write>
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
801016a0:	c7 04 24 95 97 10 80 	movl   $0x80109795,(%esp)
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
80101747:	e8 a1 47 00 00       	call   80105eed <memmove>
  log_write(bp);
8010174c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010174f:	89 04 24             	mov    %eax,(%esp)
80101752:	e8 66 23 00 00       	call   80103abd <log_write>
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
80101771:	e8 1d 44 00 00       	call   80105b93 <acquire>

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
801017bb:	e8 6e 44 00 00       	call   80105c2e <release>
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
801017ee:	c7 04 24 a7 97 10 80 	movl   $0x801097a7,(%esp)
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
8010182c:	e8 fd 43 00 00       	call   80105c2e <release>

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
80101843:	e8 4b 43 00 00       	call   80105b93 <acquire>
  ip->ref++;
80101848:	8b 45 08             	mov    0x8(%ebp),%eax
8010184b:	8b 40 08             	mov    0x8(%eax),%eax
8010184e:	8d 50 01             	lea    0x1(%eax),%edx
80101851:	8b 45 08             	mov    0x8(%ebp),%eax
80101854:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101857:	c7 04 24 e0 f8 10 80 	movl   $0x8010f8e0,(%esp)
8010185e:	e8 cb 43 00 00       	call   80105c2e <release>
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
8010187e:	c7 04 24 b7 97 10 80 	movl   $0x801097b7,(%esp)
80101885:	e8 b3 ec ff ff       	call   8010053d <panic>

  acquire(&icache.lock);
8010188a:	c7 04 24 e0 f8 10 80 	movl   $0x8010f8e0,(%esp)
80101891:	e8 fd 42 00 00       	call   80105b93 <acquire>
  while(ip->flags & I_BUSY)
80101896:	eb 13                	jmp    801018ab <ilock+0x43>
    sleep(ip, &icache.lock);
80101898:	c7 44 24 04 e0 f8 10 	movl   $0x8010f8e0,0x4(%esp)
8010189f:	80 
801018a0:	8b 45 08             	mov    0x8(%ebp),%eax
801018a3:	89 04 24             	mov    %eax,(%esp)
801018a6:	e8 48 3e 00 00       	call   801056f3 <sleep>

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
801018d0:	e8 59 43 00 00       	call   80105c2e <release>

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
8010197b:	e8 6d 45 00 00       	call   80105eed <memmove>
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
801019a8:	c7 04 24 bd 97 10 80 	movl   $0x801097bd,(%esp)
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
801019d9:	c7 04 24 cc 97 10 80 	movl   $0x801097cc,(%esp)
801019e0:	e8 58 eb ff ff       	call   8010053d <panic>
  acquire(&icache.lock);
801019e5:	c7 04 24 e0 f8 10 80 	movl   $0x8010f8e0,(%esp)
801019ec:	e8 a2 41 00 00       	call   80105b93 <acquire>
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
80101a08:	e8 58 3e 00 00       	call   80105865 <wakeup>
  release(&icache.lock);
80101a0d:	c7 04 24 e0 f8 10 80 	movl   $0x8010f8e0,(%esp)
80101a14:	e8 15 42 00 00       	call   80105c2e <release>
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
80101a28:	e8 66 41 00 00       	call   80105b93 <acquire>
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
80101a66:	c7 04 24 d4 97 10 80 	movl   $0x801097d4,(%esp)
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
80101a8a:	e8 9f 41 00 00       	call   80105c2e <release>
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
80101ab5:	e8 d9 40 00 00       	call   80105b93 <acquire>
    ip->flags = 0;
80101aba:	8b 45 08             	mov    0x8(%ebp),%eax
80101abd:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
80101ac4:	8b 45 08             	mov    0x8(%ebp),%eax
80101ac7:	89 04 24             	mov    %eax,(%esp)
80101aca:	e8 96 3d 00 00       	call   80105865 <wakeup>
  }
  ip->ref--;
80101acf:	8b 45 08             	mov    0x8(%ebp),%eax
80101ad2:	8b 40 08             	mov    0x8(%eax),%eax
80101ad5:	8d 50 ff             	lea    -0x1(%eax),%edx
80101ad8:	8b 45 08             	mov    0x8(%ebp),%eax
80101adb:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101ade:	c7 04 24 e0 f8 10 80 	movl   $0x8010f8e0,(%esp)
80101ae5:	e8 44 41 00 00       	call   80105c2e <release>
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
80101be5:	e8 d3 1e 00 00       	call   80103abd <log_write>
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
80101bfa:	c7 04 24 de 97 10 80 	movl   $0x801097de,(%esp)
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
80101e92:	e8 56 40 00 00       	call   80105eed <memmove>
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
80101ff8:	e8 f0 3e 00 00       	call   80105eed <memmove>
    log_write(bp);
80101ffd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102000:	89 04 24             	mov    %eax,(%esp)
80102003:	e8 b5 1a 00 00       	call   80103abd <log_write>
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
8010207a:	e8 12 3f 00 00       	call   80105f91 <strncmp>
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
80102094:	c7 04 24 f1 97 10 80 	movl   $0x801097f1,(%esp)
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
801020d2:	c7 04 24 03 98 10 80 	movl   $0x80109803,(%esp)
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
801021b6:	c7 04 24 03 98 10 80 	movl   $0x80109803,(%esp)
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
801021fc:	e8 e8 3d 00 00       	call   80105fe9 <strncpy>
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
8010222e:	c7 04 24 10 98 10 80 	movl   $0x80109810,(%esp)
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
801022b5:	e8 33 3c 00 00       	call   80105eed <memmove>
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
801022d0:	e8 18 3c 00 00       	call   80105eed <memmove>
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
80102532:	c7 44 24 04 18 98 10 	movl   $0x80109818,0x4(%esp)
80102539:	80 
8010253a:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
80102541:	e8 2c 36 00 00       	call   80105b72 <initlock>
  picenable(IRQ_IDE);
80102546:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
8010254d:	e8 6f 1d 00 00       	call   801042c1 <picenable>
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
801025de:	c7 04 24 1c 98 10 80 	movl   $0x8010981c,(%esp)
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
80102704:	e8 8a 34 00 00       	call   80105b93 <acquire>
  if((b = idequeue) == 0){
80102709:	a1 54 c6 10 80       	mov    0x8010c654,%eax
8010270e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102711:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102715:	75 11                	jne    80102728 <ideintr+0x31>
    release(&idelock);
80102717:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
8010271e:	e8 0b 35 00 00       	call   80105c2e <release>
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
801027a8:	e8 81 34 00 00       	call   80105c2e <release>
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
801027c1:	c7 04 24 25 98 10 80 	movl   $0x80109825,(%esp)
801027c8:	e8 70 dd ff ff       	call   8010053d <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
801027cd:	8b 45 08             	mov    0x8(%ebp),%eax
801027d0:	8b 00                	mov    (%eax),%eax
801027d2:	83 e0 06             	and    $0x6,%eax
801027d5:	83 f8 02             	cmp    $0x2,%eax
801027d8:	75 0c                	jne    801027e6 <iderw+0x37>
    panic("iderw: nothing to do");
801027da:	c7 04 24 39 98 10 80 	movl   $0x80109839,(%esp)
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
801027f9:	c7 04 24 4e 98 10 80 	movl   $0x8010984e,(%esp)
80102800:	e8 38 dd ff ff       	call   8010053d <panic>

  acquire(&idelock);  //DOC: acquire-lock
80102805:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
8010280c:	e8 82 33 00 00       	call   80105b93 <acquire>

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
8010285e:	e8 cb 33 00 00       	call   80105c2e <release>
	sti();
80102863:	e8 7a fc ff ff       	call   801024e2 <sti>
	acquire(&idelock); 
80102868:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
8010286f:	e8 1f 33 00 00       	call   80105b93 <acquire>
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
8010288b:	e8 9e 33 00 00       	call   80105c2e <release>
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
8010291a:	c7 04 24 6c 98 10 80 	movl   $0x8010986c,(%esp)
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
801029e8:	c7 44 24 04 a0 98 10 	movl   $0x801098a0,0x4(%esp)
801029ef:	80 
801029f0:	c7 04 24 c0 08 11 80 	movl   $0x801108c0,(%esp)
801029f7:	e8 76 31 00 00       	call   80105b72 <initlock>
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
80102aa4:	c7 04 24 a5 98 10 80 	movl   $0x801098a5,(%esp)
80102aab:	e8 8d da ff ff       	call   8010053d <panic>

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80102ab0:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80102ab7:	00 
80102ab8:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102abf:	00 
80102ac0:	8b 45 08             	mov    0x8(%ebp),%eax
80102ac3:	89 04 24             	mov    %eax,(%esp)
80102ac6:	e8 4f 33 00 00       	call   80105e1a <memset>

  if(kmem.use_lock)
80102acb:	a1 f4 08 11 80       	mov    0x801108f4,%eax
80102ad0:	85 c0                	test   %eax,%eax
80102ad2:	74 0c                	je     80102ae0 <kfree+0x69>
    acquire(&kmem.lock);
80102ad4:	c7 04 24 c0 08 11 80 	movl   $0x801108c0,(%esp)
80102adb:	e8 b3 30 00 00       	call   80105b93 <acquire>
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
80102b09:	e8 20 31 00 00       	call   80105c2e <release>
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
80102b26:	e8 68 30 00 00       	call   80105b93 <acquire>
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
80102b53:	e8 d6 30 00 00       	call   80105c2e <release>
  return (char*)r;
80102b58:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102b5b:	c9                   	leave  
80102b5c:	c3                   	ret    

80102b5d <shmget>:


int 
shmget(int key, uint size, int shmflg)		//allocate shared mem segment
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
80102b72:	c7 04 24 ac 98 10 80 	movl   $0x801098ac,(%esp)
80102b79:	e8 23 d8 ff ff       	call   801003a1 <cprintf>
    return -1;
80102b7e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102b83:	e9 38 01 00 00       	jmp    80102cc0 <shmget+0x163>
  }
  
  switch(shmflg)				//switch on flag
80102b88:	8b 45 10             	mov    0x10(%ebp),%eax
80102b8b:	83 f8 14             	cmp    $0x14,%eax
80102b8e:	74 0e                	je     80102b9e <shmget+0x41>
80102b90:	83 f8 15             	cmp    $0x15,%eax
80102b93:	0f 84 ef 00 00 00    	je     80102c88 <shmget+0x12b>
80102b99:	e9 1f 01 00 00       	jmp    80102cbd <shmget+0x160>
  {
    case CREAT:					//creating a new segment
      if(shm.refs[key][1][64] == 0)		//check a segment with the key does not already exist
80102b9e:	8b 45 08             	mov    0x8(%ebp),%eax
80102ba1:	c1 e0 03             	shl    $0x3,%eax
80102ba4:	89 c2                	mov    %eax,%edx
80102ba6:	c1 e2 06             	shl    $0x6,%edx
80102ba9:	01 d0                	add    %edx,%eax
80102bab:	05 44 a7 11 80       	add    $0x8011a744,%eax
80102bb0:	8b 00                	mov    (%eax),%eax
80102bb2:	85 c0                	test   %eax,%eax
80102bb4:	0f 85 c5 00 00 00    	jne    80102c7f <shmget+0x122>
      {
	sz = PGROUNDUP(size);			//round the size up to a factor of PGSIZE
80102bba:	8b 45 0c             	mov    0xc(%ebp),%eax
80102bbd:	05 ff 0f 00 00       	add    $0xfff,%eax
80102bc2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80102bc7:	89 45 e8             	mov    %eax,-0x18(%ebp)
	numOfPages = sz/PGSIZE;
80102bca:	8b 45 e8             	mov    -0x18(%ebp),%eax
80102bcd:	c1 e8 0c             	shr    $0xc,%eax
80102bd0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(i=0;i<numOfPages;i++)
80102bd3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102bda:	eb 2d                	jmp    80102c09 <shmget+0xac>
	{
	  if((shm.seg[key][i] = kalloc()) == 0)	//allocate the physical pages and save their kernel addresses in the seg array
80102bdc:	e8 2f ff ff ff       	call   80102b10 <kalloc>
80102be1:	8b 55 08             	mov    0x8(%ebp),%edx
80102be4:	6b d2 64             	imul   $0x64,%edx,%edx
80102be7:	03 55 f4             	add    -0xc(%ebp),%edx
80102bea:	89 04 95 00 09 11 80 	mov    %eax,-0x7feef700(,%edx,4)
80102bf1:	8b 45 08             	mov    0x8(%ebp),%eax
80102bf4:	6b c0 64             	imul   $0x64,%eax,%eax
80102bf7:	03 45 f4             	add    -0xc(%ebp),%eax
80102bfa:	8b 04 85 00 09 11 80 	mov    -0x7feef700(,%eax,4),%eax
80102c01:	85 c0                	test   %eax,%eax
80102c03:	74 0e                	je     80102c13 <shmget+0xb6>
    case CREAT:					//creating a new segment
      if(shm.refs[key][1][64] == 0)		//check a segment with the key does not already exist
      {
	sz = PGROUNDUP(size);			//round the size up to a factor of PGSIZE
	numOfPages = sz/PGSIZE;
	for(i=0;i<numOfPages;i++)
80102c05:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102c09:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c0c:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
80102c0f:	7c cb                	jl     80102bdc <shmget+0x7f>
80102c11:	eb 01                	jmp    80102c14 <shmget+0xb7>
	{
	  if((shm.seg[key][i] = kalloc()) == 0)	//allocate the physical pages and save their kernel addresses in the seg array
	    break;
80102c13:	90                   	nop
	}
	if(i == numOfPages)			//make sure the requested number of pages was allocated
80102c14:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c17:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
80102c1a:	75 2d                	jne    80102c49 <shmget+0xec>
	{
	  ans = (int)shm.seg[key][0];		//return the kernel addres of the first mem page in the segment as shmid
80102c1c:	8b 45 08             	mov    0x8(%ebp),%eax
80102c1f:	69 c0 90 01 00 00    	imul   $0x190,%eax,%eax
80102c25:	05 00 09 11 80       	add    $0x80110900,%eax
80102c2a:	8b 00                	mov    (%eax),%eax
80102c2c:	89 45 ec             	mov    %eax,-0x14(%ebp)
	  shm.refs[key][1][64] = numOfPages;
80102c2f:	8b 45 08             	mov    0x8(%ebp),%eax
80102c32:	c1 e0 03             	shl    $0x3,%eax
80102c35:	89 c2                	mov    %eax,%edx
80102c37:	c1 e2 06             	shl    $0x6,%edx
80102c3a:	01 d0                	add    %edx,%eax
80102c3c:	8d 90 44 a7 11 80    	lea    -0x7fee58bc(%eax),%edx
80102c42:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102c45:	89 02                	mov    %eax,(%edx)
      }
      else
      {
	ans = -1;
      }
      break;
80102c47:	eb 74                	jmp    80102cbd <shmget+0x160>
	  ans = (int)shm.seg[key][0];		//return the kernel addres of the first mem page in the segment as shmid
	  shm.refs[key][1][64] = numOfPages;
	}
	else
	{
	  for(j=0;j<i;j++)
80102c49:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80102c50:	eb 1c                	jmp    80102c6e <shmget+0x111>
	    kfree(shm.seg[key][j]);		//if failed to allocate all of the requested pages, free te pages already allocated and return -1
80102c52:	8b 45 08             	mov    0x8(%ebp),%eax
80102c55:	6b c0 64             	imul   $0x64,%eax,%eax
80102c58:	03 45 f0             	add    -0x10(%ebp),%eax
80102c5b:	8b 04 85 00 09 11 80 	mov    -0x7feef700(,%eax,4),%eax
80102c62:	89 04 24             	mov    %eax,(%esp)
80102c65:	e8 0d fe ff ff       	call   80102a77 <kfree>
	  ans = (int)shm.seg[key][0];		//return the kernel addres of the first mem page in the segment as shmid
	  shm.refs[key][1][64] = numOfPages;
	}
	else
	{
	  for(j=0;j<i;j++)
80102c6a:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80102c6e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102c71:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80102c74:	7c dc                	jl     80102c52 <shmget+0xf5>
	    kfree(shm.seg[key][j]);		//if failed to allocate all of the requested pages, free te pages already allocated and return -1
	  ans = -1;
80102c76:	c7 45 ec ff ff ff ff 	movl   $0xffffffff,-0x14(%ebp)
      }
      else
      {
	ans = -1;
      }
      break;
80102c7d:	eb 3e                	jmp    80102cbd <shmget+0x160>
	  ans = -1;
	}
      }
      else
      {
	ans = -1;
80102c7f:	c7 45 ec ff ff ff ff 	movl   $0xffffffff,-0x14(%ebp)
      }
      break;
80102c86:	eb 35                	jmp    80102cbd <shmget+0x160>
    case GET:					//get a pre-allocated segment's shmid
      if(!shm.refs[key][1][64])			//make sure the segment was allocated, if not return -1
80102c88:	8b 45 08             	mov    0x8(%ebp),%eax
80102c8b:	c1 e0 03             	shl    $0x3,%eax
80102c8e:	89 c2                	mov    %eax,%edx
80102c90:	c1 e2 06             	shl    $0x6,%edx
80102c93:	01 d0                	add    %edx,%eax
80102c95:	05 44 a7 11 80       	add    $0x8011a744,%eax
80102c9a:	8b 00                	mov    (%eax),%eax
80102c9c:	85 c0                	test   %eax,%eax
80102c9e:	75 09                	jne    80102ca9 <shmget+0x14c>
	ans = -1;
80102ca0:	c7 45 ec ff ff ff ff 	movl   $0xffffffff,-0x14(%ebp)
      else
	ans = (int)shm.seg[key][0];		//return the kernel addres of the first mem page in the segment as shmid
      break;
80102ca7:	eb 13                	jmp    80102cbc <shmget+0x15f>
      break;
    case GET:					//get a pre-allocated segment's shmid
      if(!shm.refs[key][1][64])			//make sure the segment was allocated, if not return -1
	ans = -1;
      else
	ans = (int)shm.seg[key][0];		//return the kernel addres of the first mem page in the segment as shmid
80102ca9:	8b 45 08             	mov    0x8(%ebp),%eax
80102cac:	69 c0 90 01 00 00    	imul   $0x190,%eax,%eax
80102cb2:	05 00 09 11 80       	add    $0x80110900,%eax
80102cb7:	8b 00                	mov    (%eax),%eax
80102cb9:	89 45 ec             	mov    %eax,-0x14(%ebp)
      break;
80102cbc:	90                   	nop
  }
  return ans;
80102cbd:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
80102cc0:	c9                   	leave  
80102cc1:	c3                   	ret    

80102cc2 <shmdel>:

int 
shmdel(int shmid)				//de-allocate shared memory segment
{
80102cc2:	55                   	push   %ebp
80102cc3:	89 e5                	mov    %esp,%ebp
80102cc5:	83 ec 28             	sub    $0x28,%esp
  int key,ans = -1,numOfPages,i;
80102cc8:	c7 45 f0 ff ff ff ff 	movl   $0xffffffff,-0x10(%ebp)
  for(key = 0;key<numOfSegs;key++)		//go over all keys and look for a segment matching shmid
80102ccf:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102cd6:	e9 b0 00 00 00       	jmp    80102d8b <shmdel+0xc9>
  {
    if(shmid == (int)shm.seg[key][0])
80102cdb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102cde:	69 c0 90 01 00 00    	imul   $0x190,%eax,%eax
80102ce4:	05 00 09 11 80       	add    $0x80110900,%eax
80102ce9:	8b 00                	mov    (%eax),%eax
80102ceb:	3b 45 08             	cmp    0x8(%ebp),%eax
80102cee:	0f 85 93 00 00 00    	jne    80102d87 <shmdel+0xc5>
    {
      if(shm.refs[key][0][64]>0)		//make sure no references remain to the seg, if >0 return -1
80102cf4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102cf7:	c1 e0 03             	shl    $0x3,%eax
80102cfa:	89 c2                	mov    %eax,%edx
80102cfc:	c1 e2 06             	shl    $0x6,%edx
80102cff:	01 d0                	add    %edx,%eax
80102d01:	05 40 a6 11 80       	add    $0x8011a640,%eax
80102d06:	8b 00                	mov    (%eax),%eax
80102d08:	85 c0                	test   %eax,%eax
80102d0a:	0f 8f 87 00 00 00    	jg     80102d97 <shmdel+0xd5>
      {
	break;
      }
      else
      {
	numOfPages=shm.refs[key][1][64];
80102d10:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d13:	c1 e0 03             	shl    $0x3,%eax
80102d16:	89 c2                	mov    %eax,%edx
80102d18:	c1 e2 06             	shl    $0x6,%edx
80102d1b:	01 d0                	add    %edx,%eax
80102d1d:	05 44 a7 11 80       	add    $0x8011a744,%eax
80102d22:	8b 00                	mov    (%eax),%eax
80102d24:	89 45 e8             	mov    %eax,-0x18(%ebp)
	for(i=0;i<numOfPages;i++)
80102d27:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80102d2e:	eb 47                	jmp    80102d77 <shmdel+0xb5>
	{
	    kfree(shm.seg[key][i]);		//deallocate all pages of the segment
80102d30:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d33:	6b c0 64             	imul   $0x64,%eax,%eax
80102d36:	03 45 ec             	add    -0x14(%ebp),%eax
80102d39:	8b 04 85 00 09 11 80 	mov    -0x7feef700(,%eax,4),%eax
80102d40:	89 04 24             	mov    %eax,(%esp)
80102d43:	e8 2f fd ff ff       	call   80102a77 <kfree>
	    shm.refs[key][1][64]--;
80102d48:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d4b:	c1 e0 03             	shl    $0x3,%eax
80102d4e:	89 c2                	mov    %eax,%edx
80102d50:	c1 e2 06             	shl    $0x6,%edx
80102d53:	01 d0                	add    %edx,%eax
80102d55:	05 44 a7 11 80       	add    $0x8011a744,%eax
80102d5a:	8b 00                	mov    (%eax),%eax
80102d5c:	8d 50 ff             	lea    -0x1(%eax),%edx
80102d5f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d62:	c1 e0 03             	shl    $0x3,%eax
80102d65:	89 c1                	mov    %eax,%ecx
80102d67:	c1 e1 06             	shl    $0x6,%ecx
80102d6a:	01 c8                	add    %ecx,%eax
80102d6c:	05 44 a7 11 80       	add    $0x8011a744,%eax
80102d71:	89 10                	mov    %edx,(%eax)
	break;
      }
      else
      {
	numOfPages=shm.refs[key][1][64];
	for(i=0;i<numOfPages;i++)
80102d73:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
80102d77:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102d7a:	3b 45 e8             	cmp    -0x18(%ebp),%eax
80102d7d:	7c b1                	jl     80102d30 <shmdel+0x6e>
	{
	    kfree(shm.seg[key][i]);		//deallocate all pages of the segment
	    shm.refs[key][1][64]--;
	}
      }
      ans = numOfPages;				//return number of pages deallocated
80102d7f:	8b 45 e8             	mov    -0x18(%ebp),%eax
80102d82:	89 45 f0             	mov    %eax,-0x10(%ebp)
      break;
80102d85:	eb 11                	jmp    80102d98 <shmdel+0xd6>

int 
shmdel(int shmid)				//de-allocate shared memory segment
{
  int key,ans = -1,numOfPages,i;
  for(key = 0;key<numOfSegs;key++)		//go over all keys and look for a segment matching shmid
80102d87:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102d8b:	83 7d f4 63          	cmpl   $0x63,-0xc(%ebp)
80102d8f:	0f 8e 46 ff ff ff    	jle    80102cdb <shmdel+0x19>
80102d95:	eb 01                	jmp    80102d98 <shmdel+0xd6>
  {
    if(shmid == (int)shm.seg[key][0])
    {
      if(shm.refs[key][0][64]>0)		//make sure no references remain to the seg, if >0 return -1
      {
	break;
80102d97:	90                   	nop
      }
      ans = numOfPages;				//return number of pages deallocated
      break;
    }
  }  
  return ans;
80102d98:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80102d9b:	c9                   	leave  
80102d9c:	c3                   	ret    

80102d9d <shmat>:

void *
shmat(int shmid, int shmflg)			//attach a shared mem segment to virtual mem
{
80102d9d:	55                   	push   %ebp
80102d9e:	89 e5                	mov    %esp,%ebp
80102da0:	83 ec 48             	sub    $0x48,%esp
  int i,key,forFlag=0;
80102da3:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  void* ans = (void*)-1;
80102daa:	c7 45 e8 ff ff ff ff 	movl   $0xffffffff,-0x18(%ebp)
  char* mem;
  uint a;

  acquire(&shm.lock);
80102db1:	c7 04 24 60 70 12 80 	movl   $0x80127060,(%esp)
80102db8:	e8 d6 2d 00 00       	call   80105b93 <acquire>
  for(key = 0;key<numOfSegs;key++)		//go over all segments and look for shmid
80102dbd:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80102dc4:	e9 ce 01 00 00       	jmp    80102f97 <shmat+0x1fa>
  {
    if(shmid == (int)shm.seg[key][0])
80102dc9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102dcc:	69 c0 90 01 00 00    	imul   $0x190,%eax,%eax
80102dd2:	05 00 09 11 80       	add    $0x80110900,%eax
80102dd7:	8b 00                	mov    (%eax),%eax
80102dd9:	3b 45 08             	cmp    0x8(%ebp),%eax
80102ddc:	0f 85 b1 01 00 00    	jne    80102f93 <shmat+0x1f6>
    {
      if(shm.refs[key][1][64]>0)		//make sure segment is allocated
80102de2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102de5:	c1 e0 03             	shl    $0x3,%eax
80102de8:	89 c2                	mov    %eax,%edx
80102dea:	c1 e2 06             	shl    $0x6,%edx
80102ded:	01 d0                	add    %edx,%eax
80102def:	05 44 a7 11 80       	add    $0x8011a744,%eax
80102df4:	8b 00                	mov    (%eax),%eax
80102df6:	85 c0                	test   %eax,%eax
80102df8:	0f 8e a5 01 00 00    	jle    80102fa3 <shmat+0x206>
      {
	a = PGROUNDUP(proc->sz);
80102dfe:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80102e04:	8b 00                	mov    (%eax),%eax
80102e06:	05 ff 0f 00 00       	add    $0xfff,%eax
80102e0b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80102e10:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ans = (void*)a;
80102e13:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102e16:	89 45 e8             	mov    %eax,-0x18(%ebp)
	if(a + PGSIZE >= KERNBASE)		//make sure the proc is not exceeding its virtual address space bounderies
80102e19:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102e1c:	05 00 10 00 00       	add    $0x1000,%eax
80102e21:	85 c0                	test   %eax,%eax
80102e23:	79 0c                	jns    80102e31 <shmat+0x94>
	{
	  ans = (void*)-1;
80102e25:	c7 45 e8 ff ff ff ff 	movl   $0xffffffff,-0x18(%ebp)
	  break;
80102e2c:	e9 73 01 00 00       	jmp    80102fa4 <shmat+0x207>
	}
	
	shm.refs[key][0][64]++;
80102e31:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102e34:	c1 e0 03             	shl    $0x3,%eax
80102e37:	89 c2                	mov    %eax,%edx
80102e39:	c1 e2 06             	shl    $0x6,%edx
80102e3c:	01 d0                	add    %edx,%eax
80102e3e:	05 40 a6 11 80       	add    $0x8011a640,%eax
80102e43:	8b 00                	mov    (%eax),%eax
80102e45:	8d 50 01             	lea    0x1(%eax),%edx
80102e48:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102e4b:	c1 e0 03             	shl    $0x3,%eax
80102e4e:	89 c1                	mov    %eax,%ecx
80102e50:	c1 e1 06             	shl    $0x6,%ecx
80102e53:	01 c8                	add    %ecx,%eax
80102e55:	05 40 a6 11 80       	add    $0x8011a640,%eax
80102e5a:	89 10                	mov    %edx,(%eax)
	shm.refs[key][0][proc->pid] = 1;	//set flag to indicate this proc attached to the seg
80102e5c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80102e62:	8b 50 10             	mov    0x10(%eax),%edx
80102e65:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102e68:	01 c0                	add    %eax,%eax
80102e6a:	89 c1                	mov    %eax,%ecx
80102e6c:	c1 e1 06             	shl    $0x6,%ecx
80102e6f:	01 c8                	add    %ecx,%eax
80102e71:	01 d0                	add    %edx,%eax
80102e73:	05 10 27 00 00       	add    $0x2710,%eax
80102e78:	c7 04 85 00 09 11 80 	movl   $0x1,-0x7feef700(,%eax,4)
80102e7f:	01 00 00 00 
	proc->has_shm++;			//increment counter to indicate amount of attached segments for the proc
80102e83:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80102e89:	8b 90 8c 00 00 00    	mov    0x8c(%eax),%edx
80102e8f:	83 c2 01             	add    $0x1,%edx
80102e92:	89 90 8c 00 00 00    	mov    %edx,0x8c(%eax)
	
	for(i = 0;i < shm.refs[key][1][64] && a < KERNBASE;i++,a += PGSIZE)	//go over all pages in segment and map them to virtual addresses
80102e98:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102e9f:	e9 af 00 00 00       	jmp    80102f53 <shmat+0x1b6>
	{
	    forFlag = 1;
80102ea4:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
	    mem = shm.seg[key][i];
80102eab:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102eae:	6b c0 64             	imul   $0x64,%eax,%eax
80102eb1:	03 45 f4             	add    -0xc(%ebp),%eax
80102eb4:	8b 04 85 00 09 11 80 	mov    -0x7feef700(,%eax,4),%eax
80102ebb:	89 45 e0             	mov    %eax,-0x20(%ebp)
	    switch(shmflg)
80102ebe:	8b 45 0c             	mov    0xc(%ebp),%eax
80102ec1:	83 f8 16             	cmp    $0x16,%eax
80102ec4:	74 07                	je     80102ecd <shmat+0x130>
80102ec6:	83 f8 17             	cmp    $0x17,%eax
80102ec9:	74 3c                	je     80102f07 <shmat+0x16a>
80102ecb:	eb 74                	jmp    80102f41 <shmat+0x1a4>
	    {
	      case SHM_RDONLY:
		mappages(proc->pgdir, (char*)a, PGSIZE, v2p(mem), PTE_U);	//map page as read-only
80102ecd:	8b 45 e0             	mov    -0x20(%ebp),%eax
80102ed0:	89 04 24             	mov    %eax,(%esp)
80102ed3:	e8 f0 fa ff ff       	call   801029c8 <v2p>
80102ed8:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80102edb:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80102ee2:	8b 52 04             	mov    0x4(%edx),%edx
80102ee5:	c7 44 24 10 04 00 00 	movl   $0x4,0x10(%esp)
80102eec:	00 
80102eed:	89 44 24 0c          	mov    %eax,0xc(%esp)
80102ef1:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80102ef8:	00 
80102ef9:	89 4c 24 04          	mov    %ecx,0x4(%esp)
80102efd:	89 14 24             	mov    %edx,(%esp)
80102f00:	e8 e0 5e 00 00       	call   80108de5 <mappages>
		break;
80102f05:	eb 41                	jmp    80102f48 <shmat+0x1ab>
	      case SHM_RDWR:
		mappages(proc->pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);	//map page as read & write
80102f07:	8b 45 e0             	mov    -0x20(%ebp),%eax
80102f0a:	89 04 24             	mov    %eax,(%esp)
80102f0d:	e8 b6 fa ff ff       	call   801029c8 <v2p>
80102f12:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80102f15:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80102f1c:	8b 52 04             	mov    0x4(%edx),%edx
80102f1f:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80102f26:	00 
80102f27:	89 44 24 0c          	mov    %eax,0xc(%esp)
80102f2b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80102f32:	00 
80102f33:	89 4c 24 04          	mov    %ecx,0x4(%esp)
80102f37:	89 14 24             	mov    %edx,(%esp)
80102f3a:	e8 a6 5e 00 00       	call   80108de5 <mappages>
		break;
80102f3f:	eb 07                	jmp    80102f48 <shmat+0x1ab>
	      default:
		forFlag = 0;
80102f41:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	
	shm.refs[key][0][64]++;
	shm.refs[key][0][proc->pid] = 1;	//set flag to indicate this proc attached to the seg
	proc->has_shm++;			//increment counter to indicate amount of attached segments for the proc
	
	for(i = 0;i < shm.refs[key][1][64] && a < KERNBASE;i++,a += PGSIZE)	//go over all pages in segment and map them to virtual addresses
80102f48:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102f4c:	81 45 e4 00 10 00 00 	addl   $0x1000,-0x1c(%ebp)
80102f53:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102f56:	c1 e0 03             	shl    $0x3,%eax
80102f59:	89 c2                	mov    %eax,%edx
80102f5b:	c1 e2 06             	shl    $0x6,%edx
80102f5e:	01 d0                	add    %edx,%eax
80102f60:	05 44 a7 11 80       	add    $0x8011a744,%eax
80102f65:	8b 00                	mov    (%eax),%eax
80102f67:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80102f6a:	7e 0b                	jle    80102f77 <shmat+0x1da>
80102f6c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102f6f:	85 c0                	test   %eax,%eax
80102f71:	0f 89 2d ff ff ff    	jns    80102ea4 <shmat+0x107>
		break;
	      default:
		forFlag = 0;
	    } 
	}
	if(forFlag)					//update proc size
80102f77:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80102f7b:	74 0d                	je     80102f8a <shmat+0x1ed>
	  proc->sz = a;
80102f7d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80102f83:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80102f86:	89 10                	mov    %edx,(%eax)
	else
	  ans = (void*)-1;
	break;
80102f88:	eb 1a                	jmp    80102fa4 <shmat+0x207>
	    } 
	}
	if(forFlag)					//update proc size
	  proc->sz = a;
	else
	  ans = (void*)-1;
80102f8a:	c7 45 e8 ff ff ff ff 	movl   $0xffffffff,-0x18(%ebp)
	break;
80102f91:	eb 11                	jmp    80102fa4 <shmat+0x207>
  void* ans = (void*)-1;
  char* mem;
  uint a;

  acquire(&shm.lock);
  for(key = 0;key<numOfSegs;key++)		//go over all segments and look for shmid
80102f93:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80102f97:	83 7d f0 63          	cmpl   $0x63,-0x10(%ebp)
80102f9b:	0f 8e 28 fe ff ff    	jle    80102dc9 <shmat+0x2c>
80102fa1:	eb 01                	jmp    80102fa4 <shmat+0x207>
	else
	  ans = (void*)-1;
	break;
      }
      else
      	break;
80102fa3:	90                   	nop
    }
  }
  release(&shm.lock);
80102fa4:	c7 04 24 60 70 12 80 	movl   $0x80127060,(%esp)
80102fab:	e8 7e 2c 00 00       	call   80105c2e <release>
  return ans;
80102fb0:	8b 45 e8             	mov    -0x18(%ebp),%eax
}
80102fb3:	c9                   	leave  
80102fb4:	c3                   	ret    

80102fb5 <shmdt>:

int 
shmdt(const void *shmaddr)			//detach shared memory from virtual addresses
{
80102fb5:	55                   	push   %ebp
80102fb6:	89 e5                	mov    %esp,%ebp
80102fb8:	83 ec 38             	sub    $0x38,%esp
  pte_t *pte;
  uint r, numOfPages;
  int key,found;
  pte = walkpgdir(proc->pgdir, (char*)shmaddr, 0); 	//get PTE that matches shmaddr
80102fbb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80102fc1:	8b 40 04             	mov    0x4(%eax),%eax
80102fc4:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80102fcb:	00 
80102fcc:	8b 55 08             	mov    0x8(%ebp),%edx
80102fcf:	89 54 24 04          	mov    %edx,0x4(%esp)
80102fd3:	89 04 24             	mov    %eax,(%esp)
80102fd6:	e8 74 5d 00 00       	call   80108d4f <walkpgdir>
80102fdb:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  r = (int)p2v(PTE_ADDR(*pte)) ;			//translate PTE to kernel address of page
80102fde:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102fe1:	8b 00                	mov    (%eax),%eax
80102fe3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80102fe8:	89 04 24             	mov    %eax,(%esp)
80102feb:	e8 e5 f9 ff ff       	call   801029d5 <p2v>
80102ff0:	89 45 e0             	mov    %eax,-0x20(%ebp)
  acquire(&shm.lock);
80102ff3:	c7 04 24 60 70 12 80 	movl   $0x80127060,(%esp)
80102ffa:	e8 94 2b 00 00       	call   80105b93 <acquire>
  for(found = 0,key = 0;key<numOfSegs;key++)	//go over segments and look for a match
80102fff:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80103006:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
8010300d:	e9 04 01 00 00       	jmp    80103116 <shmdt+0x161>
  {    
    if((int)shm.seg[key][0] == r)
80103012:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103015:	69 c0 90 01 00 00    	imul   $0x190,%eax,%eax
8010301b:	05 00 09 11 80       	add    $0x80110900,%eax
80103020:	8b 00                	mov    (%eax),%eax
80103022:	3b 45 e0             	cmp    -0x20(%ebp),%eax
80103025:	0f 85 e7 00 00 00    	jne    80103112 <shmdt+0x15d>
    {  
      if(shm.refs[key][1][64]>0)		//make sure segment is allocated
8010302b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010302e:	c1 e0 03             	shl    $0x3,%eax
80103031:	89 c2                	mov    %eax,%edx
80103033:	c1 e2 06             	shl    $0x6,%edx
80103036:	01 d0                	add    %edx,%eax
80103038:	05 44 a7 11 80       	add    $0x8011a744,%eax
8010303d:	8b 00                	mov    (%eax),%eax
8010303f:	85 c0                	test   %eax,%eax
80103041:	0f 8e b5 00 00 00    	jle    801030fc <shmdt+0x147>
      { 
	if(shm.refs[key][0][64] <= 0)		//make sure reference count is in order
80103047:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010304a:	c1 e0 03             	shl    $0x3,%eax
8010304d:	89 c2                	mov    %eax,%edx
8010304f:	c1 e2 06             	shl    $0x6,%edx
80103052:	01 d0                	add    %edx,%eax
80103054:	05 40 a6 11 80       	add    $0x8011a640,%eax
80103059:	8b 00                	mov    (%eax),%eax
8010305b:	85 c0                	test   %eax,%eax
8010305d:	7f 16                	jg     80103075 <shmdt+0xc0>
	{
	  cprintf("shmdt exception - trying to detach a segment with no references\n");
8010305f:	c7 04 24 e4 98 10 80 	movl   $0x801098e4,(%esp)
80103066:	e8 36 d3 ff ff       	call   801003a1 <cprintf>
	  return -1;
8010306b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103070:	e9 1f 01 00 00       	jmp    80103194 <shmdt+0x1df>
	}
	shm.refs[key][0][64]--;			//decrement reference count for seg
80103075:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103078:	c1 e0 03             	shl    $0x3,%eax
8010307b:	89 c2                	mov    %eax,%edx
8010307d:	c1 e2 06             	shl    $0x6,%edx
80103080:	01 d0                	add    %edx,%eax
80103082:	05 40 a6 11 80       	add    $0x8011a640,%eax
80103087:	8b 00                	mov    (%eax),%eax
80103089:	8d 50 ff             	lea    -0x1(%eax),%edx
8010308c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010308f:	c1 e0 03             	shl    $0x3,%eax
80103092:	89 c1                	mov    %eax,%ecx
80103094:	c1 e1 06             	shl    $0x6,%ecx
80103097:	01 c8                	add    %ecx,%eax
80103099:	05 40 a6 11 80       	add    $0x8011a640,%eax
8010309e:	89 10                	mov    %edx,(%eax)
	shm.refs[key][0][proc->pid] = 0;	//remove flag indicating the proc with pid attached the seg
801030a0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801030a6:	8b 50 10             	mov    0x10(%eax),%edx
801030a9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801030ac:	01 c0                	add    %eax,%eax
801030ae:	89 c1                	mov    %eax,%ecx
801030b0:	c1 e1 06             	shl    $0x6,%ecx
801030b3:	01 c8                	add    %ecx,%eax
801030b5:	01 d0                	add    %edx,%eax
801030b7:	05 10 27 00 00       	add    $0x2710,%eax
801030bc:	c7 04 85 00 09 11 80 	movl   $0x0,-0x7feef700(,%eax,4)
801030c3:	00 00 00 00 
	proc->has_shm--;			//decrement the counter of how many segs the proc has attached
801030c7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801030cd:	8b 90 8c 00 00 00    	mov    0x8c(%eax),%edx
801030d3:	83 ea 01             	sub    $0x1,%edx
801030d6:	89 90 8c 00 00 00    	mov    %edx,0x8c(%eax)
	numOfPages = shm.refs[key][1][64];
801030dc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801030df:	c1 e0 03             	shl    $0x3,%eax
801030e2:	89 c2                	mov    %eax,%edx
801030e4:	c1 e2 06             	shl    $0x6,%edx
801030e7:	01 d0                	add    %edx,%eax
801030e9:	05 44 a7 11 80       	add    $0x8011a744,%eax
801030ee:	8b 00                	mov    (%eax),%eax
801030f0:	89 45 f4             	mov    %eax,-0xc(%ebp)
	found = 1;
801030f3:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
	break;
801030fa:	eb 24                	jmp    80103120 <shmdt+0x16b>
      }
      else
      {
	cprintf("shmdt exception - trying to detach a segment with no pages\n");
801030fc:	c7 04 24 28 99 10 80 	movl   $0x80109928,(%esp)
80103103:	e8 99 d2 ff ff       	call   801003a1 <cprintf>
	return -1;
80103108:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010310d:	e9 82 00 00 00       	jmp    80103194 <shmdt+0x1df>
  uint r, numOfPages;
  int key,found;
  pte = walkpgdir(proc->pgdir, (char*)shmaddr, 0); 	//get PTE that matches shmaddr
  r = (int)p2v(PTE_ADDR(*pte)) ;			//translate PTE to kernel address of page
  acquire(&shm.lock);
  for(found = 0,key = 0;key<numOfSegs;key++)	//go over segments and look for a match
80103112:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80103116:	83 7d f0 63          	cmpl   $0x63,-0x10(%ebp)
8010311a:	0f 8e f2 fe ff ff    	jle    80103012 <shmdt+0x5d>
	cprintf("shmdt exception - trying to detach a segment with no pages\n");
	return -1;
      }
    }
  }
  release(&shm.lock);
80103120:	c7 04 24 60 70 12 80 	movl   $0x80127060,(%esp)
80103127:	e8 02 2b 00 00       	call   80105c2e <release>
  
  if(!found)
8010312c:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103130:	75 07                	jne    80103139 <shmdt+0x184>
    return -1;
80103132:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103137:	eb 5b                	jmp    80103194 <shmdt+0x1df>

  void *shmaddr2 = (void*)shmaddr;
80103139:	8b 45 08             	mov    0x8(%ebp),%eax
8010313c:	89 45 e8             	mov    %eax,-0x18(%ebp)

  for(; shmaddr2  < shmaddr + numOfPages*PGSIZE; shmaddr2 += PGSIZE)	//go over proc's virtual memory and delete the PTEs holding the shared mem segment
8010313f:	eb 40                	jmp    80103181 <shmdt+0x1cc>
  {
    pte = walkpgdir(proc->pgdir, (char*)shmaddr2, 0);
80103141:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80103147:	8b 40 04             	mov    0x4(%eax),%eax
8010314a:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80103151:	00 
80103152:	8b 55 e8             	mov    -0x18(%ebp),%edx
80103155:	89 54 24 04          	mov    %edx,0x4(%esp)
80103159:	89 04 24             	mov    %eax,(%esp)
8010315c:	e8 ee 5b 00 00       	call   80108d4f <walkpgdir>
80103161:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(!pte)
80103164:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80103168:	75 07                	jne    80103171 <shmdt+0x1bc>
      shmaddr2 += (NPTENTRIES - 1) * PGSIZE;
8010316a:	81 45 e8 00 f0 3f 00 	addl   $0x3ff000,-0x18(%ebp)
    *pte = 0;
80103171:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80103174:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  if(!found)
    return -1;

  void *shmaddr2 = (void*)shmaddr;

  for(; shmaddr2  < shmaddr + numOfPages*PGSIZE; shmaddr2 += PGSIZE)	//go over proc's virtual memory and delete the PTEs holding the shared mem segment
8010317a:	81 45 e8 00 10 00 00 	addl   $0x1000,-0x18(%ebp)
80103181:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103184:	c1 e0 0c             	shl    $0xc,%eax
80103187:	03 45 08             	add    0x8(%ebp),%eax
8010318a:	3b 45 e8             	cmp    -0x18(%ebp),%eax
8010318d:	77 b2                	ja     80103141 <shmdt+0x18c>
    if(!pte)
      shmaddr2 += (NPTENTRIES - 1) * PGSIZE;
    *pte = 0;
  }

  return 0;
8010318f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103194:	c9                   	leave  
80103195:	c3                   	ret    

80103196 <deallocshm>:

void 
deallocshm(int pid)			//de-allocate any left over shared memory if proc exited without calling shmdt
{
80103196:	55                   	push   %ebp
80103197:	89 e5                	mov    %esp,%ebp
80103199:	83 ec 38             	sub    $0x38,%esp
  uint a = 0;
8010319c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  int key, pa, numOfPages;
  pte_t *pte;
  
  acquire(&shm.lock);
801031a3:	c7 04 24 60 70 12 80 	movl   $0x80127060,(%esp)
801031aa:	e8 e4 29 00 00       	call   80105b93 <acquire>
  for(key = 0;key<numOfSegs;key++)	//go over all segs and look for the proc's pid in metadata array to indicate which segs are attached to it
801031af:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
801031b6:	e9 74 01 00 00       	jmp    8010332f <deallocshm+0x199>
  {    
    if(shm.refs[key][0][proc->pid])
801031bb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801031c1:	8b 50 10             	mov    0x10(%eax),%edx
801031c4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801031c7:	01 c0                	add    %eax,%eax
801031c9:	89 c1                	mov    %eax,%ecx
801031cb:	c1 e1 06             	shl    $0x6,%ecx
801031ce:	01 c8                	add    %ecx,%eax
801031d0:	01 d0                	add    %edx,%eax
801031d2:	05 10 27 00 00       	add    $0x2710,%eax
801031d7:	8b 04 85 00 09 11 80 	mov    -0x7feef700(,%eax,4),%eax
801031de:	85 c0                	test   %eax,%eax
801031e0:	0f 84 45 01 00 00    	je     8010332b <deallocshm+0x195>
    {
      for(; a  < proc->sz; a += PGSIZE)
801031e6:	e9 2c 01 00 00       	jmp    80103317 <deallocshm+0x181>
      {
	pte = walkpgdir(proc->pgdir, (char*)a, 0);	//go over proc's virtual mem and find the PTE holding the seg address
801031eb:	8b 55 f4             	mov    -0xc(%ebp),%edx
801031ee:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801031f4:	8b 40 04             	mov    0x4(%eax),%eax
801031f7:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801031fe:	00 
801031ff:	89 54 24 04          	mov    %edx,0x4(%esp)
80103203:	89 04 24             	mov    %eax,(%esp)
80103206:	e8 44 5b 00 00       	call   80108d4f <walkpgdir>
8010320b:	89 45 e8             	mov    %eax,-0x18(%ebp)
	if(!pte)
8010320e:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80103212:	75 0c                	jne    80103220 <deallocshm+0x8a>
	  a += (NPTENTRIES - 1) * PGSIZE;
80103214:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
8010321b:	e9 f0 00 00 00       	jmp    80103310 <deallocshm+0x17a>
	else if((*pte & PTE_P) != 0)
80103220:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103223:	8b 00                	mov    (%eax),%eax
80103225:	83 e0 01             	and    $0x1,%eax
80103228:	84 c0                	test   %al,%al
8010322a:	0f 84 e0 00 00 00    	je     80103310 <deallocshm+0x17a>
	{
	  pa = (int)p2v(PTE_ADDR(*pte));
80103230:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103233:	8b 00                	mov    (%eax),%eax
80103235:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010323a:	89 04 24             	mov    %eax,(%esp)
8010323d:	e8 93 f7 ff ff       	call   801029d5 <p2v>
80103242:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	  if((int)shm.seg[key][0] == pa)
80103245:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103248:	69 c0 90 01 00 00    	imul   $0x190,%eax,%eax
8010324e:	05 00 09 11 80       	add    $0x80110900,%eax
80103253:	8b 00                	mov    (%eax),%eax
80103255:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
80103258:	0f 85 b2 00 00 00    	jne    80103310 <deallocshm+0x17a>
	  {
	    void *b = (void*)a;
8010325e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103261:	89 45 ec             	mov    %eax,-0x14(%ebp)
	    numOfPages = shm.refs[key][1][64];
80103264:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103267:	c1 e0 03             	shl    $0x3,%eax
8010326a:	89 c2                	mov    %eax,%edx
8010326c:	c1 e2 06             	shl    $0x6,%edx
8010326f:	01 d0                	add    %edx,%eax
80103271:	05 44 a7 11 80       	add    $0x8011a744,%eax
80103276:	8b 00                	mov    (%eax),%eax
80103278:	89 45 e0             	mov    %eax,-0x20(%ebp)
	    for(; b  < (void*)a + numOfPages*PGSIZE; b += PGSIZE)	//when found, deallocate the required number of pages from virtual mem
8010327b:	eb 40                	jmp    801032bd <deallocshm+0x127>
	    {
	      pte = walkpgdir(proc->pgdir, (char*)b, 0);
8010327d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80103283:	8b 40 04             	mov    0x4(%eax),%eax
80103286:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010328d:	00 
8010328e:	8b 55 ec             	mov    -0x14(%ebp),%edx
80103291:	89 54 24 04          	mov    %edx,0x4(%esp)
80103295:	89 04 24             	mov    %eax,(%esp)
80103298:	e8 b2 5a 00 00       	call   80108d4f <walkpgdir>
8010329d:	89 45 e8             	mov    %eax,-0x18(%ebp)
	      if(!pte)
801032a0:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801032a4:	75 07                	jne    801032ad <deallocshm+0x117>
		b += (NPTENTRIES - 1) * PGSIZE;
801032a6:	81 45 ec 00 f0 3f 00 	addl   $0x3ff000,-0x14(%ebp)
	      *pte = 0;
801032ad:	8b 45 e8             	mov    -0x18(%ebp),%eax
801032b0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	  pa = (int)p2v(PTE_ADDR(*pte));
	  if((int)shm.seg[key][0] == pa)
	  {
	    void *b = (void*)a;
	    numOfPages = shm.refs[key][1][64];
	    for(; b  < (void*)a + numOfPages*PGSIZE; b += PGSIZE)	//when found, deallocate the required number of pages from virtual mem
801032b6:	81 45 ec 00 10 00 00 	addl   $0x1000,-0x14(%ebp)
801032bd:	8b 45 e0             	mov    -0x20(%ebp),%eax
801032c0:	c1 e0 0c             	shl    $0xc,%eax
801032c3:	03 45 f4             	add    -0xc(%ebp),%eax
801032c6:	3b 45 ec             	cmp    -0x14(%ebp),%eax
801032c9:	77 b2                	ja     8010327d <deallocshm+0xe7>
	      pte = walkpgdir(proc->pgdir, (char*)b, 0);
	      if(!pte)
		b += (NPTENTRIES - 1) * PGSIZE;
	      *pte = 0;
	    }
	    if(shm.refs[key][0][64]>0)
801032cb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801032ce:	c1 e0 03             	shl    $0x3,%eax
801032d1:	89 c2                	mov    %eax,%edx
801032d3:	c1 e2 06             	shl    $0x6,%edx
801032d6:	01 d0                	add    %edx,%eax
801032d8:	05 40 a6 11 80       	add    $0x8011a640,%eax
801032dd:	8b 00                	mov    (%eax),%eax
801032df:	85 c0                	test   %eax,%eax
801032e1:	7e 47                	jle    8010332a <deallocshm+0x194>
	      shm.refs[key][0][64]--;					//decrement the seg ref count
801032e3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801032e6:	c1 e0 03             	shl    $0x3,%eax
801032e9:	89 c2                	mov    %eax,%edx
801032eb:	c1 e2 06             	shl    $0x6,%edx
801032ee:	01 d0                	add    %edx,%eax
801032f0:	05 40 a6 11 80       	add    $0x8011a640,%eax
801032f5:	8b 00                	mov    (%eax),%eax
801032f7:	8d 50 ff             	lea    -0x1(%eax),%edx
801032fa:	8b 45 f0             	mov    -0x10(%ebp),%eax
801032fd:	c1 e0 03             	shl    $0x3,%eax
80103300:	89 c1                	mov    %eax,%ecx
80103302:	c1 e1 06             	shl    $0x6,%ecx
80103305:	01 c8                	add    %ecx,%eax
80103307:	05 40 a6 11 80       	add    $0x8011a640,%eax
8010330c:	89 10                	mov    %edx,(%eax)
	    break;
8010330e:	eb 1a                	jmp    8010332a <deallocshm+0x194>
  acquire(&shm.lock);
  for(key = 0;key<numOfSegs;key++)	//go over all segs and look for the proc's pid in metadata array to indicate which segs are attached to it
  {    
    if(shm.refs[key][0][proc->pid])
    {
      for(; a  < proc->sz; a += PGSIZE)
80103310:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80103317:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010331d:	8b 00                	mov    (%eax),%eax
8010331f:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103322:	0f 87 c3 fe ff ff    	ja     801031eb <deallocshm+0x55>
80103328:	eb 01                	jmp    8010332b <deallocshm+0x195>
		b += (NPTENTRIES - 1) * PGSIZE;
	      *pte = 0;
	    }
	    if(shm.refs[key][0][64]>0)
	      shm.refs[key][0][64]--;					//decrement the seg ref count
	    break;
8010332a:	90                   	nop
  uint a = 0;
  int key, pa, numOfPages;
  pte_t *pte;
  
  acquire(&shm.lock);
  for(key = 0;key<numOfSegs;key++)	//go over all segs and look for the proc's pid in metadata array to indicate which segs are attached to it
8010332b:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
8010332f:	83 7d f0 63          	cmpl   $0x63,-0x10(%ebp)
80103333:	0f 8e 82 fe ff ff    	jle    801031bb <deallocshm+0x25>
	  }
	}
      }
    }
  }
  release(&shm.lock);
80103339:	c7 04 24 60 70 12 80 	movl   $0x80127060,(%esp)
80103340:	e8 e9 28 00 00       	call   80105c2e <release>
}
80103345:	c9                   	leave  
80103346:	c3                   	ret    
	...

80103348 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80103348:	55                   	push   %ebp
80103349:	89 e5                	mov    %esp,%ebp
8010334b:	53                   	push   %ebx
8010334c:	83 ec 14             	sub    $0x14,%esp
8010334f:	8b 45 08             	mov    0x8(%ebp),%eax
80103352:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80103356:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
8010335a:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
8010335e:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80103362:	ec                   	in     (%dx),%al
80103363:	89 c3                	mov    %eax,%ebx
80103365:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80103368:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
8010336c:	83 c4 14             	add    $0x14,%esp
8010336f:	5b                   	pop    %ebx
80103370:	5d                   	pop    %ebp
80103371:	c3                   	ret    

80103372 <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
80103372:	55                   	push   %ebp
80103373:	89 e5                	mov    %esp,%ebp
80103375:	83 ec 14             	sub    $0x14,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
80103378:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
8010337f:	e8 c4 ff ff ff       	call   80103348 <inb>
80103384:	0f b6 c0             	movzbl %al,%eax
80103387:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
8010338a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010338d:	83 e0 01             	and    $0x1,%eax
80103390:	85 c0                	test   %eax,%eax
80103392:	75 0a                	jne    8010339e <kbdgetc+0x2c>
    return -1;
80103394:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103399:	e9 23 01 00 00       	jmp    801034c1 <kbdgetc+0x14f>
  data = inb(KBDATAP);
8010339e:	c7 04 24 60 00 00 00 	movl   $0x60,(%esp)
801033a5:	e8 9e ff ff ff       	call   80103348 <inb>
801033aa:	0f b6 c0             	movzbl %al,%eax
801033ad:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
801033b0:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
801033b7:	75 17                	jne    801033d0 <kbdgetc+0x5e>
    shift |= E0ESC;
801033b9:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
801033be:	83 c8 40             	or     $0x40,%eax
801033c1:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
    return 0;
801033c6:	b8 00 00 00 00       	mov    $0x0,%eax
801033cb:	e9 f1 00 00 00       	jmp    801034c1 <kbdgetc+0x14f>
  } else if(data & 0x80){
801033d0:	8b 45 fc             	mov    -0x4(%ebp),%eax
801033d3:	25 80 00 00 00       	and    $0x80,%eax
801033d8:	85 c0                	test   %eax,%eax
801033da:	74 45                	je     80103421 <kbdgetc+0xaf>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
801033dc:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
801033e1:	83 e0 40             	and    $0x40,%eax
801033e4:	85 c0                	test   %eax,%eax
801033e6:	75 08                	jne    801033f0 <kbdgetc+0x7e>
801033e8:	8b 45 fc             	mov    -0x4(%ebp),%eax
801033eb:	83 e0 7f             	and    $0x7f,%eax
801033ee:	eb 03                	jmp    801033f3 <kbdgetc+0x81>
801033f0:	8b 45 fc             	mov    -0x4(%ebp),%eax
801033f3:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
801033f6:	8b 45 fc             	mov    -0x4(%ebp),%eax
801033f9:	05 20 a0 10 80       	add    $0x8010a020,%eax
801033fe:	0f b6 00             	movzbl (%eax),%eax
80103401:	83 c8 40             	or     $0x40,%eax
80103404:	0f b6 c0             	movzbl %al,%eax
80103407:	f7 d0                	not    %eax
80103409:	89 c2                	mov    %eax,%edx
8010340b:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103410:	21 d0                	and    %edx,%eax
80103412:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
    return 0;
80103417:	b8 00 00 00 00       	mov    $0x0,%eax
8010341c:	e9 a0 00 00 00       	jmp    801034c1 <kbdgetc+0x14f>
  } else if(shift & E0ESC){
80103421:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103426:	83 e0 40             	and    $0x40,%eax
80103429:	85 c0                	test   %eax,%eax
8010342b:	74 14                	je     80103441 <kbdgetc+0xcf>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
8010342d:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
80103434:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103439:	83 e0 bf             	and    $0xffffffbf,%eax
8010343c:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
  }

  shift |= shiftcode[data];
80103441:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103444:	05 20 a0 10 80       	add    $0x8010a020,%eax
80103449:	0f b6 00             	movzbl (%eax),%eax
8010344c:	0f b6 d0             	movzbl %al,%edx
8010344f:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103454:	09 d0                	or     %edx,%eax
80103456:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
  shift ^= togglecode[data];
8010345b:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010345e:	05 20 a1 10 80       	add    $0x8010a120,%eax
80103463:	0f b6 00             	movzbl (%eax),%eax
80103466:	0f b6 d0             	movzbl %al,%edx
80103469:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
8010346e:	31 d0                	xor    %edx,%eax
80103470:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
  c = charcode[shift & (CTL | SHIFT)][data];
80103475:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
8010347a:	83 e0 03             	and    $0x3,%eax
8010347d:	8b 04 85 20 a5 10 80 	mov    -0x7fef5ae0(,%eax,4),%eax
80103484:	03 45 fc             	add    -0x4(%ebp),%eax
80103487:	0f b6 00             	movzbl (%eax),%eax
8010348a:	0f b6 c0             	movzbl %al,%eax
8010348d:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
80103490:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103495:	83 e0 08             	and    $0x8,%eax
80103498:	85 c0                	test   %eax,%eax
8010349a:	74 22                	je     801034be <kbdgetc+0x14c>
    if('a' <= c && c <= 'z')
8010349c:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
801034a0:	76 0c                	jbe    801034ae <kbdgetc+0x13c>
801034a2:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
801034a6:	77 06                	ja     801034ae <kbdgetc+0x13c>
      c += 'A' - 'a';
801034a8:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
801034ac:	eb 10                	jmp    801034be <kbdgetc+0x14c>
    else if('A' <= c && c <= 'Z')
801034ae:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
801034b2:	76 0a                	jbe    801034be <kbdgetc+0x14c>
801034b4:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
801034b8:	77 04                	ja     801034be <kbdgetc+0x14c>
      c += 'a' - 'A';
801034ba:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
801034be:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
801034c1:	c9                   	leave  
801034c2:	c3                   	ret    

801034c3 <kbdintr>:

void
kbdintr(void)
{
801034c3:	55                   	push   %ebp
801034c4:	89 e5                	mov    %esp,%ebp
801034c6:	83 ec 18             	sub    $0x18,%esp
  consoleintr(kbdgetc);
801034c9:	c7 04 24 72 33 10 80 	movl   $0x80103372,(%esp)
801034d0:	e8 d8 d2 ff ff       	call   801007ad <consoleintr>
}
801034d5:	c9                   	leave  
801034d6:	c3                   	ret    
	...

801034d8 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801034d8:	55                   	push   %ebp
801034d9:	89 e5                	mov    %esp,%ebp
801034db:	83 ec 08             	sub    $0x8,%esp
801034de:	8b 55 08             	mov    0x8(%ebp),%edx
801034e1:	8b 45 0c             	mov    0xc(%ebp),%eax
801034e4:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801034e8:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801034eb:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801034ef:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801034f3:	ee                   	out    %al,(%dx)
}
801034f4:	c9                   	leave  
801034f5:	c3                   	ret    

801034f6 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
801034f6:	55                   	push   %ebp
801034f7:	89 e5                	mov    %esp,%ebp
801034f9:	53                   	push   %ebx
801034fa:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801034fd:	9c                   	pushf  
801034fe:	5b                   	pop    %ebx
801034ff:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80103502:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103505:	83 c4 10             	add    $0x10,%esp
80103508:	5b                   	pop    %ebx
80103509:	5d                   	pop    %ebp
8010350a:	c3                   	ret    

8010350b <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
8010350b:	55                   	push   %ebp
8010350c:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
8010350e:	a1 94 70 12 80       	mov    0x80127094,%eax
80103513:	8b 55 08             	mov    0x8(%ebp),%edx
80103516:	c1 e2 02             	shl    $0x2,%edx
80103519:	01 c2                	add    %eax,%edx
8010351b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010351e:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
80103520:	a1 94 70 12 80       	mov    0x80127094,%eax
80103525:	83 c0 20             	add    $0x20,%eax
80103528:	8b 00                	mov    (%eax),%eax
}
8010352a:	5d                   	pop    %ebp
8010352b:	c3                   	ret    

8010352c <lapicinit>:
//PAGEBREAK!

void
lapicinit(int c)
{
8010352c:	55                   	push   %ebp
8010352d:	89 e5                	mov    %esp,%ebp
8010352f:	83 ec 08             	sub    $0x8,%esp
  if(!lapic) 
80103532:	a1 94 70 12 80       	mov    0x80127094,%eax
80103537:	85 c0                	test   %eax,%eax
80103539:	0f 84 47 01 00 00    	je     80103686 <lapicinit+0x15a>
    return;

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
8010353f:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
80103546:	00 
80103547:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
8010354e:	e8 b8 ff ff ff       	call   8010350b <lapicw>

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.  
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
80103553:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
8010355a:	00 
8010355b:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
80103562:	e8 a4 ff ff ff       	call   8010350b <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
80103567:	c7 44 24 04 20 00 02 	movl   $0x20020,0x4(%esp)
8010356e:	00 
8010356f:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103576:	e8 90 ff ff ff       	call   8010350b <lapicw>
  lapicw(TICR, 10000000); 
8010357b:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
80103582:	00 
80103583:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
8010358a:	e8 7c ff ff ff       	call   8010350b <lapicw>

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
8010358f:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103596:	00 
80103597:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
8010359e:	e8 68 ff ff ff       	call   8010350b <lapicw>
  lapicw(LINT1, MASKED);
801035a3:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
801035aa:	00 
801035ab:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
801035b2:	e8 54 ff ff ff       	call   8010350b <lapicw>

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
801035b7:	a1 94 70 12 80       	mov    0x80127094,%eax
801035bc:	83 c0 30             	add    $0x30,%eax
801035bf:	8b 00                	mov    (%eax),%eax
801035c1:	c1 e8 10             	shr    $0x10,%eax
801035c4:	25 ff 00 00 00       	and    $0xff,%eax
801035c9:	83 f8 03             	cmp    $0x3,%eax
801035cc:	76 14                	jbe    801035e2 <lapicinit+0xb6>
    lapicw(PCINT, MASKED);
801035ce:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
801035d5:	00 
801035d6:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
801035dd:	e8 29 ff ff ff       	call   8010350b <lapicw>

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
801035e2:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
801035e9:	00 
801035ea:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
801035f1:	e8 15 ff ff ff       	call   8010350b <lapicw>

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
801035f6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801035fd:	00 
801035fe:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103605:	e8 01 ff ff ff       	call   8010350b <lapicw>
  lapicw(ESR, 0);
8010360a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103611:	00 
80103612:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103619:	e8 ed fe ff ff       	call   8010350b <lapicw>

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
8010361e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103625:	00 
80103626:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
8010362d:	e8 d9 fe ff ff       	call   8010350b <lapicw>

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
80103632:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103639:	00 
8010363a:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80103641:	e8 c5 fe ff ff       	call   8010350b <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
80103646:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
8010364d:	00 
8010364e:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103655:	e8 b1 fe ff ff       	call   8010350b <lapicw>
  while(lapic[ICRLO] & DELIVS)
8010365a:	90                   	nop
8010365b:	a1 94 70 12 80       	mov    0x80127094,%eax
80103660:	05 00 03 00 00       	add    $0x300,%eax
80103665:	8b 00                	mov    (%eax),%eax
80103667:	25 00 10 00 00       	and    $0x1000,%eax
8010366c:	85 c0                	test   %eax,%eax
8010366e:	75 eb                	jne    8010365b <lapicinit+0x12f>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
80103670:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103677:	00 
80103678:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010367f:	e8 87 fe ff ff       	call   8010350b <lapicw>
80103684:	eb 01                	jmp    80103687 <lapicinit+0x15b>

void
lapicinit(int c)
{
  if(!lapic) 
    return;
80103686:	90                   	nop
  while(lapic[ICRLO] & DELIVS)
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
}
80103687:	c9                   	leave  
80103688:	c3                   	ret    

80103689 <cpunum>:

int
cpunum(void)
{
80103689:	55                   	push   %ebp
8010368a:	89 e5                	mov    %esp,%ebp
8010368c:	83 ec 18             	sub    $0x18,%esp
  // Cannot call cpu when interrupts are enabled:
  // result not guaranteed to last long enough to be used!
  // Would prefer to panic but even printing is chancy here:
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
8010368f:	e8 62 fe ff ff       	call   801034f6 <readeflags>
80103694:	25 00 02 00 00       	and    $0x200,%eax
80103699:	85 c0                	test   %eax,%eax
8010369b:	74 29                	je     801036c6 <cpunum+0x3d>
    static int n;
    if(n++ == 0)
8010369d:	a1 60 c6 10 80       	mov    0x8010c660,%eax
801036a2:	85 c0                	test   %eax,%eax
801036a4:	0f 94 c2             	sete   %dl
801036a7:	83 c0 01             	add    $0x1,%eax
801036aa:	a3 60 c6 10 80       	mov    %eax,0x8010c660
801036af:	84 d2                	test   %dl,%dl
801036b1:	74 13                	je     801036c6 <cpunum+0x3d>
      cprintf("cpu called from %x with interrupts enabled\n",
801036b3:	8b 45 04             	mov    0x4(%ebp),%eax
801036b6:	89 44 24 04          	mov    %eax,0x4(%esp)
801036ba:	c7 04 24 64 99 10 80 	movl   $0x80109964,(%esp)
801036c1:	e8 db cc ff ff       	call   801003a1 <cprintf>
        __builtin_return_address(0));
  }

  if(lapic)
801036c6:	a1 94 70 12 80       	mov    0x80127094,%eax
801036cb:	85 c0                	test   %eax,%eax
801036cd:	74 0f                	je     801036de <cpunum+0x55>
    return lapic[ID]>>24;
801036cf:	a1 94 70 12 80       	mov    0x80127094,%eax
801036d4:	83 c0 20             	add    $0x20,%eax
801036d7:	8b 00                	mov    (%eax),%eax
801036d9:	c1 e8 18             	shr    $0x18,%eax
801036dc:	eb 05                	jmp    801036e3 <cpunum+0x5a>
  return 0;
801036de:	b8 00 00 00 00       	mov    $0x0,%eax
}
801036e3:	c9                   	leave  
801036e4:	c3                   	ret    

801036e5 <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
801036e5:	55                   	push   %ebp
801036e6:	89 e5                	mov    %esp,%ebp
801036e8:	83 ec 08             	sub    $0x8,%esp
  if(lapic)
801036eb:	a1 94 70 12 80       	mov    0x80127094,%eax
801036f0:	85 c0                	test   %eax,%eax
801036f2:	74 14                	je     80103708 <lapiceoi+0x23>
    lapicw(EOI, 0);
801036f4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801036fb:	00 
801036fc:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80103703:	e8 03 fe ff ff       	call   8010350b <lapicw>
}
80103708:	c9                   	leave  
80103709:	c3                   	ret    

8010370a <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
8010370a:	55                   	push   %ebp
8010370b:	89 e5                	mov    %esp,%ebp
}
8010370d:	5d                   	pop    %ebp
8010370e:	c3                   	ret    

8010370f <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
8010370f:	55                   	push   %ebp
80103710:	89 e5                	mov    %esp,%ebp
80103712:	83 ec 1c             	sub    $0x1c,%esp
80103715:	8b 45 08             	mov    0x8(%ebp),%eax
80103718:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;
  
  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
8010371b:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80103722:	00 
80103723:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
8010372a:	e8 a9 fd ff ff       	call   801034d8 <outb>
  outb(IO_RTC+1, 0x0A);
8010372f:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80103736:	00 
80103737:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
8010373e:	e8 95 fd ff ff       	call   801034d8 <outb>
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
80103743:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
8010374a:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010374d:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
80103752:	8b 45 f8             	mov    -0x8(%ebp),%eax
80103755:	8d 50 02             	lea    0x2(%eax),%edx
80103758:	8b 45 0c             	mov    0xc(%ebp),%eax
8010375b:	c1 e8 04             	shr    $0x4,%eax
8010375e:	66 89 02             	mov    %ax,(%edx)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
80103761:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80103765:	c1 e0 18             	shl    $0x18,%eax
80103768:	89 44 24 04          	mov    %eax,0x4(%esp)
8010376c:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80103773:	e8 93 fd ff ff       	call   8010350b <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
80103778:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
8010377f:	00 
80103780:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103787:	e8 7f fd ff ff       	call   8010350b <lapicw>
  microdelay(200);
8010378c:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103793:	e8 72 ff ff ff       	call   8010370a <microdelay>
  lapicw(ICRLO, INIT | LEVEL);
80103798:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
8010379f:	00 
801037a0:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801037a7:	e8 5f fd ff ff       	call   8010350b <lapicw>
  microdelay(100);    // should be 10ms, but too slow in Bochs!
801037ac:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
801037b3:	e8 52 ff ff ff       	call   8010370a <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
801037b8:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801037bf:	eb 40                	jmp    80103801 <lapicstartap+0xf2>
    lapicw(ICRHI, apicid<<24);
801037c1:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
801037c5:	c1 e0 18             	shl    $0x18,%eax
801037c8:	89 44 24 04          	mov    %eax,0x4(%esp)
801037cc:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
801037d3:	e8 33 fd ff ff       	call   8010350b <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
801037d8:	8b 45 0c             	mov    0xc(%ebp),%eax
801037db:	c1 e8 0c             	shr    $0xc,%eax
801037de:	80 cc 06             	or     $0x6,%ah
801037e1:	89 44 24 04          	mov    %eax,0x4(%esp)
801037e5:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801037ec:	e8 1a fd ff ff       	call   8010350b <lapicw>
    microdelay(200);
801037f1:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
801037f8:	e8 0d ff ff ff       	call   8010370a <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
801037fd:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103801:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
80103805:	7e ba                	jle    801037c1 <lapicstartap+0xb2>
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
80103807:	c9                   	leave  
80103808:	c3                   	ret    
80103809:	00 00                	add    %al,(%eax)
	...

8010380c <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
8010380c:	55                   	push   %ebp
8010380d:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
8010380f:	fb                   	sti    
}
80103810:	5d                   	pop    %ebp
80103811:	c3                   	ret    

80103812 <initlog>:

static void recover_from_log(void);

void
initlog(void)
{
80103812:	55                   	push   %ebp
80103813:	89 e5                	mov    %esp,%ebp
80103815:	83 ec 28             	sub    $0x28,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
80103818:	c7 44 24 04 90 99 10 	movl   $0x80109990,0x4(%esp)
8010381f:	80 
80103820:	c7 04 24 a0 70 12 80 	movl   $0x801270a0,(%esp)
80103827:	e8 46 23 00 00       	call   80105b72 <initlock>
  readsb(ROOTDEV, &sb);
8010382c:	8d 45 e8             	lea    -0x18(%ebp),%eax
8010382f:	89 44 24 04          	mov    %eax,0x4(%esp)
80103833:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010383a:	e8 ad da ff ff       	call   801012ec <readsb>
  log.start = sb.size - sb.nlog;
8010383f:	8b 55 e8             	mov    -0x18(%ebp),%edx
80103842:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103845:	89 d1                	mov    %edx,%ecx
80103847:	29 c1                	sub    %eax,%ecx
80103849:	89 c8                	mov    %ecx,%eax
8010384b:	a3 d4 70 12 80       	mov    %eax,0x801270d4
  log.size = sb.nlog;
80103850:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103853:	a3 d8 70 12 80       	mov    %eax,0x801270d8
  log.dev = ROOTDEV;
80103858:	c7 05 e0 70 12 80 01 	movl   $0x1,0x801270e0
8010385f:	00 00 00 
  recover_from_log();
80103862:	e8 97 01 00 00       	call   801039fe <recover_from_log>
}
80103867:	c9                   	leave  
80103868:	c3                   	ret    

80103869 <install_trans>:

// Copy committed blocks from log to their home location
static void 
install_trans(void)
{
80103869:	55                   	push   %ebp
8010386a:	89 e5                	mov    %esp,%ebp
8010386c:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
8010386f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103876:	e9 89 00 00 00       	jmp    80103904 <install_trans+0x9b>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
8010387b:	a1 d4 70 12 80       	mov    0x801270d4,%eax
80103880:	03 45 f4             	add    -0xc(%ebp),%eax
80103883:	83 c0 01             	add    $0x1,%eax
80103886:	89 c2                	mov    %eax,%edx
80103888:	a1 e0 70 12 80       	mov    0x801270e0,%eax
8010388d:	89 54 24 04          	mov    %edx,0x4(%esp)
80103891:	89 04 24             	mov    %eax,(%esp)
80103894:	e8 0d c9 ff ff       	call   801001a6 <bread>
80103899:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.sector[tail]); // read dst
8010389c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010389f:	83 c0 10             	add    $0x10,%eax
801038a2:	8b 04 85 a8 70 12 80 	mov    -0x7fed8f58(,%eax,4),%eax
801038a9:	89 c2                	mov    %eax,%edx
801038ab:	a1 e0 70 12 80       	mov    0x801270e0,%eax
801038b0:	89 54 24 04          	mov    %edx,0x4(%esp)
801038b4:	89 04 24             	mov    %eax,(%esp)
801038b7:	e8 ea c8 ff ff       	call   801001a6 <bread>
801038bc:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
801038bf:	8b 45 f0             	mov    -0x10(%ebp),%eax
801038c2:	8d 50 18             	lea    0x18(%eax),%edx
801038c5:	8b 45 ec             	mov    -0x14(%ebp),%eax
801038c8:	83 c0 18             	add    $0x18,%eax
801038cb:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
801038d2:	00 
801038d3:	89 54 24 04          	mov    %edx,0x4(%esp)
801038d7:	89 04 24             	mov    %eax,(%esp)
801038da:	e8 0e 26 00 00       	call   80105eed <memmove>
    bwrite(dbuf);  // write dst to disk
801038df:	8b 45 ec             	mov    -0x14(%ebp),%eax
801038e2:	89 04 24             	mov    %eax,(%esp)
801038e5:	e8 f3 c8 ff ff       	call   801001dd <bwrite>
    brelse(lbuf); 
801038ea:	8b 45 f0             	mov    -0x10(%ebp),%eax
801038ed:	89 04 24             	mov    %eax,(%esp)
801038f0:	e8 22 c9 ff ff       	call   80100217 <brelse>
    brelse(dbuf);
801038f5:	8b 45 ec             	mov    -0x14(%ebp),%eax
801038f8:	89 04 24             	mov    %eax,(%esp)
801038fb:	e8 17 c9 ff ff       	call   80100217 <brelse>
static void 
install_trans(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103900:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103904:	a1 e4 70 12 80       	mov    0x801270e4,%eax
80103909:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010390c:	0f 8f 69 ff ff ff    	jg     8010387b <install_trans+0x12>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    bwrite(dbuf);  // write dst to disk
    brelse(lbuf); 
    brelse(dbuf);
  }
}
80103912:	c9                   	leave  
80103913:	c3                   	ret    

80103914 <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
80103914:	55                   	push   %ebp
80103915:	89 e5                	mov    %esp,%ebp
80103917:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
8010391a:	a1 d4 70 12 80       	mov    0x801270d4,%eax
8010391f:	89 c2                	mov    %eax,%edx
80103921:	a1 e0 70 12 80       	mov    0x801270e0,%eax
80103926:	89 54 24 04          	mov    %edx,0x4(%esp)
8010392a:	89 04 24             	mov    %eax,(%esp)
8010392d:	e8 74 c8 ff ff       	call   801001a6 <bread>
80103932:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
80103935:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103938:	83 c0 18             	add    $0x18,%eax
8010393b:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
8010393e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103941:	8b 00                	mov    (%eax),%eax
80103943:	a3 e4 70 12 80       	mov    %eax,0x801270e4
  for (i = 0; i < log.lh.n; i++) {
80103948:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010394f:	eb 1b                	jmp    8010396c <read_head+0x58>
    log.lh.sector[i] = lh->sector[i];
80103951:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103954:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103957:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
8010395b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010395e:	83 c2 10             	add    $0x10,%edx
80103961:	89 04 95 a8 70 12 80 	mov    %eax,-0x7fed8f58(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
80103968:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010396c:	a1 e4 70 12 80       	mov    0x801270e4,%eax
80103971:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103974:	7f db                	jg     80103951 <read_head+0x3d>
    log.lh.sector[i] = lh->sector[i];
  }
  brelse(buf);
80103976:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103979:	89 04 24             	mov    %eax,(%esp)
8010397c:	e8 96 c8 ff ff       	call   80100217 <brelse>
}
80103981:	c9                   	leave  
80103982:	c3                   	ret    

80103983 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
80103983:	55                   	push   %ebp
80103984:	89 e5                	mov    %esp,%ebp
80103986:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80103989:	a1 d4 70 12 80       	mov    0x801270d4,%eax
8010398e:	89 c2                	mov    %eax,%edx
80103990:	a1 e0 70 12 80       	mov    0x801270e0,%eax
80103995:	89 54 24 04          	mov    %edx,0x4(%esp)
80103999:	89 04 24             	mov    %eax,(%esp)
8010399c:	e8 05 c8 ff ff       	call   801001a6 <bread>
801039a1:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
801039a4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801039a7:	83 c0 18             	add    $0x18,%eax
801039aa:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
801039ad:	8b 15 e4 70 12 80    	mov    0x801270e4,%edx
801039b3:	8b 45 ec             	mov    -0x14(%ebp),%eax
801039b6:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
801039b8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801039bf:	eb 1b                	jmp    801039dc <write_head+0x59>
    hb->sector[i] = log.lh.sector[i];
801039c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039c4:	83 c0 10             	add    $0x10,%eax
801039c7:	8b 0c 85 a8 70 12 80 	mov    -0x7fed8f58(,%eax,4),%ecx
801039ce:	8b 45 ec             	mov    -0x14(%ebp),%eax
801039d1:	8b 55 f4             	mov    -0xc(%ebp),%edx
801039d4:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
801039d8:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801039dc:	a1 e4 70 12 80       	mov    0x801270e4,%eax
801039e1:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801039e4:	7f db                	jg     801039c1 <write_head+0x3e>
    hb->sector[i] = log.lh.sector[i];
  }
  bwrite(buf);
801039e6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801039e9:	89 04 24             	mov    %eax,(%esp)
801039ec:	e8 ec c7 ff ff       	call   801001dd <bwrite>
  brelse(buf);
801039f1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801039f4:	89 04 24             	mov    %eax,(%esp)
801039f7:	e8 1b c8 ff ff       	call   80100217 <brelse>
}
801039fc:	c9                   	leave  
801039fd:	c3                   	ret    

801039fe <recover_from_log>:

static void
recover_from_log(void)
{
801039fe:	55                   	push   %ebp
801039ff:	89 e5                	mov    %esp,%ebp
80103a01:	83 ec 08             	sub    $0x8,%esp
  read_head();      
80103a04:	e8 0b ff ff ff       	call   80103914 <read_head>
  install_trans(); // if committed, copy from log to disk
80103a09:	e8 5b fe ff ff       	call   80103869 <install_trans>
  log.lh.n = 0;
80103a0e:	c7 05 e4 70 12 80 00 	movl   $0x0,0x801270e4
80103a15:	00 00 00 
  write_head(); // clear the log
80103a18:	e8 66 ff ff ff       	call   80103983 <write_head>
}
80103a1d:	c9                   	leave  
80103a1e:	c3                   	ret    

80103a1f <begin_trans>:

void
begin_trans(void)
{
80103a1f:	55                   	push   %ebp
80103a20:	89 e5                	mov    %esp,%ebp
80103a22:	83 ec 18             	sub    $0x18,%esp
  acquire(&log.lock);
80103a25:	c7 04 24 a0 70 12 80 	movl   $0x801270a0,(%esp)
80103a2c:	e8 62 21 00 00       	call   80105b93 <acquire>
  while (log.busy) {		//changed sleep to busy - waiting to avoid deadlocks
80103a31:	eb 1d                	jmp    80103a50 <begin_trans+0x31>
  //sleep(&log, &log.lock);
    release(&log.lock);
80103a33:	c7 04 24 a0 70 12 80 	movl   $0x801270a0,(%esp)
80103a3a:	e8 ef 21 00 00       	call   80105c2e <release>
    sti();
80103a3f:	e8 c8 fd ff ff       	call   8010380c <sti>
    acquire(&log.lock);
80103a44:	c7 04 24 a0 70 12 80 	movl   $0x801270a0,(%esp)
80103a4b:	e8 43 21 00 00       	call   80105b93 <acquire>

void
begin_trans(void)
{
  acquire(&log.lock);
  while (log.busy) {		//changed sleep to busy - waiting to avoid deadlocks
80103a50:	a1 dc 70 12 80       	mov    0x801270dc,%eax
80103a55:	85 c0                	test   %eax,%eax
80103a57:	75 da                	jne    80103a33 <begin_trans+0x14>
  //sleep(&log, &log.lock);
    release(&log.lock);
    sti();
    acquire(&log.lock);
  }
  log.busy = 1;
80103a59:	c7 05 dc 70 12 80 01 	movl   $0x1,0x801270dc
80103a60:	00 00 00 
  release(&log.lock);
80103a63:	c7 04 24 a0 70 12 80 	movl   $0x801270a0,(%esp)
80103a6a:	e8 bf 21 00 00       	call   80105c2e <release>
}
80103a6f:	c9                   	leave  
80103a70:	c3                   	ret    

80103a71 <commit_trans>:

void
commit_trans(void)
{
80103a71:	55                   	push   %ebp
80103a72:	89 e5                	mov    %esp,%ebp
80103a74:	83 ec 18             	sub    $0x18,%esp
  if (log.lh.n > 0) {
80103a77:	a1 e4 70 12 80       	mov    0x801270e4,%eax
80103a7c:	85 c0                	test   %eax,%eax
80103a7e:	7e 19                	jle    80103a99 <commit_trans+0x28>
    write_head();    // Write header to disk -- the real commit
80103a80:	e8 fe fe ff ff       	call   80103983 <write_head>
    install_trans(); // Now install writes to home locations
80103a85:	e8 df fd ff ff       	call   80103869 <install_trans>
    log.lh.n = 0; 
80103a8a:	c7 05 e4 70 12 80 00 	movl   $0x0,0x801270e4
80103a91:	00 00 00 
    write_head();    // Erase the transaction from the log
80103a94:	e8 ea fe ff ff       	call   80103983 <write_head>
  }
  
  acquire(&log.lock);
80103a99:	c7 04 24 a0 70 12 80 	movl   $0x801270a0,(%esp)
80103aa0:	e8 ee 20 00 00       	call   80105b93 <acquire>
  log.busy = 0;
80103aa5:	c7 05 dc 70 12 80 00 	movl   $0x0,0x801270dc
80103aac:	00 00 00 
  //wakeup(&log);
  release(&log.lock);
80103aaf:	c7 04 24 a0 70 12 80 	movl   $0x801270a0,(%esp)
80103ab6:	e8 73 21 00 00       	call   80105c2e <release>
}
80103abb:	c9                   	leave  
80103abc:	c3                   	ret    

80103abd <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80103abd:	55                   	push   %ebp
80103abe:	89 e5                	mov    %esp,%ebp
80103ac0:	83 ec 28             	sub    $0x28,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80103ac3:	a1 e4 70 12 80       	mov    0x801270e4,%eax
80103ac8:	83 f8 09             	cmp    $0x9,%eax
80103acb:	7f 12                	jg     80103adf <log_write+0x22>
80103acd:	a1 e4 70 12 80       	mov    0x801270e4,%eax
80103ad2:	8b 15 d8 70 12 80    	mov    0x801270d8,%edx
80103ad8:	83 ea 01             	sub    $0x1,%edx
80103adb:	39 d0                	cmp    %edx,%eax
80103add:	7c 0c                	jl     80103aeb <log_write+0x2e>
    panic("too big a transaction");
80103adf:	c7 04 24 94 99 10 80 	movl   $0x80109994,(%esp)
80103ae6:	e8 52 ca ff ff       	call   8010053d <panic>
  if (!log.busy)
80103aeb:	a1 dc 70 12 80       	mov    0x801270dc,%eax
80103af0:	85 c0                	test   %eax,%eax
80103af2:	75 0c                	jne    80103b00 <log_write+0x43>
    panic("write outside of trans");
80103af4:	c7 04 24 aa 99 10 80 	movl   $0x801099aa,(%esp)
80103afb:	e8 3d ca ff ff       	call   8010053d <panic>

  for (i = 0; i < log.lh.n; i++) {
80103b00:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103b07:	eb 1d                	jmp    80103b26 <log_write+0x69>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
80103b09:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b0c:	83 c0 10             	add    $0x10,%eax
80103b0f:	8b 04 85 a8 70 12 80 	mov    -0x7fed8f58(,%eax,4),%eax
80103b16:	89 c2                	mov    %eax,%edx
80103b18:	8b 45 08             	mov    0x8(%ebp),%eax
80103b1b:	8b 40 08             	mov    0x8(%eax),%eax
80103b1e:	39 c2                	cmp    %eax,%edx
80103b20:	74 10                	je     80103b32 <log_write+0x75>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    panic("too big a transaction");
  if (!log.busy)
    panic("write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
80103b22:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103b26:	a1 e4 70 12 80       	mov    0x801270e4,%eax
80103b2b:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103b2e:	7f d9                	jg     80103b09 <log_write+0x4c>
80103b30:	eb 01                	jmp    80103b33 <log_write+0x76>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
      break;
80103b32:	90                   	nop
  }
  log.lh.sector[i] = b->sector;
80103b33:	8b 45 08             	mov    0x8(%ebp),%eax
80103b36:	8b 40 08             	mov    0x8(%eax),%eax
80103b39:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103b3c:	83 c2 10             	add    $0x10,%edx
80103b3f:	89 04 95 a8 70 12 80 	mov    %eax,-0x7fed8f58(,%edx,4)
  struct buf *lbuf = bread(b->dev, log.start+i+1);
80103b46:	a1 d4 70 12 80       	mov    0x801270d4,%eax
80103b4b:	03 45 f4             	add    -0xc(%ebp),%eax
80103b4e:	83 c0 01             	add    $0x1,%eax
80103b51:	89 c2                	mov    %eax,%edx
80103b53:	8b 45 08             	mov    0x8(%ebp),%eax
80103b56:	8b 40 04             	mov    0x4(%eax),%eax
80103b59:	89 54 24 04          	mov    %edx,0x4(%esp)
80103b5d:	89 04 24             	mov    %eax,(%esp)
80103b60:	e8 41 c6 ff ff       	call   801001a6 <bread>
80103b65:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(lbuf->data, b->data, BSIZE);
80103b68:	8b 45 08             	mov    0x8(%ebp),%eax
80103b6b:	8d 50 18             	lea    0x18(%eax),%edx
80103b6e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b71:	83 c0 18             	add    $0x18,%eax
80103b74:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80103b7b:	00 
80103b7c:	89 54 24 04          	mov    %edx,0x4(%esp)
80103b80:	89 04 24             	mov    %eax,(%esp)
80103b83:	e8 65 23 00 00       	call   80105eed <memmove>
  bwrite(lbuf);
80103b88:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b8b:	89 04 24             	mov    %eax,(%esp)
80103b8e:	e8 4a c6 ff ff       	call   801001dd <bwrite>
  brelse(lbuf);
80103b93:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b96:	89 04 24             	mov    %eax,(%esp)
80103b99:	e8 79 c6 ff ff       	call   80100217 <brelse>
  if (i == log.lh.n)
80103b9e:	a1 e4 70 12 80       	mov    0x801270e4,%eax
80103ba3:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103ba6:	75 0d                	jne    80103bb5 <log_write+0xf8>
    log.lh.n++;
80103ba8:	a1 e4 70 12 80       	mov    0x801270e4,%eax
80103bad:	83 c0 01             	add    $0x1,%eax
80103bb0:	a3 e4 70 12 80       	mov    %eax,0x801270e4
  b->flags |= B_DIRTY; // XXX prevent eviction
80103bb5:	8b 45 08             	mov    0x8(%ebp),%eax
80103bb8:	8b 00                	mov    (%eax),%eax
80103bba:	89 c2                	mov    %eax,%edx
80103bbc:	83 ca 04             	or     $0x4,%edx
80103bbf:	8b 45 08             	mov    0x8(%ebp),%eax
80103bc2:	89 10                	mov    %edx,(%eax)
}
80103bc4:	c9                   	leave  
80103bc5:	c3                   	ret    
	...

80103bc8 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80103bc8:	55                   	push   %ebp
80103bc9:	89 e5                	mov    %esp,%ebp
80103bcb:	8b 45 08             	mov    0x8(%ebp),%eax
80103bce:	05 00 00 00 80       	add    $0x80000000,%eax
80103bd3:	5d                   	pop    %ebp
80103bd4:	c3                   	ret    

80103bd5 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80103bd5:	55                   	push   %ebp
80103bd6:	89 e5                	mov    %esp,%ebp
80103bd8:	8b 45 08             	mov    0x8(%ebp),%eax
80103bdb:	05 00 00 00 80       	add    $0x80000000,%eax
80103be0:	5d                   	pop    %ebp
80103be1:	c3                   	ret    

80103be2 <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
80103be2:	55                   	push   %ebp
80103be3:	89 e5                	mov    %esp,%ebp
80103be5:	53                   	push   %ebx
80103be6:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
80103be9:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80103bec:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
80103bef:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80103bf2:	89 c3                	mov    %eax,%ebx
80103bf4:	89 d8                	mov    %ebx,%eax
80103bf6:	f0 87 02             	lock xchg %eax,(%edx)
80103bf9:	89 c3                	mov    %eax,%ebx
80103bfb:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80103bfe:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103c01:	83 c4 10             	add    $0x10,%esp
80103c04:	5b                   	pop    %ebx
80103c05:	5d                   	pop    %ebp
80103c06:	c3                   	ret    

80103c07 <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
80103c07:	55                   	push   %ebp
80103c08:	89 e5                	mov    %esp,%ebp
80103c0a:	83 e4 f0             	and    $0xfffffff0,%esp
80103c0d:	83 ec 10             	sub    $0x10,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80103c10:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
80103c17:	80 
80103c18:	c7 04 24 1c a4 12 80 	movl   $0x8012a41c,(%esp)
80103c1f:	e8 be ed ff ff       	call   801029e2 <kinit1>
  kvmalloc();      // kernel page table
80103c24:	e8 0d 53 00 00       	call   80108f36 <kvmalloc>
  mpinit();        // collect info about this machine
80103c29:	e8 63 04 00 00       	call   80104091 <mpinit>
  lapicinit(mpbcpu());
80103c2e:	e8 2e 02 00 00       	call   80103e61 <mpbcpu>
80103c33:	89 04 24             	mov    %eax,(%esp)
80103c36:	e8 f1 f8 ff ff       	call   8010352c <lapicinit>
  seginit();       // set up segments
80103c3b:	e8 99 4c 00 00       	call   801088d9 <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
80103c40:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103c46:	0f b6 00             	movzbl (%eax),%eax
80103c49:	0f b6 c0             	movzbl %al,%eax
80103c4c:	89 44 24 04          	mov    %eax,0x4(%esp)
80103c50:	c7 04 24 c1 99 10 80 	movl   $0x801099c1,(%esp)
80103c57:	e8 45 c7 ff ff       	call   801003a1 <cprintf>
  picinit();       // interrupt controller
80103c5c:	e8 95 06 00 00       	call   801042f6 <picinit>
  ioapicinit();    // another interrupt controller
80103c61:	e8 5f ec ff ff       	call   801028c5 <ioapicinit>
  consoleinit();   // I/O devices & their interrupts
80103c66:	e8 22 ce ff ff       	call   80100a8d <consoleinit>
  uartinit();      // serial port
80103c6b:	e8 b4 3f 00 00       	call   80107c24 <uartinit>
  pinit();         // process table
80103c70:	e8 a3 0b 00 00       	call   80104818 <pinit>
  tvinit();        // trap vectors
80103c75:	e8 4d 3b 00 00       	call   801077c7 <tvinit>
  binit();         // buffer cache
80103c7a:	e8 b5 c3 ff ff       	call   80100034 <binit>
  fileinit();      // file table
80103c7f:	e8 7c d2 ff ff       	call   80100f00 <fileinit>
  iinit();         // inode cache
80103c84:	e8 2a d9 ff ff       	call   801015b3 <iinit>
  ideinit();       // disk
80103c89:	e8 9e e8 ff ff       	call   8010252c <ideinit>
  if(!ismp)
80103c8e:	a1 24 71 12 80       	mov    0x80127124,%eax
80103c93:	85 c0                	test   %eax,%eax
80103c95:	75 05                	jne    80103c9c <main+0x95>
    timerinit();   // uniprocessor timer
80103c97:	e8 6e 3a 00 00       	call   8010770a <timerinit>
  startothers();   // start other processors
80103c9c:	e8 87 00 00 00       	call   80103d28 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80103ca1:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
80103ca8:	8e 
80103ca9:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
80103cb0:	e8 65 ed ff ff       	call   80102a1a <kinit2>
  userinit();      // first user process
80103cb5:	e8 5c 12 00 00       	call   80104f16 <userinit>
  // Finish setting up this processor in mpmain.
  mpmain();
80103cba:	e8 22 00 00 00       	call   80103ce1 <mpmain>

80103cbf <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
80103cbf:	55                   	push   %ebp
80103cc0:	89 e5                	mov    %esp,%ebp
80103cc2:	83 ec 18             	sub    $0x18,%esp
  switchkvm(); 
80103cc5:	e8 83 52 00 00       	call   80108f4d <switchkvm>
  seginit();
80103cca:	e8 0a 4c 00 00       	call   801088d9 <seginit>
  lapicinit(cpunum());
80103ccf:	e8 b5 f9 ff ff       	call   80103689 <cpunum>
80103cd4:	89 04 24             	mov    %eax,(%esp)
80103cd7:	e8 50 f8 ff ff       	call   8010352c <lapicinit>
  mpmain();
80103cdc:	e8 00 00 00 00       	call   80103ce1 <mpmain>

80103ce1 <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
80103ce1:	55                   	push   %ebp
80103ce2:	89 e5                	mov    %esp,%ebp
80103ce4:	83 ec 18             	sub    $0x18,%esp
  cprintf("cpu%d: starting\n", cpu->id);
80103ce7:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103ced:	0f b6 00             	movzbl (%eax),%eax
80103cf0:	0f b6 c0             	movzbl %al,%eax
80103cf3:	89 44 24 04          	mov    %eax,0x4(%esp)
80103cf7:	c7 04 24 d8 99 10 80 	movl   $0x801099d8,(%esp)
80103cfe:	e8 9e c6 ff ff       	call   801003a1 <cprintf>
  idtinit();       // load idt register
80103d03:	e8 33 3c 00 00       	call   8010793b <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
80103d08:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103d0e:	05 a8 00 00 00       	add    $0xa8,%eax
80103d13:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80103d1a:	00 
80103d1b:	89 04 24             	mov    %eax,(%esp)
80103d1e:	e8 bf fe ff ff       	call   80103be2 <xchg>
  scheduler();     // start running processes
80103d23:	e8 1f 18 00 00       	call   80105547 <scheduler>

80103d28 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80103d28:	55                   	push   %ebp
80103d29:	89 e5                	mov    %esp,%ebp
80103d2b:	53                   	push   %ebx
80103d2c:	83 ec 24             	sub    $0x24,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
80103d2f:	c7 04 24 00 70 00 00 	movl   $0x7000,(%esp)
80103d36:	e8 9a fe ff ff       	call   80103bd5 <p2v>
80103d3b:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80103d3e:	b8 8a 00 00 00       	mov    $0x8a,%eax
80103d43:	89 44 24 08          	mov    %eax,0x8(%esp)
80103d47:	c7 44 24 04 2c c5 10 	movl   $0x8010c52c,0x4(%esp)
80103d4e:	80 
80103d4f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d52:	89 04 24             	mov    %eax,(%esp)
80103d55:	e8 93 21 00 00       	call   80105eed <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80103d5a:	c7 45 f4 40 71 12 80 	movl   $0x80127140,-0xc(%ebp)
80103d61:	e9 86 00 00 00       	jmp    80103dec <startothers+0xc4>
    if(c == cpus+cpunum())  // We've started already.
80103d66:	e8 1e f9 ff ff       	call   80103689 <cpunum>
80103d6b:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103d71:	05 40 71 12 80       	add    $0x80127140,%eax
80103d76:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103d79:	74 69                	je     80103de4 <startothers+0xbc>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what 
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
80103d7b:	e8 90 ed ff ff       	call   80102b10 <kalloc>
80103d80:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
80103d83:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d86:	83 e8 04             	sub    $0x4,%eax
80103d89:	8b 55 ec             	mov    -0x14(%ebp),%edx
80103d8c:	81 c2 00 10 00 00    	add    $0x1000,%edx
80103d92:	89 10                	mov    %edx,(%eax)
    *(void**)(code-8) = mpenter;
80103d94:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d97:	83 e8 08             	sub    $0x8,%eax
80103d9a:	c7 00 bf 3c 10 80    	movl   $0x80103cbf,(%eax)
    *(int**)(code-12) = (void *) v2p(entrypgdir);
80103da0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103da3:	8d 58 f4             	lea    -0xc(%eax),%ebx
80103da6:	c7 04 24 00 b0 10 80 	movl   $0x8010b000,(%esp)
80103dad:	e8 16 fe ff ff       	call   80103bc8 <v2p>
80103db2:	89 03                	mov    %eax,(%ebx)

    lapicstartap(c->id, v2p(code));
80103db4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103db7:	89 04 24             	mov    %eax,(%esp)
80103dba:	e8 09 fe ff ff       	call   80103bc8 <v2p>
80103dbf:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103dc2:	0f b6 12             	movzbl (%edx),%edx
80103dc5:	0f b6 d2             	movzbl %dl,%edx
80103dc8:	89 44 24 04          	mov    %eax,0x4(%esp)
80103dcc:	89 14 24             	mov    %edx,(%esp)
80103dcf:	e8 3b f9 ff ff       	call   8010370f <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80103dd4:	90                   	nop
80103dd5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103dd8:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
80103dde:	85 c0                	test   %eax,%eax
80103de0:	74 f3                	je     80103dd5 <startothers+0xad>
80103de2:	eb 01                	jmp    80103de5 <startothers+0xbd>
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
    if(c == cpus+cpunum())  // We've started already.
      continue;
80103de4:	90                   	nop
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
80103de5:	81 45 f4 bc 00 00 00 	addl   $0xbc,-0xc(%ebp)
80103dec:	a1 20 77 12 80       	mov    0x80127720,%eax
80103df1:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103df7:	05 40 71 12 80       	add    $0x80127140,%eax
80103dfc:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103dff:	0f 87 61 ff ff ff    	ja     80103d66 <startothers+0x3e>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;
  }
}
80103e05:	83 c4 24             	add    $0x24,%esp
80103e08:	5b                   	pop    %ebx
80103e09:	5d                   	pop    %ebp
80103e0a:	c3                   	ret    
	...

80103e0c <p2v>:
80103e0c:	55                   	push   %ebp
80103e0d:	89 e5                	mov    %esp,%ebp
80103e0f:	8b 45 08             	mov    0x8(%ebp),%eax
80103e12:	05 00 00 00 80       	add    $0x80000000,%eax
80103e17:	5d                   	pop    %ebp
80103e18:	c3                   	ret    

80103e19 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80103e19:	55                   	push   %ebp
80103e1a:	89 e5                	mov    %esp,%ebp
80103e1c:	53                   	push   %ebx
80103e1d:	83 ec 14             	sub    $0x14,%esp
80103e20:	8b 45 08             	mov    0x8(%ebp),%eax
80103e23:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80103e27:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80103e2b:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80103e2f:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80103e33:	ec                   	in     (%dx),%al
80103e34:	89 c3                	mov    %eax,%ebx
80103e36:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80103e39:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80103e3d:	83 c4 14             	add    $0x14,%esp
80103e40:	5b                   	pop    %ebx
80103e41:	5d                   	pop    %ebp
80103e42:	c3                   	ret    

80103e43 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103e43:	55                   	push   %ebp
80103e44:	89 e5                	mov    %esp,%ebp
80103e46:	83 ec 08             	sub    $0x8,%esp
80103e49:	8b 55 08             	mov    0x8(%ebp),%edx
80103e4c:	8b 45 0c             	mov    0xc(%ebp),%eax
80103e4f:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103e53:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103e56:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103e5a:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103e5e:	ee                   	out    %al,(%dx)
}
80103e5f:	c9                   	leave  
80103e60:	c3                   	ret    

80103e61 <mpbcpu>:
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
80103e61:	55                   	push   %ebp
80103e62:	89 e5                	mov    %esp,%ebp
  return bcpu-cpus;
80103e64:	a1 64 c6 10 80       	mov    0x8010c664,%eax
80103e69:	89 c2                	mov    %eax,%edx
80103e6b:	b8 40 71 12 80       	mov    $0x80127140,%eax
80103e70:	89 d1                	mov    %edx,%ecx
80103e72:	29 c1                	sub    %eax,%ecx
80103e74:	89 c8                	mov    %ecx,%eax
80103e76:	c1 f8 02             	sar    $0x2,%eax
80103e79:	69 c0 cf 46 7d 67    	imul   $0x677d46cf,%eax,%eax
}
80103e7f:	5d                   	pop    %ebp
80103e80:	c3                   	ret    

80103e81 <sum>:

static uchar
sum(uchar *addr, int len)
{
80103e81:	55                   	push   %ebp
80103e82:	89 e5                	mov    %esp,%ebp
80103e84:	83 ec 10             	sub    $0x10,%esp
  int i, sum;
  
  sum = 0;
80103e87:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
80103e8e:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80103e95:	eb 13                	jmp    80103eaa <sum+0x29>
    sum += addr[i];
80103e97:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103e9a:	03 45 08             	add    0x8(%ebp),%eax
80103e9d:	0f b6 00             	movzbl (%eax),%eax
80103ea0:	0f b6 c0             	movzbl %al,%eax
80103ea3:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
80103ea6:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103eaa:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103ead:	3b 45 0c             	cmp    0xc(%ebp),%eax
80103eb0:	7c e5                	jl     80103e97 <sum+0x16>
    sum += addr[i];
  return sum;
80103eb2:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103eb5:	c9                   	leave  
80103eb6:	c3                   	ret    

80103eb7 <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80103eb7:	55                   	push   %ebp
80103eb8:	89 e5                	mov    %esp,%ebp
80103eba:	83 ec 28             	sub    $0x28,%esp
  uchar *e, *p, *addr;

  addr = p2v(a);
80103ebd:	8b 45 08             	mov    0x8(%ebp),%eax
80103ec0:	89 04 24             	mov    %eax,(%esp)
80103ec3:	e8 44 ff ff ff       	call   80103e0c <p2v>
80103ec8:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
80103ecb:	8b 45 0c             	mov    0xc(%ebp),%eax
80103ece:	03 45 f0             	add    -0x10(%ebp),%eax
80103ed1:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
80103ed4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103ed7:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103eda:	eb 3f                	jmp    80103f1b <mpsearch1+0x64>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80103edc:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80103ee3:	00 
80103ee4:	c7 44 24 04 ec 99 10 	movl   $0x801099ec,0x4(%esp)
80103eeb:	80 
80103eec:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103eef:	89 04 24             	mov    %eax,(%esp)
80103ef2:	e8 9a 1f 00 00       	call   80105e91 <memcmp>
80103ef7:	85 c0                	test   %eax,%eax
80103ef9:	75 1c                	jne    80103f17 <mpsearch1+0x60>
80103efb:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
80103f02:	00 
80103f03:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f06:	89 04 24             	mov    %eax,(%esp)
80103f09:	e8 73 ff ff ff       	call   80103e81 <sum>
80103f0e:	84 c0                	test   %al,%al
80103f10:	75 05                	jne    80103f17 <mpsearch1+0x60>
      return (struct mp*)p;
80103f12:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f15:	eb 11                	jmp    80103f28 <mpsearch1+0x71>
{
  uchar *e, *p, *addr;

  addr = p2v(a);
  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
80103f17:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80103f1b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f1e:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103f21:	72 b9                	jb     80103edc <mpsearch1+0x25>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
80103f23:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103f28:	c9                   	leave  
80103f29:	c3                   	ret    

80103f2a <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80103f2a:	55                   	push   %ebp
80103f2b:	89 e5                	mov    %esp,%ebp
80103f2d:	83 ec 28             	sub    $0x28,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
80103f30:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80103f37:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f3a:	83 c0 0f             	add    $0xf,%eax
80103f3d:	0f b6 00             	movzbl (%eax),%eax
80103f40:	0f b6 c0             	movzbl %al,%eax
80103f43:	89 c2                	mov    %eax,%edx
80103f45:	c1 e2 08             	shl    $0x8,%edx
80103f48:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f4b:	83 c0 0e             	add    $0xe,%eax
80103f4e:	0f b6 00             	movzbl (%eax),%eax
80103f51:	0f b6 c0             	movzbl %al,%eax
80103f54:	09 d0                	or     %edx,%eax
80103f56:	c1 e0 04             	shl    $0x4,%eax
80103f59:	89 45 f0             	mov    %eax,-0x10(%ebp)
80103f5c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103f60:	74 21                	je     80103f83 <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
80103f62:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80103f69:	00 
80103f6a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103f6d:	89 04 24             	mov    %eax,(%esp)
80103f70:	e8 42 ff ff ff       	call   80103eb7 <mpsearch1>
80103f75:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103f78:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103f7c:	74 50                	je     80103fce <mpsearch+0xa4>
      return mp;
80103f7e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103f81:	eb 5f                	jmp    80103fe2 <mpsearch+0xb8>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80103f83:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f86:	83 c0 14             	add    $0x14,%eax
80103f89:	0f b6 00             	movzbl (%eax),%eax
80103f8c:	0f b6 c0             	movzbl %al,%eax
80103f8f:	89 c2                	mov    %eax,%edx
80103f91:	c1 e2 08             	shl    $0x8,%edx
80103f94:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f97:	83 c0 13             	add    $0x13,%eax
80103f9a:	0f b6 00             	movzbl (%eax),%eax
80103f9d:	0f b6 c0             	movzbl %al,%eax
80103fa0:	09 d0                	or     %edx,%eax
80103fa2:	c1 e0 0a             	shl    $0xa,%eax
80103fa5:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
80103fa8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103fab:	2d 00 04 00 00       	sub    $0x400,%eax
80103fb0:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80103fb7:	00 
80103fb8:	89 04 24             	mov    %eax,(%esp)
80103fbb:	e8 f7 fe ff ff       	call   80103eb7 <mpsearch1>
80103fc0:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103fc3:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103fc7:	74 05                	je     80103fce <mpsearch+0xa4>
      return mp;
80103fc9:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103fcc:	eb 14                	jmp    80103fe2 <mpsearch+0xb8>
  }
  return mpsearch1(0xF0000, 0x10000);
80103fce:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103fd5:	00 
80103fd6:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
80103fdd:	e8 d5 fe ff ff       	call   80103eb7 <mpsearch1>
}
80103fe2:	c9                   	leave  
80103fe3:	c3                   	ret    

80103fe4 <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80103fe4:	55                   	push   %ebp
80103fe5:	89 e5                	mov    %esp,%ebp
80103fe7:	83 ec 28             	sub    $0x28,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80103fea:	e8 3b ff ff ff       	call   80103f2a <mpsearch>
80103fef:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103ff2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103ff6:	74 0a                	je     80104002 <mpconfig+0x1e>
80103ff8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ffb:	8b 40 04             	mov    0x4(%eax),%eax
80103ffe:	85 c0                	test   %eax,%eax
80104000:	75 0a                	jne    8010400c <mpconfig+0x28>
    return 0;
80104002:	b8 00 00 00 00       	mov    $0x0,%eax
80104007:	e9 83 00 00 00       	jmp    8010408f <mpconfig+0xab>
  conf = (struct mpconf*) p2v((uint) mp->physaddr);
8010400c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010400f:	8b 40 04             	mov    0x4(%eax),%eax
80104012:	89 04 24             	mov    %eax,(%esp)
80104015:	e8 f2 fd ff ff       	call   80103e0c <p2v>
8010401a:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
8010401d:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80104024:	00 
80104025:	c7 44 24 04 f1 99 10 	movl   $0x801099f1,0x4(%esp)
8010402c:	80 
8010402d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104030:	89 04 24             	mov    %eax,(%esp)
80104033:	e8 59 1e 00 00       	call   80105e91 <memcmp>
80104038:	85 c0                	test   %eax,%eax
8010403a:	74 07                	je     80104043 <mpconfig+0x5f>
    return 0;
8010403c:	b8 00 00 00 00       	mov    $0x0,%eax
80104041:	eb 4c                	jmp    8010408f <mpconfig+0xab>
  if(conf->version != 1 && conf->version != 4)
80104043:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104046:	0f b6 40 06          	movzbl 0x6(%eax),%eax
8010404a:	3c 01                	cmp    $0x1,%al
8010404c:	74 12                	je     80104060 <mpconfig+0x7c>
8010404e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104051:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80104055:	3c 04                	cmp    $0x4,%al
80104057:	74 07                	je     80104060 <mpconfig+0x7c>
    return 0;
80104059:	b8 00 00 00 00       	mov    $0x0,%eax
8010405e:	eb 2f                	jmp    8010408f <mpconfig+0xab>
  if(sum((uchar*)conf, conf->length) != 0)
80104060:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104063:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80104067:	0f b7 c0             	movzwl %ax,%eax
8010406a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010406e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104071:	89 04 24             	mov    %eax,(%esp)
80104074:	e8 08 fe ff ff       	call   80103e81 <sum>
80104079:	84 c0                	test   %al,%al
8010407b:	74 07                	je     80104084 <mpconfig+0xa0>
    return 0;
8010407d:	b8 00 00 00 00       	mov    $0x0,%eax
80104082:	eb 0b                	jmp    8010408f <mpconfig+0xab>
  *pmp = mp;
80104084:	8b 45 08             	mov    0x8(%ebp),%eax
80104087:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010408a:	89 10                	mov    %edx,(%eax)
  return conf;
8010408c:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
8010408f:	c9                   	leave  
80104090:	c3                   	ret    

80104091 <mpinit>:

void
mpinit(void)
{
80104091:	55                   	push   %ebp
80104092:	89 e5                	mov    %esp,%ebp
80104094:	83 ec 38             	sub    $0x38,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
80104097:	c7 05 64 c6 10 80 40 	movl   $0x80127140,0x8010c664
8010409e:	71 12 80 
  if((conf = mpconfig(&mp)) == 0)
801040a1:	8d 45 e0             	lea    -0x20(%ebp),%eax
801040a4:	89 04 24             	mov    %eax,(%esp)
801040a7:	e8 38 ff ff ff       	call   80103fe4 <mpconfig>
801040ac:	89 45 f0             	mov    %eax,-0x10(%ebp)
801040af:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801040b3:	0f 84 9c 01 00 00    	je     80104255 <mpinit+0x1c4>
    return;
  ismp = 1;
801040b9:	c7 05 24 71 12 80 01 	movl   $0x1,0x80127124
801040c0:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
801040c3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801040c6:	8b 40 24             	mov    0x24(%eax),%eax
801040c9:	a3 94 70 12 80       	mov    %eax,0x80127094
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
801040ce:	8b 45 f0             	mov    -0x10(%ebp),%eax
801040d1:	83 c0 2c             	add    $0x2c,%eax
801040d4:	89 45 f4             	mov    %eax,-0xc(%ebp)
801040d7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801040da:	0f b7 40 04          	movzwl 0x4(%eax),%eax
801040de:	0f b7 c0             	movzwl %ax,%eax
801040e1:	03 45 f0             	add    -0x10(%ebp),%eax
801040e4:	89 45 ec             	mov    %eax,-0x14(%ebp)
801040e7:	e9 f4 00 00 00       	jmp    801041e0 <mpinit+0x14f>
    switch(*p){
801040ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
801040ef:	0f b6 00             	movzbl (%eax),%eax
801040f2:	0f b6 c0             	movzbl %al,%eax
801040f5:	83 f8 04             	cmp    $0x4,%eax
801040f8:	0f 87 bf 00 00 00    	ja     801041bd <mpinit+0x12c>
801040fe:	8b 04 85 34 9a 10 80 	mov    -0x7fef65cc(,%eax,4),%eax
80104105:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
80104107:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010410a:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(ncpu != proc->apicid){
8010410d:	8b 45 e8             	mov    -0x18(%ebp),%eax
80104110:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80104114:	0f b6 d0             	movzbl %al,%edx
80104117:	a1 20 77 12 80       	mov    0x80127720,%eax
8010411c:	39 c2                	cmp    %eax,%edx
8010411e:	74 2d                	je     8010414d <mpinit+0xbc>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
80104120:	8b 45 e8             	mov    -0x18(%ebp),%eax
80104123:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80104127:	0f b6 d0             	movzbl %al,%edx
8010412a:	a1 20 77 12 80       	mov    0x80127720,%eax
8010412f:	89 54 24 08          	mov    %edx,0x8(%esp)
80104133:	89 44 24 04          	mov    %eax,0x4(%esp)
80104137:	c7 04 24 f6 99 10 80 	movl   $0x801099f6,(%esp)
8010413e:	e8 5e c2 ff ff       	call   801003a1 <cprintf>
        ismp = 0;
80104143:	c7 05 24 71 12 80 00 	movl   $0x0,0x80127124
8010414a:	00 00 00 
      }
      if(proc->flags & MPBOOT)
8010414d:	8b 45 e8             	mov    -0x18(%ebp),%eax
80104150:	0f b6 40 03          	movzbl 0x3(%eax),%eax
80104154:	0f b6 c0             	movzbl %al,%eax
80104157:	83 e0 02             	and    $0x2,%eax
8010415a:	85 c0                	test   %eax,%eax
8010415c:	74 15                	je     80104173 <mpinit+0xe2>
        bcpu = &cpus[ncpu];
8010415e:	a1 20 77 12 80       	mov    0x80127720,%eax
80104163:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80104169:	05 40 71 12 80       	add    $0x80127140,%eax
8010416e:	a3 64 c6 10 80       	mov    %eax,0x8010c664
      cpus[ncpu].id = ncpu;
80104173:	8b 15 20 77 12 80    	mov    0x80127720,%edx
80104179:	a1 20 77 12 80       	mov    0x80127720,%eax
8010417e:	69 d2 bc 00 00 00    	imul   $0xbc,%edx,%edx
80104184:	81 c2 40 71 12 80    	add    $0x80127140,%edx
8010418a:	88 02                	mov    %al,(%edx)
      ncpu++;
8010418c:	a1 20 77 12 80       	mov    0x80127720,%eax
80104191:	83 c0 01             	add    $0x1,%eax
80104194:	a3 20 77 12 80       	mov    %eax,0x80127720
      p += sizeof(struct mpproc);
80104199:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
8010419d:	eb 41                	jmp    801041e0 <mpinit+0x14f>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
8010419f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041a2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      ioapicid = ioapic->apicno;
801041a5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801041a8:	0f b6 40 01          	movzbl 0x1(%eax),%eax
801041ac:	a2 20 71 12 80       	mov    %al,0x80127120
      p += sizeof(struct mpioapic);
801041b1:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
801041b5:	eb 29                	jmp    801041e0 <mpinit+0x14f>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
801041b7:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
801041bb:	eb 23                	jmp    801041e0 <mpinit+0x14f>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
801041bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041c0:	0f b6 00             	movzbl (%eax),%eax
801041c3:	0f b6 c0             	movzbl %al,%eax
801041c6:	89 44 24 04          	mov    %eax,0x4(%esp)
801041ca:	c7 04 24 14 9a 10 80 	movl   $0x80109a14,(%esp)
801041d1:	e8 cb c1 ff ff       	call   801003a1 <cprintf>
      ismp = 0;
801041d6:	c7 05 24 71 12 80 00 	movl   $0x0,0x80127124
801041dd:	00 00 00 
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
801041e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041e3:	3b 45 ec             	cmp    -0x14(%ebp),%eax
801041e6:	0f 82 00 ff ff ff    	jb     801040ec <mpinit+0x5b>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
      ismp = 0;
    }
  }
  if(!ismp){
801041ec:	a1 24 71 12 80       	mov    0x80127124,%eax
801041f1:	85 c0                	test   %eax,%eax
801041f3:	75 1d                	jne    80104212 <mpinit+0x181>
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
801041f5:	c7 05 20 77 12 80 01 	movl   $0x1,0x80127720
801041fc:	00 00 00 
    lapic = 0;
801041ff:	c7 05 94 70 12 80 00 	movl   $0x0,0x80127094
80104206:	00 00 00 
    ioapicid = 0;
80104209:	c6 05 20 71 12 80 00 	movb   $0x0,0x80127120
    return;
80104210:	eb 44                	jmp    80104256 <mpinit+0x1c5>
  }

  if(mp->imcrp){
80104212:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104215:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
80104219:	84 c0                	test   %al,%al
8010421b:	74 39                	je     80104256 <mpinit+0x1c5>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
8010421d:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
80104224:	00 
80104225:	c7 04 24 22 00 00 00 	movl   $0x22,(%esp)
8010422c:	e8 12 fc ff ff       	call   80103e43 <outb>
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80104231:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80104238:	e8 dc fb ff ff       	call   80103e19 <inb>
8010423d:	83 c8 01             	or     $0x1,%eax
80104240:	0f b6 c0             	movzbl %al,%eax
80104243:	89 44 24 04          	mov    %eax,0x4(%esp)
80104247:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
8010424e:	e8 f0 fb ff ff       	call   80103e43 <outb>
80104253:	eb 01                	jmp    80104256 <mpinit+0x1c5>
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
80104255:	90                   	nop
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
  }
}
80104256:	c9                   	leave  
80104257:	c3                   	ret    

80104258 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80104258:	55                   	push   %ebp
80104259:	89 e5                	mov    %esp,%ebp
8010425b:	83 ec 08             	sub    $0x8,%esp
8010425e:	8b 55 08             	mov    0x8(%ebp),%edx
80104261:	8b 45 0c             	mov    0xc(%ebp),%eax
80104264:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80104268:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010426b:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
8010426f:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80104273:	ee                   	out    %al,(%dx)
}
80104274:	c9                   	leave  
80104275:	c3                   	ret    

80104276 <picsetmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static ushort irqmask = 0xFFFF & ~(1<<IRQ_SLAVE);

static void
picsetmask(ushort mask)
{
80104276:	55                   	push   %ebp
80104277:	89 e5                	mov    %esp,%ebp
80104279:	83 ec 0c             	sub    $0xc,%esp
8010427c:	8b 45 08             	mov    0x8(%ebp),%eax
8010427f:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  irqmask = mask;
80104283:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80104287:	66 a3 00 c0 10 80    	mov    %ax,0x8010c000
  outb(IO_PIC1+1, mask);
8010428d:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80104291:	0f b6 c0             	movzbl %al,%eax
80104294:	89 44 24 04          	mov    %eax,0x4(%esp)
80104298:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
8010429f:	e8 b4 ff ff ff       	call   80104258 <outb>
  outb(IO_PIC2+1, mask >> 8);
801042a4:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
801042a8:	66 c1 e8 08          	shr    $0x8,%ax
801042ac:	0f b6 c0             	movzbl %al,%eax
801042af:	89 44 24 04          	mov    %eax,0x4(%esp)
801042b3:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
801042ba:	e8 99 ff ff ff       	call   80104258 <outb>
}
801042bf:	c9                   	leave  
801042c0:	c3                   	ret    

801042c1 <picenable>:

void
picenable(int irq)
{
801042c1:	55                   	push   %ebp
801042c2:	89 e5                	mov    %esp,%ebp
801042c4:	53                   	push   %ebx
801042c5:	83 ec 04             	sub    $0x4,%esp
  picsetmask(irqmask & ~(1<<irq));
801042c8:	8b 45 08             	mov    0x8(%ebp),%eax
801042cb:	ba 01 00 00 00       	mov    $0x1,%edx
801042d0:	89 d3                	mov    %edx,%ebx
801042d2:	89 c1                	mov    %eax,%ecx
801042d4:	d3 e3                	shl    %cl,%ebx
801042d6:	89 d8                	mov    %ebx,%eax
801042d8:	89 c2                	mov    %eax,%edx
801042da:	f7 d2                	not    %edx
801042dc:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
801042e3:	21 d0                	and    %edx,%eax
801042e5:	0f b7 c0             	movzwl %ax,%eax
801042e8:	89 04 24             	mov    %eax,(%esp)
801042eb:	e8 86 ff ff ff       	call   80104276 <picsetmask>
}
801042f0:	83 c4 04             	add    $0x4,%esp
801042f3:	5b                   	pop    %ebx
801042f4:	5d                   	pop    %ebp
801042f5:	c3                   	ret    

801042f6 <picinit>:

// Initialize the 8259A interrupt controllers.
void
picinit(void)
{
801042f6:	55                   	push   %ebp
801042f7:	89 e5                	mov    %esp,%ebp
801042f9:	83 ec 08             	sub    $0x8,%esp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
801042fc:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80104303:	00 
80104304:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
8010430b:	e8 48 ff ff ff       	call   80104258 <outb>
  outb(IO_PIC2+1, 0xFF);
80104310:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80104317:	00 
80104318:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
8010431f:	e8 34 ff ff ff       	call   80104258 <outb>

  // ICW1:  0001g0hi
  //    g:  0 = edge triggering, 1 = level triggering
  //    h:  0 = cascaded PICs, 1 = master only
  //    i:  0 = no ICW4, 1 = ICW4 required
  outb(IO_PIC1, 0x11);
80104324:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
8010432b:	00 
8010432c:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80104333:	e8 20 ff ff ff       	call   80104258 <outb>

  // ICW2:  Vector offset
  outb(IO_PIC1+1, T_IRQ0);
80104338:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
8010433f:	00 
80104340:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104347:	e8 0c ff ff ff       	call   80104258 <outb>

  // ICW3:  (master PIC) bit mask of IR lines connected to slaves
  //        (slave PIC) 3-bit # of slave's connection to master
  outb(IO_PIC1+1, 1<<IRQ_SLAVE);
8010434c:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
80104353:	00 
80104354:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
8010435b:	e8 f8 fe ff ff       	call   80104258 <outb>
  //    m:  0 = slave PIC, 1 = master PIC
  //      (ignored when b is 0, as the master/slave role
  //      can be hardwired).
  //    a:  1 = Automatic EOI mode
  //    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
  outb(IO_PIC1+1, 0x3);
80104360:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80104367:	00 
80104368:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
8010436f:	e8 e4 fe ff ff       	call   80104258 <outb>

  // Set up slave (8259A-2)
  outb(IO_PIC2, 0x11);                  // ICW1
80104374:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
8010437b:	00 
8010437c:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104383:	e8 d0 fe ff ff       	call   80104258 <outb>
  outb(IO_PIC2+1, T_IRQ0 + 8);      // ICW2
80104388:	c7 44 24 04 28 00 00 	movl   $0x28,0x4(%esp)
8010438f:	00 
80104390:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104397:	e8 bc fe ff ff       	call   80104258 <outb>
  outb(IO_PIC2+1, IRQ_SLAVE);           // ICW3
8010439c:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
801043a3:	00 
801043a4:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
801043ab:	e8 a8 fe ff ff       	call   80104258 <outb>
  // NB Automatic EOI mode doesn't tend to work on the slave.
  // Linux source code says it's "to be investigated".
  outb(IO_PIC2+1, 0x3);                 // ICW4
801043b0:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
801043b7:	00 
801043b8:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
801043bf:	e8 94 fe ff ff       	call   80104258 <outb>

  // OCW3:  0ef01prs
  //   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
  //    p:  0 = no polling, 1 = polling mode
  //   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
  outb(IO_PIC1, 0x68);             // clear specific mask
801043c4:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
801043cb:	00 
801043cc:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
801043d3:	e8 80 fe ff ff       	call   80104258 <outb>
  outb(IO_PIC1, 0x0a);             // read IRR by default
801043d8:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
801043df:	00 
801043e0:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
801043e7:	e8 6c fe ff ff       	call   80104258 <outb>

  outb(IO_PIC2, 0x68);             // OCW3
801043ec:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
801043f3:	00 
801043f4:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
801043fb:	e8 58 fe ff ff       	call   80104258 <outb>
  outb(IO_PIC2, 0x0a);             // OCW3
80104400:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80104407:	00 
80104408:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
8010440f:	e8 44 fe ff ff       	call   80104258 <outb>

  if(irqmask != 0xFFFF)
80104414:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
8010441b:	66 83 f8 ff          	cmp    $0xffff,%ax
8010441f:	74 12                	je     80104433 <picinit+0x13d>
    picsetmask(irqmask);
80104421:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
80104428:	0f b7 c0             	movzwl %ax,%eax
8010442b:	89 04 24             	mov    %eax,(%esp)
8010442e:	e8 43 fe ff ff       	call   80104276 <picsetmask>
}
80104433:	c9                   	leave  
80104434:	c3                   	ret    
80104435:	00 00                	add    %al,(%eax)
	...

80104438 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80104438:	55                   	push   %ebp
80104439:	89 e5                	mov    %esp,%ebp
8010443b:	83 ec 28             	sub    $0x28,%esp
  struct pipe *p;

  p = 0;
8010443e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
80104445:	8b 45 0c             	mov    0xc(%ebp),%eax
80104448:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
8010444e:	8b 45 0c             	mov    0xc(%ebp),%eax
80104451:	8b 10                	mov    (%eax),%edx
80104453:	8b 45 08             	mov    0x8(%ebp),%eax
80104456:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80104458:	e8 bf ca ff ff       	call   80100f1c <filealloc>
8010445d:	8b 55 08             	mov    0x8(%ebp),%edx
80104460:	89 02                	mov    %eax,(%edx)
80104462:	8b 45 08             	mov    0x8(%ebp),%eax
80104465:	8b 00                	mov    (%eax),%eax
80104467:	85 c0                	test   %eax,%eax
80104469:	0f 84 c8 00 00 00    	je     80104537 <pipealloc+0xff>
8010446f:	e8 a8 ca ff ff       	call   80100f1c <filealloc>
80104474:	8b 55 0c             	mov    0xc(%ebp),%edx
80104477:	89 02                	mov    %eax,(%edx)
80104479:	8b 45 0c             	mov    0xc(%ebp),%eax
8010447c:	8b 00                	mov    (%eax),%eax
8010447e:	85 c0                	test   %eax,%eax
80104480:	0f 84 b1 00 00 00    	je     80104537 <pipealloc+0xff>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
80104486:	e8 85 e6 ff ff       	call   80102b10 <kalloc>
8010448b:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010448e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104492:	0f 84 9e 00 00 00    	je     80104536 <pipealloc+0xfe>
    goto bad;
  p->readopen = 1;
80104498:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010449b:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
801044a2:	00 00 00 
  p->writeopen = 1;
801044a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044a8:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
801044af:	00 00 00 
  p->nwrite = 0;
801044b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044b5:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
801044bc:	00 00 00 
  p->nread = 0;
801044bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044c2:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
801044c9:	00 00 00 
  initlock(&p->lock, "pipe");
801044cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044cf:	c7 44 24 04 48 9a 10 	movl   $0x80109a48,0x4(%esp)
801044d6:	80 
801044d7:	89 04 24             	mov    %eax,(%esp)
801044da:	e8 93 16 00 00       	call   80105b72 <initlock>
  (*f0)->type = FD_PIPE;
801044df:	8b 45 08             	mov    0x8(%ebp),%eax
801044e2:	8b 00                	mov    (%eax),%eax
801044e4:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
801044ea:	8b 45 08             	mov    0x8(%ebp),%eax
801044ed:	8b 00                	mov    (%eax),%eax
801044ef:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
801044f3:	8b 45 08             	mov    0x8(%ebp),%eax
801044f6:	8b 00                	mov    (%eax),%eax
801044f8:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
801044fc:	8b 45 08             	mov    0x8(%ebp),%eax
801044ff:	8b 00                	mov    (%eax),%eax
80104501:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104504:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
80104507:	8b 45 0c             	mov    0xc(%ebp),%eax
8010450a:	8b 00                	mov    (%eax),%eax
8010450c:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80104512:	8b 45 0c             	mov    0xc(%ebp),%eax
80104515:	8b 00                	mov    (%eax),%eax
80104517:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
8010451b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010451e:	8b 00                	mov    (%eax),%eax
80104520:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80104524:	8b 45 0c             	mov    0xc(%ebp),%eax
80104527:	8b 00                	mov    (%eax),%eax
80104529:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010452c:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
8010452f:	b8 00 00 00 00       	mov    $0x0,%eax
80104534:	eb 43                	jmp    80104579 <pipealloc+0x141>
  p = 0;
  *f0 = *f1 = 0;
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
    goto bad;
80104536:	90                   	nop
  (*f1)->pipe = p;
  return 0;

//PAGEBREAK: 20
 bad:
  if(p)
80104537:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010453b:	74 0b                	je     80104548 <pipealloc+0x110>
    kfree((char*)p);
8010453d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104540:	89 04 24             	mov    %eax,(%esp)
80104543:	e8 2f e5 ff ff       	call   80102a77 <kfree>
  if(*f0)
80104548:	8b 45 08             	mov    0x8(%ebp),%eax
8010454b:	8b 00                	mov    (%eax),%eax
8010454d:	85 c0                	test   %eax,%eax
8010454f:	74 0d                	je     8010455e <pipealloc+0x126>
    fileclose(*f0);
80104551:	8b 45 08             	mov    0x8(%ebp),%eax
80104554:	8b 00                	mov    (%eax),%eax
80104556:	89 04 24             	mov    %eax,(%esp)
80104559:	e8 66 ca ff ff       	call   80100fc4 <fileclose>
  if(*f1)
8010455e:	8b 45 0c             	mov    0xc(%ebp),%eax
80104561:	8b 00                	mov    (%eax),%eax
80104563:	85 c0                	test   %eax,%eax
80104565:	74 0d                	je     80104574 <pipealloc+0x13c>
    fileclose(*f1);
80104567:	8b 45 0c             	mov    0xc(%ebp),%eax
8010456a:	8b 00                	mov    (%eax),%eax
8010456c:	89 04 24             	mov    %eax,(%esp)
8010456f:	e8 50 ca ff ff       	call   80100fc4 <fileclose>
  return -1;
80104574:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104579:	c9                   	leave  
8010457a:	c3                   	ret    

8010457b <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
8010457b:	55                   	push   %ebp
8010457c:	89 e5                	mov    %esp,%ebp
8010457e:	83 ec 18             	sub    $0x18,%esp
  acquire(&p->lock);
80104581:	8b 45 08             	mov    0x8(%ebp),%eax
80104584:	89 04 24             	mov    %eax,(%esp)
80104587:	e8 07 16 00 00       	call   80105b93 <acquire>
  if(writable){
8010458c:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80104590:	74 1f                	je     801045b1 <pipeclose+0x36>
    p->writeopen = 0;
80104592:	8b 45 08             	mov    0x8(%ebp),%eax
80104595:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
8010459c:	00 00 00 
    wakeup(&p->nread);
8010459f:	8b 45 08             	mov    0x8(%ebp),%eax
801045a2:	05 34 02 00 00       	add    $0x234,%eax
801045a7:	89 04 24             	mov    %eax,(%esp)
801045aa:	e8 b6 12 00 00       	call   80105865 <wakeup>
801045af:	eb 1d                	jmp    801045ce <pipeclose+0x53>
  } else {
    p->readopen = 0;
801045b1:	8b 45 08             	mov    0x8(%ebp),%eax
801045b4:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
801045bb:	00 00 00 
    wakeup(&p->nwrite);
801045be:	8b 45 08             	mov    0x8(%ebp),%eax
801045c1:	05 38 02 00 00       	add    $0x238,%eax
801045c6:	89 04 24             	mov    %eax,(%esp)
801045c9:	e8 97 12 00 00       	call   80105865 <wakeup>
  }
  if(p->readopen == 0 && p->writeopen == 0){
801045ce:	8b 45 08             	mov    0x8(%ebp),%eax
801045d1:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
801045d7:	85 c0                	test   %eax,%eax
801045d9:	75 25                	jne    80104600 <pipeclose+0x85>
801045db:	8b 45 08             	mov    0x8(%ebp),%eax
801045de:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
801045e4:	85 c0                	test   %eax,%eax
801045e6:	75 18                	jne    80104600 <pipeclose+0x85>
    release(&p->lock);
801045e8:	8b 45 08             	mov    0x8(%ebp),%eax
801045eb:	89 04 24             	mov    %eax,(%esp)
801045ee:	e8 3b 16 00 00       	call   80105c2e <release>
    kfree((char*)p);
801045f3:	8b 45 08             	mov    0x8(%ebp),%eax
801045f6:	89 04 24             	mov    %eax,(%esp)
801045f9:	e8 79 e4 ff ff       	call   80102a77 <kfree>
801045fe:	eb 0b                	jmp    8010460b <pipeclose+0x90>
  } else
    release(&p->lock);
80104600:	8b 45 08             	mov    0x8(%ebp),%eax
80104603:	89 04 24             	mov    %eax,(%esp)
80104606:	e8 23 16 00 00       	call   80105c2e <release>
}
8010460b:	c9                   	leave  
8010460c:	c3                   	ret    

8010460d <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
8010460d:	55                   	push   %ebp
8010460e:	89 e5                	mov    %esp,%ebp
80104610:	53                   	push   %ebx
80104611:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80104614:	8b 45 08             	mov    0x8(%ebp),%eax
80104617:	89 04 24             	mov    %eax,(%esp)
8010461a:	e8 74 15 00 00       	call   80105b93 <acquire>
  for(i = 0; i < n; i++){
8010461f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104626:	e9 a6 00 00 00       	jmp    801046d1 <pipewrite+0xc4>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
      if(p->readopen == 0 || proc->killed){
8010462b:	8b 45 08             	mov    0x8(%ebp),%eax
8010462e:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80104634:	85 c0                	test   %eax,%eax
80104636:	74 0d                	je     80104645 <pipewrite+0x38>
80104638:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010463e:	8b 40 24             	mov    0x24(%eax),%eax
80104641:	85 c0                	test   %eax,%eax
80104643:	74 15                	je     8010465a <pipewrite+0x4d>
        release(&p->lock);
80104645:	8b 45 08             	mov    0x8(%ebp),%eax
80104648:	89 04 24             	mov    %eax,(%esp)
8010464b:	e8 de 15 00 00       	call   80105c2e <release>
        return -1;
80104650:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104655:	e9 9d 00 00 00       	jmp    801046f7 <pipewrite+0xea>
      }
      wakeup(&p->nread);
8010465a:	8b 45 08             	mov    0x8(%ebp),%eax
8010465d:	05 34 02 00 00       	add    $0x234,%eax
80104662:	89 04 24             	mov    %eax,(%esp)
80104665:	e8 fb 11 00 00       	call   80105865 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
8010466a:	8b 45 08             	mov    0x8(%ebp),%eax
8010466d:	8b 55 08             	mov    0x8(%ebp),%edx
80104670:	81 c2 38 02 00 00    	add    $0x238,%edx
80104676:	89 44 24 04          	mov    %eax,0x4(%esp)
8010467a:	89 14 24             	mov    %edx,(%esp)
8010467d:	e8 71 10 00 00       	call   801056f3 <sleep>
80104682:	eb 01                	jmp    80104685 <pipewrite+0x78>
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80104684:	90                   	nop
80104685:	8b 45 08             	mov    0x8(%ebp),%eax
80104688:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
8010468e:	8b 45 08             	mov    0x8(%ebp),%eax
80104691:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80104697:	05 00 02 00 00       	add    $0x200,%eax
8010469c:	39 c2                	cmp    %eax,%edx
8010469e:	74 8b                	je     8010462b <pipewrite+0x1e>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
801046a0:	8b 45 08             	mov    0x8(%ebp),%eax
801046a3:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
801046a9:	89 c3                	mov    %eax,%ebx
801046ab:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
801046b1:	8b 55 f4             	mov    -0xc(%ebp),%edx
801046b4:	03 55 0c             	add    0xc(%ebp),%edx
801046b7:	0f b6 0a             	movzbl (%edx),%ecx
801046ba:	8b 55 08             	mov    0x8(%ebp),%edx
801046bd:	88 4c 1a 34          	mov    %cl,0x34(%edx,%ebx,1)
801046c1:	8d 50 01             	lea    0x1(%eax),%edx
801046c4:	8b 45 08             	mov    0x8(%ebp),%eax
801046c7:	89 90 38 02 00 00    	mov    %edx,0x238(%eax)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
801046cd:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801046d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046d4:	3b 45 10             	cmp    0x10(%ebp),%eax
801046d7:	7c ab                	jl     80104684 <pipewrite+0x77>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
801046d9:	8b 45 08             	mov    0x8(%ebp),%eax
801046dc:	05 34 02 00 00       	add    $0x234,%eax
801046e1:	89 04 24             	mov    %eax,(%esp)
801046e4:	e8 7c 11 00 00       	call   80105865 <wakeup>
  release(&p->lock);
801046e9:	8b 45 08             	mov    0x8(%ebp),%eax
801046ec:	89 04 24             	mov    %eax,(%esp)
801046ef:	e8 3a 15 00 00       	call   80105c2e <release>
  return n;
801046f4:	8b 45 10             	mov    0x10(%ebp),%eax
}
801046f7:	83 c4 24             	add    $0x24,%esp
801046fa:	5b                   	pop    %ebx
801046fb:	5d                   	pop    %ebp
801046fc:	c3                   	ret    

801046fd <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
801046fd:	55                   	push   %ebp
801046fe:	89 e5                	mov    %esp,%ebp
80104700:	53                   	push   %ebx
80104701:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80104704:	8b 45 08             	mov    0x8(%ebp),%eax
80104707:	89 04 24             	mov    %eax,(%esp)
8010470a:	e8 84 14 00 00       	call   80105b93 <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
8010470f:	eb 3a                	jmp    8010474b <piperead+0x4e>
    if(proc->killed){
80104711:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104717:	8b 40 24             	mov    0x24(%eax),%eax
8010471a:	85 c0                	test   %eax,%eax
8010471c:	74 15                	je     80104733 <piperead+0x36>
      release(&p->lock);
8010471e:	8b 45 08             	mov    0x8(%ebp),%eax
80104721:	89 04 24             	mov    %eax,(%esp)
80104724:	e8 05 15 00 00       	call   80105c2e <release>
      return -1;
80104729:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010472e:	e9 b6 00 00 00       	jmp    801047e9 <piperead+0xec>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
80104733:	8b 45 08             	mov    0x8(%ebp),%eax
80104736:	8b 55 08             	mov    0x8(%ebp),%edx
80104739:	81 c2 34 02 00 00    	add    $0x234,%edx
8010473f:	89 44 24 04          	mov    %eax,0x4(%esp)
80104743:	89 14 24             	mov    %edx,(%esp)
80104746:	e8 a8 0f 00 00       	call   801056f3 <sleep>
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
8010474b:	8b 45 08             	mov    0x8(%ebp),%eax
8010474e:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80104754:	8b 45 08             	mov    0x8(%ebp),%eax
80104757:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
8010475d:	39 c2                	cmp    %eax,%edx
8010475f:	75 0d                	jne    8010476e <piperead+0x71>
80104761:	8b 45 08             	mov    0x8(%ebp),%eax
80104764:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
8010476a:	85 c0                	test   %eax,%eax
8010476c:	75 a3                	jne    80104711 <piperead+0x14>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
8010476e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104775:	eb 49                	jmp    801047c0 <piperead+0xc3>
    if(p->nread == p->nwrite)
80104777:	8b 45 08             	mov    0x8(%ebp),%eax
8010477a:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80104780:	8b 45 08             	mov    0x8(%ebp),%eax
80104783:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104789:	39 c2                	cmp    %eax,%edx
8010478b:	74 3d                	je     801047ca <piperead+0xcd>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
8010478d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104790:	89 c2                	mov    %eax,%edx
80104792:	03 55 0c             	add    0xc(%ebp),%edx
80104795:	8b 45 08             	mov    0x8(%ebp),%eax
80104798:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
8010479e:	89 c3                	mov    %eax,%ebx
801047a0:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
801047a6:	8b 4d 08             	mov    0x8(%ebp),%ecx
801047a9:	0f b6 4c 19 34       	movzbl 0x34(%ecx,%ebx,1),%ecx
801047ae:	88 0a                	mov    %cl,(%edx)
801047b0:	8d 50 01             	lea    0x1(%eax),%edx
801047b3:	8b 45 08             	mov    0x8(%ebp),%eax
801047b6:	89 90 34 02 00 00    	mov    %edx,0x234(%eax)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801047bc:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801047c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047c3:	3b 45 10             	cmp    0x10(%ebp),%eax
801047c6:	7c af                	jl     80104777 <piperead+0x7a>
801047c8:	eb 01                	jmp    801047cb <piperead+0xce>
    if(p->nread == p->nwrite)
      break;
801047ca:	90                   	nop
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
801047cb:	8b 45 08             	mov    0x8(%ebp),%eax
801047ce:	05 38 02 00 00       	add    $0x238,%eax
801047d3:	89 04 24             	mov    %eax,(%esp)
801047d6:	e8 8a 10 00 00       	call   80105865 <wakeup>
  release(&p->lock);
801047db:	8b 45 08             	mov    0x8(%ebp),%eax
801047de:	89 04 24             	mov    %eax,(%esp)
801047e1:	e8 48 14 00 00       	call   80105c2e <release>
  return i;
801047e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801047e9:	83 c4 24             	add    $0x24,%esp
801047ec:	5b                   	pop    %ebx
801047ed:	5d                   	pop    %ebp
801047ee:	c3                   	ret    
	...

801047f0 <p2v>:
801047f0:	55                   	push   %ebp
801047f1:	89 e5                	mov    %esp,%ebp
801047f3:	8b 45 08             	mov    0x8(%ebp),%eax
801047f6:	05 00 00 00 80       	add    $0x80000000,%eax
801047fb:	5d                   	pop    %ebp
801047fc:	c3                   	ret    

801047fd <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
801047fd:	55                   	push   %ebp
801047fe:	89 e5                	mov    %esp,%ebp
80104800:	53                   	push   %ebx
80104801:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80104804:	9c                   	pushf  
80104805:	5b                   	pop    %ebx
80104806:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80104809:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
8010480c:	83 c4 10             	add    $0x10,%esp
8010480f:	5b                   	pop    %ebx
80104810:	5d                   	pop    %ebp
80104811:	c3                   	ret    

80104812 <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
80104812:	55                   	push   %ebp
80104813:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80104815:	fb                   	sti    
}
80104816:	5d                   	pop    %ebp
80104817:	c3                   	ret    

80104818 <pinit>:

static void wakeup1(void *chan);

void
pinit(void)
{
80104818:	55                   	push   %ebp
80104819:	89 e5                	mov    %esp,%ebp
8010481b:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
8010481e:	c7 44 24 04 50 9a 10 	movl   $0x80109a50,0x4(%esp)
80104825:	80 
80104826:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
8010482d:	e8 40 13 00 00       	call   80105b72 <initlock>
  initlock(&swaplock, "swaplock");
80104832:	c7 44 24 04 57 9a 10 	movl   $0x80109a57,0x4(%esp)
80104839:	80 
8010483a:	c7 04 24 a0 c6 10 80 	movl   $0x8010c6a0,(%esp)
80104841:	e8 2c 13 00 00       	call   80105b72 <initlock>
}
80104846:	c9                   	leave  
80104847:	c3                   	ret    

80104848 <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
80104848:	55                   	push   %ebp
80104849:	89 e5                	mov    %esp,%ebp
8010484b:	83 ec 38             	sub    $0x38,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
8010484e:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
80104855:	e8 39 13 00 00       	call   80105b93 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010485a:	c7 45 f4 74 77 12 80 	movl   $0x80127774,-0xc(%ebp)
80104861:	eb 11                	jmp    80104874 <allocproc+0x2c>
    if(p->state == UNUSED)
80104863:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104866:	8b 40 0c             	mov    0xc(%eax),%eax
80104869:	85 c0                	test   %eax,%eax
8010486b:	74 26                	je     80104893 <allocproc+0x4b>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010486d:	81 45 f4 90 00 00 00 	addl   $0x90,-0xc(%ebp)
80104874:	81 7d f4 74 9b 12 80 	cmpl   $0x80129b74,-0xc(%ebp)
8010487b:	72 e6                	jb     80104863 <allocproc+0x1b>
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
8010487d:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
80104884:	e8 a5 13 00 00       	call   80105c2e <release>
  return 0;
80104889:	b8 00 00 00 00       	mov    $0x0,%eax
8010488e:	e9 5a 01 00 00       	jmp    801049ed <allocproc+0x1a5>
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
    if(p->state == UNUSED)
      goto found;
80104893:	90                   	nop
  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
80104894:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104897:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
  p->pid = nextpid++;
8010489e:	a1 04 c0 10 80       	mov    0x8010c004,%eax
801048a3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801048a6:	89 42 10             	mov    %eax,0x10(%edx)
801048a9:	83 c0 01             	add    $0x1,%eax
801048ac:	a3 04 c0 10 80       	mov    %eax,0x8010c004
  release(&ptable.lock);
801048b1:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
801048b8:	e8 71 13 00 00       	call   80105c2e <release>

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
801048bd:	e8 4e e2 ff ff       	call   80102b10 <kalloc>
801048c2:	8b 55 f4             	mov    -0xc(%ebp),%edx
801048c5:	89 42 08             	mov    %eax,0x8(%edx)
801048c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048cb:	8b 40 08             	mov    0x8(%eax),%eax
801048ce:	85 c0                	test   %eax,%eax
801048d0:	75 14                	jne    801048e6 <allocproc+0x9e>
    p->state = UNUSED;
801048d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048d5:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return 0;
801048dc:	b8 00 00 00 00       	mov    $0x0,%eax
801048e1:	e9 07 01 00 00       	jmp    801049ed <allocproc+0x1a5>
  }
  sp = p->kstack + KSTACKSIZE;
801048e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048e9:	8b 40 08             	mov    0x8(%eax),%eax
801048ec:	05 00 10 00 00       	add    $0x1000,%eax
801048f1:	89 45 f0             	mov    %eax,-0x10(%ebp)
  
  // Leave room for trap frame.
  sp -= sizeof *p->tf;
801048f4:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
  p->tf = (struct trapframe*)sp;
801048f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048fb:	8b 55 f0             	mov    -0x10(%ebp),%edx
801048fe:	89 50 18             	mov    %edx,0x18(%eax)
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
80104901:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
  *(uint*)sp = (uint)trapret;
80104905:	ba 7c 77 10 80       	mov    $0x8010777c,%edx
8010490a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010490d:	89 10                	mov    %edx,(%eax)

  sp -= sizeof *p->context;
8010490f:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
  p->context = (struct context*)sp;
80104913:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104916:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104919:	89 50 1c             	mov    %edx,0x1c(%eax)
  memset(p->context, 0, sizeof *p->context);
8010491c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010491f:	8b 40 1c             	mov    0x1c(%eax),%eax
80104922:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80104929:	00 
8010492a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104931:	00 
80104932:	89 04 24             	mov    %eax,(%esp)
80104935:	e8 e0 14 00 00       	call   80105e1a <memset>
  p->context->eip = (uint)forkret;
8010493a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010493d:	8b 40 1c             	mov    0x1c(%eax),%eax
80104940:	ba c7 56 10 80       	mov    $0x801056c7,%edx
80104945:	89 50 10             	mov    %edx,0x10(%eax)
  int i = 0;						//added a swpFileName field to each proc which is determined on proc creation
80104948:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  char name[8];
  name[2] = '.'; name[3] = 's'; name[4] = 'w'; name[5] = 'a'; name[6] = 'p'; name[7] = 0;
8010494f:	c6 45 e6 2e          	movb   $0x2e,-0x1a(%ebp)
80104953:	c6 45 e7 73          	movb   $0x73,-0x19(%ebp)
80104957:	c6 45 e8 77          	movb   $0x77,-0x18(%ebp)
8010495b:	c6 45 e9 61          	movb   $0x61,-0x17(%ebp)
8010495f:	c6 45 ea 70          	movb   $0x70,-0x16(%ebp)
80104963:	c6 45 eb 00          	movb   $0x0,-0x15(%ebp)
  name[1] = (char)(((int)'0')+p->pid % 10);
80104967:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010496a:	8b 48 10             	mov    0x10(%eax),%ecx
8010496d:	ba 67 66 66 66       	mov    $0x66666667,%edx
80104972:	89 c8                	mov    %ecx,%eax
80104974:	f7 ea                	imul   %edx
80104976:	c1 fa 02             	sar    $0x2,%edx
80104979:	89 c8                	mov    %ecx,%eax
8010497b:	c1 f8 1f             	sar    $0x1f,%eax
8010497e:	29 c2                	sub    %eax,%edx
80104980:	89 d0                	mov    %edx,%eax
80104982:	c1 e0 02             	shl    $0x2,%eax
80104985:	01 d0                	add    %edx,%eax
80104987:	01 c0                	add    %eax,%eax
80104989:	89 ca                	mov    %ecx,%edx
8010498b:	29 c2                	sub    %eax,%edx
8010498d:	89 d0                	mov    %edx,%eax
8010498f:	83 c0 30             	add    $0x30,%eax
80104992:	88 45 e5             	mov    %al,-0x1b(%ebp)
  if((i=p->pid/10) == 0)
80104995:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104998:	8b 48 10             	mov    0x10(%eax),%ecx
8010499b:	ba 67 66 66 66       	mov    $0x66666667,%edx
801049a0:	89 c8                	mov    %ecx,%eax
801049a2:	f7 ea                	imul   %edx
801049a4:	c1 fa 02             	sar    $0x2,%edx
801049a7:	89 c8                	mov    %ecx,%eax
801049a9:	c1 f8 1f             	sar    $0x1f,%eax
801049ac:	89 d1                	mov    %edx,%ecx
801049ae:	29 c1                	sub    %eax,%ecx
801049b0:	89 c8                	mov    %ecx,%eax
801049b2:	89 45 ec             	mov    %eax,-0x14(%ebp)
801049b5:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801049b9:	75 06                	jne    801049c1 <allocproc+0x179>
    name[0] = '0';
801049bb:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
801049bf:	eb 09                	jmp    801049ca <allocproc+0x182>
  else
    name[0] = (char)(((int)'0')+i);
801049c1:	8b 45 ec             	mov    -0x14(%ebp),%eax
801049c4:	83 c0 30             	add    $0x30,%eax
801049c7:	88 45 e4             	mov    %al,-0x1c(%ebp)
  //release(&ptable.lock);
  safestrcpy(p->swapFileName, name, sizeof(name));
801049ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049cd:	8d 90 80 00 00 00    	lea    0x80(%eax),%edx
801049d3:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
801049da:	00 
801049db:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801049de:	89 44 24 04          	mov    %eax,0x4(%esp)
801049e2:	89 14 24             	mov    %edx,(%esp)
801049e5:	e8 60 16 00 00       	call   8010604a <safestrcpy>
  return p;
801049ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801049ed:	c9                   	leave  
801049ee:	c3                   	ret    

801049ef <createInternalProcess>:


void createInternalProcess(const char *name, void (*entrypoint)())		//create a kernel process
{
801049ef:	55                   	push   %ebp
801049f0:	89 e5                	mov    %esp,%ebp
801049f2:	83 ec 28             	sub    $0x28,%esp
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
801049f5:	e8 4e fe ff ff       	call   80104848 <allocproc>
801049fa:	89 45 f4             	mov    %eax,-0xc(%ebp)
801049fd:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104a01:	0f 84 f7 00 00 00    	je     80104afe <createInternalProcess+0x10f>
    return;

  // Copy process state from p.
  if((np->pgdir = setupkvm(kalloc)) == 0)
80104a07:	c7 04 24 10 2b 10 80 	movl   $0x80102b10,(%esp)
80104a0e:	e8 66 44 00 00       	call   80108e79 <setupkvm>
80104a13:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104a16:	89 42 04             	mov    %eax,0x4(%edx)
80104a19:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a1c:	8b 40 04             	mov    0x4(%eax),%eax
80104a1f:	85 c0                	test   %eax,%eax
80104a21:	75 0c                	jne    80104a2f <createInternalProcess+0x40>
      panic("inswapper: out of memory?");
80104a23:	c7 04 24 60 9a 10 80 	movl   $0x80109a60,(%esp)
80104a2a:	e8 0e bb ff ff       	call   8010053d <panic>

  np->sz = PGSIZE;
80104a2f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a32:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  np->parent = initproc;				//set parent to init
80104a38:	8b 15 88 c6 10 80    	mov    0x8010c688,%edx
80104a3e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a41:	89 50 14             	mov    %edx,0x14(%eax)
  memset(np->tf, 0, sizeof(*np->tf));
80104a44:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a47:	8b 40 18             	mov    0x18(%eax),%eax
80104a4a:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
80104a51:	00 
80104a52:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104a59:	00 
80104a5a:	89 04 24             	mov    %eax,(%esp)
80104a5d:	e8 b8 13 00 00       	call   80105e1a <memset>
  np->tf->cs = (SEG_KCODE << 3)|0;
80104a62:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a65:	8b 40 18             	mov    0x18(%eax),%eax
80104a68:	66 c7 40 3c 08 00    	movw   $0x8,0x3c(%eax)
  np->tf->ds = (SEG_KDATA << 3)|0;
80104a6e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a71:	8b 40 18             	mov    0x18(%eax),%eax
80104a74:	66 c7 40 2c 10 00    	movw   $0x10,0x2c(%eax)
  np->tf->es = np->tf->ds;
80104a7a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a7d:	8b 40 18             	mov    0x18(%eax),%eax
80104a80:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104a83:	8b 52 18             	mov    0x18(%edx),%edx
80104a86:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104a8a:	66 89 50 28          	mov    %dx,0x28(%eax)
  np->tf->ss = np->tf->ds;
80104a8e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a91:	8b 40 18             	mov    0x18(%eax),%eax
80104a94:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104a97:	8b 52 18             	mov    0x18(%edx),%edx
80104a9a:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104a9e:	66 89 50 48          	mov    %dx,0x48(%eax)
  np->tf->eflags = FL_IF;
80104aa2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104aa5:	8b 40 18             	mov    0x18(%eax),%eax
80104aa8:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  //np->tf->esp = (uint)entrypoint+PGSIZE;
  //np->tf->eip = (uint)entrypoint;
  np->context->eip = (uint)entrypoint;			//set eip to entrypoint so proc will start running there
80104aaf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ab2:	8b 40 1c             	mov    0x1c(%eax),%eax
80104ab5:	8b 55 0c             	mov    0xc(%ebp),%edx
80104ab8:	89 50 10             	mov    %edx,0x10(%eax)

  inswapper = np;
80104abb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104abe:	a3 8c c6 10 80       	mov    %eax,0x8010c68c
  np->cwd = namei("/");					//set cwd to root so all swap files are created there
80104ac3:	c7 04 24 7a 9a 10 80 	movl   $0x80109a7a,(%esp)
80104aca:	e8 3b d9 ff ff       	call   8010240a <namei>
80104acf:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104ad2:	89 42 68             	mov    %eax,0x68(%edx)
  safestrcpy(np->name, name, sizeof(name));
80104ad5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ad8:	8d 50 6c             	lea    0x6c(%eax),%edx
80104adb:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80104ae2:	00 
80104ae3:	8b 45 08             	mov    0x8(%ebp),%eax
80104ae6:	89 44 24 04          	mov    %eax,0x4(%esp)
80104aea:	89 14 24             	mov    %edx,(%esp)
80104aed:	e8 58 15 00 00       	call   8010604a <safestrcpy>
  np->state = RUNNABLE;
80104af2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104af5:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
80104afc:	eb 01                	jmp    80104aff <createInternalProcess+0x110>
{
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
    return;
80104afe:	90                   	nop

  inswapper = np;
  np->cwd = namei("/");					//set cwd to root so all swap files are created there
  safestrcpy(np->name, name, sizeof(name));
  np->state = RUNNABLE;
}
80104aff:	c9                   	leave  
80104b00:	c3                   	ret    

80104b01 <swapIn>:

void swapIn()						//the inswapper's function
{
80104b01:	55                   	push   %ebp
80104b02:	89 e5                	mov    %esp,%ebp
80104b04:	83 ec 38             	sub    $0x38,%esp
  struct proc* t;
  for(;;)
  {
swapin:
    for(t = ptable.proc; t < &ptable.proc[NPROC]; t++)	//run over all of ptable and look for RUNNABLE_SUSPENDED
80104b07:	c7 45 f4 74 77 12 80 	movl   $0x80127774,-0xc(%ebp)
80104b0e:	e9 d7 01 00 00       	jmp    80104cea <swapIn+0x1e9>
    {
      if(t->state != RUNNABLE_SUSPENDED)
80104b13:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b16:	8b 40 0c             	mov    0xc(%eax),%eax
80104b19:	83 f8 07             	cmp    $0x7,%eax
80104b1c:	0f 85 c0 01 00 00    	jne    80104ce2 <swapIn+0x1e1>
	continue;
      
      //open file pid.swap
      if(holding(&ptable.lock))				//release ptable before every file operation and acquire it afterwards
80104b22:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
80104b29:	e8 bc 11 00 00       	call   80105cea <holding>
80104b2e:	85 c0                	test   %eax,%eax
80104b30:	74 0c                	je     80104b3e <swapIn+0x3d>
	release(&ptable.lock);
80104b32:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
80104b39:	e8 f0 10 00 00       	call   80105c2e <release>
      if((t->swap = fileopen(t->swapFileName,O_RDONLY)) == 0)	//open the swapfile
80104b3e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b41:	83 e8 80             	sub    $0xffffff80,%eax
80104b44:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104b4b:	00 
80104b4c:	89 04 24             	mov    %eax,(%esp)
80104b4f:	e8 a7 21 00 00       	call   80106cfb <fileopen>
80104b54:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104b57:	89 42 7c             	mov    %eax,0x7c(%edx)
80104b5a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b5d:	8b 40 7c             	mov    0x7c(%eax),%eax
80104b60:	85 c0                	test   %eax,%eax
80104b62:	75 1d                	jne    80104b81 <swapIn+0x80>
      {
	cprintf("fileopen failed\n");
80104b64:	c7 04 24 7c 9a 10 80 	movl   $0x80109a7c,(%esp)
80104b6b:	e8 31 b8 ff ff       	call   801003a1 <cprintf>
	acquire(&ptable.lock);
80104b70:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
80104b77:	e8 17 10 00 00       	call   80105b93 <acquire>
	break;
80104b7c:	e9 76 01 00 00       	jmp    80104cf7 <swapIn+0x1f6>
      }
      acquire(&ptable.lock);
80104b81:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
80104b88:	e8 06 10 00 00       	call   80105b93 <acquire>
            
      // allocate virtual memory
//       if((t->pgdir = setupkvm(kalloc)) == 0)			
// 	panic("inswapper: out of memory?");
      if(!allocuvm(t->pgdir, 0, t->sz))				//allocate virtual memory
80104b8d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b90:	8b 10                	mov    (%eax),%edx
80104b92:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b95:	8b 40 04             	mov    0x4(%eax),%eax
80104b98:	89 54 24 08          	mov    %edx,0x8(%esp)
80104b9c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104ba3:	00 
80104ba4:	89 04 24             	mov    %eax,(%esp)
80104ba7:	e8 9f 46 00 00       	call   8010924b <allocuvm>
80104bac:	85 c0                	test   %eax,%eax
80104bae:	75 11                	jne    80104bc1 <swapIn+0xc0>
      {
	cprintf("allocuvm failed\n");
80104bb0:	c7 04 24 8d 9a 10 80 	movl   $0x80109a8d,(%esp)
80104bb7:	e8 e5 b7 ff ff       	call   801003a1 <cprintf>
	break;
80104bbc:	e9 36 01 00 00       	jmp    80104cf7 <swapIn+0x1f6>
      }
      
      if(holding(&ptable.lock))
80104bc1:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
80104bc8:	e8 1d 11 00 00       	call   80105cea <holding>
80104bcd:	85 c0                	test   %eax,%eax
80104bcf:	74 0c                	je     80104bdd <swapIn+0xdc>
	release(&ptable.lock);
80104bd1:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
80104bd8:	e8 51 10 00 00       	call   80105c2e <release>
      loaduvm(t->pgdir,0,t->swap->ip,0,t->sz);			//load the swap file content to memory
80104bdd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104be0:	8b 08                	mov    (%eax),%ecx
80104be2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104be5:	8b 40 7c             	mov    0x7c(%eax),%eax
80104be8:	8b 50 10             	mov    0x10(%eax),%edx
80104beb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104bee:	8b 40 04             	mov    0x4(%eax),%eax
80104bf1:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80104bf5:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80104bfc:	00 
80104bfd:	89 54 24 08          	mov    %edx,0x8(%esp)
80104c01:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104c08:	00 
80104c09:	89 04 24             	mov    %eax,(%esp)
80104c0c:	e8 4b 45 00 00       	call   8010915c <loaduvm>
      
      t->isSwapped = 0;
80104c11:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c14:	c7 80 88 00 00 00 00 	movl   $0x0,0x88(%eax)
80104c1b:	00 00 00 
      int fd;
      for(fd = 0; fd < NOFILE; fd++)
80104c1e:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80104c25:	eb 60                	jmp    80104c87 <swapIn+0x186>
      {
	if(proc->ofile[fd] && proc->ofile[fd] == t->swap)	//close the swap file
80104c27:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c2d:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104c30:	83 c2 08             	add    $0x8,%edx
80104c33:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104c37:	85 c0                	test   %eax,%eax
80104c39:	74 48                	je     80104c83 <swapIn+0x182>
80104c3b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c41:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104c44:	83 c2 08             	add    $0x8,%edx
80104c47:	8b 54 90 08          	mov    0x8(%eax,%edx,4),%edx
80104c4b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c4e:	8b 40 7c             	mov    0x7c(%eax),%eax
80104c51:	39 c2                	cmp    %eax,%edx
80104c53:	75 2e                	jne    80104c83 <swapIn+0x182>
	{
	  fileclose(proc->ofile[fd]);
80104c55:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c5b:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104c5e:	83 c2 08             	add    $0x8,%edx
80104c61:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104c65:	89 04 24             	mov    %eax,(%esp)
80104c68:	e8 57 c3 ff ff       	call   80100fc4 <fileclose>
	  proc->ofile[fd] = 0;
80104c6d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c73:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104c76:	83 c2 08             	add    $0x8,%edx
80104c79:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80104c80:	00 
	  break;
80104c81:	eb 0a                	jmp    80104c8d <swapIn+0x18c>
	release(&ptable.lock);
      loaduvm(t->pgdir,0,t->swap->ip,0,t->sz);			//load the swap file content to memory
      
      t->isSwapped = 0;
      int fd;
      for(fd = 0; fd < NOFILE; fd++)
80104c83:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80104c87:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
80104c8b:	7e 9a                	jle    80104c27 <swapIn+0x126>
	  fileclose(proc->ofile[fd]);
	  proc->ofile[fd] = 0;
	  break;
	}
      }
      t->swap=0;
80104c8d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c90:	c7 40 7c 00 00 00 00 	movl   $0x0,0x7c(%eax)
      unlink(t->swapFileName);					//delete the swap file
80104c97:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c9a:	83 e8 80             	sub    $0xffffff80,%eax
80104c9d:	89 04 24             	mov    %eax,(%esp)
80104ca0:	e8 11 1b 00 00       	call   801067b6 <unlink>
      
      acquire(&ptable.lock);
80104ca5:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
80104cac:	e8 e2 0e 00 00       	call   80105b93 <acquire>
      t->state = RUNNABLE;
80104cb1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104cb4:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      
      acquire(&swaplock);
80104cbb:	c7 04 24 a0 c6 10 80 	movl   $0x8010c6a0,(%esp)
80104cc2:	e8 cc 0e 00 00       	call   80105b93 <acquire>
      swappedout--;						//update swapped out counter atomically
80104cc7:	a1 84 c6 10 80       	mov    0x8010c684,%eax
80104ccc:	83 e8 01             	sub    $0x1,%eax
80104ccf:	a3 84 c6 10 80       	mov    %eax,0x8010c684
      release(&swaplock);
80104cd4:	c7 04 24 a0 c6 10 80 	movl   $0x8010c6a0,(%esp)
80104cdb:	e8 4e 0f 00 00       	call   80105c2e <release>
80104ce0:	eb 01                	jmp    80104ce3 <swapIn+0x1e2>
  {
swapin:
    for(t = ptable.proc; t < &ptable.proc[NPROC]; t++)	//run over all of ptable and look for RUNNABLE_SUSPENDED
    {
      if(t->state != RUNNABLE_SUSPENDED)
	continue;
80104ce2:	90                   	nop
{
  struct proc* t;
  for(;;)
  {
swapin:
    for(t = ptable.proc; t < &ptable.proc[NPROC]; t++)	//run over all of ptable and look for RUNNABLE_SUSPENDED
80104ce3:	81 45 f4 90 00 00 00 	addl   $0x90,-0xc(%ebp)
80104cea:	81 7d f4 74 9b 12 80 	cmpl   $0x80129b74,-0xc(%ebp)
80104cf1:	0f 82 1c fe ff ff    	jb     80104b13 <swapIn+0x12>
      acquire(&swaplock);
      swappedout--;						//update swapped out counter atomically
      release(&swaplock);
    }
   
    acquire(&swaplock);
80104cf7:	c7 04 24 a0 c6 10 80 	movl   $0x8010c6a0,(%esp)
80104cfe:	e8 90 0e 00 00       	call   80105b93 <acquire>
    if(swappedout > 0)						//check if should sleep
80104d03:	a1 84 c6 10 80       	mov    0x8010c684,%eax
80104d08:	85 c0                	test   %eax,%eax
80104d0a:	7e 11                	jle    80104d1d <swapIn+0x21c>
    {
      release(&swaplock);
80104d0c:	c7 04 24 a0 c6 10 80 	movl   $0x8010c6a0,(%esp)
80104d13:	e8 16 0f 00 00       	call   80105c2e <release>
      goto swapin;
80104d18:	e9 ea fd ff ff       	jmp    80104b07 <swapIn+0x6>
    }
    else
      release(&swaplock);
80104d1d:	c7 04 24 a0 c6 10 80 	movl   $0x8010c6a0,(%esp)
80104d24:	e8 05 0f 00 00       	call   80105c2e <release>

    proc->chan = inswapper;
80104d29:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d2f:	8b 15 8c c6 10 80    	mov    0x8010c68c,%edx
80104d35:	89 50 20             	mov    %edx,0x20(%eax)
    proc->state = SLEEPING;					//set inswapper to sleeping
80104d38:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d3e:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
     
     sched();
80104d45:	e8 99 08 00 00       	call   801055e3 <sched>
     proc->chan = 0;
80104d4a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d50:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)
  }
80104d57:	e9 ab fd ff ff       	jmp    80104b07 <swapIn+0x6>

80104d5c <swapOut>:
}

void
swapOut()
{
80104d5c:	55                   	push   %ebp
80104d5d:	89 e5                	mov    %esp,%ebp
80104d5f:	53                   	push   %ebx
80104d60:	83 ec 24             	sub    $0x24,%esp
    proc->swap = fileopen(proc->swapFileName,(O_CREATE | O_RDWR));	//create the swapfile
80104d63:	65 8b 1d 04 00 00 00 	mov    %gs:0x4,%ebx
80104d6a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d70:	83 e8 80             	sub    $0xffffff80,%eax
80104d73:	c7 44 24 04 02 02 00 	movl   $0x202,0x4(%esp)
80104d7a:	00 
80104d7b:	89 04 24             	mov    %eax,(%esp)
80104d7e:	e8 78 1f 00 00       	call   80106cfb <fileopen>
80104d83:	89 43 7c             	mov    %eax,0x7c(%ebx)
    pte_t *pte;
    uint pa, j;
    for(j = 0; j < proc->sz; j += PGSIZE)
80104d86:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104d8d:	e9 ac 00 00 00       	jmp    80104e3e <swapOut+0xe2>
    {
      if((pte = walkpgdir(proc->pgdir, (void *) j, 0)) == 0)		//traverse proc's virtual memory and find valid PTEs 
80104d92:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104d95:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d9b:	8b 40 04             	mov    0x4(%eax),%eax
80104d9e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80104da5:	00 
80104da6:	89 54 24 04          	mov    %edx,0x4(%esp)
80104daa:	89 04 24             	mov    %eax,(%esp)
80104dad:	e8 9d 3f 00 00       	call   80108d4f <walkpgdir>
80104db2:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104db5:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80104db9:	75 0c                	jne    80104dc7 <swapOut+0x6b>
	panic("walkpgdir: pte should exist");
80104dbb:	c7 04 24 9e 9a 10 80 	movl   $0x80109a9e,(%esp)
80104dc2:	e8 76 b7 ff ff       	call   8010053d <panic>
      if(!(*pte & PTE_P))
80104dc7:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104dca:	8b 00                	mov    (%eax),%eax
80104dcc:	83 e0 01             	and    $0x1,%eax
80104dcf:	85 c0                	test   %eax,%eax
80104dd1:	75 0c                	jne    80104ddf <swapOut+0x83>
	panic("walkpgdir: page not present");
80104dd3:	c7 04 24 ba 9a 10 80 	movl   $0x80109aba,(%esp)
80104dda:	e8 5e b7 ff ff       	call   8010053d <panic>
      pa = PTE_ADDR(*pte);
80104ddf:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104de2:	8b 00                	mov    (%eax),%eax
80104de4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80104de9:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(filewrite(proc->swap, (char*)p2v(pa), PGSIZE) < 0){		//write each PTE found to swapfile
80104dec:	8b 45 e8             	mov    -0x18(%ebp),%eax
80104def:	89 04 24             	mov    %eax,(%esp)
80104df2:	e8 f9 f9 ff ff       	call   801047f0 <p2v>
80104df7:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104dfe:	8b 52 7c             	mov    0x7c(%edx),%edx
80104e01:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80104e08:	00 
80104e09:	89 44 24 04          	mov    %eax,0x4(%esp)
80104e0d:	89 14 24             	mov    %edx,(%esp)
80104e10:	e8 90 c3 ff ff       	call   801011a5 <filewrite>
80104e15:	85 c0                	test   %eax,%eax
80104e17:	79 1e                	jns    80104e37 <swapOut+0xdb>
	cprintf("could not swap out proc pid %d, filewrite failed\n",proc->pid);
80104e19:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e1f:	8b 40 10             	mov    0x10(%eax),%eax
80104e22:	89 44 24 04          	mov    %eax,0x4(%esp)
80104e26:	c7 04 24 d8 9a 10 80 	movl   $0x80109ad8,(%esp)
80104e2d:	e8 6f b5 ff ff       	call   801003a1 <cprintf>
	return;
80104e32:	e9 d9 00 00 00       	jmp    80104f10 <swapOut+0x1b4>
swapOut()
{
    proc->swap = fileopen(proc->swapFileName,(O_CREATE | O_RDWR));	//create the swapfile
    pte_t *pte;
    uint pa, j;
    for(j = 0; j < proc->sz; j += PGSIZE)
80104e37:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80104e3e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e44:	8b 00                	mov    (%eax),%eax
80104e46:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104e49:	0f 87 43 ff ff ff    	ja     80104d92 <swapOut+0x36>
	return;
      }
    }

    int fd;
    for(fd = 0; fd < NOFILE; fd++)
80104e4f:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80104e56:	eb 63                	jmp    80104ebb <swapOut+0x15f>
    {
      if(proc->ofile[fd] && proc->ofile[fd] == proc->swap)		//close swapfile
80104e58:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e5e:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104e61:	83 c2 08             	add    $0x8,%edx
80104e64:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104e68:	85 c0                	test   %eax,%eax
80104e6a:	74 4b                	je     80104eb7 <swapOut+0x15b>
80104e6c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e72:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104e75:	83 c2 08             	add    $0x8,%edx
80104e78:	8b 54 90 08          	mov    0x8(%eax,%edx,4),%edx
80104e7c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e82:	8b 40 7c             	mov    0x7c(%eax),%eax
80104e85:	39 c2                	cmp    %eax,%edx
80104e87:	75 2e                	jne    80104eb7 <swapOut+0x15b>
      {
	fileclose(proc->ofile[fd]);
80104e89:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e8f:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104e92:	83 c2 08             	add    $0x8,%edx
80104e95:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104e99:	89 04 24             	mov    %eax,(%esp)
80104e9c:	e8 23 c1 ff ff       	call   80100fc4 <fileclose>
	proc->ofile[fd] = 0;
80104ea1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ea7:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104eaa:	83 c2 08             	add    $0x8,%edx
80104ead:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80104eb4:	00 
	break;
80104eb5:	eb 0a                	jmp    80104ec1 <swapOut+0x165>
	return;
      }
    }

    int fd;
    for(fd = 0; fd < NOFILE; fd++)
80104eb7:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80104ebb:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
80104ebf:	7e 97                	jle    80104e58 <swapOut+0xfc>
	fileclose(proc->ofile[fd]);
	proc->ofile[fd] = 0;
	break;
      }
    }
    proc->swap=0;
80104ec1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ec7:	c7 40 7c 00 00 00 00 	movl   $0x0,0x7c(%eax)
    deallocuvm(proc->pgdir,proc->sz,0);					//release user virtual memory
80104ece:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ed4:	8b 10                	mov    (%eax),%edx
80104ed6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104edc:	8b 40 04             	mov    0x4(%eax),%eax
80104edf:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80104ee6:	00 
80104ee7:	89 54 24 04          	mov    %edx,0x4(%esp)
80104eeb:	89 04 24             	mov    %eax,(%esp)
80104eee:	e8 32 44 00 00       	call   80109325 <deallocuvm>
    proc->state = SLEEPING_SUSPENDED;					//set proc to SLEEPING_SUSPENDED
80104ef3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ef9:	c7 40 0c 06 00 00 00 	movl   $0x6,0xc(%eax)
    proc->isSwapped = 1;						//set flag indicating proc is swapped out
80104f00:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f06:	c7 80 88 00 00 00 01 	movl   $0x1,0x88(%eax)
80104f0d:	00 00 00 
}
80104f10:	83 c4 24             	add    $0x24,%esp
80104f13:	5b                   	pop    %ebx
80104f14:	5d                   	pop    %ebp
80104f15:	c3                   	ret    

80104f16 <userinit>:

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
80104f16:	55                   	push   %ebp
80104f17:	89 e5                	mov    %esp,%ebp
80104f19:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
80104f1c:	e8 27 f9 ff ff       	call   80104848 <allocproc>
80104f21:	89 45 f4             	mov    %eax,-0xc(%ebp)
  initproc = p;
80104f24:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f27:	a3 88 c6 10 80       	mov    %eax,0x8010c688
  if((p->pgdir = setupkvm(kalloc)) == 0)
80104f2c:	c7 04 24 10 2b 10 80 	movl   $0x80102b10,(%esp)
80104f33:	e8 41 3f 00 00       	call   80108e79 <setupkvm>
80104f38:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104f3b:	89 42 04             	mov    %eax,0x4(%edx)
80104f3e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f41:	8b 40 04             	mov    0x4(%eax),%eax
80104f44:	85 c0                	test   %eax,%eax
80104f46:	75 0c                	jne    80104f54 <userinit+0x3e>
    panic("userinit: out of memory?");
80104f48:	c7 04 24 0a 9b 10 80 	movl   $0x80109b0a,(%esp)
80104f4f:	e8 e9 b5 ff ff       	call   8010053d <panic>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80104f54:	ba 2c 00 00 00       	mov    $0x2c,%edx
80104f59:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f5c:	8b 40 04             	mov    0x4(%eax),%eax
80104f5f:	89 54 24 08          	mov    %edx,0x8(%esp)
80104f63:	c7 44 24 04 00 c5 10 	movl   $0x8010c500,0x4(%esp)
80104f6a:	80 
80104f6b:	89 04 24             	mov    %eax,(%esp)
80104f6e:	e8 5e 41 00 00       	call   801090d1 <inituvm>
  p->sz = PGSIZE;
80104f73:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f76:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  memset(p->tf, 0, sizeof(*p->tf));
80104f7c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f7f:	8b 40 18             	mov    0x18(%eax),%eax
80104f82:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
80104f89:	00 
80104f8a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104f91:	00 
80104f92:	89 04 24             	mov    %eax,(%esp)
80104f95:	e8 80 0e 00 00       	call   80105e1a <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
80104f9a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f9d:	8b 40 18             	mov    0x18(%eax),%eax
80104fa0:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
80104fa6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104fa9:	8b 40 18             	mov    0x18(%eax),%eax
80104fac:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
  p->tf->es = p->tf->ds;
80104fb2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104fb5:	8b 40 18             	mov    0x18(%eax),%eax
80104fb8:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104fbb:	8b 52 18             	mov    0x18(%edx),%edx
80104fbe:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104fc2:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
80104fc6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104fc9:	8b 40 18             	mov    0x18(%eax),%eax
80104fcc:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104fcf:	8b 52 18             	mov    0x18(%edx),%edx
80104fd2:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104fd6:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
80104fda:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104fdd:	8b 40 18             	mov    0x18(%eax),%eax
80104fe0:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
80104fe7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104fea:	8b 40 18             	mov    0x18(%eax),%eax
80104fed:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
80104ff4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ff7:	8b 40 18             	mov    0x18(%eax),%eax
80104ffa:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
80105001:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105004:	83 c0 6c             	add    $0x6c,%eax
80105007:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
8010500e:	00 
8010500f:	c7 44 24 04 23 9b 10 	movl   $0x80109b23,0x4(%esp)
80105016:	80 
80105017:	89 04 24             	mov    %eax,(%esp)
8010501a:	e8 2b 10 00 00       	call   8010604a <safestrcpy>
  p->cwd = namei("/");
8010501f:	c7 04 24 7a 9a 10 80 	movl   $0x80109a7a,(%esp)
80105026:	e8 df d3 ff ff       	call   8010240a <namei>
8010502b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010502e:	89 42 68             	mov    %eax,0x68(%edx)

  p->state = RUNNABLE;
80105031:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105034:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)

  createInternalProcess("inswapper", swapIn);
8010503b:	c7 44 24 04 01 4b 10 	movl   $0x80104b01,0x4(%esp)
80105042:	80 
80105043:	c7 04 24 2c 9b 10 80 	movl   $0x80109b2c,(%esp)
8010504a:	e8 a0 f9 ff ff       	call   801049ef <createInternalProcess>
}
8010504f:	c9                   	leave  
80105050:	c3                   	ret    

80105051 <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
80105051:	55                   	push   %ebp
80105052:	89 e5                	mov    %esp,%ebp
80105054:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  
  sz = proc->sz;
80105057:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010505d:	8b 00                	mov    (%eax),%eax
8010505f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
80105062:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80105066:	7e 34                	jle    8010509c <growproc+0x4b>
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
80105068:	8b 45 08             	mov    0x8(%ebp),%eax
8010506b:	89 c2                	mov    %eax,%edx
8010506d:	03 55 f4             	add    -0xc(%ebp),%edx
80105070:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105076:	8b 40 04             	mov    0x4(%eax),%eax
80105079:	89 54 24 08          	mov    %edx,0x8(%esp)
8010507d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105080:	89 54 24 04          	mov    %edx,0x4(%esp)
80105084:	89 04 24             	mov    %eax,(%esp)
80105087:	e8 bf 41 00 00       	call   8010924b <allocuvm>
8010508c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010508f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105093:	75 41                	jne    801050d6 <growproc+0x85>
      return -1;
80105095:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010509a:	eb 58                	jmp    801050f4 <growproc+0xa3>
  } else if(n < 0){
8010509c:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801050a0:	79 34                	jns    801050d6 <growproc+0x85>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
801050a2:	8b 45 08             	mov    0x8(%ebp),%eax
801050a5:	89 c2                	mov    %eax,%edx
801050a7:	03 55 f4             	add    -0xc(%ebp),%edx
801050aa:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050b0:	8b 40 04             	mov    0x4(%eax),%eax
801050b3:	89 54 24 08          	mov    %edx,0x8(%esp)
801050b7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801050ba:	89 54 24 04          	mov    %edx,0x4(%esp)
801050be:	89 04 24             	mov    %eax,(%esp)
801050c1:	e8 5f 42 00 00       	call   80109325 <deallocuvm>
801050c6:	89 45 f4             	mov    %eax,-0xc(%ebp)
801050c9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801050cd:	75 07                	jne    801050d6 <growproc+0x85>
      return -1;
801050cf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801050d4:	eb 1e                	jmp    801050f4 <growproc+0xa3>
  }
  proc->sz = sz;
801050d6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050dc:	8b 55 f4             	mov    -0xc(%ebp),%edx
801050df:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
801050e1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050e7:	89 04 24             	mov    %eax,(%esp)
801050ea:	e8 7b 3e 00 00       	call   80108f6a <switchuvm>
  return 0;
801050ef:	b8 00 00 00 00       	mov    $0x0,%eax
}
801050f4:	c9                   	leave  
801050f5:	c3                   	ret    

801050f6 <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
801050f6:	55                   	push   %ebp
801050f7:	89 e5                	mov    %esp,%ebp
801050f9:	57                   	push   %edi
801050fa:	56                   	push   %esi
801050fb:	53                   	push   %ebx
801050fc:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
801050ff:	e8 44 f7 ff ff       	call   80104848 <allocproc>
80105104:	89 45 e0             	mov    %eax,-0x20(%ebp)
80105107:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
8010510b:	75 0a                	jne    80105117 <fork+0x21>
    return -1;
8010510d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105112:	e9 3a 01 00 00       	jmp    80105251 <fork+0x15b>
  
  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
80105117:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010511d:	8b 10                	mov    (%eax),%edx
8010511f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105125:	8b 40 04             	mov    0x4(%eax),%eax
80105128:	89 54 24 04          	mov    %edx,0x4(%esp)
8010512c:	89 04 24             	mov    %eax,(%esp)
8010512f:	e8 81 43 00 00       	call   801094b5 <copyuvm>
80105134:	8b 55 e0             	mov    -0x20(%ebp),%edx
80105137:	89 42 04             	mov    %eax,0x4(%edx)
8010513a:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010513d:	8b 40 04             	mov    0x4(%eax),%eax
80105140:	85 c0                	test   %eax,%eax
80105142:	75 2c                	jne    80105170 <fork+0x7a>
    kfree(np->kstack);
80105144:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105147:	8b 40 08             	mov    0x8(%eax),%eax
8010514a:	89 04 24             	mov    %eax,(%esp)
8010514d:	e8 25 d9 ff ff       	call   80102a77 <kfree>
    np->kstack = 0;
80105152:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105155:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
8010515c:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010515f:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
80105166:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010516b:	e9 e1 00 00 00       	jmp    80105251 <fork+0x15b>
  }
  np->sz = proc->sz;
80105170:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105176:	8b 10                	mov    (%eax),%edx
80105178:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010517b:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
8010517d:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80105184:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105187:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *proc->tf;
8010518a:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010518d:	8b 50 18             	mov    0x18(%eax),%edx
80105190:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105196:	8b 40 18             	mov    0x18(%eax),%eax
80105199:	89 c3                	mov    %eax,%ebx
8010519b:	b8 13 00 00 00       	mov    $0x13,%eax
801051a0:	89 d7                	mov    %edx,%edi
801051a2:	89 de                	mov    %ebx,%esi
801051a4:	89 c1                	mov    %eax,%ecx
801051a6:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
801051a8:	8b 45 e0             	mov    -0x20(%ebp),%eax
801051ab:	8b 40 18             	mov    0x18(%eax),%eax
801051ae:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
801051b5:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
801051bc:	eb 3d                	jmp    801051fb <fork+0x105>
    if(proc->ofile[i])
801051be:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801051c4:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801051c7:	83 c2 08             	add    $0x8,%edx
801051ca:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801051ce:	85 c0                	test   %eax,%eax
801051d0:	74 25                	je     801051f7 <fork+0x101>
      np->ofile[i] = filedup(proc->ofile[i]);
801051d2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801051d8:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801051db:	83 c2 08             	add    $0x8,%edx
801051de:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801051e2:	89 04 24             	mov    %eax,(%esp)
801051e5:	e8 92 bd ff ff       	call   80100f7c <filedup>
801051ea:	8b 55 e0             	mov    -0x20(%ebp),%edx
801051ed:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
801051f0:	83 c1 08             	add    $0x8,%ecx
801051f3:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
801051f7:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
801051fb:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
801051ff:	7e bd                	jle    801051be <fork+0xc8>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
80105201:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105207:	8b 40 68             	mov    0x68(%eax),%eax
8010520a:	89 04 24             	mov    %eax,(%esp)
8010520d:	e8 24 c6 ff ff       	call   80101836 <idup>
80105212:	8b 55 e0             	mov    -0x20(%ebp),%edx
80105215:	89 42 68             	mov    %eax,0x68(%edx)
 
  pid = np->pid;
80105218:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010521b:	8b 40 10             	mov    0x10(%eax),%eax
8010521e:	89 45 dc             	mov    %eax,-0x24(%ebp)
  np->state = RUNNABLE;
80105221:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105224:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  safestrcpy(np->name, proc->name, sizeof(proc->name));
8010522b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105231:	8d 50 6c             	lea    0x6c(%eax),%edx
80105234:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105237:	83 c0 6c             	add    $0x6c,%eax
8010523a:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80105241:	00 
80105242:	89 54 24 04          	mov    %edx,0x4(%esp)
80105246:	89 04 24             	mov    %eax,(%esp)
80105249:	e8 fc 0d 00 00       	call   8010604a <safestrcpy>
  return pid;
8010524e:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
80105251:	83 c4 2c             	add    $0x2c,%esp
80105254:	5b                   	pop    %ebx
80105255:	5e                   	pop    %esi
80105256:	5f                   	pop    %edi
80105257:	5d                   	pop    %ebp
80105258:	c3                   	ret    

80105259 <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
80105259:	55                   	push   %ebp
8010525a:	89 e5                	mov    %esp,%ebp
8010525c:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int fd;

  if(proc == initproc)
8010525f:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80105266:	a1 88 c6 10 80       	mov    0x8010c688,%eax
8010526b:	39 c2                	cmp    %eax,%edx
8010526d:	75 0c                	jne    8010527b <exit+0x22>
    panic("init exiting");
8010526f:	c7 04 24 36 9b 10 80 	movl   $0x80109b36,(%esp)
80105276:	e8 c2 b2 ff ff       	call   8010053d <panic>

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
8010527b:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80105282:	eb 44                	jmp    801052c8 <exit+0x6f>
    if(proc->ofile[fd]){
80105284:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010528a:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010528d:	83 c2 08             	add    $0x8,%edx
80105290:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105294:	85 c0                	test   %eax,%eax
80105296:	74 2c                	je     801052c4 <exit+0x6b>
      fileclose(proc->ofile[fd]);
80105298:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010529e:	8b 55 f0             	mov    -0x10(%ebp),%edx
801052a1:	83 c2 08             	add    $0x8,%edx
801052a4:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801052a8:	89 04 24             	mov    %eax,(%esp)
801052ab:	e8 14 bd ff ff       	call   80100fc4 <fileclose>
      proc->ofile[fd] = 0;
801052b0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801052b6:	8b 55 f0             	mov    -0x10(%ebp),%edx
801052b9:	83 c2 08             	add    $0x8,%edx
801052bc:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
801052c3:	00 

  if(proc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
801052c4:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
801052c8:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
801052cc:	7e b6                	jle    80105284 <exit+0x2b>
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  iput(proc->cwd);
801052ce:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801052d4:	8b 40 68             	mov    0x68(%eax),%eax
801052d7:	89 04 24             	mov    %eax,(%esp)
801052da:	e8 3c c7 ff ff       	call   80101a1b <iput>
  proc->cwd = 0;
801052df:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801052e5:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)
  
  if(proc->has_shm)
801052ec:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801052f2:	8b 80 8c 00 00 00    	mov    0x8c(%eax),%eax
801052f8:	85 c0                	test   %eax,%eax
801052fa:	74 11                	je     8010530d <exit+0xb4>
    deallocshm(proc->pid);		//deallocate any shared memory segments proc did not shmdt
801052fc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105302:	8b 40 10             	mov    0x10(%eax),%eax
80105305:	89 04 24             	mov    %eax,(%esp)
80105308:	e8 89 de ff ff       	call   80103196 <deallocshm>
  
  acquire(&ptable.lock);
8010530d:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
80105314:	e8 7a 08 00 00       	call   80105b93 <acquire>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);
80105319:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010531f:	8b 40 14             	mov    0x14(%eax),%eax
80105322:	89 04 24             	mov    %eax,(%esp)
80105325:	e8 98 04 00 00       	call   801057c2 <wakeup1>

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010532a:	c7 45 f4 74 77 12 80 	movl   $0x80127774,-0xc(%ebp)
80105331:	eb 3b                	jmp    8010536e <exit+0x115>
    if(p->parent == proc){
80105333:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105336:	8b 50 14             	mov    0x14(%eax),%edx
80105339:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010533f:	39 c2                	cmp    %eax,%edx
80105341:	75 24                	jne    80105367 <exit+0x10e>
      p->parent = initproc;
80105343:	8b 15 88 c6 10 80    	mov    0x8010c688,%edx
80105349:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010534c:	89 50 14             	mov    %edx,0x14(%eax)
      if(p->state == ZOMBIE)
8010534f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105352:	8b 40 0c             	mov    0xc(%eax),%eax
80105355:	83 f8 05             	cmp    $0x5,%eax
80105358:	75 0d                	jne    80105367 <exit+0x10e>
        wakeup1(initproc);
8010535a:	a1 88 c6 10 80       	mov    0x8010c688,%eax
8010535f:	89 04 24             	mov    %eax,(%esp)
80105362:	e8 5b 04 00 00       	call   801057c2 <wakeup1>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105367:	81 45 f4 90 00 00 00 	addl   $0x90,-0xc(%ebp)
8010536e:	81 7d f4 74 9b 12 80 	cmpl   $0x80129b74,-0xc(%ebp)
80105375:	72 bc                	jb     80105333 <exit+0xda>
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  proc->state = ZOMBIE;
80105377:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010537d:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
  sched();
80105384:	e8 5a 02 00 00       	call   801055e3 <sched>
  panic("zombie exit");
80105389:	c7 04 24 43 9b 10 80 	movl   $0x80109b43,(%esp)
80105390:	e8 a8 b1 ff ff       	call   8010053d <panic>

80105395 <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
80105395:	55                   	push   %ebp
80105396:	89 e5                	mov    %esp,%ebp
80105398:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
8010539b:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
801053a2:	e8 ec 07 00 00       	call   80105b93 <acquire>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
801053a7:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801053ae:	c7 45 f4 74 77 12 80 	movl   $0x80127774,-0xc(%ebp)
801053b5:	e9 9d 00 00 00       	jmp    80105457 <wait+0xc2>
      if(p->parent != proc)
801053ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053bd:	8b 50 14             	mov    0x14(%eax),%edx
801053c0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801053c6:	39 c2                	cmp    %eax,%edx
801053c8:	0f 85 81 00 00 00    	jne    8010544f <wait+0xba>
        continue;
      havekids = 1;
801053ce:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
      if(p->state == ZOMBIE){
801053d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053d8:	8b 40 0c             	mov    0xc(%eax),%eax
801053db:	83 f8 05             	cmp    $0x5,%eax
801053de:	75 70                	jne    80105450 <wait+0xbb>
        // Found one.
        pid = p->pid;
801053e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053e3:	8b 40 10             	mov    0x10(%eax),%eax
801053e6:	89 45 ec             	mov    %eax,-0x14(%ebp)
        kfree(p->kstack);
801053e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053ec:	8b 40 08             	mov    0x8(%eax),%eax
801053ef:	89 04 24             	mov    %eax,(%esp)
801053f2:	e8 80 d6 ff ff       	call   80102a77 <kfree>
        p->kstack = 0;
801053f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053fa:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
        freevm(p->pgdir);
80105401:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105404:	8b 40 04             	mov    0x4(%eax),%eax
80105407:	89 04 24             	mov    %eax,(%esp)
8010540a:	e8 d2 3f 00 00       	call   801093e1 <freevm>
        p->state = UNUSED;
8010540f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105412:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        p->pid = 0;
80105419:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010541c:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
        p->parent = 0;
80105423:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105426:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
        p->name[0] = 0;
8010542d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105430:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)
        p->killed = 0;
80105434:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105437:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
        release(&ptable.lock);
8010543e:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
80105445:	e8 e4 07 00 00       	call   80105c2e <release>
        return pid;
8010544a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010544d:	eb 56                	jmp    801054a5 <wait+0x110>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->parent != proc)
        continue;
8010544f:	90                   	nop

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105450:	81 45 f4 90 00 00 00 	addl   $0x90,-0xc(%ebp)
80105457:	81 7d f4 74 9b 12 80 	cmpl   $0x80129b74,-0xc(%ebp)
8010545e:	0f 82 56 ff ff ff    	jb     801053ba <wait+0x25>
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
80105464:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105468:	74 0d                	je     80105477 <wait+0xe2>
8010546a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105470:	8b 40 24             	mov    0x24(%eax),%eax
80105473:	85 c0                	test   %eax,%eax
80105475:	74 13                	je     8010548a <wait+0xf5>
      release(&ptable.lock);
80105477:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
8010547e:	e8 ab 07 00 00       	call   80105c2e <release>
      return -1;
80105483:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105488:	eb 1b                	jmp    801054a5 <wait+0x110>
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
8010548a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105490:	c7 44 24 04 40 77 12 	movl   $0x80127740,0x4(%esp)
80105497:	80 
80105498:	89 04 24             	mov    %eax,(%esp)
8010549b:	e8 53 02 00 00       	call   801056f3 <sleep>
  }
801054a0:	e9 02 ff ff ff       	jmp    801053a7 <wait+0x12>
}
801054a5:	c9                   	leave  
801054a6:	c3                   	ret    

801054a7 <register_handler>:

void
register_handler(sighandler_t sighandler)
{
801054a7:	55                   	push   %ebp
801054a8:	89 e5                	mov    %esp,%ebp
801054aa:	83 ec 28             	sub    $0x28,%esp
  char* addr = uva2ka(proc->pgdir, (char*)proc->tf->esp);
801054ad:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054b3:	8b 40 18             	mov    0x18(%eax),%eax
801054b6:	8b 40 44             	mov    0x44(%eax),%eax
801054b9:	89 c2                	mov    %eax,%edx
801054bb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054c1:	8b 40 04             	mov    0x4(%eax),%eax
801054c4:	89 54 24 04          	mov    %edx,0x4(%esp)
801054c8:	89 04 24             	mov    %eax,(%esp)
801054cb:	e8 f6 40 00 00       	call   801095c6 <uva2ka>
801054d0:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if ((proc->tf->esp & 0xFFF) == 0)
801054d3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054d9:	8b 40 18             	mov    0x18(%eax),%eax
801054dc:	8b 40 44             	mov    0x44(%eax),%eax
801054df:	25 ff 0f 00 00       	and    $0xfff,%eax
801054e4:	85 c0                	test   %eax,%eax
801054e6:	75 0c                	jne    801054f4 <register_handler+0x4d>
    panic("esp_offset == 0");
801054e8:	c7 04 24 4f 9b 10 80 	movl   $0x80109b4f,(%esp)
801054ef:	e8 49 b0 ff ff       	call   8010053d <panic>

    /* open a new frame */
  *(int*)(addr + ((proc->tf->esp - 4) & 0xFFF))
801054f4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054fa:	8b 40 18             	mov    0x18(%eax),%eax
801054fd:	8b 40 44             	mov    0x44(%eax),%eax
80105500:	83 e8 04             	sub    $0x4,%eax
80105503:	25 ff 0f 00 00       	and    $0xfff,%eax
80105508:	03 45 f4             	add    -0xc(%ebp),%eax
          = proc->tf->eip;
8010550b:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80105512:	8b 52 18             	mov    0x18(%edx),%edx
80105515:	8b 52 38             	mov    0x38(%edx),%edx
80105518:	89 10                	mov    %edx,(%eax)
  proc->tf->esp -= 4;
8010551a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105520:	8b 40 18             	mov    0x18(%eax),%eax
80105523:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
8010552a:	8b 52 18             	mov    0x18(%edx),%edx
8010552d:	8b 52 44             	mov    0x44(%edx),%edx
80105530:	83 ea 04             	sub    $0x4,%edx
80105533:	89 50 44             	mov    %edx,0x44(%eax)

    /* update eip */
  proc->tf->eip = (uint)sighandler;
80105536:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010553c:	8b 40 18             	mov    0x18(%eax),%eax
8010553f:	8b 55 08             	mov    0x8(%ebp),%edx
80105542:	89 50 38             	mov    %edx,0x38(%eax)
}
80105545:	c9                   	leave  
80105546:	c3                   	ret    

80105547 <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
80105547:	55                   	push   %ebp
80105548:	89 e5                	mov    %esp,%ebp
8010554a:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  
  for(;;){
    // Enable interrupts on this processor.
    sti();
8010554d:	e8 c0 f2 ff ff       	call   80104812 <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
80105552:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
80105559:	e8 35 06 00 00       	call   80105b93 <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010555e:	c7 45 f4 74 77 12 80 	movl   $0x80127774,-0xc(%ebp)
80105565:	eb 62                	jmp    801055c9 <scheduler+0x82>
      if(p->state != RUNNABLE)
80105567:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010556a:	8b 40 0c             	mov    0xc(%eax),%eax
8010556d:	83 f8 03             	cmp    $0x3,%eax
80105570:	75 4f                	jne    801055c1 <scheduler+0x7a>
        continue;
    
      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
80105572:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105575:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
      switchuvm(p);
8010557b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010557e:	89 04 24             	mov    %eax,(%esp)
80105581:	e8 e4 39 00 00       	call   80108f6a <switchuvm>
      p->state = RUNNING;
80105586:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105589:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      swtch(&cpu->scheduler, proc->context);
80105590:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105596:	8b 40 1c             	mov    0x1c(%eax),%eax
80105599:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801055a0:	83 c2 04             	add    $0x4,%edx
801055a3:	89 44 24 04          	mov    %eax,0x4(%esp)
801055a7:	89 14 24             	mov    %edx,(%esp)
801055aa:	e8 11 0b 00 00       	call   801060c0 <swtch>
      switchkvm();
801055af:	e8 99 39 00 00       	call   80108f4d <switchkvm>
                 
      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
801055b4:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
801055bb:	00 00 00 00 
801055bf:	eb 01                	jmp    801055c2 <scheduler+0x7b>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->state != RUNNABLE)
        continue;
801055c1:	90                   	nop
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801055c2:	81 45 f4 90 00 00 00 	addl   $0x90,-0xc(%ebp)
801055c9:	81 7d f4 74 9b 12 80 	cmpl   $0x80129b74,-0xc(%ebp)
801055d0:	72 95                	jb     80105567 <scheduler+0x20>
                 
      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
801055d2:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
801055d9:	e8 50 06 00 00       	call   80105c2e <release>

  }
801055de:	e9 6a ff ff ff       	jmp    8010554d <scheduler+0x6>

801055e3 <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
801055e3:	55                   	push   %ebp
801055e4:	89 e5                	mov    %esp,%ebp
801055e6:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
801055e9:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
801055f0:	e8 f5 06 00 00       	call   80105cea <holding>
801055f5:	85 c0                	test   %eax,%eax
801055f7:	75 0c                	jne    80105605 <sched+0x22>
    panic("sched ptable.lock");
801055f9:	c7 04 24 5f 9b 10 80 	movl   $0x80109b5f,(%esp)
80105600:	e8 38 af ff ff       	call   8010053d <panic>
  if(cpu->ncli != 1)
80105605:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010560b:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105611:	83 f8 01             	cmp    $0x1,%eax
80105614:	74 0c                	je     80105622 <sched+0x3f>
    panic("sched locks");
80105616:	c7 04 24 71 9b 10 80 	movl   $0x80109b71,(%esp)
8010561d:	e8 1b af ff ff       	call   8010053d <panic>
  if(proc->state == RUNNING)
80105622:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105628:	8b 40 0c             	mov    0xc(%eax),%eax
8010562b:	83 f8 04             	cmp    $0x4,%eax
8010562e:	75 0c                	jne    8010563c <sched+0x59>
    panic("sched running");
80105630:	c7 04 24 7d 9b 10 80 	movl   $0x80109b7d,(%esp)
80105637:	e8 01 af ff ff       	call   8010053d <panic>
  if(readeflags()&FL_IF)
8010563c:	e8 bc f1 ff ff       	call   801047fd <readeflags>
80105641:	25 00 02 00 00       	and    $0x200,%eax
80105646:	85 c0                	test   %eax,%eax
80105648:	74 0c                	je     80105656 <sched+0x73>
    panic("sched interruptible");
8010564a:	c7 04 24 8b 9b 10 80 	movl   $0x80109b8b,(%esp)
80105651:	e8 e7 ae ff ff       	call   8010053d <panic>
  intena = cpu->intena;
80105656:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010565c:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80105662:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->context, cpu->scheduler);
80105665:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010566b:	8b 40 04             	mov    0x4(%eax),%eax
8010566e:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80105675:	83 c2 1c             	add    $0x1c,%edx
80105678:	89 44 24 04          	mov    %eax,0x4(%esp)
8010567c:	89 14 24             	mov    %edx,(%esp)
8010567f:	e8 3c 0a 00 00       	call   801060c0 <swtch>
  cpu->intena = intena;
80105684:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010568a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010568d:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80105693:	c9                   	leave  
80105694:	c3                   	ret    

80105695 <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
80105695:	55                   	push   %ebp
80105696:	89 e5                	mov    %esp,%ebp
80105698:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
8010569b:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
801056a2:	e8 ec 04 00 00       	call   80105b93 <acquire>
  proc->state = RUNNABLE;
801056a7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801056ad:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
801056b4:	e8 2a ff ff ff       	call   801055e3 <sched>
  release(&ptable.lock);
801056b9:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
801056c0:	e8 69 05 00 00       	call   80105c2e <release>
}
801056c5:	c9                   	leave  
801056c6:	c3                   	ret    

801056c7 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
801056c7:	55                   	push   %ebp
801056c8:	89 e5                	mov    %esp,%ebp
801056ca:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
801056cd:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
801056d4:	e8 55 05 00 00       	call   80105c2e <release>

  if (first) {
801056d9:	a1 20 c0 10 80       	mov    0x8010c020,%eax
801056de:	85 c0                	test   %eax,%eax
801056e0:	74 0f                	je     801056f1 <forkret+0x2a>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
801056e2:	c7 05 20 c0 10 80 00 	movl   $0x0,0x8010c020
801056e9:	00 00 00 
    initlog();
801056ec:	e8 21 e1 ff ff       	call   80103812 <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
801056f1:	c9                   	leave  
801056f2:	c3                   	ret    

801056f3 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
801056f3:	55                   	push   %ebp
801056f4:	89 e5                	mov    %esp,%ebp
801056f6:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
801056f9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801056ff:	85 c0                	test   %eax,%eax
80105701:	75 0c                	jne    8010570f <sleep+0x1c>
    panic("sleep");
80105703:	c7 04 24 9f 9b 10 80 	movl   $0x80109b9f,(%esp)
8010570a:	e8 2e ae ff ff       	call   8010053d <panic>

  if(lk == 0)
8010570f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80105713:	75 0c                	jne    80105721 <sleep+0x2e>
    panic("sleep without lk");
80105715:	c7 04 24 a5 9b 10 80 	movl   $0x80109ba5,(%esp)
8010571c:	e8 1c ae ff ff       	call   8010053d <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
80105721:	81 7d 0c 40 77 12 80 	cmpl   $0x80127740,0xc(%ebp)
80105728:	74 17                	je     80105741 <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
8010572a:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
80105731:	e8 5d 04 00 00       	call   80105b93 <acquire>
    release(lk);
80105736:	8b 45 0c             	mov    0xc(%ebp),%eax
80105739:	89 04 24             	mov    %eax,(%esp)
8010573c:	e8 ed 04 00 00       	call   80105c2e <release>
  }

  // Go to sleep.
  proc->chan = chan;
80105741:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105747:	8b 55 08             	mov    0x8(%ebp),%edx
8010574a:	89 50 20             	mov    %edx,0x20(%eax)
  proc->state = SLEEPING;
8010574d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105753:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)

  // Swap out
  if(swapFlag)			//check if swapping out is enabled
8010575a:	a1 80 c6 10 80       	mov    0x8010c680,%eax
8010575f:	85 c0                	test   %eax,%eax
80105761:	74 2b                	je     8010578e <sleep+0x9b>
  {
    if(proc->pid > 2)		//do not allow init and inswapper to swapout
80105763:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105769:	8b 40 10             	mov    0x10(%eax),%eax
8010576c:	83 f8 02             	cmp    $0x2,%eax
8010576f:	7e 1d                	jle    8010578e <sleep+0x9b>
    {
      release(&ptable.lock);	
80105771:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
80105778:	e8 b1 04 00 00       	call   80105c2e <release>
      swapOut();		//swap out proc
8010577d:	e8 da f5 ff ff       	call   80104d5c <swapOut>
      acquire(&ptable.lock);
80105782:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
80105789:	e8 05 04 00 00       	call   80105b93 <acquire>
    }
  }
  
  sched();
8010578e:	e8 50 fe ff ff       	call   801055e3 <sched>
  
  // Tidy up.
  proc->chan = 0;
80105793:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105799:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
801057a0:	81 7d 0c 40 77 12 80 	cmpl   $0x80127740,0xc(%ebp)
801057a7:	74 17                	je     801057c0 <sleep+0xcd>
    release(&ptable.lock);
801057a9:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
801057b0:	e8 79 04 00 00       	call   80105c2e <release>
    acquire(lk);
801057b5:	8b 45 0c             	mov    0xc(%ebp),%eax
801057b8:	89 04 24             	mov    %eax,(%esp)
801057bb:	e8 d3 03 00 00       	call   80105b93 <acquire>
  }
}
801057c0:	c9                   	leave  
801057c1:	c3                   	ret    

801057c2 <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
801057c2:	55                   	push   %ebp
801057c3:	89 e5                	mov    %esp,%ebp
801057c5:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int found_suspended = 0;
801057c8:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801057cf:	c7 45 f4 74 77 12 80 	movl   $0x80127774,-0xc(%ebp)
801057d6:	eb 7e                	jmp    80105856 <wakeup1+0x94>
  {
    if(p->state == SLEEPING && p->chan == chan)
801057d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057db:	8b 40 0c             	mov    0xc(%eax),%eax
801057de:	83 f8 02             	cmp    $0x2,%eax
801057e1:	75 15                	jne    801057f8 <wakeup1+0x36>
801057e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057e6:	8b 40 20             	mov    0x20(%eax),%eax
801057e9:	3b 45 08             	cmp    0x8(%ebp),%eax
801057ec:	75 0a                	jne    801057f8 <wakeup1+0x36>
      p->state = RUNNABLE;
801057ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057f1:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
    if(p->state == SLEEPING_SUSPENDED && p->chan == chan && !found_suspended)	//check if any proc is SLEEPING_SUSPENDED
801057f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057fb:	8b 40 0c             	mov    0xc(%eax),%eax
801057fe:	83 f8 06             	cmp    $0x6,%eax
80105801:	75 4c                	jne    8010584f <wakeup1+0x8d>
80105803:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105806:	8b 40 20             	mov    0x20(%eax),%eax
80105809:	3b 45 08             	cmp    0x8(%ebp),%eax
8010580c:	75 41                	jne    8010584f <wakeup1+0x8d>
8010580e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105812:	75 3b                	jne    8010584f <wakeup1+0x8d>
    {
      acquire(&swaplock);
80105814:	c7 04 24 a0 c6 10 80 	movl   $0x8010c6a0,(%esp)
8010581b:	e8 73 03 00 00       	call   80105b93 <acquire>
      swappedout++;								//increment swapped out counter
80105820:	a1 84 c6 10 80       	mov    0x8010c684,%eax
80105825:	83 c0 01             	add    $0x1,%eax
80105828:	a3 84 c6 10 80       	mov    %eax,0x8010c684
      p->state = RUNNABLE_SUSPENDED;						//set state to RUNNABLE_SUSPENDED
8010582d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105830:	c7 40 0c 07 00 00 00 	movl   $0x7,0xc(%eax)
      inswapper->state = RUNNABLE;						//wakeup inswapper
80105837:	a1 8c c6 10 80       	mov    0x8010c68c,%eax
8010583c:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      release(&swaplock);
80105843:	c7 04 24 a0 c6 10 80 	movl   $0x8010c6a0,(%esp)
8010584a:	e8 df 03 00 00       	call   80105c2e <release>
wakeup1(void *chan)
{
  struct proc *p;
  int found_suspended = 0;
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010584f:	81 45 f4 90 00 00 00 	addl   $0x90,-0xc(%ebp)
80105856:	81 7d f4 74 9b 12 80 	cmpl   $0x80129b74,-0xc(%ebp)
8010585d:	0f 82 75 ff ff ff    	jb     801057d8 <wakeup1+0x16>
      p->state = RUNNABLE_SUSPENDED;						//set state to RUNNABLE_SUSPENDED
      inswapper->state = RUNNABLE;						//wakeup inswapper
      release(&swaplock);
    }
  }
}
80105863:	c9                   	leave  
80105864:	c3                   	ret    

80105865 <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80105865:	55                   	push   %ebp
80105866:	89 e5                	mov    %esp,%ebp
80105868:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);
8010586b:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
80105872:	e8 1c 03 00 00       	call   80105b93 <acquire>
  wakeup1(chan);
80105877:	8b 45 08             	mov    0x8(%ebp),%eax
8010587a:	89 04 24             	mov    %eax,(%esp)
8010587d:	e8 40 ff ff ff       	call   801057c2 <wakeup1>
  release(&ptable.lock);
80105882:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
80105889:	e8 a0 03 00 00       	call   80105c2e <release>
}
8010588e:	c9                   	leave  
8010588f:	c3                   	ret    

80105890 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80105890:	55                   	push   %ebp
80105891:	89 e5                	mov    %esp,%ebp
80105893:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  acquire(&ptable.lock);
80105896:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
8010589d:	e8 f1 02 00 00       	call   80105b93 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801058a2:	c7 45 f4 74 77 12 80 	movl   $0x80127774,-0xc(%ebp)
801058a9:	e9 8c 00 00 00       	jmp    8010593a <kill+0xaa>
    if(p->pid == pid){
801058ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058b1:	8b 40 10             	mov    0x10(%eax),%eax
801058b4:	3b 45 08             	cmp    0x8(%ebp),%eax
801058b7:	75 7a                	jne    80105933 <kill+0xa3>
      p->killed = 1;
801058b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058bc:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
801058c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058c6:	8b 40 0c             	mov    0xc(%eax),%eax
801058c9:	83 f8 02             	cmp    $0x2,%eax
801058cc:	75 0c                	jne    801058da <kill+0x4a>
        p->state = RUNNABLE;
801058ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058d1:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
801058d8:	eb 46                	jmp    80105920 <kill+0x90>
      else if(p->state == SLEEPING_SUSPENDED)			//same as wakeup1 - swap in any killed process that is swapped out
801058da:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058dd:	8b 40 0c             	mov    0xc(%eax),%eax
801058e0:	83 f8 06             	cmp    $0x6,%eax
801058e3:	75 3b                	jne    80105920 <kill+0x90>
      {
        acquire(&swaplock);
801058e5:	c7 04 24 a0 c6 10 80 	movl   $0x8010c6a0,(%esp)
801058ec:	e8 a2 02 00 00       	call   80105b93 <acquire>
      	swappedout++;
801058f1:	a1 84 c6 10 80       	mov    0x8010c684,%eax
801058f6:	83 c0 01             	add    $0x1,%eax
801058f9:	a3 84 c6 10 80       	mov    %eax,0x8010c684
      	p->state = RUNNABLE_SUSPENDED;
801058fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105901:	c7 40 0c 07 00 00 00 	movl   $0x7,0xc(%eax)
      	inswapper->state = RUNNABLE;
80105908:	a1 8c c6 10 80       	mov    0x8010c68c,%eax
8010590d:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      	release(&swaplock);
80105914:	c7 04 24 a0 c6 10 80 	movl   $0x8010c6a0,(%esp)
8010591b:	e8 0e 03 00 00       	call   80105c2e <release>
      }
      release(&ptable.lock);
80105920:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
80105927:	e8 02 03 00 00       	call   80105c2e <release>
      return 0;
8010592c:	b8 00 00 00 00       	mov    $0x0,%eax
80105931:	eb 25                	jmp    80105958 <kill+0xc8>
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105933:	81 45 f4 90 00 00 00 	addl   $0x90,-0xc(%ebp)
8010593a:	81 7d f4 74 9b 12 80 	cmpl   $0x80129b74,-0xc(%ebp)
80105941:	0f 82 67 ff ff ff    	jb     801058ae <kill+0x1e>
      }
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
80105947:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
8010594e:	e8 db 02 00 00       	call   80105c2e <release>
  return -1;
80105953:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105958:	c9                   	leave  
80105959:	c3                   	ret    

8010595a <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
8010595a:	55                   	push   %ebp
8010595b:	89 e5                	mov    %esp,%ebp
8010595d:	83 ec 58             	sub    $0x58,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105960:	c7 45 f0 74 77 12 80 	movl   $0x80127774,-0x10(%ebp)
80105967:	e9 db 00 00 00       	jmp    80105a47 <procdump+0xed>
    if(p->state == UNUSED)
8010596c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010596f:	8b 40 0c             	mov    0xc(%eax),%eax
80105972:	85 c0                	test   %eax,%eax
80105974:	0f 84 c5 00 00 00    	je     80105a3f <procdump+0xe5>
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
8010597a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010597d:	8b 40 0c             	mov    0xc(%eax),%eax
80105980:	83 f8 05             	cmp    $0x5,%eax
80105983:	77 23                	ja     801059a8 <procdump+0x4e>
80105985:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105988:	8b 40 0c             	mov    0xc(%eax),%eax
8010598b:	8b 04 85 08 c0 10 80 	mov    -0x7fef3ff8(,%eax,4),%eax
80105992:	85 c0                	test   %eax,%eax
80105994:	74 12                	je     801059a8 <procdump+0x4e>
      state = states[p->state];
80105996:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105999:	8b 40 0c             	mov    0xc(%eax),%eax
8010599c:	8b 04 85 08 c0 10 80 	mov    -0x7fef3ff8(,%eax,4),%eax
801059a3:	89 45 ec             	mov    %eax,-0x14(%ebp)
801059a6:	eb 07                	jmp    801059af <procdump+0x55>
    else
      state = "???";
801059a8:	c7 45 ec b6 9b 10 80 	movl   $0x80109bb6,-0x14(%ebp)
    cprintf("%d %s %s", p->pid, state, p->name);
801059af:	8b 45 f0             	mov    -0x10(%ebp),%eax
801059b2:	8d 50 6c             	lea    0x6c(%eax),%edx
801059b5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801059b8:	8b 40 10             	mov    0x10(%eax),%eax
801059bb:	89 54 24 0c          	mov    %edx,0xc(%esp)
801059bf:	8b 55 ec             	mov    -0x14(%ebp),%edx
801059c2:	89 54 24 08          	mov    %edx,0x8(%esp)
801059c6:	89 44 24 04          	mov    %eax,0x4(%esp)
801059ca:	c7 04 24 ba 9b 10 80 	movl   $0x80109bba,(%esp)
801059d1:	e8 cb a9 ff ff       	call   801003a1 <cprintf>
    if(p->state == SLEEPING){
801059d6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801059d9:	8b 40 0c             	mov    0xc(%eax),%eax
801059dc:	83 f8 02             	cmp    $0x2,%eax
801059df:	75 50                	jne    80105a31 <procdump+0xd7>
      getcallerpcs((uint*)p->context->ebp+2, pc);
801059e1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801059e4:	8b 40 1c             	mov    0x1c(%eax),%eax
801059e7:	8b 40 0c             	mov    0xc(%eax),%eax
801059ea:	83 c0 08             	add    $0x8,%eax
801059ed:	8d 55 c4             	lea    -0x3c(%ebp),%edx
801059f0:	89 54 24 04          	mov    %edx,0x4(%esp)
801059f4:	89 04 24             	mov    %eax,(%esp)
801059f7:	e8 81 02 00 00       	call   80105c7d <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
801059fc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80105a03:	eb 1b                	jmp    80105a20 <procdump+0xc6>
        cprintf(" %p", pc[i]);
80105a05:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a08:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80105a0c:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a10:	c7 04 24 c3 9b 10 80 	movl   $0x80109bc3,(%esp)
80105a17:	e8 85 a9 ff ff       	call   801003a1 <cprintf>
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
80105a1c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80105a20:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
80105a24:	7f 0b                	jg     80105a31 <procdump+0xd7>
80105a26:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a29:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80105a2d:	85 c0                	test   %eax,%eax
80105a2f:	75 d4                	jne    80105a05 <procdump+0xab>
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80105a31:	c7 04 24 c7 9b 10 80 	movl   $0x80109bc7,(%esp)
80105a38:	e8 64 a9 ff ff       	call   801003a1 <cprintf>
80105a3d:	eb 01                	jmp    80105a40 <procdump+0xe6>
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
80105a3f:	90                   	nop
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105a40:	81 45 f0 90 00 00 00 	addl   $0x90,-0x10(%ebp)
80105a47:	81 7d f0 74 9b 12 80 	cmpl   $0x80129b74,-0x10(%ebp)
80105a4e:	0f 82 18 ff ff ff    	jb     8010596c <procdump+0x12>
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}
80105a54:	c9                   	leave  
80105a55:	c3                   	ret    

80105a56 <getAllocatedPages>:

int getAllocatedPages(int pid) {			//traverse the process with the given pid's virtual memory and count how many PTE_U pages are allocated
80105a56:	55                   	push   %ebp
80105a57:	89 e5                	mov    %esp,%ebp
80105a59:	83 ec 38             	sub    $0x38,%esp
  struct proc* p;
  acquire(&ptable.lock);
80105a5c:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
80105a63:	e8 2b 01 00 00       	call   80105b93 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105a68:	c7 45 f4 74 77 12 80 	movl   $0x80127774,-0xc(%ebp)
80105a6f:	eb 12                	jmp    80105a83 <getAllocatedPages+0x2d>
    if(p->pid == pid){
80105a71:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a74:	8b 40 10             	mov    0x10(%eax),%eax
80105a77:	3b 45 08             	cmp    0x8(%ebp),%eax
80105a7a:	74 12                	je     80105a8e <getAllocatedPages+0x38>
}

int getAllocatedPages(int pid) {			//traverse the process with the given pid's virtual memory and count how many PTE_U pages are allocated
  struct proc* p;
  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105a7c:	81 45 f4 90 00 00 00 	addl   $0x90,-0xc(%ebp)
80105a83:	81 7d f4 74 9b 12 80 	cmpl   $0x80129b74,-0xc(%ebp)
80105a8a:	72 e5                	jb     80105a71 <getAllocatedPages+0x1b>
80105a8c:	eb 01                	jmp    80105a8f <getAllocatedPages+0x39>
    if(p->pid == pid){
     break;
80105a8e:	90                   	nop
    }
  }
  release(&ptable.lock);
80105a8f:	c7 04 24 40 77 12 80 	movl   $0x80127740,(%esp)
80105a96:	e8 93 01 00 00       	call   80105c2e <release>
   int count= 0, j, k;
80105a9b:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   for (j=0; j<1024; j++) {
80105aa2:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80105aa9:	eb 71                	jmp    80105b1c <getAllocatedPages+0xc6>
      if(p->pgdir){ 
80105aab:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105aae:	8b 40 04             	mov    0x4(%eax),%eax
80105ab1:	85 c0                	test   %eax,%eax
80105ab3:	74 63                	je     80105b18 <getAllocatedPages+0xc2>
	if (p->pgdir[j] & PTE_P) {
80105ab5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ab8:	8b 40 04             	mov    0x4(%eax),%eax
80105abb:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105abe:	c1 e2 02             	shl    $0x2,%edx
80105ac1:	01 d0                	add    %edx,%eax
80105ac3:	8b 00                	mov    (%eax),%eax
80105ac5:	83 e0 01             	and    $0x1,%eax
80105ac8:	84 c0                	test   %al,%al
80105aca:	74 4c                	je     80105b18 <getAllocatedPages+0xc2>
	  pte_t* pte= (pte_t*)p2v(PTE_ADDR(p->pgdir[j]));
80105acc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105acf:	8b 40 04             	mov    0x4(%eax),%eax
80105ad2:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105ad5:	c1 e2 02             	shl    $0x2,%edx
80105ad8:	01 d0                	add    %edx,%eax
80105ada:	8b 00                	mov    (%eax),%eax
80105adc:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80105ae1:	89 04 24             	mov    %eax,(%esp)
80105ae4:	e8 07 ed ff ff       	call   801047f0 <p2v>
80105ae9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	  for (k=0; k<1024; k++) {
80105aec:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
80105af3:	eb 1a                	jmp    80105b0f <getAllocatedPages+0xb9>
	      if ( pte[k] & PTE_U )
80105af5:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105af8:	c1 e0 02             	shl    $0x2,%eax
80105afb:	03 45 e4             	add    -0x1c(%ebp),%eax
80105afe:	8b 00                	mov    (%eax),%eax
80105b00:	83 e0 04             	and    $0x4,%eax
80105b03:	85 c0                	test   %eax,%eax
80105b05:	74 04                	je     80105b0b <getAllocatedPages+0xb5>
		count++;
80105b07:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   int count= 0, j, k;
   for (j=0; j<1024; j++) {
      if(p->pgdir){ 
	if (p->pgdir[j] & PTE_P) {
	  pte_t* pte= (pte_t*)p2v(PTE_ADDR(p->pgdir[j]));
	  for (k=0; k<1024; k++) {
80105b0b:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
80105b0f:	81 7d e8 ff 03 00 00 	cmpl   $0x3ff,-0x18(%ebp)
80105b16:	7e dd                	jle    80105af5 <getAllocatedPages+0x9f>
     break;
    }
  }
  release(&ptable.lock);
   int count= 0, j, k;
   for (j=0; j<1024; j++) {
80105b18:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
80105b1c:	81 7d ec ff 03 00 00 	cmpl   $0x3ff,-0x14(%ebp)
80105b23:	7e 86                	jle    80105aab <getAllocatedPages+0x55>
		count++;
	  }
	}
      }
   }
   return count;
80105b25:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80105b28:	c9                   	leave  
80105b29:	c3                   	ret    
	...

80105b2c <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80105b2c:	55                   	push   %ebp
80105b2d:	89 e5                	mov    %esp,%ebp
80105b2f:	53                   	push   %ebx
80105b30:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80105b33:	9c                   	pushf  
80105b34:	5b                   	pop    %ebx
80105b35:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80105b38:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80105b3b:	83 c4 10             	add    $0x10,%esp
80105b3e:	5b                   	pop    %ebx
80105b3f:	5d                   	pop    %ebp
80105b40:	c3                   	ret    

80105b41 <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
80105b41:	55                   	push   %ebp
80105b42:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
80105b44:	fa                   	cli    
}
80105b45:	5d                   	pop    %ebp
80105b46:	c3                   	ret    

80105b47 <sti>:

static inline void
sti(void)
{
80105b47:	55                   	push   %ebp
80105b48:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80105b4a:	fb                   	sti    
}
80105b4b:	5d                   	pop    %ebp
80105b4c:	c3                   	ret    

80105b4d <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
80105b4d:	55                   	push   %ebp
80105b4e:	89 e5                	mov    %esp,%ebp
80105b50:	53                   	push   %ebx
80105b51:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
80105b54:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80105b57:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
80105b5a:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80105b5d:	89 c3                	mov    %eax,%ebx
80105b5f:	89 d8                	mov    %ebx,%eax
80105b61:	f0 87 02             	lock xchg %eax,(%edx)
80105b64:	89 c3                	mov    %eax,%ebx
80105b66:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80105b69:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80105b6c:	83 c4 10             	add    $0x10,%esp
80105b6f:	5b                   	pop    %ebx
80105b70:	5d                   	pop    %ebp
80105b71:	c3                   	ret    

80105b72 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80105b72:	55                   	push   %ebp
80105b73:	89 e5                	mov    %esp,%ebp
  lk->name = name;
80105b75:	8b 45 08             	mov    0x8(%ebp),%eax
80105b78:	8b 55 0c             	mov    0xc(%ebp),%edx
80105b7b:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80105b7e:	8b 45 08             	mov    0x8(%ebp),%eax
80105b81:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80105b87:	8b 45 08             	mov    0x8(%ebp),%eax
80105b8a:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80105b91:	5d                   	pop    %ebp
80105b92:	c3                   	ret    

80105b93 <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
80105b93:	55                   	push   %ebp
80105b94:	89 e5                	mov    %esp,%ebp
80105b96:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80105b99:	e8 76 01 00 00       	call   80105d14 <pushcli>
  if(holding(lk))
80105b9e:	8b 45 08             	mov    0x8(%ebp),%eax
80105ba1:	89 04 24             	mov    %eax,(%esp)
80105ba4:	e8 41 01 00 00       	call   80105cea <holding>
80105ba9:	85 c0                	test   %eax,%eax
80105bab:	74 45                	je     80105bf2 <acquire+0x5f>
  {
    cprintf("lock = %s\n",lk->name);
80105bad:	8b 45 08             	mov    0x8(%ebp),%eax
80105bb0:	8b 40 04             	mov    0x4(%eax),%eax
80105bb3:	89 44 24 04          	mov    %eax,0x4(%esp)
80105bb7:	c7 04 24 f3 9b 10 80 	movl   $0x80109bf3,(%esp)
80105bbe:	e8 de a7 ff ff       	call   801003a1 <cprintf>
    if(proc)
80105bc3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105bc9:	85 c0                	test   %eax,%eax
80105bcb:	74 19                	je     80105be6 <acquire+0x53>
      cprintf("pid = %d\n",proc->pid);
80105bcd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105bd3:	8b 40 10             	mov    0x10(%eax),%eax
80105bd6:	89 44 24 04          	mov    %eax,0x4(%esp)
80105bda:	c7 04 24 fe 9b 10 80 	movl   $0x80109bfe,(%esp)
80105be1:	e8 bb a7 ff ff       	call   801003a1 <cprintf>
    panic("acquire");
80105be6:	c7 04 24 08 9c 10 80 	movl   $0x80109c08,(%esp)
80105bed:	e8 4b a9 ff ff       	call   8010053d <panic>
  }

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
80105bf2:	90                   	nop
80105bf3:	8b 45 08             	mov    0x8(%ebp),%eax
80105bf6:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80105bfd:	00 
80105bfe:	89 04 24             	mov    %eax,(%esp)
80105c01:	e8 47 ff ff ff       	call   80105b4d <xchg>
80105c06:	85 c0                	test   %eax,%eax
80105c08:	75 e9                	jne    80105bf3 <acquire+0x60>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
80105c0a:	8b 45 08             	mov    0x8(%ebp),%eax
80105c0d:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80105c14:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
80105c17:	8b 45 08             	mov    0x8(%ebp),%eax
80105c1a:	83 c0 0c             	add    $0xc,%eax
80105c1d:	89 44 24 04          	mov    %eax,0x4(%esp)
80105c21:	8d 45 08             	lea    0x8(%ebp),%eax
80105c24:	89 04 24             	mov    %eax,(%esp)
80105c27:	e8 51 00 00 00       	call   80105c7d <getcallerpcs>
}
80105c2c:	c9                   	leave  
80105c2d:	c3                   	ret    

80105c2e <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
80105c2e:	55                   	push   %ebp
80105c2f:	89 e5                	mov    %esp,%ebp
80105c31:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
80105c34:	8b 45 08             	mov    0x8(%ebp),%eax
80105c37:	89 04 24             	mov    %eax,(%esp)
80105c3a:	e8 ab 00 00 00       	call   80105cea <holding>
80105c3f:	85 c0                	test   %eax,%eax
80105c41:	75 0c                	jne    80105c4f <release+0x21>
    panic("release");
80105c43:	c7 04 24 10 9c 10 80 	movl   $0x80109c10,(%esp)
80105c4a:	e8 ee a8 ff ff       	call   8010053d <panic>

  lk->pcs[0] = 0;
80105c4f:	8b 45 08             	mov    0x8(%ebp),%eax
80105c52:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
80105c59:	8b 45 08             	mov    0x8(%ebp),%eax
80105c5c:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
80105c63:	8b 45 08             	mov    0x8(%ebp),%eax
80105c66:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105c6d:	00 
80105c6e:	89 04 24             	mov    %eax,(%esp)
80105c71:	e8 d7 fe ff ff       	call   80105b4d <xchg>

  popcli();
80105c76:	e8 e1 00 00 00       	call   80105d5c <popcli>
}
80105c7b:	c9                   	leave  
80105c7c:	c3                   	ret    

80105c7d <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80105c7d:	55                   	push   %ebp
80105c7e:	89 e5                	mov    %esp,%ebp
80105c80:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
80105c83:	8b 45 08             	mov    0x8(%ebp),%eax
80105c86:	83 e8 08             	sub    $0x8,%eax
80105c89:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
80105c8c:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
80105c93:	eb 32                	jmp    80105cc7 <getcallerpcs+0x4a>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80105c95:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
80105c99:	74 47                	je     80105ce2 <getcallerpcs+0x65>
80105c9b:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
80105ca2:	76 3e                	jbe    80105ce2 <getcallerpcs+0x65>
80105ca4:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
80105ca8:	74 38                	je     80105ce2 <getcallerpcs+0x65>
      break;
    pcs[i] = ebp[1];     // saved %eip
80105caa:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105cad:	c1 e0 02             	shl    $0x2,%eax
80105cb0:	03 45 0c             	add    0xc(%ebp),%eax
80105cb3:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105cb6:	8b 52 04             	mov    0x4(%edx),%edx
80105cb9:	89 10                	mov    %edx,(%eax)
    ebp = (uint*)ebp[0]; // saved %ebp
80105cbb:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105cbe:	8b 00                	mov    (%eax),%eax
80105cc0:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
80105cc3:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105cc7:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105ccb:	7e c8                	jle    80105c95 <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105ccd:	eb 13                	jmp    80105ce2 <getcallerpcs+0x65>
    pcs[i] = 0;
80105ccf:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105cd2:	c1 e0 02             	shl    $0x2,%eax
80105cd5:	03 45 0c             	add    0xc(%ebp),%eax
80105cd8:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105cde:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105ce2:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105ce6:	7e e7                	jle    80105ccf <getcallerpcs+0x52>
    pcs[i] = 0;
}
80105ce8:	c9                   	leave  
80105ce9:	c3                   	ret    

80105cea <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
80105cea:	55                   	push   %ebp
80105ceb:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
80105ced:	8b 45 08             	mov    0x8(%ebp),%eax
80105cf0:	8b 00                	mov    (%eax),%eax
80105cf2:	85 c0                	test   %eax,%eax
80105cf4:	74 17                	je     80105d0d <holding+0x23>
80105cf6:	8b 45 08             	mov    0x8(%ebp),%eax
80105cf9:	8b 50 08             	mov    0x8(%eax),%edx
80105cfc:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105d02:	39 c2                	cmp    %eax,%edx
80105d04:	75 07                	jne    80105d0d <holding+0x23>
80105d06:	b8 01 00 00 00       	mov    $0x1,%eax
80105d0b:	eb 05                	jmp    80105d12 <holding+0x28>
80105d0d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105d12:	5d                   	pop    %ebp
80105d13:	c3                   	ret    

80105d14 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80105d14:	55                   	push   %ebp
80105d15:	89 e5                	mov    %esp,%ebp
80105d17:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
80105d1a:	e8 0d fe ff ff       	call   80105b2c <readeflags>
80105d1f:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
80105d22:	e8 1a fe ff ff       	call   80105b41 <cli>
  if(cpu->ncli++ == 0)
80105d27:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105d2d:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80105d33:	85 d2                	test   %edx,%edx
80105d35:	0f 94 c1             	sete   %cl
80105d38:	83 c2 01             	add    $0x1,%edx
80105d3b:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80105d41:	84 c9                	test   %cl,%cl
80105d43:	74 15                	je     80105d5a <pushcli+0x46>
    cpu->intena = eflags & FL_IF;
80105d45:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105d4b:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105d4e:	81 e2 00 02 00 00    	and    $0x200,%edx
80105d54:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80105d5a:	c9                   	leave  
80105d5b:	c3                   	ret    

80105d5c <popcli>:

void
popcli(void)
{
80105d5c:	55                   	push   %ebp
80105d5d:	89 e5                	mov    %esp,%ebp
80105d5f:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
80105d62:	e8 c5 fd ff ff       	call   80105b2c <readeflags>
80105d67:	25 00 02 00 00       	and    $0x200,%eax
80105d6c:	85 c0                	test   %eax,%eax
80105d6e:	74 0c                	je     80105d7c <popcli+0x20>
    panic("popcli - interruptible");
80105d70:	c7 04 24 18 9c 10 80 	movl   $0x80109c18,(%esp)
80105d77:	e8 c1 a7 ff ff       	call   8010053d <panic>
  if(--cpu->ncli < 0)
80105d7c:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105d82:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80105d88:	83 ea 01             	sub    $0x1,%edx
80105d8b:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80105d91:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105d97:	85 c0                	test   %eax,%eax
80105d99:	79 0c                	jns    80105da7 <popcli+0x4b>
    panic("popcli");
80105d9b:	c7 04 24 2f 9c 10 80 	movl   $0x80109c2f,(%esp)
80105da2:	e8 96 a7 ff ff       	call   8010053d <panic>
  if(cpu->ncli == 0 && cpu->intena)
80105da7:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105dad:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105db3:	85 c0                	test   %eax,%eax
80105db5:	75 15                	jne    80105dcc <popcli+0x70>
80105db7:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105dbd:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80105dc3:	85 c0                	test   %eax,%eax
80105dc5:	74 05                	je     80105dcc <popcli+0x70>
    sti();
80105dc7:	e8 7b fd ff ff       	call   80105b47 <sti>
}
80105dcc:	c9                   	leave  
80105dcd:	c3                   	ret    
	...

80105dd0 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
80105dd0:	55                   	push   %ebp
80105dd1:	89 e5                	mov    %esp,%ebp
80105dd3:	57                   	push   %edi
80105dd4:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
80105dd5:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105dd8:	8b 55 10             	mov    0x10(%ebp),%edx
80105ddb:	8b 45 0c             	mov    0xc(%ebp),%eax
80105dde:	89 cb                	mov    %ecx,%ebx
80105de0:	89 df                	mov    %ebx,%edi
80105de2:	89 d1                	mov    %edx,%ecx
80105de4:	fc                   	cld    
80105de5:	f3 aa                	rep stos %al,%es:(%edi)
80105de7:	89 ca                	mov    %ecx,%edx
80105de9:	89 fb                	mov    %edi,%ebx
80105deb:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105dee:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105df1:	5b                   	pop    %ebx
80105df2:	5f                   	pop    %edi
80105df3:	5d                   	pop    %ebp
80105df4:	c3                   	ret    

80105df5 <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
80105df5:	55                   	push   %ebp
80105df6:	89 e5                	mov    %esp,%ebp
80105df8:	57                   	push   %edi
80105df9:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
80105dfa:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105dfd:	8b 55 10             	mov    0x10(%ebp),%edx
80105e00:	8b 45 0c             	mov    0xc(%ebp),%eax
80105e03:	89 cb                	mov    %ecx,%ebx
80105e05:	89 df                	mov    %ebx,%edi
80105e07:	89 d1                	mov    %edx,%ecx
80105e09:	fc                   	cld    
80105e0a:	f3 ab                	rep stos %eax,%es:(%edi)
80105e0c:	89 ca                	mov    %ecx,%edx
80105e0e:	89 fb                	mov    %edi,%ebx
80105e10:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105e13:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105e16:	5b                   	pop    %ebx
80105e17:	5f                   	pop    %edi
80105e18:	5d                   	pop    %ebp
80105e19:	c3                   	ret    

80105e1a <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80105e1a:	55                   	push   %ebp
80105e1b:	89 e5                	mov    %esp,%ebp
80105e1d:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
80105e20:	8b 45 08             	mov    0x8(%ebp),%eax
80105e23:	83 e0 03             	and    $0x3,%eax
80105e26:	85 c0                	test   %eax,%eax
80105e28:	75 49                	jne    80105e73 <memset+0x59>
80105e2a:	8b 45 10             	mov    0x10(%ebp),%eax
80105e2d:	83 e0 03             	and    $0x3,%eax
80105e30:	85 c0                	test   %eax,%eax
80105e32:	75 3f                	jne    80105e73 <memset+0x59>
    c &= 0xFF;
80105e34:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80105e3b:	8b 45 10             	mov    0x10(%ebp),%eax
80105e3e:	c1 e8 02             	shr    $0x2,%eax
80105e41:	89 c2                	mov    %eax,%edx
80105e43:	8b 45 0c             	mov    0xc(%ebp),%eax
80105e46:	89 c1                	mov    %eax,%ecx
80105e48:	c1 e1 18             	shl    $0x18,%ecx
80105e4b:	8b 45 0c             	mov    0xc(%ebp),%eax
80105e4e:	c1 e0 10             	shl    $0x10,%eax
80105e51:	09 c1                	or     %eax,%ecx
80105e53:	8b 45 0c             	mov    0xc(%ebp),%eax
80105e56:	c1 e0 08             	shl    $0x8,%eax
80105e59:	09 c8                	or     %ecx,%eax
80105e5b:	0b 45 0c             	or     0xc(%ebp),%eax
80105e5e:	89 54 24 08          	mov    %edx,0x8(%esp)
80105e62:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e66:	8b 45 08             	mov    0x8(%ebp),%eax
80105e69:	89 04 24             	mov    %eax,(%esp)
80105e6c:	e8 84 ff ff ff       	call   80105df5 <stosl>
80105e71:	eb 19                	jmp    80105e8c <memset+0x72>
  } else
    stosb(dst, c, n);
80105e73:	8b 45 10             	mov    0x10(%ebp),%eax
80105e76:	89 44 24 08          	mov    %eax,0x8(%esp)
80105e7a:	8b 45 0c             	mov    0xc(%ebp),%eax
80105e7d:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e81:	8b 45 08             	mov    0x8(%ebp),%eax
80105e84:	89 04 24             	mov    %eax,(%esp)
80105e87:	e8 44 ff ff ff       	call   80105dd0 <stosb>
  return dst;
80105e8c:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105e8f:	c9                   	leave  
80105e90:	c3                   	ret    

80105e91 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80105e91:	55                   	push   %ebp
80105e92:	89 e5                	mov    %esp,%ebp
80105e94:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
80105e97:	8b 45 08             	mov    0x8(%ebp),%eax
80105e9a:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
80105e9d:	8b 45 0c             	mov    0xc(%ebp),%eax
80105ea0:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
80105ea3:	eb 32                	jmp    80105ed7 <memcmp+0x46>
    if(*s1 != *s2)
80105ea5:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105ea8:	0f b6 10             	movzbl (%eax),%edx
80105eab:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105eae:	0f b6 00             	movzbl (%eax),%eax
80105eb1:	38 c2                	cmp    %al,%dl
80105eb3:	74 1a                	je     80105ecf <memcmp+0x3e>
      return *s1 - *s2;
80105eb5:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105eb8:	0f b6 00             	movzbl (%eax),%eax
80105ebb:	0f b6 d0             	movzbl %al,%edx
80105ebe:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105ec1:	0f b6 00             	movzbl (%eax),%eax
80105ec4:	0f b6 c0             	movzbl %al,%eax
80105ec7:	89 d1                	mov    %edx,%ecx
80105ec9:	29 c1                	sub    %eax,%ecx
80105ecb:	89 c8                	mov    %ecx,%eax
80105ecd:	eb 1c                	jmp    80105eeb <memcmp+0x5a>
    s1++, s2++;
80105ecf:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105ed3:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80105ed7:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105edb:	0f 95 c0             	setne  %al
80105ede:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105ee2:	84 c0                	test   %al,%al
80105ee4:	75 bf                	jne    80105ea5 <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
80105ee6:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105eeb:	c9                   	leave  
80105eec:	c3                   	ret    

80105eed <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80105eed:	55                   	push   %ebp
80105eee:	89 e5                	mov    %esp,%ebp
80105ef0:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
80105ef3:	8b 45 0c             	mov    0xc(%ebp),%eax
80105ef6:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
80105ef9:	8b 45 08             	mov    0x8(%ebp),%eax
80105efc:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
80105eff:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105f02:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105f05:	73 54                	jae    80105f5b <memmove+0x6e>
80105f07:	8b 45 10             	mov    0x10(%ebp),%eax
80105f0a:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105f0d:	01 d0                	add    %edx,%eax
80105f0f:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105f12:	76 47                	jbe    80105f5b <memmove+0x6e>
    s += n;
80105f14:	8b 45 10             	mov    0x10(%ebp),%eax
80105f17:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
80105f1a:	8b 45 10             	mov    0x10(%ebp),%eax
80105f1d:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
80105f20:	eb 13                	jmp    80105f35 <memmove+0x48>
      *--d = *--s;
80105f22:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
80105f26:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
80105f2a:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105f2d:	0f b6 10             	movzbl (%eax),%edx
80105f30:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105f33:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
80105f35:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105f39:	0f 95 c0             	setne  %al
80105f3c:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105f40:	84 c0                	test   %al,%al
80105f42:	75 de                	jne    80105f22 <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80105f44:	eb 25                	jmp    80105f6b <memmove+0x7e>
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
      *d++ = *s++;
80105f46:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105f49:	0f b6 10             	movzbl (%eax),%edx
80105f4c:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105f4f:	88 10                	mov    %dl,(%eax)
80105f51:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105f55:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105f59:	eb 01                	jmp    80105f5c <memmove+0x6f>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
80105f5b:	90                   	nop
80105f5c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105f60:	0f 95 c0             	setne  %al
80105f63:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105f67:	84 c0                	test   %al,%al
80105f69:	75 db                	jne    80105f46 <memmove+0x59>
      *d++ = *s++;

  return dst;
80105f6b:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105f6e:	c9                   	leave  
80105f6f:	c3                   	ret    

80105f70 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80105f70:	55                   	push   %ebp
80105f71:	89 e5                	mov    %esp,%ebp
80105f73:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
80105f76:	8b 45 10             	mov    0x10(%ebp),%eax
80105f79:	89 44 24 08          	mov    %eax,0x8(%esp)
80105f7d:	8b 45 0c             	mov    0xc(%ebp),%eax
80105f80:	89 44 24 04          	mov    %eax,0x4(%esp)
80105f84:	8b 45 08             	mov    0x8(%ebp),%eax
80105f87:	89 04 24             	mov    %eax,(%esp)
80105f8a:	e8 5e ff ff ff       	call   80105eed <memmove>
}
80105f8f:	c9                   	leave  
80105f90:	c3                   	ret    

80105f91 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80105f91:	55                   	push   %ebp
80105f92:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
80105f94:	eb 0c                	jmp    80105fa2 <strncmp+0x11>
    n--, p++, q++;
80105f96:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105f9a:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105f9e:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
80105fa2:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105fa6:	74 1a                	je     80105fc2 <strncmp+0x31>
80105fa8:	8b 45 08             	mov    0x8(%ebp),%eax
80105fab:	0f b6 00             	movzbl (%eax),%eax
80105fae:	84 c0                	test   %al,%al
80105fb0:	74 10                	je     80105fc2 <strncmp+0x31>
80105fb2:	8b 45 08             	mov    0x8(%ebp),%eax
80105fb5:	0f b6 10             	movzbl (%eax),%edx
80105fb8:	8b 45 0c             	mov    0xc(%ebp),%eax
80105fbb:	0f b6 00             	movzbl (%eax),%eax
80105fbe:	38 c2                	cmp    %al,%dl
80105fc0:	74 d4                	je     80105f96 <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
80105fc2:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105fc6:	75 07                	jne    80105fcf <strncmp+0x3e>
    return 0;
80105fc8:	b8 00 00 00 00       	mov    $0x0,%eax
80105fcd:	eb 18                	jmp    80105fe7 <strncmp+0x56>
  return (uchar)*p - (uchar)*q;
80105fcf:	8b 45 08             	mov    0x8(%ebp),%eax
80105fd2:	0f b6 00             	movzbl (%eax),%eax
80105fd5:	0f b6 d0             	movzbl %al,%edx
80105fd8:	8b 45 0c             	mov    0xc(%ebp),%eax
80105fdb:	0f b6 00             	movzbl (%eax),%eax
80105fde:	0f b6 c0             	movzbl %al,%eax
80105fe1:	89 d1                	mov    %edx,%ecx
80105fe3:	29 c1                	sub    %eax,%ecx
80105fe5:	89 c8                	mov    %ecx,%eax
}
80105fe7:	5d                   	pop    %ebp
80105fe8:	c3                   	ret    

80105fe9 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80105fe9:	55                   	push   %ebp
80105fea:	89 e5                	mov    %esp,%ebp
80105fec:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105fef:	8b 45 08             	mov    0x8(%ebp),%eax
80105ff2:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
80105ff5:	90                   	nop
80105ff6:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105ffa:	0f 9f c0             	setg   %al
80105ffd:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80106001:	84 c0                	test   %al,%al
80106003:	74 30                	je     80106035 <strncpy+0x4c>
80106005:	8b 45 0c             	mov    0xc(%ebp),%eax
80106008:	0f b6 10             	movzbl (%eax),%edx
8010600b:	8b 45 08             	mov    0x8(%ebp),%eax
8010600e:	88 10                	mov    %dl,(%eax)
80106010:	8b 45 08             	mov    0x8(%ebp),%eax
80106013:	0f b6 00             	movzbl (%eax),%eax
80106016:	84 c0                	test   %al,%al
80106018:	0f 95 c0             	setne  %al
8010601b:	83 45 08 01          	addl   $0x1,0x8(%ebp)
8010601f:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
80106023:	84 c0                	test   %al,%al
80106025:	75 cf                	jne    80105ff6 <strncpy+0xd>
    ;
  while(n-- > 0)
80106027:	eb 0c                	jmp    80106035 <strncpy+0x4c>
    *s++ = 0;
80106029:	8b 45 08             	mov    0x8(%ebp),%eax
8010602c:	c6 00 00             	movb   $0x0,(%eax)
8010602f:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80106033:	eb 01                	jmp    80106036 <strncpy+0x4d>
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
80106035:	90                   	nop
80106036:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010603a:	0f 9f c0             	setg   %al
8010603d:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80106041:	84 c0                	test   %al,%al
80106043:	75 e4                	jne    80106029 <strncpy+0x40>
    *s++ = 0;
  return os;
80106045:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80106048:	c9                   	leave  
80106049:	c3                   	ret    

8010604a <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
8010604a:	55                   	push   %ebp
8010604b:	89 e5                	mov    %esp,%ebp
8010604d:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80106050:	8b 45 08             	mov    0x8(%ebp),%eax
80106053:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
80106056:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010605a:	7f 05                	jg     80106061 <safestrcpy+0x17>
    return os;
8010605c:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010605f:	eb 35                	jmp    80106096 <safestrcpy+0x4c>
  while(--n > 0 && (*s++ = *t++) != 0)
80106061:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80106065:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80106069:	7e 22                	jle    8010608d <safestrcpy+0x43>
8010606b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010606e:	0f b6 10             	movzbl (%eax),%edx
80106071:	8b 45 08             	mov    0x8(%ebp),%eax
80106074:	88 10                	mov    %dl,(%eax)
80106076:	8b 45 08             	mov    0x8(%ebp),%eax
80106079:	0f b6 00             	movzbl (%eax),%eax
8010607c:	84 c0                	test   %al,%al
8010607e:	0f 95 c0             	setne  %al
80106081:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80106085:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
80106089:	84 c0                	test   %al,%al
8010608b:	75 d4                	jne    80106061 <safestrcpy+0x17>
    ;
  *s = 0;
8010608d:	8b 45 08             	mov    0x8(%ebp),%eax
80106090:	c6 00 00             	movb   $0x0,(%eax)
  return os;
80106093:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80106096:	c9                   	leave  
80106097:	c3                   	ret    

80106098 <strlen>:

int
strlen(const char *s)
{
80106098:	55                   	push   %ebp
80106099:	89 e5                	mov    %esp,%ebp
8010609b:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
8010609e:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801060a5:	eb 04                	jmp    801060ab <strlen+0x13>
801060a7:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801060ab:	8b 45 fc             	mov    -0x4(%ebp),%eax
801060ae:	03 45 08             	add    0x8(%ebp),%eax
801060b1:	0f b6 00             	movzbl (%eax),%eax
801060b4:	84 c0                	test   %al,%al
801060b6:	75 ef                	jne    801060a7 <strlen+0xf>
    ;
  return n;
801060b8:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801060bb:	c9                   	leave  
801060bc:	c3                   	ret    
801060bd:	00 00                	add    %al,(%eax)
	...

801060c0 <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
801060c0:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
801060c4:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
801060c8:	55                   	push   %ebp
  pushl %ebx
801060c9:	53                   	push   %ebx
  pushl %esi
801060ca:	56                   	push   %esi
  pushl %edi
801060cb:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
801060cc:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
801060ce:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
801060d0:	5f                   	pop    %edi
  popl %esi
801060d1:	5e                   	pop    %esi
  popl %ebx
801060d2:	5b                   	pop    %ebx
  popl %ebp
801060d3:	5d                   	pop    %ebp
  ret
801060d4:	c3                   	ret    
801060d5:	00 00                	add    %al,(%eax)
	...

801060d8 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from process p.
int
fetchint(struct proc *p, uint addr, int *ip)
{
801060d8:	55                   	push   %ebp
801060d9:	89 e5                	mov    %esp,%ebp
  if(addr >= p->sz || addr+4 > p->sz)
801060db:	8b 45 08             	mov    0x8(%ebp),%eax
801060de:	8b 00                	mov    (%eax),%eax
801060e0:	3b 45 0c             	cmp    0xc(%ebp),%eax
801060e3:	76 0f                	jbe    801060f4 <fetchint+0x1c>
801060e5:	8b 45 0c             	mov    0xc(%ebp),%eax
801060e8:	8d 50 04             	lea    0x4(%eax),%edx
801060eb:	8b 45 08             	mov    0x8(%ebp),%eax
801060ee:	8b 00                	mov    (%eax),%eax
801060f0:	39 c2                	cmp    %eax,%edx
801060f2:	76 07                	jbe    801060fb <fetchint+0x23>
    return -1;
801060f4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801060f9:	eb 0f                	jmp    8010610a <fetchint+0x32>
  *ip = *(int*)(addr);
801060fb:	8b 45 0c             	mov    0xc(%ebp),%eax
801060fe:	8b 10                	mov    (%eax),%edx
80106100:	8b 45 10             	mov    0x10(%ebp),%eax
80106103:	89 10                	mov    %edx,(%eax)
  return 0;
80106105:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010610a:	5d                   	pop    %ebp
8010610b:	c3                   	ret    

8010610c <fetchstr>:
// Fetch the nul-terminated string at addr from process p.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(struct proc *p, uint addr, char **pp)
{
8010610c:	55                   	push   %ebp
8010610d:	89 e5                	mov    %esp,%ebp
8010610f:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= p->sz)
80106112:	8b 45 08             	mov    0x8(%ebp),%eax
80106115:	8b 00                	mov    (%eax),%eax
80106117:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010611a:	77 07                	ja     80106123 <fetchstr+0x17>
    return -1;
8010611c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106121:	eb 45                	jmp    80106168 <fetchstr+0x5c>
  *pp = (char*)addr;
80106123:	8b 55 0c             	mov    0xc(%ebp),%edx
80106126:	8b 45 10             	mov    0x10(%ebp),%eax
80106129:	89 10                	mov    %edx,(%eax)
  ep = (char*)p->sz;
8010612b:	8b 45 08             	mov    0x8(%ebp),%eax
8010612e:	8b 00                	mov    (%eax),%eax
80106130:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
80106133:	8b 45 10             	mov    0x10(%ebp),%eax
80106136:	8b 00                	mov    (%eax),%eax
80106138:	89 45 fc             	mov    %eax,-0x4(%ebp)
8010613b:	eb 1e                	jmp    8010615b <fetchstr+0x4f>
    if(*s == 0)
8010613d:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106140:	0f b6 00             	movzbl (%eax),%eax
80106143:	84 c0                	test   %al,%al
80106145:	75 10                	jne    80106157 <fetchstr+0x4b>
      return s - *pp;
80106147:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010614a:	8b 45 10             	mov    0x10(%ebp),%eax
8010614d:	8b 00                	mov    (%eax),%eax
8010614f:	89 d1                	mov    %edx,%ecx
80106151:	29 c1                	sub    %eax,%ecx
80106153:	89 c8                	mov    %ecx,%eax
80106155:	eb 11                	jmp    80106168 <fetchstr+0x5c>

  if(addr >= p->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)p->sz;
  for(s = *pp; s < ep; s++)
80106157:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010615b:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010615e:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80106161:	72 da                	jb     8010613d <fetchstr+0x31>
    if(*s == 0)
      return s - *pp;
  return -1;
80106163:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80106168:	c9                   	leave  
80106169:	c3                   	ret    

8010616a <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
8010616a:	55                   	push   %ebp
8010616b:	89 e5                	mov    %esp,%ebp
8010616d:	83 ec 0c             	sub    $0xc,%esp
  return fetchint(proc, proc->tf->esp + 4 + 4*n, ip);
80106170:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106176:	8b 40 18             	mov    0x18(%eax),%eax
80106179:	8b 50 44             	mov    0x44(%eax),%edx
8010617c:	8b 45 08             	mov    0x8(%ebp),%eax
8010617f:	c1 e0 02             	shl    $0x2,%eax
80106182:	01 d0                	add    %edx,%eax
80106184:	8d 48 04             	lea    0x4(%eax),%ecx
80106187:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010618d:	8b 55 0c             	mov    0xc(%ebp),%edx
80106190:	89 54 24 08          	mov    %edx,0x8(%esp)
80106194:	89 4c 24 04          	mov    %ecx,0x4(%esp)
80106198:	89 04 24             	mov    %eax,(%esp)
8010619b:	e8 38 ff ff ff       	call   801060d8 <fetchint>
}
801061a0:	c9                   	leave  
801061a1:	c3                   	ret    

801061a2 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
801061a2:	55                   	push   %ebp
801061a3:	89 e5                	mov    %esp,%ebp
801061a5:	83 ec 18             	sub    $0x18,%esp
  int i;

  if(argint(n, &i) < 0)
801061a8:	8d 45 fc             	lea    -0x4(%ebp),%eax
801061ab:	89 44 24 04          	mov    %eax,0x4(%esp)
801061af:	8b 45 08             	mov    0x8(%ebp),%eax
801061b2:	89 04 24             	mov    %eax,(%esp)
801061b5:	e8 b0 ff ff ff       	call   8010616a <argint>
801061ba:	85 c0                	test   %eax,%eax
801061bc:	79 07                	jns    801061c5 <argptr+0x23>
    return -1;
801061be:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061c3:	eb 3d                	jmp    80106202 <argptr+0x60>

  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
801061c5:	8b 45 fc             	mov    -0x4(%ebp),%eax
801061c8:	89 c2                	mov    %eax,%edx
801061ca:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801061d0:	8b 00                	mov    (%eax),%eax
801061d2:	39 c2                	cmp    %eax,%edx
801061d4:	73 16                	jae    801061ec <argptr+0x4a>
801061d6:	8b 45 fc             	mov    -0x4(%ebp),%eax
801061d9:	89 c2                	mov    %eax,%edx
801061db:	8b 45 10             	mov    0x10(%ebp),%eax
801061de:	01 c2                	add    %eax,%edx
801061e0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801061e6:	8b 00                	mov    (%eax),%eax
801061e8:	39 c2                	cmp    %eax,%edx
801061ea:	76 07                	jbe    801061f3 <argptr+0x51>
    return -1;
801061ec:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061f1:	eb 0f                	jmp    80106202 <argptr+0x60>
  *pp = (char*)i;
801061f3:	8b 45 fc             	mov    -0x4(%ebp),%eax
801061f6:	89 c2                	mov    %eax,%edx
801061f8:	8b 45 0c             	mov    0xc(%ebp),%eax
801061fb:	89 10                	mov    %edx,(%eax)
  return 0;
801061fd:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106202:	c9                   	leave  
80106203:	c3                   	ret    

80106204 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80106204:	55                   	push   %ebp
80106205:	89 e5                	mov    %esp,%ebp
80106207:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  if(argint(n, &addr) < 0)
8010620a:	8d 45 fc             	lea    -0x4(%ebp),%eax
8010620d:	89 44 24 04          	mov    %eax,0x4(%esp)
80106211:	8b 45 08             	mov    0x8(%ebp),%eax
80106214:	89 04 24             	mov    %eax,(%esp)
80106217:	e8 4e ff ff ff       	call   8010616a <argint>
8010621c:	85 c0                	test   %eax,%eax
8010621e:	79 07                	jns    80106227 <argstr+0x23>
    return -1;
80106220:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106225:	eb 1e                	jmp    80106245 <argstr+0x41>
  return fetchstr(proc, addr, pp);
80106227:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010622a:	89 c2                	mov    %eax,%edx
8010622c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106232:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80106235:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106239:	89 54 24 04          	mov    %edx,0x4(%esp)
8010623d:	89 04 24             	mov    %eax,(%esp)
80106240:	e8 c7 fe ff ff       	call   8010610c <fetchstr>
}
80106245:	c9                   	leave  
80106246:	c3                   	ret    

80106247 <syscall>:
[SYS_shmdt]	sys_shmdt,
};

void
syscall(void)
{
80106247:	55                   	push   %ebp
80106248:	89 e5                	mov    %esp,%ebp
8010624a:	53                   	push   %ebx
8010624b:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->tf->eax;
8010624e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106254:	8b 40 18             	mov    0x18(%eax),%eax
80106257:	8b 40 1c             	mov    0x1c(%eax),%eax
8010625a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num >= 0 && num < SYS_open && syscalls[num]) {
8010625d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106261:	78 2e                	js     80106291 <syscall+0x4a>
80106263:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
80106267:	7f 28                	jg     80106291 <syscall+0x4a>
80106269:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010626c:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
80106273:	85 c0                	test   %eax,%eax
80106275:	74 1a                	je     80106291 <syscall+0x4a>
    proc->tf->eax = syscalls[num]();
80106277:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010627d:	8b 58 18             	mov    0x18(%eax),%ebx
80106280:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106283:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
8010628a:	ff d0                	call   *%eax
8010628c:	89 43 1c             	mov    %eax,0x1c(%ebx)
8010628f:	eb 73                	jmp    80106304 <syscall+0xbd>
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
80106291:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
80106295:	7e 30                	jle    801062c7 <syscall+0x80>
80106297:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010629a:	83 f8 1e             	cmp    $0x1e,%eax
8010629d:	77 28                	ja     801062c7 <syscall+0x80>
8010629f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062a2:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
801062a9:	85 c0                	test   %eax,%eax
801062ab:	74 1a                	je     801062c7 <syscall+0x80>
    proc->tf->eax = syscalls[num]();
801062ad:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801062b3:	8b 58 18             	mov    0x18(%eax),%ebx
801062b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062b9:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
801062c0:	ff d0                	call   *%eax
801062c2:	89 43 1c             	mov    %eax,0x1c(%ebx)
801062c5:	eb 3d                	jmp    80106304 <syscall+0xbd>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
801062c7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801062cd:	8d 48 6c             	lea    0x6c(%eax),%ecx
801062d0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  if(num >= 0 && num < SYS_open && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
801062d6:	8b 40 10             	mov    0x10(%eax),%eax
801062d9:	8b 55 f4             	mov    -0xc(%ebp),%edx
801062dc:	89 54 24 0c          	mov    %edx,0xc(%esp)
801062e0:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801062e4:	89 44 24 04          	mov    %eax,0x4(%esp)
801062e8:	c7 04 24 36 9c 10 80 	movl   $0x80109c36,(%esp)
801062ef:	e8 ad a0 ff ff       	call   801003a1 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
801062f4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801062fa:	8b 40 18             	mov    0x18(%eax),%eax
801062fd:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
80106304:	83 c4 24             	add    $0x24,%esp
80106307:	5b                   	pop    %ebx
80106308:	5d                   	pop    %ebp
80106309:	c3                   	ret    
	...

8010630c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
8010630c:	55                   	push   %ebp
8010630d:	89 e5                	mov    %esp,%ebp
8010630f:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
80106312:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106315:	89 44 24 04          	mov    %eax,0x4(%esp)
80106319:	8b 45 08             	mov    0x8(%ebp),%eax
8010631c:	89 04 24             	mov    %eax,(%esp)
8010631f:	e8 46 fe ff ff       	call   8010616a <argint>
80106324:	85 c0                	test   %eax,%eax
80106326:	79 07                	jns    8010632f <argfd+0x23>
    return -1;
80106328:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010632d:	eb 50                	jmp    8010637f <argfd+0x73>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
8010632f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106332:	85 c0                	test   %eax,%eax
80106334:	78 21                	js     80106357 <argfd+0x4b>
80106336:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106339:	83 f8 0f             	cmp    $0xf,%eax
8010633c:	7f 19                	jg     80106357 <argfd+0x4b>
8010633e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106344:	8b 55 f0             	mov    -0x10(%ebp),%edx
80106347:	83 c2 08             	add    $0x8,%edx
8010634a:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010634e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106351:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106355:	75 07                	jne    8010635e <argfd+0x52>
    return -1;
80106357:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010635c:	eb 21                	jmp    8010637f <argfd+0x73>
  if(pfd)
8010635e:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80106362:	74 08                	je     8010636c <argfd+0x60>
    *pfd = fd;
80106364:	8b 55 f0             	mov    -0x10(%ebp),%edx
80106367:	8b 45 0c             	mov    0xc(%ebp),%eax
8010636a:	89 10                	mov    %edx,(%eax)
  if(pf)
8010636c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80106370:	74 08                	je     8010637a <argfd+0x6e>
    *pf = f;
80106372:	8b 45 10             	mov    0x10(%ebp),%eax
80106375:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106378:	89 10                	mov    %edx,(%eax)
  return 0;
8010637a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010637f:	c9                   	leave  
80106380:	c3                   	ret    

80106381 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
80106381:	55                   	push   %ebp
80106382:	89 e5                	mov    %esp,%ebp
80106384:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80106387:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
8010638e:	eb 30                	jmp    801063c0 <fdalloc+0x3f>
    if(proc->ofile[fd] == 0){
80106390:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106396:	8b 55 fc             	mov    -0x4(%ebp),%edx
80106399:	83 c2 08             	add    $0x8,%edx
8010639c:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801063a0:	85 c0                	test   %eax,%eax
801063a2:	75 18                	jne    801063bc <fdalloc+0x3b>
      proc->ofile[fd] = f;
801063a4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801063aa:	8b 55 fc             	mov    -0x4(%ebp),%edx
801063ad:	8d 4a 08             	lea    0x8(%edx),%ecx
801063b0:	8b 55 08             	mov    0x8(%ebp),%edx
801063b3:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
801063b7:	8b 45 fc             	mov    -0x4(%ebp),%eax
801063ba:	eb 0f                	jmp    801063cb <fdalloc+0x4a>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
801063bc:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801063c0:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
801063c4:	7e ca                	jle    80106390 <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
801063c6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801063cb:	c9                   	leave  
801063cc:	c3                   	ret    

801063cd <sys_dup>:

int
sys_dup(void)
{
801063cd:	55                   	push   %ebp
801063ce:	89 e5                	mov    %esp,%ebp
801063d0:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
801063d3:	8d 45 f0             	lea    -0x10(%ebp),%eax
801063d6:	89 44 24 08          	mov    %eax,0x8(%esp)
801063da:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801063e1:	00 
801063e2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801063e9:	e8 1e ff ff ff       	call   8010630c <argfd>
801063ee:	85 c0                	test   %eax,%eax
801063f0:	79 07                	jns    801063f9 <sys_dup+0x2c>
    return -1;
801063f2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801063f7:	eb 29                	jmp    80106422 <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
801063f9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801063fc:	89 04 24             	mov    %eax,(%esp)
801063ff:	e8 7d ff ff ff       	call   80106381 <fdalloc>
80106404:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106407:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010640b:	79 07                	jns    80106414 <sys_dup+0x47>
    return -1;
8010640d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106412:	eb 0e                	jmp    80106422 <sys_dup+0x55>
  filedup(f);
80106414:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106417:	89 04 24             	mov    %eax,(%esp)
8010641a:	e8 5d ab ff ff       	call   80100f7c <filedup>
  return fd;
8010641f:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80106422:	c9                   	leave  
80106423:	c3                   	ret    

80106424 <sys_read>:

int
sys_read(void)
{
80106424:	55                   	push   %ebp
80106425:	89 e5                	mov    %esp,%ebp
80106427:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
8010642a:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010642d:	89 44 24 08          	mov    %eax,0x8(%esp)
80106431:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106438:	00 
80106439:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106440:	e8 c7 fe ff ff       	call   8010630c <argfd>
80106445:	85 c0                	test   %eax,%eax
80106447:	78 35                	js     8010647e <sys_read+0x5a>
80106449:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010644c:	89 44 24 04          	mov    %eax,0x4(%esp)
80106450:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80106457:	e8 0e fd ff ff       	call   8010616a <argint>
8010645c:	85 c0                	test   %eax,%eax
8010645e:	78 1e                	js     8010647e <sys_read+0x5a>
80106460:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106463:	89 44 24 08          	mov    %eax,0x8(%esp)
80106467:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010646a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010646e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106475:	e8 28 fd ff ff       	call   801061a2 <argptr>
8010647a:	85 c0                	test   %eax,%eax
8010647c:	79 07                	jns    80106485 <sys_read+0x61>
    return -1;
8010647e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106483:	eb 19                	jmp    8010649e <sys_read+0x7a>
  return fileread(f, p, n);
80106485:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80106488:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010648b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010648e:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106492:	89 54 24 04          	mov    %edx,0x4(%esp)
80106496:	89 04 24             	mov    %eax,(%esp)
80106499:	e8 4b ac ff ff       	call   801010e9 <fileread>
}
8010649e:	c9                   	leave  
8010649f:	c3                   	ret    

801064a0 <sys_write>:

int
sys_write(void)
{
801064a0:	55                   	push   %ebp
801064a1:	89 e5                	mov    %esp,%ebp
801064a3:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801064a6:	8d 45 f4             	lea    -0xc(%ebp),%eax
801064a9:	89 44 24 08          	mov    %eax,0x8(%esp)
801064ad:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801064b4:	00 
801064b5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801064bc:	e8 4b fe ff ff       	call   8010630c <argfd>
801064c1:	85 c0                	test   %eax,%eax
801064c3:	78 35                	js     801064fa <sys_write+0x5a>
801064c5:	8d 45 f0             	lea    -0x10(%ebp),%eax
801064c8:	89 44 24 04          	mov    %eax,0x4(%esp)
801064cc:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801064d3:	e8 92 fc ff ff       	call   8010616a <argint>
801064d8:	85 c0                	test   %eax,%eax
801064da:	78 1e                	js     801064fa <sys_write+0x5a>
801064dc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064df:	89 44 24 08          	mov    %eax,0x8(%esp)
801064e3:	8d 45 ec             	lea    -0x14(%ebp),%eax
801064e6:	89 44 24 04          	mov    %eax,0x4(%esp)
801064ea:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801064f1:	e8 ac fc ff ff       	call   801061a2 <argptr>
801064f6:	85 c0                	test   %eax,%eax
801064f8:	79 07                	jns    80106501 <sys_write+0x61>
    return -1;
801064fa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801064ff:	eb 19                	jmp    8010651a <sys_write+0x7a>
  return filewrite(f, p, n);
80106501:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80106504:	8b 55 ec             	mov    -0x14(%ebp),%edx
80106507:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010650a:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010650e:	89 54 24 04          	mov    %edx,0x4(%esp)
80106512:	89 04 24             	mov    %eax,(%esp)
80106515:	e8 8b ac ff ff       	call   801011a5 <filewrite>
}
8010651a:	c9                   	leave  
8010651b:	c3                   	ret    

8010651c <sys_close>:

int
sys_close(void)
{
8010651c:	55                   	push   %ebp
8010651d:	89 e5                	mov    %esp,%ebp
8010651f:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
80106522:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106525:	89 44 24 08          	mov    %eax,0x8(%esp)
80106529:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010652c:	89 44 24 04          	mov    %eax,0x4(%esp)
80106530:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106537:	e8 d0 fd ff ff       	call   8010630c <argfd>
8010653c:	85 c0                	test   %eax,%eax
8010653e:	79 07                	jns    80106547 <sys_close+0x2b>
    return -1;
80106540:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106545:	eb 24                	jmp    8010656b <sys_close+0x4f>
  proc->ofile[fd] = 0;
80106547:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010654d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106550:	83 c2 08             	add    $0x8,%edx
80106553:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
8010655a:	00 
  fileclose(f);
8010655b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010655e:	89 04 24             	mov    %eax,(%esp)
80106561:	e8 5e aa ff ff       	call   80100fc4 <fileclose>
  return 0;
80106566:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010656b:	c9                   	leave  
8010656c:	c3                   	ret    

8010656d <sys_fstat>:

int
sys_fstat(void)
{
8010656d:	55                   	push   %ebp
8010656e:	89 e5                	mov    %esp,%ebp
80106570:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
80106573:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106576:	89 44 24 08          	mov    %eax,0x8(%esp)
8010657a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106581:	00 
80106582:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106589:	e8 7e fd ff ff       	call   8010630c <argfd>
8010658e:	85 c0                	test   %eax,%eax
80106590:	78 1f                	js     801065b1 <sys_fstat+0x44>
80106592:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80106599:	00 
8010659a:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010659d:	89 44 24 04          	mov    %eax,0x4(%esp)
801065a1:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801065a8:	e8 f5 fb ff ff       	call   801061a2 <argptr>
801065ad:	85 c0                	test   %eax,%eax
801065af:	79 07                	jns    801065b8 <sys_fstat+0x4b>
    return -1;
801065b1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801065b6:	eb 12                	jmp    801065ca <sys_fstat+0x5d>
  return filestat(f, st);
801065b8:	8b 55 f0             	mov    -0x10(%ebp),%edx
801065bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065be:	89 54 24 04          	mov    %edx,0x4(%esp)
801065c2:	89 04 24             	mov    %eax,(%esp)
801065c5:	e8 d0 aa ff ff       	call   8010109a <filestat>
}
801065ca:	c9                   	leave  
801065cb:	c3                   	ret    

801065cc <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
801065cc:	55                   	push   %ebp
801065cd:	89 e5                	mov    %esp,%ebp
801065cf:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
801065d2:	8d 45 d8             	lea    -0x28(%ebp),%eax
801065d5:	89 44 24 04          	mov    %eax,0x4(%esp)
801065d9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801065e0:	e8 1f fc ff ff       	call   80106204 <argstr>
801065e5:	85 c0                	test   %eax,%eax
801065e7:	78 17                	js     80106600 <sys_link+0x34>
801065e9:	8d 45 dc             	lea    -0x24(%ebp),%eax
801065ec:	89 44 24 04          	mov    %eax,0x4(%esp)
801065f0:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801065f7:	e8 08 fc ff ff       	call   80106204 <argstr>
801065fc:	85 c0                	test   %eax,%eax
801065fe:	79 0a                	jns    8010660a <sys_link+0x3e>
    return -1;
80106600:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106605:	e9 3c 01 00 00       	jmp    80106746 <sys_link+0x17a>
  if((ip = namei(old)) == 0)
8010660a:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010660d:	89 04 24             	mov    %eax,(%esp)
80106610:	e8 f5 bd ff ff       	call   8010240a <namei>
80106615:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106618:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010661c:	75 0a                	jne    80106628 <sys_link+0x5c>
    return -1;
8010661e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106623:	e9 1e 01 00 00       	jmp    80106746 <sys_link+0x17a>

  begin_trans();
80106628:	e8 f2 d3 ff ff       	call   80103a1f <begin_trans>

  ilock(ip);
8010662d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106630:	89 04 24             	mov    %eax,(%esp)
80106633:	e8 30 b2 ff ff       	call   80101868 <ilock>
  if(ip->type == T_DIR){
80106638:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010663b:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010663f:	66 83 f8 01          	cmp    $0x1,%ax
80106643:	75 1a                	jne    8010665f <sys_link+0x93>
    iunlockput(ip);
80106645:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106648:	89 04 24             	mov    %eax,(%esp)
8010664b:	e8 9c b4 ff ff       	call   80101aec <iunlockput>
    commit_trans();
80106650:	e8 1c d4 ff ff       	call   80103a71 <commit_trans>
    return -1;
80106655:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010665a:	e9 e7 00 00 00       	jmp    80106746 <sys_link+0x17a>
  }

  ip->nlink++;
8010665f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106662:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106666:	8d 50 01             	lea    0x1(%eax),%edx
80106669:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010666c:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80106670:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106673:	89 04 24             	mov    %eax,(%esp)
80106676:	e8 31 b0 ff ff       	call   801016ac <iupdate>
  iunlock(ip);
8010667b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010667e:	89 04 24             	mov    %eax,(%esp)
80106681:	e8 30 b3 ff ff       	call   801019b6 <iunlock>

  if((dp = nameiparent(new, name)) == 0)
80106686:	8b 45 dc             	mov    -0x24(%ebp),%eax
80106689:	8d 55 e2             	lea    -0x1e(%ebp),%edx
8010668c:	89 54 24 04          	mov    %edx,0x4(%esp)
80106690:	89 04 24             	mov    %eax,(%esp)
80106693:	e8 94 bd ff ff       	call   8010242c <nameiparent>
80106698:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010669b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010669f:	74 68                	je     80106709 <sys_link+0x13d>
    goto bad;
  ilock(dp);
801066a1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801066a4:	89 04 24             	mov    %eax,(%esp)
801066a7:	e8 bc b1 ff ff       	call   80101868 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
801066ac:	8b 45 f0             	mov    -0x10(%ebp),%eax
801066af:	8b 10                	mov    (%eax),%edx
801066b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066b4:	8b 00                	mov    (%eax),%eax
801066b6:	39 c2                	cmp    %eax,%edx
801066b8:	75 20                	jne    801066da <sys_link+0x10e>
801066ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066bd:	8b 40 04             	mov    0x4(%eax),%eax
801066c0:	89 44 24 08          	mov    %eax,0x8(%esp)
801066c4:	8d 45 e2             	lea    -0x1e(%ebp),%eax
801066c7:	89 44 24 04          	mov    %eax,0x4(%esp)
801066cb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801066ce:	89 04 24             	mov    %eax,(%esp)
801066d1:	e8 73 ba ff ff       	call   80102149 <dirlink>
801066d6:	85 c0                	test   %eax,%eax
801066d8:	79 0d                	jns    801066e7 <sys_link+0x11b>
    iunlockput(dp);
801066da:	8b 45 f0             	mov    -0x10(%ebp),%eax
801066dd:	89 04 24             	mov    %eax,(%esp)
801066e0:	e8 07 b4 ff ff       	call   80101aec <iunlockput>
    goto bad;
801066e5:	eb 23                	jmp    8010670a <sys_link+0x13e>
  }
  iunlockput(dp);
801066e7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801066ea:	89 04 24             	mov    %eax,(%esp)
801066ed:	e8 fa b3 ff ff       	call   80101aec <iunlockput>
  iput(ip);
801066f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066f5:	89 04 24             	mov    %eax,(%esp)
801066f8:	e8 1e b3 ff ff       	call   80101a1b <iput>

  commit_trans();
801066fd:	e8 6f d3 ff ff       	call   80103a71 <commit_trans>

  return 0;
80106702:	b8 00 00 00 00       	mov    $0x0,%eax
80106707:	eb 3d                	jmp    80106746 <sys_link+0x17a>
  ip->nlink++;
  iupdate(ip);
  iunlock(ip);

  if((dp = nameiparent(new, name)) == 0)
    goto bad;
80106709:	90                   	nop
  commit_trans();

  return 0;

bad:
  ilock(ip);
8010670a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010670d:	89 04 24             	mov    %eax,(%esp)
80106710:	e8 53 b1 ff ff       	call   80101868 <ilock>
  ip->nlink--;
80106715:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106718:	0f b7 40 16          	movzwl 0x16(%eax),%eax
8010671c:	8d 50 ff             	lea    -0x1(%eax),%edx
8010671f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106722:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80106726:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106729:	89 04 24             	mov    %eax,(%esp)
8010672c:	e8 7b af ff ff       	call   801016ac <iupdate>
  iunlockput(ip);
80106731:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106734:	89 04 24             	mov    %eax,(%esp)
80106737:	e8 b0 b3 ff ff       	call   80101aec <iunlockput>
  commit_trans();
8010673c:	e8 30 d3 ff ff       	call   80103a71 <commit_trans>
  return -1;
80106741:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80106746:	c9                   	leave  
80106747:	c3                   	ret    

80106748 <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
80106748:	55                   	push   %ebp
80106749:	89 e5                	mov    %esp,%ebp
8010674b:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
8010674e:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
80106755:	eb 4b                	jmp    801067a2 <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80106757:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010675a:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80106761:	00 
80106762:	89 44 24 08          	mov    %eax,0x8(%esp)
80106766:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106769:	89 44 24 04          	mov    %eax,0x4(%esp)
8010676d:	8b 45 08             	mov    0x8(%ebp),%eax
80106770:	89 04 24             	mov    %eax,(%esp)
80106773:	e8 e6 b5 ff ff       	call   80101d5e <readi>
80106778:	83 f8 10             	cmp    $0x10,%eax
8010677b:	74 0c                	je     80106789 <isdirempty+0x41>
      panic("isdirempty: readi");
8010677d:	c7 04 24 52 9c 10 80 	movl   $0x80109c52,(%esp)
80106784:	e8 b4 9d ff ff       	call   8010053d <panic>
    if(de.inum != 0)
80106789:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
8010678d:	66 85 c0             	test   %ax,%ax
80106790:	74 07                	je     80106799 <isdirempty+0x51>
      return 0;
80106792:	b8 00 00 00 00       	mov    $0x0,%eax
80106797:	eb 1b                	jmp    801067b4 <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80106799:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010679c:	83 c0 10             	add    $0x10,%eax
8010679f:	89 45 f4             	mov    %eax,-0xc(%ebp)
801067a2:	8b 55 f4             	mov    -0xc(%ebp),%edx
801067a5:	8b 45 08             	mov    0x8(%ebp),%eax
801067a8:	8b 40 18             	mov    0x18(%eax),%eax
801067ab:	39 c2                	cmp    %eax,%edx
801067ad:	72 a8                	jb     80106757 <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
801067af:	b8 01 00 00 00       	mov    $0x1,%eax
}
801067b4:	c9                   	leave  
801067b5:	c3                   	ret    

801067b6 <unlink>:


int
unlink(char* path)
{
801067b6:	55                   	push   %ebp
801067b7:	89 e5                	mov    %esp,%ebp
801067b9:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ];
  uint off;

  if((dp = nameiparent(path, name)) == 0)
801067bc:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801067bf:	89 44 24 04          	mov    %eax,0x4(%esp)
801067c3:	8b 45 08             	mov    0x8(%ebp),%eax
801067c6:	89 04 24             	mov    %eax,(%esp)
801067c9:	e8 5e bc ff ff       	call   8010242c <nameiparent>
801067ce:	89 45 f4             	mov    %eax,-0xc(%ebp)
801067d1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801067d5:	75 0a                	jne    801067e1 <unlink+0x2b>
    return -1;
801067d7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801067dc:	e9 85 01 00 00       	jmp    80106966 <unlink+0x1b0>

  begin_trans();
801067e1:	e8 39 d2 ff ff       	call   80103a1f <begin_trans>

  ilock(dp);
801067e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067e9:	89 04 24             	mov    %eax,(%esp)
801067ec:	e8 77 b0 ff ff       	call   80101868 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
801067f1:	c7 44 24 04 64 9c 10 	movl   $0x80109c64,0x4(%esp)
801067f8:	80 
801067f9:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801067fc:	89 04 24             	mov    %eax,(%esp)
801067ff:	e8 5b b8 ff ff       	call   8010205f <namecmp>
80106804:	85 c0                	test   %eax,%eax
80106806:	0f 84 45 01 00 00    	je     80106951 <unlink+0x19b>
8010680c:	c7 44 24 04 66 9c 10 	movl   $0x80109c66,0x4(%esp)
80106813:	80 
80106814:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80106817:	89 04 24             	mov    %eax,(%esp)
8010681a:	e8 40 b8 ff ff       	call   8010205f <namecmp>
8010681f:	85 c0                	test   %eax,%eax
80106821:	0f 84 2a 01 00 00    	je     80106951 <unlink+0x19b>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
80106827:	8d 45 cc             	lea    -0x34(%ebp),%eax
8010682a:	89 44 24 08          	mov    %eax,0x8(%esp)
8010682e:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80106831:	89 44 24 04          	mov    %eax,0x4(%esp)
80106835:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106838:	89 04 24             	mov    %eax,(%esp)
8010683b:	e8 41 b8 ff ff       	call   80102081 <dirlookup>
80106840:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106843:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106847:	0f 84 03 01 00 00    	je     80106950 <unlink+0x19a>
    goto bad;
  ilock(ip);
8010684d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106850:	89 04 24             	mov    %eax,(%esp)
80106853:	e8 10 b0 ff ff       	call   80101868 <ilock>

  if(ip->nlink < 1)
80106858:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010685b:	0f b7 40 16          	movzwl 0x16(%eax),%eax
8010685f:	66 85 c0             	test   %ax,%ax
80106862:	7f 0c                	jg     80106870 <unlink+0xba>
    panic("unlink: nlink < 1");
80106864:	c7 04 24 69 9c 10 80 	movl   $0x80109c69,(%esp)
8010686b:	e8 cd 9c ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80106870:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106873:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106877:	66 83 f8 01          	cmp    $0x1,%ax
8010687b:	75 1f                	jne    8010689c <unlink+0xe6>
8010687d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106880:	89 04 24             	mov    %eax,(%esp)
80106883:	e8 c0 fe ff ff       	call   80106748 <isdirempty>
80106888:	85 c0                	test   %eax,%eax
8010688a:	75 10                	jne    8010689c <unlink+0xe6>
    iunlockput(ip);
8010688c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010688f:	89 04 24             	mov    %eax,(%esp)
80106892:	e8 55 b2 ff ff       	call   80101aec <iunlockput>
    goto bad;
80106897:	e9 b5 00 00 00       	jmp    80106951 <unlink+0x19b>
  }

  memset(&de, 0, sizeof(de));
8010689c:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
801068a3:	00 
801068a4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801068ab:	00 
801068ac:	8d 45 e0             	lea    -0x20(%ebp),%eax
801068af:	89 04 24             	mov    %eax,(%esp)
801068b2:	e8 63 f5 ff ff       	call   80105e1a <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801068b7:	8b 45 cc             	mov    -0x34(%ebp),%eax
801068ba:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801068c1:	00 
801068c2:	89 44 24 08          	mov    %eax,0x8(%esp)
801068c6:	8d 45 e0             	lea    -0x20(%ebp),%eax
801068c9:	89 44 24 04          	mov    %eax,0x4(%esp)
801068cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068d0:	89 04 24             	mov    %eax,(%esp)
801068d3:	e8 f1 b5 ff ff       	call   80101ec9 <writei>
801068d8:	83 f8 10             	cmp    $0x10,%eax
801068db:	74 0c                	je     801068e9 <unlink+0x133>
    panic("unlink: writei");
801068dd:	c7 04 24 7b 9c 10 80 	movl   $0x80109c7b,(%esp)
801068e4:	e8 54 9c ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR){
801068e9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801068ec:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801068f0:	66 83 f8 01          	cmp    $0x1,%ax
801068f4:	75 1c                	jne    80106912 <unlink+0x15c>
    dp->nlink--;
801068f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068f9:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801068fd:	8d 50 ff             	lea    -0x1(%eax),%edx
80106900:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106903:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80106907:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010690a:	89 04 24             	mov    %eax,(%esp)
8010690d:	e8 9a ad ff ff       	call   801016ac <iupdate>
  }
  iunlockput(dp);
80106912:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106915:	89 04 24             	mov    %eax,(%esp)
80106918:	e8 cf b1 ff ff       	call   80101aec <iunlockput>

  ip->nlink--;
8010691d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106920:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106924:	8d 50 ff             	lea    -0x1(%eax),%edx
80106927:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010692a:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
8010692e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106931:	89 04 24             	mov    %eax,(%esp)
80106934:	e8 73 ad ff ff       	call   801016ac <iupdate>
  iunlockput(ip);
80106939:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010693c:	89 04 24             	mov    %eax,(%esp)
8010693f:	e8 a8 b1 ff ff       	call   80101aec <iunlockput>

  commit_trans();
80106944:	e8 28 d1 ff ff       	call   80103a71 <commit_trans>

  return 0;
80106949:	b8 00 00 00 00       	mov    $0x0,%eax
8010694e:	eb 16                	jmp    80106966 <unlink+0x1b0>
  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    goto bad;
80106950:	90                   	nop
  commit_trans();

  return 0;

bad:
  iunlockput(dp);
80106951:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106954:	89 04 24             	mov    %eax,(%esp)
80106957:	e8 90 b1 ff ff       	call   80101aec <iunlockput>
  commit_trans();
8010695c:	e8 10 d1 ff ff       	call   80103a71 <commit_trans>
  return -1;
80106961:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80106966:	c9                   	leave  
80106967:	c3                   	ret    

80106968 <sys_unlink>:


//PAGEBREAK!
int
sys_unlink(void)
{
80106968:	55                   	push   %ebp
80106969:	89 e5                	mov    %esp,%ebp
8010696b:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
8010696e:	8d 45 cc             	lea    -0x34(%ebp),%eax
80106971:	89 44 24 04          	mov    %eax,0x4(%esp)
80106975:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010697c:	e8 83 f8 ff ff       	call   80106204 <argstr>
80106981:	85 c0                	test   %eax,%eax
80106983:	79 0a                	jns    8010698f <sys_unlink+0x27>
    return -1;
80106985:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010698a:	e9 aa 01 00 00       	jmp    80106b39 <sys_unlink+0x1d1>
  if((dp = nameiparent(path, name)) == 0)
8010698f:	8b 45 cc             	mov    -0x34(%ebp),%eax
80106992:	8d 55 d2             	lea    -0x2e(%ebp),%edx
80106995:	89 54 24 04          	mov    %edx,0x4(%esp)
80106999:	89 04 24             	mov    %eax,(%esp)
8010699c:	e8 8b ba ff ff       	call   8010242c <nameiparent>
801069a1:	89 45 f4             	mov    %eax,-0xc(%ebp)
801069a4:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801069a8:	75 0a                	jne    801069b4 <sys_unlink+0x4c>
    return -1;
801069aa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801069af:	e9 85 01 00 00       	jmp    80106b39 <sys_unlink+0x1d1>

  begin_trans();
801069b4:	e8 66 d0 ff ff       	call   80103a1f <begin_trans>

  ilock(dp);
801069b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069bc:	89 04 24             	mov    %eax,(%esp)
801069bf:	e8 a4 ae ff ff       	call   80101868 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
801069c4:	c7 44 24 04 64 9c 10 	movl   $0x80109c64,0x4(%esp)
801069cb:	80 
801069cc:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801069cf:	89 04 24             	mov    %eax,(%esp)
801069d2:	e8 88 b6 ff ff       	call   8010205f <namecmp>
801069d7:	85 c0                	test   %eax,%eax
801069d9:	0f 84 45 01 00 00    	je     80106b24 <sys_unlink+0x1bc>
801069df:	c7 44 24 04 66 9c 10 	movl   $0x80109c66,0x4(%esp)
801069e6:	80 
801069e7:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801069ea:	89 04 24             	mov    %eax,(%esp)
801069ed:	e8 6d b6 ff ff       	call   8010205f <namecmp>
801069f2:	85 c0                	test   %eax,%eax
801069f4:	0f 84 2a 01 00 00    	je     80106b24 <sys_unlink+0x1bc>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
801069fa:	8d 45 c8             	lea    -0x38(%ebp),%eax
801069fd:	89 44 24 08          	mov    %eax,0x8(%esp)
80106a01:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80106a04:	89 44 24 04          	mov    %eax,0x4(%esp)
80106a08:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a0b:	89 04 24             	mov    %eax,(%esp)
80106a0e:	e8 6e b6 ff ff       	call   80102081 <dirlookup>
80106a13:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106a16:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106a1a:	0f 84 03 01 00 00    	je     80106b23 <sys_unlink+0x1bb>
    goto bad;
  ilock(ip);
80106a20:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106a23:	89 04 24             	mov    %eax,(%esp)
80106a26:	e8 3d ae ff ff       	call   80101868 <ilock>

  if(ip->nlink < 1)
80106a2b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106a2e:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106a32:	66 85 c0             	test   %ax,%ax
80106a35:	7f 0c                	jg     80106a43 <sys_unlink+0xdb>
    panic("unlink: nlink < 1");
80106a37:	c7 04 24 69 9c 10 80 	movl   $0x80109c69,(%esp)
80106a3e:	e8 fa 9a ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80106a43:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106a46:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106a4a:	66 83 f8 01          	cmp    $0x1,%ax
80106a4e:	75 1f                	jne    80106a6f <sys_unlink+0x107>
80106a50:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106a53:	89 04 24             	mov    %eax,(%esp)
80106a56:	e8 ed fc ff ff       	call   80106748 <isdirempty>
80106a5b:	85 c0                	test   %eax,%eax
80106a5d:	75 10                	jne    80106a6f <sys_unlink+0x107>
    iunlockput(ip);
80106a5f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106a62:	89 04 24             	mov    %eax,(%esp)
80106a65:	e8 82 b0 ff ff       	call   80101aec <iunlockput>
    goto bad;
80106a6a:	e9 b5 00 00 00       	jmp    80106b24 <sys_unlink+0x1bc>
  }

  memset(&de, 0, sizeof(de));
80106a6f:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80106a76:	00 
80106a77:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106a7e:	00 
80106a7f:	8d 45 e0             	lea    -0x20(%ebp),%eax
80106a82:	89 04 24             	mov    %eax,(%esp)
80106a85:	e8 90 f3 ff ff       	call   80105e1a <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80106a8a:	8b 45 c8             	mov    -0x38(%ebp),%eax
80106a8d:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80106a94:	00 
80106a95:	89 44 24 08          	mov    %eax,0x8(%esp)
80106a99:	8d 45 e0             	lea    -0x20(%ebp),%eax
80106a9c:	89 44 24 04          	mov    %eax,0x4(%esp)
80106aa0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106aa3:	89 04 24             	mov    %eax,(%esp)
80106aa6:	e8 1e b4 ff ff       	call   80101ec9 <writei>
80106aab:	83 f8 10             	cmp    $0x10,%eax
80106aae:	74 0c                	je     80106abc <sys_unlink+0x154>
    panic("unlink: writei");
80106ab0:	c7 04 24 7b 9c 10 80 	movl   $0x80109c7b,(%esp)
80106ab7:	e8 81 9a ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR){
80106abc:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106abf:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106ac3:	66 83 f8 01          	cmp    $0x1,%ax
80106ac7:	75 1c                	jne    80106ae5 <sys_unlink+0x17d>
    dp->nlink--;
80106ac9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106acc:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106ad0:	8d 50 ff             	lea    -0x1(%eax),%edx
80106ad3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ad6:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80106ada:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106add:	89 04 24             	mov    %eax,(%esp)
80106ae0:	e8 c7 ab ff ff       	call   801016ac <iupdate>
  }
  iunlockput(dp);
80106ae5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ae8:	89 04 24             	mov    %eax,(%esp)
80106aeb:	e8 fc af ff ff       	call   80101aec <iunlockput>

  ip->nlink--;
80106af0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106af3:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106af7:	8d 50 ff             	lea    -0x1(%eax),%edx
80106afa:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106afd:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80106b01:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b04:	89 04 24             	mov    %eax,(%esp)
80106b07:	e8 a0 ab ff ff       	call   801016ac <iupdate>
  iunlockput(ip);
80106b0c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b0f:	89 04 24             	mov    %eax,(%esp)
80106b12:	e8 d5 af ff ff       	call   80101aec <iunlockput>

  commit_trans();
80106b17:	e8 55 cf ff ff       	call   80103a71 <commit_trans>

  return 0;
80106b1c:	b8 00 00 00 00       	mov    $0x0,%eax
80106b21:	eb 16                	jmp    80106b39 <sys_unlink+0x1d1>
  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    goto bad;
80106b23:	90                   	nop
  commit_trans();

  return 0;

bad:
  iunlockput(dp);
80106b24:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b27:	89 04 24             	mov    %eax,(%esp)
80106b2a:	e8 bd af ff ff       	call   80101aec <iunlockput>
  commit_trans();
80106b2f:	e8 3d cf ff ff       	call   80103a71 <commit_trans>
  return -1;
80106b34:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80106b39:	c9                   	leave  
80106b3a:	c3                   	ret    

80106b3b <create>:

static struct inode*
create(char *path, short type, short major, short minor)
{
80106b3b:	55                   	push   %ebp
80106b3c:	89 e5                	mov    %esp,%ebp
80106b3e:	83 ec 48             	sub    $0x48,%esp
80106b41:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80106b44:	8b 55 10             	mov    0x10(%ebp),%edx
80106b47:	8b 45 14             	mov    0x14(%ebp),%eax
80106b4a:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
80106b4e:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
80106b52:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];
  if((dp = nameiparent(path, name)) == 0)
80106b56:	8d 45 de             	lea    -0x22(%ebp),%eax
80106b59:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b5d:	8b 45 08             	mov    0x8(%ebp),%eax
80106b60:	89 04 24             	mov    %eax,(%esp)
80106b63:	e8 c4 b8 ff ff       	call   8010242c <nameiparent>
80106b68:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106b6b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106b6f:	75 0a                	jne    80106b7b <create+0x40>
    return 0;
80106b71:	b8 00 00 00 00       	mov    $0x0,%eax
80106b76:	e9 7e 01 00 00       	jmp    80106cf9 <create+0x1be>
  ilock(dp);
80106b7b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b7e:	89 04 24             	mov    %eax,(%esp)
80106b81:	e8 e2 ac ff ff       	call   80101868 <ilock>
  if((ip = dirlookup(dp, name, &off)) != 0){
80106b86:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106b89:	89 44 24 08          	mov    %eax,0x8(%esp)
80106b8d:	8d 45 de             	lea    -0x22(%ebp),%eax
80106b90:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b94:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b97:	89 04 24             	mov    %eax,(%esp)
80106b9a:	e8 e2 b4 ff ff       	call   80102081 <dirlookup>
80106b9f:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106ba2:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106ba6:	74 47                	je     80106bef <create+0xb4>
    iunlockput(dp);
80106ba8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106bab:	89 04 24             	mov    %eax,(%esp)
80106bae:	e8 39 af ff ff       	call   80101aec <iunlockput>
    ilock(ip);
80106bb3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106bb6:	89 04 24             	mov    %eax,(%esp)
80106bb9:	e8 aa ac ff ff       	call   80101868 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
80106bbe:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
80106bc3:	75 15                	jne    80106bda <create+0x9f>
80106bc5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106bc8:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106bcc:	66 83 f8 02          	cmp    $0x2,%ax
80106bd0:	75 08                	jne    80106bda <create+0x9f>
      return ip;
80106bd2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106bd5:	e9 1f 01 00 00       	jmp    80106cf9 <create+0x1be>
    iunlockput(ip);
80106bda:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106bdd:	89 04 24             	mov    %eax,(%esp)
80106be0:	e8 07 af ff ff       	call   80101aec <iunlockput>
    return 0;
80106be5:	b8 00 00 00 00       	mov    $0x0,%eax
80106bea:	e9 0a 01 00 00       	jmp    80106cf9 <create+0x1be>
  }
  if((ip = ialloc(dp->dev, type)) == 0)
80106bef:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
80106bf3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106bf6:	8b 00                	mov    (%eax),%eax
80106bf8:	89 54 24 04          	mov    %edx,0x4(%esp)
80106bfc:	89 04 24             	mov    %eax,(%esp)
80106bff:	e8 cb a9 ff ff       	call   801015cf <ialloc>
80106c04:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106c07:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106c0b:	75 0c                	jne    80106c19 <create+0xde>
    panic("create: ialloc");
80106c0d:	c7 04 24 8a 9c 10 80 	movl   $0x80109c8a,(%esp)
80106c14:	e8 24 99 ff ff       	call   8010053d <panic>
  ilock(ip);
80106c19:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c1c:	89 04 24             	mov    %eax,(%esp)
80106c1f:	e8 44 ac ff ff       	call   80101868 <ilock>
  ip->major = major;
80106c24:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c27:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
80106c2b:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
80106c2f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c32:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
80106c36:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
80106c3a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c3d:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
80106c43:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c46:	89 04 24             	mov    %eax,(%esp)
80106c49:	e8 5e aa ff ff       	call   801016ac <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
80106c4e:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
80106c53:	75 6a                	jne    80106cbf <create+0x184>
    dp->nlink++;  // for ".."
80106c55:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c58:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106c5c:	8d 50 01             	lea    0x1(%eax),%edx
80106c5f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c62:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80106c66:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c69:	89 04 24             	mov    %eax,(%esp)
80106c6c:	e8 3b aa ff ff       	call   801016ac <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80106c71:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c74:	8b 40 04             	mov    0x4(%eax),%eax
80106c77:	89 44 24 08          	mov    %eax,0x8(%esp)
80106c7b:	c7 44 24 04 64 9c 10 	movl   $0x80109c64,0x4(%esp)
80106c82:	80 
80106c83:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c86:	89 04 24             	mov    %eax,(%esp)
80106c89:	e8 bb b4 ff ff       	call   80102149 <dirlink>
80106c8e:	85 c0                	test   %eax,%eax
80106c90:	78 21                	js     80106cb3 <create+0x178>
80106c92:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c95:	8b 40 04             	mov    0x4(%eax),%eax
80106c98:	89 44 24 08          	mov    %eax,0x8(%esp)
80106c9c:	c7 44 24 04 66 9c 10 	movl   $0x80109c66,0x4(%esp)
80106ca3:	80 
80106ca4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ca7:	89 04 24             	mov    %eax,(%esp)
80106caa:	e8 9a b4 ff ff       	call   80102149 <dirlink>
80106caf:	85 c0                	test   %eax,%eax
80106cb1:	79 0c                	jns    80106cbf <create+0x184>
      panic("create dots");
80106cb3:	c7 04 24 99 9c 10 80 	movl   $0x80109c99,(%esp)
80106cba:	e8 7e 98 ff ff       	call   8010053d <panic>
  }
  if(dirlink(dp, name, ip->inum) < 0)
80106cbf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106cc2:	8b 40 04             	mov    0x4(%eax),%eax
80106cc5:	89 44 24 08          	mov    %eax,0x8(%esp)
80106cc9:	8d 45 de             	lea    -0x22(%ebp),%eax
80106ccc:	89 44 24 04          	mov    %eax,0x4(%esp)
80106cd0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106cd3:	89 04 24             	mov    %eax,(%esp)
80106cd6:	e8 6e b4 ff ff       	call   80102149 <dirlink>
80106cdb:	85 c0                	test   %eax,%eax
80106cdd:	79 0c                	jns    80106ceb <create+0x1b0>
    panic("create: dirlink");
80106cdf:	c7 04 24 a5 9c 10 80 	movl   $0x80109ca5,(%esp)
80106ce6:	e8 52 98 ff ff       	call   8010053d <panic>
  iunlockput(dp);
80106ceb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106cee:	89 04 24             	mov    %eax,(%esp)
80106cf1:	e8 f6 ad ff ff       	call   80101aec <iunlockput>

  return ip;
80106cf6:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80106cf9:	c9                   	leave  
80106cfa:	c3                   	ret    

80106cfb <fileopen>:

struct file*
fileopen(char *path, int omode)
{
80106cfb:	55                   	push   %ebp
80106cfc:	89 e5                	mov    %esp,%ebp
80106cfe:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  struct inode *ip;

  if(omode & O_CREATE){
80106d01:	8b 45 0c             	mov    0xc(%ebp),%eax
80106d04:	25 00 02 00 00       	and    $0x200,%eax
80106d09:	85 c0                	test   %eax,%eax
80106d0b:	74 40                	je     80106d4d <fileopen+0x52>
    begin_trans();
80106d0d:	e8 0d cd ff ff       	call   80103a1f <begin_trans>
    ip = create(path, T_FILE, 0, 0);
80106d12:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106d19:	00 
80106d1a:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106d21:	00 
80106d22:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80106d29:	00 
80106d2a:	8b 45 08             	mov    0x8(%ebp),%eax
80106d2d:	89 04 24             	mov    %eax,(%esp)
80106d30:	e8 06 fe ff ff       	call   80106b3b <create>
80106d35:	89 45 f4             	mov    %eax,-0xc(%ebp)
    commit_trans();
80106d38:	e8 34 cd ff ff       	call   80103a71 <commit_trans>
    if(ip == 0)
80106d3d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106d41:	75 5b                	jne    80106d9e <fileopen+0xa3>
      return 0;
80106d43:	b8 00 00 00 00       	mov    $0x0,%eax
80106d48:	e9 f9 00 00 00       	jmp    80106e46 <fileopen+0x14b>
  } else {
    if((ip = namei(path)) == 0)
80106d4d:	8b 45 08             	mov    0x8(%ebp),%eax
80106d50:	89 04 24             	mov    %eax,(%esp)
80106d53:	e8 b2 b6 ff ff       	call   8010240a <namei>
80106d58:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106d5b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106d5f:	75 0a                	jne    80106d6b <fileopen+0x70>
      return 0;
80106d61:	b8 00 00 00 00       	mov    $0x0,%eax
80106d66:	e9 db 00 00 00       	jmp    80106e46 <fileopen+0x14b>
    ilock(ip);
80106d6b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d6e:	89 04 24             	mov    %eax,(%esp)
80106d71:	e8 f2 aa ff ff       	call   80101868 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80106d76:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d79:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106d7d:	66 83 f8 01          	cmp    $0x1,%ax
80106d81:	75 1b                	jne    80106d9e <fileopen+0xa3>
80106d83:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80106d87:	74 15                	je     80106d9e <fileopen+0xa3>
      iunlockput(ip);
80106d89:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d8c:	89 04 24             	mov    %eax,(%esp)
80106d8f:	e8 58 ad ff ff       	call   80101aec <iunlockput>
      return 0;
80106d94:	b8 00 00 00 00       	mov    $0x0,%eax
80106d99:	e9 a8 00 00 00       	jmp    80106e46 <fileopen+0x14b>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80106d9e:	e8 79 a1 ff ff       	call   80100f1c <filealloc>
80106da3:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106da6:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106daa:	74 14                	je     80106dc0 <fileopen+0xc5>
80106dac:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106daf:	89 04 24             	mov    %eax,(%esp)
80106db2:	e8 ca f5 ff ff       	call   80106381 <fdalloc>
80106db7:	89 45 ec             	mov    %eax,-0x14(%ebp)
80106dba:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80106dbe:	79 23                	jns    80106de3 <fileopen+0xe8>
    if(f)
80106dc0:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106dc4:	74 0b                	je     80106dd1 <fileopen+0xd6>
      fileclose(f);
80106dc6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106dc9:	89 04 24             	mov    %eax,(%esp)
80106dcc:	e8 f3 a1 ff ff       	call   80100fc4 <fileclose>
    iunlockput(ip);
80106dd1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106dd4:	89 04 24             	mov    %eax,(%esp)
80106dd7:	e8 10 ad ff ff       	call   80101aec <iunlockput>
    return 0;
80106ddc:	b8 00 00 00 00       	mov    $0x0,%eax
80106de1:	eb 63                	jmp    80106e46 <fileopen+0x14b>
  }
  iunlock(ip);
80106de3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106de6:	89 04 24             	mov    %eax,(%esp)
80106de9:	e8 c8 ab ff ff       	call   801019b6 <iunlock>

  f->type = FD_INODE;
80106dee:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106df1:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80106df7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106dfa:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106dfd:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
80106e00:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106e03:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80106e0a:	8b 45 0c             	mov    0xc(%ebp),%eax
80106e0d:	83 e0 01             	and    $0x1,%eax
80106e10:	85 c0                	test   %eax,%eax
80106e12:	0f 94 c2             	sete   %dl
80106e15:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106e18:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80106e1b:	8b 45 0c             	mov    0xc(%ebp),%eax
80106e1e:	83 e0 01             	and    $0x1,%eax
80106e21:	84 c0                	test   %al,%al
80106e23:	75 0a                	jne    80106e2f <fileopen+0x134>
80106e25:	8b 45 0c             	mov    0xc(%ebp),%eax
80106e28:	83 e0 02             	and    $0x2,%eax
80106e2b:	85 c0                	test   %eax,%eax
80106e2d:	74 07                	je     80106e36 <fileopen+0x13b>
80106e2f:	b8 01 00 00 00       	mov    $0x1,%eax
80106e34:	eb 05                	jmp    80106e3b <fileopen+0x140>
80106e36:	b8 00 00 00 00       	mov    $0x0,%eax
80106e3b:	89 c2                	mov    %eax,%edx
80106e3d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106e40:	88 50 09             	mov    %dl,0x9(%eax)
  return f;
80106e43:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80106e46:	c9                   	leave  
80106e47:	c3                   	ret    

80106e48 <sys_open>:

int
sys_open(void)
{
80106e48:	55                   	push   %ebp
80106e49:	89 e5                	mov    %esp,%ebp
80106e4b:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80106e4e:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106e51:	89 44 24 04          	mov    %eax,0x4(%esp)
80106e55:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106e5c:	e8 a3 f3 ff ff       	call   80106204 <argstr>
80106e61:	85 c0                	test   %eax,%eax
80106e63:	78 17                	js     80106e7c <sys_open+0x34>
80106e65:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106e68:	89 44 24 04          	mov    %eax,0x4(%esp)
80106e6c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106e73:	e8 f2 f2 ff ff       	call   8010616a <argint>
80106e78:	85 c0                	test   %eax,%eax
80106e7a:	79 0a                	jns    80106e86 <sys_open+0x3e>
    return -1;
80106e7c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106e81:	e9 46 01 00 00       	jmp    80106fcc <sys_open+0x184>
  if(omode & O_CREATE){
80106e86:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106e89:	25 00 02 00 00       	and    $0x200,%eax
80106e8e:	85 c0                	test   %eax,%eax
80106e90:	74 40                	je     80106ed2 <sys_open+0x8a>
    begin_trans();
80106e92:	e8 88 cb ff ff       	call   80103a1f <begin_trans>
    ip = create(path, T_FILE, 0, 0);
80106e97:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106e9a:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106ea1:	00 
80106ea2:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106ea9:	00 
80106eaa:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80106eb1:	00 
80106eb2:	89 04 24             	mov    %eax,(%esp)
80106eb5:	e8 81 fc ff ff       	call   80106b3b <create>
80106eba:	89 45 f4             	mov    %eax,-0xc(%ebp)
    commit_trans();
80106ebd:	e8 af cb ff ff       	call   80103a71 <commit_trans>
    if(ip == 0)
80106ec2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106ec6:	75 5c                	jne    80106f24 <sys_open+0xdc>
      return -1;
80106ec8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106ecd:	e9 fa 00 00 00       	jmp    80106fcc <sys_open+0x184>
  } else {
    if((ip = namei(path)) == 0)
80106ed2:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106ed5:	89 04 24             	mov    %eax,(%esp)
80106ed8:	e8 2d b5 ff ff       	call   8010240a <namei>
80106edd:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106ee0:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106ee4:	75 0a                	jne    80106ef0 <sys_open+0xa8>
      return -1;
80106ee6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106eeb:	e9 dc 00 00 00       	jmp    80106fcc <sys_open+0x184>
    ilock(ip);
80106ef0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ef3:	89 04 24             	mov    %eax,(%esp)
80106ef6:	e8 6d a9 ff ff       	call   80101868 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80106efb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106efe:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106f02:	66 83 f8 01          	cmp    $0x1,%ax
80106f06:	75 1c                	jne    80106f24 <sys_open+0xdc>
80106f08:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106f0b:	85 c0                	test   %eax,%eax
80106f0d:	74 15                	je     80106f24 <sys_open+0xdc>
      iunlockput(ip);
80106f0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f12:	89 04 24             	mov    %eax,(%esp)
80106f15:	e8 d2 ab ff ff       	call   80101aec <iunlockput>
      return -1;
80106f1a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106f1f:	e9 a8 00 00 00       	jmp    80106fcc <sys_open+0x184>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80106f24:	e8 f3 9f ff ff       	call   80100f1c <filealloc>
80106f29:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106f2c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106f30:	74 14                	je     80106f46 <sys_open+0xfe>
80106f32:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106f35:	89 04 24             	mov    %eax,(%esp)
80106f38:	e8 44 f4 ff ff       	call   80106381 <fdalloc>
80106f3d:	89 45 ec             	mov    %eax,-0x14(%ebp)
80106f40:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80106f44:	79 23                	jns    80106f69 <sys_open+0x121>
    if(f)
80106f46:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106f4a:	74 0b                	je     80106f57 <sys_open+0x10f>
      fileclose(f);
80106f4c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106f4f:	89 04 24             	mov    %eax,(%esp)
80106f52:	e8 6d a0 ff ff       	call   80100fc4 <fileclose>
    iunlockput(ip);
80106f57:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f5a:	89 04 24             	mov    %eax,(%esp)
80106f5d:	e8 8a ab ff ff       	call   80101aec <iunlockput>
    return -1;
80106f62:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106f67:	eb 63                	jmp    80106fcc <sys_open+0x184>
  }
  iunlock(ip);
80106f69:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f6c:	89 04 24             	mov    %eax,(%esp)
80106f6f:	e8 42 aa ff ff       	call   801019b6 <iunlock>

  f->type = FD_INODE;
80106f74:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106f77:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80106f7d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106f80:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106f83:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
80106f86:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106f89:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80106f90:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106f93:	83 e0 01             	and    $0x1,%eax
80106f96:	85 c0                	test   %eax,%eax
80106f98:	0f 94 c2             	sete   %dl
80106f9b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106f9e:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80106fa1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106fa4:	83 e0 01             	and    $0x1,%eax
80106fa7:	84 c0                	test   %al,%al
80106fa9:	75 0a                	jne    80106fb5 <sys_open+0x16d>
80106fab:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106fae:	83 e0 02             	and    $0x2,%eax
80106fb1:	85 c0                	test   %eax,%eax
80106fb3:	74 07                	je     80106fbc <sys_open+0x174>
80106fb5:	b8 01 00 00 00       	mov    $0x1,%eax
80106fba:	eb 05                	jmp    80106fc1 <sys_open+0x179>
80106fbc:	b8 00 00 00 00       	mov    $0x0,%eax
80106fc1:	89 c2                	mov    %eax,%edx
80106fc3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106fc6:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
80106fc9:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
80106fcc:	c9                   	leave  
80106fcd:	c3                   	ret    

80106fce <sys_mkdir>:

int
sys_mkdir(void)
{
80106fce:	55                   	push   %ebp
80106fcf:	89 e5                	mov    %esp,%ebp
80106fd1:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_trans();
80106fd4:	e8 46 ca ff ff       	call   80103a1f <begin_trans>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80106fd9:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106fdc:	89 44 24 04          	mov    %eax,0x4(%esp)
80106fe0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106fe7:	e8 18 f2 ff ff       	call   80106204 <argstr>
80106fec:	85 c0                	test   %eax,%eax
80106fee:	78 2c                	js     8010701c <sys_mkdir+0x4e>
80106ff0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ff3:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106ffa:	00 
80106ffb:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80107002:	00 
80107003:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010700a:	00 
8010700b:	89 04 24             	mov    %eax,(%esp)
8010700e:	e8 28 fb ff ff       	call   80106b3b <create>
80107013:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107016:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010701a:	75 0c                	jne    80107028 <sys_mkdir+0x5a>
    commit_trans();
8010701c:	e8 50 ca ff ff       	call   80103a71 <commit_trans>
    return -1;
80107021:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107026:	eb 15                	jmp    8010703d <sys_mkdir+0x6f>
  }
  iunlockput(ip);
80107028:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010702b:	89 04 24             	mov    %eax,(%esp)
8010702e:	e8 b9 aa ff ff       	call   80101aec <iunlockput>
  commit_trans();
80107033:	e8 39 ca ff ff       	call   80103a71 <commit_trans>
  return 0;
80107038:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010703d:	c9                   	leave  
8010703e:	c3                   	ret    

8010703f <sys_mknod>:

int
sys_mknod(void)
{
8010703f:	55                   	push   %ebp
80107040:	89 e5                	mov    %esp,%ebp
80107042:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
80107045:	e8 d5 c9 ff ff       	call   80103a1f <begin_trans>
  if((len=argstr(0, &path)) < 0 ||
8010704a:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010704d:	89 44 24 04          	mov    %eax,0x4(%esp)
80107051:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107058:	e8 a7 f1 ff ff       	call   80106204 <argstr>
8010705d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107060:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80107064:	78 5e                	js     801070c4 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
80107066:	8d 45 e8             	lea    -0x18(%ebp),%eax
80107069:	89 44 24 04          	mov    %eax,0x4(%esp)
8010706d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80107074:	e8 f1 f0 ff ff       	call   8010616a <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
80107079:	85 c0                	test   %eax,%eax
8010707b:	78 47                	js     801070c4 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
8010707d:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80107080:	89 44 24 04          	mov    %eax,0x4(%esp)
80107084:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
8010708b:	e8 da f0 ff ff       	call   8010616a <argint>
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
80107090:	85 c0                	test   %eax,%eax
80107092:	78 30                	js     801070c4 <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
80107094:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80107097:	0f bf c8             	movswl %ax,%ecx
8010709a:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010709d:	0f bf d0             	movswl %ax,%edx
801070a0:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
801070a3:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
801070a7:	89 54 24 08          	mov    %edx,0x8(%esp)
801070ab:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
801070b2:	00 
801070b3:	89 04 24             	mov    %eax,(%esp)
801070b6:	e8 80 fa ff ff       	call   80106b3b <create>
801070bb:	89 45 f0             	mov    %eax,-0x10(%ebp)
801070be:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801070c2:	75 0c                	jne    801070d0 <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    commit_trans();
801070c4:	e8 a8 c9 ff ff       	call   80103a71 <commit_trans>
    return -1;
801070c9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801070ce:	eb 15                	jmp    801070e5 <sys_mknod+0xa6>
  }
  iunlockput(ip);
801070d0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801070d3:	89 04 24             	mov    %eax,(%esp)
801070d6:	e8 11 aa ff ff       	call   80101aec <iunlockput>
  commit_trans();
801070db:	e8 91 c9 ff ff       	call   80103a71 <commit_trans>
  return 0;
801070e0:	b8 00 00 00 00       	mov    $0x0,%eax
}
801070e5:	c9                   	leave  
801070e6:	c3                   	ret    

801070e7 <sys_chdir>:

int
sys_chdir(void)
{
801070e7:	55                   	push   %ebp
801070e8:	89 e5                	mov    %esp,%ebp
801070ea:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0)
801070ed:	8d 45 f0             	lea    -0x10(%ebp),%eax
801070f0:	89 44 24 04          	mov    %eax,0x4(%esp)
801070f4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801070fb:	e8 04 f1 ff ff       	call   80106204 <argstr>
80107100:	85 c0                	test   %eax,%eax
80107102:	78 14                	js     80107118 <sys_chdir+0x31>
80107104:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107107:	89 04 24             	mov    %eax,(%esp)
8010710a:	e8 fb b2 ff ff       	call   8010240a <namei>
8010710f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107112:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80107116:	75 07                	jne    8010711f <sys_chdir+0x38>
    return -1;
80107118:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010711d:	eb 57                	jmp    80107176 <sys_chdir+0x8f>
  ilock(ip);
8010711f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107122:	89 04 24             	mov    %eax,(%esp)
80107125:	e8 3e a7 ff ff       	call   80101868 <ilock>
  if(ip->type != T_DIR){
8010712a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010712d:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80107131:	66 83 f8 01          	cmp    $0x1,%ax
80107135:	74 12                	je     80107149 <sys_chdir+0x62>
    iunlockput(ip);
80107137:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010713a:	89 04 24             	mov    %eax,(%esp)
8010713d:	e8 aa a9 ff ff       	call   80101aec <iunlockput>
    return -1;
80107142:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107147:	eb 2d                	jmp    80107176 <sys_chdir+0x8f>
  }
  iunlock(ip);
80107149:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010714c:	89 04 24             	mov    %eax,(%esp)
8010714f:	e8 62 a8 ff ff       	call   801019b6 <iunlock>
  iput(proc->cwd);
80107154:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010715a:	8b 40 68             	mov    0x68(%eax),%eax
8010715d:	89 04 24             	mov    %eax,(%esp)
80107160:	e8 b6 a8 ff ff       	call   80101a1b <iput>
  proc->cwd = ip;
80107165:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010716b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010716e:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
80107171:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107176:	c9                   	leave  
80107177:	c3                   	ret    

80107178 <sys_exec>:

int
sys_exec(void)
{
80107178:	55                   	push   %ebp
80107179:	89 e5                	mov    %esp,%ebp
8010717b:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80107181:	8d 45 f0             	lea    -0x10(%ebp),%eax
80107184:	89 44 24 04          	mov    %eax,0x4(%esp)
80107188:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010718f:	e8 70 f0 ff ff       	call   80106204 <argstr>
80107194:	85 c0                	test   %eax,%eax
80107196:	78 1a                	js     801071b2 <sys_exec+0x3a>
80107198:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
8010719e:	89 44 24 04          	mov    %eax,0x4(%esp)
801071a2:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801071a9:	e8 bc ef ff ff       	call   8010616a <argint>
801071ae:	85 c0                	test   %eax,%eax
801071b0:	79 0a                	jns    801071bc <sys_exec+0x44>
    return -1;
801071b2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801071b7:	e9 e2 00 00 00       	jmp    8010729e <sys_exec+0x126>
  }
  memset(argv, 0, sizeof(argv));
801071bc:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
801071c3:	00 
801071c4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801071cb:	00 
801071cc:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
801071d2:	89 04 24             	mov    %eax,(%esp)
801071d5:	e8 40 ec ff ff       	call   80105e1a <memset>
  for(i=0;; i++){
801071da:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
801071e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801071e4:	83 f8 1f             	cmp    $0x1f,%eax
801071e7:	76 0a                	jbe    801071f3 <sys_exec+0x7b>
      return -1;
801071e9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801071ee:	e9 ab 00 00 00       	jmp    8010729e <sys_exec+0x126>
    if(fetchint(proc, uargv+4*i, (int*)&uarg) < 0)
801071f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801071f6:	c1 e0 02             	shl    $0x2,%eax
801071f9:	89 c2                	mov    %eax,%edx
801071fb:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80107201:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
80107204:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010720a:	8d 95 68 ff ff ff    	lea    -0x98(%ebp),%edx
80107210:	89 54 24 08          	mov    %edx,0x8(%esp)
80107214:	89 4c 24 04          	mov    %ecx,0x4(%esp)
80107218:	89 04 24             	mov    %eax,(%esp)
8010721b:	e8 b8 ee ff ff       	call   801060d8 <fetchint>
80107220:	85 c0                	test   %eax,%eax
80107222:	79 07                	jns    8010722b <sys_exec+0xb3>
      return -1;
80107224:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107229:	eb 73                	jmp    8010729e <sys_exec+0x126>
    if(uarg == 0){
8010722b:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80107231:	85 c0                	test   %eax,%eax
80107233:	75 26                	jne    8010725b <sys_exec+0xe3>
      argv[i] = 0;
80107235:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107238:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
8010723f:	00 00 00 00 
      break;
80107243:	90                   	nop
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
80107244:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107247:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
8010724d:	89 54 24 04          	mov    %edx,0x4(%esp)
80107251:	89 04 24             	mov    %eax,(%esp)
80107254:	e8 a3 98 ff ff       	call   80100afc <exec>
80107259:	eb 43                	jmp    8010729e <sys_exec+0x126>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
8010725b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010725e:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80107265:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
8010726b:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
8010726e:	8b 95 68 ff ff ff    	mov    -0x98(%ebp),%edx
80107274:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010727a:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010727e:	89 54 24 04          	mov    %edx,0x4(%esp)
80107282:	89 04 24             	mov    %eax,(%esp)
80107285:	e8 82 ee ff ff       	call   8010610c <fetchstr>
8010728a:	85 c0                	test   %eax,%eax
8010728c:	79 07                	jns    80107295 <sys_exec+0x11d>
      return -1;
8010728e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107293:	eb 09                	jmp    8010729e <sys_exec+0x126>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
80107295:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
80107299:	e9 43 ff ff ff       	jmp    801071e1 <sys_exec+0x69>
  return exec(path, argv);
}
8010729e:	c9                   	leave  
8010729f:	c3                   	ret    

801072a0 <sys_pipe>:

int
sys_pipe(void)
{
801072a0:	55                   	push   %ebp
801072a1:	89 e5                	mov    %esp,%ebp
801072a3:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
801072a6:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
801072ad:	00 
801072ae:	8d 45 ec             	lea    -0x14(%ebp),%eax
801072b1:	89 44 24 04          	mov    %eax,0x4(%esp)
801072b5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801072bc:	e8 e1 ee ff ff       	call   801061a2 <argptr>
801072c1:	85 c0                	test   %eax,%eax
801072c3:	79 0a                	jns    801072cf <sys_pipe+0x2f>
    return -1;
801072c5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801072ca:	e9 9b 00 00 00       	jmp    8010736a <sys_pipe+0xca>
  if(pipealloc(&rf, &wf) < 0)
801072cf:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801072d2:	89 44 24 04          	mov    %eax,0x4(%esp)
801072d6:	8d 45 e8             	lea    -0x18(%ebp),%eax
801072d9:	89 04 24             	mov    %eax,(%esp)
801072dc:	e8 57 d1 ff ff       	call   80104438 <pipealloc>
801072e1:	85 c0                	test   %eax,%eax
801072e3:	79 07                	jns    801072ec <sys_pipe+0x4c>
    return -1;
801072e5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801072ea:	eb 7e                	jmp    8010736a <sys_pipe+0xca>
  fd0 = -1;
801072ec:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
801072f3:	8b 45 e8             	mov    -0x18(%ebp),%eax
801072f6:	89 04 24             	mov    %eax,(%esp)
801072f9:	e8 83 f0 ff ff       	call   80106381 <fdalloc>
801072fe:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107301:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80107305:	78 14                	js     8010731b <sys_pipe+0x7b>
80107307:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010730a:	89 04 24             	mov    %eax,(%esp)
8010730d:	e8 6f f0 ff ff       	call   80106381 <fdalloc>
80107312:	89 45 f0             	mov    %eax,-0x10(%ebp)
80107315:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107319:	79 37                	jns    80107352 <sys_pipe+0xb2>
    if(fd0 >= 0)
8010731b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010731f:	78 14                	js     80107335 <sys_pipe+0x95>
      proc->ofile[fd0] = 0;
80107321:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107327:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010732a:	83 c2 08             	add    $0x8,%edx
8010732d:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80107334:	00 
    fileclose(rf);
80107335:	8b 45 e8             	mov    -0x18(%ebp),%eax
80107338:	89 04 24             	mov    %eax,(%esp)
8010733b:	e8 84 9c ff ff       	call   80100fc4 <fileclose>
    fileclose(wf);
80107340:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80107343:	89 04 24             	mov    %eax,(%esp)
80107346:	e8 79 9c ff ff       	call   80100fc4 <fileclose>
    return -1;
8010734b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107350:	eb 18                	jmp    8010736a <sys_pipe+0xca>
  }
  fd[0] = fd0;
80107352:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107355:	8b 55 f4             	mov    -0xc(%ebp),%edx
80107358:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
8010735a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010735d:	8d 50 04             	lea    0x4(%eax),%edx
80107360:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107363:	89 02                	mov    %eax,(%edx)
  return 0;
80107365:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010736a:	c9                   	leave  
8010736b:	c3                   	ret    

8010736c <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
8010736c:	55                   	push   %ebp
8010736d:	89 e5                	mov    %esp,%ebp
8010736f:	83 ec 08             	sub    $0x8,%esp
  return fork();
80107372:	e8 7f dd ff ff       	call   801050f6 <fork>
}
80107377:	c9                   	leave  
80107378:	c3                   	ret    

80107379 <sys_exit>:

int
sys_exit(void)
{
80107379:	55                   	push   %ebp
8010737a:	89 e5                	mov    %esp,%ebp
8010737c:	83 ec 08             	sub    $0x8,%esp
  exit();
8010737f:	e8 d5 de ff ff       	call   80105259 <exit>
  return 0;  // not reached
80107384:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107389:	c9                   	leave  
8010738a:	c3                   	ret    

8010738b <sys_wait>:

int
sys_wait(void)
{
8010738b:	55                   	push   %ebp
8010738c:	89 e5                	mov    %esp,%ebp
8010738e:	83 ec 08             	sub    $0x8,%esp
  return wait();
80107391:	e8 ff df ff ff       	call   80105395 <wait>
}
80107396:	c9                   	leave  
80107397:	c3                   	ret    

80107398 <sys_kill>:

int
sys_kill(void)
{
80107398:	55                   	push   %ebp
80107399:	89 e5                	mov    %esp,%ebp
8010739b:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
8010739e:	8d 45 f4             	lea    -0xc(%ebp),%eax
801073a1:	89 44 24 04          	mov    %eax,0x4(%esp)
801073a5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801073ac:	e8 b9 ed ff ff       	call   8010616a <argint>
801073b1:	85 c0                	test   %eax,%eax
801073b3:	79 07                	jns    801073bc <sys_kill+0x24>
    return -1;
801073b5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801073ba:	eb 0b                	jmp    801073c7 <sys_kill+0x2f>
  return kill(pid);
801073bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801073bf:	89 04 24             	mov    %eax,(%esp)
801073c2:	e8 c9 e4 ff ff       	call   80105890 <kill>
}
801073c7:	c9                   	leave  
801073c8:	c3                   	ret    

801073c9 <sys_getpid>:

int
sys_getpid(void)
{
801073c9:	55                   	push   %ebp
801073ca:	89 e5                	mov    %esp,%ebp
  return proc->pid;
801073cc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801073d2:	8b 40 10             	mov    0x10(%eax),%eax
}
801073d5:	5d                   	pop    %ebp
801073d6:	c3                   	ret    

801073d7 <sys_sbrk>:

int
sys_sbrk(void)
{
801073d7:	55                   	push   %ebp
801073d8:	89 e5                	mov    %esp,%ebp
801073da:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
801073dd:	8d 45 f0             	lea    -0x10(%ebp),%eax
801073e0:	89 44 24 04          	mov    %eax,0x4(%esp)
801073e4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801073eb:	e8 7a ed ff ff       	call   8010616a <argint>
801073f0:	85 c0                	test   %eax,%eax
801073f2:	79 07                	jns    801073fb <sys_sbrk+0x24>
    return -1;
801073f4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801073f9:	eb 24                	jmp    8010741f <sys_sbrk+0x48>
  addr = proc->sz;
801073fb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107401:	8b 00                	mov    (%eax),%eax
80107403:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
80107406:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107409:	89 04 24             	mov    %eax,(%esp)
8010740c:	e8 40 dc ff ff       	call   80105051 <growproc>
80107411:	85 c0                	test   %eax,%eax
80107413:	79 07                	jns    8010741c <sys_sbrk+0x45>
    return -1;
80107415:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010741a:	eb 03                	jmp    8010741f <sys_sbrk+0x48>
  return addr;
8010741c:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010741f:	c9                   	leave  
80107420:	c3                   	ret    

80107421 <sys_sleep>:

int
sys_sleep(void)
{
80107421:	55                   	push   %ebp
80107422:	89 e5                	mov    %esp,%ebp
80107424:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
80107427:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010742a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010742e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107435:	e8 30 ed ff ff       	call   8010616a <argint>
8010743a:	85 c0                	test   %eax,%eax
8010743c:	79 07                	jns    80107445 <sys_sleep+0x24>
    return -1;
8010743e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107443:	eb 6c                	jmp    801074b1 <sys_sleep+0x90>
  acquire(&tickslock);
80107445:	c7 04 24 80 9b 12 80 	movl   $0x80129b80,(%esp)
8010744c:	e8 42 e7 ff ff       	call   80105b93 <acquire>
  ticks0 = ticks;
80107451:	a1 c0 a3 12 80       	mov    0x8012a3c0,%eax
80107456:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
80107459:	eb 34                	jmp    8010748f <sys_sleep+0x6e>
    if(proc->killed){
8010745b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107461:	8b 40 24             	mov    0x24(%eax),%eax
80107464:	85 c0                	test   %eax,%eax
80107466:	74 13                	je     8010747b <sys_sleep+0x5a>
      release(&tickslock);
80107468:	c7 04 24 80 9b 12 80 	movl   $0x80129b80,(%esp)
8010746f:	e8 ba e7 ff ff       	call   80105c2e <release>
      return -1;
80107474:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107479:	eb 36                	jmp    801074b1 <sys_sleep+0x90>
    }
    sleep(&ticks, &tickslock);
8010747b:	c7 44 24 04 80 9b 12 	movl   $0x80129b80,0x4(%esp)
80107482:	80 
80107483:	c7 04 24 c0 a3 12 80 	movl   $0x8012a3c0,(%esp)
8010748a:	e8 64 e2 ff ff       	call   801056f3 <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
8010748f:	a1 c0 a3 12 80       	mov    0x8012a3c0,%eax
80107494:	89 c2                	mov    %eax,%edx
80107496:	2b 55 f4             	sub    -0xc(%ebp),%edx
80107499:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010749c:	39 c2                	cmp    %eax,%edx
8010749e:	72 bb                	jb     8010745b <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
801074a0:	c7 04 24 80 9b 12 80 	movl   $0x80129b80,(%esp)
801074a7:	e8 82 e7 ff ff       	call   80105c2e <release>
  return 0;
801074ac:	b8 00 00 00 00       	mov    $0x0,%eax
}
801074b1:	c9                   	leave  
801074b2:	c3                   	ret    

801074b3 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
801074b3:	55                   	push   %ebp
801074b4:	89 e5                	mov    %esp,%ebp
801074b6:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
801074b9:	c7 04 24 80 9b 12 80 	movl   $0x80129b80,(%esp)
801074c0:	e8 ce e6 ff ff       	call   80105b93 <acquire>
  xticks = ticks;
801074c5:	a1 c0 a3 12 80       	mov    0x8012a3c0,%eax
801074ca:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
801074cd:	c7 04 24 80 9b 12 80 	movl   $0x80129b80,(%esp)
801074d4:	e8 55 e7 ff ff       	call   80105c2e <release>
  return xticks;
801074d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801074dc:	c9                   	leave  
801074dd:	c3                   	ret    

801074de <sys_enableSwapping>:

void
sys_enableSwapping(void)
{
801074de:	55                   	push   %ebp
801074df:	89 e5                	mov    %esp,%ebp
  swapFlag = 1;
801074e1:	c7 05 80 c6 10 80 01 	movl   $0x1,0x8010c680
801074e8:	00 00 00 
}
801074eb:	5d                   	pop    %ebp
801074ec:	c3                   	ret    

801074ed <sys_disableSwapping>:

void
sys_disableSwapping(void)
{
801074ed:	55                   	push   %ebp
801074ee:	89 e5                	mov    %esp,%ebp
  swapFlag = 0;
801074f0:	c7 05 80 c6 10 80 00 	movl   $0x0,0x8010c680
801074f7:	00 00 00 
}
801074fa:	5d                   	pop    %ebp
801074fb:	c3                   	ret    

801074fc <sys_sleep2>:

int
sys_sleep2(void)
{
801074fc:	55                   	push   %ebp
801074fd:	89 e5                	mov    %esp,%ebp
801074ff:	83 ec 18             	sub    $0x18,%esp
  acquire(&tickslock);
80107502:	c7 04 24 80 9b 12 80 	movl   $0x80129b80,(%esp)
80107509:	e8 85 e6 ff ff       	call   80105b93 <acquire>
  if(proc->killed){
8010750e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107514:	8b 40 24             	mov    0x24(%eax),%eax
80107517:	85 c0                	test   %eax,%eax
80107519:	74 13                	je     8010752e <sys_sleep2+0x32>
    release(&tickslock);
8010751b:	c7 04 24 80 9b 12 80 	movl   $0x80129b80,(%esp)
80107522:	e8 07 e7 ff ff       	call   80105c2e <release>
    return -1;
80107527:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010752c:	eb 25                	jmp    80107553 <sys_sleep2+0x57>
  }
  sleep(&swapFlag, &tickslock);
8010752e:	c7 44 24 04 80 9b 12 	movl   $0x80129b80,0x4(%esp)
80107535:	80 
80107536:	c7 04 24 80 c6 10 80 	movl   $0x8010c680,(%esp)
8010753d:	e8 b1 e1 ff ff       	call   801056f3 <sleep>
  release(&tickslock);
80107542:	c7 04 24 80 9b 12 80 	movl   $0x80129b80,(%esp)
80107549:	e8 e0 e6 ff ff       	call   80105c2e <release>
  return 0;
8010754e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107553:	c9                   	leave  
80107554:	c3                   	ret    

80107555 <sys_wakeup2>:

int
sys_wakeup2(void)
{
80107555:	55                   	push   %ebp
80107556:	89 e5                	mov    %esp,%ebp
80107558:	83 ec 18             	sub    $0x18,%esp
  wakeup(&swapFlag);
8010755b:	c7 04 24 80 c6 10 80 	movl   $0x8010c680,(%esp)
80107562:	e8 fe e2 ff ff       	call   80105865 <wakeup>
  return 0;
80107567:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010756c:	c9                   	leave  
8010756d:	c3                   	ret    

8010756e <sys_getAllocatedPages>:

int
sys_getAllocatedPages(void)
{
8010756e:	55                   	push   %ebp
8010756f:	89 e5                	mov    %esp,%ebp
80107571:	83 ec 28             	sub    $0x28,%esp
  int pid;
  if(argint(0, &pid) < 0)
80107574:	8d 45 f4             	lea    -0xc(%ebp),%eax
80107577:	89 44 24 04          	mov    %eax,0x4(%esp)
8010757b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107582:	e8 e3 eb ff ff       	call   8010616a <argint>
80107587:	85 c0                	test   %eax,%eax
80107589:	79 07                	jns    80107592 <sys_getAllocatedPages+0x24>
    return -1;
8010758b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107590:	eb 0b                	jmp    8010759d <sys_getAllocatedPages+0x2f>
  return getAllocatedPages(pid);
80107592:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107595:	89 04 24             	mov    %eax,(%esp)
80107598:	e8 b9 e4 ff ff       	call   80105a56 <getAllocatedPages>
}
8010759d:	c9                   	leave  
8010759e:	c3                   	ret    

8010759f <sys_shmget>:

int 
sys_shmget(void)
{
8010759f:	55                   	push   %ebp
801075a0:	89 e5                	mov    %esp,%ebp
801075a2:	83 ec 28             	sub    $0x28,%esp
  int key,size, shmflg;
  
  if(argint(0, &key) < 0)
801075a5:	8d 45 f4             	lea    -0xc(%ebp),%eax
801075a8:	89 44 24 04          	mov    %eax,0x4(%esp)
801075ac:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801075b3:	e8 b2 eb ff ff       	call   8010616a <argint>
801075b8:	85 c0                	test   %eax,%eax
801075ba:	79 07                	jns    801075c3 <sys_shmget+0x24>
    return -1;
801075bc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801075c1:	eb 65                	jmp    80107628 <sys_shmget+0x89>
  
  if(argint(1, &size) < 0)
801075c3:	8d 45 f0             	lea    -0x10(%ebp),%eax
801075c6:	89 44 24 04          	mov    %eax,0x4(%esp)
801075ca:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801075d1:	e8 94 eb ff ff       	call   8010616a <argint>
801075d6:	85 c0                	test   %eax,%eax
801075d8:	79 07                	jns    801075e1 <sys_shmget+0x42>
    return -1;
801075da:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801075df:	eb 47                	jmp    80107628 <sys_shmget+0x89>
  if(size<0)
801075e1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801075e4:	85 c0                	test   %eax,%eax
801075e6:	79 07                	jns    801075ef <sys_shmget+0x50>
    return -1;
801075e8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801075ed:	eb 39                	jmp    80107628 <sys_shmget+0x89>
  
  if(argint(2, &shmflg) < 0)
801075ef:	8d 45 ec             	lea    -0x14(%ebp),%eax
801075f2:	89 44 24 04          	mov    %eax,0x4(%esp)
801075f6:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801075fd:	e8 68 eb ff ff       	call   8010616a <argint>
80107602:	85 c0                	test   %eax,%eax
80107604:	79 07                	jns    8010760d <sys_shmget+0x6e>
    return -1;
80107606:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010760b:	eb 1b                	jmp    80107628 <sys_shmget+0x89>
  
  return shmget(key, (uint)size,shmflg);
8010760d:	8b 4d ec             	mov    -0x14(%ebp),%ecx
80107610:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107613:	89 c2                	mov    %eax,%edx
80107615:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107618:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010761c:	89 54 24 04          	mov    %edx,0x4(%esp)
80107620:	89 04 24             	mov    %eax,(%esp)
80107623:	e8 35 b5 ff ff       	call   80102b5d <shmget>
}
80107628:	c9                   	leave  
80107629:	c3                   	ret    

8010762a <sys_shmdel>:

int 
sys_shmdel(void)
{
8010762a:	55                   	push   %ebp
8010762b:	89 e5                	mov    %esp,%ebp
8010762d:	83 ec 28             	sub    $0x28,%esp
  int shmid;
  if(argint(0, &shmid) < 0)
80107630:	8d 45 f4             	lea    -0xc(%ebp),%eax
80107633:	89 44 24 04          	mov    %eax,0x4(%esp)
80107637:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010763e:	e8 27 eb ff ff       	call   8010616a <argint>
80107643:	85 c0                	test   %eax,%eax
80107645:	79 07                	jns    8010764e <sys_shmdel+0x24>
    return -1;
80107647:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010764c:	eb 0b                	jmp    80107659 <sys_shmdel+0x2f>
  
  return shmdel(shmid);
8010764e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107651:	89 04 24             	mov    %eax,(%esp)
80107654:	e8 69 b6 ff ff       	call   80102cc2 <shmdel>
}
80107659:	c9                   	leave  
8010765a:	c3                   	ret    

8010765b <sys_shmat>:

void *
sys_shmat(void)
{
8010765b:	55                   	push   %ebp
8010765c:	89 e5                	mov    %esp,%ebp
8010765e:	83 ec 28             	sub    $0x28,%esp
  int shmid,shmflg;
  
  if(argint(0, &shmid) < 0)
80107661:	8d 45 f4             	lea    -0xc(%ebp),%eax
80107664:	89 44 24 04          	mov    %eax,0x4(%esp)
80107668:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010766f:	e8 f6 ea ff ff       	call   8010616a <argint>
80107674:	85 c0                	test   %eax,%eax
80107676:	79 07                	jns    8010767f <sys_shmat+0x24>
    return (void*)-1;
80107678:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010767d:	eb 30                	jmp    801076af <sys_shmat+0x54>
  
  if(argint(1, &shmflg) < 0)
8010767f:	8d 45 f0             	lea    -0x10(%ebp),%eax
80107682:	89 44 24 04          	mov    %eax,0x4(%esp)
80107686:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010768d:	e8 d8 ea ff ff       	call   8010616a <argint>
80107692:	85 c0                	test   %eax,%eax
80107694:	79 07                	jns    8010769d <sys_shmat+0x42>
    return (void*)-1;
80107696:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010769b:	eb 12                	jmp    801076af <sys_shmat+0x54>
  
  return shmat(shmid,shmflg);
8010769d:	8b 55 f0             	mov    -0x10(%ebp),%edx
801076a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076a3:	89 54 24 04          	mov    %edx,0x4(%esp)
801076a7:	89 04 24             	mov    %eax,(%esp)
801076aa:	e8 ee b6 ff ff       	call   80102d9d <shmat>
}
801076af:	c9                   	leave  
801076b0:	c3                   	ret    

801076b1 <sys_shmdt>:

int 
sys_shmdt(void)
{
801076b1:	55                   	push   %ebp
801076b2:	89 e5                	mov    %esp,%ebp
801076b4:	83 ec 28             	sub    $0x28,%esp
  void* shmaddr;
  if(argptr(0, (void*)&shmaddr,sizeof(void*)) < 0)
801076b7:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
801076be:	00 
801076bf:	8d 45 f4             	lea    -0xc(%ebp),%eax
801076c2:	89 44 24 04          	mov    %eax,0x4(%esp)
801076c6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801076cd:	e8 d0 ea ff ff       	call   801061a2 <argptr>
801076d2:	85 c0                	test   %eax,%eax
801076d4:	79 07                	jns    801076dd <sys_shmdt+0x2c>
    return -1;
801076d6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801076db:	eb 0b                	jmp    801076e8 <sys_shmdt+0x37>
  return shmdt(shmaddr);
801076dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076e0:	89 04 24             	mov    %eax,(%esp)
801076e3:	e8 cd b8 ff ff       	call   80102fb5 <shmdt>
}
801076e8:	c9                   	leave  
801076e9:	c3                   	ret    
	...

801076ec <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801076ec:	55                   	push   %ebp
801076ed:	89 e5                	mov    %esp,%ebp
801076ef:	83 ec 08             	sub    $0x8,%esp
801076f2:	8b 55 08             	mov    0x8(%ebp),%edx
801076f5:	8b 45 0c             	mov    0xc(%ebp),%eax
801076f8:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801076fc:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801076ff:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80107703:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80107707:	ee                   	out    %al,(%dx)
}
80107708:	c9                   	leave  
80107709:	c3                   	ret    

8010770a <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
8010770a:	55                   	push   %ebp
8010770b:	89 e5                	mov    %esp,%ebp
8010770d:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
80107710:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
80107717:	00 
80107718:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
8010771f:	e8 c8 ff ff ff       	call   801076ec <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
80107724:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
8010772b:	00 
8010772c:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
80107733:	e8 b4 ff ff ff       	call   801076ec <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
80107738:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
8010773f:	00 
80107740:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
80107747:	e8 a0 ff ff ff       	call   801076ec <outb>
  picenable(IRQ_TIMER);
8010774c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107753:	e8 69 cb ff ff       	call   801042c1 <picenable>
}
80107758:	c9                   	leave  
80107759:	c3                   	ret    
	...

8010775c <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
8010775c:	1e                   	push   %ds
  pushl %es
8010775d:	06                   	push   %es
  pushl %fs
8010775e:	0f a0                	push   %fs
  pushl %gs
80107760:	0f a8                	push   %gs
  pushal
80107762:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
80107763:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
80107767:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80107769:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
8010776b:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
8010776f:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
80107771:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
80107773:	54                   	push   %esp
  call trap
80107774:	e8 de 01 00 00       	call   80107957 <trap>
  addl $4, %esp
80107779:	83 c4 04             	add    $0x4,%esp

8010777c <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
8010777c:	61                   	popa   
  popl %gs
8010777d:	0f a9                	pop    %gs
  popl %fs
8010777f:	0f a1                	pop    %fs
  popl %es
80107781:	07                   	pop    %es
  popl %ds
80107782:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80107783:	83 c4 08             	add    $0x8,%esp
  iret
80107786:	cf                   	iret   
	...

80107788 <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
80107788:	55                   	push   %ebp
80107789:	89 e5                	mov    %esp,%ebp
8010778b:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
8010778e:	8b 45 0c             	mov    0xc(%ebp),%eax
80107791:	83 e8 01             	sub    $0x1,%eax
80107794:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80107798:	8b 45 08             	mov    0x8(%ebp),%eax
8010779b:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
8010779f:	8b 45 08             	mov    0x8(%ebp),%eax
801077a2:	c1 e8 10             	shr    $0x10,%eax
801077a5:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
801077a9:	8d 45 fa             	lea    -0x6(%ebp),%eax
801077ac:	0f 01 18             	lidtl  (%eax)
}
801077af:	c9                   	leave  
801077b0:	c3                   	ret    

801077b1 <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
801077b1:	55                   	push   %ebp
801077b2:	89 e5                	mov    %esp,%ebp
801077b4:	53                   	push   %ebx
801077b5:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
801077b8:	0f 20 d3             	mov    %cr2,%ebx
801077bb:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return val;
801077be:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
801077c1:	83 c4 10             	add    $0x10,%esp
801077c4:	5b                   	pop    %ebx
801077c5:	5d                   	pop    %ebp
801077c6:	c3                   	ret    

801077c7 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
801077c7:	55                   	push   %ebp
801077c8:	89 e5                	mov    %esp,%ebp
801077ca:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
801077cd:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801077d4:	e9 c3 00 00 00       	jmp    8010789c <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
801077d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077dc:	8b 04 85 bc c0 10 80 	mov    -0x7fef3f44(,%eax,4),%eax
801077e3:	89 c2                	mov    %eax,%edx
801077e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077e8:	66 89 14 c5 c0 9b 12 	mov    %dx,-0x7fed6440(,%eax,8)
801077ef:	80 
801077f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077f3:	66 c7 04 c5 c2 9b 12 	movw   $0x8,-0x7fed643e(,%eax,8)
801077fa:	80 08 00 
801077fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107800:	0f b6 14 c5 c4 9b 12 	movzbl -0x7fed643c(,%eax,8),%edx
80107807:	80 
80107808:	83 e2 e0             	and    $0xffffffe0,%edx
8010780b:	88 14 c5 c4 9b 12 80 	mov    %dl,-0x7fed643c(,%eax,8)
80107812:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107815:	0f b6 14 c5 c4 9b 12 	movzbl -0x7fed643c(,%eax,8),%edx
8010781c:	80 
8010781d:	83 e2 1f             	and    $0x1f,%edx
80107820:	88 14 c5 c4 9b 12 80 	mov    %dl,-0x7fed643c(,%eax,8)
80107827:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010782a:	0f b6 14 c5 c5 9b 12 	movzbl -0x7fed643b(,%eax,8),%edx
80107831:	80 
80107832:	83 e2 f0             	and    $0xfffffff0,%edx
80107835:	83 ca 0e             	or     $0xe,%edx
80107838:	88 14 c5 c5 9b 12 80 	mov    %dl,-0x7fed643b(,%eax,8)
8010783f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107842:	0f b6 14 c5 c5 9b 12 	movzbl -0x7fed643b(,%eax,8),%edx
80107849:	80 
8010784a:	83 e2 ef             	and    $0xffffffef,%edx
8010784d:	88 14 c5 c5 9b 12 80 	mov    %dl,-0x7fed643b(,%eax,8)
80107854:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107857:	0f b6 14 c5 c5 9b 12 	movzbl -0x7fed643b(,%eax,8),%edx
8010785e:	80 
8010785f:	83 e2 9f             	and    $0xffffff9f,%edx
80107862:	88 14 c5 c5 9b 12 80 	mov    %dl,-0x7fed643b(,%eax,8)
80107869:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010786c:	0f b6 14 c5 c5 9b 12 	movzbl -0x7fed643b(,%eax,8),%edx
80107873:	80 
80107874:	83 ca 80             	or     $0xffffff80,%edx
80107877:	88 14 c5 c5 9b 12 80 	mov    %dl,-0x7fed643b(,%eax,8)
8010787e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107881:	8b 04 85 bc c0 10 80 	mov    -0x7fef3f44(,%eax,4),%eax
80107888:	c1 e8 10             	shr    $0x10,%eax
8010788b:	89 c2                	mov    %eax,%edx
8010788d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107890:	66 89 14 c5 c6 9b 12 	mov    %dx,-0x7fed643a(,%eax,8)
80107897:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
80107898:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010789c:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
801078a3:	0f 8e 30 ff ff ff    	jle    801077d9 <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
801078a9:	a1 bc c1 10 80       	mov    0x8010c1bc,%eax
801078ae:	66 a3 c0 9d 12 80    	mov    %ax,0x80129dc0
801078b4:	66 c7 05 c2 9d 12 80 	movw   $0x8,0x80129dc2
801078bb:	08 00 
801078bd:	0f b6 05 c4 9d 12 80 	movzbl 0x80129dc4,%eax
801078c4:	83 e0 e0             	and    $0xffffffe0,%eax
801078c7:	a2 c4 9d 12 80       	mov    %al,0x80129dc4
801078cc:	0f b6 05 c4 9d 12 80 	movzbl 0x80129dc4,%eax
801078d3:	83 e0 1f             	and    $0x1f,%eax
801078d6:	a2 c4 9d 12 80       	mov    %al,0x80129dc4
801078db:	0f b6 05 c5 9d 12 80 	movzbl 0x80129dc5,%eax
801078e2:	83 c8 0f             	or     $0xf,%eax
801078e5:	a2 c5 9d 12 80       	mov    %al,0x80129dc5
801078ea:	0f b6 05 c5 9d 12 80 	movzbl 0x80129dc5,%eax
801078f1:	83 e0 ef             	and    $0xffffffef,%eax
801078f4:	a2 c5 9d 12 80       	mov    %al,0x80129dc5
801078f9:	0f b6 05 c5 9d 12 80 	movzbl 0x80129dc5,%eax
80107900:	83 c8 60             	or     $0x60,%eax
80107903:	a2 c5 9d 12 80       	mov    %al,0x80129dc5
80107908:	0f b6 05 c5 9d 12 80 	movzbl 0x80129dc5,%eax
8010790f:	83 c8 80             	or     $0xffffff80,%eax
80107912:	a2 c5 9d 12 80       	mov    %al,0x80129dc5
80107917:	a1 bc c1 10 80       	mov    0x8010c1bc,%eax
8010791c:	c1 e8 10             	shr    $0x10,%eax
8010791f:	66 a3 c6 9d 12 80    	mov    %ax,0x80129dc6
  
  initlock(&tickslock, "time");
80107925:	c7 44 24 04 b8 9c 10 	movl   $0x80109cb8,0x4(%esp)
8010792c:	80 
8010792d:	c7 04 24 80 9b 12 80 	movl   $0x80129b80,(%esp)
80107934:	e8 39 e2 ff ff       	call   80105b72 <initlock>
}
80107939:	c9                   	leave  
8010793a:	c3                   	ret    

8010793b <idtinit>:

void
idtinit(void)
{
8010793b:	55                   	push   %ebp
8010793c:	89 e5                	mov    %esp,%ebp
8010793e:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
80107941:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
80107948:	00 
80107949:	c7 04 24 c0 9b 12 80 	movl   $0x80129bc0,(%esp)
80107950:	e8 33 fe ff ff       	call   80107788 <lidt>
}
80107955:	c9                   	leave  
80107956:	c3                   	ret    

80107957 <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
80107957:	55                   	push   %ebp
80107958:	89 e5                	mov    %esp,%ebp
8010795a:	57                   	push   %edi
8010795b:	56                   	push   %esi
8010795c:	53                   	push   %ebx
8010795d:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
80107960:	8b 45 08             	mov    0x8(%ebp),%eax
80107963:	8b 40 30             	mov    0x30(%eax),%eax
80107966:	83 f8 40             	cmp    $0x40,%eax
80107969:	75 3e                	jne    801079a9 <trap+0x52>
    if(proc->killed)
8010796b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107971:	8b 40 24             	mov    0x24(%eax),%eax
80107974:	85 c0                	test   %eax,%eax
80107976:	74 05                	je     8010797d <trap+0x26>
      exit();
80107978:	e8 dc d8 ff ff       	call   80105259 <exit>
    proc->tf = tf;
8010797d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107983:	8b 55 08             	mov    0x8(%ebp),%edx
80107986:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
80107989:	e8 b9 e8 ff ff       	call   80106247 <syscall>
    if(proc->killed)
8010798e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107994:	8b 40 24             	mov    0x24(%eax),%eax
80107997:	85 c0                	test   %eax,%eax
80107999:	0f 84 34 02 00 00    	je     80107bd3 <trap+0x27c>
      exit();
8010799f:	e8 b5 d8 ff ff       	call   80105259 <exit>
    return;
801079a4:	e9 2a 02 00 00       	jmp    80107bd3 <trap+0x27c>
  }

  switch(tf->trapno){
801079a9:	8b 45 08             	mov    0x8(%ebp),%eax
801079ac:	8b 40 30             	mov    0x30(%eax),%eax
801079af:	83 e8 20             	sub    $0x20,%eax
801079b2:	83 f8 1f             	cmp    $0x1f,%eax
801079b5:	0f 87 bc 00 00 00    	ja     80107a77 <trap+0x120>
801079bb:	8b 04 85 60 9d 10 80 	mov    -0x7fef62a0(,%eax,4),%eax
801079c2:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
801079c4:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801079ca:	0f b6 00             	movzbl (%eax),%eax
801079cd:	84 c0                	test   %al,%al
801079cf:	75 31                	jne    80107a02 <trap+0xab>
      acquire(&tickslock);
801079d1:	c7 04 24 80 9b 12 80 	movl   $0x80129b80,(%esp)
801079d8:	e8 b6 e1 ff ff       	call   80105b93 <acquire>
      ticks++;
801079dd:	a1 c0 a3 12 80       	mov    0x8012a3c0,%eax
801079e2:	83 c0 01             	add    $0x1,%eax
801079e5:	a3 c0 a3 12 80       	mov    %eax,0x8012a3c0
      wakeup(&ticks);
801079ea:	c7 04 24 c0 a3 12 80 	movl   $0x8012a3c0,(%esp)
801079f1:	e8 6f de ff ff       	call   80105865 <wakeup>
      release(&tickslock);
801079f6:	c7 04 24 80 9b 12 80 	movl   $0x80129b80,(%esp)
801079fd:	e8 2c e2 ff ff       	call   80105c2e <release>
    }
    lapiceoi();
80107a02:	e8 de bc ff ff       	call   801036e5 <lapiceoi>
    break;
80107a07:	e9 41 01 00 00       	jmp    80107b4d <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
80107a0c:	e8 e6 ac ff ff       	call   801026f7 <ideintr>
    lapiceoi();
80107a11:	e8 cf bc ff ff       	call   801036e5 <lapiceoi>
    break;
80107a16:	e9 32 01 00 00       	jmp    80107b4d <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
80107a1b:	e8 a3 ba ff ff       	call   801034c3 <kbdintr>
    lapiceoi();
80107a20:	e8 c0 bc ff ff       	call   801036e5 <lapiceoi>
    break;
80107a25:	e9 23 01 00 00       	jmp    80107b4d <trap+0x1f6>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
80107a2a:	e8 a9 03 00 00       	call   80107dd8 <uartintr>
    lapiceoi();
80107a2f:	e8 b1 bc ff ff       	call   801036e5 <lapiceoi>
    break;
80107a34:	e9 14 01 00 00       	jmp    80107b4d <trap+0x1f6>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
            cpu->id, tf->cs, tf->eip);
80107a39:	8b 45 08             	mov    0x8(%ebp),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80107a3c:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
80107a3f:	8b 45 08             	mov    0x8(%ebp),%eax
80107a42:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80107a46:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
80107a49:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107a4f:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80107a52:	0f b6 c0             	movzbl %al,%eax
80107a55:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80107a59:	89 54 24 08          	mov    %edx,0x8(%esp)
80107a5d:	89 44 24 04          	mov    %eax,0x4(%esp)
80107a61:	c7 04 24 c0 9c 10 80 	movl   $0x80109cc0,(%esp)
80107a68:	e8 34 89 ff ff       	call   801003a1 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
80107a6d:	e8 73 bc ff ff       	call   801036e5 <lapiceoi>
    break;
80107a72:	e9 d6 00 00 00       	jmp    80107b4d <trap+0x1f6>
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
80107a77:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107a7d:	85 c0                	test   %eax,%eax
80107a7f:	74 11                	je     80107a92 <trap+0x13b>
80107a81:	8b 45 08             	mov    0x8(%ebp),%eax
80107a84:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80107a88:	0f b7 c0             	movzwl %ax,%eax
80107a8b:	83 e0 03             	and    $0x3,%eax
80107a8e:	85 c0                	test   %eax,%eax
80107a90:	75 46                	jne    80107ad8 <trap+0x181>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80107a92:	e8 1a fd ff ff       	call   801077b1 <rcr2>
              tf->trapno, cpu->id, tf->eip, rcr2());
80107a97:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80107a9a:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
80107a9d:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107aa4:	0f b6 12             	movzbl (%edx),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80107aa7:	0f b6 ca             	movzbl %dl,%ecx
              tf->trapno, cpu->id, tf->eip, rcr2());
80107aaa:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80107aad:	8b 52 30             	mov    0x30(%edx),%edx
80107ab0:	89 44 24 10          	mov    %eax,0x10(%esp)
80107ab4:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
80107ab8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80107abc:	89 54 24 04          	mov    %edx,0x4(%esp)
80107ac0:	c7 04 24 e4 9c 10 80 	movl   $0x80109ce4,(%esp)
80107ac7:	e8 d5 88 ff ff       	call   801003a1 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
80107acc:	c7 04 24 16 9d 10 80 	movl   $0x80109d16,(%esp)
80107ad3:	e8 65 8a ff ff       	call   8010053d <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107ad8:	e8 d4 fc ff ff       	call   801077b1 <rcr2>
80107add:	89 c2                	mov    %eax,%edx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107adf:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107ae2:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107ae5:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107aeb:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107aee:	0f b6 f0             	movzbl %al,%esi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107af1:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107af4:	8b 58 34             	mov    0x34(%eax),%ebx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107af7:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107afa:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107afd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107b03:	83 c0 6c             	add    $0x6c,%eax
80107b06:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80107b09:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107b0f:	8b 40 10             	mov    0x10(%eax),%eax
80107b12:	89 54 24 1c          	mov    %edx,0x1c(%esp)
80107b16:	89 7c 24 18          	mov    %edi,0x18(%esp)
80107b1a:	89 74 24 14          	mov    %esi,0x14(%esp)
80107b1e:	89 5c 24 10          	mov    %ebx,0x10(%esp)
80107b22:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80107b26:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80107b29:	89 54 24 08          	mov    %edx,0x8(%esp)
80107b2d:	89 44 24 04          	mov    %eax,0x4(%esp)
80107b31:	c7 04 24 1c 9d 10 80 	movl   $0x80109d1c,(%esp)
80107b38:	e8 64 88 ff ff       	call   801003a1 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
80107b3d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107b43:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
80107b4a:	eb 01                	jmp    80107b4d <trap+0x1f6>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
80107b4c:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80107b4d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107b53:	85 c0                	test   %eax,%eax
80107b55:	74 24                	je     80107b7b <trap+0x224>
80107b57:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107b5d:	8b 40 24             	mov    0x24(%eax),%eax
80107b60:	85 c0                	test   %eax,%eax
80107b62:	74 17                	je     80107b7b <trap+0x224>
80107b64:	8b 45 08             	mov    0x8(%ebp),%eax
80107b67:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80107b6b:	0f b7 c0             	movzwl %ax,%eax
80107b6e:	83 e0 03             	and    $0x3,%eax
80107b71:	83 f8 03             	cmp    $0x3,%eax
80107b74:	75 05                	jne    80107b7b <trap+0x224>
    exit();
80107b76:	e8 de d6 ff ff       	call   80105259 <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
80107b7b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107b81:	85 c0                	test   %eax,%eax
80107b83:	74 1e                	je     80107ba3 <trap+0x24c>
80107b85:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107b8b:	8b 40 0c             	mov    0xc(%eax),%eax
80107b8e:	83 f8 04             	cmp    $0x4,%eax
80107b91:	75 10                	jne    80107ba3 <trap+0x24c>
80107b93:	8b 45 08             	mov    0x8(%ebp),%eax
80107b96:	8b 40 30             	mov    0x30(%eax),%eax
80107b99:	83 f8 20             	cmp    $0x20,%eax
80107b9c:	75 05                	jne    80107ba3 <trap+0x24c>
    yield();
80107b9e:	e8 f2 da ff ff       	call   80105695 <yield>

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80107ba3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107ba9:	85 c0                	test   %eax,%eax
80107bab:	74 27                	je     80107bd4 <trap+0x27d>
80107bad:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107bb3:	8b 40 24             	mov    0x24(%eax),%eax
80107bb6:	85 c0                	test   %eax,%eax
80107bb8:	74 1a                	je     80107bd4 <trap+0x27d>
80107bba:	8b 45 08             	mov    0x8(%ebp),%eax
80107bbd:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80107bc1:	0f b7 c0             	movzwl %ax,%eax
80107bc4:	83 e0 03             	and    $0x3,%eax
80107bc7:	83 f8 03             	cmp    $0x3,%eax
80107bca:	75 08                	jne    80107bd4 <trap+0x27d>
    exit();
80107bcc:	e8 88 d6 ff ff       	call   80105259 <exit>
80107bd1:	eb 01                	jmp    80107bd4 <trap+0x27d>
      exit();
    proc->tf = tf;
    syscall();
    if(proc->killed)
      exit();
    return;
80107bd3:	90                   	nop
    yield();

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
    exit();
}
80107bd4:	83 c4 3c             	add    $0x3c,%esp
80107bd7:	5b                   	pop    %ebx
80107bd8:	5e                   	pop    %esi
80107bd9:	5f                   	pop    %edi
80107bda:	5d                   	pop    %ebp
80107bdb:	c3                   	ret    

80107bdc <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80107bdc:	55                   	push   %ebp
80107bdd:	89 e5                	mov    %esp,%ebp
80107bdf:	53                   	push   %ebx
80107be0:	83 ec 14             	sub    $0x14,%esp
80107be3:	8b 45 08             	mov    0x8(%ebp),%eax
80107be6:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80107bea:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80107bee:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80107bf2:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80107bf6:	ec                   	in     (%dx),%al
80107bf7:	89 c3                	mov    %eax,%ebx
80107bf9:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80107bfc:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80107c00:	83 c4 14             	add    $0x14,%esp
80107c03:	5b                   	pop    %ebx
80107c04:	5d                   	pop    %ebp
80107c05:	c3                   	ret    

80107c06 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80107c06:	55                   	push   %ebp
80107c07:	89 e5                	mov    %esp,%ebp
80107c09:	83 ec 08             	sub    $0x8,%esp
80107c0c:	8b 55 08             	mov    0x8(%ebp),%edx
80107c0f:	8b 45 0c             	mov    0xc(%ebp),%eax
80107c12:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80107c16:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80107c19:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80107c1d:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80107c21:	ee                   	out    %al,(%dx)
}
80107c22:	c9                   	leave  
80107c23:	c3                   	ret    

80107c24 <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
80107c24:	55                   	push   %ebp
80107c25:	89 e5                	mov    %esp,%ebp
80107c27:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
80107c2a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107c31:	00 
80107c32:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80107c39:	e8 c8 ff ff ff       	call   80107c06 <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
80107c3e:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
80107c45:	00 
80107c46:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80107c4d:	e8 b4 ff ff ff       	call   80107c06 <outb>
  outb(COM1+0, 115200/9600);
80107c52:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
80107c59:	00 
80107c5a:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107c61:	e8 a0 ff ff ff       	call   80107c06 <outb>
  outb(COM1+1, 0);
80107c66:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107c6d:	00 
80107c6e:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80107c75:	e8 8c ff ff ff       	call   80107c06 <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
80107c7a:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80107c81:	00 
80107c82:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80107c89:	e8 78 ff ff ff       	call   80107c06 <outb>
  outb(COM1+4, 0);
80107c8e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107c95:	00 
80107c96:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
80107c9d:	e8 64 ff ff ff       	call   80107c06 <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
80107ca2:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80107ca9:	00 
80107caa:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80107cb1:	e8 50 ff ff ff       	call   80107c06 <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
80107cb6:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80107cbd:	e8 1a ff ff ff       	call   80107bdc <inb>
80107cc2:	3c ff                	cmp    $0xff,%al
80107cc4:	74 6c                	je     80107d32 <uartinit+0x10e>
    return;
  uart = 1;
80107cc6:	c7 05 d4 c6 10 80 01 	movl   $0x1,0x8010c6d4
80107ccd:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
80107cd0:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80107cd7:	e8 00 ff ff ff       	call   80107bdc <inb>
  inb(COM1+0);
80107cdc:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107ce3:	e8 f4 fe ff ff       	call   80107bdc <inb>
  picenable(IRQ_COM1);
80107ce8:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80107cef:	e8 cd c5 ff ff       	call   801042c1 <picenable>
  ioapicenable(IRQ_COM1, 0);
80107cf4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107cfb:	00 
80107cfc:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80107d03:	e8 72 ac ff ff       	call   8010297a <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80107d08:	c7 45 f4 e0 9d 10 80 	movl   $0x80109de0,-0xc(%ebp)
80107d0f:	eb 15                	jmp    80107d26 <uartinit+0x102>
    uartputc(*p);
80107d11:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d14:	0f b6 00             	movzbl (%eax),%eax
80107d17:	0f be c0             	movsbl %al,%eax
80107d1a:	89 04 24             	mov    %eax,(%esp)
80107d1d:	e8 13 00 00 00       	call   80107d35 <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80107d22:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107d26:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d29:	0f b6 00             	movzbl (%eax),%eax
80107d2c:	84 c0                	test   %al,%al
80107d2e:	75 e1                	jne    80107d11 <uartinit+0xed>
80107d30:	eb 01                	jmp    80107d33 <uartinit+0x10f>
  outb(COM1+4, 0);
  outb(COM1+1, 0x01);    // Enable receive interrupts.

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
    return;
80107d32:	90                   	nop
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
    uartputc(*p);
}
80107d33:	c9                   	leave  
80107d34:	c3                   	ret    

80107d35 <uartputc>:

void
uartputc(int c)
{
80107d35:	55                   	push   %ebp
80107d36:	89 e5                	mov    %esp,%ebp
80107d38:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
80107d3b:	a1 d4 c6 10 80       	mov    0x8010c6d4,%eax
80107d40:	85 c0                	test   %eax,%eax
80107d42:	74 4d                	je     80107d91 <uartputc+0x5c>
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80107d44:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80107d4b:	eb 10                	jmp    80107d5d <uartputc+0x28>
    microdelay(10);
80107d4d:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
80107d54:	e8 b1 b9 ff ff       	call   8010370a <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80107d59:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107d5d:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
80107d61:	7f 16                	jg     80107d79 <uartputc+0x44>
80107d63:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80107d6a:	e8 6d fe ff ff       	call   80107bdc <inb>
80107d6f:	0f b6 c0             	movzbl %al,%eax
80107d72:	83 e0 20             	and    $0x20,%eax
80107d75:	85 c0                	test   %eax,%eax
80107d77:	74 d4                	je     80107d4d <uartputc+0x18>
    microdelay(10);
  outb(COM1+0, c);
80107d79:	8b 45 08             	mov    0x8(%ebp),%eax
80107d7c:	0f b6 c0             	movzbl %al,%eax
80107d7f:	89 44 24 04          	mov    %eax,0x4(%esp)
80107d83:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107d8a:	e8 77 fe ff ff       	call   80107c06 <outb>
80107d8f:	eb 01                	jmp    80107d92 <uartputc+0x5d>
uartputc(int c)
{
  int i;

  if(!uart)
    return;
80107d91:	90                   	nop
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
    microdelay(10);
  outb(COM1+0, c);
}
80107d92:	c9                   	leave  
80107d93:	c3                   	ret    

80107d94 <uartgetc>:

static int
uartgetc(void)
{
80107d94:	55                   	push   %ebp
80107d95:	89 e5                	mov    %esp,%ebp
80107d97:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
80107d9a:	a1 d4 c6 10 80       	mov    0x8010c6d4,%eax
80107d9f:	85 c0                	test   %eax,%eax
80107da1:	75 07                	jne    80107daa <uartgetc+0x16>
    return -1;
80107da3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107da8:	eb 2c                	jmp    80107dd6 <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
80107daa:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80107db1:	e8 26 fe ff ff       	call   80107bdc <inb>
80107db6:	0f b6 c0             	movzbl %al,%eax
80107db9:	83 e0 01             	and    $0x1,%eax
80107dbc:	85 c0                	test   %eax,%eax
80107dbe:	75 07                	jne    80107dc7 <uartgetc+0x33>
    return -1;
80107dc0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107dc5:	eb 0f                	jmp    80107dd6 <uartgetc+0x42>
  return inb(COM1+0);
80107dc7:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107dce:	e8 09 fe ff ff       	call   80107bdc <inb>
80107dd3:	0f b6 c0             	movzbl %al,%eax
}
80107dd6:	c9                   	leave  
80107dd7:	c3                   	ret    

80107dd8 <uartintr>:

void
uartintr(void)
{
80107dd8:	55                   	push   %ebp
80107dd9:	89 e5                	mov    %esp,%ebp
80107ddb:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
80107dde:	c7 04 24 94 7d 10 80 	movl   $0x80107d94,(%esp)
80107de5:	e8 c3 89 ff ff       	call   801007ad <consoleintr>
}
80107dea:	c9                   	leave  
80107deb:	c3                   	ret    

80107dec <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80107dec:	6a 00                	push   $0x0
  pushl $0
80107dee:	6a 00                	push   $0x0
  jmp alltraps
80107df0:	e9 67 f9 ff ff       	jmp    8010775c <alltraps>

80107df5 <vector1>:
.globl vector1
vector1:
  pushl $0
80107df5:	6a 00                	push   $0x0
  pushl $1
80107df7:	6a 01                	push   $0x1
  jmp alltraps
80107df9:	e9 5e f9 ff ff       	jmp    8010775c <alltraps>

80107dfe <vector2>:
.globl vector2
vector2:
  pushl $0
80107dfe:	6a 00                	push   $0x0
  pushl $2
80107e00:	6a 02                	push   $0x2
  jmp alltraps
80107e02:	e9 55 f9 ff ff       	jmp    8010775c <alltraps>

80107e07 <vector3>:
.globl vector3
vector3:
  pushl $0
80107e07:	6a 00                	push   $0x0
  pushl $3
80107e09:	6a 03                	push   $0x3
  jmp alltraps
80107e0b:	e9 4c f9 ff ff       	jmp    8010775c <alltraps>

80107e10 <vector4>:
.globl vector4
vector4:
  pushl $0
80107e10:	6a 00                	push   $0x0
  pushl $4
80107e12:	6a 04                	push   $0x4
  jmp alltraps
80107e14:	e9 43 f9 ff ff       	jmp    8010775c <alltraps>

80107e19 <vector5>:
.globl vector5
vector5:
  pushl $0
80107e19:	6a 00                	push   $0x0
  pushl $5
80107e1b:	6a 05                	push   $0x5
  jmp alltraps
80107e1d:	e9 3a f9 ff ff       	jmp    8010775c <alltraps>

80107e22 <vector6>:
.globl vector6
vector6:
  pushl $0
80107e22:	6a 00                	push   $0x0
  pushl $6
80107e24:	6a 06                	push   $0x6
  jmp alltraps
80107e26:	e9 31 f9 ff ff       	jmp    8010775c <alltraps>

80107e2b <vector7>:
.globl vector7
vector7:
  pushl $0
80107e2b:	6a 00                	push   $0x0
  pushl $7
80107e2d:	6a 07                	push   $0x7
  jmp alltraps
80107e2f:	e9 28 f9 ff ff       	jmp    8010775c <alltraps>

80107e34 <vector8>:
.globl vector8
vector8:
  pushl $8
80107e34:	6a 08                	push   $0x8
  jmp alltraps
80107e36:	e9 21 f9 ff ff       	jmp    8010775c <alltraps>

80107e3b <vector9>:
.globl vector9
vector9:
  pushl $0
80107e3b:	6a 00                	push   $0x0
  pushl $9
80107e3d:	6a 09                	push   $0x9
  jmp alltraps
80107e3f:	e9 18 f9 ff ff       	jmp    8010775c <alltraps>

80107e44 <vector10>:
.globl vector10
vector10:
  pushl $10
80107e44:	6a 0a                	push   $0xa
  jmp alltraps
80107e46:	e9 11 f9 ff ff       	jmp    8010775c <alltraps>

80107e4b <vector11>:
.globl vector11
vector11:
  pushl $11
80107e4b:	6a 0b                	push   $0xb
  jmp alltraps
80107e4d:	e9 0a f9 ff ff       	jmp    8010775c <alltraps>

80107e52 <vector12>:
.globl vector12
vector12:
  pushl $12
80107e52:	6a 0c                	push   $0xc
  jmp alltraps
80107e54:	e9 03 f9 ff ff       	jmp    8010775c <alltraps>

80107e59 <vector13>:
.globl vector13
vector13:
  pushl $13
80107e59:	6a 0d                	push   $0xd
  jmp alltraps
80107e5b:	e9 fc f8 ff ff       	jmp    8010775c <alltraps>

80107e60 <vector14>:
.globl vector14
vector14:
  pushl $14
80107e60:	6a 0e                	push   $0xe
  jmp alltraps
80107e62:	e9 f5 f8 ff ff       	jmp    8010775c <alltraps>

80107e67 <vector15>:
.globl vector15
vector15:
  pushl $0
80107e67:	6a 00                	push   $0x0
  pushl $15
80107e69:	6a 0f                	push   $0xf
  jmp alltraps
80107e6b:	e9 ec f8 ff ff       	jmp    8010775c <alltraps>

80107e70 <vector16>:
.globl vector16
vector16:
  pushl $0
80107e70:	6a 00                	push   $0x0
  pushl $16
80107e72:	6a 10                	push   $0x10
  jmp alltraps
80107e74:	e9 e3 f8 ff ff       	jmp    8010775c <alltraps>

80107e79 <vector17>:
.globl vector17
vector17:
  pushl $17
80107e79:	6a 11                	push   $0x11
  jmp alltraps
80107e7b:	e9 dc f8 ff ff       	jmp    8010775c <alltraps>

80107e80 <vector18>:
.globl vector18
vector18:
  pushl $0
80107e80:	6a 00                	push   $0x0
  pushl $18
80107e82:	6a 12                	push   $0x12
  jmp alltraps
80107e84:	e9 d3 f8 ff ff       	jmp    8010775c <alltraps>

80107e89 <vector19>:
.globl vector19
vector19:
  pushl $0
80107e89:	6a 00                	push   $0x0
  pushl $19
80107e8b:	6a 13                	push   $0x13
  jmp alltraps
80107e8d:	e9 ca f8 ff ff       	jmp    8010775c <alltraps>

80107e92 <vector20>:
.globl vector20
vector20:
  pushl $0
80107e92:	6a 00                	push   $0x0
  pushl $20
80107e94:	6a 14                	push   $0x14
  jmp alltraps
80107e96:	e9 c1 f8 ff ff       	jmp    8010775c <alltraps>

80107e9b <vector21>:
.globl vector21
vector21:
  pushl $0
80107e9b:	6a 00                	push   $0x0
  pushl $21
80107e9d:	6a 15                	push   $0x15
  jmp alltraps
80107e9f:	e9 b8 f8 ff ff       	jmp    8010775c <alltraps>

80107ea4 <vector22>:
.globl vector22
vector22:
  pushl $0
80107ea4:	6a 00                	push   $0x0
  pushl $22
80107ea6:	6a 16                	push   $0x16
  jmp alltraps
80107ea8:	e9 af f8 ff ff       	jmp    8010775c <alltraps>

80107ead <vector23>:
.globl vector23
vector23:
  pushl $0
80107ead:	6a 00                	push   $0x0
  pushl $23
80107eaf:	6a 17                	push   $0x17
  jmp alltraps
80107eb1:	e9 a6 f8 ff ff       	jmp    8010775c <alltraps>

80107eb6 <vector24>:
.globl vector24
vector24:
  pushl $0
80107eb6:	6a 00                	push   $0x0
  pushl $24
80107eb8:	6a 18                	push   $0x18
  jmp alltraps
80107eba:	e9 9d f8 ff ff       	jmp    8010775c <alltraps>

80107ebf <vector25>:
.globl vector25
vector25:
  pushl $0
80107ebf:	6a 00                	push   $0x0
  pushl $25
80107ec1:	6a 19                	push   $0x19
  jmp alltraps
80107ec3:	e9 94 f8 ff ff       	jmp    8010775c <alltraps>

80107ec8 <vector26>:
.globl vector26
vector26:
  pushl $0
80107ec8:	6a 00                	push   $0x0
  pushl $26
80107eca:	6a 1a                	push   $0x1a
  jmp alltraps
80107ecc:	e9 8b f8 ff ff       	jmp    8010775c <alltraps>

80107ed1 <vector27>:
.globl vector27
vector27:
  pushl $0
80107ed1:	6a 00                	push   $0x0
  pushl $27
80107ed3:	6a 1b                	push   $0x1b
  jmp alltraps
80107ed5:	e9 82 f8 ff ff       	jmp    8010775c <alltraps>

80107eda <vector28>:
.globl vector28
vector28:
  pushl $0
80107eda:	6a 00                	push   $0x0
  pushl $28
80107edc:	6a 1c                	push   $0x1c
  jmp alltraps
80107ede:	e9 79 f8 ff ff       	jmp    8010775c <alltraps>

80107ee3 <vector29>:
.globl vector29
vector29:
  pushl $0
80107ee3:	6a 00                	push   $0x0
  pushl $29
80107ee5:	6a 1d                	push   $0x1d
  jmp alltraps
80107ee7:	e9 70 f8 ff ff       	jmp    8010775c <alltraps>

80107eec <vector30>:
.globl vector30
vector30:
  pushl $0
80107eec:	6a 00                	push   $0x0
  pushl $30
80107eee:	6a 1e                	push   $0x1e
  jmp alltraps
80107ef0:	e9 67 f8 ff ff       	jmp    8010775c <alltraps>

80107ef5 <vector31>:
.globl vector31
vector31:
  pushl $0
80107ef5:	6a 00                	push   $0x0
  pushl $31
80107ef7:	6a 1f                	push   $0x1f
  jmp alltraps
80107ef9:	e9 5e f8 ff ff       	jmp    8010775c <alltraps>

80107efe <vector32>:
.globl vector32
vector32:
  pushl $0
80107efe:	6a 00                	push   $0x0
  pushl $32
80107f00:	6a 20                	push   $0x20
  jmp alltraps
80107f02:	e9 55 f8 ff ff       	jmp    8010775c <alltraps>

80107f07 <vector33>:
.globl vector33
vector33:
  pushl $0
80107f07:	6a 00                	push   $0x0
  pushl $33
80107f09:	6a 21                	push   $0x21
  jmp alltraps
80107f0b:	e9 4c f8 ff ff       	jmp    8010775c <alltraps>

80107f10 <vector34>:
.globl vector34
vector34:
  pushl $0
80107f10:	6a 00                	push   $0x0
  pushl $34
80107f12:	6a 22                	push   $0x22
  jmp alltraps
80107f14:	e9 43 f8 ff ff       	jmp    8010775c <alltraps>

80107f19 <vector35>:
.globl vector35
vector35:
  pushl $0
80107f19:	6a 00                	push   $0x0
  pushl $35
80107f1b:	6a 23                	push   $0x23
  jmp alltraps
80107f1d:	e9 3a f8 ff ff       	jmp    8010775c <alltraps>

80107f22 <vector36>:
.globl vector36
vector36:
  pushl $0
80107f22:	6a 00                	push   $0x0
  pushl $36
80107f24:	6a 24                	push   $0x24
  jmp alltraps
80107f26:	e9 31 f8 ff ff       	jmp    8010775c <alltraps>

80107f2b <vector37>:
.globl vector37
vector37:
  pushl $0
80107f2b:	6a 00                	push   $0x0
  pushl $37
80107f2d:	6a 25                	push   $0x25
  jmp alltraps
80107f2f:	e9 28 f8 ff ff       	jmp    8010775c <alltraps>

80107f34 <vector38>:
.globl vector38
vector38:
  pushl $0
80107f34:	6a 00                	push   $0x0
  pushl $38
80107f36:	6a 26                	push   $0x26
  jmp alltraps
80107f38:	e9 1f f8 ff ff       	jmp    8010775c <alltraps>

80107f3d <vector39>:
.globl vector39
vector39:
  pushl $0
80107f3d:	6a 00                	push   $0x0
  pushl $39
80107f3f:	6a 27                	push   $0x27
  jmp alltraps
80107f41:	e9 16 f8 ff ff       	jmp    8010775c <alltraps>

80107f46 <vector40>:
.globl vector40
vector40:
  pushl $0
80107f46:	6a 00                	push   $0x0
  pushl $40
80107f48:	6a 28                	push   $0x28
  jmp alltraps
80107f4a:	e9 0d f8 ff ff       	jmp    8010775c <alltraps>

80107f4f <vector41>:
.globl vector41
vector41:
  pushl $0
80107f4f:	6a 00                	push   $0x0
  pushl $41
80107f51:	6a 29                	push   $0x29
  jmp alltraps
80107f53:	e9 04 f8 ff ff       	jmp    8010775c <alltraps>

80107f58 <vector42>:
.globl vector42
vector42:
  pushl $0
80107f58:	6a 00                	push   $0x0
  pushl $42
80107f5a:	6a 2a                	push   $0x2a
  jmp alltraps
80107f5c:	e9 fb f7 ff ff       	jmp    8010775c <alltraps>

80107f61 <vector43>:
.globl vector43
vector43:
  pushl $0
80107f61:	6a 00                	push   $0x0
  pushl $43
80107f63:	6a 2b                	push   $0x2b
  jmp alltraps
80107f65:	e9 f2 f7 ff ff       	jmp    8010775c <alltraps>

80107f6a <vector44>:
.globl vector44
vector44:
  pushl $0
80107f6a:	6a 00                	push   $0x0
  pushl $44
80107f6c:	6a 2c                	push   $0x2c
  jmp alltraps
80107f6e:	e9 e9 f7 ff ff       	jmp    8010775c <alltraps>

80107f73 <vector45>:
.globl vector45
vector45:
  pushl $0
80107f73:	6a 00                	push   $0x0
  pushl $45
80107f75:	6a 2d                	push   $0x2d
  jmp alltraps
80107f77:	e9 e0 f7 ff ff       	jmp    8010775c <alltraps>

80107f7c <vector46>:
.globl vector46
vector46:
  pushl $0
80107f7c:	6a 00                	push   $0x0
  pushl $46
80107f7e:	6a 2e                	push   $0x2e
  jmp alltraps
80107f80:	e9 d7 f7 ff ff       	jmp    8010775c <alltraps>

80107f85 <vector47>:
.globl vector47
vector47:
  pushl $0
80107f85:	6a 00                	push   $0x0
  pushl $47
80107f87:	6a 2f                	push   $0x2f
  jmp alltraps
80107f89:	e9 ce f7 ff ff       	jmp    8010775c <alltraps>

80107f8e <vector48>:
.globl vector48
vector48:
  pushl $0
80107f8e:	6a 00                	push   $0x0
  pushl $48
80107f90:	6a 30                	push   $0x30
  jmp alltraps
80107f92:	e9 c5 f7 ff ff       	jmp    8010775c <alltraps>

80107f97 <vector49>:
.globl vector49
vector49:
  pushl $0
80107f97:	6a 00                	push   $0x0
  pushl $49
80107f99:	6a 31                	push   $0x31
  jmp alltraps
80107f9b:	e9 bc f7 ff ff       	jmp    8010775c <alltraps>

80107fa0 <vector50>:
.globl vector50
vector50:
  pushl $0
80107fa0:	6a 00                	push   $0x0
  pushl $50
80107fa2:	6a 32                	push   $0x32
  jmp alltraps
80107fa4:	e9 b3 f7 ff ff       	jmp    8010775c <alltraps>

80107fa9 <vector51>:
.globl vector51
vector51:
  pushl $0
80107fa9:	6a 00                	push   $0x0
  pushl $51
80107fab:	6a 33                	push   $0x33
  jmp alltraps
80107fad:	e9 aa f7 ff ff       	jmp    8010775c <alltraps>

80107fb2 <vector52>:
.globl vector52
vector52:
  pushl $0
80107fb2:	6a 00                	push   $0x0
  pushl $52
80107fb4:	6a 34                	push   $0x34
  jmp alltraps
80107fb6:	e9 a1 f7 ff ff       	jmp    8010775c <alltraps>

80107fbb <vector53>:
.globl vector53
vector53:
  pushl $0
80107fbb:	6a 00                	push   $0x0
  pushl $53
80107fbd:	6a 35                	push   $0x35
  jmp alltraps
80107fbf:	e9 98 f7 ff ff       	jmp    8010775c <alltraps>

80107fc4 <vector54>:
.globl vector54
vector54:
  pushl $0
80107fc4:	6a 00                	push   $0x0
  pushl $54
80107fc6:	6a 36                	push   $0x36
  jmp alltraps
80107fc8:	e9 8f f7 ff ff       	jmp    8010775c <alltraps>

80107fcd <vector55>:
.globl vector55
vector55:
  pushl $0
80107fcd:	6a 00                	push   $0x0
  pushl $55
80107fcf:	6a 37                	push   $0x37
  jmp alltraps
80107fd1:	e9 86 f7 ff ff       	jmp    8010775c <alltraps>

80107fd6 <vector56>:
.globl vector56
vector56:
  pushl $0
80107fd6:	6a 00                	push   $0x0
  pushl $56
80107fd8:	6a 38                	push   $0x38
  jmp alltraps
80107fda:	e9 7d f7 ff ff       	jmp    8010775c <alltraps>

80107fdf <vector57>:
.globl vector57
vector57:
  pushl $0
80107fdf:	6a 00                	push   $0x0
  pushl $57
80107fe1:	6a 39                	push   $0x39
  jmp alltraps
80107fe3:	e9 74 f7 ff ff       	jmp    8010775c <alltraps>

80107fe8 <vector58>:
.globl vector58
vector58:
  pushl $0
80107fe8:	6a 00                	push   $0x0
  pushl $58
80107fea:	6a 3a                	push   $0x3a
  jmp alltraps
80107fec:	e9 6b f7 ff ff       	jmp    8010775c <alltraps>

80107ff1 <vector59>:
.globl vector59
vector59:
  pushl $0
80107ff1:	6a 00                	push   $0x0
  pushl $59
80107ff3:	6a 3b                	push   $0x3b
  jmp alltraps
80107ff5:	e9 62 f7 ff ff       	jmp    8010775c <alltraps>

80107ffa <vector60>:
.globl vector60
vector60:
  pushl $0
80107ffa:	6a 00                	push   $0x0
  pushl $60
80107ffc:	6a 3c                	push   $0x3c
  jmp alltraps
80107ffe:	e9 59 f7 ff ff       	jmp    8010775c <alltraps>

80108003 <vector61>:
.globl vector61
vector61:
  pushl $0
80108003:	6a 00                	push   $0x0
  pushl $61
80108005:	6a 3d                	push   $0x3d
  jmp alltraps
80108007:	e9 50 f7 ff ff       	jmp    8010775c <alltraps>

8010800c <vector62>:
.globl vector62
vector62:
  pushl $0
8010800c:	6a 00                	push   $0x0
  pushl $62
8010800e:	6a 3e                	push   $0x3e
  jmp alltraps
80108010:	e9 47 f7 ff ff       	jmp    8010775c <alltraps>

80108015 <vector63>:
.globl vector63
vector63:
  pushl $0
80108015:	6a 00                	push   $0x0
  pushl $63
80108017:	6a 3f                	push   $0x3f
  jmp alltraps
80108019:	e9 3e f7 ff ff       	jmp    8010775c <alltraps>

8010801e <vector64>:
.globl vector64
vector64:
  pushl $0
8010801e:	6a 00                	push   $0x0
  pushl $64
80108020:	6a 40                	push   $0x40
  jmp alltraps
80108022:	e9 35 f7 ff ff       	jmp    8010775c <alltraps>

80108027 <vector65>:
.globl vector65
vector65:
  pushl $0
80108027:	6a 00                	push   $0x0
  pushl $65
80108029:	6a 41                	push   $0x41
  jmp alltraps
8010802b:	e9 2c f7 ff ff       	jmp    8010775c <alltraps>

80108030 <vector66>:
.globl vector66
vector66:
  pushl $0
80108030:	6a 00                	push   $0x0
  pushl $66
80108032:	6a 42                	push   $0x42
  jmp alltraps
80108034:	e9 23 f7 ff ff       	jmp    8010775c <alltraps>

80108039 <vector67>:
.globl vector67
vector67:
  pushl $0
80108039:	6a 00                	push   $0x0
  pushl $67
8010803b:	6a 43                	push   $0x43
  jmp alltraps
8010803d:	e9 1a f7 ff ff       	jmp    8010775c <alltraps>

80108042 <vector68>:
.globl vector68
vector68:
  pushl $0
80108042:	6a 00                	push   $0x0
  pushl $68
80108044:	6a 44                	push   $0x44
  jmp alltraps
80108046:	e9 11 f7 ff ff       	jmp    8010775c <alltraps>

8010804b <vector69>:
.globl vector69
vector69:
  pushl $0
8010804b:	6a 00                	push   $0x0
  pushl $69
8010804d:	6a 45                	push   $0x45
  jmp alltraps
8010804f:	e9 08 f7 ff ff       	jmp    8010775c <alltraps>

80108054 <vector70>:
.globl vector70
vector70:
  pushl $0
80108054:	6a 00                	push   $0x0
  pushl $70
80108056:	6a 46                	push   $0x46
  jmp alltraps
80108058:	e9 ff f6 ff ff       	jmp    8010775c <alltraps>

8010805d <vector71>:
.globl vector71
vector71:
  pushl $0
8010805d:	6a 00                	push   $0x0
  pushl $71
8010805f:	6a 47                	push   $0x47
  jmp alltraps
80108061:	e9 f6 f6 ff ff       	jmp    8010775c <alltraps>

80108066 <vector72>:
.globl vector72
vector72:
  pushl $0
80108066:	6a 00                	push   $0x0
  pushl $72
80108068:	6a 48                	push   $0x48
  jmp alltraps
8010806a:	e9 ed f6 ff ff       	jmp    8010775c <alltraps>

8010806f <vector73>:
.globl vector73
vector73:
  pushl $0
8010806f:	6a 00                	push   $0x0
  pushl $73
80108071:	6a 49                	push   $0x49
  jmp alltraps
80108073:	e9 e4 f6 ff ff       	jmp    8010775c <alltraps>

80108078 <vector74>:
.globl vector74
vector74:
  pushl $0
80108078:	6a 00                	push   $0x0
  pushl $74
8010807a:	6a 4a                	push   $0x4a
  jmp alltraps
8010807c:	e9 db f6 ff ff       	jmp    8010775c <alltraps>

80108081 <vector75>:
.globl vector75
vector75:
  pushl $0
80108081:	6a 00                	push   $0x0
  pushl $75
80108083:	6a 4b                	push   $0x4b
  jmp alltraps
80108085:	e9 d2 f6 ff ff       	jmp    8010775c <alltraps>

8010808a <vector76>:
.globl vector76
vector76:
  pushl $0
8010808a:	6a 00                	push   $0x0
  pushl $76
8010808c:	6a 4c                	push   $0x4c
  jmp alltraps
8010808e:	e9 c9 f6 ff ff       	jmp    8010775c <alltraps>

80108093 <vector77>:
.globl vector77
vector77:
  pushl $0
80108093:	6a 00                	push   $0x0
  pushl $77
80108095:	6a 4d                	push   $0x4d
  jmp alltraps
80108097:	e9 c0 f6 ff ff       	jmp    8010775c <alltraps>

8010809c <vector78>:
.globl vector78
vector78:
  pushl $0
8010809c:	6a 00                	push   $0x0
  pushl $78
8010809e:	6a 4e                	push   $0x4e
  jmp alltraps
801080a0:	e9 b7 f6 ff ff       	jmp    8010775c <alltraps>

801080a5 <vector79>:
.globl vector79
vector79:
  pushl $0
801080a5:	6a 00                	push   $0x0
  pushl $79
801080a7:	6a 4f                	push   $0x4f
  jmp alltraps
801080a9:	e9 ae f6 ff ff       	jmp    8010775c <alltraps>

801080ae <vector80>:
.globl vector80
vector80:
  pushl $0
801080ae:	6a 00                	push   $0x0
  pushl $80
801080b0:	6a 50                	push   $0x50
  jmp alltraps
801080b2:	e9 a5 f6 ff ff       	jmp    8010775c <alltraps>

801080b7 <vector81>:
.globl vector81
vector81:
  pushl $0
801080b7:	6a 00                	push   $0x0
  pushl $81
801080b9:	6a 51                	push   $0x51
  jmp alltraps
801080bb:	e9 9c f6 ff ff       	jmp    8010775c <alltraps>

801080c0 <vector82>:
.globl vector82
vector82:
  pushl $0
801080c0:	6a 00                	push   $0x0
  pushl $82
801080c2:	6a 52                	push   $0x52
  jmp alltraps
801080c4:	e9 93 f6 ff ff       	jmp    8010775c <alltraps>

801080c9 <vector83>:
.globl vector83
vector83:
  pushl $0
801080c9:	6a 00                	push   $0x0
  pushl $83
801080cb:	6a 53                	push   $0x53
  jmp alltraps
801080cd:	e9 8a f6 ff ff       	jmp    8010775c <alltraps>

801080d2 <vector84>:
.globl vector84
vector84:
  pushl $0
801080d2:	6a 00                	push   $0x0
  pushl $84
801080d4:	6a 54                	push   $0x54
  jmp alltraps
801080d6:	e9 81 f6 ff ff       	jmp    8010775c <alltraps>

801080db <vector85>:
.globl vector85
vector85:
  pushl $0
801080db:	6a 00                	push   $0x0
  pushl $85
801080dd:	6a 55                	push   $0x55
  jmp alltraps
801080df:	e9 78 f6 ff ff       	jmp    8010775c <alltraps>

801080e4 <vector86>:
.globl vector86
vector86:
  pushl $0
801080e4:	6a 00                	push   $0x0
  pushl $86
801080e6:	6a 56                	push   $0x56
  jmp alltraps
801080e8:	e9 6f f6 ff ff       	jmp    8010775c <alltraps>

801080ed <vector87>:
.globl vector87
vector87:
  pushl $0
801080ed:	6a 00                	push   $0x0
  pushl $87
801080ef:	6a 57                	push   $0x57
  jmp alltraps
801080f1:	e9 66 f6 ff ff       	jmp    8010775c <alltraps>

801080f6 <vector88>:
.globl vector88
vector88:
  pushl $0
801080f6:	6a 00                	push   $0x0
  pushl $88
801080f8:	6a 58                	push   $0x58
  jmp alltraps
801080fa:	e9 5d f6 ff ff       	jmp    8010775c <alltraps>

801080ff <vector89>:
.globl vector89
vector89:
  pushl $0
801080ff:	6a 00                	push   $0x0
  pushl $89
80108101:	6a 59                	push   $0x59
  jmp alltraps
80108103:	e9 54 f6 ff ff       	jmp    8010775c <alltraps>

80108108 <vector90>:
.globl vector90
vector90:
  pushl $0
80108108:	6a 00                	push   $0x0
  pushl $90
8010810a:	6a 5a                	push   $0x5a
  jmp alltraps
8010810c:	e9 4b f6 ff ff       	jmp    8010775c <alltraps>

80108111 <vector91>:
.globl vector91
vector91:
  pushl $0
80108111:	6a 00                	push   $0x0
  pushl $91
80108113:	6a 5b                	push   $0x5b
  jmp alltraps
80108115:	e9 42 f6 ff ff       	jmp    8010775c <alltraps>

8010811a <vector92>:
.globl vector92
vector92:
  pushl $0
8010811a:	6a 00                	push   $0x0
  pushl $92
8010811c:	6a 5c                	push   $0x5c
  jmp alltraps
8010811e:	e9 39 f6 ff ff       	jmp    8010775c <alltraps>

80108123 <vector93>:
.globl vector93
vector93:
  pushl $0
80108123:	6a 00                	push   $0x0
  pushl $93
80108125:	6a 5d                	push   $0x5d
  jmp alltraps
80108127:	e9 30 f6 ff ff       	jmp    8010775c <alltraps>

8010812c <vector94>:
.globl vector94
vector94:
  pushl $0
8010812c:	6a 00                	push   $0x0
  pushl $94
8010812e:	6a 5e                	push   $0x5e
  jmp alltraps
80108130:	e9 27 f6 ff ff       	jmp    8010775c <alltraps>

80108135 <vector95>:
.globl vector95
vector95:
  pushl $0
80108135:	6a 00                	push   $0x0
  pushl $95
80108137:	6a 5f                	push   $0x5f
  jmp alltraps
80108139:	e9 1e f6 ff ff       	jmp    8010775c <alltraps>

8010813e <vector96>:
.globl vector96
vector96:
  pushl $0
8010813e:	6a 00                	push   $0x0
  pushl $96
80108140:	6a 60                	push   $0x60
  jmp alltraps
80108142:	e9 15 f6 ff ff       	jmp    8010775c <alltraps>

80108147 <vector97>:
.globl vector97
vector97:
  pushl $0
80108147:	6a 00                	push   $0x0
  pushl $97
80108149:	6a 61                	push   $0x61
  jmp alltraps
8010814b:	e9 0c f6 ff ff       	jmp    8010775c <alltraps>

80108150 <vector98>:
.globl vector98
vector98:
  pushl $0
80108150:	6a 00                	push   $0x0
  pushl $98
80108152:	6a 62                	push   $0x62
  jmp alltraps
80108154:	e9 03 f6 ff ff       	jmp    8010775c <alltraps>

80108159 <vector99>:
.globl vector99
vector99:
  pushl $0
80108159:	6a 00                	push   $0x0
  pushl $99
8010815b:	6a 63                	push   $0x63
  jmp alltraps
8010815d:	e9 fa f5 ff ff       	jmp    8010775c <alltraps>

80108162 <vector100>:
.globl vector100
vector100:
  pushl $0
80108162:	6a 00                	push   $0x0
  pushl $100
80108164:	6a 64                	push   $0x64
  jmp alltraps
80108166:	e9 f1 f5 ff ff       	jmp    8010775c <alltraps>

8010816b <vector101>:
.globl vector101
vector101:
  pushl $0
8010816b:	6a 00                	push   $0x0
  pushl $101
8010816d:	6a 65                	push   $0x65
  jmp alltraps
8010816f:	e9 e8 f5 ff ff       	jmp    8010775c <alltraps>

80108174 <vector102>:
.globl vector102
vector102:
  pushl $0
80108174:	6a 00                	push   $0x0
  pushl $102
80108176:	6a 66                	push   $0x66
  jmp alltraps
80108178:	e9 df f5 ff ff       	jmp    8010775c <alltraps>

8010817d <vector103>:
.globl vector103
vector103:
  pushl $0
8010817d:	6a 00                	push   $0x0
  pushl $103
8010817f:	6a 67                	push   $0x67
  jmp alltraps
80108181:	e9 d6 f5 ff ff       	jmp    8010775c <alltraps>

80108186 <vector104>:
.globl vector104
vector104:
  pushl $0
80108186:	6a 00                	push   $0x0
  pushl $104
80108188:	6a 68                	push   $0x68
  jmp alltraps
8010818a:	e9 cd f5 ff ff       	jmp    8010775c <alltraps>

8010818f <vector105>:
.globl vector105
vector105:
  pushl $0
8010818f:	6a 00                	push   $0x0
  pushl $105
80108191:	6a 69                	push   $0x69
  jmp alltraps
80108193:	e9 c4 f5 ff ff       	jmp    8010775c <alltraps>

80108198 <vector106>:
.globl vector106
vector106:
  pushl $0
80108198:	6a 00                	push   $0x0
  pushl $106
8010819a:	6a 6a                	push   $0x6a
  jmp alltraps
8010819c:	e9 bb f5 ff ff       	jmp    8010775c <alltraps>

801081a1 <vector107>:
.globl vector107
vector107:
  pushl $0
801081a1:	6a 00                	push   $0x0
  pushl $107
801081a3:	6a 6b                	push   $0x6b
  jmp alltraps
801081a5:	e9 b2 f5 ff ff       	jmp    8010775c <alltraps>

801081aa <vector108>:
.globl vector108
vector108:
  pushl $0
801081aa:	6a 00                	push   $0x0
  pushl $108
801081ac:	6a 6c                	push   $0x6c
  jmp alltraps
801081ae:	e9 a9 f5 ff ff       	jmp    8010775c <alltraps>

801081b3 <vector109>:
.globl vector109
vector109:
  pushl $0
801081b3:	6a 00                	push   $0x0
  pushl $109
801081b5:	6a 6d                	push   $0x6d
  jmp alltraps
801081b7:	e9 a0 f5 ff ff       	jmp    8010775c <alltraps>

801081bc <vector110>:
.globl vector110
vector110:
  pushl $0
801081bc:	6a 00                	push   $0x0
  pushl $110
801081be:	6a 6e                	push   $0x6e
  jmp alltraps
801081c0:	e9 97 f5 ff ff       	jmp    8010775c <alltraps>

801081c5 <vector111>:
.globl vector111
vector111:
  pushl $0
801081c5:	6a 00                	push   $0x0
  pushl $111
801081c7:	6a 6f                	push   $0x6f
  jmp alltraps
801081c9:	e9 8e f5 ff ff       	jmp    8010775c <alltraps>

801081ce <vector112>:
.globl vector112
vector112:
  pushl $0
801081ce:	6a 00                	push   $0x0
  pushl $112
801081d0:	6a 70                	push   $0x70
  jmp alltraps
801081d2:	e9 85 f5 ff ff       	jmp    8010775c <alltraps>

801081d7 <vector113>:
.globl vector113
vector113:
  pushl $0
801081d7:	6a 00                	push   $0x0
  pushl $113
801081d9:	6a 71                	push   $0x71
  jmp alltraps
801081db:	e9 7c f5 ff ff       	jmp    8010775c <alltraps>

801081e0 <vector114>:
.globl vector114
vector114:
  pushl $0
801081e0:	6a 00                	push   $0x0
  pushl $114
801081e2:	6a 72                	push   $0x72
  jmp alltraps
801081e4:	e9 73 f5 ff ff       	jmp    8010775c <alltraps>

801081e9 <vector115>:
.globl vector115
vector115:
  pushl $0
801081e9:	6a 00                	push   $0x0
  pushl $115
801081eb:	6a 73                	push   $0x73
  jmp alltraps
801081ed:	e9 6a f5 ff ff       	jmp    8010775c <alltraps>

801081f2 <vector116>:
.globl vector116
vector116:
  pushl $0
801081f2:	6a 00                	push   $0x0
  pushl $116
801081f4:	6a 74                	push   $0x74
  jmp alltraps
801081f6:	e9 61 f5 ff ff       	jmp    8010775c <alltraps>

801081fb <vector117>:
.globl vector117
vector117:
  pushl $0
801081fb:	6a 00                	push   $0x0
  pushl $117
801081fd:	6a 75                	push   $0x75
  jmp alltraps
801081ff:	e9 58 f5 ff ff       	jmp    8010775c <alltraps>

80108204 <vector118>:
.globl vector118
vector118:
  pushl $0
80108204:	6a 00                	push   $0x0
  pushl $118
80108206:	6a 76                	push   $0x76
  jmp alltraps
80108208:	e9 4f f5 ff ff       	jmp    8010775c <alltraps>

8010820d <vector119>:
.globl vector119
vector119:
  pushl $0
8010820d:	6a 00                	push   $0x0
  pushl $119
8010820f:	6a 77                	push   $0x77
  jmp alltraps
80108211:	e9 46 f5 ff ff       	jmp    8010775c <alltraps>

80108216 <vector120>:
.globl vector120
vector120:
  pushl $0
80108216:	6a 00                	push   $0x0
  pushl $120
80108218:	6a 78                	push   $0x78
  jmp alltraps
8010821a:	e9 3d f5 ff ff       	jmp    8010775c <alltraps>

8010821f <vector121>:
.globl vector121
vector121:
  pushl $0
8010821f:	6a 00                	push   $0x0
  pushl $121
80108221:	6a 79                	push   $0x79
  jmp alltraps
80108223:	e9 34 f5 ff ff       	jmp    8010775c <alltraps>

80108228 <vector122>:
.globl vector122
vector122:
  pushl $0
80108228:	6a 00                	push   $0x0
  pushl $122
8010822a:	6a 7a                	push   $0x7a
  jmp alltraps
8010822c:	e9 2b f5 ff ff       	jmp    8010775c <alltraps>

80108231 <vector123>:
.globl vector123
vector123:
  pushl $0
80108231:	6a 00                	push   $0x0
  pushl $123
80108233:	6a 7b                	push   $0x7b
  jmp alltraps
80108235:	e9 22 f5 ff ff       	jmp    8010775c <alltraps>

8010823a <vector124>:
.globl vector124
vector124:
  pushl $0
8010823a:	6a 00                	push   $0x0
  pushl $124
8010823c:	6a 7c                	push   $0x7c
  jmp alltraps
8010823e:	e9 19 f5 ff ff       	jmp    8010775c <alltraps>

80108243 <vector125>:
.globl vector125
vector125:
  pushl $0
80108243:	6a 00                	push   $0x0
  pushl $125
80108245:	6a 7d                	push   $0x7d
  jmp alltraps
80108247:	e9 10 f5 ff ff       	jmp    8010775c <alltraps>

8010824c <vector126>:
.globl vector126
vector126:
  pushl $0
8010824c:	6a 00                	push   $0x0
  pushl $126
8010824e:	6a 7e                	push   $0x7e
  jmp alltraps
80108250:	e9 07 f5 ff ff       	jmp    8010775c <alltraps>

80108255 <vector127>:
.globl vector127
vector127:
  pushl $0
80108255:	6a 00                	push   $0x0
  pushl $127
80108257:	6a 7f                	push   $0x7f
  jmp alltraps
80108259:	e9 fe f4 ff ff       	jmp    8010775c <alltraps>

8010825e <vector128>:
.globl vector128
vector128:
  pushl $0
8010825e:	6a 00                	push   $0x0
  pushl $128
80108260:	68 80 00 00 00       	push   $0x80
  jmp alltraps
80108265:	e9 f2 f4 ff ff       	jmp    8010775c <alltraps>

8010826a <vector129>:
.globl vector129
vector129:
  pushl $0
8010826a:	6a 00                	push   $0x0
  pushl $129
8010826c:	68 81 00 00 00       	push   $0x81
  jmp alltraps
80108271:	e9 e6 f4 ff ff       	jmp    8010775c <alltraps>

80108276 <vector130>:
.globl vector130
vector130:
  pushl $0
80108276:	6a 00                	push   $0x0
  pushl $130
80108278:	68 82 00 00 00       	push   $0x82
  jmp alltraps
8010827d:	e9 da f4 ff ff       	jmp    8010775c <alltraps>

80108282 <vector131>:
.globl vector131
vector131:
  pushl $0
80108282:	6a 00                	push   $0x0
  pushl $131
80108284:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80108289:	e9 ce f4 ff ff       	jmp    8010775c <alltraps>

8010828e <vector132>:
.globl vector132
vector132:
  pushl $0
8010828e:	6a 00                	push   $0x0
  pushl $132
80108290:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80108295:	e9 c2 f4 ff ff       	jmp    8010775c <alltraps>

8010829a <vector133>:
.globl vector133
vector133:
  pushl $0
8010829a:	6a 00                	push   $0x0
  pushl $133
8010829c:	68 85 00 00 00       	push   $0x85
  jmp alltraps
801082a1:	e9 b6 f4 ff ff       	jmp    8010775c <alltraps>

801082a6 <vector134>:
.globl vector134
vector134:
  pushl $0
801082a6:	6a 00                	push   $0x0
  pushl $134
801082a8:	68 86 00 00 00       	push   $0x86
  jmp alltraps
801082ad:	e9 aa f4 ff ff       	jmp    8010775c <alltraps>

801082b2 <vector135>:
.globl vector135
vector135:
  pushl $0
801082b2:	6a 00                	push   $0x0
  pushl $135
801082b4:	68 87 00 00 00       	push   $0x87
  jmp alltraps
801082b9:	e9 9e f4 ff ff       	jmp    8010775c <alltraps>

801082be <vector136>:
.globl vector136
vector136:
  pushl $0
801082be:	6a 00                	push   $0x0
  pushl $136
801082c0:	68 88 00 00 00       	push   $0x88
  jmp alltraps
801082c5:	e9 92 f4 ff ff       	jmp    8010775c <alltraps>

801082ca <vector137>:
.globl vector137
vector137:
  pushl $0
801082ca:	6a 00                	push   $0x0
  pushl $137
801082cc:	68 89 00 00 00       	push   $0x89
  jmp alltraps
801082d1:	e9 86 f4 ff ff       	jmp    8010775c <alltraps>

801082d6 <vector138>:
.globl vector138
vector138:
  pushl $0
801082d6:	6a 00                	push   $0x0
  pushl $138
801082d8:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
801082dd:	e9 7a f4 ff ff       	jmp    8010775c <alltraps>

801082e2 <vector139>:
.globl vector139
vector139:
  pushl $0
801082e2:	6a 00                	push   $0x0
  pushl $139
801082e4:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
801082e9:	e9 6e f4 ff ff       	jmp    8010775c <alltraps>

801082ee <vector140>:
.globl vector140
vector140:
  pushl $0
801082ee:	6a 00                	push   $0x0
  pushl $140
801082f0:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
801082f5:	e9 62 f4 ff ff       	jmp    8010775c <alltraps>

801082fa <vector141>:
.globl vector141
vector141:
  pushl $0
801082fa:	6a 00                	push   $0x0
  pushl $141
801082fc:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80108301:	e9 56 f4 ff ff       	jmp    8010775c <alltraps>

80108306 <vector142>:
.globl vector142
vector142:
  pushl $0
80108306:	6a 00                	push   $0x0
  pushl $142
80108308:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
8010830d:	e9 4a f4 ff ff       	jmp    8010775c <alltraps>

80108312 <vector143>:
.globl vector143
vector143:
  pushl $0
80108312:	6a 00                	push   $0x0
  pushl $143
80108314:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80108319:	e9 3e f4 ff ff       	jmp    8010775c <alltraps>

8010831e <vector144>:
.globl vector144
vector144:
  pushl $0
8010831e:	6a 00                	push   $0x0
  pushl $144
80108320:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80108325:	e9 32 f4 ff ff       	jmp    8010775c <alltraps>

8010832a <vector145>:
.globl vector145
vector145:
  pushl $0
8010832a:	6a 00                	push   $0x0
  pushl $145
8010832c:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80108331:	e9 26 f4 ff ff       	jmp    8010775c <alltraps>

80108336 <vector146>:
.globl vector146
vector146:
  pushl $0
80108336:	6a 00                	push   $0x0
  pushl $146
80108338:	68 92 00 00 00       	push   $0x92
  jmp alltraps
8010833d:	e9 1a f4 ff ff       	jmp    8010775c <alltraps>

80108342 <vector147>:
.globl vector147
vector147:
  pushl $0
80108342:	6a 00                	push   $0x0
  pushl $147
80108344:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80108349:	e9 0e f4 ff ff       	jmp    8010775c <alltraps>

8010834e <vector148>:
.globl vector148
vector148:
  pushl $0
8010834e:	6a 00                	push   $0x0
  pushl $148
80108350:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80108355:	e9 02 f4 ff ff       	jmp    8010775c <alltraps>

8010835a <vector149>:
.globl vector149
vector149:
  pushl $0
8010835a:	6a 00                	push   $0x0
  pushl $149
8010835c:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80108361:	e9 f6 f3 ff ff       	jmp    8010775c <alltraps>

80108366 <vector150>:
.globl vector150
vector150:
  pushl $0
80108366:	6a 00                	push   $0x0
  pushl $150
80108368:	68 96 00 00 00       	push   $0x96
  jmp alltraps
8010836d:	e9 ea f3 ff ff       	jmp    8010775c <alltraps>

80108372 <vector151>:
.globl vector151
vector151:
  pushl $0
80108372:	6a 00                	push   $0x0
  pushl $151
80108374:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80108379:	e9 de f3 ff ff       	jmp    8010775c <alltraps>

8010837e <vector152>:
.globl vector152
vector152:
  pushl $0
8010837e:	6a 00                	push   $0x0
  pushl $152
80108380:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80108385:	e9 d2 f3 ff ff       	jmp    8010775c <alltraps>

8010838a <vector153>:
.globl vector153
vector153:
  pushl $0
8010838a:	6a 00                	push   $0x0
  pushl $153
8010838c:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80108391:	e9 c6 f3 ff ff       	jmp    8010775c <alltraps>

80108396 <vector154>:
.globl vector154
vector154:
  pushl $0
80108396:	6a 00                	push   $0x0
  pushl $154
80108398:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
8010839d:	e9 ba f3 ff ff       	jmp    8010775c <alltraps>

801083a2 <vector155>:
.globl vector155
vector155:
  pushl $0
801083a2:	6a 00                	push   $0x0
  pushl $155
801083a4:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
801083a9:	e9 ae f3 ff ff       	jmp    8010775c <alltraps>

801083ae <vector156>:
.globl vector156
vector156:
  pushl $0
801083ae:	6a 00                	push   $0x0
  pushl $156
801083b0:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
801083b5:	e9 a2 f3 ff ff       	jmp    8010775c <alltraps>

801083ba <vector157>:
.globl vector157
vector157:
  pushl $0
801083ba:	6a 00                	push   $0x0
  pushl $157
801083bc:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
801083c1:	e9 96 f3 ff ff       	jmp    8010775c <alltraps>

801083c6 <vector158>:
.globl vector158
vector158:
  pushl $0
801083c6:	6a 00                	push   $0x0
  pushl $158
801083c8:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
801083cd:	e9 8a f3 ff ff       	jmp    8010775c <alltraps>

801083d2 <vector159>:
.globl vector159
vector159:
  pushl $0
801083d2:	6a 00                	push   $0x0
  pushl $159
801083d4:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
801083d9:	e9 7e f3 ff ff       	jmp    8010775c <alltraps>

801083de <vector160>:
.globl vector160
vector160:
  pushl $0
801083de:	6a 00                	push   $0x0
  pushl $160
801083e0:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
801083e5:	e9 72 f3 ff ff       	jmp    8010775c <alltraps>

801083ea <vector161>:
.globl vector161
vector161:
  pushl $0
801083ea:	6a 00                	push   $0x0
  pushl $161
801083ec:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
801083f1:	e9 66 f3 ff ff       	jmp    8010775c <alltraps>

801083f6 <vector162>:
.globl vector162
vector162:
  pushl $0
801083f6:	6a 00                	push   $0x0
  pushl $162
801083f8:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
801083fd:	e9 5a f3 ff ff       	jmp    8010775c <alltraps>

80108402 <vector163>:
.globl vector163
vector163:
  pushl $0
80108402:	6a 00                	push   $0x0
  pushl $163
80108404:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80108409:	e9 4e f3 ff ff       	jmp    8010775c <alltraps>

8010840e <vector164>:
.globl vector164
vector164:
  pushl $0
8010840e:	6a 00                	push   $0x0
  pushl $164
80108410:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80108415:	e9 42 f3 ff ff       	jmp    8010775c <alltraps>

8010841a <vector165>:
.globl vector165
vector165:
  pushl $0
8010841a:	6a 00                	push   $0x0
  pushl $165
8010841c:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80108421:	e9 36 f3 ff ff       	jmp    8010775c <alltraps>

80108426 <vector166>:
.globl vector166
vector166:
  pushl $0
80108426:	6a 00                	push   $0x0
  pushl $166
80108428:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
8010842d:	e9 2a f3 ff ff       	jmp    8010775c <alltraps>

80108432 <vector167>:
.globl vector167
vector167:
  pushl $0
80108432:	6a 00                	push   $0x0
  pushl $167
80108434:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80108439:	e9 1e f3 ff ff       	jmp    8010775c <alltraps>

8010843e <vector168>:
.globl vector168
vector168:
  pushl $0
8010843e:	6a 00                	push   $0x0
  pushl $168
80108440:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80108445:	e9 12 f3 ff ff       	jmp    8010775c <alltraps>

8010844a <vector169>:
.globl vector169
vector169:
  pushl $0
8010844a:	6a 00                	push   $0x0
  pushl $169
8010844c:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80108451:	e9 06 f3 ff ff       	jmp    8010775c <alltraps>

80108456 <vector170>:
.globl vector170
vector170:
  pushl $0
80108456:	6a 00                	push   $0x0
  pushl $170
80108458:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
8010845d:	e9 fa f2 ff ff       	jmp    8010775c <alltraps>

80108462 <vector171>:
.globl vector171
vector171:
  pushl $0
80108462:	6a 00                	push   $0x0
  pushl $171
80108464:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80108469:	e9 ee f2 ff ff       	jmp    8010775c <alltraps>

8010846e <vector172>:
.globl vector172
vector172:
  pushl $0
8010846e:	6a 00                	push   $0x0
  pushl $172
80108470:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80108475:	e9 e2 f2 ff ff       	jmp    8010775c <alltraps>

8010847a <vector173>:
.globl vector173
vector173:
  pushl $0
8010847a:	6a 00                	push   $0x0
  pushl $173
8010847c:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80108481:	e9 d6 f2 ff ff       	jmp    8010775c <alltraps>

80108486 <vector174>:
.globl vector174
vector174:
  pushl $0
80108486:	6a 00                	push   $0x0
  pushl $174
80108488:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
8010848d:	e9 ca f2 ff ff       	jmp    8010775c <alltraps>

80108492 <vector175>:
.globl vector175
vector175:
  pushl $0
80108492:	6a 00                	push   $0x0
  pushl $175
80108494:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80108499:	e9 be f2 ff ff       	jmp    8010775c <alltraps>

8010849e <vector176>:
.globl vector176
vector176:
  pushl $0
8010849e:	6a 00                	push   $0x0
  pushl $176
801084a0:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
801084a5:	e9 b2 f2 ff ff       	jmp    8010775c <alltraps>

801084aa <vector177>:
.globl vector177
vector177:
  pushl $0
801084aa:	6a 00                	push   $0x0
  pushl $177
801084ac:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
801084b1:	e9 a6 f2 ff ff       	jmp    8010775c <alltraps>

801084b6 <vector178>:
.globl vector178
vector178:
  pushl $0
801084b6:	6a 00                	push   $0x0
  pushl $178
801084b8:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
801084bd:	e9 9a f2 ff ff       	jmp    8010775c <alltraps>

801084c2 <vector179>:
.globl vector179
vector179:
  pushl $0
801084c2:	6a 00                	push   $0x0
  pushl $179
801084c4:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
801084c9:	e9 8e f2 ff ff       	jmp    8010775c <alltraps>

801084ce <vector180>:
.globl vector180
vector180:
  pushl $0
801084ce:	6a 00                	push   $0x0
  pushl $180
801084d0:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
801084d5:	e9 82 f2 ff ff       	jmp    8010775c <alltraps>

801084da <vector181>:
.globl vector181
vector181:
  pushl $0
801084da:	6a 00                	push   $0x0
  pushl $181
801084dc:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
801084e1:	e9 76 f2 ff ff       	jmp    8010775c <alltraps>

801084e6 <vector182>:
.globl vector182
vector182:
  pushl $0
801084e6:	6a 00                	push   $0x0
  pushl $182
801084e8:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
801084ed:	e9 6a f2 ff ff       	jmp    8010775c <alltraps>

801084f2 <vector183>:
.globl vector183
vector183:
  pushl $0
801084f2:	6a 00                	push   $0x0
  pushl $183
801084f4:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
801084f9:	e9 5e f2 ff ff       	jmp    8010775c <alltraps>

801084fe <vector184>:
.globl vector184
vector184:
  pushl $0
801084fe:	6a 00                	push   $0x0
  pushl $184
80108500:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80108505:	e9 52 f2 ff ff       	jmp    8010775c <alltraps>

8010850a <vector185>:
.globl vector185
vector185:
  pushl $0
8010850a:	6a 00                	push   $0x0
  pushl $185
8010850c:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80108511:	e9 46 f2 ff ff       	jmp    8010775c <alltraps>

80108516 <vector186>:
.globl vector186
vector186:
  pushl $0
80108516:	6a 00                	push   $0x0
  pushl $186
80108518:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
8010851d:	e9 3a f2 ff ff       	jmp    8010775c <alltraps>

80108522 <vector187>:
.globl vector187
vector187:
  pushl $0
80108522:	6a 00                	push   $0x0
  pushl $187
80108524:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80108529:	e9 2e f2 ff ff       	jmp    8010775c <alltraps>

8010852e <vector188>:
.globl vector188
vector188:
  pushl $0
8010852e:	6a 00                	push   $0x0
  pushl $188
80108530:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80108535:	e9 22 f2 ff ff       	jmp    8010775c <alltraps>

8010853a <vector189>:
.globl vector189
vector189:
  pushl $0
8010853a:	6a 00                	push   $0x0
  pushl $189
8010853c:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80108541:	e9 16 f2 ff ff       	jmp    8010775c <alltraps>

80108546 <vector190>:
.globl vector190
vector190:
  pushl $0
80108546:	6a 00                	push   $0x0
  pushl $190
80108548:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
8010854d:	e9 0a f2 ff ff       	jmp    8010775c <alltraps>

80108552 <vector191>:
.globl vector191
vector191:
  pushl $0
80108552:	6a 00                	push   $0x0
  pushl $191
80108554:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80108559:	e9 fe f1 ff ff       	jmp    8010775c <alltraps>

8010855e <vector192>:
.globl vector192
vector192:
  pushl $0
8010855e:	6a 00                	push   $0x0
  pushl $192
80108560:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80108565:	e9 f2 f1 ff ff       	jmp    8010775c <alltraps>

8010856a <vector193>:
.globl vector193
vector193:
  pushl $0
8010856a:	6a 00                	push   $0x0
  pushl $193
8010856c:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80108571:	e9 e6 f1 ff ff       	jmp    8010775c <alltraps>

80108576 <vector194>:
.globl vector194
vector194:
  pushl $0
80108576:	6a 00                	push   $0x0
  pushl $194
80108578:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
8010857d:	e9 da f1 ff ff       	jmp    8010775c <alltraps>

80108582 <vector195>:
.globl vector195
vector195:
  pushl $0
80108582:	6a 00                	push   $0x0
  pushl $195
80108584:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80108589:	e9 ce f1 ff ff       	jmp    8010775c <alltraps>

8010858e <vector196>:
.globl vector196
vector196:
  pushl $0
8010858e:	6a 00                	push   $0x0
  pushl $196
80108590:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80108595:	e9 c2 f1 ff ff       	jmp    8010775c <alltraps>

8010859a <vector197>:
.globl vector197
vector197:
  pushl $0
8010859a:	6a 00                	push   $0x0
  pushl $197
8010859c:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
801085a1:	e9 b6 f1 ff ff       	jmp    8010775c <alltraps>

801085a6 <vector198>:
.globl vector198
vector198:
  pushl $0
801085a6:	6a 00                	push   $0x0
  pushl $198
801085a8:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
801085ad:	e9 aa f1 ff ff       	jmp    8010775c <alltraps>

801085b2 <vector199>:
.globl vector199
vector199:
  pushl $0
801085b2:	6a 00                	push   $0x0
  pushl $199
801085b4:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
801085b9:	e9 9e f1 ff ff       	jmp    8010775c <alltraps>

801085be <vector200>:
.globl vector200
vector200:
  pushl $0
801085be:	6a 00                	push   $0x0
  pushl $200
801085c0:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
801085c5:	e9 92 f1 ff ff       	jmp    8010775c <alltraps>

801085ca <vector201>:
.globl vector201
vector201:
  pushl $0
801085ca:	6a 00                	push   $0x0
  pushl $201
801085cc:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
801085d1:	e9 86 f1 ff ff       	jmp    8010775c <alltraps>

801085d6 <vector202>:
.globl vector202
vector202:
  pushl $0
801085d6:	6a 00                	push   $0x0
  pushl $202
801085d8:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
801085dd:	e9 7a f1 ff ff       	jmp    8010775c <alltraps>

801085e2 <vector203>:
.globl vector203
vector203:
  pushl $0
801085e2:	6a 00                	push   $0x0
  pushl $203
801085e4:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
801085e9:	e9 6e f1 ff ff       	jmp    8010775c <alltraps>

801085ee <vector204>:
.globl vector204
vector204:
  pushl $0
801085ee:	6a 00                	push   $0x0
  pushl $204
801085f0:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
801085f5:	e9 62 f1 ff ff       	jmp    8010775c <alltraps>

801085fa <vector205>:
.globl vector205
vector205:
  pushl $0
801085fa:	6a 00                	push   $0x0
  pushl $205
801085fc:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80108601:	e9 56 f1 ff ff       	jmp    8010775c <alltraps>

80108606 <vector206>:
.globl vector206
vector206:
  pushl $0
80108606:	6a 00                	push   $0x0
  pushl $206
80108608:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
8010860d:	e9 4a f1 ff ff       	jmp    8010775c <alltraps>

80108612 <vector207>:
.globl vector207
vector207:
  pushl $0
80108612:	6a 00                	push   $0x0
  pushl $207
80108614:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80108619:	e9 3e f1 ff ff       	jmp    8010775c <alltraps>

8010861e <vector208>:
.globl vector208
vector208:
  pushl $0
8010861e:	6a 00                	push   $0x0
  pushl $208
80108620:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80108625:	e9 32 f1 ff ff       	jmp    8010775c <alltraps>

8010862a <vector209>:
.globl vector209
vector209:
  pushl $0
8010862a:	6a 00                	push   $0x0
  pushl $209
8010862c:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80108631:	e9 26 f1 ff ff       	jmp    8010775c <alltraps>

80108636 <vector210>:
.globl vector210
vector210:
  pushl $0
80108636:	6a 00                	push   $0x0
  pushl $210
80108638:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
8010863d:	e9 1a f1 ff ff       	jmp    8010775c <alltraps>

80108642 <vector211>:
.globl vector211
vector211:
  pushl $0
80108642:	6a 00                	push   $0x0
  pushl $211
80108644:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80108649:	e9 0e f1 ff ff       	jmp    8010775c <alltraps>

8010864e <vector212>:
.globl vector212
vector212:
  pushl $0
8010864e:	6a 00                	push   $0x0
  pushl $212
80108650:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80108655:	e9 02 f1 ff ff       	jmp    8010775c <alltraps>

8010865a <vector213>:
.globl vector213
vector213:
  pushl $0
8010865a:	6a 00                	push   $0x0
  pushl $213
8010865c:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80108661:	e9 f6 f0 ff ff       	jmp    8010775c <alltraps>

80108666 <vector214>:
.globl vector214
vector214:
  pushl $0
80108666:	6a 00                	push   $0x0
  pushl $214
80108668:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
8010866d:	e9 ea f0 ff ff       	jmp    8010775c <alltraps>

80108672 <vector215>:
.globl vector215
vector215:
  pushl $0
80108672:	6a 00                	push   $0x0
  pushl $215
80108674:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80108679:	e9 de f0 ff ff       	jmp    8010775c <alltraps>

8010867e <vector216>:
.globl vector216
vector216:
  pushl $0
8010867e:	6a 00                	push   $0x0
  pushl $216
80108680:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80108685:	e9 d2 f0 ff ff       	jmp    8010775c <alltraps>

8010868a <vector217>:
.globl vector217
vector217:
  pushl $0
8010868a:	6a 00                	push   $0x0
  pushl $217
8010868c:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80108691:	e9 c6 f0 ff ff       	jmp    8010775c <alltraps>

80108696 <vector218>:
.globl vector218
vector218:
  pushl $0
80108696:	6a 00                	push   $0x0
  pushl $218
80108698:	68 da 00 00 00       	push   $0xda
  jmp alltraps
8010869d:	e9 ba f0 ff ff       	jmp    8010775c <alltraps>

801086a2 <vector219>:
.globl vector219
vector219:
  pushl $0
801086a2:	6a 00                	push   $0x0
  pushl $219
801086a4:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
801086a9:	e9 ae f0 ff ff       	jmp    8010775c <alltraps>

801086ae <vector220>:
.globl vector220
vector220:
  pushl $0
801086ae:	6a 00                	push   $0x0
  pushl $220
801086b0:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
801086b5:	e9 a2 f0 ff ff       	jmp    8010775c <alltraps>

801086ba <vector221>:
.globl vector221
vector221:
  pushl $0
801086ba:	6a 00                	push   $0x0
  pushl $221
801086bc:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
801086c1:	e9 96 f0 ff ff       	jmp    8010775c <alltraps>

801086c6 <vector222>:
.globl vector222
vector222:
  pushl $0
801086c6:	6a 00                	push   $0x0
  pushl $222
801086c8:	68 de 00 00 00       	push   $0xde
  jmp alltraps
801086cd:	e9 8a f0 ff ff       	jmp    8010775c <alltraps>

801086d2 <vector223>:
.globl vector223
vector223:
  pushl $0
801086d2:	6a 00                	push   $0x0
  pushl $223
801086d4:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
801086d9:	e9 7e f0 ff ff       	jmp    8010775c <alltraps>

801086de <vector224>:
.globl vector224
vector224:
  pushl $0
801086de:	6a 00                	push   $0x0
  pushl $224
801086e0:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
801086e5:	e9 72 f0 ff ff       	jmp    8010775c <alltraps>

801086ea <vector225>:
.globl vector225
vector225:
  pushl $0
801086ea:	6a 00                	push   $0x0
  pushl $225
801086ec:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
801086f1:	e9 66 f0 ff ff       	jmp    8010775c <alltraps>

801086f6 <vector226>:
.globl vector226
vector226:
  pushl $0
801086f6:	6a 00                	push   $0x0
  pushl $226
801086f8:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
801086fd:	e9 5a f0 ff ff       	jmp    8010775c <alltraps>

80108702 <vector227>:
.globl vector227
vector227:
  pushl $0
80108702:	6a 00                	push   $0x0
  pushl $227
80108704:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80108709:	e9 4e f0 ff ff       	jmp    8010775c <alltraps>

8010870e <vector228>:
.globl vector228
vector228:
  pushl $0
8010870e:	6a 00                	push   $0x0
  pushl $228
80108710:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80108715:	e9 42 f0 ff ff       	jmp    8010775c <alltraps>

8010871a <vector229>:
.globl vector229
vector229:
  pushl $0
8010871a:	6a 00                	push   $0x0
  pushl $229
8010871c:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80108721:	e9 36 f0 ff ff       	jmp    8010775c <alltraps>

80108726 <vector230>:
.globl vector230
vector230:
  pushl $0
80108726:	6a 00                	push   $0x0
  pushl $230
80108728:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
8010872d:	e9 2a f0 ff ff       	jmp    8010775c <alltraps>

80108732 <vector231>:
.globl vector231
vector231:
  pushl $0
80108732:	6a 00                	push   $0x0
  pushl $231
80108734:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80108739:	e9 1e f0 ff ff       	jmp    8010775c <alltraps>

8010873e <vector232>:
.globl vector232
vector232:
  pushl $0
8010873e:	6a 00                	push   $0x0
  pushl $232
80108740:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80108745:	e9 12 f0 ff ff       	jmp    8010775c <alltraps>

8010874a <vector233>:
.globl vector233
vector233:
  pushl $0
8010874a:	6a 00                	push   $0x0
  pushl $233
8010874c:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80108751:	e9 06 f0 ff ff       	jmp    8010775c <alltraps>

80108756 <vector234>:
.globl vector234
vector234:
  pushl $0
80108756:	6a 00                	push   $0x0
  pushl $234
80108758:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
8010875d:	e9 fa ef ff ff       	jmp    8010775c <alltraps>

80108762 <vector235>:
.globl vector235
vector235:
  pushl $0
80108762:	6a 00                	push   $0x0
  pushl $235
80108764:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80108769:	e9 ee ef ff ff       	jmp    8010775c <alltraps>

8010876e <vector236>:
.globl vector236
vector236:
  pushl $0
8010876e:	6a 00                	push   $0x0
  pushl $236
80108770:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80108775:	e9 e2 ef ff ff       	jmp    8010775c <alltraps>

8010877a <vector237>:
.globl vector237
vector237:
  pushl $0
8010877a:	6a 00                	push   $0x0
  pushl $237
8010877c:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80108781:	e9 d6 ef ff ff       	jmp    8010775c <alltraps>

80108786 <vector238>:
.globl vector238
vector238:
  pushl $0
80108786:	6a 00                	push   $0x0
  pushl $238
80108788:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
8010878d:	e9 ca ef ff ff       	jmp    8010775c <alltraps>

80108792 <vector239>:
.globl vector239
vector239:
  pushl $0
80108792:	6a 00                	push   $0x0
  pushl $239
80108794:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80108799:	e9 be ef ff ff       	jmp    8010775c <alltraps>

8010879e <vector240>:
.globl vector240
vector240:
  pushl $0
8010879e:	6a 00                	push   $0x0
  pushl $240
801087a0:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
801087a5:	e9 b2 ef ff ff       	jmp    8010775c <alltraps>

801087aa <vector241>:
.globl vector241
vector241:
  pushl $0
801087aa:	6a 00                	push   $0x0
  pushl $241
801087ac:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
801087b1:	e9 a6 ef ff ff       	jmp    8010775c <alltraps>

801087b6 <vector242>:
.globl vector242
vector242:
  pushl $0
801087b6:	6a 00                	push   $0x0
  pushl $242
801087b8:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
801087bd:	e9 9a ef ff ff       	jmp    8010775c <alltraps>

801087c2 <vector243>:
.globl vector243
vector243:
  pushl $0
801087c2:	6a 00                	push   $0x0
  pushl $243
801087c4:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
801087c9:	e9 8e ef ff ff       	jmp    8010775c <alltraps>

801087ce <vector244>:
.globl vector244
vector244:
  pushl $0
801087ce:	6a 00                	push   $0x0
  pushl $244
801087d0:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
801087d5:	e9 82 ef ff ff       	jmp    8010775c <alltraps>

801087da <vector245>:
.globl vector245
vector245:
  pushl $0
801087da:	6a 00                	push   $0x0
  pushl $245
801087dc:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
801087e1:	e9 76 ef ff ff       	jmp    8010775c <alltraps>

801087e6 <vector246>:
.globl vector246
vector246:
  pushl $0
801087e6:	6a 00                	push   $0x0
  pushl $246
801087e8:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
801087ed:	e9 6a ef ff ff       	jmp    8010775c <alltraps>

801087f2 <vector247>:
.globl vector247
vector247:
  pushl $0
801087f2:	6a 00                	push   $0x0
  pushl $247
801087f4:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
801087f9:	e9 5e ef ff ff       	jmp    8010775c <alltraps>

801087fe <vector248>:
.globl vector248
vector248:
  pushl $0
801087fe:	6a 00                	push   $0x0
  pushl $248
80108800:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80108805:	e9 52 ef ff ff       	jmp    8010775c <alltraps>

8010880a <vector249>:
.globl vector249
vector249:
  pushl $0
8010880a:	6a 00                	push   $0x0
  pushl $249
8010880c:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80108811:	e9 46 ef ff ff       	jmp    8010775c <alltraps>

80108816 <vector250>:
.globl vector250
vector250:
  pushl $0
80108816:	6a 00                	push   $0x0
  pushl $250
80108818:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
8010881d:	e9 3a ef ff ff       	jmp    8010775c <alltraps>

80108822 <vector251>:
.globl vector251
vector251:
  pushl $0
80108822:	6a 00                	push   $0x0
  pushl $251
80108824:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80108829:	e9 2e ef ff ff       	jmp    8010775c <alltraps>

8010882e <vector252>:
.globl vector252
vector252:
  pushl $0
8010882e:	6a 00                	push   $0x0
  pushl $252
80108830:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80108835:	e9 22 ef ff ff       	jmp    8010775c <alltraps>

8010883a <vector253>:
.globl vector253
vector253:
  pushl $0
8010883a:	6a 00                	push   $0x0
  pushl $253
8010883c:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80108841:	e9 16 ef ff ff       	jmp    8010775c <alltraps>

80108846 <vector254>:
.globl vector254
vector254:
  pushl $0
80108846:	6a 00                	push   $0x0
  pushl $254
80108848:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
8010884d:	e9 0a ef ff ff       	jmp    8010775c <alltraps>

80108852 <vector255>:
.globl vector255
vector255:
  pushl $0
80108852:	6a 00                	push   $0x0
  pushl $255
80108854:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80108859:	e9 fe ee ff ff       	jmp    8010775c <alltraps>
	...

80108860 <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
80108860:	55                   	push   %ebp
80108861:	89 e5                	mov    %esp,%ebp
80108863:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80108866:	8b 45 0c             	mov    0xc(%ebp),%eax
80108869:	83 e8 01             	sub    $0x1,%eax
8010886c:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80108870:	8b 45 08             	mov    0x8(%ebp),%eax
80108873:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80108877:	8b 45 08             	mov    0x8(%ebp),%eax
8010887a:	c1 e8 10             	shr    $0x10,%eax
8010887d:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
80108881:	8d 45 fa             	lea    -0x6(%ebp),%eax
80108884:	0f 01 10             	lgdtl  (%eax)
}
80108887:	c9                   	leave  
80108888:	c3                   	ret    

80108889 <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
80108889:	55                   	push   %ebp
8010888a:	89 e5                	mov    %esp,%ebp
8010888c:	83 ec 04             	sub    $0x4,%esp
8010888f:	8b 45 08             	mov    0x8(%ebp),%eax
80108892:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
80108896:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
8010889a:	0f 00 d8             	ltr    %ax
}
8010889d:	c9                   	leave  
8010889e:	c3                   	ret    

8010889f <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
8010889f:	55                   	push   %ebp
801088a0:	89 e5                	mov    %esp,%ebp
801088a2:	83 ec 04             	sub    $0x4,%esp
801088a5:	8b 45 08             	mov    0x8(%ebp),%eax
801088a8:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
801088ac:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
801088b0:	8e e8                	mov    %eax,%gs
}
801088b2:	c9                   	leave  
801088b3:	c3                   	ret    

801088b4 <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
801088b4:	55                   	push   %ebp
801088b5:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
801088b7:	8b 45 08             	mov    0x8(%ebp),%eax
801088ba:	0f 22 d8             	mov    %eax,%cr3
}
801088bd:	5d                   	pop    %ebp
801088be:	c3                   	ret    

801088bf <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
801088bf:	55                   	push   %ebp
801088c0:	89 e5                	mov    %esp,%ebp
801088c2:	8b 45 08             	mov    0x8(%ebp),%eax
801088c5:	05 00 00 00 80       	add    $0x80000000,%eax
801088ca:	5d                   	pop    %ebp
801088cb:	c3                   	ret    

801088cc <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
801088cc:	55                   	push   %ebp
801088cd:	89 e5                	mov    %esp,%ebp
801088cf:	8b 45 08             	mov    0x8(%ebp),%eax
801088d2:	05 00 00 00 80       	add    $0x80000000,%eax
801088d7:	5d                   	pop    %ebp
801088d8:	c3                   	ret    

801088d9 <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
801088d9:	55                   	push   %ebp
801088da:	89 e5                	mov    %esp,%ebp
801088dc:	53                   	push   %ebx
801088dd:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
801088e0:	e8 a4 ad ff ff       	call   80103689 <cpunum>
801088e5:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801088eb:	05 40 71 12 80       	add    $0x80127140,%eax
801088f0:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
801088f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088f6:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
801088fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088ff:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
80108905:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108908:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
8010890c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010890f:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108913:	83 e2 f0             	and    $0xfffffff0,%edx
80108916:	83 ca 0a             	or     $0xa,%edx
80108919:	88 50 7d             	mov    %dl,0x7d(%eax)
8010891c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010891f:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108923:	83 ca 10             	or     $0x10,%edx
80108926:	88 50 7d             	mov    %dl,0x7d(%eax)
80108929:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010892c:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108930:	83 e2 9f             	and    $0xffffff9f,%edx
80108933:	88 50 7d             	mov    %dl,0x7d(%eax)
80108936:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108939:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
8010893d:	83 ca 80             	or     $0xffffff80,%edx
80108940:	88 50 7d             	mov    %dl,0x7d(%eax)
80108943:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108946:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010894a:	83 ca 0f             	or     $0xf,%edx
8010894d:	88 50 7e             	mov    %dl,0x7e(%eax)
80108950:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108953:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108957:	83 e2 ef             	and    $0xffffffef,%edx
8010895a:	88 50 7e             	mov    %dl,0x7e(%eax)
8010895d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108960:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108964:	83 e2 df             	and    $0xffffffdf,%edx
80108967:	88 50 7e             	mov    %dl,0x7e(%eax)
8010896a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010896d:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108971:	83 ca 40             	or     $0x40,%edx
80108974:	88 50 7e             	mov    %dl,0x7e(%eax)
80108977:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010897a:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010897e:	83 ca 80             	or     $0xffffff80,%edx
80108981:	88 50 7e             	mov    %dl,0x7e(%eax)
80108984:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108987:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
8010898b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010898e:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
80108995:	ff ff 
80108997:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010899a:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
801089a1:	00 00 
801089a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089a6:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
801089ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089b0:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801089b7:	83 e2 f0             	and    $0xfffffff0,%edx
801089ba:	83 ca 02             	or     $0x2,%edx
801089bd:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801089c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089c6:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801089cd:	83 ca 10             	or     $0x10,%edx
801089d0:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801089d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089d9:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801089e0:	83 e2 9f             	and    $0xffffff9f,%edx
801089e3:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801089e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089ec:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801089f3:	83 ca 80             	or     $0xffffff80,%edx
801089f6:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801089fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089ff:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108a06:	83 ca 0f             	or     $0xf,%edx
80108a09:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108a0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a12:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108a19:	83 e2 ef             	and    $0xffffffef,%edx
80108a1c:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108a22:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a25:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108a2c:	83 e2 df             	and    $0xffffffdf,%edx
80108a2f:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108a35:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a38:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108a3f:	83 ca 40             	or     $0x40,%edx
80108a42:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108a48:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a4b:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108a52:	83 ca 80             	or     $0xffffff80,%edx
80108a55:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108a5b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a5e:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80108a65:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a68:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
80108a6f:	ff ff 
80108a71:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a74:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
80108a7b:	00 00 
80108a7d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a80:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
80108a87:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a8a:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80108a91:	83 e2 f0             	and    $0xfffffff0,%edx
80108a94:	83 ca 0a             	or     $0xa,%edx
80108a97:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80108a9d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108aa0:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80108aa7:	83 ca 10             	or     $0x10,%edx
80108aaa:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80108ab0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ab3:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80108aba:	83 ca 60             	or     $0x60,%edx
80108abd:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80108ac3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ac6:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80108acd:	83 ca 80             	or     $0xffffff80,%edx
80108ad0:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80108ad6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ad9:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108ae0:	83 ca 0f             	or     $0xf,%edx
80108ae3:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108ae9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108aec:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108af3:	83 e2 ef             	and    $0xffffffef,%edx
80108af6:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108afc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108aff:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108b06:	83 e2 df             	and    $0xffffffdf,%edx
80108b09:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108b0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b12:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108b19:	83 ca 40             	or     $0x40,%edx
80108b1c:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108b22:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b25:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108b2c:	83 ca 80             	or     $0xffffff80,%edx
80108b2f:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108b35:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b38:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80108b3f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b42:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
80108b49:	ff ff 
80108b4b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b4e:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
80108b55:	00 00 
80108b57:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b5a:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
80108b61:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b64:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108b6b:	83 e2 f0             	and    $0xfffffff0,%edx
80108b6e:	83 ca 02             	or     $0x2,%edx
80108b71:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108b77:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b7a:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108b81:	83 ca 10             	or     $0x10,%edx
80108b84:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108b8a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b8d:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108b94:	83 ca 60             	or     $0x60,%edx
80108b97:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108b9d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ba0:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108ba7:	83 ca 80             	or     $0xffffff80,%edx
80108baa:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108bb0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108bb3:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108bba:	83 ca 0f             	or     $0xf,%edx
80108bbd:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108bc3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108bc6:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108bcd:	83 e2 ef             	and    $0xffffffef,%edx
80108bd0:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108bd6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108bd9:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108be0:	83 e2 df             	and    $0xffffffdf,%edx
80108be3:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108be9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108bec:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108bf3:	83 ca 40             	or     $0x40,%edx
80108bf6:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108bfc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108bff:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108c06:	83 ca 80             	or     $0xffffff80,%edx
80108c09:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108c0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c12:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
80108c19:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c1c:	05 b4 00 00 00       	add    $0xb4,%eax
80108c21:	89 c3                	mov    %eax,%ebx
80108c23:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c26:	05 b4 00 00 00       	add    $0xb4,%eax
80108c2b:	c1 e8 10             	shr    $0x10,%eax
80108c2e:	89 c1                	mov    %eax,%ecx
80108c30:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c33:	05 b4 00 00 00       	add    $0xb4,%eax
80108c38:	c1 e8 18             	shr    $0x18,%eax
80108c3b:	89 c2                	mov    %eax,%edx
80108c3d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c40:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
80108c47:	00 00 
80108c49:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c4c:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
80108c53:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c56:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
80108c5c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c5f:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108c66:	83 e1 f0             	and    $0xfffffff0,%ecx
80108c69:	83 c9 02             	or     $0x2,%ecx
80108c6c:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108c72:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c75:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108c7c:	83 c9 10             	or     $0x10,%ecx
80108c7f:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108c85:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c88:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108c8f:	83 e1 9f             	and    $0xffffff9f,%ecx
80108c92:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108c98:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c9b:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108ca2:	83 c9 80             	or     $0xffffff80,%ecx
80108ca5:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108cab:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108cae:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108cb5:	83 e1 f0             	and    $0xfffffff0,%ecx
80108cb8:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108cbe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108cc1:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108cc8:	83 e1 ef             	and    $0xffffffef,%ecx
80108ccb:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108cd1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108cd4:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108cdb:	83 e1 df             	and    $0xffffffdf,%ecx
80108cde:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108ce4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ce7:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108cee:	83 c9 40             	or     $0x40,%ecx
80108cf1:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108cf7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108cfa:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108d01:	83 c9 80             	or     $0xffffff80,%ecx
80108d04:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108d0a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d0d:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
80108d13:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d16:	83 c0 70             	add    $0x70,%eax
80108d19:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
80108d20:	00 
80108d21:	89 04 24             	mov    %eax,(%esp)
80108d24:	e8 37 fb ff ff       	call   80108860 <lgdt>
  loadgs(SEG_KCPU << 3);
80108d29:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
80108d30:	e8 6a fb ff ff       	call   8010889f <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
80108d35:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d38:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
80108d3e:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80108d45:	00 00 00 00 
}
80108d49:	83 c4 24             	add    $0x24,%esp
80108d4c:	5b                   	pop    %ebx
80108d4d:	5d                   	pop    %ebp
80108d4e:	c3                   	ret    

80108d4f <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80108d4f:	55                   	push   %ebp
80108d50:	89 e5                	mov    %esp,%ebp
80108d52:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80108d55:	8b 45 0c             	mov    0xc(%ebp),%eax
80108d58:	c1 e8 16             	shr    $0x16,%eax
80108d5b:	c1 e0 02             	shl    $0x2,%eax
80108d5e:	03 45 08             	add    0x8(%ebp),%eax
80108d61:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
80108d64:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108d67:	8b 00                	mov    (%eax),%eax
80108d69:	83 e0 01             	and    $0x1,%eax
80108d6c:	84 c0                	test   %al,%al
80108d6e:	74 17                	je     80108d87 <walkpgdir+0x38>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
80108d70:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108d73:	8b 00                	mov    (%eax),%eax
80108d75:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108d7a:	89 04 24             	mov    %eax,(%esp)
80108d7d:	e8 4a fb ff ff       	call   801088cc <p2v>
80108d82:	89 45 f4             	mov    %eax,-0xc(%ebp)
80108d85:	eb 4b                	jmp    80108dd2 <walkpgdir+0x83>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
80108d87:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80108d8b:	74 0e                	je     80108d9b <walkpgdir+0x4c>
80108d8d:	e8 7e 9d ff ff       	call   80102b10 <kalloc>
80108d92:	89 45 f4             	mov    %eax,-0xc(%ebp)
80108d95:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80108d99:	75 07                	jne    80108da2 <walkpgdir+0x53>
      return 0;
80108d9b:	b8 00 00 00 00       	mov    $0x0,%eax
80108da0:	eb 41                	jmp    80108de3 <walkpgdir+0x94>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
80108da2:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108da9:	00 
80108daa:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108db1:	00 
80108db2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108db5:	89 04 24             	mov    %eax,(%esp)
80108db8:	e8 5d d0 ff ff       	call   80105e1a <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
80108dbd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108dc0:	89 04 24             	mov    %eax,(%esp)
80108dc3:	e8 f7 fa ff ff       	call   801088bf <v2p>
80108dc8:	89 c2                	mov    %eax,%edx
80108dca:	83 ca 07             	or     $0x7,%edx
80108dcd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108dd0:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
80108dd2:	8b 45 0c             	mov    0xc(%ebp),%eax
80108dd5:	c1 e8 0c             	shr    $0xc,%eax
80108dd8:	25 ff 03 00 00       	and    $0x3ff,%eax
80108ddd:	c1 e0 02             	shl    $0x2,%eax
80108de0:	03 45 f4             	add    -0xc(%ebp),%eax
}
80108de3:	c9                   	leave  
80108de4:	c3                   	ret    

80108de5 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80108de5:	55                   	push   %ebp
80108de6:	89 e5                	mov    %esp,%ebp
80108de8:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
80108deb:	8b 45 0c             	mov    0xc(%ebp),%eax
80108dee:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108df3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  //cprintf("mappages: a = %p\n",a);
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80108df6:	8b 45 0c             	mov    0xc(%ebp),%eax
80108df9:	03 45 10             	add    0x10(%ebp),%eax
80108dfc:	83 e8 01             	sub    $0x1,%eax
80108dff:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108e04:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80108e07:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80108e0e:	00 
80108e0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e12:	89 44 24 04          	mov    %eax,0x4(%esp)
80108e16:	8b 45 08             	mov    0x8(%ebp),%eax
80108e19:	89 04 24             	mov    %eax,(%esp)
80108e1c:	e8 2e ff ff ff       	call   80108d4f <walkpgdir>
80108e21:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108e24:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108e28:	75 07                	jne    80108e31 <mappages+0x4c>
      return -1;
80108e2a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108e2f:	eb 46                	jmp    80108e77 <mappages+0x92>
    if(*pte & PTE_P)
80108e31:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108e34:	8b 00                	mov    (%eax),%eax
80108e36:	83 e0 01             	and    $0x1,%eax
80108e39:	84 c0                	test   %al,%al
80108e3b:	74 0c                	je     80108e49 <mappages+0x64>
      panic("remap");
80108e3d:	c7 04 24 e8 9d 10 80 	movl   $0x80109de8,(%esp)
80108e44:	e8 f4 76 ff ff       	call   8010053d <panic>
    *pte = pa | perm | PTE_P;
80108e49:	8b 45 18             	mov    0x18(%ebp),%eax
80108e4c:	0b 45 14             	or     0x14(%ebp),%eax
80108e4f:	89 c2                	mov    %eax,%edx
80108e51:	83 ca 01             	or     $0x1,%edx
80108e54:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108e57:	89 10                	mov    %edx,(%eax)
   //cprintf("mappages: pte = %p\n",pte);
    if(a == last)
80108e59:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e5c:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80108e5f:	74 10                	je     80108e71 <mappages+0x8c>
      break;
    a += PGSIZE;
80108e61:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
80108e68:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
80108e6f:	eb 96                	jmp    80108e07 <mappages+0x22>
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
   //cprintf("mappages: pte = %p\n",pte);
    if(a == last)
      break;
80108e71:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
80108e72:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108e77:	c9                   	leave  
80108e78:	c3                   	ret    

80108e79 <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm()
{
80108e79:	55                   	push   %ebp
80108e7a:	89 e5                	mov    %esp,%ebp
80108e7c:	53                   	push   %ebx
80108e7d:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
80108e80:	e8 8b 9c ff ff       	call   80102b10 <kalloc>
80108e85:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108e88:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108e8c:	75 0a                	jne    80108e98 <setupkvm+0x1f>
    return 0;
80108e8e:	b8 00 00 00 00       	mov    $0x0,%eax
80108e93:	e9 98 00 00 00       	jmp    80108f30 <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
80108e98:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108e9f:	00 
80108ea0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108ea7:	00 
80108ea8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108eab:	89 04 24             	mov    %eax,(%esp)
80108eae:	e8 67 cf ff ff       	call   80105e1a <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
80108eb3:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
80108eba:	e8 0d fa ff ff       	call   801088cc <p2v>
80108ebf:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
80108ec4:	76 0c                	jbe    80108ed2 <setupkvm+0x59>
    panic("PHYSTOP too high");
80108ec6:	c7 04 24 ee 9d 10 80 	movl   $0x80109dee,(%esp)
80108ecd:	e8 6b 76 ff ff       	call   8010053d <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80108ed2:	c7 45 f4 c0 c4 10 80 	movl   $0x8010c4c0,-0xc(%ebp)
80108ed9:	eb 49                	jmp    80108f24 <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
80108edb:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80108ede:	8b 48 0c             	mov    0xc(%eax),%ecx
                (uint)k->phys_start, k->perm) < 0)
80108ee1:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80108ee4:	8b 50 04             	mov    0x4(%eax),%edx
80108ee7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108eea:	8b 58 08             	mov    0x8(%eax),%ebx
80108eed:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ef0:	8b 40 04             	mov    0x4(%eax),%eax
80108ef3:	29 c3                	sub    %eax,%ebx
80108ef5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ef8:	8b 00                	mov    (%eax),%eax
80108efa:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80108efe:	89 54 24 0c          	mov    %edx,0xc(%esp)
80108f02:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80108f06:	89 44 24 04          	mov    %eax,0x4(%esp)
80108f0a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108f0d:	89 04 24             	mov    %eax,(%esp)
80108f10:	e8 d0 fe ff ff       	call   80108de5 <mappages>
80108f15:	85 c0                	test   %eax,%eax
80108f17:	79 07                	jns    80108f20 <setupkvm+0xa7>
                (uint)k->phys_start, k->perm) < 0)
      return 0;
80108f19:	b8 00 00 00 00       	mov    $0x0,%eax
80108f1e:	eb 10                	jmp    80108f30 <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80108f20:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80108f24:	81 7d f4 00 c5 10 80 	cmpl   $0x8010c500,-0xc(%ebp)
80108f2b:	72 ae                	jb     80108edb <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
      return 0;
  return pgdir;
80108f2d:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80108f30:	83 c4 34             	add    $0x34,%esp
80108f33:	5b                   	pop    %ebx
80108f34:	5d                   	pop    %ebp
80108f35:	c3                   	ret    

80108f36 <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
void
kvmalloc(void)
{
80108f36:	55                   	push   %ebp
80108f37:	89 e5                	mov    %esp,%ebp
80108f39:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80108f3c:	e8 38 ff ff ff       	call   80108e79 <setupkvm>
80108f41:	a3 18 a4 12 80       	mov    %eax,0x8012a418
  switchkvm();
80108f46:	e8 02 00 00 00       	call   80108f4d <switchkvm>
}
80108f4b:	c9                   	leave  
80108f4c:	c3                   	ret    

80108f4d <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80108f4d:	55                   	push   %ebp
80108f4e:	89 e5                	mov    %esp,%ebp
80108f50:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
80108f53:	a1 18 a4 12 80       	mov    0x8012a418,%eax
80108f58:	89 04 24             	mov    %eax,(%esp)
80108f5b:	e8 5f f9 ff ff       	call   801088bf <v2p>
80108f60:	89 04 24             	mov    %eax,(%esp)
80108f63:	e8 4c f9 ff ff       	call   801088b4 <lcr3>
}
80108f68:	c9                   	leave  
80108f69:	c3                   	ret    

80108f6a <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80108f6a:	55                   	push   %ebp
80108f6b:	89 e5                	mov    %esp,%ebp
80108f6d:	53                   	push   %ebx
80108f6e:	83 ec 14             	sub    $0x14,%esp
  pushcli();
80108f71:	e8 9e cd ff ff       	call   80105d14 <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
80108f76:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108f7c:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108f83:	83 c2 08             	add    $0x8,%edx
80108f86:	89 d3                	mov    %edx,%ebx
80108f88:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108f8f:	83 c2 08             	add    $0x8,%edx
80108f92:	c1 ea 10             	shr    $0x10,%edx
80108f95:	89 d1                	mov    %edx,%ecx
80108f97:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108f9e:	83 c2 08             	add    $0x8,%edx
80108fa1:	c1 ea 18             	shr    $0x18,%edx
80108fa4:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
80108fab:	67 00 
80108fad:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
80108fb4:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
80108fba:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108fc1:	83 e1 f0             	and    $0xfffffff0,%ecx
80108fc4:	83 c9 09             	or     $0x9,%ecx
80108fc7:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108fcd:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108fd4:	83 c9 10             	or     $0x10,%ecx
80108fd7:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108fdd:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108fe4:	83 e1 9f             	and    $0xffffff9f,%ecx
80108fe7:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108fed:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108ff4:	83 c9 80             	or     $0xffffff80,%ecx
80108ff7:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108ffd:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80109004:	83 e1 f0             	and    $0xfffffff0,%ecx
80109007:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
8010900d:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80109014:	83 e1 ef             	and    $0xffffffef,%ecx
80109017:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
8010901d:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80109024:	83 e1 df             	and    $0xffffffdf,%ecx
80109027:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
8010902d:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80109034:	83 c9 40             	or     $0x40,%ecx
80109037:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
8010903d:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80109044:	83 e1 7f             	and    $0x7f,%ecx
80109047:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
8010904d:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
80109053:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80109059:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
80109060:	83 e2 ef             	and    $0xffffffef,%edx
80109063:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
80109069:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010906f:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
80109075:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010907b:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80109082:	8b 52 08             	mov    0x8(%edx),%edx
80109085:	81 c2 00 10 00 00    	add    $0x1000,%edx
8010908b:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
8010908e:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
80109095:	e8 ef f7 ff ff       	call   80108889 <ltr>
  if(p->pgdir == 0)
8010909a:	8b 45 08             	mov    0x8(%ebp),%eax
8010909d:	8b 40 04             	mov    0x4(%eax),%eax
801090a0:	85 c0                	test   %eax,%eax
801090a2:	75 0c                	jne    801090b0 <switchuvm+0x146>
    panic("switchuvm: no pgdir");
801090a4:	c7 04 24 ff 9d 10 80 	movl   $0x80109dff,(%esp)
801090ab:	e8 8d 74 ff ff       	call   8010053d <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
801090b0:	8b 45 08             	mov    0x8(%ebp),%eax
801090b3:	8b 40 04             	mov    0x4(%eax),%eax
801090b6:	89 04 24             	mov    %eax,(%esp)
801090b9:	e8 01 f8 ff ff       	call   801088bf <v2p>
801090be:	89 04 24             	mov    %eax,(%esp)
801090c1:	e8 ee f7 ff ff       	call   801088b4 <lcr3>
  popcli();
801090c6:	e8 91 cc ff ff       	call   80105d5c <popcli>
}
801090cb:	83 c4 14             	add    $0x14,%esp
801090ce:	5b                   	pop    %ebx
801090cf:	5d                   	pop    %ebp
801090d0:	c3                   	ret    

801090d1 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
801090d1:	55                   	push   %ebp
801090d2:	89 e5                	mov    %esp,%ebp
801090d4:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
801090d7:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
801090de:	76 0c                	jbe    801090ec <inituvm+0x1b>
    panic("inituvm: more than a page");
801090e0:	c7 04 24 13 9e 10 80 	movl   $0x80109e13,(%esp)
801090e7:	e8 51 74 ff ff       	call   8010053d <panic>
  mem = kalloc();
801090ec:	e8 1f 9a ff ff       	call   80102b10 <kalloc>
801090f1:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
801090f4:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801090fb:	00 
801090fc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80109103:	00 
80109104:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109107:	89 04 24             	mov    %eax,(%esp)
8010910a:	e8 0b cd ff ff       	call   80105e1a <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
8010910f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109112:	89 04 24             	mov    %eax,(%esp)
80109115:	e8 a5 f7 ff ff       	call   801088bf <v2p>
8010911a:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80109121:	00 
80109122:	89 44 24 0c          	mov    %eax,0xc(%esp)
80109126:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010912d:	00 
8010912e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80109135:	00 
80109136:	8b 45 08             	mov    0x8(%ebp),%eax
80109139:	89 04 24             	mov    %eax,(%esp)
8010913c:	e8 a4 fc ff ff       	call   80108de5 <mappages>
  memmove(mem, init, sz);
80109141:	8b 45 10             	mov    0x10(%ebp),%eax
80109144:	89 44 24 08          	mov    %eax,0x8(%esp)
80109148:	8b 45 0c             	mov    0xc(%ebp),%eax
8010914b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010914f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109152:	89 04 24             	mov    %eax,(%esp)
80109155:	e8 93 cd ff ff       	call   80105eed <memmove>
}
8010915a:	c9                   	leave  
8010915b:	c3                   	ret    

8010915c <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
8010915c:	55                   	push   %ebp
8010915d:	89 e5                	mov    %esp,%ebp
8010915f:	53                   	push   %ebx
80109160:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;
  if((uint) addr % PGSIZE != 0)
80109163:	8b 45 0c             	mov    0xc(%ebp),%eax
80109166:	25 ff 0f 00 00       	and    $0xfff,%eax
8010916b:	85 c0                	test   %eax,%eax
8010916d:	74 0c                	je     8010917b <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
8010916f:	c7 04 24 30 9e 10 80 	movl   $0x80109e30,(%esp)
80109176:	e8 c2 73 ff ff       	call   8010053d <panic>
  for(i = 0; i < sz; i += PGSIZE){
8010917b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80109182:	e9 ad 00 00 00       	jmp    80109234 <loaduvm+0xd8>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
80109187:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010918a:	8b 55 0c             	mov    0xc(%ebp),%edx
8010918d:	01 d0                	add    %edx,%eax
8010918f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80109196:	00 
80109197:	89 44 24 04          	mov    %eax,0x4(%esp)
8010919b:	8b 45 08             	mov    0x8(%ebp),%eax
8010919e:	89 04 24             	mov    %eax,(%esp)
801091a1:	e8 a9 fb ff ff       	call   80108d4f <walkpgdir>
801091a6:	89 45 ec             	mov    %eax,-0x14(%ebp)
801091a9:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801091ad:	75 0c                	jne    801091bb <loaduvm+0x5f>
      panic("loaduvm: address should exist");
801091af:	c7 04 24 53 9e 10 80 	movl   $0x80109e53,(%esp)
801091b6:	e8 82 73 ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
801091bb:	8b 45 ec             	mov    -0x14(%ebp),%eax
801091be:	8b 00                	mov    (%eax),%eax
801091c0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801091c5:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
801091c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801091cb:	8b 55 18             	mov    0x18(%ebp),%edx
801091ce:	89 d1                	mov    %edx,%ecx
801091d0:	29 c1                	sub    %eax,%ecx
801091d2:	89 c8                	mov    %ecx,%eax
801091d4:	3d ff 0f 00 00       	cmp    $0xfff,%eax
801091d9:	77 11                	ja     801091ec <loaduvm+0x90>
      n = sz - i;
801091db:	8b 45 f4             	mov    -0xc(%ebp),%eax
801091de:	8b 55 18             	mov    0x18(%ebp),%edx
801091e1:	89 d1                	mov    %edx,%ecx
801091e3:	29 c1                	sub    %eax,%ecx
801091e5:	89 c8                	mov    %ecx,%eax
801091e7:	89 45 f0             	mov    %eax,-0x10(%ebp)
801091ea:	eb 07                	jmp    801091f3 <loaduvm+0x97>
    else
      n = PGSIZE;
801091ec:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
801091f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801091f6:	8b 55 14             	mov    0x14(%ebp),%edx
801091f9:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
801091fc:	8b 45 e8             	mov    -0x18(%ebp),%eax
801091ff:	89 04 24             	mov    %eax,(%esp)
80109202:	e8 c5 f6 ff ff       	call   801088cc <p2v>
80109207:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010920a:	89 54 24 0c          	mov    %edx,0xc(%esp)
8010920e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80109212:	89 44 24 04          	mov    %eax,0x4(%esp)
80109216:	8b 45 10             	mov    0x10(%ebp),%eax
80109219:	89 04 24             	mov    %eax,(%esp)
8010921c:	e8 3d 8b ff ff       	call   80101d5e <readi>
80109221:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80109224:	74 07                	je     8010922d <loaduvm+0xd1>
      return -1;
80109226:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010922b:	eb 18                	jmp    80109245 <loaduvm+0xe9>
{
  uint i, pa, n;
  pte_t *pte;
  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
8010922d:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80109234:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109237:	3b 45 18             	cmp    0x18(%ebp),%eax
8010923a:	0f 82 47 ff ff ff    	jb     80109187 <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
80109240:	b8 00 00 00 00       	mov    $0x0,%eax
}
80109245:	83 c4 24             	add    $0x24,%esp
80109248:	5b                   	pop    %ebx
80109249:	5d                   	pop    %ebp
8010924a:	c3                   	ret    

8010924b <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
8010924b:	55                   	push   %ebp
8010924c:	89 e5                	mov    %esp,%ebp
8010924e:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  uint a;

  if(newsz >= KERNBASE)
80109251:	8b 45 10             	mov    0x10(%ebp),%eax
80109254:	85 c0                	test   %eax,%eax
80109256:	79 0a                	jns    80109262 <allocuvm+0x17>
    return 0;
80109258:	b8 00 00 00 00       	mov    $0x0,%eax
8010925d:	e9 c1 00 00 00       	jmp    80109323 <allocuvm+0xd8>
  if(newsz < oldsz)
80109262:	8b 45 10             	mov    0x10(%ebp),%eax
80109265:	3b 45 0c             	cmp    0xc(%ebp),%eax
80109268:	73 08                	jae    80109272 <allocuvm+0x27>
    return oldsz;
8010926a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010926d:	e9 b1 00 00 00       	jmp    80109323 <allocuvm+0xd8>
  a = PGROUNDUP(oldsz);
80109272:	8b 45 0c             	mov    0xc(%ebp),%eax
80109275:	05 ff 0f 00 00       	add    $0xfff,%eax
8010927a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010927f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
80109282:	e9 8d 00 00 00       	jmp    80109314 <allocuvm+0xc9>
    mem = kalloc();
80109287:	e8 84 98 ff ff       	call   80102b10 <kalloc>
8010928c:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(mem == 0){
8010928f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80109293:	75 2c                	jne    801092c1 <allocuvm+0x76>
      cprintf("allocuvm out of memory\n");
80109295:	c7 04 24 71 9e 10 80 	movl   $0x80109e71,(%esp)
8010929c:	e8 00 71 ff ff       	call   801003a1 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
801092a1:	8b 45 0c             	mov    0xc(%ebp),%eax
801092a4:	89 44 24 08          	mov    %eax,0x8(%esp)
801092a8:	8b 45 10             	mov    0x10(%ebp),%eax
801092ab:	89 44 24 04          	mov    %eax,0x4(%esp)
801092af:	8b 45 08             	mov    0x8(%ebp),%eax
801092b2:	89 04 24             	mov    %eax,(%esp)
801092b5:	e8 6b 00 00 00       	call   80109325 <deallocuvm>
      return 0;
801092ba:	b8 00 00 00 00       	mov    $0x0,%eax
801092bf:	eb 62                	jmp    80109323 <allocuvm+0xd8>
    }
    memset(mem, 0, PGSIZE);
801092c1:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801092c8:	00 
801092c9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801092d0:	00 
801092d1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801092d4:	89 04 24             	mov    %eax,(%esp)
801092d7:	e8 3e cb ff ff       	call   80105e1a <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
801092dc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801092df:	89 04 24             	mov    %eax,(%esp)
801092e2:	e8 d8 f5 ff ff       	call   801088bf <v2p>
801092e7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801092ea:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
801092f1:	00 
801092f2:	89 44 24 0c          	mov    %eax,0xc(%esp)
801092f6:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801092fd:	00 
801092fe:	89 54 24 04          	mov    %edx,0x4(%esp)
80109302:	8b 45 08             	mov    0x8(%ebp),%eax
80109305:	89 04 24             	mov    %eax,(%esp)
80109308:	e8 d8 fa ff ff       	call   80108de5 <mappages>
  if(newsz >= KERNBASE)
    return 0;
  if(newsz < oldsz)
    return oldsz;
  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
8010930d:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80109314:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109317:	3b 45 10             	cmp    0x10(%ebp),%eax
8010931a:	0f 82 67 ff ff ff    	jb     80109287 <allocuvm+0x3c>
      return 0;
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
  }
  return newsz;
80109320:	8b 45 10             	mov    0x10(%ebp),%eax
}
80109323:	c9                   	leave  
80109324:	c3                   	ret    

80109325 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80109325:	55                   	push   %ebp
80109326:	89 e5                	mov    %esp,%ebp
80109328:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
8010932b:	8b 45 10             	mov    0x10(%ebp),%eax
8010932e:	3b 45 0c             	cmp    0xc(%ebp),%eax
80109331:	72 08                	jb     8010933b <deallocuvm+0x16>
    return oldsz;
80109333:	8b 45 0c             	mov    0xc(%ebp),%eax
80109336:	e9 a4 00 00 00       	jmp    801093df <deallocuvm+0xba>

  a = PGROUNDUP(newsz);
8010933b:	8b 45 10             	mov    0x10(%ebp),%eax
8010933e:	05 ff 0f 00 00       	add    $0xfff,%eax
80109343:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109348:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
8010934b:	e9 80 00 00 00       	jmp    801093d0 <deallocuvm+0xab>
    pte = walkpgdir(pgdir, (char*)a, 0);
80109350:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109353:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010935a:	00 
8010935b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010935f:	8b 45 08             	mov    0x8(%ebp),%eax
80109362:	89 04 24             	mov    %eax,(%esp)
80109365:	e8 e5 f9 ff ff       	call   80108d4f <walkpgdir>
8010936a:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(!pte)
8010936d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80109371:	75 09                	jne    8010937c <deallocuvm+0x57>
      a += (NPTENTRIES - 1) * PGSIZE;
80109373:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
8010937a:	eb 4d                	jmp    801093c9 <deallocuvm+0xa4>
    else if((*pte & PTE_P) != 0){
8010937c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010937f:	8b 00                	mov    (%eax),%eax
80109381:	83 e0 01             	and    $0x1,%eax
80109384:	84 c0                	test   %al,%al
80109386:	74 41                	je     801093c9 <deallocuvm+0xa4>
      pa = PTE_ADDR(*pte);
80109388:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010938b:	8b 00                	mov    (%eax),%eax
8010938d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109392:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if(pa == 0)
80109395:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80109399:	75 0c                	jne    801093a7 <deallocuvm+0x82>
        panic("kfree");
8010939b:	c7 04 24 89 9e 10 80 	movl   $0x80109e89,(%esp)
801093a2:	e8 96 71 ff ff       	call   8010053d <panic>
      char *v = p2v(pa);
801093a7:	8b 45 ec             	mov    -0x14(%ebp),%eax
801093aa:	89 04 24             	mov    %eax,(%esp)
801093ad:	e8 1a f5 ff ff       	call   801088cc <p2v>
801093b2:	89 45 e8             	mov    %eax,-0x18(%ebp)
      kfree(v);
801093b5:	8b 45 e8             	mov    -0x18(%ebp),%eax
801093b8:	89 04 24             	mov    %eax,(%esp)
801093bb:	e8 b7 96 ff ff       	call   80102a77 <kfree>
      *pte = 0;
801093c0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801093c3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
801093c9:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801093d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801093d3:	3b 45 0c             	cmp    0xc(%ebp),%eax
801093d6:	0f 82 74 ff ff ff    	jb     80109350 <deallocuvm+0x2b>
      char *v = p2v(pa);
      kfree(v);
      *pte = 0;
    }
  }
  return newsz;
801093dc:	8b 45 10             	mov    0x10(%ebp),%eax
}
801093df:	c9                   	leave  
801093e0:	c3                   	ret    

801093e1 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
801093e1:	55                   	push   %ebp
801093e2:	89 e5                	mov    %esp,%ebp
801093e4:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
801093e7:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801093eb:	75 0c                	jne    801093f9 <freevm+0x18>
    panic("freevm: no pgdir");
801093ed:	c7 04 24 8f 9e 10 80 	movl   $0x80109e8f,(%esp)
801093f4:	e8 44 71 ff ff       	call   8010053d <panic>
  deallocuvm(pgdir, KERNBASE, 0);
801093f9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80109400:	00 
80109401:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
80109408:	80 
80109409:	8b 45 08             	mov    0x8(%ebp),%eax
8010940c:	89 04 24             	mov    %eax,(%esp)
8010940f:	e8 11 ff ff ff       	call   80109325 <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
80109414:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010941b:	eb 3c                	jmp    80109459 <freevm+0x78>
    if(pgdir[i] & PTE_P){
8010941d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109420:	c1 e0 02             	shl    $0x2,%eax
80109423:	03 45 08             	add    0x8(%ebp),%eax
80109426:	8b 00                	mov    (%eax),%eax
80109428:	83 e0 01             	and    $0x1,%eax
8010942b:	84 c0                	test   %al,%al
8010942d:	74 26                	je     80109455 <freevm+0x74>
      char * v = p2v(PTE_ADDR(pgdir[i]));
8010942f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109432:	c1 e0 02             	shl    $0x2,%eax
80109435:	03 45 08             	add    0x8(%ebp),%eax
80109438:	8b 00                	mov    (%eax),%eax
8010943a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010943f:	89 04 24             	mov    %eax,(%esp)
80109442:	e8 85 f4 ff ff       	call   801088cc <p2v>
80109447:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
8010944a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010944d:	89 04 24             	mov    %eax,(%esp)
80109450:	e8 22 96 ff ff       	call   80102a77 <kfree>
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
  for(i = 0; i < NPDENTRIES; i++){
80109455:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80109459:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
80109460:	76 bb                	jbe    8010941d <freevm+0x3c>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
80109462:	8b 45 08             	mov    0x8(%ebp),%eax
80109465:	89 04 24             	mov    %eax,(%esp)
80109468:	e8 0a 96 ff ff       	call   80102a77 <kfree>
}
8010946d:	c9                   	leave  
8010946e:	c3                   	ret    

8010946f <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
8010946f:	55                   	push   %ebp
80109470:	89 e5                	mov    %esp,%ebp
80109472:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80109475:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010947c:	00 
8010947d:	8b 45 0c             	mov    0xc(%ebp),%eax
80109480:	89 44 24 04          	mov    %eax,0x4(%esp)
80109484:	8b 45 08             	mov    0x8(%ebp),%eax
80109487:	89 04 24             	mov    %eax,(%esp)
8010948a:	e8 c0 f8 ff ff       	call   80108d4f <walkpgdir>
8010948f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
80109492:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80109496:	75 0c                	jne    801094a4 <clearpteu+0x35>
    panic("clearpteu");
80109498:	c7 04 24 a0 9e 10 80 	movl   $0x80109ea0,(%esp)
8010949f:	e8 99 70 ff ff       	call   8010053d <panic>
  *pte &= ~PTE_U;
801094a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801094a7:	8b 00                	mov    (%eax),%eax
801094a9:	89 c2                	mov    %eax,%edx
801094ab:	83 e2 fb             	and    $0xfffffffb,%edx
801094ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
801094b1:	89 10                	mov    %edx,(%eax)
}
801094b3:	c9                   	leave  
801094b4:	c3                   	ret    

801094b5 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
801094b5:	55                   	push   %ebp
801094b6:	89 e5                	mov    %esp,%ebp
801094b8:	83 ec 48             	sub    $0x48,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
801094bb:	e8 b9 f9 ff ff       	call   80108e79 <setupkvm>
801094c0:	89 45 f0             	mov    %eax,-0x10(%ebp)
801094c3:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801094c7:	75 0a                	jne    801094d3 <copyuvm+0x1e>
    return 0;
801094c9:	b8 00 00 00 00       	mov    $0x0,%eax
801094ce:	e9 f1 00 00 00       	jmp    801095c4 <copyuvm+0x10f>
  for(i = 0; i < sz; i += PGSIZE){
801094d3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801094da:	e9 c0 00 00 00       	jmp    8010959f <copyuvm+0xea>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
801094df:	8b 45 f4             	mov    -0xc(%ebp),%eax
801094e2:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801094e9:	00 
801094ea:	89 44 24 04          	mov    %eax,0x4(%esp)
801094ee:	8b 45 08             	mov    0x8(%ebp),%eax
801094f1:	89 04 24             	mov    %eax,(%esp)
801094f4:	e8 56 f8 ff ff       	call   80108d4f <walkpgdir>
801094f9:	89 45 ec             	mov    %eax,-0x14(%ebp)
801094fc:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80109500:	75 0c                	jne    8010950e <copyuvm+0x59>
      panic("copyuvm: pte should exist");
80109502:	c7 04 24 aa 9e 10 80 	movl   $0x80109eaa,(%esp)
80109509:	e8 2f 70 ff ff       	call   8010053d <panic>
    if(!(*pte & PTE_P))
8010950e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109511:	8b 00                	mov    (%eax),%eax
80109513:	83 e0 01             	and    $0x1,%eax
80109516:	85 c0                	test   %eax,%eax
80109518:	75 0c                	jne    80109526 <copyuvm+0x71>
      panic("copyuvm: page not present");
8010951a:	c7 04 24 c4 9e 10 80 	movl   $0x80109ec4,(%esp)
80109521:	e8 17 70 ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
80109526:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109529:	8b 00                	mov    (%eax),%eax
8010952b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109530:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if((mem = kalloc()) == 0)
80109533:	e8 d8 95 ff ff       	call   80102b10 <kalloc>
80109538:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010953b:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
8010953f:	74 6f                	je     801095b0 <copyuvm+0xfb>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
80109541:	8b 45 e8             	mov    -0x18(%ebp),%eax
80109544:	89 04 24             	mov    %eax,(%esp)
80109547:	e8 80 f3 ff ff       	call   801088cc <p2v>
8010954c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80109553:	00 
80109554:	89 44 24 04          	mov    %eax,0x4(%esp)
80109558:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010955b:	89 04 24             	mov    %eax,(%esp)
8010955e:	e8 8a c9 ff ff       	call   80105eed <memmove>
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
80109563:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80109566:	89 04 24             	mov    %eax,(%esp)
80109569:	e8 51 f3 ff ff       	call   801088bf <v2p>
8010956e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109571:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80109578:	00 
80109579:	89 44 24 0c          	mov    %eax,0xc(%esp)
8010957d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80109584:	00 
80109585:	89 54 24 04          	mov    %edx,0x4(%esp)
80109589:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010958c:	89 04 24             	mov    %eax,(%esp)
8010958f:	e8 51 f8 ff ff       	call   80108de5 <mappages>
80109594:	85 c0                	test   %eax,%eax
80109596:	78 1b                	js     801095b3 <copyuvm+0xfe>
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
80109598:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
8010959f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801095a2:	3b 45 0c             	cmp    0xc(%ebp),%eax
801095a5:	0f 82 34 ff ff ff    	jb     801094df <copyuvm+0x2a>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
  }
  return d;
801095ab:	8b 45 f0             	mov    -0x10(%ebp),%eax
801095ae:	eb 14                	jmp    801095c4 <copyuvm+0x10f>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
    if((mem = kalloc()) == 0)
      goto bad;
801095b0:	90                   	nop
801095b1:	eb 01                	jmp    801095b4 <copyuvm+0xff>
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
801095b3:	90                   	nop
  }
  return d;

bad:
  freevm(d);
801095b4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801095b7:	89 04 24             	mov    %eax,(%esp)
801095ba:	e8 22 fe ff ff       	call   801093e1 <freevm>
  return 0;
801095bf:	b8 00 00 00 00       	mov    $0x0,%eax
}
801095c4:	c9                   	leave  
801095c5:	c3                   	ret    

801095c6 <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
801095c6:	55                   	push   %ebp
801095c7:	89 e5                	mov    %esp,%ebp
801095c9:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801095cc:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801095d3:	00 
801095d4:	8b 45 0c             	mov    0xc(%ebp),%eax
801095d7:	89 44 24 04          	mov    %eax,0x4(%esp)
801095db:	8b 45 08             	mov    0x8(%ebp),%eax
801095de:	89 04 24             	mov    %eax,(%esp)
801095e1:	e8 69 f7 ff ff       	call   80108d4f <walkpgdir>
801095e6:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
801095e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801095ec:	8b 00                	mov    (%eax),%eax
801095ee:	83 e0 01             	and    $0x1,%eax
801095f1:	85 c0                	test   %eax,%eax
801095f3:	75 07                	jne    801095fc <uva2ka+0x36>
    return 0;
801095f5:	b8 00 00 00 00       	mov    $0x0,%eax
801095fa:	eb 25                	jmp    80109621 <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
801095fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801095ff:	8b 00                	mov    (%eax),%eax
80109601:	83 e0 04             	and    $0x4,%eax
80109604:	85 c0                	test   %eax,%eax
80109606:	75 07                	jne    8010960f <uva2ka+0x49>
    return 0;
80109608:	b8 00 00 00 00       	mov    $0x0,%eax
8010960d:	eb 12                	jmp    80109621 <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
8010960f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109612:	8b 00                	mov    (%eax),%eax
80109614:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109619:	89 04 24             	mov    %eax,(%esp)
8010961c:	e8 ab f2 ff ff       	call   801088cc <p2v>
}
80109621:	c9                   	leave  
80109622:	c3                   	ret    

80109623 <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
80109623:	55                   	push   %ebp
80109624:	89 e5                	mov    %esp,%ebp
80109626:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
80109629:	8b 45 10             	mov    0x10(%ebp),%eax
8010962c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
8010962f:	e9 8b 00 00 00       	jmp    801096bf <copyout+0x9c>
    va0 = (uint)PGROUNDDOWN(va);
80109634:	8b 45 0c             	mov    0xc(%ebp),%eax
80109637:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010963c:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
8010963f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109642:	89 44 24 04          	mov    %eax,0x4(%esp)
80109646:	8b 45 08             	mov    0x8(%ebp),%eax
80109649:	89 04 24             	mov    %eax,(%esp)
8010964c:	e8 75 ff ff ff       	call   801095c6 <uva2ka>
80109651:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
80109654:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80109658:	75 07                	jne    80109661 <copyout+0x3e>
      return -1;
8010965a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010965f:	eb 6d                	jmp    801096ce <copyout+0xab>
    n = PGSIZE - (va - va0);
80109661:	8b 45 0c             	mov    0xc(%ebp),%eax
80109664:	8b 55 ec             	mov    -0x14(%ebp),%edx
80109667:	89 d1                	mov    %edx,%ecx
80109669:	29 c1                	sub    %eax,%ecx
8010966b:	89 c8                	mov    %ecx,%eax
8010966d:	05 00 10 00 00       	add    $0x1000,%eax
80109672:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
80109675:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109678:	3b 45 14             	cmp    0x14(%ebp),%eax
8010967b:	76 06                	jbe    80109683 <copyout+0x60>
      n = len;
8010967d:	8b 45 14             	mov    0x14(%ebp),%eax
80109680:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
80109683:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109686:	8b 55 0c             	mov    0xc(%ebp),%edx
80109689:	89 d1                	mov    %edx,%ecx
8010968b:	29 c1                	sub    %eax,%ecx
8010968d:	89 c8                	mov    %ecx,%eax
8010968f:	03 45 e8             	add    -0x18(%ebp),%eax
80109692:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109695:	89 54 24 08          	mov    %edx,0x8(%esp)
80109699:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010969c:	89 54 24 04          	mov    %edx,0x4(%esp)
801096a0:	89 04 24             	mov    %eax,(%esp)
801096a3:	e8 45 c8 ff ff       	call   80105eed <memmove>
    len -= n;
801096a8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801096ab:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
801096ae:	8b 45 f0             	mov    -0x10(%ebp),%eax
801096b1:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
801096b4:	8b 45 ec             	mov    -0x14(%ebp),%eax
801096b7:	05 00 10 00 00       	add    $0x1000,%eax
801096bc:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
801096bf:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
801096c3:	0f 85 6b ff ff ff    	jne    80109634 <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
801096c9:	b8 00 00 00 00       	mov    $0x0,%eax
}
801096ce:	c9                   	leave  
801096cf:	c3                   	ret    
