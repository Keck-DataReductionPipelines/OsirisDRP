
;-----------------------------------------------------------------------
; NAME: clip_frames
;
; PURPOSE: clip frames
;
; INPUT : Frames        : pointer array with the data frames
;         nFrames       : number of valid frames 
;         [dev=dev]     : 
;         [sdv=sdv]     :
;         [low=low]     :
;         [noise=noise] :
;
; OUTPUT : boolean vector of length nFrames. 1 stands for valid ('of
;          use') 0 stands for invalid ('not to use')
;
; ALGORITHM :
;         Case nFrames <= 3:  Do nothing, just return to the caller.
;                               too few frames.
;              nFrames  4-6:  Only do a Median check.
;              nFrames 7-12:  Only do a Noise check.
;              nFrames  >12:  Do a Median check followed by a Noise check.
;
; NOTES : the kernel algorithm is originally from Inseok Song and
;         ignores the intframe values
;
; STATUS : untested
;
; HISTORY : 6.8.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

function clip_frames, Frames, nFrames, dev, sdv, low, noise, DEBUG=DEBUG

  vb_Status = intarr(nFrames) + 1

  if ( keyword_set (DEBUG) ) then debug_info, 'DEBUG INFO (clip_frames.pro): Clipping on ' + strtrim(string(nFrames),2) + ' frames.'

  IF (nFrames LE 3) THEN $
     if ( keyword_set (DEBUG) ) then debug_info, 'DEBUG INFO (clip_frames.pro): Too few frames to clip'

  IF ((nFrames gt 3) AND (nFrames le 6)) THEN $
     vb_Status = check_median ( Frames, nFrames, 3, dev, DEBUG = DEBUG )

  IF ((nFrames GE 7) AND (nFrames LT 12)) THEN $
     vb_Status = check_noise(Frames, nFrames, fix(0.8*nFrames), sdv, noise, low, $
                             STATUS = vb_Status, DEBUG = DEBUG )

  IF (nFrames GE 12) THEN BEGIN
     vb_Status = check_median ( Frames, nFrames, fix(0.8*nFrames), dev, DEBUG = DEBUG)
     if ( total(vb_Status) le fix(0.8*nFrames) ) then $
        warning, ['WARNING (clip_frames.pro): Lower limit for number of frames after median checking reached.',$
                  '                           No noise checking done.'] $
     else vb_Status = check_noise (Frames, nFrames, fix(0.8*nFrames), sdv, noise, low, $
                                        STATUS = vb_Status, DEBUG = DEBUG )
  ENDIF

  if ( keyword_set ( DEBUG ) ) then $
     debug_info, 'DEBUG INFO (clip_frames.pro): Clipped out '+strtrim(string(fix(nFrames-total(vb_Status))),2)+' frames.'

  return, vb_Status

END
