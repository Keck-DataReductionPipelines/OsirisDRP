
;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; NAME:  mosaic_000
;
; PURPOSE: combine mosaiced data
;
; PARAMETERS IN RPBCONFIG.XML :
;
;    mosaic_COMMON___SumMethod    : The method to use for determining
;                                    'AVERAGE'
;                                    'MEDIAN'
;                                    'SUM'
;    mosaic_COMMON___OffsetMethod    : The method to use for determining
;                                    the mosaic offsets:
;                                    'FILE' : Read the offsets from a
;                                             file (e.g. previously determined
;                                             by mosaicdpos_000.pro)
;                                    'TEL'  : Calculate the offsets
;                                             from the telescope
;                                             coordinates
;                                    'AO'   : Calculate offsets fro
;                                             the AO mirror
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
; NOTES : - Requires that the combine_method and offset_method
;           parameters be set in the xml file.
;
; STATUS : not tested
;
; HISTORY : July.5.2006, created
;
; Based on mosaicdith by Christof Iserlohe
; AUTHOR : James Larkin and Shelley Adams Wright
;
;-----------------------------------------------------------------------

FUNCTION mosaic_000, DataSet, Modules, Backbone

    COMMON APP_CONSTANTS

    ; save the starting time
    T = systime(1)

    functionName = 'mosaic_000'
    thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)

    drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1


    ; get the parameters
    s_SumMethod    = Modules[thisModuleIndex].combine_method
    s_OffsetMethod    = Modules[thisModuleIndex].offset_method

;    if ( (s_SumMethod ne 'AVERAGE') and (s_SumMethod ne 'MEDIAN') ) then $
;       return, error ('ERROR IN CALL (' + functionName + '): SumMethod must be AVERAGE or MEDIAN.')
    if ( s_SumMethod ne 'AVERAGE' ) then $
      return, error ('ERROR IN CALL (' + functionName + '): SumMethod must be AVERAGE.')

    case s_OffsetMethod of
       'FILE' : info, 'INFO (' + functionName + '): Reading offsets from file.'
       'TEL'  : info, 'INFO (' + functionName + '): Determining offsets from telescope coordinates.'
       'AO'   : info, 'INFO (' + functionName + '): Determining offsets from AO coordinates.'
       else   : return, error ('ERROR IN CALL (' + strtrim(functionName) + '): Offset method unknown ' + strg(s_OffsetMethod) )
    endcase

    print, s_SumMethod, s_OffsetMethod
    
    n_Sets = Backbone->getValidFrameCount(DataSet.Name)

    if ( s_OffsetMethod eq 'FILE' ) then begin
       ; load and verify the offset list

       thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
       c_File = drpXlateFileName(Modules[thisModuleIndex].CalibrationFile)
       if ( NOT file_test ( c_File ) ) then $
          return, error ('ERROR IN CALL (' + strtrim(functionName) + '): Offset file list ' + strg(c_File) + ' not found.' )
       V_Shifts = readfits(c_File)
    endif else $
       ; determine shifts from header coordinates
       V_Shifts = determine_mosaic_offsets_from_header( DataSet.Headers, bool_is_cube((*DataSet.Frames(0))), $
                                                         s_OffsetMethod, n_Sets )

    ; verify shift list
    if ( NOT bool_is_image(V_Shifts) ) then $
       return, error('ERROR IN CALL ('+strtrim(functionName)+'): Offset list has a strange format.')
    if ( (size(V_Shifts))[2] ne n_Sets ) then $
       return, error('ERROR IN CALL ('+strtrim(functionName)+'): Number of shifts from offset list does not agree with the number of frames to be shifted.')

    ; for mosaicing the datasets must all have the same size, so we resize them first 
    if ( resize_dataset( DataSet, n_Sets ) ne OK ) then $
       return, error ('FAILURE ('+strtrim(functionName)+'): Resizing of dataset failed.')

    ; mosaic changes DataSet and returns the mosaiced cube
