
;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; NAME: makewavefr_000.pro
;
; PURPOSE: determine a wavelength map from a calibration image
;
; ALLOWED BRANCH IDS: All branches
;
; PARAMETERS:
;
;    mkwavcalfr_COMMON___Debug              : initialize debugging mode,
;                                             either bool or a 2-element vector specifying the pixel to
;                                             treat separatly
;    mkwavcalfr_COMMON___Linefile           : the linelist with the calibration lines
;    mkwavcalfr_COMMON___Filterfile         : the filter file
;
; Parameters for the cross correlation (CC)
;
;    mkwavcalfr_COMMON___MaxLag_px          : maximum lag for CC, integer
;    mkwavcalfr_COMMON___MedianLag          : replace CC lags by median CC lag, bool
;
; Parameters for the individual line fittings:
;
;    mkwavcalfr_COMMON___LineFitFunction    : fit function, "GAUSSIAN". "LORENTZIAN", "MOFFAT"
;    mkwavcalfr_COMMON___LineFitTerms       : fit terms as defined in gaussfit, see IDL manual
;    mkwavcalfr_COMMON___LineFitDSigma_fact : The line is searched in
;                                             a window which halfwidth is determined by this parameter times
;                                             the FWHM of the instruments profile as defined in the filterfile.
;
; Parameters determining the validness of a spectrum, line fit:
;
;    mkwavcalfr_COMMON___MinDiff_adu        : minimum difference in ADUs between the mean and median value of
;                                             a spectrum. If this difference is less, the
;                                             spectrum will not be treated
;    mkwavcalfr_COMMON___MinSigma_px        : minimum sigma of line fit (sigma, not FWHM) to be valid
;    mkwavcalfr_COMMON___MaxSigma_px        : maximum sigma of line fit (sigma, not FWHM) to be valid
;    mkwavcalfr_COMMON___MinFlux_adu        : minimum flux in ADU of line fit to be valid 
;
; Parameters determining the dispersion relation fit
;
;    mkwavcalfr_COMMON___DispFitOrder       : polynomial order of
;                                             dispersion function to fit (2 means 3 parameters, a parabola)
;    mkwavcalfr_COMMON___DispFitSigma_fact  : sigma for kappa-sigma test. Fitting the dispersion relation
;                                             is done iteratively with a kappa-sigma test. 
;    mkwavcalfr_COMMON___DispFitIter        : maximum number of iterations
;
; MINIMUM/MAXIMUM NUMBER OF ALLOWED INPUT DATASETS : 1/- 
;
; INPUT-FILES : None
;
; OUTPUT :  saves the wavelength map
;
; INPUT : 3d frames
;
; DATASET : input must contain rectified wavelength calibration cubes
;
; QUALITY BITS : 0th and 3rd bit checked
;                1st and 2nd bit ignored
;
; DEBUG : nothing special
;
; MAIN ROUTINE : findlines
;
; SAVES : see OUTPUT
;
; NOTES :  - All datasets must have the same SFILTER and SSCALE keyword
;
; ALGORITHM : see documentation for the main routine, findlines.pro
;
; STATUS : not tested
;
; HISTORY : 24.9.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION mkwavcalfr_000, DataSet, Modules, Backbone

    COMMON APP_CONSTANTS

    ; define error constants
    define_error_constants

    functionName = 'mkwavcalfr_000'
    ; save the starting time
    T = systime(1)

    drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1

    ; check integrity
    stModule =  check_module( DataSet, Modules, Backbone, functionName )
    if ( NOT bool_is_struct ( stModule ) ) then $
       return, error ('ERROR IN CALL ('+strtrim(functionName)+'): Integrity check failed.')

    ; Get all COMMON parameter values
    s_Debug              = strsplit(Backbone->getParameter('mkwavcalfr_COMMON___Debug'),',',/EXTRACT)
    if ( n_elements(s_Debug) le 2 ) then begin
       if ( n_elements(s_Debug) eq 2 ) then $
          i_Debug = [ fix(s_Debug(0)), fix(s_Debug(1))] $
       else $
          i_Debug = fix(s_Debug)
    endif else $
       return, error (['ERROR IN CALL (' + functionName + '): Wrong mkwavcalfr_COMMON___Debug definition.', $
                       '                                      Must be a integer scalar or 2-element vector.']) 

    s_Linefile           = strg(Backbone->getParameter('mkwavcalfr_COMMON___Linefile'))
    s_Filterfile         = strg(Backbone->getParameter('mkwavcalfr_COMMON___Filterfile'))

    i_CCMaxLag_px        = float(Backbone->getParameter('mkwavcalfr_COMMON___MaxLag_px')) 
    b_CCMedianLag        = fix(Backbone->getParameter('mkwavcalfr_COMMON___MedianLag'))

    s_LineFitFunction    = Backbone->getParameter('mkwavcalfr_COMMON___LineFitFunction')
    n_LineFitTerms       = fix(Backbone->getParameter('mkwavcalfr_COMMON___LineFitTerms'))   
    d_LineFitSigma_fact  = float(Backbone->getParameter('mkwavcalfr_COMMON___LineFitDSigma_fact'))

    d_MinDiff_adu        = float(Backbone->getParameter('mkwavcalfr_COMMON___MinDiff_adu'))
    d_MinSigma_px        = float(Backbone->getParameter('mkwavcalfr_COMMON___MinSigma_px'))   
    d_MaxSigma_px        = float(Backbone->getParameter('mkwavcalfr_COMMON___MaxSigma_px'))   
    d_MinFlux_adu        = float(Backbone->getParameter('mkwavcalfr_COMMON___MinFlux_adu')) 

    n_DispFitOrder       = float(Backbone->getParameter('mkwavcalfr_COMMON___DispFitOrder'))
    d_DispFitSigma_fact  = float(Backbone->getParameter('mkwavcalfr_COMMON___DispFitSigma_fact'))
    i_DispFitIter        = fix(Backbone->getParameter('mkwavcalfr_COMMON___DispFitIter')) > 1

    nFrames              = Backbone->getValidFrameCount(DataSet.Name)


    ; check whether the SFILTER keyword is the same for all datasets
    vs_Filter = get_kwd( DataSet.Headers, nFrames, "SFILTER" )
    if ( NOT array_equal ( vs_Filter, vs_Filter(0) ) ) then $ 
       return, error ('ERROR IN CALL (' + strtrim(functionName) + '): Inconsistent SFILTER keyword in dataset.')

    ; check whether the SSCALE keyword is the same for all datasets
    vs_Scale = get_kwd( DataSet.Headers, nFrames, "SSCALE" )
    if ( NOT array_equal ( vs_Scale, vs_Scale(0) ) ) then $ 
       return, error ('ERROR IN CALL (' + strtrim(functionName) + '): Inconsistent SScale keyword in dataset.')

    ; get the filter parameters
    s_FiltParam = get_filter_param ( vs_Filter(0), s_Filterfile, DEBUG=i_Debug )
    if ( NOT bool_is_struct ( s_FiltParam ) ) then $
       return, error ('FAILURE ('+strtrim(functionName)+'): Failed to get filter parameters.')

    ; read the calibration line file
    s_Lines  = findlines_read_calline_file ( s_LineFile )

    ; create a filename for saving the summed CC cube
    thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
    if ( Modules[thisModuleIndex].Save eq 1 ) then $
       c_File = make_filename ( DataSet.Headers[0], Modules[thisModuleIndex].OutputDir, stModule.Save ) $
    else $
       c_File = 0

    for i=0, nFrames-1 do begin
       *DataSet.Frames(i)       = reverse(*DataSet.Frames(i), 1)
       *DataSet.IntFrames(i)    = reverse(*DataSet.IntFrames(i), 1)
       *DataSet.IntAuxFrames(i) = reverse(*DataSet.IntAuxFrames(i), 1)
    end

    s_Res = findlines ( DataSet, nFrames, $
                        s_Lines, $              ; structure with the calibration lines
                        s_FiltParam, $          ; structure with filter info
                        vs_Filter(0), $         ; the filter used

                        i_CCMaxLag_px, $        ; maximum allowed CC lag
                        b_CCMedianLag, $        ; median CC lags ?

                        s_LineFitFunction, $    ; fit function for mpfitpeak
                        n_LineFitTerms, $       ; order of individual line fitting, see e.g NTERMS of mpfitpeak
                        d_LineFitSigma_fact, $  ; factor to determine the halfwidth of the fit window

                        d_MinDiff_adu, $        ; min diff betwee mean and median of a spectrum
                        d_MinSigma_px, $        ; minimum sigma of the fit
                        d_MaxSigma_px, $        ; maximum sigma of the fit
                        d_MinFlux_adu, $        ; minimum flux of the fitted line

                        n_DispFitOrder, $       ; order of polynomial to fit
                        d_DispFitSigma_fact, $  ; sigma for kappa-sigma test when fitting iterativla the disp rel.
                        i_DispFitIter, $        ; maximum number of iterations

                        FILE = c_File, $        ; save the summed dataset to FILE
                        DEBUG = i_DEBUG )       ; initialize debugging mode

    for i=0, nFrames-1 do begin
       *DataSet.Frames(i)       = reverse(*DataSet.Frames(i), 1)
       *DataSet.IntFrames(i)    = reverse(*DataSet.IntFrames(i), 1)
       *DataSet.IntAuxFrames(i) = reverse(*DataSet.IntAuxFrames(i), 1)
    end

    if ( NOT bool_is_struct ( s_Res ) ) then $
       return, error ('FAILURE ('+strtrim(functionName)+'): Determination of wavelength map failed.')

    ; Now, save the data
    thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
    c_File = make_filename ( DataSet.Headers[0], Modules[thisModuleIndex].OutputDir, stModule.SaveExt  )
    if ( NOT bool_is_string(c_File) ) then $
       return, error('FAILURE ('+strtrim(functionName)+'): Output filename creation failed.')

    mkhdr, h, s_Res.cd_WMap
    sxaddpar, h, 'EXTEND', 'T'
    sxaddpar, h, 'SFILTER', vs_Filter(0)
    sxaddpar, h, 'SSCALE', vs_Scale(0)
    sxaddpar, h, 'DATAFILE', sxpar ( *DataSet.Headers(0), 'DATAFILE' )
    sxaddpar, h, 'ORDER', n_DispFitOrder
    sxaddpar, h, 'COMMNT0', '0 Extension : Wavelength map/cube.'
    sxaddpar, h, 'COMMNT1', '1 Extension : Status of the the dispersion relation for a specific pixel. 0 means OK'
    sxaddpar, h, 'COMMNT2', '2 Extension : The cross correlation lag for a specific pixel.'
    sxaddpar, h, 'COMMNT3', '3 Extension : Fit coefficients of the dispersion relation for a spectrum.'
    sxaddpar, h, 'COMMNT4', '4 Extension : Errors of Fit coefficients of the dispersion relation for a spectrum.'
    sxaddpar, h, 'COMMNT5', '5 Extension : Number of valid lines used for fitting the dispersion relation.'
    sxaddpar, h, 'COMMNT6', '6 Extension : Status of fitting an individual line. 0 means OK.'
    sxaddpar, h, 'COMMNT7', '7 Extension : Fit coefficient of an individual line.'
    sxaddpar, h, 'COMMNT8', '8 Extension : Error of the fit coefficient of an individual line.'
    sxaddpar, h, 'COMMNT9', '9 Extension : Residuals of individual lines in Angstroem.'

    writefits, c_File, double(s_Res.cd_WMap*1.d3), h       
    writefits, c_File, fix(s_Res.mb_DispStat),/append
    writefits, c_File, fix(s_Res.mi_CCLag),/append
    writefits, c_File, double(s_Res.cd_DispFitCoeff),/append
    writefits, c_File, double(s_Res.cd_DispFitCoeffErr),/append 
    writefits, c_File, fix(s_Res.mi_LineValid),/append 
    writefits, c_File, fix(s_Res.cb_LineStat),/append 
    writefits, c_File, double(s_Res.cd_LineFitCoeff),/append
    writefits, c_File, double(s_Res.cd_LineFitCoeffErr),/append 
    writefits, c_File, double(s_Res.cd_Residuals_A),/append 

    info, 'INFO (' + strtrim(functionName) + '): File ' + c_File + ' successfully written.'
    fits_help, c_File

    report_success, functionName, T

    Return, OK

END
