#include "types.h"
#include "user.h"


int main()
{
  enableSwapping();
  fork();
  fork();
  while(wait()>0);
  exit();
}