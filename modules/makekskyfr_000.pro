;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; NAME:  makekskyfr_000
;
; PURPOSE: prepares a sky frame
;
; ALLOWED BRANCH IDS: ARP_SPEC, SRP_SPEC, ORP_SPEC, ORP_IMAG, SRP_IMAG
;
; PARAMETERS IN RPBCONFIG.XML : 
;    makekskyfr_COMMON___Debug : bool, initializes the debugging mode
;
; MINIMUM/MAXIMUM NUMBER OF ALLOWED INPUT DATASETS : 1/-, must be even
;
; INPUT-FILES : None
;
; OUTPUT : saves the prepared sky frame
;
; INPUT : 2d frames
;
; DATASET : will not be changed but no other module is supposed to follow
;
; QUALITY BITS : 0th     : checked
;                1st-3rd : ignored
;
; SPECIAL FITSKEYWORDS : ISSKY and ISOBJ required
;
; DEBUG : nothing special
;
; MAIN ROUTINE : average_frames.pro
;
; SAVES : see OUTPUT
;
; STATUS : not tested
;
; HISTORY : 13.5.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION makekskyfr_000, DataSet, Modules, Backbone

    COMMON APP_CONSTANTS

    functionName = 'makekskyfr_000'
    ; save starting time
    T = systime(1)

    drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1

    ; check integrity

    BranchID = Backbone->getType()

    if ( NOT ( BranchID eq 'ARP_SPEC' or BranchID eq 'SRP_SPEC' or BranchID eq 'ORP_SPEC' or $
         BranchID eq 'ORP_IMAG' or BranchID eq 'SRP_IMAG' ) ) then $
       return, error('ERROR IN CALL (' + functionName + '): Wrong Branch ID.')

    n_Sets = Backbone->getValidFrameCount(DataSet.Name)

    ; check integrity
    if ( bool_dataset_integrity( DataSet, Backbone, functionName, /IMAGE ) ne OK ) then $
       return, error ('ERROR IN CALL ('+functionName+'): integrity check failed.')

    ; integrity ok
    b_Debug = fix(Backbone->getParameter('makekskyfr_COMMON___Debug')) eq 1

    vi_issky = where( fix( get_kwd( DataSet.Headers, n_Sets, 'ISSKY' )) eq 1 and $
                      fix( get_kwd( DataSet.Headers, n_Sets, 'ISOBJ' )) eq 0, n_Sky )

    if ( n_Sky eq 0 ) then $
       return, error ('ERROR IN CALL (subtracsky_000.pro): No Skys found.') $
    else $
       info, 'INFO (makekskyfr_000.pro): Found '+strg(n_Sky) + ' sky frames.'

    ; average the frames weighted
    s_Result  = average_frames ( DataSet.Frames[vi_issky], DataSet.IntFrames[vi_issky], $
                                 DataSet.IntAuxFrames[vi_issky], n_Sky, DEBUG=b_Debug, /VALIDS )

    if ( NOT bool_is_struct ( s_Result ) ) then $
       return, error ( ['FAILURE (makekdarkfr_000.pro): Frames could not be averaged'] )

    ; Now, save the data
    thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
    c_File = make_filename ( DataSet.Headers[0], Modules[thisModuleIndex].OutputDir, 'SKY' )
    if ( NOT bool_is_string(c_File) ) then $
       return, error('FAILURE (makekskyfr_000.pro): Output filename creation failed.')

    ; one may need to add the EXTEND keyword
    h_H = *DataSet.Headers[0]
    sxaddpar, h_H, 'EXTEND', 'T'
    writefits, c_File, float(s_Result.Frame), h_H
    writefits, c_File, float(s_Result.IntFrame), /APPEND
    writefits, c_File, byte(s_Result.IntAuxFrame), /APPEND
    writefits, c_File, byte(s_Result.NFrame), /APPEND

    if ( b_Debug eq 1 ) then begin
       debug_info, 'DEBUG INFO (makekskyfr_000.pro): File '+c_File+' successfully written.'
       fits_help, c_File
    end

    drpLog, functionName+' succesfully completed after ' + strg(systime(1)-T) + ' seconds.', /DRF, DEPTH = 1

    return, OK

END
