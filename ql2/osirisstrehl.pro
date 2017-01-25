;+
; NAME:
; 	OSIRISSTREHL
;
; PURPOSE:
;	Compute the Strehl of an image taken with the OSIRIS instrument.
;
; EXPLANATION:
;	Finds the brightest non-saturated star in the field and computes
;	its Strehl ratio, or uses star at given pixel location
;
; CALLING SEQUENCE:
;	result = OSIRISSTREHL(image, [FWHM=, PSF=, FILENAME=, HD=, POS=,
;		PSFSZ=, SKYVAL=, CAMNAME=, EFFWAVE=, PMRANGL=, 
;		/DISPLAY, /VERBOSE ])
;
; INPUTS:
;	im = OSIRIS image with at least one point source.
;	  For best results, use reduced (or at least sky-subtracted) images.
;
; OUTPUTS:
;	result = Strehl ratio (floating point number between 0 and 1)
;
;       FWHM - full-width at half maximum of star, in arcseconds
;
;	PSF - point spread function used for calculation
;
; OPTIONAL INPUT KEYWORDS:
;
;	FILENAME - if specified, will load image and header from this filename.
;
;	HD - String array containing the FITS header associated with the
;		image.  If this is included, the keywords CAMNAME, 
;		EFFWAVE, and PMRANGL are not necessary.
;
;       POS - position of star to compute Strehl from.  By default, the
;		strehl of the brightest star-like object is computed.
;
;	PHOTRAD - photometric radius to use, in arcseconds.  Default=1.0
;
;	PSFSZ - Size of PSF to generate, in pixels.  Best if larger than
;		 photometric radius.  Default = 256.
;
;	SKYVAL - Specify the background value.  Otherwise computed with SKY
;		 
;	The following 4 kewords override the header fields in HD if set:
;
;	CAMNAME - camera name, eg. 'narrow'.
;
;	EFFWAVE - effective wavelength of filter in microns.
;
;	PMRANGL - pupil drive's angular position, in degress.
;
;	/DISPLAY - display image and PSF, with photometric aperture
;
;	/VERBOSE - output status messages to std. output.
;
; EXAMPLE:
;	flist = FINDFILE('/s/sdata904/nirc2eng/*/n????.fits')
;	im = READFITS(flist[0],hd)
;	strehl = OSIRISSTREHL(im,hd=hd,fwhm=fwhm)
;	PRINT,STRING([strehl,fwhm],f='("Strehl=",F4.2," FWHM=",F5.3)')
;
; NOTES:
;	None yet.
;
; PROCEDURES USED:
;	Functions:	OSIRISPSF(), OSIRISPUPIL()
;	Procedures:	FIND, CNTRD, SKY, APER (IDL Astronomy User's Library)
;			MPFITFUN (from Craig Markward's IDL library)
;
; MODIFICATION HISTORY:
;	Create 01/05 AHB.
;	Modification written March 2005, M. McElwain, UCLA
;           - adapted to OSIRIS
;-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION CENTGAUSS, x, p

  y = p[0] * EXP( -0.5 * (x / p[1])^2 )

RETURN,y
END

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION APPHOT, im, ap, pos=pos, skyval=skyval, npix=npix

  sz = (SIZE(im))[1:2]
  if not KEYWORD_SET(pos) then begin
    foo = MAX(im, mp)
    pos = [mp mod sz[0], mp/sz[0]]
  endif

  if N_ELEMENTS(skyval) eq 0 then $
    SKY, im, skyval

  DIST_CIRCLE, r, sz[0], pos[0]-0.5, pos[1]-0.5
  nap = N_ELEMENTS(ap)
  phot = FLTARR(nap)
  npix = FLTARR(nap)
  for i=0,nap-1 do begin
    if i eq 0 then w = WHERE(r lt ap[i], nw) $
      else w = WHERE((r ge ap[i-1]) and (r lt ap[i]), nw)
    npix[i] = nw
    if (nw gt 0) then phot[i] = TOTAL(im[w]-skyval)
  endfor

RETURN,phot
END

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION OSIRISSTREHL, im, FWHM=fwhm, PSF=psf, FILENAME=filename, HD=hd, $
                       POS=pos, PHOTRAD=photrad, PSFSZ=psfsz, SKYVAL=skyval, CAMNAME=camname, $
                       EFFWAVE=effwave, PMRANGL=pmrangl, DISPLAY=display, $
                       VERBOSE=verbose
  

  if KEYWORD_SET(filename) then $
    im = READFITS(filename, hd, silent=1-verbose)
  if KEYWORD_SET(hd) then begin
    if not KEYWORD_SET(camname) then camname = STRTRIM(SXPAR(hd, 'CAMNAME'))
    if not KEYWORD_SET(effwave) then effwave = SXPAR(hd, 'EFFWAVE')
    if not KEYWORD_SET(pmrangl) then pmrangl = SXPAR(hd, 'PMRANGL')
  endif else begin
    if not KEYWORD_SET(camname) then camname = 'narrow'
    if not KEYWORD_SET(effwave) then effwave = 2.12450
    if not KEYWORD_SET(pmrangl) then pmrangl = 0.
  endelse
  if not KEYWORD_SET(photrad) then photrad = 1.	; photometry radius (")
  if not KEYWORD_SET(psfsz) then psfsz = 256	; size of PSF to generate
  if not KEYWORD_SET(display) then display = 0
  if not KEYWORD_SET(verbose) then verbose = 0

;pmsname = 'open'	;FOR COMPARISON WITH MVD STREHL METER

  sz0 = (SIZE(im))[1:2]
  dsz = 256			; Display image size

;;; 1. If position of star not specified, find brightest star-like object

  if not KEYWORD_SET(pos) then begin
    bin = 4
    ; bin = 1 ; if there is one bad pixel, then it will say that is the star
    sim = REMED(im,sz0[0]/bin,sz0[1]/bin)
    foo = MAX(sim, mp)
    pos = [mp mod (sz0[0]/bin), mp*bin/sz0[0]] * bin
  endif

;;; 2. Find precise centroid of star

  case camname of
    '0.020': begin
      pscl = 20e-3
      fwhm0 = 206265. * effwave * 1e-6 / (10.0 * pscl)
    end
    '0.035': begin
      pscl = 35e-3
      fwhm0 = 2 * 206265. * effwave * 1e-6 / (10.0 * pscl)
    end
    '0.050': begin
      pscl = 50e-3
      fwhm0 = 3 * 206265. * effwave * 1e-6 / (10.0 * pscl)
    end
    '0.100': begin
      pscl = 100e-3
      fwhm0 = 4 * 206265. * effwave * 1e-6 / (10.0 * pscl)
    end
  endcase
  CNTRD, im, pos[0], pos[1], xc0, yc0, fwhm0*4, silent=1-verbose
  CNTRD, im, xc0, yc0, xc, yc, fwhm0, silent=1-verbose
  xc = xc + 0.5				; convert to AB std. pix-edge coord.
  yc = yc + 0.5

;;; 3. Compute PSF on psfsz subimage at approximate position of star

  c1 = ROUND([xc+psfsz/2*[-1,1], yc+psfsz/2*[-1,1]]) + [0,-1,0,-1]
  if c1[0] lt 0 then c1[0:1] = [0, psfsz-1]
  if c1[1] gt sz0[0]-1 then c1[0:1] = [sz0[0]-psfsz, sz0[0]-1]
  if c1[2] lt 0 then c1[2:3] = [0, psfsz-1]
  if c1[3] gt sz0[1]-1 then c1[2:3] = [sz0[1]-psfsz, sz0[1]-1]
  psf = OSIRISPSF(npix=psfsz, pos=[xc,yc]-c1[[0,2]]-psfsz/[2,2], $
    camname=camname, effwave=effwave, pmrangl=pmrangl)

;;; 4. Measure photometry on both star and PSF using astrolib APER routine

  phpadu = 3.957				; e-/ADU, OSIRIS pre-ship doc.
  if N_ELEMENTS(skyval) ne 1 then $
    SKY, im, skyval, skyerr, silent=1-verbose else $
    skyerr = 1.0

  ap = ROUND(photrad/pscl)
  phot = APPHOT(im, ap, pos=[xc,yc], skyval=skyval, npix=npix)
  flx = TOTAL(phot)
  psf_flx = TOTAL(APPHOT(psf, ap, pos=[xc,yc]-c1[[0,2]], skyval=0))

;;; 5. Extract subimage centered on star centroid

  fscl = 4.0
  c0 = ROUND([xc+fscl*fwhm0*[-0.5,0.5], yc+fscl*fwhm0*[-0.5,0.5]])
  if c0[0] lt 0 then c0[0:1] = [0,fscl*fwhm0-1]
  if c0[1] gt sz0[0]-1 then c0[0:1] = [sz0[0]-fscl*fwhm0,sz0[0]-1]
  if c0[2] lt 0 then c0[2:3] = [0,fscl*fwhm0-1]
  if c0[3] gt sz0[1]-1 then c0[2:3] = [sz0[1]-fscl*fwhm0,sz0[1]-1]
  sz1 = c0[[1,3]] - c0[[0,2]] + 1
  sim = im[c0[0]:c0[1],c0[2]:c0[3]] - skyval[0]
  c2 = c0 - c1[[0,0,2,2]]
  spsf = psf[c2[0]:c2[1],c2[2]:c2[3]]
  peak = MAX(sim)
  psf_peak = MAX(spsf)

;;; 6. If DISPLAY keyword set, display image and PSF

  if display then begin
    c2 = ROUND([xc+dsz*[-0.5,0.5], yc+dsz*[-0.5,0.5]]) + [0,-1,0,-1]
    if c2[0] lt 0 then c2[0:1] = [0,dsz-1]
    if c2[1] gt sz0[0]-1 then c2[0:1] = [sz0[0]-dsz,sz0[0]-1]
    if c2[2] lt 0 then c2[2:3] = [0,dsz-1]
    if c2[3] gt sz0[1]-1 then c2[2:3] = [sz0[1]-dsz,sz0[1]-1]
    if display gt 1 then dwin = display else dwin = 10
    WINDOW, dwin, xs=dsz*2, ys=dsz*2

    dexp = 0.3
    dim  = im[c2[0]:c2[1],c2[2]:c2[3]] - skyval[0]

    if dsz gt psfsz then begin
      c3 = c1-c2+[0,dsz-1,0,dsz-1]
      dpsf = FLTARR(dsz,dsz)
      dpsf[c3[0]:c3[1],c3[2]:c3[3]] = psf
    endif else $
      dpsf = psf[c2[0]-c1[0]:c2[1]-c1[0],c2[2]-c1[2]:c2[3]-c1[2]]

    TV, (((dim*255^(1/dexp)/peak)>0)^dexp)<255, 0, dsz
    TV, (((dpsf*255^(1/dexp)/psf_peak)>0)^dexp)<255, dsz, dsz
    TVCIRCLE, ap, xc-c2[0]-0.5, dsz+yc-c2[2]-0.5
    TVCIRCLE, ap, dsz+xc-c2[0]-0.5, dsz+yc-c2[2]-0.5
  endif

;;; 5. Measure FWHM of star and PSF

  DIST_CIRCLE, r, sz1[0], xc-c0[0]-0.5, yc-c0[2]-0.5
  psf_fwhm0 = 2*INTERPOL(r[sort(r)],spsf[SORT(r)], psf_peak/2.)	; approximate!
  gfit_thresh = psf_fwhm0 * 0.70
  w = WHERE(r lt gfit_thresh, nw)
  if w[0] ne -1 then begin
    err = REPLICATE(skyerr, nw)
    gpar0 = [peak, psf_fwhm0/2.35]
    gpar = MPFITFUN('centgauss', r[w], sim[w], err, gpar0, /quiet)
    peak = gpar[0]
    fwhm = gpar[1] * 2.35 * pscl

    psf_gpar0 = [psf_peak, psf_fwhm0/2.35]
    psf_gpar = MPFITFUN('centgauss', r[w], spsf[w], err, psf_gpar0, /quiet)
    psf_peak = psf_gpar[0]
    psf_fwhm = psf_gpar[1] * 2.35 * pscl
  endif else begin
    fwhm = 2*INTERPOL(r[sort(r)],spsf[SORT(r)], peak/2.) * pscl
    psf_fwhm = psf_fwhm0 * pscl
  endelse

;;; 6. Compute Strehl ratio and FWHM

  strehl = (peak/flx[0])/(psf_peak/psf_flx[0])

;;; 7. Ouput Strehl and FWHM to display image and/or command line

  ftxt = 'FWHM = ' + STRING(fwhm,f='(F5.3)')
  ftxt1 = 'FWHM = ' + STRING(psf_fwhm,f='(F5.3)')
  stxt = 'Strehl = ' + STRING(strehl,f='(F5.3)')
  stxt1 = 'Strehl = ' + STRING(1.0,f='(F5.3)')
;;  dtxt = 'Diffraction limit (' + pmsname + ')'

  if display then begin
    XYOUTS,0.01,0.51,ftxt,/norm,chars=1.2,align=0.0
    XYOUTS,0.49,0.51,stxt,/norm,chars=1.2,align=1.0
    XYOUTS,0.25,0.97,'Image',/norm,chars=1.3,align=0.5
    XYOUTS,0.51,0.51,ftxt1,/norm,chars=1.2,align=0.0
    XYOUTS,0.99,0.51,stxt1,/norm,chars=1.2,align=1.0
;;    XYOUTS,0.75,0.97,dtxt,/norm,chars=1.3,align=0.5

    ;cbar = CONGRID(FINDGEN(1,256), 10, ROUND(dsz*0.92))
    ;TV, (((cbar*255^(1/dexp)/256)>0)^dexp)<255, 2*dsz-10, ROUND(dsz*0.08)

    PLOT, r*pscl, sim/peak, ps=1, /noerase, pos=[0.0,0.04,0.5,0.5], $
      /xsty, xr=[0,fwhm*1.5], ysty=5, yr=[0,1]
    AXIS, yaxis=0, /ysty, yr=[0,1]
    x = gfit_thresh * FINDGEN(100)/100 * pscl
    OPLOT, x, CENTGAUSS(x/pscl,gpar)/peak	;, thick=2
    OPLOT, fwhm*[0.5,0.5], [0,0.5]

    PLOT, r*pscl, spsf/psf_peak, ps=1, /noerase, pos=[0.5,0.04,1.0,0.5], $
      /xsty, xr=[0,fwhm*1.5], /ysty, yr=[0,1]
    OPLOT, x, CENTGAUSS(x/pscl,psf_gpar)/psf_peak	;, thick=2
    OPLOT, psf_fwhm*[0.5,0.5], [0,0.5]
  endif
  if verbose then begin
    MESSAGE,/info,'FWHM  = ' + STRTRIM(fwhm,2)
    MESSAGE,/info,'Strehl= ' + STRTRIM(strehl,2)
  endif

RETURN,strehl
END
