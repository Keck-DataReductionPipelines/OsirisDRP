pro check_FITS, im, hdr, dimen, idltype, UPDATE = update, NOTYPE = notype, $
                   SDAS = sdas, FITS = fits, SILENT = silent, ERRMSG = errmsg
;+
; NAME:
;       CHECK_FITS
; PURPOSE:
;       Check that keywords in a FITS header array match the associated data  
; EXPLANATION:
;       Given a FITS array IM, and a associated FITS or STSDAS header HDR, this
;       procedure will check that
;               (1) HDR is a string array, and IM is defined and numeric   
;               (2) The NAXISi values in HDR are appropriate to the dimensions 
;                   of IM
;               (3) The BITPIX value in HDR is appropriate to the datatype of IM
;       If HDR contains a DATATYPE keyword (as in STSDAS headers), then this is 
;       also checked against the datatype of of IM
;       If the /UPDATE keyword is present, then the FITS header will be 
;       modified, if necessary, to force agreement with the image array
;
; CALLING SEQUENCE:
;       check_FITS, im, hdr, [ dimen, idltype, /UPDATE, /NOTYPE, /SDAS, /SILENT
;                              ERRMSG = ]'
;
; INPUT PARAMETERS:
;       IM -  FITS (or STSDAS) array, e.g. as read by READFITS
;       HDR - FITS (or STSDAS) header (string array) associated with IM
;
; OPTIONAL OUTPUTS:
;       dimen - vector containing actual array dimensions
;       idltype- data type of the FITS array as specified in the IDL SIZE
;               function (1 for BYTE, 2 for INTEGER*2, 3 for INTEGER*4, etc.)
;
; OPTIONAL KEYWORD INPUTS:
;       /NOTYPE - If this keyword is set, then only agreement of the array
;               dimensions with the FITS header are checked, and not the 
;               data type.
;       /UPDATE - If this keyword is set then the BITPIX, NAXIS and DATATYPE
;               FITS keywords will be updated to agree with the array
;       /SDAS - If this keyword is set then the header is assumed to be from
;               an SDAS (.hhh) file.    CHECK_FITS will then ensure that (1)
;               a DATATYPE keyword is included in the header and (2) BITPIX
;               is always written with positive values.
;       /FITS -  If this keyword is present then CHECK_FITS assumes that it is
;               dealing with a FITS header and not an SDAS header, see notes
;               below.
;       /SILENT - If keyword is set and nonzero, the informational messages 
;               will not be printed
; OPTIONAL KEYWORD OUTPUT:
;       ERRMSG  = If this keyword is present, then any error messages will be
;                 returned to the user in this parameter rather than
;                 depending on the MESSAGE routine in IDL.  If no errors are
;                 encountered, then a null string is returned.  
;;
; PROCEDURE:
;       Program checks the NAXIS1 and NAXIS2 parameters in the header to
;       see if they match the image array dimensions.
;
; NOTES:
;       An important distinction between an STSDAS header and a FITS header
;       is that the BITPIX value in an STSDAS header is always positive, 
;       e.g. BITPIX=32 for REAL*4 data.    Users should use either the /SDAS 
;       or the /FITS keyword if it is important whether the STSDAS or FITS 
;       convention for REAL*4 data is used.     Otherwise, CHECK_FITS assumes 
;       that if a DATATYPE keyword is present then it is dealing with an 
;       STSDAS header.
;
; PROCEDURE CALLS:
;       STRN(),FXADDPAR, fxpar() 
; MODIFICATION HISTORY:
;       Written, December 1991  W. Landsman Hughes/STX to replace CHKIMHD
;       No error returned if NAXIS=0 and IM is a scalar   W. Landsman  Feb 93
;       Fixed bug for REAL*8 STSDAS data W. Landsman July 93
;       Make sure NAXIS agrees with NAXISi  W. Landsman  October 93
;        Converted to IDL V5.0   W. Landsman   September 1997
;       Allow unsigned data types   W. Landsman December 1999
;       Allow BZERO = 0 for unsigned data types   W. Landsman January 2000
;       Added ERRMSG keyword, W. Landsman February 2000
;       Use FXADDPAR to put NAXISi in proper order   W. Landsman August 2000
;       Improper FXADDPAR call for DATATYPE keyword  W. Landsman December 2000
;       Remove explicit setting of obsolete !err W. Landsman February 2004
;- 
 On_error,2

 if N_params() LT 2 then begin
    print,'Syntax - CHECK_FITS, im, hdr, dimen, idltype, '
    print,'            [ /UPDATE, /NOTYPE, /SDAS, /FITS, ERRMSG=, /SILENT ]'
    return
 endif

 if arg_present(errmsg) then errmsg = ''       
 hinfo = size(hdr)
 if ( hinfo[0] NE 1 ) then begin                      ;Is hd of string type?
        message= 'FITS header is not a string array'
        if  N_elements(ERRMSG) GT 0 then errmsg = message else $
             message, 'ERROR - ' + message, /CON
             return 
 endif

 im_info = size(im)
 ndim = im_info[0]

 nax = fxpar( hdr, 'NAXIS', Count = N_naxis ) 
 if N_naxis EQ 0 then begin
        message = 'FITS header missing NAXIS keyword'
        if  N_elements(errmsg) GT 0 then errmsg = message else $
             message,'ERROR - ' + message,/CON 
             return 
 endif
        

 if ( ndim EQ 0 ) then $                  ;Null primary array
     if nax EQ 0 then return else begin
         message = 'FITS array is not defined'
         if  N_elements(errmsg) GT 0 then errmsg = message else $
             message,'ERROR - ' +message,/con 
             return 
     endelse

 dimen = im_info[ indgen( im_info[0] ) + 1]
 ndimen = N_elements( dimen)
 naxis = fxpar( hdr, 'NAXIS*')
 naxi = N_elements( naxis )
 if nax GT naxi then begin                 ;Does NAXIS agree with # of NAXISi?
        if keyword_set( UPDATE) then begin
                fxaddpar, hdr, 'NAXIS', naxi
                if not keyword_set(SILENT) then message, /INF, $
        'NAXIS changed from ' + strtrim(nax,2) + ' to ' + strtrim(naxi,2)
        endif else begin 
                message =  'FITS header has NAXIS = ' + strtrim(nax,2) + $
                ', but only ' + strtrim(naxi, 2) + ' axes defined'
                if  N_elements(ERRMSG) GT 0 then errmsg = message else $
                    message, 'ERROR - ' + message
                return
        endelse
 endif

 last = naxi-1                        ;Remove degenerate dimensions
 while ( (naxis[last] EQ 1) and (last GE 1) ) do last = last -1
 if last NE nax-1 then begin
     naxis = naxis[ 0:last]
 endif 

 if ( ndimen NE last + 1 ) then begin
    if not keyword_set( UPDATE) THEN begin
        message = $
        '# of NAXISi keywords does not match # of array dimensions'
        if  N_elements(ERRMSG) GT 0 then errmsg = message else $
                                     message,'ERROR - ' + message,/CON 
        return 
 
     endif else goto, DIMEN_ERROR
 endif

 for i = 0,last do begin
      if naxis[i] NE im_info[i+1] then begin
      if not keyword_set( UPDATE ) then begin
          message =  'Invalid NAXIS' + strn( i+1 ) + ' keyword value in header'
          if  N_elements(ERRMSG) GT 0 then errmsg = message else $ 
                                       message,'ERROR - ' + message,/CON
          return 
      endif else goto, DIMEN_ERROR
    endif
 endfor

