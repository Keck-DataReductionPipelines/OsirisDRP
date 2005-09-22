;-----------------------------------------------------------------------------------------------------
; Procedure drpSetAppConstants
;
; DESCRIPTION:
; 	Initializes the application constants used throughout the program.
; 
; ARGUMENTS:
;	None.
;
; KEYWORDS:
;	None.
;
;-----------------------------------------------------------------------------------------------------
PRO drpSetAppConstants

	; Application constants
	COMMON APP_CONSTANTS, APPLICATION_DIR,	$   		; The drp installation directory
			      BACKBONE_SUPPORT_DIR,	$	; Directory containing backbone support files
			      CONFIG_FILENAME_FILE,	$	; Filename of file that actually contains the configuration filename
			      CONFIG_FILENAME,	$		; Name and path of the config file
			      CONFIG_FILEUNIT,	$ 		; Number used as the file unit for the config file
			      EXTERNAL_CODE_FILENAME,	$	; Name and path of the external code file
			      PRINTDEPTH,	$ 		; Number of spaces before drpPushCallStackPrintDepth prints RoutineName
			      LOG_GENERAL,	$ 		; File unit number of the general log file
			      LOG_DRF,		$		; File unit number of the DRF log file	
			      DRPCONTINUE,	$		; Causes program to look for more files or to terminate
			      DIM_X,		$		; X dimension of the data frames
			      DIM_Y, 		$		; Y dimension of the data frames
			      CALL_STACK,	$		; String to hold the call stack at run time
			      OK,		$		; Indicates success
			      DATAFRAMEDIM,	$		; X and Y dimensions of a data frame
			      NUMSPEC,		$		; Number of spectra in a rectified frame
			      MAXSLICE,		$		; Maximum slice value allowed in creating basis vectors
			      MAXFRAMESINDATASETS,	$	; Maximum number of slots for input file sets in a dataset(?)
			      DEBUG_ENABLED,	$		; Error constant:  debugging enabled
			      continueAfterDRFParsing,	$		; Needed for drpDRFParser to drpBackbone communication
			      READDATA,	$		    ; Read primary data mask for drpFITSToDataSet
			      READNOISE,	$		  ; Read noise data mask for drpFITSToDataSet
			      READQUALITY,	$		; Read quality data mask for drpFITSToDataSet
			      CumulativeMemoryUsedByFITSData,	$		; Stores current allocation of <fits/> files memory
			      MaxMemorySizeOfFITSData,	$		; Max allowed allocation of <fits/> files memory
			      READWHOLEFRAME,	$ ; Read primary data mask for drpFITSToDataSet
			      ERR_UNKNOWN,	$		; Error constant:  unknown error
			      ERR_BADARRAY,	$		; Error constant:  corrupted array
			      ERR_BADCASE,	$		; Error constant:  CASE error: Bad Type
			      ERR_MISSINGFILE,	$		; Error constant:  missing file	
			      ERR_CORRUPTFILE,	$		; Error constant:  corrupted file
			      ERR_DISKSPACE,	$   		; Error constant:  lack of disk space
			      ERR_MISSINGDIR,	$		; Error constant:  missing directory
			      ERR_ALLPIXBAD,	$		; Error constant:  All pixels in a frame are bad
			      ERR_CMODULE,	$		; Error constant:  C code module returned a non-zero value
			      ERR_BADKEYWORD,	$		; Error constant:  Illegal or invalid keyword
			      ERR_WRITETOHEAD			; Error constant:  Error writing status message, message queue full
		
	CD, CURRENT = APPLICATION_DIR
	BACKBONE_SUPPORT_DIR = GETENV('BACKBONE_SUPPORT_DIR')
	BACKBONE_SUPPORT_DIR = BACKBONE_SUPPORT_DIR + '/'
	CONFIG_FILENAME_FILE = GETENV('CONFIG_FILENAME_FILE')
	CONFIG_FILENAME_FILE = BACKBONE_SUPPORT_DIR + CONFIG_FILENAME_FILE
	CONFIG_FILENAME = ''
	CONFIG_FILEUNIT = 3

	CALLABLE_INSTANTIATION = 0
	DEFSYSV, '!CALLED_FROM_C', EXISTS=CALLABLE_INSTANTIATION
	externalCodeDir = GETENV('EXTERNAL_CODE_DIR')
	externalCodeDir = externalCodeDir + '/'
	EXTERNAL_CODE_FILENAME = ''	; Create a String variable
	IF CALLABLE_INSTANTIATION EQ 1 THEN BEGIN	; Use semaphores
		EXTERNAL_CODE_FILENAME = externalCodeDir + 'osiris_ext.so'
	ENDIF ELSE BEGIN				; Don't use semaphores
		EXTERNAL_CODE_FILENAME = externalCodeDir + 'osiris_ext_null.so'
	ENDELSE
	PRINT, "EXTERNAL_CODE_FILENAME = " + EXTERNAL_CODE_FILENAME

	PRINTDEPTH = 0
	LOG_GENERAL = 1
	LOG_DRF = 2
	DRPCONTINUE = 0
	CALL_STACK = ''
	OK = 0

	DATAFRAMEDIM = 2048   ; Matches DATA in drp_structs.h
	NUMSPEC = 1216        ; Matches numspec in drp_structs.h
	MAXSLICE = 16         ; Matches MAXSLICE in drp_structs.h

	MAXFRAMESINDATASETS = 64
	
	DEBUG_ENABLED = -1

	continueAfterDRFParsing = 1

  READDATA = 1
  READNOISE = 2
  READQUALITY = 4
  READWHOLEFRAME = READDATA + READNOISE + READQUALITY

  CumulativeMemoryUsedByFITSData = 0L
  MaxMemorySizeOfFITSData = 1073741824L

  ERR_UNKNOWN = 1
	ERR_BADARRAY = 2
	ERR_BADCASE = 3
	ERR_MISSINGFILE = 4
	ERR_CORRUPTFILE = 5
	ERR_DISKSPACE = 6
	ERR_MISSINGDIR = 7
	ERR_ALLPIXBAD = 8
	ERR_CMODULE = 9
	ERR_BADKEYWORD = 10
	ERR_WRITETOHEAD = 11

	; Constant for using the message buffers
	COMMON MSGCONSTANTS,	ERRORVALUE,		$	; Error return value
				NOERROR,		$	; No error return value
				EMPTYMSGTYPE,		$	; Message type of "empty message"
				RUNPIPELINEMSGTYPE,	$	; Message type of "run pipeline"
				STOPPIPELINEMSGTYPE,	$	; Message type of "stop pipeline"
				PAUSEMSGTYPE,		$	; Message type of "pause pipeline execution"
				RESUMEMSGTYPE,		$	; Message type of "resume pipeline execution"
				ABORTSETMSGTYPE,	$	; Message type of "abort current data set"
				DESTROYMSGTYPE,		$	; Message type of "destroy pipeline"
				STATUSMSGTYPE,		$	; Message type of "status" for outgoing messages
				MSGLENGTH,		$	; Fixed maximum length of input/output message
				MSGBUFFERPOWER,		$	; N where 2^N is the number of elements in a circular message buffer
				MSGBUFFERSIZE,		$	; 2^N where 2^N is the number of elements in a circular message buffer
				MSGBUFFERMASK			; (2^N)-1 where 2^N is the number of elements in a circular message buffer
								; This mask value makes the buffer circular

	ERRORVALUE = -1L
	NOERROR = 0L

	EMPTYMSGTYPE        = 0L
	RUNPIPELINEMSGTYPE  = 1L
	STOPPIPELINEMSGTYPE = 2L
	PAUSEMSGTYPE        = 3L
	RESUMEMSGTYPE       = 4L
	ABORTSETMSGTYPE     = 5L
	DESTROYMSGTYPE      = 6L
	STATUSMSGTYPE       = 7L

	MSGLENGTH = 128L

	MSGBUFFERPOWER = 8L
	MSGBUFFERSIZE = 2L^MSGBUFFERPOWER
	MSGBUFFERMASK = MSGBUFFERSIZE - 1L

	; Define the IDL input message queue COMMON block
	COMMON MSGBUFFERIN,	headI,		$		; Input queue HEAD pointer value
				tailI,		$		; Input queue TAIL pointer value
				errorStateI,	$		; Input queue error state value
				returnTypeI,	$		; Message type of read message
				returnTextI,	$		; Message text of read message
				msgTypeI,	$		; Message type circular input buffer
				msgTextI			; Message text circular input buffer

	headI = 0L
	tailI = 0L
	errorStateI = NOERROR
	returnTypeI = EMPTYMSGTYPE
	returnTextI = BYTARR(MSGLENGTH)
	msgTypeI = LONARR(MSGBUFFERSIZE)
	msgTextI = BYTARR(MSGLENGTH, MSGBUFFERSIZE)
	; Set input circular array buffer type fields to the empty message value.
	FOR i = 0, MSGBUFFERMASK DO BEGIN
	  msgTypeI[i] = EMPTYMSGTYPE
	ENDFOR

	; Define the IDL output message queue COMMON block
	COMMON MSGBUFFEROUT,	headO,		$		; Output queue HEAD pointer value
				tailO,		$		; Output queue TAIL pointer value
				errorStateO,	$		; Output queue error state value
				inputTypeO,	$		; Message type of sent message
				inputTextO,	$		; Message text of sent message
				msgTypeO,	$		; Message type circular output buffer
				msgTextO			; Message text circular output buffer

	headO = 0L
	tailO = 0L
	errorStateO = NOERROR
	inputTypeO = EMPTYMSGTYPE
	inputTextO = BYTARR(MSGLENGTH)
	msgTypeO = LONARR(MSGBUFFERSIZE)
	msgTextO = BYTARR(MSGLENGTH, MSGBUFFERSIZE)
	; Set output circular array buffer type fields to the empty message value.
	FOR i = 0, MSGBUFFERMASK DO BEGIN
	  msgTypeO[i] = EMPTYMSGTYPE
	ENDFOR

	!EXCEPT = 0  ; Never report math computation exceptions, we will check for them.

