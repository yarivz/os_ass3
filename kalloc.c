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
  struct run* seg[numOfSegs];
  int refs[numOfSegs][2];
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


int shmget(int key, uint size, int shmflg)
{
  int numOfPages,i,ans;
  if(kmem.use_lock)
    acquire(&kmem.lock);
  switch(shmflg)
  {
    case CREAT:
      if(!shm.refs[key][1])
      {
	struct run* r = kmem.freelist;
	size = PGROUNDUP(size);
	numOfPages = size/PGSIZE;
	shm.seg[key] = (kmem.freelist);
	
	for(i=0;i<numOfPages;i++)
	{
	  r = r->next;
	}
	
	if(i == numOfPages)
	{
	  for(;kmem.freelist->next!=r;kmem.freelist = kmem.freelist->next);
	  kmem.freelist->next = 0;
	  kmem.freelist = r;
	  ans = (int)shm.seg[key];
	  shm.refs[key][1] = numOfPages;
	}
	else
	  ans = -1;
	break;
      }
      else
	ans = -1;
      break;
    case GET:
      if(!shm.refs[key][1])
	ans = -1;
      else
	ans = (int)shm.seg[key];
      break;
  }
  if(kmem.use_lock)
    release(&kmem.lock);
  return ans;
}

int shmdel(int shmid)
{
  int key,ans = -1,numOfPages;
  struct run* r;
  if(kmem.use_lock)
    acquire(&kmem.lock);
  for(key = 0;key<numOfSegs;key++)
  {
    if(shmid == (int)shm.seg[key])
    {
      if(shm.refs[key][0])
	break;
      else
      {
	for(r = shm.seg[key],numOfPages=1;r->next;r = r->next,numOfPages++)
	{
	  // Fill with junk to catch dangling refs.
	  memset(r, 1, PGSIZE);
	}
	r->next = kmem.freelist;
	kmem.freelist = shm.seg[key];
	shm.refs[key][1] = 0;
	ans = numOfPages;
      }
      break;
    }
  }
  if(kmem.use_lock)
    release(&kmem.lock);
  
  return ans;
}

void *shmat(int shmid, int shmflg)
{
  int key,forFlag=0;
  struct run* r;
  void* ans;
  char* mem;
  uint a;

  acquire(&shm.lock);
  for(key = 0;key<numOfSegs;key++)
  {
    if(shmid == (int)shm.seg[key])
    {
      if(shm.refs[key][1])
      {
	a = PGROUNDUP(proc->sz);
	ans = (void*)a;
	if(a + PGSIZE >= KERNBASE)
	{
	  ans = (void*)-1;
	  break;
	}
	
	shm.refs[key][0]++;
	
	for(r = shm.seg[key];r && a < KERNBASE;r = r->next,a += PGSIZE)
	{
	    forFlag = 1;
	    mem = (char*)r;
	    
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
	break;
      }
      else
      {
	ans = (void*)-1;
	break;
      }
    }
  }
  
  
  release(&shm.lock);
  
  return ans;
}

int shmdt(const void *shmaddr)
{
 
  pte_t *pte;
  uint r, numOfPages;
  int key,found;
  cprintf("before wlkpgdir\n");
  pte = walkpgdir(proc->pgdir, (char*)shmaddr, 0);
  r = (int)p2v(*pte) ;
  acquire(&shm.lock);
  for(found = 0,key = 0;key<numOfSegs;key++)
  {    cprintf("in for: (int)shm.seg[key] = %d, r= %d\n",(int)shm.seg[key],r);

    if(((int)shm.seg[key]| PTE_U | PTE_P | PTE_W) == r || ((int)shm.seg[key]| PTE_U | PTE_P) == r)
    {  
  cprintf("in if\n");

      if(shm.refs[key][1])
      {  cprintf("in if2\n");

	if(shm.refs[key][0])
	  shm.refs[key][0]--;
	numOfPages = shm.refs[key][1];
	found = 1;
	break;
      }
      else
	return -1;
    }
  }
  release(&shm.lock);
  
  if(!found)
    return -1;

  void * shmaddr2 = (void*)shmaddr;

  for(; shmaddr2  < shmaddr + numOfPages*PGSIZE; shmaddr2 += PGSIZE)
  {
    pte = walkpgdir(proc->pgdir, (char*)shmaddr2, 0);
    if(!pte)
      shmaddr2 += (NPTENTRIES - 1) * PGSIZE;
    *pte = 0;
  }

  return 0;
}
