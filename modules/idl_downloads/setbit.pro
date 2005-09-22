;-----------------------------------------------------------------
function setbit,input,pos,value
; set <pos> bit of <input> to value <value>
; <pos> starts from 0 increasing to left
;
; e.g., to set 6th bit of input to '1'
; setbit,input,6,1
;
; INPUT variable can be an array or scalar.
; 
; Inseok Song (2004)
;-----------------------------------------------------------------
    setbit = value ? (input OR  ISHFT(BYTE('1'X),pos)) $     ; set to '1' 
                   : (input AND NOT ISHFT(BYTE('1'x),pos))   ; set to '0' 
    return,setbit
end
