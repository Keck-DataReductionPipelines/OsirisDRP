
;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; NAME: savedatset_000 
;
; PURPOSE: save spatially rectified master flatfield
;
; PARAMETERS IN RPBCONFIG.XML :
;    saveflatfi_COMMON___Debug : bool, initialize debugging mode
;
; INPUT-FILES : None
;
; OUTPUT : Saves the dataset pointer
;
; INPUT : as defined by DATASET
;
; DATASET : not changed
;
; QUALITY BITS : ignored
;
; DEBUG : nothing special
;
; MAIN ROUTINE : None
;
; SAVES : see OUTPUT
;
; NOTES : None
;
; STATUS : not tested
;
; HISTORY : 14.9.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION savedatset_000, DataSet, Modules, Backbone

    COMMON APP_CONSTANTS

    functionName = 'savedatset_000'
    ; save starting time
    T = systime(1)

    drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1

    ; check integrity
    stModule =  check_module( DataSet, Modules, Backbone, functionName )
    if ( NOT bool_is_struct ( stModule ) ) then $
       return, error ('ERROR IN CALL ('+strtrim(functionName)+'): Integrity check failed.')

    b_Debug = fix(Backbone->getParameter('savedatset_COMMON___Debug')) eq 1 

    thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
    b_Stat = save_dataset ( DataSet, Backbone->getValidFrameCount(DataSet.Name), $
                            Modules[thisModuleIndex].OutputDir, stModule.SaveExt, DEBUG=b_Debug )
    if ( b_Stat eq OK ) then begin
       report_success, functionName, T
       return, OK
    endif else return, b_Stat

end
