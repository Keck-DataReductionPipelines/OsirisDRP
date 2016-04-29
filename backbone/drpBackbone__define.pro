;-----------------------------------------------------------------------------------------------------
; Procedure drpBackbone__define
;
; DESCRIPTION:
; 	DRP Backbone object definition module.
; 
; ARGUMENTS:
;	None.
;
; KEYWORDS:
;	None.
;
; Modified:
;	2004-03-15 TMG Changed the use of FINDFILE to FILE_SEARCH which seems to have fixed the memory
;		   error.
;	2004-06-02 TMG Remove references to CRF since it is not needed anymore.
;   2016-04-28 ARR Refactor ::Run into methods so that one can run a single DRF on command.
;
;-----------------------------------------------------------------------------------------------------
PRO drpBackbone__define

	void = {drpBackbone, $
			Parser:OBJ_NEW(), $
			ConfigParser:OBJ_NEW(), $
			DRFPipeline:OBJ_NEW(), $
			ParmList:PTR_NEW(), $
			Data:PTR_NEW(), $
			Modules:PTR_NEW(), $
			ReductionType:'', $
			CurrentlyExecutingModuleNumber:0, $
			LogPath:''}

END

PRO drpBackbone::Cleanup

	OBJ_DESTROY, Self.Parser
	OBJ_DESTROY, Self.ConfigParser
	OBJ_DESTROY, Self.DRFPipeline
	
	IF PTR_VALID(Self.Data) THEN $
		FOR i = 0, N_ELEMENTS(*Self.Data)-1 DO BEGIN
			PTR_FREE, (*Self.Data)[i].Frames[*]
			PTR_FREE, (*Self.Data)[i].Headers[*]
			PTR_FREE, (*Self.Data)[i].IntFrames[*]
			PTR_FREE, (*Self.Data)[i].IntAuxFrames[*]
		END

	PTR_FREE, Self.Data
	PTR_FREE, Self.Modules

END

;+
; Run the tasks required to start the DRP backbone.
;-
PRO drpBackbone::Start

	COMMON APP_CONSTANTS
	COMMON MSGCONSTANTS
	COMMON MSGBUFFERIN
	COMMON MSGBUFFEROUT

	CATCH, Error   	; Catch errors before the pipeline
	IF Error EQ 0 THEN BEGIN
		drpSetAppConstants		; Set the application constants
		drpPushCallStack, 'drpBackbone::Run'	
		Self -> OpenLog, drpXlateFileName(GETENV('OSIRIS_DRP_DEFAULTLOGDIR')) + '/' + general_log_name(), /GENERAL
		drpLog, 'Run Backbone', /GENERAL		 
		InErrHandler = 0
		; The following should probably be done in a drpBackbone::INIT method
		Self.Parser = OBJ_NEW('drpDRFParser')		
		Self.DRFPipeline = OBJ_NEW('drpDRFPipeline')
		Self.ConfigParser = OBJ_NEW('drpConfigParser')
		; End INIT?
		drpPARAMETERSDefine
		;drpLog, 'drpBackbone::Run: About to parse config file', /GENERAL		 
		drpDefineStructs		; Define the DRP structures
	ENDIF ELSE BEGIN
		Self -> ErrorHandler
		CLOSE, LOG_GENERAL
		FREE_LUN, LOG_GENERAL
		CLOSE, LOG_DRF
		FREE_LUN, LOG_DRF
   		RETURN
	ENDELSE
END

