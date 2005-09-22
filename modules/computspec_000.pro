;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; NAME:  computspec_000
;
; PURPOSE: Extract a stellar spectrum from datacubes (see extr_stellar_spec_2.pro).
;          The FoV must contain only one star because the position of
;          the star is determined automatically by fitting the PSF
;          (computspec_COMMON___PSFMode). The spectrum is extracted
;          from pixel that are within the extraction radius (see 
;          computspec_COMMON___ExtractionRadius). When extracting
;          optimally this parameter is ignored.
;          Optionally the background in each slice of the cube can be
;          subtracted (see computspec_COMMON___BGMode). In this case the background in a slice is
;          estimated from all pixels that are not masked (computspec_COMMON___BGExtractionRadius)
;          Optionally the extraction can be done optimally using the
;          algorithm described in Horne, 1986 PASP 98:609 (computspec_COMMON___OptClipSigma).
;
; PARAMETERS IN RPBCONFIG.XML :
;          computspec_COMMON___SpecChannels       : fraction of cube that is collapsed to
;                                                    get a high S/N image of the star, used
;                                                    for fitting the PSF (0<d_Spec_Channel<1).
;                                                    Only used for determining the
;                                                    position of the star
;          computspec_COMMON___ImgMode            : 'MED' : pixel in the collapsed image is the median value
;                                                    of the spectra
;                                                    'AVRG': pixel in the collapsed image is the mean value
;                                                    of the spectra     
;                                                    'SUM' : pixel in the collapsed image is the sum
;                                                    of the spectra
;          computspec_COMMON___PSFMode            : 'GAUSS' or 'LORENTZIAN' or 'MOFFAT', form
;                                                    of the PSF
;          computspec_COMMON___ExtractionRadius   : extraction radius = d_FWHMMultiplier *
;                                                    max(FWHM of PSF)
;          computspec_COMMON___BGMode             : Background estimation method 
;                                                    'NONE'   : no background subtraction
;                                                    'MEDIAN' : median background in each slice
;                                                    'FIT'    : fit of a plane to each slice
;          computspec_COMMON___BGExtractionRadius : the background will be estimated from
;                                                    all pixel that are more far away from the fitted PSF center
;                                                    than d_BGFHWMMultiplier*max(FWHM of PSF)
;          computspec_COMMON___OptClipSigma       : initializes the optimal extraction
;                                                    part. OPT is the number of sigmas for
;                                                    clipping that means all pixels are used for
;                                                    extraction that are closer to the
;                                                    fitted center of the PSF in each slice than
;                                                    computspec_COMMON___OptClipSigma * max(FWHMX,FWHMY). 
;                                                    When extracting optimally
;                                                    the frame and intframe values must be
;                                                    in electrons (!!!).
;          computspec_COMMON___Debug              : initializes the debugging mode
;
; INPUT-FILES : None
;
; OUTPUT : the extracted spectrum
;
; DATASET : not changed
;
; QUALITY BITS : 0th and 3rd bit are checked
;
; DEBUG : nothing special
;
; MAIN ROUTINE : extr_stellar_spec_2.pro
;
; SAVES : see OUTPUT
;
; STATUS : not tested
;
; NOTES : - Many different datasets of the same (!!!) source can be treated.
;
; HISTORY : 3.3.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------


FUNCTION computspec_000, DataSet, Modules, Backbone

    COMMON APP_CONSTANTS

    functionName = 'computspec_000'
    ; save the starting time
    T = systime(1)

    drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1

    ; check integrity
    stModule =  check_module( DataSet, Modules, Backbone, functionName )
    if ( NOT bool_is_struct ( stModule ) ) then $
       return, error ('ERROR IN CALL ('+strtrim(functionName)+'): Integrity check failed.')

    ; now get the parameters
    b_Debug        = fix(Backbone->getParameter('computspec_COMMON___Debug')) eq 1
    d_SpecChannels = float(Backbone->getParameter('computspec_COMMON___SpecChannels'))
    s_ImgMode      = Backbone->getParameter('computspec_COMMON___ImgMode')
    s_PSFMode      = Backbone->getParameter('computspec_COMMON___PSFMode')
    d_ExtrRad      = float(Backbone->getParameter('computspec_COMMON___ExtractionRadius'))
    s_BGMode       = Backbone->getParameter('computspec_COMMON___BGMode')
    d_BGExtrRad    = float(Backbone->getParameter('computspec_COMMON___BGExtractionRadius'))
    d_OptSigma     = float(Backbone->getParameter('computspec_COMMON___OptClipSigma'))

    n_Sets   = Backbone->getValidFrameCount(DataSet.Name)

    ; parameter check takes also place in extr_stellar_spec_2
    s_Res = extr_stellar_spec_2( DataSet.Frames, DataSet.IntFrames, DataSet.IntAuxFrames, n_Sets, $
                                 d_SpecChannels, s_ImgMode, s_PSFMode, d_ExtrRad, $
                                 s_BGMode, d_BGExtrRad, OPT=d_OptSigma, DEBUG=b_Debug )

    if ( NOT bool_is_struct ( s_Res ) ) then $
       return, error ('FAILURE ('+strtrim(functionName)+'): Extraction of spectrum failed.')    

    ; Now, save the data
   
    thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
    c_File = make_filename ( DataSet.Headers[0], Modules[thisModuleIndex].OutputDir, stModule.SaveExt )
    if ( NOT bool_is_string(c_File) ) then $
       return, error('FAILURE ('+strtrim(functionName)+'): Output filename creation failed.')

    h_H = *DataSet.Headers[0]
    sxaddpar, h_H, 'EXTEND', 'T'
    sxaddpar, h_H, 'COMMNT0', 'First extension is spectrum'
    sxaddpar, h_H, 'COMMNT1', 'Second extension is intspectrum'
    sxaddpar, h_H, 'COMMNT2', 'Third extension is intauxspectrum'
    writefits, c_File, float(s_Res.Frame), h_H
    writefits, c_File, float(s_Res.IntFrame), /APPEND
    writefits, c_File, byte(s_Res.IntAuxFrame), /APPEND

    if ( b_Debug ) then begin
       debug_info, 'DEBUG INFO ('+strtrim(functionName)+'): File '+c_File+' successfully written.'
       fits_help, c_File
    end

    report_success, functionName, T

    return, OK

END