;    s_Res
;                    n_Sets, V_SHIFT = md_Shifts, $
;                    AVERAGE  = (s_SumMethod eq 'AVERAGE'), $
;                    CUBIC    = (s_ShiftMethod eq 'CUBIC' ? d_Cubic : 0 ), $
;                    BILINEAR = (s_ShiftMethod eq 'BILINEAR' ? 1 : 0 ), $
;                    ROUNDED  = (s_ShiftMethod eq 'ROUNDED' ? 1 : 0 ), $
;                    EQUALIZE = b_Equalize, $
;                    DEBUG    = b_Debug )

   n_Dims = size( *DataSet.Frames[0] )   ; all input cubes/images have the same size

   ; ----- Shifts are determined --------------------------------------------------------------
      if ( keyword_set ( ROUNDED ) ) then V_SHIFTs = round(V_SHIFTs)
      x_shift = V_SHIFTs[0,*]
      y_shift = V_SHIFTs[1,*]

   ; ----- Determine the size of the new datasets ---------------------------------------------

   ; determine spatial size of the mosaiced cube/image 
   maxx = max(x_shift)      &  maxy = max(y_shift)      &  minx = min(x_shift)      &  miny = min(y_shift)
   max_x_shift = fix(maxx)  &  max_y_shift = fix(maxy)  &  min_x_shift = fix(minx)  &  min_y_shift = fix(miny)
   nn1 = n_Dims(2)+max_x_shift-min_x_shift ; x-size of the new combined cube
   nn2 = n_Dims(3)+max_y_shift-min_y_shift ; y-size of the new combined cube

   info, 'INFO (mosaic.pro): Min Max X,Y ' + $
            strg(min_x_shift)+' '+strg(max_x_shift)+' '+strg(min_y_shift)+' '+strg(max_y_shift)
   info, '     Size of combined cube/image '+strg(nn1)+' '+strg(nn2)

   ; ----- Loop over the input data, do the fractional shift and put the shifted dataset into the enlarged dataset

   ; loop over the cubes/images
   for i=0, n_Sets-1 do begin

      info, 'INFO (' + functionName + '): Working on cube/image ' + strg(i) + '.'

      ; new ith cubes with larger size to store the shifted ith cubes
      cf_Frames       = fltarr( n_Dims(1), nn1, nn2 )
      cf_IntFrames    = fltarr( n_Dims(1), nn1, nn2 )
      cb_IntAuxFrames = bytarr( n_Dims(1), nn1, nn2 )

      ; loop over the slices of dataset i
      for j=0, n_Dims(1)-1 do begin

         if ( ( j mod (n_Dims(1)/10) ) eq 0 ) then $
           info, 'INFO (' + functionName + '): ' + strg(fix(100.*float(j)/float(n_Dims(1)))) + '% of set ' + $
                 strg(i) + ' shifted.' 
         
         dx = x_shift(i)       - fix(x_shift(i)) ; the shift is slice independent (mosaicing)
         dy = y_shift(i)       - fix(y_shift(i))
         ix = abs(min_x_shift) + fix(x_shift(i))
         iy = abs(min_y_shift) + fix(y_shift(i))
         
         ; extract slices for shifting
         mf_D = ( n_Dims(0) eq 3 ) ? reform((*DataSet.Frames(i))(j,*,*)) : *DataSet.Frames(i)
         mf_N = ( n_Dims(0) eq 3 ) ? reform((*DataSet.IntFrames(i))(j,*,*)) : *DataSet.IntFrames(i)
         mb_Q = ( n_Dims(0) eq 3 ) ? reform((*DataSet.IntAuxFrames(i))(j,*,*)) : *DataSet.IntAuxFrames(i)

         ; fill the temporary cubes with the shifted (or original) slices
         cf_Frames( j, ix : ix + n_Dims(2)-1, iy : iy + n_Dims(3)-1 )       = mf_D
         cf_IntFrames( j, ix : ix + n_Dims(2)-1, iy : iy + n_Dims(3)-1 )    = mf_N
         cb_IntAuxFrames( j, ix : ix + n_Dims(2)-1, iy : iy + n_Dims(3)-1 ) = mb_Q

      end ; loop over the slices of set i

      ; replace the dataset with the enlarged dataset
      *DataSet.IntAuxFrames(i) = reform(cb_IntAuxFrames)
      *DataSet.IntFrames(i)    = reform(cf_IntFrames)
      *DataSet.Frames(i)       = reform(cf_Frames)
   end

   n_Dims = size ( *DataSet.IntAuxFrames(0) )

   ; allocate memory for final quality status frame
   NewStatus = make_array ( SIZE=n_Dims, /BYTE, VALUE = 0b )


   if ( s_SumMethod eq 'AVERAGE' ) then begin
       ; averaging the data
       info, 'INFO (' + functionName + '): Averaging shifted datasets.'
       Sum = (*DataSet.Frames(0)) - (*DataSet.Frames(0))
       Noise = Sum
       Number = Sum
       
       for i=0, n_Sets-1 do begin
           loc = where (*DataSet.IntAuxFrames[i] eq 9)
           Sum[loc]= Sum[loc] + (*DataSet.Frames[i])[loc]
           Number[loc]  = Number[loc] + 1
           Noise[loc] = Noise[loc] + (*DataSet.IntFrames(i))[loc] * (*DataSet.IntFrames(i))[loc]
       end

       loc = where(Number gt 0)
       Sum[loc] = Sum[loc] / Number[loc]
       Noise[loc] = sqrt(Noise[loc]/Number[loc])
   end

   if ( s_SumMethod eq 'MEDIAN' ) then begin
       info, 'INFO (' + functionName + '): Medianing shifted datasets.'
       ; Not implemented yet.
       
   end

   (*DataSet.Frames[0]) = Sum
   (*DataSet.IntFrames[0]) = Noise
   (*DataSet.IntAuxFrames[0])[loc] = 9

   ; the result is stored in the 0th pointer, delete the others
   for i=1, n_Sets-1 do clear_frame, DataSet, i, /ALL

   ; update the header
   if ( verify_naxis ( DataSet.Frames(0), DataSet.Headers(0), /UPDATE ) ne OK ) then $
      return, error('FAILURE ('+strtrim(functionName)+'): Update of header failed.')

   ; reset the ValidFrameCounter
   dummy  = Backbone->setValidFrameCount(DataSet.Name, 1)
   n_Sets = Backbone->getValidFrameCount(DataSet.Name)
   if ( n_Sets ne 1 ) then return, error('FAILURE ('+strtrim(functionName)+'): Failed to reset ValidFrameCounter.')

;   stModule =  check_module( DataSet, Modules, Backbone, functionName )
;   if ( NOT bool_is_struct ( stModule ) ) then $
;      return, error ('ERROR IN CALL ('+strtrim(functionName)+'): Post Integrity check failed.')

   ; save the result
   c_File = make_filename ( DataSet.Headers[0], Modules[thisModuleIndex].OutputDir, $
                            '_mosaic_', IMAG = bool_is_image(*DataSet.Frames(0)) )
;   if ( NOT bool_is_string(c_File) ) then $
;      return, error('FAILURE ('+strtrim(functionName)+'): Output filename creation failed.')
;   c_File = '/net/hydrogen/data/projects/osiris/DRP/saw/051123/reduce_v1/test.fits'
   print, 'writing file:', c_File

   writefits, c_File, float(*DataSet.Frames[0]), *DataSet.Headers[0]
   writefits, c_File, float(*DataSet.IntFrames[0]), /APPEND
   writefits, c_File, byte(*DataSet.IntAuxFrames[0]), /APPEND
   writefits, c_File, byte(Number), /APPEND
   writefits, c_File, float(V_Shifts), /APPEND


   report_success, functionName, T

   return, OK

end
