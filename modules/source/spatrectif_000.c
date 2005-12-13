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

float blame[DATA][numspec][MAXSLICE];  // Kernal for applying blame to lenslets for the first portion of the iterations
float weight[numspec][DATA];           // Weight normalization factor for distributing blame
float fblame[DATA][numspec][MAXSLICE]; // Kernal for applying blame during the final iterations
float fbasisv[DATA][numspec][MAXSLICE];    // influence matrix
float fweight[numspec][DATA];          // Weight factor for distributing final blame
float *fw;                             // Weight factor for distributing final blame
float *w;                              // Weight factor for distributing final blame
float t_image[DATA][numspec];
float c_image[DATA][numspec];
float *ti;
float *ci;
float dummy[DATA];
float residual[DATA];
float new_image[numspec][DATA];
float adjust[MAXSLICE];
float maxi;
int where;

int spatrectif_000(int argc, void* argv[])
{
  // Parameters input in IDL calling program
  short int     totalParmCount;
  short int     numiter;
  float         scale;
  float         relaxation;
  float         relax;
  short int     basesize;
  short int     (*hilo)[2];
  short int     bottom[numspec];
  short int      *effective;
  float         *bv;
  float         *bl, *fbl, *fbv;
  float         (*basis_vectors)[MAXSLICE][DATA];
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

  double t1, t2, t3, t4, t5, t6;  // Time counters used to examine execution time
  short int i=0, ii=0, j=0, jj=0, sp=0, l=0;
  long int  in1=0, in2=0, in3=0, index[numspec];

  // Make a temporary residual matrix
  long naxes[3];
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
  scale          = *(float *                 )argv[i++];   // Plate scale 
  
  /*
   * Start placing items from the original rectification code here.
   * This code will rectify an input data frame.
   */
  //  printf("Image is spatrectif is %x.\n",image);
  printf( "spatrectif_000.c: Now processing RAW data...\n");
  printf("Number of iterations = %d.\n",numiter);
  printf("Relaxation Parameter = %f.\n",relaxation);
  printf("Platescale = %f.\n",scale);
  (void)fflush(stdout);
  //////////////////////////////////////////////////////////////////////////////////////////////////////////////
  // Iterate on each lenslet.
  //////////////////////////////////////////////////////////////////////////////////////////////////////////////
  memset((void *)image,0, IMAGECNT );  // initial guess of the solution

  t1=systime();

  // Set the local pointer bv equal to the address of the lowest member of the basis_vector
  bv = basis_vectors[0][0];
  for (sp = 0; sp< numspec; sp++)
    {
      bottom[sp]=hilo[sp][0];
    }

  printf("Calculating weights.\n");
  (void)fflush(stdout);
  
  for (sp=0; sp<numspec; sp++)
    {            // for each spectral channel i ... (i.e., for a given column)
      index[sp]=sp*MAXSLICE*DATA;
      for ( i=0; i<DATA; i++)
	{
	  in1 = index[sp] + i;
	  fbv = fbasisv[i][sp];
	  for (l=0; l<MAXSLICE; l++)
	    {
	      in2 = in1 + l*DATA;
	      fbv[l]=*(bv+in2);   // local copy of influence matrix
	    }
	}
    }
  for (sp=0; sp<numspec; sp++)
    {            
      w=weight[sp];
      fw=fweight[sp];
      for ( i=0; i<DATA; i++)
	{
	  w[i] =0.0;
	  fw[i] =0.0;
	  bl = blame[i][sp];
	  fbl = fblame[i][sp];
	  fbv = fbasisv[i][sp];
	  maxi = fbv[0];
	  for (l=0; l<MAXSLICE; l++)
	    {
	      bl[l]=0.0;
	      if ( fbv[l] > maxi )
	  	{
	  	  maxi = fbv[l];
	  	  where = l;
	  	}
	    }
	  bl[where]= maxi;   // initial blame is very focused on peak pixels.
	  w[i] = maxi;
	  for (l=0; l<MAXSLICE; l++)
	    {
	      //bl[l]= fbv[l]*fbv[l]*fbv[l];   // initial blame is very focused on peak pixels.
	      //w[i] += bl[l];                 // Weight factor for distributing blame
	      fbl[l]= fbv[l];                // final blame is a copy of the infl matrices
	      fw[i]+= fbl[l];                // Weight factor for distributing blame
	    }

	  // Normalize the blame arrays
	  if ( w[i] > 0.0 ) 
	    {
	      for (l=0; l<MAXSLICE; l++)
		{
		  bl[l]=bl[l]/(w[i]);
		}
	    }
	  else
	    {
	      for (l=0; l<MAXSLICE; l++)
		{
		  bl[l]=0.0;
		}
	    }	      
	  if ( fw[i] > 0.0 ) 
	    {
	      for (l=0; l<MAXSLICE; l++)
		{
		  fbl[l]=fbl[l]/fw[i];
		}
	    }
	  else 
	    {
	      for (l=0; l<MAXSLICE; l++)
		{
		  fbl[l]=0.0;
		}
	    }
	}
    }

  printf("Doing iteration no. : 0000");
  (void)fflush(stdout);  // Initialize iteration status on the screen
  memset( (void *) c_image, 0.0, numspec*DATA*sizeof(float));
  for (ii=0; ii<numiter; ii++)
    {     // calculate a solution for a column (i) iteratively...
      printf("\b\b\b\b%4d",ii);
      (void)fflush(stdout);  // Update iteration status on the screen
      //	}
      //	relax = ((3.0*ii/numiter)+1)*relaxation;
      relax = relaxation;
      for ( i=0; i<DATA; i++)
	{ // for each spectral channel i ... (i.e., for a given column)
	  memset( (void *) dummy, 0, DATA*sizeof(float));
	  ci = c_image[i];
	  ti = t_image[i];
	  for ( sp=0; sp<numspec; sp++ )
	    {// calculate best current guess of raw data
	      fbv = fbasisv[i][sp];
	      in1 = index[sp] + i;
	      j=bottom[sp];
	      for ( jj=0; jj<MAXSLICE; jj++ )
		{
		  //  dummy[j] += *(fbv+in2) * ci[sp];   // Influence element times current best lenslet value
		  //  dummy[j] += fbv[in2] * ci[sp];   // Influence element times current best lenslet value
		  dummy[j] += fbv[jj] * ci[sp];   // Influence element times current best lenslet value
		  j++;
		}
	    }
	  for (j=0; j<DATA; j++)
	    {
	      if ( Quality[j][i] == 9 )  // For valid pixels.
		{
		  residual[j] = (Frames[j][i] - dummy[j]);     // Calculate residual at each pixel
		}
	      else
		residual[j]=0.0;
	    }

	  for ( sp=0; sp<numspec; sp++ )
	    {// ...and calculate correction (=new_image)
	      in1 = index[sp] + i;
	      j = bottom[sp];
	      bl = blame[i][sp];
	      fbl = fblame[i][sp];
	      for ( jj=0; jj<MAXSLICE; jj++ )
		{
		  // Calculate how much the jth pixel would like to adjust the sp lenslet
		  if ( ii < 15 ) {
		    // Initially be very aggressive in applying blame.
		    ci[sp]+=relax*residual[j]* bl[jj];
		  }
		  if (ii > 14) {
		    // After first set of iterations, settle down to stable solution
		    ci[sp]+=relax*residual[j]* fbl[jj];
		  }
		  j++;
		}
	    }
	  if ( (scale > 0.099) && (ii == -1)  ) {
	    for (sp = 0; sp<numspec; sp++)
		ti[sp]=ci[sp];
	    for (sp = 64; sp<(numspec-64); sp++) 
		ti[sp]=2.0*ci[sp]-0.5*ci[sp-64]-0.5*ci[sp+64];
	    for (sp = 0; sp<numspec; sp++)
		ci[sp]=ti[sp];
	  }
	  if ( (scale > 0.099) && (ii == -1)  ) {
	    for (sp = 0; sp<numspec; sp++)
		ti[sp]=ci[sp];
	    for (sp = 64; sp<(numspec-64); sp++) 
		ti[sp]=0.5*ci[sp]+0.25*ci[sp-64]+0.25*ci[sp+64];
	    for (sp = 0; sp<numspec; sp++)
		ci[sp]=ti[sp];
	  }
	  if ( (scale > 0.099) && (ii == -1)  ) {
	    for (sp = 0; sp<numspec; sp++)
		ti[sp]=ci[sp];
	    for (sp = 64; sp<(numspec-64); sp++) 
		ti[sp]=2.0*ci[sp]-0.5*ci[sp-64]-0.5*ci[sp+64];
	    for (sp = 0; sp<numspec; sp++)
		ci[sp]=ti[sp];
	  }
	  if ( (scale > 0.099) && (ii == -1)  ) {
	    for (sp = 0; sp<numspec; sp++)
		ti[sp]=ci[sp];
	    for (sp = 64; sp<(numspec-64); sp++) 
		ti[sp]=0.5*ci[sp]+0.25*ci[sp-64]+0.25*ci[sp+64];
	    for (sp = 0; sp<numspec; sp++)
		ci[sp]=ti[sp];
	  }

	  if ( ii < -1 ) {
	    for (sp = 1; sp<(numspec-1); sp++) 
	      {
		ti[sp]=0.5*ci[sp]+0.25*ci[sp+1]+0.25*ci[sp-1];
	      }
	    for (sp = 1; sp<(numspec-1); sp++)
	      {
		ci[sp]=ti[sp];
	      }
  
	  }
	} // end of loop over image.
      //      if ( (scale > 0.099) && (ii == 2)  ) {
      //for (sp = 0; sp<numspec; sp++)
      //  for (i = 1; i<(DATA-1); i++ )
      //    c_image[i][sp]=0.25*c_image[i-1][sp]+0.5*c_image[i][sp]+0.25*c_image[i+1][sp];
      //}
    } // for each iteration

  printf("out of iterations\n");
  for (i=0; i<DATA; i++)
    {
      ci = c_image[i];
      for (sp=0; sp<numspec; sp++)
	image[sp][i]=ci[sp];
    }

  // updating noise frame!!
  //
  // based on a discussion and suggestion from Alfred Krabbe on 12/11/2003 @UCLA.
  //
  // (cf) quality frame will not be changed or processed through this code.
  //      quality frame will be handled via 'mkdatacube' module!!
  // Updated noise at a given (i,j) pixel, N[i,j]=Sum over i (R[i,j]*noise[i,j])
  // where i is perpendicular to dispersion axis (i.e, along the column).
  // R[i,j] is normalized influence function coefficient.
  for (i=0; i<DATA;i++)
    {
      for (sp=0; sp<numspec; sp++)
	{
	  noise[sp][i]=0.0;
	  quality[sp][i]=9;
	  j=bottom[sp];
	  //	  for (jj=0; jj<MAXSLICE; jj++)
	  //        noise[sp][i] += basis_vectors[sp][jj][i]*Noise[jj][i];
	  //  noise[sp][i] = 1.0;
	} // for each spectral channel sp ...
    }
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
