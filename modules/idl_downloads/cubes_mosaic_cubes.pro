
;-----------------------------------------------------------------------
; NAME:  shift_object
;
; PURPOSE: Shift image or cube on subpixel basis. The x-, y-shift must be
;          less than 1
;
; INPUT :  o       : input variable
;          x_shift : 0 <= shift in x-direction < 1
;          y_shift : 0 <= shift in y-direction < 1
;          cubic   : same as in interpolate.pro
;          missing : same as in interpolate.pro
;
; OUTPUT : shifted image or cube
;
; STATUS : untested
;
; HISTORY : 27.3.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

function shift_object, o, x_shift, y_shift, cubic=cubic, missing=missing

   ; do nothing if shift is less than 0.01 pixel
   if ( abs(x_shift) lt 0.01 and abs(y_shift) lt 0.01 ) then return, o

   s  = size(o)
   Nx = s(1)
   Ny = s(2)

   if (s(0) eq 2) then Nz = 1 else Nz = s(3)

   so = dindgen(Nx,Ny,Nz)
   xo = dindgen(Nx)
   yo = dindgen(Ny)

   for i=0,Nz-1 do begin
      x = xo - x_shift
      y = yo - y_shift
      if ( keyword_set(missing) ) then $
         so(0,0,i) = interpolate ( o(*,*,i), x, y, /grid, cubic=keyword_set(cubic)?cubic:0, missing=missing ) $
      else $
         so(0,0,i) = interpolate ( o(*,*,i), x, y, /grid, cubic=keyword_set(cubic)?cubic:0 )
   end

   return, so

end


;-------------------------------------------------------------------------
; NAME:  shift_image_with_kernel
;
; PURPOSE: shift an image using the eclipse method (kernel interpolation)
;
; INPUT : mf_S     : image to be shifted
;         mb_IAux  : quality frame of the image
;         vf_K     : interpolation kernel
;         dx,dy    : shift in x- and y-direction in pixel
;         [ERROR_STATUS=ERROR_STATUS] : error status
;
; OUTPUT : returns a structure { Image : interpolated image,
;                                AuxFrame : adapted auxiliary frame } 
;
; NOTES : this routine does nothing to the image and quality frame if
;         both shifts are less than 0.01 pixel.
;
;         Currently the auxiliary frame is not changed!!!
;
;-------------------------------------------------------------------------

function shift_image_with_kernel, mf_S, mb_IAux, vf_K, dx, dy, ERROR_STATUS=error_status


   if ( NOT keyword_set(ERROR_STATUS) ) then error_status = 0

   ; do nothing if shift is less than 0.01 pixel
   if ( abs(dx) lt 0.01 and abs(dy) lt 0.01 ) then return, mf_S

   ; If you change one of the following three statements you have to change
   ; them as well in mosaic.h and you have to recompile mosaic.c.
   ; Usually there is no need to change them.
   TABSPERPIX     = 1000
   KERNEL_WIDTH   = 2.0
   KERNEL_SAMPLES = 1+fix(TABSPERPIX * KERNEL_WIDTH)


   if ( NOT bool_dim_match ( mf_S, mb_IAux ) ) then $
      return, error (['ERROR IN CALL (shift_image_with_kernel.pro): ',$
                      '         Input slice and IntAux slice not compatible in size'], error_status )

   n = size(mf_S)
   
   mf_Sx     = dindgen(n(1),n(2))*0.
   mf_Sxy    = dindgen(n(1),n(2))*0.

   mid = KERNEL_SAMPLES/2

   li = (dx lt 0) ? 1 : 2
   ui = (dx lt 0) ? n(1)-3 : n(1)-2

   fx       = double(li)-dx
   px       = fix(fx)
   rx       = fx - double(px)
   tabx     = fix(abs(double(mid) * rx))
   vf_TmpKx = [ vf_K[mid+tabx], vf_K[tabx], vf_K[mid-tabx], vf_K[KERNEL_SAMPLES-tabx-1] ]

   for j=0, n(2)-1 do $
      for i=li,ui do begin
         fx  = double(i)-dx
         pos = fix(fx)
         m_Valid = where( extbit( reform(mb_IAux[pos-1:pos+2,j]), 0 ), n_Valid )
         if ( n_Valid gt 0 ) then $
            mf_Sx(i,j) = total((mf_S(pos-1:pos+2,j))(m_Valid) * (vf_TmpKx)(m_Valid)) / $
                         total((vf_TmpKx)(m_Valid)) 
      end

   lj = (dy lt 0) ? 1 : 2
   uj = (dy lt 0) ? n(2)-3 : n(2)-2

   fy       = double(lj)-dy
   py       = fix(fy)
   ry       = fy - double(py)
   taby     = fix(abs(double(mid) * ry)) ;
   vf_TmpKy = [ vf_K[mid+taby], vf_K[taby], vf_K[mid-taby], vf_K[KERNEL_SAMPLES-taby-1] ]
   
   for i=0, n(1)-1 do $
      for j=lj,uj do begin
         fy  = double(j)-dy
         pos = fix(fy)
         m_Valid = where( extbit ( mb_IAux[i,pos-1:pos+2], 0 ) , n_Valid )
         if ( n_Valid gt 0 ) then $
            mf_Sxy(i,j) =  total((mf_Sx(i,pos-1:pos+2))(m_Valid) * (vf_TmpKy)(m_Valid)) / $
                           total((vf_TmpKy)(m_Valid))
      end

   return, {Image:mf_Sxy, AuxFrame:mb_IAux}

