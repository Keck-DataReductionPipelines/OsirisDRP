To compile:
goto drs/modules/source
edit the local_Makefile to set the IDL_INCLUDE directory to where your local idl source resides. You may also need to set the CFITSIOLIBDIR variable to the directory containing the cfitsio binary file.

* On a linux or Solaris system issue the following command in the source directory:
     gmake –f local_Makefile
* On a Mac where gmake is the normal (and often the only make command) issue the following command in the source directory:
     make –f local_Makefile