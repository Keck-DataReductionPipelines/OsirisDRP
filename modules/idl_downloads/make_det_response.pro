;-------------------------------------------------------------------------
; NAME: polynomial
;
; PURPOSE: helper function for svdfit in make_det_response.pro
;
; STATUS : untested
;
; HISTORY : 9.9.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-------------------------------------------------------------------------
function polynomial, X, m
   RETURN,[ [X], [X^2], [X^3], [X^4], [X^5] ]
end



;-------------------------------------------------------------------------
; NAME: make_det_response
;
; PURPOSE: compute coefficients for detector linearization
;
; INPUT : p_Frames           : pointer or pointerarray with the frames
;         nFrames            : number of input dataset pointers
;         [\DEBUG]           : initialize the debugging mode
;
; OUTPUT : Cube with 14 slices.
;           Slice
;           0      : Maximum value of the response curve (float)
;           1      : Number of slice with maximum (byte)
;           2      : linear fit coefficient of all data points (float)
;           3      : good pixel have positive slope (1b), (0b) else
;           4-8    : Coefficients of the polynomial fit of order 5 (y=a+bx+...+f*x^5)
;           9      : Chi squared goodness-of-fit
;           10-13  : Coefficients 1-5 divided by (coefficient 0)^(1-5)
;
;
; ALGORITHM :
;
; NOTES : - Input to this modules are flatfiled images of increasing
;           integration times.
;         - The data in the dataset pointer array is rearranged.
;           The 0th pointer contains a cube with all individual frames
;           stacked. All other data pointers are deleted.
;         - the quality frame is ignored
;
; OUTPUT : returns an integer vector of same length as nFrames with
;          the numer of successfully linearized pixel in each frame.
;
; ON ERROR : returns ERR_UNKNOWN
;
; STATUS : untested
;
; HISTORY : 9.9.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-------------------------------------------------------------------------