end


;-------------------------------------------------------------------------
; NAME:  set_surrounding_invalid
;
; PURPOSE: set surrounding pixel of a pixel with value 0 to 0
;
; INPUT :  m        : boolean matrix
;          [/CUBIC] : if set than all pixel within a 5x5 matrix
;                     centered on the pixel (with value 0) are set to 0.
; 
; OUTPUT: returns a variable of same size as m
;
;-------------------------------------------------------------------------

function set_surrounding_invalid, m, CUBIC=CUBIC

   n = size(m)

   mm = m

   for i=0, n(1)-1 do begin
      for j=0, n(2)-1 do begin
         if ( m(i,j) eq 0 ) then begin

            if ( keyword_set(CUBIC) ) then begin
               li = (i-2 ge 0) ? i-2 : 0
               ui = (i+2 le n(1)-1) ? i+2 : n(1)-1
               lj = (j-2 ge 0) ? j-2 : 0
               uj = (j+2 le n(2)-1) ? j+2 : n(2)-1
               mm(li:ui, lj:uj) = 0
            endif else begin
               li = (i-1 ge 0) ? i-1 : 0
               ui = (i+1 le n(1)-1) ? i+1 : n(1)-1
               lj = (j-1 ge 0) ? j-1 : 0
               uj = (j+1 le n(2)-1) ? j+1 : n(2)-1
               mm(li:ui, lj:uj) = 0
            end

         end
      end
   end

   return, mm

end


;-------------------------------------------------------------------------
; NAME:  determine_aux_status_after_shift
;
; PURPOSE: determines the auxiliary status after having shifted
;
; INPUT :  mb_QBit      : bool mask where the quality bit is set
;          mb_IBit      : bool mask where the interpolation bit is set
;          mb_IQBit     : bool mask where the good interpolation bit is set
;          mb_SBit      : bool mask where the outside bit is set
;          mb_ValidData : bool mask where the data value is ne NAN or INF
;          mb_ValidInt  : bool mask where the intframe value is ne 0.
;
;          dx,dy,      : shift in pixels
;          [/KERNEL]   : currently not supported
;          [/CUBIC]    : the shift has been done using cubic
;                        interpolation
;          [/BILINEAR] : the shift has been done using bilinear
;                        interpolation
;          [ERROR_STATUS=ERROR_STATUS] : error status
;
; OUTPUT: returns the new quality frame
;
; ALGORITHM : Q bit: 
;               BILINEAR: 1. if the Q bit of a pixel is equal to 0, 
;                            the surrounding 8 neighbors are set to 0
;                         2. the last row/col in shift direction is
;                            set to 0
;               CUBIC   : 1. if the Q bit of a pixel is equal to 0, 
;                            the pixel in a 5x5 matrix centered on the pixel are set to 0
;                         2. the first two rows/cols in shift direction
;                            are set to 0 and the last row/col in
;                            shift direction is set to 0
;             I bit : not yet properly defined 
;             IQ bit: not yet properly defined
;             S bit : the same as for Q bit
;-------------------------------------------------------------------------

