
; x(*,0) = x
; x(*,1) = y
; x(*,2) = l


pro equalize_func, x,p,f,pder

   n = size(x)

   f = dindgen(n(1))*0.

   for i=0, n(1)-1 do begin

      ppp = p(x(i,2)*3:x(i,2)*3+2)

      f(i) = ppp(0) + ppp(1)*x(i,0) + ppp(2)*x(i,1)

   end

end


; pcf_Cube      is the combined cube before averaging, cube index
;               first, then x,y
; pcf_IntFrame  is the combined intframe cube before 'averaging', cube index
;               first, then x,y
; pcb_Valid     is the boolean mask indicating whether pixel is valid, cube index
;               first, then x,y

function equalize, pcf_Cube, pcf_IntFrame, pcb_Valid, DEBUG=DEBUG

   n = size(*pcf_Cube)

   x = [0.]
   y = [0.]
   s = [0.]
   l = [0.]
   f = [0.]

   for i=0, n(2)-1 do begin
      for j=0,n(3)-1 do begin
   
         ; check if number of valid pixels in
         ; an overlay area is greater than 1 
         n_Valid = total((*pcb_Valid)(*,i,j))
         if ( n_Valid gt 1 ) then begin

            for k=0, n(1)-1 do begin

               if ( (*pcb_Valid)(k,i,j) ) then begin

                  x = [x,double(i)]
                  y = [y,double(j)]
                  l = [l,double(k)]
                  s = [s,(*pcf_IntFrame)(k,i,j)]
                  f = [f,(*pcf_Cube)(k,i,j)]

               end

            end

         end 

      end

   end


   pp = dindgen(n(1)*3)*0.

   xx = [[x(1:*)],[y(1:*)],[l(1:*)]]
   yy = f(1:*)
   ss = s(1:*)

   if ( keyword_set( DEBUG ) ) then $
      debug_info, 'DEBUG_INFO (equalize.pro): Doing the minimization now. This can take a while'

   yfit = mpcurvefit(xx, yy, ss, pp,  FUNCTION_NAME='equalize_func', /noderivative, /quiet )

   if ( keyword_set( DEBUG ) ) then $
      debug_info, 'DEBUG_INFO (equalize.pro): Done with the minimization'

   print, pp

   return, yfit

end
