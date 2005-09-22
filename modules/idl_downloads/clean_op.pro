;-----------------------------------------------------------------------
; NAME:  clean_op
;
; PURPOSE: this routine computes the clean mean/std of a given data
;          array that means the array is first sorted and 
;          a given percentage of the lowest and the highest values
;          is not considered
;
; INPUT :  In        : pointer to input array
;          InQ       : pointer to input quality array
;          loReject  : percentage (0.-1.) of low value elements to be thrown away before 
;                      operating
;          hiReject  : percentage (0.-1.) of high value elements to be thrown away before 
;                      operating
;          cMode     : 'MEAN', 'STD'
;
; OUTPUT : the clean mean as a vector otherwise ERR_UNKNOWN
;
; STATUS : untested
;
; HISTORY : 27.2.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------


function clean_op, In, InQ, loReject, hiReject, cMode, SILENT=SILENT

    vb_Valid = where ( extbit ( InQ, 0 ), n_Valid )

    if ( n_Valid eq 0 ) then $
       if ( keyword_set ( SILENT ) ) then $
          return, error('ERROR (cleanmean.pro): No valid pixels.') $ 
       else return, 0.

    vd_In = (In(vb_Valid))(sort( In(vb_Valid) ))

    lo_n = long (loReject * float(n_Valid))
    hi_n = long (hiReject * float(n_Valid))

    If ( cMode eq 'MEAN' ) then return, [mean(vd_In(lo_n:hi_n))]
    If ( cMode eq 'STD' ) then begin
       if ( lo_n eq hi_n ) then return, [vd_In(lo_n:hi_n)] $
       else return, [stdev(vd_In(lo_n:hi_n))]
    end

end
