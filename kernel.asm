
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
80100015:	b8 00 c0 10 00       	mov    $0x10c000,%eax
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
80100028:	bc 80 e6 10 80       	mov    $0x8010e680,%esp

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $main, %eax
8010002d:	b8 13 3e 10 80       	mov    $0x80103e13,%eax
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
8010003a:	c7 44 24 04 2c 98 10 	movl   $0x8010982c,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 80 e6 10 80 	movl   $0x8010e680,(%esp)
80100049:	e8 80 5c 00 00       	call   80105cce <initlock>

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
8010004e:	c7 05 b0 fb 10 80 a4 	movl   $0x8010fba4,0x8010fbb0
80100055:	fb 10 80 
  bcache.head.next = &bcache.head;
80100058:	c7 05 b4 fb 10 80 a4 	movl   $0x8010fba4,0x8010fbb4
8010005f:	fb 10 80 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
80100062:	c7 45 f4 b4 e6 10 80 	movl   $0x8010e6b4,-0xc(%ebp)
80100069:	eb 3a                	jmp    801000a5 <binit+0x71>
    b->next = bcache.head.next;
8010006b:	8b 15 b4 fb 10 80    	mov    0x8010fbb4,%edx
80100071:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100074:	89 50 10             	mov    %edx,0x10(%eax)
    b->prev = &bcache.head;
80100077:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010007a:	c7 40 0c a4 fb 10 80 	movl   $0x8010fba4,0xc(%eax)
    b->dev = -1;
80100081:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100084:	c7 40 04 ff ff ff ff 	movl   $0xffffffff,0x4(%eax)
    bcache.head.next->prev = b;
8010008b:	a1 b4 fb 10 80       	mov    0x8010fbb4,%eax
80100090:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100093:	89 50 0c             	mov    %edx,0xc(%eax)
    bcache.head.next = b;
80100096:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100099:	a3 b4 fb 10 80       	mov    %eax,0x8010fbb4

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
  bcache.head.next = &bcache.head;
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
8010009e:	81 45 f4 18 02 00 00 	addl   $0x218,-0xc(%ebp)
801000a5:	81 7d f4 a4 fb 10 80 	cmpl   $0x8010fba4,-0xc(%ebp)
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
801000b6:	c7 04 24 80 e6 10 80 	movl   $0x8010e680,(%esp)
801000bd:	e8 2d 5c 00 00       	call   80105cef <acquire>

 loop:
  // Is the sector already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
801000c2:	a1 b4 fb 10 80       	mov    0x8010fbb4,%eax
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
801000fd:	c7 04 24 80 e6 10 80 	movl   $0x8010e680,(%esp)
80100104:	e8 81 5c 00 00       	call   80105d8a <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 80 e6 10 	movl   $0x8010e680,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 8c 57 00 00       	call   801058b0 <sleep>
      goto loop;
80100124:	eb 9c                	jmp    801000c2 <bget+0x12>

  acquire(&bcache.lock);

 loop:
  // Is the sector already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
80100126:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100129:	8b 40 10             	mov    0x10(%eax),%eax
8010012c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010012f:	81 7d f4 a4 fb 10 80 	cmpl   $0x8010fba4,-0xc(%ebp)
80100136:	75 94                	jne    801000cc <bget+0x1c>
      goto loop;
    }
  }

  // Not cached; recycle some non-busy and clean buffer.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100138:	a1 b0 fb 10 80       	mov    0x8010fbb0,%eax
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
80100175:	c7 04 24 80 e6 10 80 	movl   $0x8010e680,(%esp)
8010017c:	e8 09 5c 00 00       	call   80105d8a <release>
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
8010018f:	81 7d f4 a4 fb 10 80 	cmpl   $0x8010fba4,-0xc(%ebp)
80100196:	75 aa                	jne    80100142 <bget+0x92>
      b->flags = B_BUSY;
      release(&bcache.lock);
      return b;
    }
  }
  panic("bget: no buffers");
80100198:	c7 04 24 33 98 10 80 	movl   $0x80109833,(%esp)
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
801001ef:	c7 04 24 44 98 10 80 	movl   $0x80109844,(%esp)
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
80100229:	c7 04 24 4b 98 10 80 	movl   $0x8010984b,(%esp)
80100230:	e8 08 03 00 00       	call   8010053d <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 80 e6 10 80 	movl   $0x8010e680,(%esp)
8010023c:	e8 ae 5a 00 00       	call   80105cef <acquire>

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
8010025f:	8b 15 b4 fb 10 80    	mov    0x8010fbb4,%edx
80100265:	8b 45 08             	mov    0x8(%ebp),%eax
80100268:	89 50 10             	mov    %edx,0x10(%eax)
  b->prev = &bcache.head;
8010026b:	8b 45 08             	mov    0x8(%ebp),%eax
8010026e:	c7 40 0c a4 fb 10 80 	movl   $0x8010fba4,0xc(%eax)
  bcache.head.next->prev = b;
80100275:	a1 b4 fb 10 80       	mov    0x8010fbb4,%eax
8010027a:	8b 55 08             	mov    0x8(%ebp),%edx
8010027d:	89 50 0c             	mov    %edx,0xc(%eax)
  bcache.head.next = b;
80100280:	8b 45 08             	mov    0x8(%ebp),%eax
80100283:	a3 b4 fb 10 80       	mov    %eax,0x8010fbb4

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
8010029d:	e8 4a 57 00 00       	call   801059ec <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 80 e6 10 80 	movl   $0x8010e680,(%esp)
801002a9:	e8 dc 5a 00 00       	call   80105d8a <release>
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
8010033f:	0f b6 90 04 b0 10 80 	movzbl -0x7fef4ffc(%eax),%edx
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
801003a7:	a1 14 d6 10 80       	mov    0x8010d614,%eax
801003ac:	89 45 e8             	mov    %eax,-0x18(%ebp)
  if(locking)
801003af:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801003b3:	74 0c                	je     801003c1 <cprintf+0x20>
    acquire(&cons.lock);
801003b5:	c7 04 24 e0 d5 10 80 	movl   $0x8010d5e0,(%esp)
801003bc:	e8 2e 59 00 00       	call   80105cef <acquire>

  if (fmt == 0)
801003c1:	8b 45 08             	mov    0x8(%ebp),%eax
801003c4:	85 c0                	test   %eax,%eax
801003c6:	75 0c                	jne    801003d4 <cprintf+0x33>
    panic("null fmt");
801003c8:	c7 04 24 52 98 10 80 	movl   $0x80109852,(%esp)
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
801004af:	c7 45 ec 5b 98 10 80 	movl   $0x8010985b,-0x14(%ebp)
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
8010052f:	c7 04 24 e0 d5 10 80 	movl   $0x8010d5e0,(%esp)
80100536:	e8 4f 58 00 00       	call   80105d8a <release>
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
80100548:	c7 05 14 d6 10 80 00 	movl   $0x0,0x8010d614
8010054f:	00 00 00 
  cprintf("cpu%d: panic: ", cpu->id);
80100552:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80100558:	0f b6 00             	movzbl (%eax),%eax
8010055b:	0f b6 c0             	movzbl %al,%eax
8010055e:	89 44 24 04          	mov    %eax,0x4(%esp)
80100562:	c7 04 24 62 98 10 80 	movl   $0x80109862,(%esp)
80100569:	e8 33 fe ff ff       	call   801003a1 <cprintf>
  cprintf(s);
8010056e:	8b 45 08             	mov    0x8(%ebp),%eax
80100571:	89 04 24             	mov    %eax,(%esp)
80100574:	e8 28 fe ff ff       	call   801003a1 <cprintf>
  cprintf("\n");
80100579:	c7 04 24 71 98 10 80 	movl   $0x80109871,(%esp)
80100580:	e8 1c fe ff ff       	call   801003a1 <cprintf>
  getcallerpcs(&s, pcs);
80100585:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100588:	89 44 24 04          	mov    %eax,0x4(%esp)
8010058c:	8d 45 08             	lea    0x8(%ebp),%eax
8010058f:	89 04 24             	mov    %eax,(%esp)
80100592:	e8 42 58 00 00       	call   80105dd9 <getcallerpcs>
  for(i=0; i<10; i++)
80100597:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010059e:	eb 1b                	jmp    801005bb <panic+0x7e>
    cprintf(" %p", pcs[i]);
801005a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005a3:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005a7:	89 44 24 04          	mov    %eax,0x4(%esp)
801005ab:	c7 04 24 73 98 10 80 	movl   $0x80109873,(%esp)
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
801005c1:	c7 05 c0 d5 10 80 01 	movl   $0x1,0x8010d5c0
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
8010066d:	a1 00 b0 10 80       	mov    0x8010b000,%eax
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
80100693:	a1 00 b0 10 80       	mov    0x8010b000,%eax
80100698:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
8010069e:	a1 00 b0 10 80       	mov    0x8010b000,%eax
801006a3:	c7 44 24 08 60 0e 00 	movl   $0xe60,0x8(%esp)
801006aa:	00 
801006ab:	89 54 24 04          	mov    %edx,0x4(%esp)
801006af:	89 04 24             	mov    %eax,(%esp)
801006b2:	e8 92 59 00 00       	call   80106049 <memmove>
    pos -= 80;
801006b7:	83 6d f4 50          	subl   $0x50,-0xc(%ebp)
    memset(crt+pos, 0, sizeof(crt[0])*(24*80 - pos));
801006bb:	b8 80 07 00 00       	mov    $0x780,%eax
801006c0:	2b 45 f4             	sub    -0xc(%ebp),%eax
801006c3:	01 c0                	add    %eax,%eax
801006c5:	8b 15 00 b0 10 80    	mov    0x8010b000,%edx
801006cb:	8b 4d f4             	mov    -0xc(%ebp),%ecx
801006ce:	01 c9                	add    %ecx,%ecx
801006d0:	01 ca                	add    %ecx,%edx
801006d2:	89 44 24 08          	mov    %eax,0x8(%esp)
801006d6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801006dd:	00 
801006de:	89 14 24             	mov    %edx,(%esp)
801006e1:	e8 90 58 00 00       	call   80105f76 <memset>
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
8010073d:	a1 00 b0 10 80       	mov    0x8010b000,%eax
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
80100756:	a1 c0 d5 10 80       	mov    0x8010d5c0,%eax
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
80100776:	e8 16 77 00 00       	call   80107e91 <uartputc>
8010077b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80100782:	e8 0a 77 00 00       	call   80107e91 <uartputc>
80100787:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
8010078e:	e8 fe 76 00 00       	call   80107e91 <uartputc>
80100793:	eb 0b                	jmp    801007a0 <consputc+0x50>
  } else
    uartputc(c);
80100795:	8b 45 08             	mov    0x8(%ebp),%eax
80100798:	89 04 24             	mov    %eax,(%esp)
8010079b:	e8 f1 76 00 00       	call   80107e91 <uartputc>
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
801007b3:	c7 04 24 c0 fd 10 80 	movl   $0x8010fdc0,(%esp)
801007ba:	e8 30 55 00 00       	call   80105cef <acquire>
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
801007ea:	e8 c6 52 00 00       	call   80105ab5 <procdump>
      break;
801007ef:	e9 11 01 00 00       	jmp    80100905 <consoleintr+0x158>
    case C('U'):  // Kill line.
      while(input.e != input.w &&
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
801007f4:	a1 7c fe 10 80       	mov    0x8010fe7c,%eax
801007f9:	83 e8 01             	sub    $0x1,%eax
801007fc:	a3 7c fe 10 80       	mov    %eax,0x8010fe7c
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
80100810:	8b 15 7c fe 10 80    	mov    0x8010fe7c,%edx
80100816:	a1 78 fe 10 80       	mov    0x8010fe78,%eax
8010081b:	39 c2                	cmp    %eax,%edx
8010081d:	0f 84 db 00 00 00    	je     801008fe <consoleintr+0x151>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
80100823:	a1 7c fe 10 80       	mov    0x8010fe7c,%eax
80100828:	83 e8 01             	sub    $0x1,%eax
8010082b:	83 e0 7f             	and    $0x7f,%eax
8010082e:	0f b6 80 f4 fd 10 80 	movzbl -0x7fef020c(%eax),%eax
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
8010083e:	8b 15 7c fe 10 80    	mov    0x8010fe7c,%edx
80100844:	a1 78 fe 10 80       	mov    0x8010fe78,%eax
80100849:	39 c2                	cmp    %eax,%edx
8010084b:	0f 84 b0 00 00 00    	je     80100901 <consoleintr+0x154>
        input.e--;
80100851:	a1 7c fe 10 80       	mov    0x8010fe7c,%eax
80100856:	83 e8 01             	sub    $0x1,%eax
80100859:	a3 7c fe 10 80       	mov    %eax,0x8010fe7c
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
80100879:	8b 15 7c fe 10 80    	mov    0x8010fe7c,%edx
8010087f:	a1 74 fe 10 80       	mov    0x8010fe74,%eax
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
801008a2:	a1 7c fe 10 80       	mov    0x8010fe7c,%eax
801008a7:	89 c1                	mov    %eax,%ecx
801008a9:	83 e1 7f             	and    $0x7f,%ecx
801008ac:	8b 55 f4             	mov    -0xc(%ebp),%edx
801008af:	88 91 f4 fd 10 80    	mov    %dl,-0x7fef020c(%ecx)
801008b5:	83 c0 01             	add    $0x1,%eax
801008b8:	a3 7c fe 10 80       	mov    %eax,0x8010fe7c
        consputc(c);
801008bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801008c0:	89 04 24             	mov    %eax,(%esp)
801008c3:	e8 88 fe ff ff       	call   80100750 <consputc>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
801008c8:	83 7d f4 0a          	cmpl   $0xa,-0xc(%ebp)
801008cc:	74 18                	je     801008e6 <consoleintr+0x139>
801008ce:	83 7d f4 04          	cmpl   $0x4,-0xc(%ebp)
801008d2:	74 12                	je     801008e6 <consoleintr+0x139>
801008d4:	a1 7c fe 10 80       	mov    0x8010fe7c,%eax
801008d9:	8b 15 74 fe 10 80    	mov    0x8010fe74,%edx
801008df:	83 ea 80             	sub    $0xffffff80,%edx
801008e2:	39 d0                	cmp    %edx,%eax
801008e4:	75 1e                	jne    80100904 <consoleintr+0x157>
          input.w = input.e;
801008e6:	a1 7c fe 10 80       	mov    0x8010fe7c,%eax
801008eb:	a3 78 fe 10 80       	mov    %eax,0x8010fe78
          wakeup(&input.r);
801008f0:	c7 04 24 74 fe 10 80 	movl   $0x8010fe74,(%esp)
801008f7:	e8 f0 50 00 00       	call   801059ec <wakeup>
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
80100917:	c7 04 24 c0 fd 10 80 	movl   $0x8010fdc0,(%esp)
8010091e:	e8 67 54 00 00       	call   80105d8a <release>
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
8010093c:	c7 04 24 c0 fd 10 80 	movl   $0x8010fdc0,(%esp)
80100943:	e8 a7 53 00 00       	call   80105cef <acquire>
  while(n > 0){
80100948:	e9 a8 00 00 00       	jmp    801009f5 <consoleread+0xd0>
    while(input.r == input.w){
      if(proc->killed){
8010094d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100953:	8b 40 24             	mov    0x24(%eax),%eax
80100956:	85 c0                	test   %eax,%eax
80100958:	74 21                	je     8010097b <consoleread+0x56>
        release(&input.lock);
8010095a:	c7 04 24 c0 fd 10 80 	movl   $0x8010fdc0,(%esp)
80100961:	e8 24 54 00 00       	call   80105d8a <release>
        ilock(ip);
80100966:	8b 45 08             	mov    0x8(%ebp),%eax
80100969:	89 04 24             	mov    %eax,(%esp)
8010096c:	e8 f7 0e 00 00       	call   80101868 <ilock>
        return -1;
80100971:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100976:	e9 a9 00 00 00       	jmp    80100a24 <consoleread+0xff>
      }
      sleep(&input.r, &input.lock);
8010097b:	c7 44 24 04 c0 fd 10 	movl   $0x8010fdc0,0x4(%esp)
80100982:	80 
80100983:	c7 04 24 74 fe 10 80 	movl   $0x8010fe74,(%esp)
8010098a:	e8 21 4f 00 00       	call   801058b0 <sleep>
8010098f:	eb 01                	jmp    80100992 <consoleread+0x6d>

  iunlock(ip);
  target = n;
  acquire(&input.lock);
  while(n > 0){
    while(input.r == input.w){
80100991:	90                   	nop
80100992:	8b 15 74 fe 10 80    	mov    0x8010fe74,%edx
80100998:	a1 78 fe 10 80       	mov    0x8010fe78,%eax
8010099d:	39 c2                	cmp    %eax,%edx
8010099f:	74 ac                	je     8010094d <consoleread+0x28>
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &input.lock);
    }
    c = input.buf[input.r++ % INPUT_BUF];
801009a1:	a1 74 fe 10 80       	mov    0x8010fe74,%eax
801009a6:	89 c2                	mov    %eax,%edx
801009a8:	83 e2 7f             	and    $0x7f,%edx
801009ab:	0f b6 92 f4 fd 10 80 	movzbl -0x7fef020c(%edx),%edx
801009b2:	0f be d2             	movsbl %dl,%edx
801009b5:	89 55 f0             	mov    %edx,-0x10(%ebp)
801009b8:	83 c0 01             	add    $0x1,%eax
801009bb:	a3 74 fe 10 80       	mov    %eax,0x8010fe74
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
801009ce:	a1 74 fe 10 80       	mov    0x8010fe74,%eax
801009d3:	83 e8 01             	sub    $0x1,%eax
801009d6:	a3 74 fe 10 80       	mov    %eax,0x8010fe74
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
80100a01:	c7 04 24 c0 fd 10 80 	movl   $0x8010fdc0,(%esp)
80100a08:	e8 7d 53 00 00       	call   80105d8a <release>
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
80100a37:	c7 04 24 e0 d5 10 80 	movl   $0x8010d5e0,(%esp)
80100a3e:	e8 ac 52 00 00       	call   80105cef <acquire>
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
80100a71:	c7 04 24 e0 d5 10 80 	movl   $0x8010d5e0,(%esp)
80100a78:	e8 0d 53 00 00       	call   80105d8a <release>
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
80100a93:	c7 44 24 04 77 98 10 	movl   $0x80109877,0x4(%esp)
80100a9a:	80 
80100a9b:	c7 04 24 e0 d5 10 80 	movl   $0x8010d5e0,(%esp)
80100aa2:	e8 27 52 00 00       	call   80105cce <initlock>
  initlock(&input.lock, "input");
80100aa7:	c7 44 24 04 7f 98 10 	movl   $0x8010987f,0x4(%esp)
80100aae:	80 
80100aaf:	c7 04 24 c0 fd 10 80 	movl   $0x8010fdc0,(%esp)
80100ab6:	e8 13 52 00 00       	call   80105cce <initlock>

  devsw[CONSOLE].write = consolewrite;
80100abb:	c7 05 2c 08 11 80 26 	movl   $0x80100a26,0x8011082c
80100ac2:	0a 10 80 
  devsw[CONSOLE].read = consoleread;
80100ac5:	c7 05 28 08 11 80 25 	movl   $0x80100925,0x80110828
80100acc:	09 10 80 
  cons.locking = 1;
80100acf:	c7 05 14 d6 10 80 01 	movl   $0x1,0x8010d614
80100ad6:	00 00 00 

  picenable(IRQ_KBD);
80100ad9:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100ae0:	e8 e8 39 00 00       	call   801044cd <picenable>
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
80100b7b:	e8 55 84 00 00       	call   80108fd5 <setupkvm>
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
80100c14:	e8 8e 87 00 00       	call   801093a7 <allocuvm>
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
80100c51:	e8 62 86 00 00       	call   801092b8 <loaduvm>
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
80100cbc:	e8 e6 86 00 00       	call   801093a7 <allocuvm>
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
80100ce0:	e8 e6 88 00 00       	call   801095cb <clearpteu>
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
80100d0f:	e8 e0 54 00 00       	call   801061f4 <strlen>
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
80100d2d:	e8 c2 54 00 00       	call   801061f4 <strlen>
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
80100d57:	e8 23 8a 00 00       	call   8010977f <copyout>
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
80100df7:	e8 83 89 00 00       	call   8010977f <copyout>
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
80100e4e:	e8 53 53 00 00       	call   801061a6 <safestrcpy>

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
80100ea0:	e8 21 82 00 00       	call   801090c6 <switchuvm>
  freevm(oldpgdir);
80100ea5:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100ea8:	89 04 24             	mov    %eax,(%esp)
80100eab:	e8 8d 86 00 00       	call   8010953d <freevm>
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
80100ee2:	e8 56 86 00 00       	call   8010953d <freevm>
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
80100f06:	c7 44 24 04 85 98 10 	movl   $0x80109885,0x4(%esp)
80100f0d:	80 
80100f0e:	c7 04 24 80 fe 10 80 	movl   $0x8010fe80,(%esp)
80100f15:	e8 b4 4d 00 00       	call   80105cce <initlock>
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
80100f22:	c7 04 24 80 fe 10 80 	movl   $0x8010fe80,(%esp)
80100f29:	e8 c1 4d 00 00       	call   80105cef <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100f2e:	c7 45 f4 b4 fe 10 80 	movl   $0x8010feb4,-0xc(%ebp)
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
80100f4b:	c7 04 24 80 fe 10 80 	movl   $0x8010fe80,(%esp)
80100f52:	e8 33 4e 00 00       	call   80105d8a <release>
      return f;
80100f57:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f5a:	eb 1e                	jmp    80100f7a <filealloc+0x5e>
filealloc(void)
{
  struct file *f;

  acquire(&ftable.lock);
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100f5c:	83 45 f4 18          	addl   $0x18,-0xc(%ebp)
80100f60:	81 7d f4 14 08 11 80 	cmpl   $0x80110814,-0xc(%ebp)
80100f67:	72 ce                	jb     80100f37 <filealloc+0x1b>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
80100f69:	c7 04 24 80 fe 10 80 	movl   $0x8010fe80,(%esp)
80100f70:	e8 15 4e 00 00       	call   80105d8a <release>
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
80100f82:	c7 04 24 80 fe 10 80 	movl   $0x8010fe80,(%esp)
80100f89:	e8 61 4d 00 00       	call   80105cef <acquire>
  if(f->ref < 1)
80100f8e:	8b 45 08             	mov    0x8(%ebp),%eax
80100f91:	8b 40 04             	mov    0x4(%eax),%eax
80100f94:	85 c0                	test   %eax,%eax
80100f96:	7f 0c                	jg     80100fa4 <filedup+0x28>
    panic("filedup");
80100f98:	c7 04 24 8c 98 10 80 	movl   $0x8010988c,(%esp)
80100f9f:	e8 99 f5 ff ff       	call   8010053d <panic>
  f->ref++;
80100fa4:	8b 45 08             	mov    0x8(%ebp),%eax
80100fa7:	8b 40 04             	mov    0x4(%eax),%eax
80100faa:	8d 50 01             	lea    0x1(%eax),%edx
80100fad:	8b 45 08             	mov    0x8(%ebp),%eax
80100fb0:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
80100fb3:	c7 04 24 80 fe 10 80 	movl   $0x8010fe80,(%esp)
80100fba:	e8 cb 4d 00 00       	call   80105d8a <release>
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
80100fca:	c7 04 24 80 fe 10 80 	movl   $0x8010fe80,(%esp)
80100fd1:	e8 19 4d 00 00       	call   80105cef <acquire>
  if(f->ref < 1)
80100fd6:	8b 45 08             	mov    0x8(%ebp),%eax
80100fd9:	8b 40 04             	mov    0x4(%eax),%eax
80100fdc:	85 c0                	test   %eax,%eax
80100fde:	7f 0c                	jg     80100fec <fileclose+0x28>
    panic("fileclose");
80100fe0:	c7 04 24 94 98 10 80 	movl   $0x80109894,(%esp)
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
80101005:	c7 04 24 80 fe 10 80 	movl   $0x8010fe80,(%esp)
8010100c:	e8 79 4d 00 00       	call   80105d8a <release>
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
8010104f:	c7 04 24 80 fe 10 80 	movl   $0x8010fe80,(%esp)
80101056:	e8 2f 4d 00 00       	call   80105d8a <release>
  
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
80101074:	e8 0e 37 00 00       	call   80104787 <pipeclose>
80101079:	eb 1d                	jmp    80101098 <fileclose+0xd4>
  else if(ff.type == FD_INODE){
8010107b:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010107e:	83 f8 02             	cmp    $0x2,%eax
80101081:	75 15                	jne    80101098 <fileclose+0xd4>
    begin_trans();
80101083:	e8 a1 2b 00 00       	call   80103c29 <begin_trans>
    iput(ff.ip);
80101088:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010108b:	89 04 24             	mov    %eax,(%esp)
8010108e:	e8 88 09 00 00       	call   80101a1b <iput>
    commit_trans();
80101093:	e8 da 2b 00 00       	call   80103c72 <commit_trans>
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
80101125:	e8 df 37 00 00       	call   80104909 <piperead>
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
80101197:	c7 04 24 9e 98 10 80 	movl   $0x8010989e,(%esp)
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
801011e2:	e8 32 36 00 00       	call   80104819 <pipewrite>
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
8010122a:	e8 fa 29 00 00       	call   80103c29 <begin_trans>
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
80101290:	e8 dd 29 00 00       	call   80103c72 <commit_trans>

      if(r < 0)
80101295:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80101299:	78 28                	js     801012c3 <filewrite+0x11e>
        break;
      if(r != n1)
8010129b:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010129e:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801012a1:	74 0c                	je     801012af <filewrite+0x10a>
        panic("short filewrite");
801012a3:	c7 04 24 a7 98 10 80 	movl   $0x801098a7,(%esp)
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
801012d8:	c7 04 24 b7 98 10 80 	movl   $0x801098b7,(%esp)
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
80101320:	e8 24 4d 00 00       	call   80106049 <memmove>
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
80101366:	e8 0b 4c 00 00       	call   80105f76 <memset>
  log_write(bp);
8010136b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010136e:	89 04 24             	mov    %eax,(%esp)
80101371:	e8 54 29 00 00       	call   80103cca <log_write>
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
80101457:	e8 6e 28 00 00       	call   80103cca <log_write>
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
801014ce:	c7 04 24 c1 98 10 80 	movl   $0x801098c1,(%esp)
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
80101565:	c7 04 24 d7 98 10 80 	movl   $0x801098d7,(%esp)
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
8010159d:	e8 28 27 00 00       	call   80103cca <log_write>
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
801015b9:	c7 44 24 04 ea 98 10 	movl   $0x801098ea,0x4(%esp)
801015c0:	80 
801015c1:	c7 04 24 80 08 11 80 	movl   $0x80110880,(%esp)
801015c8:	e8 01 47 00 00       	call   80105cce <initlock>
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
8010164a:	e8 27 49 00 00       	call   80105f76 <memset>
      dip->type = type;
8010164f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101652:	0f b7 55 d4          	movzwl -0x2c(%ebp),%edx
80101656:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
80101659:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010165c:	89 04 24             	mov    %eax,(%esp)
8010165f:	e8 66 26 00 00       	call   80103cca <log_write>
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
801016a0:	c7 04 24 f1 98 10 80 	movl   $0x801098f1,(%esp)
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
80101747:	e8 fd 48 00 00       	call   80106049 <memmove>
  log_write(bp);
8010174c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010174f:	89 04 24             	mov    %eax,(%esp)
80101752:	e8 73 25 00 00       	call   80103cca <log_write>
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
8010176a:	c7 04 24 80 08 11 80 	movl   $0x80110880,(%esp)
80101771:	e8 79 45 00 00       	call   80105cef <acquire>

  // Is the inode already cached?
  empty = 0;
80101776:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
8010177d:	c7 45 f4 b4 08 11 80 	movl   $0x801108b4,-0xc(%ebp)
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
801017b4:	c7 04 24 80 08 11 80 	movl   $0x80110880,(%esp)
801017bb:	e8 ca 45 00 00       	call   80105d8a <release>
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
801017df:	81 7d f4 54 18 11 80 	cmpl   $0x80111854,-0xc(%ebp)
801017e6:	72 9e                	jb     80101786 <iget+0x22>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
      empty = ip;
  }

  // Recycle an inode cache entry.
  if(empty == 0)
801017e8:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801017ec:	75 0c                	jne    801017fa <iget+0x96>
    panic("iget: no inodes");
801017ee:	c7 04 24 03 99 10 80 	movl   $0x80109903,(%esp)
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
80101825:	c7 04 24 80 08 11 80 	movl   $0x80110880,(%esp)
8010182c:	e8 59 45 00 00       	call   80105d8a <release>

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
8010183c:	c7 04 24 80 08 11 80 	movl   $0x80110880,(%esp)
80101843:	e8 a7 44 00 00       	call   80105cef <acquire>
  ip->ref++;
80101848:	8b 45 08             	mov    0x8(%ebp),%eax
8010184b:	8b 40 08             	mov    0x8(%eax),%eax
8010184e:	8d 50 01             	lea    0x1(%eax),%edx
80101851:	8b 45 08             	mov    0x8(%ebp),%eax
80101854:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101857:	c7 04 24 80 08 11 80 	movl   $0x80110880,(%esp)
8010185e:	e8 27 45 00 00       	call   80105d8a <release>
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
8010187e:	c7 04 24 13 99 10 80 	movl   $0x80109913,(%esp)
80101885:	e8 b3 ec ff ff       	call   8010053d <panic>

  acquire(&icache.lock);
8010188a:	c7 04 24 80 08 11 80 	movl   $0x80110880,(%esp)
80101891:	e8 59 44 00 00       	call   80105cef <acquire>
  while(ip->flags & I_BUSY)
80101896:	eb 13                	jmp    801018ab <ilock+0x43>
    sleep(ip, &icache.lock);
80101898:	c7 44 24 04 80 08 11 	movl   $0x80110880,0x4(%esp)
8010189f:	80 
801018a0:	8b 45 08             	mov    0x8(%ebp),%eax
801018a3:	89 04 24             	mov    %eax,(%esp)
801018a6:	e8 05 40 00 00       	call   801058b0 <sleep>

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
801018c9:	c7 04 24 80 08 11 80 	movl   $0x80110880,(%esp)
801018d0:	e8 b5 44 00 00       	call   80105d8a <release>

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
8010197b:	e8 c9 46 00 00       	call   80106049 <memmove>
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
801019a8:	c7 04 24 19 99 10 80 	movl   $0x80109919,(%esp)
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
801019d9:	c7 04 24 28 99 10 80 	movl   $0x80109928,(%esp)
801019e0:	e8 58 eb ff ff       	call   8010053d <panic>
  acquire(&icache.lock);
801019e5:	c7 04 24 80 08 11 80 	movl   $0x80110880,(%esp)
801019ec:	e8 fe 42 00 00       	call   80105cef <acquire>
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
80101a08:	e8 df 3f 00 00       	call   801059ec <wakeup>
  release(&icache.lock);
80101a0d:	c7 04 24 80 08 11 80 	movl   $0x80110880,(%esp)
80101a14:	e8 71 43 00 00       	call   80105d8a <release>
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
80101a21:	c7 04 24 80 08 11 80 	movl   $0x80110880,(%esp)
80101a28:	e8 c2 42 00 00       	call   80105cef <acquire>
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
80101a66:	c7 04 24 30 99 10 80 	movl   $0x80109930,(%esp)
80101a6d:	e8 cb ea ff ff       	call   8010053d <panic>
    ip->flags |= I_BUSY;
80101a72:	8b 45 08             	mov    0x8(%ebp),%eax
80101a75:	8b 40 0c             	mov    0xc(%eax),%eax
80101a78:	89 c2                	mov    %eax,%edx
80101a7a:	83 ca 01             	or     $0x1,%edx
80101a7d:	8b 45 08             	mov    0x8(%ebp),%eax
80101a80:	89 50 0c             	mov    %edx,0xc(%eax)
    release(&icache.lock);
80101a83:	c7 04 24 80 08 11 80 	movl   $0x80110880,(%esp)
80101a8a:	e8 fb 42 00 00       	call   80105d8a <release>
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
80101aae:	c7 04 24 80 08 11 80 	movl   $0x80110880,(%esp)
80101ab5:	e8 35 42 00 00       	call   80105cef <acquire>
    ip->flags = 0;
80101aba:	8b 45 08             	mov    0x8(%ebp),%eax
80101abd:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
80101ac4:	8b 45 08             	mov    0x8(%ebp),%eax
80101ac7:	89 04 24             	mov    %eax,(%esp)
80101aca:	e8 1d 3f 00 00       	call   801059ec <wakeup>
  }
  ip->ref--;
80101acf:	8b 45 08             	mov    0x8(%ebp),%eax
80101ad2:	8b 40 08             	mov    0x8(%eax),%eax
80101ad5:	8d 50 ff             	lea    -0x1(%eax),%edx
80101ad8:	8b 45 08             	mov    0x8(%ebp),%eax
80101adb:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101ade:	c7 04 24 80 08 11 80 	movl   $0x80110880,(%esp)
80101ae5:	e8 a0 42 00 00       	call   80105d8a <release>
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
80101be5:	e8 e0 20 00 00       	call   80103cca <log_write>
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
80101bfa:	c7 04 24 3a 99 10 80 	movl   $0x8010993a,(%esp)
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
80101d93:	8b 04 c5 20 08 11 80 	mov    -0x7feef7e0(,%eax,8),%eax
80101d9a:	85 c0                	test   %eax,%eax
80101d9c:	75 0a                	jne    80101da8 <readi+0x4a>
      return -1;
80101d9e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101da3:	e9 1b 01 00 00       	jmp    80101ec3 <readi+0x165>
    return devsw[ip->major].read(ip, dst, n);
80101da8:	8b 45 08             	mov    0x8(%ebp),%eax
80101dab:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101daf:	98                   	cwtl   
80101db0:	8b 14 c5 20 08 11 80 	mov    -0x7feef7e0(,%eax,8),%edx
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
80101e92:	e8 b2 41 00 00       	call   80106049 <memmove>
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
80101efe:	8b 04 c5 24 08 11 80 	mov    -0x7feef7dc(,%eax,8),%eax
80101f05:	85 c0                	test   %eax,%eax
80101f07:	75 0a                	jne    80101f13 <writei+0x4a>
      return -1;
80101f09:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101f0e:	e9 46 01 00 00       	jmp    80102059 <writei+0x190>
    return devsw[ip->major].write(ip, src, n);
80101f13:	8b 45 08             	mov    0x8(%ebp),%eax
80101f16:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101f1a:	98                   	cwtl   
80101f1b:	8b 14 c5 24 08 11 80 	mov    -0x7feef7dc(,%eax,8),%edx
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
80101ff8:	e8 4c 40 00 00       	call   80106049 <memmove>
    log_write(bp);
80101ffd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102000:	89 04 24             	mov    %eax,(%esp)
80102003:	e8 c2 1c 00 00       	call   80103cca <log_write>
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
8010207a:	e8 6e 40 00 00       	call   801060ed <strncmp>
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
80102094:	c7 04 24 4d 99 10 80 	movl   $0x8010994d,(%esp)
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
801020d2:	c7 04 24 5f 99 10 80 	movl   $0x8010995f,(%esp)
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
801021b6:	c7 04 24 5f 99 10 80 	movl   $0x8010995f,(%esp)
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
801021fc:	e8 44 3f 00 00       	call   80106145 <strncpy>
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
8010222e:	c7 04 24 6c 99 10 80 	movl   $0x8010996c,(%esp)
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
801022b5:	e8 8f 3d 00 00       	call   80106049 <memmove>
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
801022d0:	e8 74 3d 00 00       	call   80106049 <memmove>
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
80102532:	c7 44 24 04 74 99 10 	movl   $0x80109974,0x4(%esp)
80102539:	80 
8010253a:	c7 04 24 20 d6 10 80 	movl   $0x8010d620,(%esp)
80102541:	e8 88 37 00 00       	call   80105cce <initlock>
  picenable(IRQ_IDE);
80102546:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
8010254d:	e8 7b 1f 00 00       	call   801044cd <picenable>
  ioapicenable(IRQ_IDE, ncpu - 1);
80102552:	a1 60 4f 19 80       	mov    0x80194f60,%eax
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
801025a3:	c7 05 58 d6 10 80 01 	movl   $0x1,0x8010d658
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
801025de:	c7 04 24 78 99 10 80 	movl   $0x80109978,(%esp)
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
801026fd:	c7 04 24 20 d6 10 80 	movl   $0x8010d620,(%esp)
80102704:	e8 e6 35 00 00       	call   80105cef <acquire>
  if((b = idequeue) == 0){
80102709:	a1 54 d6 10 80       	mov    0x8010d654,%eax
8010270e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102711:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102715:	75 11                	jne    80102728 <ideintr+0x31>
    release(&idelock);
80102717:	c7 04 24 20 d6 10 80 	movl   $0x8010d620,(%esp)
8010271e:	e8 67 36 00 00       	call   80105d8a <release>
    // cprintf("spurious IDE interrupt\n");
    return;
80102723:	e9 85 00 00 00       	jmp    801027ad <ideintr+0xb6>
  }
  idequeue = b->qnext;
80102728:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010272b:	8b 40 14             	mov    0x14(%eax),%eax
8010272e:	a3 54 d6 10 80       	mov    %eax,0x8010d654

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
8010278b:	a1 54 d6 10 80       	mov    0x8010d654,%eax
80102790:	85 c0                	test   %eax,%eax
80102792:	74 0d                	je     801027a1 <ideintr+0xaa>
    idestart(idequeue);
80102794:	a1 54 d6 10 80       	mov    0x8010d654,%eax
80102799:	89 04 24             	mov    %eax,(%esp)
8010279c:	e8 31 fe ff ff       	call   801025d2 <idestart>

  release(&idelock);
801027a1:	c7 04 24 20 d6 10 80 	movl   $0x8010d620,(%esp)
801027a8:	e8 dd 35 00 00       	call   80105d8a <release>
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
801027c1:	c7 04 24 81 99 10 80 	movl   $0x80109981,(%esp)
801027c8:	e8 70 dd ff ff       	call   8010053d <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
801027cd:	8b 45 08             	mov    0x8(%ebp),%eax
801027d0:	8b 00                	mov    (%eax),%eax
801027d2:	83 e0 06             	and    $0x6,%eax
801027d5:	83 f8 02             	cmp    $0x2,%eax
801027d8:	75 0c                	jne    801027e6 <iderw+0x37>
    panic("iderw: nothing to do");
801027da:	c7 04 24 95 99 10 80 	movl   $0x80109995,(%esp)
801027e1:	e8 57 dd ff ff       	call   8010053d <panic>
  if(b->dev != 0 && !havedisk1)
801027e6:	8b 45 08             	mov    0x8(%ebp),%eax
801027e9:	8b 40 04             	mov    0x4(%eax),%eax
801027ec:	85 c0                	test   %eax,%eax
801027ee:	74 15                	je     80102805 <iderw+0x56>
801027f0:	a1 58 d6 10 80       	mov    0x8010d658,%eax
801027f5:	85 c0                	test   %eax,%eax
801027f7:	75 0c                	jne    80102805 <iderw+0x56>
    panic("iderw: ide disk 1 not present");
801027f9:	c7 04 24 aa 99 10 80 	movl   $0x801099aa,(%esp)
80102800:	e8 38 dd ff ff       	call   8010053d <panic>

  acquire(&idelock);  //DOC: acquire-lock
80102805:	c7 04 24 20 d6 10 80 	movl   $0x8010d620,(%esp)
8010280c:	e8 de 34 00 00       	call   80105cef <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80102811:	8b 45 08             	mov    0x8(%ebp),%eax
80102814:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC: insert-queue
8010281b:	c7 45 f4 54 d6 10 80 	movl   $0x8010d654,-0xc(%ebp)
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
80102840:	a1 54 d6 10 80       	mov    0x8010d654,%eax
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
80102857:	c7 04 24 20 d6 10 80 	movl   $0x8010d620,(%esp)
8010285e:	e8 27 35 00 00       	call   80105d8a <release>
	sti();
80102863:	e8 7a fc ff ff       	call   801024e2 <sti>
	acquire(&idelock); 
80102868:	c7 04 24 20 d6 10 80 	movl   $0x8010d620,(%esp)
8010286f:	e8 7b 34 00 00       	call   80105cef <acquire>
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
80102884:	c7 04 24 20 d6 10 80 	movl   $0x8010d620,(%esp)
8010288b:	e8 fa 34 00 00       	call   80105d8a <release>
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
80102897:	a1 54 18 11 80       	mov    0x80111854,%eax
8010289c:	8b 55 08             	mov    0x8(%ebp),%edx
8010289f:	89 10                	mov    %edx,(%eax)
  return ioapic->data;
801028a1:	a1 54 18 11 80       	mov    0x80111854,%eax
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
801028ae:	a1 54 18 11 80       	mov    0x80111854,%eax
801028b3:	8b 55 08             	mov    0x8(%ebp),%edx
801028b6:	89 10                	mov    %edx,(%eax)
  ioapic->data = data;
801028b8:	a1 54 18 11 80       	mov    0x80111854,%eax
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
801028cb:	a1 64 49 19 80       	mov    0x80194964,%eax
801028d0:	85 c0                	test   %eax,%eax
801028d2:	0f 84 9f 00 00 00    	je     80102977 <ioapicinit+0xb2>
    return;

  ioapic = (volatile struct ioapic*)IOAPIC;
801028d8:	c7 05 54 18 11 80 00 	movl   $0xfec00000,0x80111854
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
8010290b:	0f b6 05 60 49 19 80 	movzbl 0x80194960,%eax
80102912:	0f b6 c0             	movzbl %al,%eax
80102915:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80102918:	74 0c                	je     80102926 <ioapicinit+0x61>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
8010291a:	c7 04 24 c8 99 10 80 	movl   $0x801099c8,(%esp)
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
80102980:	a1 64 49 19 80       	mov    0x80194964,%eax
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
801029e8:	c7 44 24 04 fc 99 10 	movl   $0x801099fc,0x4(%esp)
801029ef:	80 
801029f0:	c7 04 24 60 18 11 80 	movl   $0x80111860,(%esp)
801029f7:	e8 d2 32 00 00       	call   80105cce <initlock>
  kmem.use_lock = 0;
801029fc:	c7 05 94 18 11 80 00 	movl   $0x0,0x80111894
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
80102a32:	c7 05 94 18 11 80 01 	movl   $0x1,0x80111894
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
80102a89:	81 7d 08 5c 7c 19 80 	cmpl   $0x80197c5c,0x8(%ebp)
80102a90:	72 12                	jb     80102aa4 <kfree+0x2d>
80102a92:	8b 45 08             	mov    0x8(%ebp),%eax
80102a95:	89 04 24             	mov    %eax,(%esp)
80102a98:	e8 2b ff ff ff       	call   801029c8 <v2p>
80102a9d:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80102aa2:	76 0c                	jbe    80102ab0 <kfree+0x39>
    panic("kfree");
80102aa4:	c7 04 24 01 9a 10 80 	movl   $0x80109a01,(%esp)
80102aab:	e8 8d da ff ff       	call   8010053d <panic>

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80102ab0:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80102ab7:	00 
80102ab8:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102abf:	00 
80102ac0:	8b 45 08             	mov    0x8(%ebp),%eax
80102ac3:	89 04 24             	mov    %eax,(%esp)
80102ac6:	e8 ab 34 00 00       	call   80105f76 <memset>

  if(kmem.use_lock)
80102acb:	a1 94 18 11 80       	mov    0x80111894,%eax
80102ad0:	85 c0                	test   %eax,%eax
80102ad2:	74 0c                	je     80102ae0 <kfree+0x69>
    acquire(&kmem.lock);
80102ad4:	c7 04 24 60 18 11 80 	movl   $0x80111860,(%esp)
80102adb:	e8 0f 32 00 00       	call   80105cef <acquire>
  r = (struct run*)v;
80102ae0:	8b 45 08             	mov    0x8(%ebp),%eax
80102ae3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
80102ae6:	8b 15 98 18 11 80    	mov    0x80111898,%edx
80102aec:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102aef:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
80102af1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102af4:	a3 98 18 11 80       	mov    %eax,0x80111898
  if(kmem.use_lock)
80102af9:	a1 94 18 11 80       	mov    0x80111894,%eax
80102afe:	85 c0                	test   %eax,%eax
80102b00:	74 0c                	je     80102b0e <kfree+0x97>
    release(&kmem.lock);
80102b02:	c7 04 24 60 18 11 80 	movl   $0x80111860,(%esp)
80102b09:	e8 7c 32 00 00       	call   80105d8a <release>
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
80102b16:	a1 94 18 11 80       	mov    0x80111894,%eax
80102b1b:	85 c0                	test   %eax,%eax
80102b1d:	74 0c                	je     80102b2b <kalloc+0x1b>
    acquire(&kmem.lock);
80102b1f:	c7 04 24 60 18 11 80 	movl   $0x80111860,(%esp)
80102b26:	e8 c4 31 00 00       	call   80105cef <acquire>
  r = kmem.freelist;
80102b2b:	a1 98 18 11 80       	mov    0x80111898,%eax
80102b30:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
80102b33:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102b37:	74 0a                	je     80102b43 <kalloc+0x33>
    kmem.freelist = r->next;
80102b39:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b3c:	8b 00                	mov    (%eax),%eax
80102b3e:	a3 98 18 11 80       	mov    %eax,0x80111898
  if(kmem.use_lock)
80102b43:	a1 94 18 11 80       	mov    0x80111894,%eax
80102b48:	85 c0                	test   %eax,%eax
80102b4a:	74 0c                	je     80102b58 <kalloc+0x48>
    release(&kmem.lock);
80102b4c:	c7 04 24 60 18 11 80 	movl   $0x80111860,(%esp)
80102b53:	e8 32 32 00 00       	call   80105d8a <release>
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
  int numOfPages,i,ans;
  uint sz;
  if(kmem.use_lock)
80102b63:	a1 94 18 11 80       	mov    0x80111894,%eax
80102b68:	85 c0                	test   %eax,%eax
80102b6a:	74 0c                	je     80102b78 <shmget+0x1b>
    acquire(&kmem.lock);
80102b6c:	c7 04 24 60 18 11 80 	movl   $0x80111860,(%esp)
80102b73:	e8 77 31 00 00       	call   80105cef <acquire>
  switch(shmflg)
80102b78:	8b 45 10             	mov    0x10(%ebp),%eax
80102b7b:	83 f8 14             	cmp    $0x14,%eax
80102b7e:	74 0e                	je     80102b8e <shmget+0x31>
80102b80:	83 f8 15             	cmp    $0x15,%eax
80102b83:	0f 84 de 01 00 00    	je     80102d67 <shmget+0x20a>
80102b89:	e9 08 02 00 00       	jmp    80102d96 <shmget+0x239>
  {
    case CREAT:
      if(shm.refs[key][1][64] == 0)
80102b8e:	8b 45 08             	mov    0x8(%ebp),%eax
80102b91:	c1 e0 03             	shl    $0x3,%eax
80102b94:	89 c2                	mov    %eax,%edx
80102b96:	c1 e2 06             	shl    $0x6,%edx
80102b99:	01 d0                	add    %edx,%eax
80102b9b:	05 a4 2a 11 80       	add    $0x80112aa4,%eax
80102ba0:	8b 00                	mov    (%eax),%eax
80102ba2:	85 c0                	test   %eax,%eax
80102ba4:	0f 85 b4 01 00 00    	jne    80102d5e <shmget+0x201>
      {
	struct run* r = kmem.freelist;
80102baa:	a1 98 18 11 80       	mov    0x80111898,%eax
80102baf:	89 45 ec             	mov    %eax,-0x14(%ebp)
	sz = PGROUNDUP(size);
80102bb2:	8b 45 0c             	mov    0xc(%ebp),%eax
80102bb5:	05 ff 0f 00 00       	add    $0xfff,%eax
80102bba:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80102bbf:	89 45 e8             	mov    %eax,-0x18(%ebp)
	numOfPages = sz/PGSIZE;
80102bc2:	8b 45 e8             	mov    -0x18(%ebp),%eax
80102bc5:	c1 e8 0c             	shr    $0xc,%eax
80102bc8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	shm.seg[key] = (kmem.freelist);
80102bcb:	8b 15 98 18 11 80    	mov    0x80111898,%edx
80102bd1:	8b 45 08             	mov    0x8(%ebp),%eax
80102bd4:	89 14 85 a0 18 11 80 	mov    %edx,-0x7feee760(,%eax,4)
	
	for(i=0;i<numOfPages;i++)
80102bdb:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102be2:	eb 58                	jmp    80102c3c <shmget+0xdf>
	{
	  cprintf("AAA: r = %d, r->next = %d, kfreelist = %d\n",r,r->next,kmem.freelist);
80102be4:	8b 15 98 18 11 80    	mov    0x80111898,%edx
80102bea:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102bed:	8b 00                	mov    (%eax),%eax
80102bef:	89 54 24 0c          	mov    %edx,0xc(%esp)
80102bf3:	89 44 24 08          	mov    %eax,0x8(%esp)
80102bf7:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102bfa:	89 44 24 04          	mov    %eax,0x4(%esp)
80102bfe:	c7 04 24 08 9a 10 80 	movl   $0x80109a08,(%esp)
80102c05:	e8 97 d7 ff ff       	call   801003a1 <cprintf>
	  r = r->next;
80102c0a:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102c0d:	8b 00                	mov    (%eax),%eax
80102c0f:	89 45 ec             	mov    %eax,-0x14(%ebp)
	  cprintf("AAA: r = %d, r->next = %d, kfreelist = %d\n",r,r->next,kmem.freelist);
80102c12:	8b 15 98 18 11 80    	mov    0x80111898,%edx
80102c18:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102c1b:	8b 00                	mov    (%eax),%eax
80102c1d:	89 54 24 0c          	mov    %edx,0xc(%esp)
80102c21:	89 44 24 08          	mov    %eax,0x8(%esp)
80102c25:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102c28:	89 44 24 04          	mov    %eax,0x4(%esp)
80102c2c:	c7 04 24 08 9a 10 80 	movl   $0x80109a08,(%esp)
80102c33:	e8 69 d7 ff ff       	call   801003a1 <cprintf>
	struct run* r = kmem.freelist;
	sz = PGROUNDUP(size);
	numOfPages = sz/PGSIZE;
	shm.seg[key] = (kmem.freelist);
	
	for(i=0;i<numOfPages;i++)
80102c38:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102c3c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c3f:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
80102c42:	7c a0                	jl     80102be4 <shmget+0x87>
	  cprintf("AAA: r = %d, r->next = %d, kfreelist = %d\n",r,r->next,kmem.freelist);
	  r = r->next;
	  cprintf("AAA: r = %d, r->next = %d, kfreelist = %d\n",r,r->next,kmem.freelist);
	}
	
	if(i == numOfPages)
80102c44:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c47:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
80102c4a:	0f 85 05 01 00 00    	jne    80102d55 <shmget+0x1f8>
	{
	  for(;kmem.freelist->next!=r;kmem.freelist = kmem.freelist->next){}
80102c50:	eb 0c                	jmp    80102c5e <shmget+0x101>
80102c52:	a1 98 18 11 80       	mov    0x80111898,%eax
80102c57:	8b 00                	mov    (%eax),%eax
80102c59:	a3 98 18 11 80       	mov    %eax,0x80111898
80102c5e:	a1 98 18 11 80       	mov    0x80111898,%eax
80102c63:	8b 00                	mov    (%eax),%eax
80102c65:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80102c68:	75 e8                	jne    80102c52 <shmget+0xf5>
  	  cprintf("BBB: r = %d, kfreelist = %d, kmem.freelist->next = %d\n",r,kmem.freelist,kmem.freelist->next);
80102c6a:	a1 98 18 11 80       	mov    0x80111898,%eax
80102c6f:	8b 10                	mov    (%eax),%edx
80102c71:	a1 98 18 11 80       	mov    0x80111898,%eax
80102c76:	89 54 24 0c          	mov    %edx,0xc(%esp)
80102c7a:	89 44 24 08          	mov    %eax,0x8(%esp)
80102c7e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102c81:	89 44 24 04          	mov    %eax,0x4(%esp)
80102c85:	c7 04 24 34 9a 10 80 	movl   $0x80109a34,(%esp)
80102c8c:	e8 10 d7 ff ff       	call   801003a1 <cprintf>
	  kmem.freelist->next = 0;
80102c91:	a1 98 18 11 80       	mov    0x80111898,%eax
80102c96:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    	  cprintf("BBB: r = %d, kfreelist = %d, kmem.freelist->next = %d\n",r,kmem.freelist,kmem.freelist->next);
80102c9c:	a1 98 18 11 80       	mov    0x80111898,%eax
80102ca1:	8b 10                	mov    (%eax),%edx
80102ca3:	a1 98 18 11 80       	mov    0x80111898,%eax
80102ca8:	89 54 24 0c          	mov    %edx,0xc(%esp)
80102cac:	89 44 24 08          	mov    %eax,0x8(%esp)
80102cb0:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102cb3:	89 44 24 04          	mov    %eax,0x4(%esp)
80102cb7:	c7 04 24 34 9a 10 80 	movl   $0x80109a34,(%esp)
80102cbe:	e8 de d6 ff ff       	call   801003a1 <cprintf>
	  kmem.freelist = r;
80102cc3:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102cc6:	a3 98 18 11 80       	mov    %eax,0x80111898
  	  cprintf("BBB: r = %d, kfreelist = %d, kmem.freelist->next = %d\n",r,kmem.freelist,kmem.freelist->next);
80102ccb:	a1 98 18 11 80       	mov    0x80111898,%eax
80102cd0:	8b 10                	mov    (%eax),%edx
80102cd2:	a1 98 18 11 80       	mov    0x80111898,%eax
80102cd7:	89 54 24 0c          	mov    %edx,0xc(%esp)
80102cdb:	89 44 24 08          	mov    %eax,0x8(%esp)
80102cdf:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102ce2:	89 44 24 04          	mov    %eax,0x4(%esp)
80102ce6:	c7 04 24 34 9a 10 80 	movl   $0x80109a34,(%esp)
80102ced:	e8 af d6 ff ff       	call   801003a1 <cprintf>
	  ans = (int)shm.seg[key];
80102cf2:	8b 45 08             	mov    0x8(%ebp),%eax
80102cf5:	8b 04 85 a0 18 11 80 	mov    -0x7feee760(,%eax,4),%eax
80102cfc:	89 45 f0             	mov    %eax,-0x10(%ebp)
  	  cprintf("BBB: shm.seg[key] = %p, shm.seg[key]->next = %p, shm.seg[key]->next->next = %p\n",shm.seg[key],shm.seg[key]->next,shm.seg[key]->next->next);
80102cff:	8b 45 08             	mov    0x8(%ebp),%eax
80102d02:	8b 04 85 a0 18 11 80 	mov    -0x7feee760(,%eax,4),%eax
80102d09:	8b 00                	mov    (%eax),%eax
80102d0b:	8b 08                	mov    (%eax),%ecx
80102d0d:	8b 45 08             	mov    0x8(%ebp),%eax
80102d10:	8b 04 85 a0 18 11 80 	mov    -0x7feee760(,%eax,4),%eax
80102d17:	8b 10                	mov    (%eax),%edx
80102d19:	8b 45 08             	mov    0x8(%ebp),%eax
80102d1c:	8b 04 85 a0 18 11 80 	mov    -0x7feee760(,%eax,4),%eax
80102d23:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80102d27:	89 54 24 08          	mov    %edx,0x8(%esp)
80102d2b:	89 44 24 04          	mov    %eax,0x4(%esp)
80102d2f:	c7 04 24 6c 9a 10 80 	movl   $0x80109a6c,(%esp)
80102d36:	e8 66 d6 ff ff       	call   801003a1 <cprintf>
	  shm.refs[key][1][64] = numOfPages;
80102d3b:	8b 45 08             	mov    0x8(%ebp),%eax
80102d3e:	c1 e0 03             	shl    $0x3,%eax
80102d41:	89 c2                	mov    %eax,%edx
80102d43:	c1 e2 06             	shl    $0x6,%edx
80102d46:	01 d0                	add    %edx,%eax
80102d48:	8d 90 a4 2a 11 80    	lea    -0x7feed55c(%eax),%edx
80102d4e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102d51:	89 02                	mov    %eax,(%edx)
	}
	else
	  ans = -1;
	break;
80102d53:	eb 41                	jmp    80102d96 <shmget+0x239>
	  ans = (int)shm.seg[key];
  	  cprintf("BBB: shm.seg[key] = %p, shm.seg[key]->next = %p, shm.seg[key]->next->next = %p\n",shm.seg[key],shm.seg[key]->next,shm.seg[key]->next->next);
	  shm.refs[key][1][64] = numOfPages;
	}
	else
	  ans = -1;
80102d55:	c7 45 f0 ff ff ff ff 	movl   $0xffffffff,-0x10(%ebp)
	break;
80102d5c:	eb 38                	jmp    80102d96 <shmget+0x239>
      }
      else
	ans = -1;
80102d5e:	c7 45 f0 ff ff ff ff 	movl   $0xffffffff,-0x10(%ebp)
      break;
80102d65:	eb 2f                	jmp    80102d96 <shmget+0x239>
    case GET:
      if(!shm.refs[key][1][64])
80102d67:	8b 45 08             	mov    0x8(%ebp),%eax
80102d6a:	c1 e0 03             	shl    $0x3,%eax
80102d6d:	89 c2                	mov    %eax,%edx
80102d6f:	c1 e2 06             	shl    $0x6,%edx
80102d72:	01 d0                	add    %edx,%eax
80102d74:	05 a4 2a 11 80       	add    $0x80112aa4,%eax
80102d79:	8b 00                	mov    (%eax),%eax
80102d7b:	85 c0                	test   %eax,%eax
80102d7d:	75 09                	jne    80102d88 <shmget+0x22b>
	ans = -1;
80102d7f:	c7 45 f0 ff ff ff ff 	movl   $0xffffffff,-0x10(%ebp)
      else
	ans = (int)shm.seg[key];
      break;
80102d86:	eb 0d                	jmp    80102d95 <shmget+0x238>
      break;
    case GET:
      if(!shm.refs[key][1][64])
	ans = -1;
      else
	ans = (int)shm.seg[key];
80102d88:	8b 45 08             	mov    0x8(%ebp),%eax
80102d8b:	8b 04 85 a0 18 11 80 	mov    -0x7feee760(,%eax,4),%eax
80102d92:	89 45 f0             	mov    %eax,-0x10(%ebp)
      break;
80102d95:	90                   	nop
  }
  if(kmem.use_lock)
80102d96:	a1 94 18 11 80       	mov    0x80111894,%eax
80102d9b:	85 c0                	test   %eax,%eax
80102d9d:	74 0c                	je     80102dab <shmget+0x24e>
    release(&kmem.lock);
80102d9f:	c7 04 24 60 18 11 80 	movl   $0x80111860,(%esp)
80102da6:	e8 df 2f 00 00       	call   80105d8a <release>
  return ans;
80102dab:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80102dae:	c9                   	leave  
80102daf:	c3                   	ret    

80102db0 <shmdel>:

int 
shmdel(int shmid)
{
80102db0:	55                   	push   %ebp
80102db1:	89 e5                	mov    %esp,%ebp
80102db3:	83 ec 48             	sub    $0x48,%esp
  int key,ans = -1,numOfPages,i,haveNext;
80102db6:	c7 45 f0 ff ff ff ff 	movl   $0xffffffff,-0x10(%ebp)
  struct run* r,*next;
  if(kmem.use_lock)
80102dbd:	a1 94 18 11 80       	mov    0x80111894,%eax
80102dc2:	85 c0                	test   %eax,%eax
80102dc4:	74 0c                	je     80102dd2 <shmdel+0x22>
    acquire(&kmem.lock);
80102dc6:	c7 04 24 60 18 11 80 	movl   $0x80111860,(%esp)
80102dcd:	e8 1d 2f 00 00       	call   80105cef <acquire>
  for(key = 0;key<numOfSegs;key++)
80102dd2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102dd9:	e9 e2 01 00 00       	jmp    80102fc0 <shmdel+0x210>
  {
    if(shmid == (int)shm.seg[key])
80102dde:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102de1:	8b 04 85 a0 18 11 80 	mov    -0x7feee760(,%eax,4),%eax
80102de8:	3b 45 08             	cmp    0x8(%ebp),%eax
80102deb:	0f 85 cb 01 00 00    	jne    80102fbc <shmdel+0x20c>
    {
      if(shm.refs[key][0][64]>0)
80102df1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102df4:	c1 e0 03             	shl    $0x3,%eax
80102df7:	89 c2                	mov    %eax,%edx
80102df9:	c1 e2 06             	shl    $0x6,%edx
80102dfc:	01 d0                	add    %edx,%eax
80102dfe:	05 a0 29 11 80       	add    $0x801129a0,%eax
80102e03:	8b 00                	mov    (%eax),%eax
80102e05:	85 c0                	test   %eax,%eax
80102e07:	0f 8f c2 01 00 00    	jg     80102fcf <shmdel+0x21f>
      {
	break;
      }
      else
      {
	cprintf("BBB: shm.seg[key] = %p, shm.seg[key]->next = %p\n",shm.seg[key],shm.seg[key]->next);
80102e0d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e10:	8b 04 85 a0 18 11 80 	mov    -0x7feee760(,%eax,4),%eax
80102e17:	8b 10                	mov    (%eax),%edx
80102e19:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e1c:	8b 04 85 a0 18 11 80 	mov    -0x7feee760(,%eax,4),%eax
80102e23:	89 54 24 08          	mov    %edx,0x8(%esp)
80102e27:	89 44 24 04          	mov    %eax,0x4(%esp)
80102e2b:	c7 04 24 bc 9a 10 80 	movl   $0x80109abc,(%esp)
80102e32:	e8 6a d5 ff ff       	call   801003a1 <cprintf>
	haveNext = 0;
80102e37:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	r = shm.seg[key];
80102e3e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e41:	8b 04 85 a0 18 11 80 	mov    -0x7feee760(,%eax,4),%eax
80102e48:	89 45 e0             	mov    %eax,-0x20(%ebp)
	numOfPages=shm.refs[key][1][64];
80102e4b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e4e:	c1 e0 03             	shl    $0x3,%eax
80102e51:	89 c2                	mov    %eax,%edx
80102e53:	c1 e2 06             	shl    $0x6,%edx
80102e56:	01 d0                	add    %edx,%eax
80102e58:	05 a4 2a 11 80       	add    $0x80112aa4,%eax
80102e5d:	8b 00                	mov    (%eax),%eax
80102e5f:	89 45 ec             	mov    %eax,-0x14(%ebp)
	
	for(;0 < numOfPages;numOfPages--,haveNext = 0)
80102e62:	e9 f9 00 00 00       	jmp    80102f60 <shmdel+0x1b0>
	{
	  for(i=1;i<numOfPages;i++)
80102e67:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
80102e6e:	eb 13                	jmp    80102e83 <shmdel+0xd3>
	  {
	    next = r->next;
80102e70:	8b 45 e0             	mov    -0x20(%ebp),%eax
80102e73:	8b 00                	mov    (%eax),%eax
80102e75:	89 45 dc             	mov    %eax,-0x24(%ebp)
	    haveNext = 1;
80102e78:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
	r = shm.seg[key];
	numOfPages=shm.refs[key][1][64];
	
	for(;0 < numOfPages;numOfPages--,haveNext = 0)
	{
	  for(i=1;i<numOfPages;i++)
80102e7f:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
80102e83:	8b 45 e8             	mov    -0x18(%ebp),%eax
80102e86:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80102e89:	7c e5                	jl     80102e70 <shmdel+0xc0>
	  {
	    next = r->next;
	    haveNext = 1;
	  }
	  
	  if(haveNext)
80102e8b:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80102e8f:	74 70                	je     80102f01 <shmdel+0x151>
	  {
    	    cprintf("r = %d, next = %d\n",r,next);
80102e91:	8b 45 dc             	mov    -0x24(%ebp),%eax
80102e94:	89 44 24 08          	mov    %eax,0x8(%esp)
80102e98:	8b 45 e0             	mov    -0x20(%ebp),%eax
80102e9b:	89 44 24 04          	mov    %eax,0x4(%esp)
80102e9f:	c7 04 24 ed 9a 10 80 	movl   $0x80109aed,(%esp)
80102ea6:	e8 f6 d4 ff ff       	call   801003a1 <cprintf>
	    char* v = (char*)next;
80102eab:	8b 45 dc             	mov    -0x24(%ebp),%eax
80102eae:	89 45 d8             	mov    %eax,-0x28(%ebp)
	    memset(v, 1, PGSIZE);
80102eb1:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80102eb8:	00 
80102eb9:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102ec0:	00 
80102ec1:	8b 45 d8             	mov    -0x28(%ebp),%eax
80102ec4:	89 04 24             	mov    %eax,(%esp)
80102ec7:	e8 aa 30 00 00       	call   80105f76 <memset>
	    cprintf("r = %d, next = %d\n",r,next);
80102ecc:	8b 45 dc             	mov    -0x24(%ebp),%eax
80102ecf:	89 44 24 08          	mov    %eax,0x8(%esp)
80102ed3:	8b 45 e0             	mov    -0x20(%ebp),%eax
80102ed6:	89 44 24 04          	mov    %eax,0x4(%esp)
80102eda:	c7 04 24 ed 9a 10 80 	movl   $0x80109aed,(%esp)
80102ee1:	e8 bb d4 ff ff       	call   801003a1 <cprintf>
	    next = (struct run*)v;
80102ee6:	8b 45 d8             	mov    -0x28(%ebp),%eax
80102ee9:	89 45 dc             	mov    %eax,-0x24(%ebp)
	    next->next = kmem.freelist;
80102eec:	8b 15 98 18 11 80    	mov    0x80111898,%edx
80102ef2:	8b 45 dc             	mov    -0x24(%ebp),%eax
80102ef5:	89 10                	mov    %edx,(%eax)
	    kmem.freelist = next;
80102ef7:	8b 45 dc             	mov    -0x24(%ebp),%eax
80102efa:	a3 98 18 11 80       	mov    %eax,0x80111898
80102eff:	eb 54                	jmp    80102f55 <shmdel+0x1a5>
	  }
	  else
	  {
	    char* v = (char*)r;
80102f01:	8b 45 e0             	mov    -0x20(%ebp),%eax
80102f04:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	    memset(v, 1, PGSIZE);
80102f07:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80102f0e:	00 
80102f0f:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102f16:	00 
80102f17:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80102f1a:	89 04 24             	mov    %eax,(%esp)
80102f1d:	e8 54 30 00 00       	call   80105f76 <memset>
	    cprintf("r = %d, next = %d\n",r,next);
80102f22:	8b 45 dc             	mov    -0x24(%ebp),%eax
80102f25:	89 44 24 08          	mov    %eax,0x8(%esp)
80102f29:	8b 45 e0             	mov    -0x20(%ebp),%eax
80102f2c:	89 44 24 04          	mov    %eax,0x4(%esp)
80102f30:	c7 04 24 ed 9a 10 80 	movl   $0x80109aed,(%esp)
80102f37:	e8 65 d4 ff ff       	call   801003a1 <cprintf>
	    r = (struct run*)v;
80102f3c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80102f3f:	89 45 e0             	mov    %eax,-0x20(%ebp)
	    r->next = kmem.freelist;
80102f42:	8b 15 98 18 11 80    	mov    0x80111898,%edx
80102f48:	8b 45 e0             	mov    -0x20(%ebp),%eax
80102f4b:	89 10                	mov    %edx,(%eax)
	    kmem.freelist = r;
80102f4d:	8b 45 e0             	mov    -0x20(%ebp),%eax
80102f50:	a3 98 18 11 80       	mov    %eax,0x80111898
	cprintf("BBB: shm.seg[key] = %p, shm.seg[key]->next = %p\n",shm.seg[key],shm.seg[key]->next);
	haveNext = 0;
	r = shm.seg[key];
	numOfPages=shm.refs[key][1][64];
	
	for(;0 < numOfPages;numOfPages--,haveNext = 0)
80102f55:	83 6d ec 01          	subl   $0x1,-0x14(%ebp)
80102f59:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80102f60:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80102f64:	0f 8f fd fe ff ff    	jg     80102e67 <shmdel+0xb7>
	  
	  r = next;
	  
	  cprintf("after memset\n");*/
	}
	cprintf("before next\n");
80102f6a:	c7 04 24 00 9b 10 80 	movl   $0x80109b00,(%esp)
80102f71:	e8 2b d4 ff ff       	call   801003a1 <cprintf>
	r->next = kmem.freelist;
80102f76:	8b 15 98 18 11 80    	mov    0x80111898,%edx
80102f7c:	8b 45 e0             	mov    -0x20(%ebp),%eax
80102f7f:	89 10                	mov    %edx,(%eax)
	cprintf("after next\n");
80102f81:	c7 04 24 0d 9b 10 80 	movl   $0x80109b0d,(%esp)
80102f88:	e8 14 d4 ff ff       	call   801003a1 <cprintf>
	kmem.freelist = shm.seg[key];
80102f8d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102f90:	8b 04 85 a0 18 11 80 	mov    -0x7feee760(,%eax,4),%eax
80102f97:	a3 98 18 11 80       	mov    %eax,0x80111898
	shm.refs[key][1][64] = 0;
80102f9c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102f9f:	c1 e0 03             	shl    $0x3,%eax
80102fa2:	89 c2                	mov    %eax,%edx
80102fa4:	c1 e2 06             	shl    $0x6,%edx
80102fa7:	01 d0                	add    %edx,%eax
80102fa9:	05 a4 2a 11 80       	add    $0x80112aa4,%eax
80102fae:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	ans = numOfPages;
80102fb4:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102fb7:	89 45 f0             	mov    %eax,-0x10(%ebp)
      }
      break;
80102fba:	eb 14                	jmp    80102fd0 <shmdel+0x220>
{
  int key,ans = -1,numOfPages,i,haveNext;
  struct run* r,*next;
  if(kmem.use_lock)
    acquire(&kmem.lock);
  for(key = 0;key<numOfSegs;key++)
80102fbc:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102fc0:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
80102fc7:	0f 8e 11 fe ff ff    	jle    80102dde <shmdel+0x2e>
80102fcd:	eb 01                	jmp    80102fd0 <shmdel+0x220>
  {
    if(shmid == (int)shm.seg[key])
    {
      if(shm.refs[key][0][64]>0)
      {
	break;
80102fcf:	90                   	nop
	ans = numOfPages;
      }
      break;
    }
  }
  if(kmem.use_lock)
80102fd0:	a1 94 18 11 80       	mov    0x80111894,%eax
80102fd5:	85 c0                	test   %eax,%eax
80102fd7:	74 0c                	je     80102fe5 <shmdel+0x235>
    release(&kmem.lock);
80102fd9:	c7 04 24 60 18 11 80 	movl   $0x80111860,(%esp)
80102fe0:	e8 a5 2d 00 00       	call   80105d8a <release>
  
  return ans;
80102fe5:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80102fe8:	c9                   	leave  
80102fe9:	c3                   	ret    

80102fea <shmat>:

void *
shmat(int shmid, int shmflg)
{
80102fea:	55                   	push   %ebp
80102feb:	89 e5                	mov    %esp,%ebp
80102fed:	83 ec 48             	sub    $0x48,%esp
  int key,forFlag=0;
80102ff0:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  struct run* r;
  void* ans;
  char* mem;
  uint a;

  acquire(&shm.lock);
80102ff7:	c7 04 24 a0 48 19 80 	movl   $0x801948a0,(%esp)
80102ffe:	e8 ec 2c 00 00       	call   80105cef <acquire>
  for(key = 0;key<numOfSegs;key++)
80103003:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010300a:	e9 b2 01 00 00       	jmp    801031c1 <shmat+0x1d7>
  {
    if(shmid == (int)shm.seg[key])
8010300f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103012:	8b 04 85 a0 18 11 80 	mov    -0x7feee760(,%eax,4),%eax
80103019:	3b 45 08             	cmp    0x8(%ebp),%eax
8010301c:	0f 85 9b 01 00 00    	jne    801031bd <shmat+0x1d3>
    {
      if(shm.refs[key][1][64]>0)
80103022:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103025:	c1 e0 03             	shl    $0x3,%eax
80103028:	89 c2                	mov    %eax,%edx
8010302a:	c1 e2 06             	shl    $0x6,%edx
8010302d:	01 d0                	add    %edx,%eax
8010302f:	05 a4 2a 11 80       	add    $0x80112aa4,%eax
80103034:	8b 00                	mov    (%eax),%eax
80103036:	85 c0                	test   %eax,%eax
80103038:	0f 8e 76 01 00 00    	jle    801031b4 <shmat+0x1ca>
      {
	a = PGROUNDUP(proc->sz);
8010303e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80103044:	8b 00                	mov    (%eax),%eax
80103046:	05 ff 0f 00 00       	add    $0xfff,%eax
8010304b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80103050:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ans = (void*)a;
80103053:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80103056:	89 45 e8             	mov    %eax,-0x18(%ebp)
	if(a + PGSIZE >= KERNBASE)
80103059:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010305c:	05 00 10 00 00       	add    $0x1000,%eax
80103061:	85 c0                	test   %eax,%eax
80103063:	79 0c                	jns    80103071 <shmat+0x87>
	{
	  ans = (void*)-1;
80103065:	c7 45 e8 ff ff ff ff 	movl   $0xffffffff,-0x18(%ebp)
	  break;
8010306c:	e9 60 01 00 00       	jmp    801031d1 <shmat+0x1e7>
	}
	
	shm.refs[key][0][64]++;
80103071:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103074:	c1 e0 03             	shl    $0x3,%eax
80103077:	89 c2                	mov    %eax,%edx
80103079:	c1 e2 06             	shl    $0x6,%edx
8010307c:	01 d0                	add    %edx,%eax
8010307e:	05 a0 29 11 80       	add    $0x801129a0,%eax
80103083:	8b 00                	mov    (%eax),%eax
80103085:	8d 50 01             	lea    0x1(%eax),%edx
80103088:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010308b:	c1 e0 03             	shl    $0x3,%eax
8010308e:	89 c1                	mov    %eax,%ecx
80103090:	c1 e1 06             	shl    $0x6,%ecx
80103093:	01 c8                	add    %ecx,%eax
80103095:	05 a0 29 11 80       	add    $0x801129a0,%eax
8010309a:	89 10                	mov    %edx,(%eax)
	shm.refs[key][0][proc->pid] = 1;
8010309c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801030a2:	8b 50 10             	mov    0x10(%eax),%edx
801030a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801030a8:	01 c0                	add    %eax,%eax
801030aa:	89 c1                	mov    %eax,%ecx
801030ac:	c1 e1 06             	shl    $0x6,%ecx
801030af:	01 c8                	add    %ecx,%eax
801030b1:	01 d0                	add    %edx,%eax
801030b3:	05 00 04 00 00       	add    $0x400,%eax
801030b8:	c7 04 85 a0 18 11 80 	movl   $0x1,-0x7feee760(,%eax,4)
801030bf:	01 00 00 00 
	proc->has_shm++;
801030c3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801030c9:	8b 90 8c 00 00 00    	mov    0x8c(%eax),%edx
801030cf:	83 c2 01             	add    $0x1,%edx
801030d2:	89 90 8c 00 00 00    	mov    %edx,0x8c(%eax)
	
	for(r = shm.seg[key];r && a < KERNBASE;r = r->next,a += PGSIZE)
801030d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801030db:	8b 04 85 a0 18 11 80 	mov    -0x7feee760(,%eax,4),%eax
801030e2:	89 45 ec             	mov    %eax,-0x14(%ebp)
801030e5:	e9 a6 00 00 00       	jmp    80103190 <shmat+0x1a6>
	{
	    forFlag = 1;
801030ea:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
	    mem = (char*)r;
801030f1:	8b 45 ec             	mov    -0x14(%ebp),%eax
801030f4:	89 45 e0             	mov    %eax,-0x20(%ebp)
	    
	    switch(shmflg)
801030f7:	8b 45 0c             	mov    0xc(%ebp),%eax
801030fa:	83 f8 16             	cmp    $0x16,%eax
801030fd:	74 07                	je     80103106 <shmat+0x11c>
801030ff:	83 f8 17             	cmp    $0x17,%eax
80103102:	74 3c                	je     80103140 <shmat+0x156>
80103104:	eb 74                	jmp    8010317a <shmat+0x190>
	    {
	      case SHM_RDONLY:
		mappages(proc->pgdir, (char*)a, PGSIZE, v2p(mem), PTE_U);
80103106:	8b 45 e0             	mov    -0x20(%ebp),%eax
80103109:	89 04 24             	mov    %eax,(%esp)
8010310c:	e8 b7 f8 ff ff       	call   801029c8 <v2p>
80103111:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80103114:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
8010311b:	8b 52 04             	mov    0x4(%edx),%edx
8010311e:	c7 44 24 10 04 00 00 	movl   $0x4,0x10(%esp)
80103125:	00 
80103126:	89 44 24 0c          	mov    %eax,0xc(%esp)
8010312a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80103131:	00 
80103132:	89 4c 24 04          	mov    %ecx,0x4(%esp)
80103136:	89 14 24             	mov    %edx,(%esp)
80103139:	e8 03 5e 00 00       	call   80108f41 <mappages>
		break;
8010313e:	eb 41                	jmp    80103181 <shmat+0x197>
	      case SHM_RDWR:
		mappages(proc->pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
80103140:	8b 45 e0             	mov    -0x20(%ebp),%eax
80103143:	89 04 24             	mov    %eax,(%esp)
80103146:	e8 7d f8 ff ff       	call   801029c8 <v2p>
8010314b:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
8010314e:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80103155:	8b 52 04             	mov    0x4(%edx),%edx
80103158:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
8010315f:	00 
80103160:	89 44 24 0c          	mov    %eax,0xc(%esp)
80103164:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010316b:	00 
8010316c:	89 4c 24 04          	mov    %ecx,0x4(%esp)
80103170:	89 14 24             	mov    %edx,(%esp)
80103173:	e8 c9 5d 00 00       	call   80108f41 <mappages>
		break;
80103178:	eb 07                	jmp    80103181 <shmat+0x197>
	      default:
		forFlag = 0;
8010317a:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
	
	shm.refs[key][0][64]++;
	shm.refs[key][0][proc->pid] = 1;
	proc->has_shm++;
	
	for(r = shm.seg[key];r && a < KERNBASE;r = r->next,a += PGSIZE)
80103181:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103184:	8b 00                	mov    (%eax),%eax
80103186:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103189:	81 45 e4 00 10 00 00 	addl   $0x1000,-0x1c(%ebp)
80103190:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103194:	74 0b                	je     801031a1 <shmat+0x1b7>
80103196:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80103199:	85 c0                	test   %eax,%eax
8010319b:	0f 89 49 ff ff ff    	jns    801030ea <shmat+0x100>
		break;
	      default:
		forFlag = 0;
	    } 
	}
	if(forFlag)
801031a1:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801031a5:	74 29                	je     801031d0 <shmat+0x1e6>
	  proc->sz = a;
801031a7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801031ad:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801031b0:	89 10                	mov    %edx,(%eax)
	break;
801031b2:	eb 1c                	jmp    801031d0 <shmat+0x1e6>
      }
      else
      {
	ans = (void*)-1;
801031b4:	c7 45 e8 ff ff ff ff 	movl   $0xffffffff,-0x18(%ebp)
	break;
801031bb:	eb 14                	jmp    801031d1 <shmat+0x1e7>
  void* ans;
  char* mem;
  uint a;

  acquire(&shm.lock);
  for(key = 0;key<numOfSegs;key++)
801031bd:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801031c1:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
801031c8:	0f 8e 41 fe ff ff    	jle    8010300f <shmat+0x25>
801031ce:	eb 01                	jmp    801031d1 <shmat+0x1e7>
		forFlag = 0;
	    } 
	}
	if(forFlag)
	  proc->sz = a;
	break;
801031d0:	90                   	nop
      }
    }
  }
  
  
  release(&shm.lock);
801031d1:	c7 04 24 a0 48 19 80 	movl   $0x801948a0,(%esp)
801031d8:	e8 ad 2b 00 00       	call   80105d8a <release>
  
  return ans;
801031dd:	8b 45 e8             	mov    -0x18(%ebp),%eax
}
801031e0:	c9                   	leave  
801031e1:	c3                   	ret    

801031e2 <shmdt>:

int 
shmdt(const void *shmaddr)
{
801031e2:	55                   	push   %ebp
801031e3:	89 e5                	mov    %esp,%ebp
801031e5:	83 ec 38             	sub    $0x38,%esp
 
  pte_t *pte;
  uint r, numOfPages;
  int key,found;
  pte = walkpgdir(proc->pgdir, (char*)shmaddr, 0);
801031e8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801031ee:	8b 40 04             	mov    0x4(%eax),%eax
801031f1:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801031f8:	00 
801031f9:	8b 55 08             	mov    0x8(%ebp),%edx
801031fc:	89 54 24 04          	mov    %edx,0x4(%esp)
80103200:	89 04 24             	mov    %eax,(%esp)
80103203:	e8 a3 5c 00 00       	call   80108eab <walkpgdir>
80103208:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  r = (int)p2v(PTE_ADDR(*pte)) ;
8010320b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010320e:	8b 00                	mov    (%eax),%eax
80103210:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80103215:	89 04 24             	mov    %eax,(%esp)
80103218:	e8 b8 f7 ff ff       	call   801029d5 <p2v>
8010321d:	89 45 e0             	mov    %eax,-0x20(%ebp)
  acquire(&shm.lock);
80103220:	c7 04 24 a0 48 19 80 	movl   $0x801948a0,(%esp)
80103227:	e8 c3 2a 00 00       	call   80105cef <acquire>
  for(found = 0,key = 0;key<numOfSegs;key++)
8010322c:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80103233:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
8010323a:	e9 dc 00 00 00       	jmp    8010331b <shmdt+0x139>
  {    
    if((int)shm.seg[key] == r)
8010323f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103242:	8b 04 85 a0 18 11 80 	mov    -0x7feee760(,%eax,4),%eax
80103249:	3b 45 e0             	cmp    -0x20(%ebp),%eax
8010324c:	0f 85 c5 00 00 00    	jne    80103317 <shmdt+0x135>
    {  
      if(shm.refs[key][1][64]>0)
80103252:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103255:	c1 e0 03             	shl    $0x3,%eax
80103258:	89 c2                	mov    %eax,%edx
8010325a:	c1 e2 06             	shl    $0x6,%edx
8010325d:	01 d0                	add    %edx,%eax
8010325f:	05 a4 2a 11 80       	add    $0x80112aa4,%eax
80103264:	8b 00                	mov    (%eax),%eax
80103266:	85 c0                	test   %eax,%eax
80103268:	0f 8e 9f 00 00 00    	jle    8010330d <shmdt+0x12b>
      { 
	if(shm.refs[key][0][64] > 0)
8010326e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103271:	c1 e0 03             	shl    $0x3,%eax
80103274:	89 c2                	mov    %eax,%edx
80103276:	c1 e2 06             	shl    $0x6,%edx
80103279:	01 d0                	add    %edx,%eax
8010327b:	05 a0 29 11 80       	add    $0x801129a0,%eax
80103280:	8b 00                	mov    (%eax),%eax
80103282:	85 c0                	test   %eax,%eax
80103284:	7e 2b                	jle    801032b1 <shmdt+0xcf>
	  shm.refs[key][0][64]--;
80103286:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103289:	c1 e0 03             	shl    $0x3,%eax
8010328c:	89 c2                	mov    %eax,%edx
8010328e:	c1 e2 06             	shl    $0x6,%edx
80103291:	01 d0                	add    %edx,%eax
80103293:	05 a0 29 11 80       	add    $0x801129a0,%eax
80103298:	8b 00                	mov    (%eax),%eax
8010329a:	8d 50 ff             	lea    -0x1(%eax),%edx
8010329d:	8b 45 f0             	mov    -0x10(%ebp),%eax
801032a0:	c1 e0 03             	shl    $0x3,%eax
801032a3:	89 c1                	mov    %eax,%ecx
801032a5:	c1 e1 06             	shl    $0x6,%ecx
801032a8:	01 c8                	add    %ecx,%eax
801032aa:	05 a0 29 11 80       	add    $0x801129a0,%eax
801032af:	89 10                	mov    %edx,(%eax)
	shm.refs[key][0][proc->pid] = 0;
801032b1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801032b7:	8b 50 10             	mov    0x10(%eax),%edx
801032ba:	8b 45 f0             	mov    -0x10(%ebp),%eax
801032bd:	01 c0                	add    %eax,%eax
801032bf:	89 c1                	mov    %eax,%ecx
801032c1:	c1 e1 06             	shl    $0x6,%ecx
801032c4:	01 c8                	add    %ecx,%eax
801032c6:	01 d0                	add    %edx,%eax
801032c8:	05 00 04 00 00       	add    $0x400,%eax
801032cd:	c7 04 85 a0 18 11 80 	movl   $0x0,-0x7feee760(,%eax,4)
801032d4:	00 00 00 00 
	proc->has_shm--;
801032d8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801032de:	8b 90 8c 00 00 00    	mov    0x8c(%eax),%edx
801032e4:	83 ea 01             	sub    $0x1,%edx
801032e7:	89 90 8c 00 00 00    	mov    %edx,0x8c(%eax)
	numOfPages = shm.refs[key][1][64];
801032ed:	8b 45 f0             	mov    -0x10(%ebp),%eax
801032f0:	c1 e0 03             	shl    $0x3,%eax
801032f3:	89 c2                	mov    %eax,%edx
801032f5:	c1 e2 06             	shl    $0x6,%edx
801032f8:	01 d0                	add    %edx,%eax
801032fa:	05 a4 2a 11 80       	add    $0x80112aa4,%eax
801032ff:	8b 00                	mov    (%eax),%eax
80103301:	89 45 f4             	mov    %eax,-0xc(%ebp)
	found = 1;
80103304:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
	break;
8010330b:	eb 1b                	jmp    80103328 <shmdt+0x146>
      }
      else
	return -1;
8010330d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103312:	e9 85 00 00 00       	jmp    8010339c <shmdt+0x1ba>
  uint r, numOfPages;
  int key,found;
  pte = walkpgdir(proc->pgdir, (char*)shmaddr, 0);
  r = (int)p2v(PTE_ADDR(*pte)) ;
  acquire(&shm.lock);
  for(found = 0,key = 0;key<numOfSegs;key++)
80103317:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
8010331b:	81 7d f0 ff 03 00 00 	cmpl   $0x3ff,-0x10(%ebp)
80103322:	0f 8e 17 ff ff ff    	jle    8010323f <shmdt+0x5d>
      }
      else
	return -1;
    }
  }
  release(&shm.lock);
80103328:	c7 04 24 a0 48 19 80 	movl   $0x801948a0,(%esp)
8010332f:	e8 56 2a 00 00       	call   80105d8a <release>
  
  if(!found)
80103334:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103338:	75 07                	jne    80103341 <shmdt+0x15f>
    return -1;
8010333a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010333f:	eb 5b                	jmp    8010339c <shmdt+0x1ba>

  void *shmaddr2 = (void*)shmaddr;
80103341:	8b 45 08             	mov    0x8(%ebp),%eax
80103344:	89 45 e8             	mov    %eax,-0x18(%ebp)

  for(; shmaddr2  < shmaddr + numOfPages*PGSIZE; shmaddr2 += PGSIZE)
80103347:	eb 40                	jmp    80103389 <shmdt+0x1a7>
  {
    pte = walkpgdir(proc->pgdir, (char*)shmaddr2, 0);
80103349:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010334f:	8b 40 04             	mov    0x4(%eax),%eax
80103352:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80103359:	00 
8010335a:	8b 55 e8             	mov    -0x18(%ebp),%edx
8010335d:	89 54 24 04          	mov    %edx,0x4(%esp)
80103361:	89 04 24             	mov    %eax,(%esp)
80103364:	e8 42 5b 00 00       	call   80108eab <walkpgdir>
80103369:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(!pte)
8010336c:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80103370:	75 07                	jne    80103379 <shmdt+0x197>
      shmaddr2 += (NPTENTRIES - 1) * PGSIZE;
80103372:	81 45 e8 00 f0 3f 00 	addl   $0x3ff000,-0x18(%ebp)
    *pte = 0;
80103379:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010337c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  if(!found)
    return -1;

  void *shmaddr2 = (void*)shmaddr;

  for(; shmaddr2  < shmaddr + numOfPages*PGSIZE; shmaddr2 += PGSIZE)
80103382:	81 45 e8 00 10 00 00 	addl   $0x1000,-0x18(%ebp)
80103389:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010338c:	c1 e0 0c             	shl    $0xc,%eax
8010338f:	03 45 08             	add    0x8(%ebp),%eax
80103392:	3b 45 e8             	cmp    -0x18(%ebp),%eax
80103395:	77 b2                	ja     80103349 <shmdt+0x167>
    if(!pte)
      shmaddr2 += (NPTENTRIES - 1) * PGSIZE;
    *pte = 0;
  }

  return 0;
80103397:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010339c:	c9                   	leave  
8010339d:	c3                   	ret    

8010339e <deallocshm>:

void 
deallocshm(int pid)
{
8010339e:	55                   	push   %ebp
8010339f:	89 e5                	mov    %esp,%ebp
801033a1:	83 ec 38             	sub    $0x38,%esp
  cprintf("in deallocshm\n");	
801033a4:	c7 04 24 19 9b 10 80 	movl   $0x80109b19,(%esp)
801033ab:	e8 f1 cf ff ff       	call   801003a1 <cprintf>
  uint a = 0;
801033b0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  int key, pa, numOfPages;
  pte_t *pte;
  
  acquire(&shm.lock);
801033b7:	c7 04 24 a0 48 19 80 	movl   $0x801948a0,(%esp)
801033be:	e8 2c 29 00 00       	call   80105cef <acquire>
  for(key = 0;key<numOfSegs;key++)
801033c3:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
801033ca:	e9 6e 01 00 00       	jmp    8010353d <deallocshm+0x19f>
  {    
    if(shm.refs[key][0][proc->pid])
801033cf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801033d5:	8b 50 10             	mov    0x10(%eax),%edx
801033d8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801033db:	01 c0                	add    %eax,%eax
801033dd:	89 c1                	mov    %eax,%ecx
801033df:	c1 e1 06             	shl    $0x6,%ecx
801033e2:	01 c8                	add    %ecx,%eax
801033e4:	01 d0                	add    %edx,%eax
801033e6:	05 00 04 00 00       	add    $0x400,%eax
801033eb:	8b 04 85 a0 18 11 80 	mov    -0x7feee760(,%eax,4),%eax
801033f2:	85 c0                	test   %eax,%eax
801033f4:	0f 84 3f 01 00 00    	je     80103539 <deallocshm+0x19b>
    {
      for(; a  < proc->sz; a += PGSIZE)
801033fa:	e9 26 01 00 00       	jmp    80103525 <deallocshm+0x187>
      {
	pte = walkpgdir(proc->pgdir, (char*)a, 0);
801033ff:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103402:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80103408:	8b 40 04             	mov    0x4(%eax),%eax
8010340b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80103412:	00 
80103413:	89 54 24 04          	mov    %edx,0x4(%esp)
80103417:	89 04 24             	mov    %eax,(%esp)
8010341a:	e8 8c 5a 00 00       	call   80108eab <walkpgdir>
8010341f:	89 45 e8             	mov    %eax,-0x18(%ebp)
	if(!pte)
80103422:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80103426:	75 0c                	jne    80103434 <deallocshm+0x96>
	  a += (NPTENTRIES - 1) * PGSIZE;
80103428:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
8010342f:	e9 ea 00 00 00       	jmp    8010351e <deallocshm+0x180>
	else if((*pte & PTE_P) != 0)
80103434:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103437:	8b 00                	mov    (%eax),%eax
80103439:	83 e0 01             	and    $0x1,%eax
8010343c:	84 c0                	test   %al,%al
8010343e:	0f 84 da 00 00 00    	je     8010351e <deallocshm+0x180>
	{
	  pa = (int)p2v(PTE_ADDR(*pte));
80103444:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103447:	8b 00                	mov    (%eax),%eax
80103449:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010344e:	89 04 24             	mov    %eax,(%esp)
80103451:	e8 7f f5 ff ff       	call   801029d5 <p2v>
80103456:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	  if((int)shm.seg[key] == pa)
80103459:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010345c:	8b 04 85 a0 18 11 80 	mov    -0x7feee760(,%eax,4),%eax
80103463:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
80103466:	0f 85 b2 00 00 00    	jne    8010351e <deallocshm+0x180>
	  {
	    void *b = (void*)a;
8010346c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010346f:	89 45 ec             	mov    %eax,-0x14(%ebp)
	    numOfPages = shm.refs[key][1][64];
80103472:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103475:	c1 e0 03             	shl    $0x3,%eax
80103478:	89 c2                	mov    %eax,%edx
8010347a:	c1 e2 06             	shl    $0x6,%edx
8010347d:	01 d0                	add    %edx,%eax
8010347f:	05 a4 2a 11 80       	add    $0x80112aa4,%eax
80103484:	8b 00                	mov    (%eax),%eax
80103486:	89 45 e0             	mov    %eax,-0x20(%ebp)
	    for(; b  < (void*)a + numOfPages*PGSIZE; b += PGSIZE)
80103489:	eb 40                	jmp    801034cb <deallocshm+0x12d>
	    {
	      pte = walkpgdir(proc->pgdir, (char*)b, 0);
8010348b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80103491:	8b 40 04             	mov    0x4(%eax),%eax
80103494:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010349b:	00 
8010349c:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010349f:	89 54 24 04          	mov    %edx,0x4(%esp)
801034a3:	89 04 24             	mov    %eax,(%esp)
801034a6:	e8 00 5a 00 00       	call   80108eab <walkpgdir>
801034ab:	89 45 e8             	mov    %eax,-0x18(%ebp)
	      if(!pte)
801034ae:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801034b2:	75 07                	jne    801034bb <deallocshm+0x11d>
		b += (NPTENTRIES - 1) * PGSIZE;
801034b4:	81 45 ec 00 f0 3f 00 	addl   $0x3ff000,-0x14(%ebp)
	      *pte = 0;
801034bb:	8b 45 e8             	mov    -0x18(%ebp),%eax
801034be:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	  pa = (int)p2v(PTE_ADDR(*pte));
	  if((int)shm.seg[key] == pa)
	  {
	    void *b = (void*)a;
	    numOfPages = shm.refs[key][1][64];
	    for(; b  < (void*)a + numOfPages*PGSIZE; b += PGSIZE)
801034c4:	81 45 ec 00 10 00 00 	addl   $0x1000,-0x14(%ebp)
801034cb:	8b 45 e0             	mov    -0x20(%ebp),%eax
801034ce:	c1 e0 0c             	shl    $0xc,%eax
801034d1:	03 45 f4             	add    -0xc(%ebp),%eax
801034d4:	3b 45 ec             	cmp    -0x14(%ebp),%eax
801034d7:	77 b2                	ja     8010348b <deallocshm+0xed>
	      pte = walkpgdir(proc->pgdir, (char*)b, 0);
	      if(!pte)
		b += (NPTENTRIES - 1) * PGSIZE;
	      *pte = 0;
	    }
	    if(shm.refs[key][0][64]>0)
801034d9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801034dc:	c1 e0 03             	shl    $0x3,%eax
801034df:	89 c2                	mov    %eax,%edx
801034e1:	c1 e2 06             	shl    $0x6,%edx
801034e4:	01 d0                	add    %edx,%eax
801034e6:	05 a0 29 11 80       	add    $0x801129a0,%eax
801034eb:	8b 00                	mov    (%eax),%eax
801034ed:	85 c0                	test   %eax,%eax
801034ef:	7e 47                	jle    80103538 <deallocshm+0x19a>
	    shm.refs[key][0][64]--;
801034f1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801034f4:	c1 e0 03             	shl    $0x3,%eax
801034f7:	89 c2                	mov    %eax,%edx
801034f9:	c1 e2 06             	shl    $0x6,%edx
801034fc:	01 d0                	add    %edx,%eax
801034fe:	05 a0 29 11 80       	add    $0x801129a0,%eax
80103503:	8b 00                	mov    (%eax),%eax
80103505:	8d 50 ff             	lea    -0x1(%eax),%edx
80103508:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010350b:	c1 e0 03             	shl    $0x3,%eax
8010350e:	89 c1                	mov    %eax,%ecx
80103510:	c1 e1 06             	shl    $0x6,%ecx
80103513:	01 c8                	add    %ecx,%eax
80103515:	05 a0 29 11 80       	add    $0x801129a0,%eax
8010351a:	89 10                	mov    %edx,(%eax)
	    break;
8010351c:	eb 1a                	jmp    80103538 <deallocshm+0x19a>
  acquire(&shm.lock);
  for(key = 0;key<numOfSegs;key++)
  {    
    if(shm.refs[key][0][proc->pid])
    {
      for(; a  < proc->sz; a += PGSIZE)
8010351e:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80103525:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010352b:	8b 00                	mov    (%eax),%eax
8010352d:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103530:	0f 87 c9 fe ff ff    	ja     801033ff <deallocshm+0x61>
80103536:	eb 01                	jmp    80103539 <deallocshm+0x19b>
		b += (NPTENTRIES - 1) * PGSIZE;
	      *pte = 0;
	    }
	    if(shm.refs[key][0][64]>0)
	    shm.refs[key][0][64]--;
	    break;
80103538:	90                   	nop
  uint a = 0;
  int key, pa, numOfPages;
  pte_t *pte;
  
  acquire(&shm.lock);
  for(key = 0;key<numOfSegs;key++)
80103539:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
8010353d:	81 7d f0 ff 03 00 00 	cmpl   $0x3ff,-0x10(%ebp)
80103544:	0f 8e 85 fe ff ff    	jle    801033cf <deallocshm+0x31>
	  }
	}
      }
    }
  }
  release(&shm.lock);
8010354a:	c7 04 24 a0 48 19 80 	movl   $0x801948a0,(%esp)
80103551:	e8 34 28 00 00       	call   80105d8a <release>

}
80103556:	c9                   	leave  
80103557:	c3                   	ret    

80103558 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80103558:	55                   	push   %ebp
80103559:	89 e5                	mov    %esp,%ebp
8010355b:	53                   	push   %ebx
8010355c:	83 ec 14             	sub    $0x14,%esp
8010355f:	8b 45 08             	mov    0x8(%ebp),%eax
80103562:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80103566:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
8010356a:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
8010356e:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80103572:	ec                   	in     (%dx),%al
80103573:	89 c3                	mov    %eax,%ebx
80103575:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80103578:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
8010357c:	83 c4 14             	add    $0x14,%esp
8010357f:	5b                   	pop    %ebx
80103580:	5d                   	pop    %ebp
80103581:	c3                   	ret    

80103582 <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
80103582:	55                   	push   %ebp
80103583:	89 e5                	mov    %esp,%ebp
80103585:	83 ec 14             	sub    $0x14,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
80103588:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
8010358f:	e8 c4 ff ff ff       	call   80103558 <inb>
80103594:	0f b6 c0             	movzbl %al,%eax
80103597:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
8010359a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010359d:	83 e0 01             	and    $0x1,%eax
801035a0:	85 c0                	test   %eax,%eax
801035a2:	75 0a                	jne    801035ae <kbdgetc+0x2c>
    return -1;
801035a4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801035a9:	e9 23 01 00 00       	jmp    801036d1 <kbdgetc+0x14f>
  data = inb(KBDATAP);
801035ae:	c7 04 24 60 00 00 00 	movl   $0x60,(%esp)
801035b5:	e8 9e ff ff ff       	call   80103558 <inb>
801035ba:	0f b6 c0             	movzbl %al,%eax
801035bd:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
801035c0:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
801035c7:	75 17                	jne    801035e0 <kbdgetc+0x5e>
    shift |= E0ESC;
801035c9:	a1 5c d6 10 80       	mov    0x8010d65c,%eax
801035ce:	83 c8 40             	or     $0x40,%eax
801035d1:	a3 5c d6 10 80       	mov    %eax,0x8010d65c
    return 0;
801035d6:	b8 00 00 00 00       	mov    $0x0,%eax
801035db:	e9 f1 00 00 00       	jmp    801036d1 <kbdgetc+0x14f>
  } else if(data & 0x80){
801035e0:	8b 45 fc             	mov    -0x4(%ebp),%eax
801035e3:	25 80 00 00 00       	and    $0x80,%eax
801035e8:	85 c0                	test   %eax,%eax
801035ea:	74 45                	je     80103631 <kbdgetc+0xaf>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
801035ec:	a1 5c d6 10 80       	mov    0x8010d65c,%eax
801035f1:	83 e0 40             	and    $0x40,%eax
801035f4:	85 c0                	test   %eax,%eax
801035f6:	75 08                	jne    80103600 <kbdgetc+0x7e>
801035f8:	8b 45 fc             	mov    -0x4(%ebp),%eax
801035fb:	83 e0 7f             	and    $0x7f,%eax
801035fe:	eb 03                	jmp    80103603 <kbdgetc+0x81>
80103600:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103603:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
80103606:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103609:	05 20 b0 10 80       	add    $0x8010b020,%eax
8010360e:	0f b6 00             	movzbl (%eax),%eax
80103611:	83 c8 40             	or     $0x40,%eax
80103614:	0f b6 c0             	movzbl %al,%eax
80103617:	f7 d0                	not    %eax
80103619:	89 c2                	mov    %eax,%edx
8010361b:	a1 5c d6 10 80       	mov    0x8010d65c,%eax
80103620:	21 d0                	and    %edx,%eax
80103622:	a3 5c d6 10 80       	mov    %eax,0x8010d65c
    return 0;
80103627:	b8 00 00 00 00       	mov    $0x0,%eax
8010362c:	e9 a0 00 00 00       	jmp    801036d1 <kbdgetc+0x14f>
  } else if(shift & E0ESC){
80103631:	a1 5c d6 10 80       	mov    0x8010d65c,%eax
80103636:	83 e0 40             	and    $0x40,%eax
80103639:	85 c0                	test   %eax,%eax
8010363b:	74 14                	je     80103651 <kbdgetc+0xcf>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
8010363d:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
80103644:	a1 5c d6 10 80       	mov    0x8010d65c,%eax
80103649:	83 e0 bf             	and    $0xffffffbf,%eax
8010364c:	a3 5c d6 10 80       	mov    %eax,0x8010d65c
  }

  shift |= shiftcode[data];
80103651:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103654:	05 20 b0 10 80       	add    $0x8010b020,%eax
80103659:	0f b6 00             	movzbl (%eax),%eax
8010365c:	0f b6 d0             	movzbl %al,%edx
8010365f:	a1 5c d6 10 80       	mov    0x8010d65c,%eax
80103664:	09 d0                	or     %edx,%eax
80103666:	a3 5c d6 10 80       	mov    %eax,0x8010d65c
  shift ^= togglecode[data];
8010366b:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010366e:	05 20 b1 10 80       	add    $0x8010b120,%eax
80103673:	0f b6 00             	movzbl (%eax),%eax
80103676:	0f b6 d0             	movzbl %al,%edx
80103679:	a1 5c d6 10 80       	mov    0x8010d65c,%eax
8010367e:	31 d0                	xor    %edx,%eax
80103680:	a3 5c d6 10 80       	mov    %eax,0x8010d65c
  c = charcode[shift & (CTL | SHIFT)][data];
80103685:	a1 5c d6 10 80       	mov    0x8010d65c,%eax
8010368a:	83 e0 03             	and    $0x3,%eax
8010368d:	8b 04 85 20 b5 10 80 	mov    -0x7fef4ae0(,%eax,4),%eax
80103694:	03 45 fc             	add    -0x4(%ebp),%eax
80103697:	0f b6 00             	movzbl (%eax),%eax
8010369a:	0f b6 c0             	movzbl %al,%eax
8010369d:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
801036a0:	a1 5c d6 10 80       	mov    0x8010d65c,%eax
801036a5:	83 e0 08             	and    $0x8,%eax
801036a8:	85 c0                	test   %eax,%eax
801036aa:	74 22                	je     801036ce <kbdgetc+0x14c>
    if('a' <= c && c <= 'z')
801036ac:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
801036b0:	76 0c                	jbe    801036be <kbdgetc+0x13c>
801036b2:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
801036b6:	77 06                	ja     801036be <kbdgetc+0x13c>
      c += 'A' - 'a';
801036b8:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
801036bc:	eb 10                	jmp    801036ce <kbdgetc+0x14c>
    else if('A' <= c && c <= 'Z')
801036be:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
801036c2:	76 0a                	jbe    801036ce <kbdgetc+0x14c>
801036c4:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
801036c8:	77 04                	ja     801036ce <kbdgetc+0x14c>
      c += 'a' - 'A';
801036ca:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
801036ce:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
801036d1:	c9                   	leave  
801036d2:	c3                   	ret    

801036d3 <kbdintr>:

void
kbdintr(void)
{
801036d3:	55                   	push   %ebp
801036d4:	89 e5                	mov    %esp,%ebp
801036d6:	83 ec 18             	sub    $0x18,%esp
  consoleintr(kbdgetc);
801036d9:	c7 04 24 82 35 10 80 	movl   $0x80103582,(%esp)
801036e0:	e8 c8 d0 ff ff       	call   801007ad <consoleintr>
}
801036e5:	c9                   	leave  
801036e6:	c3                   	ret    
	...

801036e8 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801036e8:	55                   	push   %ebp
801036e9:	89 e5                	mov    %esp,%ebp
801036eb:	83 ec 08             	sub    $0x8,%esp
801036ee:	8b 55 08             	mov    0x8(%ebp),%edx
801036f1:	8b 45 0c             	mov    0xc(%ebp),%eax
801036f4:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801036f8:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801036fb:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801036ff:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103703:	ee                   	out    %al,(%dx)
}
80103704:	c9                   	leave  
80103705:	c3                   	ret    

80103706 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80103706:	55                   	push   %ebp
80103707:	89 e5                	mov    %esp,%ebp
80103709:	53                   	push   %ebx
8010370a:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
8010370d:	9c                   	pushf  
8010370e:	5b                   	pop    %ebx
8010370f:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80103712:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103715:	83 c4 10             	add    $0x10,%esp
80103718:	5b                   	pop    %ebx
80103719:	5d                   	pop    %ebp
8010371a:	c3                   	ret    

8010371b <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
8010371b:	55                   	push   %ebp
8010371c:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
8010371e:	a1 d4 48 19 80       	mov    0x801948d4,%eax
80103723:	8b 55 08             	mov    0x8(%ebp),%edx
80103726:	c1 e2 02             	shl    $0x2,%edx
80103729:	01 c2                	add    %eax,%edx
8010372b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010372e:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
80103730:	a1 d4 48 19 80       	mov    0x801948d4,%eax
80103735:	83 c0 20             	add    $0x20,%eax
80103738:	8b 00                	mov    (%eax),%eax
}
8010373a:	5d                   	pop    %ebp
8010373b:	c3                   	ret    

8010373c <lapicinit>:
//PAGEBREAK!

void
lapicinit(int c)
{
8010373c:	55                   	push   %ebp
8010373d:	89 e5                	mov    %esp,%ebp
8010373f:	83 ec 08             	sub    $0x8,%esp
  if(!lapic) 
80103742:	a1 d4 48 19 80       	mov    0x801948d4,%eax
80103747:	85 c0                	test   %eax,%eax
80103749:	0f 84 47 01 00 00    	je     80103896 <lapicinit+0x15a>
    return;

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
8010374f:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
80103756:	00 
80103757:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
8010375e:	e8 b8 ff ff ff       	call   8010371b <lapicw>

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.  
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
80103763:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
8010376a:	00 
8010376b:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
80103772:	e8 a4 ff ff ff       	call   8010371b <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
80103777:	c7 44 24 04 20 00 02 	movl   $0x20020,0x4(%esp)
8010377e:	00 
8010377f:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103786:	e8 90 ff ff ff       	call   8010371b <lapicw>
  lapicw(TICR, 10000000); 
8010378b:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
80103792:	00 
80103793:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
8010379a:	e8 7c ff ff ff       	call   8010371b <lapicw>

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
8010379f:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
801037a6:	00 
801037a7:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
801037ae:	e8 68 ff ff ff       	call   8010371b <lapicw>
  lapicw(LINT1, MASKED);
801037b3:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
801037ba:	00 
801037bb:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
801037c2:	e8 54 ff ff ff       	call   8010371b <lapicw>

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
801037c7:	a1 d4 48 19 80       	mov    0x801948d4,%eax
801037cc:	83 c0 30             	add    $0x30,%eax
801037cf:	8b 00                	mov    (%eax),%eax
801037d1:	c1 e8 10             	shr    $0x10,%eax
801037d4:	25 ff 00 00 00       	and    $0xff,%eax
801037d9:	83 f8 03             	cmp    $0x3,%eax
801037dc:	76 14                	jbe    801037f2 <lapicinit+0xb6>
    lapicw(PCINT, MASKED);
801037de:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
801037e5:	00 
801037e6:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
801037ed:	e8 29 ff ff ff       	call   8010371b <lapicw>

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
801037f2:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
801037f9:	00 
801037fa:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
80103801:	e8 15 ff ff ff       	call   8010371b <lapicw>

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
80103806:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010380d:	00 
8010380e:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103815:	e8 01 ff ff ff       	call   8010371b <lapicw>
  lapicw(ESR, 0);
8010381a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103821:	00 
80103822:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103829:	e8 ed fe ff ff       	call   8010371b <lapicw>

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
8010382e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103835:	00 
80103836:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
8010383d:	e8 d9 fe ff ff       	call   8010371b <lapicw>

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
80103842:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103849:	00 
8010384a:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80103851:	e8 c5 fe ff ff       	call   8010371b <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
80103856:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
8010385d:	00 
8010385e:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103865:	e8 b1 fe ff ff       	call   8010371b <lapicw>
  while(lapic[ICRLO] & DELIVS)
8010386a:	90                   	nop
8010386b:	a1 d4 48 19 80       	mov    0x801948d4,%eax
80103870:	05 00 03 00 00       	add    $0x300,%eax
80103875:	8b 00                	mov    (%eax),%eax
80103877:	25 00 10 00 00       	and    $0x1000,%eax
8010387c:	85 c0                	test   %eax,%eax
8010387e:	75 eb                	jne    8010386b <lapicinit+0x12f>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
80103880:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103887:	00 
80103888:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010388f:	e8 87 fe ff ff       	call   8010371b <lapicw>
80103894:	eb 01                	jmp    80103897 <lapicinit+0x15b>

void
lapicinit(int c)
{
  if(!lapic) 
    return;
80103896:	90                   	nop
  while(lapic[ICRLO] & DELIVS)
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
}
80103897:	c9                   	leave  
80103898:	c3                   	ret    

80103899 <cpunum>:

int
cpunum(void)
{
80103899:	55                   	push   %ebp
8010389a:	89 e5                	mov    %esp,%ebp
8010389c:	83 ec 18             	sub    $0x18,%esp
  // Cannot call cpu when interrupts are enabled:
  // result not guaranteed to last long enough to be used!
  // Would prefer to panic but even printing is chancy here:
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
8010389f:	e8 62 fe ff ff       	call   80103706 <readeflags>
801038a4:	25 00 02 00 00       	and    $0x200,%eax
801038a9:	85 c0                	test   %eax,%eax
801038ab:	74 29                	je     801038d6 <cpunum+0x3d>
    static int n;
    if(n++ == 0)
801038ad:	a1 60 d6 10 80       	mov    0x8010d660,%eax
801038b2:	85 c0                	test   %eax,%eax
801038b4:	0f 94 c2             	sete   %dl
801038b7:	83 c0 01             	add    $0x1,%eax
801038ba:	a3 60 d6 10 80       	mov    %eax,0x8010d660
801038bf:	84 d2                	test   %dl,%dl
801038c1:	74 13                	je     801038d6 <cpunum+0x3d>
      cprintf("cpu called from %x with interrupts enabled\n",
801038c3:	8b 45 04             	mov    0x4(%ebp),%eax
801038c6:	89 44 24 04          	mov    %eax,0x4(%esp)
801038ca:	c7 04 24 28 9b 10 80 	movl   $0x80109b28,(%esp)
801038d1:	e8 cb ca ff ff       	call   801003a1 <cprintf>
        __builtin_return_address(0));
  }

  if(lapic)
801038d6:	a1 d4 48 19 80       	mov    0x801948d4,%eax
801038db:	85 c0                	test   %eax,%eax
801038dd:	74 0f                	je     801038ee <cpunum+0x55>
    return lapic[ID]>>24;
801038df:	a1 d4 48 19 80       	mov    0x801948d4,%eax
801038e4:	83 c0 20             	add    $0x20,%eax
801038e7:	8b 00                	mov    (%eax),%eax
801038e9:	c1 e8 18             	shr    $0x18,%eax
801038ec:	eb 05                	jmp    801038f3 <cpunum+0x5a>
  return 0;
801038ee:	b8 00 00 00 00       	mov    $0x0,%eax
}
801038f3:	c9                   	leave  
801038f4:	c3                   	ret    

801038f5 <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
801038f5:	55                   	push   %ebp
801038f6:	89 e5                	mov    %esp,%ebp
801038f8:	83 ec 08             	sub    $0x8,%esp
  if(lapic)
801038fb:	a1 d4 48 19 80       	mov    0x801948d4,%eax
80103900:	85 c0                	test   %eax,%eax
80103902:	74 14                	je     80103918 <lapiceoi+0x23>
    lapicw(EOI, 0);
80103904:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010390b:	00 
8010390c:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80103913:	e8 03 fe ff ff       	call   8010371b <lapicw>
}
80103918:	c9                   	leave  
80103919:	c3                   	ret    

8010391a <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
8010391a:	55                   	push   %ebp
8010391b:	89 e5                	mov    %esp,%ebp
}
8010391d:	5d                   	pop    %ebp
8010391e:	c3                   	ret    

8010391f <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
8010391f:	55                   	push   %ebp
80103920:	89 e5                	mov    %esp,%ebp
80103922:	83 ec 1c             	sub    $0x1c,%esp
80103925:	8b 45 08             	mov    0x8(%ebp),%eax
80103928:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;
  
  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
8010392b:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80103932:	00 
80103933:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
8010393a:	e8 a9 fd ff ff       	call   801036e8 <outb>
  outb(IO_RTC+1, 0x0A);
8010393f:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80103946:	00 
80103947:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
8010394e:	e8 95 fd ff ff       	call   801036e8 <outb>
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
80103953:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
8010395a:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010395d:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
80103962:	8b 45 f8             	mov    -0x8(%ebp),%eax
80103965:	8d 50 02             	lea    0x2(%eax),%edx
80103968:	8b 45 0c             	mov    0xc(%ebp),%eax
8010396b:	c1 e8 04             	shr    $0x4,%eax
8010396e:	66 89 02             	mov    %ax,(%edx)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
80103971:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80103975:	c1 e0 18             	shl    $0x18,%eax
80103978:	89 44 24 04          	mov    %eax,0x4(%esp)
8010397c:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80103983:	e8 93 fd ff ff       	call   8010371b <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
80103988:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
8010398f:	00 
80103990:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103997:	e8 7f fd ff ff       	call   8010371b <lapicw>
  microdelay(200);
8010399c:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
801039a3:	e8 72 ff ff ff       	call   8010391a <microdelay>
  lapicw(ICRLO, INIT | LEVEL);
801039a8:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
801039af:	00 
801039b0:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801039b7:	e8 5f fd ff ff       	call   8010371b <lapicw>
  microdelay(100);    // should be 10ms, but too slow in Bochs!
801039bc:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
801039c3:	e8 52 ff ff ff       	call   8010391a <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
801039c8:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801039cf:	eb 40                	jmp    80103a11 <lapicstartap+0xf2>
    lapicw(ICRHI, apicid<<24);
801039d1:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
801039d5:	c1 e0 18             	shl    $0x18,%eax
801039d8:	89 44 24 04          	mov    %eax,0x4(%esp)
801039dc:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
801039e3:	e8 33 fd ff ff       	call   8010371b <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
801039e8:	8b 45 0c             	mov    0xc(%ebp),%eax
801039eb:	c1 e8 0c             	shr    $0xc,%eax
801039ee:	80 cc 06             	or     $0x6,%ah
801039f1:	89 44 24 04          	mov    %eax,0x4(%esp)
801039f5:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801039fc:	e8 1a fd ff ff       	call   8010371b <lapicw>
    microdelay(200);
80103a01:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103a08:	e8 0d ff ff ff       	call   8010391a <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80103a0d:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103a11:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
80103a15:	7e ba                	jle    801039d1 <lapicstartap+0xb2>
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
80103a17:	c9                   	leave  
80103a18:	c3                   	ret    
80103a19:	00 00                	add    %al,(%eax)
	...

80103a1c <initlog>:

static void recover_from_log(void);

void
initlog(void)
{
80103a1c:	55                   	push   %ebp
80103a1d:	89 e5                	mov    %esp,%ebp
80103a1f:	83 ec 28             	sub    $0x28,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
80103a22:	c7 44 24 04 54 9b 10 	movl   $0x80109b54,0x4(%esp)
80103a29:	80 
80103a2a:	c7 04 24 e0 48 19 80 	movl   $0x801948e0,(%esp)
80103a31:	e8 98 22 00 00       	call   80105cce <initlock>
  readsb(ROOTDEV, &sb);
80103a36:	8d 45 e8             	lea    -0x18(%ebp),%eax
80103a39:	89 44 24 04          	mov    %eax,0x4(%esp)
80103a3d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103a44:	e8 a3 d8 ff ff       	call   801012ec <readsb>
  log.start = sb.size - sb.nlog;
80103a49:	8b 55 e8             	mov    -0x18(%ebp),%edx
80103a4c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a4f:	89 d1                	mov    %edx,%ecx
80103a51:	29 c1                	sub    %eax,%ecx
80103a53:	89 c8                	mov    %ecx,%eax
80103a55:	a3 14 49 19 80       	mov    %eax,0x80194914
  log.size = sb.nlog;
80103a5a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a5d:	a3 18 49 19 80       	mov    %eax,0x80194918
  log.dev = ROOTDEV;
80103a62:	c7 05 20 49 19 80 01 	movl   $0x1,0x80194920
80103a69:	00 00 00 
  recover_from_log();
80103a6c:	e8 97 01 00 00       	call   80103c08 <recover_from_log>
}
80103a71:	c9                   	leave  
80103a72:	c3                   	ret    

80103a73 <install_trans>:

// Copy committed blocks from log to their home location
static void 
install_trans(void)
{
80103a73:	55                   	push   %ebp
80103a74:	89 e5                	mov    %esp,%ebp
80103a76:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103a79:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103a80:	e9 89 00 00 00       	jmp    80103b0e <install_trans+0x9b>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
80103a85:	a1 14 49 19 80       	mov    0x80194914,%eax
80103a8a:	03 45 f4             	add    -0xc(%ebp),%eax
80103a8d:	83 c0 01             	add    $0x1,%eax
80103a90:	89 c2                	mov    %eax,%edx
80103a92:	a1 20 49 19 80       	mov    0x80194920,%eax
80103a97:	89 54 24 04          	mov    %edx,0x4(%esp)
80103a9b:	89 04 24             	mov    %eax,(%esp)
80103a9e:	e8 03 c7 ff ff       	call   801001a6 <bread>
80103aa3:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.sector[tail]); // read dst
80103aa6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103aa9:	83 c0 10             	add    $0x10,%eax
80103aac:	8b 04 85 e8 48 19 80 	mov    -0x7fe6b718(,%eax,4),%eax
80103ab3:	89 c2                	mov    %eax,%edx
80103ab5:	a1 20 49 19 80       	mov    0x80194920,%eax
80103aba:	89 54 24 04          	mov    %edx,0x4(%esp)
80103abe:	89 04 24             	mov    %eax,(%esp)
80103ac1:	e8 e0 c6 ff ff       	call   801001a6 <bread>
80103ac6:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
80103ac9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103acc:	8d 50 18             	lea    0x18(%eax),%edx
80103acf:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103ad2:	83 c0 18             	add    $0x18,%eax
80103ad5:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80103adc:	00 
80103add:	89 54 24 04          	mov    %edx,0x4(%esp)
80103ae1:	89 04 24             	mov    %eax,(%esp)
80103ae4:	e8 60 25 00 00       	call   80106049 <memmove>
    bwrite(dbuf);  // write dst to disk
80103ae9:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103aec:	89 04 24             	mov    %eax,(%esp)
80103aef:	e8 e9 c6 ff ff       	call   801001dd <bwrite>
    brelse(lbuf); 
80103af4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103af7:	89 04 24             	mov    %eax,(%esp)
80103afa:	e8 18 c7 ff ff       	call   80100217 <brelse>
    brelse(dbuf);
80103aff:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103b02:	89 04 24             	mov    %eax,(%esp)
80103b05:	e8 0d c7 ff ff       	call   80100217 <brelse>
static void 
install_trans(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103b0a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103b0e:	a1 24 49 19 80       	mov    0x80194924,%eax
80103b13:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103b16:	0f 8f 69 ff ff ff    	jg     80103a85 <install_trans+0x12>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    bwrite(dbuf);  // write dst to disk
    brelse(lbuf); 
    brelse(dbuf);
  }
}
80103b1c:	c9                   	leave  
80103b1d:	c3                   	ret    

80103b1e <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
80103b1e:	55                   	push   %ebp
80103b1f:	89 e5                	mov    %esp,%ebp
80103b21:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80103b24:	a1 14 49 19 80       	mov    0x80194914,%eax
80103b29:	89 c2                	mov    %eax,%edx
80103b2b:	a1 20 49 19 80       	mov    0x80194920,%eax
80103b30:	89 54 24 04          	mov    %edx,0x4(%esp)
80103b34:	89 04 24             	mov    %eax,(%esp)
80103b37:	e8 6a c6 ff ff       	call   801001a6 <bread>
80103b3c:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
80103b3f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b42:	83 c0 18             	add    $0x18,%eax
80103b45:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
80103b48:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103b4b:	8b 00                	mov    (%eax),%eax
80103b4d:	a3 24 49 19 80       	mov    %eax,0x80194924
  for (i = 0; i < log.lh.n; i++) {
80103b52:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103b59:	eb 1b                	jmp    80103b76 <read_head+0x58>
    log.lh.sector[i] = lh->sector[i];
80103b5b:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103b5e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103b61:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
80103b65:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103b68:	83 c2 10             	add    $0x10,%edx
80103b6b:	89 04 95 e8 48 19 80 	mov    %eax,-0x7fe6b718(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
80103b72:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103b76:	a1 24 49 19 80       	mov    0x80194924,%eax
80103b7b:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103b7e:	7f db                	jg     80103b5b <read_head+0x3d>
    log.lh.sector[i] = lh->sector[i];
  }
  brelse(buf);
80103b80:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b83:	89 04 24             	mov    %eax,(%esp)
80103b86:	e8 8c c6 ff ff       	call   80100217 <brelse>
}
80103b8b:	c9                   	leave  
80103b8c:	c3                   	ret    

80103b8d <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
80103b8d:	55                   	push   %ebp
80103b8e:	89 e5                	mov    %esp,%ebp
80103b90:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80103b93:	a1 14 49 19 80       	mov    0x80194914,%eax
80103b98:	89 c2                	mov    %eax,%edx
80103b9a:	a1 20 49 19 80       	mov    0x80194920,%eax
80103b9f:	89 54 24 04          	mov    %edx,0x4(%esp)
80103ba3:	89 04 24             	mov    %eax,(%esp)
80103ba6:	e8 fb c5 ff ff       	call   801001a6 <bread>
80103bab:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
80103bae:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103bb1:	83 c0 18             	add    $0x18,%eax
80103bb4:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
80103bb7:	8b 15 24 49 19 80    	mov    0x80194924,%edx
80103bbd:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103bc0:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
80103bc2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103bc9:	eb 1b                	jmp    80103be6 <write_head+0x59>
    hb->sector[i] = log.lh.sector[i];
80103bcb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103bce:	83 c0 10             	add    $0x10,%eax
80103bd1:	8b 0c 85 e8 48 19 80 	mov    -0x7fe6b718(,%eax,4),%ecx
80103bd8:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103bdb:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103bde:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
80103be2:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103be6:	a1 24 49 19 80       	mov    0x80194924,%eax
80103beb:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103bee:	7f db                	jg     80103bcb <write_head+0x3e>
    hb->sector[i] = log.lh.sector[i];
  }
  bwrite(buf);
80103bf0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103bf3:	89 04 24             	mov    %eax,(%esp)
80103bf6:	e8 e2 c5 ff ff       	call   801001dd <bwrite>
  brelse(buf);
80103bfb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103bfe:	89 04 24             	mov    %eax,(%esp)
80103c01:	e8 11 c6 ff ff       	call   80100217 <brelse>
}
80103c06:	c9                   	leave  
80103c07:	c3                   	ret    

80103c08 <recover_from_log>:

static void
recover_from_log(void)
{
80103c08:	55                   	push   %ebp
80103c09:	89 e5                	mov    %esp,%ebp
80103c0b:	83 ec 08             	sub    $0x8,%esp
  read_head();      
80103c0e:	e8 0b ff ff ff       	call   80103b1e <read_head>
  install_trans(); // if committed, copy from log to disk
80103c13:	e8 5b fe ff ff       	call   80103a73 <install_trans>
  log.lh.n = 0;
80103c18:	c7 05 24 49 19 80 00 	movl   $0x0,0x80194924
80103c1f:	00 00 00 
  write_head(); // clear the log
80103c22:	e8 66 ff ff ff       	call   80103b8d <write_head>
}
80103c27:	c9                   	leave  
80103c28:	c3                   	ret    

80103c29 <begin_trans>:

void
begin_trans(void)
{
80103c29:	55                   	push   %ebp
80103c2a:	89 e5                	mov    %esp,%ebp
80103c2c:	83 ec 18             	sub    $0x18,%esp
  acquire(&log.lock);
80103c2f:	c7 04 24 e0 48 19 80 	movl   $0x801948e0,(%esp)
80103c36:	e8 b4 20 00 00       	call   80105cef <acquire>
  while (log.busy) {
80103c3b:	eb 14                	jmp    80103c51 <begin_trans+0x28>
  sleep(&log, &log.lock);
80103c3d:	c7 44 24 04 e0 48 19 	movl   $0x801948e0,0x4(%esp)
80103c44:	80 
80103c45:	c7 04 24 e0 48 19 80 	movl   $0x801948e0,(%esp)
80103c4c:	e8 5f 1c 00 00       	call   801058b0 <sleep>

void
begin_trans(void)
{
  acquire(&log.lock);
  while (log.busy) {
80103c51:	a1 1c 49 19 80       	mov    0x8019491c,%eax
80103c56:	85 c0                	test   %eax,%eax
80103c58:	75 e3                	jne    80103c3d <begin_trans+0x14>
  sleep(&log, &log.lock);
  }
  log.busy = 1;
80103c5a:	c7 05 1c 49 19 80 01 	movl   $0x1,0x8019491c
80103c61:	00 00 00 
  release(&log.lock);
80103c64:	c7 04 24 e0 48 19 80 	movl   $0x801948e0,(%esp)
80103c6b:	e8 1a 21 00 00       	call   80105d8a <release>
}
80103c70:	c9                   	leave  
80103c71:	c3                   	ret    

80103c72 <commit_trans>:

void
commit_trans(void)
{
80103c72:	55                   	push   %ebp
80103c73:	89 e5                	mov    %esp,%ebp
80103c75:	83 ec 18             	sub    $0x18,%esp
  if (log.lh.n > 0) {
80103c78:	a1 24 49 19 80       	mov    0x80194924,%eax
80103c7d:	85 c0                	test   %eax,%eax
80103c7f:	7e 19                	jle    80103c9a <commit_trans+0x28>
    write_head();    // Write header to disk -- the real commit
80103c81:	e8 07 ff ff ff       	call   80103b8d <write_head>
    install_trans(); // Now install writes to home locations
80103c86:	e8 e8 fd ff ff       	call   80103a73 <install_trans>
    log.lh.n = 0; 
80103c8b:	c7 05 24 49 19 80 00 	movl   $0x0,0x80194924
80103c92:	00 00 00 
    write_head();    // Erase the transaction from the log
80103c95:	e8 f3 fe ff ff       	call   80103b8d <write_head>
  }
  
  acquire(&log.lock);
80103c9a:	c7 04 24 e0 48 19 80 	movl   $0x801948e0,(%esp)
80103ca1:	e8 49 20 00 00       	call   80105cef <acquire>
  log.busy = 0;
80103ca6:	c7 05 1c 49 19 80 00 	movl   $0x0,0x8019491c
80103cad:	00 00 00 
  wakeup(&log);
80103cb0:	c7 04 24 e0 48 19 80 	movl   $0x801948e0,(%esp)
80103cb7:	e8 30 1d 00 00       	call   801059ec <wakeup>
  release(&log.lock);
80103cbc:	c7 04 24 e0 48 19 80 	movl   $0x801948e0,(%esp)
80103cc3:	e8 c2 20 00 00       	call   80105d8a <release>
}
80103cc8:	c9                   	leave  
80103cc9:	c3                   	ret    

80103cca <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80103cca:	55                   	push   %ebp
80103ccb:	89 e5                	mov    %esp,%ebp
80103ccd:	83 ec 28             	sub    $0x28,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80103cd0:	a1 24 49 19 80       	mov    0x80194924,%eax
80103cd5:	83 f8 09             	cmp    $0x9,%eax
80103cd8:	7f 12                	jg     80103cec <log_write+0x22>
80103cda:	a1 24 49 19 80       	mov    0x80194924,%eax
80103cdf:	8b 15 18 49 19 80    	mov    0x80194918,%edx
80103ce5:	83 ea 01             	sub    $0x1,%edx
80103ce8:	39 d0                	cmp    %edx,%eax
80103cea:	7c 0c                	jl     80103cf8 <log_write+0x2e>
    panic("too big a transaction");
80103cec:	c7 04 24 58 9b 10 80 	movl   $0x80109b58,(%esp)
80103cf3:	e8 45 c8 ff ff       	call   8010053d <panic>
  if (!log.busy)
80103cf8:	a1 1c 49 19 80       	mov    0x8019491c,%eax
80103cfd:	85 c0                	test   %eax,%eax
80103cff:	75 0c                	jne    80103d0d <log_write+0x43>
    panic("write outside of trans");
80103d01:	c7 04 24 6e 9b 10 80 	movl   $0x80109b6e,(%esp)
80103d08:	e8 30 c8 ff ff       	call   8010053d <panic>

  for (i = 0; i < log.lh.n; i++) {
80103d0d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103d14:	eb 1d                	jmp    80103d33 <log_write+0x69>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
80103d16:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d19:	83 c0 10             	add    $0x10,%eax
80103d1c:	8b 04 85 e8 48 19 80 	mov    -0x7fe6b718(,%eax,4),%eax
80103d23:	89 c2                	mov    %eax,%edx
80103d25:	8b 45 08             	mov    0x8(%ebp),%eax
80103d28:	8b 40 08             	mov    0x8(%eax),%eax
80103d2b:	39 c2                	cmp    %eax,%edx
80103d2d:	74 10                	je     80103d3f <log_write+0x75>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    panic("too big a transaction");
  if (!log.busy)
    panic("write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
80103d2f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103d33:	a1 24 49 19 80       	mov    0x80194924,%eax
80103d38:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103d3b:	7f d9                	jg     80103d16 <log_write+0x4c>
80103d3d:	eb 01                	jmp    80103d40 <log_write+0x76>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
      break;
80103d3f:	90                   	nop
  }
  log.lh.sector[i] = b->sector;
80103d40:	8b 45 08             	mov    0x8(%ebp),%eax
80103d43:	8b 40 08             	mov    0x8(%eax),%eax
80103d46:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103d49:	83 c2 10             	add    $0x10,%edx
80103d4c:	89 04 95 e8 48 19 80 	mov    %eax,-0x7fe6b718(,%edx,4)
  struct buf *lbuf = bread(b->dev, log.start+i+1);
80103d53:	a1 14 49 19 80       	mov    0x80194914,%eax
80103d58:	03 45 f4             	add    -0xc(%ebp),%eax
80103d5b:	83 c0 01             	add    $0x1,%eax
80103d5e:	89 c2                	mov    %eax,%edx
80103d60:	8b 45 08             	mov    0x8(%ebp),%eax
80103d63:	8b 40 04             	mov    0x4(%eax),%eax
80103d66:	89 54 24 04          	mov    %edx,0x4(%esp)
80103d6a:	89 04 24             	mov    %eax,(%esp)
80103d6d:	e8 34 c4 ff ff       	call   801001a6 <bread>
80103d72:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(lbuf->data, b->data, BSIZE);
80103d75:	8b 45 08             	mov    0x8(%ebp),%eax
80103d78:	8d 50 18             	lea    0x18(%eax),%edx
80103d7b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d7e:	83 c0 18             	add    $0x18,%eax
80103d81:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80103d88:	00 
80103d89:	89 54 24 04          	mov    %edx,0x4(%esp)
80103d8d:	89 04 24             	mov    %eax,(%esp)
80103d90:	e8 b4 22 00 00       	call   80106049 <memmove>
  bwrite(lbuf);
80103d95:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d98:	89 04 24             	mov    %eax,(%esp)
80103d9b:	e8 3d c4 ff ff       	call   801001dd <bwrite>
  brelse(lbuf);
80103da0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103da3:	89 04 24             	mov    %eax,(%esp)
80103da6:	e8 6c c4 ff ff       	call   80100217 <brelse>
  if (i == log.lh.n)
80103dab:	a1 24 49 19 80       	mov    0x80194924,%eax
80103db0:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103db3:	75 0d                	jne    80103dc2 <log_write+0xf8>
    log.lh.n++;
80103db5:	a1 24 49 19 80       	mov    0x80194924,%eax
80103dba:	83 c0 01             	add    $0x1,%eax
80103dbd:	a3 24 49 19 80       	mov    %eax,0x80194924
  b->flags |= B_DIRTY; // XXX prevent eviction
80103dc2:	8b 45 08             	mov    0x8(%ebp),%eax
80103dc5:	8b 00                	mov    (%eax),%eax
80103dc7:	89 c2                	mov    %eax,%edx
80103dc9:	83 ca 04             	or     $0x4,%edx
80103dcc:	8b 45 08             	mov    0x8(%ebp),%eax
80103dcf:	89 10                	mov    %edx,(%eax)
}
80103dd1:	c9                   	leave  
80103dd2:	c3                   	ret    
	...

80103dd4 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80103dd4:	55                   	push   %ebp
80103dd5:	89 e5                	mov    %esp,%ebp
80103dd7:	8b 45 08             	mov    0x8(%ebp),%eax
80103dda:	05 00 00 00 80       	add    $0x80000000,%eax
80103ddf:	5d                   	pop    %ebp
80103de0:	c3                   	ret    

80103de1 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80103de1:	55                   	push   %ebp
80103de2:	89 e5                	mov    %esp,%ebp
80103de4:	8b 45 08             	mov    0x8(%ebp),%eax
80103de7:	05 00 00 00 80       	add    $0x80000000,%eax
80103dec:	5d                   	pop    %ebp
80103ded:	c3                   	ret    

80103dee <xchg>:
  asm volatile("sti");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
80103dee:	55                   	push   %ebp
80103def:	89 e5                	mov    %esp,%ebp
80103df1:	53                   	push   %ebx
80103df2:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
80103df5:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80103df8:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
80103dfb:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80103dfe:	89 c3                	mov    %eax,%ebx
80103e00:	89 d8                	mov    %ebx,%eax
80103e02:	f0 87 02             	lock xchg %eax,(%edx)
80103e05:	89 c3                	mov    %eax,%ebx
80103e07:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80103e0a:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103e0d:	83 c4 10             	add    $0x10,%esp
80103e10:	5b                   	pop    %ebx
80103e11:	5d                   	pop    %ebp
80103e12:	c3                   	ret    

80103e13 <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
80103e13:	55                   	push   %ebp
80103e14:	89 e5                	mov    %esp,%ebp
80103e16:	83 e4 f0             	and    $0xfffffff0,%esp
80103e19:	83 ec 10             	sub    $0x10,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80103e1c:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
80103e23:	80 
80103e24:	c7 04 24 5c 7c 19 80 	movl   $0x80197c5c,(%esp)
80103e2b:	e8 b2 eb ff ff       	call   801029e2 <kinit1>
  kvmalloc();      // kernel page table
80103e30:	e8 5d 52 00 00       	call   80109092 <kvmalloc>
  mpinit();        // collect info about this machine
80103e35:	e8 63 04 00 00       	call   8010429d <mpinit>
  lapicinit(mpbcpu());
80103e3a:	e8 2e 02 00 00       	call   8010406d <mpbcpu>
80103e3f:	89 04 24             	mov    %eax,(%esp)
80103e42:	e8 f5 f8 ff ff       	call   8010373c <lapicinit>
  seginit();       // set up segments
80103e47:	e8 e9 4b 00 00       	call   80108a35 <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
80103e4c:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103e52:	0f b6 00             	movzbl (%eax),%eax
80103e55:	0f b6 c0             	movzbl %al,%eax
80103e58:	89 44 24 04          	mov    %eax,0x4(%esp)
80103e5c:	c7 04 24 85 9b 10 80 	movl   $0x80109b85,(%esp)
80103e63:	e8 39 c5 ff ff       	call   801003a1 <cprintf>
  picinit();       // interrupt controller
80103e68:	e8 95 06 00 00       	call   80104502 <picinit>
  ioapicinit();    // another interrupt controller
80103e6d:	e8 53 ea ff ff       	call   801028c5 <ioapicinit>
  consoleinit();   // I/O devices & their interrupts
80103e72:	e8 16 cc ff ff       	call   80100a8d <consoleinit>
  uartinit();      // serial port
80103e77:	e8 04 3f 00 00       	call   80107d80 <uartinit>
  pinit();         // process table
80103e7c:	e8 a3 0b 00 00       	call   80104a24 <pinit>
  tvinit();        // trap vectors
80103e81:	e8 9d 3a 00 00       	call   80107923 <tvinit>
  binit();         // buffer cache
80103e86:	e8 a9 c1 ff ff       	call   80100034 <binit>
  fileinit();      // file table
80103e8b:	e8 70 d0 ff ff       	call   80100f00 <fileinit>
  iinit();         // inode cache
80103e90:	e8 1e d7 ff ff       	call   801015b3 <iinit>
  ideinit();       // disk
80103e95:	e8 92 e6 ff ff       	call   8010252c <ideinit>
  if(!ismp)
80103e9a:	a1 64 49 19 80       	mov    0x80194964,%eax
80103e9f:	85 c0                	test   %eax,%eax
80103ea1:	75 05                	jne    80103ea8 <main+0x95>
    timerinit();   // uniprocessor timer
80103ea3:	e8 be 39 00 00       	call   80107866 <timerinit>
  startothers();   // start other processors
80103ea8:	e8 87 00 00 00       	call   80103f34 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80103ead:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
80103eb4:	8e 
80103eb5:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
80103ebc:	e8 59 eb ff ff       	call   80102a1a <kinit2>
  userinit();      // first user process
80103ec1:	e8 0d 12 00 00       	call   801050d3 <userinit>
  // Finish setting up this processor in mpmain.
  mpmain();
80103ec6:	e8 22 00 00 00       	call   80103eed <mpmain>

80103ecb <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
80103ecb:	55                   	push   %ebp
80103ecc:	89 e5                	mov    %esp,%ebp
80103ece:	83 ec 18             	sub    $0x18,%esp
  switchkvm(); 
80103ed1:	e8 d3 51 00 00       	call   801090a9 <switchkvm>
  seginit();
80103ed6:	e8 5a 4b 00 00       	call   80108a35 <seginit>
  lapicinit(cpunum());
80103edb:	e8 b9 f9 ff ff       	call   80103899 <cpunum>
80103ee0:	89 04 24             	mov    %eax,(%esp)
80103ee3:	e8 54 f8 ff ff       	call   8010373c <lapicinit>
  mpmain();
80103ee8:	e8 00 00 00 00       	call   80103eed <mpmain>

80103eed <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
80103eed:	55                   	push   %ebp
80103eee:	89 e5                	mov    %esp,%ebp
80103ef0:	83 ec 18             	sub    $0x18,%esp
  cprintf("cpu%d: starting\n", cpu->id);
80103ef3:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103ef9:	0f b6 00             	movzbl (%eax),%eax
80103efc:	0f b6 c0             	movzbl %al,%eax
80103eff:	89 44 24 04          	mov    %eax,0x4(%esp)
80103f03:	c7 04 24 9c 9b 10 80 	movl   $0x80109b9c,(%esp)
80103f0a:	e8 92 c4 ff ff       	call   801003a1 <cprintf>
  idtinit();       // load idt register
80103f0f:	e8 83 3b 00 00       	call   80107a97 <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
80103f14:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103f1a:	05 a8 00 00 00       	add    $0xa8,%eax
80103f1f:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80103f26:	00 
80103f27:	89 04 24             	mov    %eax,(%esp)
80103f2a:	e8 bf fe ff ff       	call   80103dee <xchg>
  scheduler();     // start running processes
80103f2f:	e8 d0 17 00 00       	call   80105704 <scheduler>

80103f34 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80103f34:	55                   	push   %ebp
80103f35:	89 e5                	mov    %esp,%ebp
80103f37:	53                   	push   %ebx
80103f38:	83 ec 24             	sub    $0x24,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
80103f3b:	c7 04 24 00 70 00 00 	movl   $0x7000,(%esp)
80103f42:	e8 9a fe ff ff       	call   80103de1 <p2v>
80103f47:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80103f4a:	b8 8a 00 00 00       	mov    $0x8a,%eax
80103f4f:	89 44 24 08          	mov    %eax,0x8(%esp)
80103f53:	c7 44 24 04 2c d5 10 	movl   $0x8010d52c,0x4(%esp)
80103f5a:	80 
80103f5b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103f5e:	89 04 24             	mov    %eax,(%esp)
80103f61:	e8 e3 20 00 00       	call   80106049 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80103f66:	c7 45 f4 80 49 19 80 	movl   $0x80194980,-0xc(%ebp)
80103f6d:	e9 86 00 00 00       	jmp    80103ff8 <startothers+0xc4>
    if(c == cpus+cpunum())  // We've started already.
80103f72:	e8 22 f9 ff ff       	call   80103899 <cpunum>
80103f77:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103f7d:	05 80 49 19 80       	add    $0x80194980,%eax
80103f82:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103f85:	74 69                	je     80103ff0 <startothers+0xbc>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what 
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
80103f87:	e8 84 eb ff ff       	call   80102b10 <kalloc>
80103f8c:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
80103f8f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103f92:	83 e8 04             	sub    $0x4,%eax
80103f95:	8b 55 ec             	mov    -0x14(%ebp),%edx
80103f98:	81 c2 00 10 00 00    	add    $0x1000,%edx
80103f9e:	89 10                	mov    %edx,(%eax)
    *(void**)(code-8) = mpenter;
80103fa0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103fa3:	83 e8 08             	sub    $0x8,%eax
80103fa6:	c7 00 cb 3e 10 80    	movl   $0x80103ecb,(%eax)
    *(int**)(code-12) = (void *) v2p(entrypgdir);
80103fac:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103faf:	8d 58 f4             	lea    -0xc(%eax),%ebx
80103fb2:	c7 04 24 00 c0 10 80 	movl   $0x8010c000,(%esp)
80103fb9:	e8 16 fe ff ff       	call   80103dd4 <v2p>
80103fbe:	89 03                	mov    %eax,(%ebx)

    lapicstartap(c->id, v2p(code));
80103fc0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103fc3:	89 04 24             	mov    %eax,(%esp)
80103fc6:	e8 09 fe ff ff       	call   80103dd4 <v2p>
80103fcb:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103fce:	0f b6 12             	movzbl (%edx),%edx
80103fd1:	0f b6 d2             	movzbl %dl,%edx
80103fd4:	89 44 24 04          	mov    %eax,0x4(%esp)
80103fd8:	89 14 24             	mov    %edx,(%esp)
80103fdb:	e8 3f f9 ff ff       	call   8010391f <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80103fe0:	90                   	nop
80103fe1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103fe4:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
80103fea:	85 c0                	test   %eax,%eax
80103fec:	74 f3                	je     80103fe1 <startothers+0xad>
80103fee:	eb 01                	jmp    80103ff1 <startothers+0xbd>
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
    if(c == cpus+cpunum())  // We've started already.
      continue;
80103ff0:	90                   	nop
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
80103ff1:	81 45 f4 bc 00 00 00 	addl   $0xbc,-0xc(%ebp)
80103ff8:	a1 60 4f 19 80       	mov    0x80194f60,%eax
80103ffd:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80104003:	05 80 49 19 80       	add    $0x80194980,%eax
80104008:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010400b:	0f 87 61 ff ff ff    	ja     80103f72 <startothers+0x3e>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;
  }
}
80104011:	83 c4 24             	add    $0x24,%esp
80104014:	5b                   	pop    %ebx
80104015:	5d                   	pop    %ebp
80104016:	c3                   	ret    
	...

80104018 <p2v>:
80104018:	55                   	push   %ebp
80104019:	89 e5                	mov    %esp,%ebp
8010401b:	8b 45 08             	mov    0x8(%ebp),%eax
8010401e:	05 00 00 00 80       	add    $0x80000000,%eax
80104023:	5d                   	pop    %ebp
80104024:	c3                   	ret    

80104025 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80104025:	55                   	push   %ebp
80104026:	89 e5                	mov    %esp,%ebp
80104028:	53                   	push   %ebx
80104029:	83 ec 14             	sub    $0x14,%esp
8010402c:	8b 45 08             	mov    0x8(%ebp),%eax
8010402f:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80104033:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80104037:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
8010403b:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
8010403f:	ec                   	in     (%dx),%al
80104040:	89 c3                	mov    %eax,%ebx
80104042:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80104045:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80104049:	83 c4 14             	add    $0x14,%esp
8010404c:	5b                   	pop    %ebx
8010404d:	5d                   	pop    %ebp
8010404e:	c3                   	ret    

8010404f <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
8010404f:	55                   	push   %ebp
80104050:	89 e5                	mov    %esp,%ebp
80104052:	83 ec 08             	sub    $0x8,%esp
80104055:	8b 55 08             	mov    0x8(%ebp),%edx
80104058:	8b 45 0c             	mov    0xc(%ebp),%eax
8010405b:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
8010405f:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80104062:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80104066:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
8010406a:	ee                   	out    %al,(%dx)
}
8010406b:	c9                   	leave  
8010406c:	c3                   	ret    

8010406d <mpbcpu>:
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
8010406d:	55                   	push   %ebp
8010406e:	89 e5                	mov    %esp,%ebp
  return bcpu-cpus;
80104070:	a1 64 d6 10 80       	mov    0x8010d664,%eax
80104075:	89 c2                	mov    %eax,%edx
80104077:	b8 80 49 19 80       	mov    $0x80194980,%eax
8010407c:	89 d1                	mov    %edx,%ecx
8010407e:	29 c1                	sub    %eax,%ecx
80104080:	89 c8                	mov    %ecx,%eax
80104082:	c1 f8 02             	sar    $0x2,%eax
80104085:	69 c0 cf 46 7d 67    	imul   $0x677d46cf,%eax,%eax
}
8010408b:	5d                   	pop    %ebp
8010408c:	c3                   	ret    

8010408d <sum>:

static uchar
sum(uchar *addr, int len)
{
8010408d:	55                   	push   %ebp
8010408e:	89 e5                	mov    %esp,%ebp
80104090:	83 ec 10             	sub    $0x10,%esp
  int i, sum;
  
  sum = 0;
80104093:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
8010409a:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801040a1:	eb 13                	jmp    801040b6 <sum+0x29>
    sum += addr[i];
801040a3:	8b 45 fc             	mov    -0x4(%ebp),%eax
801040a6:	03 45 08             	add    0x8(%ebp),%eax
801040a9:	0f b6 00             	movzbl (%eax),%eax
801040ac:	0f b6 c0             	movzbl %al,%eax
801040af:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
801040b2:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801040b6:	8b 45 fc             	mov    -0x4(%ebp),%eax
801040b9:	3b 45 0c             	cmp    0xc(%ebp),%eax
801040bc:	7c e5                	jl     801040a3 <sum+0x16>
    sum += addr[i];
  return sum;
801040be:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
801040c1:	c9                   	leave  
801040c2:	c3                   	ret    

801040c3 <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
801040c3:	55                   	push   %ebp
801040c4:	89 e5                	mov    %esp,%ebp
801040c6:	83 ec 28             	sub    $0x28,%esp
  uchar *e, *p, *addr;

  addr = p2v(a);
801040c9:	8b 45 08             	mov    0x8(%ebp),%eax
801040cc:	89 04 24             	mov    %eax,(%esp)
801040cf:	e8 44 ff ff ff       	call   80104018 <p2v>
801040d4:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
801040d7:	8b 45 0c             	mov    0xc(%ebp),%eax
801040da:	03 45 f0             	add    -0x10(%ebp),%eax
801040dd:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
801040e0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801040e3:	89 45 f4             	mov    %eax,-0xc(%ebp)
801040e6:	eb 3f                	jmp    80104127 <mpsearch1+0x64>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
801040e8:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
801040ef:	00 
801040f0:	c7 44 24 04 b0 9b 10 	movl   $0x80109bb0,0x4(%esp)
801040f7:	80 
801040f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801040fb:	89 04 24             	mov    %eax,(%esp)
801040fe:	e8 ea 1e 00 00       	call   80105fed <memcmp>
80104103:	85 c0                	test   %eax,%eax
80104105:	75 1c                	jne    80104123 <mpsearch1+0x60>
80104107:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
8010410e:	00 
8010410f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104112:	89 04 24             	mov    %eax,(%esp)
80104115:	e8 73 ff ff ff       	call   8010408d <sum>
8010411a:	84 c0                	test   %al,%al
8010411c:	75 05                	jne    80104123 <mpsearch1+0x60>
      return (struct mp*)p;
8010411e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104121:	eb 11                	jmp    80104134 <mpsearch1+0x71>
{
  uchar *e, *p, *addr;

  addr = p2v(a);
  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
80104123:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80104127:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010412a:	3b 45 ec             	cmp    -0x14(%ebp),%eax
8010412d:	72 b9                	jb     801040e8 <mpsearch1+0x25>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
8010412f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104134:	c9                   	leave  
80104135:	c3                   	ret    

80104136 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80104136:	55                   	push   %ebp
80104137:	89 e5                	mov    %esp,%ebp
80104139:	83 ec 28             	sub    $0x28,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
8010413c:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80104143:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104146:	83 c0 0f             	add    $0xf,%eax
80104149:	0f b6 00             	movzbl (%eax),%eax
8010414c:	0f b6 c0             	movzbl %al,%eax
8010414f:	89 c2                	mov    %eax,%edx
80104151:	c1 e2 08             	shl    $0x8,%edx
80104154:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104157:	83 c0 0e             	add    $0xe,%eax
8010415a:	0f b6 00             	movzbl (%eax),%eax
8010415d:	0f b6 c0             	movzbl %al,%eax
80104160:	09 d0                	or     %edx,%eax
80104162:	c1 e0 04             	shl    $0x4,%eax
80104165:	89 45 f0             	mov    %eax,-0x10(%ebp)
80104168:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010416c:	74 21                	je     8010418f <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
8010416e:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80104175:	00 
80104176:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104179:	89 04 24             	mov    %eax,(%esp)
8010417c:	e8 42 ff ff ff       	call   801040c3 <mpsearch1>
80104181:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104184:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80104188:	74 50                	je     801041da <mpsearch+0xa4>
      return mp;
8010418a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010418d:	eb 5f                	jmp    801041ee <mpsearch+0xb8>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
8010418f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104192:	83 c0 14             	add    $0x14,%eax
80104195:	0f b6 00             	movzbl (%eax),%eax
80104198:	0f b6 c0             	movzbl %al,%eax
8010419b:	89 c2                	mov    %eax,%edx
8010419d:	c1 e2 08             	shl    $0x8,%edx
801041a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041a3:	83 c0 13             	add    $0x13,%eax
801041a6:	0f b6 00             	movzbl (%eax),%eax
801041a9:	0f b6 c0             	movzbl %al,%eax
801041ac:	09 d0                	or     %edx,%eax
801041ae:	c1 e0 0a             	shl    $0xa,%eax
801041b1:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
801041b4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801041b7:	2d 00 04 00 00       	sub    $0x400,%eax
801041bc:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
801041c3:	00 
801041c4:	89 04 24             	mov    %eax,(%esp)
801041c7:	e8 f7 fe ff ff       	call   801040c3 <mpsearch1>
801041cc:	89 45 ec             	mov    %eax,-0x14(%ebp)
801041cf:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801041d3:	74 05                	je     801041da <mpsearch+0xa4>
      return mp;
801041d5:	8b 45 ec             	mov    -0x14(%ebp),%eax
801041d8:	eb 14                	jmp    801041ee <mpsearch+0xb8>
  }
  return mpsearch1(0xF0000, 0x10000);
801041da:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
801041e1:	00 
801041e2:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
801041e9:	e8 d5 fe ff ff       	call   801040c3 <mpsearch1>
}
801041ee:	c9                   	leave  
801041ef:	c3                   	ret    

801041f0 <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
801041f0:	55                   	push   %ebp
801041f1:	89 e5                	mov    %esp,%ebp
801041f3:	83 ec 28             	sub    $0x28,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
801041f6:	e8 3b ff ff ff       	call   80104136 <mpsearch>
801041fb:	89 45 f4             	mov    %eax,-0xc(%ebp)
801041fe:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104202:	74 0a                	je     8010420e <mpconfig+0x1e>
80104204:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104207:	8b 40 04             	mov    0x4(%eax),%eax
8010420a:	85 c0                	test   %eax,%eax
8010420c:	75 0a                	jne    80104218 <mpconfig+0x28>
    return 0;
8010420e:	b8 00 00 00 00       	mov    $0x0,%eax
80104213:	e9 83 00 00 00       	jmp    8010429b <mpconfig+0xab>
  conf = (struct mpconf*) p2v((uint) mp->physaddr);
80104218:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010421b:	8b 40 04             	mov    0x4(%eax),%eax
8010421e:	89 04 24             	mov    %eax,(%esp)
80104221:	e8 f2 fd ff ff       	call   80104018 <p2v>
80104226:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
80104229:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80104230:	00 
80104231:	c7 44 24 04 b5 9b 10 	movl   $0x80109bb5,0x4(%esp)
80104238:	80 
80104239:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010423c:	89 04 24             	mov    %eax,(%esp)
8010423f:	e8 a9 1d 00 00       	call   80105fed <memcmp>
80104244:	85 c0                	test   %eax,%eax
80104246:	74 07                	je     8010424f <mpconfig+0x5f>
    return 0;
80104248:	b8 00 00 00 00       	mov    $0x0,%eax
8010424d:	eb 4c                	jmp    8010429b <mpconfig+0xab>
  if(conf->version != 1 && conf->version != 4)
8010424f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104252:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80104256:	3c 01                	cmp    $0x1,%al
80104258:	74 12                	je     8010426c <mpconfig+0x7c>
8010425a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010425d:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80104261:	3c 04                	cmp    $0x4,%al
80104263:	74 07                	je     8010426c <mpconfig+0x7c>
    return 0;
80104265:	b8 00 00 00 00       	mov    $0x0,%eax
8010426a:	eb 2f                	jmp    8010429b <mpconfig+0xab>
  if(sum((uchar*)conf, conf->length) != 0)
8010426c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010426f:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80104273:	0f b7 c0             	movzwl %ax,%eax
80104276:	89 44 24 04          	mov    %eax,0x4(%esp)
8010427a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010427d:	89 04 24             	mov    %eax,(%esp)
80104280:	e8 08 fe ff ff       	call   8010408d <sum>
80104285:	84 c0                	test   %al,%al
80104287:	74 07                	je     80104290 <mpconfig+0xa0>
    return 0;
80104289:	b8 00 00 00 00       	mov    $0x0,%eax
8010428e:	eb 0b                	jmp    8010429b <mpconfig+0xab>
  *pmp = mp;
80104290:	8b 45 08             	mov    0x8(%ebp),%eax
80104293:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104296:	89 10                	mov    %edx,(%eax)
  return conf;
80104298:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
8010429b:	c9                   	leave  
8010429c:	c3                   	ret    

8010429d <mpinit>:

void
mpinit(void)
{
8010429d:	55                   	push   %ebp
8010429e:	89 e5                	mov    %esp,%ebp
801042a0:	83 ec 38             	sub    $0x38,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
801042a3:	c7 05 64 d6 10 80 80 	movl   $0x80194980,0x8010d664
801042aa:	49 19 80 
  if((conf = mpconfig(&mp)) == 0)
801042ad:	8d 45 e0             	lea    -0x20(%ebp),%eax
801042b0:	89 04 24             	mov    %eax,(%esp)
801042b3:	e8 38 ff ff ff       	call   801041f0 <mpconfig>
801042b8:	89 45 f0             	mov    %eax,-0x10(%ebp)
801042bb:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801042bf:	0f 84 9c 01 00 00    	je     80104461 <mpinit+0x1c4>
    return;
  ismp = 1;
801042c5:	c7 05 64 49 19 80 01 	movl   $0x1,0x80194964
801042cc:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
801042cf:	8b 45 f0             	mov    -0x10(%ebp),%eax
801042d2:	8b 40 24             	mov    0x24(%eax),%eax
801042d5:	a3 d4 48 19 80       	mov    %eax,0x801948d4
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
801042da:	8b 45 f0             	mov    -0x10(%ebp),%eax
801042dd:	83 c0 2c             	add    $0x2c,%eax
801042e0:	89 45 f4             	mov    %eax,-0xc(%ebp)
801042e3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801042e6:	0f b7 40 04          	movzwl 0x4(%eax),%eax
801042ea:	0f b7 c0             	movzwl %ax,%eax
801042ed:	03 45 f0             	add    -0x10(%ebp),%eax
801042f0:	89 45 ec             	mov    %eax,-0x14(%ebp)
801042f3:	e9 f4 00 00 00       	jmp    801043ec <mpinit+0x14f>
    switch(*p){
801042f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042fb:	0f b6 00             	movzbl (%eax),%eax
801042fe:	0f b6 c0             	movzbl %al,%eax
80104301:	83 f8 04             	cmp    $0x4,%eax
80104304:	0f 87 bf 00 00 00    	ja     801043c9 <mpinit+0x12c>
8010430a:	8b 04 85 f8 9b 10 80 	mov    -0x7fef6408(,%eax,4),%eax
80104311:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
80104313:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104316:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(ncpu != proc->apicid){
80104319:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010431c:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80104320:	0f b6 d0             	movzbl %al,%edx
80104323:	a1 60 4f 19 80       	mov    0x80194f60,%eax
80104328:	39 c2                	cmp    %eax,%edx
8010432a:	74 2d                	je     80104359 <mpinit+0xbc>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
8010432c:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010432f:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80104333:	0f b6 d0             	movzbl %al,%edx
80104336:	a1 60 4f 19 80       	mov    0x80194f60,%eax
8010433b:	89 54 24 08          	mov    %edx,0x8(%esp)
8010433f:	89 44 24 04          	mov    %eax,0x4(%esp)
80104343:	c7 04 24 ba 9b 10 80 	movl   $0x80109bba,(%esp)
8010434a:	e8 52 c0 ff ff       	call   801003a1 <cprintf>
        ismp = 0;
8010434f:	c7 05 64 49 19 80 00 	movl   $0x0,0x80194964
80104356:	00 00 00 
      }
      if(proc->flags & MPBOOT)
80104359:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010435c:	0f b6 40 03          	movzbl 0x3(%eax),%eax
80104360:	0f b6 c0             	movzbl %al,%eax
80104363:	83 e0 02             	and    $0x2,%eax
80104366:	85 c0                	test   %eax,%eax
80104368:	74 15                	je     8010437f <mpinit+0xe2>
        bcpu = &cpus[ncpu];
8010436a:	a1 60 4f 19 80       	mov    0x80194f60,%eax
8010436f:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80104375:	05 80 49 19 80       	add    $0x80194980,%eax
8010437a:	a3 64 d6 10 80       	mov    %eax,0x8010d664
      cpus[ncpu].id = ncpu;
8010437f:	8b 15 60 4f 19 80    	mov    0x80194f60,%edx
80104385:	a1 60 4f 19 80       	mov    0x80194f60,%eax
8010438a:	69 d2 bc 00 00 00    	imul   $0xbc,%edx,%edx
80104390:	81 c2 80 49 19 80    	add    $0x80194980,%edx
80104396:	88 02                	mov    %al,(%edx)
      ncpu++;
80104398:	a1 60 4f 19 80       	mov    0x80194f60,%eax
8010439d:	83 c0 01             	add    $0x1,%eax
801043a0:	a3 60 4f 19 80       	mov    %eax,0x80194f60
      p += sizeof(struct mpproc);
801043a5:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
801043a9:	eb 41                	jmp    801043ec <mpinit+0x14f>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
801043ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043ae:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      ioapicid = ioapic->apicno;
801043b1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801043b4:	0f b6 40 01          	movzbl 0x1(%eax),%eax
801043b8:	a2 60 49 19 80       	mov    %al,0x80194960
      p += sizeof(struct mpioapic);
801043bd:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
801043c1:	eb 29                	jmp    801043ec <mpinit+0x14f>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
801043c3:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
801043c7:	eb 23                	jmp    801043ec <mpinit+0x14f>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
801043c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043cc:	0f b6 00             	movzbl (%eax),%eax
801043cf:	0f b6 c0             	movzbl %al,%eax
801043d2:	89 44 24 04          	mov    %eax,0x4(%esp)
801043d6:	c7 04 24 d8 9b 10 80 	movl   $0x80109bd8,(%esp)
801043dd:	e8 bf bf ff ff       	call   801003a1 <cprintf>
      ismp = 0;
801043e2:	c7 05 64 49 19 80 00 	movl   $0x0,0x80194964
801043e9:	00 00 00 
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
801043ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043ef:	3b 45 ec             	cmp    -0x14(%ebp),%eax
801043f2:	0f 82 00 ff ff ff    	jb     801042f8 <mpinit+0x5b>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
      ismp = 0;
    }
  }
  if(!ismp){
801043f8:	a1 64 49 19 80       	mov    0x80194964,%eax
801043fd:	85 c0                	test   %eax,%eax
801043ff:	75 1d                	jne    8010441e <mpinit+0x181>
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
80104401:	c7 05 60 4f 19 80 01 	movl   $0x1,0x80194f60
80104408:	00 00 00 
    lapic = 0;
8010440b:	c7 05 d4 48 19 80 00 	movl   $0x0,0x801948d4
80104412:	00 00 00 
    ioapicid = 0;
80104415:	c6 05 60 49 19 80 00 	movb   $0x0,0x80194960
    return;
8010441c:	eb 44                	jmp    80104462 <mpinit+0x1c5>
  }

  if(mp->imcrp){
8010441e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104421:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
80104425:	84 c0                	test   %al,%al
80104427:	74 39                	je     80104462 <mpinit+0x1c5>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
80104429:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
80104430:	00 
80104431:	c7 04 24 22 00 00 00 	movl   $0x22,(%esp)
80104438:	e8 12 fc ff ff       	call   8010404f <outb>
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
8010443d:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80104444:	e8 dc fb ff ff       	call   80104025 <inb>
80104449:	83 c8 01             	or     $0x1,%eax
8010444c:	0f b6 c0             	movzbl %al,%eax
8010444f:	89 44 24 04          	mov    %eax,0x4(%esp)
80104453:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
8010445a:	e8 f0 fb ff ff       	call   8010404f <outb>
8010445f:	eb 01                	jmp    80104462 <mpinit+0x1c5>
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
80104461:	90                   	nop
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
  }
}
80104462:	c9                   	leave  
80104463:	c3                   	ret    

80104464 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80104464:	55                   	push   %ebp
80104465:	89 e5                	mov    %esp,%ebp
80104467:	83 ec 08             	sub    $0x8,%esp
8010446a:	8b 55 08             	mov    0x8(%ebp),%edx
8010446d:	8b 45 0c             	mov    0xc(%ebp),%eax
80104470:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80104474:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80104477:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
8010447b:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
8010447f:	ee                   	out    %al,(%dx)
}
80104480:	c9                   	leave  
80104481:	c3                   	ret    

80104482 <picsetmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static ushort irqmask = 0xFFFF & ~(1<<IRQ_SLAVE);

static void
picsetmask(ushort mask)
{
80104482:	55                   	push   %ebp
80104483:	89 e5                	mov    %esp,%ebp
80104485:	83 ec 0c             	sub    $0xc,%esp
80104488:	8b 45 08             	mov    0x8(%ebp),%eax
8010448b:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  irqmask = mask;
8010448f:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80104493:	66 a3 00 d0 10 80    	mov    %ax,0x8010d000
  outb(IO_PIC1+1, mask);
80104499:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
8010449d:	0f b6 c0             	movzbl %al,%eax
801044a0:	89 44 24 04          	mov    %eax,0x4(%esp)
801044a4:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
801044ab:	e8 b4 ff ff ff       	call   80104464 <outb>
  outb(IO_PIC2+1, mask >> 8);
801044b0:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
801044b4:	66 c1 e8 08          	shr    $0x8,%ax
801044b8:	0f b6 c0             	movzbl %al,%eax
801044bb:	89 44 24 04          	mov    %eax,0x4(%esp)
801044bf:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
801044c6:	e8 99 ff ff ff       	call   80104464 <outb>
}
801044cb:	c9                   	leave  
801044cc:	c3                   	ret    

801044cd <picenable>:

void
picenable(int irq)
{
801044cd:	55                   	push   %ebp
801044ce:	89 e5                	mov    %esp,%ebp
801044d0:	53                   	push   %ebx
801044d1:	83 ec 04             	sub    $0x4,%esp
  picsetmask(irqmask & ~(1<<irq));
801044d4:	8b 45 08             	mov    0x8(%ebp),%eax
801044d7:	ba 01 00 00 00       	mov    $0x1,%edx
801044dc:	89 d3                	mov    %edx,%ebx
801044de:	89 c1                	mov    %eax,%ecx
801044e0:	d3 e3                	shl    %cl,%ebx
801044e2:	89 d8                	mov    %ebx,%eax
801044e4:	89 c2                	mov    %eax,%edx
801044e6:	f7 d2                	not    %edx
801044e8:	0f b7 05 00 d0 10 80 	movzwl 0x8010d000,%eax
801044ef:	21 d0                	and    %edx,%eax
801044f1:	0f b7 c0             	movzwl %ax,%eax
801044f4:	89 04 24             	mov    %eax,(%esp)
801044f7:	e8 86 ff ff ff       	call   80104482 <picsetmask>
}
801044fc:	83 c4 04             	add    $0x4,%esp
801044ff:	5b                   	pop    %ebx
80104500:	5d                   	pop    %ebp
80104501:	c3                   	ret    

80104502 <picinit>:

// Initialize the 8259A interrupt controllers.
void
picinit(void)
{
80104502:	55                   	push   %ebp
80104503:	89 e5                	mov    %esp,%ebp
80104505:	83 ec 08             	sub    $0x8,%esp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
80104508:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
8010450f:	00 
80104510:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104517:	e8 48 ff ff ff       	call   80104464 <outb>
  outb(IO_PIC2+1, 0xFF);
8010451c:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80104523:	00 
80104524:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
8010452b:	e8 34 ff ff ff       	call   80104464 <outb>

  // ICW1:  0001g0hi
  //    g:  0 = edge triggering, 1 = level triggering
  //    h:  0 = cascaded PICs, 1 = master only
  //    i:  0 = no ICW4, 1 = ICW4 required
  outb(IO_PIC1, 0x11);
80104530:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80104537:	00 
80104538:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010453f:	e8 20 ff ff ff       	call   80104464 <outb>

  // ICW2:  Vector offset
  outb(IO_PIC1+1, T_IRQ0);
80104544:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
8010454b:	00 
8010454c:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104553:	e8 0c ff ff ff       	call   80104464 <outb>

  // ICW3:  (master PIC) bit mask of IR lines connected to slaves
  //        (slave PIC) 3-bit # of slave's connection to master
  outb(IO_PIC1+1, 1<<IRQ_SLAVE);
80104558:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
8010455f:	00 
80104560:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104567:	e8 f8 fe ff ff       	call   80104464 <outb>
  //    m:  0 = slave PIC, 1 = master PIC
  //      (ignored when b is 0, as the master/slave role
  //      can be hardwired).
  //    a:  1 = Automatic EOI mode
  //    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
  outb(IO_PIC1+1, 0x3);
8010456c:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80104573:	00 
80104574:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
8010457b:	e8 e4 fe ff ff       	call   80104464 <outb>

  // Set up slave (8259A-2)
  outb(IO_PIC2, 0x11);                  // ICW1
80104580:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80104587:	00 
80104588:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
8010458f:	e8 d0 fe ff ff       	call   80104464 <outb>
  outb(IO_PIC2+1, T_IRQ0 + 8);      // ICW2
80104594:	c7 44 24 04 28 00 00 	movl   $0x28,0x4(%esp)
8010459b:	00 
8010459c:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
801045a3:	e8 bc fe ff ff       	call   80104464 <outb>
  outb(IO_PIC2+1, IRQ_SLAVE);           // ICW3
801045a8:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
801045af:	00 
801045b0:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
801045b7:	e8 a8 fe ff ff       	call   80104464 <outb>
  // NB Automatic EOI mode doesn't tend to work on the slave.
  // Linux source code says it's "to be investigated".
  outb(IO_PIC2+1, 0x3);                 // ICW4
801045bc:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
801045c3:	00 
801045c4:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
801045cb:	e8 94 fe ff ff       	call   80104464 <outb>

  // OCW3:  0ef01prs
  //   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
  //    p:  0 = no polling, 1 = polling mode
  //   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
  outb(IO_PIC1, 0x68);             // clear specific mask
801045d0:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
801045d7:	00 
801045d8:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
801045df:	e8 80 fe ff ff       	call   80104464 <outb>
  outb(IO_PIC1, 0x0a);             // read IRR by default
801045e4:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
801045eb:	00 
801045ec:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
801045f3:	e8 6c fe ff ff       	call   80104464 <outb>

  outb(IO_PIC2, 0x68);             // OCW3
801045f8:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
801045ff:	00 
80104600:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104607:	e8 58 fe ff ff       	call   80104464 <outb>
  outb(IO_PIC2, 0x0a);             // OCW3
8010460c:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80104613:	00 
80104614:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
8010461b:	e8 44 fe ff ff       	call   80104464 <outb>

  if(irqmask != 0xFFFF)
80104620:	0f b7 05 00 d0 10 80 	movzwl 0x8010d000,%eax
80104627:	66 83 f8 ff          	cmp    $0xffff,%ax
8010462b:	74 12                	je     8010463f <picinit+0x13d>
    picsetmask(irqmask);
8010462d:	0f b7 05 00 d0 10 80 	movzwl 0x8010d000,%eax
80104634:	0f b7 c0             	movzwl %ax,%eax
80104637:	89 04 24             	mov    %eax,(%esp)
8010463a:	e8 43 fe ff ff       	call   80104482 <picsetmask>
}
8010463f:	c9                   	leave  
80104640:	c3                   	ret    
80104641:	00 00                	add    %al,(%eax)
	...

80104644 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80104644:	55                   	push   %ebp
80104645:	89 e5                	mov    %esp,%ebp
80104647:	83 ec 28             	sub    $0x28,%esp
  struct pipe *p;

  p = 0;
8010464a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
80104651:	8b 45 0c             	mov    0xc(%ebp),%eax
80104654:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
8010465a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010465d:	8b 10                	mov    (%eax),%edx
8010465f:	8b 45 08             	mov    0x8(%ebp),%eax
80104662:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80104664:	e8 b3 c8 ff ff       	call   80100f1c <filealloc>
80104669:	8b 55 08             	mov    0x8(%ebp),%edx
8010466c:	89 02                	mov    %eax,(%edx)
8010466e:	8b 45 08             	mov    0x8(%ebp),%eax
80104671:	8b 00                	mov    (%eax),%eax
80104673:	85 c0                	test   %eax,%eax
80104675:	0f 84 c8 00 00 00    	je     80104743 <pipealloc+0xff>
8010467b:	e8 9c c8 ff ff       	call   80100f1c <filealloc>
80104680:	8b 55 0c             	mov    0xc(%ebp),%edx
80104683:	89 02                	mov    %eax,(%edx)
80104685:	8b 45 0c             	mov    0xc(%ebp),%eax
80104688:	8b 00                	mov    (%eax),%eax
8010468a:	85 c0                	test   %eax,%eax
8010468c:	0f 84 b1 00 00 00    	je     80104743 <pipealloc+0xff>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
80104692:	e8 79 e4 ff ff       	call   80102b10 <kalloc>
80104697:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010469a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010469e:	0f 84 9e 00 00 00    	je     80104742 <pipealloc+0xfe>
    goto bad;
  p->readopen = 1;
801046a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046a7:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
801046ae:	00 00 00 
  p->writeopen = 1;
801046b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046b4:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
801046bb:	00 00 00 
  p->nwrite = 0;
801046be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046c1:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
801046c8:	00 00 00 
  p->nread = 0;
801046cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046ce:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
801046d5:	00 00 00 
  initlock(&p->lock, "pipe");
801046d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046db:	c7 44 24 04 0c 9c 10 	movl   $0x80109c0c,0x4(%esp)
801046e2:	80 
801046e3:	89 04 24             	mov    %eax,(%esp)
801046e6:	e8 e3 15 00 00       	call   80105cce <initlock>
  (*f0)->type = FD_PIPE;
801046eb:	8b 45 08             	mov    0x8(%ebp),%eax
801046ee:	8b 00                	mov    (%eax),%eax
801046f0:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
801046f6:	8b 45 08             	mov    0x8(%ebp),%eax
801046f9:	8b 00                	mov    (%eax),%eax
801046fb:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
801046ff:	8b 45 08             	mov    0x8(%ebp),%eax
80104702:	8b 00                	mov    (%eax),%eax
80104704:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80104708:	8b 45 08             	mov    0x8(%ebp),%eax
8010470b:	8b 00                	mov    (%eax),%eax
8010470d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104710:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
80104713:	8b 45 0c             	mov    0xc(%ebp),%eax
80104716:	8b 00                	mov    (%eax),%eax
80104718:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
8010471e:	8b 45 0c             	mov    0xc(%ebp),%eax
80104721:	8b 00                	mov    (%eax),%eax
80104723:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80104727:	8b 45 0c             	mov    0xc(%ebp),%eax
8010472a:	8b 00                	mov    (%eax),%eax
8010472c:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80104730:	8b 45 0c             	mov    0xc(%ebp),%eax
80104733:	8b 00                	mov    (%eax),%eax
80104735:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104738:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
8010473b:	b8 00 00 00 00       	mov    $0x0,%eax
80104740:	eb 43                	jmp    80104785 <pipealloc+0x141>
  p = 0;
  *f0 = *f1 = 0;
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
    goto bad;
80104742:	90                   	nop
  (*f1)->pipe = p;
  return 0;

//PAGEBREAK: 20
 bad:
  if(p)
80104743:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104747:	74 0b                	je     80104754 <pipealloc+0x110>
    kfree((char*)p);
80104749:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010474c:	89 04 24             	mov    %eax,(%esp)
8010474f:	e8 23 e3 ff ff       	call   80102a77 <kfree>
  if(*f0)
80104754:	8b 45 08             	mov    0x8(%ebp),%eax
80104757:	8b 00                	mov    (%eax),%eax
80104759:	85 c0                	test   %eax,%eax
8010475b:	74 0d                	je     8010476a <pipealloc+0x126>
    fileclose(*f0);
8010475d:	8b 45 08             	mov    0x8(%ebp),%eax
80104760:	8b 00                	mov    (%eax),%eax
80104762:	89 04 24             	mov    %eax,(%esp)
80104765:	e8 5a c8 ff ff       	call   80100fc4 <fileclose>
  if(*f1)
8010476a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010476d:	8b 00                	mov    (%eax),%eax
8010476f:	85 c0                	test   %eax,%eax
80104771:	74 0d                	je     80104780 <pipealloc+0x13c>
    fileclose(*f1);
80104773:	8b 45 0c             	mov    0xc(%ebp),%eax
80104776:	8b 00                	mov    (%eax),%eax
80104778:	89 04 24             	mov    %eax,(%esp)
8010477b:	e8 44 c8 ff ff       	call   80100fc4 <fileclose>
  return -1;
80104780:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104785:	c9                   	leave  
80104786:	c3                   	ret    

80104787 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80104787:	55                   	push   %ebp
80104788:	89 e5                	mov    %esp,%ebp
8010478a:	83 ec 18             	sub    $0x18,%esp
  acquire(&p->lock);
8010478d:	8b 45 08             	mov    0x8(%ebp),%eax
80104790:	89 04 24             	mov    %eax,(%esp)
80104793:	e8 57 15 00 00       	call   80105cef <acquire>
  if(writable){
80104798:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
8010479c:	74 1f                	je     801047bd <pipeclose+0x36>
    p->writeopen = 0;
8010479e:	8b 45 08             	mov    0x8(%ebp),%eax
801047a1:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
801047a8:	00 00 00 
    wakeup(&p->nread);
801047ab:	8b 45 08             	mov    0x8(%ebp),%eax
801047ae:	05 34 02 00 00       	add    $0x234,%eax
801047b3:	89 04 24             	mov    %eax,(%esp)
801047b6:	e8 31 12 00 00       	call   801059ec <wakeup>
801047bb:	eb 1d                	jmp    801047da <pipeclose+0x53>
  } else {
    p->readopen = 0;
801047bd:	8b 45 08             	mov    0x8(%ebp),%eax
801047c0:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
801047c7:	00 00 00 
    wakeup(&p->nwrite);
801047ca:	8b 45 08             	mov    0x8(%ebp),%eax
801047cd:	05 38 02 00 00       	add    $0x238,%eax
801047d2:	89 04 24             	mov    %eax,(%esp)
801047d5:	e8 12 12 00 00       	call   801059ec <wakeup>
  }
  if(p->readopen == 0 && p->writeopen == 0){
801047da:	8b 45 08             	mov    0x8(%ebp),%eax
801047dd:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
801047e3:	85 c0                	test   %eax,%eax
801047e5:	75 25                	jne    8010480c <pipeclose+0x85>
801047e7:	8b 45 08             	mov    0x8(%ebp),%eax
801047ea:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
801047f0:	85 c0                	test   %eax,%eax
801047f2:	75 18                	jne    8010480c <pipeclose+0x85>
    release(&p->lock);
801047f4:	8b 45 08             	mov    0x8(%ebp),%eax
801047f7:	89 04 24             	mov    %eax,(%esp)
801047fa:	e8 8b 15 00 00       	call   80105d8a <release>
    kfree((char*)p);
801047ff:	8b 45 08             	mov    0x8(%ebp),%eax
80104802:	89 04 24             	mov    %eax,(%esp)
80104805:	e8 6d e2 ff ff       	call   80102a77 <kfree>
8010480a:	eb 0b                	jmp    80104817 <pipeclose+0x90>
  } else
    release(&p->lock);
8010480c:	8b 45 08             	mov    0x8(%ebp),%eax
8010480f:	89 04 24             	mov    %eax,(%esp)
80104812:	e8 73 15 00 00       	call   80105d8a <release>
}
80104817:	c9                   	leave  
80104818:	c3                   	ret    

80104819 <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
80104819:	55                   	push   %ebp
8010481a:	89 e5                	mov    %esp,%ebp
8010481c:	53                   	push   %ebx
8010481d:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80104820:	8b 45 08             	mov    0x8(%ebp),%eax
80104823:	89 04 24             	mov    %eax,(%esp)
80104826:	e8 c4 14 00 00       	call   80105cef <acquire>
  for(i = 0; i < n; i++){
8010482b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104832:	e9 a6 00 00 00       	jmp    801048dd <pipewrite+0xc4>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
      if(p->readopen == 0 || proc->killed){
80104837:	8b 45 08             	mov    0x8(%ebp),%eax
8010483a:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80104840:	85 c0                	test   %eax,%eax
80104842:	74 0d                	je     80104851 <pipewrite+0x38>
80104844:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010484a:	8b 40 24             	mov    0x24(%eax),%eax
8010484d:	85 c0                	test   %eax,%eax
8010484f:	74 15                	je     80104866 <pipewrite+0x4d>
        release(&p->lock);
80104851:	8b 45 08             	mov    0x8(%ebp),%eax
80104854:	89 04 24             	mov    %eax,(%esp)
80104857:	e8 2e 15 00 00       	call   80105d8a <release>
        return -1;
8010485c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104861:	e9 9d 00 00 00       	jmp    80104903 <pipewrite+0xea>
      }
      wakeup(&p->nread);
80104866:	8b 45 08             	mov    0x8(%ebp),%eax
80104869:	05 34 02 00 00       	add    $0x234,%eax
8010486e:	89 04 24             	mov    %eax,(%esp)
80104871:	e8 76 11 00 00       	call   801059ec <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
80104876:	8b 45 08             	mov    0x8(%ebp),%eax
80104879:	8b 55 08             	mov    0x8(%ebp),%edx
8010487c:	81 c2 38 02 00 00    	add    $0x238,%edx
80104882:	89 44 24 04          	mov    %eax,0x4(%esp)
80104886:	89 14 24             	mov    %edx,(%esp)
80104889:	e8 22 10 00 00       	call   801058b0 <sleep>
8010488e:	eb 01                	jmp    80104891 <pipewrite+0x78>
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80104890:	90                   	nop
80104891:	8b 45 08             	mov    0x8(%ebp),%eax
80104894:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
8010489a:	8b 45 08             	mov    0x8(%ebp),%eax
8010489d:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
801048a3:	05 00 02 00 00       	add    $0x200,%eax
801048a8:	39 c2                	cmp    %eax,%edx
801048aa:	74 8b                	je     80104837 <pipewrite+0x1e>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
801048ac:	8b 45 08             	mov    0x8(%ebp),%eax
801048af:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
801048b5:	89 c3                	mov    %eax,%ebx
801048b7:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
801048bd:	8b 55 f4             	mov    -0xc(%ebp),%edx
801048c0:	03 55 0c             	add    0xc(%ebp),%edx
801048c3:	0f b6 0a             	movzbl (%edx),%ecx
801048c6:	8b 55 08             	mov    0x8(%ebp),%edx
801048c9:	88 4c 1a 34          	mov    %cl,0x34(%edx,%ebx,1)
801048cd:	8d 50 01             	lea    0x1(%eax),%edx
801048d0:	8b 45 08             	mov    0x8(%ebp),%eax
801048d3:	89 90 38 02 00 00    	mov    %edx,0x238(%eax)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
801048d9:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801048dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048e0:	3b 45 10             	cmp    0x10(%ebp),%eax
801048e3:	7c ab                	jl     80104890 <pipewrite+0x77>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
801048e5:	8b 45 08             	mov    0x8(%ebp),%eax
801048e8:	05 34 02 00 00       	add    $0x234,%eax
801048ed:	89 04 24             	mov    %eax,(%esp)
801048f0:	e8 f7 10 00 00       	call   801059ec <wakeup>
  release(&p->lock);
801048f5:	8b 45 08             	mov    0x8(%ebp),%eax
801048f8:	89 04 24             	mov    %eax,(%esp)
801048fb:	e8 8a 14 00 00       	call   80105d8a <release>
  return n;
80104900:	8b 45 10             	mov    0x10(%ebp),%eax
}
80104903:	83 c4 24             	add    $0x24,%esp
80104906:	5b                   	pop    %ebx
80104907:	5d                   	pop    %ebp
80104908:	c3                   	ret    

80104909 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
80104909:	55                   	push   %ebp
8010490a:	89 e5                	mov    %esp,%ebp
8010490c:	53                   	push   %ebx
8010490d:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80104910:	8b 45 08             	mov    0x8(%ebp),%eax
80104913:	89 04 24             	mov    %eax,(%esp)
80104916:	e8 d4 13 00 00       	call   80105cef <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
8010491b:	eb 3a                	jmp    80104957 <piperead+0x4e>
    if(proc->killed){
8010491d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104923:	8b 40 24             	mov    0x24(%eax),%eax
80104926:	85 c0                	test   %eax,%eax
80104928:	74 15                	je     8010493f <piperead+0x36>
      release(&p->lock);
8010492a:	8b 45 08             	mov    0x8(%ebp),%eax
8010492d:	89 04 24             	mov    %eax,(%esp)
80104930:	e8 55 14 00 00       	call   80105d8a <release>
      return -1;
80104935:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010493a:	e9 b6 00 00 00       	jmp    801049f5 <piperead+0xec>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
8010493f:	8b 45 08             	mov    0x8(%ebp),%eax
80104942:	8b 55 08             	mov    0x8(%ebp),%edx
80104945:	81 c2 34 02 00 00    	add    $0x234,%edx
8010494b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010494f:	89 14 24             	mov    %edx,(%esp)
80104952:	e8 59 0f 00 00       	call   801058b0 <sleep>
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80104957:	8b 45 08             	mov    0x8(%ebp),%eax
8010495a:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80104960:	8b 45 08             	mov    0x8(%ebp),%eax
80104963:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104969:	39 c2                	cmp    %eax,%edx
8010496b:	75 0d                	jne    8010497a <piperead+0x71>
8010496d:	8b 45 08             	mov    0x8(%ebp),%eax
80104970:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80104976:	85 c0                	test   %eax,%eax
80104978:	75 a3                	jne    8010491d <piperead+0x14>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
8010497a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104981:	eb 49                	jmp    801049cc <piperead+0xc3>
    if(p->nread == p->nwrite)
80104983:	8b 45 08             	mov    0x8(%ebp),%eax
80104986:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
8010498c:	8b 45 08             	mov    0x8(%ebp),%eax
8010498f:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104995:	39 c2                	cmp    %eax,%edx
80104997:	74 3d                	je     801049d6 <piperead+0xcd>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
80104999:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010499c:	89 c2                	mov    %eax,%edx
8010499e:	03 55 0c             	add    0xc(%ebp),%edx
801049a1:	8b 45 08             	mov    0x8(%ebp),%eax
801049a4:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
801049aa:	89 c3                	mov    %eax,%ebx
801049ac:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
801049b2:	8b 4d 08             	mov    0x8(%ebp),%ecx
801049b5:	0f b6 4c 19 34       	movzbl 0x34(%ecx,%ebx,1),%ecx
801049ba:	88 0a                	mov    %cl,(%edx)
801049bc:	8d 50 01             	lea    0x1(%eax),%edx
801049bf:	8b 45 08             	mov    0x8(%ebp),%eax
801049c2:	89 90 34 02 00 00    	mov    %edx,0x234(%eax)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801049c8:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801049cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049cf:	3b 45 10             	cmp    0x10(%ebp),%eax
801049d2:	7c af                	jl     80104983 <piperead+0x7a>
801049d4:	eb 01                	jmp    801049d7 <piperead+0xce>
    if(p->nread == p->nwrite)
      break;
801049d6:	90                   	nop
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
801049d7:	8b 45 08             	mov    0x8(%ebp),%eax
801049da:	05 38 02 00 00       	add    $0x238,%eax
801049df:	89 04 24             	mov    %eax,(%esp)
801049e2:	e8 05 10 00 00       	call   801059ec <wakeup>
  release(&p->lock);
801049e7:	8b 45 08             	mov    0x8(%ebp),%eax
801049ea:	89 04 24             	mov    %eax,(%esp)
801049ed:	e8 98 13 00 00       	call   80105d8a <release>
  return i;
801049f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801049f5:	83 c4 24             	add    $0x24,%esp
801049f8:	5b                   	pop    %ebx
801049f9:	5d                   	pop    %ebp
801049fa:	c3                   	ret    
	...

801049fc <p2v>:
801049fc:	55                   	push   %ebp
801049fd:	89 e5                	mov    %esp,%ebp
801049ff:	8b 45 08             	mov    0x8(%ebp),%eax
80104a02:	05 00 00 00 80       	add    $0x80000000,%eax
80104a07:	5d                   	pop    %ebp
80104a08:	c3                   	ret    

80104a09 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80104a09:	55                   	push   %ebp
80104a0a:	89 e5                	mov    %esp,%ebp
80104a0c:	53                   	push   %ebx
80104a0d:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80104a10:	9c                   	pushf  
80104a11:	5b                   	pop    %ebx
80104a12:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80104a15:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80104a18:	83 c4 10             	add    $0x10,%esp
80104a1b:	5b                   	pop    %ebx
80104a1c:	5d                   	pop    %ebp
80104a1d:	c3                   	ret    

80104a1e <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
80104a1e:	55                   	push   %ebp
80104a1f:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80104a21:	fb                   	sti    
}
80104a22:	5d                   	pop    %ebp
80104a23:	c3                   	ret    

80104a24 <pinit>:

static void wakeup1(void *chan);

void
pinit(void)
{
80104a24:	55                   	push   %ebp
80104a25:	89 e5                	mov    %esp,%ebp
80104a27:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
80104a2a:	c7 44 24 04 11 9c 10 	movl   $0x80109c11,0x4(%esp)
80104a31:	80 
80104a32:	c7 04 24 80 4f 19 80 	movl   $0x80194f80,(%esp)
80104a39:	e8 90 12 00 00       	call   80105cce <initlock>
}
80104a3e:	c9                   	leave  
80104a3f:	c3                   	ret    

80104a40 <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
80104a40:	55                   	push   %ebp
80104a41:	89 e5                	mov    %esp,%ebp
80104a43:	83 ec 38             	sub    $0x38,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
80104a46:	c7 04 24 80 4f 19 80 	movl   $0x80194f80,(%esp)
80104a4d:	e8 9d 12 00 00       	call   80105cef <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104a52:	c7 45 f4 b4 4f 19 80 	movl   $0x80194fb4,-0xc(%ebp)
80104a59:	eb 11                	jmp    80104a6c <allocproc+0x2c>
    if(p->state == UNUSED)
80104a5b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a5e:	8b 40 0c             	mov    0xc(%eax),%eax
80104a61:	85 c0                	test   %eax,%eax
80104a63:	74 26                	je     80104a8b <allocproc+0x4b>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104a65:	81 45 f4 90 00 00 00 	addl   $0x90,-0xc(%ebp)
80104a6c:	81 7d f4 b4 73 19 80 	cmpl   $0x801973b4,-0xc(%ebp)
80104a73:	72 e6                	jb     80104a5b <allocproc+0x1b>
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
80104a75:	c7 04 24 80 4f 19 80 	movl   $0x80194f80,(%esp)
80104a7c:	e8 09 13 00 00       	call   80105d8a <release>
  return 0;
80104a81:	b8 00 00 00 00       	mov    $0x0,%eax
80104a86:	e9 5a 01 00 00       	jmp    80104be5 <allocproc+0x1a5>
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
    if(p->state == UNUSED)
      goto found;
80104a8b:	90                   	nop
  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
80104a8c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a8f:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
  p->pid = nextpid++;
80104a96:	a1 04 d0 10 80       	mov    0x8010d004,%eax
80104a9b:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104a9e:	89 42 10             	mov    %eax,0x10(%edx)
80104aa1:	83 c0 01             	add    $0x1,%eax
80104aa4:	a3 04 d0 10 80       	mov    %eax,0x8010d004
  release(&ptable.lock);
80104aa9:	c7 04 24 80 4f 19 80 	movl   $0x80194f80,(%esp)
80104ab0:	e8 d5 12 00 00       	call   80105d8a <release>

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
80104ab5:	e8 56 e0 ff ff       	call   80102b10 <kalloc>
80104aba:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104abd:	89 42 08             	mov    %eax,0x8(%edx)
80104ac0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ac3:	8b 40 08             	mov    0x8(%eax),%eax
80104ac6:	85 c0                	test   %eax,%eax
80104ac8:	75 14                	jne    80104ade <allocproc+0x9e>
    p->state = UNUSED;
80104aca:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104acd:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return 0;
80104ad4:	b8 00 00 00 00       	mov    $0x0,%eax
80104ad9:	e9 07 01 00 00       	jmp    80104be5 <allocproc+0x1a5>
  }
  sp = p->kstack + KSTACKSIZE;
80104ade:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ae1:	8b 40 08             	mov    0x8(%eax),%eax
80104ae4:	05 00 10 00 00       	add    $0x1000,%eax
80104ae9:	89 45 f0             	mov    %eax,-0x10(%ebp)
  
  // Leave room for trap frame.
  sp -= sizeof *p->tf;
80104aec:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
  p->tf = (struct trapframe*)sp;
80104af0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104af3:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104af6:	89 50 18             	mov    %edx,0x18(%eax)
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
80104af9:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
  *(uint*)sp = (uint)trapret;
80104afd:	ba d8 78 10 80       	mov    $0x801078d8,%edx
80104b02:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b05:	89 10                	mov    %edx,(%eax)

  sp -= sizeof *p->context;
80104b07:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
  p->context = (struct context*)sp;
80104b0b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b0e:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104b11:	89 50 1c             	mov    %edx,0x1c(%eax)
  memset(p->context, 0, sizeof *p->context);
80104b14:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b17:	8b 40 1c             	mov    0x1c(%eax),%eax
80104b1a:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80104b21:	00 
80104b22:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104b29:	00 
80104b2a:	89 04 24             	mov    %eax,(%esp)
80104b2d:	e8 44 14 00 00       	call   80105f76 <memset>
  p->context->eip = (uint)forkret;
80104b32:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b35:	8b 40 1c             	mov    0x1c(%eax),%eax
80104b38:	ba 84 58 10 80       	mov    $0x80105884,%edx
80104b3d:	89 50 10             	mov    %edx,0x10(%eax)
  int i = 0;
80104b40:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  char name[8];
  name[2] = '.'; name[3] = 's'; name[4] = 'w'; name[5] = 'a'; name[6] = 'p'; name[7] = 0;
80104b47:	c6 45 e6 2e          	movb   $0x2e,-0x1a(%ebp)
80104b4b:	c6 45 e7 73          	movb   $0x73,-0x19(%ebp)
80104b4f:	c6 45 e8 77          	movb   $0x77,-0x18(%ebp)
80104b53:	c6 45 e9 61          	movb   $0x61,-0x17(%ebp)
80104b57:	c6 45 ea 70          	movb   $0x70,-0x16(%ebp)
80104b5b:	c6 45 eb 00          	movb   $0x0,-0x15(%ebp)
  name[1] = (char)(((int)'0')+p->pid % 10);
80104b5f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b62:	8b 48 10             	mov    0x10(%eax),%ecx
80104b65:	ba 67 66 66 66       	mov    $0x66666667,%edx
80104b6a:	89 c8                	mov    %ecx,%eax
80104b6c:	f7 ea                	imul   %edx
80104b6e:	c1 fa 02             	sar    $0x2,%edx
80104b71:	89 c8                	mov    %ecx,%eax
80104b73:	c1 f8 1f             	sar    $0x1f,%eax
80104b76:	29 c2                	sub    %eax,%edx
80104b78:	89 d0                	mov    %edx,%eax
80104b7a:	c1 e0 02             	shl    $0x2,%eax
80104b7d:	01 d0                	add    %edx,%eax
80104b7f:	01 c0                	add    %eax,%eax
80104b81:	89 ca                	mov    %ecx,%edx
80104b83:	29 c2                	sub    %eax,%edx
80104b85:	89 d0                	mov    %edx,%eax
80104b87:	83 c0 30             	add    $0x30,%eax
80104b8a:	88 45 e5             	mov    %al,-0x1b(%ebp)
  if((i=p->pid/10) == 0)
80104b8d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b90:	8b 48 10             	mov    0x10(%eax),%ecx
80104b93:	ba 67 66 66 66       	mov    $0x66666667,%edx
80104b98:	89 c8                	mov    %ecx,%eax
80104b9a:	f7 ea                	imul   %edx
80104b9c:	c1 fa 02             	sar    $0x2,%edx
80104b9f:	89 c8                	mov    %ecx,%eax
80104ba1:	c1 f8 1f             	sar    $0x1f,%eax
80104ba4:	89 d1                	mov    %edx,%ecx
80104ba6:	29 c1                	sub    %eax,%ecx
80104ba8:	89 c8                	mov    %ecx,%eax
80104baa:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104bad:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80104bb1:	75 06                	jne    80104bb9 <allocproc+0x179>
    name[0] = '0';
80104bb3:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
80104bb7:	eb 09                	jmp    80104bc2 <allocproc+0x182>
  else
    name[0] = (char)(((int)'0')+i);
80104bb9:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104bbc:	83 c0 30             	add    $0x30,%eax
80104bbf:	88 45 e4             	mov    %al,-0x1c(%ebp)
  //release(&ptable.lock);
  safestrcpy(p->swapFileName, name, sizeof(name));
80104bc2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104bc5:	8d 90 80 00 00 00    	lea    0x80(%eax),%edx
80104bcb:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
80104bd2:	00 
80104bd3:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80104bd6:	89 44 24 04          	mov    %eax,0x4(%esp)
80104bda:	89 14 24             	mov    %edx,(%esp)
80104bdd:	e8 c4 15 00 00       	call   801061a6 <safestrcpy>
  return p;
80104be2:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104be5:	c9                   	leave  
80104be6:	c3                   	ret    

80104be7 <createInternalProcess>:


void createInternalProcess(const char *name, void (*entrypoint)())
{
80104be7:	55                   	push   %ebp
80104be8:	89 e5                	mov    %esp,%ebp
80104bea:	83 ec 28             	sub    $0x28,%esp
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
80104bed:	e8 4e fe ff ff       	call   80104a40 <allocproc>
80104bf2:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104bf5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104bf9:	0f 84 f7 00 00 00    	je     80104cf6 <createInternalProcess+0x10f>
    return;

  // Copy process state from p.
  if((np->pgdir = setupkvm(kalloc)) == 0)
80104bff:	c7 04 24 10 2b 10 80 	movl   $0x80102b10,(%esp)
80104c06:	e8 ca 43 00 00       	call   80108fd5 <setupkvm>
80104c0b:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c0e:	89 42 04             	mov    %eax,0x4(%edx)
80104c11:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c14:	8b 40 04             	mov    0x4(%eax),%eax
80104c17:	85 c0                	test   %eax,%eax
80104c19:	75 0c                	jne    80104c27 <createInternalProcess+0x40>
      panic("inswapper: out of memory?");
80104c1b:	c7 04 24 18 9c 10 80 	movl   $0x80109c18,(%esp)
80104c22:	e8 16 b9 ff ff       	call   8010053d <panic>

  np->sz = PGSIZE;
80104c27:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c2a:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  np->parent = initproc;
80104c30:	8b 15 6c d6 10 80    	mov    0x8010d66c,%edx
80104c36:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c39:	89 50 14             	mov    %edx,0x14(%eax)
  memset(np->tf, 0, sizeof(*np->tf));
80104c3c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c3f:	8b 40 18             	mov    0x18(%eax),%eax
80104c42:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
80104c49:	00 
80104c4a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104c51:	00 
80104c52:	89 04 24             	mov    %eax,(%esp)
80104c55:	e8 1c 13 00 00       	call   80105f76 <memset>
  np->tf->cs = (SEG_KCODE << 3)|0;
80104c5a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c5d:	8b 40 18             	mov    0x18(%eax),%eax
80104c60:	66 c7 40 3c 08 00    	movw   $0x8,0x3c(%eax)
  np->tf->ds = (SEG_KDATA << 3)|0;
80104c66:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c69:	8b 40 18             	mov    0x18(%eax),%eax
80104c6c:	66 c7 40 2c 10 00    	movw   $0x10,0x2c(%eax)
  np->tf->es = np->tf->ds;
80104c72:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c75:	8b 40 18             	mov    0x18(%eax),%eax
80104c78:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c7b:	8b 52 18             	mov    0x18(%edx),%edx
80104c7e:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104c82:	66 89 50 28          	mov    %dx,0x28(%eax)
  np->tf->ss = np->tf->ds;
80104c86:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c89:	8b 40 18             	mov    0x18(%eax),%eax
80104c8c:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c8f:	8b 52 18             	mov    0x18(%edx),%edx
80104c92:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104c96:	66 89 50 48          	mov    %dx,0x48(%eax)
  np->tf->eflags = FL_IF;
80104c9a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c9d:	8b 40 18             	mov    0x18(%eax),%eax
80104ca0:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  //np->tf->esp = (uint)entrypoint+PGSIZE;
  //np->tf->eip = (uint)entrypoint;
  np->context->eip = (uint)entrypoint;
80104ca7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104caa:	8b 40 1c             	mov    0x1c(%eax),%eax
80104cad:	8b 55 0c             	mov    0xc(%ebp),%edx
80104cb0:	89 50 10             	mov    %edx,0x10(%eax)

  inswapper = np;
80104cb3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104cb6:	a3 70 d6 10 80       	mov    %eax,0x8010d670
  np->cwd = namei("/");
80104cbb:	c7 04 24 32 9c 10 80 	movl   $0x80109c32,(%esp)
80104cc2:	e8 43 d7 ff ff       	call   8010240a <namei>
80104cc7:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104cca:	89 42 68             	mov    %eax,0x68(%edx)
  safestrcpy(np->name, name, sizeof(name));
80104ccd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104cd0:	8d 50 6c             	lea    0x6c(%eax),%edx
80104cd3:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80104cda:	00 
80104cdb:	8b 45 08             	mov    0x8(%ebp),%eax
80104cde:	89 44 24 04          	mov    %eax,0x4(%esp)
80104ce2:	89 14 24             	mov    %edx,(%esp)
80104ce5:	e8 bc 14 00 00       	call   801061a6 <safestrcpy>
  np->state = RUNNABLE;
80104cea:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ced:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
80104cf4:	eb 01                	jmp    80104cf7 <createInternalProcess+0x110>
{
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
    return;
80104cf6:	90                   	nop

  inswapper = np;
  np->cwd = namei("/");
  safestrcpy(np->name, name, sizeof(name));
  np->state = RUNNABLE;
}
80104cf7:	c9                   	leave  
80104cf8:	c3                   	ret    

80104cf9 <swapIn>:

void swapIn()
{
80104cf9:	55                   	push   %ebp
80104cfa:	89 e5                	mov    %esp,%ebp
80104cfc:	83 ec 38             	sub    $0x38,%esp
  struct proc* t;
  for(;;)
  {
    for(t = ptable.proc; t < &ptable.proc[NPROC]; t++)
80104cff:	c7 45 f4 b4 4f 19 80 	movl   $0x80194fb4,-0xc(%ebp)
80104d06:	e9 e0 01 00 00       	jmp    80104eeb <swapIn+0x1f2>
    {
      if(t->state != RUNNABLE_SUSPENDED)
80104d0b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d0e:	8b 40 0c             	mov    0xc(%eax),%eax
80104d11:	83 f8 07             	cmp    $0x7,%eax
80104d14:	0f 85 c9 01 00 00    	jne    80104ee3 <swapIn+0x1ea>
	continue;
      
      //open file pid.swap
      if(holding(&ptable.lock))
80104d1a:	c7 04 24 80 4f 19 80 	movl   $0x80194f80,(%esp)
80104d21:	e8 20 11 00 00       	call   80105e46 <holding>
80104d26:	85 c0                	test   %eax,%eax
80104d28:	74 0c                	je     80104d36 <swapIn+0x3d>
	release(&ptable.lock);
80104d2a:	c7 04 24 80 4f 19 80 	movl   $0x80194f80,(%esp)
80104d31:	e8 54 10 00 00       	call   80105d8a <release>
      if((t->swap = fileopen(t->swapFileName,O_RDONLY)) == 0)
80104d36:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d39:	83 e8 80             	sub    $0xffffff80,%eax
80104d3c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104d43:	00 
80104d44:	89 04 24             	mov    %eax,(%esp)
80104d47:	e8 0b 21 00 00       	call   80106e57 <fileopen>
80104d4c:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104d4f:	89 42 7c             	mov    %eax,0x7c(%edx)
80104d52:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d55:	8b 40 7c             	mov    0x7c(%eax),%eax
80104d58:	85 c0                	test   %eax,%eax
80104d5a:	75 1d                	jne    80104d79 <swapIn+0x80>
      {
	cprintf("fileopen failed\n");
80104d5c:	c7 04 24 34 9c 10 80 	movl   $0x80109c34,(%esp)
80104d63:	e8 39 b6 ff ff       	call   801003a1 <cprintf>
	acquire(&ptable.lock);
80104d68:	c7 04 24 80 4f 19 80 	movl   $0x80194f80,(%esp)
80104d6f:	e8 7b 0f 00 00       	call   80105cef <acquire>
	break;
80104d74:	e9 7f 01 00 00       	jmp    80104ef8 <swapIn+0x1ff>
      }
      acquire(&ptable.lock);
80104d79:	c7 04 24 80 4f 19 80 	movl   $0x80194f80,(%esp)
80104d80:	e8 6a 0f 00 00       	call   80105cef <acquire>
            
      // allocate virtual memory
      if((t->pgdir = setupkvm(kalloc)) == 0)
80104d85:	c7 04 24 10 2b 10 80 	movl   $0x80102b10,(%esp)
80104d8c:	e8 44 42 00 00       	call   80108fd5 <setupkvm>
80104d91:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104d94:	89 42 04             	mov    %eax,0x4(%edx)
80104d97:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d9a:	8b 40 04             	mov    0x4(%eax),%eax
80104d9d:	85 c0                	test   %eax,%eax
80104d9f:	75 0c                	jne    80104dad <swapIn+0xb4>
	panic("inswapper: out of memory?");
80104da1:	c7 04 24 18 9c 10 80 	movl   $0x80109c18,(%esp)
80104da8:	e8 90 b7 ff ff       	call   8010053d <panic>
      if(!allocuvm(t->pgdir, 0, t->sz))
80104dad:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104db0:	8b 10                	mov    (%eax),%edx
80104db2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104db5:	8b 40 04             	mov    0x4(%eax),%eax
80104db8:	89 54 24 08          	mov    %edx,0x8(%esp)
80104dbc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104dc3:	00 
80104dc4:	89 04 24             	mov    %eax,(%esp)
80104dc7:	e8 db 45 00 00       	call   801093a7 <allocuvm>
80104dcc:	85 c0                	test   %eax,%eax
80104dce:	75 11                	jne    80104de1 <swapIn+0xe8>
      {
	cprintf("allocuvm failed\n");
80104dd0:	c7 04 24 45 9c 10 80 	movl   $0x80109c45,(%esp)
80104dd7:	e8 c5 b5 ff ff       	call   801003a1 <cprintf>
	break;
80104ddc:	e9 17 01 00 00       	jmp    80104ef8 <swapIn+0x1ff>
      }
      
      if(holding(&ptable.lock))
80104de1:	c7 04 24 80 4f 19 80 	movl   $0x80194f80,(%esp)
80104de8:	e8 59 10 00 00       	call   80105e46 <holding>
80104ded:	85 c0                	test   %eax,%eax
80104def:	74 0c                	je     80104dfd <swapIn+0x104>
	release(&ptable.lock);
80104df1:	c7 04 24 80 4f 19 80 	movl   $0x80194f80,(%esp)
80104df8:	e8 8d 0f 00 00       	call   80105d8a <release>
      loaduvm(t->pgdir,0,t->swap->ip,0,t->sz);
80104dfd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e00:	8b 08                	mov    (%eax),%ecx
80104e02:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e05:	8b 40 7c             	mov    0x7c(%eax),%eax
80104e08:	8b 50 10             	mov    0x10(%eax),%edx
80104e0b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e0e:	8b 40 04             	mov    0x4(%eax),%eax
80104e11:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80104e15:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80104e1c:	00 
80104e1d:	89 54 24 08          	mov    %edx,0x8(%esp)
80104e21:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104e28:	00 
80104e29:	89 04 24             	mov    %eax,(%esp)
80104e2c:	e8 87 44 00 00       	call   801092b8 <loaduvm>
      
      t->isSwapped = 0;
80104e31:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e34:	c7 80 88 00 00 00 00 	movl   $0x0,0x88(%eax)
80104e3b:	00 00 00 
      int fd;
      for(fd = 0; fd < NOFILE; fd++)
80104e3e:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80104e45:	eb 63                	jmp    80104eaa <swapIn+0x1b1>
      {
	if(proc->ofile[fd] && proc->ofile[fd] == proc->swap)
80104e47:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e4d:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104e50:	83 c2 08             	add    $0x8,%edx
80104e53:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104e57:	85 c0                	test   %eax,%eax
80104e59:	74 4b                	je     80104ea6 <swapIn+0x1ad>
80104e5b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e61:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104e64:	83 c2 08             	add    $0x8,%edx
80104e67:	8b 54 90 08          	mov    0x8(%eax,%edx,4),%edx
80104e6b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e71:	8b 40 7c             	mov    0x7c(%eax),%eax
80104e74:	39 c2                	cmp    %eax,%edx
80104e76:	75 2e                	jne    80104ea6 <swapIn+0x1ad>
	{
	  fileclose(proc->ofile[fd]);
80104e78:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e7e:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104e81:	83 c2 08             	add    $0x8,%edx
80104e84:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104e88:	89 04 24             	mov    %eax,(%esp)
80104e8b:	e8 34 c1 ff ff       	call   80100fc4 <fileclose>
	  proc->ofile[fd] = 0;
80104e90:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e96:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104e99:	83 c2 08             	add    $0x8,%edx
80104e9c:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80104ea3:	00 
	  break;
80104ea4:	eb 0a                	jmp    80104eb0 <swapIn+0x1b7>
	release(&ptable.lock);
      loaduvm(t->pgdir,0,t->swap->ip,0,t->sz);
      
      t->isSwapped = 0;
      int fd;
      for(fd = 0; fd < NOFILE; fd++)
80104ea6:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80104eaa:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
80104eae:	7e 97                	jle    80104e47 <swapIn+0x14e>
	  fileclose(proc->ofile[fd]);
	  proc->ofile[fd] = 0;
	  break;
	}
      }
      proc->swap=0;
80104eb0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104eb6:	c7 40 7c 00 00 00 00 	movl   $0x0,0x7c(%eax)
      unlink(t->swapFileName);
80104ebd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ec0:	83 e8 80             	sub    $0xffffff80,%eax
80104ec3:	89 04 24             	mov    %eax,(%esp)
80104ec6:	e8 47 1a 00 00       	call   80106912 <unlink>
      acquire(&ptable.lock);
80104ecb:	c7 04 24 80 4f 19 80 	movl   $0x80194f80,(%esp)
80104ed2:	e8 18 0e 00 00       	call   80105cef <acquire>
      //cprintf("eip = %d\n",t->tf->eip);
      t->state = RUNNABLE;
80104ed7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104eda:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
80104ee1:	eb 01                	jmp    80104ee4 <swapIn+0x1eb>
  for(;;)
  {
    for(t = ptable.proc; t < &ptable.proc[NPROC]; t++)
    {
      if(t->state != RUNNABLE_SUSPENDED)
	continue;
80104ee3:	90                   	nop
void swapIn()
{
  struct proc* t;
  for(;;)
  {
    for(t = ptable.proc; t < &ptable.proc[NPROC]; t++)
80104ee4:	81 45 f4 90 00 00 00 	addl   $0x90,-0xc(%ebp)
80104eeb:	81 7d f4 b4 73 19 80 	cmpl   $0x801973b4,-0xc(%ebp)
80104ef2:	0f 82 13 fe ff ff    	jb     80104d0b <swapIn+0x12>
      unlink(t->swapFileName);
      acquire(&ptable.lock);
      //cprintf("eip = %d\n",t->tf->eip);
      t->state = RUNNABLE;
    }
    proc->chan = inswapper;
80104ef8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104efe:	8b 15 70 d6 10 80    	mov    0x8010d670,%edx
80104f04:	89 50 20             	mov    %edx,0x20(%eax)
    proc->state = SLEEPING;
80104f07:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f0d:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
    sched();
80104f14:	e8 87 08 00 00       	call   801057a0 <sched>
    proc->chan = 0;
80104f19:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f1f:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)
  }
80104f26:	e9 d4 fd ff ff       	jmp    80104cff <swapIn+0x6>

80104f2b <swapOut>:
}

void
swapOut()
{
80104f2b:	55                   	push   %ebp
80104f2c:	89 e5                	mov    %esp,%ebp
80104f2e:	53                   	push   %ebx
80104f2f:	83 ec 24             	sub    $0x24,%esp
    proc->swap = fileopen(proc->swapFileName,(O_CREATE | O_RDWR));
80104f32:	65 8b 1d 04 00 00 00 	mov    %gs:0x4,%ebx
80104f39:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f3f:	83 e8 80             	sub    $0xffffff80,%eax
80104f42:	c7 44 24 04 02 02 00 	movl   $0x202,0x4(%esp)
80104f49:	00 
80104f4a:	89 04 24             	mov    %eax,(%esp)
80104f4d:	e8 05 1f 00 00       	call   80106e57 <fileopen>
80104f52:	89 43 7c             	mov    %eax,0x7c(%ebx)
    pte_t *pte;
    uint pa, j;
    for(j = 0; j < proc->sz; j += PGSIZE)
80104f55:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104f5c:	e9 9a 00 00 00       	jmp    80104ffb <swapOut+0xd0>
    {
      if((pte = walkpgdir(proc->pgdir, (void *) j, 0)) == 0)
80104f61:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104f64:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f6a:	8b 40 04             	mov    0x4(%eax),%eax
80104f6d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80104f74:	00 
80104f75:	89 54 24 04          	mov    %edx,0x4(%esp)
80104f79:	89 04 24             	mov    %eax,(%esp)
80104f7c:	e8 2a 3f 00 00       	call   80108eab <walkpgdir>
80104f81:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104f84:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80104f88:	75 0c                	jne    80104f96 <swapOut+0x6b>
	panic("walkpgdir: pte should exist");
80104f8a:	c7 04 24 56 9c 10 80 	movl   $0x80109c56,(%esp)
80104f91:	e8 a7 b5 ff ff       	call   8010053d <panic>
      if(!(*pte & PTE_P))
80104f96:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104f99:	8b 00                	mov    (%eax),%eax
80104f9b:	83 e0 01             	and    $0x1,%eax
80104f9e:	85 c0                	test   %eax,%eax
80104fa0:	75 0c                	jne    80104fae <swapOut+0x83>
	panic("walkpgdir: page not present");
80104fa2:	c7 04 24 72 9c 10 80 	movl   $0x80109c72,(%esp)
80104fa9:	e8 8f b5 ff ff       	call   8010053d <panic>
      pa = PTE_ADDR(*pte);
80104fae:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104fb1:	8b 00                	mov    (%eax),%eax
80104fb3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80104fb8:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(filewrite(proc->swap, (char*)p2v(pa), PGSIZE) < 0)
80104fbb:	8b 45 e8             	mov    -0x18(%ebp),%eax
80104fbe:	89 04 24             	mov    %eax,(%esp)
80104fc1:	e8 36 fa ff ff       	call   801049fc <p2v>
80104fc6:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104fcd:	8b 52 7c             	mov    0x7c(%edx),%edx
80104fd0:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80104fd7:	00 
80104fd8:	89 44 24 04          	mov    %eax,0x4(%esp)
80104fdc:	89 14 24             	mov    %edx,(%esp)
80104fdf:	e8 c1 c1 ff ff       	call   801011a5 <filewrite>
80104fe4:	85 c0                	test   %eax,%eax
80104fe6:	79 0c                	jns    80104ff4 <swapOut+0xc9>
	panic("filewrite failed");
80104fe8:	c7 04 24 8e 9c 10 80 	movl   $0x80109c8e,(%esp)
80104fef:	e8 49 b5 ff ff       	call   8010053d <panic>
swapOut()
{
    proc->swap = fileopen(proc->swapFileName,(O_CREATE | O_RDWR));
    pte_t *pte;
    uint pa, j;
    for(j = 0; j < proc->sz; j += PGSIZE)
80104ff4:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80104ffb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105001:	8b 00                	mov    (%eax),%eax
80105003:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80105006:	0f 87 55 ff ff ff    	ja     80104f61 <swapOut+0x36>
      if(filewrite(proc->swap, (char*)p2v(pa), PGSIZE) < 0)
	panic("filewrite failed");
    }

    int fd;
    for(fd = 0; fd < NOFILE; fd++)
8010500c:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80105013:	eb 63                	jmp    80105078 <swapOut+0x14d>
    {
      if(proc->ofile[fd] && proc->ofile[fd] == proc->swap)
80105015:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010501b:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010501e:	83 c2 08             	add    $0x8,%edx
80105021:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105025:	85 c0                	test   %eax,%eax
80105027:	74 4b                	je     80105074 <swapOut+0x149>
80105029:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010502f:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105032:	83 c2 08             	add    $0x8,%edx
80105035:	8b 54 90 08          	mov    0x8(%eax,%edx,4),%edx
80105039:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010503f:	8b 40 7c             	mov    0x7c(%eax),%eax
80105042:	39 c2                	cmp    %eax,%edx
80105044:	75 2e                	jne    80105074 <swapOut+0x149>
      {
	fileclose(proc->ofile[fd]);
80105046:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010504c:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010504f:	83 c2 08             	add    $0x8,%edx
80105052:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105056:	89 04 24             	mov    %eax,(%esp)
80105059:	e8 66 bf ff ff       	call   80100fc4 <fileclose>
	proc->ofile[fd] = 0;
8010505e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105064:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105067:	83 c2 08             	add    $0x8,%edx
8010506a:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80105071:	00 
	break;
80105072:	eb 0a                	jmp    8010507e <swapOut+0x153>
      if(filewrite(proc->swap, (char*)p2v(pa), PGSIZE) < 0)
	panic("filewrite failed");
    }

    int fd;
    for(fd = 0; fd < NOFILE; fd++)
80105074:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80105078:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
8010507c:	7e 97                	jle    80105015 <swapOut+0xea>
	fileclose(proc->ofile[fd]);
	proc->ofile[fd] = 0;
	break;
      }
    }
    proc->swap=0;
8010507e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105084:	c7 40 7c 00 00 00 00 	movl   $0x0,0x7c(%eax)
    //freevm(proc->pgdir);
    deallocuvm(proc->pgdir,proc->sz,0);
8010508b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105091:	8b 10                	mov    (%eax),%edx
80105093:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105099:	8b 40 04             	mov    0x4(%eax),%eax
8010509c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801050a3:	00 
801050a4:	89 54 24 04          	mov    %edx,0x4(%esp)
801050a8:	89 04 24             	mov    %eax,(%esp)
801050ab:	e8 d1 43 00 00       	call   80109481 <deallocuvm>
    proc->state = SLEEPING_SUSPENDED;
801050b0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050b6:	c7 40 0c 06 00 00 00 	movl   $0x6,0xc(%eax)
    proc->isSwapped = 1;
801050bd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050c3:	c7 80 88 00 00 00 01 	movl   $0x1,0x88(%eax)
801050ca:	00 00 00 
}
801050cd:	83 c4 24             	add    $0x24,%esp
801050d0:	5b                   	pop    %ebx
801050d1:	5d                   	pop    %ebp
801050d2:	c3                   	ret    

801050d3 <userinit>:

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
801050d3:	55                   	push   %ebp
801050d4:	89 e5                	mov    %esp,%ebp
801050d6:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
801050d9:	e8 62 f9 ff ff       	call   80104a40 <allocproc>
801050de:	89 45 f4             	mov    %eax,-0xc(%ebp)
  initproc = p;
801050e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801050e4:	a3 6c d6 10 80       	mov    %eax,0x8010d66c
  if((p->pgdir = setupkvm(kalloc)) == 0)
801050e9:	c7 04 24 10 2b 10 80 	movl   $0x80102b10,(%esp)
801050f0:	e8 e0 3e 00 00       	call   80108fd5 <setupkvm>
801050f5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801050f8:	89 42 04             	mov    %eax,0x4(%edx)
801050fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801050fe:	8b 40 04             	mov    0x4(%eax),%eax
80105101:	85 c0                	test   %eax,%eax
80105103:	75 0c                	jne    80105111 <userinit+0x3e>
    panic("userinit: out of memory?");
80105105:	c7 04 24 9f 9c 10 80 	movl   $0x80109c9f,(%esp)
8010510c:	e8 2c b4 ff ff       	call   8010053d <panic>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80105111:	ba 2c 00 00 00       	mov    $0x2c,%edx
80105116:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105119:	8b 40 04             	mov    0x4(%eax),%eax
8010511c:	89 54 24 08          	mov    %edx,0x8(%esp)
80105120:	c7 44 24 04 00 d5 10 	movl   $0x8010d500,0x4(%esp)
80105127:	80 
80105128:	89 04 24             	mov    %eax,(%esp)
8010512b:	e8 fd 40 00 00       	call   8010922d <inituvm>
  p->sz = PGSIZE;
80105130:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105133:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  memset(p->tf, 0, sizeof(*p->tf));
80105139:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010513c:	8b 40 18             	mov    0x18(%eax),%eax
8010513f:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
80105146:	00 
80105147:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010514e:	00 
8010514f:	89 04 24             	mov    %eax,(%esp)
80105152:	e8 1f 0e 00 00       	call   80105f76 <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
80105157:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010515a:	8b 40 18             	mov    0x18(%eax),%eax
8010515d:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
80105163:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105166:	8b 40 18             	mov    0x18(%eax),%eax
80105169:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
  p->tf->es = p->tf->ds;
8010516f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105172:	8b 40 18             	mov    0x18(%eax),%eax
80105175:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105178:	8b 52 18             	mov    0x18(%edx),%edx
8010517b:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
8010517f:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
80105183:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105186:	8b 40 18             	mov    0x18(%eax),%eax
80105189:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010518c:	8b 52 18             	mov    0x18(%edx),%edx
8010518f:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80105193:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
80105197:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010519a:	8b 40 18             	mov    0x18(%eax),%eax
8010519d:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
801051a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051a7:	8b 40 18             	mov    0x18(%eax),%eax
801051aa:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
801051b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051b4:	8b 40 18             	mov    0x18(%eax),%eax
801051b7:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
801051be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051c1:	83 c0 6c             	add    $0x6c,%eax
801051c4:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
801051cb:	00 
801051cc:	c7 44 24 04 b8 9c 10 	movl   $0x80109cb8,0x4(%esp)
801051d3:	80 
801051d4:	89 04 24             	mov    %eax,(%esp)
801051d7:	e8 ca 0f 00 00       	call   801061a6 <safestrcpy>
  p->cwd = namei("/");
801051dc:	c7 04 24 32 9c 10 80 	movl   $0x80109c32,(%esp)
801051e3:	e8 22 d2 ff ff       	call   8010240a <namei>
801051e8:	8b 55 f4             	mov    -0xc(%ebp),%edx
801051eb:	89 42 68             	mov    %eax,0x68(%edx)

  p->state = RUNNABLE;
801051ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051f1:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)

  createInternalProcess("inswapper", swapIn);
801051f8:	c7 44 24 04 f9 4c 10 	movl   $0x80104cf9,0x4(%esp)
801051ff:	80 
80105200:	c7 04 24 c1 9c 10 80 	movl   $0x80109cc1,(%esp)
80105207:	e8 db f9 ff ff       	call   80104be7 <createInternalProcess>
}
8010520c:	c9                   	leave  
8010520d:	c3                   	ret    

8010520e <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
8010520e:	55                   	push   %ebp
8010520f:	89 e5                	mov    %esp,%ebp
80105211:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  
  sz = proc->sz;
80105214:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010521a:	8b 00                	mov    (%eax),%eax
8010521c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
8010521f:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80105223:	7e 34                	jle    80105259 <growproc+0x4b>
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
80105225:	8b 45 08             	mov    0x8(%ebp),%eax
80105228:	89 c2                	mov    %eax,%edx
8010522a:	03 55 f4             	add    -0xc(%ebp),%edx
8010522d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105233:	8b 40 04             	mov    0x4(%eax),%eax
80105236:	89 54 24 08          	mov    %edx,0x8(%esp)
8010523a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010523d:	89 54 24 04          	mov    %edx,0x4(%esp)
80105241:	89 04 24             	mov    %eax,(%esp)
80105244:	e8 5e 41 00 00       	call   801093a7 <allocuvm>
80105249:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010524c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105250:	75 41                	jne    80105293 <growproc+0x85>
      return -1;
80105252:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105257:	eb 58                	jmp    801052b1 <growproc+0xa3>
  } else if(n < 0){
80105259:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010525d:	79 34                	jns    80105293 <growproc+0x85>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
8010525f:	8b 45 08             	mov    0x8(%ebp),%eax
80105262:	89 c2                	mov    %eax,%edx
80105264:	03 55 f4             	add    -0xc(%ebp),%edx
80105267:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010526d:	8b 40 04             	mov    0x4(%eax),%eax
80105270:	89 54 24 08          	mov    %edx,0x8(%esp)
80105274:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105277:	89 54 24 04          	mov    %edx,0x4(%esp)
8010527b:	89 04 24             	mov    %eax,(%esp)
8010527e:	e8 fe 41 00 00       	call   80109481 <deallocuvm>
80105283:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105286:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010528a:	75 07                	jne    80105293 <growproc+0x85>
      return -1;
8010528c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105291:	eb 1e                	jmp    801052b1 <growproc+0xa3>
  }
  proc->sz = sz;
80105293:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105299:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010529c:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
8010529e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801052a4:	89 04 24             	mov    %eax,(%esp)
801052a7:	e8 1a 3e 00 00       	call   801090c6 <switchuvm>
  return 0;
801052ac:	b8 00 00 00 00       	mov    $0x0,%eax
}
801052b1:	c9                   	leave  
801052b2:	c3                   	ret    

801052b3 <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
801052b3:	55                   	push   %ebp
801052b4:	89 e5                	mov    %esp,%ebp
801052b6:	57                   	push   %edi
801052b7:	56                   	push   %esi
801052b8:	53                   	push   %ebx
801052b9:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
801052bc:	e8 7f f7 ff ff       	call   80104a40 <allocproc>
801052c1:	89 45 e0             	mov    %eax,-0x20(%ebp)
801052c4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
801052c8:	75 0a                	jne    801052d4 <fork+0x21>
    return -1;
801052ca:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801052cf:	e9 3a 01 00 00       	jmp    8010540e <fork+0x15b>
  
  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
801052d4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801052da:	8b 10                	mov    (%eax),%edx
801052dc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801052e2:	8b 40 04             	mov    0x4(%eax),%eax
801052e5:	89 54 24 04          	mov    %edx,0x4(%esp)
801052e9:	89 04 24             	mov    %eax,(%esp)
801052ec:	e8 20 43 00 00       	call   80109611 <copyuvm>
801052f1:	8b 55 e0             	mov    -0x20(%ebp),%edx
801052f4:	89 42 04             	mov    %eax,0x4(%edx)
801052f7:	8b 45 e0             	mov    -0x20(%ebp),%eax
801052fa:	8b 40 04             	mov    0x4(%eax),%eax
801052fd:	85 c0                	test   %eax,%eax
801052ff:	75 2c                	jne    8010532d <fork+0x7a>
    kfree(np->kstack);
80105301:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105304:	8b 40 08             	mov    0x8(%eax),%eax
80105307:	89 04 24             	mov    %eax,(%esp)
8010530a:	e8 68 d7 ff ff       	call   80102a77 <kfree>
    np->kstack = 0;
8010530f:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105312:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
80105319:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010531c:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
80105323:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105328:	e9 e1 00 00 00       	jmp    8010540e <fork+0x15b>
  }
  np->sz = proc->sz;
8010532d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105333:	8b 10                	mov    (%eax),%edx
80105335:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105338:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
8010533a:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80105341:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105344:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *proc->tf;
80105347:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010534a:	8b 50 18             	mov    0x18(%eax),%edx
8010534d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105353:	8b 40 18             	mov    0x18(%eax),%eax
80105356:	89 c3                	mov    %eax,%ebx
80105358:	b8 13 00 00 00       	mov    $0x13,%eax
8010535d:	89 d7                	mov    %edx,%edi
8010535f:	89 de                	mov    %ebx,%esi
80105361:	89 c1                	mov    %eax,%ecx
80105363:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
80105365:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105368:	8b 40 18             	mov    0x18(%eax),%eax
8010536b:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
80105372:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80105379:	eb 3d                	jmp    801053b8 <fork+0x105>
    if(proc->ofile[i])
8010537b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105381:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80105384:	83 c2 08             	add    $0x8,%edx
80105387:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010538b:	85 c0                	test   %eax,%eax
8010538d:	74 25                	je     801053b4 <fork+0x101>
      np->ofile[i] = filedup(proc->ofile[i]);
8010538f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105395:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80105398:	83 c2 08             	add    $0x8,%edx
8010539b:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010539f:	89 04 24             	mov    %eax,(%esp)
801053a2:	e8 d5 bb ff ff       	call   80100f7c <filedup>
801053a7:	8b 55 e0             	mov    -0x20(%ebp),%edx
801053aa:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
801053ad:	83 c1 08             	add    $0x8,%ecx
801053b0:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
801053b4:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
801053b8:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
801053bc:	7e bd                	jle    8010537b <fork+0xc8>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
801053be:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801053c4:	8b 40 68             	mov    0x68(%eax),%eax
801053c7:	89 04 24             	mov    %eax,(%esp)
801053ca:	e8 67 c4 ff ff       	call   80101836 <idup>
801053cf:	8b 55 e0             	mov    -0x20(%ebp),%edx
801053d2:	89 42 68             	mov    %eax,0x68(%edx)
 
  pid = np->pid;
801053d5:	8b 45 e0             	mov    -0x20(%ebp),%eax
801053d8:	8b 40 10             	mov    0x10(%eax),%eax
801053db:	89 45 dc             	mov    %eax,-0x24(%ebp)
  np->state = RUNNABLE;
801053de:	8b 45 e0             	mov    -0x20(%ebp),%eax
801053e1:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  safestrcpy(np->name, proc->name, sizeof(proc->name));
801053e8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801053ee:	8d 50 6c             	lea    0x6c(%eax),%edx
801053f1:	8b 45 e0             	mov    -0x20(%ebp),%eax
801053f4:	83 c0 6c             	add    $0x6c,%eax
801053f7:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
801053fe:	00 
801053ff:	89 54 24 04          	mov    %edx,0x4(%esp)
80105403:	89 04 24             	mov    %eax,(%esp)
80105406:	e8 9b 0d 00 00       	call   801061a6 <safestrcpy>
  return pid;
8010540b:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
8010540e:	83 c4 2c             	add    $0x2c,%esp
80105411:	5b                   	pop    %ebx
80105412:	5e                   	pop    %esi
80105413:	5f                   	pop    %edi
80105414:	5d                   	pop    %ebp
80105415:	c3                   	ret    

80105416 <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
80105416:	55                   	push   %ebp
80105417:	89 e5                	mov    %esp,%ebp
80105419:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int fd;

  if(proc == initproc)
8010541c:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80105423:	a1 6c d6 10 80       	mov    0x8010d66c,%eax
80105428:	39 c2                	cmp    %eax,%edx
8010542a:	75 0c                	jne    80105438 <exit+0x22>
    panic("init exiting");
8010542c:	c7 04 24 cb 9c 10 80 	movl   $0x80109ccb,(%esp)
80105433:	e8 05 b1 ff ff       	call   8010053d <panic>

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80105438:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
8010543f:	eb 44                	jmp    80105485 <exit+0x6f>
    if(proc->ofile[fd]){
80105441:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105447:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010544a:	83 c2 08             	add    $0x8,%edx
8010544d:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105451:	85 c0                	test   %eax,%eax
80105453:	74 2c                	je     80105481 <exit+0x6b>
      fileclose(proc->ofile[fd]);
80105455:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010545b:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010545e:	83 c2 08             	add    $0x8,%edx
80105461:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105465:	89 04 24             	mov    %eax,(%esp)
80105468:	e8 57 bb ff ff       	call   80100fc4 <fileclose>
      proc->ofile[fd] = 0;
8010546d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105473:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105476:	83 c2 08             	add    $0x8,%edx
80105479:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80105480:	00 

  if(proc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80105481:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80105485:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
80105489:	7e b6                	jle    80105441 <exit+0x2b>
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  iput(proc->cwd);
8010548b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105491:	8b 40 68             	mov    0x68(%eax),%eax
80105494:	89 04 24             	mov    %eax,(%esp)
80105497:	e8 7f c5 ff ff       	call   80101a1b <iput>
  proc->cwd = 0;
8010549c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054a2:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)
  
  if(proc->has_shm)
801054a9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054af:	8b 80 8c 00 00 00    	mov    0x8c(%eax),%eax
801054b5:	85 c0                	test   %eax,%eax
801054b7:	74 11                	je     801054ca <exit+0xb4>
    deallocshm(proc->pid);		//deallocate any shared memory segments proc did not shmdt
801054b9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054bf:	8b 40 10             	mov    0x10(%eax),%eax
801054c2:	89 04 24             	mov    %eax,(%esp)
801054c5:	e8 d4 de ff ff       	call   8010339e <deallocshm>
  
  acquire(&ptable.lock);
801054ca:	c7 04 24 80 4f 19 80 	movl   $0x80194f80,(%esp)
801054d1:	e8 19 08 00 00       	call   80105cef <acquire>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);
801054d6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054dc:	8b 40 14             	mov    0x14(%eax),%eax
801054df:	89 04 24             	mov    %eax,(%esp)
801054e2:	e8 98 04 00 00       	call   8010597f <wakeup1>

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801054e7:	c7 45 f4 b4 4f 19 80 	movl   $0x80194fb4,-0xc(%ebp)
801054ee:	eb 3b                	jmp    8010552b <exit+0x115>
    if(p->parent == proc){
801054f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801054f3:	8b 50 14             	mov    0x14(%eax),%edx
801054f6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054fc:	39 c2                	cmp    %eax,%edx
801054fe:	75 24                	jne    80105524 <exit+0x10e>
      p->parent = initproc;
80105500:	8b 15 6c d6 10 80    	mov    0x8010d66c,%edx
80105506:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105509:	89 50 14             	mov    %edx,0x14(%eax)
      if(p->state == ZOMBIE)
8010550c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010550f:	8b 40 0c             	mov    0xc(%eax),%eax
80105512:	83 f8 05             	cmp    $0x5,%eax
80105515:	75 0d                	jne    80105524 <exit+0x10e>
        wakeup1(initproc);
80105517:	a1 6c d6 10 80       	mov    0x8010d66c,%eax
8010551c:	89 04 24             	mov    %eax,(%esp)
8010551f:	e8 5b 04 00 00       	call   8010597f <wakeup1>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105524:	81 45 f4 90 00 00 00 	addl   $0x90,-0xc(%ebp)
8010552b:	81 7d f4 b4 73 19 80 	cmpl   $0x801973b4,-0xc(%ebp)
80105532:	72 bc                	jb     801054f0 <exit+0xda>
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  proc->state = ZOMBIE;
80105534:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010553a:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
  sched();
80105541:	e8 5a 02 00 00       	call   801057a0 <sched>
  panic("zombie exit");
80105546:	c7 04 24 d8 9c 10 80 	movl   $0x80109cd8,(%esp)
8010554d:	e8 eb af ff ff       	call   8010053d <panic>

80105552 <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
80105552:	55                   	push   %ebp
80105553:	89 e5                	mov    %esp,%ebp
80105555:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
80105558:	c7 04 24 80 4f 19 80 	movl   $0x80194f80,(%esp)
8010555f:	e8 8b 07 00 00       	call   80105cef <acquire>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
80105564:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010556b:	c7 45 f4 b4 4f 19 80 	movl   $0x80194fb4,-0xc(%ebp)
80105572:	e9 9d 00 00 00       	jmp    80105614 <wait+0xc2>
      if(p->parent != proc)
80105577:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010557a:	8b 50 14             	mov    0x14(%eax),%edx
8010557d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105583:	39 c2                	cmp    %eax,%edx
80105585:	0f 85 81 00 00 00    	jne    8010560c <wait+0xba>
        continue;
      havekids = 1;
8010558b:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
      if(p->state == ZOMBIE){
80105592:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105595:	8b 40 0c             	mov    0xc(%eax),%eax
80105598:	83 f8 05             	cmp    $0x5,%eax
8010559b:	75 70                	jne    8010560d <wait+0xbb>
        // Found one.
        pid = p->pid;
8010559d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055a0:	8b 40 10             	mov    0x10(%eax),%eax
801055a3:	89 45 ec             	mov    %eax,-0x14(%ebp)
        kfree(p->kstack);
801055a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055a9:	8b 40 08             	mov    0x8(%eax),%eax
801055ac:	89 04 24             	mov    %eax,(%esp)
801055af:	e8 c3 d4 ff ff       	call   80102a77 <kfree>
        p->kstack = 0;
801055b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055b7:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
        freevm(p->pgdir);
801055be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055c1:	8b 40 04             	mov    0x4(%eax),%eax
801055c4:	89 04 24             	mov    %eax,(%esp)
801055c7:	e8 71 3f 00 00       	call   8010953d <freevm>
        p->state = UNUSED;
801055cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055cf:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        p->pid = 0;
801055d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055d9:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
        p->parent = 0;
801055e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055e3:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
        p->name[0] = 0;
801055ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055ed:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)
        p->killed = 0;
801055f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055f4:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
        release(&ptable.lock);
801055fb:	c7 04 24 80 4f 19 80 	movl   $0x80194f80,(%esp)
80105602:	e8 83 07 00 00       	call   80105d8a <release>
        return pid;
80105607:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010560a:	eb 56                	jmp    80105662 <wait+0x110>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->parent != proc)
        continue;
8010560c:	90                   	nop

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010560d:	81 45 f4 90 00 00 00 	addl   $0x90,-0xc(%ebp)
80105614:	81 7d f4 b4 73 19 80 	cmpl   $0x801973b4,-0xc(%ebp)
8010561b:	0f 82 56 ff ff ff    	jb     80105577 <wait+0x25>
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
80105621:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105625:	74 0d                	je     80105634 <wait+0xe2>
80105627:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010562d:	8b 40 24             	mov    0x24(%eax),%eax
80105630:	85 c0                	test   %eax,%eax
80105632:	74 13                	je     80105647 <wait+0xf5>
      release(&ptable.lock);
80105634:	c7 04 24 80 4f 19 80 	movl   $0x80194f80,(%esp)
8010563b:	e8 4a 07 00 00       	call   80105d8a <release>
      return -1;
80105640:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105645:	eb 1b                	jmp    80105662 <wait+0x110>
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
80105647:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010564d:	c7 44 24 04 80 4f 19 	movl   $0x80194f80,0x4(%esp)
80105654:	80 
80105655:	89 04 24             	mov    %eax,(%esp)
80105658:	e8 53 02 00 00       	call   801058b0 <sleep>
  }
8010565d:	e9 02 ff ff ff       	jmp    80105564 <wait+0x12>
}
80105662:	c9                   	leave  
80105663:	c3                   	ret    

80105664 <register_handler>:

void
register_handler(sighandler_t sighandler)
{
80105664:	55                   	push   %ebp
80105665:	89 e5                	mov    %esp,%ebp
80105667:	83 ec 28             	sub    $0x28,%esp
  char* addr = uva2ka(proc->pgdir, (char*)proc->tf->esp);
8010566a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105670:	8b 40 18             	mov    0x18(%eax),%eax
80105673:	8b 40 44             	mov    0x44(%eax),%eax
80105676:	89 c2                	mov    %eax,%edx
80105678:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010567e:	8b 40 04             	mov    0x4(%eax),%eax
80105681:	89 54 24 04          	mov    %edx,0x4(%esp)
80105685:	89 04 24             	mov    %eax,(%esp)
80105688:	e8 95 40 00 00       	call   80109722 <uva2ka>
8010568d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if ((proc->tf->esp & 0xFFF) == 0)
80105690:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105696:	8b 40 18             	mov    0x18(%eax),%eax
80105699:	8b 40 44             	mov    0x44(%eax),%eax
8010569c:	25 ff 0f 00 00       	and    $0xfff,%eax
801056a1:	85 c0                	test   %eax,%eax
801056a3:	75 0c                	jne    801056b1 <register_handler+0x4d>
    panic("esp_offset == 0");
801056a5:	c7 04 24 e4 9c 10 80 	movl   $0x80109ce4,(%esp)
801056ac:	e8 8c ae ff ff       	call   8010053d <panic>

    /* open a new frame */
  *(int*)(addr + ((proc->tf->esp - 4) & 0xFFF))
801056b1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801056b7:	8b 40 18             	mov    0x18(%eax),%eax
801056ba:	8b 40 44             	mov    0x44(%eax),%eax
801056bd:	83 e8 04             	sub    $0x4,%eax
801056c0:	25 ff 0f 00 00       	and    $0xfff,%eax
801056c5:	03 45 f4             	add    -0xc(%ebp),%eax
          = proc->tf->eip;
801056c8:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801056cf:	8b 52 18             	mov    0x18(%edx),%edx
801056d2:	8b 52 38             	mov    0x38(%edx),%edx
801056d5:	89 10                	mov    %edx,(%eax)
  proc->tf->esp -= 4;
801056d7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801056dd:	8b 40 18             	mov    0x18(%eax),%eax
801056e0:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801056e7:	8b 52 18             	mov    0x18(%edx),%edx
801056ea:	8b 52 44             	mov    0x44(%edx),%edx
801056ed:	83 ea 04             	sub    $0x4,%edx
801056f0:	89 50 44             	mov    %edx,0x44(%eax)

    /* update eip */
  proc->tf->eip = (uint)sighandler;
801056f3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801056f9:	8b 40 18             	mov    0x18(%eax),%eax
801056fc:	8b 55 08             	mov    0x8(%ebp),%edx
801056ff:	89 50 38             	mov    %edx,0x38(%eax)
}
80105702:	c9                   	leave  
80105703:	c3                   	ret    

80105704 <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
80105704:	55                   	push   %ebp
80105705:	89 e5                	mov    %esp,%ebp
80105707:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  
  for(;;){
    // Enable interrupts on this processor.
    sti();
8010570a:	e8 0f f3 ff ff       	call   80104a1e <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
8010570f:	c7 04 24 80 4f 19 80 	movl   $0x80194f80,(%esp)
80105716:	e8 d4 05 00 00       	call   80105cef <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010571b:	c7 45 f4 b4 4f 19 80 	movl   $0x80194fb4,-0xc(%ebp)
80105722:	eb 62                	jmp    80105786 <scheduler+0x82>
      if(p->state != RUNNABLE)
80105724:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105727:	8b 40 0c             	mov    0xc(%eax),%eax
8010572a:	83 f8 03             	cmp    $0x3,%eax
8010572d:	75 4f                	jne    8010577e <scheduler+0x7a>
        continue;
    
      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
8010572f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105732:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
      switchuvm(p);
80105738:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010573b:	89 04 24             	mov    %eax,(%esp)
8010573e:	e8 83 39 00 00       	call   801090c6 <switchuvm>
      p->state = RUNNING;
80105743:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105746:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      swtch(&cpu->scheduler, proc->context);
8010574d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105753:	8b 40 1c             	mov    0x1c(%eax),%eax
80105756:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
8010575d:	83 c2 04             	add    $0x4,%edx
80105760:	89 44 24 04          	mov    %eax,0x4(%esp)
80105764:	89 14 24             	mov    %edx,(%esp)
80105767:	e8 b0 0a 00 00       	call   8010621c <swtch>
      switchkvm();
8010576c:	e8 38 39 00 00       	call   801090a9 <switchkvm>
                 
      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
80105771:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80105778:	00 00 00 00 
8010577c:	eb 01                	jmp    8010577f <scheduler+0x7b>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->state != RUNNABLE)
        continue;
8010577e:	90                   	nop
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010577f:	81 45 f4 90 00 00 00 	addl   $0x90,-0xc(%ebp)
80105786:	81 7d f4 b4 73 19 80 	cmpl   $0x801973b4,-0xc(%ebp)
8010578d:	72 95                	jb     80105724 <scheduler+0x20>
                 
      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
8010578f:	c7 04 24 80 4f 19 80 	movl   $0x80194f80,(%esp)
80105796:	e8 ef 05 00 00       	call   80105d8a <release>

  }
8010579b:	e9 6a ff ff ff       	jmp    8010570a <scheduler+0x6>

801057a0 <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
801057a0:	55                   	push   %ebp
801057a1:	89 e5                	mov    %esp,%ebp
801057a3:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
801057a6:	c7 04 24 80 4f 19 80 	movl   $0x80194f80,(%esp)
801057ad:	e8 94 06 00 00       	call   80105e46 <holding>
801057b2:	85 c0                	test   %eax,%eax
801057b4:	75 0c                	jne    801057c2 <sched+0x22>
    panic("sched ptable.lock");
801057b6:	c7 04 24 f4 9c 10 80 	movl   $0x80109cf4,(%esp)
801057bd:	e8 7b ad ff ff       	call   8010053d <panic>
  if(cpu->ncli != 1)
801057c2:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801057c8:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
801057ce:	83 f8 01             	cmp    $0x1,%eax
801057d1:	74 0c                	je     801057df <sched+0x3f>
    panic("sched locks");
801057d3:	c7 04 24 06 9d 10 80 	movl   $0x80109d06,(%esp)
801057da:	e8 5e ad ff ff       	call   8010053d <panic>
  if(proc->state == RUNNING)
801057df:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801057e5:	8b 40 0c             	mov    0xc(%eax),%eax
801057e8:	83 f8 04             	cmp    $0x4,%eax
801057eb:	75 0c                	jne    801057f9 <sched+0x59>
    panic("sched running");
801057ed:	c7 04 24 12 9d 10 80 	movl   $0x80109d12,(%esp)
801057f4:	e8 44 ad ff ff       	call   8010053d <panic>
  if(readeflags()&FL_IF)
801057f9:	e8 0b f2 ff ff       	call   80104a09 <readeflags>
801057fe:	25 00 02 00 00       	and    $0x200,%eax
80105803:	85 c0                	test   %eax,%eax
80105805:	74 0c                	je     80105813 <sched+0x73>
    panic("sched interruptible");
80105807:	c7 04 24 20 9d 10 80 	movl   $0x80109d20,(%esp)
8010580e:	e8 2a ad ff ff       	call   8010053d <panic>
  intena = cpu->intena;
80105813:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105819:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
8010581f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->context, cpu->scheduler);
80105822:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105828:	8b 40 04             	mov    0x4(%eax),%eax
8010582b:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80105832:	83 c2 1c             	add    $0x1c,%edx
80105835:	89 44 24 04          	mov    %eax,0x4(%esp)
80105839:	89 14 24             	mov    %edx,(%esp)
8010583c:	e8 db 09 00 00       	call   8010621c <swtch>
  cpu->intena = intena;
80105841:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105847:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010584a:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80105850:	c9                   	leave  
80105851:	c3                   	ret    

80105852 <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
80105852:	55                   	push   %ebp
80105853:	89 e5                	mov    %esp,%ebp
80105855:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
80105858:	c7 04 24 80 4f 19 80 	movl   $0x80194f80,(%esp)
8010585f:	e8 8b 04 00 00       	call   80105cef <acquire>
  proc->state = RUNNABLE;
80105864:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010586a:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
80105871:	e8 2a ff ff ff       	call   801057a0 <sched>
  release(&ptable.lock);
80105876:	c7 04 24 80 4f 19 80 	movl   $0x80194f80,(%esp)
8010587d:	e8 08 05 00 00       	call   80105d8a <release>
}
80105882:	c9                   	leave  
80105883:	c3                   	ret    

80105884 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
80105884:	55                   	push   %ebp
80105885:	89 e5                	mov    %esp,%ebp
80105887:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
8010588a:	c7 04 24 80 4f 19 80 	movl   $0x80194f80,(%esp)
80105891:	e8 f4 04 00 00       	call   80105d8a <release>

  if (first) {
80105896:	a1 20 d0 10 80       	mov    0x8010d020,%eax
8010589b:	85 c0                	test   %eax,%eax
8010589d:	74 0f                	je     801058ae <forkret+0x2a>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
8010589f:	c7 05 20 d0 10 80 00 	movl   $0x0,0x8010d020
801058a6:	00 00 00 
    initlog();
801058a9:	e8 6e e1 ff ff       	call   80103a1c <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
801058ae:	c9                   	leave  
801058af:	c3                   	ret    

801058b0 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
801058b0:	55                   	push   %ebp
801058b1:	89 e5                	mov    %esp,%ebp
801058b3:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
801058b6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801058bc:	85 c0                	test   %eax,%eax
801058be:	75 0c                	jne    801058cc <sleep+0x1c>
    panic("sleep");
801058c0:	c7 04 24 34 9d 10 80 	movl   $0x80109d34,(%esp)
801058c7:	e8 71 ac ff ff       	call   8010053d <panic>

  if(lk == 0)
801058cc:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801058d0:	75 0c                	jne    801058de <sleep+0x2e>
    panic("sleep without lk");
801058d2:	c7 04 24 3a 9d 10 80 	movl   $0x80109d3a,(%esp)
801058d9:	e8 5f ac ff ff       	call   8010053d <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
801058de:	81 7d 0c 80 4f 19 80 	cmpl   $0x80194f80,0xc(%ebp)
801058e5:	74 17                	je     801058fe <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
801058e7:	c7 04 24 80 4f 19 80 	movl   $0x80194f80,(%esp)
801058ee:	e8 fc 03 00 00       	call   80105cef <acquire>
    release(lk);
801058f3:	8b 45 0c             	mov    0xc(%ebp),%eax
801058f6:	89 04 24             	mov    %eax,(%esp)
801058f9:	e8 8c 04 00 00       	call   80105d8a <release>
  }

  // Go to sleep.
  proc->chan = chan;
801058fe:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105904:	8b 55 08             	mov    0x8(%ebp),%edx
80105907:	89 50 20             	mov    %edx,0x20(%eax)
  proc->state = SLEEPING;
8010590a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105910:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)

  // Swap out
  if(swapFlag)
80105917:	a1 68 d6 10 80       	mov    0x8010d668,%eax
8010591c:	85 c0                	test   %eax,%eax
8010591e:	74 2b                	je     8010594b <sleep+0x9b>
  {
    if(proc->pid > 3)
80105920:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105926:	8b 40 10             	mov    0x10(%eax),%eax
80105929:	83 f8 03             	cmp    $0x3,%eax
8010592c:	7e 1d                	jle    8010594b <sleep+0x9b>
    {
      release(&ptable.lock);
8010592e:	c7 04 24 80 4f 19 80 	movl   $0x80194f80,(%esp)
80105935:	e8 50 04 00 00       	call   80105d8a <release>
      swapOut();
8010593a:	e8 ec f5 ff ff       	call   80104f2b <swapOut>
      acquire(&ptable.lock);
8010593f:	c7 04 24 80 4f 19 80 	movl   $0x80194f80,(%esp)
80105946:	e8 a4 03 00 00       	call   80105cef <acquire>
    }
  }
  
  sched();
8010594b:	e8 50 fe ff ff       	call   801057a0 <sched>
  
  // Tidy up.
  proc->chan = 0;
80105950:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105956:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
8010595d:	81 7d 0c 80 4f 19 80 	cmpl   $0x80194f80,0xc(%ebp)
80105964:	74 17                	je     8010597d <sleep+0xcd>
    release(&ptable.lock);
80105966:	c7 04 24 80 4f 19 80 	movl   $0x80194f80,(%esp)
8010596d:	e8 18 04 00 00       	call   80105d8a <release>
    acquire(lk);
80105972:	8b 45 0c             	mov    0xc(%ebp),%eax
80105975:	89 04 24             	mov    %eax,(%esp)
80105978:	e8 72 03 00 00       	call   80105cef <acquire>
  }
}
8010597d:	c9                   	leave  
8010597e:	c3                   	ret    

8010597f <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
8010597f:	55                   	push   %ebp
80105980:	89 e5                	mov    %esp,%ebp
80105982:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80105985:	c7 45 fc b4 4f 19 80 	movl   $0x80194fb4,-0x4(%ebp)
8010598c:	eb 53                	jmp    801059e1 <wakeup1+0x62>
  {
    if(p->state == SLEEPING && p->chan == chan)
8010598e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105991:	8b 40 0c             	mov    0xc(%eax),%eax
80105994:	83 f8 02             	cmp    $0x2,%eax
80105997:	75 15                	jne    801059ae <wakeup1+0x2f>
80105999:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010599c:	8b 40 20             	mov    0x20(%eax),%eax
8010599f:	3b 45 08             	cmp    0x8(%ebp),%eax
801059a2:	75 0a                	jne    801059ae <wakeup1+0x2f>
      p->state = RUNNABLE;
801059a4:	8b 45 fc             	mov    -0x4(%ebp),%eax
801059a7:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
    if(p->state == SLEEPING_SUSPENDED && p->chan == chan)
801059ae:	8b 45 fc             	mov    -0x4(%ebp),%eax
801059b1:	8b 40 0c             	mov    0xc(%eax),%eax
801059b4:	83 f8 06             	cmp    $0x6,%eax
801059b7:	75 21                	jne    801059da <wakeup1+0x5b>
801059b9:	8b 45 fc             	mov    -0x4(%ebp),%eax
801059bc:	8b 40 20             	mov    0x20(%eax),%eax
801059bf:	3b 45 08             	cmp    0x8(%ebp),%eax
801059c2:	75 16                	jne    801059da <wakeup1+0x5b>
    {
      p->state = RUNNABLE_SUSPENDED;
801059c4:	8b 45 fc             	mov    -0x4(%ebp),%eax
801059c7:	c7 40 0c 07 00 00 00 	movl   $0x7,0xc(%eax)
      inswapper->state = RUNNABLE;
801059ce:	a1 70 d6 10 80       	mov    0x8010d670,%eax
801059d3:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801059da:	81 45 fc 90 00 00 00 	addl   $0x90,-0x4(%ebp)
801059e1:	81 7d fc b4 73 19 80 	cmpl   $0x801973b4,-0x4(%ebp)
801059e8:	72 a4                	jb     8010598e <wakeup1+0xf>
    {
      p->state = RUNNABLE_SUSPENDED;
      inswapper->state = RUNNABLE;
    }
  }
}
801059ea:	c9                   	leave  
801059eb:	c3                   	ret    

801059ec <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
801059ec:	55                   	push   %ebp
801059ed:	89 e5                	mov    %esp,%ebp
801059ef:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);
801059f2:	c7 04 24 80 4f 19 80 	movl   $0x80194f80,(%esp)
801059f9:	e8 f1 02 00 00       	call   80105cef <acquire>
  wakeup1(chan);
801059fe:	8b 45 08             	mov    0x8(%ebp),%eax
80105a01:	89 04 24             	mov    %eax,(%esp)
80105a04:	e8 76 ff ff ff       	call   8010597f <wakeup1>
  release(&ptable.lock);
80105a09:	c7 04 24 80 4f 19 80 	movl   $0x80194f80,(%esp)
80105a10:	e8 75 03 00 00       	call   80105d8a <release>
}
80105a15:	c9                   	leave  
80105a16:	c3                   	ret    

80105a17 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80105a17:	55                   	push   %ebp
80105a18:	89 e5                	mov    %esp,%ebp
80105a1a:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  acquire(&ptable.lock);
80105a1d:	c7 04 24 80 4f 19 80 	movl   $0x80194f80,(%esp)
80105a24:	e8 c6 02 00 00       	call   80105cef <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105a29:	c7 45 f4 b4 4f 19 80 	movl   $0x80194fb4,-0xc(%ebp)
80105a30:	eb 67                	jmp    80105a99 <kill+0x82>
    if(p->pid == pid){
80105a32:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a35:	8b 40 10             	mov    0x10(%eax),%eax
80105a38:	3b 45 08             	cmp    0x8(%ebp),%eax
80105a3b:	75 55                	jne    80105a92 <kill+0x7b>
      p->killed = 1;
80105a3d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a40:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80105a47:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a4a:	8b 40 0c             	mov    0xc(%eax),%eax
80105a4d:	83 f8 02             	cmp    $0x2,%eax
80105a50:	75 0c                	jne    80105a5e <kill+0x47>
        p->state = RUNNABLE;
80105a52:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a55:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
80105a5c:	eb 21                	jmp    80105a7f <kill+0x68>
      else if(p->state == SLEEPING_SUSPENDED)
80105a5e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a61:	8b 40 0c             	mov    0xc(%eax),%eax
80105a64:	83 f8 06             	cmp    $0x6,%eax
80105a67:	75 16                	jne    80105a7f <kill+0x68>
      {
        p->state = RUNNABLE_SUSPENDED;
80105a69:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a6c:	c7 40 0c 07 00 00 00 	movl   $0x7,0xc(%eax)
	inswapper->state = RUNNABLE;
80105a73:	a1 70 d6 10 80       	mov    0x8010d670,%eax
80105a78:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      }
      release(&ptable.lock);
80105a7f:	c7 04 24 80 4f 19 80 	movl   $0x80194f80,(%esp)
80105a86:	e8 ff 02 00 00       	call   80105d8a <release>
      return 0;
80105a8b:	b8 00 00 00 00       	mov    $0x0,%eax
80105a90:	eb 21                	jmp    80105ab3 <kill+0x9c>
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105a92:	81 45 f4 90 00 00 00 	addl   $0x90,-0xc(%ebp)
80105a99:	81 7d f4 b4 73 19 80 	cmpl   $0x801973b4,-0xc(%ebp)
80105aa0:	72 90                	jb     80105a32 <kill+0x1b>
      }
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
80105aa2:	c7 04 24 80 4f 19 80 	movl   $0x80194f80,(%esp)
80105aa9:	e8 dc 02 00 00       	call   80105d8a <release>
  return -1;
80105aae:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105ab3:	c9                   	leave  
80105ab4:	c3                   	ret    

80105ab5 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80105ab5:	55                   	push   %ebp
80105ab6:	89 e5                	mov    %esp,%ebp
80105ab8:	83 ec 58             	sub    $0x58,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105abb:	c7 45 f0 b4 4f 19 80 	movl   $0x80194fb4,-0x10(%ebp)
80105ac2:	e9 db 00 00 00       	jmp    80105ba2 <procdump+0xed>
    if(p->state == UNUSED)
80105ac7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105aca:	8b 40 0c             	mov    0xc(%eax),%eax
80105acd:	85 c0                	test   %eax,%eax
80105acf:	0f 84 c5 00 00 00    	je     80105b9a <procdump+0xe5>
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80105ad5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ad8:	8b 40 0c             	mov    0xc(%eax),%eax
80105adb:	83 f8 05             	cmp    $0x5,%eax
80105ade:	77 23                	ja     80105b03 <procdump+0x4e>
80105ae0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ae3:	8b 40 0c             	mov    0xc(%eax),%eax
80105ae6:	8b 04 85 08 d0 10 80 	mov    -0x7fef2ff8(,%eax,4),%eax
80105aed:	85 c0                	test   %eax,%eax
80105aef:	74 12                	je     80105b03 <procdump+0x4e>
      state = states[p->state];
80105af1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105af4:	8b 40 0c             	mov    0xc(%eax),%eax
80105af7:	8b 04 85 08 d0 10 80 	mov    -0x7fef2ff8(,%eax,4),%eax
80105afe:	89 45 ec             	mov    %eax,-0x14(%ebp)
80105b01:	eb 07                	jmp    80105b0a <procdump+0x55>
    else
      state = "???";
80105b03:	c7 45 ec 4b 9d 10 80 	movl   $0x80109d4b,-0x14(%ebp)
    cprintf("%d %s %s", p->pid, state, p->name);
80105b0a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b0d:	8d 50 6c             	lea    0x6c(%eax),%edx
80105b10:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b13:	8b 40 10             	mov    0x10(%eax),%eax
80105b16:	89 54 24 0c          	mov    %edx,0xc(%esp)
80105b1a:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105b1d:	89 54 24 08          	mov    %edx,0x8(%esp)
80105b21:	89 44 24 04          	mov    %eax,0x4(%esp)
80105b25:	c7 04 24 4f 9d 10 80 	movl   $0x80109d4f,(%esp)
80105b2c:	e8 70 a8 ff ff       	call   801003a1 <cprintf>
    if(p->state == SLEEPING){
80105b31:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b34:	8b 40 0c             	mov    0xc(%eax),%eax
80105b37:	83 f8 02             	cmp    $0x2,%eax
80105b3a:	75 50                	jne    80105b8c <procdump+0xd7>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80105b3c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b3f:	8b 40 1c             	mov    0x1c(%eax),%eax
80105b42:	8b 40 0c             	mov    0xc(%eax),%eax
80105b45:	83 c0 08             	add    $0x8,%eax
80105b48:	8d 55 c4             	lea    -0x3c(%ebp),%edx
80105b4b:	89 54 24 04          	mov    %edx,0x4(%esp)
80105b4f:	89 04 24             	mov    %eax,(%esp)
80105b52:	e8 82 02 00 00       	call   80105dd9 <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80105b57:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80105b5e:	eb 1b                	jmp    80105b7b <procdump+0xc6>
        cprintf(" %p", pc[i]);
80105b60:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b63:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80105b67:	89 44 24 04          	mov    %eax,0x4(%esp)
80105b6b:	c7 04 24 58 9d 10 80 	movl   $0x80109d58,(%esp)
80105b72:	e8 2a a8 ff ff       	call   801003a1 <cprintf>
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
80105b77:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80105b7b:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
80105b7f:	7f 0b                	jg     80105b8c <procdump+0xd7>
80105b81:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b84:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80105b88:	85 c0                	test   %eax,%eax
80105b8a:	75 d4                	jne    80105b60 <procdump+0xab>
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80105b8c:	c7 04 24 5c 9d 10 80 	movl   $0x80109d5c,(%esp)
80105b93:	e8 09 a8 ff ff       	call   801003a1 <cprintf>
80105b98:	eb 01                	jmp    80105b9b <procdump+0xe6>
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
80105b9a:	90                   	nop
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105b9b:	81 45 f0 90 00 00 00 	addl   $0x90,-0x10(%ebp)
80105ba2:	81 7d f0 b4 73 19 80 	cmpl   $0x801973b4,-0x10(%ebp)
80105ba9:	0f 82 18 ff ff ff    	jb     80105ac7 <procdump+0x12>
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}
80105baf:	c9                   	leave  
80105bb0:	c3                   	ret    

80105bb1 <getAllocatedPages>:

int getAllocatedPages(int pid) {
80105bb1:	55                   	push   %ebp
80105bb2:	89 e5                	mov    %esp,%ebp
80105bb4:	83 ec 38             	sub    $0x38,%esp
  struct proc* p;
  acquire(&ptable.lock);
80105bb7:	c7 04 24 80 4f 19 80 	movl   $0x80194f80,(%esp)
80105bbe:	e8 2c 01 00 00       	call   80105cef <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105bc3:	c7 45 f4 b4 4f 19 80 	movl   $0x80194fb4,-0xc(%ebp)
80105bca:	eb 12                	jmp    80105bde <getAllocatedPages+0x2d>
    if(p->pid == pid){
80105bcc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105bcf:	8b 40 10             	mov    0x10(%eax),%eax
80105bd2:	3b 45 08             	cmp    0x8(%ebp),%eax
80105bd5:	74 12                	je     80105be9 <getAllocatedPages+0x38>
}

int getAllocatedPages(int pid) {
  struct proc* p;
  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105bd7:	81 45 f4 90 00 00 00 	addl   $0x90,-0xc(%ebp)
80105bde:	81 7d f4 b4 73 19 80 	cmpl   $0x801973b4,-0xc(%ebp)
80105be5:	72 e5                	jb     80105bcc <getAllocatedPages+0x1b>
80105be7:	eb 01                	jmp    80105bea <getAllocatedPages+0x39>
    if(p->pid == pid){
     break;
80105be9:	90                   	nop
    }
  }
  release(&ptable.lock);
80105bea:	c7 04 24 80 4f 19 80 	movl   $0x80194f80,(%esp)
80105bf1:	e8 94 01 00 00       	call   80105d8a <release>
   int count= 0, j, k;
80105bf6:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   for (j=0; j<1024; j++) {
80105bfd:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80105c04:	eb 71                	jmp    80105c77 <getAllocatedPages+0xc6>
      if(p->pgdir){ 
80105c06:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c09:	8b 40 04             	mov    0x4(%eax),%eax
80105c0c:	85 c0                	test   %eax,%eax
80105c0e:	74 63                	je     80105c73 <getAllocatedPages+0xc2>
	if (p->pgdir[j] & PTE_P) {
80105c10:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c13:	8b 40 04             	mov    0x4(%eax),%eax
80105c16:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105c19:	c1 e2 02             	shl    $0x2,%edx
80105c1c:	01 d0                	add    %edx,%eax
80105c1e:	8b 00                	mov    (%eax),%eax
80105c20:	83 e0 01             	and    $0x1,%eax
80105c23:	84 c0                	test   %al,%al
80105c25:	74 4c                	je     80105c73 <getAllocatedPages+0xc2>
	  pte_t* pte= (pte_t*)p2v(PTE_ADDR(p->pgdir[j]));
80105c27:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c2a:	8b 40 04             	mov    0x4(%eax),%eax
80105c2d:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105c30:	c1 e2 02             	shl    $0x2,%edx
80105c33:	01 d0                	add    %edx,%eax
80105c35:	8b 00                	mov    (%eax),%eax
80105c37:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80105c3c:	89 04 24             	mov    %eax,(%esp)
80105c3f:	e8 b8 ed ff ff       	call   801049fc <p2v>
80105c44:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	  for (k=0; k<1024; k++) {
80105c47:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
80105c4e:	eb 1a                	jmp    80105c6a <getAllocatedPages+0xb9>
	      if ( pte[k] & PTE_U )
80105c50:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105c53:	c1 e0 02             	shl    $0x2,%eax
80105c56:	03 45 e4             	add    -0x1c(%ebp),%eax
80105c59:	8b 00                	mov    (%eax),%eax
80105c5b:	83 e0 04             	and    $0x4,%eax
80105c5e:	85 c0                	test   %eax,%eax
80105c60:	74 04                	je     80105c66 <getAllocatedPages+0xb5>
		count++;
80105c62:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   int count= 0, j, k;
   for (j=0; j<1024; j++) {
      if(p->pgdir){ 
	if (p->pgdir[j] & PTE_P) {
	  pte_t* pte= (pte_t*)p2v(PTE_ADDR(p->pgdir[j]));
	  for (k=0; k<1024; k++) {
80105c66:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
80105c6a:	81 7d e8 ff 03 00 00 	cmpl   $0x3ff,-0x18(%ebp)
80105c71:	7e dd                	jle    80105c50 <getAllocatedPages+0x9f>
     break;
    }
  }
  release(&ptable.lock);
   int count= 0, j, k;
   for (j=0; j<1024; j++) {
80105c73:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
80105c77:	81 7d ec ff 03 00 00 	cmpl   $0x3ff,-0x14(%ebp)
80105c7e:	7e 86                	jle    80105c06 <getAllocatedPages+0x55>
		count++;
	  }
	}
      }
   }
   return count;
80105c80:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80105c83:	c9                   	leave  
80105c84:	c3                   	ret    
80105c85:	00 00                	add    %al,(%eax)
	...

80105c88 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80105c88:	55                   	push   %ebp
80105c89:	89 e5                	mov    %esp,%ebp
80105c8b:	53                   	push   %ebx
80105c8c:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80105c8f:	9c                   	pushf  
80105c90:	5b                   	pop    %ebx
80105c91:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80105c94:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80105c97:	83 c4 10             	add    $0x10,%esp
80105c9a:	5b                   	pop    %ebx
80105c9b:	5d                   	pop    %ebp
80105c9c:	c3                   	ret    

80105c9d <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
80105c9d:	55                   	push   %ebp
80105c9e:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
80105ca0:	fa                   	cli    
}
80105ca1:	5d                   	pop    %ebp
80105ca2:	c3                   	ret    

80105ca3 <sti>:

static inline void
sti(void)
{
80105ca3:	55                   	push   %ebp
80105ca4:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80105ca6:	fb                   	sti    
}
80105ca7:	5d                   	pop    %ebp
80105ca8:	c3                   	ret    

80105ca9 <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
80105ca9:	55                   	push   %ebp
80105caa:	89 e5                	mov    %esp,%ebp
80105cac:	53                   	push   %ebx
80105cad:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
80105cb0:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80105cb3:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
80105cb6:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80105cb9:	89 c3                	mov    %eax,%ebx
80105cbb:	89 d8                	mov    %ebx,%eax
80105cbd:	f0 87 02             	lock xchg %eax,(%edx)
80105cc0:	89 c3                	mov    %eax,%ebx
80105cc2:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80105cc5:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80105cc8:	83 c4 10             	add    $0x10,%esp
80105ccb:	5b                   	pop    %ebx
80105ccc:	5d                   	pop    %ebp
80105ccd:	c3                   	ret    

80105cce <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80105cce:	55                   	push   %ebp
80105ccf:	89 e5                	mov    %esp,%ebp
  lk->name = name;
80105cd1:	8b 45 08             	mov    0x8(%ebp),%eax
80105cd4:	8b 55 0c             	mov    0xc(%ebp),%edx
80105cd7:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80105cda:	8b 45 08             	mov    0x8(%ebp),%eax
80105cdd:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80105ce3:	8b 45 08             	mov    0x8(%ebp),%eax
80105ce6:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80105ced:	5d                   	pop    %ebp
80105cee:	c3                   	ret    

80105cef <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
80105cef:	55                   	push   %ebp
80105cf0:	89 e5                	mov    %esp,%ebp
80105cf2:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80105cf5:	e8 76 01 00 00       	call   80105e70 <pushcli>
  if(holding(lk))
80105cfa:	8b 45 08             	mov    0x8(%ebp),%eax
80105cfd:	89 04 24             	mov    %eax,(%esp)
80105d00:	e8 41 01 00 00       	call   80105e46 <holding>
80105d05:	85 c0                	test   %eax,%eax
80105d07:	74 45                	je     80105d4e <acquire+0x5f>
  {
    cprintf("lock = %s\n",lk->name);
80105d09:	8b 45 08             	mov    0x8(%ebp),%eax
80105d0c:	8b 40 04             	mov    0x4(%eax),%eax
80105d0f:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d13:	c7 04 24 88 9d 10 80 	movl   $0x80109d88,(%esp)
80105d1a:	e8 82 a6 ff ff       	call   801003a1 <cprintf>
    if(proc)
80105d1f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105d25:	85 c0                	test   %eax,%eax
80105d27:	74 19                	je     80105d42 <acquire+0x53>
      cprintf("pid = %d\n",proc->pid);
80105d29:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105d2f:	8b 40 10             	mov    0x10(%eax),%eax
80105d32:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d36:	c7 04 24 93 9d 10 80 	movl   $0x80109d93,(%esp)
80105d3d:	e8 5f a6 ff ff       	call   801003a1 <cprintf>
    panic("acquire");
80105d42:	c7 04 24 9d 9d 10 80 	movl   $0x80109d9d,(%esp)
80105d49:	e8 ef a7 ff ff       	call   8010053d <panic>
  }

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
80105d4e:	90                   	nop
80105d4f:	8b 45 08             	mov    0x8(%ebp),%eax
80105d52:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80105d59:	00 
80105d5a:	89 04 24             	mov    %eax,(%esp)
80105d5d:	e8 47 ff ff ff       	call   80105ca9 <xchg>
80105d62:	85 c0                	test   %eax,%eax
80105d64:	75 e9                	jne    80105d4f <acquire+0x60>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
80105d66:	8b 45 08             	mov    0x8(%ebp),%eax
80105d69:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80105d70:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
80105d73:	8b 45 08             	mov    0x8(%ebp),%eax
80105d76:	83 c0 0c             	add    $0xc,%eax
80105d79:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d7d:	8d 45 08             	lea    0x8(%ebp),%eax
80105d80:	89 04 24             	mov    %eax,(%esp)
80105d83:	e8 51 00 00 00       	call   80105dd9 <getcallerpcs>
}
80105d88:	c9                   	leave  
80105d89:	c3                   	ret    

80105d8a <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
80105d8a:	55                   	push   %ebp
80105d8b:	89 e5                	mov    %esp,%ebp
80105d8d:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
80105d90:	8b 45 08             	mov    0x8(%ebp),%eax
80105d93:	89 04 24             	mov    %eax,(%esp)
80105d96:	e8 ab 00 00 00       	call   80105e46 <holding>
80105d9b:	85 c0                	test   %eax,%eax
80105d9d:	75 0c                	jne    80105dab <release+0x21>
    panic("release");
80105d9f:	c7 04 24 a5 9d 10 80 	movl   $0x80109da5,(%esp)
80105da6:	e8 92 a7 ff ff       	call   8010053d <panic>

  lk->pcs[0] = 0;
80105dab:	8b 45 08             	mov    0x8(%ebp),%eax
80105dae:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
80105db5:	8b 45 08             	mov    0x8(%ebp),%eax
80105db8:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
80105dbf:	8b 45 08             	mov    0x8(%ebp),%eax
80105dc2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105dc9:	00 
80105dca:	89 04 24             	mov    %eax,(%esp)
80105dcd:	e8 d7 fe ff ff       	call   80105ca9 <xchg>

  popcli();
80105dd2:	e8 e1 00 00 00       	call   80105eb8 <popcli>
}
80105dd7:	c9                   	leave  
80105dd8:	c3                   	ret    

80105dd9 <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80105dd9:	55                   	push   %ebp
80105dda:	89 e5                	mov    %esp,%ebp
80105ddc:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
80105ddf:	8b 45 08             	mov    0x8(%ebp),%eax
80105de2:	83 e8 08             	sub    $0x8,%eax
80105de5:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
80105de8:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
80105def:	eb 32                	jmp    80105e23 <getcallerpcs+0x4a>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80105df1:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
80105df5:	74 47                	je     80105e3e <getcallerpcs+0x65>
80105df7:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
80105dfe:	76 3e                	jbe    80105e3e <getcallerpcs+0x65>
80105e00:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
80105e04:	74 38                	je     80105e3e <getcallerpcs+0x65>
      break;
    pcs[i] = ebp[1];     // saved %eip
80105e06:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105e09:	c1 e0 02             	shl    $0x2,%eax
80105e0c:	03 45 0c             	add    0xc(%ebp),%eax
80105e0f:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105e12:	8b 52 04             	mov    0x4(%edx),%edx
80105e15:	89 10                	mov    %edx,(%eax)
    ebp = (uint*)ebp[0]; // saved %ebp
80105e17:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105e1a:	8b 00                	mov    (%eax),%eax
80105e1c:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
80105e1f:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105e23:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105e27:	7e c8                	jle    80105df1 <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105e29:	eb 13                	jmp    80105e3e <getcallerpcs+0x65>
    pcs[i] = 0;
80105e2b:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105e2e:	c1 e0 02             	shl    $0x2,%eax
80105e31:	03 45 0c             	add    0xc(%ebp),%eax
80105e34:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105e3a:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105e3e:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105e42:	7e e7                	jle    80105e2b <getcallerpcs+0x52>
    pcs[i] = 0;
}
80105e44:	c9                   	leave  
80105e45:	c3                   	ret    

80105e46 <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
80105e46:	55                   	push   %ebp
80105e47:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
80105e49:	8b 45 08             	mov    0x8(%ebp),%eax
80105e4c:	8b 00                	mov    (%eax),%eax
80105e4e:	85 c0                	test   %eax,%eax
80105e50:	74 17                	je     80105e69 <holding+0x23>
80105e52:	8b 45 08             	mov    0x8(%ebp),%eax
80105e55:	8b 50 08             	mov    0x8(%eax),%edx
80105e58:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105e5e:	39 c2                	cmp    %eax,%edx
80105e60:	75 07                	jne    80105e69 <holding+0x23>
80105e62:	b8 01 00 00 00       	mov    $0x1,%eax
80105e67:	eb 05                	jmp    80105e6e <holding+0x28>
80105e69:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105e6e:	5d                   	pop    %ebp
80105e6f:	c3                   	ret    

80105e70 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80105e70:	55                   	push   %ebp
80105e71:	89 e5                	mov    %esp,%ebp
80105e73:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
80105e76:	e8 0d fe ff ff       	call   80105c88 <readeflags>
80105e7b:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
80105e7e:	e8 1a fe ff ff       	call   80105c9d <cli>
  if(cpu->ncli++ == 0)
80105e83:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105e89:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80105e8f:	85 d2                	test   %edx,%edx
80105e91:	0f 94 c1             	sete   %cl
80105e94:	83 c2 01             	add    $0x1,%edx
80105e97:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80105e9d:	84 c9                	test   %cl,%cl
80105e9f:	74 15                	je     80105eb6 <pushcli+0x46>
    cpu->intena = eflags & FL_IF;
80105ea1:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105ea7:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105eaa:	81 e2 00 02 00 00    	and    $0x200,%edx
80105eb0:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80105eb6:	c9                   	leave  
80105eb7:	c3                   	ret    

80105eb8 <popcli>:

void
popcli(void)
{
80105eb8:	55                   	push   %ebp
80105eb9:	89 e5                	mov    %esp,%ebp
80105ebb:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
80105ebe:	e8 c5 fd ff ff       	call   80105c88 <readeflags>
80105ec3:	25 00 02 00 00       	and    $0x200,%eax
80105ec8:	85 c0                	test   %eax,%eax
80105eca:	74 0c                	je     80105ed8 <popcli+0x20>
    panic("popcli - interruptible");
80105ecc:	c7 04 24 ad 9d 10 80 	movl   $0x80109dad,(%esp)
80105ed3:	e8 65 a6 ff ff       	call   8010053d <panic>
  if(--cpu->ncli < 0)
80105ed8:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105ede:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80105ee4:	83 ea 01             	sub    $0x1,%edx
80105ee7:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80105eed:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105ef3:	85 c0                	test   %eax,%eax
80105ef5:	79 0c                	jns    80105f03 <popcli+0x4b>
    panic("popcli");
80105ef7:	c7 04 24 c4 9d 10 80 	movl   $0x80109dc4,(%esp)
80105efe:	e8 3a a6 ff ff       	call   8010053d <panic>
  if(cpu->ncli == 0 && cpu->intena)
80105f03:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105f09:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105f0f:	85 c0                	test   %eax,%eax
80105f11:	75 15                	jne    80105f28 <popcli+0x70>
80105f13:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105f19:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80105f1f:	85 c0                	test   %eax,%eax
80105f21:	74 05                	je     80105f28 <popcli+0x70>
    sti();
80105f23:	e8 7b fd ff ff       	call   80105ca3 <sti>
}
80105f28:	c9                   	leave  
80105f29:	c3                   	ret    
	...

80105f2c <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
80105f2c:	55                   	push   %ebp
80105f2d:	89 e5                	mov    %esp,%ebp
80105f2f:	57                   	push   %edi
80105f30:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
80105f31:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105f34:	8b 55 10             	mov    0x10(%ebp),%edx
80105f37:	8b 45 0c             	mov    0xc(%ebp),%eax
80105f3a:	89 cb                	mov    %ecx,%ebx
80105f3c:	89 df                	mov    %ebx,%edi
80105f3e:	89 d1                	mov    %edx,%ecx
80105f40:	fc                   	cld    
80105f41:	f3 aa                	rep stos %al,%es:(%edi)
80105f43:	89 ca                	mov    %ecx,%edx
80105f45:	89 fb                	mov    %edi,%ebx
80105f47:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105f4a:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105f4d:	5b                   	pop    %ebx
80105f4e:	5f                   	pop    %edi
80105f4f:	5d                   	pop    %ebp
80105f50:	c3                   	ret    

80105f51 <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
80105f51:	55                   	push   %ebp
80105f52:	89 e5                	mov    %esp,%ebp
80105f54:	57                   	push   %edi
80105f55:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
80105f56:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105f59:	8b 55 10             	mov    0x10(%ebp),%edx
80105f5c:	8b 45 0c             	mov    0xc(%ebp),%eax
80105f5f:	89 cb                	mov    %ecx,%ebx
80105f61:	89 df                	mov    %ebx,%edi
80105f63:	89 d1                	mov    %edx,%ecx
80105f65:	fc                   	cld    
80105f66:	f3 ab                	rep stos %eax,%es:(%edi)
80105f68:	89 ca                	mov    %ecx,%edx
80105f6a:	89 fb                	mov    %edi,%ebx
80105f6c:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105f6f:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105f72:	5b                   	pop    %ebx
80105f73:	5f                   	pop    %edi
80105f74:	5d                   	pop    %ebp
80105f75:	c3                   	ret    

80105f76 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80105f76:	55                   	push   %ebp
80105f77:	89 e5                	mov    %esp,%ebp
80105f79:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
80105f7c:	8b 45 08             	mov    0x8(%ebp),%eax
80105f7f:	83 e0 03             	and    $0x3,%eax
80105f82:	85 c0                	test   %eax,%eax
80105f84:	75 49                	jne    80105fcf <memset+0x59>
80105f86:	8b 45 10             	mov    0x10(%ebp),%eax
80105f89:	83 e0 03             	and    $0x3,%eax
80105f8c:	85 c0                	test   %eax,%eax
80105f8e:	75 3f                	jne    80105fcf <memset+0x59>
    c &= 0xFF;
80105f90:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80105f97:	8b 45 10             	mov    0x10(%ebp),%eax
80105f9a:	c1 e8 02             	shr    $0x2,%eax
80105f9d:	89 c2                	mov    %eax,%edx
80105f9f:	8b 45 0c             	mov    0xc(%ebp),%eax
80105fa2:	89 c1                	mov    %eax,%ecx
80105fa4:	c1 e1 18             	shl    $0x18,%ecx
80105fa7:	8b 45 0c             	mov    0xc(%ebp),%eax
80105faa:	c1 e0 10             	shl    $0x10,%eax
80105fad:	09 c1                	or     %eax,%ecx
80105faf:	8b 45 0c             	mov    0xc(%ebp),%eax
80105fb2:	c1 e0 08             	shl    $0x8,%eax
80105fb5:	09 c8                	or     %ecx,%eax
80105fb7:	0b 45 0c             	or     0xc(%ebp),%eax
80105fba:	89 54 24 08          	mov    %edx,0x8(%esp)
80105fbe:	89 44 24 04          	mov    %eax,0x4(%esp)
80105fc2:	8b 45 08             	mov    0x8(%ebp),%eax
80105fc5:	89 04 24             	mov    %eax,(%esp)
80105fc8:	e8 84 ff ff ff       	call   80105f51 <stosl>
80105fcd:	eb 19                	jmp    80105fe8 <memset+0x72>
  } else
    stosb(dst, c, n);
80105fcf:	8b 45 10             	mov    0x10(%ebp),%eax
80105fd2:	89 44 24 08          	mov    %eax,0x8(%esp)
80105fd6:	8b 45 0c             	mov    0xc(%ebp),%eax
80105fd9:	89 44 24 04          	mov    %eax,0x4(%esp)
80105fdd:	8b 45 08             	mov    0x8(%ebp),%eax
80105fe0:	89 04 24             	mov    %eax,(%esp)
80105fe3:	e8 44 ff ff ff       	call   80105f2c <stosb>
  return dst;
80105fe8:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105feb:	c9                   	leave  
80105fec:	c3                   	ret    

80105fed <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80105fed:	55                   	push   %ebp
80105fee:	89 e5                	mov    %esp,%ebp
80105ff0:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
80105ff3:	8b 45 08             	mov    0x8(%ebp),%eax
80105ff6:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
80105ff9:	8b 45 0c             	mov    0xc(%ebp),%eax
80105ffc:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
80105fff:	eb 32                	jmp    80106033 <memcmp+0x46>
    if(*s1 != *s2)
80106001:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106004:	0f b6 10             	movzbl (%eax),%edx
80106007:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010600a:	0f b6 00             	movzbl (%eax),%eax
8010600d:	38 c2                	cmp    %al,%dl
8010600f:	74 1a                	je     8010602b <memcmp+0x3e>
      return *s1 - *s2;
80106011:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106014:	0f b6 00             	movzbl (%eax),%eax
80106017:	0f b6 d0             	movzbl %al,%edx
8010601a:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010601d:	0f b6 00             	movzbl (%eax),%eax
80106020:	0f b6 c0             	movzbl %al,%eax
80106023:	89 d1                	mov    %edx,%ecx
80106025:	29 c1                	sub    %eax,%ecx
80106027:	89 c8                	mov    %ecx,%eax
80106029:	eb 1c                	jmp    80106047 <memcmp+0x5a>
    s1++, s2++;
8010602b:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010602f:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80106033:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80106037:	0f 95 c0             	setne  %al
8010603a:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
8010603e:	84 c0                	test   %al,%al
80106040:	75 bf                	jne    80106001 <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
80106042:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106047:	c9                   	leave  
80106048:	c3                   	ret    

80106049 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80106049:	55                   	push   %ebp
8010604a:	89 e5                	mov    %esp,%ebp
8010604c:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
8010604f:	8b 45 0c             	mov    0xc(%ebp),%eax
80106052:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
80106055:	8b 45 08             	mov    0x8(%ebp),%eax
80106058:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
8010605b:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010605e:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80106061:	73 54                	jae    801060b7 <memmove+0x6e>
80106063:	8b 45 10             	mov    0x10(%ebp),%eax
80106066:	8b 55 fc             	mov    -0x4(%ebp),%edx
80106069:	01 d0                	add    %edx,%eax
8010606b:	3b 45 f8             	cmp    -0x8(%ebp),%eax
8010606e:	76 47                	jbe    801060b7 <memmove+0x6e>
    s += n;
80106070:	8b 45 10             	mov    0x10(%ebp),%eax
80106073:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
80106076:	8b 45 10             	mov    0x10(%ebp),%eax
80106079:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
8010607c:	eb 13                	jmp    80106091 <memmove+0x48>
      *--d = *--s;
8010607e:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
80106082:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
80106086:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106089:	0f b6 10             	movzbl (%eax),%edx
8010608c:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010608f:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
80106091:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80106095:	0f 95 c0             	setne  %al
80106098:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
8010609c:	84 c0                	test   %al,%al
8010609e:	75 de                	jne    8010607e <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
801060a0:	eb 25                	jmp    801060c7 <memmove+0x7e>
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
      *d++ = *s++;
801060a2:	8b 45 fc             	mov    -0x4(%ebp),%eax
801060a5:	0f b6 10             	movzbl (%eax),%edx
801060a8:	8b 45 f8             	mov    -0x8(%ebp),%eax
801060ab:	88 10                	mov    %dl,(%eax)
801060ad:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
801060b1:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801060b5:	eb 01                	jmp    801060b8 <memmove+0x6f>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
801060b7:	90                   	nop
801060b8:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801060bc:	0f 95 c0             	setne  %al
801060bf:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801060c3:	84 c0                	test   %al,%al
801060c5:	75 db                	jne    801060a2 <memmove+0x59>
      *d++ = *s++;

  return dst;
801060c7:	8b 45 08             	mov    0x8(%ebp),%eax
}
801060ca:	c9                   	leave  
801060cb:	c3                   	ret    

801060cc <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
801060cc:	55                   	push   %ebp
801060cd:	89 e5                	mov    %esp,%ebp
801060cf:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
801060d2:	8b 45 10             	mov    0x10(%ebp),%eax
801060d5:	89 44 24 08          	mov    %eax,0x8(%esp)
801060d9:	8b 45 0c             	mov    0xc(%ebp),%eax
801060dc:	89 44 24 04          	mov    %eax,0x4(%esp)
801060e0:	8b 45 08             	mov    0x8(%ebp),%eax
801060e3:	89 04 24             	mov    %eax,(%esp)
801060e6:	e8 5e ff ff ff       	call   80106049 <memmove>
}
801060eb:	c9                   	leave  
801060ec:	c3                   	ret    

801060ed <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
801060ed:	55                   	push   %ebp
801060ee:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
801060f0:	eb 0c                	jmp    801060fe <strncmp+0x11>
    n--, p++, q++;
801060f2:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801060f6:	83 45 08 01          	addl   $0x1,0x8(%ebp)
801060fa:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
801060fe:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80106102:	74 1a                	je     8010611e <strncmp+0x31>
80106104:	8b 45 08             	mov    0x8(%ebp),%eax
80106107:	0f b6 00             	movzbl (%eax),%eax
8010610a:	84 c0                	test   %al,%al
8010610c:	74 10                	je     8010611e <strncmp+0x31>
8010610e:	8b 45 08             	mov    0x8(%ebp),%eax
80106111:	0f b6 10             	movzbl (%eax),%edx
80106114:	8b 45 0c             	mov    0xc(%ebp),%eax
80106117:	0f b6 00             	movzbl (%eax),%eax
8010611a:	38 c2                	cmp    %al,%dl
8010611c:	74 d4                	je     801060f2 <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
8010611e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80106122:	75 07                	jne    8010612b <strncmp+0x3e>
    return 0;
80106124:	b8 00 00 00 00       	mov    $0x0,%eax
80106129:	eb 18                	jmp    80106143 <strncmp+0x56>
  return (uchar)*p - (uchar)*q;
8010612b:	8b 45 08             	mov    0x8(%ebp),%eax
8010612e:	0f b6 00             	movzbl (%eax),%eax
80106131:	0f b6 d0             	movzbl %al,%edx
80106134:	8b 45 0c             	mov    0xc(%ebp),%eax
80106137:	0f b6 00             	movzbl (%eax),%eax
8010613a:	0f b6 c0             	movzbl %al,%eax
8010613d:	89 d1                	mov    %edx,%ecx
8010613f:	29 c1                	sub    %eax,%ecx
80106141:	89 c8                	mov    %ecx,%eax
}
80106143:	5d                   	pop    %ebp
80106144:	c3                   	ret    

80106145 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80106145:	55                   	push   %ebp
80106146:	89 e5                	mov    %esp,%ebp
80106148:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
8010614b:	8b 45 08             	mov    0x8(%ebp),%eax
8010614e:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
80106151:	90                   	nop
80106152:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80106156:	0f 9f c0             	setg   %al
80106159:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
8010615d:	84 c0                	test   %al,%al
8010615f:	74 30                	je     80106191 <strncpy+0x4c>
80106161:	8b 45 0c             	mov    0xc(%ebp),%eax
80106164:	0f b6 10             	movzbl (%eax),%edx
80106167:	8b 45 08             	mov    0x8(%ebp),%eax
8010616a:	88 10                	mov    %dl,(%eax)
8010616c:	8b 45 08             	mov    0x8(%ebp),%eax
8010616f:	0f b6 00             	movzbl (%eax),%eax
80106172:	84 c0                	test   %al,%al
80106174:	0f 95 c0             	setne  %al
80106177:	83 45 08 01          	addl   $0x1,0x8(%ebp)
8010617b:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
8010617f:	84 c0                	test   %al,%al
80106181:	75 cf                	jne    80106152 <strncpy+0xd>
    ;
  while(n-- > 0)
80106183:	eb 0c                	jmp    80106191 <strncpy+0x4c>
    *s++ = 0;
80106185:	8b 45 08             	mov    0x8(%ebp),%eax
80106188:	c6 00 00             	movb   $0x0,(%eax)
8010618b:	83 45 08 01          	addl   $0x1,0x8(%ebp)
8010618f:	eb 01                	jmp    80106192 <strncpy+0x4d>
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
80106191:	90                   	nop
80106192:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80106196:	0f 9f c0             	setg   %al
80106199:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
8010619d:	84 c0                	test   %al,%al
8010619f:	75 e4                	jne    80106185 <strncpy+0x40>
    *s++ = 0;
  return os;
801061a1:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801061a4:	c9                   	leave  
801061a5:	c3                   	ret    

801061a6 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
801061a6:	55                   	push   %ebp
801061a7:	89 e5                	mov    %esp,%ebp
801061a9:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
801061ac:	8b 45 08             	mov    0x8(%ebp),%eax
801061af:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
801061b2:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801061b6:	7f 05                	jg     801061bd <safestrcpy+0x17>
    return os;
801061b8:	8b 45 fc             	mov    -0x4(%ebp),%eax
801061bb:	eb 35                	jmp    801061f2 <safestrcpy+0x4c>
  while(--n > 0 && (*s++ = *t++) != 0)
801061bd:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801061c1:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801061c5:	7e 22                	jle    801061e9 <safestrcpy+0x43>
801061c7:	8b 45 0c             	mov    0xc(%ebp),%eax
801061ca:	0f b6 10             	movzbl (%eax),%edx
801061cd:	8b 45 08             	mov    0x8(%ebp),%eax
801061d0:	88 10                	mov    %dl,(%eax)
801061d2:	8b 45 08             	mov    0x8(%ebp),%eax
801061d5:	0f b6 00             	movzbl (%eax),%eax
801061d8:	84 c0                	test   %al,%al
801061da:	0f 95 c0             	setne  %al
801061dd:	83 45 08 01          	addl   $0x1,0x8(%ebp)
801061e1:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
801061e5:	84 c0                	test   %al,%al
801061e7:	75 d4                	jne    801061bd <safestrcpy+0x17>
    ;
  *s = 0;
801061e9:	8b 45 08             	mov    0x8(%ebp),%eax
801061ec:	c6 00 00             	movb   $0x0,(%eax)
  return os;
801061ef:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801061f2:	c9                   	leave  
801061f3:	c3                   	ret    

801061f4 <strlen>:

int
strlen(const char *s)
{
801061f4:	55                   	push   %ebp
801061f5:	89 e5                	mov    %esp,%ebp
801061f7:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
801061fa:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80106201:	eb 04                	jmp    80106207 <strlen+0x13>
80106203:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80106207:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010620a:	03 45 08             	add    0x8(%ebp),%eax
8010620d:	0f b6 00             	movzbl (%eax),%eax
80106210:	84 c0                	test   %al,%al
80106212:	75 ef                	jne    80106203 <strlen+0xf>
    ;
  return n;
80106214:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80106217:	c9                   	leave  
80106218:	c3                   	ret    
80106219:	00 00                	add    %al,(%eax)
	...

8010621c <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
8010621c:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80106220:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
80106224:	55                   	push   %ebp
  pushl %ebx
80106225:	53                   	push   %ebx
  pushl %esi
80106226:	56                   	push   %esi
  pushl %edi
80106227:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80106228:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
8010622a:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
8010622c:	5f                   	pop    %edi
  popl %esi
8010622d:	5e                   	pop    %esi
  popl %ebx
8010622e:	5b                   	pop    %ebx
  popl %ebp
8010622f:	5d                   	pop    %ebp
  ret
80106230:	c3                   	ret    
80106231:	00 00                	add    %al,(%eax)
	...

80106234 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from process p.
int
fetchint(struct proc *p, uint addr, int *ip)
{
80106234:	55                   	push   %ebp
80106235:	89 e5                	mov    %esp,%ebp
  if(addr >= p->sz || addr+4 > p->sz)
80106237:	8b 45 08             	mov    0x8(%ebp),%eax
8010623a:	8b 00                	mov    (%eax),%eax
8010623c:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010623f:	76 0f                	jbe    80106250 <fetchint+0x1c>
80106241:	8b 45 0c             	mov    0xc(%ebp),%eax
80106244:	8d 50 04             	lea    0x4(%eax),%edx
80106247:	8b 45 08             	mov    0x8(%ebp),%eax
8010624a:	8b 00                	mov    (%eax),%eax
8010624c:	39 c2                	cmp    %eax,%edx
8010624e:	76 07                	jbe    80106257 <fetchint+0x23>
    return -1;
80106250:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106255:	eb 0f                	jmp    80106266 <fetchint+0x32>
  *ip = *(int*)(addr);
80106257:	8b 45 0c             	mov    0xc(%ebp),%eax
8010625a:	8b 10                	mov    (%eax),%edx
8010625c:	8b 45 10             	mov    0x10(%ebp),%eax
8010625f:	89 10                	mov    %edx,(%eax)
  return 0;
80106261:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106266:	5d                   	pop    %ebp
80106267:	c3                   	ret    

80106268 <fetchstr>:
// Fetch the nul-terminated string at addr from process p.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(struct proc *p, uint addr, char **pp)
{
80106268:	55                   	push   %ebp
80106269:	89 e5                	mov    %esp,%ebp
8010626b:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= p->sz)
8010626e:	8b 45 08             	mov    0x8(%ebp),%eax
80106271:	8b 00                	mov    (%eax),%eax
80106273:	3b 45 0c             	cmp    0xc(%ebp),%eax
80106276:	77 07                	ja     8010627f <fetchstr+0x17>
    return -1;
80106278:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010627d:	eb 45                	jmp    801062c4 <fetchstr+0x5c>
  *pp = (char*)addr;
8010627f:	8b 55 0c             	mov    0xc(%ebp),%edx
80106282:	8b 45 10             	mov    0x10(%ebp),%eax
80106285:	89 10                	mov    %edx,(%eax)
  ep = (char*)p->sz;
80106287:	8b 45 08             	mov    0x8(%ebp),%eax
8010628a:	8b 00                	mov    (%eax),%eax
8010628c:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
8010628f:	8b 45 10             	mov    0x10(%ebp),%eax
80106292:	8b 00                	mov    (%eax),%eax
80106294:	89 45 fc             	mov    %eax,-0x4(%ebp)
80106297:	eb 1e                	jmp    801062b7 <fetchstr+0x4f>
    if(*s == 0)
80106299:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010629c:	0f b6 00             	movzbl (%eax),%eax
8010629f:	84 c0                	test   %al,%al
801062a1:	75 10                	jne    801062b3 <fetchstr+0x4b>
      return s - *pp;
801062a3:	8b 55 fc             	mov    -0x4(%ebp),%edx
801062a6:	8b 45 10             	mov    0x10(%ebp),%eax
801062a9:	8b 00                	mov    (%eax),%eax
801062ab:	89 d1                	mov    %edx,%ecx
801062ad:	29 c1                	sub    %eax,%ecx
801062af:	89 c8                	mov    %ecx,%eax
801062b1:	eb 11                	jmp    801062c4 <fetchstr+0x5c>

  if(addr >= p->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)p->sz;
  for(s = *pp; s < ep; s++)
801062b3:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801062b7:	8b 45 fc             	mov    -0x4(%ebp),%eax
801062ba:	3b 45 f8             	cmp    -0x8(%ebp),%eax
801062bd:	72 da                	jb     80106299 <fetchstr+0x31>
    if(*s == 0)
      return s - *pp;
  return -1;
801062bf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801062c4:	c9                   	leave  
801062c5:	c3                   	ret    

801062c6 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
801062c6:	55                   	push   %ebp
801062c7:	89 e5                	mov    %esp,%ebp
801062c9:	83 ec 0c             	sub    $0xc,%esp
  return fetchint(proc, proc->tf->esp + 4 + 4*n, ip);
801062cc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801062d2:	8b 40 18             	mov    0x18(%eax),%eax
801062d5:	8b 50 44             	mov    0x44(%eax),%edx
801062d8:	8b 45 08             	mov    0x8(%ebp),%eax
801062db:	c1 e0 02             	shl    $0x2,%eax
801062de:	01 d0                	add    %edx,%eax
801062e0:	8d 48 04             	lea    0x4(%eax),%ecx
801062e3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801062e9:	8b 55 0c             	mov    0xc(%ebp),%edx
801062ec:	89 54 24 08          	mov    %edx,0x8(%esp)
801062f0:	89 4c 24 04          	mov    %ecx,0x4(%esp)
801062f4:	89 04 24             	mov    %eax,(%esp)
801062f7:	e8 38 ff ff ff       	call   80106234 <fetchint>
}
801062fc:	c9                   	leave  
801062fd:	c3                   	ret    

801062fe <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
801062fe:	55                   	push   %ebp
801062ff:	89 e5                	mov    %esp,%ebp
80106301:	83 ec 18             	sub    $0x18,%esp
  int i;

  if(argint(n, &i) < 0)
80106304:	8d 45 fc             	lea    -0x4(%ebp),%eax
80106307:	89 44 24 04          	mov    %eax,0x4(%esp)
8010630b:	8b 45 08             	mov    0x8(%ebp),%eax
8010630e:	89 04 24             	mov    %eax,(%esp)
80106311:	e8 b0 ff ff ff       	call   801062c6 <argint>
80106316:	85 c0                	test   %eax,%eax
80106318:	79 07                	jns    80106321 <argptr+0x23>
    return -1;
8010631a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010631f:	eb 3d                	jmp    8010635e <argptr+0x60>

  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
80106321:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106324:	89 c2                	mov    %eax,%edx
80106326:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010632c:	8b 00                	mov    (%eax),%eax
8010632e:	39 c2                	cmp    %eax,%edx
80106330:	73 16                	jae    80106348 <argptr+0x4a>
80106332:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106335:	89 c2                	mov    %eax,%edx
80106337:	8b 45 10             	mov    0x10(%ebp),%eax
8010633a:	01 c2                	add    %eax,%edx
8010633c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106342:	8b 00                	mov    (%eax),%eax
80106344:	39 c2                	cmp    %eax,%edx
80106346:	76 07                	jbe    8010634f <argptr+0x51>
    return -1;
80106348:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010634d:	eb 0f                	jmp    8010635e <argptr+0x60>
  *pp = (char*)i;
8010634f:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106352:	89 c2                	mov    %eax,%edx
80106354:	8b 45 0c             	mov    0xc(%ebp),%eax
80106357:	89 10                	mov    %edx,(%eax)
  return 0;
80106359:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010635e:	c9                   	leave  
8010635f:	c3                   	ret    

80106360 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80106360:	55                   	push   %ebp
80106361:	89 e5                	mov    %esp,%ebp
80106363:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  if(argint(n, &addr) < 0)
80106366:	8d 45 fc             	lea    -0x4(%ebp),%eax
80106369:	89 44 24 04          	mov    %eax,0x4(%esp)
8010636d:	8b 45 08             	mov    0x8(%ebp),%eax
80106370:	89 04 24             	mov    %eax,(%esp)
80106373:	e8 4e ff ff ff       	call   801062c6 <argint>
80106378:	85 c0                	test   %eax,%eax
8010637a:	79 07                	jns    80106383 <argstr+0x23>
    return -1;
8010637c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106381:	eb 1e                	jmp    801063a1 <argstr+0x41>
  return fetchstr(proc, addr, pp);
80106383:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106386:	89 c2                	mov    %eax,%edx
80106388:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010638e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80106391:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106395:	89 54 24 04          	mov    %edx,0x4(%esp)
80106399:	89 04 24             	mov    %eax,(%esp)
8010639c:	e8 c7 fe ff ff       	call   80106268 <fetchstr>
}
801063a1:	c9                   	leave  
801063a2:	c3                   	ret    

801063a3 <syscall>:
[SYS_shmdt]	sys_shmdt,
};

void
syscall(void)
{
801063a3:	55                   	push   %ebp
801063a4:	89 e5                	mov    %esp,%ebp
801063a6:	53                   	push   %ebx
801063a7:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->tf->eax;
801063aa:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801063b0:	8b 40 18             	mov    0x18(%eax),%eax
801063b3:	8b 40 1c             	mov    0x1c(%eax),%eax
801063b6:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num >= 0 && num < SYS_open && syscalls[num]) {
801063b9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801063bd:	78 2e                	js     801063ed <syscall+0x4a>
801063bf:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
801063c3:	7f 28                	jg     801063ed <syscall+0x4a>
801063c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063c8:	8b 04 85 40 d0 10 80 	mov    -0x7fef2fc0(,%eax,4),%eax
801063cf:	85 c0                	test   %eax,%eax
801063d1:	74 1a                	je     801063ed <syscall+0x4a>
    proc->tf->eax = syscalls[num]();
801063d3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801063d9:	8b 58 18             	mov    0x18(%eax),%ebx
801063dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063df:	8b 04 85 40 d0 10 80 	mov    -0x7fef2fc0(,%eax,4),%eax
801063e6:	ff d0                	call   *%eax
801063e8:	89 43 1c             	mov    %eax,0x1c(%ebx)
801063eb:	eb 73                	jmp    80106460 <syscall+0xbd>
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
801063ed:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
801063f1:	7e 30                	jle    80106423 <syscall+0x80>
801063f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063f6:	83 f8 1e             	cmp    $0x1e,%eax
801063f9:	77 28                	ja     80106423 <syscall+0x80>
801063fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063fe:	8b 04 85 40 d0 10 80 	mov    -0x7fef2fc0(,%eax,4),%eax
80106405:	85 c0                	test   %eax,%eax
80106407:	74 1a                	je     80106423 <syscall+0x80>
    proc->tf->eax = syscalls[num]();
80106409:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010640f:	8b 58 18             	mov    0x18(%eax),%ebx
80106412:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106415:	8b 04 85 40 d0 10 80 	mov    -0x7fef2fc0(,%eax,4),%eax
8010641c:	ff d0                	call   *%eax
8010641e:	89 43 1c             	mov    %eax,0x1c(%ebx)
80106421:	eb 3d                	jmp    80106460 <syscall+0xbd>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
80106423:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106429:	8d 48 6c             	lea    0x6c(%eax),%ecx
8010642c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  if(num >= 0 && num < SYS_open && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
80106432:	8b 40 10             	mov    0x10(%eax),%eax
80106435:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106438:	89 54 24 0c          	mov    %edx,0xc(%esp)
8010643c:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106440:	89 44 24 04          	mov    %eax,0x4(%esp)
80106444:	c7 04 24 cb 9d 10 80 	movl   $0x80109dcb,(%esp)
8010644b:	e8 51 9f ff ff       	call   801003a1 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
80106450:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106456:	8b 40 18             	mov    0x18(%eax),%eax
80106459:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
80106460:	83 c4 24             	add    $0x24,%esp
80106463:	5b                   	pop    %ebx
80106464:	5d                   	pop    %ebp
80106465:	c3                   	ret    
	...

80106468 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
80106468:	55                   	push   %ebp
80106469:	89 e5                	mov    %esp,%ebp
8010646b:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
8010646e:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106471:	89 44 24 04          	mov    %eax,0x4(%esp)
80106475:	8b 45 08             	mov    0x8(%ebp),%eax
80106478:	89 04 24             	mov    %eax,(%esp)
8010647b:	e8 46 fe ff ff       	call   801062c6 <argint>
80106480:	85 c0                	test   %eax,%eax
80106482:	79 07                	jns    8010648b <argfd+0x23>
    return -1;
80106484:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106489:	eb 50                	jmp    801064db <argfd+0x73>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
8010648b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010648e:	85 c0                	test   %eax,%eax
80106490:	78 21                	js     801064b3 <argfd+0x4b>
80106492:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106495:	83 f8 0f             	cmp    $0xf,%eax
80106498:	7f 19                	jg     801064b3 <argfd+0x4b>
8010649a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801064a0:	8b 55 f0             	mov    -0x10(%ebp),%edx
801064a3:	83 c2 08             	add    $0x8,%edx
801064a6:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801064aa:	89 45 f4             	mov    %eax,-0xc(%ebp)
801064ad:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801064b1:	75 07                	jne    801064ba <argfd+0x52>
    return -1;
801064b3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801064b8:	eb 21                	jmp    801064db <argfd+0x73>
  if(pfd)
801064ba:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801064be:	74 08                	je     801064c8 <argfd+0x60>
    *pfd = fd;
801064c0:	8b 55 f0             	mov    -0x10(%ebp),%edx
801064c3:	8b 45 0c             	mov    0xc(%ebp),%eax
801064c6:	89 10                	mov    %edx,(%eax)
  if(pf)
801064c8:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801064cc:	74 08                	je     801064d6 <argfd+0x6e>
    *pf = f;
801064ce:	8b 45 10             	mov    0x10(%ebp),%eax
801064d1:	8b 55 f4             	mov    -0xc(%ebp),%edx
801064d4:	89 10                	mov    %edx,(%eax)
  return 0;
801064d6:	b8 00 00 00 00       	mov    $0x0,%eax
}
801064db:	c9                   	leave  
801064dc:	c3                   	ret    

801064dd <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
801064dd:	55                   	push   %ebp
801064de:	89 e5                	mov    %esp,%ebp
801064e0:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
801064e3:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801064ea:	eb 30                	jmp    8010651c <fdalloc+0x3f>
    if(proc->ofile[fd] == 0){
801064ec:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801064f2:	8b 55 fc             	mov    -0x4(%ebp),%edx
801064f5:	83 c2 08             	add    $0x8,%edx
801064f8:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801064fc:	85 c0                	test   %eax,%eax
801064fe:	75 18                	jne    80106518 <fdalloc+0x3b>
      proc->ofile[fd] = f;
80106500:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106506:	8b 55 fc             	mov    -0x4(%ebp),%edx
80106509:	8d 4a 08             	lea    0x8(%edx),%ecx
8010650c:	8b 55 08             	mov    0x8(%ebp),%edx
8010650f:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
80106513:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106516:	eb 0f                	jmp    80106527 <fdalloc+0x4a>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80106518:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010651c:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
80106520:	7e ca                	jle    801064ec <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
80106522:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80106527:	c9                   	leave  
80106528:	c3                   	ret    

80106529 <sys_dup>:

int
sys_dup(void)
{
80106529:	55                   	push   %ebp
8010652a:	89 e5                	mov    %esp,%ebp
8010652c:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
8010652f:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106532:	89 44 24 08          	mov    %eax,0x8(%esp)
80106536:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010653d:	00 
8010653e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106545:	e8 1e ff ff ff       	call   80106468 <argfd>
8010654a:	85 c0                	test   %eax,%eax
8010654c:	79 07                	jns    80106555 <sys_dup+0x2c>
    return -1;
8010654e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106553:	eb 29                	jmp    8010657e <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
80106555:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106558:	89 04 24             	mov    %eax,(%esp)
8010655b:	e8 7d ff ff ff       	call   801064dd <fdalloc>
80106560:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106563:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106567:	79 07                	jns    80106570 <sys_dup+0x47>
    return -1;
80106569:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010656e:	eb 0e                	jmp    8010657e <sys_dup+0x55>
  filedup(f);
80106570:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106573:	89 04 24             	mov    %eax,(%esp)
80106576:	e8 01 aa ff ff       	call   80100f7c <filedup>
  return fd;
8010657b:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010657e:	c9                   	leave  
8010657f:	c3                   	ret    

80106580 <sys_read>:

int
sys_read(void)
{
80106580:	55                   	push   %ebp
80106581:	89 e5                	mov    %esp,%ebp
80106583:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80106586:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106589:	89 44 24 08          	mov    %eax,0x8(%esp)
8010658d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106594:	00 
80106595:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010659c:	e8 c7 fe ff ff       	call   80106468 <argfd>
801065a1:	85 c0                	test   %eax,%eax
801065a3:	78 35                	js     801065da <sys_read+0x5a>
801065a5:	8d 45 f0             	lea    -0x10(%ebp),%eax
801065a8:	89 44 24 04          	mov    %eax,0x4(%esp)
801065ac:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801065b3:	e8 0e fd ff ff       	call   801062c6 <argint>
801065b8:	85 c0                	test   %eax,%eax
801065ba:	78 1e                	js     801065da <sys_read+0x5a>
801065bc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065bf:	89 44 24 08          	mov    %eax,0x8(%esp)
801065c3:	8d 45 ec             	lea    -0x14(%ebp),%eax
801065c6:	89 44 24 04          	mov    %eax,0x4(%esp)
801065ca:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801065d1:	e8 28 fd ff ff       	call   801062fe <argptr>
801065d6:	85 c0                	test   %eax,%eax
801065d8:	79 07                	jns    801065e1 <sys_read+0x61>
    return -1;
801065da:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801065df:	eb 19                	jmp    801065fa <sys_read+0x7a>
  return fileread(f, p, n);
801065e1:	8b 4d f0             	mov    -0x10(%ebp),%ecx
801065e4:	8b 55 ec             	mov    -0x14(%ebp),%edx
801065e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065ea:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801065ee:	89 54 24 04          	mov    %edx,0x4(%esp)
801065f2:	89 04 24             	mov    %eax,(%esp)
801065f5:	e8 ef aa ff ff       	call   801010e9 <fileread>
}
801065fa:	c9                   	leave  
801065fb:	c3                   	ret    

801065fc <sys_write>:

int
sys_write(void)
{
801065fc:	55                   	push   %ebp
801065fd:	89 e5                	mov    %esp,%ebp
801065ff:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80106602:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106605:	89 44 24 08          	mov    %eax,0x8(%esp)
80106609:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106610:	00 
80106611:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106618:	e8 4b fe ff ff       	call   80106468 <argfd>
8010661d:	85 c0                	test   %eax,%eax
8010661f:	78 35                	js     80106656 <sys_write+0x5a>
80106621:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106624:	89 44 24 04          	mov    %eax,0x4(%esp)
80106628:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
8010662f:	e8 92 fc ff ff       	call   801062c6 <argint>
80106634:	85 c0                	test   %eax,%eax
80106636:	78 1e                	js     80106656 <sys_write+0x5a>
80106638:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010663b:	89 44 24 08          	mov    %eax,0x8(%esp)
8010663f:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106642:	89 44 24 04          	mov    %eax,0x4(%esp)
80106646:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010664d:	e8 ac fc ff ff       	call   801062fe <argptr>
80106652:	85 c0                	test   %eax,%eax
80106654:	79 07                	jns    8010665d <sys_write+0x61>
    return -1;
80106656:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010665b:	eb 19                	jmp    80106676 <sys_write+0x7a>
  return filewrite(f, p, n);
8010665d:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80106660:	8b 55 ec             	mov    -0x14(%ebp),%edx
80106663:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106666:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010666a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010666e:	89 04 24             	mov    %eax,(%esp)
80106671:	e8 2f ab ff ff       	call   801011a5 <filewrite>
}
80106676:	c9                   	leave  
80106677:	c3                   	ret    

80106678 <sys_close>:

int
sys_close(void)
{
80106678:	55                   	push   %ebp
80106679:	89 e5                	mov    %esp,%ebp
8010667b:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
8010667e:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106681:	89 44 24 08          	mov    %eax,0x8(%esp)
80106685:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106688:	89 44 24 04          	mov    %eax,0x4(%esp)
8010668c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106693:	e8 d0 fd ff ff       	call   80106468 <argfd>
80106698:	85 c0                	test   %eax,%eax
8010669a:	79 07                	jns    801066a3 <sys_close+0x2b>
    return -1;
8010669c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801066a1:	eb 24                	jmp    801066c7 <sys_close+0x4f>
  proc->ofile[fd] = 0;
801066a3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801066a9:	8b 55 f4             	mov    -0xc(%ebp),%edx
801066ac:	83 c2 08             	add    $0x8,%edx
801066af:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
801066b6:	00 
  fileclose(f);
801066b7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801066ba:	89 04 24             	mov    %eax,(%esp)
801066bd:	e8 02 a9 ff ff       	call   80100fc4 <fileclose>
  return 0;
801066c2:	b8 00 00 00 00       	mov    $0x0,%eax
}
801066c7:	c9                   	leave  
801066c8:	c3                   	ret    

801066c9 <sys_fstat>:

int
sys_fstat(void)
{
801066c9:	55                   	push   %ebp
801066ca:	89 e5                	mov    %esp,%ebp
801066cc:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
801066cf:	8d 45 f4             	lea    -0xc(%ebp),%eax
801066d2:	89 44 24 08          	mov    %eax,0x8(%esp)
801066d6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801066dd:	00 
801066de:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801066e5:	e8 7e fd ff ff       	call   80106468 <argfd>
801066ea:	85 c0                	test   %eax,%eax
801066ec:	78 1f                	js     8010670d <sys_fstat+0x44>
801066ee:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
801066f5:	00 
801066f6:	8d 45 f0             	lea    -0x10(%ebp),%eax
801066f9:	89 44 24 04          	mov    %eax,0x4(%esp)
801066fd:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106704:	e8 f5 fb ff ff       	call   801062fe <argptr>
80106709:	85 c0                	test   %eax,%eax
8010670b:	79 07                	jns    80106714 <sys_fstat+0x4b>
    return -1;
8010670d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106712:	eb 12                	jmp    80106726 <sys_fstat+0x5d>
  return filestat(f, st);
80106714:	8b 55 f0             	mov    -0x10(%ebp),%edx
80106717:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010671a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010671e:	89 04 24             	mov    %eax,(%esp)
80106721:	e8 74 a9 ff ff       	call   8010109a <filestat>
}
80106726:	c9                   	leave  
80106727:	c3                   	ret    

80106728 <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
80106728:	55                   	push   %ebp
80106729:	89 e5                	mov    %esp,%ebp
8010672b:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
8010672e:	8d 45 d8             	lea    -0x28(%ebp),%eax
80106731:	89 44 24 04          	mov    %eax,0x4(%esp)
80106735:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010673c:	e8 1f fc ff ff       	call   80106360 <argstr>
80106741:	85 c0                	test   %eax,%eax
80106743:	78 17                	js     8010675c <sys_link+0x34>
80106745:	8d 45 dc             	lea    -0x24(%ebp),%eax
80106748:	89 44 24 04          	mov    %eax,0x4(%esp)
8010674c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106753:	e8 08 fc ff ff       	call   80106360 <argstr>
80106758:	85 c0                	test   %eax,%eax
8010675a:	79 0a                	jns    80106766 <sys_link+0x3e>
    return -1;
8010675c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106761:	e9 3c 01 00 00       	jmp    801068a2 <sys_link+0x17a>
  if((ip = namei(old)) == 0)
80106766:	8b 45 d8             	mov    -0x28(%ebp),%eax
80106769:	89 04 24             	mov    %eax,(%esp)
8010676c:	e8 99 bc ff ff       	call   8010240a <namei>
80106771:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106774:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106778:	75 0a                	jne    80106784 <sys_link+0x5c>
    return -1;
8010677a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010677f:	e9 1e 01 00 00       	jmp    801068a2 <sys_link+0x17a>

  begin_trans();
80106784:	e8 a0 d4 ff ff       	call   80103c29 <begin_trans>

  ilock(ip);
80106789:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010678c:	89 04 24             	mov    %eax,(%esp)
8010678f:	e8 d4 b0 ff ff       	call   80101868 <ilock>
  if(ip->type == T_DIR){
80106794:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106797:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010679b:	66 83 f8 01          	cmp    $0x1,%ax
8010679f:	75 1a                	jne    801067bb <sys_link+0x93>
    iunlockput(ip);
801067a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067a4:	89 04 24             	mov    %eax,(%esp)
801067a7:	e8 40 b3 ff ff       	call   80101aec <iunlockput>
    commit_trans();
801067ac:	e8 c1 d4 ff ff       	call   80103c72 <commit_trans>
    return -1;
801067b1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801067b6:	e9 e7 00 00 00       	jmp    801068a2 <sys_link+0x17a>
  }

  ip->nlink++;
801067bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067be:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801067c2:	8d 50 01             	lea    0x1(%eax),%edx
801067c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067c8:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801067cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067cf:	89 04 24             	mov    %eax,(%esp)
801067d2:	e8 d5 ae ff ff       	call   801016ac <iupdate>
  iunlock(ip);
801067d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067da:	89 04 24             	mov    %eax,(%esp)
801067dd:	e8 d4 b1 ff ff       	call   801019b6 <iunlock>

  if((dp = nameiparent(new, name)) == 0)
801067e2:	8b 45 dc             	mov    -0x24(%ebp),%eax
801067e5:	8d 55 e2             	lea    -0x1e(%ebp),%edx
801067e8:	89 54 24 04          	mov    %edx,0x4(%esp)
801067ec:	89 04 24             	mov    %eax,(%esp)
801067ef:	e8 38 bc ff ff       	call   8010242c <nameiparent>
801067f4:	89 45 f0             	mov    %eax,-0x10(%ebp)
801067f7:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801067fb:	74 68                	je     80106865 <sys_link+0x13d>
    goto bad;
  ilock(dp);
801067fd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106800:	89 04 24             	mov    %eax,(%esp)
80106803:	e8 60 b0 ff ff       	call   80101868 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
80106808:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010680b:	8b 10                	mov    (%eax),%edx
8010680d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106810:	8b 00                	mov    (%eax),%eax
80106812:	39 c2                	cmp    %eax,%edx
80106814:	75 20                	jne    80106836 <sys_link+0x10e>
80106816:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106819:	8b 40 04             	mov    0x4(%eax),%eax
8010681c:	89 44 24 08          	mov    %eax,0x8(%esp)
80106820:	8d 45 e2             	lea    -0x1e(%ebp),%eax
80106823:	89 44 24 04          	mov    %eax,0x4(%esp)
80106827:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010682a:	89 04 24             	mov    %eax,(%esp)
8010682d:	e8 17 b9 ff ff       	call   80102149 <dirlink>
80106832:	85 c0                	test   %eax,%eax
80106834:	79 0d                	jns    80106843 <sys_link+0x11b>
    iunlockput(dp);
80106836:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106839:	89 04 24             	mov    %eax,(%esp)
8010683c:	e8 ab b2 ff ff       	call   80101aec <iunlockput>
    goto bad;
80106841:	eb 23                	jmp    80106866 <sys_link+0x13e>
  }
  iunlockput(dp);
80106843:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106846:	89 04 24             	mov    %eax,(%esp)
80106849:	e8 9e b2 ff ff       	call   80101aec <iunlockput>
  iput(ip);
8010684e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106851:	89 04 24             	mov    %eax,(%esp)
80106854:	e8 c2 b1 ff ff       	call   80101a1b <iput>

  commit_trans();
80106859:	e8 14 d4 ff ff       	call   80103c72 <commit_trans>

  return 0;
8010685e:	b8 00 00 00 00       	mov    $0x0,%eax
80106863:	eb 3d                	jmp    801068a2 <sys_link+0x17a>
  ip->nlink++;
  iupdate(ip);
  iunlock(ip);

  if((dp = nameiparent(new, name)) == 0)
    goto bad;
80106865:	90                   	nop
  commit_trans();

  return 0;

bad:
  ilock(ip);
80106866:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106869:	89 04 24             	mov    %eax,(%esp)
8010686c:	e8 f7 af ff ff       	call   80101868 <ilock>
  ip->nlink--;
80106871:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106874:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106878:	8d 50 ff             	lea    -0x1(%eax),%edx
8010687b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010687e:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80106882:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106885:	89 04 24             	mov    %eax,(%esp)
80106888:	e8 1f ae ff ff       	call   801016ac <iupdate>
  iunlockput(ip);
8010688d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106890:	89 04 24             	mov    %eax,(%esp)
80106893:	e8 54 b2 ff ff       	call   80101aec <iunlockput>
  commit_trans();
80106898:	e8 d5 d3 ff ff       	call   80103c72 <commit_trans>
  return -1;
8010689d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801068a2:	c9                   	leave  
801068a3:	c3                   	ret    

801068a4 <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
801068a4:	55                   	push   %ebp
801068a5:	89 e5                	mov    %esp,%ebp
801068a7:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801068aa:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
801068b1:	eb 4b                	jmp    801068fe <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801068b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068b6:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801068bd:	00 
801068be:	89 44 24 08          	mov    %eax,0x8(%esp)
801068c2:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801068c5:	89 44 24 04          	mov    %eax,0x4(%esp)
801068c9:	8b 45 08             	mov    0x8(%ebp),%eax
801068cc:	89 04 24             	mov    %eax,(%esp)
801068cf:	e8 8a b4 ff ff       	call   80101d5e <readi>
801068d4:	83 f8 10             	cmp    $0x10,%eax
801068d7:	74 0c                	je     801068e5 <isdirempty+0x41>
      panic("isdirempty: readi");
801068d9:	c7 04 24 e7 9d 10 80 	movl   $0x80109de7,(%esp)
801068e0:	e8 58 9c ff ff       	call   8010053d <panic>
    if(de.inum != 0)
801068e5:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
801068e9:	66 85 c0             	test   %ax,%ax
801068ec:	74 07                	je     801068f5 <isdirempty+0x51>
      return 0;
801068ee:	b8 00 00 00 00       	mov    $0x0,%eax
801068f3:	eb 1b                	jmp    80106910 <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801068f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068f8:	83 c0 10             	add    $0x10,%eax
801068fb:	89 45 f4             	mov    %eax,-0xc(%ebp)
801068fe:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106901:	8b 45 08             	mov    0x8(%ebp),%eax
80106904:	8b 40 18             	mov    0x18(%eax),%eax
80106907:	39 c2                	cmp    %eax,%edx
80106909:	72 a8                	jb     801068b3 <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
8010690b:	b8 01 00 00 00       	mov    $0x1,%eax
}
80106910:	c9                   	leave  
80106911:	c3                   	ret    

80106912 <unlink>:


int
unlink(char* path)
{
80106912:	55                   	push   %ebp
80106913:	89 e5                	mov    %esp,%ebp
80106915:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ];
  uint off;

  if((dp = nameiparent(path, name)) == 0)
80106918:	8d 45 d2             	lea    -0x2e(%ebp),%eax
8010691b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010691f:	8b 45 08             	mov    0x8(%ebp),%eax
80106922:	89 04 24             	mov    %eax,(%esp)
80106925:	e8 02 bb ff ff       	call   8010242c <nameiparent>
8010692a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010692d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106931:	75 0a                	jne    8010693d <unlink+0x2b>
    return -1;
80106933:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106938:	e9 85 01 00 00       	jmp    80106ac2 <unlink+0x1b0>

  begin_trans();
8010693d:	e8 e7 d2 ff ff       	call   80103c29 <begin_trans>

  ilock(dp);
80106942:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106945:	89 04 24             	mov    %eax,(%esp)
80106948:	e8 1b af ff ff       	call   80101868 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
8010694d:	c7 44 24 04 f9 9d 10 	movl   $0x80109df9,0x4(%esp)
80106954:	80 
80106955:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80106958:	89 04 24             	mov    %eax,(%esp)
8010695b:	e8 ff b6 ff ff       	call   8010205f <namecmp>
80106960:	85 c0                	test   %eax,%eax
80106962:	0f 84 45 01 00 00    	je     80106aad <unlink+0x19b>
80106968:	c7 44 24 04 fb 9d 10 	movl   $0x80109dfb,0x4(%esp)
8010696f:	80 
80106970:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80106973:	89 04 24             	mov    %eax,(%esp)
80106976:	e8 e4 b6 ff ff       	call   8010205f <namecmp>
8010697b:	85 c0                	test   %eax,%eax
8010697d:	0f 84 2a 01 00 00    	je     80106aad <unlink+0x19b>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
80106983:	8d 45 cc             	lea    -0x34(%ebp),%eax
80106986:	89 44 24 08          	mov    %eax,0x8(%esp)
8010698a:	8d 45 d2             	lea    -0x2e(%ebp),%eax
8010698d:	89 44 24 04          	mov    %eax,0x4(%esp)
80106991:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106994:	89 04 24             	mov    %eax,(%esp)
80106997:	e8 e5 b6 ff ff       	call   80102081 <dirlookup>
8010699c:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010699f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801069a3:	0f 84 03 01 00 00    	je     80106aac <unlink+0x19a>
    goto bad;
  ilock(ip);
801069a9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801069ac:	89 04 24             	mov    %eax,(%esp)
801069af:	e8 b4 ae ff ff       	call   80101868 <ilock>

  if(ip->nlink < 1)
801069b4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801069b7:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801069bb:	66 85 c0             	test   %ax,%ax
801069be:	7f 0c                	jg     801069cc <unlink+0xba>
    panic("unlink: nlink < 1");
801069c0:	c7 04 24 fe 9d 10 80 	movl   $0x80109dfe,(%esp)
801069c7:	e8 71 9b ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
801069cc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801069cf:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801069d3:	66 83 f8 01          	cmp    $0x1,%ax
801069d7:	75 1f                	jne    801069f8 <unlink+0xe6>
801069d9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801069dc:	89 04 24             	mov    %eax,(%esp)
801069df:	e8 c0 fe ff ff       	call   801068a4 <isdirempty>
801069e4:	85 c0                	test   %eax,%eax
801069e6:	75 10                	jne    801069f8 <unlink+0xe6>
    iunlockput(ip);
801069e8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801069eb:	89 04 24             	mov    %eax,(%esp)
801069ee:	e8 f9 b0 ff ff       	call   80101aec <iunlockput>
    goto bad;
801069f3:	e9 b5 00 00 00       	jmp    80106aad <unlink+0x19b>
  }

  memset(&de, 0, sizeof(de));
801069f8:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
801069ff:	00 
80106a00:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106a07:	00 
80106a08:	8d 45 e0             	lea    -0x20(%ebp),%eax
80106a0b:	89 04 24             	mov    %eax,(%esp)
80106a0e:	e8 63 f5 ff ff       	call   80105f76 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80106a13:	8b 45 cc             	mov    -0x34(%ebp),%eax
80106a16:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80106a1d:	00 
80106a1e:	89 44 24 08          	mov    %eax,0x8(%esp)
80106a22:	8d 45 e0             	lea    -0x20(%ebp),%eax
80106a25:	89 44 24 04          	mov    %eax,0x4(%esp)
80106a29:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a2c:	89 04 24             	mov    %eax,(%esp)
80106a2f:	e8 95 b4 ff ff       	call   80101ec9 <writei>
80106a34:	83 f8 10             	cmp    $0x10,%eax
80106a37:	74 0c                	je     80106a45 <unlink+0x133>
    panic("unlink: writei");
80106a39:	c7 04 24 10 9e 10 80 	movl   $0x80109e10,(%esp)
80106a40:	e8 f8 9a ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR){
80106a45:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106a48:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106a4c:	66 83 f8 01          	cmp    $0x1,%ax
80106a50:	75 1c                	jne    80106a6e <unlink+0x15c>
    dp->nlink--;
80106a52:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a55:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106a59:	8d 50 ff             	lea    -0x1(%eax),%edx
80106a5c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a5f:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80106a63:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a66:	89 04 24             	mov    %eax,(%esp)
80106a69:	e8 3e ac ff ff       	call   801016ac <iupdate>
  }
  iunlockput(dp);
80106a6e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a71:	89 04 24             	mov    %eax,(%esp)
80106a74:	e8 73 b0 ff ff       	call   80101aec <iunlockput>

  ip->nlink--;
80106a79:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106a7c:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106a80:	8d 50 ff             	lea    -0x1(%eax),%edx
80106a83:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106a86:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80106a8a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106a8d:	89 04 24             	mov    %eax,(%esp)
80106a90:	e8 17 ac ff ff       	call   801016ac <iupdate>
  iunlockput(ip);
80106a95:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106a98:	89 04 24             	mov    %eax,(%esp)
80106a9b:	e8 4c b0 ff ff       	call   80101aec <iunlockput>

  commit_trans();
80106aa0:	e8 cd d1 ff ff       	call   80103c72 <commit_trans>

  return 0;
80106aa5:	b8 00 00 00 00       	mov    $0x0,%eax
80106aaa:	eb 16                	jmp    80106ac2 <unlink+0x1b0>
  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    goto bad;
80106aac:	90                   	nop
  commit_trans();

  return 0;

bad:
  iunlockput(dp);
80106aad:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ab0:	89 04 24             	mov    %eax,(%esp)
80106ab3:	e8 34 b0 ff ff       	call   80101aec <iunlockput>
  commit_trans();
80106ab8:	e8 b5 d1 ff ff       	call   80103c72 <commit_trans>
  return -1;
80106abd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80106ac2:	c9                   	leave  
80106ac3:	c3                   	ret    

80106ac4 <sys_unlink>:


//PAGEBREAK!
int
sys_unlink(void)
{
80106ac4:	55                   	push   %ebp
80106ac5:	89 e5                	mov    %esp,%ebp
80106ac7:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
80106aca:	8d 45 cc             	lea    -0x34(%ebp),%eax
80106acd:	89 44 24 04          	mov    %eax,0x4(%esp)
80106ad1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106ad8:	e8 83 f8 ff ff       	call   80106360 <argstr>
80106add:	85 c0                	test   %eax,%eax
80106adf:	79 0a                	jns    80106aeb <sys_unlink+0x27>
    return -1;
80106ae1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106ae6:	e9 aa 01 00 00       	jmp    80106c95 <sys_unlink+0x1d1>
  if((dp = nameiparent(path, name)) == 0)
80106aeb:	8b 45 cc             	mov    -0x34(%ebp),%eax
80106aee:	8d 55 d2             	lea    -0x2e(%ebp),%edx
80106af1:	89 54 24 04          	mov    %edx,0x4(%esp)
80106af5:	89 04 24             	mov    %eax,(%esp)
80106af8:	e8 2f b9 ff ff       	call   8010242c <nameiparent>
80106afd:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106b00:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106b04:	75 0a                	jne    80106b10 <sys_unlink+0x4c>
    return -1;
80106b06:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106b0b:	e9 85 01 00 00       	jmp    80106c95 <sys_unlink+0x1d1>

  begin_trans();
80106b10:	e8 14 d1 ff ff       	call   80103c29 <begin_trans>

  ilock(dp);
80106b15:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b18:	89 04 24             	mov    %eax,(%esp)
80106b1b:	e8 48 ad ff ff       	call   80101868 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80106b20:	c7 44 24 04 f9 9d 10 	movl   $0x80109df9,0x4(%esp)
80106b27:	80 
80106b28:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80106b2b:	89 04 24             	mov    %eax,(%esp)
80106b2e:	e8 2c b5 ff ff       	call   8010205f <namecmp>
80106b33:	85 c0                	test   %eax,%eax
80106b35:	0f 84 45 01 00 00    	je     80106c80 <sys_unlink+0x1bc>
80106b3b:	c7 44 24 04 fb 9d 10 	movl   $0x80109dfb,0x4(%esp)
80106b42:	80 
80106b43:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80106b46:	89 04 24             	mov    %eax,(%esp)
80106b49:	e8 11 b5 ff ff       	call   8010205f <namecmp>
80106b4e:	85 c0                	test   %eax,%eax
80106b50:	0f 84 2a 01 00 00    	je     80106c80 <sys_unlink+0x1bc>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
80106b56:	8d 45 c8             	lea    -0x38(%ebp),%eax
80106b59:	89 44 24 08          	mov    %eax,0x8(%esp)
80106b5d:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80106b60:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b64:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b67:	89 04 24             	mov    %eax,(%esp)
80106b6a:	e8 12 b5 ff ff       	call   80102081 <dirlookup>
80106b6f:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106b72:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106b76:	0f 84 03 01 00 00    	je     80106c7f <sys_unlink+0x1bb>
    goto bad;
  ilock(ip);
80106b7c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b7f:	89 04 24             	mov    %eax,(%esp)
80106b82:	e8 e1 ac ff ff       	call   80101868 <ilock>

  if(ip->nlink < 1)
80106b87:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b8a:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106b8e:	66 85 c0             	test   %ax,%ax
80106b91:	7f 0c                	jg     80106b9f <sys_unlink+0xdb>
    panic("unlink: nlink < 1");
80106b93:	c7 04 24 fe 9d 10 80 	movl   $0x80109dfe,(%esp)
80106b9a:	e8 9e 99 ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80106b9f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ba2:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106ba6:	66 83 f8 01          	cmp    $0x1,%ax
80106baa:	75 1f                	jne    80106bcb <sys_unlink+0x107>
80106bac:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106baf:	89 04 24             	mov    %eax,(%esp)
80106bb2:	e8 ed fc ff ff       	call   801068a4 <isdirempty>
80106bb7:	85 c0                	test   %eax,%eax
80106bb9:	75 10                	jne    80106bcb <sys_unlink+0x107>
    iunlockput(ip);
80106bbb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106bbe:	89 04 24             	mov    %eax,(%esp)
80106bc1:	e8 26 af ff ff       	call   80101aec <iunlockput>
    goto bad;
80106bc6:	e9 b5 00 00 00       	jmp    80106c80 <sys_unlink+0x1bc>
  }

  memset(&de, 0, sizeof(de));
80106bcb:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80106bd2:	00 
80106bd3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106bda:	00 
80106bdb:	8d 45 e0             	lea    -0x20(%ebp),%eax
80106bde:	89 04 24             	mov    %eax,(%esp)
80106be1:	e8 90 f3 ff ff       	call   80105f76 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80106be6:	8b 45 c8             	mov    -0x38(%ebp),%eax
80106be9:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80106bf0:	00 
80106bf1:	89 44 24 08          	mov    %eax,0x8(%esp)
80106bf5:	8d 45 e0             	lea    -0x20(%ebp),%eax
80106bf8:	89 44 24 04          	mov    %eax,0x4(%esp)
80106bfc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106bff:	89 04 24             	mov    %eax,(%esp)
80106c02:	e8 c2 b2 ff ff       	call   80101ec9 <writei>
80106c07:	83 f8 10             	cmp    $0x10,%eax
80106c0a:	74 0c                	je     80106c18 <sys_unlink+0x154>
    panic("unlink: writei");
80106c0c:	c7 04 24 10 9e 10 80 	movl   $0x80109e10,(%esp)
80106c13:	e8 25 99 ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR){
80106c18:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c1b:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106c1f:	66 83 f8 01          	cmp    $0x1,%ax
80106c23:	75 1c                	jne    80106c41 <sys_unlink+0x17d>
    dp->nlink--;
80106c25:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c28:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106c2c:	8d 50 ff             	lea    -0x1(%eax),%edx
80106c2f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c32:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80106c36:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c39:	89 04 24             	mov    %eax,(%esp)
80106c3c:	e8 6b aa ff ff       	call   801016ac <iupdate>
  }
  iunlockput(dp);
80106c41:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c44:	89 04 24             	mov    %eax,(%esp)
80106c47:	e8 a0 ae ff ff       	call   80101aec <iunlockput>

  ip->nlink--;
80106c4c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c4f:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106c53:	8d 50 ff             	lea    -0x1(%eax),%edx
80106c56:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c59:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80106c5d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c60:	89 04 24             	mov    %eax,(%esp)
80106c63:	e8 44 aa ff ff       	call   801016ac <iupdate>
  iunlockput(ip);
80106c68:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c6b:	89 04 24             	mov    %eax,(%esp)
80106c6e:	e8 79 ae ff ff       	call   80101aec <iunlockput>

  commit_trans();
80106c73:	e8 fa cf ff ff       	call   80103c72 <commit_trans>

  return 0;
80106c78:	b8 00 00 00 00       	mov    $0x0,%eax
80106c7d:	eb 16                	jmp    80106c95 <sys_unlink+0x1d1>
  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    goto bad;
80106c7f:	90                   	nop
  commit_trans();

  return 0;

bad:
  iunlockput(dp);
80106c80:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c83:	89 04 24             	mov    %eax,(%esp)
80106c86:	e8 61 ae ff ff       	call   80101aec <iunlockput>
  commit_trans();
80106c8b:	e8 e2 cf ff ff       	call   80103c72 <commit_trans>
  return -1;
80106c90:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80106c95:	c9                   	leave  
80106c96:	c3                   	ret    

80106c97 <create>:

static struct inode*
create(char *path, short type, short major, short minor)
{
80106c97:	55                   	push   %ebp
80106c98:	89 e5                	mov    %esp,%ebp
80106c9a:	83 ec 48             	sub    $0x48,%esp
80106c9d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80106ca0:	8b 55 10             	mov    0x10(%ebp),%edx
80106ca3:	8b 45 14             	mov    0x14(%ebp),%eax
80106ca6:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
80106caa:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
80106cae:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];
  if((dp = nameiparent(path, name)) == 0)
80106cb2:	8d 45 de             	lea    -0x22(%ebp),%eax
80106cb5:	89 44 24 04          	mov    %eax,0x4(%esp)
80106cb9:	8b 45 08             	mov    0x8(%ebp),%eax
80106cbc:	89 04 24             	mov    %eax,(%esp)
80106cbf:	e8 68 b7 ff ff       	call   8010242c <nameiparent>
80106cc4:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106cc7:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106ccb:	75 0a                	jne    80106cd7 <create+0x40>
    return 0;
80106ccd:	b8 00 00 00 00       	mov    $0x0,%eax
80106cd2:	e9 7e 01 00 00       	jmp    80106e55 <create+0x1be>
  ilock(dp);
80106cd7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106cda:	89 04 24             	mov    %eax,(%esp)
80106cdd:	e8 86 ab ff ff       	call   80101868 <ilock>
  if((ip = dirlookup(dp, name, &off)) != 0){
80106ce2:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106ce5:	89 44 24 08          	mov    %eax,0x8(%esp)
80106ce9:	8d 45 de             	lea    -0x22(%ebp),%eax
80106cec:	89 44 24 04          	mov    %eax,0x4(%esp)
80106cf0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106cf3:	89 04 24             	mov    %eax,(%esp)
80106cf6:	e8 86 b3 ff ff       	call   80102081 <dirlookup>
80106cfb:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106cfe:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106d02:	74 47                	je     80106d4b <create+0xb4>
    iunlockput(dp);
80106d04:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d07:	89 04 24             	mov    %eax,(%esp)
80106d0a:	e8 dd ad ff ff       	call   80101aec <iunlockput>
    ilock(ip);
80106d0f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d12:	89 04 24             	mov    %eax,(%esp)
80106d15:	e8 4e ab ff ff       	call   80101868 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
80106d1a:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
80106d1f:	75 15                	jne    80106d36 <create+0x9f>
80106d21:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d24:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106d28:	66 83 f8 02          	cmp    $0x2,%ax
80106d2c:	75 08                	jne    80106d36 <create+0x9f>
      return ip;
80106d2e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d31:	e9 1f 01 00 00       	jmp    80106e55 <create+0x1be>
    iunlockput(ip);
80106d36:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d39:	89 04 24             	mov    %eax,(%esp)
80106d3c:	e8 ab ad ff ff       	call   80101aec <iunlockput>
    return 0;
80106d41:	b8 00 00 00 00       	mov    $0x0,%eax
80106d46:	e9 0a 01 00 00       	jmp    80106e55 <create+0x1be>
  }
  if((ip = ialloc(dp->dev, type)) == 0)
80106d4b:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
80106d4f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d52:	8b 00                	mov    (%eax),%eax
80106d54:	89 54 24 04          	mov    %edx,0x4(%esp)
80106d58:	89 04 24             	mov    %eax,(%esp)
80106d5b:	e8 6f a8 ff ff       	call   801015cf <ialloc>
80106d60:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106d63:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106d67:	75 0c                	jne    80106d75 <create+0xde>
    panic("create: ialloc");
80106d69:	c7 04 24 1f 9e 10 80 	movl   $0x80109e1f,(%esp)
80106d70:	e8 c8 97 ff ff       	call   8010053d <panic>
  ilock(ip);
80106d75:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d78:	89 04 24             	mov    %eax,(%esp)
80106d7b:	e8 e8 aa ff ff       	call   80101868 <ilock>
  ip->major = major;
80106d80:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d83:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
80106d87:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
80106d8b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d8e:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
80106d92:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
80106d96:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d99:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
80106d9f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106da2:	89 04 24             	mov    %eax,(%esp)
80106da5:	e8 02 a9 ff ff       	call   801016ac <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
80106daa:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
80106daf:	75 6a                	jne    80106e1b <create+0x184>
    dp->nlink++;  // for ".."
80106db1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106db4:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106db8:	8d 50 01             	lea    0x1(%eax),%edx
80106dbb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106dbe:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80106dc2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106dc5:	89 04 24             	mov    %eax,(%esp)
80106dc8:	e8 df a8 ff ff       	call   801016ac <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80106dcd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106dd0:	8b 40 04             	mov    0x4(%eax),%eax
80106dd3:	89 44 24 08          	mov    %eax,0x8(%esp)
80106dd7:	c7 44 24 04 f9 9d 10 	movl   $0x80109df9,0x4(%esp)
80106dde:	80 
80106ddf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106de2:	89 04 24             	mov    %eax,(%esp)
80106de5:	e8 5f b3 ff ff       	call   80102149 <dirlink>
80106dea:	85 c0                	test   %eax,%eax
80106dec:	78 21                	js     80106e0f <create+0x178>
80106dee:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106df1:	8b 40 04             	mov    0x4(%eax),%eax
80106df4:	89 44 24 08          	mov    %eax,0x8(%esp)
80106df8:	c7 44 24 04 fb 9d 10 	movl   $0x80109dfb,0x4(%esp)
80106dff:	80 
80106e00:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106e03:	89 04 24             	mov    %eax,(%esp)
80106e06:	e8 3e b3 ff ff       	call   80102149 <dirlink>
80106e0b:	85 c0                	test   %eax,%eax
80106e0d:	79 0c                	jns    80106e1b <create+0x184>
      panic("create dots");
80106e0f:	c7 04 24 2e 9e 10 80 	movl   $0x80109e2e,(%esp)
80106e16:	e8 22 97 ff ff       	call   8010053d <panic>
  }
  if(dirlink(dp, name, ip->inum) < 0)
80106e1b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106e1e:	8b 40 04             	mov    0x4(%eax),%eax
80106e21:	89 44 24 08          	mov    %eax,0x8(%esp)
80106e25:	8d 45 de             	lea    -0x22(%ebp),%eax
80106e28:	89 44 24 04          	mov    %eax,0x4(%esp)
80106e2c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e2f:	89 04 24             	mov    %eax,(%esp)
80106e32:	e8 12 b3 ff ff       	call   80102149 <dirlink>
80106e37:	85 c0                	test   %eax,%eax
80106e39:	79 0c                	jns    80106e47 <create+0x1b0>
    panic("create: dirlink");
80106e3b:	c7 04 24 3a 9e 10 80 	movl   $0x80109e3a,(%esp)
80106e42:	e8 f6 96 ff ff       	call   8010053d <panic>
  iunlockput(dp);
80106e47:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e4a:	89 04 24             	mov    %eax,(%esp)
80106e4d:	e8 9a ac ff ff       	call   80101aec <iunlockput>

  return ip;
80106e52:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80106e55:	c9                   	leave  
80106e56:	c3                   	ret    

80106e57 <fileopen>:

struct file*
fileopen(char *path, int omode)
{
80106e57:	55                   	push   %ebp
80106e58:	89 e5                	mov    %esp,%ebp
80106e5a:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  struct inode *ip;

  if(omode & O_CREATE){
80106e5d:	8b 45 0c             	mov    0xc(%ebp),%eax
80106e60:	25 00 02 00 00       	and    $0x200,%eax
80106e65:	85 c0                	test   %eax,%eax
80106e67:	74 40                	je     80106ea9 <fileopen+0x52>
    begin_trans();
80106e69:	e8 bb cd ff ff       	call   80103c29 <begin_trans>
    ip = create(path, T_FILE, 0, 0);
80106e6e:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106e75:	00 
80106e76:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106e7d:	00 
80106e7e:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80106e85:	00 
80106e86:	8b 45 08             	mov    0x8(%ebp),%eax
80106e89:	89 04 24             	mov    %eax,(%esp)
80106e8c:	e8 06 fe ff ff       	call   80106c97 <create>
80106e91:	89 45 f4             	mov    %eax,-0xc(%ebp)
    commit_trans();
80106e94:	e8 d9 cd ff ff       	call   80103c72 <commit_trans>
    if(ip == 0)
80106e99:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106e9d:	75 5b                	jne    80106efa <fileopen+0xa3>
      return 0;
80106e9f:	b8 00 00 00 00       	mov    $0x0,%eax
80106ea4:	e9 f9 00 00 00       	jmp    80106fa2 <fileopen+0x14b>
  } else {
    if((ip = namei(path)) == 0)
80106ea9:	8b 45 08             	mov    0x8(%ebp),%eax
80106eac:	89 04 24             	mov    %eax,(%esp)
80106eaf:	e8 56 b5 ff ff       	call   8010240a <namei>
80106eb4:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106eb7:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106ebb:	75 0a                	jne    80106ec7 <fileopen+0x70>
      return 0;
80106ebd:	b8 00 00 00 00       	mov    $0x0,%eax
80106ec2:	e9 db 00 00 00       	jmp    80106fa2 <fileopen+0x14b>
    ilock(ip);
80106ec7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106eca:	89 04 24             	mov    %eax,(%esp)
80106ecd:	e8 96 a9 ff ff       	call   80101868 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80106ed2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ed5:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106ed9:	66 83 f8 01          	cmp    $0x1,%ax
80106edd:	75 1b                	jne    80106efa <fileopen+0xa3>
80106edf:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80106ee3:	74 15                	je     80106efa <fileopen+0xa3>
      iunlockput(ip);
80106ee5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ee8:	89 04 24             	mov    %eax,(%esp)
80106eeb:	e8 fc ab ff ff       	call   80101aec <iunlockput>
      return 0;
80106ef0:	b8 00 00 00 00       	mov    $0x0,%eax
80106ef5:	e9 a8 00 00 00       	jmp    80106fa2 <fileopen+0x14b>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80106efa:	e8 1d a0 ff ff       	call   80100f1c <filealloc>
80106eff:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106f02:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106f06:	74 14                	je     80106f1c <fileopen+0xc5>
80106f08:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106f0b:	89 04 24             	mov    %eax,(%esp)
80106f0e:	e8 ca f5 ff ff       	call   801064dd <fdalloc>
80106f13:	89 45 ec             	mov    %eax,-0x14(%ebp)
80106f16:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80106f1a:	79 23                	jns    80106f3f <fileopen+0xe8>
    if(f)
80106f1c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106f20:	74 0b                	je     80106f2d <fileopen+0xd6>
      fileclose(f);
80106f22:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106f25:	89 04 24             	mov    %eax,(%esp)
80106f28:	e8 97 a0 ff ff       	call   80100fc4 <fileclose>
    iunlockput(ip);
80106f2d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f30:	89 04 24             	mov    %eax,(%esp)
80106f33:	e8 b4 ab ff ff       	call   80101aec <iunlockput>
    return 0;
80106f38:	b8 00 00 00 00       	mov    $0x0,%eax
80106f3d:	eb 63                	jmp    80106fa2 <fileopen+0x14b>
  }
  iunlock(ip);
80106f3f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f42:	89 04 24             	mov    %eax,(%esp)
80106f45:	e8 6c aa ff ff       	call   801019b6 <iunlock>

  f->type = FD_INODE;
80106f4a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106f4d:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80106f53:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106f56:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106f59:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
80106f5c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106f5f:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80106f66:	8b 45 0c             	mov    0xc(%ebp),%eax
80106f69:	83 e0 01             	and    $0x1,%eax
80106f6c:	85 c0                	test   %eax,%eax
80106f6e:	0f 94 c2             	sete   %dl
80106f71:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106f74:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80106f77:	8b 45 0c             	mov    0xc(%ebp),%eax
80106f7a:	83 e0 01             	and    $0x1,%eax
80106f7d:	84 c0                	test   %al,%al
80106f7f:	75 0a                	jne    80106f8b <fileopen+0x134>
80106f81:	8b 45 0c             	mov    0xc(%ebp),%eax
80106f84:	83 e0 02             	and    $0x2,%eax
80106f87:	85 c0                	test   %eax,%eax
80106f89:	74 07                	je     80106f92 <fileopen+0x13b>
80106f8b:	b8 01 00 00 00       	mov    $0x1,%eax
80106f90:	eb 05                	jmp    80106f97 <fileopen+0x140>
80106f92:	b8 00 00 00 00       	mov    $0x0,%eax
80106f97:	89 c2                	mov    %eax,%edx
80106f99:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106f9c:	88 50 09             	mov    %dl,0x9(%eax)
  return f;
80106f9f:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80106fa2:	c9                   	leave  
80106fa3:	c3                   	ret    

80106fa4 <sys_open>:

int
sys_open(void)
{
80106fa4:	55                   	push   %ebp
80106fa5:	89 e5                	mov    %esp,%ebp
80106fa7:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80106faa:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106fad:	89 44 24 04          	mov    %eax,0x4(%esp)
80106fb1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106fb8:	e8 a3 f3 ff ff       	call   80106360 <argstr>
80106fbd:	85 c0                	test   %eax,%eax
80106fbf:	78 17                	js     80106fd8 <sys_open+0x34>
80106fc1:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106fc4:	89 44 24 04          	mov    %eax,0x4(%esp)
80106fc8:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106fcf:	e8 f2 f2 ff ff       	call   801062c6 <argint>
80106fd4:	85 c0                	test   %eax,%eax
80106fd6:	79 0a                	jns    80106fe2 <sys_open+0x3e>
    return -1;
80106fd8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106fdd:	e9 46 01 00 00       	jmp    80107128 <sys_open+0x184>
  if(omode & O_CREATE){
80106fe2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106fe5:	25 00 02 00 00       	and    $0x200,%eax
80106fea:	85 c0                	test   %eax,%eax
80106fec:	74 40                	je     8010702e <sys_open+0x8a>
    begin_trans();
80106fee:	e8 36 cc ff ff       	call   80103c29 <begin_trans>
    ip = create(path, T_FILE, 0, 0);
80106ff3:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106ff6:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106ffd:	00 
80106ffe:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80107005:	00 
80107006:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
8010700d:	00 
8010700e:	89 04 24             	mov    %eax,(%esp)
80107011:	e8 81 fc ff ff       	call   80106c97 <create>
80107016:	89 45 f4             	mov    %eax,-0xc(%ebp)
    commit_trans();
80107019:	e8 54 cc ff ff       	call   80103c72 <commit_trans>
    if(ip == 0)
8010701e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80107022:	75 5c                	jne    80107080 <sys_open+0xdc>
      return -1;
80107024:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107029:	e9 fa 00 00 00       	jmp    80107128 <sys_open+0x184>
  } else {
    if((ip = namei(path)) == 0)
8010702e:	8b 45 e8             	mov    -0x18(%ebp),%eax
80107031:	89 04 24             	mov    %eax,(%esp)
80107034:	e8 d1 b3 ff ff       	call   8010240a <namei>
80107039:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010703c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80107040:	75 0a                	jne    8010704c <sys_open+0xa8>
      return -1;
80107042:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107047:	e9 dc 00 00 00       	jmp    80107128 <sys_open+0x184>
    ilock(ip);
8010704c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010704f:	89 04 24             	mov    %eax,(%esp)
80107052:	e8 11 a8 ff ff       	call   80101868 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80107057:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010705a:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010705e:	66 83 f8 01          	cmp    $0x1,%ax
80107062:	75 1c                	jne    80107080 <sys_open+0xdc>
80107064:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80107067:	85 c0                	test   %eax,%eax
80107069:	74 15                	je     80107080 <sys_open+0xdc>
      iunlockput(ip);
8010706b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010706e:	89 04 24             	mov    %eax,(%esp)
80107071:	e8 76 aa ff ff       	call   80101aec <iunlockput>
      return -1;
80107076:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010707b:	e9 a8 00 00 00       	jmp    80107128 <sys_open+0x184>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80107080:	e8 97 9e ff ff       	call   80100f1c <filealloc>
80107085:	89 45 f0             	mov    %eax,-0x10(%ebp)
80107088:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010708c:	74 14                	je     801070a2 <sys_open+0xfe>
8010708e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107091:	89 04 24             	mov    %eax,(%esp)
80107094:	e8 44 f4 ff ff       	call   801064dd <fdalloc>
80107099:	89 45 ec             	mov    %eax,-0x14(%ebp)
8010709c:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801070a0:	79 23                	jns    801070c5 <sys_open+0x121>
    if(f)
801070a2:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801070a6:	74 0b                	je     801070b3 <sys_open+0x10f>
      fileclose(f);
801070a8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801070ab:	89 04 24             	mov    %eax,(%esp)
801070ae:	e8 11 9f ff ff       	call   80100fc4 <fileclose>
    iunlockput(ip);
801070b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801070b6:	89 04 24             	mov    %eax,(%esp)
801070b9:	e8 2e aa ff ff       	call   80101aec <iunlockput>
    return -1;
801070be:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801070c3:	eb 63                	jmp    80107128 <sys_open+0x184>
  }
  iunlock(ip);
801070c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801070c8:	89 04 24             	mov    %eax,(%esp)
801070cb:	e8 e6 a8 ff ff       	call   801019b6 <iunlock>

  f->type = FD_INODE;
801070d0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801070d3:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
801070d9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801070dc:	8b 55 f4             	mov    -0xc(%ebp),%edx
801070df:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
801070e2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801070e5:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
801070ec:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801070ef:	83 e0 01             	and    $0x1,%eax
801070f2:	85 c0                	test   %eax,%eax
801070f4:	0f 94 c2             	sete   %dl
801070f7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801070fa:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
801070fd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80107100:	83 e0 01             	and    $0x1,%eax
80107103:	84 c0                	test   %al,%al
80107105:	75 0a                	jne    80107111 <sys_open+0x16d>
80107107:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010710a:	83 e0 02             	and    $0x2,%eax
8010710d:	85 c0                	test   %eax,%eax
8010710f:	74 07                	je     80107118 <sys_open+0x174>
80107111:	b8 01 00 00 00       	mov    $0x1,%eax
80107116:	eb 05                	jmp    8010711d <sys_open+0x179>
80107118:	b8 00 00 00 00       	mov    $0x0,%eax
8010711d:	89 c2                	mov    %eax,%edx
8010711f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107122:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
80107125:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
80107128:	c9                   	leave  
80107129:	c3                   	ret    

8010712a <sys_mkdir>:

int
sys_mkdir(void)
{
8010712a:	55                   	push   %ebp
8010712b:	89 e5                	mov    %esp,%ebp
8010712d:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_trans();
80107130:	e8 f4 ca ff ff       	call   80103c29 <begin_trans>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80107135:	8d 45 f0             	lea    -0x10(%ebp),%eax
80107138:	89 44 24 04          	mov    %eax,0x4(%esp)
8010713c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107143:	e8 18 f2 ff ff       	call   80106360 <argstr>
80107148:	85 c0                	test   %eax,%eax
8010714a:	78 2c                	js     80107178 <sys_mkdir+0x4e>
8010714c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010714f:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80107156:	00 
80107157:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010715e:	00 
8010715f:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80107166:	00 
80107167:	89 04 24             	mov    %eax,(%esp)
8010716a:	e8 28 fb ff ff       	call   80106c97 <create>
8010716f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107172:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80107176:	75 0c                	jne    80107184 <sys_mkdir+0x5a>
    commit_trans();
80107178:	e8 f5 ca ff ff       	call   80103c72 <commit_trans>
    return -1;
8010717d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107182:	eb 15                	jmp    80107199 <sys_mkdir+0x6f>
  }
  iunlockput(ip);
80107184:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107187:	89 04 24             	mov    %eax,(%esp)
8010718a:	e8 5d a9 ff ff       	call   80101aec <iunlockput>
  commit_trans();
8010718f:	e8 de ca ff ff       	call   80103c72 <commit_trans>
  return 0;
80107194:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107199:	c9                   	leave  
8010719a:	c3                   	ret    

8010719b <sys_mknod>:

int
sys_mknod(void)
{
8010719b:	55                   	push   %ebp
8010719c:	89 e5                	mov    %esp,%ebp
8010719e:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
801071a1:	e8 83 ca ff ff       	call   80103c29 <begin_trans>
  if((len=argstr(0, &path)) < 0 ||
801071a6:	8d 45 ec             	lea    -0x14(%ebp),%eax
801071a9:	89 44 24 04          	mov    %eax,0x4(%esp)
801071ad:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801071b4:	e8 a7 f1 ff ff       	call   80106360 <argstr>
801071b9:	89 45 f4             	mov    %eax,-0xc(%ebp)
801071bc:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801071c0:	78 5e                	js     80107220 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
801071c2:	8d 45 e8             	lea    -0x18(%ebp),%eax
801071c5:	89 44 24 04          	mov    %eax,0x4(%esp)
801071c9:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801071d0:	e8 f1 f0 ff ff       	call   801062c6 <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
801071d5:	85 c0                	test   %eax,%eax
801071d7:	78 47                	js     80107220 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
801071d9:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801071dc:	89 44 24 04          	mov    %eax,0x4(%esp)
801071e0:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801071e7:	e8 da f0 ff ff       	call   801062c6 <argint>
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
801071ec:	85 c0                	test   %eax,%eax
801071ee:	78 30                	js     80107220 <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
801071f0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801071f3:	0f bf c8             	movswl %ax,%ecx
801071f6:	8b 45 e8             	mov    -0x18(%ebp),%eax
801071f9:	0f bf d0             	movswl %ax,%edx
801071fc:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
801071ff:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80107203:	89 54 24 08          	mov    %edx,0x8(%esp)
80107207:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
8010720e:	00 
8010720f:	89 04 24             	mov    %eax,(%esp)
80107212:	e8 80 fa ff ff       	call   80106c97 <create>
80107217:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010721a:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010721e:	75 0c                	jne    8010722c <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    commit_trans();
80107220:	e8 4d ca ff ff       	call   80103c72 <commit_trans>
    return -1;
80107225:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010722a:	eb 15                	jmp    80107241 <sys_mknod+0xa6>
  }
  iunlockput(ip);
8010722c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010722f:	89 04 24             	mov    %eax,(%esp)
80107232:	e8 b5 a8 ff ff       	call   80101aec <iunlockput>
  commit_trans();
80107237:	e8 36 ca ff ff       	call   80103c72 <commit_trans>
  return 0;
8010723c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107241:	c9                   	leave  
80107242:	c3                   	ret    

80107243 <sys_chdir>:

int
sys_chdir(void)
{
80107243:	55                   	push   %ebp
80107244:	89 e5                	mov    %esp,%ebp
80107246:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0)
80107249:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010724c:	89 44 24 04          	mov    %eax,0x4(%esp)
80107250:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107257:	e8 04 f1 ff ff       	call   80106360 <argstr>
8010725c:	85 c0                	test   %eax,%eax
8010725e:	78 14                	js     80107274 <sys_chdir+0x31>
80107260:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107263:	89 04 24             	mov    %eax,(%esp)
80107266:	e8 9f b1 ff ff       	call   8010240a <namei>
8010726b:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010726e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80107272:	75 07                	jne    8010727b <sys_chdir+0x38>
    return -1;
80107274:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107279:	eb 57                	jmp    801072d2 <sys_chdir+0x8f>
  ilock(ip);
8010727b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010727e:	89 04 24             	mov    %eax,(%esp)
80107281:	e8 e2 a5 ff ff       	call   80101868 <ilock>
  if(ip->type != T_DIR){
80107286:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107289:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010728d:	66 83 f8 01          	cmp    $0x1,%ax
80107291:	74 12                	je     801072a5 <sys_chdir+0x62>
    iunlockput(ip);
80107293:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107296:	89 04 24             	mov    %eax,(%esp)
80107299:	e8 4e a8 ff ff       	call   80101aec <iunlockput>
    return -1;
8010729e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801072a3:	eb 2d                	jmp    801072d2 <sys_chdir+0x8f>
  }
  iunlock(ip);
801072a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801072a8:	89 04 24             	mov    %eax,(%esp)
801072ab:	e8 06 a7 ff ff       	call   801019b6 <iunlock>
  iput(proc->cwd);
801072b0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801072b6:	8b 40 68             	mov    0x68(%eax),%eax
801072b9:	89 04 24             	mov    %eax,(%esp)
801072bc:	e8 5a a7 ff ff       	call   80101a1b <iput>
  proc->cwd = ip;
801072c1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801072c7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801072ca:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
801072cd:	b8 00 00 00 00       	mov    $0x0,%eax
}
801072d2:	c9                   	leave  
801072d3:	c3                   	ret    

801072d4 <sys_exec>:

int
sys_exec(void)
{
801072d4:	55                   	push   %ebp
801072d5:	89 e5                	mov    %esp,%ebp
801072d7:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
801072dd:	8d 45 f0             	lea    -0x10(%ebp),%eax
801072e0:	89 44 24 04          	mov    %eax,0x4(%esp)
801072e4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801072eb:	e8 70 f0 ff ff       	call   80106360 <argstr>
801072f0:	85 c0                	test   %eax,%eax
801072f2:	78 1a                	js     8010730e <sys_exec+0x3a>
801072f4:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
801072fa:	89 44 24 04          	mov    %eax,0x4(%esp)
801072fe:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80107305:	e8 bc ef ff ff       	call   801062c6 <argint>
8010730a:	85 c0                	test   %eax,%eax
8010730c:	79 0a                	jns    80107318 <sys_exec+0x44>
    return -1;
8010730e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107313:	e9 e2 00 00 00       	jmp    801073fa <sys_exec+0x126>
  }
  memset(argv, 0, sizeof(argv));
80107318:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
8010731f:	00 
80107320:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107327:	00 
80107328:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
8010732e:	89 04 24             	mov    %eax,(%esp)
80107331:	e8 40 ec ff ff       	call   80105f76 <memset>
  for(i=0;; i++){
80107336:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
8010733d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107340:	83 f8 1f             	cmp    $0x1f,%eax
80107343:	76 0a                	jbe    8010734f <sys_exec+0x7b>
      return -1;
80107345:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010734a:	e9 ab 00 00 00       	jmp    801073fa <sys_exec+0x126>
    if(fetchint(proc, uargv+4*i, (int*)&uarg) < 0)
8010734f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107352:	c1 e0 02             	shl    $0x2,%eax
80107355:	89 c2                	mov    %eax,%edx
80107357:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
8010735d:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
80107360:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107366:	8d 95 68 ff ff ff    	lea    -0x98(%ebp),%edx
8010736c:	89 54 24 08          	mov    %edx,0x8(%esp)
80107370:	89 4c 24 04          	mov    %ecx,0x4(%esp)
80107374:	89 04 24             	mov    %eax,(%esp)
80107377:	e8 b8 ee ff ff       	call   80106234 <fetchint>
8010737c:	85 c0                	test   %eax,%eax
8010737e:	79 07                	jns    80107387 <sys_exec+0xb3>
      return -1;
80107380:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107385:	eb 73                	jmp    801073fa <sys_exec+0x126>
    if(uarg == 0){
80107387:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
8010738d:	85 c0                	test   %eax,%eax
8010738f:	75 26                	jne    801073b7 <sys_exec+0xe3>
      argv[i] = 0;
80107391:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107394:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
8010739b:	00 00 00 00 
      break;
8010739f:	90                   	nop
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
801073a0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801073a3:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
801073a9:	89 54 24 04          	mov    %edx,0x4(%esp)
801073ad:	89 04 24             	mov    %eax,(%esp)
801073b0:	e8 47 97 ff ff       	call   80100afc <exec>
801073b5:	eb 43                	jmp    801073fa <sys_exec+0x126>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
801073b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801073ba:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801073c1:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
801073c7:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
801073ca:	8b 95 68 ff ff ff    	mov    -0x98(%ebp),%edx
801073d0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801073d6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801073da:	89 54 24 04          	mov    %edx,0x4(%esp)
801073de:	89 04 24             	mov    %eax,(%esp)
801073e1:	e8 82 ee ff ff       	call   80106268 <fetchstr>
801073e6:	85 c0                	test   %eax,%eax
801073e8:	79 07                	jns    801073f1 <sys_exec+0x11d>
      return -1;
801073ea:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801073ef:	eb 09                	jmp    801073fa <sys_exec+0x126>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
801073f1:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
801073f5:	e9 43 ff ff ff       	jmp    8010733d <sys_exec+0x69>
  return exec(path, argv);
}
801073fa:	c9                   	leave  
801073fb:	c3                   	ret    

801073fc <sys_pipe>:

int
sys_pipe(void)
{
801073fc:	55                   	push   %ebp
801073fd:	89 e5                	mov    %esp,%ebp
801073ff:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80107402:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
80107409:	00 
8010740a:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010740d:	89 44 24 04          	mov    %eax,0x4(%esp)
80107411:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107418:	e8 e1 ee ff ff       	call   801062fe <argptr>
8010741d:	85 c0                	test   %eax,%eax
8010741f:	79 0a                	jns    8010742b <sys_pipe+0x2f>
    return -1;
80107421:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107426:	e9 9b 00 00 00       	jmp    801074c6 <sys_pipe+0xca>
  if(pipealloc(&rf, &wf) < 0)
8010742b:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010742e:	89 44 24 04          	mov    %eax,0x4(%esp)
80107432:	8d 45 e8             	lea    -0x18(%ebp),%eax
80107435:	89 04 24             	mov    %eax,(%esp)
80107438:	e8 07 d2 ff ff       	call   80104644 <pipealloc>
8010743d:	85 c0                	test   %eax,%eax
8010743f:	79 07                	jns    80107448 <sys_pipe+0x4c>
    return -1;
80107441:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107446:	eb 7e                	jmp    801074c6 <sys_pipe+0xca>
  fd0 = -1;
80107448:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
8010744f:	8b 45 e8             	mov    -0x18(%ebp),%eax
80107452:	89 04 24             	mov    %eax,(%esp)
80107455:	e8 83 f0 ff ff       	call   801064dd <fdalloc>
8010745a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010745d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80107461:	78 14                	js     80107477 <sys_pipe+0x7b>
80107463:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80107466:	89 04 24             	mov    %eax,(%esp)
80107469:	e8 6f f0 ff ff       	call   801064dd <fdalloc>
8010746e:	89 45 f0             	mov    %eax,-0x10(%ebp)
80107471:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107475:	79 37                	jns    801074ae <sys_pipe+0xb2>
    if(fd0 >= 0)
80107477:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010747b:	78 14                	js     80107491 <sys_pipe+0x95>
      proc->ofile[fd0] = 0;
8010747d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107483:	8b 55 f4             	mov    -0xc(%ebp),%edx
80107486:	83 c2 08             	add    $0x8,%edx
80107489:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80107490:	00 
    fileclose(rf);
80107491:	8b 45 e8             	mov    -0x18(%ebp),%eax
80107494:	89 04 24             	mov    %eax,(%esp)
80107497:	e8 28 9b ff ff       	call   80100fc4 <fileclose>
    fileclose(wf);
8010749c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010749f:	89 04 24             	mov    %eax,(%esp)
801074a2:	e8 1d 9b ff ff       	call   80100fc4 <fileclose>
    return -1;
801074a7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801074ac:	eb 18                	jmp    801074c6 <sys_pipe+0xca>
  }
  fd[0] = fd0;
801074ae:	8b 45 ec             	mov    -0x14(%ebp),%eax
801074b1:	8b 55 f4             	mov    -0xc(%ebp),%edx
801074b4:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
801074b6:	8b 45 ec             	mov    -0x14(%ebp),%eax
801074b9:	8d 50 04             	lea    0x4(%eax),%edx
801074bc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801074bf:	89 02                	mov    %eax,(%edx)
  return 0;
801074c1:	b8 00 00 00 00       	mov    $0x0,%eax
}
801074c6:	c9                   	leave  
801074c7:	c3                   	ret    

801074c8 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
801074c8:	55                   	push   %ebp
801074c9:	89 e5                	mov    %esp,%ebp
801074cb:	83 ec 08             	sub    $0x8,%esp
  return fork();
801074ce:	e8 e0 dd ff ff       	call   801052b3 <fork>
}
801074d3:	c9                   	leave  
801074d4:	c3                   	ret    

801074d5 <sys_exit>:

int
sys_exit(void)
{
801074d5:	55                   	push   %ebp
801074d6:	89 e5                	mov    %esp,%ebp
801074d8:	83 ec 08             	sub    $0x8,%esp
  exit();
801074db:	e8 36 df ff ff       	call   80105416 <exit>
  return 0;  // not reached
801074e0:	b8 00 00 00 00       	mov    $0x0,%eax
}
801074e5:	c9                   	leave  
801074e6:	c3                   	ret    

801074e7 <sys_wait>:

int
sys_wait(void)
{
801074e7:	55                   	push   %ebp
801074e8:	89 e5                	mov    %esp,%ebp
801074ea:	83 ec 08             	sub    $0x8,%esp
  return wait();
801074ed:	e8 60 e0 ff ff       	call   80105552 <wait>
}
801074f2:	c9                   	leave  
801074f3:	c3                   	ret    

801074f4 <sys_kill>:

int
sys_kill(void)
{
801074f4:	55                   	push   %ebp
801074f5:	89 e5                	mov    %esp,%ebp
801074f7:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
801074fa:	8d 45 f4             	lea    -0xc(%ebp),%eax
801074fd:	89 44 24 04          	mov    %eax,0x4(%esp)
80107501:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107508:	e8 b9 ed ff ff       	call   801062c6 <argint>
8010750d:	85 c0                	test   %eax,%eax
8010750f:	79 07                	jns    80107518 <sys_kill+0x24>
    return -1;
80107511:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107516:	eb 0b                	jmp    80107523 <sys_kill+0x2f>
  return kill(pid);
80107518:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010751b:	89 04 24             	mov    %eax,(%esp)
8010751e:	e8 f4 e4 ff ff       	call   80105a17 <kill>
}
80107523:	c9                   	leave  
80107524:	c3                   	ret    

80107525 <sys_getpid>:

int
sys_getpid(void)
{
80107525:	55                   	push   %ebp
80107526:	89 e5                	mov    %esp,%ebp
  return proc->pid;
80107528:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010752e:	8b 40 10             	mov    0x10(%eax),%eax
}
80107531:	5d                   	pop    %ebp
80107532:	c3                   	ret    

80107533 <sys_sbrk>:

int
sys_sbrk(void)
{
80107533:	55                   	push   %ebp
80107534:	89 e5                	mov    %esp,%ebp
80107536:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80107539:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010753c:	89 44 24 04          	mov    %eax,0x4(%esp)
80107540:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107547:	e8 7a ed ff ff       	call   801062c6 <argint>
8010754c:	85 c0                	test   %eax,%eax
8010754e:	79 07                	jns    80107557 <sys_sbrk+0x24>
    return -1;
80107550:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107555:	eb 24                	jmp    8010757b <sys_sbrk+0x48>
  addr = proc->sz;
80107557:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010755d:	8b 00                	mov    (%eax),%eax
8010755f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
80107562:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107565:	89 04 24             	mov    %eax,(%esp)
80107568:	e8 a1 dc ff ff       	call   8010520e <growproc>
8010756d:	85 c0                	test   %eax,%eax
8010756f:	79 07                	jns    80107578 <sys_sbrk+0x45>
    return -1;
80107571:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107576:	eb 03                	jmp    8010757b <sys_sbrk+0x48>
  return addr;
80107578:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010757b:	c9                   	leave  
8010757c:	c3                   	ret    

8010757d <sys_sleep>:

int
sys_sleep(void)
{
8010757d:	55                   	push   %ebp
8010757e:	89 e5                	mov    %esp,%ebp
80107580:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
80107583:	8d 45 f0             	lea    -0x10(%ebp),%eax
80107586:	89 44 24 04          	mov    %eax,0x4(%esp)
8010758a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107591:	e8 30 ed ff ff       	call   801062c6 <argint>
80107596:	85 c0                	test   %eax,%eax
80107598:	79 07                	jns    801075a1 <sys_sleep+0x24>
    return -1;
8010759a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010759f:	eb 6c                	jmp    8010760d <sys_sleep+0x90>
  acquire(&tickslock);
801075a1:	c7 04 24 c0 73 19 80 	movl   $0x801973c0,(%esp)
801075a8:	e8 42 e7 ff ff       	call   80105cef <acquire>
  ticks0 = ticks;
801075ad:	a1 00 7c 19 80       	mov    0x80197c00,%eax
801075b2:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
801075b5:	eb 34                	jmp    801075eb <sys_sleep+0x6e>
    if(proc->killed){
801075b7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801075bd:	8b 40 24             	mov    0x24(%eax),%eax
801075c0:	85 c0                	test   %eax,%eax
801075c2:	74 13                	je     801075d7 <sys_sleep+0x5a>
      release(&tickslock);
801075c4:	c7 04 24 c0 73 19 80 	movl   $0x801973c0,(%esp)
801075cb:	e8 ba e7 ff ff       	call   80105d8a <release>
      return -1;
801075d0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801075d5:	eb 36                	jmp    8010760d <sys_sleep+0x90>
    }
    sleep(&ticks, &tickslock);
801075d7:	c7 44 24 04 c0 73 19 	movl   $0x801973c0,0x4(%esp)
801075de:	80 
801075df:	c7 04 24 00 7c 19 80 	movl   $0x80197c00,(%esp)
801075e6:	e8 c5 e2 ff ff       	call   801058b0 <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
801075eb:	a1 00 7c 19 80       	mov    0x80197c00,%eax
801075f0:	89 c2                	mov    %eax,%edx
801075f2:	2b 55 f4             	sub    -0xc(%ebp),%edx
801075f5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801075f8:	39 c2                	cmp    %eax,%edx
801075fa:	72 bb                	jb     801075b7 <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
801075fc:	c7 04 24 c0 73 19 80 	movl   $0x801973c0,(%esp)
80107603:	e8 82 e7 ff ff       	call   80105d8a <release>
  return 0;
80107608:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010760d:	c9                   	leave  
8010760e:	c3                   	ret    

8010760f <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
8010760f:	55                   	push   %ebp
80107610:	89 e5                	mov    %esp,%ebp
80107612:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
80107615:	c7 04 24 c0 73 19 80 	movl   $0x801973c0,(%esp)
8010761c:	e8 ce e6 ff ff       	call   80105cef <acquire>
  xticks = ticks;
80107621:	a1 00 7c 19 80       	mov    0x80197c00,%eax
80107626:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
80107629:	c7 04 24 c0 73 19 80 	movl   $0x801973c0,(%esp)
80107630:	e8 55 e7 ff ff       	call   80105d8a <release>
  return xticks;
80107635:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80107638:	c9                   	leave  
80107639:	c3                   	ret    

8010763a <sys_enableSwapping>:

void
sys_enableSwapping(void)
{
8010763a:	55                   	push   %ebp
8010763b:	89 e5                	mov    %esp,%ebp
  swapFlag = 1;
8010763d:	c7 05 68 d6 10 80 01 	movl   $0x1,0x8010d668
80107644:	00 00 00 
}
80107647:	5d                   	pop    %ebp
80107648:	c3                   	ret    

80107649 <sys_disableSwapping>:

void
sys_disableSwapping(void)
{
80107649:	55                   	push   %ebp
8010764a:	89 e5                	mov    %esp,%ebp
  swapFlag = 0;
8010764c:	c7 05 68 d6 10 80 00 	movl   $0x0,0x8010d668
80107653:	00 00 00 
}
80107656:	5d                   	pop    %ebp
80107657:	c3                   	ret    

80107658 <sys_sleep2>:

int
sys_sleep2(void)
{
80107658:	55                   	push   %ebp
80107659:	89 e5                	mov    %esp,%ebp
8010765b:	83 ec 18             	sub    $0x18,%esp
  acquire(&tickslock);
8010765e:	c7 04 24 c0 73 19 80 	movl   $0x801973c0,(%esp)
80107665:	e8 85 e6 ff ff       	call   80105cef <acquire>
  if(proc->killed){
8010766a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107670:	8b 40 24             	mov    0x24(%eax),%eax
80107673:	85 c0                	test   %eax,%eax
80107675:	74 13                	je     8010768a <sys_sleep2+0x32>
    release(&tickslock);
80107677:	c7 04 24 c0 73 19 80 	movl   $0x801973c0,(%esp)
8010767e:	e8 07 e7 ff ff       	call   80105d8a <release>
    return -1;
80107683:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107688:	eb 25                	jmp    801076af <sys_sleep2+0x57>
  }
  sleep(&swapFlag, &tickslock);
8010768a:	c7 44 24 04 c0 73 19 	movl   $0x801973c0,0x4(%esp)
80107691:	80 
80107692:	c7 04 24 68 d6 10 80 	movl   $0x8010d668,(%esp)
80107699:	e8 12 e2 ff ff       	call   801058b0 <sleep>
  release(&tickslock);
8010769e:	c7 04 24 c0 73 19 80 	movl   $0x801973c0,(%esp)
801076a5:	e8 e0 e6 ff ff       	call   80105d8a <release>
  return 0;
801076aa:	b8 00 00 00 00       	mov    $0x0,%eax
}
801076af:	c9                   	leave  
801076b0:	c3                   	ret    

801076b1 <sys_wakeup2>:

int
sys_wakeup2(void)
{
801076b1:	55                   	push   %ebp
801076b2:	89 e5                	mov    %esp,%ebp
801076b4:	83 ec 18             	sub    $0x18,%esp
  wakeup(&swapFlag);
801076b7:	c7 04 24 68 d6 10 80 	movl   $0x8010d668,(%esp)
801076be:	e8 29 e3 ff ff       	call   801059ec <wakeup>
  return 0;
801076c3:	b8 00 00 00 00       	mov    $0x0,%eax
}
801076c8:	c9                   	leave  
801076c9:	c3                   	ret    

801076ca <sys_getAllocatedPages>:

int
sys_getAllocatedPages(void)
{
801076ca:	55                   	push   %ebp
801076cb:	89 e5                	mov    %esp,%ebp
801076cd:	83 ec 28             	sub    $0x28,%esp
  int pid;
  if(argint(0, &pid) < 0)
801076d0:	8d 45 f4             	lea    -0xc(%ebp),%eax
801076d3:	89 44 24 04          	mov    %eax,0x4(%esp)
801076d7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801076de:	e8 e3 eb ff ff       	call   801062c6 <argint>
801076e3:	85 c0                	test   %eax,%eax
801076e5:	79 07                	jns    801076ee <sys_getAllocatedPages+0x24>
    return -1;
801076e7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801076ec:	eb 0b                	jmp    801076f9 <sys_getAllocatedPages+0x2f>
  return getAllocatedPages(pid);
801076ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076f1:	89 04 24             	mov    %eax,(%esp)
801076f4:	e8 b8 e4 ff ff       	call   80105bb1 <getAllocatedPages>
}
801076f9:	c9                   	leave  
801076fa:	c3                   	ret    

801076fb <sys_shmget>:

int 
sys_shmget(void)
{
801076fb:	55                   	push   %ebp
801076fc:	89 e5                	mov    %esp,%ebp
801076fe:	83 ec 28             	sub    $0x28,%esp
  int key,size, shmflg;
  
  if(argint(0, &key) < 0)
80107701:	8d 45 f4             	lea    -0xc(%ebp),%eax
80107704:	89 44 24 04          	mov    %eax,0x4(%esp)
80107708:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010770f:	e8 b2 eb ff ff       	call   801062c6 <argint>
80107714:	85 c0                	test   %eax,%eax
80107716:	79 07                	jns    8010771f <sys_shmget+0x24>
    return -1;
80107718:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010771d:	eb 65                	jmp    80107784 <sys_shmget+0x89>
  
  if(argint(1, &size) < 0)
8010771f:	8d 45 f0             	lea    -0x10(%ebp),%eax
80107722:	89 44 24 04          	mov    %eax,0x4(%esp)
80107726:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010772d:	e8 94 eb ff ff       	call   801062c6 <argint>
80107732:	85 c0                	test   %eax,%eax
80107734:	79 07                	jns    8010773d <sys_shmget+0x42>
    return -1;
80107736:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010773b:	eb 47                	jmp    80107784 <sys_shmget+0x89>
  if(size<0)
8010773d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107740:	85 c0                	test   %eax,%eax
80107742:	79 07                	jns    8010774b <sys_shmget+0x50>
    return -1;
80107744:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107749:	eb 39                	jmp    80107784 <sys_shmget+0x89>
  
  if(argint(2, &shmflg) < 0)
8010774b:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010774e:	89 44 24 04          	mov    %eax,0x4(%esp)
80107752:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80107759:	e8 68 eb ff ff       	call   801062c6 <argint>
8010775e:	85 c0                	test   %eax,%eax
80107760:	79 07                	jns    80107769 <sys_shmget+0x6e>
    return -1;
80107762:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107767:	eb 1b                	jmp    80107784 <sys_shmget+0x89>
  
  return shmget(key, (uint)size,shmflg);
80107769:	8b 4d ec             	mov    -0x14(%ebp),%ecx
8010776c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010776f:	89 c2                	mov    %eax,%edx
80107771:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107774:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80107778:	89 54 24 04          	mov    %edx,0x4(%esp)
8010777c:	89 04 24             	mov    %eax,(%esp)
8010777f:	e8 d9 b3 ff ff       	call   80102b5d <shmget>
}
80107784:	c9                   	leave  
80107785:	c3                   	ret    

80107786 <sys_shmdel>:

int 
sys_shmdel(void)
{
80107786:	55                   	push   %ebp
80107787:	89 e5                	mov    %esp,%ebp
80107789:	83 ec 28             	sub    $0x28,%esp
  int shmid;
  if(argint(0, &shmid) < 0)
8010778c:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010778f:	89 44 24 04          	mov    %eax,0x4(%esp)
80107793:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010779a:	e8 27 eb ff ff       	call   801062c6 <argint>
8010779f:	85 c0                	test   %eax,%eax
801077a1:	79 07                	jns    801077aa <sys_shmdel+0x24>
    return -1;
801077a3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801077a8:	eb 0b                	jmp    801077b5 <sys_shmdel+0x2f>
  
  return shmdel(shmid);
801077aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077ad:	89 04 24             	mov    %eax,(%esp)
801077b0:	e8 fb b5 ff ff       	call   80102db0 <shmdel>
}
801077b5:	c9                   	leave  
801077b6:	c3                   	ret    

801077b7 <sys_shmat>:

void *
sys_shmat(void)
{
801077b7:	55                   	push   %ebp
801077b8:	89 e5                	mov    %esp,%ebp
801077ba:	83 ec 28             	sub    $0x28,%esp
  int shmid,shmflg;
  
  if(argint(0, &shmid) < 0)
801077bd:	8d 45 f4             	lea    -0xc(%ebp),%eax
801077c0:	89 44 24 04          	mov    %eax,0x4(%esp)
801077c4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801077cb:	e8 f6 ea ff ff       	call   801062c6 <argint>
801077d0:	85 c0                	test   %eax,%eax
801077d2:	79 07                	jns    801077db <sys_shmat+0x24>
    return (void*)-1;
801077d4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801077d9:	eb 30                	jmp    8010780b <sys_shmat+0x54>
  
  if(argint(1, &shmflg) < 0)
801077db:	8d 45 f0             	lea    -0x10(%ebp),%eax
801077de:	89 44 24 04          	mov    %eax,0x4(%esp)
801077e2:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801077e9:	e8 d8 ea ff ff       	call   801062c6 <argint>
801077ee:	85 c0                	test   %eax,%eax
801077f0:	79 07                	jns    801077f9 <sys_shmat+0x42>
    return (void*)-1;
801077f2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801077f7:	eb 12                	jmp    8010780b <sys_shmat+0x54>
  
  return shmat(shmid,shmflg);
801077f9:	8b 55 f0             	mov    -0x10(%ebp),%edx
801077fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077ff:	89 54 24 04          	mov    %edx,0x4(%esp)
80107803:	89 04 24             	mov    %eax,(%esp)
80107806:	e8 df b7 ff ff       	call   80102fea <shmat>
}
8010780b:	c9                   	leave  
8010780c:	c3                   	ret    

8010780d <sys_shmdt>:

int 
sys_shmdt(void)
{
8010780d:	55                   	push   %ebp
8010780e:	89 e5                	mov    %esp,%ebp
80107810:	83 ec 28             	sub    $0x28,%esp
  void* shmaddr;
  if(argptr(0, (void*)&shmaddr,sizeof(void*)) < 0)
80107813:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
8010781a:	00 
8010781b:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010781e:	89 44 24 04          	mov    %eax,0x4(%esp)
80107822:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107829:	e8 d0 ea ff ff       	call   801062fe <argptr>
8010782e:	85 c0                	test   %eax,%eax
80107830:	79 07                	jns    80107839 <sys_shmdt+0x2c>
    return -1;
80107832:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107837:	eb 0b                	jmp    80107844 <sys_shmdt+0x37>
  return shmdt(shmaddr);
80107839:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010783c:	89 04 24             	mov    %eax,(%esp)
8010783f:	e8 9e b9 ff ff       	call   801031e2 <shmdt>
}
80107844:	c9                   	leave  
80107845:	c3                   	ret    
	...

80107848 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80107848:	55                   	push   %ebp
80107849:	89 e5                	mov    %esp,%ebp
8010784b:	83 ec 08             	sub    $0x8,%esp
8010784e:	8b 55 08             	mov    0x8(%ebp),%edx
80107851:	8b 45 0c             	mov    0xc(%ebp),%eax
80107854:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80107858:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010785b:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
8010785f:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80107863:	ee                   	out    %al,(%dx)
}
80107864:	c9                   	leave  
80107865:	c3                   	ret    

80107866 <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
80107866:	55                   	push   %ebp
80107867:	89 e5                	mov    %esp,%ebp
80107869:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
8010786c:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
80107873:	00 
80107874:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
8010787b:	e8 c8 ff ff ff       	call   80107848 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
80107880:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
80107887:	00 
80107888:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
8010788f:	e8 b4 ff ff ff       	call   80107848 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
80107894:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
8010789b:	00 
8010789c:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
801078a3:	e8 a0 ff ff ff       	call   80107848 <outb>
  picenable(IRQ_TIMER);
801078a8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801078af:	e8 19 cc ff ff       	call   801044cd <picenable>
}
801078b4:	c9                   	leave  
801078b5:	c3                   	ret    
	...

801078b8 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
801078b8:	1e                   	push   %ds
  pushl %es
801078b9:	06                   	push   %es
  pushl %fs
801078ba:	0f a0                	push   %fs
  pushl %gs
801078bc:	0f a8                	push   %gs
  pushal
801078be:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
801078bf:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
801078c3:	8e d8                	mov    %eax,%ds
  movw %ax, %es
801078c5:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
801078c7:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
801078cb:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
801078cd:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
801078cf:	54                   	push   %esp
  call trap
801078d0:	e8 de 01 00 00       	call   80107ab3 <trap>
  addl $4, %esp
801078d5:	83 c4 04             	add    $0x4,%esp

801078d8 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
801078d8:	61                   	popa   
  popl %gs
801078d9:	0f a9                	pop    %gs
  popl %fs
801078db:	0f a1                	pop    %fs
  popl %es
801078dd:	07                   	pop    %es
  popl %ds
801078de:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
801078df:	83 c4 08             	add    $0x8,%esp
  iret
801078e2:	cf                   	iret   
	...

801078e4 <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
801078e4:	55                   	push   %ebp
801078e5:	89 e5                	mov    %esp,%ebp
801078e7:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
801078ea:	8b 45 0c             	mov    0xc(%ebp),%eax
801078ed:	83 e8 01             	sub    $0x1,%eax
801078f0:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
801078f4:	8b 45 08             	mov    0x8(%ebp),%eax
801078f7:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
801078fb:	8b 45 08             	mov    0x8(%ebp),%eax
801078fe:	c1 e8 10             	shr    $0x10,%eax
80107901:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
80107905:	8d 45 fa             	lea    -0x6(%ebp),%eax
80107908:	0f 01 18             	lidtl  (%eax)
}
8010790b:	c9                   	leave  
8010790c:	c3                   	ret    

8010790d <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
8010790d:	55                   	push   %ebp
8010790e:	89 e5                	mov    %esp,%ebp
80107910:	53                   	push   %ebx
80107911:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
80107914:	0f 20 d3             	mov    %cr2,%ebx
80107917:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return val;
8010791a:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
8010791d:	83 c4 10             	add    $0x10,%esp
80107920:	5b                   	pop    %ebx
80107921:	5d                   	pop    %ebp
80107922:	c3                   	ret    

80107923 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
80107923:	55                   	push   %ebp
80107924:	89 e5                	mov    %esp,%ebp
80107926:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
80107929:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80107930:	e9 c3 00 00 00       	jmp    801079f8 <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80107935:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107938:	8b 04 85 bc d0 10 80 	mov    -0x7fef2f44(,%eax,4),%eax
8010793f:	89 c2                	mov    %eax,%edx
80107941:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107944:	66 89 14 c5 00 74 19 	mov    %dx,-0x7fe68c00(,%eax,8)
8010794b:	80 
8010794c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010794f:	66 c7 04 c5 02 74 19 	movw   $0x8,-0x7fe68bfe(,%eax,8)
80107956:	80 08 00 
80107959:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010795c:	0f b6 14 c5 04 74 19 	movzbl -0x7fe68bfc(,%eax,8),%edx
80107963:	80 
80107964:	83 e2 e0             	and    $0xffffffe0,%edx
80107967:	88 14 c5 04 74 19 80 	mov    %dl,-0x7fe68bfc(,%eax,8)
8010796e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107971:	0f b6 14 c5 04 74 19 	movzbl -0x7fe68bfc(,%eax,8),%edx
80107978:	80 
80107979:	83 e2 1f             	and    $0x1f,%edx
8010797c:	88 14 c5 04 74 19 80 	mov    %dl,-0x7fe68bfc(,%eax,8)
80107983:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107986:	0f b6 14 c5 05 74 19 	movzbl -0x7fe68bfb(,%eax,8),%edx
8010798d:	80 
8010798e:	83 e2 f0             	and    $0xfffffff0,%edx
80107991:	83 ca 0e             	or     $0xe,%edx
80107994:	88 14 c5 05 74 19 80 	mov    %dl,-0x7fe68bfb(,%eax,8)
8010799b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010799e:	0f b6 14 c5 05 74 19 	movzbl -0x7fe68bfb(,%eax,8),%edx
801079a5:	80 
801079a6:	83 e2 ef             	and    $0xffffffef,%edx
801079a9:	88 14 c5 05 74 19 80 	mov    %dl,-0x7fe68bfb(,%eax,8)
801079b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079b3:	0f b6 14 c5 05 74 19 	movzbl -0x7fe68bfb(,%eax,8),%edx
801079ba:	80 
801079bb:	83 e2 9f             	and    $0xffffff9f,%edx
801079be:	88 14 c5 05 74 19 80 	mov    %dl,-0x7fe68bfb(,%eax,8)
801079c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079c8:	0f b6 14 c5 05 74 19 	movzbl -0x7fe68bfb(,%eax,8),%edx
801079cf:	80 
801079d0:	83 ca 80             	or     $0xffffff80,%edx
801079d3:	88 14 c5 05 74 19 80 	mov    %dl,-0x7fe68bfb(,%eax,8)
801079da:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079dd:	8b 04 85 bc d0 10 80 	mov    -0x7fef2f44(,%eax,4),%eax
801079e4:	c1 e8 10             	shr    $0x10,%eax
801079e7:	89 c2                	mov    %eax,%edx
801079e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079ec:	66 89 14 c5 06 74 19 	mov    %dx,-0x7fe68bfa(,%eax,8)
801079f3:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
801079f4:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801079f8:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
801079ff:	0f 8e 30 ff ff ff    	jle    80107935 <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80107a05:	a1 bc d1 10 80       	mov    0x8010d1bc,%eax
80107a0a:	66 a3 00 76 19 80    	mov    %ax,0x80197600
80107a10:	66 c7 05 02 76 19 80 	movw   $0x8,0x80197602
80107a17:	08 00 
80107a19:	0f b6 05 04 76 19 80 	movzbl 0x80197604,%eax
80107a20:	83 e0 e0             	and    $0xffffffe0,%eax
80107a23:	a2 04 76 19 80       	mov    %al,0x80197604
80107a28:	0f b6 05 04 76 19 80 	movzbl 0x80197604,%eax
80107a2f:	83 e0 1f             	and    $0x1f,%eax
80107a32:	a2 04 76 19 80       	mov    %al,0x80197604
80107a37:	0f b6 05 05 76 19 80 	movzbl 0x80197605,%eax
80107a3e:	83 c8 0f             	or     $0xf,%eax
80107a41:	a2 05 76 19 80       	mov    %al,0x80197605
80107a46:	0f b6 05 05 76 19 80 	movzbl 0x80197605,%eax
80107a4d:	83 e0 ef             	and    $0xffffffef,%eax
80107a50:	a2 05 76 19 80       	mov    %al,0x80197605
80107a55:	0f b6 05 05 76 19 80 	movzbl 0x80197605,%eax
80107a5c:	83 c8 60             	or     $0x60,%eax
80107a5f:	a2 05 76 19 80       	mov    %al,0x80197605
80107a64:	0f b6 05 05 76 19 80 	movzbl 0x80197605,%eax
80107a6b:	83 c8 80             	or     $0xffffff80,%eax
80107a6e:	a2 05 76 19 80       	mov    %al,0x80197605
80107a73:	a1 bc d1 10 80       	mov    0x8010d1bc,%eax
80107a78:	c1 e8 10             	shr    $0x10,%eax
80107a7b:	66 a3 06 76 19 80    	mov    %ax,0x80197606
  
  initlock(&tickslock, "time");
80107a81:	c7 44 24 04 4c 9e 10 	movl   $0x80109e4c,0x4(%esp)
80107a88:	80 
80107a89:	c7 04 24 c0 73 19 80 	movl   $0x801973c0,(%esp)
80107a90:	e8 39 e2 ff ff       	call   80105cce <initlock>
}
80107a95:	c9                   	leave  
80107a96:	c3                   	ret    

80107a97 <idtinit>:

void
idtinit(void)
{
80107a97:	55                   	push   %ebp
80107a98:	89 e5                	mov    %esp,%ebp
80107a9a:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
80107a9d:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
80107aa4:	00 
80107aa5:	c7 04 24 00 74 19 80 	movl   $0x80197400,(%esp)
80107aac:	e8 33 fe ff ff       	call   801078e4 <lidt>
}
80107ab1:	c9                   	leave  
80107ab2:	c3                   	ret    

80107ab3 <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
80107ab3:	55                   	push   %ebp
80107ab4:	89 e5                	mov    %esp,%ebp
80107ab6:	57                   	push   %edi
80107ab7:	56                   	push   %esi
80107ab8:	53                   	push   %ebx
80107ab9:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
80107abc:	8b 45 08             	mov    0x8(%ebp),%eax
80107abf:	8b 40 30             	mov    0x30(%eax),%eax
80107ac2:	83 f8 40             	cmp    $0x40,%eax
80107ac5:	75 3e                	jne    80107b05 <trap+0x52>
    if(proc->killed)
80107ac7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107acd:	8b 40 24             	mov    0x24(%eax),%eax
80107ad0:	85 c0                	test   %eax,%eax
80107ad2:	74 05                	je     80107ad9 <trap+0x26>
      exit();
80107ad4:	e8 3d d9 ff ff       	call   80105416 <exit>
    proc->tf = tf;
80107ad9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107adf:	8b 55 08             	mov    0x8(%ebp),%edx
80107ae2:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
80107ae5:	e8 b9 e8 ff ff       	call   801063a3 <syscall>
    if(proc->killed)
80107aea:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107af0:	8b 40 24             	mov    0x24(%eax),%eax
80107af3:	85 c0                	test   %eax,%eax
80107af5:	0f 84 34 02 00 00    	je     80107d2f <trap+0x27c>
      exit();
80107afb:	e8 16 d9 ff ff       	call   80105416 <exit>
    return;
80107b00:	e9 2a 02 00 00       	jmp    80107d2f <trap+0x27c>
  }

  switch(tf->trapno){
80107b05:	8b 45 08             	mov    0x8(%ebp),%eax
80107b08:	8b 40 30             	mov    0x30(%eax),%eax
80107b0b:	83 e8 20             	sub    $0x20,%eax
80107b0e:	83 f8 1f             	cmp    $0x1f,%eax
80107b11:	0f 87 bc 00 00 00    	ja     80107bd3 <trap+0x120>
80107b17:	8b 04 85 f4 9e 10 80 	mov    -0x7fef610c(,%eax,4),%eax
80107b1e:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
80107b20:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107b26:	0f b6 00             	movzbl (%eax),%eax
80107b29:	84 c0                	test   %al,%al
80107b2b:	75 31                	jne    80107b5e <trap+0xab>
      acquire(&tickslock);
80107b2d:	c7 04 24 c0 73 19 80 	movl   $0x801973c0,(%esp)
80107b34:	e8 b6 e1 ff ff       	call   80105cef <acquire>
      ticks++;
80107b39:	a1 00 7c 19 80       	mov    0x80197c00,%eax
80107b3e:	83 c0 01             	add    $0x1,%eax
80107b41:	a3 00 7c 19 80       	mov    %eax,0x80197c00
      wakeup(&ticks);
80107b46:	c7 04 24 00 7c 19 80 	movl   $0x80197c00,(%esp)
80107b4d:	e8 9a de ff ff       	call   801059ec <wakeup>
      release(&tickslock);
80107b52:	c7 04 24 c0 73 19 80 	movl   $0x801973c0,(%esp)
80107b59:	e8 2c e2 ff ff       	call   80105d8a <release>
    }
    lapiceoi();
80107b5e:	e8 92 bd ff ff       	call   801038f5 <lapiceoi>
    break;
80107b63:	e9 41 01 00 00       	jmp    80107ca9 <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
80107b68:	e8 8a ab ff ff       	call   801026f7 <ideintr>
    lapiceoi();
80107b6d:	e8 83 bd ff ff       	call   801038f5 <lapiceoi>
    break;
80107b72:	e9 32 01 00 00       	jmp    80107ca9 <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
80107b77:	e8 57 bb ff ff       	call   801036d3 <kbdintr>
    lapiceoi();
80107b7c:	e8 74 bd ff ff       	call   801038f5 <lapiceoi>
    break;
80107b81:	e9 23 01 00 00       	jmp    80107ca9 <trap+0x1f6>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
80107b86:	e8 a9 03 00 00       	call   80107f34 <uartintr>
    lapiceoi();
80107b8b:	e8 65 bd ff ff       	call   801038f5 <lapiceoi>
    break;
80107b90:	e9 14 01 00 00       	jmp    80107ca9 <trap+0x1f6>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
            cpu->id, tf->cs, tf->eip);
80107b95:	8b 45 08             	mov    0x8(%ebp),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80107b98:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
80107b9b:	8b 45 08             	mov    0x8(%ebp),%eax
80107b9e:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80107ba2:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
80107ba5:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107bab:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80107bae:	0f b6 c0             	movzbl %al,%eax
80107bb1:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80107bb5:	89 54 24 08          	mov    %edx,0x8(%esp)
80107bb9:	89 44 24 04          	mov    %eax,0x4(%esp)
80107bbd:	c7 04 24 54 9e 10 80 	movl   $0x80109e54,(%esp)
80107bc4:	e8 d8 87 ff ff       	call   801003a1 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
80107bc9:	e8 27 bd ff ff       	call   801038f5 <lapiceoi>
    break;
80107bce:	e9 d6 00 00 00       	jmp    80107ca9 <trap+0x1f6>
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
80107bd3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107bd9:	85 c0                	test   %eax,%eax
80107bdb:	74 11                	je     80107bee <trap+0x13b>
80107bdd:	8b 45 08             	mov    0x8(%ebp),%eax
80107be0:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80107be4:	0f b7 c0             	movzwl %ax,%eax
80107be7:	83 e0 03             	and    $0x3,%eax
80107bea:	85 c0                	test   %eax,%eax
80107bec:	75 46                	jne    80107c34 <trap+0x181>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80107bee:	e8 1a fd ff ff       	call   8010790d <rcr2>
              tf->trapno, cpu->id, tf->eip, rcr2());
80107bf3:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80107bf6:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
80107bf9:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107c00:	0f b6 12             	movzbl (%edx),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80107c03:	0f b6 ca             	movzbl %dl,%ecx
              tf->trapno, cpu->id, tf->eip, rcr2());
80107c06:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80107c09:	8b 52 30             	mov    0x30(%edx),%edx
80107c0c:	89 44 24 10          	mov    %eax,0x10(%esp)
80107c10:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
80107c14:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80107c18:	89 54 24 04          	mov    %edx,0x4(%esp)
80107c1c:	c7 04 24 78 9e 10 80 	movl   $0x80109e78,(%esp)
80107c23:	e8 79 87 ff ff       	call   801003a1 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
80107c28:	c7 04 24 aa 9e 10 80 	movl   $0x80109eaa,(%esp)
80107c2f:	e8 09 89 ff ff       	call   8010053d <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107c34:	e8 d4 fc ff ff       	call   8010790d <rcr2>
80107c39:	89 c2                	mov    %eax,%edx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107c3b:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107c3e:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107c41:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107c47:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107c4a:	0f b6 f0             	movzbl %al,%esi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107c4d:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107c50:	8b 58 34             	mov    0x34(%eax),%ebx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107c53:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107c56:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107c59:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107c5f:	83 c0 6c             	add    $0x6c,%eax
80107c62:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80107c65:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107c6b:	8b 40 10             	mov    0x10(%eax),%eax
80107c6e:	89 54 24 1c          	mov    %edx,0x1c(%esp)
80107c72:	89 7c 24 18          	mov    %edi,0x18(%esp)
80107c76:	89 74 24 14          	mov    %esi,0x14(%esp)
80107c7a:	89 5c 24 10          	mov    %ebx,0x10(%esp)
80107c7e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80107c82:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80107c85:	89 54 24 08          	mov    %edx,0x8(%esp)
80107c89:	89 44 24 04          	mov    %eax,0x4(%esp)
80107c8d:	c7 04 24 b0 9e 10 80 	movl   $0x80109eb0,(%esp)
80107c94:	e8 08 87 ff ff       	call   801003a1 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
80107c99:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107c9f:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
80107ca6:	eb 01                	jmp    80107ca9 <trap+0x1f6>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
80107ca8:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80107ca9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107caf:	85 c0                	test   %eax,%eax
80107cb1:	74 24                	je     80107cd7 <trap+0x224>
80107cb3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107cb9:	8b 40 24             	mov    0x24(%eax),%eax
80107cbc:	85 c0                	test   %eax,%eax
80107cbe:	74 17                	je     80107cd7 <trap+0x224>
80107cc0:	8b 45 08             	mov    0x8(%ebp),%eax
80107cc3:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80107cc7:	0f b7 c0             	movzwl %ax,%eax
80107cca:	83 e0 03             	and    $0x3,%eax
80107ccd:	83 f8 03             	cmp    $0x3,%eax
80107cd0:	75 05                	jne    80107cd7 <trap+0x224>
    exit();
80107cd2:	e8 3f d7 ff ff       	call   80105416 <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
80107cd7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107cdd:	85 c0                	test   %eax,%eax
80107cdf:	74 1e                	je     80107cff <trap+0x24c>
80107ce1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107ce7:	8b 40 0c             	mov    0xc(%eax),%eax
80107cea:	83 f8 04             	cmp    $0x4,%eax
80107ced:	75 10                	jne    80107cff <trap+0x24c>
80107cef:	8b 45 08             	mov    0x8(%ebp),%eax
80107cf2:	8b 40 30             	mov    0x30(%eax),%eax
80107cf5:	83 f8 20             	cmp    $0x20,%eax
80107cf8:	75 05                	jne    80107cff <trap+0x24c>
    yield();
80107cfa:	e8 53 db ff ff       	call   80105852 <yield>

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80107cff:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107d05:	85 c0                	test   %eax,%eax
80107d07:	74 27                	je     80107d30 <trap+0x27d>
80107d09:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107d0f:	8b 40 24             	mov    0x24(%eax),%eax
80107d12:	85 c0                	test   %eax,%eax
80107d14:	74 1a                	je     80107d30 <trap+0x27d>
80107d16:	8b 45 08             	mov    0x8(%ebp),%eax
80107d19:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80107d1d:	0f b7 c0             	movzwl %ax,%eax
80107d20:	83 e0 03             	and    $0x3,%eax
80107d23:	83 f8 03             	cmp    $0x3,%eax
80107d26:	75 08                	jne    80107d30 <trap+0x27d>
    exit();
80107d28:	e8 e9 d6 ff ff       	call   80105416 <exit>
80107d2d:	eb 01                	jmp    80107d30 <trap+0x27d>
      exit();
    proc->tf = tf;
    syscall();
    if(proc->killed)
      exit();
    return;
80107d2f:	90                   	nop
    yield();

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
    exit();
}
80107d30:	83 c4 3c             	add    $0x3c,%esp
80107d33:	5b                   	pop    %ebx
80107d34:	5e                   	pop    %esi
80107d35:	5f                   	pop    %edi
80107d36:	5d                   	pop    %ebp
80107d37:	c3                   	ret    

80107d38 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80107d38:	55                   	push   %ebp
80107d39:	89 e5                	mov    %esp,%ebp
80107d3b:	53                   	push   %ebx
80107d3c:	83 ec 14             	sub    $0x14,%esp
80107d3f:	8b 45 08             	mov    0x8(%ebp),%eax
80107d42:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80107d46:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80107d4a:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80107d4e:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80107d52:	ec                   	in     (%dx),%al
80107d53:	89 c3                	mov    %eax,%ebx
80107d55:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80107d58:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80107d5c:	83 c4 14             	add    $0x14,%esp
80107d5f:	5b                   	pop    %ebx
80107d60:	5d                   	pop    %ebp
80107d61:	c3                   	ret    

80107d62 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80107d62:	55                   	push   %ebp
80107d63:	89 e5                	mov    %esp,%ebp
80107d65:	83 ec 08             	sub    $0x8,%esp
80107d68:	8b 55 08             	mov    0x8(%ebp),%edx
80107d6b:	8b 45 0c             	mov    0xc(%ebp),%eax
80107d6e:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80107d72:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80107d75:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80107d79:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80107d7d:	ee                   	out    %al,(%dx)
}
80107d7e:	c9                   	leave  
80107d7f:	c3                   	ret    

80107d80 <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
80107d80:	55                   	push   %ebp
80107d81:	89 e5                	mov    %esp,%ebp
80107d83:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
80107d86:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107d8d:	00 
80107d8e:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80107d95:	e8 c8 ff ff ff       	call   80107d62 <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
80107d9a:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
80107da1:	00 
80107da2:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80107da9:	e8 b4 ff ff ff       	call   80107d62 <outb>
  outb(COM1+0, 115200/9600);
80107dae:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
80107db5:	00 
80107db6:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107dbd:	e8 a0 ff ff ff       	call   80107d62 <outb>
  outb(COM1+1, 0);
80107dc2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107dc9:	00 
80107dca:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80107dd1:	e8 8c ff ff ff       	call   80107d62 <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
80107dd6:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80107ddd:	00 
80107dde:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80107de5:	e8 78 ff ff ff       	call   80107d62 <outb>
  outb(COM1+4, 0);
80107dea:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107df1:	00 
80107df2:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
80107df9:	e8 64 ff ff ff       	call   80107d62 <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
80107dfe:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80107e05:	00 
80107e06:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80107e0d:	e8 50 ff ff ff       	call   80107d62 <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
80107e12:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80107e19:	e8 1a ff ff ff       	call   80107d38 <inb>
80107e1e:	3c ff                	cmp    $0xff,%al
80107e20:	74 6c                	je     80107e8e <uartinit+0x10e>
    return;
  uart = 1;
80107e22:	c7 05 74 d6 10 80 01 	movl   $0x1,0x8010d674
80107e29:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
80107e2c:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80107e33:	e8 00 ff ff ff       	call   80107d38 <inb>
  inb(COM1+0);
80107e38:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107e3f:	e8 f4 fe ff ff       	call   80107d38 <inb>
  picenable(IRQ_COM1);
80107e44:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80107e4b:	e8 7d c6 ff ff       	call   801044cd <picenable>
  ioapicenable(IRQ_COM1, 0);
80107e50:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107e57:	00 
80107e58:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80107e5f:	e8 16 ab ff ff       	call   8010297a <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80107e64:	c7 45 f4 74 9f 10 80 	movl   $0x80109f74,-0xc(%ebp)
80107e6b:	eb 15                	jmp    80107e82 <uartinit+0x102>
    uartputc(*p);
80107e6d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e70:	0f b6 00             	movzbl (%eax),%eax
80107e73:	0f be c0             	movsbl %al,%eax
80107e76:	89 04 24             	mov    %eax,(%esp)
80107e79:	e8 13 00 00 00       	call   80107e91 <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80107e7e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107e82:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e85:	0f b6 00             	movzbl (%eax),%eax
80107e88:	84 c0                	test   %al,%al
80107e8a:	75 e1                	jne    80107e6d <uartinit+0xed>
80107e8c:	eb 01                	jmp    80107e8f <uartinit+0x10f>
  outb(COM1+4, 0);
  outb(COM1+1, 0x01);    // Enable receive interrupts.

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
    return;
80107e8e:	90                   	nop
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
    uartputc(*p);
}
80107e8f:	c9                   	leave  
80107e90:	c3                   	ret    

80107e91 <uartputc>:

void
uartputc(int c)
{
80107e91:	55                   	push   %ebp
80107e92:	89 e5                	mov    %esp,%ebp
80107e94:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
80107e97:	a1 74 d6 10 80       	mov    0x8010d674,%eax
80107e9c:	85 c0                	test   %eax,%eax
80107e9e:	74 4d                	je     80107eed <uartputc+0x5c>
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80107ea0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80107ea7:	eb 10                	jmp    80107eb9 <uartputc+0x28>
    microdelay(10);
80107ea9:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
80107eb0:	e8 65 ba ff ff       	call   8010391a <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80107eb5:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107eb9:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
80107ebd:	7f 16                	jg     80107ed5 <uartputc+0x44>
80107ebf:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80107ec6:	e8 6d fe ff ff       	call   80107d38 <inb>
80107ecb:	0f b6 c0             	movzbl %al,%eax
80107ece:	83 e0 20             	and    $0x20,%eax
80107ed1:	85 c0                	test   %eax,%eax
80107ed3:	74 d4                	je     80107ea9 <uartputc+0x18>
    microdelay(10);
  outb(COM1+0, c);
80107ed5:	8b 45 08             	mov    0x8(%ebp),%eax
80107ed8:	0f b6 c0             	movzbl %al,%eax
80107edb:	89 44 24 04          	mov    %eax,0x4(%esp)
80107edf:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107ee6:	e8 77 fe ff ff       	call   80107d62 <outb>
80107eeb:	eb 01                	jmp    80107eee <uartputc+0x5d>
uartputc(int c)
{
  int i;

  if(!uart)
    return;
80107eed:	90                   	nop
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
    microdelay(10);
  outb(COM1+0, c);
}
80107eee:	c9                   	leave  
80107eef:	c3                   	ret    

80107ef0 <uartgetc>:

static int
uartgetc(void)
{
80107ef0:	55                   	push   %ebp
80107ef1:	89 e5                	mov    %esp,%ebp
80107ef3:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
80107ef6:	a1 74 d6 10 80       	mov    0x8010d674,%eax
80107efb:	85 c0                	test   %eax,%eax
80107efd:	75 07                	jne    80107f06 <uartgetc+0x16>
    return -1;
80107eff:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107f04:	eb 2c                	jmp    80107f32 <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
80107f06:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80107f0d:	e8 26 fe ff ff       	call   80107d38 <inb>
80107f12:	0f b6 c0             	movzbl %al,%eax
80107f15:	83 e0 01             	and    $0x1,%eax
80107f18:	85 c0                	test   %eax,%eax
80107f1a:	75 07                	jne    80107f23 <uartgetc+0x33>
    return -1;
80107f1c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107f21:	eb 0f                	jmp    80107f32 <uartgetc+0x42>
  return inb(COM1+0);
80107f23:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107f2a:	e8 09 fe ff ff       	call   80107d38 <inb>
80107f2f:	0f b6 c0             	movzbl %al,%eax
}
80107f32:	c9                   	leave  
80107f33:	c3                   	ret    

80107f34 <uartintr>:

void
uartintr(void)
{
80107f34:	55                   	push   %ebp
80107f35:	89 e5                	mov    %esp,%ebp
80107f37:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
80107f3a:	c7 04 24 f0 7e 10 80 	movl   $0x80107ef0,(%esp)
80107f41:	e8 67 88 ff ff       	call   801007ad <consoleintr>
}
80107f46:	c9                   	leave  
80107f47:	c3                   	ret    

80107f48 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80107f48:	6a 00                	push   $0x0
  pushl $0
80107f4a:	6a 00                	push   $0x0
  jmp alltraps
80107f4c:	e9 67 f9 ff ff       	jmp    801078b8 <alltraps>

80107f51 <vector1>:
.globl vector1
vector1:
  pushl $0
80107f51:	6a 00                	push   $0x0
  pushl $1
80107f53:	6a 01                	push   $0x1
  jmp alltraps
80107f55:	e9 5e f9 ff ff       	jmp    801078b8 <alltraps>

80107f5a <vector2>:
.globl vector2
vector2:
  pushl $0
80107f5a:	6a 00                	push   $0x0
  pushl $2
80107f5c:	6a 02                	push   $0x2
  jmp alltraps
80107f5e:	e9 55 f9 ff ff       	jmp    801078b8 <alltraps>

80107f63 <vector3>:
.globl vector3
vector3:
  pushl $0
80107f63:	6a 00                	push   $0x0
  pushl $3
80107f65:	6a 03                	push   $0x3
  jmp alltraps
80107f67:	e9 4c f9 ff ff       	jmp    801078b8 <alltraps>

80107f6c <vector4>:
.globl vector4
vector4:
  pushl $0
80107f6c:	6a 00                	push   $0x0
  pushl $4
80107f6e:	6a 04                	push   $0x4
  jmp alltraps
80107f70:	e9 43 f9 ff ff       	jmp    801078b8 <alltraps>

80107f75 <vector5>:
.globl vector5
vector5:
  pushl $0
80107f75:	6a 00                	push   $0x0
  pushl $5
80107f77:	6a 05                	push   $0x5
  jmp alltraps
80107f79:	e9 3a f9 ff ff       	jmp    801078b8 <alltraps>

80107f7e <vector6>:
.globl vector6
vector6:
  pushl $0
80107f7e:	6a 00                	push   $0x0
  pushl $6
80107f80:	6a 06                	push   $0x6
  jmp alltraps
80107f82:	e9 31 f9 ff ff       	jmp    801078b8 <alltraps>

80107f87 <vector7>:
.globl vector7
vector7:
  pushl $0
80107f87:	6a 00                	push   $0x0
  pushl $7
80107f89:	6a 07                	push   $0x7
  jmp alltraps
80107f8b:	e9 28 f9 ff ff       	jmp    801078b8 <alltraps>

80107f90 <vector8>:
.globl vector8
vector8:
  pushl $8
80107f90:	6a 08                	push   $0x8
  jmp alltraps
80107f92:	e9 21 f9 ff ff       	jmp    801078b8 <alltraps>

80107f97 <vector9>:
.globl vector9
vector9:
  pushl $0
80107f97:	6a 00                	push   $0x0
  pushl $9
80107f99:	6a 09                	push   $0x9
  jmp alltraps
80107f9b:	e9 18 f9 ff ff       	jmp    801078b8 <alltraps>

80107fa0 <vector10>:
.globl vector10
vector10:
  pushl $10
80107fa0:	6a 0a                	push   $0xa
  jmp alltraps
80107fa2:	e9 11 f9 ff ff       	jmp    801078b8 <alltraps>

80107fa7 <vector11>:
.globl vector11
vector11:
  pushl $11
80107fa7:	6a 0b                	push   $0xb
  jmp alltraps
80107fa9:	e9 0a f9 ff ff       	jmp    801078b8 <alltraps>

80107fae <vector12>:
.globl vector12
vector12:
  pushl $12
80107fae:	6a 0c                	push   $0xc
  jmp alltraps
80107fb0:	e9 03 f9 ff ff       	jmp    801078b8 <alltraps>

80107fb5 <vector13>:
.globl vector13
vector13:
  pushl $13
80107fb5:	6a 0d                	push   $0xd
  jmp alltraps
80107fb7:	e9 fc f8 ff ff       	jmp    801078b8 <alltraps>

80107fbc <vector14>:
.globl vector14
vector14:
  pushl $14
80107fbc:	6a 0e                	push   $0xe
  jmp alltraps
80107fbe:	e9 f5 f8 ff ff       	jmp    801078b8 <alltraps>

80107fc3 <vector15>:
.globl vector15
vector15:
  pushl $0
80107fc3:	6a 00                	push   $0x0
  pushl $15
80107fc5:	6a 0f                	push   $0xf
  jmp alltraps
80107fc7:	e9 ec f8 ff ff       	jmp    801078b8 <alltraps>

80107fcc <vector16>:
.globl vector16
vector16:
  pushl $0
80107fcc:	6a 00                	push   $0x0
  pushl $16
80107fce:	6a 10                	push   $0x10
  jmp alltraps
80107fd0:	e9 e3 f8 ff ff       	jmp    801078b8 <alltraps>

80107fd5 <vector17>:
.globl vector17
vector17:
  pushl $17
80107fd5:	6a 11                	push   $0x11
  jmp alltraps
80107fd7:	e9 dc f8 ff ff       	jmp    801078b8 <alltraps>

80107fdc <vector18>:
.globl vector18
vector18:
  pushl $0
80107fdc:	6a 00                	push   $0x0
  pushl $18
80107fde:	6a 12                	push   $0x12
  jmp alltraps
80107fe0:	e9 d3 f8 ff ff       	jmp    801078b8 <alltraps>

80107fe5 <vector19>:
.globl vector19
vector19:
  pushl $0
80107fe5:	6a 00                	push   $0x0
  pushl $19
80107fe7:	6a 13                	push   $0x13
  jmp alltraps
80107fe9:	e9 ca f8 ff ff       	jmp    801078b8 <alltraps>

80107fee <vector20>:
.globl vector20
vector20:
  pushl $0
80107fee:	6a 00                	push   $0x0
  pushl $20
80107ff0:	6a 14                	push   $0x14
  jmp alltraps
80107ff2:	e9 c1 f8 ff ff       	jmp    801078b8 <alltraps>

80107ff7 <vector21>:
.globl vector21
vector21:
  pushl $0
80107ff7:	6a 00                	push   $0x0
  pushl $21
80107ff9:	6a 15                	push   $0x15
  jmp alltraps
80107ffb:	e9 b8 f8 ff ff       	jmp    801078b8 <alltraps>

80108000 <vector22>:
.globl vector22
vector22:
  pushl $0
80108000:	6a 00                	push   $0x0
  pushl $22
80108002:	6a 16                	push   $0x16
  jmp alltraps
80108004:	e9 af f8 ff ff       	jmp    801078b8 <alltraps>

80108009 <vector23>:
.globl vector23
vector23:
  pushl $0
80108009:	6a 00                	push   $0x0
  pushl $23
8010800b:	6a 17                	push   $0x17
  jmp alltraps
8010800d:	e9 a6 f8 ff ff       	jmp    801078b8 <alltraps>

80108012 <vector24>:
.globl vector24
vector24:
  pushl $0
80108012:	6a 00                	push   $0x0
  pushl $24
80108014:	6a 18                	push   $0x18
  jmp alltraps
80108016:	e9 9d f8 ff ff       	jmp    801078b8 <alltraps>

8010801b <vector25>:
.globl vector25
vector25:
  pushl $0
8010801b:	6a 00                	push   $0x0
  pushl $25
8010801d:	6a 19                	push   $0x19
  jmp alltraps
8010801f:	e9 94 f8 ff ff       	jmp    801078b8 <alltraps>

80108024 <vector26>:
.globl vector26
vector26:
  pushl $0
80108024:	6a 00                	push   $0x0
  pushl $26
80108026:	6a 1a                	push   $0x1a
  jmp alltraps
80108028:	e9 8b f8 ff ff       	jmp    801078b8 <alltraps>

8010802d <vector27>:
.globl vector27
vector27:
  pushl $0
8010802d:	6a 00                	push   $0x0
  pushl $27
8010802f:	6a 1b                	push   $0x1b
  jmp alltraps
80108031:	e9 82 f8 ff ff       	jmp    801078b8 <alltraps>

80108036 <vector28>:
.globl vector28
vector28:
  pushl $0
80108036:	6a 00                	push   $0x0
  pushl $28
80108038:	6a 1c                	push   $0x1c
  jmp alltraps
8010803a:	e9 79 f8 ff ff       	jmp    801078b8 <alltraps>

8010803f <vector29>:
.globl vector29
vector29:
  pushl $0
8010803f:	6a 00                	push   $0x0
  pushl $29
80108041:	6a 1d                	push   $0x1d
  jmp alltraps
80108043:	e9 70 f8 ff ff       	jmp    801078b8 <alltraps>

80108048 <vector30>:
.globl vector30
vector30:
  pushl $0
80108048:	6a 00                	push   $0x0
  pushl $30
8010804a:	6a 1e                	push   $0x1e
  jmp alltraps
8010804c:	e9 67 f8 ff ff       	jmp    801078b8 <alltraps>

80108051 <vector31>:
.globl vector31
vector31:
  pushl $0
80108051:	6a 00                	push   $0x0
  pushl $31
80108053:	6a 1f                	push   $0x1f
  jmp alltraps
80108055:	e9 5e f8 ff ff       	jmp    801078b8 <alltraps>

8010805a <vector32>:
.globl vector32
vector32:
  pushl $0
8010805a:	6a 00                	push   $0x0
  pushl $32
8010805c:	6a 20                	push   $0x20
  jmp alltraps
8010805e:	e9 55 f8 ff ff       	jmp    801078b8 <alltraps>

80108063 <vector33>:
.globl vector33
vector33:
  pushl $0
80108063:	6a 00                	push   $0x0
  pushl $33
80108065:	6a 21                	push   $0x21
  jmp alltraps
80108067:	e9 4c f8 ff ff       	jmp    801078b8 <alltraps>

8010806c <vector34>:
.globl vector34
vector34:
  pushl $0
8010806c:	6a 00                	push   $0x0
  pushl $34
8010806e:	6a 22                	push   $0x22
  jmp alltraps
80108070:	e9 43 f8 ff ff       	jmp    801078b8 <alltraps>

80108075 <vector35>:
.globl vector35
vector35:
  pushl $0
80108075:	6a 00                	push   $0x0
  pushl $35
80108077:	6a 23                	push   $0x23
  jmp alltraps
80108079:	e9 3a f8 ff ff       	jmp    801078b8 <alltraps>

8010807e <vector36>:
.globl vector36
vector36:
  pushl $0
8010807e:	6a 00                	push   $0x0
  pushl $36
80108080:	6a 24                	push   $0x24
  jmp alltraps
80108082:	e9 31 f8 ff ff       	jmp    801078b8 <alltraps>

80108087 <vector37>:
.globl vector37
vector37:
  pushl $0
80108087:	6a 00                	push   $0x0
  pushl $37
80108089:	6a 25                	push   $0x25
  jmp alltraps
8010808b:	e9 28 f8 ff ff       	jmp    801078b8 <alltraps>

80108090 <vector38>:
.globl vector38
vector38:
  pushl $0
80108090:	6a 00                	push   $0x0
  pushl $38
80108092:	6a 26                	push   $0x26
  jmp alltraps
80108094:	e9 1f f8 ff ff       	jmp    801078b8 <alltraps>

80108099 <vector39>:
.globl vector39
vector39:
  pushl $0
80108099:	6a 00                	push   $0x0
  pushl $39
8010809b:	6a 27                	push   $0x27
  jmp alltraps
8010809d:	e9 16 f8 ff ff       	jmp    801078b8 <alltraps>

801080a2 <vector40>:
.globl vector40
vector40:
  pushl $0
801080a2:	6a 00                	push   $0x0
  pushl $40
801080a4:	6a 28                	push   $0x28
  jmp alltraps
801080a6:	e9 0d f8 ff ff       	jmp    801078b8 <alltraps>

801080ab <vector41>:
.globl vector41
vector41:
  pushl $0
801080ab:	6a 00                	push   $0x0
  pushl $41
801080ad:	6a 29                	push   $0x29
  jmp alltraps
801080af:	e9 04 f8 ff ff       	jmp    801078b8 <alltraps>

801080b4 <vector42>:
.globl vector42
vector42:
  pushl $0
801080b4:	6a 00                	push   $0x0
  pushl $42
801080b6:	6a 2a                	push   $0x2a
  jmp alltraps
801080b8:	e9 fb f7 ff ff       	jmp    801078b8 <alltraps>

801080bd <vector43>:
.globl vector43
vector43:
  pushl $0
801080bd:	6a 00                	push   $0x0
  pushl $43
801080bf:	6a 2b                	push   $0x2b
  jmp alltraps
801080c1:	e9 f2 f7 ff ff       	jmp    801078b8 <alltraps>

801080c6 <vector44>:
.globl vector44
vector44:
  pushl $0
801080c6:	6a 00                	push   $0x0
  pushl $44
801080c8:	6a 2c                	push   $0x2c
  jmp alltraps
801080ca:	e9 e9 f7 ff ff       	jmp    801078b8 <alltraps>

801080cf <vector45>:
.globl vector45
vector45:
  pushl $0
801080cf:	6a 00                	push   $0x0
  pushl $45
801080d1:	6a 2d                	push   $0x2d
  jmp alltraps
801080d3:	e9 e0 f7 ff ff       	jmp    801078b8 <alltraps>

801080d8 <vector46>:
.globl vector46
vector46:
  pushl $0
801080d8:	6a 00                	push   $0x0
  pushl $46
801080da:	6a 2e                	push   $0x2e
  jmp alltraps
801080dc:	e9 d7 f7 ff ff       	jmp    801078b8 <alltraps>

801080e1 <vector47>:
.globl vector47
vector47:
  pushl $0
801080e1:	6a 00                	push   $0x0
  pushl $47
801080e3:	6a 2f                	push   $0x2f
  jmp alltraps
801080e5:	e9 ce f7 ff ff       	jmp    801078b8 <alltraps>

801080ea <vector48>:
.globl vector48
vector48:
  pushl $0
801080ea:	6a 00                	push   $0x0
  pushl $48
801080ec:	6a 30                	push   $0x30
  jmp alltraps
801080ee:	e9 c5 f7 ff ff       	jmp    801078b8 <alltraps>

801080f3 <vector49>:
.globl vector49
vector49:
  pushl $0
801080f3:	6a 00                	push   $0x0
  pushl $49
801080f5:	6a 31                	push   $0x31
  jmp alltraps
801080f7:	e9 bc f7 ff ff       	jmp    801078b8 <alltraps>

801080fc <vector50>:
.globl vector50
vector50:
  pushl $0
801080fc:	6a 00                	push   $0x0
  pushl $50
801080fe:	6a 32                	push   $0x32
  jmp alltraps
80108100:	e9 b3 f7 ff ff       	jmp    801078b8 <alltraps>

80108105 <vector51>:
.globl vector51
vector51:
  pushl $0
80108105:	6a 00                	push   $0x0
  pushl $51
80108107:	6a 33                	push   $0x33
  jmp alltraps
80108109:	e9 aa f7 ff ff       	jmp    801078b8 <alltraps>

8010810e <vector52>:
.globl vector52
vector52:
  pushl $0
8010810e:	6a 00                	push   $0x0
  pushl $52
80108110:	6a 34                	push   $0x34
  jmp alltraps
80108112:	e9 a1 f7 ff ff       	jmp    801078b8 <alltraps>

80108117 <vector53>:
.globl vector53
vector53:
  pushl $0
80108117:	6a 00                	push   $0x0
  pushl $53
80108119:	6a 35                	push   $0x35
  jmp alltraps
8010811b:	e9 98 f7 ff ff       	jmp    801078b8 <alltraps>

80108120 <vector54>:
.globl vector54
vector54:
  pushl $0
80108120:	6a 00                	push   $0x0
  pushl $54
80108122:	6a 36                	push   $0x36
  jmp alltraps
80108124:	e9 8f f7 ff ff       	jmp    801078b8 <alltraps>

80108129 <vector55>:
.globl vector55
vector55:
  pushl $0
80108129:	6a 00                	push   $0x0
  pushl $55
8010812b:	6a 37                	push   $0x37
  jmp alltraps
8010812d:	e9 86 f7 ff ff       	jmp    801078b8 <alltraps>

80108132 <vector56>:
.globl vector56
vector56:
  pushl $0
80108132:	6a 00                	push   $0x0
  pushl $56
80108134:	6a 38                	push   $0x38
  jmp alltraps
80108136:	e9 7d f7 ff ff       	jmp    801078b8 <alltraps>

8010813b <vector57>:
.globl vector57
vector57:
  pushl $0
8010813b:	6a 00                	push   $0x0
  pushl $57
8010813d:	6a 39                	push   $0x39
  jmp alltraps
8010813f:	e9 74 f7 ff ff       	jmp    801078b8 <alltraps>

80108144 <vector58>:
.globl vector58
vector58:
  pushl $0
80108144:	6a 00                	push   $0x0
  pushl $58
80108146:	6a 3a                	push   $0x3a
  jmp alltraps
80108148:	e9 6b f7 ff ff       	jmp    801078b8 <alltraps>

8010814d <vector59>:
.globl vector59
vector59:
  pushl $0
8010814d:	6a 00                	push   $0x0
  pushl $59
8010814f:	6a 3b                	push   $0x3b
  jmp alltraps
80108151:	e9 62 f7 ff ff       	jmp    801078b8 <alltraps>

80108156 <vector60>:
.globl vector60
vector60:
  pushl $0
80108156:	6a 00                	push   $0x0
  pushl $60
80108158:	6a 3c                	push   $0x3c
  jmp alltraps
8010815a:	e9 59 f7 ff ff       	jmp    801078b8 <alltraps>

8010815f <vector61>:
.globl vector61
vector61:
  pushl $0
8010815f:	6a 00                	push   $0x0
  pushl $61
80108161:	6a 3d                	push   $0x3d
  jmp alltraps
80108163:	e9 50 f7 ff ff       	jmp    801078b8 <alltraps>

80108168 <vector62>:
.globl vector62
vector62:
  pushl $0
80108168:	6a 00                	push   $0x0
  pushl $62
8010816a:	6a 3e                	push   $0x3e
  jmp alltraps
8010816c:	e9 47 f7 ff ff       	jmp    801078b8 <alltraps>

80108171 <vector63>:
.globl vector63
vector63:
  pushl $0
80108171:	6a 00                	push   $0x0
  pushl $63
80108173:	6a 3f                	push   $0x3f
  jmp alltraps
80108175:	e9 3e f7 ff ff       	jmp    801078b8 <alltraps>

8010817a <vector64>:
.globl vector64
vector64:
  pushl $0
8010817a:	6a 00                	push   $0x0
  pushl $64
8010817c:	6a 40                	push   $0x40
  jmp alltraps
8010817e:	e9 35 f7 ff ff       	jmp    801078b8 <alltraps>

80108183 <vector65>:
.globl vector65
vector65:
  pushl $0
80108183:	6a 00                	push   $0x0
  pushl $65
80108185:	6a 41                	push   $0x41
  jmp alltraps
80108187:	e9 2c f7 ff ff       	jmp    801078b8 <alltraps>

8010818c <vector66>:
.globl vector66
vector66:
  pushl $0
8010818c:	6a 00                	push   $0x0
  pushl $66
8010818e:	6a 42                	push   $0x42
  jmp alltraps
80108190:	e9 23 f7 ff ff       	jmp    801078b8 <alltraps>

80108195 <vector67>:
.globl vector67
vector67:
  pushl $0
80108195:	6a 00                	push   $0x0
  pushl $67
80108197:	6a 43                	push   $0x43
  jmp alltraps
80108199:	e9 1a f7 ff ff       	jmp    801078b8 <alltraps>

8010819e <vector68>:
.globl vector68
vector68:
  pushl $0
8010819e:	6a 00                	push   $0x0
  pushl $68
801081a0:	6a 44                	push   $0x44
  jmp alltraps
801081a2:	e9 11 f7 ff ff       	jmp    801078b8 <alltraps>

801081a7 <vector69>:
.globl vector69
vector69:
  pushl $0
801081a7:	6a 00                	push   $0x0
  pushl $69
801081a9:	6a 45                	push   $0x45
  jmp alltraps
801081ab:	e9 08 f7 ff ff       	jmp    801078b8 <alltraps>

801081b0 <vector70>:
.globl vector70
vector70:
  pushl $0
801081b0:	6a 00                	push   $0x0
  pushl $70
801081b2:	6a 46                	push   $0x46
  jmp alltraps
801081b4:	e9 ff f6 ff ff       	jmp    801078b8 <alltraps>

801081b9 <vector71>:
.globl vector71
vector71:
  pushl $0
801081b9:	6a 00                	push   $0x0
  pushl $71
801081bb:	6a 47                	push   $0x47
  jmp alltraps
801081bd:	e9 f6 f6 ff ff       	jmp    801078b8 <alltraps>

801081c2 <vector72>:
.globl vector72
vector72:
  pushl $0
801081c2:	6a 00                	push   $0x0
  pushl $72
801081c4:	6a 48                	push   $0x48
  jmp alltraps
801081c6:	e9 ed f6 ff ff       	jmp    801078b8 <alltraps>

801081cb <vector73>:
.globl vector73
vector73:
  pushl $0
801081cb:	6a 00                	push   $0x0
  pushl $73
801081cd:	6a 49                	push   $0x49
  jmp alltraps
801081cf:	e9 e4 f6 ff ff       	jmp    801078b8 <alltraps>

801081d4 <vector74>:
.globl vector74
vector74:
  pushl $0
801081d4:	6a 00                	push   $0x0
  pushl $74
801081d6:	6a 4a                	push   $0x4a
  jmp alltraps
801081d8:	e9 db f6 ff ff       	jmp    801078b8 <alltraps>

801081dd <vector75>:
.globl vector75
vector75:
  pushl $0
801081dd:	6a 00                	push   $0x0
  pushl $75
801081df:	6a 4b                	push   $0x4b
  jmp alltraps
801081e1:	e9 d2 f6 ff ff       	jmp    801078b8 <alltraps>

801081e6 <vector76>:
.globl vector76
vector76:
  pushl $0
801081e6:	6a 00                	push   $0x0
  pushl $76
801081e8:	6a 4c                	push   $0x4c
  jmp alltraps
801081ea:	e9 c9 f6 ff ff       	jmp    801078b8 <alltraps>

801081ef <vector77>:
.globl vector77
vector77:
  pushl $0
801081ef:	6a 00                	push   $0x0
  pushl $77
801081f1:	6a 4d                	push   $0x4d
  jmp alltraps
801081f3:	e9 c0 f6 ff ff       	jmp    801078b8 <alltraps>

801081f8 <vector78>:
.globl vector78
vector78:
  pushl $0
801081f8:	6a 00                	push   $0x0
  pushl $78
801081fa:	6a 4e                	push   $0x4e
  jmp alltraps
801081fc:	e9 b7 f6 ff ff       	jmp    801078b8 <alltraps>

80108201 <vector79>:
.globl vector79
vector79:
  pushl $0
80108201:	6a 00                	push   $0x0
  pushl $79
80108203:	6a 4f                	push   $0x4f
  jmp alltraps
80108205:	e9 ae f6 ff ff       	jmp    801078b8 <alltraps>

8010820a <vector80>:
.globl vector80
vector80:
  pushl $0
8010820a:	6a 00                	push   $0x0
  pushl $80
8010820c:	6a 50                	push   $0x50
  jmp alltraps
8010820e:	e9 a5 f6 ff ff       	jmp    801078b8 <alltraps>

80108213 <vector81>:
.globl vector81
vector81:
  pushl $0
80108213:	6a 00                	push   $0x0
  pushl $81
80108215:	6a 51                	push   $0x51
  jmp alltraps
80108217:	e9 9c f6 ff ff       	jmp    801078b8 <alltraps>

8010821c <vector82>:
.globl vector82
vector82:
  pushl $0
8010821c:	6a 00                	push   $0x0
  pushl $82
8010821e:	6a 52                	push   $0x52
  jmp alltraps
80108220:	e9 93 f6 ff ff       	jmp    801078b8 <alltraps>

80108225 <vector83>:
.globl vector83
vector83:
  pushl $0
80108225:	6a 00                	push   $0x0
  pushl $83
80108227:	6a 53                	push   $0x53
  jmp alltraps
80108229:	e9 8a f6 ff ff       	jmp    801078b8 <alltraps>

8010822e <vector84>:
.globl vector84
vector84:
  pushl $0
8010822e:	6a 00                	push   $0x0
  pushl $84
80108230:	6a 54                	push   $0x54
  jmp alltraps
80108232:	e9 81 f6 ff ff       	jmp    801078b8 <alltraps>

80108237 <vector85>:
.globl vector85
vector85:
  pushl $0
80108237:	6a 00                	push   $0x0
  pushl $85
80108239:	6a 55                	push   $0x55
  jmp alltraps
8010823b:	e9 78 f6 ff ff       	jmp    801078b8 <alltraps>

80108240 <vector86>:
.globl vector86
vector86:
  pushl $0
80108240:	6a 00                	push   $0x0
  pushl $86
80108242:	6a 56                	push   $0x56
  jmp alltraps
80108244:	e9 6f f6 ff ff       	jmp    801078b8 <alltraps>

80108249 <vector87>:
.globl vector87
vector87:
  pushl $0
80108249:	6a 00                	push   $0x0
  pushl $87
8010824b:	6a 57                	push   $0x57
  jmp alltraps
8010824d:	e9 66 f6 ff ff       	jmp    801078b8 <alltraps>

80108252 <vector88>:
.globl vector88
vector88:
  pushl $0
80108252:	6a 00                	push   $0x0
  pushl $88
80108254:	6a 58                	push   $0x58
  jmp alltraps
80108256:	e9 5d f6 ff ff       	jmp    801078b8 <alltraps>

8010825b <vector89>:
.globl vector89
vector89:
  pushl $0
8010825b:	6a 00                	push   $0x0
  pushl $89
8010825d:	6a 59                	push   $0x59
  jmp alltraps
8010825f:	e9 54 f6 ff ff       	jmp    801078b8 <alltraps>

80108264 <vector90>:
.globl vector90
vector90:
  pushl $0
80108264:	6a 00                	push   $0x0
  pushl $90
80108266:	6a 5a                	push   $0x5a
  jmp alltraps
80108268:	e9 4b f6 ff ff       	jmp    801078b8 <alltraps>

8010826d <vector91>:
.globl vector91
vector91:
  pushl $0
8010826d:	6a 00                	push   $0x0
  pushl $91
8010826f:	6a 5b                	push   $0x5b
  jmp alltraps
80108271:	e9 42 f6 ff ff       	jmp    801078b8 <alltraps>

80108276 <vector92>:
.globl vector92
vector92:
  pushl $0
80108276:	6a 00                	push   $0x0
  pushl $92
80108278:	6a 5c                	push   $0x5c
  jmp alltraps
8010827a:	e9 39 f6 ff ff       	jmp    801078b8 <alltraps>

8010827f <vector93>:
.globl vector93
vector93:
  pushl $0
8010827f:	6a 00                	push   $0x0
  pushl $93
80108281:	6a 5d                	push   $0x5d
  jmp alltraps
80108283:	e9 30 f6 ff ff       	jmp    801078b8 <alltraps>

80108288 <vector94>:
.globl vector94
vector94:
  pushl $0
80108288:	6a 00                	push   $0x0
  pushl $94
8010828a:	6a 5e                	push   $0x5e
  jmp alltraps
8010828c:	e9 27 f6 ff ff       	jmp    801078b8 <alltraps>

80108291 <vector95>:
.globl vector95
vector95:
  pushl $0
80108291:	6a 00                	push   $0x0
  pushl $95
80108293:	6a 5f                	push   $0x5f
  jmp alltraps
80108295:	e9 1e f6 ff ff       	jmp    801078b8 <alltraps>

8010829a <vector96>:
.globl vector96
vector96:
  pushl $0
8010829a:	6a 00                	push   $0x0
  pushl $96
8010829c:	6a 60                	push   $0x60
  jmp alltraps
8010829e:	e9 15 f6 ff ff       	jmp    801078b8 <alltraps>

801082a3 <vector97>:
.globl vector97
vector97:
  pushl $0
801082a3:	6a 00                	push   $0x0
  pushl $97
801082a5:	6a 61                	push   $0x61
  jmp alltraps
801082a7:	e9 0c f6 ff ff       	jmp    801078b8 <alltraps>

801082ac <vector98>:
.globl vector98
vector98:
  pushl $0
801082ac:	6a 00                	push   $0x0
  pushl $98
801082ae:	6a 62                	push   $0x62
  jmp alltraps
801082b0:	e9 03 f6 ff ff       	jmp    801078b8 <alltraps>

801082b5 <vector99>:
.globl vector99
vector99:
  pushl $0
801082b5:	6a 00                	push   $0x0
  pushl $99
801082b7:	6a 63                	push   $0x63
  jmp alltraps
801082b9:	e9 fa f5 ff ff       	jmp    801078b8 <alltraps>

801082be <vector100>:
.globl vector100
vector100:
  pushl $0
801082be:	6a 00                	push   $0x0
  pushl $100
801082c0:	6a 64                	push   $0x64
  jmp alltraps
801082c2:	e9 f1 f5 ff ff       	jmp    801078b8 <alltraps>

801082c7 <vector101>:
.globl vector101
vector101:
  pushl $0
801082c7:	6a 00                	push   $0x0
  pushl $101
801082c9:	6a 65                	push   $0x65
  jmp alltraps
801082cb:	e9 e8 f5 ff ff       	jmp    801078b8 <alltraps>

801082d0 <vector102>:
.globl vector102
vector102:
  pushl $0
801082d0:	6a 00                	push   $0x0
  pushl $102
801082d2:	6a 66                	push   $0x66
  jmp alltraps
801082d4:	e9 df f5 ff ff       	jmp    801078b8 <alltraps>

801082d9 <vector103>:
.globl vector103
vector103:
  pushl $0
801082d9:	6a 00                	push   $0x0
  pushl $103
801082db:	6a 67                	push   $0x67
  jmp alltraps
801082dd:	e9 d6 f5 ff ff       	jmp    801078b8 <alltraps>

801082e2 <vector104>:
.globl vector104
vector104:
  pushl $0
801082e2:	6a 00                	push   $0x0
  pushl $104
801082e4:	6a 68                	push   $0x68
  jmp alltraps
801082e6:	e9 cd f5 ff ff       	jmp    801078b8 <alltraps>

801082eb <vector105>:
.globl vector105
vector105:
  pushl $0
801082eb:	6a 00                	push   $0x0
  pushl $105
801082ed:	6a 69                	push   $0x69
  jmp alltraps
801082ef:	e9 c4 f5 ff ff       	jmp    801078b8 <alltraps>

801082f4 <vector106>:
.globl vector106
vector106:
  pushl $0
801082f4:	6a 00                	push   $0x0
  pushl $106
801082f6:	6a 6a                	push   $0x6a
  jmp alltraps
801082f8:	e9 bb f5 ff ff       	jmp    801078b8 <alltraps>

801082fd <vector107>:
.globl vector107
vector107:
  pushl $0
801082fd:	6a 00                	push   $0x0
  pushl $107
801082ff:	6a 6b                	push   $0x6b
  jmp alltraps
80108301:	e9 b2 f5 ff ff       	jmp    801078b8 <alltraps>

80108306 <vector108>:
.globl vector108
vector108:
  pushl $0
80108306:	6a 00                	push   $0x0
  pushl $108
80108308:	6a 6c                	push   $0x6c
  jmp alltraps
8010830a:	e9 a9 f5 ff ff       	jmp    801078b8 <alltraps>

8010830f <vector109>:
.globl vector109
vector109:
  pushl $0
8010830f:	6a 00                	push   $0x0
  pushl $109
80108311:	6a 6d                	push   $0x6d
  jmp alltraps
80108313:	e9 a0 f5 ff ff       	jmp    801078b8 <alltraps>

80108318 <vector110>:
.globl vector110
vector110:
  pushl $0
80108318:	6a 00                	push   $0x0
  pushl $110
8010831a:	6a 6e                	push   $0x6e
  jmp alltraps
8010831c:	e9 97 f5 ff ff       	jmp    801078b8 <alltraps>

80108321 <vector111>:
.globl vector111
vector111:
  pushl $0
80108321:	6a 00                	push   $0x0
  pushl $111
80108323:	6a 6f                	push   $0x6f
  jmp alltraps
80108325:	e9 8e f5 ff ff       	jmp    801078b8 <alltraps>

8010832a <vector112>:
.globl vector112
vector112:
  pushl $0
8010832a:	6a 00                	push   $0x0
  pushl $112
8010832c:	6a 70                	push   $0x70
  jmp alltraps
8010832e:	e9 85 f5 ff ff       	jmp    801078b8 <alltraps>

80108333 <vector113>:
.globl vector113
vector113:
  pushl $0
80108333:	6a 00                	push   $0x0
  pushl $113
80108335:	6a 71                	push   $0x71
  jmp alltraps
80108337:	e9 7c f5 ff ff       	jmp    801078b8 <alltraps>

8010833c <vector114>:
.globl vector114
vector114:
  pushl $0
8010833c:	6a 00                	push   $0x0
  pushl $114
8010833e:	6a 72                	push   $0x72
  jmp alltraps
80108340:	e9 73 f5 ff ff       	jmp    801078b8 <alltraps>

80108345 <vector115>:
.globl vector115
vector115:
  pushl $0
80108345:	6a 00                	push   $0x0
  pushl $115
80108347:	6a 73                	push   $0x73
  jmp alltraps
80108349:	e9 6a f5 ff ff       	jmp    801078b8 <alltraps>

8010834e <vector116>:
.globl vector116
vector116:
  pushl $0
8010834e:	6a 00                	push   $0x0
  pushl $116
80108350:	6a 74                	push   $0x74
  jmp alltraps
80108352:	e9 61 f5 ff ff       	jmp    801078b8 <alltraps>

80108357 <vector117>:
.globl vector117
vector117:
  pushl $0
80108357:	6a 00                	push   $0x0
  pushl $117
80108359:	6a 75                	push   $0x75
  jmp alltraps
8010835b:	e9 58 f5 ff ff       	jmp    801078b8 <alltraps>

80108360 <vector118>:
.globl vector118
vector118:
  pushl $0
80108360:	6a 00                	push   $0x0
  pushl $118
80108362:	6a 76                	push   $0x76
  jmp alltraps
80108364:	e9 4f f5 ff ff       	jmp    801078b8 <alltraps>

80108369 <vector119>:
.globl vector119
vector119:
  pushl $0
80108369:	6a 00                	push   $0x0
  pushl $119
8010836b:	6a 77                	push   $0x77
  jmp alltraps
8010836d:	e9 46 f5 ff ff       	jmp    801078b8 <alltraps>

80108372 <vector120>:
.globl vector120
vector120:
  pushl $0
80108372:	6a 00                	push   $0x0
  pushl $120
80108374:	6a 78                	push   $0x78
  jmp alltraps
80108376:	e9 3d f5 ff ff       	jmp    801078b8 <alltraps>

8010837b <vector121>:
.globl vector121
vector121:
  pushl $0
8010837b:	6a 00                	push   $0x0
  pushl $121
8010837d:	6a 79                	push   $0x79
  jmp alltraps
8010837f:	e9 34 f5 ff ff       	jmp    801078b8 <alltraps>

80108384 <vector122>:
.globl vector122
vector122:
  pushl $0
80108384:	6a 00                	push   $0x0
  pushl $122
80108386:	6a 7a                	push   $0x7a
  jmp alltraps
80108388:	e9 2b f5 ff ff       	jmp    801078b8 <alltraps>

8010838d <vector123>:
.globl vector123
vector123:
  pushl $0
8010838d:	6a 00                	push   $0x0
  pushl $123
8010838f:	6a 7b                	push   $0x7b
  jmp alltraps
80108391:	e9 22 f5 ff ff       	jmp    801078b8 <alltraps>

80108396 <vector124>:
.globl vector124
vector124:
  pushl $0
80108396:	6a 00                	push   $0x0
  pushl $124
80108398:	6a 7c                	push   $0x7c
  jmp alltraps
8010839a:	e9 19 f5 ff ff       	jmp    801078b8 <alltraps>

8010839f <vector125>:
.globl vector125
vector125:
  pushl $0
8010839f:	6a 00                	push   $0x0
  pushl $125
801083a1:	6a 7d                	push   $0x7d
  jmp alltraps
801083a3:	e9 10 f5 ff ff       	jmp    801078b8 <alltraps>

801083a8 <vector126>:
.globl vector126
vector126:
  pushl $0
801083a8:	6a 00                	push   $0x0
  pushl $126
801083aa:	6a 7e                	push   $0x7e
  jmp alltraps
801083ac:	e9 07 f5 ff ff       	jmp    801078b8 <alltraps>

801083b1 <vector127>:
.globl vector127
vector127:
  pushl $0
801083b1:	6a 00                	push   $0x0
  pushl $127
801083b3:	6a 7f                	push   $0x7f
  jmp alltraps
801083b5:	e9 fe f4 ff ff       	jmp    801078b8 <alltraps>

801083ba <vector128>:
.globl vector128
vector128:
  pushl $0
801083ba:	6a 00                	push   $0x0
  pushl $128
801083bc:	68 80 00 00 00       	push   $0x80
  jmp alltraps
801083c1:	e9 f2 f4 ff ff       	jmp    801078b8 <alltraps>

801083c6 <vector129>:
.globl vector129
vector129:
  pushl $0
801083c6:	6a 00                	push   $0x0
  pushl $129
801083c8:	68 81 00 00 00       	push   $0x81
  jmp alltraps
801083cd:	e9 e6 f4 ff ff       	jmp    801078b8 <alltraps>

801083d2 <vector130>:
.globl vector130
vector130:
  pushl $0
801083d2:	6a 00                	push   $0x0
  pushl $130
801083d4:	68 82 00 00 00       	push   $0x82
  jmp alltraps
801083d9:	e9 da f4 ff ff       	jmp    801078b8 <alltraps>

801083de <vector131>:
.globl vector131
vector131:
  pushl $0
801083de:	6a 00                	push   $0x0
  pushl $131
801083e0:	68 83 00 00 00       	push   $0x83
  jmp alltraps
801083e5:	e9 ce f4 ff ff       	jmp    801078b8 <alltraps>

801083ea <vector132>:
.globl vector132
vector132:
  pushl $0
801083ea:	6a 00                	push   $0x0
  pushl $132
801083ec:	68 84 00 00 00       	push   $0x84
  jmp alltraps
801083f1:	e9 c2 f4 ff ff       	jmp    801078b8 <alltraps>

801083f6 <vector133>:
.globl vector133
vector133:
  pushl $0
801083f6:	6a 00                	push   $0x0
  pushl $133
801083f8:	68 85 00 00 00       	push   $0x85
  jmp alltraps
801083fd:	e9 b6 f4 ff ff       	jmp    801078b8 <alltraps>

80108402 <vector134>:
.globl vector134
vector134:
  pushl $0
80108402:	6a 00                	push   $0x0
  pushl $134
80108404:	68 86 00 00 00       	push   $0x86
  jmp alltraps
80108409:	e9 aa f4 ff ff       	jmp    801078b8 <alltraps>

8010840e <vector135>:
.globl vector135
vector135:
  pushl $0
8010840e:	6a 00                	push   $0x0
  pushl $135
80108410:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80108415:	e9 9e f4 ff ff       	jmp    801078b8 <alltraps>

8010841a <vector136>:
.globl vector136
vector136:
  pushl $0
8010841a:	6a 00                	push   $0x0
  pushl $136
8010841c:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80108421:	e9 92 f4 ff ff       	jmp    801078b8 <alltraps>

80108426 <vector137>:
.globl vector137
vector137:
  pushl $0
80108426:	6a 00                	push   $0x0
  pushl $137
80108428:	68 89 00 00 00       	push   $0x89
  jmp alltraps
8010842d:	e9 86 f4 ff ff       	jmp    801078b8 <alltraps>

80108432 <vector138>:
.globl vector138
vector138:
  pushl $0
80108432:	6a 00                	push   $0x0
  pushl $138
80108434:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80108439:	e9 7a f4 ff ff       	jmp    801078b8 <alltraps>

8010843e <vector139>:
.globl vector139
vector139:
  pushl $0
8010843e:	6a 00                	push   $0x0
  pushl $139
80108440:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80108445:	e9 6e f4 ff ff       	jmp    801078b8 <alltraps>

8010844a <vector140>:
.globl vector140
vector140:
  pushl $0
8010844a:	6a 00                	push   $0x0
  pushl $140
8010844c:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
80108451:	e9 62 f4 ff ff       	jmp    801078b8 <alltraps>

80108456 <vector141>:
.globl vector141
vector141:
  pushl $0
80108456:	6a 00                	push   $0x0
  pushl $141
80108458:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
8010845d:	e9 56 f4 ff ff       	jmp    801078b8 <alltraps>

80108462 <vector142>:
.globl vector142
vector142:
  pushl $0
80108462:	6a 00                	push   $0x0
  pushl $142
80108464:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80108469:	e9 4a f4 ff ff       	jmp    801078b8 <alltraps>

8010846e <vector143>:
.globl vector143
vector143:
  pushl $0
8010846e:	6a 00                	push   $0x0
  pushl $143
80108470:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80108475:	e9 3e f4 ff ff       	jmp    801078b8 <alltraps>

8010847a <vector144>:
.globl vector144
vector144:
  pushl $0
8010847a:	6a 00                	push   $0x0
  pushl $144
8010847c:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80108481:	e9 32 f4 ff ff       	jmp    801078b8 <alltraps>

80108486 <vector145>:
.globl vector145
vector145:
  pushl $0
80108486:	6a 00                	push   $0x0
  pushl $145
80108488:	68 91 00 00 00       	push   $0x91
  jmp alltraps
8010848d:	e9 26 f4 ff ff       	jmp    801078b8 <alltraps>

80108492 <vector146>:
.globl vector146
vector146:
  pushl $0
80108492:	6a 00                	push   $0x0
  pushl $146
80108494:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80108499:	e9 1a f4 ff ff       	jmp    801078b8 <alltraps>

8010849e <vector147>:
.globl vector147
vector147:
  pushl $0
8010849e:	6a 00                	push   $0x0
  pushl $147
801084a0:	68 93 00 00 00       	push   $0x93
  jmp alltraps
801084a5:	e9 0e f4 ff ff       	jmp    801078b8 <alltraps>

801084aa <vector148>:
.globl vector148
vector148:
  pushl $0
801084aa:	6a 00                	push   $0x0
  pushl $148
801084ac:	68 94 00 00 00       	push   $0x94
  jmp alltraps
801084b1:	e9 02 f4 ff ff       	jmp    801078b8 <alltraps>

801084b6 <vector149>:
.globl vector149
vector149:
  pushl $0
801084b6:	6a 00                	push   $0x0
  pushl $149
801084b8:	68 95 00 00 00       	push   $0x95
  jmp alltraps
801084bd:	e9 f6 f3 ff ff       	jmp    801078b8 <alltraps>

801084c2 <vector150>:
.globl vector150
vector150:
  pushl $0
801084c2:	6a 00                	push   $0x0
  pushl $150
801084c4:	68 96 00 00 00       	push   $0x96
  jmp alltraps
801084c9:	e9 ea f3 ff ff       	jmp    801078b8 <alltraps>

801084ce <vector151>:
.globl vector151
vector151:
  pushl $0
801084ce:	6a 00                	push   $0x0
  pushl $151
801084d0:	68 97 00 00 00       	push   $0x97
  jmp alltraps
801084d5:	e9 de f3 ff ff       	jmp    801078b8 <alltraps>

801084da <vector152>:
.globl vector152
vector152:
  pushl $0
801084da:	6a 00                	push   $0x0
  pushl $152
801084dc:	68 98 00 00 00       	push   $0x98
  jmp alltraps
801084e1:	e9 d2 f3 ff ff       	jmp    801078b8 <alltraps>

801084e6 <vector153>:
.globl vector153
vector153:
  pushl $0
801084e6:	6a 00                	push   $0x0
  pushl $153
801084e8:	68 99 00 00 00       	push   $0x99
  jmp alltraps
801084ed:	e9 c6 f3 ff ff       	jmp    801078b8 <alltraps>

801084f2 <vector154>:
.globl vector154
vector154:
  pushl $0
801084f2:	6a 00                	push   $0x0
  pushl $154
801084f4:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
801084f9:	e9 ba f3 ff ff       	jmp    801078b8 <alltraps>

801084fe <vector155>:
.globl vector155
vector155:
  pushl $0
801084fe:	6a 00                	push   $0x0
  pushl $155
80108500:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80108505:	e9 ae f3 ff ff       	jmp    801078b8 <alltraps>

8010850a <vector156>:
.globl vector156
vector156:
  pushl $0
8010850a:	6a 00                	push   $0x0
  pushl $156
8010850c:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80108511:	e9 a2 f3 ff ff       	jmp    801078b8 <alltraps>

80108516 <vector157>:
.globl vector157
vector157:
  pushl $0
80108516:	6a 00                	push   $0x0
  pushl $157
80108518:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
8010851d:	e9 96 f3 ff ff       	jmp    801078b8 <alltraps>

80108522 <vector158>:
.globl vector158
vector158:
  pushl $0
80108522:	6a 00                	push   $0x0
  pushl $158
80108524:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80108529:	e9 8a f3 ff ff       	jmp    801078b8 <alltraps>

8010852e <vector159>:
.globl vector159
vector159:
  pushl $0
8010852e:	6a 00                	push   $0x0
  pushl $159
80108530:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80108535:	e9 7e f3 ff ff       	jmp    801078b8 <alltraps>

8010853a <vector160>:
.globl vector160
vector160:
  pushl $0
8010853a:	6a 00                	push   $0x0
  pushl $160
8010853c:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80108541:	e9 72 f3 ff ff       	jmp    801078b8 <alltraps>

80108546 <vector161>:
.globl vector161
vector161:
  pushl $0
80108546:	6a 00                	push   $0x0
  pushl $161
80108548:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
8010854d:	e9 66 f3 ff ff       	jmp    801078b8 <alltraps>

80108552 <vector162>:
.globl vector162
vector162:
  pushl $0
80108552:	6a 00                	push   $0x0
  pushl $162
80108554:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80108559:	e9 5a f3 ff ff       	jmp    801078b8 <alltraps>

8010855e <vector163>:
.globl vector163
vector163:
  pushl $0
8010855e:	6a 00                	push   $0x0
  pushl $163
80108560:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80108565:	e9 4e f3 ff ff       	jmp    801078b8 <alltraps>

8010856a <vector164>:
.globl vector164
vector164:
  pushl $0
8010856a:	6a 00                	push   $0x0
  pushl $164
8010856c:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80108571:	e9 42 f3 ff ff       	jmp    801078b8 <alltraps>

80108576 <vector165>:
.globl vector165
vector165:
  pushl $0
80108576:	6a 00                	push   $0x0
  pushl $165
80108578:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
8010857d:	e9 36 f3 ff ff       	jmp    801078b8 <alltraps>

80108582 <vector166>:
.globl vector166
vector166:
  pushl $0
80108582:	6a 00                	push   $0x0
  pushl $166
80108584:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80108589:	e9 2a f3 ff ff       	jmp    801078b8 <alltraps>

8010858e <vector167>:
.globl vector167
vector167:
  pushl $0
8010858e:	6a 00                	push   $0x0
  pushl $167
80108590:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80108595:	e9 1e f3 ff ff       	jmp    801078b8 <alltraps>

8010859a <vector168>:
.globl vector168
vector168:
  pushl $0
8010859a:	6a 00                	push   $0x0
  pushl $168
8010859c:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
801085a1:	e9 12 f3 ff ff       	jmp    801078b8 <alltraps>

801085a6 <vector169>:
.globl vector169
vector169:
  pushl $0
801085a6:	6a 00                	push   $0x0
  pushl $169
801085a8:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
801085ad:	e9 06 f3 ff ff       	jmp    801078b8 <alltraps>

801085b2 <vector170>:
.globl vector170
vector170:
  pushl $0
801085b2:	6a 00                	push   $0x0
  pushl $170
801085b4:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
801085b9:	e9 fa f2 ff ff       	jmp    801078b8 <alltraps>

801085be <vector171>:
.globl vector171
vector171:
  pushl $0
801085be:	6a 00                	push   $0x0
  pushl $171
801085c0:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
801085c5:	e9 ee f2 ff ff       	jmp    801078b8 <alltraps>

801085ca <vector172>:
.globl vector172
vector172:
  pushl $0
801085ca:	6a 00                	push   $0x0
  pushl $172
801085cc:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
801085d1:	e9 e2 f2 ff ff       	jmp    801078b8 <alltraps>

801085d6 <vector173>:
.globl vector173
vector173:
  pushl $0
801085d6:	6a 00                	push   $0x0
  pushl $173
801085d8:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
801085dd:	e9 d6 f2 ff ff       	jmp    801078b8 <alltraps>

801085e2 <vector174>:
.globl vector174
vector174:
  pushl $0
801085e2:	6a 00                	push   $0x0
  pushl $174
801085e4:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
801085e9:	e9 ca f2 ff ff       	jmp    801078b8 <alltraps>

801085ee <vector175>:
.globl vector175
vector175:
  pushl $0
801085ee:	6a 00                	push   $0x0
  pushl $175
801085f0:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
801085f5:	e9 be f2 ff ff       	jmp    801078b8 <alltraps>

801085fa <vector176>:
.globl vector176
vector176:
  pushl $0
801085fa:	6a 00                	push   $0x0
  pushl $176
801085fc:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80108601:	e9 b2 f2 ff ff       	jmp    801078b8 <alltraps>

80108606 <vector177>:
.globl vector177
vector177:
  pushl $0
80108606:	6a 00                	push   $0x0
  pushl $177
80108608:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
8010860d:	e9 a6 f2 ff ff       	jmp    801078b8 <alltraps>

80108612 <vector178>:
.globl vector178
vector178:
  pushl $0
80108612:	6a 00                	push   $0x0
  pushl $178
80108614:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80108619:	e9 9a f2 ff ff       	jmp    801078b8 <alltraps>

8010861e <vector179>:
.globl vector179
vector179:
  pushl $0
8010861e:	6a 00                	push   $0x0
  pushl $179
80108620:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80108625:	e9 8e f2 ff ff       	jmp    801078b8 <alltraps>

8010862a <vector180>:
.globl vector180
vector180:
  pushl $0
8010862a:	6a 00                	push   $0x0
  pushl $180
8010862c:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80108631:	e9 82 f2 ff ff       	jmp    801078b8 <alltraps>

80108636 <vector181>:
.globl vector181
vector181:
  pushl $0
80108636:	6a 00                	push   $0x0
  pushl $181
80108638:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
8010863d:	e9 76 f2 ff ff       	jmp    801078b8 <alltraps>

80108642 <vector182>:
.globl vector182
vector182:
  pushl $0
80108642:	6a 00                	push   $0x0
  pushl $182
80108644:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80108649:	e9 6a f2 ff ff       	jmp    801078b8 <alltraps>

8010864e <vector183>:
.globl vector183
vector183:
  pushl $0
8010864e:	6a 00                	push   $0x0
  pushl $183
80108650:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80108655:	e9 5e f2 ff ff       	jmp    801078b8 <alltraps>

8010865a <vector184>:
.globl vector184
vector184:
  pushl $0
8010865a:	6a 00                	push   $0x0
  pushl $184
8010865c:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80108661:	e9 52 f2 ff ff       	jmp    801078b8 <alltraps>

80108666 <vector185>:
.globl vector185
vector185:
  pushl $0
80108666:	6a 00                	push   $0x0
  pushl $185
80108668:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
8010866d:	e9 46 f2 ff ff       	jmp    801078b8 <alltraps>

80108672 <vector186>:
.globl vector186
vector186:
  pushl $0
80108672:	6a 00                	push   $0x0
  pushl $186
80108674:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80108679:	e9 3a f2 ff ff       	jmp    801078b8 <alltraps>

8010867e <vector187>:
.globl vector187
vector187:
  pushl $0
8010867e:	6a 00                	push   $0x0
  pushl $187
80108680:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80108685:	e9 2e f2 ff ff       	jmp    801078b8 <alltraps>

8010868a <vector188>:
.globl vector188
vector188:
  pushl $0
8010868a:	6a 00                	push   $0x0
  pushl $188
8010868c:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80108691:	e9 22 f2 ff ff       	jmp    801078b8 <alltraps>

80108696 <vector189>:
.globl vector189
vector189:
  pushl $0
80108696:	6a 00                	push   $0x0
  pushl $189
80108698:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
8010869d:	e9 16 f2 ff ff       	jmp    801078b8 <alltraps>

801086a2 <vector190>:
.globl vector190
vector190:
  pushl $0
801086a2:	6a 00                	push   $0x0
  pushl $190
801086a4:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
801086a9:	e9 0a f2 ff ff       	jmp    801078b8 <alltraps>

801086ae <vector191>:
.globl vector191
vector191:
  pushl $0
801086ae:	6a 00                	push   $0x0
  pushl $191
801086b0:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
801086b5:	e9 fe f1 ff ff       	jmp    801078b8 <alltraps>

801086ba <vector192>:
.globl vector192
vector192:
  pushl $0
801086ba:	6a 00                	push   $0x0
  pushl $192
801086bc:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
801086c1:	e9 f2 f1 ff ff       	jmp    801078b8 <alltraps>

801086c6 <vector193>:
.globl vector193
vector193:
  pushl $0
801086c6:	6a 00                	push   $0x0
  pushl $193
801086c8:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
801086cd:	e9 e6 f1 ff ff       	jmp    801078b8 <alltraps>

801086d2 <vector194>:
.globl vector194
vector194:
  pushl $0
801086d2:	6a 00                	push   $0x0
  pushl $194
801086d4:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
801086d9:	e9 da f1 ff ff       	jmp    801078b8 <alltraps>

801086de <vector195>:
.globl vector195
vector195:
  pushl $0
801086de:	6a 00                	push   $0x0
  pushl $195
801086e0:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
801086e5:	e9 ce f1 ff ff       	jmp    801078b8 <alltraps>

801086ea <vector196>:
.globl vector196
vector196:
  pushl $0
801086ea:	6a 00                	push   $0x0
  pushl $196
801086ec:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
801086f1:	e9 c2 f1 ff ff       	jmp    801078b8 <alltraps>

801086f6 <vector197>:
.globl vector197
vector197:
  pushl $0
801086f6:	6a 00                	push   $0x0
  pushl $197
801086f8:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
801086fd:	e9 b6 f1 ff ff       	jmp    801078b8 <alltraps>

80108702 <vector198>:
.globl vector198
vector198:
  pushl $0
80108702:	6a 00                	push   $0x0
  pushl $198
80108704:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80108709:	e9 aa f1 ff ff       	jmp    801078b8 <alltraps>

8010870e <vector199>:
.globl vector199
vector199:
  pushl $0
8010870e:	6a 00                	push   $0x0
  pushl $199
80108710:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80108715:	e9 9e f1 ff ff       	jmp    801078b8 <alltraps>

8010871a <vector200>:
.globl vector200
vector200:
  pushl $0
8010871a:	6a 00                	push   $0x0
  pushl $200
8010871c:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80108721:	e9 92 f1 ff ff       	jmp    801078b8 <alltraps>

80108726 <vector201>:
.globl vector201
vector201:
  pushl $0
80108726:	6a 00                	push   $0x0
  pushl $201
80108728:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
8010872d:	e9 86 f1 ff ff       	jmp    801078b8 <alltraps>

80108732 <vector202>:
.globl vector202
vector202:
  pushl $0
80108732:	6a 00                	push   $0x0
  pushl $202
80108734:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80108739:	e9 7a f1 ff ff       	jmp    801078b8 <alltraps>

8010873e <vector203>:
.globl vector203
vector203:
  pushl $0
8010873e:	6a 00                	push   $0x0
  pushl $203
80108740:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80108745:	e9 6e f1 ff ff       	jmp    801078b8 <alltraps>

8010874a <vector204>:
.globl vector204
vector204:
  pushl $0
8010874a:	6a 00                	push   $0x0
  pushl $204
8010874c:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80108751:	e9 62 f1 ff ff       	jmp    801078b8 <alltraps>

80108756 <vector205>:
.globl vector205
vector205:
  pushl $0
80108756:	6a 00                	push   $0x0
  pushl $205
80108758:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
8010875d:	e9 56 f1 ff ff       	jmp    801078b8 <alltraps>

80108762 <vector206>:
.globl vector206
vector206:
  pushl $0
80108762:	6a 00                	push   $0x0
  pushl $206
80108764:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80108769:	e9 4a f1 ff ff       	jmp    801078b8 <alltraps>

8010876e <vector207>:
.globl vector207
vector207:
  pushl $0
8010876e:	6a 00                	push   $0x0
  pushl $207
80108770:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80108775:	e9 3e f1 ff ff       	jmp    801078b8 <alltraps>

8010877a <vector208>:
.globl vector208
vector208:
  pushl $0
8010877a:	6a 00                	push   $0x0
  pushl $208
8010877c:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80108781:	e9 32 f1 ff ff       	jmp    801078b8 <alltraps>

80108786 <vector209>:
.globl vector209
vector209:
  pushl $0
80108786:	6a 00                	push   $0x0
  pushl $209
80108788:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
8010878d:	e9 26 f1 ff ff       	jmp    801078b8 <alltraps>

80108792 <vector210>:
.globl vector210
vector210:
  pushl $0
80108792:	6a 00                	push   $0x0
  pushl $210
80108794:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80108799:	e9 1a f1 ff ff       	jmp    801078b8 <alltraps>

8010879e <vector211>:
.globl vector211
vector211:
  pushl $0
8010879e:	6a 00                	push   $0x0
  pushl $211
801087a0:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
801087a5:	e9 0e f1 ff ff       	jmp    801078b8 <alltraps>

801087aa <vector212>:
.globl vector212
vector212:
  pushl $0
801087aa:	6a 00                	push   $0x0
  pushl $212
801087ac:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
801087b1:	e9 02 f1 ff ff       	jmp    801078b8 <alltraps>

801087b6 <vector213>:
.globl vector213
vector213:
  pushl $0
801087b6:	6a 00                	push   $0x0
  pushl $213
801087b8:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
801087bd:	e9 f6 f0 ff ff       	jmp    801078b8 <alltraps>

801087c2 <vector214>:
.globl vector214
vector214:
  pushl $0
801087c2:	6a 00                	push   $0x0
  pushl $214
801087c4:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
801087c9:	e9 ea f0 ff ff       	jmp    801078b8 <alltraps>

801087ce <vector215>:
.globl vector215
vector215:
  pushl $0
801087ce:	6a 00                	push   $0x0
  pushl $215
801087d0:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
801087d5:	e9 de f0 ff ff       	jmp    801078b8 <alltraps>

801087da <vector216>:
.globl vector216
vector216:
  pushl $0
801087da:	6a 00                	push   $0x0
  pushl $216
801087dc:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
801087e1:	e9 d2 f0 ff ff       	jmp    801078b8 <alltraps>

801087e6 <vector217>:
.globl vector217
vector217:
  pushl $0
801087e6:	6a 00                	push   $0x0
  pushl $217
801087e8:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
801087ed:	e9 c6 f0 ff ff       	jmp    801078b8 <alltraps>

801087f2 <vector218>:
.globl vector218
vector218:
  pushl $0
801087f2:	6a 00                	push   $0x0
  pushl $218
801087f4:	68 da 00 00 00       	push   $0xda
  jmp alltraps
801087f9:	e9 ba f0 ff ff       	jmp    801078b8 <alltraps>

801087fe <vector219>:
.globl vector219
vector219:
  pushl $0
801087fe:	6a 00                	push   $0x0
  pushl $219
80108800:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80108805:	e9 ae f0 ff ff       	jmp    801078b8 <alltraps>

8010880a <vector220>:
.globl vector220
vector220:
  pushl $0
8010880a:	6a 00                	push   $0x0
  pushl $220
8010880c:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80108811:	e9 a2 f0 ff ff       	jmp    801078b8 <alltraps>

80108816 <vector221>:
.globl vector221
vector221:
  pushl $0
80108816:	6a 00                	push   $0x0
  pushl $221
80108818:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
8010881d:	e9 96 f0 ff ff       	jmp    801078b8 <alltraps>

80108822 <vector222>:
.globl vector222
vector222:
  pushl $0
80108822:	6a 00                	push   $0x0
  pushl $222
80108824:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80108829:	e9 8a f0 ff ff       	jmp    801078b8 <alltraps>

8010882e <vector223>:
.globl vector223
vector223:
  pushl $0
8010882e:	6a 00                	push   $0x0
  pushl $223
80108830:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80108835:	e9 7e f0 ff ff       	jmp    801078b8 <alltraps>

8010883a <vector224>:
.globl vector224
vector224:
  pushl $0
8010883a:	6a 00                	push   $0x0
  pushl $224
8010883c:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80108841:	e9 72 f0 ff ff       	jmp    801078b8 <alltraps>

80108846 <vector225>:
.globl vector225
vector225:
  pushl $0
80108846:	6a 00                	push   $0x0
  pushl $225
80108848:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
8010884d:	e9 66 f0 ff ff       	jmp    801078b8 <alltraps>

80108852 <vector226>:
.globl vector226
vector226:
  pushl $0
80108852:	6a 00                	push   $0x0
  pushl $226
80108854:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80108859:	e9 5a f0 ff ff       	jmp    801078b8 <alltraps>

8010885e <vector227>:
.globl vector227
vector227:
  pushl $0
8010885e:	6a 00                	push   $0x0
  pushl $227
80108860:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80108865:	e9 4e f0 ff ff       	jmp    801078b8 <alltraps>

8010886a <vector228>:
.globl vector228
vector228:
  pushl $0
8010886a:	6a 00                	push   $0x0
  pushl $228
8010886c:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80108871:	e9 42 f0 ff ff       	jmp    801078b8 <alltraps>

80108876 <vector229>:
.globl vector229
vector229:
  pushl $0
80108876:	6a 00                	push   $0x0
  pushl $229
80108878:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
8010887d:	e9 36 f0 ff ff       	jmp    801078b8 <alltraps>

80108882 <vector230>:
.globl vector230
vector230:
  pushl $0
80108882:	6a 00                	push   $0x0
  pushl $230
80108884:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80108889:	e9 2a f0 ff ff       	jmp    801078b8 <alltraps>

8010888e <vector231>:
.globl vector231
vector231:
  pushl $0
8010888e:	6a 00                	push   $0x0
  pushl $231
80108890:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80108895:	e9 1e f0 ff ff       	jmp    801078b8 <alltraps>

8010889a <vector232>:
.globl vector232
vector232:
  pushl $0
8010889a:	6a 00                	push   $0x0
  pushl $232
8010889c:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
801088a1:	e9 12 f0 ff ff       	jmp    801078b8 <alltraps>

801088a6 <vector233>:
.globl vector233
vector233:
  pushl $0
801088a6:	6a 00                	push   $0x0
  pushl $233
801088a8:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
801088ad:	e9 06 f0 ff ff       	jmp    801078b8 <alltraps>

801088b2 <vector234>:
.globl vector234
vector234:
  pushl $0
801088b2:	6a 00                	push   $0x0
  pushl $234
801088b4:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
801088b9:	e9 fa ef ff ff       	jmp    801078b8 <alltraps>

801088be <vector235>:
.globl vector235
vector235:
  pushl $0
801088be:	6a 00                	push   $0x0
  pushl $235
801088c0:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
801088c5:	e9 ee ef ff ff       	jmp    801078b8 <alltraps>

801088ca <vector236>:
.globl vector236
vector236:
  pushl $0
801088ca:	6a 00                	push   $0x0
  pushl $236
801088cc:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
801088d1:	e9 e2 ef ff ff       	jmp    801078b8 <alltraps>

801088d6 <vector237>:
.globl vector237
vector237:
  pushl $0
801088d6:	6a 00                	push   $0x0
  pushl $237
801088d8:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
801088dd:	e9 d6 ef ff ff       	jmp    801078b8 <alltraps>

801088e2 <vector238>:
.globl vector238
vector238:
  pushl $0
801088e2:	6a 00                	push   $0x0
  pushl $238
801088e4:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
801088e9:	e9 ca ef ff ff       	jmp    801078b8 <alltraps>

801088ee <vector239>:
.globl vector239
vector239:
  pushl $0
801088ee:	6a 00                	push   $0x0
  pushl $239
801088f0:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
801088f5:	e9 be ef ff ff       	jmp    801078b8 <alltraps>

801088fa <vector240>:
.globl vector240
vector240:
  pushl $0
801088fa:	6a 00                	push   $0x0
  pushl $240
801088fc:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80108901:	e9 b2 ef ff ff       	jmp    801078b8 <alltraps>

80108906 <vector241>:
.globl vector241
vector241:
  pushl $0
80108906:	6a 00                	push   $0x0
  pushl $241
80108908:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
8010890d:	e9 a6 ef ff ff       	jmp    801078b8 <alltraps>

80108912 <vector242>:
.globl vector242
vector242:
  pushl $0
80108912:	6a 00                	push   $0x0
  pushl $242
80108914:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80108919:	e9 9a ef ff ff       	jmp    801078b8 <alltraps>

8010891e <vector243>:
.globl vector243
vector243:
  pushl $0
8010891e:	6a 00                	push   $0x0
  pushl $243
80108920:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80108925:	e9 8e ef ff ff       	jmp    801078b8 <alltraps>

8010892a <vector244>:
.globl vector244
vector244:
  pushl $0
8010892a:	6a 00                	push   $0x0
  pushl $244
8010892c:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80108931:	e9 82 ef ff ff       	jmp    801078b8 <alltraps>

80108936 <vector245>:
.globl vector245
vector245:
  pushl $0
80108936:	6a 00                	push   $0x0
  pushl $245
80108938:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
8010893d:	e9 76 ef ff ff       	jmp    801078b8 <alltraps>

80108942 <vector246>:
.globl vector246
vector246:
  pushl $0
80108942:	6a 00                	push   $0x0
  pushl $246
80108944:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80108949:	e9 6a ef ff ff       	jmp    801078b8 <alltraps>

8010894e <vector247>:
.globl vector247
vector247:
  pushl $0
8010894e:	6a 00                	push   $0x0
  pushl $247
80108950:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80108955:	e9 5e ef ff ff       	jmp    801078b8 <alltraps>

8010895a <vector248>:
.globl vector248
vector248:
  pushl $0
8010895a:	6a 00                	push   $0x0
  pushl $248
8010895c:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80108961:	e9 52 ef ff ff       	jmp    801078b8 <alltraps>

80108966 <vector249>:
.globl vector249
vector249:
  pushl $0
80108966:	6a 00                	push   $0x0
  pushl $249
80108968:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
8010896d:	e9 46 ef ff ff       	jmp    801078b8 <alltraps>

80108972 <vector250>:
.globl vector250
vector250:
  pushl $0
80108972:	6a 00                	push   $0x0
  pushl $250
80108974:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80108979:	e9 3a ef ff ff       	jmp    801078b8 <alltraps>

8010897e <vector251>:
.globl vector251
vector251:
  pushl $0
8010897e:	6a 00                	push   $0x0
  pushl $251
80108980:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80108985:	e9 2e ef ff ff       	jmp    801078b8 <alltraps>

8010898a <vector252>:
.globl vector252
vector252:
  pushl $0
8010898a:	6a 00                	push   $0x0
  pushl $252
8010898c:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80108991:	e9 22 ef ff ff       	jmp    801078b8 <alltraps>

80108996 <vector253>:
.globl vector253
vector253:
  pushl $0
80108996:	6a 00                	push   $0x0
  pushl $253
80108998:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
8010899d:	e9 16 ef ff ff       	jmp    801078b8 <alltraps>

801089a2 <vector254>:
.globl vector254
vector254:
  pushl $0
801089a2:	6a 00                	push   $0x0
  pushl $254
801089a4:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
801089a9:	e9 0a ef ff ff       	jmp    801078b8 <alltraps>

801089ae <vector255>:
.globl vector255
vector255:
  pushl $0
801089ae:	6a 00                	push   $0x0
  pushl $255
801089b0:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
801089b5:	e9 fe ee ff ff       	jmp    801078b8 <alltraps>
	...

801089bc <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
801089bc:	55                   	push   %ebp
801089bd:	89 e5                	mov    %esp,%ebp
801089bf:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
801089c2:	8b 45 0c             	mov    0xc(%ebp),%eax
801089c5:	83 e8 01             	sub    $0x1,%eax
801089c8:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
801089cc:	8b 45 08             	mov    0x8(%ebp),%eax
801089cf:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
801089d3:	8b 45 08             	mov    0x8(%ebp),%eax
801089d6:	c1 e8 10             	shr    $0x10,%eax
801089d9:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
801089dd:	8d 45 fa             	lea    -0x6(%ebp),%eax
801089e0:	0f 01 10             	lgdtl  (%eax)
}
801089e3:	c9                   	leave  
801089e4:	c3                   	ret    

801089e5 <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
801089e5:	55                   	push   %ebp
801089e6:	89 e5                	mov    %esp,%ebp
801089e8:	83 ec 04             	sub    $0x4,%esp
801089eb:	8b 45 08             	mov    0x8(%ebp),%eax
801089ee:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
801089f2:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
801089f6:	0f 00 d8             	ltr    %ax
}
801089f9:	c9                   	leave  
801089fa:	c3                   	ret    

801089fb <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
801089fb:	55                   	push   %ebp
801089fc:	89 e5                	mov    %esp,%ebp
801089fe:	83 ec 04             	sub    $0x4,%esp
80108a01:	8b 45 08             	mov    0x8(%ebp),%eax
80108a04:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
80108a08:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80108a0c:	8e e8                	mov    %eax,%gs
}
80108a0e:	c9                   	leave  
80108a0f:	c3                   	ret    

80108a10 <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
80108a10:	55                   	push   %ebp
80108a11:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
80108a13:	8b 45 08             	mov    0x8(%ebp),%eax
80108a16:	0f 22 d8             	mov    %eax,%cr3
}
80108a19:	5d                   	pop    %ebp
80108a1a:	c3                   	ret    

80108a1b <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80108a1b:	55                   	push   %ebp
80108a1c:	89 e5                	mov    %esp,%ebp
80108a1e:	8b 45 08             	mov    0x8(%ebp),%eax
80108a21:	05 00 00 00 80       	add    $0x80000000,%eax
80108a26:	5d                   	pop    %ebp
80108a27:	c3                   	ret    

80108a28 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80108a28:	55                   	push   %ebp
80108a29:	89 e5                	mov    %esp,%ebp
80108a2b:	8b 45 08             	mov    0x8(%ebp),%eax
80108a2e:	05 00 00 00 80       	add    $0x80000000,%eax
80108a33:	5d                   	pop    %ebp
80108a34:	c3                   	ret    

80108a35 <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
80108a35:	55                   	push   %ebp
80108a36:	89 e5                	mov    %esp,%ebp
80108a38:	53                   	push   %ebx
80108a39:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
80108a3c:	e8 58 ae ff ff       	call   80103899 <cpunum>
80108a41:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80108a47:	05 80 49 19 80       	add    $0x80194980,%eax
80108a4c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80108a4f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a52:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
80108a58:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a5b:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
80108a61:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a64:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
80108a68:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a6b:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108a6f:	83 e2 f0             	and    $0xfffffff0,%edx
80108a72:	83 ca 0a             	or     $0xa,%edx
80108a75:	88 50 7d             	mov    %dl,0x7d(%eax)
80108a78:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a7b:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108a7f:	83 ca 10             	or     $0x10,%edx
80108a82:	88 50 7d             	mov    %dl,0x7d(%eax)
80108a85:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a88:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108a8c:	83 e2 9f             	and    $0xffffff9f,%edx
80108a8f:	88 50 7d             	mov    %dl,0x7d(%eax)
80108a92:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a95:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108a99:	83 ca 80             	or     $0xffffff80,%edx
80108a9c:	88 50 7d             	mov    %dl,0x7d(%eax)
80108a9f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108aa2:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108aa6:	83 ca 0f             	or     $0xf,%edx
80108aa9:	88 50 7e             	mov    %dl,0x7e(%eax)
80108aac:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108aaf:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108ab3:	83 e2 ef             	and    $0xffffffef,%edx
80108ab6:	88 50 7e             	mov    %dl,0x7e(%eax)
80108ab9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108abc:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108ac0:	83 e2 df             	and    $0xffffffdf,%edx
80108ac3:	88 50 7e             	mov    %dl,0x7e(%eax)
80108ac6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ac9:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108acd:	83 ca 40             	or     $0x40,%edx
80108ad0:	88 50 7e             	mov    %dl,0x7e(%eax)
80108ad3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ad6:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108ada:	83 ca 80             	or     $0xffffff80,%edx
80108add:	88 50 7e             	mov    %dl,0x7e(%eax)
80108ae0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ae3:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80108ae7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108aea:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
80108af1:	ff ff 
80108af3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108af6:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
80108afd:	00 00 
80108aff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b02:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
80108b09:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b0c:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80108b13:	83 e2 f0             	and    $0xfffffff0,%edx
80108b16:	83 ca 02             	or     $0x2,%edx
80108b19:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80108b1f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b22:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80108b29:	83 ca 10             	or     $0x10,%edx
80108b2c:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80108b32:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b35:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80108b3c:	83 e2 9f             	and    $0xffffff9f,%edx
80108b3f:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80108b45:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b48:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80108b4f:	83 ca 80             	or     $0xffffff80,%edx
80108b52:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80108b58:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b5b:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108b62:	83 ca 0f             	or     $0xf,%edx
80108b65:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108b6b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b6e:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108b75:	83 e2 ef             	and    $0xffffffef,%edx
80108b78:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108b7e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b81:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108b88:	83 e2 df             	and    $0xffffffdf,%edx
80108b8b:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108b91:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b94:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108b9b:	83 ca 40             	or     $0x40,%edx
80108b9e:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108ba4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ba7:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108bae:	83 ca 80             	or     $0xffffff80,%edx
80108bb1:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108bb7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108bba:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80108bc1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108bc4:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
80108bcb:	ff ff 
80108bcd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108bd0:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
80108bd7:	00 00 
80108bd9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108bdc:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
80108be3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108be6:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80108bed:	83 e2 f0             	and    $0xfffffff0,%edx
80108bf0:	83 ca 0a             	or     $0xa,%edx
80108bf3:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80108bf9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108bfc:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80108c03:	83 ca 10             	or     $0x10,%edx
80108c06:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80108c0c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c0f:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80108c16:	83 ca 60             	or     $0x60,%edx
80108c19:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80108c1f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c22:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80108c29:	83 ca 80             	or     $0xffffff80,%edx
80108c2c:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80108c32:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c35:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108c3c:	83 ca 0f             	or     $0xf,%edx
80108c3f:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108c45:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c48:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108c4f:	83 e2 ef             	and    $0xffffffef,%edx
80108c52:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108c58:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c5b:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108c62:	83 e2 df             	and    $0xffffffdf,%edx
80108c65:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108c6b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c6e:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108c75:	83 ca 40             	or     $0x40,%edx
80108c78:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108c7e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c81:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108c88:	83 ca 80             	or     $0xffffff80,%edx
80108c8b:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108c91:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c94:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80108c9b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c9e:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
80108ca5:	ff ff 
80108ca7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108caa:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
80108cb1:	00 00 
80108cb3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108cb6:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
80108cbd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108cc0:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108cc7:	83 e2 f0             	and    $0xfffffff0,%edx
80108cca:	83 ca 02             	or     $0x2,%edx
80108ccd:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108cd3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108cd6:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108cdd:	83 ca 10             	or     $0x10,%edx
80108ce0:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108ce6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ce9:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108cf0:	83 ca 60             	or     $0x60,%edx
80108cf3:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108cf9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108cfc:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108d03:	83 ca 80             	or     $0xffffff80,%edx
80108d06:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108d0c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d0f:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108d16:	83 ca 0f             	or     $0xf,%edx
80108d19:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108d1f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d22:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108d29:	83 e2 ef             	and    $0xffffffef,%edx
80108d2c:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108d32:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d35:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108d3c:	83 e2 df             	and    $0xffffffdf,%edx
80108d3f:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108d45:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d48:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108d4f:	83 ca 40             	or     $0x40,%edx
80108d52:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108d58:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d5b:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108d62:	83 ca 80             	or     $0xffffff80,%edx
80108d65:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108d6b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d6e:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
80108d75:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d78:	05 b4 00 00 00       	add    $0xb4,%eax
80108d7d:	89 c3                	mov    %eax,%ebx
80108d7f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d82:	05 b4 00 00 00       	add    $0xb4,%eax
80108d87:	c1 e8 10             	shr    $0x10,%eax
80108d8a:	89 c1                	mov    %eax,%ecx
80108d8c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d8f:	05 b4 00 00 00       	add    $0xb4,%eax
80108d94:	c1 e8 18             	shr    $0x18,%eax
80108d97:	89 c2                	mov    %eax,%edx
80108d99:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d9c:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
80108da3:	00 00 
80108da5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108da8:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
80108daf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108db2:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
80108db8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108dbb:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108dc2:	83 e1 f0             	and    $0xfffffff0,%ecx
80108dc5:	83 c9 02             	or     $0x2,%ecx
80108dc8:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108dce:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108dd1:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108dd8:	83 c9 10             	or     $0x10,%ecx
80108ddb:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108de1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108de4:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108deb:	83 e1 9f             	and    $0xffffff9f,%ecx
80108dee:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108df4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108df7:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108dfe:	83 c9 80             	or     $0xffffff80,%ecx
80108e01:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108e07:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e0a:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108e11:	83 e1 f0             	and    $0xfffffff0,%ecx
80108e14:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108e1a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e1d:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108e24:	83 e1 ef             	and    $0xffffffef,%ecx
80108e27:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108e2d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e30:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108e37:	83 e1 df             	and    $0xffffffdf,%ecx
80108e3a:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108e40:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e43:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108e4a:	83 c9 40             	or     $0x40,%ecx
80108e4d:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108e53:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e56:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108e5d:	83 c9 80             	or     $0xffffff80,%ecx
80108e60:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108e66:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e69:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
80108e6f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e72:	83 c0 70             	add    $0x70,%eax
80108e75:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
80108e7c:	00 
80108e7d:	89 04 24             	mov    %eax,(%esp)
80108e80:	e8 37 fb ff ff       	call   801089bc <lgdt>
  loadgs(SEG_KCPU << 3);
80108e85:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
80108e8c:	e8 6a fb ff ff       	call   801089fb <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
80108e91:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e94:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
80108e9a:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80108ea1:	00 00 00 00 
}
80108ea5:	83 c4 24             	add    $0x24,%esp
80108ea8:	5b                   	pop    %ebx
80108ea9:	5d                   	pop    %ebp
80108eaa:	c3                   	ret    

80108eab <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80108eab:	55                   	push   %ebp
80108eac:	89 e5                	mov    %esp,%ebp
80108eae:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80108eb1:	8b 45 0c             	mov    0xc(%ebp),%eax
80108eb4:	c1 e8 16             	shr    $0x16,%eax
80108eb7:	c1 e0 02             	shl    $0x2,%eax
80108eba:	03 45 08             	add    0x8(%ebp),%eax
80108ebd:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
80108ec0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108ec3:	8b 00                	mov    (%eax),%eax
80108ec5:	83 e0 01             	and    $0x1,%eax
80108ec8:	84 c0                	test   %al,%al
80108eca:	74 17                	je     80108ee3 <walkpgdir+0x38>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
80108ecc:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108ecf:	8b 00                	mov    (%eax),%eax
80108ed1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108ed6:	89 04 24             	mov    %eax,(%esp)
80108ed9:	e8 4a fb ff ff       	call   80108a28 <p2v>
80108ede:	89 45 f4             	mov    %eax,-0xc(%ebp)
80108ee1:	eb 4b                	jmp    80108f2e <walkpgdir+0x83>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
80108ee3:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80108ee7:	74 0e                	je     80108ef7 <walkpgdir+0x4c>
80108ee9:	e8 22 9c ff ff       	call   80102b10 <kalloc>
80108eee:	89 45 f4             	mov    %eax,-0xc(%ebp)
80108ef1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80108ef5:	75 07                	jne    80108efe <walkpgdir+0x53>
      return 0;
80108ef7:	b8 00 00 00 00       	mov    $0x0,%eax
80108efc:	eb 41                	jmp    80108f3f <walkpgdir+0x94>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
80108efe:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108f05:	00 
80108f06:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108f0d:	00 
80108f0e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108f11:	89 04 24             	mov    %eax,(%esp)
80108f14:	e8 5d d0 ff ff       	call   80105f76 <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
80108f19:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108f1c:	89 04 24             	mov    %eax,(%esp)
80108f1f:	e8 f7 fa ff ff       	call   80108a1b <v2p>
80108f24:	89 c2                	mov    %eax,%edx
80108f26:	83 ca 07             	or     $0x7,%edx
80108f29:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108f2c:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
80108f2e:	8b 45 0c             	mov    0xc(%ebp),%eax
80108f31:	c1 e8 0c             	shr    $0xc,%eax
80108f34:	25 ff 03 00 00       	and    $0x3ff,%eax
80108f39:	c1 e0 02             	shl    $0x2,%eax
80108f3c:	03 45 f4             	add    -0xc(%ebp),%eax
}
80108f3f:	c9                   	leave  
80108f40:	c3                   	ret    

80108f41 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80108f41:	55                   	push   %ebp
80108f42:	89 e5                	mov    %esp,%ebp
80108f44:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
80108f47:	8b 45 0c             	mov    0xc(%ebp),%eax
80108f4a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108f4f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  //cprintf("mappages: a = %p\n",a);
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80108f52:	8b 45 0c             	mov    0xc(%ebp),%eax
80108f55:	03 45 10             	add    0x10(%ebp),%eax
80108f58:	83 e8 01             	sub    $0x1,%eax
80108f5b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108f60:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80108f63:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80108f6a:	00 
80108f6b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108f6e:	89 44 24 04          	mov    %eax,0x4(%esp)
80108f72:	8b 45 08             	mov    0x8(%ebp),%eax
80108f75:	89 04 24             	mov    %eax,(%esp)
80108f78:	e8 2e ff ff ff       	call   80108eab <walkpgdir>
80108f7d:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108f80:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108f84:	75 07                	jne    80108f8d <mappages+0x4c>
      return -1;
80108f86:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108f8b:	eb 46                	jmp    80108fd3 <mappages+0x92>
    if(*pte & PTE_P)
80108f8d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108f90:	8b 00                	mov    (%eax),%eax
80108f92:	83 e0 01             	and    $0x1,%eax
80108f95:	84 c0                	test   %al,%al
80108f97:	74 0c                	je     80108fa5 <mappages+0x64>
      panic("remap");
80108f99:	c7 04 24 7c 9f 10 80 	movl   $0x80109f7c,(%esp)
80108fa0:	e8 98 75 ff ff       	call   8010053d <panic>
    *pte = pa | perm | PTE_P;
80108fa5:	8b 45 18             	mov    0x18(%ebp),%eax
80108fa8:	0b 45 14             	or     0x14(%ebp),%eax
80108fab:	89 c2                	mov    %eax,%edx
80108fad:	83 ca 01             	or     $0x1,%edx
80108fb0:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108fb3:	89 10                	mov    %edx,(%eax)
   //cprintf("mappages: pte = %p\n",pte);
    if(a == last)
80108fb5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108fb8:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80108fbb:	74 10                	je     80108fcd <mappages+0x8c>
      break;
    a += PGSIZE;
80108fbd:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
80108fc4:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
80108fcb:	eb 96                	jmp    80108f63 <mappages+0x22>
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
   //cprintf("mappages: pte = %p\n",pte);
    if(a == last)
      break;
80108fcd:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
80108fce:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108fd3:	c9                   	leave  
80108fd4:	c3                   	ret    

80108fd5 <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm()
{
80108fd5:	55                   	push   %ebp
80108fd6:	89 e5                	mov    %esp,%ebp
80108fd8:	53                   	push   %ebx
80108fd9:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
80108fdc:	e8 2f 9b ff ff       	call   80102b10 <kalloc>
80108fe1:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108fe4:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108fe8:	75 0a                	jne    80108ff4 <setupkvm+0x1f>
    return 0;
80108fea:	b8 00 00 00 00       	mov    $0x0,%eax
80108fef:	e9 98 00 00 00       	jmp    8010908c <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
80108ff4:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108ffb:	00 
80108ffc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80109003:	00 
80109004:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109007:	89 04 24             	mov    %eax,(%esp)
8010900a:	e8 67 cf ff ff       	call   80105f76 <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
8010900f:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
80109016:	e8 0d fa ff ff       	call   80108a28 <p2v>
8010901b:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
80109020:	76 0c                	jbe    8010902e <setupkvm+0x59>
    panic("PHYSTOP too high");
80109022:	c7 04 24 82 9f 10 80 	movl   $0x80109f82,(%esp)
80109029:	e8 0f 75 ff ff       	call   8010053d <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
8010902e:	c7 45 f4 c0 d4 10 80 	movl   $0x8010d4c0,-0xc(%ebp)
80109035:	eb 49                	jmp    80109080 <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
80109037:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
8010903a:	8b 48 0c             	mov    0xc(%eax),%ecx
                (uint)k->phys_start, k->perm) < 0)
8010903d:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80109040:	8b 50 04             	mov    0x4(%eax),%edx
80109043:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109046:	8b 58 08             	mov    0x8(%eax),%ebx
80109049:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010904c:	8b 40 04             	mov    0x4(%eax),%eax
8010904f:	29 c3                	sub    %eax,%ebx
80109051:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109054:	8b 00                	mov    (%eax),%eax
80109056:	89 4c 24 10          	mov    %ecx,0x10(%esp)
8010905a:	89 54 24 0c          	mov    %edx,0xc(%esp)
8010905e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80109062:	89 44 24 04          	mov    %eax,0x4(%esp)
80109066:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109069:	89 04 24             	mov    %eax,(%esp)
8010906c:	e8 d0 fe ff ff       	call   80108f41 <mappages>
80109071:	85 c0                	test   %eax,%eax
80109073:	79 07                	jns    8010907c <setupkvm+0xa7>
                (uint)k->phys_start, k->perm) < 0)
      return 0;
80109075:	b8 00 00 00 00       	mov    $0x0,%eax
8010907a:	eb 10                	jmp    8010908c <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
8010907c:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80109080:	81 7d f4 00 d5 10 80 	cmpl   $0x8010d500,-0xc(%ebp)
80109087:	72 ae                	jb     80109037 <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
      return 0;
  return pgdir;
80109089:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
8010908c:	83 c4 34             	add    $0x34,%esp
8010908f:	5b                   	pop    %ebx
80109090:	5d                   	pop    %ebp
80109091:	c3                   	ret    

80109092 <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
void
kvmalloc(void)
{
80109092:	55                   	push   %ebp
80109093:	89 e5                	mov    %esp,%ebp
80109095:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80109098:	e8 38 ff ff ff       	call   80108fd5 <setupkvm>
8010909d:	a3 58 7c 19 80       	mov    %eax,0x80197c58
  switchkvm();
801090a2:	e8 02 00 00 00       	call   801090a9 <switchkvm>
}
801090a7:	c9                   	leave  
801090a8:	c3                   	ret    

801090a9 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
801090a9:	55                   	push   %ebp
801090aa:	89 e5                	mov    %esp,%ebp
801090ac:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
801090af:	a1 58 7c 19 80       	mov    0x80197c58,%eax
801090b4:	89 04 24             	mov    %eax,(%esp)
801090b7:	e8 5f f9 ff ff       	call   80108a1b <v2p>
801090bc:	89 04 24             	mov    %eax,(%esp)
801090bf:	e8 4c f9 ff ff       	call   80108a10 <lcr3>
}
801090c4:	c9                   	leave  
801090c5:	c3                   	ret    

801090c6 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
801090c6:	55                   	push   %ebp
801090c7:	89 e5                	mov    %esp,%ebp
801090c9:	53                   	push   %ebx
801090ca:	83 ec 14             	sub    $0x14,%esp
  pushcli();
801090cd:	e8 9e cd ff ff       	call   80105e70 <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
801090d2:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801090d8:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801090df:	83 c2 08             	add    $0x8,%edx
801090e2:	89 d3                	mov    %edx,%ebx
801090e4:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801090eb:	83 c2 08             	add    $0x8,%edx
801090ee:	c1 ea 10             	shr    $0x10,%edx
801090f1:	89 d1                	mov    %edx,%ecx
801090f3:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801090fa:	83 c2 08             	add    $0x8,%edx
801090fd:	c1 ea 18             	shr    $0x18,%edx
80109100:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
80109107:	67 00 
80109109:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
80109110:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
80109116:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
8010911d:	83 e1 f0             	and    $0xfffffff0,%ecx
80109120:	83 c9 09             	or     $0x9,%ecx
80109123:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80109129:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80109130:	83 c9 10             	or     $0x10,%ecx
80109133:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80109139:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80109140:	83 e1 9f             	and    $0xffffff9f,%ecx
80109143:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80109149:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80109150:	83 c9 80             	or     $0xffffff80,%ecx
80109153:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80109159:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80109160:	83 e1 f0             	and    $0xfffffff0,%ecx
80109163:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80109169:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80109170:	83 e1 ef             	and    $0xffffffef,%ecx
80109173:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80109179:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80109180:	83 e1 df             	and    $0xffffffdf,%ecx
80109183:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80109189:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80109190:	83 c9 40             	or     $0x40,%ecx
80109193:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80109199:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
801091a0:	83 e1 7f             	and    $0x7f,%ecx
801091a3:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
801091a9:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
801091af:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801091b5:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
801091bc:	83 e2 ef             	and    $0xffffffef,%edx
801091bf:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
801091c5:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801091cb:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
801091d1:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801091d7:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801091de:	8b 52 08             	mov    0x8(%edx),%edx
801091e1:	81 c2 00 10 00 00    	add    $0x1000,%edx
801091e7:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
801091ea:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
801091f1:	e8 ef f7 ff ff       	call   801089e5 <ltr>
  if(p->pgdir == 0)
801091f6:	8b 45 08             	mov    0x8(%ebp),%eax
801091f9:	8b 40 04             	mov    0x4(%eax),%eax
801091fc:	85 c0                	test   %eax,%eax
801091fe:	75 0c                	jne    8010920c <switchuvm+0x146>
    panic("switchuvm: no pgdir");
80109200:	c7 04 24 93 9f 10 80 	movl   $0x80109f93,(%esp)
80109207:	e8 31 73 ff ff       	call   8010053d <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
8010920c:	8b 45 08             	mov    0x8(%ebp),%eax
8010920f:	8b 40 04             	mov    0x4(%eax),%eax
80109212:	89 04 24             	mov    %eax,(%esp)
80109215:	e8 01 f8 ff ff       	call   80108a1b <v2p>
8010921a:	89 04 24             	mov    %eax,(%esp)
8010921d:	e8 ee f7 ff ff       	call   80108a10 <lcr3>
  popcli();
80109222:	e8 91 cc ff ff       	call   80105eb8 <popcli>
}
80109227:	83 c4 14             	add    $0x14,%esp
8010922a:	5b                   	pop    %ebx
8010922b:	5d                   	pop    %ebp
8010922c:	c3                   	ret    

8010922d <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
8010922d:	55                   	push   %ebp
8010922e:	89 e5                	mov    %esp,%ebp
80109230:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
80109233:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
8010923a:	76 0c                	jbe    80109248 <inituvm+0x1b>
    panic("inituvm: more than a page");
8010923c:	c7 04 24 a7 9f 10 80 	movl   $0x80109fa7,(%esp)
80109243:	e8 f5 72 ff ff       	call   8010053d <panic>
  mem = kalloc();
80109248:	e8 c3 98 ff ff       	call   80102b10 <kalloc>
8010924d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
80109250:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80109257:	00 
80109258:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010925f:	00 
80109260:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109263:	89 04 24             	mov    %eax,(%esp)
80109266:	e8 0b cd ff ff       	call   80105f76 <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
8010926b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010926e:	89 04 24             	mov    %eax,(%esp)
80109271:	e8 a5 f7 ff ff       	call   80108a1b <v2p>
80109276:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
8010927d:	00 
8010927e:	89 44 24 0c          	mov    %eax,0xc(%esp)
80109282:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80109289:	00 
8010928a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80109291:	00 
80109292:	8b 45 08             	mov    0x8(%ebp),%eax
80109295:	89 04 24             	mov    %eax,(%esp)
80109298:	e8 a4 fc ff ff       	call   80108f41 <mappages>
  memmove(mem, init, sz);
8010929d:	8b 45 10             	mov    0x10(%ebp),%eax
801092a0:	89 44 24 08          	mov    %eax,0x8(%esp)
801092a4:	8b 45 0c             	mov    0xc(%ebp),%eax
801092a7:	89 44 24 04          	mov    %eax,0x4(%esp)
801092ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801092ae:	89 04 24             	mov    %eax,(%esp)
801092b1:	e8 93 cd ff ff       	call   80106049 <memmove>
}
801092b6:	c9                   	leave  
801092b7:	c3                   	ret    

801092b8 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
801092b8:	55                   	push   %ebp
801092b9:	89 e5                	mov    %esp,%ebp
801092bb:	53                   	push   %ebx
801092bc:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;
  if((uint) addr % PGSIZE != 0)
801092bf:	8b 45 0c             	mov    0xc(%ebp),%eax
801092c2:	25 ff 0f 00 00       	and    $0xfff,%eax
801092c7:	85 c0                	test   %eax,%eax
801092c9:	74 0c                	je     801092d7 <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
801092cb:	c7 04 24 c4 9f 10 80 	movl   $0x80109fc4,(%esp)
801092d2:	e8 66 72 ff ff       	call   8010053d <panic>
  for(i = 0; i < sz; i += PGSIZE){
801092d7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801092de:	e9 ad 00 00 00       	jmp    80109390 <loaduvm+0xd8>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
801092e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801092e6:	8b 55 0c             	mov    0xc(%ebp),%edx
801092e9:	01 d0                	add    %edx,%eax
801092eb:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801092f2:	00 
801092f3:	89 44 24 04          	mov    %eax,0x4(%esp)
801092f7:	8b 45 08             	mov    0x8(%ebp),%eax
801092fa:	89 04 24             	mov    %eax,(%esp)
801092fd:	e8 a9 fb ff ff       	call   80108eab <walkpgdir>
80109302:	89 45 ec             	mov    %eax,-0x14(%ebp)
80109305:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80109309:	75 0c                	jne    80109317 <loaduvm+0x5f>
      panic("loaduvm: address should exist");
8010930b:	c7 04 24 e7 9f 10 80 	movl   $0x80109fe7,(%esp)
80109312:	e8 26 72 ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
80109317:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010931a:	8b 00                	mov    (%eax),%eax
8010931c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109321:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
80109324:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109327:	8b 55 18             	mov    0x18(%ebp),%edx
8010932a:	89 d1                	mov    %edx,%ecx
8010932c:	29 c1                	sub    %eax,%ecx
8010932e:	89 c8                	mov    %ecx,%eax
80109330:	3d ff 0f 00 00       	cmp    $0xfff,%eax
80109335:	77 11                	ja     80109348 <loaduvm+0x90>
      n = sz - i;
80109337:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010933a:	8b 55 18             	mov    0x18(%ebp),%edx
8010933d:	89 d1                	mov    %edx,%ecx
8010933f:	29 c1                	sub    %eax,%ecx
80109341:	89 c8                	mov    %ecx,%eax
80109343:	89 45 f0             	mov    %eax,-0x10(%ebp)
80109346:	eb 07                	jmp    8010934f <loaduvm+0x97>
    else
      n = PGSIZE;
80109348:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
8010934f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109352:	8b 55 14             	mov    0x14(%ebp),%edx
80109355:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80109358:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010935b:	89 04 24             	mov    %eax,(%esp)
8010935e:	e8 c5 f6 ff ff       	call   80108a28 <p2v>
80109363:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109366:	89 54 24 0c          	mov    %edx,0xc(%esp)
8010936a:	89 5c 24 08          	mov    %ebx,0x8(%esp)
8010936e:	89 44 24 04          	mov    %eax,0x4(%esp)
80109372:	8b 45 10             	mov    0x10(%ebp),%eax
80109375:	89 04 24             	mov    %eax,(%esp)
80109378:	e8 e1 89 ff ff       	call   80101d5e <readi>
8010937d:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80109380:	74 07                	je     80109389 <loaduvm+0xd1>
      return -1;
80109382:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80109387:	eb 18                	jmp    801093a1 <loaduvm+0xe9>
{
  uint i, pa, n;
  pte_t *pte;
  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80109389:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80109390:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109393:	3b 45 18             	cmp    0x18(%ebp),%eax
80109396:	0f 82 47 ff ff ff    	jb     801092e3 <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
8010939c:	b8 00 00 00 00       	mov    $0x0,%eax
}
801093a1:	83 c4 24             	add    $0x24,%esp
801093a4:	5b                   	pop    %ebx
801093a5:	5d                   	pop    %ebp
801093a6:	c3                   	ret    

801093a7 <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
801093a7:	55                   	push   %ebp
801093a8:	89 e5                	mov    %esp,%ebp
801093aa:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  uint a;

  if(newsz >= KERNBASE)
801093ad:	8b 45 10             	mov    0x10(%ebp),%eax
801093b0:	85 c0                	test   %eax,%eax
801093b2:	79 0a                	jns    801093be <allocuvm+0x17>
    return 0;
801093b4:	b8 00 00 00 00       	mov    $0x0,%eax
801093b9:	e9 c1 00 00 00       	jmp    8010947f <allocuvm+0xd8>
  if(newsz < oldsz)
801093be:	8b 45 10             	mov    0x10(%ebp),%eax
801093c1:	3b 45 0c             	cmp    0xc(%ebp),%eax
801093c4:	73 08                	jae    801093ce <allocuvm+0x27>
    return oldsz;
801093c6:	8b 45 0c             	mov    0xc(%ebp),%eax
801093c9:	e9 b1 00 00 00       	jmp    8010947f <allocuvm+0xd8>
  a = PGROUNDUP(oldsz);
801093ce:	8b 45 0c             	mov    0xc(%ebp),%eax
801093d1:	05 ff 0f 00 00       	add    $0xfff,%eax
801093d6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801093db:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
801093de:	e9 8d 00 00 00       	jmp    80109470 <allocuvm+0xc9>
    mem = kalloc();
801093e3:	e8 28 97 ff ff       	call   80102b10 <kalloc>
801093e8:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(mem == 0){
801093eb:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801093ef:	75 2c                	jne    8010941d <allocuvm+0x76>
      cprintf("allocuvm out of memory\n");
801093f1:	c7 04 24 05 a0 10 80 	movl   $0x8010a005,(%esp)
801093f8:	e8 a4 6f ff ff       	call   801003a1 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
801093fd:	8b 45 0c             	mov    0xc(%ebp),%eax
80109400:	89 44 24 08          	mov    %eax,0x8(%esp)
80109404:	8b 45 10             	mov    0x10(%ebp),%eax
80109407:	89 44 24 04          	mov    %eax,0x4(%esp)
8010940b:	8b 45 08             	mov    0x8(%ebp),%eax
8010940e:	89 04 24             	mov    %eax,(%esp)
80109411:	e8 6b 00 00 00       	call   80109481 <deallocuvm>
      return 0;
80109416:	b8 00 00 00 00       	mov    $0x0,%eax
8010941b:	eb 62                	jmp    8010947f <allocuvm+0xd8>
    }
    memset(mem, 0, PGSIZE);
8010941d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80109424:	00 
80109425:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010942c:	00 
8010942d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109430:	89 04 24             	mov    %eax,(%esp)
80109433:	e8 3e cb ff ff       	call   80105f76 <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
80109438:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010943b:	89 04 24             	mov    %eax,(%esp)
8010943e:	e8 d8 f5 ff ff       	call   80108a1b <v2p>
80109443:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109446:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
8010944d:	00 
8010944e:	89 44 24 0c          	mov    %eax,0xc(%esp)
80109452:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80109459:	00 
8010945a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010945e:	8b 45 08             	mov    0x8(%ebp),%eax
80109461:	89 04 24             	mov    %eax,(%esp)
80109464:	e8 d8 fa ff ff       	call   80108f41 <mappages>
  if(newsz >= KERNBASE)
    return 0;
  if(newsz < oldsz)
    return oldsz;
  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
80109469:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80109470:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109473:	3b 45 10             	cmp    0x10(%ebp),%eax
80109476:	0f 82 67 ff ff ff    	jb     801093e3 <allocuvm+0x3c>
      return 0;
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
  }
  return newsz;
8010947c:	8b 45 10             	mov    0x10(%ebp),%eax
}
8010947f:	c9                   	leave  
80109480:	c3                   	ret    

80109481 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80109481:	55                   	push   %ebp
80109482:	89 e5                	mov    %esp,%ebp
80109484:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
80109487:	8b 45 10             	mov    0x10(%ebp),%eax
8010948a:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010948d:	72 08                	jb     80109497 <deallocuvm+0x16>
    return oldsz;
8010948f:	8b 45 0c             	mov    0xc(%ebp),%eax
80109492:	e9 a4 00 00 00       	jmp    8010953b <deallocuvm+0xba>

  a = PGROUNDUP(newsz);
80109497:	8b 45 10             	mov    0x10(%ebp),%eax
8010949a:	05 ff 0f 00 00       	add    $0xfff,%eax
8010949f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801094a4:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
801094a7:	e9 80 00 00 00       	jmp    8010952c <deallocuvm+0xab>
    pte = walkpgdir(pgdir, (char*)a, 0);
801094ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
801094af:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801094b6:	00 
801094b7:	89 44 24 04          	mov    %eax,0x4(%esp)
801094bb:	8b 45 08             	mov    0x8(%ebp),%eax
801094be:	89 04 24             	mov    %eax,(%esp)
801094c1:	e8 e5 f9 ff ff       	call   80108eab <walkpgdir>
801094c6:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(!pte)
801094c9:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801094cd:	75 09                	jne    801094d8 <deallocuvm+0x57>
      a += (NPTENTRIES - 1) * PGSIZE;
801094cf:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
801094d6:	eb 4d                	jmp    80109525 <deallocuvm+0xa4>
    else if((*pte & PTE_P) != 0){
801094d8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801094db:	8b 00                	mov    (%eax),%eax
801094dd:	83 e0 01             	and    $0x1,%eax
801094e0:	84 c0                	test   %al,%al
801094e2:	74 41                	je     80109525 <deallocuvm+0xa4>
      pa = PTE_ADDR(*pte);
801094e4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801094e7:	8b 00                	mov    (%eax),%eax
801094e9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801094ee:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if(pa == 0)
801094f1:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801094f5:	75 0c                	jne    80109503 <deallocuvm+0x82>
        panic("kfree");
801094f7:	c7 04 24 1d a0 10 80 	movl   $0x8010a01d,(%esp)
801094fe:	e8 3a 70 ff ff       	call   8010053d <panic>
      char *v = p2v(pa);
80109503:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109506:	89 04 24             	mov    %eax,(%esp)
80109509:	e8 1a f5 ff ff       	call   80108a28 <p2v>
8010950e:	89 45 e8             	mov    %eax,-0x18(%ebp)
      kfree(v);
80109511:	8b 45 e8             	mov    -0x18(%ebp),%eax
80109514:	89 04 24             	mov    %eax,(%esp)
80109517:	e8 5b 95 ff ff       	call   80102a77 <kfree>
      *pte = 0;
8010951c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010951f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
80109525:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
8010952c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010952f:	3b 45 0c             	cmp    0xc(%ebp),%eax
80109532:	0f 82 74 ff ff ff    	jb     801094ac <deallocuvm+0x2b>
      char *v = p2v(pa);
      kfree(v);
      *pte = 0;
    }
  }
  return newsz;
80109538:	8b 45 10             	mov    0x10(%ebp),%eax
}
8010953b:	c9                   	leave  
8010953c:	c3                   	ret    

8010953d <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
8010953d:	55                   	push   %ebp
8010953e:	89 e5                	mov    %esp,%ebp
80109540:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
80109543:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80109547:	75 0c                	jne    80109555 <freevm+0x18>
    panic("freevm: no pgdir");
80109549:	c7 04 24 23 a0 10 80 	movl   $0x8010a023,(%esp)
80109550:	e8 e8 6f ff ff       	call   8010053d <panic>
  deallocuvm(pgdir, KERNBASE, 0);
80109555:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010955c:	00 
8010955d:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
80109564:	80 
80109565:	8b 45 08             	mov    0x8(%ebp),%eax
80109568:	89 04 24             	mov    %eax,(%esp)
8010956b:	e8 11 ff ff ff       	call   80109481 <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
80109570:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80109577:	eb 3c                	jmp    801095b5 <freevm+0x78>
    if(pgdir[i] & PTE_P){
80109579:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010957c:	c1 e0 02             	shl    $0x2,%eax
8010957f:	03 45 08             	add    0x8(%ebp),%eax
80109582:	8b 00                	mov    (%eax),%eax
80109584:	83 e0 01             	and    $0x1,%eax
80109587:	84 c0                	test   %al,%al
80109589:	74 26                	je     801095b1 <freevm+0x74>
      char * v = p2v(PTE_ADDR(pgdir[i]));
8010958b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010958e:	c1 e0 02             	shl    $0x2,%eax
80109591:	03 45 08             	add    0x8(%ebp),%eax
80109594:	8b 00                	mov    (%eax),%eax
80109596:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010959b:	89 04 24             	mov    %eax,(%esp)
8010959e:	e8 85 f4 ff ff       	call   80108a28 <p2v>
801095a3:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
801095a6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801095a9:	89 04 24             	mov    %eax,(%esp)
801095ac:	e8 c6 94 ff ff       	call   80102a77 <kfree>
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
  for(i = 0; i < NPDENTRIES; i++){
801095b1:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801095b5:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
801095bc:	76 bb                	jbe    80109579 <freevm+0x3c>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
801095be:	8b 45 08             	mov    0x8(%ebp),%eax
801095c1:	89 04 24             	mov    %eax,(%esp)
801095c4:	e8 ae 94 ff ff       	call   80102a77 <kfree>
}
801095c9:	c9                   	leave  
801095ca:	c3                   	ret    

801095cb <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
801095cb:	55                   	push   %ebp
801095cc:	89 e5                	mov    %esp,%ebp
801095ce:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801095d1:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801095d8:	00 
801095d9:	8b 45 0c             	mov    0xc(%ebp),%eax
801095dc:	89 44 24 04          	mov    %eax,0x4(%esp)
801095e0:	8b 45 08             	mov    0x8(%ebp),%eax
801095e3:	89 04 24             	mov    %eax,(%esp)
801095e6:	e8 c0 f8 ff ff       	call   80108eab <walkpgdir>
801095eb:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
801095ee:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801095f2:	75 0c                	jne    80109600 <clearpteu+0x35>
    panic("clearpteu");
801095f4:	c7 04 24 34 a0 10 80 	movl   $0x8010a034,(%esp)
801095fb:	e8 3d 6f ff ff       	call   8010053d <panic>
  *pte &= ~PTE_U;
80109600:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109603:	8b 00                	mov    (%eax),%eax
80109605:	89 c2                	mov    %eax,%edx
80109607:	83 e2 fb             	and    $0xfffffffb,%edx
8010960a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010960d:	89 10                	mov    %edx,(%eax)
}
8010960f:	c9                   	leave  
80109610:	c3                   	ret    

80109611 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
80109611:	55                   	push   %ebp
80109612:	89 e5                	mov    %esp,%ebp
80109614:	83 ec 48             	sub    $0x48,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
80109617:	e8 b9 f9 ff ff       	call   80108fd5 <setupkvm>
8010961c:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010961f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80109623:	75 0a                	jne    8010962f <copyuvm+0x1e>
    return 0;
80109625:	b8 00 00 00 00       	mov    $0x0,%eax
8010962a:	e9 f1 00 00 00       	jmp    80109720 <copyuvm+0x10f>
  for(i = 0; i < sz; i += PGSIZE){
8010962f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80109636:	e9 c0 00 00 00       	jmp    801096fb <copyuvm+0xea>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
8010963b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010963e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80109645:	00 
80109646:	89 44 24 04          	mov    %eax,0x4(%esp)
8010964a:	8b 45 08             	mov    0x8(%ebp),%eax
8010964d:	89 04 24             	mov    %eax,(%esp)
80109650:	e8 56 f8 ff ff       	call   80108eab <walkpgdir>
80109655:	89 45 ec             	mov    %eax,-0x14(%ebp)
80109658:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
8010965c:	75 0c                	jne    8010966a <copyuvm+0x59>
      panic("copyuvm: pte should exist");
8010965e:	c7 04 24 3e a0 10 80 	movl   $0x8010a03e,(%esp)
80109665:	e8 d3 6e ff ff       	call   8010053d <panic>
    if(!(*pte & PTE_P))
8010966a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010966d:	8b 00                	mov    (%eax),%eax
8010966f:	83 e0 01             	and    $0x1,%eax
80109672:	85 c0                	test   %eax,%eax
80109674:	75 0c                	jne    80109682 <copyuvm+0x71>
      panic("copyuvm: page not present");
80109676:	c7 04 24 58 a0 10 80 	movl   $0x8010a058,(%esp)
8010967d:	e8 bb 6e ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
80109682:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109685:	8b 00                	mov    (%eax),%eax
80109687:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010968c:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if((mem = kalloc()) == 0)
8010968f:	e8 7c 94 ff ff       	call   80102b10 <kalloc>
80109694:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80109697:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
8010969b:	74 6f                	je     8010970c <copyuvm+0xfb>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
8010969d:	8b 45 e8             	mov    -0x18(%ebp),%eax
801096a0:	89 04 24             	mov    %eax,(%esp)
801096a3:	e8 80 f3 ff ff       	call   80108a28 <p2v>
801096a8:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801096af:	00 
801096b0:	89 44 24 04          	mov    %eax,0x4(%esp)
801096b4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801096b7:	89 04 24             	mov    %eax,(%esp)
801096ba:	e8 8a c9 ff ff       	call   80106049 <memmove>
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
801096bf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801096c2:	89 04 24             	mov    %eax,(%esp)
801096c5:	e8 51 f3 ff ff       	call   80108a1b <v2p>
801096ca:	8b 55 f4             	mov    -0xc(%ebp),%edx
801096cd:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
801096d4:	00 
801096d5:	89 44 24 0c          	mov    %eax,0xc(%esp)
801096d9:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801096e0:	00 
801096e1:	89 54 24 04          	mov    %edx,0x4(%esp)
801096e5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801096e8:	89 04 24             	mov    %eax,(%esp)
801096eb:	e8 51 f8 ff ff       	call   80108f41 <mappages>
801096f0:	85 c0                	test   %eax,%eax
801096f2:	78 1b                	js     8010970f <copyuvm+0xfe>
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
801096f4:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801096fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801096fe:	3b 45 0c             	cmp    0xc(%ebp),%eax
80109701:	0f 82 34 ff ff ff    	jb     8010963b <copyuvm+0x2a>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
  }
  return d;
80109707:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010970a:	eb 14                	jmp    80109720 <copyuvm+0x10f>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
    if((mem = kalloc()) == 0)
      goto bad;
8010970c:	90                   	nop
8010970d:	eb 01                	jmp    80109710 <copyuvm+0xff>
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
8010970f:	90                   	nop
  }
  return d;

bad:
  freevm(d);
80109710:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109713:	89 04 24             	mov    %eax,(%esp)
80109716:	e8 22 fe ff ff       	call   8010953d <freevm>
  return 0;
8010971b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80109720:	c9                   	leave  
80109721:	c3                   	ret    

80109722 <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
80109722:	55                   	push   %ebp
80109723:	89 e5                	mov    %esp,%ebp
80109725:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80109728:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010972f:	00 
80109730:	8b 45 0c             	mov    0xc(%ebp),%eax
80109733:	89 44 24 04          	mov    %eax,0x4(%esp)
80109737:	8b 45 08             	mov    0x8(%ebp),%eax
8010973a:	89 04 24             	mov    %eax,(%esp)
8010973d:	e8 69 f7 ff ff       	call   80108eab <walkpgdir>
80109742:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
80109745:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109748:	8b 00                	mov    (%eax),%eax
8010974a:	83 e0 01             	and    $0x1,%eax
8010974d:	85 c0                	test   %eax,%eax
8010974f:	75 07                	jne    80109758 <uva2ka+0x36>
    return 0;
80109751:	b8 00 00 00 00       	mov    $0x0,%eax
80109756:	eb 25                	jmp    8010977d <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
80109758:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010975b:	8b 00                	mov    (%eax),%eax
8010975d:	83 e0 04             	and    $0x4,%eax
80109760:	85 c0                	test   %eax,%eax
80109762:	75 07                	jne    8010976b <uva2ka+0x49>
    return 0;
80109764:	b8 00 00 00 00       	mov    $0x0,%eax
80109769:	eb 12                	jmp    8010977d <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
8010976b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010976e:	8b 00                	mov    (%eax),%eax
80109770:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109775:	89 04 24             	mov    %eax,(%esp)
80109778:	e8 ab f2 ff ff       	call   80108a28 <p2v>
}
8010977d:	c9                   	leave  
8010977e:	c3                   	ret    

8010977f <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
8010977f:	55                   	push   %ebp
80109780:	89 e5                	mov    %esp,%ebp
80109782:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
80109785:	8b 45 10             	mov    0x10(%ebp),%eax
80109788:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
8010978b:	e9 8b 00 00 00       	jmp    8010981b <copyout+0x9c>
    va0 = (uint)PGROUNDDOWN(va);
80109790:	8b 45 0c             	mov    0xc(%ebp),%eax
80109793:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109798:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
8010979b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010979e:	89 44 24 04          	mov    %eax,0x4(%esp)
801097a2:	8b 45 08             	mov    0x8(%ebp),%eax
801097a5:	89 04 24             	mov    %eax,(%esp)
801097a8:	e8 75 ff ff ff       	call   80109722 <uva2ka>
801097ad:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
801097b0:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801097b4:	75 07                	jne    801097bd <copyout+0x3e>
      return -1;
801097b6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801097bb:	eb 6d                	jmp    8010982a <copyout+0xab>
    n = PGSIZE - (va - va0);
801097bd:	8b 45 0c             	mov    0xc(%ebp),%eax
801097c0:	8b 55 ec             	mov    -0x14(%ebp),%edx
801097c3:	89 d1                	mov    %edx,%ecx
801097c5:	29 c1                	sub    %eax,%ecx
801097c7:	89 c8                	mov    %ecx,%eax
801097c9:	05 00 10 00 00       	add    $0x1000,%eax
801097ce:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
801097d1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801097d4:	3b 45 14             	cmp    0x14(%ebp),%eax
801097d7:	76 06                	jbe    801097df <copyout+0x60>
      n = len;
801097d9:	8b 45 14             	mov    0x14(%ebp),%eax
801097dc:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
801097df:	8b 45 ec             	mov    -0x14(%ebp),%eax
801097e2:	8b 55 0c             	mov    0xc(%ebp),%edx
801097e5:	89 d1                	mov    %edx,%ecx
801097e7:	29 c1                	sub    %eax,%ecx
801097e9:	89 c8                	mov    %ecx,%eax
801097eb:	03 45 e8             	add    -0x18(%ebp),%eax
801097ee:	8b 55 f0             	mov    -0x10(%ebp),%edx
801097f1:	89 54 24 08          	mov    %edx,0x8(%esp)
801097f5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801097f8:	89 54 24 04          	mov    %edx,0x4(%esp)
801097fc:	89 04 24             	mov    %eax,(%esp)
801097ff:	e8 45 c8 ff ff       	call   80106049 <memmove>
    len -= n;
80109804:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109807:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
8010980a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010980d:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
80109810:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109813:	05 00 10 00 00       	add    $0x1000,%eax
80109818:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
8010981b:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
8010981f:	0f 85 6b ff ff ff    	jne    80109790 <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
80109825:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010982a:	c9                   	leave  
8010982b:	c3                   	ret    
