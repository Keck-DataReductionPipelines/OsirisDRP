; x : 1-dim vector of x-coords
; y : 1-dim vector of y-coords

function sfit_surface, x, y, k


   n_Dims = size(k)
   n = n_Dims(1)-1
   m = n_Dims(2)-1
   
   v_Res = fltarr(n_elements(x))

   for i=0, n do $
      for j=0, m do $
         v_Res = v_Res + k(j,i) * ( x^double(i) *  y^double(j) )

   return, v_Res

end
