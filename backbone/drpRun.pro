PRO drpRun, QUEUE_DIR=queue_dir

	x = OBJ_NEW('drpBackbone')
	IF KEYWORD_SET(QUEUE_DIR) THEN BEGIN
		initialQueueDir = QUEUE_DIR
	ENDIF ELSE BEGIN
		initialQueueDir = GETENV('DRF_QUEUE_DIR')
	ENDELSE
	initialQueueDir = initialQueueDir + '/'
        print, "                                                    "
        PRINT, "*****************************************************"
        print, "*                                                   *"
        PRINT, "*          OSIRIS DATA REDUCTION PIPELINE           *"
        print, "*                                                   *"
        print, "*                   VERSION 2.1                     *"
        print, "*                                                   *"
        print, "*           James Larkin, Shelley Wright,           *"
        print, "*            Jason Weiss, Mike McElwain,            *"
        print, "*         Christof Iserlohe, Alfred Krabbe,         *"
        print, "*           Tom Gasaway, Tommer Wizanski            *"
        print, "*                                                   *"
        print, "*****************************************************"
	PRINT, "DRF Queue directory = " + initialQueueDir
	x->Run, initialQueueDir
	OBJ_DESTROY, x

END