;+
; Given a filename, run it through the DRF queue.
; Optionally, provide the name of the queue directory.
; Otherwise, assume that the DRF is in the queue directory.
;-
PRO drpBackbone::DoFile, Filename, QueueDir=QueueDir
	COMMON APP_CONSTANTS
	COMMON MSGCONSTANTS
	COMMON MSGBUFFERIN
	COMMON MSGBUFFEROUT
	CATCH, Error	; Catch errors inside the pipeline
	IF Error EQ 0 THEN BEGIN
        IF ~KEYWORD_SET(QueueDir) THEN BEGIN
            parsed = FILE_PATH_NAME_EXT(Filename)
            QueueDir = parsed.path
        ENDIF
        
		CurrentDRF = {structQueryEntry}
		parsed_file = file_path_name_ext(Filename)
		CurrentDRF.status = STRMID(parsed_file.ext, 1)
		parsed_file = file_path_name_ext(parsed_file.name)
		CurrentDRF.name = STRMID(parsed_file.ext, 1)
		CurrentDRF.index = parsed_file.name
		Self -> DoSingle, CurrentDRF, QueueDir
	ENDIF ELSE BEGIN
		PRINT, "Calling Self -> ErrorHandler..."
		Self -> ErrorHandler, CurrentDRF, QueueDir
		CLOSE, LOG_DRF
		FREE_LUN, LOG_DRF
	ENDELSE
	
END

;+
; Process a single CurrentDRF struct.
; This inernal method is used by both drpBackbone::DoQueueOnce
; and drpBackbone::DoFile
;
PRO drpBackbone::DoSingle, CurrentDRF, QueueDir
	COMMON APP_CONSTANTS
	COMMON MSGCONSTANTS
	COMMON MSGBUFFERIN
	COMMON MSGBUFFEROUT
	IF CurrentDRF.Name NE '' THEN BEGIN
		drpLog, 'Found file:' + CurrentDRF.Name, /GENERAL
                            wait, 1.0   ; Wait 1 seconds to make sure file is fully written.
		drpSetStatus, CurrentDRF, QueueDir, 'working'
		DRFFileName = drpFileNameFromStruct(QueueDir, CurrentDRF)
		; Re-parse the configuration file, in case it has been changed.
		OPENR, lun, CONFIG_FILENAME_FILE, /GET_LUN
		READF, lun, CONFIG_FILENAME
		FREE_LUN, lun
		Self.ConfigParser -> ParseFile, drpXlateFileName(CONFIG_FILENAME)
		Self.ConfigParser -> getParameters, Self
    CATCH, parserError
		IF parserError EQ 0 THEN BEGIN
			continueAfterDRFParsing = 1    ; Assume it will be Ok to continue
			Self.Parser -> ParseFile, DRFFileName, Self
			CATCH, /CANCEL
		ENDIF ELSE BEGIN
      ; This branch, for errors we have not thought of yet, will cause a
      ; memory leak.  I do not understand it, but the the destruction and
      ; recreation of the DRF parser seems to be the source of the leak.
      ; TMG July 12, 2004
			; Call the local error handler
			Self -> ErrorHandler, CurrentDRF, QueueDir
			; Destroy the current DRF parser and punt the DRF
			OBJ_DESTROY, Self.Parser
			; Recreate a parser object for the next DRF in the pipeline
			Self.Parser = OBJ_NEW('drpDRFParser')
			continueAfterDRFParsing = 0
			CATCH, /CANCEL
		ENDELSE
		IF continueAfterDRFParsing EQ 1 THEN BEGIN
			Self.ConfigParser -> getIDLFunctions, Self
			Self -> OpenLog, Self.LogPath + '/' + CurrentDRF.Name + '.log', /DRF
			Result = Self.DRFPipeline -> Reduce(*Self.Modules, *Self.Data, Self)
			IF Result EQ 1 THEN BEGIN
				PRINT, "Success"
				drpSetStatus, CurrentDRF, QueueDir, 'done'
			ENDIF ELSE BEGIN
				PRINT, "Failure"
				drpSetStatus, CurrentDRF, QueueDir, 'failed'
			ENDELSE
			; Free any remaining THIS memory here
			IF PTR_VALID(Self.Data) THEN BEGIN
				FOR i = N_ELEMENTS(*Self.Data)-1, 0, -1 DO BEGIN
					PTR_FREE, (*Self.Data)[i].IntAuxFrames[*]
					PTR_FREE, (*Self.Data)[i].IntFrames[*]
					PTR_FREE, (*Self.Data)[i].Headers[*]
					PTR_FREE, (*Self.Data)[i].Frames[*]
				ENDFOR
			ENDIF ; PTR_VALID(Self.Data)

			; We are done with the DRF, so close its log file
			CLOSE, LOG_DRF
			FREE_LUN, LOG_DRF
		ENDIF ELSE BEGIN  ; ENDIF continueAfterDRFParsing EQ 1
      ; This code if continueAfterDRFParsing == 0
      drpLog, 'drpBackbone::Run: Reduction failed due to parsing error in file ' + DRFFileName, /GENERAL
      drpSetStatus, CurrentDRF, QueueDir, 'failed'
      ; If we failed with outstanding data, then clean it up.
      IF PTR_VALID(Self.Data) THEN BEGIN
        FOR i = N_ELEMENTS(*Self.Data)-1, 0, -1 DO BEGIN
          PTR_FREE, (*Self.Data)[i].IntAuxFrames[*]
          PTR_FREE, (*Self.Data)[i].IntFrames[*]
          PTR_FREE, (*Self.Data)[i].Headers[*]
          PTR_FREE, (*Self.Data)[i].Frames[*]
        ENDFOR
      ENDIF
    ENDELSE
