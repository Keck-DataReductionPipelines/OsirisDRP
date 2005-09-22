;-----------------------------------------------------------------------
; NAME:  sigma_poly_fit
;
; PURPOSE: fit a polynomial iteratively using svdfit
;
; INPUT :  vd_X           : input vector with X coordinates
;          vd_Y           : input vector with Y coordinates
;          vd_W           : input vector with Noise values; currently ignored
;          n_Degree       : degree o polynomial to fit
;          d_LowerSigma   : lower sigma value
;          d_UpperSigma   : upper sigma value
;          n_MaxIter      : maximum number of iterations
;          DEBUG = DEBUG  : initializes the debugging mode
;          INDEX = INDEX  : a named variable that contains 1 if value
;                           is valid after iterative fitting, otherwise 0
;
; ON ERROR : returns 0.
;
; STATUS : untested
;
; HISTORY : 3.11.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

function sigma_poly_fit, vd_X, vd_Y, vd_W, n_Degree, d_LowerSigma, d_UpperSigma, n_MaxIter, DEBUG = DEBUG, INDEX=INDEX

   if ( n_elements(vd_X) ne n_elements(vd_Y) or n_elements(vd_X) ne n_elements(vd_W) ) then $
      return, error('ERROR IN CALL (sigma_poly_fit.pro): Input incompatible in size.')

   vi_Mask     = indgen(n_elements(vd_X))   ; running index of the data values, this is used as x-coord. for fitting
   vb_Mask     = make_array( /INT, n_elements(vd_X), Value=1)   ; is 1 for valid elements, otherwise 0
   vd_Coeff    = 0.                         ; initialize the return value
   vd_CoeffOld = 0.                         ; 
   n_MaskOld   = -1                         ; number of elements used for fitting in the last iteration

   ; break the loop if neccessary
   for i=0, n_MaxIter-1 do begin

      vi_Valid = where ( vb_Mask eq 1 )

      if ( keyword_set (DEBUG) ) then begin
         !p.multi=[0,1,2]
         plot, vd_X, vd_Y, title='White: All Data, Red: Data used in next fit, Green: Fit, Blue Fit+Std, Iter:' + $
               strg(i)
         oploterr, vd_X, vd_Y, vd_W
         wait, DEBUG
      end

      if ( keyword_set (DEBUG) ) then $
         oplot, vd_X(vi_Valid), vd_Y(vi_Valid), psym=1, color=1, symsize=3

      ; do the fit
      vd_CoeffOld = svdfit ( vd_X(vi_Valid), vd_Y(vi_Valid), n_Degree+1, /DOUBLE )

      ; check if fit was successful
      if ( NOT bool_is_defined ( vd_CoeffOld ) ) then break 
      v_Res   = poly ( vd_X, vd_CoeffOld )
      d_Std   = sqrt(total( (v_Res(vi_Valid)-vd_Y(vi_Valid))^2 )/n_elements(v_Res(vi_Valid)))    ; calculate the standard deviation

      vi_Mask = where ( (vd_Y lt v_Res-d_LowerSigma * d_Std or $   ; check where values are invalid for next iteration
                         vd_Y gt v_Res+d_UpperSigma * d_Std    ) or vb_Mask eq 0, n_Mask )

      ; the iteration was successful, store the coefficients in the return variable
      vd_Coeff = vd_CoeffOld

      if ( keyword_set (DEBUG) ) then begin
         vd_All = poly ( vd_X, vd_CoeffOld )
         oplot, vd_X, vd_All, color=2, symsize=3
         oplot, vd_X, vd_All-d_LowerSigma * d_Std, color=3
         oplot, vd_X, vd_All+d_LowerSigma * d_Std, color=3

         plot, vd_X, (vd_All-vd_Y)*10000., psym=2, /yst, title='Residual of all lines after fit in Angstroem'

         wait, DEBUG
         !p.multi=[0,1,0]

      end

      if ( total(vb_Mask) lt n_Degree+1 ) then begin
        if ( keyword_set ( DEBUG ) ) then $
        debug_info, 'DEBUG INFO (sigma_poly_fit.pro): Too few points to fit left.'
        break
      end

      if ( n_Mask eq 0 ) then begin
        if ( keyword_set ( DEBUG ) ) then $
        debug_info, 'DEBUG INFO (sigma_poly_fit.pro): No more points outside.'
        break
      end

      vb_Mask(vi_Mask) = 0 

   end

   if ( keyword_set ( INDEX ) ) then INDEX = vb_Mask

   return, vd_Coeff

end
