#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h> 
#include <sys/ipc.h>
#include "idl_export.h"
#include <errno.h>
int errno;

int dumpxmlptr(int argc, void* argv[])
{
  int retval = 0;

  (void)fprintf(stdout, "dumpxmlptr: argv[0] = %08x\n", argv[0]);
  return retval;
}
