        FUNCTION FIND_WITH_DEF, FILENAME, PATHS, EXTENSIONS,    $
                NOCURRENT=NOCURRENT, RESET=RESET
;+
; NAME: 
;     FIND_WITH_DEF()
; PURPOSE: 
;     Searches for files with a default path and extension.
; EXPLANATION:
;     Finds files using default paths and extensions, similar to using the
;     DEFAULT keyword with the OPEN statement in VMS.  Using this routine
;     together with environment variables allows an OS-independent approach
;     to finding files.
; CALLING SEQUENCE: 
;     Result = FIND_WITH_DEF( FILENAME, PATHS  [, EXTENSIONS ] )
;
; INPUTS: 
;     FILENAME   = Name of file to be searched for.  It may either be a
;                    complete filename, or the path or extension could be left
;                    off, in which case the routine will attempt to find the
;                    file using the default paths and extensions.
;
;     PATHS      = One or more default paths to use in the search in case
;                    FILENAME does not contain a path itself.  The individual
;                    paths are separated by commas, although in UNIX, colons
;                    can also be used.  In other words, PATHS has the same
;                    format as !PATH, except that commas can be used as a
;                    separator regardless of operating system.  The current
;                    directory is always searched first, unless the keyword
;                    NOCURRENT is set.
;
;                    A leading $ can be used in any path to signal that what
;                    follows is an environmental variable, but the $ is not
;                    necessary.  (In VMS the $ can either be part of the path,
;                    or can signal logical names for compatibility with Unix.)
;                    Environmental variables can themselves contain multiple
;                    paths.
;
; OPTIONAL INPUTS: 
;     EXTENSIONS = One or more extensions to append to end of filename if the
;                    filename does not contain one (e.g. ".dat").  The period
;                    is optional.  Multiple extensions can be separated by
;                    commas or colons.
; OUTPUTS: 
;     The result of the function is the name of the file if successful, or
;     the null string if unsuccessful.
; OPTIONAL INPUT KEYWORDS: 
;     NOCURRENT = If set, then the current directory is not searched.
;
;      RESET      = The FIND_WITH_DEF routine supports paths which are
;                    preceeded with the plus sign to signal that all
;                    subdirectories should also be searched.  Often this is
;                    used with logical names.  It can be rather slow to search
;                    through these subdirectories.  The /RESET keyword can be
;                    used to redefine an environment variable so that
;                    subsequent calls don't need to look for the
;                    subdirectories.
;
;                    To use /RESET, the PATHS parameter must contain the name
;                    of a *single* environment variable.  For example
;
;                     setenv,'FITS_DATA=+/datadisk/fits'
;                     file = find_with_def('test.fits','FITS_DATA',/reset)
;
; EXAMPLE:
;
;       FILENAME = ''
;       READ, 'File to open: ', FILENAME
;       FILE = FIND_WITH_DEF( FILENAME, 'SERTS_DATA', '.fix' )
;       IF FILE NE '' THEN ...
;
;
; PROCEDURE CALLS: 
;       BREAK_PATH(), FIND_ALL_DIR()
; REVISION HISTORY: 
;       Version 1, William Thompson, GSFC, 3 May 1993.
;               Removed trailing / and : characters.
;               Fixed bugs
;               Allow for commas within values of logical names.
;               Added keyword NOCURRENT.
;               Changed to call BREAK_PATH
;       Version 2, William Thompson, GSFC, 3 November 1994
;               Made EXTENSIONS optional.
;       Version 3, William Thompson, GSFC, 30 April 1996
;               Call FIND_ALL_DIR to resolve any plus signs.
;       Version 4, S.V. Haugan, UiO, 5 June 1996
;               Using OPENR,..,ERROR=ERROR to avoid an IDL 3.6
;               internal nesting error.
;       Version 5, R.A. Schwartz, GSFC, 11 July 1996
;               Use SPEC_DIR to interpret PATH under VMS
;       Version 6, William Thompson, GSFC, 5 August 1996
;               Took out call to SPEC_DIR (i.e., reverted to version 4).  The
;               use of SPEC_DIR was required to support logical names defined
;               via SETLOG,/CONFINE.  However, it conflicted with the ability
;               to use logical names with multiple values.  Removing the
;               /CONFINE made it unnecessary to call SPEC_DIR in this routine.
;       Version 7, William Thompson, GSFC, 6 August 1996
;               Added keyword RESET
;       Converted to IDL V5.0   W. Landsman   October 1997
;       Use STRTRIM instead of TRIM,   W. Landsman   November 1998
;       Use STRSPLIT instead of STR_SEP(), V5.3 or later W.L.   July 2002
;-
;
        ON_ERROR, 2
        FORWARD_FUNCTION strsplit            ;Pre V5.3 compatibility
