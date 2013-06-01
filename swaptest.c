#include "types.h"
#include "user.h"

int main()
{
  int i;
  char * str = "";
  enableSwapping();
  if(fork()==0)
  {
    printf(1,"Pid = %d is going to sleep and to be swapped out\n",getpid());
    sleep(10);
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
      exec("ls",&str);
    }
    else
    {
      disableSwapping();
      sleep(100);
      if(fork()==0)
      {
	printf(1,"Pid = %d is going to sleep and it won't be swapped out\n",getpid());
	sleep(10);
      }
    }
  }
  
  for(i=0;i<3;i++)
    wait();
  return 0;
}