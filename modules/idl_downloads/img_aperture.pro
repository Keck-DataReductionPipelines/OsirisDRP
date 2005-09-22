;-----------------------------------------------------------------------
; NAME:  img_aperture
;
; PURPOSE: Calculates an aperture mask on subpixel basis.
;          The oversampling is done with a factor of 50.
;
; INPUT :  nx, ny   : size of the mask
;          cx, cy   : center of aperture
;          rad      : radius of the aperture in pixel
;          [/NOSUB] : the aperture mask is not calculated on subpixel
;                     basis and returned as a byte mask 
;
;
; ALGORITHM:  - if pixel (that means all corners) is completely
;               within the chosen aperture -> weight = 1
;             - if less than 4 corners of a skypixel are within
;               the aperture the fractional area is the weight
;             - if no corner of a skypixel is within the aperture
;                  - if the center is within the
;                    aperture the weight is the fractional area of that pixel
;                  - if the center is not within 
;                    the aperture the weight is 0.
;
; OUTPUT : returns an subpixel aperture mask
;
; NOTES : - The values of the mask are between 0 (invalid) and 1
;           (fully valid)
;
; STATUS : tested
;
; HISTORY : 5.3.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

function img_aperture, nx, ny, cx, cy, rad, NOSUB=NOSUB

   if ( keyword_set ( NOSUB ) ) then begin

      m_Weights = bytarr(nx,ny)
      dist_circle, m_Mask, [nx,ny], cx, cy
      v_Mask = where ( m_Mask gt rad, n_dist )
      if ( n_dist gt 0 ) then $
         m_Weights(v_Mask) = 1

   endif else begin

      m_Weights = fltarr(nx,ny)
      for i=0, nx-1 do $
         for j=0, ny-1 do begin
            ; check for each pixel how many corners of the pixel are within
            ; rad from the center
            dummy = where ( [sqrt( (float(i)-0.5-cx)^2. + (float(j)-0.5-cy)^2. ), $
                             sqrt( (float(i)-0.5-cx)^2. + (float(j)+0.5-cy)^2. ), $
                             sqrt( (float(i)+0.5-cx)^2. + (float(j)-0.5-cy)^2. ), $
                             sqrt( (float(i)+0.5-cx)^2. + (float(j)+0.5-cy)^2. ) ] $
                             le rad, n_corner )
            if ( n_corner eq 4 ) then $
               ; all corners are within rad from the center
               md_Weights(i,j) = 1. $
            else begin  
                    if ( ( n_corner gt 0 ) or ( cx ge (float(i)-0.5) and cx lt (float(i)+0.5) and $
                                                cy ge (float(j)-0.5) and cy lt (float(j)+0.5) ) ) then begin
                       ; not all corners are within rad from the center -> Subsampling
                       sub_dist = findgen(50,50)*0.
                       for ii=0, 49 do $
                          for jj=0, 49 do $
                              sub_dist(ii,jj) = sqrt( (float(ii/50.)+float(i)-0.5-cx)^2. + $
                                                      (float(jj/50.)+float(j)-0.5-cy)^2. )
                       dummy = where(sub_dist le rad, nn)
                       md_Weights(i,j) = float(nn) * 0.0004
                    end
                 end
         end
   end


   return, m_Weights

end
