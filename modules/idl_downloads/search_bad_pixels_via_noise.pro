;-----------------------------------------------------------------------
;
; NAME:  search_bad_pixels_via_noise
;
; PURPOSE: Find bad pixels from noise, uses darks.
;          this routine searches for static bad pixel positions
;          This is done by building a cube of dark frames and examine 
;          the noise variations in each pixel. If big deviations
;          from a clean mean pixel noise occurr, the pixel is 
;          declared as bad.
;
; INPUT :  p_Frames          : input pointer array with frames
;          p_IntFrames       : input pointer array with intframes
;          p_IntAuxFrames    : input pointer array with intauxframes
;          n_Sets            : number of valid frames
;          threshSigmaFactor : factor to determine standard deviation
;                              in each pixel to determine the threshold
;                              beyond which a pixel is declared as bad. 
;          loReject          
;          hiReject          : percentage (0. - 1.) of extreme pixel 
;                              values that is not considered for image
;                              statistics
;          llx,lly,urx,ury   : to compute image statistics on a
;                              rectangular zone of the image
;                              the coordinates of the rectangle are needed, llx is the lower left. 
;                              coordinates in pixel units
;
; OUTPUT : bad pixel mask (1 is good 0 is bad)
;
; NOTES : - At least 6 frames are needed
;         - The algorithm is from the SPIFFI data reduction pipeline
;
; STATUS : not tested
;
; HISTORY : 12.8.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

function search_bad_pixels_via_noise, p_Frames, p_IntFrames, p_IntAuxFrames, n_Sets, threshSigmaFactor, $
                                      loReject, hiReject, llx, lly, urx, ury, DEBUG=DEBUG


    if ( threshSigmaFactor le 0. ) then $
       return, error('ERROR IN CALL (search_bad_pixels_via_noise.pro): threshold factor is smaller or equal zero')

    if ( loReject lt 0. or hiReject lt 0. or (loReject + hiReject) ge 100.  ) then $
       return, error('ERROR IN CALL (search_bad_pixels_via_noise.pro): wrong reject parameters.')

    if ( n_Sets lt 5 ) then $
       return, error('ERROR IN CALL (search_bad_pixels_via_noise.pro): Too few input frames.')

    n_Dims = size(*p_Frames[0])

    low_n  = fix(loReject*float(n_Sets))
    high_n = fix(hiReject*float(n_Sets))

    pmd_Noise  = ptr_new(fltarr(n_Dims(1),n_Dims(2)))
    pmb_NoiseQ = ptr_new(bytarr(n_Dims(1),n_Dims(2)))

    for i=0, n_Dims(1)-1 do begin

       if ( keyword_set ( DEBUG ) ) then $
          if ( (i MOD (n_Dims(1)/10)) eq 0 ) then $
             debug_info, 'DEBUG INFO (search_bad_pixel_via_noise.pro): '+strtrim(string(fix(100.*float(i)/float(n_Dims(1)))),2)+'% done.'       

       for j=0, n_Dims(2)-1 do begin

          vd_Data  = fltarr(n_Sets)
          vb_DataQ = bytarr(n_Sets)

          for k=0, n_Sets-1 do begin
             vd_Data(k)  = (*p_Frames(k))(i,j)
             vb_DataQ(k) = (*p_IntAuxFrames(k))(i,j)
          end

          d_Noise  = clean_op( vd_Data, vb_DataQ, loReject, hiReject, 'STD' )
          if ( bool_is_vector ( d_Noise ) ) then begin
             (*pmd_Noise)[i,j]  = d_Noise
             (*pmb_NoiseQ)[i,j] = 1b
          end
       end
    end

    s_imag_stat = image_stat_on_rect ( pmd_Noise, pmb_NoiseQ, loReject, hiReject, $
                                       llx, lly, urx, ury )

    ;now build the bad pixel mask
    mb_Mask = bytarr(n_Dims(1),n_Dims(2))+1b

    if ( NOT bool_is_struct(s_imag_stat) ) then begin
       warning, ['WARNING (searchBadPixelsViaNoise.pro): image statistics of noise frame failed.', $
                 '                                       All pixels are set to valid.']
       return, mb_Mask
    end

    ;now build the bad pixel mask
    vb_Mask = where ( *pmd_Noise gt s_imag_stat.CMEAN + threshSigmaFactor*s_imag_stat.CSTDEV or $
                      *pmd_Noise lt s_imag_stat.CMEAN - threshSigmaFactor*s_imag_stat.CSTDEV     , n_Dead )
    if ( n_Dead gt 0 ) then mb_Mask(vb_Mask) = 0


    return, mb_Mask

end
