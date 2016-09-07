;-----------------------------------------------------------------------------
; NAME:  update_dataset_pointer
;
; PURPOSE: update the dataset pointers.
;
; INPUT : p_Frames       : pointer or pointer array to the dataset frames
;         p_IntFrames    : pointer or pointer array to the dataset intframes
;         p_IntAuxFrames : pointer or pointer array to the dataset intauxframes
;         p_Headers      : pointer or pointer array to the dataset headers
;         nFrames        : number of datasets
;         Frame          : data to be stored in p_Frames[0]
;         IntFrame       : data to be stored in p_IntFrames[0]
;         IntAuxFrame    : data to be stored in p_IntAuxFrames[0]
;         Header         : data to be stored in p_Headers[0]
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

pro update_dataset_pointer, p_Frames, p_IntFrames, p_IntAuxFrames, p_Headers, nFrames, $
                            Frame, IntFrame, IntAuxFrame, Header

    ; delete all the rest
    FOR i = 0, nFrames-1 DO BEGIN

       tempPtr = PTR_NEW(/ALLOCATE_HEAP)	; Create a new, temporary, pointer variable
       *tempPtr = *p_Frames[i]		        ; Use it to save a pointer to the old data
       PTR_FREE, tempPtr			; Free the old data using the temporary pointer
    
       tempPtr = PTR_NEW(/ALLOCATE_HEAP)	
       *tempPtr = *p_IntFrames[i]	
       PTR_FREE, tempPtr			
       
       tempPtr = PTR_NEW(/ALLOCATE_HEAP)	
       *tempPtr = *p_IntAuxFrames[i]
       PTR_FREE, tempPtr			
       
       tempPtr = PTR_NEW(/ALLOCATE_HEAP)	
       *tempPtr = *p_Headers[i]	
       PTR_FREE, tempPtr			

    ENDFOR

    *p_Frames[0]       = Frame
    *p_IntFrames[0]    = IntFrame
    *p_IntAuxFrames[0] = IntAuxFrame
    *p_Headers[0]      = Header

END
