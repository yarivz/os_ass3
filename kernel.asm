
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
80100028:	bc 20 d7 10 80       	mov    $0x8010d720,%esp

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
8010003a:	c7 44 24 04 a4 97 10 	movl   $0x801097a4,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 20 d7 10 80 	movl   $0x8010d720,(%esp)
80100049:	e8 d4 5b 00 00       	call   80105c22 <initlock>

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
8010004e:	c7 05 50 ec 10 80 44 	movl   $0x8010ec44,0x8010ec50
80100055:	ec 10 80 
  bcache.head.next = &bcache.head;
80100058:	c7 05 54 ec 10 80 44 	movl   $0x8010ec44,0x8010ec54
8010005f:	ec 10 80 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
80100062:	c7 45 f4 54 d7 10 80 	movl   $0x8010d754,-0xc(%ebp)
80100069:	eb 3a                	jmp    801000a5 <binit+0x71>
    b->next = bcache.head.next;
8010006b:	8b 15 54 ec 10 80    	mov    0x8010ec54,%edx
80100071:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100074:	89 50 10             	mov    %edx,0x10(%eax)
    b->prev = &bcache.head;
80100077:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010007a:	c7 40 0c 44 ec 10 80 	movl   $0x8010ec44,0xc(%eax)
    b->dev = -1;
80100081:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100084:	c7 40 04 ff ff ff ff 	movl   $0xffffffff,0x4(%eax)
    bcache.head.next->prev = b;
8010008b:	a1 54 ec 10 80       	mov    0x8010ec54,%eax
80100090:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100093:	89 50 0c             	mov    %edx,0xc(%eax)
    bcache.head.next = b;
80100096:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100099:	a3 54 ec 10 80       	mov    %eax,0x8010ec54

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
  bcache.head.next = &bcache.head;
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
8010009e:	81 45 f4 18 02 00 00 	addl   $0x218,-0xc(%ebp)
801000a5:	81 7d f4 44 ec 10 80 	cmpl   $0x8010ec44,-0xc(%ebp)
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
801000b6:	c7 04 24 20 d7 10 80 	movl   $0x8010d720,(%esp)
801000bd:	e8 81 5b 00 00       	call   80105c43 <acquire>

 loop:
  // Is the sector already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
801000c2:	a1 54 ec 10 80       	mov    0x8010ec54,%eax
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
801000fd:	c7 04 24 20 d7 10 80 	movl   $0x8010d720,(%esp)
80100104:	e8 d5 5b 00 00       	call   80105cde <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 20 d7 10 	movl   $0x8010d720,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 de 55 00 00       	call   80105702 <sleep>
      goto loop;
80100124:	eb 9c                	jmp    801000c2 <bget+0x12>

  acquire(&bcache.lock);

 loop:
  // Is the sector already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
80100126:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100129:	8b 40 10             	mov    0x10(%eax),%eax
8010012c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010012f:	81 7d f4 44 ec 10 80 	cmpl   $0x8010ec44,-0xc(%ebp)
80100136:	75 94                	jne    801000cc <bget+0x1c>
      goto loop;
    }
  }

  // Not cached; recycle some non-busy and clean buffer.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100138:	a1 50 ec 10 80       	mov    0x8010ec50,%eax
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
80100175:	c7 04 24 20 d7 10 80 	movl   $0x8010d720,(%esp)
8010017c:	e8 5d 5b 00 00       	call   80105cde <release>
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
8010018f:	81 7d f4 44 ec 10 80 	cmpl   $0x8010ec44,-0xc(%ebp)
80100196:	75 aa                	jne    80100142 <bget+0x92>
      b->flags = B_BUSY;
      release(&bcache.lock);
      return b;
    }
  }
  panic("bget: no buffers");
80100198:	c7 04 24 ab 97 10 80 	movl   $0x801097ab,(%esp)
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
801001ef:	c7 04 24 bc 97 10 80 	movl   $0x801097bc,(%esp)
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
80100229:	c7 04 24 c3 97 10 80 	movl   $0x801097c3,(%esp)
80100230:	e8 08 03 00 00       	call   8010053d <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 20 d7 10 80 	movl   $0x8010d720,(%esp)
8010023c:	e8 02 5a 00 00       	call   80105c43 <acquire>

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
8010025f:	8b 15 54 ec 10 80    	mov    0x8010ec54,%edx
80100265:	8b 45 08             	mov    0x8(%ebp),%eax
80100268:	89 50 10             	mov    %edx,0x10(%eax)
  b->prev = &bcache.head;
8010026b:	8b 45 08             	mov    0x8(%ebp),%eax
8010026e:	c7 40 0c 44 ec 10 80 	movl   $0x8010ec44,0xc(%eax)
  bcache.head.next->prev = b;
80100275:	a1 54 ec 10 80       	mov    0x8010ec54,%eax
8010027a:	8b 55 08             	mov    0x8(%ebp),%edx
8010027d:	89 50 0c             	mov    %edx,0xc(%eax)
  bcache.head.next = b;
80100280:	8b 45 08             	mov    0x8(%ebp),%eax
80100283:	a3 54 ec 10 80       	mov    %eax,0x8010ec54

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
8010029d:	e8 75 56 00 00       	call   80105917 <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 20 d7 10 80 	movl   $0x8010d720,(%esp)
801002a9:	e8 30 5a 00 00       	call   80105cde <release>
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
801003bc:	e8 82 58 00 00       	call   80105c43 <acquire>

  if (fmt == 0)
801003c1:	8b 45 08             	mov    0x8(%ebp),%eax
801003c4:	85 c0                	test   %eax,%eax
801003c6:	75 0c                	jne    801003d4 <cprintf+0x33>
    panic("null fmt");
801003c8:	c7 04 24 ca 97 10 80 	movl   $0x801097ca,(%esp)
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
801004af:	c7 45 ec d3 97 10 80 	movl   $0x801097d3,-0x14(%ebp)
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
80100536:	e8 a3 57 00 00       	call   80105cde <release>
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
80100562:	c7 04 24 da 97 10 80 	movl   $0x801097da,(%esp)
80100569:	e8 33 fe ff ff       	call   801003a1 <cprintf>
  cprintf(s);
8010056e:	8b 45 08             	mov    0x8(%ebp),%eax
80100571:	89 04 24             	mov    %eax,(%esp)
80100574:	e8 28 fe ff ff       	call   801003a1 <cprintf>
  cprintf("\n");
80100579:	c7 04 24 e9 97 10 80 	movl   $0x801097e9,(%esp)
80100580:	e8 1c fe ff ff       	call   801003a1 <cprintf>
  getcallerpcs(&s, pcs);
80100585:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100588:	89 44 24 04          	mov    %eax,0x4(%esp)
8010058c:	8d 45 08             	lea    0x8(%ebp),%eax
8010058f:	89 04 24             	mov    %eax,(%esp)
80100592:	e8 96 57 00 00       	call   80105d2d <getcallerpcs>
  for(i=0; i<10; i++)
80100597:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010059e:	eb 1b                	jmp    801005bb <panic+0x7e>
    cprintf(" %p", pcs[i]);
801005a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005a3:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005a7:	89 44 24 04          	mov    %eax,0x4(%esp)
801005ab:	c7 04 24 eb 97 10 80 	movl   $0x801097eb,(%esp)
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
801006b2:	e8 e6 58 00 00       	call   80105f9d <memmove>
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
801006e1:	e8 e4 57 00 00       	call   80105eca <memset>
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
80100776:	e8 8e 76 00 00       	call   80107e09 <uartputc>
8010077b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80100782:	e8 82 76 00 00       	call   80107e09 <uartputc>
80100787:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
8010078e:	e8 76 76 00 00       	call   80107e09 <uartputc>
80100793:	eb 0b                	jmp    801007a0 <consputc+0x50>
  } else
    uartputc(c);
80100795:	8b 45 08             	mov    0x8(%ebp),%eax
80100798:	89 04 24             	mov    %eax,(%esp)
8010079b:	e8 69 76 00 00       	call   80107e09 <uartputc>
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
801007b3:	c7 04 24 60 ee 10 80 	movl   $0x8010ee60,(%esp)
801007ba:	e8 84 54 00 00       	call   80105c43 <acquire>
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
801007ea:	e8 1d 52 00 00       	call   80105a0c <procdump>
      break;
801007ef:	e9 11 01 00 00       	jmp    80100905 <consoleintr+0x158>
    case C('U'):  // Kill line.
      while(input.e != input.w &&
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
801007f4:	a1 1c ef 10 80       	mov    0x8010ef1c,%eax
801007f9:	83 e8 01             	sub    $0x1,%eax
801007fc:	a3 1c ef 10 80       	mov    %eax,0x8010ef1c
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
80100810:	8b 15 1c ef 10 80    	mov    0x8010ef1c,%edx
80100816:	a1 18 ef 10 80       	mov    0x8010ef18,%eax
8010081b:	39 c2                	cmp    %eax,%edx
8010081d:	0f 84 db 00 00 00    	je     801008fe <consoleintr+0x151>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
80100823:	a1 1c ef 10 80       	mov    0x8010ef1c,%eax
80100828:	83 e8 01             	sub    $0x1,%eax
8010082b:	83 e0 7f             	and    $0x7f,%eax
8010082e:	0f b6 80 94 ee 10 80 	movzbl -0x7fef116c(%eax),%eax
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
8010083e:	8b 15 1c ef 10 80    	mov    0x8010ef1c,%edx
80100844:	a1 18 ef 10 80       	mov    0x8010ef18,%eax
80100849:	39 c2                	cmp    %eax,%edx
8010084b:	0f 84 b0 00 00 00    	je     80100901 <consoleintr+0x154>
        input.e--;
80100851:	a1 1c ef 10 80       	mov    0x8010ef1c,%eax
80100856:	83 e8 01             	sub    $0x1,%eax
80100859:	a3 1c ef 10 80       	mov    %eax,0x8010ef1c
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
80100879:	8b 15 1c ef 10 80    	mov    0x8010ef1c,%edx
8010087f:	a1 14 ef 10 80       	mov    0x8010ef14,%eax
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
801008a2:	a1 1c ef 10 80       	mov    0x8010ef1c,%eax
801008a7:	89 c1                	mov    %eax,%ecx
801008a9:	83 e1 7f             	and    $0x7f,%ecx
801008ac:	8b 55 f4             	mov    -0xc(%ebp),%edx
801008af:	88 91 94 ee 10 80    	mov    %dl,-0x7fef116c(%ecx)
801008b5:	83 c0 01             	add    $0x1,%eax
801008b8:	a3 1c ef 10 80       	mov    %eax,0x8010ef1c
        consputc(c);
801008bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801008c0:	89 04 24             	mov    %eax,(%esp)
801008c3:	e8 88 fe ff ff       	call   80100750 <consputc>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
801008c8:	83 7d f4 0a          	cmpl   $0xa,-0xc(%ebp)
801008cc:	74 18                	je     801008e6 <consoleintr+0x139>
801008ce:	83 7d f4 04          	cmpl   $0x4,-0xc(%ebp)
801008d2:	74 12                	je     801008e6 <consoleintr+0x139>
801008d4:	a1 1c ef 10 80       	mov    0x8010ef1c,%eax
801008d9:	8b 15 14 ef 10 80    	mov    0x8010ef14,%edx
801008df:	83 ea 80             	sub    $0xffffff80,%edx
801008e2:	39 d0                	cmp    %edx,%eax
801008e4:	75 1e                	jne    80100904 <consoleintr+0x157>
          input.w = input.e;
801008e6:	a1 1c ef 10 80       	mov    0x8010ef1c,%eax
801008eb:	a3 18 ef 10 80       	mov    %eax,0x8010ef18
          wakeup(&input.r);
801008f0:	c7 04 24 14 ef 10 80 	movl   $0x8010ef14,(%esp)
801008f7:	e8 1b 50 00 00       	call   80105917 <wakeup>
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
80100917:	c7 04 24 60 ee 10 80 	movl   $0x8010ee60,(%esp)
8010091e:	e8 bb 53 00 00       	call   80105cde <release>
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
8010093c:	c7 04 24 60 ee 10 80 	movl   $0x8010ee60,(%esp)
80100943:	e8 fb 52 00 00       	call   80105c43 <acquire>
  while(n > 0){
80100948:	e9 a8 00 00 00       	jmp    801009f5 <consoleread+0xd0>
    while(input.r == input.w){
      if(proc->killed){
8010094d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100953:	8b 40 24             	mov    0x24(%eax),%eax
80100956:	85 c0                	test   %eax,%eax
80100958:	74 21                	je     8010097b <consoleread+0x56>
        release(&input.lock);
8010095a:	c7 04 24 60 ee 10 80 	movl   $0x8010ee60,(%esp)
80100961:	e8 78 53 00 00       	call   80105cde <release>
        ilock(ip);
80100966:	8b 45 08             	mov    0x8(%ebp),%eax
80100969:	89 04 24             	mov    %eax,(%esp)
8010096c:	e8 f7 0e 00 00       	call   80101868 <ilock>
        return -1;
80100971:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100976:	e9 a9 00 00 00       	jmp    80100a24 <consoleread+0xff>
      }
      sleep(&input.r, &input.lock);
8010097b:	c7 44 24 04 60 ee 10 	movl   $0x8010ee60,0x4(%esp)
80100982:	80 
80100983:	c7 04 24 14 ef 10 80 	movl   $0x8010ef14,(%esp)
8010098a:	e8 73 4d 00 00       	call   80105702 <sleep>
8010098f:	eb 01                	jmp    80100992 <consoleread+0x6d>

  iunlock(ip);
  target = n;
  acquire(&input.lock);
  while(n > 0){
    while(input.r == input.w){
80100991:	90                   	nop
80100992:	8b 15 14 ef 10 80    	mov    0x8010ef14,%edx
80100998:	a1 18 ef 10 80       	mov    0x8010ef18,%eax
8010099d:	39 c2                	cmp    %eax,%edx
8010099f:	74 ac                	je     8010094d <consoleread+0x28>
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &input.lock);
    }
    c = input.buf[input.r++ % INPUT_BUF];
801009a1:	a1 14 ef 10 80       	mov    0x8010ef14,%eax
801009a6:	89 c2                	mov    %eax,%edx
801009a8:	83 e2 7f             	and    $0x7f,%edx
801009ab:	0f b6 92 94 ee 10 80 	movzbl -0x7fef116c(%edx),%edx
801009b2:	0f be d2             	movsbl %dl,%edx
801009b5:	89 55 f0             	mov    %edx,-0x10(%ebp)
801009b8:	83 c0 01             	add    $0x1,%eax
801009bb:	a3 14 ef 10 80       	mov    %eax,0x8010ef14
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
801009ce:	a1 14 ef 10 80       	mov    0x8010ef14,%eax
801009d3:	83 e8 01             	sub    $0x1,%eax
801009d6:	a3 14 ef 10 80       	mov    %eax,0x8010ef14
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
80100a01:	c7 04 24 60 ee 10 80 	movl   $0x8010ee60,(%esp)
80100a08:	e8 d1 52 00 00       	call   80105cde <release>
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
80100a3e:	e8 00 52 00 00       	call   80105c43 <acquire>
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
80100a78:	e8 61 52 00 00       	call   80105cde <release>
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
80100a93:	c7 44 24 04 ef 97 10 	movl   $0x801097ef,0x4(%esp)
80100a9a:	80 
80100a9b:	c7 04 24 e0 c5 10 80 	movl   $0x8010c5e0,(%esp)
80100aa2:	e8 7b 51 00 00       	call   80105c22 <initlock>
  initlock(&input.lock, "input");
80100aa7:	c7 44 24 04 f7 97 10 	movl   $0x801097f7,0x4(%esp)
80100aae:	80 
80100aaf:	c7 04 24 60 ee 10 80 	movl   $0x8010ee60,(%esp)
80100ab6:	e8 67 51 00 00       	call   80105c22 <initlock>

  devsw[CONSOLE].write = consolewrite;
80100abb:	c7 05 cc f8 10 80 26 	movl   $0x80100a26,0x8010f8cc
80100ac2:	0a 10 80 
  devsw[CONSOLE].read = consoleread;
80100ac5:	c7 05 c8 f8 10 80 25 	movl   $0x80100925,0x8010f8c8
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
80100b7b:	e8 cd 83 00 00       	call   80108f4d <setupkvm>
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
80100c14:	e8 06 87 00 00       	call   8010931f <allocuvm>
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
80100c51:	e8 da 85 00 00       	call   80109230 <loaduvm>
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
80100cbc:	e8 5e 86 00 00       	call   8010931f <allocuvm>
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
80100ce0:	e8 5e 88 00 00       	call   80109543 <clearpteu>
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
80100d0f:	e8 34 54 00 00       	call   80106148 <strlen>
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
80100d2d:	e8 16 54 00 00       	call   80106148 <strlen>
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
80100d57:	e8 9b 89 00 00       	call   801096f7 <copyout>
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
80100df7:	e8 fb 88 00 00       	call   801096f7 <copyout>
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
80100e4e:	e8 a7 52 00 00       	call   801060fa <safestrcpy>

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
80100ea0:	e8 99 81 00 00       	call   8010903e <switchuvm>
  freevm(oldpgdir);
80100ea5:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100ea8:	89 04 24             	mov    %eax,(%esp)
80100eab:	e8 05 86 00 00       	call   801094b5 <freevm>
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
80100ee2:	e8 ce 85 00 00       	call   801094b5 <freevm>
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
80100f06:	c7 44 24 04 fd 97 10 	movl   $0x801097fd,0x4(%esp)
80100f0d:	80 
80100f0e:	c7 04 24 20 ef 10 80 	movl   $0x8010ef20,(%esp)
80100f15:	e8 08 4d 00 00       	call   80105c22 <initlock>
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
80100f22:	c7 04 24 20 ef 10 80 	movl   $0x8010ef20,(%esp)
80100f29:	e8 15 4d 00 00       	call   80105c43 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100f2e:	c7 45 f4 54 ef 10 80 	movl   $0x8010ef54,-0xc(%ebp)
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
80100f4b:	c7 04 24 20 ef 10 80 	movl   $0x8010ef20,(%esp)
80100f52:	e8 87 4d 00 00       	call   80105cde <release>
      return f;
80100f57:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f5a:	eb 1e                	jmp    80100f7a <filealloc+0x5e>
filealloc(void)
{
  struct file *f;

  acquire(&ftable.lock);
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100f5c:	83 45 f4 18          	addl   $0x18,-0xc(%ebp)
80100f60:	81 7d f4 b4 f8 10 80 	cmpl   $0x8010f8b4,-0xc(%ebp)
80100f67:	72 ce                	jb     80100f37 <filealloc+0x1b>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
80100f69:	c7 04 24 20 ef 10 80 	movl   $0x8010ef20,(%esp)
80100f70:	e8 69 4d 00 00       	call   80105cde <release>
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
80100f82:	c7 04 24 20 ef 10 80 	movl   $0x8010ef20,(%esp)
80100f89:	e8 b5 4c 00 00       	call   80105c43 <acquire>
  if(f->ref < 1)
80100f8e:	8b 45 08             	mov    0x8(%ebp),%eax
80100f91:	8b 40 04             	mov    0x4(%eax),%eax
80100f94:	85 c0                	test   %eax,%eax
80100f96:	7f 0c                	jg     80100fa4 <filedup+0x28>
    panic("filedup");
80100f98:	c7 04 24 04 98 10 80 	movl   $0x80109804,(%esp)
80100f9f:	e8 99 f5 ff ff       	call   8010053d <panic>
  f->ref++;
80100fa4:	8b 45 08             	mov    0x8(%ebp),%eax
80100fa7:	8b 40 04             	mov    0x4(%eax),%eax
80100faa:	8d 50 01             	lea    0x1(%eax),%edx
80100fad:	8b 45 08             	mov    0x8(%ebp),%eax
80100fb0:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
80100fb3:	c7 04 24 20 ef 10 80 	movl   $0x8010ef20,(%esp)
80100fba:	e8 1f 4d 00 00       	call   80105cde <release>
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
80100fca:	c7 04 24 20 ef 10 80 	movl   $0x8010ef20,(%esp)
80100fd1:	e8 6d 4c 00 00       	call   80105c43 <acquire>
  if(f->ref < 1)
80100fd6:	8b 45 08             	mov    0x8(%ebp),%eax
80100fd9:	8b 40 04             	mov    0x4(%eax),%eax
80100fdc:	85 c0                	test   %eax,%eax
80100fde:	7f 0c                	jg     80100fec <fileclose+0x28>
    panic("fileclose");
80100fe0:	c7 04 24 0c 98 10 80 	movl   $0x8010980c,(%esp)
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
80101005:	c7 04 24 20 ef 10 80 	movl   $0x8010ef20,(%esp)
8010100c:	e8 cd 4c 00 00       	call   80105cde <release>
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
8010104f:	c7 04 24 20 ef 10 80 	movl   $0x8010ef20,(%esp)
80101056:	e8 83 4c 00 00       	call   80105cde <release>
  
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
80101197:	c7 04 24 16 98 10 80 	movl   $0x80109816,(%esp)
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
801012a3:	c7 04 24 1f 98 10 80 	movl   $0x8010981f,(%esp)
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
801012d8:	c7 04 24 2f 98 10 80 	movl   $0x8010982f,(%esp)
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
80101320:	e8 78 4c 00 00       	call   80105f9d <memmove>
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
80101366:	e8 5f 4b 00 00       	call   80105eca <memset>
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
801014ce:	c7 04 24 39 98 10 80 	movl   $0x80109839,(%esp)
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
80101565:	c7 04 24 4f 98 10 80 	movl   $0x8010984f,(%esp)
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
801015b9:	c7 44 24 04 62 98 10 	movl   $0x80109862,0x4(%esp)
801015c0:	80 
801015c1:	c7 04 24 20 f9 10 80 	movl   $0x8010f920,(%esp)
801015c8:	e8 55 46 00 00       	call   80105c22 <initlock>
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
8010164a:	e8 7b 48 00 00       	call   80105eca <memset>
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
801016a0:	c7 04 24 69 98 10 80 	movl   $0x80109869,(%esp)
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
80101747:	e8 51 48 00 00       	call   80105f9d <memmove>
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
8010176a:	c7 04 24 20 f9 10 80 	movl   $0x8010f920,(%esp)
80101771:	e8 cd 44 00 00       	call   80105c43 <acquire>

  // Is the inode already cached?
  empty = 0;
80101776:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
8010177d:	c7 45 f4 54 f9 10 80 	movl   $0x8010f954,-0xc(%ebp)
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
801017b4:	c7 04 24 20 f9 10 80 	movl   $0x8010f920,(%esp)
801017bb:	e8 1e 45 00 00       	call   80105cde <release>
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
801017df:	81 7d f4 f4 08 11 80 	cmpl   $0x801108f4,-0xc(%ebp)
801017e6:	72 9e                	jb     80101786 <iget+0x22>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
      empty = ip;
  }

  // Recycle an inode cache entry.
  if(empty == 0)
801017e8:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801017ec:	75 0c                	jne    801017fa <iget+0x96>
    panic("iget: no inodes");
801017ee:	c7 04 24 7b 98 10 80 	movl   $0x8010987b,(%esp)
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
80101825:	c7 04 24 20 f9 10 80 	movl   $0x8010f920,(%esp)
8010182c:	e8 ad 44 00 00       	call   80105cde <release>

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
8010183c:	c7 04 24 20 f9 10 80 	movl   $0x8010f920,(%esp)
80101843:	e8 fb 43 00 00       	call   80105c43 <acquire>
  ip->ref++;
80101848:	8b 45 08             	mov    0x8(%ebp),%eax
8010184b:	8b 40 08             	mov    0x8(%eax),%eax
8010184e:	8d 50 01             	lea    0x1(%eax),%edx
80101851:	8b 45 08             	mov    0x8(%ebp),%eax
80101854:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101857:	c7 04 24 20 f9 10 80 	movl   $0x8010f920,(%esp)
8010185e:	e8 7b 44 00 00       	call   80105cde <release>
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
8010187e:	c7 04 24 8b 98 10 80 	movl   $0x8010988b,(%esp)
80101885:	e8 b3 ec ff ff       	call   8010053d <panic>

  acquire(&icache.lock);
8010188a:	c7 04 24 20 f9 10 80 	movl   $0x8010f920,(%esp)
80101891:	e8 ad 43 00 00       	call   80105c43 <acquire>
  while(ip->flags & I_BUSY)
80101896:	eb 13                	jmp    801018ab <ilock+0x43>
    sleep(ip, &icache.lock);
80101898:	c7 44 24 04 20 f9 10 	movl   $0x8010f920,0x4(%esp)
8010189f:	80 
801018a0:	8b 45 08             	mov    0x8(%ebp),%eax
801018a3:	89 04 24             	mov    %eax,(%esp)
801018a6:	e8 57 3e 00 00       	call   80105702 <sleep>

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
801018c9:	c7 04 24 20 f9 10 80 	movl   $0x8010f920,(%esp)
801018d0:	e8 09 44 00 00       	call   80105cde <release>

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
8010197b:	e8 1d 46 00 00       	call   80105f9d <memmove>
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
801019a8:	c7 04 24 91 98 10 80 	movl   $0x80109891,(%esp)
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
801019d9:	c7 04 24 a0 98 10 80 	movl   $0x801098a0,(%esp)
801019e0:	e8 58 eb ff ff       	call   8010053d <panic>
  acquire(&icache.lock);
801019e5:	c7 04 24 20 f9 10 80 	movl   $0x8010f920,(%esp)
801019ec:	e8 52 42 00 00       	call   80105c43 <acquire>
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
80101a08:	e8 0a 3f 00 00       	call   80105917 <wakeup>
  release(&icache.lock);
80101a0d:	c7 04 24 20 f9 10 80 	movl   $0x8010f920,(%esp)
80101a14:	e8 c5 42 00 00       	call   80105cde <release>
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
80101a21:	c7 04 24 20 f9 10 80 	movl   $0x8010f920,(%esp)
80101a28:	e8 16 42 00 00       	call   80105c43 <acquire>
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
80101a66:	c7 04 24 a8 98 10 80 	movl   $0x801098a8,(%esp)
80101a6d:	e8 cb ea ff ff       	call   8010053d <panic>
    ip->flags |= I_BUSY;
80101a72:	8b 45 08             	mov    0x8(%ebp),%eax
80101a75:	8b 40 0c             	mov    0xc(%eax),%eax
80101a78:	89 c2                	mov    %eax,%edx
80101a7a:	83 ca 01             	or     $0x1,%edx
80101a7d:	8b 45 08             	mov    0x8(%ebp),%eax
80101a80:	89 50 0c             	mov    %edx,0xc(%eax)
    release(&icache.lock);
80101a83:	c7 04 24 20 f9 10 80 	movl   $0x8010f920,(%esp)
80101a8a:	e8 4f 42 00 00       	call   80105cde <release>
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
80101aae:	c7 04 24 20 f9 10 80 	movl   $0x8010f920,(%esp)
80101ab5:	e8 89 41 00 00       	call   80105c43 <acquire>
    ip->flags = 0;
80101aba:	8b 45 08             	mov    0x8(%ebp),%eax
80101abd:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
80101ac4:	8b 45 08             	mov    0x8(%ebp),%eax
80101ac7:	89 04 24             	mov    %eax,(%esp)
80101aca:	e8 48 3e 00 00       	call   80105917 <wakeup>
  }
  ip->ref--;
80101acf:	8b 45 08             	mov    0x8(%ebp),%eax
80101ad2:	8b 40 08             	mov    0x8(%eax),%eax
80101ad5:	8d 50 ff             	lea    -0x1(%eax),%edx
80101ad8:	8b 45 08             	mov    0x8(%ebp),%eax
80101adb:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101ade:	c7 04 24 20 f9 10 80 	movl   $0x8010f920,(%esp)
80101ae5:	e8 f4 41 00 00       	call   80105cde <release>
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
80101bfa:	c7 04 24 b2 98 10 80 	movl   $0x801098b2,(%esp)
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
80101d93:	8b 04 c5 c0 f8 10 80 	mov    -0x7fef0740(,%eax,8),%eax
80101d9a:	85 c0                	test   %eax,%eax
80101d9c:	75 0a                	jne    80101da8 <readi+0x4a>
      return -1;
80101d9e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101da3:	e9 1b 01 00 00       	jmp    80101ec3 <readi+0x165>
    return devsw[ip->major].read(ip, dst, n);
80101da8:	8b 45 08             	mov    0x8(%ebp),%eax
80101dab:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101daf:	98                   	cwtl   
80101db0:	8b 14 c5 c0 f8 10 80 	mov    -0x7fef0740(,%eax,8),%edx
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
80101e92:	e8 06 41 00 00       	call   80105f9d <memmove>
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
80101efe:	8b 04 c5 c4 f8 10 80 	mov    -0x7fef073c(,%eax,8),%eax
80101f05:	85 c0                	test   %eax,%eax
80101f07:	75 0a                	jne    80101f13 <writei+0x4a>
      return -1;
80101f09:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101f0e:	e9 46 01 00 00       	jmp    80102059 <writei+0x190>
    return devsw[ip->major].write(ip, src, n);
80101f13:	8b 45 08             	mov    0x8(%ebp),%eax
80101f16:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101f1a:	98                   	cwtl   
80101f1b:	8b 14 c5 c4 f8 10 80 	mov    -0x7fef073c(,%eax,8),%edx
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
80101ff8:	e8 a0 3f 00 00       	call   80105f9d <memmove>
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
8010207a:	e8 c2 3f 00 00       	call   80106041 <strncmp>
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
80102094:	c7 04 24 c5 98 10 80 	movl   $0x801098c5,(%esp)
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
801020d2:	c7 04 24 d7 98 10 80 	movl   $0x801098d7,(%esp)
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
801021b6:	c7 04 24 d7 98 10 80 	movl   $0x801098d7,(%esp)
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
801021fc:	e8 98 3e 00 00       	call   80106099 <strncpy>
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
8010222e:	c7 04 24 e4 98 10 80 	movl   $0x801098e4,(%esp)
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
801022b5:	e8 e3 3c 00 00       	call   80105f9d <memmove>
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
801022d0:	e8 c8 3c 00 00       	call   80105f9d <memmove>
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
80102532:	c7 44 24 04 ec 98 10 	movl   $0x801098ec,0x4(%esp)
80102539:	80 
8010253a:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
80102541:	e8 dc 36 00 00       	call   80105c22 <initlock>
  picenable(IRQ_IDE);
80102546:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
8010254d:	e8 6f 1d 00 00       	call   801042c1 <picenable>
  ioapicenable(IRQ_IDE, ncpu - 1);
80102552:	a1 60 77 12 80       	mov    0x80127760,%eax
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
801025de:	c7 04 24 f0 98 10 80 	movl   $0x801098f0,(%esp)
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
80102704:	e8 3a 35 00 00       	call   80105c43 <acquire>
  if((b = idequeue) == 0){
80102709:	a1 54 c6 10 80       	mov    0x8010c654,%eax
8010270e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102711:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102715:	75 11                	jne    80102728 <ideintr+0x31>
    release(&idelock);
80102717:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
8010271e:	e8 bb 35 00 00       	call   80105cde <release>
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
801027a8:	e8 31 35 00 00       	call   80105cde <release>
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
801027c1:	c7 04 24 f9 98 10 80 	movl   $0x801098f9,(%esp)
801027c8:	e8 70 dd ff ff       	call   8010053d <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
801027cd:	8b 45 08             	mov    0x8(%ebp),%eax
801027d0:	8b 00                	mov    (%eax),%eax
801027d2:	83 e0 06             	and    $0x6,%eax
801027d5:	83 f8 02             	cmp    $0x2,%eax
801027d8:	75 0c                	jne    801027e6 <iderw+0x37>
    panic("iderw: nothing to do");
801027da:	c7 04 24 0d 99 10 80 	movl   $0x8010990d,(%esp)
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
801027f9:	c7 04 24 22 99 10 80 	movl   $0x80109922,(%esp)
80102800:	e8 38 dd ff ff       	call   8010053d <panic>

  acquire(&idelock);  //DOC: acquire-lock
80102805:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
8010280c:	e8 32 34 00 00       	call   80105c43 <acquire>

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
8010285e:	e8 7b 34 00 00       	call   80105cde <release>
	sti();
80102863:	e8 7a fc ff ff       	call   801024e2 <sti>
	acquire(&idelock); 
80102868:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
8010286f:	e8 cf 33 00 00       	call   80105c43 <acquire>
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
8010288b:	e8 4e 34 00 00       	call   80105cde <release>
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
80102897:	a1 f4 08 11 80       	mov    0x801108f4,%eax
8010289c:	8b 55 08             	mov    0x8(%ebp),%edx
8010289f:	89 10                	mov    %edx,(%eax)
  return ioapic->data;
801028a1:	a1 f4 08 11 80       	mov    0x801108f4,%eax
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
801028ae:	a1 f4 08 11 80       	mov    0x801108f4,%eax
801028b3:	8b 55 08             	mov    0x8(%ebp),%edx
801028b6:	89 10                	mov    %edx,(%eax)
  ioapic->data = data;
801028b8:	a1 f4 08 11 80       	mov    0x801108f4,%eax
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
801028cb:	a1 64 71 12 80       	mov    0x80127164,%eax
801028d0:	85 c0                	test   %eax,%eax
801028d2:	0f 84 9f 00 00 00    	je     80102977 <ioapicinit+0xb2>
    return;

  ioapic = (volatile struct ioapic*)IOAPIC;
801028d8:	c7 05 f4 08 11 80 00 	movl   $0xfec00000,0x801108f4
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
8010290b:	0f b6 05 60 71 12 80 	movzbl 0x80127160,%eax
80102912:	0f b6 c0             	movzbl %al,%eax
80102915:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80102918:	74 0c                	je     80102926 <ioapicinit+0x61>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
8010291a:	c7 04 24 40 99 10 80 	movl   $0x80109940,(%esp)
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
80102980:	a1 64 71 12 80       	mov    0x80127164,%eax
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
801029e8:	c7 44 24 04 74 99 10 	movl   $0x80109974,0x4(%esp)
801029ef:	80 
801029f0:	c7 04 24 00 09 11 80 	movl   $0x80110900,(%esp)
801029f7:	e8 26 32 00 00       	call   80105c22 <initlock>
  kmem.use_lock = 0;
801029fc:	c7 05 34 09 11 80 00 	movl   $0x0,0x80110934
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
80102a32:	c7 05 34 09 11 80 01 	movl   $0x1,0x80110934
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
80102a89:	81 7d 08 5c a5 12 80 	cmpl   $0x8012a55c,0x8(%ebp)
80102a90:	72 12                	jb     80102aa4 <kfree+0x2d>
80102a92:	8b 45 08             	mov    0x8(%ebp),%eax
80102a95:	89 04 24             	mov    %eax,(%esp)
80102a98:	e8 2b ff ff ff       	call   801029c8 <v2p>
80102a9d:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80102aa2:	76 0c                	jbe    80102ab0 <kfree+0x39>
    panic("kfree");
80102aa4:	c7 04 24 79 99 10 80 	movl   $0x80109979,(%esp)
80102aab:	e8 8d da ff ff       	call   8010053d <panic>

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80102ab0:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80102ab7:	00 
80102ab8:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102abf:	00 
80102ac0:	8b 45 08             	mov    0x8(%ebp),%eax
80102ac3:	89 04 24             	mov    %eax,(%esp)
80102ac6:	e8 ff 33 00 00       	call   80105eca <memset>

  if(kmem.use_lock)
80102acb:	a1 34 09 11 80       	mov    0x80110934,%eax
80102ad0:	85 c0                	test   %eax,%eax
80102ad2:	74 0c                	je     80102ae0 <kfree+0x69>
    acquire(&kmem.lock);
80102ad4:	c7 04 24 00 09 11 80 	movl   $0x80110900,(%esp)
80102adb:	e8 63 31 00 00       	call   80105c43 <acquire>
  r = (struct run*)v;
80102ae0:	8b 45 08             	mov    0x8(%ebp),%eax
80102ae3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
80102ae6:	8b 15 38 09 11 80    	mov    0x80110938,%edx
80102aec:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102aef:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
80102af1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102af4:	a3 38 09 11 80       	mov    %eax,0x80110938
  if(kmem.use_lock)
80102af9:	a1 34 09 11 80       	mov    0x80110934,%eax
80102afe:	85 c0                	test   %eax,%eax
80102b00:	74 0c                	je     80102b0e <kfree+0x97>
    release(&kmem.lock);
80102b02:	c7 04 24 00 09 11 80 	movl   $0x80110900,(%esp)
80102b09:	e8 d0 31 00 00       	call   80105cde <release>
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
80102b16:	a1 34 09 11 80       	mov    0x80110934,%eax
80102b1b:	85 c0                	test   %eax,%eax
80102b1d:	74 0c                	je     80102b2b <kalloc+0x1b>
    acquire(&kmem.lock);
80102b1f:	c7 04 24 00 09 11 80 	movl   $0x80110900,(%esp)
80102b26:	e8 18 31 00 00       	call   80105c43 <acquire>
  r = kmem.freelist;
80102b2b:	a1 38 09 11 80       	mov    0x80110938,%eax
80102b30:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
80102b33:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102b37:	74 0a                	je     80102b43 <kalloc+0x33>
    kmem.freelist = r->next;
80102b39:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b3c:	8b 00                	mov    (%eax),%eax
80102b3e:	a3 38 09 11 80       	mov    %eax,0x80110938
  if(kmem.use_lock)
80102b43:	a1 34 09 11 80       	mov    0x80110934,%eax
80102b48:	85 c0                	test   %eax,%eax
80102b4a:	74 0c                	je     80102b58 <kalloc+0x48>
    release(&kmem.lock);
80102b4c:	c7 04 24 00 09 11 80 	movl   $0x80110900,(%esp)
80102b53:	e8 86 31 00 00       	call   80105cde <release>
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
80102b72:	c7 04 24 80 99 10 80 	movl   $0x80109980,(%esp)
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
80102bab:	05 84 a7 11 80       	add    $0x8011a784,%eax
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
80102bea:	89 04 95 40 09 11 80 	mov    %eax,-0x7feef6c0(,%edx,4)
80102bf1:	8b 45 08             	mov    0x8(%ebp),%eax
80102bf4:	6b c0 64             	imul   $0x64,%eax,%eax
80102bf7:	03 45 f4             	add    -0xc(%ebp),%eax
80102bfa:	8b 04 85 40 09 11 80 	mov    -0x7feef6c0(,%eax,4),%eax
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
80102c25:	05 40 09 11 80       	add    $0x80110940,%eax
80102c2a:	8b 00                	mov    (%eax),%eax
80102c2c:	89 45 ec             	mov    %eax,-0x14(%ebp)
	  shm.refs[key][1][64] = numOfPages;
80102c2f:	8b 45 08             	mov    0x8(%ebp),%eax
80102c32:	c1 e0 03             	shl    $0x3,%eax
80102c35:	89 c2                	mov    %eax,%edx
80102c37:	c1 e2 06             	shl    $0x6,%edx
80102c3a:	01 d0                	add    %edx,%eax
80102c3c:	8d 90 84 a7 11 80    	lea    -0x7fee587c(%eax),%edx
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
80102c5b:	8b 04 85 40 09 11 80 	mov    -0x7feef6c0(,%eax,4),%eax
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
80102c95:	05 84 a7 11 80       	add    $0x8011a784,%eax
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
80102cb2:	05 40 09 11 80       	add    $0x80110940,%eax
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
80102ce4:	05 40 09 11 80       	add    $0x80110940,%eax
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
80102d01:	05 80 a6 11 80       	add    $0x8011a680,%eax
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
80102d1d:	05 84 a7 11 80       	add    $0x8011a784,%eax
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
80102d39:	8b 04 85 40 09 11 80 	mov    -0x7feef6c0(,%eax,4),%eax
80102d40:	89 04 24             	mov    %eax,(%esp)
80102d43:	e8 2f fd ff ff       	call   80102a77 <kfree>
	    shm.refs[key][1][64]--;
80102d48:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d4b:	c1 e0 03             	shl    $0x3,%eax
80102d4e:	89 c2                	mov    %eax,%edx
80102d50:	c1 e2 06             	shl    $0x6,%edx
80102d53:	01 d0                	add    %edx,%eax
80102d55:	05 84 a7 11 80       	add    $0x8011a784,%eax
80102d5a:	8b 00                	mov    (%eax),%eax
80102d5c:	8d 50 ff             	lea    -0x1(%eax),%edx
80102d5f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d62:	c1 e0 03             	shl    $0x3,%eax
80102d65:	89 c1                	mov    %eax,%ecx
80102d67:	c1 e1 06             	shl    $0x6,%ecx
80102d6a:	01 c8                	add    %ecx,%eax
80102d6c:	05 84 a7 11 80       	add    $0x8011a784,%eax
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
80102db1:	c7 04 24 a0 70 12 80 	movl   $0x801270a0,(%esp)
80102db8:	e8 86 2e 00 00       	call   80105c43 <acquire>
  for(key = 0;key<numOfSegs;key++)		//go over all segments and look for shmid
80102dbd:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80102dc4:	e9 ce 01 00 00       	jmp    80102f97 <shmat+0x1fa>
  {
    if(shmid == (int)shm.seg[key][0])
80102dc9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102dcc:	69 c0 90 01 00 00    	imul   $0x190,%eax,%eax
80102dd2:	05 40 09 11 80       	add    $0x80110940,%eax
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
80102def:	05 84 a7 11 80       	add    $0x8011a784,%eax
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
80102e3e:	05 80 a6 11 80       	add    $0x8011a680,%eax
80102e43:	8b 00                	mov    (%eax),%eax
80102e45:	8d 50 01             	lea    0x1(%eax),%edx
80102e48:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102e4b:	c1 e0 03             	shl    $0x3,%eax
80102e4e:	89 c1                	mov    %eax,%ecx
80102e50:	c1 e1 06             	shl    $0x6,%ecx
80102e53:	01 c8                	add    %ecx,%eax
80102e55:	05 80 a6 11 80       	add    $0x8011a680,%eax
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
80102e78:	c7 04 85 40 09 11 80 	movl   $0x1,-0x7feef6c0(,%eax,4)
80102e7f:	01 00 00 00 
	proc->has_shm++;			//increment counter to indicate amount of attached segments for the proc
80102e83:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80102e89:	8b 90 90 00 00 00    	mov    0x90(%eax),%edx
80102e8f:	83 c2 01             	add    $0x1,%edx
80102e92:	89 90 90 00 00 00    	mov    %edx,0x90(%eax)
	
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
80102eb4:	8b 04 85 40 09 11 80 	mov    -0x7feef6c0(,%eax,4),%eax
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
80102f00:	e8 b4 5f 00 00       	call   80108eb9 <mappages>
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
80102f3a:	e8 7a 5f 00 00       	call   80108eb9 <mappages>
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
80102f60:	05 84 a7 11 80       	add    $0x8011a784,%eax
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
80102fa4:	c7 04 24 a0 70 12 80 	movl   $0x801270a0,(%esp)
80102fab:	e8 2e 2d 00 00       	call   80105cde <release>
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
80102fd6:	e8 48 5e 00 00       	call   80108e23 <walkpgdir>
80102fdb:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  r = (int)p2v(PTE_ADDR(*pte)) ;			//translate PTE to kernel address of page
80102fde:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102fe1:	8b 00                	mov    (%eax),%eax
80102fe3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80102fe8:	89 04 24             	mov    %eax,(%esp)
80102feb:	e8 e5 f9 ff ff       	call   801029d5 <p2v>
80102ff0:	89 45 e0             	mov    %eax,-0x20(%ebp)
  acquire(&shm.lock);
80102ff3:	c7 04 24 a0 70 12 80 	movl   $0x801270a0,(%esp)
80102ffa:	e8 44 2c 00 00       	call   80105c43 <acquire>
  for(found = 0,key = 0;key<numOfSegs;key++)	//go over segments and look for a match
80102fff:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80103006:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
8010300d:	e9 04 01 00 00       	jmp    80103116 <shmdt+0x161>
  {    
    if((int)shm.seg[key][0] == r)
80103012:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103015:	69 c0 90 01 00 00    	imul   $0x190,%eax,%eax
8010301b:	05 40 09 11 80       	add    $0x80110940,%eax
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
80103038:	05 84 a7 11 80       	add    $0x8011a784,%eax
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
80103054:	05 80 a6 11 80       	add    $0x8011a680,%eax
80103059:	8b 00                	mov    (%eax),%eax
8010305b:	85 c0                	test   %eax,%eax
8010305d:	7f 16                	jg     80103075 <shmdt+0xc0>
	{
	  cprintf("shmdt exception - trying to detach a segment with no references\n");
8010305f:	c7 04 24 b8 99 10 80 	movl   $0x801099b8,(%esp)
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
80103082:	05 80 a6 11 80       	add    $0x8011a680,%eax
80103087:	8b 00                	mov    (%eax),%eax
80103089:	8d 50 ff             	lea    -0x1(%eax),%edx
8010308c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010308f:	c1 e0 03             	shl    $0x3,%eax
80103092:	89 c1                	mov    %eax,%ecx
80103094:	c1 e1 06             	shl    $0x6,%ecx
80103097:	01 c8                	add    %ecx,%eax
80103099:	05 80 a6 11 80       	add    $0x8011a680,%eax
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
801030bc:	c7 04 85 40 09 11 80 	movl   $0x0,-0x7feef6c0(,%eax,4)
801030c3:	00 00 00 00 
	proc->has_shm--;			//decrement the counter of how many segs the proc has attached
801030c7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801030cd:	8b 90 90 00 00 00    	mov    0x90(%eax),%edx
801030d3:	83 ea 01             	sub    $0x1,%edx
801030d6:	89 90 90 00 00 00    	mov    %edx,0x90(%eax)
	numOfPages = shm.refs[key][1][64];
801030dc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801030df:	c1 e0 03             	shl    $0x3,%eax
801030e2:	89 c2                	mov    %eax,%edx
801030e4:	c1 e2 06             	shl    $0x6,%edx
801030e7:	01 d0                	add    %edx,%eax
801030e9:	05 84 a7 11 80       	add    $0x8011a784,%eax
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
801030fc:	c7 04 24 fc 99 10 80 	movl   $0x801099fc,(%esp)
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
80103120:	c7 04 24 a0 70 12 80 	movl   $0x801270a0,(%esp)
80103127:	e8 b2 2b 00 00       	call   80105cde <release>
  
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
8010315c:	e8 c2 5c 00 00       	call   80108e23 <walkpgdir>
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
801031a3:	c7 04 24 a0 70 12 80 	movl   $0x801270a0,(%esp)
801031aa:	e8 94 2a 00 00       	call   80105c43 <acquire>
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
801031d7:	8b 04 85 40 09 11 80 	mov    -0x7feef6c0(,%eax,4),%eax
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
80103206:	e8 18 5c 00 00       	call   80108e23 <walkpgdir>
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
8010324e:	05 40 09 11 80       	add    $0x80110940,%eax
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
80103271:	05 84 a7 11 80       	add    $0x8011a784,%eax
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
80103298:	e8 86 5b 00 00       	call   80108e23 <walkpgdir>
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
801032d8:	05 80 a6 11 80       	add    $0x8011a680,%eax
801032dd:	8b 00                	mov    (%eax),%eax
801032df:	85 c0                	test   %eax,%eax
801032e1:	7e 47                	jle    8010332a <deallocshm+0x194>
	      shm.refs[key][0][64]--;					//decrement the seg ref count
801032e3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801032e6:	c1 e0 03             	shl    $0x3,%eax
801032e9:	89 c2                	mov    %eax,%edx
801032eb:	c1 e2 06             	shl    $0x6,%edx
801032ee:	01 d0                	add    %edx,%eax
801032f0:	05 80 a6 11 80       	add    $0x8011a680,%eax
801032f5:	8b 00                	mov    (%eax),%eax
801032f7:	8d 50 ff             	lea    -0x1(%eax),%edx
801032fa:	8b 45 f0             	mov    -0x10(%ebp),%eax
801032fd:	c1 e0 03             	shl    $0x3,%eax
80103300:	89 c1                	mov    %eax,%ecx
80103302:	c1 e1 06             	shl    $0x6,%ecx
80103305:	01 c8                	add    %ecx,%eax
80103307:	05 80 a6 11 80       	add    $0x8011a680,%eax
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
80103339:	c7 04 24 a0 70 12 80 	movl   $0x801270a0,(%esp)
80103340:	e8 99 29 00 00       	call   80105cde <release>
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
8010350e:	a1 d4 70 12 80       	mov    0x801270d4,%eax
80103513:	8b 55 08             	mov    0x8(%ebp),%edx
80103516:	c1 e2 02             	shl    $0x2,%edx
80103519:	01 c2                	add    %eax,%edx
8010351b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010351e:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
80103520:	a1 d4 70 12 80       	mov    0x801270d4,%eax
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
80103532:	a1 d4 70 12 80       	mov    0x801270d4,%eax
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
801035b7:	a1 d4 70 12 80       	mov    0x801270d4,%eax
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
8010365b:	a1 d4 70 12 80       	mov    0x801270d4,%eax
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
801036ba:	c7 04 24 38 9a 10 80 	movl   $0x80109a38,(%esp)
801036c1:	e8 db cc ff ff       	call   801003a1 <cprintf>
        __builtin_return_address(0));
  }

  if(lapic)
801036c6:	a1 d4 70 12 80       	mov    0x801270d4,%eax
801036cb:	85 c0                	test   %eax,%eax
801036cd:	74 0f                	je     801036de <cpunum+0x55>
    return lapic[ID]>>24;
801036cf:	a1 d4 70 12 80       	mov    0x801270d4,%eax
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
801036eb:	a1 d4 70 12 80       	mov    0x801270d4,%eax
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
80103818:	c7 44 24 04 64 9a 10 	movl   $0x80109a64,0x4(%esp)
8010381f:	80 
80103820:	c7 04 24 e0 70 12 80 	movl   $0x801270e0,(%esp)
80103827:	e8 f6 23 00 00       	call   80105c22 <initlock>
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
8010384b:	a3 14 71 12 80       	mov    %eax,0x80127114
  log.size = sb.nlog;
80103850:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103853:	a3 18 71 12 80       	mov    %eax,0x80127118
  log.dev = ROOTDEV;
80103858:	c7 05 20 71 12 80 01 	movl   $0x1,0x80127120
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
8010387b:	a1 14 71 12 80       	mov    0x80127114,%eax
80103880:	03 45 f4             	add    -0xc(%ebp),%eax
80103883:	83 c0 01             	add    $0x1,%eax
80103886:	89 c2                	mov    %eax,%edx
80103888:	a1 20 71 12 80       	mov    0x80127120,%eax
8010388d:	89 54 24 04          	mov    %edx,0x4(%esp)
80103891:	89 04 24             	mov    %eax,(%esp)
80103894:	e8 0d c9 ff ff       	call   801001a6 <bread>
80103899:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.sector[tail]); // read dst
8010389c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010389f:	83 c0 10             	add    $0x10,%eax
801038a2:	8b 04 85 e8 70 12 80 	mov    -0x7fed8f18(,%eax,4),%eax
801038a9:	89 c2                	mov    %eax,%edx
801038ab:	a1 20 71 12 80       	mov    0x80127120,%eax
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
801038da:	e8 be 26 00 00       	call   80105f9d <memmove>
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
80103904:	a1 24 71 12 80       	mov    0x80127124,%eax
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
8010391a:	a1 14 71 12 80       	mov    0x80127114,%eax
8010391f:	89 c2                	mov    %eax,%edx
80103921:	a1 20 71 12 80       	mov    0x80127120,%eax
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
80103943:	a3 24 71 12 80       	mov    %eax,0x80127124
  for (i = 0; i < log.lh.n; i++) {
80103948:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010394f:	eb 1b                	jmp    8010396c <read_head+0x58>
    log.lh.sector[i] = lh->sector[i];
80103951:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103954:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103957:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
8010395b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010395e:	83 c2 10             	add    $0x10,%edx
80103961:	89 04 95 e8 70 12 80 	mov    %eax,-0x7fed8f18(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
80103968:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010396c:	a1 24 71 12 80       	mov    0x80127124,%eax
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
80103989:	a1 14 71 12 80       	mov    0x80127114,%eax
8010398e:	89 c2                	mov    %eax,%edx
80103990:	a1 20 71 12 80       	mov    0x80127120,%eax
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
801039ad:	8b 15 24 71 12 80    	mov    0x80127124,%edx
801039b3:	8b 45 ec             	mov    -0x14(%ebp),%eax
801039b6:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
801039b8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801039bf:	eb 1b                	jmp    801039dc <write_head+0x59>
    hb->sector[i] = log.lh.sector[i];
801039c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039c4:	83 c0 10             	add    $0x10,%eax
801039c7:	8b 0c 85 e8 70 12 80 	mov    -0x7fed8f18(,%eax,4),%ecx
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
801039dc:	a1 24 71 12 80       	mov    0x80127124,%eax
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
80103a0e:	c7 05 24 71 12 80 00 	movl   $0x0,0x80127124
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
80103a25:	c7 04 24 e0 70 12 80 	movl   $0x801270e0,(%esp)
80103a2c:	e8 12 22 00 00       	call   80105c43 <acquire>
  while (log.busy) {		//changed sleep to busy - waiting to avoid deadlocks
80103a31:	eb 1d                	jmp    80103a50 <begin_trans+0x31>
  //sleep(&log, &log.lock);
    release(&log.lock);
80103a33:	c7 04 24 e0 70 12 80 	movl   $0x801270e0,(%esp)
80103a3a:	e8 9f 22 00 00       	call   80105cde <release>
    sti();
80103a3f:	e8 c8 fd ff ff       	call   8010380c <sti>
    acquire(&log.lock);
80103a44:	c7 04 24 e0 70 12 80 	movl   $0x801270e0,(%esp)
80103a4b:	e8 f3 21 00 00       	call   80105c43 <acquire>

void
begin_trans(void)
{
  acquire(&log.lock);
  while (log.busy) {		//changed sleep to busy - waiting to avoid deadlocks
80103a50:	a1 1c 71 12 80       	mov    0x8012711c,%eax
80103a55:	85 c0                	test   %eax,%eax
80103a57:	75 da                	jne    80103a33 <begin_trans+0x14>
  //sleep(&log, &log.lock);
    release(&log.lock);
    sti();
    acquire(&log.lock);
  }
  log.busy = 1;
80103a59:	c7 05 1c 71 12 80 01 	movl   $0x1,0x8012711c
80103a60:	00 00 00 
  release(&log.lock);
80103a63:	c7 04 24 e0 70 12 80 	movl   $0x801270e0,(%esp)
80103a6a:	e8 6f 22 00 00       	call   80105cde <release>
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
80103a77:	a1 24 71 12 80       	mov    0x80127124,%eax
80103a7c:	85 c0                	test   %eax,%eax
80103a7e:	7e 19                	jle    80103a99 <commit_trans+0x28>
    write_head();    // Write header to disk -- the real commit
80103a80:	e8 fe fe ff ff       	call   80103983 <write_head>
    install_trans(); // Now install writes to home locations
80103a85:	e8 df fd ff ff       	call   80103869 <install_trans>
    log.lh.n = 0; 
80103a8a:	c7 05 24 71 12 80 00 	movl   $0x0,0x80127124
80103a91:	00 00 00 
    write_head();    // Erase the transaction from the log
80103a94:	e8 ea fe ff ff       	call   80103983 <write_head>
  }
  
  acquire(&log.lock);
80103a99:	c7 04 24 e0 70 12 80 	movl   $0x801270e0,(%esp)
80103aa0:	e8 9e 21 00 00       	call   80105c43 <acquire>
  log.busy = 0;
80103aa5:	c7 05 1c 71 12 80 00 	movl   $0x0,0x8012711c
80103aac:	00 00 00 
  //wakeup(&log);
  release(&log.lock);
80103aaf:	c7 04 24 e0 70 12 80 	movl   $0x801270e0,(%esp)
80103ab6:	e8 23 22 00 00       	call   80105cde <release>
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
80103ac3:	a1 24 71 12 80       	mov    0x80127124,%eax
80103ac8:	83 f8 09             	cmp    $0x9,%eax
80103acb:	7f 12                	jg     80103adf <log_write+0x22>
80103acd:	a1 24 71 12 80       	mov    0x80127124,%eax
80103ad2:	8b 15 18 71 12 80    	mov    0x80127118,%edx
80103ad8:	83 ea 01             	sub    $0x1,%edx
80103adb:	39 d0                	cmp    %edx,%eax
80103add:	7c 0c                	jl     80103aeb <log_write+0x2e>
    panic("too big a transaction");
80103adf:	c7 04 24 68 9a 10 80 	movl   $0x80109a68,(%esp)
80103ae6:	e8 52 ca ff ff       	call   8010053d <panic>
  if (!log.busy)
80103aeb:	a1 1c 71 12 80       	mov    0x8012711c,%eax
80103af0:	85 c0                	test   %eax,%eax
80103af2:	75 0c                	jne    80103b00 <log_write+0x43>
    panic("write outside of trans");
80103af4:	c7 04 24 7e 9a 10 80 	movl   $0x80109a7e,(%esp)
80103afb:	e8 3d ca ff ff       	call   8010053d <panic>

  for (i = 0; i < log.lh.n; i++) {
80103b00:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103b07:	eb 1d                	jmp    80103b26 <log_write+0x69>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
80103b09:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b0c:	83 c0 10             	add    $0x10,%eax
80103b0f:	8b 04 85 e8 70 12 80 	mov    -0x7fed8f18(,%eax,4),%eax
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
80103b26:	a1 24 71 12 80       	mov    0x80127124,%eax
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
80103b3f:	89 04 95 e8 70 12 80 	mov    %eax,-0x7fed8f18(,%edx,4)
  struct buf *lbuf = bread(b->dev, log.start+i+1);
80103b46:	a1 14 71 12 80       	mov    0x80127114,%eax
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
80103b83:	e8 15 24 00 00       	call   80105f9d <memmove>
  bwrite(lbuf);
80103b88:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b8b:	89 04 24             	mov    %eax,(%esp)
80103b8e:	e8 4a c6 ff ff       	call   801001dd <bwrite>
  brelse(lbuf);
80103b93:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b96:	89 04 24             	mov    %eax,(%esp)
80103b99:	e8 79 c6 ff ff       	call   80100217 <brelse>
  if (i == log.lh.n)
80103b9e:	a1 24 71 12 80       	mov    0x80127124,%eax
80103ba3:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103ba6:	75 0d                	jne    80103bb5 <log_write+0xf8>
    log.lh.n++;
80103ba8:	a1 24 71 12 80       	mov    0x80127124,%eax
80103bad:	83 c0 01             	add    $0x1,%eax
80103bb0:	a3 24 71 12 80       	mov    %eax,0x80127124
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
80103c18:	c7 04 24 5c a5 12 80 	movl   $0x8012a55c,(%esp)
80103c1f:	e8 be ed ff ff       	call   801029e2 <kinit1>
  kvmalloc();      // kernel page table
80103c24:	e8 e1 53 00 00       	call   8010900a <kvmalloc>
  mpinit();        // collect info about this machine
80103c29:	e8 63 04 00 00       	call   80104091 <mpinit>
  lapicinit(mpbcpu());
80103c2e:	e8 2e 02 00 00       	call   80103e61 <mpbcpu>
80103c33:	89 04 24             	mov    %eax,(%esp)
80103c36:	e8 f1 f8 ff ff       	call   8010352c <lapicinit>
  seginit();       // set up segments
80103c3b:	e8 6d 4d 00 00       	call   801089ad <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
80103c40:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103c46:	0f b6 00             	movzbl (%eax),%eax
80103c49:	0f b6 c0             	movzbl %al,%eax
80103c4c:	89 44 24 04          	mov    %eax,0x4(%esp)
80103c50:	c7 04 24 95 9a 10 80 	movl   $0x80109a95,(%esp)
80103c57:	e8 45 c7 ff ff       	call   801003a1 <cprintf>
  picinit();       // interrupt controller
80103c5c:	e8 95 06 00 00       	call   801042f6 <picinit>
  ioapicinit();    // another interrupt controller
80103c61:	e8 5f ec ff ff       	call   801028c5 <ioapicinit>
  consoleinit();   // I/O devices & their interrupts
80103c66:	e8 22 ce ff ff       	call   80100a8d <consoleinit>
  uartinit();      // serial port
80103c6b:	e8 88 40 00 00       	call   80107cf8 <uartinit>
  pinit();         // process table
80103c70:	e8 a3 0b 00 00       	call   80104818 <pinit>
  tvinit();        // trap vectors
80103c75:	e8 21 3c 00 00       	call   8010789b <tvinit>
  binit();         // buffer cache
80103c7a:	e8 b5 c3 ff ff       	call   80100034 <binit>
  fileinit();      // file table
80103c7f:	e8 7c d2 ff ff       	call   80100f00 <fileinit>
  iinit();         // inode cache
80103c84:	e8 2a d9 ff ff       	call   801015b3 <iinit>
  ideinit();       // disk
80103c89:	e8 9e e8 ff ff       	call   8010252c <ideinit>
  if(!ismp)
80103c8e:	a1 64 71 12 80       	mov    0x80127164,%eax
80103c93:	85 c0                	test   %eax,%eax
80103c95:	75 05                	jne    80103c9c <main+0x95>
    timerinit();   // uniprocessor timer
80103c97:	e8 42 3b 00 00       	call   801077de <timerinit>
  startothers();   // start other processors
80103c9c:	e8 87 00 00 00       	call   80103d28 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80103ca1:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
80103ca8:	8e 
80103ca9:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
80103cb0:	e8 65 ed ff ff       	call   80102a1a <kinit2>
  userinit();      // first user process
80103cb5:	e8 6b 12 00 00       	call   80104f25 <userinit>
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
80103cc5:	e8 57 53 00 00       	call   80109021 <switchkvm>
  seginit();
80103cca:	e8 de 4c 00 00       	call   801089ad <seginit>
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
80103cf7:	c7 04 24 ac 9a 10 80 	movl   $0x80109aac,(%esp)
80103cfe:	e8 9e c6 ff ff       	call   801003a1 <cprintf>
  idtinit();       // load idt register
80103d03:	e8 07 3d 00 00       	call   80107a0f <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
80103d08:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103d0e:	05 a8 00 00 00       	add    $0xa8,%eax
80103d13:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80103d1a:	00 
80103d1b:	89 04 24             	mov    %eax,(%esp)
80103d1e:	e8 bf fe ff ff       	call   80103be2 <xchg>
  scheduler();     // start running processes
80103d23:	e8 2e 18 00 00       	call   80105556 <scheduler>

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
80103d55:	e8 43 22 00 00       	call   80105f9d <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80103d5a:	c7 45 f4 80 71 12 80 	movl   $0x80127180,-0xc(%ebp)
80103d61:	e9 86 00 00 00       	jmp    80103dec <startothers+0xc4>
    if(c == cpus+cpunum())  // We've started already.
80103d66:	e8 1e f9 ff ff       	call   80103689 <cpunum>
80103d6b:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103d71:	05 80 71 12 80       	add    $0x80127180,%eax
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
80103dec:	a1 60 77 12 80       	mov    0x80127760,%eax
80103df1:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103df7:	05 80 71 12 80       	add    $0x80127180,%eax
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
80103e6b:	b8 80 71 12 80       	mov    $0x80127180,%eax
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
80103ee4:	c7 44 24 04 c0 9a 10 	movl   $0x80109ac0,0x4(%esp)
80103eeb:	80 
80103eec:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103eef:	89 04 24             	mov    %eax,(%esp)
80103ef2:	e8 4a 20 00 00       	call   80105f41 <memcmp>
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
80104025:	c7 44 24 04 c5 9a 10 	movl   $0x80109ac5,0x4(%esp)
8010402c:	80 
8010402d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104030:	89 04 24             	mov    %eax,(%esp)
80104033:	e8 09 1f 00 00       	call   80105f41 <memcmp>
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
80104097:	c7 05 64 c6 10 80 80 	movl   $0x80127180,0x8010c664
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
801040b9:	c7 05 64 71 12 80 01 	movl   $0x1,0x80127164
801040c0:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
801040c3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801040c6:	8b 40 24             	mov    0x24(%eax),%eax
801040c9:	a3 d4 70 12 80       	mov    %eax,0x801270d4
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
801040fe:	8b 04 85 08 9b 10 80 	mov    -0x7fef64f8(,%eax,4),%eax
80104105:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
80104107:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010410a:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(ncpu != proc->apicid){
8010410d:	8b 45 e8             	mov    -0x18(%ebp),%eax
80104110:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80104114:	0f b6 d0             	movzbl %al,%edx
80104117:	a1 60 77 12 80       	mov    0x80127760,%eax
8010411c:	39 c2                	cmp    %eax,%edx
8010411e:	74 2d                	je     8010414d <mpinit+0xbc>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
80104120:	8b 45 e8             	mov    -0x18(%ebp),%eax
80104123:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80104127:	0f b6 d0             	movzbl %al,%edx
8010412a:	a1 60 77 12 80       	mov    0x80127760,%eax
8010412f:	89 54 24 08          	mov    %edx,0x8(%esp)
80104133:	89 44 24 04          	mov    %eax,0x4(%esp)
80104137:	c7 04 24 ca 9a 10 80 	movl   $0x80109aca,(%esp)
8010413e:	e8 5e c2 ff ff       	call   801003a1 <cprintf>
        ismp = 0;
80104143:	c7 05 64 71 12 80 00 	movl   $0x0,0x80127164
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
8010415e:	a1 60 77 12 80       	mov    0x80127760,%eax
80104163:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80104169:	05 80 71 12 80       	add    $0x80127180,%eax
8010416e:	a3 64 c6 10 80       	mov    %eax,0x8010c664
      cpus[ncpu].id = ncpu;
80104173:	8b 15 60 77 12 80    	mov    0x80127760,%edx
80104179:	a1 60 77 12 80       	mov    0x80127760,%eax
8010417e:	69 d2 bc 00 00 00    	imul   $0xbc,%edx,%edx
80104184:	81 c2 80 71 12 80    	add    $0x80127180,%edx
8010418a:	88 02                	mov    %al,(%edx)
      ncpu++;
8010418c:	a1 60 77 12 80       	mov    0x80127760,%eax
80104191:	83 c0 01             	add    $0x1,%eax
80104194:	a3 60 77 12 80       	mov    %eax,0x80127760
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
801041ac:	a2 60 71 12 80       	mov    %al,0x80127160
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
801041ca:	c7 04 24 e8 9a 10 80 	movl   $0x80109ae8,(%esp)
801041d1:	e8 cb c1 ff ff       	call   801003a1 <cprintf>
      ismp = 0;
801041d6:	c7 05 64 71 12 80 00 	movl   $0x0,0x80127164
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
801041ec:	a1 64 71 12 80       	mov    0x80127164,%eax
801041f1:	85 c0                	test   %eax,%eax
801041f3:	75 1d                	jne    80104212 <mpinit+0x181>
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
801041f5:	c7 05 60 77 12 80 01 	movl   $0x1,0x80127760
801041fc:	00 00 00 
    lapic = 0;
801041ff:	c7 05 d4 70 12 80 00 	movl   $0x0,0x801270d4
80104206:	00 00 00 
    ioapicid = 0;
80104209:	c6 05 60 71 12 80 00 	movb   $0x0,0x80127160
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
801044cf:	c7 44 24 04 1c 9b 10 	movl   $0x80109b1c,0x4(%esp)
801044d6:	80 
801044d7:	89 04 24             	mov    %eax,(%esp)
801044da:	e8 43 17 00 00       	call   80105c22 <initlock>
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
80104587:	e8 b7 16 00 00       	call   80105c43 <acquire>
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
801045aa:	e8 68 13 00 00       	call   80105917 <wakeup>
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
801045c9:	e8 49 13 00 00       	call   80105917 <wakeup>
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
801045ee:	e8 eb 16 00 00       	call   80105cde <release>
    kfree((char*)p);
801045f3:	8b 45 08             	mov    0x8(%ebp),%eax
801045f6:	89 04 24             	mov    %eax,(%esp)
801045f9:	e8 79 e4 ff ff       	call   80102a77 <kfree>
801045fe:	eb 0b                	jmp    8010460b <pipeclose+0x90>
  } else
    release(&p->lock);
80104600:	8b 45 08             	mov    0x8(%ebp),%eax
80104603:	89 04 24             	mov    %eax,(%esp)
80104606:	e8 d3 16 00 00       	call   80105cde <release>
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
8010461a:	e8 24 16 00 00       	call   80105c43 <acquire>
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
8010464b:	e8 8e 16 00 00       	call   80105cde <release>
        return -1;
80104650:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104655:	e9 9d 00 00 00       	jmp    801046f7 <pipewrite+0xea>
      }
      wakeup(&p->nread);
8010465a:	8b 45 08             	mov    0x8(%ebp),%eax
8010465d:	05 34 02 00 00       	add    $0x234,%eax
80104662:	89 04 24             	mov    %eax,(%esp)
80104665:	e8 ad 12 00 00       	call   80105917 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
8010466a:	8b 45 08             	mov    0x8(%ebp),%eax
8010466d:	8b 55 08             	mov    0x8(%ebp),%edx
80104670:	81 c2 38 02 00 00    	add    $0x238,%edx
80104676:	89 44 24 04          	mov    %eax,0x4(%esp)
8010467a:	89 14 24             	mov    %edx,(%esp)
8010467d:	e8 80 10 00 00       	call   80105702 <sleep>
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
801046e4:	e8 2e 12 00 00       	call   80105917 <wakeup>
  release(&p->lock);
801046e9:	8b 45 08             	mov    0x8(%ebp),%eax
801046ec:	89 04 24             	mov    %eax,(%esp)
801046ef:	e8 ea 15 00 00       	call   80105cde <release>
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
8010470a:	e8 34 15 00 00       	call   80105c43 <acquire>
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
80104724:	e8 b5 15 00 00       	call   80105cde <release>
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
80104746:	e8 b7 0f 00 00       	call   80105702 <sleep>
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
801047d6:	e8 3c 11 00 00       	call   80105917 <wakeup>
  release(&p->lock);
801047db:	8b 45 08             	mov    0x8(%ebp),%eax
801047de:	89 04 24             	mov    %eax,(%esp)
801047e1:	e8 f8 14 00 00       	call   80105cde <release>
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
8010481e:	c7 44 24 04 24 9b 10 	movl   $0x80109b24,0x4(%esp)
80104825:	80 
80104826:	c7 04 24 80 77 12 80 	movl   $0x80127780,(%esp)
8010482d:	e8 f0 13 00 00       	call   80105c22 <initlock>
  initlock(&swaplock, "swaplock");
80104832:	c7 44 24 04 2b 9b 10 	movl   $0x80109b2b,0x4(%esp)
80104839:	80 
8010483a:	c7 04 24 a0 c6 10 80 	movl   $0x8010c6a0,(%esp)
80104841:	e8 dc 13 00 00       	call   80105c22 <initlock>
  initlock(&wakeuplock, "wakeuplock");
80104846:	c7 44 24 04 34 9b 10 	movl   $0x80109b34,0x4(%esp)
8010484d:	80 
8010484e:	c7 04 24 e0 c6 10 80 	movl   $0x8010c6e0,(%esp)
80104855:	e8 c8 13 00 00       	call   80105c22 <initlock>
}
8010485a:	c9                   	leave  
8010485b:	c3                   	ret    

8010485c <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
8010485c:	55                   	push   %ebp
8010485d:	89 e5                	mov    %esp,%ebp
8010485f:	83 ec 38             	sub    $0x38,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
80104862:	c7 04 24 80 77 12 80 	movl   $0x80127780,(%esp)
80104869:	e8 d5 13 00 00       	call   80105c43 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010486e:	c7 45 f4 b4 77 12 80 	movl   $0x801277b4,-0xc(%ebp)
80104875:	eb 11                	jmp    80104888 <allocproc+0x2c>
    if(p->state == UNUSED)
80104877:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010487a:	8b 40 0c             	mov    0xc(%eax),%eax
8010487d:	85 c0                	test   %eax,%eax
8010487f:	74 26                	je     801048a7 <allocproc+0x4b>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104881:	81 45 f4 94 00 00 00 	addl   $0x94,-0xc(%ebp)
80104888:	81 7d f4 b4 9c 12 80 	cmpl   $0x80129cb4,-0xc(%ebp)
8010488f:	72 e6                	jb     80104877 <allocproc+0x1b>
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
80104891:	c7 04 24 80 77 12 80 	movl   $0x80127780,(%esp)
80104898:	e8 41 14 00 00       	call   80105cde <release>
  return 0;
8010489d:	b8 00 00 00 00       	mov    $0x0,%eax
801048a2:	e9 5a 01 00 00       	jmp    80104a01 <allocproc+0x1a5>
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
    if(p->state == UNUSED)
      goto found;
801048a7:	90                   	nop
  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
801048a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048ab:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
  p->pid = nextpid++;
801048b2:	a1 04 c0 10 80       	mov    0x8010c004,%eax
801048b7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801048ba:	89 42 10             	mov    %eax,0x10(%edx)
801048bd:	83 c0 01             	add    $0x1,%eax
801048c0:	a3 04 c0 10 80       	mov    %eax,0x8010c004
  release(&ptable.lock);
801048c5:	c7 04 24 80 77 12 80 	movl   $0x80127780,(%esp)
801048cc:	e8 0d 14 00 00       	call   80105cde <release>

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
801048d1:	e8 3a e2 ff ff       	call   80102b10 <kalloc>
801048d6:	8b 55 f4             	mov    -0xc(%ebp),%edx
801048d9:	89 42 08             	mov    %eax,0x8(%edx)
801048dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048df:	8b 40 08             	mov    0x8(%eax),%eax
801048e2:	85 c0                	test   %eax,%eax
801048e4:	75 14                	jne    801048fa <allocproc+0x9e>
    p->state = UNUSED;
801048e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048e9:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return 0;
801048f0:	b8 00 00 00 00       	mov    $0x0,%eax
801048f5:	e9 07 01 00 00       	jmp    80104a01 <allocproc+0x1a5>
  }
  sp = p->kstack + KSTACKSIZE;
801048fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048fd:	8b 40 08             	mov    0x8(%eax),%eax
80104900:	05 00 10 00 00       	add    $0x1000,%eax
80104905:	89 45 f0             	mov    %eax,-0x10(%ebp)
  
  // Leave room for trap frame.
  sp -= sizeof *p->tf;
80104908:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
  p->tf = (struct trapframe*)sp;
8010490c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010490f:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104912:	89 50 18             	mov    %edx,0x18(%eax)
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
80104915:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
  *(uint*)sp = (uint)trapret;
80104919:	ba 50 78 10 80       	mov    $0x80107850,%edx
8010491e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104921:	89 10                	mov    %edx,(%eax)

  sp -= sizeof *p->context;
80104923:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
  p->context = (struct context*)sp;
80104927:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010492a:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010492d:	89 50 1c             	mov    %edx,0x1c(%eax)
  memset(p->context, 0, sizeof *p->context);
80104930:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104933:	8b 40 1c             	mov    0x1c(%eax),%eax
80104936:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
8010493d:	00 
8010493e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104945:	00 
80104946:	89 04 24             	mov    %eax,(%esp)
80104949:	e8 7c 15 00 00       	call   80105eca <memset>
  p->context->eip = (uint)forkret;
8010494e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104951:	8b 40 1c             	mov    0x1c(%eax),%eax
80104954:	ba d6 56 10 80       	mov    $0x801056d6,%edx
80104959:	89 50 10             	mov    %edx,0x10(%eax)
  int i = 0;						//added a swpFileName field to each proc which is determined on proc creation
8010495c:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  char name[8];
  name[2] = '.'; name[3] = 's'; name[4] = 'w'; name[5] = 'a'; name[6] = 'p'; name[7] = 0;
80104963:	c6 45 e6 2e          	movb   $0x2e,-0x1a(%ebp)
80104967:	c6 45 e7 73          	movb   $0x73,-0x19(%ebp)
8010496b:	c6 45 e8 77          	movb   $0x77,-0x18(%ebp)
8010496f:	c6 45 e9 61          	movb   $0x61,-0x17(%ebp)
80104973:	c6 45 ea 70          	movb   $0x70,-0x16(%ebp)
80104977:	c6 45 eb 00          	movb   $0x0,-0x15(%ebp)
  name[1] = (char)(((int)'0')+p->pid % 10);
8010497b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010497e:	8b 48 10             	mov    0x10(%eax),%ecx
80104981:	ba 67 66 66 66       	mov    $0x66666667,%edx
80104986:	89 c8                	mov    %ecx,%eax
80104988:	f7 ea                	imul   %edx
8010498a:	c1 fa 02             	sar    $0x2,%edx
8010498d:	89 c8                	mov    %ecx,%eax
8010498f:	c1 f8 1f             	sar    $0x1f,%eax
80104992:	29 c2                	sub    %eax,%edx
80104994:	89 d0                	mov    %edx,%eax
80104996:	c1 e0 02             	shl    $0x2,%eax
80104999:	01 d0                	add    %edx,%eax
8010499b:	01 c0                	add    %eax,%eax
8010499d:	89 ca                	mov    %ecx,%edx
8010499f:	29 c2                	sub    %eax,%edx
801049a1:	89 d0                	mov    %edx,%eax
801049a3:	83 c0 30             	add    $0x30,%eax
801049a6:	88 45 e5             	mov    %al,-0x1b(%ebp)
  if((i=p->pid/10) == 0)
801049a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049ac:	8b 48 10             	mov    0x10(%eax),%ecx
801049af:	ba 67 66 66 66       	mov    $0x66666667,%edx
801049b4:	89 c8                	mov    %ecx,%eax
801049b6:	f7 ea                	imul   %edx
801049b8:	c1 fa 02             	sar    $0x2,%edx
801049bb:	89 c8                	mov    %ecx,%eax
801049bd:	c1 f8 1f             	sar    $0x1f,%eax
801049c0:	89 d1                	mov    %edx,%ecx
801049c2:	29 c1                	sub    %eax,%ecx
801049c4:	89 c8                	mov    %ecx,%eax
801049c6:	89 45 ec             	mov    %eax,-0x14(%ebp)
801049c9:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801049cd:	75 06                	jne    801049d5 <allocproc+0x179>
    name[0] = '0';
801049cf:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
801049d3:	eb 09                	jmp    801049de <allocproc+0x182>
  else
    name[0] = (char)(((int)'0')+i);
801049d5:	8b 45 ec             	mov    -0x14(%ebp),%eax
801049d8:	83 c0 30             	add    $0x30,%eax
801049db:	88 45 e4             	mov    %al,-0x1c(%ebp)
  //release(&ptable.lock);
  safestrcpy(p->swapFileName, name, sizeof(name));
801049de:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049e1:	8d 90 80 00 00 00    	lea    0x80(%eax),%edx
801049e7:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
801049ee:	00 
801049ef:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801049f2:	89 44 24 04          	mov    %eax,0x4(%esp)
801049f6:	89 14 24             	mov    %edx,(%esp)
801049f9:	e8 fc 16 00 00       	call   801060fa <safestrcpy>
  return p;
801049fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104a01:	c9                   	leave  
80104a02:	c3                   	ret    

80104a03 <createInternalProcess>:


void createInternalProcess(const char *name, void (*entrypoint)())		//create a kernel process
{
80104a03:	55                   	push   %ebp
80104a04:	89 e5                	mov    %esp,%ebp
80104a06:	83 ec 28             	sub    $0x28,%esp
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
80104a09:	e8 4e fe ff ff       	call   8010485c <allocproc>
80104a0e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104a11:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104a15:	0f 84 f7 00 00 00    	je     80104b12 <createInternalProcess+0x10f>
    return;

  // Copy process state from p.
  if((np->pgdir = setupkvm(kalloc)) == 0)
80104a1b:	c7 04 24 10 2b 10 80 	movl   $0x80102b10,(%esp)
80104a22:	e8 26 45 00 00       	call   80108f4d <setupkvm>
80104a27:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104a2a:	89 42 04             	mov    %eax,0x4(%edx)
80104a2d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a30:	8b 40 04             	mov    0x4(%eax),%eax
80104a33:	85 c0                	test   %eax,%eax
80104a35:	75 0c                	jne    80104a43 <createInternalProcess+0x40>
      panic("inswapper: out of memory?");
80104a37:	c7 04 24 3f 9b 10 80 	movl   $0x80109b3f,(%esp)
80104a3e:	e8 fa ba ff ff       	call   8010053d <panic>

  np->sz = PGSIZE;
80104a43:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a46:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  np->parent = initproc;				//set parent to init
80104a4c:	8b 15 88 c6 10 80    	mov    0x8010c688,%edx
80104a52:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a55:	89 50 14             	mov    %edx,0x14(%eax)
  memset(np->tf, 0, sizeof(*np->tf));
80104a58:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a5b:	8b 40 18             	mov    0x18(%eax),%eax
80104a5e:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
80104a65:	00 
80104a66:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104a6d:	00 
80104a6e:	89 04 24             	mov    %eax,(%esp)
80104a71:	e8 54 14 00 00       	call   80105eca <memset>
  np->tf->cs = (SEG_KCODE << 3)|0;
80104a76:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a79:	8b 40 18             	mov    0x18(%eax),%eax
80104a7c:	66 c7 40 3c 08 00    	movw   $0x8,0x3c(%eax)
  np->tf->ds = (SEG_KDATA << 3)|0;
80104a82:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a85:	8b 40 18             	mov    0x18(%eax),%eax
80104a88:	66 c7 40 2c 10 00    	movw   $0x10,0x2c(%eax)
  np->tf->es = np->tf->ds;
80104a8e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a91:	8b 40 18             	mov    0x18(%eax),%eax
80104a94:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104a97:	8b 52 18             	mov    0x18(%edx),%edx
80104a9a:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104a9e:	66 89 50 28          	mov    %dx,0x28(%eax)
  np->tf->ss = np->tf->ds;
80104aa2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104aa5:	8b 40 18             	mov    0x18(%eax),%eax
80104aa8:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104aab:	8b 52 18             	mov    0x18(%edx),%edx
80104aae:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104ab2:	66 89 50 48          	mov    %dx,0x48(%eax)
  np->tf->eflags = FL_IF;
80104ab6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ab9:	8b 40 18             	mov    0x18(%eax),%eax
80104abc:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  //np->tf->esp = (uint)entrypoint+PGSIZE;
  //np->tf->eip = (uint)entrypoint;
  np->context->eip = (uint)entrypoint;			//set eip to entrypoint so proc will start running there
80104ac3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ac6:	8b 40 1c             	mov    0x1c(%eax),%eax
80104ac9:	8b 55 0c             	mov    0xc(%ebp),%edx
80104acc:	89 50 10             	mov    %edx,0x10(%eax)

  inswapper = np;
80104acf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ad2:	a3 8c c6 10 80       	mov    %eax,0x8010c68c
  np->cwd = namei("/");					//set cwd to root so all swap files are created there
80104ad7:	c7 04 24 59 9b 10 80 	movl   $0x80109b59,(%esp)
80104ade:	e8 27 d9 ff ff       	call   8010240a <namei>
80104ae3:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104ae6:	89 42 68             	mov    %eax,0x68(%edx)
  safestrcpy(np->name, name, sizeof(name));
80104ae9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104aec:	8d 50 6c             	lea    0x6c(%eax),%edx
80104aef:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80104af6:	00 
80104af7:	8b 45 08             	mov    0x8(%ebp),%eax
80104afa:	89 44 24 04          	mov    %eax,0x4(%esp)
80104afe:	89 14 24             	mov    %edx,(%esp)
80104b01:	e8 f4 15 00 00       	call   801060fa <safestrcpy>
  np->state = RUNNABLE;
80104b06:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b09:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
80104b10:	eb 01                	jmp    80104b13 <createInternalProcess+0x110>
{
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
    return;
80104b12:	90                   	nop

  inswapper = np;
  np->cwd = namei("/");					//set cwd to root so all swap files are created there
  safestrcpy(np->name, name, sizeof(name));
  np->state = RUNNABLE;
}
80104b13:	c9                   	leave  
80104b14:	c3                   	ret    

80104b15 <swapIn>:

void swapIn()						//the inswapper's function
{
80104b15:	55                   	push   %ebp
80104b16:	89 e5                	mov    %esp,%ebp
80104b18:	83 ec 38             	sub    $0x38,%esp
  struct proc* t;
  for(;;)
  {
swapin:
    for(t = ptable.proc; t < &ptable.proc[NPROC]; t++)	//run over all of ptable and look for RUNNABLE_SUSPENDED
80104b1b:	c7 45 f4 b4 77 12 80 	movl   $0x801277b4,-0xc(%ebp)
80104b22:	e9 ca 01 00 00       	jmp    80104cf1 <swapIn+0x1dc>
    {
      if(t->state != RUNNABLE_SUSPENDED)
80104b27:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b2a:	8b 40 0c             	mov    0xc(%eax),%eax
80104b2d:	83 f8 07             	cmp    $0x7,%eax
80104b30:	0f 85 b3 01 00 00    	jne    80104ce9 <swapIn+0x1d4>
	continue;
      
      //open file pid.swap
      if(holding(&ptable.lock))				//release ptable before every file operation and acquire it afterwards
80104b36:	c7 04 24 80 77 12 80 	movl   $0x80127780,(%esp)
80104b3d:	e8 58 12 00 00       	call   80105d9a <holding>
80104b42:	85 c0                	test   %eax,%eax
80104b44:	74 0c                	je     80104b52 <swapIn+0x3d>
	release(&ptable.lock);
80104b46:	c7 04 24 80 77 12 80 	movl   $0x80127780,(%esp)
80104b4d:	e8 8c 11 00 00       	call   80105cde <release>
      if((t->swap = fileopen(t->swapFileName,O_RDONLY)) == 0)	//open the swapfile
80104b52:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b55:	83 e8 80             	sub    $0xffffff80,%eax
80104b58:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104b5f:	00 
80104b60:	89 04 24             	mov    %eax,(%esp)
80104b63:	e8 43 22 00 00       	call   80106dab <fileopen>
80104b68:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104b6b:	89 42 7c             	mov    %eax,0x7c(%edx)
80104b6e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b71:	8b 40 7c             	mov    0x7c(%eax),%eax
80104b74:	85 c0                	test   %eax,%eax
80104b76:	75 1d                	jne    80104b95 <swapIn+0x80>
      {
	cprintf("fileopen failed\n");
80104b78:	c7 04 24 5b 9b 10 80 	movl   $0x80109b5b,(%esp)
80104b7f:	e8 1d b8 ff ff       	call   801003a1 <cprintf>
	acquire(&ptable.lock);
80104b84:	c7 04 24 80 77 12 80 	movl   $0x80127780,(%esp)
80104b8b:	e8 b3 10 00 00       	call   80105c43 <acquire>
	break;
80104b90:	e9 69 01 00 00       	jmp    80104cfe <swapIn+0x1e9>
      }
      acquire(&ptable.lock);
80104b95:	c7 04 24 80 77 12 80 	movl   $0x80127780,(%esp)
80104b9c:	e8 a2 10 00 00       	call   80105c43 <acquire>
            
      // allocate virtual memory
//       if((t->pgdir = setupkvm(kalloc)) == 0)			
// 	panic("inswapper: out of memory?");
      if(!allocuvm(t->pgdir, 0, t->sz))				//allocate virtual memory
80104ba1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ba4:	8b 10                	mov    (%eax),%edx
80104ba6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ba9:	8b 40 04             	mov    0x4(%eax),%eax
80104bac:	89 54 24 08          	mov    %edx,0x8(%esp)
80104bb0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104bb7:	00 
80104bb8:	89 04 24             	mov    %eax,(%esp)
80104bbb:	e8 5f 47 00 00       	call   8010931f <allocuvm>
80104bc0:	85 c0                	test   %eax,%eax
80104bc2:	75 11                	jne    80104bd5 <swapIn+0xc0>
      {
	cprintf("allocuvm failed\n");
80104bc4:	c7 04 24 6c 9b 10 80 	movl   $0x80109b6c,(%esp)
80104bcb:	e8 d1 b7 ff ff       	call   801003a1 <cprintf>
	break;
80104bd0:	e9 29 01 00 00       	jmp    80104cfe <swapIn+0x1e9>
      }
      
      if(holding(&ptable.lock))
80104bd5:	c7 04 24 80 77 12 80 	movl   $0x80127780,(%esp)
80104bdc:	e8 b9 11 00 00       	call   80105d9a <holding>
80104be1:	85 c0                	test   %eax,%eax
80104be3:	74 0c                	je     80104bf1 <swapIn+0xdc>
	release(&ptable.lock);
80104be5:	c7 04 24 80 77 12 80 	movl   $0x80127780,(%esp)
80104bec:	e8 ed 10 00 00       	call   80105cde <release>
      loaduvm(t->pgdir,0,t->swap->ip,0,t->sz);			//load the swap file content to memory
80104bf1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104bf4:	8b 08                	mov    (%eax),%ecx
80104bf6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104bf9:	8b 40 7c             	mov    0x7c(%eax),%eax
80104bfc:	8b 50 10             	mov    0x10(%eax),%edx
80104bff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c02:	8b 40 04             	mov    0x4(%eax),%eax
80104c05:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80104c09:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80104c10:	00 
80104c11:	89 54 24 08          	mov    %edx,0x8(%esp)
80104c15:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104c1c:	00 
80104c1d:	89 04 24             	mov    %eax,(%esp)
80104c20:	e8 0b 46 00 00       	call   80109230 <loaduvm>
      
      int fd;
      for(fd = 0; fd < NOFILE; fd++)
80104c25:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80104c2c:	eb 60                	jmp    80104c8e <swapIn+0x179>
      {
	if(proc->ofile[fd] && proc->ofile[fd] == t->swap)	//close the swap file
80104c2e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c34:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104c37:	83 c2 08             	add    $0x8,%edx
80104c3a:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104c3e:	85 c0                	test   %eax,%eax
80104c40:	74 48                	je     80104c8a <swapIn+0x175>
80104c42:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c48:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104c4b:	83 c2 08             	add    $0x8,%edx
80104c4e:	8b 54 90 08          	mov    0x8(%eax,%edx,4),%edx
80104c52:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c55:	8b 40 7c             	mov    0x7c(%eax),%eax
80104c58:	39 c2                	cmp    %eax,%edx
80104c5a:	75 2e                	jne    80104c8a <swapIn+0x175>
	{
	  fileclose(proc->ofile[fd]);
80104c5c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c62:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104c65:	83 c2 08             	add    $0x8,%edx
80104c68:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104c6c:	89 04 24             	mov    %eax,(%esp)
80104c6f:	e8 50 c3 ff ff       	call   80100fc4 <fileclose>
	  proc->ofile[fd] = 0;
80104c74:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c7a:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104c7d:	83 c2 08             	add    $0x8,%edx
80104c80:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80104c87:	00 
	  break;
80104c88:	eb 0a                	jmp    80104c94 <swapIn+0x17f>
      if(holding(&ptable.lock))
	release(&ptable.lock);
      loaduvm(t->pgdir,0,t->swap->ip,0,t->sz);			//load the swap file content to memory
      
      int fd;
      for(fd = 0; fd < NOFILE; fd++)
80104c8a:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80104c8e:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
80104c92:	7e 9a                	jle    80104c2e <swapIn+0x119>
	  fileclose(proc->ofile[fd]);
	  proc->ofile[fd] = 0;
	  break;
	}
      }
      t->swap=0;
80104c94:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c97:	c7 40 7c 00 00 00 00 	movl   $0x0,0x7c(%eax)
      unlink(t->swapFileName);					//delete the swap file
80104c9e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ca1:	83 e8 80             	sub    $0xffffff80,%eax
80104ca4:	89 04 24             	mov    %eax,(%esp)
80104ca7:	e8 ba 1b 00 00       	call   80106866 <unlink>
      
      acquire(&ptable.lock);
80104cac:	c7 04 24 80 77 12 80 	movl   $0x80127780,(%esp)
80104cb3:	e8 8b 0f 00 00       	call   80105c43 <acquire>
      t->state = RUNNABLE;
80104cb8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104cbb:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      
      acquire(&swaplock);
80104cc2:	c7 04 24 a0 c6 10 80 	movl   $0x8010c6a0,(%esp)
80104cc9:	e8 75 0f 00 00       	call   80105c43 <acquire>
      swappedout--;						//update swapped out counter atomically
80104cce:	a1 84 c6 10 80       	mov    0x8010c684,%eax
80104cd3:	83 e8 01             	sub    $0x1,%eax
80104cd6:	a3 84 c6 10 80       	mov    %eax,0x8010c684
      release(&swaplock);
80104cdb:	c7 04 24 a0 c6 10 80 	movl   $0x8010c6a0,(%esp)
80104ce2:	e8 f7 0f 00 00       	call   80105cde <release>
80104ce7:	eb 01                	jmp    80104cea <swapIn+0x1d5>
  {
swapin:
    for(t = ptable.proc; t < &ptable.proc[NPROC]; t++)	//run over all of ptable and look for RUNNABLE_SUSPENDED
    {
      if(t->state != RUNNABLE_SUSPENDED)
	continue;
80104ce9:	90                   	nop
{
  struct proc* t;
  for(;;)
  {
swapin:
    for(t = ptable.proc; t < &ptable.proc[NPROC]; t++)	//run over all of ptable and look for RUNNABLE_SUSPENDED
80104cea:	81 45 f4 94 00 00 00 	addl   $0x94,-0xc(%ebp)
80104cf1:	81 7d f4 b4 9c 12 80 	cmpl   $0x80129cb4,-0xc(%ebp)
80104cf8:	0f 82 29 fe ff ff    	jb     80104b27 <swapIn+0x12>
      acquire(&swaplock);
      swappedout--;						//update swapped out counter atomically
      release(&swaplock);
    }
   
    acquire(&swaplock);
80104cfe:	c7 04 24 a0 c6 10 80 	movl   $0x8010c6a0,(%esp)
80104d05:	e8 39 0f 00 00       	call   80105c43 <acquire>
    if(swappedout > 0)						//check if should sleep
80104d0a:	a1 84 c6 10 80       	mov    0x8010c684,%eax
80104d0f:	85 c0                	test   %eax,%eax
80104d11:	7e 11                	jle    80104d24 <swapIn+0x20f>
    {
      release(&swaplock);
80104d13:	c7 04 24 a0 c6 10 80 	movl   $0x8010c6a0,(%esp)
80104d1a:	e8 bf 0f 00 00       	call   80105cde <release>
      goto swapin;
80104d1f:	e9 f7 fd ff ff       	jmp    80104b1b <swapIn+0x6>
    }
    else
      release(&swaplock);
80104d24:	c7 04 24 a0 c6 10 80 	movl   $0x8010c6a0,(%esp)
80104d2b:	e8 ae 0f 00 00       	call   80105cde <release>

    proc->chan = inswapper;
80104d30:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d36:	8b 15 8c c6 10 80    	mov    0x8010c68c,%edx
80104d3c:	89 50 20             	mov    %edx,0x20(%eax)
    proc->state = SLEEPING;					//set inswapper to sleeping
80104d3f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d45:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
     
     sched();
80104d4c:	e8 a1 08 00 00       	call   801055f2 <sched>
     proc->chan = 0;
80104d51:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d57:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)
  }
80104d5e:	e9 b8 fd ff ff       	jmp    80104b1b <swapIn+0x6>

80104d63 <swapOut>:
}

void
swapOut()
{
80104d63:	55                   	push   %ebp
80104d64:	89 e5                	mov    %esp,%ebp
80104d66:	53                   	push   %ebx
80104d67:	83 ec 24             	sub    $0x24,%esp
    if((proc->swap = fileopen(proc->swapFileName,(O_CREATE | O_RDWR))) == 0)	//create the swapfile
80104d6a:	65 8b 1d 04 00 00 00 	mov    %gs:0x4,%ebx
80104d71:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d77:	83 e8 80             	sub    $0xffffff80,%eax
80104d7a:	c7 44 24 04 02 02 00 	movl   $0x202,0x4(%esp)
80104d81:	00 
80104d82:	89 04 24             	mov    %eax,(%esp)
80104d85:	e8 21 20 00 00       	call   80106dab <fileopen>
80104d8a:	89 43 7c             	mov    %eax,0x7c(%ebx)
80104d8d:	8b 43 7c             	mov    0x7c(%ebx),%eax
80104d90:	85 c0                	test   %eax,%eax
80104d92:	75 1e                	jne    80104db2 <swapOut+0x4f>
    {
	cprintf("could not create swapfile %s\n",proc->swapFileName);
80104d94:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d9a:	83 e8 80             	sub    $0xffffff80,%eax
80104d9d:	89 44 24 04          	mov    %eax,0x4(%esp)
80104da1:	c7 04 24 7d 9b 10 80 	movl   $0x80109b7d,(%esp)
80104da8:	e8 f4 b5 ff ff       	call   801003a1 <cprintf>
	return;
80104dad:	e9 6d 01 00 00       	jmp    80104f1f <swapOut+0x1bc>
    }
    pte_t *pte;
    uint pa, j;
    for(j = 0; j < proc->sz; j += PGSIZE)
80104db2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104db9:	e9 ac 00 00 00       	jmp    80104e6a <swapOut+0x107>
    {
      if((pte = walkpgdir(proc->pgdir, (void *) j, 0)) == 0)		//traverse proc's virtual memory and find valid PTEs 
80104dbe:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104dc1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104dc7:	8b 40 04             	mov    0x4(%eax),%eax
80104dca:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80104dd1:	00 
80104dd2:	89 54 24 04          	mov    %edx,0x4(%esp)
80104dd6:	89 04 24             	mov    %eax,(%esp)
80104dd9:	e8 45 40 00 00       	call   80108e23 <walkpgdir>
80104dde:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104de1:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80104de5:	75 0c                	jne    80104df3 <swapOut+0x90>
	panic("walkpgdir: pte should exist");
80104de7:	c7 04 24 9b 9b 10 80 	movl   $0x80109b9b,(%esp)
80104dee:	e8 4a b7 ff ff       	call   8010053d <panic>
      if(!(*pte & PTE_P))
80104df3:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104df6:	8b 00                	mov    (%eax),%eax
80104df8:	83 e0 01             	and    $0x1,%eax
80104dfb:	85 c0                	test   %eax,%eax
80104dfd:	75 0c                	jne    80104e0b <swapOut+0xa8>
	panic("walkpgdir: page not present");
80104dff:	c7 04 24 b7 9b 10 80 	movl   $0x80109bb7,(%esp)
80104e06:	e8 32 b7 ff ff       	call   8010053d <panic>
      pa = PTE_ADDR(*pte);
80104e0b:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104e0e:	8b 00                	mov    (%eax),%eax
80104e10:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80104e15:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(filewrite(proc->swap, (char*)p2v(pa), PGSIZE) < 0){		//write each PTE found to swapfile
80104e18:	8b 45 e8             	mov    -0x18(%ebp),%eax
80104e1b:	89 04 24             	mov    %eax,(%esp)
80104e1e:	e8 cd f9 ff ff       	call   801047f0 <p2v>
80104e23:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104e2a:	8b 52 7c             	mov    0x7c(%edx),%edx
80104e2d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80104e34:	00 
80104e35:	89 44 24 04          	mov    %eax,0x4(%esp)
80104e39:	89 14 24             	mov    %edx,(%esp)
80104e3c:	e8 64 c3 ff ff       	call   801011a5 <filewrite>
80104e41:	85 c0                	test   %eax,%eax
80104e43:	79 1e                	jns    80104e63 <swapOut+0x100>
	cprintf("could not swap out proc pid %d, filewrite failed\n",proc->pid);
80104e45:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e4b:	8b 40 10             	mov    0x10(%eax),%eax
80104e4e:	89 44 24 04          	mov    %eax,0x4(%esp)
80104e52:	c7 04 24 d4 9b 10 80 	movl   $0x80109bd4,(%esp)
80104e59:	e8 43 b5 ff ff       	call   801003a1 <cprintf>
	return;
80104e5e:	e9 bc 00 00 00       	jmp    80104f1f <swapOut+0x1bc>
	cprintf("could not create swapfile %s\n",proc->swapFileName);
	return;
    }
    pte_t *pte;
    uint pa, j;
    for(j = 0; j < proc->sz; j += PGSIZE)
80104e63:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80104e6a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e70:	8b 00                	mov    (%eax),%eax
80104e72:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104e75:	0f 87 43 ff ff ff    	ja     80104dbe <swapOut+0x5b>
	return;
      }
    }

    int fd;
    for(fd = 0; fd < NOFILE; fd++)
80104e7b:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80104e82:	eb 63                	jmp    80104ee7 <swapOut+0x184>
    {
      if(proc->ofile[fd] && proc->ofile[fd] == proc->swap)		//close swapfile
80104e84:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e8a:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104e8d:	83 c2 08             	add    $0x8,%edx
80104e90:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104e94:	85 c0                	test   %eax,%eax
80104e96:	74 4b                	je     80104ee3 <swapOut+0x180>
80104e98:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e9e:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104ea1:	83 c2 08             	add    $0x8,%edx
80104ea4:	8b 54 90 08          	mov    0x8(%eax,%edx,4),%edx
80104ea8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104eae:	8b 40 7c             	mov    0x7c(%eax),%eax
80104eb1:	39 c2                	cmp    %eax,%edx
80104eb3:	75 2e                	jne    80104ee3 <swapOut+0x180>
      {
	fileclose(proc->ofile[fd]);
80104eb5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ebb:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104ebe:	83 c2 08             	add    $0x8,%edx
80104ec1:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104ec5:	89 04 24             	mov    %eax,(%esp)
80104ec8:	e8 f7 c0 ff ff       	call   80100fc4 <fileclose>
	proc->ofile[fd] = 0;
80104ecd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ed3:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104ed6:	83 c2 08             	add    $0x8,%edx
80104ed9:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80104ee0:	00 
	break;
80104ee1:	eb 0a                	jmp    80104eed <swapOut+0x18a>
	return;
      }
    }

    int fd;
    for(fd = 0; fd < NOFILE; fd++)
80104ee3:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80104ee7:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
80104eeb:	7e 97                	jle    80104e84 <swapOut+0x121>
	fileclose(proc->ofile[fd]);
	proc->ofile[fd] = 0;
	break;
      }
    }
    proc->swap=0;
80104eed:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ef3:	c7 40 7c 00 00 00 00 	movl   $0x0,0x7c(%eax)
    deallocuvm(proc->pgdir,proc->sz,0);				//release user virtual memory
80104efa:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f00:	8b 10                	mov    (%eax),%edx
80104f02:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f08:	8b 40 04             	mov    0x4(%eax),%eax
80104f0b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80104f12:	00 
80104f13:	89 54 24 04          	mov    %edx,0x4(%esp)
80104f17:	89 04 24             	mov    %eax,(%esp)
80104f1a:	e8 da 44 00 00       	call   801093f9 <deallocuvm>
}
80104f1f:	83 c4 24             	add    $0x24,%esp
80104f22:	5b                   	pop    %ebx
80104f23:	5d                   	pop    %ebp
80104f24:	c3                   	ret    

80104f25 <userinit>:

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
80104f25:	55                   	push   %ebp
80104f26:	89 e5                	mov    %esp,%ebp
80104f28:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
80104f2b:	e8 2c f9 ff ff       	call   8010485c <allocproc>
80104f30:	89 45 f4             	mov    %eax,-0xc(%ebp)
  initproc = p;
80104f33:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f36:	a3 88 c6 10 80       	mov    %eax,0x8010c688
  if((p->pgdir = setupkvm(kalloc)) == 0)
80104f3b:	c7 04 24 10 2b 10 80 	movl   $0x80102b10,(%esp)
80104f42:	e8 06 40 00 00       	call   80108f4d <setupkvm>
80104f47:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104f4a:	89 42 04             	mov    %eax,0x4(%edx)
80104f4d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f50:	8b 40 04             	mov    0x4(%eax),%eax
80104f53:	85 c0                	test   %eax,%eax
80104f55:	75 0c                	jne    80104f63 <userinit+0x3e>
    panic("userinit: out of memory?");
80104f57:	c7 04 24 06 9c 10 80 	movl   $0x80109c06,(%esp)
80104f5e:	e8 da b5 ff ff       	call   8010053d <panic>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80104f63:	ba 2c 00 00 00       	mov    $0x2c,%edx
80104f68:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f6b:	8b 40 04             	mov    0x4(%eax),%eax
80104f6e:	89 54 24 08          	mov    %edx,0x8(%esp)
80104f72:	c7 44 24 04 00 c5 10 	movl   $0x8010c500,0x4(%esp)
80104f79:	80 
80104f7a:	89 04 24             	mov    %eax,(%esp)
80104f7d:	e8 23 42 00 00       	call   801091a5 <inituvm>
  p->sz = PGSIZE;
80104f82:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f85:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  memset(p->tf, 0, sizeof(*p->tf));
80104f8b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f8e:	8b 40 18             	mov    0x18(%eax),%eax
80104f91:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
80104f98:	00 
80104f99:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104fa0:	00 
80104fa1:	89 04 24             	mov    %eax,(%esp)
80104fa4:	e8 21 0f 00 00       	call   80105eca <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
80104fa9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104fac:	8b 40 18             	mov    0x18(%eax),%eax
80104faf:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
80104fb5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104fb8:	8b 40 18             	mov    0x18(%eax),%eax
80104fbb:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
  p->tf->es = p->tf->ds;
80104fc1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104fc4:	8b 40 18             	mov    0x18(%eax),%eax
80104fc7:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104fca:	8b 52 18             	mov    0x18(%edx),%edx
80104fcd:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104fd1:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
80104fd5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104fd8:	8b 40 18             	mov    0x18(%eax),%eax
80104fdb:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104fde:	8b 52 18             	mov    0x18(%edx),%edx
80104fe1:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104fe5:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
80104fe9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104fec:	8b 40 18             	mov    0x18(%eax),%eax
80104fef:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
80104ff6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ff9:	8b 40 18             	mov    0x18(%eax),%eax
80104ffc:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
80105003:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105006:	8b 40 18             	mov    0x18(%eax),%eax
80105009:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
80105010:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105013:	83 c0 6c             	add    $0x6c,%eax
80105016:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
8010501d:	00 
8010501e:	c7 44 24 04 1f 9c 10 	movl   $0x80109c1f,0x4(%esp)
80105025:	80 
80105026:	89 04 24             	mov    %eax,(%esp)
80105029:	e8 cc 10 00 00       	call   801060fa <safestrcpy>
  p->cwd = namei("/");
8010502e:	c7 04 24 59 9b 10 80 	movl   $0x80109b59,(%esp)
80105035:	e8 d0 d3 ff ff       	call   8010240a <namei>
8010503a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010503d:	89 42 68             	mov    %eax,0x68(%edx)

  p->state = RUNNABLE;
80105040:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105043:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)

  createInternalProcess("inswapper", swapIn);
8010504a:	c7 44 24 04 15 4b 10 	movl   $0x80104b15,0x4(%esp)
80105051:	80 
80105052:	c7 04 24 28 9c 10 80 	movl   $0x80109c28,(%esp)
80105059:	e8 a5 f9 ff ff       	call   80104a03 <createInternalProcess>
}
8010505e:	c9                   	leave  
8010505f:	c3                   	ret    

80105060 <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
80105060:	55                   	push   %ebp
80105061:	89 e5                	mov    %esp,%ebp
80105063:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  
  sz = proc->sz;
80105066:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010506c:	8b 00                	mov    (%eax),%eax
8010506e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
80105071:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80105075:	7e 34                	jle    801050ab <growproc+0x4b>
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
80105077:	8b 45 08             	mov    0x8(%ebp),%eax
8010507a:	89 c2                	mov    %eax,%edx
8010507c:	03 55 f4             	add    -0xc(%ebp),%edx
8010507f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105085:	8b 40 04             	mov    0x4(%eax),%eax
80105088:	89 54 24 08          	mov    %edx,0x8(%esp)
8010508c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010508f:	89 54 24 04          	mov    %edx,0x4(%esp)
80105093:	89 04 24             	mov    %eax,(%esp)
80105096:	e8 84 42 00 00       	call   8010931f <allocuvm>
8010509b:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010509e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801050a2:	75 41                	jne    801050e5 <growproc+0x85>
      return -1;
801050a4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801050a9:	eb 58                	jmp    80105103 <growproc+0xa3>
  } else if(n < 0){
801050ab:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801050af:	79 34                	jns    801050e5 <growproc+0x85>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
801050b1:	8b 45 08             	mov    0x8(%ebp),%eax
801050b4:	89 c2                	mov    %eax,%edx
801050b6:	03 55 f4             	add    -0xc(%ebp),%edx
801050b9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050bf:	8b 40 04             	mov    0x4(%eax),%eax
801050c2:	89 54 24 08          	mov    %edx,0x8(%esp)
801050c6:	8b 55 f4             	mov    -0xc(%ebp),%edx
801050c9:	89 54 24 04          	mov    %edx,0x4(%esp)
801050cd:	89 04 24             	mov    %eax,(%esp)
801050d0:	e8 24 43 00 00       	call   801093f9 <deallocuvm>
801050d5:	89 45 f4             	mov    %eax,-0xc(%ebp)
801050d8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801050dc:	75 07                	jne    801050e5 <growproc+0x85>
      return -1;
801050de:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801050e3:	eb 1e                	jmp    80105103 <growproc+0xa3>
  }
  proc->sz = sz;
801050e5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050eb:	8b 55 f4             	mov    -0xc(%ebp),%edx
801050ee:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
801050f0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050f6:	89 04 24             	mov    %eax,(%esp)
801050f9:	e8 40 3f 00 00       	call   8010903e <switchuvm>
  return 0;
801050fe:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105103:	c9                   	leave  
80105104:	c3                   	ret    

80105105 <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
80105105:	55                   	push   %ebp
80105106:	89 e5                	mov    %esp,%ebp
80105108:	57                   	push   %edi
80105109:	56                   	push   %esi
8010510a:	53                   	push   %ebx
8010510b:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
8010510e:	e8 49 f7 ff ff       	call   8010485c <allocproc>
80105113:	89 45 e0             	mov    %eax,-0x20(%ebp)
80105116:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
8010511a:	75 0a                	jne    80105126 <fork+0x21>
    return -1;
8010511c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105121:	e9 3a 01 00 00       	jmp    80105260 <fork+0x15b>
  
  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
80105126:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010512c:	8b 10                	mov    (%eax),%edx
8010512e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105134:	8b 40 04             	mov    0x4(%eax),%eax
80105137:	89 54 24 04          	mov    %edx,0x4(%esp)
8010513b:	89 04 24             	mov    %eax,(%esp)
8010513e:	e8 46 44 00 00       	call   80109589 <copyuvm>
80105143:	8b 55 e0             	mov    -0x20(%ebp),%edx
80105146:	89 42 04             	mov    %eax,0x4(%edx)
80105149:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010514c:	8b 40 04             	mov    0x4(%eax),%eax
8010514f:	85 c0                	test   %eax,%eax
80105151:	75 2c                	jne    8010517f <fork+0x7a>
    kfree(np->kstack);
80105153:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105156:	8b 40 08             	mov    0x8(%eax),%eax
80105159:	89 04 24             	mov    %eax,(%esp)
8010515c:	e8 16 d9 ff ff       	call   80102a77 <kfree>
    np->kstack = 0;
80105161:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105164:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
8010516b:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010516e:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
80105175:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010517a:	e9 e1 00 00 00       	jmp    80105260 <fork+0x15b>
  }
  np->sz = proc->sz;
8010517f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105185:	8b 10                	mov    (%eax),%edx
80105187:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010518a:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
8010518c:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80105193:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105196:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *proc->tf;
80105199:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010519c:	8b 50 18             	mov    0x18(%eax),%edx
8010519f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801051a5:	8b 40 18             	mov    0x18(%eax),%eax
801051a8:	89 c3                	mov    %eax,%ebx
801051aa:	b8 13 00 00 00       	mov    $0x13,%eax
801051af:	89 d7                	mov    %edx,%edi
801051b1:	89 de                	mov    %ebx,%esi
801051b3:	89 c1                	mov    %eax,%ecx
801051b5:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
801051b7:	8b 45 e0             	mov    -0x20(%ebp),%eax
801051ba:	8b 40 18             	mov    0x18(%eax),%eax
801051bd:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
801051c4:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
801051cb:	eb 3d                	jmp    8010520a <fork+0x105>
    if(proc->ofile[i])
801051cd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801051d3:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801051d6:	83 c2 08             	add    $0x8,%edx
801051d9:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801051dd:	85 c0                	test   %eax,%eax
801051df:	74 25                	je     80105206 <fork+0x101>
      np->ofile[i] = filedup(proc->ofile[i]);
801051e1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801051e7:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801051ea:	83 c2 08             	add    $0x8,%edx
801051ed:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801051f1:	89 04 24             	mov    %eax,(%esp)
801051f4:	e8 83 bd ff ff       	call   80100f7c <filedup>
801051f9:	8b 55 e0             	mov    -0x20(%ebp),%edx
801051fc:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
801051ff:	83 c1 08             	add    $0x8,%ecx
80105202:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
80105206:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
8010520a:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
8010520e:	7e bd                	jle    801051cd <fork+0xc8>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
80105210:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105216:	8b 40 68             	mov    0x68(%eax),%eax
80105219:	89 04 24             	mov    %eax,(%esp)
8010521c:	e8 15 c6 ff ff       	call   80101836 <idup>
80105221:	8b 55 e0             	mov    -0x20(%ebp),%edx
80105224:	89 42 68             	mov    %eax,0x68(%edx)
 
  pid = np->pid;
80105227:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010522a:	8b 40 10             	mov    0x10(%eax),%eax
8010522d:	89 45 dc             	mov    %eax,-0x24(%ebp)
  np->state = RUNNABLE;
80105230:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105233:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  safestrcpy(np->name, proc->name, sizeof(proc->name));
8010523a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105240:	8d 50 6c             	lea    0x6c(%eax),%edx
80105243:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105246:	83 c0 6c             	add    $0x6c,%eax
80105249:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80105250:	00 
80105251:	89 54 24 04          	mov    %edx,0x4(%esp)
80105255:	89 04 24             	mov    %eax,(%esp)
80105258:	e8 9d 0e 00 00       	call   801060fa <safestrcpy>
  return pid;
8010525d:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
80105260:	83 c4 2c             	add    $0x2c,%esp
80105263:	5b                   	pop    %ebx
80105264:	5e                   	pop    %esi
80105265:	5f                   	pop    %edi
80105266:	5d                   	pop    %ebp
80105267:	c3                   	ret    

80105268 <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
80105268:	55                   	push   %ebp
80105269:	89 e5                	mov    %esp,%ebp
8010526b:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int fd;

  if(proc == initproc)
8010526e:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80105275:	a1 88 c6 10 80       	mov    0x8010c688,%eax
8010527a:	39 c2                	cmp    %eax,%edx
8010527c:	75 0c                	jne    8010528a <exit+0x22>
    panic("init exiting");
8010527e:	c7 04 24 32 9c 10 80 	movl   $0x80109c32,(%esp)
80105285:	e8 b3 b2 ff ff       	call   8010053d <panic>

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
8010528a:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80105291:	eb 44                	jmp    801052d7 <exit+0x6f>
    if(proc->ofile[fd]){
80105293:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105299:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010529c:	83 c2 08             	add    $0x8,%edx
8010529f:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801052a3:	85 c0                	test   %eax,%eax
801052a5:	74 2c                	je     801052d3 <exit+0x6b>
      fileclose(proc->ofile[fd]);
801052a7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801052ad:	8b 55 f0             	mov    -0x10(%ebp),%edx
801052b0:	83 c2 08             	add    $0x8,%edx
801052b3:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801052b7:	89 04 24             	mov    %eax,(%esp)
801052ba:	e8 05 bd ff ff       	call   80100fc4 <fileclose>
      proc->ofile[fd] = 0;
801052bf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801052c5:	8b 55 f0             	mov    -0x10(%ebp),%edx
801052c8:	83 c2 08             	add    $0x8,%edx
801052cb:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
801052d2:	00 

  if(proc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
801052d3:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
801052d7:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
801052db:	7e b6                	jle    80105293 <exit+0x2b>
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  iput(proc->cwd);
801052dd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801052e3:	8b 40 68             	mov    0x68(%eax),%eax
801052e6:	89 04 24             	mov    %eax,(%esp)
801052e9:	e8 2d c7 ff ff       	call   80101a1b <iput>
  proc->cwd = 0;
801052ee:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801052f4:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)
  
  if(proc->has_shm)
801052fb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105301:	8b 80 90 00 00 00    	mov    0x90(%eax),%eax
80105307:	85 c0                	test   %eax,%eax
80105309:	74 11                	je     8010531c <exit+0xb4>
    deallocshm(proc->pid);		//deallocate any shared memory segments proc did not shmdt
8010530b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105311:	8b 40 10             	mov    0x10(%eax),%eax
80105314:	89 04 24             	mov    %eax,(%esp)
80105317:	e8 7a de ff ff       	call   80103196 <deallocshm>
  
  acquire(&ptable.lock);
8010531c:	c7 04 24 80 77 12 80 	movl   $0x80127780,(%esp)
80105323:	e8 1b 09 00 00       	call   80105c43 <acquire>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);
80105328:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010532e:	8b 40 14             	mov    0x14(%eax),%eax
80105331:	89 04 24             	mov    %eax,(%esp)
80105334:	e8 19 05 00 00       	call   80105852 <wakeup1>

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105339:	c7 45 f4 b4 77 12 80 	movl   $0x801277b4,-0xc(%ebp)
80105340:	eb 3b                	jmp    8010537d <exit+0x115>
    if(p->parent == proc){
80105342:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105345:	8b 50 14             	mov    0x14(%eax),%edx
80105348:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010534e:	39 c2                	cmp    %eax,%edx
80105350:	75 24                	jne    80105376 <exit+0x10e>
      p->parent = initproc;
80105352:	8b 15 88 c6 10 80    	mov    0x8010c688,%edx
80105358:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010535b:	89 50 14             	mov    %edx,0x14(%eax)
      if(p->state == ZOMBIE)
8010535e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105361:	8b 40 0c             	mov    0xc(%eax),%eax
80105364:	83 f8 05             	cmp    $0x5,%eax
80105367:	75 0d                	jne    80105376 <exit+0x10e>
        wakeup1(initproc);
80105369:	a1 88 c6 10 80       	mov    0x8010c688,%eax
8010536e:	89 04 24             	mov    %eax,(%esp)
80105371:	e8 dc 04 00 00       	call   80105852 <wakeup1>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105376:	81 45 f4 94 00 00 00 	addl   $0x94,-0xc(%ebp)
8010537d:	81 7d f4 b4 9c 12 80 	cmpl   $0x80129cb4,-0xc(%ebp)
80105384:	72 bc                	jb     80105342 <exit+0xda>
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  proc->state = ZOMBIE;
80105386:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010538c:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
  sched();
80105393:	e8 5a 02 00 00       	call   801055f2 <sched>
  panic("zombie exit");
80105398:	c7 04 24 3f 9c 10 80 	movl   $0x80109c3f,(%esp)
8010539f:	e8 99 b1 ff ff       	call   8010053d <panic>

801053a4 <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
801053a4:	55                   	push   %ebp
801053a5:	89 e5                	mov    %esp,%ebp
801053a7:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
801053aa:	c7 04 24 80 77 12 80 	movl   $0x80127780,(%esp)
801053b1:	e8 8d 08 00 00       	call   80105c43 <acquire>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
801053b6:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801053bd:	c7 45 f4 b4 77 12 80 	movl   $0x801277b4,-0xc(%ebp)
801053c4:	e9 9d 00 00 00       	jmp    80105466 <wait+0xc2>
      if(p->parent != proc)
801053c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053cc:	8b 50 14             	mov    0x14(%eax),%edx
801053cf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801053d5:	39 c2                	cmp    %eax,%edx
801053d7:	0f 85 81 00 00 00    	jne    8010545e <wait+0xba>
        continue;
      havekids = 1;
801053dd:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
      if(p->state == ZOMBIE){
801053e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053e7:	8b 40 0c             	mov    0xc(%eax),%eax
801053ea:	83 f8 05             	cmp    $0x5,%eax
801053ed:	75 70                	jne    8010545f <wait+0xbb>
        // Found one.
        pid = p->pid;
801053ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053f2:	8b 40 10             	mov    0x10(%eax),%eax
801053f5:	89 45 ec             	mov    %eax,-0x14(%ebp)
        kfree(p->kstack);
801053f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053fb:	8b 40 08             	mov    0x8(%eax),%eax
801053fe:	89 04 24             	mov    %eax,(%esp)
80105401:	e8 71 d6 ff ff       	call   80102a77 <kfree>
        p->kstack = 0;
80105406:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105409:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
        freevm(p->pgdir);
80105410:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105413:	8b 40 04             	mov    0x4(%eax),%eax
80105416:	89 04 24             	mov    %eax,(%esp)
80105419:	e8 97 40 00 00       	call   801094b5 <freevm>
        p->state = UNUSED;
8010541e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105421:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        p->pid = 0;
80105428:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010542b:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
        p->parent = 0;
80105432:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105435:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
        p->name[0] = 0;
8010543c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010543f:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)
        p->killed = 0;
80105443:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105446:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
        release(&ptable.lock);
8010544d:	c7 04 24 80 77 12 80 	movl   $0x80127780,(%esp)
80105454:	e8 85 08 00 00       	call   80105cde <release>
        return pid;
80105459:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010545c:	eb 56                	jmp    801054b4 <wait+0x110>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->parent != proc)
        continue;
8010545e:	90                   	nop

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010545f:	81 45 f4 94 00 00 00 	addl   $0x94,-0xc(%ebp)
80105466:	81 7d f4 b4 9c 12 80 	cmpl   $0x80129cb4,-0xc(%ebp)
8010546d:	0f 82 56 ff ff ff    	jb     801053c9 <wait+0x25>
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
80105473:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105477:	74 0d                	je     80105486 <wait+0xe2>
80105479:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010547f:	8b 40 24             	mov    0x24(%eax),%eax
80105482:	85 c0                	test   %eax,%eax
80105484:	74 13                	je     80105499 <wait+0xf5>
      release(&ptable.lock);
80105486:	c7 04 24 80 77 12 80 	movl   $0x80127780,(%esp)
8010548d:	e8 4c 08 00 00       	call   80105cde <release>
      return -1;
80105492:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105497:	eb 1b                	jmp    801054b4 <wait+0x110>
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
80105499:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010549f:	c7 44 24 04 80 77 12 	movl   $0x80127780,0x4(%esp)
801054a6:	80 
801054a7:	89 04 24             	mov    %eax,(%esp)
801054aa:	e8 53 02 00 00       	call   80105702 <sleep>
  }
801054af:	e9 02 ff ff ff       	jmp    801053b6 <wait+0x12>
}
801054b4:	c9                   	leave  
801054b5:	c3                   	ret    

801054b6 <register_handler>:

void
register_handler(sighandler_t sighandler)
{
801054b6:	55                   	push   %ebp
801054b7:	89 e5                	mov    %esp,%ebp
801054b9:	83 ec 28             	sub    $0x28,%esp
  char* addr = uva2ka(proc->pgdir, (char*)proc->tf->esp);
801054bc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054c2:	8b 40 18             	mov    0x18(%eax),%eax
801054c5:	8b 40 44             	mov    0x44(%eax),%eax
801054c8:	89 c2                	mov    %eax,%edx
801054ca:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054d0:	8b 40 04             	mov    0x4(%eax),%eax
801054d3:	89 54 24 04          	mov    %edx,0x4(%esp)
801054d7:	89 04 24             	mov    %eax,(%esp)
801054da:	e8 bb 41 00 00       	call   8010969a <uva2ka>
801054df:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if ((proc->tf->esp & 0xFFF) == 0)
801054e2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054e8:	8b 40 18             	mov    0x18(%eax),%eax
801054eb:	8b 40 44             	mov    0x44(%eax),%eax
801054ee:	25 ff 0f 00 00       	and    $0xfff,%eax
801054f3:	85 c0                	test   %eax,%eax
801054f5:	75 0c                	jne    80105503 <register_handler+0x4d>
    panic("esp_offset == 0");
801054f7:	c7 04 24 4b 9c 10 80 	movl   $0x80109c4b,(%esp)
801054fe:	e8 3a b0 ff ff       	call   8010053d <panic>

    /* open a new frame */
  *(int*)(addr + ((proc->tf->esp - 4) & 0xFFF))
80105503:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105509:	8b 40 18             	mov    0x18(%eax),%eax
8010550c:	8b 40 44             	mov    0x44(%eax),%eax
8010550f:	83 e8 04             	sub    $0x4,%eax
80105512:	25 ff 0f 00 00       	and    $0xfff,%eax
80105517:	03 45 f4             	add    -0xc(%ebp),%eax
          = proc->tf->eip;
8010551a:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80105521:	8b 52 18             	mov    0x18(%edx),%edx
80105524:	8b 52 38             	mov    0x38(%edx),%edx
80105527:	89 10                	mov    %edx,(%eax)
  proc->tf->esp -= 4;
80105529:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010552f:	8b 40 18             	mov    0x18(%eax),%eax
80105532:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80105539:	8b 52 18             	mov    0x18(%edx),%edx
8010553c:	8b 52 44             	mov    0x44(%edx),%edx
8010553f:	83 ea 04             	sub    $0x4,%edx
80105542:	89 50 44             	mov    %edx,0x44(%eax)

    /* update eip */
  proc->tf->eip = (uint)sighandler;
80105545:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010554b:	8b 40 18             	mov    0x18(%eax),%eax
8010554e:	8b 55 08             	mov    0x8(%ebp),%edx
80105551:	89 50 38             	mov    %edx,0x38(%eax)
}
80105554:	c9                   	leave  
80105555:	c3                   	ret    

80105556 <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
80105556:	55                   	push   %ebp
80105557:	89 e5                	mov    %esp,%ebp
80105559:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  
  for(;;){
    // Enable interrupts on this processor.
    sti();
8010555c:	e8 b1 f2 ff ff       	call   80104812 <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
80105561:	c7 04 24 80 77 12 80 	movl   $0x80127780,(%esp)
80105568:	e8 d6 06 00 00       	call   80105c43 <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010556d:	c7 45 f4 b4 77 12 80 	movl   $0x801277b4,-0xc(%ebp)
80105574:	eb 62                	jmp    801055d8 <scheduler+0x82>
      if(p->state != RUNNABLE)
80105576:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105579:	8b 40 0c             	mov    0xc(%eax),%eax
8010557c:	83 f8 03             	cmp    $0x3,%eax
8010557f:	75 4f                	jne    801055d0 <scheduler+0x7a>
        continue;
    
      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
80105581:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105584:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
      switchuvm(p);
8010558a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010558d:	89 04 24             	mov    %eax,(%esp)
80105590:	e8 a9 3a 00 00       	call   8010903e <switchuvm>
      p->state = RUNNING;
80105595:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105598:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      swtch(&cpu->scheduler, proc->context);
8010559f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801055a5:	8b 40 1c             	mov    0x1c(%eax),%eax
801055a8:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801055af:	83 c2 04             	add    $0x4,%edx
801055b2:	89 44 24 04          	mov    %eax,0x4(%esp)
801055b6:	89 14 24             	mov    %edx,(%esp)
801055b9:	e8 b2 0b 00 00       	call   80106170 <swtch>
      switchkvm();
801055be:	e8 5e 3a 00 00       	call   80109021 <switchkvm>
                 
      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
801055c3:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
801055ca:	00 00 00 00 
801055ce:	eb 01                	jmp    801055d1 <scheduler+0x7b>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->state != RUNNABLE)
        continue;
801055d0:	90                   	nop
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801055d1:	81 45 f4 94 00 00 00 	addl   $0x94,-0xc(%ebp)
801055d8:	81 7d f4 b4 9c 12 80 	cmpl   $0x80129cb4,-0xc(%ebp)
801055df:	72 95                	jb     80105576 <scheduler+0x20>
                 
      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
801055e1:	c7 04 24 80 77 12 80 	movl   $0x80127780,(%esp)
801055e8:	e8 f1 06 00 00       	call   80105cde <release>

  }
801055ed:	e9 6a ff ff ff       	jmp    8010555c <scheduler+0x6>

801055f2 <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
801055f2:	55                   	push   %ebp
801055f3:	89 e5                	mov    %esp,%ebp
801055f5:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
801055f8:	c7 04 24 80 77 12 80 	movl   $0x80127780,(%esp)
801055ff:	e8 96 07 00 00       	call   80105d9a <holding>
80105604:	85 c0                	test   %eax,%eax
80105606:	75 0c                	jne    80105614 <sched+0x22>
    panic("sched ptable.lock");
80105608:	c7 04 24 5b 9c 10 80 	movl   $0x80109c5b,(%esp)
8010560f:	e8 29 af ff ff       	call   8010053d <panic>
  if(cpu->ncli != 1)
80105614:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010561a:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105620:	83 f8 01             	cmp    $0x1,%eax
80105623:	74 0c                	je     80105631 <sched+0x3f>
    panic("sched locks");
80105625:	c7 04 24 6d 9c 10 80 	movl   $0x80109c6d,(%esp)
8010562c:	e8 0c af ff ff       	call   8010053d <panic>
  if(proc->state == RUNNING)
80105631:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105637:	8b 40 0c             	mov    0xc(%eax),%eax
8010563a:	83 f8 04             	cmp    $0x4,%eax
8010563d:	75 0c                	jne    8010564b <sched+0x59>
    panic("sched running");
8010563f:	c7 04 24 79 9c 10 80 	movl   $0x80109c79,(%esp)
80105646:	e8 f2 ae ff ff       	call   8010053d <panic>
  if(readeflags()&FL_IF)
8010564b:	e8 ad f1 ff ff       	call   801047fd <readeflags>
80105650:	25 00 02 00 00       	and    $0x200,%eax
80105655:	85 c0                	test   %eax,%eax
80105657:	74 0c                	je     80105665 <sched+0x73>
    panic("sched interruptible");
80105659:	c7 04 24 87 9c 10 80 	movl   $0x80109c87,(%esp)
80105660:	e8 d8 ae ff ff       	call   8010053d <panic>
  intena = cpu->intena;
80105665:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010566b:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80105671:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->context, cpu->scheduler);
80105674:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010567a:	8b 40 04             	mov    0x4(%eax),%eax
8010567d:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80105684:	83 c2 1c             	add    $0x1c,%edx
80105687:	89 44 24 04          	mov    %eax,0x4(%esp)
8010568b:	89 14 24             	mov    %edx,(%esp)
8010568e:	e8 dd 0a 00 00       	call   80106170 <swtch>
  cpu->intena = intena;
80105693:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105699:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010569c:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
801056a2:	c9                   	leave  
801056a3:	c3                   	ret    

801056a4 <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
801056a4:	55                   	push   %ebp
801056a5:	89 e5                	mov    %esp,%ebp
801056a7:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
801056aa:	c7 04 24 80 77 12 80 	movl   $0x80127780,(%esp)
801056b1:	e8 8d 05 00 00       	call   80105c43 <acquire>
  proc->state = RUNNABLE;
801056b6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801056bc:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
801056c3:	e8 2a ff ff ff       	call   801055f2 <sched>
  release(&ptable.lock);
801056c8:	c7 04 24 80 77 12 80 	movl   $0x80127780,(%esp)
801056cf:	e8 0a 06 00 00       	call   80105cde <release>
}
801056d4:	c9                   	leave  
801056d5:	c3                   	ret    

801056d6 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
801056d6:	55                   	push   %ebp
801056d7:	89 e5                	mov    %esp,%ebp
801056d9:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
801056dc:	c7 04 24 80 77 12 80 	movl   $0x80127780,(%esp)
801056e3:	e8 f6 05 00 00       	call   80105cde <release>

  if (first) {
801056e8:	a1 20 c0 10 80       	mov    0x8010c020,%eax
801056ed:	85 c0                	test   %eax,%eax
801056ef:	74 0f                	je     80105700 <forkret+0x2a>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
801056f1:	c7 05 20 c0 10 80 00 	movl   $0x0,0x8010c020
801056f8:	00 00 00 
    initlog();
801056fb:	e8 12 e1 ff ff       	call   80103812 <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
80105700:	c9                   	leave  
80105701:	c3                   	ret    

80105702 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
80105702:	55                   	push   %ebp
80105703:	89 e5                	mov    %esp,%ebp
80105705:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
80105708:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010570e:	85 c0                	test   %eax,%eax
80105710:	75 0c                	jne    8010571e <sleep+0x1c>
    panic("sleep");
80105712:	c7 04 24 9b 9c 10 80 	movl   $0x80109c9b,(%esp)
80105719:	e8 1f ae ff ff       	call   8010053d <panic>

  if(lk == 0)
8010571e:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80105722:	75 0c                	jne    80105730 <sleep+0x2e>
    panic("sleep without lk");
80105724:	c7 04 24 a1 9c 10 80 	movl   $0x80109ca1,(%esp)
8010572b:	e8 0d ae ff ff       	call   8010053d <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
80105730:	81 7d 0c 80 77 12 80 	cmpl   $0x80127780,0xc(%ebp)
80105737:	74 17                	je     80105750 <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
80105739:	c7 04 24 80 77 12 80 	movl   $0x80127780,(%esp)
80105740:	e8 fe 04 00 00       	call   80105c43 <acquire>
    release(lk);
80105745:	8b 45 0c             	mov    0xc(%ebp),%eax
80105748:	89 04 24             	mov    %eax,(%esp)
8010574b:	e8 8e 05 00 00       	call   80105cde <release>
  }

  // Go to sleep.
  proc->chan = chan;
80105750:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105756:	8b 55 08             	mov    0x8(%ebp),%edx
80105759:	89 50 20             	mov    %edx,0x20(%eax)
  proc->state = SLEEPING;
8010575c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105762:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)

  // Swap out
  if(swapFlag)			//check if swapping out is enabled
80105769:	a1 80 c6 10 80       	mov    0x8010c680,%eax
8010576e:	85 c0                	test   %eax,%eax
80105770:	0f 84 a8 00 00 00    	je     8010581e <sleep+0x11c>
  {
    if(proc->pid > 3)		//do not allow init and inswapper to swapout
80105776:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010577c:	8b 40 10             	mov    0x10(%eax),%eax
8010577f:	83 f8 03             	cmp    $0x3,%eax
80105782:	0f 8e 96 00 00 00    	jle    8010581e <sleep+0x11c>
    {
      proc->wokenUp = 0;
80105788:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010578e:	c7 80 8c 00 00 00 00 	movl   $0x0,0x8c(%eax)
80105795:	00 00 00 
      proc->swappingOut = 1;
80105798:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010579e:	c7 80 88 00 00 00 01 	movl   $0x1,0x88(%eax)
801057a5:	00 00 00 
      //if(!holding(&wakeuplock));
      //{
	//cprintf("swapping, proc = %d\n",proc->pid);
	//acquire(&wakeuplock);
      //}
      release(&ptable.lock);	
801057a8:	c7 04 24 80 77 12 80 	movl   $0x80127780,(%esp)
801057af:	e8 2a 05 00 00       	call   80105cde <release>
      swapOut();		//swap out proc
801057b4:	e8 aa f5 ff ff       	call   80104d63 <swapOut>
      acquire(&ptable.lock);
801057b9:	c7 04 24 80 77 12 80 	movl   $0x80127780,(%esp)
801057c0:	e8 7e 04 00 00       	call   80105c43 <acquire>
      proc->swappingOut = 0;	//oran
801057c5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801057cb:	c7 80 88 00 00 00 00 	movl   $0x0,0x88(%eax)
801057d2:	00 00 00 
      //release(&wakeuplock);
      if(proc->wokenUp == 1)
801057d5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801057db:	8b 80 8c 00 00 00    	mov    0x8c(%eax),%eax
801057e1:	83 f8 01             	cmp    $0x1,%eax
801057e4:	75 2b                	jne    80105811 <sleep+0x10f>
      {
	proc->wokenUp = 0;	//oran
801057e6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801057ec:	c7 80 8c 00 00 00 00 	movl   $0x0,0x8c(%eax)
801057f3:	00 00 00 
	proc->state = RUNNABLE_SUSPENDED;
801057f6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801057fc:	c7 40 0c 07 00 00 00 	movl   $0x7,0xc(%eax)
	inswapper->state = RUNNABLE;
80105803:	a1 8c c6 10 80       	mov    0x8010c68c,%eax
80105808:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
8010580f:	eb 0d                	jmp    8010581e <sleep+0x11c>
      }
      else
      {
	proc->state = SLEEPING_SUSPENDED;					//set proc to SLEEPING_SUSPENDED
80105811:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105817:	c7 40 0c 06 00 00 00 	movl   $0x6,0xc(%eax)
	//proc->swappingOut = 0;	//oran						//set flag indicating proc is swapped out
      }
    }
  }
  
  sched();
8010581e:	e8 cf fd ff ff       	call   801055f2 <sched>
  
  // Tidy up.
  proc->chan = 0;
80105823:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105829:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
80105830:	81 7d 0c 80 77 12 80 	cmpl   $0x80127780,0xc(%ebp)
80105837:	74 17                	je     80105850 <sleep+0x14e>
    release(&ptable.lock);
80105839:	c7 04 24 80 77 12 80 	movl   $0x80127780,(%esp)
80105840:	e8 99 04 00 00       	call   80105cde <release>
    acquire(lk);
80105845:	8b 45 0c             	mov    0xc(%ebp),%eax
80105848:	89 04 24             	mov    %eax,(%esp)
8010584b:	e8 f3 03 00 00       	call   80105c43 <acquire>
  }
}
80105850:	c9                   	leave  
80105851:	c3                   	ret    

80105852 <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80105852:	55                   	push   %ebp
80105853:	89 e5                	mov    %esp,%ebp
80105855:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int found_suspended = 0;
80105858:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010585f:	c7 45 f4 b4 77 12 80 	movl   $0x801277b4,-0xc(%ebp)
80105866:	e9 9d 00 00 00       	jmp    80105908 <wakeup1+0xb6>
  {
    if(p->state == SLEEPING && p->chan == chan)
8010586b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010586e:	8b 40 0c             	mov    0xc(%eax),%eax
80105871:	83 f8 02             	cmp    $0x2,%eax
80105874:	75 34                	jne    801058aa <wakeup1+0x58>
80105876:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105879:	8b 40 20             	mov    0x20(%eax),%eax
8010587c:	3b 45 08             	cmp    0x8(%ebp),%eax
8010587f:	75 29                	jne    801058aa <wakeup1+0x58>
      //if(!holding(&wakeuplock));
      //{
	//cprintf("wakeup1, p->pid = %d\n",p->pid);
	 // acquire(&wakeuplock);
      //}
      if(p->swappingOut == 1)
80105881:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105884:	8b 80 88 00 00 00    	mov    0x88(%eax),%eax
8010588a:	83 f8 01             	cmp    $0x1,%eax
8010588d:	75 0f                	jne    8010589e <wakeup1+0x4c>
	p->wokenUp = 1;
8010588f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105892:	c7 80 8c 00 00 00 01 	movl   $0x1,0x8c(%eax)
80105899:	00 00 00 
      //if(!holding(&wakeuplock));
      //{
	//cprintf("wakeup1, p->pid = %d\n",p->pid);
	 // acquire(&wakeuplock);
      //}
      if(p->swappingOut == 1)
8010589c:	eb 63                	jmp    80105901 <wakeup1+0xaf>
	p->wokenUp = 1;
      else
	p->state = RUNNABLE;
8010589e:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058a1:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      //if(!holding(&wakeuplock));
      //{
	//cprintf("wakeup1, p->pid = %d\n",p->pid);
	 // acquire(&wakeuplock);
      //}
      if(p->swappingOut == 1)
801058a8:	eb 57                	jmp    80105901 <wakeup1+0xaf>
	p->wokenUp = 1;
      else
	p->state = RUNNABLE;
      //release(&wakeuplock);
    }
    else if(p->state == SLEEPING_SUSPENDED && p->chan == chan && !found_suspended)	//check if any proc is SLEEPING_SUSPENDED
801058aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058ad:	8b 40 0c             	mov    0xc(%eax),%eax
801058b0:	83 f8 06             	cmp    $0x6,%eax
801058b3:	75 4c                	jne    80105901 <wakeup1+0xaf>
801058b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058b8:	8b 40 20             	mov    0x20(%eax),%eax
801058bb:	3b 45 08             	cmp    0x8(%ebp),%eax
801058be:	75 41                	jne    80105901 <wakeup1+0xaf>
801058c0:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801058c4:	75 3b                	jne    80105901 <wakeup1+0xaf>
    {
      //cprintf("proc = %d\n",proc->pid);
      acquire(&swaplock);
801058c6:	c7 04 24 a0 c6 10 80 	movl   $0x8010c6a0,(%esp)
801058cd:	e8 71 03 00 00       	call   80105c43 <acquire>
      swappedout++;								//increment swapped out counter
801058d2:	a1 84 c6 10 80       	mov    0x8010c684,%eax
801058d7:	83 c0 01             	add    $0x1,%eax
801058da:	a3 84 c6 10 80       	mov    %eax,0x8010c684
      p->state = RUNNABLE_SUSPENDED;						//set state to RUNNABLE_SUSPENDED
801058df:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058e2:	c7 40 0c 07 00 00 00 	movl   $0x7,0xc(%eax)
      inswapper->state = RUNNABLE;						//wakeup inswapper
801058e9:	a1 8c c6 10 80       	mov    0x8010c68c,%eax
801058ee:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      release(&swaplock);
801058f5:	c7 04 24 a0 c6 10 80 	movl   $0x8010c6a0,(%esp)
801058fc:	e8 dd 03 00 00       	call   80105cde <release>
wakeup1(void *chan)
{
  struct proc *p;
  int found_suspended = 0;
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80105901:	81 45 f4 94 00 00 00 	addl   $0x94,-0xc(%ebp)
80105908:	81 7d f4 b4 9c 12 80 	cmpl   $0x80129cb4,-0xc(%ebp)
8010590f:	0f 82 56 ff ff ff    	jb     8010586b <wakeup1+0x19>
      p->state = RUNNABLE_SUSPENDED;						//set state to RUNNABLE_SUSPENDED
      inswapper->state = RUNNABLE;						//wakeup inswapper
      release(&swaplock);
    }
  }
}
80105915:	c9                   	leave  
80105916:	c3                   	ret    

80105917 <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80105917:	55                   	push   %ebp
80105918:	89 e5                	mov    %esp,%ebp
8010591a:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);
8010591d:	c7 04 24 80 77 12 80 	movl   $0x80127780,(%esp)
80105924:	e8 1a 03 00 00       	call   80105c43 <acquire>
  wakeup1(chan);
80105929:	8b 45 08             	mov    0x8(%ebp),%eax
8010592c:	89 04 24             	mov    %eax,(%esp)
8010592f:	e8 1e ff ff ff       	call   80105852 <wakeup1>
  release(&ptable.lock);
80105934:	c7 04 24 80 77 12 80 	movl   $0x80127780,(%esp)
8010593b:	e8 9e 03 00 00       	call   80105cde <release>
}
80105940:	c9                   	leave  
80105941:	c3                   	ret    

80105942 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80105942:	55                   	push   %ebp
80105943:	89 e5                	mov    %esp,%ebp
80105945:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  acquire(&ptable.lock);
80105948:	c7 04 24 80 77 12 80 	movl   $0x80127780,(%esp)
8010594f:	e8 ef 02 00 00       	call   80105c43 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105954:	c7 45 f4 b4 77 12 80 	movl   $0x801277b4,-0xc(%ebp)
8010595b:	e9 8c 00 00 00       	jmp    801059ec <kill+0xaa>
    if(p->pid == pid){
80105960:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105963:	8b 40 10             	mov    0x10(%eax),%eax
80105966:	3b 45 08             	cmp    0x8(%ebp),%eax
80105969:	75 7a                	jne    801059e5 <kill+0xa3>
      p->killed = 1;
8010596b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010596e:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80105975:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105978:	8b 40 0c             	mov    0xc(%eax),%eax
8010597b:	83 f8 02             	cmp    $0x2,%eax
8010597e:	75 0c                	jne    8010598c <kill+0x4a>
        p->state = RUNNABLE;
80105980:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105983:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
8010598a:	eb 46                	jmp    801059d2 <kill+0x90>
      else if(p->state == SLEEPING_SUSPENDED)			//same as wakeup1 - swap in any killed process that is swapped out
8010598c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010598f:	8b 40 0c             	mov    0xc(%eax),%eax
80105992:	83 f8 06             	cmp    $0x6,%eax
80105995:	75 3b                	jne    801059d2 <kill+0x90>
      {
        acquire(&swaplock);
80105997:	c7 04 24 a0 c6 10 80 	movl   $0x8010c6a0,(%esp)
8010599e:	e8 a0 02 00 00       	call   80105c43 <acquire>
      	swappedout++;
801059a3:	a1 84 c6 10 80       	mov    0x8010c684,%eax
801059a8:	83 c0 01             	add    $0x1,%eax
801059ab:	a3 84 c6 10 80       	mov    %eax,0x8010c684
      	p->state = RUNNABLE_SUSPENDED;
801059b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059b3:	c7 40 0c 07 00 00 00 	movl   $0x7,0xc(%eax)
      	inswapper->state = RUNNABLE;
801059ba:	a1 8c c6 10 80       	mov    0x8010c68c,%eax
801059bf:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      	release(&swaplock);
801059c6:	c7 04 24 a0 c6 10 80 	movl   $0x8010c6a0,(%esp)
801059cd:	e8 0c 03 00 00       	call   80105cde <release>
      }
      release(&ptable.lock);
801059d2:	c7 04 24 80 77 12 80 	movl   $0x80127780,(%esp)
801059d9:	e8 00 03 00 00       	call   80105cde <release>
      return 0;
801059de:	b8 00 00 00 00       	mov    $0x0,%eax
801059e3:	eb 25                	jmp    80105a0a <kill+0xc8>
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801059e5:	81 45 f4 94 00 00 00 	addl   $0x94,-0xc(%ebp)
801059ec:	81 7d f4 b4 9c 12 80 	cmpl   $0x80129cb4,-0xc(%ebp)
801059f3:	0f 82 67 ff ff ff    	jb     80105960 <kill+0x1e>
      }
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
801059f9:	c7 04 24 80 77 12 80 	movl   $0x80127780,(%esp)
80105a00:	e8 d9 02 00 00       	call   80105cde <release>
  return -1;
80105a05:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105a0a:	c9                   	leave  
80105a0b:	c3                   	ret    

80105a0c <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80105a0c:	55                   	push   %ebp
80105a0d:	89 e5                	mov    %esp,%ebp
80105a0f:	83 ec 58             	sub    $0x58,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105a12:	c7 45 f0 b4 77 12 80 	movl   $0x801277b4,-0x10(%ebp)
80105a19:	e9 db 00 00 00       	jmp    80105af9 <procdump+0xed>
    if(p->state == UNUSED)
80105a1e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a21:	8b 40 0c             	mov    0xc(%eax),%eax
80105a24:	85 c0                	test   %eax,%eax
80105a26:	0f 84 c5 00 00 00    	je     80105af1 <procdump+0xe5>
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80105a2c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a2f:	8b 40 0c             	mov    0xc(%eax),%eax
80105a32:	83 f8 05             	cmp    $0x5,%eax
80105a35:	77 23                	ja     80105a5a <procdump+0x4e>
80105a37:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a3a:	8b 40 0c             	mov    0xc(%eax),%eax
80105a3d:	8b 04 85 08 c0 10 80 	mov    -0x7fef3ff8(,%eax,4),%eax
80105a44:	85 c0                	test   %eax,%eax
80105a46:	74 12                	je     80105a5a <procdump+0x4e>
      state = states[p->state];
80105a48:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a4b:	8b 40 0c             	mov    0xc(%eax),%eax
80105a4e:	8b 04 85 08 c0 10 80 	mov    -0x7fef3ff8(,%eax,4),%eax
80105a55:	89 45 ec             	mov    %eax,-0x14(%ebp)
80105a58:	eb 07                	jmp    80105a61 <procdump+0x55>
    else
      state = "???";
80105a5a:	c7 45 ec b2 9c 10 80 	movl   $0x80109cb2,-0x14(%ebp)
    cprintf("%d %s %s", p->pid, state, p->name);
80105a61:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a64:	8d 50 6c             	lea    0x6c(%eax),%edx
80105a67:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a6a:	8b 40 10             	mov    0x10(%eax),%eax
80105a6d:	89 54 24 0c          	mov    %edx,0xc(%esp)
80105a71:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105a74:	89 54 24 08          	mov    %edx,0x8(%esp)
80105a78:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a7c:	c7 04 24 b6 9c 10 80 	movl   $0x80109cb6,(%esp)
80105a83:	e8 19 a9 ff ff       	call   801003a1 <cprintf>
    if(p->state == SLEEPING){
80105a88:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a8b:	8b 40 0c             	mov    0xc(%eax),%eax
80105a8e:	83 f8 02             	cmp    $0x2,%eax
80105a91:	75 50                	jne    80105ae3 <procdump+0xd7>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80105a93:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a96:	8b 40 1c             	mov    0x1c(%eax),%eax
80105a99:	8b 40 0c             	mov    0xc(%eax),%eax
80105a9c:	83 c0 08             	add    $0x8,%eax
80105a9f:	8d 55 c4             	lea    -0x3c(%ebp),%edx
80105aa2:	89 54 24 04          	mov    %edx,0x4(%esp)
80105aa6:	89 04 24             	mov    %eax,(%esp)
80105aa9:	e8 7f 02 00 00       	call   80105d2d <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80105aae:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80105ab5:	eb 1b                	jmp    80105ad2 <procdump+0xc6>
        cprintf(" %p", pc[i]);
80105ab7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105aba:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80105abe:	89 44 24 04          	mov    %eax,0x4(%esp)
80105ac2:	c7 04 24 bf 9c 10 80 	movl   $0x80109cbf,(%esp)
80105ac9:	e8 d3 a8 ff ff       	call   801003a1 <cprintf>
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
80105ace:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80105ad2:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
80105ad6:	7f 0b                	jg     80105ae3 <procdump+0xd7>
80105ad8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105adb:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80105adf:	85 c0                	test   %eax,%eax
80105ae1:	75 d4                	jne    80105ab7 <procdump+0xab>
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80105ae3:	c7 04 24 c3 9c 10 80 	movl   $0x80109cc3,(%esp)
80105aea:	e8 b2 a8 ff ff       	call   801003a1 <cprintf>
80105aef:	eb 01                	jmp    80105af2 <procdump+0xe6>
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
80105af1:	90                   	nop
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105af2:	81 45 f0 94 00 00 00 	addl   $0x94,-0x10(%ebp)
80105af9:	81 7d f0 b4 9c 12 80 	cmpl   $0x80129cb4,-0x10(%ebp)
80105b00:	0f 82 18 ff ff ff    	jb     80105a1e <procdump+0x12>
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}
80105b06:	c9                   	leave  
80105b07:	c3                   	ret    

80105b08 <getAllocatedPages>:

int getAllocatedPages(int pid) {			//traverse the process with the given pid's virtual memory and count how many PTE_U pages are allocated
80105b08:	55                   	push   %ebp
80105b09:	89 e5                	mov    %esp,%ebp
80105b0b:	83 ec 38             	sub    $0x38,%esp
  struct proc* p;
  acquire(&ptable.lock);
80105b0e:	c7 04 24 80 77 12 80 	movl   $0x80127780,(%esp)
80105b15:	e8 29 01 00 00       	call   80105c43 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105b1a:	c7 45 f4 b4 77 12 80 	movl   $0x801277b4,-0xc(%ebp)
80105b21:	eb 12                	jmp    80105b35 <getAllocatedPages+0x2d>
    if(p->pid == pid){
80105b23:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b26:	8b 40 10             	mov    0x10(%eax),%eax
80105b29:	3b 45 08             	cmp    0x8(%ebp),%eax
80105b2c:	74 12                	je     80105b40 <getAllocatedPages+0x38>
}

int getAllocatedPages(int pid) {			//traverse the process with the given pid's virtual memory and count how many PTE_U pages are allocated
  struct proc* p;
  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105b2e:	81 45 f4 94 00 00 00 	addl   $0x94,-0xc(%ebp)
80105b35:	81 7d f4 b4 9c 12 80 	cmpl   $0x80129cb4,-0xc(%ebp)
80105b3c:	72 e5                	jb     80105b23 <getAllocatedPages+0x1b>
80105b3e:	eb 01                	jmp    80105b41 <getAllocatedPages+0x39>
    if(p->pid == pid){
     break;
80105b40:	90                   	nop
    }
  }
  release(&ptable.lock);
80105b41:	c7 04 24 80 77 12 80 	movl   $0x80127780,(%esp)
80105b48:	e8 91 01 00 00       	call   80105cde <release>
   int count= 0, j, k;
80105b4d:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   for (j=0; j<1024; j++) {
80105b54:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80105b5b:	eb 71                	jmp    80105bce <getAllocatedPages+0xc6>
      if(p->pgdir){ 
80105b5d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b60:	8b 40 04             	mov    0x4(%eax),%eax
80105b63:	85 c0                	test   %eax,%eax
80105b65:	74 63                	je     80105bca <getAllocatedPages+0xc2>
	if (p->pgdir[j] & PTE_P) {
80105b67:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b6a:	8b 40 04             	mov    0x4(%eax),%eax
80105b6d:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105b70:	c1 e2 02             	shl    $0x2,%edx
80105b73:	01 d0                	add    %edx,%eax
80105b75:	8b 00                	mov    (%eax),%eax
80105b77:	83 e0 01             	and    $0x1,%eax
80105b7a:	84 c0                	test   %al,%al
80105b7c:	74 4c                	je     80105bca <getAllocatedPages+0xc2>
	  pte_t* pte= (pte_t*)p2v(PTE_ADDR(p->pgdir[j]));
80105b7e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b81:	8b 40 04             	mov    0x4(%eax),%eax
80105b84:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105b87:	c1 e2 02             	shl    $0x2,%edx
80105b8a:	01 d0                	add    %edx,%eax
80105b8c:	8b 00                	mov    (%eax),%eax
80105b8e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80105b93:	89 04 24             	mov    %eax,(%esp)
80105b96:	e8 55 ec ff ff       	call   801047f0 <p2v>
80105b9b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	  for (k=0; k<1024; k++) {
80105b9e:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
80105ba5:	eb 1a                	jmp    80105bc1 <getAllocatedPages+0xb9>
	      if ( pte[k] & PTE_U )
80105ba7:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105baa:	c1 e0 02             	shl    $0x2,%eax
80105bad:	03 45 e4             	add    -0x1c(%ebp),%eax
80105bb0:	8b 00                	mov    (%eax),%eax
80105bb2:	83 e0 04             	and    $0x4,%eax
80105bb5:	85 c0                	test   %eax,%eax
80105bb7:	74 04                	je     80105bbd <getAllocatedPages+0xb5>
		count++;
80105bb9:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   int count= 0, j, k;
   for (j=0; j<1024; j++) {
      if(p->pgdir){ 
	if (p->pgdir[j] & PTE_P) {
	  pte_t* pte= (pte_t*)p2v(PTE_ADDR(p->pgdir[j]));
	  for (k=0; k<1024; k++) {
80105bbd:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
80105bc1:	81 7d e8 ff 03 00 00 	cmpl   $0x3ff,-0x18(%ebp)
80105bc8:	7e dd                	jle    80105ba7 <getAllocatedPages+0x9f>
     break;
    }
  }
  release(&ptable.lock);
   int count= 0, j, k;
   for (j=0; j<1024; j++) {
80105bca:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
80105bce:	81 7d ec ff 03 00 00 	cmpl   $0x3ff,-0x14(%ebp)
80105bd5:	7e 86                	jle    80105b5d <getAllocatedPages+0x55>
		count++;
	  }
	}
      }
   }
   return count;
80105bd7:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80105bda:	c9                   	leave  
80105bdb:	c3                   	ret    

80105bdc <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80105bdc:	55                   	push   %ebp
80105bdd:	89 e5                	mov    %esp,%ebp
80105bdf:	53                   	push   %ebx
80105be0:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80105be3:	9c                   	pushf  
80105be4:	5b                   	pop    %ebx
80105be5:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80105be8:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80105beb:	83 c4 10             	add    $0x10,%esp
80105bee:	5b                   	pop    %ebx
80105bef:	5d                   	pop    %ebp
80105bf0:	c3                   	ret    

80105bf1 <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
80105bf1:	55                   	push   %ebp
80105bf2:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
80105bf4:	fa                   	cli    
}
80105bf5:	5d                   	pop    %ebp
80105bf6:	c3                   	ret    

80105bf7 <sti>:

static inline void
sti(void)
{
80105bf7:	55                   	push   %ebp
80105bf8:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80105bfa:	fb                   	sti    
}
80105bfb:	5d                   	pop    %ebp
80105bfc:	c3                   	ret    

80105bfd <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
80105bfd:	55                   	push   %ebp
80105bfe:	89 e5                	mov    %esp,%ebp
80105c00:	53                   	push   %ebx
80105c01:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
80105c04:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80105c07:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
80105c0a:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80105c0d:	89 c3                	mov    %eax,%ebx
80105c0f:	89 d8                	mov    %ebx,%eax
80105c11:	f0 87 02             	lock xchg %eax,(%edx)
80105c14:	89 c3                	mov    %eax,%ebx
80105c16:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80105c19:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80105c1c:	83 c4 10             	add    $0x10,%esp
80105c1f:	5b                   	pop    %ebx
80105c20:	5d                   	pop    %ebp
80105c21:	c3                   	ret    

80105c22 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80105c22:	55                   	push   %ebp
80105c23:	89 e5                	mov    %esp,%ebp
  lk->name = name;
80105c25:	8b 45 08             	mov    0x8(%ebp),%eax
80105c28:	8b 55 0c             	mov    0xc(%ebp),%edx
80105c2b:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80105c2e:	8b 45 08             	mov    0x8(%ebp),%eax
80105c31:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80105c37:	8b 45 08             	mov    0x8(%ebp),%eax
80105c3a:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80105c41:	5d                   	pop    %ebp
80105c42:	c3                   	ret    

80105c43 <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
80105c43:	55                   	push   %ebp
80105c44:	89 e5                	mov    %esp,%ebp
80105c46:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80105c49:	e8 76 01 00 00       	call   80105dc4 <pushcli>
  if(holding(lk))
80105c4e:	8b 45 08             	mov    0x8(%ebp),%eax
80105c51:	89 04 24             	mov    %eax,(%esp)
80105c54:	e8 41 01 00 00       	call   80105d9a <holding>
80105c59:	85 c0                	test   %eax,%eax
80105c5b:	74 45                	je     80105ca2 <acquire+0x5f>
  {
    cprintf("lock = %s\n",lk->name);
80105c5d:	8b 45 08             	mov    0x8(%ebp),%eax
80105c60:	8b 40 04             	mov    0x4(%eax),%eax
80105c63:	89 44 24 04          	mov    %eax,0x4(%esp)
80105c67:	c7 04 24 ef 9c 10 80 	movl   $0x80109cef,(%esp)
80105c6e:	e8 2e a7 ff ff       	call   801003a1 <cprintf>
    if(proc)
80105c73:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105c79:	85 c0                	test   %eax,%eax
80105c7b:	74 19                	je     80105c96 <acquire+0x53>
      cprintf("pid = %d\n",proc->pid);
80105c7d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105c83:	8b 40 10             	mov    0x10(%eax),%eax
80105c86:	89 44 24 04          	mov    %eax,0x4(%esp)
80105c8a:	c7 04 24 fa 9c 10 80 	movl   $0x80109cfa,(%esp)
80105c91:	e8 0b a7 ff ff       	call   801003a1 <cprintf>
    panic("acquire");
80105c96:	c7 04 24 04 9d 10 80 	movl   $0x80109d04,(%esp)
80105c9d:	e8 9b a8 ff ff       	call   8010053d <panic>
  }

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
80105ca2:	90                   	nop
80105ca3:	8b 45 08             	mov    0x8(%ebp),%eax
80105ca6:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80105cad:	00 
80105cae:	89 04 24             	mov    %eax,(%esp)
80105cb1:	e8 47 ff ff ff       	call   80105bfd <xchg>
80105cb6:	85 c0                	test   %eax,%eax
80105cb8:	75 e9                	jne    80105ca3 <acquire+0x60>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
80105cba:	8b 45 08             	mov    0x8(%ebp),%eax
80105cbd:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80105cc4:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
80105cc7:	8b 45 08             	mov    0x8(%ebp),%eax
80105cca:	83 c0 0c             	add    $0xc,%eax
80105ccd:	89 44 24 04          	mov    %eax,0x4(%esp)
80105cd1:	8d 45 08             	lea    0x8(%ebp),%eax
80105cd4:	89 04 24             	mov    %eax,(%esp)
80105cd7:	e8 51 00 00 00       	call   80105d2d <getcallerpcs>
}
80105cdc:	c9                   	leave  
80105cdd:	c3                   	ret    

80105cde <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
80105cde:	55                   	push   %ebp
80105cdf:	89 e5                	mov    %esp,%ebp
80105ce1:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
80105ce4:	8b 45 08             	mov    0x8(%ebp),%eax
80105ce7:	89 04 24             	mov    %eax,(%esp)
80105cea:	e8 ab 00 00 00       	call   80105d9a <holding>
80105cef:	85 c0                	test   %eax,%eax
80105cf1:	75 0c                	jne    80105cff <release+0x21>
    panic("release");
80105cf3:	c7 04 24 0c 9d 10 80 	movl   $0x80109d0c,(%esp)
80105cfa:	e8 3e a8 ff ff       	call   8010053d <panic>

  lk->pcs[0] = 0;
80105cff:	8b 45 08             	mov    0x8(%ebp),%eax
80105d02:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
80105d09:	8b 45 08             	mov    0x8(%ebp),%eax
80105d0c:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
80105d13:	8b 45 08             	mov    0x8(%ebp),%eax
80105d16:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105d1d:	00 
80105d1e:	89 04 24             	mov    %eax,(%esp)
80105d21:	e8 d7 fe ff ff       	call   80105bfd <xchg>

  popcli();
80105d26:	e8 e1 00 00 00       	call   80105e0c <popcli>
}
80105d2b:	c9                   	leave  
80105d2c:	c3                   	ret    

80105d2d <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80105d2d:	55                   	push   %ebp
80105d2e:	89 e5                	mov    %esp,%ebp
80105d30:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
80105d33:	8b 45 08             	mov    0x8(%ebp),%eax
80105d36:	83 e8 08             	sub    $0x8,%eax
80105d39:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
80105d3c:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
80105d43:	eb 32                	jmp    80105d77 <getcallerpcs+0x4a>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80105d45:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
80105d49:	74 47                	je     80105d92 <getcallerpcs+0x65>
80105d4b:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
80105d52:	76 3e                	jbe    80105d92 <getcallerpcs+0x65>
80105d54:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
80105d58:	74 38                	je     80105d92 <getcallerpcs+0x65>
      break;
    pcs[i] = ebp[1];     // saved %eip
80105d5a:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105d5d:	c1 e0 02             	shl    $0x2,%eax
80105d60:	03 45 0c             	add    0xc(%ebp),%eax
80105d63:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105d66:	8b 52 04             	mov    0x4(%edx),%edx
80105d69:	89 10                	mov    %edx,(%eax)
    ebp = (uint*)ebp[0]; // saved %ebp
80105d6b:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105d6e:	8b 00                	mov    (%eax),%eax
80105d70:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
80105d73:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105d77:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105d7b:	7e c8                	jle    80105d45 <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105d7d:	eb 13                	jmp    80105d92 <getcallerpcs+0x65>
    pcs[i] = 0;
80105d7f:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105d82:	c1 e0 02             	shl    $0x2,%eax
80105d85:	03 45 0c             	add    0xc(%ebp),%eax
80105d88:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105d8e:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105d92:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105d96:	7e e7                	jle    80105d7f <getcallerpcs+0x52>
    pcs[i] = 0;
}
80105d98:	c9                   	leave  
80105d99:	c3                   	ret    

80105d9a <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
80105d9a:	55                   	push   %ebp
80105d9b:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
80105d9d:	8b 45 08             	mov    0x8(%ebp),%eax
80105da0:	8b 00                	mov    (%eax),%eax
80105da2:	85 c0                	test   %eax,%eax
80105da4:	74 17                	je     80105dbd <holding+0x23>
80105da6:	8b 45 08             	mov    0x8(%ebp),%eax
80105da9:	8b 50 08             	mov    0x8(%eax),%edx
80105dac:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105db2:	39 c2                	cmp    %eax,%edx
80105db4:	75 07                	jne    80105dbd <holding+0x23>
80105db6:	b8 01 00 00 00       	mov    $0x1,%eax
80105dbb:	eb 05                	jmp    80105dc2 <holding+0x28>
80105dbd:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105dc2:	5d                   	pop    %ebp
80105dc3:	c3                   	ret    

80105dc4 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80105dc4:	55                   	push   %ebp
80105dc5:	89 e5                	mov    %esp,%ebp
80105dc7:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
80105dca:	e8 0d fe ff ff       	call   80105bdc <readeflags>
80105dcf:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
80105dd2:	e8 1a fe ff ff       	call   80105bf1 <cli>
  if(cpu->ncli++ == 0)
80105dd7:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105ddd:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80105de3:	85 d2                	test   %edx,%edx
80105de5:	0f 94 c1             	sete   %cl
80105de8:	83 c2 01             	add    $0x1,%edx
80105deb:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80105df1:	84 c9                	test   %cl,%cl
80105df3:	74 15                	je     80105e0a <pushcli+0x46>
    cpu->intena = eflags & FL_IF;
80105df5:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105dfb:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105dfe:	81 e2 00 02 00 00    	and    $0x200,%edx
80105e04:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80105e0a:	c9                   	leave  
80105e0b:	c3                   	ret    

80105e0c <popcli>:

void
popcli(void)
{
80105e0c:	55                   	push   %ebp
80105e0d:	89 e5                	mov    %esp,%ebp
80105e0f:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
80105e12:	e8 c5 fd ff ff       	call   80105bdc <readeflags>
80105e17:	25 00 02 00 00       	and    $0x200,%eax
80105e1c:	85 c0                	test   %eax,%eax
80105e1e:	74 0c                	je     80105e2c <popcli+0x20>
    panic("popcli - interruptible");
80105e20:	c7 04 24 14 9d 10 80 	movl   $0x80109d14,(%esp)
80105e27:	e8 11 a7 ff ff       	call   8010053d <panic>
  if(--cpu->ncli < 0)
80105e2c:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105e32:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80105e38:	83 ea 01             	sub    $0x1,%edx
80105e3b:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80105e41:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105e47:	85 c0                	test   %eax,%eax
80105e49:	79 0c                	jns    80105e57 <popcli+0x4b>
    panic("popcli");
80105e4b:	c7 04 24 2b 9d 10 80 	movl   $0x80109d2b,(%esp)
80105e52:	e8 e6 a6 ff ff       	call   8010053d <panic>
  if(cpu->ncli == 0 && cpu->intena)
80105e57:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105e5d:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105e63:	85 c0                	test   %eax,%eax
80105e65:	75 15                	jne    80105e7c <popcli+0x70>
80105e67:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105e6d:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80105e73:	85 c0                	test   %eax,%eax
80105e75:	74 05                	je     80105e7c <popcli+0x70>
    sti();
80105e77:	e8 7b fd ff ff       	call   80105bf7 <sti>
}
80105e7c:	c9                   	leave  
80105e7d:	c3                   	ret    
	...

80105e80 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
80105e80:	55                   	push   %ebp
80105e81:	89 e5                	mov    %esp,%ebp
80105e83:	57                   	push   %edi
80105e84:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
80105e85:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105e88:	8b 55 10             	mov    0x10(%ebp),%edx
80105e8b:	8b 45 0c             	mov    0xc(%ebp),%eax
80105e8e:	89 cb                	mov    %ecx,%ebx
80105e90:	89 df                	mov    %ebx,%edi
80105e92:	89 d1                	mov    %edx,%ecx
80105e94:	fc                   	cld    
80105e95:	f3 aa                	rep stos %al,%es:(%edi)
80105e97:	89 ca                	mov    %ecx,%edx
80105e99:	89 fb                	mov    %edi,%ebx
80105e9b:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105e9e:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105ea1:	5b                   	pop    %ebx
80105ea2:	5f                   	pop    %edi
80105ea3:	5d                   	pop    %ebp
80105ea4:	c3                   	ret    

80105ea5 <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
80105ea5:	55                   	push   %ebp
80105ea6:	89 e5                	mov    %esp,%ebp
80105ea8:	57                   	push   %edi
80105ea9:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
80105eaa:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105ead:	8b 55 10             	mov    0x10(%ebp),%edx
80105eb0:	8b 45 0c             	mov    0xc(%ebp),%eax
80105eb3:	89 cb                	mov    %ecx,%ebx
80105eb5:	89 df                	mov    %ebx,%edi
80105eb7:	89 d1                	mov    %edx,%ecx
80105eb9:	fc                   	cld    
80105eba:	f3 ab                	rep stos %eax,%es:(%edi)
80105ebc:	89 ca                	mov    %ecx,%edx
80105ebe:	89 fb                	mov    %edi,%ebx
80105ec0:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105ec3:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105ec6:	5b                   	pop    %ebx
80105ec7:	5f                   	pop    %edi
80105ec8:	5d                   	pop    %ebp
80105ec9:	c3                   	ret    

80105eca <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80105eca:	55                   	push   %ebp
80105ecb:	89 e5                	mov    %esp,%ebp
80105ecd:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
80105ed0:	8b 45 08             	mov    0x8(%ebp),%eax
80105ed3:	83 e0 03             	and    $0x3,%eax
80105ed6:	85 c0                	test   %eax,%eax
80105ed8:	75 49                	jne    80105f23 <memset+0x59>
80105eda:	8b 45 10             	mov    0x10(%ebp),%eax
80105edd:	83 e0 03             	and    $0x3,%eax
80105ee0:	85 c0                	test   %eax,%eax
80105ee2:	75 3f                	jne    80105f23 <memset+0x59>
    c &= 0xFF;
80105ee4:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80105eeb:	8b 45 10             	mov    0x10(%ebp),%eax
80105eee:	c1 e8 02             	shr    $0x2,%eax
80105ef1:	89 c2                	mov    %eax,%edx
80105ef3:	8b 45 0c             	mov    0xc(%ebp),%eax
80105ef6:	89 c1                	mov    %eax,%ecx
80105ef8:	c1 e1 18             	shl    $0x18,%ecx
80105efb:	8b 45 0c             	mov    0xc(%ebp),%eax
80105efe:	c1 e0 10             	shl    $0x10,%eax
80105f01:	09 c1                	or     %eax,%ecx
80105f03:	8b 45 0c             	mov    0xc(%ebp),%eax
80105f06:	c1 e0 08             	shl    $0x8,%eax
80105f09:	09 c8                	or     %ecx,%eax
80105f0b:	0b 45 0c             	or     0xc(%ebp),%eax
80105f0e:	89 54 24 08          	mov    %edx,0x8(%esp)
80105f12:	89 44 24 04          	mov    %eax,0x4(%esp)
80105f16:	8b 45 08             	mov    0x8(%ebp),%eax
80105f19:	89 04 24             	mov    %eax,(%esp)
80105f1c:	e8 84 ff ff ff       	call   80105ea5 <stosl>
80105f21:	eb 19                	jmp    80105f3c <memset+0x72>
  } else
    stosb(dst, c, n);
80105f23:	8b 45 10             	mov    0x10(%ebp),%eax
80105f26:	89 44 24 08          	mov    %eax,0x8(%esp)
80105f2a:	8b 45 0c             	mov    0xc(%ebp),%eax
80105f2d:	89 44 24 04          	mov    %eax,0x4(%esp)
80105f31:	8b 45 08             	mov    0x8(%ebp),%eax
80105f34:	89 04 24             	mov    %eax,(%esp)
80105f37:	e8 44 ff ff ff       	call   80105e80 <stosb>
  return dst;
80105f3c:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105f3f:	c9                   	leave  
80105f40:	c3                   	ret    

80105f41 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80105f41:	55                   	push   %ebp
80105f42:	89 e5                	mov    %esp,%ebp
80105f44:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
80105f47:	8b 45 08             	mov    0x8(%ebp),%eax
80105f4a:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
80105f4d:	8b 45 0c             	mov    0xc(%ebp),%eax
80105f50:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
80105f53:	eb 32                	jmp    80105f87 <memcmp+0x46>
    if(*s1 != *s2)
80105f55:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105f58:	0f b6 10             	movzbl (%eax),%edx
80105f5b:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105f5e:	0f b6 00             	movzbl (%eax),%eax
80105f61:	38 c2                	cmp    %al,%dl
80105f63:	74 1a                	je     80105f7f <memcmp+0x3e>
      return *s1 - *s2;
80105f65:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105f68:	0f b6 00             	movzbl (%eax),%eax
80105f6b:	0f b6 d0             	movzbl %al,%edx
80105f6e:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105f71:	0f b6 00             	movzbl (%eax),%eax
80105f74:	0f b6 c0             	movzbl %al,%eax
80105f77:	89 d1                	mov    %edx,%ecx
80105f79:	29 c1                	sub    %eax,%ecx
80105f7b:	89 c8                	mov    %ecx,%eax
80105f7d:	eb 1c                	jmp    80105f9b <memcmp+0x5a>
    s1++, s2++;
80105f7f:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105f83:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80105f87:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105f8b:	0f 95 c0             	setne  %al
80105f8e:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105f92:	84 c0                	test   %al,%al
80105f94:	75 bf                	jne    80105f55 <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
80105f96:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105f9b:	c9                   	leave  
80105f9c:	c3                   	ret    

80105f9d <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80105f9d:	55                   	push   %ebp
80105f9e:	89 e5                	mov    %esp,%ebp
80105fa0:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
80105fa3:	8b 45 0c             	mov    0xc(%ebp),%eax
80105fa6:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
80105fa9:	8b 45 08             	mov    0x8(%ebp),%eax
80105fac:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
80105faf:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105fb2:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105fb5:	73 54                	jae    8010600b <memmove+0x6e>
80105fb7:	8b 45 10             	mov    0x10(%ebp),%eax
80105fba:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105fbd:	01 d0                	add    %edx,%eax
80105fbf:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105fc2:	76 47                	jbe    8010600b <memmove+0x6e>
    s += n;
80105fc4:	8b 45 10             	mov    0x10(%ebp),%eax
80105fc7:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
80105fca:	8b 45 10             	mov    0x10(%ebp),%eax
80105fcd:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
80105fd0:	eb 13                	jmp    80105fe5 <memmove+0x48>
      *--d = *--s;
80105fd2:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
80105fd6:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
80105fda:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105fdd:	0f b6 10             	movzbl (%eax),%edx
80105fe0:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105fe3:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
80105fe5:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105fe9:	0f 95 c0             	setne  %al
80105fec:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105ff0:	84 c0                	test   %al,%al
80105ff2:	75 de                	jne    80105fd2 <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80105ff4:	eb 25                	jmp    8010601b <memmove+0x7e>
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
      *d++ = *s++;
80105ff6:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105ff9:	0f b6 10             	movzbl (%eax),%edx
80105ffc:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105fff:	88 10                	mov    %dl,(%eax)
80106001:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80106005:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80106009:	eb 01                	jmp    8010600c <memmove+0x6f>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
8010600b:	90                   	nop
8010600c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80106010:	0f 95 c0             	setne  %al
80106013:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80106017:	84 c0                	test   %al,%al
80106019:	75 db                	jne    80105ff6 <memmove+0x59>
      *d++ = *s++;

  return dst;
8010601b:	8b 45 08             	mov    0x8(%ebp),%eax
}
8010601e:	c9                   	leave  
8010601f:	c3                   	ret    

80106020 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80106020:	55                   	push   %ebp
80106021:	89 e5                	mov    %esp,%ebp
80106023:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
80106026:	8b 45 10             	mov    0x10(%ebp),%eax
80106029:	89 44 24 08          	mov    %eax,0x8(%esp)
8010602d:	8b 45 0c             	mov    0xc(%ebp),%eax
80106030:	89 44 24 04          	mov    %eax,0x4(%esp)
80106034:	8b 45 08             	mov    0x8(%ebp),%eax
80106037:	89 04 24             	mov    %eax,(%esp)
8010603a:	e8 5e ff ff ff       	call   80105f9d <memmove>
}
8010603f:	c9                   	leave  
80106040:	c3                   	ret    

80106041 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80106041:	55                   	push   %ebp
80106042:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
80106044:	eb 0c                	jmp    80106052 <strncmp+0x11>
    n--, p++, q++;
80106046:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
8010604a:	83 45 08 01          	addl   $0x1,0x8(%ebp)
8010604e:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
80106052:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80106056:	74 1a                	je     80106072 <strncmp+0x31>
80106058:	8b 45 08             	mov    0x8(%ebp),%eax
8010605b:	0f b6 00             	movzbl (%eax),%eax
8010605e:	84 c0                	test   %al,%al
80106060:	74 10                	je     80106072 <strncmp+0x31>
80106062:	8b 45 08             	mov    0x8(%ebp),%eax
80106065:	0f b6 10             	movzbl (%eax),%edx
80106068:	8b 45 0c             	mov    0xc(%ebp),%eax
8010606b:	0f b6 00             	movzbl (%eax),%eax
8010606e:	38 c2                	cmp    %al,%dl
80106070:	74 d4                	je     80106046 <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
80106072:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80106076:	75 07                	jne    8010607f <strncmp+0x3e>
    return 0;
80106078:	b8 00 00 00 00       	mov    $0x0,%eax
8010607d:	eb 18                	jmp    80106097 <strncmp+0x56>
  return (uchar)*p - (uchar)*q;
8010607f:	8b 45 08             	mov    0x8(%ebp),%eax
80106082:	0f b6 00             	movzbl (%eax),%eax
80106085:	0f b6 d0             	movzbl %al,%edx
80106088:	8b 45 0c             	mov    0xc(%ebp),%eax
8010608b:	0f b6 00             	movzbl (%eax),%eax
8010608e:	0f b6 c0             	movzbl %al,%eax
80106091:	89 d1                	mov    %edx,%ecx
80106093:	29 c1                	sub    %eax,%ecx
80106095:	89 c8                	mov    %ecx,%eax
}
80106097:	5d                   	pop    %ebp
80106098:	c3                   	ret    

80106099 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80106099:	55                   	push   %ebp
8010609a:	89 e5                	mov    %esp,%ebp
8010609c:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
8010609f:	8b 45 08             	mov    0x8(%ebp),%eax
801060a2:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
801060a5:	90                   	nop
801060a6:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801060aa:	0f 9f c0             	setg   %al
801060ad:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801060b1:	84 c0                	test   %al,%al
801060b3:	74 30                	je     801060e5 <strncpy+0x4c>
801060b5:	8b 45 0c             	mov    0xc(%ebp),%eax
801060b8:	0f b6 10             	movzbl (%eax),%edx
801060bb:	8b 45 08             	mov    0x8(%ebp),%eax
801060be:	88 10                	mov    %dl,(%eax)
801060c0:	8b 45 08             	mov    0x8(%ebp),%eax
801060c3:	0f b6 00             	movzbl (%eax),%eax
801060c6:	84 c0                	test   %al,%al
801060c8:	0f 95 c0             	setne  %al
801060cb:	83 45 08 01          	addl   $0x1,0x8(%ebp)
801060cf:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
801060d3:	84 c0                	test   %al,%al
801060d5:	75 cf                	jne    801060a6 <strncpy+0xd>
    ;
  while(n-- > 0)
801060d7:	eb 0c                	jmp    801060e5 <strncpy+0x4c>
    *s++ = 0;
801060d9:	8b 45 08             	mov    0x8(%ebp),%eax
801060dc:	c6 00 00             	movb   $0x0,(%eax)
801060df:	83 45 08 01          	addl   $0x1,0x8(%ebp)
801060e3:	eb 01                	jmp    801060e6 <strncpy+0x4d>
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
801060e5:	90                   	nop
801060e6:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801060ea:	0f 9f c0             	setg   %al
801060ed:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801060f1:	84 c0                	test   %al,%al
801060f3:	75 e4                	jne    801060d9 <strncpy+0x40>
    *s++ = 0;
  return os;
801060f5:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801060f8:	c9                   	leave  
801060f9:	c3                   	ret    

801060fa <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
801060fa:	55                   	push   %ebp
801060fb:	89 e5                	mov    %esp,%ebp
801060fd:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80106100:	8b 45 08             	mov    0x8(%ebp),%eax
80106103:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
80106106:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010610a:	7f 05                	jg     80106111 <safestrcpy+0x17>
    return os;
8010610c:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010610f:	eb 35                	jmp    80106146 <safestrcpy+0x4c>
  while(--n > 0 && (*s++ = *t++) != 0)
80106111:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80106115:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80106119:	7e 22                	jle    8010613d <safestrcpy+0x43>
8010611b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010611e:	0f b6 10             	movzbl (%eax),%edx
80106121:	8b 45 08             	mov    0x8(%ebp),%eax
80106124:	88 10                	mov    %dl,(%eax)
80106126:	8b 45 08             	mov    0x8(%ebp),%eax
80106129:	0f b6 00             	movzbl (%eax),%eax
8010612c:	84 c0                	test   %al,%al
8010612e:	0f 95 c0             	setne  %al
80106131:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80106135:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
80106139:	84 c0                	test   %al,%al
8010613b:	75 d4                	jne    80106111 <safestrcpy+0x17>
    ;
  *s = 0;
8010613d:	8b 45 08             	mov    0x8(%ebp),%eax
80106140:	c6 00 00             	movb   $0x0,(%eax)
  return os;
80106143:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80106146:	c9                   	leave  
80106147:	c3                   	ret    

80106148 <strlen>:

int
strlen(const char *s)
{
80106148:	55                   	push   %ebp
80106149:	89 e5                	mov    %esp,%ebp
8010614b:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
8010614e:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80106155:	eb 04                	jmp    8010615b <strlen+0x13>
80106157:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010615b:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010615e:	03 45 08             	add    0x8(%ebp),%eax
80106161:	0f b6 00             	movzbl (%eax),%eax
80106164:	84 c0                	test   %al,%al
80106166:	75 ef                	jne    80106157 <strlen+0xf>
    ;
  return n;
80106168:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
8010616b:	c9                   	leave  
8010616c:	c3                   	ret    
8010616d:	00 00                	add    %al,(%eax)
	...

80106170 <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
80106170:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80106174:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
80106178:	55                   	push   %ebp
  pushl %ebx
80106179:	53                   	push   %ebx
  pushl %esi
8010617a:	56                   	push   %esi
  pushl %edi
8010617b:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
8010617c:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
8010617e:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
80106180:	5f                   	pop    %edi
  popl %esi
80106181:	5e                   	pop    %esi
  popl %ebx
80106182:	5b                   	pop    %ebx
  popl %ebp
80106183:	5d                   	pop    %ebp
  ret
80106184:	c3                   	ret    
80106185:	00 00                	add    %al,(%eax)
	...

80106188 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from process p.
int
fetchint(struct proc *p, uint addr, int *ip)
{
80106188:	55                   	push   %ebp
80106189:	89 e5                	mov    %esp,%ebp
  if(addr >= p->sz || addr+4 > p->sz)
8010618b:	8b 45 08             	mov    0x8(%ebp),%eax
8010618e:	8b 00                	mov    (%eax),%eax
80106190:	3b 45 0c             	cmp    0xc(%ebp),%eax
80106193:	76 0f                	jbe    801061a4 <fetchint+0x1c>
80106195:	8b 45 0c             	mov    0xc(%ebp),%eax
80106198:	8d 50 04             	lea    0x4(%eax),%edx
8010619b:	8b 45 08             	mov    0x8(%ebp),%eax
8010619e:	8b 00                	mov    (%eax),%eax
801061a0:	39 c2                	cmp    %eax,%edx
801061a2:	76 07                	jbe    801061ab <fetchint+0x23>
    return -1;
801061a4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061a9:	eb 0f                	jmp    801061ba <fetchint+0x32>
  *ip = *(int*)(addr);
801061ab:	8b 45 0c             	mov    0xc(%ebp),%eax
801061ae:	8b 10                	mov    (%eax),%edx
801061b0:	8b 45 10             	mov    0x10(%ebp),%eax
801061b3:	89 10                	mov    %edx,(%eax)
  return 0;
801061b5:	b8 00 00 00 00       	mov    $0x0,%eax
}
801061ba:	5d                   	pop    %ebp
801061bb:	c3                   	ret    

801061bc <fetchstr>:
// Fetch the nul-terminated string at addr from process p.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(struct proc *p, uint addr, char **pp)
{
801061bc:	55                   	push   %ebp
801061bd:	89 e5                	mov    %esp,%ebp
801061bf:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= p->sz)
801061c2:	8b 45 08             	mov    0x8(%ebp),%eax
801061c5:	8b 00                	mov    (%eax),%eax
801061c7:	3b 45 0c             	cmp    0xc(%ebp),%eax
801061ca:	77 07                	ja     801061d3 <fetchstr+0x17>
    return -1;
801061cc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061d1:	eb 45                	jmp    80106218 <fetchstr+0x5c>
  *pp = (char*)addr;
801061d3:	8b 55 0c             	mov    0xc(%ebp),%edx
801061d6:	8b 45 10             	mov    0x10(%ebp),%eax
801061d9:	89 10                	mov    %edx,(%eax)
  ep = (char*)p->sz;
801061db:	8b 45 08             	mov    0x8(%ebp),%eax
801061de:	8b 00                	mov    (%eax),%eax
801061e0:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
801061e3:	8b 45 10             	mov    0x10(%ebp),%eax
801061e6:	8b 00                	mov    (%eax),%eax
801061e8:	89 45 fc             	mov    %eax,-0x4(%ebp)
801061eb:	eb 1e                	jmp    8010620b <fetchstr+0x4f>
    if(*s == 0)
801061ed:	8b 45 fc             	mov    -0x4(%ebp),%eax
801061f0:	0f b6 00             	movzbl (%eax),%eax
801061f3:	84 c0                	test   %al,%al
801061f5:	75 10                	jne    80106207 <fetchstr+0x4b>
      return s - *pp;
801061f7:	8b 55 fc             	mov    -0x4(%ebp),%edx
801061fa:	8b 45 10             	mov    0x10(%ebp),%eax
801061fd:	8b 00                	mov    (%eax),%eax
801061ff:	89 d1                	mov    %edx,%ecx
80106201:	29 c1                	sub    %eax,%ecx
80106203:	89 c8                	mov    %ecx,%eax
80106205:	eb 11                	jmp    80106218 <fetchstr+0x5c>

  if(addr >= p->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)p->sz;
  for(s = *pp; s < ep; s++)
80106207:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010620b:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010620e:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80106211:	72 da                	jb     801061ed <fetchstr+0x31>
    if(*s == 0)
      return s - *pp;
  return -1;
80106213:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80106218:	c9                   	leave  
80106219:	c3                   	ret    

8010621a <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
8010621a:	55                   	push   %ebp
8010621b:	89 e5                	mov    %esp,%ebp
8010621d:	83 ec 0c             	sub    $0xc,%esp
  return fetchint(proc, proc->tf->esp + 4 + 4*n, ip);
80106220:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106226:	8b 40 18             	mov    0x18(%eax),%eax
80106229:	8b 50 44             	mov    0x44(%eax),%edx
8010622c:	8b 45 08             	mov    0x8(%ebp),%eax
8010622f:	c1 e0 02             	shl    $0x2,%eax
80106232:	01 d0                	add    %edx,%eax
80106234:	8d 48 04             	lea    0x4(%eax),%ecx
80106237:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010623d:	8b 55 0c             	mov    0xc(%ebp),%edx
80106240:	89 54 24 08          	mov    %edx,0x8(%esp)
80106244:	89 4c 24 04          	mov    %ecx,0x4(%esp)
80106248:	89 04 24             	mov    %eax,(%esp)
8010624b:	e8 38 ff ff ff       	call   80106188 <fetchint>
}
80106250:	c9                   	leave  
80106251:	c3                   	ret    

80106252 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
80106252:	55                   	push   %ebp
80106253:	89 e5                	mov    %esp,%ebp
80106255:	83 ec 18             	sub    $0x18,%esp
  int i;

  if(argint(n, &i) < 0)
80106258:	8d 45 fc             	lea    -0x4(%ebp),%eax
8010625b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010625f:	8b 45 08             	mov    0x8(%ebp),%eax
80106262:	89 04 24             	mov    %eax,(%esp)
80106265:	e8 b0 ff ff ff       	call   8010621a <argint>
8010626a:	85 c0                	test   %eax,%eax
8010626c:	79 07                	jns    80106275 <argptr+0x23>
    return -1;
8010626e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106273:	eb 3d                	jmp    801062b2 <argptr+0x60>

  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
80106275:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106278:	89 c2                	mov    %eax,%edx
8010627a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106280:	8b 00                	mov    (%eax),%eax
80106282:	39 c2                	cmp    %eax,%edx
80106284:	73 16                	jae    8010629c <argptr+0x4a>
80106286:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106289:	89 c2                	mov    %eax,%edx
8010628b:	8b 45 10             	mov    0x10(%ebp),%eax
8010628e:	01 c2                	add    %eax,%edx
80106290:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106296:	8b 00                	mov    (%eax),%eax
80106298:	39 c2                	cmp    %eax,%edx
8010629a:	76 07                	jbe    801062a3 <argptr+0x51>
    return -1;
8010629c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801062a1:	eb 0f                	jmp    801062b2 <argptr+0x60>
  *pp = (char*)i;
801062a3:	8b 45 fc             	mov    -0x4(%ebp),%eax
801062a6:	89 c2                	mov    %eax,%edx
801062a8:	8b 45 0c             	mov    0xc(%ebp),%eax
801062ab:	89 10                	mov    %edx,(%eax)
  return 0;
801062ad:	b8 00 00 00 00       	mov    $0x0,%eax
}
801062b2:	c9                   	leave  
801062b3:	c3                   	ret    

801062b4 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
801062b4:	55                   	push   %ebp
801062b5:	89 e5                	mov    %esp,%ebp
801062b7:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  if(argint(n, &addr) < 0)
801062ba:	8d 45 fc             	lea    -0x4(%ebp),%eax
801062bd:	89 44 24 04          	mov    %eax,0x4(%esp)
801062c1:	8b 45 08             	mov    0x8(%ebp),%eax
801062c4:	89 04 24             	mov    %eax,(%esp)
801062c7:	e8 4e ff ff ff       	call   8010621a <argint>
801062cc:	85 c0                	test   %eax,%eax
801062ce:	79 07                	jns    801062d7 <argstr+0x23>
    return -1;
801062d0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801062d5:	eb 1e                	jmp    801062f5 <argstr+0x41>
  return fetchstr(proc, addr, pp);
801062d7:	8b 45 fc             	mov    -0x4(%ebp),%eax
801062da:	89 c2                	mov    %eax,%edx
801062dc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801062e2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801062e5:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801062e9:	89 54 24 04          	mov    %edx,0x4(%esp)
801062ed:	89 04 24             	mov    %eax,(%esp)
801062f0:	e8 c7 fe ff ff       	call   801061bc <fetchstr>
}
801062f5:	c9                   	leave  
801062f6:	c3                   	ret    

801062f7 <syscall>:
[SYS_shmdt]	sys_shmdt,
};

void
syscall(void)
{
801062f7:	55                   	push   %ebp
801062f8:	89 e5                	mov    %esp,%ebp
801062fa:	53                   	push   %ebx
801062fb:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->tf->eax;
801062fe:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106304:	8b 40 18             	mov    0x18(%eax),%eax
80106307:	8b 40 1c             	mov    0x1c(%eax),%eax
8010630a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num >= 0 && num < SYS_open && syscalls[num]) {
8010630d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106311:	78 2e                	js     80106341 <syscall+0x4a>
80106313:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
80106317:	7f 28                	jg     80106341 <syscall+0x4a>
80106319:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010631c:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
80106323:	85 c0                	test   %eax,%eax
80106325:	74 1a                	je     80106341 <syscall+0x4a>
    proc->tf->eax = syscalls[num]();
80106327:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010632d:	8b 58 18             	mov    0x18(%eax),%ebx
80106330:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106333:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
8010633a:	ff d0                	call   *%eax
8010633c:	89 43 1c             	mov    %eax,0x1c(%ebx)
8010633f:	eb 73                	jmp    801063b4 <syscall+0xbd>
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
80106341:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
80106345:	7e 30                	jle    80106377 <syscall+0x80>
80106347:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010634a:	83 f8 1e             	cmp    $0x1e,%eax
8010634d:	77 28                	ja     80106377 <syscall+0x80>
8010634f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106352:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
80106359:	85 c0                	test   %eax,%eax
8010635b:	74 1a                	je     80106377 <syscall+0x80>
    proc->tf->eax = syscalls[num]();
8010635d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106363:	8b 58 18             	mov    0x18(%eax),%ebx
80106366:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106369:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
80106370:	ff d0                	call   *%eax
80106372:	89 43 1c             	mov    %eax,0x1c(%ebx)
80106375:	eb 3d                	jmp    801063b4 <syscall+0xbd>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
80106377:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010637d:	8d 48 6c             	lea    0x6c(%eax),%ecx
80106380:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  if(num >= 0 && num < SYS_open && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
80106386:	8b 40 10             	mov    0x10(%eax),%eax
80106389:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010638c:	89 54 24 0c          	mov    %edx,0xc(%esp)
80106390:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106394:	89 44 24 04          	mov    %eax,0x4(%esp)
80106398:	c7 04 24 32 9d 10 80 	movl   $0x80109d32,(%esp)
8010639f:	e8 fd 9f ff ff       	call   801003a1 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
801063a4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801063aa:	8b 40 18             	mov    0x18(%eax),%eax
801063ad:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
801063b4:	83 c4 24             	add    $0x24,%esp
801063b7:	5b                   	pop    %ebx
801063b8:	5d                   	pop    %ebp
801063b9:	c3                   	ret    
	...

801063bc <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
801063bc:	55                   	push   %ebp
801063bd:	89 e5                	mov    %esp,%ebp
801063bf:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
801063c2:	8d 45 f0             	lea    -0x10(%ebp),%eax
801063c5:	89 44 24 04          	mov    %eax,0x4(%esp)
801063c9:	8b 45 08             	mov    0x8(%ebp),%eax
801063cc:	89 04 24             	mov    %eax,(%esp)
801063cf:	e8 46 fe ff ff       	call   8010621a <argint>
801063d4:	85 c0                	test   %eax,%eax
801063d6:	79 07                	jns    801063df <argfd+0x23>
    return -1;
801063d8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801063dd:	eb 50                	jmp    8010642f <argfd+0x73>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
801063df:	8b 45 f0             	mov    -0x10(%ebp),%eax
801063e2:	85 c0                	test   %eax,%eax
801063e4:	78 21                	js     80106407 <argfd+0x4b>
801063e6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801063e9:	83 f8 0f             	cmp    $0xf,%eax
801063ec:	7f 19                	jg     80106407 <argfd+0x4b>
801063ee:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801063f4:	8b 55 f0             	mov    -0x10(%ebp),%edx
801063f7:	83 c2 08             	add    $0x8,%edx
801063fa:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801063fe:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106401:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106405:	75 07                	jne    8010640e <argfd+0x52>
    return -1;
80106407:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010640c:	eb 21                	jmp    8010642f <argfd+0x73>
  if(pfd)
8010640e:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80106412:	74 08                	je     8010641c <argfd+0x60>
    *pfd = fd;
80106414:	8b 55 f0             	mov    -0x10(%ebp),%edx
80106417:	8b 45 0c             	mov    0xc(%ebp),%eax
8010641a:	89 10                	mov    %edx,(%eax)
  if(pf)
8010641c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80106420:	74 08                	je     8010642a <argfd+0x6e>
    *pf = f;
80106422:	8b 45 10             	mov    0x10(%ebp),%eax
80106425:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106428:	89 10                	mov    %edx,(%eax)
  return 0;
8010642a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010642f:	c9                   	leave  
80106430:	c3                   	ret    

80106431 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
80106431:	55                   	push   %ebp
80106432:	89 e5                	mov    %esp,%ebp
80106434:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80106437:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
8010643e:	eb 30                	jmp    80106470 <fdalloc+0x3f>
    if(proc->ofile[fd] == 0){
80106440:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106446:	8b 55 fc             	mov    -0x4(%ebp),%edx
80106449:	83 c2 08             	add    $0x8,%edx
8010644c:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80106450:	85 c0                	test   %eax,%eax
80106452:	75 18                	jne    8010646c <fdalloc+0x3b>
      proc->ofile[fd] = f;
80106454:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010645a:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010645d:	8d 4a 08             	lea    0x8(%edx),%ecx
80106460:	8b 55 08             	mov    0x8(%ebp),%edx
80106463:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
80106467:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010646a:	eb 0f                	jmp    8010647b <fdalloc+0x4a>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
8010646c:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80106470:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
80106474:	7e ca                	jle    80106440 <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
80106476:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010647b:	c9                   	leave  
8010647c:	c3                   	ret    

8010647d <sys_dup>:

int
sys_dup(void)
{
8010647d:	55                   	push   %ebp
8010647e:	89 e5                	mov    %esp,%ebp
80106480:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
80106483:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106486:	89 44 24 08          	mov    %eax,0x8(%esp)
8010648a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106491:	00 
80106492:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106499:	e8 1e ff ff ff       	call   801063bc <argfd>
8010649e:	85 c0                	test   %eax,%eax
801064a0:	79 07                	jns    801064a9 <sys_dup+0x2c>
    return -1;
801064a2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801064a7:	eb 29                	jmp    801064d2 <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
801064a9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064ac:	89 04 24             	mov    %eax,(%esp)
801064af:	e8 7d ff ff ff       	call   80106431 <fdalloc>
801064b4:	89 45 f4             	mov    %eax,-0xc(%ebp)
801064b7:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801064bb:	79 07                	jns    801064c4 <sys_dup+0x47>
    return -1;
801064bd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801064c2:	eb 0e                	jmp    801064d2 <sys_dup+0x55>
  filedup(f);
801064c4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064c7:	89 04 24             	mov    %eax,(%esp)
801064ca:	e8 ad aa ff ff       	call   80100f7c <filedup>
  return fd;
801064cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801064d2:	c9                   	leave  
801064d3:	c3                   	ret    

801064d4 <sys_read>:

int
sys_read(void)
{
801064d4:	55                   	push   %ebp
801064d5:	89 e5                	mov    %esp,%ebp
801064d7:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801064da:	8d 45 f4             	lea    -0xc(%ebp),%eax
801064dd:	89 44 24 08          	mov    %eax,0x8(%esp)
801064e1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801064e8:	00 
801064e9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801064f0:	e8 c7 fe ff ff       	call   801063bc <argfd>
801064f5:	85 c0                	test   %eax,%eax
801064f7:	78 35                	js     8010652e <sys_read+0x5a>
801064f9:	8d 45 f0             	lea    -0x10(%ebp),%eax
801064fc:	89 44 24 04          	mov    %eax,0x4(%esp)
80106500:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80106507:	e8 0e fd ff ff       	call   8010621a <argint>
8010650c:	85 c0                	test   %eax,%eax
8010650e:	78 1e                	js     8010652e <sys_read+0x5a>
80106510:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106513:	89 44 24 08          	mov    %eax,0x8(%esp)
80106517:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010651a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010651e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106525:	e8 28 fd ff ff       	call   80106252 <argptr>
8010652a:	85 c0                	test   %eax,%eax
8010652c:	79 07                	jns    80106535 <sys_read+0x61>
    return -1;
8010652e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106533:	eb 19                	jmp    8010654e <sys_read+0x7a>
  return fileread(f, p, n);
80106535:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80106538:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010653b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010653e:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106542:	89 54 24 04          	mov    %edx,0x4(%esp)
80106546:	89 04 24             	mov    %eax,(%esp)
80106549:	e8 9b ab ff ff       	call   801010e9 <fileread>
}
8010654e:	c9                   	leave  
8010654f:	c3                   	ret    

80106550 <sys_write>:

int
sys_write(void)
{
80106550:	55                   	push   %ebp
80106551:	89 e5                	mov    %esp,%ebp
80106553:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80106556:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106559:	89 44 24 08          	mov    %eax,0x8(%esp)
8010655d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106564:	00 
80106565:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010656c:	e8 4b fe ff ff       	call   801063bc <argfd>
80106571:	85 c0                	test   %eax,%eax
80106573:	78 35                	js     801065aa <sys_write+0x5a>
80106575:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106578:	89 44 24 04          	mov    %eax,0x4(%esp)
8010657c:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80106583:	e8 92 fc ff ff       	call   8010621a <argint>
80106588:	85 c0                	test   %eax,%eax
8010658a:	78 1e                	js     801065aa <sys_write+0x5a>
8010658c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010658f:	89 44 24 08          	mov    %eax,0x8(%esp)
80106593:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106596:	89 44 24 04          	mov    %eax,0x4(%esp)
8010659a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801065a1:	e8 ac fc ff ff       	call   80106252 <argptr>
801065a6:	85 c0                	test   %eax,%eax
801065a8:	79 07                	jns    801065b1 <sys_write+0x61>
    return -1;
801065aa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801065af:	eb 19                	jmp    801065ca <sys_write+0x7a>
  return filewrite(f, p, n);
801065b1:	8b 4d f0             	mov    -0x10(%ebp),%ecx
801065b4:	8b 55 ec             	mov    -0x14(%ebp),%edx
801065b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065ba:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801065be:	89 54 24 04          	mov    %edx,0x4(%esp)
801065c2:	89 04 24             	mov    %eax,(%esp)
801065c5:	e8 db ab ff ff       	call   801011a5 <filewrite>
}
801065ca:	c9                   	leave  
801065cb:	c3                   	ret    

801065cc <sys_close>:

int
sys_close(void)
{
801065cc:	55                   	push   %ebp
801065cd:	89 e5                	mov    %esp,%ebp
801065cf:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
801065d2:	8d 45 f0             	lea    -0x10(%ebp),%eax
801065d5:	89 44 24 08          	mov    %eax,0x8(%esp)
801065d9:	8d 45 f4             	lea    -0xc(%ebp),%eax
801065dc:	89 44 24 04          	mov    %eax,0x4(%esp)
801065e0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801065e7:	e8 d0 fd ff ff       	call   801063bc <argfd>
801065ec:	85 c0                	test   %eax,%eax
801065ee:	79 07                	jns    801065f7 <sys_close+0x2b>
    return -1;
801065f0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801065f5:	eb 24                	jmp    8010661b <sys_close+0x4f>
  proc->ofile[fd] = 0;
801065f7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801065fd:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106600:	83 c2 08             	add    $0x8,%edx
80106603:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
8010660a:	00 
  fileclose(f);
8010660b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010660e:	89 04 24             	mov    %eax,(%esp)
80106611:	e8 ae a9 ff ff       	call   80100fc4 <fileclose>
  return 0;
80106616:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010661b:	c9                   	leave  
8010661c:	c3                   	ret    

8010661d <sys_fstat>:

int
sys_fstat(void)
{
8010661d:	55                   	push   %ebp
8010661e:	89 e5                	mov    %esp,%ebp
80106620:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
80106623:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106626:	89 44 24 08          	mov    %eax,0x8(%esp)
8010662a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106631:	00 
80106632:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106639:	e8 7e fd ff ff       	call   801063bc <argfd>
8010663e:	85 c0                	test   %eax,%eax
80106640:	78 1f                	js     80106661 <sys_fstat+0x44>
80106642:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80106649:	00 
8010664a:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010664d:	89 44 24 04          	mov    %eax,0x4(%esp)
80106651:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106658:	e8 f5 fb ff ff       	call   80106252 <argptr>
8010665d:	85 c0                	test   %eax,%eax
8010665f:	79 07                	jns    80106668 <sys_fstat+0x4b>
    return -1;
80106661:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106666:	eb 12                	jmp    8010667a <sys_fstat+0x5d>
  return filestat(f, st);
80106668:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010666b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010666e:	89 54 24 04          	mov    %edx,0x4(%esp)
80106672:	89 04 24             	mov    %eax,(%esp)
80106675:	e8 20 aa ff ff       	call   8010109a <filestat>
}
8010667a:	c9                   	leave  
8010667b:	c3                   	ret    

8010667c <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
8010667c:	55                   	push   %ebp
8010667d:	89 e5                	mov    %esp,%ebp
8010667f:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
80106682:	8d 45 d8             	lea    -0x28(%ebp),%eax
80106685:	89 44 24 04          	mov    %eax,0x4(%esp)
80106689:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106690:	e8 1f fc ff ff       	call   801062b4 <argstr>
80106695:	85 c0                	test   %eax,%eax
80106697:	78 17                	js     801066b0 <sys_link+0x34>
80106699:	8d 45 dc             	lea    -0x24(%ebp),%eax
8010669c:	89 44 24 04          	mov    %eax,0x4(%esp)
801066a0:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801066a7:	e8 08 fc ff ff       	call   801062b4 <argstr>
801066ac:	85 c0                	test   %eax,%eax
801066ae:	79 0a                	jns    801066ba <sys_link+0x3e>
    return -1;
801066b0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801066b5:	e9 3c 01 00 00       	jmp    801067f6 <sys_link+0x17a>
  if((ip = namei(old)) == 0)
801066ba:	8b 45 d8             	mov    -0x28(%ebp),%eax
801066bd:	89 04 24             	mov    %eax,(%esp)
801066c0:	e8 45 bd ff ff       	call   8010240a <namei>
801066c5:	89 45 f4             	mov    %eax,-0xc(%ebp)
801066c8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801066cc:	75 0a                	jne    801066d8 <sys_link+0x5c>
    return -1;
801066ce:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801066d3:	e9 1e 01 00 00       	jmp    801067f6 <sys_link+0x17a>

  begin_trans();
801066d8:	e8 42 d3 ff ff       	call   80103a1f <begin_trans>

  ilock(ip);
801066dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066e0:	89 04 24             	mov    %eax,(%esp)
801066e3:	e8 80 b1 ff ff       	call   80101868 <ilock>
  if(ip->type == T_DIR){
801066e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066eb:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801066ef:	66 83 f8 01          	cmp    $0x1,%ax
801066f3:	75 1a                	jne    8010670f <sys_link+0x93>
    iunlockput(ip);
801066f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066f8:	89 04 24             	mov    %eax,(%esp)
801066fb:	e8 ec b3 ff ff       	call   80101aec <iunlockput>
    commit_trans();
80106700:	e8 6c d3 ff ff       	call   80103a71 <commit_trans>
    return -1;
80106705:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010670a:	e9 e7 00 00 00       	jmp    801067f6 <sys_link+0x17a>
  }

  ip->nlink++;
8010670f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106712:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106716:	8d 50 01             	lea    0x1(%eax),%edx
80106719:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010671c:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80106720:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106723:	89 04 24             	mov    %eax,(%esp)
80106726:	e8 81 af ff ff       	call   801016ac <iupdate>
  iunlock(ip);
8010672b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010672e:	89 04 24             	mov    %eax,(%esp)
80106731:	e8 80 b2 ff ff       	call   801019b6 <iunlock>

  if((dp = nameiparent(new, name)) == 0)
80106736:	8b 45 dc             	mov    -0x24(%ebp),%eax
80106739:	8d 55 e2             	lea    -0x1e(%ebp),%edx
8010673c:	89 54 24 04          	mov    %edx,0x4(%esp)
80106740:	89 04 24             	mov    %eax,(%esp)
80106743:	e8 e4 bc ff ff       	call   8010242c <nameiparent>
80106748:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010674b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010674f:	74 68                	je     801067b9 <sys_link+0x13d>
    goto bad;
  ilock(dp);
80106751:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106754:	89 04 24             	mov    %eax,(%esp)
80106757:	e8 0c b1 ff ff       	call   80101868 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
8010675c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010675f:	8b 10                	mov    (%eax),%edx
80106761:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106764:	8b 00                	mov    (%eax),%eax
80106766:	39 c2                	cmp    %eax,%edx
80106768:	75 20                	jne    8010678a <sys_link+0x10e>
8010676a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010676d:	8b 40 04             	mov    0x4(%eax),%eax
80106770:	89 44 24 08          	mov    %eax,0x8(%esp)
80106774:	8d 45 e2             	lea    -0x1e(%ebp),%eax
80106777:	89 44 24 04          	mov    %eax,0x4(%esp)
8010677b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010677e:	89 04 24             	mov    %eax,(%esp)
80106781:	e8 c3 b9 ff ff       	call   80102149 <dirlink>
80106786:	85 c0                	test   %eax,%eax
80106788:	79 0d                	jns    80106797 <sys_link+0x11b>
    iunlockput(dp);
8010678a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010678d:	89 04 24             	mov    %eax,(%esp)
80106790:	e8 57 b3 ff ff       	call   80101aec <iunlockput>
    goto bad;
80106795:	eb 23                	jmp    801067ba <sys_link+0x13e>
  }
  iunlockput(dp);
80106797:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010679a:	89 04 24             	mov    %eax,(%esp)
8010679d:	e8 4a b3 ff ff       	call   80101aec <iunlockput>
  iput(ip);
801067a2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067a5:	89 04 24             	mov    %eax,(%esp)
801067a8:	e8 6e b2 ff ff       	call   80101a1b <iput>

  commit_trans();
801067ad:	e8 bf d2 ff ff       	call   80103a71 <commit_trans>

  return 0;
801067b2:	b8 00 00 00 00       	mov    $0x0,%eax
801067b7:	eb 3d                	jmp    801067f6 <sys_link+0x17a>
  ip->nlink++;
  iupdate(ip);
  iunlock(ip);

  if((dp = nameiparent(new, name)) == 0)
    goto bad;
801067b9:	90                   	nop
  commit_trans();

  return 0;

bad:
  ilock(ip);
801067ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067bd:	89 04 24             	mov    %eax,(%esp)
801067c0:	e8 a3 b0 ff ff       	call   80101868 <ilock>
  ip->nlink--;
801067c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067c8:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801067cc:	8d 50 ff             	lea    -0x1(%eax),%edx
801067cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067d2:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801067d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067d9:	89 04 24             	mov    %eax,(%esp)
801067dc:	e8 cb ae ff ff       	call   801016ac <iupdate>
  iunlockput(ip);
801067e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067e4:	89 04 24             	mov    %eax,(%esp)
801067e7:	e8 00 b3 ff ff       	call   80101aec <iunlockput>
  commit_trans();
801067ec:	e8 80 d2 ff ff       	call   80103a71 <commit_trans>
  return -1;
801067f1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801067f6:	c9                   	leave  
801067f7:	c3                   	ret    

801067f8 <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
801067f8:	55                   	push   %ebp
801067f9:	89 e5                	mov    %esp,%ebp
801067fb:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801067fe:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
80106805:	eb 4b                	jmp    80106852 <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80106807:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010680a:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80106811:	00 
80106812:	89 44 24 08          	mov    %eax,0x8(%esp)
80106816:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106819:	89 44 24 04          	mov    %eax,0x4(%esp)
8010681d:	8b 45 08             	mov    0x8(%ebp),%eax
80106820:	89 04 24             	mov    %eax,(%esp)
80106823:	e8 36 b5 ff ff       	call   80101d5e <readi>
80106828:	83 f8 10             	cmp    $0x10,%eax
8010682b:	74 0c                	je     80106839 <isdirempty+0x41>
      panic("isdirempty: readi");
8010682d:	c7 04 24 4e 9d 10 80 	movl   $0x80109d4e,(%esp)
80106834:	e8 04 9d ff ff       	call   8010053d <panic>
    if(de.inum != 0)
80106839:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
8010683d:	66 85 c0             	test   %ax,%ax
80106840:	74 07                	je     80106849 <isdirempty+0x51>
      return 0;
80106842:	b8 00 00 00 00       	mov    $0x0,%eax
80106847:	eb 1b                	jmp    80106864 <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80106849:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010684c:	83 c0 10             	add    $0x10,%eax
8010684f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106852:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106855:	8b 45 08             	mov    0x8(%ebp),%eax
80106858:	8b 40 18             	mov    0x18(%eax),%eax
8010685b:	39 c2                	cmp    %eax,%edx
8010685d:	72 a8                	jb     80106807 <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
8010685f:	b8 01 00 00 00       	mov    $0x1,%eax
}
80106864:	c9                   	leave  
80106865:	c3                   	ret    

80106866 <unlink>:


int
unlink(char* path)
{
80106866:	55                   	push   %ebp
80106867:	89 e5                	mov    %esp,%ebp
80106869:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ];
  uint off;

  if((dp = nameiparent(path, name)) == 0)
8010686c:	8d 45 d2             	lea    -0x2e(%ebp),%eax
8010686f:	89 44 24 04          	mov    %eax,0x4(%esp)
80106873:	8b 45 08             	mov    0x8(%ebp),%eax
80106876:	89 04 24             	mov    %eax,(%esp)
80106879:	e8 ae bb ff ff       	call   8010242c <nameiparent>
8010687e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106881:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106885:	75 0a                	jne    80106891 <unlink+0x2b>
    return -1;
80106887:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010688c:	e9 85 01 00 00       	jmp    80106a16 <unlink+0x1b0>

  begin_trans();
80106891:	e8 89 d1 ff ff       	call   80103a1f <begin_trans>

  ilock(dp);
80106896:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106899:	89 04 24             	mov    %eax,(%esp)
8010689c:	e8 c7 af ff ff       	call   80101868 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
801068a1:	c7 44 24 04 60 9d 10 	movl   $0x80109d60,0x4(%esp)
801068a8:	80 
801068a9:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801068ac:	89 04 24             	mov    %eax,(%esp)
801068af:	e8 ab b7 ff ff       	call   8010205f <namecmp>
801068b4:	85 c0                	test   %eax,%eax
801068b6:	0f 84 45 01 00 00    	je     80106a01 <unlink+0x19b>
801068bc:	c7 44 24 04 62 9d 10 	movl   $0x80109d62,0x4(%esp)
801068c3:	80 
801068c4:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801068c7:	89 04 24             	mov    %eax,(%esp)
801068ca:	e8 90 b7 ff ff       	call   8010205f <namecmp>
801068cf:	85 c0                	test   %eax,%eax
801068d1:	0f 84 2a 01 00 00    	je     80106a01 <unlink+0x19b>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
801068d7:	8d 45 cc             	lea    -0x34(%ebp),%eax
801068da:	89 44 24 08          	mov    %eax,0x8(%esp)
801068de:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801068e1:	89 44 24 04          	mov    %eax,0x4(%esp)
801068e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068e8:	89 04 24             	mov    %eax,(%esp)
801068eb:	e8 91 b7 ff ff       	call   80102081 <dirlookup>
801068f0:	89 45 f0             	mov    %eax,-0x10(%ebp)
801068f3:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801068f7:	0f 84 03 01 00 00    	je     80106a00 <unlink+0x19a>
    goto bad;
  ilock(ip);
801068fd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106900:	89 04 24             	mov    %eax,(%esp)
80106903:	e8 60 af ff ff       	call   80101868 <ilock>

  if(ip->nlink < 1)
80106908:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010690b:	0f b7 40 16          	movzwl 0x16(%eax),%eax
8010690f:	66 85 c0             	test   %ax,%ax
80106912:	7f 0c                	jg     80106920 <unlink+0xba>
    panic("unlink: nlink < 1");
80106914:	c7 04 24 65 9d 10 80 	movl   $0x80109d65,(%esp)
8010691b:	e8 1d 9c ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80106920:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106923:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106927:	66 83 f8 01          	cmp    $0x1,%ax
8010692b:	75 1f                	jne    8010694c <unlink+0xe6>
8010692d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106930:	89 04 24             	mov    %eax,(%esp)
80106933:	e8 c0 fe ff ff       	call   801067f8 <isdirempty>
80106938:	85 c0                	test   %eax,%eax
8010693a:	75 10                	jne    8010694c <unlink+0xe6>
    iunlockput(ip);
8010693c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010693f:	89 04 24             	mov    %eax,(%esp)
80106942:	e8 a5 b1 ff ff       	call   80101aec <iunlockput>
    goto bad;
80106947:	e9 b5 00 00 00       	jmp    80106a01 <unlink+0x19b>
  }

  memset(&de, 0, sizeof(de));
8010694c:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80106953:	00 
80106954:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010695b:	00 
8010695c:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010695f:	89 04 24             	mov    %eax,(%esp)
80106962:	e8 63 f5 ff ff       	call   80105eca <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80106967:	8b 45 cc             	mov    -0x34(%ebp),%eax
8010696a:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80106971:	00 
80106972:	89 44 24 08          	mov    %eax,0x8(%esp)
80106976:	8d 45 e0             	lea    -0x20(%ebp),%eax
80106979:	89 44 24 04          	mov    %eax,0x4(%esp)
8010697d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106980:	89 04 24             	mov    %eax,(%esp)
80106983:	e8 41 b5 ff ff       	call   80101ec9 <writei>
80106988:	83 f8 10             	cmp    $0x10,%eax
8010698b:	74 0c                	je     80106999 <unlink+0x133>
    panic("unlink: writei");
8010698d:	c7 04 24 77 9d 10 80 	movl   $0x80109d77,(%esp)
80106994:	e8 a4 9b ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR){
80106999:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010699c:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801069a0:	66 83 f8 01          	cmp    $0x1,%ax
801069a4:	75 1c                	jne    801069c2 <unlink+0x15c>
    dp->nlink--;
801069a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069a9:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801069ad:	8d 50 ff             	lea    -0x1(%eax),%edx
801069b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069b3:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
801069b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069ba:	89 04 24             	mov    %eax,(%esp)
801069bd:	e8 ea ac ff ff       	call   801016ac <iupdate>
  }
  iunlockput(dp);
801069c2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069c5:	89 04 24             	mov    %eax,(%esp)
801069c8:	e8 1f b1 ff ff       	call   80101aec <iunlockput>

  ip->nlink--;
801069cd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801069d0:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801069d4:	8d 50 ff             	lea    -0x1(%eax),%edx
801069d7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801069da:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801069de:	8b 45 f0             	mov    -0x10(%ebp),%eax
801069e1:	89 04 24             	mov    %eax,(%esp)
801069e4:	e8 c3 ac ff ff       	call   801016ac <iupdate>
  iunlockput(ip);
801069e9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801069ec:	89 04 24             	mov    %eax,(%esp)
801069ef:	e8 f8 b0 ff ff       	call   80101aec <iunlockput>

  commit_trans();
801069f4:	e8 78 d0 ff ff       	call   80103a71 <commit_trans>

  return 0;
801069f9:	b8 00 00 00 00       	mov    $0x0,%eax
801069fe:	eb 16                	jmp    80106a16 <unlink+0x1b0>
  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    goto bad;
80106a00:	90                   	nop
  commit_trans();

  return 0;

bad:
  iunlockput(dp);
80106a01:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a04:	89 04 24             	mov    %eax,(%esp)
80106a07:	e8 e0 b0 ff ff       	call   80101aec <iunlockput>
  commit_trans();
80106a0c:	e8 60 d0 ff ff       	call   80103a71 <commit_trans>
  return -1;
80106a11:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80106a16:	c9                   	leave  
80106a17:	c3                   	ret    

80106a18 <sys_unlink>:


//PAGEBREAK!
int
sys_unlink(void)
{
80106a18:	55                   	push   %ebp
80106a19:	89 e5                	mov    %esp,%ebp
80106a1b:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
80106a1e:	8d 45 cc             	lea    -0x34(%ebp),%eax
80106a21:	89 44 24 04          	mov    %eax,0x4(%esp)
80106a25:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106a2c:	e8 83 f8 ff ff       	call   801062b4 <argstr>
80106a31:	85 c0                	test   %eax,%eax
80106a33:	79 0a                	jns    80106a3f <sys_unlink+0x27>
    return -1;
80106a35:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106a3a:	e9 aa 01 00 00       	jmp    80106be9 <sys_unlink+0x1d1>
  if((dp = nameiparent(path, name)) == 0)
80106a3f:	8b 45 cc             	mov    -0x34(%ebp),%eax
80106a42:	8d 55 d2             	lea    -0x2e(%ebp),%edx
80106a45:	89 54 24 04          	mov    %edx,0x4(%esp)
80106a49:	89 04 24             	mov    %eax,(%esp)
80106a4c:	e8 db b9 ff ff       	call   8010242c <nameiparent>
80106a51:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106a54:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106a58:	75 0a                	jne    80106a64 <sys_unlink+0x4c>
    return -1;
80106a5a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106a5f:	e9 85 01 00 00       	jmp    80106be9 <sys_unlink+0x1d1>

  begin_trans();
80106a64:	e8 b6 cf ff ff       	call   80103a1f <begin_trans>

  ilock(dp);
80106a69:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a6c:	89 04 24             	mov    %eax,(%esp)
80106a6f:	e8 f4 ad ff ff       	call   80101868 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80106a74:	c7 44 24 04 60 9d 10 	movl   $0x80109d60,0x4(%esp)
80106a7b:	80 
80106a7c:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80106a7f:	89 04 24             	mov    %eax,(%esp)
80106a82:	e8 d8 b5 ff ff       	call   8010205f <namecmp>
80106a87:	85 c0                	test   %eax,%eax
80106a89:	0f 84 45 01 00 00    	je     80106bd4 <sys_unlink+0x1bc>
80106a8f:	c7 44 24 04 62 9d 10 	movl   $0x80109d62,0x4(%esp)
80106a96:	80 
80106a97:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80106a9a:	89 04 24             	mov    %eax,(%esp)
80106a9d:	e8 bd b5 ff ff       	call   8010205f <namecmp>
80106aa2:	85 c0                	test   %eax,%eax
80106aa4:	0f 84 2a 01 00 00    	je     80106bd4 <sys_unlink+0x1bc>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
80106aaa:	8d 45 c8             	lea    -0x38(%ebp),%eax
80106aad:	89 44 24 08          	mov    %eax,0x8(%esp)
80106ab1:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80106ab4:	89 44 24 04          	mov    %eax,0x4(%esp)
80106ab8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106abb:	89 04 24             	mov    %eax,(%esp)
80106abe:	e8 be b5 ff ff       	call   80102081 <dirlookup>
80106ac3:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106ac6:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106aca:	0f 84 03 01 00 00    	je     80106bd3 <sys_unlink+0x1bb>
    goto bad;
  ilock(ip);
80106ad0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ad3:	89 04 24             	mov    %eax,(%esp)
80106ad6:	e8 8d ad ff ff       	call   80101868 <ilock>

  if(ip->nlink < 1)
80106adb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ade:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106ae2:	66 85 c0             	test   %ax,%ax
80106ae5:	7f 0c                	jg     80106af3 <sys_unlink+0xdb>
    panic("unlink: nlink < 1");
80106ae7:	c7 04 24 65 9d 10 80 	movl   $0x80109d65,(%esp)
80106aee:	e8 4a 9a ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80106af3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106af6:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106afa:	66 83 f8 01          	cmp    $0x1,%ax
80106afe:	75 1f                	jne    80106b1f <sys_unlink+0x107>
80106b00:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b03:	89 04 24             	mov    %eax,(%esp)
80106b06:	e8 ed fc ff ff       	call   801067f8 <isdirempty>
80106b0b:	85 c0                	test   %eax,%eax
80106b0d:	75 10                	jne    80106b1f <sys_unlink+0x107>
    iunlockput(ip);
80106b0f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b12:	89 04 24             	mov    %eax,(%esp)
80106b15:	e8 d2 af ff ff       	call   80101aec <iunlockput>
    goto bad;
80106b1a:	e9 b5 00 00 00       	jmp    80106bd4 <sys_unlink+0x1bc>
  }

  memset(&de, 0, sizeof(de));
80106b1f:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80106b26:	00 
80106b27:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106b2e:	00 
80106b2f:	8d 45 e0             	lea    -0x20(%ebp),%eax
80106b32:	89 04 24             	mov    %eax,(%esp)
80106b35:	e8 90 f3 ff ff       	call   80105eca <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80106b3a:	8b 45 c8             	mov    -0x38(%ebp),%eax
80106b3d:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80106b44:	00 
80106b45:	89 44 24 08          	mov    %eax,0x8(%esp)
80106b49:	8d 45 e0             	lea    -0x20(%ebp),%eax
80106b4c:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b50:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b53:	89 04 24             	mov    %eax,(%esp)
80106b56:	e8 6e b3 ff ff       	call   80101ec9 <writei>
80106b5b:	83 f8 10             	cmp    $0x10,%eax
80106b5e:	74 0c                	je     80106b6c <sys_unlink+0x154>
    panic("unlink: writei");
80106b60:	c7 04 24 77 9d 10 80 	movl   $0x80109d77,(%esp)
80106b67:	e8 d1 99 ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR){
80106b6c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b6f:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106b73:	66 83 f8 01          	cmp    $0x1,%ax
80106b77:	75 1c                	jne    80106b95 <sys_unlink+0x17d>
    dp->nlink--;
80106b79:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b7c:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106b80:	8d 50 ff             	lea    -0x1(%eax),%edx
80106b83:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b86:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80106b8a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b8d:	89 04 24             	mov    %eax,(%esp)
80106b90:	e8 17 ab ff ff       	call   801016ac <iupdate>
  }
  iunlockput(dp);
80106b95:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b98:	89 04 24             	mov    %eax,(%esp)
80106b9b:	e8 4c af ff ff       	call   80101aec <iunlockput>

  ip->nlink--;
80106ba0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ba3:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106ba7:	8d 50 ff             	lea    -0x1(%eax),%edx
80106baa:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106bad:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80106bb1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106bb4:	89 04 24             	mov    %eax,(%esp)
80106bb7:	e8 f0 aa ff ff       	call   801016ac <iupdate>
  iunlockput(ip);
80106bbc:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106bbf:	89 04 24             	mov    %eax,(%esp)
80106bc2:	e8 25 af ff ff       	call   80101aec <iunlockput>

  commit_trans();
80106bc7:	e8 a5 ce ff ff       	call   80103a71 <commit_trans>

  return 0;
80106bcc:	b8 00 00 00 00       	mov    $0x0,%eax
80106bd1:	eb 16                	jmp    80106be9 <sys_unlink+0x1d1>
  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    goto bad;
80106bd3:	90                   	nop
  commit_trans();

  return 0;

bad:
  iunlockput(dp);
80106bd4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106bd7:	89 04 24             	mov    %eax,(%esp)
80106bda:	e8 0d af ff ff       	call   80101aec <iunlockput>
  commit_trans();
80106bdf:	e8 8d ce ff ff       	call   80103a71 <commit_trans>
  return -1;
80106be4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80106be9:	c9                   	leave  
80106bea:	c3                   	ret    

80106beb <create>:

static struct inode*
create(char *path, short type, short major, short minor)
{
80106beb:	55                   	push   %ebp
80106bec:	89 e5                	mov    %esp,%ebp
80106bee:	83 ec 48             	sub    $0x48,%esp
80106bf1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80106bf4:	8b 55 10             	mov    0x10(%ebp),%edx
80106bf7:	8b 45 14             	mov    0x14(%ebp),%eax
80106bfa:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
80106bfe:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
80106c02:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];
  if((dp = nameiparent(path, name)) == 0)
80106c06:	8d 45 de             	lea    -0x22(%ebp),%eax
80106c09:	89 44 24 04          	mov    %eax,0x4(%esp)
80106c0d:	8b 45 08             	mov    0x8(%ebp),%eax
80106c10:	89 04 24             	mov    %eax,(%esp)
80106c13:	e8 14 b8 ff ff       	call   8010242c <nameiparent>
80106c18:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106c1b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106c1f:	75 0a                	jne    80106c2b <create+0x40>
    return 0;
80106c21:	b8 00 00 00 00       	mov    $0x0,%eax
80106c26:	e9 7e 01 00 00       	jmp    80106da9 <create+0x1be>
  ilock(dp);
80106c2b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c2e:	89 04 24             	mov    %eax,(%esp)
80106c31:	e8 32 ac ff ff       	call   80101868 <ilock>
  if((ip = dirlookup(dp, name, &off)) != 0){
80106c36:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106c39:	89 44 24 08          	mov    %eax,0x8(%esp)
80106c3d:	8d 45 de             	lea    -0x22(%ebp),%eax
80106c40:	89 44 24 04          	mov    %eax,0x4(%esp)
80106c44:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c47:	89 04 24             	mov    %eax,(%esp)
80106c4a:	e8 32 b4 ff ff       	call   80102081 <dirlookup>
80106c4f:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106c52:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106c56:	74 47                	je     80106c9f <create+0xb4>
    iunlockput(dp);
80106c58:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c5b:	89 04 24             	mov    %eax,(%esp)
80106c5e:	e8 89 ae ff ff       	call   80101aec <iunlockput>
    ilock(ip);
80106c63:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c66:	89 04 24             	mov    %eax,(%esp)
80106c69:	e8 fa ab ff ff       	call   80101868 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
80106c6e:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
80106c73:	75 15                	jne    80106c8a <create+0x9f>
80106c75:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c78:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106c7c:	66 83 f8 02          	cmp    $0x2,%ax
80106c80:	75 08                	jne    80106c8a <create+0x9f>
      return ip;
80106c82:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c85:	e9 1f 01 00 00       	jmp    80106da9 <create+0x1be>
    iunlockput(ip);
80106c8a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c8d:	89 04 24             	mov    %eax,(%esp)
80106c90:	e8 57 ae ff ff       	call   80101aec <iunlockput>
    return 0;
80106c95:	b8 00 00 00 00       	mov    $0x0,%eax
80106c9a:	e9 0a 01 00 00       	jmp    80106da9 <create+0x1be>
  }
  if((ip = ialloc(dp->dev, type)) == 0)
80106c9f:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
80106ca3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ca6:	8b 00                	mov    (%eax),%eax
80106ca8:	89 54 24 04          	mov    %edx,0x4(%esp)
80106cac:	89 04 24             	mov    %eax,(%esp)
80106caf:	e8 1b a9 ff ff       	call   801015cf <ialloc>
80106cb4:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106cb7:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106cbb:	75 0c                	jne    80106cc9 <create+0xde>
    panic("create: ialloc");
80106cbd:	c7 04 24 86 9d 10 80 	movl   $0x80109d86,(%esp)
80106cc4:	e8 74 98 ff ff       	call   8010053d <panic>
  ilock(ip);
80106cc9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ccc:	89 04 24             	mov    %eax,(%esp)
80106ccf:	e8 94 ab ff ff       	call   80101868 <ilock>
  ip->major = major;
80106cd4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106cd7:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
80106cdb:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
80106cdf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ce2:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
80106ce6:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
80106cea:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ced:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
80106cf3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106cf6:	89 04 24             	mov    %eax,(%esp)
80106cf9:	e8 ae a9 ff ff       	call   801016ac <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
80106cfe:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
80106d03:	75 6a                	jne    80106d6f <create+0x184>
    dp->nlink++;  // for ".."
80106d05:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d08:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106d0c:	8d 50 01             	lea    0x1(%eax),%edx
80106d0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d12:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80106d16:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d19:	89 04 24             	mov    %eax,(%esp)
80106d1c:	e8 8b a9 ff ff       	call   801016ac <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80106d21:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d24:	8b 40 04             	mov    0x4(%eax),%eax
80106d27:	89 44 24 08          	mov    %eax,0x8(%esp)
80106d2b:	c7 44 24 04 60 9d 10 	movl   $0x80109d60,0x4(%esp)
80106d32:	80 
80106d33:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d36:	89 04 24             	mov    %eax,(%esp)
80106d39:	e8 0b b4 ff ff       	call   80102149 <dirlink>
80106d3e:	85 c0                	test   %eax,%eax
80106d40:	78 21                	js     80106d63 <create+0x178>
80106d42:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d45:	8b 40 04             	mov    0x4(%eax),%eax
80106d48:	89 44 24 08          	mov    %eax,0x8(%esp)
80106d4c:	c7 44 24 04 62 9d 10 	movl   $0x80109d62,0x4(%esp)
80106d53:	80 
80106d54:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d57:	89 04 24             	mov    %eax,(%esp)
80106d5a:	e8 ea b3 ff ff       	call   80102149 <dirlink>
80106d5f:	85 c0                	test   %eax,%eax
80106d61:	79 0c                	jns    80106d6f <create+0x184>
      panic("create dots");
80106d63:	c7 04 24 95 9d 10 80 	movl   $0x80109d95,(%esp)
80106d6a:	e8 ce 97 ff ff       	call   8010053d <panic>
  }
  if(dirlink(dp, name, ip->inum) < 0)
80106d6f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d72:	8b 40 04             	mov    0x4(%eax),%eax
80106d75:	89 44 24 08          	mov    %eax,0x8(%esp)
80106d79:	8d 45 de             	lea    -0x22(%ebp),%eax
80106d7c:	89 44 24 04          	mov    %eax,0x4(%esp)
80106d80:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d83:	89 04 24             	mov    %eax,(%esp)
80106d86:	e8 be b3 ff ff       	call   80102149 <dirlink>
80106d8b:	85 c0                	test   %eax,%eax
80106d8d:	79 0c                	jns    80106d9b <create+0x1b0>
    panic("create: dirlink");
80106d8f:	c7 04 24 a1 9d 10 80 	movl   $0x80109da1,(%esp)
80106d96:	e8 a2 97 ff ff       	call   8010053d <panic>
  iunlockput(dp);
80106d9b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d9e:	89 04 24             	mov    %eax,(%esp)
80106da1:	e8 46 ad ff ff       	call   80101aec <iunlockput>

  return ip;
80106da6:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80106da9:	c9                   	leave  
80106daa:	c3                   	ret    

80106dab <fileopen>:

struct file*
fileopen(char *path, int omode)
{
80106dab:	55                   	push   %ebp
80106dac:	89 e5                	mov    %esp,%ebp
80106dae:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  struct inode *ip;

  if(omode & O_CREATE){
80106db1:	8b 45 0c             	mov    0xc(%ebp),%eax
80106db4:	25 00 02 00 00       	and    $0x200,%eax
80106db9:	85 c0                	test   %eax,%eax
80106dbb:	74 4c                	je     80106e09 <fileopen+0x5e>
    begin_trans();
80106dbd:	e8 5d cc ff ff       	call   80103a1f <begin_trans>
    ip = create(path, T_FILE, 0, 0);cprintf("1\n");
80106dc2:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106dc9:	00 
80106dca:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106dd1:	00 
80106dd2:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80106dd9:	00 
80106dda:	8b 45 08             	mov    0x8(%ebp),%eax
80106ddd:	89 04 24             	mov    %eax,(%esp)
80106de0:	e8 06 fe ff ff       	call   80106beb <create>
80106de5:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106de8:	c7 04 24 b1 9d 10 80 	movl   $0x80109db1,(%esp)
80106def:	e8 ad 95 ff ff       	call   801003a1 <cprintf>
    commit_trans();
80106df4:	e8 78 cc ff ff       	call   80103a71 <commit_trans>
    if(ip == 0)
80106df9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106dfd:	75 73                	jne    80106e72 <fileopen+0xc7>
      return 0;
80106dff:	b8 00 00 00 00       	mov    $0x0,%eax
80106e04:	e9 11 01 00 00       	jmp    80106f1a <fileopen+0x16f>
  } else {
    if((ip = namei(path)) == 0)
80106e09:	8b 45 08             	mov    0x8(%ebp),%eax
80106e0c:	89 04 24             	mov    %eax,(%esp)
80106e0f:	e8 f6 b5 ff ff       	call   8010240a <namei>
80106e14:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106e17:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106e1b:	75 0a                	jne    80106e27 <fileopen+0x7c>
      return 0;cprintf("4\n");
80106e1d:	b8 00 00 00 00       	mov    $0x0,%eax
80106e22:	e9 f3 00 00 00       	jmp    80106f1a <fileopen+0x16f>
80106e27:	c7 04 24 b4 9d 10 80 	movl   $0x80109db4,(%esp)
80106e2e:	e8 6e 95 ff ff       	call   801003a1 <cprintf>
    ilock(ip);
80106e33:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e36:	89 04 24             	mov    %eax,(%esp)
80106e39:	e8 2a aa ff ff       	call   80101868 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){cprintf("5\n");
80106e3e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e41:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106e45:	66 83 f8 01          	cmp    $0x1,%ax
80106e49:	75 27                	jne    80106e72 <fileopen+0xc7>
80106e4b:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80106e4f:	74 21                	je     80106e72 <fileopen+0xc7>
80106e51:	c7 04 24 b7 9d 10 80 	movl   $0x80109db7,(%esp)
80106e58:	e8 44 95 ff ff       	call   801003a1 <cprintf>
      iunlockput(ip);
80106e5d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e60:	89 04 24             	mov    %eax,(%esp)
80106e63:	e8 84 ac ff ff       	call   80101aec <iunlockput>
      return 0;
80106e68:	b8 00 00 00 00       	mov    $0x0,%eax
80106e6d:	e9 a8 00 00 00       	jmp    80106f1a <fileopen+0x16f>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80106e72:	e8 a5 a0 ff ff       	call   80100f1c <filealloc>
80106e77:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106e7a:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106e7e:	74 14                	je     80106e94 <fileopen+0xe9>
80106e80:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106e83:	89 04 24             	mov    %eax,(%esp)
80106e86:	e8 a6 f5 ff ff       	call   80106431 <fdalloc>
80106e8b:	89 45 ec             	mov    %eax,-0x14(%ebp)
80106e8e:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80106e92:	79 23                	jns    80106eb7 <fileopen+0x10c>
    if(f)
80106e94:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106e98:	74 0b                	je     80106ea5 <fileopen+0xfa>
      fileclose(f);
80106e9a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106e9d:	89 04 24             	mov    %eax,(%esp)
80106ea0:	e8 1f a1 ff ff       	call   80100fc4 <fileclose>
    iunlockput(ip);
80106ea5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ea8:	89 04 24             	mov    %eax,(%esp)
80106eab:	e8 3c ac ff ff       	call   80101aec <iunlockput>
    return 0;
80106eb0:	b8 00 00 00 00       	mov    $0x0,%eax
80106eb5:	eb 63                	jmp    80106f1a <fileopen+0x16f>
  }
  iunlock(ip);
80106eb7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106eba:	89 04 24             	mov    %eax,(%esp)
80106ebd:	e8 f4 aa ff ff       	call   801019b6 <iunlock>

  f->type = FD_INODE;
80106ec2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ec5:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80106ecb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ece:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106ed1:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
80106ed4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ed7:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80106ede:	8b 45 0c             	mov    0xc(%ebp),%eax
80106ee1:	83 e0 01             	and    $0x1,%eax
80106ee4:	85 c0                	test   %eax,%eax
80106ee6:	0f 94 c2             	sete   %dl
80106ee9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106eec:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80106eef:	8b 45 0c             	mov    0xc(%ebp),%eax
80106ef2:	83 e0 01             	and    $0x1,%eax
80106ef5:	84 c0                	test   %al,%al
80106ef7:	75 0a                	jne    80106f03 <fileopen+0x158>
80106ef9:	8b 45 0c             	mov    0xc(%ebp),%eax
80106efc:	83 e0 02             	and    $0x2,%eax
80106eff:	85 c0                	test   %eax,%eax
80106f01:	74 07                	je     80106f0a <fileopen+0x15f>
80106f03:	b8 01 00 00 00       	mov    $0x1,%eax
80106f08:	eb 05                	jmp    80106f0f <fileopen+0x164>
80106f0a:	b8 00 00 00 00       	mov    $0x0,%eax
80106f0f:	89 c2                	mov    %eax,%edx
80106f11:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106f14:	88 50 09             	mov    %dl,0x9(%eax)
  return f;
80106f17:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80106f1a:	c9                   	leave  
80106f1b:	c3                   	ret    

80106f1c <sys_open>:

int
sys_open(void)
{
80106f1c:	55                   	push   %ebp
80106f1d:	89 e5                	mov    %esp,%ebp
80106f1f:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80106f22:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106f25:	89 44 24 04          	mov    %eax,0x4(%esp)
80106f29:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106f30:	e8 7f f3 ff ff       	call   801062b4 <argstr>
80106f35:	85 c0                	test   %eax,%eax
80106f37:	78 17                	js     80106f50 <sys_open+0x34>
80106f39:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106f3c:	89 44 24 04          	mov    %eax,0x4(%esp)
80106f40:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106f47:	e8 ce f2 ff ff       	call   8010621a <argint>
80106f4c:	85 c0                	test   %eax,%eax
80106f4e:	79 0a                	jns    80106f5a <sys_open+0x3e>
    return -1;
80106f50:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106f55:	e9 46 01 00 00       	jmp    801070a0 <sys_open+0x184>
  if(omode & O_CREATE){
80106f5a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106f5d:	25 00 02 00 00       	and    $0x200,%eax
80106f62:	85 c0                	test   %eax,%eax
80106f64:	74 40                	je     80106fa6 <sys_open+0x8a>
    begin_trans();
80106f66:	e8 b4 ca ff ff       	call   80103a1f <begin_trans>
    ip = create(path, T_FILE, 0, 0);
80106f6b:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106f6e:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106f75:	00 
80106f76:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106f7d:	00 
80106f7e:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80106f85:	00 
80106f86:	89 04 24             	mov    %eax,(%esp)
80106f89:	e8 5d fc ff ff       	call   80106beb <create>
80106f8e:	89 45 f4             	mov    %eax,-0xc(%ebp)
    commit_trans();
80106f91:	e8 db ca ff ff       	call   80103a71 <commit_trans>
    if(ip == 0)
80106f96:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106f9a:	75 5c                	jne    80106ff8 <sys_open+0xdc>
      return -1;
80106f9c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106fa1:	e9 fa 00 00 00       	jmp    801070a0 <sys_open+0x184>
  } else {
    if((ip = namei(path)) == 0)
80106fa6:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106fa9:	89 04 24             	mov    %eax,(%esp)
80106fac:	e8 59 b4 ff ff       	call   8010240a <namei>
80106fb1:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106fb4:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106fb8:	75 0a                	jne    80106fc4 <sys_open+0xa8>
      return -1;
80106fba:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106fbf:	e9 dc 00 00 00       	jmp    801070a0 <sys_open+0x184>
    ilock(ip);
80106fc4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106fc7:	89 04 24             	mov    %eax,(%esp)
80106fca:	e8 99 a8 ff ff       	call   80101868 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80106fcf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106fd2:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106fd6:	66 83 f8 01          	cmp    $0x1,%ax
80106fda:	75 1c                	jne    80106ff8 <sys_open+0xdc>
80106fdc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106fdf:	85 c0                	test   %eax,%eax
80106fe1:	74 15                	je     80106ff8 <sys_open+0xdc>
      iunlockput(ip);
80106fe3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106fe6:	89 04 24             	mov    %eax,(%esp)
80106fe9:	e8 fe aa ff ff       	call   80101aec <iunlockput>
      return -1;
80106fee:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106ff3:	e9 a8 00 00 00       	jmp    801070a0 <sys_open+0x184>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80106ff8:	e8 1f 9f ff ff       	call   80100f1c <filealloc>
80106ffd:	89 45 f0             	mov    %eax,-0x10(%ebp)
80107000:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107004:	74 14                	je     8010701a <sys_open+0xfe>
80107006:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107009:	89 04 24             	mov    %eax,(%esp)
8010700c:	e8 20 f4 ff ff       	call   80106431 <fdalloc>
80107011:	89 45 ec             	mov    %eax,-0x14(%ebp)
80107014:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80107018:	79 23                	jns    8010703d <sys_open+0x121>
    if(f)
8010701a:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010701e:	74 0b                	je     8010702b <sys_open+0x10f>
      fileclose(f);
80107020:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107023:	89 04 24             	mov    %eax,(%esp)
80107026:	e8 99 9f ff ff       	call   80100fc4 <fileclose>
    iunlockput(ip);
8010702b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010702e:	89 04 24             	mov    %eax,(%esp)
80107031:	e8 b6 aa ff ff       	call   80101aec <iunlockput>
    return -1;
80107036:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010703b:	eb 63                	jmp    801070a0 <sys_open+0x184>
  }
  iunlock(ip);
8010703d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107040:	89 04 24             	mov    %eax,(%esp)
80107043:	e8 6e a9 ff ff       	call   801019b6 <iunlock>

  f->type = FD_INODE;
80107048:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010704b:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80107051:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107054:	8b 55 f4             	mov    -0xc(%ebp),%edx
80107057:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
8010705a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010705d:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80107064:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80107067:	83 e0 01             	and    $0x1,%eax
8010706a:	85 c0                	test   %eax,%eax
8010706c:	0f 94 c2             	sete   %dl
8010706f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107072:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80107075:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80107078:	83 e0 01             	and    $0x1,%eax
8010707b:	84 c0                	test   %al,%al
8010707d:	75 0a                	jne    80107089 <sys_open+0x16d>
8010707f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80107082:	83 e0 02             	and    $0x2,%eax
80107085:	85 c0                	test   %eax,%eax
80107087:	74 07                	je     80107090 <sys_open+0x174>
80107089:	b8 01 00 00 00       	mov    $0x1,%eax
8010708e:	eb 05                	jmp    80107095 <sys_open+0x179>
80107090:	b8 00 00 00 00       	mov    $0x0,%eax
80107095:	89 c2                	mov    %eax,%edx
80107097:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010709a:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
8010709d:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
801070a0:	c9                   	leave  
801070a1:	c3                   	ret    

801070a2 <sys_mkdir>:

int
sys_mkdir(void)
{
801070a2:	55                   	push   %ebp
801070a3:	89 e5                	mov    %esp,%ebp
801070a5:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_trans();
801070a8:	e8 72 c9 ff ff       	call   80103a1f <begin_trans>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
801070ad:	8d 45 f0             	lea    -0x10(%ebp),%eax
801070b0:	89 44 24 04          	mov    %eax,0x4(%esp)
801070b4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801070bb:	e8 f4 f1 ff ff       	call   801062b4 <argstr>
801070c0:	85 c0                	test   %eax,%eax
801070c2:	78 2c                	js     801070f0 <sys_mkdir+0x4e>
801070c4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801070c7:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
801070ce:	00 
801070cf:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801070d6:	00 
801070d7:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801070de:	00 
801070df:	89 04 24             	mov    %eax,(%esp)
801070e2:	e8 04 fb ff ff       	call   80106beb <create>
801070e7:	89 45 f4             	mov    %eax,-0xc(%ebp)
801070ea:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801070ee:	75 0c                	jne    801070fc <sys_mkdir+0x5a>
    commit_trans();
801070f0:	e8 7c c9 ff ff       	call   80103a71 <commit_trans>
    return -1;
801070f5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801070fa:	eb 15                	jmp    80107111 <sys_mkdir+0x6f>
  }
  iunlockput(ip);
801070fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801070ff:	89 04 24             	mov    %eax,(%esp)
80107102:	e8 e5 a9 ff ff       	call   80101aec <iunlockput>
  commit_trans();
80107107:	e8 65 c9 ff ff       	call   80103a71 <commit_trans>
  return 0;
8010710c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107111:	c9                   	leave  
80107112:	c3                   	ret    

80107113 <sys_mknod>:

int
sys_mknod(void)
{
80107113:	55                   	push   %ebp
80107114:	89 e5                	mov    %esp,%ebp
80107116:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
80107119:	e8 01 c9 ff ff       	call   80103a1f <begin_trans>
  if((len=argstr(0, &path)) < 0 ||
8010711e:	8d 45 ec             	lea    -0x14(%ebp),%eax
80107121:	89 44 24 04          	mov    %eax,0x4(%esp)
80107125:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010712c:	e8 83 f1 ff ff       	call   801062b4 <argstr>
80107131:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107134:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80107138:	78 5e                	js     80107198 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
8010713a:	8d 45 e8             	lea    -0x18(%ebp),%eax
8010713d:	89 44 24 04          	mov    %eax,0x4(%esp)
80107141:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80107148:	e8 cd f0 ff ff       	call   8010621a <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
8010714d:	85 c0                	test   %eax,%eax
8010714f:	78 47                	js     80107198 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80107151:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80107154:	89 44 24 04          	mov    %eax,0x4(%esp)
80107158:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
8010715f:	e8 b6 f0 ff ff       	call   8010621a <argint>
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
80107164:	85 c0                	test   %eax,%eax
80107166:	78 30                	js     80107198 <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
80107168:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010716b:	0f bf c8             	movswl %ax,%ecx
8010716e:	8b 45 e8             	mov    -0x18(%ebp),%eax
80107171:	0f bf d0             	movswl %ax,%edx
80107174:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80107177:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
8010717b:	89 54 24 08          	mov    %edx,0x8(%esp)
8010717f:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80107186:	00 
80107187:	89 04 24             	mov    %eax,(%esp)
8010718a:	e8 5c fa ff ff       	call   80106beb <create>
8010718f:	89 45 f0             	mov    %eax,-0x10(%ebp)
80107192:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107196:	75 0c                	jne    801071a4 <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    commit_trans();
80107198:	e8 d4 c8 ff ff       	call   80103a71 <commit_trans>
    return -1;
8010719d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801071a2:	eb 15                	jmp    801071b9 <sys_mknod+0xa6>
  }
  iunlockput(ip);
801071a4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801071a7:	89 04 24             	mov    %eax,(%esp)
801071aa:	e8 3d a9 ff ff       	call   80101aec <iunlockput>
  commit_trans();
801071af:	e8 bd c8 ff ff       	call   80103a71 <commit_trans>
  return 0;
801071b4:	b8 00 00 00 00       	mov    $0x0,%eax
}
801071b9:	c9                   	leave  
801071ba:	c3                   	ret    

801071bb <sys_chdir>:

int
sys_chdir(void)
{
801071bb:	55                   	push   %ebp
801071bc:	89 e5                	mov    %esp,%ebp
801071be:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0)
801071c1:	8d 45 f0             	lea    -0x10(%ebp),%eax
801071c4:	89 44 24 04          	mov    %eax,0x4(%esp)
801071c8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801071cf:	e8 e0 f0 ff ff       	call   801062b4 <argstr>
801071d4:	85 c0                	test   %eax,%eax
801071d6:	78 14                	js     801071ec <sys_chdir+0x31>
801071d8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801071db:	89 04 24             	mov    %eax,(%esp)
801071de:	e8 27 b2 ff ff       	call   8010240a <namei>
801071e3:	89 45 f4             	mov    %eax,-0xc(%ebp)
801071e6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801071ea:	75 07                	jne    801071f3 <sys_chdir+0x38>
    return -1;
801071ec:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801071f1:	eb 57                	jmp    8010724a <sys_chdir+0x8f>
  ilock(ip);
801071f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801071f6:	89 04 24             	mov    %eax,(%esp)
801071f9:	e8 6a a6 ff ff       	call   80101868 <ilock>
  if(ip->type != T_DIR){
801071fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107201:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80107205:	66 83 f8 01          	cmp    $0x1,%ax
80107209:	74 12                	je     8010721d <sys_chdir+0x62>
    iunlockput(ip);
8010720b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010720e:	89 04 24             	mov    %eax,(%esp)
80107211:	e8 d6 a8 ff ff       	call   80101aec <iunlockput>
    return -1;
80107216:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010721b:	eb 2d                	jmp    8010724a <sys_chdir+0x8f>
  }
  iunlock(ip);
8010721d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107220:	89 04 24             	mov    %eax,(%esp)
80107223:	e8 8e a7 ff ff       	call   801019b6 <iunlock>
  iput(proc->cwd);
80107228:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010722e:	8b 40 68             	mov    0x68(%eax),%eax
80107231:	89 04 24             	mov    %eax,(%esp)
80107234:	e8 e2 a7 ff ff       	call   80101a1b <iput>
  proc->cwd = ip;
80107239:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010723f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80107242:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
80107245:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010724a:	c9                   	leave  
8010724b:	c3                   	ret    

8010724c <sys_exec>:

int
sys_exec(void)
{
8010724c:	55                   	push   %ebp
8010724d:	89 e5                	mov    %esp,%ebp
8010724f:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80107255:	8d 45 f0             	lea    -0x10(%ebp),%eax
80107258:	89 44 24 04          	mov    %eax,0x4(%esp)
8010725c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107263:	e8 4c f0 ff ff       	call   801062b4 <argstr>
80107268:	85 c0                	test   %eax,%eax
8010726a:	78 1a                	js     80107286 <sys_exec+0x3a>
8010726c:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80107272:	89 44 24 04          	mov    %eax,0x4(%esp)
80107276:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010727d:	e8 98 ef ff ff       	call   8010621a <argint>
80107282:	85 c0                	test   %eax,%eax
80107284:	79 0a                	jns    80107290 <sys_exec+0x44>
    return -1;
80107286:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010728b:	e9 e2 00 00 00       	jmp    80107372 <sys_exec+0x126>
  }
  memset(argv, 0, sizeof(argv));
80107290:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80107297:	00 
80107298:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010729f:	00 
801072a0:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
801072a6:	89 04 24             	mov    %eax,(%esp)
801072a9:	e8 1c ec ff ff       	call   80105eca <memset>
  for(i=0;; i++){
801072ae:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
801072b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801072b8:	83 f8 1f             	cmp    $0x1f,%eax
801072bb:	76 0a                	jbe    801072c7 <sys_exec+0x7b>
      return -1;
801072bd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801072c2:	e9 ab 00 00 00       	jmp    80107372 <sys_exec+0x126>
    if(fetchint(proc, uargv+4*i, (int*)&uarg) < 0)
801072c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801072ca:	c1 e0 02             	shl    $0x2,%eax
801072cd:	89 c2                	mov    %eax,%edx
801072cf:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
801072d5:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
801072d8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801072de:	8d 95 68 ff ff ff    	lea    -0x98(%ebp),%edx
801072e4:	89 54 24 08          	mov    %edx,0x8(%esp)
801072e8:	89 4c 24 04          	mov    %ecx,0x4(%esp)
801072ec:	89 04 24             	mov    %eax,(%esp)
801072ef:	e8 94 ee ff ff       	call   80106188 <fetchint>
801072f4:	85 c0                	test   %eax,%eax
801072f6:	79 07                	jns    801072ff <sys_exec+0xb3>
      return -1;
801072f8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801072fd:	eb 73                	jmp    80107372 <sys_exec+0x126>
    if(uarg == 0){
801072ff:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80107305:	85 c0                	test   %eax,%eax
80107307:	75 26                	jne    8010732f <sys_exec+0xe3>
      argv[i] = 0;
80107309:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010730c:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
80107313:	00 00 00 00 
      break;
80107317:	90                   	nop
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
80107318:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010731b:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
80107321:	89 54 24 04          	mov    %edx,0x4(%esp)
80107325:	89 04 24             	mov    %eax,(%esp)
80107328:	e8 cf 97 ff ff       	call   80100afc <exec>
8010732d:	eb 43                	jmp    80107372 <sys_exec+0x126>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
8010732f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107332:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80107339:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
8010733f:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
80107342:	8b 95 68 ff ff ff    	mov    -0x98(%ebp),%edx
80107348:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010734e:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80107352:	89 54 24 04          	mov    %edx,0x4(%esp)
80107356:	89 04 24             	mov    %eax,(%esp)
80107359:	e8 5e ee ff ff       	call   801061bc <fetchstr>
8010735e:	85 c0                	test   %eax,%eax
80107360:	79 07                	jns    80107369 <sys_exec+0x11d>
      return -1;
80107362:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107367:	eb 09                	jmp    80107372 <sys_exec+0x126>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
80107369:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
8010736d:	e9 43 ff ff ff       	jmp    801072b5 <sys_exec+0x69>
  return exec(path, argv);
}
80107372:	c9                   	leave  
80107373:	c3                   	ret    

80107374 <sys_pipe>:

int
sys_pipe(void)
{
80107374:	55                   	push   %ebp
80107375:	89 e5                	mov    %esp,%ebp
80107377:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
8010737a:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
80107381:	00 
80107382:	8d 45 ec             	lea    -0x14(%ebp),%eax
80107385:	89 44 24 04          	mov    %eax,0x4(%esp)
80107389:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107390:	e8 bd ee ff ff       	call   80106252 <argptr>
80107395:	85 c0                	test   %eax,%eax
80107397:	79 0a                	jns    801073a3 <sys_pipe+0x2f>
    return -1;
80107399:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010739e:	e9 9b 00 00 00       	jmp    8010743e <sys_pipe+0xca>
  if(pipealloc(&rf, &wf) < 0)
801073a3:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801073a6:	89 44 24 04          	mov    %eax,0x4(%esp)
801073aa:	8d 45 e8             	lea    -0x18(%ebp),%eax
801073ad:	89 04 24             	mov    %eax,(%esp)
801073b0:	e8 83 d0 ff ff       	call   80104438 <pipealloc>
801073b5:	85 c0                	test   %eax,%eax
801073b7:	79 07                	jns    801073c0 <sys_pipe+0x4c>
    return -1;
801073b9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801073be:	eb 7e                	jmp    8010743e <sys_pipe+0xca>
  fd0 = -1;
801073c0:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
801073c7:	8b 45 e8             	mov    -0x18(%ebp),%eax
801073ca:	89 04 24             	mov    %eax,(%esp)
801073cd:	e8 5f f0 ff ff       	call   80106431 <fdalloc>
801073d2:	89 45 f4             	mov    %eax,-0xc(%ebp)
801073d5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801073d9:	78 14                	js     801073ef <sys_pipe+0x7b>
801073db:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801073de:	89 04 24             	mov    %eax,(%esp)
801073e1:	e8 4b f0 ff ff       	call   80106431 <fdalloc>
801073e6:	89 45 f0             	mov    %eax,-0x10(%ebp)
801073e9:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801073ed:	79 37                	jns    80107426 <sys_pipe+0xb2>
    if(fd0 >= 0)
801073ef:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801073f3:	78 14                	js     80107409 <sys_pipe+0x95>
      proc->ofile[fd0] = 0;
801073f5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801073fb:	8b 55 f4             	mov    -0xc(%ebp),%edx
801073fe:	83 c2 08             	add    $0x8,%edx
80107401:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80107408:	00 
    fileclose(rf);
80107409:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010740c:	89 04 24             	mov    %eax,(%esp)
8010740f:	e8 b0 9b ff ff       	call   80100fc4 <fileclose>
    fileclose(wf);
80107414:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80107417:	89 04 24             	mov    %eax,(%esp)
8010741a:	e8 a5 9b ff ff       	call   80100fc4 <fileclose>
    return -1;
8010741f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107424:	eb 18                	jmp    8010743e <sys_pipe+0xca>
  }
  fd[0] = fd0;
80107426:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107429:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010742c:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
8010742e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107431:	8d 50 04             	lea    0x4(%eax),%edx
80107434:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107437:	89 02                	mov    %eax,(%edx)
  return 0;
80107439:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010743e:	c9                   	leave  
8010743f:	c3                   	ret    

80107440 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80107440:	55                   	push   %ebp
80107441:	89 e5                	mov    %esp,%ebp
80107443:	83 ec 08             	sub    $0x8,%esp
  return fork();
80107446:	e8 ba dc ff ff       	call   80105105 <fork>
}
8010744b:	c9                   	leave  
8010744c:	c3                   	ret    

8010744d <sys_exit>:

int
sys_exit(void)
{
8010744d:	55                   	push   %ebp
8010744e:	89 e5                	mov    %esp,%ebp
80107450:	83 ec 08             	sub    $0x8,%esp
  exit();
80107453:	e8 10 de ff ff       	call   80105268 <exit>
  return 0;  // not reached
80107458:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010745d:	c9                   	leave  
8010745e:	c3                   	ret    

8010745f <sys_wait>:

int
sys_wait(void)
{
8010745f:	55                   	push   %ebp
80107460:	89 e5                	mov    %esp,%ebp
80107462:	83 ec 08             	sub    $0x8,%esp
  return wait();
80107465:	e8 3a df ff ff       	call   801053a4 <wait>
}
8010746a:	c9                   	leave  
8010746b:	c3                   	ret    

8010746c <sys_kill>:

int
sys_kill(void)
{
8010746c:	55                   	push   %ebp
8010746d:	89 e5                	mov    %esp,%ebp
8010746f:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
80107472:	8d 45 f4             	lea    -0xc(%ebp),%eax
80107475:	89 44 24 04          	mov    %eax,0x4(%esp)
80107479:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107480:	e8 95 ed ff ff       	call   8010621a <argint>
80107485:	85 c0                	test   %eax,%eax
80107487:	79 07                	jns    80107490 <sys_kill+0x24>
    return -1;
80107489:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010748e:	eb 0b                	jmp    8010749b <sys_kill+0x2f>
  return kill(pid);
80107490:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107493:	89 04 24             	mov    %eax,(%esp)
80107496:	e8 a7 e4 ff ff       	call   80105942 <kill>
}
8010749b:	c9                   	leave  
8010749c:	c3                   	ret    

8010749d <sys_getpid>:

int
sys_getpid(void)
{
8010749d:	55                   	push   %ebp
8010749e:	89 e5                	mov    %esp,%ebp
  return proc->pid;
801074a0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801074a6:	8b 40 10             	mov    0x10(%eax),%eax
}
801074a9:	5d                   	pop    %ebp
801074aa:	c3                   	ret    

801074ab <sys_sbrk>:

int
sys_sbrk(void)
{
801074ab:	55                   	push   %ebp
801074ac:	89 e5                	mov    %esp,%ebp
801074ae:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
801074b1:	8d 45 f0             	lea    -0x10(%ebp),%eax
801074b4:	89 44 24 04          	mov    %eax,0x4(%esp)
801074b8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801074bf:	e8 56 ed ff ff       	call   8010621a <argint>
801074c4:	85 c0                	test   %eax,%eax
801074c6:	79 07                	jns    801074cf <sys_sbrk+0x24>
    return -1;
801074c8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801074cd:	eb 24                	jmp    801074f3 <sys_sbrk+0x48>
  addr = proc->sz;
801074cf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801074d5:	8b 00                	mov    (%eax),%eax
801074d7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
801074da:	8b 45 f0             	mov    -0x10(%ebp),%eax
801074dd:	89 04 24             	mov    %eax,(%esp)
801074e0:	e8 7b db ff ff       	call   80105060 <growproc>
801074e5:	85 c0                	test   %eax,%eax
801074e7:	79 07                	jns    801074f0 <sys_sbrk+0x45>
    return -1;
801074e9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801074ee:	eb 03                	jmp    801074f3 <sys_sbrk+0x48>
  return addr;
801074f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801074f3:	c9                   	leave  
801074f4:	c3                   	ret    

801074f5 <sys_sleep>:

int
sys_sleep(void)
{
801074f5:	55                   	push   %ebp
801074f6:	89 e5                	mov    %esp,%ebp
801074f8:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
801074fb:	8d 45 f0             	lea    -0x10(%ebp),%eax
801074fe:	89 44 24 04          	mov    %eax,0x4(%esp)
80107502:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107509:	e8 0c ed ff ff       	call   8010621a <argint>
8010750e:	85 c0                	test   %eax,%eax
80107510:	79 07                	jns    80107519 <sys_sleep+0x24>
    return -1;
80107512:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107517:	eb 6c                	jmp    80107585 <sys_sleep+0x90>
  acquire(&tickslock);
80107519:	c7 04 24 c0 9c 12 80 	movl   $0x80129cc0,(%esp)
80107520:	e8 1e e7 ff ff       	call   80105c43 <acquire>
  ticks0 = ticks;
80107525:	a1 00 a5 12 80       	mov    0x8012a500,%eax
8010752a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
8010752d:	eb 34                	jmp    80107563 <sys_sleep+0x6e>
    if(proc->killed){
8010752f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107535:	8b 40 24             	mov    0x24(%eax),%eax
80107538:	85 c0                	test   %eax,%eax
8010753a:	74 13                	je     8010754f <sys_sleep+0x5a>
      release(&tickslock);
8010753c:	c7 04 24 c0 9c 12 80 	movl   $0x80129cc0,(%esp)
80107543:	e8 96 e7 ff ff       	call   80105cde <release>
      return -1;
80107548:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010754d:	eb 36                	jmp    80107585 <sys_sleep+0x90>
    }
    sleep(&ticks, &tickslock);
8010754f:	c7 44 24 04 c0 9c 12 	movl   $0x80129cc0,0x4(%esp)
80107556:	80 
80107557:	c7 04 24 00 a5 12 80 	movl   $0x8012a500,(%esp)
8010755e:	e8 9f e1 ff ff       	call   80105702 <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
80107563:	a1 00 a5 12 80       	mov    0x8012a500,%eax
80107568:	89 c2                	mov    %eax,%edx
8010756a:	2b 55 f4             	sub    -0xc(%ebp),%edx
8010756d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107570:	39 c2                	cmp    %eax,%edx
80107572:	72 bb                	jb     8010752f <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
80107574:	c7 04 24 c0 9c 12 80 	movl   $0x80129cc0,(%esp)
8010757b:	e8 5e e7 ff ff       	call   80105cde <release>
  return 0;
80107580:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107585:	c9                   	leave  
80107586:	c3                   	ret    

80107587 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80107587:	55                   	push   %ebp
80107588:	89 e5                	mov    %esp,%ebp
8010758a:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
8010758d:	c7 04 24 c0 9c 12 80 	movl   $0x80129cc0,(%esp)
80107594:	e8 aa e6 ff ff       	call   80105c43 <acquire>
  xticks = ticks;
80107599:	a1 00 a5 12 80       	mov    0x8012a500,%eax
8010759e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
801075a1:	c7 04 24 c0 9c 12 80 	movl   $0x80129cc0,(%esp)
801075a8:	e8 31 e7 ff ff       	call   80105cde <release>
  return xticks;
801075ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801075b0:	c9                   	leave  
801075b1:	c3                   	ret    

801075b2 <sys_enableSwapping>:

void
sys_enableSwapping(void)
{
801075b2:	55                   	push   %ebp
801075b3:	89 e5                	mov    %esp,%ebp
  swapFlag = 1;
801075b5:	c7 05 80 c6 10 80 01 	movl   $0x1,0x8010c680
801075bc:	00 00 00 
}
801075bf:	5d                   	pop    %ebp
801075c0:	c3                   	ret    

801075c1 <sys_disableSwapping>:

void
sys_disableSwapping(void)
{
801075c1:	55                   	push   %ebp
801075c2:	89 e5                	mov    %esp,%ebp
  swapFlag = 0;
801075c4:	c7 05 80 c6 10 80 00 	movl   $0x0,0x8010c680
801075cb:	00 00 00 
}
801075ce:	5d                   	pop    %ebp
801075cf:	c3                   	ret    

801075d0 <sys_sleep2>:

int
sys_sleep2(void)
{
801075d0:	55                   	push   %ebp
801075d1:	89 e5                	mov    %esp,%ebp
801075d3:	83 ec 18             	sub    $0x18,%esp
  acquire(&tickslock);
801075d6:	c7 04 24 c0 9c 12 80 	movl   $0x80129cc0,(%esp)
801075dd:	e8 61 e6 ff ff       	call   80105c43 <acquire>
  if(proc->killed){
801075e2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801075e8:	8b 40 24             	mov    0x24(%eax),%eax
801075eb:	85 c0                	test   %eax,%eax
801075ed:	74 13                	je     80107602 <sys_sleep2+0x32>
    release(&tickslock);
801075ef:	c7 04 24 c0 9c 12 80 	movl   $0x80129cc0,(%esp)
801075f6:	e8 e3 e6 ff ff       	call   80105cde <release>
    return -1;
801075fb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107600:	eb 25                	jmp    80107627 <sys_sleep2+0x57>
  }
  sleep(&swapFlag, &tickslock);
80107602:	c7 44 24 04 c0 9c 12 	movl   $0x80129cc0,0x4(%esp)
80107609:	80 
8010760a:	c7 04 24 80 c6 10 80 	movl   $0x8010c680,(%esp)
80107611:	e8 ec e0 ff ff       	call   80105702 <sleep>
  release(&tickslock);
80107616:	c7 04 24 c0 9c 12 80 	movl   $0x80129cc0,(%esp)
8010761d:	e8 bc e6 ff ff       	call   80105cde <release>
  return 0;
80107622:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107627:	c9                   	leave  
80107628:	c3                   	ret    

80107629 <sys_wakeup2>:

int
sys_wakeup2(void)
{
80107629:	55                   	push   %ebp
8010762a:	89 e5                	mov    %esp,%ebp
8010762c:	83 ec 18             	sub    $0x18,%esp
  wakeup(&swapFlag);
8010762f:	c7 04 24 80 c6 10 80 	movl   $0x8010c680,(%esp)
80107636:	e8 dc e2 ff ff       	call   80105917 <wakeup>
  return 0;
8010763b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107640:	c9                   	leave  
80107641:	c3                   	ret    

80107642 <sys_getAllocatedPages>:

int
sys_getAllocatedPages(void)
{
80107642:	55                   	push   %ebp
80107643:	89 e5                	mov    %esp,%ebp
80107645:	83 ec 28             	sub    $0x28,%esp
  int pid;
  if(argint(0, &pid) < 0)
80107648:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010764b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010764f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107656:	e8 bf eb ff ff       	call   8010621a <argint>
8010765b:	85 c0                	test   %eax,%eax
8010765d:	79 07                	jns    80107666 <sys_getAllocatedPages+0x24>
    return -1;
8010765f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107664:	eb 0b                	jmp    80107671 <sys_getAllocatedPages+0x2f>
  return getAllocatedPages(pid);
80107666:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107669:	89 04 24             	mov    %eax,(%esp)
8010766c:	e8 97 e4 ff ff       	call   80105b08 <getAllocatedPages>
}
80107671:	c9                   	leave  
80107672:	c3                   	ret    

80107673 <sys_shmget>:

int 
sys_shmget(void)
{
80107673:	55                   	push   %ebp
80107674:	89 e5                	mov    %esp,%ebp
80107676:	83 ec 28             	sub    $0x28,%esp
  int key,size, shmflg;
  
  if(argint(0, &key) < 0)
80107679:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010767c:	89 44 24 04          	mov    %eax,0x4(%esp)
80107680:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107687:	e8 8e eb ff ff       	call   8010621a <argint>
8010768c:	85 c0                	test   %eax,%eax
8010768e:	79 07                	jns    80107697 <sys_shmget+0x24>
    return -1;
80107690:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107695:	eb 65                	jmp    801076fc <sys_shmget+0x89>
  
  if(argint(1, &size) < 0)
80107697:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010769a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010769e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801076a5:	e8 70 eb ff ff       	call   8010621a <argint>
801076aa:	85 c0                	test   %eax,%eax
801076ac:	79 07                	jns    801076b5 <sys_shmget+0x42>
    return -1;
801076ae:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801076b3:	eb 47                	jmp    801076fc <sys_shmget+0x89>
  if(size<0)
801076b5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801076b8:	85 c0                	test   %eax,%eax
801076ba:	79 07                	jns    801076c3 <sys_shmget+0x50>
    return -1;
801076bc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801076c1:	eb 39                	jmp    801076fc <sys_shmget+0x89>
  
  if(argint(2, &shmflg) < 0)
801076c3:	8d 45 ec             	lea    -0x14(%ebp),%eax
801076c6:	89 44 24 04          	mov    %eax,0x4(%esp)
801076ca:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801076d1:	e8 44 eb ff ff       	call   8010621a <argint>
801076d6:	85 c0                	test   %eax,%eax
801076d8:	79 07                	jns    801076e1 <sys_shmget+0x6e>
    return -1;
801076da:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801076df:	eb 1b                	jmp    801076fc <sys_shmget+0x89>
  
  return shmget(key, (uint)size,shmflg);
801076e1:	8b 4d ec             	mov    -0x14(%ebp),%ecx
801076e4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801076e7:	89 c2                	mov    %eax,%edx
801076e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076ec:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801076f0:	89 54 24 04          	mov    %edx,0x4(%esp)
801076f4:	89 04 24             	mov    %eax,(%esp)
801076f7:	e8 61 b4 ff ff       	call   80102b5d <shmget>
}
801076fc:	c9                   	leave  
801076fd:	c3                   	ret    

801076fe <sys_shmdel>:

int 
sys_shmdel(void)
{
801076fe:	55                   	push   %ebp
801076ff:	89 e5                	mov    %esp,%ebp
80107701:	83 ec 28             	sub    $0x28,%esp
  int shmid;
  if(argint(0, &shmid) < 0)
80107704:	8d 45 f4             	lea    -0xc(%ebp),%eax
80107707:	89 44 24 04          	mov    %eax,0x4(%esp)
8010770b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107712:	e8 03 eb ff ff       	call   8010621a <argint>
80107717:	85 c0                	test   %eax,%eax
80107719:	79 07                	jns    80107722 <sys_shmdel+0x24>
    return -1;
8010771b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107720:	eb 0b                	jmp    8010772d <sys_shmdel+0x2f>
  
  return shmdel(shmid);
80107722:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107725:	89 04 24             	mov    %eax,(%esp)
80107728:	e8 95 b5 ff ff       	call   80102cc2 <shmdel>
}
8010772d:	c9                   	leave  
8010772e:	c3                   	ret    

8010772f <sys_shmat>:

void *
sys_shmat(void)
{
8010772f:	55                   	push   %ebp
80107730:	89 e5                	mov    %esp,%ebp
80107732:	83 ec 28             	sub    $0x28,%esp
  int shmid,shmflg;
  
  if(argint(0, &shmid) < 0)
80107735:	8d 45 f4             	lea    -0xc(%ebp),%eax
80107738:	89 44 24 04          	mov    %eax,0x4(%esp)
8010773c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107743:	e8 d2 ea ff ff       	call   8010621a <argint>
80107748:	85 c0                	test   %eax,%eax
8010774a:	79 07                	jns    80107753 <sys_shmat+0x24>
    return (void*)-1;
8010774c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107751:	eb 30                	jmp    80107783 <sys_shmat+0x54>
  
  if(argint(1, &shmflg) < 0)
80107753:	8d 45 f0             	lea    -0x10(%ebp),%eax
80107756:	89 44 24 04          	mov    %eax,0x4(%esp)
8010775a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80107761:	e8 b4 ea ff ff       	call   8010621a <argint>
80107766:	85 c0                	test   %eax,%eax
80107768:	79 07                	jns    80107771 <sys_shmat+0x42>
    return (void*)-1;
8010776a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010776f:	eb 12                	jmp    80107783 <sys_shmat+0x54>
  
  return shmat(shmid,shmflg);
80107771:	8b 55 f0             	mov    -0x10(%ebp),%edx
80107774:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107777:	89 54 24 04          	mov    %edx,0x4(%esp)
8010777b:	89 04 24             	mov    %eax,(%esp)
8010777e:	e8 1a b6 ff ff       	call   80102d9d <shmat>
}
80107783:	c9                   	leave  
80107784:	c3                   	ret    

80107785 <sys_shmdt>:

int 
sys_shmdt(void)
{
80107785:	55                   	push   %ebp
80107786:	89 e5                	mov    %esp,%ebp
80107788:	83 ec 28             	sub    $0x28,%esp
  void* shmaddr;
  if(argptr(0, (void*)&shmaddr,sizeof(void*)) < 0)
8010778b:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80107792:	00 
80107793:	8d 45 f4             	lea    -0xc(%ebp),%eax
80107796:	89 44 24 04          	mov    %eax,0x4(%esp)
8010779a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801077a1:	e8 ac ea ff ff       	call   80106252 <argptr>
801077a6:	85 c0                	test   %eax,%eax
801077a8:	79 07                	jns    801077b1 <sys_shmdt+0x2c>
    return -1;
801077aa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801077af:	eb 0b                	jmp    801077bc <sys_shmdt+0x37>
  return shmdt(shmaddr);
801077b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077b4:	89 04 24             	mov    %eax,(%esp)
801077b7:	e8 f9 b7 ff ff       	call   80102fb5 <shmdt>
}
801077bc:	c9                   	leave  
801077bd:	c3                   	ret    
	...

801077c0 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801077c0:	55                   	push   %ebp
801077c1:	89 e5                	mov    %esp,%ebp
801077c3:	83 ec 08             	sub    $0x8,%esp
801077c6:	8b 55 08             	mov    0x8(%ebp),%edx
801077c9:	8b 45 0c             	mov    0xc(%ebp),%eax
801077cc:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801077d0:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801077d3:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801077d7:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801077db:	ee                   	out    %al,(%dx)
}
801077dc:	c9                   	leave  
801077dd:	c3                   	ret    

801077de <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
801077de:	55                   	push   %ebp
801077df:	89 e5                	mov    %esp,%ebp
801077e1:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
801077e4:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
801077eb:	00 
801077ec:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
801077f3:	e8 c8 ff ff ff       	call   801077c0 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
801077f8:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
801077ff:	00 
80107800:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
80107807:	e8 b4 ff ff ff       	call   801077c0 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
8010780c:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
80107813:	00 
80107814:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
8010781b:	e8 a0 ff ff ff       	call   801077c0 <outb>
  picenable(IRQ_TIMER);
80107820:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107827:	e8 95 ca ff ff       	call   801042c1 <picenable>
}
8010782c:	c9                   	leave  
8010782d:	c3                   	ret    
	...

80107830 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80107830:	1e                   	push   %ds
  pushl %es
80107831:	06                   	push   %es
  pushl %fs
80107832:	0f a0                	push   %fs
  pushl %gs
80107834:	0f a8                	push   %gs
  pushal
80107836:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
80107837:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
8010783b:	8e d8                	mov    %eax,%ds
  movw %ax, %es
8010783d:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
8010783f:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
80107843:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
80107845:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
80107847:	54                   	push   %esp
  call trap
80107848:	e8 de 01 00 00       	call   80107a2b <trap>
  addl $4, %esp
8010784d:	83 c4 04             	add    $0x4,%esp

80107850 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80107850:	61                   	popa   
  popl %gs
80107851:	0f a9                	pop    %gs
  popl %fs
80107853:	0f a1                	pop    %fs
  popl %es
80107855:	07                   	pop    %es
  popl %ds
80107856:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80107857:	83 c4 08             	add    $0x8,%esp
  iret
8010785a:	cf                   	iret   
	...

8010785c <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
8010785c:	55                   	push   %ebp
8010785d:	89 e5                	mov    %esp,%ebp
8010785f:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80107862:	8b 45 0c             	mov    0xc(%ebp),%eax
80107865:	83 e8 01             	sub    $0x1,%eax
80107868:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
8010786c:	8b 45 08             	mov    0x8(%ebp),%eax
8010786f:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80107873:	8b 45 08             	mov    0x8(%ebp),%eax
80107876:	c1 e8 10             	shr    $0x10,%eax
80107879:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
8010787d:	8d 45 fa             	lea    -0x6(%ebp),%eax
80107880:	0f 01 18             	lidtl  (%eax)
}
80107883:	c9                   	leave  
80107884:	c3                   	ret    

80107885 <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
80107885:	55                   	push   %ebp
80107886:	89 e5                	mov    %esp,%ebp
80107888:	53                   	push   %ebx
80107889:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
8010788c:	0f 20 d3             	mov    %cr2,%ebx
8010788f:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return val;
80107892:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80107895:	83 c4 10             	add    $0x10,%esp
80107898:	5b                   	pop    %ebx
80107899:	5d                   	pop    %ebp
8010789a:	c3                   	ret    

8010789b <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
8010789b:	55                   	push   %ebp
8010789c:	89 e5                	mov    %esp,%ebp
8010789e:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
801078a1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801078a8:	e9 c3 00 00 00       	jmp    80107970 <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
801078ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078b0:	8b 04 85 bc c0 10 80 	mov    -0x7fef3f44(,%eax,4),%eax
801078b7:	89 c2                	mov    %eax,%edx
801078b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078bc:	66 89 14 c5 00 9d 12 	mov    %dx,-0x7fed6300(,%eax,8)
801078c3:	80 
801078c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078c7:	66 c7 04 c5 02 9d 12 	movw   $0x8,-0x7fed62fe(,%eax,8)
801078ce:	80 08 00 
801078d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078d4:	0f b6 14 c5 04 9d 12 	movzbl -0x7fed62fc(,%eax,8),%edx
801078db:	80 
801078dc:	83 e2 e0             	and    $0xffffffe0,%edx
801078df:	88 14 c5 04 9d 12 80 	mov    %dl,-0x7fed62fc(,%eax,8)
801078e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078e9:	0f b6 14 c5 04 9d 12 	movzbl -0x7fed62fc(,%eax,8),%edx
801078f0:	80 
801078f1:	83 e2 1f             	and    $0x1f,%edx
801078f4:	88 14 c5 04 9d 12 80 	mov    %dl,-0x7fed62fc(,%eax,8)
801078fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078fe:	0f b6 14 c5 05 9d 12 	movzbl -0x7fed62fb(,%eax,8),%edx
80107905:	80 
80107906:	83 e2 f0             	and    $0xfffffff0,%edx
80107909:	83 ca 0e             	or     $0xe,%edx
8010790c:	88 14 c5 05 9d 12 80 	mov    %dl,-0x7fed62fb(,%eax,8)
80107913:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107916:	0f b6 14 c5 05 9d 12 	movzbl -0x7fed62fb(,%eax,8),%edx
8010791d:	80 
8010791e:	83 e2 ef             	and    $0xffffffef,%edx
80107921:	88 14 c5 05 9d 12 80 	mov    %dl,-0x7fed62fb(,%eax,8)
80107928:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010792b:	0f b6 14 c5 05 9d 12 	movzbl -0x7fed62fb(,%eax,8),%edx
80107932:	80 
80107933:	83 e2 9f             	and    $0xffffff9f,%edx
80107936:	88 14 c5 05 9d 12 80 	mov    %dl,-0x7fed62fb(,%eax,8)
8010793d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107940:	0f b6 14 c5 05 9d 12 	movzbl -0x7fed62fb(,%eax,8),%edx
80107947:	80 
80107948:	83 ca 80             	or     $0xffffff80,%edx
8010794b:	88 14 c5 05 9d 12 80 	mov    %dl,-0x7fed62fb(,%eax,8)
80107952:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107955:	8b 04 85 bc c0 10 80 	mov    -0x7fef3f44(,%eax,4),%eax
8010795c:	c1 e8 10             	shr    $0x10,%eax
8010795f:	89 c2                	mov    %eax,%edx
80107961:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107964:	66 89 14 c5 06 9d 12 	mov    %dx,-0x7fed62fa(,%eax,8)
8010796b:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
8010796c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107970:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
80107977:	0f 8e 30 ff ff ff    	jle    801078ad <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
8010797d:	a1 bc c1 10 80       	mov    0x8010c1bc,%eax
80107982:	66 a3 00 9f 12 80    	mov    %ax,0x80129f00
80107988:	66 c7 05 02 9f 12 80 	movw   $0x8,0x80129f02
8010798f:	08 00 
80107991:	0f b6 05 04 9f 12 80 	movzbl 0x80129f04,%eax
80107998:	83 e0 e0             	and    $0xffffffe0,%eax
8010799b:	a2 04 9f 12 80       	mov    %al,0x80129f04
801079a0:	0f b6 05 04 9f 12 80 	movzbl 0x80129f04,%eax
801079a7:	83 e0 1f             	and    $0x1f,%eax
801079aa:	a2 04 9f 12 80       	mov    %al,0x80129f04
801079af:	0f b6 05 05 9f 12 80 	movzbl 0x80129f05,%eax
801079b6:	83 c8 0f             	or     $0xf,%eax
801079b9:	a2 05 9f 12 80       	mov    %al,0x80129f05
801079be:	0f b6 05 05 9f 12 80 	movzbl 0x80129f05,%eax
801079c5:	83 e0 ef             	and    $0xffffffef,%eax
801079c8:	a2 05 9f 12 80       	mov    %al,0x80129f05
801079cd:	0f b6 05 05 9f 12 80 	movzbl 0x80129f05,%eax
801079d4:	83 c8 60             	or     $0x60,%eax
801079d7:	a2 05 9f 12 80       	mov    %al,0x80129f05
801079dc:	0f b6 05 05 9f 12 80 	movzbl 0x80129f05,%eax
801079e3:	83 c8 80             	or     $0xffffff80,%eax
801079e6:	a2 05 9f 12 80       	mov    %al,0x80129f05
801079eb:	a1 bc c1 10 80       	mov    0x8010c1bc,%eax
801079f0:	c1 e8 10             	shr    $0x10,%eax
801079f3:	66 a3 06 9f 12 80    	mov    %ax,0x80129f06
  
  initlock(&tickslock, "time");
801079f9:	c7 44 24 04 bc 9d 10 	movl   $0x80109dbc,0x4(%esp)
80107a00:	80 
80107a01:	c7 04 24 c0 9c 12 80 	movl   $0x80129cc0,(%esp)
80107a08:	e8 15 e2 ff ff       	call   80105c22 <initlock>
}
80107a0d:	c9                   	leave  
80107a0e:	c3                   	ret    

80107a0f <idtinit>:

void
idtinit(void)
{
80107a0f:	55                   	push   %ebp
80107a10:	89 e5                	mov    %esp,%ebp
80107a12:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
80107a15:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
80107a1c:	00 
80107a1d:	c7 04 24 00 9d 12 80 	movl   $0x80129d00,(%esp)
80107a24:	e8 33 fe ff ff       	call   8010785c <lidt>
}
80107a29:	c9                   	leave  
80107a2a:	c3                   	ret    

80107a2b <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
80107a2b:	55                   	push   %ebp
80107a2c:	89 e5                	mov    %esp,%ebp
80107a2e:	57                   	push   %edi
80107a2f:	56                   	push   %esi
80107a30:	53                   	push   %ebx
80107a31:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
80107a34:	8b 45 08             	mov    0x8(%ebp),%eax
80107a37:	8b 40 30             	mov    0x30(%eax),%eax
80107a3a:	83 f8 40             	cmp    $0x40,%eax
80107a3d:	75 3e                	jne    80107a7d <trap+0x52>
    if(proc->killed)
80107a3f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107a45:	8b 40 24             	mov    0x24(%eax),%eax
80107a48:	85 c0                	test   %eax,%eax
80107a4a:	74 05                	je     80107a51 <trap+0x26>
      exit();
80107a4c:	e8 17 d8 ff ff       	call   80105268 <exit>
    proc->tf = tf;
80107a51:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107a57:	8b 55 08             	mov    0x8(%ebp),%edx
80107a5a:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
80107a5d:	e8 95 e8 ff ff       	call   801062f7 <syscall>
    if(proc->killed)
80107a62:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107a68:	8b 40 24             	mov    0x24(%eax),%eax
80107a6b:	85 c0                	test   %eax,%eax
80107a6d:	0f 84 34 02 00 00    	je     80107ca7 <trap+0x27c>
      exit();
80107a73:	e8 f0 d7 ff ff       	call   80105268 <exit>
    return;
80107a78:	e9 2a 02 00 00       	jmp    80107ca7 <trap+0x27c>
  }

  switch(tf->trapno){
80107a7d:	8b 45 08             	mov    0x8(%ebp),%eax
80107a80:	8b 40 30             	mov    0x30(%eax),%eax
80107a83:	83 e8 20             	sub    $0x20,%eax
80107a86:	83 f8 1f             	cmp    $0x1f,%eax
80107a89:	0f 87 bc 00 00 00    	ja     80107b4b <trap+0x120>
80107a8f:	8b 04 85 64 9e 10 80 	mov    -0x7fef619c(,%eax,4),%eax
80107a96:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
80107a98:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107a9e:	0f b6 00             	movzbl (%eax),%eax
80107aa1:	84 c0                	test   %al,%al
80107aa3:	75 31                	jne    80107ad6 <trap+0xab>
      acquire(&tickslock);
80107aa5:	c7 04 24 c0 9c 12 80 	movl   $0x80129cc0,(%esp)
80107aac:	e8 92 e1 ff ff       	call   80105c43 <acquire>
      ticks++;
80107ab1:	a1 00 a5 12 80       	mov    0x8012a500,%eax
80107ab6:	83 c0 01             	add    $0x1,%eax
80107ab9:	a3 00 a5 12 80       	mov    %eax,0x8012a500
      wakeup(&ticks);
80107abe:	c7 04 24 00 a5 12 80 	movl   $0x8012a500,(%esp)
80107ac5:	e8 4d de ff ff       	call   80105917 <wakeup>
      release(&tickslock);
80107aca:	c7 04 24 c0 9c 12 80 	movl   $0x80129cc0,(%esp)
80107ad1:	e8 08 e2 ff ff       	call   80105cde <release>
    }
    lapiceoi();
80107ad6:	e8 0a bc ff ff       	call   801036e5 <lapiceoi>
    break;
80107adb:	e9 41 01 00 00       	jmp    80107c21 <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
80107ae0:	e8 12 ac ff ff       	call   801026f7 <ideintr>
    lapiceoi();
80107ae5:	e8 fb bb ff ff       	call   801036e5 <lapiceoi>
    break;
80107aea:	e9 32 01 00 00       	jmp    80107c21 <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
80107aef:	e8 cf b9 ff ff       	call   801034c3 <kbdintr>
    lapiceoi();
80107af4:	e8 ec bb ff ff       	call   801036e5 <lapiceoi>
    break;
80107af9:	e9 23 01 00 00       	jmp    80107c21 <trap+0x1f6>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
80107afe:	e8 a9 03 00 00       	call   80107eac <uartintr>
    lapiceoi();
80107b03:	e8 dd bb ff ff       	call   801036e5 <lapiceoi>
    break;
80107b08:	e9 14 01 00 00       	jmp    80107c21 <trap+0x1f6>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
            cpu->id, tf->cs, tf->eip);
80107b0d:	8b 45 08             	mov    0x8(%ebp),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80107b10:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
80107b13:	8b 45 08             	mov    0x8(%ebp),%eax
80107b16:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80107b1a:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
80107b1d:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107b23:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80107b26:	0f b6 c0             	movzbl %al,%eax
80107b29:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80107b2d:	89 54 24 08          	mov    %edx,0x8(%esp)
80107b31:	89 44 24 04          	mov    %eax,0x4(%esp)
80107b35:	c7 04 24 c4 9d 10 80 	movl   $0x80109dc4,(%esp)
80107b3c:	e8 60 88 ff ff       	call   801003a1 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
80107b41:	e8 9f bb ff ff       	call   801036e5 <lapiceoi>
    break;
80107b46:	e9 d6 00 00 00       	jmp    80107c21 <trap+0x1f6>
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
80107b4b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107b51:	85 c0                	test   %eax,%eax
80107b53:	74 11                	je     80107b66 <trap+0x13b>
80107b55:	8b 45 08             	mov    0x8(%ebp),%eax
80107b58:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80107b5c:	0f b7 c0             	movzwl %ax,%eax
80107b5f:	83 e0 03             	and    $0x3,%eax
80107b62:	85 c0                	test   %eax,%eax
80107b64:	75 46                	jne    80107bac <trap+0x181>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80107b66:	e8 1a fd ff ff       	call   80107885 <rcr2>
              tf->trapno, cpu->id, tf->eip, rcr2());
80107b6b:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80107b6e:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
80107b71:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107b78:	0f b6 12             	movzbl (%edx),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80107b7b:	0f b6 ca             	movzbl %dl,%ecx
              tf->trapno, cpu->id, tf->eip, rcr2());
80107b7e:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80107b81:	8b 52 30             	mov    0x30(%edx),%edx
80107b84:	89 44 24 10          	mov    %eax,0x10(%esp)
80107b88:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
80107b8c:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80107b90:	89 54 24 04          	mov    %edx,0x4(%esp)
80107b94:	c7 04 24 e8 9d 10 80 	movl   $0x80109de8,(%esp)
80107b9b:	e8 01 88 ff ff       	call   801003a1 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
80107ba0:	c7 04 24 1a 9e 10 80 	movl   $0x80109e1a,(%esp)
80107ba7:	e8 91 89 ff ff       	call   8010053d <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107bac:	e8 d4 fc ff ff       	call   80107885 <rcr2>
80107bb1:	89 c2                	mov    %eax,%edx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107bb3:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107bb6:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107bb9:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107bbf:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107bc2:	0f b6 f0             	movzbl %al,%esi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107bc5:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107bc8:	8b 58 34             	mov    0x34(%eax),%ebx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107bcb:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107bce:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107bd1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107bd7:	83 c0 6c             	add    $0x6c,%eax
80107bda:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80107bdd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107be3:	8b 40 10             	mov    0x10(%eax),%eax
80107be6:	89 54 24 1c          	mov    %edx,0x1c(%esp)
80107bea:	89 7c 24 18          	mov    %edi,0x18(%esp)
80107bee:	89 74 24 14          	mov    %esi,0x14(%esp)
80107bf2:	89 5c 24 10          	mov    %ebx,0x10(%esp)
80107bf6:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80107bfa:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80107bfd:	89 54 24 08          	mov    %edx,0x8(%esp)
80107c01:	89 44 24 04          	mov    %eax,0x4(%esp)
80107c05:	c7 04 24 20 9e 10 80 	movl   $0x80109e20,(%esp)
80107c0c:	e8 90 87 ff ff       	call   801003a1 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
80107c11:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107c17:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
80107c1e:	eb 01                	jmp    80107c21 <trap+0x1f6>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
80107c20:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80107c21:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107c27:	85 c0                	test   %eax,%eax
80107c29:	74 24                	je     80107c4f <trap+0x224>
80107c2b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107c31:	8b 40 24             	mov    0x24(%eax),%eax
80107c34:	85 c0                	test   %eax,%eax
80107c36:	74 17                	je     80107c4f <trap+0x224>
80107c38:	8b 45 08             	mov    0x8(%ebp),%eax
80107c3b:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80107c3f:	0f b7 c0             	movzwl %ax,%eax
80107c42:	83 e0 03             	and    $0x3,%eax
80107c45:	83 f8 03             	cmp    $0x3,%eax
80107c48:	75 05                	jne    80107c4f <trap+0x224>
    exit();
80107c4a:	e8 19 d6 ff ff       	call   80105268 <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
80107c4f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107c55:	85 c0                	test   %eax,%eax
80107c57:	74 1e                	je     80107c77 <trap+0x24c>
80107c59:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107c5f:	8b 40 0c             	mov    0xc(%eax),%eax
80107c62:	83 f8 04             	cmp    $0x4,%eax
80107c65:	75 10                	jne    80107c77 <trap+0x24c>
80107c67:	8b 45 08             	mov    0x8(%ebp),%eax
80107c6a:	8b 40 30             	mov    0x30(%eax),%eax
80107c6d:	83 f8 20             	cmp    $0x20,%eax
80107c70:	75 05                	jne    80107c77 <trap+0x24c>
    yield();
80107c72:	e8 2d da ff ff       	call   801056a4 <yield>

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80107c77:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107c7d:	85 c0                	test   %eax,%eax
80107c7f:	74 27                	je     80107ca8 <trap+0x27d>
80107c81:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107c87:	8b 40 24             	mov    0x24(%eax),%eax
80107c8a:	85 c0                	test   %eax,%eax
80107c8c:	74 1a                	je     80107ca8 <trap+0x27d>
80107c8e:	8b 45 08             	mov    0x8(%ebp),%eax
80107c91:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80107c95:	0f b7 c0             	movzwl %ax,%eax
80107c98:	83 e0 03             	and    $0x3,%eax
80107c9b:	83 f8 03             	cmp    $0x3,%eax
80107c9e:	75 08                	jne    80107ca8 <trap+0x27d>
    exit();
80107ca0:	e8 c3 d5 ff ff       	call   80105268 <exit>
80107ca5:	eb 01                	jmp    80107ca8 <trap+0x27d>
      exit();
    proc->tf = tf;
    syscall();
    if(proc->killed)
      exit();
    return;
80107ca7:	90                   	nop
    yield();

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
    exit();
}
80107ca8:	83 c4 3c             	add    $0x3c,%esp
80107cab:	5b                   	pop    %ebx
80107cac:	5e                   	pop    %esi
80107cad:	5f                   	pop    %edi
80107cae:	5d                   	pop    %ebp
80107caf:	c3                   	ret    

80107cb0 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80107cb0:	55                   	push   %ebp
80107cb1:	89 e5                	mov    %esp,%ebp
80107cb3:	53                   	push   %ebx
80107cb4:	83 ec 14             	sub    $0x14,%esp
80107cb7:	8b 45 08             	mov    0x8(%ebp),%eax
80107cba:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80107cbe:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80107cc2:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80107cc6:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80107cca:	ec                   	in     (%dx),%al
80107ccb:	89 c3                	mov    %eax,%ebx
80107ccd:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80107cd0:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80107cd4:	83 c4 14             	add    $0x14,%esp
80107cd7:	5b                   	pop    %ebx
80107cd8:	5d                   	pop    %ebp
80107cd9:	c3                   	ret    

80107cda <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80107cda:	55                   	push   %ebp
80107cdb:	89 e5                	mov    %esp,%ebp
80107cdd:	83 ec 08             	sub    $0x8,%esp
80107ce0:	8b 55 08             	mov    0x8(%ebp),%edx
80107ce3:	8b 45 0c             	mov    0xc(%ebp),%eax
80107ce6:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80107cea:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80107ced:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80107cf1:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80107cf5:	ee                   	out    %al,(%dx)
}
80107cf6:	c9                   	leave  
80107cf7:	c3                   	ret    

80107cf8 <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
80107cf8:	55                   	push   %ebp
80107cf9:	89 e5                	mov    %esp,%ebp
80107cfb:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
80107cfe:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107d05:	00 
80107d06:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80107d0d:	e8 c8 ff ff ff       	call   80107cda <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
80107d12:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
80107d19:	00 
80107d1a:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80107d21:	e8 b4 ff ff ff       	call   80107cda <outb>
  outb(COM1+0, 115200/9600);
80107d26:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
80107d2d:	00 
80107d2e:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107d35:	e8 a0 ff ff ff       	call   80107cda <outb>
  outb(COM1+1, 0);
80107d3a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107d41:	00 
80107d42:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80107d49:	e8 8c ff ff ff       	call   80107cda <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
80107d4e:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80107d55:	00 
80107d56:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80107d5d:	e8 78 ff ff ff       	call   80107cda <outb>
  outb(COM1+4, 0);
80107d62:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107d69:	00 
80107d6a:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
80107d71:	e8 64 ff ff ff       	call   80107cda <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
80107d76:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80107d7d:	00 
80107d7e:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80107d85:	e8 50 ff ff ff       	call   80107cda <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
80107d8a:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80107d91:	e8 1a ff ff ff       	call   80107cb0 <inb>
80107d96:	3c ff                	cmp    $0xff,%al
80107d98:	74 6c                	je     80107e06 <uartinit+0x10e>
    return;
  uart = 1;
80107d9a:	c7 05 14 c7 10 80 01 	movl   $0x1,0x8010c714
80107da1:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
80107da4:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80107dab:	e8 00 ff ff ff       	call   80107cb0 <inb>
  inb(COM1+0);
80107db0:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107db7:	e8 f4 fe ff ff       	call   80107cb0 <inb>
  picenable(IRQ_COM1);
80107dbc:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80107dc3:	e8 f9 c4 ff ff       	call   801042c1 <picenable>
  ioapicenable(IRQ_COM1, 0);
80107dc8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107dcf:	00 
80107dd0:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80107dd7:	e8 9e ab ff ff       	call   8010297a <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80107ddc:	c7 45 f4 e4 9e 10 80 	movl   $0x80109ee4,-0xc(%ebp)
80107de3:	eb 15                	jmp    80107dfa <uartinit+0x102>
    uartputc(*p);
80107de5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107de8:	0f b6 00             	movzbl (%eax),%eax
80107deb:	0f be c0             	movsbl %al,%eax
80107dee:	89 04 24             	mov    %eax,(%esp)
80107df1:	e8 13 00 00 00       	call   80107e09 <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80107df6:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107dfa:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107dfd:	0f b6 00             	movzbl (%eax),%eax
80107e00:	84 c0                	test   %al,%al
80107e02:	75 e1                	jne    80107de5 <uartinit+0xed>
80107e04:	eb 01                	jmp    80107e07 <uartinit+0x10f>
  outb(COM1+4, 0);
  outb(COM1+1, 0x01);    // Enable receive interrupts.

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
    return;
80107e06:	90                   	nop
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
    uartputc(*p);
}
80107e07:	c9                   	leave  
80107e08:	c3                   	ret    

80107e09 <uartputc>:

void
uartputc(int c)
{
80107e09:	55                   	push   %ebp
80107e0a:	89 e5                	mov    %esp,%ebp
80107e0c:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
80107e0f:	a1 14 c7 10 80       	mov    0x8010c714,%eax
80107e14:	85 c0                	test   %eax,%eax
80107e16:	74 4d                	je     80107e65 <uartputc+0x5c>
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80107e18:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80107e1f:	eb 10                	jmp    80107e31 <uartputc+0x28>
    microdelay(10);
80107e21:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
80107e28:	e8 dd b8 ff ff       	call   8010370a <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80107e2d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107e31:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
80107e35:	7f 16                	jg     80107e4d <uartputc+0x44>
80107e37:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80107e3e:	e8 6d fe ff ff       	call   80107cb0 <inb>
80107e43:	0f b6 c0             	movzbl %al,%eax
80107e46:	83 e0 20             	and    $0x20,%eax
80107e49:	85 c0                	test   %eax,%eax
80107e4b:	74 d4                	je     80107e21 <uartputc+0x18>
    microdelay(10);
  outb(COM1+0, c);
80107e4d:	8b 45 08             	mov    0x8(%ebp),%eax
80107e50:	0f b6 c0             	movzbl %al,%eax
80107e53:	89 44 24 04          	mov    %eax,0x4(%esp)
80107e57:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107e5e:	e8 77 fe ff ff       	call   80107cda <outb>
80107e63:	eb 01                	jmp    80107e66 <uartputc+0x5d>
uartputc(int c)
{
  int i;

  if(!uart)
    return;
80107e65:	90                   	nop
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
    microdelay(10);
  outb(COM1+0, c);
}
80107e66:	c9                   	leave  
80107e67:	c3                   	ret    

80107e68 <uartgetc>:

static int
uartgetc(void)
{
80107e68:	55                   	push   %ebp
80107e69:	89 e5                	mov    %esp,%ebp
80107e6b:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
80107e6e:	a1 14 c7 10 80       	mov    0x8010c714,%eax
80107e73:	85 c0                	test   %eax,%eax
80107e75:	75 07                	jne    80107e7e <uartgetc+0x16>
    return -1;
80107e77:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107e7c:	eb 2c                	jmp    80107eaa <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
80107e7e:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80107e85:	e8 26 fe ff ff       	call   80107cb0 <inb>
80107e8a:	0f b6 c0             	movzbl %al,%eax
80107e8d:	83 e0 01             	and    $0x1,%eax
80107e90:	85 c0                	test   %eax,%eax
80107e92:	75 07                	jne    80107e9b <uartgetc+0x33>
    return -1;
80107e94:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107e99:	eb 0f                	jmp    80107eaa <uartgetc+0x42>
  return inb(COM1+0);
80107e9b:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107ea2:	e8 09 fe ff ff       	call   80107cb0 <inb>
80107ea7:	0f b6 c0             	movzbl %al,%eax
}
80107eaa:	c9                   	leave  
80107eab:	c3                   	ret    

80107eac <uartintr>:

void
uartintr(void)
{
80107eac:	55                   	push   %ebp
80107ead:	89 e5                	mov    %esp,%ebp
80107eaf:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
80107eb2:	c7 04 24 68 7e 10 80 	movl   $0x80107e68,(%esp)
80107eb9:	e8 ef 88 ff ff       	call   801007ad <consoleintr>
}
80107ebe:	c9                   	leave  
80107ebf:	c3                   	ret    

80107ec0 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80107ec0:	6a 00                	push   $0x0
  pushl $0
80107ec2:	6a 00                	push   $0x0
  jmp alltraps
80107ec4:	e9 67 f9 ff ff       	jmp    80107830 <alltraps>

80107ec9 <vector1>:
.globl vector1
vector1:
  pushl $0
80107ec9:	6a 00                	push   $0x0
  pushl $1
80107ecb:	6a 01                	push   $0x1
  jmp alltraps
80107ecd:	e9 5e f9 ff ff       	jmp    80107830 <alltraps>

80107ed2 <vector2>:
.globl vector2
vector2:
  pushl $0
80107ed2:	6a 00                	push   $0x0
  pushl $2
80107ed4:	6a 02                	push   $0x2
  jmp alltraps
80107ed6:	e9 55 f9 ff ff       	jmp    80107830 <alltraps>

80107edb <vector3>:
.globl vector3
vector3:
  pushl $0
80107edb:	6a 00                	push   $0x0
  pushl $3
80107edd:	6a 03                	push   $0x3
  jmp alltraps
80107edf:	e9 4c f9 ff ff       	jmp    80107830 <alltraps>

80107ee4 <vector4>:
.globl vector4
vector4:
  pushl $0
80107ee4:	6a 00                	push   $0x0
  pushl $4
80107ee6:	6a 04                	push   $0x4
  jmp alltraps
80107ee8:	e9 43 f9 ff ff       	jmp    80107830 <alltraps>

80107eed <vector5>:
.globl vector5
vector5:
  pushl $0
80107eed:	6a 00                	push   $0x0
  pushl $5
80107eef:	6a 05                	push   $0x5
  jmp alltraps
80107ef1:	e9 3a f9 ff ff       	jmp    80107830 <alltraps>

80107ef6 <vector6>:
.globl vector6
vector6:
  pushl $0
80107ef6:	6a 00                	push   $0x0
  pushl $6
80107ef8:	6a 06                	push   $0x6
  jmp alltraps
80107efa:	e9 31 f9 ff ff       	jmp    80107830 <alltraps>

80107eff <vector7>:
.globl vector7
vector7:
  pushl $0
80107eff:	6a 00                	push   $0x0
  pushl $7
80107f01:	6a 07                	push   $0x7
  jmp alltraps
80107f03:	e9 28 f9 ff ff       	jmp    80107830 <alltraps>

80107f08 <vector8>:
.globl vector8
vector8:
  pushl $8
80107f08:	6a 08                	push   $0x8
  jmp alltraps
80107f0a:	e9 21 f9 ff ff       	jmp    80107830 <alltraps>

80107f0f <vector9>:
.globl vector9
vector9:
  pushl $0
80107f0f:	6a 00                	push   $0x0
  pushl $9
80107f11:	6a 09                	push   $0x9
  jmp alltraps
80107f13:	e9 18 f9 ff ff       	jmp    80107830 <alltraps>

80107f18 <vector10>:
.globl vector10
vector10:
  pushl $10
80107f18:	6a 0a                	push   $0xa
  jmp alltraps
80107f1a:	e9 11 f9 ff ff       	jmp    80107830 <alltraps>

80107f1f <vector11>:
.globl vector11
vector11:
  pushl $11
80107f1f:	6a 0b                	push   $0xb
  jmp alltraps
80107f21:	e9 0a f9 ff ff       	jmp    80107830 <alltraps>

80107f26 <vector12>:
.globl vector12
vector12:
  pushl $12
80107f26:	6a 0c                	push   $0xc
  jmp alltraps
80107f28:	e9 03 f9 ff ff       	jmp    80107830 <alltraps>

80107f2d <vector13>:
.globl vector13
vector13:
  pushl $13
80107f2d:	6a 0d                	push   $0xd
  jmp alltraps
80107f2f:	e9 fc f8 ff ff       	jmp    80107830 <alltraps>

80107f34 <vector14>:
.globl vector14
vector14:
  pushl $14
80107f34:	6a 0e                	push   $0xe
  jmp alltraps
80107f36:	e9 f5 f8 ff ff       	jmp    80107830 <alltraps>

80107f3b <vector15>:
.globl vector15
vector15:
  pushl $0
80107f3b:	6a 00                	push   $0x0
  pushl $15
80107f3d:	6a 0f                	push   $0xf
  jmp alltraps
80107f3f:	e9 ec f8 ff ff       	jmp    80107830 <alltraps>

80107f44 <vector16>:
.globl vector16
vector16:
  pushl $0
80107f44:	6a 00                	push   $0x0
  pushl $16
80107f46:	6a 10                	push   $0x10
  jmp alltraps
80107f48:	e9 e3 f8 ff ff       	jmp    80107830 <alltraps>

80107f4d <vector17>:
.globl vector17
vector17:
  pushl $17
80107f4d:	6a 11                	push   $0x11
  jmp alltraps
80107f4f:	e9 dc f8 ff ff       	jmp    80107830 <alltraps>

80107f54 <vector18>:
.globl vector18
vector18:
  pushl $0
80107f54:	6a 00                	push   $0x0
  pushl $18
80107f56:	6a 12                	push   $0x12
  jmp alltraps
80107f58:	e9 d3 f8 ff ff       	jmp    80107830 <alltraps>

80107f5d <vector19>:
.globl vector19
vector19:
  pushl $0
80107f5d:	6a 00                	push   $0x0
  pushl $19
80107f5f:	6a 13                	push   $0x13
  jmp alltraps
80107f61:	e9 ca f8 ff ff       	jmp    80107830 <alltraps>

80107f66 <vector20>:
.globl vector20
vector20:
  pushl $0
80107f66:	6a 00                	push   $0x0
  pushl $20
80107f68:	6a 14                	push   $0x14
  jmp alltraps
80107f6a:	e9 c1 f8 ff ff       	jmp    80107830 <alltraps>

80107f6f <vector21>:
.globl vector21
vector21:
  pushl $0
80107f6f:	6a 00                	push   $0x0
  pushl $21
80107f71:	6a 15                	push   $0x15
  jmp alltraps
80107f73:	e9 b8 f8 ff ff       	jmp    80107830 <alltraps>

80107f78 <vector22>:
.globl vector22
vector22:
  pushl $0
80107f78:	6a 00                	push   $0x0
  pushl $22
80107f7a:	6a 16                	push   $0x16
  jmp alltraps
80107f7c:	e9 af f8 ff ff       	jmp    80107830 <alltraps>

80107f81 <vector23>:
.globl vector23
vector23:
  pushl $0
80107f81:	6a 00                	push   $0x0
  pushl $23
80107f83:	6a 17                	push   $0x17
  jmp alltraps
80107f85:	e9 a6 f8 ff ff       	jmp    80107830 <alltraps>

80107f8a <vector24>:
.globl vector24
vector24:
  pushl $0
80107f8a:	6a 00                	push   $0x0
  pushl $24
80107f8c:	6a 18                	push   $0x18
  jmp alltraps
80107f8e:	e9 9d f8 ff ff       	jmp    80107830 <alltraps>

80107f93 <vector25>:
.globl vector25
vector25:
  pushl $0
80107f93:	6a 00                	push   $0x0
  pushl $25
80107f95:	6a 19                	push   $0x19
  jmp alltraps
80107f97:	e9 94 f8 ff ff       	jmp    80107830 <alltraps>

80107f9c <vector26>:
.globl vector26
vector26:
  pushl $0
80107f9c:	6a 00                	push   $0x0
  pushl $26
80107f9e:	6a 1a                	push   $0x1a
  jmp alltraps
80107fa0:	e9 8b f8 ff ff       	jmp    80107830 <alltraps>

80107fa5 <vector27>:
.globl vector27
vector27:
  pushl $0
80107fa5:	6a 00                	push   $0x0
  pushl $27
80107fa7:	6a 1b                	push   $0x1b
  jmp alltraps
80107fa9:	e9 82 f8 ff ff       	jmp    80107830 <alltraps>

80107fae <vector28>:
.globl vector28
vector28:
  pushl $0
80107fae:	6a 00                	push   $0x0
  pushl $28
80107fb0:	6a 1c                	push   $0x1c
  jmp alltraps
80107fb2:	e9 79 f8 ff ff       	jmp    80107830 <alltraps>

80107fb7 <vector29>:
.globl vector29
vector29:
  pushl $0
80107fb7:	6a 00                	push   $0x0
  pushl $29
80107fb9:	6a 1d                	push   $0x1d
  jmp alltraps
80107fbb:	e9 70 f8 ff ff       	jmp    80107830 <alltraps>

80107fc0 <vector30>:
.globl vector30
vector30:
  pushl $0
80107fc0:	6a 00                	push   $0x0
  pushl $30
80107fc2:	6a 1e                	push   $0x1e
  jmp alltraps
80107fc4:	e9 67 f8 ff ff       	jmp    80107830 <alltraps>

80107fc9 <vector31>:
.globl vector31
vector31:
  pushl $0
80107fc9:	6a 00                	push   $0x0
  pushl $31
80107fcb:	6a 1f                	push   $0x1f
  jmp alltraps
80107fcd:	e9 5e f8 ff ff       	jmp    80107830 <alltraps>

80107fd2 <vector32>:
.globl vector32
vector32:
  pushl $0
80107fd2:	6a 00                	push   $0x0
  pushl $32
80107fd4:	6a 20                	push   $0x20
  jmp alltraps
80107fd6:	e9 55 f8 ff ff       	jmp    80107830 <alltraps>

80107fdb <vector33>:
.globl vector33
vector33:
  pushl $0
80107fdb:	6a 00                	push   $0x0
  pushl $33
80107fdd:	6a 21                	push   $0x21
  jmp alltraps
80107fdf:	e9 4c f8 ff ff       	jmp    80107830 <alltraps>

80107fe4 <vector34>:
.globl vector34
vector34:
  pushl $0
80107fe4:	6a 00                	push   $0x0
  pushl $34
80107fe6:	6a 22                	push   $0x22
  jmp alltraps
80107fe8:	e9 43 f8 ff ff       	jmp    80107830 <alltraps>

80107fed <vector35>:
.globl vector35
vector35:
  pushl $0
80107fed:	6a 00                	push   $0x0
  pushl $35
80107fef:	6a 23                	push   $0x23
  jmp alltraps
80107ff1:	e9 3a f8 ff ff       	jmp    80107830 <alltraps>

80107ff6 <vector36>:
.globl vector36
vector36:
  pushl $0
80107ff6:	6a 00                	push   $0x0
  pushl $36
80107ff8:	6a 24                	push   $0x24
  jmp alltraps
80107ffa:	e9 31 f8 ff ff       	jmp    80107830 <alltraps>

80107fff <vector37>:
.globl vector37
vector37:
  pushl $0
80107fff:	6a 00                	push   $0x0
  pushl $37
80108001:	6a 25                	push   $0x25
  jmp alltraps
80108003:	e9 28 f8 ff ff       	jmp    80107830 <alltraps>

80108008 <vector38>:
.globl vector38
vector38:
  pushl $0
80108008:	6a 00                	push   $0x0
  pushl $38
8010800a:	6a 26                	push   $0x26
  jmp alltraps
8010800c:	e9 1f f8 ff ff       	jmp    80107830 <alltraps>

80108011 <vector39>:
.globl vector39
vector39:
  pushl $0
80108011:	6a 00                	push   $0x0
  pushl $39
80108013:	6a 27                	push   $0x27
  jmp alltraps
80108015:	e9 16 f8 ff ff       	jmp    80107830 <alltraps>

8010801a <vector40>:
.globl vector40
vector40:
  pushl $0
8010801a:	6a 00                	push   $0x0
  pushl $40
8010801c:	6a 28                	push   $0x28
  jmp alltraps
8010801e:	e9 0d f8 ff ff       	jmp    80107830 <alltraps>

80108023 <vector41>:
.globl vector41
vector41:
  pushl $0
80108023:	6a 00                	push   $0x0
  pushl $41
80108025:	6a 29                	push   $0x29
  jmp alltraps
80108027:	e9 04 f8 ff ff       	jmp    80107830 <alltraps>

8010802c <vector42>:
.globl vector42
vector42:
  pushl $0
8010802c:	6a 00                	push   $0x0
  pushl $42
8010802e:	6a 2a                	push   $0x2a
  jmp alltraps
80108030:	e9 fb f7 ff ff       	jmp    80107830 <alltraps>

80108035 <vector43>:
.globl vector43
vector43:
  pushl $0
80108035:	6a 00                	push   $0x0
  pushl $43
80108037:	6a 2b                	push   $0x2b
  jmp alltraps
80108039:	e9 f2 f7 ff ff       	jmp    80107830 <alltraps>

8010803e <vector44>:
.globl vector44
vector44:
  pushl $0
8010803e:	6a 00                	push   $0x0
  pushl $44
80108040:	6a 2c                	push   $0x2c
  jmp alltraps
80108042:	e9 e9 f7 ff ff       	jmp    80107830 <alltraps>

80108047 <vector45>:
.globl vector45
vector45:
  pushl $0
80108047:	6a 00                	push   $0x0
  pushl $45
80108049:	6a 2d                	push   $0x2d
  jmp alltraps
8010804b:	e9 e0 f7 ff ff       	jmp    80107830 <alltraps>

80108050 <vector46>:
.globl vector46
vector46:
  pushl $0
80108050:	6a 00                	push   $0x0
  pushl $46
80108052:	6a 2e                	push   $0x2e
  jmp alltraps
80108054:	e9 d7 f7 ff ff       	jmp    80107830 <alltraps>

80108059 <vector47>:
.globl vector47
vector47:
  pushl $0
80108059:	6a 00                	push   $0x0
  pushl $47
8010805b:	6a 2f                	push   $0x2f
  jmp alltraps
8010805d:	e9 ce f7 ff ff       	jmp    80107830 <alltraps>

80108062 <vector48>:
.globl vector48
vector48:
  pushl $0
80108062:	6a 00                	push   $0x0
  pushl $48
80108064:	6a 30                	push   $0x30
  jmp alltraps
80108066:	e9 c5 f7 ff ff       	jmp    80107830 <alltraps>

8010806b <vector49>:
.globl vector49
vector49:
  pushl $0
8010806b:	6a 00                	push   $0x0
  pushl $49
8010806d:	6a 31                	push   $0x31
  jmp alltraps
8010806f:	e9 bc f7 ff ff       	jmp    80107830 <alltraps>

80108074 <vector50>:
.globl vector50
vector50:
  pushl $0
80108074:	6a 00                	push   $0x0
  pushl $50
80108076:	6a 32                	push   $0x32
  jmp alltraps
80108078:	e9 b3 f7 ff ff       	jmp    80107830 <alltraps>

8010807d <vector51>:
.globl vector51
vector51:
  pushl $0
8010807d:	6a 00                	push   $0x0
  pushl $51
8010807f:	6a 33                	push   $0x33
  jmp alltraps
80108081:	e9 aa f7 ff ff       	jmp    80107830 <alltraps>

80108086 <vector52>:
.globl vector52
vector52:
  pushl $0
80108086:	6a 00                	push   $0x0
  pushl $52
80108088:	6a 34                	push   $0x34
  jmp alltraps
8010808a:	e9 a1 f7 ff ff       	jmp    80107830 <alltraps>

8010808f <vector53>:
.globl vector53
vector53:
  pushl $0
8010808f:	6a 00                	push   $0x0
  pushl $53
80108091:	6a 35                	push   $0x35
  jmp alltraps
80108093:	e9 98 f7 ff ff       	jmp    80107830 <alltraps>

80108098 <vector54>:
.globl vector54
vector54:
  pushl $0
80108098:	6a 00                	push   $0x0
  pushl $54
8010809a:	6a 36                	push   $0x36
  jmp alltraps
8010809c:	e9 8f f7 ff ff       	jmp    80107830 <alltraps>

801080a1 <vector55>:
.globl vector55
vector55:
  pushl $0
801080a1:	6a 00                	push   $0x0
  pushl $55
801080a3:	6a 37                	push   $0x37
  jmp alltraps
801080a5:	e9 86 f7 ff ff       	jmp    80107830 <alltraps>

801080aa <vector56>:
.globl vector56
vector56:
  pushl $0
801080aa:	6a 00                	push   $0x0
  pushl $56
801080ac:	6a 38                	push   $0x38
  jmp alltraps
801080ae:	e9 7d f7 ff ff       	jmp    80107830 <alltraps>

801080b3 <vector57>:
.globl vector57
vector57:
  pushl $0
801080b3:	6a 00                	push   $0x0
  pushl $57
801080b5:	6a 39                	push   $0x39
  jmp alltraps
801080b7:	e9 74 f7 ff ff       	jmp    80107830 <alltraps>

801080bc <vector58>:
.globl vector58
vector58:
  pushl $0
801080bc:	6a 00                	push   $0x0
  pushl $58
801080be:	6a 3a                	push   $0x3a
  jmp alltraps
801080c0:	e9 6b f7 ff ff       	jmp    80107830 <alltraps>

801080c5 <vector59>:
.globl vector59
vector59:
  pushl $0
801080c5:	6a 00                	push   $0x0
  pushl $59
801080c7:	6a 3b                	push   $0x3b
  jmp alltraps
801080c9:	e9 62 f7 ff ff       	jmp    80107830 <alltraps>

801080ce <vector60>:
.globl vector60
vector60:
  pushl $0
801080ce:	6a 00                	push   $0x0
  pushl $60
801080d0:	6a 3c                	push   $0x3c
  jmp alltraps
801080d2:	e9 59 f7 ff ff       	jmp    80107830 <alltraps>

801080d7 <vector61>:
.globl vector61
vector61:
  pushl $0
801080d7:	6a 00                	push   $0x0
  pushl $61
801080d9:	6a 3d                	push   $0x3d
  jmp alltraps
801080db:	e9 50 f7 ff ff       	jmp    80107830 <alltraps>

801080e0 <vector62>:
.globl vector62
vector62:
  pushl $0
801080e0:	6a 00                	push   $0x0
  pushl $62
801080e2:	6a 3e                	push   $0x3e
  jmp alltraps
801080e4:	e9 47 f7 ff ff       	jmp    80107830 <alltraps>

801080e9 <vector63>:
.globl vector63
vector63:
  pushl $0
801080e9:	6a 00                	push   $0x0
  pushl $63
801080eb:	6a 3f                	push   $0x3f
  jmp alltraps
801080ed:	e9 3e f7 ff ff       	jmp    80107830 <alltraps>

801080f2 <vector64>:
.globl vector64
vector64:
  pushl $0
801080f2:	6a 00                	push   $0x0
  pushl $64
801080f4:	6a 40                	push   $0x40
  jmp alltraps
801080f6:	e9 35 f7 ff ff       	jmp    80107830 <alltraps>

801080fb <vector65>:
.globl vector65
vector65:
  pushl $0
801080fb:	6a 00                	push   $0x0
  pushl $65
801080fd:	6a 41                	push   $0x41
  jmp alltraps
801080ff:	e9 2c f7 ff ff       	jmp    80107830 <alltraps>

80108104 <vector66>:
.globl vector66
vector66:
  pushl $0
80108104:	6a 00                	push   $0x0
  pushl $66
80108106:	6a 42                	push   $0x42
  jmp alltraps
80108108:	e9 23 f7 ff ff       	jmp    80107830 <alltraps>

8010810d <vector67>:
.globl vector67
vector67:
  pushl $0
8010810d:	6a 00                	push   $0x0
  pushl $67
8010810f:	6a 43                	push   $0x43
  jmp alltraps
80108111:	e9 1a f7 ff ff       	jmp    80107830 <alltraps>

80108116 <vector68>:
.globl vector68
vector68:
  pushl $0
80108116:	6a 00                	push   $0x0
  pushl $68
80108118:	6a 44                	push   $0x44
  jmp alltraps
8010811a:	e9 11 f7 ff ff       	jmp    80107830 <alltraps>

8010811f <vector69>:
.globl vector69
vector69:
  pushl $0
8010811f:	6a 00                	push   $0x0
  pushl $69
80108121:	6a 45                	push   $0x45
  jmp alltraps
80108123:	e9 08 f7 ff ff       	jmp    80107830 <alltraps>

80108128 <vector70>:
.globl vector70
vector70:
  pushl $0
80108128:	6a 00                	push   $0x0
  pushl $70
8010812a:	6a 46                	push   $0x46
  jmp alltraps
8010812c:	e9 ff f6 ff ff       	jmp    80107830 <alltraps>

80108131 <vector71>:
.globl vector71
vector71:
  pushl $0
80108131:	6a 00                	push   $0x0
  pushl $71
80108133:	6a 47                	push   $0x47
  jmp alltraps
80108135:	e9 f6 f6 ff ff       	jmp    80107830 <alltraps>

8010813a <vector72>:
.globl vector72
vector72:
  pushl $0
8010813a:	6a 00                	push   $0x0
  pushl $72
8010813c:	6a 48                	push   $0x48
  jmp alltraps
8010813e:	e9 ed f6 ff ff       	jmp    80107830 <alltraps>

80108143 <vector73>:
.globl vector73
vector73:
  pushl $0
80108143:	6a 00                	push   $0x0
  pushl $73
80108145:	6a 49                	push   $0x49
  jmp alltraps
80108147:	e9 e4 f6 ff ff       	jmp    80107830 <alltraps>

8010814c <vector74>:
.globl vector74
vector74:
  pushl $0
8010814c:	6a 00                	push   $0x0
  pushl $74
8010814e:	6a 4a                	push   $0x4a
  jmp alltraps
80108150:	e9 db f6 ff ff       	jmp    80107830 <alltraps>

80108155 <vector75>:
.globl vector75
vector75:
  pushl $0
80108155:	6a 00                	push   $0x0
  pushl $75
80108157:	6a 4b                	push   $0x4b
  jmp alltraps
80108159:	e9 d2 f6 ff ff       	jmp    80107830 <alltraps>

8010815e <vector76>:
.globl vector76
vector76:
  pushl $0
8010815e:	6a 00                	push   $0x0
  pushl $76
80108160:	6a 4c                	push   $0x4c
  jmp alltraps
80108162:	e9 c9 f6 ff ff       	jmp    80107830 <alltraps>

80108167 <vector77>:
.globl vector77
vector77:
  pushl $0
80108167:	6a 00                	push   $0x0
  pushl $77
80108169:	6a 4d                	push   $0x4d
  jmp alltraps
8010816b:	e9 c0 f6 ff ff       	jmp    80107830 <alltraps>

80108170 <vector78>:
.globl vector78
vector78:
  pushl $0
80108170:	6a 00                	push   $0x0
  pushl $78
80108172:	6a 4e                	push   $0x4e
  jmp alltraps
80108174:	e9 b7 f6 ff ff       	jmp    80107830 <alltraps>

80108179 <vector79>:
.globl vector79
vector79:
  pushl $0
80108179:	6a 00                	push   $0x0
  pushl $79
8010817b:	6a 4f                	push   $0x4f
  jmp alltraps
8010817d:	e9 ae f6 ff ff       	jmp    80107830 <alltraps>

80108182 <vector80>:
.globl vector80
vector80:
  pushl $0
80108182:	6a 00                	push   $0x0
  pushl $80
80108184:	6a 50                	push   $0x50
  jmp alltraps
80108186:	e9 a5 f6 ff ff       	jmp    80107830 <alltraps>

8010818b <vector81>:
.globl vector81
vector81:
  pushl $0
8010818b:	6a 00                	push   $0x0
  pushl $81
8010818d:	6a 51                	push   $0x51
  jmp alltraps
8010818f:	e9 9c f6 ff ff       	jmp    80107830 <alltraps>

80108194 <vector82>:
.globl vector82
vector82:
  pushl $0
80108194:	6a 00                	push   $0x0
  pushl $82
80108196:	6a 52                	push   $0x52
  jmp alltraps
80108198:	e9 93 f6 ff ff       	jmp    80107830 <alltraps>

8010819d <vector83>:
.globl vector83
vector83:
  pushl $0
8010819d:	6a 00                	push   $0x0
  pushl $83
8010819f:	6a 53                	push   $0x53
  jmp alltraps
801081a1:	e9 8a f6 ff ff       	jmp    80107830 <alltraps>

801081a6 <vector84>:
.globl vector84
vector84:
  pushl $0
801081a6:	6a 00                	push   $0x0
  pushl $84
801081a8:	6a 54                	push   $0x54
  jmp alltraps
801081aa:	e9 81 f6 ff ff       	jmp    80107830 <alltraps>

801081af <vector85>:
.globl vector85
vector85:
  pushl $0
801081af:	6a 00                	push   $0x0
  pushl $85
801081b1:	6a 55                	push   $0x55
  jmp alltraps
801081b3:	e9 78 f6 ff ff       	jmp    80107830 <alltraps>

801081b8 <vector86>:
.globl vector86
vector86:
  pushl $0
801081b8:	6a 00                	push   $0x0
  pushl $86
801081ba:	6a 56                	push   $0x56
  jmp alltraps
801081bc:	e9 6f f6 ff ff       	jmp    80107830 <alltraps>

801081c1 <vector87>:
.globl vector87
vector87:
  pushl $0
801081c1:	6a 00                	push   $0x0
  pushl $87
801081c3:	6a 57                	push   $0x57
  jmp alltraps
801081c5:	e9 66 f6 ff ff       	jmp    80107830 <alltraps>

801081ca <vector88>:
.globl vector88
vector88:
  pushl $0
801081ca:	6a 00                	push   $0x0
  pushl $88
801081cc:	6a 58                	push   $0x58
  jmp alltraps
801081ce:	e9 5d f6 ff ff       	jmp    80107830 <alltraps>

801081d3 <vector89>:
.globl vector89
vector89:
  pushl $0
801081d3:	6a 00                	push   $0x0
  pushl $89
801081d5:	6a 59                	push   $0x59
  jmp alltraps
801081d7:	e9 54 f6 ff ff       	jmp    80107830 <alltraps>

801081dc <vector90>:
.globl vector90
vector90:
  pushl $0
801081dc:	6a 00                	push   $0x0
  pushl $90
801081de:	6a 5a                	push   $0x5a
  jmp alltraps
801081e0:	e9 4b f6 ff ff       	jmp    80107830 <alltraps>

801081e5 <vector91>:
.globl vector91
vector91:
  pushl $0
801081e5:	6a 00                	push   $0x0
  pushl $91
801081e7:	6a 5b                	push   $0x5b
  jmp alltraps
801081e9:	e9 42 f6 ff ff       	jmp    80107830 <alltraps>

801081ee <vector92>:
.globl vector92
vector92:
  pushl $0
801081ee:	6a 00                	push   $0x0
  pushl $92
801081f0:	6a 5c                	push   $0x5c
  jmp alltraps
801081f2:	e9 39 f6 ff ff       	jmp    80107830 <alltraps>

801081f7 <vector93>:
.globl vector93
vector93:
  pushl $0
801081f7:	6a 00                	push   $0x0
  pushl $93
801081f9:	6a 5d                	push   $0x5d
  jmp alltraps
801081fb:	e9 30 f6 ff ff       	jmp    80107830 <alltraps>

80108200 <vector94>:
.globl vector94
vector94:
  pushl $0
80108200:	6a 00                	push   $0x0
  pushl $94
80108202:	6a 5e                	push   $0x5e
  jmp alltraps
80108204:	e9 27 f6 ff ff       	jmp    80107830 <alltraps>

80108209 <vector95>:
.globl vector95
vector95:
  pushl $0
80108209:	6a 00                	push   $0x0
  pushl $95
8010820b:	6a 5f                	push   $0x5f
  jmp alltraps
8010820d:	e9 1e f6 ff ff       	jmp    80107830 <alltraps>

80108212 <vector96>:
.globl vector96
vector96:
  pushl $0
80108212:	6a 00                	push   $0x0
  pushl $96
80108214:	6a 60                	push   $0x60
  jmp alltraps
80108216:	e9 15 f6 ff ff       	jmp    80107830 <alltraps>

8010821b <vector97>:
.globl vector97
vector97:
  pushl $0
8010821b:	6a 00                	push   $0x0
  pushl $97
8010821d:	6a 61                	push   $0x61
  jmp alltraps
8010821f:	e9 0c f6 ff ff       	jmp    80107830 <alltraps>

80108224 <vector98>:
.globl vector98
vector98:
  pushl $0
80108224:	6a 00                	push   $0x0
  pushl $98
80108226:	6a 62                	push   $0x62
  jmp alltraps
80108228:	e9 03 f6 ff ff       	jmp    80107830 <alltraps>

8010822d <vector99>:
.globl vector99
vector99:
  pushl $0
8010822d:	6a 00                	push   $0x0
  pushl $99
8010822f:	6a 63                	push   $0x63
  jmp alltraps
80108231:	e9 fa f5 ff ff       	jmp    80107830 <alltraps>

80108236 <vector100>:
.globl vector100
vector100:
  pushl $0
80108236:	6a 00                	push   $0x0
  pushl $100
80108238:	6a 64                	push   $0x64
  jmp alltraps
8010823a:	e9 f1 f5 ff ff       	jmp    80107830 <alltraps>

8010823f <vector101>:
.globl vector101
vector101:
  pushl $0
8010823f:	6a 00                	push   $0x0
  pushl $101
80108241:	6a 65                	push   $0x65
  jmp alltraps
80108243:	e9 e8 f5 ff ff       	jmp    80107830 <alltraps>

80108248 <vector102>:
.globl vector102
vector102:
  pushl $0
80108248:	6a 00                	push   $0x0
  pushl $102
8010824a:	6a 66                	push   $0x66
  jmp alltraps
8010824c:	e9 df f5 ff ff       	jmp    80107830 <alltraps>

80108251 <vector103>:
.globl vector103
vector103:
  pushl $0
80108251:	6a 00                	push   $0x0
  pushl $103
80108253:	6a 67                	push   $0x67
  jmp alltraps
80108255:	e9 d6 f5 ff ff       	jmp    80107830 <alltraps>

8010825a <vector104>:
.globl vector104
vector104:
  pushl $0
8010825a:	6a 00                	push   $0x0
  pushl $104
8010825c:	6a 68                	push   $0x68
  jmp alltraps
8010825e:	e9 cd f5 ff ff       	jmp    80107830 <alltraps>

80108263 <vector105>:
.globl vector105
vector105:
  pushl $0
80108263:	6a 00                	push   $0x0
  pushl $105
80108265:	6a 69                	push   $0x69
  jmp alltraps
80108267:	e9 c4 f5 ff ff       	jmp    80107830 <alltraps>

8010826c <vector106>:
.globl vector106
vector106:
  pushl $0
8010826c:	6a 00                	push   $0x0
  pushl $106
8010826e:	6a 6a                	push   $0x6a
  jmp alltraps
80108270:	e9 bb f5 ff ff       	jmp    80107830 <alltraps>

80108275 <vector107>:
.globl vector107
vector107:
  pushl $0
80108275:	6a 00                	push   $0x0
  pushl $107
80108277:	6a 6b                	push   $0x6b
  jmp alltraps
80108279:	e9 b2 f5 ff ff       	jmp    80107830 <alltraps>

8010827e <vector108>:
.globl vector108
vector108:
  pushl $0
8010827e:	6a 00                	push   $0x0
  pushl $108
80108280:	6a 6c                	push   $0x6c
  jmp alltraps
80108282:	e9 a9 f5 ff ff       	jmp    80107830 <alltraps>

80108287 <vector109>:
.globl vector109
vector109:
  pushl $0
80108287:	6a 00                	push   $0x0
  pushl $109
80108289:	6a 6d                	push   $0x6d
  jmp alltraps
8010828b:	e9 a0 f5 ff ff       	jmp    80107830 <alltraps>

80108290 <vector110>:
.globl vector110
vector110:
  pushl $0
80108290:	6a 00                	push   $0x0
  pushl $110
80108292:	6a 6e                	push   $0x6e
  jmp alltraps
80108294:	e9 97 f5 ff ff       	jmp    80107830 <alltraps>

80108299 <vector111>:
.globl vector111
vector111:
  pushl $0
80108299:	6a 00                	push   $0x0
  pushl $111
8010829b:	6a 6f                	push   $0x6f
  jmp alltraps
8010829d:	e9 8e f5 ff ff       	jmp    80107830 <alltraps>

801082a2 <vector112>:
.globl vector112
vector112:
  pushl $0
801082a2:	6a 00                	push   $0x0
  pushl $112
801082a4:	6a 70                	push   $0x70
  jmp alltraps
801082a6:	e9 85 f5 ff ff       	jmp    80107830 <alltraps>

801082ab <vector113>:
.globl vector113
vector113:
  pushl $0
801082ab:	6a 00                	push   $0x0
  pushl $113
801082ad:	6a 71                	push   $0x71
  jmp alltraps
801082af:	e9 7c f5 ff ff       	jmp    80107830 <alltraps>

801082b4 <vector114>:
.globl vector114
vector114:
  pushl $0
801082b4:	6a 00                	push   $0x0
  pushl $114
801082b6:	6a 72                	push   $0x72
  jmp alltraps
801082b8:	e9 73 f5 ff ff       	jmp    80107830 <alltraps>

801082bd <vector115>:
.globl vector115
vector115:
  pushl $0
801082bd:	6a 00                	push   $0x0
  pushl $115
801082bf:	6a 73                	push   $0x73
  jmp alltraps
801082c1:	e9 6a f5 ff ff       	jmp    80107830 <alltraps>

801082c6 <vector116>:
.globl vector116
vector116:
  pushl $0
801082c6:	6a 00                	push   $0x0
  pushl $116
801082c8:	6a 74                	push   $0x74
  jmp alltraps
801082ca:	e9 61 f5 ff ff       	jmp    80107830 <alltraps>

801082cf <vector117>:
.globl vector117
vector117:
  pushl $0
801082cf:	6a 00                	push   $0x0
  pushl $117
801082d1:	6a 75                	push   $0x75
  jmp alltraps
801082d3:	e9 58 f5 ff ff       	jmp    80107830 <alltraps>

801082d8 <vector118>:
.globl vector118
vector118:
  pushl $0
801082d8:	6a 00                	push   $0x0
  pushl $118
801082da:	6a 76                	push   $0x76
  jmp alltraps
801082dc:	e9 4f f5 ff ff       	jmp    80107830 <alltraps>

801082e1 <vector119>:
.globl vector119
vector119:
  pushl $0
801082e1:	6a 00                	push   $0x0
  pushl $119
801082e3:	6a 77                	push   $0x77
  jmp alltraps
801082e5:	e9 46 f5 ff ff       	jmp    80107830 <alltraps>

801082ea <vector120>:
.globl vector120
vector120:
  pushl $0
801082ea:	6a 00                	push   $0x0
  pushl $120
801082ec:	6a 78                	push   $0x78
  jmp alltraps
801082ee:	e9 3d f5 ff ff       	jmp    80107830 <alltraps>

801082f3 <vector121>:
.globl vector121
vector121:
  pushl $0
801082f3:	6a 00                	push   $0x0
  pushl $121
801082f5:	6a 79                	push   $0x79
  jmp alltraps
801082f7:	e9 34 f5 ff ff       	jmp    80107830 <alltraps>

801082fc <vector122>:
.globl vector122
vector122:
  pushl $0
801082fc:	6a 00                	push   $0x0
  pushl $122
801082fe:	6a 7a                	push   $0x7a
  jmp alltraps
80108300:	e9 2b f5 ff ff       	jmp    80107830 <alltraps>

80108305 <vector123>:
.globl vector123
vector123:
  pushl $0
80108305:	6a 00                	push   $0x0
  pushl $123
80108307:	6a 7b                	push   $0x7b
  jmp alltraps
80108309:	e9 22 f5 ff ff       	jmp    80107830 <alltraps>

8010830e <vector124>:
.globl vector124
vector124:
  pushl $0
8010830e:	6a 00                	push   $0x0
  pushl $124
80108310:	6a 7c                	push   $0x7c
  jmp alltraps
80108312:	e9 19 f5 ff ff       	jmp    80107830 <alltraps>

80108317 <vector125>:
.globl vector125
vector125:
  pushl $0
80108317:	6a 00                	push   $0x0
  pushl $125
80108319:	6a 7d                	push   $0x7d
  jmp alltraps
8010831b:	e9 10 f5 ff ff       	jmp    80107830 <alltraps>

80108320 <vector126>:
.globl vector126
vector126:
  pushl $0
80108320:	6a 00                	push   $0x0
  pushl $126
80108322:	6a 7e                	push   $0x7e
  jmp alltraps
80108324:	e9 07 f5 ff ff       	jmp    80107830 <alltraps>

80108329 <vector127>:
.globl vector127
vector127:
  pushl $0
80108329:	6a 00                	push   $0x0
  pushl $127
8010832b:	6a 7f                	push   $0x7f
  jmp alltraps
8010832d:	e9 fe f4 ff ff       	jmp    80107830 <alltraps>

80108332 <vector128>:
.globl vector128
vector128:
  pushl $0
80108332:	6a 00                	push   $0x0
  pushl $128
80108334:	68 80 00 00 00       	push   $0x80
  jmp alltraps
80108339:	e9 f2 f4 ff ff       	jmp    80107830 <alltraps>

8010833e <vector129>:
.globl vector129
vector129:
  pushl $0
8010833e:	6a 00                	push   $0x0
  pushl $129
80108340:	68 81 00 00 00       	push   $0x81
  jmp alltraps
80108345:	e9 e6 f4 ff ff       	jmp    80107830 <alltraps>

8010834a <vector130>:
.globl vector130
vector130:
  pushl $0
8010834a:	6a 00                	push   $0x0
  pushl $130
8010834c:	68 82 00 00 00       	push   $0x82
  jmp alltraps
80108351:	e9 da f4 ff ff       	jmp    80107830 <alltraps>

80108356 <vector131>:
.globl vector131
vector131:
  pushl $0
80108356:	6a 00                	push   $0x0
  pushl $131
80108358:	68 83 00 00 00       	push   $0x83
  jmp alltraps
8010835d:	e9 ce f4 ff ff       	jmp    80107830 <alltraps>

80108362 <vector132>:
.globl vector132
vector132:
  pushl $0
80108362:	6a 00                	push   $0x0
  pushl $132
80108364:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80108369:	e9 c2 f4 ff ff       	jmp    80107830 <alltraps>

8010836e <vector133>:
.globl vector133
vector133:
  pushl $0
8010836e:	6a 00                	push   $0x0
  pushl $133
80108370:	68 85 00 00 00       	push   $0x85
  jmp alltraps
80108375:	e9 b6 f4 ff ff       	jmp    80107830 <alltraps>

8010837a <vector134>:
.globl vector134
vector134:
  pushl $0
8010837a:	6a 00                	push   $0x0
  pushl $134
8010837c:	68 86 00 00 00       	push   $0x86
  jmp alltraps
80108381:	e9 aa f4 ff ff       	jmp    80107830 <alltraps>

80108386 <vector135>:
.globl vector135
vector135:
  pushl $0
80108386:	6a 00                	push   $0x0
  pushl $135
80108388:	68 87 00 00 00       	push   $0x87
  jmp alltraps
8010838d:	e9 9e f4 ff ff       	jmp    80107830 <alltraps>

80108392 <vector136>:
.globl vector136
vector136:
  pushl $0
80108392:	6a 00                	push   $0x0
  pushl $136
80108394:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80108399:	e9 92 f4 ff ff       	jmp    80107830 <alltraps>

8010839e <vector137>:
.globl vector137
vector137:
  pushl $0
8010839e:	6a 00                	push   $0x0
  pushl $137
801083a0:	68 89 00 00 00       	push   $0x89
  jmp alltraps
801083a5:	e9 86 f4 ff ff       	jmp    80107830 <alltraps>

801083aa <vector138>:
.globl vector138
vector138:
  pushl $0
801083aa:	6a 00                	push   $0x0
  pushl $138
801083ac:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
801083b1:	e9 7a f4 ff ff       	jmp    80107830 <alltraps>

801083b6 <vector139>:
.globl vector139
vector139:
  pushl $0
801083b6:	6a 00                	push   $0x0
  pushl $139
801083b8:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
801083bd:	e9 6e f4 ff ff       	jmp    80107830 <alltraps>

801083c2 <vector140>:
.globl vector140
vector140:
  pushl $0
801083c2:	6a 00                	push   $0x0
  pushl $140
801083c4:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
801083c9:	e9 62 f4 ff ff       	jmp    80107830 <alltraps>

801083ce <vector141>:
.globl vector141
vector141:
  pushl $0
801083ce:	6a 00                	push   $0x0
  pushl $141
801083d0:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
801083d5:	e9 56 f4 ff ff       	jmp    80107830 <alltraps>

801083da <vector142>:
.globl vector142
vector142:
  pushl $0
801083da:	6a 00                	push   $0x0
  pushl $142
801083dc:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
801083e1:	e9 4a f4 ff ff       	jmp    80107830 <alltraps>

801083e6 <vector143>:
.globl vector143
vector143:
  pushl $0
801083e6:	6a 00                	push   $0x0
  pushl $143
801083e8:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
801083ed:	e9 3e f4 ff ff       	jmp    80107830 <alltraps>

801083f2 <vector144>:
.globl vector144
vector144:
  pushl $0
801083f2:	6a 00                	push   $0x0
  pushl $144
801083f4:	68 90 00 00 00       	push   $0x90
  jmp alltraps
801083f9:	e9 32 f4 ff ff       	jmp    80107830 <alltraps>

801083fe <vector145>:
.globl vector145
vector145:
  pushl $0
801083fe:	6a 00                	push   $0x0
  pushl $145
80108400:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80108405:	e9 26 f4 ff ff       	jmp    80107830 <alltraps>

8010840a <vector146>:
.globl vector146
vector146:
  pushl $0
8010840a:	6a 00                	push   $0x0
  pushl $146
8010840c:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80108411:	e9 1a f4 ff ff       	jmp    80107830 <alltraps>

80108416 <vector147>:
.globl vector147
vector147:
  pushl $0
80108416:	6a 00                	push   $0x0
  pushl $147
80108418:	68 93 00 00 00       	push   $0x93
  jmp alltraps
8010841d:	e9 0e f4 ff ff       	jmp    80107830 <alltraps>

80108422 <vector148>:
.globl vector148
vector148:
  pushl $0
80108422:	6a 00                	push   $0x0
  pushl $148
80108424:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80108429:	e9 02 f4 ff ff       	jmp    80107830 <alltraps>

8010842e <vector149>:
.globl vector149
vector149:
  pushl $0
8010842e:	6a 00                	push   $0x0
  pushl $149
80108430:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80108435:	e9 f6 f3 ff ff       	jmp    80107830 <alltraps>

8010843a <vector150>:
.globl vector150
vector150:
  pushl $0
8010843a:	6a 00                	push   $0x0
  pushl $150
8010843c:	68 96 00 00 00       	push   $0x96
  jmp alltraps
80108441:	e9 ea f3 ff ff       	jmp    80107830 <alltraps>

80108446 <vector151>:
.globl vector151
vector151:
  pushl $0
80108446:	6a 00                	push   $0x0
  pushl $151
80108448:	68 97 00 00 00       	push   $0x97
  jmp alltraps
8010844d:	e9 de f3 ff ff       	jmp    80107830 <alltraps>

80108452 <vector152>:
.globl vector152
vector152:
  pushl $0
80108452:	6a 00                	push   $0x0
  pushl $152
80108454:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80108459:	e9 d2 f3 ff ff       	jmp    80107830 <alltraps>

8010845e <vector153>:
.globl vector153
vector153:
  pushl $0
8010845e:	6a 00                	push   $0x0
  pushl $153
80108460:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80108465:	e9 c6 f3 ff ff       	jmp    80107830 <alltraps>

8010846a <vector154>:
.globl vector154
vector154:
  pushl $0
8010846a:	6a 00                	push   $0x0
  pushl $154
8010846c:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80108471:	e9 ba f3 ff ff       	jmp    80107830 <alltraps>

80108476 <vector155>:
.globl vector155
vector155:
  pushl $0
80108476:	6a 00                	push   $0x0
  pushl $155
80108478:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
8010847d:	e9 ae f3 ff ff       	jmp    80107830 <alltraps>

80108482 <vector156>:
.globl vector156
vector156:
  pushl $0
80108482:	6a 00                	push   $0x0
  pushl $156
80108484:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80108489:	e9 a2 f3 ff ff       	jmp    80107830 <alltraps>

8010848e <vector157>:
.globl vector157
vector157:
  pushl $0
8010848e:	6a 00                	push   $0x0
  pushl $157
80108490:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80108495:	e9 96 f3 ff ff       	jmp    80107830 <alltraps>

8010849a <vector158>:
.globl vector158
vector158:
  pushl $0
8010849a:	6a 00                	push   $0x0
  pushl $158
8010849c:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
801084a1:	e9 8a f3 ff ff       	jmp    80107830 <alltraps>

801084a6 <vector159>:
.globl vector159
vector159:
  pushl $0
801084a6:	6a 00                	push   $0x0
  pushl $159
801084a8:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
801084ad:	e9 7e f3 ff ff       	jmp    80107830 <alltraps>

801084b2 <vector160>:
.globl vector160
vector160:
  pushl $0
801084b2:	6a 00                	push   $0x0
  pushl $160
801084b4:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
801084b9:	e9 72 f3 ff ff       	jmp    80107830 <alltraps>

801084be <vector161>:
.globl vector161
vector161:
  pushl $0
801084be:	6a 00                	push   $0x0
  pushl $161
801084c0:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
801084c5:	e9 66 f3 ff ff       	jmp    80107830 <alltraps>

801084ca <vector162>:
.globl vector162
vector162:
  pushl $0
801084ca:	6a 00                	push   $0x0
  pushl $162
801084cc:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
801084d1:	e9 5a f3 ff ff       	jmp    80107830 <alltraps>

801084d6 <vector163>:
.globl vector163
vector163:
  pushl $0
801084d6:	6a 00                	push   $0x0
  pushl $163
801084d8:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
801084dd:	e9 4e f3 ff ff       	jmp    80107830 <alltraps>

801084e2 <vector164>:
.globl vector164
vector164:
  pushl $0
801084e2:	6a 00                	push   $0x0
  pushl $164
801084e4:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
801084e9:	e9 42 f3 ff ff       	jmp    80107830 <alltraps>

801084ee <vector165>:
.globl vector165
vector165:
  pushl $0
801084ee:	6a 00                	push   $0x0
  pushl $165
801084f0:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
801084f5:	e9 36 f3 ff ff       	jmp    80107830 <alltraps>

801084fa <vector166>:
.globl vector166
vector166:
  pushl $0
801084fa:	6a 00                	push   $0x0
  pushl $166
801084fc:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80108501:	e9 2a f3 ff ff       	jmp    80107830 <alltraps>

80108506 <vector167>:
.globl vector167
vector167:
  pushl $0
80108506:	6a 00                	push   $0x0
  pushl $167
80108508:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
8010850d:	e9 1e f3 ff ff       	jmp    80107830 <alltraps>

80108512 <vector168>:
.globl vector168
vector168:
  pushl $0
80108512:	6a 00                	push   $0x0
  pushl $168
80108514:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80108519:	e9 12 f3 ff ff       	jmp    80107830 <alltraps>

8010851e <vector169>:
.globl vector169
vector169:
  pushl $0
8010851e:	6a 00                	push   $0x0
  pushl $169
80108520:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80108525:	e9 06 f3 ff ff       	jmp    80107830 <alltraps>

8010852a <vector170>:
.globl vector170
vector170:
  pushl $0
8010852a:	6a 00                	push   $0x0
  pushl $170
8010852c:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80108531:	e9 fa f2 ff ff       	jmp    80107830 <alltraps>

80108536 <vector171>:
.globl vector171
vector171:
  pushl $0
80108536:	6a 00                	push   $0x0
  pushl $171
80108538:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
8010853d:	e9 ee f2 ff ff       	jmp    80107830 <alltraps>

80108542 <vector172>:
.globl vector172
vector172:
  pushl $0
80108542:	6a 00                	push   $0x0
  pushl $172
80108544:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80108549:	e9 e2 f2 ff ff       	jmp    80107830 <alltraps>

8010854e <vector173>:
.globl vector173
vector173:
  pushl $0
8010854e:	6a 00                	push   $0x0
  pushl $173
80108550:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80108555:	e9 d6 f2 ff ff       	jmp    80107830 <alltraps>

8010855a <vector174>:
.globl vector174
vector174:
  pushl $0
8010855a:	6a 00                	push   $0x0
  pushl $174
8010855c:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80108561:	e9 ca f2 ff ff       	jmp    80107830 <alltraps>

80108566 <vector175>:
.globl vector175
vector175:
  pushl $0
80108566:	6a 00                	push   $0x0
  pushl $175
80108568:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
8010856d:	e9 be f2 ff ff       	jmp    80107830 <alltraps>

80108572 <vector176>:
.globl vector176
vector176:
  pushl $0
80108572:	6a 00                	push   $0x0
  pushl $176
80108574:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80108579:	e9 b2 f2 ff ff       	jmp    80107830 <alltraps>

8010857e <vector177>:
.globl vector177
vector177:
  pushl $0
8010857e:	6a 00                	push   $0x0
  pushl $177
80108580:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80108585:	e9 a6 f2 ff ff       	jmp    80107830 <alltraps>

8010858a <vector178>:
.globl vector178
vector178:
  pushl $0
8010858a:	6a 00                	push   $0x0
  pushl $178
8010858c:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80108591:	e9 9a f2 ff ff       	jmp    80107830 <alltraps>

80108596 <vector179>:
.globl vector179
vector179:
  pushl $0
80108596:	6a 00                	push   $0x0
  pushl $179
80108598:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
8010859d:	e9 8e f2 ff ff       	jmp    80107830 <alltraps>

801085a2 <vector180>:
.globl vector180
vector180:
  pushl $0
801085a2:	6a 00                	push   $0x0
  pushl $180
801085a4:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
801085a9:	e9 82 f2 ff ff       	jmp    80107830 <alltraps>

801085ae <vector181>:
.globl vector181
vector181:
  pushl $0
801085ae:	6a 00                	push   $0x0
  pushl $181
801085b0:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
801085b5:	e9 76 f2 ff ff       	jmp    80107830 <alltraps>

801085ba <vector182>:
.globl vector182
vector182:
  pushl $0
801085ba:	6a 00                	push   $0x0
  pushl $182
801085bc:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
801085c1:	e9 6a f2 ff ff       	jmp    80107830 <alltraps>

801085c6 <vector183>:
.globl vector183
vector183:
  pushl $0
801085c6:	6a 00                	push   $0x0
  pushl $183
801085c8:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
801085cd:	e9 5e f2 ff ff       	jmp    80107830 <alltraps>

801085d2 <vector184>:
.globl vector184
vector184:
  pushl $0
801085d2:	6a 00                	push   $0x0
  pushl $184
801085d4:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
801085d9:	e9 52 f2 ff ff       	jmp    80107830 <alltraps>

801085de <vector185>:
.globl vector185
vector185:
  pushl $0
801085de:	6a 00                	push   $0x0
  pushl $185
801085e0:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
801085e5:	e9 46 f2 ff ff       	jmp    80107830 <alltraps>

801085ea <vector186>:
.globl vector186
vector186:
  pushl $0
801085ea:	6a 00                	push   $0x0
  pushl $186
801085ec:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
801085f1:	e9 3a f2 ff ff       	jmp    80107830 <alltraps>

801085f6 <vector187>:
.globl vector187
vector187:
  pushl $0
801085f6:	6a 00                	push   $0x0
  pushl $187
801085f8:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
801085fd:	e9 2e f2 ff ff       	jmp    80107830 <alltraps>

80108602 <vector188>:
.globl vector188
vector188:
  pushl $0
80108602:	6a 00                	push   $0x0
  pushl $188
80108604:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80108609:	e9 22 f2 ff ff       	jmp    80107830 <alltraps>

8010860e <vector189>:
.globl vector189
vector189:
  pushl $0
8010860e:	6a 00                	push   $0x0
  pushl $189
80108610:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80108615:	e9 16 f2 ff ff       	jmp    80107830 <alltraps>

8010861a <vector190>:
.globl vector190
vector190:
  pushl $0
8010861a:	6a 00                	push   $0x0
  pushl $190
8010861c:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80108621:	e9 0a f2 ff ff       	jmp    80107830 <alltraps>

80108626 <vector191>:
.globl vector191
vector191:
  pushl $0
80108626:	6a 00                	push   $0x0
  pushl $191
80108628:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
8010862d:	e9 fe f1 ff ff       	jmp    80107830 <alltraps>

80108632 <vector192>:
.globl vector192
vector192:
  pushl $0
80108632:	6a 00                	push   $0x0
  pushl $192
80108634:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80108639:	e9 f2 f1 ff ff       	jmp    80107830 <alltraps>

8010863e <vector193>:
.globl vector193
vector193:
  pushl $0
8010863e:	6a 00                	push   $0x0
  pushl $193
80108640:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80108645:	e9 e6 f1 ff ff       	jmp    80107830 <alltraps>

8010864a <vector194>:
.globl vector194
vector194:
  pushl $0
8010864a:	6a 00                	push   $0x0
  pushl $194
8010864c:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80108651:	e9 da f1 ff ff       	jmp    80107830 <alltraps>

80108656 <vector195>:
.globl vector195
vector195:
  pushl $0
80108656:	6a 00                	push   $0x0
  pushl $195
80108658:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
8010865d:	e9 ce f1 ff ff       	jmp    80107830 <alltraps>

80108662 <vector196>:
.globl vector196
vector196:
  pushl $0
80108662:	6a 00                	push   $0x0
  pushl $196
80108664:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80108669:	e9 c2 f1 ff ff       	jmp    80107830 <alltraps>

8010866e <vector197>:
.globl vector197
vector197:
  pushl $0
8010866e:	6a 00                	push   $0x0
  pushl $197
80108670:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80108675:	e9 b6 f1 ff ff       	jmp    80107830 <alltraps>

8010867a <vector198>:
.globl vector198
vector198:
  pushl $0
8010867a:	6a 00                	push   $0x0
  pushl $198
8010867c:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80108681:	e9 aa f1 ff ff       	jmp    80107830 <alltraps>

80108686 <vector199>:
.globl vector199
vector199:
  pushl $0
80108686:	6a 00                	push   $0x0
  pushl $199
80108688:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
8010868d:	e9 9e f1 ff ff       	jmp    80107830 <alltraps>

80108692 <vector200>:
.globl vector200
vector200:
  pushl $0
80108692:	6a 00                	push   $0x0
  pushl $200
80108694:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80108699:	e9 92 f1 ff ff       	jmp    80107830 <alltraps>

8010869e <vector201>:
.globl vector201
vector201:
  pushl $0
8010869e:	6a 00                	push   $0x0
  pushl $201
801086a0:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
801086a5:	e9 86 f1 ff ff       	jmp    80107830 <alltraps>

801086aa <vector202>:
.globl vector202
vector202:
  pushl $0
801086aa:	6a 00                	push   $0x0
  pushl $202
801086ac:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
801086b1:	e9 7a f1 ff ff       	jmp    80107830 <alltraps>

801086b6 <vector203>:
.globl vector203
vector203:
  pushl $0
801086b6:	6a 00                	push   $0x0
  pushl $203
801086b8:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
801086bd:	e9 6e f1 ff ff       	jmp    80107830 <alltraps>

801086c2 <vector204>:
.globl vector204
vector204:
  pushl $0
801086c2:	6a 00                	push   $0x0
  pushl $204
801086c4:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
801086c9:	e9 62 f1 ff ff       	jmp    80107830 <alltraps>

801086ce <vector205>:
.globl vector205
vector205:
  pushl $0
801086ce:	6a 00                	push   $0x0
  pushl $205
801086d0:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
801086d5:	e9 56 f1 ff ff       	jmp    80107830 <alltraps>

801086da <vector206>:
.globl vector206
vector206:
  pushl $0
801086da:	6a 00                	push   $0x0
  pushl $206
801086dc:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
801086e1:	e9 4a f1 ff ff       	jmp    80107830 <alltraps>

801086e6 <vector207>:
.globl vector207
vector207:
  pushl $0
801086e6:	6a 00                	push   $0x0
  pushl $207
801086e8:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
801086ed:	e9 3e f1 ff ff       	jmp    80107830 <alltraps>

801086f2 <vector208>:
.globl vector208
vector208:
  pushl $0
801086f2:	6a 00                	push   $0x0
  pushl $208
801086f4:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
801086f9:	e9 32 f1 ff ff       	jmp    80107830 <alltraps>

801086fe <vector209>:
.globl vector209
vector209:
  pushl $0
801086fe:	6a 00                	push   $0x0
  pushl $209
80108700:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80108705:	e9 26 f1 ff ff       	jmp    80107830 <alltraps>

8010870a <vector210>:
.globl vector210
vector210:
  pushl $0
8010870a:	6a 00                	push   $0x0
  pushl $210
8010870c:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80108711:	e9 1a f1 ff ff       	jmp    80107830 <alltraps>

80108716 <vector211>:
.globl vector211
vector211:
  pushl $0
80108716:	6a 00                	push   $0x0
  pushl $211
80108718:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
8010871d:	e9 0e f1 ff ff       	jmp    80107830 <alltraps>

80108722 <vector212>:
.globl vector212
vector212:
  pushl $0
80108722:	6a 00                	push   $0x0
  pushl $212
80108724:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80108729:	e9 02 f1 ff ff       	jmp    80107830 <alltraps>

8010872e <vector213>:
.globl vector213
vector213:
  pushl $0
8010872e:	6a 00                	push   $0x0
  pushl $213
80108730:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80108735:	e9 f6 f0 ff ff       	jmp    80107830 <alltraps>

8010873a <vector214>:
.globl vector214
vector214:
  pushl $0
8010873a:	6a 00                	push   $0x0
  pushl $214
8010873c:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80108741:	e9 ea f0 ff ff       	jmp    80107830 <alltraps>

80108746 <vector215>:
.globl vector215
vector215:
  pushl $0
80108746:	6a 00                	push   $0x0
  pushl $215
80108748:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
8010874d:	e9 de f0 ff ff       	jmp    80107830 <alltraps>

80108752 <vector216>:
.globl vector216
vector216:
  pushl $0
80108752:	6a 00                	push   $0x0
  pushl $216
80108754:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80108759:	e9 d2 f0 ff ff       	jmp    80107830 <alltraps>

8010875e <vector217>:
.globl vector217
vector217:
  pushl $0
8010875e:	6a 00                	push   $0x0
  pushl $217
80108760:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80108765:	e9 c6 f0 ff ff       	jmp    80107830 <alltraps>

8010876a <vector218>:
.globl vector218
vector218:
  pushl $0
8010876a:	6a 00                	push   $0x0
  pushl $218
8010876c:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80108771:	e9 ba f0 ff ff       	jmp    80107830 <alltraps>

80108776 <vector219>:
.globl vector219
vector219:
  pushl $0
80108776:	6a 00                	push   $0x0
  pushl $219
80108778:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
8010877d:	e9 ae f0 ff ff       	jmp    80107830 <alltraps>

80108782 <vector220>:
.globl vector220
vector220:
  pushl $0
80108782:	6a 00                	push   $0x0
  pushl $220
80108784:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80108789:	e9 a2 f0 ff ff       	jmp    80107830 <alltraps>

8010878e <vector221>:
.globl vector221
vector221:
  pushl $0
8010878e:	6a 00                	push   $0x0
  pushl $221
80108790:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80108795:	e9 96 f0 ff ff       	jmp    80107830 <alltraps>

8010879a <vector222>:
.globl vector222
vector222:
  pushl $0
8010879a:	6a 00                	push   $0x0
  pushl $222
8010879c:	68 de 00 00 00       	push   $0xde
  jmp alltraps
801087a1:	e9 8a f0 ff ff       	jmp    80107830 <alltraps>

801087a6 <vector223>:
.globl vector223
vector223:
  pushl $0
801087a6:	6a 00                	push   $0x0
  pushl $223
801087a8:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
801087ad:	e9 7e f0 ff ff       	jmp    80107830 <alltraps>

801087b2 <vector224>:
.globl vector224
vector224:
  pushl $0
801087b2:	6a 00                	push   $0x0
  pushl $224
801087b4:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
801087b9:	e9 72 f0 ff ff       	jmp    80107830 <alltraps>

801087be <vector225>:
.globl vector225
vector225:
  pushl $0
801087be:	6a 00                	push   $0x0
  pushl $225
801087c0:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
801087c5:	e9 66 f0 ff ff       	jmp    80107830 <alltraps>

801087ca <vector226>:
.globl vector226
vector226:
  pushl $0
801087ca:	6a 00                	push   $0x0
  pushl $226
801087cc:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
801087d1:	e9 5a f0 ff ff       	jmp    80107830 <alltraps>

801087d6 <vector227>:
.globl vector227
vector227:
  pushl $0
801087d6:	6a 00                	push   $0x0
  pushl $227
801087d8:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
801087dd:	e9 4e f0 ff ff       	jmp    80107830 <alltraps>

801087e2 <vector228>:
.globl vector228
vector228:
  pushl $0
801087e2:	6a 00                	push   $0x0
  pushl $228
801087e4:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
801087e9:	e9 42 f0 ff ff       	jmp    80107830 <alltraps>

801087ee <vector229>:
.globl vector229
vector229:
  pushl $0
801087ee:	6a 00                	push   $0x0
  pushl $229
801087f0:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
801087f5:	e9 36 f0 ff ff       	jmp    80107830 <alltraps>

801087fa <vector230>:
.globl vector230
vector230:
  pushl $0
801087fa:	6a 00                	push   $0x0
  pushl $230
801087fc:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80108801:	e9 2a f0 ff ff       	jmp    80107830 <alltraps>

80108806 <vector231>:
.globl vector231
vector231:
  pushl $0
80108806:	6a 00                	push   $0x0
  pushl $231
80108808:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
8010880d:	e9 1e f0 ff ff       	jmp    80107830 <alltraps>

80108812 <vector232>:
.globl vector232
vector232:
  pushl $0
80108812:	6a 00                	push   $0x0
  pushl $232
80108814:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80108819:	e9 12 f0 ff ff       	jmp    80107830 <alltraps>

8010881e <vector233>:
.globl vector233
vector233:
  pushl $0
8010881e:	6a 00                	push   $0x0
  pushl $233
80108820:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80108825:	e9 06 f0 ff ff       	jmp    80107830 <alltraps>

8010882a <vector234>:
.globl vector234
vector234:
  pushl $0
8010882a:	6a 00                	push   $0x0
  pushl $234
8010882c:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80108831:	e9 fa ef ff ff       	jmp    80107830 <alltraps>

80108836 <vector235>:
.globl vector235
vector235:
  pushl $0
80108836:	6a 00                	push   $0x0
  pushl $235
80108838:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
8010883d:	e9 ee ef ff ff       	jmp    80107830 <alltraps>

80108842 <vector236>:
.globl vector236
vector236:
  pushl $0
80108842:	6a 00                	push   $0x0
  pushl $236
80108844:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80108849:	e9 e2 ef ff ff       	jmp    80107830 <alltraps>

8010884e <vector237>:
.globl vector237
vector237:
  pushl $0
8010884e:	6a 00                	push   $0x0
  pushl $237
80108850:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80108855:	e9 d6 ef ff ff       	jmp    80107830 <alltraps>

8010885a <vector238>:
.globl vector238
vector238:
  pushl $0
8010885a:	6a 00                	push   $0x0
  pushl $238
8010885c:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80108861:	e9 ca ef ff ff       	jmp    80107830 <alltraps>

80108866 <vector239>:
.globl vector239
vector239:
  pushl $0
80108866:	6a 00                	push   $0x0
  pushl $239
80108868:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
8010886d:	e9 be ef ff ff       	jmp    80107830 <alltraps>

80108872 <vector240>:
.globl vector240
vector240:
  pushl $0
80108872:	6a 00                	push   $0x0
  pushl $240
80108874:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80108879:	e9 b2 ef ff ff       	jmp    80107830 <alltraps>

8010887e <vector241>:
.globl vector241
vector241:
  pushl $0
8010887e:	6a 00                	push   $0x0
  pushl $241
80108880:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80108885:	e9 a6 ef ff ff       	jmp    80107830 <alltraps>

8010888a <vector242>:
.globl vector242
vector242:
  pushl $0
8010888a:	6a 00                	push   $0x0
  pushl $242
8010888c:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80108891:	e9 9a ef ff ff       	jmp    80107830 <alltraps>

80108896 <vector243>:
.globl vector243
vector243:
  pushl $0
80108896:	6a 00                	push   $0x0
  pushl $243
80108898:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
8010889d:	e9 8e ef ff ff       	jmp    80107830 <alltraps>

801088a2 <vector244>:
.globl vector244
vector244:
  pushl $0
801088a2:	6a 00                	push   $0x0
  pushl $244
801088a4:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
801088a9:	e9 82 ef ff ff       	jmp    80107830 <alltraps>

801088ae <vector245>:
.globl vector245
vector245:
  pushl $0
801088ae:	6a 00                	push   $0x0
  pushl $245
801088b0:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
801088b5:	e9 76 ef ff ff       	jmp    80107830 <alltraps>

801088ba <vector246>:
.globl vector246
vector246:
  pushl $0
801088ba:	6a 00                	push   $0x0
  pushl $246
801088bc:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
801088c1:	e9 6a ef ff ff       	jmp    80107830 <alltraps>

801088c6 <vector247>:
.globl vector247
vector247:
  pushl $0
801088c6:	6a 00                	push   $0x0
  pushl $247
801088c8:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
801088cd:	e9 5e ef ff ff       	jmp    80107830 <alltraps>

801088d2 <vector248>:
.globl vector248
vector248:
  pushl $0
801088d2:	6a 00                	push   $0x0
  pushl $248
801088d4:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
801088d9:	e9 52 ef ff ff       	jmp    80107830 <alltraps>

801088de <vector249>:
.globl vector249
vector249:
  pushl $0
801088de:	6a 00                	push   $0x0
  pushl $249
801088e0:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
801088e5:	e9 46 ef ff ff       	jmp    80107830 <alltraps>

801088ea <vector250>:
.globl vector250
vector250:
  pushl $0
801088ea:	6a 00                	push   $0x0
  pushl $250
801088ec:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
801088f1:	e9 3a ef ff ff       	jmp    80107830 <alltraps>

801088f6 <vector251>:
.globl vector251
vector251:
  pushl $0
801088f6:	6a 00                	push   $0x0
  pushl $251
801088f8:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
801088fd:	e9 2e ef ff ff       	jmp    80107830 <alltraps>

80108902 <vector252>:
.globl vector252
vector252:
  pushl $0
80108902:	6a 00                	push   $0x0
  pushl $252
80108904:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80108909:	e9 22 ef ff ff       	jmp    80107830 <alltraps>

8010890e <vector253>:
.globl vector253
vector253:
  pushl $0
8010890e:	6a 00                	push   $0x0
  pushl $253
80108910:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80108915:	e9 16 ef ff ff       	jmp    80107830 <alltraps>

8010891a <vector254>:
.globl vector254
vector254:
  pushl $0
8010891a:	6a 00                	push   $0x0
  pushl $254
8010891c:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80108921:	e9 0a ef ff ff       	jmp    80107830 <alltraps>

80108926 <vector255>:
.globl vector255
vector255:
  pushl $0
80108926:	6a 00                	push   $0x0
  pushl $255
80108928:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
8010892d:	e9 fe ee ff ff       	jmp    80107830 <alltraps>
	...

80108934 <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
80108934:	55                   	push   %ebp
80108935:	89 e5                	mov    %esp,%ebp
80108937:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
8010893a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010893d:	83 e8 01             	sub    $0x1,%eax
80108940:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80108944:	8b 45 08             	mov    0x8(%ebp),%eax
80108947:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
8010894b:	8b 45 08             	mov    0x8(%ebp),%eax
8010894e:	c1 e8 10             	shr    $0x10,%eax
80108951:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
80108955:	8d 45 fa             	lea    -0x6(%ebp),%eax
80108958:	0f 01 10             	lgdtl  (%eax)
}
8010895b:	c9                   	leave  
8010895c:	c3                   	ret    

8010895d <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
8010895d:	55                   	push   %ebp
8010895e:	89 e5                	mov    %esp,%ebp
80108960:	83 ec 04             	sub    $0x4,%esp
80108963:	8b 45 08             	mov    0x8(%ebp),%eax
80108966:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
8010896a:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
8010896e:	0f 00 d8             	ltr    %ax
}
80108971:	c9                   	leave  
80108972:	c3                   	ret    

80108973 <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
80108973:	55                   	push   %ebp
80108974:	89 e5                	mov    %esp,%ebp
80108976:	83 ec 04             	sub    $0x4,%esp
80108979:	8b 45 08             	mov    0x8(%ebp),%eax
8010897c:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
80108980:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80108984:	8e e8                	mov    %eax,%gs
}
80108986:	c9                   	leave  
80108987:	c3                   	ret    

80108988 <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
80108988:	55                   	push   %ebp
80108989:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
8010898b:	8b 45 08             	mov    0x8(%ebp),%eax
8010898e:	0f 22 d8             	mov    %eax,%cr3
}
80108991:	5d                   	pop    %ebp
80108992:	c3                   	ret    

80108993 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80108993:	55                   	push   %ebp
80108994:	89 e5                	mov    %esp,%ebp
80108996:	8b 45 08             	mov    0x8(%ebp),%eax
80108999:	05 00 00 00 80       	add    $0x80000000,%eax
8010899e:	5d                   	pop    %ebp
8010899f:	c3                   	ret    

801089a0 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
801089a0:	55                   	push   %ebp
801089a1:	89 e5                	mov    %esp,%ebp
801089a3:	8b 45 08             	mov    0x8(%ebp),%eax
801089a6:	05 00 00 00 80       	add    $0x80000000,%eax
801089ab:	5d                   	pop    %ebp
801089ac:	c3                   	ret    

801089ad <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
801089ad:	55                   	push   %ebp
801089ae:	89 e5                	mov    %esp,%ebp
801089b0:	53                   	push   %ebx
801089b1:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
801089b4:	e8 d0 ac ff ff       	call   80103689 <cpunum>
801089b9:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801089bf:	05 80 71 12 80       	add    $0x80127180,%eax
801089c4:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
801089c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089ca:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
801089d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089d3:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
801089d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089dc:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
801089e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089e3:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801089e7:	83 e2 f0             	and    $0xfffffff0,%edx
801089ea:	83 ca 0a             	or     $0xa,%edx
801089ed:	88 50 7d             	mov    %dl,0x7d(%eax)
801089f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089f3:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801089f7:	83 ca 10             	or     $0x10,%edx
801089fa:	88 50 7d             	mov    %dl,0x7d(%eax)
801089fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a00:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108a04:	83 e2 9f             	and    $0xffffff9f,%edx
80108a07:	88 50 7d             	mov    %dl,0x7d(%eax)
80108a0a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a0d:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108a11:	83 ca 80             	or     $0xffffff80,%edx
80108a14:	88 50 7d             	mov    %dl,0x7d(%eax)
80108a17:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a1a:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108a1e:	83 ca 0f             	or     $0xf,%edx
80108a21:	88 50 7e             	mov    %dl,0x7e(%eax)
80108a24:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a27:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108a2b:	83 e2 ef             	and    $0xffffffef,%edx
80108a2e:	88 50 7e             	mov    %dl,0x7e(%eax)
80108a31:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a34:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108a38:	83 e2 df             	and    $0xffffffdf,%edx
80108a3b:	88 50 7e             	mov    %dl,0x7e(%eax)
80108a3e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a41:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108a45:	83 ca 40             	or     $0x40,%edx
80108a48:	88 50 7e             	mov    %dl,0x7e(%eax)
80108a4b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a4e:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108a52:	83 ca 80             	or     $0xffffff80,%edx
80108a55:	88 50 7e             	mov    %dl,0x7e(%eax)
80108a58:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a5b:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80108a5f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a62:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
80108a69:	ff ff 
80108a6b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a6e:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
80108a75:	00 00 
80108a77:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a7a:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
80108a81:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a84:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80108a8b:	83 e2 f0             	and    $0xfffffff0,%edx
80108a8e:	83 ca 02             	or     $0x2,%edx
80108a91:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80108a97:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a9a:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80108aa1:	83 ca 10             	or     $0x10,%edx
80108aa4:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80108aaa:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108aad:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80108ab4:	83 e2 9f             	and    $0xffffff9f,%edx
80108ab7:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80108abd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ac0:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80108ac7:	83 ca 80             	or     $0xffffff80,%edx
80108aca:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80108ad0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ad3:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108ada:	83 ca 0f             	or     $0xf,%edx
80108add:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108ae3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ae6:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108aed:	83 e2 ef             	and    $0xffffffef,%edx
80108af0:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108af6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108af9:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108b00:	83 e2 df             	and    $0xffffffdf,%edx
80108b03:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108b09:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b0c:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108b13:	83 ca 40             	or     $0x40,%edx
80108b16:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108b1c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b1f:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108b26:	83 ca 80             	or     $0xffffff80,%edx
80108b29:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108b2f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b32:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80108b39:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b3c:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
80108b43:	ff ff 
80108b45:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b48:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
80108b4f:	00 00 
80108b51:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b54:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
80108b5b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b5e:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80108b65:	83 e2 f0             	and    $0xfffffff0,%edx
80108b68:	83 ca 0a             	or     $0xa,%edx
80108b6b:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80108b71:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b74:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80108b7b:	83 ca 10             	or     $0x10,%edx
80108b7e:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80108b84:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b87:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80108b8e:	83 ca 60             	or     $0x60,%edx
80108b91:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80108b97:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b9a:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80108ba1:	83 ca 80             	or     $0xffffff80,%edx
80108ba4:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80108baa:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108bad:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108bb4:	83 ca 0f             	or     $0xf,%edx
80108bb7:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108bbd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108bc0:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108bc7:	83 e2 ef             	and    $0xffffffef,%edx
80108bca:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108bd0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108bd3:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108bda:	83 e2 df             	and    $0xffffffdf,%edx
80108bdd:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108be3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108be6:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108bed:	83 ca 40             	or     $0x40,%edx
80108bf0:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108bf6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108bf9:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108c00:	83 ca 80             	or     $0xffffff80,%edx
80108c03:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108c09:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c0c:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80108c13:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c16:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
80108c1d:	ff ff 
80108c1f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c22:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
80108c29:	00 00 
80108c2b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c2e:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
80108c35:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c38:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108c3f:	83 e2 f0             	and    $0xfffffff0,%edx
80108c42:	83 ca 02             	or     $0x2,%edx
80108c45:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108c4b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c4e:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108c55:	83 ca 10             	or     $0x10,%edx
80108c58:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108c5e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c61:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108c68:	83 ca 60             	or     $0x60,%edx
80108c6b:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108c71:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c74:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108c7b:	83 ca 80             	or     $0xffffff80,%edx
80108c7e:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108c84:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c87:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108c8e:	83 ca 0f             	or     $0xf,%edx
80108c91:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108c97:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c9a:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108ca1:	83 e2 ef             	and    $0xffffffef,%edx
80108ca4:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108caa:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108cad:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108cb4:	83 e2 df             	and    $0xffffffdf,%edx
80108cb7:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108cbd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108cc0:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108cc7:	83 ca 40             	or     $0x40,%edx
80108cca:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108cd0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108cd3:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108cda:	83 ca 80             	or     $0xffffff80,%edx
80108cdd:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108ce3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ce6:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
80108ced:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108cf0:	05 b4 00 00 00       	add    $0xb4,%eax
80108cf5:	89 c3                	mov    %eax,%ebx
80108cf7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108cfa:	05 b4 00 00 00       	add    $0xb4,%eax
80108cff:	c1 e8 10             	shr    $0x10,%eax
80108d02:	89 c1                	mov    %eax,%ecx
80108d04:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d07:	05 b4 00 00 00       	add    $0xb4,%eax
80108d0c:	c1 e8 18             	shr    $0x18,%eax
80108d0f:	89 c2                	mov    %eax,%edx
80108d11:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d14:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
80108d1b:	00 00 
80108d1d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d20:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
80108d27:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d2a:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
80108d30:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d33:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108d3a:	83 e1 f0             	and    $0xfffffff0,%ecx
80108d3d:	83 c9 02             	or     $0x2,%ecx
80108d40:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108d46:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d49:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108d50:	83 c9 10             	or     $0x10,%ecx
80108d53:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108d59:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d5c:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108d63:	83 e1 9f             	and    $0xffffff9f,%ecx
80108d66:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108d6c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d6f:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108d76:	83 c9 80             	or     $0xffffff80,%ecx
80108d79:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108d7f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d82:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108d89:	83 e1 f0             	and    $0xfffffff0,%ecx
80108d8c:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108d92:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d95:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108d9c:	83 e1 ef             	and    $0xffffffef,%ecx
80108d9f:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108da5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108da8:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108daf:	83 e1 df             	and    $0xffffffdf,%ecx
80108db2:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108db8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108dbb:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108dc2:	83 c9 40             	or     $0x40,%ecx
80108dc5:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108dcb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108dce:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108dd5:	83 c9 80             	or     $0xffffff80,%ecx
80108dd8:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108dde:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108de1:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
80108de7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108dea:	83 c0 70             	add    $0x70,%eax
80108ded:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
80108df4:	00 
80108df5:	89 04 24             	mov    %eax,(%esp)
80108df8:	e8 37 fb ff ff       	call   80108934 <lgdt>
  loadgs(SEG_KCPU << 3);
80108dfd:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
80108e04:	e8 6a fb ff ff       	call   80108973 <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
80108e09:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e0c:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
80108e12:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80108e19:	00 00 00 00 
}
80108e1d:	83 c4 24             	add    $0x24,%esp
80108e20:	5b                   	pop    %ebx
80108e21:	5d                   	pop    %ebp
80108e22:	c3                   	ret    

80108e23 <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80108e23:	55                   	push   %ebp
80108e24:	89 e5                	mov    %esp,%ebp
80108e26:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80108e29:	8b 45 0c             	mov    0xc(%ebp),%eax
80108e2c:	c1 e8 16             	shr    $0x16,%eax
80108e2f:	c1 e0 02             	shl    $0x2,%eax
80108e32:	03 45 08             	add    0x8(%ebp),%eax
80108e35:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
80108e38:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108e3b:	8b 00                	mov    (%eax),%eax
80108e3d:	83 e0 01             	and    $0x1,%eax
80108e40:	84 c0                	test   %al,%al
80108e42:	74 17                	je     80108e5b <walkpgdir+0x38>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
80108e44:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108e47:	8b 00                	mov    (%eax),%eax
80108e49:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108e4e:	89 04 24             	mov    %eax,(%esp)
80108e51:	e8 4a fb ff ff       	call   801089a0 <p2v>
80108e56:	89 45 f4             	mov    %eax,-0xc(%ebp)
80108e59:	eb 4b                	jmp    80108ea6 <walkpgdir+0x83>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
80108e5b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80108e5f:	74 0e                	je     80108e6f <walkpgdir+0x4c>
80108e61:	e8 aa 9c ff ff       	call   80102b10 <kalloc>
80108e66:	89 45 f4             	mov    %eax,-0xc(%ebp)
80108e69:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80108e6d:	75 07                	jne    80108e76 <walkpgdir+0x53>
      return 0;
80108e6f:	b8 00 00 00 00       	mov    $0x0,%eax
80108e74:	eb 41                	jmp    80108eb7 <walkpgdir+0x94>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
80108e76:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108e7d:	00 
80108e7e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108e85:	00 
80108e86:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e89:	89 04 24             	mov    %eax,(%esp)
80108e8c:	e8 39 d0 ff ff       	call   80105eca <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
80108e91:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e94:	89 04 24             	mov    %eax,(%esp)
80108e97:	e8 f7 fa ff ff       	call   80108993 <v2p>
80108e9c:	89 c2                	mov    %eax,%edx
80108e9e:	83 ca 07             	or     $0x7,%edx
80108ea1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108ea4:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
80108ea6:	8b 45 0c             	mov    0xc(%ebp),%eax
80108ea9:	c1 e8 0c             	shr    $0xc,%eax
80108eac:	25 ff 03 00 00       	and    $0x3ff,%eax
80108eb1:	c1 e0 02             	shl    $0x2,%eax
80108eb4:	03 45 f4             	add    -0xc(%ebp),%eax
}
80108eb7:	c9                   	leave  
80108eb8:	c3                   	ret    

80108eb9 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80108eb9:	55                   	push   %ebp
80108eba:	89 e5                	mov    %esp,%ebp
80108ebc:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
80108ebf:	8b 45 0c             	mov    0xc(%ebp),%eax
80108ec2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108ec7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  //cprintf("mappages: a = %p\n",a);
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80108eca:	8b 45 0c             	mov    0xc(%ebp),%eax
80108ecd:	03 45 10             	add    0x10(%ebp),%eax
80108ed0:	83 e8 01             	sub    $0x1,%eax
80108ed3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108ed8:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80108edb:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80108ee2:	00 
80108ee3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ee6:	89 44 24 04          	mov    %eax,0x4(%esp)
80108eea:	8b 45 08             	mov    0x8(%ebp),%eax
80108eed:	89 04 24             	mov    %eax,(%esp)
80108ef0:	e8 2e ff ff ff       	call   80108e23 <walkpgdir>
80108ef5:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108ef8:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108efc:	75 07                	jne    80108f05 <mappages+0x4c>
      return -1;
80108efe:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108f03:	eb 46                	jmp    80108f4b <mappages+0x92>
    if(*pte & PTE_P)
80108f05:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108f08:	8b 00                	mov    (%eax),%eax
80108f0a:	83 e0 01             	and    $0x1,%eax
80108f0d:	84 c0                	test   %al,%al
80108f0f:	74 0c                	je     80108f1d <mappages+0x64>
      panic("remap");
80108f11:	c7 04 24 ec 9e 10 80 	movl   $0x80109eec,(%esp)
80108f18:	e8 20 76 ff ff       	call   8010053d <panic>
    *pte = pa | perm | PTE_P;
80108f1d:	8b 45 18             	mov    0x18(%ebp),%eax
80108f20:	0b 45 14             	or     0x14(%ebp),%eax
80108f23:	89 c2                	mov    %eax,%edx
80108f25:	83 ca 01             	or     $0x1,%edx
80108f28:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108f2b:	89 10                	mov    %edx,(%eax)
   //cprintf("mappages: pte = %p\n",pte);
    if(a == last)
80108f2d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108f30:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80108f33:	74 10                	je     80108f45 <mappages+0x8c>
      break;
    a += PGSIZE;
80108f35:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
80108f3c:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
80108f43:	eb 96                	jmp    80108edb <mappages+0x22>
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
   //cprintf("mappages: pte = %p\n",pte);
    if(a == last)
      break;
80108f45:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
80108f46:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108f4b:	c9                   	leave  
80108f4c:	c3                   	ret    

80108f4d <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm()
{
80108f4d:	55                   	push   %ebp
80108f4e:	89 e5                	mov    %esp,%ebp
80108f50:	53                   	push   %ebx
80108f51:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
80108f54:	e8 b7 9b ff ff       	call   80102b10 <kalloc>
80108f59:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108f5c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108f60:	75 0a                	jne    80108f6c <setupkvm+0x1f>
    return 0;
80108f62:	b8 00 00 00 00       	mov    $0x0,%eax
80108f67:	e9 98 00 00 00       	jmp    80109004 <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
80108f6c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108f73:	00 
80108f74:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108f7b:	00 
80108f7c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108f7f:	89 04 24             	mov    %eax,(%esp)
80108f82:	e8 43 cf ff ff       	call   80105eca <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
80108f87:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
80108f8e:	e8 0d fa ff ff       	call   801089a0 <p2v>
80108f93:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
80108f98:	76 0c                	jbe    80108fa6 <setupkvm+0x59>
    panic("PHYSTOP too high");
80108f9a:	c7 04 24 f2 9e 10 80 	movl   $0x80109ef2,(%esp)
80108fa1:	e8 97 75 ff ff       	call   8010053d <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80108fa6:	c7 45 f4 c0 c4 10 80 	movl   $0x8010c4c0,-0xc(%ebp)
80108fad:	eb 49                	jmp    80108ff8 <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
80108faf:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80108fb2:	8b 48 0c             	mov    0xc(%eax),%ecx
                (uint)k->phys_start, k->perm) < 0)
80108fb5:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80108fb8:	8b 50 04             	mov    0x4(%eax),%edx
80108fbb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108fbe:	8b 58 08             	mov    0x8(%eax),%ebx
80108fc1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108fc4:	8b 40 04             	mov    0x4(%eax),%eax
80108fc7:	29 c3                	sub    %eax,%ebx
80108fc9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108fcc:	8b 00                	mov    (%eax),%eax
80108fce:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80108fd2:	89 54 24 0c          	mov    %edx,0xc(%esp)
80108fd6:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80108fda:	89 44 24 04          	mov    %eax,0x4(%esp)
80108fde:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108fe1:	89 04 24             	mov    %eax,(%esp)
80108fe4:	e8 d0 fe ff ff       	call   80108eb9 <mappages>
80108fe9:	85 c0                	test   %eax,%eax
80108feb:	79 07                	jns    80108ff4 <setupkvm+0xa7>
                (uint)k->phys_start, k->perm) < 0)
      return 0;
80108fed:	b8 00 00 00 00       	mov    $0x0,%eax
80108ff2:	eb 10                	jmp    80109004 <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80108ff4:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80108ff8:	81 7d f4 00 c5 10 80 	cmpl   $0x8010c500,-0xc(%ebp)
80108fff:	72 ae                	jb     80108faf <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
      return 0;
  return pgdir;
80109001:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80109004:	83 c4 34             	add    $0x34,%esp
80109007:	5b                   	pop    %ebx
80109008:	5d                   	pop    %ebp
80109009:	c3                   	ret    

8010900a <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
void
kvmalloc(void)
{
8010900a:	55                   	push   %ebp
8010900b:	89 e5                	mov    %esp,%ebp
8010900d:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80109010:	e8 38 ff ff ff       	call   80108f4d <setupkvm>
80109015:	a3 58 a5 12 80       	mov    %eax,0x8012a558
  switchkvm();
8010901a:	e8 02 00 00 00       	call   80109021 <switchkvm>
}
8010901f:	c9                   	leave  
80109020:	c3                   	ret    

80109021 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80109021:	55                   	push   %ebp
80109022:	89 e5                	mov    %esp,%ebp
80109024:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
80109027:	a1 58 a5 12 80       	mov    0x8012a558,%eax
8010902c:	89 04 24             	mov    %eax,(%esp)
8010902f:	e8 5f f9 ff ff       	call   80108993 <v2p>
80109034:	89 04 24             	mov    %eax,(%esp)
80109037:	e8 4c f9 ff ff       	call   80108988 <lcr3>
}
8010903c:	c9                   	leave  
8010903d:	c3                   	ret    

8010903e <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
8010903e:	55                   	push   %ebp
8010903f:	89 e5                	mov    %esp,%ebp
80109041:	53                   	push   %ebx
80109042:	83 ec 14             	sub    $0x14,%esp
  pushcli();
80109045:	e8 7a cd ff ff       	call   80105dc4 <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
8010904a:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80109050:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80109057:	83 c2 08             	add    $0x8,%edx
8010905a:	89 d3                	mov    %edx,%ebx
8010905c:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80109063:	83 c2 08             	add    $0x8,%edx
80109066:	c1 ea 10             	shr    $0x10,%edx
80109069:	89 d1                	mov    %edx,%ecx
8010906b:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80109072:	83 c2 08             	add    $0x8,%edx
80109075:	c1 ea 18             	shr    $0x18,%edx
80109078:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
8010907f:	67 00 
80109081:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
80109088:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
8010908e:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80109095:	83 e1 f0             	and    $0xfffffff0,%ecx
80109098:	83 c9 09             	or     $0x9,%ecx
8010909b:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
801090a1:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
801090a8:	83 c9 10             	or     $0x10,%ecx
801090ab:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
801090b1:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
801090b8:	83 e1 9f             	and    $0xffffff9f,%ecx
801090bb:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
801090c1:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
801090c8:	83 c9 80             	or     $0xffffff80,%ecx
801090cb:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
801090d1:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
801090d8:	83 e1 f0             	and    $0xfffffff0,%ecx
801090db:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
801090e1:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
801090e8:	83 e1 ef             	and    $0xffffffef,%ecx
801090eb:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
801090f1:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
801090f8:	83 e1 df             	and    $0xffffffdf,%ecx
801090fb:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80109101:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80109108:	83 c9 40             	or     $0x40,%ecx
8010910b:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80109111:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80109118:	83 e1 7f             	and    $0x7f,%ecx
8010911b:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80109121:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
80109127:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010912d:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
80109134:	83 e2 ef             	and    $0xffffffef,%edx
80109137:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
8010913d:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80109143:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
80109149:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010914f:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80109156:	8b 52 08             	mov    0x8(%edx),%edx
80109159:	81 c2 00 10 00 00    	add    $0x1000,%edx
8010915f:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
80109162:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
80109169:	e8 ef f7 ff ff       	call   8010895d <ltr>
  if(p->pgdir == 0)
8010916e:	8b 45 08             	mov    0x8(%ebp),%eax
80109171:	8b 40 04             	mov    0x4(%eax),%eax
80109174:	85 c0                	test   %eax,%eax
80109176:	75 0c                	jne    80109184 <switchuvm+0x146>
    panic("switchuvm: no pgdir");
80109178:	c7 04 24 03 9f 10 80 	movl   $0x80109f03,(%esp)
8010917f:	e8 b9 73 ff ff       	call   8010053d <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
80109184:	8b 45 08             	mov    0x8(%ebp),%eax
80109187:	8b 40 04             	mov    0x4(%eax),%eax
8010918a:	89 04 24             	mov    %eax,(%esp)
8010918d:	e8 01 f8 ff ff       	call   80108993 <v2p>
80109192:	89 04 24             	mov    %eax,(%esp)
80109195:	e8 ee f7 ff ff       	call   80108988 <lcr3>
  popcli();
8010919a:	e8 6d cc ff ff       	call   80105e0c <popcli>
}
8010919f:	83 c4 14             	add    $0x14,%esp
801091a2:	5b                   	pop    %ebx
801091a3:	5d                   	pop    %ebp
801091a4:	c3                   	ret    

801091a5 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
801091a5:	55                   	push   %ebp
801091a6:	89 e5                	mov    %esp,%ebp
801091a8:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
801091ab:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
801091b2:	76 0c                	jbe    801091c0 <inituvm+0x1b>
    panic("inituvm: more than a page");
801091b4:	c7 04 24 17 9f 10 80 	movl   $0x80109f17,(%esp)
801091bb:	e8 7d 73 ff ff       	call   8010053d <panic>
  mem = kalloc();
801091c0:	e8 4b 99 ff ff       	call   80102b10 <kalloc>
801091c5:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
801091c8:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801091cf:	00 
801091d0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801091d7:	00 
801091d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801091db:	89 04 24             	mov    %eax,(%esp)
801091de:	e8 e7 cc ff ff       	call   80105eca <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
801091e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801091e6:	89 04 24             	mov    %eax,(%esp)
801091e9:	e8 a5 f7 ff ff       	call   80108993 <v2p>
801091ee:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
801091f5:	00 
801091f6:	89 44 24 0c          	mov    %eax,0xc(%esp)
801091fa:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80109201:	00 
80109202:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80109209:	00 
8010920a:	8b 45 08             	mov    0x8(%ebp),%eax
8010920d:	89 04 24             	mov    %eax,(%esp)
80109210:	e8 a4 fc ff ff       	call   80108eb9 <mappages>
  memmove(mem, init, sz);
80109215:	8b 45 10             	mov    0x10(%ebp),%eax
80109218:	89 44 24 08          	mov    %eax,0x8(%esp)
8010921c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010921f:	89 44 24 04          	mov    %eax,0x4(%esp)
80109223:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109226:	89 04 24             	mov    %eax,(%esp)
80109229:	e8 6f cd ff ff       	call   80105f9d <memmove>
}
8010922e:	c9                   	leave  
8010922f:	c3                   	ret    

80109230 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80109230:	55                   	push   %ebp
80109231:	89 e5                	mov    %esp,%ebp
80109233:	53                   	push   %ebx
80109234:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;
  if((uint) addr % PGSIZE != 0)
80109237:	8b 45 0c             	mov    0xc(%ebp),%eax
8010923a:	25 ff 0f 00 00       	and    $0xfff,%eax
8010923f:	85 c0                	test   %eax,%eax
80109241:	74 0c                	je     8010924f <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
80109243:	c7 04 24 34 9f 10 80 	movl   $0x80109f34,(%esp)
8010924a:	e8 ee 72 ff ff       	call   8010053d <panic>
  for(i = 0; i < sz; i += PGSIZE){
8010924f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80109256:	e9 ad 00 00 00       	jmp    80109308 <loaduvm+0xd8>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
8010925b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010925e:	8b 55 0c             	mov    0xc(%ebp),%edx
80109261:	01 d0                	add    %edx,%eax
80109263:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010926a:	00 
8010926b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010926f:	8b 45 08             	mov    0x8(%ebp),%eax
80109272:	89 04 24             	mov    %eax,(%esp)
80109275:	e8 a9 fb ff ff       	call   80108e23 <walkpgdir>
8010927a:	89 45 ec             	mov    %eax,-0x14(%ebp)
8010927d:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80109281:	75 0c                	jne    8010928f <loaduvm+0x5f>
      panic("loaduvm: address should exist");
80109283:	c7 04 24 57 9f 10 80 	movl   $0x80109f57,(%esp)
8010928a:	e8 ae 72 ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
8010928f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109292:	8b 00                	mov    (%eax),%eax
80109294:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109299:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
8010929c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010929f:	8b 55 18             	mov    0x18(%ebp),%edx
801092a2:	89 d1                	mov    %edx,%ecx
801092a4:	29 c1                	sub    %eax,%ecx
801092a6:	89 c8                	mov    %ecx,%eax
801092a8:	3d ff 0f 00 00       	cmp    $0xfff,%eax
801092ad:	77 11                	ja     801092c0 <loaduvm+0x90>
      n = sz - i;
801092af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801092b2:	8b 55 18             	mov    0x18(%ebp),%edx
801092b5:	89 d1                	mov    %edx,%ecx
801092b7:	29 c1                	sub    %eax,%ecx
801092b9:	89 c8                	mov    %ecx,%eax
801092bb:	89 45 f0             	mov    %eax,-0x10(%ebp)
801092be:	eb 07                	jmp    801092c7 <loaduvm+0x97>
    else
      n = PGSIZE;
801092c0:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
801092c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801092ca:	8b 55 14             	mov    0x14(%ebp),%edx
801092cd:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
801092d0:	8b 45 e8             	mov    -0x18(%ebp),%eax
801092d3:	89 04 24             	mov    %eax,(%esp)
801092d6:	e8 c5 f6 ff ff       	call   801089a0 <p2v>
801092db:	8b 55 f0             	mov    -0x10(%ebp),%edx
801092de:	89 54 24 0c          	mov    %edx,0xc(%esp)
801092e2:	89 5c 24 08          	mov    %ebx,0x8(%esp)
801092e6:	89 44 24 04          	mov    %eax,0x4(%esp)
801092ea:	8b 45 10             	mov    0x10(%ebp),%eax
801092ed:	89 04 24             	mov    %eax,(%esp)
801092f0:	e8 69 8a ff ff       	call   80101d5e <readi>
801092f5:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801092f8:	74 07                	je     80109301 <loaduvm+0xd1>
      return -1;
801092fa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801092ff:	eb 18                	jmp    80109319 <loaduvm+0xe9>
{
  uint i, pa, n;
  pte_t *pte;
  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80109301:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80109308:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010930b:	3b 45 18             	cmp    0x18(%ebp),%eax
8010930e:	0f 82 47 ff ff ff    	jb     8010925b <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
80109314:	b8 00 00 00 00       	mov    $0x0,%eax
}
80109319:	83 c4 24             	add    $0x24,%esp
8010931c:	5b                   	pop    %ebx
8010931d:	5d                   	pop    %ebp
8010931e:	c3                   	ret    

8010931f <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
8010931f:	55                   	push   %ebp
80109320:	89 e5                	mov    %esp,%ebp
80109322:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  uint a;

  if(newsz >= KERNBASE)
80109325:	8b 45 10             	mov    0x10(%ebp),%eax
80109328:	85 c0                	test   %eax,%eax
8010932a:	79 0a                	jns    80109336 <allocuvm+0x17>
    return 0;
8010932c:	b8 00 00 00 00       	mov    $0x0,%eax
80109331:	e9 c1 00 00 00       	jmp    801093f7 <allocuvm+0xd8>
  if(newsz < oldsz)
80109336:	8b 45 10             	mov    0x10(%ebp),%eax
80109339:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010933c:	73 08                	jae    80109346 <allocuvm+0x27>
    return oldsz;
8010933e:	8b 45 0c             	mov    0xc(%ebp),%eax
80109341:	e9 b1 00 00 00       	jmp    801093f7 <allocuvm+0xd8>
  a = PGROUNDUP(oldsz);
80109346:	8b 45 0c             	mov    0xc(%ebp),%eax
80109349:	05 ff 0f 00 00       	add    $0xfff,%eax
8010934e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109353:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
80109356:	e9 8d 00 00 00       	jmp    801093e8 <allocuvm+0xc9>
    mem = kalloc();
8010935b:	e8 b0 97 ff ff       	call   80102b10 <kalloc>
80109360:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(mem == 0){
80109363:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80109367:	75 2c                	jne    80109395 <allocuvm+0x76>
      cprintf("allocuvm out of memory\n");
80109369:	c7 04 24 75 9f 10 80 	movl   $0x80109f75,(%esp)
80109370:	e8 2c 70 ff ff       	call   801003a1 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80109375:	8b 45 0c             	mov    0xc(%ebp),%eax
80109378:	89 44 24 08          	mov    %eax,0x8(%esp)
8010937c:	8b 45 10             	mov    0x10(%ebp),%eax
8010937f:	89 44 24 04          	mov    %eax,0x4(%esp)
80109383:	8b 45 08             	mov    0x8(%ebp),%eax
80109386:	89 04 24             	mov    %eax,(%esp)
80109389:	e8 6b 00 00 00       	call   801093f9 <deallocuvm>
      return 0;
8010938e:	b8 00 00 00 00       	mov    $0x0,%eax
80109393:	eb 62                	jmp    801093f7 <allocuvm+0xd8>
    }
    memset(mem, 0, PGSIZE);
80109395:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010939c:	00 
8010939d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801093a4:	00 
801093a5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801093a8:	89 04 24             	mov    %eax,(%esp)
801093ab:	e8 1a cb ff ff       	call   80105eca <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
801093b0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801093b3:	89 04 24             	mov    %eax,(%esp)
801093b6:	e8 d8 f5 ff ff       	call   80108993 <v2p>
801093bb:	8b 55 f4             	mov    -0xc(%ebp),%edx
801093be:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
801093c5:	00 
801093c6:	89 44 24 0c          	mov    %eax,0xc(%esp)
801093ca:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801093d1:	00 
801093d2:	89 54 24 04          	mov    %edx,0x4(%esp)
801093d6:	8b 45 08             	mov    0x8(%ebp),%eax
801093d9:	89 04 24             	mov    %eax,(%esp)
801093dc:	e8 d8 fa ff ff       	call   80108eb9 <mappages>
  if(newsz >= KERNBASE)
    return 0;
  if(newsz < oldsz)
    return oldsz;
  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
801093e1:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801093e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801093eb:	3b 45 10             	cmp    0x10(%ebp),%eax
801093ee:	0f 82 67 ff ff ff    	jb     8010935b <allocuvm+0x3c>
      return 0;
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
  }
  return newsz;
801093f4:	8b 45 10             	mov    0x10(%ebp),%eax
}
801093f7:	c9                   	leave  
801093f8:	c3                   	ret    

801093f9 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
801093f9:	55                   	push   %ebp
801093fa:	89 e5                	mov    %esp,%ebp
801093fc:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
801093ff:	8b 45 10             	mov    0x10(%ebp),%eax
80109402:	3b 45 0c             	cmp    0xc(%ebp),%eax
80109405:	72 08                	jb     8010940f <deallocuvm+0x16>
    return oldsz;
80109407:	8b 45 0c             	mov    0xc(%ebp),%eax
8010940a:	e9 a4 00 00 00       	jmp    801094b3 <deallocuvm+0xba>

  a = PGROUNDUP(newsz);
8010940f:	8b 45 10             	mov    0x10(%ebp),%eax
80109412:	05 ff 0f 00 00       	add    $0xfff,%eax
80109417:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010941c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
8010941f:	e9 80 00 00 00       	jmp    801094a4 <deallocuvm+0xab>
    pte = walkpgdir(pgdir, (char*)a, 0);
80109424:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109427:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010942e:	00 
8010942f:	89 44 24 04          	mov    %eax,0x4(%esp)
80109433:	8b 45 08             	mov    0x8(%ebp),%eax
80109436:	89 04 24             	mov    %eax,(%esp)
80109439:	e8 e5 f9 ff ff       	call   80108e23 <walkpgdir>
8010943e:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(!pte)
80109441:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80109445:	75 09                	jne    80109450 <deallocuvm+0x57>
      a += (NPTENTRIES - 1) * PGSIZE;
80109447:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
8010944e:	eb 4d                	jmp    8010949d <deallocuvm+0xa4>
    else if((*pte & PTE_P) != 0){
80109450:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109453:	8b 00                	mov    (%eax),%eax
80109455:	83 e0 01             	and    $0x1,%eax
80109458:	84 c0                	test   %al,%al
8010945a:	74 41                	je     8010949d <deallocuvm+0xa4>
      pa = PTE_ADDR(*pte);
8010945c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010945f:	8b 00                	mov    (%eax),%eax
80109461:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109466:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if(pa == 0)
80109469:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
8010946d:	75 0c                	jne    8010947b <deallocuvm+0x82>
        panic("kfree");
8010946f:	c7 04 24 8d 9f 10 80 	movl   $0x80109f8d,(%esp)
80109476:	e8 c2 70 ff ff       	call   8010053d <panic>
      char *v = p2v(pa);
8010947b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010947e:	89 04 24             	mov    %eax,(%esp)
80109481:	e8 1a f5 ff ff       	call   801089a0 <p2v>
80109486:	89 45 e8             	mov    %eax,-0x18(%ebp)
      kfree(v);
80109489:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010948c:	89 04 24             	mov    %eax,(%esp)
8010948f:	e8 e3 95 ff ff       	call   80102a77 <kfree>
      *pte = 0;
80109494:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109497:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
8010949d:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801094a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801094a7:	3b 45 0c             	cmp    0xc(%ebp),%eax
801094aa:	0f 82 74 ff ff ff    	jb     80109424 <deallocuvm+0x2b>
      char *v = p2v(pa);
      kfree(v);
      *pte = 0;
    }
  }
  return newsz;
801094b0:	8b 45 10             	mov    0x10(%ebp),%eax
}
801094b3:	c9                   	leave  
801094b4:	c3                   	ret    

801094b5 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
801094b5:	55                   	push   %ebp
801094b6:	89 e5                	mov    %esp,%ebp
801094b8:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
801094bb:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801094bf:	75 0c                	jne    801094cd <freevm+0x18>
    panic("freevm: no pgdir");
801094c1:	c7 04 24 93 9f 10 80 	movl   $0x80109f93,(%esp)
801094c8:	e8 70 70 ff ff       	call   8010053d <panic>
  deallocuvm(pgdir, KERNBASE, 0);
801094cd:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801094d4:	00 
801094d5:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
801094dc:	80 
801094dd:	8b 45 08             	mov    0x8(%ebp),%eax
801094e0:	89 04 24             	mov    %eax,(%esp)
801094e3:	e8 11 ff ff ff       	call   801093f9 <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
801094e8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801094ef:	eb 3c                	jmp    8010952d <freevm+0x78>
    if(pgdir[i] & PTE_P){
801094f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801094f4:	c1 e0 02             	shl    $0x2,%eax
801094f7:	03 45 08             	add    0x8(%ebp),%eax
801094fa:	8b 00                	mov    (%eax),%eax
801094fc:	83 e0 01             	and    $0x1,%eax
801094ff:	84 c0                	test   %al,%al
80109501:	74 26                	je     80109529 <freevm+0x74>
      char * v = p2v(PTE_ADDR(pgdir[i]));
80109503:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109506:	c1 e0 02             	shl    $0x2,%eax
80109509:	03 45 08             	add    0x8(%ebp),%eax
8010950c:	8b 00                	mov    (%eax),%eax
8010950e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109513:	89 04 24             	mov    %eax,(%esp)
80109516:	e8 85 f4 ff ff       	call   801089a0 <p2v>
8010951b:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
8010951e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109521:	89 04 24             	mov    %eax,(%esp)
80109524:	e8 4e 95 ff ff       	call   80102a77 <kfree>
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
  for(i = 0; i < NPDENTRIES; i++){
80109529:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010952d:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
80109534:	76 bb                	jbe    801094f1 <freevm+0x3c>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
80109536:	8b 45 08             	mov    0x8(%ebp),%eax
80109539:	89 04 24             	mov    %eax,(%esp)
8010953c:	e8 36 95 ff ff       	call   80102a77 <kfree>
}
80109541:	c9                   	leave  
80109542:	c3                   	ret    

80109543 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80109543:	55                   	push   %ebp
80109544:	89 e5                	mov    %esp,%ebp
80109546:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80109549:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80109550:	00 
80109551:	8b 45 0c             	mov    0xc(%ebp),%eax
80109554:	89 44 24 04          	mov    %eax,0x4(%esp)
80109558:	8b 45 08             	mov    0x8(%ebp),%eax
8010955b:	89 04 24             	mov    %eax,(%esp)
8010955e:	e8 c0 f8 ff ff       	call   80108e23 <walkpgdir>
80109563:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
80109566:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010956a:	75 0c                	jne    80109578 <clearpteu+0x35>
    panic("clearpteu");
8010956c:	c7 04 24 a4 9f 10 80 	movl   $0x80109fa4,(%esp)
80109573:	e8 c5 6f ff ff       	call   8010053d <panic>
  *pte &= ~PTE_U;
80109578:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010957b:	8b 00                	mov    (%eax),%eax
8010957d:	89 c2                	mov    %eax,%edx
8010957f:	83 e2 fb             	and    $0xfffffffb,%edx
80109582:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109585:	89 10                	mov    %edx,(%eax)
}
80109587:	c9                   	leave  
80109588:	c3                   	ret    

80109589 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
80109589:	55                   	push   %ebp
8010958a:	89 e5                	mov    %esp,%ebp
8010958c:	83 ec 48             	sub    $0x48,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
8010958f:	e8 b9 f9 ff ff       	call   80108f4d <setupkvm>
80109594:	89 45 f0             	mov    %eax,-0x10(%ebp)
80109597:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010959b:	75 0a                	jne    801095a7 <copyuvm+0x1e>
    return 0;
8010959d:	b8 00 00 00 00       	mov    $0x0,%eax
801095a2:	e9 f1 00 00 00       	jmp    80109698 <copyuvm+0x10f>
  for(i = 0; i < sz; i += PGSIZE){
801095a7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801095ae:	e9 c0 00 00 00       	jmp    80109673 <copyuvm+0xea>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
801095b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801095b6:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801095bd:	00 
801095be:	89 44 24 04          	mov    %eax,0x4(%esp)
801095c2:	8b 45 08             	mov    0x8(%ebp),%eax
801095c5:	89 04 24             	mov    %eax,(%esp)
801095c8:	e8 56 f8 ff ff       	call   80108e23 <walkpgdir>
801095cd:	89 45 ec             	mov    %eax,-0x14(%ebp)
801095d0:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801095d4:	75 0c                	jne    801095e2 <copyuvm+0x59>
      panic("copyuvm: pte should exist");
801095d6:	c7 04 24 ae 9f 10 80 	movl   $0x80109fae,(%esp)
801095dd:	e8 5b 6f ff ff       	call   8010053d <panic>
    if(!(*pte & PTE_P))
801095e2:	8b 45 ec             	mov    -0x14(%ebp),%eax
801095e5:	8b 00                	mov    (%eax),%eax
801095e7:	83 e0 01             	and    $0x1,%eax
801095ea:	85 c0                	test   %eax,%eax
801095ec:	75 0c                	jne    801095fa <copyuvm+0x71>
      panic("copyuvm: page not present");
801095ee:	c7 04 24 c8 9f 10 80 	movl   $0x80109fc8,(%esp)
801095f5:	e8 43 6f ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
801095fa:	8b 45 ec             	mov    -0x14(%ebp),%eax
801095fd:	8b 00                	mov    (%eax),%eax
801095ff:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109604:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if((mem = kalloc()) == 0)
80109607:	e8 04 95 ff ff       	call   80102b10 <kalloc>
8010960c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010960f:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80109613:	74 6f                	je     80109684 <copyuvm+0xfb>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
80109615:	8b 45 e8             	mov    -0x18(%ebp),%eax
80109618:	89 04 24             	mov    %eax,(%esp)
8010961b:	e8 80 f3 ff ff       	call   801089a0 <p2v>
80109620:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80109627:	00 
80109628:	89 44 24 04          	mov    %eax,0x4(%esp)
8010962c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010962f:	89 04 24             	mov    %eax,(%esp)
80109632:	e8 66 c9 ff ff       	call   80105f9d <memmove>
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
80109637:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010963a:	89 04 24             	mov    %eax,(%esp)
8010963d:	e8 51 f3 ff ff       	call   80108993 <v2p>
80109642:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109645:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
8010964c:	00 
8010964d:	89 44 24 0c          	mov    %eax,0xc(%esp)
80109651:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80109658:	00 
80109659:	89 54 24 04          	mov    %edx,0x4(%esp)
8010965d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109660:	89 04 24             	mov    %eax,(%esp)
80109663:	e8 51 f8 ff ff       	call   80108eb9 <mappages>
80109668:	85 c0                	test   %eax,%eax
8010966a:	78 1b                	js     80109687 <copyuvm+0xfe>
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
8010966c:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80109673:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109676:	3b 45 0c             	cmp    0xc(%ebp),%eax
80109679:	0f 82 34 ff ff ff    	jb     801095b3 <copyuvm+0x2a>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
  }
  return d;
8010967f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109682:	eb 14                	jmp    80109698 <copyuvm+0x10f>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
    if((mem = kalloc()) == 0)
      goto bad;
80109684:	90                   	nop
80109685:	eb 01                	jmp    80109688 <copyuvm+0xff>
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
80109687:	90                   	nop
  }
  return d;

bad:
  freevm(d);
80109688:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010968b:	89 04 24             	mov    %eax,(%esp)
8010968e:	e8 22 fe ff ff       	call   801094b5 <freevm>
  return 0;
80109693:	b8 00 00 00 00       	mov    $0x0,%eax
}
80109698:	c9                   	leave  
80109699:	c3                   	ret    

8010969a <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
8010969a:	55                   	push   %ebp
8010969b:	89 e5                	mov    %esp,%ebp
8010969d:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801096a0:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801096a7:	00 
801096a8:	8b 45 0c             	mov    0xc(%ebp),%eax
801096ab:	89 44 24 04          	mov    %eax,0x4(%esp)
801096af:	8b 45 08             	mov    0x8(%ebp),%eax
801096b2:	89 04 24             	mov    %eax,(%esp)
801096b5:	e8 69 f7 ff ff       	call   80108e23 <walkpgdir>
801096ba:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
801096bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801096c0:	8b 00                	mov    (%eax),%eax
801096c2:	83 e0 01             	and    $0x1,%eax
801096c5:	85 c0                	test   %eax,%eax
801096c7:	75 07                	jne    801096d0 <uva2ka+0x36>
    return 0;
801096c9:	b8 00 00 00 00       	mov    $0x0,%eax
801096ce:	eb 25                	jmp    801096f5 <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
801096d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801096d3:	8b 00                	mov    (%eax),%eax
801096d5:	83 e0 04             	and    $0x4,%eax
801096d8:	85 c0                	test   %eax,%eax
801096da:	75 07                	jne    801096e3 <uva2ka+0x49>
    return 0;
801096dc:	b8 00 00 00 00       	mov    $0x0,%eax
801096e1:	eb 12                	jmp    801096f5 <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
801096e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801096e6:	8b 00                	mov    (%eax),%eax
801096e8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801096ed:	89 04 24             	mov    %eax,(%esp)
801096f0:	e8 ab f2 ff ff       	call   801089a0 <p2v>
}
801096f5:	c9                   	leave  
801096f6:	c3                   	ret    

801096f7 <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
801096f7:	55                   	push   %ebp
801096f8:	89 e5                	mov    %esp,%ebp
801096fa:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
801096fd:	8b 45 10             	mov    0x10(%ebp),%eax
80109700:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
80109703:	e9 8b 00 00 00       	jmp    80109793 <copyout+0x9c>
    va0 = (uint)PGROUNDDOWN(va);
80109708:	8b 45 0c             	mov    0xc(%ebp),%eax
8010970b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109710:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
80109713:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109716:	89 44 24 04          	mov    %eax,0x4(%esp)
8010971a:	8b 45 08             	mov    0x8(%ebp),%eax
8010971d:	89 04 24             	mov    %eax,(%esp)
80109720:	e8 75 ff ff ff       	call   8010969a <uva2ka>
80109725:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
80109728:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
8010972c:	75 07                	jne    80109735 <copyout+0x3e>
      return -1;
8010972e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80109733:	eb 6d                	jmp    801097a2 <copyout+0xab>
    n = PGSIZE - (va - va0);
80109735:	8b 45 0c             	mov    0xc(%ebp),%eax
80109738:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010973b:	89 d1                	mov    %edx,%ecx
8010973d:	29 c1                	sub    %eax,%ecx
8010973f:	89 c8                	mov    %ecx,%eax
80109741:	05 00 10 00 00       	add    $0x1000,%eax
80109746:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
80109749:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010974c:	3b 45 14             	cmp    0x14(%ebp),%eax
8010974f:	76 06                	jbe    80109757 <copyout+0x60>
      n = len;
80109751:	8b 45 14             	mov    0x14(%ebp),%eax
80109754:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
80109757:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010975a:	8b 55 0c             	mov    0xc(%ebp),%edx
8010975d:	89 d1                	mov    %edx,%ecx
8010975f:	29 c1                	sub    %eax,%ecx
80109761:	89 c8                	mov    %ecx,%eax
80109763:	03 45 e8             	add    -0x18(%ebp),%eax
80109766:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109769:	89 54 24 08          	mov    %edx,0x8(%esp)
8010976d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109770:	89 54 24 04          	mov    %edx,0x4(%esp)
80109774:	89 04 24             	mov    %eax,(%esp)
80109777:	e8 21 c8 ff ff       	call   80105f9d <memmove>
    len -= n;
8010977c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010977f:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
80109782:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109785:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
80109788:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010978b:	05 00 10 00 00       	add    $0x1000,%eax
80109790:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
80109793:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
80109797:	0f 85 6b ff ff ff    	jne    80109708 <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
8010979d:	b8 00 00 00 00       	mov    $0x0,%eax
}
801097a2:	c9                   	leave  
801097a3:	c3                   	ret    
