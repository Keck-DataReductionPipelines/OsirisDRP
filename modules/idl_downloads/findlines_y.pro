
; calculates the cross correlation lag

function cross_correlate, vd_ArtSpec, vd_Spec, vd_SpecWeights, i_MaxLag, DEBUG=DEBUG

   if ( keyword_set(DEBUG) ) then d_Debug_Delay = DEBUG

   ; cross correlate artificial and measured spectrum
   vd_X        = indgen(2*i_MaxLag)-i_MaxLag      ; define the lag

   ; weight the measured spectrum
   vd_CrossCor = c_correlate ( vd_ArtSpec, vd_Spec/vd_SpecWeights, vd_X )

   ; find maximum of cross correlation
   d_MaxCrossCor = max ( vd_CrossCor, i_CrossCor_px )

   if ( keyword_set ( DEBUG ) ) then begin
      plot, vd_X, vd_CrossCor, title='Cross Correlation'
      wait, d_Debug_Delay
   end

   i_CrossCor_px = i_CrossCor_px - i_MaxLag

   return, i_CrossCor_px 

end




;-------------------------------------------------------------------------
; NAME: findlines
;
; PURPOSE: wavelength calibration
;
; INPUT : p_WFrame           : pointer or pointerarray with the frame values
;         p_WIntFrame        : pointer or pointerarray with the intframe values
;         p_WIntAuxFrame     : pointer or pointerarray with the quality values
;
;   Parameters checking the validness of a single spectrum
;         d_MinDiff          : minimum difference between the mean and
;                              the median of a spectrum
;   Parameters determining the calculation of the artificial spectrum
;         d_ArtSpecSigma_mu           : FWHM of the calibration lines =
;                                       FWHM of instrument spectral profile
;         d_ArtSpecBeginWave_um       : begin wavelength
;         d_ArtSpecDispersion_muperpx : initial estimate of dispersion
;         d_ArtSigmaDist_fact         : the calibration lines must
;                                       have a minimum distance of 
;                                       2.*d_ArtSigmaDist_fact*d_ArtSpecSigma_mu  
;                                       to be used for determining the
;                                       dispersion relation
;
;   Parameters determining the fit of a calibration line
;         vd_ArtLines_um     : wavelengths of calibration lines
;         vd_ArtLines_adu    : intensities of calibration lines
;         d_FitSigma_fact    : halfsize of the fit window
;         n_FitOrder         : order of the polynomial = # of
;                              coefficients - 1
;         s_FitFunction      : name of the fit function :
;                              "GAUSSIAN", "LORENTZIAN", "MOFFAT"
;         n_FitTerms         : see nterms of gaussfit
;
;   Parameters determining whether a calibration line shall be used
;   for calculating the dispersion relation
;         d_MinSigma_px         : FWHM of fit must be ge than d_MinSigma_px
;         d_MaxSigma_px         : FWHM of fit must be le than d_MaxSigma_px
;         d_MinFlux_adu         : Flux of fit must be ge than d_MinFlux_adu
;         d_MaxError_px         : Error of COI of fit mist be less than d_MaxError_px
;
;   Parameters determining the polynomial fit of the coefficients
;      The fit is done if this optional 4-element vector is supplied
;         [FitCoeff = [ d_loReject            : percentage (0.-1.) of low value
;                                               coefficient i to be thrown away 
;                       d_hiReject            : percentage (0.-1.) of high value
;                                               coefficient i to be thrown away 
;                       n_CoeffOrder          : order of polynomial to
;                                               fit to the coefficients
;                       d_Sigma               : sigma of iterative
;                                               sigma fit
;                       n_Max                 : maximum number of
;                                               iterations
;                       b_Debug               : initializes the
;                                               debugging mode
;                     ] ]
;
;   Other parameter
;
;         [DEBUG=DEBUG]              : initialize the debugging mode
;
; OUTPUT : wavelength map
;
; ALGORITHM : 1. creation of artificial spectrum consisting of the
;                lines in vd_ArtLines_um and vd_ArtLines_adu. 
;                Let n be the number of spectral channels.
;                The wavelength axis of the artificial spectrum :
;                   lambda = n*d_ArtSpecDispersion_muperpx + d_ArtSpecBeginWave_um
;                The artificial spectrum is the superposition of all
;                calibration lines folded by a gaussian with parameters
;                center : vd_ArtLines_um(i), sigma : d_ArtSpecSigma_mu, 
;                intensity : vd_ArtLines_adu(i)
;             2. Loop over the spectra
;                a. the absolute difference between the mean and
;                   median value of the spectrum computed
;                   from all valid pixels (acc. valid(/VALIDS)) must
;                   exceed d_MinDiff.
;                b. cross correlation of the measured and artificial
;                   spectrum. Determination of the lag that gives a
;                   maximum in the cc. The maximum lag is +- 30 pixel.
;                   So the wavelength of the 0th slice of a cube
;                   should be stated in filter_info.list.
;                c. Loop over the calibration lines:
;                   A line is searched within a window (in pixel)
;                      position of artificial line in pixel +-
;                      d_FitSigma_fact * sigma of artificial gaussian
;                      in pixel.
;                   The lines are fitted by a gaussian, lorentzian or
;                   moffat as indicated by s_FitFunction. The fit
;                   window is centered based on the lag of the cc and
;                   the should be position according to the artificial
;                   spectrum. At least 4 pixel in the fit window must 
;                   be valid (acc. to valid(\VALIDS)).
;                   The line is accepted if 
;                   - the error as determined by the fit of the COI is
;                     less than d_MaxError_px
;                   - the flux as determined by the fit is greater
;                     than d_MinFlux_adu
;                   - the sigma in pixel as determined by the fit is
;                     between d_MinSigma_px and d_MaxSigma_px
;                   - the COI as determined by the fit is within the
;                     fit window
;                d. a polynomial of order n_FitOrder is fitted to the
;                   determined COIs of the calibration lines using the
;                   errors determined by the fit (n_FitOrder = # of
;                   coefficients - 1)
;                e. if FITCOEFF = [ d_loReject, d_hiReject,
;                   n_CoeffOrder, d_Sigma, n_Max, b_Debug ] is
;                   supplied, each set of coefficient
;                   of order i of a x-slice is fitted with a
;                   polynomial of degree n_CoeffOrder.
;                   Before the fit valid coefficient values are
;                   clipped using d_loReject, d_hiReject. The fit
;                   itself is done iteratively where data values are
;                   not used for fitting if the value/coefficient is
;                   more far away from the fit than d_Sigma*standard
;                   deviation of the fit. The fit itself is done not
;                   more than n_Max times. b_Debug initializes the
;                   debugging process for this fit procedure only.
;                   With fitting the coefficients of the dispersion
;                   relation it is only possible to enhance the
;                   wavelength map. If a spectrum is marked as bad
;                   because the dispersion relation could not be
;                   determined, the spectrum is marked as bad after
;                   this fitting process as well.
;                f. the determined dispersion relation is calculated
;                   and stored to the wavelength map.
;
; NOTES : - This routine works on cubes only
;         - At that stage the inside bit is not set and therefore ignored.
;         - Before using this module only bright lines must be
;           selected from the list
;
; OUTPUT : let n be the number of calibration lines, i,j, the spatial
;          dims and k the number of spectral channels: 
;          
;
;          structure : { cd_WMap : cube with wavelengths for all
;                                  pixels, double[k,i,j]
;                        mb_WMap : image indicating whether the
;                                  wavelength calibration was
;                                  successful, byte[i,j]
;                        mi_Sing : spatial image with the number of
;                                  singular elements (elements that do
;                                  not represent the fit) int[i,j]
;                        mi_CCor : spatial image with the cross
;                                  correlation lag, int[i,j]
;                        mi_LineValid : number of calibration lines used
;                                  for determining the dispersion
;                                  relation, int[i,j]
;                        cd_Cent : center position in pixel of each
;                                  line, double[i,j,n]
;                        cd_Inte : fitted intensity, double[i,j,n]
;                        cd_Disp : fitted dipsersion in pixel, double[i,j,n]
;                        cd_Chi2 : Chi square of line fit, double[i,j,n]
;                        cd_CErr : error of fitted center position in
;                                  pixel, double[i,j,n]
;                        cd_Line : wavelength of the fitted
;                                  calibration line
;                        cb_Line : bool indicating whether a line has
;                                  been used for determining the
;                                  dispersion relation
;                        cd_FitCoeff       : Fit coefficients for all spectra
;                        cd_FitCoeffErrors : Errors of fit coefficients for all spectra }
;
;
; ON ERROR : returns ERR_UNKNOWN
;
; STATUS : untested
;
; HISTORY : 24.9.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-------------------------------------------------------------------------

