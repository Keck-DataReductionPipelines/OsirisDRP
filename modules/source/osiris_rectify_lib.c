// drplib.c
//
//                     Song  09/04/2002 separating subroutines from Tom Gasaway's drpbparm.c as drplib.c
//
//                                      Change systime function to use the internal clock() function.
//                                      clock() function returns processor time used by this program
//                                              in unit of 1/1,000,000 sec.

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "fitsio.h"  

void printerror( int status, int lineNumber ) {
  /*****************************************************/
  /* Print out cfitsio error messages and exit program */
  /*****************************************************/

  char status_str[FLEN_STATUS], errmsg[FLEN_ERRMSG];
  
  if (status)
    fprintf( stderr, "\n*** Error occurred during program execution at line %d***\n", lineNumber );

  fits_get_errstatus(status, status_str);       // get the error description
  fprintf(stderr, "\nstatus = %d: %s\n", status, status_str);

  // get first message; null if stack is empty
  if ( fits_read_errmsg(errmsg) ) 
    {
      fprintf(stderr, "\nError message stack:\n");
      fprintf(stderr, " %s\n", errmsg);

      while ( fits_read_errmsg(errmsg) )        // get remaining messages
	fprintf(stderr, " %s\n", errmsg);
    }

  // terminate the program, returning error status
  exit( status );       
}

clock_t clock(void);
double systime( void )
{
  long   time1;
  double seconds;

  time1 = (long) clock();
  seconds = (double) (time1 / 1000000.0);

  return seconds;
}

void readheader( char *filename )

     /**********************************************************************/
     /* Print out all the header keywords in all extensions of a FITS file */
     /**********************************************************************/
{
  fitsfile *fptr;       /* pointer to the FITS file, defined in fitsio.h */

  int status, nkeys, keypos, hdutype, ii, jj;
  char card[FLEN_CARD];   /* standard string lengths defined in fitsioc.h */

  status = 0;

  if ( fits_open_file(&fptr, filename, READONLY, &status) ) 
    printerror( status, __LINE__ );

  /* attempt to move to next HDU, until we get an EOF error */
  for (ii = 1; !(fits_movabs_hdu(fptr, ii, &hdutype, &status) ); ii++) 
    {
      /* get no. of keywords */
      if (fits_get_hdrpos(fptr, &nkeys, &keypos, &status) )
	printerror( status, __LINE__ );

      printf("Header listing for HDU #%d:\n", ii);
      for (jj = 1; jj <= nkeys; jj++)  {
	if ( fits_read_record(fptr, jj, card, &status) )
	  printerror( status, __LINE__ );

	printf("%s\n", card); /* print the keyword card */
      }
      printf("END\n\n");  /* terminate listing with END */
    }

  if (status == END_OF_FILE)   /* status values are defined in fitsioc.h */
    status = 0;              /* got the expected EOF error; reset = 0  */
  else
    printerror( status, __LINE__ );     /* got an unexpected error                */

  if ( fits_close_file(fptr, &status) )
    printerror( status, __LINE__ );

  return;
}

#define BYTE_IMG 8 
#define SHORT_IMG 16
#define LONG_IMG 32
#define FLOAT_IMG -32
#define DOUBLE_IMG -64

int dataTypes[] = {    TBYTE,    TSHORT,    TLONG,    TFLOAT,    TDOUBLE };
int imgTypes[]  = { BYTE_IMG, SHORT_IMG, LONG_IMG, FLOAT_IMG, DOUBLE_IMG };

#define NTYPES (sizeof(imgTypes) / sizeof(int))

int getDataType( fitsfile *pFile )
{
  long int bitpix=0, i;
  char keycomment[FLEN_COMMENT]; /* string lengths defined in fitsioc.h */
  int status=0;
  int type=0;

  /* Get BITPIX */
  if ( fits_read_key(pFile, TINT, "BITPIX", (void *)&bitpix, keycomment, &status) )
    printerror( status, __LINE__ );

  for (i=0; i<NTYPES; i++) {
    if ( bitpix == imgTypes[i] ) {
      type = dataTypes[i];
    }
  }

  return type;
}

int getDataTypeFromImgType( int imgType )
{
  int i;
  int type = 0;

  for (i=0; i<NTYPES; i++) {
    if ( imgType == imgTypes[i] ) {
      type = dataTypes[i];
    }
  }

  return type;
}

char strBuf[128];

