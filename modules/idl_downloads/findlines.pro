
COMMON FINDLINES_CONSTANTS, $
              i_DebugDelay                    ; wait i_DebugDelay seconds in each debugging step

;-------------------------------------------------------------------------------------------------------------------
; calculates the cross correlation lag

function findlines_cc, vd_ArtSpec, vd_Spec, vd_SpecWeights, i_MaxLag, DEBUG=DEBUG

   COMMON FINDLINES_CONSTANTS

   ; cross correlate artificial and measured spectrum
   vd_X = indgen(2*i_MaxLag)-i_MaxLag      ; define the lag

   ; weight the measured spectrum
   vd_CrossCor = c_correlate ( vd_ArtSpec, vd_Spec/vd_SpecWeights, vd_X )

   ; find maximum of cross correlation
   d_MaxCrossCor = max ( vd_CrossCor, i_CrossCor_px )

   if ( keyword_set ( DEBUG ) ) then begin
      plot, vd_X, vd_CrossCor, title='Cross Correlation'
      wait, i_DebugDelay
   end

   i_CrossCor_px = i_CrossCor_px - i_MaxLag

   return, i_CrossCor_px 

end

;-------------------------------------------------------------------------------------------------------------------
; do the wavelength calibration



function findlines, DataSet, nFrames, $
                    s_Lines, $             ; structure with the calibration lines
                    s_FiltParam, $         ; structure with filter info
                    s_Filter, $            ; the filter used

                    i_CCMaxLag_px, $       ; maximum allowed CC lag
                    b_CCMedianLag, $       ; median CC lags ?

                    s_LineFitFunction, $   ; fit function for mpfitpeak
                    n_LineFitTerms, $      ; order of individual line fitting, see e.g NTERMS of mpfitpeak
                    d_LineFitSigma_fact, $ ;

                    d_MinDiff_adu, $       ; min diff betwee mean and median of a spectrum
                    d_MinSigma_px, $       ; minimum sigma of the fit
                    d_MaxSigma_px, $       ; maximum sigma of the fit
                    d_MinFlux_adu, $       ; minimum flux of the fitted line

                    n_DispFitOrder, $      ; order of polynomial to fit
                    d_DispFitSigma_fact, $  
                    i_DispFitIter, $        

                    FILE = FILE, $         ; save the summed dataset to FILE (FILE has .fits extension) 
                                           ;   and save a report to FILE(without .fits).ps
                    NOFHP = NOFHP, $       ; instead of using the filter halfpoints use the app. wavelength
                                           ;  range given in the filter file (col
                                           ;  8 and 9
                    DEBUG = DEBUG          ; initialize debugging mode

    COMMON ERROR_CONSTANTS
    COMMON FINDLINES_CONSTANTS


    functionName = 'findlines.pro'
    i_DebugDelay = 3.                 ; wait i_DebugDelay seconds in each debugging step
    n_Dims       = size ( *DataSet.Frames(0) )

    i_SLX        = 0 
    i_SUX        = n_Dims(2)-1
    i_SLY        = 0
    i_SUY        = n_Dims(3)-1

    if ( keyword_set ( DEBUG ) ) then begin
       if ( n_elements(DEBUG) eq 2 ) then begin
          info, 'INFO (' + functionName + '): Debugging pixel ' + strg(DEBUG(0)) + ',' + strg(DEBUG(1)) + '.'
          i_SLX = DEBUG(0)>0<(n_Dims(2)-1)
          i_SUX = DEBUG(0)>0<(n_Dims(2)-1)
          i_SLY = DEBUG(1)>0<(n_Dims(3)-1)
          i_SUY = DEBUG(1)>0<(n_Dims(3)-1)
       endif else $
          return, error ('ERROR IN CALL(' + functionName + '): DEBUG must be 0 or a two-element vector.')
      
    end

    ; ----------- cross correlation section

    ; ------ sum up the individual datasets
    pcd_Frame       = ptr_new(*DataSet.Frames[0])
    pcd_IntFrame    = ptr_new(*DataSet.IntFrames[0])
    pcb_IntAuxFrame = ptr_new(*DataSet.IntAuxFrames[0])

    for i=1, nFrames-1 do begin   ; sum up all the frames in DataSet

       vb_Status = frame_op( pcd_Frame, pcd_IntFrame, pcb_IntAuxFrame, '+', $
                             reverse(DataSet.Frames[i], 1), $
                             reverse(DataSet.IntFrames[i], 1), $
                             reverse(DataSet.IntAuxFrames[i], 1), 1, $
                             Debug=keyword_set(DEBUG) )

       if ( NOT bool_is_vector (vb_Status) ) then $
          return, error('FAILURE ('+strtrim(functionName)+'): Operation on frame '+strg(i)+' failed (1).') 

       if ( vb_Status(0) ne 1 ) then $
          return, error('FAILURE ('+strtrim(functionName)+'): Operation on frame '+strg(i)+' failed (2).') 

    endfor

    if ( keyword_set ( FILE ) ) then begin
       ; save the summed dataset
       writefits, FILE, float(*pcd_Frame), *DataSet.Headers[0]
       writefits, FILE, float(*pcd_IntFrame), /APPEND
       writefits, FILE, byte(*pcb_IntAuxFrame), /APPEND
       info, 'INFO (' + functionName + '): File ' + FILE + ' successfully written.'
       fits_help, FILE
    endif else $
       FILE = 'findlines.fits'

    ; ------ create the artificial spectrum for the cc

    ; get the names of lamps that are switched on
    vs_Lamps = findlines_get_lamp_status ( DataSet.Headers, nFrames )
    info, 'INFO (' + functionName + '): Running CC with species ' + strjoin(vs_Lamps,', ')

    ; AS : Artificial spectrum

    ; the spectrums x-axis in pixel
    vi_AS_px  = dindgen(n_Dims(1)) 
    ; the spectrums x-axis in microns as a first estimate
    vd_AS_um  = vi_AS_px * s_FiltParam.d_Disp_nmperpix/1.d3 + s_FiltParam.d_MinWL_nm/1.d3
    ; the artificial spectrum
    vd_AS_adu = fltarr(n_Dims(1))

    ; app. wavelength range of the cube
;    vd_Range_um = [min(vd_AS_um), max(vd_AS_um)]
;    vd_Range_um = [ s_FiltParam.d_FilterHalfPointLow_nm/1.d3, s_FiltParam.d_FilterHalfPointUp_nm/1.d3 ]

    if ( keyword_set (NOFHP) ) then $
       vd_Range_um = [ s_FiltParam.d_MinWL_nm/1.d3, s_FiltParam.d_MaxWL_nm/1.d3 ] $
    else $
       vd_Range_um = [ s_FiltParam.d_FilterHalfPointLow_nm/1.d3, s_FiltParam.d_FilterHalfPointUp_nm/1.d3 ]

    ; only take lines within spectral range
    vi_ASMask = findlines_get_index ( s_Lines, WAVE = vd_Range_um, NAME = vs_Lamps )
    n_AS      = n_elements ( vi_ASMask )
    info, 'INFO (' + functionName + '): Artificial spectrum : Found ' + strg(n_AS) + $
          ' calibration lines within FHP [' + $
          strg(vd_Range_um(0)) + ',' + strg(vd_Range_um(1)) + '] microns.'

    ; now create the artificial spectrum
    for i=0, n_AS-1 do begin
       vd_AS_adu = vd_AS_adu + $
                   gauss1 ( vd_AS_um, [ ( s_Lines.vd_WL_um (vi_ASMask) )(i), $
                                        s_FiltParam.d_FWHM_nm/1.d3, $
                                        ( s_Lines.vd_Int_adu (vi_ASMask) )(i) ] )

       info, 'INFO (' + functionName + '): Artificial spectrum : Line ' + (s_Lines.vs_Name(vi_ASMask))(i) + ' ' + $
          strg(i) + ' at ' + strg( (s_Lines.vd_WL_um (vi_ASMask))(i) ) + ' microns.'
    end

    ; normalize the artificial spectrum to integrated unity flux
    vd_AS_adu = vd_AS_adu/total(vd_AS_adu)
    if ( keyword_set ( DEBUG ) ) then begin
       plot, vd_AS_um, vd_AS_adu, title='Artificial spectrum'
       wait, i_DebugDelay
    end

    ; ------ initialize some variables

    ; dispersion flag
    mb_DispStat = make_array(/INT, n_Dims(2), n_Dims(3), VALUE=ERROR_DISPERSION_OK ) 

    if ( (strpos(strupcase(s_Filter),'BB') ne -1) ) then begin
       mb_DispStat(0,0)     = ERROR_DISPERSION_OUT   ; for these spectra nothing needs to be done
       mb_DispStat(16:*,0)  = ERROR_DISPERSION_OUT
       mb_DispStat(32:*,1)  = ERROR_DISPERSION_OUT
       mb_DispStat(48:*,2)  = ERROR_DISPERSION_OUT
       mb_DispStat(0:15,16) = ERROR_DISPERSION_OUT
       mb_DispStat(0:31,17) = ERROR_DISPERSION_OUT
       mb_DispStat(0:47,18) = ERROR_DISPERSION_OUT
    endif else begin
       mb_DispStat(0,0:31)  = ERROR_DISPERSION_OUT
       mb_DispStat(1,0:15)  = ERROR_DISPERSION_OUT
       mb_DispStat(17:*,0)  = ERROR_DISPERSION_OUT
       mb_DispStat(33:*,1)  = ERROR_DISPERSION_OUT
       mb_DispStat(49:*,2)  = ERROR_DISPERSION_OUT
       mb_DispStat(0:15,48) = ERROR_DISPERSION_OUT
       mb_DispStat(0:31,49) = ERROR_DISPERSION_OUT
       mb_DispStat(0:47,50) = ERROR_DISPERSION_OUT
       mb_DispStat(65,19:*) = ERROR_DISPERSION_OUT
       mb_DispStat(64,35:*) = ERROR_DISPERSION_OUT
    end

    ; cross correlation lag
    mi_CCLag_px = intarr(n_Dims(2), n_Dims(3))

    ; ------ now do the cross correlation with the artificial spectrum

    ; loop over the individual spectra to determine the lag first
    for i1=i_SLX, i_SUX do begin

       for i2=i_SLY, i_SUY do begin

          if ( mb_DispStat[i1,i2] eq ERROR_DISPERSION_OK ) then begin

             ; find where the spectrum is valid
             vi_Valid = where ( valid ( (*pcd_Frame)(*,i1,i2), $
                                        (*pcd_IntFrame)(*,i1,i2), $
                                        (*pcb_IntAuxFrame)(*,i1,i2) ), n_Valid )

            if ( n_Valid gt 0 ) then begin

               ; determine mean and median intensity of spectrum
               d_Mean   = mean((*pcd_Frame)(vi_Valid,i1,i2))
               d_Median = median((*pcd_Frame)(vi_Valid,i1,i2))

               if ( keyword_set ( DEBUG ) ) then $
                  debug_info, 'DEBUG INFO (' + functionName + '): Spectrum ' +strg(i1) + ',' + strg(i2) + $
                              ' Mean:'+ strg(d_Mean) + ' Median: '+strg(d_Median)
  
               ; only continue if mean and median differ by more than d_MinDiff_adu
               if ( abs(d_Mean - d_Median) ge d_MinDiff_adu ) then begin

                  ; determine the lag
                  mi_CCLag_px(i1,i2)  = findlines_cc ( vd_AS_adu(vi_Valid), reform((*pcd_Frame)(vi_Valid,i1,i2)), $
                                                       reform((*pcd_IntFrame)(vi_Valid,i1,i2)), i_CCMaxLag_px, $
                                                       DEBUG=keyword_set(DEBUG) )

                  if ( keyword_set ( DEBUG ) ) then begin
                     ; plot spectra
                     debug_info, 'DEBUG INFO (' + functionName + '): CC gives lag of ' + strg(mi_CCLag_px(i1,i2))
                     plot, vd_AS_um, vd_AS_adu, title='Artificial spectrum and measured spectrum (red)'
                     oplot, vd_AS_um, reform((*pcd_Frame)(vi_Valid,i1,i2))/total((*pcd_Frame)(vi_Valid,i1,i2)), color=1
                     for i=0, n_AS-1 do $
                        xyouts, (s_Lines.vd_WL_um (vi_ASMask))(i), (!Y.CRANGE(1)-!Y.CRANGE(0))/2. , $
                           (s_Lines.vs_Name(vi_ASMask))(i), color=2
                     wait, i_DebugDelay
                  end

                  ; check if lag is smaller than the defined limit
                  if ( abs(mi_CCLag_px(i1,i2)) lt i_CCMaxLag_px ) then begin
  
                     if ( keyword_set ( DEBUG ) ) then begin
                        plot, vi_AS_px, vd_AS_adu, title='Shifted Artificial spectrum and row spectrum (red)'
                        oplot, vi_AS_px-mi_CCLag_px(i1,i2), $
                               reform((*pcd_Frame)(vi_Valid,i1,i2))/total((*pcd_Frame)(vi_Valid,i1,i2)), color=1

                        wait, i_DebugDelay
                     end
        
                  endif else begin
                     warning, 'WARNING (' + functionName + '): Determined lag (' + $
                              strg(mi_CCLag_px(i1,i2)) + ') exceeds limit in ' + $
                              strg(i1) + ',' + strg(i2)
                     mb_DispStat[i1,i2] = ERROR_DISPERSION_LAG
                  end

               endif else begin
                  warning, 'WARNING (' + functionName + '): Not enough intensity (mean:' + strg(d_Mean) + $
                           ', median:' + strg(d_Median) + ') in ' + strg(i1) + ',' + strg(i2) + '.'
                  mb_DispStat[i1,i2] = ERROR_DISPERSION_NOINT
               end

            endif else begin
               warning, 'WARNING (' + functionName + '): No valid pixels in spectrum ' + $
                        strg(i1) + ',' + strg(i2) + ' .'
               mb_DispStat[i1,i2] = ERROR_DISPERSION_NOPIX
            end

         end

      end

   end

   info,'INFO (' + functionName + '): All Lags determined.'

   ; ------ correct lag which exceed limit with median lag or use medianed lag for all spectra
   i_MedCCLag = median(mi_CCLag_px)
   if ( b_CCMedianLag eq 1 ) then begin
      mi_CCLag_px[*,*]    = i_MedCCLag
      mb_DispStat[*,*] = ERROR_DISPERSION_OK
      info,'INFO (' + functionName + '): Setting CC lags to median CC lag: ' + strg(i_MedCCLag) + ' px'
   endif else begin
      ; set median lag where lag exceeded limit
      n = 0
      for i1=i_SLX, i_SUX do begin
         for i2=i_SLY, i_SUY do begin
            if ( mb_DispStat[i1,i2] eq ERROR_DISPERSION_LAG ) then begin
               mb_DispStat[i1,i2] = ERROR_DISPERSION_OK
               mi_CCLag_px[i1,i2]    = i_MedCCLag
               n                  = n + 1
               if ( keyword_set ( DEBUG ) ) then $
                  debug_info, 'DEBUG INFO (' + functionName + '): Correcting CC lag in pixel ' + $
                     strg(i1) + ',' + strg(i2) + '.'
            end
         end
      end
      info, 'INFO (' + functionName + '): CC lag corrected for ' + strg(n) + ' spectra.'
   end

   ; ----------- individual line fitting
  
   ; ----- determine the lines to fit for each frame

   ; CL : Calibration Lines
   vi_CL_frame = [ -1 ]     ; indicates frame number
   vd_CL_um    = [ -1. ]    ; mu of cal line
   vi_CL_px    = [ -1 ]     ; app pixel pos of cal line in spectrum
   vs_CL_Name  = [' ']      ; species

   if ( keyword_set (NOFHP) ) then $
      vd_Range_um = [ s_FiltParam.d_MinWL_nm/1.d3, s_FiltParam.d_MaxWL_nm/1.d3 ] $
   else $
      vd_Range_um = [ s_FiltParam.d_FilterHalfPointLow_nm/1.d3, s_FiltParam.d_FilterHalfPointUp_nm/1.d3 ]

   if ( vd_Range_um(0) ge vd_Range_um(1) ) then $
      return, error ('ERROR (' + functionName + '): Wavelength limits in filter file are inconsistent.')

   ; loop over the input sets
   for i=0, nFrames-1 do begin

      ; get the lamp
      vs_Lamps = findlines_get_lamp_status ( DataSet.Headers(i), 1 )   ; e.g. ['NE']
      ; get the calibration lines
      vi_Mask  = findlines_get_index ( s_Lines, WAVE = vd_Range_um, NAME = vs_Lamps )

      if ( bool_is_vector ( vi_Mask ) ) then $   ; findlines_get_index returned with some lines
         n_Mask = n_elements ( vi_Mask ) $ ; number of lines in range
      else n_Mask = 0

      info, 'INFO (' + functionName + '): Line fitting : Found ' + strg(n_Mask) + ' ' + strjoin(vs_Lamps,', ') + $
            ' lines within [' + strg(vd_Range_um(0)) + ','+strg(vd_Range_um(1))+'] microns.'

      if ( n_Mask gt 0 ) then begin

         ; calibration lines in range
         vd_CLi_um   = s_Lines.vd_WL_um (vi_Mask)
         vd_CLi_adu  = s_Lines.vd_Int_adu (vi_Mask)
         vs_CLi_Name = s_Lines.vs_Name (vi_Mask)

         ; sort out lines that are too close together 
         d_FitWindowSize = 1.25 * d_LineFitSigma_fact * s_FiltParam.d_FWHM_nm/1.d3
         ; the 1.25 takes into account the recentering of the fit window
         vb_Valid = intarr(n_Mask) + 1
         for j=0, n_Mask-2 do $
            if ( abs(vd_CLi_um(j) - vd_CLi_um(j+1)) lt d_FitWindowSize ) then begin
               warning, 'WARNING: Omitting line '+strg(j)+' at '+$
                        strg(vd_CLi_um(j))+' and line '+strg(j+1)+' at '+ strg(vd_CLi_um(j+1))
               vb_Valid(j:j+1) = 0
            end
         vi_Valid = where (vb_Valid eq 1, n_Valid)

         if ( n_Valid gt 0 ) then begin

            ; wavelengths of lines that are seperate enough and will be fitted
            vi_CL_frame = [vi_CL_frame, intarr(n_Valid) + i]
            vd_CL_um    = [vd_CL_um, vd_CLi_um(vi_Valid)]
            vi_CL_px    = [vi_CL_px, intarr(n_Valid)]        ; approximate position of the cal line
            vs_CL_Name  = [vs_CL_Name, vs_CLi_Name(vi_Valid)]

         endif else $
            info, 'INFO (' + functionName + '): No seperated lines in frame ' + strg(i) + '.'

      endif else $
         info, 'INFO (' + functionName + '): No lines in frame ' + strg(i) + '.'

   end

   n_Lines = n_elements ( vi_CL_frame ) - 1 
   if ( n_Lines lt n_DispFitOrder+1 ) then $
      return, error ('FAILURE (' + functionName + '): Too few single lines (' + strg(n_Lines) + $
                     ') found for wavelength calibration of order ' + strg(n_DispFitOrder) + '.')

   vi_CL_frame = vi_CL_frame(1:*)
   vd_CL_um    = vd_CL_um(1:*) 
   vi_CL_px    = vi_CL_px(1:*)   
   vs_CL_Name  = vs_CL_Name(1:*) 
   
   ; determine app. pixel position of cal line in spectrum
   for i=0, n_Lines-1 do $
      vi_CL_px(i) = my_index( vd_AS_um, vd_CL_um(i) )

   for i=0, n_Lines-1 do $
      info, 'INFO (' + functionName + '): Individual Set : ' + strg(vi_CL_frame(i)) + ', Identified ' + strg(vs_CL_Name(i)) + $
            ' line ' + strg(i) + ' at pixel ' + strg(vi_CL_px(i)) + ' with ' + strg(vd_CL_um(i)) + ' microns.'

   ; ----- now do the fit

   ; define the result variables
   cb_LineStat        = make_array(/INT, n_Dims(2), n_Dims(3), n_Lines, VALUE=ERROR_SINGLE_LINE_OK )
   mi_LineValid       = intarr(n_Dims(2), n_Dims(3))
   cd_LineFitCoeff    = dblarr(n_Dims(2), n_Dims(3), 4, n_Lines)  ; scale, center, sigma, chi2
   cd_LineFitCoeffErr = dblarr(n_Dims(2), n_Dims(3), 3, n_Lines)  ; error scale, eror center, error sigma

   ; loop over the input sets
   for i0=0, nFrames-1 do begin

      vb_Frame = where ( vi_CL_frame eq i0, n_Linesi )

      if ( n_Linesi gt 0 ) then begin

         vi_Frame = vi_CL_frame(vb_Frame)
         vd_um    = vd_CL_um(vb_Frame) 
         vi_px    = vi_CL_px(vb_Frame)   
         vs_Name  = vs_CL_Name(vb_Frame) 

         ; loop over the individual spectra
         for i1=i_SLX, i_SUX do begin

            for i2=i_SLY, i_SUY do begin

               if ( mb_DispStat[i1,i2] eq ERROR_DISPERSION_OK ) then begin

                  ; find where the pixels are valid
                  vi_Mask = where ( valid ( (*DataSet.Frames(i0))(*,i1,i2), $
                                            (*DataSet.IntFrames(i0))(*,i1,i2), $
                                            (*DataSet.IntAuxFrames(i0))(*,i1,i2) ), n_Valid )

                  if ( n_Valid gt 0 ) then begin

                      ; loop over the individual lines
                      for j=0, n_Linesi-1 do begin

                        s_Txt = 'Set ' + strg(i0) + ' ' + strg(vs_Name(j)) + '-Line ' + strg(j) + ' at ' + $
                                strg(vd_um(j)) + 'mu in ' + strg(i1) + ',' + strg(i2)

                        ; determine the position of the line
                        lj = fix(vi_px(j) - d_LineFitSigma_fact * s_FiltParam.d_FWHM_nm / $
                                s_FiltParam.d_Disp_nmperpix + mi_CCLag_px(i1,i2) )
                        uj = fix(vi_px(j) + d_LineFitSigma_fact * s_FiltParam.d_FWHM_nm / $
                                s_FiltParam.d_Disp_nmperpix + mi_CCLag_px(i1,i2) )

                        if ( lj ge 0 and lj lt n_Dims(1) and uj ge 0 and uj lt n_Dims(1) and lj le uj ) then begin
   
                           if ( keyword_set ( DEBUG ) ) then $
                              debug_info, 'DEBUG INFO (' + functionName + '): Fit of valid line ' + $
                                          strg(vb_Frame(j))+' at ' + strg(vd_um(j)) + 'mu from ' + strg(lj) + ' to ' + strg(uj)

                           vd_X    = float(vi_AS_px(lj:uj))
                           vd_Y    = (*DataSet.Frames(i0))(lj:uj,i1,i2)
                           vd_N    = (*DataSet.IntFrames(i0))(lj:uj,i1,i2)
                           vi_Mask = where ( valid ( (*DataSet.Frames(i0))(lj:uj,i1,i2), $
                                                     (*DataSet.IntFrames(i0))(lj:uj,i1,i2), $
                                                     (*DataSet.IntAuxFrames(i0))(lj:uj,i1,i2) ), n_ValidLineMask )

                           if ( n_ValidLineMask gt 4 ) then begin

                              ; first determine the COI of the line to center the fit window.
                              vi_MaskPos = where ( vd_Y gt 0., n_Pos )

                              if ( n_Pos eq 0 ) then begin
                                 i_DCOI = 0
                              endif else begin  
                                 i_COI = fix(total(vd_X(vi_MaskPos)*vd_Y(vi_MaskPos))/total(vd_Y(vi_MaskPos)))
                                 i_DCOI = i_COI - fix((max(vd_X)+min(vd_X))/2)
                              end

                              if ( abs(i_DCOI) lt (uj-lj) ) then begin

                                 lj     = lj + i_DCOI
                                 uj     = uj + i_DCOI

                                 if ( keyword_set ( DEBUG ) ) then $
                                    debug_info, 'DEBUG INFO (' + functionName + '): Recentered Fit of valid line ' + $
                                       strg(vb_Frame(j)) + ' at ' + strg(vd_um(j)) + 'mu from ' + strg(lj) + ' to ' + $
                                       strg(uj) + ' (DCOI:' + strg(i_DCOI) + ').'

                                 if ( lj ge 0 and lj lt n_Dims(1) and uj ge 0 and $
                                      uj lt n_Dims(1) and lj le uj ) then begin
  
                                    vd_X    = float(vi_AS_px(lj:uj))
                                    vd_Y    = (*DataSet.Frames(i0))(lj:uj,i1,i2)
                                    vd_N    = (*DataSet.IntFrames(i0))(lj:uj,i1,i2)
                                    vi_Mask = where ( valid ( (*DataSet.Frames(i0))(lj:uj,i1,i2), $
                                                              (*DataSet.IntFrames(i0))(lj:uj,i1,i2), $
                                                              (*DataSet.IntAuxFrames(i0))(lj:uj,i1,i2) ) , $
                                                      n_ValidLineMask )

                                    if ( n_ValidLineMask gt 4 ) then begin
                                       ; fit the individual line
                                       vd_Fit = mpfitpeak ( vd_X(vi_Mask), vd_Y(vi_Mask), vd_Coeff, $
                                                      NTERMS=n_FitTerms, $
                                                      GAUSSIAN=s_LineFitFunction eq "GAUSSIAN", $
                                                      LORENTZIAN=s_LineFitFunction eq "LORENTZIAN", $
                                                      MOFFAT=s_LineFitFunction eq "MOFFAT", $
                                                      MEASURE_ERRORS = vd_N(vi_Mask), perror=vd_Errors )

                                       if ( n_elements(vd_Errors) ne 0 ) then begin

                                          if ( vd_Coeff(0) gt d_MinFlux_adu ) then begin

                                             if ( vd_Coeff(2) ge d_MinSigma_px and $
                                                  vd_Coeff(2) le d_MaxSigma_px ) then begin

                                                if ( vd_Coeff(1) ge lj and vd_Coeff(1) le uj ) then begin

                                                   cd_LineFitCoeff(i1,i2,*,vb_Frame(j)) = [ vd_Coeff(0:2), $
                                                                           total( (vd_Fit - vd_Y(vi_Mask))^2 ) ]
                                                   cd_LineFitCoeffErr(i1,i2,*,vb_Frame(j)) = [ vd_Errors(0), $
                                                        vd_Errors(1)*s_FiltParam.d_Disp_nmperpix/1.d3, vd_Errors(2) ]
                                                endif else begin
                                                   warning, ['WARNING (' + functionName + '): ' + s_Txt + $
                                                       ': Fitted center out of fit window. Line exists ?']
                                                   cb_LineStat[i1,i2,vb_Frame(j)] = ERROR_SINGLE_LINE_COIOUT
                                                end

                                             endif else begin
                                                warning, 'WARNING (' + functionName + '): ' + s_Txt + $
                                                   ': Fitted line width exceeds limits: '+ strg(d_MinSigma_px)+'<='+$
                                                         strg(vd_Coeff(2)) + '<=' + strg(d_MaxSigma_px)
                                                cb_LineStat[i1,i2,vb_Frame(j)] = ERROR_SINGLE_LINE_SIGMA
                                             end

                                          endif else begin
                                             warning, 'WARNING (' + functionName + '): ' + s_Txt + $
                                                ': Fitted Flux lower than flux limit ' + $
                                                strg(vd_Coeff(0)) + ' < ' + strg(d_MinFlux_adu) + '.'
                                             cb_LineStat[i1,i2,vb_Frame(j)] = ERROR_SINGLE_LINE_FLUX
                                          end

                                          if ( keyword_set ( DEBUG ) ) then begin
                                             vs_Title = s_Txt + s_LineFitFunction + ' Scale: '+strg(vd_Coeff(0)) + $
                                                ' Center: ' + strg(vd_Coeff(1)) + '+-' + $
                                                strg(vd_Errors(1)) + ' Sigma: ' + strg(vd_Coeff(2)) + $
                                                ' Lag:' + strg(mi_CCLag_px(i1,i2)) + ', DCOI:' + strg(i_DCOI)
 
                                             if ( cb_LineStat[i1,i2,vb_Frame(j)] eq ERROR_SINGLE_LINE_OK ) then $
                                                plot, vd_X(vi_Mask),vd_Y(vi_Mask), psym=2, title=vs_Title, /XST $
                                             else $
                                                plot, vd_X(vi_Mask),vd_Y(vi_Mask), psym=2, title=vs_Title, /XST, color=1
                                             oplot, vd_X(vi_Mask),vd_Fit
                                             oploterr, vd_X(vi_Mask),vd_Y(vi_Mask), vd_N(vi_Mask)
                                             debug_info, 'DEBUG INFO (' + functionName + '): Scale: ' + $
                                                strg(vd_Coeff(0)) + ' Center: ' + strg(vd_Coeff(1)) + $
                                                ' Sigma: ' + strg(vd_Coeff(2))
                                             wait, i_DebugDelay
                                          end

                                       endif else begin
                                          warning, 'WARNING (' + functionName + '): ' + s_Txt + ': Fit Failed.'
                                          cb_LineStat[i1,i2,vb_Frame(j)] = ERROR_SINGLE_LINE_FAILED
                                       end

                                    endif else begin
                                       warning, 'WARNING (' + functionName + '): ' + s_Txt + $
                                          ': too few valid pixels after recentering found for fitting.'
                                       cb_LineStat[i1,i2,vb_Frame(j)] = ERROR_SINGLE_LINE_FEW
                                    end

                                 endif else begin
                                    warning, 'WARNING (' + functionName + '): ' + s_Txt + $
                                       ': Recentered fit window invalid.'
                                    cb_LineStat[i1,i2,vb_Frame(j)] = ERROR_SINGLE_LINE_WINDOW
                                 end

                              endif else begin
                                 warning, 'WARNING (' + functionName + '): ' + s_Txt + $
                                    'Shift to recenter fit window exceeds window width.'
                                 cb_LineStat[i1,i2,vb_Frame(j)] = ERROR_SINGLE_LINE_WINDOW
                              end

                           endif else begin
                              warning, 'WARNING (' + functionName + '): ' + s_Txt + $
                                 ': too few valid pixels before recentering found for fitting.'
                              cb_LineStat[i1,i2,vb_Frame(j)] = ERROR_SINGLE_LINE_NOCOI
                           end

                        endif else begin
                           warning, 'WARNING (' + functionName + '): ' + s_Txt + ': too close to edge of spectrum.'
                           cb_LineStat[i1,i2,vb_Frame(j)] = ERROR_SINGLE_LINE_OUT
                        end
                    end ; loop pover individual lines

                    ; for safety we have to check whether a line has been identified twice or more

                    i_MinDist_px = 2

                    vi_MaskValid = where ( cb_LineStat[i1,i2,*] eq ERROR_SINGLE_LINE_OK, n_MaskValid )

                    if ( n_MaskValid gt 0 ) then begin    ; at least one line was fitted

                       for j1=0, n_Linesi-1 do begin
                          for j2=0, n_Linesi-1 do begin

                             if ( cb_LineStat[i1,i2,vb_Frame(j1)] eq ERROR_SINGLE_LINE_OK and $
                                  cb_LineStat[i1,i2,vb_Frame(j2)] eq ERROR_SINGLE_LINE_OK and $
                                  j1 ne j2) then begin
                                if ( abs ( cd_LineFitCoeff(i1,i2,1,vb_Frame(j1)) - $
                                           cd_LineFitCoeff(i1,i2,1,vb_Frame(j2)) ) lt i_MinDist_px ) then begin
                                   ; the fitted distances of two different line is less than
                                   ; i_MinDist_px. Misidentification
                                   cb_LineStat[i1,i2,vb_Frame(j1)] = ERROR_SINGLE_LINE_COIERROR
                                   cb_LineStat[i1,i2,vb_Frame(j2)] = ERROR_SINGLE_LINE_COIERROR
 
                                   warning, 'WARNING (' + functionName + '): Dynamic recentering of fit window may have lead to multiple identification of the same line.'
                                   warning, '         pixel pos. ' + strg(cd_LineFitCoeff(i1,i2,1,vb_Frame(j1))) + $
                                            ' and ' + strg(cd_LineFitCoeff(i1,i2,1,vb_Frame(j2))) + $
                                            '. Ignoring these line.'
                               end
                             end
                          end
                       end

                    end

                end ; too few valid pixel
             end ; DISPERSION_OUT
          end ; loop over spectra
       end ; loop over spectra
     endif else $
        info, 'INFO (' + functionName + '): No lines to fit in set ' + strg(i0) + '.'
   end ; loop over frames

   info, 'INFO (' + functionName + '): Individual emission lines search completed.'

   ; ----------- now determine the dispersion functions

   ; fit coefficients of the dispersion relation   
   cd_DispFitCoeff    = dblarr(n_Dims(2), n_Dims(3), n_DispFitOrder+1 )
   ; errors of fit coefficients of the dispersion relation
   cd_DispFitCoeffErr = dblarr(n_Dims(2), n_Dims(3), n_DispFitOrder+1 )

   for i1=i_SLX, i_SUX do begin

      for i2=i_SLY, i_SUY do begin

         if ( mb_DispStat[i1,i2] eq ERROR_DISPERSION_OK ) then begin

            vi_FitLine = where ( reform(cb_LineStat(i1,i2,*)) eq ERROR_SINGLE_LINE_OK, n_LineValid )

            if ( keyword_set ( DEBUG ) ) then $
               debug_info, 'DEBUG INFO (' + functionName + '): Fitted succesfully ' + $
                  strg(n_LineValid) + ' lines.'

            if ( n_LineValid ge n_DispFitOrder+1 ) then begin
               ; do the fit

               vd_X = reform(cd_LineFitCoeff(i1,i2,1,vi_FitLine))/100.d
               vd_Y = double(vd_CL_um(vi_FitLine))
               vd_S = double(reform(cd_LineFitCoeffErr(i1,i2,1,vi_FitLine)))

               vi_LinesValid = [1.]
               v_Res = sigma_poly_fit( vd_X, vd_Y, fltarr(n_elements(vd_Y))+1., $
                                       n_DispFitOrder, d_DispFitSigma_fact, d_DispFitSigma_fact, $
                                       i_DispFitIter, DEBUG = keyword_set(DEBUG), INDEX=vi_LinesValid )
               v_Errors = v_Res

               vi_MaskInvalid = where(vi_LinesValid eq 0, n_MaskInvalid)
               if ( n_MaskInvalid gt 0 ) then $
                  cb_LineStat(i1,i2,vi_FitLine(vi_MaskInvalid)) = ERROR_SINGLE_LINE_ITERATION_FAILED

               mi_LineValid[i1,i2] = total(vi_LinesValid)

               ; check 
               if ( bool_is_vector ( v_Res ) ) then begin

                  cd_DispFitCoeff(i1,i2,*)    = v_Res / 100.d^findgen(n_elements(v_Res))
                  cd_DispFitCoeffErr(i1,i2,*) = v_Errors

                  if ( keyword_set ( DEBUG ) ) then begin
                     vs_Title = ''
                     for k=0, n_DispFitOrder do vs_Title = vs_Title + strg(cd_DispFitCoeff(i1,i2,k)) + '  '

                     vi_Ar = where ( vs_CL_Name(vi_FitLine) eq 'AR', nar )
                     vi_Kr = where ( vs_CL_Name(vi_FitLine) eq 'KR', nkr )
                     vi_Xe = where ( vs_CL_Name(vi_FitLine) eq 'XE', nxe )
                     vi_Ne = where ( vs_CL_Name(vi_FitLine) eq 'NE', nne )

                     plot, vd_X*100.d, vd_CL_um(vi_FitLine), $
                        psym=2, title = strg(i1) + ' ' + strg(i2) + ' Coeff:' + vs_Title, /yst, /nodata

                     if ( nar gt 0 ) then $
                        oplot, vd_X(vi_Ar)*100.d, (vd_CL_um(vi_FitLine))(vi_Ar), psym=2,symsize=2

                     if ( nkr gt 0 ) then $
                        oplot, vd_X(vi_Kr)*100.d, (vd_CL_um(vi_FitLine))(vi_Kr), psym=4,symsize=2

                     if ( nxe gt 0 ) then $
                        oplot, vd_X(vi_Xe)*100.d, (vd_CL_um(vi_FitLine))(vi_Xe), psym=5,symsize=2

                     if ( nne gt 0 ) then $
                        oplot, vd_X(vi_Ne)*100.d, (vd_CL_um(vi_FitLine))(vi_Ne), psym=6,symsize=2


                     oploterr, (vd_X)*100.d, vd_CL_um(vi_FitLine), vd_S
                     oplot, vi_AS_px, poly(vi_AS_px, cd_DispFitCoeff(i1,i2,*))

                     debug_info, 'DEBUG INFO (' + functionName + '): Found fit coefficients ' + vs_Title
                     for ii=0, n_elements(vi_FitLine)-1 do $
                        debug_info, 'DEBUG INFO (' + functionName + '): Found fit values ' + $
                           strg(cd_LineFitCoeff(i1,i2,0,vi_FitLine(ii))) + '   ' + $
                           strg(cd_LineFitCoeff(i1,i2,1,vi_FitLine(ii))) + $
                           '   ' + strg(cd_LineFitCoeff(i1,i2,2,vi_FitLine(ii))) + '   ' + $
                           strg(vd_CL_um(vi_FitLine(ii)))
                     wait, i_DebugDelay
                  end

               endif else begin
                  info, 'INFO (' + functionName + '): Failed to determine dispersion function in spectrum ' + $
                        strg(i1) + ',' + strg(i2) + '. SVDFIT failed.'
                  mb_DispStat[i1,i2] = ERROR_DISPERSION_SVDFIT
               end

            endif else begin
               info, 'INFO (' + functionName + '): Failed to determine dispersion function in spectrum ' + $
                    strg(i1) + ',' + strg(i2) + '. Too few valid lines found.'
               mb_DispStat[i1,i2] = ERROR_DISPERSION_FEW
            end
        end
      end
   end

   info ,'INFO (' + functionName + '): Dispersion functions determined.'

   cd_WMap = dblarr(n_Dims(1), n_Dims(2), n_Dims(3) )         ; wavelength cube
   ; calculate the wavelength map
   for i=i_SLX, i_SUX do $
      for j=i_SLY, i_SUY do $
         if ( mb_DispStat[i,j] eq ERROR_DISPERSION_OK ) then $
            cd_WMap(*,i,j) = poly( vi_AS_px, cd_DispFitCoeff(i,j,*) )

   info ,'INFO (' + functionName + '): Wavelength map determined.'

   ; residuals in mu
   n_Lines = n_elements(cd_LineFitCoeff(0,0,0,*))
   cd_Residuals_um = dblarr(n_Dims(2), n_Dims(3), n_Lines )
   ; now check the residuals
   for i=i_SLX, i_SUX do $
      for j=i_SLY, i_SUY do $
         if ( mb_DispStat[i,j] eq ERROR_DISPERSION_OK ) then begin
            for l=0, n_Lines-1 do begin
               cd_Residuals_um(i,j,l) = poly( cd_LineFitCoeff(i,j,1,l), $
                                              reform(cd_DispFitCoeff(i,j,*))) - vd_CL_um(l)
            end 

            if ( keyword_set ( DEBUG ) ) then begin

               vi_Mask = where ( cb_LineStat(i,j,*) eq ERROR_SINGLE_LINE_OK, n )

               vl = vd_CL_um(vi_Mask)
               vr = cd_Residuals_um(i,j,vi_Mask)*10000.
               vn = vs_CL_Name(vi_Mask)

               vi_Ar = where ( vn eq 'AR', nar )
               vi_Kr = where ( vn eq 'KR', nkr )
               vi_Xe = where ( vn eq 'XE', nxe )
               vi_Ne = where ( vn eq 'NE', nne )

               plot, vl, vr, title='Residuals in Angstroems', /nodata

               if ( nar gt 0 ) then oplot, vl(vi_Ar), vr(vi_Ar), psym=2,symsize=2
               if ( nkr gt 0 ) then oplot, vl(vi_Kr), vr(vi_Kr), psym=4,symsize=2
               if ( nxe gt 0 ) then oplot, vl(vi_Xe), vr(vi_Xe), psym=5,symsize=2
               if ( nne gt 0 ) then oplot, vl(vi_Ne), vr(vi_Ne), psym=6,symsize=2

            end
         end

   if ( not keyword_set ( DEBUG ) ) then begin

      ; print some statistics
      info, 'INFO (' + functionName + '): Summary'
      dummy = where ( mb_DispStat eq ERROR_DISPERSION_OK, n ) 
      info, 'INFO (' + functionName + '): '+strg(n)+' dispersion relations.'
      dummy = where ( mb_DispStat eq ERROR_DISPERSION_OUT, n ) 
      info, 'INFO (' + functionName + '): '+strg(n)+' spectra with no information.'
      dummy = where ( mb_DispStat eq ERROR_DISPERSION_NOPIX , n)
      info, 'INFO (' + functionName + '): '+strg(n)+' spectra with no valid pixels.'
      dummy = where ( mb_DispStat eq ERROR_DISPERSION_NOINT, n)
      info, 'INFO (' + functionName + '): '+strg(n)+' spectra with too low intensity.'
      dummy = where ( mb_DispStat eq ERROR_DISPERSION_FEW, n)
      info, 'INFO (' + functionName + '): '+strg(n)+' spectra with too few valid pixel.'
      dummy = where ( mb_DispStat eq ERROR_DISPERSION_SVDFIT, n)
      info, 'INFO (' + functionName + '): '+strg(n)+' spectra could not be fitted (SVDFIT).'

      dummy = where ( mb_DispStat eq ERROR_DISPERSION_OK, n )
      if ( n eq 0 ) then $
         return, error ( 'FAILURE (' + functionName + '): All dispersion fits failed.' )

      dummy = where ( mb_DispStat eq ERROR_DISPERSION_OUT, n_Out )
      n_All = n_Dims(2) * n_Dims(3)
      n_In  = n_All - n_Out

      info, 'INFO (findlines.pro): Line usage (after iteration) for '+strg(n_In)+' spectra:'
      for i=0, n_Lines-1 do begin
         vi_Mask = where ( cb_LineStat(*,*,i) eq ERROR_SINGLE_LINE_OK and mb_DispStat eq ERROR_DISPERSION_OK, n_Valid )
         info,'INFO (findlines.pro): Line '+strg(i)+' on average '+strg(n_Valid)+',  '+strg(fix(100.*n_Valid/n_In))+$
              '% used where fit was succesful.'
      end


      ; --- plot residuals

      info,'INFO (' + functionName + '): Residuals in Angstroem:'
      set_plot,'ps'
      device,file=strmid(FILE,0,strlen(FILE)-5)+'.ps',/color

      v_HX = (findgen(401)-200)*0.01

      vi_Sort = sort(vd_CL_um)
      vd_MedianRes = fltarr(n_Lines,2)

      for i=0, n_Lines-1 do begin
         ii = vi_Sort(i)
         vi_Mask = where ( mb_DispStat eq ERROR_DISPERSION_OK, n_Valid )
         if ( n_Valid gt 1 ) then begin
            d_Mean   = 10000.*mean( (cd_Residuals_um(*,*,ii))(vi_Mask) )
            d_Median = 10000.*median( (cd_Residuals_um(*,*,ii))(vi_Mask) )
            d_RMS    = 10000.*stddev( (cd_Residuals_um(*,*,ii))(vi_Mask) )
            info,'INFO (' + functionName + '): Line '+strg(ii) + ' at ' + strg(vd_CL_um(ii)) + '   all spectra ' + $
                 '   Mean:' + strmid(strg(d_Mean),0,6) + '   Median:' + strmid(strg(d_Median),0,6) + $
                 '   RMS:' + strmid(strg(d_RMS),0,6) + ' in ' + strg(n_Valid) + ' spectra.'

            v_HY = histogram ( 10000.*(cd_Residuals_um(*,*,ii))(vi_Mask), min=-2., max=2., binsize=0.01)

            plot, v_HX, v_HY, title='Res. of line ' + strg(ii) + ' at ' + strmid(strg(vd_CL_um(ii)),0,6) + $
                  'um in valid spectra in A ', xtitle = 'Residual [A]', ytitle = '# of pixel', charsize=0.7, psym=10

         end

         vi_Mask = where ( cb_LineStat(*,*,ii) eq ERROR_SINGLE_LINE_OK and mb_DispStat eq ERROR_DISPERSION_OK, n_Valid )
         if ( n_Valid gt 1 ) then begin
            d_Mean   = 10000.*mean( (cd_Residuals_um(*,*,ii))(vi_Mask) )
            d_Median = 10000.*median( (cd_Residuals_um(*,*,ii))(vi_Mask) )
            d_RMS    = 10000.*stddev( (cd_Residuals_um(*,*,ii))(vi_Mask) )
            info,'INFO (' + functionName + '): Line '+strg(ii) + ' at ' + strg(vd_CL_um(ii)) + ' valid spectra ' + $
                 '   Mean:' + strmid(strg(d_Mean),0,6) + '   Median:' + strmid(strg(d_Median),0,6) + $
                 '   RMS:' + strmid(strg(d_RMS),0,6) + ' in ' + strg(n_Valid) + ' spectra.'

            v_HY = histogram ( 10000.*(cd_Residuals_um(*,*,ii))(vi_Mask), min=-2., max=2., binsize=0.01)

            oplot, v_HX, v_HY, color=1, psym=10

            vd_MedianRes(i,1) = d_Median
            vd_MedianRes(i,0) = vd_CL_um(ii)

         end

      end

      plot, vd_MedianRes(*,0), vd_MedianRes(*,1), psym=2, $
         title='Median of valid residuals vs. Wavelength', xtitle='Lambda [micron]', ytitle='Residual [A]' 

      ; --- plot sigma

      info,'INFO (' + functionName + '): Sigma of line fits :'

      v_HX = d_MinSigma_px + findgen(fix((d_MaxSigma_px - d_MinSigma_px) / 0.01))*0.01

      vi_Sort = sort(vd_CL_um)
      vd_MedianSigma = fltarr(n_Lines,2)

      for i=0, n_Lines-1 do begin
         ii = vi_Sort(i)
         vi_Mask = where ( mb_DispStat eq ERROR_DISPERSION_OK, n_Valid )
         if ( n_Valid gt 1 ) then begin
            d_Mean   = mean( (cd_LineFitCoeff(*,*,2,ii))(vi_Mask) )
            d_Median = median( (cd_LineFitCoeff(*,*,2,ii))(vi_Mask) )
            d_RMS    = stddev( (cd_LineFitCoeff(*,*,2,ii))(vi_Mask) )
            info,'INFO (' + functionName + '): Line '+strg(ii) + ' at ' + strg(vd_CL_um(ii)) + '   all spectra ' + $
                 '   Mean:' + strmid(strg(d_Mean),0,6) + '   Median:' + strmid(strg(d_Median),0,6) + $
                 '   RMS:' + strmid(strg(d_RMS),0,6) + ' in ' + strg(n_Valid) + ' spectra.'

            v_HY = histogram ( (cd_LineFitCoeff(*,*,2,ii))(vi_Mask), min=d_MinSigma_px, max=d_MaxSigma_px, binsize=0.01)

            plot, v_HX, v_HY, title='Res. of line ' + strg(ii) + ' at ' + strmid(strg(vd_CL_um(ii)),0,6) + 'um in A ', $
               xtitle = 'Residual [A]', ytitle = '# of pixel', charsize=0.7, psym=10

         end

         vi_Mask = where ( cb_LineStat(*,*,ii) eq ERROR_SINGLE_LINE_OK and mb_DispStat eq ERROR_DISPERSION_OK, n_Valid )
         if ( n_Valid gt 1 ) then begin
            d_Mean   = mean( (cd_LineFitCoeff(*,*,2,ii))(vi_Mask) )
            d_Median = median( (cd_LineFitCoeff(*,*,2,ii))(vi_Mask) )
            d_RMS    = stddev( (cd_LineFitCoeff(*,*,2,ii))(vi_Mask) )
            info,'INFO (' + functionName + '): Line '+strg(ii) + ' at ' + strg(vd_CL_um(ii)) + ' valid spectra ' + $
                 '   Mean:' + strmid(strg(d_Mean),0,6) + '   Median:' + strmid(strg(d_Median),0,6) + $
                 '   RMS:' + strmid(strg(d_RMS),0,6) + ' in ' + strg(n_Valid) + ' spectra.'

            v_HY = histogram ( (cd_LineFitCoeff(*,*,2,ii))(vi_Mask), min=d_MinSigma_px, max=d_MaxSigma_px, binsize=0.01)

            oplot, v_HX, v_HY, color=1, psym=10

            vd_MedianSigma(i,1) = d_Median
            vd_MedianSigma(i,0) = vd_CL_um(ii)

         end

      end

      plot, vd_MedianSigma(*,0), vd_MedianSigma(*,1), psym=2, $
         title='Median of valid Sigmas vs. Wavelength', xtitle='Lambda [micron]', ytitle='Sigma [px]'

      device,/close
      set_plot,'x'

   end


   if ( keyword_set ( DEBUG ) ) then begin

      info , 'INFO (' + functionName + '): Residuals in Angstroem:'

      for i=i_SLX, i_SUX do $
         for j=i_SLY, i_SUY do $
            for l=0, n_Lines-1 do $
               info , 'INFO : ' + ((cb_LineStat(i,j,l) eq ERROR_SINGLE_LINE_OK) ? '     valid' : ' not valid') + ' Line ' + strg(l) + $
                      ' at ' + strg(vd_CL_um(l)) + 'um ' + strg(cd_Residuals_um(i,j,l)*10000.)
   end


   ; return the results
   return, { cd_WMap            : reverse(cd_WMap), $
             mb_DispStat        : mb_DispStat, $
             mi_CCLag           : mi_CCLag_px, $
             cd_DispFitCoeff    : cd_DispFitCoeff, $
             cd_DispFitCoeffErr : cd_DispFitCoeffErr, $
             cb_LineStat        : cb_LineStat, $
             mi_LineValid       : mi_LineValid, $
             cd_LineFitCoeff    : cd_LineFitCoeff, $
             cd_LineFitCoeffErr : cd_LineFitCoeffErr, $
             cd_Residuals_A     : cd_Residuals_um*10000. }

end

