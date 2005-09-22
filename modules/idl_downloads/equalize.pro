

pro equalize_func, x,p,f,pder

   n = size(x)
   np = n_elements(p)

   f = 0.
   pder = dindgen(n(1),np)*0.

   a=0
   b=0

   for i=0, n(1)-1 do begin

      p1 = p(fix(x(i,1))*2:fix(x(i,1))*2+1)
      p2 = p(fix(x(i,3))*2:fix(x(i,3))*2+1)

      d_t =  p1(0) + p1(1)*x(i,0) - p2(0) - p2(1)*x(i,2)

      f = f + d_t*d_t

      pder(i,fix(x(i,1))*2)   = 2. * d_t
      pder(i,fix(x(i,1))*2+1) = x(i,0) * 2. * d_t
      pder(i,fix(x(i,3))*2)   = -2. * d_t
      pder(i,fix(x(i,3))*2+1) = -2. * x(i,2) * d_t

   end 

   m1 = indgen(np/2)*2+1
   m0 = indgen(np/2)*2
   print, 'fit : ', f
   print, 'fit result offset: ', -p(m0)/p(m1)
   print, 'fit result scale: ', 1./p(m1)


end


; pcf_Cube      is the combined cube before averaging, cube index
;               first, then x,y
; pcf_IntFrame  is the combined intframe cube before 'averaging', cube index
;               first, then x,y
; pcb_Valid     is the boolean mask indicating whether pixel is valid, cube index
;               first, then x,y

function equalize, pcf_Cube, pcf_IntFrame, pcb_Valid, DEBUG=DEBUG

   n = size(*pcf_Cube)

   v1 = [0.]
   v2 = [0.]
   l1 = [0]
   l2 = [0]
   s  = [0.]


   ; first run with dim pixels to find a starting value for the offset
   nn = 0L
   for i=0, n(2)-1 do $
      for j=0,n(3)-1 do $
         for ii=0, n(1)-2 do $ 
            for jj=ii+1, n(1)-1 do $
               if ( (*pcb_Valid)(ii,i,j) and (*pcb_Valid)(jj,i,j) and $
                    (*pcf_Cube)(ii,i,j) lt 100. and (*pcf_Cube)(jj,i,j) lt 100. ) then begin

                  v1 = [ v1, (*pcf_Cube)(ii,i,j) ]
                  v2 = [ v2, (*pcf_Cube)(jj,i,j) ]
                  l1 = [ l1, ii ]
                  l2 = [ l2, jj ]
                  s  = [ s, sqrt((*pcf_IntFrame)(ii,i,j)^2 + (*pcf_IntFrame)(jj,i,j)^2) ]
                  nn = nn + 1L

                  if ( ii eq jj ) then print, 'error 1'

               end

   ; define delimiters for fitting
 
   parinfo = replicate({value:0.D, fixed:0, limited:[0,0], $
                        limits:[0.D,0.D] },n(1)*2)

   ; keep plane 0 constant
   ms = indgen(n(1))*2+1
   mo = indgen(n(1))*2
   m = indgen(n(1)*2)
   m ( ms ) = 1.
   m ( mo ) = 0.

   ; first run with fixed scales
   parinfo(0).fixed = 1
   parinfo(1).fixed = 1
   parinfo(*).value = m
   parinfo(ms).fixed = 1

   xx = [[v1(1:*)],[double(l1(1:*))],[v2(1:*)],[double(l2(1:*))]]

   yy = dindgen(nn)*0.
   ss = s(1:*)

   if ( keyword_set( DEBUG ) ) then $
      debug_info, 'DEBUG_INFO (equalize.pro): Doing the minimization now. This can take a while'

   yfit = mpcurvefit(xx, yy, ss, pp, PARINFO=parinfo, FUNCTION_NAME='equalize_func', /quiet, $
                     FTOL=1.e-4, itmax=2000 )

   print, 'fit result offset: ', -pp(mo)/pp(ms)
   print, 'fit result scale: ', 1./pp(ms)

   ; now rerun with starting offsets and variable scales.

   v1 = [0.]
   v2 = [0.]
   l1 = [0]
   l2 = [0]
   s  = [0.]

   nn = 0L
   for i=0, n(2)-1 do $
      for j=0,n(3)-1 do $
         for ii=0, n(1)-2 do $ 
            for jj=ii+1, n(1)-1 do $
               if ( (*pcb_Valid)(ii,i,j) and (*pcb_Valid)(jj,i,j) ) then begin

                  v1 = [ v1, (*pcf_Cube)(ii,i,j) ]
                  v2 = [ v2, (*pcf_Cube)(jj,i,j) ]
                  l1 = [ l1, ii ]
                  l2 = [ l2, jj ]
                  s  = [ s, sqrt((*pcf_IntFrame)(ii,i,j)^2 + (*pcf_IntFrame)(jj,i,j)^2) ]
                  nn = nn + 1L

                  if ( ii eq jj ) then print, 'error 1'

               end

   ; define delimiters for fitting
 
   parinfo = replicate({value:0.D, fixed:0, limited:[0,0], $
                        limits:[0.D,0.D], mpmaxstep:0. },n(1)*2)

   ms = indgen(n(1))*2+1
   mo = indgen(n(1))*2
   m = indgen(n(1)*2)
   m ( ms ) = 1.
   m ( mo ) = 0.

   parinfo(0).fixed = 1
   parinfo(1).fixed = 1
   parinfo(*).value = pp
   parinfo(ms).limits(0) = 0.D
   parinfo(ms).limited(0) = 1
   parinfo(ms).mpmaxstep = 0.01
   parinfo(mo).mpmaxstep = 20.

   xx = [[v1(1:*)],[double(l1(1:*))],[v2(1:*)],[double(l2(1:*))]]

   yy = dindgen(nn)*0.
   ss = s(1:*)

   if ( keyword_set( DEBUG ) ) then $
      debug_info, 'DEBUG_INFO (equalize.pro): Doing the minimization now. This can take a while'

   yfit = mpcurvefit(xx, yy, ss, pp, PARINFO=parinfo, FUNCTION_NAME='equalize_func', /quiet, $
                     FTOL=1.e-6, itmax=2000 )

   print, 'fit result offset: ', -pp(mo)/pp(ms)
   print, 'fit result scale: ', 1./pp(ms)









   if ( keyword_set( DEBUG ) ) then $
      debug_info, 'DEBUG_INFO (equalize.pro): Done with the minimization'

   return, pp

end
