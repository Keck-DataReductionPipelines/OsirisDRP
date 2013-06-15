PRO drpRun, QUEUE_DIR=queue_dir

	x = OBJ_NEW('drpBackbone')
	IF KEYWORD_SET(QUEUE_DIR) THEN BEGIN
		initialQueueDir = QUEUE_DIR
	ENDIF ELSE BEGIN
		initialQueueDir = GETENV('DRF_QUEUE_DIR')
	ENDELSE
	initialQueueDir = initialQueueDir + '/'
        backboneDIR = GETENV('OSIRIS_BACKBONE_DIR')
        drpData = GETENV('OSIRIS_DRP_DATA_PATH')
        drpConfig = GETENV('OSIRIS_DRP_CONFIG_FILE')
        IDLversion = !version.release
        print, "                                                    "
        PRINT, "*****************************************************"
        print, "*                                                   *"
        PRINT, "*          OSIRIS DATA REDUCTION PIPELINE           *"
        print, "*                                                   *"
        print, "*###################################################*"
        print, "*                                                   *"
        print, "*                   VERSION 3.2                     *"
        print, "*                                                   *"
        print, "*           James Larkin, Shelley Wright,           *"
        print, "*            Jason Weiss, Mike McElwain,            *"
        print, "*                 Marshall Perrin,                  *"
        print, "*         Christof Iserlohe, Alfred Krabbe,         *"
        print, "*           Tom Gasaway, Tommer Wizanski,           *"
        print, "*              Randy Campbell, Jim Lyke             *" 
        print, "*                                                   *"
        print, "*****************************************************"
	PRINT, "DRF Queue directory = " + initialQueueDir
        PRINT, "BACKBONE directory = " + backboneDir
        PRINT, "DRP Data Path = " + drpData
        PRINT, "DRP Config File = " + drpConfig
        PRINT, "IDL Version = " + IDLversion
	x->Run, initialQueueDir
	OBJ_DESTROY, x

END