drpMemoryMarkSimple, 'xh'
;HEAP_GC, /VERBOSE    ; Use this if the RBconfig.xml parameter list gets "big"
ENDIF
END

;+
; Get the next waiting DRF and process it.
; This is a single run through the main DRP while loop.
;-
PRO drpBackbone::DoQueueOnce, QueueDir
	COMMON APP_CONSTANTS
	COMMON MSGCONSTANTS
	COMMON MSGBUFFERIN
	COMMON MSGBUFFEROUT
	CATCH, Error	; Catch errors inside the pipeline
	IF Error EQ 0 THEN BEGIN
		queueDirName = QueueDir + '*.waiting'
		FileNameArray = FILE_SEARCH(queueDirName)
		CurrentDRF = drpGetNextWaitingFile(FileNameArray)
		Self -> DoSingle, CurrentDRF, QueueDir
	ENDIF ELSE BEGIN
		PRINT, "Calling Self -> ErrorHandler..."
		Self -> ErrorHandler, CurrentDRF, QueueDir
		CLOSE, LOG_DRF
		FREE_LUN, LOG_DRF
	ENDELSE
END

;+
; Get all waiting DRFs and process them.
;-
PRO drpBackbone::ConsumeQueue, QueueDir
	COMMON APP_CONSTANTS
	COMMON MSGCONSTANTS
	COMMON MSGBUFFERIN
	COMMON MSGBUFFEROUT
	queueDirName = QueueDir + '*.waiting'
	FileNameArray = FILE_SEARCH(queueDirName)
    DRPCONTINUE = 1
    WHILE size(FileNameArray)[0] GT 0 AND DRPCONTINUE DO BEGIN
    	CATCH, Error; Catch errors inside the pipeline
    	IF Error EQ 0 THEN BEGIN
    		CurrentDRF = drpGetNextWaitingFile(FileNameArray)
    		Self -> DoSingle, CurrentDRF, QueueDir
    	ENDIF ELSE BEGIN
    		PRINT, "Calling Self -> ErrorHandler..."
    		Self -> ErrorHandler, CurrentDRF, QueueDir
    		CLOSE, LOG_DRF
    		FREE_LUN, LOG_DRF
    	ENDELSE
    	FileNameArray = FILE_SEARCH(queueDirName)
    ENDWHILE
END

;+
; Called to close log files etc when the DRP queue is done.
;-
PRO drpBackbone::Finish
	COMMON APP_CONSTANTS
	COMMON MSGCONSTANTS
	COMMON MSGBUFFERIN
	COMMON MSGBUFFEROUT
	
	CLOSE, LOG_GENERAL
	FREE_LUN, LOG_GENERAL
END


