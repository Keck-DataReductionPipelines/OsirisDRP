/* osiris_post_sem_signal_null.c */
#include <semaphore.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h> 
#include <sys/ipc.h>
#include "idl_export.h"
#include <errno.h>
int errno;

int osiris_post_sem_signal(int argc, void* argv[])
{
  int retval = 0;  /* Assume we are OK to procede. */

  return retval;
}
