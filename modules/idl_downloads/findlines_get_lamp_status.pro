;-----------------------------------------------------------------------
; NAME:  findlines_get_lamp_status
;
; PURPOSE: get the lamp status
;
; INPUT :  p_Headers   : pointer or pointer array with headers
;          nFrames     : number of valid headers in p_Headers
;
; OUTPUT : a vector with names of lamps that are switched on
;
; ON ERROR : returns 0
;
; STATUS : untested
;
; HISTORY : 28.9.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

function findlines_get_lamp_status, p_Headers, nFrames

    ; status of the ar kr ne xe lamp, 1 is on 0 is off
    vs_LampAcro = ['AR', 'KR', 'NE', 'XE']   ; must be uppercase
    ; names of the fits keywords describing the lamp status
    vs_LampKey  = ["Ar_On", "Kr_On", "Ne_On", "Xe_On"] 
    vb_LampOn   = [0,0,0,0]

    ; some internal checks
    if ( n_elements(vs_LampAcro) ne n_elements(vs_LampKey) ) then $
       return, error('FATAL ERROR (get_my_linelist.pro): Internal error.')

    for i=0, nFrames-1 do begin
       for j=0, n_elements(vs_LampKey)-1 do begin
          b_Lamp = SXPAR(*p_Headers[i], vs_LampKey(j), /SILENT, count=ncount)
          if ( ncount ne 1 ) then $
             warning, 'ERROR IN CALL (get_lamp_status.pro): keyword '+strg(vs_LampKey(i))+' defined '+ $
                strg(ncount)+ ' times in header '+strg(i)+'. Ignoring.' $
          else $
             if ( b_Lamp eq 1 ) then $
                vb_LampOn(j) = 1
       end
    end

    vi_Mask = where (vb_LampOn eq 1, n)

    if ( n eq 0 ) then $
       return, 0 $
    else $
       return, vs_LampAcro(vi_Mask)

end
