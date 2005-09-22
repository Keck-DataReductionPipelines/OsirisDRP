PRO weightedmean, Frames, ErrFrames, pWeightedMean, pNewIntFrame
; calculate weighted mean of XxYxN where N is a number of input data frames
;
; - ErrFrames are "noise frames" contain noise values.
; 
; - Frames and ErrFrames are "Pointer" variables of array.
;   and assumed that Frames and nFrames are valid 
;   (i.e., same dimension and valid pointers) 
;
; INPUT : Frames        = pointer to input data arrays
;         ErrFrames     = pointer to input integration arrays
;
; OUTPUT: pWeightedMean = pointer to the weighted mean frame
;         pNewIntFrame  = pointer to the updated integration frame
;
; Algorithm:    
;         weighted mean = Sum ( Si * Wi ) / Sum (Wi), 
;                               where Si is signal, Wi is associated weight.
;         std. dev. of weighted mean = 1 / SQRT( Sum(Wi) )  == 1 sigma of W.M.
;         new weight    = SQRT(Sum((Si-Wgt.mean)^2)/(n_elements(Si)-1))
;
; updated Nov, 2003 by I. Song
;==============================================================================
  nFrames    = N_ELEMENTS( (*Frames)[0,0,*] )
  
  IF (nFrames LE 1) THEN BEGIN
    drpLog,'Attempt to calculated an weighted average on single frame!'
    return   ;; nothing to do with one frame!
  ENDIF ELSE BEGIN
    IntFrames=1.0/((*ErrFrames)^2)
    WeightedMean = TOTAL((*Frames)*(IntFrames), 3) / TOTAL(IntFrames,3)
    NewIntFrame  = 1.0/SQRT( TOTAL(IntFrames,3) )
    IF NOT ptr_valid(pWeightedMean) THEN $
           pWeightedMean =ptr_new(WeightedMean,/ALLOCATE_HEAP)
    IF NOT ptr_valid(pNewIntFrame)  THEN $
           pNewIntFrame  =ptr_new(NewIntFrame, /ALLOCATE_HEAP)
  ENDELSE

  RETURN
END
