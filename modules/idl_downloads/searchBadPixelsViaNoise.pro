;   Function     :       searchBadPixelsViaNoise()
;   In           :       darks: sequence of darks (NDIT = 1) 
;                               stored in a cube, at least 10 to get good statistics
;                        threshSigmaFactor: factor to determined standard deviation
;                                           in each pixel to determine the threshold
;                                           beyond which a pixel is declared as bad. 
;                        loReject, hiReject: percentage (0...100) of extreme pixel 
;                                            values that is not considered for image
;                                            statistics
;   Out          :       Bad pixel mask image (1: good pixel, 0: bad pixel). 
;   Job          :       this routine searches for static bad pixel positions
;                        This is done by building a cube of dark frames and examine 
;                        the noise variations in each pixel. If big deviations
;                        from a clean mean pixel noise occurr, the pixel is 
;                        declared as bad.
; ---------------------------------------------------------------------------*/

function search_bad_pixels_via_noise, p_Frames, p_IntFrames, p_IntAuxFrames, n_Sets, threshSigmaFactor, loReject, hiReject


    if ( threshSigmaFactor le 0. ) then $
       return, error('ERROR IN CALL (search_bad_pixels_via_noise.pro): threshold factor is smaller or equal zero')

    if ( loReject lt 0. or hiReject lt 0. or (loReject + hiReject) ge 100.  ) then $
       return, error('ERROR IN CALL (search_bad_pixels_via_noise.pro): wrong reject parameters.')

    if ( n_Sets lt 5 ) then $
       return, error('ERROR IN CALL (search_bad_pixels_via_noise.pro): Too few input frames.')


    n_Dims = size(*p_Frames)
    lx = n_Dims(1)
    ly = n_Dims(2)
    low_n  = fix(loReject*float(n_Sets))
    high_n = fix(hiReject*float(n_Sets))

    pmd_Noise  = ptr_new(fltarr(n_Dims(1),n_Dims(2)))
    pmb_NoiseQ = ptr_new(bytarr(n_Dims(1),n_Dims(2)))

    for i=0, n_Dims(1)-1 do $
       for j=0, n_Dims(2)-1 do begin
          vd_Data  = (*p_Frames)(i,j,*)
          vd_DataQ = (*p_IntAuxFrames)(i,j,*)
          d_Noise  = clean_op( vd_Data, vd_DataQ, loReject, hiReject, 'STD' )
          if ( bool_is_vector ( d_Noise ) ) then begin
             (*pmd_Noise)[i,j]  = d_Noise
             (*pmb_NoiseQ)[i,j] = 1b
          end
       end

    s_imag_stat = image_stat_on_rect ( pmd_Noise, pmb_NoiseQ, loReject, hiReject, $
                                       fix(0.2*n_Dims(1)), fix(0.2*n_Dims(2)), fix(0.8*n_Dims(1)), fix(0.8*n_Dims(2)) )

    ;now build the bad pixel mask
    mb_Mask = bytarr(n_Dims(1),n_Dims(2))+1b

    if ( NOT bool_is_struct(s_imag_stat) ) then begin
       warning, ['WARNING (searchBadPixelsViaNoise.pro): image statistics of noise frame failed.', $
                 '                                       All pixels are set to valid.']
       return, mb_Mask
    end

    ;now build the bad pixel mask
    mb_Mask ( where ( *pmd_Noise gt s_imag_stat.CMEAN + threshSigmaFactor*s_imag_stat.CSTDEV or $
                      *pmd_Noise lt s_imag_stat.CMEAN - threshSigmaFactor*s_imag_stat.CSTDEV      ) ) = 0

    return, mb_Mask

end
