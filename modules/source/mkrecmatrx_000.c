/* mkrecmatrx_000.c */
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

float basis_vectors[numspec][MAXSLICE][DATA];

int mkrecmatrx_000(int argc, void* argv[]) {
  long int ptrsOffset;

  // Parameters input in IDL calling program
  short int totalParmCount;
  float weight_limit, x;
  //int slice;
  Module *pModule;
  DataSet *pDataSet;
  short int frameCount;
  IDL_STRING *outDirname;
  IDL_STRING *outFilename;
  char completeOutName[256];
  IDL_STRING *sfilter;
  float *Frames[MAXFRAMESINDATASETS];  // These arrays will hold pointers to the collection of
  // Frames, Headers IntFrames and IntAuxFrames data passed
  // from the IDL backbone.  This collection is passed as
  // separate argv entries, up to MAXFRAMESINDATASETS of them.
  IDL_STRING *Headers[MAXFRAMESINDATASETS];
  float *IntFrames[MAXFRAMESINDATASETS];
  unsigned char *IntAuxFrames[MAXFRAMESINDATASETS];
  // End of parameters input in IDL calling program

  //float (*pData)[FRAMESIZE];    // This might hold a pointer to an individual frame
  // of data passed from the IDL backbone.

  short int effective[numspec], row, col, trueCol;  // used for determining extraction region
  int     OFFSET;                                   // Y-position offset between BB and NB; in reality, this may not be needed.
  short int i=0, j=0, jj=0, slice=0, sp=0, shift=0;
  int status = 0;
  short int basesize, hilo[numspec][2];
  short int BB=TRUE, NB=FALSE;         // logical variables to set between broadband/narrowband modes.
  float (*raw_data)[DATA];         // Used to access individual frames as 2-D arrays
  float (*raw_int)[DATA];         // Used to access noise frames as 2-D arrays
  unsigned char (*raw_aux)[DATA];     // Used to access quality frames as 2-D arrays
  float weight[numspec];           // weight array
  //float basis_vectors[numspec][MAXSLICE][DATA];  // malloc to get this, then make sure it is released.
  fitsfile *fptr;       /* pointer to the FITS file, defined in fitsio.h */
  char *pOutDir;
  long int fpixel = 1, naxis = 2, nelements;
  long int naxis_hilo = 2, naxis_effective = 1, naxis_basis_vectors = 3;
  long int naxes_hilo[2] = { 2, numspec };    // Indices go "backwards", like FORTRAN
  long int naxes_effective[1] = { numspec };  //
  long int naxes_basis_vectors[3] = { DATA, MAXSLICE, numspec };    // Indices go "backwards", like FORTRAN
  float total, pretotal, posttotal;  // Temporary variables when looking for bad pixels.

  int skip1; // Temporary variable to turn on/off some value checks

  // These parameters should be set in the same order as theay are passed
  // from the IDL code.  This is not yet automated, and I'm not sure how to
  // do it.
  i = 0;
  totalParmCount = *(short int *)argv[i++];
  weight_limit = *(float *)argv[i++];
  slice = *(short int *)argv[i++];
  shift = *(short int *)argv[i++];  // Shift is a global spectral shift if the grating is moved.
  pModule = (Module *)argv[i++];
  pDataSet = (DataSet *)argv[i++];
  outDirname = (IDL_STRING *)argv[i++];
  //(void)printf("Executing mkrecmatrx_000.c... outDirname  = *%s*\n", outDirname->s);
  outFilename = (IDL_STRING *)argv[i++];
  //(void)printf("Executing mkrecmatrx_000.c... outFilename = *%s*\n", outFilename->s);
  sfilter = (IDL_STRING *)argv[i++];
  frameCount = *(short int *)argv[i++];

  /*
   * Samples that access the input data
   */
  /*
  (void)printf("Executing mkrecmatrx_000... totalParmCount = %d\n", totalParmCount);
  (void)printf("Executing mkrecmatrx_000... weight_limit   = %f\n", weight_limit);
  (void)printf("Executing mkrecmatrx_000... slice          = %d\n", slice);
  (void)printf("Executing mkrecmatrx_000... sfilter        = %s\n", sfilter->s);
  (void)printf("Executing mkrecmatrx_000... frameCount     = %d\n", frameCount);

  (void)printf("Executing mkrecmatrx_000... Module.Name            = %s\n", pModule->Name.s);
  (void)printf("Executing mkrecmatrx_000... Module.CallSequence    = %s\n", pModule->CallSequence.s);
  (void)printf("Executing mkrecmatrx_000... Module.Skip            = %d\n", pModule->Skip);
  (void)printf("Executing mkrecmatrx_000... Module.Save            = %d\n", pModule->Save);
  (void)printf("Executing mkrecmatrx_000... Module.SaveOnErr       = %d\n", pModule->SaveOnErr);
  (void)printf("Executing mkrecmatrx_000... Module.OutputDir       = %s\n", pModule->OutputDir.s);
  (void)printf("Executing mkrecmatrx_000... Module.CalibrationData = %s\n", pModule->CalibrationData.s);
  (void)printf("Executing mkrecmatrx_000... Module.LabData         = %s\n", pModule->LabData.s);

  (void)printf("Executing mkrecmatrx_000... DataSet.Name           = %s\n", pDataSet->Name.s);
  (void)printf("Executing mkrecmatrx_000... DataSet.InputDir       = %s\n", pDataSet->InputDir.s);
  (void)printf("Executing mkrecmatrx_000... DataSet.OutputDir      = %s\n", pDataSet->OutputDir.s);
  */

  ptrsOffset = totalParmCount - (4*frameCount);
  if (argc != ((4*frameCount)+ptrsOffset))
    return -1;

  for (i=0; i<frameCount; i++) {
    Frames[i]       = (float *        )argv[ptrsOffset+4*i+0];
    Headers[i]      = (IDL_STRING *  )argv[ptrsOffset+4*i+1];
    IntFrames[i]    = (float *        )argv[ptrsOffset+4*i+2];
    IntAuxFrames[i] = (unsigned char *)argv[ptrsOffset+4*i+3];
  }

  /*
   * Start placing items from the original rectification code here.
   * This code will build and save the influence matrix from a set
   * of input data frames, together with a few parameters passed from
   * the calling IDL code.
   */

  // Changed conditional to work with the KC filters 6/7/2008 (JEL)
  if (strncmp(&(sfilter->s)[2], "b", 1)!=0) {
    BB=FALSE;
    NB=TRUE;
    OFFSET=-4;  // Narrowband spectra are lower
    for (sp=0; sp< numspec; sp++) {
      effective[sp]=1;
    }
    for (sp=1024; sp<numspec; sp++)
      effective[sp] = 0;
  } else {
    BB=TRUE;
    NB=FALSE;
    OFFSET=0;
    // Throughout the DRP, spectrum number (sp) starts from the upper left corner of the
    // ... lenslet array couting downward. ( sp = (col-1)*specpercol + row )
    // Simplified masking with the effective variable 10/6/2004 (JEL)
    // First fill effective file with 1's
    for (sp=0; sp< numspec; sp++) {
      effective[sp]=1;
    }

    // Mask off the bottom 48 lenslets of the 1st column
    for (sp=16; sp< 64; sp++) {
      effective[sp]=0;
    }
    // Mask off the bottom 32 lenslets of the 2nd column
    for (sp=(96); sp< (128); sp++) {
      effective[sp]=0;
    }
    // Mask off the bottom 16 lenslets of the 3rd column
    for (sp=(176); sp< (192); sp++) {
      effective[sp]=0;
    }

    // Mask off the top 16 lenslets of the 17th column
    for (sp=(1024); sp< 1040; sp++) {
      effective[sp]=0;
    }
    // Mask off the top 32 lenslets of the 18th column
    for (sp=(1088); sp< 1120; sp++) {
      effective[sp]=0;
    }
    // Mask off the top 48 lenslets of the 19th column
    for (sp=1152; sp< 1200; sp++) {
      effective[sp]=0;
    }

    // We lose one lenslet off the top of the 1st 5 columns.
    // ... add more lenslets to mask them out softwarely.
    //    effective[   0]=0;
    // effective[  64]=0;
    //effective[ 128]=0;
    //effective[ 192]=0;
    //effective[ 256]=0;
  }

  // Apply the passed in shift due to any gross motions of the grating.
  OFFSET += shift;

  // set basesize to be an odd number always for calculational convenience!
  if ( (slice % 2) == 0 )
    basesize = slice + 1;
  else
    basesize = slice;
  if (basesize>32)
    basesize=31;
  //(void)printf("Executing mkrecmatrx_000... effective and basesize set\n");

  // hilo array describes, for each column of lenslets, where the calibration data
  // lie on the 2048 X 2048 calibration image.
  // Modified base value to 2056 on Oct 6, 2004 (JEL)
  // Modified base value to 2054 on Feb 27, 2005 (JEL)

  // Temporarily trying 2052 on Dec 23, 2009 (JEL)
  sp = 0;
  for (col=0; col<numcolumn; col++ ) {
    for (row=0; row<specpercol; row++ ) {
      // Modified vertical offset between spectra to 31.79 from 31.9
      hilo[sp][0]=2052+OFFSET-(31.79*row)-(2*col)-((basesize-1)/2);  // y-pixel lower limit for calibration frame of spectrum no.=sp
      hilo[sp][1]=2052+OFFSET-(31.79*row)-(2*col)+((basesize-1)/2);  // y-pixel upper limit for calibration frame of spectrum no.=sp
      //hilo[sp][0]=2052+OFFSET-(31.9*row)-(2*col)-((basesize-1)/2);  // y-pixel lower limit for calibration frame of spectrum no.=sp
      //hilo[sp][1]=2052+OFFSET-(31.9*row)-(2*col)+((basesize-1)/2);  // y-pixel upper limit for calibration frame of spectrum no.=sp
      
      // Checking for top and bottom edges added 10/7/04 (JEL)
      if (hilo[sp][0] < 0) {       // Spectrum is close to the bottom edge
        hilo[sp][0]=0;  // y-pixel lower limit for calibration frame of spectrum no.=sp
        hilo[sp][1]=basesize;  // y-pixel upper limit for calibration frame of spectrum no.=sp
      }
      if (hilo[sp][1] >= DATA) {    // Spectrum is close to top edge
        hilo[sp][0]=DATA-basesize-1;  // y-pixel lower limit for calibration frame of spectrum no.=sp
        hilo[sp][1]=DATA-1;           // y-pixel upper limit for calibration frame of spectrum no.=sp
      }
      sp++;
    }
  }
  //(void)printf("Executing mkrecmatrx_000... hilo set\n");


  sp = 0;
  for (col=0; col<numcolumn; col++ )  // col is the index of the proper frame in DataSet.Frames[]
  {
    trueCol = col;

    raw_data = (float (*) [DATA])(Frames[trueCol]);
    // Added assignments for noise and quality frames 10/7/2004 (JEL)
    raw_int = (float (*) [DATA])(IntFrames[trueCol]);
    raw_aux = (unsigned char (*) [DATA])(IntAuxFrames[trueCol]);

    for (row=0; row<specpercol; row++ ) {
      for (j=hilo[sp][0]; j<hilo[sp][1]; j++ ) {
        jj = j - hilo[sp][0];
        if ( (j < DATA) && (j >= 0) ) {
          for (i=0; i<DATA; i++ ) {
            // Added checking quality flag for basis vectors 10/6/2004 (JEL) //
            if ( (raw_aux[j][i] & 1) && (effective[sp] == 1) ) // Quality frame has the valid bit set
            {
              basis_vectors[sp][jj][i] = raw_data[j][i];
            } else   // Flagged bad pixel or not effective spectrum
            {
	      basis_vectors[sp][jj][i] = 0.0;
            }
          }
        }
      }
      sp++;
    }
  } // End the loop for setting basis_vectors


  ////////////////////////////////////////////////////////////////////////////////////////////
  // Construct normalized basis_vectors
  //  use image array as temporary storage space to search for local maxima of basis vectors
  ////////////////////////////////////////////////////////////////////////////////////////////
  for ( sp=0; sp<numspec; sp++ ) {   // search for the maximum value of b.v. for each column
    weight[sp]=0.0;
    // For one of the middle columns, find the sum of each basis vector
    // Then select the median sum as the normalization factor for all basis vectors. 10/6/2004 (JEL)
    i = 1000;  // Arbitrary but near middle of array and not on a boundary 10/6/2004 (JEL)
    for ( j=0; j<basesize; j++ ) {
      weight[sp]+=basis_vectors[sp][j][i];
    }
  }
  // Set weight[0] to the median of the weights
  // Perform slow dumb sort of the weight matrices. Ignore the 0th element. Use for temporary storage.
  for ( sp=1; sp<numspec; sp++ ) {
    for (j = sp+1; j<numspec; j++ ) {
      if ( weight[sp] > weight[j] ) {
	weight[0]=weight[sp];
	weight[sp]=weight[j];
	weight[j]=weight[0];
      }
    }
  }
  
  // Now set the reference weight to the median of the weight matrix. This is in the middle position because of the sort.
  //  weight[0] = weight[numspec/2];
  weight[0] = weight[numspec-20];
  
  (void)printf ("Global weight= %f\n",weight[0]);
  for ( sp=0; sp<numspec; sp++ )
    for (i = 0; i<DATA; i++ )
      for ( j = 0; j < basesize; j++ ) {
        basis_vectors[sp][j][i]=basis_vectors[sp][j][i]/weight[0];
	// Check to see if data is a NAN... If so then set to zero (JEL 12/22/09)
	x = basis_vectors[sp][j][i];
	if ( x != x ) {
	  basis_vectors[sp][j][i] = 0.0;
	}
        if (basis_vectors[sp][j][i] < weight_limit)
	  basis_vectors[sp][j][i] = 0.0;
      }
 
 // Now look for bad elements in matrix. Bad is 2x both neighbors in spectral direction or 4x in spatial direction.
 // jlyke 2016mar30 skip this as a try why PSF replaced with so many zeros
 // jlyke 2016apr06 make skip1=0 as we had weird values in recmats
  skip1 = 0;
  if ( skip1 == 0 ) { 
  for ( sp=0; sp<numspec; sp++ ) {
    for ( i = 1; i< (DATA-1); i++ ) {
      pretotal = 0.0;
      for (j = 1; j < (basesize-1); j++ ) {
	// Pixels should be between 0 and 1 but noise can make them slightly negative and the psf should make the peak pixels below about 0.8 even in extreme cases. But to make sure we're just killing bad pixels, I'm going to zap values between -0.05 and 1.0.  (JEL 12/23/09)
	if ( basis_vectors[sp][j][i] < -0.05 ) basis_vectors[sp][j][i]=0.0;
	if ( basis_vectors[sp][j][i] > 1.0 ) basis_vectors[sp][j][i]=0.0;

       	pretotal += basis_vectors[sp][j][i];
	if ( fabs(basis_vectors[sp][j][i]) > ( (basis_vectors[sp][j-1][i]+basis_vectors[sp][j+1][i])*2.0 ) ) {
	  basis_vectors[sp][j][i]= (basis_vectors[sp][j-1][i]+basis_vectors[sp][j+1][i])/2.0;
	}
	if ( fabs(basis_vectors[sp][j][i]) > ( (basis_vectors[sp][j][i-1]+basis_vectors[sp][j][i+1])*2.0 ) ) {
	  basis_vectors[sp][j][i]= (basis_vectors[sp][j][i+1]+basis_vectors[sp][j][i-1])/2.0;
	}
	if ( fabs(basis_vectors[sp][j][i]) < ( (basis_vectors[sp][j][i-1]+basis_vectors[sp][j][i+1])/2.0 ) ) {
	  if ( (basis_vectors[sp][j][i-1] > 0.1) ) {
	    if ( (basis_vectors[sp][j][i+1] > 0.1) ) {
	      basis_vectors[sp][j][i]= (basis_vectors[sp][j][i+1]+basis_vectors[sp][j][i-1])/2.0;
	    }
	  }
	}
	
       }
      // Look at the upper and lower edges of each strip. Set them to 0, if they are too large
      if ( fabs(basis_vectors[sp][0][i]) > (pretotal/2.0) ) basis_vectors[sp][0][i]=0.0;
      if ( fabs(basis_vectors[sp][(basesize-1)][i]) > (pretotal/2.0) ) basis_vectors[sp][(basesize-1)][i]=0.0;
    }
  }
  }


  // Write a FITS file containing the hilo, effective and "normalized basis vectors" arrays
  // Add some keywords too.
  // Create an output file name from the parameter outFilename and the parameter outDirname
  (void)strcpy(completeOutName, outDirname->s);
  // Eliminate any trailing '/' from the directory path
  if (completeOutName[strlen(completeOutName)-1] == '/')
    completeOutName[strlen(completeOutName)-1] = '\0';
  // Create the actual file name.
  fits_create_file(&fptr, makefitsfilenamenoext(completeOutName, outFilename->s, -1,strBuf), &status);

  /* Create the primary array image (16-bit short integer pixels */
  fits_create_img(fptr, SHORT_IMG, naxis_hilo, naxes_hilo, &status);

  /* Write some keywords; must pass the ADDRESS of the value */
  fits_update_key(fptr, TSHORT, "BASESIZE", &basesize, "Derived from input slice value", &status);
  fits_update_key(fptr, TFLOAT, "WTLIMIT", &weight_limit, "Passed in parameter", &status);
  fits_update_key(fptr, TSHORT, "SLICE", &slice, "Passed in parameter", &status);
  fits_update_key(fptr, TSHORT, "SHIFT", &shift, "Passed in paraemter", &status);

  nelements = naxes_hilo[0] * naxes_hilo[1];  /* number of pixels to write */

  /* Write the array of short integers in hilo[] to the image */
  fits_write_img(fptr, TSHORT, fpixel, nelements, hilo[0], &status);

  /* Create a new image extension (16-bit short integer pixels */
  fits_create_img(fptr, SHORT_IMG, naxis_effective, naxes_effective, &status);

  nelements = naxes_effective[0];  /* number of pixels to write */

  /* Write the array of short integers in effective[] to the image */
  fits_write_img(fptr, TSHORT, fpixel, nelements, effective, &status);

  /* Create a new image extension (32-bit float pixels */
  fits_create_img(fptr, FLOAT_IMG, naxis_basis_vectors, naxes_basis_vectors, &status);

  nelements = naxes_basis_vectors[0] * naxes_basis_vectors[1] * naxes_basis_vectors[2];  /* number of pixels to write */

  /* Write the array of floats in basis_vectors[] to the image */
  fits_write_img(fptr, TFLOAT, fpixel, nelements, basis_vectors[0][0], &status);

  fits_close_file(fptr, &status);       /* close the file */
  fits_report_error(stderr, status);  /* print out any error messages */

  return 0;
}
