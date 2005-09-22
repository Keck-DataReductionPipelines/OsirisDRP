;-----------------------------------------------------------------
function extbit,input,pos
; extract <pos> bit of <input> variable.
; <pos> starts from 0 increasing to left
; 
; Since IDL (as of V6.0) does not support bit-field access of
; variable, return value will be a BYTE (instead of BIT) array of
; the same dimension as the input variable.
;
; e.g., to extract the 6th bit of input
; bit6 = extbit(input,6)
;
; Inseok Song (2004)
;-----------------------------------------------------------------
    isize = size(input)
    if (isize[0] EQ 0) then begin
       extbit = BYTE('0'x)  ; define a scalar byte variable for output
    endif else begin
       CASE isize[0] OF
          1: extbit = make_array(isize[1],/BYTE,value='0'x)
          2: extbit = make_array(isize[1],isize[2],/BYTE,value='0'x)
          3: extbit = make_array(isize[1],isize[2],isize[3],/BYTE,value='0'x)
       ELSE: STOP,"<extbit> routine currently only supports upto 3 dimension."
       ENDCASE
    endelse
    extbit = ISHFT(input AND ISHFT(BYTE('1'x),pos),-pos)
    return,extbit
end
