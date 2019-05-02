; +
; NAME: osiris_calc_pa
;
; PURPOSE: 
;
; CALLING SEQUENCE: osiris_calc_pa, header
;
; INPUTS:
;
; OPTIONAL INPUTS: 
;                  
; OPTIONAL KEYWORD INPUTS: 
;
; EXAMPLE:
;
; NOTES:
;
; PROCEDURES USED:
;
; REVISION HISTORY: 06JUN2006 - MWM: added this header
; -

function osiris_calc_pa, hd

; extract pa from header
rotposn=sxpar(hd, 'ROTPOSN')
instangl=sxpar(hd, 'INSTANGL')
instr=strtrim(sxpar(hd, 'INSTR'),2)
tel=strtrim(sxpar(hd, 'TELESCOP'),2)

if !ERR eq -1 then begin
    pa=[-1,-1]
endif else begin
    if ( tel eq 'Keck I' ) then begin
        iangle = 42.5
    endif else begin
        iangle = 47.5
    endelse
    case instr of
        'spec': begin
            north=rotposn-instangl
            east=north-90
            pa=[north,east]
        end
        'imag': begin
            north=iangle+rotposn-instangl
            east=north-90
            pa=[north,east]
        end
        else: begin
            pa=[-1,-1]
        end
    endcase
endelse
print, 'Position Angle: ', pa[0]
return, pa

end
