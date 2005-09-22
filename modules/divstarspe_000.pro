;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; NAME:   divstarspe_000
;
; PURPOSE:  divide by stellar spectrum
;
; PARAMETERS IN RPBCONFIG.XML :
;    divstarspe_COMMON___Debug : initializes the debugging mode
;    divstarspe_COMMON___Limit : minimum denominator allowed for stellar spectrum
;                                Must be gt 1.d-60
;
; INPUT-FILES : Stellar spectrum (1d)
;
; OUTPUT : None
;
; DATASET : Contains the divided data afterwards. The pointers are
;           not changed
;
; QUALITY BITS :
;          0th     : checked
;          1st-2nd : ignored
;          3rd     : checked
;
;          since the stellar spectrum is replicated to a cube, the 0th
;          and 3rd bit of the spctrum must be set correctly. 
;
; DEBUG : Saves all datasets
;
; SAVES : If Save tag in drf file is set to 1, the divided cubes are
;         saved. Ensure that when dealing with multiple input cubes
;         the DATAFILE keyword varies.
;
;
; NOTES : - This module works on cubes only.
;         - The stellar spectrum has been extracted from a cube, the
;           inside bit is set.
;
; STATUS : not tested
;
; HISTORY : 13.5.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION divstarspe_000, DataSet, Modules, Backbone

    COMMON APP_CONSTANTS

    functionName = 'divstarspe_000'
    ; save starting time
    T = systime(1)

    drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1

    ; check integrity
    stModule =  check_module( DataSet, Modules, Backbone, functionName )
    if ( NOT bool_is_struct ( stModule ) ) then $
       return, error ('ERROR IN CALL ('+strtrim(functionName)+'): Integrity check failed.')

    ; get the parameters
    b_Debug = fix(Backbone->getParameter('divstarspe_COMMON___Debug')) eq 1
    d_Limit = 1.d-20
    d_Limit = double(Backbone->getParameter('divstarspe_COMMON___Limit'))
    if ( d_Limit lt 1.d-60 ) then begin
       warning, ['ERROR IN CALL ('+strtrim(functionName)+'): divstarspe_COMMON__Limit in RPBconfig.xml must be greater', $
                 '              than 1.d-60. Setting divideflat_Limit internally (only for this module) to 1.d-60']
       d_Limit = 1.d-60
    end    

    ; get the input stellar spectrum which is already EURO3D compliant
    thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
    c_File = drpXlateFileName(Modules[thisModuleIndex].CalibrationFile)
    if ( NOT file_test ( c_File ) ) then $
       return, error('ERROR In CALL ('+strtrim(functionName)+'): File '+strtrim(string(c_File),2)+$
                     ' with stellar spectrum not found.')
    pvd_StarFrame       = ptr_new(readfits(c_File, h_Header ))
    pvd_StarIntFrame    = ptr_new(readfits(c_File, h_Header, EXTEN_NO=1 ))
    pvb_StarIntAuxFrame = ptr_new(readfits(c_File, h_Header, EXTEN_NO=2 ))

    if ( b_Debug ) then $
       debug_info, 'DEBUG INFO ('+strtrim(functionName)+'): Stellar spectrum loaded from '+ c_File

    if ( bool_pointer_integrity( pvd_StarFrame, pvd_StarIntFrame, pvb_StarIntAuxFrame, 1, $
                                 functionName, /VECTOR ) ne OK ) then $
       return, error('ERROR IN CALL ('+strtrim(functionName)+'): Integrity check of stellar spectrum failed.')

    ; all frames, intframes and intauxframes have the same dims
    n_Dims = size ( *DataSet.Frames(0) )

    ; replicate the stellar data to fit the input data
    p_Frame = ptr_new( replicate_vector( *pvd_StarFrame, n_Dims(2), n_Dims(3) ) )
    if ( NOT bool_is_cube ( *p_Frame ) ) then $
       return, error('FAILURE ('+strtrim(functionName)+'): Could not replicate stellar spectrum vector.')

    p_IntFrame = ptr_new( replicate_vector( *pvd_StarIntFrame, n_Dims(2), n_Dims(3) ) )
    if ( NOT bool_is_cube ( *p_IntFrame ) ) then $
       return, error('FAILURE ('+strtrim(functionName)+'): Could not replicate stellar noise vector.')

    p_IntAuxFrame = ptr_new( replicate_vector( *pvb_StarIntAuxFrame, n_Dims(2), n_Dims(3) ) )
    if ( NOT bool_is_cube ( *p_IntAuxFrame ) ) then $
       return, error('FAILURE ('+strtrim(functionName)+'): Could not replicate stellar quality vector.')

    if ( NOT bool_dim_match ( *DataSet.Frames(0), *p_Frame ) ) then $
       return, error ('ERROR IN CALL ('+strtrim(functionName)+'): Stellar spectrum does not fit in length with input cube.')

    nFrames = Backbone->getValidFrameCount(DataSet.Name)

    ; now loop over the input data sets
    for i=0, nFrames-1 do begin

       ; divide it
       vb_Status = frame_op( DataSet.Frames[i], DataSet.IntFrames[i], DataSet.IntAuxFrames[i], '/', $
                             p_Frame, p_IntFrame, p_IntAuxFrame, 1, MinDiv = d_Limit )

       if ( NOT bool_is_vector ( vb_Status ) ) then $
          warning, 'WARNING ('+strtrim(functionName)+'): Operation failed in set '+strtrim(string(i),2)+'.'

    end

    thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
    if ( Modules[thisModuleIndex].Save eq 1 ) then begin

       b_Stat = save_dataset ( DataSet, nFrames, Modules[thisModuleIndex].OutputDir, stModule.Save, DEBUG=b_Debug )
       if ( b_Stat eq OK ) then begin
          report_success, functionName, T
          return, OK
       endif else return, b_Stat

    end

end