function determine_aux_status_after_shift, mb_QBit, mb_IBit, mb_IQBit, mb_SBit, mb_ValidData, mb_ValidInt, dx, dy, $
                           KERNEL=KERNEL, CUBIC=CUBIC, BILINEAR=BILINEAR, ERROR_STATUS=ERROR_STATUS

   if ( NOT keyword_set ( ERROR_STATUS) ) then error_status = 0

   nv = total([ keyword_set ( KERNEL ), keyword_set ( CUBIC ), keyword_set ( BILINEAR )])
   if ( not ( nv eq 0 or nv eq 1 ) ) then $
      return, error (['ERROR IN CALL (determine_aux_status_after_shift.pro): ',$
                              'Either KERNEL, CUBIC, BILINEAR or none of these allowed'], error_status)


   if ( NOT ( bool_dim_match(mb_QBit,mb_IBit) and bool_dim_match(mb_QBit,mb_IQBit) and bool_dim_match(mb_QBit,mb_SBit) and $
        bool_dim_match(mb_QBit,mb_ValidData) and bool_dim_match(mb_QBit,mb_ValidInt) ) ) then $
        return, error(['ERROR IN CALL (determine_aux_status_after_shift.pro):', $
                       '              Byte masks not compatible in size'], error_status)

   ; done with the checks

   Dim = size(mb_QBit)

   if ( keyword_set ( KERNEL ) ) then begin
      mb_B0 = mb_QBit
      mb_B1 = mb_IBit
      mb_B2 = mb_IQBit
      mb_B3 = mb_SBit
   end

   if ( keyword_set ( CUBIC ) ) then begin

      ; set the quality bit and outside bit
      mb_B0 = set_surrounding_invalid ( mb_QBit and mb_ValidData and mb_ValidInt, /CUBIC )
      mb_B3 = set_surrounding_invalid ( mb_SBit, /CUBIC )

      ; set the interpolation bits
      ; this needs still some discussion
      mb_B1 = mb_IBit
      mb_B2 = mb_IQBit

      ; set the borders to outside
      if ( abs(dx) gt 0.01 ) then $
         if (dx gt 0.) then begin
            mb_B3(0:1,*)      = 0 
            mb_B3(Dim(1)-1,*) = 0
        endif else begin
            mb_B3(0,*)                 = 0 
            mb_B3(Dim(1)-2:Dim(1)-1,*) = 0
        end
      if ( abs(dy) gt 0.01 ) then $
         if (dy gt 0.) then begin
            mb_B3(*,0:1) = 0 
            mb_B3(*,Dim(2)-1) = 0
         endif else begin
            mb_B3(*,0) = 0 
            mb_B3(*,Dim(2)-2:Dim(2)-1) = 0
         end

      ; set the borders to not valid
      if ( abs(dx) gt 0.01 ) then $
         if (dx gt 0.) then begin
            mb_B0(0:1,*)      = 0 
            mb_B0(Dim(1)-1,*) = 0
        endif else begin
            mb_B0(0,*)                 = 0 
            mb_B0(Dim(1)-2:Dim(1)-1,*) = 0
        end
      if ( abs(dy) gt 0.01 ) then $
         if (dy gt 0.) then begin
            mb_B0(*,0:1) = 0 
            mb_B0(*,Dim(2)-1) = 0
         endif else begin
            mb_B0(*,0) = 0 
            mb_B0(*,Dim(2)-2:Dim(2)-1) = 0
         end

   end

   if ( keyword_set ( BILINEAR ) ) then begin

      ; set the quality bit and outside bit
      mb_B0 = set_surrounding_invalid ( mb_QBit and mb_ValidData and mb_ValidInt )
      mb_B3 = set_surrounding_invalid ( mb_SBit )

      ; set the interpolation bits
      ; this needs still some discussion
      mb_B1 = mb_IBit
      mb_B2 = mb_IQBit

      ; set the borders to outside
      if ( abs(dx) gt 0.01 ) then $
         if (dx gt 0.) then mb_B3(0,*) = 0 $
         else mb_B3(Dim(1)-1,*) = 0
      if ( abs(dy) gt 0.01 ) then $
         if (dy gt 0.) then mb_B3(*,0) = 0 $
         else mb_B3(*,Dim(2)-1) = 0

      ; set the borders to not valid
      if ( abs(dx) gt 0.01 ) then $
         if (dx gt 0.) then mb_B0(0,*) = 0 $
         else mb_B0(Dim(1)-1,*) = 0
      if ( abs(dy) gt 0.01 ) then $
         if (dy gt 0.) then mb_B0(*,0) = 0 $
         else mb_B0(*,Dim(2)-1) = 0

   end

   if ( nv eq 0 ) then begin
      mb_B0 = mb_QBit
      mb_B1 = mb_IBit
      mb_B2 = mb_IQBit
      mb_B3 = mb_SBit
   end

   ; now determine the intauxframe value

   mb_B = bindgen(Dim(1),Dim(2))*0B

   for i=0, Dim(1)-1 do $
      for j=0, Dim(2)-1 do begin
         mb_B(i,j) = setbit(mb_B(i,j),0,mb_B0(i,j))
         mb_B(i,j) = setbit(mb_B(i,j),1,mb_B1(i,j))
         mb_B(i,j) = setbit(mb_B(i,j),2,mb_B2(i,j))
         mb_B(i,j) = setbit(mb_B(i,j),3,mb_B3(i,j))
      end

   return, mb_B

end

