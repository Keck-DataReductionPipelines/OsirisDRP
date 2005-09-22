;==============================================================================
PRO noiseanalysis, Frames, IndexFrames, sdv, noise, low
;==============================================================================
; A subroutine used in the clipimages.pro
;
; - Calculate Noise Analysis 
;   see Module description (for clipimages) for details
;
; - OUTPUT : Only update IndexFrames; Frames are not changed.
;            IndexFrames
;
; Versions:
;       updated Dec, 2003 by I. Song
;==============================================================================
     GoodFrames = WHERE(IndexFrames EQ 0)
     GoodData   = (*Frames)[*,*,GoodFrames]
     nFrames    = N_ELEMENTS(GoodFrames)

     AveragedFrame = TOTAL(GoodData,3) / nFrames ; 2D images
     MedianOfAverage = MEDIAN (AveragedFrame)     ; a scalar
     ValidPixels=WHERE((ABS(AveragedFrame-MedianOfAverage)/MedianOfAverage) < (noise/2.0), count )
     If (count LE 0) THEN BEGIN
        print,'There is no valid pixels!'
        return
     ENDIF
     DimX    = N_ELEMENTS( (*Frames)[*,0,0] ) ; dimension of X
     DimY    = N_ELEMENTS( (*Frames)[0,*,0] ) ; dimension of Y
     ValPX = ValidPixels MOD DimX
     ValPY = ValidPixels / DimX
     
     SDV_Valids = FLTARR(nFrames)
;    print,nFrames,ValPX,ValPY
     FOR i=0,nFrames-1 DO BEGIN
         SDV_Valids[i] = STDDEV(GoodData[ValPX,ValPY,i]) ; a vector of nFrames elements
     ENDFOR
     MeanOfSDV = MEAN(SDV_Valids)                        ; a scalar
     Deviates = (SDV_Valids - MeanOfSDV)/MeanOfSDV

     SortDevs = SORT(Deviates)

     IF (Deviates[SortDevs[nFrames-1]] GT (sdv/2.0)) THEN BEGIN
         print,'One noisy frame discarded...'
         IndexFrames[ GoodFrames[SortDevs[nFrames-1]] ] = 99   ; set value as '99' for noise clipped frames.
     ENDIF 

     IF (Deviates[SortDevs[0]] LT (-sdv/2.0)) THEN BEGIN
        IF (SDV_Valids[SortDevs[0]] LT (low*MeanOfSDV)) THEN BEGIN
            print,'One quiet frame discarded...'
            IndexFrames[ GoodFrames[SortDevs[0]] ] = 99
        ENDIF ELSE BEGIN
            IF ((SDV_Valids[SortDevs[1]] GE low*MeanOfSDV) AND (Deviates[SortDevs[1]] LT (-sdv/2.0)) ) THEN BEGIN
               print,'One noisy frame discarded...'
               IndexFrames[ GoodFrames[SortDevs[0]] ] = 99
            ENDIF 
        ENDELSE
     ENDIF
END
