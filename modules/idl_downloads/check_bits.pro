
;-----------------------------------------------------------------------
; NAME:  check_bits
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
;              - interpolation bits are deleted
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

pro check_bits, pcf_Frame, pcf_IntFrame, pcb_IntAuxFrame, n_Sets, DEBUG=DEBUG

   functionName = 'check_bits.pro'

   for i=0, n_Sets-1 do begin

      ; invalid pixel = data or noise not finite or noise lt 0. or outside
      v_Mask1_ = finite ( *pcf_Frame(i) ) eq 0
      v_Mask2_ = finite ( *pcf_IntFrame(i) ) eq 0
      v_Mask3_ = *pcf_IntFrame(i) lt 0.
      v_Mask4_ = extbit ( *pcb_IntAuxFrame(i), 3 ) eq 0

      v_Mask1 = where ( v_Mask1_, n_Mask1 )
      v_Mask2 = where ( v_Mask2_, n_Mask2 )
      v_Mask3 = where ( v_Mask3_, n_Mask3 )
      v_Mask4 = where ( v_Mask4_, n_Mask4 )

      v_Mask = where ( v_Mask1_ or v_Mask2_ or v_Mask3_ or v_Mask4_, n_Mask )

      if ( n_Mask1+n_Mask2+n_Mask3+n_Mask4 gt 0 ) then begin

         if ( keyword_set ( DEBUG ) and n_Mask1 gt 0 ) then $
            debug_info, 'DEBUG INFO (' + functionName + '): Updating ' + strg(n_Mask1) + ' not finite data pixel. (This implies an error)'
         if ( keyword_set ( DEBUG ) and n_Mask2 gt 0 ) then $
            debug_info, 'DEBUG INFO (' + functionName + '): Updating ' + strg(n_Mask2) + ' not finite noise pixel. (This implies an error)'
         if ( keyword_set ( DEBUG ) and n_Mask3 gt 0 ) then $
            debug_info, 'DEBUG INFO (' + functionName + '): Updating ' + strg(n_Mask3) + ' negative noise pixel. (This implies an error)'
         if ( keyword_set ( DEBUG ) and n_Mask4 gt 0 ) then $
            debug_info, 'DEBUG INFO (' + functionName + '): Updating ' + strg(n_Mask4) + ' outside pixel. (This is not an error message)'

         ; set qbit 0,1 and 2 of invalid pixel to 0
         (*pcb_IntAuxFrame(i))( v_Mask ) = setbit ( (*pcb_IntAuxFrame(i))( v_Mask ), 0, 0 )
         (*pcb_IntAuxFrame(i))( v_Mask ) = setbit ( (*pcb_IntAuxFrame(i))( v_Mask ), 1, 0 )
         (*pcb_IntAuxFrame(i))( v_Mask ) = setbit ( (*pcb_IntAuxFrame(i))( v_Mask ), 2, 0 )

         ; set data and noise of invalid pixel to 0.
         (*pcf_Frame(i))( v_Mask ) = 0.
         (*pcf_IntFrame(i))( v_Mask ) = 0.

      endif 
      

      ; check the interpolation bits  (Bit 1 : interpolation status, bit 2 : good(1)/bad(0) )
      ; if qbit 2 is 1 qbit 1 must be 1 as well 
      v_Mask  = where ( extbit( *pcb_IntAuxFrame(i), 2 ) and extbit( *pcb_IntAuxFrame(i), 1 ) eq 0, n )
      if ( n gt 0 ) then begin
         if ( keyword_set ( DEBUG ) ) then $
            debug_info, 'DEBUG INFO (' + functionName + '): ' + strg(n) + $
               ' pixel have strange interpolation status. Correcting.'
         (*pcb_IntAuxFrame(i))( v_Mask ) = setbit ( (*pcb_IntAuxFrame(i))( v_Mask ), 1, 1)
      end

      ; Ensure that outside pixel are invalid
      v_Mask = where ( extbit ( *pcb_IntAuxFrame(i), 3 ) eq 0 and extbit ( *pcb_IntAuxFrame(i), 0 ), n )
      if ( n gt 0 ) then begin
         if ( keyword_set ( DEBUG ) ) then $
            debug_info, 'DEBUG INFO (' + functionName + '): ' + strg(n) + ' pixels ' + $
                  ' in set ' + strg(i) + ' have outside status but are valid. Correcting.'
         (*pcb_IntAuxFrame(i))( v_Mask ) = setbit ( (*pcb_IntAuxFrame(i))( v_Mask ), 0, 0 )
         (*pcf_Frame(i))( v_Mask )       = 0.
         (*pcf_IntFrame(i))( v_Mask )    = 0.
      end

   end

end
