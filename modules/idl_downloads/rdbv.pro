PRO rdbv

	; Read in the Calibration file that will contain:
	;	BASESIZE	Keyword
	;	hilo		short int array[NUMSPEC][2]
	;	effective	short int array[NUMSPEC]
	;	basis_vectors	float array[NUMSPEC][MAXSLICE][DATA]
	FileName = "S030604_c001__infl_Hbb_050.fits"
	pHilo = PTR_NEW(/ALLOCATE_HEAP)
	*pHilo = FIX(READFITS(drpXlateFileName('$TESTOUTPUTDIR' + '/' + FileName), Header, /SILENT))
	HELP, *pHilo
	basesize = FIX(SXPAR(Header, "BASESIZE", /SILENT))
	HELP, basesize
	PRINT, "BASESIZE = " + STRTRIM(STRING(basesize), 2)
	pEffective = PTR_NEW(/ALLOCATE_HEAP)
	*pEffective = FIX(READFITS(drpXlateFileName('$TESTOUTPUTDIR' + '/' + FileName), Header, EXTEN_NO=1, /SILENT))
	HELP, *pEffective
	pBasis_Vectors = PTR_NEW(/ALLOCATE_HEAP)
	*pBasis_Vectors = READFITS(drpXlateFileName('$TESTOUTPUTDIR' + '/' + FileName), Header, EXTEN_NO=2, /SILENT)
	HELP, *pBasis_Vectors

END