;
;  Check the number of parameters:
;
        IF N_PARAMS() LT 2 THEN MESSAGE, 'Syntax:  Result = ' + $
                'FIND_WITH_DEF(FILENAME, PATHS [, EXTENSIONS])'
;
;  If there are any plus signs, then expand them.
;
        PATH = FIND_ALL_DIR(PATHS, /PLUS_REQUIRED, /PATH, RESET=RESET)
;
;  Reformat PATHS into an array.  The first element is the null string.
;
        PATH = BREAK_PATH(PATH)
;
;  If NOCURRENT was set, then remove the first (blank) entry from the PATH
;  array.
;
        IF KEYWORD_SET(NOCURRENT) THEN PATH = PATH[1:*]
;
;  Reformat EXTENSIONS into an array.  The first element is the null string.
;
       EXT = '' 
       IF N_PARAMS() EQ 3 THEN BEGIN
       if !VERSION.RELEASE GE '5.3' THEN $
            EXT = ['',STRSPLIT(EXTENSIONS,',:',/EXTRACT)] ELSE BEGIN
                TEMP = STR_SEP(EXTENSIONS,',')
                FOR I = 0,N_ELEMENTS(TEMP)-1 DO         $
                        EXT = [EXT, STR_SEP(TEMP[I],':')]
        ENDELSE
        ENDIF
;
;  Make sure that the extensions begin with a period.
;
        FOR I = 0,N_ELEMENTS(EXT)-1 DO IF EXT[I] NE '' THEN     $
                IF STRMID(EXT[I],0,1) NE '.' THEN EXT[I] = '.' + EXT[I]
;
;  Set up variables used by the loops below.
;
        I_PATH = -1
        I_EXT = -1
        GET_LUN, UNIT
;
;  Step through each of the paths.
;
NEXT_PATH:
        I_PATH = I_PATH + 1
        IF I_PATH GE N_ELEMENTS(PATH) THEN GOTO, NO_FILE
        PTH = PATH[I_PATH]
;
;  Step through each of the extensions.
;
NEXT_EXT:
        I_EXT = I_EXT + 1
        IF I_EXT GE N_ELEMENTS(EXT) THEN BEGIN
                I_EXT = -1
                GOTO, NEXT_PATH
        ENDIF
        EX = EXT[I_EXT]
;
;  Try to open the file.  Note:  ON_IOERROR and OPENR are used instead of
;  FINDFILE because it is much faster.
;
        ON_IOERROR, NEXT_EXT
        FILE = PTH + STRTRIM(FILENAME,2) + EX
        OPENR, UNIT, FILE,error=error    ;; Added use of error status instead
        IF error NE 0 THEN GOTO,NEXT_EXT ;; of counting on ON_IOERROR.
        !ERR = 0
        GOTO, DONE
;
;  If we reach this point, then no file has been found.
;
NO_FILE:
        FILE = ''
;
;  Otherwise, we jump directly to here when we find a file.
;
DONE:
        FREE_LUN, UNIT
        RETURN, FILE
        END
