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
;                                    'AVERAGE' - Average over good pixels 
;						(uses bad pixel map)
;
;                                    'MEDIAN'  - Median over all pixels
;						(only works for a large
;						number of overlapping frames.
;						Large padded regions will
;						introduce a bias)
;
;                                    'MEANCLIP' - Mean with a sigma clip 
;						(sigma=2)
;						(uses bad pixel map)
;
;    mosaic_COMMON___OffsetMethod    : The method to use for determining
;                                    the mosaic offsets:
;                                    'FILE' : Read the offsets from a
;                                             file (e.g. previously determined
;                                             by mosaicdpos_000.pro)
;                                    'TEL'  : Calculate the offsets
;                                             from the telescope
;                                             coordinates
;     	                             'NGS'   : Calculate offsets from NGS-AO
;						(OBSFMXIM, OBSFMYIM)
;				     'LGS'   : Calculate offsets from LGS-AO
;						(AOTSX,AOTSY)
;
; INPUT-FILES : None
;
; OUTPUT : Saves the 0th dataset pointer which contains after
;          mosaicing the result (primary and 1st and 2nd extension). The filename for this file is created
;          from the 0th header. The 3rd extension contains the number of frames used to combine the mosaic 
;	   for each pixel. The 4th extension of the result saved is the offset list 
;	   (float matrix with first index DataSet.IntAuxFrames[i] x-offsets and eq to 1 
;	   indexing the y-offsets.) 
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
;
; AUTHORS : Shelley Wright and James Larkin
;	Modified Nov 2006 - Shelley Wright
;		added MEDIAN, MEANCLIP, and NGS, LGS offsets
;	Modified May 2007 - Shelley Wright
;		added RA and DEC header for mosaiced frame 
;       Modified 21 March 2008 - SAW and JEL
;               modified to include Kc filters
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

    if ( (s_SumMethod ne 'AVERAGE') and (s_SumMethod ne 'MEDIAN') and (s_SumMethod ne 'MEANCLIP')) then $
       return, error ('ERROR IN CALL (' + functionName + '): SumMethod must be AVERAGE or MEDIAN.')

;    if ( s_SumMethod ne 'AVERAGE' ) then $
;      return, error ('ERROR IN CALL (' + functionName + '): SumMethod must be AVERAGE.')

    case s_OffsetMethod of
       'FILE' : info, 'INFO (' + functionName + '): Reading offsets from file.'
       'TEL'  : info, 'INFO (' + functionName + '): Determining offsets from telescope coordinates.'
       'NGS'  : info, 'INFO (' + functionName + '): Determining offsets from NGS-AO coordinates.'
       'LGS'  : info, 'INFO (' + functionName + '): Determining offsets from LGS-AO coordinates.'
       else   : return, error ('ERROR IN CALL (' + strtrim(functionName) + '): Offset method unknown ' + strg(s_OffsetMethod) )
    endcase

    print, 'Sum Method = ', s_SumMethod 
    print, 'Shift Method = ', s_OffsetMethod
    
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

   n_Dims = size( *DataSet.Frames[0] )   ; all input cubes/images have the same size

   ; ----- Shifts are determined --------------------------------------------------------------
      if ( keyword_set ( ROUNDED ) ) then V_SHIFTs = round(V_SHIFTs)
      x_shift = V_SHIFTs[0,*]
      y_shift = V_SHIFTs[1,*]

   ; ----- Determine the size of the new datasets ---------------------------------------------

   ; determine spatial size of the mosaiced cube/image 
   maxx = max(x_shift)      &  maxy = max(y_shift)      &  minx = min(x_shift)      &  miny = min(y_shift)
   max_x_shift = round(maxx)  &  max_y_shift = round(maxy)  &  min_x_shift = round(minx)  &  min_y_shift = round(miny)
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
           info, 'INFO (' + functionName + '): ' + strg(round(100.*float(j)/float(n_Dims(1)))) + '% of set ' + $
                 strg(i) + ' shifted.' 
         
         dx = x_shift(i)       - round(x_shift(i)) ; the shift is slice independent (mosaicing)
         dy = y_shift(i)       - round(y_shift(i))
         ix = abs(min_x_shift) + round(x_shift(i))
         iy = abs(min_y_shift) + round(y_shift(i))
         
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