DATATYPE: 

 if not keyword_set( NOTYPE ) then begin

   idltype = im_info[im_info[0]+1]
   datatype = strtrim( fxpar( hdr, 'DATATYPE', Count = N_datatype ))
   if N_datatype GT 0 then begin
     case idltype of

     1: if ( datatype NE 'INTEGER*1' ) then goto, DATATYPE_ERROR
     2: if ( datatype NE 'INTEGER*2' ) and  $
           ( datatype NE 'UNSIGNED*2') then goto, DATATYPE_ERROR
     4: if ( datatype NE 'REAL*4' ) then goto, DATATYPE_ERROR
     3: if ( datatype NE 'INTEGER*4') and  $
           ( datatype NE 'UNSIGNED*4') then goto, DATATYPE_ERROR
     5: if ( datatype NE 'REAL*8' ) then goto, DATATYPE_ERROR
     6: if ( datatype NE 'COMPLEX*8' ) then goto, DATATYPE_ERROR
    12: if ( datatype NE 'UNSIGNED*2') then goto, DATATYPE_ERROR
    13: if ( datatype NE 'UNSIGNED*4') then goto, DATATYPE_ERROR 
    else: begin
           message = 'Image array is non-numeric datatype'
           if  N_elements(ERRMSG) GT 0 then errmsg = message else $
                                        message,'ERROR - ' + message,/CON 
           return 
         end
      endcase
    endif else begin
       if keyword_set(SDAS) then goto, DATATYPE_ERROR
       datatype = ''
    endelse
 
