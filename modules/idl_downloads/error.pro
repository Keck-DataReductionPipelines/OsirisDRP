;-----------------------------------------------------------------------
; NAME:  error
;
; PURPOSE: Prints a error message to stdou and the logfile, 
;          increases the error_status and returns ERR_UNKNOWN
;
; INPUT :  mess  : error message
;
; STATUS : untested
;
; HISTORY : 27.2.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION error, mess, error_status

   COMMON APP_CONSTANTS

;   mess(0) = '!!!   ' + mess(0)
   m = size(mess,/N_ELEMENTS)
   for i=0, m-1 do print, '!!!   ' + mess(i)
   if (n_params() eq 2) then error_status = error_status + 1
   drpLog, strjoin(mess), /DRF, DEPTH = 1

   return, ERR_UNKNOWN

END 