;;;-------------------------;

   ;;; Update RA and DEC header information to be for the [0,0] pixel in mosaiced cube

   ; Retrieve header information (1st frame)
   RA_old = double(sxpar(*DataSet.Headers[0], 'RA'))
   DEC_old = double(sxpar(*DataSet.Headers[0], 'DEC'))
   d_Scale = float(sxpar(*DataSet.Headers[0], 'SSCALE'))
   naxis1 = sxpar(*DataSet.Headers[0],'NAXIS1')
   d_PA  = float(sxpar(*DataSet.Headers[0], 'PA_SPEC'))
   d_PA = d_PA * !pi / 180d
   s_filter = sxpar(*DataSet.Headers[0],'SFILTER',count=n_sf)

   ; Make default center the broad band values
   pnt_cen=[32.0,9.0]
   if ( n_sf eq 1 ) then begin
       bb = strcmp('b',strmid(s_filter,2,1))
       if ( strcmp('Zn2',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,25.0]
       if ( strcmp('Zn3',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,25.0]
       if ( strcmp('Zn4',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,33.0]
       if ( strcmp('Zn5',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,33.0]
       if ( strcmp('Jn1',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,17.0]
       if ( strcmp('Jn2',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,22.0]
       if ( strcmp('Jn3',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,25.0]
       if ( strcmp('Jn4',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,28.0]
       if ( strcmp('Hn1',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,19.0]
       if ( strcmp('Hn2',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,23.0]
       if ( strcmp('Hn3',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,25.0]
       if ( strcmp('Hn4',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,28.0]
       if ( strcmp('Hn5',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,33.0]
       if ( strcmp('Kn1',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,19.0]
       if ( strcmp('Kn2',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,23.0]
       if ( strcmp('Kn3',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,25.0]
       if ( strcmp('Kn4',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,28.0]
       if ( strcmp('Kn5',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,33.0]
       if ( strcmp('Kc3',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,25.0]
       if ( strcmp('Kc4',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,28.0]
       if ( strcmp('Kc5',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,33.0]
   end
   print, "Pointing center is", pnt_cen
   
   ; Find offsets from frame1 to padded mosaic frame in arcseconds
        hdx = (abs(min_x_shift) + round(x_shift(0)) + pnt_cen[0]) * d_Scale
	hdy = (abs(min_y_shift) + round(y_shift(0)) + pnt_cen[1]) * d_Scale

   ; Rotate offsets using lenslet PA (arcseconds)
	hdx_rot = hdx * cos(d_PA) - hdy * sin(d_PA)
        hdy_rot = -1* hdx * sin(d_PA) - hdy * cos(d_PA) 

   ; Convert offsets from arcsecs to RA and DEC
   ; Add RA Dec offsets to original RA, Dec from 1st file.
	hdec_offset  =  double(hdx_rot / 3600.) 	
	DEC_new = DEC_old - hdec_offset
	
	hra_offset =  double(hdy_rot / (3600. * cos ( DEC_new * !pi/180. )))	
	RA_new = RA_old - hra_offset

	print,'New RA and DEC = ', RA_new,' ',DEC_new
	print,' '

   ; Update RA and DEC header keywords
	sxaddpar, *DataSet.Headers[0], 'RA', RA_new,' RA at spatial [0,0] in mosaic'
	sxaddpar, *DataSet.Headers[0], 'DEC', DEC_new,' DEC at spatial [0,0] in mosaic'

;;;-------------------------;


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

	print, 'Average Complete'

       loc = where(Number gt 0)
       Sum[loc] = Sum[loc] / Number[loc]
       Noise[loc] = sqrt(Noise[loc]/Number[loc])

   (*DataSet.Frames[0]) = Sum
   (*DataSet.IntFrames[0]) = Noise
   (*DataSet.IntAuxFrames[0])[loc] = 9


   end

;;;-------------------------;


   if ( s_SumMethod eq 'MEDIAN' ) then begin
       ; median the data
       info, 'INFO (' + functionName + '): Medianing shifted datasets.'
       ; Creat arrays for median function
       Stack = (*DataSet.Frames(0)) - (*DataSet.Frames(0))
       Noise = Stack
       Number = Stack + n_Sets
       sz = size(Stack,/dimensions)
       Frame = fltarr(sz[0],sz[1],sz[2],n_Sets)
       IntAx = fltarr(sz[0],sz[1],sz[2],n_Sets)

      for n=0, n_Sets-1 do begin
           Frame[*,*,*,n] = (*DataSet.Frames(n))[*,*,*]
           IntAx[*,*,*,n] = (*DataSet.IntAuxFrames(n))[*,*,*]
      end

       Stack[*,*,*] = median(Frame[*,*,*,*], dimension = 4)
       Noise[*,*,*] = median(IntAx[*,*,*,*], dimension = 4)

	print, 'Median Complete'

   (*DataSet.Frames[0]) = Stack
   (*DataSet.IntFrames[0]) = Noise

    end

;;;;-----------------------;

   if ( s_SumMethod eq 'MEANCLIP' ) then begin
       ; median the data
       info, 'INFO (' + functionName + '): Mean-Clip shifted datasets.'
       ; Create arrays for intermediate results
       sz = size(*DataSet.Frames(0),/dimensions)
       Noise = fltarr(sz[0],sz[1],sz[2])
       Mn = fltarr(sz[0],sz[1],sz[2])
       Var = fltarr(sz[0],sz[1],sz[2])
       Number = fltarr(sz[0],sz[1],sz[2])

       ; Create a pointer array to hold the
       ; deviations in the same array format
       ; as DataSet.Frames
       Dev = PTRARR(n_Sets, /ALLOCATE_HEAP)
       for n=0, n_Sets-1 do begin
            *Dev[n] = fltarr(sz[0],sz[1],sz[2])
       end       

       ; First calculate the average at good pixel locations ignoring deviations
       for i=0, n_Sets-1 do begin
           loc = where(*DataSet.IntAuxFrames[i] eq 9)
           Mn[loc]= Mn[loc] + (*DataSet.Frames[i])[loc]
           Number[loc]  = Number[loc] + 1
           Noise[loc] = Noise[loc] + (*DataSet.IntFrames(i))[loc] * $
					(*DataSet.IntFrames(i))[loc]
       end
       ; Calculate an initial average at the valid pixels.
       loc = where(Number gt 0)
       Mn[loc] = Mn[loc] / Number[loc]
       ; Calculate the noise based on the noise
       ; in all valid frames
       Noise[loc] = sqrt(Noise[loc]/Number[loc])

       ; Zero out the accumlator array
       Number = Number - Number
       ; Now calculate the deviation and variance
       for i=0, n_Sets-1 do begin
           loc = where (*DataSet.IntAuxFrames[i] eq 9)
           (*Dev[i])[loc] = (((*DataSet.Frames[i])[loc]-Mn[loc])*$
				((*DataSet.Frames[i])[loc]-Mn[loc]))
	   Var[loc] = Var[loc] + (*Dev[i])[loc]
           Number[loc] = Number[loc]+1
       end
       ; Calculate the variance for the valid pixels
       loc = where(Number gt 0)
       Var[loc] = Var[loc] / Number[loc]

	; Now calculate the average again using a clip from the deviation
       threshold = 1.7 ; threshold for stdev but used thresh*thresh for Var 
       ; Zero out the accumulator arrays.
       Number = Number - Number
       Mn = Mn - Mn
       for i=0, n_Sets-1 do begin
	   loc = where( (*DataSet.IntAuxFrames[i] eq 9) and $
			(*Dev[i] lt threshold*threshold*Var) )
           Mn[loc] = Mn[loc] + (*DataSet.Frames[i])[loc]
           Number[loc]  = Number[loc] + 1
       end
       ; Calculate the average at the valid pixels
       loc = where(Number gt 0)
       Mn[loc] = Mn[loc] / Number[loc]

       ; Assign average and noise to the dataset arrays
       (*DataSet.Frames[0]) = Mn
       (*DataSet.IntFrames[0]) = Noise
       (*DataSet.IntAuxFrames[0])[loc] = 9

       ; Free the memory for the deviation array
       for i=0, n_Sets-1 do begin
           PTR_FREE, Dev[i]
       end          
       
       print, 'Meanclip complete' 
   end

;;;;-----------------------;


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

   if ( Modules[thisModuleIndex].Save eq 1 ) then begin
                                ; save the result

       c_File = make_filename ( DataSet.Headers[0], Modules[thisModuleIndex].OutputDir, $
                            '_mosaic', IMAG = bool_is_image(*DataSet.Frames(0)) )
;   if ( NOT bool_is_string(c_File) ) then $
;      return, error('FAILURE ('+strtrim(functionName)+'): Output filename creation failed.')
;   c_File = '/net/hydrogen/data/projects/osiris/DRP/saw/051123/reduce_v1/test.fits'
       print, 'writing file:', c_File

                                ; Update DATAFILE keyword with _mosaic
                                ; so output file is distinct from original
       writefits, c_File, float(*DataSet.Frames[0]), *DataSet.Headers[0]
       writefits, c_File, float(*DataSet.IntFrames[0]), /APPEND
       writefits, c_File, byte(*DataSet.IntAuxFrames[0]), /APPEND
       writefits, c_File, float(Number), /APPEND
       writefits, c_File, float(V_Shifts), /APPEND
   endif


   fname = sxpar(*DataSet.Headers[0],'DATAFILE')
   fname = fname + '_mosaic'
   print, fname
   SXADDPAR, *DataSet.Headers[0], "DATAFILE", fname

   report_success, functionName, T

   return, OK

end
