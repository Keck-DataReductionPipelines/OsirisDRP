pro writefits, filename, data, header, NaNvalue = NaNvalue, Append = Append
;+
; NAME:
;       WRITEFITS
; PURPOSE:
;       Write IDL array and header variables to a disk FITS file.    
;
; EXPLANATION:
;       A minimal FITS header is created if not supplied.
;       WRITEFITS works for all types of FITS files except random groups
;
; CALLING SEQUENCE:
;       WRITEFITS, filename, data [, header, /APPEND] 
;
; INPUTS:
;       FILENAME = String containing the name of the file to be written.
;
;       DATA = Image array to be written to FITS file.    If DATA is 
;              undefined or a scalar, then only the FITS header (which
;              must have NAXIS = 0) will be written to disk
;
; OPTIONAL INPUT:
;       HEADER = String array containing the header for the FITS file.
;                If the variable HEADER is not supplied, the program will 
;                generate a minimal FITS header.
;
; OPTIONAL INPUT KEYWORD:
;       /APPEND - If this keyword is set then the supplied header and data
;                array are assumed to be an extension and are appended onto
;                the end of an existing FITS file.    If the file does not 
;                exist, then WRITEFITS will create one with a minimal primary
;                header (and /EXTEND keyword) and then append the supplied
;                extension header and array.     Note that the primary
;                header in an existing file must already have an EXTEND
;                keyword to indicate the presence of an FITS extension.
;
; OUTPUTS:
;       None
;
; RESTRICTIONS:
;       (1) It recommended that BSCALE and BZERO not be used (or set equal
;           to 1. and 0) with REAL*4 or REAL*8 data.
;       (2) WRITEFITS will remove any group parameters from the FITS header
;
; EXAMPLE:
;       Write a randomn 50 x 50 array as a FITS file creating a minimal header.
;
;       IDL> im = randomn(seed, 50, 50)        ;Create array
;       IDL> writefits, 'test', im             ;Write to a FITS file "test"
;
; PROCEDURES USED:
;       CHECK_FITS, MKHDR, MRD_HREAD, SXDELPAR, SXADDPAR, SXPAR()
;
; MODIFICATION HISTORY:
;       WRITTEN, Jim Wofford, January, 29 1989
;       MODIFIED, Wayne Landsman, added BITPIX = -32,-64 support for UNIX
;       Use new BYTEODER keywords 22-Feb-92
;       Modify OPENW for V3.0.0   W. Landsman       Dec 92
;       Work for "windows"   R. Isaacman            Jan 93
;       More checks for null data                   Mar 94
;       Work for Linux  W. Landsman                 Sep 95
;       Added call to IS_IEEE_BIG()  W. Landsman  Apr 96
;       Make sure SIMPLE is written in first line of header  W. Landsman Jun 97
;       Use SYSTIME() instead of !STIME    W. Landsman  July 97
;       Create a default image extension header if needed W. Landsman June 98
;       Converted to IDL V5.0   W. Landsman         June 98
;       Write unsigned data types W. Landsman       December 1999
;       Correct BZERO value for unsigned data  W. Landsman   July 2000
;       Assume at least V5.1 remove NANValue keyword W. Landsman July 2001
;       Use FILE_SEARCH for V5.5 or later     W. Landsman    April 2002
;       Create the file if not already present and /APPEND is set
;                                             W. Landsman    September 2002
;	Change error handling so that errors are raised instead of -1 return values. 
;		Specific to the DRP backbone.		T. Wizansky January 2003 
;-
  On_error, 2
  FORWARD_FUNCTION FILE_SEARCH      ;For pre-V5.5 compatibility

  if N_params() LT 2 then begin 
       MESSAGE,'Syntax - WRITEFITS, filename, data,[ header, /APPEND]'
  endif

; Get information about data

  siz = size( data )
  naxis = siz[0]                    ;Number of dimensions
  if naxis GT 0 then nax = siz[ 1:naxis ]              ;Vector of dimensions
  lim = siz[ naxis+2 ]              ;Total number of data points
  type = siz[naxis + 1]             ;Data type

