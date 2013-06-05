#include "param.h"
#include "types.h"
#include "stat.h"
#include "user.h"
#include "fs.h"
#include "fcntl.h"
#include "syscall.h"
#include "traps.h"
#include "memlayout.h"


int main (int args, char** argv) {
disableSwapping();

printf(1, "now allocating shared mem\n");

int add = shmget(1, 4000, CREAT);
printf(1, "allocated in %p\n",add);
printf(1, "trying to allocate with same key, should fail%d\n",shmget(1, 4000, CREAT));
printf(1, "trying to get the same add we allocated, should be the same %p %p\n",add,shmget(1, 4000, GET));

const void * addVa = shmat(add,SHM_RDONLY);
printf(1, "tring to attach the same add we allocated. should return add va's. va = %d\n",addVa);
printf(1, "tring to deattach the same add we allocated. should return 0. return value = %d\n",shmdt(addVa));
addVa = shmat(add,SHM_RDWR);
printf(1, "tring to attach the same add we allocated. should return add va's. va = %d\n",addVa);
printf(1, "tring to deattach the same add we allocated. should return 0. return value = %d\n",shmdt(addVa));

printf(1, "trying to dealloc, %d\n",shmdel(add));


exit();
}
