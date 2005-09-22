;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; NAME:  corrdisper_000
;
; PURPOSE: correct atmospheric dispersion effects
;
; PARAMETERS IN RPBCONFIG.XML :
;               corrdisper_COMMON___Cubic : parameter determining the
;                                           cubic spline interpolation 
;                                           used when shifting slices
;                                           (see IDL built-in function
;                                           'interpolate'), default = -0.5
;               corrdisper_COMMON___Debug : inititalizes the debugging
;                                           mode
;
; INPUT-FILES : dispersion offsets determined by fitdispers_000.pro
;
; OUTPUT : None
;
; DATASET : The frames are corrected. The dataset pointers are not
;           changed.
;
; QUALITY BITS :
;
; DEBUG : Nothing special
;
; MAIN ROUTINE : mosaic.pro
;
; SAVES : see OUTPUT
;
; NOTES :  None
;
; STATUS : not tested
;
; HISTORY : 5.4.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION corrdisper_000, DataSet, Modules, Backbone

    COMMON APP_CONSTANTS

    functionName = 'corrdisper_000'
    ; save the starting time
    T = systime(1)

    drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1

    ; check integrity
    stModule = check_module( DataSet, Modules, Backbone, functionName )
    if ( NOT bool_is_struct ( stModule ) ) then $
       return, error ('ERROR IN CALL ('+strtrim(functionName)+'): Integrity check failed.')

    ; get the parameters
    d_Cubic = float(Backbone->getParameter('corrdisper_COMMON___Cubic'))
    b_Debug = fix(Backbone->getParameter('corrdisper_COMMON___Debug')) eq 1

    ; read output filename for the atmospheric dispersion corrected data
    thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
    c_File          = drpXlateFileName(Modules[thisModuleIndex].CalibrationFile)
    if ( NOT file_test ( c_File ) ) then $
       return, error ('ERROR IN CALL ('+strtrim(functionName)+'): File ' + strg(c_File) + $
                         ' with atmospheric dispersion offsets could not be found' )

    ; all further integrity checks are done in mosaic.pro

    n_Sets = Backbone->getValidFrameCount(DataSet.Name)
    s_Res  = mosaic( DataSet.Frames, DataSet.IntFrames, DataSet.IntAuxFrames, $
                     n_Sets, DISPERSION=c_File, CUBIC=d_Cubic, DEBUG=b_Debug)

    ; if no error occured mosaic returns a structure
    if ( NOT bool_is_struct(s_Res) ) then $
       return, error('FAILURE ('+strtrim(functionName)+'): Correction failed.')

    ; save the result
    thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
    if ( Modules[thisModuleIndex].Save eq 1 ) then begin
       ; save the result
       c_File = make_filename ( DataSet.Headers[0], Modules[thisModuleIndex].OutputDir, $
                                stModule.Save )
       if ( NOT bool_is_string(c_File) ) then $
          return, error('FAILURE ('+strtrim(functionName)+'): Output filename creation failed.')

       writefits, c_File, float(*DataSet.Frames[0]), *DataSet.Headers[0]
       writefits, c_File, float(*DataSet.IntFrames[0]), /APPEND
       writefits, c_File, byte(*DataSet.IntAuxFrames[0]), /APPEND

       if ( b_Debug ) then begin
          info, 'INFO ('+strtrim(functionName)+'): File ' + c_File + ' successfully written.'
          fits_help, c_File
       end

    end

    report_success, functionName, T

    return, OK

END
