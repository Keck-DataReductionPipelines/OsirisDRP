function filt_mult_med,image

;+
; NAME:
; 	FILT_MULT_MED()
; PURPOSE:
; 	Multpiple scale median filtering: The  noise is removed
;	from the image, and the image is multi median scale fitlered
;	using MED_MULT_DEC.PRO. Points where data is not available
;	(i.e. too noisy) are filled with the standard idl DILATE() 
;	function. 
;
;
; CALLING SEQUENCE:
;	RESULT = FILT_MULT_MED( IMAGE )
;
; INPUT:
;	IMAGE   -- 2D raw image 
;
; OUTPUTS:
;	RESULT  -- Multi scale median filtered image.
;
; NOTES:
;	The differences between this image and the result of
;	MED_MULT_DEC() are that noise ( > 3 sigma) is filtered 
;	out of this image and the high frequency channel also
;	added to the low frequncy channel, so that details are not
;	lost.
;
; REVISION HISTORY:
;	Written Francois Poulet, Paris Observatory, 1995
;-

dima=(size(image))(1)
dimb=(size(image))(2)

multi_supp=bytarr(dima,dimb,5)
elem_struc=[[0,1,0],[1,1,1],[0,1,0]]
sigb_w=fltarr(5)

sigma=stdev(image,me_noise)

;;3 sigma clipping --> estimation du sigma du bruit

for i=1,5 do begin
 ind_noise=where(abs(image-me_noise) le 3.0*sigma)
 sigma=stdev(image(ind_noise),me_noise)
 print,'new_sigma, moyenne',sigma,me_noise
endfor

nsig=3.0
sigb_w(1)=sigma*0.95
sigb_w(2)=sigma*0.31
sigb_w(3)=sigma*0.125
sigb_w(4)=sigma*0.067

med_mult_dec,image,Itab,Jtab,4

for i_sup=1,4 do begin
  toto=bytarr(dima,dimb)
  toto(where(abs(Jtab(*,*,i_sup)) gt nsig*sigb_w(i_sup)))=byte(1)
  multi_supp(*,*,i_sup)=toto
  multi_supp(*,*,i_sup)=dilate(multi_supp(*,*,i_sup),elem_struc)
endfor

for i_sup=1,4 do begin
Jtab(*,*,i_sup)=Jtab(*,*,i_sup)*multi_supp(*,*,i_sup)
endfor
image_filtree=(Itab(*,*,4)+total(Jtab,3))>0
                                          
return,image_filtree
end
