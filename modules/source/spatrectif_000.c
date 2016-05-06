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
float good[numspec][DATA];             // Weighted version of quality to decide if a pixel is valid.
float cmp[numspec][DATA];              // Weights for good				       
float fblame[DATA][numspec][MAXSLICE]; // Kernal for applying blame during the final iterations
float fbasisv[DATA][numspec][MAXSLICE];    // influence matrix (basis vector)
float fweight[numspec][DATA];          // Weight factor for distributing final blame
float *fw;                             // Weight factor for distributing final blame
float *w;                              // Weight factor for distributing final blame
float t_image[DATA][numspec];	       // Temporary extracted spectra
float c_image[DATA][numspec];	       // Cumulative extracted spectra
float *ti;			       // For each column accumulate delta to lenslet value
float *ci;			       // For each column best current estimate of lenslet value
float t_fbv[MAXSLICE];		       // Temporary basis vector to manipulate if necessary 
float dummy[DATA];		       // Model of the flux given current lenslet estimate
float residual[DATA];		       // Residual between data - model

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
  /*  printf("Relaxation Parameter = %f.\n",relaxation);
      printf("Platescale = %f.\n",scale); */
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
  
  // Making local copies of the basis vector 
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

  // Assigning weights for each blame function, by intergrating under the blame function
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
		for (l=0; l<MAXSLICE; l++)
	    {
	      bl[l]= fbv[l]*fbv[l]*fbv[l];   // initial blame is very focused on peak pixels.
	      //bl[l]= fbv[l]*fbv[l]*fbv[l]*fbv[l]*fbv[l]*fbv[l];   // initial blame is very focused on peak pixels.	      
	      w[i] += bl[l];                 // Weight factor for distributing blame
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

  // Start iterations... here we go.
 
  printf("Doing iteration no. : 0000");
  (void)fflush(stdout);  // Initialize iteration status on the screen
  memset( (void *) c_image, 0.0, numspec*DATA*sizeof(float)); // start all intial lenslet guesses to zero
  for (ii=0; ii<numiter; ii++)
    {     // calculate a solution for a column (i) iteratively...
      printf("\b\b\b\b%4d",ii);
      (void)fflush(stdout);  // Update iteration status on the screen
      //	}
      //	relax = ((3.0*ii/numiter)+1)*relaxation;
      relax = relaxation;
      // for each column calculate a new iteration on the lenslets
      for ( i=0; i<DATA; i++)
	{ // for each spectral channel i ... (i.e., for a given column)
	  memset( (void *) dummy, 0, DATA*sizeof(float)); // current forward model of the lenslet PSF
	  ci = c_image[i];	// current lenslet value
	  ti = t_image[i];	// temporary (delta) lenslet value to be applied below
	  for ( sp=0; sp<numspec; sp++ )
	    {// calculate best current guess of raw data
	      ti[sp]=0.0;
	      fbv = fbasisv[i][sp];	// temp PSF for this particular column
	      for (jj=1; jj<(MAXSLICE-1); jj++ )	
	      {// smoothing basis vector to better match on-sky and make temp basis vector array
		//t_fbv[jj] = -fbv[jj-1]*0.02 + 1.04*fbv[jj] - 0.02*fbv[jj+1]; // attempt #1
		//t_fbv[jj] = fbv[jj-1]*0.03 + 0.95*fbv[jj] + 0.02*fbv[jj+1]; // attempt #2; broadened_psf_1
	        //t_fbv[jj] = fbv[jj-1]*0.3 + 0.4*fbv[jj] + 0.3*fbv[jj+1]; // attempt #3  // asymmetric
		t_fbv[jj] = fbv[jj];
	      }
	      in1 = index[sp] + i;	// keep track of each spectrum location
	      j=bottom[sp];
	      for ( jj=0; jj<MAXSLICE; jj++ )
		{
		  dummy[j] += t_fbv[jj] * ci[sp];   // Influence element times current best lenslet value
		  j++;
		}
	    }
	  //if (i==1020) printf("dummy[1020][100] = %lf\n", dummy[100] );	  
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
		    // Initially be very aggressive in applying blame. Accumulate blame, but don't apply yet for 1st iterations.
		    ti[sp]+=relax*residual[j]* bl[jj];
		  }
		  if ( ii > 14) {
		    // After first set of iterations, settle down to stable solution
		    ti[sp]+=relax*residual[j]* fbl[jj];
		    //ti[sp]+=relax*residual[j]* bl[jj];		    
		  }
		  j++; // march up column to match PSF location
		}
	    }
	  //	 Correction is applied.
	  for (sp=0; sp< numspec; sp++) { 
	    if ( weight[sp][i] > 0.0 ) {
	      ci[sp]+= ti[sp];
	    }
	  }

	} // end of loop over image.
    } // for each iteration

  for (i=0; i<DATA; i++)
    {
      ci = c_image[i];
      for (sp=0; sp<numspec; sp++)
	image[sp][i]=ci[sp]/1.28;  // Dividing by 1.28 for an overall normalization (james' magic!)
    }

  // updating noise frame!!
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
	  quality[sp][i]=0;
	  j=bottom[sp];
	  good[sp][i] = 0.0;
	  cmp[sp][i] = 0.0;
	  for (jj=0; jj<MAXSLICE; jj++)
	    {
	      if ( Quality[jj][i] == 9 )  // For valid pixels.
		//	noise[sp][i] += basis_vectors[sp][jj][i]*Noise[j][i];
		noise[sp][i] += fblame[i][sp][jj]*Noise[j][i];
	      good[sp][i] += fblame[i][sp][jj]*Quality[jj][i];
	      cmp[sp][i] += fblame[i][sp][jj];
	      j++;
	    }
	  good[sp][i] = good[sp][i]/cmp[sp][i];  //Compare weights to valid weights
	  if ( good[sp][i] > 4.5 ) quality[sp][i]=9;  // Implies over have of the weights have good pixels.
	} // for each spectral channel sp ...
    }
  printf("\n");
  //////////////////////////////////////////////////////////////////////////////////////////////////////////////
  t2 = systime();
  //  (void)printf("Total Time = %lf\n", t2-t1 );
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
