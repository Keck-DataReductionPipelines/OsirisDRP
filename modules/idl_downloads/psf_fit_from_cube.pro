
; INPUT : PSF    : 'GAUSS', 'LORENTZIAN', 'MOFFAT'
;
; RETURNS : the PSF fit parameter
;
;

function psf_fit_from_cube, pcf_Frame, pcf_IntFrame, pcb_IntAuxFrame, $
                               d_Spec_Channels, k_ImgMode, PSF, DEBUG=DEBUG

   COMMON APP_CONSTANTS

   ; Collapse cube. img_cube2image returns a struct on success
   s_Image = img_cube2image ( pcf_Frame, pcf_IntFrame, pcb_IntAuxFrame, d_Spec_Channels, k_ImgMode, $
                              DEBUG = 0 ) 

   if ( NOT bool_is_struct ( s_Image ) ) then $
      return, error ( 'FAILURE (psf_fit_from_cube.pro): Cube collapsing failed.' )

   mf_Image  = s_Image.md_Image 
   md_Weight = s_Image.md_Weight   ; these are already the 1/Noise^2 values

   ; do the PSF fit
   mf_PSF = mpfit2dpeak ( mf_Image, v_FitBGRes, WEIGHTS=md_Weight, /TILT, $
                          GAUSS      = PSF eq 'GAUSS', $
                          LORENTZIAN = PSF eq 'LORENTZIAN', $
                          MOFFAT     = PSF eq 'MOFFAT' )

   if ( keyword_set ( DEBUG ) ) then begin
      d_ChiS = sqrt(total( (mf_PSF - mf_Image)^2 ))
      debug_info, 'DEBUG INFO (psf_fit.pro): PSF parameters: '
      debug_info, 'DEBUG INFO (psf_fit.pro): offset: '+strg(v_FitBGRes(0))
      debug_info, 'DEBUG INFO (psf_fit.pro): scale : '+strg(v_FitBGRes(1))
      debug_info, 'DEBUG INFO (psf_fit.pro): fwhmx : '+strg(v_FitBGRes(2))
      debug_info, 'DEBUG INFO (psf_fit.pro): fwhmy : '+strg(v_FitBGRes(3))
      debug_info, 'DEBUG INFO (psf_fit.pro): cx    : '+strg(v_FitBGRes(4))
      debug_info, 'DEBUG INFO (psf_fit.pro): cy    : '+strg(v_FitBGRes(5))
      if ( n_elements(v_FitBGRes) eq 7 ) then $
         debug_info, 'DEBUG INFO (psf_fit.pro): tilt  : '+strg(v_FitBGRes(6))
      if ( n_elements(v_FitBGRes) eq 8 ) then $
         debug_info, 'DEBUG INFO (psf_fit.pro): damp  : '+strg(v_FitBGRes(7))
      debug_info, 'DEBUG INFO (psf_fit.pro): ChiSquare is '+ strg(d_ChiS)
   end
   
   return, { Param : v_FitBGRes, Image : mf_PSF }

end

