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
;         It is assumed that input frames have been made into cubes and
;         are linear in wavelength. This allows it to compare pixels
;         within the same slice.
;
; ALGORITHM :
; REQUIRED ROUTINE :
;
; HISTORY : Oct 3, 2005    created
;           June 8, 2006   modified to work on raw data instead of cubes
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
        ; Step through the array horizontally in 97 pixel increments
        for j = 0, 2047 do begin
            for ii = 0, 1947, 97 do begin
                smalla=Frame[ii:ii+99, j] ; 100 pixel strip of data
                smallb=IntAuxFrame[ii:ii+99, j] ; Bad pixel strip
                isok = where( smallb eq 9 )
                notok = where( smallb ne 9)
                if ( isok[0] ne -1 ) then begin
                    osz = size(isok)
                    if ( osz[1] gt 20 ) then begin
                        srt = sort(smalla[isok])
                        sz = size(srt)
                        q = srt[10:sz[1]-10]
                        std = stddev(smalla[q])
                        compare = abs(smalla) > 3.0*std
                        if ( notok[0] ne -1) then compare[notok]=3.0*std
                        rat = abs(smalla[indx]) / (compare[0>indx-1]+compare[99<indx+1])
                        bad = where(rat gt 1.2)
                        rat[*] = 1.0
                        if ( bad[0] ne -1 ) then rat[bad]=0.0
                        IntAuxFrame[ii+1:ii+98,j] = intAuxFrame[ii+1:ii+98,j]*rat[1:98]
                    end
                end
            end
        end
        bad = where(IntAuxFrame ne 9)
        Frame[bad] = 0.0
    end
    *DataSet.IntAuxFrames[i] = IntAuxFrame
    *DataSet.Frames[i] = Frame

endfor                          ; repeat on nFrames

RETURN, OK

END
