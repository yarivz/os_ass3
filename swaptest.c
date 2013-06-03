#include "types.h"
#include "user.h"

int main(int argc,char** argv)
{
  int i,pid;
  printf(1,"Enabling swapping now...\n");
  enableSwapping();
  if((pid = fork())==0)
  {
    pid = getpid();
    printf(1,"Child process Pid = %d has %d memory pages allocated.\nChild process pid = %d is going to sleep and will be swapped out\n",pid,getAllocatedPages(pid),pid);
    sleep2();
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
      printf(1,"Disabling swapping now...\n");
      disableSwapping();
      sleep(1000);
      printf(1,"Child process Pid = %d has %d memory pages allocated.\nChild process pid = %d will now be woken up\n",pid,getAllocatedPages(pid),pid);
      wakeup2();
      sleep(100);
      if((pid = fork())==0)
      {
	pid = getpid();
	printf(1,"Child process Pid = %d has %d memory pages allocated.\nChild process pid = %d is going to sleep and WILL NOT be swapped out\n",pid,getAllocatedPages(pid),pid);
	sleep2();
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
	  sleep(1000);
	  printf(1,"Child process Pid = %d has %d memory pages allocated.\nChild process pid = %d will now be woken up\n",pid,getAllocatedPages(pid),pid);
	  wakeup2();
	}
      }
    }
  }
  
  for(i=0;i<4;i++)
    wait();
  exit();
}