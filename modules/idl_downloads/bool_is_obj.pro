;-----------------------------------------------------------------------
; NAME:  bool_is_obj
;
; PURPOSE: Check if input is obj
;
; INPUT :  In     : single input header variable
;          /FOUND : searches for occurence of keyword ISOBJ in header
;         
; OUTPUT : if FOUND is set this routine returns OK if input contains ISOBJ, otherwise ERR_UNKNOWN.
;          if FOUND is not set this routine returns the value of ISOBJ
;             if this keyword is set exactly once.
;
; STATUS : untested
;
; HISTORY : 28.6.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION bool_is_obj, In, FOUND=FOUND

   COMMON APP_CONSTANTS

   n = 0
   retval = sxpar ( In, 'ISOBJ', count=n )

   if ( keyword_set ( FOUND ) ) then begin
      case n of 
         0    : return, error ('FAILURE (bool_is_obj.pro): ISOBJ keyword not found')
         1    : return, OK
         else : return, error ('FAILURE (bool_is_obj.pro): Multiple ISOBJ keywords in header')
      endcase
   endif else  begin
     if ( n ne 1 ) then $
        return, error ('FAILURE (bool_is_obj.pro): ISOBJ keyword not found or multiple definitions found') $
     else return, retval
   end

END 
