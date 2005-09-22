PRO drpDRFPipeline__define

	void = {drpDRFPipeline, INHERITS drpPipeline}

END

FUNCTION drpDRFPipeline::Reduce, Modules, Data, Backbone

	COMMON APP_CONSTANTS

	drpPushCallStack, 'drpDRFPipeline::Reduce'

	PRINT, ''
	PRINT, SYSTIME(/UTC)
	PRINT, ''

	; Iterate over the datasets in the 'Data' array and run the sequence of modules for each dataset.
	FOR indexDataset = 0, N_ELEMENTS(Data)-1 DO BEGIN
		drpLog, 'Reducing data set: ' + Data[indexDataset].Name, /GENERAL, /DRF	
		; Iterate over the modules in the 'Modules' array and run the call sequence for each.
		Result = 1
		FOR indexModules = 0, N_ELEMENTS(Modules)-1 DO BEGIN
			; Continue if the current module's skip field equals 0 and no previous module 
			; has failed (Result = 1).
			IF (Modules[indexModules].Skip EQ 0) AND (Result EQ 1) THEN BEGIN
				Result = Self -> RunModule(Modules, indexModules, Data[indexDataset], Backbone)
			ENDIF
		ENDFOR
		; Log the result.
		IF result EQ 1 THEN BEGIN
			drpLog, 'Reduction successful: ' + Data[indexDataset].name, /GENERAL, /DRF
		ENDIF ELSE drpLog, 'Reduction failed: ' + Data[indexDataset].name, /GENERAL, /DRF
	ENDFOR

	PRINT, ''
	PRINT, SYSTIME(/UTC)
	PRINT, ''

	void = drpPopCallStack()

	RETURN, Result

END
