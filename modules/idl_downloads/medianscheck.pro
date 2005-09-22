;==============================================================================
PRO medianscheck, Frames, IndexFrames, dev
;==============================================================================
; A subroutine used in the clipiamges.pro
;
; - Calculate Medians and Mean of the Medians of each input frames
;   and see if any one of them is "OFF" from the others
; - OUTPUT : Only update IndexFrames; Frames is not changed.
;            IndexFrames
;
; Versions:
;       updated Dec, 2003 by I. Song
;==============================================================================
     GoodFrames = WHERE(IndexFrames EQ 0)
     GoodData = (*Frames)[*,*,GoodFrames]
     nFrames = N_ELEMENTS(GoodFrames)

     nRepeats = MAX(IndexFrames) ; value of "IndexFrames" indicates the status of the frame
                                 ; 0 : the frame is good
                                 ; 1 : the frame is the most deviated (noisy) frame among input Frames
                                 ; 2 : the frame is the 2nd most deviated (noisy) frame.
                                 ; 3 : the frame is the 3rd most deviated (noisy) frame.
                                 ; and so on.
     Medians=fltarr(nFrames)
     FOR i=0,nFrames-1 DO Medians[i] = MEDIAN (GoodData[*,*,i])
     MeanOfMedian = MEAN(Medians)
     NormMeanOfMedian = (MeanOfMedian-Medians)/MeanOfMedian
     Indicies = SORT(ABS(NormMeanOfMedian))
     IF (ABS(NormMeanOfMedian(Indicies[nFrames-1])) GT dev) THEN BEGIN
        print,'One frame discarded in MediansCheck procedure...'
        IndexFrames[ GoodFrames[Indicies[nFrames-1]] ] = nRepeats + 1
     ENDIF
END
