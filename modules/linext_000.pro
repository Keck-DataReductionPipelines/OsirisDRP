FUNCTION linext_000, DataSet, Modules, Backbone

COMMON APP_CONSTANTS

;drpMemoryMark, 'Entering linext_000.pro...'
; Linext is a specialized version of the spectral extraction that
; works for a source with no continuum. It does not try to separate
; flux from different lenslets but instead simply integrates over the
; region for each spectral channel.

functionName = 'linext_000'

drpLog, 'Module: ' + functionName + ' - Received data set: ' + DataSet.Name, /GENERAL, /DRF, DEPTH = 1

                                ; Get all COMMON parameter values
numpix = FLOAT(drpParamValue('linext_COMMON___numpix'))
print, 'Number of pixels in each extraction is:', numpix
                                ; Now perform the common code execution for spatial rectification
                                ; Read in the Calibration file that will contain:
                                ;	BASESIZE	Keyword
                                ;	hilo		short int array[NUMSPEC][2]
                                ;	effective	short int array[NUMSPEC]
                                ;	basis_vectors	float array[NUMSPEC][MAXSLICE][DATAFRAMEDIM]
thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
FileName = drpXlateFileName(Modules[thisModuleIndex].CalibrationFile)
pHilo = FIX(READFITS(FileName, Header, /SILENT))
basesize = FIX(SXPAR(Header, "BASESIZE", /SILENT))
sscale = FLOAT(SXPAR(*DataSet.Headers[0],"SSCALE", /SILENT))
print, "Plate Scale = ", sscale
pEffective = FIX(READFITS(FileName, Header, EXTEN_NO=1, /SILENT))
pBasis_Vectors = READFITS(FileName, Header, EXTEN_NO=2, /SILENT)

nFrames = DataSet.ValidFrameCount
localReturnVal = 0
FOR i=0, (nFrames-1) DO BEGIN
                                ; First, construct the execution string that implements references to the available
                                ; parameters.  Start with a base string then add the code module name followed by the
                                ; parameters.  As a parameter is added, increment the total parameter count.
                                ; Initialize the execution string and the parameter count.
                                ; Create a new type of data for the Frames[i] pointer to reference, say a cube
    image = (FLTARR(DATAFRAMEDIM, NUMSPEC)) ; Create a new array on the heap and a pointer variable to it
    noise = PTR_NEW(FLTARR(DATAFRAMEDIM, NUMSPEC)) ; Create a new array on the heap and a pointer variable to it
    quality = PTR_NEW(BYTARR(DATAFRAMEDIM, NUMSPEC)) ; Create a new array on the heap and a pointer variable to it

    
    for j = 0, (DATAFRAMEDIM-1) do begin ; Work on the data one column at a time
        for k = 0, (NUMSPEC-1) do begin  ; Calculate each lenslet's value
            basis = pBasis_Vectors[j,*,k]
            offset = pHilo[0,k]
            indx = reverse(sort(basis))
            if ( (j eq 500) and (k eq 500) ) then begin
                print, "Basis and index"
                print, basis
                print, indx
            end
            weight = 0.0
            for q = 0, (numpix-1) do begin
                image[j,k]=image[j,k] + (*DataSet.Frames[i])[j,offset+indx[q]]
                weight = weight + basis[indx[q]]
            end
            if ( weight ne 0.0 ) then begin
                image[j,k] = image[j,k] / weight
                (*quality)[j,k]=9
            endif
        end
    end

    help, image
                                ; We have a good rectification, so swap the pointers in DataSet.Frames
                                ; DataSet.IntFrames and DataSet.IntAuxFrames to point to the new data.
    tempPtr = PTR_NEW(/ALLOCATE_HEAP) ; Create a new heap variable
    *tempPtr = *DataSet.Frames[i] ; Use the new heap variable to save the old data
    *DataSet.Frames[i] = image ; Now the DataSet.Frames[i] pointer to the rectified frame
    PTR_FREE, tempPtr           ; Free the old data using the temporary pointer
    tempPtr = PTR_NEW(/ALLOCATE_HEAP) ; Create a new heap variable
    *tempPtr = *DataSet.IntFrames[i] ; Use the new heap variable to save the old noise data
    *DataSet.IntFrames[i] = *noise ; Now the DataSet.IntFrames[i] pointer to the rectified noise data
    PTR_FREE, tempPtr           ; Free the old noise data using the temporary pointer
    PTR_FREE, noise             ; Free the noise data array
    tempPtr = PTR_NEW(/ALLOCATE_HEAP) ; Create a new heap variable
    *tempPtr = *DataSet.IntAuxFrames[i] ; Use the new heap variable to save the old quality data
    *DataSet.IntAuxFrames[i] = *quality ; Now the DataSet.IntAuxFrames[i] pointer to the rectified quality data
    PTR_FREE, tempPtr           ; Free the old quality data using the temporary pointer
    PTR_FREE, quality           ; Free the quality data array
                                ; Reset the header keywords NAXIS1 and NAXIS2
    SXADDPAR, *DataSet.Headers[i], "NAXIS1", DATAFRAMEDIM, AFTER='NAXIS'
    SXADDPAR, *DataSet.Headers[i], "NAXIS2", NUMSPEC, AFTER='NAXIS1'
ENDFOR

                                ; Free the Calibration data here since, error or not, we are done with it for this DRF.
                                ; ------------------------ TO DO: Figure out how to retain the Calibration data from DRF to DRF ----------------------------
;PTR_FREE, pHilo
;PTR_FREE, pEffective
;PTR_FREE, pBasis_Vectors

;drpMemoryMark, 'Exiting spatrectif_000.pro...'

RETURN, localReturnVal

END