;+
; Consume the DRP backbone queue indefinietly, similar to how drpBackbone::Run works.
;-
PRO drpBackbone::RunMany, QueueDir
	COMMON APP_CONSTANTS
	COMMON MSGCONSTANTS
	COMMON MSGBUFFERIN
	COMMON MSGBUFFEROUT
	Self -> Start
	DRPCONTINUE = 1  ; Start off with a continuous loop
	WHILE DRPCONTINUE EQ 1 DO BEGIN
		Self -> DoQueueOnce, QueueDir
		drpCheckMessages  ; Check to see if we told ourselves to stop via the GUI
                                ; Delay added to keep CPU usage
                                ; down. Suggested by Marshall Perrin
                                ; Feb 18, 2006
                ; Moved to the correct place JEL, May 30, 2007
    wait, 1
	ENDWHILE
	Self -> Finish
END

PRO drpBackbone::Run, QueueDir

	COMMON APP_CONSTANTS
	COMMON MSGCONSTANTS
	COMMON MSGBUFFERIN
	COMMON MSGBUFFEROUT

	CATCH, Error   	; Catch errors before the pipeline
	IF Error EQ 0 THEN BEGIN
		drpSetAppConstants		; Set the application constants
		drpPushCallStack, 'drpBackbone::Run'	
		Self -> OpenLog, drpXlateFileName(GETENV('OSIRIS_DRP_DEFAULTLOGDIR')) + '/' + general_log_name(), /GENERAL
		drpLog, 'Run Backbone', /GENERAL		 
		InErrHandler = 0
		; The following should probably be done in a drpBackbone::INIT method
		Self.Parser = OBJ_NEW('drpDRFParser')		
		Self.DRFPipeline = OBJ_NEW('drpDRFPipeline')
		Self.ConfigParser = OBJ_NEW('drpConfigParser')
		; End INIT?
		drpPARAMETERSDefine
		;drpLog, 'drpBackbone::Run: About to parse config file', /GENERAL		 
		drpDefineStructs		; Define the DRP structures
	ENDIF ELSE BEGIN
		Self -> ErrorHandler
		CLOSE, LOG_GENERAL
		FREE_LUN, LOG_GENERAL
		CLOSE, LOG_DRF
		FREE_LUN, LOG_DRF
   		RETURN
	ENDELSE	

	; Replace this fixed assignement with some environment variable stuff

