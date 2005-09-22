
;-----------------------------------------------------------------------
; NAME:  mosaic_check_bits
;
; PURPOSE: Ensure that the bits make sense
;
; NOTES: A pixel is considered as invalid if :
;        - the data or noise value is not finite
;        - the noise value is lt 0.
;        - the pixel is outside
;
;        After this procedure :
;
;           Invalid pixels get:
;              - qbit 0 = 0
;              - data and noise value = 0.
;
;           Interpolation bit is checked and correctly set
;
;           Outside pixels are set to invalid (as defined above)
;
; STATUS : untested
;
; HISTORY : 17.9.2005, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

pro mosaic_check_bits, pcf_Frame, pcf_IntFrame, pcb_IntAuxFrame, n_Sets

   functionName = 'mosaic_check_bits.pro'

   for i=0, n_Sets-1 do begin

      ; invalid pixel = data or noise not finite or noise lt 0. or outside
      v_Mask = where ( bool_invert ( finite ( *pcf_Frame(i) ) ) or $
                       bool_invert ( finite ( *pcf_IntFrame(i) ) ) or $
                       (*pcf_IntFrame(i) lt 0. ) or $
                       bool_invert ( extbit ( *pcb_IntAuxFrame(i), 3 ) ), n_Mask )

      if ( n_Mask gt 0 ) then begin

         ; set qbit 0 of invalid pixel to 0
         tmp                 = *pcb_IntAuxFrame(i)
         tmp ( v_Mask )      = setbit ( tmp ( v_Mask ), 0, 0 )
         *pcb_IntAuxFrame(i) = tmp

         ; set data of invalid pixel to 0.
         tmp            = *pcf_Frame(i)
         tmp ( v_Mask ) = 0.
         *pcf_Frame(i)  = tmp

         ; set noise of invalid pixel to 0
         tmp              = *pcf_IntFrame(i)
         tmp ( v_Mask )   = 0.
         *pcf_IntFrame(i) = tmp

      end

      ; check the interpolation bits  (Bit 1 : interpolation status, bit 2 : good(1)/bad(0) )
      ; if qbit 2 is 1 qbit 1 must be 1 as well 
      v_Mask  = where ( extbit( *pcb_IntAuxFrame(i), 2 ) and bool_invert(extbit( *pcb_IntAuxFrame(i), 1 )), n )
      if ( n gt 0 ) then begin
 
         info, 'INFO (' + functionName + '): ' + strg(n) + ' pixel have strange interpolation status. Correcting.'
         tmp                 = *pcb_IntAuxFrame(i)
         tmp ( v_Mask )      = setbit (tmp ( v_Mask ), 1, 1)
         *pcb_IntAuxFrame(i) = tmp

      end

      ; Ensure that outside pixel are invalid
      v_Tmp = where ( bool_invert ( extbit ( *pcb_IntAuxFrame(i), 3 ) ) and extbit ( *pcb_IntAuxFrame(i), 0 ), n )
      if ( n gt 0 ) then begin
         warning, 'WARNING (' + functionName + '): Preparing mosaicing: ' + strg(n) + ' pixels ' + $
                     ' in set ' + strg(i) + ' have outside status but are valid. Correcting.'
         tmp                 = *pcb_IntAuxFrame(i)
         tmp( v_Tmp )        = setbit ( tmp ( v_Tmp ), 0, 0 )
         *pcb_IntAuxFrame(i) = tmp
      end

   end

   delvarx, v_Tmp
   delvarx, v_Mask
   delvarx, tmp

end

;-----------------------------------------------------------------------
; NAME:  mosaic_equalize
;
; PURPOSE: helper fit function for equalizing
;
; See mpcurvefit for further details
;
;-----------------------------------------------------------------------

pro mosaic_equalize, X, P, YMOD, PDER

   YMOD = P(1) * ( P(0) + X )

   if ( n_params() eq 4 ) then begin

      PDER = [[ replicate(1.0, N_ELEMENTS(X))], [X]]

   end


end

