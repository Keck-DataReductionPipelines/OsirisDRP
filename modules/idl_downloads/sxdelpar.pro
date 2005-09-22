pro sxdelpar, h, parname
;+
; NAME:
;	SXDELPAR
; PURPOSE:
;	Procedure to delete a keyword parameter(s) from a FITS header
;
; CALLING SEQUENCE:
;	sxdelpar, h, parname
;
; INPUTS:
;	h - FITS or STSDAS header, string array
;	parname - string or string array of keyword name(s) to delete
;
; OUTPUTS:
;	h - updated FITS header, If all lines are deleted from 
;		the header, then h is returned with a value of 0
;
; EXAMPLE:
;	Delete the astrometry keywords CDn_n from a FITS header, h
;
;	IDL> sxdelpar, h, ['CD1_1','CD1_2','CD2_1','CD2_2']
;
; NOTES:
;	(1)  No message is returned if the keyword to be deleted is not found
;	(2)  All appearances of a keyword in the header will be deleted
; HISTORY:
;	version 1  D. Lindler Feb. 1987
;	Converted to new IDL  April 1990 by D. Lindler
;	Test for case where all keywords are deleted    W. Landsman Aug 1995 
;	Converted to IDL V5.0   W. Landsman   September 1997
;------------------------------------------------------------------
 On_error,2

 if N_Params() LT 2 then begin
      print,'Syntax - SXDELPAR, h, parname'
      return
 endif

; convert parameters to string array of upper case names of length 8 char

 s = size(parname) & ndim = s[0] & type = s[ndim+1]

 if type NE 7 then message,'Keyword name(s) must be a string or string array'

 num = N_elements( parname )
 par = strtrim( strupcase(parname),2 ) 

 s = size(h) & ndim = s[0] & type = s[ndim+1]

 if (ndim NE 1) or (type NE 7) then $
	message,'FITS header (1st parameter) must be a string array'

 nlines = s[1]		;number of lines in header array
 pos = 0		;position in compressed header with keywords removed

; loop on header lines

 keyword = strtrim( strmid(h,0,8), 2 )
 for i = 0, nlines-1 do begin
	for j = 0,num-1 do $
              if keyword[i] EQ par[j] then goto, DELETE ;delete it?
	h[pos] = h[i]		;keep it
	pos = pos+1		;increment number of lines kept
	if keyword[i] eq 'END' then goto, DONE   	;end of header
DELETE: 
 endfor

DONE:
 if pos GT 0 then h = h[0:pos-1] else h = 0	      ;truncate

 return
 end
