        FUNCTION FXPOSIT, XFILE, EXT_NO, readonly=readonly, COMPRESS=COMPRESS, $
                 SILENT = Silent 
;+
; NAME:
;     FXPOSIT
; PURPOSE:
;     Return the unit number of a FITS file positioned at specified extension
; EXPLANATION:
;     The FITS file will be ready to be read at the beginning of the 
;     specified extension.
;
; CALLING SEQUENCE:
;     unit=FXPOSIT(FILE, EXT_NO, /READONLY, COMPRESS=program, /SILENT)
;
; INPUT PARAMETERS:
;     FILE    = FITS file name, scalar string
;     EXT_NO  = Extension to be moved to, scalar nonnegative integer
;
; RETURNS:
;     Unit number of file or -1 if an error is detected.
;
; OPTIONAL KEYWORD PARAMETER:
;     /READONLY - If this keyword is set and non-zero, then OPENR rather 
;                than OPENU will be used to open the FITS file.
;     COMPRESS - If this keyword is set and non-zero, then then treat
;                the file as compressed.  If 1 assume a gzipped file.
;                Where possible use IDLs internal decompression
;                facilities (i.e., v5.3 or greater) or on Unix systems
;                spawn off a process to decompress and use its output
;                as the FITS stream.  If the keyword is not 1, then
;                use its value as a string giving the command needed for
;                decompression.
;     /SILENT    If set, then suppress any messages about invalid characters
;                in the FITS file.
;
; COMMON BLOCKS:
;      None.
; SIDE EFFECTS:
;      Opens and returns the descriptor of a file.
; PROCEDURE:
;      Open the appropriate file, or spawn a command and intercept
;      the output.
;      Call FXMOVE to get to the appropriate extension.
; PROCEDURE CALLS:
;      EXPAND_TILDE() (Unix only), FXPAR(), FXMOVE()
; MODIFICATION HISTORY:
;      Derived from William Thompson's FXFINDEND routine.
;      Modified by T.McGlynn, 5-October-1994.
;       Modified by T.McGlynn, 25-Feb-1995 to handle compressed
;          files.  Pipes cannot be accessed using FXHREAD so
;          MRD_HREAD was written.
;       W. Landsman 23-Apr-1997    Force the /bin/sh shell when uncompressing 
;       W. Landsman 26-May-1997    Non-unix is not just VMS
;       T. McGlynn  22-Apr-1999    Add /binary modifier needed for Windows
;       T. McGlynn  03-June-1999   Use /noshell option to get rid of processes left by spawn.
;                                  Use findfile to retain ability to use wildcards
;       W. Landsman 03-Aug-1999    Use EXPAND_TILDE under Unix to find file
;       T. McGlynn  04-Apr-2000    Put reading code into FXMOVE,
;                                  additional support for compression from D.Palmer.
;       W. Landsman/D.Zarro 04-Jul-2000    Added test for !VERSION.OS EQ 'Win32' (WinNT)
;       W. Landsman    12-Dec-2000 Added /SILENT keyword
;       W. Landsman April 2002     Use FILE_SEARCH for V5.5 or later
;-
;
        ON_ERROR,2
        FORWARD_FUNCTION FILE_SEARCH       ;For pre-V5.5 compatibility
;
;  Check the number of parameters.
;
        IF N_PARAMS() LT 2 THEN BEGIN 
            PRINT,'SYNTAX:  UNIT = FXPOSIT(FILE, EXT_NO, /Readonly, compress=prog)'
            RETURN,-1
        ENDIF

        IF !VERSION.RELEASE GE '5.5' THEN $
           FILE = FILE_SEARCH(XFILE, COUNT=COUNT) ELSE BEGIN

; Expand wildcards in name.    Compensate that FINDFILE doesn't recognize
; the meaning of the Unix tilde.

        IF !VERSION.OS_FAMILY EQ 'unix' THEN BEGIN
	    IF STRPOS(XFILE,'~') NE -1 THEN XFILE = EXPAND_TILDE(XFILE)
	    FILE = FINDFILE(REPSTR(XFILE," ","\ "), COUNT=COUNT)
	ENDIF ELSE FILE = FINDFILE(XFILE, COUNT=COUNT)
        ENDELSE

        IF COUNT EQ 0 THEN BEGIN
            RETURN, -1   ; Don't print anything out, just report an error
        ENDIF
        
        FILE = FILE[0]
;
;  Check if this is a compressed file.
;
        UNIT = -1

        UCMPRS = ' '
	IF KEYWORD_SET(compress) THEN BEGIN
	    IF strcompress(string(compress),/remo) eq '1' THEN BEGIN
	        compress = 'gunzip'
	    ENDIF
	    UCMPRS = compress;
	ENDIF ELSE BEGIN
        
            LEN = STRLEN(FILE)
            IF LEN GT 3 THEN BEGIN
	        TAIL = STRMID(FILE, LEN-3, 3)
	    ENDIF ELSE BEGIN
		TAIL = ' '
	    ENDELSE
	    
            IF STRMID(TAIL,1,2) EQ '.z' OR STRMID(TAIL,1,2) EQ '.Z' THEN BEGIN
                UCMPRS = 'uncompress'
	    ENDIF ELSE IF TAIL EQ '.gz'  OR TAIL EQ '.GZ' THEN BEGIN
	        UCMPRS = 'gunzip'
	    ENDIF
	    
	ENDELSE
                
;  Handle compressed files.
	IF UCMPRS EQ 'gunzip' AND !version.release GE 5.3 THEN BEGIN
	        
                IF KEYWORD_SET(READONLY) THEN BEGIN
                    OPENR, UNIT, FILE, /COMPRESS, /GET_LUN, /BLOCK, /BINARY, ERROR = ERROR
                ENDIF ELSE BEGIN
                    OPENU, UNIT, FILE, /COMPRESS, /GET_LUN, /BLOCK, /BINARY, ERROR = ERROR
                ENDELSE

	ENDIF ELSE IF UCMPRS NE ' ' THEN BEGIN
		
                IF (!VERSION.OS_FAMILY EQ 'unix') THEN BEGIN
                        SPAWN, [UCMPRS,'-c',FILE], UNIT=UNIT, /NOSHELL
                ENDIF ELSE BEGIN
                        PRINT, 'MRDFITS: Only Unix IDL supports piped spawns'
                        PRINT, '         File must be uncompressed manually'
                        RETURN, -1                      
                ENDELSE
                
        ENDIF ELSE BEGIN
;
;  Go to the start of the file.
;
                IF KEYWORD_SET(READONLY) THEN BEGIN
                        OPENR, UNIT, FILE, /GET_LUN, /BLOCK, /BINARY, ERROR = ERROR
                ENDIF ELSE BEGIN
                        OPENU, UNIT, FILE, /GET_LUN, /BLOCK, /BINARY, ERROR = ERROR
                ENDELSE
                IF ERROR NE 0 THEN BEGIN
                        PRINT,!ERR_STRING
                        RETURN,-1
                ENDIF
        ENDELSE

        IF EXT_NO LE 0 THEN RETURN, UNIT
	STAT = FXMOVE(UNIT, EXT_NO, SILENT = Silent)
	IF STAT LT 0 THEN BEGIN
	    RETURN, STAT
	ENDIF ELSE BEGIN
	    RETURN, UNIT
	ENDELSE
END


