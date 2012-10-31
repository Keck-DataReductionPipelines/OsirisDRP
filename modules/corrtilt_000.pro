
;-----------------------------------------------------------------------

function calc_atmo_diff_shift_in_pixel, vd_L, d_Pressure, d_Temperature, d_Elevation, $
                                        d_Parang, d_Pa_Spec, d_Scale, DEBUG=DEBUG

;   vd_L          : wavelengths in micron
;   d_Pressure    : pressure in millibars
;   d_Temperature : ambient temperature in Kelvin
;   d_Elevation   : elevation of the telescope in degrees
;   d_Parang      : parallactic angle in degrees
;   d_Pa_Spec     : position angle of the spectrograph
;   d_Scale       : scale im mas

; this formula is based on Allen's astrophysical quantities and is an
; approximation for wavelengths longer than 400nm. Since
; meteorological parameters are not written to the fits-header, we
; should assume here 620 mbars and 273 Kelvin.

   functionName = "calc_atmo_diff_shift_in_pixel.pro"

   if ( keyword_set ( DEBUG ) ) then begin
      print, 'INFO (' + functionName + '): Min wavelength = ' + strg(min(vd_L)) + ' micron.'
      print, 'INFO (' + functionName + '): Scale = ' + strg(d_Scale) + ' mas.'
   end      

   vd_Deflection = (0.0000744d * (1. + 0.00563d/vd_L^2)) * tan( (90.-d_Elevation) / !RADEG ) / $
                   d_Scale * d_Pressure / d_Temperature * 206265. * 1000.

   vd_Deflection = vd_Deflection - vd_Deflection(0)  

   return, { vd_DeltaX : vd_Deflection * sin ( ( d_Pa_Spec - d_Parang ) / !RADEG ), $
             vd_DeltaY : vd_Deflection * cos ( ( d_Pa_Spec - d_Parang ) / !RADEG ) }

end

;-----------------------------------------------------------------------

function calc_ao_bench_shift_in_pixel, vd_L, d_Scale, jul_date,DEBUG=DEBUG

; the shift introduced by the AO bench has been determined
; empirically.

; vd_L    : Wavelengths in nm
; d_Scale : Scale in mas

   functionName = "calc_ao_bench_shift_in_pixel.pro"

   if ( keyword_set ( DEBUG ) ) then begin
      print, 'INFO (' + functionName + '): Min wavelength = ' + strg(min(vd_L)) + ' nm.'
      print, 'INFO (' + functionName + '): Scale = ' + strg(d_Scale) + ' mas.'
   end      

	; IR dichroic used on Keck II bench before Sept 2009 use old equation
	; Use new equation (SAW measured) for after Sept 2009
   if (jul_date le 55076.02) then $
	vd_Motion_mas = -20.4 + sqrt ( -16204. + 19.66 * vd_L - 0.00304 * vd_L^2 ) $
	else vd_Motion_mas = -55.8 + sqrt ( -7516.5 + 12.38 * vd_L - 0.00193 * vd_L^2 )

   vi_NAN = where ( finite ( vd_Motion_mas, /NAN ), n_NAN )

   if ( n_NAN gt 0 ) then begin
      warning, 'WARNING (' + functionName + '): AO bench shifts contain abnormal values. Setting these to 0.'
      vd_Motion_mas(vi_NAN) = 0.
   end

   vd_Motion_mas = vd_Motion_mas - vd_Motion_mas(0)

   return, { vd_DeltaX :  sin (48. / !RADEG ) * vd_Motion_mas / d_Scale, $
             vd_DeltaY : -cos (48. / !RADEG ) * vd_Motion_mas / d_Scale }

end 
   
;-----------------------------------------------------------------------




