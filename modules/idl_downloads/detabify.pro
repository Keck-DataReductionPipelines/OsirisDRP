	FUNCTION DETABIFY, CHAR_STR
;+
; Project     : SOHO - CDS
;
; Name        : 
;	DETABIFY()
; Purpose     : 
;	Converts tabs to spaces in character strings.
; Explanation : 
;	Replaces tabs in character strings with the appropriate number of
;	spaces.  The number of space characters inserted is calculated to space
;	out to the next effective tab stop, each of which is eight characters
;	apart.
; Use         : 
;	Result = DETABIFY(CHAR_STR)
; Inputs      : 
;	CHAR_STR = Character string variable (or array) to remove tabs from.
; Opt. Inputs : 
;	None.
; Outputs     : 
;	Result of function is CHAR_STR with tabs replaced by spaces.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	None.
; Calls       : 
;	None.
; Common      : 
;	None.
; Restrictions: 
;	CHAR_STR must be a character string variable.
; Side effects: 
;	None.
; Category    : 
;	Utilities, Strings.
; Prev. Hist. : 
;	William Thompson, Feb. 1992.
; Written     : 
;	William Thompson, GSFC, February 1992.
; Modified    : 
;	Version 1, William Thompson, GSFC, 12 April 1993.
;		Incorporated into CDS library.
; Version     : 
;	Version 1, 12 April 1993.
;-
;
	ON_ERROR, 2
;
;  Check the number of parameters.
;
	IF N_PARAMS() NE 1 THEN MESSAGE,'Syntax:  Result = DETABIFY(CHAR_STR)'
;
;  Make sure CHAR_STR is of type string.
;
	SZ = SIZE(CHAR_STR)
	IF SZ(SZ(0)+1) NE 7 THEN BEGIN
		MESSAGE,/INFORMATIONAL,'CHAR_STR must be of type string'
		RETURN, CHAR_STR
	ENDIF
;
;  Step through each element of CHAR_STR.
;
	STR = CHAR_STR
	FOR I = 0,N_ELEMENTS(STR)-1 DO BEGIN
;
;  Keep looking for tabs until there aren't any more.
;
		REPEAT BEGIN
			TAB = STRPOS(STR(I),STRING(9B))
			IF TAB GE 0 THEN BEGIN
				NBLANK = 8 - (TAB MOD 8)
				STR(I) = STRMID(STR(I),0,TAB) +		$
					STRING(REPLICATE(32B,NBLANK)) +	$
					STRMID(STR(I),TAB+1,STRLEN(STR(I))-TAB-1)
			ENDIF
		ENDREP UNTIL TAB LT 0
	ENDFOR
;
	RETURN, STR
	END
