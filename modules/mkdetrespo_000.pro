
;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; NAME: mkdetrespo_000.pro
;
; PURPOSE: Provide coefficients for the linearisation of the detector response.
;          Input is a series of flazfield images with raising
;          intensities up to the saturation level.
;
; ALLOWED BRANCH IDS: CRP_SPEC, CRP_IMAG
;
; PARAMETERS IN RPBCONFIG.XML : 
;     mkdetrespo_COMMON___Debug : initialize debugging mode
;
; MINIMUM/MAXIMUM NUMBER OF ALLOWED INPUT DATASETS : 20/- 
;
; INPUT-FILES : None
;
; OUTPUT :  saves a cube with 14 slices with the same slice size as the
;           input data :
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
; INPUT : 2d frames
;
; DATASET : DELETES ALL data connected to the DataSet pointers !!!
;
; QUALITY BITS : ignored
;
; DEBUG : nothing special
;
; MAIN ROUTINE : make_det_response
;
; SAVES : see OUTPUT
;
; NOTES : No other module is supposed to follow
;
; ALGORITHM : see documentation
;
; STATUS : not tested
;
; HISTORY : 8.9.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION mkdetrespo_000, DataSet, Modules, Backbone

    COMMON APP_CONSTANTS

    functionName = 'mkdetrespo_000'
    ; save starting time
    T = systime(1)

    drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1

    ; integrity check

    nFrames = Backbone->getValidFrameCount(DataSet.Name)

    if ( nFrames lt 20 ) then $
       warning, 'WARNING (mkdetrespo_000.pro): Working on less than 20 input datasets.'

    if ( bool_dataset_integrity( DataSet, Backbone, functionName, /IMAGE ) ne OK ) then $
       return, error ('ERROR IN CALL (mkdetrespo_000.pro): integrity check failed.')

    ; the integrity is ok

    ; Get all COMMON parameter values

    BranchID = Backbone->getType()

    if ( BranchID ne 'CRP_SPEC' and BranchID ne 'CRP_IMAG' ) then $
          return, error('ERROR IN CALL (mkdetrespo_000.pro): Bad Branch ID.')

    b_Debug = fix(Backbone->getParameter('mkdetrespo_COMMON___Debug')) eq 1

    ; determine the detector response
    s_Res = make_det_response ( DataSet.Frames, DataSet.Headers, nFrames, DEBUG=b_Debug )
    if ( NOT bool_is_struct ( s_Res ) ) then $
       return, error ('FAILURE (mkdetrespo_000.pro): Determination of detector response failed.')

    ; Now, save the data
    thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
    c_File = make_filename ( DataSet.Headers[0], Modules[thisModuleIndex].OutputDir, 'DETRES' )
    if ( NOT bool_is_string(c_File) ) then $
       return, error('FAILURE (mkdetrespo_000.pro): Output filename creation failed.')

    mkhdr, h, s_Res.mf_Max
    sxaddpar, h, 'COMMENT', 'Slice 0      : Maximum value of the response curve (float)'
    sxaddpar, h, 'COMMENT', 'Slice 1      : Number of slice with maximum (byte)'
    sxaddpar, h, 'COMMENT', 'Slice 2      : linear fit coefficient of all data points (float)'
    sxaddpar, h, 'COMMENT', 'Slice 3      : good pixel have positive slope (1b), (0b) else'
    sxaddpar, h, 'COMMENT', 'Slice 4-8    : Coefficients of the polynomial fit of order 5 (y=a+bx+...+f*x^5)'
    sxaddpar, h, 'COMMENT', 'Slice 9      : Chi squared goodness-of-fit'
    sxaddpar, h, 'COMMENT', 'Slice 10-13  : Coefficients 1-5 divided by (coefficient 0)^(1-5)'
    sxaddpar, h, 'EXTEND', 'T'

    writefits, c_File, float(s_Res.mf_Max), h       
    writefits, c_File, byte(s_Res.mb_Max), /APPEND        
    writefits, c_File, float(s_Res.mf_Linear), /APPEND         
    writefits, c_File, byte(s_Res.mb_Valid), /APPEND         
    writefits, c_File, float(s_Res.mf_CoeffsPoly(*,*,0)), /APPEND
    writefits, c_File, float(s_Res.mf_CoeffsPoly(*,*,1)), /APPEND
    writefits, c_File, float(s_Res.mf_CoeffsPoly(*,*,2)), /APPEND     
    writefits, c_File, float(s_Res.mf_CoeffsPoly(*,*,3)), /APPEND     
    writefits, c_File, float(s_Res.mf_CoeffsPoly(*,*,4)), /APPEND     
    writefits, c_File, float(s_Res.mf_Chi2), /APPEND           
    writefits, c_File, float(s_Res.mf_CoeffsPolyNorm(*,*,0)), /APPEND 
    writefits, c_File, float(s_Res.mf_CoeffsPolyNorm(*,*,1)), /APPEND 
    writefits, c_File, float(s_Res.mf_CoeffsPolyNorm(*,*,2)), /APPEND 
    writefits, c_File, float(s_Res.mf_CoeffsPolyNorm(*,*,3)), /APPEND 
    
    if ( b_Debug ) then begin
       debug_info, 'DEBUG INFO (mkdetrespo_000.pro): File '+c_File+' successfully written.'
       fits_help, c_File
    end

    dummy   = Backbone->setValidFrameCount(DataSet.Name, 0)
    nFrames = Backbone->getValidFrameCount(DataSet.Name)
    if ( nFrames ne 0 ) then return, error('FAILURE (mkdetrespo_000.pro): Failed to reset ValidFrameCounter.')

    drpLog, functionName+' succesfully completed after ' + strg(systime(1)-T) + ' seconds.', /DRF, DEPTH = 1

    Return, OK

END