;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; @BEGIN
;
; @NAME corrtilt_000
;
; @PURPOSE This module corrects for spatial shifts along the spectral
; axis in the datacube due to atmospheric differential dispersion and 
; other instrumental effects
;
; @@@PARAMETERS
;
;    ALL_COMMON___Colors             : BOOL, to initialize the colored
;                                      plots when in debugging mode, 
;                                      overrides the current colortable
;    corrtilt_COMMON___Debug         : BOOL, initialize debugging mode. 
;    corrtilt_COMMON___MinShift      : BOOL, apply minimum fractional
;                                      shift. E.g. a shift of 0.8 can
;                                      be 0 (integer) + 0.8
;                                      (fractional) shift or -1
;                                      (integer) and 0.2 (fractional)
;                                      shift. Enabling this method
;                                      results in a shifted datacube
;                                      with non-smooth borders
;                                      (considering the inside bit).
;    corrtilt_COMMON___Atmo          : BOOL, correct atmospheric
;                                      differential refraction tilt
;    corrtilt_COMMON___AOBench       : BOOL, correct tilt due to AO bench
;    corrtilt_COMMON___Temperature   : FLOAT, ambient temperature in
;                                      Kelvin, only for differential
;                                      atmospheric refraction correction
;    corrtilt_COMMON___Pressure      : FLOAT, ambient pressure in
;                                      mbars, only for differential
;                                      atmospheric refraction correction
;
; @@@DRF-PARAMETERS
;
;    None
;
; @CALIBRATION-FILES None
;
; @INPUT cubes
;
; @OUTPUT None
;
; @MAIN None
;
; @QBITS verified
;
; @DEBUG  Debugging mode should only be enabled when dealing with
;         datasets of stellar objects with a well defined PSF. In
;         debugging mode the center of the PSF is determined before
;         and after having applied the shift using the
;         CNTRD function from the astro library. 
;
; @@@SAVES
;          Always        : nothing
;          SAVE tag      : saves the shifted data, Suffix='_cctlt'
;          SAVEONERR tag : saves the found shifts as an image
;                          [2,#channels] with [0,*] the x shifts and 
;                          [1,*] the y shifts, Suffix='__ctlt'
;
; @@@@NOTES  
;            - This modules shifts each slice of a datacube to correct
;              for atmospheric differential dispersion and and shift
;              introduced by the AO bench. In the formulaes below the
;              X-axis is the 2nd axis in the cube and the y-axis is
;              the 3rd axis in the cube
;              The shift due to differential atmospheric dispersion is
;              calculated based upon Allen's astrophysical
;              quantities. The deflection $\alpha$ at a particular 
;              wavelength in radians is
;              $$d(atmo) = \frac{P}{T}*[0.0000744*(1+\frac{0.00563}{\lambda^2})]*tan(90.-E)$$
;              with P: pressure in mbars, T: temperature in K,
;              $\lambda$: wavelength in micron, E: elevation of the
;              telescope.
;              The shift to be applied is then
;              $$\Delta X = -d(atmo)*\sin{(PA_SPEC-PARANG)}$$ and
;              $$\Delta Y = -d(atmo)*\cos{(PA_SPEC-PARANG)}$$
;              with PA_SPEC: position angle of the spectrograph and
;              PARANG: the parallactic angle.\\
;              The shift $\Delta$ in mas due to the AO bench has been determined
;              empirically:
;              $$d(bench) = -20.4 + \sqrt{-16204+19.66*\lambda-0.00304*\lambda^2}$$ 
;              The shift to be applied is then
;              $$\Delta X = -\sin{48}*d(bench)$$
;              $$\Delta Y = \cos{48}*d(bench)$$
;
;            - The slices are shifted by bilinear interpolation
;
;            - This module works on cubes only. Many cubes may be
;              treated.
;
;            - All slices in a datacube are shifted to the reference
;              position determined by the first slice in a data cube.
;
;            - Several header keywords are read from the header. If
;              PA_SPEC is not present in the header (as in older
;              version), the position angle of the spectrograph is
;              determined from the keywords 'ROTPOSN' - 'INSTANGL'.
;
;            - When correcting the tilt the resulting cube could 
;              become larger (in spatial dimensions). If pixel 0,0
;              of the the 0th slice of the unshifted cube coincides
;              with pixel 0,0 of the new (larger) cube we do not need
;              to update RA and DEC. Otherwise the offset in RA and
;              DEC due to the enlargement is calculated, added to RA and DEC and
;              written as a fits keyword (CRRA and CRDEC) to the
;              individual headers. When mosaicing these keywords must
;              be read.
;
;            - Due to bilinear interpolation always a whole row/column
;              is lost in shift direction !!!
;
;            - Here is an example DRF
;              \begin{verbatim}
;  <?xml version="1.0" encoding="UTF-8"?>
;  <!-- s060601_a001001 -->
;  <DRF
;  LogPath="/afs/ph1.uni-koeln.de/akgroup/working/ISERLOHE/OSIRIS/ColPipe/drf_queue/logs" 
;  ReductionType="ORP_SPEC">
;    <dataset
;       InputDir="/afs/ph1.uni-koeln.de/akgroup/working/ISERLOHE/OSIRIS/ColPipe/out" 
;       Name="s060601_a001001" 
;       OutputDir="/afs/ph1.uni-koeln.de/akgroup/working/ISERLOHE/OSIRIS/ColPipe/out">
;      <fits FileName="s060602_a005001_datset_Kbb_050_0.fits" />
;    </dataset>
;    <module 
;       Name="Correct Tilt" 
;       OutputDir="/afs/ph1.uni-koeln.de/akgroup/working/ISERLOHE/OSIRIS/ColPipe/out"
;       Save="1" SaveOnErr="1" Skip="0" />
;  </DRF>
;              \end{verbatim}
;
; @HISTORY  5.9.2006, created
;
; @AUTHOR   Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;		James Larkin, Mike McElwain, Shelley Wright (2007) 
;		modified and applied originally routine as Correct Dispersion
;
; @MODIFIED S. Wright (July 2009) to correctly handle quality bits 
;		extension 2 of reduced fits
;
;	S. Wright modified for new IR dichroic instrumental
;	chromatic dispersion after June 2009
;
; @END
;
;-----------------------------------------------------------------------

FUNCTION corrtilt_000, DataSet, Modules, Backbone

    COMMON APP_CONSTANTS

    functionName = 'corrtilt_000'


    ; save the starting time
    T = systime(1)

    drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1

    b_Debug       = fix   ( strg(Backbone->getParameter('corrtilt_COMMON___Debug'))) eq 1
    b_MinShift    = fix   ( strg(Backbone->getParameter('corrtilt_COMMON___MinShift')) ) eq 1
    b_Atmo        = fix   ( strg(Backbone->getParameter('corrtilt_COMMON___Atmo')) ) eq 1
    b_AOBench     = fix   ( strg(Backbone->getParameter('corrtilt_COMMON___AOBench')) ) eq 1
    d_Pressure    = float ( strg(Backbone->getParameter('corrtilt_COMMON___Pressure')) )
    d_Temperature = float ( strg(Backbone->getParameter('corrtilt_COMMON___Temperature')) )

    ; to initialize colors, when plotting colors can be accessed with color=1..8
;    if ( fix( Backbone->getParameter('ALL_COMMON___Colors') ) eq 1 ) then init_colors

    if ( b_Atmo eq 0 and b_AOBench eq 0 ) then begin
       info, 'INFO (' + functionName + '): Nothing to be done.'
       return, OK
    end

    i_Delta = 10  ; for the CNTRD function
                  ; total +-10 slices around the actual
                  ; position to get a better S/N in the image

    nFrames = Backbone->getValidFrameCount(DataSet.Name)
    thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)

    ; verify the bits
    check_bits, DataSet.Frames, DataSet.IntFrames, DataSet.IntAuxFrames, nFrames

    ; loop over the input sets
    for i=0, nFrames-1 do begin

       ; only do cubes
       if ( (size(*DataSet.Frames(i)))(0) eq 3 ) then begin
          info, 'INFO (' + functionName + '): Working on set ' + strg(i) + ' now.'

          ; get the wavelengths in microns