;-----------------------------------------------------------------------
; NAME:  mosaic_shift_image
;
; PURPOSE: Shift image on subpixel basis. 
;          The x-, y-shift must be less than 1 (not checked)
;
; INPUT :  mf_D            : input data image
;          mf_N            : input noise image
;          mb_Q            : input quality image
;          d_x             : 0 <= shift in x-direction < 1 (not checked)
;          d_y             : 0 <= shift in y-direction < 1 (not checked)
;          [CUBIC=CUBIC]   : same as in interpolate.pro
;          [TEXT=TEXT]     : for better error messaging. E.g. the number of
;                            the slice currently treated 
;
; OUTPUT : returns 1 on success, 0 else.
;          updates the input images
;
; NOTES : - since the shift is fractional, the output arrays have the
;           same size as the input arrays
;         - the input images must have same dimension (not checked)
;         - qbit 0 must be set correctly. The decission whether a
;           pixel is valid or not is solely based on that bit. 
;
; STATUS : untested
;
; HISTORY : 11.9.2005, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

function mosaic_shift_image, mf_D, mf_N, mb_Q, d_x, d_y, CUBIC = CUBIC, TEXT = TEXT

   functionName = 'mosaic_shift_image.pro'

   ; the shifted images
   mf_DS = make_array ( SIZE=size(mf_D), /FLOAT, VALUE=0. )
   mf_NS = make_array ( SIZE=size(mf_N), /FLOAT, VALUE=0. )
   mb_QS = make_array ( SIZE=size(mb_Q), /BYTE, VALUE=0b )

   ; calculate the new grid points
   vd_X = dindgen( (size(mf_D))(1) ) - d_x
   vd_Y = dindgen( (size(mf_D))(2) ) - d_y

   ; ---- First the inside bit

   ; the inside bit is preserved
   v_In = where ( extbit ( mb_Q, 3 ), n_In )
   if ( n_In gt 0 ) then $
      mb_QS ( v_In ) = setbit ( mb_QS ( v_In ), 3, 1 )

   ; ---- Now determine the shifted frames and other quality bits

   ; find the valid (qbit 0 = 1) pixels
   ; Reminder : Pixels have qbit 0 = 0 if :
   ;            - data or noise not finite
   ;            - noise negative
   ;            - outside
   Valid   = extbit ( mb_Q, 0 )
   v_Valid = where ( Valid, n_Valid )

   ; if there are no valid pixel the interpolation status will be lost

   if ( n_Valid gt 0 ) then begin

      ; there are valid pixel in the slice

      ; set invalid pixel in data and noise slice to NaN
      v_Invalid = where ( Valid ne 1, n_Invalid )
      if ( n_Invalid gt 0 ) then begin
         mf_D(v_Invalid) = !VALUES.F_NAN
         mf_N(v_Invalid) = !VALUES.F_NAN
      end

      ; shift the data frame cubic or bilinear, the noise frame bilinear
      ; The MISSING value is the value to return for elements outside the bounds of the input
      mf_DS = interpolate ( mf_D, vd_X, vd_Y, /grid, CUBIC=CUBIC, MISSING = !VALUES.F_NAN )
      mf_NS = interpolate ( mf_N, vd_X, vd_Y, /grid, MISSING = !VALUES.F_NAN )

      ; the interpolation status must be determined

      ; The Interpolation Map contains for valid (qbit 0 = 1 ) well interpolated pixel 1 and
      ; for bad interpolated pixel 2
      mf_I = float ( Valid  * ( $                       ; these are the valid pixel
             extbit ( mb_Q, 1 ) + $                     ; these are the interpolated pixel
             ( extbit ( mb_Q, 1 ) and $                 ; these are the bad interpolated pixel
               bool_invert( extbit ( mb_Q, 2 ) ) ) ) )

      ; Now shift the Interpolation Map
      mf_IS = interpolate ( mf_I, vd_X, vd_Y, /grid, CUBIC=CUBIC, MISSING = !VALUES.F_NAN )

      ; now go ahead

      ; search where after shifting valid (not NaN) data, noise and
      ; interpolation map pixel are and the noise is not negative
      ValidShifted     = finite ( mf_DS ) and finite ( mf_NS ) and finite ( mf_IS ) and ( mf_NS ge 0. )
      v_ValidShifted   = where ( ValidShifted, n_ValidShifted ) 

      ; set invalid pixels in the shifted data and noise images to 0.
      v_InvalidShifted  = where ( ValidShifted eq 0, n_InvalidShifted )
      if ( n_InvalidShifted gt 0 ) then begin
         mf_DS ( v_InvalidShifted ) = 0.
         mf_NS ( v_InvalidShifted ) = 0.
      end

      if ( n_ValidShifted gt 0 ) then begin

         ; there are valid shifted pixel in the image

         ; set qbit 0 to 1 where valid after shifting
         mb_QS(v_ValidShifted) = setbit ( mb_QS(v_ValidShifted), 0, 1 )

         ; where the shifted interpolation map is greater than 1/2 the shifted
         ; pixel is regarded as interpolated. If it is greater than
         ; 1 it is badly interpolated
         v_MaskInt = where ( mf_IS(v_ValidShifted) gt 0.5, n_Int )
         if ( n_Int gt 0 ) then begin
            mb_QS(v_ValidShifted(v_MaskInt)) = setbit ( mb_QS(v_ValidShifted(v_MaskInt)), 1, 1 )
            mb_QS(v_ValidShifted(v_MaskInt)) = setbit ( mb_QS(v_ValidShifted(v_MaskInt)), 2, 1 )
         end
         v_MaskBadInt = where ( mf_IS(v_ValidShifted) gt 1., n_BadInt )
         if ( n_BadInt gt 0 ) then $
            mb_QS(v_ValidShifted(v_MaskBadInt)) = setbit ( mb_QS(v_ValidShifted(v_MaskBadInt)), 2, 0 )

      endif else $
         info, 'INFO (' + functionName + '): No valid pixel in image after shift ' + $
            (keyword_set ( TEXT ) ? TEXT : '.')

   endif else $
      info, 'INFO (' + functionName + '): No valid pixel in image before shift ' + $
         (keyword_set ( TEXT ) ? TEXT : '.')

   ; a last check is whether in the shifted quality frame all outside pixel have qbit 0 = 0
   v_Tmp = where ( bool_invert ( extbit ( mb_QS, 3 ) ) and extbit ( mb_QS, 0 ), n )
   if ( n gt 0 ) then begin
      warning, 'WARNING (' + functionName + '): Whoopsie daisy, ' + strg(n) + ' pixels ' + $
                  (keyword_set (TEXT) ? TEXT : '') + ' have outside status but are valid. Correcting.'
      mb_QS ( v_Tmp ) = setbit ( mb_QS ( v_Tmp ), 0, 0 )
   end

   ; all done

   return, {mf_D:mf_DS, mf_N:mf_NS, mb_Q:mb_QS }

