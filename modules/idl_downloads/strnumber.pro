function strnumber, st, val, hex = hexflg, NaN = nan
;+
; NAME:
;      STRNUMBER()
; PURPOSE:
;      Function to determine if a string is a valid numeric value.
;
; EXPLANATION:
;      A string is considered a valid numeric value if IDL can convert it
;      to a numeric variable without error.    
; CALLING SEQUENCE:
;      result = strnumber( st, [val, /HEX] )
;
; INPUTS:
;      st - any IDL scalar string
;
; OUTPUTS:
;      1 is returned as the function value if the string st has a
;      valid numeric value, otherwise, 0 is returned.
;
; OPTIONAL OUTPUT:
;      val - (optional) value of the string.  real*8
;
; OPTIONAL INPUT KEYWORD:
;       /HEX - If present and nonzero, the string is treated as a hexadecimal
;             longword integer.
;       /NAN - if set, then the value of an empty string is returned as NaN,
;              by default the returned value is 0.0d.     In either case,
;              an empty string is considered a valid numeric value.
;
; EXAMPLES:
;      IDL> res = strnumber('0.2d', val)
;           returns res=1 (a valid number), and val = 0.2000d
;              
; NOTES:
;      (1) STRNUMBER was modified in August 2006 so that an empty string is 
;      considered a valid number.   Earlier versions of strnumber.pro did not 
;      do this because in very early (pre-V4.0) versions of IDL
;      this could corrupt the IDL session.
;
;       (2) STRNUMBER will return a string such as '23.45uyrg' as a valid 
;      number (=23.45) since this is how IDL performs the type conversion.  If
;      you want a stricter definition of valid number then use the VALID_NUM
;      function.
; HISTORY:
;      version 1  By D. Lindler Aug. 1987
;      test for empty string, W. Landsman          February, 1993
;      Converted to IDL V5.0   W. Landsman   September 1997
;      Hex keyword added.  MRG, RITSS, 15 March 2000.
;      An empty string is a valid number   W. Landsman    August 2006
;      Added /NAN keyword  W. Landsman August 2006
;-
 if N_params() EQ 0 then begin
      print,'Syntax - result = strnumber( st, [val, /HEX, /NAN] )'
      return, 0
 endif

 newstr = strtrim( st )
 if keyword_set(NAN) then if newstr EQ '' then begin
        val = !VALUES.D_NAN
	return, 1
  endif 	

 On_IOerror, L1                 ;Go to L1 if conversion error occurs

  If (NOT keyword_set(hexflg)) Then Begin
   val = double( newstr )
 EndIf Else Begin
   val = 0L
   reads, newstr, val, Format="(Z)"
 EndElse

 return, 1                      ;No conversion error

 L1: return, 0                  ;Conversion error occured

 end
 