;-----------------------------------------------------------------------
; NAME:  mosaic
;
; PURPOSE: Shift and combine cubes or images
;
; INPUT :  pcf_Data                 : pointer to input cubes or images
;          pcf_IntFrame             : pointer to input IntFrame cubes or images
;          n_Sets                  : # of input cubes or images
;          x_shift, y_shift         : double vectors with the shifts with
;                                     respect to any cube in pcf_Data
;          CUBIC=CUBIC              : Initializes the cubic convolution
;                                     interpolation method with 
;                                     0 < CUBIC <= -1 (fast!!!
;                                     and recommended with CUBIC=-0.5).
;          /BILINEAR                : Initializes the bilinear interpolation
;                                     method (fast!!!).
;          KERNEL=KERNEL            : Determines the type of the
;                                     interpolation kernel.
;                                     Must be equal to
;                                     "tanh"		Hyperbolic tangent
;                                     "sinc2"		Square sinc
;                                     "lanczos"	Lanczos2 kernel 
;                                     "hamming"	Hamming kernel 
;                                     "hann"		Hann kernel
;                                     This option is very slow!!!
;         /EQUALIZING               : adjust the cubes according to a
;                                     linear transformation: new
;                                     intesity = offset + scale*intensity
;                                     This option is not implemented
;                                     yet. Therefore if a pixel is
;                                     invalid when averaging the
;                                     single shifted cubes, the
;                                     combined pixel will be invalid
;                                     as well. 
;         /DEBUG                    : initializes the debugging level
;         ERROR_STATUS=ERROR_STATUS : initializes the error status
;
; RETURN VALUE : returns a structure with:
;                {Cube: the combined and shifted data cube, 
;                 IntFrame: the combined and shifted IntFrame cube, 
;                 IntAuxFrame: the combined IntAuxFrame cube}
;
; NOTES: - Currently the interpolation kernels (keyword KERNEL) are read from disk.
;        - The intauxframe values are not properly set when using the
;          KERNEL option
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
;                      intauxframe values see determine_aux_status_after_shift.pro
;
;             KERNEL : uses ESOs eclipse library, especially
;                      resampling.c ( for details see:
;                      N. Devillard, "The eclipse software", 
;                         The messenger No 87 - March 1997 )
;                      In this case ensure that mosaic.c is compiled
;                      which calculates the interpolation kernel.
;                      In this case the shift is done first in
;                      x-direction and than in y-direction by
;                      convolving with a 1-dimensional interpolation
;                      kernel of length 4. Invalid pixels are ignored for
;                      convolving. If a pixel is invalid the shifted
;                      pixel is invalid as well. For coding
;                      intauxframe values see determine_aux_status_after_shift.pro
;
;             Neither CUBIC/LINEAR/KERNEL: The shift-vectors are
;                      rounded to integer values. For coding
;                      intauxframe values see determine_aux_status_after_shift.pro
;
; ON ERROR: returns 0.
;
; STATUS : The BILINEAR and CUBIC keyword have been tested. Although
;    tested the KERNEL keyword is not supported because of its worse
;    performance than the CUBIC=-0.5.
;
; NOTES : Shifts less than 0.01 pixel are not performed.
;
; HISTORY : 27.3.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

