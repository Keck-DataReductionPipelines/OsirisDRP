;-----------------------------------------------------------------------
; NAME:  clean
;
; PURPOSE: this routine cleans the input.
;
; INPUT :  In         : input array/cube
;          loReject   : percentage (0.-1.) of low value elements to be thrown away 
;          hiReject   : percentage (0.-1.) of high value elements to be
;                       thrown away 
;          [/EXTRACT] : returns the non-clipped values in ascending order
;
; OUTPUT : bool-array of same format as In with 0 where clipped and 1
;          where not if keyword EXTRACT is not set
;          or
;          values of In which not been clipped in ascending order. 
;
; EXAMPLE : hhh = clean ( In, 0.1, 0.1 )   ; throws away th 10%
;                                          ; highest and 10% lowest values
;
; ON ERROR : returns 0.
;
; STATUS : untested
;
; HISTORY : 27.2.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------


function clean, In, loReject, hiReject, EXTRACT=EXTRACT

    if ( loReject lt 0. or loReject gt 1. or hiReject lt 0. or hiReject gt 1. or loReject gt hiReject ) then $ 
       return, error ('ERROR IN CALL (clean.pro): loReject or hiReject has wrong limit.')

    if ( n_elements ( In ) le 1 ) then $
       return, error ('ERROR IN CALL (clean.pro): Input must not be a scalar.')

    n_Dims = size(In)
    mb_Out = make_array(/BYTE,SIZE=n_Dims)

    vi_Ind = sort( In )
    vd_In  = (In)(vi_Ind)
 
    n = n_elements(In)

    lo_n = long (loReject * n)
    hi_n = n - long (hiReject * n) - 1

    if ( lo_n gt hi_n ) then return, 0. 

    if ( keyword_set ( EXTRACT ) ) then $
       return, [vd_In(lo_n:hi_n)] $
    else begin
       mb_Out(vi_Ind(lo_n:hi_n)) = 1
       return, mb_Out
    end

end
