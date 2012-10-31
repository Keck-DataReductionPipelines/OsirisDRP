PRO drpRun, QUEUE_DIR=queue_dir

	x = OBJ_NEW('drpBackbone')
	IF KEYWORD_SET(QUEUE_DIR) THEN BEGIN
		initialQueueDir = QUEUE_DIR
	ENDIF ELSE BEGIN
		initialQueueDir = GETENV('DRF_QUEUE_DIR')
	ENDELSE
	initialQueueDir = initialQueueDir + '/'
        backboneDIR = GETENV('OSIRIS_BACKBONE_DIR')
        print, "                                                    "
        PRINT, "*****************************************************"
        print, "*                                                   *"
        PRINT, "*          OSIRIS DATA REDUCTION PIPELINE           *"
        print, "*                   Development                     *"
        print, "*                   VERSION 3.0                     *"
        print, "*                                                   *"
        print, "*           James Larkin, Shelley Wright,           *"
        print, "*            Jason Weiss, Mike McElwain,            *"
        print, "*                 Marshall Perrin,                  *"
        print, "*         Christof Iserlohe, Alfred Krabbe,         *"
        print, "*           Tom Gasaway, Tommer Wizanski            *"
        print, "*                                                   *"
        print, "*****************************************************"
	PRINT, "DRF Queue directory = " + initialQueueDir
        PRINT, "BACKBONE directory = " + backboneDir
	x->Run, initialQueueDir
	OBJ_DESTROY, x

END
