/* osiris_test.c */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h> 
#include <errno.h>
int errno;

#define DATA       64

// Parameter list:
//                 char[]
//                 float
//                 pointer to data frame

int osiris_test(int argc, void* argv[])
{
  int i, j;
  float (*pData)[DATA];  // This will hold a pointer to the frame data
                         // passed from the IDL backbone.

  if (argc != 3) return -1;

  (void)printf("Execute osiris_test... %s %f\n\r", (char *)argv[0], *(float *)argv[1]);
  
  pData = (float (*) [DATA])argv[2];

  for (i=0; i<DATA; i++) {
    for (j=0; j<DATA; j++) {
      pData[j][i] = (float)(i+1) * (float)(j+1);
    }
  }

  return 0;
}
