
;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; NAME:  mosaicdith_000
;
; PURPOSE: combine mosaiced data
;
; PARAMETERS IN RPBCONFIG.XML :
;
;    mosaicdith_COMMON___Cubic     : cubic parameter (float) used for shifting the
;                                    images on subpixel basis,
;                                    range=(-1.,0.), default: -0.5
;
;    mosaicdith_COMMON___OffsetMethod    : The method to use for determining
;                                    the mosaic offsets:
;                                    'FILE' : Read the offsets from a
;                                             file (e.g. previously determined
;                                             by mosaicdpos_000.pro)
;                                    'TEL'  : Calculate the offsets
;                                             from the telescope
;                                             coordinates
;                                    'AO'   : Calculate offsets fro
;                                             the AO mirror
;    mosaicdith_COMMON___Debug     : initializes the debugging mode
;
; INPUT-FILES : None
;
; OUTPUT : Saves the 0th dataset pointer which contains after
;          mosaicing the result (primary and 1st and 2nd extension). The filename for this file is created
;          from the 0th header. The 3rd extension of the result saved
;          is the offset list (float matrix with first index eq to 0 indexing the
;          x-offsets and eq to 1 indexing the y-offsets. 
;
; DATASET : the mosaiced result is put into the 0th pointer. All
;           others are deleted. The ValidFrameCounter is set to 1.
;
; DEBUG : nothing special
;
; MAIN ROUTINE : mosaic.pro
;
; SAVES : If Save tag in drf file is set to 1, the mosaiced cubes are saved.
;
; NOTES : - When defining OFFMTD in the headers, with OFFMTD being
;           equal to 'FILE', 'TEL' or 'AO' (see
;           mosaicdith_COMMON___OffsetMethod for meaning)
;           mosaicdith_COMMON___OffsetMethod is ignored and the value
;           of OFFMTD is used instead.
;
; STATUS : not tested
;
; HISTORY : 3.3.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION mosaicdith_000, DataSet, Modules, Backbone

    COMMON APP_CONSTANTS

    functionName = 'mosaicdith_000'
    ; save the starting time
    T = systime(1)

    drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1

    ; check integrity
    stModule =  check_module( DataSet, Modules, Backbone, functionName, /DIMS )
    if ( NOT bool_is_struct ( stModule ) ) then $
       return, error ('ERROR IN CALL ('+strtrim(functionName)+'): Integrity check failed.')

    ; get the parameters
    s_SumMethod    = strg(Backbone->getParameter('mosaicdith_COMMON___SumMethod'))
    s_ShiftMethod  = strg(Backbone->getParameter('mosaicdith_COMMON___ShiftMethod'))
    d_Cubic        = float(Backbone->getParameter('mosaicdith_COMMON___Cubic'))
    s_OffsetMethod = strg(Backbone->getParameter('mosaicdith_COMMON___OffsetMethod'))
    b_Equalize     = fix(Backbone->getParameter('mosaicdith_COMMON___Equalize'))
    b_Debug        = fix(Backbone->getParameter('mosaicdith_COMMON___Debug')) eq 1

    ; check the shift method
    if ( s_ShiftMethod ne 'CUBIC' and s_ShiftMethod ne 'BILINEAR' and s_ShiftMethod ne 'ROUNDED' ) then $
       return, error ('ERROR IN CALL (' + functionName + '): ShiftMethod must be CUBIC, BILINEAR or ROUNDED.')
    ; check the sum method
    if ( s_SumMethod ne 'AVERAGE' and s_SumMethod ne 'SUM' ) then $
       return, error ('ERROR IN CALL (' + functionName + '): SumMethod must be AVERAGE or SUM.')

    ; check if the offset method is specified in the header, if so
    ; overwrite the parameter from RPBconfig.xml
    s_OffsetMethodFromHeader = strupcase(strg(sxpar( *(DataSet.Headers(0)), 'OFFMTD', count = n )))
    if ( n gt 1 ) then $
       return, error ('ERROR IN CALL (' + functionName + '): OFFMTD keyword in header occurs more than once.')
    if ( n eq 1 ) then $
       s_OffsetMethod = s_OffsetMethodFromHeader

    case s_OffsetMethod of
       'FILE' : info, 'INFO (' + functionName + '): Reading offsets from file.'
       'TEL'  : info, 'INFO (' + functionName + '): Determining offsets from telescope coordinates.'
       'AO'   : info, 'INFO (' + functionName + '): Determining offsets from AO coordinates.'
       else   : return, error ('ERROR IN CALL (' + strtrim(functionName) + '): Offset method unknown ' + strg(s_OffsetMethod) )
    endcase






    n_Sets = Backbone->getValidFrameCount(DataSet.Name)

    if ( s_OffsetMethod eq 'FILE' ) then begin

       ; load and verify the offset list

       thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
       c_File = drpXlateFileName(Modules[thisModuleIndex].CalibrationFile)
       if ( NOT file_test ( c_File ) ) then $
          return, error ('ERROR IN CALL (' + strtrim(functionName) + '): Offset file list ' + strg(c_File) + ' not found.' )
       md_Shifts = readfits(c_File)

    endif else $

       ; determine shifts from header coordinates
       md_Shifts = determine_mosaic_offsets_from_header( DataSet.Headers, bool_is_cube(*(DataSet.Frames(0))), $
                                                         s_OffsetMethod, n_Sets )

    ; verify shift list
    if ( NOT bool_is_image(md_Shifts) ) then $
       return, error('ERROR IN CALL ('+strtrim(functionName)+'): Offset list has a strange format.')
    if ( (size(md_Shifts))(2) ne n_Sets ) then $
       return, error('ERROR IN CALL ('+strtrim(functionName)+'): Number of shifts from offset list does not agree with the number of frames to be shifted.')

    ; for mosaicing the datasets must all have the same size, so we resize them first 
    if ( resize_dataset( DataSet, n_Sets ) ne OK ) then $
       return, error ('FAILURE ('+strtrim(functionName)+'): Resizing of dataset failed.')

    ; mosaic changes DataSet and returns the mosaiced cube
    s_Res = mosaic( DataSet.Frames, DataSet.IntFrames, DataSet.IntAuxFrames, $
                    n_Sets, V_SHIFT = md_Shifts, $
                    AVERAGE  = (s_SumMethod eq 'AVERAGE'), $
                    CUBIC    = (s_ShiftMethod eq 'CUBIC' ? d_Cubic : 0 ), $
                    BILINEAR = (s_ShiftMethod eq 'BILINEAR' ? 1 : 0 ), $
                    ROUNDED  = (s_ShiftMethod eq 'ROUNDED' ? 1 : 0 ), $
                    EQUALIZE = b_Equalize, $
                    DEBUG    = b_Debug )

   ; the return value of mosaic is really a structure and therefore mosaicing was succesful
   if ( NOT bool_is_struct(s_Res) ) then $
      return, error('FAILURE ('+strtrim(functionName)+'): Mosaicing failed.')

   ; the result is stored in the 0th pointer, delete the others
   for i=1, n_Sets-1 do delete_frame, DataSet, i, /ALL

   ; update the header
   if ( verify_naxis ( DataSet.Frames(0), DataSet.Headers(0), /UPDATE ) ne OK ) then $
      return, error('FAILURE ('+strtrim(functionName)+'): Update of header failed.')





   ; reset the ValidFrameCounter
   dummy  = Backbone->setValidFrameCount(DataSet.Name, 1)
   n_Sets = Backbone->getValidFrameCount(DataSet.Name)
   if ( n_Sets ne 1 ) then return, error('FAILURE ('+strtrim(functionName)+'): Failed to reset ValidFrameCounter.')

   stModule =  check_module( DataSet, Modules, Backbone, functionName )
   if ( NOT bool_is_struct ( stModule ) ) then $
      return, error ('ERROR IN CALL ('+strtrim(functionName)+'): Post Integrity check failed.')

   ; save the result
   thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
   c_File = make_filename ( DataSet.Headers[0], Modules[thisModuleIndex].OutputDir, $
                            stModule.SaveExt, IMAG = bool_is_image(*DataSet.Frames(0)) )
   if ( NOT bool_is_string(c_File) ) then $
      return, error('FAILURE ('+strtrim(functionName)+'): Output filename creation failed.')

   writefits, c_File, float(*DataSet.Frames[0]), *DataSet.Headers[0]
   writefits, c_File, float(*DataSet.IntFrames[0]), /APPEND
   writefits, c_File, byte(*DataSet.IntAuxFrames[0]), /APPEND
   writefits, c_File, byte(s_Res.NFrame), /APPEND
   writefits, c_File, float(md_Shifts), /APPEND

   if ( b_Debug ) then begin
      info, 'INFO ('+strtrim(functionName)+'): File ' + c_File + ' successfully written.'
      fits_help, c_File
   end

   report_success, functionName, T

   return, OK

end
