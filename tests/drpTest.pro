
FUNCTION drpParseFilename, Filename
	CurrentDRF = {structQueryEntry}
	parsed_file = file_path_name_ext(Filename)
	CurrentDRF.status = STRMID(parsed_file.ext, 1)
	parsed_file = file_path_name_ext(parsed_file.name)
	CurrentDRF.name = STRMID(parsed_file.ext, 1)
	CurrentDRF.index = parsed_file.name
    return, CurrentDRF
END

PRO drpTestSingle, Filename
  
  parsed = FILE_PATH_NAME_EXT(Filename)
  QueueDir = parsed.path
  
  ; We have to do this, otherwise the default log directory probably won't exist at runtime.
  SetLogDir = STRING('OSIRIS_DRP_DEFAULTLOGDIR=',parsed.path,FORMAT='(A,A,$)')
  SETENV, SetLogDir
  x = OBJ_NEW('drpBackbone')
  x->Start
  CurrentDRF = drpParseFilename(Filename)
  x->DoSingle, CurrentDRF, QueueDir
  drpSetStatus, CurrentDRF, QueueDir, "waiting"
  x->Finish
  OBJ_DESTROY, x
  
END

;+
; Run all DRP tests,
;-
PRO drpTest
    TestDir = GETENV("OSIRIS_ROOT") + "/tests/"
	TestDirName = TestDir + 'test**/*.waiting'
	FileNameArray = FILE_SEARCH(TestDirName)
    s = SIZE(FileNameArray)
    IF s[0] GT 0 THEN BEGIN
        FOR i=0, s[0] DO BEGIN
            PRINT, "Testing ", FileNameArray[i], format="(A,A)"
            drpTestSingle, FileNameArray[i]
        ENDFOR
    ENDIF
END

