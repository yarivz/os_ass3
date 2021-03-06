#include "types.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "mmu.h"
#include "x86.h"
#include "proc.h"
#include "spinlock.h"
#include "fcntl.h"
#include "stat.h"
#include "file.h"
#include "fs.h"

struct {
  struct spinlock lock;
  struct proc proc[NPROC];
} ptable;

static struct proc *initproc;
static struct proc *inswapper;		//the inswapper proc
static struct spinlock swaplock;	//spinlock to sync access to the inswapper
static struct spinlock wakeuplock;

int nextpid = 1;
int swapFlag = 0;			//global flag to indicate if swapping is enabled (1) or disabled (0)
int swappedout = 0;			//counter for the number of procs in the RUNNABLE_SUSPENDED state

extern void forkret(void);
extern void trapret(void);

static void wakeup1(void *chan);

void
pinit(void)
{
  initlock(&ptable.lock, "ptable");
  initlock(&swaplock, "swaplock");
  initlock(&wakeuplock, "wakeuplock");
}

//PAGEBREAK: 32
// Look in the process table for an UNUSED proc.
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
  p->pid = nextpid++;
  release(&ptable.lock);

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
    p->state = UNUSED;
    return 0;
  }
  sp = p->kstack + KSTACKSIZE;
  
  // Leave room for trap frame.
  sp -= sizeof *p->tf;
  p->tf = (struct trapframe*)sp;
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
  *(uint*)sp = (uint)trapret;

  sp -= sizeof *p->context;
  p->context = (struct context*)sp;
  memset(p->context, 0, sizeof *p->context);
  p->context->eip = (uint)forkret;
  int i = 0;						//added a swpFileName field to each proc which is determined on proc creation
  char name[8];
  name[2] = '.'; name[3] = 's'; name[4] = 'w'; name[5] = 'a'; name[6] = 'p'; name[7] = 0;
  name[1] = (char)(((int)'0')+p->pid % 10);
  if((i=p->pid/10) == 0)
    name[0] = '0';
  else
    name[0] = (char)(((int)'0')+i);
  //release(&ptable.lock);
  safestrcpy(p->swapFileName, name, sizeof(name));
  return p;
}


void createInternalProcess(const char *name, void (*entrypoint)())		//create a kernel process
{
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
    return;

  // Copy process state from p.
  if((np->pgdir = setupkvm(kalloc)) == 0)
      panic("inswapper: out of memory?");

  np->sz = PGSIZE;
  np->parent = initproc;				//set parent to init
  memset(np->tf, 0, sizeof(*np->tf));
  np->tf->cs = (SEG_KCODE << 3)|0;
  np->tf->ds = (SEG_KDATA << 3)|0;
  np->tf->es = np->tf->ds;
  np->tf->ss = np->tf->ds;
  np->tf->eflags = FL_IF;
  //np->tf->esp = (uint)entrypoint+PGSIZE;
  //np->tf->eip = (uint)entrypoint;
  np->context->eip = (uint)entrypoint;			//set eip to entrypoint so proc will start running there

  inswapper = np;
  np->cwd = namei("/");					//set cwd to root so all swap files are created there
  safestrcpy(np->name, name, sizeof(name));
  np->state = RUNNABLE;
}

void swapIn()						//the inswapper's function
{
  struct proc* t;
  for(;;)
  {
swapin:
    for(t = ptable.proc; t < &ptable.proc[NPROC]; t++)	//run over all of ptable and look for RUNNABLE_SUSPENDED
    {
      if(t->state != RUNNABLE_SUSPENDED)
	continue;
      
      //open file pid.swap
      if(holding(&ptable.lock))				//release ptable before every file operation and acquire it afterwards
	release(&ptable.lock);
      if((t->swap = fileopen(t->swapFileName,O_RDONLY)) == 0)	//open the swapfile
      {
	cprintf("fileopen failed\n");
	//acquire(&ptable.lock);
	break;
      }cprintf("1\n");
      //acquire(&ptable.lock);
            
      // allocate virtual memory
//       if((t->pgdir = setupkvm(kalloc)) == 0)			
// 	panic("inswapper: out of memory?");
      if(!allocuvm(t->pgdir, 0, t->sz))				//allocate virtual memory
      {
	cprintf("allocuvm failed\n");
	break;
      }
      
//       if(holding(&ptable.lock))
// 	release(&ptable.lock);
      loaduvm(t->pgdir,0,t->swap->ip,0,t->sz);			//load the swap file content to memory
      
//       int fd;
//       for(fd = 0; fd < NOFILE; fd++)
//       {
// 	if(proc->ofile[fd] && proc->ofile[fd] == t->swap)	//close the swap file
// 	{
// 	  fileclose(proc->ofile[fd]);
// 	  proc->ofile[fd] = 0;
// 	  break;
// 	}
//       }
      fileclose( t->swap);
      t->swap=0;
      unlink(t->swapFileName);	cprintf("3\n");				//delete the swap file
      
      acquire(&ptable.lock);
      t->state = RUNNABLE;
      
      acquire(&swaplock);
      swappedout--;						//update swapped out counter atomically
      release(&swaplock);
    }
   
    acquire(&swaplock);
    if(swappedout > 0)						//check if should sleep
    {
      release(&swaplock);
      goto swapin;
    }
    else
      release(&swaplock);

    proc->chan = inswapper;
    proc->state = SLEEPING;					//set inswapper to sleeping
     
     sched();
     proc->chan = 0;
  }
}

