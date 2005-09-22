
pro drpLog, mess, DRF=DRF, DEPTH=DEPTH

end

pro declare_app_constants

	; Application constants
	COMMON APP_CONSTANTS, OK,		$		; Indicates success
			      MAXFILESINDATASET,$       	; Maximum number of slots for input files in a dataset
			      ERR_UNKNOWN,	$		; Error constant:  unknown error
			      ERR_BADARRAY,	$		; Error constant:  corrupted array
			      ERR_MISSINGFILE,	$		; Error constant:  missing file	
			      ERR_CORRUPTFILE,	$		; Error constant:  corrupted file
			      ERR_DISKSPACE,	$   		; Error constant:  lack of disk space
			      ERR_MISSINGDIR,	$		; Error constant:  missing directory
			      ERR_ALLPIXBAD,	$		; Error constant:  All pixels in a frame are bad
			      ERR_WRITETOHEAD			; Error constant:  Error writing status message, message queue full
		
	OK = 0
	MAXFILESINDATASET = 128
	ERR_UNKNOWN = 1
	ERR_BADARRAY = 2
	ERR_MISSINGFILE = 3
	ERR_CORRUPTFILE = 4
	ERR_DISKSPACE = 5
	ERR_MISSINGDIR = 6
	ERR_ALLPIXBAD = 7
	ERR_WRITETOHEAD = 8


end
