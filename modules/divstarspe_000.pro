;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; NAME:   divstarspe_000
;
; PURPOSE:  divide by stellar spectrum; It first normalizes the
; stellar spectrum to a median value of 1.0
;
; PARAMETERS IN RPBCONFIG.XML :
;    divstarspe_COMMON___Debug : initializes the debugging mode
;    divstarspe_COMMON___Limit : minimum denominator allowed for stellar spectrum
;                                Must be gt 1.d-60
;
; INPUT-FILES : Stellar spectrum (1d)
;
; OUTPUT : None
;
; DATASET : Contains the divided data afterwards. The pointers are
;           not changed
;
; QUALITY BITS :
;          0th     : checked
;          1st-2nd : ignored
;          3rd     : checked
;
;          since the stellar spectrum is replicated to a cube, the 0th
;          and 3rd bit of the spctrum must be set correctly. 
;
; DEBUG : Saves all datasets
;
; SAVES : If Save tag in drf file is set to 1, the divided cubes are
;         saved. Ensure that when dealing with multiple input cubes
;         the DATAFILE keyword varies.
;
;
; NOTES : - This module works on cubes only.
;         - The stellar spectrum has been extracted from a cube, the
;           inside bit is set.
;
; STATUS : not tested
;
; HISTORY : 13.5.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;          Significantly modified to normalize the stellar spectrum
;          and ignore bad pixels in stellar spectrum. Also does not
;          replicate the spectrum but instead cycles through cube
;          dividing each lenslet by spectrum - James Larkin May 29, 2007
;
;-----------------------------------------------------------------------

FUNCTION divstarspe_000, DataSet, Modules, Backbone

    COMMON APP_CONSTANTS

    functionName = 'divstarspe_000'
    ; save starting time
    T = systime(1)

    drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1

    nFrames = Backbone->getValidFrameCount(DataSet.Name)

    ; get the input stellar spectrum which is already EURO3D compliant
    thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
    c_File = drpXlateFileName(Modules[thisModuleIndex].CalibrationFile)
    if ( NOT file_test ( c_File ) ) then $
       return, error('ERROR In CALL ('+strtrim(functionName)+'): File '+strtrim(string(c_File),2)+$
                     ' with stellar spectrum not found.')
    pvd_StarFrame       = readfits(c_File, h_Header )

    ; all frames, intframes and intauxframes have the same dims
    n_Dims = size ( *DataSet.Frames[0] )
    length = size( pvd_StarFrame )
    if ( n_Dims[0] ne 3 ) then return, error('ERROR IN CALL ('+strtrim(functionName)+'): Dataset must be 3-d for divide star spectrum')
    if ( length[0] ne 1 ) then return, error('ERROR IN CALL ('+strtrim(functionName)+'): Stellar Spectrum must be 1-d for divide star spectrum')
    if ( n_Dims[1] ne length[1] ) then return, error('ERROR IN CALL ('+strtrim(functionName)+'): Stellar Spectrum must be same length as data set.')

    ; Normalize stellar spectrum
    pvd_StarFrame = pvd_StarFrame / median(pvd_StarFrame)

    ; now loop over the input data sets
    for i=0, nFrames-1 do begin
        for j = 0, n_Dims[2]-1 do begin
            for k = 0, n_Dims[3]-1 do begin
                (*DataSet.Frames[i])[*,j,k] = (*DataSet.Frames[i])[*,j,k] / pvd_StarFrame
            end
        end
        ; Edit file name in header to replace datset with calstar
        ; updated code for H2RG (by jlyke, added by A. Boehle - April 2016)
        ; For H2, this file name DOES NOT include the .fits file extension.
        ; For H2RG, this file name DOES include the .fits file extenstion.
        fname = sxpar(*DataSet.Headers[i],'DATAFILE')
        fn = STRSPLIT(fname, '.', /EXTRACT)
        fname = fn[0]
        fname = fname + '_tlc'
        print, fname
        SXADDPAR, *DataSet.Headers[i], "DATAFILE", fname
    end


    if ( Modules[thisModuleIndex].Save eq 1 ) then begin

       b_Stat = save_dataset ( DataSet, nFrames, Modules[thisModuleIndex].OutputDir, stModule.Save, DEBUG=b_Debug )
       if ( b_Stat eq OK ) then begin
          report_success, functionName, T
          return, OK
       endif else return, b_Stat

    end

end