function findlines_y, p_WFrame_, p_WIntFrame_, p_WIntAuxFrame_, d_MinDiff, $
                    d_ArtSpecSigma_mu, d_ArtSpecBeginWave_um, d_ArtSpecDispersion_muperpx, $
                    d_ArtSigmaDist_fact, vd_ArtLines_um, vd_ArtLines_adu, d_FitSigma_fact, $
                    n_FitOrder, s_FitFunction, n_FitTerms, d_MinSigma_px, d_MaxSigma_px, d_MinFlux_adu, $
                    d_MaxError_px, i_MaxLag, FitCoeff=FitCoeff, DEBUG = DEBUG

   COMMON ERROR_CONSTANTS

   WFrame         = reverse(*p_WFrame_)
   WIntFrame      = reverse(*p_WIntFrame_)
   WIntAuxFrame   = reverse(*p_WIntAuxFrame_)

   p_WFrame       = ptr_new( WFrame )
   p_WIntFrame    = ptr_new( WIntFrame )
   p_WIntAuxFrame = ptr_new( WIntAuxFrame )

   ; delay in seconds when in debugging mode
   if ( keyword_set(DEBUG) ) then d_Debug_Delay = DEBUG

   ; some parameter checks
   if ( NOT (s_FitFunction eq "GAUSSIAN" or s_FitFunction eq "LORENTZIAN" or s_FitFunction eq "MOFFAT") ) then $
      return, error('ERROR IN CALL (findlines.pro): Unknown fit function.')

   if ( NOT bool_is_cube (*p_WFrame) ) then $
      return, error('ERROR IN CALL (findlines.pro): Input frame is not a cube.')

   if ( NOT bool_is_cube (*p_WIntFrame) ) then $
      return, error('ERROR IN CALL (findlines.pro): Input intframe is not a cube.')

   if ( NOT bool_is_cube (*p_WIntAuxFrame) ) then $
      return, error('ERROR IN CALL (findlines.pro): Input intauxframe is not a cube.')

   if ( NOT bool_dim_match (*p_WFrame, *p_WIntFrame) or $
        NOT bool_dim_match (*p_WIntFrame, *p_WIntAuxFrame) ) then $
      return, error('ERROR IN CALL (findlines.pro): Input frames not compatible in size.')

   if ( d_MinDiff le 0. ) then $
      return, error('ERROR IN CALL (findlines.pro): d_MinDiff is le 0.')

   if ( d_ArtSpecBeginWave_um le 0. ) then $
      return, error('ERROR IN CALL (findlines.pro): d_ArtSpecBeginWave_um is le 0.')

   if ( d_ArtSpecDispersion_muperpx le 0. ) then $
      return, error('ERROR IN CALL (findlines.pro): d_ArtSpecDispersion_muperpx is le 0.')

   if ( d_FitSigma_fact le 0. ) then $
      return, error('ERROR IN CALL (findlines.pro): d_FitSigma_fact is le 0.')

   if ( n_FitOrder le 0 or n_FitOrder ge 6 ) then $
      return, error('ERROR IN CALL (findlines.pro): 0<n_FitOrder<6.')

   if ( n_FitTerms le 2 or n_FitTerms ge 7 ) then $
      return, error('ERROR IN CALL (findlines.pro): 3<=n_FitTerms<=6 ('+strg(n_FitTerms)+')')

   if ( d_MinSigma_px le 0 ) then $
      return, error('ERROR IN CALL (findlines.pro): d_MinSigma_px > 0')

   if ( d_MaxSigma_px le 0 ) then $
      return, error('ERROR IN CALL (findlines.pro): d_MaxSigma_px > 0')

   if ( d_MaxSigma_px le d_MinSigma_px ) then $
      return, error('ERROR IN CALL (findlines.pro): d_MinSigma_px < d_MaxSigma_px')

   if ( d_MinFlux_adu le 0 ) then $
      return, error('ERROR IN CALL (findlines.pro): d_MinFlux_adu > 0')

   if ( d_MaxError_px le 0 ) then $
      return, error('ERROR IN CALL (findlines.pro): d_MaxError_px > 0')

   if ( keyword_set ( FitCoeff ) ) then begin
      if ( n_elements ( FitCoeff ) ne 6 ) then $
         return, error('ERROR IN CALL (findlines.pro): FitCoeff must have 3 elements.')
      if ( FitCoeff(0) lt 0. or FitCoeff(0) gt 1. or FitCoeff(1) lt 0. or FitCoeff(1) gt 1. or $
           FitCoeff(0) gt FitCoeff(1) ) then $ 
         return, error ('ERROR IN CALL (findline.pro): loReject or hiReject has wrong limit.')
      if ( FitCoeff(2) lt 0 or FitCoeff(2) gt 6 ) then $
         return, error('ERROR IN CALL (findlines.pro): Order of FitCoeff must ge 0 and le 6.')
      if ( FitCoeff(3) lt 0 ) then $
         return, error('ERROR IN CALL (findlines.pro): Sigma must be positive.')
      if ( FitCoeff(4) lt 0 or FitCoeff(4) gt 10 ) then $
         return, error('ERROR IN CALL (findlines.pro): Maximum number of iterations must be less equal 10.')
   end

   ; parameter checks done

   if ( keyword_set ( DEBUG ) ) then begin
      debug_info, 'DEBUG INFO (findlines.pro): Fit function for lines is '+s_FitFunction
      debug_info, 'DEBUG INFO (findlines.pro): Order of polynomial for dispersion function is '+strg(n_FitOrder)
   end

   n_Dims = size ( *p_WFrame )

   ; size of the PSF in pixel
   i_Sigma_px = d_ArtSpecSigma_mu / d_ArtSpecDispersion_muperpx

   ; create artificial spectrum
   vi_ArtSpec_px  = indgen(n_Dims(1))
