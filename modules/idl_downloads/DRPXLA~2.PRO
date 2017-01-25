FUNCTION drpXlateFileName, input

	; Returns the translated name of the file string by expanding any
	; environment variables in the input string.
	; E.g., if $HOME=/Users/tgasaway then $HOME/code/backbone should be
	; translated as /Users/tgasaway/code/backbone
	; If any presumed environment variables do not translate, or if there
	; are no environment variables, then the function returns the original
	; input string.

	; Split the input string into parts
	inSplit = STRSPLIT(input, '[$,/]', /EXTRACT, /REGEX)

	ReturnOriginal = 0	; Assume that we won't have to return the original
				; because of errors

	; Translate all of the environment variables that we find.
	FOR i = 0, (N_ELEMENTS(inSplit)-1) DO BEGIN
		IF STRPOS(input, '$'+inSplit[i]) NE -1 THEN BEGIN
		; We have an environment variable embedded in the input string so
		; replace the string with it's translation.
			temp = GETENV(STRUPCASE(inSplit[i]))
			IF temp NE '' THEN BEGIN
				inSplit[i] = temp
			ENDIF ELSE BEGIN
				ReturnOriginal = 1	; We failed translate an environment variable
							; so set the error return
			ENDELSE
		ENDIF
	ENDFOR

	IF ReturnOriginal NE 1 THEN BEGIN
		; Now that we have translated everything we can, reassemble the string correctly
		output = ''
		; Prepend '/' if one began the input string
		IF STRPOS(input, '/') EQ 0 THEN BEGIN
			output = '/'
		ENDIF
		i = 0
		IF N_ELEMENTS(inSplit)-2 GE 0 THEN BEGIN
			FOR i = 0, (N_ELEMENTS(inSplit)-2) DO BEGIN
				output = output + inSplit[i]
				output = output + '/'
			ENDFOR
		ENDIF
		output = output + inSplit[i]	; Do case for i == N_ELEMENTS(inSplit)-1
		; Append final'/' if one ended the input string
		IF STRPOS(input, '/', /REVERSE_SEARCH) EQ STRLEN(input)-1 THEN BEGIN
			output = output + '/'
		ENDIF
	ENDIF ELSE BEGIN
		output = input
	ENDELSE

	RETURN, output
END
