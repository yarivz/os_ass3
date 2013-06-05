
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
8010002d:	b8 9b 39 10 80       	mov    $0x8010399b,%eax
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
8010003a:	c7 44 24 04 90 93 10 	movl   $0x80109390,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
80100049:	e8 e4 57 00 00       	call   80105832 <initlock>

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
801000bd:	e8 91 57 00 00       	call   80105853 <acquire>

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
80100104:	e8 e5 57 00 00       	call   801058ee <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 80 d6 10 	movl   $0x8010d680,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 f3 52 00 00       	call   80105417 <sleep>
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
8010017c:	e8 6d 57 00 00       	call   801058ee <release>
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
80100198:	c7 04 24 97 93 10 80 	movl   $0x80109397,(%esp)
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
801001ef:	c7 04 24 a8 93 10 80 	movl   $0x801093a8,(%esp)
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
80100229:	c7 04 24 af 93 10 80 	movl   $0x801093af,(%esp)
80100230:	e8 08 03 00 00       	call   8010053d <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
8010023c:	e8 12 56 00 00       	call   80105853 <acquire>

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
8010029d:	e8 b1 52 00 00       	call   80105553 <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
801002a9:	e8 40 56 00 00       	call   801058ee <release>
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
801003bc:	e8 92 54 00 00       	call   80105853 <acquire>

  if (fmt == 0)
801003c1:	8b 45 08             	mov    0x8(%ebp),%eax
801003c4:	85 c0                	test   %eax,%eax
801003c6:	75 0c                	jne    801003d4 <cprintf+0x33>
    panic("null fmt");
801003c8:	c7 04 24 b6 93 10 80 	movl   $0x801093b6,(%esp)
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
801004af:	c7 45 ec bf 93 10 80 	movl   $0x801093bf,-0x14(%ebp)
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
80100536:	e8 b3 53 00 00       	call   801058ee <release>
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
80100562:	c7 04 24 c6 93 10 80 	movl   $0x801093c6,(%esp)
80100569:	e8 33 fe ff ff       	call   801003a1 <cprintf>
  cprintf(s);
8010056e:	8b 45 08             	mov    0x8(%ebp),%eax
80100571:	89 04 24             	mov    %eax,(%esp)
80100574:	e8 28 fe ff ff       	call   801003a1 <cprintf>
  cprintf("\n");
80100579:	c7 04 24 d5 93 10 80 	movl   $0x801093d5,(%esp)
80100580:	e8 1c fe ff ff       	call   801003a1 <cprintf>
  getcallerpcs(&s, pcs);
80100585:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100588:	89 44 24 04          	mov    %eax,0x4(%esp)
8010058c:	8d 45 08             	lea    0x8(%ebp),%eax
8010058f:	89 04 24             	mov    %eax,(%esp)
80100592:	e8 a6 53 00 00       	call   8010593d <getcallerpcs>
  for(i=0; i<10; i++)
80100597:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010059e:	eb 1b                	jmp    801005bb <panic+0x7e>
    cprintf(" %p", pcs[i]);
801005a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005a3:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005a7:	89 44 24 04          	mov    %eax,0x4(%esp)
801005ab:	c7 04 24 d7 93 10 80 	movl   $0x801093d7,(%esp)
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
801006b2:	e8 f6 54 00 00       	call   80105bad <memmove>
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
801006e1:	e8 f4 53 00 00       	call   80105ada <memset>
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
80100776:	e8 7a 72 00 00       	call   801079f5 <uartputc>
8010077b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80100782:	e8 6e 72 00 00       	call   801079f5 <uartputc>
80100787:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
8010078e:	e8 62 72 00 00       	call   801079f5 <uartputc>
80100793:	eb 0b                	jmp    801007a0 <consputc+0x50>
  } else
    uartputc(c);
80100795:	8b 45 08             	mov    0x8(%ebp),%eax
80100798:	89 04 24             	mov    %eax,(%esp)
8010079b:	e8 55 72 00 00       	call   801079f5 <uartputc>
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
801007ba:	e8 94 50 00 00       	call   80105853 <acquire>
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
801007ea:	e8 2d 4e 00 00       	call   8010561c <procdump>
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
801008f7:	e8 57 4c 00 00       	call   80105553 <wakeup>
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
8010091e:	e8 cb 4f 00 00       	call   801058ee <release>
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
80100943:	e8 0b 4f 00 00       	call   80105853 <acquire>
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
80100961:	e8 88 4f 00 00       	call   801058ee <release>
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
8010098a:	e8 88 4a 00 00       	call   80105417 <sleep>
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
80100a08:	e8 e1 4e 00 00       	call   801058ee <release>
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
80100a3e:	e8 10 4e 00 00       	call   80105853 <acquire>
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
80100a78:	e8 71 4e 00 00       	call   801058ee <release>
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
80100a93:	c7 44 24 04 db 93 10 	movl   $0x801093db,0x4(%esp)
80100a9a:	80 
80100a9b:	c7 04 24 e0 c5 10 80 	movl   $0x8010c5e0,(%esp)
80100aa2:	e8 8b 4d 00 00       	call   80105832 <initlock>
  initlock(&input.lock, "input");
80100aa7:	c7 44 24 04 e3 93 10 	movl   $0x801093e3,0x4(%esp)
80100aae:	80 
80100aaf:	c7 04 24 c0 ed 10 80 	movl   $0x8010edc0,(%esp)
80100ab6:	e8 77 4d 00 00       	call   80105832 <initlock>

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
80100ae0:	e8 70 35 00 00       	call   80104055 <picenable>
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
80100b7b:	e8 b9 7f 00 00       	call   80108b39 <setupkvm>
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
80100c14:	e8 f2 82 00 00       	call   80108f0b <allocuvm>
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
80100c51:	e8 c6 81 00 00       	call   80108e1c <loaduvm>
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
80100cbc:	e8 4a 82 00 00       	call   80108f0b <allocuvm>
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
80100ce0:	e8 4a 84 00 00       	call   8010912f <clearpteu>
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
80100d0f:	e8 44 50 00 00       	call   80105d58 <strlen>
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
80100d2d:	e8 26 50 00 00       	call   80105d58 <strlen>
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
80100d57:	e8 87 85 00 00       	call   801092e3 <copyout>
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
80100df7:	e8 e7 84 00 00       	call   801092e3 <copyout>
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
80100e4e:	e8 b7 4e 00 00       	call   80105d0a <safestrcpy>

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
80100ea0:	e8 85 7d 00 00       	call   80108c2a <switchuvm>
  freevm(oldpgdir);
80100ea5:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100ea8:	89 04 24             	mov    %eax,(%esp)
80100eab:	e8 f1 81 00 00       	call   801090a1 <freevm>
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
80100ee2:	e8 ba 81 00 00       	call   801090a1 <freevm>
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
80100f06:	c7 44 24 04 e9 93 10 	movl   $0x801093e9,0x4(%esp)
80100f0d:	80 
80100f0e:	c7 04 24 80 ee 10 80 	movl   $0x8010ee80,(%esp)
80100f15:	e8 18 49 00 00       	call   80105832 <initlock>
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
80100f29:	e8 25 49 00 00       	call   80105853 <acquire>
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
80100f52:	e8 97 49 00 00       	call   801058ee <release>
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
80100f70:	e8 79 49 00 00       	call   801058ee <release>
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
80100f89:	e8 c5 48 00 00       	call   80105853 <acquire>
  if(f->ref < 1)
80100f8e:	8b 45 08             	mov    0x8(%ebp),%eax
80100f91:	8b 40 04             	mov    0x4(%eax),%eax
80100f94:	85 c0                	test   %eax,%eax
80100f96:	7f 0c                	jg     80100fa4 <filedup+0x28>
    panic("filedup");
80100f98:	c7 04 24 f0 93 10 80 	movl   $0x801093f0,(%esp)
80100f9f:	e8 99 f5 ff ff       	call   8010053d <panic>
  f->ref++;
80100fa4:	8b 45 08             	mov    0x8(%ebp),%eax
80100fa7:	8b 40 04             	mov    0x4(%eax),%eax
80100faa:	8d 50 01             	lea    0x1(%eax),%edx
80100fad:	8b 45 08             	mov    0x8(%ebp),%eax
80100fb0:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
80100fb3:	c7 04 24 80 ee 10 80 	movl   $0x8010ee80,(%esp)
80100fba:	e8 2f 49 00 00       	call   801058ee <release>
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
80100fd1:	e8 7d 48 00 00       	call   80105853 <acquire>
  if(f->ref < 1)
80100fd6:	8b 45 08             	mov    0x8(%ebp),%eax
80100fd9:	8b 40 04             	mov    0x4(%eax),%eax
80100fdc:	85 c0                	test   %eax,%eax
80100fde:	7f 0c                	jg     80100fec <fileclose+0x28>
    panic("fileclose");
80100fe0:	c7 04 24 f8 93 10 80 	movl   $0x801093f8,(%esp)
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
8010100c:	e8 dd 48 00 00       	call   801058ee <release>
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
80101056:	e8 93 48 00 00       	call   801058ee <release>
  
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
80101074:	e8 96 32 00 00       	call   8010430f <pipeclose>
80101079:	eb 1d                	jmp    80101098 <fileclose+0xd4>
  else if(ff.type == FD_INODE){
8010107b:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010107e:	83 f8 02             	cmp    $0x2,%eax
80101081:	75 15                	jne    80101098 <fileclose+0xd4>
    begin_trans();
80101083:	e8 29 27 00 00       	call   801037b1 <begin_trans>
    iput(ff.ip);
80101088:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010108b:	89 04 24             	mov    %eax,(%esp)
8010108e:	e8 88 09 00 00       	call   80101a1b <iput>
    commit_trans();
80101093:	e8 62 27 00 00       	call   801037fa <commit_trans>
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
80101125:	e8 67 33 00 00       	call   80104491 <piperead>
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
80101197:	c7 04 24 02 94 10 80 	movl   $0x80109402,(%esp)
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
801011e2:	e8 ba 31 00 00       	call   801043a1 <pipewrite>
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
8010122a:	e8 82 25 00 00       	call   801037b1 <begin_trans>
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
80101290:	e8 65 25 00 00       	call   801037fa <commit_trans>

      if(r < 0)
80101295:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80101299:	78 28                	js     801012c3 <filewrite+0x11e>
        break;
      if(r != n1)
8010129b:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010129e:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801012a1:	74 0c                	je     801012af <filewrite+0x10a>
        panic("short filewrite");
801012a3:	c7 04 24 0b 94 10 80 	movl   $0x8010940b,(%esp)
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
801012d8:	c7 04 24 1b 94 10 80 	movl   $0x8010941b,(%esp)
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
80101320:	e8 88 48 00 00       	call   80105bad <memmove>
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
80101366:	e8 6f 47 00 00       	call   80105ada <memset>
  log_write(bp);
8010136b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010136e:	89 04 24             	mov    %eax,(%esp)
80101371:	e8 dc 24 00 00       	call   80103852 <log_write>
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
80101457:	e8 f6 23 00 00       	call   80103852 <log_write>
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
801014ce:	c7 04 24 25 94 10 80 	movl   $0x80109425,(%esp)
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
80101565:	c7 04 24 3b 94 10 80 	movl   $0x8010943b,(%esp)
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
8010159d:	e8 b0 22 00 00       	call   80103852 <log_write>
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
801015b9:	c7 44 24 04 4e 94 10 	movl   $0x8010944e,0x4(%esp)
801015c0:	80 
801015c1:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
801015c8:	e8 65 42 00 00       	call   80105832 <initlock>
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
8010164a:	e8 8b 44 00 00       	call   80105ada <memset>
      dip->type = type;
8010164f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101652:	0f b7 55 d4          	movzwl -0x2c(%ebp),%edx
80101656:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
80101659:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010165c:	89 04 24             	mov    %eax,(%esp)
8010165f:	e8 ee 21 00 00       	call   80103852 <log_write>
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
801016a0:	c7 04 24 55 94 10 80 	movl   $0x80109455,(%esp)
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
80101747:	e8 61 44 00 00       	call   80105bad <memmove>
  log_write(bp);
8010174c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010174f:	89 04 24             	mov    %eax,(%esp)
80101752:	e8 fb 20 00 00       	call   80103852 <log_write>
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
80101771:	e8 dd 40 00 00       	call   80105853 <acquire>

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
801017bb:	e8 2e 41 00 00       	call   801058ee <release>
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
801017ee:	c7 04 24 67 94 10 80 	movl   $0x80109467,(%esp)
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
8010182c:	e8 bd 40 00 00       	call   801058ee <release>

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
80101843:	e8 0b 40 00 00       	call   80105853 <acquire>
  ip->ref++;
80101848:	8b 45 08             	mov    0x8(%ebp),%eax
8010184b:	8b 40 08             	mov    0x8(%eax),%eax
8010184e:	8d 50 01             	lea    0x1(%eax),%edx
80101851:	8b 45 08             	mov    0x8(%ebp),%eax
80101854:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101857:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
8010185e:	e8 8b 40 00 00       	call   801058ee <release>
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
8010187e:	c7 04 24 77 94 10 80 	movl   $0x80109477,(%esp)
80101885:	e8 b3 ec ff ff       	call   8010053d <panic>

  acquire(&icache.lock);
8010188a:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
80101891:	e8 bd 3f 00 00       	call   80105853 <acquire>
  while(ip->flags & I_BUSY)
80101896:	eb 13                	jmp    801018ab <ilock+0x43>
    sleep(ip, &icache.lock);
80101898:	c7 44 24 04 80 f8 10 	movl   $0x8010f880,0x4(%esp)
8010189f:	80 
801018a0:	8b 45 08             	mov    0x8(%ebp),%eax
801018a3:	89 04 24             	mov    %eax,(%esp)
801018a6:	e8 6c 3b 00 00       	call   80105417 <sleep>

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
801018d0:	e8 19 40 00 00       	call   801058ee <release>

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
8010197b:	e8 2d 42 00 00       	call   80105bad <memmove>
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
801019a8:	c7 04 24 7d 94 10 80 	movl   $0x8010947d,(%esp)
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
801019d9:	c7 04 24 8c 94 10 80 	movl   $0x8010948c,(%esp)
801019e0:	e8 58 eb ff ff       	call   8010053d <panic>
  acquire(&icache.lock);
801019e5:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
801019ec:	e8 62 3e 00 00       	call   80105853 <acquire>
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
80101a08:	e8 46 3b 00 00       	call   80105553 <wakeup>
  release(&icache.lock);
80101a0d:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
80101a14:	e8 d5 3e 00 00       	call   801058ee <release>
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
80101a28:	e8 26 3e 00 00       	call   80105853 <acquire>
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
80101a66:	c7 04 24 94 94 10 80 	movl   $0x80109494,(%esp)
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
80101a8a:	e8 5f 3e 00 00       	call   801058ee <release>
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
80101ab5:	e8 99 3d 00 00       	call   80105853 <acquire>
    ip->flags = 0;
80101aba:	8b 45 08             	mov    0x8(%ebp),%eax
80101abd:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
80101ac4:	8b 45 08             	mov    0x8(%ebp),%eax
80101ac7:	89 04 24             	mov    %eax,(%esp)
80101aca:	e8 84 3a 00 00       	call   80105553 <wakeup>
  }
  ip->ref--;
80101acf:	8b 45 08             	mov    0x8(%ebp),%eax
80101ad2:	8b 40 08             	mov    0x8(%eax),%eax
80101ad5:	8d 50 ff             	lea    -0x1(%eax),%edx
80101ad8:	8b 45 08             	mov    0x8(%ebp),%eax
80101adb:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101ade:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
80101ae5:	e8 04 3e 00 00       	call   801058ee <release>
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
80101be5:	e8 68 1c 00 00       	call   80103852 <log_write>
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
80101bfa:	c7 04 24 9e 94 10 80 	movl   $0x8010949e,(%esp)
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
80101e92:	e8 16 3d 00 00       	call   80105bad <memmove>
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
80101ff8:	e8 b0 3b 00 00       	call   80105bad <memmove>
    log_write(bp);
80101ffd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102000:	89 04 24             	mov    %eax,(%esp)
80102003:	e8 4a 18 00 00       	call   80103852 <log_write>
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
8010207a:	e8 d2 3b 00 00       	call   80105c51 <strncmp>
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
80102094:	c7 04 24 b1 94 10 80 	movl   $0x801094b1,(%esp)
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
801020d2:	c7 04 24 c3 94 10 80 	movl   $0x801094c3,(%esp)
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
801021b6:	c7 04 24 c3 94 10 80 	movl   $0x801094c3,(%esp)
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
801021fc:	e8 a8 3a 00 00       	call   80105ca9 <strncpy>
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
8010222e:	c7 04 24 d0 94 10 80 	movl   $0x801094d0,(%esp)
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
801022b5:	e8 f3 38 00 00       	call   80105bad <memmove>
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
801022d0:	e8 d8 38 00 00       	call   80105bad <memmove>
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
80102532:	c7 44 24 04 d8 94 10 	movl   $0x801094d8,0x4(%esp)
80102539:	80 
8010253a:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
80102541:	e8 ec 32 00 00       	call   80105832 <initlock>
  picenable(IRQ_IDE);
80102546:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
8010254d:	e8 03 1b 00 00       	call   80104055 <picenable>
  ioapicenable(IRQ_IDE, ncpu - 1);
80102552:	a1 60 3f 11 80       	mov    0x80113f60,%eax
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
801025de:	c7 04 24 dc 94 10 80 	movl   $0x801094dc,(%esp)
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
80102704:	e8 4a 31 00 00       	call   80105853 <acquire>
  if((b = idequeue) == 0){
80102709:	a1 54 c6 10 80       	mov    0x8010c654,%eax
8010270e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102711:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102715:	75 11                	jne    80102728 <ideintr+0x31>
    release(&idelock);
80102717:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
8010271e:	e8 cb 31 00 00       	call   801058ee <release>
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
801027a8:	e8 41 31 00 00       	call   801058ee <release>
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
801027c1:	c7 04 24 e5 94 10 80 	movl   $0x801094e5,(%esp)
801027c8:	e8 70 dd ff ff       	call   8010053d <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
801027cd:	8b 45 08             	mov    0x8(%ebp),%eax
801027d0:	8b 00                	mov    (%eax),%eax
801027d2:	83 e0 06             	and    $0x6,%eax
801027d5:	83 f8 02             	cmp    $0x2,%eax
801027d8:	75 0c                	jne    801027e6 <iderw+0x37>
    panic("iderw: nothing to do");
801027da:	c7 04 24 f9 94 10 80 	movl   $0x801094f9,(%esp)
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
801027f9:	c7 04 24 0e 95 10 80 	movl   $0x8010950e,(%esp)
80102800:	e8 38 dd ff ff       	call   8010053d <panic>

  acquire(&idelock);  //DOC: acquire-lock
80102805:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
8010280c:	e8 42 30 00 00       	call   80105853 <acquire>

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
8010285e:	e8 8b 30 00 00       	call   801058ee <release>
	sti();
80102863:	e8 7a fc ff ff       	call   801024e2 <sti>
	acquire(&idelock); 
80102868:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
8010286f:	e8 df 2f 00 00       	call   80105853 <acquire>
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
8010288b:	e8 5e 30 00 00       	call   801058ee <release>
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
801028cb:	a1 64 39 11 80       	mov    0x80113964,%eax
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
8010290b:	0f b6 05 60 39 11 80 	movzbl 0x80113960,%eax
80102912:	0f b6 c0             	movzbl %al,%eax
80102915:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80102918:	74 0c                	je     80102926 <ioapicinit+0x61>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
8010291a:	c7 04 24 2c 95 10 80 	movl   $0x8010952c,(%esp)
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
80102980:	a1 64 39 11 80       	mov    0x80113964,%eax
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
801029e8:	c7 44 24 04 60 95 10 	movl   $0x80109560,0x4(%esp)
801029ef:	80 
801029f0:	c7 04 24 60 08 11 80 	movl   $0x80110860,(%esp)
801029f7:	e8 36 2e 00 00       	call   80105832 <initlock>
  kmem.use_lock = 0;
801029fc:	c7 05 94 08 11 80 00 	movl   $0x0,0x80110894
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
80102a32:	c7 05 94 08 11 80 01 	movl   $0x1,0x80110894
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
80102a89:	81 7d 08 5c 6b 11 80 	cmpl   $0x80116b5c,0x8(%ebp)
80102a90:	72 12                	jb     80102aa4 <kfree+0x2d>
80102a92:	8b 45 08             	mov    0x8(%ebp),%eax
80102a95:	89 04 24             	mov    %eax,(%esp)
80102a98:	e8 2b ff ff ff       	call   801029c8 <v2p>
80102a9d:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80102aa2:	76 0c                	jbe    80102ab0 <kfree+0x39>
    panic("kfree");
80102aa4:	c7 04 24 65 95 10 80 	movl   $0x80109565,(%esp)
80102aab:	e8 8d da ff ff       	call   8010053d <panic>

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80102ab0:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80102ab7:	00 
80102ab8:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102abf:	00 
80102ac0:	8b 45 08             	mov    0x8(%ebp),%eax
80102ac3:	89 04 24             	mov    %eax,(%esp)
80102ac6:	e8 0f 30 00 00       	call   80105ada <memset>

  if(kmem.use_lock)
80102acb:	a1 94 08 11 80       	mov    0x80110894,%eax
80102ad0:	85 c0                	test   %eax,%eax
80102ad2:	74 0c                	je     80102ae0 <kfree+0x69>
    acquire(&kmem.lock);
80102ad4:	c7 04 24 60 08 11 80 	movl   $0x80110860,(%esp)
80102adb:	e8 73 2d 00 00       	call   80105853 <acquire>
  r = (struct run*)v;
80102ae0:	8b 45 08             	mov    0x8(%ebp),%eax
80102ae3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
80102ae6:	8b 15 98 08 11 80    	mov    0x80110898,%edx
80102aec:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102aef:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
80102af1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102af4:	a3 98 08 11 80       	mov    %eax,0x80110898
  if(kmem.use_lock)
80102af9:	a1 94 08 11 80       	mov    0x80110894,%eax
80102afe:	85 c0                	test   %eax,%eax
80102b00:	74 0c                	je     80102b0e <kfree+0x97>
    release(&kmem.lock);
80102b02:	c7 04 24 60 08 11 80 	movl   $0x80110860,(%esp)
80102b09:	e8 e0 2d 00 00       	call   801058ee <release>
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
80102b16:	a1 94 08 11 80       	mov    0x80110894,%eax
80102b1b:	85 c0                	test   %eax,%eax
80102b1d:	74 0c                	je     80102b2b <kalloc+0x1b>
    acquire(&kmem.lock);
80102b1f:	c7 04 24 60 08 11 80 	movl   $0x80110860,(%esp)
80102b26:	e8 28 2d 00 00       	call   80105853 <acquire>
  r = kmem.freelist;
80102b2b:	a1 98 08 11 80       	mov    0x80110898,%eax
80102b30:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
80102b33:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102b37:	74 0a                	je     80102b43 <kalloc+0x33>
    kmem.freelist = r->next;
80102b39:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b3c:	8b 00                	mov    (%eax),%eax
80102b3e:	a3 98 08 11 80       	mov    %eax,0x80110898
  if(kmem.use_lock)
80102b43:	a1 94 08 11 80       	mov    0x80110894,%eax
80102b48:	85 c0                	test   %eax,%eax
80102b4a:	74 0c                	je     80102b58 <kalloc+0x48>
    release(&kmem.lock);
80102b4c:	c7 04 24 60 08 11 80 	movl   $0x80110860,(%esp)
80102b53:	e8 96 2d 00 00       	call   801058ee <release>
  return (char*)r;
80102b58:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102b5b:	c9                   	leave  
80102b5c:	c3                   	ret    

80102b5d <shmget>:


int shmget(int key, uint size, int shmflg)
{
80102b5d:	55                   	push   %ebp
80102b5e:	89 e5                	mov    %esp,%ebp
80102b60:	83 ec 28             	sub    $0x28,%esp
  int numOfPages,i,ans;
  if(kmem.use_lock)
80102b63:	a1 94 08 11 80       	mov    0x80110894,%eax
80102b68:	85 c0                	test   %eax,%eax
80102b6a:	74 0c                	je     80102b78 <shmget+0x1b>
    acquire(&kmem.lock);
80102b6c:	c7 04 24 60 08 11 80 	movl   $0x80110860,(%esp)
80102b73:	e8 db 2c 00 00       	call   80105853 <acquire>
  switch(shmflg)
80102b78:	8b 45 10             	mov    0x10(%ebp),%eax
80102b7b:	83 f8 14             	cmp    $0x14,%eax
80102b7e:	74 0e                	je     80102b8e <shmget+0x31>
80102b80:	83 f8 15             	cmp    $0x15,%eax
80102b83:	0f 84 c8 00 00 00    	je     80102c51 <shmget+0xf4>
80102b89:	e9 e8 00 00 00       	jmp    80102c76 <shmget+0x119>
  {
    case CREAT:
      if(!shm.refs[key][1])
80102b8e:	8b 45 08             	mov    0x8(%ebp),%eax
80102b91:	8b 04 c5 a4 18 11 80 	mov    -0x7feee75c(,%eax,8),%eax
80102b98:	85 c0                	test   %eax,%eax
80102b9a:	0f 85 a8 00 00 00    	jne    80102c48 <shmget+0xeb>
      {
	struct run* r = kmem.freelist;
80102ba0:	a1 98 08 11 80       	mov    0x80110898,%eax
80102ba5:	89 45 ec             	mov    %eax,-0x14(%ebp)
	size = PGROUNDUP(size);
80102ba8:	8b 45 0c             	mov    0xc(%ebp),%eax
80102bab:	05 ff 0f 00 00       	add    $0xfff,%eax
80102bb0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80102bb5:	89 45 0c             	mov    %eax,0xc(%ebp)
	numOfPages = size/PGSIZE;
80102bb8:	8b 45 0c             	mov    0xc(%ebp),%eax
80102bbb:	c1 e8 0c             	shr    $0xc,%eax
80102bbe:	89 45 e8             	mov    %eax,-0x18(%ebp)
	shm.seg[key] = (kmem.freelist);
80102bc1:	8b 15 98 08 11 80    	mov    0x80110898,%edx
80102bc7:	8b 45 08             	mov    0x8(%ebp),%eax
80102bca:	89 14 85 a0 08 11 80 	mov    %edx,-0x7feef760(,%eax,4)
	
	for(i=0;i<numOfPages;i++)
80102bd1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102bd8:	eb 0c                	jmp    80102be6 <shmget+0x89>
	{
	  r = r->next;
80102bda:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102bdd:	8b 00                	mov    (%eax),%eax
80102bdf:	89 45 ec             	mov    %eax,-0x14(%ebp)
	struct run* r = kmem.freelist;
	size = PGROUNDUP(size);
	numOfPages = size/PGSIZE;
	shm.seg[key] = (kmem.freelist);
	
	for(i=0;i<numOfPages;i++)
80102be2:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102be6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102be9:	3b 45 e8             	cmp    -0x18(%ebp),%eax
80102bec:	7c ec                	jl     80102bda <shmget+0x7d>
	{
	  r = r->next;
	}
	
	if(i == numOfPages)
80102bee:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102bf1:	3b 45 e8             	cmp    -0x18(%ebp),%eax
80102bf4:	75 49                	jne    80102c3f <shmget+0xe2>
	{
	  for(;kmem.freelist->next!=r;kmem.freelist = kmem.freelist->next);
80102bf6:	eb 0c                	jmp    80102c04 <shmget+0xa7>
80102bf8:	a1 98 08 11 80       	mov    0x80110898,%eax
80102bfd:	8b 00                	mov    (%eax),%eax
80102bff:	a3 98 08 11 80       	mov    %eax,0x80110898
80102c04:	a1 98 08 11 80       	mov    0x80110898,%eax
80102c09:	8b 00                	mov    (%eax),%eax
80102c0b:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80102c0e:	75 e8                	jne    80102bf8 <shmget+0x9b>
	  kmem.freelist->next = 0;
80102c10:	a1 98 08 11 80       	mov    0x80110898,%eax
80102c15:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	  kmem.freelist = r;
80102c1b:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102c1e:	a3 98 08 11 80       	mov    %eax,0x80110898
	  ans = (int)shm.seg[key];
80102c23:	8b 45 08             	mov    0x8(%ebp),%eax
80102c26:	8b 04 85 a0 08 11 80 	mov    -0x7feef760(,%eax,4),%eax
80102c2d:	89 45 f0             	mov    %eax,-0x10(%ebp)
	  shm.refs[key][1] = numOfPages;
80102c30:	8b 45 08             	mov    0x8(%ebp),%eax
80102c33:	8b 55 e8             	mov    -0x18(%ebp),%edx
80102c36:	89 14 c5 a4 18 11 80 	mov    %edx,-0x7feee75c(,%eax,8)
	}
	else
	  ans = -1;
	break;
80102c3d:	eb 37                	jmp    80102c76 <shmget+0x119>
	  kmem.freelist = r;
	  ans = (int)shm.seg[key];
	  shm.refs[key][1] = numOfPages;
	}
	else
	  ans = -1;
80102c3f:	c7 45 f0 ff ff ff ff 	movl   $0xffffffff,-0x10(%ebp)
	break;
80102c46:	eb 2e                	jmp    80102c76 <shmget+0x119>
      }
      else
	ans = -1;
80102c48:	c7 45 f0 ff ff ff ff 	movl   $0xffffffff,-0x10(%ebp)
      break;
80102c4f:	eb 25                	jmp    80102c76 <shmget+0x119>
    case GET:
      if(!shm.refs[key][1])
80102c51:	8b 45 08             	mov    0x8(%ebp),%eax
80102c54:	8b 04 c5 a4 18 11 80 	mov    -0x7feee75c(,%eax,8),%eax
80102c5b:	85 c0                	test   %eax,%eax
80102c5d:	75 09                	jne    80102c68 <shmget+0x10b>
	ans = -1;
80102c5f:	c7 45 f0 ff ff ff ff 	movl   $0xffffffff,-0x10(%ebp)
      else
	ans = (int)shm.seg[key];
      break;
80102c66:	eb 0d                	jmp    80102c75 <shmget+0x118>
      break;
    case GET:
      if(!shm.refs[key][1])
	ans = -1;
      else
	ans = (int)shm.seg[key];
80102c68:	8b 45 08             	mov    0x8(%ebp),%eax
80102c6b:	8b 04 85 a0 08 11 80 	mov    -0x7feef760(,%eax,4),%eax
80102c72:	89 45 f0             	mov    %eax,-0x10(%ebp)
      break;
80102c75:	90                   	nop
  }
  if(kmem.use_lock)
80102c76:	a1 94 08 11 80       	mov    0x80110894,%eax
80102c7b:	85 c0                	test   %eax,%eax
80102c7d:	74 0c                	je     80102c8b <shmget+0x12e>
    release(&kmem.lock);
80102c7f:	c7 04 24 60 08 11 80 	movl   $0x80110860,(%esp)
80102c86:	e8 63 2c 00 00       	call   801058ee <release>
  return ans;
80102c8b:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80102c8e:	c9                   	leave  
80102c8f:	c3                   	ret    

80102c90 <shmdel>:

int shmdel(int shmid)
{
80102c90:	55                   	push   %ebp
80102c91:	89 e5                	mov    %esp,%ebp
80102c93:	83 ec 28             	sub    $0x28,%esp
  int key,ans = -1,numOfPages;
80102c96:	c7 45 f0 ff ff ff ff 	movl   $0xffffffff,-0x10(%ebp)
  struct run* r;
  if(kmem.use_lock)
80102c9d:	a1 94 08 11 80       	mov    0x80110894,%eax
80102ca2:	85 c0                	test   %eax,%eax
80102ca4:	74 0c                	je     80102cb2 <shmdel+0x22>
    acquire(&kmem.lock);
80102ca6:	c7 04 24 60 08 11 80 	movl   $0x80110860,(%esp)
80102cad:	e8 a1 2b 00 00       	call   80105853 <acquire>
  for(key = 0;key<numOfSegs;key++)
80102cb2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102cb9:	e9 a4 00 00 00       	jmp    80102d62 <shmdel+0xd2>
  {
    if(shmid == (int)shm.seg[key])
80102cbe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102cc1:	8b 04 85 a0 08 11 80 	mov    -0x7feef760(,%eax,4),%eax
80102cc8:	3b 45 08             	cmp    0x8(%ebp),%eax
80102ccb:	0f 85 8d 00 00 00    	jne    80102d5e <shmdel+0xce>
    {
      if(shm.refs[key][0])
80102cd1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102cd4:	05 00 02 00 00       	add    $0x200,%eax
80102cd9:	8b 04 c5 a0 08 11 80 	mov    -0x7feef760(,%eax,8),%eax
80102ce0:	85 c0                	test   %eax,%eax
80102ce2:	0f 85 89 00 00 00    	jne    80102d71 <shmdel+0xe1>
	break;
      else
      {
	for(r = shm.seg[key],numOfPages=1;r->next;r = r->next,numOfPages++)
80102ce8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102ceb:	8b 04 85 a0 08 11 80 	mov    -0x7feef760(,%eax,4),%eax
80102cf2:	89 45 e8             	mov    %eax,-0x18(%ebp)
80102cf5:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
80102cfc:	eb 27                	jmp    80102d25 <shmdel+0x95>
	{
	  // Fill with junk to catch dangling refs.
	  memset(r, 1, PGSIZE);
80102cfe:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80102d05:	00 
80102d06:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102d0d:	00 
80102d0e:	8b 45 e8             	mov    -0x18(%ebp),%eax
80102d11:	89 04 24             	mov    %eax,(%esp)
80102d14:	e8 c1 2d 00 00       	call   80105ada <memset>
    {
      if(shm.refs[key][0])
	break;
      else
      {
	for(r = shm.seg[key],numOfPages=1;r->next;r = r->next,numOfPages++)
80102d19:	8b 45 e8             	mov    -0x18(%ebp),%eax
80102d1c:	8b 00                	mov    (%eax),%eax
80102d1e:	89 45 e8             	mov    %eax,-0x18(%ebp)
80102d21:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
80102d25:	8b 45 e8             	mov    -0x18(%ebp),%eax
80102d28:	8b 00                	mov    (%eax),%eax
80102d2a:	85 c0                	test   %eax,%eax
80102d2c:	75 d0                	jne    80102cfe <shmdel+0x6e>
	{
	  // Fill with junk to catch dangling refs.
	  memset(r, 1, PGSIZE);
	}
	r->next = kmem.freelist;
80102d2e:	8b 15 98 08 11 80    	mov    0x80110898,%edx
80102d34:	8b 45 e8             	mov    -0x18(%ebp),%eax
80102d37:	89 10                	mov    %edx,(%eax)
	kmem.freelist = shm.seg[key];
80102d39:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d3c:	8b 04 85 a0 08 11 80 	mov    -0x7feef760(,%eax,4),%eax
80102d43:	a3 98 08 11 80       	mov    %eax,0x80110898
	shm.refs[key][1] = 0;
80102d48:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d4b:	c7 04 c5 a4 18 11 80 	movl   $0x0,-0x7feee75c(,%eax,8)
80102d52:	00 00 00 00 
	ans = numOfPages;
80102d56:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102d59:	89 45 f0             	mov    %eax,-0x10(%ebp)
      }
      break;
80102d5c:	eb 14                	jmp    80102d72 <shmdel+0xe2>
{
  int key,ans = -1,numOfPages;
  struct run* r;
  if(kmem.use_lock)
    acquire(&kmem.lock);
  for(key = 0;key<numOfSegs;key++)
80102d5e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102d62:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
80102d69:	0f 8e 4f ff ff ff    	jle    80102cbe <shmdel+0x2e>
80102d6f:	eb 01                	jmp    80102d72 <shmdel+0xe2>
  {
    if(shmid == (int)shm.seg[key])
    {
      if(shm.refs[key][0])
	break;
80102d71:	90                   	nop
	ans = numOfPages;
      }
      break;
    }
  }
  if(kmem.use_lock)
80102d72:	a1 94 08 11 80       	mov    0x80110894,%eax
80102d77:	85 c0                	test   %eax,%eax
80102d79:	74 0c                	je     80102d87 <shmdel+0xf7>
    release(&kmem.lock);
80102d7b:	c7 04 24 60 08 11 80 	movl   $0x80110860,(%esp)
80102d82:	e8 67 2b 00 00       	call   801058ee <release>
  
  return ans;
80102d87:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80102d8a:	c9                   	leave  
80102d8b:	c3                   	ret    

80102d8c <shmat>:

void *shmat(int shmid, int shmflg)
{
80102d8c:	55                   	push   %ebp
80102d8d:	89 e5                	mov    %esp,%ebp
80102d8f:	83 ec 48             	sub    $0x48,%esp
  int key,forFlag=0;
80102d92:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  struct run* r;
  void* ans;
  char* mem;
  uint a;

  acquire(&shm.lock);
80102d99:	c7 04 24 a0 38 11 80 	movl   $0x801138a0,(%esp)
80102da0:	e8 ae 2a 00 00       	call   80105853 <acquire>
  for(key = 0;key<numOfSegs;key++)
80102da5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102dac:	e9 62 01 00 00       	jmp    80102f13 <shmat+0x187>
  {
    if(shmid == (int)shm.seg[key])
80102db1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102db4:	8b 04 85 a0 08 11 80 	mov    -0x7feef760(,%eax,4),%eax
80102dbb:	3b 45 08             	cmp    0x8(%ebp),%eax
80102dbe:	0f 85 4b 01 00 00    	jne    80102f0f <shmat+0x183>
    {
      if(shm.refs[key][1])
80102dc4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102dc7:	8b 04 c5 a4 18 11 80 	mov    -0x7feee75c(,%eax,8),%eax
80102dce:	85 c0                	test   %eax,%eax
80102dd0:	0f 84 30 01 00 00    	je     80102f06 <shmat+0x17a>
      {
	a = PGROUNDUP(proc->sz);
80102dd6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80102ddc:	8b 00                	mov    (%eax),%eax
80102dde:	05 ff 0f 00 00       	add    $0xfff,%eax
80102de3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80102de8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ans = (void*)a;
80102deb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102dee:	89 45 e8             	mov    %eax,-0x18(%ebp)
	if(a + PGSIZE >= KERNBASE)
80102df1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102df4:	05 00 10 00 00       	add    $0x1000,%eax
80102df9:	85 c0                	test   %eax,%eax
80102dfb:	79 0c                	jns    80102e09 <shmat+0x7d>
	{
	  ans = (void*)-1;
80102dfd:	c7 45 e8 ff ff ff ff 	movl   $0xffffffff,-0x18(%ebp)
	  break;
80102e04:	e9 1a 01 00 00       	jmp    80102f23 <shmat+0x197>
	}
	
	shm.refs[key][0]++;
80102e09:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e0c:	05 00 02 00 00       	add    $0x200,%eax
80102e11:	8b 04 c5 a0 08 11 80 	mov    -0x7feef760(,%eax,8),%eax
80102e18:	8d 50 01             	lea    0x1(%eax),%edx
80102e1b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e1e:	05 00 02 00 00       	add    $0x200,%eax
80102e23:	89 14 c5 a0 08 11 80 	mov    %edx,-0x7feef760(,%eax,8)
	
	for(r = shm.seg[key];r && a < KERNBASE;r = r->next,a += PGSIZE)
80102e2a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e2d:	8b 04 85 a0 08 11 80 	mov    -0x7feef760(,%eax,4),%eax
80102e34:	89 45 ec             	mov    %eax,-0x14(%ebp)
80102e37:	e9 a6 00 00 00       	jmp    80102ee2 <shmat+0x156>
	{
	    forFlag = 1;
80102e3c:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
	    mem = (char*)r;
80102e43:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102e46:	89 45 e0             	mov    %eax,-0x20(%ebp)
	    
	    switch(shmflg)
80102e49:	8b 45 0c             	mov    0xc(%ebp),%eax
80102e4c:	83 f8 16             	cmp    $0x16,%eax
80102e4f:	74 07                	je     80102e58 <shmat+0xcc>
80102e51:	83 f8 17             	cmp    $0x17,%eax
80102e54:	74 3c                	je     80102e92 <shmat+0x106>
80102e56:	eb 74                	jmp    80102ecc <shmat+0x140>
	    {
	      case SHM_RDONLY:
		mappages(proc->pgdir, (char*)a, PGSIZE, v2p(mem), PTE_U);
80102e58:	8b 45 e0             	mov    -0x20(%ebp),%eax
80102e5b:	89 04 24             	mov    %eax,(%esp)
80102e5e:	e8 65 fb ff ff       	call   801029c8 <v2p>
80102e63:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80102e66:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80102e6d:	8b 52 04             	mov    0x4(%edx),%edx
80102e70:	c7 44 24 10 04 00 00 	movl   $0x4,0x10(%esp)
80102e77:	00 
80102e78:	89 44 24 0c          	mov    %eax,0xc(%esp)
80102e7c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80102e83:	00 
80102e84:	89 4c 24 04          	mov    %ecx,0x4(%esp)
80102e88:	89 14 24             	mov    %edx,(%esp)
80102e8b:	e8 15 5c 00 00       	call   80108aa5 <mappages>
		break;
80102e90:	eb 41                	jmp    80102ed3 <shmat+0x147>
	      case SHM_RDWR:
		mappages(proc->pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
80102e92:	8b 45 e0             	mov    -0x20(%ebp),%eax
80102e95:	89 04 24             	mov    %eax,(%esp)
80102e98:	e8 2b fb ff ff       	call   801029c8 <v2p>
80102e9d:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80102ea0:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80102ea7:	8b 52 04             	mov    0x4(%edx),%edx
80102eaa:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80102eb1:	00 
80102eb2:	89 44 24 0c          	mov    %eax,0xc(%esp)
80102eb6:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80102ebd:	00 
80102ebe:	89 4c 24 04          	mov    %ecx,0x4(%esp)
80102ec2:	89 14 24             	mov    %edx,(%esp)
80102ec5:	e8 db 5b 00 00       	call   80108aa5 <mappages>
		break;
80102eca:	eb 07                	jmp    80102ed3 <shmat+0x147>
	      default:
		forFlag = 0;
80102ecc:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
	  break;
	}
	
	shm.refs[key][0]++;
	
	for(r = shm.seg[key];r && a < KERNBASE;r = r->next,a += PGSIZE)
80102ed3:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102ed6:	8b 00                	mov    (%eax),%eax
80102ed8:	89 45 ec             	mov    %eax,-0x14(%ebp)
80102edb:	81 45 e4 00 10 00 00 	addl   $0x1000,-0x1c(%ebp)
80102ee2:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80102ee6:	74 0b                	je     80102ef3 <shmat+0x167>
80102ee8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102eeb:	85 c0                	test   %eax,%eax
80102eed:	0f 89 49 ff ff ff    	jns    80102e3c <shmat+0xb0>
		break;
	      default:
		forFlag = 0;
	    } 
	}
	if(forFlag)
80102ef3:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80102ef7:	74 29                	je     80102f22 <shmat+0x196>
	  proc->sz = a;
80102ef9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80102eff:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80102f02:	89 10                	mov    %edx,(%eax)
	break;
80102f04:	eb 1c                	jmp    80102f22 <shmat+0x196>
      }
      else
      {
	ans = (void*)-1;
80102f06:	c7 45 e8 ff ff ff ff 	movl   $0xffffffff,-0x18(%ebp)
	break;
80102f0d:	eb 14                	jmp    80102f23 <shmat+0x197>
  void* ans;
  char* mem;
  uint a;

  acquire(&shm.lock);
  for(key = 0;key<numOfSegs;key++)
80102f0f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102f13:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
80102f1a:	0f 8e 91 fe ff ff    	jle    80102db1 <shmat+0x25>
80102f20:	eb 01                	jmp    80102f23 <shmat+0x197>
		forFlag = 0;
	    } 
	}
	if(forFlag)
	  proc->sz = a;
	break;
80102f22:	90                   	nop
      }
    }
  }
  
  
  release(&shm.lock);
80102f23:	c7 04 24 a0 38 11 80 	movl   $0x801138a0,(%esp)
80102f2a:	e8 bf 29 00 00       	call   801058ee <release>
  
  return ans;
80102f2f:	8b 45 e8             	mov    -0x18(%ebp),%eax
}
80102f32:	c9                   	leave  
80102f33:	c3                   	ret    

80102f34 <shmdt>:

int shmdt(const void *shmaddr)
{
80102f34:	55                   	push   %ebp
80102f35:	89 e5                	mov    %esp,%ebp
80102f37:	83 ec 38             	sub    $0x38,%esp
 
  pte_t *pte;
  uint r, numOfPages;
  int key,found;
  cprintf("before wlkpgdir\n");
80102f3a:	c7 04 24 6b 95 10 80 	movl   $0x8010956b,(%esp)
80102f41:	e8 5b d4 ff ff       	call   801003a1 <cprintf>
  pte = walkpgdir(proc->pgdir, (char*)shmaddr, 0);
80102f46:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80102f4c:	8b 40 04             	mov    0x4(%eax),%eax
80102f4f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80102f56:	00 
80102f57:	8b 55 08             	mov    0x8(%ebp),%edx
80102f5a:	89 54 24 04          	mov    %edx,0x4(%esp)
80102f5e:	89 04 24             	mov    %eax,(%esp)
80102f61:	e8 a9 5a 00 00       	call   80108a0f <walkpgdir>
80102f66:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  r = (int)p2v(*pte) ;
80102f69:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102f6c:	8b 00                	mov    (%eax),%eax
80102f6e:	89 04 24             	mov    %eax,(%esp)
80102f71:	e8 5f fa ff ff       	call   801029d5 <p2v>
80102f76:	89 45 e0             	mov    %eax,-0x20(%ebp)
  acquire(&shm.lock);
80102f79:	c7 04 24 a0 38 11 80 	movl   $0x801138a0,(%esp)
80102f80:	e8 ce 28 00 00       	call   80105853 <acquire>
  for(found = 0,key = 0;key<numOfSegs;key++)
80102f85:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80102f8c:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80102f93:	e9 c3 00 00 00       	jmp    8010305b <shmdt+0x127>
  {    cprintf("in for: (int)shm.seg[key] = %d, r= %d\n",(int)shm.seg[key],r);
80102f98:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102f9b:	8b 04 85 a0 08 11 80 	mov    -0x7feef760(,%eax,4),%eax
80102fa2:	8b 55 e0             	mov    -0x20(%ebp),%edx
80102fa5:	89 54 24 08          	mov    %edx,0x8(%esp)
80102fa9:	89 44 24 04          	mov    %eax,0x4(%esp)
80102fad:	c7 04 24 7c 95 10 80 	movl   $0x8010957c,(%esp)
80102fb4:	e8 e8 d3 ff ff       	call   801003a1 <cprintf>

    if(((int)shm.seg[key]| PTE_U | PTE_P | PTE_W) == r || ((int)shm.seg[key]| PTE_U | PTE_P) == r)
80102fb9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102fbc:	8b 04 85 a0 08 11 80 	mov    -0x7feef760(,%eax,4),%eax
80102fc3:	83 c8 07             	or     $0x7,%eax
80102fc6:	3b 45 e0             	cmp    -0x20(%ebp),%eax
80102fc9:	74 12                	je     80102fdd <shmdt+0xa9>
80102fcb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102fce:	8b 04 85 a0 08 11 80 	mov    -0x7feef760(,%eax,4),%eax
80102fd5:	83 c8 05             	or     $0x5,%eax
80102fd8:	3b 45 e0             	cmp    -0x20(%ebp),%eax
80102fdb:	75 7a                	jne    80103057 <shmdt+0x123>
    {  
  cprintf("in if\n");
80102fdd:	c7 04 24 a3 95 10 80 	movl   $0x801095a3,(%esp)
80102fe4:	e8 b8 d3 ff ff       	call   801003a1 <cprintf>

      if(shm.refs[key][1])
80102fe9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102fec:	8b 04 c5 a4 18 11 80 	mov    -0x7feee75c(,%eax,8),%eax
80102ff3:	85 c0                	test   %eax,%eax
80102ff5:	74 56                	je     8010304d <shmdt+0x119>
      {  cprintf("in if2\n");
80102ff7:	c7 04 24 aa 95 10 80 	movl   $0x801095aa,(%esp)
80102ffe:	e8 9e d3 ff ff       	call   801003a1 <cprintf>

	if(shm.refs[key][0])
80103003:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103006:	05 00 02 00 00       	add    $0x200,%eax
8010300b:	8b 04 c5 a0 08 11 80 	mov    -0x7feef760(,%eax,8),%eax
80103012:	85 c0                	test   %eax,%eax
80103014:	74 21                	je     80103037 <shmdt+0x103>
	  shm.refs[key][0]--;
80103016:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103019:	05 00 02 00 00       	add    $0x200,%eax
8010301e:	8b 04 c5 a0 08 11 80 	mov    -0x7feef760(,%eax,8),%eax
80103025:	8d 50 ff             	lea    -0x1(%eax),%edx
80103028:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010302b:	05 00 02 00 00       	add    $0x200,%eax
80103030:	89 14 c5 a0 08 11 80 	mov    %edx,-0x7feef760(,%eax,8)
	numOfPages = shm.refs[key][1];
80103037:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010303a:	8b 04 c5 a4 18 11 80 	mov    -0x7feee75c(,%eax,8),%eax
80103041:	89 45 f4             	mov    %eax,-0xc(%ebp)
	found = 1;
80103044:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
	break;
8010304b:	eb 1b                	jmp    80103068 <shmdt+0x134>
      }
      else
	return -1;
8010304d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103052:	e9 85 00 00 00       	jmp    801030dc <shmdt+0x1a8>
  int key,found;
  cprintf("before wlkpgdir\n");
  pte = walkpgdir(proc->pgdir, (char*)shmaddr, 0);
  r = (int)p2v(*pte) ;
  acquire(&shm.lock);
  for(found = 0,key = 0;key<numOfSegs;key++)
80103057:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
8010305b:	81 7d f0 ff 03 00 00 	cmpl   $0x3ff,-0x10(%ebp)
80103062:	0f 8e 30 ff ff ff    	jle    80102f98 <shmdt+0x64>
      }
      else
	return -1;
    }
  }
  release(&shm.lock);
80103068:	c7 04 24 a0 38 11 80 	movl   $0x801138a0,(%esp)
8010306f:	e8 7a 28 00 00       	call   801058ee <release>
  
  if(!found)
80103074:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103078:	75 07                	jne    80103081 <shmdt+0x14d>
    return -1;
8010307a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010307f:	eb 5b                	jmp    801030dc <shmdt+0x1a8>

  void * shmaddr2 = (void*)shmaddr;
80103081:	8b 45 08             	mov    0x8(%ebp),%eax
80103084:	89 45 e8             	mov    %eax,-0x18(%ebp)

  for(; shmaddr2  < shmaddr + numOfPages*PGSIZE; shmaddr2 += PGSIZE)
80103087:	eb 40                	jmp    801030c9 <shmdt+0x195>
  {
    pte = walkpgdir(proc->pgdir, (char*)shmaddr2, 0);
80103089:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010308f:	8b 40 04             	mov    0x4(%eax),%eax
80103092:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80103099:	00 
8010309a:	8b 55 e8             	mov    -0x18(%ebp),%edx
8010309d:	89 54 24 04          	mov    %edx,0x4(%esp)
801030a1:	89 04 24             	mov    %eax,(%esp)
801030a4:	e8 66 59 00 00       	call   80108a0f <walkpgdir>
801030a9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(!pte)
801030ac:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
801030b0:	75 07                	jne    801030b9 <shmdt+0x185>
      shmaddr2 += (NPTENTRIES - 1) * PGSIZE;
801030b2:	81 45 e8 00 f0 3f 00 	addl   $0x3ff000,-0x18(%ebp)
    *pte = 0;
801030b9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801030bc:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  if(!found)
    return -1;

  void * shmaddr2 = (void*)shmaddr;

  for(; shmaddr2  < shmaddr + numOfPages*PGSIZE; shmaddr2 += PGSIZE)
801030c2:	81 45 e8 00 10 00 00 	addl   $0x1000,-0x18(%ebp)
801030c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801030cc:	c1 e0 0c             	shl    $0xc,%eax
801030cf:	03 45 08             	add    0x8(%ebp),%eax
801030d2:	3b 45 e8             	cmp    -0x18(%ebp),%eax
801030d5:	77 b2                	ja     80103089 <shmdt+0x155>
    if(!pte)
      shmaddr2 += (NPTENTRIES - 1) * PGSIZE;
    *pte = 0;
  }

  return 0;
801030d7:	b8 00 00 00 00       	mov    $0x0,%eax
}
801030dc:	c9                   	leave  
801030dd:	c3                   	ret    
	...

801030e0 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801030e0:	55                   	push   %ebp
801030e1:	89 e5                	mov    %esp,%ebp
801030e3:	53                   	push   %ebx
801030e4:	83 ec 14             	sub    $0x14,%esp
801030e7:	8b 45 08             	mov    0x8(%ebp),%eax
801030ea:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801030ee:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
801030f2:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
801030f6:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
801030fa:	ec                   	in     (%dx),%al
801030fb:	89 c3                	mov    %eax,%ebx
801030fd:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80103100:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80103104:	83 c4 14             	add    $0x14,%esp
80103107:	5b                   	pop    %ebx
80103108:	5d                   	pop    %ebp
80103109:	c3                   	ret    

8010310a <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
8010310a:	55                   	push   %ebp
8010310b:	89 e5                	mov    %esp,%ebp
8010310d:	83 ec 14             	sub    $0x14,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
80103110:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80103117:	e8 c4 ff ff ff       	call   801030e0 <inb>
8010311c:	0f b6 c0             	movzbl %al,%eax
8010311f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
80103122:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103125:	83 e0 01             	and    $0x1,%eax
80103128:	85 c0                	test   %eax,%eax
8010312a:	75 0a                	jne    80103136 <kbdgetc+0x2c>
    return -1;
8010312c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103131:	e9 23 01 00 00       	jmp    80103259 <kbdgetc+0x14f>
  data = inb(KBDATAP);
80103136:	c7 04 24 60 00 00 00 	movl   $0x60,(%esp)
8010313d:	e8 9e ff ff ff       	call   801030e0 <inb>
80103142:	0f b6 c0             	movzbl %al,%eax
80103145:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
80103148:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
8010314f:	75 17                	jne    80103168 <kbdgetc+0x5e>
    shift |= E0ESC;
80103151:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103156:	83 c8 40             	or     $0x40,%eax
80103159:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
    return 0;
8010315e:	b8 00 00 00 00       	mov    $0x0,%eax
80103163:	e9 f1 00 00 00       	jmp    80103259 <kbdgetc+0x14f>
  } else if(data & 0x80){
80103168:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010316b:	25 80 00 00 00       	and    $0x80,%eax
80103170:	85 c0                	test   %eax,%eax
80103172:	74 45                	je     801031b9 <kbdgetc+0xaf>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
80103174:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103179:	83 e0 40             	and    $0x40,%eax
8010317c:	85 c0                	test   %eax,%eax
8010317e:	75 08                	jne    80103188 <kbdgetc+0x7e>
80103180:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103183:	83 e0 7f             	and    $0x7f,%eax
80103186:	eb 03                	jmp    8010318b <kbdgetc+0x81>
80103188:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010318b:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
8010318e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103191:	05 20 a0 10 80       	add    $0x8010a020,%eax
80103196:	0f b6 00             	movzbl (%eax),%eax
80103199:	83 c8 40             	or     $0x40,%eax
8010319c:	0f b6 c0             	movzbl %al,%eax
8010319f:	f7 d0                	not    %eax
801031a1:	89 c2                	mov    %eax,%edx
801031a3:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
801031a8:	21 d0                	and    %edx,%eax
801031aa:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
    return 0;
801031af:	b8 00 00 00 00       	mov    $0x0,%eax
801031b4:	e9 a0 00 00 00       	jmp    80103259 <kbdgetc+0x14f>
  } else if(shift & E0ESC){
801031b9:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
801031be:	83 e0 40             	and    $0x40,%eax
801031c1:	85 c0                	test   %eax,%eax
801031c3:	74 14                	je     801031d9 <kbdgetc+0xcf>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
801031c5:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
801031cc:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
801031d1:	83 e0 bf             	and    $0xffffffbf,%eax
801031d4:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
  }

  shift |= shiftcode[data];
801031d9:	8b 45 fc             	mov    -0x4(%ebp),%eax
801031dc:	05 20 a0 10 80       	add    $0x8010a020,%eax
801031e1:	0f b6 00             	movzbl (%eax),%eax
801031e4:	0f b6 d0             	movzbl %al,%edx
801031e7:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
801031ec:	09 d0                	or     %edx,%eax
801031ee:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
  shift ^= togglecode[data];
801031f3:	8b 45 fc             	mov    -0x4(%ebp),%eax
801031f6:	05 20 a1 10 80       	add    $0x8010a120,%eax
801031fb:	0f b6 00             	movzbl (%eax),%eax
801031fe:	0f b6 d0             	movzbl %al,%edx
80103201:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103206:	31 d0                	xor    %edx,%eax
80103208:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
  c = charcode[shift & (CTL | SHIFT)][data];
8010320d:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103212:	83 e0 03             	and    $0x3,%eax
80103215:	8b 04 85 20 a5 10 80 	mov    -0x7fef5ae0(,%eax,4),%eax
8010321c:	03 45 fc             	add    -0x4(%ebp),%eax
8010321f:	0f b6 00             	movzbl (%eax),%eax
80103222:	0f b6 c0             	movzbl %al,%eax
80103225:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
80103228:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
8010322d:	83 e0 08             	and    $0x8,%eax
80103230:	85 c0                	test   %eax,%eax
80103232:	74 22                	je     80103256 <kbdgetc+0x14c>
    if('a' <= c && c <= 'z')
80103234:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
80103238:	76 0c                	jbe    80103246 <kbdgetc+0x13c>
8010323a:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
8010323e:	77 06                	ja     80103246 <kbdgetc+0x13c>
      c += 'A' - 'a';
80103240:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
80103244:	eb 10                	jmp    80103256 <kbdgetc+0x14c>
    else if('A' <= c && c <= 'Z')
80103246:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
8010324a:	76 0a                	jbe    80103256 <kbdgetc+0x14c>
8010324c:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
80103250:	77 04                	ja     80103256 <kbdgetc+0x14c>
      c += 'a' - 'A';
80103252:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
80103256:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103259:	c9                   	leave  
8010325a:	c3                   	ret    

8010325b <kbdintr>:

void
kbdintr(void)
{
8010325b:	55                   	push   %ebp
8010325c:	89 e5                	mov    %esp,%ebp
8010325e:	83 ec 18             	sub    $0x18,%esp
  consoleintr(kbdgetc);
80103261:	c7 04 24 0a 31 10 80 	movl   $0x8010310a,(%esp)
80103268:	e8 40 d5 ff ff       	call   801007ad <consoleintr>
}
8010326d:	c9                   	leave  
8010326e:	c3                   	ret    
	...

80103270 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103270:	55                   	push   %ebp
80103271:	89 e5                	mov    %esp,%ebp
80103273:	83 ec 08             	sub    $0x8,%esp
80103276:	8b 55 08             	mov    0x8(%ebp),%edx
80103279:	8b 45 0c             	mov    0xc(%ebp),%eax
8010327c:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103280:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103283:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103287:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
8010328b:	ee                   	out    %al,(%dx)
}
8010328c:	c9                   	leave  
8010328d:	c3                   	ret    

8010328e <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
8010328e:	55                   	push   %ebp
8010328f:	89 e5                	mov    %esp,%ebp
80103291:	53                   	push   %ebx
80103292:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103295:	9c                   	pushf  
80103296:	5b                   	pop    %ebx
80103297:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
8010329a:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
8010329d:	83 c4 10             	add    $0x10,%esp
801032a0:	5b                   	pop    %ebx
801032a1:	5d                   	pop    %ebp
801032a2:	c3                   	ret    

801032a3 <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
801032a3:	55                   	push   %ebp
801032a4:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
801032a6:	a1 d4 38 11 80       	mov    0x801138d4,%eax
801032ab:	8b 55 08             	mov    0x8(%ebp),%edx
801032ae:	c1 e2 02             	shl    $0x2,%edx
801032b1:	01 c2                	add    %eax,%edx
801032b3:	8b 45 0c             	mov    0xc(%ebp),%eax
801032b6:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
801032b8:	a1 d4 38 11 80       	mov    0x801138d4,%eax
801032bd:	83 c0 20             	add    $0x20,%eax
801032c0:	8b 00                	mov    (%eax),%eax
}
801032c2:	5d                   	pop    %ebp
801032c3:	c3                   	ret    

801032c4 <lapicinit>:
//PAGEBREAK!

void
lapicinit(int c)
{
801032c4:	55                   	push   %ebp
801032c5:	89 e5                	mov    %esp,%ebp
801032c7:	83 ec 08             	sub    $0x8,%esp
  if(!lapic) 
801032ca:	a1 d4 38 11 80       	mov    0x801138d4,%eax
801032cf:	85 c0                	test   %eax,%eax
801032d1:	0f 84 47 01 00 00    	je     8010341e <lapicinit+0x15a>
    return;

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
801032d7:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
801032de:	00 
801032df:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
801032e6:	e8 b8 ff ff ff       	call   801032a3 <lapicw>

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.  
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
801032eb:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
801032f2:	00 
801032f3:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
801032fa:	e8 a4 ff ff ff       	call   801032a3 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
801032ff:	c7 44 24 04 20 00 02 	movl   $0x20020,0x4(%esp)
80103306:	00 
80103307:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
8010330e:	e8 90 ff ff ff       	call   801032a3 <lapicw>
  lapicw(TICR, 10000000); 
80103313:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
8010331a:	00 
8010331b:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
80103322:	e8 7c ff ff ff       	call   801032a3 <lapicw>

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
80103327:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
8010332e:	00 
8010332f:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
80103336:	e8 68 ff ff ff       	call   801032a3 <lapicw>
  lapicw(LINT1, MASKED);
8010333b:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103342:	00 
80103343:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
8010334a:	e8 54 ff ff ff       	call   801032a3 <lapicw>

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
8010334f:	a1 d4 38 11 80       	mov    0x801138d4,%eax
80103354:	83 c0 30             	add    $0x30,%eax
80103357:	8b 00                	mov    (%eax),%eax
80103359:	c1 e8 10             	shr    $0x10,%eax
8010335c:	25 ff 00 00 00       	and    $0xff,%eax
80103361:	83 f8 03             	cmp    $0x3,%eax
80103364:	76 14                	jbe    8010337a <lapicinit+0xb6>
    lapicw(PCINT, MASKED);
80103366:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
8010336d:	00 
8010336e:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
80103375:	e8 29 ff ff ff       	call   801032a3 <lapicw>

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
8010337a:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
80103381:	00 
80103382:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
80103389:	e8 15 ff ff ff       	call   801032a3 <lapicw>

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
8010338e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103395:	00 
80103396:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
8010339d:	e8 01 ff ff ff       	call   801032a3 <lapicw>
  lapicw(ESR, 0);
801033a2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801033a9:	00 
801033aa:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
801033b1:	e8 ed fe ff ff       	call   801032a3 <lapicw>

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
801033b6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801033bd:	00 
801033be:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
801033c5:	e8 d9 fe ff ff       	call   801032a3 <lapicw>

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
801033ca:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801033d1:	00 
801033d2:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
801033d9:	e8 c5 fe ff ff       	call   801032a3 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
801033de:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
801033e5:	00 
801033e6:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801033ed:	e8 b1 fe ff ff       	call   801032a3 <lapicw>
  while(lapic[ICRLO] & DELIVS)
801033f2:	90                   	nop
801033f3:	a1 d4 38 11 80       	mov    0x801138d4,%eax
801033f8:	05 00 03 00 00       	add    $0x300,%eax
801033fd:	8b 00                	mov    (%eax),%eax
801033ff:	25 00 10 00 00       	and    $0x1000,%eax
80103404:	85 c0                	test   %eax,%eax
80103406:	75 eb                	jne    801033f3 <lapicinit+0x12f>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
80103408:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010340f:	00 
80103410:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103417:	e8 87 fe ff ff       	call   801032a3 <lapicw>
8010341c:	eb 01                	jmp    8010341f <lapicinit+0x15b>

void
lapicinit(int c)
{
  if(!lapic) 
    return;
8010341e:	90                   	nop
  while(lapic[ICRLO] & DELIVS)
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
}
8010341f:	c9                   	leave  
80103420:	c3                   	ret    

80103421 <cpunum>:

int
cpunum(void)
{
80103421:	55                   	push   %ebp
80103422:	89 e5                	mov    %esp,%ebp
80103424:	83 ec 18             	sub    $0x18,%esp
  // Cannot call cpu when interrupts are enabled:
  // result not guaranteed to last long enough to be used!
  // Would prefer to panic but even printing is chancy here:
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
80103427:	e8 62 fe ff ff       	call   8010328e <readeflags>
8010342c:	25 00 02 00 00       	and    $0x200,%eax
80103431:	85 c0                	test   %eax,%eax
80103433:	74 29                	je     8010345e <cpunum+0x3d>
    static int n;
    if(n++ == 0)
80103435:	a1 60 c6 10 80       	mov    0x8010c660,%eax
8010343a:	85 c0                	test   %eax,%eax
8010343c:	0f 94 c2             	sete   %dl
8010343f:	83 c0 01             	add    $0x1,%eax
80103442:	a3 60 c6 10 80       	mov    %eax,0x8010c660
80103447:	84 d2                	test   %dl,%dl
80103449:	74 13                	je     8010345e <cpunum+0x3d>
      cprintf("cpu called from %x with interrupts enabled\n",
8010344b:	8b 45 04             	mov    0x4(%ebp),%eax
8010344e:	89 44 24 04          	mov    %eax,0x4(%esp)
80103452:	c7 04 24 b4 95 10 80 	movl   $0x801095b4,(%esp)
80103459:	e8 43 cf ff ff       	call   801003a1 <cprintf>
        __builtin_return_address(0));
  }

  if(lapic)
8010345e:	a1 d4 38 11 80       	mov    0x801138d4,%eax
80103463:	85 c0                	test   %eax,%eax
80103465:	74 0f                	je     80103476 <cpunum+0x55>
    return lapic[ID]>>24;
80103467:	a1 d4 38 11 80       	mov    0x801138d4,%eax
8010346c:	83 c0 20             	add    $0x20,%eax
8010346f:	8b 00                	mov    (%eax),%eax
80103471:	c1 e8 18             	shr    $0x18,%eax
80103474:	eb 05                	jmp    8010347b <cpunum+0x5a>
  return 0;
80103476:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010347b:	c9                   	leave  
8010347c:	c3                   	ret    

8010347d <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
8010347d:	55                   	push   %ebp
8010347e:	89 e5                	mov    %esp,%ebp
80103480:	83 ec 08             	sub    $0x8,%esp
  if(lapic)
80103483:	a1 d4 38 11 80       	mov    0x801138d4,%eax
80103488:	85 c0                	test   %eax,%eax
8010348a:	74 14                	je     801034a0 <lapiceoi+0x23>
    lapicw(EOI, 0);
8010348c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103493:	00 
80103494:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
8010349b:	e8 03 fe ff ff       	call   801032a3 <lapicw>
}
801034a0:	c9                   	leave  
801034a1:	c3                   	ret    

801034a2 <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
801034a2:	55                   	push   %ebp
801034a3:	89 e5                	mov    %esp,%ebp
}
801034a5:	5d                   	pop    %ebp
801034a6:	c3                   	ret    

801034a7 <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
801034a7:	55                   	push   %ebp
801034a8:	89 e5                	mov    %esp,%ebp
801034aa:	83 ec 1c             	sub    $0x1c,%esp
801034ad:	8b 45 08             	mov    0x8(%ebp),%eax
801034b0:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;
  
  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
801034b3:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
801034ba:	00 
801034bb:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
801034c2:	e8 a9 fd ff ff       	call   80103270 <outb>
  outb(IO_RTC+1, 0x0A);
801034c7:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
801034ce:	00 
801034cf:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
801034d6:	e8 95 fd ff ff       	call   80103270 <outb>
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
801034db:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
801034e2:	8b 45 f8             	mov    -0x8(%ebp),%eax
801034e5:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
801034ea:	8b 45 f8             	mov    -0x8(%ebp),%eax
801034ed:	8d 50 02             	lea    0x2(%eax),%edx
801034f0:	8b 45 0c             	mov    0xc(%ebp),%eax
801034f3:	c1 e8 04             	shr    $0x4,%eax
801034f6:	66 89 02             	mov    %ax,(%edx)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
801034f9:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
801034fd:	c1 e0 18             	shl    $0x18,%eax
80103500:	89 44 24 04          	mov    %eax,0x4(%esp)
80103504:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
8010350b:	e8 93 fd ff ff       	call   801032a3 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
80103510:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
80103517:	00 
80103518:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
8010351f:	e8 7f fd ff ff       	call   801032a3 <lapicw>
  microdelay(200);
80103524:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
8010352b:	e8 72 ff ff ff       	call   801034a2 <microdelay>
  lapicw(ICRLO, INIT | LEVEL);
80103530:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
80103537:	00 
80103538:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
8010353f:	e8 5f fd ff ff       	call   801032a3 <lapicw>
  microdelay(100);    // should be 10ms, but too slow in Bochs!
80103544:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
8010354b:	e8 52 ff ff ff       	call   801034a2 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80103550:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80103557:	eb 40                	jmp    80103599 <lapicstartap+0xf2>
    lapicw(ICRHI, apicid<<24);
80103559:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
8010355d:	c1 e0 18             	shl    $0x18,%eax
80103560:	89 44 24 04          	mov    %eax,0x4(%esp)
80103564:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
8010356b:	e8 33 fd ff ff       	call   801032a3 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
80103570:	8b 45 0c             	mov    0xc(%ebp),%eax
80103573:	c1 e8 0c             	shr    $0xc,%eax
80103576:	80 cc 06             	or     $0x6,%ah
80103579:	89 44 24 04          	mov    %eax,0x4(%esp)
8010357d:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103584:	e8 1a fd ff ff       	call   801032a3 <lapicw>
    microdelay(200);
80103589:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103590:	e8 0d ff ff ff       	call   801034a2 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80103595:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103599:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
8010359d:	7e ba                	jle    80103559 <lapicstartap+0xb2>
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
8010359f:	c9                   	leave  
801035a0:	c3                   	ret    
801035a1:	00 00                	add    %al,(%eax)
	...

801035a4 <initlog>:

static void recover_from_log(void);

void
initlog(void)
{
801035a4:	55                   	push   %ebp
801035a5:	89 e5                	mov    %esp,%ebp
801035a7:	83 ec 28             	sub    $0x28,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
801035aa:	c7 44 24 04 e0 95 10 	movl   $0x801095e0,0x4(%esp)
801035b1:	80 
801035b2:	c7 04 24 e0 38 11 80 	movl   $0x801138e0,(%esp)
801035b9:	e8 74 22 00 00       	call   80105832 <initlock>
  readsb(ROOTDEV, &sb);
801035be:	8d 45 e8             	lea    -0x18(%ebp),%eax
801035c1:	89 44 24 04          	mov    %eax,0x4(%esp)
801035c5:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801035cc:	e8 1b dd ff ff       	call   801012ec <readsb>
  log.start = sb.size - sb.nlog;
801035d1:	8b 55 e8             	mov    -0x18(%ebp),%edx
801035d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801035d7:	89 d1                	mov    %edx,%ecx
801035d9:	29 c1                	sub    %eax,%ecx
801035db:	89 c8                	mov    %ecx,%eax
801035dd:	a3 14 39 11 80       	mov    %eax,0x80113914
  log.size = sb.nlog;
801035e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801035e5:	a3 18 39 11 80       	mov    %eax,0x80113918
  log.dev = ROOTDEV;
801035ea:	c7 05 20 39 11 80 01 	movl   $0x1,0x80113920
801035f1:	00 00 00 
  recover_from_log();
801035f4:	e8 97 01 00 00       	call   80103790 <recover_from_log>
}
801035f9:	c9                   	leave  
801035fa:	c3                   	ret    

801035fb <install_trans>:

// Copy committed blocks from log to their home location
static void 
install_trans(void)
{
801035fb:	55                   	push   %ebp
801035fc:	89 e5                	mov    %esp,%ebp
801035fe:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103601:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103608:	e9 89 00 00 00       	jmp    80103696 <install_trans+0x9b>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
8010360d:	a1 14 39 11 80       	mov    0x80113914,%eax
80103612:	03 45 f4             	add    -0xc(%ebp),%eax
80103615:	83 c0 01             	add    $0x1,%eax
80103618:	89 c2                	mov    %eax,%edx
8010361a:	a1 20 39 11 80       	mov    0x80113920,%eax
8010361f:	89 54 24 04          	mov    %edx,0x4(%esp)
80103623:	89 04 24             	mov    %eax,(%esp)
80103626:	e8 7b cb ff ff       	call   801001a6 <bread>
8010362b:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.sector[tail]); // read dst
8010362e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103631:	83 c0 10             	add    $0x10,%eax
80103634:	8b 04 85 e8 38 11 80 	mov    -0x7feec718(,%eax,4),%eax
8010363b:	89 c2                	mov    %eax,%edx
8010363d:	a1 20 39 11 80       	mov    0x80113920,%eax
80103642:	89 54 24 04          	mov    %edx,0x4(%esp)
80103646:	89 04 24             	mov    %eax,(%esp)
80103649:	e8 58 cb ff ff       	call   801001a6 <bread>
8010364e:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
80103651:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103654:	8d 50 18             	lea    0x18(%eax),%edx
80103657:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010365a:	83 c0 18             	add    $0x18,%eax
8010365d:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80103664:	00 
80103665:	89 54 24 04          	mov    %edx,0x4(%esp)
80103669:	89 04 24             	mov    %eax,(%esp)
8010366c:	e8 3c 25 00 00       	call   80105bad <memmove>
    bwrite(dbuf);  // write dst to disk
80103671:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103674:	89 04 24             	mov    %eax,(%esp)
80103677:	e8 61 cb ff ff       	call   801001dd <bwrite>
    brelse(lbuf); 
8010367c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010367f:	89 04 24             	mov    %eax,(%esp)
80103682:	e8 90 cb ff ff       	call   80100217 <brelse>
    brelse(dbuf);
80103687:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010368a:	89 04 24             	mov    %eax,(%esp)
8010368d:	e8 85 cb ff ff       	call   80100217 <brelse>
static void 
install_trans(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103692:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103696:	a1 24 39 11 80       	mov    0x80113924,%eax
8010369b:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010369e:	0f 8f 69 ff ff ff    	jg     8010360d <install_trans+0x12>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    bwrite(dbuf);  // write dst to disk
    brelse(lbuf); 
    brelse(dbuf);
  }
}
801036a4:	c9                   	leave  
801036a5:	c3                   	ret    

801036a6 <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
801036a6:	55                   	push   %ebp
801036a7:	89 e5                	mov    %esp,%ebp
801036a9:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
801036ac:	a1 14 39 11 80       	mov    0x80113914,%eax
801036b1:	89 c2                	mov    %eax,%edx
801036b3:	a1 20 39 11 80       	mov    0x80113920,%eax
801036b8:	89 54 24 04          	mov    %edx,0x4(%esp)
801036bc:	89 04 24             	mov    %eax,(%esp)
801036bf:	e8 e2 ca ff ff       	call   801001a6 <bread>
801036c4:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
801036c7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801036ca:	83 c0 18             	add    $0x18,%eax
801036cd:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
801036d0:	8b 45 ec             	mov    -0x14(%ebp),%eax
801036d3:	8b 00                	mov    (%eax),%eax
801036d5:	a3 24 39 11 80       	mov    %eax,0x80113924
  for (i = 0; i < log.lh.n; i++) {
801036da:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801036e1:	eb 1b                	jmp    801036fe <read_head+0x58>
    log.lh.sector[i] = lh->sector[i];
801036e3:	8b 45 ec             	mov    -0x14(%ebp),%eax
801036e6:	8b 55 f4             	mov    -0xc(%ebp),%edx
801036e9:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
801036ed:	8b 55 f4             	mov    -0xc(%ebp),%edx
801036f0:	83 c2 10             	add    $0x10,%edx
801036f3:	89 04 95 e8 38 11 80 	mov    %eax,-0x7feec718(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
801036fa:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801036fe:	a1 24 39 11 80       	mov    0x80113924,%eax
80103703:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103706:	7f db                	jg     801036e3 <read_head+0x3d>
    log.lh.sector[i] = lh->sector[i];
  }
  brelse(buf);
80103708:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010370b:	89 04 24             	mov    %eax,(%esp)
8010370e:	e8 04 cb ff ff       	call   80100217 <brelse>
}
80103713:	c9                   	leave  
80103714:	c3                   	ret    

80103715 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
80103715:	55                   	push   %ebp
80103716:	89 e5                	mov    %esp,%ebp
80103718:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
8010371b:	a1 14 39 11 80       	mov    0x80113914,%eax
80103720:	89 c2                	mov    %eax,%edx
80103722:	a1 20 39 11 80       	mov    0x80113920,%eax
80103727:	89 54 24 04          	mov    %edx,0x4(%esp)
8010372b:	89 04 24             	mov    %eax,(%esp)
8010372e:	e8 73 ca ff ff       	call   801001a6 <bread>
80103733:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
80103736:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103739:	83 c0 18             	add    $0x18,%eax
8010373c:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
8010373f:	8b 15 24 39 11 80    	mov    0x80113924,%edx
80103745:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103748:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
8010374a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103751:	eb 1b                	jmp    8010376e <write_head+0x59>
    hb->sector[i] = log.lh.sector[i];
80103753:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103756:	83 c0 10             	add    $0x10,%eax
80103759:	8b 0c 85 e8 38 11 80 	mov    -0x7feec718(,%eax,4),%ecx
80103760:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103763:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103766:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
8010376a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010376e:	a1 24 39 11 80       	mov    0x80113924,%eax
80103773:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103776:	7f db                	jg     80103753 <write_head+0x3e>
    hb->sector[i] = log.lh.sector[i];
  }
  bwrite(buf);
80103778:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010377b:	89 04 24             	mov    %eax,(%esp)
8010377e:	e8 5a ca ff ff       	call   801001dd <bwrite>
  brelse(buf);
80103783:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103786:	89 04 24             	mov    %eax,(%esp)
80103789:	e8 89 ca ff ff       	call   80100217 <brelse>
}
8010378e:	c9                   	leave  
8010378f:	c3                   	ret    

80103790 <recover_from_log>:

static void
recover_from_log(void)
{
80103790:	55                   	push   %ebp
80103791:	89 e5                	mov    %esp,%ebp
80103793:	83 ec 08             	sub    $0x8,%esp
  read_head();      
80103796:	e8 0b ff ff ff       	call   801036a6 <read_head>
  install_trans(); // if committed, copy from log to disk
8010379b:	e8 5b fe ff ff       	call   801035fb <install_trans>
  log.lh.n = 0;
801037a0:	c7 05 24 39 11 80 00 	movl   $0x0,0x80113924
801037a7:	00 00 00 
  write_head(); // clear the log
801037aa:	e8 66 ff ff ff       	call   80103715 <write_head>
}
801037af:	c9                   	leave  
801037b0:	c3                   	ret    

801037b1 <begin_trans>:

void
begin_trans(void)
{
801037b1:	55                   	push   %ebp
801037b2:	89 e5                	mov    %esp,%ebp
801037b4:	83 ec 18             	sub    $0x18,%esp
  acquire(&log.lock);
801037b7:	c7 04 24 e0 38 11 80 	movl   $0x801138e0,(%esp)
801037be:	e8 90 20 00 00       	call   80105853 <acquire>
  while (log.busy) {
801037c3:	eb 14                	jmp    801037d9 <begin_trans+0x28>
  sleep(&log, &log.lock);
801037c5:	c7 44 24 04 e0 38 11 	movl   $0x801138e0,0x4(%esp)
801037cc:	80 
801037cd:	c7 04 24 e0 38 11 80 	movl   $0x801138e0,(%esp)
801037d4:	e8 3e 1c 00 00       	call   80105417 <sleep>

void
begin_trans(void)
{
  acquire(&log.lock);
  while (log.busy) {
801037d9:	a1 1c 39 11 80       	mov    0x8011391c,%eax
801037de:	85 c0                	test   %eax,%eax
801037e0:	75 e3                	jne    801037c5 <begin_trans+0x14>
  sleep(&log, &log.lock);
  }
  log.busy = 1;
801037e2:	c7 05 1c 39 11 80 01 	movl   $0x1,0x8011391c
801037e9:	00 00 00 
  release(&log.lock);
801037ec:	c7 04 24 e0 38 11 80 	movl   $0x801138e0,(%esp)
801037f3:	e8 f6 20 00 00       	call   801058ee <release>
}
801037f8:	c9                   	leave  
801037f9:	c3                   	ret    

801037fa <commit_trans>:

void
commit_trans(void)
{
801037fa:	55                   	push   %ebp
801037fb:	89 e5                	mov    %esp,%ebp
801037fd:	83 ec 18             	sub    $0x18,%esp
  if (log.lh.n > 0) {
80103800:	a1 24 39 11 80       	mov    0x80113924,%eax
80103805:	85 c0                	test   %eax,%eax
80103807:	7e 19                	jle    80103822 <commit_trans+0x28>
    write_head();    // Write header to disk -- the real commit
80103809:	e8 07 ff ff ff       	call   80103715 <write_head>
    install_trans(); // Now install writes to home locations
8010380e:	e8 e8 fd ff ff       	call   801035fb <install_trans>
    log.lh.n = 0; 
80103813:	c7 05 24 39 11 80 00 	movl   $0x0,0x80113924
8010381a:	00 00 00 
    write_head();    // Erase the transaction from the log
8010381d:	e8 f3 fe ff ff       	call   80103715 <write_head>
  }
  
  acquire(&log.lock);
80103822:	c7 04 24 e0 38 11 80 	movl   $0x801138e0,(%esp)
80103829:	e8 25 20 00 00       	call   80105853 <acquire>
  log.busy = 0;
8010382e:	c7 05 1c 39 11 80 00 	movl   $0x0,0x8011391c
80103835:	00 00 00 
  wakeup(&log);
80103838:	c7 04 24 e0 38 11 80 	movl   $0x801138e0,(%esp)
8010383f:	e8 0f 1d 00 00       	call   80105553 <wakeup>
  release(&log.lock);
80103844:	c7 04 24 e0 38 11 80 	movl   $0x801138e0,(%esp)
8010384b:	e8 9e 20 00 00       	call   801058ee <release>
}
80103850:	c9                   	leave  
80103851:	c3                   	ret    

80103852 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80103852:	55                   	push   %ebp
80103853:	89 e5                	mov    %esp,%ebp
80103855:	83 ec 28             	sub    $0x28,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80103858:	a1 24 39 11 80       	mov    0x80113924,%eax
8010385d:	83 f8 09             	cmp    $0x9,%eax
80103860:	7f 12                	jg     80103874 <log_write+0x22>
80103862:	a1 24 39 11 80       	mov    0x80113924,%eax
80103867:	8b 15 18 39 11 80    	mov    0x80113918,%edx
8010386d:	83 ea 01             	sub    $0x1,%edx
80103870:	39 d0                	cmp    %edx,%eax
80103872:	7c 0c                	jl     80103880 <log_write+0x2e>
    panic("too big a transaction");
80103874:	c7 04 24 e4 95 10 80 	movl   $0x801095e4,(%esp)
8010387b:	e8 bd cc ff ff       	call   8010053d <panic>
  if (!log.busy)
80103880:	a1 1c 39 11 80       	mov    0x8011391c,%eax
80103885:	85 c0                	test   %eax,%eax
80103887:	75 0c                	jne    80103895 <log_write+0x43>
    panic("write outside of trans");
80103889:	c7 04 24 fa 95 10 80 	movl   $0x801095fa,(%esp)
80103890:	e8 a8 cc ff ff       	call   8010053d <panic>

  for (i = 0; i < log.lh.n; i++) {
80103895:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010389c:	eb 1d                	jmp    801038bb <log_write+0x69>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
8010389e:	8b 45 f4             	mov    -0xc(%ebp),%eax
801038a1:	83 c0 10             	add    $0x10,%eax
801038a4:	8b 04 85 e8 38 11 80 	mov    -0x7feec718(,%eax,4),%eax
801038ab:	89 c2                	mov    %eax,%edx
801038ad:	8b 45 08             	mov    0x8(%ebp),%eax
801038b0:	8b 40 08             	mov    0x8(%eax),%eax
801038b3:	39 c2                	cmp    %eax,%edx
801038b5:	74 10                	je     801038c7 <log_write+0x75>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    panic("too big a transaction");
  if (!log.busy)
    panic("write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
801038b7:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801038bb:	a1 24 39 11 80       	mov    0x80113924,%eax
801038c0:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801038c3:	7f d9                	jg     8010389e <log_write+0x4c>
801038c5:	eb 01                	jmp    801038c8 <log_write+0x76>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
      break;
801038c7:	90                   	nop
  }
  log.lh.sector[i] = b->sector;
801038c8:	8b 45 08             	mov    0x8(%ebp),%eax
801038cb:	8b 40 08             	mov    0x8(%eax),%eax
801038ce:	8b 55 f4             	mov    -0xc(%ebp),%edx
801038d1:	83 c2 10             	add    $0x10,%edx
801038d4:	89 04 95 e8 38 11 80 	mov    %eax,-0x7feec718(,%edx,4)
  struct buf *lbuf = bread(b->dev, log.start+i+1);
801038db:	a1 14 39 11 80       	mov    0x80113914,%eax
801038e0:	03 45 f4             	add    -0xc(%ebp),%eax
801038e3:	83 c0 01             	add    $0x1,%eax
801038e6:	89 c2                	mov    %eax,%edx
801038e8:	8b 45 08             	mov    0x8(%ebp),%eax
801038eb:	8b 40 04             	mov    0x4(%eax),%eax
801038ee:	89 54 24 04          	mov    %edx,0x4(%esp)
801038f2:	89 04 24             	mov    %eax,(%esp)
801038f5:	e8 ac c8 ff ff       	call   801001a6 <bread>
801038fa:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(lbuf->data, b->data, BSIZE);
801038fd:	8b 45 08             	mov    0x8(%ebp),%eax
80103900:	8d 50 18             	lea    0x18(%eax),%edx
80103903:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103906:	83 c0 18             	add    $0x18,%eax
80103909:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80103910:	00 
80103911:	89 54 24 04          	mov    %edx,0x4(%esp)
80103915:	89 04 24             	mov    %eax,(%esp)
80103918:	e8 90 22 00 00       	call   80105bad <memmove>
  bwrite(lbuf);
8010391d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103920:	89 04 24             	mov    %eax,(%esp)
80103923:	e8 b5 c8 ff ff       	call   801001dd <bwrite>
  brelse(lbuf);
80103928:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010392b:	89 04 24             	mov    %eax,(%esp)
8010392e:	e8 e4 c8 ff ff       	call   80100217 <brelse>
  if (i == log.lh.n)
80103933:	a1 24 39 11 80       	mov    0x80113924,%eax
80103938:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010393b:	75 0d                	jne    8010394a <log_write+0xf8>
    log.lh.n++;
8010393d:	a1 24 39 11 80       	mov    0x80113924,%eax
80103942:	83 c0 01             	add    $0x1,%eax
80103945:	a3 24 39 11 80       	mov    %eax,0x80113924
  b->flags |= B_DIRTY; // XXX prevent eviction
8010394a:	8b 45 08             	mov    0x8(%ebp),%eax
8010394d:	8b 00                	mov    (%eax),%eax
8010394f:	89 c2                	mov    %eax,%edx
80103951:	83 ca 04             	or     $0x4,%edx
80103954:	8b 45 08             	mov    0x8(%ebp),%eax
80103957:	89 10                	mov    %edx,(%eax)
}
80103959:	c9                   	leave  
8010395a:	c3                   	ret    
	...

8010395c <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
8010395c:	55                   	push   %ebp
8010395d:	89 e5                	mov    %esp,%ebp
8010395f:	8b 45 08             	mov    0x8(%ebp),%eax
80103962:	05 00 00 00 80       	add    $0x80000000,%eax
80103967:	5d                   	pop    %ebp
80103968:	c3                   	ret    

80103969 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80103969:	55                   	push   %ebp
8010396a:	89 e5                	mov    %esp,%ebp
8010396c:	8b 45 08             	mov    0x8(%ebp),%eax
8010396f:	05 00 00 00 80       	add    $0x80000000,%eax
80103974:	5d                   	pop    %ebp
80103975:	c3                   	ret    

80103976 <xchg>:
  asm volatile("sti");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
80103976:	55                   	push   %ebp
80103977:	89 e5                	mov    %esp,%ebp
80103979:	53                   	push   %ebx
8010397a:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
8010397d:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80103980:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
80103983:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80103986:	89 c3                	mov    %eax,%ebx
80103988:	89 d8                	mov    %ebx,%eax
8010398a:	f0 87 02             	lock xchg %eax,(%edx)
8010398d:	89 c3                	mov    %eax,%ebx
8010398f:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80103992:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103995:	83 c4 10             	add    $0x10,%esp
80103998:	5b                   	pop    %ebx
80103999:	5d                   	pop    %ebp
8010399a:	c3                   	ret    

8010399b <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
8010399b:	55                   	push   %ebp
8010399c:	89 e5                	mov    %esp,%ebp
8010399e:	83 e4 f0             	and    $0xfffffff0,%esp
801039a1:	83 ec 10             	sub    $0x10,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
801039a4:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
801039ab:	80 
801039ac:	c7 04 24 5c 6b 11 80 	movl   $0x80116b5c,(%esp)
801039b3:	e8 2a f0 ff ff       	call   801029e2 <kinit1>
  kvmalloc();      // kernel page table
801039b8:	e8 39 52 00 00       	call   80108bf6 <kvmalloc>
  mpinit();        // collect info about this machine
801039bd:	e8 63 04 00 00       	call   80103e25 <mpinit>
  lapicinit(mpbcpu());
801039c2:	e8 2e 02 00 00       	call   80103bf5 <mpbcpu>
801039c7:	89 04 24             	mov    %eax,(%esp)
801039ca:	e8 f5 f8 ff ff       	call   801032c4 <lapicinit>
  seginit();       // set up segments
801039cf:	e8 c5 4b 00 00       	call   80108599 <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
801039d4:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801039da:	0f b6 00             	movzbl (%eax),%eax
801039dd:	0f b6 c0             	movzbl %al,%eax
801039e0:	89 44 24 04          	mov    %eax,0x4(%esp)
801039e4:	c7 04 24 11 96 10 80 	movl   $0x80109611,(%esp)
801039eb:	e8 b1 c9 ff ff       	call   801003a1 <cprintf>
  picinit();       // interrupt controller
801039f0:	e8 95 06 00 00       	call   8010408a <picinit>
  ioapicinit();    // another interrupt controller
801039f5:	e8 cb ee ff ff       	call   801028c5 <ioapicinit>
  consoleinit();   // I/O devices & their interrupts
801039fa:	e8 8e d0 ff ff       	call   80100a8d <consoleinit>
  uartinit();      // serial port
801039ff:	e8 e0 3e 00 00       	call   801078e4 <uartinit>
  pinit();         // process table
80103a04:	e8 a3 0b 00 00       	call   801045ac <pinit>
  tvinit();        // trap vectors
80103a09:	e8 79 3a 00 00       	call   80107487 <tvinit>
  binit();         // buffer cache
80103a0e:	e8 21 c6 ff ff       	call   80100034 <binit>
  fileinit();      // file table
80103a13:	e8 e8 d4 ff ff       	call   80100f00 <fileinit>
  iinit();         // inode cache
80103a18:	e8 96 db ff ff       	call   801015b3 <iinit>
  ideinit();       // disk
80103a1d:	e8 0a eb ff ff       	call   8010252c <ideinit>
  if(!ismp)
80103a22:	a1 64 39 11 80       	mov    0x80113964,%eax
80103a27:	85 c0                	test   %eax,%eax
80103a29:	75 05                	jne    80103a30 <main+0x95>
    timerinit();   // uniprocessor timer
80103a2b:	e8 9a 39 00 00       	call   801073ca <timerinit>
  startothers();   // start other processors
80103a30:	e8 87 00 00 00       	call   80103abc <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80103a35:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
80103a3c:	8e 
80103a3d:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
80103a44:	e8 d1 ef ff ff       	call   80102a1a <kinit2>
  userinit();      // first user process
80103a49:	e8 0d 12 00 00       	call   80104c5b <userinit>
  // Finish setting up this processor in mpmain.
  mpmain();
80103a4e:	e8 22 00 00 00       	call   80103a75 <mpmain>

80103a53 <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
80103a53:	55                   	push   %ebp
80103a54:	89 e5                	mov    %esp,%ebp
80103a56:	83 ec 18             	sub    $0x18,%esp
  switchkvm(); 
80103a59:	e8 af 51 00 00       	call   80108c0d <switchkvm>
  seginit();
80103a5e:	e8 36 4b 00 00       	call   80108599 <seginit>
  lapicinit(cpunum());
80103a63:	e8 b9 f9 ff ff       	call   80103421 <cpunum>
80103a68:	89 04 24             	mov    %eax,(%esp)
80103a6b:	e8 54 f8 ff ff       	call   801032c4 <lapicinit>
  mpmain();
80103a70:	e8 00 00 00 00       	call   80103a75 <mpmain>

80103a75 <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
80103a75:	55                   	push   %ebp
80103a76:	89 e5                	mov    %esp,%ebp
80103a78:	83 ec 18             	sub    $0x18,%esp
  cprintf("cpu%d: starting\n", cpu->id);
80103a7b:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103a81:	0f b6 00             	movzbl (%eax),%eax
80103a84:	0f b6 c0             	movzbl %al,%eax
80103a87:	89 44 24 04          	mov    %eax,0x4(%esp)
80103a8b:	c7 04 24 28 96 10 80 	movl   $0x80109628,(%esp)
80103a92:	e8 0a c9 ff ff       	call   801003a1 <cprintf>
  idtinit();       // load idt register
80103a97:	e8 5f 3b 00 00       	call   801075fb <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
80103a9c:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103aa2:	05 a8 00 00 00       	add    $0xa8,%eax
80103aa7:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80103aae:	00 
80103aaf:	89 04 24             	mov    %eax,(%esp)
80103ab2:	e8 bf fe ff ff       	call   80103976 <xchg>
  scheduler();     // start running processes
80103ab7:	e8 af 17 00 00       	call   8010526b <scheduler>

80103abc <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80103abc:	55                   	push   %ebp
80103abd:	89 e5                	mov    %esp,%ebp
80103abf:	53                   	push   %ebx
80103ac0:	83 ec 24             	sub    $0x24,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
80103ac3:	c7 04 24 00 70 00 00 	movl   $0x7000,(%esp)
80103aca:	e8 9a fe ff ff       	call   80103969 <p2v>
80103acf:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80103ad2:	b8 8a 00 00 00       	mov    $0x8a,%eax
80103ad7:	89 44 24 08          	mov    %eax,0x8(%esp)
80103adb:	c7 44 24 04 2c c5 10 	movl   $0x8010c52c,0x4(%esp)
80103ae2:	80 
80103ae3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103ae6:	89 04 24             	mov    %eax,(%esp)
80103ae9:	e8 bf 20 00 00       	call   80105bad <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80103aee:	c7 45 f4 80 39 11 80 	movl   $0x80113980,-0xc(%ebp)
80103af5:	e9 86 00 00 00       	jmp    80103b80 <startothers+0xc4>
    if(c == cpus+cpunum())  // We've started already.
80103afa:	e8 22 f9 ff ff       	call   80103421 <cpunum>
80103aff:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103b05:	05 80 39 11 80       	add    $0x80113980,%eax
80103b0a:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103b0d:	74 69                	je     80103b78 <startothers+0xbc>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what 
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
80103b0f:	e8 fc ef ff ff       	call   80102b10 <kalloc>
80103b14:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
80103b17:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b1a:	83 e8 04             	sub    $0x4,%eax
80103b1d:	8b 55 ec             	mov    -0x14(%ebp),%edx
80103b20:	81 c2 00 10 00 00    	add    $0x1000,%edx
80103b26:	89 10                	mov    %edx,(%eax)
    *(void**)(code-8) = mpenter;
80103b28:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b2b:	83 e8 08             	sub    $0x8,%eax
80103b2e:	c7 00 53 3a 10 80    	movl   $0x80103a53,(%eax)
    *(int**)(code-12) = (void *) v2p(entrypgdir);
80103b34:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b37:	8d 58 f4             	lea    -0xc(%eax),%ebx
80103b3a:	c7 04 24 00 b0 10 80 	movl   $0x8010b000,(%esp)
80103b41:	e8 16 fe ff ff       	call   8010395c <v2p>
80103b46:	89 03                	mov    %eax,(%ebx)

    lapicstartap(c->id, v2p(code));
80103b48:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b4b:	89 04 24             	mov    %eax,(%esp)
80103b4e:	e8 09 fe ff ff       	call   8010395c <v2p>
80103b53:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103b56:	0f b6 12             	movzbl (%edx),%edx
80103b59:	0f b6 d2             	movzbl %dl,%edx
80103b5c:	89 44 24 04          	mov    %eax,0x4(%esp)
80103b60:	89 14 24             	mov    %edx,(%esp)
80103b63:	e8 3f f9 ff ff       	call   801034a7 <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80103b68:	90                   	nop
80103b69:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b6c:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
80103b72:	85 c0                	test   %eax,%eax
80103b74:	74 f3                	je     80103b69 <startothers+0xad>
80103b76:	eb 01                	jmp    80103b79 <startothers+0xbd>
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
    if(c == cpus+cpunum())  // We've started already.
      continue;
80103b78:	90                   	nop
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
80103b79:	81 45 f4 bc 00 00 00 	addl   $0xbc,-0xc(%ebp)
80103b80:	a1 60 3f 11 80       	mov    0x80113f60,%eax
80103b85:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103b8b:	05 80 39 11 80       	add    $0x80113980,%eax
80103b90:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103b93:	0f 87 61 ff ff ff    	ja     80103afa <startothers+0x3e>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;
  }
}
80103b99:	83 c4 24             	add    $0x24,%esp
80103b9c:	5b                   	pop    %ebx
80103b9d:	5d                   	pop    %ebp
80103b9e:	c3                   	ret    
	...

80103ba0 <p2v>:
80103ba0:	55                   	push   %ebp
80103ba1:	89 e5                	mov    %esp,%ebp
80103ba3:	8b 45 08             	mov    0x8(%ebp),%eax
80103ba6:	05 00 00 00 80       	add    $0x80000000,%eax
80103bab:	5d                   	pop    %ebp
80103bac:	c3                   	ret    

80103bad <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80103bad:	55                   	push   %ebp
80103bae:	89 e5                	mov    %esp,%ebp
80103bb0:	53                   	push   %ebx
80103bb1:	83 ec 14             	sub    $0x14,%esp
80103bb4:	8b 45 08             	mov    0x8(%ebp),%eax
80103bb7:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80103bbb:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80103bbf:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80103bc3:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80103bc7:	ec                   	in     (%dx),%al
80103bc8:	89 c3                	mov    %eax,%ebx
80103bca:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80103bcd:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80103bd1:	83 c4 14             	add    $0x14,%esp
80103bd4:	5b                   	pop    %ebx
80103bd5:	5d                   	pop    %ebp
80103bd6:	c3                   	ret    

80103bd7 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103bd7:	55                   	push   %ebp
80103bd8:	89 e5                	mov    %esp,%ebp
80103bda:	83 ec 08             	sub    $0x8,%esp
80103bdd:	8b 55 08             	mov    0x8(%ebp),%edx
80103be0:	8b 45 0c             	mov    0xc(%ebp),%eax
80103be3:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103be7:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103bea:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103bee:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103bf2:	ee                   	out    %al,(%dx)
}
80103bf3:	c9                   	leave  
80103bf4:	c3                   	ret    

80103bf5 <mpbcpu>:
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
80103bf5:	55                   	push   %ebp
80103bf6:	89 e5                	mov    %esp,%ebp
  return bcpu-cpus;
80103bf8:	a1 64 c6 10 80       	mov    0x8010c664,%eax
80103bfd:	89 c2                	mov    %eax,%edx
80103bff:	b8 80 39 11 80       	mov    $0x80113980,%eax
80103c04:	89 d1                	mov    %edx,%ecx
80103c06:	29 c1                	sub    %eax,%ecx
80103c08:	89 c8                	mov    %ecx,%eax
80103c0a:	c1 f8 02             	sar    $0x2,%eax
80103c0d:	69 c0 cf 46 7d 67    	imul   $0x677d46cf,%eax,%eax
}
80103c13:	5d                   	pop    %ebp
80103c14:	c3                   	ret    

80103c15 <sum>:

static uchar
sum(uchar *addr, int len)
{
80103c15:	55                   	push   %ebp
80103c16:	89 e5                	mov    %esp,%ebp
80103c18:	83 ec 10             	sub    $0x10,%esp
  int i, sum;
  
  sum = 0;
80103c1b:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
80103c22:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80103c29:	eb 13                	jmp    80103c3e <sum+0x29>
    sum += addr[i];
80103c2b:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103c2e:	03 45 08             	add    0x8(%ebp),%eax
80103c31:	0f b6 00             	movzbl (%eax),%eax
80103c34:	0f b6 c0             	movzbl %al,%eax
80103c37:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
80103c3a:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103c3e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103c41:	3b 45 0c             	cmp    0xc(%ebp),%eax
80103c44:	7c e5                	jl     80103c2b <sum+0x16>
    sum += addr[i];
  return sum;
80103c46:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103c49:	c9                   	leave  
80103c4a:	c3                   	ret    

80103c4b <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80103c4b:	55                   	push   %ebp
80103c4c:	89 e5                	mov    %esp,%ebp
80103c4e:	83 ec 28             	sub    $0x28,%esp
  uchar *e, *p, *addr;

  addr = p2v(a);
80103c51:	8b 45 08             	mov    0x8(%ebp),%eax
80103c54:	89 04 24             	mov    %eax,(%esp)
80103c57:	e8 44 ff ff ff       	call   80103ba0 <p2v>
80103c5c:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
80103c5f:	8b 45 0c             	mov    0xc(%ebp),%eax
80103c62:	03 45 f0             	add    -0x10(%ebp),%eax
80103c65:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
80103c68:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103c6b:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103c6e:	eb 3f                	jmp    80103caf <mpsearch1+0x64>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80103c70:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80103c77:	00 
80103c78:	c7 44 24 04 3c 96 10 	movl   $0x8010963c,0x4(%esp)
80103c7f:	80 
80103c80:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c83:	89 04 24             	mov    %eax,(%esp)
80103c86:	e8 c6 1e 00 00       	call   80105b51 <memcmp>
80103c8b:	85 c0                	test   %eax,%eax
80103c8d:	75 1c                	jne    80103cab <mpsearch1+0x60>
80103c8f:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
80103c96:	00 
80103c97:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c9a:	89 04 24             	mov    %eax,(%esp)
80103c9d:	e8 73 ff ff ff       	call   80103c15 <sum>
80103ca2:	84 c0                	test   %al,%al
80103ca4:	75 05                	jne    80103cab <mpsearch1+0x60>
      return (struct mp*)p;
80103ca6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ca9:	eb 11                	jmp    80103cbc <mpsearch1+0x71>
{
  uchar *e, *p, *addr;

  addr = p2v(a);
  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
80103cab:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80103caf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103cb2:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103cb5:	72 b9                	jb     80103c70 <mpsearch1+0x25>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
80103cb7:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103cbc:	c9                   	leave  
80103cbd:	c3                   	ret    

80103cbe <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80103cbe:	55                   	push   %ebp
80103cbf:	89 e5                	mov    %esp,%ebp
80103cc1:	83 ec 28             	sub    $0x28,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
80103cc4:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80103ccb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103cce:	83 c0 0f             	add    $0xf,%eax
80103cd1:	0f b6 00             	movzbl (%eax),%eax
80103cd4:	0f b6 c0             	movzbl %al,%eax
80103cd7:	89 c2                	mov    %eax,%edx
80103cd9:	c1 e2 08             	shl    $0x8,%edx
80103cdc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103cdf:	83 c0 0e             	add    $0xe,%eax
80103ce2:	0f b6 00             	movzbl (%eax),%eax
80103ce5:	0f b6 c0             	movzbl %al,%eax
80103ce8:	09 d0                	or     %edx,%eax
80103cea:	c1 e0 04             	shl    $0x4,%eax
80103ced:	89 45 f0             	mov    %eax,-0x10(%ebp)
80103cf0:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103cf4:	74 21                	je     80103d17 <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
80103cf6:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80103cfd:	00 
80103cfe:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d01:	89 04 24             	mov    %eax,(%esp)
80103d04:	e8 42 ff ff ff       	call   80103c4b <mpsearch1>
80103d09:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103d0c:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103d10:	74 50                	je     80103d62 <mpsearch+0xa4>
      return mp;
80103d12:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103d15:	eb 5f                	jmp    80103d76 <mpsearch+0xb8>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80103d17:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d1a:	83 c0 14             	add    $0x14,%eax
80103d1d:	0f b6 00             	movzbl (%eax),%eax
80103d20:	0f b6 c0             	movzbl %al,%eax
80103d23:	89 c2                	mov    %eax,%edx
80103d25:	c1 e2 08             	shl    $0x8,%edx
80103d28:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d2b:	83 c0 13             	add    $0x13,%eax
80103d2e:	0f b6 00             	movzbl (%eax),%eax
80103d31:	0f b6 c0             	movzbl %al,%eax
80103d34:	09 d0                	or     %edx,%eax
80103d36:	c1 e0 0a             	shl    $0xa,%eax
80103d39:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
80103d3c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d3f:	2d 00 04 00 00       	sub    $0x400,%eax
80103d44:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80103d4b:	00 
80103d4c:	89 04 24             	mov    %eax,(%esp)
80103d4f:	e8 f7 fe ff ff       	call   80103c4b <mpsearch1>
80103d54:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103d57:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103d5b:	74 05                	je     80103d62 <mpsearch+0xa4>
      return mp;
80103d5d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103d60:	eb 14                	jmp    80103d76 <mpsearch+0xb8>
  }
  return mpsearch1(0xF0000, 0x10000);
80103d62:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103d69:	00 
80103d6a:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
80103d71:	e8 d5 fe ff ff       	call   80103c4b <mpsearch1>
}
80103d76:	c9                   	leave  
80103d77:	c3                   	ret    

80103d78 <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80103d78:	55                   	push   %ebp
80103d79:	89 e5                	mov    %esp,%ebp
80103d7b:	83 ec 28             	sub    $0x28,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80103d7e:	e8 3b ff ff ff       	call   80103cbe <mpsearch>
80103d83:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103d86:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103d8a:	74 0a                	je     80103d96 <mpconfig+0x1e>
80103d8c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d8f:	8b 40 04             	mov    0x4(%eax),%eax
80103d92:	85 c0                	test   %eax,%eax
80103d94:	75 0a                	jne    80103da0 <mpconfig+0x28>
    return 0;
80103d96:	b8 00 00 00 00       	mov    $0x0,%eax
80103d9b:	e9 83 00 00 00       	jmp    80103e23 <mpconfig+0xab>
  conf = (struct mpconf*) p2v((uint) mp->physaddr);
80103da0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103da3:	8b 40 04             	mov    0x4(%eax),%eax
80103da6:	89 04 24             	mov    %eax,(%esp)
80103da9:	e8 f2 fd ff ff       	call   80103ba0 <p2v>
80103dae:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
80103db1:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80103db8:	00 
80103db9:	c7 44 24 04 41 96 10 	movl   $0x80109641,0x4(%esp)
80103dc0:	80 
80103dc1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103dc4:	89 04 24             	mov    %eax,(%esp)
80103dc7:	e8 85 1d 00 00       	call   80105b51 <memcmp>
80103dcc:	85 c0                	test   %eax,%eax
80103dce:	74 07                	je     80103dd7 <mpconfig+0x5f>
    return 0;
80103dd0:	b8 00 00 00 00       	mov    $0x0,%eax
80103dd5:	eb 4c                	jmp    80103e23 <mpconfig+0xab>
  if(conf->version != 1 && conf->version != 4)
80103dd7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103dda:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80103dde:	3c 01                	cmp    $0x1,%al
80103de0:	74 12                	je     80103df4 <mpconfig+0x7c>
80103de2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103de5:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80103de9:	3c 04                	cmp    $0x4,%al
80103deb:	74 07                	je     80103df4 <mpconfig+0x7c>
    return 0;
80103ded:	b8 00 00 00 00       	mov    $0x0,%eax
80103df2:	eb 2f                	jmp    80103e23 <mpconfig+0xab>
  if(sum((uchar*)conf, conf->length) != 0)
80103df4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103df7:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80103dfb:	0f b7 c0             	movzwl %ax,%eax
80103dfe:	89 44 24 04          	mov    %eax,0x4(%esp)
80103e02:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103e05:	89 04 24             	mov    %eax,(%esp)
80103e08:	e8 08 fe ff ff       	call   80103c15 <sum>
80103e0d:	84 c0                	test   %al,%al
80103e0f:	74 07                	je     80103e18 <mpconfig+0xa0>
    return 0;
80103e11:	b8 00 00 00 00       	mov    $0x0,%eax
80103e16:	eb 0b                	jmp    80103e23 <mpconfig+0xab>
  *pmp = mp;
80103e18:	8b 45 08             	mov    0x8(%ebp),%eax
80103e1b:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103e1e:	89 10                	mov    %edx,(%eax)
  return conf;
80103e20:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80103e23:	c9                   	leave  
80103e24:	c3                   	ret    

80103e25 <mpinit>:

void
mpinit(void)
{
80103e25:	55                   	push   %ebp
80103e26:	89 e5                	mov    %esp,%ebp
80103e28:	83 ec 38             	sub    $0x38,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
80103e2b:	c7 05 64 c6 10 80 80 	movl   $0x80113980,0x8010c664
80103e32:	39 11 80 
  if((conf = mpconfig(&mp)) == 0)
80103e35:	8d 45 e0             	lea    -0x20(%ebp),%eax
80103e38:	89 04 24             	mov    %eax,(%esp)
80103e3b:	e8 38 ff ff ff       	call   80103d78 <mpconfig>
80103e40:	89 45 f0             	mov    %eax,-0x10(%ebp)
80103e43:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103e47:	0f 84 9c 01 00 00    	je     80103fe9 <mpinit+0x1c4>
    return;
  ismp = 1;
80103e4d:	c7 05 64 39 11 80 01 	movl   $0x1,0x80113964
80103e54:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
80103e57:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103e5a:	8b 40 24             	mov    0x24(%eax),%eax
80103e5d:	a3 d4 38 11 80       	mov    %eax,0x801138d4
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80103e62:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103e65:	83 c0 2c             	add    $0x2c,%eax
80103e68:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103e6b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103e6e:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80103e72:	0f b7 c0             	movzwl %ax,%eax
80103e75:	03 45 f0             	add    -0x10(%ebp),%eax
80103e78:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103e7b:	e9 f4 00 00 00       	jmp    80103f74 <mpinit+0x14f>
    switch(*p){
80103e80:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103e83:	0f b6 00             	movzbl (%eax),%eax
80103e86:	0f b6 c0             	movzbl %al,%eax
80103e89:	83 f8 04             	cmp    $0x4,%eax
80103e8c:	0f 87 bf 00 00 00    	ja     80103f51 <mpinit+0x12c>
80103e92:	8b 04 85 84 96 10 80 	mov    -0x7fef697c(,%eax,4),%eax
80103e99:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
80103e9b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103e9e:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(ncpu != proc->apicid){
80103ea1:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103ea4:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103ea8:	0f b6 d0             	movzbl %al,%edx
80103eab:	a1 60 3f 11 80       	mov    0x80113f60,%eax
80103eb0:	39 c2                	cmp    %eax,%edx
80103eb2:	74 2d                	je     80103ee1 <mpinit+0xbc>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
80103eb4:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103eb7:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103ebb:	0f b6 d0             	movzbl %al,%edx
80103ebe:	a1 60 3f 11 80       	mov    0x80113f60,%eax
80103ec3:	89 54 24 08          	mov    %edx,0x8(%esp)
80103ec7:	89 44 24 04          	mov    %eax,0x4(%esp)
80103ecb:	c7 04 24 46 96 10 80 	movl   $0x80109646,(%esp)
80103ed2:	e8 ca c4 ff ff       	call   801003a1 <cprintf>
        ismp = 0;
80103ed7:	c7 05 64 39 11 80 00 	movl   $0x0,0x80113964
80103ede:	00 00 00 
      }
      if(proc->flags & MPBOOT)
80103ee1:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103ee4:	0f b6 40 03          	movzbl 0x3(%eax),%eax
80103ee8:	0f b6 c0             	movzbl %al,%eax
80103eeb:	83 e0 02             	and    $0x2,%eax
80103eee:	85 c0                	test   %eax,%eax
80103ef0:	74 15                	je     80103f07 <mpinit+0xe2>
        bcpu = &cpus[ncpu];
80103ef2:	a1 60 3f 11 80       	mov    0x80113f60,%eax
80103ef7:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103efd:	05 80 39 11 80       	add    $0x80113980,%eax
80103f02:	a3 64 c6 10 80       	mov    %eax,0x8010c664
      cpus[ncpu].id = ncpu;
80103f07:	8b 15 60 3f 11 80    	mov    0x80113f60,%edx
80103f0d:	a1 60 3f 11 80       	mov    0x80113f60,%eax
80103f12:	69 d2 bc 00 00 00    	imul   $0xbc,%edx,%edx
80103f18:	81 c2 80 39 11 80    	add    $0x80113980,%edx
80103f1e:	88 02                	mov    %al,(%edx)
      ncpu++;
80103f20:	a1 60 3f 11 80       	mov    0x80113f60,%eax
80103f25:	83 c0 01             	add    $0x1,%eax
80103f28:	a3 60 3f 11 80       	mov    %eax,0x80113f60
      p += sizeof(struct mpproc);
80103f2d:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
80103f31:	eb 41                	jmp    80103f74 <mpinit+0x14f>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
80103f33:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f36:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      ioapicid = ioapic->apicno;
80103f39:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80103f3c:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103f40:	a2 60 39 11 80       	mov    %al,0x80113960
      p += sizeof(struct mpioapic);
80103f45:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80103f49:	eb 29                	jmp    80103f74 <mpinit+0x14f>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80103f4b:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80103f4f:	eb 23                	jmp    80103f74 <mpinit+0x14f>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
80103f51:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f54:	0f b6 00             	movzbl (%eax),%eax
80103f57:	0f b6 c0             	movzbl %al,%eax
80103f5a:	89 44 24 04          	mov    %eax,0x4(%esp)
80103f5e:	c7 04 24 64 96 10 80 	movl   $0x80109664,(%esp)
80103f65:	e8 37 c4 ff ff       	call   801003a1 <cprintf>
      ismp = 0;
80103f6a:	c7 05 64 39 11 80 00 	movl   $0x0,0x80113964
80103f71:	00 00 00 
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80103f74:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f77:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103f7a:	0f 82 00 ff ff ff    	jb     80103e80 <mpinit+0x5b>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
      ismp = 0;
    }
  }
  if(!ismp){
80103f80:	a1 64 39 11 80       	mov    0x80113964,%eax
80103f85:	85 c0                	test   %eax,%eax
80103f87:	75 1d                	jne    80103fa6 <mpinit+0x181>
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
80103f89:	c7 05 60 3f 11 80 01 	movl   $0x1,0x80113f60
80103f90:	00 00 00 
    lapic = 0;
80103f93:	c7 05 d4 38 11 80 00 	movl   $0x0,0x801138d4
80103f9a:	00 00 00 
    ioapicid = 0;
80103f9d:	c6 05 60 39 11 80 00 	movb   $0x0,0x80113960
    return;
80103fa4:	eb 44                	jmp    80103fea <mpinit+0x1c5>
  }

  if(mp->imcrp){
80103fa6:	8b 45 e0             	mov    -0x20(%ebp),%eax
80103fa9:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
80103fad:	84 c0                	test   %al,%al
80103faf:	74 39                	je     80103fea <mpinit+0x1c5>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
80103fb1:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
80103fb8:	00 
80103fb9:	c7 04 24 22 00 00 00 	movl   $0x22,(%esp)
80103fc0:	e8 12 fc ff ff       	call   80103bd7 <outb>
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80103fc5:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80103fcc:	e8 dc fb ff ff       	call   80103bad <inb>
80103fd1:	83 c8 01             	or     $0x1,%eax
80103fd4:	0f b6 c0             	movzbl %al,%eax
80103fd7:	89 44 24 04          	mov    %eax,0x4(%esp)
80103fdb:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80103fe2:	e8 f0 fb ff ff       	call   80103bd7 <outb>
80103fe7:	eb 01                	jmp    80103fea <mpinit+0x1c5>
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
80103fe9:	90                   	nop
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
  }
}
80103fea:	c9                   	leave  
80103feb:	c3                   	ret    

80103fec <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103fec:	55                   	push   %ebp
80103fed:	89 e5                	mov    %esp,%ebp
80103fef:	83 ec 08             	sub    $0x8,%esp
80103ff2:	8b 55 08             	mov    0x8(%ebp),%edx
80103ff5:	8b 45 0c             	mov    0xc(%ebp),%eax
80103ff8:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103ffc:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103fff:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80104003:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80104007:	ee                   	out    %al,(%dx)
}
80104008:	c9                   	leave  
80104009:	c3                   	ret    

8010400a <picsetmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static ushort irqmask = 0xFFFF & ~(1<<IRQ_SLAVE);

static void
picsetmask(ushort mask)
{
8010400a:	55                   	push   %ebp
8010400b:	89 e5                	mov    %esp,%ebp
8010400d:	83 ec 0c             	sub    $0xc,%esp
80104010:	8b 45 08             	mov    0x8(%ebp),%eax
80104013:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  irqmask = mask;
80104017:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
8010401b:	66 a3 00 c0 10 80    	mov    %ax,0x8010c000
  outb(IO_PIC1+1, mask);
80104021:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80104025:	0f b6 c0             	movzbl %al,%eax
80104028:	89 44 24 04          	mov    %eax,0x4(%esp)
8010402c:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104033:	e8 b4 ff ff ff       	call   80103fec <outb>
  outb(IO_PIC2+1, mask >> 8);
80104038:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
8010403c:	66 c1 e8 08          	shr    $0x8,%ax
80104040:	0f b6 c0             	movzbl %al,%eax
80104043:	89 44 24 04          	mov    %eax,0x4(%esp)
80104047:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
8010404e:	e8 99 ff ff ff       	call   80103fec <outb>
}
80104053:	c9                   	leave  
80104054:	c3                   	ret    

80104055 <picenable>:

void
picenable(int irq)
{
80104055:	55                   	push   %ebp
80104056:	89 e5                	mov    %esp,%ebp
80104058:	53                   	push   %ebx
80104059:	83 ec 04             	sub    $0x4,%esp
  picsetmask(irqmask & ~(1<<irq));
8010405c:	8b 45 08             	mov    0x8(%ebp),%eax
8010405f:	ba 01 00 00 00       	mov    $0x1,%edx
80104064:	89 d3                	mov    %edx,%ebx
80104066:	89 c1                	mov    %eax,%ecx
80104068:	d3 e3                	shl    %cl,%ebx
8010406a:	89 d8                	mov    %ebx,%eax
8010406c:	89 c2                	mov    %eax,%edx
8010406e:	f7 d2                	not    %edx
80104070:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
80104077:	21 d0                	and    %edx,%eax
80104079:	0f b7 c0             	movzwl %ax,%eax
8010407c:	89 04 24             	mov    %eax,(%esp)
8010407f:	e8 86 ff ff ff       	call   8010400a <picsetmask>
}
80104084:	83 c4 04             	add    $0x4,%esp
80104087:	5b                   	pop    %ebx
80104088:	5d                   	pop    %ebp
80104089:	c3                   	ret    

8010408a <picinit>:

// Initialize the 8259A interrupt controllers.
void
picinit(void)
{
8010408a:	55                   	push   %ebp
8010408b:	89 e5                	mov    %esp,%ebp
8010408d:	83 ec 08             	sub    $0x8,%esp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
80104090:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80104097:	00 
80104098:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
8010409f:	e8 48 ff ff ff       	call   80103fec <outb>
  outb(IO_PIC2+1, 0xFF);
801040a4:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
801040ab:	00 
801040ac:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
801040b3:	e8 34 ff ff ff       	call   80103fec <outb>

  // ICW1:  0001g0hi
  //    g:  0 = edge triggering, 1 = level triggering
  //    h:  0 = cascaded PICs, 1 = master only
  //    i:  0 = no ICW4, 1 = ICW4 required
  outb(IO_PIC1, 0x11);
801040b8:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
801040bf:	00 
801040c0:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
801040c7:	e8 20 ff ff ff       	call   80103fec <outb>

  // ICW2:  Vector offset
  outb(IO_PIC1+1, T_IRQ0);
801040cc:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
801040d3:	00 
801040d4:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
801040db:	e8 0c ff ff ff       	call   80103fec <outb>

  // ICW3:  (master PIC) bit mask of IR lines connected to slaves
  //        (slave PIC) 3-bit # of slave's connection to master
  outb(IO_PIC1+1, 1<<IRQ_SLAVE);
801040e0:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
801040e7:	00 
801040e8:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
801040ef:	e8 f8 fe ff ff       	call   80103fec <outb>
  //    m:  0 = slave PIC, 1 = master PIC
  //      (ignored when b is 0, as the master/slave role
  //      can be hardwired).
  //    a:  1 = Automatic EOI mode
  //    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
  outb(IO_PIC1+1, 0x3);
801040f4:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
801040fb:	00 
801040fc:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104103:	e8 e4 fe ff ff       	call   80103fec <outb>

  // Set up slave (8259A-2)
  outb(IO_PIC2, 0x11);                  // ICW1
80104108:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
8010410f:	00 
80104110:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104117:	e8 d0 fe ff ff       	call   80103fec <outb>
  outb(IO_PIC2+1, T_IRQ0 + 8);      // ICW2
8010411c:	c7 44 24 04 28 00 00 	movl   $0x28,0x4(%esp)
80104123:	00 
80104124:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
8010412b:	e8 bc fe ff ff       	call   80103fec <outb>
  outb(IO_PIC2+1, IRQ_SLAVE);           // ICW3
80104130:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80104137:	00 
80104138:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
8010413f:	e8 a8 fe ff ff       	call   80103fec <outb>
  // NB Automatic EOI mode doesn't tend to work on the slave.
  // Linux source code says it's "to be investigated".
  outb(IO_PIC2+1, 0x3);                 // ICW4
80104144:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
8010414b:	00 
8010414c:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104153:	e8 94 fe ff ff       	call   80103fec <outb>

  // OCW3:  0ef01prs
  //   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
  //    p:  0 = no polling, 1 = polling mode
  //   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
  outb(IO_PIC1, 0x68);             // clear specific mask
80104158:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
8010415f:	00 
80104160:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80104167:	e8 80 fe ff ff       	call   80103fec <outb>
  outb(IO_PIC1, 0x0a);             // read IRR by default
8010416c:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80104173:	00 
80104174:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010417b:	e8 6c fe ff ff       	call   80103fec <outb>

  outb(IO_PIC2, 0x68);             // OCW3
80104180:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80104187:	00 
80104188:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
8010418f:	e8 58 fe ff ff       	call   80103fec <outb>
  outb(IO_PIC2, 0x0a);             // OCW3
80104194:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
8010419b:	00 
8010419c:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
801041a3:	e8 44 fe ff ff       	call   80103fec <outb>

  if(irqmask != 0xFFFF)
801041a8:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
801041af:	66 83 f8 ff          	cmp    $0xffff,%ax
801041b3:	74 12                	je     801041c7 <picinit+0x13d>
    picsetmask(irqmask);
801041b5:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
801041bc:	0f b7 c0             	movzwl %ax,%eax
801041bf:	89 04 24             	mov    %eax,(%esp)
801041c2:	e8 43 fe ff ff       	call   8010400a <picsetmask>
}
801041c7:	c9                   	leave  
801041c8:	c3                   	ret    
801041c9:	00 00                	add    %al,(%eax)
	...

801041cc <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
801041cc:	55                   	push   %ebp
801041cd:	89 e5                	mov    %esp,%ebp
801041cf:	83 ec 28             	sub    $0x28,%esp
  struct pipe *p;

  p = 0;
801041d2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
801041d9:	8b 45 0c             	mov    0xc(%ebp),%eax
801041dc:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
801041e2:	8b 45 0c             	mov    0xc(%ebp),%eax
801041e5:	8b 10                	mov    (%eax),%edx
801041e7:	8b 45 08             	mov    0x8(%ebp),%eax
801041ea:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
801041ec:	e8 2b cd ff ff       	call   80100f1c <filealloc>
801041f1:	8b 55 08             	mov    0x8(%ebp),%edx
801041f4:	89 02                	mov    %eax,(%edx)
801041f6:	8b 45 08             	mov    0x8(%ebp),%eax
801041f9:	8b 00                	mov    (%eax),%eax
801041fb:	85 c0                	test   %eax,%eax
801041fd:	0f 84 c8 00 00 00    	je     801042cb <pipealloc+0xff>
80104203:	e8 14 cd ff ff       	call   80100f1c <filealloc>
80104208:	8b 55 0c             	mov    0xc(%ebp),%edx
8010420b:	89 02                	mov    %eax,(%edx)
8010420d:	8b 45 0c             	mov    0xc(%ebp),%eax
80104210:	8b 00                	mov    (%eax),%eax
80104212:	85 c0                	test   %eax,%eax
80104214:	0f 84 b1 00 00 00    	je     801042cb <pipealloc+0xff>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
8010421a:	e8 f1 e8 ff ff       	call   80102b10 <kalloc>
8010421f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104222:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104226:	0f 84 9e 00 00 00    	je     801042ca <pipealloc+0xfe>
    goto bad;
  p->readopen = 1;
8010422c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010422f:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80104236:	00 00 00 
  p->writeopen = 1;
80104239:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010423c:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80104243:	00 00 00 
  p->nwrite = 0;
80104246:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104249:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80104250:	00 00 00 
  p->nread = 0;
80104253:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104256:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
8010425d:	00 00 00 
  initlock(&p->lock, "pipe");
80104260:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104263:	c7 44 24 04 98 96 10 	movl   $0x80109698,0x4(%esp)
8010426a:	80 
8010426b:	89 04 24             	mov    %eax,(%esp)
8010426e:	e8 bf 15 00 00       	call   80105832 <initlock>
  (*f0)->type = FD_PIPE;
80104273:	8b 45 08             	mov    0x8(%ebp),%eax
80104276:	8b 00                	mov    (%eax),%eax
80104278:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
8010427e:	8b 45 08             	mov    0x8(%ebp),%eax
80104281:	8b 00                	mov    (%eax),%eax
80104283:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80104287:	8b 45 08             	mov    0x8(%ebp),%eax
8010428a:	8b 00                	mov    (%eax),%eax
8010428c:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80104290:	8b 45 08             	mov    0x8(%ebp),%eax
80104293:	8b 00                	mov    (%eax),%eax
80104295:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104298:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
8010429b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010429e:	8b 00                	mov    (%eax),%eax
801042a0:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
801042a6:	8b 45 0c             	mov    0xc(%ebp),%eax
801042a9:	8b 00                	mov    (%eax),%eax
801042ab:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
801042af:	8b 45 0c             	mov    0xc(%ebp),%eax
801042b2:	8b 00                	mov    (%eax),%eax
801042b4:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
801042b8:	8b 45 0c             	mov    0xc(%ebp),%eax
801042bb:	8b 00                	mov    (%eax),%eax
801042bd:	8b 55 f4             	mov    -0xc(%ebp),%edx
801042c0:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
801042c3:	b8 00 00 00 00       	mov    $0x0,%eax
801042c8:	eb 43                	jmp    8010430d <pipealloc+0x141>
  p = 0;
  *f0 = *f1 = 0;
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
    goto bad;
801042ca:	90                   	nop
  (*f1)->pipe = p;
  return 0;

//PAGEBREAK: 20
 bad:
  if(p)
801042cb:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801042cf:	74 0b                	je     801042dc <pipealloc+0x110>
    kfree((char*)p);
801042d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042d4:	89 04 24             	mov    %eax,(%esp)
801042d7:	e8 9b e7 ff ff       	call   80102a77 <kfree>
  if(*f0)
801042dc:	8b 45 08             	mov    0x8(%ebp),%eax
801042df:	8b 00                	mov    (%eax),%eax
801042e1:	85 c0                	test   %eax,%eax
801042e3:	74 0d                	je     801042f2 <pipealloc+0x126>
    fileclose(*f0);
801042e5:	8b 45 08             	mov    0x8(%ebp),%eax
801042e8:	8b 00                	mov    (%eax),%eax
801042ea:	89 04 24             	mov    %eax,(%esp)
801042ed:	e8 d2 cc ff ff       	call   80100fc4 <fileclose>
  if(*f1)
801042f2:	8b 45 0c             	mov    0xc(%ebp),%eax
801042f5:	8b 00                	mov    (%eax),%eax
801042f7:	85 c0                	test   %eax,%eax
801042f9:	74 0d                	je     80104308 <pipealloc+0x13c>
    fileclose(*f1);
801042fb:	8b 45 0c             	mov    0xc(%ebp),%eax
801042fe:	8b 00                	mov    (%eax),%eax
80104300:	89 04 24             	mov    %eax,(%esp)
80104303:	e8 bc cc ff ff       	call   80100fc4 <fileclose>
  return -1;
80104308:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010430d:	c9                   	leave  
8010430e:	c3                   	ret    

8010430f <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
8010430f:	55                   	push   %ebp
80104310:	89 e5                	mov    %esp,%ebp
80104312:	83 ec 18             	sub    $0x18,%esp
  acquire(&p->lock);
80104315:	8b 45 08             	mov    0x8(%ebp),%eax
80104318:	89 04 24             	mov    %eax,(%esp)
8010431b:	e8 33 15 00 00       	call   80105853 <acquire>
  if(writable){
80104320:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80104324:	74 1f                	je     80104345 <pipeclose+0x36>
    p->writeopen = 0;
80104326:	8b 45 08             	mov    0x8(%ebp),%eax
80104329:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
80104330:	00 00 00 
    wakeup(&p->nread);
80104333:	8b 45 08             	mov    0x8(%ebp),%eax
80104336:	05 34 02 00 00       	add    $0x234,%eax
8010433b:	89 04 24             	mov    %eax,(%esp)
8010433e:	e8 10 12 00 00       	call   80105553 <wakeup>
80104343:	eb 1d                	jmp    80104362 <pipeclose+0x53>
  } else {
    p->readopen = 0;
80104345:	8b 45 08             	mov    0x8(%ebp),%eax
80104348:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
8010434f:	00 00 00 
    wakeup(&p->nwrite);
80104352:	8b 45 08             	mov    0x8(%ebp),%eax
80104355:	05 38 02 00 00       	add    $0x238,%eax
8010435a:	89 04 24             	mov    %eax,(%esp)
8010435d:	e8 f1 11 00 00       	call   80105553 <wakeup>
  }
  if(p->readopen == 0 && p->writeopen == 0){
80104362:	8b 45 08             	mov    0x8(%ebp),%eax
80104365:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
8010436b:	85 c0                	test   %eax,%eax
8010436d:	75 25                	jne    80104394 <pipeclose+0x85>
8010436f:	8b 45 08             	mov    0x8(%ebp),%eax
80104372:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80104378:	85 c0                	test   %eax,%eax
8010437a:	75 18                	jne    80104394 <pipeclose+0x85>
    release(&p->lock);
8010437c:	8b 45 08             	mov    0x8(%ebp),%eax
8010437f:	89 04 24             	mov    %eax,(%esp)
80104382:	e8 67 15 00 00       	call   801058ee <release>
    kfree((char*)p);
80104387:	8b 45 08             	mov    0x8(%ebp),%eax
8010438a:	89 04 24             	mov    %eax,(%esp)
8010438d:	e8 e5 e6 ff ff       	call   80102a77 <kfree>
80104392:	eb 0b                	jmp    8010439f <pipeclose+0x90>
  } else
    release(&p->lock);
80104394:	8b 45 08             	mov    0x8(%ebp),%eax
80104397:	89 04 24             	mov    %eax,(%esp)
8010439a:	e8 4f 15 00 00       	call   801058ee <release>
}
8010439f:	c9                   	leave  
801043a0:	c3                   	ret    

801043a1 <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
801043a1:	55                   	push   %ebp
801043a2:	89 e5                	mov    %esp,%ebp
801043a4:	53                   	push   %ebx
801043a5:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
801043a8:	8b 45 08             	mov    0x8(%ebp),%eax
801043ab:	89 04 24             	mov    %eax,(%esp)
801043ae:	e8 a0 14 00 00       	call   80105853 <acquire>
  for(i = 0; i < n; i++){
801043b3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801043ba:	e9 a6 00 00 00       	jmp    80104465 <pipewrite+0xc4>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
      if(p->readopen == 0 || proc->killed){
801043bf:	8b 45 08             	mov    0x8(%ebp),%eax
801043c2:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
801043c8:	85 c0                	test   %eax,%eax
801043ca:	74 0d                	je     801043d9 <pipewrite+0x38>
801043cc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801043d2:	8b 40 24             	mov    0x24(%eax),%eax
801043d5:	85 c0                	test   %eax,%eax
801043d7:	74 15                	je     801043ee <pipewrite+0x4d>
        release(&p->lock);
801043d9:	8b 45 08             	mov    0x8(%ebp),%eax
801043dc:	89 04 24             	mov    %eax,(%esp)
801043df:	e8 0a 15 00 00       	call   801058ee <release>
        return -1;
801043e4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801043e9:	e9 9d 00 00 00       	jmp    8010448b <pipewrite+0xea>
      }
      wakeup(&p->nread);
801043ee:	8b 45 08             	mov    0x8(%ebp),%eax
801043f1:	05 34 02 00 00       	add    $0x234,%eax
801043f6:	89 04 24             	mov    %eax,(%esp)
801043f9:	e8 55 11 00 00       	call   80105553 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
801043fe:	8b 45 08             	mov    0x8(%ebp),%eax
80104401:	8b 55 08             	mov    0x8(%ebp),%edx
80104404:	81 c2 38 02 00 00    	add    $0x238,%edx
8010440a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010440e:	89 14 24             	mov    %edx,(%esp)
80104411:	e8 01 10 00 00       	call   80105417 <sleep>
80104416:	eb 01                	jmp    80104419 <pipewrite+0x78>
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80104418:	90                   	nop
80104419:	8b 45 08             	mov    0x8(%ebp),%eax
8010441c:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
80104422:	8b 45 08             	mov    0x8(%ebp),%eax
80104425:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
8010442b:	05 00 02 00 00       	add    $0x200,%eax
80104430:	39 c2                	cmp    %eax,%edx
80104432:	74 8b                	je     801043bf <pipewrite+0x1e>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
80104434:	8b 45 08             	mov    0x8(%ebp),%eax
80104437:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
8010443d:	89 c3                	mov    %eax,%ebx
8010443f:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
80104445:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104448:	03 55 0c             	add    0xc(%ebp),%edx
8010444b:	0f b6 0a             	movzbl (%edx),%ecx
8010444e:	8b 55 08             	mov    0x8(%ebp),%edx
80104451:	88 4c 1a 34          	mov    %cl,0x34(%edx,%ebx,1)
80104455:	8d 50 01             	lea    0x1(%eax),%edx
80104458:	8b 45 08             	mov    0x8(%ebp),%eax
8010445b:	89 90 38 02 00 00    	mov    %edx,0x238(%eax)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
80104461:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104465:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104468:	3b 45 10             	cmp    0x10(%ebp),%eax
8010446b:	7c ab                	jl     80104418 <pipewrite+0x77>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
8010446d:	8b 45 08             	mov    0x8(%ebp),%eax
80104470:	05 34 02 00 00       	add    $0x234,%eax
80104475:	89 04 24             	mov    %eax,(%esp)
80104478:	e8 d6 10 00 00       	call   80105553 <wakeup>
  release(&p->lock);
8010447d:	8b 45 08             	mov    0x8(%ebp),%eax
80104480:	89 04 24             	mov    %eax,(%esp)
80104483:	e8 66 14 00 00       	call   801058ee <release>
  return n;
80104488:	8b 45 10             	mov    0x10(%ebp),%eax
}
8010448b:	83 c4 24             	add    $0x24,%esp
8010448e:	5b                   	pop    %ebx
8010448f:	5d                   	pop    %ebp
80104490:	c3                   	ret    

80104491 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
80104491:	55                   	push   %ebp
80104492:	89 e5                	mov    %esp,%ebp
80104494:	53                   	push   %ebx
80104495:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80104498:	8b 45 08             	mov    0x8(%ebp),%eax
8010449b:	89 04 24             	mov    %eax,(%esp)
8010449e:	e8 b0 13 00 00       	call   80105853 <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
801044a3:	eb 3a                	jmp    801044df <piperead+0x4e>
    if(proc->killed){
801044a5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801044ab:	8b 40 24             	mov    0x24(%eax),%eax
801044ae:	85 c0                	test   %eax,%eax
801044b0:	74 15                	je     801044c7 <piperead+0x36>
      release(&p->lock);
801044b2:	8b 45 08             	mov    0x8(%ebp),%eax
801044b5:	89 04 24             	mov    %eax,(%esp)
801044b8:	e8 31 14 00 00       	call   801058ee <release>
      return -1;
801044bd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801044c2:	e9 b6 00 00 00       	jmp    8010457d <piperead+0xec>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
801044c7:	8b 45 08             	mov    0x8(%ebp),%eax
801044ca:	8b 55 08             	mov    0x8(%ebp),%edx
801044cd:	81 c2 34 02 00 00    	add    $0x234,%edx
801044d3:	89 44 24 04          	mov    %eax,0x4(%esp)
801044d7:	89 14 24             	mov    %edx,(%esp)
801044da:	e8 38 0f 00 00       	call   80105417 <sleep>
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
801044df:	8b 45 08             	mov    0x8(%ebp),%eax
801044e2:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
801044e8:	8b 45 08             	mov    0x8(%ebp),%eax
801044eb:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
801044f1:	39 c2                	cmp    %eax,%edx
801044f3:	75 0d                	jne    80104502 <piperead+0x71>
801044f5:	8b 45 08             	mov    0x8(%ebp),%eax
801044f8:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
801044fe:	85 c0                	test   %eax,%eax
80104500:	75 a3                	jne    801044a5 <piperead+0x14>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80104502:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104509:	eb 49                	jmp    80104554 <piperead+0xc3>
    if(p->nread == p->nwrite)
8010450b:	8b 45 08             	mov    0x8(%ebp),%eax
8010450e:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80104514:	8b 45 08             	mov    0x8(%ebp),%eax
80104517:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
8010451d:	39 c2                	cmp    %eax,%edx
8010451f:	74 3d                	je     8010455e <piperead+0xcd>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
80104521:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104524:	89 c2                	mov    %eax,%edx
80104526:	03 55 0c             	add    0xc(%ebp),%edx
80104529:	8b 45 08             	mov    0x8(%ebp),%eax
8010452c:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80104532:	89 c3                	mov    %eax,%ebx
80104534:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
8010453a:	8b 4d 08             	mov    0x8(%ebp),%ecx
8010453d:	0f b6 4c 19 34       	movzbl 0x34(%ecx,%ebx,1),%ecx
80104542:	88 0a                	mov    %cl,(%edx)
80104544:	8d 50 01             	lea    0x1(%eax),%edx
80104547:	8b 45 08             	mov    0x8(%ebp),%eax
8010454a:	89 90 34 02 00 00    	mov    %edx,0x234(%eax)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80104550:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104554:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104557:	3b 45 10             	cmp    0x10(%ebp),%eax
8010455a:	7c af                	jl     8010450b <piperead+0x7a>
8010455c:	eb 01                	jmp    8010455f <piperead+0xce>
    if(p->nread == p->nwrite)
      break;
8010455e:	90                   	nop
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
8010455f:	8b 45 08             	mov    0x8(%ebp),%eax
80104562:	05 38 02 00 00       	add    $0x238,%eax
80104567:	89 04 24             	mov    %eax,(%esp)
8010456a:	e8 e4 0f 00 00       	call   80105553 <wakeup>
  release(&p->lock);
8010456f:	8b 45 08             	mov    0x8(%ebp),%eax
80104572:	89 04 24             	mov    %eax,(%esp)
80104575:	e8 74 13 00 00       	call   801058ee <release>
  return i;
8010457a:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010457d:	83 c4 24             	add    $0x24,%esp
80104580:	5b                   	pop    %ebx
80104581:	5d                   	pop    %ebp
80104582:	c3                   	ret    
	...

80104584 <p2v>:
80104584:	55                   	push   %ebp
80104585:	89 e5                	mov    %esp,%ebp
80104587:	8b 45 08             	mov    0x8(%ebp),%eax
8010458a:	05 00 00 00 80       	add    $0x80000000,%eax
8010458f:	5d                   	pop    %ebp
80104590:	c3                   	ret    

80104591 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80104591:	55                   	push   %ebp
80104592:	89 e5                	mov    %esp,%ebp
80104594:	53                   	push   %ebx
80104595:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80104598:	9c                   	pushf  
80104599:	5b                   	pop    %ebx
8010459a:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
8010459d:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
801045a0:	83 c4 10             	add    $0x10,%esp
801045a3:	5b                   	pop    %ebx
801045a4:	5d                   	pop    %ebp
801045a5:	c3                   	ret    

801045a6 <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
801045a6:	55                   	push   %ebp
801045a7:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
801045a9:	fb                   	sti    
}
801045aa:	5d                   	pop    %ebp
801045ab:	c3                   	ret    

801045ac <pinit>:

static void wakeup1(void *chan);

void
pinit(void)
{
801045ac:	55                   	push   %ebp
801045ad:	89 e5                	mov    %esp,%ebp
801045af:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
801045b2:	c7 44 24 04 9d 96 10 	movl   $0x8010969d,0x4(%esp)
801045b9:	80 
801045ba:	c7 04 24 80 3f 11 80 	movl   $0x80113f80,(%esp)
801045c1:	e8 6c 12 00 00       	call   80105832 <initlock>
}
801045c6:	c9                   	leave  
801045c7:	c3                   	ret    

801045c8 <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
801045c8:	55                   	push   %ebp
801045c9:	89 e5                	mov    %esp,%ebp
801045cb:	83 ec 38             	sub    $0x38,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
801045ce:	c7 04 24 80 3f 11 80 	movl   $0x80113f80,(%esp)
801045d5:	e8 79 12 00 00       	call   80105853 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801045da:	c7 45 f4 b4 3f 11 80 	movl   $0x80113fb4,-0xc(%ebp)
801045e1:	eb 11                	jmp    801045f4 <allocproc+0x2c>
    if(p->state == UNUSED)
801045e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045e6:	8b 40 0c             	mov    0xc(%eax),%eax
801045e9:	85 c0                	test   %eax,%eax
801045eb:	74 26                	je     80104613 <allocproc+0x4b>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801045ed:	81 45 f4 8c 00 00 00 	addl   $0x8c,-0xc(%ebp)
801045f4:	81 7d f4 b4 62 11 80 	cmpl   $0x801162b4,-0xc(%ebp)
801045fb:	72 e6                	jb     801045e3 <allocproc+0x1b>
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
801045fd:	c7 04 24 80 3f 11 80 	movl   $0x80113f80,(%esp)
80104604:	e8 e5 12 00 00       	call   801058ee <release>
  return 0;
80104609:	b8 00 00 00 00       	mov    $0x0,%eax
8010460e:	e9 5a 01 00 00       	jmp    8010476d <allocproc+0x1a5>
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
    if(p->state == UNUSED)
      goto found;
80104613:	90                   	nop
  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
80104614:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104617:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
  p->pid = nextpid++;
8010461e:	a1 04 c0 10 80       	mov    0x8010c004,%eax
80104623:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104626:	89 42 10             	mov    %eax,0x10(%edx)
80104629:	83 c0 01             	add    $0x1,%eax
8010462c:	a3 04 c0 10 80       	mov    %eax,0x8010c004
  release(&ptable.lock);
80104631:	c7 04 24 80 3f 11 80 	movl   $0x80113f80,(%esp)
80104638:	e8 b1 12 00 00       	call   801058ee <release>

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
8010463d:	e8 ce e4 ff ff       	call   80102b10 <kalloc>
80104642:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104645:	89 42 08             	mov    %eax,0x8(%edx)
80104648:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010464b:	8b 40 08             	mov    0x8(%eax),%eax
8010464e:	85 c0                	test   %eax,%eax
80104650:	75 14                	jne    80104666 <allocproc+0x9e>
    p->state = UNUSED;
80104652:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104655:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return 0;
8010465c:	b8 00 00 00 00       	mov    $0x0,%eax
80104661:	e9 07 01 00 00       	jmp    8010476d <allocproc+0x1a5>
  }
  sp = p->kstack + KSTACKSIZE;
80104666:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104669:	8b 40 08             	mov    0x8(%eax),%eax
8010466c:	05 00 10 00 00       	add    $0x1000,%eax
80104671:	89 45 f0             	mov    %eax,-0x10(%ebp)
  
  // Leave room for trap frame.
  sp -= sizeof *p->tf;
80104674:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
  p->tf = (struct trapframe*)sp;
80104678:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010467b:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010467e:	89 50 18             	mov    %edx,0x18(%eax)
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
80104681:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
  *(uint*)sp = (uint)trapret;
80104685:	ba 3c 74 10 80       	mov    $0x8010743c,%edx
8010468a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010468d:	89 10                	mov    %edx,(%eax)

  sp -= sizeof *p->context;
8010468f:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
  p->context = (struct context*)sp;
80104693:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104696:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104699:	89 50 1c             	mov    %edx,0x1c(%eax)
  memset(p->context, 0, sizeof *p->context);
8010469c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010469f:	8b 40 1c             	mov    0x1c(%eax),%eax
801046a2:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
801046a9:	00 
801046aa:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801046b1:	00 
801046b2:	89 04 24             	mov    %eax,(%esp)
801046b5:	e8 20 14 00 00       	call   80105ada <memset>
  p->context->eip = (uint)forkret;
801046ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046bd:	8b 40 1c             	mov    0x1c(%eax),%eax
801046c0:	ba eb 53 10 80       	mov    $0x801053eb,%edx
801046c5:	89 50 10             	mov    %edx,0x10(%eax)
  int i = 0;
801046c8:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  char name[8];
  name[2] = '.'; name[3] = 's'; name[4] = 'w'; name[5] = 'a'; name[6] = 'p'; name[7] = 0;
801046cf:	c6 45 e6 2e          	movb   $0x2e,-0x1a(%ebp)
801046d3:	c6 45 e7 73          	movb   $0x73,-0x19(%ebp)
801046d7:	c6 45 e8 77          	movb   $0x77,-0x18(%ebp)
801046db:	c6 45 e9 61          	movb   $0x61,-0x17(%ebp)
801046df:	c6 45 ea 70          	movb   $0x70,-0x16(%ebp)
801046e3:	c6 45 eb 00          	movb   $0x0,-0x15(%ebp)
  name[1] = (char)(((int)'0')+p->pid % 10);
801046e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046ea:	8b 48 10             	mov    0x10(%eax),%ecx
801046ed:	ba 67 66 66 66       	mov    $0x66666667,%edx
801046f2:	89 c8                	mov    %ecx,%eax
801046f4:	f7 ea                	imul   %edx
801046f6:	c1 fa 02             	sar    $0x2,%edx
801046f9:	89 c8                	mov    %ecx,%eax
801046fb:	c1 f8 1f             	sar    $0x1f,%eax
801046fe:	29 c2                	sub    %eax,%edx
80104700:	89 d0                	mov    %edx,%eax
80104702:	c1 e0 02             	shl    $0x2,%eax
80104705:	01 d0                	add    %edx,%eax
80104707:	01 c0                	add    %eax,%eax
80104709:	89 ca                	mov    %ecx,%edx
8010470b:	29 c2                	sub    %eax,%edx
8010470d:	89 d0                	mov    %edx,%eax
8010470f:	83 c0 30             	add    $0x30,%eax
80104712:	88 45 e5             	mov    %al,-0x1b(%ebp)
  if((i=p->pid/10) == 0)
80104715:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104718:	8b 48 10             	mov    0x10(%eax),%ecx
8010471b:	ba 67 66 66 66       	mov    $0x66666667,%edx
80104720:	89 c8                	mov    %ecx,%eax
80104722:	f7 ea                	imul   %edx
80104724:	c1 fa 02             	sar    $0x2,%edx
80104727:	89 c8                	mov    %ecx,%eax
80104729:	c1 f8 1f             	sar    $0x1f,%eax
8010472c:	89 d1                	mov    %edx,%ecx
8010472e:	29 c1                	sub    %eax,%ecx
80104730:	89 c8                	mov    %ecx,%eax
80104732:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104735:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80104739:	75 06                	jne    80104741 <allocproc+0x179>
    name[0] = '0';
8010473b:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
8010473f:	eb 09                	jmp    8010474a <allocproc+0x182>
  else
    name[0] = (char)(((int)'0')+i);
80104741:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104744:	83 c0 30             	add    $0x30,%eax
80104747:	88 45 e4             	mov    %al,-0x1c(%ebp)
  //release(&ptable.lock);
  safestrcpy(p->swapFileName, name, sizeof(name));
8010474a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010474d:	8d 90 80 00 00 00    	lea    0x80(%eax),%edx
80104753:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
8010475a:	00 
8010475b:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010475e:	89 44 24 04          	mov    %eax,0x4(%esp)
80104762:	89 14 24             	mov    %edx,(%esp)
80104765:	e8 a0 15 00 00       	call   80105d0a <safestrcpy>
  return p;
8010476a:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010476d:	c9                   	leave  
8010476e:	c3                   	ret    

8010476f <createInternalProcess>:


void createInternalProcess(const char *name, void (*entrypoint)())
{
8010476f:	55                   	push   %ebp
80104770:	89 e5                	mov    %esp,%ebp
80104772:	83 ec 28             	sub    $0x28,%esp
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
80104775:	e8 4e fe ff ff       	call   801045c8 <allocproc>
8010477a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010477d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104781:	0f 84 f7 00 00 00    	je     8010487e <createInternalProcess+0x10f>
    return;

  // Copy process state from p.
  if((np->pgdir = setupkvm(kalloc)) == 0)
80104787:	c7 04 24 10 2b 10 80 	movl   $0x80102b10,(%esp)
8010478e:	e8 a6 43 00 00       	call   80108b39 <setupkvm>
80104793:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104796:	89 42 04             	mov    %eax,0x4(%edx)
80104799:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010479c:	8b 40 04             	mov    0x4(%eax),%eax
8010479f:	85 c0                	test   %eax,%eax
801047a1:	75 0c                	jne    801047af <createInternalProcess+0x40>
      panic("inswapper: out of memory?");
801047a3:	c7 04 24 a4 96 10 80 	movl   $0x801096a4,(%esp)
801047aa:	e8 8e bd ff ff       	call   8010053d <panic>

  np->sz = PGSIZE;
801047af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047b2:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  np->parent = initproc;
801047b8:	8b 15 6c c6 10 80    	mov    0x8010c66c,%edx
801047be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047c1:	89 50 14             	mov    %edx,0x14(%eax)
  memset(np->tf, 0, sizeof(*np->tf));
801047c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047c7:	8b 40 18             	mov    0x18(%eax),%eax
801047ca:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
801047d1:	00 
801047d2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801047d9:	00 
801047da:	89 04 24             	mov    %eax,(%esp)
801047dd:	e8 f8 12 00 00       	call   80105ada <memset>
  np->tf->cs = (SEG_KCODE << 3)|0;
801047e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047e5:	8b 40 18             	mov    0x18(%eax),%eax
801047e8:	66 c7 40 3c 08 00    	movw   $0x8,0x3c(%eax)
  np->tf->ds = (SEG_KDATA << 3)|0;
801047ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047f1:	8b 40 18             	mov    0x18(%eax),%eax
801047f4:	66 c7 40 2c 10 00    	movw   $0x10,0x2c(%eax)
  np->tf->es = np->tf->ds;
801047fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047fd:	8b 40 18             	mov    0x18(%eax),%eax
80104800:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104803:	8b 52 18             	mov    0x18(%edx),%edx
80104806:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
8010480a:	66 89 50 28          	mov    %dx,0x28(%eax)
  np->tf->ss = np->tf->ds;
8010480e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104811:	8b 40 18             	mov    0x18(%eax),%eax
80104814:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104817:	8b 52 18             	mov    0x18(%edx),%edx
8010481a:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
8010481e:	66 89 50 48          	mov    %dx,0x48(%eax)
  np->tf->eflags = FL_IF;
80104822:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104825:	8b 40 18             	mov    0x18(%eax),%eax
80104828:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  //np->tf->esp = (uint)entrypoint+PGSIZE;
  //np->tf->eip = (uint)entrypoint;
  np->context->eip = (uint)entrypoint;
8010482f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104832:	8b 40 1c             	mov    0x1c(%eax),%eax
80104835:	8b 55 0c             	mov    0xc(%ebp),%edx
80104838:	89 50 10             	mov    %edx,0x10(%eax)

  inswapper = np;
8010483b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010483e:	a3 70 c6 10 80       	mov    %eax,0x8010c670
  np->cwd = namei("/");
80104843:	c7 04 24 be 96 10 80 	movl   $0x801096be,(%esp)
8010484a:	e8 bb db ff ff       	call   8010240a <namei>
8010484f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104852:	89 42 68             	mov    %eax,0x68(%edx)
  safestrcpy(np->name, name, sizeof(name));
80104855:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104858:	8d 50 6c             	lea    0x6c(%eax),%edx
8010485b:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80104862:	00 
80104863:	8b 45 08             	mov    0x8(%ebp),%eax
80104866:	89 44 24 04          	mov    %eax,0x4(%esp)
8010486a:	89 14 24             	mov    %edx,(%esp)
8010486d:	e8 98 14 00 00       	call   80105d0a <safestrcpy>
  np->state = RUNNABLE;
80104872:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104875:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
8010487c:	eb 01                	jmp    8010487f <createInternalProcess+0x110>
{
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
    return;
8010487e:	90                   	nop

  inswapper = np;
  np->cwd = namei("/");
  safestrcpy(np->name, name, sizeof(name));
  np->state = RUNNABLE;
}
8010487f:	c9                   	leave  
80104880:	c3                   	ret    

80104881 <swapIn>:

void swapIn()
{
80104881:	55                   	push   %ebp
80104882:	89 e5                	mov    %esp,%ebp
80104884:	83 ec 38             	sub    $0x38,%esp
  struct proc* t;
  for(;;)
  {
    for(t = ptable.proc; t < &ptable.proc[NPROC]; t++)
80104887:	c7 45 f4 b4 3f 11 80 	movl   $0x80113fb4,-0xc(%ebp)
8010488e:	e9 e0 01 00 00       	jmp    80104a73 <swapIn+0x1f2>
    {
      if(t->state != RUNNABLE_SUSPENDED)
80104893:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104896:	8b 40 0c             	mov    0xc(%eax),%eax
80104899:	83 f8 07             	cmp    $0x7,%eax
8010489c:	0f 85 c9 01 00 00    	jne    80104a6b <swapIn+0x1ea>
	continue;
      
      //open file pid.swap
      if(holding(&ptable.lock))
801048a2:	c7 04 24 80 3f 11 80 	movl   $0x80113f80,(%esp)
801048a9:	e8 fc 10 00 00       	call   801059aa <holding>
801048ae:	85 c0                	test   %eax,%eax
801048b0:	74 0c                	je     801048be <swapIn+0x3d>
	release(&ptable.lock);
801048b2:	c7 04 24 80 3f 11 80 	movl   $0x80113f80,(%esp)
801048b9:	e8 30 10 00 00       	call   801058ee <release>
      if((t->swap = fileopen(t->swapFileName,O_RDONLY)) == 0)
801048be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048c1:	83 e8 80             	sub    $0xffffff80,%eax
801048c4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801048cb:	00 
801048cc:	89 04 24             	mov    %eax,(%esp)
801048cf:	e8 e7 20 00 00       	call   801069bb <fileopen>
801048d4:	8b 55 f4             	mov    -0xc(%ebp),%edx
801048d7:	89 42 7c             	mov    %eax,0x7c(%edx)
801048da:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048dd:	8b 40 7c             	mov    0x7c(%eax),%eax
801048e0:	85 c0                	test   %eax,%eax
801048e2:	75 1d                	jne    80104901 <swapIn+0x80>
      {
	cprintf("fileopen failed\n");
801048e4:	c7 04 24 c0 96 10 80 	movl   $0x801096c0,(%esp)
801048eb:	e8 b1 ba ff ff       	call   801003a1 <cprintf>
	acquire(&ptable.lock);
801048f0:	c7 04 24 80 3f 11 80 	movl   $0x80113f80,(%esp)
801048f7:	e8 57 0f 00 00       	call   80105853 <acquire>
	break;
801048fc:	e9 7f 01 00 00       	jmp    80104a80 <swapIn+0x1ff>
      }
      acquire(&ptable.lock);
80104901:	c7 04 24 80 3f 11 80 	movl   $0x80113f80,(%esp)
80104908:	e8 46 0f 00 00       	call   80105853 <acquire>
            
      // allocate virtual memory
      if((t->pgdir = setupkvm(kalloc)) == 0)
8010490d:	c7 04 24 10 2b 10 80 	movl   $0x80102b10,(%esp)
80104914:	e8 20 42 00 00       	call   80108b39 <setupkvm>
80104919:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010491c:	89 42 04             	mov    %eax,0x4(%edx)
8010491f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104922:	8b 40 04             	mov    0x4(%eax),%eax
80104925:	85 c0                	test   %eax,%eax
80104927:	75 0c                	jne    80104935 <swapIn+0xb4>
	panic("inswapper: out of memory?");
80104929:	c7 04 24 a4 96 10 80 	movl   $0x801096a4,(%esp)
80104930:	e8 08 bc ff ff       	call   8010053d <panic>
      if(!allocuvm(t->pgdir, 0, t->sz))
80104935:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104938:	8b 10                	mov    (%eax),%edx
8010493a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010493d:	8b 40 04             	mov    0x4(%eax),%eax
80104940:	89 54 24 08          	mov    %edx,0x8(%esp)
80104944:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010494b:	00 
8010494c:	89 04 24             	mov    %eax,(%esp)
8010494f:	e8 b7 45 00 00       	call   80108f0b <allocuvm>
80104954:	85 c0                	test   %eax,%eax
80104956:	75 11                	jne    80104969 <swapIn+0xe8>
      {
	cprintf("allocuvm failed\n");
80104958:	c7 04 24 d1 96 10 80 	movl   $0x801096d1,(%esp)
8010495f:	e8 3d ba ff ff       	call   801003a1 <cprintf>
	break;
80104964:	e9 17 01 00 00       	jmp    80104a80 <swapIn+0x1ff>
      }
      
      if(holding(&ptable.lock))
80104969:	c7 04 24 80 3f 11 80 	movl   $0x80113f80,(%esp)
80104970:	e8 35 10 00 00       	call   801059aa <holding>
80104975:	85 c0                	test   %eax,%eax
80104977:	74 0c                	je     80104985 <swapIn+0x104>
	release(&ptable.lock);
80104979:	c7 04 24 80 3f 11 80 	movl   $0x80113f80,(%esp)
80104980:	e8 69 0f 00 00       	call   801058ee <release>
      loaduvm(t->pgdir,0,t->swap->ip,0,t->sz);
80104985:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104988:	8b 08                	mov    (%eax),%ecx
8010498a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010498d:	8b 40 7c             	mov    0x7c(%eax),%eax
80104990:	8b 50 10             	mov    0x10(%eax),%edx
80104993:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104996:	8b 40 04             	mov    0x4(%eax),%eax
80104999:	89 4c 24 10          	mov    %ecx,0x10(%esp)
8010499d:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
801049a4:	00 
801049a5:	89 54 24 08          	mov    %edx,0x8(%esp)
801049a9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801049b0:	00 
801049b1:	89 04 24             	mov    %eax,(%esp)
801049b4:	e8 63 44 00 00       	call   80108e1c <loaduvm>
      
      t->isSwapped = 0;
801049b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049bc:	c7 80 88 00 00 00 00 	movl   $0x0,0x88(%eax)
801049c3:	00 00 00 
      int fd;
      for(fd = 0; fd < NOFILE; fd++)
801049c6:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
801049cd:	eb 63                	jmp    80104a32 <swapIn+0x1b1>
      {
	if(proc->ofile[fd] && proc->ofile[fd] == proc->swap)
801049cf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801049d5:	8b 55 f0             	mov    -0x10(%ebp),%edx
801049d8:	83 c2 08             	add    $0x8,%edx
801049db:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801049df:	85 c0                	test   %eax,%eax
801049e1:	74 4b                	je     80104a2e <swapIn+0x1ad>
801049e3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801049e9:	8b 55 f0             	mov    -0x10(%ebp),%edx
801049ec:	83 c2 08             	add    $0x8,%edx
801049ef:	8b 54 90 08          	mov    0x8(%eax,%edx,4),%edx
801049f3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801049f9:	8b 40 7c             	mov    0x7c(%eax),%eax
801049fc:	39 c2                	cmp    %eax,%edx
801049fe:	75 2e                	jne    80104a2e <swapIn+0x1ad>
	{
	  fileclose(proc->ofile[fd]);
80104a00:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104a06:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104a09:	83 c2 08             	add    $0x8,%edx
80104a0c:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104a10:	89 04 24             	mov    %eax,(%esp)
80104a13:	e8 ac c5 ff ff       	call   80100fc4 <fileclose>
	  proc->ofile[fd] = 0;
80104a18:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104a1e:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104a21:	83 c2 08             	add    $0x8,%edx
80104a24:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80104a2b:	00 
	  break;
80104a2c:	eb 0a                	jmp    80104a38 <swapIn+0x1b7>
	release(&ptable.lock);
      loaduvm(t->pgdir,0,t->swap->ip,0,t->sz);
      
      t->isSwapped = 0;
      int fd;
      for(fd = 0; fd < NOFILE; fd++)
80104a2e:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80104a32:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
80104a36:	7e 97                	jle    801049cf <swapIn+0x14e>
	  fileclose(proc->ofile[fd]);
	  proc->ofile[fd] = 0;
	  break;
	}
      }
      proc->swap=0;
80104a38:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104a3e:	c7 40 7c 00 00 00 00 	movl   $0x0,0x7c(%eax)
      unlink(t->swapFileName);
80104a45:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a48:	83 e8 80             	sub    $0xffffff80,%eax
80104a4b:	89 04 24             	mov    %eax,(%esp)
80104a4e:	e8 23 1a 00 00       	call   80106476 <unlink>
      acquire(&ptable.lock);
80104a53:	c7 04 24 80 3f 11 80 	movl   $0x80113f80,(%esp)
80104a5a:	e8 f4 0d 00 00       	call   80105853 <acquire>
      //cprintf("eip = %d\n",t->tf->eip);
      t->state = RUNNABLE;
80104a5f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a62:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
80104a69:	eb 01                	jmp    80104a6c <swapIn+0x1eb>
  for(;;)
  {
    for(t = ptable.proc; t < &ptable.proc[NPROC]; t++)
    {
      if(t->state != RUNNABLE_SUSPENDED)
	continue;
80104a6b:	90                   	nop
void swapIn()
{
  struct proc* t;
  for(;;)
  {
    for(t = ptable.proc; t < &ptable.proc[NPROC]; t++)
80104a6c:	81 45 f4 8c 00 00 00 	addl   $0x8c,-0xc(%ebp)
80104a73:	81 7d f4 b4 62 11 80 	cmpl   $0x801162b4,-0xc(%ebp)
80104a7a:	0f 82 13 fe ff ff    	jb     80104893 <swapIn+0x12>
      unlink(t->swapFileName);
      acquire(&ptable.lock);
      //cprintf("eip = %d\n",t->tf->eip);
      t->state = RUNNABLE;
    }
    proc->chan = inswapper;
80104a80:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104a86:	8b 15 70 c6 10 80    	mov    0x8010c670,%edx
80104a8c:	89 50 20             	mov    %edx,0x20(%eax)
    proc->state = SLEEPING;
80104a8f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104a95:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
    sched();
80104a9c:	e8 66 08 00 00       	call   80105307 <sched>
    proc->chan = 0;
80104aa1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104aa7:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)
  }
80104aae:	e9 d4 fd ff ff       	jmp    80104887 <swapIn+0x6>

80104ab3 <swapOut>:
}

void
swapOut()
{
80104ab3:	55                   	push   %ebp
80104ab4:	89 e5                	mov    %esp,%ebp
80104ab6:	53                   	push   %ebx
80104ab7:	83 ec 24             	sub    $0x24,%esp
    proc->swap = fileopen(proc->swapFileName,(O_CREATE | O_RDWR));
80104aba:	65 8b 1d 04 00 00 00 	mov    %gs:0x4,%ebx
80104ac1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ac7:	83 e8 80             	sub    $0xffffff80,%eax
80104aca:	c7 44 24 04 02 02 00 	movl   $0x202,0x4(%esp)
80104ad1:	00 
80104ad2:	89 04 24             	mov    %eax,(%esp)
80104ad5:	e8 e1 1e 00 00       	call   801069bb <fileopen>
80104ada:	89 43 7c             	mov    %eax,0x7c(%ebx)
    pte_t *pte;
    uint pa, j;
    for(j = 0; j < proc->sz; j += PGSIZE)
80104add:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104ae4:	e9 9a 00 00 00       	jmp    80104b83 <swapOut+0xd0>
    {
      if((pte = walkpgdir(proc->pgdir, (void *) j, 0)) == 0)
80104ae9:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104aec:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104af2:	8b 40 04             	mov    0x4(%eax),%eax
80104af5:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80104afc:	00 
80104afd:	89 54 24 04          	mov    %edx,0x4(%esp)
80104b01:	89 04 24             	mov    %eax,(%esp)
80104b04:	e8 06 3f 00 00       	call   80108a0f <walkpgdir>
80104b09:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104b0c:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80104b10:	75 0c                	jne    80104b1e <swapOut+0x6b>
	panic("walkpgdir: pte should exist");
80104b12:	c7 04 24 e2 96 10 80 	movl   $0x801096e2,(%esp)
80104b19:	e8 1f ba ff ff       	call   8010053d <panic>
      if(!(*pte & PTE_P))
80104b1e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104b21:	8b 00                	mov    (%eax),%eax
80104b23:	83 e0 01             	and    $0x1,%eax
80104b26:	85 c0                	test   %eax,%eax
80104b28:	75 0c                	jne    80104b36 <swapOut+0x83>
	panic("walkpgdir: page not present");
80104b2a:	c7 04 24 fe 96 10 80 	movl   $0x801096fe,(%esp)
80104b31:	e8 07 ba ff ff       	call   8010053d <panic>
      pa = PTE_ADDR(*pte);
80104b36:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104b39:	8b 00                	mov    (%eax),%eax
80104b3b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80104b40:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(filewrite(proc->swap, (char*)p2v(pa), PGSIZE) < 0)
80104b43:	8b 45 e8             	mov    -0x18(%ebp),%eax
80104b46:	89 04 24             	mov    %eax,(%esp)
80104b49:	e8 36 fa ff ff       	call   80104584 <p2v>
80104b4e:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104b55:	8b 52 7c             	mov    0x7c(%edx),%edx
80104b58:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80104b5f:	00 
80104b60:	89 44 24 04          	mov    %eax,0x4(%esp)
80104b64:	89 14 24             	mov    %edx,(%esp)
80104b67:	e8 39 c6 ff ff       	call   801011a5 <filewrite>
80104b6c:	85 c0                	test   %eax,%eax
80104b6e:	79 0c                	jns    80104b7c <swapOut+0xc9>
	panic("filewrite failed");
80104b70:	c7 04 24 1a 97 10 80 	movl   $0x8010971a,(%esp)
80104b77:	e8 c1 b9 ff ff       	call   8010053d <panic>
swapOut()
{
    proc->swap = fileopen(proc->swapFileName,(O_CREATE | O_RDWR));
    pte_t *pte;
    uint pa, j;
    for(j = 0; j < proc->sz; j += PGSIZE)
80104b7c:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80104b83:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b89:	8b 00                	mov    (%eax),%eax
80104b8b:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104b8e:	0f 87 55 ff ff ff    	ja     80104ae9 <swapOut+0x36>
      if(filewrite(proc->swap, (char*)p2v(pa), PGSIZE) < 0)
	panic("filewrite failed");
    }

    int fd;
    for(fd = 0; fd < NOFILE; fd++)
80104b94:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80104b9b:	eb 63                	jmp    80104c00 <swapOut+0x14d>
    {
      if(proc->ofile[fd] && proc->ofile[fd] == proc->swap)
80104b9d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ba3:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104ba6:	83 c2 08             	add    $0x8,%edx
80104ba9:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104bad:	85 c0                	test   %eax,%eax
80104baf:	74 4b                	je     80104bfc <swapOut+0x149>
80104bb1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104bb7:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104bba:	83 c2 08             	add    $0x8,%edx
80104bbd:	8b 54 90 08          	mov    0x8(%eax,%edx,4),%edx
80104bc1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104bc7:	8b 40 7c             	mov    0x7c(%eax),%eax
80104bca:	39 c2                	cmp    %eax,%edx
80104bcc:	75 2e                	jne    80104bfc <swapOut+0x149>
      {
	fileclose(proc->ofile[fd]);
80104bce:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104bd4:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104bd7:	83 c2 08             	add    $0x8,%edx
80104bda:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104bde:	89 04 24             	mov    %eax,(%esp)
80104be1:	e8 de c3 ff ff       	call   80100fc4 <fileclose>
	proc->ofile[fd] = 0;
80104be6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104bec:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104bef:	83 c2 08             	add    $0x8,%edx
80104bf2:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80104bf9:	00 
	break;
80104bfa:	eb 0a                	jmp    80104c06 <swapOut+0x153>
      if(filewrite(proc->swap, (char*)p2v(pa), PGSIZE) < 0)
	panic("filewrite failed");
    }

    int fd;
    for(fd = 0; fd < NOFILE; fd++)
80104bfc:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80104c00:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
80104c04:	7e 97                	jle    80104b9d <swapOut+0xea>
	fileclose(proc->ofile[fd]);
	proc->ofile[fd] = 0;
	break;
      }
    }
    proc->swap=0;
80104c06:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c0c:	c7 40 7c 00 00 00 00 	movl   $0x0,0x7c(%eax)
    //freevm(proc->pgdir);
    deallocuvm(proc->pgdir,proc->sz,0);
80104c13:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c19:	8b 10                	mov    (%eax),%edx
80104c1b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c21:	8b 40 04             	mov    0x4(%eax),%eax
80104c24:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80104c2b:	00 
80104c2c:	89 54 24 04          	mov    %edx,0x4(%esp)
80104c30:	89 04 24             	mov    %eax,(%esp)
80104c33:	e8 ad 43 00 00       	call   80108fe5 <deallocuvm>
    proc->state = SLEEPING_SUSPENDED;
80104c38:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c3e:	c7 40 0c 06 00 00 00 	movl   $0x6,0xc(%eax)
    proc->isSwapped = 1;
80104c45:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c4b:	c7 80 88 00 00 00 01 	movl   $0x1,0x88(%eax)
80104c52:	00 00 00 
}
80104c55:	83 c4 24             	add    $0x24,%esp
80104c58:	5b                   	pop    %ebx
80104c59:	5d                   	pop    %ebp
80104c5a:	c3                   	ret    

80104c5b <userinit>:

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
80104c5b:	55                   	push   %ebp
80104c5c:	89 e5                	mov    %esp,%ebp
80104c5e:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
80104c61:	e8 62 f9 ff ff       	call   801045c8 <allocproc>
80104c66:	89 45 f4             	mov    %eax,-0xc(%ebp)
  initproc = p;
80104c69:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c6c:	a3 6c c6 10 80       	mov    %eax,0x8010c66c
  if((p->pgdir = setupkvm(kalloc)) == 0)
80104c71:	c7 04 24 10 2b 10 80 	movl   $0x80102b10,(%esp)
80104c78:	e8 bc 3e 00 00       	call   80108b39 <setupkvm>
80104c7d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c80:	89 42 04             	mov    %eax,0x4(%edx)
80104c83:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c86:	8b 40 04             	mov    0x4(%eax),%eax
80104c89:	85 c0                	test   %eax,%eax
80104c8b:	75 0c                	jne    80104c99 <userinit+0x3e>
    panic("userinit: out of memory?");
80104c8d:	c7 04 24 2b 97 10 80 	movl   $0x8010972b,(%esp)
80104c94:	e8 a4 b8 ff ff       	call   8010053d <panic>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80104c99:	ba 2c 00 00 00       	mov    $0x2c,%edx
80104c9e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ca1:	8b 40 04             	mov    0x4(%eax),%eax
80104ca4:	89 54 24 08          	mov    %edx,0x8(%esp)
80104ca8:	c7 44 24 04 00 c5 10 	movl   $0x8010c500,0x4(%esp)
80104caf:	80 
80104cb0:	89 04 24             	mov    %eax,(%esp)
80104cb3:	e8 d9 40 00 00       	call   80108d91 <inituvm>
  p->sz = PGSIZE;
80104cb8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104cbb:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  memset(p->tf, 0, sizeof(*p->tf));
80104cc1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104cc4:	8b 40 18             	mov    0x18(%eax),%eax
80104cc7:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
80104cce:	00 
80104ccf:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104cd6:	00 
80104cd7:	89 04 24             	mov    %eax,(%esp)
80104cda:	e8 fb 0d 00 00       	call   80105ada <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
80104cdf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ce2:	8b 40 18             	mov    0x18(%eax),%eax
80104ce5:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
80104ceb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104cee:	8b 40 18             	mov    0x18(%eax),%eax
80104cf1:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
  p->tf->es = p->tf->ds;
80104cf7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104cfa:	8b 40 18             	mov    0x18(%eax),%eax
80104cfd:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104d00:	8b 52 18             	mov    0x18(%edx),%edx
80104d03:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104d07:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
80104d0b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d0e:	8b 40 18             	mov    0x18(%eax),%eax
80104d11:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104d14:	8b 52 18             	mov    0x18(%edx),%edx
80104d17:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104d1b:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
80104d1f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d22:	8b 40 18             	mov    0x18(%eax),%eax
80104d25:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
80104d2c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d2f:	8b 40 18             	mov    0x18(%eax),%eax
80104d32:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
80104d39:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d3c:	8b 40 18             	mov    0x18(%eax),%eax
80104d3f:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
80104d46:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d49:	83 c0 6c             	add    $0x6c,%eax
80104d4c:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104d53:	00 
80104d54:	c7 44 24 04 44 97 10 	movl   $0x80109744,0x4(%esp)
80104d5b:	80 
80104d5c:	89 04 24             	mov    %eax,(%esp)
80104d5f:	e8 a6 0f 00 00       	call   80105d0a <safestrcpy>
  p->cwd = namei("/");
80104d64:	c7 04 24 be 96 10 80 	movl   $0x801096be,(%esp)
80104d6b:	e8 9a d6 ff ff       	call   8010240a <namei>
80104d70:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104d73:	89 42 68             	mov    %eax,0x68(%edx)

  p->state = RUNNABLE;
80104d76:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d79:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)

  createInternalProcess("inswapper", swapIn);
80104d80:	c7 44 24 04 81 48 10 	movl   $0x80104881,0x4(%esp)
80104d87:	80 
80104d88:	c7 04 24 4d 97 10 80 	movl   $0x8010974d,(%esp)
80104d8f:	e8 db f9 ff ff       	call   8010476f <createInternalProcess>
}
80104d94:	c9                   	leave  
80104d95:	c3                   	ret    

80104d96 <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
80104d96:	55                   	push   %ebp
80104d97:	89 e5                	mov    %esp,%ebp
80104d99:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  
  sz = proc->sz;
80104d9c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104da2:	8b 00                	mov    (%eax),%eax
80104da4:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
80104da7:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80104dab:	7e 34                	jle    80104de1 <growproc+0x4b>
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
80104dad:	8b 45 08             	mov    0x8(%ebp),%eax
80104db0:	89 c2                	mov    %eax,%edx
80104db2:	03 55 f4             	add    -0xc(%ebp),%edx
80104db5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104dbb:	8b 40 04             	mov    0x4(%eax),%eax
80104dbe:	89 54 24 08          	mov    %edx,0x8(%esp)
80104dc2:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104dc5:	89 54 24 04          	mov    %edx,0x4(%esp)
80104dc9:	89 04 24             	mov    %eax,(%esp)
80104dcc:	e8 3a 41 00 00       	call   80108f0b <allocuvm>
80104dd1:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104dd4:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104dd8:	75 41                	jne    80104e1b <growproc+0x85>
      return -1;
80104dda:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ddf:	eb 58                	jmp    80104e39 <growproc+0xa3>
  } else if(n < 0){
80104de1:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80104de5:	79 34                	jns    80104e1b <growproc+0x85>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
80104de7:	8b 45 08             	mov    0x8(%ebp),%eax
80104dea:	89 c2                	mov    %eax,%edx
80104dec:	03 55 f4             	add    -0xc(%ebp),%edx
80104def:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104df5:	8b 40 04             	mov    0x4(%eax),%eax
80104df8:	89 54 24 08          	mov    %edx,0x8(%esp)
80104dfc:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104dff:	89 54 24 04          	mov    %edx,0x4(%esp)
80104e03:	89 04 24             	mov    %eax,(%esp)
80104e06:	e8 da 41 00 00       	call   80108fe5 <deallocuvm>
80104e0b:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104e0e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104e12:	75 07                	jne    80104e1b <growproc+0x85>
      return -1;
80104e14:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e19:	eb 1e                	jmp    80104e39 <growproc+0xa3>
  }
  proc->sz = sz;
80104e1b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e21:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104e24:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
80104e26:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e2c:	89 04 24             	mov    %eax,(%esp)
80104e2f:	e8 f6 3d 00 00       	call   80108c2a <switchuvm>
  return 0;
80104e34:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104e39:	c9                   	leave  
80104e3a:	c3                   	ret    

80104e3b <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
80104e3b:	55                   	push   %ebp
80104e3c:	89 e5                	mov    %esp,%ebp
80104e3e:	57                   	push   %edi
80104e3f:	56                   	push   %esi
80104e40:	53                   	push   %ebx
80104e41:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
80104e44:	e8 7f f7 ff ff       	call   801045c8 <allocproc>
80104e49:	89 45 e0             	mov    %eax,-0x20(%ebp)
80104e4c:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80104e50:	75 0a                	jne    80104e5c <fork+0x21>
    return -1;
80104e52:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e57:	e9 3a 01 00 00       	jmp    80104f96 <fork+0x15b>
  
  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
80104e5c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e62:	8b 10                	mov    (%eax),%edx
80104e64:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e6a:	8b 40 04             	mov    0x4(%eax),%eax
80104e6d:	89 54 24 04          	mov    %edx,0x4(%esp)
80104e71:	89 04 24             	mov    %eax,(%esp)
80104e74:	e8 fc 42 00 00       	call   80109175 <copyuvm>
80104e79:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104e7c:	89 42 04             	mov    %eax,0x4(%edx)
80104e7f:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104e82:	8b 40 04             	mov    0x4(%eax),%eax
80104e85:	85 c0                	test   %eax,%eax
80104e87:	75 2c                	jne    80104eb5 <fork+0x7a>
    kfree(np->kstack);
80104e89:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104e8c:	8b 40 08             	mov    0x8(%eax),%eax
80104e8f:	89 04 24             	mov    %eax,(%esp)
80104e92:	e8 e0 db ff ff       	call   80102a77 <kfree>
    np->kstack = 0;
80104e97:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104e9a:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
80104ea1:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104ea4:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
80104eab:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104eb0:	e9 e1 00 00 00       	jmp    80104f96 <fork+0x15b>
  }
  np->sz = proc->sz;
80104eb5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ebb:	8b 10                	mov    (%eax),%edx
80104ebd:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104ec0:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
80104ec2:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104ec9:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104ecc:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *proc->tf;
80104ecf:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104ed2:	8b 50 18             	mov    0x18(%eax),%edx
80104ed5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104edb:	8b 40 18             	mov    0x18(%eax),%eax
80104ede:	89 c3                	mov    %eax,%ebx
80104ee0:	b8 13 00 00 00       	mov    $0x13,%eax
80104ee5:	89 d7                	mov    %edx,%edi
80104ee7:	89 de                	mov    %ebx,%esi
80104ee9:	89 c1                	mov    %eax,%ecx
80104eeb:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
80104eed:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104ef0:	8b 40 18             	mov    0x18(%eax),%eax
80104ef3:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
80104efa:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80104f01:	eb 3d                	jmp    80104f40 <fork+0x105>
    if(proc->ofile[i])
80104f03:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f09:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104f0c:	83 c2 08             	add    $0x8,%edx
80104f0f:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104f13:	85 c0                	test   %eax,%eax
80104f15:	74 25                	je     80104f3c <fork+0x101>
      np->ofile[i] = filedup(proc->ofile[i]);
80104f17:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f1d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104f20:	83 c2 08             	add    $0x8,%edx
80104f23:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104f27:	89 04 24             	mov    %eax,(%esp)
80104f2a:	e8 4d c0 ff ff       	call   80100f7c <filedup>
80104f2f:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104f32:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80104f35:	83 c1 08             	add    $0x8,%ecx
80104f38:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
80104f3c:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80104f40:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
80104f44:	7e bd                	jle    80104f03 <fork+0xc8>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
80104f46:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f4c:	8b 40 68             	mov    0x68(%eax),%eax
80104f4f:	89 04 24             	mov    %eax,(%esp)
80104f52:	e8 df c8 ff ff       	call   80101836 <idup>
80104f57:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104f5a:	89 42 68             	mov    %eax,0x68(%edx)
 
  pid = np->pid;
80104f5d:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104f60:	8b 40 10             	mov    0x10(%eax),%eax
80104f63:	89 45 dc             	mov    %eax,-0x24(%ebp)
  np->state = RUNNABLE;
80104f66:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104f69:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  safestrcpy(np->name, proc->name, sizeof(proc->name));
80104f70:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f76:	8d 50 6c             	lea    0x6c(%eax),%edx
80104f79:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104f7c:	83 c0 6c             	add    $0x6c,%eax
80104f7f:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104f86:	00 
80104f87:	89 54 24 04          	mov    %edx,0x4(%esp)
80104f8b:	89 04 24             	mov    %eax,(%esp)
80104f8e:	e8 77 0d 00 00       	call   80105d0a <safestrcpy>
  return pid;
80104f93:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
80104f96:	83 c4 2c             	add    $0x2c,%esp
80104f99:	5b                   	pop    %ebx
80104f9a:	5e                   	pop    %esi
80104f9b:	5f                   	pop    %edi
80104f9c:	5d                   	pop    %ebp
80104f9d:	c3                   	ret    

80104f9e <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
80104f9e:	55                   	push   %ebp
80104f9f:	89 e5                	mov    %esp,%ebp
80104fa1:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int fd;

  if(proc == initproc)
80104fa4:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104fab:	a1 6c c6 10 80       	mov    0x8010c66c,%eax
80104fb0:	39 c2                	cmp    %eax,%edx
80104fb2:	75 0c                	jne    80104fc0 <exit+0x22>
    panic("init exiting");
80104fb4:	c7 04 24 57 97 10 80 	movl   $0x80109757,(%esp)
80104fbb:	e8 7d b5 ff ff       	call   8010053d <panic>

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80104fc0:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80104fc7:	eb 44                	jmp    8010500d <exit+0x6f>
    if(proc->ofile[fd]){
80104fc9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104fcf:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104fd2:	83 c2 08             	add    $0x8,%edx
80104fd5:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104fd9:	85 c0                	test   %eax,%eax
80104fdb:	74 2c                	je     80105009 <exit+0x6b>
      fileclose(proc->ofile[fd]);
80104fdd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104fe3:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104fe6:	83 c2 08             	add    $0x8,%edx
80104fe9:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104fed:	89 04 24             	mov    %eax,(%esp)
80104ff0:	e8 cf bf ff ff       	call   80100fc4 <fileclose>
      proc->ofile[fd] = 0;
80104ff5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ffb:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104ffe:	83 c2 08             	add    $0x8,%edx
80105001:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80105008:	00 

  if(proc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80105009:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
8010500d:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
80105011:	7e b6                	jle    80104fc9 <exit+0x2b>
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  iput(proc->cwd);
80105013:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105019:	8b 40 68             	mov    0x68(%eax),%eax
8010501c:	89 04 24             	mov    %eax,(%esp)
8010501f:	e8 f7 c9 ff ff       	call   80101a1b <iput>
  proc->cwd = 0;
80105024:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010502a:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)

  acquire(&ptable.lock);
80105031:	c7 04 24 80 3f 11 80 	movl   $0x80113f80,(%esp)
80105038:	e8 16 08 00 00       	call   80105853 <acquire>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);
8010503d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105043:	8b 40 14             	mov    0x14(%eax),%eax
80105046:	89 04 24             	mov    %eax,(%esp)
80105049:	e8 98 04 00 00       	call   801054e6 <wakeup1>

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010504e:	c7 45 f4 b4 3f 11 80 	movl   $0x80113fb4,-0xc(%ebp)
80105055:	eb 3b                	jmp    80105092 <exit+0xf4>
    if(p->parent == proc){
80105057:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010505a:	8b 50 14             	mov    0x14(%eax),%edx
8010505d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105063:	39 c2                	cmp    %eax,%edx
80105065:	75 24                	jne    8010508b <exit+0xed>
      p->parent = initproc;
80105067:	8b 15 6c c6 10 80    	mov    0x8010c66c,%edx
8010506d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105070:	89 50 14             	mov    %edx,0x14(%eax)
      if(p->state == ZOMBIE)
80105073:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105076:	8b 40 0c             	mov    0xc(%eax),%eax
80105079:	83 f8 05             	cmp    $0x5,%eax
8010507c:	75 0d                	jne    8010508b <exit+0xed>
        wakeup1(initproc);
8010507e:	a1 6c c6 10 80       	mov    0x8010c66c,%eax
80105083:	89 04 24             	mov    %eax,(%esp)
80105086:	e8 5b 04 00 00       	call   801054e6 <wakeup1>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010508b:	81 45 f4 8c 00 00 00 	addl   $0x8c,-0xc(%ebp)
80105092:	81 7d f4 b4 62 11 80 	cmpl   $0x801162b4,-0xc(%ebp)
80105099:	72 bc                	jb     80105057 <exit+0xb9>
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  proc->state = ZOMBIE;
8010509b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050a1:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
  sched();
801050a8:	e8 5a 02 00 00       	call   80105307 <sched>
  panic("zombie exit");
801050ad:	c7 04 24 64 97 10 80 	movl   $0x80109764,(%esp)
801050b4:	e8 84 b4 ff ff       	call   8010053d <panic>

801050b9 <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
801050b9:	55                   	push   %ebp
801050ba:	89 e5                	mov    %esp,%ebp
801050bc:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
801050bf:	c7 04 24 80 3f 11 80 	movl   $0x80113f80,(%esp)
801050c6:	e8 88 07 00 00       	call   80105853 <acquire>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
801050cb:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801050d2:	c7 45 f4 b4 3f 11 80 	movl   $0x80113fb4,-0xc(%ebp)
801050d9:	e9 9d 00 00 00       	jmp    8010517b <wait+0xc2>
      if(p->parent != proc)
801050de:	8b 45 f4             	mov    -0xc(%ebp),%eax
801050e1:	8b 50 14             	mov    0x14(%eax),%edx
801050e4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050ea:	39 c2                	cmp    %eax,%edx
801050ec:	0f 85 81 00 00 00    	jne    80105173 <wait+0xba>
        continue;
      havekids = 1;
801050f2:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
      if(p->state == ZOMBIE){
801050f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801050fc:	8b 40 0c             	mov    0xc(%eax),%eax
801050ff:	83 f8 05             	cmp    $0x5,%eax
80105102:	75 70                	jne    80105174 <wait+0xbb>
        // Found one.
        pid = p->pid;
80105104:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105107:	8b 40 10             	mov    0x10(%eax),%eax
8010510a:	89 45 ec             	mov    %eax,-0x14(%ebp)
        kfree(p->kstack);
8010510d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105110:	8b 40 08             	mov    0x8(%eax),%eax
80105113:	89 04 24             	mov    %eax,(%esp)
80105116:	e8 5c d9 ff ff       	call   80102a77 <kfree>
        p->kstack = 0;
8010511b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010511e:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
        freevm(p->pgdir);
80105125:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105128:	8b 40 04             	mov    0x4(%eax),%eax
8010512b:	89 04 24             	mov    %eax,(%esp)
8010512e:	e8 6e 3f 00 00       	call   801090a1 <freevm>
        p->state = UNUSED;
80105133:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105136:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        p->pid = 0;
8010513d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105140:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
        p->parent = 0;
80105147:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010514a:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
        p->name[0] = 0;
80105151:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105154:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)
        p->killed = 0;
80105158:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010515b:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
        release(&ptable.lock);
80105162:	c7 04 24 80 3f 11 80 	movl   $0x80113f80,(%esp)
80105169:	e8 80 07 00 00       	call   801058ee <release>
        return pid;
8010516e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80105171:	eb 56                	jmp    801051c9 <wait+0x110>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->parent != proc)
        continue;
80105173:	90                   	nop

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105174:	81 45 f4 8c 00 00 00 	addl   $0x8c,-0xc(%ebp)
8010517b:	81 7d f4 b4 62 11 80 	cmpl   $0x801162b4,-0xc(%ebp)
80105182:	0f 82 56 ff ff ff    	jb     801050de <wait+0x25>
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
80105188:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010518c:	74 0d                	je     8010519b <wait+0xe2>
8010518e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105194:	8b 40 24             	mov    0x24(%eax),%eax
80105197:	85 c0                	test   %eax,%eax
80105199:	74 13                	je     801051ae <wait+0xf5>
      release(&ptable.lock);
8010519b:	c7 04 24 80 3f 11 80 	movl   $0x80113f80,(%esp)
801051a2:	e8 47 07 00 00       	call   801058ee <release>
      return -1;
801051a7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801051ac:	eb 1b                	jmp    801051c9 <wait+0x110>
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
801051ae:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801051b4:	c7 44 24 04 80 3f 11 	movl   $0x80113f80,0x4(%esp)
801051bb:	80 
801051bc:	89 04 24             	mov    %eax,(%esp)
801051bf:	e8 53 02 00 00       	call   80105417 <sleep>
  }
801051c4:	e9 02 ff ff ff       	jmp    801050cb <wait+0x12>
}
801051c9:	c9                   	leave  
801051ca:	c3                   	ret    

801051cb <register_handler>:

void
register_handler(sighandler_t sighandler)
{
801051cb:	55                   	push   %ebp
801051cc:	89 e5                	mov    %esp,%ebp
801051ce:	83 ec 28             	sub    $0x28,%esp
  char* addr = uva2ka(proc->pgdir, (char*)proc->tf->esp);
801051d1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801051d7:	8b 40 18             	mov    0x18(%eax),%eax
801051da:	8b 40 44             	mov    0x44(%eax),%eax
801051dd:	89 c2                	mov    %eax,%edx
801051df:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801051e5:	8b 40 04             	mov    0x4(%eax),%eax
801051e8:	89 54 24 04          	mov    %edx,0x4(%esp)
801051ec:	89 04 24             	mov    %eax,(%esp)
801051ef:	e8 92 40 00 00       	call   80109286 <uva2ka>
801051f4:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if ((proc->tf->esp & 0xFFF) == 0)
801051f7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801051fd:	8b 40 18             	mov    0x18(%eax),%eax
80105200:	8b 40 44             	mov    0x44(%eax),%eax
80105203:	25 ff 0f 00 00       	and    $0xfff,%eax
80105208:	85 c0                	test   %eax,%eax
8010520a:	75 0c                	jne    80105218 <register_handler+0x4d>
    panic("esp_offset == 0");
8010520c:	c7 04 24 70 97 10 80 	movl   $0x80109770,(%esp)
80105213:	e8 25 b3 ff ff       	call   8010053d <panic>

    /* open a new frame */
  *(int*)(addr + ((proc->tf->esp - 4) & 0xFFF))
80105218:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010521e:	8b 40 18             	mov    0x18(%eax),%eax
80105221:	8b 40 44             	mov    0x44(%eax),%eax
80105224:	83 e8 04             	sub    $0x4,%eax
80105227:	25 ff 0f 00 00       	and    $0xfff,%eax
8010522c:	03 45 f4             	add    -0xc(%ebp),%eax
          = proc->tf->eip;
8010522f:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80105236:	8b 52 18             	mov    0x18(%edx),%edx
80105239:	8b 52 38             	mov    0x38(%edx),%edx
8010523c:	89 10                	mov    %edx,(%eax)
  proc->tf->esp -= 4;
8010523e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105244:	8b 40 18             	mov    0x18(%eax),%eax
80105247:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
8010524e:	8b 52 18             	mov    0x18(%edx),%edx
80105251:	8b 52 44             	mov    0x44(%edx),%edx
80105254:	83 ea 04             	sub    $0x4,%edx
80105257:	89 50 44             	mov    %edx,0x44(%eax)

    /* update eip */
  proc->tf->eip = (uint)sighandler;
8010525a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105260:	8b 40 18             	mov    0x18(%eax),%eax
80105263:	8b 55 08             	mov    0x8(%ebp),%edx
80105266:	89 50 38             	mov    %edx,0x38(%eax)
}
80105269:	c9                   	leave  
8010526a:	c3                   	ret    

8010526b <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
8010526b:	55                   	push   %ebp
8010526c:	89 e5                	mov    %esp,%ebp
8010526e:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  
  for(;;){
    // Enable interrupts on this processor.
    sti();
80105271:	e8 30 f3 ff ff       	call   801045a6 <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
80105276:	c7 04 24 80 3f 11 80 	movl   $0x80113f80,(%esp)
8010527d:	e8 d1 05 00 00       	call   80105853 <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105282:	c7 45 f4 b4 3f 11 80 	movl   $0x80113fb4,-0xc(%ebp)
80105289:	eb 62                	jmp    801052ed <scheduler+0x82>
      if(p->state != RUNNABLE)
8010528b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010528e:	8b 40 0c             	mov    0xc(%eax),%eax
80105291:	83 f8 03             	cmp    $0x3,%eax
80105294:	75 4f                	jne    801052e5 <scheduler+0x7a>
        continue;
    
      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
80105296:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105299:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
      switchuvm(p);
8010529f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052a2:	89 04 24             	mov    %eax,(%esp)
801052a5:	e8 80 39 00 00       	call   80108c2a <switchuvm>
      p->state = RUNNING;
801052aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052ad:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      swtch(&cpu->scheduler, proc->context);
801052b4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801052ba:	8b 40 1c             	mov    0x1c(%eax),%eax
801052bd:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801052c4:	83 c2 04             	add    $0x4,%edx
801052c7:	89 44 24 04          	mov    %eax,0x4(%esp)
801052cb:	89 14 24             	mov    %edx,(%esp)
801052ce:	e8 ad 0a 00 00       	call   80105d80 <swtch>
      switchkvm();
801052d3:	e8 35 39 00 00       	call   80108c0d <switchkvm>
                 
      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
801052d8:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
801052df:	00 00 00 00 
801052e3:	eb 01                	jmp    801052e6 <scheduler+0x7b>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->state != RUNNABLE)
        continue;
801052e5:	90                   	nop
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801052e6:	81 45 f4 8c 00 00 00 	addl   $0x8c,-0xc(%ebp)
801052ed:	81 7d f4 b4 62 11 80 	cmpl   $0x801162b4,-0xc(%ebp)
801052f4:	72 95                	jb     8010528b <scheduler+0x20>
                 
      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
801052f6:	c7 04 24 80 3f 11 80 	movl   $0x80113f80,(%esp)
801052fd:	e8 ec 05 00 00       	call   801058ee <release>

  }
80105302:	e9 6a ff ff ff       	jmp    80105271 <scheduler+0x6>

80105307 <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
80105307:	55                   	push   %ebp
80105308:	89 e5                	mov    %esp,%ebp
8010530a:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
8010530d:	c7 04 24 80 3f 11 80 	movl   $0x80113f80,(%esp)
80105314:	e8 91 06 00 00       	call   801059aa <holding>
80105319:	85 c0                	test   %eax,%eax
8010531b:	75 0c                	jne    80105329 <sched+0x22>
    panic("sched ptable.lock");
8010531d:	c7 04 24 80 97 10 80 	movl   $0x80109780,(%esp)
80105324:	e8 14 b2 ff ff       	call   8010053d <panic>
  if(cpu->ncli != 1)
80105329:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010532f:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105335:	83 f8 01             	cmp    $0x1,%eax
80105338:	74 0c                	je     80105346 <sched+0x3f>
    panic("sched locks");
8010533a:	c7 04 24 92 97 10 80 	movl   $0x80109792,(%esp)
80105341:	e8 f7 b1 ff ff       	call   8010053d <panic>
  if(proc->state == RUNNING)
80105346:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010534c:	8b 40 0c             	mov    0xc(%eax),%eax
8010534f:	83 f8 04             	cmp    $0x4,%eax
80105352:	75 0c                	jne    80105360 <sched+0x59>
    panic("sched running");
80105354:	c7 04 24 9e 97 10 80 	movl   $0x8010979e,(%esp)
8010535b:	e8 dd b1 ff ff       	call   8010053d <panic>
  if(readeflags()&FL_IF)
80105360:	e8 2c f2 ff ff       	call   80104591 <readeflags>
80105365:	25 00 02 00 00       	and    $0x200,%eax
8010536a:	85 c0                	test   %eax,%eax
8010536c:	74 0c                	je     8010537a <sched+0x73>
    panic("sched interruptible");
8010536e:	c7 04 24 ac 97 10 80 	movl   $0x801097ac,(%esp)
80105375:	e8 c3 b1 ff ff       	call   8010053d <panic>
  intena = cpu->intena;
8010537a:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105380:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80105386:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->context, cpu->scheduler);
80105389:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010538f:	8b 40 04             	mov    0x4(%eax),%eax
80105392:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80105399:	83 c2 1c             	add    $0x1c,%edx
8010539c:	89 44 24 04          	mov    %eax,0x4(%esp)
801053a0:	89 14 24             	mov    %edx,(%esp)
801053a3:	e8 d8 09 00 00       	call   80105d80 <swtch>
  cpu->intena = intena;
801053a8:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801053ae:	8b 55 f4             	mov    -0xc(%ebp),%edx
801053b1:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
801053b7:	c9                   	leave  
801053b8:	c3                   	ret    

801053b9 <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
801053b9:	55                   	push   %ebp
801053ba:	89 e5                	mov    %esp,%ebp
801053bc:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
801053bf:	c7 04 24 80 3f 11 80 	movl   $0x80113f80,(%esp)
801053c6:	e8 88 04 00 00       	call   80105853 <acquire>
  proc->state = RUNNABLE;
801053cb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801053d1:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
801053d8:	e8 2a ff ff ff       	call   80105307 <sched>
  release(&ptable.lock);
801053dd:	c7 04 24 80 3f 11 80 	movl   $0x80113f80,(%esp)
801053e4:	e8 05 05 00 00       	call   801058ee <release>
}
801053e9:	c9                   	leave  
801053ea:	c3                   	ret    

801053eb <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
801053eb:	55                   	push   %ebp
801053ec:	89 e5                	mov    %esp,%ebp
801053ee:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
801053f1:	c7 04 24 80 3f 11 80 	movl   $0x80113f80,(%esp)
801053f8:	e8 f1 04 00 00       	call   801058ee <release>

  if (first) {
801053fd:	a1 20 c0 10 80       	mov    0x8010c020,%eax
80105402:	85 c0                	test   %eax,%eax
80105404:	74 0f                	je     80105415 <forkret+0x2a>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
80105406:	c7 05 20 c0 10 80 00 	movl   $0x0,0x8010c020
8010540d:	00 00 00 
    initlog();
80105410:	e8 8f e1 ff ff       	call   801035a4 <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
80105415:	c9                   	leave  
80105416:	c3                   	ret    

80105417 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
80105417:	55                   	push   %ebp
80105418:	89 e5                	mov    %esp,%ebp
8010541a:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
8010541d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105423:	85 c0                	test   %eax,%eax
80105425:	75 0c                	jne    80105433 <sleep+0x1c>
    panic("sleep");
80105427:	c7 04 24 c0 97 10 80 	movl   $0x801097c0,(%esp)
8010542e:	e8 0a b1 ff ff       	call   8010053d <panic>

  if(lk == 0)
80105433:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80105437:	75 0c                	jne    80105445 <sleep+0x2e>
    panic("sleep without lk");
80105439:	c7 04 24 c6 97 10 80 	movl   $0x801097c6,(%esp)
80105440:	e8 f8 b0 ff ff       	call   8010053d <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
80105445:	81 7d 0c 80 3f 11 80 	cmpl   $0x80113f80,0xc(%ebp)
8010544c:	74 17                	je     80105465 <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
8010544e:	c7 04 24 80 3f 11 80 	movl   $0x80113f80,(%esp)
80105455:	e8 f9 03 00 00       	call   80105853 <acquire>
    release(lk);
8010545a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010545d:	89 04 24             	mov    %eax,(%esp)
80105460:	e8 89 04 00 00       	call   801058ee <release>
  }

  // Go to sleep.
  proc->chan = chan;
80105465:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010546b:	8b 55 08             	mov    0x8(%ebp),%edx
8010546e:	89 50 20             	mov    %edx,0x20(%eax)
  proc->state = SLEEPING;
80105471:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105477:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)

  // Swap out
  if(swapFlag)
8010547e:	a1 68 c6 10 80       	mov    0x8010c668,%eax
80105483:	85 c0                	test   %eax,%eax
80105485:	74 2b                	je     801054b2 <sleep+0x9b>
  {
    if(proc->pid > 3)
80105487:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010548d:	8b 40 10             	mov    0x10(%eax),%eax
80105490:	83 f8 03             	cmp    $0x3,%eax
80105493:	7e 1d                	jle    801054b2 <sleep+0x9b>
    {
      release(&ptable.lock);
80105495:	c7 04 24 80 3f 11 80 	movl   $0x80113f80,(%esp)
8010549c:	e8 4d 04 00 00       	call   801058ee <release>
      swapOut();
801054a1:	e8 0d f6 ff ff       	call   80104ab3 <swapOut>
      acquire(&ptable.lock);
801054a6:	c7 04 24 80 3f 11 80 	movl   $0x80113f80,(%esp)
801054ad:	e8 a1 03 00 00       	call   80105853 <acquire>
    }
  }
  
  sched();
801054b2:	e8 50 fe ff ff       	call   80105307 <sched>
  
  // Tidy up.
  proc->chan = 0;
801054b7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054bd:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
801054c4:	81 7d 0c 80 3f 11 80 	cmpl   $0x80113f80,0xc(%ebp)
801054cb:	74 17                	je     801054e4 <sleep+0xcd>
    release(&ptable.lock);
801054cd:	c7 04 24 80 3f 11 80 	movl   $0x80113f80,(%esp)
801054d4:	e8 15 04 00 00       	call   801058ee <release>
    acquire(lk);
801054d9:	8b 45 0c             	mov    0xc(%ebp),%eax
801054dc:	89 04 24             	mov    %eax,(%esp)
801054df:	e8 6f 03 00 00       	call   80105853 <acquire>
  }
}
801054e4:	c9                   	leave  
801054e5:	c3                   	ret    

801054e6 <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
801054e6:	55                   	push   %ebp
801054e7:	89 e5                	mov    %esp,%ebp
801054e9:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801054ec:	c7 45 fc b4 3f 11 80 	movl   $0x80113fb4,-0x4(%ebp)
801054f3:	eb 53                	jmp    80105548 <wakeup1+0x62>
  {
    if(p->state == SLEEPING && p->chan == chan)
801054f5:	8b 45 fc             	mov    -0x4(%ebp),%eax
801054f8:	8b 40 0c             	mov    0xc(%eax),%eax
801054fb:	83 f8 02             	cmp    $0x2,%eax
801054fe:	75 15                	jne    80105515 <wakeup1+0x2f>
80105500:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105503:	8b 40 20             	mov    0x20(%eax),%eax
80105506:	3b 45 08             	cmp    0x8(%ebp),%eax
80105509:	75 0a                	jne    80105515 <wakeup1+0x2f>
      p->state = RUNNABLE;
8010550b:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010550e:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
    if(p->state == SLEEPING_SUSPENDED && p->chan == chan)
80105515:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105518:	8b 40 0c             	mov    0xc(%eax),%eax
8010551b:	83 f8 06             	cmp    $0x6,%eax
8010551e:	75 21                	jne    80105541 <wakeup1+0x5b>
80105520:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105523:	8b 40 20             	mov    0x20(%eax),%eax
80105526:	3b 45 08             	cmp    0x8(%ebp),%eax
80105529:	75 16                	jne    80105541 <wakeup1+0x5b>
    {
      p->state = RUNNABLE_SUSPENDED;
8010552b:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010552e:	c7 40 0c 07 00 00 00 	movl   $0x7,0xc(%eax)
      inswapper->state = RUNNABLE;
80105535:	a1 70 c6 10 80       	mov    0x8010c670,%eax
8010553a:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80105541:	81 45 fc 8c 00 00 00 	addl   $0x8c,-0x4(%ebp)
80105548:	81 7d fc b4 62 11 80 	cmpl   $0x801162b4,-0x4(%ebp)
8010554f:	72 a4                	jb     801054f5 <wakeup1+0xf>
    {
      p->state = RUNNABLE_SUSPENDED;
      inswapper->state = RUNNABLE;
    }
  }
}
80105551:	c9                   	leave  
80105552:	c3                   	ret    

80105553 <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80105553:	55                   	push   %ebp
80105554:	89 e5                	mov    %esp,%ebp
80105556:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);
80105559:	c7 04 24 80 3f 11 80 	movl   $0x80113f80,(%esp)
80105560:	e8 ee 02 00 00       	call   80105853 <acquire>
  wakeup1(chan);
80105565:	8b 45 08             	mov    0x8(%ebp),%eax
80105568:	89 04 24             	mov    %eax,(%esp)
8010556b:	e8 76 ff ff ff       	call   801054e6 <wakeup1>
  release(&ptable.lock);
80105570:	c7 04 24 80 3f 11 80 	movl   $0x80113f80,(%esp)
80105577:	e8 72 03 00 00       	call   801058ee <release>
}
8010557c:	c9                   	leave  
8010557d:	c3                   	ret    

8010557e <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
8010557e:	55                   	push   %ebp
8010557f:	89 e5                	mov    %esp,%ebp
80105581:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  acquire(&ptable.lock);
80105584:	c7 04 24 80 3f 11 80 	movl   $0x80113f80,(%esp)
8010558b:	e8 c3 02 00 00       	call   80105853 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105590:	c7 45 f4 b4 3f 11 80 	movl   $0x80113fb4,-0xc(%ebp)
80105597:	eb 67                	jmp    80105600 <kill+0x82>
    if(p->pid == pid){
80105599:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010559c:	8b 40 10             	mov    0x10(%eax),%eax
8010559f:	3b 45 08             	cmp    0x8(%ebp),%eax
801055a2:	75 55                	jne    801055f9 <kill+0x7b>
      p->killed = 1;
801055a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055a7:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
801055ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055b1:	8b 40 0c             	mov    0xc(%eax),%eax
801055b4:	83 f8 02             	cmp    $0x2,%eax
801055b7:	75 0c                	jne    801055c5 <kill+0x47>
        p->state = RUNNABLE;
801055b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055bc:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
801055c3:	eb 21                	jmp    801055e6 <kill+0x68>
      else if(p->state == SLEEPING_SUSPENDED)
801055c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055c8:	8b 40 0c             	mov    0xc(%eax),%eax
801055cb:	83 f8 06             	cmp    $0x6,%eax
801055ce:	75 16                	jne    801055e6 <kill+0x68>
      {
        p->state = RUNNABLE_SUSPENDED;
801055d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055d3:	c7 40 0c 07 00 00 00 	movl   $0x7,0xc(%eax)
	inswapper->state = RUNNABLE;
801055da:	a1 70 c6 10 80       	mov    0x8010c670,%eax
801055df:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      }
      release(&ptable.lock);
801055e6:	c7 04 24 80 3f 11 80 	movl   $0x80113f80,(%esp)
801055ed:	e8 fc 02 00 00       	call   801058ee <release>
      return 0;
801055f2:	b8 00 00 00 00       	mov    $0x0,%eax
801055f7:	eb 21                	jmp    8010561a <kill+0x9c>
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801055f9:	81 45 f4 8c 00 00 00 	addl   $0x8c,-0xc(%ebp)
80105600:	81 7d f4 b4 62 11 80 	cmpl   $0x801162b4,-0xc(%ebp)
80105607:	72 90                	jb     80105599 <kill+0x1b>
      }
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
80105609:	c7 04 24 80 3f 11 80 	movl   $0x80113f80,(%esp)
80105610:	e8 d9 02 00 00       	call   801058ee <release>
  return -1;
80105615:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010561a:	c9                   	leave  
8010561b:	c3                   	ret    

8010561c <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
8010561c:	55                   	push   %ebp
8010561d:	89 e5                	mov    %esp,%ebp
8010561f:	83 ec 58             	sub    $0x58,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105622:	c7 45 f0 b4 3f 11 80 	movl   $0x80113fb4,-0x10(%ebp)
80105629:	e9 db 00 00 00       	jmp    80105709 <procdump+0xed>
    if(p->state == UNUSED)
8010562e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105631:	8b 40 0c             	mov    0xc(%eax),%eax
80105634:	85 c0                	test   %eax,%eax
80105636:	0f 84 c5 00 00 00    	je     80105701 <procdump+0xe5>
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
8010563c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010563f:	8b 40 0c             	mov    0xc(%eax),%eax
80105642:	83 f8 05             	cmp    $0x5,%eax
80105645:	77 23                	ja     8010566a <procdump+0x4e>
80105647:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010564a:	8b 40 0c             	mov    0xc(%eax),%eax
8010564d:	8b 04 85 08 c0 10 80 	mov    -0x7fef3ff8(,%eax,4),%eax
80105654:	85 c0                	test   %eax,%eax
80105656:	74 12                	je     8010566a <procdump+0x4e>
      state = states[p->state];
80105658:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010565b:	8b 40 0c             	mov    0xc(%eax),%eax
8010565e:	8b 04 85 08 c0 10 80 	mov    -0x7fef3ff8(,%eax,4),%eax
80105665:	89 45 ec             	mov    %eax,-0x14(%ebp)
80105668:	eb 07                	jmp    80105671 <procdump+0x55>
    else
      state = "???";
8010566a:	c7 45 ec d7 97 10 80 	movl   $0x801097d7,-0x14(%ebp)
    cprintf("%d %s %s", p->pid, state, p->name);
80105671:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105674:	8d 50 6c             	lea    0x6c(%eax),%edx
80105677:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010567a:	8b 40 10             	mov    0x10(%eax),%eax
8010567d:	89 54 24 0c          	mov    %edx,0xc(%esp)
80105681:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105684:	89 54 24 08          	mov    %edx,0x8(%esp)
80105688:	89 44 24 04          	mov    %eax,0x4(%esp)
8010568c:	c7 04 24 db 97 10 80 	movl   $0x801097db,(%esp)
80105693:	e8 09 ad ff ff       	call   801003a1 <cprintf>
    if(p->state == SLEEPING){
80105698:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010569b:	8b 40 0c             	mov    0xc(%eax),%eax
8010569e:	83 f8 02             	cmp    $0x2,%eax
801056a1:	75 50                	jne    801056f3 <procdump+0xd7>
      getcallerpcs((uint*)p->context->ebp+2, pc);
801056a3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801056a6:	8b 40 1c             	mov    0x1c(%eax),%eax
801056a9:	8b 40 0c             	mov    0xc(%eax),%eax
801056ac:	83 c0 08             	add    $0x8,%eax
801056af:	8d 55 c4             	lea    -0x3c(%ebp),%edx
801056b2:	89 54 24 04          	mov    %edx,0x4(%esp)
801056b6:	89 04 24             	mov    %eax,(%esp)
801056b9:	e8 7f 02 00 00       	call   8010593d <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
801056be:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801056c5:	eb 1b                	jmp    801056e2 <procdump+0xc6>
        cprintf(" %p", pc[i]);
801056c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801056ca:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
801056ce:	89 44 24 04          	mov    %eax,0x4(%esp)
801056d2:	c7 04 24 e4 97 10 80 	movl   $0x801097e4,(%esp)
801056d9:	e8 c3 ac ff ff       	call   801003a1 <cprintf>
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
801056de:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801056e2:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
801056e6:	7f 0b                	jg     801056f3 <procdump+0xd7>
801056e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801056eb:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
801056ef:	85 c0                	test   %eax,%eax
801056f1:	75 d4                	jne    801056c7 <procdump+0xab>
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
801056f3:	c7 04 24 e8 97 10 80 	movl   $0x801097e8,(%esp)
801056fa:	e8 a2 ac ff ff       	call   801003a1 <cprintf>
801056ff:	eb 01                	jmp    80105702 <procdump+0xe6>
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
80105701:	90                   	nop
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105702:	81 45 f0 8c 00 00 00 	addl   $0x8c,-0x10(%ebp)
80105709:	81 7d f0 b4 62 11 80 	cmpl   $0x801162b4,-0x10(%ebp)
80105710:	0f 82 18 ff ff ff    	jb     8010562e <procdump+0x12>
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}
80105716:	c9                   	leave  
80105717:	c3                   	ret    

80105718 <getAllocatedPages>:

int getAllocatedPages(int pid) {
80105718:	55                   	push   %ebp
80105719:	89 e5                	mov    %esp,%ebp
8010571b:	83 ec 38             	sub    $0x38,%esp
  struct proc* p;
  acquire(&ptable.lock);
8010571e:	c7 04 24 80 3f 11 80 	movl   $0x80113f80,(%esp)
80105725:	e8 29 01 00 00       	call   80105853 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010572a:	c7 45 f4 b4 3f 11 80 	movl   $0x80113fb4,-0xc(%ebp)
80105731:	eb 12                	jmp    80105745 <getAllocatedPages+0x2d>
    if(p->pid == pid){
80105733:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105736:	8b 40 10             	mov    0x10(%eax),%eax
80105739:	3b 45 08             	cmp    0x8(%ebp),%eax
8010573c:	74 12                	je     80105750 <getAllocatedPages+0x38>
}

int getAllocatedPages(int pid) {
  struct proc* p;
  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010573e:	81 45 f4 8c 00 00 00 	addl   $0x8c,-0xc(%ebp)
80105745:	81 7d f4 b4 62 11 80 	cmpl   $0x801162b4,-0xc(%ebp)
8010574c:	72 e5                	jb     80105733 <getAllocatedPages+0x1b>
8010574e:	eb 01                	jmp    80105751 <getAllocatedPages+0x39>
    if(p->pid == pid){
     break;
80105750:	90                   	nop
    }
  }
  release(&ptable.lock);
80105751:	c7 04 24 80 3f 11 80 	movl   $0x80113f80,(%esp)
80105758:	e8 91 01 00 00       	call   801058ee <release>
   int count= 0, j, k;
8010575d:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   for (j=0; j<1024; j++) {
80105764:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
8010576b:	eb 71                	jmp    801057de <getAllocatedPages+0xc6>
      if(p->pgdir){ 
8010576d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105770:	8b 40 04             	mov    0x4(%eax),%eax
80105773:	85 c0                	test   %eax,%eax
80105775:	74 63                	je     801057da <getAllocatedPages+0xc2>
	if (p->pgdir[j] & PTE_P) {
80105777:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010577a:	8b 40 04             	mov    0x4(%eax),%eax
8010577d:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105780:	c1 e2 02             	shl    $0x2,%edx
80105783:	01 d0                	add    %edx,%eax
80105785:	8b 00                	mov    (%eax),%eax
80105787:	83 e0 01             	and    $0x1,%eax
8010578a:	84 c0                	test   %al,%al
8010578c:	74 4c                	je     801057da <getAllocatedPages+0xc2>
	  pte_t* pte= (pte_t*)p2v(PTE_ADDR(p->pgdir[j]));
8010578e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105791:	8b 40 04             	mov    0x4(%eax),%eax
80105794:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105797:	c1 e2 02             	shl    $0x2,%edx
8010579a:	01 d0                	add    %edx,%eax
8010579c:	8b 00                	mov    (%eax),%eax
8010579e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801057a3:	89 04 24             	mov    %eax,(%esp)
801057a6:	e8 d9 ed ff ff       	call   80104584 <p2v>
801057ab:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	  for (k=0; k<1024; k++) {
801057ae:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
801057b5:	eb 1a                	jmp    801057d1 <getAllocatedPages+0xb9>
	      if ( pte[k] & PTE_U )
801057b7:	8b 45 e8             	mov    -0x18(%ebp),%eax
801057ba:	c1 e0 02             	shl    $0x2,%eax
801057bd:	03 45 e4             	add    -0x1c(%ebp),%eax
801057c0:	8b 00                	mov    (%eax),%eax
801057c2:	83 e0 04             	and    $0x4,%eax
801057c5:	85 c0                	test   %eax,%eax
801057c7:	74 04                	je     801057cd <getAllocatedPages+0xb5>
		count++;
801057c9:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   int count= 0, j, k;
   for (j=0; j<1024; j++) {
      if(p->pgdir){ 
	if (p->pgdir[j] & PTE_P) {
	  pte_t* pte= (pte_t*)p2v(PTE_ADDR(p->pgdir[j]));
	  for (k=0; k<1024; k++) {
801057cd:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
801057d1:	81 7d e8 ff 03 00 00 	cmpl   $0x3ff,-0x18(%ebp)
801057d8:	7e dd                	jle    801057b7 <getAllocatedPages+0x9f>
     break;
    }
  }
  release(&ptable.lock);
   int count= 0, j, k;
   for (j=0; j<1024; j++) {
801057da:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
801057de:	81 7d ec ff 03 00 00 	cmpl   $0x3ff,-0x14(%ebp)
801057e5:	7e 86                	jle    8010576d <getAllocatedPages+0x55>
		count++;
	  }
	}
      }
   }
   return count;
801057e7:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
801057ea:	c9                   	leave  
801057eb:	c3                   	ret    

801057ec <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
801057ec:	55                   	push   %ebp
801057ed:	89 e5                	mov    %esp,%ebp
801057ef:	53                   	push   %ebx
801057f0:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801057f3:	9c                   	pushf  
801057f4:	5b                   	pop    %ebx
801057f5:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
801057f8:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
801057fb:	83 c4 10             	add    $0x10,%esp
801057fe:	5b                   	pop    %ebx
801057ff:	5d                   	pop    %ebp
80105800:	c3                   	ret    

80105801 <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
80105801:	55                   	push   %ebp
80105802:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
80105804:	fa                   	cli    
}
80105805:	5d                   	pop    %ebp
80105806:	c3                   	ret    

80105807 <sti>:

static inline void
sti(void)
{
80105807:	55                   	push   %ebp
80105808:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
8010580a:	fb                   	sti    
}
8010580b:	5d                   	pop    %ebp
8010580c:	c3                   	ret    

8010580d <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
8010580d:	55                   	push   %ebp
8010580e:	89 e5                	mov    %esp,%ebp
80105810:	53                   	push   %ebx
80105811:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
80105814:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80105817:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
8010581a:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
8010581d:	89 c3                	mov    %eax,%ebx
8010581f:	89 d8                	mov    %ebx,%eax
80105821:	f0 87 02             	lock xchg %eax,(%edx)
80105824:	89 c3                	mov    %eax,%ebx
80105826:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80105829:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
8010582c:	83 c4 10             	add    $0x10,%esp
8010582f:	5b                   	pop    %ebx
80105830:	5d                   	pop    %ebp
80105831:	c3                   	ret    

80105832 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80105832:	55                   	push   %ebp
80105833:	89 e5                	mov    %esp,%ebp
  lk->name = name;
80105835:	8b 45 08             	mov    0x8(%ebp),%eax
80105838:	8b 55 0c             	mov    0xc(%ebp),%edx
8010583b:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
8010583e:	8b 45 08             	mov    0x8(%ebp),%eax
80105841:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80105847:	8b 45 08             	mov    0x8(%ebp),%eax
8010584a:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80105851:	5d                   	pop    %ebp
80105852:	c3                   	ret    

80105853 <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
80105853:	55                   	push   %ebp
80105854:	89 e5                	mov    %esp,%ebp
80105856:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80105859:	e8 76 01 00 00       	call   801059d4 <pushcli>
  if(holding(lk))
8010585e:	8b 45 08             	mov    0x8(%ebp),%eax
80105861:	89 04 24             	mov    %eax,(%esp)
80105864:	e8 41 01 00 00       	call   801059aa <holding>
80105869:	85 c0                	test   %eax,%eax
8010586b:	74 45                	je     801058b2 <acquire+0x5f>
  {
    cprintf("lock = %s\n",lk->name);
8010586d:	8b 45 08             	mov    0x8(%ebp),%eax
80105870:	8b 40 04             	mov    0x4(%eax),%eax
80105873:	89 44 24 04          	mov    %eax,0x4(%esp)
80105877:	c7 04 24 14 98 10 80 	movl   $0x80109814,(%esp)
8010587e:	e8 1e ab ff ff       	call   801003a1 <cprintf>
    if(proc)
80105883:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105889:	85 c0                	test   %eax,%eax
8010588b:	74 19                	je     801058a6 <acquire+0x53>
      cprintf("pid = %d\n",proc->pid);
8010588d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105893:	8b 40 10             	mov    0x10(%eax),%eax
80105896:	89 44 24 04          	mov    %eax,0x4(%esp)
8010589a:	c7 04 24 1f 98 10 80 	movl   $0x8010981f,(%esp)
801058a1:	e8 fb aa ff ff       	call   801003a1 <cprintf>
    panic("acquire");
801058a6:	c7 04 24 29 98 10 80 	movl   $0x80109829,(%esp)
801058ad:	e8 8b ac ff ff       	call   8010053d <panic>
  }

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
801058b2:	90                   	nop
801058b3:	8b 45 08             	mov    0x8(%ebp),%eax
801058b6:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801058bd:	00 
801058be:	89 04 24             	mov    %eax,(%esp)
801058c1:	e8 47 ff ff ff       	call   8010580d <xchg>
801058c6:	85 c0                	test   %eax,%eax
801058c8:	75 e9                	jne    801058b3 <acquire+0x60>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
801058ca:	8b 45 08             	mov    0x8(%ebp),%eax
801058cd:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801058d4:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
801058d7:	8b 45 08             	mov    0x8(%ebp),%eax
801058da:	83 c0 0c             	add    $0xc,%eax
801058dd:	89 44 24 04          	mov    %eax,0x4(%esp)
801058e1:	8d 45 08             	lea    0x8(%ebp),%eax
801058e4:	89 04 24             	mov    %eax,(%esp)
801058e7:	e8 51 00 00 00       	call   8010593d <getcallerpcs>
}
801058ec:	c9                   	leave  
801058ed:	c3                   	ret    

801058ee <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
801058ee:	55                   	push   %ebp
801058ef:	89 e5                	mov    %esp,%ebp
801058f1:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
801058f4:	8b 45 08             	mov    0x8(%ebp),%eax
801058f7:	89 04 24             	mov    %eax,(%esp)
801058fa:	e8 ab 00 00 00       	call   801059aa <holding>
801058ff:	85 c0                	test   %eax,%eax
80105901:	75 0c                	jne    8010590f <release+0x21>
    panic("release");
80105903:	c7 04 24 31 98 10 80 	movl   $0x80109831,(%esp)
8010590a:	e8 2e ac ff ff       	call   8010053d <panic>

  lk->pcs[0] = 0;
8010590f:	8b 45 08             	mov    0x8(%ebp),%eax
80105912:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
80105919:	8b 45 08             	mov    0x8(%ebp),%eax
8010591c:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
80105923:	8b 45 08             	mov    0x8(%ebp),%eax
80105926:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010592d:	00 
8010592e:	89 04 24             	mov    %eax,(%esp)
80105931:	e8 d7 fe ff ff       	call   8010580d <xchg>

  popcli();
80105936:	e8 e1 00 00 00       	call   80105a1c <popcli>
}
8010593b:	c9                   	leave  
8010593c:	c3                   	ret    

8010593d <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
8010593d:	55                   	push   %ebp
8010593e:	89 e5                	mov    %esp,%ebp
80105940:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
80105943:	8b 45 08             	mov    0x8(%ebp),%eax
80105946:	83 e8 08             	sub    $0x8,%eax
80105949:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
8010594c:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
80105953:	eb 32                	jmp    80105987 <getcallerpcs+0x4a>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80105955:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
80105959:	74 47                	je     801059a2 <getcallerpcs+0x65>
8010595b:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
80105962:	76 3e                	jbe    801059a2 <getcallerpcs+0x65>
80105964:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
80105968:	74 38                	je     801059a2 <getcallerpcs+0x65>
      break;
    pcs[i] = ebp[1];     // saved %eip
8010596a:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010596d:	c1 e0 02             	shl    $0x2,%eax
80105970:	03 45 0c             	add    0xc(%ebp),%eax
80105973:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105976:	8b 52 04             	mov    0x4(%edx),%edx
80105979:	89 10                	mov    %edx,(%eax)
    ebp = (uint*)ebp[0]; // saved %ebp
8010597b:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010597e:	8b 00                	mov    (%eax),%eax
80105980:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
80105983:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105987:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
8010598b:	7e c8                	jle    80105955 <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
8010598d:	eb 13                	jmp    801059a2 <getcallerpcs+0x65>
    pcs[i] = 0;
8010598f:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105992:	c1 e0 02             	shl    $0x2,%eax
80105995:	03 45 0c             	add    0xc(%ebp),%eax
80105998:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
8010599e:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
801059a2:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
801059a6:	7e e7                	jle    8010598f <getcallerpcs+0x52>
    pcs[i] = 0;
}
801059a8:	c9                   	leave  
801059a9:	c3                   	ret    

801059aa <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
801059aa:	55                   	push   %ebp
801059ab:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
801059ad:	8b 45 08             	mov    0x8(%ebp),%eax
801059b0:	8b 00                	mov    (%eax),%eax
801059b2:	85 c0                	test   %eax,%eax
801059b4:	74 17                	je     801059cd <holding+0x23>
801059b6:	8b 45 08             	mov    0x8(%ebp),%eax
801059b9:	8b 50 08             	mov    0x8(%eax),%edx
801059bc:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801059c2:	39 c2                	cmp    %eax,%edx
801059c4:	75 07                	jne    801059cd <holding+0x23>
801059c6:	b8 01 00 00 00       	mov    $0x1,%eax
801059cb:	eb 05                	jmp    801059d2 <holding+0x28>
801059cd:	b8 00 00 00 00       	mov    $0x0,%eax
}
801059d2:	5d                   	pop    %ebp
801059d3:	c3                   	ret    

801059d4 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
801059d4:	55                   	push   %ebp
801059d5:	89 e5                	mov    %esp,%ebp
801059d7:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
801059da:	e8 0d fe ff ff       	call   801057ec <readeflags>
801059df:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
801059e2:	e8 1a fe ff ff       	call   80105801 <cli>
  if(cpu->ncli++ == 0)
801059e7:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801059ed:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
801059f3:	85 d2                	test   %edx,%edx
801059f5:	0f 94 c1             	sete   %cl
801059f8:	83 c2 01             	add    $0x1,%edx
801059fb:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80105a01:	84 c9                	test   %cl,%cl
80105a03:	74 15                	je     80105a1a <pushcli+0x46>
    cpu->intena = eflags & FL_IF;
80105a05:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105a0b:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105a0e:	81 e2 00 02 00 00    	and    $0x200,%edx
80105a14:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80105a1a:	c9                   	leave  
80105a1b:	c3                   	ret    

80105a1c <popcli>:

void
popcli(void)
{
80105a1c:	55                   	push   %ebp
80105a1d:	89 e5                	mov    %esp,%ebp
80105a1f:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
80105a22:	e8 c5 fd ff ff       	call   801057ec <readeflags>
80105a27:	25 00 02 00 00       	and    $0x200,%eax
80105a2c:	85 c0                	test   %eax,%eax
80105a2e:	74 0c                	je     80105a3c <popcli+0x20>
    panic("popcli - interruptible");
80105a30:	c7 04 24 39 98 10 80 	movl   $0x80109839,(%esp)
80105a37:	e8 01 ab ff ff       	call   8010053d <panic>
  if(--cpu->ncli < 0)
80105a3c:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105a42:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80105a48:	83 ea 01             	sub    $0x1,%edx
80105a4b:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80105a51:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105a57:	85 c0                	test   %eax,%eax
80105a59:	79 0c                	jns    80105a67 <popcli+0x4b>
    panic("popcli");
80105a5b:	c7 04 24 50 98 10 80 	movl   $0x80109850,(%esp)
80105a62:	e8 d6 aa ff ff       	call   8010053d <panic>
  if(cpu->ncli == 0 && cpu->intena)
80105a67:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105a6d:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105a73:	85 c0                	test   %eax,%eax
80105a75:	75 15                	jne    80105a8c <popcli+0x70>
80105a77:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105a7d:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80105a83:	85 c0                	test   %eax,%eax
80105a85:	74 05                	je     80105a8c <popcli+0x70>
    sti();
80105a87:	e8 7b fd ff ff       	call   80105807 <sti>
}
80105a8c:	c9                   	leave  
80105a8d:	c3                   	ret    
	...

80105a90 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
80105a90:	55                   	push   %ebp
80105a91:	89 e5                	mov    %esp,%ebp
80105a93:	57                   	push   %edi
80105a94:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
80105a95:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105a98:	8b 55 10             	mov    0x10(%ebp),%edx
80105a9b:	8b 45 0c             	mov    0xc(%ebp),%eax
80105a9e:	89 cb                	mov    %ecx,%ebx
80105aa0:	89 df                	mov    %ebx,%edi
80105aa2:	89 d1                	mov    %edx,%ecx
80105aa4:	fc                   	cld    
80105aa5:	f3 aa                	rep stos %al,%es:(%edi)
80105aa7:	89 ca                	mov    %ecx,%edx
80105aa9:	89 fb                	mov    %edi,%ebx
80105aab:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105aae:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105ab1:	5b                   	pop    %ebx
80105ab2:	5f                   	pop    %edi
80105ab3:	5d                   	pop    %ebp
80105ab4:	c3                   	ret    

80105ab5 <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
80105ab5:	55                   	push   %ebp
80105ab6:	89 e5                	mov    %esp,%ebp
80105ab8:	57                   	push   %edi
80105ab9:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
80105aba:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105abd:	8b 55 10             	mov    0x10(%ebp),%edx
80105ac0:	8b 45 0c             	mov    0xc(%ebp),%eax
80105ac3:	89 cb                	mov    %ecx,%ebx
80105ac5:	89 df                	mov    %ebx,%edi
80105ac7:	89 d1                	mov    %edx,%ecx
80105ac9:	fc                   	cld    
80105aca:	f3 ab                	rep stos %eax,%es:(%edi)
80105acc:	89 ca                	mov    %ecx,%edx
80105ace:	89 fb                	mov    %edi,%ebx
80105ad0:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105ad3:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105ad6:	5b                   	pop    %ebx
80105ad7:	5f                   	pop    %edi
80105ad8:	5d                   	pop    %ebp
80105ad9:	c3                   	ret    

80105ada <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80105ada:	55                   	push   %ebp
80105adb:	89 e5                	mov    %esp,%ebp
80105add:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
80105ae0:	8b 45 08             	mov    0x8(%ebp),%eax
80105ae3:	83 e0 03             	and    $0x3,%eax
80105ae6:	85 c0                	test   %eax,%eax
80105ae8:	75 49                	jne    80105b33 <memset+0x59>
80105aea:	8b 45 10             	mov    0x10(%ebp),%eax
80105aed:	83 e0 03             	and    $0x3,%eax
80105af0:	85 c0                	test   %eax,%eax
80105af2:	75 3f                	jne    80105b33 <memset+0x59>
    c &= 0xFF;
80105af4:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80105afb:	8b 45 10             	mov    0x10(%ebp),%eax
80105afe:	c1 e8 02             	shr    $0x2,%eax
80105b01:	89 c2                	mov    %eax,%edx
80105b03:	8b 45 0c             	mov    0xc(%ebp),%eax
80105b06:	89 c1                	mov    %eax,%ecx
80105b08:	c1 e1 18             	shl    $0x18,%ecx
80105b0b:	8b 45 0c             	mov    0xc(%ebp),%eax
80105b0e:	c1 e0 10             	shl    $0x10,%eax
80105b11:	09 c1                	or     %eax,%ecx
80105b13:	8b 45 0c             	mov    0xc(%ebp),%eax
80105b16:	c1 e0 08             	shl    $0x8,%eax
80105b19:	09 c8                	or     %ecx,%eax
80105b1b:	0b 45 0c             	or     0xc(%ebp),%eax
80105b1e:	89 54 24 08          	mov    %edx,0x8(%esp)
80105b22:	89 44 24 04          	mov    %eax,0x4(%esp)
80105b26:	8b 45 08             	mov    0x8(%ebp),%eax
80105b29:	89 04 24             	mov    %eax,(%esp)
80105b2c:	e8 84 ff ff ff       	call   80105ab5 <stosl>
80105b31:	eb 19                	jmp    80105b4c <memset+0x72>
  } else
    stosb(dst, c, n);
80105b33:	8b 45 10             	mov    0x10(%ebp),%eax
80105b36:	89 44 24 08          	mov    %eax,0x8(%esp)
80105b3a:	8b 45 0c             	mov    0xc(%ebp),%eax
80105b3d:	89 44 24 04          	mov    %eax,0x4(%esp)
80105b41:	8b 45 08             	mov    0x8(%ebp),%eax
80105b44:	89 04 24             	mov    %eax,(%esp)
80105b47:	e8 44 ff ff ff       	call   80105a90 <stosb>
  return dst;
80105b4c:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105b4f:	c9                   	leave  
80105b50:	c3                   	ret    

80105b51 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80105b51:	55                   	push   %ebp
80105b52:	89 e5                	mov    %esp,%ebp
80105b54:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
80105b57:	8b 45 08             	mov    0x8(%ebp),%eax
80105b5a:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
80105b5d:	8b 45 0c             	mov    0xc(%ebp),%eax
80105b60:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
80105b63:	eb 32                	jmp    80105b97 <memcmp+0x46>
    if(*s1 != *s2)
80105b65:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105b68:	0f b6 10             	movzbl (%eax),%edx
80105b6b:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105b6e:	0f b6 00             	movzbl (%eax),%eax
80105b71:	38 c2                	cmp    %al,%dl
80105b73:	74 1a                	je     80105b8f <memcmp+0x3e>
      return *s1 - *s2;
80105b75:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105b78:	0f b6 00             	movzbl (%eax),%eax
80105b7b:	0f b6 d0             	movzbl %al,%edx
80105b7e:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105b81:	0f b6 00             	movzbl (%eax),%eax
80105b84:	0f b6 c0             	movzbl %al,%eax
80105b87:	89 d1                	mov    %edx,%ecx
80105b89:	29 c1                	sub    %eax,%ecx
80105b8b:	89 c8                	mov    %ecx,%eax
80105b8d:	eb 1c                	jmp    80105bab <memcmp+0x5a>
    s1++, s2++;
80105b8f:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105b93:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80105b97:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105b9b:	0f 95 c0             	setne  %al
80105b9e:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105ba2:	84 c0                	test   %al,%al
80105ba4:	75 bf                	jne    80105b65 <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
80105ba6:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105bab:	c9                   	leave  
80105bac:	c3                   	ret    

80105bad <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80105bad:	55                   	push   %ebp
80105bae:	89 e5                	mov    %esp,%ebp
80105bb0:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
80105bb3:	8b 45 0c             	mov    0xc(%ebp),%eax
80105bb6:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
80105bb9:	8b 45 08             	mov    0x8(%ebp),%eax
80105bbc:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
80105bbf:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105bc2:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105bc5:	73 54                	jae    80105c1b <memmove+0x6e>
80105bc7:	8b 45 10             	mov    0x10(%ebp),%eax
80105bca:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105bcd:	01 d0                	add    %edx,%eax
80105bcf:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105bd2:	76 47                	jbe    80105c1b <memmove+0x6e>
    s += n;
80105bd4:	8b 45 10             	mov    0x10(%ebp),%eax
80105bd7:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
80105bda:	8b 45 10             	mov    0x10(%ebp),%eax
80105bdd:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
80105be0:	eb 13                	jmp    80105bf5 <memmove+0x48>
      *--d = *--s;
80105be2:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
80105be6:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
80105bea:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105bed:	0f b6 10             	movzbl (%eax),%edx
80105bf0:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105bf3:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
80105bf5:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105bf9:	0f 95 c0             	setne  %al
80105bfc:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105c00:	84 c0                	test   %al,%al
80105c02:	75 de                	jne    80105be2 <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80105c04:	eb 25                	jmp    80105c2b <memmove+0x7e>
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
      *d++ = *s++;
80105c06:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105c09:	0f b6 10             	movzbl (%eax),%edx
80105c0c:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105c0f:	88 10                	mov    %dl,(%eax)
80105c11:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105c15:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105c19:	eb 01                	jmp    80105c1c <memmove+0x6f>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
80105c1b:	90                   	nop
80105c1c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105c20:	0f 95 c0             	setne  %al
80105c23:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105c27:	84 c0                	test   %al,%al
80105c29:	75 db                	jne    80105c06 <memmove+0x59>
      *d++ = *s++;

  return dst;
80105c2b:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105c2e:	c9                   	leave  
80105c2f:	c3                   	ret    

80105c30 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80105c30:	55                   	push   %ebp
80105c31:	89 e5                	mov    %esp,%ebp
80105c33:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
80105c36:	8b 45 10             	mov    0x10(%ebp),%eax
80105c39:	89 44 24 08          	mov    %eax,0x8(%esp)
80105c3d:	8b 45 0c             	mov    0xc(%ebp),%eax
80105c40:	89 44 24 04          	mov    %eax,0x4(%esp)
80105c44:	8b 45 08             	mov    0x8(%ebp),%eax
80105c47:	89 04 24             	mov    %eax,(%esp)
80105c4a:	e8 5e ff ff ff       	call   80105bad <memmove>
}
80105c4f:	c9                   	leave  
80105c50:	c3                   	ret    

80105c51 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80105c51:	55                   	push   %ebp
80105c52:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
80105c54:	eb 0c                	jmp    80105c62 <strncmp+0x11>
    n--, p++, q++;
80105c56:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105c5a:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105c5e:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
80105c62:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105c66:	74 1a                	je     80105c82 <strncmp+0x31>
80105c68:	8b 45 08             	mov    0x8(%ebp),%eax
80105c6b:	0f b6 00             	movzbl (%eax),%eax
80105c6e:	84 c0                	test   %al,%al
80105c70:	74 10                	je     80105c82 <strncmp+0x31>
80105c72:	8b 45 08             	mov    0x8(%ebp),%eax
80105c75:	0f b6 10             	movzbl (%eax),%edx
80105c78:	8b 45 0c             	mov    0xc(%ebp),%eax
80105c7b:	0f b6 00             	movzbl (%eax),%eax
80105c7e:	38 c2                	cmp    %al,%dl
80105c80:	74 d4                	je     80105c56 <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
80105c82:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105c86:	75 07                	jne    80105c8f <strncmp+0x3e>
    return 0;
80105c88:	b8 00 00 00 00       	mov    $0x0,%eax
80105c8d:	eb 18                	jmp    80105ca7 <strncmp+0x56>
  return (uchar)*p - (uchar)*q;
80105c8f:	8b 45 08             	mov    0x8(%ebp),%eax
80105c92:	0f b6 00             	movzbl (%eax),%eax
80105c95:	0f b6 d0             	movzbl %al,%edx
80105c98:	8b 45 0c             	mov    0xc(%ebp),%eax
80105c9b:	0f b6 00             	movzbl (%eax),%eax
80105c9e:	0f b6 c0             	movzbl %al,%eax
80105ca1:	89 d1                	mov    %edx,%ecx
80105ca3:	29 c1                	sub    %eax,%ecx
80105ca5:	89 c8                	mov    %ecx,%eax
}
80105ca7:	5d                   	pop    %ebp
80105ca8:	c3                   	ret    

80105ca9 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80105ca9:	55                   	push   %ebp
80105caa:	89 e5                	mov    %esp,%ebp
80105cac:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105caf:	8b 45 08             	mov    0x8(%ebp),%eax
80105cb2:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
80105cb5:	90                   	nop
80105cb6:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105cba:	0f 9f c0             	setg   %al
80105cbd:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105cc1:	84 c0                	test   %al,%al
80105cc3:	74 30                	je     80105cf5 <strncpy+0x4c>
80105cc5:	8b 45 0c             	mov    0xc(%ebp),%eax
80105cc8:	0f b6 10             	movzbl (%eax),%edx
80105ccb:	8b 45 08             	mov    0x8(%ebp),%eax
80105cce:	88 10                	mov    %dl,(%eax)
80105cd0:	8b 45 08             	mov    0x8(%ebp),%eax
80105cd3:	0f b6 00             	movzbl (%eax),%eax
80105cd6:	84 c0                	test   %al,%al
80105cd8:	0f 95 c0             	setne  %al
80105cdb:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105cdf:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
80105ce3:	84 c0                	test   %al,%al
80105ce5:	75 cf                	jne    80105cb6 <strncpy+0xd>
    ;
  while(n-- > 0)
80105ce7:	eb 0c                	jmp    80105cf5 <strncpy+0x4c>
    *s++ = 0;
80105ce9:	8b 45 08             	mov    0x8(%ebp),%eax
80105cec:	c6 00 00             	movb   $0x0,(%eax)
80105cef:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105cf3:	eb 01                	jmp    80105cf6 <strncpy+0x4d>
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
80105cf5:	90                   	nop
80105cf6:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105cfa:	0f 9f c0             	setg   %al
80105cfd:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105d01:	84 c0                	test   %al,%al
80105d03:	75 e4                	jne    80105ce9 <strncpy+0x40>
    *s++ = 0;
  return os;
80105d05:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105d08:	c9                   	leave  
80105d09:	c3                   	ret    

80105d0a <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80105d0a:	55                   	push   %ebp
80105d0b:	89 e5                	mov    %esp,%ebp
80105d0d:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105d10:	8b 45 08             	mov    0x8(%ebp),%eax
80105d13:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
80105d16:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105d1a:	7f 05                	jg     80105d21 <safestrcpy+0x17>
    return os;
80105d1c:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105d1f:	eb 35                	jmp    80105d56 <safestrcpy+0x4c>
  while(--n > 0 && (*s++ = *t++) != 0)
80105d21:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105d25:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105d29:	7e 22                	jle    80105d4d <safestrcpy+0x43>
80105d2b:	8b 45 0c             	mov    0xc(%ebp),%eax
80105d2e:	0f b6 10             	movzbl (%eax),%edx
80105d31:	8b 45 08             	mov    0x8(%ebp),%eax
80105d34:	88 10                	mov    %dl,(%eax)
80105d36:	8b 45 08             	mov    0x8(%ebp),%eax
80105d39:	0f b6 00             	movzbl (%eax),%eax
80105d3c:	84 c0                	test   %al,%al
80105d3e:	0f 95 c0             	setne  %al
80105d41:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105d45:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
80105d49:	84 c0                	test   %al,%al
80105d4b:	75 d4                	jne    80105d21 <safestrcpy+0x17>
    ;
  *s = 0;
80105d4d:	8b 45 08             	mov    0x8(%ebp),%eax
80105d50:	c6 00 00             	movb   $0x0,(%eax)
  return os;
80105d53:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105d56:	c9                   	leave  
80105d57:	c3                   	ret    

80105d58 <strlen>:

int
strlen(const char *s)
{
80105d58:	55                   	push   %ebp
80105d59:	89 e5                	mov    %esp,%ebp
80105d5b:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
80105d5e:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105d65:	eb 04                	jmp    80105d6b <strlen+0x13>
80105d67:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105d6b:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105d6e:	03 45 08             	add    0x8(%ebp),%eax
80105d71:	0f b6 00             	movzbl (%eax),%eax
80105d74:	84 c0                	test   %al,%al
80105d76:	75 ef                	jne    80105d67 <strlen+0xf>
    ;
  return n;
80105d78:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105d7b:	c9                   	leave  
80105d7c:	c3                   	ret    
80105d7d:	00 00                	add    %al,(%eax)
	...

80105d80 <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
80105d80:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80105d84:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
80105d88:	55                   	push   %ebp
  pushl %ebx
80105d89:	53                   	push   %ebx
  pushl %esi
80105d8a:	56                   	push   %esi
  pushl %edi
80105d8b:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80105d8c:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80105d8e:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
80105d90:	5f                   	pop    %edi
  popl %esi
80105d91:	5e                   	pop    %esi
  popl %ebx
80105d92:	5b                   	pop    %ebx
  popl %ebp
80105d93:	5d                   	pop    %ebp
  ret
80105d94:	c3                   	ret    
80105d95:	00 00                	add    %al,(%eax)
	...

80105d98 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from process p.
int
fetchint(struct proc *p, uint addr, int *ip)
{
80105d98:	55                   	push   %ebp
80105d99:	89 e5                	mov    %esp,%ebp
  if(addr >= p->sz || addr+4 > p->sz)
80105d9b:	8b 45 08             	mov    0x8(%ebp),%eax
80105d9e:	8b 00                	mov    (%eax),%eax
80105da0:	3b 45 0c             	cmp    0xc(%ebp),%eax
80105da3:	76 0f                	jbe    80105db4 <fetchint+0x1c>
80105da5:	8b 45 0c             	mov    0xc(%ebp),%eax
80105da8:	8d 50 04             	lea    0x4(%eax),%edx
80105dab:	8b 45 08             	mov    0x8(%ebp),%eax
80105dae:	8b 00                	mov    (%eax),%eax
80105db0:	39 c2                	cmp    %eax,%edx
80105db2:	76 07                	jbe    80105dbb <fetchint+0x23>
    return -1;
80105db4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105db9:	eb 0f                	jmp    80105dca <fetchint+0x32>
  *ip = *(int*)(addr);
80105dbb:	8b 45 0c             	mov    0xc(%ebp),%eax
80105dbe:	8b 10                	mov    (%eax),%edx
80105dc0:	8b 45 10             	mov    0x10(%ebp),%eax
80105dc3:	89 10                	mov    %edx,(%eax)
  return 0;
80105dc5:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105dca:	5d                   	pop    %ebp
80105dcb:	c3                   	ret    

80105dcc <fetchstr>:
// Fetch the nul-terminated string at addr from process p.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(struct proc *p, uint addr, char **pp)
{
80105dcc:	55                   	push   %ebp
80105dcd:	89 e5                	mov    %esp,%ebp
80105dcf:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= p->sz)
80105dd2:	8b 45 08             	mov    0x8(%ebp),%eax
80105dd5:	8b 00                	mov    (%eax),%eax
80105dd7:	3b 45 0c             	cmp    0xc(%ebp),%eax
80105dda:	77 07                	ja     80105de3 <fetchstr+0x17>
    return -1;
80105ddc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105de1:	eb 45                	jmp    80105e28 <fetchstr+0x5c>
  *pp = (char*)addr;
80105de3:	8b 55 0c             	mov    0xc(%ebp),%edx
80105de6:	8b 45 10             	mov    0x10(%ebp),%eax
80105de9:	89 10                	mov    %edx,(%eax)
  ep = (char*)p->sz;
80105deb:	8b 45 08             	mov    0x8(%ebp),%eax
80105dee:	8b 00                	mov    (%eax),%eax
80105df0:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
80105df3:	8b 45 10             	mov    0x10(%ebp),%eax
80105df6:	8b 00                	mov    (%eax),%eax
80105df8:	89 45 fc             	mov    %eax,-0x4(%ebp)
80105dfb:	eb 1e                	jmp    80105e1b <fetchstr+0x4f>
    if(*s == 0)
80105dfd:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105e00:	0f b6 00             	movzbl (%eax),%eax
80105e03:	84 c0                	test   %al,%al
80105e05:	75 10                	jne    80105e17 <fetchstr+0x4b>
      return s - *pp;
80105e07:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105e0a:	8b 45 10             	mov    0x10(%ebp),%eax
80105e0d:	8b 00                	mov    (%eax),%eax
80105e0f:	89 d1                	mov    %edx,%ecx
80105e11:	29 c1                	sub    %eax,%ecx
80105e13:	89 c8                	mov    %ecx,%eax
80105e15:	eb 11                	jmp    80105e28 <fetchstr+0x5c>

  if(addr >= p->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)p->sz;
  for(s = *pp; s < ep; s++)
80105e17:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105e1b:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105e1e:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105e21:	72 da                	jb     80105dfd <fetchstr+0x31>
    if(*s == 0)
      return s - *pp;
  return -1;
80105e23:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105e28:	c9                   	leave  
80105e29:	c3                   	ret    

80105e2a <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
80105e2a:	55                   	push   %ebp
80105e2b:	89 e5                	mov    %esp,%ebp
80105e2d:	83 ec 0c             	sub    $0xc,%esp
  return fetchint(proc, proc->tf->esp + 4 + 4*n, ip);
80105e30:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105e36:	8b 40 18             	mov    0x18(%eax),%eax
80105e39:	8b 50 44             	mov    0x44(%eax),%edx
80105e3c:	8b 45 08             	mov    0x8(%ebp),%eax
80105e3f:	c1 e0 02             	shl    $0x2,%eax
80105e42:	01 d0                	add    %edx,%eax
80105e44:	8d 48 04             	lea    0x4(%eax),%ecx
80105e47:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105e4d:	8b 55 0c             	mov    0xc(%ebp),%edx
80105e50:	89 54 24 08          	mov    %edx,0x8(%esp)
80105e54:	89 4c 24 04          	mov    %ecx,0x4(%esp)
80105e58:	89 04 24             	mov    %eax,(%esp)
80105e5b:	e8 38 ff ff ff       	call   80105d98 <fetchint>
}
80105e60:	c9                   	leave  
80105e61:	c3                   	ret    

80105e62 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
80105e62:	55                   	push   %ebp
80105e63:	89 e5                	mov    %esp,%ebp
80105e65:	83 ec 18             	sub    $0x18,%esp
  int i;

  if(argint(n, &i) < 0)
80105e68:	8d 45 fc             	lea    -0x4(%ebp),%eax
80105e6b:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e6f:	8b 45 08             	mov    0x8(%ebp),%eax
80105e72:	89 04 24             	mov    %eax,(%esp)
80105e75:	e8 b0 ff ff ff       	call   80105e2a <argint>
80105e7a:	85 c0                	test   %eax,%eax
80105e7c:	79 07                	jns    80105e85 <argptr+0x23>
    return -1;
80105e7e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105e83:	eb 3d                	jmp    80105ec2 <argptr+0x60>

  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
80105e85:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105e88:	89 c2                	mov    %eax,%edx
80105e8a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105e90:	8b 00                	mov    (%eax),%eax
80105e92:	39 c2                	cmp    %eax,%edx
80105e94:	73 16                	jae    80105eac <argptr+0x4a>
80105e96:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105e99:	89 c2                	mov    %eax,%edx
80105e9b:	8b 45 10             	mov    0x10(%ebp),%eax
80105e9e:	01 c2                	add    %eax,%edx
80105ea0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105ea6:	8b 00                	mov    (%eax),%eax
80105ea8:	39 c2                	cmp    %eax,%edx
80105eaa:	76 07                	jbe    80105eb3 <argptr+0x51>
    return -1;
80105eac:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105eb1:	eb 0f                	jmp    80105ec2 <argptr+0x60>
  *pp = (char*)i;
80105eb3:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105eb6:	89 c2                	mov    %eax,%edx
80105eb8:	8b 45 0c             	mov    0xc(%ebp),%eax
80105ebb:	89 10                	mov    %edx,(%eax)
  return 0;
80105ebd:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105ec2:	c9                   	leave  
80105ec3:	c3                   	ret    

80105ec4 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80105ec4:	55                   	push   %ebp
80105ec5:	89 e5                	mov    %esp,%ebp
80105ec7:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  if(argint(n, &addr) < 0)
80105eca:	8d 45 fc             	lea    -0x4(%ebp),%eax
80105ecd:	89 44 24 04          	mov    %eax,0x4(%esp)
80105ed1:	8b 45 08             	mov    0x8(%ebp),%eax
80105ed4:	89 04 24             	mov    %eax,(%esp)
80105ed7:	e8 4e ff ff ff       	call   80105e2a <argint>
80105edc:	85 c0                	test   %eax,%eax
80105ede:	79 07                	jns    80105ee7 <argstr+0x23>
    return -1;
80105ee0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105ee5:	eb 1e                	jmp    80105f05 <argstr+0x41>
  return fetchstr(proc, addr, pp);
80105ee7:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105eea:	89 c2                	mov    %eax,%edx
80105eec:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105ef2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80105ef5:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105ef9:	89 54 24 04          	mov    %edx,0x4(%esp)
80105efd:	89 04 24             	mov    %eax,(%esp)
80105f00:	e8 c7 fe ff ff       	call   80105dcc <fetchstr>
}
80105f05:	c9                   	leave  
80105f06:	c3                   	ret    

80105f07 <syscall>:
[SYS_shmdt]	sys_shmdt,
};

void
syscall(void)
{
80105f07:	55                   	push   %ebp
80105f08:	89 e5                	mov    %esp,%ebp
80105f0a:	53                   	push   %ebx
80105f0b:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->tf->eax;
80105f0e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105f14:	8b 40 18             	mov    0x18(%eax),%eax
80105f17:	8b 40 1c             	mov    0x1c(%eax),%eax
80105f1a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num >= 0 && num < SYS_open && syscalls[num]) {
80105f1d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105f21:	78 2e                	js     80105f51 <syscall+0x4a>
80105f23:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
80105f27:	7f 28                	jg     80105f51 <syscall+0x4a>
80105f29:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f2c:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
80105f33:	85 c0                	test   %eax,%eax
80105f35:	74 1a                	je     80105f51 <syscall+0x4a>
    proc->tf->eax = syscalls[num]();
80105f37:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105f3d:	8b 58 18             	mov    0x18(%eax),%ebx
80105f40:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f43:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
80105f4a:	ff d0                	call   *%eax
80105f4c:	89 43 1c             	mov    %eax,0x1c(%ebx)
80105f4f:	eb 73                	jmp    80105fc4 <syscall+0xbd>
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
80105f51:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
80105f55:	7e 30                	jle    80105f87 <syscall+0x80>
80105f57:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f5a:	83 f8 1e             	cmp    $0x1e,%eax
80105f5d:	77 28                	ja     80105f87 <syscall+0x80>
80105f5f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f62:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
80105f69:	85 c0                	test   %eax,%eax
80105f6b:	74 1a                	je     80105f87 <syscall+0x80>
    proc->tf->eax = syscalls[num]();
80105f6d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105f73:	8b 58 18             	mov    0x18(%eax),%ebx
80105f76:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f79:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
80105f80:	ff d0                	call   *%eax
80105f82:	89 43 1c             	mov    %eax,0x1c(%ebx)
80105f85:	eb 3d                	jmp    80105fc4 <syscall+0xbd>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
80105f87:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105f8d:	8d 48 6c             	lea    0x6c(%eax),%ecx
80105f90:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  if(num >= 0 && num < SYS_open && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
80105f96:	8b 40 10             	mov    0x10(%eax),%eax
80105f99:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105f9c:	89 54 24 0c          	mov    %edx,0xc(%esp)
80105fa0:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105fa4:	89 44 24 04          	mov    %eax,0x4(%esp)
80105fa8:	c7 04 24 57 98 10 80 	movl   $0x80109857,(%esp)
80105faf:	e8 ed a3 ff ff       	call   801003a1 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
80105fb4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105fba:	8b 40 18             	mov    0x18(%eax),%eax
80105fbd:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
80105fc4:	83 c4 24             	add    $0x24,%esp
80105fc7:	5b                   	pop    %ebx
80105fc8:	5d                   	pop    %ebp
80105fc9:	c3                   	ret    
	...

80105fcc <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
80105fcc:	55                   	push   %ebp
80105fcd:	89 e5                	mov    %esp,%ebp
80105fcf:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
80105fd2:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105fd5:	89 44 24 04          	mov    %eax,0x4(%esp)
80105fd9:	8b 45 08             	mov    0x8(%ebp),%eax
80105fdc:	89 04 24             	mov    %eax,(%esp)
80105fdf:	e8 46 fe ff ff       	call   80105e2a <argint>
80105fe4:	85 c0                	test   %eax,%eax
80105fe6:	79 07                	jns    80105fef <argfd+0x23>
    return -1;
80105fe8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105fed:	eb 50                	jmp    8010603f <argfd+0x73>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
80105fef:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ff2:	85 c0                	test   %eax,%eax
80105ff4:	78 21                	js     80106017 <argfd+0x4b>
80105ff6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ff9:	83 f8 0f             	cmp    $0xf,%eax
80105ffc:	7f 19                	jg     80106017 <argfd+0x4b>
80105ffe:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106004:	8b 55 f0             	mov    -0x10(%ebp),%edx
80106007:	83 c2 08             	add    $0x8,%edx
8010600a:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010600e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106011:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106015:	75 07                	jne    8010601e <argfd+0x52>
    return -1;
80106017:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010601c:	eb 21                	jmp    8010603f <argfd+0x73>
  if(pfd)
8010601e:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80106022:	74 08                	je     8010602c <argfd+0x60>
    *pfd = fd;
80106024:	8b 55 f0             	mov    -0x10(%ebp),%edx
80106027:	8b 45 0c             	mov    0xc(%ebp),%eax
8010602a:	89 10                	mov    %edx,(%eax)
  if(pf)
8010602c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80106030:	74 08                	je     8010603a <argfd+0x6e>
    *pf = f;
80106032:	8b 45 10             	mov    0x10(%ebp),%eax
80106035:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106038:	89 10                	mov    %edx,(%eax)
  return 0;
8010603a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010603f:	c9                   	leave  
80106040:	c3                   	ret    

80106041 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
80106041:	55                   	push   %ebp
80106042:	89 e5                	mov    %esp,%ebp
80106044:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80106047:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
8010604e:	eb 30                	jmp    80106080 <fdalloc+0x3f>
    if(proc->ofile[fd] == 0){
80106050:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106056:	8b 55 fc             	mov    -0x4(%ebp),%edx
80106059:	83 c2 08             	add    $0x8,%edx
8010605c:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80106060:	85 c0                	test   %eax,%eax
80106062:	75 18                	jne    8010607c <fdalloc+0x3b>
      proc->ofile[fd] = f;
80106064:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010606a:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010606d:	8d 4a 08             	lea    0x8(%edx),%ecx
80106070:	8b 55 08             	mov    0x8(%ebp),%edx
80106073:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
80106077:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010607a:	eb 0f                	jmp    8010608b <fdalloc+0x4a>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
8010607c:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80106080:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
80106084:	7e ca                	jle    80106050 <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
80106086:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010608b:	c9                   	leave  
8010608c:	c3                   	ret    

8010608d <sys_dup>:

int
sys_dup(void)
{
8010608d:	55                   	push   %ebp
8010608e:	89 e5                	mov    %esp,%ebp
80106090:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
80106093:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106096:	89 44 24 08          	mov    %eax,0x8(%esp)
8010609a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801060a1:	00 
801060a2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801060a9:	e8 1e ff ff ff       	call   80105fcc <argfd>
801060ae:	85 c0                	test   %eax,%eax
801060b0:	79 07                	jns    801060b9 <sys_dup+0x2c>
    return -1;
801060b2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801060b7:	eb 29                	jmp    801060e2 <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
801060b9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801060bc:	89 04 24             	mov    %eax,(%esp)
801060bf:	e8 7d ff ff ff       	call   80106041 <fdalloc>
801060c4:	89 45 f4             	mov    %eax,-0xc(%ebp)
801060c7:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801060cb:	79 07                	jns    801060d4 <sys_dup+0x47>
    return -1;
801060cd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801060d2:	eb 0e                	jmp    801060e2 <sys_dup+0x55>
  filedup(f);
801060d4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801060d7:	89 04 24             	mov    %eax,(%esp)
801060da:	e8 9d ae ff ff       	call   80100f7c <filedup>
  return fd;
801060df:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801060e2:	c9                   	leave  
801060e3:	c3                   	ret    

801060e4 <sys_read>:

int
sys_read(void)
{
801060e4:	55                   	push   %ebp
801060e5:	89 e5                	mov    %esp,%ebp
801060e7:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801060ea:	8d 45 f4             	lea    -0xc(%ebp),%eax
801060ed:	89 44 24 08          	mov    %eax,0x8(%esp)
801060f1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801060f8:	00 
801060f9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106100:	e8 c7 fe ff ff       	call   80105fcc <argfd>
80106105:	85 c0                	test   %eax,%eax
80106107:	78 35                	js     8010613e <sys_read+0x5a>
80106109:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010610c:	89 44 24 04          	mov    %eax,0x4(%esp)
80106110:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80106117:	e8 0e fd ff ff       	call   80105e2a <argint>
8010611c:	85 c0                	test   %eax,%eax
8010611e:	78 1e                	js     8010613e <sys_read+0x5a>
80106120:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106123:	89 44 24 08          	mov    %eax,0x8(%esp)
80106127:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010612a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010612e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106135:	e8 28 fd ff ff       	call   80105e62 <argptr>
8010613a:	85 c0                	test   %eax,%eax
8010613c:	79 07                	jns    80106145 <sys_read+0x61>
    return -1;
8010613e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106143:	eb 19                	jmp    8010615e <sys_read+0x7a>
  return fileread(f, p, n);
80106145:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80106148:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010614b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010614e:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106152:	89 54 24 04          	mov    %edx,0x4(%esp)
80106156:	89 04 24             	mov    %eax,(%esp)
80106159:	e8 8b af ff ff       	call   801010e9 <fileread>
}
8010615e:	c9                   	leave  
8010615f:	c3                   	ret    

80106160 <sys_write>:

int
sys_write(void)
{
80106160:	55                   	push   %ebp
80106161:	89 e5                	mov    %esp,%ebp
80106163:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80106166:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106169:	89 44 24 08          	mov    %eax,0x8(%esp)
8010616d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106174:	00 
80106175:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010617c:	e8 4b fe ff ff       	call   80105fcc <argfd>
80106181:	85 c0                	test   %eax,%eax
80106183:	78 35                	js     801061ba <sys_write+0x5a>
80106185:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106188:	89 44 24 04          	mov    %eax,0x4(%esp)
8010618c:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80106193:	e8 92 fc ff ff       	call   80105e2a <argint>
80106198:	85 c0                	test   %eax,%eax
8010619a:	78 1e                	js     801061ba <sys_write+0x5a>
8010619c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010619f:	89 44 24 08          	mov    %eax,0x8(%esp)
801061a3:	8d 45 ec             	lea    -0x14(%ebp),%eax
801061a6:	89 44 24 04          	mov    %eax,0x4(%esp)
801061aa:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801061b1:	e8 ac fc ff ff       	call   80105e62 <argptr>
801061b6:	85 c0                	test   %eax,%eax
801061b8:	79 07                	jns    801061c1 <sys_write+0x61>
    return -1;
801061ba:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061bf:	eb 19                	jmp    801061da <sys_write+0x7a>
  return filewrite(f, p, n);
801061c1:	8b 4d f0             	mov    -0x10(%ebp),%ecx
801061c4:	8b 55 ec             	mov    -0x14(%ebp),%edx
801061c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061ca:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801061ce:	89 54 24 04          	mov    %edx,0x4(%esp)
801061d2:	89 04 24             	mov    %eax,(%esp)
801061d5:	e8 cb af ff ff       	call   801011a5 <filewrite>
}
801061da:	c9                   	leave  
801061db:	c3                   	ret    

801061dc <sys_close>:

int
sys_close(void)
{
801061dc:	55                   	push   %ebp
801061dd:	89 e5                	mov    %esp,%ebp
801061df:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
801061e2:	8d 45 f0             	lea    -0x10(%ebp),%eax
801061e5:	89 44 24 08          	mov    %eax,0x8(%esp)
801061e9:	8d 45 f4             	lea    -0xc(%ebp),%eax
801061ec:	89 44 24 04          	mov    %eax,0x4(%esp)
801061f0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801061f7:	e8 d0 fd ff ff       	call   80105fcc <argfd>
801061fc:	85 c0                	test   %eax,%eax
801061fe:	79 07                	jns    80106207 <sys_close+0x2b>
    return -1;
80106200:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106205:	eb 24                	jmp    8010622b <sys_close+0x4f>
  proc->ofile[fd] = 0;
80106207:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010620d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106210:	83 c2 08             	add    $0x8,%edx
80106213:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
8010621a:	00 
  fileclose(f);
8010621b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010621e:	89 04 24             	mov    %eax,(%esp)
80106221:	e8 9e ad ff ff       	call   80100fc4 <fileclose>
  return 0;
80106226:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010622b:	c9                   	leave  
8010622c:	c3                   	ret    

8010622d <sys_fstat>:

int
sys_fstat(void)
{
8010622d:	55                   	push   %ebp
8010622e:	89 e5                	mov    %esp,%ebp
80106230:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
80106233:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106236:	89 44 24 08          	mov    %eax,0x8(%esp)
8010623a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106241:	00 
80106242:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106249:	e8 7e fd ff ff       	call   80105fcc <argfd>
8010624e:	85 c0                	test   %eax,%eax
80106250:	78 1f                	js     80106271 <sys_fstat+0x44>
80106252:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80106259:	00 
8010625a:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010625d:	89 44 24 04          	mov    %eax,0x4(%esp)
80106261:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106268:	e8 f5 fb ff ff       	call   80105e62 <argptr>
8010626d:	85 c0                	test   %eax,%eax
8010626f:	79 07                	jns    80106278 <sys_fstat+0x4b>
    return -1;
80106271:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106276:	eb 12                	jmp    8010628a <sys_fstat+0x5d>
  return filestat(f, st);
80106278:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010627b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010627e:	89 54 24 04          	mov    %edx,0x4(%esp)
80106282:	89 04 24             	mov    %eax,(%esp)
80106285:	e8 10 ae ff ff       	call   8010109a <filestat>
}
8010628a:	c9                   	leave  
8010628b:	c3                   	ret    

8010628c <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
8010628c:	55                   	push   %ebp
8010628d:	89 e5                	mov    %esp,%ebp
8010628f:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
80106292:	8d 45 d8             	lea    -0x28(%ebp),%eax
80106295:	89 44 24 04          	mov    %eax,0x4(%esp)
80106299:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801062a0:	e8 1f fc ff ff       	call   80105ec4 <argstr>
801062a5:	85 c0                	test   %eax,%eax
801062a7:	78 17                	js     801062c0 <sys_link+0x34>
801062a9:	8d 45 dc             	lea    -0x24(%ebp),%eax
801062ac:	89 44 24 04          	mov    %eax,0x4(%esp)
801062b0:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801062b7:	e8 08 fc ff ff       	call   80105ec4 <argstr>
801062bc:	85 c0                	test   %eax,%eax
801062be:	79 0a                	jns    801062ca <sys_link+0x3e>
    return -1;
801062c0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801062c5:	e9 3c 01 00 00       	jmp    80106406 <sys_link+0x17a>
  if((ip = namei(old)) == 0)
801062ca:	8b 45 d8             	mov    -0x28(%ebp),%eax
801062cd:	89 04 24             	mov    %eax,(%esp)
801062d0:	e8 35 c1 ff ff       	call   8010240a <namei>
801062d5:	89 45 f4             	mov    %eax,-0xc(%ebp)
801062d8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801062dc:	75 0a                	jne    801062e8 <sys_link+0x5c>
    return -1;
801062de:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801062e3:	e9 1e 01 00 00       	jmp    80106406 <sys_link+0x17a>

  begin_trans();
801062e8:	e8 c4 d4 ff ff       	call   801037b1 <begin_trans>

  ilock(ip);
801062ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062f0:	89 04 24             	mov    %eax,(%esp)
801062f3:	e8 70 b5 ff ff       	call   80101868 <ilock>
  if(ip->type == T_DIR){
801062f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062fb:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801062ff:	66 83 f8 01          	cmp    $0x1,%ax
80106303:	75 1a                	jne    8010631f <sys_link+0x93>
    iunlockput(ip);
80106305:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106308:	89 04 24             	mov    %eax,(%esp)
8010630b:	e8 dc b7 ff ff       	call   80101aec <iunlockput>
    commit_trans();
80106310:	e8 e5 d4 ff ff       	call   801037fa <commit_trans>
    return -1;
80106315:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010631a:	e9 e7 00 00 00       	jmp    80106406 <sys_link+0x17a>
  }

  ip->nlink++;
8010631f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106322:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106326:	8d 50 01             	lea    0x1(%eax),%edx
80106329:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010632c:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80106330:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106333:	89 04 24             	mov    %eax,(%esp)
80106336:	e8 71 b3 ff ff       	call   801016ac <iupdate>
  iunlock(ip);
8010633b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010633e:	89 04 24             	mov    %eax,(%esp)
80106341:	e8 70 b6 ff ff       	call   801019b6 <iunlock>

  if((dp = nameiparent(new, name)) == 0)
80106346:	8b 45 dc             	mov    -0x24(%ebp),%eax
80106349:	8d 55 e2             	lea    -0x1e(%ebp),%edx
8010634c:	89 54 24 04          	mov    %edx,0x4(%esp)
80106350:	89 04 24             	mov    %eax,(%esp)
80106353:	e8 d4 c0 ff ff       	call   8010242c <nameiparent>
80106358:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010635b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010635f:	74 68                	je     801063c9 <sys_link+0x13d>
    goto bad;
  ilock(dp);
80106361:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106364:	89 04 24             	mov    %eax,(%esp)
80106367:	e8 fc b4 ff ff       	call   80101868 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
8010636c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010636f:	8b 10                	mov    (%eax),%edx
80106371:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106374:	8b 00                	mov    (%eax),%eax
80106376:	39 c2                	cmp    %eax,%edx
80106378:	75 20                	jne    8010639a <sys_link+0x10e>
8010637a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010637d:	8b 40 04             	mov    0x4(%eax),%eax
80106380:	89 44 24 08          	mov    %eax,0x8(%esp)
80106384:	8d 45 e2             	lea    -0x1e(%ebp),%eax
80106387:	89 44 24 04          	mov    %eax,0x4(%esp)
8010638b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010638e:	89 04 24             	mov    %eax,(%esp)
80106391:	e8 b3 bd ff ff       	call   80102149 <dirlink>
80106396:	85 c0                	test   %eax,%eax
80106398:	79 0d                	jns    801063a7 <sys_link+0x11b>
    iunlockput(dp);
8010639a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010639d:	89 04 24             	mov    %eax,(%esp)
801063a0:	e8 47 b7 ff ff       	call   80101aec <iunlockput>
    goto bad;
801063a5:	eb 23                	jmp    801063ca <sys_link+0x13e>
  }
  iunlockput(dp);
801063a7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801063aa:	89 04 24             	mov    %eax,(%esp)
801063ad:	e8 3a b7 ff ff       	call   80101aec <iunlockput>
  iput(ip);
801063b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063b5:	89 04 24             	mov    %eax,(%esp)
801063b8:	e8 5e b6 ff ff       	call   80101a1b <iput>

  commit_trans();
801063bd:	e8 38 d4 ff ff       	call   801037fa <commit_trans>

  return 0;
801063c2:	b8 00 00 00 00       	mov    $0x0,%eax
801063c7:	eb 3d                	jmp    80106406 <sys_link+0x17a>
  ip->nlink++;
  iupdate(ip);
  iunlock(ip);

  if((dp = nameiparent(new, name)) == 0)
    goto bad;
801063c9:	90                   	nop
  commit_trans();

  return 0;

bad:
  ilock(ip);
801063ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063cd:	89 04 24             	mov    %eax,(%esp)
801063d0:	e8 93 b4 ff ff       	call   80101868 <ilock>
  ip->nlink--;
801063d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063d8:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801063dc:	8d 50 ff             	lea    -0x1(%eax),%edx
801063df:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063e2:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801063e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063e9:	89 04 24             	mov    %eax,(%esp)
801063ec:	e8 bb b2 ff ff       	call   801016ac <iupdate>
  iunlockput(ip);
801063f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063f4:	89 04 24             	mov    %eax,(%esp)
801063f7:	e8 f0 b6 ff ff       	call   80101aec <iunlockput>
  commit_trans();
801063fc:	e8 f9 d3 ff ff       	call   801037fa <commit_trans>
  return -1;
80106401:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80106406:	c9                   	leave  
80106407:	c3                   	ret    

80106408 <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
80106408:	55                   	push   %ebp
80106409:	89 e5                	mov    %esp,%ebp
8010640b:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
8010640e:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
80106415:	eb 4b                	jmp    80106462 <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80106417:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010641a:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80106421:	00 
80106422:	89 44 24 08          	mov    %eax,0x8(%esp)
80106426:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106429:	89 44 24 04          	mov    %eax,0x4(%esp)
8010642d:	8b 45 08             	mov    0x8(%ebp),%eax
80106430:	89 04 24             	mov    %eax,(%esp)
80106433:	e8 26 b9 ff ff       	call   80101d5e <readi>
80106438:	83 f8 10             	cmp    $0x10,%eax
8010643b:	74 0c                	je     80106449 <isdirempty+0x41>
      panic("isdirempty: readi");
8010643d:	c7 04 24 73 98 10 80 	movl   $0x80109873,(%esp)
80106444:	e8 f4 a0 ff ff       	call   8010053d <panic>
    if(de.inum != 0)
80106449:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
8010644d:	66 85 c0             	test   %ax,%ax
80106450:	74 07                	je     80106459 <isdirempty+0x51>
      return 0;
80106452:	b8 00 00 00 00       	mov    $0x0,%eax
80106457:	eb 1b                	jmp    80106474 <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80106459:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010645c:	83 c0 10             	add    $0x10,%eax
8010645f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106462:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106465:	8b 45 08             	mov    0x8(%ebp),%eax
80106468:	8b 40 18             	mov    0x18(%eax),%eax
8010646b:	39 c2                	cmp    %eax,%edx
8010646d:	72 a8                	jb     80106417 <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
8010646f:	b8 01 00 00 00       	mov    $0x1,%eax
}
80106474:	c9                   	leave  
80106475:	c3                   	ret    

80106476 <unlink>:


int
unlink(char* path)
{
80106476:	55                   	push   %ebp
80106477:	89 e5                	mov    %esp,%ebp
80106479:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ];
  uint off;

  if((dp = nameiparent(path, name)) == 0)
8010647c:	8d 45 d2             	lea    -0x2e(%ebp),%eax
8010647f:	89 44 24 04          	mov    %eax,0x4(%esp)
80106483:	8b 45 08             	mov    0x8(%ebp),%eax
80106486:	89 04 24             	mov    %eax,(%esp)
80106489:	e8 9e bf ff ff       	call   8010242c <nameiparent>
8010648e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106491:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106495:	75 0a                	jne    801064a1 <unlink+0x2b>
    return -1;
80106497:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010649c:	e9 85 01 00 00       	jmp    80106626 <unlink+0x1b0>

  begin_trans();
801064a1:	e8 0b d3 ff ff       	call   801037b1 <begin_trans>

  ilock(dp);
801064a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064a9:	89 04 24             	mov    %eax,(%esp)
801064ac:	e8 b7 b3 ff ff       	call   80101868 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
801064b1:	c7 44 24 04 85 98 10 	movl   $0x80109885,0x4(%esp)
801064b8:	80 
801064b9:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801064bc:	89 04 24             	mov    %eax,(%esp)
801064bf:	e8 9b bb ff ff       	call   8010205f <namecmp>
801064c4:	85 c0                	test   %eax,%eax
801064c6:	0f 84 45 01 00 00    	je     80106611 <unlink+0x19b>
801064cc:	c7 44 24 04 87 98 10 	movl   $0x80109887,0x4(%esp)
801064d3:	80 
801064d4:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801064d7:	89 04 24             	mov    %eax,(%esp)
801064da:	e8 80 bb ff ff       	call   8010205f <namecmp>
801064df:	85 c0                	test   %eax,%eax
801064e1:	0f 84 2a 01 00 00    	je     80106611 <unlink+0x19b>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
801064e7:	8d 45 cc             	lea    -0x34(%ebp),%eax
801064ea:	89 44 24 08          	mov    %eax,0x8(%esp)
801064ee:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801064f1:	89 44 24 04          	mov    %eax,0x4(%esp)
801064f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064f8:	89 04 24             	mov    %eax,(%esp)
801064fb:	e8 81 bb ff ff       	call   80102081 <dirlookup>
80106500:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106503:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106507:	0f 84 03 01 00 00    	je     80106610 <unlink+0x19a>
    goto bad;
  ilock(ip);
8010650d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106510:	89 04 24             	mov    %eax,(%esp)
80106513:	e8 50 b3 ff ff       	call   80101868 <ilock>

  if(ip->nlink < 1)
80106518:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010651b:	0f b7 40 16          	movzwl 0x16(%eax),%eax
8010651f:	66 85 c0             	test   %ax,%ax
80106522:	7f 0c                	jg     80106530 <unlink+0xba>
    panic("unlink: nlink < 1");
80106524:	c7 04 24 8a 98 10 80 	movl   $0x8010988a,(%esp)
8010652b:	e8 0d a0 ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80106530:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106533:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106537:	66 83 f8 01          	cmp    $0x1,%ax
8010653b:	75 1f                	jne    8010655c <unlink+0xe6>
8010653d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106540:	89 04 24             	mov    %eax,(%esp)
80106543:	e8 c0 fe ff ff       	call   80106408 <isdirempty>
80106548:	85 c0                	test   %eax,%eax
8010654a:	75 10                	jne    8010655c <unlink+0xe6>
    iunlockput(ip);
8010654c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010654f:	89 04 24             	mov    %eax,(%esp)
80106552:	e8 95 b5 ff ff       	call   80101aec <iunlockput>
    goto bad;
80106557:	e9 b5 00 00 00       	jmp    80106611 <unlink+0x19b>
  }

  memset(&de, 0, sizeof(de));
8010655c:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80106563:	00 
80106564:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010656b:	00 
8010656c:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010656f:	89 04 24             	mov    %eax,(%esp)
80106572:	e8 63 f5 ff ff       	call   80105ada <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80106577:	8b 45 cc             	mov    -0x34(%ebp),%eax
8010657a:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80106581:	00 
80106582:	89 44 24 08          	mov    %eax,0x8(%esp)
80106586:	8d 45 e0             	lea    -0x20(%ebp),%eax
80106589:	89 44 24 04          	mov    %eax,0x4(%esp)
8010658d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106590:	89 04 24             	mov    %eax,(%esp)
80106593:	e8 31 b9 ff ff       	call   80101ec9 <writei>
80106598:	83 f8 10             	cmp    $0x10,%eax
8010659b:	74 0c                	je     801065a9 <unlink+0x133>
    panic("unlink: writei");
8010659d:	c7 04 24 9c 98 10 80 	movl   $0x8010989c,(%esp)
801065a4:	e8 94 9f ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR){
801065a9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065ac:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801065b0:	66 83 f8 01          	cmp    $0x1,%ax
801065b4:	75 1c                	jne    801065d2 <unlink+0x15c>
    dp->nlink--;
801065b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065b9:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801065bd:	8d 50 ff             	lea    -0x1(%eax),%edx
801065c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065c3:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
801065c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065ca:	89 04 24             	mov    %eax,(%esp)
801065cd:	e8 da b0 ff ff       	call   801016ac <iupdate>
  }
  iunlockput(dp);
801065d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065d5:	89 04 24             	mov    %eax,(%esp)
801065d8:	e8 0f b5 ff ff       	call   80101aec <iunlockput>

  ip->nlink--;
801065dd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065e0:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801065e4:	8d 50 ff             	lea    -0x1(%eax),%edx
801065e7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065ea:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801065ee:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065f1:	89 04 24             	mov    %eax,(%esp)
801065f4:	e8 b3 b0 ff ff       	call   801016ac <iupdate>
  iunlockput(ip);
801065f9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065fc:	89 04 24             	mov    %eax,(%esp)
801065ff:	e8 e8 b4 ff ff       	call   80101aec <iunlockput>

  commit_trans();
80106604:	e8 f1 d1 ff ff       	call   801037fa <commit_trans>

  return 0;
80106609:	b8 00 00 00 00       	mov    $0x0,%eax
8010660e:	eb 16                	jmp    80106626 <unlink+0x1b0>
  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    goto bad;
80106610:	90                   	nop
  commit_trans();

  return 0;

bad:
  iunlockput(dp);
80106611:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106614:	89 04 24             	mov    %eax,(%esp)
80106617:	e8 d0 b4 ff ff       	call   80101aec <iunlockput>
  commit_trans();
8010661c:	e8 d9 d1 ff ff       	call   801037fa <commit_trans>
  return -1;
80106621:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80106626:	c9                   	leave  
80106627:	c3                   	ret    

80106628 <sys_unlink>:


//PAGEBREAK!
int
sys_unlink(void)
{
80106628:	55                   	push   %ebp
80106629:	89 e5                	mov    %esp,%ebp
8010662b:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
8010662e:	8d 45 cc             	lea    -0x34(%ebp),%eax
80106631:	89 44 24 04          	mov    %eax,0x4(%esp)
80106635:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010663c:	e8 83 f8 ff ff       	call   80105ec4 <argstr>
80106641:	85 c0                	test   %eax,%eax
80106643:	79 0a                	jns    8010664f <sys_unlink+0x27>
    return -1;
80106645:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010664a:	e9 aa 01 00 00       	jmp    801067f9 <sys_unlink+0x1d1>
  if((dp = nameiparent(path, name)) == 0)
8010664f:	8b 45 cc             	mov    -0x34(%ebp),%eax
80106652:	8d 55 d2             	lea    -0x2e(%ebp),%edx
80106655:	89 54 24 04          	mov    %edx,0x4(%esp)
80106659:	89 04 24             	mov    %eax,(%esp)
8010665c:	e8 cb bd ff ff       	call   8010242c <nameiparent>
80106661:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106664:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106668:	75 0a                	jne    80106674 <sys_unlink+0x4c>
    return -1;
8010666a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010666f:	e9 85 01 00 00       	jmp    801067f9 <sys_unlink+0x1d1>

  begin_trans();
80106674:	e8 38 d1 ff ff       	call   801037b1 <begin_trans>

  ilock(dp);
80106679:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010667c:	89 04 24             	mov    %eax,(%esp)
8010667f:	e8 e4 b1 ff ff       	call   80101868 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80106684:	c7 44 24 04 85 98 10 	movl   $0x80109885,0x4(%esp)
8010668b:	80 
8010668c:	8d 45 d2             	lea    -0x2e(%ebp),%eax
8010668f:	89 04 24             	mov    %eax,(%esp)
80106692:	e8 c8 b9 ff ff       	call   8010205f <namecmp>
80106697:	85 c0                	test   %eax,%eax
80106699:	0f 84 45 01 00 00    	je     801067e4 <sys_unlink+0x1bc>
8010669f:	c7 44 24 04 87 98 10 	movl   $0x80109887,0x4(%esp)
801066a6:	80 
801066a7:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801066aa:	89 04 24             	mov    %eax,(%esp)
801066ad:	e8 ad b9 ff ff       	call   8010205f <namecmp>
801066b2:	85 c0                	test   %eax,%eax
801066b4:	0f 84 2a 01 00 00    	je     801067e4 <sys_unlink+0x1bc>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
801066ba:	8d 45 c8             	lea    -0x38(%ebp),%eax
801066bd:	89 44 24 08          	mov    %eax,0x8(%esp)
801066c1:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801066c4:	89 44 24 04          	mov    %eax,0x4(%esp)
801066c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066cb:	89 04 24             	mov    %eax,(%esp)
801066ce:	e8 ae b9 ff ff       	call   80102081 <dirlookup>
801066d3:	89 45 f0             	mov    %eax,-0x10(%ebp)
801066d6:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801066da:	0f 84 03 01 00 00    	je     801067e3 <sys_unlink+0x1bb>
    goto bad;
  ilock(ip);
801066e0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801066e3:	89 04 24             	mov    %eax,(%esp)
801066e6:	e8 7d b1 ff ff       	call   80101868 <ilock>

  if(ip->nlink < 1)
801066eb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801066ee:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801066f2:	66 85 c0             	test   %ax,%ax
801066f5:	7f 0c                	jg     80106703 <sys_unlink+0xdb>
    panic("unlink: nlink < 1");
801066f7:	c7 04 24 8a 98 10 80 	movl   $0x8010988a,(%esp)
801066fe:	e8 3a 9e ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80106703:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106706:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010670a:	66 83 f8 01          	cmp    $0x1,%ax
8010670e:	75 1f                	jne    8010672f <sys_unlink+0x107>
80106710:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106713:	89 04 24             	mov    %eax,(%esp)
80106716:	e8 ed fc ff ff       	call   80106408 <isdirempty>
8010671b:	85 c0                	test   %eax,%eax
8010671d:	75 10                	jne    8010672f <sys_unlink+0x107>
    iunlockput(ip);
8010671f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106722:	89 04 24             	mov    %eax,(%esp)
80106725:	e8 c2 b3 ff ff       	call   80101aec <iunlockput>
    goto bad;
8010672a:	e9 b5 00 00 00       	jmp    801067e4 <sys_unlink+0x1bc>
  }

  memset(&de, 0, sizeof(de));
8010672f:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80106736:	00 
80106737:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010673e:	00 
8010673f:	8d 45 e0             	lea    -0x20(%ebp),%eax
80106742:	89 04 24             	mov    %eax,(%esp)
80106745:	e8 90 f3 ff ff       	call   80105ada <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010674a:	8b 45 c8             	mov    -0x38(%ebp),%eax
8010674d:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80106754:	00 
80106755:	89 44 24 08          	mov    %eax,0x8(%esp)
80106759:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010675c:	89 44 24 04          	mov    %eax,0x4(%esp)
80106760:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106763:	89 04 24             	mov    %eax,(%esp)
80106766:	e8 5e b7 ff ff       	call   80101ec9 <writei>
8010676b:	83 f8 10             	cmp    $0x10,%eax
8010676e:	74 0c                	je     8010677c <sys_unlink+0x154>
    panic("unlink: writei");
80106770:	c7 04 24 9c 98 10 80 	movl   $0x8010989c,(%esp)
80106777:	e8 c1 9d ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR){
8010677c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010677f:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106783:	66 83 f8 01          	cmp    $0x1,%ax
80106787:	75 1c                	jne    801067a5 <sys_unlink+0x17d>
    dp->nlink--;
80106789:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010678c:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106790:	8d 50 ff             	lea    -0x1(%eax),%edx
80106793:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106796:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
8010679a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010679d:	89 04 24             	mov    %eax,(%esp)
801067a0:	e8 07 af ff ff       	call   801016ac <iupdate>
  }
  iunlockput(dp);
801067a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067a8:	89 04 24             	mov    %eax,(%esp)
801067ab:	e8 3c b3 ff ff       	call   80101aec <iunlockput>

  ip->nlink--;
801067b0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801067b3:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801067b7:	8d 50 ff             	lea    -0x1(%eax),%edx
801067ba:	8b 45 f0             	mov    -0x10(%ebp),%eax
801067bd:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801067c1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801067c4:	89 04 24             	mov    %eax,(%esp)
801067c7:	e8 e0 ae ff ff       	call   801016ac <iupdate>
  iunlockput(ip);
801067cc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801067cf:	89 04 24             	mov    %eax,(%esp)
801067d2:	e8 15 b3 ff ff       	call   80101aec <iunlockput>

  commit_trans();
801067d7:	e8 1e d0 ff ff       	call   801037fa <commit_trans>

  return 0;
801067dc:	b8 00 00 00 00       	mov    $0x0,%eax
801067e1:	eb 16                	jmp    801067f9 <sys_unlink+0x1d1>
  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    goto bad;
801067e3:	90                   	nop
  commit_trans();

  return 0;

bad:
  iunlockput(dp);
801067e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067e7:	89 04 24             	mov    %eax,(%esp)
801067ea:	e8 fd b2 ff ff       	call   80101aec <iunlockput>
  commit_trans();
801067ef:	e8 06 d0 ff ff       	call   801037fa <commit_trans>
  return -1;
801067f4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801067f9:	c9                   	leave  
801067fa:	c3                   	ret    

801067fb <create>:

static struct inode*
create(char *path, short type, short major, short minor)
{
801067fb:	55                   	push   %ebp
801067fc:	89 e5                	mov    %esp,%ebp
801067fe:	83 ec 48             	sub    $0x48,%esp
80106801:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80106804:	8b 55 10             	mov    0x10(%ebp),%edx
80106807:	8b 45 14             	mov    0x14(%ebp),%eax
8010680a:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
8010680e:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
80106812:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];
  if((dp = nameiparent(path, name)) == 0)
80106816:	8d 45 de             	lea    -0x22(%ebp),%eax
80106819:	89 44 24 04          	mov    %eax,0x4(%esp)
8010681d:	8b 45 08             	mov    0x8(%ebp),%eax
80106820:	89 04 24             	mov    %eax,(%esp)
80106823:	e8 04 bc ff ff       	call   8010242c <nameiparent>
80106828:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010682b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010682f:	75 0a                	jne    8010683b <create+0x40>
    return 0;
80106831:	b8 00 00 00 00       	mov    $0x0,%eax
80106836:	e9 7e 01 00 00       	jmp    801069b9 <create+0x1be>
  ilock(dp);
8010683b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010683e:	89 04 24             	mov    %eax,(%esp)
80106841:	e8 22 b0 ff ff       	call   80101868 <ilock>
  if((ip = dirlookup(dp, name, &off)) != 0){
80106846:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106849:	89 44 24 08          	mov    %eax,0x8(%esp)
8010684d:	8d 45 de             	lea    -0x22(%ebp),%eax
80106850:	89 44 24 04          	mov    %eax,0x4(%esp)
80106854:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106857:	89 04 24             	mov    %eax,(%esp)
8010685a:	e8 22 b8 ff ff       	call   80102081 <dirlookup>
8010685f:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106862:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106866:	74 47                	je     801068af <create+0xb4>
    iunlockput(dp);
80106868:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010686b:	89 04 24             	mov    %eax,(%esp)
8010686e:	e8 79 b2 ff ff       	call   80101aec <iunlockput>
    ilock(ip);
80106873:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106876:	89 04 24             	mov    %eax,(%esp)
80106879:	e8 ea af ff ff       	call   80101868 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
8010687e:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
80106883:	75 15                	jne    8010689a <create+0x9f>
80106885:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106888:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010688c:	66 83 f8 02          	cmp    $0x2,%ax
80106890:	75 08                	jne    8010689a <create+0x9f>
      return ip;
80106892:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106895:	e9 1f 01 00 00       	jmp    801069b9 <create+0x1be>
    iunlockput(ip);
8010689a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010689d:	89 04 24             	mov    %eax,(%esp)
801068a0:	e8 47 b2 ff ff       	call   80101aec <iunlockput>
    return 0;
801068a5:	b8 00 00 00 00       	mov    $0x0,%eax
801068aa:	e9 0a 01 00 00       	jmp    801069b9 <create+0x1be>
  }
  if((ip = ialloc(dp->dev, type)) == 0)
801068af:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
801068b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068b6:	8b 00                	mov    (%eax),%eax
801068b8:	89 54 24 04          	mov    %edx,0x4(%esp)
801068bc:	89 04 24             	mov    %eax,(%esp)
801068bf:	e8 0b ad ff ff       	call   801015cf <ialloc>
801068c4:	89 45 f0             	mov    %eax,-0x10(%ebp)
801068c7:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801068cb:	75 0c                	jne    801068d9 <create+0xde>
    panic("create: ialloc");
801068cd:	c7 04 24 ab 98 10 80 	movl   $0x801098ab,(%esp)
801068d4:	e8 64 9c ff ff       	call   8010053d <panic>
  ilock(ip);
801068d9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801068dc:	89 04 24             	mov    %eax,(%esp)
801068df:	e8 84 af ff ff       	call   80101868 <ilock>
  ip->major = major;
801068e4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801068e7:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
801068eb:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
801068ef:	8b 45 f0             	mov    -0x10(%ebp),%eax
801068f2:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
801068f6:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
801068fa:	8b 45 f0             	mov    -0x10(%ebp),%eax
801068fd:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
80106903:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106906:	89 04 24             	mov    %eax,(%esp)
80106909:	e8 9e ad ff ff       	call   801016ac <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
8010690e:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
80106913:	75 6a                	jne    8010697f <create+0x184>
    dp->nlink++;  // for ".."
80106915:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106918:	0f b7 40 16          	movzwl 0x16(%eax),%eax
8010691c:	8d 50 01             	lea    0x1(%eax),%edx
8010691f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106922:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80106926:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106929:	89 04 24             	mov    %eax,(%esp)
8010692c:	e8 7b ad ff ff       	call   801016ac <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80106931:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106934:	8b 40 04             	mov    0x4(%eax),%eax
80106937:	89 44 24 08          	mov    %eax,0x8(%esp)
8010693b:	c7 44 24 04 85 98 10 	movl   $0x80109885,0x4(%esp)
80106942:	80 
80106943:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106946:	89 04 24             	mov    %eax,(%esp)
80106949:	e8 fb b7 ff ff       	call   80102149 <dirlink>
8010694e:	85 c0                	test   %eax,%eax
80106950:	78 21                	js     80106973 <create+0x178>
80106952:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106955:	8b 40 04             	mov    0x4(%eax),%eax
80106958:	89 44 24 08          	mov    %eax,0x8(%esp)
8010695c:	c7 44 24 04 87 98 10 	movl   $0x80109887,0x4(%esp)
80106963:	80 
80106964:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106967:	89 04 24             	mov    %eax,(%esp)
8010696a:	e8 da b7 ff ff       	call   80102149 <dirlink>
8010696f:	85 c0                	test   %eax,%eax
80106971:	79 0c                	jns    8010697f <create+0x184>
      panic("create dots");
80106973:	c7 04 24 ba 98 10 80 	movl   $0x801098ba,(%esp)
8010697a:	e8 be 9b ff ff       	call   8010053d <panic>
  }
  if(dirlink(dp, name, ip->inum) < 0)
8010697f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106982:	8b 40 04             	mov    0x4(%eax),%eax
80106985:	89 44 24 08          	mov    %eax,0x8(%esp)
80106989:	8d 45 de             	lea    -0x22(%ebp),%eax
8010698c:	89 44 24 04          	mov    %eax,0x4(%esp)
80106990:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106993:	89 04 24             	mov    %eax,(%esp)
80106996:	e8 ae b7 ff ff       	call   80102149 <dirlink>
8010699b:	85 c0                	test   %eax,%eax
8010699d:	79 0c                	jns    801069ab <create+0x1b0>
    panic("create: dirlink");
8010699f:	c7 04 24 c6 98 10 80 	movl   $0x801098c6,(%esp)
801069a6:	e8 92 9b ff ff       	call   8010053d <panic>
  iunlockput(dp);
801069ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069ae:	89 04 24             	mov    %eax,(%esp)
801069b1:	e8 36 b1 ff ff       	call   80101aec <iunlockput>

  return ip;
801069b6:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
801069b9:	c9                   	leave  
801069ba:	c3                   	ret    

801069bb <fileopen>:

struct file*
fileopen(char *path, int omode)
{
801069bb:	55                   	push   %ebp
801069bc:	89 e5                	mov    %esp,%ebp
801069be:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  struct inode *ip;

  if(omode & O_CREATE){
801069c1:	8b 45 0c             	mov    0xc(%ebp),%eax
801069c4:	25 00 02 00 00       	and    $0x200,%eax
801069c9:	85 c0                	test   %eax,%eax
801069cb:	74 40                	je     80106a0d <fileopen+0x52>
    begin_trans();
801069cd:	e8 df cd ff ff       	call   801037b1 <begin_trans>
    ip = create(path, T_FILE, 0, 0);
801069d2:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
801069d9:	00 
801069da:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801069e1:	00 
801069e2:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
801069e9:	00 
801069ea:	8b 45 08             	mov    0x8(%ebp),%eax
801069ed:	89 04 24             	mov    %eax,(%esp)
801069f0:	e8 06 fe ff ff       	call   801067fb <create>
801069f5:	89 45 f4             	mov    %eax,-0xc(%ebp)
    commit_trans();
801069f8:	e8 fd cd ff ff       	call   801037fa <commit_trans>
    if(ip == 0)
801069fd:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106a01:	75 5b                	jne    80106a5e <fileopen+0xa3>
      return 0;
80106a03:	b8 00 00 00 00       	mov    $0x0,%eax
80106a08:	e9 f9 00 00 00       	jmp    80106b06 <fileopen+0x14b>
  } else {
    if((ip = namei(path)) == 0)
80106a0d:	8b 45 08             	mov    0x8(%ebp),%eax
80106a10:	89 04 24             	mov    %eax,(%esp)
80106a13:	e8 f2 b9 ff ff       	call   8010240a <namei>
80106a18:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106a1b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106a1f:	75 0a                	jne    80106a2b <fileopen+0x70>
      return 0;
80106a21:	b8 00 00 00 00       	mov    $0x0,%eax
80106a26:	e9 db 00 00 00       	jmp    80106b06 <fileopen+0x14b>
    ilock(ip);
80106a2b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a2e:	89 04 24             	mov    %eax,(%esp)
80106a31:	e8 32 ae ff ff       	call   80101868 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80106a36:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a39:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106a3d:	66 83 f8 01          	cmp    $0x1,%ax
80106a41:	75 1b                	jne    80106a5e <fileopen+0xa3>
80106a43:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80106a47:	74 15                	je     80106a5e <fileopen+0xa3>
      iunlockput(ip);
80106a49:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a4c:	89 04 24             	mov    %eax,(%esp)
80106a4f:	e8 98 b0 ff ff       	call   80101aec <iunlockput>
      return 0;
80106a54:	b8 00 00 00 00       	mov    $0x0,%eax
80106a59:	e9 a8 00 00 00       	jmp    80106b06 <fileopen+0x14b>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80106a5e:	e8 b9 a4 ff ff       	call   80100f1c <filealloc>
80106a63:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106a66:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106a6a:	74 14                	je     80106a80 <fileopen+0xc5>
80106a6c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106a6f:	89 04 24             	mov    %eax,(%esp)
80106a72:	e8 ca f5 ff ff       	call   80106041 <fdalloc>
80106a77:	89 45 ec             	mov    %eax,-0x14(%ebp)
80106a7a:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80106a7e:	79 23                	jns    80106aa3 <fileopen+0xe8>
    if(f)
80106a80:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106a84:	74 0b                	je     80106a91 <fileopen+0xd6>
      fileclose(f);
80106a86:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106a89:	89 04 24             	mov    %eax,(%esp)
80106a8c:	e8 33 a5 ff ff       	call   80100fc4 <fileclose>
    iunlockput(ip);
80106a91:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a94:	89 04 24             	mov    %eax,(%esp)
80106a97:	e8 50 b0 ff ff       	call   80101aec <iunlockput>
    return 0;
80106a9c:	b8 00 00 00 00       	mov    $0x0,%eax
80106aa1:	eb 63                	jmp    80106b06 <fileopen+0x14b>
  }
  iunlock(ip);
80106aa3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106aa6:	89 04 24             	mov    %eax,(%esp)
80106aa9:	e8 08 af ff ff       	call   801019b6 <iunlock>

  f->type = FD_INODE;
80106aae:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ab1:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80106ab7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106aba:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106abd:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
80106ac0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ac3:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80106aca:	8b 45 0c             	mov    0xc(%ebp),%eax
80106acd:	83 e0 01             	and    $0x1,%eax
80106ad0:	85 c0                	test   %eax,%eax
80106ad2:	0f 94 c2             	sete   %dl
80106ad5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ad8:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80106adb:	8b 45 0c             	mov    0xc(%ebp),%eax
80106ade:	83 e0 01             	and    $0x1,%eax
80106ae1:	84 c0                	test   %al,%al
80106ae3:	75 0a                	jne    80106aef <fileopen+0x134>
80106ae5:	8b 45 0c             	mov    0xc(%ebp),%eax
80106ae8:	83 e0 02             	and    $0x2,%eax
80106aeb:	85 c0                	test   %eax,%eax
80106aed:	74 07                	je     80106af6 <fileopen+0x13b>
80106aef:	b8 01 00 00 00       	mov    $0x1,%eax
80106af4:	eb 05                	jmp    80106afb <fileopen+0x140>
80106af6:	b8 00 00 00 00       	mov    $0x0,%eax
80106afb:	89 c2                	mov    %eax,%edx
80106afd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b00:	88 50 09             	mov    %dl,0x9(%eax)
  return f;
80106b03:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80106b06:	c9                   	leave  
80106b07:	c3                   	ret    

80106b08 <sys_open>:

int
sys_open(void)
{
80106b08:	55                   	push   %ebp
80106b09:	89 e5                	mov    %esp,%ebp
80106b0b:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80106b0e:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106b11:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b15:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106b1c:	e8 a3 f3 ff ff       	call   80105ec4 <argstr>
80106b21:	85 c0                	test   %eax,%eax
80106b23:	78 17                	js     80106b3c <sys_open+0x34>
80106b25:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106b28:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b2c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106b33:	e8 f2 f2 ff ff       	call   80105e2a <argint>
80106b38:	85 c0                	test   %eax,%eax
80106b3a:	79 0a                	jns    80106b46 <sys_open+0x3e>
    return -1;
80106b3c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106b41:	e9 46 01 00 00       	jmp    80106c8c <sys_open+0x184>
  if(omode & O_CREATE){
80106b46:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106b49:	25 00 02 00 00       	and    $0x200,%eax
80106b4e:	85 c0                	test   %eax,%eax
80106b50:	74 40                	je     80106b92 <sys_open+0x8a>
    begin_trans();
80106b52:	e8 5a cc ff ff       	call   801037b1 <begin_trans>
    ip = create(path, T_FILE, 0, 0);
80106b57:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106b5a:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106b61:	00 
80106b62:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106b69:	00 
80106b6a:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80106b71:	00 
80106b72:	89 04 24             	mov    %eax,(%esp)
80106b75:	e8 81 fc ff ff       	call   801067fb <create>
80106b7a:	89 45 f4             	mov    %eax,-0xc(%ebp)
    commit_trans();
80106b7d:	e8 78 cc ff ff       	call   801037fa <commit_trans>
    if(ip == 0)
80106b82:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106b86:	75 5c                	jne    80106be4 <sys_open+0xdc>
      return -1;
80106b88:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106b8d:	e9 fa 00 00 00       	jmp    80106c8c <sys_open+0x184>
  } else {
    if((ip = namei(path)) == 0)
80106b92:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106b95:	89 04 24             	mov    %eax,(%esp)
80106b98:	e8 6d b8 ff ff       	call   8010240a <namei>
80106b9d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106ba0:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106ba4:	75 0a                	jne    80106bb0 <sys_open+0xa8>
      return -1;
80106ba6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106bab:	e9 dc 00 00 00       	jmp    80106c8c <sys_open+0x184>
    ilock(ip);
80106bb0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106bb3:	89 04 24             	mov    %eax,(%esp)
80106bb6:	e8 ad ac ff ff       	call   80101868 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80106bbb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106bbe:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106bc2:	66 83 f8 01          	cmp    $0x1,%ax
80106bc6:	75 1c                	jne    80106be4 <sys_open+0xdc>
80106bc8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106bcb:	85 c0                	test   %eax,%eax
80106bcd:	74 15                	je     80106be4 <sys_open+0xdc>
      iunlockput(ip);
80106bcf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106bd2:	89 04 24             	mov    %eax,(%esp)
80106bd5:	e8 12 af ff ff       	call   80101aec <iunlockput>
      return -1;
80106bda:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106bdf:	e9 a8 00 00 00       	jmp    80106c8c <sys_open+0x184>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80106be4:	e8 33 a3 ff ff       	call   80100f1c <filealloc>
80106be9:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106bec:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106bf0:	74 14                	je     80106c06 <sys_open+0xfe>
80106bf2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106bf5:	89 04 24             	mov    %eax,(%esp)
80106bf8:	e8 44 f4 ff ff       	call   80106041 <fdalloc>
80106bfd:	89 45 ec             	mov    %eax,-0x14(%ebp)
80106c00:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80106c04:	79 23                	jns    80106c29 <sys_open+0x121>
    if(f)
80106c06:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106c0a:	74 0b                	je     80106c17 <sys_open+0x10f>
      fileclose(f);
80106c0c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c0f:	89 04 24             	mov    %eax,(%esp)
80106c12:	e8 ad a3 ff ff       	call   80100fc4 <fileclose>
    iunlockput(ip);
80106c17:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c1a:	89 04 24             	mov    %eax,(%esp)
80106c1d:	e8 ca ae ff ff       	call   80101aec <iunlockput>
    return -1;
80106c22:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106c27:	eb 63                	jmp    80106c8c <sys_open+0x184>
  }
  iunlock(ip);
80106c29:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c2c:	89 04 24             	mov    %eax,(%esp)
80106c2f:	e8 82 ad ff ff       	call   801019b6 <iunlock>

  f->type = FD_INODE;
80106c34:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c37:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80106c3d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c40:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106c43:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
80106c46:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c49:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80106c50:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106c53:	83 e0 01             	and    $0x1,%eax
80106c56:	85 c0                	test   %eax,%eax
80106c58:	0f 94 c2             	sete   %dl
80106c5b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c5e:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80106c61:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106c64:	83 e0 01             	and    $0x1,%eax
80106c67:	84 c0                	test   %al,%al
80106c69:	75 0a                	jne    80106c75 <sys_open+0x16d>
80106c6b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106c6e:	83 e0 02             	and    $0x2,%eax
80106c71:	85 c0                	test   %eax,%eax
80106c73:	74 07                	je     80106c7c <sys_open+0x174>
80106c75:	b8 01 00 00 00       	mov    $0x1,%eax
80106c7a:	eb 05                	jmp    80106c81 <sys_open+0x179>
80106c7c:	b8 00 00 00 00       	mov    $0x0,%eax
80106c81:	89 c2                	mov    %eax,%edx
80106c83:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c86:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
80106c89:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
80106c8c:	c9                   	leave  
80106c8d:	c3                   	ret    

80106c8e <sys_mkdir>:

int
sys_mkdir(void)
{
80106c8e:	55                   	push   %ebp
80106c8f:	89 e5                	mov    %esp,%ebp
80106c91:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_trans();
80106c94:	e8 18 cb ff ff       	call   801037b1 <begin_trans>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80106c99:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106c9c:	89 44 24 04          	mov    %eax,0x4(%esp)
80106ca0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106ca7:	e8 18 f2 ff ff       	call   80105ec4 <argstr>
80106cac:	85 c0                	test   %eax,%eax
80106cae:	78 2c                	js     80106cdc <sys_mkdir+0x4e>
80106cb0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106cb3:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106cba:	00 
80106cbb:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106cc2:	00 
80106cc3:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80106cca:	00 
80106ccb:	89 04 24             	mov    %eax,(%esp)
80106cce:	e8 28 fb ff ff       	call   801067fb <create>
80106cd3:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106cd6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106cda:	75 0c                	jne    80106ce8 <sys_mkdir+0x5a>
    commit_trans();
80106cdc:	e8 19 cb ff ff       	call   801037fa <commit_trans>
    return -1;
80106ce1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106ce6:	eb 15                	jmp    80106cfd <sys_mkdir+0x6f>
  }
  iunlockput(ip);
80106ce8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ceb:	89 04 24             	mov    %eax,(%esp)
80106cee:	e8 f9 ad ff ff       	call   80101aec <iunlockput>
  commit_trans();
80106cf3:	e8 02 cb ff ff       	call   801037fa <commit_trans>
  return 0;
80106cf8:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106cfd:	c9                   	leave  
80106cfe:	c3                   	ret    

80106cff <sys_mknod>:

int
sys_mknod(void)
{
80106cff:	55                   	push   %ebp
80106d00:	89 e5                	mov    %esp,%ebp
80106d02:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
80106d05:	e8 a7 ca ff ff       	call   801037b1 <begin_trans>
  if((len=argstr(0, &path)) < 0 ||
80106d0a:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106d0d:	89 44 24 04          	mov    %eax,0x4(%esp)
80106d11:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106d18:	e8 a7 f1 ff ff       	call   80105ec4 <argstr>
80106d1d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106d20:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106d24:	78 5e                	js     80106d84 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
80106d26:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106d29:	89 44 24 04          	mov    %eax,0x4(%esp)
80106d2d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106d34:	e8 f1 f0 ff ff       	call   80105e2a <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
80106d39:	85 c0                	test   %eax,%eax
80106d3b:	78 47                	js     80106d84 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80106d3d:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106d40:	89 44 24 04          	mov    %eax,0x4(%esp)
80106d44:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80106d4b:	e8 da f0 ff ff       	call   80105e2a <argint>
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
80106d50:	85 c0                	test   %eax,%eax
80106d52:	78 30                	js     80106d84 <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
80106d54:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106d57:	0f bf c8             	movswl %ax,%ecx
80106d5a:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106d5d:	0f bf d0             	movswl %ax,%edx
80106d60:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80106d63:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106d67:	89 54 24 08          	mov    %edx,0x8(%esp)
80106d6b:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80106d72:	00 
80106d73:	89 04 24             	mov    %eax,(%esp)
80106d76:	e8 80 fa ff ff       	call   801067fb <create>
80106d7b:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106d7e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106d82:	75 0c                	jne    80106d90 <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    commit_trans();
80106d84:	e8 71 ca ff ff       	call   801037fa <commit_trans>
    return -1;
80106d89:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106d8e:	eb 15                	jmp    80106da5 <sys_mknod+0xa6>
  }
  iunlockput(ip);
80106d90:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d93:	89 04 24             	mov    %eax,(%esp)
80106d96:	e8 51 ad ff ff       	call   80101aec <iunlockput>
  commit_trans();
80106d9b:	e8 5a ca ff ff       	call   801037fa <commit_trans>
  return 0;
80106da0:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106da5:	c9                   	leave  
80106da6:	c3                   	ret    

80106da7 <sys_chdir>:

int
sys_chdir(void)
{
80106da7:	55                   	push   %ebp
80106da8:	89 e5                	mov    %esp,%ebp
80106daa:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0)
80106dad:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106db0:	89 44 24 04          	mov    %eax,0x4(%esp)
80106db4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106dbb:	e8 04 f1 ff ff       	call   80105ec4 <argstr>
80106dc0:	85 c0                	test   %eax,%eax
80106dc2:	78 14                	js     80106dd8 <sys_chdir+0x31>
80106dc4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106dc7:	89 04 24             	mov    %eax,(%esp)
80106dca:	e8 3b b6 ff ff       	call   8010240a <namei>
80106dcf:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106dd2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106dd6:	75 07                	jne    80106ddf <sys_chdir+0x38>
    return -1;
80106dd8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106ddd:	eb 57                	jmp    80106e36 <sys_chdir+0x8f>
  ilock(ip);
80106ddf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106de2:	89 04 24             	mov    %eax,(%esp)
80106de5:	e8 7e aa ff ff       	call   80101868 <ilock>
  if(ip->type != T_DIR){
80106dea:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ded:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106df1:	66 83 f8 01          	cmp    $0x1,%ax
80106df5:	74 12                	je     80106e09 <sys_chdir+0x62>
    iunlockput(ip);
80106df7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106dfa:	89 04 24             	mov    %eax,(%esp)
80106dfd:	e8 ea ac ff ff       	call   80101aec <iunlockput>
    return -1;
80106e02:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106e07:	eb 2d                	jmp    80106e36 <sys_chdir+0x8f>
  }
  iunlock(ip);
80106e09:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e0c:	89 04 24             	mov    %eax,(%esp)
80106e0f:	e8 a2 ab ff ff       	call   801019b6 <iunlock>
  iput(proc->cwd);
80106e14:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106e1a:	8b 40 68             	mov    0x68(%eax),%eax
80106e1d:	89 04 24             	mov    %eax,(%esp)
80106e20:	e8 f6 ab ff ff       	call   80101a1b <iput>
  proc->cwd = ip;
80106e25:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106e2b:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106e2e:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
80106e31:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106e36:	c9                   	leave  
80106e37:	c3                   	ret    

80106e38 <sys_exec>:

int
sys_exec(void)
{
80106e38:	55                   	push   %ebp
80106e39:	89 e5                	mov    %esp,%ebp
80106e3b:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80106e41:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106e44:	89 44 24 04          	mov    %eax,0x4(%esp)
80106e48:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106e4f:	e8 70 f0 ff ff       	call   80105ec4 <argstr>
80106e54:	85 c0                	test   %eax,%eax
80106e56:	78 1a                	js     80106e72 <sys_exec+0x3a>
80106e58:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80106e5e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106e62:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106e69:	e8 bc ef ff ff       	call   80105e2a <argint>
80106e6e:	85 c0                	test   %eax,%eax
80106e70:	79 0a                	jns    80106e7c <sys_exec+0x44>
    return -1;
80106e72:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106e77:	e9 e2 00 00 00       	jmp    80106f5e <sys_exec+0x126>
  }
  memset(argv, 0, sizeof(argv));
80106e7c:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80106e83:	00 
80106e84:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106e8b:	00 
80106e8c:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106e92:	89 04 24             	mov    %eax,(%esp)
80106e95:	e8 40 ec ff ff       	call   80105ada <memset>
  for(i=0;; i++){
80106e9a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
80106ea1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ea4:	83 f8 1f             	cmp    $0x1f,%eax
80106ea7:	76 0a                	jbe    80106eb3 <sys_exec+0x7b>
      return -1;
80106ea9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106eae:	e9 ab 00 00 00       	jmp    80106f5e <sys_exec+0x126>
    if(fetchint(proc, uargv+4*i, (int*)&uarg) < 0)
80106eb3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106eb6:	c1 e0 02             	shl    $0x2,%eax
80106eb9:	89 c2                	mov    %eax,%edx
80106ebb:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80106ec1:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
80106ec4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106eca:	8d 95 68 ff ff ff    	lea    -0x98(%ebp),%edx
80106ed0:	89 54 24 08          	mov    %edx,0x8(%esp)
80106ed4:	89 4c 24 04          	mov    %ecx,0x4(%esp)
80106ed8:	89 04 24             	mov    %eax,(%esp)
80106edb:	e8 b8 ee ff ff       	call   80105d98 <fetchint>
80106ee0:	85 c0                	test   %eax,%eax
80106ee2:	79 07                	jns    80106eeb <sys_exec+0xb3>
      return -1;
80106ee4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106ee9:	eb 73                	jmp    80106f5e <sys_exec+0x126>
    if(uarg == 0){
80106eeb:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80106ef1:	85 c0                	test   %eax,%eax
80106ef3:	75 26                	jne    80106f1b <sys_exec+0xe3>
      argv[i] = 0;
80106ef5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ef8:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
80106eff:	00 00 00 00 
      break;
80106f03:	90                   	nop
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
80106f04:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106f07:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
80106f0d:	89 54 24 04          	mov    %edx,0x4(%esp)
80106f11:	89 04 24             	mov    %eax,(%esp)
80106f14:	e8 e3 9b ff ff       	call   80100afc <exec>
80106f19:	eb 43                	jmp    80106f5e <sys_exec+0x126>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
80106f1b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f1e:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80106f25:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106f2b:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
80106f2e:	8b 95 68 ff ff ff    	mov    -0x98(%ebp),%edx
80106f34:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106f3a:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106f3e:	89 54 24 04          	mov    %edx,0x4(%esp)
80106f42:	89 04 24             	mov    %eax,(%esp)
80106f45:	e8 82 ee ff ff       	call   80105dcc <fetchstr>
80106f4a:	85 c0                	test   %eax,%eax
80106f4c:	79 07                	jns    80106f55 <sys_exec+0x11d>
      return -1;
80106f4e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106f53:	eb 09                	jmp    80106f5e <sys_exec+0x126>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
80106f55:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
80106f59:	e9 43 ff ff ff       	jmp    80106ea1 <sys_exec+0x69>
  return exec(path, argv);
}
80106f5e:	c9                   	leave  
80106f5f:	c3                   	ret    

80106f60 <sys_pipe>:

int
sys_pipe(void)
{
80106f60:	55                   	push   %ebp
80106f61:	89 e5                	mov    %esp,%ebp
80106f63:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80106f66:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
80106f6d:	00 
80106f6e:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106f71:	89 44 24 04          	mov    %eax,0x4(%esp)
80106f75:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106f7c:	e8 e1 ee ff ff       	call   80105e62 <argptr>
80106f81:	85 c0                	test   %eax,%eax
80106f83:	79 0a                	jns    80106f8f <sys_pipe+0x2f>
    return -1;
80106f85:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106f8a:	e9 9b 00 00 00       	jmp    8010702a <sys_pipe+0xca>
  if(pipealloc(&rf, &wf) < 0)
80106f8f:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106f92:	89 44 24 04          	mov    %eax,0x4(%esp)
80106f96:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106f99:	89 04 24             	mov    %eax,(%esp)
80106f9c:	e8 2b d2 ff ff       	call   801041cc <pipealloc>
80106fa1:	85 c0                	test   %eax,%eax
80106fa3:	79 07                	jns    80106fac <sys_pipe+0x4c>
    return -1;
80106fa5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106faa:	eb 7e                	jmp    8010702a <sys_pipe+0xca>
  fd0 = -1;
80106fac:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80106fb3:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106fb6:	89 04 24             	mov    %eax,(%esp)
80106fb9:	e8 83 f0 ff ff       	call   80106041 <fdalloc>
80106fbe:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106fc1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106fc5:	78 14                	js     80106fdb <sys_pipe+0x7b>
80106fc7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106fca:	89 04 24             	mov    %eax,(%esp)
80106fcd:	e8 6f f0 ff ff       	call   80106041 <fdalloc>
80106fd2:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106fd5:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106fd9:	79 37                	jns    80107012 <sys_pipe+0xb2>
    if(fd0 >= 0)
80106fdb:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106fdf:	78 14                	js     80106ff5 <sys_pipe+0x95>
      proc->ofile[fd0] = 0;
80106fe1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106fe7:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106fea:	83 c2 08             	add    $0x8,%edx
80106fed:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80106ff4:	00 
    fileclose(rf);
80106ff5:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106ff8:	89 04 24             	mov    %eax,(%esp)
80106ffb:	e8 c4 9f ff ff       	call   80100fc4 <fileclose>
    fileclose(wf);
80107000:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80107003:	89 04 24             	mov    %eax,(%esp)
80107006:	e8 b9 9f ff ff       	call   80100fc4 <fileclose>
    return -1;
8010700b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107010:	eb 18                	jmp    8010702a <sys_pipe+0xca>
  }
  fd[0] = fd0;
80107012:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107015:	8b 55 f4             	mov    -0xc(%ebp),%edx
80107018:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
8010701a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010701d:	8d 50 04             	lea    0x4(%eax),%edx
80107020:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107023:	89 02                	mov    %eax,(%edx)
  return 0;
80107025:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010702a:	c9                   	leave  
8010702b:	c3                   	ret    

8010702c <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
8010702c:	55                   	push   %ebp
8010702d:	89 e5                	mov    %esp,%ebp
8010702f:	83 ec 08             	sub    $0x8,%esp
  return fork();
80107032:	e8 04 de ff ff       	call   80104e3b <fork>
}
80107037:	c9                   	leave  
80107038:	c3                   	ret    

80107039 <sys_exit>:

int
sys_exit(void)
{
80107039:	55                   	push   %ebp
8010703a:	89 e5                	mov    %esp,%ebp
8010703c:	83 ec 08             	sub    $0x8,%esp
  exit();
8010703f:	e8 5a df ff ff       	call   80104f9e <exit>
  return 0;  // not reached
80107044:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107049:	c9                   	leave  
8010704a:	c3                   	ret    

8010704b <sys_wait>:

int
sys_wait(void)
{
8010704b:	55                   	push   %ebp
8010704c:	89 e5                	mov    %esp,%ebp
8010704e:	83 ec 08             	sub    $0x8,%esp
  return wait();
80107051:	e8 63 e0 ff ff       	call   801050b9 <wait>
}
80107056:	c9                   	leave  
80107057:	c3                   	ret    

80107058 <sys_kill>:

int
sys_kill(void)
{
80107058:	55                   	push   %ebp
80107059:	89 e5                	mov    %esp,%ebp
8010705b:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
8010705e:	8d 45 f4             	lea    -0xc(%ebp),%eax
80107061:	89 44 24 04          	mov    %eax,0x4(%esp)
80107065:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010706c:	e8 b9 ed ff ff       	call   80105e2a <argint>
80107071:	85 c0                	test   %eax,%eax
80107073:	79 07                	jns    8010707c <sys_kill+0x24>
    return -1;
80107075:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010707a:	eb 0b                	jmp    80107087 <sys_kill+0x2f>
  return kill(pid);
8010707c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010707f:	89 04 24             	mov    %eax,(%esp)
80107082:	e8 f7 e4 ff ff       	call   8010557e <kill>
}
80107087:	c9                   	leave  
80107088:	c3                   	ret    

80107089 <sys_getpid>:

int
sys_getpid(void)
{
80107089:	55                   	push   %ebp
8010708a:	89 e5                	mov    %esp,%ebp
  return proc->pid;
8010708c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107092:	8b 40 10             	mov    0x10(%eax),%eax
}
80107095:	5d                   	pop    %ebp
80107096:	c3                   	ret    

80107097 <sys_sbrk>:

int
sys_sbrk(void)
{
80107097:	55                   	push   %ebp
80107098:	89 e5                	mov    %esp,%ebp
8010709a:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
8010709d:	8d 45 f0             	lea    -0x10(%ebp),%eax
801070a0:	89 44 24 04          	mov    %eax,0x4(%esp)
801070a4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801070ab:	e8 7a ed ff ff       	call   80105e2a <argint>
801070b0:	85 c0                	test   %eax,%eax
801070b2:	79 07                	jns    801070bb <sys_sbrk+0x24>
    return -1;
801070b4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801070b9:	eb 24                	jmp    801070df <sys_sbrk+0x48>
  addr = proc->sz;
801070bb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801070c1:	8b 00                	mov    (%eax),%eax
801070c3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
801070c6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801070c9:	89 04 24             	mov    %eax,(%esp)
801070cc:	e8 c5 dc ff ff       	call   80104d96 <growproc>
801070d1:	85 c0                	test   %eax,%eax
801070d3:	79 07                	jns    801070dc <sys_sbrk+0x45>
    return -1;
801070d5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801070da:	eb 03                	jmp    801070df <sys_sbrk+0x48>
  return addr;
801070dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801070df:	c9                   	leave  
801070e0:	c3                   	ret    

801070e1 <sys_sleep>:

int
sys_sleep(void)
{
801070e1:	55                   	push   %ebp
801070e2:	89 e5                	mov    %esp,%ebp
801070e4:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
801070e7:	8d 45 f0             	lea    -0x10(%ebp),%eax
801070ea:	89 44 24 04          	mov    %eax,0x4(%esp)
801070ee:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801070f5:	e8 30 ed ff ff       	call   80105e2a <argint>
801070fa:	85 c0                	test   %eax,%eax
801070fc:	79 07                	jns    80107105 <sys_sleep+0x24>
    return -1;
801070fe:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107103:	eb 6c                	jmp    80107171 <sys_sleep+0x90>
  acquire(&tickslock);
80107105:	c7 04 24 c0 62 11 80 	movl   $0x801162c0,(%esp)
8010710c:	e8 42 e7 ff ff       	call   80105853 <acquire>
  ticks0 = ticks;
80107111:	a1 00 6b 11 80       	mov    0x80116b00,%eax
80107116:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
80107119:	eb 34                	jmp    8010714f <sys_sleep+0x6e>
    if(proc->killed){
8010711b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107121:	8b 40 24             	mov    0x24(%eax),%eax
80107124:	85 c0                	test   %eax,%eax
80107126:	74 13                	je     8010713b <sys_sleep+0x5a>
      release(&tickslock);
80107128:	c7 04 24 c0 62 11 80 	movl   $0x801162c0,(%esp)
8010712f:	e8 ba e7 ff ff       	call   801058ee <release>
      return -1;
80107134:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107139:	eb 36                	jmp    80107171 <sys_sleep+0x90>
    }
    sleep(&ticks, &tickslock);
8010713b:	c7 44 24 04 c0 62 11 	movl   $0x801162c0,0x4(%esp)
80107142:	80 
80107143:	c7 04 24 00 6b 11 80 	movl   $0x80116b00,(%esp)
8010714a:	e8 c8 e2 ff ff       	call   80105417 <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
8010714f:	a1 00 6b 11 80       	mov    0x80116b00,%eax
80107154:	89 c2                	mov    %eax,%edx
80107156:	2b 55 f4             	sub    -0xc(%ebp),%edx
80107159:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010715c:	39 c2                	cmp    %eax,%edx
8010715e:	72 bb                	jb     8010711b <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
80107160:	c7 04 24 c0 62 11 80 	movl   $0x801162c0,(%esp)
80107167:	e8 82 e7 ff ff       	call   801058ee <release>
  return 0;
8010716c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107171:	c9                   	leave  
80107172:	c3                   	ret    

80107173 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80107173:	55                   	push   %ebp
80107174:	89 e5                	mov    %esp,%ebp
80107176:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
80107179:	c7 04 24 c0 62 11 80 	movl   $0x801162c0,(%esp)
80107180:	e8 ce e6 ff ff       	call   80105853 <acquire>
  xticks = ticks;
80107185:	a1 00 6b 11 80       	mov    0x80116b00,%eax
8010718a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
8010718d:	c7 04 24 c0 62 11 80 	movl   $0x801162c0,(%esp)
80107194:	e8 55 e7 ff ff       	call   801058ee <release>
  return xticks;
80107199:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010719c:	c9                   	leave  
8010719d:	c3                   	ret    

8010719e <sys_enableSwapping>:

void
sys_enableSwapping(void)
{
8010719e:	55                   	push   %ebp
8010719f:	89 e5                	mov    %esp,%ebp
  swapFlag = 1;
801071a1:	c7 05 68 c6 10 80 01 	movl   $0x1,0x8010c668
801071a8:	00 00 00 
}
801071ab:	5d                   	pop    %ebp
801071ac:	c3                   	ret    

801071ad <sys_disableSwapping>:

void
sys_disableSwapping(void)
{
801071ad:	55                   	push   %ebp
801071ae:	89 e5                	mov    %esp,%ebp
  swapFlag = 0;
801071b0:	c7 05 68 c6 10 80 00 	movl   $0x0,0x8010c668
801071b7:	00 00 00 
}
801071ba:	5d                   	pop    %ebp
801071bb:	c3                   	ret    

801071bc <sys_sleep2>:

int
sys_sleep2(void)
{
801071bc:	55                   	push   %ebp
801071bd:	89 e5                	mov    %esp,%ebp
801071bf:	83 ec 18             	sub    $0x18,%esp
  acquire(&tickslock);
801071c2:	c7 04 24 c0 62 11 80 	movl   $0x801162c0,(%esp)
801071c9:	e8 85 e6 ff ff       	call   80105853 <acquire>
  if(proc->killed){
801071ce:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801071d4:	8b 40 24             	mov    0x24(%eax),%eax
801071d7:	85 c0                	test   %eax,%eax
801071d9:	74 13                	je     801071ee <sys_sleep2+0x32>
    release(&tickslock);
801071db:	c7 04 24 c0 62 11 80 	movl   $0x801162c0,(%esp)
801071e2:	e8 07 e7 ff ff       	call   801058ee <release>
    return -1;
801071e7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801071ec:	eb 25                	jmp    80107213 <sys_sleep2+0x57>
  }
  sleep(&swapFlag, &tickslock);
801071ee:	c7 44 24 04 c0 62 11 	movl   $0x801162c0,0x4(%esp)
801071f5:	80 
801071f6:	c7 04 24 68 c6 10 80 	movl   $0x8010c668,(%esp)
801071fd:	e8 15 e2 ff ff       	call   80105417 <sleep>
  release(&tickslock);
80107202:	c7 04 24 c0 62 11 80 	movl   $0x801162c0,(%esp)
80107209:	e8 e0 e6 ff ff       	call   801058ee <release>
  return 0;
8010720e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107213:	c9                   	leave  
80107214:	c3                   	ret    

80107215 <sys_wakeup2>:

int
sys_wakeup2(void)
{
80107215:	55                   	push   %ebp
80107216:	89 e5                	mov    %esp,%ebp
80107218:	83 ec 18             	sub    $0x18,%esp
  wakeup(&swapFlag);
8010721b:	c7 04 24 68 c6 10 80 	movl   $0x8010c668,(%esp)
80107222:	e8 2c e3 ff ff       	call   80105553 <wakeup>
  return 0;
80107227:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010722c:	c9                   	leave  
8010722d:	c3                   	ret    

8010722e <sys_getAllocatedPages>:

int
sys_getAllocatedPages(void)
{
8010722e:	55                   	push   %ebp
8010722f:	89 e5                	mov    %esp,%ebp
80107231:	83 ec 28             	sub    $0x28,%esp
  int pid;
  if(argint(0, &pid) < 0)
80107234:	8d 45 f4             	lea    -0xc(%ebp),%eax
80107237:	89 44 24 04          	mov    %eax,0x4(%esp)
8010723b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107242:	e8 e3 eb ff ff       	call   80105e2a <argint>
80107247:	85 c0                	test   %eax,%eax
80107249:	79 07                	jns    80107252 <sys_getAllocatedPages+0x24>
    return -1;
8010724b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107250:	eb 0b                	jmp    8010725d <sys_getAllocatedPages+0x2f>
  return getAllocatedPages(pid);
80107252:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107255:	89 04 24             	mov    %eax,(%esp)
80107258:	e8 bb e4 ff ff       	call   80105718 <getAllocatedPages>
}
8010725d:	c9                   	leave  
8010725e:	c3                   	ret    

8010725f <sys_shmget>:

int 
sys_shmget(void)
{
8010725f:	55                   	push   %ebp
80107260:	89 e5                	mov    %esp,%ebp
80107262:	83 ec 28             	sub    $0x28,%esp
  int key,size, shmflg;
  
  if(argint(0, &key) < 0)
80107265:	8d 45 f4             	lea    -0xc(%ebp),%eax
80107268:	89 44 24 04          	mov    %eax,0x4(%esp)
8010726c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107273:	e8 b2 eb ff ff       	call   80105e2a <argint>
80107278:	85 c0                	test   %eax,%eax
8010727a:	79 07                	jns    80107283 <sys_shmget+0x24>
    return -1;
8010727c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107281:	eb 65                	jmp    801072e8 <sys_shmget+0x89>
  
  if(argint(1, &size) < 0)
80107283:	8d 45 f0             	lea    -0x10(%ebp),%eax
80107286:	89 44 24 04          	mov    %eax,0x4(%esp)
8010728a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80107291:	e8 94 eb ff ff       	call   80105e2a <argint>
80107296:	85 c0                	test   %eax,%eax
80107298:	79 07                	jns    801072a1 <sys_shmget+0x42>
    return -1;
8010729a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010729f:	eb 47                	jmp    801072e8 <sys_shmget+0x89>
  if(size<0)
801072a1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801072a4:	85 c0                	test   %eax,%eax
801072a6:	79 07                	jns    801072af <sys_shmget+0x50>
    return -1;
801072a8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801072ad:	eb 39                	jmp    801072e8 <sys_shmget+0x89>
  
  if(argint(2, &shmflg) < 0)
801072af:	8d 45 ec             	lea    -0x14(%ebp),%eax
801072b2:	89 44 24 04          	mov    %eax,0x4(%esp)
801072b6:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801072bd:	e8 68 eb ff ff       	call   80105e2a <argint>
801072c2:	85 c0                	test   %eax,%eax
801072c4:	79 07                	jns    801072cd <sys_shmget+0x6e>
    return -1;
801072c6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801072cb:	eb 1b                	jmp    801072e8 <sys_shmget+0x89>
  
  return shmget(key, (uint)size,shmflg);
801072cd:	8b 4d ec             	mov    -0x14(%ebp),%ecx
801072d0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801072d3:	89 c2                	mov    %eax,%edx
801072d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801072d8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801072dc:	89 54 24 04          	mov    %edx,0x4(%esp)
801072e0:	89 04 24             	mov    %eax,(%esp)
801072e3:	e8 75 b8 ff ff       	call   80102b5d <shmget>
}
801072e8:	c9                   	leave  
801072e9:	c3                   	ret    

801072ea <sys_shmdel>:

int 
sys_shmdel(void)
{
801072ea:	55                   	push   %ebp
801072eb:	89 e5                	mov    %esp,%ebp
801072ed:	83 ec 28             	sub    $0x28,%esp
  int shmid;
  if(argint(0, &shmid) < 0)
801072f0:	8d 45 f4             	lea    -0xc(%ebp),%eax
801072f3:	89 44 24 04          	mov    %eax,0x4(%esp)
801072f7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801072fe:	e8 27 eb ff ff       	call   80105e2a <argint>
80107303:	85 c0                	test   %eax,%eax
80107305:	79 07                	jns    8010730e <sys_shmdel+0x24>
    return -1;
80107307:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010730c:	eb 0b                	jmp    80107319 <sys_shmdel+0x2f>
  
  return shmdel(shmid);
8010730e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107311:	89 04 24             	mov    %eax,(%esp)
80107314:	e8 77 b9 ff ff       	call   80102c90 <shmdel>
}
80107319:	c9                   	leave  
8010731a:	c3                   	ret    

8010731b <sys_shmat>:

void *
sys_shmat(void)
{
8010731b:	55                   	push   %ebp
8010731c:	89 e5                	mov    %esp,%ebp
8010731e:	83 ec 28             	sub    $0x28,%esp
  int shmid,shmflg;
  
  if(argint(0, &shmid) < 0)
80107321:	8d 45 f4             	lea    -0xc(%ebp),%eax
80107324:	89 44 24 04          	mov    %eax,0x4(%esp)
80107328:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010732f:	e8 f6 ea ff ff       	call   80105e2a <argint>
80107334:	85 c0                	test   %eax,%eax
80107336:	79 07                	jns    8010733f <sys_shmat+0x24>
    return (void*)-1;
80107338:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010733d:	eb 30                	jmp    8010736f <sys_shmat+0x54>
  
  if(argint(1, &shmflg) < 0)
8010733f:	8d 45 f0             	lea    -0x10(%ebp),%eax
80107342:	89 44 24 04          	mov    %eax,0x4(%esp)
80107346:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010734d:	e8 d8 ea ff ff       	call   80105e2a <argint>
80107352:	85 c0                	test   %eax,%eax
80107354:	79 07                	jns    8010735d <sys_shmat+0x42>
    return (void*)-1;
80107356:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010735b:	eb 12                	jmp    8010736f <sys_shmat+0x54>
  
  return shmat(shmid,shmflg);
8010735d:	8b 55 f0             	mov    -0x10(%ebp),%edx
80107360:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107363:	89 54 24 04          	mov    %edx,0x4(%esp)
80107367:	89 04 24             	mov    %eax,(%esp)
8010736a:	e8 1d ba ff ff       	call   80102d8c <shmat>
}
8010736f:	c9                   	leave  
80107370:	c3                   	ret    

80107371 <sys_shmdt>:

int 
sys_shmdt(void)
{
80107371:	55                   	push   %ebp
80107372:	89 e5                	mov    %esp,%ebp
80107374:	83 ec 28             	sub    $0x28,%esp
  void* shmaddr;
  if(argptr(0, (void*)&shmaddr,sizeof(void*)) < 0)
80107377:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
8010737e:	00 
8010737f:	8d 45 f4             	lea    -0xc(%ebp),%eax
80107382:	89 44 24 04          	mov    %eax,0x4(%esp)
80107386:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010738d:	e8 d0 ea ff ff       	call   80105e62 <argptr>
80107392:	85 c0                	test   %eax,%eax
80107394:	79 07                	jns    8010739d <sys_shmdt+0x2c>
    return -1;
80107396:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010739b:	eb 0b                	jmp    801073a8 <sys_shmdt+0x37>
  return shmdt(shmaddr);
8010739d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801073a0:	89 04 24             	mov    %eax,(%esp)
801073a3:	e8 8c bb ff ff       	call   80102f34 <shmdt>
}
801073a8:	c9                   	leave  
801073a9:	c3                   	ret    
	...

801073ac <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801073ac:	55                   	push   %ebp
801073ad:	89 e5                	mov    %esp,%ebp
801073af:	83 ec 08             	sub    $0x8,%esp
801073b2:	8b 55 08             	mov    0x8(%ebp),%edx
801073b5:	8b 45 0c             	mov    0xc(%ebp),%eax
801073b8:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801073bc:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801073bf:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801073c3:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801073c7:	ee                   	out    %al,(%dx)
}
801073c8:	c9                   	leave  
801073c9:	c3                   	ret    

801073ca <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
801073ca:	55                   	push   %ebp
801073cb:	89 e5                	mov    %esp,%ebp
801073cd:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
801073d0:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
801073d7:	00 
801073d8:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
801073df:	e8 c8 ff ff ff       	call   801073ac <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
801073e4:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
801073eb:	00 
801073ec:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
801073f3:	e8 b4 ff ff ff       	call   801073ac <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
801073f8:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
801073ff:	00 
80107400:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
80107407:	e8 a0 ff ff ff       	call   801073ac <outb>
  picenable(IRQ_TIMER);
8010740c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107413:	e8 3d cc ff ff       	call   80104055 <picenable>
}
80107418:	c9                   	leave  
80107419:	c3                   	ret    
	...

8010741c <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
8010741c:	1e                   	push   %ds
  pushl %es
8010741d:	06                   	push   %es
  pushl %fs
8010741e:	0f a0                	push   %fs
  pushl %gs
80107420:	0f a8                	push   %gs
  pushal
80107422:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
80107423:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
80107427:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80107429:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
8010742b:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
8010742f:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
80107431:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
80107433:	54                   	push   %esp
  call trap
80107434:	e8 de 01 00 00       	call   80107617 <trap>
  addl $4, %esp
80107439:	83 c4 04             	add    $0x4,%esp

8010743c <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
8010743c:	61                   	popa   
  popl %gs
8010743d:	0f a9                	pop    %gs
  popl %fs
8010743f:	0f a1                	pop    %fs
  popl %es
80107441:	07                   	pop    %es
  popl %ds
80107442:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80107443:	83 c4 08             	add    $0x8,%esp
  iret
80107446:	cf                   	iret   
	...

80107448 <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
80107448:	55                   	push   %ebp
80107449:	89 e5                	mov    %esp,%ebp
8010744b:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
8010744e:	8b 45 0c             	mov    0xc(%ebp),%eax
80107451:	83 e8 01             	sub    $0x1,%eax
80107454:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80107458:	8b 45 08             	mov    0x8(%ebp),%eax
8010745b:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
8010745f:	8b 45 08             	mov    0x8(%ebp),%eax
80107462:	c1 e8 10             	shr    $0x10,%eax
80107465:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
80107469:	8d 45 fa             	lea    -0x6(%ebp),%eax
8010746c:	0f 01 18             	lidtl  (%eax)
}
8010746f:	c9                   	leave  
80107470:	c3                   	ret    

80107471 <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
80107471:	55                   	push   %ebp
80107472:	89 e5                	mov    %esp,%ebp
80107474:	53                   	push   %ebx
80107475:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
80107478:	0f 20 d3             	mov    %cr2,%ebx
8010747b:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return val;
8010747e:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80107481:	83 c4 10             	add    $0x10,%esp
80107484:	5b                   	pop    %ebx
80107485:	5d                   	pop    %ebp
80107486:	c3                   	ret    

80107487 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
80107487:	55                   	push   %ebp
80107488:	89 e5                	mov    %esp,%ebp
8010748a:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
8010748d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80107494:	e9 c3 00 00 00       	jmp    8010755c <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80107499:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010749c:	8b 04 85 bc c0 10 80 	mov    -0x7fef3f44(,%eax,4),%eax
801074a3:	89 c2                	mov    %eax,%edx
801074a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074a8:	66 89 14 c5 00 63 11 	mov    %dx,-0x7fee9d00(,%eax,8)
801074af:	80 
801074b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074b3:	66 c7 04 c5 02 63 11 	movw   $0x8,-0x7fee9cfe(,%eax,8)
801074ba:	80 08 00 
801074bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074c0:	0f b6 14 c5 04 63 11 	movzbl -0x7fee9cfc(,%eax,8),%edx
801074c7:	80 
801074c8:	83 e2 e0             	and    $0xffffffe0,%edx
801074cb:	88 14 c5 04 63 11 80 	mov    %dl,-0x7fee9cfc(,%eax,8)
801074d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074d5:	0f b6 14 c5 04 63 11 	movzbl -0x7fee9cfc(,%eax,8),%edx
801074dc:	80 
801074dd:	83 e2 1f             	and    $0x1f,%edx
801074e0:	88 14 c5 04 63 11 80 	mov    %dl,-0x7fee9cfc(,%eax,8)
801074e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074ea:	0f b6 14 c5 05 63 11 	movzbl -0x7fee9cfb(,%eax,8),%edx
801074f1:	80 
801074f2:	83 e2 f0             	and    $0xfffffff0,%edx
801074f5:	83 ca 0e             	or     $0xe,%edx
801074f8:	88 14 c5 05 63 11 80 	mov    %dl,-0x7fee9cfb(,%eax,8)
801074ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107502:	0f b6 14 c5 05 63 11 	movzbl -0x7fee9cfb(,%eax,8),%edx
80107509:	80 
8010750a:	83 e2 ef             	and    $0xffffffef,%edx
8010750d:	88 14 c5 05 63 11 80 	mov    %dl,-0x7fee9cfb(,%eax,8)
80107514:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107517:	0f b6 14 c5 05 63 11 	movzbl -0x7fee9cfb(,%eax,8),%edx
8010751e:	80 
8010751f:	83 e2 9f             	and    $0xffffff9f,%edx
80107522:	88 14 c5 05 63 11 80 	mov    %dl,-0x7fee9cfb(,%eax,8)
80107529:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010752c:	0f b6 14 c5 05 63 11 	movzbl -0x7fee9cfb(,%eax,8),%edx
80107533:	80 
80107534:	83 ca 80             	or     $0xffffff80,%edx
80107537:	88 14 c5 05 63 11 80 	mov    %dl,-0x7fee9cfb(,%eax,8)
8010753e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107541:	8b 04 85 bc c0 10 80 	mov    -0x7fef3f44(,%eax,4),%eax
80107548:	c1 e8 10             	shr    $0x10,%eax
8010754b:	89 c2                	mov    %eax,%edx
8010754d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107550:	66 89 14 c5 06 63 11 	mov    %dx,-0x7fee9cfa(,%eax,8)
80107557:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
80107558:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010755c:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
80107563:	0f 8e 30 ff ff ff    	jle    80107499 <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80107569:	a1 bc c1 10 80       	mov    0x8010c1bc,%eax
8010756e:	66 a3 00 65 11 80    	mov    %ax,0x80116500
80107574:	66 c7 05 02 65 11 80 	movw   $0x8,0x80116502
8010757b:	08 00 
8010757d:	0f b6 05 04 65 11 80 	movzbl 0x80116504,%eax
80107584:	83 e0 e0             	and    $0xffffffe0,%eax
80107587:	a2 04 65 11 80       	mov    %al,0x80116504
8010758c:	0f b6 05 04 65 11 80 	movzbl 0x80116504,%eax
80107593:	83 e0 1f             	and    $0x1f,%eax
80107596:	a2 04 65 11 80       	mov    %al,0x80116504
8010759b:	0f b6 05 05 65 11 80 	movzbl 0x80116505,%eax
801075a2:	83 c8 0f             	or     $0xf,%eax
801075a5:	a2 05 65 11 80       	mov    %al,0x80116505
801075aa:	0f b6 05 05 65 11 80 	movzbl 0x80116505,%eax
801075b1:	83 e0 ef             	and    $0xffffffef,%eax
801075b4:	a2 05 65 11 80       	mov    %al,0x80116505
801075b9:	0f b6 05 05 65 11 80 	movzbl 0x80116505,%eax
801075c0:	83 c8 60             	or     $0x60,%eax
801075c3:	a2 05 65 11 80       	mov    %al,0x80116505
801075c8:	0f b6 05 05 65 11 80 	movzbl 0x80116505,%eax
801075cf:	83 c8 80             	or     $0xffffff80,%eax
801075d2:	a2 05 65 11 80       	mov    %al,0x80116505
801075d7:	a1 bc c1 10 80       	mov    0x8010c1bc,%eax
801075dc:	c1 e8 10             	shr    $0x10,%eax
801075df:	66 a3 06 65 11 80    	mov    %ax,0x80116506
  
  initlock(&tickslock, "time");
801075e5:	c7 44 24 04 d8 98 10 	movl   $0x801098d8,0x4(%esp)
801075ec:	80 
801075ed:	c7 04 24 c0 62 11 80 	movl   $0x801162c0,(%esp)
801075f4:	e8 39 e2 ff ff       	call   80105832 <initlock>
}
801075f9:	c9                   	leave  
801075fa:	c3                   	ret    

801075fb <idtinit>:

void
idtinit(void)
{
801075fb:	55                   	push   %ebp
801075fc:	89 e5                	mov    %esp,%ebp
801075fe:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
80107601:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
80107608:	00 
80107609:	c7 04 24 00 63 11 80 	movl   $0x80116300,(%esp)
80107610:	e8 33 fe ff ff       	call   80107448 <lidt>
}
80107615:	c9                   	leave  
80107616:	c3                   	ret    

80107617 <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
80107617:	55                   	push   %ebp
80107618:	89 e5                	mov    %esp,%ebp
8010761a:	57                   	push   %edi
8010761b:	56                   	push   %esi
8010761c:	53                   	push   %ebx
8010761d:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
80107620:	8b 45 08             	mov    0x8(%ebp),%eax
80107623:	8b 40 30             	mov    0x30(%eax),%eax
80107626:	83 f8 40             	cmp    $0x40,%eax
80107629:	75 3e                	jne    80107669 <trap+0x52>
    if(proc->killed)
8010762b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107631:	8b 40 24             	mov    0x24(%eax),%eax
80107634:	85 c0                	test   %eax,%eax
80107636:	74 05                	je     8010763d <trap+0x26>
      exit();
80107638:	e8 61 d9 ff ff       	call   80104f9e <exit>
    proc->tf = tf;
8010763d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107643:	8b 55 08             	mov    0x8(%ebp),%edx
80107646:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
80107649:	e8 b9 e8 ff ff       	call   80105f07 <syscall>
    if(proc->killed)
8010764e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107654:	8b 40 24             	mov    0x24(%eax),%eax
80107657:	85 c0                	test   %eax,%eax
80107659:	0f 84 34 02 00 00    	je     80107893 <trap+0x27c>
      exit();
8010765f:	e8 3a d9 ff ff       	call   80104f9e <exit>
    return;
80107664:	e9 2a 02 00 00       	jmp    80107893 <trap+0x27c>
  }

  switch(tf->trapno){
80107669:	8b 45 08             	mov    0x8(%ebp),%eax
8010766c:	8b 40 30             	mov    0x30(%eax),%eax
8010766f:	83 e8 20             	sub    $0x20,%eax
80107672:	83 f8 1f             	cmp    $0x1f,%eax
80107675:	0f 87 bc 00 00 00    	ja     80107737 <trap+0x120>
8010767b:	8b 04 85 80 99 10 80 	mov    -0x7fef6680(,%eax,4),%eax
80107682:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
80107684:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010768a:	0f b6 00             	movzbl (%eax),%eax
8010768d:	84 c0                	test   %al,%al
8010768f:	75 31                	jne    801076c2 <trap+0xab>
      acquire(&tickslock);
80107691:	c7 04 24 c0 62 11 80 	movl   $0x801162c0,(%esp)
80107698:	e8 b6 e1 ff ff       	call   80105853 <acquire>
      ticks++;
8010769d:	a1 00 6b 11 80       	mov    0x80116b00,%eax
801076a2:	83 c0 01             	add    $0x1,%eax
801076a5:	a3 00 6b 11 80       	mov    %eax,0x80116b00
      wakeup(&ticks);
801076aa:	c7 04 24 00 6b 11 80 	movl   $0x80116b00,(%esp)
801076b1:	e8 9d de ff ff       	call   80105553 <wakeup>
      release(&tickslock);
801076b6:	c7 04 24 c0 62 11 80 	movl   $0x801162c0,(%esp)
801076bd:	e8 2c e2 ff ff       	call   801058ee <release>
    }
    lapiceoi();
801076c2:	e8 b6 bd ff ff       	call   8010347d <lapiceoi>
    break;
801076c7:	e9 41 01 00 00       	jmp    8010780d <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
801076cc:	e8 26 b0 ff ff       	call   801026f7 <ideintr>
    lapiceoi();
801076d1:	e8 a7 bd ff ff       	call   8010347d <lapiceoi>
    break;
801076d6:	e9 32 01 00 00       	jmp    8010780d <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
801076db:	e8 7b bb ff ff       	call   8010325b <kbdintr>
    lapiceoi();
801076e0:	e8 98 bd ff ff       	call   8010347d <lapiceoi>
    break;
801076e5:	e9 23 01 00 00       	jmp    8010780d <trap+0x1f6>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
801076ea:	e8 a9 03 00 00       	call   80107a98 <uartintr>
    lapiceoi();
801076ef:	e8 89 bd ff ff       	call   8010347d <lapiceoi>
    break;
801076f4:	e9 14 01 00 00       	jmp    8010780d <trap+0x1f6>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
            cpu->id, tf->cs, tf->eip);
801076f9:	8b 45 08             	mov    0x8(%ebp),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801076fc:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
801076ff:	8b 45 08             	mov    0x8(%ebp),%eax
80107702:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80107706:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
80107709:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010770f:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80107712:	0f b6 c0             	movzbl %al,%eax
80107715:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80107719:	89 54 24 08          	mov    %edx,0x8(%esp)
8010771d:	89 44 24 04          	mov    %eax,0x4(%esp)
80107721:	c7 04 24 e0 98 10 80 	movl   $0x801098e0,(%esp)
80107728:	e8 74 8c ff ff       	call   801003a1 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
8010772d:	e8 4b bd ff ff       	call   8010347d <lapiceoi>
    break;
80107732:	e9 d6 00 00 00       	jmp    8010780d <trap+0x1f6>
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
80107737:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010773d:	85 c0                	test   %eax,%eax
8010773f:	74 11                	je     80107752 <trap+0x13b>
80107741:	8b 45 08             	mov    0x8(%ebp),%eax
80107744:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80107748:	0f b7 c0             	movzwl %ax,%eax
8010774b:	83 e0 03             	and    $0x3,%eax
8010774e:	85 c0                	test   %eax,%eax
80107750:	75 46                	jne    80107798 <trap+0x181>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80107752:	e8 1a fd ff ff       	call   80107471 <rcr2>
              tf->trapno, cpu->id, tf->eip, rcr2());
80107757:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
8010775a:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
8010775d:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107764:	0f b6 12             	movzbl (%edx),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80107767:	0f b6 ca             	movzbl %dl,%ecx
              tf->trapno, cpu->id, tf->eip, rcr2());
8010776a:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
8010776d:	8b 52 30             	mov    0x30(%edx),%edx
80107770:	89 44 24 10          	mov    %eax,0x10(%esp)
80107774:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
80107778:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010777c:	89 54 24 04          	mov    %edx,0x4(%esp)
80107780:	c7 04 24 04 99 10 80 	movl   $0x80109904,(%esp)
80107787:	e8 15 8c ff ff       	call   801003a1 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
8010778c:	c7 04 24 36 99 10 80 	movl   $0x80109936,(%esp)
80107793:	e8 a5 8d ff ff       	call   8010053d <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107798:	e8 d4 fc ff ff       	call   80107471 <rcr2>
8010779d:	89 c2                	mov    %eax,%edx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
8010779f:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801077a2:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801077a5:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801077ab:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801077ae:	0f b6 f0             	movzbl %al,%esi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801077b1:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801077b4:	8b 58 34             	mov    0x34(%eax),%ebx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801077b7:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801077ba:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801077bd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801077c3:	83 c0 6c             	add    $0x6c,%eax
801077c6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801077c9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801077cf:	8b 40 10             	mov    0x10(%eax),%eax
801077d2:	89 54 24 1c          	mov    %edx,0x1c(%esp)
801077d6:	89 7c 24 18          	mov    %edi,0x18(%esp)
801077da:	89 74 24 14          	mov    %esi,0x14(%esp)
801077de:	89 5c 24 10          	mov    %ebx,0x10(%esp)
801077e2:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
801077e6:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801077e9:	89 54 24 08          	mov    %edx,0x8(%esp)
801077ed:	89 44 24 04          	mov    %eax,0x4(%esp)
801077f1:	c7 04 24 3c 99 10 80 	movl   $0x8010993c,(%esp)
801077f8:	e8 a4 8b ff ff       	call   801003a1 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
801077fd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107803:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
8010780a:	eb 01                	jmp    8010780d <trap+0x1f6>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
8010780c:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
8010780d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107813:	85 c0                	test   %eax,%eax
80107815:	74 24                	je     8010783b <trap+0x224>
80107817:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010781d:	8b 40 24             	mov    0x24(%eax),%eax
80107820:	85 c0                	test   %eax,%eax
80107822:	74 17                	je     8010783b <trap+0x224>
80107824:	8b 45 08             	mov    0x8(%ebp),%eax
80107827:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
8010782b:	0f b7 c0             	movzwl %ax,%eax
8010782e:	83 e0 03             	and    $0x3,%eax
80107831:	83 f8 03             	cmp    $0x3,%eax
80107834:	75 05                	jne    8010783b <trap+0x224>
    exit();
80107836:	e8 63 d7 ff ff       	call   80104f9e <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
8010783b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107841:	85 c0                	test   %eax,%eax
80107843:	74 1e                	je     80107863 <trap+0x24c>
80107845:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010784b:	8b 40 0c             	mov    0xc(%eax),%eax
8010784e:	83 f8 04             	cmp    $0x4,%eax
80107851:	75 10                	jne    80107863 <trap+0x24c>
80107853:	8b 45 08             	mov    0x8(%ebp),%eax
80107856:	8b 40 30             	mov    0x30(%eax),%eax
80107859:	83 f8 20             	cmp    $0x20,%eax
8010785c:	75 05                	jne    80107863 <trap+0x24c>
    yield();
8010785e:	e8 56 db ff ff       	call   801053b9 <yield>

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80107863:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107869:	85 c0                	test   %eax,%eax
8010786b:	74 27                	je     80107894 <trap+0x27d>
8010786d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107873:	8b 40 24             	mov    0x24(%eax),%eax
80107876:	85 c0                	test   %eax,%eax
80107878:	74 1a                	je     80107894 <trap+0x27d>
8010787a:	8b 45 08             	mov    0x8(%ebp),%eax
8010787d:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80107881:	0f b7 c0             	movzwl %ax,%eax
80107884:	83 e0 03             	and    $0x3,%eax
80107887:	83 f8 03             	cmp    $0x3,%eax
8010788a:	75 08                	jne    80107894 <trap+0x27d>
    exit();
8010788c:	e8 0d d7 ff ff       	call   80104f9e <exit>
80107891:	eb 01                	jmp    80107894 <trap+0x27d>
      exit();
    proc->tf = tf;
    syscall();
    if(proc->killed)
      exit();
    return;
80107893:	90                   	nop
    yield();

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
    exit();
}
80107894:	83 c4 3c             	add    $0x3c,%esp
80107897:	5b                   	pop    %ebx
80107898:	5e                   	pop    %esi
80107899:	5f                   	pop    %edi
8010789a:	5d                   	pop    %ebp
8010789b:	c3                   	ret    

8010789c <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
8010789c:	55                   	push   %ebp
8010789d:	89 e5                	mov    %esp,%ebp
8010789f:	53                   	push   %ebx
801078a0:	83 ec 14             	sub    $0x14,%esp
801078a3:	8b 45 08             	mov    0x8(%ebp),%eax
801078a6:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801078aa:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
801078ae:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
801078b2:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
801078b6:	ec                   	in     (%dx),%al
801078b7:	89 c3                	mov    %eax,%ebx
801078b9:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
801078bc:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
801078c0:	83 c4 14             	add    $0x14,%esp
801078c3:	5b                   	pop    %ebx
801078c4:	5d                   	pop    %ebp
801078c5:	c3                   	ret    

801078c6 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801078c6:	55                   	push   %ebp
801078c7:	89 e5                	mov    %esp,%ebp
801078c9:	83 ec 08             	sub    $0x8,%esp
801078cc:	8b 55 08             	mov    0x8(%ebp),%edx
801078cf:	8b 45 0c             	mov    0xc(%ebp),%eax
801078d2:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801078d6:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801078d9:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801078dd:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801078e1:	ee                   	out    %al,(%dx)
}
801078e2:	c9                   	leave  
801078e3:	c3                   	ret    

801078e4 <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
801078e4:	55                   	push   %ebp
801078e5:	89 e5                	mov    %esp,%ebp
801078e7:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
801078ea:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801078f1:	00 
801078f2:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
801078f9:	e8 c8 ff ff ff       	call   801078c6 <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
801078fe:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
80107905:	00 
80107906:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
8010790d:	e8 b4 ff ff ff       	call   801078c6 <outb>
  outb(COM1+0, 115200/9600);
80107912:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
80107919:	00 
8010791a:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107921:	e8 a0 ff ff ff       	call   801078c6 <outb>
  outb(COM1+1, 0);
80107926:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010792d:	00 
8010792e:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80107935:	e8 8c ff ff ff       	call   801078c6 <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
8010793a:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80107941:	00 
80107942:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80107949:	e8 78 ff ff ff       	call   801078c6 <outb>
  outb(COM1+4, 0);
8010794e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107955:	00 
80107956:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
8010795d:	e8 64 ff ff ff       	call   801078c6 <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
80107962:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80107969:	00 
8010796a:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80107971:	e8 50 ff ff ff       	call   801078c6 <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
80107976:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
8010797d:	e8 1a ff ff ff       	call   8010789c <inb>
80107982:	3c ff                	cmp    $0xff,%al
80107984:	74 6c                	je     801079f2 <uartinit+0x10e>
    return;
  uart = 1;
80107986:	c7 05 74 c6 10 80 01 	movl   $0x1,0x8010c674
8010798d:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
80107990:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80107997:	e8 00 ff ff ff       	call   8010789c <inb>
  inb(COM1+0);
8010799c:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
801079a3:	e8 f4 fe ff ff       	call   8010789c <inb>
  picenable(IRQ_COM1);
801079a8:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
801079af:	e8 a1 c6 ff ff       	call   80104055 <picenable>
  ioapicenable(IRQ_COM1, 0);
801079b4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801079bb:	00 
801079bc:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
801079c3:	e8 b2 af ff ff       	call   8010297a <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
801079c8:	c7 45 f4 00 9a 10 80 	movl   $0x80109a00,-0xc(%ebp)
801079cf:	eb 15                	jmp    801079e6 <uartinit+0x102>
    uartputc(*p);
801079d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079d4:	0f b6 00             	movzbl (%eax),%eax
801079d7:	0f be c0             	movsbl %al,%eax
801079da:	89 04 24             	mov    %eax,(%esp)
801079dd:	e8 13 00 00 00       	call   801079f5 <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
801079e2:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801079e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079e9:	0f b6 00             	movzbl (%eax),%eax
801079ec:	84 c0                	test   %al,%al
801079ee:	75 e1                	jne    801079d1 <uartinit+0xed>
801079f0:	eb 01                	jmp    801079f3 <uartinit+0x10f>
  outb(COM1+4, 0);
  outb(COM1+1, 0x01);    // Enable receive interrupts.

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
    return;
801079f2:	90                   	nop
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
    uartputc(*p);
}
801079f3:	c9                   	leave  
801079f4:	c3                   	ret    

801079f5 <uartputc>:

void
uartputc(int c)
{
801079f5:	55                   	push   %ebp
801079f6:	89 e5                	mov    %esp,%ebp
801079f8:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
801079fb:	a1 74 c6 10 80       	mov    0x8010c674,%eax
80107a00:	85 c0                	test   %eax,%eax
80107a02:	74 4d                	je     80107a51 <uartputc+0x5c>
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80107a04:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80107a0b:	eb 10                	jmp    80107a1d <uartputc+0x28>
    microdelay(10);
80107a0d:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
80107a14:	e8 89 ba ff ff       	call   801034a2 <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80107a19:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107a1d:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
80107a21:	7f 16                	jg     80107a39 <uartputc+0x44>
80107a23:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80107a2a:	e8 6d fe ff ff       	call   8010789c <inb>
80107a2f:	0f b6 c0             	movzbl %al,%eax
80107a32:	83 e0 20             	and    $0x20,%eax
80107a35:	85 c0                	test   %eax,%eax
80107a37:	74 d4                	je     80107a0d <uartputc+0x18>
    microdelay(10);
  outb(COM1+0, c);
80107a39:	8b 45 08             	mov    0x8(%ebp),%eax
80107a3c:	0f b6 c0             	movzbl %al,%eax
80107a3f:	89 44 24 04          	mov    %eax,0x4(%esp)
80107a43:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107a4a:	e8 77 fe ff ff       	call   801078c6 <outb>
80107a4f:	eb 01                	jmp    80107a52 <uartputc+0x5d>
uartputc(int c)
{
  int i;

  if(!uart)
    return;
80107a51:	90                   	nop
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
    microdelay(10);
  outb(COM1+0, c);
}
80107a52:	c9                   	leave  
80107a53:	c3                   	ret    

80107a54 <uartgetc>:

static int
uartgetc(void)
{
80107a54:	55                   	push   %ebp
80107a55:	89 e5                	mov    %esp,%ebp
80107a57:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
80107a5a:	a1 74 c6 10 80       	mov    0x8010c674,%eax
80107a5f:	85 c0                	test   %eax,%eax
80107a61:	75 07                	jne    80107a6a <uartgetc+0x16>
    return -1;
80107a63:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107a68:	eb 2c                	jmp    80107a96 <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
80107a6a:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80107a71:	e8 26 fe ff ff       	call   8010789c <inb>
80107a76:	0f b6 c0             	movzbl %al,%eax
80107a79:	83 e0 01             	and    $0x1,%eax
80107a7c:	85 c0                	test   %eax,%eax
80107a7e:	75 07                	jne    80107a87 <uartgetc+0x33>
    return -1;
80107a80:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107a85:	eb 0f                	jmp    80107a96 <uartgetc+0x42>
  return inb(COM1+0);
80107a87:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107a8e:	e8 09 fe ff ff       	call   8010789c <inb>
80107a93:	0f b6 c0             	movzbl %al,%eax
}
80107a96:	c9                   	leave  
80107a97:	c3                   	ret    

80107a98 <uartintr>:

void
uartintr(void)
{
80107a98:	55                   	push   %ebp
80107a99:	89 e5                	mov    %esp,%ebp
80107a9b:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
80107a9e:	c7 04 24 54 7a 10 80 	movl   $0x80107a54,(%esp)
80107aa5:	e8 03 8d ff ff       	call   801007ad <consoleintr>
}
80107aaa:	c9                   	leave  
80107aab:	c3                   	ret    

80107aac <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80107aac:	6a 00                	push   $0x0
  pushl $0
80107aae:	6a 00                	push   $0x0
  jmp alltraps
80107ab0:	e9 67 f9 ff ff       	jmp    8010741c <alltraps>

80107ab5 <vector1>:
.globl vector1
vector1:
  pushl $0
80107ab5:	6a 00                	push   $0x0
  pushl $1
80107ab7:	6a 01                	push   $0x1
  jmp alltraps
80107ab9:	e9 5e f9 ff ff       	jmp    8010741c <alltraps>

80107abe <vector2>:
.globl vector2
vector2:
  pushl $0
80107abe:	6a 00                	push   $0x0
  pushl $2
80107ac0:	6a 02                	push   $0x2
  jmp alltraps
80107ac2:	e9 55 f9 ff ff       	jmp    8010741c <alltraps>

80107ac7 <vector3>:
.globl vector3
vector3:
  pushl $0
80107ac7:	6a 00                	push   $0x0
  pushl $3
80107ac9:	6a 03                	push   $0x3
  jmp alltraps
80107acb:	e9 4c f9 ff ff       	jmp    8010741c <alltraps>

80107ad0 <vector4>:
.globl vector4
vector4:
  pushl $0
80107ad0:	6a 00                	push   $0x0
  pushl $4
80107ad2:	6a 04                	push   $0x4
  jmp alltraps
80107ad4:	e9 43 f9 ff ff       	jmp    8010741c <alltraps>

80107ad9 <vector5>:
.globl vector5
vector5:
  pushl $0
80107ad9:	6a 00                	push   $0x0
  pushl $5
80107adb:	6a 05                	push   $0x5
  jmp alltraps
80107add:	e9 3a f9 ff ff       	jmp    8010741c <alltraps>

80107ae2 <vector6>:
.globl vector6
vector6:
  pushl $0
80107ae2:	6a 00                	push   $0x0
  pushl $6
80107ae4:	6a 06                	push   $0x6
  jmp alltraps
80107ae6:	e9 31 f9 ff ff       	jmp    8010741c <alltraps>

80107aeb <vector7>:
.globl vector7
vector7:
  pushl $0
80107aeb:	6a 00                	push   $0x0
  pushl $7
80107aed:	6a 07                	push   $0x7
  jmp alltraps
80107aef:	e9 28 f9 ff ff       	jmp    8010741c <alltraps>

80107af4 <vector8>:
.globl vector8
vector8:
  pushl $8
80107af4:	6a 08                	push   $0x8
  jmp alltraps
80107af6:	e9 21 f9 ff ff       	jmp    8010741c <alltraps>

80107afb <vector9>:
.globl vector9
vector9:
  pushl $0
80107afb:	6a 00                	push   $0x0
  pushl $9
80107afd:	6a 09                	push   $0x9
  jmp alltraps
80107aff:	e9 18 f9 ff ff       	jmp    8010741c <alltraps>

80107b04 <vector10>:
.globl vector10
vector10:
  pushl $10
80107b04:	6a 0a                	push   $0xa
  jmp alltraps
80107b06:	e9 11 f9 ff ff       	jmp    8010741c <alltraps>

80107b0b <vector11>:
.globl vector11
vector11:
  pushl $11
80107b0b:	6a 0b                	push   $0xb
  jmp alltraps
80107b0d:	e9 0a f9 ff ff       	jmp    8010741c <alltraps>

80107b12 <vector12>:
.globl vector12
vector12:
  pushl $12
80107b12:	6a 0c                	push   $0xc
  jmp alltraps
80107b14:	e9 03 f9 ff ff       	jmp    8010741c <alltraps>

80107b19 <vector13>:
.globl vector13
vector13:
  pushl $13
80107b19:	6a 0d                	push   $0xd
  jmp alltraps
80107b1b:	e9 fc f8 ff ff       	jmp    8010741c <alltraps>

80107b20 <vector14>:
.globl vector14
vector14:
  pushl $14
80107b20:	6a 0e                	push   $0xe
  jmp alltraps
80107b22:	e9 f5 f8 ff ff       	jmp    8010741c <alltraps>

80107b27 <vector15>:
.globl vector15
vector15:
  pushl $0
80107b27:	6a 00                	push   $0x0
  pushl $15
80107b29:	6a 0f                	push   $0xf
  jmp alltraps
80107b2b:	e9 ec f8 ff ff       	jmp    8010741c <alltraps>

80107b30 <vector16>:
.globl vector16
vector16:
  pushl $0
80107b30:	6a 00                	push   $0x0
  pushl $16
80107b32:	6a 10                	push   $0x10
  jmp alltraps
80107b34:	e9 e3 f8 ff ff       	jmp    8010741c <alltraps>

80107b39 <vector17>:
.globl vector17
vector17:
  pushl $17
80107b39:	6a 11                	push   $0x11
  jmp alltraps
80107b3b:	e9 dc f8 ff ff       	jmp    8010741c <alltraps>

80107b40 <vector18>:
.globl vector18
vector18:
  pushl $0
80107b40:	6a 00                	push   $0x0
  pushl $18
80107b42:	6a 12                	push   $0x12
  jmp alltraps
80107b44:	e9 d3 f8 ff ff       	jmp    8010741c <alltraps>

80107b49 <vector19>:
.globl vector19
vector19:
  pushl $0
80107b49:	6a 00                	push   $0x0
  pushl $19
80107b4b:	6a 13                	push   $0x13
  jmp alltraps
80107b4d:	e9 ca f8 ff ff       	jmp    8010741c <alltraps>

80107b52 <vector20>:
.globl vector20
vector20:
  pushl $0
80107b52:	6a 00                	push   $0x0
  pushl $20
80107b54:	6a 14                	push   $0x14
  jmp alltraps
80107b56:	e9 c1 f8 ff ff       	jmp    8010741c <alltraps>

80107b5b <vector21>:
.globl vector21
vector21:
  pushl $0
80107b5b:	6a 00                	push   $0x0
  pushl $21
80107b5d:	6a 15                	push   $0x15
  jmp alltraps
80107b5f:	e9 b8 f8 ff ff       	jmp    8010741c <alltraps>

80107b64 <vector22>:
.globl vector22
vector22:
  pushl $0
80107b64:	6a 00                	push   $0x0
  pushl $22
80107b66:	6a 16                	push   $0x16
  jmp alltraps
80107b68:	e9 af f8 ff ff       	jmp    8010741c <alltraps>

80107b6d <vector23>:
.globl vector23
vector23:
  pushl $0
80107b6d:	6a 00                	push   $0x0
  pushl $23
80107b6f:	6a 17                	push   $0x17
  jmp alltraps
80107b71:	e9 a6 f8 ff ff       	jmp    8010741c <alltraps>

80107b76 <vector24>:
.globl vector24
vector24:
  pushl $0
80107b76:	6a 00                	push   $0x0
  pushl $24
80107b78:	6a 18                	push   $0x18
  jmp alltraps
80107b7a:	e9 9d f8 ff ff       	jmp    8010741c <alltraps>

80107b7f <vector25>:
.globl vector25
vector25:
  pushl $0
80107b7f:	6a 00                	push   $0x0
  pushl $25
80107b81:	6a 19                	push   $0x19
  jmp alltraps
80107b83:	e9 94 f8 ff ff       	jmp    8010741c <alltraps>

80107b88 <vector26>:
.globl vector26
vector26:
  pushl $0
80107b88:	6a 00                	push   $0x0
  pushl $26
80107b8a:	6a 1a                	push   $0x1a
  jmp alltraps
80107b8c:	e9 8b f8 ff ff       	jmp    8010741c <alltraps>

80107b91 <vector27>:
.globl vector27
vector27:
  pushl $0
80107b91:	6a 00                	push   $0x0
  pushl $27
80107b93:	6a 1b                	push   $0x1b
  jmp alltraps
80107b95:	e9 82 f8 ff ff       	jmp    8010741c <alltraps>

80107b9a <vector28>:
.globl vector28
vector28:
  pushl $0
80107b9a:	6a 00                	push   $0x0
  pushl $28
80107b9c:	6a 1c                	push   $0x1c
  jmp alltraps
80107b9e:	e9 79 f8 ff ff       	jmp    8010741c <alltraps>

80107ba3 <vector29>:
.globl vector29
vector29:
  pushl $0
80107ba3:	6a 00                	push   $0x0
  pushl $29
80107ba5:	6a 1d                	push   $0x1d
  jmp alltraps
80107ba7:	e9 70 f8 ff ff       	jmp    8010741c <alltraps>

80107bac <vector30>:
.globl vector30
vector30:
  pushl $0
80107bac:	6a 00                	push   $0x0
  pushl $30
80107bae:	6a 1e                	push   $0x1e
  jmp alltraps
80107bb0:	e9 67 f8 ff ff       	jmp    8010741c <alltraps>

80107bb5 <vector31>:
.globl vector31
vector31:
  pushl $0
80107bb5:	6a 00                	push   $0x0
  pushl $31
80107bb7:	6a 1f                	push   $0x1f
  jmp alltraps
80107bb9:	e9 5e f8 ff ff       	jmp    8010741c <alltraps>

80107bbe <vector32>:
.globl vector32
vector32:
  pushl $0
80107bbe:	6a 00                	push   $0x0
  pushl $32
80107bc0:	6a 20                	push   $0x20
  jmp alltraps
80107bc2:	e9 55 f8 ff ff       	jmp    8010741c <alltraps>

80107bc7 <vector33>:
.globl vector33
vector33:
  pushl $0
80107bc7:	6a 00                	push   $0x0
  pushl $33
80107bc9:	6a 21                	push   $0x21
  jmp alltraps
80107bcb:	e9 4c f8 ff ff       	jmp    8010741c <alltraps>

80107bd0 <vector34>:
.globl vector34
vector34:
  pushl $0
80107bd0:	6a 00                	push   $0x0
  pushl $34
80107bd2:	6a 22                	push   $0x22
  jmp alltraps
80107bd4:	e9 43 f8 ff ff       	jmp    8010741c <alltraps>

80107bd9 <vector35>:
.globl vector35
vector35:
  pushl $0
80107bd9:	6a 00                	push   $0x0
  pushl $35
80107bdb:	6a 23                	push   $0x23
  jmp alltraps
80107bdd:	e9 3a f8 ff ff       	jmp    8010741c <alltraps>

80107be2 <vector36>:
.globl vector36
vector36:
  pushl $0
80107be2:	6a 00                	push   $0x0
  pushl $36
80107be4:	6a 24                	push   $0x24
  jmp alltraps
80107be6:	e9 31 f8 ff ff       	jmp    8010741c <alltraps>

80107beb <vector37>:
.globl vector37
vector37:
  pushl $0
80107beb:	6a 00                	push   $0x0
  pushl $37
80107bed:	6a 25                	push   $0x25
  jmp alltraps
80107bef:	e9 28 f8 ff ff       	jmp    8010741c <alltraps>

80107bf4 <vector38>:
.globl vector38
vector38:
  pushl $0
80107bf4:	6a 00                	push   $0x0
  pushl $38
80107bf6:	6a 26                	push   $0x26
  jmp alltraps
80107bf8:	e9 1f f8 ff ff       	jmp    8010741c <alltraps>

80107bfd <vector39>:
.globl vector39
vector39:
  pushl $0
80107bfd:	6a 00                	push   $0x0
  pushl $39
80107bff:	6a 27                	push   $0x27
  jmp alltraps
80107c01:	e9 16 f8 ff ff       	jmp    8010741c <alltraps>

80107c06 <vector40>:
.globl vector40
vector40:
  pushl $0
80107c06:	6a 00                	push   $0x0
  pushl $40
80107c08:	6a 28                	push   $0x28
  jmp alltraps
80107c0a:	e9 0d f8 ff ff       	jmp    8010741c <alltraps>

80107c0f <vector41>:
.globl vector41
vector41:
  pushl $0
80107c0f:	6a 00                	push   $0x0
  pushl $41
80107c11:	6a 29                	push   $0x29
  jmp alltraps
80107c13:	e9 04 f8 ff ff       	jmp    8010741c <alltraps>

80107c18 <vector42>:
.globl vector42
vector42:
  pushl $0
80107c18:	6a 00                	push   $0x0
  pushl $42
80107c1a:	6a 2a                	push   $0x2a
  jmp alltraps
80107c1c:	e9 fb f7 ff ff       	jmp    8010741c <alltraps>

80107c21 <vector43>:
.globl vector43
vector43:
  pushl $0
80107c21:	6a 00                	push   $0x0
  pushl $43
80107c23:	6a 2b                	push   $0x2b
  jmp alltraps
80107c25:	e9 f2 f7 ff ff       	jmp    8010741c <alltraps>

80107c2a <vector44>:
.globl vector44
vector44:
  pushl $0
80107c2a:	6a 00                	push   $0x0
  pushl $44
80107c2c:	6a 2c                	push   $0x2c
  jmp alltraps
80107c2e:	e9 e9 f7 ff ff       	jmp    8010741c <alltraps>

80107c33 <vector45>:
.globl vector45
vector45:
  pushl $0
80107c33:	6a 00                	push   $0x0
  pushl $45
80107c35:	6a 2d                	push   $0x2d
  jmp alltraps
80107c37:	e9 e0 f7 ff ff       	jmp    8010741c <alltraps>

80107c3c <vector46>:
.globl vector46
vector46:
  pushl $0
80107c3c:	6a 00                	push   $0x0
  pushl $46
80107c3e:	6a 2e                	push   $0x2e
  jmp alltraps
80107c40:	e9 d7 f7 ff ff       	jmp    8010741c <alltraps>

80107c45 <vector47>:
.globl vector47
vector47:
  pushl $0
80107c45:	6a 00                	push   $0x0
  pushl $47
80107c47:	6a 2f                	push   $0x2f
  jmp alltraps
80107c49:	e9 ce f7 ff ff       	jmp    8010741c <alltraps>

80107c4e <vector48>:
.globl vector48
vector48:
  pushl $0
80107c4e:	6a 00                	push   $0x0
  pushl $48
80107c50:	6a 30                	push   $0x30
  jmp alltraps
80107c52:	e9 c5 f7 ff ff       	jmp    8010741c <alltraps>

80107c57 <vector49>:
.globl vector49
vector49:
  pushl $0
80107c57:	6a 00                	push   $0x0
  pushl $49
80107c59:	6a 31                	push   $0x31
  jmp alltraps
80107c5b:	e9 bc f7 ff ff       	jmp    8010741c <alltraps>

80107c60 <vector50>:
.globl vector50
vector50:
  pushl $0
80107c60:	6a 00                	push   $0x0
  pushl $50
80107c62:	6a 32                	push   $0x32
  jmp alltraps
80107c64:	e9 b3 f7 ff ff       	jmp    8010741c <alltraps>

80107c69 <vector51>:
.globl vector51
vector51:
  pushl $0
80107c69:	6a 00                	push   $0x0
  pushl $51
80107c6b:	6a 33                	push   $0x33
  jmp alltraps
80107c6d:	e9 aa f7 ff ff       	jmp    8010741c <alltraps>

80107c72 <vector52>:
.globl vector52
vector52:
  pushl $0
80107c72:	6a 00                	push   $0x0
  pushl $52
80107c74:	6a 34                	push   $0x34
  jmp alltraps
80107c76:	e9 a1 f7 ff ff       	jmp    8010741c <alltraps>

80107c7b <vector53>:
.globl vector53
vector53:
  pushl $0
80107c7b:	6a 00                	push   $0x0
  pushl $53
80107c7d:	6a 35                	push   $0x35
  jmp alltraps
80107c7f:	e9 98 f7 ff ff       	jmp    8010741c <alltraps>

80107c84 <vector54>:
.globl vector54
vector54:
  pushl $0
80107c84:	6a 00                	push   $0x0
  pushl $54
80107c86:	6a 36                	push   $0x36
  jmp alltraps
80107c88:	e9 8f f7 ff ff       	jmp    8010741c <alltraps>

80107c8d <vector55>:
.globl vector55
vector55:
  pushl $0
80107c8d:	6a 00                	push   $0x0
  pushl $55
80107c8f:	6a 37                	push   $0x37
  jmp alltraps
80107c91:	e9 86 f7 ff ff       	jmp    8010741c <alltraps>

80107c96 <vector56>:
.globl vector56
vector56:
  pushl $0
80107c96:	6a 00                	push   $0x0
  pushl $56
80107c98:	6a 38                	push   $0x38
  jmp alltraps
80107c9a:	e9 7d f7 ff ff       	jmp    8010741c <alltraps>

80107c9f <vector57>:
.globl vector57
vector57:
  pushl $0
80107c9f:	6a 00                	push   $0x0
  pushl $57
80107ca1:	6a 39                	push   $0x39
  jmp alltraps
80107ca3:	e9 74 f7 ff ff       	jmp    8010741c <alltraps>

80107ca8 <vector58>:
.globl vector58
vector58:
  pushl $0
80107ca8:	6a 00                	push   $0x0
  pushl $58
80107caa:	6a 3a                	push   $0x3a
  jmp alltraps
80107cac:	e9 6b f7 ff ff       	jmp    8010741c <alltraps>

80107cb1 <vector59>:
.globl vector59
vector59:
  pushl $0
80107cb1:	6a 00                	push   $0x0
  pushl $59
80107cb3:	6a 3b                	push   $0x3b
  jmp alltraps
80107cb5:	e9 62 f7 ff ff       	jmp    8010741c <alltraps>

80107cba <vector60>:
.globl vector60
vector60:
  pushl $0
80107cba:	6a 00                	push   $0x0
  pushl $60
80107cbc:	6a 3c                	push   $0x3c
  jmp alltraps
80107cbe:	e9 59 f7 ff ff       	jmp    8010741c <alltraps>

80107cc3 <vector61>:
.globl vector61
vector61:
  pushl $0
80107cc3:	6a 00                	push   $0x0
  pushl $61
80107cc5:	6a 3d                	push   $0x3d
  jmp alltraps
80107cc7:	e9 50 f7 ff ff       	jmp    8010741c <alltraps>

80107ccc <vector62>:
.globl vector62
vector62:
  pushl $0
80107ccc:	6a 00                	push   $0x0
  pushl $62
80107cce:	6a 3e                	push   $0x3e
  jmp alltraps
80107cd0:	e9 47 f7 ff ff       	jmp    8010741c <alltraps>

80107cd5 <vector63>:
.globl vector63
vector63:
  pushl $0
80107cd5:	6a 00                	push   $0x0
  pushl $63
80107cd7:	6a 3f                	push   $0x3f
  jmp alltraps
80107cd9:	e9 3e f7 ff ff       	jmp    8010741c <alltraps>

80107cde <vector64>:
.globl vector64
vector64:
  pushl $0
80107cde:	6a 00                	push   $0x0
  pushl $64
80107ce0:	6a 40                	push   $0x40
  jmp alltraps
80107ce2:	e9 35 f7 ff ff       	jmp    8010741c <alltraps>

80107ce7 <vector65>:
.globl vector65
vector65:
  pushl $0
80107ce7:	6a 00                	push   $0x0
  pushl $65
80107ce9:	6a 41                	push   $0x41
  jmp alltraps
80107ceb:	e9 2c f7 ff ff       	jmp    8010741c <alltraps>

80107cf0 <vector66>:
.globl vector66
vector66:
  pushl $0
80107cf0:	6a 00                	push   $0x0
  pushl $66
80107cf2:	6a 42                	push   $0x42
  jmp alltraps
80107cf4:	e9 23 f7 ff ff       	jmp    8010741c <alltraps>

80107cf9 <vector67>:
.globl vector67
vector67:
  pushl $0
80107cf9:	6a 00                	push   $0x0
  pushl $67
80107cfb:	6a 43                	push   $0x43
  jmp alltraps
80107cfd:	e9 1a f7 ff ff       	jmp    8010741c <alltraps>

80107d02 <vector68>:
.globl vector68
vector68:
  pushl $0
80107d02:	6a 00                	push   $0x0
  pushl $68
80107d04:	6a 44                	push   $0x44
  jmp alltraps
80107d06:	e9 11 f7 ff ff       	jmp    8010741c <alltraps>

80107d0b <vector69>:
.globl vector69
vector69:
  pushl $0
80107d0b:	6a 00                	push   $0x0
  pushl $69
80107d0d:	6a 45                	push   $0x45
  jmp alltraps
80107d0f:	e9 08 f7 ff ff       	jmp    8010741c <alltraps>

80107d14 <vector70>:
.globl vector70
vector70:
  pushl $0
80107d14:	6a 00                	push   $0x0
  pushl $70
80107d16:	6a 46                	push   $0x46
  jmp alltraps
80107d18:	e9 ff f6 ff ff       	jmp    8010741c <alltraps>

80107d1d <vector71>:
.globl vector71
vector71:
  pushl $0
80107d1d:	6a 00                	push   $0x0
  pushl $71
80107d1f:	6a 47                	push   $0x47
  jmp alltraps
80107d21:	e9 f6 f6 ff ff       	jmp    8010741c <alltraps>

80107d26 <vector72>:
.globl vector72
vector72:
  pushl $0
80107d26:	6a 00                	push   $0x0
  pushl $72
80107d28:	6a 48                	push   $0x48
  jmp alltraps
80107d2a:	e9 ed f6 ff ff       	jmp    8010741c <alltraps>

80107d2f <vector73>:
.globl vector73
vector73:
  pushl $0
80107d2f:	6a 00                	push   $0x0
  pushl $73
80107d31:	6a 49                	push   $0x49
  jmp alltraps
80107d33:	e9 e4 f6 ff ff       	jmp    8010741c <alltraps>

80107d38 <vector74>:
.globl vector74
vector74:
  pushl $0
80107d38:	6a 00                	push   $0x0
  pushl $74
80107d3a:	6a 4a                	push   $0x4a
  jmp alltraps
80107d3c:	e9 db f6 ff ff       	jmp    8010741c <alltraps>

80107d41 <vector75>:
.globl vector75
vector75:
  pushl $0
80107d41:	6a 00                	push   $0x0
  pushl $75
80107d43:	6a 4b                	push   $0x4b
  jmp alltraps
80107d45:	e9 d2 f6 ff ff       	jmp    8010741c <alltraps>

80107d4a <vector76>:
.globl vector76
vector76:
  pushl $0
80107d4a:	6a 00                	push   $0x0
  pushl $76
80107d4c:	6a 4c                	push   $0x4c
  jmp alltraps
80107d4e:	e9 c9 f6 ff ff       	jmp    8010741c <alltraps>

80107d53 <vector77>:
.globl vector77
vector77:
  pushl $0
80107d53:	6a 00                	push   $0x0
  pushl $77
80107d55:	6a 4d                	push   $0x4d
  jmp alltraps
80107d57:	e9 c0 f6 ff ff       	jmp    8010741c <alltraps>

80107d5c <vector78>:
.globl vector78
vector78:
  pushl $0
80107d5c:	6a 00                	push   $0x0
  pushl $78
80107d5e:	6a 4e                	push   $0x4e
  jmp alltraps
80107d60:	e9 b7 f6 ff ff       	jmp    8010741c <alltraps>

80107d65 <vector79>:
.globl vector79
vector79:
  pushl $0
80107d65:	6a 00                	push   $0x0
  pushl $79
80107d67:	6a 4f                	push   $0x4f
  jmp alltraps
80107d69:	e9 ae f6 ff ff       	jmp    8010741c <alltraps>

80107d6e <vector80>:
.globl vector80
vector80:
  pushl $0
80107d6e:	6a 00                	push   $0x0
  pushl $80
80107d70:	6a 50                	push   $0x50
  jmp alltraps
80107d72:	e9 a5 f6 ff ff       	jmp    8010741c <alltraps>

80107d77 <vector81>:
.globl vector81
vector81:
  pushl $0
80107d77:	6a 00                	push   $0x0
  pushl $81
80107d79:	6a 51                	push   $0x51
  jmp alltraps
80107d7b:	e9 9c f6 ff ff       	jmp    8010741c <alltraps>

80107d80 <vector82>:
.globl vector82
vector82:
  pushl $0
80107d80:	6a 00                	push   $0x0
  pushl $82
80107d82:	6a 52                	push   $0x52
  jmp alltraps
80107d84:	e9 93 f6 ff ff       	jmp    8010741c <alltraps>

80107d89 <vector83>:
.globl vector83
vector83:
  pushl $0
80107d89:	6a 00                	push   $0x0
  pushl $83
80107d8b:	6a 53                	push   $0x53
  jmp alltraps
80107d8d:	e9 8a f6 ff ff       	jmp    8010741c <alltraps>

80107d92 <vector84>:
.globl vector84
vector84:
  pushl $0
80107d92:	6a 00                	push   $0x0
  pushl $84
80107d94:	6a 54                	push   $0x54
  jmp alltraps
80107d96:	e9 81 f6 ff ff       	jmp    8010741c <alltraps>

80107d9b <vector85>:
.globl vector85
vector85:
  pushl $0
80107d9b:	6a 00                	push   $0x0
  pushl $85
80107d9d:	6a 55                	push   $0x55
  jmp alltraps
80107d9f:	e9 78 f6 ff ff       	jmp    8010741c <alltraps>

80107da4 <vector86>:
.globl vector86
vector86:
  pushl $0
80107da4:	6a 00                	push   $0x0
  pushl $86
80107da6:	6a 56                	push   $0x56
  jmp alltraps
80107da8:	e9 6f f6 ff ff       	jmp    8010741c <alltraps>

80107dad <vector87>:
.globl vector87
vector87:
  pushl $0
80107dad:	6a 00                	push   $0x0
  pushl $87
80107daf:	6a 57                	push   $0x57
  jmp alltraps
80107db1:	e9 66 f6 ff ff       	jmp    8010741c <alltraps>

80107db6 <vector88>:
.globl vector88
vector88:
  pushl $0
80107db6:	6a 00                	push   $0x0
  pushl $88
80107db8:	6a 58                	push   $0x58
  jmp alltraps
80107dba:	e9 5d f6 ff ff       	jmp    8010741c <alltraps>

80107dbf <vector89>:
.globl vector89
vector89:
  pushl $0
80107dbf:	6a 00                	push   $0x0
  pushl $89
80107dc1:	6a 59                	push   $0x59
  jmp alltraps
80107dc3:	e9 54 f6 ff ff       	jmp    8010741c <alltraps>

80107dc8 <vector90>:
.globl vector90
vector90:
  pushl $0
80107dc8:	6a 00                	push   $0x0
  pushl $90
80107dca:	6a 5a                	push   $0x5a
  jmp alltraps
80107dcc:	e9 4b f6 ff ff       	jmp    8010741c <alltraps>

80107dd1 <vector91>:
.globl vector91
vector91:
  pushl $0
80107dd1:	6a 00                	push   $0x0
  pushl $91
80107dd3:	6a 5b                	push   $0x5b
  jmp alltraps
80107dd5:	e9 42 f6 ff ff       	jmp    8010741c <alltraps>

80107dda <vector92>:
.globl vector92
vector92:
  pushl $0
80107dda:	6a 00                	push   $0x0
  pushl $92
80107ddc:	6a 5c                	push   $0x5c
  jmp alltraps
80107dde:	e9 39 f6 ff ff       	jmp    8010741c <alltraps>

80107de3 <vector93>:
.globl vector93
vector93:
  pushl $0
80107de3:	6a 00                	push   $0x0
  pushl $93
80107de5:	6a 5d                	push   $0x5d
  jmp alltraps
80107de7:	e9 30 f6 ff ff       	jmp    8010741c <alltraps>

80107dec <vector94>:
.globl vector94
vector94:
  pushl $0
80107dec:	6a 00                	push   $0x0
  pushl $94
80107dee:	6a 5e                	push   $0x5e
  jmp alltraps
80107df0:	e9 27 f6 ff ff       	jmp    8010741c <alltraps>

80107df5 <vector95>:
.globl vector95
vector95:
  pushl $0
80107df5:	6a 00                	push   $0x0
  pushl $95
80107df7:	6a 5f                	push   $0x5f
  jmp alltraps
80107df9:	e9 1e f6 ff ff       	jmp    8010741c <alltraps>

80107dfe <vector96>:
.globl vector96
vector96:
  pushl $0
80107dfe:	6a 00                	push   $0x0
  pushl $96
80107e00:	6a 60                	push   $0x60
  jmp alltraps
80107e02:	e9 15 f6 ff ff       	jmp    8010741c <alltraps>

80107e07 <vector97>:
.globl vector97
vector97:
  pushl $0
80107e07:	6a 00                	push   $0x0
  pushl $97
80107e09:	6a 61                	push   $0x61
  jmp alltraps
80107e0b:	e9 0c f6 ff ff       	jmp    8010741c <alltraps>

80107e10 <vector98>:
.globl vector98
vector98:
  pushl $0
80107e10:	6a 00                	push   $0x0
  pushl $98
80107e12:	6a 62                	push   $0x62
  jmp alltraps
80107e14:	e9 03 f6 ff ff       	jmp    8010741c <alltraps>

80107e19 <vector99>:
.globl vector99
vector99:
  pushl $0
80107e19:	6a 00                	push   $0x0
  pushl $99
80107e1b:	6a 63                	push   $0x63
  jmp alltraps
80107e1d:	e9 fa f5 ff ff       	jmp    8010741c <alltraps>

80107e22 <vector100>:
.globl vector100
vector100:
  pushl $0
80107e22:	6a 00                	push   $0x0
  pushl $100
80107e24:	6a 64                	push   $0x64
  jmp alltraps
80107e26:	e9 f1 f5 ff ff       	jmp    8010741c <alltraps>

80107e2b <vector101>:
.globl vector101
vector101:
  pushl $0
80107e2b:	6a 00                	push   $0x0
  pushl $101
80107e2d:	6a 65                	push   $0x65
  jmp alltraps
80107e2f:	e9 e8 f5 ff ff       	jmp    8010741c <alltraps>

80107e34 <vector102>:
.globl vector102
vector102:
  pushl $0
80107e34:	6a 00                	push   $0x0
  pushl $102
80107e36:	6a 66                	push   $0x66
  jmp alltraps
80107e38:	e9 df f5 ff ff       	jmp    8010741c <alltraps>

80107e3d <vector103>:
.globl vector103
vector103:
  pushl $0
80107e3d:	6a 00                	push   $0x0
  pushl $103
80107e3f:	6a 67                	push   $0x67
  jmp alltraps
80107e41:	e9 d6 f5 ff ff       	jmp    8010741c <alltraps>

80107e46 <vector104>:
.globl vector104
vector104:
  pushl $0
80107e46:	6a 00                	push   $0x0
  pushl $104
80107e48:	6a 68                	push   $0x68
  jmp alltraps
80107e4a:	e9 cd f5 ff ff       	jmp    8010741c <alltraps>

80107e4f <vector105>:
.globl vector105
vector105:
  pushl $0
80107e4f:	6a 00                	push   $0x0
  pushl $105
80107e51:	6a 69                	push   $0x69
  jmp alltraps
80107e53:	e9 c4 f5 ff ff       	jmp    8010741c <alltraps>

80107e58 <vector106>:
.globl vector106
vector106:
  pushl $0
80107e58:	6a 00                	push   $0x0
  pushl $106
80107e5a:	6a 6a                	push   $0x6a
  jmp alltraps
80107e5c:	e9 bb f5 ff ff       	jmp    8010741c <alltraps>

80107e61 <vector107>:
.globl vector107
vector107:
  pushl $0
80107e61:	6a 00                	push   $0x0
  pushl $107
80107e63:	6a 6b                	push   $0x6b
  jmp alltraps
80107e65:	e9 b2 f5 ff ff       	jmp    8010741c <alltraps>

80107e6a <vector108>:
.globl vector108
vector108:
  pushl $0
80107e6a:	6a 00                	push   $0x0
  pushl $108
80107e6c:	6a 6c                	push   $0x6c
  jmp alltraps
80107e6e:	e9 a9 f5 ff ff       	jmp    8010741c <alltraps>

80107e73 <vector109>:
.globl vector109
vector109:
  pushl $0
80107e73:	6a 00                	push   $0x0
  pushl $109
80107e75:	6a 6d                	push   $0x6d
  jmp alltraps
80107e77:	e9 a0 f5 ff ff       	jmp    8010741c <alltraps>

80107e7c <vector110>:
.globl vector110
vector110:
  pushl $0
80107e7c:	6a 00                	push   $0x0
  pushl $110
80107e7e:	6a 6e                	push   $0x6e
  jmp alltraps
80107e80:	e9 97 f5 ff ff       	jmp    8010741c <alltraps>

80107e85 <vector111>:
.globl vector111
vector111:
  pushl $0
80107e85:	6a 00                	push   $0x0
  pushl $111
80107e87:	6a 6f                	push   $0x6f
  jmp alltraps
80107e89:	e9 8e f5 ff ff       	jmp    8010741c <alltraps>

80107e8e <vector112>:
.globl vector112
vector112:
  pushl $0
80107e8e:	6a 00                	push   $0x0
  pushl $112
80107e90:	6a 70                	push   $0x70
  jmp alltraps
80107e92:	e9 85 f5 ff ff       	jmp    8010741c <alltraps>

80107e97 <vector113>:
.globl vector113
vector113:
  pushl $0
80107e97:	6a 00                	push   $0x0
  pushl $113
80107e99:	6a 71                	push   $0x71
  jmp alltraps
80107e9b:	e9 7c f5 ff ff       	jmp    8010741c <alltraps>

80107ea0 <vector114>:
.globl vector114
vector114:
  pushl $0
80107ea0:	6a 00                	push   $0x0
  pushl $114
80107ea2:	6a 72                	push   $0x72
  jmp alltraps
80107ea4:	e9 73 f5 ff ff       	jmp    8010741c <alltraps>

80107ea9 <vector115>:
.globl vector115
vector115:
  pushl $0
80107ea9:	6a 00                	push   $0x0
  pushl $115
80107eab:	6a 73                	push   $0x73
  jmp alltraps
80107ead:	e9 6a f5 ff ff       	jmp    8010741c <alltraps>

80107eb2 <vector116>:
.globl vector116
vector116:
  pushl $0
80107eb2:	6a 00                	push   $0x0
  pushl $116
80107eb4:	6a 74                	push   $0x74
  jmp alltraps
80107eb6:	e9 61 f5 ff ff       	jmp    8010741c <alltraps>

80107ebb <vector117>:
.globl vector117
vector117:
  pushl $0
80107ebb:	6a 00                	push   $0x0
  pushl $117
80107ebd:	6a 75                	push   $0x75
  jmp alltraps
80107ebf:	e9 58 f5 ff ff       	jmp    8010741c <alltraps>

80107ec4 <vector118>:
.globl vector118
vector118:
  pushl $0
80107ec4:	6a 00                	push   $0x0
  pushl $118
80107ec6:	6a 76                	push   $0x76
  jmp alltraps
80107ec8:	e9 4f f5 ff ff       	jmp    8010741c <alltraps>

80107ecd <vector119>:
.globl vector119
vector119:
  pushl $0
80107ecd:	6a 00                	push   $0x0
  pushl $119
80107ecf:	6a 77                	push   $0x77
  jmp alltraps
80107ed1:	e9 46 f5 ff ff       	jmp    8010741c <alltraps>

80107ed6 <vector120>:
.globl vector120
vector120:
  pushl $0
80107ed6:	6a 00                	push   $0x0
  pushl $120
80107ed8:	6a 78                	push   $0x78
  jmp alltraps
80107eda:	e9 3d f5 ff ff       	jmp    8010741c <alltraps>

80107edf <vector121>:
.globl vector121
vector121:
  pushl $0
80107edf:	6a 00                	push   $0x0
  pushl $121
80107ee1:	6a 79                	push   $0x79
  jmp alltraps
80107ee3:	e9 34 f5 ff ff       	jmp    8010741c <alltraps>

80107ee8 <vector122>:
.globl vector122
vector122:
  pushl $0
80107ee8:	6a 00                	push   $0x0
  pushl $122
80107eea:	6a 7a                	push   $0x7a
  jmp alltraps
80107eec:	e9 2b f5 ff ff       	jmp    8010741c <alltraps>

80107ef1 <vector123>:
.globl vector123
vector123:
  pushl $0
80107ef1:	6a 00                	push   $0x0
  pushl $123
80107ef3:	6a 7b                	push   $0x7b
  jmp alltraps
80107ef5:	e9 22 f5 ff ff       	jmp    8010741c <alltraps>

80107efa <vector124>:
.globl vector124
vector124:
  pushl $0
80107efa:	6a 00                	push   $0x0
  pushl $124
80107efc:	6a 7c                	push   $0x7c
  jmp alltraps
80107efe:	e9 19 f5 ff ff       	jmp    8010741c <alltraps>

80107f03 <vector125>:
.globl vector125
vector125:
  pushl $0
80107f03:	6a 00                	push   $0x0
  pushl $125
80107f05:	6a 7d                	push   $0x7d
  jmp alltraps
80107f07:	e9 10 f5 ff ff       	jmp    8010741c <alltraps>

80107f0c <vector126>:
.globl vector126
vector126:
  pushl $0
80107f0c:	6a 00                	push   $0x0
  pushl $126
80107f0e:	6a 7e                	push   $0x7e
  jmp alltraps
80107f10:	e9 07 f5 ff ff       	jmp    8010741c <alltraps>

80107f15 <vector127>:
.globl vector127
vector127:
  pushl $0
80107f15:	6a 00                	push   $0x0
  pushl $127
80107f17:	6a 7f                	push   $0x7f
  jmp alltraps
80107f19:	e9 fe f4 ff ff       	jmp    8010741c <alltraps>

80107f1e <vector128>:
.globl vector128
vector128:
  pushl $0
80107f1e:	6a 00                	push   $0x0
  pushl $128
80107f20:	68 80 00 00 00       	push   $0x80
  jmp alltraps
80107f25:	e9 f2 f4 ff ff       	jmp    8010741c <alltraps>

80107f2a <vector129>:
.globl vector129
vector129:
  pushl $0
80107f2a:	6a 00                	push   $0x0
  pushl $129
80107f2c:	68 81 00 00 00       	push   $0x81
  jmp alltraps
80107f31:	e9 e6 f4 ff ff       	jmp    8010741c <alltraps>

80107f36 <vector130>:
.globl vector130
vector130:
  pushl $0
80107f36:	6a 00                	push   $0x0
  pushl $130
80107f38:	68 82 00 00 00       	push   $0x82
  jmp alltraps
80107f3d:	e9 da f4 ff ff       	jmp    8010741c <alltraps>

80107f42 <vector131>:
.globl vector131
vector131:
  pushl $0
80107f42:	6a 00                	push   $0x0
  pushl $131
80107f44:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80107f49:	e9 ce f4 ff ff       	jmp    8010741c <alltraps>

80107f4e <vector132>:
.globl vector132
vector132:
  pushl $0
80107f4e:	6a 00                	push   $0x0
  pushl $132
80107f50:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80107f55:	e9 c2 f4 ff ff       	jmp    8010741c <alltraps>

80107f5a <vector133>:
.globl vector133
vector133:
  pushl $0
80107f5a:	6a 00                	push   $0x0
  pushl $133
80107f5c:	68 85 00 00 00       	push   $0x85
  jmp alltraps
80107f61:	e9 b6 f4 ff ff       	jmp    8010741c <alltraps>

80107f66 <vector134>:
.globl vector134
vector134:
  pushl $0
80107f66:	6a 00                	push   $0x0
  pushl $134
80107f68:	68 86 00 00 00       	push   $0x86
  jmp alltraps
80107f6d:	e9 aa f4 ff ff       	jmp    8010741c <alltraps>

80107f72 <vector135>:
.globl vector135
vector135:
  pushl $0
80107f72:	6a 00                	push   $0x0
  pushl $135
80107f74:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80107f79:	e9 9e f4 ff ff       	jmp    8010741c <alltraps>

80107f7e <vector136>:
.globl vector136
vector136:
  pushl $0
80107f7e:	6a 00                	push   $0x0
  pushl $136
80107f80:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80107f85:	e9 92 f4 ff ff       	jmp    8010741c <alltraps>

80107f8a <vector137>:
.globl vector137
vector137:
  pushl $0
80107f8a:	6a 00                	push   $0x0
  pushl $137
80107f8c:	68 89 00 00 00       	push   $0x89
  jmp alltraps
80107f91:	e9 86 f4 ff ff       	jmp    8010741c <alltraps>

80107f96 <vector138>:
.globl vector138
vector138:
  pushl $0
80107f96:	6a 00                	push   $0x0
  pushl $138
80107f98:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80107f9d:	e9 7a f4 ff ff       	jmp    8010741c <alltraps>

80107fa2 <vector139>:
.globl vector139
vector139:
  pushl $0
80107fa2:	6a 00                	push   $0x0
  pushl $139
80107fa4:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80107fa9:	e9 6e f4 ff ff       	jmp    8010741c <alltraps>

80107fae <vector140>:
.globl vector140
vector140:
  pushl $0
80107fae:	6a 00                	push   $0x0
  pushl $140
80107fb0:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
80107fb5:	e9 62 f4 ff ff       	jmp    8010741c <alltraps>

80107fba <vector141>:
.globl vector141
vector141:
  pushl $0
80107fba:	6a 00                	push   $0x0
  pushl $141
80107fbc:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80107fc1:	e9 56 f4 ff ff       	jmp    8010741c <alltraps>

80107fc6 <vector142>:
.globl vector142
vector142:
  pushl $0
80107fc6:	6a 00                	push   $0x0
  pushl $142
80107fc8:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80107fcd:	e9 4a f4 ff ff       	jmp    8010741c <alltraps>

80107fd2 <vector143>:
.globl vector143
vector143:
  pushl $0
80107fd2:	6a 00                	push   $0x0
  pushl $143
80107fd4:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80107fd9:	e9 3e f4 ff ff       	jmp    8010741c <alltraps>

80107fde <vector144>:
.globl vector144
vector144:
  pushl $0
80107fde:	6a 00                	push   $0x0
  pushl $144
80107fe0:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80107fe5:	e9 32 f4 ff ff       	jmp    8010741c <alltraps>

80107fea <vector145>:
.globl vector145
vector145:
  pushl $0
80107fea:	6a 00                	push   $0x0
  pushl $145
80107fec:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80107ff1:	e9 26 f4 ff ff       	jmp    8010741c <alltraps>

80107ff6 <vector146>:
.globl vector146
vector146:
  pushl $0
80107ff6:	6a 00                	push   $0x0
  pushl $146
80107ff8:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80107ffd:	e9 1a f4 ff ff       	jmp    8010741c <alltraps>

80108002 <vector147>:
.globl vector147
vector147:
  pushl $0
80108002:	6a 00                	push   $0x0
  pushl $147
80108004:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80108009:	e9 0e f4 ff ff       	jmp    8010741c <alltraps>

8010800e <vector148>:
.globl vector148
vector148:
  pushl $0
8010800e:	6a 00                	push   $0x0
  pushl $148
80108010:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80108015:	e9 02 f4 ff ff       	jmp    8010741c <alltraps>

8010801a <vector149>:
.globl vector149
vector149:
  pushl $0
8010801a:	6a 00                	push   $0x0
  pushl $149
8010801c:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80108021:	e9 f6 f3 ff ff       	jmp    8010741c <alltraps>

80108026 <vector150>:
.globl vector150
vector150:
  pushl $0
80108026:	6a 00                	push   $0x0
  pushl $150
80108028:	68 96 00 00 00       	push   $0x96
  jmp alltraps
8010802d:	e9 ea f3 ff ff       	jmp    8010741c <alltraps>

80108032 <vector151>:
.globl vector151
vector151:
  pushl $0
80108032:	6a 00                	push   $0x0
  pushl $151
80108034:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80108039:	e9 de f3 ff ff       	jmp    8010741c <alltraps>

8010803e <vector152>:
.globl vector152
vector152:
  pushl $0
8010803e:	6a 00                	push   $0x0
  pushl $152
80108040:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80108045:	e9 d2 f3 ff ff       	jmp    8010741c <alltraps>

8010804a <vector153>:
.globl vector153
vector153:
  pushl $0
8010804a:	6a 00                	push   $0x0
  pushl $153
8010804c:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80108051:	e9 c6 f3 ff ff       	jmp    8010741c <alltraps>

80108056 <vector154>:
.globl vector154
vector154:
  pushl $0
80108056:	6a 00                	push   $0x0
  pushl $154
80108058:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
8010805d:	e9 ba f3 ff ff       	jmp    8010741c <alltraps>

80108062 <vector155>:
.globl vector155
vector155:
  pushl $0
80108062:	6a 00                	push   $0x0
  pushl $155
80108064:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80108069:	e9 ae f3 ff ff       	jmp    8010741c <alltraps>

8010806e <vector156>:
.globl vector156
vector156:
  pushl $0
8010806e:	6a 00                	push   $0x0
  pushl $156
80108070:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80108075:	e9 a2 f3 ff ff       	jmp    8010741c <alltraps>

8010807a <vector157>:
.globl vector157
vector157:
  pushl $0
8010807a:	6a 00                	push   $0x0
  pushl $157
8010807c:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80108081:	e9 96 f3 ff ff       	jmp    8010741c <alltraps>

80108086 <vector158>:
.globl vector158
vector158:
  pushl $0
80108086:	6a 00                	push   $0x0
  pushl $158
80108088:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
8010808d:	e9 8a f3 ff ff       	jmp    8010741c <alltraps>

80108092 <vector159>:
.globl vector159
vector159:
  pushl $0
80108092:	6a 00                	push   $0x0
  pushl $159
80108094:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80108099:	e9 7e f3 ff ff       	jmp    8010741c <alltraps>

8010809e <vector160>:
.globl vector160
vector160:
  pushl $0
8010809e:	6a 00                	push   $0x0
  pushl $160
801080a0:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
801080a5:	e9 72 f3 ff ff       	jmp    8010741c <alltraps>

801080aa <vector161>:
.globl vector161
vector161:
  pushl $0
801080aa:	6a 00                	push   $0x0
  pushl $161
801080ac:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
801080b1:	e9 66 f3 ff ff       	jmp    8010741c <alltraps>

801080b6 <vector162>:
.globl vector162
vector162:
  pushl $0
801080b6:	6a 00                	push   $0x0
  pushl $162
801080b8:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
801080bd:	e9 5a f3 ff ff       	jmp    8010741c <alltraps>

801080c2 <vector163>:
.globl vector163
vector163:
  pushl $0
801080c2:	6a 00                	push   $0x0
  pushl $163
801080c4:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
801080c9:	e9 4e f3 ff ff       	jmp    8010741c <alltraps>

801080ce <vector164>:
.globl vector164
vector164:
  pushl $0
801080ce:	6a 00                	push   $0x0
  pushl $164
801080d0:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
801080d5:	e9 42 f3 ff ff       	jmp    8010741c <alltraps>

801080da <vector165>:
.globl vector165
vector165:
  pushl $0
801080da:	6a 00                	push   $0x0
  pushl $165
801080dc:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
801080e1:	e9 36 f3 ff ff       	jmp    8010741c <alltraps>

801080e6 <vector166>:
.globl vector166
vector166:
  pushl $0
801080e6:	6a 00                	push   $0x0
  pushl $166
801080e8:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
801080ed:	e9 2a f3 ff ff       	jmp    8010741c <alltraps>

801080f2 <vector167>:
.globl vector167
vector167:
  pushl $0
801080f2:	6a 00                	push   $0x0
  pushl $167
801080f4:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
801080f9:	e9 1e f3 ff ff       	jmp    8010741c <alltraps>

801080fe <vector168>:
.globl vector168
vector168:
  pushl $0
801080fe:	6a 00                	push   $0x0
  pushl $168
80108100:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80108105:	e9 12 f3 ff ff       	jmp    8010741c <alltraps>

8010810a <vector169>:
.globl vector169
vector169:
  pushl $0
8010810a:	6a 00                	push   $0x0
  pushl $169
8010810c:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80108111:	e9 06 f3 ff ff       	jmp    8010741c <alltraps>

80108116 <vector170>:
.globl vector170
vector170:
  pushl $0
80108116:	6a 00                	push   $0x0
  pushl $170
80108118:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
8010811d:	e9 fa f2 ff ff       	jmp    8010741c <alltraps>

80108122 <vector171>:
.globl vector171
vector171:
  pushl $0
80108122:	6a 00                	push   $0x0
  pushl $171
80108124:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80108129:	e9 ee f2 ff ff       	jmp    8010741c <alltraps>

8010812e <vector172>:
.globl vector172
vector172:
  pushl $0
8010812e:	6a 00                	push   $0x0
  pushl $172
80108130:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80108135:	e9 e2 f2 ff ff       	jmp    8010741c <alltraps>

8010813a <vector173>:
.globl vector173
vector173:
  pushl $0
8010813a:	6a 00                	push   $0x0
  pushl $173
8010813c:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80108141:	e9 d6 f2 ff ff       	jmp    8010741c <alltraps>

80108146 <vector174>:
.globl vector174
vector174:
  pushl $0
80108146:	6a 00                	push   $0x0
  pushl $174
80108148:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
8010814d:	e9 ca f2 ff ff       	jmp    8010741c <alltraps>

80108152 <vector175>:
.globl vector175
vector175:
  pushl $0
80108152:	6a 00                	push   $0x0
  pushl $175
80108154:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80108159:	e9 be f2 ff ff       	jmp    8010741c <alltraps>

8010815e <vector176>:
.globl vector176
vector176:
  pushl $0
8010815e:	6a 00                	push   $0x0
  pushl $176
80108160:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80108165:	e9 b2 f2 ff ff       	jmp    8010741c <alltraps>

8010816a <vector177>:
.globl vector177
vector177:
  pushl $0
8010816a:	6a 00                	push   $0x0
  pushl $177
8010816c:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80108171:	e9 a6 f2 ff ff       	jmp    8010741c <alltraps>

80108176 <vector178>:
.globl vector178
vector178:
  pushl $0
80108176:	6a 00                	push   $0x0
  pushl $178
80108178:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
8010817d:	e9 9a f2 ff ff       	jmp    8010741c <alltraps>

80108182 <vector179>:
.globl vector179
vector179:
  pushl $0
80108182:	6a 00                	push   $0x0
  pushl $179
80108184:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80108189:	e9 8e f2 ff ff       	jmp    8010741c <alltraps>

8010818e <vector180>:
.globl vector180
vector180:
  pushl $0
8010818e:	6a 00                	push   $0x0
  pushl $180
80108190:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80108195:	e9 82 f2 ff ff       	jmp    8010741c <alltraps>

8010819a <vector181>:
.globl vector181
vector181:
  pushl $0
8010819a:	6a 00                	push   $0x0
  pushl $181
8010819c:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
801081a1:	e9 76 f2 ff ff       	jmp    8010741c <alltraps>

801081a6 <vector182>:
.globl vector182
vector182:
  pushl $0
801081a6:	6a 00                	push   $0x0
  pushl $182
801081a8:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
801081ad:	e9 6a f2 ff ff       	jmp    8010741c <alltraps>

801081b2 <vector183>:
.globl vector183
vector183:
  pushl $0
801081b2:	6a 00                	push   $0x0
  pushl $183
801081b4:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
801081b9:	e9 5e f2 ff ff       	jmp    8010741c <alltraps>

801081be <vector184>:
.globl vector184
vector184:
  pushl $0
801081be:	6a 00                	push   $0x0
  pushl $184
801081c0:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
801081c5:	e9 52 f2 ff ff       	jmp    8010741c <alltraps>

801081ca <vector185>:
.globl vector185
vector185:
  pushl $0
801081ca:	6a 00                	push   $0x0
  pushl $185
801081cc:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
801081d1:	e9 46 f2 ff ff       	jmp    8010741c <alltraps>

801081d6 <vector186>:
.globl vector186
vector186:
  pushl $0
801081d6:	6a 00                	push   $0x0
  pushl $186
801081d8:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
801081dd:	e9 3a f2 ff ff       	jmp    8010741c <alltraps>

801081e2 <vector187>:
.globl vector187
vector187:
  pushl $0
801081e2:	6a 00                	push   $0x0
  pushl $187
801081e4:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
801081e9:	e9 2e f2 ff ff       	jmp    8010741c <alltraps>

801081ee <vector188>:
.globl vector188
vector188:
  pushl $0
801081ee:	6a 00                	push   $0x0
  pushl $188
801081f0:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
801081f5:	e9 22 f2 ff ff       	jmp    8010741c <alltraps>

801081fa <vector189>:
.globl vector189
vector189:
  pushl $0
801081fa:	6a 00                	push   $0x0
  pushl $189
801081fc:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80108201:	e9 16 f2 ff ff       	jmp    8010741c <alltraps>

80108206 <vector190>:
.globl vector190
vector190:
  pushl $0
80108206:	6a 00                	push   $0x0
  pushl $190
80108208:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
8010820d:	e9 0a f2 ff ff       	jmp    8010741c <alltraps>

80108212 <vector191>:
.globl vector191
vector191:
  pushl $0
80108212:	6a 00                	push   $0x0
  pushl $191
80108214:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80108219:	e9 fe f1 ff ff       	jmp    8010741c <alltraps>

8010821e <vector192>:
.globl vector192
vector192:
  pushl $0
8010821e:	6a 00                	push   $0x0
  pushl $192
80108220:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80108225:	e9 f2 f1 ff ff       	jmp    8010741c <alltraps>

8010822a <vector193>:
.globl vector193
vector193:
  pushl $0
8010822a:	6a 00                	push   $0x0
  pushl $193
8010822c:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80108231:	e9 e6 f1 ff ff       	jmp    8010741c <alltraps>

80108236 <vector194>:
.globl vector194
vector194:
  pushl $0
80108236:	6a 00                	push   $0x0
  pushl $194
80108238:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
8010823d:	e9 da f1 ff ff       	jmp    8010741c <alltraps>

80108242 <vector195>:
.globl vector195
vector195:
  pushl $0
80108242:	6a 00                	push   $0x0
  pushl $195
80108244:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80108249:	e9 ce f1 ff ff       	jmp    8010741c <alltraps>

8010824e <vector196>:
.globl vector196
vector196:
  pushl $0
8010824e:	6a 00                	push   $0x0
  pushl $196
80108250:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80108255:	e9 c2 f1 ff ff       	jmp    8010741c <alltraps>

8010825a <vector197>:
.globl vector197
vector197:
  pushl $0
8010825a:	6a 00                	push   $0x0
  pushl $197
8010825c:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80108261:	e9 b6 f1 ff ff       	jmp    8010741c <alltraps>

80108266 <vector198>:
.globl vector198
vector198:
  pushl $0
80108266:	6a 00                	push   $0x0
  pushl $198
80108268:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
8010826d:	e9 aa f1 ff ff       	jmp    8010741c <alltraps>

80108272 <vector199>:
.globl vector199
vector199:
  pushl $0
80108272:	6a 00                	push   $0x0
  pushl $199
80108274:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80108279:	e9 9e f1 ff ff       	jmp    8010741c <alltraps>

8010827e <vector200>:
.globl vector200
vector200:
  pushl $0
8010827e:	6a 00                	push   $0x0
  pushl $200
80108280:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80108285:	e9 92 f1 ff ff       	jmp    8010741c <alltraps>

8010828a <vector201>:
.globl vector201
vector201:
  pushl $0
8010828a:	6a 00                	push   $0x0
  pushl $201
8010828c:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80108291:	e9 86 f1 ff ff       	jmp    8010741c <alltraps>

80108296 <vector202>:
.globl vector202
vector202:
  pushl $0
80108296:	6a 00                	push   $0x0
  pushl $202
80108298:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
8010829d:	e9 7a f1 ff ff       	jmp    8010741c <alltraps>

801082a2 <vector203>:
.globl vector203
vector203:
  pushl $0
801082a2:	6a 00                	push   $0x0
  pushl $203
801082a4:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
801082a9:	e9 6e f1 ff ff       	jmp    8010741c <alltraps>

801082ae <vector204>:
.globl vector204
vector204:
  pushl $0
801082ae:	6a 00                	push   $0x0
  pushl $204
801082b0:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
801082b5:	e9 62 f1 ff ff       	jmp    8010741c <alltraps>

801082ba <vector205>:
.globl vector205
vector205:
  pushl $0
801082ba:	6a 00                	push   $0x0
  pushl $205
801082bc:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
801082c1:	e9 56 f1 ff ff       	jmp    8010741c <alltraps>

801082c6 <vector206>:
.globl vector206
vector206:
  pushl $0
801082c6:	6a 00                	push   $0x0
  pushl $206
801082c8:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
801082cd:	e9 4a f1 ff ff       	jmp    8010741c <alltraps>

801082d2 <vector207>:
.globl vector207
vector207:
  pushl $0
801082d2:	6a 00                	push   $0x0
  pushl $207
801082d4:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
801082d9:	e9 3e f1 ff ff       	jmp    8010741c <alltraps>

801082de <vector208>:
.globl vector208
vector208:
  pushl $0
801082de:	6a 00                	push   $0x0
  pushl $208
801082e0:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
801082e5:	e9 32 f1 ff ff       	jmp    8010741c <alltraps>

801082ea <vector209>:
.globl vector209
vector209:
  pushl $0
801082ea:	6a 00                	push   $0x0
  pushl $209
801082ec:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
801082f1:	e9 26 f1 ff ff       	jmp    8010741c <alltraps>

801082f6 <vector210>:
.globl vector210
vector210:
  pushl $0
801082f6:	6a 00                	push   $0x0
  pushl $210
801082f8:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
801082fd:	e9 1a f1 ff ff       	jmp    8010741c <alltraps>

80108302 <vector211>:
.globl vector211
vector211:
  pushl $0
80108302:	6a 00                	push   $0x0
  pushl $211
80108304:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80108309:	e9 0e f1 ff ff       	jmp    8010741c <alltraps>

8010830e <vector212>:
.globl vector212
vector212:
  pushl $0
8010830e:	6a 00                	push   $0x0
  pushl $212
80108310:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80108315:	e9 02 f1 ff ff       	jmp    8010741c <alltraps>

8010831a <vector213>:
.globl vector213
vector213:
  pushl $0
8010831a:	6a 00                	push   $0x0
  pushl $213
8010831c:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80108321:	e9 f6 f0 ff ff       	jmp    8010741c <alltraps>

80108326 <vector214>:
.globl vector214
vector214:
  pushl $0
80108326:	6a 00                	push   $0x0
  pushl $214
80108328:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
8010832d:	e9 ea f0 ff ff       	jmp    8010741c <alltraps>

80108332 <vector215>:
.globl vector215
vector215:
  pushl $0
80108332:	6a 00                	push   $0x0
  pushl $215
80108334:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80108339:	e9 de f0 ff ff       	jmp    8010741c <alltraps>

8010833e <vector216>:
.globl vector216
vector216:
  pushl $0
8010833e:	6a 00                	push   $0x0
  pushl $216
80108340:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80108345:	e9 d2 f0 ff ff       	jmp    8010741c <alltraps>

8010834a <vector217>:
.globl vector217
vector217:
  pushl $0
8010834a:	6a 00                	push   $0x0
  pushl $217
8010834c:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80108351:	e9 c6 f0 ff ff       	jmp    8010741c <alltraps>

80108356 <vector218>:
.globl vector218
vector218:
  pushl $0
80108356:	6a 00                	push   $0x0
  pushl $218
80108358:	68 da 00 00 00       	push   $0xda
  jmp alltraps
8010835d:	e9 ba f0 ff ff       	jmp    8010741c <alltraps>

80108362 <vector219>:
.globl vector219
vector219:
  pushl $0
80108362:	6a 00                	push   $0x0
  pushl $219
80108364:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80108369:	e9 ae f0 ff ff       	jmp    8010741c <alltraps>

8010836e <vector220>:
.globl vector220
vector220:
  pushl $0
8010836e:	6a 00                	push   $0x0
  pushl $220
80108370:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80108375:	e9 a2 f0 ff ff       	jmp    8010741c <alltraps>

8010837a <vector221>:
.globl vector221
vector221:
  pushl $0
8010837a:	6a 00                	push   $0x0
  pushl $221
8010837c:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80108381:	e9 96 f0 ff ff       	jmp    8010741c <alltraps>

80108386 <vector222>:
.globl vector222
vector222:
  pushl $0
80108386:	6a 00                	push   $0x0
  pushl $222
80108388:	68 de 00 00 00       	push   $0xde
  jmp alltraps
8010838d:	e9 8a f0 ff ff       	jmp    8010741c <alltraps>

80108392 <vector223>:
.globl vector223
vector223:
  pushl $0
80108392:	6a 00                	push   $0x0
  pushl $223
80108394:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80108399:	e9 7e f0 ff ff       	jmp    8010741c <alltraps>

8010839e <vector224>:
.globl vector224
vector224:
  pushl $0
8010839e:	6a 00                	push   $0x0
  pushl $224
801083a0:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
801083a5:	e9 72 f0 ff ff       	jmp    8010741c <alltraps>

801083aa <vector225>:
.globl vector225
vector225:
  pushl $0
801083aa:	6a 00                	push   $0x0
  pushl $225
801083ac:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
801083b1:	e9 66 f0 ff ff       	jmp    8010741c <alltraps>

801083b6 <vector226>:
.globl vector226
vector226:
  pushl $0
801083b6:	6a 00                	push   $0x0
  pushl $226
801083b8:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
801083bd:	e9 5a f0 ff ff       	jmp    8010741c <alltraps>

801083c2 <vector227>:
.globl vector227
vector227:
  pushl $0
801083c2:	6a 00                	push   $0x0
  pushl $227
801083c4:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
801083c9:	e9 4e f0 ff ff       	jmp    8010741c <alltraps>

801083ce <vector228>:
.globl vector228
vector228:
  pushl $0
801083ce:	6a 00                	push   $0x0
  pushl $228
801083d0:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
801083d5:	e9 42 f0 ff ff       	jmp    8010741c <alltraps>

801083da <vector229>:
.globl vector229
vector229:
  pushl $0
801083da:	6a 00                	push   $0x0
  pushl $229
801083dc:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
801083e1:	e9 36 f0 ff ff       	jmp    8010741c <alltraps>

801083e6 <vector230>:
.globl vector230
vector230:
  pushl $0
801083e6:	6a 00                	push   $0x0
  pushl $230
801083e8:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
801083ed:	e9 2a f0 ff ff       	jmp    8010741c <alltraps>

801083f2 <vector231>:
.globl vector231
vector231:
  pushl $0
801083f2:	6a 00                	push   $0x0
  pushl $231
801083f4:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
801083f9:	e9 1e f0 ff ff       	jmp    8010741c <alltraps>

801083fe <vector232>:
.globl vector232
vector232:
  pushl $0
801083fe:	6a 00                	push   $0x0
  pushl $232
80108400:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80108405:	e9 12 f0 ff ff       	jmp    8010741c <alltraps>

8010840a <vector233>:
.globl vector233
vector233:
  pushl $0
8010840a:	6a 00                	push   $0x0
  pushl $233
8010840c:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80108411:	e9 06 f0 ff ff       	jmp    8010741c <alltraps>

80108416 <vector234>:
.globl vector234
vector234:
  pushl $0
80108416:	6a 00                	push   $0x0
  pushl $234
80108418:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
8010841d:	e9 fa ef ff ff       	jmp    8010741c <alltraps>

80108422 <vector235>:
.globl vector235
vector235:
  pushl $0
80108422:	6a 00                	push   $0x0
  pushl $235
80108424:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80108429:	e9 ee ef ff ff       	jmp    8010741c <alltraps>

8010842e <vector236>:
.globl vector236
vector236:
  pushl $0
8010842e:	6a 00                	push   $0x0
  pushl $236
80108430:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80108435:	e9 e2 ef ff ff       	jmp    8010741c <alltraps>

8010843a <vector237>:
.globl vector237
vector237:
  pushl $0
8010843a:	6a 00                	push   $0x0
  pushl $237
8010843c:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80108441:	e9 d6 ef ff ff       	jmp    8010741c <alltraps>

80108446 <vector238>:
.globl vector238
vector238:
  pushl $0
80108446:	6a 00                	push   $0x0
  pushl $238
80108448:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
8010844d:	e9 ca ef ff ff       	jmp    8010741c <alltraps>

80108452 <vector239>:
.globl vector239
vector239:
  pushl $0
80108452:	6a 00                	push   $0x0
  pushl $239
80108454:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80108459:	e9 be ef ff ff       	jmp    8010741c <alltraps>

8010845e <vector240>:
.globl vector240
vector240:
  pushl $0
8010845e:	6a 00                	push   $0x0
  pushl $240
80108460:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80108465:	e9 b2 ef ff ff       	jmp    8010741c <alltraps>

8010846a <vector241>:
.globl vector241
vector241:
  pushl $0
8010846a:	6a 00                	push   $0x0
  pushl $241
8010846c:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80108471:	e9 a6 ef ff ff       	jmp    8010741c <alltraps>

80108476 <vector242>:
.globl vector242
vector242:
  pushl $0
80108476:	6a 00                	push   $0x0
  pushl $242
80108478:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
8010847d:	e9 9a ef ff ff       	jmp    8010741c <alltraps>

80108482 <vector243>:
.globl vector243
vector243:
  pushl $0
80108482:	6a 00                	push   $0x0
  pushl $243
80108484:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80108489:	e9 8e ef ff ff       	jmp    8010741c <alltraps>

8010848e <vector244>:
.globl vector244
vector244:
  pushl $0
8010848e:	6a 00                	push   $0x0
  pushl $244
80108490:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80108495:	e9 82 ef ff ff       	jmp    8010741c <alltraps>

8010849a <vector245>:
.globl vector245
vector245:
  pushl $0
8010849a:	6a 00                	push   $0x0
  pushl $245
8010849c:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
801084a1:	e9 76 ef ff ff       	jmp    8010741c <alltraps>

801084a6 <vector246>:
.globl vector246
vector246:
  pushl $0
801084a6:	6a 00                	push   $0x0
  pushl $246
801084a8:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
801084ad:	e9 6a ef ff ff       	jmp    8010741c <alltraps>

801084b2 <vector247>:
.globl vector247
vector247:
  pushl $0
801084b2:	6a 00                	push   $0x0
  pushl $247
801084b4:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
801084b9:	e9 5e ef ff ff       	jmp    8010741c <alltraps>

801084be <vector248>:
.globl vector248
vector248:
  pushl $0
801084be:	6a 00                	push   $0x0
  pushl $248
801084c0:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
801084c5:	e9 52 ef ff ff       	jmp    8010741c <alltraps>

801084ca <vector249>:
.globl vector249
vector249:
  pushl $0
801084ca:	6a 00                	push   $0x0
  pushl $249
801084cc:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
801084d1:	e9 46 ef ff ff       	jmp    8010741c <alltraps>

801084d6 <vector250>:
.globl vector250
vector250:
  pushl $0
801084d6:	6a 00                	push   $0x0
  pushl $250
801084d8:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
801084dd:	e9 3a ef ff ff       	jmp    8010741c <alltraps>

801084e2 <vector251>:
.globl vector251
vector251:
  pushl $0
801084e2:	6a 00                	push   $0x0
  pushl $251
801084e4:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
801084e9:	e9 2e ef ff ff       	jmp    8010741c <alltraps>

801084ee <vector252>:
.globl vector252
vector252:
  pushl $0
801084ee:	6a 00                	push   $0x0
  pushl $252
801084f0:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
801084f5:	e9 22 ef ff ff       	jmp    8010741c <alltraps>

801084fa <vector253>:
.globl vector253
vector253:
  pushl $0
801084fa:	6a 00                	push   $0x0
  pushl $253
801084fc:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80108501:	e9 16 ef ff ff       	jmp    8010741c <alltraps>

80108506 <vector254>:
.globl vector254
vector254:
  pushl $0
80108506:	6a 00                	push   $0x0
  pushl $254
80108508:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
8010850d:	e9 0a ef ff ff       	jmp    8010741c <alltraps>

80108512 <vector255>:
.globl vector255
vector255:
  pushl $0
80108512:	6a 00                	push   $0x0
  pushl $255
80108514:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80108519:	e9 fe ee ff ff       	jmp    8010741c <alltraps>
	...

80108520 <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
80108520:	55                   	push   %ebp
80108521:	89 e5                	mov    %esp,%ebp
80108523:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80108526:	8b 45 0c             	mov    0xc(%ebp),%eax
80108529:	83 e8 01             	sub    $0x1,%eax
8010852c:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80108530:	8b 45 08             	mov    0x8(%ebp),%eax
80108533:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80108537:	8b 45 08             	mov    0x8(%ebp),%eax
8010853a:	c1 e8 10             	shr    $0x10,%eax
8010853d:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
80108541:	8d 45 fa             	lea    -0x6(%ebp),%eax
80108544:	0f 01 10             	lgdtl  (%eax)
}
80108547:	c9                   	leave  
80108548:	c3                   	ret    

80108549 <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
80108549:	55                   	push   %ebp
8010854a:	89 e5                	mov    %esp,%ebp
8010854c:	83 ec 04             	sub    $0x4,%esp
8010854f:	8b 45 08             	mov    0x8(%ebp),%eax
80108552:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
80108556:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
8010855a:	0f 00 d8             	ltr    %ax
}
8010855d:	c9                   	leave  
8010855e:	c3                   	ret    

8010855f <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
8010855f:	55                   	push   %ebp
80108560:	89 e5                	mov    %esp,%ebp
80108562:	83 ec 04             	sub    $0x4,%esp
80108565:	8b 45 08             	mov    0x8(%ebp),%eax
80108568:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
8010856c:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80108570:	8e e8                	mov    %eax,%gs
}
80108572:	c9                   	leave  
80108573:	c3                   	ret    

80108574 <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
80108574:	55                   	push   %ebp
80108575:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
80108577:	8b 45 08             	mov    0x8(%ebp),%eax
8010857a:	0f 22 d8             	mov    %eax,%cr3
}
8010857d:	5d                   	pop    %ebp
8010857e:	c3                   	ret    

8010857f <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
8010857f:	55                   	push   %ebp
80108580:	89 e5                	mov    %esp,%ebp
80108582:	8b 45 08             	mov    0x8(%ebp),%eax
80108585:	05 00 00 00 80       	add    $0x80000000,%eax
8010858a:	5d                   	pop    %ebp
8010858b:	c3                   	ret    

8010858c <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
8010858c:	55                   	push   %ebp
8010858d:	89 e5                	mov    %esp,%ebp
8010858f:	8b 45 08             	mov    0x8(%ebp),%eax
80108592:	05 00 00 00 80       	add    $0x80000000,%eax
80108597:	5d                   	pop    %ebp
80108598:	c3                   	ret    

80108599 <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
80108599:	55                   	push   %ebp
8010859a:	89 e5                	mov    %esp,%ebp
8010859c:	53                   	push   %ebx
8010859d:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
801085a0:	e8 7c ae ff ff       	call   80103421 <cpunum>
801085a5:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801085ab:	05 80 39 11 80       	add    $0x80113980,%eax
801085b0:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
801085b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085b6:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
801085bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085bf:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
801085c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085c8:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
801085cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085cf:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801085d3:	83 e2 f0             	and    $0xfffffff0,%edx
801085d6:	83 ca 0a             	or     $0xa,%edx
801085d9:	88 50 7d             	mov    %dl,0x7d(%eax)
801085dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085df:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801085e3:	83 ca 10             	or     $0x10,%edx
801085e6:	88 50 7d             	mov    %dl,0x7d(%eax)
801085e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085ec:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801085f0:	83 e2 9f             	and    $0xffffff9f,%edx
801085f3:	88 50 7d             	mov    %dl,0x7d(%eax)
801085f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085f9:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801085fd:	83 ca 80             	or     $0xffffff80,%edx
80108600:	88 50 7d             	mov    %dl,0x7d(%eax)
80108603:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108606:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010860a:	83 ca 0f             	or     $0xf,%edx
8010860d:	88 50 7e             	mov    %dl,0x7e(%eax)
80108610:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108613:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108617:	83 e2 ef             	and    $0xffffffef,%edx
8010861a:	88 50 7e             	mov    %dl,0x7e(%eax)
8010861d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108620:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108624:	83 e2 df             	and    $0xffffffdf,%edx
80108627:	88 50 7e             	mov    %dl,0x7e(%eax)
8010862a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010862d:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108631:	83 ca 40             	or     $0x40,%edx
80108634:	88 50 7e             	mov    %dl,0x7e(%eax)
80108637:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010863a:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010863e:	83 ca 80             	or     $0xffffff80,%edx
80108641:	88 50 7e             	mov    %dl,0x7e(%eax)
80108644:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108647:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
8010864b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010864e:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
80108655:	ff ff 
80108657:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010865a:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
80108661:	00 00 
80108663:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108666:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
8010866d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108670:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80108677:	83 e2 f0             	and    $0xfffffff0,%edx
8010867a:	83 ca 02             	or     $0x2,%edx
8010867d:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80108683:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108686:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
8010868d:	83 ca 10             	or     $0x10,%edx
80108690:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80108696:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108699:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801086a0:	83 e2 9f             	and    $0xffffff9f,%edx
801086a3:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801086a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086ac:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801086b3:	83 ca 80             	or     $0xffffff80,%edx
801086b6:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801086bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086bf:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801086c6:	83 ca 0f             	or     $0xf,%edx
801086c9:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801086cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086d2:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801086d9:	83 e2 ef             	and    $0xffffffef,%edx
801086dc:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801086e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086e5:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801086ec:	83 e2 df             	and    $0xffffffdf,%edx
801086ef:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801086f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086f8:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801086ff:	83 ca 40             	or     $0x40,%edx
80108702:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108708:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010870b:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108712:	83 ca 80             	or     $0xffffff80,%edx
80108715:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
8010871b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010871e:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80108725:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108728:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
8010872f:	ff ff 
80108731:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108734:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
8010873b:	00 00 
8010873d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108740:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
80108747:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010874a:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80108751:	83 e2 f0             	and    $0xfffffff0,%edx
80108754:	83 ca 0a             	or     $0xa,%edx
80108757:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
8010875d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108760:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80108767:	83 ca 10             	or     $0x10,%edx
8010876a:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80108770:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108773:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
8010877a:	83 ca 60             	or     $0x60,%edx
8010877d:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80108783:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108786:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
8010878d:	83 ca 80             	or     $0xffffff80,%edx
80108790:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80108796:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108799:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801087a0:	83 ca 0f             	or     $0xf,%edx
801087a3:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801087a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087ac:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801087b3:	83 e2 ef             	and    $0xffffffef,%edx
801087b6:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801087bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087bf:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801087c6:	83 e2 df             	and    $0xffffffdf,%edx
801087c9:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801087cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087d2:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801087d9:	83 ca 40             	or     $0x40,%edx
801087dc:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801087e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087e5:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801087ec:	83 ca 80             	or     $0xffffff80,%edx
801087ef:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801087f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087f8:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
801087ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108802:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
80108809:	ff ff 
8010880b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010880e:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
80108815:	00 00 
80108817:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010881a:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
80108821:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108824:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
8010882b:	83 e2 f0             	and    $0xfffffff0,%edx
8010882e:	83 ca 02             	or     $0x2,%edx
80108831:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108837:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010883a:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108841:	83 ca 10             	or     $0x10,%edx
80108844:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
8010884a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010884d:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108854:	83 ca 60             	or     $0x60,%edx
80108857:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
8010885d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108860:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108867:	83 ca 80             	or     $0xffffff80,%edx
8010886a:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108870:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108873:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
8010887a:	83 ca 0f             	or     $0xf,%edx
8010887d:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108883:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108886:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
8010888d:	83 e2 ef             	and    $0xffffffef,%edx
80108890:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108896:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108899:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801088a0:	83 e2 df             	and    $0xffffffdf,%edx
801088a3:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801088a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088ac:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801088b3:	83 ca 40             	or     $0x40,%edx
801088b6:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801088bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088bf:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801088c6:	83 ca 80             	or     $0xffffff80,%edx
801088c9:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801088cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088d2:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
801088d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088dc:	05 b4 00 00 00       	add    $0xb4,%eax
801088e1:	89 c3                	mov    %eax,%ebx
801088e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088e6:	05 b4 00 00 00       	add    $0xb4,%eax
801088eb:	c1 e8 10             	shr    $0x10,%eax
801088ee:	89 c1                	mov    %eax,%ecx
801088f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088f3:	05 b4 00 00 00       	add    $0xb4,%eax
801088f8:	c1 e8 18             	shr    $0x18,%eax
801088fb:	89 c2                	mov    %eax,%edx
801088fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108900:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
80108907:	00 00 
80108909:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010890c:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
80108913:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108916:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
8010891c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010891f:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108926:	83 e1 f0             	and    $0xfffffff0,%ecx
80108929:	83 c9 02             	or     $0x2,%ecx
8010892c:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108932:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108935:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
8010893c:	83 c9 10             	or     $0x10,%ecx
8010893f:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108945:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108948:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
8010894f:	83 e1 9f             	and    $0xffffff9f,%ecx
80108952:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108958:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010895b:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108962:	83 c9 80             	or     $0xffffff80,%ecx
80108965:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
8010896b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010896e:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108975:	83 e1 f0             	and    $0xfffffff0,%ecx
80108978:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
8010897e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108981:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108988:	83 e1 ef             	and    $0xffffffef,%ecx
8010898b:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108991:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108994:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
8010899b:	83 e1 df             	and    $0xffffffdf,%ecx
8010899e:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801089a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089a7:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801089ae:	83 c9 40             	or     $0x40,%ecx
801089b1:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801089b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089ba:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801089c1:	83 c9 80             	or     $0xffffff80,%ecx
801089c4:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801089ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089cd:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
801089d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089d6:	83 c0 70             	add    $0x70,%eax
801089d9:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
801089e0:	00 
801089e1:	89 04 24             	mov    %eax,(%esp)
801089e4:	e8 37 fb ff ff       	call   80108520 <lgdt>
  loadgs(SEG_KCPU << 3);
801089e9:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
801089f0:	e8 6a fb ff ff       	call   8010855f <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
801089f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089f8:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
801089fe:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80108a05:	00 00 00 00 
}
80108a09:	83 c4 24             	add    $0x24,%esp
80108a0c:	5b                   	pop    %ebx
80108a0d:	5d                   	pop    %ebp
80108a0e:	c3                   	ret    

80108a0f <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80108a0f:	55                   	push   %ebp
80108a10:	89 e5                	mov    %esp,%ebp
80108a12:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80108a15:	8b 45 0c             	mov    0xc(%ebp),%eax
80108a18:	c1 e8 16             	shr    $0x16,%eax
80108a1b:	c1 e0 02             	shl    $0x2,%eax
80108a1e:	03 45 08             	add    0x8(%ebp),%eax
80108a21:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
80108a24:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108a27:	8b 00                	mov    (%eax),%eax
80108a29:	83 e0 01             	and    $0x1,%eax
80108a2c:	84 c0                	test   %al,%al
80108a2e:	74 17                	je     80108a47 <walkpgdir+0x38>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
80108a30:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108a33:	8b 00                	mov    (%eax),%eax
80108a35:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108a3a:	89 04 24             	mov    %eax,(%esp)
80108a3d:	e8 4a fb ff ff       	call   8010858c <p2v>
80108a42:	89 45 f4             	mov    %eax,-0xc(%ebp)
80108a45:	eb 4b                	jmp    80108a92 <walkpgdir+0x83>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
80108a47:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80108a4b:	74 0e                	je     80108a5b <walkpgdir+0x4c>
80108a4d:	e8 be a0 ff ff       	call   80102b10 <kalloc>
80108a52:	89 45 f4             	mov    %eax,-0xc(%ebp)
80108a55:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80108a59:	75 07                	jne    80108a62 <walkpgdir+0x53>
      return 0;
80108a5b:	b8 00 00 00 00       	mov    $0x0,%eax
80108a60:	eb 41                	jmp    80108aa3 <walkpgdir+0x94>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
80108a62:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108a69:	00 
80108a6a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108a71:	00 
80108a72:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a75:	89 04 24             	mov    %eax,(%esp)
80108a78:	e8 5d d0 ff ff       	call   80105ada <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
80108a7d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a80:	89 04 24             	mov    %eax,(%esp)
80108a83:	e8 f7 fa ff ff       	call   8010857f <v2p>
80108a88:	89 c2                	mov    %eax,%edx
80108a8a:	83 ca 07             	or     $0x7,%edx
80108a8d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108a90:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
80108a92:	8b 45 0c             	mov    0xc(%ebp),%eax
80108a95:	c1 e8 0c             	shr    $0xc,%eax
80108a98:	25 ff 03 00 00       	and    $0x3ff,%eax
80108a9d:	c1 e0 02             	shl    $0x2,%eax
80108aa0:	03 45 f4             	add    -0xc(%ebp),%eax
}
80108aa3:	c9                   	leave  
80108aa4:	c3                   	ret    

80108aa5 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80108aa5:	55                   	push   %ebp
80108aa6:	89 e5                	mov    %esp,%ebp
80108aa8:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
80108aab:	8b 45 0c             	mov    0xc(%ebp),%eax
80108aae:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108ab3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  //cprintf("mappages: a = %p\n",a);
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80108ab6:	8b 45 0c             	mov    0xc(%ebp),%eax
80108ab9:	03 45 10             	add    0x10(%ebp),%eax
80108abc:	83 e8 01             	sub    $0x1,%eax
80108abf:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108ac4:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80108ac7:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80108ace:	00 
80108acf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ad2:	89 44 24 04          	mov    %eax,0x4(%esp)
80108ad6:	8b 45 08             	mov    0x8(%ebp),%eax
80108ad9:	89 04 24             	mov    %eax,(%esp)
80108adc:	e8 2e ff ff ff       	call   80108a0f <walkpgdir>
80108ae1:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108ae4:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108ae8:	75 07                	jne    80108af1 <mappages+0x4c>
      return -1;
80108aea:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108aef:	eb 46                	jmp    80108b37 <mappages+0x92>
    if(*pte & PTE_P)
80108af1:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108af4:	8b 00                	mov    (%eax),%eax
80108af6:	83 e0 01             	and    $0x1,%eax
80108af9:	84 c0                	test   %al,%al
80108afb:	74 0c                	je     80108b09 <mappages+0x64>
      panic("remap");
80108afd:	c7 04 24 08 9a 10 80 	movl   $0x80109a08,(%esp)
80108b04:	e8 34 7a ff ff       	call   8010053d <panic>
    *pte = pa | perm | PTE_P;
80108b09:	8b 45 18             	mov    0x18(%ebp),%eax
80108b0c:	0b 45 14             	or     0x14(%ebp),%eax
80108b0f:	89 c2                	mov    %eax,%edx
80108b11:	83 ca 01             	or     $0x1,%edx
80108b14:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108b17:	89 10                	mov    %edx,(%eax)
   //cprintf("mappages: pte = %p\n",pte);
    if(a == last)
80108b19:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b1c:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80108b1f:	74 10                	je     80108b31 <mappages+0x8c>
      break;
    a += PGSIZE;
80108b21:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
80108b28:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
80108b2f:	eb 96                	jmp    80108ac7 <mappages+0x22>
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
   //cprintf("mappages: pte = %p\n",pte);
    if(a == last)
      break;
80108b31:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
80108b32:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108b37:	c9                   	leave  
80108b38:	c3                   	ret    

80108b39 <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm()
{
80108b39:	55                   	push   %ebp
80108b3a:	89 e5                	mov    %esp,%ebp
80108b3c:	53                   	push   %ebx
80108b3d:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
80108b40:	e8 cb 9f ff ff       	call   80102b10 <kalloc>
80108b45:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108b48:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108b4c:	75 0a                	jne    80108b58 <setupkvm+0x1f>
    return 0;
80108b4e:	b8 00 00 00 00       	mov    $0x0,%eax
80108b53:	e9 98 00 00 00       	jmp    80108bf0 <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
80108b58:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108b5f:	00 
80108b60:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108b67:	00 
80108b68:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108b6b:	89 04 24             	mov    %eax,(%esp)
80108b6e:	e8 67 cf ff ff       	call   80105ada <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
80108b73:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
80108b7a:	e8 0d fa ff ff       	call   8010858c <p2v>
80108b7f:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
80108b84:	76 0c                	jbe    80108b92 <setupkvm+0x59>
    panic("PHYSTOP too high");
80108b86:	c7 04 24 0e 9a 10 80 	movl   $0x80109a0e,(%esp)
80108b8d:	e8 ab 79 ff ff       	call   8010053d <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80108b92:	c7 45 f4 c0 c4 10 80 	movl   $0x8010c4c0,-0xc(%ebp)
80108b99:	eb 49                	jmp    80108be4 <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
80108b9b:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80108b9e:	8b 48 0c             	mov    0xc(%eax),%ecx
                (uint)k->phys_start, k->perm) < 0)
80108ba1:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80108ba4:	8b 50 04             	mov    0x4(%eax),%edx
80108ba7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108baa:	8b 58 08             	mov    0x8(%eax),%ebx
80108bad:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108bb0:	8b 40 04             	mov    0x4(%eax),%eax
80108bb3:	29 c3                	sub    %eax,%ebx
80108bb5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108bb8:	8b 00                	mov    (%eax),%eax
80108bba:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80108bbe:	89 54 24 0c          	mov    %edx,0xc(%esp)
80108bc2:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80108bc6:	89 44 24 04          	mov    %eax,0x4(%esp)
80108bca:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108bcd:	89 04 24             	mov    %eax,(%esp)
80108bd0:	e8 d0 fe ff ff       	call   80108aa5 <mappages>
80108bd5:	85 c0                	test   %eax,%eax
80108bd7:	79 07                	jns    80108be0 <setupkvm+0xa7>
                (uint)k->phys_start, k->perm) < 0)
      return 0;
80108bd9:	b8 00 00 00 00       	mov    $0x0,%eax
80108bde:	eb 10                	jmp    80108bf0 <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80108be0:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80108be4:	81 7d f4 00 c5 10 80 	cmpl   $0x8010c500,-0xc(%ebp)
80108beb:	72 ae                	jb     80108b9b <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
      return 0;
  return pgdir;
80108bed:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80108bf0:	83 c4 34             	add    $0x34,%esp
80108bf3:	5b                   	pop    %ebx
80108bf4:	5d                   	pop    %ebp
80108bf5:	c3                   	ret    

80108bf6 <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
void
kvmalloc(void)
{
80108bf6:	55                   	push   %ebp
80108bf7:	89 e5                	mov    %esp,%ebp
80108bf9:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80108bfc:	e8 38 ff ff ff       	call   80108b39 <setupkvm>
80108c01:	a3 58 6b 11 80       	mov    %eax,0x80116b58
  switchkvm();
80108c06:	e8 02 00 00 00       	call   80108c0d <switchkvm>
}
80108c0b:	c9                   	leave  
80108c0c:	c3                   	ret    

80108c0d <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80108c0d:	55                   	push   %ebp
80108c0e:	89 e5                	mov    %esp,%ebp
80108c10:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
80108c13:	a1 58 6b 11 80       	mov    0x80116b58,%eax
80108c18:	89 04 24             	mov    %eax,(%esp)
80108c1b:	e8 5f f9 ff ff       	call   8010857f <v2p>
80108c20:	89 04 24             	mov    %eax,(%esp)
80108c23:	e8 4c f9 ff ff       	call   80108574 <lcr3>
}
80108c28:	c9                   	leave  
80108c29:	c3                   	ret    

80108c2a <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80108c2a:	55                   	push   %ebp
80108c2b:	89 e5                	mov    %esp,%ebp
80108c2d:	53                   	push   %ebx
80108c2e:	83 ec 14             	sub    $0x14,%esp
  pushcli();
80108c31:	e8 9e cd ff ff       	call   801059d4 <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
80108c36:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108c3c:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108c43:	83 c2 08             	add    $0x8,%edx
80108c46:	89 d3                	mov    %edx,%ebx
80108c48:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108c4f:	83 c2 08             	add    $0x8,%edx
80108c52:	c1 ea 10             	shr    $0x10,%edx
80108c55:	89 d1                	mov    %edx,%ecx
80108c57:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108c5e:	83 c2 08             	add    $0x8,%edx
80108c61:	c1 ea 18             	shr    $0x18,%edx
80108c64:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
80108c6b:	67 00 
80108c6d:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
80108c74:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
80108c7a:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108c81:	83 e1 f0             	and    $0xfffffff0,%ecx
80108c84:	83 c9 09             	or     $0x9,%ecx
80108c87:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108c8d:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108c94:	83 c9 10             	or     $0x10,%ecx
80108c97:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108c9d:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108ca4:	83 e1 9f             	and    $0xffffff9f,%ecx
80108ca7:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108cad:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108cb4:	83 c9 80             	or     $0xffffff80,%ecx
80108cb7:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108cbd:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108cc4:	83 e1 f0             	and    $0xfffffff0,%ecx
80108cc7:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108ccd:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108cd4:	83 e1 ef             	and    $0xffffffef,%ecx
80108cd7:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108cdd:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108ce4:	83 e1 df             	and    $0xffffffdf,%ecx
80108ce7:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108ced:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108cf4:	83 c9 40             	or     $0x40,%ecx
80108cf7:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108cfd:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108d04:	83 e1 7f             	and    $0x7f,%ecx
80108d07:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108d0d:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
80108d13:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108d19:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
80108d20:	83 e2 ef             	and    $0xffffffef,%edx
80108d23:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
80108d29:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108d2f:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
80108d35:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108d3b:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80108d42:	8b 52 08             	mov    0x8(%edx),%edx
80108d45:	81 c2 00 10 00 00    	add    $0x1000,%edx
80108d4b:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
80108d4e:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
80108d55:	e8 ef f7 ff ff       	call   80108549 <ltr>
  if(p->pgdir == 0)
80108d5a:	8b 45 08             	mov    0x8(%ebp),%eax
80108d5d:	8b 40 04             	mov    0x4(%eax),%eax
80108d60:	85 c0                	test   %eax,%eax
80108d62:	75 0c                	jne    80108d70 <switchuvm+0x146>
    panic("switchuvm: no pgdir");
80108d64:	c7 04 24 1f 9a 10 80 	movl   $0x80109a1f,(%esp)
80108d6b:	e8 cd 77 ff ff       	call   8010053d <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
80108d70:	8b 45 08             	mov    0x8(%ebp),%eax
80108d73:	8b 40 04             	mov    0x4(%eax),%eax
80108d76:	89 04 24             	mov    %eax,(%esp)
80108d79:	e8 01 f8 ff ff       	call   8010857f <v2p>
80108d7e:	89 04 24             	mov    %eax,(%esp)
80108d81:	e8 ee f7 ff ff       	call   80108574 <lcr3>
  popcli();
80108d86:	e8 91 cc ff ff       	call   80105a1c <popcli>
}
80108d8b:	83 c4 14             	add    $0x14,%esp
80108d8e:	5b                   	pop    %ebx
80108d8f:	5d                   	pop    %ebp
80108d90:	c3                   	ret    

80108d91 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80108d91:	55                   	push   %ebp
80108d92:	89 e5                	mov    %esp,%ebp
80108d94:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
80108d97:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
80108d9e:	76 0c                	jbe    80108dac <inituvm+0x1b>
    panic("inituvm: more than a page");
80108da0:	c7 04 24 33 9a 10 80 	movl   $0x80109a33,(%esp)
80108da7:	e8 91 77 ff ff       	call   8010053d <panic>
  mem = kalloc();
80108dac:	e8 5f 9d ff ff       	call   80102b10 <kalloc>
80108db1:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
80108db4:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108dbb:	00 
80108dbc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108dc3:	00 
80108dc4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108dc7:	89 04 24             	mov    %eax,(%esp)
80108dca:	e8 0b cd ff ff       	call   80105ada <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
80108dcf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108dd2:	89 04 24             	mov    %eax,(%esp)
80108dd5:	e8 a5 f7 ff ff       	call   8010857f <v2p>
80108dda:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80108de1:	00 
80108de2:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108de6:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108ded:	00 
80108dee:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108df5:	00 
80108df6:	8b 45 08             	mov    0x8(%ebp),%eax
80108df9:	89 04 24             	mov    %eax,(%esp)
80108dfc:	e8 a4 fc ff ff       	call   80108aa5 <mappages>
  memmove(mem, init, sz);
80108e01:	8b 45 10             	mov    0x10(%ebp),%eax
80108e04:	89 44 24 08          	mov    %eax,0x8(%esp)
80108e08:	8b 45 0c             	mov    0xc(%ebp),%eax
80108e0b:	89 44 24 04          	mov    %eax,0x4(%esp)
80108e0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e12:	89 04 24             	mov    %eax,(%esp)
80108e15:	e8 93 cd ff ff       	call   80105bad <memmove>
}
80108e1a:	c9                   	leave  
80108e1b:	c3                   	ret    

80108e1c <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80108e1c:	55                   	push   %ebp
80108e1d:	89 e5                	mov    %esp,%ebp
80108e1f:	53                   	push   %ebx
80108e20:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;
  if((uint) addr % PGSIZE != 0)
80108e23:	8b 45 0c             	mov    0xc(%ebp),%eax
80108e26:	25 ff 0f 00 00       	and    $0xfff,%eax
80108e2b:	85 c0                	test   %eax,%eax
80108e2d:	74 0c                	je     80108e3b <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
80108e2f:	c7 04 24 50 9a 10 80 	movl   $0x80109a50,(%esp)
80108e36:	e8 02 77 ff ff       	call   8010053d <panic>
  for(i = 0; i < sz; i += PGSIZE){
80108e3b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108e42:	e9 ad 00 00 00       	jmp    80108ef4 <loaduvm+0xd8>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
80108e47:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e4a:	8b 55 0c             	mov    0xc(%ebp),%edx
80108e4d:	01 d0                	add    %edx,%eax
80108e4f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108e56:	00 
80108e57:	89 44 24 04          	mov    %eax,0x4(%esp)
80108e5b:	8b 45 08             	mov    0x8(%ebp),%eax
80108e5e:	89 04 24             	mov    %eax,(%esp)
80108e61:	e8 a9 fb ff ff       	call   80108a0f <walkpgdir>
80108e66:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108e69:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108e6d:	75 0c                	jne    80108e7b <loaduvm+0x5f>
      panic("loaduvm: address should exist");
80108e6f:	c7 04 24 73 9a 10 80 	movl   $0x80109a73,(%esp)
80108e76:	e8 c2 76 ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
80108e7b:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108e7e:	8b 00                	mov    (%eax),%eax
80108e80:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108e85:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
80108e88:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e8b:	8b 55 18             	mov    0x18(%ebp),%edx
80108e8e:	89 d1                	mov    %edx,%ecx
80108e90:	29 c1                	sub    %eax,%ecx
80108e92:	89 c8                	mov    %ecx,%eax
80108e94:	3d ff 0f 00 00       	cmp    $0xfff,%eax
80108e99:	77 11                	ja     80108eac <loaduvm+0x90>
      n = sz - i;
80108e9b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e9e:	8b 55 18             	mov    0x18(%ebp),%edx
80108ea1:	89 d1                	mov    %edx,%ecx
80108ea3:	29 c1                	sub    %eax,%ecx
80108ea5:	89 c8                	mov    %ecx,%eax
80108ea7:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108eaa:	eb 07                	jmp    80108eb3 <loaduvm+0x97>
    else
      n = PGSIZE;
80108eac:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
80108eb3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108eb6:	8b 55 14             	mov    0x14(%ebp),%edx
80108eb9:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80108ebc:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108ebf:	89 04 24             	mov    %eax,(%esp)
80108ec2:	e8 c5 f6 ff ff       	call   8010858c <p2v>
80108ec7:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108eca:	89 54 24 0c          	mov    %edx,0xc(%esp)
80108ece:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80108ed2:	89 44 24 04          	mov    %eax,0x4(%esp)
80108ed6:	8b 45 10             	mov    0x10(%ebp),%eax
80108ed9:	89 04 24             	mov    %eax,(%esp)
80108edc:	e8 7d 8e ff ff       	call   80101d5e <readi>
80108ee1:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80108ee4:	74 07                	je     80108eed <loaduvm+0xd1>
      return -1;
80108ee6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108eeb:	eb 18                	jmp    80108f05 <loaduvm+0xe9>
{
  uint i, pa, n;
  pte_t *pte;
  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80108eed:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108ef4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ef7:	3b 45 18             	cmp    0x18(%ebp),%eax
80108efa:	0f 82 47 ff ff ff    	jb     80108e47 <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
80108f00:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108f05:	83 c4 24             	add    $0x24,%esp
80108f08:	5b                   	pop    %ebx
80108f09:	5d                   	pop    %ebp
80108f0a:	c3                   	ret    

80108f0b <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80108f0b:	55                   	push   %ebp
80108f0c:	89 e5                	mov    %esp,%ebp
80108f0e:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  uint a;

  if(newsz >= KERNBASE)
80108f11:	8b 45 10             	mov    0x10(%ebp),%eax
80108f14:	85 c0                	test   %eax,%eax
80108f16:	79 0a                	jns    80108f22 <allocuvm+0x17>
    return 0;
80108f18:	b8 00 00 00 00       	mov    $0x0,%eax
80108f1d:	e9 c1 00 00 00       	jmp    80108fe3 <allocuvm+0xd8>
  if(newsz < oldsz)
80108f22:	8b 45 10             	mov    0x10(%ebp),%eax
80108f25:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108f28:	73 08                	jae    80108f32 <allocuvm+0x27>
    return oldsz;
80108f2a:	8b 45 0c             	mov    0xc(%ebp),%eax
80108f2d:	e9 b1 00 00 00       	jmp    80108fe3 <allocuvm+0xd8>
  a = PGROUNDUP(oldsz);
80108f32:	8b 45 0c             	mov    0xc(%ebp),%eax
80108f35:	05 ff 0f 00 00       	add    $0xfff,%eax
80108f3a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108f3f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
80108f42:	e9 8d 00 00 00       	jmp    80108fd4 <allocuvm+0xc9>
    mem = kalloc();
80108f47:	e8 c4 9b ff ff       	call   80102b10 <kalloc>
80108f4c:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(mem == 0){
80108f4f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108f53:	75 2c                	jne    80108f81 <allocuvm+0x76>
      cprintf("allocuvm out of memory\n");
80108f55:	c7 04 24 91 9a 10 80 	movl   $0x80109a91,(%esp)
80108f5c:	e8 40 74 ff ff       	call   801003a1 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80108f61:	8b 45 0c             	mov    0xc(%ebp),%eax
80108f64:	89 44 24 08          	mov    %eax,0x8(%esp)
80108f68:	8b 45 10             	mov    0x10(%ebp),%eax
80108f6b:	89 44 24 04          	mov    %eax,0x4(%esp)
80108f6f:	8b 45 08             	mov    0x8(%ebp),%eax
80108f72:	89 04 24             	mov    %eax,(%esp)
80108f75:	e8 6b 00 00 00       	call   80108fe5 <deallocuvm>
      return 0;
80108f7a:	b8 00 00 00 00       	mov    $0x0,%eax
80108f7f:	eb 62                	jmp    80108fe3 <allocuvm+0xd8>
    }
    memset(mem, 0, PGSIZE);
80108f81:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108f88:	00 
80108f89:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108f90:	00 
80108f91:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108f94:	89 04 24             	mov    %eax,(%esp)
80108f97:	e8 3e cb ff ff       	call   80105ada <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
80108f9c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108f9f:	89 04 24             	mov    %eax,(%esp)
80108fa2:	e8 d8 f5 ff ff       	call   8010857f <v2p>
80108fa7:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108faa:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80108fb1:	00 
80108fb2:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108fb6:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108fbd:	00 
80108fbe:	89 54 24 04          	mov    %edx,0x4(%esp)
80108fc2:	8b 45 08             	mov    0x8(%ebp),%eax
80108fc5:	89 04 24             	mov    %eax,(%esp)
80108fc8:	e8 d8 fa ff ff       	call   80108aa5 <mappages>
  if(newsz >= KERNBASE)
    return 0;
  if(newsz < oldsz)
    return oldsz;
  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
80108fcd:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108fd4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108fd7:	3b 45 10             	cmp    0x10(%ebp),%eax
80108fda:	0f 82 67 ff ff ff    	jb     80108f47 <allocuvm+0x3c>
      return 0;
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
  }
  return newsz;
80108fe0:	8b 45 10             	mov    0x10(%ebp),%eax
}
80108fe3:	c9                   	leave  
80108fe4:	c3                   	ret    

80108fe5 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80108fe5:	55                   	push   %ebp
80108fe6:	89 e5                	mov    %esp,%ebp
80108fe8:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
80108feb:	8b 45 10             	mov    0x10(%ebp),%eax
80108fee:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108ff1:	72 08                	jb     80108ffb <deallocuvm+0x16>
    return oldsz;
80108ff3:	8b 45 0c             	mov    0xc(%ebp),%eax
80108ff6:	e9 a4 00 00 00       	jmp    8010909f <deallocuvm+0xba>

  a = PGROUNDUP(newsz);
80108ffb:	8b 45 10             	mov    0x10(%ebp),%eax
80108ffe:	05 ff 0f 00 00       	add    $0xfff,%eax
80109003:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109008:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
8010900b:	e9 80 00 00 00       	jmp    80109090 <deallocuvm+0xab>
    pte = walkpgdir(pgdir, (char*)a, 0);
80109010:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109013:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010901a:	00 
8010901b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010901f:	8b 45 08             	mov    0x8(%ebp),%eax
80109022:	89 04 24             	mov    %eax,(%esp)
80109025:	e8 e5 f9 ff ff       	call   80108a0f <walkpgdir>
8010902a:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(!pte)
8010902d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80109031:	75 09                	jne    8010903c <deallocuvm+0x57>
      a += (NPTENTRIES - 1) * PGSIZE;
80109033:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
8010903a:	eb 4d                	jmp    80109089 <deallocuvm+0xa4>
    else if((*pte & PTE_P) != 0){
8010903c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010903f:	8b 00                	mov    (%eax),%eax
80109041:	83 e0 01             	and    $0x1,%eax
80109044:	84 c0                	test   %al,%al
80109046:	74 41                	je     80109089 <deallocuvm+0xa4>
      pa = PTE_ADDR(*pte);
80109048:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010904b:	8b 00                	mov    (%eax),%eax
8010904d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109052:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if(pa == 0)
80109055:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80109059:	75 0c                	jne    80109067 <deallocuvm+0x82>
        panic("kfree");
8010905b:	c7 04 24 a9 9a 10 80 	movl   $0x80109aa9,(%esp)
80109062:	e8 d6 74 ff ff       	call   8010053d <panic>
      char *v = p2v(pa);
80109067:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010906a:	89 04 24             	mov    %eax,(%esp)
8010906d:	e8 1a f5 ff ff       	call   8010858c <p2v>
80109072:	89 45 e8             	mov    %eax,-0x18(%ebp)
      kfree(v);
80109075:	8b 45 e8             	mov    -0x18(%ebp),%eax
80109078:	89 04 24             	mov    %eax,(%esp)
8010907b:	e8 f7 99 ff ff       	call   80102a77 <kfree>
      *pte = 0;
80109080:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109083:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
80109089:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80109090:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109093:	3b 45 0c             	cmp    0xc(%ebp),%eax
80109096:	0f 82 74 ff ff ff    	jb     80109010 <deallocuvm+0x2b>
      char *v = p2v(pa);
      kfree(v);
      *pte = 0;
    }
  }
  return newsz;
8010909c:	8b 45 10             	mov    0x10(%ebp),%eax
}
8010909f:	c9                   	leave  
801090a0:	c3                   	ret    

801090a1 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
801090a1:	55                   	push   %ebp
801090a2:	89 e5                	mov    %esp,%ebp
801090a4:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
801090a7:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801090ab:	75 0c                	jne    801090b9 <freevm+0x18>
    panic("freevm: no pgdir");
801090ad:	c7 04 24 af 9a 10 80 	movl   $0x80109aaf,(%esp)
801090b4:	e8 84 74 ff ff       	call   8010053d <panic>
  deallocuvm(pgdir, KERNBASE, 0);
801090b9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801090c0:	00 
801090c1:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
801090c8:	80 
801090c9:	8b 45 08             	mov    0x8(%ebp),%eax
801090cc:	89 04 24             	mov    %eax,(%esp)
801090cf:	e8 11 ff ff ff       	call   80108fe5 <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
801090d4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801090db:	eb 3c                	jmp    80109119 <freevm+0x78>
    if(pgdir[i] & PTE_P){
801090dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801090e0:	c1 e0 02             	shl    $0x2,%eax
801090e3:	03 45 08             	add    0x8(%ebp),%eax
801090e6:	8b 00                	mov    (%eax),%eax
801090e8:	83 e0 01             	and    $0x1,%eax
801090eb:	84 c0                	test   %al,%al
801090ed:	74 26                	je     80109115 <freevm+0x74>
      char * v = p2v(PTE_ADDR(pgdir[i]));
801090ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
801090f2:	c1 e0 02             	shl    $0x2,%eax
801090f5:	03 45 08             	add    0x8(%ebp),%eax
801090f8:	8b 00                	mov    (%eax),%eax
801090fa:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801090ff:	89 04 24             	mov    %eax,(%esp)
80109102:	e8 85 f4 ff ff       	call   8010858c <p2v>
80109107:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
8010910a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010910d:	89 04 24             	mov    %eax,(%esp)
80109110:	e8 62 99 ff ff       	call   80102a77 <kfree>
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
  for(i = 0; i < NPDENTRIES; i++){
80109115:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80109119:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
80109120:	76 bb                	jbe    801090dd <freevm+0x3c>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
80109122:	8b 45 08             	mov    0x8(%ebp),%eax
80109125:	89 04 24             	mov    %eax,(%esp)
80109128:	e8 4a 99 ff ff       	call   80102a77 <kfree>
}
8010912d:	c9                   	leave  
8010912e:	c3                   	ret    

8010912f <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
8010912f:	55                   	push   %ebp
80109130:	89 e5                	mov    %esp,%ebp
80109132:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80109135:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010913c:	00 
8010913d:	8b 45 0c             	mov    0xc(%ebp),%eax
80109140:	89 44 24 04          	mov    %eax,0x4(%esp)
80109144:	8b 45 08             	mov    0x8(%ebp),%eax
80109147:	89 04 24             	mov    %eax,(%esp)
8010914a:	e8 c0 f8 ff ff       	call   80108a0f <walkpgdir>
8010914f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
80109152:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80109156:	75 0c                	jne    80109164 <clearpteu+0x35>
    panic("clearpteu");
80109158:	c7 04 24 c0 9a 10 80 	movl   $0x80109ac0,(%esp)
8010915f:	e8 d9 73 ff ff       	call   8010053d <panic>
  *pte &= ~PTE_U;
80109164:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109167:	8b 00                	mov    (%eax),%eax
80109169:	89 c2                	mov    %eax,%edx
8010916b:	83 e2 fb             	and    $0xfffffffb,%edx
8010916e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109171:	89 10                	mov    %edx,(%eax)
}
80109173:	c9                   	leave  
80109174:	c3                   	ret    

80109175 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
80109175:	55                   	push   %ebp
80109176:	89 e5                	mov    %esp,%ebp
80109178:	83 ec 48             	sub    $0x48,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
8010917b:	e8 b9 f9 ff ff       	call   80108b39 <setupkvm>
80109180:	89 45 f0             	mov    %eax,-0x10(%ebp)
80109183:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80109187:	75 0a                	jne    80109193 <copyuvm+0x1e>
    return 0;
80109189:	b8 00 00 00 00       	mov    $0x0,%eax
8010918e:	e9 f1 00 00 00       	jmp    80109284 <copyuvm+0x10f>
  for(i = 0; i < sz; i += PGSIZE){
80109193:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010919a:	e9 c0 00 00 00       	jmp    8010925f <copyuvm+0xea>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
8010919f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801091a2:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801091a9:	00 
801091aa:	89 44 24 04          	mov    %eax,0x4(%esp)
801091ae:	8b 45 08             	mov    0x8(%ebp),%eax
801091b1:	89 04 24             	mov    %eax,(%esp)
801091b4:	e8 56 f8 ff ff       	call   80108a0f <walkpgdir>
801091b9:	89 45 ec             	mov    %eax,-0x14(%ebp)
801091bc:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801091c0:	75 0c                	jne    801091ce <copyuvm+0x59>
      panic("copyuvm: pte should exist");
801091c2:	c7 04 24 ca 9a 10 80 	movl   $0x80109aca,(%esp)
801091c9:	e8 6f 73 ff ff       	call   8010053d <panic>
    if(!(*pte & PTE_P))
801091ce:	8b 45 ec             	mov    -0x14(%ebp),%eax
801091d1:	8b 00                	mov    (%eax),%eax
801091d3:	83 e0 01             	and    $0x1,%eax
801091d6:	85 c0                	test   %eax,%eax
801091d8:	75 0c                	jne    801091e6 <copyuvm+0x71>
      panic("copyuvm: page not present");
801091da:	c7 04 24 e4 9a 10 80 	movl   $0x80109ae4,(%esp)
801091e1:	e8 57 73 ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
801091e6:	8b 45 ec             	mov    -0x14(%ebp),%eax
801091e9:	8b 00                	mov    (%eax),%eax
801091eb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801091f0:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if((mem = kalloc()) == 0)
801091f3:	e8 18 99 ff ff       	call   80102b10 <kalloc>
801091f8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801091fb:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
801091ff:	74 6f                	je     80109270 <copyuvm+0xfb>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
80109201:	8b 45 e8             	mov    -0x18(%ebp),%eax
80109204:	89 04 24             	mov    %eax,(%esp)
80109207:	e8 80 f3 ff ff       	call   8010858c <p2v>
8010920c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80109213:	00 
80109214:	89 44 24 04          	mov    %eax,0x4(%esp)
80109218:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010921b:	89 04 24             	mov    %eax,(%esp)
8010921e:	e8 8a c9 ff ff       	call   80105bad <memmove>
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
80109223:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80109226:	89 04 24             	mov    %eax,(%esp)
80109229:	e8 51 f3 ff ff       	call   8010857f <v2p>
8010922e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109231:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80109238:	00 
80109239:	89 44 24 0c          	mov    %eax,0xc(%esp)
8010923d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80109244:	00 
80109245:	89 54 24 04          	mov    %edx,0x4(%esp)
80109249:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010924c:	89 04 24             	mov    %eax,(%esp)
8010924f:	e8 51 f8 ff ff       	call   80108aa5 <mappages>
80109254:	85 c0                	test   %eax,%eax
80109256:	78 1b                	js     80109273 <copyuvm+0xfe>
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
80109258:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
8010925f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109262:	3b 45 0c             	cmp    0xc(%ebp),%eax
80109265:	0f 82 34 ff ff ff    	jb     8010919f <copyuvm+0x2a>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
  }
  return d;
8010926b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010926e:	eb 14                	jmp    80109284 <copyuvm+0x10f>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
    if((mem = kalloc()) == 0)
      goto bad;
80109270:	90                   	nop
80109271:	eb 01                	jmp    80109274 <copyuvm+0xff>
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
80109273:	90                   	nop
  }
  return d;

bad:
  freevm(d);
80109274:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109277:	89 04 24             	mov    %eax,(%esp)
8010927a:	e8 22 fe ff ff       	call   801090a1 <freevm>
  return 0;
8010927f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80109284:	c9                   	leave  
80109285:	c3                   	ret    

80109286 <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
80109286:	55                   	push   %ebp
80109287:	89 e5                	mov    %esp,%ebp
80109289:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
8010928c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80109293:	00 
80109294:	8b 45 0c             	mov    0xc(%ebp),%eax
80109297:	89 44 24 04          	mov    %eax,0x4(%esp)
8010929b:	8b 45 08             	mov    0x8(%ebp),%eax
8010929e:	89 04 24             	mov    %eax,(%esp)
801092a1:	e8 69 f7 ff ff       	call   80108a0f <walkpgdir>
801092a6:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
801092a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801092ac:	8b 00                	mov    (%eax),%eax
801092ae:	83 e0 01             	and    $0x1,%eax
801092b1:	85 c0                	test   %eax,%eax
801092b3:	75 07                	jne    801092bc <uva2ka+0x36>
    return 0;
801092b5:	b8 00 00 00 00       	mov    $0x0,%eax
801092ba:	eb 25                	jmp    801092e1 <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
801092bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801092bf:	8b 00                	mov    (%eax),%eax
801092c1:	83 e0 04             	and    $0x4,%eax
801092c4:	85 c0                	test   %eax,%eax
801092c6:	75 07                	jne    801092cf <uva2ka+0x49>
    return 0;
801092c8:	b8 00 00 00 00       	mov    $0x0,%eax
801092cd:	eb 12                	jmp    801092e1 <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
801092cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801092d2:	8b 00                	mov    (%eax),%eax
801092d4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801092d9:	89 04 24             	mov    %eax,(%esp)
801092dc:	e8 ab f2 ff ff       	call   8010858c <p2v>
}
801092e1:	c9                   	leave  
801092e2:	c3                   	ret    

801092e3 <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
801092e3:	55                   	push   %ebp
801092e4:	89 e5                	mov    %esp,%ebp
801092e6:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
801092e9:	8b 45 10             	mov    0x10(%ebp),%eax
801092ec:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
801092ef:	e9 8b 00 00 00       	jmp    8010937f <copyout+0x9c>
    va0 = (uint)PGROUNDDOWN(va);
801092f4:	8b 45 0c             	mov    0xc(%ebp),%eax
801092f7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801092fc:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
801092ff:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109302:	89 44 24 04          	mov    %eax,0x4(%esp)
80109306:	8b 45 08             	mov    0x8(%ebp),%eax
80109309:	89 04 24             	mov    %eax,(%esp)
8010930c:	e8 75 ff ff ff       	call   80109286 <uva2ka>
80109311:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
80109314:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80109318:	75 07                	jne    80109321 <copyout+0x3e>
      return -1;
8010931a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010931f:	eb 6d                	jmp    8010938e <copyout+0xab>
    n = PGSIZE - (va - va0);
80109321:	8b 45 0c             	mov    0xc(%ebp),%eax
80109324:	8b 55 ec             	mov    -0x14(%ebp),%edx
80109327:	89 d1                	mov    %edx,%ecx
80109329:	29 c1                	sub    %eax,%ecx
8010932b:	89 c8                	mov    %ecx,%eax
8010932d:	05 00 10 00 00       	add    $0x1000,%eax
80109332:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
80109335:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109338:	3b 45 14             	cmp    0x14(%ebp),%eax
8010933b:	76 06                	jbe    80109343 <copyout+0x60>
      n = len;
8010933d:	8b 45 14             	mov    0x14(%ebp),%eax
80109340:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
80109343:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109346:	8b 55 0c             	mov    0xc(%ebp),%edx
80109349:	89 d1                	mov    %edx,%ecx
8010934b:	29 c1                	sub    %eax,%ecx
8010934d:	89 c8                	mov    %ecx,%eax
8010934f:	03 45 e8             	add    -0x18(%ebp),%eax
80109352:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109355:	89 54 24 08          	mov    %edx,0x8(%esp)
80109359:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010935c:	89 54 24 04          	mov    %edx,0x4(%esp)
80109360:	89 04 24             	mov    %eax,(%esp)
80109363:	e8 45 c8 ff ff       	call   80105bad <memmove>
    len -= n;
80109368:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010936b:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
8010936e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109371:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
80109374:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109377:	05 00 10 00 00       	add    $0x1000,%eax
8010937c:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
8010937f:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
80109383:	0f 85 6b ff ff ff    	jne    801092f4 <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
80109389:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010938e:	c9                   	leave  
8010938f:	c3                   	ret    