;print, n_Dims(1),d_ArtSpecDispersion_muperpx(0), d_ArtSpecBeginWave_um(0)
   vd_ArtSpec_um  = dindgen(n_Dims(1)) * d_ArtSpecDispersion_muperpx(0) + d_ArtSpecBeginWave_um(0)
   vd_ArtSpec_adu = fltarr(n_Dims(1))
   ; only take lines within range
   vi_LinesMask = where ( vd_ArtLines_um ge min(vd_ArtSpec_um) and vd_ArtLines_um le max(vd_ArtSpec_um), n_Lines )
   info, 'INFO (findlines.pro): Found '+strg(n_Lines)+' calibration lines within '+strg(min(vd_ArtSpec_um))+$
         ' and '+strg(max(vd_ArtSpec_um))+' microns.'

   if ( n_Lines le n_FitOrder ) then $
      return, error ('FAILURE (findlines.pro): Sorry too few lines found.')

   vd_ArtLines_um  = vd_ArtLines_um (vi_LinesMask)
   vd_ArtLines_adu = vd_ArtLines_adu (vi_LinesMask)

   for i=0, n_Lines-1 do $
      vd_ArtSpec_adu = vd_ArtSpec_adu + $
         gauss1 ( vd_ArtSpec_um, [vd_ArtLines_um(i), d_ArtSpecSigma_mu, vd_ArtLines_adu(i)] )

   vd_ArtSpec_adu = vd_ArtSpec_adu/total(vd_ArtSpec_adu)

   if ( keyword_set ( DEBUG ) ) then begin
      plot, vd_ArtSpec_um, vd_ArtSpec_adu, title='Artificial spectrum'
      wait,d_Debug_Delay
   end

   ; sort out lines that are too close together 
   b_ValidArtLines = intarr(n_Lines) + 1
   for i=0, n_Lines-2 do $
      if ( abs(vd_ArtLines_um(i) - vd_ArtLines_um(i+1)) lt d_ArtSigmaDist_fact*d_ArtSpecSigma_mu ) then $
         b_ValidArtLines(i:i+1) = 0
   vi_ValidArtLines = where (b_ValidArtLines, n_ValidArtLines)

   if ( keyword_set ( DEBUG ) ) then $
      for i=0, n_ValidArtLines-1 do $
         debug_info, 'DEBUG INFO (findlines.pro): Using line no.: '+strg(vi_ValidArtLines(i)) + $
            ' at ' + strg(vd_ArtLines_um(vi_ValidArtLines(i))) + ' mu with '+$
            strg(vd_ArtLines_adu(vi_ValidArtLines(i)))+' adu.'

   if ( n_ValidArtLines lt n_FitOrder+1 ) then $
      return, error ('FAILURE (findlines.pro): Too few single lines found for wavelength calibration of order ' + $
         strg(n_FitOrder)+'.')

   ; wavelengths of lines that are used to determine the dispersion relation
   vd_ArtLines2_um = vd_ArtLines_um(vi_ValidArtLines)

   vi_ArtLines2_px = intarr(n_ValidArtLines)
   for i=0, n_ValidArtLines-1 do $
      vi_ArtLines2_px(i) = my_index( vd_ArtSpec_um, vd_ArtLines2_um(i) )

   cd_WMap = dblarr(n_Dims(1), n_Dims(2), n_Dims(3) )         ; wavelength cube

   ; results of fitting the dispersion relation
   mb_DispStat        = make_array(/INT, n_Dims(2), n_Dims(3), VALUE=ERROR_DISPERSION_OK )                ; error status of fitting the disp. rel

   mb_DispStat(0,0)     = ERROR_SINGLE_LINE_OUT
   mb_DispStat(16:*,0)  = ERROR_SINGLE_LINE_OUT
   mb_DispStat(32:*,1)  = ERROR_SINGLE_LINE_OUT
   mb_DispStat(48:*,2)  = ERROR_SINGLE_LINE_OUT
   mb_DispStat(0:15,16) = ERROR_SINGLE_LINE_OUT
   mb_DispStat(0:31,17) = ERROR_SINGLE_LINE_OUT
   mb_DispStat(0:47,18) = ERROR_SINGLE_LINE_OUT

   mi_DispSVal        = intarr(n_Dims(2), n_Dims(3))                 ; number of singular values in disp. rel.
   mi_DispCLag        = intarr(n_Dims(2), n_Dims(3))                 ; lag of cross correlation
   cd_DispFitCoeff    = dblarr(n_Dims(2), n_Dims(3), n_FitOrder+1 )  ; fit coefficients of the dispersion relation
   cd_DispFitCoeffErr = dblarr(n_Dims(2), n_Dims(3), n_FitOrder+1 )  ; errors of fit coefficients of the dispersion relation

   ; results of individual line fitting
   cb_LineStat        = make_array(/INT, n_Dims(2), n_Dims(3), n_ValidArtLines, VALUE=ERROR_SINGLE_LINE_OK ) ; error status of fitting individual lines
   mi_LineValid       = intarr(n_Dims(2), n_Dims(3))
   cd_LineFitCoeff    = dblarr(n_Dims(2), n_Dims(3), 4, n_ValidArtLines)  ;scale, center, sigma, chi2
   cd_LineFitCoeffErr = dblarr(n_Dims(2), n_Dims(3), 3, n_ValidArtLines)  ;error scale, eror center, error sigma

   ; loop over the individual spectra
   for i1=0, n_Dims(2)-1 do begin

      for i2=0, n_Dims(3)-1 do begin

         if ( mb_DispStat[i1,i2] eq ERROR_DISPERSION_OK ) then begin

         ; find where the pixels are valid
         vb_Mask = valid ( (*p_WFrame)(*,i1,i2), (*p_WIntFrame)(*,i1,i2), (*p_WIntAuxFrame)(*,i1,i2) )
         vi_Mask = where ( vb_Mask, n_Valid )

         if ( n_Valid gt 0 ) then begin

            ; determine mean and median intensity of spectrum
            d_MeanSpec   = mean((*p_WFrame)(vi_Mask,i1,i2))
            d_MedianSpec = median((*p_WFrame)(vi_Mask,i1,i2))

            if ( keyword_set ( DEBUG ) ) then $
               debug_info, 'DEBUG INFO (findlines.pro): Spectrum ' +strg(i1) + ',' + strg(i2) + $
                           ' Mean:'+ strg(d_MeanSpec) + ' Median: '+strg(d_MedianSpec)
  
            if ( abs(d_MeanSpec - d_MedianSpec) ge d_MinDiff ) then begin

               ; determine the lag
               i_CrossCor_px      = cross_correlate ( vd_ArtSpec_adu(vi_Mask), reform((*p_WFrame)(vi_Mask,i1,i2)), $
                                                      reform((*p_WIntFrame)(vi_Mask,i1,i2)), i_MaxLag, $
                                                      DEBUG=keyword_set(DEBUG) )
               mi_DispCLag(i1,i2) = i_CrossCor_px

               if ( keyword_set ( DEBUG ) ) then begin
                  debug_info, 'DEBUG INFO (findlines.pro): Cross correlation gives lag of '+strg(i_CrossCor_px)
                  plot, vd_ArtSpec_um, vd_ArtSpec_adu, title='Artificial spectrum and row spectrum (red)'
                  oplot, vd_ArtSpec_um, reform((*p_WFrame)(vi_Mask,i1,i2))/total((*p_WFrame)(vi_Mask,i1,i2)), color=1