void
swapOut()
{
    if((proc->swap = fileopen(proc->swapFileName,(O_CREATE | O_RDWR))) == 0)	//create the swapfile
    {
	cprintf("could not create swapfile %s\n",proc->swapFileName);
	return;
    }cprintf("2\n");
    pte_t *pte;
    uint pa, j;
    for(j = 0; j < proc->sz; j += PGSIZE)
    {
      if((pte = walkpgdir(proc->pgdir, (void *) j, 0)) == 0)		//traverse proc's virtual memory and find valid PTEs 
	panic("walkpgdir: pte should exist");
      if(!(*pte & PTE_P))
	panic("walkpgdir: page not present");
      pa = PTE_ADDR(*pte);
      if(filewrite(proc->swap, (char*)p2v(pa), PGSIZE) < 0){		//write each PTE found to swapfile
	cprintf("could not swap out proc pid %d, filewrite failed\n",proc->pid);
	return;
      }
    }

//     int fd;
//     for(fd = 0; fd < NOFILE; fd++)
//     {
//       if(proc->ofile[fd] && proc->ofile[fd] == proc->swap)		//close swapfile
//       {
// 	fileclose(proc->ofile[fd]);
// 	proc->ofile[fd] = 0;
// 	break;
//       }
//     }
    fileclose(proc->swap);
    proc->swap=0;
    deallocuvm(proc->pgdir,proc->sz,0);				//release user virtual memory
}

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
  initproc = p;
  if((p->pgdir = setupkvm(kalloc)) == 0)
    panic("userinit: out of memory?");
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
  p->sz = PGSIZE;
  memset(p->tf, 0, sizeof(*p->tf));
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
  p->tf->es = p->tf->ds;
  p->tf->ss = p->tf->ds;
  p->tf->eflags = FL_IF;
  p->tf->esp = PGSIZE;
  p->tf->eip = 0;  // beginning of initcode.S

  safestrcpy(p->name, "initcode", sizeof(p->name));
  p->cwd = namei("/");

  p->state = RUNNABLE;

  createInternalProcess("inswapper", swapIn);
}

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
  uint sz;
  
  sz = proc->sz;
  if(n > 0){
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
      return -1;
  } else if(n < 0){
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
      return -1;
  }
  proc->sz = sz;
  switchuvm(proc);
  return 0;
}

// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
    return -1;
  
  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
    kfree(np->kstack);
    np->kstack = 0;
    np->state = UNUSED;
    return -1;
  }
  np->sz = proc->sz;
  np->parent = proc;
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
 
  pid = np->pid;
  np->state = RUNNABLE;
  safestrcpy(np->name, proc->name, sizeof(proc->name));
  return pid;
}

// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
  struct proc *p;
  int fd;

  if(proc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
    if(proc->ofile[fd]){
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  iput(proc->cwd);
  proc->cwd = 0;
  
  if(proc->has_shm)
    deallocshm(proc->pid);		//deallocate any shared memory segments proc did not shmdt
  
  acquire(&ptable.lock);

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->parent == proc){
      p->parent = initproc;
      if(p->state == ZOMBIE)
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  proc->state = ZOMBIE;
  sched();
  panic("zombie exit");
}

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->parent != proc)
        continue;
      havekids = 1;
      if(p->state == ZOMBIE){
        // Found one.
        pid = p->pid;
        kfree(p->kstack);
        p->kstack = 0;
        freevm(p->pgdir);
        p->state = UNUSED;
        p->pid = 0;
        p->parent = 0;
        p->name[0] = 0;
        p->killed = 0;
        release(&ptable.lock);
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
      release(&ptable.lock);
      return -1;
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
  }
}

void
register_handler(sighandler_t sighandler)
{
  char* addr = uva2ka(proc->pgdir, (char*)proc->tf->esp);
  if ((proc->tf->esp & 0xFFF) == 0)
    panic("esp_offset == 0");

    /* open a new frame */
  *(int*)(addr + ((proc->tf->esp - 4) & 0xFFF))
          = proc->tf->eip;
  proc->tf->esp -= 4;

    /* update eip */
  proc->tf->eip = (uint)sighandler;
}


