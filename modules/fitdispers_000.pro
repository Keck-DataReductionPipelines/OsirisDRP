;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; NAME: fitdispers_000
;
; PURPOSE: correct atmospheric dispersion effects
;
; PARAMETERS IN RPBCONFIG.XML :
;
;    fitdispers_COMMON___Debug : initializes the debugging mode
;
;    fitdispers_COMMON___Func  : Function to be used when determining the
;                                PSF centroid ('GAUSS', 'LORENTZ',
;                                'MOFFAT')
;    fitdispers_COMMON___Step  : Step through the cube with steps of
;                                this size
;
; INPUT-FILES : None
;
; OUTPUT : Saves the found offsets ( fltarr(2,number of spectral channels) )
;
; DATASET : not changed
;
; QUALITY BITS : 
;         0th     : checked
;         1st-2nd : ignored
;         3rd     : checked
;
; DEBUG : nothing special
;
; MAIN ROUTINE : fit_dispersion.pro
;
; SAVES : see OUTPUT
;
; NOTES : Input cube must be EURO3D compliant.
;
; STATUS : not tested
;
; HISTORY : 5.4.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION fitdispers_000, DataSet, Modules, Backbone

    COMMON APP_CONSTANTS

    functionName = 'fitdispers_000'
    ; save starting time
    T = systime(1)

    drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1

    ; check integrity
    stModule =  check_module( DataSet, Modules, Backbone, functionName )
    if ( NOT bool_is_struct ( stModule ) ) then $
       return, error ('ERROR IN CALL ('+strtrim(functionName)+'): Integrity check failed.')

    ; get the parameters
    c_Func  = Backbone->getParameter('fitdispers_COMMON___Func')
    b_Debug = fix(Backbone->getParameter('fitdispers_COMMON___Debug')) eq 1
    i_Step  = fix(Backbone->getParameter('fitdispers_COMMON___Step'))

    ; calculate the offsets
    s_Result = fit_dispersion ( DataSet.Frames[0], DataSet.IntFrames[0], DataSet.IntAuxFrames[0], $
                                c_Func, i_Step, DEBUG=b_Debug )

    ; if no error occured fit_dispersion returns a matrix
    if ( NOT bool_is_struct (s_Result) ) then $ 
       return, error('FAILURE ('+strtrim(functionName)+'): fit atmospheric dispersion failed. No offset list saved.')

    ; save the result
    thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
    c_File = make_filename ( DataSet.Headers[0], Modules[thisModuleIndex].OutputDir, stModule.SaveExt )
    if ( NOT bool_is_string(c_File) ) then $
       return, error(['FAILURE ('+strtrim(functionName)+'): filename creation for calibration output failed.'])

    mkhdr, h_Header, s_Result.m_Offsets
    sxaddpar, h_Header, 'EXTEND', 'T'
    sxaddpar, h_Header, 'COMMNT', 'Output of fitdispers module'
    sxaddpar, h_Header, 'COMMNT', 'First dimension : Offsets in pixel (x,y) for shifting planes'
    sxaddpar, h_Header, 'COMMNT', 'Second dimension : First axis , spatial x/y'
    sxaddpar, h_Header, 'COMMNT', 'Third dimension : Second axis , dispersion axis'
    writefits, c_File, float(s_Result.m_Offsets), h_Header
    writefits, c_File, float(s_Result.m_Center), /append

    if ( b_Debug ) then begin
       debug_info, 'DEBUG INFO ('+strtrim(functionName)+'): Offset list succesfully written to:' + c_File
       fits_help, c_File
    end

    report_success, functionName, T

    RETURN, OK

END
