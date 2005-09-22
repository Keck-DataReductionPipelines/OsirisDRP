
; Helper function for mpcurvefit

function disp_func, x,p
    return, transpose([[p(0) + p(1) * x^(p(2))],[p(3) + p(4) * x^(p(2))]])
end

pro dispersion_func, x,p,f,pder
    f = disp_func(x,p)
end




;-------------------------------------------------------------------------
; NAME:  fit_dispersion
;
; PURPOSE: determines the atmospheric dispersion in a data cube
;
; INPUT : pcf_Frame       : pointer to input data cube
;         pcf_IntFrame    : pointer to input intframe cube
;         pcb_IntAuxFrame : pointer to input intauxframe cube
;         c_Func          : Function to be used when determining the
;                           PSF centroid ('GAUSS', 'LORENTZ',
;                           'MOFFAT')
;         FIXPOW=FIXPOW   : Sometimes the fitting routine fails due to
;                           the high sensitivity of chi2 according to
;                           the power of the fitfunction. FIXPOW fixes
;                           the power law index to be used.
;         [/DEBUG]        : initializes the debugging mode
;         [/SINFONI]      : if set, the input cubes are assumed to
;                           be SINFONI compliant, that means the
;                           wavelength axis is the last axis. 
;
; OUTPUT : returns a matrix with dimensions [2,n] with n being the
;          number of spectral channels of the input cubes with the
;          offsets determined. [0,*] are the x-offsets and [1,*] are
;          the y-offsets. Each slice of a cube has to be shifted
;          with these offsets to eliminate the atmospheric dispersion effects.
;
; ON ERROR : returns ERR_UNKNOWN from APP_CONSTANTS
;
; NOTES: - This routine treats only one input cube. You need to
;          call it several times if you want to process more than 1
;          input cube.
;        - The center of the star must be within the FoV.
;        - The cube must be EURO3D compliant.
;
; ALGORITHM: This routine determines a stars PSF in each spectral
;            slice by fitting a gaussian, loretzian or moffatian. The
;            PSF center coordinates are than fitted by a function 
;            f[x,y]=[cx0+cx*l^n,cy0+cy*l^n] with n (float) ranging from 1 to
;            5. This fit is not done iteratively but the fit weight is
;            proportional to the maximum valid pixel value of the
;            slice divided by the maximum value of collapsed averaged cube.
;            All slices are used for determining a PSF that :
;            - contain more than 10 pixel
;            - and the maximum intensity of the valid pixels in a
;              slice must be at least 5 % of the maximum intensity of
;              the collapsed averaged cube
;            - Then the PSF center is fitted and rejected if the
;              center is not within the slice (therefore slices 
;              that only contain the seeing wing are rejected)
;
;-------------------------------------------------------------------------

