
FUNCTION drpParseFilename, Filename
	CurrentDRF = {structQueryEntry}
	parsed_file = file_path_name_ext(Filename)
	CurrentDRF.status = STRMID(parsed_file.ext, 1)
	parsed_file = file_path_name_ext(parsed_file.name)
	CurrentDRF.name = STRMID(parsed_file.ext, 1)
	CurrentDRF.index = parsed_file.name
    return, CurrentDRF
END

PRO drpResetDRFs, DRFFiles, QueueDir
    IF DRFFiles NE '' AND N_ELEMENTS(DRFFiles) GT 0 THEN BEGIN
        FOR i=0, N_ELEMENTS(DRFFiles)-1 DO BEGIN
            CurrentDRF = drpParseFilename(DRFFiles[i])
            drpSetStatus, CurrentDRF, QueueDir, "waiting"
        ENDFOR
    ENDIF
END

PRO drpTestSingle, QueueDir
  
  ; We have to do this, otherwise the default log directory probably won't exist at runtime.
  SetLogDir = STRING('OSIRIS_DRP_DEFAULTLOGDIR=',QueueDir,FORMAT='(A,A,$)')
  SETENV, SetLogDir
  x = OBJ_NEW('drpBackbone')
  x->Start
  x->ConsumeQueue, QueueDir
  DRFFiles = FILE_SEARCH(QueueDir + "*.done")
  drpResetDRFs, DRFFiles, QueueDir
  DRFFiles = FILE_SEARCH(QueueDir + "*.failed")
  drpResetDRFs, DRFFiles, QueueDir
  x->Finish
  OBJ_DESTROY, x
  
END

;+
; Run all DRP tests,
;-
PRO drpTest
    TestDir = GETENV("OSIRIS_ROOT") + "/tests/"
	TestDirName = TestDir + 'test**/'
	QueueDirArray = FILE_SEARCH(TestDirName)
    IF N_ELEMENTS(QueueDirArray) GT 0 THEN BEGIN
        TESTCONTINUE = 1
        WHILE TESTCONTINUE EQ 1 DO BEGIN
            PRINT, "Testing ", QueueDirArray[0], format="(A,A,'/')"
            drpTestSingle, QueueDirArray[0] + "/"
            IF N_ELEMENTS(QueueDirArray) EQ 1 THEN TESTCONTINUE = 0 $
            ELSE IF N_ELEMENTS(QueueDirArray) GT 1 THEN remove, [0], QueueDirArray
            s = SIZE(QueueDirArray)
        ENDWHILE
    ENDIF
END

