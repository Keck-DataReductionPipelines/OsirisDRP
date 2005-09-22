;==============================================================================
Function checkvalidity, InputData, nDim
;==============================================================================
; OSIRIS Data Reduction Software Module
;
; Description of this subroutine::
;   
;    Check if the inputdata is valid pointer form and
;          has proper dimension.
;
; INPUT:   InputDate = pointer to input variable
;          nDim      = number of dimension that inputdata should have.
;         
;
; Return value: 
;          0 = everything is OK and the data has nDim dimension.
;          1 = pointer not exist.
;          2 = wrong dimension.
;
; Versions:
;       created  Dec, 2003 by I. Song
;==============================================================================

IF not ptr_valid(InputData) THEN BEGIN
   message, 'InputData pointer is invalid'
   return, 1
ENDIF

; 0th element of SIZE return value is the number of dimension 
; of the variable. See SIZE function description for more details.
IF ( (SIZE(*InputData))[0] NE nDim ) THEN BEGIN
   message, 'InputData does not have a dimension ' + string(nDim)
   return, 2
ENDIF

return, 0

END
