pro xyz2adl, x, y, z, astr, a, d, lambda, waveunits=waveunits
;+
; NAME:
;     XYZ2ADL
;
;     Like XY2AD, but for IFU data cubes containing 2 spatial and 1 spectral
;     dimension!
;
; PURPOSE:
;     Compute R.A., Dec, and Wavelength from X, Y, and Z and a FITS astrometry structure
; EXPLANATION:
;     The astrometry structure must first be extracted by EXTAST from a FITS
;     header.   The offset from the reference pixel is computed and the CD 
;     matrix is applied.     If distortion is present then this is corrected.
;     If a WCS projection (Calabretta & Greisen 2002, A&A, 395, 1077) is 
;     present, then the procedure WCSXY2SPH is used to compute astronomical
;     coordinates.    Angles are returned in  degrees.
;   
;
; CALLING SEQUENCE:
;     XYZ2ADL, x, y, z, astr, a, d, lambda
;
; INPUTS:
;     X     - row position in pixels, scalar or vector
;     Y     - column position in pixels, scalar or vector
;     Z     - slice position in pixels, scalar or vector
;           X,Y,Z should be in the standard IDL convention (first pixel is
;           0), and not the FITS convention (first pixel is 1). 
;     ASTR - astrometry structure, output from EXTAST3 procedure containing:
;        .CD   -  3 x 3 array containing the astrometry parameters 
;               in DEGREES/PIXEL                                   
;        .CDELT - 3 element vector giving physical increment at reference pixel
;        .CRPIX - 3 element vector giving X and Y coordinates of reference pixel
;               (def = NAXIS/2)
;        .CRVAL - 3 element vector giving R.A. and DEC of reference pixel 
;               in DEGREES
;        .CTYPE - 3 element vector giving projection types 
;        .LONGPOLE - scalar longitude of north pole
;        .LATPOLE - scalar giving native latitude of the celestial pole
;        .PV2 - Vector of projection parameter associated with latitude axis
;             PV2 will have up to 21 elements for the ZPN projection, up to 3
;             for the SIN projection and no more than 2 for any other
;             projection
;        .DISTORT - Optional substructure specifying distortion parameters
;                  
;
; OUTPUT:
;     A - R.A. in DEGREES, same number of elements as X and Y
;     D - Dec. in DEGREES, same number of elements as X and Y
;     Lambda - wavelength in whatever units CUNITx is
;
; OPTIONAL KEYWORD OUTPUT:
;     waveunits=	String giving units for wavelength axis, from header CUNIT
;     				keyword.
;
; RESTRICTIONS:
;       Note that all angles are in degrees, including CD and CRVAL
;       Also note that the CRPIX keyword assumes an FORTRAN type
;       array beginning at (1,1), while X and Y give the IDL position
;       beginning at (0,0).   No parameter checking is performed.
;
; NOTES:
;	   This routine automatically determines which axes are wavelength and
;	   which axes are RA and Dec. 
;
;	   The Wavelength axis MUST be linear; no other axes types are supported.
;	   The RA and Dec axes can be anything that will work in regular XY2AD.
;	   
;      
; PROCEDURES USED:
;       TAG_EXIST(), WCSXY2SPH
; REVISION HISTORY:
; 	Written by M. Perrin, UC Berkeley, based on XY2AD.PRO as of July 2, 2007.
;       
;- 
 compile_opt idl2
 if N_params() LT 6 then begin
        print,'Syntax -- XYZ2ADL, x, y, z, astr, a, d, lambda'
        return
 endif
 radeg = 180.0d/!DPI                  ;Double precision !RADEG

  ; Which axis is which? Make sure all indices are scalars.

  ; allowable spectral coordinate type codes. Griesen et al. 2006 Table 1
  wave_axes_types = ["FREQ", "ENER", "WAVN", "VRAD", "WAVE", "VOPT", "ZOPT", $
  	"AWAV", "VELO", "BETA"]
  for i = 0,n_elements(wave_axes_types)-1 do begin
  	axis_lambda = where( strmid(astr.ctype,0,4) eq wave_axes_types[i], lambdact)
	if lambdact eq 1 then break
  endfor