function mosaic, pcf_Data, pcf_IntFrame, pcb_IntAuxFrame, n_Sets, x_shift, y_shift, $
                 CUBIC=CUBIC, BILINEAR=BILINEAR, KERNEL=KERNEL, EQUALIZING=EQUALIZING, $
                 DEBUG=DEBUG, ERRORS_STATUS=ERROR_STATUS

   ; parameter checks

   if (NOT keyword_set(ERROR_STATUS) ) then error_status = 0

   np = total( [ keyword_set(CUBIC), keyword_set(BILINEAR), keyword_set(KERNEL) ] )

   if ( np gt 1 ) then $
      return, error ( ['ERROR IN CALL (cubes_mosaic.pro):', $
                       '               Either CUBIC, BILINEAR or KERNEL'], error_status )

   DimCube = size(*pcf_Data(0))

   if ( DimCube(1) lt 5 or DimCube(2) lt 5 ) then $
      return, error('ERROR IN CALL (cubes_mosaic_cubes.pro): Cubes must be at least 6x6 in spatial dims',$
              error_status)

   if ( np eq 0 ) then begin
      x_shift = round(x_shift)
      y_shift = round(y_shift)
   end

   if ( keyword_set(KERNEL) ) then begin
      case KERNEL of

         "tanh"	   : if keyword_set ( DEBUG ) then debug_info, 'DEBUG INFO (cubes_mosaic.pro): Using default = tanh kernel'
         "sinc2"   : if keyword_set ( DEBUG ) then debug_info, 'DEBUG INFO (cubes_mosaic.pro): Using sinc2 kernel'
         "lanczos" : if keyword_set ( DEBUG ) then debug_info, 'DEBUG INFO (cubes_mosaic.pro): Using lanczos kernel'
         "hamming" : if keyword_set ( DEBUG ) then debug_info, 'DEBUG INFO (cubes_mosaic.pro): Using hamming kernel'
         "hann"	   : if keyword_set ( DEBUG ) then debug_info, 'DEBUG INFO (cubes_mosaic.pro): Using hann kernel'
         else      : return, error ( ['ERROR IN CALL (cubes_mosaic.pro):', $
                                      '               Unknown KERNEL mode'], error_status )
      endcase
   end

   if ( keyword_set(CUBIC) ) then $
      if ( CUBIC lt -1. or CUBIC gt 0. ) then $
         return, error ( ['ERROR IN CALL (cubes_mosaic.pro): 0 < CUBIC < 1'], error_status )

   ; done with the parameter checks

   if ( keyword_set(DEBUG) ) then T=systime(1)


   ; determine size of the combined cube 
   maxx = max(x_shift)      &  maxy = max(y_shift)      &  minx = min(x_shift)      &  miny = min(y_shift)
   max_x_shift = fix(maxx)  &  max_y_shift = fix(maxy)  &  min_x_shift = fix(minx)  &  min_y_shift = fix(miny)
   nn1 = DimCube(1)+max_x_shift-min_x_shift
   nn2 = DimCube(2)+max_y_shift-min_y_shift

   if ( keyword_set ( DEBUG ) ) then begin
      debug_info, 'DEBUG INFO (cubes_mosaic.pro): Min Max X,Y '+$
                  strtrim(string(min_x_shift),2)+' '+strtrim(string(max_x_shift),2)+' '+$
                  strtrim(string(min_y_shift),2)+' '+strtrim(string(max_y_shift),2)

      debug_info, 'DEBUG INFO (cubes_mosaic.pro): Size of combined cube '+$
                  strtrim(string(nn1),2)+' '+strtrim(string(nn2),2)
   end

   if ( keyword_set(KERNEL) ) then begin
      ; calculate the kernel with mosaic.c or read it from disk
      case KERNEL of
         'tanh'   : v_Kernel = readfits('tanh_kernel.fits')
         'sinc2'  : v_Kernel = readfits('sinc2_kernel.fits')
         'lanczos': v_Kernel = readfits('lanczos_kernel.fits')
         'hamming': v_Kernel = readfits('hamming_kernel.fits')
         'hann'   : v_Kernel = readfits('hann_kernel.fits')
      endcase
   end

   ; loop over the cubes
   for i=0,n_Sets-1 do begin

      ; new ith cubes to store the shifted ith cubes
      cf_Cubes        = dindgen(nn1,nn2,DimCube(3))*0.
      cf_IntFrames    = dindgen(nn1,nn2,DimCube(3))*0.
      cb_IntAuxFrames = bindgen(nn1,nn2,DimCube(3))*0b

      if ( keyword_set(DEBUG) ) then $
            debug_info, 'DEBUG INFO (cubes_mosaic.pro): Working on cube '+strtrim(string(i),2)

      ; loop over the slices of cube i
      for j=0, DimCube(3)-1 do begin

         if ( keyword_set(DEBUG) ) then $
            if ( (j mod fix((DimCube(3)/4.)) ) eq 0 ) then $
               debug_info, 'DEBUG INFO (cubes_mosaic_cubes.pro): Done '+$
                           strtrim(string(fix(double(j)/DimCube(3)*100.)),2)+'%'

         dx   = x_shift(i) - fix(x_shift(i))
         dy   = y_shift(i) - fix(y_shift(i))

         ; 2d masks where quality bit is set the outside bit is not set and data,
         ; IntFrame values are valid
         mb_QBit      = extbit ( reform((*pcb_IntAuxFrame(i))(*,*,j)), 0 )           ; is 1 if valid
         mb_SBit      = extbit ( reform((*pcb_IntAuxFrame(i))(*,*,j)), 3 )           ; is 1 if inside
         mb_ValidInt  = int_valid ( reform((*pcf_IntFrame(i))(*,*,j)), n_IntValid )  ; is 1 if intframe value gt 1.d-10
         mb_ValidData = data_valid ( reform((*pcf_Data(i))(*,*,j)), n_Valid )        ; is 1 if data value ne NAN or INF
 
         ; this is only a consistency check
         m_Mask =  mb_QBit and mb_SBit and ( not mb_ValidData or not mb_ValidInt ) 
         mmm = where ( m_Mask, n_Mask ) 
         if ( n_Mask ne 0 ) then begin
            warning,['WARNING (cubes_mosaic_cubes.pro):',$
                     '        '+strtrim(string(n_Mask),2)+' pixel in slice '+strtrim(string(j),2)+' of cube '+strtrim(string(i),2)+$
                              ' has Q=1 and S=1 but either the corresponding intframe', $
                     '        value is less than 1.D-10 or the data value is INF or NAN.', $
                     '        First occurance at '+strtrim(string(mmm(0)),2)+'='+$
                              strtrim(string(mmm(0) MOD DimCube(2)),2)+','+$
                              strtrim(string(mmm(0) / DimCube(1)),2),$
                     '        Q:'+strtrim(string(fix(mb_QBit(mmm(0)))),2)+$
                     '        S:'+strtrim(string(fix(mb_SBit(mmm(0)))),2)+$
                     '        Data:'+strtrim(string((reform((*pcf_Data(i))(*,*,j)))(mmm(0))),2)+$
                     '        Intframe:' + strtrim(string((reform((*pcf_IntFrame(i))(*,*,j)))(mmm(0))),2),$
                     '    Setting these to Q=0' ]
         end

         ; v_AllValid is 1 where the actual slice is valid
         v_AllValid = where( mb_QBit and mb_SBit and mb_ValidInt and mb_ValidData, n_AllValid )

