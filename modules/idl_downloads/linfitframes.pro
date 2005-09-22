
FUNCTION LinFit, x, y, $
	chisqr = chisqr, Double = Double, prob = prob, $
	sig_ab = sig_ab, sigma = sigma, $
	COVAR=covar,YFIT=yfit, MEASURE_ERRORS=measure_errors, $
	SDEV = sdevIn  ; obsolete keyword (still works)

COMPILE_OPT idl2

  ON_ERROR, 2

  TypeX = SIZE(X)
  TypeY = SIZE(Y)
  nX = TypeX[TypeX[0]+2]
  nY = TypeY[TypeY[0]+2]

  if nX ne nY then $
    MESSAGE, "X and Y must be vectors of equal length."

  ;If the DOUBLE keyword is not set then the internal precision and
  ;result are identical to the type of input.
  if (N_ELEMENTS(double) GT 0) THEN double=KEYWORD_SET(double) ELSE $
    Double = (TypeX[TypeX[0]+1] eq 5 or TypeY[TypeY[0]+1] eq 5)
  one = double ? 1d : 1.0

  isSdev = N_ELEMENTS(sdevIn) GT 0
  isMeasure = N_ELEMENTS(measure_errors) GT 0
  IF (isSdev OR isMeasure) THEN BEGIN
    IF (isSdev AND isMeasure) THEN $
  	  MESSAGE,'Conflicting keywords SDEV and MEASURE_ERRORS.'
    sdev = isMeasure ? measure_errors : sdevIn
    nsdev = N_ELEMENTS(sdev)
    IF (nsdev NE nX) THEN MESSAGE, $
      'MEASURE_ERRORS must have the number of elements as X and Y.'
  ENDIF ELSE BEGIN
    sdev = one
    nsdev = 0
  ENDELSE


; for explanation of constants see Numerical Recipes sec. 15-2
  if nsdev eq nX then begin ;Standard deviations are supplied.
	wt = one/sdev^2
	ss = TOTAL(wt)
	sx = TOTAL(wt * x)
	sy = TOTAL(wt * y)
    t =  (x - sx/ss) / sdev
    b = TOTAL(t * y / sdev)
  endif else begin
	ss = nX
	sx = TOTAL(one * x)
	sy = TOTAL(one * y)
    t = x - sx/ss
    b = TOTAL(t * y)
  endelse

  st2 = TOTAL(t^2)
  IF (NOT double) THEN BEGIN
	ss = FLOAT(ss)
	sx = FLOAT(sx)
	sy = FLOAT(sy)
	st2 = FLOAT(st2)
	b = FLOAT(b)
  ENDIF

; parameter estimates
  b = b / st2
  a = (sy - sx * b) / ss

; error estimates
  sdeva = SQRT((1.0 + sx * sx / (ss * st2)) / ss)
  sdevb = SQRT(1.0 / st2)
  covar = -sx/(ss*st2)
  covar = [[sdeva^2, covar], [covar, sdevb^2]]

  yfit = b*x + a

  if nsdev ne 0 then begin
    chisqr = TOTAL( ((y - yfit) / sdev)^2, Double = Double )
    if Double eq 0 then chisqr = FLOAT(chisqr)
    prob = 1 - IGAMMA(0.5*(nX-2), 0.5*chisqr)
  endif else begin
    chisqr = TOTAL( (y - yfit)^2, Double = Double )
    if Double eq 0 then chisqr = FLOAT(chisqr)
    prob = chisqr * 0 + 1 ;Make prob same type as chisqr.
    sdevdat = SQRT(chisqr / (nX-2))
    sdeva = sdeva * sdevdat
    sdevb = sdevb * sdevdat
  endelse

  sigma = (sig_ab = [sdeva, sdevb])

  RETURN, [a, b]

END





FUNCTION lin_fit_cube, v3X, v3Y, no_const

   ssx = size(v3X)
   ssy = size(v3Y)
   if ( ssx[0] ne 3 ) then print, 'ERROR (lin_fit_cube.pro): 1. cube not a cube'
   if ( ssy[0] ne 3 ) then print, 'ERROR (lin_fit_cube.pro): 2. cube not a cube'
   
   if ( ssx[1] ne ssy[1] or ssx[2] ne ssy[2] or ssx[3] ne ssy[3] ) then $
      print, 'ERROR (lin_fit_cube.pro): dimensions of 1. and 2. cube not matching'

   if ( NOT keyword_set ( no_const ) ) then begin

      sx  = findgen(ssx[1],ssx[2])*0.
      sxx = findgen(ssx[1],ssx[2])*0.
      sxy = findgen(ssx[1],ssx[2])*0.
      sy  = findgen(ssx[1],ssx[2])*0.

      for i=0,ssx[3]-1 do begin
         sx  = sx + v3X[*,*,i]
         sy  = sy + v3Y[*,*,i]
         sxx = sxx + v3X[*,*,i]*v3X[*,*,i]
         sxy = sxy + v3X[*,*,i]*v3Y[*,*,i]
      end
   
      s = ssx[3]
      d = (s*sxx)-sx*sx 
      a = (sxx*sy - sx*sxy)/d
      b = (s*sxy-sx*sy)/d

      dy = findgen(ssx[1],ssx[2])*0.
      for i=0,ssx[3]-1 do dy = dy + (a + b * v3X[*,*,i] - v3Y[*,*,i])^2

      sb = sqrt(s*dy/((s-2)*d))
      sa = sqrt(sxx/(s-2)*dy/d)

      r = findgen ( ssx[1], ssx[2], 4 ) * 0.
      r[*,*,0] = a
      r[*,*,1] = b
      r[*,*,2] = sa
      r[*,*,3] = sb

   endif else begin
   
      sxx = findgen(ssx[1],ssx[2])*0.
      sxy = findgen(ssx[1],ssx[2])*0.

      for i=0,ssx[3]-1 do begin
         sxx = sxx + v3X[*,*,i]*v3X[*,*,i]
         sxy = sxy + v3X[*,*,i]*v3Y[*,*,i]
      end

      r = findgen ( ssx[1], ssx[2] ) * 0.
      r = sxy/sxx

   end

   return, r

END