; wait,5.
                  wait, d_Debug_Delay
               end

               ; check if lag is smaller than the defined limit
               if ( abs(i_CrossCor_px) lt i_MaxLag ) then begin
  
                  if ( keyword_set ( DEBUG ) ) then begin
                     plot, vi_ArtSpec_px, vd_ArtSpec_adu, title='Shifted Artificial spectrum and row spectrum (red)'
                     oplot, vi_ArtSpec_px-i_CrossCor_px, reform((*p_WFrame)(vi_Mask,i1,i2))/total((*p_WFrame)(vi_Mask,i1,i2)), color=1
                     wait, d_Debug_Delay
                  end
        
                  ; loop over the individual lines
                  for j=0, n_ValidArtLines-1 do begin

                     ; determine the position of the line
                     lj = fix((vi_ArtLines2_px(j) - d_FitSigma_fact * i_Sigma_px + i_CrossCor_px ))
                     uj = fix((vi_ArtLines2_px(j) + d_FitSigma_fact * i_Sigma_px + i_CrossCor_px ))

                     if ( lj ge 0 and lj lt n_Dims(1) and uj ge 0 and uj lt n_Dims(1) and lj le uj ) then begin
   
                        if ( keyword_set ( DEBUG ) ) then $
                           debug_info, 'DEBUG INFO (findlines.pro): Fit of valid line '+strg(j)+' at ' + $
                              strg(vd_ArtLines2_um(j)) + 'mu from ' + strg(lj) + ' to ' + strg(uj)
     
                        vd_X    = float(vi_ArtSpec_px(lj:uj))
                        vd_Y    = (*p_WFrame)(lj:uj,i1,i2)
                        vd_N    = (*p_WIntFrame)(lj:uj,i1,i2)
                        vb_Mask = valid ( (*p_WFrame)(lj:uj,i1,i2), (*p_WIntFrame)(lj:uj,i1,i2), $
                                          (*p_WIntAuxFrame)(lj:uj,i1,i2) )
                        vi_Mask = where ( vb_Mask, n_ValidLineMask )

                        if ( n_ValidLineMask gt 4 ) then begin

                           ; first determine the COI of the line to center the fit window.
                           i_COI = fix(total(vd_X*vd_Y)/total(vd_Y))
   
                           i_DCOI = i_COI - fix((max(vd_X)+min(vd_X))/2)

                           lj     = lj + i_DCOI
                           uj     = uj + i_DCOI

                           if ( keyword_set ( DEBUG ) ) then $
                              debug_info, 'DEBUG INFO (findlines.pro): Recentered Fit of valid line '+strg(j)+$
                                 ' at ' + strg(vd_ArtLines2_um(j)) + 'mu from ' + strg(lj) + ' to ' + strg(uj)

                           if ( lj ge 0 and lj lt n_Dims(1) and uj ge 0 and uj lt n_Dims(1) and lj le uj ) then begin
 
                              vd_X    = float(vi_ArtSpec_px(lj:uj))
                              vd_Y    = (*p_WFrame)(lj:uj,i1,i2)
                              vd_N    = (*p_WIntFrame)(lj:uj,i1,i2)
                              vb_Mask = valid ( (*p_WFrame)(lj:uj,i1,i2), $
                                                (*p_WIntFrame)(lj:uj,i1,i2), $
                                                (*p_WIntAuxFrame)(lj:uj,i1,i2) )
                              vi_Mask = where ( vb_Mask, n_ValidLineMask )

                              if ( n_ValidLineMask gt 4 ) then begin
                                 ; fit the individual line
                                 vd_Fit = mpfitpeak ( vd_X(vi_Mask), vd_Y(vi_Mask), vd_Coeff, NTERMS=n_FitTerms, $
                                                      GAUSSIAN=s_FitFunction eq "GAUSSIAN", $
                                                      LORENTZIAN=s_FitFunction eq "LORENTZIAN", $
                                                      MOFFAT=s_FitFunction eq "MOFFAT", $
                                                      MEASURE_ERRORS = vd_N(vi_Mask), perror=vd_Errors )
 
                                 if ( keyword_set ( DEBUG ) ) then begin
                                    vs_Title = 'Fit of line '+strg(j)+' '+s_FitFunction+ ' '+strg(vd_Coeff(1) ) +$
                                        '+-' + $
                                     strg(vd_Errors(1)) + ' '+strg(vd_Coeff(0))+ ' '+strg(vd_Coeff(2))
                                    plot, vd_X(vi_Mask),vd_Y(vi_Mask), psym=2, title=vs_Title, /XST
                                    oplot, vd_X(vi_Mask),vd_Fit
                                    oploterr, vd_X(vi_Mask),vd_Y(vi_Mask), vd_N(vi_Mask)
                                    debug_info, 'DEBUG INFO (findlines.pro): Scale: '+strg(vd_Coeff(0)) + $
                                       ' Center: '+strg(vd_Coeff(1)) + ' Sigma: '+strg(vd_Coeff(2))
                                    wait, d_Debug_Delay
                                 end

                                 if ( vd_Errors(1) lt d_MaxError_px ) then begin
  
                                    if ( vd_Coeff(0) gt d_MinFlux_adu ) then begin

                                       if ( vd_Coeff(2) ge d_MinSigma_px and vd_Coeff(2) le d_MaxSigma_px ) then begin

                                          if ( vd_Coeff(1) ge lj and vd_Coeff(1) le uj ) then begin

                                             cd_LineFitCoeff(i1,i2,*,j)    = [ vd_Coeff(0:2), $
                                                                               total( (vd_Fit - vd_Y(vi_Mask))^2 ) ]
                                             cd_LineFitCoeffErr(i1,i2,*,j) = [ vd_Errors(0), $
                                                                               vd_Errors(1)*d_ArtSpecDispersion_muperpx, $
                                                                               vd_Errors(2) ]
                                             mi_LineValid[i1,i2]           = mi_LineValid[i1,i2] + 1

                                          endif else begin
                                             warning, ['WARNING (findlines.pro): Line ' + strg(j) + ' (' + $
                                                       strg(vd_ArtLines2_um(j)) + ' in spectrum ' + strg(i1) + ',' + $
                                                       strg(i2), '   Fitted center out of fit window. Maybe ' + $
                                                       ' line does not exist in measured spectrum or ' + $
                                                       ' dispersion relation is highly non-linear.']
                                             cb_LineStat[i1,i2,j] = ERROR_SINGLE_LINE_COIOUT
                                          end

                                       endif else begin
                                          warning, 'WARNING (findlines.pro): Line '+strg(j)+' ('+$
                                                   strg(vd_ArtLines2_um(j)) + ') in spectrum '+strg(i1) + ',' + $
                                                   strg(i2) + ' Dispersion exceeds limits: '+ strg(d_MinSigma_px)+'<='+$
                                                   strg(vd_Coeff(2))+'<='+strg(d_MaxSigma_px)
                                          cb_LineStat[i1,i2,j] = ERROR_SINGLE_LINE_SIGMA
                                       end

                                    endif else begin
                                       warning, 'WARNING (findlines.pro): Line '+strg(j)+' ('+strg(vd_ArtLines2_um(j)) + $
                                                ') in spectrum '+strg(i1) + ',' + strg(i2)+ $
                                                ' Fitted Flux too low or line does not exist in measured spectrum.'
                                       cb_LineStat[i1,i2,j] = ERROR_SINGLE_LINE_FLUX
                                    end

                                 endif else begin
                                    warning, 'WARNING (findlines.pro): Line '+strg(j)+' ('+strg(vd_ArtLines2_um(j)) + $
                                             ') in spectrum '+strg(i1) + ',' + strg(i2)+ ': Error in COI (' + $
                                              strg(vd_Errors(1))+') exceeds limit.'
                                    cb_LineStat[i1,i2,j] = ERROR_SINGLE_LINE_COIERROR
                                 end

                              endif else begin
                                 warning, 'WARNING (findlines.pro): Valid Line no. '+strg(j)+' in spectrum '+strg(i1) + $
                                          ','+strg(i2) + ': too few valid pixels after recentering found for fitting.'
   
                                 cb_LineStat[i1,i2,j] = ERROR_SINGLE_LINE_FEW
                              end

                           endif else begin
                              warning, 'WARNING (findlines.pro): Valid Line no. '+strg(j)+' in spectrum '+$
                                       strg(i1) + ','+strg(i2) + ': Recentered fit window invalid.'
                              cb_LineStat[i1,i2,j] = ERROR_SINGLE_LINE_WINDOW
                           end

                        endif else begin
                           warning, 'WARNING (findlines.pro): Valid Line no. '+strg(j)+' in spectrum '+strg(i1) + $
                                    ','+strg(i2) + ': too few valid pixels before recentering found for fitting.'
                           cb_LineStat[i1,i2,j] = ERROR_SINGLE_LINE_NOCOI
                        end

                     endif else begin
                        warning, 'WARNING (findlines.pro): Artificial Line no. ' + strg(j) + ' in ' + $
                                 strg(i1) + ','+strg(i2) + ': not within measured spectrum.'
                        cb_LineStat[i1,i2,j] = ERROR_SINGLE_LINE_OUT
                     end

                  end             ; ende of loop over individual lines

                  vi_FitLine = where ( reform(cb_LineStat(i1,i2,*)) eq ERROR_SINGLE_LINE_OK, n_LineValid )

                  if ( n_LineValid ne mi_LineValid[i1,i2] ) then $
                     return, error ('INTERNAL ERROR (findlines.pro): Inconsistent number of valid lines found ' + $
                                    'in spectrum ' + strg(i1) + ',' + strg(i2) + ' (' + strg(n_LineValid) + ',' + $
                                    strg(mi_LineValid[i1,i2]) + ').' )

                  if ( keyword_set ( DEBUG ) ) then $
                     debug_info, 'DEBUG INFO (findlines.pro): Fitted succesfully ' + strg(n_LineValid) + ' lines.'

                  if ( n_LineValid ge n_FitOrder+1 ) then begin
                     ; do the fit
                     v_Res = SVDFIT( reform(cd_LineFitCoeff(i1,i2,1,vi_FitLine)), $
                                        vd_ArtLines2_um(vi_FitLine), n_FitOrder+1, $
;                                        MEASURE_ERRORS = reform(cd_LineFitCoeffErr(i1,i2,1,vi_FitLine)), $
                                        SINGULAR=mi_DispSVal[i1,i2], /DOUBLE, SIGMA=v_Errors )

                     ; check 
                     if ( bool_is_vector ( v_Res ) ) then begin

                        cd_DispFitCoeff(i1,i2,*)    = v_Res
                        cd_DispFitCoeffErr(i1,i2,*) = v_Errors

                        if ( keyword_set ( DEBUG ) ) then begin
                           vs_Title = ''
                           for k=0, n_FitOrder do vs_Title = vs_Title + strg(v_Res(k)) + '  '
                           plot, cd_LineFitCoeff(i1,i2,1,vi_FitLine), vd_ArtLines2_um(vi_FitLine), psym=2, $
                              title = strg(i1)+' '+strg(i2)+' Coeff:'+vs_Title
                           oploterr, cd_LineFitCoeff(i1,i2,1,vi_FitLine), vd_ArtLines2_um(vi_FitLine), $
                                     cd_LineFitCoeffErr(i1,i2,1,vi_FitLine)
                           oplot, vi_ArtSpec_px, poly(vi_ArtSpec_px, v_Res)
                           debug_info, 'DEBUG INFO (findlines.pro): Found fit coefficients ' + vs_Title
                           for ii=0, n_elements(vi_FitLine)-1 do $
                              debug_info, 'DEBUG INFO (findlines.pro): Found fit values ' + $
                                 strg(cd_LineFitCoeff(i1,i2,1,vi_FitLine(ii))) + '   ' + $
                                 strg(vd_ArtLines2_um(vi_FitLine(ii)))
                           wait, d_Debug_Delay
                        end

                     endif else begin
                        info, 'INFO (findlines.pro): Failed to determine dispersion function in spectrum ' + $
                              strg(i1)+','+strg(i2) + '. SVDFIT failed.'
                        mb_DispStat[i1,i2] = ERROR_DISPERSION_SVDFIT
                     end

                  endif else begin
                     info, 'INFO (findlines.pro): Failed to determine dispersion function in spectrum ' + $
                          strg(i1)+','+strg(i2) + '. Too few valid lines found.'
                     mb_DispStat[i1,i2] = ERROR_DISPERSION_FEW
                  end


               endif else begin
                  warning, 'WARNING (findlines.pro): Determined lag exceeds limit in pixel ' + strg(i1)+','+strg(i2)
                  mb_DispStat[i1,i2] = ERROR_DISPERSION_LAG
                  cb_LineStat(i1,i2,*) = ERROR_SINGLE_LINE_FAILED
               end

            endif else begin
               warning, 'WARNING (findlines.pro): Not enough intensity (mean:' + strg(d_MeanSpec) + $
                        ', median:'+strg(d_MedianSpec)+') in spectrum '+strg(i1)+','+strg(i2)+'.'
               mb_DispStat[i1,i2] = ERROR_DISPERSION_NOINT
            end

         endif else begin
            warning, 'WARNING (findlines.pro): No valid pixels in spectrum '+strg(i1)+','+strg(i2)+' .'
            mb_DispStat[i1,i2] = ERROR_DISPERSION_NOPIX
         end

      end

      end

   end

   info, 'INFO (findlines.pro): Individual emission lines search completed.'

   if ( keyword_set ( FitCoeff ) ) then begin

      info, 'INFO (findlines.pro): Fitting the coefficients now.'

      ; the section with the coefficient fitting

      d_CoeffLoReject = FitCoeff(0)
      d_CoeffHiReject = FitCoeff(1)
      i_CoeffFitOrder = FitCoeff(2)
      d_CoeffSigma    = FitCoeff(3)
      n_CoeffMax      = FitCoeff(4)
      i_CoeffDebug    = FitCoeff(5)

      mb_CoeffStat     = make_array(/INT, n_Dims(2), n_Dims(3), VALUE=ERROR_COEFF_FAILED ) ; is the spectrum valid ?
      cd_CoeffFitCoeff = dblarr(n_Dims(2), n_FitOrder+1, i_CoeffFitOrder+1 ) ; coefficients of the fitted fit coefficients
      cd_CoeffCoeff    = dblarr(n_Dims(2), n_Dims(3), n_FitOrder+1 )  ; fitted fit coefficients

      if ( i_CoeffDebug ne 0 ) then $
         debug_info, 'DEBUG INFO (findlines.pro): Fitting coefficients now.'

      ; loop over the y-slices
      for i=0, n_Dims(2)-1 do begin

         ; loop over coefficients
         for j=0, n_FitOrder do begin

            if ( i_CoeffDebug ne 0 ) then $
               debug_info, 'DEBUG INFO (findlines.pro): Now in line ' + strg(i) + ' coefficient ' + $
                           strg(j) + ' of ' + strg(n_FitOrder)

            vd_X     = dindgen(n_Dims(3))                                         ; the running index of the x-slice
            vi_Valid = where ( mb_DispStat[i,*] eq ERROR_DISPERSION_OK, n_Valid ) 
               ; check where fitting of the dispersion relation has been successful

            if ( n_Valid gt i_CoeffFitOrder ) then begin 

               ; cut out the valid coefficients
               vd_X = vd_X(vi_Valid)
               vd_Y = cd_DispFitCoeff(i,vi_Valid,j)
               vd_W = cd_DispFitCoeffErr(i,vi_Valid,j)

               ; clean the input data from outliers
               vb_Mask = where ( clean ( vd_Y, d_CoeffLoReject, d_CoeffHiReject ), n_Clip )

               if ( n_Clip ge i_CoeffFitOrder ) then begin

                  ; cut out the not clipped coefficients
                  vd_X = vd_X(vb_Mask)
                  vd_Y = vd_Y(vb_Mask)
                  vd_W = vd_W(vb_Mask)

                  ; do the iterative sigma fit
                  vd_Coeff = sigma_poly_fit( vd_X, vd_Y, vd_W, i_CoeffFitOrder, d_CoeffSigma, $
                                             d_CoeffSigma, n_CoeffMax, DEBUG=i_CoeffDebug )

                  if ( NOT bool_is_vector ( vd_Coeff ) ) then begin
                     warning, 'WARNING (findlines.pro): Row '+strg(i)+' not fittable.' 
                     mb_CoeffStat(i,*) = ERROR_COEFF_SVD
                  endif else begin

                     cd_CoeffFitCoeff(i, j, *) = vd_Coeff

                     vi_Valid = where ( mb_DispStat[i,*] eq ERROR_DISPERSION_OK or $
                                        mb_DispStat[i,*] eq ERROR_DISPERSION_FEW, n_Valid )

                     for k=0, n_Valid-1 do $
                        cd_CoeffCoeff(i,vi_Valid(k), j ) = poly(vi_Valid(k),vd_Coeff) 

                     mb_CoeffStat(i,vi_Valid)  = ERROR_COEFF_OK

