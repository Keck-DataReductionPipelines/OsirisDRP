;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; NAME:  badpixnois_000
;
; PURPOSE: find bad pixels from noise, uses darks
;
; PARAMETERS IN RPBCONFIG.XML :
;
;    badpixnois_COMMON___Debug
;    badpixnois_COMMON___loReject
;    badpixnois_COMMON___hiReject
;    badpixnois_COMMON___threshSigmaFactor
;    badpixnois_COMMON___llxf
;    badpixnois_COMMON___llyf
;    badpixnois_COMMON___urxf
;    badpixnois_COMMON___uryf
;           for meaning see search_bad_pixels_via_noise.pro
;
; INPUT-FILES : None
;
; OUTPUT : Bad pixel mask (1:good, 0:bad)
;
; DATASET : not changed
;
; QUALITY BITS: 
;                0th     : checked
;                1st-3rd : ignored
;
; DEBUG : nothing special
;
; MAIN ROUTINE : search_bad_pixels_via_noise.pro
;
; SAVES : see OUTPUT
;
; NOTES : - the noise of a pixel is determined from the various frames
;           not from the intframe values
;         - other bad pixel searching routines may follow
;
; STATUS : not tested
;
; HISTORY : 12.8.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION badpixnois_000, DataSet, Modules, Backbone

    COMMON APP_CONSTANTS

    functionName = 'badpixnois_000'
    ; save starting time
    T = systime(1)

    drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1

    ; check integrity
    stModule =  check_module( DataSet, Modules, Backbone, functionName )
    if ( NOT bool_is_struct ( stModule ) ) then $
       return, error ('ERROR IN CALL ('+strtrim(functionName)+'): Integrity check failed.')

    ; the integrity is ok, now run

    b_Debug          = fix(Backbone->getParameter('badpixnois_COMMON___Debug')) eq 1
    d_loreject       = float(Backbone->getParameter('badpixnois_COMMON___loReject'))
    d_hireject       = float(Backbone->getParameter('badpixnois_COMMON___hiReject'))  
    d_thresholdsigma = float(Backbone->getParameter('badpixnois_COMMON___threshSigmaFactor'))
    d_fllx           = float(Backbone->getParameter('badpixnois_COMMON___llxf'))
    d_flly           = float(Backbone->getParameter('badpixnois_COMMON___llyf')) 
    d_furx           = float(Backbone->getParameter('badpixnois_COMMON___urxf')) 
    d_fury           = float(Backbone->getParameter('badpixnois_COMMON___uryf'))                    

    n_Dims = size(*DataSet.Frames[0])
    n_Sets = Backbone->getValidFrameCount(DataSet.Name)

    mi_BadMask = search_bad_pixels_via_noise( DataSet.Frames, DataSet.IntFrames, DataSet.IntAuxFrames, $
                                              n_Sets, d_thresholdsigma, d_loreject, d_hireject,$
                                              fix(d_fllx*n_Dims(1)), fix(d_flly*n_Dims(2)), $
                                              fix(d_furx*n_Dims(1)), fix(d_fury*n_Dims(2)), DEBUG=b_Debug )

    ; Now, save the data
    thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
    c_File = make_filename ( DataSet.Headers[0], Modules[thisModuleIndex].OutputDir, stModule.SaveExt )
    if ( NOT bool_is_string(c_File) ) then $
       return, error('FAILURE ('+strtrim(functionName)+'): Output filename creation failed.')

    writefits, c_File, byte(mi_BadMask)

    if ( b_Debug ) then begin
       debug_info, 'DEBUG INFO ('+strtrim(functionName)+'): File '+c_File+' successfully written.'
       fits_help, c_File
    end

    report_success, functionName, T

    return, OK

END
