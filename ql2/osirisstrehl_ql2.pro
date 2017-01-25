;+
; NAME:
; 	OSIRISSTREHL_QL2
;
; PURPOSE:
;	Compute the Strehl of an image taken with the OSIRIS instrument.
;
; EXPLANATION:
;	Finds the brightest non-saturated star in the field and computes
;	its Strehl ratio, or uses star at given pixel location
;
; CALLING SEQUENCE:
;	result = OSIRISSTREHL_QL2(image, [FWHM=, PSF=, FILENAME=, HD=, POS=,
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
;	PHOTRAD - photometric radius to use, in pixels.
;                 Default=1.0" (calculated from plate scale)
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
;	Functions:	OSIRISPSF_QL2(), OSIRISPUPIL_QL2()
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
FUNCTION OSIRISSTREHL_QL2, base_id, pos, photrad=photrad

print, 'strehlling now 2 times'

widget_control, base_id, get_uval=cimwin_uval
widget_control, cimwin_uval.exist.strehl, get_uval=strehl_uval

self=(*cimwin_uval.self_ptr)

; get image object for this image window
ImObj_ptr=self->GetImObj()
ImObj=*ImObj_ptr

disp_im=*(self->GetDispIm())

im_s=size(disp_im)

if ((im_s[1] lt 256) or (im_s[2] lt 256)) then begin
    im=fltarr(256,256)
    im[0:im_s[1]-1,0:im_s[2]-1]=disp_im
endif else begin
    im=disp_im
endelse

hd=*(ImObj->GetHeader())
camname=osiris_pscale(hd)
effwave=osiris_effwave(hd)
 
if (camname eq '0') then camname='0.020'
if (effwave eq 0) then effwave=2.12450
pmrangl=0.

psfsz=256	; size of PSF to generate
display=0
verbose=0

; DISCLAIMER
if ((camname eq '0.100') or (camname eq '0.050')) then begin
    ; let the person know they're in trouble
    message='Unless you are working in the mid-infrared,'+$
             ' your strehl calculation may be undersampled.'
    answer=dialog_message(message, dialog_parent=base_id, /info)
endif

;pmsname = 'open' ; FOR COMPARISON WITH MVD STREHL METER

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
xc = xc + 0.5                   ; convert to AB std. pix-edge coord.
yc = yc + 0.5

;;; 3. Compute PSF on psfsz subimage at approximate position of star

c1 = ROUND([xc+psfsz/2*[-1,1], yc+psfsz/2*[-1,1]]) + [0,-1,0,-1]
if c1[0] lt 0 then c1[0:1] = [0, psfsz-1]
if c1[1] gt sz0[0]-1 then c1[0:1] = [sz0[0]-psfsz, sz0[0]-1]
if c1[2] lt 0 then c1[2:3] = [0, psfsz-1]
if c1[3] gt sz0[1]-1 then c1[2:3] = [sz0[1]-psfsz, sz0[1]-1]
psf = OSIRISPSF_QL2(npix=psfsz, pos=[xc,yc]-c1[[0,2]]-psfsz/[2,2], $
                camname=camname, effwave=effwave, pmrangl=pmrangl)

;;; 4. Measure photometry on both star and PSF using astrolib APER routine

phpadu = 3.957                  ; e-/ADU, OSIRIS pre-ship doc.
if N_ELEMENTS(skyval) ne 1 then $
  SKY, im, skyval, skyerr, silent=1-verbose else $
  skyerr = 1.0

if keyword_set(photrad) then begin
    ap=photrad
endif else begin
    photrad=0.5  ; photometry radius (in ")
    ap=ROUND(photrad/pscl)
endelse

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

;;; 6. Display image and PSF

c2 = ROUND([xc+dsz*[-0.5,0.5], yc+dsz*[-0.5,0.5]]) + [0,-1,0,-1]
if c2[0] lt 0 then c2[0:1] = [0,dsz-1]
if c2[1] gt sz0[0]-1 then c2[0:1] = [sz0[0]-dsz,sz0[0]-1]
if c2[2] lt 0 then c2[2:3] = [0,dsz-1]
if c2[3] gt sz0[1]-1 then c2[2:3] = [sz0[1]-dsz,sz0[1]-1]

dexp = 0.3
dim  = im[c2[0]:c2[1],c2[2]:c2[3]] - skyval[0]

if dsz gt psfsz then begin
    c3 = c1-c2+[0,dsz-1,0,dsz-1]
    dpsf = FLTARR(dsz,dsz)
    dpsf[c3[0]:c3[1],c3[2]:c3[3]] = psf
endif else $
  dpsf = psf[c2[0]-c1[0]:c2[1]-c1[0],c2[2]-c1[2]:c2[3]-c1[2]]

; make window active
save=!D.WINDOW
wset, strehl_uval.wids.im

if ((im_s[1] lt 256) or (im_s[2] lt 256)) then begin
    im=(((dim*255^(1/dexp)/peak)>0)^dexp)<255
    tv_im=im[0:im_s[1]-1,0:im_s[2]-1]
    ; rescale the image
    short_size=im_s[1] < im_s[2]
    zoom=256./short_size

    new_im=congrid(tv_im, im_s[1]*zoom, im_s[2]*zoom) 
    TV, new_im
    TVCIRCLE, ap, xc*zoom, yc*zoom
endif else begin
    TV, (((dim*255^(1/dexp)/peak)>0)^dexp)<255
    TVCIRCLE, ap, xc, yc
endelse

wset, strehl_uval.wids.psf_im
if ((im_s[1] lt 256) or (im_s[2] lt 256)) then begin
    im=(((dpsf*255^(1/dexp)/psf_peak)>0)^dexp)<255
    tv_im=im[0:im_s[1]-1,0:im_s[2]-1]
    ; rescale the image
    short_size=im_s[1] < im_s[2]
    zoom=256./short_size

    new_im=congrid(tv_im, im_s[1]*zoom, im_s[2]*zoom) 
    TV, new_im
    TVCIRCLE, ap, xc*zoom, yc*zoom
endif else begin
    TV, (((dim*255^(1/dexp)/peak)>0)^dexp)<255
    TVCIRCLE, ap, xc, yc
endelse

;;; 5. Measure FWHM of star and PSF
DIST_CIRCLE, r, sz1[0], xc-c0[0]-0.5, yc-c0[2]-0.5
psf_fwhm0 = 2*INTERPOL(r[sort(r)],spsf[SORT(r)], psf_peak/2.) ; approximate!

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

;;; 7. Output Strehl and FWHM to display image and/or command line

ftxt=STRING(fwhm,f='(F5.3)')
ftxt1=STRING(psf_fwhm,f='(F5.3)')
stxt=STRING(strehl,f='(F5.3)')
stxt1=STRING(1.0,f='(F5.3)')
;;  dtxt = 'Diffraction limit (' + pmsname + ')'

widget_control, strehl_uval.wids.imfwhm, set_value=ftxt
widget_control, strehl_uval.wids.imstrehl, set_value=stxt

widget_control, strehl_uval.wids.psf_imfwhm, set_value=ftxt1
widget_control, strehl_uval.wids.psf_imstrehl, set_value=stxt1

;cbar = CONGRID(FINDGEN(1,256), 10, ROUND(dsz*0.92))
;TV, (((cbar*255^(1/dexp)/256)>0)^dexp)<255, 2*dsz-10, ROUND(dsz*0.08)

wset, strehl_uval.wids.im_fit
PLOT, r*pscl, sim/peak, ps=1, /noerase, $
  /xsty, xr=[0,fwhm*1.5], ysty=5, yr=[0,1]
AXIS, yaxis=0, /ysty, yr=[0,1]
x = gfit_thresh * FINDGEN(100)/100 * pscl
OPLOT, x, CENTGAUSS(x/pscl,gpar)/peak ;, thick=2
OPLOT, fwhm*[0.5,0.5], [0,0.5]
    
wset, strehl_uval.wids.psf_fit
PLOT, r*pscl, spsf/psf_peak, ps=1, /noerase, $
  /xsty, xr=[0,fwhm*1.5], /ysty, yr=[0,1]
OPLOT, x, CENTGAUSS(x/pscl,psf_gpar)/psf_peak ;, thick=2
OPLOT, psf_fwhm*[0.5,0.5], [0,0.5]

if verbose then begin
    MESSAGE,/info,'FWHM  = ' + STRTRIM(fwhm,2)
    MESSAGE,/info,'Strehl= ' + STRTRIM(strehl,2)
endif

  ; make window active
wset, save

RETURN,strehl

END