;                     if ( i_CoeffDebug ne 0 ) then begin
;                        plot, vd_X, vd_Y, title='White: Coeff., Red: Fitted coeff. Slice '+strg(i)+', #Coeff '+strg(j)
;                        oplot, (dindgen(n_Dims(2)))(vi_Valid), cd_CoeffCoeff(vi_Valid, i, j), psym=1, symsize=2,color=1
;                        wait, i_CoeffDebug
;                     end
                  end

               endif else begin
                 warning, 'WARNING (findlines.pro): Not enough coefficients for fit left after clipping in slice ' + strg(i) +'. '
                 mb_CoeffStat(i,*) = ERROR_COEFF_CLIPFEW
               end

            endif else begin
               warning, 'WARNING (findlines.pro): Not enough valid coefficients for fit in slice ' + strg(i) + '.'
               mb_CoeffStat(i,*) = ERROR_COEFF_FEW
            end

         end

      end

      ; calculate the wavelength map using the determined fitted coefficients
      for i=0, n_Dims(2)-1 do $
         for j=0, n_Dims(3)-1 do $
            if ( mb_CoeffStat(i,j) eq ERROR_COEFF_OK ) then $
               cd_WMap(*,i,j) = poly( vi_ArtSpec_px, cd_CoeffCoeff(i,j,*) )

      return, { cd_WMap            : reverse(cd_WMap), $             ; the wavelength map
                mb_DispStat        : mb_DispStat, $
                mi_DispSVal        : mi_DispSVal, $      
                mi_DispCLag        : mi_DispCLag, $
                cd_DispFitCoeff    : cd_DispFitCoeff, $
                cd_DispFitCoeffErr : cd_DispFitCoeffErr, $
                cb_LineStat        : cb_LineStat, $
                mi_LineValid       : mi_LineValid, $
                cd_LineFitCoeff    : cd_LineFitCoeff, $
                cd_LineFitCoeffErr : cd_LineFitCoeffErr, $
                vd_ArtLines        : vd_ArtLines2_um(vi_FitLine), $
                mb_CoeffStat       : mb_CoeffStat, $
                cd_CoeffCoeff      : cd_CoeffCoeff, $
                cd_CoeffFitCoeff   : cd_CoeffFitCoeff }

   endif else begin

      ; the section without the coefficient fitting

      ; calculate the wavelength map using the determined unfitted coefficients
      for i=0, n_Dims(2)-1 do $
         for j=0, n_Dims(3)-1 do $
            if ( mb_DispStat[i,j] eq ERROR_COEFF_OK ) then $
               cd_WMap(*,i,j) = poly( vi_ArtSpec_px, cd_DispFitCoeff(i,j,*) )

      ; return the results
      return, { cd_WMap            : reverse(cd_WMap), $             ; the wavelength map
                mb_DispStat        : mb_DispStat, $
                mi_DispSVal        : mi_DispSVal, $      
                mi_DispCLag        : mi_DispCLag, $
                cd_DispFitCoeff    : cd_DispFitCoeff, $
                cd_DispFitCoeffErr : cd_DispFitCoeffErr, $
                cb_LineStat        : cb_LineStat, $
                mi_LineValid       : mi_LineValid, $
                cd_LineFitCoeff    : cd_LineFitCoeff, $
                cd_LineFitCoeffErr : cd_LineFitCoeffErr, $
                vd_ArtLines        : vd_ArtLines2_um(vi_FitLine) }

   end

end