;         print,'--before-----------------------'
;         print,'Cube ',i,' Slice',j
;         print,'Intframe'
;         print, reform((*pcf_IntFrame(i))(*,*,j))
;         print,'Valid'
;         print, reform((*pcb_IntAuxFrame(i))(*,*,j))
;         print,'Slice'
;         print, reform((*pcf_Data(i))(*,*,j))
;         print,'-------------------------'


         ; only do something if the number of valid pixel within the current slice is gt 0
         if ( n_AllValid gt 0 ) then begin

            ; the actual slices with the intframe values transfered to noise values
            mf_ActualSlice                  = reform((*pcf_Data(i))(*,*,j))
            mf_ActualSliceNoise             = dindgen(DimCube(1),DimCube(2))*0.
            mf_ActualSliceNoise(v_AllValid) = intframe2noise((reform((*pcf_IntFrame(i))(*,*,j)))(v_AllValid))
            mb_ActualSliceIntAuxFrame       = reform((*pcb_IntAuxFrame(i))(*,*,j))

            mb_IBit  = extbit ( reform((*pcb_IntAuxFrame(i))(*,*,j)), 1 )           ; is 1 if interpolated
            mb_IQBit = extbit ( reform((*pcb_IntAuxFrame(i))(*,*,j)), 2 )           ; is 1 if good interpolated

            if ( keyword_set(CUBIC) ) then begin
               ; do the cubic interpolation

               ; shift the data with cubic interpolation
               mf_S  = shift_object(mf_ActualSlice, dx, dy, cubic=cubic)
               ; shift the noise(!) with bilinear interpolation
               mf_N  = shift_object(mf_ActualSliceNoise, dx, dy)
               ; determine new aux status
               mb_IA = determine_aux_status_after_shift ( mb_QBit, mb_IBit, mb_IQBit, mb_SBit, mb_ValidData, $
                                                          mb_ValidInt, dx, dy, /CUBIC )

            endif else begin

               if ( keyword_set(BILINEAR) ) then begin
                  ; do the bilinear interpolation

                  ; shift the data with bilinear interpolation
                  mf_S  = shift_object(mf_ActualSlice, dx, dy)
                  ; shift the noise(!) with bilinear interpolation
                  mf_N  = shift_object(mf_ActualSliceNoise, dx, dy)
                  ; determine new aux status
                  mb_IA = determine_aux_status_after_shift ( mb_QBit, mb_IBit, mb_IQBit, mb_SBit, mb_ValidData, $
                                                             mb_ValidInt, dx, dy, /BILINEAR )

               endif else begin

                  if ( keyword_set(KERNEL) ) then begin
                     ; do the eclipse stuff

                     ; shift the data with kernel interpolation
                     mf_S  = shift_image_with_kernel ( mf_ActualSlice, reform((*pcb_IntAuxFrame(i))(*,*,j)), $
                                                       v_Kernel, dx, dy, ERROR_STATUS=error_status )
                     ; shift the noise(!) with bilinear interpolation
                     mf_N  = shift_object(mf_ActualSliceNoise, dx, dy)
                     ; determine new aux status
                     mb_IA = determine_aux_status_after_shift ( mb_QBit, mb_IBit, mb_IQBit, mb_SBit, mb_ValidData, $
                                                                mb_ValidInt, dx, dy, /KERNEL )

                  endif else begin
                     ; do integer pixel shift
                     mf_S  = mf_ActualSlice
                     mf_N  = mf_ActualSliceIntFrame
                     mb_IA = determine_aux_status_after_shift ( mb_QBit, mb_IBit, mb_IQBit, mb_SBit, mb_ValidData, $
                                                                mb_ValidInt, dx, dy )
                  end
               end
            end

            m1 = where ( mf_N eq 0. and extbit(mb_IA,0), nm1 )
            if ( nm1 gt 0 ) then begin
               warning,['WARNING (cubes_mosaic_cubes.pro):',$
                        '        A noise value is equal to 0.0 and the quality bit is set to 1', $
                        '        The noise value cannot be translated into a weight.',$
                        '        Cause: the bilinear shift of the noise frame produced pixel with 0 noise that',$
                        '               have not been detected as invalid by determine_aux_status_after_shift.pro',$
                        '        The quality bit of these pixels is set to 0.']
               mb_IA(m1) = setbit(mb_IA(m1),0,0)
            end

            ; determine integer offset in slice
            n1 = abs(min_x_shift)+fix(x_shift(i))
            n2 = abs(min_y_shift)+fix(y_shift(i))

            ; fill the temporary slice cubes with the shifted slices
            cf_Cubes(n1:n1+DimCube(1)-1,n2:n2+DimCube(2)-1, j)        = mf_S

            v_Mask = where(extbit(mb_IA,0) eq 0 ,n_Mask)
            if ( n_Mask gt 0 ) then mf_N(v_Mask)=0.
            cf_IntFrames(n1:n1+DimCube(1)-1,n2:n2+DimCube(2)-1, j)    = intframe2noise(mf_N,/REV)

            cb_IntAuxFrames(n1:n1+DimCube(1)-1,n2:n2+DimCube(2)-1, j) = mb_IA

