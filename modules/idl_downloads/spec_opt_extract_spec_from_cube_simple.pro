;-----------------------------------------------------------------------
; NAME:  spec_opt_extract_spec_from_single_cube
;
; PURPOSE: Extract a stellar spectrum from a cube or a set of cubes. 
;          The FoV must contain only 1 star.
;
; INPUT :  p_Cubes        : Pointer to a data cube
;          p_IntFrames    : Pointer to an IntFrame cube.
;          p_IntAuxFrames : Pointer to an IntAuxFrame cube.
;
;    Parameters that determine the collapsing of the cube :
;
;          d_Spec_Channels: range of the dispersion axis used to
;                           collapse the image in percent
;                           (0<d_SPEC_CHANNELS<1).
;          k_ImgMode      : 'MED' : pixel in image is the median value
;                                   of the spectrum
;                           'AVRG': pixel in image is the mean value
;                                   of the spectrum     
;                           'SUM' : pixel in image is the sum
;                                   of the spectrum 
;
;    Parameters that determine the background subtraction
;
;         BGAPTMULT={Mode,r} : Initializes the background subtraction.
;                              BGAPTMULT is a 2-element structure.
;                              Mode determines the PSF fitting
;                              function and must be equal to 'GAUSS',
;                              'LORENTZ' or
;                              'MOFFAT'. r is the aperture mask radius
;                              in sigma when fitting a gaussian or
;                              lorentzian or HWHM when fitting a
;                              moffat. The structures tagnames are
;                              ignored but Mode must be the first tag
;                              and r the second. 
;                or            
;         BGAPTPIX=[cx,cy,r] : Initializes the background subtraction.
;                              BGAPTPIX is a 3-element vector.
;                              The star is masked with a circular mask
;                              centered on cx, cy with a radius of r
;
;         [BGMEDIAN=BGMEDIAN]: if set, the background in each slice is the median
;                              value of all valid skypixels of a slice.
;                              
;
;    Parameters that determine the extraction method
;
;       optimal extraction
;
;          optimal extraction aperture masks are not subpixel based
;
;          OPTAPTMULT={Mode,r}: Initializes the optimal extraction
;          OPTQ=OPTQ            OPTAPTMULT is a 2-element structure.
;                               Mode determines the PSF fitting
;                               function and must be equal to 'GAUSS', 
;                               'LORENTZ' or
;                               'MOFFAT'. r is the aperture mask radius
;                               in sigma when fitting a gaussian or
;                               lorentzian or HWHM when fitting a
;                               moffat. The structures tagnames are
;                               ignored but Mode must be the first tag
;                               and r the second. 
;                               OPTQ is the conversion factor in electrons/ADU.
;                or            
;          OPTAPTPIX=[cx,cy,r]: Initializes the optimal extraction
;          OPTQ=OPTQ            OPTAPTPIX is a 3-element vector.
;          OPTPSF=OPTPSF        The PSF is masked with a circular mask
;                               centered on cx, cy with a radius of r.
;                               OPTQ is the conversion factor in electrons/ADU.
;                               OPTPSF is an external PSF used by the
;                               extraction routine. This PSF needs not
;                               to be normalized. Negative values in
;                               the PSF are set to 0. The optional PSF
;                               must be centered on the maximum of the
;                               collapsed image, that means on the
;                               offset where the crosscorrelation is
;                               max. The optional PSF must be
;                               background subtracted. 
;               or              
;          OPTSELF=r          : if set, then the collapsed image is
;          OPTQ=OPTQ            used as PSF. r is the extraction
;                               radius in sky-pixel. You should use an
;                               background subtraction method when
;                               using OPTSELF.
;
;          [OPTCLIP = OPTCLIP]: a sigma factor, pixels that do not fullfill 
;                               (pixel value - flux within r * PSF)^2
;                                              < OPTCLIP * pixel variance
;                               are not used for extraction.
;          [\OPTFULL]         : if set, then all pixels of a slice
;                               within r must be valid to extract a spectrum.
;
;                               If APTMULT or APTPIX are set together
;                               with OPTQ, OPTPSF, OPTCLIP or OPTFULL they are
;                               ignored. If OPTAPTMULT is set together
;                               with OPTPSF, OPTPSF is ignored
;
;       hard aperture summation
;
;          hard aperture masks are subpixel based
;
;          APTMULT={Mode,r}   : Initializes the hard aperture extraction.
;                               APTMULT is a 2-element structure.
;                               Mode determines the PSF fitting
;                               function and must be equal to 'GAUSS', 'LORENTZ' or
;                               'MOFFAT'. r is the aperture mask radius
;                               in sigma when fitting a gaussian or
;                               lorentzian or HWHM when fitting a
;                               moffat. The structures tagnames are
;                               ignored but Mode must be the first tag
;                               and r the second. 
;                or
;          APTPIX=[cx,cy,r]   : Initializes the hard aperture extraction.
;                               APTPIX is a 3-element vector.
;                               All valid pixels within r skypixel centered
;                               at cx,cy are summed up
;
;    Debugging parameters:
;
;           [ OUT_DIR = OUT_DIR ]    : Writes 
;                                      ...IMG1... : collapsed image
;                                                   used for PSF fit
;                                                   for BG subtraction
;                                      ...IMG2... : collapsed image
;                                                   used for PSF fit after BG
;                                                   subtraction
;                                      ...PSF1... : PSF fit before BG
;                                                   subtraction
;                                      ...PSF2... : PSF fit after BG
;                                                   subtraction 
;                                      ...BGM...  : Mask that
;                                                   determines whether a pixel is
;                                                   used for BG
;                                                   estimation or not
;                                      ...BGC...  : BG subtracted cube
;                                                   with SPIFFI
;                                                   fits-keywords to
;                                                   view with atvs.pro
;                                      ...APTMULT... : aperture mask
;                                                      in mode APTMULT
;                                      ...APTPIX...  : aperture mask
;                                                      in mode APTPIX
;
;                                      to disk in directory OUT_DIR
;
;                                      The filenames have the form:  
;                  DEBUG_spec_opt_extract_spec_from_single_cube_+VERSION+_IMG1_+FN+.fits
;                                      with VERSION the current
;                                      version and FN the current
;                                      system date.
;
;                                      Which files are written depends
;                                      on the chosen modes.
;
;           [ /DEBUG ] : initializes debugging which gives additional
;                        info to the user. If a BG subtraction method
;                        is chosen, the fitted or estimated BG
;                        parameters are plotted.
;
; OPTIONAL OUTPUT : None
;
; RETURN VALUE : returns a structure
;                  Spectrum       : contains the extracted spectrum
;                  IntSpectrum    : contains the quality spectrum (double)
;                                   comparable to the IntFrame (double)
;                  IntAuxSpectrum : contains the auxiliary spectrum
;                                   (byte)
;                  SpectrumSum    : using optimal extraction this
;                                   vector contains the simple sum of the
;                                   spectra within the extraction
;                                   aperture. Otherwise this variable
;                                   is not set. (double)
;
; On error : On error this function returns 0.
;
; Nomenclature : skypixel means a spatial pixel on the sky
;                spectral pixel means one dispersion element of a spectrum
;
; Algorithm :  1. Background subtraction
;
;                 - Collapse the cube (see also img_cube2image.pro).
;
;                 - Determination of a mask to mask out the star.
;
;                   If BGAPTMULT is set, the PSF of the star is
;                      determined by fitting a gaussian,
;                      lorentzian or moffat to the collapsed image. 
;                      The fit is done weighted. The mask is centered
;                      on the PSF center and has a radius of
;                      BGAPTMULT.(1)*max(X,Y) with X,Y being the gaussian
;                      sigma (if BGAPTMULT.(1) equal to 'GAUSS' or
;                      'LORENTZ') or the HWHM (if BGAPTMULT.(1) equal to
;                      'MOFFAT') of the fitted PSF. 
;                   If BGAPTPIX is set the mask is centered on
;                      BGAPTPIX.(0),BGAPTPIX.(1) and has a radius of
;                      BGAPTPIX.(2) sky-pixel
;
;                   A pixel is masked out if the center of a pixel is
;                   outside the radius around the center.
;
;                 - The background in each slice of the cube is fitted by
;                   a plane or by medianing ( if additionally BGMEDIAN
;                   is set ).
;                   All pixels of each slice are used for estimating
;                   the background that are not masked, have finite
;                   data values, an intframe value ne 0 and a valid
;                   intauxframe value. 
;                   The fit is done unweighted. If the fit fails, the data
;                   values and the intframe values of the slice are set
;                   to 0 and the intauxframe values of this slice are
;                   set to invalid. 
;
;              2. Extraction of the spectrum:
;                Either the extraction is done using a hard aperture
;                or applying Horne's scheme (a symplified method
;                without iteration)
;
;                - hard aperture: 
;                  calculation of a weight matrix giving a weight to
;                  each pixel. This aperture mask is defined
;                  on subpixel accuracy that means that the weight is
;                  proportional to the area of the pixel within
;                  the mask.
;                  If APTMULT is set, the cube is collapsed again and 
;                     the PSF of the star is recalculated
;                     using a gaussian, lorentzian or moffat. The
;                     aperture mask is centered
;                     on the PSF center and has a radius of
;                     APTMULT.(1)*max(X,Y) with X,Y being the gaussian
;                     sigma (if APTMULT.(0) equal to 'GAUSS' or
;                     'LORENTZ') or the HWHM (if APTMULT.(0) equal to
;                     'MOFFAT') of the fitted PSF. 
;                  If APTPIX is set the aperture mask is centered on
;                     APTPIX.(0),APTPIX.(1) and has a radius of
;                     APTPIX.(2) sky-pixel
;                  When using a hard aperture all pixel within the
;                  aperture must be valid, that means that the data
;                  values must be finite, the intframe value must be
;                  ne 0 and the intauxframe value must be valid.
;
;                - optimal extraction:
;                  The optimal extraction scheme used is the one of
;                  Horne, 1986 PASP 98:609. The applied scheme is
;                  without iteration, that means that the center of the
;                  PSF must not move within the fov and must not change
;                  its form along the dispersion axis. The spectrum is
;                  extracted from an aperture mask which is calculated
;                  in the following. The aperture masks when using
;                  optimal extraction are not subpixel based, that
;                  means that a pixel is used for extraction that is
;                  valid (see e.g. section hard aperture) and if the
;                  center of the pixel is within the radius around the
;                  PSF center. The weight is therefore either 1 or 0.
;                  When using OPTSELF the PSF center coordinates are integers.
;                  If OPTAPTMULT is set, the cube is collapsed again
;                     and the PSF of the star is recalculated
;                     using a gaussian, lorentzian or moffat. The
;                     aperture mask is centered
;                     on the PSF center and has a radius of
;                     OPTAPTMULT.(1)*max(X,Y) with X,Y being the gaussian
;                     sigma (if OPTAPTMULT.(0) equal to 'GAUSS' or
;                     'LORENTZ') or the HWHM (if OPTAPTMULT.(0) equal to
;                     'MOFFAT') of the fitted PSF. 
;                  If OPTAPTPIX is set the aperture mask is centered on
;                     OPTAPTPIX.(0),OPTAPTPIX.(1) and has a radius of
;                     OPTAPTPIX.(2) sky-pixel. In addition OPTPSF
;                     must be set containing a optional PSF which is
;                     used in the extraction process.
;                  If OPTSELF is set the aperture mask has a radius of
;                     r sky-pixel. With this option the collapsed
;                     image is used as PSF.
;                     When using OPTSELF you should use a background
;                     subtraction method as well. 
;
;                  When doing the optimal extraction additionally the conversion
;                  factor OPTQ (in electrons/ADU) must be given. 
;                  Optional parameters can be set like OPTCLIP and
;                  OPTFULL. If OPTFULL is not set than the photometric
;                  accuracy may decrease where only few pixels are
;                  valid for extraction but the advantage is
;                  a 'longer' spectrum. 
;                  When extracting optimally all aperture masks are
;                  pixel (not subpixel!!!) based.
;
;
; LOOP: spec_opt_extract_spec_from_cube is a loop over
;       spec_opt_extract_spec_from_single_cube in the case of input
;       pointer arrays. The individual extracted spectra are simply summed up
;       to get the final extracted spectrum. The individual intframe
;       values are squared and summed. If any of the individual
;       spectra have invalid values, the summed spectrum is invalid
;       there as well.
;
; STATUS : As supposed by Horne et al (1986), tests in photon noise
;    dominated regime and in the background limited regime have been
;    carried out. In the first case the optimally extracted spectrum
;    should have the same S/N as the simple sum of spectra within the
;    extraction aperture. This applies to this routine. In the second
;    case the optimally extracted spectrum should have a S/N higher by a
;    factor of sqrt(1.69) than the simple sum. Within the accuracy this
;    applies as well. Additional background subtraction and optional PSF
;    have been tested.
;
; NOTES: - Whenever fitting a PSF a tilt is applied, that means that the
;          main axes of the fitted PSF do not need to be parallel to the
;          x- and y-axis
;        - The extracted intauxframe spectrum has only the quality bit set.
;        - its required that only one star is in the fov.
;
; EXAMPLES:  The following program can be execute directly:
;
;   ; - Simulate a star with gaussian PSF centered at 25,25 and a
;   ;   gaussian sigma of 3.
;   ; - Add readout noise and photon noise
;   ; - Start the extraction using the optimal extraction method
;   ;   using the collapsed image as PSF and extracting from an
;   ;   aperture having a radius of 9 skypixel.
;   ;   Before, the background is subtracted by masking the star with
;   ;   an aperture of 6 * fitted gaussian sigma.
;   
;   q   = 1.  ; conversion factor
;   rn  = 20. ; readout noise
;   snf=0.    ; 0. means no photon noise, 1 means incl. photon noise
;   
;   p_data     = ptr_new(/ALLOCATE_HEAP)
;   p_intframe = ptr_new(/ALLOCATE_HEAP)
;   p_intauxframe = ptr_new(/ALLOCATE_HEAP)
;   
;   data = dindgen(50,50,2000)*0.
;   intframe = 1./(dindgen(50,50,2000)*0.+rn)^2
;   intauxframe = indgen(50,50,2000)*0+1
;   
;   ; calculate gaussian star
;   p = [25D, 25D, 3., 1.]
;   x = dindgen(50) # replicate(1.,50)
;   y = replicate(1.,50) # dindgen(50)
;   z = gauss2(x, y, p)
;   z = z / max(z)*10000.
;   
;   ; noise the star
;   for k=0, 1999 do begin
;      r1 = randomn(s,2500)
;      r2 = randomn(s,2500)
;      data(*,*,k)=z+snf*r1*sqrt(z)/q+r2*rn
;   end
;   
;   *p_data        = data
;   *p_intframe    = intframe
;   *p_intauxframe = intauxframe
;   
;   ; here we go
;   spec = spec_opt_extract_spec_from_cube_simple (p_data, p_intframe, p_intauxframe, 1, 2000, .9, 'AVRG', $
;             OPTSELF=9, OPTQ=q, $
;             BGAPTMULT={Mode:'GAUSS',S:6}, /DEBUG )
;   
;   print, 'Returning with '+string(error_status)
;   
;   ; the first (white) one is the simple sum, the second one is the
;   ; optimally extracted one
;   plot, spec.SpectrumSum, yrange=[5.5e5,5.8e5]
;   oplot, spec.Spectrum,color=1
;   
;   a=median(spec.SpectrumSum/stddev(spec.SpectrumSum)) ; S/N of the simple sum
;   b=median(spec.Spectrum/stddev(spec.Spectrum))       ; S/N of the optimal extracted spectrum 
;   
;   print, a,b
;   
;   end
;
; HISTORY : 3.3.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

