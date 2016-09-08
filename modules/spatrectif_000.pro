FUNCTION spatrectif_000, DataSet, Modules, Backbone

COMMON APP_CONSTANTS

;drpMemoryMark, 'Entering spatrectif_000.pro...'

functionName = 'spatrectif_000'

drpLog, 'Module: ' + functionName + ' - Received data set: ' + DataSet.Name, /GENERAL, /DRF, DEPTH = 1

                                ; Get all COMMON parameter values
relaxation = FLOAT(drpParamValue('spatrectif_COMMON___relaxation'))

BranchID = Backbone->getType()
CASE BranchID OF
    'ARP_SPEC':	BEGIN
                                ; Get reduction type specific parameters
        numiter = FIX(drpParamValue('spatrectif_ARP_SPEC_numiter'))
    END                         ; CASE 'ARP_SPEC'
    'SRP_SPEC':	BEGIN
    END                         ; CASE 'SRP_SPEC'
    'ORP_SPEC':	BEGIN
                                ; Get reduction type specific parameters
        numiter = FIX(drpParamValue('spatrectif_ORP_SPEC_numiter'))
    END                         ; CASE 'ORP_SPEC'
    ELSE:	BEGIN
        drpLog, 'FUNCTION '+ functionName + ': CASE error: Bad Type = ' + BranchID, /DRF, DEPTH = 2
        RETURN, ERR_BADCASE
    END                         ; CASE BadType
ENDCASE
           ; Now perform the common code execution for spatial rectification
           ; Read in the Calibration file that will contain:
           ;	BASESIZE	Keyword
           ;	hilo		short int array[NUMSPEC][2]                  -- The row index of the bottom (low) and the top (high) raw for each spectral slice.
           ;	effective	short int array[NUMSPEC]                     -- A flag to indicate whether this spaxel is sufficiently illuminated (0=bad, 1=good)
           ;	basis_vectors	float array[NUMSPEC][MAXSLICE][DATAFRAMEDIM] -- The actual influence matrix.
           ;	Note NUMSPEC = typically 1216 spectra
           ;	Note MAXSLICE = 16 (default) but up to 32 (height of slice, orthogonal to dispersion direction)
           ;	Note DATAFRAMEDIM = 2048 (width of slice in dispersion direction)
thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
FileName = drpXlateFileName(Modules[thisModuleIndex].CalibrationFile)
pHilo = PTR_NEW(/ALLOCATE_HEAP)
*pHilo = FIX(READFITS(FileName, Header, /SILENT))
basesize = FIX(SXPAR(Header, "BASESIZE", /SILENT))
sscale = FLOAT(SXPAR(*DataSet.Headers[0],"SSCALE", /SILENT))
print, "Plate Scale = ", sscale
pEffective = PTR_NEW(/ALLOCATE_HEAP)
*pEffective = FIX(READFITS(FileName, Header, EXTEN_NO=1, /SILENT))
pBasis_Vectors = PTR_NEW(/ALLOCATE_HEAP)
*pBasis_Vectors = READFITS(FileName, Header, EXTEN_NO=2, /SILENT)
;IF PTR_VALID(pBasis_Vectors) THEN HELP, pBasis_Vectors
;IF PTR_VALID(pBasis_Vectors) THEN HELP, *pBasis_Vectors
nFrames = DataSet.ValidFrameCount
localReturnVal = 0
FOR i=0, (nFrames-1) DO BEGIN
                                ; First, construct the execution string that implements references to the available
                                ; parameters.  Start with a base string then add the code module name followed by the
                                ; parameters.  As a parameter is added, increment the total parameter count.
                                ; Initialize the execution string and the parameter count.
    execString = "retval = CALL_EXTERNAL(EXTERNAL_CODE_FILENAME"
    totalParmCount = FIX(0)
                                ; Add the C code module name which is NOT a prameter.
    execString = execString + ", 'spatrectif_000'"
                                ; Add parameters to the execution string and increment the total parameter count
    totalParmCount = totalParmCount + drpAddParmToCallSequence(execString, 'totalParmCount')
    totalParmCount = totalParmCount + drpAddParmToCallSequence(execString, 'numiter')
    totalParmCount = totalParmCount + drpAddParmToCallSequence(execString, 'relaxation')
    totalParmCount = totalParmCount + drpAddParmToCallSequence(execString, 'basesize')
    totalParmCount = totalParmCount + drpAddParmToCallSequence(execString, '(*pHilo)')
    totalParmCount = totalParmCount + drpAddParmToCallSequence(execString, '(*pEffective)')
    totalParmCount = totalParmCount + drpAddParmToCallSequence(execString, '(*pBasis_Vectors)')
    totalParmCount = totalParmCount + drpAddParmToCallSequence(execString, 'Modules[thisModuleIndex]')
    totalParmCount = totalParmCount + drpAddParmToCallSequence(execString, 'DataSet')
    totalParmCount = totalParmCount + drpAddParmToCallSequence(execString, '(*DataSet.Frames[' + STRTRIM(STRING(i), 2) + '])')
    totalParmCount = totalParmCount + drpAddParmToCallSequence(execString, '(*DataSet.Headers[' + STRTRIM(STRING(i), 2) + '])')
    totalParmCount = totalParmCount + drpAddParmToCallSequence(execString, '(*DataSet.IntFrames[' + STRTRIM(STRING(i), 2) + '])')
    totalParmCount = totalParmCount + drpAddParmToCallSequence(execString, '(*DataSet.IntAuxFrames[' + STRTRIM(STRING(i), 2) + '])')
                                ; Create a new type of data for the Frames[i] pointer to reference, say a cube
;    drpMemoryMark, 'spatrectif_000.pro: Before creating image, noise and quality arrays'
    image = PTR_NEW(FLTARR(DATAFRAMEDIM, NUMSPEC)) ; Create a new array on the heap and a pointer variable to it
    noise = PTR_NEW(FLTARR(DATAFRAMEDIM, NUMSPEC)) ; Create a new array on the heap and a pointer variable to it
    quality = PTR_NEW(BYTARR(DATAFRAMEDIM, NUMSPEC)) ; Create a new array on the heap and a pointer variable to it
;    drpMemoryMark, 'spatrectif_000.pro: After  creating image, noise and quality arrays'
;    IF PTR_VALID(image) THEN HELP, image
;    IF PTR_VALID(image) THEN HELP, *image
;    IF PTR_VALID(noise) THEN HELP, noise
;    IF PTR_VALID(noise) THEN HELP, *noise
;    IF PTR_VALID(quality) THEN HELP, quality
;    IF PTR_VALID(quality) THEN HELP, *quality
    totalParmCount = totalParmCount + drpAddParmToCallSequence(execString, '(*image)')
    totalParmCount = totalParmCount + drpAddParmToCallSequence(execString, '(*noise)')
    totalParmCount = totalParmCount + drpAddParmToCallSequence(execString, '(*quality)')
    totalParmCount = totalParmCount + drpAddParmToCallSequence(execString, 'sscale')
                                ; Close the call with a parenthesis
    execString = execString + ')'
    
;    PRINT, "spatrectif_000.pro: totalParmCount = " + STRTRIM(STRING(totalParmCount), 2)
                                ;PRINT, "spatrectif_000.pro: execString = " + execString
    
                                ; ------------------------ TO DO: The C procedure needs to alter the Int Maps ----------------------------
                                ; Call the C procedure
;    drpMemoryMark, 'Calling C code from spatrectif_000.pro...'
    retVal = 0                  ; Clear the C code return value
    execReturn = EXECUTE(execString)
;    drpMemoryMark, 'Returned from calling C code in spatrectif_000.pro...'
    IF (retval EQ 0) THEN BEGIN