;  ; Check for NONSTANDARD "LAMBDA" axis type produced by Gemini GMOS IRAF
;  ; pipeline
;  if lambdact eq 0 then begin
;	  axis_lambda = where( strmid(astr.ctype,0,6) eq "LAMBDA", lambdact)
;	  if lambdact eq 1 then astr.ctype[axis_lambda] = "WAVE" ; make it standard!
;  endif
  ; if still nothing, then complain
  if lambdact eq 0 then message, "Did not find unique wavelength axis!" else axis_lambda=axis_lambda[0]
	  
  ; now find spatial axes.
  axis_ra = where( strmid(astr.ctype,0,4) eq "RA--", ract)
  if ract ne 1 then message, "Did not find unique wavelength axis!" else axis_ra=axis_ra[0]
  axis_dec = where( strmid(astr.ctype,0,4) eq "DEC-", decct)
  if decct ne 1 then message, "Did not find unique wavelength axis!" else axis_dec=axis_dec[0]


 cd = astr.cd
 crpix = astr.crpix;[[axis_ra, axis_dec]]
 cdelt = astr.cdelt;[[axis_ra, axis_dec]]
 ctype = astr.ctype
 crval = astr.crval

 for i=0,2 do if cdelt[i] NE 1.0 then cd[i,*] *= cdelt[i]

 xdif = x - (crpix[0]-1)            
 ydif = y - (crpix[1]-1)
 zdif = z - (crpix[2]-1)
 
 if tag_exist(astr,'DISTORT') then begin
	 message, "Distortion not supported in XYZ2ADL!"
 endif

 xsi0 = cd[0,0]*xdif + cd[0,1]*ydif + cd[0,2]*zdif   ;Can't use matrix notation, in
 eta0 = cd[1,0]*xdif + cd[1,1]*ydif + cd[1,2]*zdif   ;case X and Y are vectors
 phi0 = cd[2,0]*xdif + cd[2,1]*ydif + cd[2,2]*zdif   

xsiar = [ptr_new(xsi0),ptr_new(eta0),ptr_new(phi0)] ; this allows arbitrary shapes for x,y,z arrays
													; remember to clean up these
													; pointers!
													
xsi = *(xsiar[axis_ra])
eta = *(xsiar[axis_dec])
phi = *(xsiar[axis_lambda])
ptr_free,xsiar

 ;------ compute wavelength axis ------
 ; NOTE THAT ONLY LINEAR WAVELENGTH IS ASSUMED HERE!
 ; This is NOWHERE near the full glory/gory possibilities
 ; allowed in the FITS spectral WCS standard.
 algo = strcompress(strmid(astr.ctype[axis_lambda],4,4),/remove_all)
 if algo ne '' then message, "Nonlinear wavelength axes algorithms not yet supported!"
 lambda = phi + crval[axis_lambda]
 waveunits = astr.cunit[axis_lambda] ; microns, nm, etc.

 ;------ compute spatial axes ------
 coord = strmid(ctype,0,4)
 
 ; TODO update the following for datacubes?
 reverse = ((coord[0] EQ 'DEC-') and (coord[1] EQ 'RA--')) or $
           ((coord[0] EQ 'GLAT') and (coord[1] EQ 'GLON')) or $
           ((coord[0] EQ 'ELAT') and (coord[1] EQ 'ELON'))
 if reverse then begin
     crval = rotate(crval,2)
     temp = xsi & xsi = eta & eta = temp
 endif

 if strmid(ctype[0],4,1) EQ '-' then begin
 WCSXY2SPH, xsi, eta, a, d, CTYPE = ctype[[axis_ra, axis_dec]], PV2 = astr.pv2, $
        LONGPOLE = astr.longpole, CRVAL = crval[[axis_ra, axis_dec]], LATPOLE = astr.latpole
 endif else begin
         a = crval[axis_ra] +xsi & d = crval[axis_dec] + eta	
 endelse
 return
 end