function make_det_response, p_Frames, p_Headers, nFrames, DEBUG=DEBUG

   COMMON APP_CONSTANTS

   if ( nFrames gt 255 ) then return, ERR_UNKNOWN

   n_Dims = size ( *p_Frames(0) )
 
   if ( keyword_set ( DEBUG ) ) then $
      debug_info, 'DEBUG INFO (make_det_response.pro): Getting integration times.'

   ; get the integration times
   vf_IntTimes = fltarr(nFrames)
   for i=0, nFrames-1 do $
      vf_IntTimes(i) = sxpar ( *p_Headers(i), 'INTTIME' )

   ; check if an integration time occurs twice
   vf_IntTmp = vf_IntTimes( sort ( vf_IntTimes ) )
   for i=0, nFrames-2 do $
      if ( vf_IntTmp(i) eq vf_IntTmp(i+1) ) then $
         return, error ('ERROR IN CALL (make_det_response.pro): Integration time occurs twice or more.')

   ; normalize the integration times
   vf_IntTimes = vf_IntTimes / max ( vf_IntTimes )

   if ( keyword_set ( DEBUG ) ) then $
      debug_info, 'DEBUG INFO (make_det_response.pro): Finding the saturation level.'

   ; find the maximum value of a pixel and the index
   vi_Mask = make_array ( /FLOAT, SIZE=n_Dims )
   mf_Max  = *p_Frames(0)
   mb_Max  = make_array( /BYTE, SIZE = n_Dims )
   for i=1, nFrames-1 do begin
      vi_Max = where ( *p_Frames(i) gt mf_Max, n_NewMax )
      if ( n_NewMax gt 0 ) then begin
         mf_Max(vi_Max) = (*p_Frames(i))(vi_Max)
         mb_Max(vi_Max) = byte(i)
      end
   end
   vi_Max = where ( fix(mb_Max) eq nFrames-1, n_Max )
   if ( n_Max gt 0 ) then $
      mb_Max(vi_Max) = temporary(fix(mb_Max(vi_Max))) - 1

   if ( keyword_set ( DEBUG ) ) then $
      debug_info, 'DEBUG INFO (make_det_response.pro): Fitting linear relation.'

   ; fit linear part from subset 3 to mb_Max
   mf_XY = make_array( /FLOAT, SIZE=n_Dims )
   f_XX  = make_array( /FLOAT, SIZE=n_Dims )
   for i=2, nFrames-1 do begin
      f_XX  = temporary(f_XX) + vf_IntTimes(i)^2
      mf_XY = temporary(mf_XY) + vf_IntTimes(i) * (*p_Frames(i))
   end
   ; the linear coefficients of a fit of the form y = ax
   mf_Linear = mf_XY/f_XX

   if ( keyword_set ( DEBUG ) ) then $
      debug_info, 'DEBUG INFO (make_det_response.pro): Checking for negative slopes.'

   ; bad pixels are pixels with a le 0
   mb_Valid  = make_array( /BYTE, SIZE=n_Dims ) + 1b
   vi_MaskBad = where ( mf_Linear le 0., n_Bad ) 
   if ( n_Bad gt 0 ) then $
      mb_Valid(vi_MaskBad) = 0b

   if ( keyword_set ( DEBUG ) ) then $
      debug_info, 'DEBUG INFO (make_det_response.pro): Rearranging memory.'

   ; rearrange memory to get a cube to grant faster access
   ; and delete everything else
   p_Y  = ptr_new(/allocate_heap)
   *p_Y = *p_Frames(0)

   tempPtr  = PTR_NEW(/ALLOCATE_HEAP)	; Create a new, temporary, pointer variable
   *tempPtr = *p_Frames[0]		; Use it to save a pointer to the old data
   PTR_FREE, tempPtr			; Free the old data using the temporary pointer

   tempPtr  = PTR_NEW(/ALLOCATE_HEAP)	; Create a new, temporary, pointer variable
   *tempPtr = *p_Headers[0]		; Use it to save a pointer to the old data
   PTR_FREE, tempPtr			; Free the old data using the temporary pointer

   for i=1, nFrames-1 do begin

      *p_Y = [ [[*p_Y]], [[*p_Frames(i)]] ]

      tempPtr = PTR_NEW(/ALLOCATE_HEAP)	; Create a new, temporary, pointer variable
      *tempPtr = *p_Frames[i]		; Use it to save a pointer to the old data
      PTR_FREE, tempPtr			; Free the old data using the temporary pointer

      tempPtr = PTR_NEW(/ALLOCATE_HEAP)	
      *tempPtr = *p_Headers[i]	
      PTR_FREE, tempPtr			

   endfor

   ; now fit the polynomial

   ; create memory for the results
   mf_CoeffsPoly     = fltarr(n_Dims(1),n_Dims(2),5)
   mf_Chi2           = fltarr(n_Dims(1),n_Dims(2))
   mf_CoeffsPolyNorm = fltarr(n_Dims(1),n_Dims(2),4)

   if ( keyword_set ( DEBUG ) ) then $
      debug_info, 'DEBUG INFO (make_det_response.pro): Looping over the pixel.'

   ; loop over the pixel
   for i=0, n_Dims(1)-1 do begin

      if ( ((i+1) mod ((n_Dims(1)/20)>1) ) eq 0 ) then $
         info,'INFO (make_Det_response.pro): '+ strg(fix(float(i+1)*100./n_Dims(1)))+$
              '% of the linearization coefficients determined.'

      for j=0, n_Dims(2)-1 do begin

         if ( mb_Valid(i,j) ) then begin   
            ; do the polynomial fit only if the pixel is valid
            vf_FirstGuess = [1.,0.,0.,0.,0.]

            v_Res = SVDFIT( vf_IntTimes, reform((*p_Y)(i,j,*)), A=vf_FirstGuess, $
                            FUNCTION_NAME='polynomial', SIGMA=vf_Sigma, CHISQ = f_Chi2, YFIT=v_Fit)

            if ( keyword_set (DEBUG) ) then begin
               plot, vf_IntTimes, reform((*p_Y)(i,j,*)), psym=2, title='Pixel '+strg(i)+','+strg(j)
               oplot, vf_IntTimes, v_Fit
               oplot, vf_IntTimes, v_Fit
            end

            ; check that the fit produced a monotonically raising function
            if ( total( v_Fit gt v_Fit[1:(fix(mb_Max(i,j))-1)>1] ) eq 0 and v_Res(0) gt 0.) then begin
               mf_CoeffsPoly(i,j,0:4)   = v_Res
               mf_Chi2(i,j)             = f_Chi2
               mf_CoeffsPolyNorm(i,j,0) = mf_CoeffsPoly(i,j,1)/mf_CoeffsPoly(i,j,0)^2
               mf_CoeffsPolyNorm(i,j,1) = mf_CoeffsPoly(i,j,2)/mf_CoeffsPoly(i,j,0)^3
               mf_CoeffsPolyNorm(i,j,2) = mf_CoeffsPoly(i,j,3)/mf_CoeffsPoly(i,j,0)^4
               mf_CoeffsPolyNorm(i,j,3) = mf_CoeffsPoly(i,j,4)/mf_CoeffsPoly(i,j,0)^5
            endif else begin
               mb_Valid(i,j) = 0b
               info,'INFO (make_det_response.pro): Solution not monotonically raising.'
            end
         end

      end

   end 

   if ( keyword_set ( DEBUG ) ) then $
      debug_info, 'DEBUG INFO (make_det_response.pro): Response determined successfully.'

   ; return the result
   return, { mf_Max              : mf_Max, $
             mb_Max              : mb_Max, $
             mf_Linear           : mf_Linear, $
             mb_Valid            : mb_Valid, $
             mf_CoeffsPoly       : mf_CoeffsPoly, $
             mf_Chi2             : mf_Chi2, $
             mf_CoeffsPolyNorm   : mf_CoeffsPolyNorm }

end
