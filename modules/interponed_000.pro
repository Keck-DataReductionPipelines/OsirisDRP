;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; NAME:  interponed_000
;
; PURPOSE: interpolate bad pixel
;
; PARAMETERS IN RPBCONFIG.XML :
;
;             interponed_COMMON___Debug    : initializes debugging mode
;             interponed_COMMON___BadMult  : Noise multiplier
;             interponed_COMMON___GoodMult : Noise multiplier
;
; INPUT-FILES : optionally 2d or 3d bad pixel mask
;
; OUTPUT : None
;
; DATASET : dataset will be updated
;
; QUALITY BITS : 
;     2d : only 0th bit checked
;     3d : only 0th and 3rd bit checked
;
; DEBUG : nothing special
;
; MAIN ROUTINE : interponed.pro
;      Pixels are interpolated that are invalid according to
;      valid(/VALIDS). 
;
; SAVES : see OUTPUT
;
; NOTES : None
;
; STATUS : not tested
;
; HISTORY : 11.9.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION interponed_000, DataSet, Modules, Backbone

    COMMON APP_CONSTANTS

    functionName = 'interponed_000'
    ; save starting time
    T = systime(1)

    drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1

    ; check integrity
    stModule =  check_module( DataSet, Modules, Backbone, functionName )
    if ( NOT bool_is_struct ( stModule ) ) then $
       return, error ('ERROR IN CALL ('+strtrim(functionName)+'): Integrity check failed.')

    ; now get the parameters
    b_Debug    = fix(Backbone->getParameter('interponed_COMMON___Debug')) eq 1
    d_BadMult  = float(Backbone->getParameter('interponed_COMMON___BadMult'))
    d_GoodMult = float(Backbone->getParameter('interponed_COMMON___GoodMult'))

    nFrames  = Backbone->getValidFrameCount(DataSet.Name)

    ; get the bad pixel mask
    thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
    c_File = drpXlateFileName(Modules[thisModuleIndex].CalibrationFile)

    if ( strg(c_File) ne '/' ) then begin

       if ( NOT file_test ( c_File ) ) then $
          return, error ('ERROR IN CALL ('+strtrim(functionName)+'): Bad pixel mask ' + $
                         strg(c_File) + ' not found.' )

       pmd_BadFrame = ptr_new(READFITS(c_File, Header, /SILENT))

       if ( b_Debug ) then $
          debug_info, 'DEBUG INFO ('+strtrim(functionName)+'): Bad pixel mask loaded from '+ c_File

       vl_Res = interponed ( DataSet.Frames, DataSet.IntFrames, DataSet.IntAuxFrames, nFrames, $
                             d_BadMult, d_GoodMult, MASK = pmd_BadFrame, DEBUG = b_Debug )
    endif else $
       vl_Res = interponed ( DataSet.Frames, DataSet.IntFrames, DataSet.IntAuxFrames, nFrames, $
                             d_BadMult, d_GoodMult, DEBUG = b_Debug )

    if ( NOT bool_is_vector (vl_Res) ) then $
       return, error ('ERROR ('+strtrim(functionName)+'): interpolation failed.')

    for i=0, nFrames-1 do $
       if ( vl_Res(0) ne 0L ) then $
          warning, 'WARNING ('+strtrim(functionName)+'): In set '+strg(i)+', '+strg(vl_Res)+' pixels not interpolated.'

    thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
    if ( Modules[thisModuleIndex].Save eq 1 ) then begin

       b_Stat = save_dataset ( DataSet, Backbone->getValidFrameCount(DataSet.Name), $
                            Modules[thisModuleIndex].OutputDir, stModule.Save, DEBUG=b_Debug )
       if ( b_Stat ne OK ) then $
          return, error ('FAILURE ('+functionName+'): Failed to save dataset.')

    end

    report_success, functionName, T

    RETURN, OK

END