; Kernel routines ----------------------------------

FUNCTION spec_opt_extract_spec_from_single_cube, pcf_Cube, pcf_IntFrame, pcb_IntAuxFrame, $
         d_Spec_Channels, k_ImgMode, $
         BGAPTMULT=BGAPTMULT, BGAPTPIX=BGAPTPIX, BGMEDIAN=BGMEDIAN, $
         OPTAPTPIX=OPTAPTPIX, OPTAPTMULT=OPTAPTMULT, OPTSELF=OPTSELF, OPTQ=OPTQ, OPTPSF=OPTPSF, $
            OPTCLIP=OPTCLIP, OPTFULL=OPTFULL, $
         APTPIX=APTPIX, APTMULT=APTMULT, $
         OUT_DIR=OUT_DIR, DEBUG = DEBUG

   ; specific constants
   VERSION = 'V1.2'
   pi = 3.1415926535897932384626433832795D
   filename = strjoin(strsplit(systime(/UTC),/Extract),'_')

   ; --- Check input parameters -------------------------------------------------------

   if ( bool_pointer_integrity( pcf_Cube, pcf_IntFrame, pcb_IntAuxFrame, 1, $
          'spec_opt_extract_spec_from_single_cube' ) ne OK ) then $
      return, error('ERROR IN CALL (spec_opt_extract_spec_from_single_cube): Integrity check failed.')

   if ( d_Spec_Channels le 0. or d_Spec_Channels gt 1. ) then $
      return, error ( 'ERROR IN CALL (spec_opt_extract_spec_from_single_cube.pro):', $
                      '               Not 0<Spec_Channels<=1' )

   if ( NOT ( k_ImgMode eq 'MED' or k_ImgMode eq 'AVRG' or k_ImgMode eq 'SUM' ) ) then $
      return, error ( ['ERROR IN CALL (spec_opt_extract_spec_from_single_cube.pro):', $
                       '               Unknown Mode '+strtrim(string(k_ImgMode),2)] )

   if ( keyword_set ( BGAPTMULT ) and keyword_set ( BGAPTPIX ) ) then $
      return, error ( ['ERROR IN CALL (spec_opt_extract_spec_from_single_cube.pro):',$
                       '               Only BGAPTMULT or BGAPTPIX allowed'] )

   if ( keyword_set ( BGAPTMULT ) ) then begin
      if ( NOT bool_is_struct(BGAPTMULT,n=2 ) )then $
         return, error ( ['ERROR IN CALL (spec_opt_extract_spec_from_single_cube.pro):',$
                          '               Wrong number of arguments in BGAPTMULT or BGAPTMULT is not a structure '] )
      if ( BGAPTMULT.(0) ne 'GAUSS' and BGAPTMULT.(0) ne 'LORENTZ' and BGAPTMULT.(0) ne 'MOFFAT' ) then $
         return, error ( ['ERROR IN CALL (spec_opt_extract_spec_from_single_cube.pro):',$
                          '               Unknown mode in BGAPTMULT'] )
      if ( BGAPTMULT.(1) lt 0 ) then $
         return, error ( ['ERROR IN CALL (spec_opt_extract_spec_from_single_cube.pro):',$
                          '               In BGAPTMULT sigma/HWHM is negative'] )
   end

   if ( keyword_set ( BGAPTPIX ) ) then begin
      if ( bool_is_struct(BGAPTPIX) ) then $
         return, error ( ['ERROR IN CALL (spec_opt_extract_spec_from_single_cube.pro):',$
                          '               BGAPTPIX must be a 3-element vector, not a structure'] )
      if ( (size(BGAPTPIX))(0) ne 3 ) then $
         return, error ( ['ERROR IN CALL (spec_opt_extract_spec_from_single_cube.pro):',$
                          '               Wrong number of arguments in BGAPTPIX'] )
      if ( BGAPTPIX(0) lt 0 or BGAPTPIX(1) lt 0 or BGAPTPIX(2) lt 0 ) then $
         return, error ( ['ERROR IN CALL (spec_opt_extract_spec_from_single_cube.pro):',$
                          '               No negative numbers in BGAPTPIX'] )
   end

   n_Mode = total( [ keyword_set(OPTAPTPIX),keyword_set(OPTAPTMULT),keyword_set(OPTSELF), $
                     keyword_set(APTPIX),keyword_set(APTMULT) ] )
   if ( n_Mode ne 1 ) then $
      return, error ( ['ERROR IN CALL (spec_opt_extract_spec_from_single_cube.pro):',$
                       '               What shall i do?'] )

   if ( keyword_set(OPTAPTPIX) and NOT ( keyword_set(OPTQ) or keyword_set(OPTPSF) ) ) then $
      return, error ( ['ERROR IN CALL (spec_opt_extract_spec_from_single_cube.pro):',$
                       '               OPTAPTPIX together with OPTQ and OPTPSF'] )

   if ( keyword_set(OPTAPTMULT) and NOT keyword_set(OPTQ) ) then $
      return, error ( ['ERROR IN CALL (spec_opt_extract_spec_from_single_cube.pro):',$
                       '               OPTAPTMULT together with OPTQ'] )

   if ( keyword_set(OPTSELF) and NOT keyword_set(OPTQ) ) then $
      return, error ( ['ERROR IN CALL (spec_opt_extract_spec_from_single_cube.pro):',$
                       '               OPTSELF together with OPTQ'] )

   if ( keyword_set ( OPTAPTMULT ) ) then begin
      if ( NOT bool_is_struct(OPTAPTMULT,n=2) ) then $
         return, error ( ['ERROR IN CALL (spec_opt_extract_spec_from_single_cube.pro):',$
                          '               Wrong number of arguments in OPTAPTMULT or OPTAPTMULT is not a structure'] )
      if ( OPTAPTMULT.(0) ne 'GAUSS' and OPTAPTMULT.(0) ne 'LORENTZ' and OPTAPTMULT.(0) ne 'MOFFAT' ) then $
         return, error ( ['ERROR IN CALL (spec_opt_extract_spec_from_single_cube.pro):',$
                          '               Unknown mode in OPTAPTMULT'] )
      if ( OPTAPTMULT.(1) lt 0 ) then $
         return, error ( ['ERROR IN CALL (spec_opt_extract_spec_from_single_cube.pro):',$
                          '               In OPTAPTMULT sigma/HWHM is negative'] )
   end

   if ( keyword_set ( OPTAPTPIX ) ) then begin
      if ( bool_is_struct(OPTAPTPIX) ) then $
         return, error ( ['ERROR IN CALL (spec_opt_extract_spec_from_single_cube.pro):',$
                          '               OPTAPTPIX must be a 3-element vector, not a structure'] )
      if ( n_elements(OPTAPTPIX) ne 3 ) then $
         return, error ( ['ERROR IN CALL (spec_opt_extract_spec_from_single_cube.pro):',$
                          '               Wrong number of arguments in OPTAPTPIX'] )
      if ( OPTAPTPIX(0) lt 0 or OPTAPTPIX(1) lt 0 or OPTAPTPIX(2) lt 0 ) then $
         return, error ( ['ERROR IN CALL (spec_opt_extract_spec_from_single_cube.pro):',$
                          '               No negative numbers in OPTAPTPIX'] )
   end

   if ( keyword_set ( OPTSELF ) ) then $
      if ( OPTSELF lt 0. ) then $
         return, error ( ['ERROR IN CALL (spec_opt_extract_spec_from_single_cube.pro):',$
                          '               OPTSELF must be gt 0'] )

   if ( keyword_set ( APTMULT ) ) then begin
      if ( NOT bool_is_struct(APTMULT,n=2) ) then $
         return, error ( ['ERROR IN CALL (spec_opt_extract_spec_from_single_cube.pro):',$
                          '               Wrong number of arguments in APTMULT'] )
      if ( APTMULT.(0) ne 'GAUSS' and APTMULT.(0) ne 'LORENTZ' and APTMULT.(0) ne 'MOFFAT' ) then $
         return, error ( ['ERROR IN CALL (spec_opt_extract_spec_from_single_cube.pro):',$
                          '               Unknown mode in APTMULT'] )
      if ( APTMULT.(1) lt 0 ) then $
         return, error ( ['ERROR IN CALL (spec_opt_extract_spec_from_single_cube.pro):',$
                          '               In APTMULT sigma/HWHM is negative'] )
   end

   if ( keyword_set ( APTPIX ) ) then begin
      if ( bool_is_struct(APTPIX) ) then $
         return, error ( ['ERROR IN CALL (spec_opt_extract_spec_from_single_cube.pro):',$
                          '               APTPIX must be a 3-element vector, not a structure'] )
      if ( n_elements(APTPIX) ne 3 ) then $
         return, error ( ['ERROR IN CALL (spec_opt_extract_spec_from_single_cube.pro):',$
                          '               Wrong number of arguments in APTPIX'] )
      if ( APTPIX(0) lt 0 or APTPIX(1) lt 0 or APTPIX(2) lt 0 ) then $
         return, error ( ['ERROR IN CALL (spec_opt_extract_spec_from_single_cube.pro):',$
                          '               No negative numbers in APTPIX'] )
   end

   DimCube = size( *pcf_Cube )
   DimPSF  = size( OPTPSF )

   if ( keyword_set(OPTPSF) ) then $
      if ( DimCube(1) ne DimPSF(1) or DimCube(2) ne DimPSF(2) ) then $ 
      return, error ( ['ERROR IN CALL (spec_opt_extract_spec_from_single_cube.pro):',$
                       '               OPTPSF does not match cube'] )

   ; ok, all parameters understood and parameter integrity is ok

   ; --- Here it goes -----------------------------------------------------------------

   ; do we need an initial estimate of the PSF for subtracting the BG?
   if ( keyword_set(BGAPTMULT) ) then begin

      ; Collapse cube. img_cube2image returns a struct on success with
      ; md_Weight being the 1/Noise^2 values
      s_Image = img_cube2image ( pcf_Cube, pcf_IntFrame, pcb_IntAuxFrame, d_Spec_Channels, k_ImgMode, $
                                 DEBUG = keyword_set(DEBUG) ) 
      if ( NOT bool_is_struct ( s_Image ) ) then $
         return, error ( 'FAILURE (spec_opt_extract_spec_from_single_cube.pro): Cube collapsing failed.' )

      mf_Image  = s_Image.md_Image 
      md_Weight = s_Image.md_Weight

      ; Log collapsed image?
      if ( keyword_set ( OUT_DIR ) ) then writefits, OUT_DIR+$
                   'DEBUG_spec_opt_extract_spec_from_single_cube_'+VERSION+'_IMG1_'+filename+'.fits',mf_Image

      mf_PSF = mpfit2dpeak ( mf_Image, v_FitBGRes, WEIGHTS=md_Weight, /TILT, QUIET=(NOT keyword_set(DEBUG)), $
                             GAUSS=BGAPTMULT.(0) eq 'GAUSS', $
                             LORENTZIAN=BGAPTMULT.(0) eq 'LORENTZ', $
                             MOFFAT=BGAPTMULT.(0) eq 'MOFFAT' )

      if ( keyword_set ( DEBUG ) ) then begin
         d_ChiS = sqrt(total( (mf_PSF - mf_Image)^2 ))
         debug_info, 'DEBUG INFO (spec_opt_extract_spec_from_single_cube.pro): PSF parameters before BG subtraction: '
         debug_info, 'DEBUG INFO (spec_opt_extract_spec_from_single_cube.pro): offset: '+string(v_FitBGRes(0))
         debug_info, 'DEBUG INFO (spec_opt_extract_spec_from_single_cube.pro): scale : '+string(v_FitBGRes(1))
         debug_info, 'DEBUG INFO (spec_opt_extract_spec_from_single_cube.pro): fwhmx : '+string(v_FitBGRes(2))
         debug_info, 'DEBUG INFO (spec_opt_extract_spec_from_single_cube.pro): fwhmy : '+string(v_FitBGRes(3))
         debug_info, 'DEBUG INFO (spec_opt_extract_spec_from_single_cube.pro): cx    : '+string(v_FitBGRes(4))
         debug_info, 'DEBUG INFO (spec_opt_extract_spec_from_single_cube.pro): cy    : '+string(v_FitBGRes(5))
         if ( n_elements(v_FitBGRes) eq 7 ) then $
         debug_info, 'DEBUG INFO (spec_opt_extract_spec_from_single_cube.pro): tilt  : '+string(v_FitBGRes(6))
         if ( n_elements(v_FitBGRes) eq 8 ) then $
         debug_info, 'DEBUG INFO (spec_opt_extract_spec_from_single_cube.pro): damp  : '+string(v_FitBGRes(7))
         debug_info, 'DEBUG INFO (spec_opt_extract_spec_from_single_cube.pro): ChiSquare of fitted function is '+ $
                     strtrim(string(d_ChiS),2)
      end
   
      if ( keyword_set ( OUT_DIR ) ) then $
         writefits,OUT_DIR+'DEBUG_spec_opt_extract_spec_from_single_cube_'+VERSION+'_PSF1_'+filename+$
                   '.fits',mf_PSF

      if ( v_FitBGRes(0) lt 0. ) then $
         warning, ['WARNING (spec_opt_extract_spec_from_cube_simple.pro): ', $
                   '        The offset of the fitted PSF before background subtraction is negativ ('+strtrim(string(v_FitBGRes(0)),2)+')', $
                   '        Continuing']

   endif 

   ; do we want to subtract the background?
   if ( keyword_set(BGAPTPIX) or keyword_set(BGAPTMULT) or keyword_set(BGMEDIAN) ) then begin

      ; This is the mask with which the star is masked out. It is 0 where no star is.
      mb_StarMask = intarr(DimCube(1),DimCube(2)) + 1

      ; subtract the background in each spectral channel of the cube with masking out
      ; the star. The mask is 0 where the star is. 

      if ( keyword_set (BGAPTMULT) or keyword_set (BGAPTPIX) ) then begin

         if ( keyword_set (BGAPTMULT) ) then begin
            d_fwhm_x = v_FitBGRes(2) & d_fwhm_y = v_FitBGRes(3) & cx = v_FitBGRes(4) & cy = v_FitBGRes(5) 
            radius = BGAPTMULT.(1)*(d_fwhm_x > d_fwhm_y)
         endif

         if ( keyword_set (BGAPTPIX) ) then begin 
            cx = BGAPTPIX(0) & cy = BGAPTPIX(1) & radius = BGAPTPIX(2)
         endif

         dist_circle, m_DistMask, [DimCube(1),DimCube(2)], cx, cy
         v_Mask      = where ( m_DistMask lt radius, n_dist )
         if ( n_dist eq 0 ) then begin
            warning, ['WARNING (spec_opt_extract_spec_from_single_cube.pro):', $
                      '        Star mask for advanced background subtraction contains no valid element', $
                      '        No background subtraction done!!!']
            goto, no_bg_subtraction
         endif else mb_StarMask(v_Mask) = 0

         if ( keyword_set ( OUT_DIR ) ) then $
            writefits, OUT_DIR+'DEBUG_spec_opt_extract_spec_from_single_cube_'+VERSION+'_BGM_'+$
                       filename+'.fits', mb_StarMask

      end

      m_Fit = subtract_slice_bg_from_cube ( pcf_Cube, pcf_IntFrame, pcb_IntAuxFrame, MASK=mb_StarMask, $
                                            MEDIANING=keyword_set(BGMEDIAN), DEBUG=DEBUG )
      if ( NOT bool_is_cube(m_Fit) ) then $
         return, error ( ['FAILURE (spec_opt_extract_spec_from_single_cube.pro):', $
                          '        advanced background subtraction failed' ] )

      if ( keyword_set ( OUT_DIR ) ) then $
         write_spiffi_cube, OUT_DIR+'DEBUG_spec_opt_extract_spec_from_single_cube_'+VERSION+$
                   '_BGC_'+filename+'.fits', *pcf_Cube

      if ( keyword_set(DEBUG) ) then begin
         !p.multi=[0,1,3]
         !p.charsize=2
         plot, m_Fit[0,*],xtitle='Slice',ytitle='Fitted Offset' , $
            title='Debug Info: subtract_slice_bg_from_single_cube'
         plot, m_Fit[1,*],xtitle='Slice',ytitle='Fitted X-Slope' 
         plot, m_Fit[2,*],xtitle='Slice',ytitle='Fitted Y-Slope' 
         !p.multi=[0,1,0]
      end

   end

   ; do we need a PSF for extraction?
   if ( keyword_set(OPTSELF) or keyword_set(OPTAPTMULT) or keyword_set(APTMULT) ) then begin

      s_Image = img_cube2image ( pcf_Cube, pcf_IntFrame, pcb_IntAuxFrame, d_Spec_Channels, k_ImgMode, $
                                 DEBUG = keyword_set(DEBUG) ) 
      if ( NOT bool_is_struct (s_Image) ) then $
         return, error ( ['FAILURE (spec_opt_extract_spec_from_single_cube.pro):', $
                          '         Cube re-collapsing failed'] )
      mf_Image  = s_Image.md_Image 
      md_Weight = s_Image.md_Weight

      ; Log collapsed image
      if ( keyword_set ( OUT_DIR ) ) then $
         writefits,OUT_DIR+'DEBUG_spec_opt_extract_spec_from_single_cube_'+VERSION+$
                   '_IMG2_'+filename+'.fits', mf_Image
   end

   if ( keyword_set(OPTAPTMULT) or keyword_set(APTMULT) ) then begin

      ; Recalculate PSF
      if ( keyword_set(OPTAPTMULT) ) then s_FitMode = OPTAPTMULT.(0)
      if ( keyword_set(APTMULT) ) then s_FitMode = APTMULT.(0)

      mf_PSF = mpfit2dpeak ( mf_Image, v_FitRes, WEIGHTS=md_Weight, /TILT, QUIET=(NOT keyword_set(DEBUG)), $
                             GAUSS=s_FitMode eq 'GAUSS', $
                             LORENTZIAN=s_FitMode eq 'LORENTZ', $
                             MOFFAT=s_FitMode eq 'MOFFAT' )

      if ( keyword_set ( OUT_DIR ) ) then $
         writefits, OUT_DIR+'DEBUG_spec_opt_extract_spec_from_single_cube_'+VERSION+ $
                    '_PSF2_'+filename+'.fits',mf_PSF

      if ( keyword_set(BGAPTMULT) ) then $
         if ( sqrt( (v_FitRes(4)-v_FitBGRes(4))^2 + (v_FitRes(5)-v_FitBGRes(5))^2 ) gt 1. ) then $
            warning, [ 'WARNING (spec_opt_extract_spec_from_single_cube.pro): ',$
                       '      The center of the fitted PSF after background subtraction differs by more',$
                       '      than a pixel from the previously calculated PSF. This is somehow strange!!!',$
                       '      Continuing ...']

      if ( keyword_set ( DEBUG ) ) then begin
         d_ChiS = sqrt(total( (mf_PSF - mf_Image)^2 ))
         debug_info, 'DEBUG INFO (spec_opt_extract_spec_from_single_cube.pro): PSF parameters after BG subtraction: '
         debug_info, 'DEBUG INFO (spec_opt_extract_spec_from_single_cube.pro): offset: '+string(v_FitRes(0))
         debug_info, 'DEBUG INFO (spec_opt_extract_spec_from_single_cube.pro): scale : '+string(v_FitRes(1))
         debug_info, 'DEBUG INFO (spec_opt_extract_spec_from_single_cube.pro): fwhmx : '+string(v_FitRes(2))
         debug_info, 'DEBUG INFO (spec_opt_extract_spec_from_single_cube.pro): fwhmy : '+string(v_FitRes(3))
         debug_info, 'DEBUG INFO (spec_opt_extract_spec_from_single_cube.pro): cx    : '+string(v_FitRes(4))
         debug_info, 'DEBUG INFO (spec_opt_extract_spec_from_single_cube.pro): cy    : '+string(v_FitRes(5))
         if ( n_elements(v_FitRes) eq 7 ) then $
         debug_info, 'DEBUG INFO (spec_opt_extract_spec_from_single_cube.pro): tilt  : '+string(v_FitRes(6))
         if ( n_elements(v_FitRes) eq 8 ) then $
         debug_info, 'DEBUG INFO (spec_opt_extract_spec_from_single_cube.pro): damp  : '+string(v_FitRes(7))
         debug_info, 'DEBUG INFO (spec_opt_extract_spec_from_single_cube.pro): ChiSquare of fitted function is '+ $
                     strtrim(string(d_ChiS),2)
      end

      if ( v_FitRes(0) lt 0. ) then $
         warning, ['WARNING (spec_opt_extract_spec_from_cube_simple.pro): ', $
                   '        The offset of the fitted PSF after background subtraction is negativ (' + $
                   strtrim(string(v_FitBGRes(0)),2)+')', '        Continuing.']

   end