;Create a primary or image extension header if not supplied by the user

        if N_elements(header) LT 2 then begin 
                if keyword_set(append) then mkhdr, header, data, /IMAGE  $
                                       else mkhdr, header, data, /EXTEND
        endif else if naxis GT 0 then $         
              check_FITS, data, header, /UPDATE, /FITS

; Remove any STSDAS/random group keywords from the primary header

  hdr = header
  if not keyword_set( APPEND) then begin 
         simple = 'SIMPLE  =                    T / Written by IDL:  ' $
                        + systime()  
         hdr[0] =  simple + string( replicate(32b,80-strlen(simple) ) )
         sxdelpar, hdr, [ 'GCOUNT', 'GROUPS', 'PCOUNT', 'PSIZE' ]
  endif

  ; If necessary,convert unsigned to signed.    Do not destroy the original data

  if naxis NE 0 then begin
        
        unsigned = (type EQ 12) or (type EQ 13)
        if unsigned then begin
              if type EQ 12 then begin
                     sxaddpar,hdr,'BZERO',32768,'Data is Unsigned Integer'
                     newdata = fix(data - 32768)
             endif else if type EQ 13 then begin 
                    sxaddpar,hdr,'BZERO',2147483648,'Data is Unsigned Long'
                    newdata = long(data - 2147483648)
             endif
         endif
 endif

; Open file and write header information

        if keyword_set( APPEND) then begin
            if (strmid( hdr[0],0,8 ) NE 'XTENSION') then begin
                   message, 'ERROR - "XTENSION" must be first keyword in header extension'
            endif
            if !VERSION.RELEASE GE '5.5' then $
            test = file_search(filename, COUNT = n) else $
            test = findfile( filename, COUNT = n)
            if n EQ 0 then  begin       ;Create default primary header
                mkhdr,h0,0,/exten
                writefits,filename,0,h0
                openu, unit, filename, /BLOCK, /GET_LUN, /swap_if_little_endian
            endif else begin
            openu, unit, filename, /BLOCK, /GET_LUN, /swap_if_little_endian
            mrd_hread, unit, hprimary
            extend = where( strmid(hprimary,0,8) EQ 'EXTEND  ', Nextend)
             if Nextend EQ 0 then begin
               message,'EXTEND keyword not found in primary FITS header'
            endif
            endelse
                   
            file = fstat(unit)
            nbytes  = file.size
            point_lun, unit, nbytes
            npad = nbytes mod 2880
            if npad NE 0 then writeu, unit, replicate(32b, 2880 - npad)

    endif else begin

        if !VERSION.OS EQ "vms" then $
                openw, unit, filename, /NONE, /BLOCK, /GET_LUN, 2880, $
                       /swap_if_little_endian   else $
                openw, unit, filename, /GET_LUN, /swap_if_little_endian

    endelse

; Determine if an END line occurs, and add one if necessary

       endline = where( strmid(hdr,0,8) EQ 'END     ', Nend)
     if Nend EQ 0 then begin

 message,'WARNING - An END statement has been appended to the FITS header',/INF
     hdr = [ hdr, 'END' + string( replicate(32b,77) ) ]
     endline = N_elements(hdr) - 1 

   endif
   nmax = endline[0] + 1

; Convert to byte and force into 80 character lines

       bhdr = replicate(32b, 80l*nmax)
       for n = 0l, endline[0] do bhdr[80*n] = byte( hdr[n] )
       npad = 80l*nmax mod 2880
       writeu, unit, bhdr
       if npad GT 0 then writeu, unit,  replicate(32b, 2880 - npad)

; Write data
       if naxis EQ 0 then goto, DONE
        bitpix = sxpar( hdr, 'BITPIX' )
        nbytes = N_elements( data) * (abs(bitpix) / 8 )
        npad = nbytes mod 2880

        if unsigned then writeu, unit, newdata $
                    else writeu, unit, data 
   
; ASCII Tables padded with blanks (32b) otherwise pad with zeros
        if keyword_set( APPEND) then begin
             exten = sxpar( header, 'XTENSION')
             if exten EQ 'TABLE   ' then padnum = 32b else padnum = 0b
        endif else padnum = 0b
         
        if npad GT 0 then writeu, unit, replicate( padnum, 2880 - npad)
DONE:
        free_lun, unit  

  return
  end