END


;-----------------------------------------------------------------------------------------------------
; Procedure drpPushCallStack
;
; DESCRIPTION:
; 	Pushes a procedure name into the call stack
;
; ARGUMENTS:
;	RoutineName	Name of the routine to be pushed
;
; KEYWORDS:
;	None.
;-----------------------------------------------------------------------------------------------------
PRO drpPushCallStack, RoutineName

	COMMON APP_CONSTANTS

	CALL_STACK = RoutineName + '/' + CALL_STACK

END


;-----------------------------------------------------------------------------------------------------
; Procedure drpPushCallStackPrintDepth
;
; DESCRIPTION:
; 	Pushes a procedure name into the call stack and prints most routine
;	names in an appropriately indented fashion.
;
; ARGUMENTS:
;	RoutineName	Name of the routine to be pushed
;
; KEYWORDS:
;	None.
;-----------------------------------------------------------------------------------------------------
PRO drpPushCallStackPrintDepth, RoutineName

	COMMON APP_CONSTANTS

	IF RoutineName NE "drpParseQueue" AND RoutineName NE "drpSortQueue" THEN BEGIN
		FOR i=1, PRINTDEPTH DO PRINT, FORMAT='(" ", $)'
		PRINT, RoutineName
	END
	PRINTDEPTH = PRINTDEPTH + 2  ; Adjust spacing

	CALL_STACK = RoutineName + '/' + CALL_STACK

END


;-----------------------------------------------------------------------------------------------------
; Function drpPopCallStack
;
; DESCRIPTION:
; 	Pops the top most procedure name from the call stack
;
; ARGUMENTS:
;	None.
;
; KEYWORDS:
;	None.
;
; RETURN VALUE:
;	Name of the top most procedure in the stack
;-----------------------------------------------------------------------------------------------------
FUNCTION drpPopCallStack

	COMMON APP_CONSTANTS

	Pos = STRPOS(CALL_STACK, '/')
	IF Pos NE -1 THEN BEGIN
		Routine = STRMID(CALL_STACK, 0, Pos)
		CALL_STACK = STRMID(CALL_STACK, Pos + 1)
		RETURN, Routine
	ENDIF

END


;-----------------------------------------------------------------------------------------------------
; Function drpPopCallStackPrintDepth
;
; DESCRIPTION:
; 	Pops the top most procedure name from the call stack and adjusts the
;	variable PRINTDEPTH appropriately.
;
; ARGUMENTS:
;	None.
;
; KEYWORDS:
;	None.
;
; RETURN VALUE:
;	Name of the top most procedure in the stack
;-----------------------------------------------------------------------------------------------------
FUNCTION drpPopCallStackPrintDepth

	COMMON APP_CONSTANTS

	Pos = STRPOS(CALL_STACK, '/')
	IF Pos NE -1 THEN BEGIN
		Routine = STRMID(CALL_STACK, 0, Pos)
		CALL_STACK = STRMID(CALL_STACK, Pos + 1)

		PRINTDEPTH = PRINTDEPTH - 2  ; Adjust spacing

		RETURN, Routine
	ENDIF

END


