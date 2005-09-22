;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; NAME:   divblackbo_000
;
; PURPOSE:  divide by a black body of given temperature
;
; PARAMETERS IN RPBCONFIG.XML :
;    divblackbo_COMMON___Debug        : initializes the debugging mode
;    divblackbo_COMMON___Temperature  : the blackbody temperature
;    divblackbo_COMMON___Multiplicate : multiplicates with the
;                                       blackbody '1' or divides '0'
;
; INPUT-FILES : None
;
; OUTPUT : None
;
; INPUT : 3d frames (cubes)
;
; DATASET : Contains the divided data afterwards. The pointers are
;           not changed
;
; QUALITY BITS :
;          0th     : checked
;          1st-2nd : ignored
;          3rd     : checked
;
; DEBUG : Plots the blackbody spectrum
;
; SAVES : If Save tag in drf file is set to 1, the divided cubes are
;         saved. Ensure that when dealing with multiple input cubes
;         the DATAFILE keyword varies.
;
; NOTES : - This module works on cubes only.
;         - The blackbody over the whole spectral range as specified
;           by the keywords CRVAL1, CDELT1 and CRVAL1 is normalized to
;           unit flux.
;
; STATUS : not tested
;
; HISTORY : 13.5.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION divblackbo_000, DataSet, Modules, Backbone

    COMMON APP_CONSTANTS

    functionName = 'divblackbo_000'
    ; save starting time
    T = systime(1)

    drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1

    ; check integrity
    stModule =  check_module( DataSet, Modules, Backbone, functionName )
    if ( NOT bool_is_struct ( stModule ) ) then $
       return, error ('ERROR IN CALL ('+strtrim(functionName)+'): Integrity check failed.')

    ; get the parameters
    b_Debug       = fix(Backbone->getParameter('divblackbo_COMMON___Debug')) eq 1
    d_Temperature = double(Backbone->getParameter('divblackbo_COMMON___Temperature'))
    b_Multiply    = fix(Backbone->getParameter('divblackbo_COMMON___Multiplicate')) eq 1
    if ( d_Temperature lt 0. ) then $
       return, error('ERROR IN CALL ('+strtrim(functionName)+'): Temperatures must be positive.')

    nFrames = Backbone->getValidFrameCount(DataSet.Name)

    ; now loop over the input data sets
    for i=0, nFrames-1 do begin

       ; all frames, intframes and intauxframes have the same dims
       n_Dims = size ( *DataSet.Frames(i) )

       vd_L = get_wave_axis ( DataSet.Headers(i), DEBUG=b_Debug )  ; wavelength axis in meter

       if ( NOT bool_is_vector ( vd_L ) ) then $
          return, error ('FAILURE ('+strg(functionName)+'): Failed to determine dispersion axis values.') 

       info, 'INFO ('+strg(functionName)+'): Minimum wavelength found is '+strg(min(vd_L)*1.d6) + $
             ' microns in set '+strg(i) + '.'

       vd_BB = blackbody ( double(vd_L), double(d_Temperature) )
       vd_BB = vd_BB / median(vd_BB)

       if ( b_Debug eq 1 ) then $
          plot, vd_L*1.d6, vd_BB, /XST, title='Blackbody of '+strg(d_Temperature)+'K', $
                xtitle='[microns]', ytitle='Normed Flux'

       ; replicate the bb data to fit the input data
       p_Frame = ptr_new( replicate_vector( vd_BB, n_Dims(2), n_Dims(3) ) )
       if ( NOT bool_is_cube ( *p_Frame ) ) then $
          return, error('FAILURE ('+strtrim(functionName)+'): Could not replicate bb spectrum vector.')

       p_IntFrame = ptr_new( make_array(/FLOAT,SIZE=n_Dims,VALUE=1. ) )
       if ( NOT bool_is_cube ( *p_IntFrame ) ) then $
          return, error('FAILURE ('+strtrim(functionName)+'): Could not replicate bb noise vector.')

       p_IntAuxFrame = ptr_new( make_array(/BYTE,SIZE=n_Dims,VALUE=9b ) )
       if ( NOT bool_is_cube ( *p_IntAuxFrame ) ) then $
          return, error('FAILURE ('+strtrim(functionName)+'): Could not replicate bb quality vector.')

       ; do it
       vb_Status = frame_op( DataSet.Frames[i], DataSet.IntFrames[i], DataSet.IntAuxFrames[i], $
                             ( b_Multiply eq 1 ) ? '*' : '/', $
                              p_Frame, p_IntFrame, p_IntAuxFrame, 1, MinDiv = 1.d-20 )

       if ( NOT bool_is_vector ( vb_Status ) ) then begin
          warning, 'WARNING ('+strtrim(functionName)+'): Operation failed in set '+strg(i)+'.'
          add_fitskwd_to_header, DataSet.Headers(i), 1, ['COMMNT'], $
                                                        ['Black body treatment failed.'], ['a']
       endif else $ 
          add_fitskwd_to_header, DataSet.Headers(i), 1, ['COMMNT', 'BBTEMP_K'], $
                                                        ['Black body treated.', strg(d_Temperature)], ['a','i']

   end

   thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
   if ( Modules[thisModuleIndex].Save eq 1 ) then begin

      b_Stat = save_dataset ( DataSet, nFrames, Modules[thisModuleIndex].OutputDir, stModule.Save, DEBUG=b_Debug )
      if ( b_Stat ne OK ) then $
         return, error ('FAILURE ('+functionName+'): Failed to save dataset.')

   end

   report_success, functionName, T

   return, OK

end