BITPIX:    
  bitpix = fxpar( hdr, 'BITPIX')
  
    case idltype of

     1: if ( bitpix NE 8) then goto, BITPIX_ERROR
     2: if ( bitpix NE 16 ) then goto, BITPIX_ERROR  
     4: begin
        if keyword_set(FITS) and (bitpix NE -32) then goto, BITPIX_ERROR $
        else begin
        if ( abs( bitpix) NE 32 ) then goto, BITPIX_ERROR
        if bitpix EQ 32 then if datatype NE 'REAL*4' then goto, BITPIX_ERROR
        endelse
        end
     3: if bitpix NE 32 then goto, BITPIX_ERROR 
     5: begin
        if keyword_set(FITS) and (bitpix NE -64) then goto, BITPIX_ERROR $
        else begin
        if ( abs( bitpix) NE 64 ) then goto, BITPIX_ERROR
        if bitpix EQ 64 then if datatype NE 'REAL*8' then goto, BITPIX_ERROR
        endelse
        end
     12:if bitpix NE 16 then goto, BITPIX_ERROR
     13: if bitpix NE 32 then goto, BITPIX_ERROR
     else: begin
           if not ( (idltype EQ 6) and (datatype EQ 'COMPLEX*8') ) then  begin
              message = 'Data array is a non-numeric datatype'
             if  N_elements(ERRMSG) GT 0 then errmsg = message else $
                                          message,'ERROR - ' + message,/CON
             return 
           endif
      end

   endcase

 endif

 return

DATATYPE_ERROR:
    if  keyword_set( UPDATE ) then begin

       dtype = ['', 'INTEGER*1', 'INTEGER*2', 'INTEGER*4', 'REAL*4', $
               'REAL*8',  'COMPLEX*8','','','','','','UNSIGNED*2','UNSIGNED*4']
       datatype = dtype[ idltype]
     if not keyword_set(SILENT) then message,/INF, $
        'DATATYPE keyword of '+ datatype + ' added to FITS header'
     fxaddpar, hdr, 'DATATYPE', datatype, $
                     ' FITS/SDAS version of BITPIX', before ='HISTORY'
     goto, BITPIX

   endif else begin
      message = 'Incorrect DATATYPE keyword of ' + datatype
      if  N_elements(ERRMSG) GT 0 then errmsg = message else $
          message,'ERROR - ' + message,/CON
      return
   endelse

BITPIX_ERROR:
    if keyword_set( UPDATE ) then begin
    bpix = [0, 8, 16, 32, -32, -64, 32, 0, 0, 0, 0, 0, 16,32 ]
    if keyword_set(SDAS) then bpix = abs(bpix)
    comm = ['',' Character or unsigned binary integer', $
               ' 16-bit twos complement binary integer', $
               ' 32-bit twos complement binary integer', $
               ' IEEE single precision floating point', $
               ' IEEE double precision floating point', $
               ' 32-bit twos complement binary integer','','','','','', $
               ' 16-bit unsigned binary integer', $
               ' 32-bit unsigned binary integer' ]
    bitpix = bpix[idltype]
    comment = comm[idltype]
    if not keyword_set(SILENT) then message, /INF, $
        'BITPIX value of ' + strtrim(bitpix,2) +  ' added to FITS header'
    fxaddpar, hdr, 'BITPIX', bitpix, comment
    return

  endif else begin 
       message = 'BITPIX value of ' + strtrim(bitpix,2) + $
                 ' in FITS header does not match array'
      if  N_elements(ERRMSG) GT 0  then errmsg = message else  $
          message,'ERROR - ' + message,/CON
      return
 endelse

DIMEN_ERROR:
   if keyword_set( UPDATE ) then begin
        fxaddpar, hdr, 'NAXIS', ndimen, before = 'NAXIS1'
        for i = 1, ndimen do fxaddpar, hdr, 'NAXIS' + strn(i), dimen[i-1], $
                'Number of positions along axis ' + strn(i), $
                after = 'NAXIS' + strn(i-1)          
        if naxi GT ndimen then begin
                for i = ndimen+1, naxi do sxdelpar, hdr, 'NAXIS'+strn(i)
        endif
        if not keyword_set(SILENT) then message, /INF, $
                'NAXIS keywords in FITS header have been updated'
        goto, DATATYPE
   endif

 end
