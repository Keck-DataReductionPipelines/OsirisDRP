function remove_pattern,image_input,image_filtree,filtering=filtering, $
			silent=silent

;+
; NAME:
; 	REMOVE_PATTERN()
; PURPOSE:
; 	Remove correlated (or periodic) noise from images.
; 	CPU-intensive because of median filtering and FFTs, 
;	but efficient. Calls med_mult_dec.pro
;
; CALLING SEQUENCE:
;	RESULT = REMOVE_PATTERN( IMAGE [ , FILTERED_IMAGE ] , $
;		FILTERING = FILTERING , SILENT = SILENT )
;
; INPUTS:
;	IMAGE  -- image frame containing periodic (or correlated) noise.
;
; OPTIONAL KEYWORDS INPUTS:
; 	FILTERING -- If set (or equal to 1), the multi median filtered
;		     image will be computed and returned in the
;		     FILTERED_IMAGE optionnal variable.
;	SILENT    -- if it's equal to zero or not there, the program
;		     will run quietly. Otherwise, graphic displays 
;		     illustrate the median filtering in image plane and
;		     the sigma clipping in the Fourier Domain.
;
; OUTPUTS:
;	RESULT = The original image corrected from the correlated noise. 
;		 Because it is a linear process the difference of 
;		 RESULT and IMAGE is the actual noise that was removed
;		 from the image. 
;
; OPTIONAL OUTPUTS:
;	FILTERED_IMAGE is a named variable that will contain the 
;	multi median filtered image, if the FILTERING keyword is
;	set. This image is the result of FILT_MULT_MED.PRO and not
;	the low frequency component used to determine the periodic
;	noise.
; NOTES:
;	The procedure is described by Wampler in the ESO 
;	Messenger, december 1992.
;
; PROCEDURE CALLS:
; 	MED_MULT_DEC, FILT_MULT_MED()
;
; REVISION HISTORY:
;	Written Francois Poulet, Paris Observatory, 1995
;-

if not keyword_set(silent) then window,0,xsize=512,ysize=512

image_work=image_input
image_ori=image_input
dima=(size(image_input))(1)
dimb=(size(image_input))(2)

if not keyword_set(silent) then tvscl,image_input,0,dima

;estimation du sigma du bruit

med_mult_dec,image_input,I,J,4
;;on commence par enlever les structures a basse frequence
;; par median multiresolution

image_hf=image_ori-I(*,*,4)
image_work=image_hf

sigma=stdev(image_hf,me_noise)

;;3 sigma clipping
for i=1,5 do begin
    ind_noise=where(abs(image_hf-me_noise) le 3.0*sigma)
                                ;verif=bytarr(dima,dimb)
                                ;verif(ind_noise)=1
                                ;mytv,verif
    sigma=stdev(image_hf(ind_noise),me_noise)
    if not keyword_set(silent) then  print,'new_sigma, moyenne',sigma,me_noise
endfor


;; remplacement des "objets" par une valeur mediane
;; un objet est detecte si il est au dessus de 3sigmas du bruit

ind_det_obj=where(abs(image_hf-me_noise) ge (3.0*sigma))
image_work(ind_det_obj)=me_noise

for i_boucle=1,4 do begin
    if not keyword_set(silent) then  print,'boucle ',i_boucle
    image_work_ft=fft(image_work)
    image_work_ft_re=float(image_work_ft)
    image_work_ft_im=imaginary(image_work_ft)
    if not keyword_set(silent) then begin
        tvscl,image_work_ft_re
        tvscl,image_work_ft_im,dima,0
    endif
    
    ;;3 sigma clipping
    sigma_fl=stdev(image_work_ft_re,me_noise_fl)
    sigma_im=stdev(image_work_ft_im,me_noise_im)
    for i=1,5 do begin
        ind_noise_fl=where(abs(image_work_ft_re) le 3*sigma_fl)
        ind_noise_im=where(abs(image_work_ft_im) le 3*sigma_im)
        sigma_fl=stdev(image_work_ft_re(ind_noise_fl),me_noise_fl)
        sigma_im=stdev(image_work_ft_im(ind_noise_im),me_noise_im)
        if not keyword_set(silent) then   $
          print,'sigmas float et imag',sigma_fl,sigma_im
    endfor
    
    image_work_ft_re( where(abs(image_work_ft_re) le $ 
                            (6-i_boucle)*sigma_fl) )=0.0
    image_work_ft_im( where(abs(image_work_ft_im) le $
                            (6-i_boucle)*sigma_im) )=0.0
    if not keyword_set(silent) then begin
        tvscl,image_work_ft_re
        tvscl,image_work_ft_im,dima,0
    endif
    
    noise_pattern= $ 
      float(dfti(complex(image_work_ft_re,image_work_ft_im)))
    if not keyword_set(silent) then begin
        tvscl,noise_pattern,dima*2,0
	tvscl,image_input-noise_pattern,dima,dimb
    endif
    
;; on masque les objets enleves et on les remplace par les pattern
    
    image_work(ind_det_obj)=noise_pattern(ind_det_obj)
    
endfor

if keyword_set(filtering) eq 1 then $
  image_filtree = filt_mult_med(image_input-noise_pattern)

return,image_input-noise_pattern

end
