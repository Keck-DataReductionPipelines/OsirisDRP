
;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; NAME:  subtradark_000
;
; PURPOSE: subtract the master dark frame
;
; PARAMETERS IN RPBCONFIG.XML :
;
;    subtradark_COMMON___Debug : bool, initializes the debugging mode
;
; INPUT-FILES : master dark 
;
; OUTPUT : None
;
; DATASET : contains the dark subtracted data afterwards. The number of
;           valid pointers is not changed.
;
; QUALITY BITS : 0th     : checked
;                1st-3rd : ignored
;
; DEBUG : nothing special
;
; MAIN ROUTINE : frame_op.pro
;
; SAVES : Nothing
;
; NOTES : - The inside bit is ignored.
;
;         - Input frames must be 2d.
;
; STATUS : not tested
;
; HISTORY : 6.8.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION subtradark_000, DataSet, Modules, Backbone

    COMMON APP_CONSTANTS

    functionName = 'subtradark_000'
    ; save the starting time
    T = systime(1)

    drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1

    ; check integrity
    stModule =  check_module( DataSet, Modules, Backbone, functionName )
    if ( NOT bool_is_struct ( stModule ) ) then $
       return, error ('ERROR IN CALL ('+strtrim(functionName)+'): Integrity check failed.')

    ; get the parameters
    b_Debug = fix(Backbone->getParameter('subtradark_COMMON___Debug')) eq 1

    ; get the master dark
    thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
    c_File = drpXlateFileName(Modules[thisModuleIndex].CalibrationFile)
    if ( NOT file_test ( c_File ) ) then $
       return, error ('ERROR IN CALL ('+strtrim(functionName)+'): Master dark ' + $
                      strtrim(string(c_File),2) + ' not found.' )

    pmd_DarkFrame       = ptr_new(READFITS(c_File, Header, /SILENT))
    pmd_DarkIntFrame    = ptr_new(READFITS(c_File, Header, EXT=1, /SILENT))
    pmb_DarkIntAuxFrame = ptr_new(READFITS(c_File, Header, EXT=2, /SILENT))

    if ( b_Debug ) then $
       debug_info, 'DEBUG INFO ('+strtrim(functionName)+'): Master dark loaded from '+ c_File

    if ( bool_pointer_integrity( pmd_DarkFrame, pmd_DarkIntFrame, pmb_DarkIntAuxFrame, 1, $
                                 functionName ) ne OK ) then $
       return, error('ERROR IN CALL ('+strtrim(functionName)+'): Integrity check of master dark failed.')

    ; check master darks and data frames dimensions
    if ( NOT bool_dim_match ( *pmd_DarkFrame, *DataSet.Frames[0] ) ) then $
       return, error('ERROR ('+strtrim(functionName)+'): Master dark and data frames not compatible in size')

    nFrames = Backbone->getValidFrameCount(DataSet.Name)
    ; do the subtraction
    vb_Status = frame_op( DataSet.Frames, DataSet.IntFrames, DataSet.IntAuxFrames, '-', $
                          pmd_DarkFrame, pmd_DarkIntFrame, pmb_DarkIntAuxFrame, nFrames, Debug=b_Debug, /VALIDS )

    if ( NOT bool_is_vector ( vb_Status ) ) then $
       return, error('FAILURE ('+strtrim(functionName)+'): Dark subtraction failed')

    ; it is not neccessary to change the dataset pointer

    report_success, functionName, T

    RETURN, OK

END
