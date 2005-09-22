;-----------------------------------------------------------------------
; NAME:  verify_naxis
;
; PURPOSE: Check if the dimensions specified by the NAXIS keywords in
;          the header is compliant with the dimensions of the data
;
; INPUT :  p_P      : input pointer array 
;          nFrames  : number of input pointers to check
;
; NOTES : Checks for NAXIS first. Then for NAXISi
;
; STATUS : untested
;
; HISTORY : 27.2.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------
function verify_naxis, p_P, p_H, UPDATE=UPDATE

    COMMON APP_CONSTANTS

    functionName = 'verify_naxis'

    v_Size  = size(*p_P)

    for j=0, v_Size(0) do begin

       s_Naxis = 'NAXIS'+((j eq 0)?'':strg(j))

       n_Naxis = sxpar(*p_H, s_Naxis, count=n)
       if ( n ne 1 ) then $
          return, error('FAILURE ('+strg(functionName)+'): '+strg(s_Naxis)+ $
                        ' keyword in header not or multiply defined.')

       if ( v_Size(j) ne n_Naxis ) then begin

          if ( keyword_set ( UPDATE ) ) then begin
             sxaddpar, *p_H, s_Naxis, v_Size(j)   ; the keyword must already be defined
             info, 'INFO (verify_naxis): Updating '+strg(s_Naxis)+'.'
          endif else $
             return, error('FAILURE ('+strg(functionName)+'): '+strg(s_Naxis)+ $
                           ' keyword in header ('+strg(v_Size(j))+') incompatible with dimensionality of data array (' + $
                           strg(n_Naxis)+').')

       end

    end

    return, OK

end
  
