#include "param.h"
#include "types.h"
#include "stat.h"
#include "user.h"
#include "fs.h"
#include "fcntl.h"
#include "syscall.h"
#include "traps.h"
#include "memlayout.h"


int main (int args, char** argv) 
{

  int pid;
  
  printf(1, "Starting Shared Memory Test\n\n");

  printf(1, "Allocating 8000 B of Shared memory with key = 1\n\n");

  int shmid = shmget(1, 8000, CREAT);

  printf(1, "allocated memory in %p\n\n",shmid);

  printf(1, "trying to allocate with same key, should fail, return value = %d\n\n",shmget(1, 4000, CREAT));

  printf(1, "trying to get the same memory we allocated with key = 1, original shmid = %p, returned shmid = %p\n\n",shmid,shmget(1, 4000, GET));

  const void * addVa = shmat(shmid,SHM_RDWR);
  printf(1, "Attaching Shared memory to main process in RDWR mode, pid = %d, Virtual Address = %p\n\n",getpid(),addVa);

  const void * addVa2 = shmat(shmid,SHM_RDWR);
  printf(1, "Trying to attach the same shmid we allocated. should return a different VA: va = %p\n\n",addVa2);

  printf(1, "Creating child process to demonstrate Shared Memory Usage\n\n");
  
  if((pid = fork()) == 0)
  {
    pid = getpid();
    char *str = "Hello Father, how are you?\0";
    char * shm;
    printf(1, "Child process created, pid = %d\n\n",pid);
    printf(1, "Getting Shared memory with key = 1, shmid should be the same as in father = %p\n\n",shmid = shmget(1, 4000, GET));
    printf(1, "Trying to attach the same shmid I got. VA may be different than the father's: va = %p\n\n",addVa = shmat(shmid,SHM_RDWR));
    printf(1, "Child process writing the String to Shared Memory to be read by the father: Hello Father, how are you?\n\n");
    shm = (char *)addVa;
    strcpy(shm,str);
    
    printf(1, "Child process wrote to Shared Memory and will now wait until father reads memory and changes first char to *\n\n");
    while(*((char *)addVa) != '*')
      sleep(1);
    
    sleep(1);
    printf(1, "Child process released and trying to detach the same VA he got, should return 0. return value = %d\n\n",shmdt(addVa));
    printf(1, "Child process trying to dealloc Shared memory while father still attached,should fail, return value =  %d\n\n",shmdel(shmid));
   
    /*
    const void * addVa2 = shmat(shmid,SHM_RDONLY);
    printf(1, "Child process Trying to attach the same shmid we allocated, this time with Read-Only. va = %p\n\n",addVa2);
    
    printf(1, "Child attempting to write to the Read-Only VA %p, should throw a trap 14:\n\n");
    *((char*)addVa2) = '*';
    */
    exit();
  }
    
  printf(1, "Father going to sleep to allow child to run\n\n");
  sleep(1000);
  char * shm = (char *)addVa;
  char str[30];
  strcpy(str,shm);
  
  printf(1, "Father read from memory the String: %s\n\n",str);
  
   
  printf(1, "Father writing '*' to memory to allow child to finish\n\n");
  *((char*)addVa) = '*';

  printf(1, "Father is waiting allow child to run\n\n");
  
  wait();
  
  printf(1, "Creating another child process to demonstrate freeing left over Shared Memory on exit\n\n");
  
  if((pid = fork()) == 0)
  {
    pid = getpid();
    char *str = "2nd child exited without shmdt\0";
    char * shm;
    printf(1, "Child process created, pid = %d\n\n",pid);
    printf(1, "Getting Shared memory with key = 1, shmid should be the same as in father = %p\n\n",shmid = shmget(1, 4000, GET));
    printf(1, "Trying to attach the same shmid I got. VA may be different than the father's: va = %p\n\n",addVa = shmat(shmid,SHM_RDWR));
    printf(1, "Child process writing the String to Shared Memory to be read by the father: 2nd child exited without shmdt\n\n");
    shm = (char *)addVa;
    strcpy(shm,str);
    
    printf(1, "Child process exiting without calling shmdt\n");
    exit();
  }
  
  printf(1, "Father waiting to allow 2nd child to run\n\n");
  wait();
  
  
  shm = (char *)addVa;
  strcpy(str,shm);
  
  printf(1, "Father read from memory the String: %s\n\n",str);
  
  printf(1, "Father trying to detach both VAs he allocated. should return 0,0. return value = %d,%d\n\n",shmdt(addVa),shmdt(addVa2));

  printf(1, "trying to dealloc, should return the number of pages, return value =  %d\n\n",shmdel(shmid));

  exit();
  }


  