end


;-----------------------------------------------------------------------
; NAME:  mosaic
;
; PURPOSE: Shift and combine cubes or images
;
; INPUT :  pcf_Frame                : pointer to input cubes or images
;          pcf_IntFrame             : pointer to input IntFrame cubes
;                                     or images (noise not 1/noise^2)
;          pcb_IntAuxFrame          : pointer to input IntAuxFrame cubes or images.
;          n_Sets                   : # of input cubes or images
;          Either
;          V_SHIFT=V_SHIFT          : double vectors with the shifts with
;                                     respect to any cube in
;                                     pcf_Frame. You have to set these
;                                     keywords when mosaicing.
;          or
;          DISPERSION=DISPERSION    : Path/name of a fitsfile containing
;                                     the dispersion offsets of a
;                                     single cube (usually prepared by
;                                     fitdispers_000.pro). If the pointer to
;                                     the data cubes is an array (if
;                                     there are more than one cubes to
;                                     shift), all cubes are corrected
;                                     with this file. 
;          Either
;          CUBIC=CUBIC              : Initializes the cubic convolution
;                                     interpolation method with 
;                                     0 < CUBIC <= -1 (fast!!!
;                                     and recommended with CUBIC=-0.5).
;          or
;          /BILINEAR                : Initializes the bilinear interpolation
;                                     method (fast!!!).
;
;          /DEBUG                   : initializes the debugging level
;
; RETURN VALUE : returns a structure on success:
;                Mosaicing :
;                   {NFrame : number of pixels used for mosaicing}
;                atmosphere :
;                   {Status      :1}
;
;                or ERR_UNKNOWN from APP_CONSTANTS
;
; NOTES: - When using bilinear or cubic shifting the noise slices are shifted bilinearly
;
; ALGORITHM: 
;     Generell: - All modes support IntFrame and IntAuxFrame values.
;               - The data cubes as well as the IntFrame cubes are shifted.
;               - subpixel shifts do not enlarge the combined cube
;               - after having shifted the individual slices the
;                 value of the pixel in the combined cube is the
;                 with the IntFrame values weighted average of the shifted pixels.
;               - The IntFrame values are in all cases shifted with
;                 the BILINEAR method.
;
;             CUBIC/BILINEAR : uses IDLs interpolate function with/out the cubic
;                     keyword. When using CUBIC or BILINEAR invalid pixels are
;                     used for interpolation!!!. For coding
;                     intauxframe values see moasic_determine_aux_status_after_shift.pro
;
;             When mosaicing (V_SHIFTS) ROUNDED rounds the input offsets. For coding
;                     intauxframe values see mosaic_determine_aux_status_after_shift.pro
;
; ON ERROR: returns 0.
;
; STATUS : The BILINEAR and CUBIC keyword have been tested. 
;
; NOTES : - Shifts less than 0.01 pixel are not performed.
;         - Only integer shifts enlarge the new cube, e.g. two frames,
;           10x10 is size shifted by 2.5 pixel in both directions will
;           give a 12x12 frame. Only the fractional shift is done by
;           shifting. The shifting process therefore is 2 integer
;           shifts and 0.5 subpixel shifts. (The alternative would be
;           3 integer and -0.5 subpixel shifts, which is not realized here)
;
; HISTORY : 27.3.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