;            print,'--after------------------------'
;            print,'Cube ',i,' Slice',j
;            print,'Intframe'
;            print, cf_IntFrames(n1:n1+DimCube(1)-1,n2:n2+DimCube(2)-1, j)
;            print,'Auxiliary'
;            print, cb_IntAuxFrames(n1:n1+DimCube(1)-1,n2:n2+DimCube(2)-1, j)
;            print,'Data'
;            print, cf_Cubes(n1:n1+DimCube(1)-1,n2:n2+DimCube(2)-1, j)
;            print,'-------------------------'

         end
      end

      ; delete the old ith cubes and put the shifted ith cubes into place
      pcb_IAF = ptr_new(/ALLOCATE_HEAP)
      pcf_IF  = ptr_new(/ALLOCATE_HEAP)
      pcf_C   = ptr_new(/ALLOCATE_HEAP)

      *pcb_IAF = (*pcb_IntAuxFrame(i))
      *pcf_IF  = (*pcf_IntFrame(i))
      *pcf_C   = (*pcf_Data(i))

      (*pcb_IntAuxFrame(i)) = cb_IntAuxFrames
      (*pcf_IntFrame(i))    = cf_IntFrames
      (*pcf_Data(i))        = cf_Cubes

      ptr_free, pcb_IAF, pcf_IF, pcf_C 

   end

   if ( keyword_set ( EQUALIZE ) ) then begin

      if ( keyword_set(DEBUG) ) then $
         debug_info,'DEBUG INFO (cubes_mosaic_cubes.pro): Equalizing now, Collapsing cubes now.'

      ; create collapsed images for equalizing
      cd_Images = dindgen(DimCube(1),DimCube(2),n_Sets)*0.d
      cd_Weight = dindgen(DimCube(1),DimCube(2),n_Sets)*0.d

      for i=0, n_Sets-1 do begin
         s_Image = img_cube2image( pcf_Data(i), pcf_IntFrame(i), pcb_IntAuxFrame(i), 0.8, 'MED', $
                                   ERROR_STATUS = error_status, DEBUG=keyword_set(DEBUG) )
         cd_Image(*,*,i)  = s_Image.dImage
         cd_Weight(*,*,i) = s_Image.dWeight
      end

      ; equalize
      ; the interface needs to be changed
      ; v_Fit = equalize ( ptr_new(cd_Image), ptr_new(cd_Weight), /DEBUG )

      ; adjust the cubes with the found parameters
      ; for i=0,n_Sets-1 do begin
      ;    p = v_Fit(i*2:i*2+1)
      ;    (*pcf_Data(i))     = (*pcf_Data(i)) * p(1) + p(0)  
      ;    (*pcf_IntFrame(i)) = (*pcf_IntFrame(i)) * p(1)
      ; end        

   end

   ; we are done with the loop over the cubes now average the cubes
   ; the new combined cubes

   ; memory for the new combined cubes
   cf_Cubes        = dindgen(nn1,nn2,DimCube(3))*0.d
   cf_IntFrames    = dindgen(nn1,nn2,DimCube(3))*0.d
   cb_IntAuxFrames = bindgen(nn1,nn2,DimCube(3))*0b

   if ( keyword_set(DEBUG) ) then $
      debug_info, 'DEBUG INFO (cubes_mosaic_cubes.pro): Averaging now'  

   for j=0,DimCube(3)-1 do begin

      if ( keyword_set(DEBUG) ) then $
         if ( (j mod fix((DimCube(3)/20.)) ) eq 0 ) then $
            debug_info, 'DEBUG INFO (cubes_mosaic_cubes.pro): Done '+$
                        strtrim(string(fix(double(j)/DimCube(3)*100.)),2)+'%'

      for k1=0, nn1-1 do begin
         for k2=0, nn2-1 do begin

            v_ValidBit        = bindgen(n_Sets)*0B
            v_InterpolBit     = bindgen(n_Sets)*0B
            v_GoodInterpolBit = bindgen(n_Sets)*0B
            v_InsideBit       = bindgen(n_Sets)*0B

            for i=0, n_Sets-1 do begin
               v_ValidBit[i]        = extbit((*pcb_IntAuxFrame(i))(k1,k2,j), 0 )
               v_InterpolBit[i]     = extbit((*pcb_IntAuxFrame(i))(k1,k2,j), 1 )
               v_GoodInterpolBit[i] = extbit((*pcb_IntAuxFrame(i))(k1,k2,j), 2 )
               v_InsideBit[i]       = extbit((*pcb_IntAuxFrame(i))(k1,k2,j), 3 )
            end

            ; valid bits must be valid and inside
            v_Mask = where ( ( v_ValidBit and v_InsideBit ) eq 1, n_Mask )

            ; without equalizing all pixels must be valid and within a spectrum
            if ( n_Mask eq n_Sets ) then begin

               d_ws = 0.  &  d_w  = 0.  &  d_n  = 0.

               for id = 0, n_Mask-1 do begin
                  d_ws = d_ws + (*pcf_Data(v_Mask(id)))(k1,k2,j) * (*pcf_IntFrame(v_Mask(id)))(k1,k2,j)
                  d_w  = d_w  + (*pcf_IntFrame(v_Mask(id)))(k1,k2,j)
                  d_n  = d_n + intframe2noise((*pcf_IntFrame(v_Mask(id)))(k1,k2,j))^2
               end

               cf_Cubes(k1,k2,j) = d_ws / d_w
               cf_IntFrames(k1,k2,j) = intframe2noise(sqrt(d_n),/REV)

               ; the valid bit is set for sure
               cb_IntAuxFrames(k1,k2,j) = setbit(cb_IntAuxFrames(k1,k2,j),0,1)

               ; the interpolation bits
               ni = total(v_InterpolBit)
               ; ngi : number of "good interpolated pixels"
               ;       either Bit 2 und 3 or Bit 1 und not 2
               ngi = total((v_InterpolBit and v_GoodInterpolBit) or (v_ValidBit and bool_invert(v_InterpolBit)))
               ; nbi : number of "bad interpolated pixels"
               ;       Bit 2 und not 3                
               nbi = total(v_InterpolBit and bool_invert(v_GoodInterpolBit))
               if ( ni gt 0 ) then begin
                  ; some pixels are interpolated
                  cb_IntAuxFrames(k1,k2,j) = setbit(cb_IntAuxFrames(k1,k2,j),1,1)
                  ; if the fraction of badly interpolated pixel is less than 25%, then assign
                  ; good interpolated
                  if ( double(nbi)/double(nbi+ngi) gt 0.25 ) then $
                     cb_IntAuxFrames(k1,k2,j) = setbit(cb_IntAuxFrames(k1,k2,j),2,1) 
               endif else begin
                  ; there are no interpolated pixels, that means all pixels have Q=1 and I=0
                  ; cb_IntAuxFrames(k1,k2,j) = setbit(cb_IntAuxFrames(k1,k2,j),1,0)              
                  ; cb_IntAuxFrames(k1,k2,j) = setbit(cb_IntAuxFrames(k1,k2,j),2,0)              
               end

               ; the inside bit is set for sure
               cb_IntAuxFrames(k1,k2,j) = setbit(cb_IntAuxFrames(k1,k2,j),3,1)

               ; not more than 15 overlays can be coded in the auxiliary frame
               n_Mask = n_Mask gt 15 ? 15 : n_Mask
               cb_IntAuxFrames(k1,k2,j) = cb_IntAuxFrames(k1,k2,j) + byte(n_Mask) * byte(16) 
            end
         end
      end
   end

   if ( keyword_set(DEBUG) ) then begin
      TT=systime(1)-T
      debug_info,'DEBUG INFO (cubes_mosaic.pro): ran for '+strtrim(string(TT),2)+' seconds'
   end 

;   print, '--result-----------'
;   print, 'Slice'
;   print, cf_Cubes
;   print, 'Intframe'
;   print, cf_IntFrames
;   print, 'IntAuxFrame'
;   print, cb_IntAuxFrames

   return, {Cube:cf_Cubes, IntFrame:cf_IntFrames, IntAuxFrame: cb_IntAuxFrames }

end





