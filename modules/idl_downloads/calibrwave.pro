;-------------------------------------------------------------------------
; NAME: calibrwave
;
; PURPOSE: resample spectrum to a regular grid, NOT flux conserving
;
; INPUT : p_Frames           : pointer or pointerarray with the frames
;                              images or cubes
;         p_IntFrames        : pointer or pointerarray with the intframes
;                              images or cubes
;         p_IntAuxFrames     : pointer or pointerarray with the intauxframes
;                              images or cubes
;         p_Headers          : pointer or pointerarray with the headers
;         nFrames            : number of input dataset pointers
;         cd_CalibFrame      : calibration frame describing the
;                              wavelengths for each spectrum
;         mb_CalibFrameValid : status of calibration frame. 0 means OK
;         d_BadMultiplier    : see ALGORITHM
;         d_BadIntMultiplier : see ALGORITHM
;         d_LowerLimitGood   : see ALGORITHM
;         d_UpperLimitGood   : see ALGORITHM
;         d_UpperLimitBad    : see ALGORITHM
;         d_NoiseMultiplier  : see ALGORITHM
;         s_InterPolType     : interpolation function:
;                              LINEAR, QUADRATIC, LSQUADRATIC, SPLINE
;         s_FilterFile       : absolute path with the filter file
;         [\ORP]             : if set the interpolation bits (bit 1 and 2)
;                              are not determined
;         [\DEBUG]           : initialize the debugging mode
;
; OUTPUT : None
;
; ALGORITHM :
;    The grids :
;
;                n : not valid (acc valid.pro but ignoring the 3rd bit)
;                o : outside, 3rd bit=0
;
;
;            d_MinLReg      d_MinL                                 d_MaxL      d_MaxLReg
;                <-------------|-----------------------------------------|------------->        spectrum on 
;                                                                                                  regular grid
;
;                         d_MinLCal                                   d_MaxLCal
;                              <oooooo|------------n----o---------|oooooo>                      spectrum on 
;                                 d_MinLInside                d_MaxLInside                         calibrated grid
;
;
;     Definitions : 1) d_MinLReg/d_MaxLReg = lowest/highest occuring wavelength of the resampled grid
;                   2) d_MinLCal/d_MaxLCal = lowest/highest occuring wavelength of the calibrated grid
;                   3) d_MinL/d_MaxL       = lowest/highest occuring common wavelength of the calibrated 
;                                            and resampled grid
;                   4) d_MinLInside/d_MaxLInside = inner wavelengths,
;                         lowest/highest occuring wavelength of the calibrated grid
;                         where the spectrum starts and ends (concerning the inside bit),
;                                                  
;                   Remark : depending on the relative shifts between the resampled and calibrated grid
;                            e.g. d_MinLInside can coincide with d_MinL and/or d_MinLReg.
;                      
;                   5) Pixels within d_MinLInside and d_MaxLInside are called inner pixel. 
;                   6) bad means not valid accoring to valid.pro
;                   7) outside means that the 3rd bit is 0
;
;     Interpolation on inner pixel:
;
;        Only inner pixel that are not bad and not outside are used for cubic spline interpolation.
;        All values on the resampled grid that are between d_MinLInside and d_MaxLInside.
;        will contain interpolated values afterwards.
;
;        All pixel that are not inner pixel get :  frame value = intframe value = 0
;                                                  [0,0,0,0] : quality bits 0-3
;        All inner pixel get the interpolated frame and intframe values (exceptions are bad and outside inner pixel).
;
;        The intframe values are interpolated squared and rooted afterwards. 
;
;        Determining the quality status after interpolation:
;           A status vector is created describing the status of the inner pixel. 
;           The status vector elements corresponding to an inner pixel get :
;              not interpolated      : 0
;              good/bad interpolated : 1 / d_BadIntMultiplier
;              bad or outside        : d_BadMultiplier
;
;           The status vector is resampled linearly onto the new grid. Resampled pixel on the new grid
;           that fullfill any of the following conditions get :
;              d_LowerLimitGood < value < d_UpperLimitGood  : good interpolation status 
;              d_UpperLimitGood < value < d_UpperLimitBad   : bad interpolation status
;              value > d_UpperLimitBad                      : bad interpolation status and the corresponding
;                                                             resampled intframe value is multiplied by
;                                                             d_NoiseMultiplier.
;
;
; NOTES : - modifies the input data pointer
;         - the dataset images or cubes are reformed to images before
;           calculations.
;         - sets the CDELT1, CRVAL1 and CRPIX1 fits-keyword.
;
; OUTPUT : nothing
;
; ON ERROR : returns nothing
;
; STATUS : untested
;
; HISTORY : 3.9.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-------------------------------------------------------------------------


