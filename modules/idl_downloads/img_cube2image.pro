;-----------------------------------------------------------------------
; NAME:  img_cube2image
;
; PURPOSE: Collapses a cube to create an image.
;
; INPUT :  pc_Cube        : Pointer to data cube or image. The x and y axes must have at
;                           least 2 channels. Cubes must be EURO3D compliant.
;          pc_IntFrame    : Pointer to intframe cube.
;          pc_IntAuxFrame : Pointer to intauxframe cube.
;          d_SPEC_CHANNELS: range of the dispersion axis used to
;                           collapse the image in percent
;                           (0<d_SPEC_CHANNELS<1).
;          k_Mode         : 'MED' : pixel in image is the median value
;                                   of the spectrum (unweighted)
;                           'AVRG': pixel in image is the mean value
;                                   of the spectrum (weighted).
;                           'SUM' : pixel in image is the sum
;                                   of the spectrum (unweighted) 
;          [/DEBUG]       : initializes the debugging mode
;
; ON ERROR : returns ERR_UNKNOWN from APP_CONSTANTS
;
; RETURN VALUE : structure { md_Image    : collapsed image (double),
;                            mb_Valid    : image with 1 where succesfully
;                                          collapsed, 0 else (byte)
;                            mi_Channels : the number of spectral
;                                          channels on which the operation described
;                                          by k_Mode succeded (long) 
;                            md_Weight   : the 1/noise^2 in each pixel
;                                          (double)
;                                          MED, SUM : 1./total(noise^2)
;                                          AVRG     : total(1./noise^2) }
;
; NOTES :  - When collapsing the cube all pixels within the range 
;            are used that are valid as defined by valid.pro
;
;          - The Cube, IntFrame and the IntAuxFrame will not be changed.
;
; STATUS : roughly tested on 6.3.2004
;
; HISTORY : 27.2.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION img_cube2image, pc_Cube, pc_IntFrame, pc_IntAuxFrame, d_SPEC_CHANNELS, k_Mode, $
                         DEBUG=DEBUG

   COMMON APP_CONSTANTS

   if ( NOT bool_is_ptr ( pc_Cube ) ) then $
      return, error ( 'ERROR IN CALL (img_cube2image.pro): Input cube must be a pointer.')

   ; check spatial dimensions
   n = size ( *pc_Cube )

   if ( n(0) lt 2 ) then $
      return, error ( 'ERROR IN CALL (img_cube2image.pro): Input pointer neither cube nor image.')
   if ( n(0) eq 2 ) then n = [n(0),1,n(1),n(2)]     ; is it an image?

   if ( n(2) lt 2 or n(3) lt 2 ) then $
      return, error ( 'ERROR IN CALL (img_cube2image.pro): Input cube spatial dims must be at least 2x2.')

   if ( d_SPEC_CHANNELS lt 0. or d_SPEC_CHANNELS gt 1. ) then $
      return, error ('ERROR IN CALL (img_cube2image.pro): SPEC_CHANNELS out of range' )

   if ( NOT ( k_Mode eq 'MED' or k_Mode eq 'AVRG' or k_Mode eq 'SUM' ) ) then $
      return, error ( 'ERROR IN CALL (img_cube2image.pro): unknown Mode '+strtrim(string(k_Mode),2) )

   ; Calculate boundaries
   if ( d_Spec_Channels eq 1. ) then begin
      ll = 0
      ul = n(1)-1
   endif else begin
      ll = long(fix(n(1)/2)-fix(n(1)/2*d_Spec_Channels))
      ul = long(fix(n(1)/2)+fix(n(1)/2*d_Spec_Channels))
      ll = ll > 0
      ul = ul < n(1)-1 > ll
   end

   if ( keyword_set ( DEBUG ) ) then $
      debug_info, 'DEBUG INFO (img_cube2image.pro): Collapsing cube from slice '+ strg(ll)+' to '+ strg(ul)

   ; Slice cubes
   c_Frame       = (*pc_Cube)(ll:ul,*,*)
   c_IntFrame    = (*pc_IntFrame)(ll:ul,*,*)
   c_IntAuxFrame = (*pc_IntAuxFrame)(ll:ul,*,*)

   md_Avrg     = dindgen( n(2), n(3) ) * 0.
   mb_Valid    = bindgen( n(2), n(3) ) * 0b
   mi_Channels = lindgen( n(2), n(3) ) * 0l
   md_Weight   = dindgen( n(2), n(3) ) * 0.

   for i=0, n(2)-1 do $
      for j=0, n(3)-1 do begin

         ; check where valid
         v_Ind = where ( valid ( reform(c_Frame(*,i,j)), reform(c_IntFrame(*,i,j)), $
                                 reform(c_IntAuxFrame(*,i,j)) ), n_Ind )

         if ( n_Ind gt 0 ) then begin

            v_D = reform(c_Frame (v_Ind,i,j))
            v_N = reform(c_IntFrame (v_Ind,i,j))

            case k_Mode of
               'MED'  : begin
                           md_Avrg(i,j)   = median( v_D )
                           md_Weight(i,j) = 1./total( v_N^2 )
                        end
               'AVRG' : begin
                           md_Avrg(i,j)   = total( v_D / v_N^2) / total( 1./v_N^2 )
                           md_Weight(i,j) = total( 1./v_N^2 )
                        end
               'SUM'  : begin
                           md_Avrg(i,j)   = median( v_D )
                           md_Weight(i,j) = 1./total( v_N^2 )
                        end
            endcase 

            mi_Channels(i,j) = long(n_Ind)    ;the number of pixels that have been used
            mb_Valid(i,j)    = 1b             ;the pixel is valid

         endif else $
            if ( keyword_set ( DEBUG ) ) then $
               debug_info, 'DEBUG INFO (img_cube2image.pro): Pixel '+strg(i)+','+ strg(j)+' is invalid'

      end

   return, {md_Image:md_Avrg, mb_Valid:mb_Valid, mi_Channels:mi_Channels, md_Weight:md_Weight}

end

