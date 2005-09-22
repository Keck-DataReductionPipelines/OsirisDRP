;-----------------------------------------------------------------------
; NAME:  subtract_slice_bg_from_cube
;
; PURPOSE: Estimate the background in each slice of a cube by fitting
;          a plane or medianing and subtract it
;
; INPUT :  pcf_Frame       : pointer to a float cube. (EURO3D compliant)
;          pcfIntFrame     : pointer to intframe. 
;          pcb_IntAuxFrame : pointer to intauxframe.
;          [MASK=MASK]     : 2d boolean mask, set to 0 where
;                            pixels in a slice shall not be used (invalid pixel), 1 else.
;          [/MEDIANING]    : if set, then the median value of all valid
;                            pixels which are not masked with MASK is the
;                            background value in each slice  
;          [/DEBUG]        : starts the debugging mode
;
; OUTPUT : pcf_Frame will be modified.
;          
; RETURN VALUE : Returns an image [n_spectral_channels,3]
;                meaning of the 1st axis :
;                   0: fitted offsets
;                   1: fitted x-slopes
;                   2: fitted y-slopes
;
;                If MEDIANING is set returns a vector [n_spectral_channels]
;
; Notes : none
;
; ALGORITHM : This functions fits a plane to each slice of a cube to
;             estimate the background.
;             Pixels are valid according valid.pro
;
;             Fitting:
;             The fit will be done if at least 5 pixel in the slice
;             are valid and the topology of the pixels does not reveal
;             a 1d structure, like a vertical, horizontal or diagonal line.
;             The fit is done weighted.
;             If the fit is succesful the fit is extrapolated to all
;             pixels and subtracted from the slice.
;             If the fit was not succesful the slice is unchanged but
;             the intframe slice is set to 0 and the Q bit of the 
;             intauxframe values are set to invalid.
;             Except of a fit failure the intframe and intauxframe
;             values are not changed. 
;
;             Medianing:
;             The background is estimated from valid sky-pixels by
;             medianing. If the number of valid pixels
;             is less than 1, the the data and intframe values are set
;             to 0 and the Q bit of the intauxframe values are set to 0.
;
;
; STATUS : compiles
;
; HISTORY : 27.2.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION subtract_slice_bg_from_cube, pcf_Frame, pcf_IntFrame, pcb_IntAuxFrame, $
                                      MASK=MASK, MEDIANING=MEDIANING, DEBUG=DEBUG

   COMMON APP_CONSTANTS

   functionName = 'subtract_slice_bg_from_cube'

   ; check integrity

   if ( bool_pointer_integrity ( pcf_Frame, pcf_IntFrame, pcb_IntAuxFrame, 1, $
                                 functionName, /CUBE ) ne OK ) then $
      return, error ( 'ERROR IN CALL (subtract_slice_bg_from_cube): Integrity check failed.' )

   DimCube = size(*pcf_Frame)

   if ( keyword_set ( MASK ) ) then begin

      if ( NOT bool_is_image(mask) ) then $
         return, error ('ERROR IN CALL (subtract_slice_bg_from_cube): optional mask is not an image' )

      DimMask = size(mask)
      if ( DimCube(2) ne DimMask(1) or DimCube(3) ne DimMask(2) ) then $
         return, error ('ERROR IN CALL (subtract_slice_bg_from_cube):'+ $
                        'dims of input mask does not fit dims of cube' )

      if ( NOT bool_is_bool ( mask ) ) then $
         return, error ('ERROR IN CALL (subtract_slice_bg_from_cube): Mask is not of type boolean' )

   end

   if ( keyword_set ( DEBUG ) ) then $
      if ( keyword_set ( MEDIANING ) ) then $
         debug_info,'DEBUG INFO (subtract_slice_from_bg.pro): Medianing.' $
      else $
         debug_info,'DEBUG INFO (subtract_slice_from_bg.pro): Fitting.'
 
   ; ---- here it goes

   if ( keyword_set(MEDIANING) ) then $
      md_Res = dindgen(DimCube(1)) * 0. $
   else $
      md_Res = dindgen(DimCube(1),3) * 0.

   ; loop over the slices
   for k=0, DimCube(1)-1 do begin

      mb_Mask = valid ( reform((*pcf_Frame)(k,*,*)), reform((*pcf_IntFrame)(k,*,*)), $
                        reform((*pcb_IntAuxFrame)(k,*,*)) )

      if ( keyword_set ( MASK ) ) then $
         v_Ind = where( mb_Mask and MASK, n_Ind ) $
      else $
         v_Ind = where( mb_Mask, n_Ind )

      if ( keyword_set(MEDIANING) ) then begin

         if ( n_Ind gt 0 ) then begin

            d_BG                = median((reform((*pcf_Frame)(k,*,*)))(v_Ind))
            (*pcf_Frame)(*,*,k) = (*pcf_Frame)(k,*,*) - d_BG
            md_Res[k]           = d_BG
           
         endif else begin
            if ( keyword_set ( DEBUG ) ) then $