char * makefitsfilename( char *filedirname, char *filebasename, int filenum, char *filename )
{
  /* filedirname  - char * Directory name where file will be placed.                     */
  /* filebasename - char * File name.                                                    */
  /* filenum      - int    File number one less than the number in the file string.      */
  /*                       If filenum < 0 then it is not used in producing the filename. */
  /* filename     - char * Constructed file name.  It must be a big enough array or the  */
  /*                       results will be unexpected and may damage the program.        */

  (void)strcpy( filename, "!" );        // leading '!' will overwrite pre-existing fits file
  (void)strcat( filename, filedirname );
  (void)strcat( filename, "/" );
  (void)strcat( filename, filebasename );
  if ( filenum >= 0 ) {
    (void)sprintf( strBuf, "%d", filenum+1 );
    (void)strcat( filename, strBuf );
  }
  (void)strcat( filename, ".fits" );
  (void)printf( "Constructed filename = %s\n", filename+1 ); // but don't print the leading '!'

  return filename;
}

char * makefitsfilenamenoext( char *filedirname, char *filebasename, int filenum, char *filename )
{
  /* Modified version makefitsfilename.  Does not append ".fits" to base name.           */
  /* filedirname  - char * Directory name where file will be placed.                     */
  /* filebasename - char * File name.                                                    */
  /* filenum      - int    File number one less than the number in the file string.      */
  /*                       If filenum < 0 then it is not used in producing the filename. */
  /* filename     - char * Constructed file name.  It must be a big enough array or the  */
  /*                       results will be unexpected and may damage the program.        */

  (void)strcpy( filename, "!" );        // leading '!' will overwrite pre-existing fits file
  (void)strcat( filename, filedirname );
  (void)strcat( filename, "/" );
  (void)strcat( filename, filebasename );
  if ( filenum >= 0 ) {
    (void)sprintf( strBuf, "%d", filenum+1 );
    (void)strcat( filename, strBuf );
  }
  //(void)strcat( filename, ".fits" );
  (void)printf( "Constructed filename = %s\n", filename+1 ); // but don't print the leading '!'

  return filename;
}

void writefitsimagefile( char *filename, long int bitpix, long int naxis, long int naxes[], void *address )
{
  /* N.B. If filename exists then we get an error trying to write it. */
  /* long int bitpix - Must be proper image type for data type of array at address. */
  /* long int naxis  - Number of axes.                                              */
  /* long int naxes  - Array of axes values.                                        */
  /* void *address   - Pointer to array of data values.                             */

  long int i, nElements, fpixel = 1;  /* fpixel means always start at pixel number 1, i.e., first pixel. */
  fitsfile *fptr;    /* A pointer to a FITS file; defined in fitsio.h */
  int status = 0;

  if ( fits_create_file( &fptr, filename, &status ) ) {  /* Create new FITS file */
    printerror( status, __LINE__ );
  }

  /* Write the required keywords for the primary array image */
  if ( fits_create_img( fptr,  bitpix, naxis, naxes, &status ) ) {
    printerror( status, __LINE__ );
  }

  /* Compute number of pixels to write */
  nElements = naxes[0];
  for (i = 1; i < naxis; i++ ) {
    nElements = nElements * naxes[i];
  }


  /* Write the array of floats to the file. */
  if ( fits_write_img(fptr, getDataTypeFromImgType( bitpix ), fpixel, nElements, address, &status) ) {
    printerror( status, __LINE__ );
  }

  if ( fits_close_file(fptr, &status) ) {  /* close the file */
    printerror( status, __LINE__ );
  }

  return;
}

void makebasisfile( int kk, int datax, int slice, void *address )
{
  long int bitpix = -32, nElements, naxis = 2, naxes[2], fpixel = 1;
  fitsfile *fptr;             /* pointer to output FITS files; defined in fitsio.h */
  int status = 0;
  char tname[128];

  /* Initialize FITS image parameters */
  /* First build the file name. */
  (void)strcpy( tname, "basis" );
  (void)sprintf( strBuf, "%d", kk+1 );
  (void)strcat( tname, strBuf );
  (void)strcat( tname, ".fits" );
  (void)printf( "tname = %s\n", tname );
  naxes[0] = datax;  /* datax pixels wide */
  naxes[1] = slice;  /* by slice rows */

  if ( fits_create_file( &fptr, tname, &status ) ) {  /* Create new FITS file */
    printerror( status, __LINE__ );
  }

  /* Write the required keywords for the primary array image */
  if ( fits_create_img( fptr,  bitpix, naxis, naxes, &status ) ) {
    printerror( status, __LINE__ );
  }

  nElements = naxes[0] * naxes[1];       /* number of pixels to write */

  /* Write the array of floats to the file. */
  if ( fits_write_img(fptr, TFLOAT, fpixel, nElements, address, &status) ) {
    printerror( status, __LINE__ );
  }

  if ( fits_close_file(fptr, &status) ) {  /* close the file */
    printerror( status, __LINE__ );
  }

  return;
}
