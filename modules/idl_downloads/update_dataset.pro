;-----------------------------------------------------------------------------
; NAME:  update_dataset
;
; PURPOSE: update the dataset.
;
; INPUT : DataSet     : DataSet pointer
;         Backbone    : Backbone pointer
;         Frame       : data to be stored in *DataSet.Frames[0]
;         IntFrame    : data to be stored in *DataSet.IntFrames[0]
;         IntAuxFrame : data to be stored in *DataSet.IntAuxFrames[0]
;
; STATUS : untested
;
; NOTES : Index 0 in DataSet gets Frame, IntFrame, IntAuxFrame
;         other indices are deleted
;
; HISTORY : 8.8.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------------

pro update_dataset, DataSet, Backbone, Frame, IntFrame, IntAuxFrame

    tempPtr = PTR_NEW(/ALLOCATE_HEAP)
    *tempPtr = *DataSet.Frames[0]
    *DataSet.Frames[0] = Frame
    PTR_FREE, tempPtr
   
    tempPtr = PTR_NEW(/ALLOCATE_HEAP)
    *tempPtr = *DataSet.IntFrames[0]
    *DataSet.IntFrames[0] = IntFrame
    PTR_FREE, tempPtr
    
    tempPtr = PTR_NEW(/ALLOCATE_HEAP)
    *tempPtr = *DataSet.IntAuxFrames[0]
    *DataSet.IntAuxFrames[0] = IntAuxFrame
    PTR_FREE, tempPtr
    
    nFrames = Backbone->getValidFrameCount(DataSet.Name)

    ; now delete all the rest
    FOR i = 1, nFrames-1 DO BEGIN

       tempPtr = PTR_NEW(/ALLOCATE_HEAP)	; Create a new, temporary, pointer variable
       *tempPtr = *DataSet.Frames[i]		; Use it to save a pointer to the old data
       PTR_FREE, tempPtr			; Free the old data using the temporary pointer
    
       tempPtr = PTR_NEW(/ALLOCATE_HEAP)	
       *tempPtr = *DataSet.IntFrames[i]	
       PTR_FREE, tempPtr			
       
       tempPtr = PTR_NEW(/ALLOCATE_HEAP)	
       *tempPtr = *DataSet.IntAuxFrames[i]
       PTR_FREE, tempPtr			
       
       tempPtr = PTR_NEW(/ALLOCATE_HEAP)	
       *tempPtr = *DataSet.Headers[i]	
       PTR_FREE, tempPtr			

    ENDFOR

    dummy = Backbone->setValidFrameCount(DataSet.Name, 1)

END
