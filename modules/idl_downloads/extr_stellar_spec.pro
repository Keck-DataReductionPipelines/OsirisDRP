;------------------------------------------------------------------
;
; NAME : extr_stellar_spec
;
; PURPOSE : extract stellar spectrum from cubes
;
; INPUT :  pcf_Frame          : pointer or pointer array to frame cubes
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
;                               part. OPT is the number of slices used to determine the
;                               extraction PSF.
;          [Outdir=Outdir]    : directory whre to store intermediate
;                               results, also initializes the debugging mode
;
; ALGORITHM : The PSF is calculated (by fitting) from a collapsed
;             image. An extraction mask selects pixel for background
;             estimation. The PSF is fitted again and the spectrum is extracted
;             from a mask.
;
;
;--------------------------------------------------------------------

function extr_stellar_spec, pcf_Frame, pcf_IntFrame, pcb_IntAuxFrame, nFrames, d_Spec_Channel, s_ImgMode,$
                            s_PSFMode, d_FWHMMultiplier, s_BGMethod, d_BGFWHMMultiplier, $
                            OPT=OPT, Outdir=Outdir

   COMMON APP_CONSTANTS

   functionName = 'extr_stellar_spec'

   if ( bool_pointer_integrity( pcf_Frame, pcf_IntFrame, pcb_IntAuxFrame, nFrames, functionName, /CUBE ) ne OK ) then $
      return, error ('ERROR IN CALL (extr_stellar_spec.pro): Integrity check failed.')

   n_Dims = size( *pcf_Frame(0) )

   vi_Frame       = intarr(n_Dims(3))
   vd_Frame       = fltarr(n_Dims(3))
   vd_IntFrame    = fltarr(n_Dims(3))
   vb_IntAuxFrame = bytarr(n_Dims(3))

   for i=0, nFrames-1 do begin

      ;----- BG SUBTRACTION ---------------------------------------------------------------------

      if ( s_BGMethod ne 'NONE' ) then begin

         ; do bg subtraction

         ; find the position of the star
         s_PSF = psf_fit_from_cube( pcf_Frame(i), pcf_IntFrame(i), pcb_IntAuxFrame(i), $
                                    d_Spec_Channel, s_ImgMode, s_PSFMode, OUTDIR=OUTDIR )

         if ( NOT bool_is_struct( s_PSF ) ) then $
            return, error('FAILURE (extr_stellar_spec.pro): PSF fit no. 1 failed.')

         mb_StarMask = img_aperture( n_Dims(1), n_Dims(2), s_PSF.Param(4), s_PSF.Param(5), $
                                     d_BGFWHMMultiplier * ( s_PSF.Param(2) > s_PSF.Param(3) ), /NOSUB )

         if ( 0.10*n_Dims(1)*n_Dims(2) gt total(mb_StarMask) ) then $
            warning, ['FAILURE (extr_stellar_spec.pro): Less than 10% of the pixel are available ', $
                      '        for bg subtraction. Skipping bg subtraction.'] $
         else begin

            ; subtract the background from the cube
            m_Fit = subtract_slice_bg_from_cube ( pcf_Frame(i), pcf_IntFrame(i), pcb_IntAuxFrame(i), $
                        MASK=mb_StarMask, MEDIANING = (s_BGMethod eq 'MEDIAN'), DEBUG=keyword_set(Outdir) )
            if ( NOT bool_is_image(m_Fit) ) then $
               return, error ( 'FAILURE (extr_stellar_spec.pro): Background subtraction failed' )

         end

      end

      ;----- BG SUBTRACTION DONE ----------------------------------------------------------------

      if ( NOT keyword_set ( OPT ) ) then begin

         ;----- NORMAL EXTRACTION ------------------------------------------------------------------

         ; find the position of the star
         s_PSF = psf_fit_from_cube( pcf_Frame(i), pcf_IntFrame(i), pcb_IntAuxFrame(i), $
                                    d_Spec_Channel, s_ImgMode, s_PSFMode, OUTDIR=OUTDIR )

         if ( NOT bool_is_struct( s_PSF ) ) then $
            return, error('FAILURE (extr_stellar_spec.pro): PSF fit no.2  failed.')

         mb_StarMask = img_aperture( n_Dims(1), n_Dims(2), s_PSF.Param(4), s_PSF.Param(5), $
                                     d_FWHMMultiplier * ( s_PSF.Param(2) > s_PSF.Param(3) ), /NOSUB )

         mb_StarMask = byte(bool_invert(mb_StarMask))

         if ( total(mb_StarMask) eq 0 ) then $
            warning, ['FAILURE (extr_stellar_spec.pro): No extraction pixel found.'] $
         else begin

            n_Pix = total(mb_StarMask)
            info, 'INFO (extrs_stellar_spec.pro): Extracting from '+strg(n_Pix)+' pixels.'

            for j=0, n_Dims(3)-1 do begin

               mf_SliceFrame       =  reform((*pcf_Frame(i))(*,*,j))
               mf_SliceIntFrame    =  reform((*pcf_IntFrame(i))(*,*,j))
               mb_SliceIntAuxFrame =  reform((*pcb_IntAuxFrame(i))(*,*,j))


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

         ; optimal extraction

         ; find the position of the star
         s_AllPSF = psf_fit_from_cube( pcf_Frame(i), pcf_IntFrame(i), pcb_IntAuxFrame(i), $
                                       d_Spec_Channel, s_ImgMode, s_PSFMode, OUTDIR=OUTDIR )

         if ( NOT bool_is_struct( s_AllPSF ) ) then $
            return, error('FAILURE (extr_stellar_spec.pro): PSF fit no.2  failed.')

         v_CX    = 0.
         v_CY    = 0.
         v_FWHMX = 0.
         v_FWHMY = 0.

         for k = 0, n_Dims(3)-1 do begin

            if ( (k MOD OPT) eq 0 ) then begin

               lk = k < (n_Dims(3)-1-OPT)
               uk = k+OPT < (n_Dims(3)-1)

               pmf_SliceFrame       =  ptr_new((*pcf_Frame(i))(*,*,lk:uk))
               pmf_SliceIntFrame    =  ptr_new((*pcf_IntFrame(i))(*,*,lk:uk))
               pmb_SliceIntAuxFrame =  ptr_new((*pcb_IntAuxFrame(i))(*,*,lk:uk))

               ; calculate PSF
               s_NewPSF = psf_fit_from_cube( pmf_SliceFrame, pmf_SliceIntFrame, pmb_SliceIntAuxFrame, $
                                             1., s_ImgMode, s_PSFMode, OUTDIR=OUTDIR )
               if ( NOT bool_is_struct( s_NewPSF ) ) then begin
                  warning, 'FAILURE (extr_stellar_spec.pro): PSF fit failed. Taking overall one.'
                  s_PSF = s_AllPSF
               endif else $
                  s_PSF = s_NewPSF

               v_CX    = [v_CX, s_PSF.Param(4)]
               v_CY    = [v_CY, s_PSF.Param(5)]
               v_FWHMX = [v_FWHMX, s_PSF.Param(2)]
               v_FWHMY = [v_FWHMY, s_PSF.Param(3)]

            end

            mb_StarMask = img_aperture( n_Dims(1), n_Dims(2), s_PSF.Param(4), s_PSF.Param(5), $
                                        d_FWHMMultiplier * ( s_PSF.Param(2) > s_PSF.Param(3) ), /NOSUB )

            mb_StarMask = byte(bool_invert(mb_StarMask))

            mf_SliceFrame       =  reform((*pcf_Frame(i))(*,*,k))
            mf_SliceIntFrame    =  reform((*pcf_IntFrame(i))(*,*,k))
            mb_SliceIntAuxFrame =  reform((*pcb_IntAuxFrame(i))(*,*,k))

            mb_Valid  = valid ( mf_SliceFrame, mf_SliceIntFrame, mb_SliceIntAuxFrame ) and mb_StarMask
            v_OptMask = where ( mb_Valid, n_Valid )

            if ( n_Valid gt 0 ) then begin

               P            = dindgen(n_Dims(1),n_Dims(2))*0.d
               P(v_OptMask) = s_PSF.Image(v_OptMask)
               P            = P / total(P)

               ; step 4 of Horne's scheme
               f = total((mf_SliceFrame)(v_OptMask))
               V = fltarr(n_Dims(1),n_Dims(2))
               V(v_OptMask) = mf_SliceIntFrame(v_OptMask)^2

               ; step 8 of Horne's scheme
               d_Denom           = total( (P(v_OptMask)*P(v_OptMask)/V(v_OptMask)) )
               vd_Frame(k)       = vd_Frame(k) + total( (P(v_OptMask)*(mf_SliceFrame)(v_OptMask)/V(v_OptMask)) ) / d_Denom
               vd_IntFrame(k)    = sqrt( vd_IntFrame(k)^2 + total( (P(v_OptMask)) ) / d_Denom )
               vb_IntAuxFrame(k) = setbit(vb_IntAuxFrame(k),0,1)
               vb_IntAuxFrame(k) = setbit(vb_IntAuxFrame(k),3,1)
               vi_Frame(k)       = vi_Frame(k) + n_Valid 

            endif
         end

         if ( keyword_set ( OUTDIR ) ) then begin
            !p.multi=[0,2,2]
            plot, v_CX[1:*], title='X, Median:'+strg(median(v_CX[1:*]))
            plot, v_CY[1:*], title='Y, Median:'+strg(median(v_CY[1:*]))
            plot, v_FWHMX[1:*], title='FWHM X, Median:'+strg(median(v_FWHMX[1:*]))
            plot, v_FWHMY[1:*], title='FWHM Y, Median:'+strg(median(v_FWHMY[1:*]))
         end
      end
   end

   return, { Frame:vd_Frame, IntFrame:vd_IntFrame, IntAuxFrame:vb_IntAuxFrame, NFrame:vi_Frame }

end