function mosaic, pcf_Frame, pcf_IntFrame, pcb_IntAuxFrame, n_Sets, $
                 V_SHIFT = V_SHIFT, DISPERSION = DISPERSION, $ ; select one
                 AVERAGE = AVERAGE, $
                 CUBIC = CUBIC, BILINEAR = BILINEAR, ROUNDED = ROUNDED, $
                 EQUALIZE = EQUALIZE, $
                 DEBUG = DEBUG

   COMMON APP_CONSTANTS

   functionName ='mosaic.pro'

   ; ------ parameter checks --------------------------------------------------------

   n_Dims = size( *pcf_Frame(0) )   ; all input cubes/images have the same size

   if ( ( keyword_set ( V_SHIFT ) + keyword_set ( DISPERSION ) ) ne 1 ) then $
      return, error ( 'ERROR IN CALL (mosaic.pro): Either V_SHIFT (mosaicing) or DISPERSION (atmosphere).' )

   if ( ( keyword_set ( CUBIC ) + keyword_set ( BILINEAR ) + keyword_set ( ROUNDED ) ) ne 1 ) then $
      return, error ( 'ERROR IN CALL (mosaic.pro): Either CUBIC, BILINEAR or ROUNDED.' )

   if ( keyword_set ( ROUNDED ) and NOT keyword_set ( V_SHIFT ) ) then $
      return, error ( 'ERROR IN CALL (mosaic.pro): ROUNDED only together with V_SHIFT (mosaicing).' )

   if ( bool_pointer_integrity( pcf_Frame, pcf_IntFrame, pcb_IntAuxFrame, n_Sets, 'mosaic.pro', $
                                CUBE = keyword_set ( CUBE ), IMAGE = keyword_set ( IMAGE ) ) ne OK ) then $
      return, error ('ERROR IN CALL (mosaic.pro): Integrity check failed.')

   if ( keyword_set ( CUBIC ) ) then $
      if ( CUBIC lt -1. or CUBIC gt 0. ) then return, error ( 'ERROR IN CALL (mosaic.pro): 0 < CUBIC < 1' )

   if ( n_Dims(0) eq 2 ) then n_Dims = [n_Dims(0), 1, n_Dims(1:2)]  ; images ?

   if ( n_Dims(2) lt 5 or n_Dims(3) lt 5 ) then $
      return, error('ERROR IN CALL (mosaic.pro): Spatial dimensions must be at least 6x6.')

   mosaic_check_bits, pcf_Frame, pcf_IntFrame, pcb_IntAuxFrame, n_Sets  ; ensure that the bits make sense

   if ( bool_is_image ( *pcf_Frame(0) ) ) then b_Images = 1 else b_Images = 0

   ; ----- Done with the parameter checks -----------------------------------------------------

   ; ----- Determine the shifts ---------------------------------------------------------------

   if ( keyword_set (CUBIC) or keyword_set (BILINEAR) ) then $
      info,'INFO ('+functionName+'): Mosaicing with fractional shifts.' $
   else $
      info,'INFO (' + functionName + '): Mosaicing with rounded shifts.'

   if ( keyword_set ( V_SHIFT ) ) then begin

      ; we are about to mosaic

      ; ensure that the length of the list with shifts is equal to the number of datsets to be shifted
      if ( NOT array_equal( (size ( V_SHIFT ))(0:2), [2,2,n_Sets] ) ) then $
         return, error(['ERROR IN CALL (mosaic.pro): Number of shifts does not ', $
                        '                            match number of cubes/images to shift.'])

      if ( keyword_set ( ROUNDED ) ) then V_SHIFT = round(V_SHIFT)

      x_shift = V_SHIFT(0,*)
      y_shift = V_SHIFT(1,*)

      info, 'INFO : (' + functionName + '): Applying shifts :'
      for i=0, n_elements(x_shift)-1 do $
        print, x_shift(i), y_shift(i)

   endif else begin

      ; we are about to correct atmopheric dispersion

      if ( n_Dims(0) ne 3 ) then $
         return, error ('ERROR IN CALL (' + functionName + '): Atmospheric dispersion can only be corrected in cubes.')

      if ( NOT file_test ( DISPERSION ) ) then $
         return, error ('ERROR IN CALL (' + functionName + '): File (' + string(DISPERSION) + $
                        ') with atmospheric dispersion offsets could not be found.')

      md_DispOffsets = readfits( DISPERSION )
      if ( NOT array_equal( (size(md_DispOffsets))(0:2), [2,2,n_Dims(1)] )) then $
         return, error ('FAILURE (' + functionName + '): File ('+string(DISPERSION)+$
                        ') with dispersion offsets is not compatible in size with the input data.')

      x_shift = md_DispOffsets(0,*)
      y_shift = md_DispOffsets(1,*)

   end

   ; ----- Shifts are determined --------------------------------------------------------------

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

         ; determine fractional and integer shift for shifting routine
         if ( keyword_set ( DISPERSION ) ) then begin

            dx = x_shift(j)       - fix(x_shift(j))   ; the shift is slice dependent
            dy = y_shift(j)       - fix(y_shift(j))
            ix = abs(min_x_shift) + fix(x_shift(j))
            iy = abs(min_y_shift) + fix(y_shift(j))

         endif else begin

            dx = x_shift(i)       - fix(x_shift(i))   ; the shift is slice independent (mosaicing)
            dy = y_shift(i)       - fix(y_shift(i))
            ix = abs(min_x_shift) + fix(x_shift(i))
            iy = abs(min_y_shift) + fix(y_shift(i))

         end

         ; extract slices for shifting
         mf_D = ( n_Dims(0) eq 3 ) ? reform((*pcf_Frame(i))(j,*,*)) : *pcf_Frame(i)
         mf_N = ( n_Dims(0) eq 3 ) ? reform((*pcf_IntFrame(i))(j,*,*)) : *pcf_IntFrame(i)
         mb_Q = ( n_Dims(0) eq 3 ) ? reform((*pcb_IntAuxFrame(i))(j,*,*)) : *pcb_IntAuxFrame(i)


         ; fill in the original slices if no fractional shift is to be applied
         if ( abs ( dx ) gt 0.01 or abs ( dy ) gt 0.01 ) then begin

            if ( keyword_set ( CUBIC ) ) then $
               s_Res = mosaic_shift_image ( mf_D, mf_N, mb_Q, dx, dy, CUBIC = CUBIC, $
                                            TEXT = 'Set '+strg(i)+' Slice '+strg(j) )

            if ( keyword_set ( BILINEAR ) ) then $
               s_Res = mosaic_shift_image ( mf_D, mf_N, mb_Q, dx, dy, $
                                            TEXT = 'Set '+strg(i)+' Slice '+strg(j) )

            if ( bool_is_struct ( s_Res ) ) then begin
               mf_D = s_Res.mf_D
               mf_N = s_Res.mf_N
               mb_Q = s_Res.mb_Q
            end

         end

         ; fill the temporary cubes with the shifted (or original) slices
         cf_Frames( j, ix : ix + n_Dims(2)-1, iy : iy + n_Dims(3)-1 )       = mf_D
         cf_IntFrames( j, ix : ix + n_Dims(2)-1, iy : iy + n_Dims(3)-1 )    = mf_N
         cb_IntAuxFrames( j, ix : ix + n_Dims(2)-1, iy : iy + n_Dims(3)-1 ) = mb_Q

      end ; loop over the slices of set i

      ; replace the dataset with the enlarged dataset
      *pcb_IntAuxFrame(i) = reform(cb_IntAuxFrames)
      *pcf_IntFrame(i)    = reform(cf_IntFrames)
      *pcf_Frame(i)       = reform(cf_Frames)

