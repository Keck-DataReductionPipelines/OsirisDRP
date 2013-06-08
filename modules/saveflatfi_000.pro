
;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; NAME: saveflatfi_000 
;
; PURPOSE: save spatially rectified master flatfield
;
; PARAMETERS IN RPBCONFIG.XML :
;    saveflatfi_COMMON___Debug : bool, initialize debugging mode
;
; INPUT-FILES : None
;
; OUTPUT : Saves the flatfield
;
; DATASET : not changed
;
; DEBUG : nothing special
;
; MAIN ROUTINE : None
;
; SAVES : see OUTPUT
;
; NOTES : This module saves regardless of branch id or content always
;         the 0th pointers of DataSet.
;
; STATUS : not tested
;
; HISTORY : 8.8.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION saveflatfi_000, DataSet, Modules, Backbone

    COMMON APP_CONSTANTS

    functionName = 'saveflatfi_000'
    ; save starting time
    T = systime(1)

    drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1

    ; check integrity
    stModule =  check_module( DataSet, Modules, Backbone, functionName )
    if ( NOT bool_is_struct ( stModule ) ) then $
       return, error ('ERROR IN CALL ('+strtrim(functionName)+'): Integrity check failed.')
    ; integrity is ok

    b_Debug = fix(Backbone->getParameter('saveflatfi_COMMON___Debug')) eq 1 

    ; Now, save the data
    thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
    c_File = make_filename ( DataSet.Headers[0], Modules[thisModuleIndex].OutputDir, stModule.SaveExt )
    if ( NOT bool_is_string(c_File) ) then $
       return, error('FAILURE ('+strtrim(functionName)+'): Output filename creation failed.')

    h_H = *DataSet.Headers[0]
    sxaddpar, h_H, 'EXTEND', 'T'
    sxaddpar, h_H, 'COMMENT0', 'This is a spectrometer flatfield'
    sxaddpar, h_H, 'COMMENT1', 'First image is the flatfield frame'
    sxaddpar, h_H, 'COMMENT2', 'Second image is the flatfield intframe'
    sxaddpar, h_H, 'COMMENT3', 'Third image is the flatfield intauxframe'
    writefits, c_File, float(*DataSet.Frames[0]), h_H
    writefits, c_File, float(*DataSet.IntFrames[0]), /APPEND
    writefits, c_File, byte(*DataSet.IntAuxFrames[0]), /APPEND

    if ( b_Debug ) then begin
       debug_info, 'DEBUG INFO ('+strtrim(functionName)+'): File '+c_File+' successfully written.'
       fits_help, c_File
    end

    report_success, functionName, T

    return, OK

end
