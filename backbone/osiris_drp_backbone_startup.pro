; Check to see if we need to use an alternate DRF queue
alt_drf_queue = GETENV('OSIRIS_ALTERNATE_DRF_QUEUE_DIR')
;PRINT, ''
;PRINT, 'To change the DRF queue directory set the environment variable'
;PRINT, 'OSIRIS_ALTERNATE_DRF_QUEUE_DIR to the new queue directory and then'
;PRINT, 're-run the pipeline'
;PRINT, ''
; start backbone
IF alt_drf_queue eq '' THEN $
  drpRun $
ELSE $
  drpRun, QUEUE_DIR=alt_drf_queue