;        PRINT, "spatrectif_000 C code returned 0"
;        drpMemoryMark, 'Memory before storing image, noise and quality'
                                ; We have a good rectification, so swap the pointers in DataSet.Frames
                                ; DataSet.IntFrames and DataSet.IntAuxFrames to point to the new data.
        tempPtr = PTR_NEW(/ALLOCATE_HEAP) ; Create a new heap variable
        *tempPtr = *DataSet.Frames[i] ; Use the new heap variable to save the old data
        *DataSet.Frames[i] = *image ; Now the DataSet.Frames[i] pointer to the rectified frame
        PTR_FREE, tempPtr       ; Free the old data using the temporary pointer
        PTR_FREE, image         ; Free the image data array
        tempPtr = PTR_NEW(/ALLOCATE_HEAP) ; Create a new heap variable
        *tempPtr = *DataSet.IntFrames[i] ; Use the new heap variable to save the old noise data
        *DataSet.IntFrames[i] = *noise ; Now the DataSet.IntFrames[i] pointer to the rectified noise data
        PTR_FREE, tempPtr       ; Free the old noise data using the temporary pointer
        PTR_FREE, noise         ; Free the noise data array
        tempPtr = PTR_NEW(/ALLOCATE_HEAP) ; Create a new heap variable
        *tempPtr = *DataSet.IntAuxFrames[i] ; Use the new heap variable to save the old quality data
        *DataSet.IntAuxFrames[i] = *quality ; Now the DataSet.IntAuxFrames[i] pointer to the rectified quality data
        PTR_FREE, tempPtr       ; Free the old quality data using the temporary pointer
        PTR_FREE, quality       ; Free the quality data array
                                ; Reset the header keywords NAXIS1 and NAXIS2
        SXADDPAR, *DataSet.Headers[i], "NAXIS1", DATAFRAMEDIM, AFTER='NAXIS'
        SXADDPAR, *DataSet.Headers[i], "NAXIS2", NUMSPEC, AFTER='NAXIS1'
;        drpMemoryMark, 'spatrectif_000.pro: After  freeing original Frames, Noise and Quality arrays'
;        IF PTR_VALID(image) THEN HELP, image
;        IF PTR_VALID(image) THEN HELP, *image
;        IF PTR_VALID(noise) THEN HELP, noise
;        IF PTR_VALID(noise) THEN HELP, *noise
;        IF PTR_VALID(quality) THEN HELP, quality
;        IF PTR_VALID(quality) THEN HELP, *quality
;        PRINT, "HELP on the DataSet pointer members"
;        HELP, DataSet.Frames[i]
;        HELP, *DataSet.Frames[i]
;        HELP, DataSet.IntFrames[i]
;        HELP, *DataSet.IntFrames[i]
;        HELP, DataSet.IntAuxFrames[i]
;        HELP, *DataSet.IntAuxFrames[i]
    ENDIF ELSE BEGIN
        PTR_FREE, image         ; Free the allocated image array since we will not be needing it
        PTR_FREE, noise         ; Free the allocated noise array since we will not be needing it
        PTR_FREE, quality       ; Free the allocated quality array since we will not be needing it
        drpLog, 'FUNCTION '+ functionName + ': C code returned non-zero value == ' + STRTRIM(STRING(retval), 2), /DRF, DEPTH = 2
        PRINT, "ERROR: spatrectif_000 C code returned non-zero value == " + STRTRIM(STRING(retval), 2)
        localReturnVal = ERR_CMODULE ; Set the local return value to show the C code error
        i = nFrames             ; Set i so there will be no more looping
    ENDELSE
ENDFOR

                                ; Free the Calibration data here since, error or not, we are done with it for this DRF.
                                ; ------------------------ TO DO: Figure out how to retain the Calibration data from DRF to DRF ----------------------------
PTR_FREE, pHilo
PTR_FREE, pEffective
PTR_FREE, pBasis_Vectors

;drpMemoryMark, 'Exiting spatrectif_000.pro...'

RETURN, localReturnVal

END
