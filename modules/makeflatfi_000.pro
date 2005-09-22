;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; NAME:  makeflatfi_000
;
; PURPOSE: create a master flatfield
;
; PARAMETERS IN RPBCONFIG.XML :
;
;              makeflatfi_COMMON___Debug     : initializes debugging mode
;              makeflatfi_COMMON___Mode      : 'MED' (medianing) or 'AVRG' (averaging)
;
; INPUT-FILES : None
;
; OUTPUT : CRP_IMAG : saves the master flat field, dataset unchanged
;          CRP_SPEC : updates the dataset, the master is put into the
;                     0th index, others are deleted.
;
; DATASET : see OUTPUT
;
; QUALITY BITS : 
;     0th     : checked
;     1st-3rd : ignored
;
; DEBUG : nothing special
;
; MAIN ROUTINE : average_frames.pro, frame_op
;
; SAVES : see OUTPUT
;
; NOTES : - currently only averaging is implemented according to average_frames.pro
;
;         - For the IMAG branch this module creates the final master
;           flat. For the SPEC branch, the spatial rectification
;           module and the saveflatfi_000.pro must be called afterwards.
;
;         - the IMAG flatfield written to disk has 5 extensions.
;           0: frame, 1: intframe, 2: intauxframe, 3: # of pix valid
;           for ON calculation, 4: # of pix valid for OFF calculation
;
;         - The filename for the result is extracted from the 0th header.
;
;         - At this stage of data reduction the inside bits are ignored.
;
; ALGORITHM :
;         - identify ON and OFF frames be looking at the median values
;         - average ON and OFF frames separately according average_frames.pro
;         - calculate the master flatfield (ON-OFF)
;
; STATUS : not tested
;
; HISTORY : 12.8.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION makeflatfi_000, DataSet, Modules, Backbone

    COMMON APP_CONSTANTS

    functionName = 'makeflatfi_000'
    ; save the starting time
    T = systime(1)

    drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1

    ; check integrity
    stModule =  check_module( DataSet, Modules, Backbone, functionName )
    if ( NOT bool_is_struct ( stModule ) ) then $
       return, error ('ERROR IN CALL ('+strtrim(functionName)+'): Integrity check failed.')

    ; Get all COMMON parameter values
    b_Debug = fix(Backbone->getParameter('makeflatfi_COMMON___Debug')) eq 1
    s_Mode  = Backbone->getParameter('makeflatfi_COMMON___Mode')
    if ( s_Mode ne 'AVRG' and s_Mode ne 'MED' ) then $
       return, error ('ERROR IN CALL ('+strtrim(functionName)+'): Mode must be AVRG or MED.')

    if ( b_Debug ) then $
       debug_info,'DEBUG INFO ('+strtrim(functionName)+'): Checking ' + strg(nFrames) + ' flats for on and off.'

    nFrames = Backbone->getValidFrameCount(DataSet.Name)
    ; boolean vector indicating whether frame i is on (1) or off (0)
    vb_On = intarr(nFrames)

    ; ON frames have higher median values than OFF frames. So check median
    ; values to find the Ons and Offs

    ; median of frames
    vd_Median = fltarr(nFrames)

    ; find ONs and OFFs
    FOR i=0, nFrames-1 DO vd_Median[i] = median ( *DataSet.Frames(i) )
    if ( b_Debug ) then $
       debug_info,'DEBUG INFO ('+strtrim(functionName)+'): Found median values of flatfields to be ' + strg(vd_Median)
    vb_On( (reverse(sort ( vd_Median )))(0:nFrames/2-1) ) = 1

    if ( b_Debug ) then $
       for i=0, nFrames-1 do $
          debug_info,'DEBUG INFO ('+strtrim(functionName)+'): Frame '+strtrim(string(i),2) + $
                     ' is ' + ((vb_On(i) eq 1) ? 'ON' : 'OFF')

    ; create pointer arrays holding the ONs and OFFs
    vi_OnMask  = where(vb_On eq 1, n_On)
    vi_OffMask = where(vb_On eq 0, n_Off)

    if ( n_On ne n_Off or n_On eq 0 or n_Off eq 0 or total(vb_On) ne nFrames/2) then $
       return, error ('FATAL ERROR ('+strtrim(functionName)+'): Number of ons or offs not determinable.')

    vp_OnFrame        = DataSet.Frames(vi_OnMask)
    vp_OffFrame       = DataSet.Frames(vi_OffMask)
    vp_OnIntFrame     = DataSet.IntFrames(vi_OnMask)
    vp_OffIntFrame    = DataSet.IntFrames(vi_OffMask)
    vp_OnIntAuxFrame  = DataSet.IntAuxFrames(vi_OnMask)
    vp_OffIntAuxFrame = DataSet.IntAuxFrames(vi_OffMask)

    ; deal with the Ons first
    vb_StatusOn = intarr(nFrames/2)+1

    ; average the frames weighted
    s_ResultOn  = average_frames ( vp_OnFrame, vp_OnIntFrame, vp_OnIntAuxFrame, $
                                   nFrames/2, STATUS=vb_StatusOn, DEBUG=b_Debug, /VALIDS, MED=fix(s_Mode eq 'MED') )
    if ( NOT bool_is_struct ( s_ResultOn ) ) then $
       return, error ( ['FAILURE ('+strtrim(functionName)+'): On Frames could not be averaged'] )

    ; then deal with the Offs
    vb_StatusOff = intarr(nFrames/2)+1

    ; average the frames weighted
    s_ResultOff = average_frames ( vp_OffFrame, vp_OffIntFrame, vp_OffIntAuxFrame, $
                                   nFrames/2, STATUS=vb_StatusOff, DEBUG=b_Debug, /VALIDS, MED=fix(s_Mode eq 'MED') )
    if ( NOT bool_is_struct ( s_ResultOff ) ) then $
       return, error ( ['FAILURE ('+strtrim(functionName)+'): Off Frames could not be averaged'] )

    p_FrameOn        = ptr_new ( s_ResultOn.Frame )
    p_FrameOff       = ptr_new ( s_ResultOff.Frame )
    p_IntFrameOn     = ptr_new ( s_ResultOn.IntFrame )
    p_IntFrameOff    = ptr_new ( s_ResultOff.IntFrame )
    p_IntAuxFrameOn  = ptr_new ( s_ResultOn.IntAuxFrame )
    p_IntAuxFrameOff = ptr_new ( s_ResultOff.IntAuxFrame )

    vb_Status = frame_op( p_FrameOn, p_IntFrameOn, p_IntAuxFrameOn, '-', $
                          p_FrameOff, p_IntFrameOff, p_IntAuxFrameOff, 1, /VALIDS )
    if ( NOT bool_is_vector ( vb_Status ) ) then $
       return, error('FAILURE ('+strtrim(functionName)+'): On-Off subtraction failed.')

    ; cast the result
    *p_FrameOn         = float(*p_FrameOn)    
    *p_IntFrameOn      = float(*p_IntFrameOn)
    *p_IntAuxFrameOn   = byte(*p_IntAuxFrameOn)
    s_ResultOn.NFrame  = byte(s_ResultOn.NFrame)
    s_ResultOff.NFrame = byte(s_ResultOff.NFrame)

    ; now check whether we have to save the IMAG data or wait for the
    ; spatial rectification

    if ( Backbone->getType() eq 'CRP_IMAG' ) then begin

       ; Now, save the data
       thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
       c_File = make_filename ( DataSet.Headers[0], Modules[thisModuleIndex].OutputDir, stModule.SaveExt )
       if ( NOT bool_is_string(c_File) ) then $
          return, error('FAILURE ('+strtrim(functionName)+'): Output filename creation failed.')

       h_H = *DataSet.Headers[0]
       sxaddpar, h_H, 'EXTEND', 'T'
       sxaddpar, h_H, 'COMMNT0', 'This is an imager flatfield'
       sxaddpar, h_H, 'COMMNT1', 'First image is the flatfield frame'
       sxaddpar, h_H, 'COMMNT2', 'Second image is the flatfield intframe'
       sxaddpar, h_H, 'COMMNT3', 'Third image is the flatfield intauxframe'
       sxaddpar, h_H, 'COMMNT4', 'Fourth image is the number of valid pixel calculating the ON'
       sxaddpar, h_H, 'COMMNT5', 'Fifth image is the number of valid pixel calculating the OFF'
       writefits, c_File, float(*p_FrameOn), h_H
       writefits, c_File, float(*p_IntFrameOn), /APPEND
       writefits, c_File, byte(*p_IntAuxFrameOn), /APPEND
       writefits, c_File, byte(s_ResultOn.NFrame), /APPEND
       writefits, c_File, byte(s_ResultOff.NFrame), /APPEND

       if ( b_Debug ) then begin
          debug_info, 'DEBUG INFO ('+strtrim(functionName)+'): File '+c_File+' successfully written.'
          fits_help, c_File
       end

    endif else begin

       ; This is going to be an spectrometer flatfield

       h_H = *DataSet.Headers(0)

       ; we are done now free all input data and put the result into place
       for i=0, nFrames-1 do $
          delete_frame, DataSet, i, /ALL

       *DataSet.Frames(0)       = *p_FrameOn
       *DataSet.IntFrames(0)    = *p_IntAuxFrameOn
       *DataSet.IntAuxFrames(0) = *p_IntAuxFrameOn
       *DataSet.Headers(0)      = h_H

       nFrames = Backbone->getValidFrameCount(DataSet.Name)
       if ( nFrames ne 1 ) then $
          return, error('FAILURE ('+strtrim(functionName)+'): Mode CRP_SPEC, failed to reset ValidFrameCount')

    end

    report_success, functionName, T

    Return, OK

END
