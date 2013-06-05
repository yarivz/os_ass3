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
  struct run* seg[1024];
  int refs[1024];
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
      if(!shm.seg[key])
      {
	struct run* r = kmem.freelist;
	size = PGROUNDUP(size);
	numOfPages = size/PGSIZE;
	shm.seg[key] = kmem.freelist;
	
	for(i=0;i<numOfPages;i++)
	{
	  r = r->next;
	}
	
	if(i == numOfPages-1)
	{
	  kmem.freelist = r->next;
	  ans = (int)shm.seg[key];
	  shm.refs[key]++;
	}
	else
	{
	  shm.seg[key] = 0;
	  ans = -1;
	}
	break;
      }
      else
	ans = -1;
      break;
    case GET:
      if(!shm.seg[key])
	ans = -1;
      else
      {
	ans = (int)shm.seg[key];
	shm.refs[key]++;
      }
      break;
  }
  if(kmem.use_lock)
    release(&kmem.lock);
  
  return ans;
}

int shmdel(int shmid)
{
  int key,ans,numOfPages;
  struct run* r;
  if(kmem.use_lock)
    acquire(&kmem.lock);
  struct run* ptr;
  for(key = 0,ptr = shm.seg[0];ptr<shm.seg[1024];ptr += sizeof(struct run*),key++)
  {
    if(shmid == (int)ptr)
    {
      if(shm.refs[key])
	ans = -1;
      else
      {
	for(r = shm.seg[key],numOfPages=0;r->next;r = r->next,numOfPages++)
	  // Fill with junk to catch dangling refs.
	  memset(r, 1, PGSIZE);
	r->next = kmem.freelist;
	kmem.freelist = shm.seg[key];
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
  int key;
  struct run* r;
  void* ans;
  char* mem;

  acquire(&shm.lock);
  struct run* ptr;
  for(key = 0,ptr = shm.seg[0];ptr<shm.seg[1024];ptr += sizeof(struct run*),key++)
  {
    if(shmid == (int)ptr)
    {
      if(shm.refs[key])
      {
	if(proc->sz + PGSIZE >= KERNBASE)
	{
	  ans = (void*)-1;
	  break;
	}
	
	shm.refs[key]++;
	
	for(r = shm.seg[key];r->next && proc->sz < KERNBASE;r = r->next,proc->sz += PGSIZE)
	{
	    mem = (char*)r;
	    
	    switch(shmflg)
	    {
	      case SHM_RDONLY:
		mappages(proc->pgdir, (char*)proc->sz, PGSIZE, v2p(mem), PTE_U);
		break;
	      case SHM_RDWR:
		mappages(proc->pgdir, (char*)proc->sz, PGSIZE, v2p(mem), PTE_W|PTE_U);
		break;
	    } 
	}
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
  
}
