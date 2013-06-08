;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; @BEGIN
;
; NAME: fix_badelem_matrices 
;
; PURPOSE: Fix bad array elements within the reduced influence
;	rectification matrices (OSIRIS calibration files) 
;
;	There are three extension files in the calibration files
;	which defines the (x,y) location of the spectra across 
;	the detector from each lenslet.
;
;	Extension 0: [2,1216] - x,y location for each lenset
;	Extension 1: [1216] - vertical position on the detector 
;		where they are extracted
;	Extension 2: [2048, 16, 1216] - Images [2048,16] for all
;		1215 spectra (independent of narrow or broadbands)
;		Each spectrum on the detector is separated by 16
;		pixels
;
; MODIFICATION:
;	written by Shelley Wright (Dec 2009)
;
;;;
FUNCTION mkcleanrect_000, DataSet, Modules, Backbone

    COMMON APP_CONSTANTS

    functionName = 'glitchid_000'
    ; save the starting time
    T = systime(1)

    drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1




END
