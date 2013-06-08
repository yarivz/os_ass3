// Physical memory allocator, intended to allocate
// memory for user processes, kernel stacks, page table pages,
// and pipe buffers. Allocates 4096-byte pages.

#include "types.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "mmu.h"
#include "spinlock.h"
#include "proc.h"

void freerange(void *vstart, void *vend);
extern char end[]; // first address after kernel loaded from ELF file

struct run {
  struct run *next;
};

struct {
  struct spinlock lock;
  int use_lock;
  struct run *freelist;
} kmem;

struct {
  char* seg[numOfSegs][numOfSegs];
  int refs[numOfSegs][2][65];
  struct spinlock lock;
} shm;

// Initialization happens in two phases.
// 1. main() calls kinit1() while still using entrypgdir to place just
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
  initlock(&kmem.lock, "kmem");
  kmem.use_lock = 0;
  freerange(vstart, vend);
}

void
kinit2(void *vstart, void *vend)
{
  freerange(vstart, vend);
  kmem.use_lock = 1;
}

void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
    kfree(p);
}

//PAGEBREAK: 21
// Free the page of physical memory pointed at by v,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
  struct run *r;

  if((uint)v % PGSIZE || v < end || v2p(v) >= PHYSTOP)
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);

  if(kmem.use_lock)
    acquire(&kmem.lock);
  r = (struct run*)v;
  r->next = kmem.freelist;
  kmem.freelist = r;
  if(kmem.use_lock)
    release(&kmem.lock);
}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
  struct run *r;

  if(kmem.use_lock)
    acquire(&kmem.lock);
  r = kmem.freelist;
  if(r)
    kmem.freelist = r->next;
  if(kmem.use_lock)
    release(&kmem.lock);
  return (char*)r;
}


int 
shmget(int key, uint size, int shmflg)
{
  int numOfPages,i,j,ans;
  uint sz;
  if(key < 0 || key > 1023)
  {
    cprintf("Illegal key exception, value must be between 0-1023\n");
    return -1;
  }
  
  switch(shmflg)
  {
    case CREAT:
      if(shm.refs[key][1][64] == 0)
      {
	sz = PGROUNDUP(size);
	numOfPages = sz/PGSIZE;
	for(i=0;i<numOfPages;i++)
	{
	  if((shm.seg[key][i] = kalloc()) == 0)
	    break;
	}
	
	if(i == numOfPages)
	{
	  ans = (int)shm.seg[key][0];
	  shm.refs[key][1][64] = numOfPages;
	}
	else
	{
	  for(j=0;j<i;j++)
	    kfree(shm.seg[key][j]);
	  ans = -1;
	}
      }
      else
	ans = -1;
      break;
    case GET:
      if(!shm.refs[key][1][64])
	ans = -1;
      else
	ans = (int)shm.seg[key][0];
      break;
  }
  return ans;
}

int 
shmdel(int shmid)
{
  int key,ans = -1,numOfPages,i;
  for(key = 0;key<numOfSegs;key++)
  {
    if(shmid == (int)shm.seg[key][0])
    {
      if(shm.refs[key][0][64]>0)
      {
	break;
      }
      else
      {
	numOfPages=shm.refs[key][1][64];
	for(i=0;i<numOfPages;i++)
	    kfree(shm.seg[key][i]);
      }
      ans = numOfPages;
    }
    break;
  }  
  return ans;
}

void *
shmat(int shmid, int shmflg)
{
  int i,key,forFlag=0;
  void* ans = (void*)-1;
  char* mem;
  uint a;

  acquire(&shm.lock);
  for(key = 0;key<numOfSegs;key++)
  {
    if(shmid == (int)shm.seg[key][0])
    {
      if(shm.refs[key][1][64]>0)
      {
	a = PGROUNDUP(proc->sz);
	ans = (void*)a;
	if(a + PGSIZE >= KERNBASE)
	{
	  ans = (void*)-1;
	  break;
	}
	
	shm.refs[key][0][64]++;
	shm.refs[key][0][proc->pid] = 1;
	proc->has_shm++;
	
	for(i = 0;i < shm.refs[key][1][64] && a < KERNBASE;i++,a += PGSIZE)
	{
	    forFlag = 1;
	    mem = shm.seg[key][i];
	    switch(shmflg)
	    {
	      case SHM_RDONLY:
		mappages(proc->pgdir, (char*)a, PGSIZE, v2p(mem), PTE_U);
		break;
	      case SHM_RDWR:
		mappages(proc->pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
		break;
	      default:
		forFlag = 0;
	    } 
	}
	if(forFlag)
	  proc->sz = a;
	else
	  ans = (void*)-1;
	break;
      }
      else
      	break;
    }
  }
  release(&shm.lock);
  return ans;
}

int 
shmdt(const void *shmaddr)
{
  pte_t *pte;
  uint r, numOfPages;
  int key,found;
  pte = walkpgdir(proc->pgdir, (char*)shmaddr, 0);
  r = (int)p2v(PTE_ADDR(*pte)) ;
  acquire(&shm.lock);
  for(found = 0,key = 0;key<numOfSegs;key++)
  {    
    if((int)shm.seg[key][0] == r)
    {  
      if(shm.refs[key][1][64]>0)
      { 
	if(shm.refs[key][0][64] <= 0)
	{
	  cprintf("shmdt exception - trying to detach a segment with no references\n");
	  return -1;
	}
	shm.refs[key][0][64]--;
	shm.refs[key][0][proc->pid] = 0;
	proc->has_shm--;
	numOfPages = shm.refs[key][1][64];
	found = 1;
	break;
      }
      else
      {
	cprintf("shmdt exception - trying to detach a segment with no pages\n");
	return -1;
      }
    }
  }
  release(&shm.lock);
  
  if(!found)
    return -1;

  void *shmaddr2 = (void*)shmaddr;

  for(; shmaddr2  < shmaddr + numOfPages*PGSIZE; shmaddr2 += PGSIZE)
  {
    pte = walkpgdir(proc->pgdir, (char*)shmaddr2, 0);
    if(!pte)
      shmaddr2 += (NPTENTRIES - 1) * PGSIZE;
    *pte = 0;
  }

  return 0;
}

void 
deallocshm(int pid)
{
  cprintf("in deallocshm\n");	
  uint a = 0;
  int key, pa, numOfPages;
  pte_t *pte;
  
  acquire(&shm.lock);
  for(key = 0;key<numOfSegs;key++)
  {    
    if(shm.refs[key][0][proc->pid])
    {
      for(; a  < proc->sz; a += PGSIZE)
      {
	pte = walkpgdir(proc->pgdir, (char*)a, 0);
	if(!pte)
	  a += (NPTENTRIES - 1) * PGSIZE;
	else if((*pte & PTE_P) != 0)
	{
	  pa = (int)p2v(PTE_ADDR(*pte));
	  if((int)shm.seg[key][0] == pa)
	  {
	    void *b = (void*)a;
	    numOfPages = shm.refs[key][1][64];
	    for(; b  < (void*)a + numOfPages*PGSIZE; b += PGSIZE)
	    {
	      pte = walkpgdir(proc->pgdir, (char*)b, 0);
	      if(!pte)
		b += (NPTENTRIES - 1) * PGSIZE;
	      *pte = 0;
	    }
	    if(shm.refs[key][0][64]>0)
	      shm.refs[key][0][64]--;
	    break;
	  }
	}
      }
    }
  }
  release(&shm.lock);
}
        