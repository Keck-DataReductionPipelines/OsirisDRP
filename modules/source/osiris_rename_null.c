/* osiris_rename_null.c */
#include <semaphore.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h> 
#include <sys/ipc.h>
#include "idl_export.h"
#include <errno.h>
int errno;

int osiris_rename(int argc, void* argv[])
{
  int retval;

  if (argc != 2) return -1;
  (void)printf("rename %s %s\n\r", (char *)argv[0], (char *)argv[1]);
  retval = rename((char *)argv[0], (char *)argv[1]);
  if (retval != 0) {
    return errno;
  } else {
    return 0;
  }
}