//PAGEBREAK: 42
// Per-CPU process scheduler.
// Each CPU calls scheduler() after setting itself up.
// Scheduler never returns.  It loops, doing:
//  - choose a process to run
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
  struct proc *p;
  
  for(;;){
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->state != RUNNABLE)
        continue;
    
      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
      switchuvm(p);
      p->state = RUNNING;
      swtch(&cpu->scheduler, proc->context);
      switchkvm();
                 
      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);

  }
}

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
  int intena;

  if(!holding(&ptable.lock))
    panic("sched ptable.lock");
  if(cpu->ncli != 1)
    panic("sched locks");
  if(proc->state == RUNNING)
    panic("sched running");
  if(readeflags()&FL_IF)
    panic("sched interruptible");
  intena = cpu->intena;
  swtch(&proc->context, cpu->scheduler);
  cpu->intena = intena;
}

// Give up the CPU for one scheduling round.
void
yield(void)
{
  acquire(&ptable.lock);  //DOC: yieldlock
  proc->state = RUNNABLE;
  sched();
  release(&ptable.lock);
}

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);

  if (first) {
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
    initlog();
  }
  
  // Return to "caller", actually trapret (see allocproc).
}

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
  if(proc == 0)
    panic("sleep");

  if(lk == 0)
    panic("sleep without lk");

  // Must acquire ptable.lock in order to
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
    acquire(&ptable.lock);  //DOC: sleeplock1
    release(lk);
  }

  // Go to sleep.
  proc->chan = chan;
  proc->state = SLEEPING;

  // Swap out
  if(swapFlag)			//check if swapping out is enabled
  {
    if(proc->pid > 3)		//do not allow init and inswapper to swapout
    {
      proc->wokenUp = 0;
      proc->swappingOut = 1;
      
      //if(!holding(&wakeuplock));
      //{
	//cprintf("swapping, proc = %d\n",proc->pid);
	//acquire(&wakeuplock);
      //}
      release(&ptable.lock);	
      swapOut();		//swap out proc
      acquire(&ptable.lock);
      proc->swappingOut = 0;	//oran
      //release(&wakeuplock);
      if(proc->wokenUp == 1)
      {
	proc->wokenUp = 0;	//oran
	proc->state = RUNNABLE_SUSPENDED;
	inswapper->state = RUNNABLE;
      }
      else
      {
	proc->state = SLEEPING_SUSPENDED;					//set proc to SLEEPING_SUSPENDED
	//proc->swappingOut = 0;	//oran						//set flag indicating proc is swapped out
      }
    }
  }
  
  sched();
  
  // Tidy up.
  proc->chan = 0;

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
    release(&ptable.lock);
    acquire(lk);
  }
}

//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
  struct proc *p;
  int found_suspended = 0;
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
  {
    if(p->state == SLEEPING && p->chan == chan)
    {
      //if(!holding(&wakeuplock));
      //{
	//cprintf("wakeup1, p->pid = %d\n",p->pid);
	 // acquire(&wakeuplock);
      //}
      if(p->swappingOut == 1)
	p->wokenUp = 1;
      else
	p->state = RUNNABLE;
      //release(&wakeuplock);
    }
    else if(p->state == SLEEPING_SUSPENDED && p->chan == chan && !found_suspended)	//check if any proc is SLEEPING_SUSPENDED
    {
      //cprintf("proc = %d\n",proc->pid);
      acquire(&swaplock);
      swappedout++;								//increment swapped out counter
      p->state = RUNNABLE_SUSPENDED;						//set state to RUNNABLE_SUSPENDED
      inswapper->state = RUNNABLE;						//wakeup inswapper
      release(&swaplock);
    }
  }
}

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
  acquire(&ptable.lock);
  wakeup1(chan);
  release(&ptable.lock);
}

// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->pid == pid){
      p->killed = 1;
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
        p->state = RUNNABLE;
      else if(p->state == SLEEPING_SUSPENDED)			//same as wakeup1 - swap in any killed process that is swapped out
      {
        acquire(&swaplock);
      	swappedout++;
      	p->state = RUNNABLE_SUSPENDED;
      	inswapper->state = RUNNABLE;
      	release(&swaplock);
      }
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
  return -1;
}

//PAGEBREAK: 36
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
  static char *states[] = {
  [UNUSED]    "unused",
  [EMBRYO]    "embryo",
  [SLEEPING]  "sleep ",
  [RUNNABLE]  "runble",
  [RUNNING]   "run   ",
  [ZOMBIE]    "zombie"
  };
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}

int getAllocatedPages(int pid) {			//traverse the process with the given pid's virtual memory and count how many PTE_U pages are allocated
  struct proc* p;
  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->pid == pid){
     break;
    }
  }
  release(&ptable.lock);
   int count= 0, j, k;
   for (j=0; j<1024; j++) {
      if(p->pgdir){ 
	if (p->pgdir[j] & PTE_P) {
	  pte_t* pte= (pte_t*)p2v(PTE_ADDR(p->pgdir[j]));
	  for (k=0; k<1024; k++) {
	      if ( pte[k] & PTE_U )
		count++;
	  }
	}
      }
   }
   return count;
}
