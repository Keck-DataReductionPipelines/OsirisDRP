
RESOLVE_ALL, RESOLVE_PROCEDURE='drpRun', /CONTINUE_ON_ERROR
FILES = FILE_SEARCH(getenv("OSIRIS_IDL_BASE") + "/modules/*_[0-9][0-9][0-9].pro")
FOR I=0, N_ELEMENTS(FILES)-1 DO $
        RESOLVE_ALL, RESOLVE_EITHER=FILE_BASENAME(FILES[I], '.pro'), /CONTINUE_ON_ERROR
