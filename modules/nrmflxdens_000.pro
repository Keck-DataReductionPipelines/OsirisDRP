;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; NAME:   nrmflxdens_000
;
; PURPOSE:  normalizes cubes to a given fluxdensity
;
; PARAMETERS IN RPBCONFIG.XML :
;         nrmflxdens_COMMON___Window         : half size of the
;                                              extraction window in spectral channels.
;         nrmflxdens_COMMON___Wavelength     : list of wavelengths in microns,
;                                              separated by kommas,
;                                              e.g. '1.65, 2.2'
;         nrmflxdens_COMMON___Fluxdensity    : list of fluxdensities
;                                              in mJy
;                                              at that wavelength,
;                                              separated by kommas
;                                              e.g. '10.,15.5'
;         nrmflxdens_COMMON___Debug          : initializes the debugging mode
;
; INPUT-FILES : None
;
; OUTPUT : None
;
; INPUT : cubes
;
; DATASET : afterwards the normalized datasets.
;
; QUALITY BITS :
;          0th     : checked
;          1st-2nd : ignored
;          3rd     : checked
;
; DEBUG : Nothing special
;
; SAVES : see Output
;
; NOTES : This module performs a normalization. At a specific
;         wavelength this module extracts an averaged collapsed image
;         from 2*Window slices centered at the specified wavelength 
;         from each frame cube. The image is
;         summed up and the multiplicative normalization factor is 
;         the fluxdensity divided by this sum. 
;         If many fluxdensities are given the normalization factors
;         are averaged before they are applied.
;
;         This module requires somehow that the given fluxdensity
;         corresponds to an aperture that covers somewhat the FoV or 
;         in other words the object should be always completely in the FoV. 
;         Otherwise the normalization is arbitrary.
;
;         Ensure that the cubes contain usefule information at the
;         specified wavelengths.
;
;         This module can be useful e.g. before mosaicing low extended
;         sources.
;
;         The wavelength information of each cube must be coded
;         properly in the corresponding headers with the fitskeywords
;         CRPIX1, CRVAL1, CDELT1, and NAXIS1
;
; STATUS : not tested
;
; HISTORY : 12.11.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION nrmflxdens_000, DataSet, Modules, Backbone

    COMMON APP_CONSTANTS

    functionName = 'nrmflxdens_000'
    ; save the starting time
    T = systime(1)

    drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1

    ; check integrity
    stModule =  check_module( DataSet, Modules, Backbone, functionName )
    if ( NOT bool_is_struct ( stModule ) ) then $
       return, error ('ERROR IN CALL ('+strtrim(functionName)+'): Integrity check failed.')

    ; Get all COMMON parameter values
    b_Debug  = fix(Backbone->getParameter('nrmflxdens_COMMON___Debug')) eq 1
    i_Window = fix(Backbone->getParameter('nrmflxdens_COMMON___Window'))
    vd_WL_um = double(strsplit(Backbone->getParameter( 'nrmflxdens_COMMON___Wavelength'),',',/extract))
    vd_FD_Jy = double(strsplit(Backbone->getParameter( 'nrmflxdens_COMMON___Fluxdensity'),',',/extract))

    if ( n_elements(vd_WL_um) ne n_elements(vd_FD_Jy) ) then $
       return, error('ERROR IN CALL ('+strg(functionName)+'): Number of wavelengths and flux densities not equal.')

    nFrames = Backbone->getValidFrameCount(DataSet.Name)
    for i=0, nFrames-1 do begin

       n_Dims = size(*DataSet.Frames[i])

       ; create wavelength vector
       vd_L = get_wave_axis ( DataSet.Headers[i], DEBUG=b_Debug )  ; wavelength axis in meter
       vd_L = vd_L * 1.d6 ; in microns
       d_LL = min ( vd_L )
       d_UL = max ( vd_L )

       ; average intensity at the specified wavelength (vd_WL_um(j))
       vd_Avrg   = [0.]
       vd_FDA_Jy = [0.] 
       vd_WLA_um = [0.] 

       for j=0, n_elements(vd_WL_um)-1 do begin

          ; check if the wavelength is present in the cube
          if ( vd_WL_um(j) ge d_LL and vd_WL_um(j) le d_UL ) then begin

             ; determine the slices to extract from the cube
             i_Pos = my_index( vd_L, vd_WL_um(j) )
             i_L   = (i_Pos-i_Window) > 0
             i_U   = (i_Pos+i_Window) < (n_Dims[1]-1)

             ; create collapsed average image from the specified slices
             s_Image = cube2image ( DataSet.Frames[i], DataSet.IntFrames[i], DataSet.IntAuxFrames[i], $
                                    1., 'AVRG', SRANGE=[i_L,i_U], DEBUG=b_Debug )

             if ( bool_is_struct(s_Image) ) then begin

                ; determine the sum of this image
                mi_Mask = where(s_Image.mb_Valid, n_Valid)

                if ( n_Valid gt 0 ) then begin

                   vd_Avrg   = [vd_Avrg,total(s_Image.md_Image(mi_Mask))]
                   vd_WLA_um = [vd_WLA_um, vd_WL_um(j)]
                   vd_FDA_Jy = [vd_FDA_Jy, vd_FD_Jy(j)]

                endif else $
                   warning, 'WARNING ('+strtrim(functionName)+'): Not enough valid pixels in collapsed slice for wavelength '+strg(vd_WL_um(j))+'microns in set '+strg(i)+'.'

            endif else $
               warning, 'WARNING ('+strtrim(functionName)+'): Cube collapsing failed at wavelength '+strg(vd_WL_um(j))+'microns in set '+strg(i)+'.'

          endif else $
             warning,'WARNING ('+strg(functionName)+'): Wavelength '+strg(vd_WL_um)+'microns is out of range according to the header.' 

       end

       if ( n_elements(vd_Avrg) ge 2 ) then begin

          vd_Avrg   = vd_Avrg(1:*)
          vd_WLA_um = vd_WLA_um(1:*)
          vd_FDA_Jy = vd_FDA_Jy(1:*)

          if ( b_Debug ) then $
             for k=0, n_elements(vd_Avrg)-1 do $
                debug_info,['DEBUG INFO ('+strtrim(functionName)+'): Set               '+strg(i), $
                            '                                 Wavelength        '+strg(vd_WLA_um(k)), $
                            '                                 Average intensity '+strg(vd_Avrg(k)), $
                            '                                 Flux density      '+strg(vd_FDA_Jy(k)) ]

          ; now find the normalizing factor for each wavelength and average them
          vi_Mask = where ( vd_Avrg eq 0., n_Zero )
          if ( n_Zero ne 0 ) then begin

             vd_Avrg   = vd_Avrg(vi_Mask)
             vd_WLA_um = vd_WLA_um(vi_Mask)
             vd_FDA_Jy = vd_FDA_Jy(vi_Mask)

          end

          if ( n_elements(vd_Avrg) ge 1 ) then begin

             vd_Norm = vd_FDA_Jy/vd_Avrg

             if ( b_Debug eq 1 ) then $
                for k=0, n_elements(vd_Norm)-1 do $
                   debug_info,['DEBUG INFO ('+strtrim(functionName)+'): Set               '+strg(i), $
                               '                                 Wavelength        '+strg(vd_WLA_um(k)), $
                               '                                 Normalization     '+strg(vd_Norm(k)) ]

             ; calculate the error of the normalizing factor
             if ( n_elements(vd_Avrg) ge 2 ) then $
                d_ENorm = stddev(vd_Norm) $
             else $
                d_ENorm = 1.

             ; determine the average normalization factor
             d_Norm  = mean(vd_Norm)

             if ( b_Debug eq 1 ) then $
                debug_info,['DEBUG INFO ('+strtrim(functionName)+'): Set                  '+strg(i), $
                            '                                 Normalization        '+strg(d_Norm), $
                            '                                 Error Normalization  '+strg(d_ENorm) ]

             ; now apply the normalizing factor

             pcd_NormFrame       = ptr_new(make_array(/FLOAT,SIZE=n_Dims,VALUE=d_Norm))
             pcd_NormIntFrame    = ptr_new(make_array(/FLOAT,SIZE=n_Dims,VALUE=d_ENorm))
             pcb_NormIntAuxFrame = ptr_new(make_array(/BYTE,SIZE=n_Dims,VALUE=9b))

             v_Status = frame_op ( DataSet.Frames[i], DataSet.IntFrames[i], DataSet.IntAuxFrames[i], $
                                   '*', pcd_NormFrame, pcd_NormIntFrame, pcb_NormIntAuxFrame, 1 )

             if ( NOT bool_is_vector (v_Status) ) then $
                warning,'WARNING ('+strtrim(functionName)+'): Normalization of dataset '+strg(i)+' failed [0].' $
             else if ( v_Status[0] ne 1 ) then $
                     warning,'WARNING ('+strtrim(functionName)+'): Normalization of dataset '+strg(i)+' failed [0].' $
                  else begin
                     add_fitskwd_to_header, DataSet.Headers[i], 1, ['NORMCMMT'], ['This cube has been flux normalized.'], ['a']
                     add_fitskwd_to_header, DataSet.Headers[i], 1, ['NORMUNIT'], ['The units are mJy.'], ['a']
                     add_fitskwd_to_header, DataSet.Headers[i], 1, ['NORMCNST'], [d_Norm], ['f']

                     info,'INFO ('+strtrim(functionName)+'): Normalization of dataset '+strg(i)+' successfully done.'
                  end

         endif else $
          warning, 'WARNING ('+strtrim(functionName)+'): Normalizing of set '+strg(i)+ $
                   ' failed. Only zero average fluxes found.'

       endif else $
          warning, 'WARNING ('+strtrim(functionName)+'): Normalizing of set '+strg(i)+ $
                   ' failed. No valid average intensity found.'

    end

    thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
    if ( Modules[thisModuleIndex].Save eq 1 ) then begin

       b_Stat = save_dataset ( DataSet, nFrames, Modules[thisModuleIndex].OutputDir, stModule.Save, DEBUG=b_Debug )
       if ( b_Stat eq OK ) then begin
          report_success, functionName, T
          return, OK
       endif else return, b_Stat

    end

END
