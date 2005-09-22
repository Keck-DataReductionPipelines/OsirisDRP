;-----------------------------------------------------------------------------
; NAME:  qbit_translate
;
; PURPOSE: translate the quality frame from the new definition to the
;          old one
;
; INPUT : mb_Q      : quality frame or cube
;         [rev=rev] : reverse transformation, from old to new
;
; ALGORITHM :
;
; old definition
;     (Assumed): . . 0 0 = bad pixel (weight should be zero)
;                . . 0 1 = interpolated (noise needs to be escalated by a factor of 5)
;                . . 1 0 = interpolated good pixels (noise to be increased by 2 times)
;                . . 1 1 = Good pixel

; new definition
;                . 0 0 0 = bad pixel
;                . 0 0 1 = good pixel, not interpolated
;                . 1 1 1 = good pixel interpolated, good interpolated
;                . 0 1 1 = good pixel interpolated, not good interpolated
;
; STATUS : untested
;
; HISTORY : 8.8.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------------

pro qbit_translate, mb_Q, rev=rev

   n_Pix = size(mb_Q, /N_ELEMENTS)

   if ( keyword_set(rev) ) then begin

      for i=0, n_Pix-1 do begin

         b_Bit0 = extbit (mb_Q(i),0)  ; Quality bit
         b_Bit1 = extbit (mb_Q(i),1)  ; Interpolation bit
         b_Bit2 = extbit (mb_Q(i),2)  ; Interpolation quality bit

         ; the pixel is bad
         if ( b_Bit0 eq 0 ) then begin
            setbit (mb_Q(i),0,0)
            setbit (mb_Q(i),1,0)
         end

         ; the pixel is good and not interpolated
         if ( b_Bit0 eq 1 and b_Bit1 eq 0 ) then begin
            setbit (mb_Q(i),0,1)
            setbit (mb_Q(i),1,1)
         end

         ; the pixel is good and good interpolated
         if ( b_Bit0 eq 1 and b_Bit1 eq 1 and b_Bit2 eq 1 ) then begin
            setbit (mb_Q(i),0,0)
            setbit (mb_Q(i),1,1)
         end

         ; the pixel is good but badly interpolated
         if ( b_Bit0 eq 1 and b_Bit1 eq 1 and b_Bit2 eq 0 ) then begin
            setbit (mb_Q(i),0,1)
            setbit (mb_Q(i),1,0)
         end

      end

  endif else begin

      for i=0, n_Pix-1 do begin

         b_Bit0 = extbit (mb_Q(i),0)
         b_Bit1 = extbit (mb_Q(i),1)

         ; the pixel is bad
         if ( b_Bit0 eq 0 and b_Bit1 eq 0 ) then begin
            setbit (mb_Q(i),0,0)
         end

         ; the pixel is good and not interpolated
         if ( b_Bit0 eq 1 and b_Bit1 eq 1 ) then begin
            setbit (mb_Q(i),0,1)
            setbit (mb_Q(i),1,0)
         end

         ; the pixel is good and good interpolated
         if ( b_Bit0 eq 0 and b_Bit1 eq 1 ) then begin
            setbit (mb_Q(i),0,1)
            setbit (mb_Q(i),1,1)
            setbit (mb_Q(i),2,1)
         end

         ; the pixel is good but badly interpolated
         if ( b_Bit0 eq 1 and b_Bit1 eq 0 ) then begin
            setbit (mb_Q(i),0,1)
            setbit (mb_Q(i),1,1)
            setbit (mb_Q(i),2,0)
         end

      end

  end

end