;-----------------------------------------------------------------------------------------------------
; Procedure drpIOLock
;
; DESCRIPTION:
; 	Calls the external procedure osiris_wait_on_sem_signal() in order to allow
;	IDL code to perform I/O without being interrupted by a signal when the drp
;	has been invoked from a C program via the Callable IDL interface.
;
; ARGUMENTS:
;	None.
;
; KEYWORDS:
;	None.
;-----------------------------------------------------------------------------------------------------
PRO drpIOLock

	COMMON APP_CONSTANTS

	drpPushCallStack, 'drpIOLock'

	; ------------------------ TO DO: Make this platform independent ----------------------------
	; ------------------------ TO DO: This is currently UNIX only    ----------------------------
	retval = CALL_EXTERNAL(EXTERNAL_CODE_FILENAME, 'osiris_wait_on_sem_signal')

	void = drpPopCallStack()

END  


;-----------------------------------------------------------------------------------------------------
; Procedure drpIOUnlock
;
; DESCRIPTION:
; 	Calls the external procedure osiris_post_sem_signal() in order to allow
;	IDL code to be interrupted by a signal when the drp has been invoked from
;	a C program via the Callable IDL interface.  This routine must only be used
;	after a call to drpIOLock.
;
; ARGUMENTS:
;	None.
;
; KEYWORDS:
;	None.
;-----------------------------------------------------------------------------------------------------
PRO drpIOUnlock

	COMMON APP_CONSTANTS

	drpPushCallStack, 'drpIOUnlock'

	; ------------------------ TO DO: Make this platform independent ----------------------------
	; ------------------------ TO DO: This is currently UNIX only    ----------------------------
	retval = CALL_EXTERNAL(EXTERNAL_CODE_FILENAME, 'osiris_post_sem_signal')

	void = drpPopCallStack()

END  


;-----------------------------------------------------------------------------------------------------
; Function incMsgBufferPointer
;
; DESCRIPTION:
; 	Increments a circular message buffer pointer
;
; ARGUMENTS:
;	pointer		A circular message buffer pointer
;
; KEYWORDS:
;	None.
;
; RETURN VALUE:
;	Value of pointer, incremented to work with a circular buffer
;-----------------------------------------------------------------------------------------------------
FUNCTION incMsgBufferPointer, pointer

	COMMON APP_CONSTANTS
	COMMON MSGCONSTANTS
	COMMON MSGBUFFERIN
	COMMON MSGBUFFEROUT

	RETURN, ((LONG(pointer)+1L) AND MSGBUFFERMASK)

END


;-----------------------------------------------------------------------------------------------------
; Function readFromTailI
;
; DESCRIPTION:
; 	Checks for incoming messages to the input pipeline
;
; ARGUMENTS:
;	msgTypeI and tailI in COMMON block MSGBUFFERIN
;
; KEYWORDS:
;	None.
;
; RETURN VALUE:
;	If message found, modifies various variables in COMMON block MSGBUFFERIN
;	including the current message information.  Returns the message type
;-----------------------------------------------------------------------------------------------------
FUNCTION readFromTailI

	COMMON APP_CONSTANTS
	COMMON MSGCONSTANTS
	COMMON MSGBUFFERIN
	COMMON MSGBUFFEROUT

	if (msgTypeI[tailI] EQ EMPTYMSGTYPE) THEN BEGIN  ; Already read this message slot
		RETURN, NOERROR
	ENDIF ELSE BEGIN
		returnTypeI = msgTypeI[tailI]
		returnTextI = msgTextI[*,tailI]
		msgTypeI[tailI] = EMPTYMSGTYPE
		tailI = incMsgBufferPointer(tailI)
		RETURN, returnTypeI
	ENDELSE

END


;-----------------------------------------------------------------------------------------------------
; Function writeToHeadO
;
; DESCRIPTION:
; 	Post a message to the output pipeline
;
; ARGUMENTS:
;	msgTypeO and tailO in COMMON block MSGBUFFEROUT
;
; KEYWORDS:
;	None.
;
; RETURN VALUE:
;	If message type array is full, returns ERRORVALUE, else modifies various
;	variables in COMMON block MSGBUFFEROUT and returns NOERROR
;-----------------------------------------------------------------------------------------------------
FUNCTION writeToHeadO

	COMMON APP_CONSTANTS
	COMMON MSGCONSTANTS
	COMMON MSGBUFFERIN
	COMMON MSGBUFFEROUT

	if (msgTypeO[headO] NE EMPTYMSGTYPE) THEN BEGIN
		; We have an error; set the error state and return error indicator to caller
		errorStateO = ERR_WRITETOHEAD
		RETURN, ERRORVALUE
	ENDIF ELSE BEGIN
		msgTypeO[headO] = inputTypeO
		msgTextO[*,headO] = msgTextO[*,headO] * 0  ; Clear the current message
		msgTextO[*,headO] = inputTextO
		headO = incMsgBufferPointer(headO)
		RETURN, NOERROR
	ENDELSE

END


;-----------------------------------------------------------------------------------------------------
; Procedure drpCheckMessages
;
; DESCRIPTION:
; 	Checks for incoming messages to the pipeline
;
; ARGUMENTS:
;	None.
;
; KEYWORDS:
;	None.
;
; RETURN VALUE:
;	If message found, modifies variable(s) in COMMON APP_CONSTANTS
;-----------------------------------------------------------------------------------------------------
PRO drpCheckMessages

	COMMON APP_CONSTANTS
	COMMON MSGCONSTANTS
	COMMON MSGBUFFERIN
	COMMON MSGBUFFEROUT

	drpIOLock
	IF (readFromTailI() GT 0) THEN BEGIN
		;PRINT, "drpCheckMessages: Input Msg Type = ", STRTRIM(STRING(returnTypeI), 2)
		;PRINT, "drpCheckMessages: Input Msg Text = ", STRING(returnTextI)

		IF (returnTypeI EQ DESTROYMSGTYPE) THEN BEGIN
			DRPCONTINUE = 0  ; Set a COMMON block variable here
		ENDIF

		; Echo the received message back to the control GUI
		inputTypeO = returnTypeI
		inputTextO = inputTextO * 0  ; Clear the bytes of the message to be created.
		tempBuf = BYTE("Echo: " + STRING(returnTextI))
		neededLen = N_ELEMENTS(tempBuf) - 1
		FOR i = 0, neededLen DO BEGIN
			inputTextO[i] = tempBuf[i]
		ENDFOR
		IF (writeToHeadO() EQ ERRORVALUE) THEN BEGIN
	; ------------------------ TO DO: Figure out what to do with this error    ----------------
			;drpLog, 'Error in call to writeToHeadO() function', /GENERAL, /DRF, Depth=1
		ENDIF
	ENDIF
	drpIOUnlock

END


