;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; @BEGIN
;
; @NAME  subbackgrd_000
;
; @PURPOSE background subtraction, this routine is obsolete !!!
;
; @STATUS not tested
;
; @HISTORY 8.3.2004, created
;
; @AUTHOR Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
; @END
;
;-----------------------------------------------------------------------

FUNCTION subbackgrd_000, DataSet, Modules, Backbone

    COMMON APP_CONSTANTS

    functionName = 'subbackgrd_000'

    drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1

    ; Get all COMMON parameter values

    BranchID = Backbone->getType()

    n_Sets = Backbone->getValidFrameCount(DataSet.Name)

    if ( BranchID ne 'ARP_SPEC' ) then $
       return, error ('ERROR IN CALL (subbackgrd_000.pro): Wrong Branch ID.')

    if ( bool_dataset_integrity( DataSet, Backbone, functionName, /CUBE ) ne OK ) then $
       return, error ('ERROR IN CALL (subbackgrd_000.pro): integrity check failed.')

    ; the integrity is ok; now get the parameter

    b_BGMedian = fix(Backbone->getParameter('subbackgrd_ARP_SPEC_bMEDIAN')) eq 1
    b_Debug    = fix(Backbone->getParameter('subbackgrd_COMMON___Debug')) eq 1  

    ; check if an external sky needs to be loaded
    thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
    c_File = drpXlateFileName(Modules[thisModuleIndex].CalibrationFile)

    b_Mask = 0

    if ( strg(c_File) ne '/' ) then begin

       ; a background mask is given
       if ( NOT file_test ( c_File ) ) then $
          return, error ('ERROR IN CALL (subbackgrd_000.pro): Sky frame ' + strg(c_File) + ' not found.' )

       md_Mask = READFITS(c_File, /SILENT)

       if ( NOT bool_is_bool(md_Mask) ) then $
          return, error ('ERROR IN CALL (subbackgrd_000.pro): Mask not of type bool.')

       if ( b_Debug ) then $
          debug_info, 'DEBUG INFO (subbackgrd_000.pro): Sky frame loaded from '+ c_File

       b_Mask = 1

    endif

    n_Dims = size ( DataSet.Frames[0] )

    if ( b_BGMedian ) then cd_Fit = fltarr ( n_Dims(1), n_Sets ) $
    else cd_Fit = fltarr ( n_Dims(1), 3, n_Sets )

    for i=0, n_Sets-1 do begin

       Res = subtract_slice_bg_from_cube ( DataSet.Frames[i], DataSet.IntFrames[i], $
                                           DataSet.IntAuxFrames[i], MEDIANING=b_BGMedian, $
                                           MASK = (b_Mask eq 1) ? md_Mask : 0,  DEBUG=DEBUG )

       if ( bool_is_image(Res) ) then cd_Fit(*,*,i) = Res 
       if ( bool_is_vector(Res) ) then cd_Fit(*,i) = Res 

    end

    thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
    if ( Modules[thisModuleIndex].Save eq 1 ) then begin
       c_File = make_filename ( DataSet.Headers[0], Modules[thisModuleIndex].OutputDir, 'SBGD' )
       if ( NOT bool_is_string(c_File) ) then $
          return, error('FAILURE (subbackgrd_000.pro): Output filename creation failed.')

       mkhdr, h, cd_Fit

       if ( b_BGMedian ) then begin
          sxaddpar, h, 'COMMNT0' , '0th axis is spectral chanel'
          sxaddpar, h, 'COMMNT1' , '1st axis is offset, x-slope, y-slope'
          sxaddpar, h, 'COMMNT2' , '2nd axis is running frame number'
       endif else begin
          sxaddpar, h, 'COMMNT0' , '0th axis is spectral chanel'
          sxaddpar, h, 'COMMNT1' , '1st axis is running frame number'
       end

       writefits, c_File, cd_Fit, h

       info, 'INFO (subbackgrd_000.pro): File '+c_File+' successfully written.'

       if ( b_Debug ) then fits_help, c_File

    end

    return, OK

END
