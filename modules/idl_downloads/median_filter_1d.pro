;-----------------------------------------------------------------------
; NAME:  median_filter_1d
;
; PURPOSE: median filter
;
; INPUT :  v       : input variable
;          width   : halfwidth of filter window
;
; OUTPUT : medianed vector
;
; STATUS : tested
;
; HISTORY : 22.5.2005, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

function median_filter_1d, v, width

   n = n_elements(v)-1

   if ( width gt n+1 ) then begin
      print, 'ERROR (median_filter_1d.pro): Width gt array length. Returning original vector.'
      return, v
   end

   mv = dblarr(n+1)

   for i = 0, n do begin

      li = (i - width) > 0
      ui = (i + width) < n

      mv(i) = median( v(li:ui) )
   end

   return, mv

end