function fit_dispersion, pcf_Frame, pcf_IntFrame, pcb_IntAuxFrame, c_Func, i_Step, FIXPOW=FIXPOW, $
                         DEBUG=DEBUG

   COMMON APP_CONSTANTS

   pi = 3.1415926535897932384626433832795D

   if ( bool_pointer_integrity( pcf_Frame, pcf_IntFrame, pcb_IntAuxFrame, 1, 'fit_dispersion.pro', $
           /CUBE ) ne OK ) then $
      return, error ('ERROR IN CALL (fit_dispersion.pro): Integrity check failed.')

   if ( NOT ( c_Func eq 'GAUSS' or c_Func eq 'LORENTZ' or c_Func eq 'MOFFAT' ) ) then $
      return, error ( ['ERROR IN CALL (fit_dispersion.pro):', $
                       '               Unknown function keyword ('+c_Func+')'] )

   ; save the starting time
   if ( keyword_set ( DEBUG ) ) then T = systime(1)

   n_Dims = size( *pcf_Frame )
   
   ; collapse the cube to get a glimpse of the PSF
   s_Image = img_cube2image ( pcf_Frame, pcf_IntFrame, pcb_IntAuxFrame, 1 , 'AVRG', $
                              DEBUG = keyword_set(DEBUG) ) 
   if ( NOT bool_is_struct (s_Image) ) then $
      return, error ( 'FAILURE (fit_dispersion.pro): Unable to collapse cube' )

   ; fit a PSF to the collapsed image to get an initial estimate of the PSF
   dummy = mpfit2dpeak ( s_Image.md_Image, v_FitIni, WEIGHTS=s_Image.md_Weight, /TILT, $
                         QUIET=(NOT keyword_set(DEBUG)), $
                         GAUSS=c_Func eq 'GAUSS', $
                         LORENTZIAN=c_Func eq 'LORENTZ', $
                         MOFFAT=c_Func eq 'MOFFAT' )

   d_ImageMax = max(s_Image.md_Image)

   ; first is weight (maximum value of slice divided by maximum value of
   ; collapsed averaged image), second is x, third is y center of the PSF in slice 
   m_Center = dindgen(3,n_Dims(1))*0.
   i_Valid  = indgen(n_Dims(1))*0.

   ; now step through the slices
   for i=0, n_Dims(1)-1, i_Step do begin

      if ( keyword_set ( DEBUG ) ) then if ( (i mod (n_Dims(1)/20)) eq 0 ) then $
         debug_info,'DEBUG INFO (fit_dispersion.pro): '+strg(fix(float(i)*100./n_Dims(1)))+'% done.'

      md_Frame       = reform((*pcf_Frame)(i,*,*))
      md_IntFrame    = reform((*pcf_IntFrame)(i,*,*))
      md_IntAuxFrame = reform((*pcb_IntAuxFrame)(i,*,*))

      ; masks where the slice is valid
      v_Mask = where( valid ( md_Frame, md_IntFrame, md_IntAuxFrame ), n_Total )

      if ( n_Total gt 900 ) then begin
         ; at least 10 pixel for fitting are required
         d_Weight = max((md_Frame)(v_Mask))/d_ImageMax

         if ( d_Weight gt 0.05 ) then begin

            ; only do the fit if the maximum intensity in a slice is at least 5%
            ; of the maximum of the averaged collapsed image 

            ; calculate the fit weights
            md_Weight         = dindgen(n_Dims(2),n_Dims(3)) * 0.
            md_Weight(v_Mask) = 1./double(md_IntFrame(v_Mask))^2

            ; calculate the PSF center coordinates
            dummy = mpfit2dpeak ( md_Frame, v_FitRes, WEIGHTS=md_Weight, $
                                  QUIET=(NOT keyword_set(DEBUG)), $
                                  GAUSS=c_Func eq 'GAUSS', $
                                  LORENTZIAN=c_Func eq 'LORENTZ', $
                                  MOFFAT=c_Func eq 'MOFFAT' )

            ; ensure that the PSF center is within the slice
            if ( v_FitRes(4) ge 0 and v_FitRes(4) le n_Dims(2)-1 and $
                 v_FitRes(5) ge 0 and v_FitRes(5) le n_Dims(3)-1       ) then begin
               ; calculated PSF center is within the slice
               i_Valid(i)    = 1
               m_Center(0,i) = d_Weight 
               m_Center(1,i) = v_FitRes(4)
               m_Center(2,i) = v_FitRes(5)
            endif else if ( keyword_set ( DEBUG ) ) then $
                   debug_info,'DEBUG INFO (fit_dispersion.pro): Slice '+strg(i)+' PSF center is not within slice.'
         endif else if ( keyword_set ( DEBUG ) ) then $
                   debug_info,'DEBUG INFO (fit_dispersion.pro): Slice '+strg(i)+' max is less than 5% of max of averaged, collapsed image.'
     endif else if ( keyword_set ( DEBUG ) ) then $
                   debug_info,'DEBUG INFO (fit_dispersion.pro): Slice '+strg(i)+' has less than 900 valid pixel.'

   end


   ; now fit the centroids
   if ( keyword_set ( DEBUG ) ) then $
      debug_info,'DEBUG INFO (fit_dispersion.pro): Fitting the centroids now.'

   ; define fit constraints
   parinfo = replicate({value:0.D, fixed:0, limited:[0,0], $
                        limits:[0.D,0.D] }, 5)
   ; index  parameter
   ;   0    offset in x
   ;   1    scale in x
   ;   2    power in dispersion direction (float between 2 and 5)
   ;   3    offset in y
   ;   4    scale in y

   ; initialize starting values
   parinfo(0).value = v_FitIni(4)
   parinfo(1).value = 0.
   if ( keyword_set ( FIXPOW ) ) then parinfo(2).value = FIXPOW else parinfo(2).value = 4.
   parinfo(3).value = v_FitIni(5)
   parinfo(4).value = 0.
   ; limit the power law index
   if ( keyword_set ( FIXPOW ) ) then begin
      parinfo(2).fixed = 1
   endif else begin
      parinfo(2).limits(0) = 1.
      parinfo(2).limits(1) = 5.
      parinfo(2).limited(0) = 1
      parinfo(2).limited(1) = 1
   end

   ; now fit a smooth function to the data
   vi_Mask = where ( i_Valid eq 1, n_Valid )

   if ( n_Valid gt 10 ) then begin
      yfit = mpcurvefit( (dindgen(n_Dims(1)))(vi_Mask), m_Center(1:2,vi_Mask), $
                         [m_Center(0,vi_Mask),m_Center(0,vi_Mask)], v_FitPar, $
                         FUNCTION_NAME='dispersion_func', /quiet, $
                         FTOL=1.e-20, itmax=2000, /NODERIVATIVE, PARINFO=parinfo )

      if ( keyword_set ( DEBUG ) ) then debug_info, $
         ['DEBUG INFO (fit_dispersion.pro): Found                 ', $
          '                                cx = '+strtrim(string(v_FitPar(0))),$
          '                                cy = '+strtrim(string(v_FitPar(3))),$
          '                                sx = '+strtrim(string(v_FitPar(1))),$
          '                                sy = '+strtrim(string(v_FitPar(4))),$
          '                             power = '+strtrim(string(v_FitPar(2)))   ]

      ; extrapolate the fit result to all slices
      m_Offsets = disp_func( dindgen(n_Dims(1)), v_FitPar )
 
      if ( keyword_set ( DEBUG ) ) then begin
         !p.multi=[0,1,2]
         plot, dindgen(n_Dims(1)), reform(m_Center(1,*)), xtitle='LAMBDA [a.u.]', ytitle='X-Pixel', $
            yrange=[min(reform(m_Center(1,*))),max(reform(m_Center(1,*)))], ystyle=1
         oplot, dindgen(n_Dims(1)), reform(m_Offsets(0,*)), color=1
         plot, dindgen(n_Dims(1)), reform(m_Center(2,*)), xtitle='LAMBDA [a.u.]', ytitle='Y-Pixel', $
            yrange=[min(reform(m_Center(2,*))),max(reform(m_Center(2,*)))], ystyle=1
         oplot, dindgen(n_Dims(1)), reform(m_Offsets(1,*)), color=1
         !p.multi=[0,1,0]     
         v_Mask = where ( m_Center(0,*) gt 0. )
         d_AvChi = mean(sqrt(((m_Offsets(0,*)-m_Center(1,*))^2)(v_Mask)+((m_Offsets(1,*)-m_Center(2,*))^2)(v_Mask)))
         debug_info,'DEBUG INFO (fit_dispersion.pro): Average Chi = '+ strtrim(string(d_AvChi),2)+' Pixel'
      end

      ; calculate the offsets for corrdisper_000.pro
      m_Offsets(0,*) = m_Offsets(0,0) - m_Offsets(0,*) 
      m_Offsets(1,*) = m_Offsets(1,0) - m_Offsets(1,*) 

   endif else begin

      return, error ('FAILURE (' + functionName + '): Failed to determine dispersion.')

   end


   if ( keyword_set(DEBUG) ) then begin
      TT=systime(1)-T
      debug_info,'DEBUG INFO (fit_dispersion.pro): ran for '+strtrim(string(TT),2)+' seconds'
   end 

   ; return the extrapolated offsets
   return, { m_Offsets : m_Offsets, $
             m_Center  : m_Center }

end
