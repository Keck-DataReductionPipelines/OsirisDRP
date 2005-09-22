;-----------------------------------------------------------------------
; NAME:  Info
;
; PURPOSE: Prints an information message to screen and logbook
;
; INPUT :  mess  : message
;
; STATUS : untested
;
; HISTORY : 27.2.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

pro info, mess

;   mess(0) = '!!!   ' + mess(0)
   n = size(mess)
   if ( n(0) eq 0 ) then m=1 else m=n(1)
   for i=0, m-1 do print, '!!!   ' + mess(i)
   drpLog, strjoin(mess), /DRF, DEPTH = 1

END 
