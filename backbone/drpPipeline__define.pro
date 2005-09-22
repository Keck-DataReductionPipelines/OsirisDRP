PRO drpPipeline__define

	void = {drpPipeline, Type:''}

END

FUNCTION drpPipeline::RunModule, Modules, ModNum, DataSet, Backbone

	COMMON APP_CONSTANTS

	drpPushCallStack, 'drpPipeline::RunModule'
	
	; Execute the call sequence and pass the return value to DRP_EVALUATE
	drpLog, 'Running Module: ' + Modules[ModNum].Name, /GENERAL, /DRF, DEPTH = 1

  ; Add the currently executing module number to the Backbone structure
  Backbone.CurrentlyExecutingModuleNumber = ModNum

	Result = EXECUTE('drpEvaluate, ' + Modules[ModNum].CallSequence + $
			'(DataSet, Modules, Backbone),  ''' + Modules[ModNum].Name + '''')
			
	IF Result EQ 0 THEN BEGIN			;  The module failed
		IF (STRCMP(!ERR_STRING, "Variable", 8, /FOLD_CASE) EQ 1) THEN BEGIN
			drpIOLock
			PRINT, "drpPipeline::RunModule: " + !ERROR_STATE.MSG
			PRINT, "drpPipeline::RunModule: " + !ERR_STRING
			PRINT, "drpPipeline::RunModule: " + CALL_STACK
			PRINT, "drpPipeline::RunModule: " + Modules[ModNum].CallSequence
			PRINT, "drpPipeline::RunModule: " + Modules[ModNum].Name
			drpIOUnlock
		ENDIF
		drpLog, 'ERROR: ' + !ERR_STRING, /GENERAL, /DRF, DEPTH=2 	
		drpLog, 'Module failed: ' + Modules[ModNum].Name, /GENERAL, /DRF, Depth=1
	ENDIF ELSE BEGIN				;  The module succeeded
		drpLog, 'Module completed: ' + Modules[ModNum].Name, $
		/GENERAL, /DRF, DEPTH = 1
	ENDELSE

	drpCheckMessages

	void = drpPopCallStack()

	RETURN, Result

END
