pro med_mult_dec,image,I,J,nniveaux

;+
; NAME:
; 	MED_MULT_DEC
; PURPOSE:
; 	Multpiple scale median filtering: The image is separated into
;	two channels, one is smooth, low frequency, and the other is 
; 	details and high frquency. Note that because of the iterative
;	scheme, the original image is NOT the sum of the two channels.
;
; CALLING SEQUENCE:
;	MED_MULT_DEC, IMAGE , LOW_FREQ , HIGH_FREQ , N_LEVELS
;
; INPUTS:
;	IMAGE     -- 2D raw image with periodic noise
;	N_LEVELS  -- number of iterations to carry out the
;		     multi level filtering. Note that the size of
;		     kernel is (2*N_LEVELS + 1)
;
; OUTPUTS:
;	LOW_FREQ  -- cube containing images of the respective 
;		     iterations of the low frequency component of 
;		     the input.
;	HIGH_FREQ -- cube containing images of the respective 
;		     iterations of the high frequency component of 
;		     the input.
;
; NOTES:
;	The useful output of the entire procedure is 
;	LOW_FREQ(*,*,N_LEVELS - 1). The correlated noise will be
; 	in IMAGE - LOW_FREQ(*,*,N_LEVELS - 1).
;
; REVISION HISTORY:
;	Written Francois Poulet, Paris Observatory, 1995
;-


dima=(size(image))(1)
dimb=(size(image))(2)
I=fltarr(dima,dimb,nniveaux+1)
J=fltarr(dima,dimb,nniveaux+1)

imalis_old=image
I(*,*,0)=image
for ii=1,nniveaux do begin
    
    imalis_new=median(imalis_old,2*ii+1)
    I(*,*,ii)=imalis_new
    J(*,*,ii)=imalis_old-imalis_new
    imalis_old=imalis_new
endfor
end
