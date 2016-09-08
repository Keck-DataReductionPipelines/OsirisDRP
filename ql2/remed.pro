FUNCTION	REMED,image,xsz,ysz

;;; Like REBIN(), but compute median of pixels instead.
;;; Create AHB Apr 2004.

  sz = (SIZE(image))(1:2)
  xr = sz[0]/xsz
  yr = sz[1]/ysz
  medim = REBIN(image,xsz,ysz)	; will crash here if not integer factor!
  for i=0,xsz-1 do $
    for j=0,ysz-1 do $
      medim[i,j] = MEDIAN(image[i*xr:(i+1)*xr-1,j*yr:(j+1)*yr-1])

RETURN,medim
END