,                  debug_info, 'DEBUG INFO (subtract_slice_bg_from_cube.pro): '+ $
                              'Number of valid pixels is zero in slice '+ $
                              strtrim(string(k),2)+'. Medianing failed.'
            (*pcb_IntAuxFrame)(k,*,*) = setbit ( (*pcb_IntAuxFrame)(k,*,*), 0, 0 )
            (*pcf_IntFrame)(k,*,*)    = 0.
            (*pcf_Frame)(k,*,*)       = 0. 
         end

      end

      if ( NOT keyword_set ( MEDIANING ) ) then begin

         if ( n_Ind gt 4 ) then begin

            m_Plane          = dindgen(DimCube(2),DimCube(3))*0.
            m_Plane(v_Ind)   = (reform((*pcf_Frame)(k,*,*)))(v_Ind)
            m_Weights        = dindgen(DimCube(2),DimCube(3))*0.
            m_Weights(v_Ind) = 1./(reform((*pcf_IntFrame)(k,*,*)))(v_Ind)^2

            m_Plane = img_lin2dfit2 ( m_Plane, v_par, m_Weights, UNIQUE = b_Unique )

            if ( b_Unique and bool_is_image ( m_Plane ) ) then begin

               md_Res[k,0] = v_par(0) & md_Res[k,1] = v_par(1) & md_Res[k,2] = v_par(2) 
               (*pcf_Frame)(k,*,*) = (*pcf_Frame)(k,*,*) - m_Plane

            endif else begin
               if ( keyword_set ( DEBUG ) ) then $
                  debug_info, ['DEBUG INFO (subtract_slice_bg_from_cube.pro): Cannot fit plane '+ $
                              strtrim(string(k),2)+ ' because its 1d or the fit result is not 2d.', $
                              '   Setting slice to invalid.']
               (*pcb_IntAuxFrame)(k,*,*) = setbit ( (*pcb_IntAuxFrame)(k,*,*), 0, 0 )
               (*pcf_IntFrame)(k,*,*)    = 0.
               (*pcf_Frame)(k,*,*)       = 0. 
            end


         endif else $
            if ( keyword_set ( DEBUG ) ) then $
               debug_info, 'DEBUG INFO (subtract_slice_bg_from_cube.pro): Plane fitting failed in slice '+ $
                  strtrim(string(k),2)+' due to few pixel'
     end

   end


   if ( keyword_set(DEBUG) ) then begin

      if ( keyword_set(MEDIANING) ) then begin
         ; plot the found backgrounds
         !p.multi=[0,1,0]
         !p.charsize=1.5
         plot, md_Res,xtitle='Slice',ytitle='Medianed Offset' , $
            title='Debug Info: subtract_slice_bg_from_cube.pro'
         debug_info, 'DEBUG INFO (subtract_slice_bg_from_cube.pro): Medianed Median '+ $
                     strg(median(md_Res))
      endif else begin 

         !p.multi=[0,1,3]
         !p.charsize=1.5
         plot, md_Res[*,0],xtitle='Slice',ytitle='Fitted Offset' , $
            title='Debug Info: subtract_slice_bg_from_single_cube'
         plot, md_Res[*,1],xtitle='Slice',ytitle='Fitted X-Slope' 
         plot, md_Res[*,2],xtitle='Slice',ytitle='Fitted Y-Slope' 
         !p.multi=[0,1,0]
         debug_info, 'DEBUG INFO (subtract_slice_bg_from_cube.pro): Medianed X/Y/Offset '+ $
                     strg(median(md_Res[*,0]))+'/'+strg(median(md_Res[*,1]))+'/'+strg(median(md_Res[*,2]))

      end

   endif

   return, md_Res

end
