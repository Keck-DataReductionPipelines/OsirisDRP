;------------------------------------------------------------------
;
; NAME : extr_horne_1
;
; PURPOSE : horne extractions scheme
;
; INPUT :  pmf_SliceFrame       : pointer to frame slice
;          pmf_SliceIntFrame    : pointer to intframe slice (noise,
;                                 not noise^2 or 1/noise^2)
;          pmb_SliceIntAuxFrame : pointer to intauxframe slice
;          s_ImgMode            : 'MED' : pixel in the collapsed image is the median value
;                                         of the spectra
;                                 'AVRG': pixel in the collapsed image is the mean value
;                                         of the spectra     
;                                 'SUM' : pixel in the collapsed image is the sum
;                                         of the spectra
;          s_PSFMode            : 'GAUSS' or 'LORENTZIAN' or 'MOFFAT', form
;                                 of the PSF
;          d_FWHMMultiplier     : extraction radius = d_FWHMMultiplier *
;                                 max(FWHM of PSF)
;          OPT                  : number of sigmas for clipping
;          n_Iter               : running number of iterations, set to
;                                 0 when called first
;          [/DEBUG]             : initializes the debugging mode,
;                                 plots the fitted PSF at the position
;                                 of the center as a y-slice (red),
;                                 frame values and OPT*intframe values
;                                 as error bars (white)
;                                 and extraction radius (green)(initialize
;                                 atv first to get the colors). 
;
; ALGORITHM : see Horne, 1986 PASP 98:609.
;
; NOTES : 
;--------------------------------------------------------------------

function extr_horne_1, pmf_SliceFrame, pmf_SliceIntFrame, pmb_SliceIntAuxFrame, $
                       s_ImgMode, s_PSFMode, d_FWHMMultiplier, OPT, n_Iter, DEBUG=DEBUG

   COMMON APP_CONSTANTS

   n_Dims = size(*pmf_SliceFrame)

   ; calculate P
   s_PSF = psf_fit_from_cube( pmf_SliceFrame, pmf_SliceIntFrame, pmb_SliceIntAuxFrame, $
                              1., s_ImgMode, s_PSFMode, DEBUG=DEBUG )
   if ( NOT bool_is_struct( s_PSF ) ) then $
      error, 'FAILURE (extr_stellar_spec.pro): PSF fit failed.'

   if ( s_PSF.Param(4) lt 0 or s_PSF.Param(4) ge n_Dims(2)-1 or $
        s_PSF.Param(5) lt 0 or s_PSF.Param(5) ge n_Dims(3)-1 ) then return, 0.

   ; calculate extraction radius
   d_Radius    = d_FWHMMultiplier * ( s_PSF.Param(2) > s_PSF.Param(3) ) 
   ; calculate extraction mask
   d_Radius    = d_Radius + sqrt((s_PSF.Param(4)-round(s_PSF.Param(4)))^2 + (s_PSF.Param(5)-round(s_PSF.Param(5)))^2)
   mb_StarMask = img_aperture( n_Dims(2), n_Dims(3), s_PSF.Param(4), s_PSF.Param(5), d_Radius, /NOSUB )
   mb_StarMask = byte(bool_invert(mb_StarMask))

   ; search where valid
   mb_Valid  = valid ( reform(*pmf_SliceFrame), reform(*pmf_SliceIntFrame), reform(*pmb_SliceIntAuxFrame) ) and mb_StarMask
   v_OptMask = where ( mb_Valid, n_Valid )

   if ( n_Valid gt 0 ) then begin

      ; some pixel within the extraction radius are valid
      P            = dindgen(n_Dims(2),n_Dims(3))*0.d
      P(v_OptMask) = s_PSF.Image(v_OptMask)
      f            = total(P)
      P            = P / f

      ; step 4 of Horne's scheme
      V            = fltarr(n_Dims(2),n_Dims(3))
      V(v_OptMask) = (reform(*pmf_SliceIntFrame))(v_OptMask)^2

      if ( keyword_set(DEBUG) ) then begin
         !p.multi=[0,1,0]
         plot, (reform(*pmf_SliceFrame))(*,round(s_PSF.Param(5))),psym=2,$
            title='Iteration '+strg(n_Iter)+' Row '+strg(round(s_PSF.Param(5)))
         oploterr, (reform(*pmf_SliceFrame))(*,round(s_PSF.Param(5))),(OPT*sqrt(V))(*,round(s_PSF.Param(5))),2
         oplot, f*P(*,round(s_PSF.Param(5))),color=1,psym=2
         plots,[round(s_PSF.Param(4))-d_Radius,round(s_PSF.Param(4))-d_Radius],[!y.crange(0),!y.crange(1)], color=2
         plots,[round(s_PSF.Param(4))+d_Radius,round(s_PSF.Param(4))+d_Radius],[!y.crange(0),!y.crange(1)], color=2
         empty
      end

      ; step 7 of Horne's scheme
      v_Diff      = ((reform((*pmf_SliceFrame)))(v_OptMask) - f*P(v_OptMask))^2
      vi_ClipMask = where( v_Diff gt OPT^2*V(v_OptMask), n_Clip) 

      if ( n_Clip gt 0 ) then begin
         ; some pixel are clipped
         ; set the clipped pixel to invalid
         (*pmb_SliceIntAuxFrame)(v_OptMask(vi_ClipMask)) = 0b
         n_Iter = n_Iter + 1
         ; call the routine again (iterate)
         s_Res = extr_horne_1 ( pmf_SliceFrame, pmf_SliceIntFrame, pmb_SliceIntAuxFrame, $
                                s_ImgMode, s_PSFMode, d_FWHMMultiplier, OPT, n_Iter, DEBUG=keyword_Set(DEBUG) )

      end else begin

         ; step 8 of Horne's scheme
         d_Denom    = total( P(v_OptMask)*P(v_OptMask)/V(v_OptMask) )
         d_Frame    = total( P(v_OptMask)*(reform((*pmf_SliceFrame)))(v_OptMask)/V(v_OptMask) ) / d_Denom
         d_IntFrame = total( P(v_OptMask) ) / d_Denom

         return, { Frame:d_Frame, IntFrame:d_IntFrame, N:n_Valid}

      end

  endif else return, 0.

  return, s_Res

end



