

;-----------------------------------------------------------------------
; NAME:  shift_image
;
; PURPOSE: Shift image on subpixel basis. 
;
; INPUT :  mf_D            : input data image
;          mf_N            : input noise image
;          mb_Q            : input quality image
;          d_x             : 0 <= shift in x-direction < 1 (not checked)
;          d_y             : 0 <= shift in y-direction < 1 (not checked)
;
; OUTPUT : returns a structure with the shifted frames
;
; NOTES : - since the shift is fractional, the output arrays have the
;           same size as the input arrays
;         - the input images must have same dimension (not checked)
;         - qbit 0 must be set correctly. The decission whether a
;           pixel is valid or not is solely based on that bit. 
;         - a pixel at coordinate x,y is shifted to x+dx,y+dy (tested,
;           19.8.2006, CI)
;
; STATUS : tested
;
; HISTORY : 11.9.2005, created
;           19.8.2006, tested
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

function shift_image, mf_D, mf_N, mb_Q, d_x, d_y

   functionName = 'shift_image.pro'

   if ( abs ( d_x ) lt 0.01 and abs ( d_y ) lt 0.01 ) then $
      return, {mf_D:mf_D, mf_N:mf_N, mb_Q:mb_Q }

   if ( abs(d_x) gt 1. or abs(d_y) gt 1. ) then $
      warning, 'WARNING (' + functionName + '): Shifts are greater than 1.'

   mf_D = reform(mf_D)
   mf_N = reform(mf_N)
   mb_Q = reform(mb_Q)

   ; the shifted images
   mf_DS = make_array ( SIZE=size(mf_D), /FLOAT, VALUE=0. )
   mf_NS = make_array ( SIZE=size(mf_N), /FLOAT, VALUE=0. )
   mb_QS = make_array ( SIZE=size(mb_Q), /BYTE, VALUE=9b )

   ; calculate the new grid points
   vd_X = dindgen( (size(mf_D))(1) ) - d_x
   vd_Y = dindgen( (size(mf_D))(2) ) - d_y

   ; ---- Now determine the shifted frames and other quality bits

   ; find the valid (qbit 0 = 1) pixels
   ; Reminder : Pixels have qbit 0 = 0 if :
   ;            - data or noise not finite
   ;            - noise negative
   ;            - outside
   mi_Valid = extbit ( mb_Q, 0 )
   dummy    = where ( mi_Valid, n_Valid )

   ; if there are no valid pixel the interpolation status will be lost

   if ( n_Valid gt 0 ) then begin

      ; there are valid pixel in the slice

      ; shift both frames bilinearly
      ; The MISSING value is the value to return for elements outside the bounds of the input
      mf_DS = interpolate ( mf_D, vd_X, vd_Y, /grid, MISSING=0.0 )
      mf_NS = interpolate ( mf_N, vd_X, vd_Y, /grid, MISSING=0.0  )

      ; determine the valid bit
      mi_VS = interpolate ( float(mi_Valid), vd_X, vd_Y, /grid, MISSING = 0  )
      v = where ( finite(mi_VS,/NAN) or mi_VS ne 1., n ) ; these ones are not valid for sure
      if ( n gt 0 ) then begin
         mb_QS(v) = setbit(mb_QS(v),0,0)
;         mf_DS(v) = 0.
;         mf_NS(v) = 0.
      end
      ; determine the inside bit
      mi_Out = interpolate ( float(extbit(mb_Q,3)), vd_X, vd_Y, /grid, MISSING = 0  )
      v = where ( finite(mi_Out,/NAN) or mi_Out ne 1., n ) ; these ones are definitely outside
      if ( n gt 0 ) then begin
         mb_QS(v) = setbit(mb_QS(v),3,0)
;         mf_DS(v) = 0.
;         mf_NS(v) = 0.
      end

      vi_Valid = where ( extbit ( mb_QS, 0 ), n_Valid )

      if ( n_Valid gt 0 ) then begin

         ; The Interpolation Map contains for valid (qbit 0 = 1 ) well interpolated pixel 1 and
         ; for bad interpolated pixel 2
         mf_I = float ( mi_Valid  * ( $                    ; these are the valid pixel
                extbit ( mb_Q, 1 ) + $                     ; these are the interpolated pixel
                ( extbit ( mb_Q, 1 ) and $                 ; these are the bad interpolated pixel
                  bool_invert( extbit ( mb_Q, 2 ) ) ) ) )

         ; Now shift the Interpolation Map
         mf_IS = interpolate ( mf_I, vd_X, vd_Y, /grid )

         ; where the shifted interpolation map is greater than 1/2 the shifted
         ; pixel is regarded as interpolated. If it is greater than
         ; 1 it is badly interpolated
         v_MaskInt = where ( mf_IS(vi_Valid) gt 0.5, n_Int )
         if ( n_Int gt 0 ) then begin
            mb_QS(vi_Valid(v_MaskInt)) = setbit ( mb_QS(vi_Valid(v_MaskInt)), 1, 1 )
            mb_QS(vi_Valid(v_MaskInt)) = setbit ( mb_QS(vi_Valid(v_MaskInt)), 2, 1 )
         end
         v_MaskBadInt = where ( mf_IS(vi_Valid) gt 1., n_BadInt )
         if ( n_BadInt gt 0 ) then $
            mb_QS(vi_Valid(v_MaskBadInt)) = setbit ( mb_QS(vi_Valid(v_MaskBadInt)), 2, 0 )

      endif else $
         info, 'INFO (' + functionName + '): No valid pixel in image after shift '

   endif else $
      info, 'INFO (' + functionName + '): No valid pixel in image before shift '

   ; a last check: are all values finite and are the bits correctly set
   v_0 = extbit ( mb_QS, 0 )
   v_1 = extbit ( mb_QS, 1 )
   v_2 = extbit ( mb_QS, 2 )
   v_3 = extbit ( mb_QS, 3 )

   v = where ( v_0 and v_3 eq 0, n )
   if ( n gt 0 ) then begin
      warning, 'WARNING (' + functionName + '): Whoopsie daisy, ' + strg(n) + $
               ' pixels have valid status but are outside. Correcting.'
      mb_QS(v) = setbit ( mb_QS(v), 0, 0)
   end

   v = where ( ( v_1 or v_2 ) and v_0 eq 0, n )
   if ( n gt 0 ) then begin
      warning, 'WARNING (' + functionName + '): Whoopsie daisy, ' + strg(n) + $
               ' pixels have interpolated status but are not valid. Correcting.'
      mb_QS(v) = setbit ( mb_QS(v), 1, 0)
      mb_QS(v) = setbit ( mb_QS(v), 2, 0)
   end

   v = where ( finite(mf_DS,/NAN) or finite(mf_NS,/NAN), n )
   if ( n gt 0 ) then begin
;      warning, 'WARNING (' + functionName + '): Whoopsie daisy, ' + strg(n) + $
 ;              ' data or noise values are not finite. Correcting.'
      mb_QS(v) = setbit ( mb_QS(v), 0, 0)
 ;     mf_DS(v) = 0.
 ;     mf_NS(v) = 0.
   end

   ; all done

   return, {mf_D:mf_DS, mf_N:mf_NS, mb_Q:mb_QS }

end
