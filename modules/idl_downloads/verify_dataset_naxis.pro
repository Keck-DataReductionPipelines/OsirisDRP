;-----------------------------------------------------------------------
; NAME:  verify_dataset_naxis
;
; PURPOSE: Check if the dimensions specified by the NAXIS keywords in
;          DataSet.Headers are compliant with the dimensions of
;          the DataSet pointer arrays.
;
; INPUT :  DataSet  : DataSet 
;          nFrames  : number of input pointers to check
;          /UPDATE  : if set, then the header is updated according to
;                     the dimensionality of the frame
;                     pointers. Afterwards the intframe and
;                     intauxframe pointers are compared to the updated header.
;
; NOTES : - One header describes the frame, intframe and intauxframe
;           pointer.
;         - Updating the header is done according to the dimensionality
;           of the frame pointer
;
; STATUS : untested
;
; HISTORY : 27.2.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------
function verify_dataset_naxis, DataSet, nFrames, UPDATE=UPDATE

    COMMON APP_CONSTANTS

    functionName = 'verify_dataset_naxis'

    for i=0, nFrames-1 do begin

       if ( verify_naxis ( DataSet.Frames(i), DataSet.Headers(i), UPDATE=keyword_set(UPDATE) ) ne OK ) then $
          return, error('FAILURE ('+strg(functionName)+'): Verification of frame axes in header '+strg(i)+' failed.')

       if ( verify_naxis ( DataSet.IntFrames(i), DataSet.Headers(i) ) ne OK ) then $
          return, error('FAILURE ('+strg(functionName)+'): Verification of intframe axes in header '+strg(i)+' failed.')

       if ( verify_naxis ( DataSet.IntAuxFrames(i), DataSet.Headers(i) ) ne OK ) then $
          return, error('FAILURE ('+strg(functionName)+'): Verification of intauxframe axes in header '+strg(i)+' failed.')
    end

    return, OK

end
  
