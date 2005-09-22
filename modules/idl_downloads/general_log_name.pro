; Generates a new log name for an invocation of a pipeline
FUNCTION general_log_name 
  t = BIN_DATE()
  r = STRING(FORMAT='(%"%04d%02d%02d_%02d%02d")', t[0], t[1], t[2], t[3], t[4])
  r = STRMID(r,2) + "_drp.log"
  RETURN, r
END
