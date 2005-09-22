pro mrd_skip, unit, nskip
;+
; NAME:
;       MRD_SKIP
; PURPOSE:
;       Skip a number of bytes from the current location in a file or a pipe
; EXPLANATION:
;       First tries using POINT_LUN and if this doesn't work, perhaps because
;       the unit is a pipe, MRD_SKIP will just read in the requisite number 
;       of bytes.    GZIP files opened with /COMPRESS (in V5.3 or later) are
;       also read as a series of bytes, since this is faster than using 
;       POINT_LUN when not at the beginning of a file. 
; CALLING SEQUENCE:
;       MRD_SKIP, Unit, Nskip
;
; INPUTS:
;       Unit - File unit for the file or pipe in question, integer scalar
;       Nskip - Number of bytes to be skipped, positive integer
; NOTES:
;       This routine should be used in place of POINT_LUN wherever a pipe
;       may be the input unit (see the procedure FXPOSIT for an example).  
;       Note that it assumes that it can only work with nskip >= 0 so it 
;       doesn't even try for negative values.      
;
;       For reading a pipe, MRD_SKIP currently uses a maximum buffer size
;       of 8 MB.   This chunk value can be increased for improved efficiency
;       (or decreased if you really have little memory.)
; REVISION HISTORY:
;       Written, Thomas A. McGlynn    July 1995
;	Don't even try to skip bytes on a pipe with POINT_LUN, since this
;	might reset the current pointer     W. Landsman        April 1996
;       Increase buffer size, check fstat.compress W. Landsman  Jan 2001
;       Only a warning if trying read past EOF   W. Landsman   Sep 2001
;-
        On_error,2

	if nskip le 0 then return

; Since V5.4 we can test for the presence of gzip compressed files using the 
; .compress field of fstat(unit).   For Unix compress or earlier IDL versions
; we test whether we can read the current position.    If we can then it is not
; a pipe and we can  go ahead and use POINT_LUN.

        if !VERSION.RELEASE GE '5.4' then compress = (fstat(unit)).compress $
                                     else compress = 0
        if compress EQ 0 then begin 
 	  on_ioerror, byte_read
	  point_lun, -unit, curr_pos
	  on_ioerror, null
          if curr_pos NE -1 then point_lun, unit, curr_pos+nskip
           return
        endif 

; Otherwise, we have to explictly read the number of bytes to skip
; If the number is very large we don't want to create a array so skip
; in chunks of 8 Megabyte

byte_read:
        chunk = 8000000L
	buf = bytarr(nskip<chunk, /nozero)
	nleft = nskip
	on_ioerror, DONE
	while (nleft gt 0) do begin
		readu, unit, buf
		nleft = nleft - chunk
	        if (nleft gt 0 and nleft lt chunk) then begin
		    buf = buf(0:nleft-1)
		endif
	endwhile
	return
DONE:  message,'Warning - Byte padding in FITS file may not be correct',/CON
       return		
end