; Commented out by James Larkin, Oct. 29, 2005
;	OriginalPath = STRING(!PATH)
;	newModulePath = drpXlateFileName(GETENV('OSIRIS_DRP_MODULE_PATH')) + ':' + OriginalPath
;	drpSetModulePath, newModulePath
;	OriginalPath = STRING(!PATH)
;	newModulePath = drpXlateFileName(GETENV('OSIRIS_DRP_IDL_DOWNLOADS_PATH')) + ':' + OriginalPath
;	drpSetModulePath, newModulePath
;	OriginalPath = STRING(!PATH)
;	newModulePath = drpXlateFileName(GETENV('OSIRIS_DRP_BACKBONE_PATH')) + ':' + OriginalPath
;	drpSetModulePath, newModulePath

	;  Poll the 'queue' directory continuously.  If a DRF is encountered, reduce it.
	DRPCONTINUE = 1  ; Start off with a continuous loop
	WHILE DRPCONTINUE EQ 1 DO BEGIN
		CATCH, Error	; Catch errors inside the pipeline
  	IF Error EQ 0 THEN BEGIN
			queueDirName = QueueDir + '*.waiting'
			FileNameArray = FILE_SEARCH(queueDirName)
			CurrentDRF = drpGetNextWaitingFile(FileNameArray)
			IF CurrentDRF.Name NE '' THEN BEGIN
				drpLog, 'Found file:' + CurrentDRF.Name, /GENERAL
                                wait, 1.0   ; Wait 1 seconds to make sure file is fully written.
				drpSetStatus, CurrentDRF, QueueDir, 'working'
				DRFFileName = drpFileNameFromStruct(QueueDir, CurrentDRF)
				; Re-parse the configuration file, in case it has been changed.
				OPENR, lun, CONFIG_FILENAME_FILE, /GET_LUN
				READF, lun, CONFIG_FILENAME
				FREE_LUN, lun
				Self.ConfigParser -> ParseFile, drpXlateFileName(CONFIG_FILENAME)
				Self.ConfigParser -> getParameters, Self
        CATCH, parserError
				IF parserError EQ 0 THEN BEGIN
					continueAfterDRFParsing = 1    ; Assume it will be Ok to continue
					Self.Parser -> ParseFile, DRFFileName, Self
					CATCH, /CANCEL
				ENDIF ELSE BEGIN
          ; This branch, for errors we have not thought of yet, will cause a
          ; memory leak.  I do not understand it, but the the destruction and
          ; recreation of the DRF parser seems to be the source of the leak.
          ; TMG July 12, 2004
					; Call the local error handler
					Self -> ErrorHandler, CurrentDRF, QueueDir
					; Destroy the current DRF parser and punt the DRF
					OBJ_DESTROY, Self.Parser
					; Recreate a parser object for the next DRF in the pipeline
					Self.Parser = OBJ_NEW('drpDRFParser')
					continueAfterDRFParsing = 0
					CATCH, /CANCEL
				ENDELSE
				IF continueAfterDRFParsing EQ 1 THEN BEGIN
					Self.ConfigParser -> getIDLFunctions, Self
					Self -> OpenLog, Self.LogPath + '/' + CurrentDRF.Name + '.log', /DRF
					Result = Self.DRFPipeline -> Reduce(*Self.Modules, *Self.Data, Self)
					IF Result EQ 1 THEN BEGIN
						PRINT, "Success"
						drpSetStatus, CurrentDRF, QueueDir, 'done'
					ENDIF ELSE BEGIN
						PRINT, "Failure"
						drpSetStatus, CurrentDRF, QueueDir, 'failed'
					ENDELSE
					; Free any remaining THIS memory here
					IF PTR_VALID(Self.Data) THEN BEGIN
						FOR i = N_ELEMENTS(*Self.Data)-1, 0, -1 DO BEGIN
							PTR_FREE, (*Self.Data)[i].IntAuxFrames[*]
							PTR_FREE, (*Self.Data)[i].IntFrames[*]
							PTR_FREE, (*Self.Data)[i].Headers[*]
							PTR_FREE, (*Self.Data)[i].Frames[*]
						ENDFOR
					ENDIF ; PTR_VALID(Self.Data)

					; We are done with the DRF, so close its log file
					CLOSE, LOG_DRF
					FREE_LUN, LOG_DRF
				ENDIF ELSE BEGIN  ; ENDIF continueAfterDRFParsing EQ 1
          ; This code if continueAfterDRFParsing == 0
          drpLog, 'drpBackbone::Run: Reduction failed due to parsing error in file ' + DRFFileName, /GENERAL
          drpSetStatus, CurrentDRF, QueueDir, 'failed'
          ; If we failed with outstanding data, then clean it up.
          IF PTR_VALID(Self.Data) THEN BEGIN
            FOR i = N_ELEMENTS(*Self.Data)-1, 0, -1 DO BEGIN
              PTR_FREE, (*Self.Data)[i].IntAuxFrames[*]
              PTR_FREE, (*Self.Data)[i].IntFrames[*]
              PTR_FREE, (*Self.Data)[i].Headers[*]
              PTR_FREE, (*Self.Data)[i].Frames[*]
            ENDFOR
          ENDIF
        ENDELSE
drpMemoryMarkSimple, 'xh'
;HEAP_GC, /VERBOSE    ; Use this if the RBconfig.xml parameter list gets "big"
			ENDIF
		ENDIF ELSE BEGIN
			PRINT, "Calling Self -> ErrorHandler..."
			Self -> ErrorHandler, CurrentDRF, QueueDir
			CLOSE, LOG_DRF
			FREE_LUN, LOG_DRF
		ENDELSE
		drpCheckMessages  ; Check to see if we told ourselves to stop via the GUI
                                ; Delay added to keep CPU usage
                                ; down. Suggested by Marshall Perrin
                                ; Feb 18, 2006
                ; Moved to the correct place JEL, May 30, 2007
                wait, 1
	ENDWHILE
	CLOSE, LOG_GENERAL
	FREE_LUN, LOG_GENERAL
