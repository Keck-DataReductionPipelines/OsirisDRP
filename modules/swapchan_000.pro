
;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; NAME: swapchan_000.pro
;
; PURPOSE: This is a test program which works on rectified data before
; it becomes a cube. It reorders the array of extracted spectra so
; that spectra that were adjacent on the detector are adjacent
; again. It is used to check the quality of the rectification process.
;
; PARAMETERS IN RPBCONFIG.XML : None
;
; INPUT-FILES : None
;
; OUTPUT : None
;
; DATASET : contains the adjusted data. The number of valid pointers 
;           is not changed.
;
; QUALITY BITS : all ignored
;
; DEBUG : nothing special
;
; MAIN ROUTINE : 
;
; SAVES : Nothing
;
; NOTES :   - Input frames must be 2d.
;
; STATUS : not tested
;
; HISTORY : 9.26.2005, created
;
; AUTHOR : James Larkin
;
;-----------------------------------------------------------------------

FUNCTION swapchan_000, DataSet, Modules, Backbone

    COMMON APP_CONSTANTS

    functionName = 'swapchan_000'
    ; save the starting time
    T = systime(1)

    drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1

    nFrames = Backbone->getValidFrameCount(DataSet.Name)

    ; do the subtraction
    n_Dims = size( *DataSet.Frames(0))

    for n = 0, (nFrames-1) do begin

        ;;; Read in the image and header info.
        im = *DataSet.Frames[n]
        temp=im
        for i = 0, 63 do begin
            for j = 0, 18 do begin
                temp[*,i*19+j]=im[*,j*64+i]
            end
        end
        (*DataSet.Frames[n])[*,*]=temp[*,*

    endfor

    ; it is not neccessary to change the dataset pointer

    report_success, functionName, T

    RETURN, OK

END
