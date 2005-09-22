;-----------------------------------------------------------------------
; NAME:  warning
;
; PURPOSE: Prints a warning message
;
; INPUT :  mess  : warning message
;
; STATUS : untested
;
; HISTORY : 27.2.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

pro warning, mess

   n = size(mess)
   if ( n(0) eq 0 ) then m=1 else m=n(1)
   for i=0, m-1 do print, '!!!   ' + mess(i)
   drpLog, strjoin(mess), /DRF, DEPTH = 1

END 
