function reduce_algorithm,object,sky,flat,deadpix_map, $
	 remove_pattern_flag=remove_pattern_flag


;+
; NAME:
; 	REDUCE_ALGORITHM()
; PURPOSE:
; 	Reduce standard near IR images.
; 	calls remove_pattern.pro and deadpixcor.pro
;
; CALLING SEQUENCE:
;	final = REDUCE_ALGORITHM( OBJECT , SKY , FLAT , DEADPIX_MAP , $
;		REMOVE_PATTERN_FLAG = REMOVE_PATTERN_FLAG )
;
; INPUTS:
;	OBJECT -- image frame containing object
;	SKY    -- image frame of sky
;	FLAT   -- Flat-field image at the correct wavelength
;	DEADPIX_MAP -- map of dead pixels (1 = dead pixel, 
;					   0 = good pixel)
;
; OPTIONAL KEYWORDS INPUTS:
; 	REMOVE_PATTERN_FLAG -- 0 for no correlated noise removal
;			    -- 1 for correlated noise removal
;
; OUTPUTS:
;	final = reduced image: sky and  flat-field corrected, if available 
; 		dead pixels corrected and quadrants re-shuffled for KCAM.
;		correlated noise removed (if option set), and sigma filtered
;		with a 3x3 box and 4 sigma cuts.
;
; NOTES:
;	Standard infrared data reduction
;
; PROCEDURE CALLS:
; 	DEADPIXCOR(), REMOVE_PATTERN(), SIGMA_FILTER(), ROTATE(), REFORM()
;
; REVISION HISTORY:
;	Written Olivier Lai, CFHT/KECK, October 1999
;-

final=(object-sky)/flat
final=deadpixcor(final,deadpix_map,/silent)

if keyword_set(remove_pattern_flag) then begin
    final=remove_pattern(final,/silent)
endif
final=sigma_filter(final,3,n_sigma=4,/all,/monitor)

return, final


end
