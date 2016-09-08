;+
; NAME:
;	OSIRISPUPIL_QL2
;
; PURPOSE:
;	Calculate OSIRIS pupil image
;
; EXPLANATION:
;	Calculate pupil image for any pupil stop, pupil angle, and image
;	scale, for use by OSIRISPSF in determining theoretical PSF.
;
; CALLING SEQUENCE:
;	result = OSIRISPUPIL( [NPIX=, DU=, PMRANGL= ])
;
; INPUTS:
;	none.
;
; OUTPITS:
;	result = binary image of pupil
;
; OPTIONAL INPUT KEYWORDS:
;	NPIX = size of pupil image, in pixels
;
;	DU = platescale of pupil image, in m/pixel at the telescope primary
;
;	PMRANGL = pupil drive's angular position (for rotated pupil images).
;	  NOT TESTED.  There could be an offset and/or a sign flip needed!
;
; EXAMPLE:
;	pupil = OSIRISPUPIL(npix=512, du=0.05, PMSNAME='open')
;
; ERROR HANDLING:
;	none
;
; RESTRICTIONS:
;	none
;
; NOTES:
;	The dimentions are based on Keck KAON 253 and the OSIRIS pupil
;	  stop drawings.
;
; PROCEDURES USED:
;	none
;
; MODIFICATION HISTORY:
;	Original writen May 2004, A. Bouchez, W.M. Keck Observatory
;	Modification written March 2005, M. McElwain, UCLA
;           - adapted to OSIRIS
;-
FUNCTION OSIRISPUPIL_QL2, NPIX=npix, DU=du, PMRANGL=pmrangl

  if not KEYWORD_SET(npix) then npix = 256
  if not KEYWORD_SET(du) then $
    du = 2.124e-6 / (npix * 0.00994 / 206265)
  if not KEYWORD_SET(pmrangl) then pmrangl = 0.

  ; Define the pupil stops to be open
  pmsname = 'open'

;;; 1. Define dimentions of pupil in inches based on engineering drawings.

  pmsstr = STRUPCASE(STRCOMPRESS(pmsname,/remove_all))
  case pmsstr of
    'OPEN':     d = [0.49D, 0.42, 0.350, 0.280, 0., 0.]
    'LARGEHEX': d = [0.479D, 0.4090, 0.3390, 0.2690, 0.1170, 0.0020]
    'MEDIUMHEX':d = [0.471D, 0.4010, 0.3310, 0.2610, 0.1250, 0.0030]
    'SMALLHEX': d = [0.451D, 0.3810, 0.3110, 0.2410, 0.1450, 0.0030]
    'INCIRCLE': d = [0.392D, 0.1325, 0.0030]
    else: begin
      MESSAGE,/info,'pmsname '+pmsstr+' not recognized.  Using default=Open'
      d = [0.479D, 0.4090, 0.3390, 0.2690, 0.1170, 0.0020]
    end
  endcase
  pms_pscl = 0.0899D			; m/inch (derived in KAON 253)

  pupil = BYTARR(npix,npix)
  DIST_CIRCLE,r,npix,npix/2-0.5,npix/2-0.5

;;; 1. Create INCIRCLE pupil

  if pmsstr eq 'INCIRCLE' then begin
    w = WHERE(r*du*pms_pscl lt d[0] and $
              r*du*pms_pscl gt d[1])
    if w[0] ne -1 then pupil[w] = 1B

    v = [[-1*d[2],0], [d[2],0], [d[2],d[0]*1.1], $
         [-1*d[2],d[0]*1.1], [-1*d[2],0]]
    ang = (60 * DINDGEN(6) + pmrangl) * !dtor
    for i=0,5 do begin
      rmat = [[-1*SIN(ang[i]), COS(ang[i])], $
              [   COS(ang[i]), SIN(ang[i])]]
      rv = npix/2 + (rmat#v / (du * pms_pscl))
      w = POLYFILLV(rv[1,*],rv[0,*],npix,npix)
      if w[0] ne -1 then pupil[w] = 0B
    endfor
  endif else begin

;;; 2. For others, compute vertices for one sextant (in mm)

    s = (d[0]-d[1])/COS(30*!dtor)	; length of segment edge
    v0 = [[ d[5], d[4]/COS(30*!dtor) - d[5]*SIN(30*!dtor) ], $
          [ d[5], d[2]/COS(30*!dtor) + d[5]*SIN(30*!dtor) ], $
          [ s*COS(30*!dtor), d[2]/COS(30*!dtor) +  s*SIN(30*!dtor)], $
          [ 2*s*COS(30*!dtor), d[2]/COS(30*!dtor) ], $
          [ 3*s*COS(30*!dtor), d[2]/COS(30*!dtor) + s*SIN(30*!dtor)], $
          [ d[0]*SIN(30*!dtor), d[0]*COS(30*!dtor)], $
          [ d[4]*SIN(30*!dtor), d[4]*COS(30*!dtor)], $
          [ d[5], d[4]/COS(30*!dtor) - d[5]*SIN(30*!dtor) ]]
    v1 = v0 * REBIN([-1,1],2,8)		; mirror image across Y axis

;;; 3. Fill in pupil image (dimentions in pixels)
 
    ang = (60 * DINDGEN(6) + pmrangl) * !dtor 
    for i=0,5 do begin
      rmat = [[-1*SIN(ang[i]), COS(ang[i])], $
              [   COS(ang[i]), SIN(ang[i])]]
      rv0 = npix/2 + (rmat#v0 / (du * pms_pscl))
      rv1 = npix/2 + (rmat#v1 / (du * pms_pscl))
      inpupil = POLYFILLV(rv0[1,*],rv0[0,*],npix,npix)
      if inpupil[0] ne -1 then pupil[inpupil] = 1B
      inpupil = POLYFILLV(rv1[1,*],rv1[0,*],npix,npix)
      if inpupil[0] ne -1 then pupil[inpupil] = 1B
    endfor

    if pmsstr eq 'OPEN' then begin			; cut out circular secondary
      w = WHERE(r*du lt 1.30)			;   diameter = 2.60m
      if w[0] ne -1 then pupil(w) = 0B
    endif
  endelse

RETURN,pupil
END
