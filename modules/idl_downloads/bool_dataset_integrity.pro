;-----------------------------------------------------------------------
; NAME: bool_dataset_integrity
;
; PURPOSE: Check integrity of DataSet. The Headers are verified
;          against the dimensionality of the data arrays.
;
; INPUT :  DataSet      : DataSet
;          Backbone     : Backbone
;          functionName : name of the calling function/module 
;          Either
;          /VECTOR      : DataSet must contain vectors exclusively
;             or
;          /IMAGE       : DataSet must contain images exclusively
;             or
;          /CUBE        : DataSet must contain cubes exclusively
;
;          /DIMS        : Do not check for spatial dimensions (see arr_chk.pro)
;
; OUTPUT : returns OK on success or ERR_UNKNOWN from APP_CONSTANTS
;
; NOTES : if neither /VECTOR, /IMAGE or /CUBE is set, DataSet may
;         contain either vectors, images or cubes
;
; STATUS : untested
;
; HISTORY : 27.2.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

function bool_dataset_integrity, DataSet, Backbone, functionName, VECTOR=VECTOR, IMAGE=IMAGE, CUBE=CUBE, $
                                 DIMS=DIMS

    COMMON APP_CONSTANTS

    nFrames = fix(Backbone->getValidFrameCount(DataSet.Name))

    b_BPI = bool_pointer_integrity ( DataSet.Frames, DataSet.IntFrames, DataSet.IntAuxFrames, $
                                     nFrames, functionName, VECTOR = keyword_set(VECTOR), $
                                     IMAGE = keyword_set(IMAGE), CUBE = keyword_set(CUBE), $
                                     DIMS = keyword_set(DIMS) )

    b_VN  = verify_dataset_naxis ( DataSet, nFrames )

    if ( b_BPI eq OK and b_VN eq OK ) then return, OK else return, ERR_UNKNOWN

end
