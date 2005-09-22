pro mrd_hread, unit, header, status, SILENT = silent 
;+
; NAME: 
;     MRD_HREAD
;
; PURPOSE: 
;     Reads a FITS header from an opened disk file or Unix pipe
; EXPLANATION:
;     Like FXHREAD but also works with compressed Unix files
;
; CALLING SEQUENCE: 
;     MRD_HREAD, UNIT, HEADER  [, STATUS, /SILENT ]
; INPUTS: 
;     UNIT    = Logical unit number of an open FITS file
; OUTPUTS: 
;     HEADER  = String array containing the FITS header.
; OPT. OUTPUTS: 
;     STATUS  = Condition code giving the status of the read.  Normally, this
;                 is zero, but is set to -1 if an error occurs, or if the
;                 first byte of the header is zero (ASCII null).
; OPTIONAL KEYWORD INPUT:
;      /SILENT - If set, then warning messages about any invalid characters in
;                the header are suppressed.
; RESTRICTIONS: 
;      The file must already be positioned at the start of the header.  It
;      must be a proper FITS file.
; SIDE EFFECTS: 
;       The file ends by being positioned at the end of the FITS header, unless
;       an error occurs.
; REVISION HISTORY:
;      Written,  Thomas McGlynn                     August 1995
;      Modified, Thomas McGlynn		     January 1996
;         Changed MRD_HREAD to handle Headers which have null characters
;          A warning message is printed out but the program continues.
;          Previously MRD_HREAD would fail if the null characters were
;          not in the last 2880 byte block of the header.  Note that
;          such characters are illegal in the header but frequently
;          are produced by poor FITS writers.
;      Converted to IDL V5.0   W. Landsman   September 1997
;      Added /SILENT keyword   W. Landsman   December 2000
;-
 	block = string(replicate(32b, 80, 36))
		
	header = ' '
	w = [-1]

	while w[0] eq -1 do begin
		
		; Shouldn't get eof in middle of header.
		if eof(unit) then begin
			free_lun, unit
			status = -1
			return
		endif
		
		on_ioerror, error_return
		readu, unit, block
		on_ioerror, null

		; Check that there aren't improper null characters
		; in strings that are causing them to be truncated.
		; Issue a warning but continue if problems are found.
		w = where(strlen(block) ne 80)
		if (w[0] ne -1) then begin
			if not keyword_set(SILENT) then message, /INF, $
                            'Warning-Invalid characters in header'
			block[w] = string(replicate(32b, 80))
		endif
		w = where(strmid(block, 0, 8) eq 'END     ')
		if w[0] eq -1 then begin
			header = [header, block]
		endif else begin
			header = [header, block[0:w[0]]]
		endelse
			
	endwhile
		
	header = header[1:*]
	status = 0
	return
error_return:
        status = -1
	return
end
			