; Don't have get_wave_axis routine. Quick work around. Jan 9,2007:  JEL.
;          vd_L = get_wave_axis ( DataSet.Headers(i), s_Parameters, DEBUG=b_Debug ) * 1.E6
          sz = size(*DataSet.Frames(i))
          disp = float( sxpar( *DataSet.Headers(i), 'CDELT1', count= n_disp))/1.E3   ; Raw value is in nm.
          if ( n_disp ne 1) then $
            warning, ' WARNING (' + functionName + '): CDELT1 not found or not unique in set ' + strg(i) + '.' 
          info, 'INFO (' + functionName + '): Found CDELT1 of ' + strg ( disp ) + ' microns.'

          initial = float( sxpar( *DataSet.Headers(i), 'CRVAL1', count= n_val))/1.E3   ; Raw value is in nm.
          if ( n_val ne 1) then $
            warning, ' WARNING (' + functionName + '): CRVAL1 not found or not unique in set ' + strg(i) + '.' 
          info, 'INFO (' + functionName + '): Found initial wavelength of ' + strg ( initial ) + ' microns.'
          vd_L = findgen(sz[1])*disp + initial
; End work around.

	  ; read in julian date for instrumental dispersion equation choice
   	  jul_date = float(sxpar(*DataSet.Headers[i],'MJD-OBS', count=jnum))
         if ( n_disp ne 1) then $
            warning, ' WARNING (' + functionName + '): MJD-OBS is not found ' + strg(i) + '.' 
          info, 'INFO (' + functionName + '): Found MJD-OBS of ' + strg ( jul_date ) + ' Julian Date.'

          ; arrays for the calculated offsets in pixel
          vd_DeltaX = fltarr ( n_elements(vd_L) )  &  vd_DeltaY = fltarr ( n_elements(vd_L) )

          ; get the fitsheader keywords
          d_Elevation   = float( sxpar ( *DataSet.Headers(i), 'EL', count = n_El ) )
          if ( n_El ne 1 ) then $
             warning, ' WARNING (' + functionName + '): EL not found or not unique in set ' + strg(i) + '.' 
          info, 'INFO (' + functionName + '): Found telescope elevation of ' + strg ( d_Elevation ) + ' degrees.'

          d_Parang   = float( sxpar ( *DataSet.Headers(i), 'PARANG', count = n_Parang ) )
          if ( n_Parang ne 1 ) then $
             warning, ' WARNING (' + functionName + '): PARANG not found or not unique in set ' + strg(i) + '.' 
          info, 'INFO (' + functionName + '): Found parallactic angle of ' + strg ( d_Parang ) + ' degrees.'

          d_Pa_Spec   = float( sxpar ( *DataSet.Headers(i), 'PA_SPEC', count = n_Pa_Spec ) )
          if ( n_Pa_Spec ne 1 ) then begin
             warning, ' WARNING (' + functionName + '): PA_SPEC not found or not unique in set ' + $
                      strg(i) + '. Trying ROTPOSN and INSTANGL.' 
             d_RotPos    = float( sxpar ( *DataSet.Headers(i), 'ROTPOSN', count = n_RotPos ) )
             d_InstAngle = float( sxpar ( *DataSet.Headers(i), 'INSTANGL', count = n_InstAngle ) )
             if ( n_RotPos ne 1 or n_InstAngle ne 1 ) then $
                warning, ' WARNING (' + functionName + '): Cannot determine angle of the spectrograph in set ' + $
                         strg(i) + '.'  $
             else $
               d_Pa_Spec = d_RotPos - d_InstAngle
          end             
          info, 'INFO (' + functionName + '): Found position angle of the spectrograph of ' + $
                strg ( d_Pa_Spec ) + ' degrees.'

          ; the real scale is not exactly the keyword
