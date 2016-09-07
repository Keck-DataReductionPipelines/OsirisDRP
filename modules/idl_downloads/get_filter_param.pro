;-----------------------------------------------------------------------
; NAME:  get_filter_param
;
; PURPOSE: get filter specific parameters
;
; INPUT :  s_Filter     : name of the filter
;          s_FilterFile : absolute path of the filter file 
;          [/DEBUG]     : debug
;
; ADDITIONAL INPUT :
;                    The format of the filter file is:
;                    1. col  : filtername  
;                    2. col  : filter halfpoint lower wavelength side (nm)
;                    3. col  : filter halfpoint upper wavelength side (nm)
;                    4. col  : # of pixels of regular grid
;                    5. col  : min lambda (nm) of regular grid
;                    6. col  : max lambda (nm) of regular grid
;                    7. col  : minimum wavelength (nm) of all real spectra
;                    8. col  : maximum wavelength (nm) of all real spectra
;                    9. col  : app. dispersion in microns per pix
;                    10. col : app. instrument FWHM in mu
;                    11. col : dispersion of the regular grid
;
; NOTES : The corresponding wavelength of the 0th slice of a cube
;         should be app. constant. This wavelength is the minimum
;         wavelength (nm) of all real spectra (col. 5).
;         Col 6 is ignored as col 4.
;
; OUTPUT : structure { s_Name                  : filter name
;                      d_FilterHalfPointLow_nm : filter halfpoint lower wavelength side (nm)
;                      d_FilterHalfPointUp_nm  : filter halfpoint upper wavelength side (nm)
;                      n_Pix                   : # of pixel on regular grid
;                      d_MinRegWL_nm           : min lambda of regular grid
;                      d_MaxRegWL_nm           : max lambda of regular grid
;                      d_MinWL_nm              : minimum wavelength of all real spectra
;                      d_MaxWL_nm              : maximum wavelength of all real spectra
;                      d_Sigma_px              : app. instrument FWHM in mu
;                      d_Dispersion_nmperpix   : app. dispersion in nm per pix }
;
;
; ON ERROR : returns ERR_UNKNOWN from APP_CONSTANTS
;
; NOTES : In order to find the calibration file 'filter_info.list' an
;         environment variable $OSIRIS_DRS_CAL_FILES must be declared
;         containing the directory where the calibration files are stored.
;
; STATUS : untested
;
; HISTORY : 28.9.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------
function get_filter_param, s_Filter, s_FilterFile, DEBUG=DEBUG

   if ( keyword_set ( DEBUG ) ) then $
      debug_info, 'DEBUG INFO (get_filter_param.pro): Getting filter information from '+strg(s_FilterFile)

   if ( NOT file_test(s_FilterFile) ) then $
      return, error ('FAILURE (get_filter_param.pro): File '+strg(s_FilterFile)+' with filter information not found.')

  ; read the filter file

  ; filter_info.list contains:
  ;   1. filtername              :  vs_FilterName
  ;   2.                         :  vd_FilterHalfPointsLow_nm
  ;   3.                         :  vd_FilterHalfPointsUp_nm
  ;   4. - 7. (regular grid)     :
  ;     # of pixels              :  vn_RegPix
  ;     min lambda in nm         :  vd_RegMinWL_nm
  ;     max lambda in nm         :  vd_RegMaxWL_nm
  ;     dispersion in nm per pix :  vd_RegDisp_nmperpix
  ;   8. - 11. (detector grid) : 
  ;     app. minimum begin wavelength in nm           :  vd_MinWL_nm
  ;     app. maximum end wavelength   in nm           :  vd_MaxWL_nm
  ;     mean dispersion               in nm per pixel :  vd_Disp_nmperpix
  ;     app. instrument FWHM          in nm           :  vd_FWHM_nm

   readcol, s_FilterFile, vs_FilterName, vd_FilterHalfPointsLow_nm, vd_FilterHalfPointsUp_nm, vn_RegPix, $
                          vd_RegMinWL_nm, vd_RegMaxWL_nm, vd_RegDisp_nmperpix, $
                          vd_MinWL_nm, vd_MaxWL_nm, vd_Disp_nmperpix, vd_FWHM_nm, FORMAT='A D D D D D D D D D D'

   i_FiltPos = where( vs_FilterName EQ strg(s_Filter(0)), n_Filt)
   if (n_Filt ne 1) then $
      return, error('ERROR (get_filter_param.pro): Filter '+strg(s_Filter)+' defined ' + strg(n_Filt) + $
         ' times in filter list.') 

   return, { s_Name                  : (reform(s_FilterFile[i_FiltPos]))(0), $
             d_FilterHalfPointLow_nm : (reform(vd_FilterHalfPointsLow_nm[i_FiltPos]))(0), $
             d_FilterHalfPointUp_nm  : (reform(vd_FilterHalfPointsUp_nm[i_FiltPos]))(0), $
             n_RegPix                : (reform(vn_RegPix[i_FiltPos]))(0), $
             d_RegMinWL_nm           : (reform(vd_RegMinWL_nm[i_FiltPos]))(0), $
             d_RegMaxWL_nm           : (reform(vd_RegMaxWL_nm[i_FiltPos]))(0), $
             d_RegDisp_nmperpix      : (reform(vd_RegDisp_nmperpix[i_FiltPos]))(0), $
             d_MinWL_nm              : (reform(vd_MinWL_nm[i_FiltPos]))(0), $
             d_MaxWL_nm              : (reform(vd_MaxWL_nm[i_FiltPos]))(0), $
             d_Disp_nmperpix         : (reform(vd_Disp_nmperpix[i_FiltPos]))(0), $ 
             d_FWHM_nm               : (reform(vd_FWHM_nm[i_FiltPos]))(0) }

end