no_bg_subtraction:

   if ( keyword_set ( OPTAPTPIX ) ) then mf_PSF = OPTPSF
   if ( keyword_set ( OPTSELF ) )   then mf_PSF = mf_Image

   ; make a new temporary cube
   v_Spectrum     = dindgen(DimCube(3))*0.
   v_SpectrumSum  = dindgen(DimCube(3))*0.
   v_IntFrame     = dindgen(DimCube(3))*0.
   vb_IntAuxFrame = bindgen(DimCube(3))*0b

   if ( keyword_set ( OPTAPTPIX ) or keyword_set ( OPTAPTMULT ) or keyword_set( OPTSELF ) ) then begin

      ; this is the optimal extraction part

      ; determine the parameters for masking the star
      if ( keyword_set ( OPTAPTPIX ) ) then begin
         dist_circle, m_DistMask, [DimCube(1),DimCube(2)], OPTAPTPIX[0], OPTAPTPIX[1]
         radius = OPTAPTPIX[2]
      endif 

      if ( keyword_set ( OPTAPTMULT ) ) then begin
         dist_circle, m_DistMask, [DimCube(1),DimCube(2)], v_FitRes(4), v_FitRes(5)
         radius = OPTAPTMULT.(1)*(v_FitRes(2) > v_FitRes(3))
      end

      if ( keyword_set ( OPTSELF ) ) then begin
         dummy = max(mf_PSF,c)
         x     = c mod DimCube(1)
         y     = fix(c) / fix(DimCube(1))

         dist_circle, m_DistMask, [DimCube(1),DimCube(2)], x, y
         radius = OPTSELF
      end

      ; calculate the mask
      v_DistMask  = where ( m_DistMask le radius, n_dist )
      mb_DistMask = indgen(DimCube(1),DimCube(2))*0

      if ( n_dist eq 0 ) then $
         return, error (['FAILURE (spec_opt_extract_spec_from_single_cube.pro):', $
                         '         DistMask is invalid. Either the extraction radius is too small or',$
                         '         there is no valid spectrum in the extraction radius'] )

      mb_DistMask(v_DistMask) = 1

      if ( keyword_set ( DEBUG ) ) then $
         debug_info,'DEBUG INFO (spec_opt_extract_spec_from_single_cube.pro): Extracting from '+ $
            strtrim(string(n_dist),2)+' Pixel'

      mmm = where(mf_PSF lt 0., n_Zero)          ; step 5b and 5c of Horne's scheme
      if ( n_Zero gt 0 ) then begin 
         warning, ['WARNING (spec_opt_extract_spec_from_cube_simple.pro): ', $
                   '        The PSF contains negativ values (step 5 of Hornes scheme) Min/Max:'+$
                   strtrim(string(min(mf_PSF)),2)+'/'+strtrim(string(max(mf_PSF)),2), $
                   '        Setting these to 0. and continue.']
         mf_PSF(mmm) = 0. 
      end

      for k = 0, DimCube(3)-1 do begin

         ; search for valid pixel
         mb_MaskValid = valid ( reform((*pcf_Cube)(*,*,k)), reform((*pcf_IntFrame)(*,*,k)), $
                                reform((*pcb_IntAuxFrame)(*,*,k)) )

         v_OptMask = where( mb_DistMask and mb_MaskValid, n_Total )

         if ( keyword_set(OPTFULL)?(n_Total eq n_dist):(n_Total gt 0) ) then begin

            P            = dindgen(DimCube(1),DimCube(2))*0.d
            P(v_OptMask) = mf_PSF(v_OptMask)
            P            = P / total(P)

            ; step 4 of Horne's scheme
            f = total(((*pcf_Cube)(*,*,k))(v_OptMask))   ; step 4 of Horne's scheme

            ; step 6 of Horne's scheme
