FUNCTION mkrecmatrx_000, DataSet, Modules, Backbone

	COMMON APP_CONSTANTS

	functionName = 'mkrecmatrx_000'

	drpLog, 'Module: ' + functionName + ' - Received data set: ' + DataSet.Name, /GENERAL, /DRF, DEPTH = 1

	; Get all COMMON parameter values
	weight_limit = FLOAT(drpParamValue('mkrecmatrx_COMMON___weight_limit'))
	slice = FIX(drpParamValue('mkrecmatrx_COMMON___slice'))
	shift = FIX(drpParamValue('mkrecmatrx_COMMON___shift'))

        print, 'WEIGHT_LIMIT = ', weight_limit
        print, 'SLICE        = ', slice
        print, 'SHIFT        = ', shift

	BranchID = Backbone->getType()
	CASE BranchID OF
		'CRP_SPEC':	BEGIN
			; Get some parameters from the first header.  These will be used to control
			; the construction of the rectification matrix (influence function) as well
			; build the output file name.

			; Get the dataset info from the first of the frame headers.
			; Parse the keyword SFILTER to determine if the scans are BroadBand or NarrowBand.
			; This parameter will also be used as part of the influence function file name.
			filename = STRTRIM(SXPAR(*DataSet.Headers[0], "DATAFILE", /SILENT), 2)
			sfilter = STRTRIM(SXPAR(*DataSet.Headers[0], "SFILTER", /SILENT), 2)
			sscale = FLOAT(SXPAR(*DataSet.Headers[0], "SSCALE", /SILENT))
      outDirname = drpXlateFileName(Modules[drpModuleIndexFromCallSequence(Modules, functionName)].OutputDir)
			PRINT, 'mkrecmatrx_000: DataSet.ValidFrameCount  = ' + strg(DataSet.ValidFrameCount)
			PRINT, 'outDirname  = ' + outDirname
			outFilename = STRMID(filename, 0, 12)
			outFilename = outFilename + '_' + '__infl'
			outFilename = outFilename + '_' + sfilter
			outFilename = outFilename + '_' + STRMID(STRTRIM(STRING(sscale), 2), 2, 3)
			outFilename = outFilename + '.fits'
			PRINT, 'outFilename = ' + outFilename

			; First, construct the execution string that implements references to the available
			; parameters.  Start with a base string then add the code module name followed by the
			; parameters.  As a parameter is added, increment the total parameter count.
			; Initialize the execution string and the parameter count.
			execString = "retval = CALL_EXTERNAL(EXTERNAL_CODE_FILENAME"
			totalParmCount = 0
			; Add the C code module name which is NOT a prameter.
			execString = execString + ", 'mkrecmatrx_000'"
			; Add parameters to the execution string and increment the total parameter count
			totalParmCount = totalParmCount + drpAddParmToCallSequence(execString, 'totalParmCount')
			totalParmCount = totalParmCount + drpAddParmToCallSequence(execString, 'weight_limit')
			totalParmCount = totalParmCount + drpAddParmToCallSequence(execString, 'slice')
			totalParmCount = totalParmCount + drpAddParmToCallSequence(execString, 'shift')
			thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
			totalParmCount = totalParmCount + drpAddParmToCallSequence(execString, 'Modules[thisModuleIndex]')
			totalParmCount = totalParmCount + drpAddParmToCallSequence(execString, 'DataSet')
			totalParmCount = totalParmCount + drpAddParmToCallSequence(execString, 'outDirname')
			totalParmCount = totalParmCount + drpAddParmToCallSequence(execString, 'outFilename')
			totalParmCount = totalParmCount + drpAddParmToCallSequence(execString, 'sfilter')
			frameCount = DataSet.ValidFrameCount
			totalParmCount = totalParmCount + drpAddParmToCallSequence(execString, 'frameCount')

			FOR i = 0, frameCount-1 DO BEGIN
				totalParmCount = totalParmCount + drpAddParmToCallSequence(execString, '(*DataSet.Frames[' + STRTRIM(STRING(i), 2) + '])')
				totalParmCount = totalParmCount + drpAddParmToCallSequence(execString, '(*DataSet.Headers[' + STRTRIM(STRING(i), 2) + '])')
				totalParmCount = totalParmCount + drpAddParmToCallSequence(execString, '(*DataSet.IntFrames[' + STRTRIM(STRING(i), 2) + '])')
				totalParmCount = totalParmCount + drpAddParmToCallSequence(execString, '(*DataSet.IntAuxFrames[' + STRTRIM(STRING(i), 2) + '])')
			ENDFOR
			; Close the call with a parenthesis
			execString = execString + ')'

			PRINT, "mkrecmatrx_000.pro: totalParmCount = " + STRTRIM(STRING(totalParmCount), 2)
			;PRINT, "mkrecmatrx_000.pro: execString = " + execString

			; Call the C procedure
PRINT, "calling C code..."
			retVal = 0
			execReturn = EXECUTE(execString)
PRINT, "returned from calling C code..."
			IF (retval EQ 0) THEN BEGIN
				PRINT, "mkrecmatrx_000 C code returned 0"
			ENDIF ELSE BEGIN
				drpLog, 'FUNCTION '+ functionName + ': C code returned non-zero value == ' + STRTRIM(STRING(retval), 2), /DRF, DEPTH = 2
				PRINT, "ERROR: mkrecmatrx_000 C code returned non-zero value == " + STRTRIM(STRING(retval), 2)
				RETURN, ERR_CMODULE
			ENDELSE
		END  ; CASE 'CRP_SPEC'
		ELSE:	BEGIN
			drpLog, 'FUNCTION '+ functionName + ': CASE error: Bad Type = ' + BranchID, /DRF, DEPTH = 2
			RETURN, ERR_BADCASE
		END  ; CASE BadType
	ENDCASE

	RETURN, 0

END
