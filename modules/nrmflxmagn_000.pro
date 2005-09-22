;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; NAME:   nrmflxmagn_000
;
; PURPOSE:  normalizes cubes to given magnitudes for several bands
;
; PARAMETERS IN RPBCONFIG.XML :
;    nrmflxmagn_COMMON___Debug            : initializes the debugging mode
;    nrmflxmagn_COMMON___Filterfile       : absolute path and name of the filter file
;    nrmflxmagn_COMMON___PSF              : Type of the PSF fit
;                                           function: "GAUSSIAN",
;                                           "LORENTZIAN", "MOFFAT"
;    nrmflxmagn_COMMON___LibraryType      : Type of the library star
;    nrmflxmagn_COMMON___LibraryPath      : absolute path to the
;                                           directory with the Pickles spectra
;    nrmflxmagn_COMMON___CalWindow1_um    : lower wavelength limit
;    nrmflxmagn_COMMON___CalWindow2_um      upper wavelenth limit
;                                           of the windows for which
;                                           the fluxes in magnitudes
;                                           have been measured
;    nrmflxmagn_COMMON___Flux_mag         : Fluxes in magnitudes
;                                           measured for the upper windows
;    nrmflxmagn_COMMON___SigmaMult        : The counts are extracted
;                                           from SigmaMult*Sigma of
;                                           the PSF fit.
;    nrmflxmagn_COMMON___LibraryWindow    : float,
;                                           0.2<=Window<=0.8. If a
;                                           library star is used the
;                                           flux window is determined
;                                           as Window*width of the
;                                           valid (exposed) spectrum
;                                           as defined by the filter table.
;
; INPUT-FILES : None
;
; OUTPUT : None
;
; INPUT : cubes
;
; DATASET : no changes
;
; QUALITY BITS :
;          0th     : checked
;          1st-2nd : ignored
;          3rd     : checked
;
; DEBUG : Nothing special
;
; SAVES : The conversion factor
;
; NOTES : 
;         Definitions:
;
;         1. |-----LLLLLLLLL*LLLL*LLLLLLLLLLLL----|   -> regular wavelength
;
;         2. |-*-*-LLLLLLLLLLLLLLLLLLLLLLLLLLL----|   -> regular wavelength
;
;         3. |-----LLLLLLLL*LLLLLLLLLLLLLLLLLL--*-|   -> regular wavelength
;
;
;         LLLLL  : Measured(!) spectrum.
;         *---*  : wavelength range for which the given magnitude has
;                  been measured, calibration window
;                  Preferentially the calibration window should be
;                  covered by light detecting elements. In other words
;                  then it is possible to calibrate the measurement solely
;                  with the measured spectrum.
;
;         The upper three cases can occur:
;         1.         The calibration window is covred by the measured spectrum
;         2. and 3.  The calibration window is not or only partially covered by the
;                    measured spectrum
;
;         Case 1: The flux calibration can be done solely using the
;                 measured spectrum. 
;                 nc : measured counts in the calibration window
;                 fc : flux measured in calibration window, W/(m^2*s)
;                 fc corresponds to nc count -> 1 count corresponds to fc/nc W(m^2*s)
;         Case 2 and 3: The flux calibration must be done using a
;                 library star. The flux window are automatically
;                 selected. The flux window is Window*100 percent of
;                 the measured spectrum centered on the center of the
;                 measured spectrum.
;                 nc : counts from the library spectrum in the calibration window
;                 fc : flux measured in calibration window, W/(m^2*s)
;                 nf : counts from the library spectrum in the flux window
;                 n  : counts in the measured spectrum in the flux window
;                 nf/nc*fc = flux in W/(m^2*s) in the flux window = f
;                 -> n counts correspond to f W/(m^2*s)
;                 -> 1 count corresponds to f/n W/(m^2*s)      
;
;         In the case that a spectrum covers more bands, e.g. H+K,
;         multiple magnitudes for each band can be given. The
;         conversion factors of each band are than averaged.
;
;         Library stars are taken from :
;         A Stellar Spectral Flux Library, 1150 -- 25000 A (A.J. Pickles, PASP 110, 863, 1998)
;         or see the ESO webpage on ISAAC
;         The filenames have the format ukxyz.fits with xyz being the
;         type. Not all types are available. Select the one that
;         matches best your type.
;
; STATUS : not tested
;
; HISTORY : 12.11.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION nrmflxmagn_000, DataSet, Modules, Backbone

    COMMON APP_CONSTANTS

    functionName = 'nrmflxmagn_000'
    ; save the starting time
    T = systime(1)

    drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1

    ; check integrity
    stModule =  check_module( DataSet, Modules, Backbone, functionName )
    if ( NOT bool_is_struct ( stModule ) ) then $
       return, error ('ERROR IN CALL ('+strtrim(functionName)+'): Integrity check failed.')

    ; Get all COMMON parameter values and check their integrity
    b_Debug         = fix(Backbone->getParameter('nrmflxmagn_COMMON___Debug')) eq 1
    c_FFile         = Backbone->getParameter('nrmflxmagn_COMMON___Filterfile')
    c_PSF           = strupcase(strg(Backbone->getParameter('nrmflxmagn_COMMON___PSF')))
    c_LibraryType   = strlowcase(strg(Backbone->getParameter('nrmflxmagn_COMMON___LibraryType')))
    c_LibraryPath   = strg(Backbone->getParameter('nrmflxmagn_COMMON___LibraryPath'))
    vd_CW1_um       = double(strsplit(Backbone->getParameter('nrmflxmagn_COMMON___CalWindow1_um'),',',/extract))
    vd_CW2_um       = double(strsplit(Backbone->getParameter('nrmflxmagn_COMMON___CalWindow2_um'),',',/extract))
    vd_Fl           = exp(-0.4*double(strsplit(Backbone->getParameter('nrmflxmagn_COMMON___Flux_mag'),',',/extract)))
    d_SigmaMult     = double(Backbone->getParameter('nrmflxmagn_COMMON___SigmaMult'))
    d_LibraryWindow = double(Backbone->getParameter('nrmflxmagn_COMMON___LibraryWindow'))

    ; check the parameters

    ; check the PSF keyword
    if ( c_PSF ne 'GAUSSIAN' and c_PSF ne 'LORENTZIAN' and c_PSF ne 'MOFFAT' ) then $
       return, error ('ERROR IN CALL ('+functionName+'): Unknown PSF ('+strg(c_PSF)+').')
    ; check extraction radii
    if ( d_SigmaMult le 0. ) then $
       return, error ('ERROR IN CALL ('+functionName+'): Extraction FWHM is less than zero.')
    ; check the Window width parameter
    if ( d_LibraryWindow lt .2 or d_LibraryWindow gt .8 ) then $
       return, error ('ERROR IN CALL ('+functionName+'): Extraction window must be between 0.2 and 0.8.')
    ; check number of wavelength limits and fluxes
    if ( n_elements(vd_CW1_um) ne n_elements(vd_Fl) or $
         n_elements(vd_CW2_um) ne n_elements(vd_Fl) ) then $
       return, error('ERROR IN CALL ('+strg(functionName)+'): Number of wavelengths and magnitudes do not conform.')    ; check wavelength limits
    for i=0, n_elements(vd_Fl)-1 do $
       if ( vd_CW1_um(i) ge vd_CW2_um(i) ) then $
          return, error('ERROR IN CALL ('+strg(functionName)+'): Calibration wavelengths not set correctly.')
    ; done with the parameter checks

    ; get the filter keyword
    c_Filter = strg( get_kwd(DataSet.Headers[0], 1, "SFILTER") )
    ; get the wavelengths of the new regular grid
    s_Filter = get_filter_param ( c_Filter, c_FFile )
    if ( NOT bool_is_struct ( s_Filter ) ) then $
       return, error ('FAILURE ('+functionName+'): Failed to get the filter information.')

    d_MinLExposed_um = s_Filter.d_MinWL_nm/1000.    ; These are the minimum and maximum (app.) wavelengths that
    d_MaxLExposed_um = s_Filter.d_MaxWL_nm/1000.    ;   "are exposed to light"
    ; get the regular wavelength grid of the input dataset
    vd_LRegular_um   = get_wave_axis ( DataSet.Headers(0), DEBUG=b_Debug ) * 1.d6  ; wavelength axis in microns
    d_MinLRegular_um = min ( vd_LRegular_um )
    d_MaxLRegular_um = max ( vd_LRegular_um ) 
    if ( d_MinLExposed_um lt d_MinLRegular_um or d_MaxLExposed_um gt d_MaxLRegular_um ) then $
       return, error('FAILURE ('+functionName+'): Checking the input revealed that the spectrum is exposed beyond the regular grid. That could be a severe error in the calibration tables (filter file).')
    if ( b_Debug eq 1 ) then $
       debug_info, 'DEBUG INFO ('+functionName+'): Measured spectrum exposed (acc. to filter table) from '+$
          strg(d_MinLExposed_um) + ' microns to '+strg(d_MaxLExposed_um)+' microns.'


    ; bool to indicate whether we have to use a library star
    b_Library = 0
    ; check if the calibration wavelength limits are contained in the measured spectrum
    dummy = where ( vd_CW1_um lt d_MinLExposed_um or vd_CW2_um gt d_MaxLExposed_um, n_Err )
    if ( n_Err gt 0 ) then begin
       ; in this case we need a library star

       b_Library = 1
       ; check if the star is in the library
       c_File = strg(c_LibraryPath)+'/uk'+strg(c_LibraryType)+'.fits'
       if ( NOT file_test ( c_File ) ) then $
          return, error ('ERROR IN CALL ('+functionName+'): Star ' + strg(c_LibraryType) + ' file '+$
             strg(c_File)+'not found in library.' )
       if ( b_Debug ) then $
          debug_info, 'DEBUG INFO ('+functionName+'): Star ' + strg(c_LibraryType) + ' file '+$
             strg(c_File)+' reading.'
       ; read the library star
       vd_LibSpec   = readfits( c_File, h_LibHead )
       p_LibHead    = ptr_new ( h_LibHead )
       vd_LibL_um   = get_wave_axis ( p_LibHead, DEBUG=b_Debug, /NOUNIT )/1.e4  ; wavelength axis in microns
       d_MinLLib_um = min ( vd_LibL_um )
       d_MaxLLib_um = max ( vd_LibL_um )
       if ( b_Debug ) then $
          debug_info, 'DEBUG INFO ('+functionName+'): Library star spectrum ranges from ' + $
             strg(d_MinLLib_um) + 'microns to '+ strg(d_MaxLLib_um)+'microns.'

       ; check if the required windows are covered by the library star spectrum
       dummy = where ( vd_CW1_um lt d_MinLLib_um or vd_CW2_um gt d_MaxLLib_um, n_ErrCW )
       if ( n_ErrCW gt 0 ) then $
          return, error('ERROR IN CALL ('+functionName+'): At least one calibration wavelength limit is not covered by the library star spectrum.')

       ; determine the flux window
       d_d    = (d_MaxLExposed_um - d_MinLExposed_um)
       d_dp   = (1.-d_LibraryWindow)/2.
       d_MinLFluxWindow_um  = d_MinLExposed_um+d_d*d_dp
       d_MaxLFluxWindow_um  = d_MaxLExposed_um-d_d*d_dp
       i_LPos = my_index( vd_LRegular_um, d_MinLFluxWindow_um )
       i_UPos = my_index( vd_LRegular_um, d_MaxLFluxWindow_um )

       ; consistency checks
       if ( d_MinLFluxWindow_um lt d_MinLExposed_um or d_MinLFluxWindow_um gt d_MaxLExposed_um or $
            d_MaxLFluxWindow_um lt d_MinLExposed_um or d_MaxLFluxWindow_um gt d_MaxLExposed_um or $
            d_MaxLFluxWindow_um lt d_MinLFluxWindow_um ) then $
          return, error('FATAL ERROR ('+functionName+'): Internal error while calibrating with a library star.') 

       if ( b_Debug ) then begin
          debug_info, 'DEBUG INFO ('+functionName+'): A library star from '+strg(c_File)+' will be used.'
          debug_info, 'DEBUG INFO ('+functionName+'): The library star spectrum ranges from '+strg(d_MinLLib_um)+$
                ' microns to '+ strg(d_MaxLLib_um)+' microns.'
          debug_info, 'DEBUG INFO ('+functionName+'): Extracting counts from measured spectrum from  '+$
             strg(d_MinLFluxWindow_um) + ' microns to '+strg(d_MaxLFluxWindow_um)+' microns.'
       endif

    endif else $
       if ( b_Debug ) then $
          debug_info, 'DEBUG INFO ('+functionName+'): No library star is needed.'

    n_Dims = size(*DataSet.Frames(0))

    ; now loop over the number of input fluxes/magnitudes
    for j=0, n_elements(vd_Fl)-1 do begin

       if ( b_Debug ) then $
          debug_info,'DEBUG INFO ('+functionName+'): Working on magnitude no. '+strg(j)+' now.'

       vd_ConvFactor = [0.]

       ; determine the counts in the calibration window if not using a library
       ; star or in the automatically determined flux window

       if ( b_Library eq 0 ) then begin
          ; determine the slices to extract from the cube
          i_LPos = my_index( vd_LRegular_um,vd_CW1_um(j) )
          i_UPos = my_index( vd_LRegular_um,vd_CW2_um(j) )
       endif 

       ; collapse the dataset
       s_Image = cube2image ( DataSet.Frames(0), DataSet.IntFrames(0), DataSet.IntAuxFrames(0), $
                              1., 'SUM', SRANGE=[i_LPos,i_UPos], DEBUG=b_Debug )

       if ( bool_is_struct(s_Image) ) then begin

          ; do the PSF fit
          mf_PSF = mpfit2dpeak ( s_Image.md_Image, v_Fit, WEIGHTS=s_Image.md_Weight, /TILT, $
                                 GAUSS      = c_PSF eq 'GAUSS', $
                                 LORENTZIAN = c_PSF eq 'LORENTZIAN', $
                                 MOFFAT     = c_PSF eq 'MOFFAT' )

          if ( b_Debug ) then $
             debug_info, 'DEBUG INFO ('+functionName+'): Found star at X='+strg(v_Fit(4))+', Y='+$
                strg(v_Fit(5))+', SigmaX='+ strg(v_Fit(2))+', SigmaY='+strg(v_Fit(3))

          dist_circle, m_DistMask, [n_Dims(2),n_Dims(3)], v_Fit(4), v_Fit(5)
          vi_Mask = where ( m_DistMask le max([v_Fit(2),v_Fit(3)])*d_SigmaMult, n_Mask )

          if ( b_Debug ) then $
             debug_info, 'DEBUG INFO ('+functionName+'): Extracting counts from '+strg(n_Mask)+' Pixel.'

          if ( n_Mask gt 0 ) then begin

             ; these are the measured counts in the calibration window/ flux window
             d_Counts = total((s_Image.md_Image)(vi_Mask))

             if ( b_Debug ) then $
                debug_info, 'DEBUG INFO ('+strg(functionName)+'): Found '+strg(d_Counts)+$
                   ' counts in the calibration spectrum.'

             ; do we have to continue with the library star ?
             if ( b_Library eq 1 ) then begin

                ; get the flux of the library star in the calibration and extraction window
                vi_LibCWMask = where ( vd_LibL_um ge vd_CW1_um(j) and vd_LibL_um le vd_CW2_um(j), n_LibCWMask ) 
                vi_LibFWMask = where ( vd_LibL_um ge d_MinLFluxWindow_um and $
                                       vd_LibL_um le d_MaxLFluxWindow_um, n_LibFWMask ) 

                if ( n_LibCWMask gt 0 and n_LibFWMask gt 0 ) then begin

                      d_LibFluxCW   = total(vd_LibSpec(vi_LibCWMask))
                      d_LibFluxFW   = total(vd_LibSpec(vi_LibFWMask))
                      d_FWFlux      = d_LibFluxCW/d_LibFluxFW*vd_Fl(j)
                      vd_ConvFactor = [vd_ConvFactor, d_FWFlux/d_Counts]

                endif else $
                   warning,'WARNING ('+functionName+'): Library star extraction failed. Some of the specified wavelengths are not in the spectrum ('+strg(n_LibCWMask)+'/'+strg(n_LibFWMask)+').'

             endif else begin

                ; calculate the conversion factor
                vd_ConvFactor = [vd_ConvFactor, vd_Fl(j)/d_Counts]

             end

          endif else $
             warning,'WARNING ('+functionName+'): PSF mask to extract spectrum from is too small. Enlarge the SigmaMult parameter.'

       endif else $
          warning,'WARNING ('+functionName+'): Collapsing of datacube failed.'

    end

    if ( n_elements(vd_ConvFactor) gt 1 ) then begin
       d_ConvFactor = mean(vd_ConvFactor(1:*))
       if ( b_Debug ) then $
          debug_info, 'DEBUG INFO ('+functionName+'): Found conversion factor '+strg(d_ConvFactor)+' W/(m^2*s) per count.'
    endif else $
       return, error('FAILURE ('+functionName+'): Determination of conversion factors failed.')


    thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
    c_File = make_filename ( DataSet.Headers[0], Modules[thisModuleIndex].OutputDir, stModule.SaveExt )
    if ( NOT bool_is_string(c_File) ) then $
       return, error('FAILURE ('+functionName+'): Output filename creation failed.')

    if ( strpos(c_File ,'.fits' ) ne -1 ) then $
       c_File1 = strmid(c_File,0,strlen(c_File)-5)+'_'+strg(0)+'.fits' $
    else begin 
       warning, 'WARNING ('+functionName+'): Filename is not fits compatible. Adding .fits.'
       c_File1 = c_File+'_'+strg(0)+'.fits'
    end

    mkhdr, h_H, float(d_ConvFactor)
    sxaddpar, h_H, 'COMMENT', 'Conversion factor in W/(m^2*s) per count'
    writefits, c_File1, float(d_ConvFactor), h_H

    if ( b_Debug ) then begin
       debug_info, 'DEBUG INFO ('+functionName+'): File '+c_File1+' successfully written.'
       fits_help, c_File1
    end

    report_success, functionName, T

    Return, OK

END