; changed on 29.3.2004
; IntFrame contains detector noise and photon noise
;            V0            = dindgen(DimCube(1),DimCube(2))*0.d
;            V0(v_OptMask) = 1./((reform((*pcf_IntFrame)(*,*,k)))(v_OptMask))
;            V             = V0 + f*P/OPTQ
            V            = dindgen(DimCube(1),DimCube(2))*0.d
; changed on 19.8.2004
;            V(v_OptMask) = 1./((reform((*pcf_IntFrame)(*,*,k)))(v_OptMask))
            V(v_OptMask) = ((reform((*pcf_IntFrame)(*,*,k)))(v_OptMask))^2


            if ( keyword_set(OPTCLIP) ) then begin
               ; step 7 of Horne's scheme
               C = (((*pcf_Cube)(*,*,k))(v_OptMask) - f*P(v_OptMask))^2
               M = where( C lt OPTCLIP^2*V(v_OptMask), n_Clip) 
            endif else begin
               n_Clip = n_elements(v_OptMask)
               M = indgen(n_Clip)
            end

            ; step 8 of Horne's scheme
            if ( NOT keyword_set ( OPTCLIP ) or n_Clip gt 0 ) then begin

               nom               = total( (P(v_OptMask)*P(v_OptMask)/V(v_OptMask))(M) )
               v_IntFrame(k)     = intframe2noise(sqrt( total( (P(v_OptMask))(M) ) / nom ) ,/REV)
               v_Spectrum(k)     = total( (P(v_OptMask)*((*pcf_Cube)(*,*,k))(v_OptMask)/V(v_OptMask))(M) ) / nom
               v_SpectrumSum(k)  = total( (((*pcf_Cube)(*,*,k))(v_OptMask))(M) )
               vb_IntAuxFrame(k) = setbit(vb_IntAuxFrame(k),0,1)

            endif else begin
               if ( keyword_set ( DEBUG ) ) then $
                  debug_info,'DEBUG INFO (spec_opt_extract_spec_from_single_cube.pro):' + $
                             '            In slice '+strtrim(string(k),2)+' not enough pixel'
               v_Spectrum(k)     = 0.
               v_IntFrame(k)     = 0.
               vb_IntAuxFrame(k) = setbit(vb_IntAuxFrame(k),0,0)
            end

         endif else begin
            ; invalid or too few pixel within the extraction radius
            v_Spectrum(k)     = 0.
            v_IntFrame(k)     = 0.
            vb_IntAuxFrame(k) = setbit(vb_IntAuxFrame(k),0,1)
            if ( keyword_set ( DEBUG ) ) then begin
               if ( keyword_set(OPTFULL) ) then $
                  debug_info,'DEBUG INFO (spec_opt_extract_spec_from_single_cube.pro):' + $
                             '            In slice '+strtrim(string(k),2)+' some pixel in the extraction aperture are invalid.' $
               else $
                  debug_info,'DEBUG INFO (spec_opt_extract_spec_from_single_cube.pro):' + $
                             '            In slice '+strtrim(string(k),2)+' too few pixel.'
            end
         end
      end

   endif else begin

      ; this is the standard extraction section

      ; the weights for each sky-pixel. Invalid sky-pixel will have a weight of 0.
      md_Weights = dindgen(DimCube(1),DimCube(2))*0.+1.

      ; aperture weights ?
      if ( keyword_set ( APTMULT ) ) then begin
         md_Weights = img_aperture ( DimCube(1), DimCube(2), v_FitRes(4), v_FitRes(5), $
                                     APTMULT.(1) * ( v_FitRes(2) > v_FitRes(3) ) )
         if ( keyword_set ( OUT_DIR ) ) then $
            writefits, OUT_DIR+'DEBUG_spec_opt_extract_spec_from_single_cube_'+VERSION+'_APTMULT_'+ $
                       filename+'.fits',md_Weights
         if ( keyword_set ( DEBUG ) ) then $
            debug_info,'DEBUG INFO (spec_opt_extract_spec_from_single_cube.pro): Extraction radius'+ $
            strtrim(string(APTMULT.(1) * ( v_FitRes(2) > v_FitRes(3) ) ),2)+' at '+strtrim(string(v_FitRes(4)),2)+$
            ','+strtrim(string(v_FitRes(5)),2)
      end

      if ( keyword_set ( APTPIX ) ) then begin
         md_Weights = img_aperture ( DimCube(1), DimCube(2), APTPIX(0), APTPIX(1), APTPIX(2))
         if ( keyword_set ( OUT_DIR ) ) then $
            writefits, OUT_DIR+'DEBUG_spec_opt_extract_spec_from_single_cube_'+VERSION+'_APTPIX_'+ $
                       filename+'.fits',md_Weights
         if ( keyword_set ( DEBUG ) ) then $
            debug_info,'DEBUG INFO (spec_opt_extract_spec_from_single_cube.pro): Extraction radius'+ $
            strtrim(string(APTPIX(2)),2)+' at '+strtrim(string(APTPIX(1)),2)+$
            ','+strtrim(string(APTPIX(2)),2)
      end

      ; now the extraction
      if ( keyword_set ( DEBUG ) ) then $
         debug_info,'DEBUG INFO (spec_opt_extract_spec_from_single_cube.pro): Weighting single cube now'
   
      ; 2d mask where combined PSF/aperture weight mask is gt 0.
      mb_Weights = indgen(DimCube(1),DimCube(2))*0

      vb_WeightsTmp = where ( md_Weights gt 0., n_Weights )

      if ( n_Weights gt 0 ) then begin

         mb_Weights(vb_WeightsTmp) = 1

         ; now loop over the slices
         for k = 0, DimCube(3)-1 do begin
   
            ; find valid pixels

            mb_MaskValid = valid ( reform((*pcf_Cube)(*,*,k)), reform((*pcf_IntFrame)(*,*,k)), $
                                   reform((*pcb_IntAuxFrame)(*,*,k)) )
 
            v_Mask = where( mb_Weights and mb_MaskValid, n_Total )

            if ( n_Total eq n_Weights ) then begin

               ; All spectral pixel in the slice within the PSF/aperture weight mask are valid.

               ; fill the slice of the temporary cube with the data slice weighted by the 
               ; overall weights and set IntFrame and IntAuxFrame

               v_Spectrum(k)     = total( ((*pcf_Cube)(*,*,k))(v_Mask) * md_Weights(v_Mask) )
               v_SpectrumSum(k)  = v_Spectrum(k)
               v_IntFrame(k)     = sqrt(total( ( ((*pcf_IntFrame)(*,*,k))(v_Mask) * $
                                                 md_Weights(v_Mask))^2))
               vb_IntAuxFrame(k) = setbit(vb_IntAuxFrame(k),0,1)

            endif else begin
               ; At least one spectral pixel in the slice within the PSF/aperture weight mask is invalid
               v_Spectrum(k)    = 0.
               v_IntFrame(k)    = 0.
               v_IntAuxFrame(k) = setbit(vb_IntAuxFrame(k),0,0)
               if ( keyword_set ( DEBUG ) ) then $
                  debug_info,'DEBUG INFO (spec_opt_extract_spec_from_single_cube.pro):' + $
                             '            In slice '+strtrim(string(k),2)+' the spectrum cannot be extracted'
            end
         end
      endif else return, error ( ['FAILURE (spec_opt_extract_spec_from_single_cube.pro):', $
                                  '        PSF mask is invalid'] )

   end


   return, { Spectrum : v_Spectrum, IntSpectrum : v_IntFrame, IntAuxSpectrum : vb_IntAuxFrame, $
             SpectrumSum : v_SpectrumSum }

