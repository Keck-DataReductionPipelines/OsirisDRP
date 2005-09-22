;==============================================================================
PRO clipframes, Frames, IntFrames, dev=dev, sdv=sdv, low=low, noise=noise
;==============================================================================
; performs a check if all input frames are identical statistically...
;
; - IntFrames are "integration frames" contain a weight factor at each pixel
;   assumed to be defined as ( 1/noise^2 ).
; 
; - Frames and IntFrames are "Pointer" variables of array.
;   and assumed that Frames and nFrames are valid 
;   (i.e., same dimension and valid pointers) 
;
; INPUT : Frames        = pointer to input data arrays
;         IntFrames     = pointer to input integration arrays
;
; OUTPUT: Modify "Frames" and "IntFrames" variables after clipping
;
; Algorithm:    
;         Case NumFrames <= 3:  Do nothing, just return to the caller.
;                               too few frames.
;              NumFrames  4-6:  Only do a Median check.
;              NumFrames 7-12:  Only do a Noise check.
;              NumFrames  >12:  Do a Median check followed by a Noise check.
;
; Required subroutines:
;       medianscheck
;       noiseanalysis
; Versions:
;       updated Dec, 2003 by I. Song
;==============================================================================
; Internal parameters::
  IF (not keyword_set(dev))   then dev = 0.10  ; deviation parameter; 1   .. 500 (unit %*100)
  IF (not keyword_set(sdv))   then sdv = 0.20  ; std. dev parameter;  0.1 .. 100 (unit %*100)
  IF (not keyword_set(low))   then low = 0.70  ; low value parameter; 1   ..  90 (unit %*100)
  IF (not keyword_set(noise)) then noise = 0.20; noise parameter;     0.1 .. 100 (unit %*100)

  IF (checkvalidity(Frames,3) NE 0) THEN BEGIN
     drpLog,'In clipimages, Data Frame Pointer variable is invalid!'
     return
  ENDIF; check validity of 'Frames' data
  IF (vheckvalidity(IntFrames,3) NE 0) THEN BEGIN
     drpLog,'In clipimages, Integration Frame Pointer variable is invalid!'
     return
  ENDIF; check validity of 'IntFrames' data

  nFrames = N_ELEMENTS( (*Frames)[0,0,*] ) ; number of 2D frames in input images.
  IndexFrames = INTARR(nFrames)  ; an array holds an index of clipped or non-clipped frames
                                 ; if value = 0 --> "good frame"
                                 ;         >= 1 --> "bad frame (the number indicates a rank)"
                                 ;          =99 --> "noisy frame"

  IF (nFrames LE 3) THEN BEGIN
     drpLog,'N(images)=3 for clipimages, do nothing...'
     ;; Do nothing
  ENDIF ELSE IF ((nFrames GT 3) AND (nFrames LE 6)) THEN BEGIN

     REPEAT BEGIN ; Loop until no frames being dropped any more...
       PreviousNGoods = N_ELEMENTS(WHERE(IndexFrames EQ 0))
       MediansCheck,Frames,IndexFrames,dev
       NewNGoods = N_ELEMENTS(WHERE(IndexFrames EQ 0))
     ENDREP UNTIL ((NewNGoods EQ PreviousNGoods) OR NewNGoods LE 3)

  ENDIF ELSE IF ((nFrames GE 7) AND (nFrames LT 12)) THEN BEGIN

     ; Noise check...
     REPEAT BEGIN
       PreviousNGoods = N_ELEMENTS(WHERE(IndexFrames EQ 0))
       NoiseAnalysis,Frames,IndexFrames,sdv,noise,low
       NewNGoods = N_ELEMENTS(WHERE(IndexFrames EQ 0))
     ENDREP UNTIL ((NewNGoods EQ PreviousNGoods) OR NewNGoods LE 0.2*nFrames)

  ENDIF ELSE IF (nFrames GE 12) THEN BEGIN

     ; Medians check...
     ;; Repeat the checking if any frames keep falling off 
     ;; or until the we reach down to 1/5 of the input frames...
     REPEAT BEGIN ; Loop until no frames being dropped any more...
       PreviousNGoods = N_ELEMENTS(WHERE(IndexFrames EQ 0))
       MediansCheck,Frames,IndexFrames,dev
       NewNGoods = N_ELEMENTS(WHERE(IndexFrames EQ 0))
     ENDREP UNTIL ((NewNGoods EQ PreviousNGoods) OR NewNGoods LE 0.2*nFrames)

     ; Noise check...
     REPEAT BEGIN
       PreviousNGoods = N_ELEMENTS(WHERE(IndexFrames EQ 0))
       NoiseAnalysis,Frames,IndexFrames,sdv,noise,low
       NewNGoods = N_ELEMENTS(WHERE(IndexFrames EQ 0))
     ENDREP UNTIL ((NewNGoods EQ PreviousNGoods) OR NewNGoods LE 0.2*nFrames)

  ENDIF

  GoodFrames = WHERE(IndexFrames EQ 0)
  IF (N_ELEMENTS(WHERE(IndexFrames NE 0)) GE 2) THEN $
      drpLog,'Some frames show higher or lower than expected noise...'

  (*Frames)    =    (*Frames)[*,*,GoodFrames]
  (*IntFrames) = (*IntFrames)[*,*,GoodFrames]

END
