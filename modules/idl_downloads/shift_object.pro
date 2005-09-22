
;-----------------------------------------------------------------------
; NAME:  shift_object
;
; PURPOSE: Shift image or cube on subpixel basis. The x-, y-shift must be
;          less than 1
;
; INPUT :  o       : input variable
;          x_shift : 0 <= shift in x-direction < 1
;          y_shift : 0 <= shift in y-direction < 1
;          cubic   : same as in interpolate.pro
;          missing : same as in interpolate.pro
;
; OUTPUT : shifted image or cube
;
; STATUS : untested
;
; HISTORY : 27.3.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

function shift_object, o, x_shift, y_shift, cubic=cubic, missing=missing

   ; do nothing if shift is less than 0.01 pixel
   if ( abs(x_shift) lt 0.01 and abs(y_shift) lt 0.01 ) then return, o

   s  = size(o)
   Nx = s(1)
   Ny = s(2)
   if (s(0) eq 2) then Nz = 1 else Nz = s(3)

   so = dindgen(Nx,Ny,Nz)
   xo = dindgen(Nx)
   yo = dindgen(Ny)

   for i=0,Nz-1 do begin
      x = xo - x_shift
      y = yo - y_shift
      if ( keyword_set(missing) ) then $
         so(0,0,i) = interpolate ( o(*,*,i), x, y, /grid, cubic=keyword_set(cubic)?cubic:0., missing=missing ) $
      else $
         so(0,0,i) = interpolate ( o(*,*,i), x, y, /grid, cubic=keyword_set(cubic)?cubic:0. )
   end

   return, so

end

