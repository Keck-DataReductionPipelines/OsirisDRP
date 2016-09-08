;+
; NAME:
;	OSIRISPSF
;
; PURPOSE:
;	Calculate theoretical PSF for a OSIRIS image.
;
; EXPLANATION:
;	Calculates the diffraction-limited monochromatic OSIRIS point
;	spread function (PSF) for any camera, pupil stop, and pupil angle.
;
; CALLING SEQUENCE:
;	result = OSIRISPSF( [NPIX=, POS=, HD=, CAMNAME=, 
;		EFFWAVE=, PMRANGL=, PUPIL= ])
;
; INPUTS:
;	none.
;
; OUTPUTS:
;	result = image of PSF
;
; OPTIONAL OUPUTS:
;	PUPIL = pupil image used to generate PSF
;
; OPTIONAL INPUT KEYWORDS:
;	NPIX = size of pupil image, in pixels
;
;       POS = position of PSF wrt image center (pixel-edge coordinates!)
;
;	HD = string array containing OSIRIS FITS header
;
;	The following 4 keywords override the header fields in HD if set:
;
;	CAMNAME = camera name, eg. 'narrow'
;
;	EFFWAVE = effective wavelength of filter in microns
;
;	PMRANGL = pupil drive's angular position (for rotated pupil images).
;
; EXAMPLE:
;	flist = FINDFILE('/s/sdata904/nirc2eng/*/n????.fits')
;	hd = HEADFITS(flist[0])
;	psf = OSIRISPSF(npix=512, hd=hd, pupil=pupil)
;
; ERROR HANDLING:
;	none
;
; RESTRICTIONS:
;	none
;
; NOTES:
;	none
;
; PROCEDURES USED:
;	Functions:	OSIRISPUPIL()
;
; MODIFICATION HISTORY:
;	Original written May 2004, A. Bouchez, W.M. Keck Observatory
;	Modification written March 2005, M. McElwain, UCLA
;           - adapted to OSIRIS
;-
FUNCTION OSIRISPSF, NPIX=npix, POS=pos, HD=hd, CAMNAME=camname,$
		EFFWAVE=effwave, PMRANGL=pmrangl, PUPIL=pupil

  if not KEYWORD_SET(npix) then npix = 256
  if not KEYWORD_SET(pos) then pos = [0.,0]
  if KEYWORD_SET(hd) then begin
    if not KEYWORD_SET(camname) then camname = strtrim(SXPAR(hd, 'SS1NAME'),2)
    if not KEYWORD_SET(effwave) then effwave = SXPAR(hd, 'EFFWAVE')
    if not KEYWORD_SET(pmrangl) then pmrangl = SXPAR(hd, 'PMRANGL')
  endif else begin
    if not KEYWORD_SET(camname) then camname = '0.020'
    if not KEYWORD_SET(effwave) then effwave = 2.12450
    if not KEYWORD_SET(pmrangl) then pmrangle = 0.
  endelse

;;; 1. Calculate OSIRIS2 pupil
;;; We require du<0.10 m/pix(for sufficient detail) and $
;;;   npix*du>12.0 m(to avoid truncating pupil).  This is done by increasing
;;;   the platescale and resampling and/or increasing the pupil image size.

  camstr = STRUPCASE(STRCOMPRESS(camname,/remove_all))
  case camstr of
      '0.020': pscl = 0.020 / 206265 ; radians/pix
      '0.035': pscl = 0.035 / 206265
      '0.050': pscl = 0.050 / 206265
      '0.100': pscl = 0.100 / 206265
    else: begin
      MESSAGE,/info,'camname ' + camstr + $
        ' not recognized.  Using default=NARROW'
      pscl = 0.009942 / 206265
    end
  endcase

  tmp = pscl * 12.0 / (effwave*1e-6)
  rpfac = (2.^CEIL(ALOG( tmp )/ALOG(2)))>1	; reb. 2^N so npix*du>12.0 m
  pscl1 = pscl / rpfac				; reb. detector platescale
  npix1 = npix * rpfac				; reb. image size
  du = (effwave*1e-6) / (npix1 * pscl1)		; pupil image platescale, m/pix
  rdfac = (2.^CEIL(ALOG( du / 0.10 )/ALOG(2)))>1	; reb. 2^N so du<0.10
  npix2 = npix1 * rdfac				; reb. pupil image size
  du = (effwave*1e-6) / (npix2 * pscl1)		; reb. pupil image pscl, m/pix
  pupil = OSIRISPUPIL(npix=npix2,du=du,pmrangl=pmrangl)

;;; 2. Create phase ramp to position PSF.  Note that the -[0.5,0.5]
;;;   forces the PSF to lie on the pixel edges if pos=[0,0].

  uu = REBIN(FINDGEN(npix2,1),npix2,npix2)
  vv = REBIN(FINDGEN(1,npix2),npix2,npix2)
  rpos = pos * rpfac - 0.5
  phase = 2 * !pi * (uu*rpos[0] + vv*rpos[1]) / npix2

;;; 3. Compute PSF by fast Fourier transform

  wavefront = pupil * EXP(COMPLEX(0,phase))
  rpsf = SHIFT(ABS(FFT(wavefront,-1))^2, npix2/2, npix2/2)
  psf = REBIN(rpsf(npix2/2-npix1/2:npix2/2+npix1/2-1, $
                   npix2/2-npix1/2:npix2/2+npix1/2-1),npix,npix)

RETURN,psf/TOTAL(psf)
END
