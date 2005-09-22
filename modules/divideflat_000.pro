
;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; NAME: divideflat_000 
;
; PURPOSE: Divide by flat field
;
; PARAMETERS IN RPBCONFIG.XML :
;              divideflat_COMMON___Limit : minimum denominator allowed for flat
;                                          field. Must be gt 1.d-60
;                                          and lt 1.d60
;              divideflat_COMMON___Debug : initializes debugging mode
;
; INPUT-FILES : master flat field
;
; OUTPUT : None
;
; DATASET : contains the flatfielded data afterwards. The number of
;           valid pointers is not changed.
;
; QUALITY BITS : 
;       2d frames : 
;          0th     : checked
;          1st-3rd : ignored         
;       3d frames : 
;          0th     : checked
;          1st-2nd : ignored         
;          3rd     : checked
;
; DEBUG : nothing special
;
; MAIN ROUTINE : frame_op.pro
; 
; SAVES : see Output
;
; NOTES : - Flatfielding takes place after the spatial rectification.
;           The frame that is flatfielded can be a frame or a
;           cube. The master flatfield just must have the same dimensions.
;           The inside bit is set after having made a cube. The inside
;           bit is ignored when working on 2d frames.
;
; STATUS : not tested
;
; HISTORY : 6.8.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION divideflat_000, DataSet, Modules, Backbone

    COMMON APP_CONSTANTS

    functionName = 'divideflat_000'
    ; save starting time
    T = systime(1)

    drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1

    ; check integrity
    stModule =  check_module( DataSet, Modules, Backbone, functionName )
    if ( NOT bool_is_struct ( stModule ) ) then $
       return, error ('ERROR IN CALL ('+strtrim(functionName)+'): Integrity check failed.')

    ; Get parameters
    d_FlatLimit = 1.d-20
    d_FlatLimit = double(Backbone->getParameter('divideflat_Limit'))
    if ( d_FlatLimit lt 1.d-60 ) then begin
       warning, ['ERROR IN CALL ('+strtrim(functionName)+'): divideflat_Limit in RPBconfig.xml must be greater', $
                 '              than 1.d-60. Setting divideflat_Limit internally (only for this module) to 1.d-60']
       d_FlatLimit = 1.d-60
    end    
    b_Debug = fix(Backbone->getParameter('divideflat_COMMON___Debug')) eq 1

    ; get the master flatfield
    thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
    c_File = drpXlateFileName(Modules[thisModuleIndex].CalibrationFile)
    if ( NOT file_test ( c_File ) ) then $
       return, error ('ERROR IN CALL ('+strtrim(functionName)+'): Master flatfield ' + $
                      strtrim(string(c_File),2) + ' not found.' )

    pmd_FlatFrame        = ptr_new(READFITS(c_File, Header, /SILENT))
    pmd_FlatIntFrame     = ptr_new(READFITS(c_File, Header, EXT=1, /SILENT))
    pmd_FlatIntAuxFrame  = ptr_new(READFITS(c_File, Header, EXT=2, /SILENT))

    if ( b_Debug ) then $
       debug_info, 'DEBUG INFO ('+strtrim(functionName)+'): Master flat loaded from '+ c_File

    if ( bool_pointer_integrity( pmd_FlatFrame, pmd_FlatIntFrame, pmd_FlatIntAuxFrame, 1, $
                                 functionName ) ne OK ) then $
       return, error('ERROR IN CALL ('+strtrim(functionName)+'): Integrity check of master flat failed.')

    ; check master flat and data frames dimensions
    if ( NOT bool_dim_match ( *pmd_FlatFrame, *DataSet.Frames[0] ) ) then $
       return, error('ERROR ('+strtrim(functionName)+'): Master flat and data frames not compatible in size.')

    nFrames = Backbone->getValidFrameCount(DataSet.Name)

    vb_Status = frame_op( DataSet.Frames, DataSet.IntFrames, DataSet.IntAuxFrames, '/', $
                          pmd_FlatFrame, pmd_FlatIntFrame, pmd_FlatIntAuxFrame, nFrames, $
                          MinDiv = d_FlatLimit, DEBUG = b_Debug, VALIDS=bool_is_image (*pmd_FlatFrame) )
    if ( NOT bool_is_vector ( vb_Status ) ) then $
       return, error('WARNING ('+strtrim(functionName)+'): Flat field division failed.')

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