;-----------------------------------------------------------------------------------------------------
; Procedure drpCheckMessagesDummyMsgs
;
; DESCRIPTION:
; 	Checks for incoming messages to the pipeline and generates random
;	dummy messages via drpDummyMsgGenerator.
;
; ARGUMENTS:
;	None.
;
; KEYWORDS:
;	None.
;
; RETURN VALUE:
;	If message found, modifies variable(s) in COMMON APP_CONSTANTS
;-----------------------------------------------------------------------------------------------------
PRO drpCheckMessagesDummyMsgs

	COMMON APP_CONSTANTS
	COMMON MSGCONSTANTS
	COMMON MSGBUFFERIN
	COMMON MSGBUFFEROUT

	drpIOLock
	IF (readFromTailI() GT 0) THEN BEGIN
		;PRINT, "drpCheckMessagesDummyMsgs: Input Msg Type = ", STRTRIM(STRING(returnTypeI), 2)
		;PRINT, "drpCheckMessagesDummyMsgs: Input Msg Text = ", STRING(returnTextI)

		IF (returnTypeI EQ DESTROYMSGTYPE) THEN BEGIN
			DRPCONTINUE = 0  ; Set a COMMON block variable here
		ENDIF

		; Echo the received message back to the control GUI
		inputTypeO = returnTypeI
		inputTextO = inputTextO * 0  ; Clear the bytes of the message to be created.
		tempBuf = BYTE("Echo: " + STRING(returnTextI))
		neededLen = N_ELEMENTS(tempBuf) - 1
		FOR i = 0, neededLen DO BEGIN
			inputTextO[i] = tempBuf[i]
		ENDFOR
		IF (writeToHeadO() EQ ERRORVALUE) THEN BEGIN
	; ------------------------ TO DO: Figure out what to do with this error    ----------------
			;drpLog, 'Error in call to writeToHeadO() function', /GENERAL, /DRF, Depth=1
		ENDIF
		drpDummyMsgGenerator	; DEBUG CALL
	ENDIF
	drpIOUnlock

END


PRO drpStatusMessage, Msg

	COMMON APP_CONSTANTS
	COMMON MSGCONSTANTS
	COMMON MSGBUFFERIN
	COMMON MSGBUFFEROUT

	drpIOLock
	;Post input message to the Output Message Queue
	inputTypeO = STATUSMSGTYPE
	inputTextO = inputTextO * 0  ; Clear the bytes of the message to be created.
	tempBuf = BYTE(Msg)
	neededLen = N_ELEMENTS(tempBuf) - 1
	IF neededLen GT (MSGLENGTH-1) THEN BEGIN
		tempBuf = BYTE(STRMID(Msg, 0, MSGLENGTH))  ; Remake tempBuf to max allowed length
		neededLen = N_ELEMENTS(tempBuf) - 1  ; This should be MSGLENGTH-1
	END
	FOR i = 0, neededLen DO BEGIN
		inputTextO[i] = tempBuf[i]
	ENDFOR
	IF (writeToHeadO() EQ ERRORVALUE) THEN BEGIN
	; ------------------------ TO DO: Figure out what to do with this error    ----------------
		;drpLog, 'Error in call to writeToHeadO() function', /GENERAL, /DRF, Depth=1
	ENDIF
	drpIOUnlock

END