END


PRO drpBackbone::OpenLog, LogFile, GENERAL = LogGeneral, DRF = LogDRF

	COMMON APP_CONSTANTS

	drpPushCallStack, 'drpBackbone::OpenLog'

	IF KEYWORD_SET(LogGeneral) THEN BEGIN
		drpIOLock
		CLOSE, LOG_GENERAL
		FREE_LUN, LOG_GENERAL
		OPENW, LOG_GENERAL, LogFile, /GET_LUN
		PRINTF, LOG_GENERAL, 'Data Reduction Pipeline' 
		PRINTF, LOG_GENERAL, 'Run On ' + SYSTIME(0)
		PRINTF, LOG_GENERAL, 'Logical Unit Number = ' + STRING(LOG_GENERAL)
		PRINTF, LOG_GENERAL, ''
		drpIOUnlock
	ENDIF

	IF KEYWORD_SET(LogDRF) THEN BEGIN
		drpIOLock
		CLOSE, LOG_DRF
		FREE_LUN, LOG_DRF
		OPENW, LOG_DRF, LogFile, /GET_LUN
		PRINTF, LOG_DRF, 'Data Reduction Pipeline' 
		PRINTF, LOG_DRF, 'Run On ' + SYSTIME(0)
		PRINTF, LOG_DRF, 'Logical Unit Number = ' + STRING(LOG_DRF)
		PRINTF, LOG_DRF, ''
		PRINTF, LOG_GENERAL, 'DRF log opened on LUN = ' + STRING(LOG_DRF)
		drpIOUnlock
	ENDIF

	void = drpPopCallStack()

END

FUNCTION drpBackbone::getParameter, ParmName

	temp = ''
	fetchString = "temp = (*Self.ParmList)." + ParmName
	retVal = EXECUTE(fetchString)
	RETURN, temp

END


FUNCTION drpBackbone::getType

	RETURN, Self.ReductionType

END


FUNCTION drpBackbone::getValidFrameCount, DataSetName

  index = drpDataSetIndexFromName(*Self.Data, DataSetName)
	RETURN, (*Self.Data)[index].ValidFrameCount

END


FUNCTION drpBackbone::getCurrentlyExecutingModuleNumber

	RETURN, Self.CurrentlyExecutingModuleNumber

END


FUNCTION drpBackbone::setValidFrameCount, DataSetName, NewFrameCount

  index = drpDataSetIndexFromName(*Self.Data, DataSetName)
  (*Self.Data)[index].ValidFrameCount = NewFrameCount
	RETURN, 1

END


PRO drpBackbone::ErrorHandler, CurrentDRF, QueueDir

	COMMON APP_CONSTANTS

	CATCH, Error

	IF Error EQ 0 THEN BEGIN
		drpLog, 'ERROR: ' + !ERROR_STATE.MSG + '    ' + $
			!ERROR_STATE.SYS_MSG, /GENERAL, DEPTH = 1
		drpLog, 'Reduction failed', /GENERAL
		IF N_PARAMS() EQ 2 THEN BEGIN
			drpSetStatus, CurrentDRF, QueueDir, 'failed'
			; If we failed with outstanding data, then clean it up.
			IF PTR_VALID(Self.Data) THEN BEGIN
				FOR i = N_ELEMENTS(*Self.Data)-1, 0, -1 DO BEGIN
					PTR_FREE, (*Self.Data)[i].IntAuxFrames[*]
					PTR_FREE, (*Self.Data)[i].IntFrames[*]
					PTR_FREE, (*Self.Data)[i].Headers[*]
					PTR_FREE, (*Self.Data)[i].Frames[*]
				ENDFOR
			ENDIF
		ENDIF
	ENDIF ELSE BEGIN
    ; Will this cause a recursion error?
		MESSAGE, 'ERROR in drpBackbone::ErrorHandler - ' + STRTRIM(STRING(!ERR),2) + ': ' + !ERR_STRING, /INFO
	ENDELSE

	CATCH, /CANCEL
END