; Not sure why get_real_scale is needed.
; Trying just raw parameter. JEL Jan 9, 2007
;          d_Scale = get_real_scale(float( sxpar ( *DataSet.Headers(i), 'SSCALE', count = n_Scale ) ), 1 )
          d_Scale = (float( sxpar ( *DataSet.Headers(i), 'SSCALE', count = n_Scale ) ))
          if ( n_Scale ne 1 ) then $
             warning, 'WARNING (' + functionName + '): Scale of the spectrograph not found or not unique in set ' + strg(i) + '.' 
          if ( d_Scale lt 0. ) then $
             warning, 'WARNING (' + functionName + '): Cannot determine actual scale of spectrograph in set ' + strg(i)
          info, 'INFO (' + functionName + '): Found scale of the spectrograph ' + strg ( d_Scale ) + ' as.'

          ; calculate the shifts due to atmospheric differential refraction 
          if ( b_Atmo eq 1 ) then begin

             st_Atmo_Shifts  = calc_atmo_diff_shift_in_pixel ( vd_L, d_Pressure, d_Temperature, d_Elevation, $
                                                               d_Parang, d_Pa_Spec, d_Scale*1000., DEBUG=b_Debug )

             vd_DeltaX = vd_DeltaX + st_Atmo_Shifts.vd_DeltaX 
             vd_DeltaY = vd_DeltaY + st_Atmo_Shifts.vd_DeltaY 

             if ( b_Debug eq 1 ) then begin
                dummy = max(abs(st_Atmo_Shifts.vd_DeltaX),mx)
                dummy = max(abs(st_Atmo_Shifts.vd_DeltaY),my)
                info, 'INFO (' + functionName + '): Maximum shift due to atmosphere ' + $
                      strg(st_Atmo_Shifts.vd_DeltaX(mx)) + ',' + $
                      strg(st_Atmo_Shifts.vd_DeltaY(my))
             end

          end

          ; get the shift due to the AO bench
          if ( b_AOBench eq 1 ) then begin

             st_Bench_Shifts = calc_ao_bench_shift_in_pixel( vd_L*1e3, d_Scale*1000., jul_date,DEBUG=b_Debug  )

             vd_DeltaX = vd_DeltaX + st_Bench_Shifts.vd_DeltaX 
             vd_DeltaY = vd_DeltaY + st_Bench_Shifts.vd_DeltaY 

             if ( b_Debug eq 1 ) then begin
                dummy = max(abs(st_Bench_Shifts.vd_DeltaX),mx)
                dummy = max(abs(st_Bench_Shifts.vd_DeltaY),my)
                info, 'INFO (' + functionName + '): Maximum shift due to AO bench ' + $
                      strg(st_Bench_Shifts.vd_DeltaX(mx)) + ',' + $
                      strg(st_Bench_Shifts.vd_DeltaY(my))
             end

          end

          if ( b_Debug eq 1 ) then begin
             dummy = max(abs(vd_DeltaX),mx)
             dummy = max(abs(vd_DeltaY),my)
             info, 'INFO (' + functionName + '): Maximum total shift ' + $
                   strg(vd_DeltaX(mx)) + ',' + strg(vd_DeltaY(my))
          end

          ; now shift the cube

          ; some shorts
          pcf_Frame       = DataSet.Frames(i)
          pcf_IntFrame    = DataSet.IntFrames(i)
          pcb_IntAuxFrame = DataSet.IntAuxFrames(i)
          p_Header        = DataSet.Headers(i)

          n_Dims = size( *pcf_Frame )  ; size of the unshifted datacube

          ; we are not really calculating the shift but the displacement (that is
          ; why the minus sign). The above formulaes are for exchanged X/Y axes
          ; (thats why we swap them).
          vd_xshift = -vd_DeltaY
          vd_yshift = -vd_DeltaX

          if ( b_MinShift eq 1 ) then begin
             info, 'INFO (' + functionName + '): Optimizing shifts.'
             vi_x = fix(round(vd_xshift))   ; integer shifts
             vi_y = fix(round(vd_yshift))
          endif else begin
             vi_x = fix(vd_xshift)          ; integer shifts
             vi_y = fix(vd_yshift)
          end

          vd_x = vd_xshift - vi_x        ; fractional shifts
          vd_y = vd_yshift - vi_y

          dummy = where ( abs(vi_x + vd_x - vd_xshift) gt 0.001 or $
                          abs(vi_y + vd_y - vd_yshift) gt 0.001, n_Mask )
          if ( n_Mask gt 0 ) then $
             return, error('FATAL ERROR (' + functionName + '): Error determining integer and fractional shifts. Exiting.')

          ; pixel 0,0 of the old cube goes to pixel i_MinX, i_MinY of the new cube
          ; i_MinX and i_MinY are always 0 or positive (remember, the 0th slice is
          ; never shifted)
          i_MinX = abs(min(vi_x))
          i_MinY = abs(min(vi_y))
 
          ; now we convert the integer shifts to array index shifts (which are >= 0)
          vi_xi = i_MinX + vi_x
          vi_yi = i_MinY + vi_y
   
          dummy = where ( vi_xi lt 0 or vi_yi lt 0, n_Mask )
          if ( n_Mask gt 0 ) then $
             return, error('FATAL ERROR (' + functionName + '): Found negative array index shifts. Exiting.')

          ; determine spatial size of the shifted cube
          nn1 = n_Dims(2) + max(vi_xi) ; x-size of the old cube + the greatest array index shift
          nn2 = n_Dims(3) + max(vi_yi) ; y-size of the old cube + the greatest array index shift
          sxaddpar, *Dataset.Headers(i), 'NAXIS2', nn1
          sxaddpar, *Dataset.Headers(i), 'NAXIS3', nn2

          info, 'INFO (' + functionName + '): Size of unshifted cube ' + strg(n_Dims(2)) + ' ' + strg(n_Dims(3))
          info, 'INFO (' + functionName + '): Size of shifted cube ' + strg(nn1) + ' ' + strg(nn2)
          info, 'INFO (' + functionName + '): Coord. 0,0 of 0th slice shifted to ' + strg(i_MinX) + ',' + strg(i_MinY)

          if ( i_MinX ne 0 or i_MinY ne 0 ) then begin

             ; we have to update the RA and DEC keyword
             info, 'INFO (' + functionName + '): Updating Ra and Dec.'
             d_Ra = double(sxpar ( *DataSet.Headers(i), 'RA', count=n ))
             if ( n ne 1 ) then $
                return, error ('FAILURE (' + functionName + '): RA keyword not found in set ' + strg(i) + '.')
             d_Dec = double(sxpar ( *DataSet.Headers(i), 'DEC', count=n ))
             if ( n ne 1 ) then $
                return, error ('FAILURE (' + functionName + '): DEC keyword not found in set ' + strg(i) + '.')
             vd_Coords = det2coord(float([-i_MinX, -i_MinY]), d_RA, d_Dec, d_Scale, d_Pa_Spec/!RADEG)
             ; sxaddpar, *Dataset.Headers(i), 'CRRA', vd_Coords(0)
             ; sxaddpar, *Dataset.Headers(i), 'CRDEC', vd_Coords(1)
            
             radec, vd_Coords(0), vd_Coords(1), ihr, imin, xsec, ideg, imn, xsc

             ra_hr=strtrim(ihr,2)
             ra_min=strtrim(imin,2)
             ra_sec=strtrim(string(Format='(F5.2)',xsec),2)

             dec_hr=strtrim(ideg,2)
             dec_min=strtrim(imn,2)
             dec_sec=strtrim(string(Format='(F4.1)',xsc),2)

             sxaddpar, *Dataset.Headers(i), 'RA', vd_Coords(0), 'telescope right ascension ('+ra_hr+':'+ra_min+':'+ra_sec+' deg)' 
             sxaddpar, *Dataset.Headers(i), 'DEC', vd_Coords(1), 'telescope declination ('+dec_hr+':'+dec_min+':'+dec_sec+' hr)'

             print,format='("INFO (",A,"): RA and DEC shifted from ")',functionName
             print,format='("     ",D15.10,",",D15.10)',d_RA,d_Dec
             print,format='("     ",D15.10,",",D15.10)',vd_Coords(0),vd_Coords(1)

         end

         info, 'INFO (' + functionName + '): Working on cube ' + strg(i) + ' now.'

         ; new ith cubes with larger size to store the shifted ith cubes
         cf_Frames       = fltarr( n_Dims(1), nn1, nn2 )
         cf_IntFrames    = fltarr( n_Dims(1), nn1, nn2 )
         cb_IntAuxFrames = bytarr( n_Dims(1), nn1, nn2 )

         if ( b_Debug eq 1 ) then begin
            mi_CenterPos  = fltarr ( 2, n_Dims(1) )   ; the centroid positions
            mi_CenterPosS = fltarr ( 2, n_Dims(1) )   ; the centroid positions
            m_I = reform(median((*pcf_Frame)(*,*,*),dimension=1))
            dummy = max(total(m_I,2),i_x)
            dummy = max(total(m_I,1),i_y)
            info, 'INFO (' + functionName + '): Found center of intensity around ' + strg(i_x) + ',' + strg(i_y)
         end

         ; loop over the slices of dataset i
         for j=0, n_Dims(1)-1 do begin

            if ( ( j mod (n_Dims(1)/10) ) eq 0 ) then $
               info, 'INFO (' + functionName + '): ' + strg(fix(100.*float(j)/float(n_Dims(1)))) + $
                     '% of set ' + strg(i) + ' shifted.' 

            ; extract slices for shifting
            mf_D = reform((*pcf_Frame)(j,*,*))
            mf_N = reform((*pcf_IntFrame)(j,*,*))
            mb_Q = reform((*pcb_IntAuxFrame)(j,*,*))

            if ( b_Debug eq 1 ) then  begin
               mf_I = reform(total((*pcf_Frame)((j-i_Delta)>0:(j+i_Delta)<(n_Dims(1)-1),*,*),1))
               xcen=0. & ycen=0.
               CNTRD, mf_I, i_x, i_y, xcen, ycen, 2.
               mi_CenterPos(*,j) = [xcen,ycen]
