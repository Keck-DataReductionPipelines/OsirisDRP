;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; NAME:  cleancosmic_000
;
; PURPOSE: Attempts to identify and remove pixele that are damaged by
; cosmic rays. It only works on 2-d cubes.
;
; STATUS : prototype
;
; NOTES : 
;
; ALGORITHM :
; REQUIRED ROUTINE :
;
; HISTORY : Oct 3, 2005    created
;           June 8, 2006   modified to work on raw data instead of cubes
;	    Sept 16, 2016  complete change to old algorithm which was NOT
;				written by James Larkin :) It was entirely
;				S/N driven and clipped bright pixels in lines!
;
; AUTHOR : created by James Larkin
;-----------------------------------------------------------------------
FUNCTION cleancosmic_000, DataSet, Modules, Backbone

COMMON APP_CONSTANTS

functionName = 'cleancosmic_000'

drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1

nFrames = Backbone->getValidFrameCount(DataSet.Name)
indx = lindgen(100)

for i = 0, nFrames-1 do begin
    ; Setup local pointers to the frames
    Frame       = *DataSet.Frames[i]
    IntFrame    = *DataSet.IntFrames[i]
    IntAuxFrame = *DataSet.IntAuxFrames[i]
    sz = size(Frame)
    if ( sz[0] ne 2 ) then $
      return, error ( ['FAILURE (' + strtrim(functionName,2) + '):', $
                       '        In Set ' + strtrim(string(i+1),2) + $
                       ' Frame must be 2 dimensional.'] )
    if ( sz[1] ne 2048 ) then $
      return, error ( ['FAILURE (' + strtrim(functionName,2) + '):', $
                       '        In Set ' + strtrim(string(i+1),2) + $
                       ' X-Spatial axis is not 2048 pixels.'] )
    if ( sz[2] ne 2048 ) then $
      return, error ( ['FAILURE (' + strtrim(functionName,2) + '):', $
                       '        In Set ' + strtrim(string(i+1),2) + $
                       ' Y-Spatial axis is not 2048 pixels.'] )

    ; Repeat search for bad pixels twice
    for qq = 0, 1 do begin 
         for j = 1, 2046 do begin  ; columns, Routine requires 3x3 region to calculate stdev
            for ii = 1, 2046 do begin ; rows
                smalla=Frame[ii-1:ii+1, j-1:j+1] ; 3x3 pixel region to calculate median and stdev
                smallb=IntAuxFrame[ii-1:ii+1, j-1:j+1] ; 3x3 array to check if pixels are valid
		; We only want to use valid pixels not already flagged to 0.
                isok = where( smallb eq 9 )
                notok = where( smallb ne 9)
                if ( isok[0] ne -1 ) then begin
                    osz = size(isok)
                    if ( osz[1] gt 6 ) then begin  ; require at least 6 valid pixels to operate
                        srt = sort(smalla[isok])
                        sz = size(srt)
			std=stddev(srt[2:(osz[1]-2)])  ; std used clipped set of pixels that are valid
			surround=[Frame[ii-1,j],Frame[ii+1,j],Frame[ii,j-1],Frame[ii,j+1]]  ; Four neighboring pixels are primary comparison for shape.
			compare=median(surround)	; This is the median of four neighbors
			back=median(srt)		; A local background is median of valid pixel in 3x3 box
			pixel=Frame[ii,j]-back		; Subtract local background from pixel
			cmp=compare-back		; Subtract local background from median of four neighbors.
			if ( pixel lt 0.0 ) then begin
				pixel= 0.0-pixel	; If pixel is negative, flip both it and comparison
				cmp=0.0-pixel
			endif
			cmp = cmp+3.0*std	; Set the comparison value to the value of the four neighbors plus 3 sigma noise.
			if ( pixel gt cmp*2.0 ) then begin ; Require that the pixel-background is less than 3*median of four neighbors after adding noise.
				Frame[ii,j]=compare	; Shouldn't be used, but set value to median of 4 neighbors.
				IntAuxFrame[ii,j]=0	; Flag as bad
			endif
		    endif
                endif
            endfor
        endfor
        bad = where(IntAuxFrame ne 9)
    endfor
    *DataSet.IntAuxFrames[i] = IntAuxFrame
    *DataSet.Frames[i] = Frame

endfor                          ; repeat on nFrames

RETURN, OK

END
