PRO drpRunSingle, Filename
  
  parsed = FILE_PATH_NAME_EXT(Filename)
  QueueDir = parsed.path
  
  ; We have to do this, otherwise the default log directory probably won't exist at runtime.
  SetLogDir = STRING('OSIRIS_DRP_DEFAULTLOGDIR=',parsed.path,FORMAT='(A,A,$)')
  SETENV, SetLogDir
  x = OBJ_NEW('drpBackbone')
  x->Start
  x->DoFile, Filename, QueueDir
  x->Finish
  OBJ_DESTROY, x
END