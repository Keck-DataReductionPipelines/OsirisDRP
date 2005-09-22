;-------------------------------------------------------------------------
; NAME: interponed
;
; PURPOSE: interpolate bad pixel in wavelength direction
;
; INPUT : p_Frames           : pointer or pointerarray with the frames
;                              images or cubes
;         p_IntFrames        : pointer or pointerarray with the intframes
;                              images or cubes
;         p_IntAuxFrames     : pointer or pointerarray with the intauxframes
;                              images or cubes
;         nFrames            : number of input dataset pointers
;         d_BadMult          : noise multiplication factor
;         d_GoodMult         : noise multiplication factor
;         [MASK = MASK]      : optional pointer to a bad pixel mask (1b:bad, 0b:good)
;         [\DEBUG]           : initialize the debugging mode
;
; OUTPUT : float vector with the number of pixels in each frame that could not be interpolated.
;
; ALGORITHM : Bad pixel (indicated by valid(/VALIDS)) are pixel that shall be interpolated.
;             An optional bad pixel mask can be passed which is anded. 
;             Bad pixels are interpolated only in spectral direction.
;             An extraction window around a bad pixel is enlarged as
;             long as the number of pixel that may be used for
;             interpolation n and the size of the extraction window s
;             fullfill one of the following conditions :
;               -  n ge 3 and s ge 3
;               -  n ge 4 and s lt 3
;             In the first case the interpolation is linear, in the
;             second parabolic.
;             The extraction window must be smaller than half of the
;             wavelength axis. Otherwise the pixel will not be interpolated.
;             Pixel that may be used for interpolation must be valid
;             (acc. to valid (\VALIDS)).
;             The new noise value is the median of noise values of the
;             pixels that have been used for interpolation times a
;             factor. If the interpolation was linear the factor is
;             d_BadMult otherwise d_GoodMult.
;
; NOTES :   - When dealing with cubes the cubes are reformed to images
;             before. 
;
; OUTPUT : works on the dataset pointers
;          returns longword integer vector with number of pixels in
;          each frame that have not been interpolated.
;
; ON ERROR : returns nothing
;
; STATUS : untested
;
; HISTORY : 13.9.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-------------------------------------------------------------------------
function interponed, p_Frames, p_IntFrames, p_IntAuxFrames, nFrames, d_BadMult, d_GoodMult, $
                     MASK = MASK, DEBUG = DEBUG

   COMMON APP_CONSTANTS

   vi_Dead = lonarr(nFrames)

   ; integrity checks
   if ( bool_pointer_integrity( p_Frames, p_IntFrames, p_IntAuxFrames, 1, 'interponed.pro' ) ne OK ) then $
      return, error('ERROR IN CALL (interponed.pro): Integrity check failed.')

   if ( keyword_set ( MASK ) ) then begin
      mb_Mask = *MASK
      if ( NOT bool_dim_match ( mb_Mask, *p_Frames(0) ) ) then $
         return, error('ERROR IN CALL (interponed.pro): Bad pixel mask and input not compatible in size.')
      if ( keyword_set ( DEBUG ) ) then $
        debug_info, 'DEBUG INFO (interponed.pro): Found '+ strg(fix(total(mb_Mask))) + $
           ' pixels as defined in the bad pixel mask.'
   end

   ; integrity checks done, now run

   ; loop over the frames
   for i=0, nFrames-1 do begin

      if ( keyword_set ( DEBUG ) ) then $
         debug_info, 'DEBUG INFO (interponed.pro): Interpolating set '+strg(i) + ' now.'

      n_DimsOrig = size ( *p_Frames(i) )

      ; indicator that input frames have been cubes
      b_WasCube = 0

      ; reform cube cubes to images, wavelength axis = first axis, if input
      ; are cubes
      if ( bool_is_cube(*p_Frames(i)) ) then begin
         b_WasCube          = 1
         *p_Frames(i)       = reform ( *p_Frames(i), n_DimsOrig(1), n_DimsOrig(2)*n_DimsOrig(3) )
         *p_IntFrames(i)    = reform ( *p_IntFrames(i), n_DimsOrig(1), n_DimsOrig(2)*n_DimsOrig(3) )
         *p_IntAuxFrames(i) = reform ( *p_IntAuxFrames(i), n_DimsOrig(1), n_DimsOrig(2)*n_DimsOrig(3) )
         if ( keyword_set (DEBUG) ) then $
            debug_info,'DEBUG INFO (interponed.pro): Reforming cubes.'
      end

      n_Dims = size ( *p_Frames(i) )

      ; counters
      i_Lin = 0L ; # linear interpolations
      i_Squ = 0L ; # parabolic interpolations
      i_Dea = 0L ; # failed interpolations
 
      ; indicates where invalid pixels are
      if ( b_WasCube eq 0 ) then begin
         ; in 2d the inside bit has no meaning
         mb_Bad    = bool_invert( valid ( *p_Frames(i), *p_IntFrames(i), *p_IntAuxFrames(i), /VALIDS ) ) 
         mb_Inside = make_array( SIZE=size(mb_Bad), /BYTE, VALUE=1b)
      endif else begin
         ; in 3d the inside bit must be checked
         mb_Bad    = bool_invert( valid ( *p_Frames(i), *p_IntFrames(i), *p_IntAuxFrames(i) ) ) 
         mb_Inside = valid ( *p_Frames(i), *p_IntFrames(i), *p_IntAuxFrames(i), /INSIDE ) 
      end

      ; indicates what pixels are to be interpolated
      if ( keyword_set(MASK) ) then mb_ToBeInterp = mb_Mask else mb_ToBeInterp = (mb_Bad and mb_Inside)

      if ( b_WasCube eq 1 ) then $
         mb_ToBeInterp = reform ( mb_ToBeInterp, n_DimsOrig(1), n_DimsOrig(2)*n_DimsOrig(3) )

      ; 1d index of pixels that shall be interpolated
      vi_ToBeInterp = where ( mb_ToBeInterp eq 1, n_ToBeInterp )

      info, 'INFO (interponed.pro): Found '+ strg(n_ToBeInterp) + ' pixels out of ' + strg(n_elements(*p_Frames(i))) + $
            ' to interpolate in set '+strg(i)+'.'

      if ( n_ToBeInterp gt 0 ) then begin

         ; we found some pixel to interpolate

         ; determine x and y coordinates in frame
         vi_ToBeInterpX = vi_ToBeInterp mod n_Dims(1)
         vi_ToBeInterpY = fix( vi_ToBeInterp / n_Dims(1) )

         ; check that the reconstructed x,y coordinates make sense
         mb_Tmp = make_array(/BYTE, SIZE=n_Dims)
         mb_Tmp[vi_ToBeInterpX, vi_ToBeInterpY] = 1b
         if ( array_equal ( mb_Tmp, mb_ToBeInterp ) ne 1 ) then $
            return, error ('INTERNAL ERROR (interponed.pro): Array indices not recoverable.')

         ; abbreviation
         nx = n_Dims(1)-1

         ; loop over the pixels to be interpolated
         for j=0L, long(n_ToBeInterp)-1L do begin

            if ( ((j>1) mod ((n_ToBeInterp/10)>1) ) eq 0 ) then $
               info,'INFO (interponed.pro): '+ strg(fix(float(j)*100./n_ToBeInterp))+$
                    '% of the bad pixel in set '+strg(i)+' interpolated.'

            b_Go     = 1   ; if 1 continue to enlarge the extraction window
                           ; around the bad pixel
            i_Window = 2   ; width of the window (to the left and to the right)
                           ; around a specific bad pixel

            while ( b_Go ) do begin

               ; limits around the bad pixel
               nlx = (vi_ToBeInterpX(j)-i_Window)>0<nx
               nux = (vi_ToBeInterpX(j)+i_Window)>0<nx

               ; extract pixels between these limits that may
               ; be used for interpolation
               vi_MaskX  = where ( mb_ToBeInterp(nlx:nux,vi_ToBeInterpY(j)) eq 0 and $
                                   mb_Bad(nlx:nux,vi_ToBeInterpY(j)) eq 0, n_Window )

               ; criteria to stop enlarging the window
               b_Lin = ( n_Window ge 3 and i_Window ge 3 )
               b_Squ = ( n_Window ge 4 and i_Window lt 3 )

               if ( b_Squ or b_Lin ) then begin

                  b_Go = 0

                  ; get the parameters for interpolation

                  vf_XX = findgen(n_Dims(1))
                  vf_X  = ((vf_XX)(nlx:nux))(vi_MaskX)
                  vf_Y  = ( reform ( (*p_Frames(i))(nlx:nux, vi_ToBeInterpY(j)) ) ) (vi_MaskX)
                  vf_N  = ( reform ( (*p_IntFrames(i))(nlx:nux, vi_ToBeInterpY(j)) ) ) (vi_MaskX)

                  ; normalize the x-axis
                  d_MaxX = 0
                  d_MaxX = median(vf_X)
                  vf_X = vf_X - d_MaxX

                  if ( b_Lin ) then begin

                     ; linear interpolate
                     i_Lin = i_Lin + 1L

                     ; SVDFIT may fail if less than 3 pixels are used for fitting
                     vf_Coeff = linfit( vf_X, vf_Y, MEASURE_ERRORS=vf_N )
                     vf_New = vf_Coeff(0) + vf_Coeff(1)*(vf_XX-d_MaxX)
                     (*p_IntFrames(i))(vi_ToBeInterpX(j),vi_ToBeInterpY(j)) = median(vf_N) * d_BadMult
                     (*p_IntAuxFrames(i))(vi_ToBeInterpX(j),vi_ToBeInterpY(j)) = setbit ( $
                                               (*p_IntAuxFrames(i))(vi_ToBeInterpX(j),vi_ToBeInterpY(j)), 0, 1)
                     (*p_IntAuxFrames(i))(vi_ToBeInterpX(j),vi_ToBeInterpY(j)) = setbit ( $
                                               (*p_IntAuxFrames(i))(vi_ToBeInterpX(j),vi_ToBeInterpY(j)), 1, 1)
                     (*p_Frames(i))(vi_ToBeInterpX(j),vi_ToBeInterpY(j)) = vf_New(vi_ToBeInterpX(j))

                     if ( keyword_set (Debug) ) then begin
                         plot, vf_X, vf_Y, title='Linear interpolation', psym=2, symsize=2
                         oplot, [vi_ToBeInterpX(j),vi_ToBeInterpX(j)], $
                                [vf_New(vi_ToBeInterpX(j)),vf_New(vi_ToBeInterpX(j))], color=2, psym=4, symsize=2
                         oplot, vf_X, (vf_New(nlx:nux))(vi_MaskX), color=1
                         wait, 0.5
                     end

                  endif else begin

                     ; parabolic interpolation
                     i_Squ = i_Squ + 1L
                     ; SVDFIT may fail if less than 4 pixels are used for fitting
                     vf_Coeff = SVDFIT_61( vf_X, vf_Y, 3, MEASURE_ERRORS=vf_N )
                     vf_New = vf_Coeff(0) + vf_Coeff(1)*(vf_XX-d_MaxX) + vf_Coeff(2)*(vf_XX-d_MaxX)^2
                     (*p_IntFrames(i))(vi_ToBeInterpX(j),vi_ToBeInterpY(j)) = median(vf_N) * d_GoodMult
                     (*p_IntAuxFrames(i))(vi_ToBeInterpX(j),vi_ToBeInterpY(j)) = setbit ( $
                                            (*p_IntAuxFrames(i))(vi_ToBeInterpX(j),vi_ToBeInterpY(j)), 0, 1)
                     (*p_IntAuxFrames(i))(vi_ToBeInterpX(j),vi_ToBeInterpY(j)) = setbit ( $
                                            (*p_IntAuxFrames(i))(vi_ToBeInterpX(j),vi_ToBeInterpY(j)), 1, 1)
                     (*p_IntAuxFrames(i))(vi_ToBeInterpX(j),vi_ToBeInterpY(j)) = setbit ( $
                                            (*p_IntAuxFrames(i))(vi_ToBeInterpX(j),vi_ToBeInterpY(j)), 2, 1)
                     (*p_Frames(i))(vi_ToBeInterpX(j),vi_ToBeInterpY(j)) = vf_New(vi_ToBeInterpX(j))

                     if ( keyword_set (Debug) ) then begin
                         plot, vf_X, vf_Y, title='Parabolic interpolation', psym=2, symsize=2
                         oplot, [vi_ToBeInterpX(j)-d_MaxX,vi_ToBeInterpX(j)-d_MaxX], $
                                [vf_New(vi_ToBeInterpX(j)),vf_New(vi_ToBeInterpX(j))], color=2, psym=4, symsize=2
                         oplot, vf_X, (vf_New(nlx:nux))(vi_MaskX), color=1
                         wait, 0.5
                     end

                  end

              endif else i_Window = i_Window + 1 ; if not enough valid pixels have been found in the 
                                ; extraction window enlarge the window

              if ( i_Window gt fix(nx/4) ) then begin
                 ; the window extends a quarter of the spectrum
                 ; stop, the pixels cannot be interpolated
                 ; the fit failed, not enough pixel found
                 b_Go = 0 
                 i_Dea = i_Dea + 1L
                 info,[ 'INFO (interponed.pro): Failed to interpolate pixel in set ' +strg(i) +'.', $
                        '     Extraction window length exceeding limit.', $
                        '     Pixel has 0th bit ' + strg(fix(mb_ToBeInterp(vi_ToBeInterp(j)))) + $
                        ' and 3rd bit ' + strg(fix(mb_Out(vi_ToBeInterp(j)))) + '.' ]
              end

            end

         end

      end

      ; reform the images to cubes, if the input have been cubes
      if ( b_WasCube ) then begin
         *p_Frames(i)       = reform ( *p_Frames(i), n_DimsOrig(1), n_DimsOrig(2), n_DimsOrig(3) )
         *p_IntFrames(i)    = reform ( *p_IntFrames(i), n_DimsOrig(1), n_DimsOrig(2), n_DimsOrig(3) )
         *p_IntAuxFrames(i) = reform ( *p_IntAuxFrames(i), n_DimsOrig(1), n_DimsOrig(2), n_DimsOrig(3) )
         n_Dims             = size ( *p_Frames(i) )
         if ( keyword_set (DEBUG) ) then $
            debug_info,'DEBUG INFO (interponed.pro): Reforming cubes again.'
      end

      info, 'INFO (interponed.pro): '+strg(i_Lin) + ' pixel linearly interpolated.'
      info, 'INFO (interponed.pro): '+strg(i_Squ) + ' pixel parabolically interpolated.'
      info, 'INFO (interponed.pro): '+strg(i_Dea) + ' pixel not interpolated.'

      vi_Dead(i) = i_Dea

  end

  return, vi_Dead

end
