;-----------------------------------------------------------------------
; NAME:  minmax_2d
;
; PURPOSE: Find the brightest and darkest pixel in image
;
; INPUT  :  m_img          : image
;
; RETURN VALUE : a 4-vector with [xmin,ymin,xmax,ymax]
;
; STATUS : tested
;
; HISTORY : 27.2.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION minmax_2d, m_img

   if ( NOT bool_is_image ( m_img ) ) then $
      print,'ERROR IN CALL (max_2d.pro): Input is not an image'

   n = size ( m_img )
   dummy = max( m_img, imax, /NAN )
   dummy = min( m_img, imin, /NAN )
   return, [ imin MOD n(1), imin / n(1), imax MOD n(1), imax / n(1) ] 

end
