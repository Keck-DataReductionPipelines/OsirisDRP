;-----------------------------------------------------------------------
; NAME: img_gauss2dfit und IMG_GAUSS2_FUNCT
;
; PURPOSE: Fit a plane to an image. 
;          The image should be greater than 3x3 pixel.
;
; INPUT  :  zzz            : image
;           a              : vector with fit parameter
;           w              : fit weights
;           UNIQUE=UNIQUE  : checks whether there exits a unique
;                            solution (a straight line can not be fitted).
;
; RETURN VALUE : fitted image
;
; STATUS : functionality tested
;
; NOTES : - The structure of this routine is the same as in
;           img_gauss2dfit.pro gauss2dfit.pro in the lib directory.
;           Except that the xy-grid used is the array index grid.
;
;         - This routine failes if the input is perfect because it uses curvefit.
;
;         - The initial values used by curvefit are the median value of
;           the image and zero slope.
;
;         - the fit is done weighted.
;
; HISTORY : 2.3.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

PRO IMG_LIN2_FUNCT, X, A, F, PDER

nx    = long(x(0))
ny    = long(x(1))

xp = dindgen(nx) # replicate(1.,ny)
yp = replicate(1.,nx) # dindgen(ny)

F = reform(a(0) + xp*a(1) + yp*a(2), nx*ny)

if n_params(0) le 3 then return ;need partial?

PDER = FLTARR(long(nx)*long(ny), 3)
PDER[*,0] = 1.0	
pder[*,1] = reform(xp,nx*ny)
pder[*,2] = reform(yp,nx*ny)

END



Function img_lin2dfit2, zzz, a, w, UNIQUE = b_Unique

COMMON APP_CONSTANTS

z = zzz

if ( NOT bool_is_image ( z ) ) then $
   return, error ( 'ERROR IN CALL (img_lin2dfit.pro): Input is not an image' )

if ( NOT bool_dim_match (z,w) ) then $
   return, error ( 'ERROR IN CALL (img_lin2dfit.pro): Weights and Image not compatible in size.' )

s = size(z)
nx = s[1]
ny = s[2]

;z = z * w

n = n_elements(z)
mask_nzero = where( w ne 0., n_nzero)

if ( n_nzero lt 3 ) then $
   return, error ( 'FAILURE (img_lin2dfit.pro): Must have at least 3 valid values to fit a plane' )

; check whether there exist a unique solution

mm = indgen(nx,ny)*0
mm(mask_nzero)  = 1
dummy = where(total(mm,1) gt 0., n1)
dummy = where(total(mm,2) gt 0., n2)

mask1 = indgen(ny+nx-1,ny)*0.
for i=0, ny-1 do mask1(i:i+nx-1,i) = mm(*,i)
dummy = where(total(mask1,2) gt 0., n3)

mask2 = indgen(ny+nx-1,ny)*0.
for i=0, ny-1 do mask2(i:i+nx-1,i) = reverse(mm(*,i))
dummy = where(total(mask2,2) gt 0., n4)

if ( n1 le 1 or n2 le 1 or n3 le 1 or n4 le 1 ) then b_Unique = 0 else b_Unique = 1

; First guess, without XY term...
a = [ median(z(mask_nzero)), 0., 0. ]

ret_val = curvefit( [nx,ny], reform(z, n_elements(z)), reform(w, n_elements(w)), $
	  	    a, itmax=1000, function_name = "IMG_LIN2_FUNCT" )

return, reform(ret_val,nx,ny)

end
