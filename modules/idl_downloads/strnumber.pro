function strnumber, st, val, hex = hexflg
;+
; NAME:
;      STRNUMBER
; PURPOSE:
;      Function to determine if a string is a valid numeric value.
;
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
;
; EXAMPLES:
;      IDL> res = strnumber(' ',val)
;           returns res=0 (not a number) and val is undefined
;
;      IDL> res = strnumber('0.2d', val)
;           returns res=1 (a valid number), and val = 0.2000d
;              
; NOTES:
;      (1) STRNUMBER was modified in February 1993 to include a special test for 
;      empty or null strings, which now returns a 0 (not a number).    Without
;      this special test, it was found that a empty string (' ') could corrupt
;      the stack.
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
;-
 if N_params() EQ 0 then begin
      print,'Syntax - result = strnumber( st, [val, /HEX] )'
      return, 0
 endif

 newstr = strtrim( st )

 if ( newstr EQ '' ) then return, 0    ;Empty string is a special case

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
