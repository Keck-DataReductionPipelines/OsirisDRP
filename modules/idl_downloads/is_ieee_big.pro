function is_ieee_big
;+
; NAME:
;	IS_IEEE_BIG
; PURPOSE:
;	Determine if the current machine uses IEEE, big-endian numbers.
; EXPLANATION:
;       (Big endian implies that byteorder XDR conversions are no-ops).
; CALLING SEQUENCE:
;	flag = is_ieee_big()
; INPUT PARAMETERS:
;       None
; RETURNS:
;       1 if the machine appears to be IEEE-compliant, 0 if not.
; COMMON BLOCKS:
;	None.
; SIDE EFFECTS:
;	None
; RESTRICTIONS:
; PROCEDURE:
;       A sample int, long, float and double are converted using
;       byteorder and compared with the original.  If there is no
;       change, the machine is assumed to be IEEE compliant and
;       big-endian.
; MODIFICATION HISTORY:
;       Written 15-April-1996 by T. McGlynn for use in MRDFITS.
;	13-jul-1997	jkf/acc	- added calls to check_math to avoid
;				  underflow messages in V5.0 on Win32 (NT).
;	Converted to IDL V5.0   W. Landsman   September 1997
;-

    itest = 512
    ltest = 102580L
    ftest = 1.23e10
    dtest = 1.23d10
		
		
    it2 = itest
    lt2 = ltest
    ft2 = ftest
    dt2 = dtest
				
    byteorder, it2, /htons
    byteorder, lt2, /htonl
    byteorder, ft2, /ftoxdr
    byteorder, dt2, /dtoxdr

    if itest eq it2  and  ltest eq lt2   and ftest eq ft2  and dtest eq dt2  $
    then begin
    	dum = check_math()
        return, 1
    endif else begin
    	dum = check_math()
        return, 0
    endelse
    end								    