;      writefits, strg(i)+'.fits', *pcf_Frame(i)
;      writefits, strg(i)+'.fits', *pcf_IntFrame(i), /APPEND
;      writefits, strg(i)+'.fits', *pcb_IntAuxFrame(i), /APPEND

   end

   ; ----- We are done with shifting, now collapse the datasets--------------------------------

   mosaic_check_bits, pcf_Frame, pcf_IntFrame, pcb_IntAuxFrame, n_Sets  ; ensure that the bits make sense

   ; if we want to correct the dispersion only, we are done
   if ( keyword_set ( DISPERSION ) ) then return, { Status : 1 } $

   else begin

     ; if we want to equalize the individual datasets we do it now

     if ( keyword_set ( EQUALIZE ) ) then begin

        i_ll = fix(0.3*n_Dims(1))   ; in case of cubes only spectral channels between i_ll and i_ul 
        i_ul = fix(0.7*n_Dims(1))   ; are considered for determining the overlap region and the equalization

        ; first we determine the overlap regions of the individual frames
        Overlap_NPix = lonarr( n_Sets, n_Sets )

        for i=0, n_Sets-2 do begin
           for j=i, n_Sets-1 do begin

              if ( b_Images ) then $
                 Overlap_NPix ( i, j ) = total ( long ( extbit ( *pcb_IntAuxFrame(i), 0 ) and $
                                                        extbit ( *pcb_IntAuxFrame(j), 0 ) ) ) $
              else $
                 Overlap_NPix ( i, j ) = total ( long ( extbit ( (*pcb_IntAuxFrame(i))(i_ll:i_ul,*,*), 0 ) and $
                                                        extbit ( (*pcb_IntAuxFrame(j))(i_ll:i_ul,*,*), 0 ) ) )

              Overlap_NPix ( j, i ) = Overlap_NPix ( i, j )

           end
        end

        n_PixOverlapMin = 10000     ; minimum number of pixel that do overlap

        ; find a frame with which all other frames do overlap, the individual
        ; overlaps must contain at least n_PixOverlapMin pixel
        v_Overlap = where ( cmapply( 'AND', byte(Overlap_NPix gt n_PixOverlapMin), 1), n_Overlaps )

        if ( n_Overlaps gt 0 ) then begin

           ; there is a frame overlapping with all others
           ii = v_Overlap(0)
           info, 'INFO (' + functionName + '): Found reference dataset for equalizing : ' + strg(ii)

           ; now we try to equalize the datasets
           for i=0, n_Sets-1 do begin

              if ( i ne ii ) then begin   ; we do not equalize frame i with itself

                 if ( b_Images ) then $
                    v_MaskOverlap = where ( fix ( extbit ( *pcb_IntAuxFrame(i), 0 ) and $
                                                  extbit ( *pcb_IntAuxFrame(ii), 0 ) ), n_Overlap ) $
                 else $
                    v_MaskOverlap = where ( ( fix ( extbit ( *pcb_IntAuxFrame(i), 0 ) and $
                                                    extbit ( *pcb_IntAuxFrame(ii), 0 ) ) ) $
                                            (i_ll:i_ul,*,*), n_Overlap )

                 ; only do something if more than n_PixOverlapMin (overlay) pixel are present
                 if ( n_Overlap gt n_PixOverlapMin ) then begin

                    ; now do the equalization
                    info, 'INFO (' + functionName + '): Overlap area : ' + $
                             strg(n_Overlap) + ' pixel for set ' + strg(i) + '.'

                    if ( b_Images ) then begin
                       mf_Set_0 = (*pcf_Frame(i))( v_MaskOverlap )
                       mf_Set_1 = (*pcf_Frame(ii))( v_MaskOverlap )
                       ; the weights
                       v_Weights = sqrt ( ((*pcf_IntFrame(i))(v_MaskOverlap))^2 + $
                                          ((*pcf_IntFrame(ii))(v_MaskOverlap))^2  )
                    endif else begin
                       mf_Set_0 = ((*pcf_Frame(i))(i_ll:i_ul,*,*))( v_MaskOverlap )
                       mf_Set_1 = ((*pcf_Frame(ii))(i_ll:i_ul,*,*))( v_MaskOverlap )
                       ; the weights
                       v_Weights = sqrt ( (((*pcf_IntFrame(i))(i_ll:i_ul,*,*))(v_MaskOverlap))^2 + $
                                          (((*pcf_IntFrame(ii))(i_ll:i_ul,*,*))(v_MaskOverlap))^2  )
                    end

                    v_Par = [ 0., 1. ] ; initial parameters : offset, scaling 
                    ; do the minimization
                    result = mpcurvefit( mf_Set_0, mf_Set_1, v_Weights, v_Par, $
                                         FUNCTION_NAME='mosaic_equalize', /quiet, $
                                         FTOL=1.e-6, itmax=200, STATUS=stat )

                    info, 'INFO (' + functionName + '): Equalizing dataset ' + strg(i) + $
                          ' returned with status '+strg(stat) + '.'
                    info, 'INFO (' + functionName + '): Equalizing result: ' + strg(v_Par(0)) + $
                          ' (Offset), ' + strg(v_Par(1)) + ' (Scaling).'

                    ; adjust data and noise values with found fit values
                    *pcf_Frame(i)    = v_Par(1) * (v_Par(0) + *pcf_Frame(i) )
                    *pcf_IntFrame(i) = v_Par(1)* *pcf_IntFrame(i)

                endif else $
                    warning, 'SEVERE WARNING (' + functionName + '): Overlap area too small (' + $
                             strg(n_Overlap) + '). Not equalizing set ' + strg(i)

              end

           end

        endif else $
           warning, 'WARNING (' + functionName + '): No dataset found that overlaps with all others. Continuing without equalizing.'

     end

     ; do we need to average or sum

     mosaic_check_bits, pcf_Frame, pcf_IntFrame, pcb_IntAuxFrame, n_Sets  ; ensure that the bits make sense

     n_Dims = size ( *pcb_IntAuxFrame(0) )

     ; allocate memory for final quality status frame
     NewStatus = make_array ( SIZE=n_Dims, /BYTE, VALUE = 0b )

     if ( keyword_set ( AVERAGE ) ) then begin

        ; averaging the data
        info, 'INFO (' + functionName + '): Averaging shifted datasets.'
        ; the weights
        Weights  = *(pcf_IntFrame(0))
        Weights2 = (*(pcf_IntFrame(0)))^2
        Sum      = *(pcf_Frame(0)) * *(pcf_IntFrame(0)) 
        for i=1, n_Sets-1 do begin
           Sum      = Sum + *pcf_Frame(i) * *pcf_IntFrame(i)
           Weights  = Weights + *pcf_IntFrame(i)
           Weights2 = sqrt(Weights^2 + *pcf_IntFrame(i)^2)
        end

        ; find where the weight is not 0.
        MaskWeights = where ( Weights gt 0., n_Weight )
        if ( n_Weight gt 0 ) then begin
           tmp                 = *(pcf_Frame(0)) * 0.
           tmp ( MaskWeights ) = Sum ( MaskWeights ) / Weights ( MaskWeights )
           *(pcf_Frame(0))     = tmp
           *(pcf_IntFrame(0))  = Weights2
        end

        delvarx, Weights2
        delvarx, Weights
        delvarx, tmp

     endif else begin

        info, 'INFO (' + functionName + '): Summing up shifted datasets.'

        ; summing up the data
        for i=1, n_Sets-1 do begin
           *pcf_Frame(0)    = *pcf_Frame(0) + *pcf_Frame(i)
           *pcf_IntFrame(0) = sqrt( *pcf_IntFrame(0)^2 + *pcf_IntFrame(i)^2 )
        end

     end

     ; now we have to figure out how many of the individual valid (data storing) pixel have contributed 
     ; to the value of the mosaiced pixel (Count counter).
     Count = fix( extbit ( *pcb_IntAuxFrame(0), 0 ) )  ; these are data storing pixel
     for i=1, n_Sets-1 do $
        Count = Count + fix( extbit ( *pcb_IntAuxFrame(i), 0 ) )

     ; since all pixel that have qbit 0 = 1 are valid, all pixel are valid that
     ; have a non-zero value in the count map
     v_Count = where ( Count, n_Count )
     if ( n_Count gt 0 ) then $
        NewStatus(v_Count) = setbit ( NewStatus(v_Count), 0, 1 )

     ; now the interpolation status
     ; The Interpol counter contains the number of 'data storing' pixels that have been interpolated,
     ; badly interpolated pixel count twice
     Interpol = fix (   extbit ( *pcb_IntAuxFrame(0), 0 ) * $  ; these are data storing pixel
                      ( extbit ( *pcb_IntAuxFrame(0), 1 ) + $ ; these pixel are interpolated
                        ( extbit ( *pcb_IntAuxFrame(0), 1 ) and $
                           bool_invert ( extbit ( *(pcb_IntAuxFrame(0)), 2 )) ) ) )
     for i=1, n_Sets-1 do $
        Interpol = Interpol + fix (   extbit ( *pcb_IntAuxFrame(i), 0 ) * $  ; these are data storing pixel
                                    ( extbit ( *pcb_IntAuxFrame(i), 1 ) + $ ; these pixel are interpolated
                                      ( extbit ( *pcb_IntAuxFrame(i), 1 ) and $
                                        bool_invert ( extbit ( *pcb_IntAuxFrame(i), 2 )) ) ) )

     ; where Interpol counter is greater than 1/4 of the Count counter set
     ; well interpolated status
     v_MaskInt = where ( float(Interpol) gt 0.25 * float(Count), n_Int )
     if ( n_Int gt 0 ) then begin
        NewStatus(v_MaskInt) = setbit ( NewStatus(v_MaskInt), 1, 1 )
        NewStatus(v_MaskInt) = setbit ( NewStatus(v_MaskInt), 2, 1 )
     end
     v_MaskBadInt = where ( float(Interpol) gt float(Count), n_BadInt )
     if ( n_BadInt gt 0 ) then $
        NewStatus(v_MaskBadInt) = setbit ( NewStatus(v_MaskBadInt), 2, 0 )

     ; now the inside bit (Inside counter)
     Inside = extbit ( *pcb_IntAuxFrame(0), 3 )  ; padded pixels have qbit 3 = 0
     for i=1, n_Sets-1 do $
        Inside = Inside + extbit ( *pcb_IntAuxFrame(i), 3 )

     ; set the inside bit where at least one inside pixel was found
     v_MaskInside = where ( Inside gt 0, n_Inside )
     if ( n_Inside gt 0 ) then $
        NewStatus ( v_MaskInside ) = setbit ( NewStatus ( v_MaskInside ), 3, 1 )

     ; fill the new status into the 0th pointer
     *pcb_IntAuxFrame(0) = NewStatus

     ; we are done. The 0th pointer contains the result. Deletion of the
     ; other pointer must take place in the calling routine.

     return, { NFrame : Count }

   end

end
