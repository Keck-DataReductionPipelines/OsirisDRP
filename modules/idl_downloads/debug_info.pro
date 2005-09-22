;-----------------------------------------------------------------------
; NAME:  debug_info
;
; PURPOSE: prints debugging info
;
; INPUT :  mess : debugging message
;
; STATUS : not tested
;
; HISTORY : 5.3.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------


pro debug_info, mess

;   mess(0) = '!!!   ' + mess(0)
   n = size(mess)
   if ( n(0) eq 0 ) then m=1 else m=n(1)
   for i=0, m-1 do print, '!!!   ' + mess(i)
;   drpLog, strjoin(mess), /DRF, DEPTH = 1

end
