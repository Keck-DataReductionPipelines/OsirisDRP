function deadpixcor, image, pixmap,silent=silent

;+
; NAME:
; 	DEADPIXCOR()
; PURPOSE:
; 	corrects dead pixels by nearest neighbour averaging
; 	iterative scheme for dead pixel clumps
;
; CALLING SEQUENCE:
;	result = DEADPIXCOR( IMAGE , DEADPIXELS , SILENT = SILENT )
;
; INPUTS:
;	IMAGE      -- 2D raw image
;	DEADPIXELS -- 2D image containing dead pixels
;		      = 1 for bad pixel
;		      = 0 for good pixel
;
; OPTIONAL KEYWORDS INPUTS:
; 	SILENT -- if not set, produces statistics on standard output
;
; OUTPUTS:
;	result = 2D image where every pixel that was set to zero 
;		 in DEADPIXELS is unchanged and dead pixels that 
;		 were set to 1 in DEADPIXELS have been replaced by
;		 nearest neighbour averaging
;
; NOTES:
;	Depending on how the dead pixel map is computed, the edges 
;	(and especially corners) of images can often be considered
;	dead pixels. Because of the iterative scheme, this can lead
;	to artefacts in the corners of images.
;;
; REVISION HISTORY:
;	Written Francois Rigaut, CFHT, 1995
;-


bmap=pixmap
gmap=1-bmap
im=float(image*gmap)

while (total(bmap) ne 0) do begin
    if not keyword_set(silent) then $ 
      print,'number of bad pixels to average:',total(bmap)
    
    dpix=((shift(gmap,1,0)+shift(gmap,-1,0)+shift(gmap,0,-1)+ $
           shift(gmap,0,1)) ne 0)*bmap*(shift(im,1,0)+shift(im,-1,0)+ $
                    shift(im,0,-1)+shift(im,0,1))/(shift(gmap,1,0)+ $
                    shift(gmap,-1,0)+shift(gmap,0,-1)+shift(gmap,0,1)+1e-15)

    bmap=(shift(gmap,1,0)+shift(gmap,-1,0)+shift(gmap,0,-1)+ $
          shift(gmap,0,1)) eq 0
    gmap=1-bmap
    im=im+dpix
endwhile

return,im
end

