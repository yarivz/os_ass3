#define NPROC        64  // maximum number of processes
#define KSTACKSIZE 4096  // size of per-process kernel stack
#define NCPU          8  // maximum number of CPUs
#define NOFILE       16  // open files per process
#define NFILE       100  // open files per system
#define NBUF         10  // size of disk block cache
#define NINODE       50  // maximum number of active i-nodes
#define NDEV         10  // maximum major device number
#define ROOTDEV       1  // device number of file system root disk
#define MAXARG       32  // max exec arguments
#define LOGSIZE      10  // max data sectors in on-disk log
#define CREAT	20	// shmflag for creating sheard memory
#define GET	21	// shmflag for getting sheard memory
#define SHM_RDONLY	22	// shmflag for reading only
#define SHM_RDWR	23	// shmflag for reading & writing
#define numOfSegs	100	// maximum number of segments


