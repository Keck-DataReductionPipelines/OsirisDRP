PRO drpRun, QUEUE_DIR=queue_dir

	x = OBJ_NEW('drpBackbone')
	IF KEYWORD_SET(QUEUE_DIR) THEN BEGIN
		initialQueueDir = QUEUE_DIR
	ENDIF ELSE BEGIN
		initialQueueDir = GETENV('DRF_QUEUE_DIR')
	ENDELSE
	initialQueueDir = initialQueueDir + '/'
	PRINT, "DRF Queue directory = " + initialQueueDir
	x->Run, initialQueueDir
	OBJ_DESTROY, x

END
