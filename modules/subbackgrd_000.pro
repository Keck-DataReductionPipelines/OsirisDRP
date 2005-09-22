;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; NAME:  subbackgrd_000
;
; PURPOSE: see subtract_slice_bg_from_cube.pro
;
; ALLOWED BRANCH IDS: ARP_SPEC
;
; PARAMETERS IN RPBCONFIG.XML : 
;    subbackgrd_ARP_SPEC_bMEDIAN   : instead of fitting the background
;                                    with a plane the median value is determined
;    subbackgrd_COMMON___Debug     : bool, initializes the debugging mode
;
; MINIMUM/MAXIMUM NUMBER OF ALLOWED INPUT DATASETS : 1/-
;
; INPUT-FILES : Optional mask to mask out regions of the fov not to take into
;               account. 0 means not use, 1 means use.
;
; OUTPUT : None
;
; INPUT : 3d frames
;
; DATASET : updated
;
; QUALITY BITS : 0th     : checked
;                1st-3rd : ignored
;
; SPECIAL FITSKEYWORDS : none
;
; DEBUG : nothing special
;
; MAIN ROUTINE : subtract_slice_bg_from_cube.pro
;
; SAVES : If the SAVE tag in the module section of the drf has been
;         set to 1, the found background coefficients are saved.
;         Returns a cube, [3,n,n_Sets] with n being the number of spectral
;         channels and n_Sets being the number of input frames, meaning of the 0th axis :
;                   0: fitted offsets
;                   1: fitted x-slopes
;                   2: fitted y-slopes
;
;         If subbackgrd_ARP_SPEC_bMEDIAN is set to 1 it returns an
;         image [n,n_Sets] with the median values.
;
;
; STATUS : not tested
;
; HISTORY : 8.3.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
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
