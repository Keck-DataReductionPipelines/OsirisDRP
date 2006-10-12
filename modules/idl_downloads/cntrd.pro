pro cntrd, img, x, y, xcen, ycen, fwhm, SILENT= silent, DEBUG=debug
;+
;  NAME: 
;       CNTRD
;  PURPOSE:
;       Compute the centroid coordinates of a stellar object 
; EXPLANATION:
;       CNTRD uses the DAOPHOT "FIND" centroid algorithm by locating the 
;       position where the X and Y derivatives go to zero.   This is usually a 
;       more "robust"  determination than a "center of mass" or fitting a 2d 
;       Gaussian  if the wings in one direction are affected by the presence
;       of a neighboring star .
;
;  CALLING SEQUENCE: 
;       CNTRD, img, x, y, xcen, ycen, [ fwhm , /SILENT, /DEBUG]
;
;  INPUTS:     
;       IMG - Two dimensional image array
;       X,Y - Scalar or vector integers giving approximate stellar center
;
;  OPTIONAL INPUT:
;       FWHM - floating scalar; Centroid is computed using a box of half
;               width equal to 1.5 sigma = 0.637* FWHM.  CNTRD will prompt
;               for FWHM if not supplied
;
;  OUTPUTS:   
;       XCEN - the computed X centroid position, same number of points as X
;       YCEN - computed Y centroid position, same number of points as Y
;
;       Values for XCEN and YCEN will not be computed if the computed
;       centroid falls outside of the box, or if the computed derivatives
;       are non-decreasing.   If the centroid cannot be computed, then a 
;       message is displayed and XCEN and YCEN are set to -1.
;
;  OPTIONAL OUTPUT KEYWORDS:
;       /SILENT - Normally CNTRD prints an error message if it is unable
;               to compute the centroid.   Set /SILENT to suppress this.
;       /DEBUG - If this keyword is set, then CNTRD will display the subarray
;               it is using to compute the centroid.
;
;  PROCEDURE: 
;       Maximum pixel within distance from input pixel X, Y  determined 
;       from FHWM is found and used as the center of a square, within 
;       which the centroid is computed as the value (XCEN,YCEN) at which 
;       the derivatives of the partial sums of the input image over (y,x)
;       with respect to (x,y) = 0.
;
;  MODIFICATION HISTORY:
;       Written 2/25/86, by J. K. Hill, S.A.S.C., following
;       algorithm used by P. Stetson in DAOPHOT.
;       Allowed input vectors        G. Hennessy       April,  1992
;       Fixed to prevent wrong answer if floating pt. X & Y supplied
;               W. Landsman        March, 1993
;       Convert byte, integer subimages to float  W. Landsman  May 1995
;       Converted to IDL V5.0   W. Landsman   September 1997
;       Better checking of edge of frame David Hogg October 2000
;       Avoid integer wraparound for unsigned arrays W.Landsman January 2001
;       Handle case where more than 1 pixel has maximum value W.L. July 2002
;-      
 On_error,2                          ;Return to caller

 if N_params() LT 5 then begin
        print,'Syntax: CNTRD, img, x, y, xcen, ycen, [ fwhm, /SILENT, /DEBUG ]'
        PRINT,'img - Input image array'
        PRINT,'x,y - Input scalars giving approximate X,Y position'
        PRINT,'xcen,ycen - Output scalars giving centroided X,Y position'
        return
 endif else if N_elements(fwhm) NE 1 then $
      read,'Enter approximate FWHM of image in pixels: ',fwhm

 sz_image = size(img)
 if sz_image[0] NE 2 then message, $
   'ERROR - Image array (first parameter) must be 2 dimensional'

 xsize = sz_image[1]
 ysize = sz_image[2]
 dtype = sz_image[3]              ;Datatype

;   Compute size of box needed to compute centroid

 nhalf =  fix(0.637*fwhm) > 2  ;
 nbox = 2*nhalf+1             ;Width of box to be used to compute centroid
 nhalfbig = nhalf +3
 nbig = nbox + 6        ;Extend box 3 pixels on each side to search for max pixel value
 npts = N_elements(x) 
 xcentroid = fltarr(npts)  & ycentroid = xcentroid
 xcen = float(x) & ycen = float(y)
 ix = fix( x + 0.5 )          ;Central X pixel        ;Added 3/93
 iy = fix( y + 0.5 )          ;Central Y pixel

 for i = 0,npts-1 do begin        ;Loop over X,Y vector

 pos = strtrim(x[i],2) + ' ' + strtrim(y[i],2)

 if ( (ix[i] LT nhalfbig) or ((ix[i] + nhalfbig) GT xsize-1) or $
      (iy[i] LT nhalfbig) or ((iy[i] + nhalfbig) GT ysize-1) ) then begin
     if not keyword_set(SILENT) then message,/INF, $
           'Position '+ pos + ' too near edge of image'
     xcen[i] = -1   & ycen[i] = -1
     goto, DONE
 endif

 bigbox = img[ix[i]-nhalfbig : ix[i]+nhalfbig, iy[i]-nhalfbig : iy[i]+nhalfbig]

