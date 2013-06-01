
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
80100028:	bc 60 d6 10 80       	mov    $0x8010d660,%esp

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
8010003a:	c7 44 24 04 84 88 10 	movl   $0x80108884,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 60 d6 10 80 	movl   $0x8010d660,(%esp)
80100049:	e8 44 50 00 00       	call   80105092 <initlock>

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
8010004e:	c7 05 90 eb 10 80 84 	movl   $0x8010eb84,0x8010eb90
80100055:	eb 10 80 
  bcache.head.next = &bcache.head;
80100058:	c7 05 94 eb 10 80 84 	movl   $0x8010eb84,0x8010eb94
8010005f:	eb 10 80 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
80100062:	c7 45 f4 94 d6 10 80 	movl   $0x8010d694,-0xc(%ebp)
80100069:	eb 3a                	jmp    801000a5 <binit+0x71>
    b->next = bcache.head.next;
8010006b:	8b 15 94 eb 10 80    	mov    0x8010eb94,%edx
80100071:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100074:	89 50 10             	mov    %edx,0x10(%eax)
    b->prev = &bcache.head;
80100077:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010007a:	c7 40 0c 84 eb 10 80 	movl   $0x8010eb84,0xc(%eax)
    b->dev = -1;
80100081:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100084:	c7 40 04 ff ff ff ff 	movl   $0xffffffff,0x4(%eax)
    bcache.head.next->prev = b;
8010008b:	a1 94 eb 10 80       	mov    0x8010eb94,%eax
80100090:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100093:	89 50 0c             	mov    %edx,0xc(%eax)
    bcache.head.next = b;
80100096:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100099:	a3 94 eb 10 80       	mov    %eax,0x8010eb94

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
  bcache.head.next = &bcache.head;
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
8010009e:	81 45 f4 18 02 00 00 	addl   $0x218,-0xc(%ebp)
801000a5:	81 7d f4 84 eb 10 80 	cmpl   $0x8010eb84,-0xc(%ebp)
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
801000b6:	c7 04 24 60 d6 10 80 	movl   $0x8010d660,(%esp)
801000bd:	e8 f1 4f 00 00       	call   801050b3 <acquire>

 loop:
  // Is the sector already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
801000c2:	a1 94 eb 10 80       	mov    0x8010eb94,%eax
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
801000fd:	c7 04 24 60 d6 10 80 	movl   $0x8010d660,(%esp)
80100104:	e8 45 50 00 00       	call   8010514e <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 60 d6 10 	movl   $0x8010d660,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 50 4c 00 00       	call   80104d74 <sleep>
      goto loop;
80100124:	eb 9c                	jmp    801000c2 <bget+0x12>

  acquire(&bcache.lock);

 loop:
  // Is the sector already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
80100126:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100129:	8b 40 10             	mov    0x10(%eax),%eax
8010012c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010012f:	81 7d f4 84 eb 10 80 	cmpl   $0x8010eb84,-0xc(%ebp)
80100136:	75 94                	jne    801000cc <bget+0x1c>
      goto loop;
    }
  }

  // Not cached; recycle some non-busy and clean buffer.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100138:	a1 90 eb 10 80       	mov    0x8010eb90,%eax
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
80100175:	c7 04 24 60 d6 10 80 	movl   $0x8010d660,(%esp)
8010017c:	e8 cd 4f 00 00       	call   8010514e <release>
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
8010018f:	81 7d f4 84 eb 10 80 	cmpl   $0x8010eb84,-0xc(%ebp)
80100196:	75 aa                	jne    80100142 <bget+0x92>
      b->flags = B_BUSY;
      release(&bcache.lock);
      return b;
    }
  }
  panic("bget: no buffers");
80100198:	c7 04 24 8b 88 10 80 	movl   $0x8010888b,(%esp)
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
801001ef:	c7 04 24 9c 88 10 80 	movl   $0x8010889c,(%esp)
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
80100229:	c7 04 24 a3 88 10 80 	movl   $0x801088a3,(%esp)
80100230:	e8 08 03 00 00       	call   8010053d <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 60 d6 10 80 	movl   $0x8010d660,(%esp)
8010023c:	e8 72 4e 00 00       	call   801050b3 <acquire>

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
8010025f:	8b 15 94 eb 10 80    	mov    0x8010eb94,%edx
80100265:	8b 45 08             	mov    0x8(%ebp),%eax
80100268:	89 50 10             	mov    %edx,0x10(%eax)
  b->prev = &bcache.head;
8010026b:	8b 45 08             	mov    0x8(%ebp),%eax
8010026e:	c7 40 0c 84 eb 10 80 	movl   $0x8010eb84,0xc(%eax)
  bcache.head.next->prev = b;
80100275:	a1 94 eb 10 80       	mov    0x8010eb94,%eax
8010027a:	8b 55 08             	mov    0x8(%ebp),%edx
8010027d:	89 50 0c             	mov    %edx,0xc(%eax)
  bcache.head.next = b;
80100280:	8b 45 08             	mov    0x8(%ebp),%eax
80100283:	a3 94 eb 10 80       	mov    %eax,0x8010eb94

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
8010029d:	e8 06 4c 00 00       	call   80104ea8 <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 60 d6 10 80 	movl   $0x8010d660,(%esp)
801002a9:	e8 a0 4e 00 00       	call   8010514e <release>
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
801003a7:	a1 f4 c5 10 80       	mov    0x8010c5f4,%eax
801003ac:	89 45 e8             	mov    %eax,-0x18(%ebp)
  if(locking)
801003af:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801003b3:	74 0c                	je     801003c1 <cprintf+0x20>
    acquire(&cons.lock);
801003b5:	c7 04 24 c0 c5 10 80 	movl   $0x8010c5c0,(%esp)
801003bc:	e8 f2 4c 00 00       	call   801050b3 <acquire>

  if (fmt == 0)
801003c1:	8b 45 08             	mov    0x8(%ebp),%eax
801003c4:	85 c0                	test   %eax,%eax
801003c6:	75 0c                	jne    801003d4 <cprintf+0x33>
    panic("null fmt");
801003c8:	c7 04 24 aa 88 10 80 	movl   $0x801088aa,(%esp)
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
801004af:	c7 45 ec b3 88 10 80 	movl   $0x801088b3,-0x14(%ebp)
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
8010052f:	c7 04 24 c0 c5 10 80 	movl   $0x8010c5c0,(%esp)
80100536:	e8 13 4c 00 00       	call   8010514e <release>
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
80100548:	c7 05 f4 c5 10 80 00 	movl   $0x0,0x8010c5f4
8010054f:	00 00 00 
  cprintf("cpu%d: panic: ", cpu->id);
80100552:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80100558:	0f b6 00             	movzbl (%eax),%eax
8010055b:	0f b6 c0             	movzbl %al,%eax
8010055e:	89 44 24 04          	mov    %eax,0x4(%esp)
80100562:	c7 04 24 ba 88 10 80 	movl   $0x801088ba,(%esp)
80100569:	e8 33 fe ff ff       	call   801003a1 <cprintf>
  cprintf(s);
8010056e:	8b 45 08             	mov    0x8(%ebp),%eax
80100571:	89 04 24             	mov    %eax,(%esp)
80100574:	e8 28 fe ff ff       	call   801003a1 <cprintf>
  cprintf("\n");
80100579:	c7 04 24 c9 88 10 80 	movl   $0x801088c9,(%esp)
80100580:	e8 1c fe ff ff       	call   801003a1 <cprintf>
  getcallerpcs(&s, pcs);
80100585:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100588:	89 44 24 04          	mov    %eax,0x4(%esp)
8010058c:	8d 45 08             	lea    0x8(%ebp),%eax
8010058f:	89 04 24             	mov    %eax,(%esp)
80100592:	e8 06 4c 00 00       	call   8010519d <getcallerpcs>
  for(i=0; i<10; i++)
80100597:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010059e:	eb 1b                	jmp    801005bb <panic+0x7e>
    cprintf(" %p", pcs[i]);
801005a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005a3:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005a7:	89 44 24 04          	mov    %eax,0x4(%esp)
801005ab:	c7 04 24 cb 88 10 80 	movl   $0x801088cb,(%esp)
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
801005c1:	c7 05 a0 c5 10 80 01 	movl   $0x1,0x8010c5a0
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
801006b2:	e8 56 4d 00 00       	call   8010540d <memmove>
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
801006e1:	e8 54 4c 00 00       	call   8010533a <memset>
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
80100756:	a1 a0 c5 10 80       	mov    0x8010c5a0,%eax
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
80100776:	e8 3a 67 00 00       	call   80106eb5 <uartputc>
8010077b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80100782:	e8 2e 67 00 00       	call   80106eb5 <uartputc>
80100787:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
8010078e:	e8 22 67 00 00       	call   80106eb5 <uartputc>
80100793:	eb 0b                	jmp    801007a0 <consputc+0x50>
  } else
    uartputc(c);
80100795:	8b 45 08             	mov    0x8(%ebp),%eax
80100798:	89 04 24             	mov    %eax,(%esp)
8010079b:	e8 15 67 00 00       	call   80106eb5 <uartputc>
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
801007b3:	c7 04 24 a0 ed 10 80 	movl   $0x8010eda0,(%esp)
801007ba:	e8 f4 48 00 00       	call   801050b3 <acquire>
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
801007ea:	e8 5f 47 00 00       	call   80104f4e <procdump>
      break;
801007ef:	e9 11 01 00 00       	jmp    80100905 <consoleintr+0x158>
    case C('U'):  // Kill line.
      while(input.e != input.w &&
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
801007f4:	a1 5c ee 10 80       	mov    0x8010ee5c,%eax
801007f9:	83 e8 01             	sub    $0x1,%eax
801007fc:	a3 5c ee 10 80       	mov    %eax,0x8010ee5c
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
80100810:	8b 15 5c ee 10 80    	mov    0x8010ee5c,%edx
80100816:	a1 58 ee 10 80       	mov    0x8010ee58,%eax
8010081b:	39 c2                	cmp    %eax,%edx
8010081d:	0f 84 db 00 00 00    	je     801008fe <consoleintr+0x151>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
80100823:	a1 5c ee 10 80       	mov    0x8010ee5c,%eax
80100828:	83 e8 01             	sub    $0x1,%eax
8010082b:	83 e0 7f             	and    $0x7f,%eax
8010082e:	0f b6 80 d4 ed 10 80 	movzbl -0x7fef122c(%eax),%eax
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
8010083e:	8b 15 5c ee 10 80    	mov    0x8010ee5c,%edx
80100844:	a1 58 ee 10 80       	mov    0x8010ee58,%eax
80100849:	39 c2                	cmp    %eax,%edx
8010084b:	0f 84 b0 00 00 00    	je     80100901 <consoleintr+0x154>
        input.e--;
80100851:	a1 5c ee 10 80       	mov    0x8010ee5c,%eax
80100856:	83 e8 01             	sub    $0x1,%eax
80100859:	a3 5c ee 10 80       	mov    %eax,0x8010ee5c
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
80100879:	8b 15 5c ee 10 80    	mov    0x8010ee5c,%edx
8010087f:	a1 54 ee 10 80       	mov    0x8010ee54,%eax
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
801008a2:	a1 5c ee 10 80       	mov    0x8010ee5c,%eax
801008a7:	89 c1                	mov    %eax,%ecx
801008a9:	83 e1 7f             	and    $0x7f,%ecx
801008ac:	8b 55 f4             	mov    -0xc(%ebp),%edx
801008af:	88 91 d4 ed 10 80    	mov    %dl,-0x7fef122c(%ecx)
801008b5:	83 c0 01             	add    $0x1,%eax
801008b8:	a3 5c ee 10 80       	mov    %eax,0x8010ee5c
        consputc(c);
801008bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801008c0:	89 04 24             	mov    %eax,(%esp)
801008c3:	e8 88 fe ff ff       	call   80100750 <consputc>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
801008c8:	83 7d f4 0a          	cmpl   $0xa,-0xc(%ebp)
801008cc:	74 18                	je     801008e6 <consoleintr+0x139>
801008ce:	83 7d f4 04          	cmpl   $0x4,-0xc(%ebp)
801008d2:	74 12                	je     801008e6 <consoleintr+0x139>
801008d4:	a1 5c ee 10 80       	mov    0x8010ee5c,%eax
801008d9:	8b 15 54 ee 10 80    	mov    0x8010ee54,%edx
801008df:	83 ea 80             	sub    $0xffffff80,%edx
801008e2:	39 d0                	cmp    %edx,%eax
801008e4:	75 1e                	jne    80100904 <consoleintr+0x157>
          input.w = input.e;
801008e6:	a1 5c ee 10 80       	mov    0x8010ee5c,%eax
801008eb:	a3 58 ee 10 80       	mov    %eax,0x8010ee58
          wakeup(&input.r);
801008f0:	c7 04 24 54 ee 10 80 	movl   $0x8010ee54,(%esp)
801008f7:	e8 ac 45 00 00       	call   80104ea8 <wakeup>
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
80100917:	c7 04 24 a0 ed 10 80 	movl   $0x8010eda0,(%esp)
8010091e:	e8 2b 48 00 00       	call   8010514e <release>
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
8010093c:	c7 04 24 a0 ed 10 80 	movl   $0x8010eda0,(%esp)
80100943:	e8 6b 47 00 00       	call   801050b3 <acquire>
  while(n > 0){
80100948:	e9 a8 00 00 00       	jmp    801009f5 <consoleread+0xd0>
    while(input.r == input.w){
      if(proc->killed){
8010094d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100953:	8b 40 24             	mov    0x24(%eax),%eax
80100956:	85 c0                	test   %eax,%eax
80100958:	74 21                	je     8010097b <consoleread+0x56>
        release(&input.lock);
8010095a:	c7 04 24 a0 ed 10 80 	movl   $0x8010eda0,(%esp)
80100961:	e8 e8 47 00 00       	call   8010514e <release>
        ilock(ip);
80100966:	8b 45 08             	mov    0x8(%ebp),%eax
80100969:	89 04 24             	mov    %eax,(%esp)
8010096c:	e8 f7 0e 00 00       	call   80101868 <ilock>
        return -1;
80100971:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100976:	e9 a9 00 00 00       	jmp    80100a24 <consoleread+0xff>
      }
      sleep(&input.r, &input.lock);
8010097b:	c7 44 24 04 a0 ed 10 	movl   $0x8010eda0,0x4(%esp)
80100982:	80 
80100983:	c7 04 24 54 ee 10 80 	movl   $0x8010ee54,(%esp)
8010098a:	e8 e5 43 00 00       	call   80104d74 <sleep>
8010098f:	eb 01                	jmp    80100992 <consoleread+0x6d>

  iunlock(ip);
  target = n;
  acquire(&input.lock);
  while(n > 0){
    while(input.r == input.w){
80100991:	90                   	nop
80100992:	8b 15 54 ee 10 80    	mov    0x8010ee54,%edx
80100998:	a1 58 ee 10 80       	mov    0x8010ee58,%eax
8010099d:	39 c2                	cmp    %eax,%edx
8010099f:	74 ac                	je     8010094d <consoleread+0x28>
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &input.lock);
    }
    c = input.buf[input.r++ % INPUT_BUF];
801009a1:	a1 54 ee 10 80       	mov    0x8010ee54,%eax
801009a6:	89 c2                	mov    %eax,%edx
801009a8:	83 e2 7f             	and    $0x7f,%edx
801009ab:	0f b6 92 d4 ed 10 80 	movzbl -0x7fef122c(%edx),%edx
801009b2:	0f be d2             	movsbl %dl,%edx
801009b5:	89 55 f0             	mov    %edx,-0x10(%ebp)
801009b8:	83 c0 01             	add    $0x1,%eax
801009bb:	a3 54 ee 10 80       	mov    %eax,0x8010ee54
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
801009ce:	a1 54 ee 10 80       	mov    0x8010ee54,%eax
801009d3:	83 e8 01             	sub    $0x1,%eax
801009d6:	a3 54 ee 10 80       	mov    %eax,0x8010ee54
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
80100a01:	c7 04 24 a0 ed 10 80 	movl   $0x8010eda0,(%esp)
80100a08:	e8 41 47 00 00       	call   8010514e <release>
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
80100a37:	c7 04 24 c0 c5 10 80 	movl   $0x8010c5c0,(%esp)
80100a3e:	e8 70 46 00 00       	call   801050b3 <acquire>
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
80100a71:	c7 04 24 c0 c5 10 80 	movl   $0x8010c5c0,(%esp)
80100a78:	e8 d1 46 00 00       	call   8010514e <release>
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
80100a93:	c7 44 24 04 cf 88 10 	movl   $0x801088cf,0x4(%esp)
80100a9a:	80 
80100a9b:	c7 04 24 c0 c5 10 80 	movl   $0x8010c5c0,(%esp)
80100aa2:	e8 eb 45 00 00       	call   80105092 <initlock>
  initlock(&input.lock, "input");
80100aa7:	c7 44 24 04 d7 88 10 	movl   $0x801088d7,0x4(%esp)
80100aae:	80 
80100aaf:	c7 04 24 a0 ed 10 80 	movl   $0x8010eda0,(%esp)
80100ab6:	e8 d7 45 00 00       	call   80105092 <initlock>

  devsw[CONSOLE].write = consolewrite;
80100abb:	c7 05 0c f8 10 80 26 	movl   $0x80100a26,0x8010f80c
80100ac2:	0a 10 80 
  devsw[CONSOLE].read = consoleread;
80100ac5:	c7 05 08 f8 10 80 25 	movl   $0x80100925,0x8010f808
80100acc:	09 10 80 
  cons.locking = 1;
80100acf:	c7 05 f4 c5 10 80 01 	movl   $0x1,0x8010c5f4
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
80100b7b:	e8 79 74 00 00       	call   80107ff9 <setupkvm>
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
80100c14:	e8 b2 77 00 00       	call   801083cb <allocuvm>
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
80100c51:	e8 86 76 00 00       	call   801082dc <loaduvm>
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
80100cbc:	e8 0a 77 00 00       	call   801083cb <allocuvm>
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
80100ce0:	e8 3c 79 00 00       	call   80108621 <clearpteu>
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
80100d0f:	e8 a4 48 00 00       	call   801055b8 <strlen>
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
80100d2d:	e8 86 48 00 00       	call   801055b8 <strlen>
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
80100d57:	e8 79 7a 00 00       	call   801087d5 <copyout>
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
80100df7:	e8 d9 79 00 00       	call   801087d5 <copyout>
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
80100e4e:	e8 17 47 00 00       	call   8010556a <safestrcpy>

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
80100ea0:	e8 45 72 00 00       	call   801080ea <switchuvm>
  freevm(oldpgdir);
80100ea5:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100ea8:	89 04 24             	mov    %eax,(%esp)
80100eab:	e8 b1 76 00 00       	call   80108561 <freevm>
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
80100ee2:	e8 7a 76 00 00       	call   80108561 <freevm>
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
80100f06:	c7 44 24 04 dd 88 10 	movl   $0x801088dd,0x4(%esp)
80100f0d:	80 
80100f0e:	c7 04 24 60 ee 10 80 	movl   $0x8010ee60,(%esp)
80100f15:	e8 78 41 00 00       	call   80105092 <initlock>
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
80100f22:	c7 04 24 60 ee 10 80 	movl   $0x8010ee60,(%esp)
80100f29:	e8 85 41 00 00       	call   801050b3 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100f2e:	c7 45 f4 94 ee 10 80 	movl   $0x8010ee94,-0xc(%ebp)
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
80100f4b:	c7 04 24 60 ee 10 80 	movl   $0x8010ee60,(%esp)
80100f52:	e8 f7 41 00 00       	call   8010514e <release>
      return f;
80100f57:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f5a:	eb 1e                	jmp    80100f7a <filealloc+0x5e>
filealloc(void)
{
  struct file *f;

  acquire(&ftable.lock);
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100f5c:	83 45 f4 18          	addl   $0x18,-0xc(%ebp)
80100f60:	81 7d f4 f4 f7 10 80 	cmpl   $0x8010f7f4,-0xc(%ebp)
80100f67:	72 ce                	jb     80100f37 <filealloc+0x1b>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
80100f69:	c7 04 24 60 ee 10 80 	movl   $0x8010ee60,(%esp)
80100f70:	e8 d9 41 00 00       	call   8010514e <release>
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
80100f82:	c7 04 24 60 ee 10 80 	movl   $0x8010ee60,(%esp)
80100f89:	e8 25 41 00 00       	call   801050b3 <acquire>
  if(f->ref < 1)
80100f8e:	8b 45 08             	mov    0x8(%ebp),%eax
80100f91:	8b 40 04             	mov    0x4(%eax),%eax
80100f94:	85 c0                	test   %eax,%eax
80100f96:	7f 0c                	jg     80100fa4 <filedup+0x28>
    panic("filedup");
80100f98:	c7 04 24 e4 88 10 80 	movl   $0x801088e4,(%esp)
80100f9f:	e8 99 f5 ff ff       	call   8010053d <panic>
  f->ref++;
80100fa4:	8b 45 08             	mov    0x8(%ebp),%eax
80100fa7:	8b 40 04             	mov    0x4(%eax),%eax
80100faa:	8d 50 01             	lea    0x1(%eax),%edx
80100fad:	8b 45 08             	mov    0x8(%ebp),%eax
80100fb0:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
80100fb3:	c7 04 24 60 ee 10 80 	movl   $0x8010ee60,(%esp)
80100fba:	e8 8f 41 00 00       	call   8010514e <release>
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
80100fca:	c7 04 24 60 ee 10 80 	movl   $0x8010ee60,(%esp)
80100fd1:	e8 dd 40 00 00       	call   801050b3 <acquire>
  if(f->ref < 1)
80100fd6:	8b 45 08             	mov    0x8(%ebp),%eax
80100fd9:	8b 40 04             	mov    0x4(%eax),%eax
80100fdc:	85 c0                	test   %eax,%eax
80100fde:	7f 0c                	jg     80100fec <fileclose+0x28>
    panic("fileclose");
80100fe0:	c7 04 24 ec 88 10 80 	movl   $0x801088ec,(%esp)
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
80101005:	c7 04 24 60 ee 10 80 	movl   $0x8010ee60,(%esp)
8010100c:	e8 3d 41 00 00       	call   8010514e <release>
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
8010104f:	c7 04 24 60 ee 10 80 	movl   $0x8010ee60,(%esp)
80101056:	e8 f3 40 00 00       	call   8010514e <release>
  
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
80101197:	c7 04 24 f6 88 10 80 	movl   $0x801088f6,(%esp)
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
801012a3:	c7 04 24 ff 88 10 80 	movl   $0x801088ff,(%esp)
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
801012d8:	c7 04 24 0f 89 10 80 	movl   $0x8010890f,(%esp)
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
80101320:	e8 e8 40 00 00       	call   8010540d <memmove>
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
80101366:	e8 cf 3f 00 00       	call   8010533a <memset>
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
801014ce:	c7 04 24 19 89 10 80 	movl   $0x80108919,(%esp)
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
80101565:	c7 04 24 2f 89 10 80 	movl   $0x8010892f,(%esp)
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
801015b9:	c7 44 24 04 42 89 10 	movl   $0x80108942,0x4(%esp)
801015c0:	80 
801015c1:	c7 04 24 60 f8 10 80 	movl   $0x8010f860,(%esp)
801015c8:	e8 c5 3a 00 00       	call   80105092 <initlock>
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
8010164a:	e8 eb 3c 00 00       	call   8010533a <memset>
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
801016a0:	c7 04 24 49 89 10 80 	movl   $0x80108949,(%esp)
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
80101747:	e8 c1 3c 00 00       	call   8010540d <memmove>
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
8010176a:	c7 04 24 60 f8 10 80 	movl   $0x8010f860,(%esp)
80101771:	e8 3d 39 00 00       	call   801050b3 <acquire>

  // Is the inode already cached?
  empty = 0;
80101776:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
8010177d:	c7 45 f4 94 f8 10 80 	movl   $0x8010f894,-0xc(%ebp)
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
801017b4:	c7 04 24 60 f8 10 80 	movl   $0x8010f860,(%esp)
801017bb:	e8 8e 39 00 00       	call   8010514e <release>
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
801017df:	81 7d f4 34 08 11 80 	cmpl   $0x80110834,-0xc(%ebp)
801017e6:	72 9e                	jb     80101786 <iget+0x22>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
      empty = ip;
  }

  // Recycle an inode cache entry.
  if(empty == 0)
801017e8:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801017ec:	75 0c                	jne    801017fa <iget+0x96>
    panic("iget: no inodes");
801017ee:	c7 04 24 5b 89 10 80 	movl   $0x8010895b,(%esp)
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
80101825:	c7 04 24 60 f8 10 80 	movl   $0x8010f860,(%esp)
8010182c:	e8 1d 39 00 00       	call   8010514e <release>

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
8010183c:	c7 04 24 60 f8 10 80 	movl   $0x8010f860,(%esp)
80101843:	e8 6b 38 00 00       	call   801050b3 <acquire>
  ip->ref++;
80101848:	8b 45 08             	mov    0x8(%ebp),%eax
8010184b:	8b 40 08             	mov    0x8(%eax),%eax
8010184e:	8d 50 01             	lea    0x1(%eax),%edx
80101851:	8b 45 08             	mov    0x8(%ebp),%eax
80101854:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101857:	c7 04 24 60 f8 10 80 	movl   $0x8010f860,(%esp)
8010185e:	e8 eb 38 00 00       	call   8010514e <release>
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
8010187e:	c7 04 24 6b 89 10 80 	movl   $0x8010896b,(%esp)
80101885:	e8 b3 ec ff ff       	call   8010053d <panic>

  acquire(&icache.lock);
8010188a:	c7 04 24 60 f8 10 80 	movl   $0x8010f860,(%esp)
80101891:	e8 1d 38 00 00       	call   801050b3 <acquire>
  while(ip->flags & I_BUSY)
80101896:	eb 13                	jmp    801018ab <ilock+0x43>
    sleep(ip, &icache.lock);
80101898:	c7 44 24 04 60 f8 10 	movl   $0x8010f860,0x4(%esp)
8010189f:	80 
801018a0:	8b 45 08             	mov    0x8(%ebp),%eax
801018a3:	89 04 24             	mov    %eax,(%esp)
801018a6:	e8 c9 34 00 00       	call   80104d74 <sleep>

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
801018c9:	c7 04 24 60 f8 10 80 	movl   $0x8010f860,(%esp)
801018d0:	e8 79 38 00 00       	call   8010514e <release>

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
8010197b:	e8 8d 3a 00 00       	call   8010540d <memmove>
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
801019a8:	c7 04 24 71 89 10 80 	movl   $0x80108971,(%esp)
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
801019d9:	c7 04 24 80 89 10 80 	movl   $0x80108980,(%esp)
801019e0:	e8 58 eb ff ff       	call   8010053d <panic>
  acquire(&icache.lock);
801019e5:	c7 04 24 60 f8 10 80 	movl   $0x8010f860,(%esp)
801019ec:	e8 c2 36 00 00       	call   801050b3 <acquire>
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
80101a08:	e8 9b 34 00 00       	call   80104ea8 <wakeup>
  release(&icache.lock);
80101a0d:	c7 04 24 60 f8 10 80 	movl   $0x8010f860,(%esp)
80101a14:	e8 35 37 00 00       	call   8010514e <release>
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
80101a21:	c7 04 24 60 f8 10 80 	movl   $0x8010f860,(%esp)
80101a28:	e8 86 36 00 00       	call   801050b3 <acquire>
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
80101a66:	c7 04 24 88 89 10 80 	movl   $0x80108988,(%esp)
80101a6d:	e8 cb ea ff ff       	call   8010053d <panic>
    ip->flags |= I_BUSY;
80101a72:	8b 45 08             	mov    0x8(%ebp),%eax
80101a75:	8b 40 0c             	mov    0xc(%eax),%eax
80101a78:	89 c2                	mov    %eax,%edx
80101a7a:	83 ca 01             	or     $0x1,%edx
80101a7d:	8b 45 08             	mov    0x8(%ebp),%eax
80101a80:	89 50 0c             	mov    %edx,0xc(%eax)
    release(&icache.lock);
80101a83:	c7 04 24 60 f8 10 80 	movl   $0x8010f860,(%esp)
80101a8a:	e8 bf 36 00 00       	call   8010514e <release>
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
80101aae:	c7 04 24 60 f8 10 80 	movl   $0x8010f860,(%esp)
80101ab5:	e8 f9 35 00 00       	call   801050b3 <acquire>
    ip->flags = 0;
80101aba:	8b 45 08             	mov    0x8(%ebp),%eax
80101abd:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
80101ac4:	8b 45 08             	mov    0x8(%ebp),%eax
80101ac7:	89 04 24             	mov    %eax,(%esp)
80101aca:	e8 d9 33 00 00       	call   80104ea8 <wakeup>
  }
  ip->ref--;
80101acf:	8b 45 08             	mov    0x8(%ebp),%eax
80101ad2:	8b 40 08             	mov    0x8(%eax),%eax
80101ad5:	8d 50 ff             	lea    -0x1(%eax),%edx
80101ad8:	8b 45 08             	mov    0x8(%ebp),%eax
80101adb:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101ade:	c7 04 24 60 f8 10 80 	movl   $0x8010f860,(%esp)
80101ae5:	e8 64 36 00 00       	call   8010514e <release>
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
80101bfa:	c7 04 24 92 89 10 80 	movl   $0x80108992,(%esp)
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
80101d93:	8b 04 c5 00 f8 10 80 	mov    -0x7fef0800(,%eax,8),%eax
80101d9a:	85 c0                	test   %eax,%eax
80101d9c:	75 0a                	jne    80101da8 <readi+0x4a>
      return -1;
80101d9e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101da3:	e9 1b 01 00 00       	jmp    80101ec3 <readi+0x165>
    return devsw[ip->major].read(ip, dst, n);
80101da8:	8b 45 08             	mov    0x8(%ebp),%eax
80101dab:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101daf:	98                   	cwtl   
80101db0:	8b 14 c5 00 f8 10 80 	mov    -0x7fef0800(,%eax,8),%edx
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
80101e92:	e8 76 35 00 00       	call   8010540d <memmove>
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
80101efe:	8b 04 c5 04 f8 10 80 	mov    -0x7fef07fc(,%eax,8),%eax
80101f05:	85 c0                	test   %eax,%eax
80101f07:	75 0a                	jne    80101f13 <writei+0x4a>
      return -1;
80101f09:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101f0e:	e9 46 01 00 00       	jmp    80102059 <writei+0x190>
    return devsw[ip->major].write(ip, src, n);
80101f13:	8b 45 08             	mov    0x8(%ebp),%eax
80101f16:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101f1a:	98                   	cwtl   
80101f1b:	8b 14 c5 04 f8 10 80 	mov    -0x7fef07fc(,%eax,8),%edx
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
80101ff8:	e8 10 34 00 00       	call   8010540d <memmove>
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
8010207a:	e8 32 34 00 00       	call   801054b1 <strncmp>
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
80102094:	c7 04 24 a5 89 10 80 	movl   $0x801089a5,(%esp)
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
801020d2:	c7 04 24 b7 89 10 80 	movl   $0x801089b7,(%esp)
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
801021b6:	c7 04 24 b7 89 10 80 	movl   $0x801089b7,(%esp)
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
801021fc:	e8 08 33 00 00       	call   80105509 <strncpy>
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
8010222e:	c7 04 24 c4 89 10 80 	movl   $0x801089c4,(%esp)
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
801022b5:	e8 53 31 00 00       	call   8010540d <memmove>
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
801022d0:	e8 38 31 00 00       	call   8010540d <memmove>
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
8010252c:	c7 44 24 04 cc 89 10 	movl   $0x801089cc,0x4(%esp)
80102533:	80 
80102534:	c7 04 24 00 c6 10 80 	movl   $0x8010c600,(%esp)
8010253b:	e8 52 2b 00 00       	call   80105092 <initlock>
  picenable(IRQ_IDE);
80102540:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
80102547:	e8 81 15 00 00       	call   80103acd <picenable>
  ioapicenable(IRQ_IDE, ncpu - 1);
8010254c:	a1 00 0f 11 80       	mov    0x80110f00,%eax
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
8010259d:	c7 05 38 c6 10 80 01 	movl   $0x1,0x8010c638
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
801025d8:	c7 04 24 d0 89 10 80 	movl   $0x801089d0,(%esp)
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
801026f7:	c7 04 24 00 c6 10 80 	movl   $0x8010c600,(%esp)
801026fe:	e8 b0 29 00 00       	call   801050b3 <acquire>
  if((b = idequeue) == 0){
80102703:	a1 34 c6 10 80       	mov    0x8010c634,%eax
80102708:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010270b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010270f:	75 11                	jne    80102722 <ideintr+0x31>
    release(&idelock);
80102711:	c7 04 24 00 c6 10 80 	movl   $0x8010c600,(%esp)
80102718:	e8 31 2a 00 00       	call   8010514e <release>
    // cprintf("spurious IDE interrupt\n");
    return;
8010271d:	e9 85 00 00 00       	jmp    801027a7 <ideintr+0xb6>
  }
  idequeue = b->qnext;
80102722:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102725:	8b 40 14             	mov    0x14(%eax),%eax
80102728:	a3 34 c6 10 80       	mov    %eax,0x8010c634

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
80102785:	a1 34 c6 10 80       	mov    0x8010c634,%eax
8010278a:	85 c0                	test   %eax,%eax
8010278c:	74 0d                	je     8010279b <ideintr+0xaa>
    idestart(idequeue);
8010278e:	a1 34 c6 10 80       	mov    0x8010c634,%eax
80102793:	89 04 24             	mov    %eax,(%esp)
80102796:	e8 31 fe ff ff       	call   801025cc <idestart>

  release(&idelock);
8010279b:	c7 04 24 00 c6 10 80 	movl   $0x8010c600,(%esp)
801027a2:	e8 a7 29 00 00       	call   8010514e <release>
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
801027bb:	c7 04 24 d9 89 10 80 	movl   $0x801089d9,(%esp)
801027c2:	e8 76 dd ff ff       	call   8010053d <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
801027c7:	8b 45 08             	mov    0x8(%ebp),%eax
801027ca:	8b 00                	mov    (%eax),%eax
801027cc:	83 e0 06             	and    $0x6,%eax
801027cf:	83 f8 02             	cmp    $0x2,%eax
801027d2:	75 0c                	jne    801027e0 <iderw+0x37>
    panic("iderw: nothing to do");
801027d4:	c7 04 24 ed 89 10 80 	movl   $0x801089ed,(%esp)
801027db:	e8 5d dd ff ff       	call   8010053d <panic>
  if(b->dev != 0 && !havedisk1)
801027e0:	8b 45 08             	mov    0x8(%ebp),%eax
801027e3:	8b 40 04             	mov    0x4(%eax),%eax
801027e6:	85 c0                	test   %eax,%eax
801027e8:	74 15                	je     801027ff <iderw+0x56>
801027ea:	a1 38 c6 10 80       	mov    0x8010c638,%eax
801027ef:	85 c0                	test   %eax,%eax
801027f1:	75 0c                	jne    801027ff <iderw+0x56>
    panic("iderw: ide disk 1 not present");
801027f3:	c7 04 24 02 8a 10 80 	movl   $0x80108a02,(%esp)
801027fa:	e8 3e dd ff ff       	call   8010053d <panic>

  acquire(&idelock);  //DOC: acquire-lock
801027ff:	c7 04 24 00 c6 10 80 	movl   $0x8010c600,(%esp)
80102806:	e8 a8 28 00 00       	call   801050b3 <acquire>

  // Append b to idequeue.
  b->qnext = 0;
8010280b:	8b 45 08             	mov    0x8(%ebp),%eax
8010280e:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC: insert-queue
80102815:	c7 45 f4 34 c6 10 80 	movl   $0x8010c634,-0xc(%ebp)
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
8010283a:	a1 34 c6 10 80       	mov    0x8010c634,%eax
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
80102851:	c7 04 24 00 c6 10 80 	movl   $0x8010c600,(%esp)
80102858:	e8 ad 29 00 00       	call   8010520a <holding>
8010285d:	85 c0                	test   %eax,%eax
8010285f:	74 0f                	je     80102870 <iderw+0xc7>
      release(&idelock);
80102861:	c7 04 24 00 c6 10 80 	movl   $0x8010c600,(%esp)
80102868:	e8 e1 28 00 00       	call   8010514e <release>
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
8010287d:	c7 04 24 00 c6 10 80 	movl   $0x8010c600,(%esp)
80102884:	e8 81 29 00 00       	call   8010520a <holding>
80102889:	85 c0                	test   %eax,%eax
8010288b:	74 0c                	je     80102899 <iderw+0xf0>
    release(&idelock);
8010288d:	c7 04 24 00 c6 10 80 	movl   $0x8010c600,(%esp)
80102894:	e8 b5 28 00 00       	call   8010514e <release>
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
8010289f:	a1 34 08 11 80       	mov    0x80110834,%eax
801028a4:	8b 55 08             	mov    0x8(%ebp),%edx
801028a7:	89 10                	mov    %edx,(%eax)
  return ioapic->data;
801028a9:	a1 34 08 11 80       	mov    0x80110834,%eax
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
801028b6:	a1 34 08 11 80       	mov    0x80110834,%eax
801028bb:	8b 55 08             	mov    0x8(%ebp),%edx
801028be:	89 10                	mov    %edx,(%eax)
  ioapic->data = data;
801028c0:	a1 34 08 11 80       	mov    0x80110834,%eax
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
801028d3:	a1 04 09 11 80       	mov    0x80110904,%eax
801028d8:	85 c0                	test   %eax,%eax
801028da:	0f 84 9f 00 00 00    	je     8010297f <ioapicinit+0xb2>
    return;

  ioapic = (volatile struct ioapic*)IOAPIC;
801028e0:	c7 05 34 08 11 80 00 	movl   $0xfec00000,0x80110834
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
80102913:	0f b6 05 00 09 11 80 	movzbl 0x80110900,%eax
8010291a:	0f b6 c0             	movzbl %al,%eax
8010291d:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80102920:	74 0c                	je     8010292e <ioapicinit+0x61>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80102922:	c7 04 24 20 8a 10 80 	movl   $0x80108a20,(%esp)
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
80102988:	a1 04 09 11 80       	mov    0x80110904,%eax
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
801029e3:	c7 44 24 04 52 8a 10 	movl   $0x80108a52,0x4(%esp)
801029ea:	80 
801029eb:	c7 04 24 40 08 11 80 	movl   $0x80110840,(%esp)
801029f2:	e8 9b 26 00 00       	call   80105092 <initlock>
  kmem.use_lock = 0;
801029f7:	c7 05 74 08 11 80 00 	movl   $0x0,0x80110874
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
80102a2d:	c7 05 74 08 11 80 01 	movl   $0x1,0x80110874
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
80102a84:	81 7d 08 fc 38 11 80 	cmpl   $0x801138fc,0x8(%ebp)
80102a8b:	72 12                	jb     80102a9f <kfree+0x2d>
80102a8d:	8b 45 08             	mov    0x8(%ebp),%eax
80102a90:	89 04 24             	mov    %eax,(%esp)
80102a93:	e8 38 ff ff ff       	call   801029d0 <v2p>
80102a98:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80102a9d:	76 0c                	jbe    80102aab <kfree+0x39>
    panic("kfree");
80102a9f:	c7 04 24 57 8a 10 80 	movl   $0x80108a57,(%esp)
80102aa6:	e8 92 da ff ff       	call   8010053d <panic>

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80102aab:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80102ab2:	00 
80102ab3:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102aba:	00 
80102abb:	8b 45 08             	mov    0x8(%ebp),%eax
80102abe:	89 04 24             	mov    %eax,(%esp)
80102ac1:	e8 74 28 00 00       	call   8010533a <memset>

  if(kmem.use_lock)
80102ac6:	a1 74 08 11 80       	mov    0x80110874,%eax
80102acb:	85 c0                	test   %eax,%eax
80102acd:	74 0c                	je     80102adb <kfree+0x69>
    acquire(&kmem.lock);
80102acf:	c7 04 24 40 08 11 80 	movl   $0x80110840,(%esp)
80102ad6:	e8 d8 25 00 00       	call   801050b3 <acquire>
  r = (struct run*)v;
80102adb:	8b 45 08             	mov    0x8(%ebp),%eax
80102ade:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
80102ae1:	8b 15 78 08 11 80    	mov    0x80110878,%edx
80102ae7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102aea:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
80102aec:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102aef:	a3 78 08 11 80       	mov    %eax,0x80110878
  if(kmem.use_lock)
80102af4:	a1 74 08 11 80       	mov    0x80110874,%eax
80102af9:	85 c0                	test   %eax,%eax
80102afb:	74 0c                	je     80102b09 <kfree+0x97>
    release(&kmem.lock);
80102afd:	c7 04 24 40 08 11 80 	movl   $0x80110840,(%esp)
80102b04:	e8 45 26 00 00       	call   8010514e <release>
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
80102b11:	a1 74 08 11 80       	mov    0x80110874,%eax
80102b16:	85 c0                	test   %eax,%eax
80102b18:	74 0c                	je     80102b26 <kalloc+0x1b>
    acquire(&kmem.lock);
80102b1a:	c7 04 24 40 08 11 80 	movl   $0x80110840,(%esp)
80102b21:	e8 8d 25 00 00       	call   801050b3 <acquire>
  r = kmem.freelist;
80102b26:	a1 78 08 11 80       	mov    0x80110878,%eax
80102b2b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
80102b2e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102b32:	74 0a                	je     80102b3e <kalloc+0x33>
    kmem.freelist = r->next;
80102b34:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b37:	8b 00                	mov    (%eax),%eax
80102b39:	a3 78 08 11 80       	mov    %eax,0x80110878
  if(kmem.use_lock)
80102b3e:	a1 74 08 11 80       	mov    0x80110874,%eax
80102b43:	85 c0                	test   %eax,%eax
80102b45:	74 0c                	je     80102b53 <kalloc+0x48>
    release(&kmem.lock);
80102b47:	c7 04 24 40 08 11 80 	movl   $0x80110840,(%esp)
80102b4e:	e8 fb 25 00 00       	call   8010514e <release>
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
80102bc9:	a1 3c c6 10 80       	mov    0x8010c63c,%eax
80102bce:	83 c8 40             	or     $0x40,%eax
80102bd1:	a3 3c c6 10 80       	mov    %eax,0x8010c63c
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
80102bec:	a1 3c c6 10 80       	mov    0x8010c63c,%eax
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
80102c09:	05 20 a0 10 80       	add    $0x8010a020,%eax
80102c0e:	0f b6 00             	movzbl (%eax),%eax
80102c11:	83 c8 40             	or     $0x40,%eax
80102c14:	0f b6 c0             	movzbl %al,%eax
80102c17:	f7 d0                	not    %eax
80102c19:	89 c2                	mov    %eax,%edx
80102c1b:	a1 3c c6 10 80       	mov    0x8010c63c,%eax
80102c20:	21 d0                	and    %edx,%eax
80102c22:	a3 3c c6 10 80       	mov    %eax,0x8010c63c
    return 0;
80102c27:	b8 00 00 00 00       	mov    $0x0,%eax
80102c2c:	e9 a0 00 00 00       	jmp    80102cd1 <kbdgetc+0x14f>
  } else if(shift & E0ESC){
80102c31:	a1 3c c6 10 80       	mov    0x8010c63c,%eax
80102c36:	83 e0 40             	and    $0x40,%eax
80102c39:	85 c0                	test   %eax,%eax
80102c3b:	74 14                	je     80102c51 <kbdgetc+0xcf>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80102c3d:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
80102c44:	a1 3c c6 10 80       	mov    0x8010c63c,%eax
80102c49:	83 e0 bf             	and    $0xffffffbf,%eax
80102c4c:	a3 3c c6 10 80       	mov    %eax,0x8010c63c
  }

  shift |= shiftcode[data];
80102c51:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102c54:	05 20 a0 10 80       	add    $0x8010a020,%eax
80102c59:	0f b6 00             	movzbl (%eax),%eax
80102c5c:	0f b6 d0             	movzbl %al,%edx
80102c5f:	a1 3c c6 10 80       	mov    0x8010c63c,%eax
80102c64:	09 d0                	or     %edx,%eax
80102c66:	a3 3c c6 10 80       	mov    %eax,0x8010c63c
  shift ^= togglecode[data];
80102c6b:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102c6e:	05 20 a1 10 80       	add    $0x8010a120,%eax
80102c73:	0f b6 00             	movzbl (%eax),%eax
80102c76:	0f b6 d0             	movzbl %al,%edx
80102c79:	a1 3c c6 10 80       	mov    0x8010c63c,%eax
80102c7e:	31 d0                	xor    %edx,%eax
80102c80:	a3 3c c6 10 80       	mov    %eax,0x8010c63c
  c = charcode[shift & (CTL | SHIFT)][data];
80102c85:	a1 3c c6 10 80       	mov    0x8010c63c,%eax
80102c8a:	83 e0 03             	and    $0x3,%eax
80102c8d:	8b 04 85 20 a5 10 80 	mov    -0x7fef5ae0(,%eax,4),%eax
80102c94:	03 45 fc             	add    -0x4(%ebp),%eax
80102c97:	0f b6 00             	movzbl (%eax),%eax
80102c9a:	0f b6 c0             	movzbl %al,%eax
80102c9d:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
80102ca0:	a1 3c c6 10 80       	mov    0x8010c63c,%eax
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
80102d1e:	a1 7c 08 11 80       	mov    0x8011087c,%eax
80102d23:	8b 55 08             	mov    0x8(%ebp),%edx
80102d26:	c1 e2 02             	shl    $0x2,%edx
80102d29:	01 c2                	add    %eax,%edx
80102d2b:	8b 45 0c             	mov    0xc(%ebp),%eax
80102d2e:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
80102d30:	a1 7c 08 11 80       	mov    0x8011087c,%eax
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
80102d42:	a1 7c 08 11 80       	mov    0x8011087c,%eax
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
80102dc7:	a1 7c 08 11 80       	mov    0x8011087c,%eax
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
80102e6b:	a1 7c 08 11 80       	mov    0x8011087c,%eax
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
80102ead:	a1 40 c6 10 80       	mov    0x8010c640,%eax
80102eb2:	85 c0                	test   %eax,%eax
80102eb4:	0f 94 c2             	sete   %dl
80102eb7:	83 c0 01             	add    $0x1,%eax
80102eba:	a3 40 c6 10 80       	mov    %eax,0x8010c640
80102ebf:	84 d2                	test   %dl,%dl
80102ec1:	74 13                	je     80102ed6 <cpunum+0x3d>
      cprintf("cpu called from %x with interrupts enabled\n",
80102ec3:	8b 45 04             	mov    0x4(%ebp),%eax
80102ec6:	89 44 24 04          	mov    %eax,0x4(%esp)
80102eca:	c7 04 24 60 8a 10 80 	movl   $0x80108a60,(%esp)
80102ed1:	e8 cb d4 ff ff       	call   801003a1 <cprintf>
        __builtin_return_address(0));
  }

  if(lapic)
80102ed6:	a1 7c 08 11 80       	mov    0x8011087c,%eax
80102edb:	85 c0                	test   %eax,%eax
80102edd:	74 0f                	je     80102eee <cpunum+0x55>
    return lapic[ID]>>24;
80102edf:	a1 7c 08 11 80       	mov    0x8011087c,%eax
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
80102efb:	a1 7c 08 11 80       	mov    0x8011087c,%eax
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
80103022:	c7 44 24 04 8c 8a 10 	movl   $0x80108a8c,0x4(%esp)
80103029:	80 
8010302a:	c7 04 24 80 08 11 80 	movl   $0x80110880,(%esp)
80103031:	e8 5c 20 00 00       	call   80105092 <initlock>
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
80103055:	a3 b4 08 11 80       	mov    %eax,0x801108b4
  log.size = sb.nlog;
8010305a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010305d:	a3 b8 08 11 80       	mov    %eax,0x801108b8
  log.dev = ROOTDEV;
80103062:	c7 05 c0 08 11 80 01 	movl   $0x1,0x801108c0
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
80103085:	a1 b4 08 11 80       	mov    0x801108b4,%eax
8010308a:	03 45 f4             	add    -0xc(%ebp),%eax
8010308d:	83 c0 01             	add    $0x1,%eax
80103090:	89 c2                	mov    %eax,%edx
80103092:	a1 c0 08 11 80       	mov    0x801108c0,%eax
80103097:	89 54 24 04          	mov    %edx,0x4(%esp)
8010309b:	89 04 24             	mov    %eax,(%esp)
8010309e:	e8 03 d1 ff ff       	call   801001a6 <bread>
801030a3:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.sector[tail]); // read dst
801030a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801030a9:	83 c0 10             	add    $0x10,%eax
801030ac:	8b 04 85 88 08 11 80 	mov    -0x7feef778(,%eax,4),%eax
801030b3:	89 c2                	mov    %eax,%edx
801030b5:	a1 c0 08 11 80       	mov    0x801108c0,%eax
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
801030e4:	e8 24 23 00 00       	call   8010540d <memmove>
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
8010310e:	a1 c4 08 11 80       	mov    0x801108c4,%eax
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
80103124:	a1 b4 08 11 80       	mov    0x801108b4,%eax
80103129:	89 c2                	mov    %eax,%edx
8010312b:	a1 c0 08 11 80       	mov    0x801108c0,%eax
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
8010314d:	a3 c4 08 11 80       	mov    %eax,0x801108c4
  for (i = 0; i < log.lh.n; i++) {
80103152:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103159:	eb 1b                	jmp    80103176 <read_head+0x58>
    log.lh.sector[i] = lh->sector[i];
8010315b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010315e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103161:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
80103165:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103168:	83 c2 10             	add    $0x10,%edx
8010316b:	89 04 95 88 08 11 80 	mov    %eax,-0x7feef778(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
80103172:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103176:	a1 c4 08 11 80       	mov    0x801108c4,%eax
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
80103193:	a1 b4 08 11 80       	mov    0x801108b4,%eax
80103198:	89 c2                	mov    %eax,%edx
8010319a:	a1 c0 08 11 80       	mov    0x801108c0,%eax
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
801031b7:	8b 15 c4 08 11 80    	mov    0x801108c4,%edx
801031bd:	8b 45 ec             	mov    -0x14(%ebp),%eax
801031c0:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
801031c2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801031c9:	eb 1b                	jmp    801031e6 <write_head+0x59>
    hb->sector[i] = log.lh.sector[i];
801031cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801031ce:	83 c0 10             	add    $0x10,%eax
801031d1:	8b 0c 85 88 08 11 80 	mov    -0x7feef778(,%eax,4),%ecx
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
801031e6:	a1 c4 08 11 80       	mov    0x801108c4,%eax
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
80103218:	c7 05 c4 08 11 80 00 	movl   $0x0,0x801108c4
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
8010322f:	c7 04 24 80 08 11 80 	movl   $0x80110880,(%esp)
80103236:	e8 78 1e 00 00       	call   801050b3 <acquire>
  while (log.busy) {
8010323b:	eb 14                	jmp    80103251 <begin_trans+0x28>
  sleep(&log, &log.lock);
8010323d:	c7 44 24 04 80 08 11 	movl   $0x80110880,0x4(%esp)
80103244:	80 
80103245:	c7 04 24 80 08 11 80 	movl   $0x80110880,(%esp)
8010324c:	e8 23 1b 00 00       	call   80104d74 <sleep>

void
begin_trans(void)
{
  acquire(&log.lock);
  while (log.busy) {
80103251:	a1 bc 08 11 80       	mov    0x801108bc,%eax
80103256:	85 c0                	test   %eax,%eax
80103258:	75 e3                	jne    8010323d <begin_trans+0x14>
  sleep(&log, &log.lock);
  }
  log.busy = 1;
8010325a:	c7 05 bc 08 11 80 01 	movl   $0x1,0x801108bc
80103261:	00 00 00 
  release(&log.lock);
80103264:	c7 04 24 80 08 11 80 	movl   $0x80110880,(%esp)
8010326b:	e8 de 1e 00 00       	call   8010514e <release>
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
80103278:	a1 c4 08 11 80       	mov    0x801108c4,%eax
8010327d:	85 c0                	test   %eax,%eax
8010327f:	7e 19                	jle    8010329a <commit_trans+0x28>
    write_head();    // Write header to disk -- the real commit
80103281:	e8 07 ff ff ff       	call   8010318d <write_head>
    install_trans(); // Now install writes to home locations
80103286:	e8 e8 fd ff ff       	call   80103073 <install_trans>
    log.lh.n = 0; 
8010328b:	c7 05 c4 08 11 80 00 	movl   $0x0,0x801108c4
80103292:	00 00 00 
    write_head();    // Erase the transaction from the log
80103295:	e8 f3 fe ff ff       	call   8010318d <write_head>
  }
  
  acquire(&log.lock);
8010329a:	c7 04 24 80 08 11 80 	movl   $0x80110880,(%esp)
801032a1:	e8 0d 1e 00 00       	call   801050b3 <acquire>
  log.busy = 0;
801032a6:	c7 05 bc 08 11 80 00 	movl   $0x0,0x801108bc
801032ad:	00 00 00 
  wakeup(&log);
801032b0:	c7 04 24 80 08 11 80 	movl   $0x80110880,(%esp)
801032b7:	e8 ec 1b 00 00       	call   80104ea8 <wakeup>
  release(&log.lock);
801032bc:	c7 04 24 80 08 11 80 	movl   $0x80110880,(%esp)
801032c3:	e8 86 1e 00 00       	call   8010514e <release>
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
801032d0:	a1 c4 08 11 80       	mov    0x801108c4,%eax
801032d5:	83 f8 09             	cmp    $0x9,%eax
801032d8:	7f 12                	jg     801032ec <log_write+0x22>
801032da:	a1 c4 08 11 80       	mov    0x801108c4,%eax
801032df:	8b 15 b8 08 11 80    	mov    0x801108b8,%edx
801032e5:	83 ea 01             	sub    $0x1,%edx
801032e8:	39 d0                	cmp    %edx,%eax
801032ea:	7c 0c                	jl     801032f8 <log_write+0x2e>
    panic("too big a transaction");
801032ec:	c7 04 24 90 8a 10 80 	movl   $0x80108a90,(%esp)
801032f3:	e8 45 d2 ff ff       	call   8010053d <panic>
  if (!log.busy)
801032f8:	a1 bc 08 11 80       	mov    0x801108bc,%eax
801032fd:	85 c0                	test   %eax,%eax
801032ff:	75 0c                	jne    8010330d <log_write+0x43>
    panic("write outside of trans");
80103301:	c7 04 24 a6 8a 10 80 	movl   $0x80108aa6,(%esp)
80103308:	e8 30 d2 ff ff       	call   8010053d <panic>

  for (i = 0; i < log.lh.n; i++) {
8010330d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103314:	eb 1d                	jmp    80103333 <log_write+0x69>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
80103316:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103319:	83 c0 10             	add    $0x10,%eax
8010331c:	8b 04 85 88 08 11 80 	mov    -0x7feef778(,%eax,4),%eax
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
80103333:	a1 c4 08 11 80       	mov    0x801108c4,%eax
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
8010334c:	89 04 95 88 08 11 80 	mov    %eax,-0x7feef778(,%edx,4)
  struct buf *lbuf = bread(b->dev, log.start+i+1);
80103353:	a1 b4 08 11 80       	mov    0x801108b4,%eax
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
80103390:	e8 78 20 00 00       	call   8010540d <memmove>
  bwrite(lbuf);
80103395:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103398:	89 04 24             	mov    %eax,(%esp)
8010339b:	e8 3d ce ff ff       	call   801001dd <bwrite>
  brelse(lbuf);
801033a0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801033a3:	89 04 24             	mov    %eax,(%esp)
801033a6:	e8 6c ce ff ff       	call   80100217 <brelse>
  if (i == log.lh.n)
801033ab:	a1 c4 08 11 80       	mov    0x801108c4,%eax
801033b0:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801033b3:	75 0d                	jne    801033c2 <log_write+0xf8>
    log.lh.n++;
801033b5:	a1 c4 08 11 80       	mov    0x801108c4,%eax
801033ba:	83 c0 01             	add    $0x1,%eax
801033bd:	a3 c4 08 11 80       	mov    %eax,0x801108c4
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
80103424:	c7 04 24 fc 38 11 80 	movl   $0x801138fc,(%esp)
8010342b:	e8 ad f5 ff ff       	call   801029dd <kinit1>
  kvmalloc();      // kernel page table
80103430:	e8 81 4c 00 00       	call   801080b6 <kvmalloc>
  mpinit();        // collect info about this machine
80103435:	e8 63 04 00 00       	call   8010389d <mpinit>
  lapicinit(mpbcpu());
8010343a:	e8 2e 02 00 00       	call   8010366d <mpbcpu>
8010343f:	89 04 24             	mov    %eax,(%esp)
80103442:	e8 f5 f8 ff ff       	call   80102d3c <lapicinit>
  seginit();       // set up segments
80103447:	e8 0d 46 00 00       	call   80107a59 <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
8010344c:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103452:	0f b6 00             	movzbl (%eax),%eax
80103455:	0f b6 c0             	movzbl %al,%eax
80103458:	89 44 24 04          	mov    %eax,0x4(%esp)
8010345c:	c7 04 24 bd 8a 10 80 	movl   $0x80108abd,(%esp)
80103463:	e8 39 cf ff ff       	call   801003a1 <cprintf>
  picinit();       // interrupt controller
80103468:	e8 95 06 00 00       	call   80103b02 <picinit>
  ioapicinit();    // another interrupt controller
8010346d:	e8 5b f4 ff ff       	call   801028cd <ioapicinit>
  consoleinit();   // I/O devices & their interrupts
80103472:	e8 16 d6 ff ff       	call   80100a8d <consoleinit>
  uartinit();      // serial port
80103477:	e8 28 39 00 00       	call   80106da4 <uartinit>
  pinit();         // process table
8010347c:	e8 a3 0b 00 00       	call   80104024 <pinit>
  tvinit();        // trap vectors
80103481:	e8 c1 34 00 00       	call   80106947 <tvinit>
  binit();         // buffer cache
80103486:	e8 a9 cb ff ff       	call   80100034 <binit>
  fileinit();      // file table
8010348b:	e8 70 da ff ff       	call   80100f00 <fileinit>
  iinit();         // inode cache
80103490:	e8 1e e1 ff ff       	call   801015b3 <iinit>
  ideinit();       // disk
80103495:	e8 8c f0 ff ff       	call   80102526 <ideinit>
  if(!ismp)
8010349a:	a1 04 09 11 80       	mov    0x80110904,%eax
8010349f:	85 c0                	test   %eax,%eax
801034a1:	75 05                	jne    801034a8 <main+0x95>
    timerinit();   // uniprocessor timer
801034a3:	e8 e2 33 00 00       	call   8010688a <timerinit>
  startothers();   // start other processors
801034a8:	e8 87 00 00 00       	call   80103534 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
801034ad:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
801034b4:	8e 
801034b5:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
801034bc:	e8 54 f5 ff ff       	call   80102a15 <kinit2>
  userinit();      // first user process
801034c1:	e8 94 10 00 00       	call   8010455a <userinit>
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
801034d1:	e8 f7 4b 00 00       	call   801080cd <switchkvm>
  seginit();
801034d6:	e8 7e 45 00 00       	call   80107a59 <seginit>
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
80103503:	c7 04 24 d4 8a 10 80 	movl   $0x80108ad4,(%esp)
8010350a:	e8 92 ce ff ff       	call   801003a1 <cprintf>
  idtinit();       // load idt register
8010350f:	e8 a7 35 00 00       	call   80106abb <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
80103514:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010351a:	05 a8 00 00 00       	add    $0xa8,%eax
8010351f:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80103526:	00 
80103527:	89 04 24             	mov    %eax,(%esp)
8010352a:	e8 bf fe ff ff       	call   801033ee <xchg>
  scheduler();     // start running processes
8010352f:	e8 36 16 00 00       	call   80104b6a <scheduler>

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
80103553:	c7 44 24 04 0c c5 10 	movl   $0x8010c50c,0x4(%esp)
8010355a:	80 
8010355b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010355e:	89 04 24             	mov    %eax,(%esp)
80103561:	e8 a7 1e 00 00       	call   8010540d <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80103566:	c7 45 f4 20 09 11 80 	movl   $0x80110920,-0xc(%ebp)
8010356d:	e9 86 00 00 00       	jmp    801035f8 <startothers+0xc4>
    if(c == cpus+cpunum())  // We've started already.
80103572:	e8 22 f9 ff ff       	call   80102e99 <cpunum>
80103577:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
8010357d:	05 20 09 11 80       	add    $0x80110920,%eax
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
801035b2:	c7 04 24 00 b0 10 80 	movl   $0x8010b000,(%esp)
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
801035f8:	a1 00 0f 11 80       	mov    0x80110f00,%eax
801035fd:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103603:	05 20 09 11 80       	add    $0x80110920,%eax
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
80103670:	a1 44 c6 10 80       	mov    0x8010c644,%eax
80103675:	89 c2                	mov    %eax,%edx
80103677:	b8 20 09 11 80       	mov    $0x80110920,%eax
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
801036f0:	c7 44 24 04 e8 8a 10 	movl   $0x80108ae8,0x4(%esp)
801036f7:	80 
801036f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801036fb:	89 04 24             	mov    %eax,(%esp)
801036fe:	e8 ae 1c 00 00       	call   801053b1 <memcmp>
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
80103831:	c7 44 24 04 ed 8a 10 	movl   $0x80108aed,0x4(%esp)
80103838:	80 
80103839:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010383c:	89 04 24             	mov    %eax,(%esp)
8010383f:	e8 6d 1b 00 00       	call   801053b1 <memcmp>
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
801038a3:	c7 05 44 c6 10 80 20 	movl   $0x80110920,0x8010c644
801038aa:	09 11 80 
  if((conf = mpconfig(&mp)) == 0)
801038ad:	8d 45 e0             	lea    -0x20(%ebp),%eax
801038b0:	89 04 24             	mov    %eax,(%esp)
801038b3:	e8 38 ff ff ff       	call   801037f0 <mpconfig>
801038b8:	89 45 f0             	mov    %eax,-0x10(%ebp)
801038bb:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801038bf:	0f 84 9c 01 00 00    	je     80103a61 <mpinit+0x1c4>
    return;
  ismp = 1;
801038c5:	c7 05 04 09 11 80 01 	movl   $0x1,0x80110904
801038cc:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
801038cf:	8b 45 f0             	mov    -0x10(%ebp),%eax
801038d2:	8b 40 24             	mov    0x24(%eax),%eax
801038d5:	a3 7c 08 11 80       	mov    %eax,0x8011087c
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
8010390a:	8b 04 85 30 8b 10 80 	mov    -0x7fef74d0(,%eax,4),%eax
80103911:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
80103913:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103916:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(ncpu != proc->apicid){
80103919:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010391c:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103920:	0f b6 d0             	movzbl %al,%edx
80103923:	a1 00 0f 11 80       	mov    0x80110f00,%eax
80103928:	39 c2                	cmp    %eax,%edx
8010392a:	74 2d                	je     80103959 <mpinit+0xbc>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
8010392c:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010392f:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103933:	0f b6 d0             	movzbl %al,%edx
80103936:	a1 00 0f 11 80       	mov    0x80110f00,%eax
8010393b:	89 54 24 08          	mov    %edx,0x8(%esp)
8010393f:	89 44 24 04          	mov    %eax,0x4(%esp)
80103943:	c7 04 24 f2 8a 10 80 	movl   $0x80108af2,(%esp)
8010394a:	e8 52 ca ff ff       	call   801003a1 <cprintf>
        ismp = 0;
8010394f:	c7 05 04 09 11 80 00 	movl   $0x0,0x80110904
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
8010396a:	a1 00 0f 11 80       	mov    0x80110f00,%eax
8010396f:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103975:	05 20 09 11 80       	add    $0x80110920,%eax
8010397a:	a3 44 c6 10 80       	mov    %eax,0x8010c644
      cpus[ncpu].id = ncpu;
8010397f:	8b 15 00 0f 11 80    	mov    0x80110f00,%edx
80103985:	a1 00 0f 11 80       	mov    0x80110f00,%eax
8010398a:	69 d2 bc 00 00 00    	imul   $0xbc,%edx,%edx
80103990:	81 c2 20 09 11 80    	add    $0x80110920,%edx
80103996:	88 02                	mov    %al,(%edx)
      ncpu++;
80103998:	a1 00 0f 11 80       	mov    0x80110f00,%eax
8010399d:	83 c0 01             	add    $0x1,%eax
801039a0:	a3 00 0f 11 80       	mov    %eax,0x80110f00
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
801039b8:	a2 00 09 11 80       	mov    %al,0x80110900
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
801039d6:	c7 04 24 10 8b 10 80 	movl   $0x80108b10,(%esp)
801039dd:	e8 bf c9 ff ff       	call   801003a1 <cprintf>
      ismp = 0;
801039e2:	c7 05 04 09 11 80 00 	movl   $0x0,0x80110904
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
801039f8:	a1 04 09 11 80       	mov    0x80110904,%eax
801039fd:	85 c0                	test   %eax,%eax
801039ff:	75 1d                	jne    80103a1e <mpinit+0x181>
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
80103a01:	c7 05 00 0f 11 80 01 	movl   $0x1,0x80110f00
80103a08:	00 00 00 
    lapic = 0;
80103a0b:	c7 05 7c 08 11 80 00 	movl   $0x0,0x8011087c
80103a12:	00 00 00 
    ioapicid = 0;
80103a15:	c6 05 00 09 11 80 00 	movb   $0x0,0x80110900
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
80103a93:	66 a3 00 c0 10 80    	mov    %ax,0x8010c000
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
80103ae8:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
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
80103c20:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
80103c27:	66 83 f8 ff          	cmp    $0xffff,%ax
80103c2b:	74 12                	je     80103c3f <picinit+0x13d>
    picsetmask(irqmask);
80103c2d:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
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
80103cdb:	c7 44 24 04 44 8b 10 	movl   $0x80108b44,0x4(%esp)
80103ce2:	80 
80103ce3:	89 04 24             	mov    %eax,(%esp)
80103ce6:	e8 a7 13 00 00       	call   80105092 <initlock>
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
80103d93:	e8 1b 13 00 00       	call   801050b3 <acquire>
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
80103db6:	e8 ed 10 00 00       	call   80104ea8 <wakeup>
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
80103dd5:	e8 ce 10 00 00       	call   80104ea8 <wakeup>
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
80103dfa:	e8 4f 13 00 00       	call   8010514e <release>
    kfree((char*)p);
80103dff:	8b 45 08             	mov    0x8(%ebp),%eax
80103e02:	89 04 24             	mov    %eax,(%esp)
80103e05:	e8 68 ec ff ff       	call   80102a72 <kfree>
80103e0a:	eb 0b                	jmp    80103e17 <pipeclose+0x90>
  } else
    release(&p->lock);
80103e0c:	8b 45 08             	mov    0x8(%ebp),%eax
80103e0f:	89 04 24             	mov    %eax,(%esp)
80103e12:	e8 37 13 00 00       	call   8010514e <release>
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
80103e26:	e8 88 12 00 00       	call   801050b3 <acquire>
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
80103e57:	e8 f2 12 00 00       	call   8010514e <release>
        return -1;
80103e5c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103e61:	e9 9d 00 00 00       	jmp    80103f03 <pipewrite+0xea>
      }
      wakeup(&p->nread);
80103e66:	8b 45 08             	mov    0x8(%ebp),%eax
80103e69:	05 34 02 00 00       	add    $0x234,%eax
80103e6e:	89 04 24             	mov    %eax,(%esp)
80103e71:	e8 32 10 00 00       	call   80104ea8 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
80103e76:	8b 45 08             	mov    0x8(%ebp),%eax
80103e79:	8b 55 08             	mov    0x8(%ebp),%edx
80103e7c:	81 c2 38 02 00 00    	add    $0x238,%edx
80103e82:	89 44 24 04          	mov    %eax,0x4(%esp)
80103e86:	89 14 24             	mov    %edx,(%esp)
80103e89:	e8 e6 0e 00 00       	call   80104d74 <sleep>
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
80103ef0:	e8 b3 0f 00 00       	call   80104ea8 <wakeup>
  release(&p->lock);
80103ef5:	8b 45 08             	mov    0x8(%ebp),%eax
80103ef8:	89 04 24             	mov    %eax,(%esp)
80103efb:	e8 4e 12 00 00       	call   8010514e <release>
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
80103f16:	e8 98 11 00 00       	call   801050b3 <acquire>
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
80103f30:	e8 19 12 00 00       	call   8010514e <release>
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
80103f52:	e8 1d 0e 00 00       	call   80104d74 <sleep>
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
80103fe2:	e8 c1 0e 00 00       	call   80104ea8 <wakeup>
  release(&p->lock);
80103fe7:	8b 45 08             	mov    0x8(%ebp),%eax
80103fea:	89 04 24             	mov    %eax,(%esp)
80103fed:	e8 5c 11 00 00       	call   8010514e <release>
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
8010402a:	c7 44 24 04 4c 8b 10 	movl   $0x80108b4c,0x4(%esp)
80104031:	80 
80104032:	c7 04 24 20 0f 11 80 	movl   $0x80110f20,(%esp)
80104039:	e8 54 10 00 00       	call   80105092 <initlock>
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
80104043:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
80104046:	c7 04 24 20 0f 11 80 	movl   $0x80110f20,(%esp)
8010404d:	e8 61 10 00 00       	call   801050b3 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104052:	c7 45 f4 54 0f 11 80 	movl   $0x80110f54,-0xc(%ebp)
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
80104065:	81 45 f4 84 00 00 00 	addl   $0x84,-0xc(%ebp)
8010406c:	81 7d f4 54 30 11 80 	cmpl   $0x80113054,-0xc(%ebp)
80104073:	72 e6                	jb     8010405b <allocproc+0x1b>
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
80104075:	c7 04 24 20 0f 11 80 	movl   $0x80110f20,(%esp)
8010407c:	e8 cd 10 00 00       	call   8010514e <release>
  return 0;
80104081:	b8 00 00 00 00       	mov    $0x0,%eax
80104086:	e9 b5 00 00 00       	jmp    80104140 <allocproc+0x100>
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
80104096:	a1 04 c0 10 80       	mov    0x8010c004,%eax
8010409b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010409e:	89 42 10             	mov    %eax,0x10(%edx)
801040a1:	83 c0 01             	add    $0x1,%eax
801040a4:	a3 04 c0 10 80       	mov    %eax,0x8010c004
  release(&ptable.lock);
801040a9:	c7 04 24 20 0f 11 80 	movl   $0x80110f20,(%esp)
801040b0:	e8 99 10 00 00       	call   8010514e <release>

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
801040b5:	e8 51 ea ff ff       	call   80102b0b <kalloc>
801040ba:	8b 55 f4             	mov    -0xc(%ebp),%edx
801040bd:	89 42 08             	mov    %eax,0x8(%edx)
801040c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801040c3:	8b 40 08             	mov    0x8(%eax),%eax
801040c6:	85 c0                	test   %eax,%eax
801040c8:	75 11                	jne    801040db <allocproc+0x9b>
    p->state = UNUSED;
801040ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
801040cd:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return 0;
801040d4:	b8 00 00 00 00       	mov    $0x0,%eax
801040d9:	eb 65                	jmp    80104140 <allocproc+0x100>
  }
  sp = p->kstack + KSTACKSIZE;
801040db:	8b 45 f4             	mov    -0xc(%ebp),%eax
801040de:	8b 40 08             	mov    0x8(%eax),%eax
801040e1:	05 00 10 00 00       	add    $0x1000,%eax
801040e6:	89 45 f0             	mov    %eax,-0x10(%ebp)
  
  // Leave room for trap frame.
  sp -= sizeof *p->tf;
801040e9:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
  p->tf = (struct trapframe*)sp;
801040ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
801040f0:	8b 55 f0             	mov    -0x10(%ebp),%edx
801040f3:	89 50 18             	mov    %edx,0x18(%eax)
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
801040f6:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
  *(uint*)sp = (uint)trapret;
801040fa:	ba fc 68 10 80       	mov    $0x801068fc,%edx
801040ff:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104102:	89 10                	mov    %edx,(%eax)

  sp -= sizeof *p->context;
80104104:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
  p->context = (struct context*)sp;
80104108:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010410b:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010410e:	89 50 1c             	mov    %edx,0x1c(%eax)
  memset(p->context, 0, sizeof *p->context);
80104111:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104114:	8b 40 1c             	mov    0x1c(%eax),%eax
80104117:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
8010411e:	00 
8010411f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104126:	00 
80104127:	89 04 24             	mov    %eax,(%esp)
8010412a:	e8 0b 12 00 00       	call   8010533a <memset>
  p->context->eip = (uint)forkret;
8010412f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104132:	8b 40 1c             	mov    0x1c(%eax),%eax
80104135:	ba 48 4d 10 80       	mov    $0x80104d48,%edx
8010413a:	89 50 10             	mov    %edx,0x10(%eax)

  return p;
8010413d:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104140:	c9                   	leave  
80104141:	c3                   	ret    

80104142 <createInternalProcess>:


void createInternalProcess(const char *name, void (*entrypoint)())
{
80104142:	55                   	push   %ebp
80104143:	89 e5                	mov    %esp,%ebp
80104145:	83 ec 28             	sub    $0x28,%esp
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
80104148:	e8 f3 fe ff ff       	call   80104040 <allocproc>
8010414d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104150:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104154:	0f 84 f7 00 00 00    	je     80104251 <createInternalProcess+0x10f>
    return;

  // Copy process state from p.
  if((np->pgdir = setupkvm(kalloc)) == 0)
8010415a:	c7 04 24 0b 2b 10 80 	movl   $0x80102b0b,(%esp)
80104161:	e8 93 3e 00 00       	call   80107ff9 <setupkvm>
80104166:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104169:	89 42 04             	mov    %eax,0x4(%edx)
8010416c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010416f:	8b 40 04             	mov    0x4(%eax),%eax
80104172:	85 c0                	test   %eax,%eax
80104174:	75 0c                	jne    80104182 <createInternalProcess+0x40>
      panic("inswapper: out of memory?");
80104176:	c7 04 24 53 8b 10 80 	movl   $0x80108b53,(%esp)
8010417d:	e8 bb c3 ff ff       	call   8010053d <panic>

  np->sz = PGSIZE;
80104182:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104185:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  np->parent = initproc;
8010418b:	8b 15 48 c6 10 80    	mov    0x8010c648,%edx
80104191:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104194:	89 50 14             	mov    %edx,0x14(%eax)
  memset(np->tf, 0, sizeof(*np->tf));
80104197:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010419a:	8b 40 18             	mov    0x18(%eax),%eax
8010419d:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
801041a4:	00 
801041a5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801041ac:	00 
801041ad:	89 04 24             	mov    %eax,(%esp)
801041b0:	e8 85 11 00 00       	call   8010533a <memset>
  np->tf->cs = (SEG_KCODE << 3) | DPL_USER;
801041b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041b8:	8b 40 18             	mov    0x18(%eax),%eax
801041bb:	66 c7 40 3c 0b 00    	movw   $0xb,0x3c(%eax)
  np->tf->ds = (SEG_KDATA << 3) | DPL_USER;
801041c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041c4:	8b 40 18             	mov    0x18(%eax),%eax
801041c7:	66 c7 40 2c 13 00    	movw   $0x13,0x2c(%eax)
  np->tf->es = np->tf->ds;
801041cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041d0:	8b 40 18             	mov    0x18(%eax),%eax
801041d3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801041d6:	8b 52 18             	mov    0x18(%edx),%edx
801041d9:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
801041dd:	66 89 50 28          	mov    %dx,0x28(%eax)
  np->tf->ss = np->tf->ds;
801041e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041e4:	8b 40 18             	mov    0x18(%eax),%eax
801041e7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801041ea:	8b 52 18             	mov    0x18(%edx),%edx
801041ed:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
801041f1:	66 89 50 48          	mov    %dx,0x48(%eax)
  np->tf->eflags = FL_IF;
801041f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041f8:	8b 40 18             	mov    0x18(%eax),%eax
801041fb:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  //np->tf->esp = (uint)entrypoint+PGSIZE;
  //np->tf->eip = (uint)entrypoint;
  np->context->eip = (uint)entrypoint;
80104202:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104205:	8b 40 1c             	mov    0x1c(%eax),%eax
80104208:	8b 55 0c             	mov    0xc(%ebp),%edx
8010420b:	89 50 10             	mov    %edx,0x10(%eax)

  inswapper = np;
8010420e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104211:	a3 4c c6 10 80       	mov    %eax,0x8010c64c
  np->cwd = namei("/");
80104216:	c7 04 24 6d 8b 10 80 	movl   $0x80108b6d,(%esp)
8010421d:	e8 e8 e1 ff ff       	call   8010240a <namei>
80104222:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104225:	89 42 68             	mov    %eax,0x68(%edx)
  np->state = RUNNABLE;
80104228:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010422b:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  safestrcpy(np->name, name, sizeof(name));
80104232:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104235:	8d 50 6c             	lea    0x6c(%eax),%edx
80104238:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
8010423f:	00 
80104240:	8b 45 08             	mov    0x8(%ebp),%eax
80104243:	89 44 24 04          	mov    %eax,0x4(%esp)
80104247:	89 14 24             	mov    %edx,(%esp)
8010424a:	e8 1b 13 00 00       	call   8010556a <safestrcpy>
8010424f:	eb 01                	jmp    80104252 <createInternalProcess+0x110>
{
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
    return;
80104251:	90                   	nop

  inswapper = np;
  np->cwd = namei("/");
  np->state = RUNNABLE;
  safestrcpy(np->name, name, sizeof(name));
}
80104252:	c9                   	leave  
80104253:	c3                   	ret    

80104254 <swapIn>:

void swapIn()
{
80104254:	55                   	push   %ebp
80104255:	89 e5                	mov    %esp,%ebp
80104257:	81 ec 28 10 00 00    	sub    $0x1028,%esp
  struct proc* t;
  //acquire(&ptable.lock);
  for(;;)
  {
    for(t = ptable.proc; t < &ptable.proc[NPROC]; t++)
8010425d:	c7 45 f4 54 0f 11 80 	movl   $0x80110f54,-0xc(%ebp)
80104264:	e9 f4 00 00 00       	jmp    8010435d <swapIn+0x109>
    {
      if(t->state != RUNNABLE_SUSPENDED)
80104269:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010426c:	8b 40 0c             	mov    0xc(%eax),%eax
8010426f:	83 f8 07             	cmp    $0x7,%eax
80104272:	0f 85 dd 00 00 00    	jne    80104355 <swapIn+0x101>
	continue;
      
      //open file pid.swap
      
      char buf[PGSIZE];
      int read=0;
80104278:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
      
      // allocate virtual memory
      if(!allocuvm(t->pgdir, 0, t->sz))
8010427f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104282:	8b 10                	mov    (%eax),%edx
80104284:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104287:	8b 40 04             	mov    0x4(%eax),%eax
8010428a:	89 54 24 08          	mov    %edx,0x8(%esp)
8010428e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104295:	00 
80104296:	89 04 24             	mov    %eax,(%esp)
80104299:	e8 2d 41 00 00       	call   801083cb <allocuvm>
8010429e:	85 c0                	test   %eax,%eax
801042a0:	75 11                	jne    801042b3 <swapIn+0x5f>
      {
	cprintf("allocuvm failed\n");
801042a2:	c7 04 24 6f 8b 10 80 	movl   $0x80108b6f,(%esp)
801042a9:	e8 f3 c0 ff ff       	call   801003a1 <cprintf>
	break;
801042ae:	e9 b7 00 00 00       	jmp    8010436a <swapIn+0x116>
      }
      
      uint a = 0;
801042b3:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
      for(; a < t->sz; a += PGSIZE)
801042ba:	eb 68                	jmp    80104324 <swapIn+0xd0>
      {
	if((read = fileread(t->swap, buf, PGSIZE)) > 0)
801042bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042bf:	8b 40 7c             	mov    0x7c(%eax),%eax
801042c2:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801042c9:	00 
801042ca:	8d 95 ec ef ff ff    	lea    -0x1014(%ebp),%edx
801042d0:	89 54 24 04          	mov    %edx,0x4(%esp)
801042d4:	89 04 24             	mov    %eax,(%esp)
801042d7:	e8 0d ce ff ff       	call   801010e9 <fileread>
801042dc:	89 45 ec             	mov    %eax,-0x14(%ebp)
801042df:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801042e3:	7e 38                	jle    8010431d <swapIn+0xc9>
	{
	  if(copyout(t->pgdir,a, buf, read) < 0)
801042e5:	8b 55 ec             	mov    -0x14(%ebp),%edx
801042e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042eb:	8b 40 04             	mov    0x4(%eax),%eax
801042ee:	89 54 24 0c          	mov    %edx,0xc(%esp)
801042f2:	8d 95 ec ef ff ff    	lea    -0x1014(%ebp),%edx
801042f8:	89 54 24 08          	mov    %edx,0x8(%esp)
801042fc:	8b 55 f0             	mov    -0x10(%ebp),%edx
801042ff:	89 54 24 04          	mov    %edx,0x4(%esp)
80104303:	89 04 24             	mov    %eax,(%esp)
80104306:	e8 ca 44 00 00       	call   801087d5 <copyout>
8010430b:	85 c0                	test   %eax,%eax
8010430d:	79 0e                	jns    8010431d <swapIn+0xc9>
	  {
	    cprintf("copyout failed\n");
8010430f:	c7 04 24 80 8b 10 80 	movl   $0x80108b80,(%esp)
80104316:	e8 86 c0 ff ff       	call   801003a1 <cprintf>
	    break;
8010431b:	eb 11                	jmp    8010432e <swapIn+0xda>
	cprintf("allocuvm failed\n");
	break;
      }
      
      uint a = 0;
      for(; a < t->sz; a += PGSIZE)
8010431d:	81 45 f0 00 10 00 00 	addl   $0x1000,-0x10(%ebp)
80104324:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104327:	8b 00                	mov    (%eax),%eax
80104329:	3b 45 f0             	cmp    -0x10(%ebp),%eax
8010432c:	77 8e                	ja     801042bc <swapIn+0x68>
	    break;
	  }
	}
      }
      
      t->state = RUNNABLE;
8010432e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104331:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      t->isSwapped = 0;
80104338:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010433b:	c7 80 80 00 00 00 00 	movl   $0x0,0x80(%eax)
80104342:	00 00 00 
      fileclose(t->swap);
80104345:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104348:	8b 40 7c             	mov    0x7c(%eax),%eax
8010434b:	89 04 24             	mov    %eax,(%esp)
8010434e:	e8 71 cc ff ff       	call   80100fc4 <fileclose>
80104353:	eb 01                	jmp    80104356 <swapIn+0x102>
  for(;;)
  {
    for(t = ptable.proc; t < &ptable.proc[NPROC]; t++)
    {
      if(t->state != RUNNABLE_SUSPENDED)
	continue;
80104355:	90                   	nop
{
  struct proc* t;
  //acquire(&ptable.lock);
  for(;;)
  {
    for(t = ptable.proc; t < &ptable.proc[NPROC]; t++)
80104356:	81 45 f4 84 00 00 00 	addl   $0x84,-0xc(%ebp)
8010435d:	81 7d f4 54 30 11 80 	cmpl   $0x80113054,-0xc(%ebp)
80104364:	0f 82 ff fe ff ff    	jb     80104269 <swapIn+0x15>
      fileclose(t->swap);
      
      // delete fild pid.swap
    }
    
    sleep(proc,&ptable.lock);
8010436a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104370:	c7 44 24 04 20 0f 11 	movl   $0x80110f20,0x4(%esp)
80104377:	80 
80104378:	89 04 24             	mov    %eax,(%esp)
8010437b:	e8 f4 09 00 00       	call   80104d74 <sleep>
  }
80104380:	e9 d8 fe ff ff       	jmp    8010425d <swapIn+0x9>

80104385 <swapOut>:
}

void
swapOut()
{
80104385:	55                   	push   %ebp
80104386:	89 e5                	mov    %esp,%ebp
80104388:	53                   	push   %ebx
80104389:	83 ec 34             	sub    $0x34,%esp
  if(swapFlag)
8010438c:	a1 08 c0 10 80       	mov    0x8010c008,%eax
80104391:	85 c0                	test   %eax,%eax
80104393:	0f 84 bb 01 00 00    	je     80104554 <swapOut+0x1cf>
  {
    if(proc->pid > 3)
80104399:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010439f:	8b 40 10             	mov    0x10(%eax),%eax
801043a2:	83 f8 03             	cmp    $0x3,%eax
801043a5:	0f 8e a9 01 00 00    	jle    80104554 <swapOut+0x1cf>
    {
      int i = 0;
801043ab:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
      char name[8];
      name[2] = '.'; name[3] = 's'; name[4] = 'w'; name[5] = 'a'; name[6] = 'p'; name[7] = 0;
801043b2:	c6 45 e2 2e          	movb   $0x2e,-0x1e(%ebp)
801043b6:	c6 45 e3 73          	movb   $0x73,-0x1d(%ebp)
801043ba:	c6 45 e4 77          	movb   $0x77,-0x1c(%ebp)
801043be:	c6 45 e5 61          	movb   $0x61,-0x1b(%ebp)
801043c2:	c6 45 e6 70          	movb   $0x70,-0x1a(%ebp)
801043c6:	c6 45 e7 00          	movb   $0x0,-0x19(%ebp)
      name[1] = (char)(((int)'0')+proc->pid % 10);
801043ca:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801043d0:	8b 48 10             	mov    0x10(%eax),%ecx
801043d3:	ba 67 66 66 66       	mov    $0x66666667,%edx
801043d8:	89 c8                	mov    %ecx,%eax
801043da:	f7 ea                	imul   %edx
801043dc:	c1 fa 02             	sar    $0x2,%edx
801043df:	89 c8                	mov    %ecx,%eax
801043e1:	c1 f8 1f             	sar    $0x1f,%eax
801043e4:	29 c2                	sub    %eax,%edx
801043e6:	89 d0                	mov    %edx,%eax
801043e8:	c1 e0 02             	shl    $0x2,%eax
801043eb:	01 d0                	add    %edx,%eax
801043ed:	01 c0                	add    %eax,%eax
801043ef:	89 ca                	mov    %ecx,%edx
801043f1:	29 c2                	sub    %eax,%edx
801043f3:	89 d0                	mov    %edx,%eax
801043f5:	83 c0 30             	add    $0x30,%eax
801043f8:	88 45 e1             	mov    %al,-0x1f(%ebp)
      if((i=proc->pid/10) == 0)
801043fb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104401:	8b 48 10             	mov    0x10(%eax),%ecx
80104404:	ba 67 66 66 66       	mov    $0x66666667,%edx
80104409:	89 c8                	mov    %ecx,%eax
8010440b:	f7 ea                	imul   %edx
8010440d:	c1 fa 02             	sar    $0x2,%edx
80104410:	89 c8                	mov    %ecx,%eax
80104412:	c1 f8 1f             	sar    $0x1f,%eax
80104415:	89 d1                	mov    %edx,%ecx
80104417:	29 c1                	sub    %eax,%ecx
80104419:	89 c8                	mov    %ecx,%eax
8010441b:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010441e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80104422:	75 06                	jne    8010442a <swapOut+0xa5>
	name[0] = '0';
80104424:	c6 45 e0 30          	movb   $0x30,-0x20(%ebp)
80104428:	eb 09                	jmp    80104433 <swapOut+0xae>
      else
	name[0] = (char)(((int)'0')+i);
8010442a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010442d:	83 c0 30             	add    $0x30,%eax
80104430:	88 45 e0             	mov    %al,-0x20(%ebp)
      release(&ptable.lock);
80104433:	c7 04 24 20 0f 11 80 	movl   $0x80110f20,(%esp)
8010443a:	e8 0f 0d 00 00       	call   8010514e <release>
      proc->swap = fileopen(name,(O_CREATE | O_RDWR));
8010443f:	65 8b 1d 04 00 00 00 	mov    %gs:0x4,%ebx
80104446:	c7 44 24 04 02 02 00 	movl   $0x202,0x4(%esp)
8010444d:	00 
8010444e:	8d 45 e0             	lea    -0x20(%ebp),%eax
80104451:	89 04 24             	mov    %eax,(%esp)
80104454:	e8 10 1c 00 00       	call   80106069 <fileopen>
80104459:	89 43 7c             	mov    %eax,0x7c(%ebx)
      acquire(&ptable.lock);
8010445c:	c7 04 24 20 0f 11 80 	movl   $0x80110f20,(%esp)
80104463:	e8 4b 0c 00 00       	call   801050b3 <acquire>
      pte_t *pte;
      uint pa, j;
      for(j = 0; j < proc->sz; j += PGSIZE)
80104468:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010446f:	e9 b2 00 00 00       	jmp    80104526 <swapOut+0x1a1>
      {
	if((pte = walkpgdir(proc->pgdir, (void *) j, 0)) == 0)
80104474:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104477:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010447d:	8b 40 04             	mov    0x4(%eax),%eax
80104480:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80104487:	00 
80104488:	89 54 24 04          	mov    %edx,0x4(%esp)
8010448c:	89 04 24             	mov    %eax,(%esp)
8010448f:	e8 3b 3a 00 00       	call   80107ecf <walkpgdir>
80104494:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104497:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
8010449b:	75 0c                	jne    801044a9 <swapOut+0x124>
	  panic("copyuvm: pte should exist");
8010449d:	c7 04 24 90 8b 10 80 	movl   $0x80108b90,(%esp)
801044a4:	e8 94 c0 ff ff       	call   8010053d <panic>
	if(!(*pte & PTE_P))
801044a9:	8b 45 ec             	mov    -0x14(%ebp),%eax
801044ac:	8b 00                	mov    (%eax),%eax
801044ae:	83 e0 01             	and    $0x1,%eax
801044b1:	85 c0                	test   %eax,%eax
801044b3:	75 0c                	jne    801044c1 <swapOut+0x13c>
	  panic("copyuvm: page not present");
801044b5:	c7 04 24 aa 8b 10 80 	movl   $0x80108baa,(%esp)
801044bc:	e8 7c c0 ff ff       	call   8010053d <panic>
	pa = PTE_ADDR(*pte);
801044c1:	8b 45 ec             	mov    -0x14(%ebp),%eax
801044c4:	8b 00                	mov    (%eax),%eax
801044c6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801044cb:	89 45 e8             	mov    %eax,-0x18(%ebp)
	
	release(&ptable.lock);
801044ce:	c7 04 24 20 0f 11 80 	movl   $0x80110f20,(%esp)
801044d5:	e8 74 0c 00 00       	call   8010514e <release>
	if(filewrite(proc->swap, (char*)p2v(pa), PGSIZE) < 0)
801044da:	8b 45 e8             	mov    -0x18(%ebp),%eax
801044dd:	89 04 24             	mov    %eax,(%esp)
801044e0:	e8 17 fb ff ff       	call   80103ffc <p2v>
801044e5:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801044ec:	8b 52 7c             	mov    0x7c(%edx),%edx
801044ef:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801044f6:	00 
801044f7:	89 44 24 04          	mov    %eax,0x4(%esp)
801044fb:	89 14 24             	mov    %edx,(%esp)
801044fe:	e8 a2 cc ff ff       	call   801011a5 <filewrite>
80104503:	85 c0                	test   %eax,%eax
80104505:	79 0c                	jns    80104513 <swapOut+0x18e>
	  panic("filewrite failed");
80104507:	c7 04 24 c4 8b 10 80 	movl   $0x80108bc4,(%esp)
8010450e:	e8 2a c0 ff ff       	call   8010053d <panic>
	acquire(&ptable.lock);
80104513:	c7 04 24 20 0f 11 80 	movl   $0x80110f20,(%esp)
8010451a:	e8 94 0b 00 00       	call   801050b3 <acquire>
      release(&ptable.lock);
      proc->swap = fileopen(name,(O_CREATE | O_RDWR));
      acquire(&ptable.lock);
      pte_t *pte;
      uint pa, j;
      for(j = 0; j < proc->sz; j += PGSIZE)
8010451f:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80104526:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010452c:	8b 00                	mov    (%eax),%eax
8010452e:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104531:	0f 87 3d ff ff ff    	ja     80104474 <swapOut+0xef>
	if(filewrite(proc->swap, (char*)p2v(pa), PGSIZE) < 0)
	  panic("filewrite failed");
	acquire(&ptable.lock);
      }
      
      proc->state = SLEEPING_SUSPENDED;
80104537:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010453d:	c7 40 0c 06 00 00 00 	movl   $0x6,0xc(%eax)
      proc->isSwapped = 1;
80104544:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010454a:	c7 80 80 00 00 00 01 	movl   $0x1,0x80(%eax)
80104551:	00 00 00 
    }
  }
}
80104554:	83 c4 34             	add    $0x34,%esp
80104557:	5b                   	pop    %ebx
80104558:	5d                   	pop    %ebp
80104559:	c3                   	ret    

8010455a <userinit>:

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
8010455a:	55                   	push   %ebp
8010455b:	89 e5                	mov    %esp,%ebp
8010455d:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
80104560:	e8 db fa ff ff       	call   80104040 <allocproc>
80104565:	89 45 f4             	mov    %eax,-0xc(%ebp)
  initproc = p;
80104568:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010456b:	a3 48 c6 10 80       	mov    %eax,0x8010c648
  if((p->pgdir = setupkvm(kalloc)) == 0)
80104570:	c7 04 24 0b 2b 10 80 	movl   $0x80102b0b,(%esp)
80104577:	e8 7d 3a 00 00       	call   80107ff9 <setupkvm>
8010457c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010457f:	89 42 04             	mov    %eax,0x4(%edx)
80104582:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104585:	8b 40 04             	mov    0x4(%eax),%eax
80104588:	85 c0                	test   %eax,%eax
8010458a:	75 0c                	jne    80104598 <userinit+0x3e>
    panic("userinit: out of memory?");
8010458c:	c7 04 24 d5 8b 10 80 	movl   $0x80108bd5,(%esp)
80104593:	e8 a5 bf ff ff       	call   8010053d <panic>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80104598:	ba 2c 00 00 00       	mov    $0x2c,%edx
8010459d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045a0:	8b 40 04             	mov    0x4(%eax),%eax
801045a3:	89 54 24 08          	mov    %edx,0x8(%esp)
801045a7:	c7 44 24 04 e0 c4 10 	movl   $0x8010c4e0,0x4(%esp)
801045ae:	80 
801045af:	89 04 24             	mov    %eax,(%esp)
801045b2:	e8 9a 3c 00 00       	call   80108251 <inituvm>
  p->sz = PGSIZE;
801045b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045ba:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  memset(p->tf, 0, sizeof(*p->tf));
801045c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045c3:	8b 40 18             	mov    0x18(%eax),%eax
801045c6:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
801045cd:	00 
801045ce:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801045d5:	00 
801045d6:	89 04 24             	mov    %eax,(%esp)
801045d9:	e8 5c 0d 00 00       	call   8010533a <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
801045de:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045e1:	8b 40 18             	mov    0x18(%eax),%eax
801045e4:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
801045ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045ed:	8b 40 18             	mov    0x18(%eax),%eax
801045f0:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
  p->tf->es = p->tf->ds;
801045f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045f9:	8b 40 18             	mov    0x18(%eax),%eax
801045fc:	8b 55 f4             	mov    -0xc(%ebp),%edx
801045ff:	8b 52 18             	mov    0x18(%edx),%edx
80104602:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104606:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
8010460a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010460d:	8b 40 18             	mov    0x18(%eax),%eax
80104610:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104613:	8b 52 18             	mov    0x18(%edx),%edx
80104616:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
8010461a:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
8010461e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104621:	8b 40 18             	mov    0x18(%eax),%eax
80104624:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
8010462b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010462e:	8b 40 18             	mov    0x18(%eax),%eax
80104631:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
80104638:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010463b:	8b 40 18             	mov    0x18(%eax),%eax
8010463e:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
80104645:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104648:	83 c0 6c             	add    $0x6c,%eax
8010464b:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104652:	00 
80104653:	c7 44 24 04 ee 8b 10 	movl   $0x80108bee,0x4(%esp)
8010465a:	80 
8010465b:	89 04 24             	mov    %eax,(%esp)
8010465e:	e8 07 0f 00 00       	call   8010556a <safestrcpy>
  p->cwd = namei("/");
80104663:	c7 04 24 6d 8b 10 80 	movl   $0x80108b6d,(%esp)
8010466a:	e8 9b dd ff ff       	call   8010240a <namei>
8010466f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104672:	89 42 68             	mov    %eax,0x68(%edx)

  p->state = RUNNABLE;
80104675:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104678:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)

  createInternalProcess("inswapper", swapIn);
8010467f:	c7 44 24 04 54 42 10 	movl   $0x80104254,0x4(%esp)
80104686:	80 
80104687:	c7 04 24 f7 8b 10 80 	movl   $0x80108bf7,(%esp)
8010468e:	e8 af fa ff ff       	call   80104142 <createInternalProcess>
}
80104693:	c9                   	leave  
80104694:	c3                   	ret    

80104695 <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
80104695:	55                   	push   %ebp
80104696:	89 e5                	mov    %esp,%ebp
80104698:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  
  sz = proc->sz;
8010469b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801046a1:	8b 00                	mov    (%eax),%eax
801046a3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
801046a6:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801046aa:	7e 34                	jle    801046e0 <growproc+0x4b>
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
801046ac:	8b 45 08             	mov    0x8(%ebp),%eax
801046af:	89 c2                	mov    %eax,%edx
801046b1:	03 55 f4             	add    -0xc(%ebp),%edx
801046b4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801046ba:	8b 40 04             	mov    0x4(%eax),%eax
801046bd:	89 54 24 08          	mov    %edx,0x8(%esp)
801046c1:	8b 55 f4             	mov    -0xc(%ebp),%edx
801046c4:	89 54 24 04          	mov    %edx,0x4(%esp)
801046c8:	89 04 24             	mov    %eax,(%esp)
801046cb:	e8 fb 3c 00 00       	call   801083cb <allocuvm>
801046d0:	89 45 f4             	mov    %eax,-0xc(%ebp)
801046d3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801046d7:	75 41                	jne    8010471a <growproc+0x85>
      return -1;
801046d9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801046de:	eb 58                	jmp    80104738 <growproc+0xa3>
  } else if(n < 0){
801046e0:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801046e4:	79 34                	jns    8010471a <growproc+0x85>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
801046e6:	8b 45 08             	mov    0x8(%ebp),%eax
801046e9:	89 c2                	mov    %eax,%edx
801046eb:	03 55 f4             	add    -0xc(%ebp),%edx
801046ee:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801046f4:	8b 40 04             	mov    0x4(%eax),%eax
801046f7:	89 54 24 08          	mov    %edx,0x8(%esp)
801046fb:	8b 55 f4             	mov    -0xc(%ebp),%edx
801046fe:	89 54 24 04          	mov    %edx,0x4(%esp)
80104702:	89 04 24             	mov    %eax,(%esp)
80104705:	e8 9b 3d 00 00       	call   801084a5 <deallocuvm>
8010470a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010470d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104711:	75 07                	jne    8010471a <growproc+0x85>
      return -1;
80104713:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104718:	eb 1e                	jmp    80104738 <growproc+0xa3>
  }
  proc->sz = sz;
8010471a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104720:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104723:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
80104725:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010472b:	89 04 24             	mov    %eax,(%esp)
8010472e:	e8 b7 39 00 00       	call   801080ea <switchuvm>
  return 0;
80104733:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104738:	c9                   	leave  
80104739:	c3                   	ret    

8010473a <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
8010473a:	55                   	push   %ebp
8010473b:	89 e5                	mov    %esp,%ebp
8010473d:	57                   	push   %edi
8010473e:	56                   	push   %esi
8010473f:	53                   	push   %ebx
80104740:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
80104743:	e8 f8 f8 ff ff       	call   80104040 <allocproc>
80104748:	89 45 e0             	mov    %eax,-0x20(%ebp)
8010474b:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
8010474f:	75 0a                	jne    8010475b <fork+0x21>
    return -1;
80104751:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104756:	e9 3a 01 00 00       	jmp    80104895 <fork+0x15b>
  
  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
8010475b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104761:	8b 10                	mov    (%eax),%edx
80104763:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104769:	8b 40 04             	mov    0x4(%eax),%eax
8010476c:	89 54 24 04          	mov    %edx,0x4(%esp)
80104770:	89 04 24             	mov    %eax,(%esp)
80104773:	e8 ef 3e 00 00       	call   80108667 <copyuvm>
80104778:	8b 55 e0             	mov    -0x20(%ebp),%edx
8010477b:	89 42 04             	mov    %eax,0x4(%edx)
8010477e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104781:	8b 40 04             	mov    0x4(%eax),%eax
80104784:	85 c0                	test   %eax,%eax
80104786:	75 2c                	jne    801047b4 <fork+0x7a>
    kfree(np->kstack);
80104788:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010478b:	8b 40 08             	mov    0x8(%eax),%eax
8010478e:	89 04 24             	mov    %eax,(%esp)
80104791:	e8 dc e2 ff ff       	call   80102a72 <kfree>
    np->kstack = 0;
80104796:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104799:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
801047a0:	8b 45 e0             	mov    -0x20(%ebp),%eax
801047a3:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
801047aa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801047af:	e9 e1 00 00 00       	jmp    80104895 <fork+0x15b>
  }
  np->sz = proc->sz;
801047b4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047ba:	8b 10                	mov    (%eax),%edx
801047bc:	8b 45 e0             	mov    -0x20(%ebp),%eax
801047bf:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
801047c1:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801047c8:	8b 45 e0             	mov    -0x20(%ebp),%eax
801047cb:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *proc->tf;
801047ce:	8b 45 e0             	mov    -0x20(%ebp),%eax
801047d1:	8b 50 18             	mov    0x18(%eax),%edx
801047d4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047da:	8b 40 18             	mov    0x18(%eax),%eax
801047dd:	89 c3                	mov    %eax,%ebx
801047df:	b8 13 00 00 00       	mov    $0x13,%eax
801047e4:	89 d7                	mov    %edx,%edi
801047e6:	89 de                	mov    %ebx,%esi
801047e8:	89 c1                	mov    %eax,%ecx
801047ea:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
801047ec:	8b 45 e0             	mov    -0x20(%ebp),%eax
801047ef:	8b 40 18             	mov    0x18(%eax),%eax
801047f2:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
801047f9:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80104800:	eb 3d                	jmp    8010483f <fork+0x105>
    if(proc->ofile[i])
80104802:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104808:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010480b:	83 c2 08             	add    $0x8,%edx
8010480e:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104812:	85 c0                	test   %eax,%eax
80104814:	74 25                	je     8010483b <fork+0x101>
      np->ofile[i] = filedup(proc->ofile[i]);
80104816:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010481c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010481f:	83 c2 08             	add    $0x8,%edx
80104822:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104826:	89 04 24             	mov    %eax,(%esp)
80104829:	e8 4e c7 ff ff       	call   80100f7c <filedup>
8010482e:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104831:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80104834:	83 c1 08             	add    $0x8,%ecx
80104837:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
8010483b:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
8010483f:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
80104843:	7e bd                	jle    80104802 <fork+0xc8>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
80104845:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010484b:	8b 40 68             	mov    0x68(%eax),%eax
8010484e:	89 04 24             	mov    %eax,(%esp)
80104851:	e8 e0 cf ff ff       	call   80101836 <idup>
80104856:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104859:	89 42 68             	mov    %eax,0x68(%edx)
 
  pid = np->pid;
8010485c:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010485f:	8b 40 10             	mov    0x10(%eax),%eax
80104862:	89 45 dc             	mov    %eax,-0x24(%ebp)
  np->state = RUNNABLE;
80104865:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104868:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  safestrcpy(np->name, proc->name, sizeof(proc->name));
8010486f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104875:	8d 50 6c             	lea    0x6c(%eax),%edx
80104878:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010487b:	83 c0 6c             	add    $0x6c,%eax
8010487e:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104885:	00 
80104886:	89 54 24 04          	mov    %edx,0x4(%esp)
8010488a:	89 04 24             	mov    %eax,(%esp)
8010488d:	e8 d8 0c 00 00       	call   8010556a <safestrcpy>
  return pid;
80104892:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
80104895:	83 c4 2c             	add    $0x2c,%esp
80104898:	5b                   	pop    %ebx
80104899:	5e                   	pop    %esi
8010489a:	5f                   	pop    %edi
8010489b:	5d                   	pop    %ebp
8010489c:	c3                   	ret    

8010489d <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
8010489d:	55                   	push   %ebp
8010489e:	89 e5                	mov    %esp,%ebp
801048a0:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int fd;

  if(proc == initproc)
801048a3:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801048aa:	a1 48 c6 10 80       	mov    0x8010c648,%eax
801048af:	39 c2                	cmp    %eax,%edx
801048b1:	75 0c                	jne    801048bf <exit+0x22>
    panic("init exiting");
801048b3:	c7 04 24 01 8c 10 80 	movl   $0x80108c01,(%esp)
801048ba:	e8 7e bc ff ff       	call   8010053d <panic>

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
801048bf:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
801048c6:	eb 44                	jmp    8010490c <exit+0x6f>
    if(proc->ofile[fd]){
801048c8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048ce:	8b 55 f0             	mov    -0x10(%ebp),%edx
801048d1:	83 c2 08             	add    $0x8,%edx
801048d4:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801048d8:	85 c0                	test   %eax,%eax
801048da:	74 2c                	je     80104908 <exit+0x6b>
      fileclose(proc->ofile[fd]);
801048dc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048e2:	8b 55 f0             	mov    -0x10(%ebp),%edx
801048e5:	83 c2 08             	add    $0x8,%edx
801048e8:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801048ec:	89 04 24             	mov    %eax,(%esp)
801048ef:	e8 d0 c6 ff ff       	call   80100fc4 <fileclose>
      proc->ofile[fd] = 0;
801048f4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048fa:	8b 55 f0             	mov    -0x10(%ebp),%edx
801048fd:	83 c2 08             	add    $0x8,%edx
80104900:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80104907:	00 

  if(proc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80104908:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
8010490c:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
80104910:	7e b6                	jle    801048c8 <exit+0x2b>
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  iput(proc->cwd);
80104912:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104918:	8b 40 68             	mov    0x68(%eax),%eax
8010491b:	89 04 24             	mov    %eax,(%esp)
8010491e:	e8 f8 d0 ff ff       	call   80101a1b <iput>
  proc->cwd = 0;
80104923:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104929:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)

  acquire(&ptable.lock);
80104930:	c7 04 24 20 0f 11 80 	movl   $0x80110f20,(%esp)
80104937:	e8 77 07 00 00       	call   801050b3 <acquire>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);
8010493c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104942:	8b 40 14             	mov    0x14(%eax),%eax
80104945:	89 04 24             	mov    %eax,(%esp)
80104948:	e8 ee 04 00 00       	call   80104e3b <wakeup1>

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010494d:	c7 45 f4 54 0f 11 80 	movl   $0x80110f54,-0xc(%ebp)
80104954:	eb 3b                	jmp    80104991 <exit+0xf4>
    if(p->parent == proc){
80104956:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104959:	8b 50 14             	mov    0x14(%eax),%edx
8010495c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104962:	39 c2                	cmp    %eax,%edx
80104964:	75 24                	jne    8010498a <exit+0xed>
      p->parent = initproc;
80104966:	8b 15 48 c6 10 80    	mov    0x8010c648,%edx
8010496c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010496f:	89 50 14             	mov    %edx,0x14(%eax)
      if(p->state == ZOMBIE)
80104972:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104975:	8b 40 0c             	mov    0xc(%eax),%eax
80104978:	83 f8 05             	cmp    $0x5,%eax
8010497b:	75 0d                	jne    8010498a <exit+0xed>
        wakeup1(initproc);
8010497d:	a1 48 c6 10 80       	mov    0x8010c648,%eax
80104982:	89 04 24             	mov    %eax,(%esp)
80104985:	e8 b1 04 00 00       	call   80104e3b <wakeup1>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010498a:	81 45 f4 84 00 00 00 	addl   $0x84,-0xc(%ebp)
80104991:	81 7d f4 54 30 11 80 	cmpl   $0x80113054,-0xc(%ebp)
80104998:	72 bc                	jb     80104956 <exit+0xb9>
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  proc->state = ZOMBIE;
8010499a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801049a0:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
  sched();
801049a7:	e8 b8 02 00 00       	call   80104c64 <sched>
  panic("zombie exit");
801049ac:	c7 04 24 0e 8c 10 80 	movl   $0x80108c0e,(%esp)
801049b3:	e8 85 bb ff ff       	call   8010053d <panic>

801049b8 <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
801049b8:	55                   	push   %ebp
801049b9:	89 e5                	mov    %esp,%ebp
801049bb:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
801049be:	c7 04 24 20 0f 11 80 	movl   $0x80110f20,(%esp)
801049c5:	e8 e9 06 00 00       	call   801050b3 <acquire>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
801049ca:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801049d1:	c7 45 f4 54 0f 11 80 	movl   $0x80110f54,-0xc(%ebp)
801049d8:	e9 9d 00 00 00       	jmp    80104a7a <wait+0xc2>
      if(p->parent != proc)
801049dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049e0:	8b 50 14             	mov    0x14(%eax),%edx
801049e3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801049e9:	39 c2                	cmp    %eax,%edx
801049eb:	0f 85 81 00 00 00    	jne    80104a72 <wait+0xba>
        continue;
      havekids = 1;
801049f1:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
      if(p->state == ZOMBIE){
801049f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049fb:	8b 40 0c             	mov    0xc(%eax),%eax
801049fe:	83 f8 05             	cmp    $0x5,%eax
80104a01:	75 70                	jne    80104a73 <wait+0xbb>
        // Found one.
        pid = p->pid;
80104a03:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a06:	8b 40 10             	mov    0x10(%eax),%eax
80104a09:	89 45 ec             	mov    %eax,-0x14(%ebp)
        kfree(p->kstack);
80104a0c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a0f:	8b 40 08             	mov    0x8(%eax),%eax
80104a12:	89 04 24             	mov    %eax,(%esp)
80104a15:	e8 58 e0 ff ff       	call   80102a72 <kfree>
        p->kstack = 0;
80104a1a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a1d:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
        freevm(p->pgdir);
80104a24:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a27:	8b 40 04             	mov    0x4(%eax),%eax
80104a2a:	89 04 24             	mov    %eax,(%esp)
80104a2d:	e8 2f 3b 00 00       	call   80108561 <freevm>
        p->state = UNUSED;
80104a32:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a35:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        p->pid = 0;
80104a3c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a3f:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
        p->parent = 0;
80104a46:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a49:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
        p->name[0] = 0;
80104a50:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a53:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)
        p->killed = 0;
80104a57:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a5a:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
        release(&ptable.lock);
80104a61:	c7 04 24 20 0f 11 80 	movl   $0x80110f20,(%esp)
80104a68:	e8 e1 06 00 00       	call   8010514e <release>
        return pid;
80104a6d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104a70:	eb 56                	jmp    80104ac8 <wait+0x110>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->parent != proc)
        continue;
80104a72:	90                   	nop

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104a73:	81 45 f4 84 00 00 00 	addl   $0x84,-0xc(%ebp)
80104a7a:	81 7d f4 54 30 11 80 	cmpl   $0x80113054,-0xc(%ebp)
80104a81:	0f 82 56 ff ff ff    	jb     801049dd <wait+0x25>
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
80104a87:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80104a8b:	74 0d                	je     80104a9a <wait+0xe2>
80104a8d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104a93:	8b 40 24             	mov    0x24(%eax),%eax
80104a96:	85 c0                	test   %eax,%eax
80104a98:	74 13                	je     80104aad <wait+0xf5>
      release(&ptable.lock);
80104a9a:	c7 04 24 20 0f 11 80 	movl   $0x80110f20,(%esp)
80104aa1:	e8 a8 06 00 00       	call   8010514e <release>
      return -1;
80104aa6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104aab:	eb 1b                	jmp    80104ac8 <wait+0x110>
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
80104aad:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ab3:	c7 44 24 04 20 0f 11 	movl   $0x80110f20,0x4(%esp)
80104aba:	80 
80104abb:	89 04 24             	mov    %eax,(%esp)
80104abe:	e8 b1 02 00 00       	call   80104d74 <sleep>
  }
80104ac3:	e9 02 ff ff ff       	jmp    801049ca <wait+0x12>
}
80104ac8:	c9                   	leave  
80104ac9:	c3                   	ret    

80104aca <register_handler>:

void
register_handler(sighandler_t sighandler)
{
80104aca:	55                   	push   %ebp
80104acb:	89 e5                	mov    %esp,%ebp
80104acd:	83 ec 28             	sub    $0x28,%esp
  char* addr = uva2ka(proc->pgdir, (char*)proc->tf->esp);
80104ad0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ad6:	8b 40 18             	mov    0x18(%eax),%eax
80104ad9:	8b 40 44             	mov    0x44(%eax),%eax
80104adc:	89 c2                	mov    %eax,%edx
80104ade:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ae4:	8b 40 04             	mov    0x4(%eax),%eax
80104ae7:	89 54 24 04          	mov    %edx,0x4(%esp)
80104aeb:	89 04 24             	mov    %eax,(%esp)
80104aee:	e8 85 3c 00 00       	call   80108778 <uva2ka>
80104af3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if ((proc->tf->esp & 0xFFF) == 0)
80104af6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104afc:	8b 40 18             	mov    0x18(%eax),%eax
80104aff:	8b 40 44             	mov    0x44(%eax),%eax
80104b02:	25 ff 0f 00 00       	and    $0xfff,%eax
80104b07:	85 c0                	test   %eax,%eax
80104b09:	75 0c                	jne    80104b17 <register_handler+0x4d>
    panic("esp_offset == 0");
80104b0b:	c7 04 24 1a 8c 10 80 	movl   $0x80108c1a,(%esp)
80104b12:	e8 26 ba ff ff       	call   8010053d <panic>

    /* open a new frame */
  *(int*)(addr + ((proc->tf->esp - 4) & 0xFFF))
80104b17:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b1d:	8b 40 18             	mov    0x18(%eax),%eax
80104b20:	8b 40 44             	mov    0x44(%eax),%eax
80104b23:	83 e8 04             	sub    $0x4,%eax
80104b26:	25 ff 0f 00 00       	and    $0xfff,%eax
80104b2b:	03 45 f4             	add    -0xc(%ebp),%eax
          = proc->tf->eip;
80104b2e:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104b35:	8b 52 18             	mov    0x18(%edx),%edx
80104b38:	8b 52 38             	mov    0x38(%edx),%edx
80104b3b:	89 10                	mov    %edx,(%eax)
  proc->tf->esp -= 4;
80104b3d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b43:	8b 40 18             	mov    0x18(%eax),%eax
80104b46:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104b4d:	8b 52 18             	mov    0x18(%edx),%edx
80104b50:	8b 52 44             	mov    0x44(%edx),%edx
80104b53:	83 ea 04             	sub    $0x4,%edx
80104b56:	89 50 44             	mov    %edx,0x44(%eax)

    /* update eip */
  proc->tf->eip = (uint)sighandler;
80104b59:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b5f:	8b 40 18             	mov    0x18(%eax),%eax
80104b62:	8b 55 08             	mov    0x8(%ebp),%edx
80104b65:	89 50 38             	mov    %edx,0x38(%eax)
}
80104b68:	c9                   	leave  
80104b69:	c3                   	ret    

80104b6a <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
80104b6a:	55                   	push   %ebp
80104b6b:	89 e5                	mov    %esp,%ebp
80104b6d:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  
  for(;;){
    // Enable interrupts on this processor.
    sti();
80104b70:	e8 a9 f4 ff ff       	call   8010401e <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
80104b75:	c7 04 24 20 0f 11 80 	movl   $0x80110f20,(%esp)
80104b7c:	e8 32 05 00 00       	call   801050b3 <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104b81:	c7 45 f4 54 0f 11 80 	movl   $0x80110f54,-0xc(%ebp)
80104b88:	e9 b9 00 00 00       	jmp    80104c46 <scheduler+0xdc>
      if(p->state != RUNNABLE)
80104b8d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b90:	8b 40 0c             	mov    0xc(%eax),%eax
80104b93:	83 f8 03             	cmp    $0x3,%eax
80104b96:	0f 85 a2 00 00 00    	jne    80104c3e <scheduler+0xd4>
        continue;
    
      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
80104b9c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b9f:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
      switchuvm(p);
80104ba5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ba8:	89 04 24             	mov    %eax,(%esp)
80104bab:	e8 3a 35 00 00       	call   801080ea <switchuvm>
      p->state = RUNNING;
80104bb0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104bb3:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      swtch(&cpu->scheduler, proc->context);
80104bba:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104bc0:	8b 40 1c             	mov    0x1c(%eax),%eax
80104bc3:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80104bca:	83 c2 04             	add    $0x4,%edx
80104bcd:	89 44 24 04          	mov    %eax,0x4(%esp)
80104bd1:	89 14 24             	mov    %edx,(%esp)
80104bd4:	e8 07 0a 00 00       	call   801055e0 <swtch>
      if(proc->isSwapped)
80104bd9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104bdf:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
80104be5:	85 c0                	test   %eax,%eax
80104be7:	74 43                	je     80104c2c <scheduler+0xc2>
      {
	cprintf("**********before freevm pid = %d\n",proc->pid);
80104be9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104bef:	8b 40 10             	mov    0x10(%eax),%eax
80104bf2:	89 44 24 04          	mov    %eax,0x4(%esp)
80104bf6:	c7 04 24 2c 8c 10 80 	movl   $0x80108c2c,(%esp)
80104bfd:	e8 9f b7 ff ff       	call   801003a1 <cprintf>
	freevm(proc->pgdir);
80104c02:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c08:	8b 40 04             	mov    0x4(%eax),%eax
80104c0b:	89 04 24             	mov    %eax,(%esp)
80104c0e:	e8 4e 39 00 00       	call   80108561 <freevm>
	cprintf("**********after freevm pid = %d\n",proc->pid);
80104c13:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c19:	8b 40 10             	mov    0x10(%eax),%eax
80104c1c:	89 44 24 04          	mov    %eax,0x4(%esp)
80104c20:	c7 04 24 50 8c 10 80 	movl   $0x80108c50,(%esp)
80104c27:	e8 75 b7 ff ff       	call   801003a1 <cprintf>
      }
      switchkvm();
80104c2c:	e8 9c 34 00 00       	call   801080cd <switchkvm>
      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
80104c31:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80104c38:	00 00 00 00 
80104c3c:	eb 01                	jmp    80104c3f <scheduler+0xd5>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->state != RUNNABLE)
        continue;
80104c3e:	90                   	nop
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104c3f:	81 45 f4 84 00 00 00 	addl   $0x84,-0xc(%ebp)
80104c46:	81 7d f4 54 30 11 80 	cmpl   $0x80113054,-0xc(%ebp)
80104c4d:	0f 82 3a ff ff ff    	jb     80104b8d <scheduler+0x23>
      switchkvm();
      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
80104c53:	c7 04 24 20 0f 11 80 	movl   $0x80110f20,(%esp)
80104c5a:	e8 ef 04 00 00       	call   8010514e <release>

  }
80104c5f:	e9 0c ff ff ff       	jmp    80104b70 <scheduler+0x6>

80104c64 <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
80104c64:	55                   	push   %ebp
80104c65:	89 e5                	mov    %esp,%ebp
80104c67:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
80104c6a:	c7 04 24 20 0f 11 80 	movl   $0x80110f20,(%esp)
80104c71:	e8 94 05 00 00       	call   8010520a <holding>
80104c76:	85 c0                	test   %eax,%eax
80104c78:	75 0c                	jne    80104c86 <sched+0x22>
    panic("sched ptable.lock");
80104c7a:	c7 04 24 71 8c 10 80 	movl   $0x80108c71,(%esp)
80104c81:	e8 b7 b8 ff ff       	call   8010053d <panic>
  if(cpu->ncli != 1)
80104c86:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104c8c:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80104c92:	83 f8 01             	cmp    $0x1,%eax
80104c95:	74 0c                	je     80104ca3 <sched+0x3f>
    panic("sched locks");
80104c97:	c7 04 24 83 8c 10 80 	movl   $0x80108c83,(%esp)
80104c9e:	e8 9a b8 ff ff       	call   8010053d <panic>
  if(proc->state == RUNNING)
80104ca3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ca9:	8b 40 0c             	mov    0xc(%eax),%eax
80104cac:	83 f8 04             	cmp    $0x4,%eax
80104caf:	75 0c                	jne    80104cbd <sched+0x59>
    panic("sched running");
80104cb1:	c7 04 24 8f 8c 10 80 	movl   $0x80108c8f,(%esp)
80104cb8:	e8 80 b8 ff ff       	call   8010053d <panic>
  if(readeflags()&FL_IF)
80104cbd:	e8 47 f3 ff ff       	call   80104009 <readeflags>
80104cc2:	25 00 02 00 00       	and    $0x200,%eax
80104cc7:	85 c0                	test   %eax,%eax
80104cc9:	74 0c                	je     80104cd7 <sched+0x73>
    panic("sched interruptible");
80104ccb:	c7 04 24 9d 8c 10 80 	movl   $0x80108c9d,(%esp)
80104cd2:	e8 66 b8 ff ff       	call   8010053d <panic>
  intena = cpu->intena;
80104cd7:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104cdd:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80104ce3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->context, cpu->scheduler);
80104ce6:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104cec:	8b 40 04             	mov    0x4(%eax),%eax
80104cef:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104cf6:	83 c2 1c             	add    $0x1c,%edx
80104cf9:	89 44 24 04          	mov    %eax,0x4(%esp)
80104cfd:	89 14 24             	mov    %edx,(%esp)
80104d00:	e8 db 08 00 00       	call   801055e0 <swtch>
  cpu->intena = intena;
80104d05:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104d0b:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104d0e:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80104d14:	c9                   	leave  
80104d15:	c3                   	ret    

80104d16 <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
80104d16:	55                   	push   %ebp
80104d17:	89 e5                	mov    %esp,%ebp
80104d19:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
80104d1c:	c7 04 24 20 0f 11 80 	movl   $0x80110f20,(%esp)
80104d23:	e8 8b 03 00 00       	call   801050b3 <acquire>
  proc->state = RUNNABLE;
80104d28:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d2e:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
80104d35:	e8 2a ff ff ff       	call   80104c64 <sched>
  release(&ptable.lock);
80104d3a:	c7 04 24 20 0f 11 80 	movl   $0x80110f20,(%esp)
80104d41:	e8 08 04 00 00       	call   8010514e <release>
}
80104d46:	c9                   	leave  
80104d47:	c3                   	ret    

80104d48 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
80104d48:	55                   	push   %ebp
80104d49:	89 e5                	mov    %esp,%ebp
80104d4b:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
80104d4e:	c7 04 24 20 0f 11 80 	movl   $0x80110f20,(%esp)
80104d55:	e8 f4 03 00 00       	call   8010514e <release>

  if (first) {
80104d5a:	a1 24 c0 10 80       	mov    0x8010c024,%eax
80104d5f:	85 c0                	test   %eax,%eax
80104d61:	74 0f                	je     80104d72 <forkret+0x2a>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
80104d63:	c7 05 24 c0 10 80 00 	movl   $0x0,0x8010c024
80104d6a:	00 00 00 
    initlog();
80104d6d:	e8 aa e2 ff ff       	call   8010301c <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
80104d72:	c9                   	leave  
80104d73:	c3                   	ret    

80104d74 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
80104d74:	55                   	push   %ebp
80104d75:	89 e5                	mov    %esp,%ebp
80104d77:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
80104d7a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d80:	85 c0                	test   %eax,%eax
80104d82:	75 0c                	jne    80104d90 <sleep+0x1c>
    panic("sleep");
80104d84:	c7 04 24 b1 8c 10 80 	movl   $0x80108cb1,(%esp)
80104d8b:	e8 ad b7 ff ff       	call   8010053d <panic>

  if(lk == 0)
80104d90:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80104d94:	75 0c                	jne    80104da2 <sleep+0x2e>
    panic("sleep without lk");
80104d96:	c7 04 24 b7 8c 10 80 	movl   $0x80108cb7,(%esp)
80104d9d:	e8 9b b7 ff ff       	call   8010053d <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
80104da2:	81 7d 0c 20 0f 11 80 	cmpl   $0x80110f20,0xc(%ebp)
80104da9:	74 17                	je     80104dc2 <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
80104dab:	c7 04 24 20 0f 11 80 	movl   $0x80110f20,(%esp)
80104db2:	e8 fc 02 00 00       	call   801050b3 <acquire>
    release(lk);
80104db7:	8b 45 0c             	mov    0xc(%ebp),%eax
80104dba:	89 04 24             	mov    %eax,(%esp)
80104dbd:	e8 8c 03 00 00       	call   8010514e <release>
  }

  // Go to sleep.
  proc->chan = chan;
80104dc2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104dc8:	8b 55 08             	mov    0x8(%ebp),%edx
80104dcb:	89 50 20             	mov    %edx,0x20(%eax)
  proc->state = SLEEPING;
80104dce:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104dd4:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)

  // Swap out
  swapOut();
80104ddb:	e8 a5 f5 ff ff       	call   80104385 <swapOut>
  
  sched();
80104de0:	e8 7f fe ff ff       	call   80104c64 <sched>
  if(proc->pid>3)
80104de5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104deb:	8b 40 10             	mov    0x10(%eax),%eax
80104dee:	83 f8 03             	cmp    $0x3,%eax
80104df1:	7e 19                	jle    80104e0c <sleep+0x98>
    cprintf("pid = %d, after waking up\n",proc->pid);
80104df3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104df9:	8b 40 10             	mov    0x10(%eax),%eax
80104dfc:	89 44 24 04          	mov    %eax,0x4(%esp)
80104e00:	c7 04 24 c8 8c 10 80 	movl   $0x80108cc8,(%esp)
80104e07:	e8 95 b5 ff ff       	call   801003a1 <cprintf>
  // Tidy up.
  proc->chan = 0;
80104e0c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e12:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
80104e19:	81 7d 0c 20 0f 11 80 	cmpl   $0x80110f20,0xc(%ebp)
80104e20:	74 17                	je     80104e39 <sleep+0xc5>
    release(&ptable.lock);
80104e22:	c7 04 24 20 0f 11 80 	movl   $0x80110f20,(%esp)
80104e29:	e8 20 03 00 00       	call   8010514e <release>
    acquire(lk);
80104e2e:	8b 45 0c             	mov    0xc(%ebp),%eax
80104e31:	89 04 24             	mov    %eax,(%esp)
80104e34:	e8 7a 02 00 00       	call   801050b3 <acquire>
  }
}
80104e39:	c9                   	leave  
80104e3a:	c3                   	ret    

80104e3b <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80104e3b:	55                   	push   %ebp
80104e3c:	89 e5                	mov    %esp,%ebp
80104e3e:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104e41:	c7 45 fc 54 0f 11 80 	movl   $0x80110f54,-0x4(%ebp)
80104e48:	eb 53                	jmp    80104e9d <wakeup1+0x62>
  {
    if(p->state == SLEEPING && p->chan == chan)
80104e4a:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104e4d:	8b 40 0c             	mov    0xc(%eax),%eax
80104e50:	83 f8 02             	cmp    $0x2,%eax
80104e53:	75 15                	jne    80104e6a <wakeup1+0x2f>
80104e55:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104e58:	8b 40 20             	mov    0x20(%eax),%eax
80104e5b:	3b 45 08             	cmp    0x8(%ebp),%eax
80104e5e:	75 0a                	jne    80104e6a <wakeup1+0x2f>
      p->state = RUNNABLE;
80104e60:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104e63:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
    if(p->state == SLEEPING_SUSPENDED && p->chan == chan)
80104e6a:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104e6d:	8b 40 0c             	mov    0xc(%eax),%eax
80104e70:	83 f8 06             	cmp    $0x6,%eax
80104e73:	75 21                	jne    80104e96 <wakeup1+0x5b>
80104e75:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104e78:	8b 40 20             	mov    0x20(%eax),%eax
80104e7b:	3b 45 08             	cmp    0x8(%ebp),%eax
80104e7e:	75 16                	jne    80104e96 <wakeup1+0x5b>
    {
      p->state = RUNNABLE_SUSPENDED;
80104e80:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104e83:	c7 40 0c 07 00 00 00 	movl   $0x7,0xc(%eax)
      inswapper->state = RUNNABLE;
80104e8a:	a1 4c c6 10 80       	mov    0x8010c64c,%eax
80104e8f:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104e96:	81 45 fc 84 00 00 00 	addl   $0x84,-0x4(%ebp)
80104e9d:	81 7d fc 54 30 11 80 	cmpl   $0x80113054,-0x4(%ebp)
80104ea4:	72 a4                	jb     80104e4a <wakeup1+0xf>
    {
      p->state = RUNNABLE_SUSPENDED;
      inswapper->state = RUNNABLE;
    }
  }
}
80104ea6:	c9                   	leave  
80104ea7:	c3                   	ret    

80104ea8 <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80104ea8:	55                   	push   %ebp
80104ea9:	89 e5                	mov    %esp,%ebp
80104eab:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);
80104eae:	c7 04 24 20 0f 11 80 	movl   $0x80110f20,(%esp)
80104eb5:	e8 f9 01 00 00       	call   801050b3 <acquire>
  wakeup1(chan);
80104eba:	8b 45 08             	mov    0x8(%ebp),%eax
80104ebd:	89 04 24             	mov    %eax,(%esp)
80104ec0:	e8 76 ff ff ff       	call   80104e3b <wakeup1>
  release(&ptable.lock);
80104ec5:	c7 04 24 20 0f 11 80 	movl   $0x80110f20,(%esp)
80104ecc:	e8 7d 02 00 00       	call   8010514e <release>
}
80104ed1:	c9                   	leave  
80104ed2:	c3                   	ret    

80104ed3 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80104ed3:	55                   	push   %ebp
80104ed4:	89 e5                	mov    %esp,%ebp
80104ed6:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  acquire(&ptable.lock);
80104ed9:	c7 04 24 20 0f 11 80 	movl   $0x80110f20,(%esp)
80104ee0:	e8 ce 01 00 00       	call   801050b3 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104ee5:	c7 45 f4 54 0f 11 80 	movl   $0x80110f54,-0xc(%ebp)
80104eec:	eb 44                	jmp    80104f32 <kill+0x5f>
    if(p->pid == pid){
80104eee:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ef1:	8b 40 10             	mov    0x10(%eax),%eax
80104ef4:	3b 45 08             	cmp    0x8(%ebp),%eax
80104ef7:	75 32                	jne    80104f2b <kill+0x58>
      p->killed = 1;
80104ef9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104efc:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80104f03:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f06:	8b 40 0c             	mov    0xc(%eax),%eax
80104f09:	83 f8 02             	cmp    $0x2,%eax
80104f0c:	75 0a                	jne    80104f18 <kill+0x45>
        p->state = RUNNABLE;
80104f0e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f11:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      release(&ptable.lock);
80104f18:	c7 04 24 20 0f 11 80 	movl   $0x80110f20,(%esp)
80104f1f:	e8 2a 02 00 00       	call   8010514e <release>
      return 0;
80104f24:	b8 00 00 00 00       	mov    $0x0,%eax
80104f29:	eb 21                	jmp    80104f4c <kill+0x79>
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104f2b:	81 45 f4 84 00 00 00 	addl   $0x84,-0xc(%ebp)
80104f32:	81 7d f4 54 30 11 80 	cmpl   $0x80113054,-0xc(%ebp)
80104f39:	72 b3                	jb     80104eee <kill+0x1b>
        p->state = RUNNABLE;
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
80104f3b:	c7 04 24 20 0f 11 80 	movl   $0x80110f20,(%esp)
80104f42:	e8 07 02 00 00       	call   8010514e <release>
  return -1;
80104f47:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104f4c:	c9                   	leave  
80104f4d:	c3                   	ret    

80104f4e <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80104f4e:	55                   	push   %ebp
80104f4f:	89 e5                	mov    %esp,%ebp
80104f51:	83 ec 58             	sub    $0x58,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104f54:	c7 45 f0 54 0f 11 80 	movl   $0x80110f54,-0x10(%ebp)
80104f5b:	e9 db 00 00 00       	jmp    8010503b <procdump+0xed>
    if(p->state == UNUSED)
80104f60:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104f63:	8b 40 0c             	mov    0xc(%eax),%eax
80104f66:	85 c0                	test   %eax,%eax
80104f68:	0f 84 c5 00 00 00    	je     80105033 <procdump+0xe5>
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80104f6e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104f71:	8b 40 0c             	mov    0xc(%eax),%eax
80104f74:	83 f8 05             	cmp    $0x5,%eax
80104f77:	77 23                	ja     80104f9c <procdump+0x4e>
80104f79:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104f7c:	8b 40 0c             	mov    0xc(%eax),%eax
80104f7f:	8b 04 85 0c c0 10 80 	mov    -0x7fef3ff4(,%eax,4),%eax
80104f86:	85 c0                	test   %eax,%eax
80104f88:	74 12                	je     80104f9c <procdump+0x4e>
      state = states[p->state];
80104f8a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104f8d:	8b 40 0c             	mov    0xc(%eax),%eax
80104f90:	8b 04 85 0c c0 10 80 	mov    -0x7fef3ff4(,%eax,4),%eax
80104f97:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104f9a:	eb 07                	jmp    80104fa3 <procdump+0x55>
    else
      state = "???";
80104f9c:	c7 45 ec e3 8c 10 80 	movl   $0x80108ce3,-0x14(%ebp)
    cprintf("%d %s %s", p->pid, state, p->name);
80104fa3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104fa6:	8d 50 6c             	lea    0x6c(%eax),%edx
80104fa9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104fac:	8b 40 10             	mov    0x10(%eax),%eax
80104faf:	89 54 24 0c          	mov    %edx,0xc(%esp)
80104fb3:	8b 55 ec             	mov    -0x14(%ebp),%edx
80104fb6:	89 54 24 08          	mov    %edx,0x8(%esp)
80104fba:	89 44 24 04          	mov    %eax,0x4(%esp)
80104fbe:	c7 04 24 e7 8c 10 80 	movl   $0x80108ce7,(%esp)
80104fc5:	e8 d7 b3 ff ff       	call   801003a1 <cprintf>
    if(p->state == SLEEPING){
80104fca:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104fcd:	8b 40 0c             	mov    0xc(%eax),%eax
80104fd0:	83 f8 02             	cmp    $0x2,%eax
80104fd3:	75 50                	jne    80105025 <procdump+0xd7>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80104fd5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104fd8:	8b 40 1c             	mov    0x1c(%eax),%eax
80104fdb:	8b 40 0c             	mov    0xc(%eax),%eax
80104fde:	83 c0 08             	add    $0x8,%eax
80104fe1:	8d 55 c4             	lea    -0x3c(%ebp),%edx
80104fe4:	89 54 24 04          	mov    %edx,0x4(%esp)
80104fe8:	89 04 24             	mov    %eax,(%esp)
80104feb:	e8 ad 01 00 00       	call   8010519d <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80104ff0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104ff7:	eb 1b                	jmp    80105014 <procdump+0xc6>
        cprintf(" %p", pc[i]);
80104ff9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ffc:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80105000:	89 44 24 04          	mov    %eax,0x4(%esp)
80105004:	c7 04 24 f0 8c 10 80 	movl   $0x80108cf0,(%esp)
8010500b:	e8 91 b3 ff ff       	call   801003a1 <cprintf>
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
80105010:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80105014:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
80105018:	7f 0b                	jg     80105025 <procdump+0xd7>
8010501a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010501d:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80105021:	85 c0                	test   %eax,%eax
80105023:	75 d4                	jne    80104ff9 <procdump+0xab>
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80105025:	c7 04 24 f4 8c 10 80 	movl   $0x80108cf4,(%esp)
8010502c:	e8 70 b3 ff ff       	call   801003a1 <cprintf>
80105031:	eb 01                	jmp    80105034 <procdump+0xe6>
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
80105033:	90                   	nop
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105034:	81 45 f0 84 00 00 00 	addl   $0x84,-0x10(%ebp)
8010503b:	81 7d f0 54 30 11 80 	cmpl   $0x80113054,-0x10(%ebp)
80105042:	0f 82 18 ff ff ff    	jb     80104f60 <procdump+0x12>
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}
80105048:	c9                   	leave  
80105049:	c3                   	ret    
	...

8010504c <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
8010504c:	55                   	push   %ebp
8010504d:	89 e5                	mov    %esp,%ebp
8010504f:	53                   	push   %ebx
80105050:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80105053:	9c                   	pushf  
80105054:	5b                   	pop    %ebx
80105055:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80105058:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
8010505b:	83 c4 10             	add    $0x10,%esp
8010505e:	5b                   	pop    %ebx
8010505f:	5d                   	pop    %ebp
80105060:	c3                   	ret    

80105061 <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
80105061:	55                   	push   %ebp
80105062:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
80105064:	fa                   	cli    
}
80105065:	5d                   	pop    %ebp
80105066:	c3                   	ret    

80105067 <sti>:

static inline void
sti(void)
{
80105067:	55                   	push   %ebp
80105068:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
8010506a:	fb                   	sti    
}
8010506b:	5d                   	pop    %ebp
8010506c:	c3                   	ret    

8010506d <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
8010506d:	55                   	push   %ebp
8010506e:	89 e5                	mov    %esp,%ebp
80105070:	53                   	push   %ebx
80105071:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
80105074:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80105077:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
8010507a:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
8010507d:	89 c3                	mov    %eax,%ebx
8010507f:	89 d8                	mov    %ebx,%eax
80105081:	f0 87 02             	lock xchg %eax,(%edx)
80105084:	89 c3                	mov    %eax,%ebx
80105086:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80105089:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
8010508c:	83 c4 10             	add    $0x10,%esp
8010508f:	5b                   	pop    %ebx
80105090:	5d                   	pop    %ebp
80105091:	c3                   	ret    

80105092 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80105092:	55                   	push   %ebp
80105093:	89 e5                	mov    %esp,%ebp
  lk->name = name;
80105095:	8b 45 08             	mov    0x8(%ebp),%eax
80105098:	8b 55 0c             	mov    0xc(%ebp),%edx
8010509b:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
8010509e:	8b 45 08             	mov    0x8(%ebp),%eax
801050a1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
801050a7:	8b 45 08             	mov    0x8(%ebp),%eax
801050aa:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
801050b1:	5d                   	pop    %ebp
801050b2:	c3                   	ret    

801050b3 <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
801050b3:	55                   	push   %ebp
801050b4:	89 e5                	mov    %esp,%ebp
801050b6:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
801050b9:	e8 76 01 00 00       	call   80105234 <pushcli>
  if(holding(lk))
801050be:	8b 45 08             	mov    0x8(%ebp),%eax
801050c1:	89 04 24             	mov    %eax,(%esp)
801050c4:	e8 41 01 00 00       	call   8010520a <holding>
801050c9:	85 c0                	test   %eax,%eax
801050cb:	74 45                	je     80105112 <acquire+0x5f>
  {
    cprintf("lock = %s\n",lk->name);
801050cd:	8b 45 08             	mov    0x8(%ebp),%eax
801050d0:	8b 40 04             	mov    0x4(%eax),%eax
801050d3:	89 44 24 04          	mov    %eax,0x4(%esp)
801050d7:	c7 04 24 20 8d 10 80 	movl   $0x80108d20,(%esp)
801050de:	e8 be b2 ff ff       	call   801003a1 <cprintf>
    if(proc)
801050e3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050e9:	85 c0                	test   %eax,%eax
801050eb:	74 19                	je     80105106 <acquire+0x53>
      cprintf("pid = %d\n",proc->pid);
801050ed:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050f3:	8b 40 10             	mov    0x10(%eax),%eax
801050f6:	89 44 24 04          	mov    %eax,0x4(%esp)
801050fa:	c7 04 24 2b 8d 10 80 	movl   $0x80108d2b,(%esp)
80105101:	e8 9b b2 ff ff       	call   801003a1 <cprintf>
    panic("acquire");
80105106:	c7 04 24 35 8d 10 80 	movl   $0x80108d35,(%esp)
8010510d:	e8 2b b4 ff ff       	call   8010053d <panic>
  }

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
80105112:	90                   	nop
80105113:	8b 45 08             	mov    0x8(%ebp),%eax
80105116:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010511d:	00 
8010511e:	89 04 24             	mov    %eax,(%esp)
80105121:	e8 47 ff ff ff       	call   8010506d <xchg>
80105126:	85 c0                	test   %eax,%eax
80105128:	75 e9                	jne    80105113 <acquire+0x60>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
8010512a:	8b 45 08             	mov    0x8(%ebp),%eax
8010512d:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80105134:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
80105137:	8b 45 08             	mov    0x8(%ebp),%eax
8010513a:	83 c0 0c             	add    $0xc,%eax
8010513d:	89 44 24 04          	mov    %eax,0x4(%esp)
80105141:	8d 45 08             	lea    0x8(%ebp),%eax
80105144:	89 04 24             	mov    %eax,(%esp)
80105147:	e8 51 00 00 00       	call   8010519d <getcallerpcs>
}
8010514c:	c9                   	leave  
8010514d:	c3                   	ret    

8010514e <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
8010514e:	55                   	push   %ebp
8010514f:	89 e5                	mov    %esp,%ebp
80105151:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
80105154:	8b 45 08             	mov    0x8(%ebp),%eax
80105157:	89 04 24             	mov    %eax,(%esp)
8010515a:	e8 ab 00 00 00       	call   8010520a <holding>
8010515f:	85 c0                	test   %eax,%eax
80105161:	75 0c                	jne    8010516f <release+0x21>
    panic("release");
80105163:	c7 04 24 3d 8d 10 80 	movl   $0x80108d3d,(%esp)
8010516a:	e8 ce b3 ff ff       	call   8010053d <panic>

  lk->pcs[0] = 0;
8010516f:	8b 45 08             	mov    0x8(%ebp),%eax
80105172:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
80105179:	8b 45 08             	mov    0x8(%ebp),%eax
8010517c:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
80105183:	8b 45 08             	mov    0x8(%ebp),%eax
80105186:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010518d:	00 
8010518e:	89 04 24             	mov    %eax,(%esp)
80105191:	e8 d7 fe ff ff       	call   8010506d <xchg>

  popcli();
80105196:	e8 e1 00 00 00       	call   8010527c <popcli>
}
8010519b:	c9                   	leave  
8010519c:	c3                   	ret    

8010519d <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
8010519d:	55                   	push   %ebp
8010519e:	89 e5                	mov    %esp,%ebp
801051a0:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
801051a3:	8b 45 08             	mov    0x8(%ebp),%eax
801051a6:	83 e8 08             	sub    $0x8,%eax
801051a9:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
801051ac:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
801051b3:	eb 32                	jmp    801051e7 <getcallerpcs+0x4a>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
801051b5:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
801051b9:	74 47                	je     80105202 <getcallerpcs+0x65>
801051bb:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
801051c2:	76 3e                	jbe    80105202 <getcallerpcs+0x65>
801051c4:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
801051c8:	74 38                	je     80105202 <getcallerpcs+0x65>
      break;
    pcs[i] = ebp[1];     // saved %eip
801051ca:	8b 45 f8             	mov    -0x8(%ebp),%eax
801051cd:	c1 e0 02             	shl    $0x2,%eax
801051d0:	03 45 0c             	add    0xc(%ebp),%eax
801051d3:	8b 55 fc             	mov    -0x4(%ebp),%edx
801051d6:	8b 52 04             	mov    0x4(%edx),%edx
801051d9:	89 10                	mov    %edx,(%eax)
    ebp = (uint*)ebp[0]; // saved %ebp
801051db:	8b 45 fc             	mov    -0x4(%ebp),%eax
801051de:	8b 00                	mov    (%eax),%eax
801051e0:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
801051e3:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
801051e7:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
801051eb:	7e c8                	jle    801051b5 <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
801051ed:	eb 13                	jmp    80105202 <getcallerpcs+0x65>
    pcs[i] = 0;
801051ef:	8b 45 f8             	mov    -0x8(%ebp),%eax
801051f2:	c1 e0 02             	shl    $0x2,%eax
801051f5:	03 45 0c             	add    0xc(%ebp),%eax
801051f8:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
801051fe:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105202:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105206:	7e e7                	jle    801051ef <getcallerpcs+0x52>
    pcs[i] = 0;
}
80105208:	c9                   	leave  
80105209:	c3                   	ret    

8010520a <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
8010520a:	55                   	push   %ebp
8010520b:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
8010520d:	8b 45 08             	mov    0x8(%ebp),%eax
80105210:	8b 00                	mov    (%eax),%eax
80105212:	85 c0                	test   %eax,%eax
80105214:	74 17                	je     8010522d <holding+0x23>
80105216:	8b 45 08             	mov    0x8(%ebp),%eax
80105219:	8b 50 08             	mov    0x8(%eax),%edx
8010521c:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105222:	39 c2                	cmp    %eax,%edx
80105224:	75 07                	jne    8010522d <holding+0x23>
80105226:	b8 01 00 00 00       	mov    $0x1,%eax
8010522b:	eb 05                	jmp    80105232 <holding+0x28>
8010522d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105232:	5d                   	pop    %ebp
80105233:	c3                   	ret    

80105234 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80105234:	55                   	push   %ebp
80105235:	89 e5                	mov    %esp,%ebp
80105237:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
8010523a:	e8 0d fe ff ff       	call   8010504c <readeflags>
8010523f:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
80105242:	e8 1a fe ff ff       	call   80105061 <cli>
  if(cpu->ncli++ == 0)
80105247:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010524d:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80105253:	85 d2                	test   %edx,%edx
80105255:	0f 94 c1             	sete   %cl
80105258:	83 c2 01             	add    $0x1,%edx
8010525b:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80105261:	84 c9                	test   %cl,%cl
80105263:	74 15                	je     8010527a <pushcli+0x46>
    cpu->intena = eflags & FL_IF;
80105265:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010526b:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010526e:	81 e2 00 02 00 00    	and    $0x200,%edx
80105274:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
8010527a:	c9                   	leave  
8010527b:	c3                   	ret    

8010527c <popcli>:

void
popcli(void)
{
8010527c:	55                   	push   %ebp
8010527d:	89 e5                	mov    %esp,%ebp
8010527f:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
80105282:	e8 c5 fd ff ff       	call   8010504c <readeflags>
80105287:	25 00 02 00 00       	and    $0x200,%eax
8010528c:	85 c0                	test   %eax,%eax
8010528e:	74 0c                	je     8010529c <popcli+0x20>
    panic("popcli - interruptible");
80105290:	c7 04 24 45 8d 10 80 	movl   $0x80108d45,(%esp)
80105297:	e8 a1 b2 ff ff       	call   8010053d <panic>
  if(--cpu->ncli < 0)
8010529c:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801052a2:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
801052a8:	83 ea 01             	sub    $0x1,%edx
801052ab:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
801052b1:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
801052b7:	85 c0                	test   %eax,%eax
801052b9:	79 0c                	jns    801052c7 <popcli+0x4b>
    panic("popcli");
801052bb:	c7 04 24 5c 8d 10 80 	movl   $0x80108d5c,(%esp)
801052c2:	e8 76 b2 ff ff       	call   8010053d <panic>
  if(cpu->ncli == 0 && cpu->intena)
801052c7:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801052cd:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
801052d3:	85 c0                	test   %eax,%eax
801052d5:	75 15                	jne    801052ec <popcli+0x70>
801052d7:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801052dd:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
801052e3:	85 c0                	test   %eax,%eax
801052e5:	74 05                	je     801052ec <popcli+0x70>
    sti();
801052e7:	e8 7b fd ff ff       	call   80105067 <sti>
}
801052ec:	c9                   	leave  
801052ed:	c3                   	ret    
	...

801052f0 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
801052f0:	55                   	push   %ebp
801052f1:	89 e5                	mov    %esp,%ebp
801052f3:	57                   	push   %edi
801052f4:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
801052f5:	8b 4d 08             	mov    0x8(%ebp),%ecx
801052f8:	8b 55 10             	mov    0x10(%ebp),%edx
801052fb:	8b 45 0c             	mov    0xc(%ebp),%eax
801052fe:	89 cb                	mov    %ecx,%ebx
80105300:	89 df                	mov    %ebx,%edi
80105302:	89 d1                	mov    %edx,%ecx
80105304:	fc                   	cld    
80105305:	f3 aa                	rep stos %al,%es:(%edi)
80105307:	89 ca                	mov    %ecx,%edx
80105309:	89 fb                	mov    %edi,%ebx
8010530b:	89 5d 08             	mov    %ebx,0x8(%ebp)
8010530e:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105311:	5b                   	pop    %ebx
80105312:	5f                   	pop    %edi
80105313:	5d                   	pop    %ebp
80105314:	c3                   	ret    

80105315 <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
80105315:	55                   	push   %ebp
80105316:	89 e5                	mov    %esp,%ebp
80105318:	57                   	push   %edi
80105319:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
8010531a:	8b 4d 08             	mov    0x8(%ebp),%ecx
8010531d:	8b 55 10             	mov    0x10(%ebp),%edx
80105320:	8b 45 0c             	mov    0xc(%ebp),%eax
80105323:	89 cb                	mov    %ecx,%ebx
80105325:	89 df                	mov    %ebx,%edi
80105327:	89 d1                	mov    %edx,%ecx
80105329:	fc                   	cld    
8010532a:	f3 ab                	rep stos %eax,%es:(%edi)
8010532c:	89 ca                	mov    %ecx,%edx
8010532e:	89 fb                	mov    %edi,%ebx
80105330:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105333:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105336:	5b                   	pop    %ebx
80105337:	5f                   	pop    %edi
80105338:	5d                   	pop    %ebp
80105339:	c3                   	ret    

8010533a <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
8010533a:	55                   	push   %ebp
8010533b:	89 e5                	mov    %esp,%ebp
8010533d:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
80105340:	8b 45 08             	mov    0x8(%ebp),%eax
80105343:	83 e0 03             	and    $0x3,%eax
80105346:	85 c0                	test   %eax,%eax
80105348:	75 49                	jne    80105393 <memset+0x59>
8010534a:	8b 45 10             	mov    0x10(%ebp),%eax
8010534d:	83 e0 03             	and    $0x3,%eax
80105350:	85 c0                	test   %eax,%eax
80105352:	75 3f                	jne    80105393 <memset+0x59>
    c &= 0xFF;
80105354:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
8010535b:	8b 45 10             	mov    0x10(%ebp),%eax
8010535e:	c1 e8 02             	shr    $0x2,%eax
80105361:	89 c2                	mov    %eax,%edx
80105363:	8b 45 0c             	mov    0xc(%ebp),%eax
80105366:	89 c1                	mov    %eax,%ecx
80105368:	c1 e1 18             	shl    $0x18,%ecx
8010536b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010536e:	c1 e0 10             	shl    $0x10,%eax
80105371:	09 c1                	or     %eax,%ecx
80105373:	8b 45 0c             	mov    0xc(%ebp),%eax
80105376:	c1 e0 08             	shl    $0x8,%eax
80105379:	09 c8                	or     %ecx,%eax
8010537b:	0b 45 0c             	or     0xc(%ebp),%eax
8010537e:	89 54 24 08          	mov    %edx,0x8(%esp)
80105382:	89 44 24 04          	mov    %eax,0x4(%esp)
80105386:	8b 45 08             	mov    0x8(%ebp),%eax
80105389:	89 04 24             	mov    %eax,(%esp)
8010538c:	e8 84 ff ff ff       	call   80105315 <stosl>
80105391:	eb 19                	jmp    801053ac <memset+0x72>
  } else
    stosb(dst, c, n);
80105393:	8b 45 10             	mov    0x10(%ebp),%eax
80105396:	89 44 24 08          	mov    %eax,0x8(%esp)
8010539a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010539d:	89 44 24 04          	mov    %eax,0x4(%esp)
801053a1:	8b 45 08             	mov    0x8(%ebp),%eax
801053a4:	89 04 24             	mov    %eax,(%esp)
801053a7:	e8 44 ff ff ff       	call   801052f0 <stosb>
  return dst;
801053ac:	8b 45 08             	mov    0x8(%ebp),%eax
}
801053af:	c9                   	leave  
801053b0:	c3                   	ret    

801053b1 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
801053b1:	55                   	push   %ebp
801053b2:	89 e5                	mov    %esp,%ebp
801053b4:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
801053b7:	8b 45 08             	mov    0x8(%ebp),%eax
801053ba:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
801053bd:	8b 45 0c             	mov    0xc(%ebp),%eax
801053c0:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
801053c3:	eb 32                	jmp    801053f7 <memcmp+0x46>
    if(*s1 != *s2)
801053c5:	8b 45 fc             	mov    -0x4(%ebp),%eax
801053c8:	0f b6 10             	movzbl (%eax),%edx
801053cb:	8b 45 f8             	mov    -0x8(%ebp),%eax
801053ce:	0f b6 00             	movzbl (%eax),%eax
801053d1:	38 c2                	cmp    %al,%dl
801053d3:	74 1a                	je     801053ef <memcmp+0x3e>
      return *s1 - *s2;
801053d5:	8b 45 fc             	mov    -0x4(%ebp),%eax
801053d8:	0f b6 00             	movzbl (%eax),%eax
801053db:	0f b6 d0             	movzbl %al,%edx
801053de:	8b 45 f8             	mov    -0x8(%ebp),%eax
801053e1:	0f b6 00             	movzbl (%eax),%eax
801053e4:	0f b6 c0             	movzbl %al,%eax
801053e7:	89 d1                	mov    %edx,%ecx
801053e9:	29 c1                	sub    %eax,%ecx
801053eb:	89 c8                	mov    %ecx,%eax
801053ed:	eb 1c                	jmp    8010540b <memcmp+0x5a>
    s1++, s2++;
801053ef:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801053f3:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
801053f7:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801053fb:	0f 95 c0             	setne  %al
801053fe:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105402:	84 c0                	test   %al,%al
80105404:	75 bf                	jne    801053c5 <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
80105406:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010540b:	c9                   	leave  
8010540c:	c3                   	ret    

8010540d <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
8010540d:	55                   	push   %ebp
8010540e:	89 e5                	mov    %esp,%ebp
80105410:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
80105413:	8b 45 0c             	mov    0xc(%ebp),%eax
80105416:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
80105419:	8b 45 08             	mov    0x8(%ebp),%eax
8010541c:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
8010541f:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105422:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105425:	73 54                	jae    8010547b <memmove+0x6e>
80105427:	8b 45 10             	mov    0x10(%ebp),%eax
8010542a:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010542d:	01 d0                	add    %edx,%eax
8010542f:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105432:	76 47                	jbe    8010547b <memmove+0x6e>
    s += n;
80105434:	8b 45 10             	mov    0x10(%ebp),%eax
80105437:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
8010543a:	8b 45 10             	mov    0x10(%ebp),%eax
8010543d:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
80105440:	eb 13                	jmp    80105455 <memmove+0x48>
      *--d = *--s;
80105442:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
80105446:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
8010544a:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010544d:	0f b6 10             	movzbl (%eax),%edx
80105450:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105453:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
80105455:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105459:	0f 95 c0             	setne  %al
8010545c:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105460:	84 c0                	test   %al,%al
80105462:	75 de                	jne    80105442 <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80105464:	eb 25                	jmp    8010548b <memmove+0x7e>
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
      *d++ = *s++;
80105466:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105469:	0f b6 10             	movzbl (%eax),%edx
8010546c:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010546f:	88 10                	mov    %dl,(%eax)
80105471:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105475:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105479:	eb 01                	jmp    8010547c <memmove+0x6f>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
8010547b:	90                   	nop
8010547c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105480:	0f 95 c0             	setne  %al
80105483:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105487:	84 c0                	test   %al,%al
80105489:	75 db                	jne    80105466 <memmove+0x59>
      *d++ = *s++;

  return dst;
8010548b:	8b 45 08             	mov    0x8(%ebp),%eax
}
8010548e:	c9                   	leave  
8010548f:	c3                   	ret    

80105490 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80105490:	55                   	push   %ebp
80105491:	89 e5                	mov    %esp,%ebp
80105493:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
80105496:	8b 45 10             	mov    0x10(%ebp),%eax
80105499:	89 44 24 08          	mov    %eax,0x8(%esp)
8010549d:	8b 45 0c             	mov    0xc(%ebp),%eax
801054a0:	89 44 24 04          	mov    %eax,0x4(%esp)
801054a4:	8b 45 08             	mov    0x8(%ebp),%eax
801054a7:	89 04 24             	mov    %eax,(%esp)
801054aa:	e8 5e ff ff ff       	call   8010540d <memmove>
}
801054af:	c9                   	leave  
801054b0:	c3                   	ret    

801054b1 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
801054b1:	55                   	push   %ebp
801054b2:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
801054b4:	eb 0c                	jmp    801054c2 <strncmp+0x11>
    n--, p++, q++;
801054b6:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801054ba:	83 45 08 01          	addl   $0x1,0x8(%ebp)
801054be:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
801054c2:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801054c6:	74 1a                	je     801054e2 <strncmp+0x31>
801054c8:	8b 45 08             	mov    0x8(%ebp),%eax
801054cb:	0f b6 00             	movzbl (%eax),%eax
801054ce:	84 c0                	test   %al,%al
801054d0:	74 10                	je     801054e2 <strncmp+0x31>
801054d2:	8b 45 08             	mov    0x8(%ebp),%eax
801054d5:	0f b6 10             	movzbl (%eax),%edx
801054d8:	8b 45 0c             	mov    0xc(%ebp),%eax
801054db:	0f b6 00             	movzbl (%eax),%eax
801054de:	38 c2                	cmp    %al,%dl
801054e0:	74 d4                	je     801054b6 <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
801054e2:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801054e6:	75 07                	jne    801054ef <strncmp+0x3e>
    return 0;
801054e8:	b8 00 00 00 00       	mov    $0x0,%eax
801054ed:	eb 18                	jmp    80105507 <strncmp+0x56>
  return (uchar)*p - (uchar)*q;
801054ef:	8b 45 08             	mov    0x8(%ebp),%eax
801054f2:	0f b6 00             	movzbl (%eax),%eax
801054f5:	0f b6 d0             	movzbl %al,%edx
801054f8:	8b 45 0c             	mov    0xc(%ebp),%eax
801054fb:	0f b6 00             	movzbl (%eax),%eax
801054fe:	0f b6 c0             	movzbl %al,%eax
80105501:	89 d1                	mov    %edx,%ecx
80105503:	29 c1                	sub    %eax,%ecx
80105505:	89 c8                	mov    %ecx,%eax
}
80105507:	5d                   	pop    %ebp
80105508:	c3                   	ret    

80105509 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80105509:	55                   	push   %ebp
8010550a:	89 e5                	mov    %esp,%ebp
8010550c:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
8010550f:	8b 45 08             	mov    0x8(%ebp),%eax
80105512:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
80105515:	90                   	nop
80105516:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010551a:	0f 9f c0             	setg   %al
8010551d:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105521:	84 c0                	test   %al,%al
80105523:	74 30                	je     80105555 <strncpy+0x4c>
80105525:	8b 45 0c             	mov    0xc(%ebp),%eax
80105528:	0f b6 10             	movzbl (%eax),%edx
8010552b:	8b 45 08             	mov    0x8(%ebp),%eax
8010552e:	88 10                	mov    %dl,(%eax)
80105530:	8b 45 08             	mov    0x8(%ebp),%eax
80105533:	0f b6 00             	movzbl (%eax),%eax
80105536:	84 c0                	test   %al,%al
80105538:	0f 95 c0             	setne  %al
8010553b:	83 45 08 01          	addl   $0x1,0x8(%ebp)
8010553f:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
80105543:	84 c0                	test   %al,%al
80105545:	75 cf                	jne    80105516 <strncpy+0xd>
    ;
  while(n-- > 0)
80105547:	eb 0c                	jmp    80105555 <strncpy+0x4c>
    *s++ = 0;
80105549:	8b 45 08             	mov    0x8(%ebp),%eax
8010554c:	c6 00 00             	movb   $0x0,(%eax)
8010554f:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105553:	eb 01                	jmp    80105556 <strncpy+0x4d>
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
80105555:	90                   	nop
80105556:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010555a:	0f 9f c0             	setg   %al
8010555d:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105561:	84 c0                	test   %al,%al
80105563:	75 e4                	jne    80105549 <strncpy+0x40>
    *s++ = 0;
  return os;
80105565:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105568:	c9                   	leave  
80105569:	c3                   	ret    

8010556a <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
8010556a:	55                   	push   %ebp
8010556b:	89 e5                	mov    %esp,%ebp
8010556d:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105570:	8b 45 08             	mov    0x8(%ebp),%eax
80105573:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
80105576:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010557a:	7f 05                	jg     80105581 <safestrcpy+0x17>
    return os;
8010557c:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010557f:	eb 35                	jmp    801055b6 <safestrcpy+0x4c>
  while(--n > 0 && (*s++ = *t++) != 0)
80105581:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105585:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105589:	7e 22                	jle    801055ad <safestrcpy+0x43>
8010558b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010558e:	0f b6 10             	movzbl (%eax),%edx
80105591:	8b 45 08             	mov    0x8(%ebp),%eax
80105594:	88 10                	mov    %dl,(%eax)
80105596:	8b 45 08             	mov    0x8(%ebp),%eax
80105599:	0f b6 00             	movzbl (%eax),%eax
8010559c:	84 c0                	test   %al,%al
8010559e:	0f 95 c0             	setne  %al
801055a1:	83 45 08 01          	addl   $0x1,0x8(%ebp)
801055a5:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
801055a9:	84 c0                	test   %al,%al
801055ab:	75 d4                	jne    80105581 <safestrcpy+0x17>
    ;
  *s = 0;
801055ad:	8b 45 08             	mov    0x8(%ebp),%eax
801055b0:	c6 00 00             	movb   $0x0,(%eax)
  return os;
801055b3:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801055b6:	c9                   	leave  
801055b7:	c3                   	ret    

801055b8 <strlen>:

int
strlen(const char *s)
{
801055b8:	55                   	push   %ebp
801055b9:	89 e5                	mov    %esp,%ebp
801055bb:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
801055be:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801055c5:	eb 04                	jmp    801055cb <strlen+0x13>
801055c7:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801055cb:	8b 45 fc             	mov    -0x4(%ebp),%eax
801055ce:	03 45 08             	add    0x8(%ebp),%eax
801055d1:	0f b6 00             	movzbl (%eax),%eax
801055d4:	84 c0                	test   %al,%al
801055d6:	75 ef                	jne    801055c7 <strlen+0xf>
    ;
  return n;
801055d8:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801055db:	c9                   	leave  
801055dc:	c3                   	ret    
801055dd:	00 00                	add    %al,(%eax)
	...

801055e0 <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
801055e0:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
801055e4:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
801055e8:	55                   	push   %ebp
  pushl %ebx
801055e9:	53                   	push   %ebx
  pushl %esi
801055ea:	56                   	push   %esi
  pushl %edi
801055eb:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
801055ec:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
801055ee:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
801055f0:	5f                   	pop    %edi
  popl %esi
801055f1:	5e                   	pop    %esi
  popl %ebx
801055f2:	5b                   	pop    %ebx
  popl %ebp
801055f3:	5d                   	pop    %ebp
  ret
801055f4:	c3                   	ret    
801055f5:	00 00                	add    %al,(%eax)
	...

801055f8 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from process p.
int
fetchint(struct proc *p, uint addr, int *ip)
{
801055f8:	55                   	push   %ebp
801055f9:	89 e5                	mov    %esp,%ebp
  if(addr >= p->sz || addr+4 > p->sz)
801055fb:	8b 45 08             	mov    0x8(%ebp),%eax
801055fe:	8b 00                	mov    (%eax),%eax
80105600:	3b 45 0c             	cmp    0xc(%ebp),%eax
80105603:	76 0f                	jbe    80105614 <fetchint+0x1c>
80105605:	8b 45 0c             	mov    0xc(%ebp),%eax
80105608:	8d 50 04             	lea    0x4(%eax),%edx
8010560b:	8b 45 08             	mov    0x8(%ebp),%eax
8010560e:	8b 00                	mov    (%eax),%eax
80105610:	39 c2                	cmp    %eax,%edx
80105612:	76 07                	jbe    8010561b <fetchint+0x23>
    return -1;
80105614:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105619:	eb 0f                	jmp    8010562a <fetchint+0x32>
  *ip = *(int*)(addr);
8010561b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010561e:	8b 10                	mov    (%eax),%edx
80105620:	8b 45 10             	mov    0x10(%ebp),%eax
80105623:	89 10                	mov    %edx,(%eax)
  return 0;
80105625:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010562a:	5d                   	pop    %ebp
8010562b:	c3                   	ret    

8010562c <fetchstr>:
// Fetch the nul-terminated string at addr from process p.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(struct proc *p, uint addr, char **pp)
{
8010562c:	55                   	push   %ebp
8010562d:	89 e5                	mov    %esp,%ebp
8010562f:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= p->sz)
80105632:	8b 45 08             	mov    0x8(%ebp),%eax
80105635:	8b 00                	mov    (%eax),%eax
80105637:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010563a:	77 07                	ja     80105643 <fetchstr+0x17>
    return -1;
8010563c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105641:	eb 45                	jmp    80105688 <fetchstr+0x5c>
  *pp = (char*)addr;
80105643:	8b 55 0c             	mov    0xc(%ebp),%edx
80105646:	8b 45 10             	mov    0x10(%ebp),%eax
80105649:	89 10                	mov    %edx,(%eax)
  ep = (char*)p->sz;
8010564b:	8b 45 08             	mov    0x8(%ebp),%eax
8010564e:	8b 00                	mov    (%eax),%eax
80105650:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
80105653:	8b 45 10             	mov    0x10(%ebp),%eax
80105656:	8b 00                	mov    (%eax),%eax
80105658:	89 45 fc             	mov    %eax,-0x4(%ebp)
8010565b:	eb 1e                	jmp    8010567b <fetchstr+0x4f>
    if(*s == 0)
8010565d:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105660:	0f b6 00             	movzbl (%eax),%eax
80105663:	84 c0                	test   %al,%al
80105665:	75 10                	jne    80105677 <fetchstr+0x4b>
      return s - *pp;
80105667:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010566a:	8b 45 10             	mov    0x10(%ebp),%eax
8010566d:	8b 00                	mov    (%eax),%eax
8010566f:	89 d1                	mov    %edx,%ecx
80105671:	29 c1                	sub    %eax,%ecx
80105673:	89 c8                	mov    %ecx,%eax
80105675:	eb 11                	jmp    80105688 <fetchstr+0x5c>

  if(addr >= p->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)p->sz;
  for(s = *pp; s < ep; s++)
80105677:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010567b:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010567e:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105681:	72 da                	jb     8010565d <fetchstr+0x31>
    if(*s == 0)
      return s - *pp;
  return -1;
80105683:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105688:	c9                   	leave  
80105689:	c3                   	ret    

8010568a <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
8010568a:	55                   	push   %ebp
8010568b:	89 e5                	mov    %esp,%ebp
8010568d:	83 ec 0c             	sub    $0xc,%esp
  return fetchint(proc, proc->tf->esp + 4 + 4*n, ip);
80105690:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105696:	8b 40 18             	mov    0x18(%eax),%eax
80105699:	8b 50 44             	mov    0x44(%eax),%edx
8010569c:	8b 45 08             	mov    0x8(%ebp),%eax
8010569f:	c1 e0 02             	shl    $0x2,%eax
801056a2:	01 d0                	add    %edx,%eax
801056a4:	8d 48 04             	lea    0x4(%eax),%ecx
801056a7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801056ad:	8b 55 0c             	mov    0xc(%ebp),%edx
801056b0:	89 54 24 08          	mov    %edx,0x8(%esp)
801056b4:	89 4c 24 04          	mov    %ecx,0x4(%esp)
801056b8:	89 04 24             	mov    %eax,(%esp)
801056bb:	e8 38 ff ff ff       	call   801055f8 <fetchint>
}
801056c0:	c9                   	leave  
801056c1:	c3                   	ret    

801056c2 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
801056c2:	55                   	push   %ebp
801056c3:	89 e5                	mov    %esp,%ebp
801056c5:	83 ec 18             	sub    $0x18,%esp
  int i;
  
  if(argint(n, &i) < 0)
801056c8:	8d 45 fc             	lea    -0x4(%ebp),%eax
801056cb:	89 44 24 04          	mov    %eax,0x4(%esp)
801056cf:	8b 45 08             	mov    0x8(%ebp),%eax
801056d2:	89 04 24             	mov    %eax,(%esp)
801056d5:	e8 b0 ff ff ff       	call   8010568a <argint>
801056da:	85 c0                	test   %eax,%eax
801056dc:	79 07                	jns    801056e5 <argptr+0x23>
    return -1;
801056de:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801056e3:	eb 3d                	jmp    80105722 <argptr+0x60>
  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
801056e5:	8b 45 fc             	mov    -0x4(%ebp),%eax
801056e8:	89 c2                	mov    %eax,%edx
801056ea:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801056f0:	8b 00                	mov    (%eax),%eax
801056f2:	39 c2                	cmp    %eax,%edx
801056f4:	73 16                	jae    8010570c <argptr+0x4a>
801056f6:	8b 45 fc             	mov    -0x4(%ebp),%eax
801056f9:	89 c2                	mov    %eax,%edx
801056fb:	8b 45 10             	mov    0x10(%ebp),%eax
801056fe:	01 c2                	add    %eax,%edx
80105700:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105706:	8b 00                	mov    (%eax),%eax
80105708:	39 c2                	cmp    %eax,%edx
8010570a:	76 07                	jbe    80105713 <argptr+0x51>
    return -1;
8010570c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105711:	eb 0f                	jmp    80105722 <argptr+0x60>
  *pp = (char*)i;
80105713:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105716:	89 c2                	mov    %eax,%edx
80105718:	8b 45 0c             	mov    0xc(%ebp),%eax
8010571b:	89 10                	mov    %edx,(%eax)
  return 0;
8010571d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105722:	c9                   	leave  
80105723:	c3                   	ret    

80105724 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80105724:	55                   	push   %ebp
80105725:	89 e5                	mov    %esp,%ebp
80105727:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  if(argint(n, &addr) < 0)
8010572a:	8d 45 fc             	lea    -0x4(%ebp),%eax
8010572d:	89 44 24 04          	mov    %eax,0x4(%esp)
80105731:	8b 45 08             	mov    0x8(%ebp),%eax
80105734:	89 04 24             	mov    %eax,(%esp)
80105737:	e8 4e ff ff ff       	call   8010568a <argint>
8010573c:	85 c0                	test   %eax,%eax
8010573e:	79 07                	jns    80105747 <argstr+0x23>
    return -1;
80105740:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105745:	eb 1e                	jmp    80105765 <argstr+0x41>
  return fetchstr(proc, addr, pp);
80105747:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010574a:	89 c2                	mov    %eax,%edx
8010574c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105752:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80105755:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105759:	89 54 24 04          	mov    %edx,0x4(%esp)
8010575d:	89 04 24             	mov    %eax,(%esp)
80105760:	e8 c7 fe ff ff       	call   8010562c <fetchstr>
}
80105765:	c9                   	leave  
80105766:	c3                   	ret    

80105767 <syscall>:
[SYS_disableSwapping]	sys_disableSwapping,
};

void
syscall(void)
{
80105767:	55                   	push   %ebp
80105768:	89 e5                	mov    %esp,%ebp
8010576a:	53                   	push   %ebx
8010576b:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->tf->eax;
8010576e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105774:	8b 40 18             	mov    0x18(%eax),%eax
80105777:	8b 40 1c             	mov    0x1c(%eax),%eax
8010577a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num >= 0 && num < SYS_open && syscalls[num]) {
8010577d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105781:	78 2e                	js     801057b1 <syscall+0x4a>
80105783:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
80105787:	7f 28                	jg     801057b1 <syscall+0x4a>
80105789:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010578c:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
80105793:	85 c0                	test   %eax,%eax
80105795:	74 1a                	je     801057b1 <syscall+0x4a>
    proc->tf->eax = syscalls[num]();
80105797:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010579d:	8b 58 18             	mov    0x18(%eax),%ebx
801057a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057a3:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
801057aa:	ff d0                	call   *%eax
801057ac:	89 43 1c             	mov    %eax,0x1c(%ebx)
801057af:	eb 73                	jmp    80105824 <syscall+0xbd>
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
801057b1:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
801057b5:	7e 30                	jle    801057e7 <syscall+0x80>
801057b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057ba:	83 f8 17             	cmp    $0x17,%eax
801057bd:	77 28                	ja     801057e7 <syscall+0x80>
801057bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057c2:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
801057c9:	85 c0                	test   %eax,%eax
801057cb:	74 1a                	je     801057e7 <syscall+0x80>
    proc->tf->eax = syscalls[num]();
801057cd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801057d3:	8b 58 18             	mov    0x18(%eax),%ebx
801057d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057d9:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
801057e0:	ff d0                	call   *%eax
801057e2:	89 43 1c             	mov    %eax,0x1c(%ebx)
801057e5:	eb 3d                	jmp    80105824 <syscall+0xbd>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
801057e7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801057ed:	8d 48 6c             	lea    0x6c(%eax),%ecx
801057f0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  if(num >= 0 && num < SYS_open && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
801057f6:	8b 40 10             	mov    0x10(%eax),%eax
801057f9:	8b 55 f4             	mov    -0xc(%ebp),%edx
801057fc:	89 54 24 0c          	mov    %edx,0xc(%esp)
80105800:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105804:	89 44 24 04          	mov    %eax,0x4(%esp)
80105808:	c7 04 24 63 8d 10 80 	movl   $0x80108d63,(%esp)
8010580f:	e8 8d ab ff ff       	call   801003a1 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
80105814:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010581a:	8b 40 18             	mov    0x18(%eax),%eax
8010581d:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
80105824:	83 c4 24             	add    $0x24,%esp
80105827:	5b                   	pop    %ebx
80105828:	5d                   	pop    %ebp
80105829:	c3                   	ret    
	...

8010582c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
8010582c:	55                   	push   %ebp
8010582d:	89 e5                	mov    %esp,%ebp
8010582f:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
80105832:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105835:	89 44 24 04          	mov    %eax,0x4(%esp)
80105839:	8b 45 08             	mov    0x8(%ebp),%eax
8010583c:	89 04 24             	mov    %eax,(%esp)
8010583f:	e8 46 fe ff ff       	call   8010568a <argint>
80105844:	85 c0                	test   %eax,%eax
80105846:	79 07                	jns    8010584f <argfd+0x23>
    return -1;
80105848:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010584d:	eb 50                	jmp    8010589f <argfd+0x73>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
8010584f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105852:	85 c0                	test   %eax,%eax
80105854:	78 21                	js     80105877 <argfd+0x4b>
80105856:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105859:	83 f8 0f             	cmp    $0xf,%eax
8010585c:	7f 19                	jg     80105877 <argfd+0x4b>
8010585e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105864:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105867:	83 c2 08             	add    $0x8,%edx
8010586a:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010586e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105871:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105875:	75 07                	jne    8010587e <argfd+0x52>
    return -1;
80105877:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010587c:	eb 21                	jmp    8010589f <argfd+0x73>
  if(pfd)
8010587e:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80105882:	74 08                	je     8010588c <argfd+0x60>
    *pfd = fd;
80105884:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105887:	8b 45 0c             	mov    0xc(%ebp),%eax
8010588a:	89 10                	mov    %edx,(%eax)
  if(pf)
8010588c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105890:	74 08                	je     8010589a <argfd+0x6e>
    *pf = f;
80105892:	8b 45 10             	mov    0x10(%ebp),%eax
80105895:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105898:	89 10                	mov    %edx,(%eax)
  return 0;
8010589a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010589f:	c9                   	leave  
801058a0:	c3                   	ret    

801058a1 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
801058a1:	55                   	push   %ebp
801058a2:	89 e5                	mov    %esp,%ebp
801058a4:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
801058a7:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801058ae:	eb 30                	jmp    801058e0 <fdalloc+0x3f>
    if(proc->ofile[fd] == 0){
801058b0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801058b6:	8b 55 fc             	mov    -0x4(%ebp),%edx
801058b9:	83 c2 08             	add    $0x8,%edx
801058bc:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801058c0:	85 c0                	test   %eax,%eax
801058c2:	75 18                	jne    801058dc <fdalloc+0x3b>
      proc->ofile[fd] = f;
801058c4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801058ca:	8b 55 fc             	mov    -0x4(%ebp),%edx
801058cd:	8d 4a 08             	lea    0x8(%edx),%ecx
801058d0:	8b 55 08             	mov    0x8(%ebp),%edx
801058d3:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
801058d7:	8b 45 fc             	mov    -0x4(%ebp),%eax
801058da:	eb 0f                	jmp    801058eb <fdalloc+0x4a>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
801058dc:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801058e0:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
801058e4:	7e ca                	jle    801058b0 <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
801058e6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801058eb:	c9                   	leave  
801058ec:	c3                   	ret    

801058ed <sys_dup>:

int
sys_dup(void)
{
801058ed:	55                   	push   %ebp
801058ee:	89 e5                	mov    %esp,%ebp
801058f0:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
801058f3:	8d 45 f0             	lea    -0x10(%ebp),%eax
801058f6:	89 44 24 08          	mov    %eax,0x8(%esp)
801058fa:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105901:	00 
80105902:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105909:	e8 1e ff ff ff       	call   8010582c <argfd>
8010590e:	85 c0                	test   %eax,%eax
80105910:	79 07                	jns    80105919 <sys_dup+0x2c>
    return -1;
80105912:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105917:	eb 29                	jmp    80105942 <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
80105919:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010591c:	89 04 24             	mov    %eax,(%esp)
8010591f:	e8 7d ff ff ff       	call   801058a1 <fdalloc>
80105924:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105927:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010592b:	79 07                	jns    80105934 <sys_dup+0x47>
    return -1;
8010592d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105932:	eb 0e                	jmp    80105942 <sys_dup+0x55>
  filedup(f);
80105934:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105937:	89 04 24             	mov    %eax,(%esp)
8010593a:	e8 3d b6 ff ff       	call   80100f7c <filedup>
  return fd;
8010593f:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80105942:	c9                   	leave  
80105943:	c3                   	ret    

80105944 <sys_read>:

int
sys_read(void)
{
80105944:	55                   	push   %ebp
80105945:	89 e5                	mov    %esp,%ebp
80105947:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
8010594a:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010594d:	89 44 24 08          	mov    %eax,0x8(%esp)
80105951:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105958:	00 
80105959:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105960:	e8 c7 fe ff ff       	call   8010582c <argfd>
80105965:	85 c0                	test   %eax,%eax
80105967:	78 35                	js     8010599e <sys_read+0x5a>
80105969:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010596c:	89 44 24 04          	mov    %eax,0x4(%esp)
80105970:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80105977:	e8 0e fd ff ff       	call   8010568a <argint>
8010597c:	85 c0                	test   %eax,%eax
8010597e:	78 1e                	js     8010599e <sys_read+0x5a>
80105980:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105983:	89 44 24 08          	mov    %eax,0x8(%esp)
80105987:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010598a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010598e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105995:	e8 28 fd ff ff       	call   801056c2 <argptr>
8010599a:	85 c0                	test   %eax,%eax
8010599c:	79 07                	jns    801059a5 <sys_read+0x61>
    return -1;
8010599e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801059a3:	eb 19                	jmp    801059be <sys_read+0x7a>
  return fileread(f, p, n);
801059a5:	8b 4d f0             	mov    -0x10(%ebp),%ecx
801059a8:	8b 55 ec             	mov    -0x14(%ebp),%edx
801059ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059ae:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801059b2:	89 54 24 04          	mov    %edx,0x4(%esp)
801059b6:	89 04 24             	mov    %eax,(%esp)
801059b9:	e8 2b b7 ff ff       	call   801010e9 <fileread>
}
801059be:	c9                   	leave  
801059bf:	c3                   	ret    

801059c0 <sys_write>:

int
sys_write(void)
{
801059c0:	55                   	push   %ebp
801059c1:	89 e5                	mov    %esp,%ebp
801059c3:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801059c6:	8d 45 f4             	lea    -0xc(%ebp),%eax
801059c9:	89 44 24 08          	mov    %eax,0x8(%esp)
801059cd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801059d4:	00 
801059d5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801059dc:	e8 4b fe ff ff       	call   8010582c <argfd>
801059e1:	85 c0                	test   %eax,%eax
801059e3:	78 35                	js     80105a1a <sys_write+0x5a>
801059e5:	8d 45 f0             	lea    -0x10(%ebp),%eax
801059e8:	89 44 24 04          	mov    %eax,0x4(%esp)
801059ec:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801059f3:	e8 92 fc ff ff       	call   8010568a <argint>
801059f8:	85 c0                	test   %eax,%eax
801059fa:	78 1e                	js     80105a1a <sys_write+0x5a>
801059fc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801059ff:	89 44 24 08          	mov    %eax,0x8(%esp)
80105a03:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105a06:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a0a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105a11:	e8 ac fc ff ff       	call   801056c2 <argptr>
80105a16:	85 c0                	test   %eax,%eax
80105a18:	79 07                	jns    80105a21 <sys_write+0x61>
    return -1;
80105a1a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105a1f:	eb 19                	jmp    80105a3a <sys_write+0x7a>
  return filewrite(f, p, n);
80105a21:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80105a24:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105a27:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a2a:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105a2e:	89 54 24 04          	mov    %edx,0x4(%esp)
80105a32:	89 04 24             	mov    %eax,(%esp)
80105a35:	e8 6b b7 ff ff       	call   801011a5 <filewrite>
}
80105a3a:	c9                   	leave  
80105a3b:	c3                   	ret    

80105a3c <sys_close>:

int
sys_close(void)
{
80105a3c:	55                   	push   %ebp
80105a3d:	89 e5                	mov    %esp,%ebp
80105a3f:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
80105a42:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105a45:	89 44 24 08          	mov    %eax,0x8(%esp)
80105a49:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105a4c:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a50:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105a57:	e8 d0 fd ff ff       	call   8010582c <argfd>
80105a5c:	85 c0                	test   %eax,%eax
80105a5e:	79 07                	jns    80105a67 <sys_close+0x2b>
    return -1;
80105a60:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105a65:	eb 24                	jmp    80105a8b <sys_close+0x4f>
  proc->ofile[fd] = 0;
80105a67:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105a6d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105a70:	83 c2 08             	add    $0x8,%edx
80105a73:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80105a7a:	00 
  fileclose(f);
80105a7b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a7e:	89 04 24             	mov    %eax,(%esp)
80105a81:	e8 3e b5 ff ff       	call   80100fc4 <fileclose>
  return 0;
80105a86:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105a8b:	c9                   	leave  
80105a8c:	c3                   	ret    

80105a8d <sys_fstat>:

int
sys_fstat(void)
{
80105a8d:	55                   	push   %ebp
80105a8e:	89 e5                	mov    %esp,%ebp
80105a90:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
80105a93:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105a96:	89 44 24 08          	mov    %eax,0x8(%esp)
80105a9a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105aa1:	00 
80105aa2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105aa9:	e8 7e fd ff ff       	call   8010582c <argfd>
80105aae:	85 c0                	test   %eax,%eax
80105ab0:	78 1f                	js     80105ad1 <sys_fstat+0x44>
80105ab2:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80105ab9:	00 
80105aba:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105abd:	89 44 24 04          	mov    %eax,0x4(%esp)
80105ac1:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105ac8:	e8 f5 fb ff ff       	call   801056c2 <argptr>
80105acd:	85 c0                	test   %eax,%eax
80105acf:	79 07                	jns    80105ad8 <sys_fstat+0x4b>
    return -1;
80105ad1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105ad6:	eb 12                	jmp    80105aea <sys_fstat+0x5d>
  return filestat(f, st);
80105ad8:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105adb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ade:	89 54 24 04          	mov    %edx,0x4(%esp)
80105ae2:	89 04 24             	mov    %eax,(%esp)
80105ae5:	e8 b0 b5 ff ff       	call   8010109a <filestat>
}
80105aea:	c9                   	leave  
80105aeb:	c3                   	ret    

80105aec <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
80105aec:	55                   	push   %ebp
80105aed:	89 e5                	mov    %esp,%ebp
80105aef:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
80105af2:	8d 45 d8             	lea    -0x28(%ebp),%eax
80105af5:	89 44 24 04          	mov    %eax,0x4(%esp)
80105af9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105b00:	e8 1f fc ff ff       	call   80105724 <argstr>
80105b05:	85 c0                	test   %eax,%eax
80105b07:	78 17                	js     80105b20 <sys_link+0x34>
80105b09:	8d 45 dc             	lea    -0x24(%ebp),%eax
80105b0c:	89 44 24 04          	mov    %eax,0x4(%esp)
80105b10:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105b17:	e8 08 fc ff ff       	call   80105724 <argstr>
80105b1c:	85 c0                	test   %eax,%eax
80105b1e:	79 0a                	jns    80105b2a <sys_link+0x3e>
    return -1;
80105b20:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105b25:	e9 3c 01 00 00       	jmp    80105c66 <sys_link+0x17a>
  if((ip = namei(old)) == 0)
80105b2a:	8b 45 d8             	mov    -0x28(%ebp),%eax
80105b2d:	89 04 24             	mov    %eax,(%esp)
80105b30:	e8 d5 c8 ff ff       	call   8010240a <namei>
80105b35:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105b38:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105b3c:	75 0a                	jne    80105b48 <sys_link+0x5c>
    return -1;
80105b3e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105b43:	e9 1e 01 00 00       	jmp    80105c66 <sys_link+0x17a>

  begin_trans();
80105b48:	e8 dc d6 ff ff       	call   80103229 <begin_trans>

  ilock(ip);
80105b4d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b50:	89 04 24             	mov    %eax,(%esp)
80105b53:	e8 10 bd ff ff       	call   80101868 <ilock>
  if(ip->type == T_DIR){
80105b58:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b5b:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105b5f:	66 83 f8 01          	cmp    $0x1,%ax
80105b63:	75 1a                	jne    80105b7f <sys_link+0x93>
    iunlockput(ip);
80105b65:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b68:	89 04 24             	mov    %eax,(%esp)
80105b6b:	e8 7c bf ff ff       	call   80101aec <iunlockput>
    commit_trans();
80105b70:	e8 fd d6 ff ff       	call   80103272 <commit_trans>
    return -1;
80105b75:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105b7a:	e9 e7 00 00 00       	jmp    80105c66 <sys_link+0x17a>
  }

  ip->nlink++;
80105b7f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b82:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105b86:	8d 50 01             	lea    0x1(%eax),%edx
80105b89:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b8c:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80105b90:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b93:	89 04 24             	mov    %eax,(%esp)
80105b96:	e8 11 bb ff ff       	call   801016ac <iupdate>
  iunlock(ip);
80105b9b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b9e:	89 04 24             	mov    %eax,(%esp)
80105ba1:	e8 10 be ff ff       	call   801019b6 <iunlock>

  if((dp = nameiparent(new, name)) == 0)
80105ba6:	8b 45 dc             	mov    -0x24(%ebp),%eax
80105ba9:	8d 55 e2             	lea    -0x1e(%ebp),%edx
80105bac:	89 54 24 04          	mov    %edx,0x4(%esp)
80105bb0:	89 04 24             	mov    %eax,(%esp)
80105bb3:	e8 74 c8 ff ff       	call   8010242c <nameiparent>
80105bb8:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105bbb:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105bbf:	74 68                	je     80105c29 <sys_link+0x13d>
    goto bad;
  ilock(dp);
80105bc1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105bc4:	89 04 24             	mov    %eax,(%esp)
80105bc7:	e8 9c bc ff ff       	call   80101868 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
80105bcc:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105bcf:	8b 10                	mov    (%eax),%edx
80105bd1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105bd4:	8b 00                	mov    (%eax),%eax
80105bd6:	39 c2                	cmp    %eax,%edx
80105bd8:	75 20                	jne    80105bfa <sys_link+0x10e>
80105bda:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105bdd:	8b 40 04             	mov    0x4(%eax),%eax
80105be0:	89 44 24 08          	mov    %eax,0x8(%esp)
80105be4:	8d 45 e2             	lea    -0x1e(%ebp),%eax
80105be7:	89 44 24 04          	mov    %eax,0x4(%esp)
80105beb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105bee:	89 04 24             	mov    %eax,(%esp)
80105bf1:	e8 53 c5 ff ff       	call   80102149 <dirlink>
80105bf6:	85 c0                	test   %eax,%eax
80105bf8:	79 0d                	jns    80105c07 <sys_link+0x11b>
    iunlockput(dp);
80105bfa:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105bfd:	89 04 24             	mov    %eax,(%esp)
80105c00:	e8 e7 be ff ff       	call   80101aec <iunlockput>
    goto bad;
80105c05:	eb 23                	jmp    80105c2a <sys_link+0x13e>
  }
  iunlockput(dp);
80105c07:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c0a:	89 04 24             	mov    %eax,(%esp)
80105c0d:	e8 da be ff ff       	call   80101aec <iunlockput>
  iput(ip);
80105c12:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c15:	89 04 24             	mov    %eax,(%esp)
80105c18:	e8 fe bd ff ff       	call   80101a1b <iput>

  commit_trans();
80105c1d:	e8 50 d6 ff ff       	call   80103272 <commit_trans>

  return 0;
80105c22:	b8 00 00 00 00       	mov    $0x0,%eax
80105c27:	eb 3d                	jmp    80105c66 <sys_link+0x17a>
  ip->nlink++;
  iupdate(ip);
  iunlock(ip);

  if((dp = nameiparent(new, name)) == 0)
    goto bad;
80105c29:	90                   	nop
  commit_trans();

  return 0;

bad:
  ilock(ip);
80105c2a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c2d:	89 04 24             	mov    %eax,(%esp)
80105c30:	e8 33 bc ff ff       	call   80101868 <ilock>
  ip->nlink--;
80105c35:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c38:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105c3c:	8d 50 ff             	lea    -0x1(%eax),%edx
80105c3f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c42:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80105c46:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c49:	89 04 24             	mov    %eax,(%esp)
80105c4c:	e8 5b ba ff ff       	call   801016ac <iupdate>
  iunlockput(ip);
80105c51:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c54:	89 04 24             	mov    %eax,(%esp)
80105c57:	e8 90 be ff ff       	call   80101aec <iunlockput>
  commit_trans();
80105c5c:	e8 11 d6 ff ff       	call   80103272 <commit_trans>
  return -1;
80105c61:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105c66:	c9                   	leave  
80105c67:	c3                   	ret    

80105c68 <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
80105c68:	55                   	push   %ebp
80105c69:	89 e5                	mov    %esp,%ebp
80105c6b:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80105c6e:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
80105c75:	eb 4b                	jmp    80105cc2 <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80105c77:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c7a:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80105c81:	00 
80105c82:	89 44 24 08          	mov    %eax,0x8(%esp)
80105c86:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105c89:	89 44 24 04          	mov    %eax,0x4(%esp)
80105c8d:	8b 45 08             	mov    0x8(%ebp),%eax
80105c90:	89 04 24             	mov    %eax,(%esp)
80105c93:	e8 c6 c0 ff ff       	call   80101d5e <readi>
80105c98:	83 f8 10             	cmp    $0x10,%eax
80105c9b:	74 0c                	je     80105ca9 <isdirempty+0x41>
      panic("isdirempty: readi");
80105c9d:	c7 04 24 7f 8d 10 80 	movl   $0x80108d7f,(%esp)
80105ca4:	e8 94 a8 ff ff       	call   8010053d <panic>
    if(de.inum != 0)
80105ca9:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
80105cad:	66 85 c0             	test   %ax,%ax
80105cb0:	74 07                	je     80105cb9 <isdirempty+0x51>
      return 0;
80105cb2:	b8 00 00 00 00       	mov    $0x0,%eax
80105cb7:	eb 1b                	jmp    80105cd4 <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80105cb9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105cbc:	83 c0 10             	add    $0x10,%eax
80105cbf:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105cc2:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105cc5:	8b 45 08             	mov    0x8(%ebp),%eax
80105cc8:	8b 40 18             	mov    0x18(%eax),%eax
80105ccb:	39 c2                	cmp    %eax,%edx
80105ccd:	72 a8                	jb     80105c77 <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
80105ccf:	b8 01 00 00 00       	mov    $0x1,%eax
}
80105cd4:	c9                   	leave  
80105cd5:	c3                   	ret    

80105cd6 <sys_unlink>:

//PAGEBREAK!
int
sys_unlink(void)
{
80105cd6:	55                   	push   %ebp
80105cd7:	89 e5                	mov    %esp,%ebp
80105cd9:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
80105cdc:	8d 45 cc             	lea    -0x34(%ebp),%eax
80105cdf:	89 44 24 04          	mov    %eax,0x4(%esp)
80105ce3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105cea:	e8 35 fa ff ff       	call   80105724 <argstr>
80105cef:	85 c0                	test   %eax,%eax
80105cf1:	79 0a                	jns    80105cfd <sys_unlink+0x27>
    return -1;
80105cf3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105cf8:	e9 aa 01 00 00       	jmp    80105ea7 <sys_unlink+0x1d1>
  if((dp = nameiparent(path, name)) == 0)
80105cfd:	8b 45 cc             	mov    -0x34(%ebp),%eax
80105d00:	8d 55 d2             	lea    -0x2e(%ebp),%edx
80105d03:	89 54 24 04          	mov    %edx,0x4(%esp)
80105d07:	89 04 24             	mov    %eax,(%esp)
80105d0a:	e8 1d c7 ff ff       	call   8010242c <nameiparent>
80105d0f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105d12:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105d16:	75 0a                	jne    80105d22 <sys_unlink+0x4c>
    return -1;
80105d18:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105d1d:	e9 85 01 00 00       	jmp    80105ea7 <sys_unlink+0x1d1>

  begin_trans();
80105d22:	e8 02 d5 ff ff       	call   80103229 <begin_trans>

  ilock(dp);
80105d27:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d2a:	89 04 24             	mov    %eax,(%esp)
80105d2d:	e8 36 bb ff ff       	call   80101868 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80105d32:	c7 44 24 04 91 8d 10 	movl   $0x80108d91,0x4(%esp)
80105d39:	80 
80105d3a:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105d3d:	89 04 24             	mov    %eax,(%esp)
80105d40:	e8 1a c3 ff ff       	call   8010205f <namecmp>
80105d45:	85 c0                	test   %eax,%eax
80105d47:	0f 84 45 01 00 00    	je     80105e92 <sys_unlink+0x1bc>
80105d4d:	c7 44 24 04 93 8d 10 	movl   $0x80108d93,0x4(%esp)
80105d54:	80 
80105d55:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105d58:	89 04 24             	mov    %eax,(%esp)
80105d5b:	e8 ff c2 ff ff       	call   8010205f <namecmp>
80105d60:	85 c0                	test   %eax,%eax
80105d62:	0f 84 2a 01 00 00    	je     80105e92 <sys_unlink+0x1bc>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
80105d68:	8d 45 c8             	lea    -0x38(%ebp),%eax
80105d6b:	89 44 24 08          	mov    %eax,0x8(%esp)
80105d6f:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105d72:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d76:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d79:	89 04 24             	mov    %eax,(%esp)
80105d7c:	e8 00 c3 ff ff       	call   80102081 <dirlookup>
80105d81:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105d84:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105d88:	0f 84 03 01 00 00    	je     80105e91 <sys_unlink+0x1bb>
    goto bad;
  ilock(ip);
80105d8e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d91:	89 04 24             	mov    %eax,(%esp)
80105d94:	e8 cf ba ff ff       	call   80101868 <ilock>

  if(ip->nlink < 1)
80105d99:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d9c:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105da0:	66 85 c0             	test   %ax,%ax
80105da3:	7f 0c                	jg     80105db1 <sys_unlink+0xdb>
    panic("unlink: nlink < 1");
80105da5:	c7 04 24 96 8d 10 80 	movl   $0x80108d96,(%esp)
80105dac:	e8 8c a7 ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80105db1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105db4:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105db8:	66 83 f8 01          	cmp    $0x1,%ax
80105dbc:	75 1f                	jne    80105ddd <sys_unlink+0x107>
80105dbe:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105dc1:	89 04 24             	mov    %eax,(%esp)
80105dc4:	e8 9f fe ff ff       	call   80105c68 <isdirempty>
80105dc9:	85 c0                	test   %eax,%eax
80105dcb:	75 10                	jne    80105ddd <sys_unlink+0x107>
    iunlockput(ip);
80105dcd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105dd0:	89 04 24             	mov    %eax,(%esp)
80105dd3:	e8 14 bd ff ff       	call   80101aec <iunlockput>
    goto bad;
80105dd8:	e9 b5 00 00 00       	jmp    80105e92 <sys_unlink+0x1bc>
  }

  memset(&de, 0, sizeof(de));
80105ddd:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80105de4:	00 
80105de5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105dec:	00 
80105ded:	8d 45 e0             	lea    -0x20(%ebp),%eax
80105df0:	89 04 24             	mov    %eax,(%esp)
80105df3:	e8 42 f5 ff ff       	call   8010533a <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80105df8:	8b 45 c8             	mov    -0x38(%ebp),%eax
80105dfb:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80105e02:	00 
80105e03:	89 44 24 08          	mov    %eax,0x8(%esp)
80105e07:	8d 45 e0             	lea    -0x20(%ebp),%eax
80105e0a:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e0e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e11:	89 04 24             	mov    %eax,(%esp)
80105e14:	e8 b0 c0 ff ff       	call   80101ec9 <writei>
80105e19:	83 f8 10             	cmp    $0x10,%eax
80105e1c:	74 0c                	je     80105e2a <sys_unlink+0x154>
    panic("unlink: writei");
80105e1e:	c7 04 24 a8 8d 10 80 	movl   $0x80108da8,(%esp)
80105e25:	e8 13 a7 ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR){
80105e2a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e2d:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105e31:	66 83 f8 01          	cmp    $0x1,%ax
80105e35:	75 1c                	jne    80105e53 <sys_unlink+0x17d>
    dp->nlink--;
80105e37:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e3a:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105e3e:	8d 50 ff             	lea    -0x1(%eax),%edx
80105e41:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e44:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80105e48:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e4b:	89 04 24             	mov    %eax,(%esp)
80105e4e:	e8 59 b8 ff ff       	call   801016ac <iupdate>
  }
  iunlockput(dp);
80105e53:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e56:	89 04 24             	mov    %eax,(%esp)
80105e59:	e8 8e bc ff ff       	call   80101aec <iunlockput>

  ip->nlink--;
80105e5e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e61:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105e65:	8d 50 ff             	lea    -0x1(%eax),%edx
80105e68:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e6b:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80105e6f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e72:	89 04 24             	mov    %eax,(%esp)
80105e75:	e8 32 b8 ff ff       	call   801016ac <iupdate>
  iunlockput(ip);
80105e7a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e7d:	89 04 24             	mov    %eax,(%esp)
80105e80:	e8 67 bc ff ff       	call   80101aec <iunlockput>

  commit_trans();
80105e85:	e8 e8 d3 ff ff       	call   80103272 <commit_trans>

  return 0;
80105e8a:	b8 00 00 00 00       	mov    $0x0,%eax
80105e8f:	eb 16                	jmp    80105ea7 <sys_unlink+0x1d1>
  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    goto bad;
80105e91:	90                   	nop
  commit_trans();

  return 0;

bad:
  iunlockput(dp);
80105e92:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e95:	89 04 24             	mov    %eax,(%esp)
80105e98:	e8 4f bc ff ff       	call   80101aec <iunlockput>
  commit_trans();
80105e9d:	e8 d0 d3 ff ff       	call   80103272 <commit_trans>
  return -1;
80105ea2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105ea7:	c9                   	leave  
80105ea8:	c3                   	ret    

80105ea9 <create>:

static struct inode*
create(char *path, short type, short major, short minor)
{
80105ea9:	55                   	push   %ebp
80105eaa:	89 e5                	mov    %esp,%ebp
80105eac:	83 ec 48             	sub    $0x48,%esp
80105eaf:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80105eb2:	8b 55 10             	mov    0x10(%ebp),%edx
80105eb5:	8b 45 14             	mov    0x14(%ebp),%eax
80105eb8:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
80105ebc:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
80105ec0:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];
  if((dp = nameiparent(path, name)) == 0)
80105ec4:	8d 45 de             	lea    -0x22(%ebp),%eax
80105ec7:	89 44 24 04          	mov    %eax,0x4(%esp)
80105ecb:	8b 45 08             	mov    0x8(%ebp),%eax
80105ece:	89 04 24             	mov    %eax,(%esp)
80105ed1:	e8 56 c5 ff ff       	call   8010242c <nameiparent>
80105ed6:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105ed9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105edd:	75 0a                	jne    80105ee9 <create+0x40>
    return 0;
80105edf:	b8 00 00 00 00       	mov    $0x0,%eax
80105ee4:	e9 7e 01 00 00       	jmp    80106067 <create+0x1be>
  ilock(dp);
80105ee9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105eec:	89 04 24             	mov    %eax,(%esp)
80105eef:	e8 74 b9 ff ff       	call   80101868 <ilock>
  if((ip = dirlookup(dp, name, &off)) != 0){
80105ef4:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105ef7:	89 44 24 08          	mov    %eax,0x8(%esp)
80105efb:	8d 45 de             	lea    -0x22(%ebp),%eax
80105efe:	89 44 24 04          	mov    %eax,0x4(%esp)
80105f02:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f05:	89 04 24             	mov    %eax,(%esp)
80105f08:	e8 74 c1 ff ff       	call   80102081 <dirlookup>
80105f0d:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105f10:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105f14:	74 47                	je     80105f5d <create+0xb4>
    iunlockput(dp);
80105f16:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f19:	89 04 24             	mov    %eax,(%esp)
80105f1c:	e8 cb bb ff ff       	call   80101aec <iunlockput>
    ilock(ip);
80105f21:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f24:	89 04 24             	mov    %eax,(%esp)
80105f27:	e8 3c b9 ff ff       	call   80101868 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
80105f2c:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
80105f31:	75 15                	jne    80105f48 <create+0x9f>
80105f33:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f36:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105f3a:	66 83 f8 02          	cmp    $0x2,%ax
80105f3e:	75 08                	jne    80105f48 <create+0x9f>
      return ip;
80105f40:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f43:	e9 1f 01 00 00       	jmp    80106067 <create+0x1be>
    iunlockput(ip);
80105f48:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f4b:	89 04 24             	mov    %eax,(%esp)
80105f4e:	e8 99 bb ff ff       	call   80101aec <iunlockput>
    return 0;
80105f53:	b8 00 00 00 00       	mov    $0x0,%eax
80105f58:	e9 0a 01 00 00       	jmp    80106067 <create+0x1be>
  }
  if((ip = ialloc(dp->dev, type)) == 0)
80105f5d:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
80105f61:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f64:	8b 00                	mov    (%eax),%eax
80105f66:	89 54 24 04          	mov    %edx,0x4(%esp)
80105f6a:	89 04 24             	mov    %eax,(%esp)
80105f6d:	e8 5d b6 ff ff       	call   801015cf <ialloc>
80105f72:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105f75:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105f79:	75 0c                	jne    80105f87 <create+0xde>
    panic("create: ialloc");
80105f7b:	c7 04 24 b7 8d 10 80 	movl   $0x80108db7,(%esp)
80105f82:	e8 b6 a5 ff ff       	call   8010053d <panic>
  ilock(ip);
80105f87:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f8a:	89 04 24             	mov    %eax,(%esp)
80105f8d:	e8 d6 b8 ff ff       	call   80101868 <ilock>
  ip->major = major;
80105f92:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f95:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
80105f99:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
80105f9d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105fa0:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
80105fa4:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
80105fa8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105fab:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
80105fb1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105fb4:	89 04 24             	mov    %eax,(%esp)
80105fb7:	e8 f0 b6 ff ff       	call   801016ac <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
80105fbc:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
80105fc1:	75 6a                	jne    8010602d <create+0x184>
    dp->nlink++;  // for ".."
80105fc3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105fc6:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105fca:	8d 50 01             	lea    0x1(%eax),%edx
80105fcd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105fd0:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80105fd4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105fd7:	89 04 24             	mov    %eax,(%esp)
80105fda:	e8 cd b6 ff ff       	call   801016ac <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80105fdf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105fe2:	8b 40 04             	mov    0x4(%eax),%eax
80105fe5:	89 44 24 08          	mov    %eax,0x8(%esp)
80105fe9:	c7 44 24 04 91 8d 10 	movl   $0x80108d91,0x4(%esp)
80105ff0:	80 
80105ff1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ff4:	89 04 24             	mov    %eax,(%esp)
80105ff7:	e8 4d c1 ff ff       	call   80102149 <dirlink>
80105ffc:	85 c0                	test   %eax,%eax
80105ffe:	78 21                	js     80106021 <create+0x178>
80106000:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106003:	8b 40 04             	mov    0x4(%eax),%eax
80106006:	89 44 24 08          	mov    %eax,0x8(%esp)
8010600a:	c7 44 24 04 93 8d 10 	movl   $0x80108d93,0x4(%esp)
80106011:	80 
80106012:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106015:	89 04 24             	mov    %eax,(%esp)
80106018:	e8 2c c1 ff ff       	call   80102149 <dirlink>
8010601d:	85 c0                	test   %eax,%eax
8010601f:	79 0c                	jns    8010602d <create+0x184>
      panic("create dots");
80106021:	c7 04 24 c6 8d 10 80 	movl   $0x80108dc6,(%esp)
80106028:	e8 10 a5 ff ff       	call   8010053d <panic>
  }
  if(dirlink(dp, name, ip->inum) < 0)
8010602d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106030:	8b 40 04             	mov    0x4(%eax),%eax
80106033:	89 44 24 08          	mov    %eax,0x8(%esp)
80106037:	8d 45 de             	lea    -0x22(%ebp),%eax
8010603a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010603e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106041:	89 04 24             	mov    %eax,(%esp)
80106044:	e8 00 c1 ff ff       	call   80102149 <dirlink>
80106049:	85 c0                	test   %eax,%eax
8010604b:	79 0c                	jns    80106059 <create+0x1b0>
    panic("create: dirlink");
8010604d:	c7 04 24 d2 8d 10 80 	movl   $0x80108dd2,(%esp)
80106054:	e8 e4 a4 ff ff       	call   8010053d <panic>
  iunlockput(dp);
80106059:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010605c:	89 04 24             	mov    %eax,(%esp)
8010605f:	e8 88 ba ff ff       	call   80101aec <iunlockput>

  return ip;
80106064:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80106067:	c9                   	leave  
80106068:	c3                   	ret    

80106069 <fileopen>:

struct file*
fileopen(char *path, int omode)
{
80106069:	55                   	push   %ebp
8010606a:	89 e5                	mov    %esp,%ebp
8010606c:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  struct inode *ip;

  if(omode & O_CREATE){
8010606f:	8b 45 0c             	mov    0xc(%ebp),%eax
80106072:	25 00 02 00 00       	and    $0x200,%eax
80106077:	85 c0                	test   %eax,%eax
80106079:	74 40                	je     801060bb <fileopen+0x52>
    begin_trans();
8010607b:	e8 a9 d1 ff ff       	call   80103229 <begin_trans>
    ip = create(path, T_FILE, 0, 0);
80106080:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106087:	00 
80106088:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010608f:	00 
80106090:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80106097:	00 
80106098:	8b 45 08             	mov    0x8(%ebp),%eax
8010609b:	89 04 24             	mov    %eax,(%esp)
8010609e:	e8 06 fe ff ff       	call   80105ea9 <create>
801060a3:	89 45 f4             	mov    %eax,-0xc(%ebp)
    commit_trans();
801060a6:	e8 c7 d1 ff ff       	call   80103272 <commit_trans>
    if(ip == 0)
801060ab:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801060af:	75 5b                	jne    8010610c <fileopen+0xa3>
      return 0;
801060b1:	b8 00 00 00 00       	mov    $0x0,%eax
801060b6:	e9 f9 00 00 00       	jmp    801061b4 <fileopen+0x14b>
  } else {
    if((ip = namei(path)) == 0)
801060bb:	8b 45 08             	mov    0x8(%ebp),%eax
801060be:	89 04 24             	mov    %eax,(%esp)
801060c1:	e8 44 c3 ff ff       	call   8010240a <namei>
801060c6:	89 45 f4             	mov    %eax,-0xc(%ebp)
801060c9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801060cd:	75 0a                	jne    801060d9 <fileopen+0x70>
      return 0;
801060cf:	b8 00 00 00 00       	mov    $0x0,%eax
801060d4:	e9 db 00 00 00       	jmp    801061b4 <fileopen+0x14b>
    ilock(ip);
801060d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801060dc:	89 04 24             	mov    %eax,(%esp)
801060df:	e8 84 b7 ff ff       	call   80101868 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
801060e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801060e7:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801060eb:	66 83 f8 01          	cmp    $0x1,%ax
801060ef:	75 1b                	jne    8010610c <fileopen+0xa3>
801060f1:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801060f5:	74 15                	je     8010610c <fileopen+0xa3>
      iunlockput(ip);
801060f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801060fa:	89 04 24             	mov    %eax,(%esp)
801060fd:	e8 ea b9 ff ff       	call   80101aec <iunlockput>
      return 0;
80106102:	b8 00 00 00 00       	mov    $0x0,%eax
80106107:	e9 a8 00 00 00       	jmp    801061b4 <fileopen+0x14b>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
8010610c:	e8 0b ae ff ff       	call   80100f1c <filealloc>
80106111:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106114:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106118:	74 14                	je     8010612e <fileopen+0xc5>
8010611a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010611d:	89 04 24             	mov    %eax,(%esp)
80106120:	e8 7c f7 ff ff       	call   801058a1 <fdalloc>
80106125:	89 45 ec             	mov    %eax,-0x14(%ebp)
80106128:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
8010612c:	79 23                	jns    80106151 <fileopen+0xe8>
    if(f)
8010612e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106132:	74 0b                	je     8010613f <fileopen+0xd6>
      fileclose(f);
80106134:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106137:	89 04 24             	mov    %eax,(%esp)
8010613a:	e8 85 ae ff ff       	call   80100fc4 <fileclose>
    iunlockput(ip);
8010613f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106142:	89 04 24             	mov    %eax,(%esp)
80106145:	e8 a2 b9 ff ff       	call   80101aec <iunlockput>
    return 0;
8010614a:	b8 00 00 00 00       	mov    $0x0,%eax
8010614f:	eb 63                	jmp    801061b4 <fileopen+0x14b>
  }
  iunlock(ip);
80106151:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106154:	89 04 24             	mov    %eax,(%esp)
80106157:	e8 5a b8 ff ff       	call   801019b6 <iunlock>

  f->type = FD_INODE;
8010615c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010615f:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80106165:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106168:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010616b:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
8010616e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106171:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80106178:	8b 45 0c             	mov    0xc(%ebp),%eax
8010617b:	83 e0 01             	and    $0x1,%eax
8010617e:	85 c0                	test   %eax,%eax
80106180:	0f 94 c2             	sete   %dl
80106183:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106186:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80106189:	8b 45 0c             	mov    0xc(%ebp),%eax
8010618c:	83 e0 01             	and    $0x1,%eax
8010618f:	84 c0                	test   %al,%al
80106191:	75 0a                	jne    8010619d <fileopen+0x134>
80106193:	8b 45 0c             	mov    0xc(%ebp),%eax
80106196:	83 e0 02             	and    $0x2,%eax
80106199:	85 c0                	test   %eax,%eax
8010619b:	74 07                	je     801061a4 <fileopen+0x13b>
8010619d:	b8 01 00 00 00       	mov    $0x1,%eax
801061a2:	eb 05                	jmp    801061a9 <fileopen+0x140>
801061a4:	b8 00 00 00 00       	mov    $0x0,%eax
801061a9:	89 c2                	mov    %eax,%edx
801061ab:	8b 45 f0             	mov    -0x10(%ebp),%eax
801061ae:	88 50 09             	mov    %dl,0x9(%eax)
  return f;
801061b1:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
801061b4:	c9                   	leave  
801061b5:	c3                   	ret    

801061b6 <sys_open>:

int
sys_open(void)
{
801061b6:	55                   	push   %ebp
801061b7:	89 e5                	mov    %esp,%ebp
801061b9:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
801061bc:	8d 45 e8             	lea    -0x18(%ebp),%eax
801061bf:	89 44 24 04          	mov    %eax,0x4(%esp)
801061c3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801061ca:	e8 55 f5 ff ff       	call   80105724 <argstr>
801061cf:	85 c0                	test   %eax,%eax
801061d1:	78 17                	js     801061ea <sys_open+0x34>
801061d3:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801061d6:	89 44 24 04          	mov    %eax,0x4(%esp)
801061da:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801061e1:	e8 a4 f4 ff ff       	call   8010568a <argint>
801061e6:	85 c0                	test   %eax,%eax
801061e8:	79 0a                	jns    801061f4 <sys_open+0x3e>
    return -1;
801061ea:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061ef:	e9 46 01 00 00       	jmp    8010633a <sys_open+0x184>
  if(omode & O_CREATE){
801061f4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801061f7:	25 00 02 00 00       	and    $0x200,%eax
801061fc:	85 c0                	test   %eax,%eax
801061fe:	74 40                	je     80106240 <sys_open+0x8a>
    begin_trans();
80106200:	e8 24 d0 ff ff       	call   80103229 <begin_trans>
    ip = create(path, T_FILE, 0, 0);
80106205:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106208:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
8010620f:	00 
80106210:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106217:	00 
80106218:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
8010621f:	00 
80106220:	89 04 24             	mov    %eax,(%esp)
80106223:	e8 81 fc ff ff       	call   80105ea9 <create>
80106228:	89 45 f4             	mov    %eax,-0xc(%ebp)
    commit_trans();
8010622b:	e8 42 d0 ff ff       	call   80103272 <commit_trans>
    if(ip == 0)
80106230:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106234:	75 5c                	jne    80106292 <sys_open+0xdc>
      return -1;
80106236:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010623b:	e9 fa 00 00 00       	jmp    8010633a <sys_open+0x184>
  } else {
    if((ip = namei(path)) == 0)
80106240:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106243:	89 04 24             	mov    %eax,(%esp)
80106246:	e8 bf c1 ff ff       	call   8010240a <namei>
8010624b:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010624e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106252:	75 0a                	jne    8010625e <sys_open+0xa8>
      return -1;
80106254:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106259:	e9 dc 00 00 00       	jmp    8010633a <sys_open+0x184>
    ilock(ip);
8010625e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106261:	89 04 24             	mov    %eax,(%esp)
80106264:	e8 ff b5 ff ff       	call   80101868 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80106269:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010626c:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106270:	66 83 f8 01          	cmp    $0x1,%ax
80106274:	75 1c                	jne    80106292 <sys_open+0xdc>
80106276:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106279:	85 c0                	test   %eax,%eax
8010627b:	74 15                	je     80106292 <sys_open+0xdc>
      iunlockput(ip);
8010627d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106280:	89 04 24             	mov    %eax,(%esp)
80106283:	e8 64 b8 ff ff       	call   80101aec <iunlockput>
      return -1;
80106288:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010628d:	e9 a8 00 00 00       	jmp    8010633a <sys_open+0x184>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80106292:	e8 85 ac ff ff       	call   80100f1c <filealloc>
80106297:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010629a:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010629e:	74 14                	je     801062b4 <sys_open+0xfe>
801062a0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801062a3:	89 04 24             	mov    %eax,(%esp)
801062a6:	e8 f6 f5 ff ff       	call   801058a1 <fdalloc>
801062ab:	89 45 ec             	mov    %eax,-0x14(%ebp)
801062ae:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801062b2:	79 23                	jns    801062d7 <sys_open+0x121>
    if(f)
801062b4:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801062b8:	74 0b                	je     801062c5 <sys_open+0x10f>
      fileclose(f);
801062ba:	8b 45 f0             	mov    -0x10(%ebp),%eax
801062bd:	89 04 24             	mov    %eax,(%esp)
801062c0:	e8 ff ac ff ff       	call   80100fc4 <fileclose>
    iunlockput(ip);
801062c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062c8:	89 04 24             	mov    %eax,(%esp)
801062cb:	e8 1c b8 ff ff       	call   80101aec <iunlockput>
    return -1;
801062d0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801062d5:	eb 63                	jmp    8010633a <sys_open+0x184>
  }
  iunlock(ip);
801062d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062da:	89 04 24             	mov    %eax,(%esp)
801062dd:	e8 d4 b6 ff ff       	call   801019b6 <iunlock>

  f->type = FD_INODE;
801062e2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801062e5:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
801062eb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801062ee:	8b 55 f4             	mov    -0xc(%ebp),%edx
801062f1:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
801062f4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801062f7:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
801062fe:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106301:	83 e0 01             	and    $0x1,%eax
80106304:	85 c0                	test   %eax,%eax
80106306:	0f 94 c2             	sete   %dl
80106309:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010630c:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
8010630f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106312:	83 e0 01             	and    $0x1,%eax
80106315:	84 c0                	test   %al,%al
80106317:	75 0a                	jne    80106323 <sys_open+0x16d>
80106319:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010631c:	83 e0 02             	and    $0x2,%eax
8010631f:	85 c0                	test   %eax,%eax
80106321:	74 07                	je     8010632a <sys_open+0x174>
80106323:	b8 01 00 00 00       	mov    $0x1,%eax
80106328:	eb 05                	jmp    8010632f <sys_open+0x179>
8010632a:	b8 00 00 00 00       	mov    $0x0,%eax
8010632f:	89 c2                	mov    %eax,%edx
80106331:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106334:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
80106337:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
8010633a:	c9                   	leave  
8010633b:	c3                   	ret    

8010633c <sys_mkdir>:

int
sys_mkdir(void)
{
8010633c:	55                   	push   %ebp
8010633d:	89 e5                	mov    %esp,%ebp
8010633f:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_trans();
80106342:	e8 e2 ce ff ff       	call   80103229 <begin_trans>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80106347:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010634a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010634e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106355:	e8 ca f3 ff ff       	call   80105724 <argstr>
8010635a:	85 c0                	test   %eax,%eax
8010635c:	78 2c                	js     8010638a <sys_mkdir+0x4e>
8010635e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106361:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106368:	00 
80106369:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106370:	00 
80106371:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80106378:	00 
80106379:	89 04 24             	mov    %eax,(%esp)
8010637c:	e8 28 fb ff ff       	call   80105ea9 <create>
80106381:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106384:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106388:	75 0c                	jne    80106396 <sys_mkdir+0x5a>
    commit_trans();
8010638a:	e8 e3 ce ff ff       	call   80103272 <commit_trans>
    return -1;
8010638f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106394:	eb 15                	jmp    801063ab <sys_mkdir+0x6f>
  }
  iunlockput(ip);
80106396:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106399:	89 04 24             	mov    %eax,(%esp)
8010639c:	e8 4b b7 ff ff       	call   80101aec <iunlockput>
  commit_trans();
801063a1:	e8 cc ce ff ff       	call   80103272 <commit_trans>
  return 0;
801063a6:	b8 00 00 00 00       	mov    $0x0,%eax
}
801063ab:	c9                   	leave  
801063ac:	c3                   	ret    

801063ad <sys_mknod>:

int
sys_mknod(void)
{
801063ad:	55                   	push   %ebp
801063ae:	89 e5                	mov    %esp,%ebp
801063b0:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
801063b3:	e8 71 ce ff ff       	call   80103229 <begin_trans>
  if((len=argstr(0, &path)) < 0 ||
801063b8:	8d 45 ec             	lea    -0x14(%ebp),%eax
801063bb:	89 44 24 04          	mov    %eax,0x4(%esp)
801063bf:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801063c6:	e8 59 f3 ff ff       	call   80105724 <argstr>
801063cb:	89 45 f4             	mov    %eax,-0xc(%ebp)
801063ce:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801063d2:	78 5e                	js     80106432 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
801063d4:	8d 45 e8             	lea    -0x18(%ebp),%eax
801063d7:	89 44 24 04          	mov    %eax,0x4(%esp)
801063db:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801063e2:	e8 a3 f2 ff ff       	call   8010568a <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
801063e7:	85 c0                	test   %eax,%eax
801063e9:	78 47                	js     80106432 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
801063eb:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801063ee:	89 44 24 04          	mov    %eax,0x4(%esp)
801063f2:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801063f9:	e8 8c f2 ff ff       	call   8010568a <argint>
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
801063fe:	85 c0                	test   %eax,%eax
80106400:	78 30                	js     80106432 <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
80106402:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106405:	0f bf c8             	movswl %ax,%ecx
80106408:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010640b:	0f bf d0             	movswl %ax,%edx
8010640e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80106411:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106415:	89 54 24 08          	mov    %edx,0x8(%esp)
80106419:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80106420:	00 
80106421:	89 04 24             	mov    %eax,(%esp)
80106424:	e8 80 fa ff ff       	call   80105ea9 <create>
80106429:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010642c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106430:	75 0c                	jne    8010643e <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    commit_trans();
80106432:	e8 3b ce ff ff       	call   80103272 <commit_trans>
    return -1;
80106437:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010643c:	eb 15                	jmp    80106453 <sys_mknod+0xa6>
  }
  iunlockput(ip);
8010643e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106441:	89 04 24             	mov    %eax,(%esp)
80106444:	e8 a3 b6 ff ff       	call   80101aec <iunlockput>
  commit_trans();
80106449:	e8 24 ce ff ff       	call   80103272 <commit_trans>
  return 0;
8010644e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106453:	c9                   	leave  
80106454:	c3                   	ret    

80106455 <sys_chdir>:

int
sys_chdir(void)
{
80106455:	55                   	push   %ebp
80106456:	89 e5                	mov    %esp,%ebp
80106458:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0)
8010645b:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010645e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106462:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106469:	e8 b6 f2 ff ff       	call   80105724 <argstr>
8010646e:	85 c0                	test   %eax,%eax
80106470:	78 14                	js     80106486 <sys_chdir+0x31>
80106472:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106475:	89 04 24             	mov    %eax,(%esp)
80106478:	e8 8d bf ff ff       	call   8010240a <namei>
8010647d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106480:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106484:	75 07                	jne    8010648d <sys_chdir+0x38>
    return -1;
80106486:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010648b:	eb 57                	jmp    801064e4 <sys_chdir+0x8f>
  ilock(ip);
8010648d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106490:	89 04 24             	mov    %eax,(%esp)
80106493:	e8 d0 b3 ff ff       	call   80101868 <ilock>
  if(ip->type != T_DIR){
80106498:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010649b:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010649f:	66 83 f8 01          	cmp    $0x1,%ax
801064a3:	74 12                	je     801064b7 <sys_chdir+0x62>
    iunlockput(ip);
801064a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064a8:	89 04 24             	mov    %eax,(%esp)
801064ab:	e8 3c b6 ff ff       	call   80101aec <iunlockput>
    return -1;
801064b0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801064b5:	eb 2d                	jmp    801064e4 <sys_chdir+0x8f>
  }
  iunlock(ip);
801064b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064ba:	89 04 24             	mov    %eax,(%esp)
801064bd:	e8 f4 b4 ff ff       	call   801019b6 <iunlock>
  iput(proc->cwd);
801064c2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801064c8:	8b 40 68             	mov    0x68(%eax),%eax
801064cb:	89 04 24             	mov    %eax,(%esp)
801064ce:	e8 48 b5 ff ff       	call   80101a1b <iput>
  proc->cwd = ip;
801064d3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801064d9:	8b 55 f4             	mov    -0xc(%ebp),%edx
801064dc:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
801064df:	b8 00 00 00 00       	mov    $0x0,%eax
}
801064e4:	c9                   	leave  
801064e5:	c3                   	ret    

801064e6 <sys_exec>:

int
sys_exec(void)
{
801064e6:	55                   	push   %ebp
801064e7:	89 e5                	mov    %esp,%ebp
801064e9:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
801064ef:	8d 45 f0             	lea    -0x10(%ebp),%eax
801064f2:	89 44 24 04          	mov    %eax,0x4(%esp)
801064f6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801064fd:	e8 22 f2 ff ff       	call   80105724 <argstr>
80106502:	85 c0                	test   %eax,%eax
80106504:	78 1a                	js     80106520 <sys_exec+0x3a>
80106506:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
8010650c:	89 44 24 04          	mov    %eax,0x4(%esp)
80106510:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106517:	e8 6e f1 ff ff       	call   8010568a <argint>
8010651c:	85 c0                	test   %eax,%eax
8010651e:	79 0a                	jns    8010652a <sys_exec+0x44>
    return -1;
80106520:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106525:	e9 e2 00 00 00       	jmp    8010660c <sys_exec+0x126>
  }
  memset(argv, 0, sizeof(argv));
8010652a:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80106531:	00 
80106532:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106539:	00 
8010653a:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106540:	89 04 24             	mov    %eax,(%esp)
80106543:	e8 f2 ed ff ff       	call   8010533a <memset>
  for(i=0;; i++){
80106548:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
8010654f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106552:	83 f8 1f             	cmp    $0x1f,%eax
80106555:	76 0a                	jbe    80106561 <sys_exec+0x7b>
      return -1;
80106557:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010655c:	e9 ab 00 00 00       	jmp    8010660c <sys_exec+0x126>
    if(fetchint(proc, uargv+4*i, (int*)&uarg) < 0)
80106561:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106564:	c1 e0 02             	shl    $0x2,%eax
80106567:	89 c2                	mov    %eax,%edx
80106569:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
8010656f:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
80106572:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106578:	8d 95 68 ff ff ff    	lea    -0x98(%ebp),%edx
8010657e:	89 54 24 08          	mov    %edx,0x8(%esp)
80106582:	89 4c 24 04          	mov    %ecx,0x4(%esp)
80106586:	89 04 24             	mov    %eax,(%esp)
80106589:	e8 6a f0 ff ff       	call   801055f8 <fetchint>
8010658e:	85 c0                	test   %eax,%eax
80106590:	79 07                	jns    80106599 <sys_exec+0xb3>
      return -1;
80106592:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106597:	eb 73                	jmp    8010660c <sys_exec+0x126>
    if(uarg == 0){
80106599:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
8010659f:	85 c0                	test   %eax,%eax
801065a1:	75 26                	jne    801065c9 <sys_exec+0xe3>
      argv[i] = 0;
801065a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065a6:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
801065ad:	00 00 00 00 
      break;
801065b1:	90                   	nop
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
801065b2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065b5:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
801065bb:	89 54 24 04          	mov    %edx,0x4(%esp)
801065bf:	89 04 24             	mov    %eax,(%esp)
801065c2:	e8 35 a5 ff ff       	call   80100afc <exec>
801065c7:	eb 43                	jmp    8010660c <sys_exec+0x126>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
801065c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065cc:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801065d3:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
801065d9:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
801065dc:	8b 95 68 ff ff ff    	mov    -0x98(%ebp),%edx
801065e2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801065e8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801065ec:	89 54 24 04          	mov    %edx,0x4(%esp)
801065f0:	89 04 24             	mov    %eax,(%esp)
801065f3:	e8 34 f0 ff ff       	call   8010562c <fetchstr>
801065f8:	85 c0                	test   %eax,%eax
801065fa:	79 07                	jns    80106603 <sys_exec+0x11d>
      return -1;
801065fc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106601:	eb 09                	jmp    8010660c <sys_exec+0x126>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
80106603:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
80106607:	e9 43 ff ff ff       	jmp    8010654f <sys_exec+0x69>
  return exec(path, argv);
}
8010660c:	c9                   	leave  
8010660d:	c3                   	ret    

8010660e <sys_pipe>:

int
sys_pipe(void)
{
8010660e:	55                   	push   %ebp
8010660f:	89 e5                	mov    %esp,%ebp
80106611:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80106614:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
8010661b:	00 
8010661c:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010661f:	89 44 24 04          	mov    %eax,0x4(%esp)
80106623:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010662a:	e8 93 f0 ff ff       	call   801056c2 <argptr>
8010662f:	85 c0                	test   %eax,%eax
80106631:	79 0a                	jns    8010663d <sys_pipe+0x2f>
    return -1;
80106633:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106638:	e9 9b 00 00 00       	jmp    801066d8 <sys_pipe+0xca>
  if(pipealloc(&rf, &wf) < 0)
8010663d:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106640:	89 44 24 04          	mov    %eax,0x4(%esp)
80106644:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106647:	89 04 24             	mov    %eax,(%esp)
8010664a:	e8 f5 d5 ff ff       	call   80103c44 <pipealloc>
8010664f:	85 c0                	test   %eax,%eax
80106651:	79 07                	jns    8010665a <sys_pipe+0x4c>
    return -1;
80106653:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106658:	eb 7e                	jmp    801066d8 <sys_pipe+0xca>
  fd0 = -1;
8010665a:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80106661:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106664:	89 04 24             	mov    %eax,(%esp)
80106667:	e8 35 f2 ff ff       	call   801058a1 <fdalloc>
8010666c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010666f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106673:	78 14                	js     80106689 <sys_pipe+0x7b>
80106675:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106678:	89 04 24             	mov    %eax,(%esp)
8010667b:	e8 21 f2 ff ff       	call   801058a1 <fdalloc>
80106680:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106683:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106687:	79 37                	jns    801066c0 <sys_pipe+0xb2>
    if(fd0 >= 0)
80106689:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010668d:	78 14                	js     801066a3 <sys_pipe+0x95>
      proc->ofile[fd0] = 0;
8010668f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106695:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106698:	83 c2 08             	add    $0x8,%edx
8010669b:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
801066a2:	00 
    fileclose(rf);
801066a3:	8b 45 e8             	mov    -0x18(%ebp),%eax
801066a6:	89 04 24             	mov    %eax,(%esp)
801066a9:	e8 16 a9 ff ff       	call   80100fc4 <fileclose>
    fileclose(wf);
801066ae:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801066b1:	89 04 24             	mov    %eax,(%esp)
801066b4:	e8 0b a9 ff ff       	call   80100fc4 <fileclose>
    return -1;
801066b9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801066be:	eb 18                	jmp    801066d8 <sys_pipe+0xca>
  }
  fd[0] = fd0;
801066c0:	8b 45 ec             	mov    -0x14(%ebp),%eax
801066c3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801066c6:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
801066c8:	8b 45 ec             	mov    -0x14(%ebp),%eax
801066cb:	8d 50 04             	lea    0x4(%eax),%edx
801066ce:	8b 45 f0             	mov    -0x10(%ebp),%eax
801066d1:	89 02                	mov    %eax,(%edx)
  return 0;
801066d3:	b8 00 00 00 00       	mov    $0x0,%eax
}
801066d8:	c9                   	leave  
801066d9:	c3                   	ret    
	...

801066dc <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
801066dc:	55                   	push   %ebp
801066dd:	89 e5                	mov    %esp,%ebp
801066df:	83 ec 08             	sub    $0x8,%esp
  return fork();
801066e2:	e8 53 e0 ff ff       	call   8010473a <fork>
}
801066e7:	c9                   	leave  
801066e8:	c3                   	ret    

801066e9 <sys_exit>:

int
sys_exit(void)
{
801066e9:	55                   	push   %ebp
801066ea:	89 e5                	mov    %esp,%ebp
801066ec:	83 ec 08             	sub    $0x8,%esp
  exit();
801066ef:	e8 a9 e1 ff ff       	call   8010489d <exit>
  return 0;  // not reached
801066f4:	b8 00 00 00 00       	mov    $0x0,%eax
}
801066f9:	c9                   	leave  
801066fa:	c3                   	ret    

801066fb <sys_wait>:

int
sys_wait(void)
{
801066fb:	55                   	push   %ebp
801066fc:	89 e5                	mov    %esp,%ebp
801066fe:	83 ec 08             	sub    $0x8,%esp
  return wait();
80106701:	e8 b2 e2 ff ff       	call   801049b8 <wait>
}
80106706:	c9                   	leave  
80106707:	c3                   	ret    

80106708 <sys_kill>:

int
sys_kill(void)
{
80106708:	55                   	push   %ebp
80106709:	89 e5                	mov    %esp,%ebp
8010670b:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
8010670e:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106711:	89 44 24 04          	mov    %eax,0x4(%esp)
80106715:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010671c:	e8 69 ef ff ff       	call   8010568a <argint>
80106721:	85 c0                	test   %eax,%eax
80106723:	79 07                	jns    8010672c <sys_kill+0x24>
    return -1;
80106725:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010672a:	eb 0b                	jmp    80106737 <sys_kill+0x2f>
  return kill(pid);
8010672c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010672f:	89 04 24             	mov    %eax,(%esp)
80106732:	e8 9c e7 ff ff       	call   80104ed3 <kill>
}
80106737:	c9                   	leave  
80106738:	c3                   	ret    

80106739 <sys_getpid>:

int
sys_getpid(void)
{
80106739:	55                   	push   %ebp
8010673a:	89 e5                	mov    %esp,%ebp
  return proc->pid;
8010673c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106742:	8b 40 10             	mov    0x10(%eax),%eax
}
80106745:	5d                   	pop    %ebp
80106746:	c3                   	ret    

80106747 <sys_sbrk>:

int
sys_sbrk(void)
{
80106747:	55                   	push   %ebp
80106748:	89 e5                	mov    %esp,%ebp
8010674a:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
8010674d:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106750:	89 44 24 04          	mov    %eax,0x4(%esp)
80106754:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010675b:	e8 2a ef ff ff       	call   8010568a <argint>
80106760:	85 c0                	test   %eax,%eax
80106762:	79 07                	jns    8010676b <sys_sbrk+0x24>
    return -1;
80106764:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106769:	eb 24                	jmp    8010678f <sys_sbrk+0x48>
  addr = proc->sz;
8010676b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106771:	8b 00                	mov    (%eax),%eax
80106773:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
80106776:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106779:	89 04 24             	mov    %eax,(%esp)
8010677c:	e8 14 df ff ff       	call   80104695 <growproc>
80106781:	85 c0                	test   %eax,%eax
80106783:	79 07                	jns    8010678c <sys_sbrk+0x45>
    return -1;
80106785:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010678a:	eb 03                	jmp    8010678f <sys_sbrk+0x48>
  return addr;
8010678c:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010678f:	c9                   	leave  
80106790:	c3                   	ret    

80106791 <sys_sleep>:

int
sys_sleep(void)
{
80106791:	55                   	push   %ebp
80106792:	89 e5                	mov    %esp,%ebp
80106794:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
80106797:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010679a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010679e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801067a5:	e8 e0 ee ff ff       	call   8010568a <argint>
801067aa:	85 c0                	test   %eax,%eax
801067ac:	79 07                	jns    801067b5 <sys_sleep+0x24>
    return -1;
801067ae:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801067b3:	eb 6c                	jmp    80106821 <sys_sleep+0x90>
  acquire(&tickslock);
801067b5:	c7 04 24 60 30 11 80 	movl   $0x80113060,(%esp)
801067bc:	e8 f2 e8 ff ff       	call   801050b3 <acquire>
  ticks0 = ticks;
801067c1:	a1 a0 38 11 80       	mov    0x801138a0,%eax
801067c6:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
801067c9:	eb 34                	jmp    801067ff <sys_sleep+0x6e>
    if(proc->killed){
801067cb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801067d1:	8b 40 24             	mov    0x24(%eax),%eax
801067d4:	85 c0                	test   %eax,%eax
801067d6:	74 13                	je     801067eb <sys_sleep+0x5a>
      release(&tickslock);
801067d8:	c7 04 24 60 30 11 80 	movl   $0x80113060,(%esp)
801067df:	e8 6a e9 ff ff       	call   8010514e <release>
      return -1;
801067e4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801067e9:	eb 36                	jmp    80106821 <sys_sleep+0x90>
    }
    sleep(&ticks, &tickslock);
801067eb:	c7 44 24 04 60 30 11 	movl   $0x80113060,0x4(%esp)
801067f2:	80 
801067f3:	c7 04 24 a0 38 11 80 	movl   $0x801138a0,(%esp)
801067fa:	e8 75 e5 ff ff       	call   80104d74 <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
801067ff:	a1 a0 38 11 80       	mov    0x801138a0,%eax
80106804:	89 c2                	mov    %eax,%edx
80106806:	2b 55 f4             	sub    -0xc(%ebp),%edx
80106809:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010680c:	39 c2                	cmp    %eax,%edx
8010680e:	72 bb                	jb     801067cb <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
80106810:	c7 04 24 60 30 11 80 	movl   $0x80113060,(%esp)
80106817:	e8 32 e9 ff ff       	call   8010514e <release>
  return 0;
8010681c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106821:	c9                   	leave  
80106822:	c3                   	ret    

80106823 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80106823:	55                   	push   %ebp
80106824:	89 e5                	mov    %esp,%ebp
80106826:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
80106829:	c7 04 24 60 30 11 80 	movl   $0x80113060,(%esp)
80106830:	e8 7e e8 ff ff       	call   801050b3 <acquire>
  xticks = ticks;
80106835:	a1 a0 38 11 80       	mov    0x801138a0,%eax
8010683a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
8010683d:	c7 04 24 60 30 11 80 	movl   $0x80113060,(%esp)
80106844:	e8 05 e9 ff ff       	call   8010514e <release>
  return xticks;
80106849:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010684c:	c9                   	leave  
8010684d:	c3                   	ret    

8010684e <sys_enableSwapping>:

void
sys_enableSwapping(void)
{
8010684e:	55                   	push   %ebp
8010684f:	89 e5                	mov    %esp,%ebp
  swapFlag = 1;
80106851:	c7 05 08 c0 10 80 01 	movl   $0x1,0x8010c008
80106858:	00 00 00 
}
8010685b:	5d                   	pop    %ebp
8010685c:	c3                   	ret    

8010685d <sys_disableSwapping>:

void
sys_disableSwapping(void)
{
8010685d:	55                   	push   %ebp
8010685e:	89 e5                	mov    %esp,%ebp
  swapFlag = 0;
80106860:	c7 05 08 c0 10 80 00 	movl   $0x0,0x8010c008
80106867:	00 00 00 
}
8010686a:	5d                   	pop    %ebp
8010686b:	c3                   	ret    

8010686c <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
8010686c:	55                   	push   %ebp
8010686d:	89 e5                	mov    %esp,%ebp
8010686f:	83 ec 08             	sub    $0x8,%esp
80106872:	8b 55 08             	mov    0x8(%ebp),%edx
80106875:	8b 45 0c             	mov    0xc(%ebp),%eax
80106878:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
8010687c:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010687f:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80106883:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80106887:	ee                   	out    %al,(%dx)
}
80106888:	c9                   	leave  
80106889:	c3                   	ret    

8010688a <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
8010688a:	55                   	push   %ebp
8010688b:	89 e5                	mov    %esp,%ebp
8010688d:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
80106890:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
80106897:	00 
80106898:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
8010689f:	e8 c8 ff ff ff       	call   8010686c <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
801068a4:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
801068ab:	00 
801068ac:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
801068b3:	e8 b4 ff ff ff       	call   8010686c <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
801068b8:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
801068bf:	00 
801068c0:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
801068c7:	e8 a0 ff ff ff       	call   8010686c <outb>
  picenable(IRQ_TIMER);
801068cc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801068d3:	e8 f5 d1 ff ff       	call   80103acd <picenable>
}
801068d8:	c9                   	leave  
801068d9:	c3                   	ret    
	...

801068dc <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
801068dc:	1e                   	push   %ds
  pushl %es
801068dd:	06                   	push   %es
  pushl %fs
801068de:	0f a0                	push   %fs
  pushl %gs
801068e0:	0f a8                	push   %gs
  pushal
801068e2:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
801068e3:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
801068e7:	8e d8                	mov    %eax,%ds
  movw %ax, %es
801068e9:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
801068eb:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
801068ef:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
801068f1:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
801068f3:	54                   	push   %esp
  call trap
801068f4:	e8 de 01 00 00       	call   80106ad7 <trap>
  addl $4, %esp
801068f9:	83 c4 04             	add    $0x4,%esp

801068fc <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
801068fc:	61                   	popa   
  popl %gs
801068fd:	0f a9                	pop    %gs
  popl %fs
801068ff:	0f a1                	pop    %fs
  popl %es
80106901:	07                   	pop    %es
  popl %ds
80106902:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80106903:	83 c4 08             	add    $0x8,%esp
  iret
80106906:	cf                   	iret   
	...

80106908 <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
80106908:	55                   	push   %ebp
80106909:	89 e5                	mov    %esp,%ebp
8010690b:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
8010690e:	8b 45 0c             	mov    0xc(%ebp),%eax
80106911:	83 e8 01             	sub    $0x1,%eax
80106914:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80106918:	8b 45 08             	mov    0x8(%ebp),%eax
8010691b:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
8010691f:	8b 45 08             	mov    0x8(%ebp),%eax
80106922:	c1 e8 10             	shr    $0x10,%eax
80106925:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
80106929:	8d 45 fa             	lea    -0x6(%ebp),%eax
8010692c:	0f 01 18             	lidtl  (%eax)
}
8010692f:	c9                   	leave  
80106930:	c3                   	ret    

80106931 <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
80106931:	55                   	push   %ebp
80106932:	89 e5                	mov    %esp,%ebp
80106934:	53                   	push   %ebx
80106935:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
80106938:	0f 20 d3             	mov    %cr2,%ebx
8010693b:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return val;
8010693e:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80106941:	83 c4 10             	add    $0x10,%esp
80106944:	5b                   	pop    %ebx
80106945:	5d                   	pop    %ebp
80106946:	c3                   	ret    

80106947 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
80106947:	55                   	push   %ebp
80106948:	89 e5                	mov    %esp,%ebp
8010694a:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
8010694d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80106954:	e9 c3 00 00 00       	jmp    80106a1c <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80106959:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010695c:	8b 04 85 a0 c0 10 80 	mov    -0x7fef3f60(,%eax,4),%eax
80106963:	89 c2                	mov    %eax,%edx
80106965:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106968:	66 89 14 c5 a0 30 11 	mov    %dx,-0x7feecf60(,%eax,8)
8010696f:	80 
80106970:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106973:	66 c7 04 c5 a2 30 11 	movw   $0x8,-0x7feecf5e(,%eax,8)
8010697a:	80 08 00 
8010697d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106980:	0f b6 14 c5 a4 30 11 	movzbl -0x7feecf5c(,%eax,8),%edx
80106987:	80 
80106988:	83 e2 e0             	and    $0xffffffe0,%edx
8010698b:	88 14 c5 a4 30 11 80 	mov    %dl,-0x7feecf5c(,%eax,8)
80106992:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106995:	0f b6 14 c5 a4 30 11 	movzbl -0x7feecf5c(,%eax,8),%edx
8010699c:	80 
8010699d:	83 e2 1f             	and    $0x1f,%edx
801069a0:	88 14 c5 a4 30 11 80 	mov    %dl,-0x7feecf5c(,%eax,8)
801069a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069aa:	0f b6 14 c5 a5 30 11 	movzbl -0x7feecf5b(,%eax,8),%edx
801069b1:	80 
801069b2:	83 e2 f0             	and    $0xfffffff0,%edx
801069b5:	83 ca 0e             	or     $0xe,%edx
801069b8:	88 14 c5 a5 30 11 80 	mov    %dl,-0x7feecf5b(,%eax,8)
801069bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069c2:	0f b6 14 c5 a5 30 11 	movzbl -0x7feecf5b(,%eax,8),%edx
801069c9:	80 
801069ca:	83 e2 ef             	and    $0xffffffef,%edx
801069cd:	88 14 c5 a5 30 11 80 	mov    %dl,-0x7feecf5b(,%eax,8)
801069d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069d7:	0f b6 14 c5 a5 30 11 	movzbl -0x7feecf5b(,%eax,8),%edx
801069de:	80 
801069df:	83 e2 9f             	and    $0xffffff9f,%edx
801069e2:	88 14 c5 a5 30 11 80 	mov    %dl,-0x7feecf5b(,%eax,8)
801069e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069ec:	0f b6 14 c5 a5 30 11 	movzbl -0x7feecf5b(,%eax,8),%edx
801069f3:	80 
801069f4:	83 ca 80             	or     $0xffffff80,%edx
801069f7:	88 14 c5 a5 30 11 80 	mov    %dl,-0x7feecf5b(,%eax,8)
801069fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a01:	8b 04 85 a0 c0 10 80 	mov    -0x7fef3f60(,%eax,4),%eax
80106a08:	c1 e8 10             	shr    $0x10,%eax
80106a0b:	89 c2                	mov    %eax,%edx
80106a0d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a10:	66 89 14 c5 a6 30 11 	mov    %dx,-0x7feecf5a(,%eax,8)
80106a17:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
80106a18:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106a1c:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
80106a23:	0f 8e 30 ff ff ff    	jle    80106959 <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80106a29:	a1 a0 c1 10 80       	mov    0x8010c1a0,%eax
80106a2e:	66 a3 a0 32 11 80    	mov    %ax,0x801132a0
80106a34:	66 c7 05 a2 32 11 80 	movw   $0x8,0x801132a2
80106a3b:	08 00 
80106a3d:	0f b6 05 a4 32 11 80 	movzbl 0x801132a4,%eax
80106a44:	83 e0 e0             	and    $0xffffffe0,%eax
80106a47:	a2 a4 32 11 80       	mov    %al,0x801132a4
80106a4c:	0f b6 05 a4 32 11 80 	movzbl 0x801132a4,%eax
80106a53:	83 e0 1f             	and    $0x1f,%eax
80106a56:	a2 a4 32 11 80       	mov    %al,0x801132a4
80106a5b:	0f b6 05 a5 32 11 80 	movzbl 0x801132a5,%eax
80106a62:	83 c8 0f             	or     $0xf,%eax
80106a65:	a2 a5 32 11 80       	mov    %al,0x801132a5
80106a6a:	0f b6 05 a5 32 11 80 	movzbl 0x801132a5,%eax
80106a71:	83 e0 ef             	and    $0xffffffef,%eax
80106a74:	a2 a5 32 11 80       	mov    %al,0x801132a5
80106a79:	0f b6 05 a5 32 11 80 	movzbl 0x801132a5,%eax
80106a80:	83 c8 60             	or     $0x60,%eax
80106a83:	a2 a5 32 11 80       	mov    %al,0x801132a5
80106a88:	0f b6 05 a5 32 11 80 	movzbl 0x801132a5,%eax
80106a8f:	83 c8 80             	or     $0xffffff80,%eax
80106a92:	a2 a5 32 11 80       	mov    %al,0x801132a5
80106a97:	a1 a0 c1 10 80       	mov    0x8010c1a0,%eax
80106a9c:	c1 e8 10             	shr    $0x10,%eax
80106a9f:	66 a3 a6 32 11 80    	mov    %ax,0x801132a6
  
  initlock(&tickslock, "time");
80106aa5:	c7 44 24 04 e4 8d 10 	movl   $0x80108de4,0x4(%esp)
80106aac:	80 
80106aad:	c7 04 24 60 30 11 80 	movl   $0x80113060,(%esp)
80106ab4:	e8 d9 e5 ff ff       	call   80105092 <initlock>
}
80106ab9:	c9                   	leave  
80106aba:	c3                   	ret    

80106abb <idtinit>:

void
idtinit(void)
{
80106abb:	55                   	push   %ebp
80106abc:	89 e5                	mov    %esp,%ebp
80106abe:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
80106ac1:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
80106ac8:	00 
80106ac9:	c7 04 24 a0 30 11 80 	movl   $0x801130a0,(%esp)
80106ad0:	e8 33 fe ff ff       	call   80106908 <lidt>
}
80106ad5:	c9                   	leave  
80106ad6:	c3                   	ret    

80106ad7 <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
80106ad7:	55                   	push   %ebp
80106ad8:	89 e5                	mov    %esp,%ebp
80106ada:	57                   	push   %edi
80106adb:	56                   	push   %esi
80106adc:	53                   	push   %ebx
80106add:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
80106ae0:	8b 45 08             	mov    0x8(%ebp),%eax
80106ae3:	8b 40 30             	mov    0x30(%eax),%eax
80106ae6:	83 f8 40             	cmp    $0x40,%eax
80106ae9:	75 3e                	jne    80106b29 <trap+0x52>
    if(proc->killed)
80106aeb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106af1:	8b 40 24             	mov    0x24(%eax),%eax
80106af4:	85 c0                	test   %eax,%eax
80106af6:	74 05                	je     80106afd <trap+0x26>
      exit();
80106af8:	e8 a0 dd ff ff       	call   8010489d <exit>
    proc->tf = tf;
80106afd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106b03:	8b 55 08             	mov    0x8(%ebp),%edx
80106b06:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
80106b09:	e8 59 ec ff ff       	call   80105767 <syscall>
    if(proc->killed)
80106b0e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106b14:	8b 40 24             	mov    0x24(%eax),%eax
80106b17:	85 c0                	test   %eax,%eax
80106b19:	0f 84 34 02 00 00    	je     80106d53 <trap+0x27c>
      exit();
80106b1f:	e8 79 dd ff ff       	call   8010489d <exit>
    return;
80106b24:	e9 2a 02 00 00       	jmp    80106d53 <trap+0x27c>
  }

  switch(tf->trapno){
80106b29:	8b 45 08             	mov    0x8(%ebp),%eax
80106b2c:	8b 40 30             	mov    0x30(%eax),%eax
80106b2f:	83 e8 20             	sub    $0x20,%eax
80106b32:	83 f8 1f             	cmp    $0x1f,%eax
80106b35:	0f 87 bc 00 00 00    	ja     80106bf7 <trap+0x120>
80106b3b:	8b 04 85 8c 8e 10 80 	mov    -0x7fef7174(,%eax,4),%eax
80106b42:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
80106b44:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80106b4a:	0f b6 00             	movzbl (%eax),%eax
80106b4d:	84 c0                	test   %al,%al
80106b4f:	75 31                	jne    80106b82 <trap+0xab>
      acquire(&tickslock);
80106b51:	c7 04 24 60 30 11 80 	movl   $0x80113060,(%esp)
80106b58:	e8 56 e5 ff ff       	call   801050b3 <acquire>
      ticks++;
80106b5d:	a1 a0 38 11 80       	mov    0x801138a0,%eax
80106b62:	83 c0 01             	add    $0x1,%eax
80106b65:	a3 a0 38 11 80       	mov    %eax,0x801138a0
      wakeup(&ticks);
80106b6a:	c7 04 24 a0 38 11 80 	movl   $0x801138a0,(%esp)
80106b71:	e8 32 e3 ff ff       	call   80104ea8 <wakeup>
      release(&tickslock);
80106b76:	c7 04 24 60 30 11 80 	movl   $0x80113060,(%esp)
80106b7d:	e8 cc e5 ff ff       	call   8010514e <release>
    }
    lapiceoi();
80106b82:	e8 6e c3 ff ff       	call   80102ef5 <lapiceoi>
    break;
80106b87:	e9 41 01 00 00       	jmp    80106ccd <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
80106b8c:	e8 60 bb ff ff       	call   801026f1 <ideintr>
    lapiceoi();
80106b91:	e8 5f c3 ff ff       	call   80102ef5 <lapiceoi>
    break;
80106b96:	e9 32 01 00 00       	jmp    80106ccd <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
80106b9b:	e8 33 c1 ff ff       	call   80102cd3 <kbdintr>
    lapiceoi();
80106ba0:	e8 50 c3 ff ff       	call   80102ef5 <lapiceoi>
    break;
80106ba5:	e9 23 01 00 00       	jmp    80106ccd <trap+0x1f6>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
80106baa:	e8 a9 03 00 00       	call   80106f58 <uartintr>
    lapiceoi();
80106baf:	e8 41 c3 ff ff       	call   80102ef5 <lapiceoi>
    break;
80106bb4:	e9 14 01 00 00       	jmp    80106ccd <trap+0x1f6>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
            cpu->id, tf->cs, tf->eip);
80106bb9:	8b 45 08             	mov    0x8(%ebp),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80106bbc:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
80106bbf:	8b 45 08             	mov    0x8(%ebp),%eax
80106bc2:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80106bc6:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
80106bc9:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80106bcf:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80106bd2:	0f b6 c0             	movzbl %al,%eax
80106bd5:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106bd9:	89 54 24 08          	mov    %edx,0x8(%esp)
80106bdd:	89 44 24 04          	mov    %eax,0x4(%esp)
80106be1:	c7 04 24 ec 8d 10 80 	movl   $0x80108dec,(%esp)
80106be8:	e8 b4 97 ff ff       	call   801003a1 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
80106bed:	e8 03 c3 ff ff       	call   80102ef5 <lapiceoi>
    break;
80106bf2:	e9 d6 00 00 00       	jmp    80106ccd <trap+0x1f6>
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
80106bf7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106bfd:	85 c0                	test   %eax,%eax
80106bff:	74 11                	je     80106c12 <trap+0x13b>
80106c01:	8b 45 08             	mov    0x8(%ebp),%eax
80106c04:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106c08:	0f b7 c0             	movzwl %ax,%eax
80106c0b:	83 e0 03             	and    $0x3,%eax
80106c0e:	85 c0                	test   %eax,%eax
80106c10:	75 46                	jne    80106c58 <trap+0x181>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80106c12:	e8 1a fd ff ff       	call   80106931 <rcr2>
              tf->trapno, cpu->id, tf->eip, rcr2());
80106c17:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80106c1a:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
80106c1d:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80106c24:	0f b6 12             	movzbl (%edx),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80106c27:	0f b6 ca             	movzbl %dl,%ecx
              tf->trapno, cpu->id, tf->eip, rcr2());
80106c2a:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80106c2d:	8b 52 30             	mov    0x30(%edx),%edx
80106c30:	89 44 24 10          	mov    %eax,0x10(%esp)
80106c34:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
80106c38:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106c3c:	89 54 24 04          	mov    %edx,0x4(%esp)
80106c40:	c7 04 24 10 8e 10 80 	movl   $0x80108e10,(%esp)
80106c47:	e8 55 97 ff ff       	call   801003a1 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
80106c4c:	c7 04 24 42 8e 10 80 	movl   $0x80108e42,(%esp)
80106c53:	e8 e5 98 ff ff       	call   8010053d <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106c58:	e8 d4 fc ff ff       	call   80106931 <rcr2>
80106c5d:	89 c2                	mov    %eax,%edx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80106c5f:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106c62:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80106c65:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80106c6b:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106c6e:	0f b6 f0             	movzbl %al,%esi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80106c71:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106c74:	8b 58 34             	mov    0x34(%eax),%ebx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80106c77:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106c7a:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80106c7d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106c83:	83 c0 6c             	add    $0x6c,%eax
80106c86:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80106c89:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106c8f:	8b 40 10             	mov    0x10(%eax),%eax
80106c92:	89 54 24 1c          	mov    %edx,0x1c(%esp)
80106c96:	89 7c 24 18          	mov    %edi,0x18(%esp)
80106c9a:	89 74 24 14          	mov    %esi,0x14(%esp)
80106c9e:	89 5c 24 10          	mov    %ebx,0x10(%esp)
80106ca2:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106ca6:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80106ca9:	89 54 24 08          	mov    %edx,0x8(%esp)
80106cad:	89 44 24 04          	mov    %eax,0x4(%esp)
80106cb1:	c7 04 24 48 8e 10 80 	movl   $0x80108e48,(%esp)
80106cb8:	e8 e4 96 ff ff       	call   801003a1 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
80106cbd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106cc3:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
80106cca:	eb 01                	jmp    80106ccd <trap+0x1f6>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
80106ccc:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80106ccd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106cd3:	85 c0                	test   %eax,%eax
80106cd5:	74 24                	je     80106cfb <trap+0x224>
80106cd7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106cdd:	8b 40 24             	mov    0x24(%eax),%eax
80106ce0:	85 c0                	test   %eax,%eax
80106ce2:	74 17                	je     80106cfb <trap+0x224>
80106ce4:	8b 45 08             	mov    0x8(%ebp),%eax
80106ce7:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106ceb:	0f b7 c0             	movzwl %ax,%eax
80106cee:	83 e0 03             	and    $0x3,%eax
80106cf1:	83 f8 03             	cmp    $0x3,%eax
80106cf4:	75 05                	jne    80106cfb <trap+0x224>
    exit();
80106cf6:	e8 a2 db ff ff       	call   8010489d <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
80106cfb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106d01:	85 c0                	test   %eax,%eax
80106d03:	74 1e                	je     80106d23 <trap+0x24c>
80106d05:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106d0b:	8b 40 0c             	mov    0xc(%eax),%eax
80106d0e:	83 f8 04             	cmp    $0x4,%eax
80106d11:	75 10                	jne    80106d23 <trap+0x24c>
80106d13:	8b 45 08             	mov    0x8(%ebp),%eax
80106d16:	8b 40 30             	mov    0x30(%eax),%eax
80106d19:	83 f8 20             	cmp    $0x20,%eax
80106d1c:	75 05                	jne    80106d23 <trap+0x24c>
    yield();
80106d1e:	e8 f3 df ff ff       	call   80104d16 <yield>

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80106d23:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106d29:	85 c0                	test   %eax,%eax
80106d2b:	74 27                	je     80106d54 <trap+0x27d>
80106d2d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106d33:	8b 40 24             	mov    0x24(%eax),%eax
80106d36:	85 c0                	test   %eax,%eax
80106d38:	74 1a                	je     80106d54 <trap+0x27d>
80106d3a:	8b 45 08             	mov    0x8(%ebp),%eax
80106d3d:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106d41:	0f b7 c0             	movzwl %ax,%eax
80106d44:	83 e0 03             	and    $0x3,%eax
80106d47:	83 f8 03             	cmp    $0x3,%eax
80106d4a:	75 08                	jne    80106d54 <trap+0x27d>
    exit();
80106d4c:	e8 4c db ff ff       	call   8010489d <exit>
80106d51:	eb 01                	jmp    80106d54 <trap+0x27d>
      exit();
    proc->tf = tf;
    syscall();
    if(proc->killed)
      exit();
    return;
80106d53:	90                   	nop
    yield();

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
    exit();
}
80106d54:	83 c4 3c             	add    $0x3c,%esp
80106d57:	5b                   	pop    %ebx
80106d58:	5e                   	pop    %esi
80106d59:	5f                   	pop    %edi
80106d5a:	5d                   	pop    %ebp
80106d5b:	c3                   	ret    

80106d5c <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80106d5c:	55                   	push   %ebp
80106d5d:	89 e5                	mov    %esp,%ebp
80106d5f:	53                   	push   %ebx
80106d60:	83 ec 14             	sub    $0x14,%esp
80106d63:	8b 45 08             	mov    0x8(%ebp),%eax
80106d66:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80106d6a:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80106d6e:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80106d72:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80106d76:	ec                   	in     (%dx),%al
80106d77:	89 c3                	mov    %eax,%ebx
80106d79:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80106d7c:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80106d80:	83 c4 14             	add    $0x14,%esp
80106d83:	5b                   	pop    %ebx
80106d84:	5d                   	pop    %ebp
80106d85:	c3                   	ret    

80106d86 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80106d86:	55                   	push   %ebp
80106d87:	89 e5                	mov    %esp,%ebp
80106d89:	83 ec 08             	sub    $0x8,%esp
80106d8c:	8b 55 08             	mov    0x8(%ebp),%edx
80106d8f:	8b 45 0c             	mov    0xc(%ebp),%eax
80106d92:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80106d96:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80106d99:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80106d9d:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80106da1:	ee                   	out    %al,(%dx)
}
80106da2:	c9                   	leave  
80106da3:	c3                   	ret    

80106da4 <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
80106da4:	55                   	push   %ebp
80106da5:	89 e5                	mov    %esp,%ebp
80106da7:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
80106daa:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106db1:	00 
80106db2:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80106db9:	e8 c8 ff ff ff       	call   80106d86 <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
80106dbe:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
80106dc5:	00 
80106dc6:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80106dcd:	e8 b4 ff ff ff       	call   80106d86 <outb>
  outb(COM1+0, 115200/9600);
80106dd2:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
80106dd9:	00 
80106dda:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106de1:	e8 a0 ff ff ff       	call   80106d86 <outb>
  outb(COM1+1, 0);
80106de6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106ded:	00 
80106dee:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80106df5:	e8 8c ff ff ff       	call   80106d86 <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
80106dfa:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80106e01:	00 
80106e02:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80106e09:	e8 78 ff ff ff       	call   80106d86 <outb>
  outb(COM1+4, 0);
80106e0e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106e15:	00 
80106e16:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
80106e1d:	e8 64 ff ff ff       	call   80106d86 <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
80106e22:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80106e29:	00 
80106e2a:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80106e31:	e8 50 ff ff ff       	call   80106d86 <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
80106e36:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106e3d:	e8 1a ff ff ff       	call   80106d5c <inb>
80106e42:	3c ff                	cmp    $0xff,%al
80106e44:	74 6c                	je     80106eb2 <uartinit+0x10e>
    return;
  uart = 1;
80106e46:	c7 05 50 c6 10 80 01 	movl   $0x1,0x8010c650
80106e4d:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
80106e50:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80106e57:	e8 00 ff ff ff       	call   80106d5c <inb>
  inb(COM1+0);
80106e5c:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106e63:	e8 f4 fe ff ff       	call   80106d5c <inb>
  picenable(IRQ_COM1);
80106e68:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80106e6f:	e8 59 cc ff ff       	call   80103acd <picenable>
  ioapicenable(IRQ_COM1, 0);
80106e74:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106e7b:	00 
80106e7c:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80106e83:	e8 fa ba ff ff       	call   80102982 <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80106e88:	c7 45 f4 0c 8f 10 80 	movl   $0x80108f0c,-0xc(%ebp)
80106e8f:	eb 15                	jmp    80106ea6 <uartinit+0x102>
    uartputc(*p);
80106e91:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e94:	0f b6 00             	movzbl (%eax),%eax
80106e97:	0f be c0             	movsbl %al,%eax
80106e9a:	89 04 24             	mov    %eax,(%esp)
80106e9d:	e8 13 00 00 00       	call   80106eb5 <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80106ea2:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106ea6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ea9:	0f b6 00             	movzbl (%eax),%eax
80106eac:	84 c0                	test   %al,%al
80106eae:	75 e1                	jne    80106e91 <uartinit+0xed>
80106eb0:	eb 01                	jmp    80106eb3 <uartinit+0x10f>
  outb(COM1+4, 0);
  outb(COM1+1, 0x01);    // Enable receive interrupts.

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
    return;
80106eb2:	90                   	nop
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
    uartputc(*p);
}
80106eb3:	c9                   	leave  
80106eb4:	c3                   	ret    

80106eb5 <uartputc>:

void
uartputc(int c)
{
80106eb5:	55                   	push   %ebp
80106eb6:	89 e5                	mov    %esp,%ebp
80106eb8:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
80106ebb:	a1 50 c6 10 80       	mov    0x8010c650,%eax
80106ec0:	85 c0                	test   %eax,%eax
80106ec2:	74 4d                	je     80106f11 <uartputc+0x5c>
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80106ec4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80106ecb:	eb 10                	jmp    80106edd <uartputc+0x28>
    microdelay(10);
80106ecd:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
80106ed4:	e8 41 c0 ff ff       	call   80102f1a <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80106ed9:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106edd:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
80106ee1:	7f 16                	jg     80106ef9 <uartputc+0x44>
80106ee3:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106eea:	e8 6d fe ff ff       	call   80106d5c <inb>
80106eef:	0f b6 c0             	movzbl %al,%eax
80106ef2:	83 e0 20             	and    $0x20,%eax
80106ef5:	85 c0                	test   %eax,%eax
80106ef7:	74 d4                	je     80106ecd <uartputc+0x18>
    microdelay(10);
  outb(COM1+0, c);
80106ef9:	8b 45 08             	mov    0x8(%ebp),%eax
80106efc:	0f b6 c0             	movzbl %al,%eax
80106eff:	89 44 24 04          	mov    %eax,0x4(%esp)
80106f03:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106f0a:	e8 77 fe ff ff       	call   80106d86 <outb>
80106f0f:	eb 01                	jmp    80106f12 <uartputc+0x5d>
uartputc(int c)
{
  int i;

  if(!uart)
    return;
80106f11:	90                   	nop
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
    microdelay(10);
  outb(COM1+0, c);
}
80106f12:	c9                   	leave  
80106f13:	c3                   	ret    

80106f14 <uartgetc>:

static int
uartgetc(void)
{
80106f14:	55                   	push   %ebp
80106f15:	89 e5                	mov    %esp,%ebp
80106f17:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
80106f1a:	a1 50 c6 10 80       	mov    0x8010c650,%eax
80106f1f:	85 c0                	test   %eax,%eax
80106f21:	75 07                	jne    80106f2a <uartgetc+0x16>
    return -1;
80106f23:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106f28:	eb 2c                	jmp    80106f56 <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
80106f2a:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106f31:	e8 26 fe ff ff       	call   80106d5c <inb>
80106f36:	0f b6 c0             	movzbl %al,%eax
80106f39:	83 e0 01             	and    $0x1,%eax
80106f3c:	85 c0                	test   %eax,%eax
80106f3e:	75 07                	jne    80106f47 <uartgetc+0x33>
    return -1;
80106f40:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106f45:	eb 0f                	jmp    80106f56 <uartgetc+0x42>
  return inb(COM1+0);
80106f47:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106f4e:	e8 09 fe ff ff       	call   80106d5c <inb>
80106f53:	0f b6 c0             	movzbl %al,%eax
}
80106f56:	c9                   	leave  
80106f57:	c3                   	ret    

80106f58 <uartintr>:

void
uartintr(void)
{
80106f58:	55                   	push   %ebp
80106f59:	89 e5                	mov    %esp,%ebp
80106f5b:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
80106f5e:	c7 04 24 14 6f 10 80 	movl   $0x80106f14,(%esp)
80106f65:	e8 43 98 ff ff       	call   801007ad <consoleintr>
}
80106f6a:	c9                   	leave  
80106f6b:	c3                   	ret    

80106f6c <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80106f6c:	6a 00                	push   $0x0
  pushl $0
80106f6e:	6a 00                	push   $0x0
  jmp alltraps
80106f70:	e9 67 f9 ff ff       	jmp    801068dc <alltraps>

80106f75 <vector1>:
.globl vector1
vector1:
  pushl $0
80106f75:	6a 00                	push   $0x0
  pushl $1
80106f77:	6a 01                	push   $0x1
  jmp alltraps
80106f79:	e9 5e f9 ff ff       	jmp    801068dc <alltraps>

80106f7e <vector2>:
.globl vector2
vector2:
  pushl $0
80106f7e:	6a 00                	push   $0x0
  pushl $2
80106f80:	6a 02                	push   $0x2
  jmp alltraps
80106f82:	e9 55 f9 ff ff       	jmp    801068dc <alltraps>

80106f87 <vector3>:
.globl vector3
vector3:
  pushl $0
80106f87:	6a 00                	push   $0x0
  pushl $3
80106f89:	6a 03                	push   $0x3
  jmp alltraps
80106f8b:	e9 4c f9 ff ff       	jmp    801068dc <alltraps>

80106f90 <vector4>:
.globl vector4
vector4:
  pushl $0
80106f90:	6a 00                	push   $0x0
  pushl $4
80106f92:	6a 04                	push   $0x4
  jmp alltraps
80106f94:	e9 43 f9 ff ff       	jmp    801068dc <alltraps>

80106f99 <vector5>:
.globl vector5
vector5:
  pushl $0
80106f99:	6a 00                	push   $0x0
  pushl $5
80106f9b:	6a 05                	push   $0x5
  jmp alltraps
80106f9d:	e9 3a f9 ff ff       	jmp    801068dc <alltraps>

80106fa2 <vector6>:
.globl vector6
vector6:
  pushl $0
80106fa2:	6a 00                	push   $0x0
  pushl $6
80106fa4:	6a 06                	push   $0x6
  jmp alltraps
80106fa6:	e9 31 f9 ff ff       	jmp    801068dc <alltraps>

80106fab <vector7>:
.globl vector7
vector7:
  pushl $0
80106fab:	6a 00                	push   $0x0
  pushl $7
80106fad:	6a 07                	push   $0x7
  jmp alltraps
80106faf:	e9 28 f9 ff ff       	jmp    801068dc <alltraps>

80106fb4 <vector8>:
.globl vector8
vector8:
  pushl $8
80106fb4:	6a 08                	push   $0x8
  jmp alltraps
80106fb6:	e9 21 f9 ff ff       	jmp    801068dc <alltraps>

80106fbb <vector9>:
.globl vector9
vector9:
  pushl $0
80106fbb:	6a 00                	push   $0x0
  pushl $9
80106fbd:	6a 09                	push   $0x9
  jmp alltraps
80106fbf:	e9 18 f9 ff ff       	jmp    801068dc <alltraps>

80106fc4 <vector10>:
.globl vector10
vector10:
  pushl $10
80106fc4:	6a 0a                	push   $0xa
  jmp alltraps
80106fc6:	e9 11 f9 ff ff       	jmp    801068dc <alltraps>

80106fcb <vector11>:
.globl vector11
vector11:
  pushl $11
80106fcb:	6a 0b                	push   $0xb
  jmp alltraps
80106fcd:	e9 0a f9 ff ff       	jmp    801068dc <alltraps>

80106fd2 <vector12>:
.globl vector12
vector12:
  pushl $12
80106fd2:	6a 0c                	push   $0xc
  jmp alltraps
80106fd4:	e9 03 f9 ff ff       	jmp    801068dc <alltraps>

80106fd9 <vector13>:
.globl vector13
vector13:
  pushl $13
80106fd9:	6a 0d                	push   $0xd
  jmp alltraps
80106fdb:	e9 fc f8 ff ff       	jmp    801068dc <alltraps>

80106fe0 <vector14>:
.globl vector14
vector14:
  pushl $14
80106fe0:	6a 0e                	push   $0xe
  jmp alltraps
80106fe2:	e9 f5 f8 ff ff       	jmp    801068dc <alltraps>

80106fe7 <vector15>:
.globl vector15
vector15:
  pushl $0
80106fe7:	6a 00                	push   $0x0
  pushl $15
80106fe9:	6a 0f                	push   $0xf
  jmp alltraps
80106feb:	e9 ec f8 ff ff       	jmp    801068dc <alltraps>

80106ff0 <vector16>:
.globl vector16
vector16:
  pushl $0
80106ff0:	6a 00                	push   $0x0
  pushl $16
80106ff2:	6a 10                	push   $0x10
  jmp alltraps
80106ff4:	e9 e3 f8 ff ff       	jmp    801068dc <alltraps>

80106ff9 <vector17>:
.globl vector17
vector17:
  pushl $17
80106ff9:	6a 11                	push   $0x11
  jmp alltraps
80106ffb:	e9 dc f8 ff ff       	jmp    801068dc <alltraps>

80107000 <vector18>:
.globl vector18
vector18:
  pushl $0
80107000:	6a 00                	push   $0x0
  pushl $18
80107002:	6a 12                	push   $0x12
  jmp alltraps
80107004:	e9 d3 f8 ff ff       	jmp    801068dc <alltraps>

80107009 <vector19>:
.globl vector19
vector19:
  pushl $0
80107009:	6a 00                	push   $0x0
  pushl $19
8010700b:	6a 13                	push   $0x13
  jmp alltraps
8010700d:	e9 ca f8 ff ff       	jmp    801068dc <alltraps>

80107012 <vector20>:
.globl vector20
vector20:
  pushl $0
80107012:	6a 00                	push   $0x0
  pushl $20
80107014:	6a 14                	push   $0x14
  jmp alltraps
80107016:	e9 c1 f8 ff ff       	jmp    801068dc <alltraps>

8010701b <vector21>:
.globl vector21
vector21:
  pushl $0
8010701b:	6a 00                	push   $0x0
  pushl $21
8010701d:	6a 15                	push   $0x15
  jmp alltraps
8010701f:	e9 b8 f8 ff ff       	jmp    801068dc <alltraps>

80107024 <vector22>:
.globl vector22
vector22:
  pushl $0
80107024:	6a 00                	push   $0x0
  pushl $22
80107026:	6a 16                	push   $0x16
  jmp alltraps
80107028:	e9 af f8 ff ff       	jmp    801068dc <alltraps>

8010702d <vector23>:
.globl vector23
vector23:
  pushl $0
8010702d:	6a 00                	push   $0x0
  pushl $23
8010702f:	6a 17                	push   $0x17
  jmp alltraps
80107031:	e9 a6 f8 ff ff       	jmp    801068dc <alltraps>

80107036 <vector24>:
.globl vector24
vector24:
  pushl $0
80107036:	6a 00                	push   $0x0
  pushl $24
80107038:	6a 18                	push   $0x18
  jmp alltraps
8010703a:	e9 9d f8 ff ff       	jmp    801068dc <alltraps>

8010703f <vector25>:
.globl vector25
vector25:
  pushl $0
8010703f:	6a 00                	push   $0x0
  pushl $25
80107041:	6a 19                	push   $0x19
  jmp alltraps
80107043:	e9 94 f8 ff ff       	jmp    801068dc <alltraps>

80107048 <vector26>:
.globl vector26
vector26:
  pushl $0
80107048:	6a 00                	push   $0x0
  pushl $26
8010704a:	6a 1a                	push   $0x1a
  jmp alltraps
8010704c:	e9 8b f8 ff ff       	jmp    801068dc <alltraps>

80107051 <vector27>:
.globl vector27
vector27:
  pushl $0
80107051:	6a 00                	push   $0x0
  pushl $27
80107053:	6a 1b                	push   $0x1b
  jmp alltraps
80107055:	e9 82 f8 ff ff       	jmp    801068dc <alltraps>

8010705a <vector28>:
.globl vector28
vector28:
  pushl $0
8010705a:	6a 00                	push   $0x0
  pushl $28
8010705c:	6a 1c                	push   $0x1c
  jmp alltraps
8010705e:	e9 79 f8 ff ff       	jmp    801068dc <alltraps>

80107063 <vector29>:
.globl vector29
vector29:
  pushl $0
80107063:	6a 00                	push   $0x0
  pushl $29
80107065:	6a 1d                	push   $0x1d
  jmp alltraps
80107067:	e9 70 f8 ff ff       	jmp    801068dc <alltraps>

8010706c <vector30>:
.globl vector30
vector30:
  pushl $0
8010706c:	6a 00                	push   $0x0
  pushl $30
8010706e:	6a 1e                	push   $0x1e
  jmp alltraps
80107070:	e9 67 f8 ff ff       	jmp    801068dc <alltraps>

80107075 <vector31>:
.globl vector31
vector31:
  pushl $0
80107075:	6a 00                	push   $0x0
  pushl $31
80107077:	6a 1f                	push   $0x1f
  jmp alltraps
80107079:	e9 5e f8 ff ff       	jmp    801068dc <alltraps>

8010707e <vector32>:
.globl vector32
vector32:
  pushl $0
8010707e:	6a 00                	push   $0x0
  pushl $32
80107080:	6a 20                	push   $0x20
  jmp alltraps
80107082:	e9 55 f8 ff ff       	jmp    801068dc <alltraps>

80107087 <vector33>:
.globl vector33
vector33:
  pushl $0
80107087:	6a 00                	push   $0x0
  pushl $33
80107089:	6a 21                	push   $0x21
  jmp alltraps
8010708b:	e9 4c f8 ff ff       	jmp    801068dc <alltraps>

80107090 <vector34>:
.globl vector34
vector34:
  pushl $0
80107090:	6a 00                	push   $0x0
  pushl $34
80107092:	6a 22                	push   $0x22
  jmp alltraps
80107094:	e9 43 f8 ff ff       	jmp    801068dc <alltraps>

80107099 <vector35>:
.globl vector35
vector35:
  pushl $0
80107099:	6a 00                	push   $0x0
  pushl $35
8010709b:	6a 23                	push   $0x23
  jmp alltraps
8010709d:	e9 3a f8 ff ff       	jmp    801068dc <alltraps>

801070a2 <vector36>:
.globl vector36
vector36:
  pushl $0
801070a2:	6a 00                	push   $0x0
  pushl $36
801070a4:	6a 24                	push   $0x24
  jmp alltraps
801070a6:	e9 31 f8 ff ff       	jmp    801068dc <alltraps>

801070ab <vector37>:
.globl vector37
vector37:
  pushl $0
801070ab:	6a 00                	push   $0x0
  pushl $37
801070ad:	6a 25                	push   $0x25
  jmp alltraps
801070af:	e9 28 f8 ff ff       	jmp    801068dc <alltraps>

801070b4 <vector38>:
.globl vector38
vector38:
  pushl $0
801070b4:	6a 00                	push   $0x0
  pushl $38
801070b6:	6a 26                	push   $0x26
  jmp alltraps
801070b8:	e9 1f f8 ff ff       	jmp    801068dc <alltraps>

801070bd <vector39>:
.globl vector39
vector39:
  pushl $0
801070bd:	6a 00                	push   $0x0
  pushl $39
801070bf:	6a 27                	push   $0x27
  jmp alltraps
801070c1:	e9 16 f8 ff ff       	jmp    801068dc <alltraps>

801070c6 <vector40>:
.globl vector40
vector40:
  pushl $0
801070c6:	6a 00                	push   $0x0
  pushl $40
801070c8:	6a 28                	push   $0x28
  jmp alltraps
801070ca:	e9 0d f8 ff ff       	jmp    801068dc <alltraps>

801070cf <vector41>:
.globl vector41
vector41:
  pushl $0
801070cf:	6a 00                	push   $0x0
  pushl $41
801070d1:	6a 29                	push   $0x29
  jmp alltraps
801070d3:	e9 04 f8 ff ff       	jmp    801068dc <alltraps>

801070d8 <vector42>:
.globl vector42
vector42:
  pushl $0
801070d8:	6a 00                	push   $0x0
  pushl $42
801070da:	6a 2a                	push   $0x2a
  jmp alltraps
801070dc:	e9 fb f7 ff ff       	jmp    801068dc <alltraps>

801070e1 <vector43>:
.globl vector43
vector43:
  pushl $0
801070e1:	6a 00                	push   $0x0
  pushl $43
801070e3:	6a 2b                	push   $0x2b
  jmp alltraps
801070e5:	e9 f2 f7 ff ff       	jmp    801068dc <alltraps>

801070ea <vector44>:
.globl vector44
vector44:
  pushl $0
801070ea:	6a 00                	push   $0x0
  pushl $44
801070ec:	6a 2c                	push   $0x2c
  jmp alltraps
801070ee:	e9 e9 f7 ff ff       	jmp    801068dc <alltraps>

801070f3 <vector45>:
.globl vector45
vector45:
  pushl $0
801070f3:	6a 00                	push   $0x0
  pushl $45
801070f5:	6a 2d                	push   $0x2d
  jmp alltraps
801070f7:	e9 e0 f7 ff ff       	jmp    801068dc <alltraps>

801070fc <vector46>:
.globl vector46
vector46:
  pushl $0
801070fc:	6a 00                	push   $0x0
  pushl $46
801070fe:	6a 2e                	push   $0x2e
  jmp alltraps
80107100:	e9 d7 f7 ff ff       	jmp    801068dc <alltraps>

80107105 <vector47>:
.globl vector47
vector47:
  pushl $0
80107105:	6a 00                	push   $0x0
  pushl $47
80107107:	6a 2f                	push   $0x2f
  jmp alltraps
80107109:	e9 ce f7 ff ff       	jmp    801068dc <alltraps>

8010710e <vector48>:
.globl vector48
vector48:
  pushl $0
8010710e:	6a 00                	push   $0x0
  pushl $48
80107110:	6a 30                	push   $0x30
  jmp alltraps
80107112:	e9 c5 f7 ff ff       	jmp    801068dc <alltraps>

80107117 <vector49>:
.globl vector49
vector49:
  pushl $0
80107117:	6a 00                	push   $0x0
  pushl $49
80107119:	6a 31                	push   $0x31
  jmp alltraps
8010711b:	e9 bc f7 ff ff       	jmp    801068dc <alltraps>

80107120 <vector50>:
.globl vector50
vector50:
  pushl $0
80107120:	6a 00                	push   $0x0
  pushl $50
80107122:	6a 32                	push   $0x32
  jmp alltraps
80107124:	e9 b3 f7 ff ff       	jmp    801068dc <alltraps>

80107129 <vector51>:
.globl vector51
vector51:
  pushl $0
80107129:	6a 00                	push   $0x0
  pushl $51
8010712b:	6a 33                	push   $0x33
  jmp alltraps
8010712d:	e9 aa f7 ff ff       	jmp    801068dc <alltraps>

80107132 <vector52>:
.globl vector52
vector52:
  pushl $0
80107132:	6a 00                	push   $0x0
  pushl $52
80107134:	6a 34                	push   $0x34
  jmp alltraps
80107136:	e9 a1 f7 ff ff       	jmp    801068dc <alltraps>

8010713b <vector53>:
.globl vector53
vector53:
  pushl $0
8010713b:	6a 00                	push   $0x0
  pushl $53
8010713d:	6a 35                	push   $0x35
  jmp alltraps
8010713f:	e9 98 f7 ff ff       	jmp    801068dc <alltraps>

80107144 <vector54>:
.globl vector54
vector54:
  pushl $0
80107144:	6a 00                	push   $0x0
  pushl $54
80107146:	6a 36                	push   $0x36
  jmp alltraps
80107148:	e9 8f f7 ff ff       	jmp    801068dc <alltraps>

8010714d <vector55>:
.globl vector55
vector55:
  pushl $0
8010714d:	6a 00                	push   $0x0
  pushl $55
8010714f:	6a 37                	push   $0x37
  jmp alltraps
80107151:	e9 86 f7 ff ff       	jmp    801068dc <alltraps>

80107156 <vector56>:
.globl vector56
vector56:
  pushl $0
80107156:	6a 00                	push   $0x0
  pushl $56
80107158:	6a 38                	push   $0x38
  jmp alltraps
8010715a:	e9 7d f7 ff ff       	jmp    801068dc <alltraps>

8010715f <vector57>:
.globl vector57
vector57:
  pushl $0
8010715f:	6a 00                	push   $0x0
  pushl $57
80107161:	6a 39                	push   $0x39
  jmp alltraps
80107163:	e9 74 f7 ff ff       	jmp    801068dc <alltraps>

80107168 <vector58>:
.globl vector58
vector58:
  pushl $0
80107168:	6a 00                	push   $0x0
  pushl $58
8010716a:	6a 3a                	push   $0x3a
  jmp alltraps
8010716c:	e9 6b f7 ff ff       	jmp    801068dc <alltraps>

80107171 <vector59>:
.globl vector59
vector59:
  pushl $0
80107171:	6a 00                	push   $0x0
  pushl $59
80107173:	6a 3b                	push   $0x3b
  jmp alltraps
80107175:	e9 62 f7 ff ff       	jmp    801068dc <alltraps>

8010717a <vector60>:
.globl vector60
vector60:
  pushl $0
8010717a:	6a 00                	push   $0x0
  pushl $60
8010717c:	6a 3c                	push   $0x3c
  jmp alltraps
8010717e:	e9 59 f7 ff ff       	jmp    801068dc <alltraps>

80107183 <vector61>:
.globl vector61
vector61:
  pushl $0
80107183:	6a 00                	push   $0x0
  pushl $61
80107185:	6a 3d                	push   $0x3d
  jmp alltraps
80107187:	e9 50 f7 ff ff       	jmp    801068dc <alltraps>

8010718c <vector62>:
.globl vector62
vector62:
  pushl $0
8010718c:	6a 00                	push   $0x0
  pushl $62
8010718e:	6a 3e                	push   $0x3e
  jmp alltraps
80107190:	e9 47 f7 ff ff       	jmp    801068dc <alltraps>

80107195 <vector63>:
.globl vector63
vector63:
  pushl $0
80107195:	6a 00                	push   $0x0
  pushl $63
80107197:	6a 3f                	push   $0x3f
  jmp alltraps
80107199:	e9 3e f7 ff ff       	jmp    801068dc <alltraps>

8010719e <vector64>:
.globl vector64
vector64:
  pushl $0
8010719e:	6a 00                	push   $0x0
  pushl $64
801071a0:	6a 40                	push   $0x40
  jmp alltraps
801071a2:	e9 35 f7 ff ff       	jmp    801068dc <alltraps>

801071a7 <vector65>:
.globl vector65
vector65:
  pushl $0
801071a7:	6a 00                	push   $0x0
  pushl $65
801071a9:	6a 41                	push   $0x41
  jmp alltraps
801071ab:	e9 2c f7 ff ff       	jmp    801068dc <alltraps>

801071b0 <vector66>:
.globl vector66
vector66:
  pushl $0
801071b0:	6a 00                	push   $0x0
  pushl $66
801071b2:	6a 42                	push   $0x42
  jmp alltraps
801071b4:	e9 23 f7 ff ff       	jmp    801068dc <alltraps>

801071b9 <vector67>:
.globl vector67
vector67:
  pushl $0
801071b9:	6a 00                	push   $0x0
  pushl $67
801071bb:	6a 43                	push   $0x43
  jmp alltraps
801071bd:	e9 1a f7 ff ff       	jmp    801068dc <alltraps>

801071c2 <vector68>:
.globl vector68
vector68:
  pushl $0
801071c2:	6a 00                	push   $0x0
  pushl $68
801071c4:	6a 44                	push   $0x44
  jmp alltraps
801071c6:	e9 11 f7 ff ff       	jmp    801068dc <alltraps>

801071cb <vector69>:
.globl vector69
vector69:
  pushl $0
801071cb:	6a 00                	push   $0x0
  pushl $69
801071cd:	6a 45                	push   $0x45
  jmp alltraps
801071cf:	e9 08 f7 ff ff       	jmp    801068dc <alltraps>

801071d4 <vector70>:
.globl vector70
vector70:
  pushl $0
801071d4:	6a 00                	push   $0x0
  pushl $70
801071d6:	6a 46                	push   $0x46
  jmp alltraps
801071d8:	e9 ff f6 ff ff       	jmp    801068dc <alltraps>

801071dd <vector71>:
.globl vector71
vector71:
  pushl $0
801071dd:	6a 00                	push   $0x0
  pushl $71
801071df:	6a 47                	push   $0x47
  jmp alltraps
801071e1:	e9 f6 f6 ff ff       	jmp    801068dc <alltraps>

801071e6 <vector72>:
.globl vector72
vector72:
  pushl $0
801071e6:	6a 00                	push   $0x0
  pushl $72
801071e8:	6a 48                	push   $0x48
  jmp alltraps
801071ea:	e9 ed f6 ff ff       	jmp    801068dc <alltraps>

801071ef <vector73>:
.globl vector73
vector73:
  pushl $0
801071ef:	6a 00                	push   $0x0
  pushl $73
801071f1:	6a 49                	push   $0x49
  jmp alltraps
801071f3:	e9 e4 f6 ff ff       	jmp    801068dc <alltraps>

801071f8 <vector74>:
.globl vector74
vector74:
  pushl $0
801071f8:	6a 00                	push   $0x0
  pushl $74
801071fa:	6a 4a                	push   $0x4a
  jmp alltraps
801071fc:	e9 db f6 ff ff       	jmp    801068dc <alltraps>

80107201 <vector75>:
.globl vector75
vector75:
  pushl $0
80107201:	6a 00                	push   $0x0
  pushl $75
80107203:	6a 4b                	push   $0x4b
  jmp alltraps
80107205:	e9 d2 f6 ff ff       	jmp    801068dc <alltraps>

8010720a <vector76>:
.globl vector76
vector76:
  pushl $0
8010720a:	6a 00                	push   $0x0
  pushl $76
8010720c:	6a 4c                	push   $0x4c
  jmp alltraps
8010720e:	e9 c9 f6 ff ff       	jmp    801068dc <alltraps>

80107213 <vector77>:
.globl vector77
vector77:
  pushl $0
80107213:	6a 00                	push   $0x0
  pushl $77
80107215:	6a 4d                	push   $0x4d
  jmp alltraps
80107217:	e9 c0 f6 ff ff       	jmp    801068dc <alltraps>

8010721c <vector78>:
.globl vector78
vector78:
  pushl $0
8010721c:	6a 00                	push   $0x0
  pushl $78
8010721e:	6a 4e                	push   $0x4e
  jmp alltraps
80107220:	e9 b7 f6 ff ff       	jmp    801068dc <alltraps>

80107225 <vector79>:
.globl vector79
vector79:
  pushl $0
80107225:	6a 00                	push   $0x0
  pushl $79
80107227:	6a 4f                	push   $0x4f
  jmp alltraps
80107229:	e9 ae f6 ff ff       	jmp    801068dc <alltraps>

8010722e <vector80>:
.globl vector80
vector80:
  pushl $0
8010722e:	6a 00                	push   $0x0
  pushl $80
80107230:	6a 50                	push   $0x50
  jmp alltraps
80107232:	e9 a5 f6 ff ff       	jmp    801068dc <alltraps>

80107237 <vector81>:
.globl vector81
vector81:
  pushl $0
80107237:	6a 00                	push   $0x0
  pushl $81
80107239:	6a 51                	push   $0x51
  jmp alltraps
8010723b:	e9 9c f6 ff ff       	jmp    801068dc <alltraps>

80107240 <vector82>:
.globl vector82
vector82:
  pushl $0
80107240:	6a 00                	push   $0x0
  pushl $82
80107242:	6a 52                	push   $0x52
  jmp alltraps
80107244:	e9 93 f6 ff ff       	jmp    801068dc <alltraps>

80107249 <vector83>:
.globl vector83
vector83:
  pushl $0
80107249:	6a 00                	push   $0x0
  pushl $83
8010724b:	6a 53                	push   $0x53
  jmp alltraps
8010724d:	e9 8a f6 ff ff       	jmp    801068dc <alltraps>

80107252 <vector84>:
.globl vector84
vector84:
  pushl $0
80107252:	6a 00                	push   $0x0
  pushl $84
80107254:	6a 54                	push   $0x54
  jmp alltraps
80107256:	e9 81 f6 ff ff       	jmp    801068dc <alltraps>

8010725b <vector85>:
.globl vector85
vector85:
  pushl $0
8010725b:	6a 00                	push   $0x0
  pushl $85
8010725d:	6a 55                	push   $0x55
  jmp alltraps
8010725f:	e9 78 f6 ff ff       	jmp    801068dc <alltraps>

80107264 <vector86>:
.globl vector86
vector86:
  pushl $0
80107264:	6a 00                	push   $0x0
  pushl $86
80107266:	6a 56                	push   $0x56
  jmp alltraps
80107268:	e9 6f f6 ff ff       	jmp    801068dc <alltraps>

8010726d <vector87>:
.globl vector87
vector87:
  pushl $0
8010726d:	6a 00                	push   $0x0
  pushl $87
8010726f:	6a 57                	push   $0x57
  jmp alltraps
80107271:	e9 66 f6 ff ff       	jmp    801068dc <alltraps>

80107276 <vector88>:
.globl vector88
vector88:
  pushl $0
80107276:	6a 00                	push   $0x0
  pushl $88
80107278:	6a 58                	push   $0x58
  jmp alltraps
8010727a:	e9 5d f6 ff ff       	jmp    801068dc <alltraps>

8010727f <vector89>:
.globl vector89
vector89:
  pushl $0
8010727f:	6a 00                	push   $0x0
  pushl $89
80107281:	6a 59                	push   $0x59
  jmp alltraps
80107283:	e9 54 f6 ff ff       	jmp    801068dc <alltraps>

80107288 <vector90>:
.globl vector90
vector90:
  pushl $0
80107288:	6a 00                	push   $0x0
  pushl $90
8010728a:	6a 5a                	push   $0x5a
  jmp alltraps
8010728c:	e9 4b f6 ff ff       	jmp    801068dc <alltraps>

80107291 <vector91>:
.globl vector91
vector91:
  pushl $0
80107291:	6a 00                	push   $0x0
  pushl $91
80107293:	6a 5b                	push   $0x5b
  jmp alltraps
80107295:	e9 42 f6 ff ff       	jmp    801068dc <alltraps>

8010729a <vector92>:
.globl vector92
vector92:
  pushl $0
8010729a:	6a 00                	push   $0x0
  pushl $92
8010729c:	6a 5c                	push   $0x5c
  jmp alltraps
8010729e:	e9 39 f6 ff ff       	jmp    801068dc <alltraps>

801072a3 <vector93>:
.globl vector93
vector93:
  pushl $0
801072a3:	6a 00                	push   $0x0
  pushl $93
801072a5:	6a 5d                	push   $0x5d
  jmp alltraps
801072a7:	e9 30 f6 ff ff       	jmp    801068dc <alltraps>

801072ac <vector94>:
.globl vector94
vector94:
  pushl $0
801072ac:	6a 00                	push   $0x0
  pushl $94
801072ae:	6a 5e                	push   $0x5e
  jmp alltraps
801072b0:	e9 27 f6 ff ff       	jmp    801068dc <alltraps>

801072b5 <vector95>:
.globl vector95
vector95:
  pushl $0
801072b5:	6a 00                	push   $0x0
  pushl $95
801072b7:	6a 5f                	push   $0x5f
  jmp alltraps
801072b9:	e9 1e f6 ff ff       	jmp    801068dc <alltraps>

801072be <vector96>:
.globl vector96
vector96:
  pushl $0
801072be:	6a 00                	push   $0x0
  pushl $96
801072c0:	6a 60                	push   $0x60
  jmp alltraps
801072c2:	e9 15 f6 ff ff       	jmp    801068dc <alltraps>

801072c7 <vector97>:
.globl vector97
vector97:
  pushl $0
801072c7:	6a 00                	push   $0x0
  pushl $97
801072c9:	6a 61                	push   $0x61
  jmp alltraps
801072cb:	e9 0c f6 ff ff       	jmp    801068dc <alltraps>

801072d0 <vector98>:
.globl vector98
vector98:
  pushl $0
801072d0:	6a 00                	push   $0x0
  pushl $98
801072d2:	6a 62                	push   $0x62
  jmp alltraps
801072d4:	e9 03 f6 ff ff       	jmp    801068dc <alltraps>

801072d9 <vector99>:
.globl vector99
vector99:
  pushl $0
801072d9:	6a 00                	push   $0x0
  pushl $99
801072db:	6a 63                	push   $0x63
  jmp alltraps
801072dd:	e9 fa f5 ff ff       	jmp    801068dc <alltraps>

801072e2 <vector100>:
.globl vector100
vector100:
  pushl $0
801072e2:	6a 00                	push   $0x0
  pushl $100
801072e4:	6a 64                	push   $0x64
  jmp alltraps
801072e6:	e9 f1 f5 ff ff       	jmp    801068dc <alltraps>

801072eb <vector101>:
.globl vector101
vector101:
  pushl $0
801072eb:	6a 00                	push   $0x0
  pushl $101
801072ed:	6a 65                	push   $0x65
  jmp alltraps
801072ef:	e9 e8 f5 ff ff       	jmp    801068dc <alltraps>

801072f4 <vector102>:
.globl vector102
vector102:
  pushl $0
801072f4:	6a 00                	push   $0x0
  pushl $102
801072f6:	6a 66                	push   $0x66
  jmp alltraps
801072f8:	e9 df f5 ff ff       	jmp    801068dc <alltraps>

801072fd <vector103>:
.globl vector103
vector103:
  pushl $0
801072fd:	6a 00                	push   $0x0
  pushl $103
801072ff:	6a 67                	push   $0x67
  jmp alltraps
80107301:	e9 d6 f5 ff ff       	jmp    801068dc <alltraps>

80107306 <vector104>:
.globl vector104
vector104:
  pushl $0
80107306:	6a 00                	push   $0x0
  pushl $104
80107308:	6a 68                	push   $0x68
  jmp alltraps
8010730a:	e9 cd f5 ff ff       	jmp    801068dc <alltraps>

8010730f <vector105>:
.globl vector105
vector105:
  pushl $0
8010730f:	6a 00                	push   $0x0
  pushl $105
80107311:	6a 69                	push   $0x69
  jmp alltraps
80107313:	e9 c4 f5 ff ff       	jmp    801068dc <alltraps>

80107318 <vector106>:
.globl vector106
vector106:
  pushl $0
80107318:	6a 00                	push   $0x0
  pushl $106
8010731a:	6a 6a                	push   $0x6a
  jmp alltraps
8010731c:	e9 bb f5 ff ff       	jmp    801068dc <alltraps>

80107321 <vector107>:
.globl vector107
vector107:
  pushl $0
80107321:	6a 00                	push   $0x0
  pushl $107
80107323:	6a 6b                	push   $0x6b
  jmp alltraps
80107325:	e9 b2 f5 ff ff       	jmp    801068dc <alltraps>

8010732a <vector108>:
.globl vector108
vector108:
  pushl $0
8010732a:	6a 00                	push   $0x0
  pushl $108
8010732c:	6a 6c                	push   $0x6c
  jmp alltraps
8010732e:	e9 a9 f5 ff ff       	jmp    801068dc <alltraps>

80107333 <vector109>:
.globl vector109
vector109:
  pushl $0
80107333:	6a 00                	push   $0x0
  pushl $109
80107335:	6a 6d                	push   $0x6d
  jmp alltraps
80107337:	e9 a0 f5 ff ff       	jmp    801068dc <alltraps>

8010733c <vector110>:
.globl vector110
vector110:
  pushl $0
8010733c:	6a 00                	push   $0x0
  pushl $110
8010733e:	6a 6e                	push   $0x6e
  jmp alltraps
80107340:	e9 97 f5 ff ff       	jmp    801068dc <alltraps>

80107345 <vector111>:
.globl vector111
vector111:
  pushl $0
80107345:	6a 00                	push   $0x0
  pushl $111
80107347:	6a 6f                	push   $0x6f
  jmp alltraps
80107349:	e9 8e f5 ff ff       	jmp    801068dc <alltraps>

8010734e <vector112>:
.globl vector112
vector112:
  pushl $0
8010734e:	6a 00                	push   $0x0
  pushl $112
80107350:	6a 70                	push   $0x70
  jmp alltraps
80107352:	e9 85 f5 ff ff       	jmp    801068dc <alltraps>

80107357 <vector113>:
.globl vector113
vector113:
  pushl $0
80107357:	6a 00                	push   $0x0
  pushl $113
80107359:	6a 71                	push   $0x71
  jmp alltraps
8010735b:	e9 7c f5 ff ff       	jmp    801068dc <alltraps>

80107360 <vector114>:
.globl vector114
vector114:
  pushl $0
80107360:	6a 00                	push   $0x0
  pushl $114
80107362:	6a 72                	push   $0x72
  jmp alltraps
80107364:	e9 73 f5 ff ff       	jmp    801068dc <alltraps>

80107369 <vector115>:
.globl vector115
vector115:
  pushl $0
80107369:	6a 00                	push   $0x0
  pushl $115
8010736b:	6a 73                	push   $0x73
  jmp alltraps
8010736d:	e9 6a f5 ff ff       	jmp    801068dc <alltraps>

80107372 <vector116>:
.globl vector116
vector116:
  pushl $0
80107372:	6a 00                	push   $0x0
  pushl $116
80107374:	6a 74                	push   $0x74
  jmp alltraps
80107376:	e9 61 f5 ff ff       	jmp    801068dc <alltraps>

8010737b <vector117>:
.globl vector117
vector117:
  pushl $0
8010737b:	6a 00                	push   $0x0
  pushl $117
8010737d:	6a 75                	push   $0x75
  jmp alltraps
8010737f:	e9 58 f5 ff ff       	jmp    801068dc <alltraps>

80107384 <vector118>:
.globl vector118
vector118:
  pushl $0
80107384:	6a 00                	push   $0x0
  pushl $118
80107386:	6a 76                	push   $0x76
  jmp alltraps
80107388:	e9 4f f5 ff ff       	jmp    801068dc <alltraps>

8010738d <vector119>:
.globl vector119
vector119:
  pushl $0
8010738d:	6a 00                	push   $0x0
  pushl $119
8010738f:	6a 77                	push   $0x77
  jmp alltraps
80107391:	e9 46 f5 ff ff       	jmp    801068dc <alltraps>

80107396 <vector120>:
.globl vector120
vector120:
  pushl $0
80107396:	6a 00                	push   $0x0
  pushl $120
80107398:	6a 78                	push   $0x78
  jmp alltraps
8010739a:	e9 3d f5 ff ff       	jmp    801068dc <alltraps>

8010739f <vector121>:
.globl vector121
vector121:
  pushl $0
8010739f:	6a 00                	push   $0x0
  pushl $121
801073a1:	6a 79                	push   $0x79
  jmp alltraps
801073a3:	e9 34 f5 ff ff       	jmp    801068dc <alltraps>

801073a8 <vector122>:
.globl vector122
vector122:
  pushl $0
801073a8:	6a 00                	push   $0x0
  pushl $122
801073aa:	6a 7a                	push   $0x7a
  jmp alltraps
801073ac:	e9 2b f5 ff ff       	jmp    801068dc <alltraps>

801073b1 <vector123>:
.globl vector123
vector123:
  pushl $0
801073b1:	6a 00                	push   $0x0
  pushl $123
801073b3:	6a 7b                	push   $0x7b
  jmp alltraps
801073b5:	e9 22 f5 ff ff       	jmp    801068dc <alltraps>

801073ba <vector124>:
.globl vector124
vector124:
  pushl $0
801073ba:	6a 00                	push   $0x0
  pushl $124
801073bc:	6a 7c                	push   $0x7c
  jmp alltraps
801073be:	e9 19 f5 ff ff       	jmp    801068dc <alltraps>

801073c3 <vector125>:
.globl vector125
vector125:
  pushl $0
801073c3:	6a 00                	push   $0x0
  pushl $125
801073c5:	6a 7d                	push   $0x7d
  jmp alltraps
801073c7:	e9 10 f5 ff ff       	jmp    801068dc <alltraps>

801073cc <vector126>:
.globl vector126
vector126:
  pushl $0
801073cc:	6a 00                	push   $0x0
  pushl $126
801073ce:	6a 7e                	push   $0x7e
  jmp alltraps
801073d0:	e9 07 f5 ff ff       	jmp    801068dc <alltraps>

801073d5 <vector127>:
.globl vector127
vector127:
  pushl $0
801073d5:	6a 00                	push   $0x0
  pushl $127
801073d7:	6a 7f                	push   $0x7f
  jmp alltraps
801073d9:	e9 fe f4 ff ff       	jmp    801068dc <alltraps>

801073de <vector128>:
.globl vector128
vector128:
  pushl $0
801073de:	6a 00                	push   $0x0
  pushl $128
801073e0:	68 80 00 00 00       	push   $0x80
  jmp alltraps
801073e5:	e9 f2 f4 ff ff       	jmp    801068dc <alltraps>

801073ea <vector129>:
.globl vector129
vector129:
  pushl $0
801073ea:	6a 00                	push   $0x0
  pushl $129
801073ec:	68 81 00 00 00       	push   $0x81
  jmp alltraps
801073f1:	e9 e6 f4 ff ff       	jmp    801068dc <alltraps>

801073f6 <vector130>:
.globl vector130
vector130:
  pushl $0
801073f6:	6a 00                	push   $0x0
  pushl $130
801073f8:	68 82 00 00 00       	push   $0x82
  jmp alltraps
801073fd:	e9 da f4 ff ff       	jmp    801068dc <alltraps>

80107402 <vector131>:
.globl vector131
vector131:
  pushl $0
80107402:	6a 00                	push   $0x0
  pushl $131
80107404:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80107409:	e9 ce f4 ff ff       	jmp    801068dc <alltraps>

8010740e <vector132>:
.globl vector132
vector132:
  pushl $0
8010740e:	6a 00                	push   $0x0
  pushl $132
80107410:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80107415:	e9 c2 f4 ff ff       	jmp    801068dc <alltraps>

8010741a <vector133>:
.globl vector133
vector133:
  pushl $0
8010741a:	6a 00                	push   $0x0
  pushl $133
8010741c:	68 85 00 00 00       	push   $0x85
  jmp alltraps
80107421:	e9 b6 f4 ff ff       	jmp    801068dc <alltraps>

80107426 <vector134>:
.globl vector134
vector134:
  pushl $0
80107426:	6a 00                	push   $0x0
  pushl $134
80107428:	68 86 00 00 00       	push   $0x86
  jmp alltraps
8010742d:	e9 aa f4 ff ff       	jmp    801068dc <alltraps>

80107432 <vector135>:
.globl vector135
vector135:
  pushl $0
80107432:	6a 00                	push   $0x0
  pushl $135
80107434:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80107439:	e9 9e f4 ff ff       	jmp    801068dc <alltraps>

8010743e <vector136>:
.globl vector136
vector136:
  pushl $0
8010743e:	6a 00                	push   $0x0
  pushl $136
80107440:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80107445:	e9 92 f4 ff ff       	jmp    801068dc <alltraps>

8010744a <vector137>:
.globl vector137
vector137:
  pushl $0
8010744a:	6a 00                	push   $0x0
  pushl $137
8010744c:	68 89 00 00 00       	push   $0x89
  jmp alltraps
80107451:	e9 86 f4 ff ff       	jmp    801068dc <alltraps>

80107456 <vector138>:
.globl vector138
vector138:
  pushl $0
80107456:	6a 00                	push   $0x0
  pushl $138
80107458:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
8010745d:	e9 7a f4 ff ff       	jmp    801068dc <alltraps>

80107462 <vector139>:
.globl vector139
vector139:
  pushl $0
80107462:	6a 00                	push   $0x0
  pushl $139
80107464:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80107469:	e9 6e f4 ff ff       	jmp    801068dc <alltraps>

8010746e <vector140>:
.globl vector140
vector140:
  pushl $0
8010746e:	6a 00                	push   $0x0
  pushl $140
80107470:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
80107475:	e9 62 f4 ff ff       	jmp    801068dc <alltraps>

8010747a <vector141>:
.globl vector141
vector141:
  pushl $0
8010747a:	6a 00                	push   $0x0
  pushl $141
8010747c:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80107481:	e9 56 f4 ff ff       	jmp    801068dc <alltraps>

80107486 <vector142>:
.globl vector142
vector142:
  pushl $0
80107486:	6a 00                	push   $0x0
  pushl $142
80107488:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
8010748d:	e9 4a f4 ff ff       	jmp    801068dc <alltraps>

80107492 <vector143>:
.globl vector143
vector143:
  pushl $0
80107492:	6a 00                	push   $0x0
  pushl $143
80107494:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80107499:	e9 3e f4 ff ff       	jmp    801068dc <alltraps>

8010749e <vector144>:
.globl vector144
vector144:
  pushl $0
8010749e:	6a 00                	push   $0x0
  pushl $144
801074a0:	68 90 00 00 00       	push   $0x90
  jmp alltraps
801074a5:	e9 32 f4 ff ff       	jmp    801068dc <alltraps>

801074aa <vector145>:
.globl vector145
vector145:
  pushl $0
801074aa:	6a 00                	push   $0x0
  pushl $145
801074ac:	68 91 00 00 00       	push   $0x91
  jmp alltraps
801074b1:	e9 26 f4 ff ff       	jmp    801068dc <alltraps>

801074b6 <vector146>:
.globl vector146
vector146:
  pushl $0
801074b6:	6a 00                	push   $0x0
  pushl $146
801074b8:	68 92 00 00 00       	push   $0x92
  jmp alltraps
801074bd:	e9 1a f4 ff ff       	jmp    801068dc <alltraps>

801074c2 <vector147>:
.globl vector147
vector147:
  pushl $0
801074c2:	6a 00                	push   $0x0
  pushl $147
801074c4:	68 93 00 00 00       	push   $0x93
  jmp alltraps
801074c9:	e9 0e f4 ff ff       	jmp    801068dc <alltraps>

801074ce <vector148>:
.globl vector148
vector148:
  pushl $0
801074ce:	6a 00                	push   $0x0
  pushl $148
801074d0:	68 94 00 00 00       	push   $0x94
  jmp alltraps
801074d5:	e9 02 f4 ff ff       	jmp    801068dc <alltraps>

801074da <vector149>:
.globl vector149
vector149:
  pushl $0
801074da:	6a 00                	push   $0x0
  pushl $149
801074dc:	68 95 00 00 00       	push   $0x95
  jmp alltraps
801074e1:	e9 f6 f3 ff ff       	jmp    801068dc <alltraps>

801074e6 <vector150>:
.globl vector150
vector150:
  pushl $0
801074e6:	6a 00                	push   $0x0
  pushl $150
801074e8:	68 96 00 00 00       	push   $0x96
  jmp alltraps
801074ed:	e9 ea f3 ff ff       	jmp    801068dc <alltraps>

801074f2 <vector151>:
.globl vector151
vector151:
  pushl $0
801074f2:	6a 00                	push   $0x0
  pushl $151
801074f4:	68 97 00 00 00       	push   $0x97
  jmp alltraps
801074f9:	e9 de f3 ff ff       	jmp    801068dc <alltraps>

801074fe <vector152>:
.globl vector152
vector152:
  pushl $0
801074fe:	6a 00                	push   $0x0
  pushl $152
80107500:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80107505:	e9 d2 f3 ff ff       	jmp    801068dc <alltraps>

8010750a <vector153>:
.globl vector153
vector153:
  pushl $0
8010750a:	6a 00                	push   $0x0
  pushl $153
8010750c:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80107511:	e9 c6 f3 ff ff       	jmp    801068dc <alltraps>

80107516 <vector154>:
.globl vector154
vector154:
  pushl $0
80107516:	6a 00                	push   $0x0
  pushl $154
80107518:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
8010751d:	e9 ba f3 ff ff       	jmp    801068dc <alltraps>

80107522 <vector155>:
.globl vector155
vector155:
  pushl $0
80107522:	6a 00                	push   $0x0
  pushl $155
80107524:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80107529:	e9 ae f3 ff ff       	jmp    801068dc <alltraps>

8010752e <vector156>:
.globl vector156
vector156:
  pushl $0
8010752e:	6a 00                	push   $0x0
  pushl $156
80107530:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80107535:	e9 a2 f3 ff ff       	jmp    801068dc <alltraps>

8010753a <vector157>:
.globl vector157
vector157:
  pushl $0
8010753a:	6a 00                	push   $0x0
  pushl $157
8010753c:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80107541:	e9 96 f3 ff ff       	jmp    801068dc <alltraps>

80107546 <vector158>:
.globl vector158
vector158:
  pushl $0
80107546:	6a 00                	push   $0x0
  pushl $158
80107548:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
8010754d:	e9 8a f3 ff ff       	jmp    801068dc <alltraps>

80107552 <vector159>:
.globl vector159
vector159:
  pushl $0
80107552:	6a 00                	push   $0x0
  pushl $159
80107554:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80107559:	e9 7e f3 ff ff       	jmp    801068dc <alltraps>

8010755e <vector160>:
.globl vector160
vector160:
  pushl $0
8010755e:	6a 00                	push   $0x0
  pushl $160
80107560:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80107565:	e9 72 f3 ff ff       	jmp    801068dc <alltraps>

8010756a <vector161>:
.globl vector161
vector161:
  pushl $0
8010756a:	6a 00                	push   $0x0
  pushl $161
8010756c:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80107571:	e9 66 f3 ff ff       	jmp    801068dc <alltraps>

80107576 <vector162>:
.globl vector162
vector162:
  pushl $0
80107576:	6a 00                	push   $0x0
  pushl $162
80107578:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
8010757d:	e9 5a f3 ff ff       	jmp    801068dc <alltraps>

80107582 <vector163>:
.globl vector163
vector163:
  pushl $0
80107582:	6a 00                	push   $0x0
  pushl $163
80107584:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80107589:	e9 4e f3 ff ff       	jmp    801068dc <alltraps>

8010758e <vector164>:
.globl vector164
vector164:
  pushl $0
8010758e:	6a 00                	push   $0x0
  pushl $164
80107590:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80107595:	e9 42 f3 ff ff       	jmp    801068dc <alltraps>

8010759a <vector165>:
.globl vector165
vector165:
  pushl $0
8010759a:	6a 00                	push   $0x0
  pushl $165
8010759c:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
801075a1:	e9 36 f3 ff ff       	jmp    801068dc <alltraps>

801075a6 <vector166>:
.globl vector166
vector166:
  pushl $0
801075a6:	6a 00                	push   $0x0
  pushl $166
801075a8:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
801075ad:	e9 2a f3 ff ff       	jmp    801068dc <alltraps>

801075b2 <vector167>:
.globl vector167
vector167:
  pushl $0
801075b2:	6a 00                	push   $0x0
  pushl $167
801075b4:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
801075b9:	e9 1e f3 ff ff       	jmp    801068dc <alltraps>

801075be <vector168>:
.globl vector168
vector168:
  pushl $0
801075be:	6a 00                	push   $0x0
  pushl $168
801075c0:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
801075c5:	e9 12 f3 ff ff       	jmp    801068dc <alltraps>

801075ca <vector169>:
.globl vector169
vector169:
  pushl $0
801075ca:	6a 00                	push   $0x0
  pushl $169
801075cc:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
801075d1:	e9 06 f3 ff ff       	jmp    801068dc <alltraps>

801075d6 <vector170>:
.globl vector170
vector170:
  pushl $0
801075d6:	6a 00                	push   $0x0
  pushl $170
801075d8:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
801075dd:	e9 fa f2 ff ff       	jmp    801068dc <alltraps>

801075e2 <vector171>:
.globl vector171
vector171:
  pushl $0
801075e2:	6a 00                	push   $0x0
  pushl $171
801075e4:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
801075e9:	e9 ee f2 ff ff       	jmp    801068dc <alltraps>

801075ee <vector172>:
.globl vector172
vector172:
  pushl $0
801075ee:	6a 00                	push   $0x0
  pushl $172
801075f0:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
801075f5:	e9 e2 f2 ff ff       	jmp    801068dc <alltraps>

801075fa <vector173>:
.globl vector173
vector173:
  pushl $0
801075fa:	6a 00                	push   $0x0
  pushl $173
801075fc:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80107601:	e9 d6 f2 ff ff       	jmp    801068dc <alltraps>

80107606 <vector174>:
.globl vector174
vector174:
  pushl $0
80107606:	6a 00                	push   $0x0
  pushl $174
80107608:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
8010760d:	e9 ca f2 ff ff       	jmp    801068dc <alltraps>

80107612 <vector175>:
.globl vector175
vector175:
  pushl $0
80107612:	6a 00                	push   $0x0
  pushl $175
80107614:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80107619:	e9 be f2 ff ff       	jmp    801068dc <alltraps>

8010761e <vector176>:
.globl vector176
vector176:
  pushl $0
8010761e:	6a 00                	push   $0x0
  pushl $176
80107620:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80107625:	e9 b2 f2 ff ff       	jmp    801068dc <alltraps>

8010762a <vector177>:
.globl vector177
vector177:
  pushl $0
8010762a:	6a 00                	push   $0x0
  pushl $177
8010762c:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80107631:	e9 a6 f2 ff ff       	jmp    801068dc <alltraps>

80107636 <vector178>:
.globl vector178
vector178:
  pushl $0
80107636:	6a 00                	push   $0x0
  pushl $178
80107638:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
8010763d:	e9 9a f2 ff ff       	jmp    801068dc <alltraps>

80107642 <vector179>:
.globl vector179
vector179:
  pushl $0
80107642:	6a 00                	push   $0x0
  pushl $179
80107644:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80107649:	e9 8e f2 ff ff       	jmp    801068dc <alltraps>

8010764e <vector180>:
.globl vector180
vector180:
  pushl $0
8010764e:	6a 00                	push   $0x0
  pushl $180
80107650:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80107655:	e9 82 f2 ff ff       	jmp    801068dc <alltraps>

8010765a <vector181>:
.globl vector181
vector181:
  pushl $0
8010765a:	6a 00                	push   $0x0
  pushl $181
8010765c:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80107661:	e9 76 f2 ff ff       	jmp    801068dc <alltraps>

80107666 <vector182>:
.globl vector182
vector182:
  pushl $0
80107666:	6a 00                	push   $0x0
  pushl $182
80107668:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
8010766d:	e9 6a f2 ff ff       	jmp    801068dc <alltraps>

80107672 <vector183>:
.globl vector183
vector183:
  pushl $0
80107672:	6a 00                	push   $0x0
  pushl $183
80107674:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80107679:	e9 5e f2 ff ff       	jmp    801068dc <alltraps>

8010767e <vector184>:
.globl vector184
vector184:
  pushl $0
8010767e:	6a 00                	push   $0x0
  pushl $184
80107680:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80107685:	e9 52 f2 ff ff       	jmp    801068dc <alltraps>

8010768a <vector185>:
.globl vector185
vector185:
  pushl $0
8010768a:	6a 00                	push   $0x0
  pushl $185
8010768c:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80107691:	e9 46 f2 ff ff       	jmp    801068dc <alltraps>

80107696 <vector186>:
.globl vector186
vector186:
  pushl $0
80107696:	6a 00                	push   $0x0
  pushl $186
80107698:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
8010769d:	e9 3a f2 ff ff       	jmp    801068dc <alltraps>

801076a2 <vector187>:
.globl vector187
vector187:
  pushl $0
801076a2:	6a 00                	push   $0x0
  pushl $187
801076a4:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
801076a9:	e9 2e f2 ff ff       	jmp    801068dc <alltraps>

801076ae <vector188>:
.globl vector188
vector188:
  pushl $0
801076ae:	6a 00                	push   $0x0
  pushl $188
801076b0:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
801076b5:	e9 22 f2 ff ff       	jmp    801068dc <alltraps>

801076ba <vector189>:
.globl vector189
vector189:
  pushl $0
801076ba:	6a 00                	push   $0x0
  pushl $189
801076bc:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
801076c1:	e9 16 f2 ff ff       	jmp    801068dc <alltraps>

801076c6 <vector190>:
.globl vector190
vector190:
  pushl $0
801076c6:	6a 00                	push   $0x0
  pushl $190
801076c8:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
801076cd:	e9 0a f2 ff ff       	jmp    801068dc <alltraps>

801076d2 <vector191>:
.globl vector191
vector191:
  pushl $0
801076d2:	6a 00                	push   $0x0
  pushl $191
801076d4:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
801076d9:	e9 fe f1 ff ff       	jmp    801068dc <alltraps>

801076de <vector192>:
.globl vector192
vector192:
  pushl $0
801076de:	6a 00                	push   $0x0
  pushl $192
801076e0:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
801076e5:	e9 f2 f1 ff ff       	jmp    801068dc <alltraps>

801076ea <vector193>:
.globl vector193
vector193:
  pushl $0
801076ea:	6a 00                	push   $0x0
  pushl $193
801076ec:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
801076f1:	e9 e6 f1 ff ff       	jmp    801068dc <alltraps>

801076f6 <vector194>:
.globl vector194
vector194:
  pushl $0
801076f6:	6a 00                	push   $0x0
  pushl $194
801076f8:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
801076fd:	e9 da f1 ff ff       	jmp    801068dc <alltraps>

80107702 <vector195>:
.globl vector195
vector195:
  pushl $0
80107702:	6a 00                	push   $0x0
  pushl $195
80107704:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80107709:	e9 ce f1 ff ff       	jmp    801068dc <alltraps>

8010770e <vector196>:
.globl vector196
vector196:
  pushl $0
8010770e:	6a 00                	push   $0x0
  pushl $196
80107710:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80107715:	e9 c2 f1 ff ff       	jmp    801068dc <alltraps>

8010771a <vector197>:
.globl vector197
vector197:
  pushl $0
8010771a:	6a 00                	push   $0x0
  pushl $197
8010771c:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80107721:	e9 b6 f1 ff ff       	jmp    801068dc <alltraps>

80107726 <vector198>:
.globl vector198
vector198:
  pushl $0
80107726:	6a 00                	push   $0x0
  pushl $198
80107728:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
8010772d:	e9 aa f1 ff ff       	jmp    801068dc <alltraps>

80107732 <vector199>:
.globl vector199
vector199:
  pushl $0
80107732:	6a 00                	push   $0x0
  pushl $199
80107734:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80107739:	e9 9e f1 ff ff       	jmp    801068dc <alltraps>

8010773e <vector200>:
.globl vector200
vector200:
  pushl $0
8010773e:	6a 00                	push   $0x0
  pushl $200
80107740:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80107745:	e9 92 f1 ff ff       	jmp    801068dc <alltraps>

8010774a <vector201>:
.globl vector201
vector201:
  pushl $0
8010774a:	6a 00                	push   $0x0
  pushl $201
8010774c:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80107751:	e9 86 f1 ff ff       	jmp    801068dc <alltraps>

80107756 <vector202>:
.globl vector202
vector202:
  pushl $0
80107756:	6a 00                	push   $0x0
  pushl $202
80107758:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
8010775d:	e9 7a f1 ff ff       	jmp    801068dc <alltraps>

80107762 <vector203>:
.globl vector203
vector203:
  pushl $0
80107762:	6a 00                	push   $0x0
  pushl $203
80107764:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80107769:	e9 6e f1 ff ff       	jmp    801068dc <alltraps>

8010776e <vector204>:
.globl vector204
vector204:
  pushl $0
8010776e:	6a 00                	push   $0x0
  pushl $204
80107770:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80107775:	e9 62 f1 ff ff       	jmp    801068dc <alltraps>

8010777a <vector205>:
.globl vector205
vector205:
  pushl $0
8010777a:	6a 00                	push   $0x0
  pushl $205
8010777c:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80107781:	e9 56 f1 ff ff       	jmp    801068dc <alltraps>

80107786 <vector206>:
.globl vector206
vector206:
  pushl $0
80107786:	6a 00                	push   $0x0
  pushl $206
80107788:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
8010778d:	e9 4a f1 ff ff       	jmp    801068dc <alltraps>

80107792 <vector207>:
.globl vector207
vector207:
  pushl $0
80107792:	6a 00                	push   $0x0
  pushl $207
80107794:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80107799:	e9 3e f1 ff ff       	jmp    801068dc <alltraps>

8010779e <vector208>:
.globl vector208
vector208:
  pushl $0
8010779e:	6a 00                	push   $0x0
  pushl $208
801077a0:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
801077a5:	e9 32 f1 ff ff       	jmp    801068dc <alltraps>

801077aa <vector209>:
.globl vector209
vector209:
  pushl $0
801077aa:	6a 00                	push   $0x0
  pushl $209
801077ac:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
801077b1:	e9 26 f1 ff ff       	jmp    801068dc <alltraps>

801077b6 <vector210>:
.globl vector210
vector210:
  pushl $0
801077b6:	6a 00                	push   $0x0
  pushl $210
801077b8:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
801077bd:	e9 1a f1 ff ff       	jmp    801068dc <alltraps>

801077c2 <vector211>:
.globl vector211
vector211:
  pushl $0
801077c2:	6a 00                	push   $0x0
  pushl $211
801077c4:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
801077c9:	e9 0e f1 ff ff       	jmp    801068dc <alltraps>

801077ce <vector212>:
.globl vector212
vector212:
  pushl $0
801077ce:	6a 00                	push   $0x0
  pushl $212
801077d0:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
801077d5:	e9 02 f1 ff ff       	jmp    801068dc <alltraps>

801077da <vector213>:
.globl vector213
vector213:
  pushl $0
801077da:	6a 00                	push   $0x0
  pushl $213
801077dc:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
801077e1:	e9 f6 f0 ff ff       	jmp    801068dc <alltraps>

801077e6 <vector214>:
.globl vector214
vector214:
  pushl $0
801077e6:	6a 00                	push   $0x0
  pushl $214
801077e8:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
801077ed:	e9 ea f0 ff ff       	jmp    801068dc <alltraps>

801077f2 <vector215>:
.globl vector215
vector215:
  pushl $0
801077f2:	6a 00                	push   $0x0
  pushl $215
801077f4:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
801077f9:	e9 de f0 ff ff       	jmp    801068dc <alltraps>

801077fe <vector216>:
.globl vector216
vector216:
  pushl $0
801077fe:	6a 00                	push   $0x0
  pushl $216
80107800:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80107805:	e9 d2 f0 ff ff       	jmp    801068dc <alltraps>

8010780a <vector217>:
.globl vector217
vector217:
  pushl $0
8010780a:	6a 00                	push   $0x0
  pushl $217
8010780c:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80107811:	e9 c6 f0 ff ff       	jmp    801068dc <alltraps>

80107816 <vector218>:
.globl vector218
vector218:
  pushl $0
80107816:	6a 00                	push   $0x0
  pushl $218
80107818:	68 da 00 00 00       	push   $0xda
  jmp alltraps
8010781d:	e9 ba f0 ff ff       	jmp    801068dc <alltraps>

80107822 <vector219>:
.globl vector219
vector219:
  pushl $0
80107822:	6a 00                	push   $0x0
  pushl $219
80107824:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80107829:	e9 ae f0 ff ff       	jmp    801068dc <alltraps>

8010782e <vector220>:
.globl vector220
vector220:
  pushl $0
8010782e:	6a 00                	push   $0x0
  pushl $220
80107830:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80107835:	e9 a2 f0 ff ff       	jmp    801068dc <alltraps>

8010783a <vector221>:
.globl vector221
vector221:
  pushl $0
8010783a:	6a 00                	push   $0x0
  pushl $221
8010783c:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80107841:	e9 96 f0 ff ff       	jmp    801068dc <alltraps>

80107846 <vector222>:
.globl vector222
vector222:
  pushl $0
80107846:	6a 00                	push   $0x0
  pushl $222
80107848:	68 de 00 00 00       	push   $0xde
  jmp alltraps
8010784d:	e9 8a f0 ff ff       	jmp    801068dc <alltraps>

80107852 <vector223>:
.globl vector223
vector223:
  pushl $0
80107852:	6a 00                	push   $0x0
  pushl $223
80107854:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80107859:	e9 7e f0 ff ff       	jmp    801068dc <alltraps>

8010785e <vector224>:
.globl vector224
vector224:
  pushl $0
8010785e:	6a 00                	push   $0x0
  pushl $224
80107860:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80107865:	e9 72 f0 ff ff       	jmp    801068dc <alltraps>

8010786a <vector225>:
.globl vector225
vector225:
  pushl $0
8010786a:	6a 00                	push   $0x0
  pushl $225
8010786c:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80107871:	e9 66 f0 ff ff       	jmp    801068dc <alltraps>

80107876 <vector226>:
.globl vector226
vector226:
  pushl $0
80107876:	6a 00                	push   $0x0
  pushl $226
80107878:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
8010787d:	e9 5a f0 ff ff       	jmp    801068dc <alltraps>

80107882 <vector227>:
.globl vector227
vector227:
  pushl $0
80107882:	6a 00                	push   $0x0
  pushl $227
80107884:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80107889:	e9 4e f0 ff ff       	jmp    801068dc <alltraps>

8010788e <vector228>:
.globl vector228
vector228:
  pushl $0
8010788e:	6a 00                	push   $0x0
  pushl $228
80107890:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80107895:	e9 42 f0 ff ff       	jmp    801068dc <alltraps>

8010789a <vector229>:
.globl vector229
vector229:
  pushl $0
8010789a:	6a 00                	push   $0x0
  pushl $229
8010789c:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
801078a1:	e9 36 f0 ff ff       	jmp    801068dc <alltraps>

801078a6 <vector230>:
.globl vector230
vector230:
  pushl $0
801078a6:	6a 00                	push   $0x0
  pushl $230
801078a8:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
801078ad:	e9 2a f0 ff ff       	jmp    801068dc <alltraps>

801078b2 <vector231>:
.globl vector231
vector231:
  pushl $0
801078b2:	6a 00                	push   $0x0
  pushl $231
801078b4:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
801078b9:	e9 1e f0 ff ff       	jmp    801068dc <alltraps>

801078be <vector232>:
.globl vector232
vector232:
  pushl $0
801078be:	6a 00                	push   $0x0
  pushl $232
801078c0:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
801078c5:	e9 12 f0 ff ff       	jmp    801068dc <alltraps>

801078ca <vector233>:
.globl vector233
vector233:
  pushl $0
801078ca:	6a 00                	push   $0x0
  pushl $233
801078cc:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
801078d1:	e9 06 f0 ff ff       	jmp    801068dc <alltraps>

801078d6 <vector234>:
.globl vector234
vector234:
  pushl $0
801078d6:	6a 00                	push   $0x0
  pushl $234
801078d8:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
801078dd:	e9 fa ef ff ff       	jmp    801068dc <alltraps>

801078e2 <vector235>:
.globl vector235
vector235:
  pushl $0
801078e2:	6a 00                	push   $0x0
  pushl $235
801078e4:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
801078e9:	e9 ee ef ff ff       	jmp    801068dc <alltraps>

801078ee <vector236>:
.globl vector236
vector236:
  pushl $0
801078ee:	6a 00                	push   $0x0
  pushl $236
801078f0:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
801078f5:	e9 e2 ef ff ff       	jmp    801068dc <alltraps>

801078fa <vector237>:
.globl vector237
vector237:
  pushl $0
801078fa:	6a 00                	push   $0x0
  pushl $237
801078fc:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80107901:	e9 d6 ef ff ff       	jmp    801068dc <alltraps>

80107906 <vector238>:
.globl vector238
vector238:
  pushl $0
80107906:	6a 00                	push   $0x0
  pushl $238
80107908:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
8010790d:	e9 ca ef ff ff       	jmp    801068dc <alltraps>

80107912 <vector239>:
.globl vector239
vector239:
  pushl $0
80107912:	6a 00                	push   $0x0
  pushl $239
80107914:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80107919:	e9 be ef ff ff       	jmp    801068dc <alltraps>

8010791e <vector240>:
.globl vector240
vector240:
  pushl $0
8010791e:	6a 00                	push   $0x0
  pushl $240
80107920:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80107925:	e9 b2 ef ff ff       	jmp    801068dc <alltraps>

8010792a <vector241>:
.globl vector241
vector241:
  pushl $0
8010792a:	6a 00                	push   $0x0
  pushl $241
8010792c:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80107931:	e9 a6 ef ff ff       	jmp    801068dc <alltraps>

80107936 <vector242>:
.globl vector242
vector242:
  pushl $0
80107936:	6a 00                	push   $0x0
  pushl $242
80107938:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
8010793d:	e9 9a ef ff ff       	jmp    801068dc <alltraps>

80107942 <vector243>:
.globl vector243
vector243:
  pushl $0
80107942:	6a 00                	push   $0x0
  pushl $243
80107944:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80107949:	e9 8e ef ff ff       	jmp    801068dc <alltraps>

8010794e <vector244>:
.globl vector244
vector244:
  pushl $0
8010794e:	6a 00                	push   $0x0
  pushl $244
80107950:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80107955:	e9 82 ef ff ff       	jmp    801068dc <alltraps>

8010795a <vector245>:
.globl vector245
vector245:
  pushl $0
8010795a:	6a 00                	push   $0x0
  pushl $245
8010795c:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80107961:	e9 76 ef ff ff       	jmp    801068dc <alltraps>

80107966 <vector246>:
.globl vector246
vector246:
  pushl $0
80107966:	6a 00                	push   $0x0
  pushl $246
80107968:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
8010796d:	e9 6a ef ff ff       	jmp    801068dc <alltraps>

80107972 <vector247>:
.globl vector247
vector247:
  pushl $0
80107972:	6a 00                	push   $0x0
  pushl $247
80107974:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80107979:	e9 5e ef ff ff       	jmp    801068dc <alltraps>

8010797e <vector248>:
.globl vector248
vector248:
  pushl $0
8010797e:	6a 00                	push   $0x0
  pushl $248
80107980:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80107985:	e9 52 ef ff ff       	jmp    801068dc <alltraps>

8010798a <vector249>:
.globl vector249
vector249:
  pushl $0
8010798a:	6a 00                	push   $0x0
  pushl $249
8010798c:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80107991:	e9 46 ef ff ff       	jmp    801068dc <alltraps>

80107996 <vector250>:
.globl vector250
vector250:
  pushl $0
80107996:	6a 00                	push   $0x0
  pushl $250
80107998:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
8010799d:	e9 3a ef ff ff       	jmp    801068dc <alltraps>

801079a2 <vector251>:
.globl vector251
vector251:
  pushl $0
801079a2:	6a 00                	push   $0x0
  pushl $251
801079a4:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
801079a9:	e9 2e ef ff ff       	jmp    801068dc <alltraps>

801079ae <vector252>:
.globl vector252
vector252:
  pushl $0
801079ae:	6a 00                	push   $0x0
  pushl $252
801079b0:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
801079b5:	e9 22 ef ff ff       	jmp    801068dc <alltraps>

801079ba <vector253>:
.globl vector253
vector253:
  pushl $0
801079ba:	6a 00                	push   $0x0
  pushl $253
801079bc:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
801079c1:	e9 16 ef ff ff       	jmp    801068dc <alltraps>

801079c6 <vector254>:
.globl vector254
vector254:
  pushl $0
801079c6:	6a 00                	push   $0x0
  pushl $254
801079c8:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
801079cd:	e9 0a ef ff ff       	jmp    801068dc <alltraps>

801079d2 <vector255>:
.globl vector255
vector255:
  pushl $0
801079d2:	6a 00                	push   $0x0
  pushl $255
801079d4:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
801079d9:	e9 fe ee ff ff       	jmp    801068dc <alltraps>
	...

801079e0 <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
801079e0:	55                   	push   %ebp
801079e1:	89 e5                	mov    %esp,%ebp
801079e3:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
801079e6:	8b 45 0c             	mov    0xc(%ebp),%eax
801079e9:	83 e8 01             	sub    $0x1,%eax
801079ec:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
801079f0:	8b 45 08             	mov    0x8(%ebp),%eax
801079f3:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
801079f7:	8b 45 08             	mov    0x8(%ebp),%eax
801079fa:	c1 e8 10             	shr    $0x10,%eax
801079fd:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
80107a01:	8d 45 fa             	lea    -0x6(%ebp),%eax
80107a04:	0f 01 10             	lgdtl  (%eax)
}
80107a07:	c9                   	leave  
80107a08:	c3                   	ret    

80107a09 <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
80107a09:	55                   	push   %ebp
80107a0a:	89 e5                	mov    %esp,%ebp
80107a0c:	83 ec 04             	sub    $0x4,%esp
80107a0f:	8b 45 08             	mov    0x8(%ebp),%eax
80107a12:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
80107a16:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80107a1a:	0f 00 d8             	ltr    %ax
}
80107a1d:	c9                   	leave  
80107a1e:	c3                   	ret    

80107a1f <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
80107a1f:	55                   	push   %ebp
80107a20:	89 e5                	mov    %esp,%ebp
80107a22:	83 ec 04             	sub    $0x4,%esp
80107a25:	8b 45 08             	mov    0x8(%ebp),%eax
80107a28:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
80107a2c:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80107a30:	8e e8                	mov    %eax,%gs
}
80107a32:	c9                   	leave  
80107a33:	c3                   	ret    

80107a34 <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
80107a34:	55                   	push   %ebp
80107a35:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
80107a37:	8b 45 08             	mov    0x8(%ebp),%eax
80107a3a:	0f 22 d8             	mov    %eax,%cr3
}
80107a3d:	5d                   	pop    %ebp
80107a3e:	c3                   	ret    

80107a3f <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80107a3f:	55                   	push   %ebp
80107a40:	89 e5                	mov    %esp,%ebp
80107a42:	8b 45 08             	mov    0x8(%ebp),%eax
80107a45:	05 00 00 00 80       	add    $0x80000000,%eax
80107a4a:	5d                   	pop    %ebp
80107a4b:	c3                   	ret    

80107a4c <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80107a4c:	55                   	push   %ebp
80107a4d:	89 e5                	mov    %esp,%ebp
80107a4f:	8b 45 08             	mov    0x8(%ebp),%eax
80107a52:	05 00 00 00 80       	add    $0x80000000,%eax
80107a57:	5d                   	pop    %ebp
80107a58:	c3                   	ret    

80107a59 <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
80107a59:	55                   	push   %ebp
80107a5a:	89 e5                	mov    %esp,%ebp
80107a5c:	53                   	push   %ebx
80107a5d:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
80107a60:	e8 34 b4 ff ff       	call   80102e99 <cpunum>
80107a65:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80107a6b:	05 20 09 11 80       	add    $0x80110920,%eax
80107a70:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80107a73:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a76:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
80107a7c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a7f:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
80107a85:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a88:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
80107a8c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a8f:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107a93:	83 e2 f0             	and    $0xfffffff0,%edx
80107a96:	83 ca 0a             	or     $0xa,%edx
80107a99:	88 50 7d             	mov    %dl,0x7d(%eax)
80107a9c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a9f:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107aa3:	83 ca 10             	or     $0x10,%edx
80107aa6:	88 50 7d             	mov    %dl,0x7d(%eax)
80107aa9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107aac:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107ab0:	83 e2 9f             	and    $0xffffff9f,%edx
80107ab3:	88 50 7d             	mov    %dl,0x7d(%eax)
80107ab6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ab9:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107abd:	83 ca 80             	or     $0xffffff80,%edx
80107ac0:	88 50 7d             	mov    %dl,0x7d(%eax)
80107ac3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ac6:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107aca:	83 ca 0f             	or     $0xf,%edx
80107acd:	88 50 7e             	mov    %dl,0x7e(%eax)
80107ad0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ad3:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107ad7:	83 e2 ef             	and    $0xffffffef,%edx
80107ada:	88 50 7e             	mov    %dl,0x7e(%eax)
80107add:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ae0:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107ae4:	83 e2 df             	and    $0xffffffdf,%edx
80107ae7:	88 50 7e             	mov    %dl,0x7e(%eax)
80107aea:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107aed:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107af1:	83 ca 40             	or     $0x40,%edx
80107af4:	88 50 7e             	mov    %dl,0x7e(%eax)
80107af7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107afa:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107afe:	83 ca 80             	or     $0xffffff80,%edx
80107b01:	88 50 7e             	mov    %dl,0x7e(%eax)
80107b04:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b07:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80107b0b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b0e:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
80107b15:	ff ff 
80107b17:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b1a:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
80107b21:	00 00 
80107b23:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b26:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
80107b2d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b30:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107b37:	83 e2 f0             	and    $0xfffffff0,%edx
80107b3a:	83 ca 02             	or     $0x2,%edx
80107b3d:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107b43:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b46:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107b4d:	83 ca 10             	or     $0x10,%edx
80107b50:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107b56:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b59:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107b60:	83 e2 9f             	and    $0xffffff9f,%edx
80107b63:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107b69:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b6c:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107b73:	83 ca 80             	or     $0xffffff80,%edx
80107b76:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107b7c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b7f:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107b86:	83 ca 0f             	or     $0xf,%edx
80107b89:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107b8f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b92:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107b99:	83 e2 ef             	and    $0xffffffef,%edx
80107b9c:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107ba2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ba5:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107bac:	83 e2 df             	and    $0xffffffdf,%edx
80107baf:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107bb5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107bb8:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107bbf:	83 ca 40             	or     $0x40,%edx
80107bc2:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107bc8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107bcb:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107bd2:	83 ca 80             	or     $0xffffff80,%edx
80107bd5:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107bdb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107bde:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80107be5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107be8:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
80107bef:	ff ff 
80107bf1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107bf4:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
80107bfb:	00 00 
80107bfd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c00:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
80107c07:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c0a:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107c11:	83 e2 f0             	and    $0xfffffff0,%edx
80107c14:	83 ca 0a             	or     $0xa,%edx
80107c17:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107c1d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c20:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107c27:	83 ca 10             	or     $0x10,%edx
80107c2a:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107c30:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c33:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107c3a:	83 ca 60             	or     $0x60,%edx
80107c3d:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107c43:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c46:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107c4d:	83 ca 80             	or     $0xffffff80,%edx
80107c50:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107c56:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c59:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107c60:	83 ca 0f             	or     $0xf,%edx
80107c63:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107c69:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c6c:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107c73:	83 e2 ef             	and    $0xffffffef,%edx
80107c76:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107c7c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c7f:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107c86:	83 e2 df             	and    $0xffffffdf,%edx
80107c89:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107c8f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c92:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107c99:	83 ca 40             	or     $0x40,%edx
80107c9c:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107ca2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ca5:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107cac:	83 ca 80             	or     $0xffffff80,%edx
80107caf:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107cb5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107cb8:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80107cbf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107cc2:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
80107cc9:	ff ff 
80107ccb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107cce:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
80107cd5:	00 00 
80107cd7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107cda:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
80107ce1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ce4:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107ceb:	83 e2 f0             	and    $0xfffffff0,%edx
80107cee:	83 ca 02             	or     $0x2,%edx
80107cf1:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107cf7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107cfa:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107d01:	83 ca 10             	or     $0x10,%edx
80107d04:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107d0a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d0d:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107d14:	83 ca 60             	or     $0x60,%edx
80107d17:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107d1d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d20:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107d27:	83 ca 80             	or     $0xffffff80,%edx
80107d2a:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107d30:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d33:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107d3a:	83 ca 0f             	or     $0xf,%edx
80107d3d:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107d43:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d46:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107d4d:	83 e2 ef             	and    $0xffffffef,%edx
80107d50:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107d56:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d59:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107d60:	83 e2 df             	and    $0xffffffdf,%edx
80107d63:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107d69:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d6c:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107d73:	83 ca 40             	or     $0x40,%edx
80107d76:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107d7c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d7f:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107d86:	83 ca 80             	or     $0xffffff80,%edx
80107d89:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107d8f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d92:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
80107d99:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d9c:	05 b4 00 00 00       	add    $0xb4,%eax
80107da1:	89 c3                	mov    %eax,%ebx
80107da3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107da6:	05 b4 00 00 00       	add    $0xb4,%eax
80107dab:	c1 e8 10             	shr    $0x10,%eax
80107dae:	89 c1                	mov    %eax,%ecx
80107db0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107db3:	05 b4 00 00 00       	add    $0xb4,%eax
80107db8:	c1 e8 18             	shr    $0x18,%eax
80107dbb:	89 c2                	mov    %eax,%edx
80107dbd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107dc0:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
80107dc7:	00 00 
80107dc9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107dcc:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
80107dd3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107dd6:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
80107ddc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ddf:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107de6:	83 e1 f0             	and    $0xfffffff0,%ecx
80107de9:	83 c9 02             	or     $0x2,%ecx
80107dec:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107df2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107df5:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107dfc:	83 c9 10             	or     $0x10,%ecx
80107dff:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107e05:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e08:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107e0f:	83 e1 9f             	and    $0xffffff9f,%ecx
80107e12:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107e18:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e1b:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107e22:	83 c9 80             	or     $0xffffff80,%ecx
80107e25:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107e2b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e2e:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107e35:	83 e1 f0             	and    $0xfffffff0,%ecx
80107e38:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107e3e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e41:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107e48:	83 e1 ef             	and    $0xffffffef,%ecx
80107e4b:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107e51:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e54:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107e5b:	83 e1 df             	and    $0xffffffdf,%ecx
80107e5e:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107e64:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e67:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107e6e:	83 c9 40             	or     $0x40,%ecx
80107e71:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107e77:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e7a:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107e81:	83 c9 80             	or     $0xffffff80,%ecx
80107e84:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107e8a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e8d:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
80107e93:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e96:	83 c0 70             	add    $0x70,%eax
80107e99:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
80107ea0:	00 
80107ea1:	89 04 24             	mov    %eax,(%esp)
80107ea4:	e8 37 fb ff ff       	call   801079e0 <lgdt>
  loadgs(SEG_KCPU << 3);
80107ea9:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
80107eb0:	e8 6a fb ff ff       	call   80107a1f <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
80107eb5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107eb8:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
80107ebe:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80107ec5:	00 00 00 00 
}
80107ec9:	83 c4 24             	add    $0x24,%esp
80107ecc:	5b                   	pop    %ebx
80107ecd:	5d                   	pop    %ebp
80107ece:	c3                   	ret    

80107ecf <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80107ecf:	55                   	push   %ebp
80107ed0:	89 e5                	mov    %esp,%ebp
80107ed2:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80107ed5:	8b 45 0c             	mov    0xc(%ebp),%eax
80107ed8:	c1 e8 16             	shr    $0x16,%eax
80107edb:	c1 e0 02             	shl    $0x2,%eax
80107ede:	03 45 08             	add    0x8(%ebp),%eax
80107ee1:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
80107ee4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107ee7:	8b 00                	mov    (%eax),%eax
80107ee9:	83 e0 01             	and    $0x1,%eax
80107eec:	84 c0                	test   %al,%al
80107eee:	74 17                	je     80107f07 <walkpgdir+0x38>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
80107ef0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107ef3:	8b 00                	mov    (%eax),%eax
80107ef5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107efa:	89 04 24             	mov    %eax,(%esp)
80107efd:	e8 4a fb ff ff       	call   80107a4c <p2v>
80107f02:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107f05:	eb 4b                	jmp    80107f52 <walkpgdir+0x83>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
80107f07:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80107f0b:	74 0e                	je     80107f1b <walkpgdir+0x4c>
80107f0d:	e8 f9 ab ff ff       	call   80102b0b <kalloc>
80107f12:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107f15:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80107f19:	75 07                	jne    80107f22 <walkpgdir+0x53>
      return 0;
80107f1b:	b8 00 00 00 00       	mov    $0x0,%eax
80107f20:	eb 41                	jmp    80107f63 <walkpgdir+0x94>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
80107f22:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107f29:	00 
80107f2a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107f31:	00 
80107f32:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f35:	89 04 24             	mov    %eax,(%esp)
80107f38:	e8 fd d3 ff ff       	call   8010533a <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
80107f3d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f40:	89 04 24             	mov    %eax,(%esp)
80107f43:	e8 f7 fa ff ff       	call   80107a3f <v2p>
80107f48:	89 c2                	mov    %eax,%edx
80107f4a:	83 ca 07             	or     $0x7,%edx
80107f4d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107f50:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
80107f52:	8b 45 0c             	mov    0xc(%ebp),%eax
80107f55:	c1 e8 0c             	shr    $0xc,%eax
80107f58:	25 ff 03 00 00       	and    $0x3ff,%eax
80107f5d:	c1 e0 02             	shl    $0x2,%eax
80107f60:	03 45 f4             	add    -0xc(%ebp),%eax
}
80107f63:	c9                   	leave  
80107f64:	c3                   	ret    

80107f65 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80107f65:	55                   	push   %ebp
80107f66:	89 e5                	mov    %esp,%ebp
80107f68:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
80107f6b:	8b 45 0c             	mov    0xc(%ebp),%eax
80107f6e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107f73:	89 45 f4             	mov    %eax,-0xc(%ebp)
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80107f76:	8b 45 0c             	mov    0xc(%ebp),%eax
80107f79:	03 45 10             	add    0x10(%ebp),%eax
80107f7c:	83 e8 01             	sub    $0x1,%eax
80107f7f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107f84:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80107f87:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80107f8e:	00 
80107f8f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f92:	89 44 24 04          	mov    %eax,0x4(%esp)
80107f96:	8b 45 08             	mov    0x8(%ebp),%eax
80107f99:	89 04 24             	mov    %eax,(%esp)
80107f9c:	e8 2e ff ff ff       	call   80107ecf <walkpgdir>
80107fa1:	89 45 ec             	mov    %eax,-0x14(%ebp)
80107fa4:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80107fa8:	75 07                	jne    80107fb1 <mappages+0x4c>
      return -1;
80107faa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107faf:	eb 46                	jmp    80107ff7 <mappages+0x92>
    if(*pte & PTE_P)
80107fb1:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107fb4:	8b 00                	mov    (%eax),%eax
80107fb6:	83 e0 01             	and    $0x1,%eax
80107fb9:	84 c0                	test   %al,%al
80107fbb:	74 0c                	je     80107fc9 <mappages+0x64>
      panic("remap");
80107fbd:	c7 04 24 14 8f 10 80 	movl   $0x80108f14,(%esp)
80107fc4:	e8 74 85 ff ff       	call   8010053d <panic>
    *pte = pa | perm | PTE_P;
80107fc9:	8b 45 18             	mov    0x18(%ebp),%eax
80107fcc:	0b 45 14             	or     0x14(%ebp),%eax
80107fcf:	89 c2                	mov    %eax,%edx
80107fd1:	83 ca 01             	or     $0x1,%edx
80107fd4:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107fd7:	89 10                	mov    %edx,(%eax)
    if(a == last)
80107fd9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fdc:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80107fdf:	74 10                	je     80107ff1 <mappages+0x8c>
      break;
    a += PGSIZE;
80107fe1:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
80107fe8:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
80107fef:	eb 96                	jmp    80107f87 <mappages+0x22>
      return -1;
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
80107ff1:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
80107ff2:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107ff7:	c9                   	leave  
80107ff8:	c3                   	ret    

80107ff9 <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm()
{
80107ff9:	55                   	push   %ebp
80107ffa:	89 e5                	mov    %esp,%ebp
80107ffc:	53                   	push   %ebx
80107ffd:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
80108000:	e8 06 ab ff ff       	call   80102b0b <kalloc>
80108005:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108008:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010800c:	75 0a                	jne    80108018 <setupkvm+0x1f>
    return 0;
8010800e:	b8 00 00 00 00       	mov    $0x0,%eax
80108013:	e9 98 00 00 00       	jmp    801080b0 <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
80108018:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010801f:	00 
80108020:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108027:	00 
80108028:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010802b:	89 04 24             	mov    %eax,(%esp)
8010802e:	e8 07 d3 ff ff       	call   8010533a <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
80108033:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
8010803a:	e8 0d fa ff ff       	call   80107a4c <p2v>
8010803f:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
80108044:	76 0c                	jbe    80108052 <setupkvm+0x59>
    panic("PHYSTOP too high");
80108046:	c7 04 24 1a 8f 10 80 	movl   $0x80108f1a,(%esp)
8010804d:	e8 eb 84 ff ff       	call   8010053d <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80108052:	c7 45 f4 a0 c4 10 80 	movl   $0x8010c4a0,-0xc(%ebp)
80108059:	eb 49                	jmp    801080a4 <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
8010805b:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
8010805e:	8b 48 0c             	mov    0xc(%eax),%ecx
                (uint)k->phys_start, k->perm) < 0)
80108061:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80108064:	8b 50 04             	mov    0x4(%eax),%edx
80108067:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010806a:	8b 58 08             	mov    0x8(%eax),%ebx
8010806d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108070:	8b 40 04             	mov    0x4(%eax),%eax
80108073:	29 c3                	sub    %eax,%ebx
80108075:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108078:	8b 00                	mov    (%eax),%eax
8010807a:	89 4c 24 10          	mov    %ecx,0x10(%esp)
8010807e:	89 54 24 0c          	mov    %edx,0xc(%esp)
80108082:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80108086:	89 44 24 04          	mov    %eax,0x4(%esp)
8010808a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010808d:	89 04 24             	mov    %eax,(%esp)
80108090:	e8 d0 fe ff ff       	call   80107f65 <mappages>
80108095:	85 c0                	test   %eax,%eax
80108097:	79 07                	jns    801080a0 <setupkvm+0xa7>
                (uint)k->phys_start, k->perm) < 0)
      return 0;
80108099:	b8 00 00 00 00       	mov    $0x0,%eax
8010809e:	eb 10                	jmp    801080b0 <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
801080a0:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
801080a4:	81 7d f4 e0 c4 10 80 	cmpl   $0x8010c4e0,-0xc(%ebp)
801080ab:	72 ae                	jb     8010805b <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
      return 0;
  return pgdir;
801080ad:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
801080b0:	83 c4 34             	add    $0x34,%esp
801080b3:	5b                   	pop    %ebx
801080b4:	5d                   	pop    %ebp
801080b5:	c3                   	ret    

801080b6 <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
void
kvmalloc(void)
{
801080b6:	55                   	push   %ebp
801080b7:	89 e5                	mov    %esp,%ebp
801080b9:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
801080bc:	e8 38 ff ff ff       	call   80107ff9 <setupkvm>
801080c1:	a3 f8 38 11 80       	mov    %eax,0x801138f8
  switchkvm();
801080c6:	e8 02 00 00 00       	call   801080cd <switchkvm>
}
801080cb:	c9                   	leave  
801080cc:	c3                   	ret    

801080cd <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
801080cd:	55                   	push   %ebp
801080ce:	89 e5                	mov    %esp,%ebp
801080d0:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
801080d3:	a1 f8 38 11 80       	mov    0x801138f8,%eax
801080d8:	89 04 24             	mov    %eax,(%esp)
801080db:	e8 5f f9 ff ff       	call   80107a3f <v2p>
801080e0:	89 04 24             	mov    %eax,(%esp)
801080e3:	e8 4c f9 ff ff       	call   80107a34 <lcr3>
}
801080e8:	c9                   	leave  
801080e9:	c3                   	ret    

801080ea <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
801080ea:	55                   	push   %ebp
801080eb:	89 e5                	mov    %esp,%ebp
801080ed:	53                   	push   %ebx
801080ee:	83 ec 14             	sub    $0x14,%esp
  pushcli();
801080f1:	e8 3e d1 ff ff       	call   80105234 <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
801080f6:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801080fc:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108103:	83 c2 08             	add    $0x8,%edx
80108106:	89 d3                	mov    %edx,%ebx
80108108:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
8010810f:	83 c2 08             	add    $0x8,%edx
80108112:	c1 ea 10             	shr    $0x10,%edx
80108115:	89 d1                	mov    %edx,%ecx
80108117:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
8010811e:	83 c2 08             	add    $0x8,%edx
80108121:	c1 ea 18             	shr    $0x18,%edx
80108124:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
8010812b:	67 00 
8010812d:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
80108134:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
8010813a:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108141:	83 e1 f0             	and    $0xfffffff0,%ecx
80108144:	83 c9 09             	or     $0x9,%ecx
80108147:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
8010814d:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108154:	83 c9 10             	or     $0x10,%ecx
80108157:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
8010815d:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108164:	83 e1 9f             	and    $0xffffff9f,%ecx
80108167:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
8010816d:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108174:	83 c9 80             	or     $0xffffff80,%ecx
80108177:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
8010817d:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108184:	83 e1 f0             	and    $0xfffffff0,%ecx
80108187:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
8010818d:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108194:	83 e1 ef             	and    $0xffffffef,%ecx
80108197:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
8010819d:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
801081a4:	83 e1 df             	and    $0xffffffdf,%ecx
801081a7:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
801081ad:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
801081b4:	83 c9 40             	or     $0x40,%ecx
801081b7:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
801081bd:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
801081c4:	83 e1 7f             	and    $0x7f,%ecx
801081c7:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
801081cd:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
801081d3:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801081d9:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
801081e0:	83 e2 ef             	and    $0xffffffef,%edx
801081e3:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
801081e9:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801081ef:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
801081f5:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801081fb:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80108202:	8b 52 08             	mov    0x8(%edx),%edx
80108205:	81 c2 00 10 00 00    	add    $0x1000,%edx
8010820b:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
8010820e:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
80108215:	e8 ef f7 ff ff       	call   80107a09 <ltr>
  if(p->pgdir == 0)
8010821a:	8b 45 08             	mov    0x8(%ebp),%eax
8010821d:	8b 40 04             	mov    0x4(%eax),%eax
80108220:	85 c0                	test   %eax,%eax
80108222:	75 0c                	jne    80108230 <switchuvm+0x146>
    panic("switchuvm: no pgdir");
80108224:	c7 04 24 2b 8f 10 80 	movl   $0x80108f2b,(%esp)
8010822b:	e8 0d 83 ff ff       	call   8010053d <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
80108230:	8b 45 08             	mov    0x8(%ebp),%eax
80108233:	8b 40 04             	mov    0x4(%eax),%eax
80108236:	89 04 24             	mov    %eax,(%esp)
80108239:	e8 01 f8 ff ff       	call   80107a3f <v2p>
8010823e:	89 04 24             	mov    %eax,(%esp)
80108241:	e8 ee f7 ff ff       	call   80107a34 <lcr3>
  popcli();
80108246:	e8 31 d0 ff ff       	call   8010527c <popcli>
}
8010824b:	83 c4 14             	add    $0x14,%esp
8010824e:	5b                   	pop    %ebx
8010824f:	5d                   	pop    %ebp
80108250:	c3                   	ret    

80108251 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80108251:	55                   	push   %ebp
80108252:	89 e5                	mov    %esp,%ebp
80108254:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
80108257:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
8010825e:	76 0c                	jbe    8010826c <inituvm+0x1b>
    panic("inituvm: more than a page");
80108260:	c7 04 24 3f 8f 10 80 	movl   $0x80108f3f,(%esp)
80108267:	e8 d1 82 ff ff       	call   8010053d <panic>
  mem = kalloc();
8010826c:	e8 9a a8 ff ff       	call   80102b0b <kalloc>
80108271:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
80108274:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010827b:	00 
8010827c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108283:	00 
80108284:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108287:	89 04 24             	mov    %eax,(%esp)
8010828a:	e8 ab d0 ff ff       	call   8010533a <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
8010828f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108292:	89 04 24             	mov    %eax,(%esp)
80108295:	e8 a5 f7 ff ff       	call   80107a3f <v2p>
8010829a:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
801082a1:	00 
801082a2:	89 44 24 0c          	mov    %eax,0xc(%esp)
801082a6:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801082ad:	00 
801082ae:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801082b5:	00 
801082b6:	8b 45 08             	mov    0x8(%ebp),%eax
801082b9:	89 04 24             	mov    %eax,(%esp)
801082bc:	e8 a4 fc ff ff       	call   80107f65 <mappages>
  memmove(mem, init, sz);
801082c1:	8b 45 10             	mov    0x10(%ebp),%eax
801082c4:	89 44 24 08          	mov    %eax,0x8(%esp)
801082c8:	8b 45 0c             	mov    0xc(%ebp),%eax
801082cb:	89 44 24 04          	mov    %eax,0x4(%esp)
801082cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082d2:	89 04 24             	mov    %eax,(%esp)
801082d5:	e8 33 d1 ff ff       	call   8010540d <memmove>
}
801082da:	c9                   	leave  
801082db:	c3                   	ret    

801082dc <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
801082dc:	55                   	push   %ebp
801082dd:	89 e5                	mov    %esp,%ebp
801082df:	53                   	push   %ebx
801082e0:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
801082e3:	8b 45 0c             	mov    0xc(%ebp),%eax
801082e6:	25 ff 0f 00 00       	and    $0xfff,%eax
801082eb:	85 c0                	test   %eax,%eax
801082ed:	74 0c                	je     801082fb <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
801082ef:	c7 04 24 5c 8f 10 80 	movl   $0x80108f5c,(%esp)
801082f6:	e8 42 82 ff ff       	call   8010053d <panic>
  for(i = 0; i < sz; i += PGSIZE){
801082fb:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108302:	e9 ad 00 00 00       	jmp    801083b4 <loaduvm+0xd8>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
80108307:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010830a:	8b 55 0c             	mov    0xc(%ebp),%edx
8010830d:	01 d0                	add    %edx,%eax
8010830f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108316:	00 
80108317:	89 44 24 04          	mov    %eax,0x4(%esp)
8010831b:	8b 45 08             	mov    0x8(%ebp),%eax
8010831e:	89 04 24             	mov    %eax,(%esp)
80108321:	e8 a9 fb ff ff       	call   80107ecf <walkpgdir>
80108326:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108329:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
8010832d:	75 0c                	jne    8010833b <loaduvm+0x5f>
      panic("loaduvm: address should exist");
8010832f:	c7 04 24 7f 8f 10 80 	movl   $0x80108f7f,(%esp)
80108336:	e8 02 82 ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
8010833b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010833e:	8b 00                	mov    (%eax),%eax
80108340:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108345:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
80108348:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010834b:	8b 55 18             	mov    0x18(%ebp),%edx
8010834e:	89 d1                	mov    %edx,%ecx
80108350:	29 c1                	sub    %eax,%ecx
80108352:	89 c8                	mov    %ecx,%eax
80108354:	3d ff 0f 00 00       	cmp    $0xfff,%eax
80108359:	77 11                	ja     8010836c <loaduvm+0x90>
      n = sz - i;
8010835b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010835e:	8b 55 18             	mov    0x18(%ebp),%edx
80108361:	89 d1                	mov    %edx,%ecx
80108363:	29 c1                	sub    %eax,%ecx
80108365:	89 c8                	mov    %ecx,%eax
80108367:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010836a:	eb 07                	jmp    80108373 <loaduvm+0x97>
    else
      n = PGSIZE;
8010836c:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
80108373:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108376:	8b 55 14             	mov    0x14(%ebp),%edx
80108379:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
8010837c:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010837f:	89 04 24             	mov    %eax,(%esp)
80108382:	e8 c5 f6 ff ff       	call   80107a4c <p2v>
80108387:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010838a:	89 54 24 0c          	mov    %edx,0xc(%esp)
8010838e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80108392:	89 44 24 04          	mov    %eax,0x4(%esp)
80108396:	8b 45 10             	mov    0x10(%ebp),%eax
80108399:	89 04 24             	mov    %eax,(%esp)
8010839c:	e8 bd 99 ff ff       	call   80101d5e <readi>
801083a1:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801083a4:	74 07                	je     801083ad <loaduvm+0xd1>
      return -1;
801083a6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801083ab:	eb 18                	jmp    801083c5 <loaduvm+0xe9>
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
801083ad:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801083b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083b7:	3b 45 18             	cmp    0x18(%ebp),%eax
801083ba:	0f 82 47 ff ff ff    	jb     80108307 <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
801083c0:	b8 00 00 00 00       	mov    $0x0,%eax
}
801083c5:	83 c4 24             	add    $0x24,%esp
801083c8:	5b                   	pop    %ebx
801083c9:	5d                   	pop    %ebp
801083ca:	c3                   	ret    

801083cb <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
801083cb:	55                   	push   %ebp
801083cc:	89 e5                	mov    %esp,%ebp
801083ce:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  uint a;

  if(newsz >= KERNBASE)
801083d1:	8b 45 10             	mov    0x10(%ebp),%eax
801083d4:	85 c0                	test   %eax,%eax
801083d6:	79 0a                	jns    801083e2 <allocuvm+0x17>
    return 0;
801083d8:	b8 00 00 00 00       	mov    $0x0,%eax
801083dd:	e9 c1 00 00 00       	jmp    801084a3 <allocuvm+0xd8>
  if(newsz < oldsz)
801083e2:	8b 45 10             	mov    0x10(%ebp),%eax
801083e5:	3b 45 0c             	cmp    0xc(%ebp),%eax
801083e8:	73 08                	jae    801083f2 <allocuvm+0x27>
    return oldsz;
801083ea:	8b 45 0c             	mov    0xc(%ebp),%eax
801083ed:	e9 b1 00 00 00       	jmp    801084a3 <allocuvm+0xd8>
  a = PGROUNDUP(oldsz);
801083f2:	8b 45 0c             	mov    0xc(%ebp),%eax
801083f5:	05 ff 0f 00 00       	add    $0xfff,%eax
801083fa:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801083ff:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
80108402:	e9 8d 00 00 00       	jmp    80108494 <allocuvm+0xc9>
    mem = kalloc();
80108407:	e8 ff a6 ff ff       	call   80102b0b <kalloc>
8010840c:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(mem == 0){
8010840f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108413:	75 2c                	jne    80108441 <allocuvm+0x76>
      cprintf("allocuvm out of memory\n");
80108415:	c7 04 24 9d 8f 10 80 	movl   $0x80108f9d,(%esp)
8010841c:	e8 80 7f ff ff       	call   801003a1 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80108421:	8b 45 0c             	mov    0xc(%ebp),%eax
80108424:	89 44 24 08          	mov    %eax,0x8(%esp)
80108428:	8b 45 10             	mov    0x10(%ebp),%eax
8010842b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010842f:	8b 45 08             	mov    0x8(%ebp),%eax
80108432:	89 04 24             	mov    %eax,(%esp)
80108435:	e8 6b 00 00 00       	call   801084a5 <deallocuvm>
      return 0;
8010843a:	b8 00 00 00 00       	mov    $0x0,%eax
8010843f:	eb 62                	jmp    801084a3 <allocuvm+0xd8>
    }
    memset(mem, 0, PGSIZE);
80108441:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108448:	00 
80108449:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108450:	00 
80108451:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108454:	89 04 24             	mov    %eax,(%esp)
80108457:	e8 de ce ff ff       	call   8010533a <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
8010845c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010845f:	89 04 24             	mov    %eax,(%esp)
80108462:	e8 d8 f5 ff ff       	call   80107a3f <v2p>
80108467:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010846a:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80108471:	00 
80108472:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108476:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010847d:	00 
8010847e:	89 54 24 04          	mov    %edx,0x4(%esp)
80108482:	8b 45 08             	mov    0x8(%ebp),%eax
80108485:	89 04 24             	mov    %eax,(%esp)
80108488:	e8 d8 fa ff ff       	call   80107f65 <mappages>
  if(newsz >= KERNBASE)
    return 0;
  if(newsz < oldsz)
    return oldsz;
  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
8010848d:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108494:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108497:	3b 45 10             	cmp    0x10(%ebp),%eax
8010849a:	0f 82 67 ff ff ff    	jb     80108407 <allocuvm+0x3c>
      return 0;
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
  }
  return newsz;
801084a0:	8b 45 10             	mov    0x10(%ebp),%eax
}
801084a3:	c9                   	leave  
801084a4:	c3                   	ret    

801084a5 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
801084a5:	55                   	push   %ebp
801084a6:	89 e5                	mov    %esp,%ebp
801084a8:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
801084ab:	8b 45 10             	mov    0x10(%ebp),%eax
801084ae:	3b 45 0c             	cmp    0xc(%ebp),%eax
801084b1:	72 08                	jb     801084bb <deallocuvm+0x16>
    return oldsz;
801084b3:	8b 45 0c             	mov    0xc(%ebp),%eax
801084b6:	e9 a4 00 00 00       	jmp    8010855f <deallocuvm+0xba>

  a = PGROUNDUP(newsz);
801084bb:	8b 45 10             	mov    0x10(%ebp),%eax
801084be:	05 ff 0f 00 00       	add    $0xfff,%eax
801084c3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801084c8:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
801084cb:	e9 80 00 00 00       	jmp    80108550 <deallocuvm+0xab>
    pte = walkpgdir(pgdir, (char*)a, 0);
801084d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084d3:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801084da:	00 
801084db:	89 44 24 04          	mov    %eax,0x4(%esp)
801084df:	8b 45 08             	mov    0x8(%ebp),%eax
801084e2:	89 04 24             	mov    %eax,(%esp)
801084e5:	e8 e5 f9 ff ff       	call   80107ecf <walkpgdir>
801084ea:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(!pte)
801084ed:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801084f1:	75 09                	jne    801084fc <deallocuvm+0x57>
      a += (NPTENTRIES - 1) * PGSIZE;
801084f3:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
801084fa:	eb 4d                	jmp    80108549 <deallocuvm+0xa4>
    else if((*pte & PTE_P) != 0){
801084fc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801084ff:	8b 00                	mov    (%eax),%eax
80108501:	83 e0 01             	and    $0x1,%eax
80108504:	84 c0                	test   %al,%al
80108506:	74 41                	je     80108549 <deallocuvm+0xa4>
      pa = PTE_ADDR(*pte);
80108508:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010850b:	8b 00                	mov    (%eax),%eax
8010850d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108512:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if(pa == 0)
80108515:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108519:	75 0c                	jne    80108527 <deallocuvm+0x82>
        panic("kfree");
8010851b:	c7 04 24 b5 8f 10 80 	movl   $0x80108fb5,(%esp)
80108522:	e8 16 80 ff ff       	call   8010053d <panic>
      char *v = p2v(pa);
80108527:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010852a:	89 04 24             	mov    %eax,(%esp)
8010852d:	e8 1a f5 ff ff       	call   80107a4c <p2v>
80108532:	89 45 e8             	mov    %eax,-0x18(%ebp)
      kfree(v);
80108535:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108538:	89 04 24             	mov    %eax,(%esp)
8010853b:	e8 32 a5 ff ff       	call   80102a72 <kfree>
      *pte = 0;
80108540:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108543:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
80108549:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108550:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108553:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108556:	0f 82 74 ff ff ff    	jb     801084d0 <deallocuvm+0x2b>
      char *v = p2v(pa);
      kfree(v);
      *pte = 0;
    }
  }
  return newsz;
8010855c:	8b 45 10             	mov    0x10(%ebp),%eax
}
8010855f:	c9                   	leave  
80108560:	c3                   	ret    

80108561 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
80108561:	55                   	push   %ebp
80108562:	89 e5                	mov    %esp,%ebp
80108564:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
80108567:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010856b:	75 0c                	jne    80108579 <freevm+0x18>
    panic("freevm: no pgdir");
8010856d:	c7 04 24 bb 8f 10 80 	movl   $0x80108fbb,(%esp)
80108574:	e8 c4 7f ff ff       	call   8010053d <panic>
  deallocuvm(pgdir, KERNBASE, 0);
80108579:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108580:	00 
80108581:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
80108588:	80 
80108589:	8b 45 08             	mov    0x8(%ebp),%eax
8010858c:	89 04 24             	mov    %eax,(%esp)
8010858f:	e8 11 ff ff ff       	call   801084a5 <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
80108594:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010859b:	eb 6e                	jmp    8010860b <freevm+0xaa>
    if(pgdir[i] & PTE_P){
8010859d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085a0:	c1 e0 02             	shl    $0x2,%eax
801085a3:	03 45 08             	add    0x8(%ebp),%eax
801085a6:	8b 00                	mov    (%eax),%eax
801085a8:	83 e0 01             	and    $0x1,%eax
801085ab:	84 c0                	test   %al,%al
801085ad:	74 58                	je     80108607 <freevm+0xa6>
      char * v = p2v(PTE_ADDR(pgdir[i]));
801085af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085b2:	c1 e0 02             	shl    $0x2,%eax
801085b5:	03 45 08             	add    0x8(%ebp),%eax
801085b8:	8b 00                	mov    (%eax),%eax
801085ba:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801085bf:	89 04 24             	mov    %eax,(%esp)
801085c2:	e8 85 f4 ff ff       	call   80107a4c <p2v>
801085c7:	89 45 f0             	mov    %eax,-0x10(%ebp)
      cprintf("before kfree pid = %d\n",proc->pid);
801085ca:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801085d0:	8b 40 10             	mov    0x10(%eax),%eax
801085d3:	89 44 24 04          	mov    %eax,0x4(%esp)
801085d7:	c7 04 24 cc 8f 10 80 	movl   $0x80108fcc,(%esp)
801085de:	e8 be 7d ff ff       	call   801003a1 <cprintf>
      kfree(v);
801085e3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801085e6:	89 04 24             	mov    %eax,(%esp)
801085e9:	e8 84 a4 ff ff       	call   80102a72 <kfree>
      cprintf("after kfree pid = %d\n",proc->pid);
801085ee:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801085f4:	8b 40 10             	mov    0x10(%eax),%eax
801085f7:	89 44 24 04          	mov    %eax,0x4(%esp)
801085fb:	c7 04 24 e3 8f 10 80 	movl   $0x80108fe3,(%esp)
80108602:	e8 9a 7d ff ff       	call   801003a1 <cprintf>
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
  for(i = 0; i < NPDENTRIES; i++){
80108607:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010860b:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
80108612:	76 89                	jbe    8010859d <freevm+0x3c>
      cprintf("before kfree pid = %d\n",proc->pid);
      kfree(v);
      cprintf("after kfree pid = %d\n",proc->pid);
    }
  }
  kfree((char*)pgdir);
80108614:	8b 45 08             	mov    0x8(%ebp),%eax
80108617:	89 04 24             	mov    %eax,(%esp)
8010861a:	e8 53 a4 ff ff       	call   80102a72 <kfree>
}
8010861f:	c9                   	leave  
80108620:	c3                   	ret    

80108621 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80108621:	55                   	push   %ebp
80108622:	89 e5                	mov    %esp,%ebp
80108624:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80108627:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010862e:	00 
8010862f:	8b 45 0c             	mov    0xc(%ebp),%eax
80108632:	89 44 24 04          	mov    %eax,0x4(%esp)
80108636:	8b 45 08             	mov    0x8(%ebp),%eax
80108639:	89 04 24             	mov    %eax,(%esp)
8010863c:	e8 8e f8 ff ff       	call   80107ecf <walkpgdir>
80108641:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
80108644:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80108648:	75 0c                	jne    80108656 <clearpteu+0x35>
    panic("clearpteu");
8010864a:	c7 04 24 f9 8f 10 80 	movl   $0x80108ff9,(%esp)
80108651:	e8 e7 7e ff ff       	call   8010053d <panic>
  *pte &= ~PTE_U;
80108656:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108659:	8b 00                	mov    (%eax),%eax
8010865b:	89 c2                	mov    %eax,%edx
8010865d:	83 e2 fb             	and    $0xfffffffb,%edx
80108660:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108663:	89 10                	mov    %edx,(%eax)
}
80108665:	c9                   	leave  
80108666:	c3                   	ret    

80108667 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
80108667:	55                   	push   %ebp
80108668:	89 e5                	mov    %esp,%ebp
8010866a:	83 ec 48             	sub    $0x48,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
8010866d:	e8 87 f9 ff ff       	call   80107ff9 <setupkvm>
80108672:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108675:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108679:	75 0a                	jne    80108685 <copyuvm+0x1e>
    return 0;
8010867b:	b8 00 00 00 00       	mov    $0x0,%eax
80108680:	e9 f1 00 00 00       	jmp    80108776 <copyuvm+0x10f>
  for(i = 0; i < sz; i += PGSIZE){
80108685:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010868c:	e9 c0 00 00 00       	jmp    80108751 <copyuvm+0xea>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
80108691:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108694:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010869b:	00 
8010869c:	89 44 24 04          	mov    %eax,0x4(%esp)
801086a0:	8b 45 08             	mov    0x8(%ebp),%eax
801086a3:	89 04 24             	mov    %eax,(%esp)
801086a6:	e8 24 f8 ff ff       	call   80107ecf <walkpgdir>
801086ab:	89 45 ec             	mov    %eax,-0x14(%ebp)
801086ae:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801086b2:	75 0c                	jne    801086c0 <copyuvm+0x59>
      panic("copyuvm: pte should exist");
801086b4:	c7 04 24 03 90 10 80 	movl   $0x80109003,(%esp)
801086bb:	e8 7d 7e ff ff       	call   8010053d <panic>
    if(!(*pte & PTE_P))
801086c0:	8b 45 ec             	mov    -0x14(%ebp),%eax
801086c3:	8b 00                	mov    (%eax),%eax
801086c5:	83 e0 01             	and    $0x1,%eax
801086c8:	85 c0                	test   %eax,%eax
801086ca:	75 0c                	jne    801086d8 <copyuvm+0x71>
      panic("copyuvm: page not present");
801086cc:	c7 04 24 1d 90 10 80 	movl   $0x8010901d,(%esp)
801086d3:	e8 65 7e ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
801086d8:	8b 45 ec             	mov    -0x14(%ebp),%eax
801086db:	8b 00                	mov    (%eax),%eax
801086dd:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801086e2:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if((mem = kalloc()) == 0)
801086e5:	e8 21 a4 ff ff       	call   80102b0b <kalloc>
801086ea:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801086ed:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
801086f1:	74 6f                	je     80108762 <copyuvm+0xfb>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
801086f3:	8b 45 e8             	mov    -0x18(%ebp),%eax
801086f6:	89 04 24             	mov    %eax,(%esp)
801086f9:	e8 4e f3 ff ff       	call   80107a4c <p2v>
801086fe:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108705:	00 
80108706:	89 44 24 04          	mov    %eax,0x4(%esp)
8010870a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010870d:	89 04 24             	mov    %eax,(%esp)
80108710:	e8 f8 cc ff ff       	call   8010540d <memmove>
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
80108715:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80108718:	89 04 24             	mov    %eax,(%esp)
8010871b:	e8 1f f3 ff ff       	call   80107a3f <v2p>
80108720:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108723:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
8010872a:	00 
8010872b:	89 44 24 0c          	mov    %eax,0xc(%esp)
8010872f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108736:	00 
80108737:	89 54 24 04          	mov    %edx,0x4(%esp)
8010873b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010873e:	89 04 24             	mov    %eax,(%esp)
80108741:	e8 1f f8 ff ff       	call   80107f65 <mappages>
80108746:	85 c0                	test   %eax,%eax
80108748:	78 1b                	js     80108765 <copyuvm+0xfe>
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
8010874a:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108751:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108754:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108757:	0f 82 34 ff ff ff    	jb     80108691 <copyuvm+0x2a>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
  }
  return d;
8010875d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108760:	eb 14                	jmp    80108776 <copyuvm+0x10f>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
    if((mem = kalloc()) == 0)
      goto bad;
80108762:	90                   	nop
80108763:	eb 01                	jmp    80108766 <copyuvm+0xff>
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
80108765:	90                   	nop
  }
  return d;

bad:
  freevm(d);
80108766:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108769:	89 04 24             	mov    %eax,(%esp)
8010876c:	e8 f0 fd ff ff       	call   80108561 <freevm>
  return 0;
80108771:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108776:	c9                   	leave  
80108777:	c3                   	ret    

80108778 <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
80108778:	55                   	push   %ebp
80108779:	89 e5                	mov    %esp,%ebp
8010877b:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
8010877e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108785:	00 
80108786:	8b 45 0c             	mov    0xc(%ebp),%eax
80108789:	89 44 24 04          	mov    %eax,0x4(%esp)
8010878d:	8b 45 08             	mov    0x8(%ebp),%eax
80108790:	89 04 24             	mov    %eax,(%esp)
80108793:	e8 37 f7 ff ff       	call   80107ecf <walkpgdir>
80108798:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
8010879b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010879e:	8b 00                	mov    (%eax),%eax
801087a0:	83 e0 01             	and    $0x1,%eax
801087a3:	85 c0                	test   %eax,%eax
801087a5:	75 07                	jne    801087ae <uva2ka+0x36>
    return 0;
801087a7:	b8 00 00 00 00       	mov    $0x0,%eax
801087ac:	eb 25                	jmp    801087d3 <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
801087ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087b1:	8b 00                	mov    (%eax),%eax
801087b3:	83 e0 04             	and    $0x4,%eax
801087b6:	85 c0                	test   %eax,%eax
801087b8:	75 07                	jne    801087c1 <uva2ka+0x49>
    return 0;
801087ba:	b8 00 00 00 00       	mov    $0x0,%eax
801087bf:	eb 12                	jmp    801087d3 <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
801087c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087c4:	8b 00                	mov    (%eax),%eax
801087c6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801087cb:	89 04 24             	mov    %eax,(%esp)
801087ce:	e8 79 f2 ff ff       	call   80107a4c <p2v>
}
801087d3:	c9                   	leave  
801087d4:	c3                   	ret    

801087d5 <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
801087d5:	55                   	push   %ebp
801087d6:	89 e5                	mov    %esp,%ebp
801087d8:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
801087db:	8b 45 10             	mov    0x10(%ebp),%eax
801087de:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
801087e1:	e9 8b 00 00 00       	jmp    80108871 <copyout+0x9c>
    va0 = (uint)PGROUNDDOWN(va);
801087e6:	8b 45 0c             	mov    0xc(%ebp),%eax
801087e9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801087ee:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
801087f1:	8b 45 ec             	mov    -0x14(%ebp),%eax
801087f4:	89 44 24 04          	mov    %eax,0x4(%esp)
801087f8:	8b 45 08             	mov    0x8(%ebp),%eax
801087fb:	89 04 24             	mov    %eax,(%esp)
801087fe:	e8 75 ff ff ff       	call   80108778 <uva2ka>
80108803:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
80108806:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
8010880a:	75 07                	jne    80108813 <copyout+0x3e>
      return -1;
8010880c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108811:	eb 6d                	jmp    80108880 <copyout+0xab>
    n = PGSIZE - (va - va0);
80108813:	8b 45 0c             	mov    0xc(%ebp),%eax
80108816:	8b 55 ec             	mov    -0x14(%ebp),%edx
80108819:	89 d1                	mov    %edx,%ecx
8010881b:	29 c1                	sub    %eax,%ecx
8010881d:	89 c8                	mov    %ecx,%eax
8010881f:	05 00 10 00 00       	add    $0x1000,%eax
80108824:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
80108827:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010882a:	3b 45 14             	cmp    0x14(%ebp),%eax
8010882d:	76 06                	jbe    80108835 <copyout+0x60>
      n = len;
8010882f:	8b 45 14             	mov    0x14(%ebp),%eax
80108832:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
80108835:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108838:	8b 55 0c             	mov    0xc(%ebp),%edx
8010883b:	89 d1                	mov    %edx,%ecx
8010883d:	29 c1                	sub    %eax,%ecx
8010883f:	89 c8                	mov    %ecx,%eax
80108841:	03 45 e8             	add    -0x18(%ebp),%eax
80108844:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108847:	89 54 24 08          	mov    %edx,0x8(%esp)
8010884b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010884e:	89 54 24 04          	mov    %edx,0x4(%esp)
80108852:	89 04 24             	mov    %eax,(%esp)
80108855:	e8 b3 cb ff ff       	call   8010540d <memmove>
    len -= n;
8010885a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010885d:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
80108860:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108863:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
80108866:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108869:	05 00 10 00 00       	add    $0x1000,%eax
8010886e:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
80108871:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
80108875:	0f 85 6b ff ff ff    	jne    801087e6 <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
8010887b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108880:	c9                   	leave  
80108881:	c3                   	ret    
