;-----------------------------------------------------------------------
; NAME:  check_module
;
; PURPOSE : compare the parameters of the call to a module with the
;           module definition in define_modules.pro, check the
;           integrity of the DataSet and verify that the headers are
;           compliant with the DataSet
;
; INPUT :  DataSet      : DataSet
;          Modules      : Modules
;          Backbone     : Backbone
;          functionName : name of the calling function
;          Either
;          /IMAGE       : the datset pointers must be images
;            or
;          /CUBE        : the datset pointers must be cubes
;          /DIMS        : the spatial dimensions are not checked
;
; NOTES : This function should be executed first in each module (and
;         maybe before finishing).
;
; STATUS : untested
;
; HISTORY : 27.2.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------
function check_module, DataSet, Modules, Backbone, functionName, IMAGE=IMAGE, CUBE=CUBE, DIMS=DIMS, RETONLY=RETONLY

    COMMON APP_CONSTANTS

    ; get the module definition
    stModule = define_module()
    if ( NOT bool_is_struct ( stModule ) ) then $
       return, error ('ERROR IN CALL('+strtrim(functionName)+'): Error in module definition.')

    ;identify module
    for i=0, n_tags(stModule)-1 do $
       if ( stModule.(i).Name eq functionName ) then break
    if ( i eq n_tags(stModule) ) then $
       return, error ('ERROR IN CALL('+strtrim(functionName)+'): Module definition not found.')

    if ( not keyword_set ( RETONLY ) ) then begin
         
       n_Sets = Backbone->getValidFrameCount(DataSet.Name)
       ; check number of input datasets
       if ( n_Sets lt stModule.(i).NInput(0) or n_Sets gt stModule.(i).NInput(1) ) then $
          return, error ( 'ERROR IN CALL ('+strtrim(functionName,2)+'): Number of input datasets incompatible with definition.' )
       ; check number of input frames
       if ( stModule.(i).Number eq 'Odd' and (n_Sets mod 2) eq 0 ) then $
          return, error ( 'ERROR IN CALL ('+strtrim(functionName,2)+'): Number of datasets must be odd.' )
       if ( stModule.(i).Number eq 'Even' and (n_Sets mod 2) eq 1 ) then $
          return, error ( 'ERROR IN CALL ('+strtrim(functionName,2)+'): Number of datasets must be even.' )

       ; check dataset integrity
       if ( bool_dataset_integrity( DataSet, Backbone, functionName, $
                                    IMAGE = (keyword_set(IMAGE)?1:stModule.(i).IInput), $
                                    CUBE  = (keyword_set(CUBE)?1:stModule.(i).CInput), $
                                    DIMS  = keyword_set(DIMS)                             ) ne OK ) then $
          return, error ('ERROR IN CALL ('+strtrim(functionName,2)+'): Integrity check of dataset failed.')

       ; check branch id
       BranchID = Backbone->getType()
       n = where ( stModule.(i).Branches eq BranchID )
       if ( n(0) lt 0 ) then $
          return, error ('ERROR IN CALL ('+strtrim(functionName,2)+'): Invalid branch id detected.')

    end

    return, stModule.(i)

end
