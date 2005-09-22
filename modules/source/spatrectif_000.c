/* spatrectif_000.c */
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <libgen.h>
#include <sys/time.h>
#include <errno.h>
#include <idl_export.h>
int errno;
#include "drp_structs.h"
#include "fitsio.h"

float c_bv[numspec][MAXSLICE];   // Local copy of influence matrix elements
float blame[numspec][MAXSLICE];  // Kernal for applying blame to lenslets for the first portion of the iterations
float weight[numspec];           // Weight normalization factor for distributing blame
float fblame[numspec][MAXSLICE]; // Kernal for applying blame during the final iterations
float fweight[numspec];          // Weight factor for distributing final blame
float q[numspec];                // Default lenslet intensity with w_weight distribution
float c_raw[DATA];
unsigned char c_aux[DATA];
float c_int[DATA];
float t_image[numspec];
float c_image[numspec];
float dummy[DATA];
float residual[DATA];
float new_image[numspec];
float adjust[MAXSLICE];

int spatrectif_000(int argc, void* argv[])
{
  // Parameters input in IDL calling program
  short int     totalParmCount;
  short int     numiter;
  float         relaxation;
  float         relax;
  short int     basesize;
  short int     (*hilo)[2];
  short int      *effective;
  float         (*basis_vectors)[MAXSLICE][DATA];
  short int     maxlens[numspec];
  float         max_bv[numspec];
  Module         *pModule;
  DataSet        *pDataSet;
  float         (*Frames)[DATA];
  IDL_STRING     *Headers;
  float         (*Noise)[DATA];
  unsigned char (*Quality)[DATA];
  float         (*image)[DATA];
  float         (*noise)[DATA];
  unsigned char (*quality)[DATA];
  // End of parameters input in IDL calling program

  double t1, t2;  // Time counters used to examine execution time
  short int i=0, ii=0, j=0, jj=0, sp=0, l=0;

  // Make a temporary residual matrix
  long naxes[3];
  //float  (*resid)[DATA][DATA];
  naxes[0] = DATA;
  naxes[1] = DATA;
  naxes[2] = (21);
  // *******************************

  // These parameters should be set in the same order as theay are passed
  // from the IDL code.  This is not yet automated, and I'm not sure how to
  // do it.
  i = 0;
  totalParmCount = *(short int *             )argv[i++];
  numiter        = *(short int *             )argv[i++];
  relaxation     = *(float *                 )argv[i++];
  basesize       = *(short int *             )argv[i++];
  hilo           = (short int (*)[2]         )argv[i++];
  effective      = (short int *              )argv[i++];
  basis_vectors  = (float (*)[MAXSLICE][DATA])argv[i++];
  pModule        = (Module *                 )argv[i++];
  pDataSet       = (DataSet *                )argv[i++];
  Frames         = (float (*)[DATA]          )argv[i++];
  Headers        = (IDL_STRING *             )argv[i++];
  Noise          = (float (*)[DATA]          )argv[i++];
  Quality        = (unsigned char (*)[DATA]  )argv[i++];
  image          = (float (*)[DATA]          )argv[i++];
  noise          = (float (*)[DATA]          )argv[i++];
  quality        = (unsigned char (*)[DATA]  )argv[i++];

  /*
   * Start placing items from the original rectification code here.
   * This code will rectify an input data frame.
   */
  //  printf("Image is spatrectif is %x.\n",image);
  printf( "spatrectif_000.c: Now processing RAW data...\n");
  printf("Number of iterations = %d.\n",numiter);
  printf("Relaxation Parameter = %f.\n",relaxation);
  (void)fflush(stdout);
  //////////////////////////////////////////////////////////////////////////////////////////////////////////////
  // Iterate on each lenslet.
  //////////////////////////////////////////////////////////////////////////////////////////////////////////////
  memset((void *)image,0, IMAGECNT );  // initial guess of the solution
  //  resid = malloc(sizeof(float)*DATA*DATA*(naxes[2]+1));
  t1=systime();

  printf("Doing column no. : 0000");
  (void)fflush(stdout);  // Initialize iteration status on the screen
  for ( i=0; i<DATA; i++)
  {            // for each spectral channel i ... (i.e., for a given column)
    for (j=0; j<DATA; j++) {
      c_raw[j]= Frames[j][i];
      c_int[j]= Noise[j][i];
      c_aux[j]= Quality[j][i];
    }

    for (sp=0; sp<numspec; sp++)
      {
	max_bv[sp] = 0.0;
	maxlens[sp]=0;
	weight[sp]=0.0;
	fweight[sp]=0.0;
	for (l=0; l<basesize; l++) {
	  j = hilo[sp][0]+l;          
	  c_bv[sp][l]=basis_vectors[sp][l][i];     // Store the basis vector in a local variable.
	  blame[sp][l]=c_bv[sp][l]*c_bv[sp][l]*c_bv[sp][l]*c_bv[sp][l]; // initial blame is very focused on peak pixels.
	  weight[sp]=weight[sp]+blame[sp][l];      // Weight factor for distributing blame
	  fblame[sp][l]=c_bv[sp][l];                  // final blame is a copy of the infl matrices
	  fweight[sp]=fweight[sp]+fblame[sp][l];      // Weight factor for distributing blame
	}

      }

    memset( (void *) c_image, 0.0, numspec*sizeof(float));

    if ( (i & 0x007f) == 0 )
    {
      printf("\b\b\b\b%4d",i);
      (void)fflush(stdout);  // Update iteration status on the screen
    }

    for (ii=0; ii<numiter; ii++)
      {     // calculate a solution for a column (i) iteratively...
	//	relax = ((3.0*ii/numiter)+1)*relaxation;
	relax = relaxation;
	memset( (void *) dummy, 0, DATA*sizeof(float));
	for ( sp=0; sp<numspec; sp++ )
	  {// calculate best current guess of raw data
	    j=hilo[sp][0];
	    for ( jj=0; jj<basesize; jj++ )
	      {
		dummy[j] += c_bv[sp][jj] * c_image[sp];   // Influence element times current best lenslet value
		j++;
	      }
	  }
	for (j=0; j<DATA; j++)
	  residual[j] = (c_raw[j] - dummy[j]);     // Calculate residual at each pixel

	for ( sp=0; sp<numspec; sp++ )
	  {// ...and calculate correction (=new_image)
	    for ( jj=0; jj<basesize; jj++ )
	      {
		j = hilo[sp][0]+jj;
		// Calculate how much the jth pixel would like to adjust the sp lenslet
		adjust[jj] = 0.0;
		if ( ii < 10 ) {
		  // Initially be very aggressive in applying blame.
		  if ( weight[sp] > 0.0 ) {
		    adjust[jj]=2.0*residual[j]*blame[sp][jj]/weight[sp];
		  }
		}
		if (ii > 9) {
		  // After first set of iterations, settle down to stable solution
		    if ( fweight[sp] > 0.0 ) {
		      adjust[jj]=residual[j]*fblame[sp][jj]/fweight[sp];
		    }
		}
	      }
	    for ( jj=0; jj<basesize; jj++ )
	      {
		// Adjust that lenslet.
		c_image[sp]+=relax*adjust[jj];
	      }
	  }
	//	if ( ii == 6 ) {
	//for (sp = 1; sp<(numspec-1); sp++) 
	//  {
	//    t_image[sp]=0.5*c_image[sp]+0.25*c_image[sp-1]+0.25*c_image[sp+1];
	//  }
	//for (sp = 0; sp<numspec; sp++)
	//  {
	//    c_image[sp]=t_image[sp];
	//  }
	//}
	if ( (ii<8) && (ii < 8) ) {
	  for (sp = 0; sp<numspec; sp++)
	    {
	      t_image[sp]=c_image[sp];
	    }
	  for (sp = 64; sp<(numspec-64); sp++) 
	    {
	      if ( (c_image[sp] < 0.0) && (c_image[sp] < c_image[sp-64]) && (c_image[sp] < c_image[sp+64]) ) {
		// For the iterations 3 to 8, apply a hanning filter to reduce ringing
		t_image[sp]=c_image[sp]+0.5*c_image[sp-64]+0.5*c_image[sp+64];
		t_image[sp-64]=0.5*c_image[sp-64];
		t_image[sp+64]=0.5*c_image[sp+64];
	      }
	      if ( (c_image[sp] > 0.0) && (c_image[sp] > c_image[sp-64]) && (c_image[sp] > c_image[sp+64]) ) {
		// For the iterations 3 to 8, apply a hanning filter to reduce ringing
		t_image[sp]=c_image[sp]+0.5*c_image[sp-64]+0.5*c_image[sp+64];
		t_image[sp-64]=0.5*c_image[sp-64];
		t_image[sp+64]=0.5*c_image[sp+64];
	      }
	    }
	  for (sp = 0; sp<numspec; sp++)
	    {
	      c_image[sp]=t_image[sp];
	    }
	}
	if ( ii < -1 ) {
	  for (sp = 1; sp<(numspec-1); sp++) 
	    {
		// For the iterations 7, apply a hanning filter to reduce ringing
	      t_image[sp]=0.5*c_image[sp]+0.25*c_image[sp+1]+0.25*c_image[sp-1];
	    }
	  for (sp = 1; sp<(numspec-1); sp++)
	    {
	      c_image[sp]=t_image[sp];
	    }
	  
	}
      } // iteration routine for 'ii'
  
    for (sp=0; sp<numspec; sp++)
      image[sp][i]=c_image[sp];

    // updating noise frame!!
    //
    // based on a discussion and suggestion from Alfred Krabbe on 12/11/2003 @UCLA.
    //
    // (cf) quality frame will not be changed or processed through this code.
    //      quality frame will be handled via 'mkdatacube' module!!
    // Updated noise at a given (i,j) pixel, N[i,j]=Sum over i (R[i,j]*noise[i,j])
    // where i is perpendicular to dispersion axis (i.e, along the column).
    // R[i,j] is normalized influence function coefficient.
    for (sp=0; sp<numspec; sp++)
    {
      noise[sp][i]=0.0;
      quality[sp][i]=9;
      j=hilo[sp][0];
      for (jj=0; jj<basesize; jj++)
	//        noise[sp][i] += c_bv[sp][jj]*Noise[jj][i];
	noise[sp][i] = 1.0;
    }

  } // for each spectral channel i ...
  printf("\n");
  //////////////////////////////////////////////////////////////////////////////////////////////////////////////
  t2 = systime();
  (void)printf("Total Time = %lf\n", t2-t1 );

  //  writefitsimagefile("!/sdata1101/osiris-data/osiris2/050224/SPEC/ORP/resid.fits", FLOAT_IMG, 3, naxes, resid);
  //  free(resid);


#ifdef SAVE_INTERMEDIATE_FILES
  //naxes[0] = DATA;
  //naxes[1] = numspec;
  //writefitsimagefile("testimage.fits", FLOAT_IMG, 2, naxes, image);
#endif
  //  printf("Image is spatrectif is %x.\n",image);

  return 0;
}
