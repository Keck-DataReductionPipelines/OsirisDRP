;------------------------------------------------------------------
;
; NAME : extr_stellar_spec_2
;
; PURPOSE : extract stellar spectrum from cubes
;
; INPUT :  pcf_Frame          : pointer or pointer array to frame cubes.
;          pcf_IntFrame       : pointer or pointer array to intframe cubes
;          pcb_IntAuxFrame    : pointer or pointer array to intauxframe cubes
;          nFrames            : number of valid cubes
;          d_Spec_Channel     : fraction of cube that is collapsed to
;                               get a high S/N image of the star, used
;                               for fitting the PSF (0<d_Spec_Channel<1)
;          s_ImgMode          : 'MED' : pixel in the collapsed image is the median value
;                                       of the spectra
;                               'AVRG': pixel in the collapsed image is the mean value
;                                       of the spectra     
;                               'SUM' : pixel in the collapsed image is the sum
;                                       of the spectra
;          s_PSFMode          : 'GAUSS' or 'LORENTZIAN' or 'MOFFAT', form
;                               of the PSF
;          d_FWHMMultiplier   : extraction radius = d_FWHMMultiplier *
;                               max(FWHM of PSF)
;          s_BGMethod         : Background estimation method 
;                               'NONE'   : no background subtraction
;                               'MEDIAN' : median background in each slice
;                               'FIT'    : fit of a plane to each
;                                          slice
;          d_BGFHWMMultiplier : the background will be estimated from
;                               all pixel that are more far away from the fitted PSF center
;                               than d_BGFHWMMultiplier*max(FWHM of
;                               PSF)
;          [OPT=OPT]          : initializes the optimal extraction
;                               part (see Horne, 1986 PASP 98:609.). 
;                               OPT is the number of sigmas for
;                               clipping. When extracting optimally
;                               the frame and intframe values must be
;                               in electrons (!!!).
;          [/DEBUG]           : initializes the debugging mode
;
; ALGORITHM : The PSF is calculated (by fitting) from a collapsed
;             image. An extraction mask selects pixel for background
;             estimation. The PSF is fitted again and the spectrum is extracted
;             from a mask.
;
; NOTES : The input cubes must be EURO3D compliant. The result is a vector.
;
; STATUS : untested
;
; HISTORY : 9.9.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;--------------------------------------------------------------------

