
;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; NAME: lineapixel_000.pro
;
; PURPOSE: linearize pixels
;
; ALLOWED BRANCH IDS: All
;
; PARAMETERS IN RPBCONFIG.XML : 
;
;    lineapixel_COMMON___Debug   : initialize debugging mode
;    lineapixel_COMMON___Limit   : maximum allowed float value for a pixel to be linearized
;    lineapixel_COMMON___Maximum : a pixel is linearized if its value is
;                                  less than Maximum * saturation
;                                  level.
;    lineapixel_COMMON___CPix    : if the number of consecutive (in a
;                                  column) saturated pixel exceed CPix a
;                                  warning is printed.
;    lineapixel_COMMON___HiLimit : a pixel is accounted for as saturated
;                                  if after the linearization the
;                                  linearized pixel value exceeds
;                                  HiLimit times the unlinearized pixel value. 
;    lineapixel_COMMON___LoLimit : a pixel is accounted for as invalid
;                                  if after the linearization the
;                                  linearized pixel value is lower than 
;                                  LoLimit times the unlinearized pixel value.
;
; MINIMUM/MAXIMUM NUMBER OF ALLOWED INPUT DATASETS : 1/- 
;
; INPUT-FILES :  loads a cube with 14 slices with the same slice size as the
;                input data that has been prepared by
;                mkdetrespo_000.pro :
;
;           Slice
;           0      : Maximum value of the response curve (float)
;           1      : Number of slice with maximum (byte)
;           2      : linear fit coefficient of all data points (float)
;           3      : good pixel have positive slope (1b), (0b) else
;           4-8    : Coefficients of the polynomial fit of order 5 (y=a+bx+...+f*x^5)
;           9      : Chi squared goodness-of-fit
;           10-13  : Coefficients 1-5 divided by (coefficient 0)^(1-5)
;
; OUTPUT : 
;
; INPUT : none
;
; DATASET : contains the linearized values
;
; QUALITY BITS : 
;
; DEBUG : nothing special
;
; MAIN ROUTINE : linearize.pro
;
; SAVES : see OUTPUT
;
; NOTES : None
;
; ALGORITHM : see linearize.pro
;
; STATUS : not tested
;
; HISTORY : 9.9.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION lineapixel_000, DataSet, Modules, Backbone

    COMMON APP_CONSTANTS

    functionName = 'lineapixel_000'
    ; save starting time
    T = systime(1)

    drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1

    BranchID = Backbone->getType()

    ; integrity check

    nFrames = Backbone->getValidFrameCount(DataSet.Name)

    if ( bool_dataset_integrity( DataSet, Backbone, functionName, /IMAGE ) ne OK ) then $
       return, error ('ERROR IN CALL (lineapixel_000.pro): integrity check failed.')

;    if ( BranchID ne 'CRP_SPEC' and BranchID ne 'CRP_IMAG' ) then $
;          return, error('ERROR IN CALL (lineapixel_000.pro): Bad Branch ID.')

    ; the integrity is ok

    ; get the parameters

    b_Debug   = fix(Backbone->getParameter('lineapixel_COMMON___Debug')) eq 1
    d_Limit   = float(Backbone->getParameter('lineapixel_COMMON___Limit')) 
    d_Maximum = float(Backbone->getParameter('lineapixel_COMMON___Maximum')) 
    i_CPix    = fix(Backbone->getParameter('lineapixel_COMMON___CPix')) 
    d_HiLimit = float(Backbone->getParameter('lineapixel_COMMON___HiLimit')) 
    d_LoLimit = float(Backbone->getParameter('lineapixel_COMMON___LoLimit')) 

    ; check parameters
    if ( d_Limit lt 0 ) then $
       return, error ( 'ERROR IN CALL (lineapixl_000.pro): Limit lt 0.')
    if ( d_Maximum lt 0 ) then $
       return, error ( 'ERROR IN CALL (lineapixl_000.pro): Maximum lt 0.')
    if ( i_CPix lt 0 ) then $
       return, error ( 'ERROR IN CALL (lineapixl_000.pro): CPix lt 0.')
    if ( d_HiLimit lt 0 ) then $
       return, error ( 'ERROR IN CALL (lineapixl_000.pro): HiLimit lt 0.')
    if ( d_LoLimit lt 0 ) then $
       return, error ( 'ERROR IN CALL (lineapixl_000.pro): LoLimit lt 0.')

    ; get the coefficient file
    thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
    c_File = drpXlateFileName(Modules[thisModuleIndex].CalibrationFile)

    if ( NOT file_test ( c_File ) ) then $
       return, error ('ERROR IN CALL (lineapixel_000.pro): Coefficient file ' + $
                      strtrim(string(c_File),2) + ' not found.' )
    
    pmf_SatLevel = ptr_new(READFITS(c_File, /SILENT, EXT=0))
    pmb_Bad      = ptr_new(READFITS(c_File, /SILENT, EXT=3))
    pmf_Coeff0   = ptr_new(READFITS(c_File, /SILENT, EXT=10))
    pmf_Coeff1   = ptr_new(READFITS(c_File, /SILENT, EXT=11))
    pmf_Coeff2   = ptr_new(READFITS(c_File, /SILENT, EXT=12))
    pmf_Coeff3   = ptr_new(READFITS(c_File, /SILENT, EXT=13))

    ; check consistency of coefficients
    if ( b_Debug ) then $
       debug_info, 'DEBUG INFO (lineapixel_000.pro): Coefficients loaded from '+ c_File

    ; check dimensions
    if ( NOT bool_dim_match ( *pmf_SatLevel, *DataSet.Frames[0] ) ) then $
       return, error('ERROR (lineapixel_000.pro): Coefficient 0 and data frames not compatible in size.')
    if ( NOT bool_dim_match ( *pmb_Bad, *DataSet.Frames[0] ) ) then $
       return, error('ERROR (lineapixel_000.pro): Coefficient 3 and data frames not compatible in size.')
    if ( NOT bool_dim_match ( *pmf_Coeff0, *DataSet.Frames[0] ) ) then $
       return, error('ERROR (lineapixel_000.pro): Coefficient 10 and data frames not compatible in size.')
    if ( NOT bool_dim_match ( *pmf_Coeff1, *DataSet.Frames[0] ) ) then $
       return, error('ERROR (lineapixel_000.pro): Coefficient 11 and data frames not compatible in size.')
    if ( NOT bool_dim_match ( *pmf_Coeff2, *DataSet.Frames[0] ) ) then $
       return, error('ERROR (lineapixel_000.pro): Coefficient 12 and data frames not compatible in size.')
    if ( NOT bool_dim_match ( *pmf_Coeff3, *DataSet.Frames[0] ) ) then $
       return, error('ERROR (lineapixel_000.pro): Coefficient 13 and data frames not compatible in size.')

    ; integrity of coefficients is ok, now run

    v_Res = linearize( pmb_Bad, pmf_SatLevel, pmf_Coeff0, pmf_Coeff1, pmf_Coeff2, pmf_Coeff3, $
                       DataSet.Frames, DataSet.IntFrames, DataSet.IntAuxFrames, nFrames, $
                       d_Limit, d_Maximum, i_CPix, d_HiLimit, d_LoLimit, DEBUG = b_Debug )
    if ( NOT bool_is_vector ( v_Res ) ) then $
       return, error ('FAILURE (lineapixel_000.pro): Failed to linearize.') ; this cannot happen

    drpLog, functionName+' succesfully completed after ' + strg(systime(1)-T) + ' seconds.', /DRF, DEPTH = 1

    Return, OK

END
