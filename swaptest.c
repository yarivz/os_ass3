#include "types.h"
#include "user.h"

int main(int argc,char** argv)
{
  int pid;
  printf(1,"\n**************** PART 1 *****************\n\n");
  printf(1,"Enabling swapping now...\n");
  enableSwapping();
  if((pid = fork())==0)
  {
    pid = getpid();
    printf(1,"Child process Pid = %d has %d memory pages allocated, going to sleep and will be swapped out\n",pid,getAllocatedPages(pid));
    sleep2();
    printf(1,"Child process pid = %d has woken up and was swapped in - has %d memory pages allocated.\n",pid,getAllocatedPages(pid));
    exit();
  }
  else
  {
    int j,k;
    for(j=0;j<10000000;j++)
    {
      k = j;
      j = j+1;
      j = k;
    }
    if(fork()==0)
    {
      printf(1,"we will now run the 'ls' command and see that the %d.swap file is created\n",pid);
      exec("ls",argv);
    }
    else
    {
      for(j=0;j<10000000;j++)
      {
	k = j;
	j = j+1;
	j = k;
      }
      printf(1,"\nChild process Pid = %d is sleeping and swapped out - has %d memory pages allocated.\n",pid,getAllocatedPages(pid));
      wakeup2();
      while(wait()>0);
      
      printf(1,"\n\n**************** PART 2 *****************\n\n");
      printf(1,"Disabling swapping now...\n");
      disableSwapping();
      if((pid = fork())==0)
      {
	pid = getpid();
	printf(1,"Child process Pid = %d has %d memory pages allocated, going to sleep and WILL NOT be swapped out\n",pid,getAllocatedPages(pid));
	sleep2();
	printf(1,"Child process pid = %d has woken up and was swapped in - has %d memory pages allocated.\n",pid,getAllocatedPages(pid));
	exit();
      }
      else
      {
	if(fork()==0)
	{
	  printf(1,"we will now run the 'ls' command and see that the %d.swap file has not been created\n",pid);
	  exec("ls",argv);
	}
	else
	{
	  sleep(100);
	  printf(1,"\nChild process Pid = %d is sleeping and NOT swapped out - has %d memory pages allocated.\n",pid,getAllocatedPages(pid));
	  wakeup2();
	}
      }
    }
  }
  
  while(wait()>0);
  exit();
}