;              CNTRD works much much faster
;               mf_W = float(reform(total(extbit((*pcb_IntAuxFrame)((j-i_Delta)>0:(j+i_Delta)<(n_Dims(1)-1),*,*),0),1)) gt 0 )
;               dummy = mpfit2dpeak ( mf_I, vf_FitRes, WEIGHTS=mf_W )
;               mi_CenterPos(*,j) = [vf_FitRes(4),vf_FitRes(5)]

            end

            dummy = where ( extbit ( mb_Q, 0 ) eq 0 and extbit ( mb_Q, 3 ) eq 1, n_Bad )
            if ( n_Bad gt 0 ) then $
               warning, ' WARNING (' + functionName + '): ' + strg(n_Bad) + ' detected in slice ' + $
                        strg(i) + '. You should better interpolate first.' 

; Fractional pixel shifts
            s_Res = shift_image ( mf_D, mf_N, mb_Q, vd_x(j), vd_y(j) )

            if ( bool_is_struct ( s_Res ) ) then begin
               ; shift was successful
               mf_D = s_Res.mf_D  &  mf_N = s_Res.mf_N  &  mb_Q = s_Res.mb_Q
            endif else $
               info, 'INFO (' + functionName + '): Shifting of slice ' + strg(j) + $
                     ' in set ' + strg(i) + ' failed.'

            ; fill the temporary cubes with the shifted (or original) slices
            cf_Frames( j, vi_xi(j) : vi_xi(j) + n_Dims(2)-1, vi_yi(j) : vi_yi(j) + n_Dims(3)-1 )       = mf_D
            cf_IntFrames( j, vi_xi(j) : vi_xi(j) + n_Dims(2)-1, vi_yi(j) : vi_yi(j) + n_Dims(3)-1 )    = mf_N
            cb_IntAuxFrames( j, vi_xi(j) : vi_xi(j) + n_Dims(2)-1, vi_yi(j) : vi_yi(j) + n_Dims(3)-1 ) = mb_Q

         end ; loop over the slices of set i

         ;Return the Quality Bits to integers of 0(bad) and 9(good) - saw(July 2009)
	    bad = where(cb_IntAuxFrames ne 9)
	    if ( bad[0] ne -1 ) then begin
                  cb_IntAuxFrames[bad] = 0
            endif

	  ; replace the ith dataset with the enlarged and shifted ith dataset
         *pcb_IntAuxFrame = reform(cb_IntAuxFrames)
         *pcf_IntFrame    = reform(cf_IntFrames)
         *pcf_Frame       = reform(cf_Frames)

         if ( b_Debug eq 1 ) then  begin

            m_I = reform(median((*pcf_Frame)(*,*,*),dimension=1))
            dummy = max(total(m_I,2),i_x)
            dummy = max(total(m_I,1),i_y)

            ; loop over the slices of dataset i
            for j=0, n_Dims(1)-1 do begin
               xcen=0.  &  ycen=0.
               mf_I = reform(total((*pcf_Frame)((j-i_Delta)>0:(j+i_Delta)<(n_Dims(1)-1),*,*),1))
               CNTRD, mf_I, i_x, i_y, xcen, ycen, 2.
               mi_CenterPosS(*,j) = [xcen,ycen]
            end

            ;set_plot,'ps'
            ;device,file='K_50mas.ps',/color,/landscape

            !p.multi=[0,2,2]
            mask = where ( mi_CenterPos[0,*] gt 0., nmask )
            if ( nmask gt 0 ) then begin
               minp = min( [reform(mi_CenterPos[0,mask]), reform(mi_CenterPosS[0,mask])])
               maxp = max( [reform(mi_CenterPos[0,mask]), reform(mi_CenterPosS[0,mask])])
               ;plot, reform(mi_CenterPos[0,mask]),charsize=1,title='X Pos (black/before, green/after)',$
                ;     /yst,/xst,yrange=[minp,maxp],xtitle='Channel',ytitle='X Pos [px]'
               ;oplot, reform(mi_CenterPosS[0,mask]), color=2
            end

            mask = where ( mi_CenterPos[1,*] gt 0., nmask )
            if ( nmask gt 0 ) then begin
               minp = min( [reform(mi_CenterPos[1,mask]), reform(mi_CenterPosS[1,mask])])
               maxp = max( [reform(mi_CenterPos[1,mask]), reform(mi_CenterPosS[1,mask])])
               ;plot, reform(mi_CenterPos[1,mask]),charsize=1,title='Y Pos (black/before, green/after)',$
                     ;/yst,/xst,yrange=[minp,maxp],xtitle='Channel',ytitle='Y Pos [px]'
               ;oplot, reform(mi_CenterPosS[1,mask]), color=2
            end

            ;plot, vd_xshift, /yst, /xst, title='X Shift (total:white, integer:red, fractional:green)', $
                 ; xtitle='Channel', ytitle='Shift [px]', yrange=[min([vi_x,vd_x,vd_xshift]), max([vi_x,vd_x,vd_xshift])]
            ;oplot, vi_x,color=255,  linestyle=2
            ;oplot, vd_x,color=255*256, linestyle=2
            ;oplot, vd_x+vi_x,color=255*256+255, linestyle=1

           ; plot, vd_yshift, /yst, /xst, title='Y Shift (check:blue(=red+green))', $
           ;       xtitle='Channel', ytitle='Shift [px]', yrange=[min([vi_y,vd_y,vd_yshift]), max([vi_y,vd_y,vd_yshift])]
           ; oplot, vi_y, color=255, linestyle=2
           ; oplot, vd_y,color=255*256, linestyle=2
           ; oplot, vd_y+vi_y,color=255*256+255, linestyle=2


           ; !p.multi=[0,1,0]

            ;device,/close
            ;set_plot,'x'

          end

          if ( Modules[thisModuleIndex].SaveOnErr eq 1 ) then begin

             ; Now, save the shifts
             c_File = make_filename ( DataSet.Headers[i], Modules[thisModuleIndex].OutputDir, '__ctlt' )
             if ( NOT bool_is_string(c_File) ) then $
                return, error('FAILURE (' + functionName + '): Output filename creation failed.')
         
             writefits, c_File, transpose([[vd_xshift],[vd_yshift]])

          endif

          if ( Modules[thisModuleIndex].Save eq 1 ) then begin

            ; Now, save the data
             c_File = make_filename ( DataSet.Headers[i], Modules[thisModuleIndex].OutputDir, '_cctlt' )
             if ( NOT bool_is_string(c_File) ) then $
                return, error('FAILURE (' + functionName + '): Output filename creation failed.')
         
             writefits, c_File, *DataSet.Frames(i), *DataSet.Headers(i)
             writefits, c_File, *DataSet.IntFrames(i), /append
             writefits, c_File, *DataSet.IntAuxFrames(i), /append

          endif

       endif else $
          warning, ' WARNING (' + functionName + '): Not a cube in set ' + strg(i) + '.' 

    end

    report_success, functionName, T

    return, OK

END
