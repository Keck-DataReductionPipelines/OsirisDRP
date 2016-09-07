;-------------------------------------------------------------------------
; NAME: fx_func
;
; PURPOSE: helper function for fx_root in linearize.pro
;
; STATUS : untested
;
; HISTORY : 9.9.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-------------------------------------------------------------------------

function fx_func, x

   COMMON Linearize_Coefficients, COMMON_d_A1, COMMON_d_A2, COMMON_d_A3, COMMON_d_A4, COMMON_d_Y

   return, x + COMMON_d_A1*x^2 + COMMON_d_A2*x^3 + COMMON_d_A3*x^4 + COMMON_d_A4*x^5 - COMMON_d_Y

end



;-------------------------------------------------------------------------
; NAME: linearize
;
; PURPOSE: linearize detector signals
;
; INPUT : pmb_Bad            : pointer to byte matrix indicating good
;                              pixel (1b), (0b) else. Slice 3 of
;                              output of mkdetrespo_000.pro.
;         pmf_SatLevel       : pointer to matrix with maximum value of
;                              the response curve (float). Saturation
;                              level. Slice 0 of
;                              output of mkdetrespo_000.pro.
;         pmf_Coeff0         : pointer to float matrix with 0th
;                              coefficient. Slice 10 of output of mkdetrespo_000.pro.
;         pmf_Coeff1         : pointer to float matrix with 0th
;                              coefficient. Slice 11 of output of mkdetrespo_000.pro.
;         pmf_Coeff2         : pointer to float matrix with 0th
;                              coefficient. Slice 12 of output of mkdetrespo_000.pro.
;         pmf_Coeff3         : pointer to float matrix with 0th
;                              coefficient. Slice 13 of output of mkdetrespo_000.pro.
;         p_Frames           : pointer or pointerarray with the frames
;         p_IntFrames        : pointer or pointerarray with the intframes
;         p_IntAuxFrames     : pointer or pointerarray with the intauxframes
;         nFrames            : number of input dataset pointers
;         d_Limit            : maximum allowed float value for a pixel to be linearized
;         d_Maximum          : a pixel is linearized if its value is
;                              less than d_Maximum * saturation
;                              level.
;         i_CPix             : if the number of consecutive (in a
;                              column) saturated pixel exceed i_CPix a
;                              warning is printed. 
;         d_HiLimit          : a pixel is accounted for as saturated
;                              if after the linearization the
;                              linearized pixel value exceeds
;                              d_HiLimit times the unlinearized pixel value. 
;         d_LoLimit          : a pixel is accounted for as invalid
;                              if after the linearization the
;                              linearized pixel value is lower than 
;                              d_LoLimit times the unlinearized pixel value.
;         [BAD2 = pmb_Bad2]  : pointer to optional bad pixel mask (1:
;                              good, 0:bad)
;         [\DEBUG]           : initialize the debugging mode
;
; OUTPUT : None
;
; ALGORITHM : linearize pixels if :
;                indicated by external bad pixel mask
;                valid acc. to valid( /VALIDS ) 
;                its value is gt d_Limit
;                its value is gt d_Maximum * saturation level

;
; NOTES : Uses a COMMON block named Linearize_Coefficients
;
; OUTPUT : returns an integer vector of same length as nFrames with
;          the numer of successfully linearized pixel in each frame.
;
; ON ERROR : not occuring
;
; STATUS : untested
;
; HISTORY : 9.9.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-------------------------------------------------------------------------

