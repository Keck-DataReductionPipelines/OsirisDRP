;-----------------------------------------------------------------------
; NAME:  clip
;
; PURPOSE: this routine clips and returns a vector of same length as
;          the input with 1 where valid and 0 where clipped
;
; INPUT :  In        : pointer to input array
;          loReject  : percentage (0.-1.) of low value elements to be thrown away before 
;                      operating
;          hiReject  : percentage (0.-1.) of high value elements to be thrown away before 
;                      operating
;          INDEX=INDEX : returns a vector of indices where not clipped
;
; STATUS : untested
;
; HISTORY : 27.2.2005, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------


function clip, In, loReject, hiReject, INDEX=INDEX

    if ( loReject gt hiReject ) then begin
       warning, 'ERROR IN CALL (clip.pro): loReject gt hiReject. Continue without doing anything'
       return, indgen(n_elements(In))
    end

    if ( loReject gt 1. or hiReject gt 1. ) then begin
       warning, 'ERROR IN CALL (clip.pro): loReject or hiReject gt 1. Continue without doing anything.'
       return, indgen(n_elements(In))
    end

    if ( loReject lt 0. or hiReject lt 0. ) then begin
       warning, 'ERROR IN CALL (clip.pro): loReject or hiReject lt 0. Continue without doing anything.'
       return, indgen(n_elements(In))
    end

    vi_Index = sort( In )

    lo_n = long (loReject * float(n_elements(In)))
    hi_n = long (n_elements(In) - ( ( hiReject * float(n_elements(In)) + 1 ) <  n_elements(In) ) ) > 0

    vb_Clip = make_array(n_elements(In), VALUE=0, /INT)
    vb_Clip( vi_Index(lo_n:hi_n) ) = 1

    if ( keyword_set ( INDEX ) ) then $
       return, (indgen(n_elements(In)))(vi_Index(lo_n:hi_n)) $
    else $
       return, vb_Clip

end
