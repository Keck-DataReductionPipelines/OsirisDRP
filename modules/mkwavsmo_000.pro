;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; NAME: mkwavsmo_000.pro
;
; PURPOSE: smooth the determined wavelength map
;
; ALLOWED BRANCH IDS: All branches
;
; PARAMETERS IN RPBCONFIG.XML : 
;     mkwavcalfr_COMMON___Debug       : initialize debugging mode
;     mkwavsmo_COMMON___Order         : Fit order of the surface
;     mkwavsmo_COMMON___MedianWindow  : median window in pixel
;     mkwavsmo_COMMON___LimitPixel    : maximum deviation
;     mkwavsmo_COMMON___FilterFile    : filter file
;
; MINIMUM/MAXIMUM NUMBER OF ALLOWED INPUT DATASETS : 1/1
;
; INPUT-FILES : None
;
; OUTPUT :  the smoothed wavelength map
;
; INPUT : 3d frames
;
; DATASET : input must contain a wavelength cube
;
; QUALITY BITS : all bits ignored
;
; DEBUG : nothing special
;
; SAVES : see OUTPUT
;
; NOTES : all fits keywords are ignored
;
; STATUS : not tested
;
; HISTORY : 24.5.2005, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION mkwavsmo_000, DataSet, Modules, Backbone

    COMMON APP_CONSTANTS

    ; define error constants
    define_error_constants

    functionName = 'mkwavsmo_000'
    ; save the starting time
    T = systime(1)

    drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1

    ; no check integrity
    stModule =  check_module( DataSet, Modules, Backbone, functionName, /RETONLY )
    if ( NOT bool_is_struct ( stModule ) ) then $
       return, error ('ERROR IN CALL ('+strtrim(functionName)+'): Integrity check failed.')

    ; Get all COMMON parameter values
    b_Debug              = fix(Backbone->getParameter('mkwavsmo_COMMON___Debug')) eq 1
    i_FSOrder            = fix(Backbone->getParameter('mkwavsmo_COMMON___Order'))
    i_FSMedianWindow     = fix(Backbone->getParameter('mkwavsmo_COMMON___MedianWindow'))
    i_FSLimitPixel_px    = fix(Backbone->getParameter('mkwavsmo_COMMON___LimitPixel'))
    s_FSFilterFile       = Backbone->getParameter('mkwavsmo_COMMON___FilterFile')

    thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
    c_File = drpXlateFileName(Modules[thisModuleIndex].CalibrationFile)
    if ( NOT file_test ( c_File ) ) then $
       return, error ('ERROR IN CALL ('+strtrim(functionName)+'): Wavelength map ' + $
                      strtrim(string(c_File),2) + ' not found.' )

    s_Res = mkwavsmo( c_File, i_FSOrder, i_FSMedianWindow, i_FSLimitPixel_px, s_FSFilterFile, b_Debug )
    if ( NOT bool_is_struct ( s_Res ) ) then $
       return, error ('FAILURE (mkwavsmo_000): Failed to fit surfaces.')

    if ( 1 ) then begin

       ; Now, save the data
       thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
       c_File = make_filename ( ptr_new(s_Res.h_Header), Modules[thisModuleIndex].OutputDir, stModule.SaveExt  )
       if ( NOT bool_is_string(c_File) ) then $
          return, error('FAILURE ('+strtrim(functionName)+'): Output filename creation failed.')

       mkhdr, h, s_Res.cd_WMap
       sxaddpar, h, 'EXTEND', 'T'
       sxaddpar, h, 'SFILTER', s_Res.s_Filter
       sxaddpar, h, 'ORDER', s_Res.i_Order
       sxaddpar, h, 'SORDER', s_Res.i_FSOrder
       sxaddpar, h, 'COMMNT0', '0th Extension : Wavelength map/cube.'
       sxaddpar, h, 'COMMNT1', '1st Extension : Status of the the dispersion relation for a specific pixel. 0 means OK'

       writefits, c_File, double(s_Res.cd_WMap), h       
       writefits, c_File, fix(s_Res.mb_DispStat),/append

       if ( b_Debug ) then begin
          debug_info, 'DEBUG INFO ('+strtrim(functionName)+'): File '+c_File+' successfully written.'
          fits_help, c_File
       end

    end

    report_success, functionName, T

    Return, OK

END