end




FUNCTION spec_opt_extract_spec_from_cube_simple, p_Cubes, p_IntFrames, p_IntAuxFrames, n_Cubes, n_z, $
         d_Spec_Channels, k_ImgMode, $
         BGAPTMULT=BGAPTMULT, BGAPTPIX=BGAPTPIX, BGMEDIAN=BGMEDIAN, $
         OPTAPTPIX=OPTAPTPIX, OPTAPTMULT=OPTAPTMULT, OPTSELF=OPTSELF, OPTQ=OPTQ, OPTPSF=OPTPSF, OPTCLIP=OPTCLIP, OPTFULL=OPTFULL, $
         APTPIX=APTPIX, APTMULT=APTMULT, $
         OUT_DIR=OUT_DIR, DEBUG = DEBUG

   ; cube to store the extracted spectra of each cube
   m_Spectra = findgen( n_Cubes, n_z, 3 )

   for i = 0, n_Cubes-1 do begin       ; loop over all datasets

      if ( keyword_set ( DEBUG ) ) then $
         debug_info, 'DEBUG INFO (spec_opt_extract_spec_from_cube.pro): Processing now cube ' + $
                            strtrim(string(i+1),2) + ' of ' + strtrim(string(n_Cubes),2)

      s_ret = spec_opt_extract_spec_from_single_cube ( p_Cubes(i), p_IntFrames(i), p_IntAuxFrames(i), $
              d_Spec_Channels, k_ImgMode, $
              BGAPTMULT=keyword_set(BGAPTMULT)?BGAPTMULT:0, $
              BGAPTPIX=keyword_set(BGAPTPIX)?BGAPTPIX:0, $
              BGMEDIAN=keyword_set(BGMEDIAN), $
              OPTAPTPIX=keyword_set(OPTAPTPIX)?OPTAPTPIX:0, $
              OPTAPTMULT=keyword_set(OPTAPTMULT)?OPTAPTMULT:0, $
              OPTSELF=keyword_set(OPTSELF)?OPTSELF:0, $
              OPTQ=keyword_set(OPTQ)?OPTQ:0, $
              OPTPSF=keyword_set(OPTPSF)?OPTPSF:0, $
              OPTCLIP=keyword_set(OPTCLIP)?OPTCLIP:0, $
              OPTFULL=keyword_set(OPTFULL), $
              APTPIX=keyword_set(APTPIX)?APTPIX:0, $
              APTMULT=keyword_set(APTMULT)?APTMULT:0, $
              OUT_DIR = keyword_set(OUT_DIR) ? OUT_DIR : 0, $
              DEBUG = keyword_set(DEBUG) )

      if ( NOT bool_is_struct (s_ret) ) then $
         return, error ( ['FAILURE (spec_opt_extract_spec_from_cube.pro):', $
                          '         Extraction from cube '+strtrim(string(i+1),2)+' failed'] )

      m_Spectra (i,*,0) = s_ret.Spectrum
      m_Spectra (i,*,1) = s_ret.IntSpectrum
      ; IntAuxSpectrum is 0 for invalid pixel and 1 for valid pixel, all
      ; other bits are deleted
      m_Spectra (i,*,2) = s_ret.IntAuxSpectrum

   end

   ; now combine the extracted spectra
   vf_FinalSpectrum       = dindgen(n_z) * 0.
   vf_FinalIntSpectrum    = dindgen(n_z) * 0.
   vb_FinalIntAuxSpectrum = bindgen(n_z) * 0b

   if ( keyword_set ( DEBUG ) ) then $
      debug_info,'DEBUG INFO (spec_opt_extract_spec_from_cube.pro): Summing up extracted spectra now'

      
   for i=0, n_Cubes-1 do begin
      vf_FinalSpectrum       = vf_FinalSpectrum + reform(m_Spectra ( i,*,0 ))
      vf_FinalIntSpectrum    = sqrt(vf_FinalIntSpectrum^2 + reform(m_Spectra ( i,*,1 ))^2) 
      vb_FinalIntAuxSpectrum = vb_FinalIntAuxSpectrum * reform(m_Spectra ( i,*,2 ))
   end

; changed on 8.4.2004, not neccessary
;   v_Val = aux_valid ( v_FinalIntAuxSpectrum, n_val, /NOVAL )
;   if ( n_val gt 0 ) then begin
;      v_FinalSpectrum(v_Val)    = 0.
;      v_FinalIntSpectrum(v_Val) = 0.
;      ; here v_FinalIntAuxSpectrum still needs to be coded properly
;      v_FinalIntAuxSpectrum(v_Val) = 0.
;   endif else $
;      if ( error_status ne 0 ) then $
;         return, error ( ['FAILURE (spec_opt_extract_spec_from_cube.pro):', $
;                          '         No valid common spectrum found'], error_status )

   return, { Spectrum:vf_FinalSpectrum, IntSpectrum:vf_FinalIntSpectrum, IntAuxSpectrum:byte(vb_FinalIntAuxSpectrum), $
             SpectrumSum : s_ret.SpectrumSum }

end