;  Locate maximum pixel in 'NBIG' sized subimage 

 mx = max( bigbox)     ;Maximum pixel value in BIGBOX
 mx_pos = where(bigbox EQ mx, Nmax) ;How many pixels have maximum value?
 idx = mx_pos mod nbig          ;X coordinate of Max pixel
 idy = mx_pos / nbig            ;Y coordinate of Max pixel
 if NMax GT 1 then begin        ;More than 1 pixel at maximum?
     idx = round(total(idx)/Nmax)
     idy = round(total(idy)/Nmax)
 endif else begin
     idx = idx[0]
     idy = idy[0]
 endelse

 xmax = ix[i] - (nhalf+3) + idx  ;X coordinate in original image array
 ymax = iy[i] - (nhalf+3) + idy  ;Y coordinate in original image array

; ---------------------------------------------------------------------
; check *new* center location for range
; added by Hogg

 if ( (xmax LT nhalf) or ((xmax + nhalf) GT xsize-1) or $
      (ymax LT nhalf) or ((ymax + nhalf) GT ysize-1) ) then begin
     if not keyword_set(SILENT) then message,/INF, $
           'Position '+ pos + ' moved too near edge of image'
     xcen[i] = -1   & ycen[i] = -1
     goto, DONE
 endif
; ---------------------------------------------------------------------

;  Extract smaller 'STRBOX' sized subimage centered on maximum pixel 

 strbox = img[xmax-nhalf : xmax+nhalf, ymax-nhalf : ymax+nhalf]
 if (dtype NE 4) and (dtype NE 5) then strbox = float(strbox)

 if keyword_set(DEBUG) then begin
       message,'Subarray used to compute centroid:',/inf
       print,strbox
 endif  

 ir = (nhalf-1) > 1 
 dd = indgen(nbox-1) + 0.5 - nhalf
; Weighting factor W unity in center, 0.5 at end, and linear in between 
 w = 1. - 0.5*(abs(dd)-0.5)/(nhalf-0.5) 
 sumc   = total(w)

; Find X centroid

 deriv = shift(strbox,-1,0) - strbox    ;Shift in X & subtract to get derivative
 deriv = deriv[0:nbox-2,nhalf-ir:nhalf+ir] ;Don't want edges of the array
 deriv = total( deriv, 2 )                        ;Sum X derivatives over Y direction
 sumd   = total( w*deriv )
 sumxd  = total( w*dd*deriv )
 sumxsq = total( w*dd^2 )

 if sumxd GT 0 then begin  ;Reject if X derivative not decreasing
   
   if not keyword_set(SILENT) then message,/INF, $
        'Unable to compute X centroid around position '+ pos
   xcen[i]=-1 & ycen[i]=-1
   goto,DONE
 endif 
 dx = sumxsq*sumd/(sumc*sumxd)
 if ( abs(dx) GT nhalf ) then begin    ;Reject if centroid outside box  
   if not keyword_set(SILENT) then message,/INF, $
       'Computed X centroid for position '+ pos + ' out of range'
   xcen[i]=-1 & ycen[i]=-1 
   goto, DONE
 endif

 xcen[i] = xmax - dx    ;X centroid in original array

;  Find Y Centroid

 deriv = shift(strbox,0,-1) - strbox
 deriv = deriv[nhalf-ir:nhalf+ir,0:nbox-2]
 deriv = total( deriv,1 )
 sumd =   total( w*deriv )
 sumxd =  total( w*deriv*dd )
 sumxsq = total( w*dd^2 )
 if (sumxd GT 0) then begin  ;Reject if Y derivative not decreasing
   if not keyword_set(SILENT) then message,/INF, $
        'Unable to compute Y centroid around position '+ pos
        xcen[i] = -1   & ycen[i] = -1
        goto, DONE
 endif

 dy = sumxsq*sumd/(sumc*sumxd)
 if (abs(dy) GT nhalf) then begin ;Reject if computed Y centroid outside box
   if not keyword_set(SILENT) then message,/INF, $
       'Computed X centroid for position '+ pos + ' out of range'
        xcen[i]=-1 & ycen[i]=-1
        goto, DONE
 endif 
 
 ycen[i] = ymax-dy

 DONE: 

 endfor

 return
 end


