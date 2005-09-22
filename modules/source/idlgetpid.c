#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h> 
#include <unistd.h>
#include <sys/ipc.h>
#include "idl_export.h"
#include <errno.h>
int errno;

pid_t idlgetpid(int argc, void* argv[])
{
  pid_t retval;

  retval = getpid();
  (void)fprintf(stdout, "idlgetpid: process id = %d\n", retval); 
  return retval;
}
