pro fits_help,file_or_fcb
;+
; NAME:
;	FITS_HELP
;
;*PURPOSE:
;	To print a summary of the primary data units and extensions in a
;	FITS file.
;
;*CATEGORY:
;	INPUT/OUTPUT
;
;*CALLING SEQUENCE:
;	FITS_HELP,filename_or_fcb
;
;*INPUTS:
;	FILENAME_OR_FCB - name of the fits file or the FITS Control Block (FCB)
;		returned by FITS_OPEN.
;
;*OUTPUTS:
;	a summary of the fits file is printed.	
;
;*EXAMPLES:
;	FITS_HELP,'myfile.fits'
;
;	FITS_OPEN,'anotherfile.fits',fcb
;	FITS_HELP,fcb
;
;*PROCEDURES USED:
;	FITS_OPEN, FITS_CLOSE
;*HISTORY:
;	Written by:	D. Lindler	August, 1995
;	Converted to IDL V5.0   W. Landsman   September 1997
;-
;-----------------------------------------------------------------------------
;
; print calling sequence
;
	if n_params(0) eq 0 then begin
	  print,'Syntax -  FITS_HELP,file_or_fcb'
	  return
	endif
;
; Open file if file name is supplied
;
        s = size(file_or_fcb) & fcbtype = s[s[0]+1]
        fcbsize = n_elements(file_or_fcb)
        if (fcbsize ne 1) or ((fcbtype ne 7) and (fcbtype ne 8)) then begin
                print, 'FITS_HELP: Invalid Filename or FCB supplied'
		retall
        end

        if fcbtype eq 7 then fits_open,file_or_fcb,fcb $
	                else fcb = file_or_fcb
;
; print headings
;
	print,' '
	print,FCB.FILENAME
	print,' '
	print,'     XTENSION  EXTNAME  EXTVER EXTLEVEL BITPIX GCOUNT ' + $
			'PCOUNT NAXIS  NAXIS*'
	print,' '
;
; loop on extensions
;
	for i=0,fcb.nextend do begin
		st = string(i,'(I4)')
;
; xtension, extname, extver, extlevel (except for i=0)
;
		if i gt 0 then begin
			t = fcb.xtension[i]
			while strlen(t) lt 8 do t = t + ' '
			st = st + ' '+ strmid(t,0,8)
			t = fcb.extname[i]
			while strlen(t) lt 10 do t = t + ' '
			st = st + ' '+ strmid(t,0,10)
			t = fcb.extver[i]
			if t eq 0 then st = st + '     ' $
				  else st = st + string(t,'(I5)')
			t = fcb.extlevel[i]
			if t eq 0 then st = st + '        ' $
				  else st = st + string(t,'(I8)')
		end else st = st + '                                 '
;
; bitpix, gcount, pcount, naxis
;
		st = st + string(fcb.bitpix[i],'(I6)')
		st = st + string(fcb.gcount[i],'(I7)')
		st = st + string(fcb.pcount[i],'(I7)')
		st = st + string(fcb.naxis[i],'(I6)')
;
; naxis*
;
		st = st + '  '
		if fcb.naxis[i] gt 0 then begin
		    for k=0,fcb.naxis[i]-1 do begin
			if k gt 0 then st = st + ' x '
			st = st + strtrim(fcb.axis[k,i],2)
		    end
		end
;
; print the info
;
		print,st
	end
        if fcbtype eq 7 then fits_close,fcb
return
end