function calibrwave, p_Frames, p_IntFrames, p_IntAuxFrames, p_Headers, nFrames, cd_CalibFrame, mb_CalibFrameValid, $
                     d_BadMultiplier, d_BadIntMultiplier, d_LowerLimitGood, d_UpperLimitGood, d_UpperLimitBad, $
                     d_NoiseMultiplier, s_InterPolType, s_FilterFile, ORP=ORP, DEBUG=DEBUG

   COMMON APP_CONSTANTS
   COMMON ERROR_CONSTANTS

   ; parameter checks
   if ( d_LowerLimitGood ge d_UpperLimitGood ) then $
      return, error('ERROR IN CALL (calibrwave.pro): LowerLimitGood ge UpperLimitGood.')
   if ( d_UpperLimitGood ge d_UpperLimitBad ) then $
      return, error('ERROR IN CALL (calibrwave.pro): d_UpperLimitGood ge d_UpperLimitBad.')
   if ( d_BadMultiplier le 0. ) then $
      return, error('ERROR IN CALL (calibrwave.pro): d_BadMultiplier lt 0.')
   if ( d_BadIntMultiplier le 0. ) then $
      return, error('ERROR IN CALL (calibrwave.pro): d_BadIntMultiplier lt 0.')
   if ( d_NoiseMultiplier le 0. ) then $
      return, error('ERROR IN CALL (calibrwave.pro): d_NoiseMultiplier lt 0.')
   if ( s_InterpolType ne 'LINEAR' and s_InterpolType ne 'QUADRATIC' and $
        s_InterpolType ne 'LSQUADRATIC' and s_InterpolType ne 'SPLINE' ) then $
      return, error('ERROR IN CALL (calibrwave.pro): Unknown interpolation type ('+strg(s_InterPolType)+').')

   ; done with the integrity checks

   ; dimensions of the wavelength map
   n_DimCal = size(cd_CalibFrame)

   ; get the filter 
   s_Filter = strtrim(sxpar(*p_Headers[0], "SFILTER", /SILENT),2)

   ; get the wavelengths of the new regular grid
   s_Res = get_filter_param ( s_Filter, s_FilterFile )

   if ( NOT bool_is_struct ( s_Res ) ) then $
      return, error ('FAILURE ('+functionName+'): Failed to get the filter information.')

   vd_WLReg = (dindgen(s_Res.n_RegPix(0)) * s_Res.d_RegDisp_nmperpix(0)) + s_Res.d_RegMinWL_nm(0)

   ; min and max of the new regular grid
   d_MinLReg = min ( vd_WLReg )
   d_MaxLReg = max ( vd_WLReg )

   if ( keyword_set ( DEBUG ) ) then begin
      debug_info, 'DEBUG INFO (calibrwave.pro): Filter ' + strg(s_Filter)
      debug_info, 'DEBUG INFO (calibrwave.pro): Min WL ' + strg(d_MinLReg) + ', max WL ' + strg(d_MaxLReg)
      debug_info, 'DEBUG INFO (calibrwave.pro): # of pix ' + strg(s_Res.n_RegPix(0)) + $
         ', Scale ' +strg(s_Res.d_Disp_nmperpix(0))
   end

   ; loop over the frames
   for i = 0, nFrames-1 do begin

      if ( keyword_set ( DEBUG ) ) then $
         debug_info, 'DEBUG INFO (calibrwave.pro): Working on frame ' + strg(i) + ' now.'

      ; allocate memory for the resampled resultant frame
      md_FrameReg       = fltarr(s_Res.n_RegPix(0),n_DimCal(2),n_DimCal(3))
      md_IntFrameReg    = fltarr(s_Res.n_RegPix(0),n_DimCal(2),n_DimCal(3))
      mb_IntAuxFrameReg = bytarr(s_Res.n_RegPix(0),n_DimCal(2),n_DimCal(3))

      ; loop over the individual spectra
      for j=0, n_DimCal(2)-1 do begin

         info,'INFO (calibrwave.pro): Working on row '+strg(j)+' of set '+strg(i)+'.'

         for k=0, n_DimCal(3)-1 do begin

            ; initialize the resultant resampled spectrum
            vd_FrameReg       = fltarr(s_Res.n_RegPix(0))
            vd_IntFrameReg    = fltarr(s_Res.n_RegPix(0))
            vb_IntAuxFrameReg = bytarr(s_Res.n_RegPix(0))

            if ( mb_CalibFrameValid(j,k) eq ERROR_DISPERSION_OK ) then begin
 
               ; min and max of the calibrated grid
               d_MinLCal = min(reform((cd_CalibFrame)[*,j,k]))
               d_MaxLCal = max(reform((cd_CalibFrame)[*,j,k]))

               ; find common wavelength regime of regular and calibrated grid
               d_MinL = d_MinLCal > d_MinLReg
               d_MaxL = d_MaxLCal < d_MaxLReg

               if ( keyword_set ( DEBUG ) ) then begin
                  debug_info, 'DEBUG INFO (calibrwave.pro): WL calibrated '+strg(d_MinLCal)+','+strg(d_MaxLCal)
                  debug_info, 'DEBUG INFO (calibrwave.pro): WL resampled  '+strg(d_MinLReg)+','+strg(d_MaxLReg)
                  debug_info, 'DEBUG INFO (calibrwave.pro): WL common     '+strg(d_MinL)+','+strg(d_MaxL)
               end

               if ( d_MinLCal lt d_MinLReg ) then $
                  warning, ['WARNING (calibrwave.pro): Minimum wavelength of resampled grid ('+strg(d_MinLReg)+ $
                           ') is greater than ', $
                            '        minimum calibrated wavelength ('+strg(d_MinLCal)+') in spectrum '+$
                            strg(j)+','+strg(k)+'. You may loose information.']
               if ( d_MaxLCal gt d_MaxLReg ) then $
                  warning, ['WARNING (calibrwave.pro): Maximum wavelength of resampled grid ('+strg(d_MaxLReg)+ $
                            ') is less than ', $
                            '        maximum calibrated wavelength ('+strg(d_MaxLCal)+') in spectrum '+$
                            strg(j)+','+strg(k)+'. You may loose information.']
               
               ; find pixel on calibrated grid that are withing the common
               ; wavelength regime and that are inside : inner pixel
               vb_CommonInside = reform ( ( (cd_CalibFrame)[*,j,k] ge d_MinL and $
                                            (cd_CalibFrame)[*,j,k] le d_MaxL ) and $
                                          extbit ( (*p_IntAuxFrames[i])[*,j,k], 3 ) )
               vi_CommonInside = where ( vb_CommonInside, n_CommonInside )

               if ( n_CommonInside gt 5 ) then begin
                  ; at least 5 inner pixel found, determine the inner wavelengths
                  d_MinLInside = min ( (cd_CalibFrame)[vi_CommonInside,j,k] )
                  d_MaxLInside = max ( (cd_CalibFrame)[vi_CommonInside,j,k] )
      
                  if ( keyword_set ( DEBUG ) ) then $
                     debug_info, 'DEBUG INFO (calibrwave.pro): WL calibrated and inside '+$
                                 strg(d_MinLInside)+','+strg(d_MaxLInside)
      
                  ; mask where inner pixels are within a calibrated spectrum
                  vb_Common2 = reform( (cd_CalibFrame)[*,j,k] ge d_MinLInside and $
                                       (cd_CalibFrame)[*,j,k] le d_MaxLInside )
      
                  ; mask where pixels of whole spectrum are valid
                           vb_Valid   = reform ( valid ( (*p_Frames[i])[*,j,k], (*p_IntFrames[i])[*,j,k], $
                                                (*p_IntAuxFrames[i])[*,j,k] ) )
      
                  ; mask where inner valid pixels are
                           vi_Valid = where ( vb_Valid and vb_Common2, n_Valid )
      
                  if ( n_Valid gt 5 ) then begin
      
                     ; at least 5 inner valid pixels have been found
      
                     vd_YIntCal   = reform((*p_IntFrames[i])[vi_Valid,j,k])
                     vd_YCal      = reform((*p_Frames[i])[vi_Valid,j,k])
                     vd_XCal      = reform((cd_CalibFrame)[vi_Valid,j,k])
               
                     ; mask where the inner pixel come to lie on the resampled grid
                     vb_CommonReg = vd_WLReg ge d_MinLInside and vd_WLReg le d_MaxLInside
                     vi_CommonReg = where ( vb_CommonReg, n_CommonReg )
                     ; the wavelengths of the regular grid for inner pixel
                     vd_XReg      = vd_WLReg(vi_CommonReg)
      
                     ; cubic spline interpolation of the fluxes to the new wavelength grid
                     vd_FrameRegPart = interpol( vd_YCal, vd_XCal, vd_XReg, $
                                                 QUADRATIC = s_InterPolType eq 'QUADRATIC', $
                                                 LSQUADRATIC = s_InterPolType eq 'LSQUADRATIC', $
                                                 SPLINE = s_InterPolType eq 'SPLINE' )
      
                     ; cubic spline interpolation of the squared noises to the new wavelength grid
                     vd_IntFrameRegPart = interpol( vd_YIntCal^2, vd_XCal, vd_XReg, $
                                                 QUADRATIC = s_InterPolType eq 'QUADRATIC', $
                                                 LSQUADRATIC = s_InterPolType eq 'LSQUADRATIC', $
                                                 SPLINE = s_InterPolType eq 'SPLINE' )
      
                     ; safety check, the noise interpolation should not create negative values
                     vi_Neg = where ( vd_IntFrameRegPart lt 0., n_Neg )
                     if ( n_Neg gt 0 ) then $
                        warning, ['WARNING (calibrwave.pro): Noise interpolation created negative noise values' + $
                                           ' in set '+ strg(i) + ' in spectrum ' + strg(j)+','+strg(k)+'.', $
                                  '   This is not an error but may indicate the occurance of clustered bad pixels.' + $ 
                                  ' I continue with the absolute values.']
      
                     ; now root the squared resampled noise values
                     vd_IntFrameRegPart = sqrt( abs (vd_IntFrameRegPart) )

                     ; fill the interpolated inner part of the spectrum into the inner part of
                     ; the resampled grid
                     vd_FrameReg(vi_CommonReg)    = vd_FrameRegPart
                     vd_IntFrameReg(vi_CommonReg) = vd_IntFrameRegPart
      
                     ; now set the intauxframe bits
      
                     ; all inner pixel on the resampled grid get 0th bit and 3rd bit set to 1
                     vb_IntAuxFrameReg(vi_CommonReg) = setbit ( vb_IntAuxFrameReg(vi_CommonReg), 0, 1 )
                     vb_IntAuxFrameReg(vi_CommonReg) = setbit ( vb_IntAuxFrameReg(vi_CommonReg), 3, 1 )
      
                     ; the interpolation bits ( bits 1 and 2 ) are not set in ORP mode to save
                     ; computation time
                     if ( NOT keyword_set ( ORP ) ) then begin
      
                        if ( keyword_set ( DEBUG ) ) then $
                                    debug_info, 'DEBUG INFO (calibrwave.pro): Setting interpolation bits'
      
                        ; check where inner pixel
                        ; on the calibrated grid are good/bad interpolated or not valid
                
                        vi_Common2  = where ( vb_Common2 )
      
                        vb_NotValid = bool_invert( valid ( (*p_Frames[i])[vi_Common2,j,k], $
                                                           (*p_IntFrames[i])[vi_Common2,j,k], $
                                                           (*p_IntAuxFrames[i])[vi_Common2,j,k] ) )
                        vb_GoodInt  = valid ( (*p_Frames[i])[vi_Common2,j,k], (*p_IntFrames[i])[vi_Common2,j,k], $
                                              (*p_IntAuxFrames[i])[vi_Common2,j,k], /GOODINT )
                        vb_BadInt   = valid ( (*p_Frames[i])[vi_Common2,j,k], (*p_IntFrames[i])[vi_Common2,j,k], $
                                                       (*p_IntAuxFrames[i])[vi_Common2,j,k], /BADINT )
      
                        ; create the status vector. 
                        vf_Int = reform ( float(vb_GoodInt) + d_BadIntMultiplier*float(vb_BadInt) + $
                                                   d_BadMultiplier*float(vb_NotValid) )
                        ; check consistency
                        dummy  = where ( vf_Int ne 0. and vf_Int ne 1. and vf_Int ne d_BadIntMultiplier and $
                                         vf_Int ne d_BadMultiplier, n_Check )
                        if ( n_Check gt 0 ) then $
                           warning,['WARNING (calibrwave.pro): Not critical inconsistency (1) detected.', $
                                    '        New interpolation status may be wrong.']
      
                        ; count the interpolated pixels in that spectrum
                                 dummy = where ( vf_Int gt 0., n_Int )
      
                        if ( n_Int gt 0 ) then begin
      
                           ; interpolate the status vector linearly
                           vd_IntReg  = interpol( vf_Int, reform((cd_CalibFrame)[vi_Common2,j,k]), vd_XReg )
                           ; compare with the limits
                           vi_GoodIntReg  = where ( vd_IntReg gt d_LowerLimitGood and vd_IntReg lt d_UpperLimitGood, $
                                                    n_GoodIntReg )
                           vi_BadIntReg   = where ( vd_IntReg gt d_UpperLimitGood and vd_IntReg lt d_UpperLimitBad, $
                                                    n_BadIntReg )
                           vi_NotValidReg = where ( vd_IntReg gt d_UpperLimitBad, n_NotValidIntReg  ) 
      
                           ; set good interpolation status when found 
                           if ( n_GoodIntReg gt 0 ) then begin
                              if ( keyword_set ( DEBUG ) ) then $
                                 debug_info, 'DEBUG INFO (calibrwave.pro): '+strg(n_GoodIntReg)+$
                                             ' interpolated pixels in set '+strg(i)+$
                                    ' spectrum '+strg(j)+','+strg(k) +' get the good interpolation status.'
                              vb_IntAuxFrameReg(vi_CommonReg(vi_GoodIntReg)) = $
                                  setbit(vb_IntAuxFrameReg(vi_CommonReg(vi_GoodIntReg)),1,1)
                              vb_IntAuxFrameReg(vi_CommonReg(vi_GoodIntReg)) = $
                                  setbit(vb_IntAuxFrameReg(vi_CommonReg(vi_GoodIntReg)),2,1)
                           end
      
                           ; set bad interpolation status when found 
                           if ( n_BadIntReg gt 0 ) then begin
                              if ( keyword_set ( DEBUG ) ) then $
                                 debug_info, 'DEBUG INFO (calibrwave.pro): '+strg(n_BadIntReg)+$
                                    ' interpolated pixels in set '+strg(i)+$
                                             ' spectrum '+strg(j)+','+strg(k) +' get the bad interpolation status.'
                              vb_IntAuxFrameReg(vi_CommonReg(vi_BadIntReg)) = $
                                 setbit(vb_IntAuxFrameReg(vi_CommonReg(vi_BadIntReg)),1,1)
                           end
      
                           ; set bad interpolation status and increase noise when found 
                           if ( n_NotValidIntReg gt 0 ) then begin
                              if ( keyword_set ( DEBUG ) ) then $
                                 debug_info, 'DEBUG INFO (calibrwave.pro): '+strg(n_NotValidIntReg)+$
                                             ' interpolated pixels have been interpolated from invalid pixels in set '+strg(i)+$
                                    ' spectrum '+strg(j)+','+strg(k) +' and get higher noise.'
                              vb_IntAuxFrameReg(vi_CommonReg(vi_NotValidReg)) = $
                                 setbit(vb_IntAuxFrameReg(vi_CommonReg(vi_NotValidReg)),1,1)
                                       vd_IntFrameReg(vi_CommonReg(vi_NotValidReg)) = $
                                 d_NoiseMultiplier * vd_IntFrameReg(vi_CommonReg(vi_NotValidReg))
                           end
      
                           ; consistency check, all inner pixel on the resampled grid shall have 0th
                           ; bit and 3rd bit = 1
                           if ( total( bool_invert( extbit ( vb_IntAuxFrameReg(vi_CommonReg),0 ) and $
                                                    extbit ( vb_IntAuxFrameReg(vi_CommonReg),3 )      ) ) ne 0 ) then $
                              warning, ['WARNING (calibrwave.pro): Not critical inconsistency (2) detected.', $
                                                 '                          Invalid pixel remained in interpolated spectrum.']
                        end
      
                        ; check minimum and maximum inside wavelength
                        if ( keyword_set ( DEBUG ) ) then begin
                           vi_C = where ( extbit ( vb_IntAuxFrameReg , 3 ), nn )
                           if ( nn gt 0 ) then $
                              debug_info, 'DEBUG INFO (calibrwave.pro): WL calibrated and inside '+$
                                 strg(min(vd_WLReg(vi_C)))+','+strg(max(vd_WLReg(vi_C)))
                        end
      
                     end
      
                  endif else $
                     warning, ['WARNING (calibrwave.pro): Too few valid pixels in common wavelength regime found ', $
                               '        for resampling in set ' + strg(i) + ' in spectrum ' +strg(j)+','+strg(k)]
               endif else $
                           warning, ['WARNING (calibrwave.pro): Too few pixels in common wavelength regime found ', $
                            '        for resampling in set ' + strg(i) + ' in spectrum ' +strg(j)+','+strg(k)]
      
            endif else $
               info, 'INFO (calibrwave.pro): Whoopsie daisy. Spectrum '+strg(j)+','+strg(k)+' has no valid wavelength calibration.' 

            ; insert the interpolated spectrum in the result frames
            md_FrameReg[*,j,k]       = vd_FrameReg
            md_IntFrameReg[*,j,k]    = vd_IntFrameReg
            mb_IntAuxFrameReg[*,j,k] = vb_IntAuxFrameReg

         end

      end

      ; free the old data and put the resampled data into place
      *p_Frames[i]       = md_FrameReg
      *p_IntFrames[i]    = md_IntFrameReg
      *p_IntAuxFrames[i] = mb_IntAuxFrameReg

      ; update header
      n_dims = size(*p_Frames[i])

      SXADDPAR, *p_Headers(i), "NAXIS", n_dims(0),AFTER='BITPIX'
      SXADDPAR, *p_Headers(i), "NAXIS1", n_dims(1),AFTER='NAXIS'
      SXADDPAR, *p_Headers(i), "NAXIS2", n_dims(2),AFTER='NAXIS1'
      SXADDPAR, *p_Headers(i), "NAXIS3", n_dims(3),AFTER='NAXIS2'

      sxdelpar, *p_Headers(i), 'CDELT1'
      sxdelpar, *p_Headers(i), 'CRVAL1'
      sxdelpar, *p_Headers(i), 'CRPIX1'
      sxdelpar, *p_Headers(i), 'CUNIT1'

      sxaddpar, *p_Headers(i), 'CDELT1', s_Res.d_RegDisp_nmperpix(0)
      sxaddpar, *p_Headers(i), 'CRVAL1', s_Res.d_RegMinWL_nm(0)
      sxaddpar, *p_Headers(i), 'CRPIX1', 1
      sxaddpar, *p_Headers(i), 'CUNIT1', 'nm'

   end

   if ( keyword_set ( DEBUG ) ) then $
      debug_info, 'DEBUG INFO (calibrwave.pro): Returning successfully'

   return, OK

end