function extr_stellar_spec_2, pcf_Frame, pcf_IntFrame, pcb_IntAuxFrame, nFrames, d_Spec_Channel, s_ImgMode,$
                              s_PSFMode, d_FWHMMultiplier, s_BGMethod, d_BGFWHMMultiplier, $
                              OPT = OPT, DEBUG=DEBUG

   COMMON APP_CONSTANTS

   functionName = 'extr_stellar_spec_2'

   ; integrity check

   if ( bool_pointer_integrity( pcf_Frame, pcf_IntFrame, pcb_IntAuxFrame, nFrames, functionName, /CUBE ) ne OK ) then $
      return, error ('ERROR IN CALL (' + functionName + '): Integrity check failed.')

   If ( (d_Spec_Channel LT 0.1) OR (d_Spec_Channel GT 1.) ) THEN $
     	return, error( 'ERROR IN CALL (' + functionName + '): SpecChannels parameter out of bounds.')
   
   If ( (s_ImgMode ne 'MED') and (s_ImgMode ne 'AVRG') and (s_ImgMode ne 'SUM') ) THEN $
     	return, error( 'ERROR IN CALL (' + functionName + '): ImgMode parameter invalid.')
 
   If ( (s_PSFMode ne 'GAUSS') and (s_PSFMode ne 'LORENTZIAN') and (s_PSFMode ne 'MOFFAT') ) THEN $
     	return, error( 'ERROR IN CALL (' + functionName + '): PSFMode parameter invalid.')

   If ( (d_FWHMMultiplier lt 0.1) or (d_FWHMMultiplier gt 100.) ) THEN $
     	return, error ('ERROR IN CALL (' + functionName + '): FWHMMultiplier parameter out of bounds.')

   If ( (s_BGMethod ne 'NONE') and (s_BGMethod ne 'MED') and (s_BGMethod ne 'FIT') ) THEN $
     	return, error('ERROR IN CALL (' + functionName + '): BGMode parameter invalid.')
 
   If ( (s_BGMethod ne 'NONE') ) then $
      If ( (d_BGFWHMMultiplier lt 0.1) or (d_BGFWHMMultiplier gt 100.) ) THEN $
         return, error('ERROR IN CALL (' + functionName + '): BGFWHMMultiplier parameter out of bounds.')

   if ( keyword_set ( OPT )  ) then begin
      d_Opt = OPT
      if ( (d_Opt lt 0.1) or (d_Opt gt 100.) ) THEN $
        	return, error( 'WARNING (' + functionName + '): OPT parameter out of bounds.')
   end

   ; the parameters and the integrity are ok, now run

   n_Dims = size( *pcf_Frame(0) )

   ; data structure where the (intermediate) result is stored
   vi_Frame       = intarr(n_Dims(1))
   vd_Frame       = fltarr(n_Dims(1))
   vd_IntFrame    = fltarr(n_Dims(1))
   vb_IntAuxFrame = bytarr(n_Dims(1))

   ; loop over all input cubes
   for i=0, nFrames-1 do begin

      if ( keyword_set ( DEBUG ) ) then $
         debug_info,'DEBUG INFO (extr_stellar_spec_2.pro): '+ strg(fix(i/nFrames))+'% of total extraction done.'

      ;----- BG SUBTRACTION ---------------------------------------------------------------------

      if ( s_BGMethod ne 'NONE' ) then begin

         ; do bg subtraction
         if ( keyword_set ( DEBUG ) ) then $
            debug_info,'DEBUG INFO (extr_stellar_spec_2.pro): Subtracting background now'

         ; find the position of the star
         s_PSF = psf_fit_from_cube( pcf_Frame(i), pcf_IntFrame(i), pcb_IntAuxFrame(i), $
                                    d_Spec_Channel, s_ImgMode, s_PSFMode, DEBUG=keyword_set(DEBUG) )

         if ( NOT bool_is_struct( s_PSF ) ) then $
            return, error('FAILURE (extr_stellar_spec.pro): PSF fit no. 1 failed.')

         ; mask out the star
         mb_StarMask = img_aperture( n_Dims(2), n_Dims(3), s_PSF.Param(4), s_PSF.Param(5), $
                                     d_BGFWHMMultiplier * ( s_PSF.Param(2) > s_PSF.Param(3) ), /NOSUB )

         if ( 0.10*n_Dims(2)*n_Dims(3) gt total(mb_StarMask) ) then $
            ; do nothing if too few pixel
            warning, ['FAILURE (extr_stellar_spec.pro): Less than 10% of the pixel are available ', $
                      '        for bg subtraction. Skipping bg subtraction.'] $
         else begin

            ; subtract the background from the cube
            m_Fit = subtract_slice_bg_from_cube ( pcf_Frame(i), pcf_IntFrame(i), pcb_IntAuxFrame(i), $
                        MASK=mb_StarMask, MEDIANING = (s_BGMethod eq 'MEDIAN'), DEBUG=keyword_set(DEBUG) )
            if ( NOT bool_is_image(m_Fit) ) then $
               return, error ( 'FAILURE (extr_stellar_spec.pro): Background subtraction failed' )

         end

      end

      ;----- BG SUBTRACTION DONE ----------------------------------------------------------------

      if ( NOT keyword_set ( OPT ) ) then begin

         ;----- NORMAL EXTRACTION ------------------------------------------------------------------

         ; find the position of the star
         s_PSF = psf_fit_from_cube( pcf_Frame(i), pcf_IntFrame(i), pcb_IntAuxFrame(i), $
                                    d_Spec_Channel, s_ImgMode, s_PSFMode, DEBUG=keyword_set(DEBUG) )

         if ( NOT bool_is_struct( s_PSF ) ) then $
            return, error('FAILURE (extr_stellar_spec.pro): PSF fit no.2  failed.')

         ; calculate extraction radius
         d_Radius    = d_FWHMMultiplier * ( s_PSF.Param(2) > s_PSF.Param(3) ) 
         ; calculate extraction mask
         d_FracXY    = sqrt((s_PSF.Param(4)-round(s_PSF.Param(4)))^2 + (s_PSF.Param(5)-round(s_PSF.Param(5)))^2)
         mb_StarMask = img_aperture( n_Dims(2), n_Dims(3), s_PSF.Param(4), s_PSF.Param(5), $
                                     d_Radius + d_FracXY, /NOSUB )
         mb_StarMask = byte(bool_invert(mb_StarMask))

         if ( total(mb_StarMask) eq 0 ) then $
            warning, ['FAILURE (extr_stellar_spec.pro): No extraction pixel found.'] $
         else begin

            ; there is at least one valid pixel
            n_Pix = total(mb_StarMask)
            info, 'INFO (extrs_stellar_spec.pro): Extracting from '+strg(n_Pix)+' pixels.'

            ; loop over the slices
            for j=0, n_Dims(1)-1 do begin

               mf_SliceFrame       =  reform((*pcf_Frame(i))(j,*,*))
               mf_SliceIntFrame    =  reform((*pcf_IntFrame(i))(j,*,*))
               mb_SliceIntAuxFrame =  reform((*pcb_IntAuxFrame(i))(j,*,*))

               ; check for valid (valid and within starmask) pixel
               mb_Valid = valid ( mf_SliceFrame, mf_SliceIntFrame, mb_SliceIntAuxFrame ) and mb_StarMask
               vi_Valid = where ( mb_Valid, n_Valid )

               ; all pixel in the StarMask must be valid
               ; if ( n_Valid eq n_Pix ) then begin
               if ( n_Valid gt 0 ) then begin

                  vd_Frame(j)       = vd_Frame(j)       + total((mf_SliceFrame)(vi_Valid))
                  vd_IntFrame(j)    = vd_IntFrame(j)    + sqrt(total((mf_SliceIntFrame)(vi_Valid)^2))
                  vb_IntAuxFrame(j) = vb_IntAuxFrame(j) + setbit(vb_IntAuxFrame(i),0,1)
                  vb_IntAuxFrame(j) = vb_IntAuxFrame(j) + setbit(vb_IntAuxFrame(i),3,1)
                  vb_IntAuxFrame(j) = vb_IntAuxFrame(j) + setbit(vb_IntAuxFrame(i),1,1)
                  vi_Frame(j)       = vi_Frame(j)       + n_Valid

               end
            end
         end

      endif else begin

         ;----- OPTIMAL EXTRACTION -----------------------------------------------------------------

         ; loop over the slices
         for k = 0, n_Dims(1)-1 do begin

            if ( (k mod (n_Dims(1)/20)) eq 0 ) then $
               info,'INFO (extr_stellar_spec_2.pro): '+ $
                  strg(fix(float(k)*100./n_Dims(1)))+'% of optimal extraction done.'
            ; the individual slices
            pmf_SliceFrame       =  ptr_new((*pcf_Frame(i))(k,*,*))
            pmf_SliceIntFrame    =  ptr_new((*pcf_IntFrame(i))(k,*,*))
            pmb_SliceIntAuxFrame =  ptr_new((*pcb_IntAuxFrame(i))(k,*,*))

            ; the iterative optimal extraction part
            s_Res = extr_horne_1 ( pmf_SliceFrame, pmf_SliceIntFrame, pmb_SliceIntAuxFrame, $
                                   s_ImgMode, s_PSFMode, d_FWHMMultiplier, d_Opt, 0, DEBUG=keyword_set(DEBUG) )

            if ( bool_is_Struct(s_Res) ) then begin
               if ( s_Res.N ne 0 ) then begin
                  ; the extraction was succesful
                  ; step 8 of Horne's scheme
                  vd_Frame(k)       = vd_Frame(k) + s_Res.Frame
                  vd_IntFrame(k)    = sqrt( vd_IntFrame(k)^2 + s_Res.IntFrame )
                  vb_IntAuxFrame(k) = setbit(vb_IntAuxFrame(k),0,1)
                  vb_IntAuxFrame(k) = setbit(vb_IntAuxFrame(k),3,1)
                  vi_Frame(k)       = vi_Frame(k) + s_Res.N

               endif

            endif

         end

      end

   end

   return, { Frame:vd_Frame, IntFrame:vd_IntFrame, IntAuxFrame:vb_IntAuxFrame, NFrame:vi_Frame }

end
