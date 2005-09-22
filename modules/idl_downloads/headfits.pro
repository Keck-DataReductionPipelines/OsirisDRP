function HEADFITS, filename, EXTEN = exten, Compress = compress, $ 
                   ERRMSG = errmsg, SILENT = silent
;+
; NAME:
;       HEADFITS
; PURPOSE:
;       Read a FITS (primary or extension) header into a string array.
; EXPLANATION:
;       Under Unix, HEADFITS() can also read gzip (.gz) or Unix compressed
;       (.Z) FITS files.   In IDL V5.3 or later, HEADFITS() can read gzip files
;       under any machine OS. 
;
; CALLING SEQUENCE:
;       Result = HEADFITS(Filename/Fileunit ,[ ERRMSG =, EXTEN= , COMPRESS=, 
;                                            /SILENT ])
;
; INPUTS:
;       Filename = String containing the name of the FITS file to be read.
;                File names ending in '.gz' are assumed to be gzip'ed compressed
;                and under Unix file names ending in '.Z' are assumed to be
;                Unix compressed.    If this default behaviour is not sufficient
;                then use the COMPRESS keyword.
;                            or
;       Fileunit - A scalar integer specifying the unit of an already opened
;                  FITS file.  The unit will remain open after exiting 
;                  HEADFITS().  There are two possible reasons for choosing 
;                  to specify a unit number rather than a file name:
;          (1) For a FITS file with many extensions, one can move to the 
;              desired extensions with FXPOSIT() and then use HEADFITS().  This
;              is more efficient that repeatedly starting at the beginning of 
;              the file.
;          (2) For reading a FITS file across a Web http: address after opening
;              the unit with the SOCKET procedure (IDL V5.4 or later,
;              Unix and Windows only) 
; OPTIONAL INPUT KEYWORDS:
;      EXTEN  = integer scalar, specifying which FITS extension to read.
;               For example, to read the header of the first extension set
;               EXTEN = 1.   Default is to read the primary FITS header 
;               (EXTEN = 0).    The EXTEN keyword cannot be used when a unit
;               number is supplied instead of a file name.
;     COMPRESS - If this keyword is set and non-zero, then treat the file
;              as compressed.  If 1 assume a gzipped file.   Where possible use
;              IDLs internal decompression facilities (i.e., v5.3 or greater) 
;              or on Unix systems spawn off a process to decompress and use its
;              output as the FITS stream.  If the keyword is not 1, then use 
;              its value as a string giving the command needed for 
;              decompression.   See FXPOSIT for more info.
;     /SILENT - If set, then suppress any warning messages about invalid 
;              characters in the FITS file.
; OPTIONAL KEYWORD OUTPUT:
;       ERRMSG	= If this keyword is present, then any error messages will be
;                 returned to the user in this parameter rather than
;                 depending on the MESSAGE routine in IDL.  If no errors are
;                 encountered, then a null string is returned.  
;
; OUTPUTS:
;       Result of function = FITS header, string array
;
; EXAMPLE:
;       Print the main FITS header of a file 'test.fits' into a string 
;       variable, h
;
;       IDL>  print, headfits( 'test.fits')
;
;       Print the second extension header of a gzip compressed FITS file
;       'test.fits.gz'.  Use HPRINT for pretty format
;
;       IDL> hprint, headfits( 'test.fits.gz', ext=2)
;
; PROCEDURES CALLED
;       FXPOSIT(), MRD_HREAD
; MODIFICATION HISTORY:
;       adapted by Frank Varosi from READFITS by Jim Wofford, January, 24 1989
;       Keyword EXTEN added, K.Venkatakrishna, May 1992
;       Make sure first 8 characters are 'SIMPLE'  W. Landsman October 1993
;       Check PCOUNT and GCOUNT   W. Landsman    December 1994
;       Major rewrite, work for Unix gzip files,   W. Landsman  April 1996
;       Converted to IDL V5.0   W. Landsman   September 1997
;       Added COMPRESS keyword  W. Landsman   April 2000
;       Added ERRMSG keyword    W. Landsman   July 2000
;       Added /SILENT keyword   W. Landsman    December 2000
;       Option to read a unit number rather than file name W.L    October 2001
;-
 On_error,2

 if N_params() LT 1 then begin
     print,'Syntax - header = headfits( filename,[ EXTEN=, ERRMSG=, ' + $
                   '/SILENT, COMPRESS= ])'
     return, -1
 endif

  if arg_present(errmsg) then errmsg = ''
  if not keyword_set(exten) then exten = 0

  unitsupplied = size(filename,/TNAME) NE 'STRING'
  if unitsupplied then unit = filename else begin 
     unit = fxposit( filename, exten, $
                   /READONLY,compress = compress, SILENT=silent)
     if unit EQ -1 then begin 
         message = 'Unable to open file ' + filename 
         if N_elements(errmsg) GT 0 then errmsg = message else $
          message,'ERROR - ' + message,/CON 
       return,-1
     endif
     if eof(unit) then begin
        free_lun,unit
        message = 'Extension past EOF'
        if N_elements(errmsg) GT 0 then errmsg = message else $
               message,'ERROR - ' + message,/CON 
        return,-1
     endif
  endelse
  mrd_hread, unit, header, status, SILENT = silent
  if not unitsupplied then free_lun, unit
 
  return, header
  end