function linearize, pmb_Bad, pmf_SatLevel, pmf_Coeff0, pmf_Coeff1, pmf_Coeff2, pmf_Coeff3, $
                    p_Frames, p_IntFrames, p_IntAuxFrames, nFrames, $
                    d_Limit, d_Maximum, i_CPix, d_HiLimit, d_LoLimit, $
                    BAD2 = pmb_Bad2, DEBUG = DEBUG

   COMMON Linearize_Coefficients, COMMON_d_A1, COMMON_d_A2, COMMON_d_A3, COMMON_d_A4, COMMON_d_Y
   COMMON APP_CONSTANTS

   n_Dims = size ( *pmb_Bad )

   ; counter for successfully linearized pixel per frame
   vi_Success = intarr ( nFrames )

   ; loop over the input frames
   for n=0, nFrames-1 do begin

      ; create memory for the result
      mf_Frame       = make_array ( /FLOAT, SIZE=n_Dims )
      mf_IntFrame    = make_array ( /FLOAT, SIZE=n_Dims )
      mb_IntAuxFrame = make_array ( /BYTE, SIZE=n_Dims )

      ; create bad pixel indicator mask
      if ( keyword_set ( BAD2 ) ) then mb_Bad = *pmb_Bad and *pmb_Bad2 else mb_Bad = *pmb_Bad

      ; loop over the pixel
      for i=0, n_Dims(1)-1 do begin

         if ( ((i+1) mod ((n_Dims(1)/20)>1) ) eq 0 ) then $
            info,'INFO (linearize.pro): '+ strg(fix(float(i+1)*100./n_Dims(1)))+$
                 '% of the columns of set '+strg(n)+' linearized.'

         ; counter for consecutive saturated pixel in a column
         i_OverExp = 0

         for j=0, n_Dims(2)-1 do begin

            ; check the number of consecutive saturated pixel
            if ( i_OverExp gt i_CPix ) then begin
               warning, 'WARNING (linearize.pro): Number of consecutive saturated pixels in col ' + strg(j) + $
                        ' exceeds the limit.'
               i_OverExp = 0
            end

            ; get the values of the pixel
            d_Val = (*p_Frames(n))(i,j)
            d_Noi = (*p_IntFrames(n))(i,j)
            b_Sta = (*p_IntAuxFrames(n))(i,j)

            ; check pixel
            if ( mb_Bad(i,j) eq 0 or $                            ;  the pixel is marked as bad
                                                                  ;     acc. to Coefficient 3 or external mask
                 valid( d_Val, d_Noi, b_Sta, /VALIDS ) ne 1 or $           ;  the pixel is not valid
                 d_Val gt d_Limit or $                            ;  the pixels value exceeds the limit
                 d_Val gt d_Maximum* ((*pmf_SatLevel)(i,j)) $       ;  the pixels values exceeds 
                                                                  ;    d_Maximum*the saturation level
                                                      ) then begin
               ; the pixel failed. Return its values and set the 0th bit to 0
               mf_Frame(i,j)       = d_Val
               mf_IntFrame(i,j)    = d_Noi
               mb_IntAuxFrame(i,j) = b_Sta
               mb_IntAuxFrame(i,j) = setbit ( mb_IntAuxFrame(i,j), 0, 0 )

               ; if it is 'saturated' increase the saturation counter
               if ( d_Val gt d_Limit or $
                    d_Val gt d_Maximum* ( (*pmf_SatLevel)(i,j) ) ) then $
                  i_OverExp = i_OverExp + 1

            endif else begin

               ; do the linearization

               ; declare common variables
               COMMON_d_A1 = (*pmf_Coeff0)(i,j)
               COMMON_d_A2 = (*pmf_Coeff1)(i,j)
               COMMON_d_A3 = (*pmf_Coeff2)(i,j)
               COMMON_d_A4 = (*pmf_Coeff3)(i,j)
               COMMON_d_Y  = d_Val

               ; solve the equation
               d_Result = float( fx_root ( [0., 1., 2.], 'fx_func' ) ) ; the result maybe complex
               if ( d_Result gt d_Val * d_HiLimit or d_Result lt d_Val * d_LoLimit ) then begin
                  mf_Frame(i,j)       = d_Val
                  mf_IntFrame(i,j)    = d_Noi
                  mb_IntAuxFrame(i,j) = b_Sta
                  mb_IntAuxFrame(i,j) = setbit ( mb_IntAuxFrame(i,j), 0, 0 )
                  ; increase the saturation counter if saturated
                  if ( d_Result gt d_Val * d_HiLimit ) then $
                     i_OverExp = i_OverExp + 1
                  vi_Success(n) = vi_Success(n) + 1

               endif else begin
                  mf_Frame(i,j)       = d_Result 
                  mf_IntFrame(i,j)    = d_Noi * abs(d_Result/d_Val)
                  mb_IntAuxFrame(i,j) = b_Sta
                  i_OverExp           = 0

               end

            end

         end

      end

      ; put the result into place
      *p_Frames(n)       = mf_Frame
      *p_IntFrames(n)    = mf_IntFrame
      *p_IntAuxFrames(n) = mb_IntAuxFrame

      if ( keyword_set ( DEBUG ) ) then $
         debug_info, 'DEBUG INFO (linearize.pro): Linearized ' + strg(vi_Success(n)) + ' of ' + $
                     strg(n_Dims(1)) + ' successfully.'

   end

   return, vi_Success

end
