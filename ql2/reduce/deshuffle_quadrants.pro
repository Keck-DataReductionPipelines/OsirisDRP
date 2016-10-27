function deshuffle_quadrants , image

;+
; NAME:
; 	DESHUFFLE_QUADRANTS()
; PURPOSE:
; 	remove quadrant shift introduced by KCAM's electronics at
; 	read out.
;
; CALLING SEQUENCE:
;	final = DESHUFFLE_QUADRANTS( IMAGE )
;
; INPUTS:
;	IMAGE -- KCAM image frame 
;
;	final = same image but quadrants re-shuffled, to take into
;		account the fact that the way the electronics are 
;		read out, the quadrants are each offset by one pixel, 
;		they therefore have to be re-ordered for the final 
;		image.
;
; NOTES:
;	There is a debate whether this should be applied to the 
;	reduced data (as is the case right now) or on every frame
;	that comes out of KCam (even calibration files, etc). The
;	reason for the latter is that dead pixel correction (if
;	nearest neighbour interpolation is used) should be done 
;	after this routine is called.
;
; REVISION HISTORY:
;	Written Olivier Lai, CFHT/KECK, October 1999
;-


quad1 = image(0:127,0:127)
quad2 = image(128:255,0:127)
quad3 = image(0:127,128:255)
quad4 = image(128:255,128:255)
nquad1=rotate(reform(shift(reform(rotate(quad1,7),16384),1),128,128),7)
nquad2=rotate(reform(shift(reform(rotate(quad2,7),16384),1),128,128),7)
nquad3=rotate(reform(shift(reform(rotate(quad3,7),16384),1),128,128),7)
nquad4=rotate(reform(shift(reform(rotate(quad4,7),16384),1),128,128),7)
final(0:127,0:127)=nquad1
final(128:255,0:127)=nquad2
final(0:127,128:255)=nquad3
final(128:255,128:255)=nquad4
final(127,*)=shift(final(127,*),-1)


;final(127:128,*)=shift(final(127:128,*),0,2)


return, final

end