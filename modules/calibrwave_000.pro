;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; NAME:  calibrwave_000
;
; PURPOSE: resample the spectra to a regular wavelength grid by cubic
;          spline interpolation
;
; PARAMETERS IN RPBCONFIG.XML :
;
;   calibrwave_COMMON___Debug             : initialize debugging mode
;   calibrwave_COMMON___BadMultiplier     : see below
;   calibrwave_COMMON___BadIntMultiplier  : see below
;   calibrwave_COMMON___LowerLimitGood    : see below
;   calibrwave_COMMON___UpperLimitGood    : see below
;   calibrwave_COMMON___UpperLimitBad     : see below
;   calibrwave_COMMON___NoiseMultiplier   : see below
;   calibrwave_COMMON___InterPolType      : interpolation method. Either LINEAR, LSQUADRATIC,
;                                           QUADRATIC, SPLINE (see IDL built-in function interpol)
;   calibrwave_COMMON___Filterfile        : filter file
;
;        Determining the quality status after interpolation:
;           A status vector is created describing the status of the inner pixel. 
;           The status vector elements corresponding to an inner pixel get :
;              not interpolated      : 0
;              good/bad interpolated : 1 / d_BadIntMultiplier
;              bad or outside        : d_BadMultiplier
;
;           The status vector is resampled linearly onto the new grid. Resampled pixel on the new grid
;           that fullfill any of the following conditions get :
;              d_LowerLimitGood < value < d_UpperLimitGood  : good interpolation status 
;              d_UpperLimitGood < value < d_UpperLimitBad   : bad interpolation status
;              value > d_UpperLimitBad                      : bad interpolation status and the corresponding
;                                                             resampled intframe value is multiplied by
;                                                             d_NoiseMultiplier.
;
; INPUT-FILES : wavelength calibration cube
;
; OUTPUT : none 
;
; DATASET : contains the wavelength calibrated cubes. The result has the same
;           size as the wavelength calibration frame.
;
; QUALITY BITS : all bits checked
;
; DEBUG : nothing special
;
; SAVES : see Output
;
; NOTES : - This module reads a spatially rectified frame containing the
;           wavelengths for each pixel of the dataframes
;
; STATUS : not tested
;
; HISTORY : 12.8.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION calibrwave_000, DataSet, Modules, Backbone

   COMMON APP_CONSTANTS

   ; define error constants
   define_error_constants

   functionName = 'calibrwave_000'
   ; save starting time
   T = systime(1)

   drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1

   ; check integrity
   stModule =  check_module( DataSet, Modules, Backbone, functionName )
   if ( NOT bool_is_struct ( stModule ) ) then $
      return, error ('ERROR IN CALL ('+strtrim(functionName)+'): Integrity check failed.')


   BranchID = Backbone->getType()
   nFrames  = Backbone->getValidFrameCount(DataSet.Name)

   thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
   FileName        = drpXlateFileName(Modules[thisModuleIndex].CalibrationFile)
   if ( NOT file_test ( FileName ) ) then $
      return, error ('ERROR IN CALL ('+strtrim(functionName)+'): Wavelength map ' + strg(FileName) + ' not found')

   cd_CalibFrame = readfits(FileName, CalibHeader, /SILENT)
   if ( NOT bool_is_cube ( cd_CalibFrame ) ) then $
      return, error ('ERROR IN CALL ('+strtrim(functionName)+'): wavelength map must be a cube.')

   mb_CalibFrameValid = readfits(FileName, EXT=1, /SILENT)
   if ( NOT bool_is_image ( mb_CalibFrameValid ) ) then $
      return, error ('ERROR IN CALL ('+strtrim(functionName)+'): wavelength map indicator must be an image.')

   if ( NOT bool_dim_match ( mb_CalibFrameValid , reform(cd_CalibFrame(0,*,*)) ) ) then $
      return, error ('ERROR IN CALL ('+strtrim(functionName)+'): wavelength map indicator and wavelength map must match in spatial dimensions.')

   s_CalibFilter = sxpar(CalibHeader, "SFILTER", count=n_CSF)
   if ( n_CSF ne 1 ) then $
      return, error('ERROR IN CALL ('+strtrim(functionName)+'): SFILTER keyword not or multiply defined in wavelength map.')

   ; some checks
   for i=0, nFrames-1 do begin

      ; check that input cubes and wavelength cube have the same size
      if ( NOT bool_dim_match ( cd_CalibFrame, *DataSet.Frames(i) ) ) then $
         return, error('ERROR IN CALL ('+strtrim(functionName)+'): Wavelength map and input cube '+$
            strg(i)+' not compatible in size.')
      ; check that the SFilter keyword occurs exactly 1 time
      s_Filter = sxpar(*DataSet.Headers[i], "SFILTER", count=n_SF)
      if ( n_SF ne 1 ) then $
         return, error('ERROR IN CALL ('+strtrim(functionName)+'): SFILTER keyword not or multiply defined.')
      ; check that the SFilter keyword of the wavelength map matches the one
      ; of the input 
      if ( s_Filter ne s_CalibFilter ) then $
         return, error('ERROR IN CALL ('+strtrim(functionName)+'): SFILTER keywords of input and wavelength map do not match.')

   end

   ; the integrity is ok

   ; now start

   b_Debug            = fix(Backbone->getParameter('calibrwave_COMMON___Debug')) eq 1
   d_BadMultiplier    = float(Backbone->getParameter('calibrwave_COMMON___BadMultiplier'))
   d_BadIntMultiplier = float(Backbone->getParameter('calibrwave_COMMON___BadIntMultiplier'))
   d_LowerLimitGood   = float(Backbone->getParameter('calibrwave_COMMON___LowerLimitGood'))
   d_UpperLimitGood   = float(Backbone->getParameter('calibrwave_COMMON___UpperLimitGood'))
   d_UpperLimitBad    = float(Backbone->getParameter('calibrwave_COMMON___UpperLimitBad'))
   d_NoiseMultiplier  = float(Backbone->getParameter('calibrwave_COMMON___NoiseMultiplier'))
   s_InterPolType     = strg(Backbone->getParameter('calibrwave_COMMON___InterPolType'))
   s_FilterFile       = strg(Backbone->getParameter('calibrwave_COMMON___Filterfile'))

   i_Res = calibrwave ( DataSet.Frames, DataSet.IntFrames, DataSet.IntAuxFrames, $
                        DataSet.Headers, nFrames, cd_CalibFrame, mb_CalibFrameValid, $
                        d_BadMultiplier, d_BadIntMultiplier, d_LowerLimitGood, $
                        d_UpperLimitGood, d_UpperLimitBad, $
                        d_NoiseMultiplier, s_InterPolType, s_FilterFile, $
                        ORP=(BranchID eq 'ORP_SPEC'), DEBUG=b_Debug )

   if ( i_Res ne OK ) then $
      return, error ('FAILURE ('+strtrim(functionName)+'): Whoopsie daisy. Failed to do the regularization.')

   ; update the header
   for i=0, nFrames-1 do $
      if ( verify_naxis ( DataSet.Frames(i), DataSet.Headers(i), /UPDATE ) ne OK ) then $
         return, error('FAILURE ('+strtrim(functionName)+'): Update of header failed.')
  
   thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
   if ( Modules[thisModuleIndex].Save eq 1 ) then begin

      b_Stat = save_dataset ( DataSet, nFrames, Modules[thisModuleIndex].OutputDir, stModule.Save, DEBUG=b_Debug )
      if ( b_Stat ne OK ) then $
         return, error ('FAILURE ('+functionName+'): Failed to save dataset.')

   end

   report_success, functionName, T

   return, OK

end
