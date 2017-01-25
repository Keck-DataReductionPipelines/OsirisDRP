// drp_structs.h
// 2004-09-09 tmg Per Inseok Song, change number of spectra to 1254 = 19*66

#ifndef DRP_structures
#define DRP_structures

#ifdef __cplusplus
    extern "C" {
#endif

#include <idl_export.h>

#ifdef BIGFRAMES
#define FRAMESIZE               2048
#else
#define FRAMESIZE                 64
#endif

#define MAXFRAMESINDATASETS       30

#define DATA       2048                           // Equivalent to BIGFRAMES' FRAMESIZE
#define MAXSLICE     16                           // Maximum slice of image in pixels; original value = 16
#define numspec    1216                           // numspec and numcolumn are same for BB and NB.
#define numcolumn    19                           // ... final NB frames will have 51 columns and (51*66)=3366 spectra!
#define specpercol (numspec/numcolumn)            // # of spectra per lenslet column
#define BBCUBEDEPTH 1700                          // number of spectral channel per spectrum
#define NBCUBEDEPTH  536                          // number of spectral channel per spectrum
#define IMAGECNT (numspec * DATA * sizeof(float)) // size of reduced 2D image

// This structure defines the portions of a true DataSet IDL structure that are
// accessible in a C module invoked using CALL_EXTERNAL.
typedef struct { 
	IDL_STRING Name;
	IDL_STRING InputDir;
	IDL_STRING OutputDir;
	short int NextAvailableSlot;
	// float *Frames[MAXFRAMESINDATASETS];
	// IDL_STRING (*Headers[MAXFRAMESINDATASETS])[1];
	// float *IntFrames[MAXFRAMESINDATASETS];
	// unsigned char *IntAuxFrames[MAXFRAMESINDATASETS];
} DataSet;

typedef struct {
	IDL_STRING Name;
	IDL_STRING CallSequence;
	short int Skip;
	short int Save;
	short int SaveOnErr;
	IDL_STRING OutputDir;
	IDL_STRING CalibrationData;
	IDL_STRING LabData;
} Module;

// Function definitions
double  systime( void );
void    printerror( int status, int lineNumber );
char    *makefitsfilename( char *filedirname, char *filebasename, int filenum, char *filename );
char    *makefitsfilenamenoext( char *filedirname, char *filebasename, int filenum, char *filename );
void    writefitsimagefile( char *filename, long int bitpix, long int naxis, long int naxes[], void *address );

extern char strBuf[128];

#ifdef __cplusplus
    }
#endif

#endif                               /* DRP_structures */
