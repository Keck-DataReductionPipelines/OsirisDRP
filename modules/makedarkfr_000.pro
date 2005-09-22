;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; NAME:  makedarkfr_000
;
; PURPOSE: create a master dark frame
;
; PARAMETERS IN RPBCONFIG.XML :
;
;             makedarkfr_COMMON___Debug : initializes debugging mode
;             makedarkfr_COMMON___Mode  : 'MED' (medianing) or 'AVRG' (averaging)
;
; INPUT-FILES : None
;
; OUTPUT : Saves the master dark
;
; DATASET : not changed
;
; QUALITY BITS : 
;     0th     : checked
;     1st-3rd : ignored
;
; DEBUG : nothing special
;
; MAIN ROUTINE : average_frames.pro
;
; SAVES : see OUTPUT
;
; NOTES : - The master dark written to disk has 4 extensions.
;           0: frame, 1: intframe, 2: intauxframe, 3: # of pix used
;           for averaging
;
;         - The filename for the result is extracted from the 0th header.
;
;         - Currently only averaging is implemented
;
;         - At this stage of data reduction the inside bits are ignored.
;
; STATUS : not tested
;
; HISTORY : 6.8.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION makedarkfr_000, DataSet, Modules, Backbone

    COMMON APP_CONSTANTS

    functionName = 'makedarkfr_000'
    ; save the starting time
    T = systime(1)

    drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1

    ; check integrity
    stModule =  check_module( DataSet, Modules, Backbone, functionName )
    if ( NOT bool_is_struct ( stModule ) ) then $
       return, error ('ERROR IN CALL ('+strtrim(functionName)+'): Integrity check failed.')

    ; now get the parameters
    b_Debug = fix(Backbone->getParameter('makedarkfr_COMMON___Debug')) eq 1
    s_Mode  = Backbone->getParameter('makedarkfr_COMMON___Mode')
    if ( s_Mode ne 'AVRG' and s_Mode ne 'MED' ) then $
       return, error ('ERROR IN CALL ('+strtrim(functionName)+'): Mode must be AVRG or MED.')

    nFrames   = Backbone->getValidFrameCount(DataSet.Name)
    vb_Status = intarr(nFrames) + 1

    ; average the frames weighted
    s_Result  = average_frames ( DataSet.Frames, DataSet.IntFrames, DataSet.IntAuxFrames, $
                                 nFrames, STATUS=vb_Status, DEBUG=b_Debug, /VALIDS, MED=fix(s_Mode eq 'MED') )

    if ( NOT bool_is_struct ( s_Result ) ) then $
       return, error ( ['FAILURE ('+strtrim(functionName)+'): Frames could not be averaged'] )

    ; Now, save the data
    thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
    c_File = make_filename ( DataSet.Headers[0], Modules[thisModuleIndex].OutputDir, stModule.SaveExt )
    if ( NOT bool_is_string(c_File) ) then $
       return, error('FAILURE ('+strtrim(functionName)+'): Output filename creation failed.')

    ; one may need to add the EXTEND keyword
    h_H = *DataSet.Headers[0]
    sxaddpar, h_H, 'EXTEND', 'T'
    sxaddpar, h_H, 'COMMNT0', 'First image is dark frame'
    sxaddpar, h_H, 'COMMNT1', 'Second image is dark intframe'
    sxaddpar, h_H, 'COMMNT2', 'Third image is dark intauxframe'
    sxaddpar, h_H, 'COMMNT3', 'Fourth image is the number of valid pixel calculating the dark'
    writefits, c_File, float(s_Result.Frame), h_H
    writefits, c_File, float(s_Result.IntFrame), /APPEND
    writefits, c_File, byte(s_Result.IntAuxFrame), /APPEND
    writefits, c_File, byte(s_Result.NFrame), /APPEND

    if ( b_Debug eq 1 ) then begin
       debug_info, 'DEBUG INFO ('+strtrim(functionName)+'): File '+c_File+' successfully written.'
       fits_help, c_File
    end

    ; deleting the Dataset variables is not neccessary, there is no other
    ; module supposed to follow

    report_success, functionName, T

    RETURN, OK

END
