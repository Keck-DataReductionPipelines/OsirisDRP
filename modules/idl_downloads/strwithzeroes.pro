FUNCTION strwithzeroes, instring, length, position
  ; instring    Input string which will have prepended or appended zeroes
  ; length      The final length of the output (must be >= STRLEN(instring))
  ; position    Append or prepend.  Integer >= 0 == Append, < 0 == Prepend
  IF length GE STRLEN(instring) THEN BEGIN
    zs = ''
    FOR i = 1, length DO BEGIN
      zs = zs + '0'
    ENDFOR
    IF position GE 0 THEN BEGIN
      outVal = instring + zs
      outVal = STRMID(outVal, 0, length)
    ENDIF ELSE BEGIN
      outVal = zs + instring
      outVal = STRMID(outVal, STRLEN(outVal)-length, length)
    ENDELSE
  ENDIF ELSE BEGIN
    outVal = instring
  ENDELSE
  RETURN, outVal
END