;------------------------------------------------------------------------------------------
; Procedure drpEvaluate
;
; DESCRIPTION:
; 	DRP_EVALUATE evaluates the return value of a module.  0 indicates success and a non zero 
; 	return value indicates an error within the module.  The procedure makes the appropriate log 
; 	entries and raises an exception if the error is fatal.
;
; ARGUMRNTS:
;	ReturnVal     The return value of the module being evaluated
;	ModuleName    The Name of the module.  This is used for the logging
;
; KEYWORDS:
; 	None.
;-----------------------------------------------------------------------------------------------------
PRO drpEvaluate, ReturnVal, ModuleName

	COMMON APP_CONSTANTS

	; Check for math errors	
	CASE CHECK_MATH() OF
		1:   Msg = 'Integer devided by zero' 
		2:   Msg = 'Integer overflow'
		16:  Msg = 'Floating-point devided by zero'
		32:  Msg = 'Floating-point underflow'
		64:  Msg = 'Floating-point overflow'
		128: Msg = 'Floating point operand error'
		ELSE: Msg = ''
	ENDCASE
	IF Msg NE '' THEN $
		drpLog, 'MATH WARNING IN MODULE ''' + ModuleName + ''': ' + Msg, /GENERAL, /DRF, DEPTH=2

	; Set the message to be logged according to the return value.  
	CASE ReturnVal OF
		ERR_UNKNOWN: MESSAGE, 'unknown error'
		ERR_BADARRAY: MESSAGE, 'Corrupted or uninitialized data array'
		ERR_BADCASE: MESSAGE, 'CASE error: Bad Type'
		ERR_MISSINGFILE: MESSAGE, 'Missing file'
		ERR_CORRUPTFILE: MESSAGE, 'Corrupted file encountered'
		ERR_DISKSPACE: MESSAGE, 'Not enough disk space'
		ERR_MISSINGDIR: MESSAGE, 'missing directory'
		ERR_ALLPIXBAD: MESSAGE, 'All pixels in a frame are bad'
		ERR_CMODULE: MESSAGE, 'C code module returned a non-zero value'
		ERR_BADKEYWORD: MESSAGE, 'Illegal or invalid keyword'
		ERR_WRITETOHEAD: MESSAGE, 'Error writing status message, message queue full'
		OK:  ; Post No Bills
		ELSE: Msg = 'Unknown error'  ; I do not know what this does, Tommer left it.  TMG
	ENDCASE
	IF Msg NE '' THEN $
		drpLog, 'Unknown error IN MODULE ''' + ModuleName + ''': ' + Msg, /GENERAL, /DRF, DEPTH=2

END

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

PRO drpUpdateKeywords, Header, KeywordList, KeywordValues

	COMMON APP_CONSTANTS

	;HELP, Header, /FULL
	FOR i = 0, N_ELEMENTS(KeywordList) - 1 DO BEGIN
		addString = "SXADDPAR, Header, '" + KeywordList[i]  + "', '" + KeywordValues[i] + "', BEFORE='COMMENT'"
		PRINT, addString
		returnValue = EXECUTE(addString)
		PRINT, "returnValue = ", returnValue
	ENDFOR
	;HELP, Header, /FULL
	;PRINT, Header
END

PRO drpSetModulePath, newDRPModulePath
	!PATH = newDRPModulePath
	;PRINT, !PATH
END


;-----------------------------------------------------------------------------------------------------
; Procedure drpLog
;
; DESCRIPTION:
; 	drpLog makes log entries in the general and DRF log files.  Each entry is given a time stamp 
; 	and for entries to the general log file the current procedure is specified
;
;	--- NOTE: Al says "More comments!" and this routine must use syslog.
;
; ARGUMENTS:
;	Text		String to be logged
;	
; KEYWORDS:
;	GENERAL		If this keyword is set, an entry is made in the general log file
;	DRF		If this keyword is set, and entry is made in the DRF log file
;	DEPTH		The level of indentation of the log entry.  The default is 0
;-----------------------------------------------------------------------------------------------------
PRO drpLog, Text, GENERAL=LogGeneral, DRF=LogDRF, DEPTH = TextDepth

	COMMON APP_CONSTANTS

	;HELP, CALLS = A
	;PRINT, 'drpLog: HELP, CALLS = A = ', A
	;PRINT, 'drpLog: Text = ', Text

	Routine = drpPopCallStack()			; Get the name of the calling routine
	drpPushCallStack, Routine			; Replace the name to avoid corrupting
							; the call stack
	
	drpPushCallStack, 'drpLog'

	IF KEYWORD_SET(TextDepth) NE 1 THEN TextDepth = 0	; Default indentation	
	
	Time = STRMID(SYSTIME(), 11, 9)				; Get time stamp

	WHILE STRLEN(Routine) LT 35 DO Routine = Routine + ' '	
	TDString = ''
	FOR i = 1, TextDepth DO TDString = '   ' + TDString 	; Create indentation string
	localText = TDString + Text 				; Create indented log string
	IF KEYWORD_SET(LogGeneral) THEN BEGIN
		drpIOLock
		PRINTF, LOG_GENERAL, Time + ' ' + Routine + localText	; Log to General file
		FLUSH, LOG_GENERAL
		drpIOUnlock
		drpStatusMessage, Time + ' ' + localText		; Send to status queue
	ENDIF
	IF KEYWORD_SET(LogDRF) THEN BEGIN
		drpIOLock
		PRINTF, LOG_DRF, Time + ' ' + localText			; Log to DRF file
		FLUSH, LOG_DRF
		drpIOUnlock
	ENDIF

	void = drpPopCallStack()

END


;-----------------------------------------------------------------------------------------------------
; Procedure drpFITSToDataSet
;
; DESCRIPTION:
; 	drpFITSToDataSet reads a standard data frame FITS file into a structDataSet variable
; ARGUMENTS:
;	DataSet			A pointer to structDataSet variable into which the data is placed
;	FileName		Name and path of the data frame FITS file.
;	FileControl	Control bits that determine which HDUs in FileName are read into memory.
;
; KEYWORDS:
;	None.
; MODIFIED:	tmg 2003/09/11 Change type of data set to FLOAT from UINT (at least for testing)
; 		tmg 2004/02/11 Change to use individual pointers to all data arrays
; 		tmg 2004/04/15 On error, issue a MESSAGE to force a catchable error.
;     tmg 2004/06/30(?) Change code to use one file input instead of three.
; 		tmg 2004/07/12 On error, do not issue a MESSAGE to force a catchable error; instead set
;                    a variable to allow the DRF parser to abort the DRF processing.
; 		tmg 2004/09/09 Add file reading control to select parts of data frames to be read
;-----------------------------------------------------------------------------------------------------
PRO drpFITSToDataSet, DataSet, ValidFrameCount, FileName, FileControl

	COMMON APP_CONSTANTS

	drpPushCallStack, 'drpFITSToDataSet'

  IF continueAfterDRFParsing EQ 1 THEN BEGIN
    IF ValidFrameCount EQ 0 THEN BEGIN  ; Reset current running total on first file of a DRF
      CumulativeMemoryUsedByFITSData = 0L
    ENDIF
    MemoryBeforeReadingFITSFile = MEMORY(/CURRENT)  ; Memory before reading all or part of file
    IF CumulativeMemoryUsedByFITSData LT MaxMemorySizeOfFITSData THEN BEGIN
      drpLog, 'Reading data file: ' + drpXlateFileName(DataSet.InputDir + '/' + FileName), /GENERAL, DEPTH = 1
      drpIOLock
      CATCH, readfitsError
      IF readfitsError EQ 0 THEN BEGIN
        IF (FileControl AND READDATA) EQ READDATA THEN BEGIN
          *DataSet.Frames[ValidFrameCount] = FLOAT(READFITS(drpXlateFileName(DataSet.InputDir + '/' + FileName), Header, /SILENT)) 
          *DataSet.Headers[ValidFrameCount] = Header
        ENDIF
        IF (FileControl AND READNOISE) EQ READNOISE THEN BEGIN
          *DataSet.IntFrames[ValidFrameCount] = FLOAT(READFITS(drpXlateFileName(DataSet.InputDir + '/' + FileName), Header, EXTEN_NO=1, /SILENT))
          IF (FileControl AND READDATA) EQ 0 THEN BEGIN
            *DataSet.Headers[ValidFrameCount] = Header
          ENDIF
        ENDIF
        IF (FileControl AND READQUALITY) EQ READQUALITY THEN BEGIN
          *DataSet.IntAuxFrames[ValidFrameCount] = BYTE(READFITS(drpXlateFileName(DataSet.InputDir + '/' + FileName), Header, EXTEN_NO=2, /SILENT))
          IF (FileControl AND READDATA) EQ 0 THEN BEGIN
            IF (FileControl AND READNOISE) EQ 0 THEN BEGIN
              *DataSet.Headers[ValidFrameCount] = Header
            ENDIF
          ENDIF
        ENDIF
        MemoryAfterReadingFITSFile = MEMORY(/CURRENT)  ; Memory after reading all or part of file
        ; Add memory used by this file to current running total
        CumulativeMemoryUsedByFITSData = CumulativeMemoryUsedByFITSData + (MemoryAfterReadingFITSFile - MemoryBeforeReadingFITSFile)
        drpLog, 'Memory used by FITS files: ' + STRTRIM(STRING(CumulativeMemoryUsedByFITSData), 2), /GENERAL, DEPTH = 1
      ENDIF ELSE BEGIN
        drpLog, 'READFITS() Error on file ' + drpXlateFileName(DataSet.InputDir + '/' + FileName), /GENERAL, DEPTH = 1
        drpLog, 'DRF will be aborted', /GENERAL, DEPTH = 1
        continueAfterDRFParsing = 0
      ENDELSE
      CATCH, /CANCEL
      drpIOUnlock
    ENDIF ELSE BEGIN
      drpLog, 'Already allocated too much memory for this DRF.  ' + STRTRIM(STRING(CumulativeMemoryUsedByFITSData), 2) + ' is currently allocated', /GENERAL, DEPTH = 1
      drpLog, 'DRF will be aborted', /GENERAL, DEPTH = 1
      continueAfterDRFParsing = 0
    ENDELSE
    PRINT, FORMAT='(".",$)'
  ENDIF

	void = drpPopCallStack()

END


;-----------------------------------------------------------------------------------------------------
; Procedure drpDefineStructs
;
; DESCRIPTION:
; 	drpDefineStructs defines the user defined structures used by the program
;
; ARGUMENTS:
;	None.
;
; KEYWORDS:
;	None.
; 2005/01/04 TMG structQueryEntry index is now a string
;-----------------------------------------------------------------------------------------------------
PRO drpDefineStructs

	COMMON APP_CONSTANTS

	drpPushCallStack, 'drpDefineStructs'

	void = {structDataSet, $
			Name:'', $
			InputDir:'', $
			OutputDir:'', $
			ValidFrameCount:0, $
			Frames:PTRARR(MAXFRAMESINDATASETS, /ALLOCATE_HEAP), $
			Headers:PTRARR(MAXFRAMESINDATASETS, /ALLOCATE_HEAP), $
			IntFrames:PTRARR(MAXFRAMESINDATASETS, /ALLOCATE_HEAP), $
			IntAuxFrames:PTRARR(MAXFRAMESINDATASETS, /ALLOCATE_HEAP)}

	void = {structDataPasser, $
			nameCreatorModule:'', $
			dataName:'', $
			pData: PTR_NEW(/ALLOCATE_HEAP)}

	void = {structModule, $
			Name:'', $
			CallSequence:'', $
			Skip:0, $
			Save:0, $
			SaveOnErr:0, $
			OutputDir:'', $
			CalibrationFile:'', $
			LabDataFile:''}

	void = {structQueryEntry, $
			index:'', $
			name:'', $
			status: '', $
			error:''}

	void = {structUpdateList, $
			datasetNumber: 0, $
			headerNumber: 0, $
			parameters:PTR_NEW(/ALLOCATE_HEAP)}

	void = drpPopCallStack()

END


;-----------------------------------------------------------------------------------------------------
; Procedure drpSetStatus
;
; DESCRIPTION:
; 	Sets the status field in the file name of a DRF
;
; ARGUMENTS:
;	DRF		the a structQueryEntry variable for the drf which is to be set
;	Dir		Location of the DRF (usually the queue)
;	Status		The new status to be given
;
; KEYWORDS:
;	None.
;-----------------------------------------------------------------------------------------------------
PRO drpSetStatus, drf, dir, status

	COMMON APP_CONSTANTS
	COMMON MSGBUFFEROUT

	drpPushCallStack, 'drpSetStatus'
	HELP, CALLS=A
	PRINT, A[1]

	; ------------------------ TO DO: Make this platform independent ----------------------------
	; ------------------------ TO DO: This is currently UNIX only    ----------------------------
	origName = dir + STRTRIM(STRING(drf.index), 2) + '.' + drf.name + '.' + drf.status
	newName  = dir + STRTRIM(STRING(drf.index), 2) + '.' + drf.name + '.' + status

	MAXNAMELEN = 1024L
	fromNameAsBytes = BYTARR(MAXNAMELEN)
	toNameAsBytes = BYTARR(MAXNAMELEN)
	fromNameAsBytes[0:MAXNAMELEN-1] = 0B  ; Zero the first buffer
	toNameAsBytes[0:MAXNAMELEN-1] = 0B  ; Zero the second buffer

	msglen = LONG(N_ELEMENTS(BYTE(origName)))  ; Length of original file name
	fromNameAsBytes[0:msglen-1] = BYTE(origName)  ; Copy name to the first buffer
	msglen = LONG(N_ELEMENTS(BYTE(newName)))  ; Length of new file name
	toNameAsBytes[0:msglen-1] = BYTE(newName)  ; Copy name to the second buffer
	drpIOLock
	retval = CALL_EXTERNAL(EXTERNAL_CODE_FILENAME, 'osiris_rename', fromNameAsBytes, toNameAsBytes)
	;retval = CALL_EXTERNAL('/home/tg/idl/osiris_ext_null.so', 'osiris_rename', fromNameAsBytes, toNameAsBytes)
	drpIOUnlock

	IF (retval EQ 0) THEN BEGIN
		; Set the status field in the input drf to the new status value
		drf.status = status
	ENDIF ELSE BEGIN
		drpLog, 'Error in renaming ' + origName + ' to ' + newName, /GENERAL, /DRF, Depth=1
	ENDELSE

	void = drpPopCallStack()

END  


;-----------------------------------------------------------------------------------------------------
; Procedure drpParseQueue
;
; DESCRIPTION:
; 	Parses  '.' separated file names into structQueryEntry variables
;
; ARGUMENTS:
;	Files		An array of '.' separated file names
;
; KEYWORDS:
;	None.
;
; RETURN VALUE:
;	An array of structQueryEntry elements
;
; MODIFIED:
;	2003/04/18 TMG Change return value to match name case (cosmetic)
; 2005/01/04 TMG Change structQueueEntry to structQueryEntry
; 2005/01/04 TMG structQueryEntry index is now a string
;-----------------------------------------------------------------------------------------------------
FUNCTION drpParseQueue, Files

	drpPushCallStack, 'drpParseQueue'

	s = SIZE(files)
	queue = REPLICATE({structQueryEntry, index:'', name:'', status: '', error:''}, s[1])
	if s[0] NE 0 THEN FOR i = 0, s[1] - 1 DO BEGIN
		parsed_file = file_path_name_ext(files[i])
		queue[i].status = STRMID(parsed_file.ext, 1)
		parsed_file = file_path_name_ext(parsed_file.name)
		queue[i].name = STRMID(parsed_file.ext, 1)
		queue[i].index = parsed_file.name
	ENDFOR

	void = drpPopCallStack()	

	RETURN, queue

END


;-----------------------------------------------------------------------------------------------------
; Procedure drpSortQueue
;
; DESCRIPTION:
; 	Sorts an array of structQueryEntry variables according to index.  Uses bubble sort.
;
; ARGUMENTS:
;	Queue		An array of structQueryEntry elements
;
; KEYWORDS:
;	None.
; 2005/01/04 TMG Change structQueueEntry to structQueryEntry
; 2005/01/04 TMG structQueryEntry index is now a string
;-----------------------------------------------------------------------------------------------------
PRO drpSortQueue, Queue

	drpPushCallStack, 'drpSortQueue'

	; Bubble sort the queue.
	n = N_ELEMENTS(Queue)
	FOR i = n - 1, 0, -1 DO BEGIN
		j = i
		WHILE (j LE n-2) DO BEGIN
			IF Queue[j].index GT Queue[j + 1].index THEN BEGIN
				Temp = Queue[j]
				Queue[j] = Queue[j+1]
				Queue[j + 1] = Temp
				j = j + 1		
			ENDIF ELSE j = n
		ENDWHILE
	ENDFOR

	void = drpPopCallStack()
				
END


;-----------------------------------------------------------------------------------------------------
; Function drpGetNextWaitingFile
;
; DESCRIPTION:
;	Combines the funtionality of drpParseQueue and drpSortQueue to obtain
;	a new file name to be analyzed by the main loop of drpBackbone::Run
; It parses  '.' separated file names into structQueryEntry variables
;	then sorts the list to get the return value.
;
; ARGUMENTS:
;	Files		An array of '.' separated file names
;
; KEYWORDS:
;	None.
;
; RETURN VALUE:
;	A structQueueEntry element
;
; MODIFIED:
; 2005/01/04 TMG structQueryEntry index is now a string
;-----------------------------------------------------------------------------------------------------
FUNCTION drpGetNextWaitingFile, Files

	drpPushCallStack, 'drpGetNextWaitingFile'

	IF (SIZE(Files))[0] GT 0 THEN BEGIN
		s = SIZE(files)  ; Get info about the the current list of files available
		; Create an array of structQueryEntry elements
		queue = REPLICATE({structQueryEntry}, s[1])
		if s[0] NE 0 THEN FOR i = 0, s[1] - 1 DO BEGIN
			parsed_file = file_path_name_ext(Files[i])
			queue[i].status = STRMID(parsed_file.ext, 1)
			parsed_file = file_path_name_ext(parsed_file.name)
			queue[i].name = STRMID(parsed_file.ext, 1)
			queue[i].index = parsed_file.name
		ENDFOR

		; Bubble sort the queue.
		n = N_ELEMENTS(queue)
		FOR i = n - 1, 0, -1 DO BEGIN
			j = i
			WHILE (j LE n-2) DO BEGIN
				IF queue[j].index GT queue[j + 1].index THEN BEGIN
					Temp = queue[j]
					queue[j] = queue[j+1]
					queue[j + 1] = Temp
					j = j + 1		
				ENDIF ELSE j = n
			ENDWHILE
		ENDFOR

		void = drpPopCallStack()	
		RETURN, queue[0]
	ENDIF ELSE BEGIN
		void = drpPopCallStack()	
		RETURN, REPLICATE({structQueryEntry}, 1)
	ENDELSE

END


;-----------------------------------------------------------------------------------------------------
; Procedure drpFileNameFromStruct
;
; DESCRIPTION:
; 	Creates a '.' separated file name from a structQueryEntry variable
;
; ARGUMENTS:
;	Dir		Path to be appended to the file name
;	FileStruct	structQueryEntry variable 
;
; KEYWORDS:
;	None.
; MODIFIED:
; 2005/01/04 TMG structQueryEntry index is now a string
;-----------------------------------------------------------------------------------------------------
FUNCTION drpFileNameFromStruct, Dir, FileStruct

	;drpPushCallStack, 'drpFileNameFromStruct'

	RETURN, Dir + FileStruct.Index + '.' + FileStruct.Name + '.' + FileStruct.Status	

	;void = drpPopCallStack()

END


FUNCTION drpGetElemValue, Name, Names, Values

	FOR i = 0, N_ELEMENTS(Names)-1 DO $
		IF Name EQ Names[i] THEN RETURN, Values[i]

END


PRO drpPARAMETERSDefine

	COMMON PARAMS, PARAMETERS

	PARAMETERS = SINDGEN(256,2)	; DEBUG: This makes COMMON PARAMS big enough
					; so that parsing the current drp.params file
					; into it does not screw things up; I think

END


FUNCTION drpParamValue, ParamName

	COMMON PARAMS

	RETURN, drpGetElemValue(ParamName, PARAMETERS[*,0], PARAMETERS[*,1])

END


FUNCTION drpModuleIndexFromName, Modules, ModName

	for i=0, N_ELEMENTS(Modules)-1 DO $
		IF Modules(i).Name EQ ModName THEN RETURN, i	

END

FUNCTION drpDataSetIndexFromName, Data, DataSetName
	FOR i=0, N_ELEMENTS(Data)-1 DO BEGIN
		IF Data(i).Name EQ DataSetName THEN RETURN, i
  ENDFOR

END


FUNCTION drpModuleIndexFromCallSequence, Modules, ModCallSequence

	for i=0, N_ELEMENTS(Modules)-1 DO $
		IF Modules(i).CallSequence EQ ModCallSequence THEN RETURN, i	

END


FUNCTION drpAddParmToCallSequence, Base, Parameter

	Base = Base + ', ' + Parameter
	RETURN, 1

END


; DEBUG Routines

;-----------------------------------------------------------------------------------------------------
; Procedure drpCheckMessagesForTesting
;
; DESCRIPTION:
; 	Checks for incoming messages to the pipeline, but sets flags differently
;	than the regular drpCheckMessages routine
;
; ARGUMENTS:
;	None.
;
; KEYWORDS:
;	None.
;
; RETURN VALUE:
;	If message found, modifies variable(s) in COMMON APP_CONSTANTS
;-----------------------------------------------------------------------------------------------------
PRO drpCheckMessagesForTesting

	COMMON APP_CONSTANTS
	COMMON MSGCONSTANTS
	COMMON MSGBUFFERIN
	COMMON MSGBUFFEROUT

	IF (readFromTailI() GT 0) THEN BEGIN
		;PRINT, "drpCheckMessages: Input Msg Type = ", STRTRIM(STRING(returnTypeI), 2)
		;PRINT, "drpCheckMessages: Input Msg Text = ", STRING(returnTextI)

		IF (returnTypeI EQ ABORTSETMSGTYPE) THEN BEGIN  ; DEBUG
			DRPCONTINUE = 0  ; Set a COMMON block variable here  ; DEBUG
		ENDIF  ; DEBUG

		; Echo the received message back to the control GUI
		inputTypeO = returnTypeI
		inputTextO = inputTextO * 0  ; Clear the bytes of the message to be created.
		tempBuf = BYTE("Echo: " + STRING(returnTextI))
		neededLen = N_ELEMENTS(tempBuf) - 1
		FOR i = 0, neededLen DO BEGIN
			inputTextO[i] = tempBuf[i]
		ENDFOR
		IF (writeToHeadO() EQ ERRORVALUE) THEN BEGIN
	; ------------------------ TO DO: Figure out what to do with this error    ----------------
			;drpLog, 'Error in call to writeToHeadO() function', /GENERAL, /DRF, Depth=1
		ENDIF
	ENDIF

END

PRO drpInfiniteMessageLoop, Invocation

	COMMON APP_CONSTANTS
	COMMON MSGCONSTANTS
	COMMON MSGBUFFERIN
	COMMON MSGBUFFEROUT

	;PRINT, "drpInfiniteMessageLoop: Invocation " + STRING(Invocation)
	;PRINT, "                        About to enter loop looking for messages only..."
	DRPCONTINUE = 1
	WHILE DRPCONTINUE EQ 1 DO drpCheckMessagesForTesting  ; DEBUG: Creates infinite loop at this point...
	DRPCONTINUE = 1

END

PRO drpDummyMsgGenerator

	COMMON APP_CONSTANTS
	COMMON MSGCONSTANTS
	COMMON MSGBUFFERIN
	COMMON MSGBUFFEROUT

	; Generate a random number of between 10 an 20 messages. of random length about 40 to 70 characters
	nMsgs = FIX(RANDOMU(SEED) * 10.) + 10
	FOR i = 1, nMsgs DO BEGIN
		msgLen = FIX(RANDOMU(SEED) * 30.) + 40
		msgText = "Random Message #" + STRING(i) + " "
		neededChars = msgLen - STRLEN(msgText)
		FOR j = 1, neededChars DO msgText = msgText + '*'
		drpStatusMessage, msgText
	ENDFOR
END


PRO drpMemoryMark, text

	COMMON APP_CONSTANTS

	IF DEBUG_ENABLED THEN BEGIN
		PRINT, "vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv"
		PRINT, text
		HELP, /MEMORY
		PRINT, "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
	ENDIF
END


PRO drpMemoryMarkSimple, text

	COMMON APP_CONSTANTS

	IF DEBUG_ENABLED THEN BEGIN
		PRINT, FORMAT='(A, " ", $)', text
		HELP, /MEMORY
	ENDIF
END


;-----------------------------------------------------------------------------------------------------
; Procedure drpRectify
;
; DESCRIPTION:
; 	Calls the osiris_rectify C code rectification routine
;
; ARGUMENTS:
;	pDataname	Pointer to name of data file without extension(s)
;	numiter		Number of iterations
;	weight_limit	Internal but variable parameter to algorithm
;	relaxation	Internal but variable parameter to algorithm
;	slice		Internal but variable parameter to algorithm
;	dataAddress	Pointer to data
;
; KEYWORDS:
;	None.
;-----------------------------------------------------------------------------------------------------
PRO drpRectify, pDataname, numiter, weight_limit, relaxation, slice, dataAddress

	COMMON APP_CONSTANTS
	COMMON MSGBUFFEROUT

	drpPushCallStack, 'drpRectify'

	; ------------------------ TO DO: Make this platform independent ----------------------------
	; ------------------------ TO DO: This is currently UNIX only    ----------------------------

        ; Zero the parameter list variables for the call to osiris_rectify
        MAXNAMELEN = 128L
        argv = BYTARR(MAXNAMELEN, 6)
        argv[0:MAXNAMELEN-1, *] = 0B  ; Zero the buffer

	; The zero'th parameter is always the name of the program to be called
	msglen = LONG(N_ELEMENTS(BYTE('osiris_rectify')))  ; Length
	argv[0:msglen-1, 0] = BYTE('osiris_rectify')        ; Store parameter

	msglen = LONG(N_ELEMENTS(BYTE(BYTE(pDataname))))  ; Length
	argv[0:msglen-1, 1] = BYTE(BYTE(pDataname))        ; Store parameter
	msglen = LONG(N_ELEMENTS(BYTE(numiter)))  ; Length
	argv[0:msglen-1, 2] = BYTE(numiter)        ; Store parameter
	msglen = LONG(N_ELEMENTS(BYTE(weight_limit)))  ; Length
	argv[0:msglen-1, 3] = BYTE(weight_limit)        ; Store parameter
	msglen = LONG(N_ELEMENTS(BYTE(relaxation)))  ; Length
	argv[0:msglen-1, 4] = BYTE(relaxation)        ; Store parameter
	msglen = LONG(N_ELEMENTS(BYTE(slice)))  ; Length
	argv[0:msglen-1, 5] = BYTE(slice)        ; Store parameter

	retval = CALL_EXTERNAL(EXTERNAL_CODE_FILENAME, 'osiris_rectify', argv[*,0], argv[*,1], argv[*,2], argv[*,3], argv[*,4], argv[*,5], dataAddress)

	IF (retval EQ 0) THEN BEGIN
		PRINT, 'Successful return from osiris_rectify'
		FLUSH, -1
	ENDIF ELSE BEGIN
		PRINT, 'Error in osiris_rectify: retval = ', retval
		FLUSH, -1
	ENDELSE

	void = drpPopCallStack()

END

;-----------------------------------------------------------------------------------------------------
; Procedure drp_CALL_mkrecmatrx
;
; DESCRIPTION:
; 	Calls the mkrecmatrx C code rectification routine
;	--------- TO DO: Correct this code, starting with the comments and parameters --------- 
;
; ARGUMENTS:
;	pDataname	Pointer to name of data file without extension(s)
;	numiter		Number of iterations
;	weight_limit	Internal but variable parameter to algorithm
;	relaxation	Internal but variable parameter to algorithm
;	slice		Internal but variable parameter to algorithm
;	dataAddress	Pointer to data
;
; KEYWORDS:
;	None.
;-----------------------------------------------------------------------------------------------------
PRO drp_CALL_mkrecmatrx, pDataname, numiter, weight_limit, relaxation, slice, dataAddress

	COMMON APP_CONSTANTS
	COMMON MSGBUFFEROUT

	drpPushCallStack, 'drpRectify'

	; ------------------------ TO DO: Make this platform independent ----------------------------
	; ------------------------ TO DO: This is currently UNIX only    ----------------------------

        ; Zero the parameter list variables for the call to osiris_rectify
        MAXNAMELEN = 128L
        argv = BYTARR(MAXNAMELEN, 6)
	argv[0:MAXNAMELEN-1, *] = 0B  ; Zero the buffer

	; The zero'th parameter is always the name of the program to be called
	msglen = LONG(N_ELEMENTS(BYTE('osiris_rectify')))  ; Length
	argv[0:msglen-1, 0] = BYTE('osiris_rectify')        ; Store parameter

	msglen = LONG(N_ELEMENTS(BYTE(BYTE(pDataname))))  ; Length
	argv[0:msglen-1, 1] = BYTE(BYTE(pDataname))        ; Store parameter
	msglen = LONG(N_ELEMENTS(BYTE(numiter)))  ; Length
	argv[0:msglen-1, 2] = BYTE(numiter)        ; Store parameter
	msglen = LONG(N_ELEMENTS(BYTE(weight_limit)))  ; Length
	argv[0:msglen-1, 3] = BYTE(weight_limit)        ; Store parameter
	msglen = LONG(N_ELEMENTS(BYTE(relaxation)))  ; Length
	argv[0:msglen-1, 4] = BYTE(relaxation)        ; Store parameter
	msglen = LONG(N_ELEMENTS(BYTE(slice)))  ; Length
	argv[0:msglen-1, 5] = BYTE(slice)        ; Store parameter

	retval = CALL_EXTERNAL(EXTERNAL_CODE_FILENAME, 'osiris_rectify', argv[*,0], argv[*,1], argv[*,2], argv[*,3], argv[*,4], argv[*,5], dataAddress)

	IF (retval EQ 0) THEN BEGIN
		PRINT, 'Successful return from osiris_rectify'
		FLUSH, -1
	ENDIF ELSE BEGIN
		PRINT, 'Error in osiris_rectify: retval = ', retval
		FLUSH, -1
	ENDELSE

	void = drpPopCallStack()

END
