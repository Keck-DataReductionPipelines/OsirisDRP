;+
; NAME:
;  skysclim
; PURPOSE:
;  Compute stretch range for a hard stretch on the background in an image.
; DESCRIPTION:
; CATEGORY:
;  Image display
; CALLING SEQUENCE:
;  skysclim,image,lowval,hival,meanval,sigma
; INPUTS:
;  image - 2-d image to compute stretch range for.
; OPTIONAL INPUT PARAMETERS:
; KEYWORD INPUT PARAMETERS:
; OUTPUTS:
;  lowval - Low DN value for sky stretch
;  hival  - High DN value for sky stretch
; KEYWORD OUTPUT PARAMETERS:
; COMMON BLOCKS:
; SIDE EFFECTS:
; RESTRICTIONS:
; PROCEDURE:
; MODIFICATION HISTORY:
;  96/01/07 - Marc W. Buie
;-
pro skysclim,image,lowval,hival,meanval,sigma
   idx=randomu(seed,min([601,n_elements(image)]))*(n_elements(image)-1)
;   sub=image[idx]
;   s=sort(sub)
;   subs=sub[s]
;   meanval=subs[50]
;   sigma=stdev(subs[20:80])

	; MDP replace with call to sky...
   ;robomean,image[idx],2.0,0.5,meanval,dummy,sigma

	sky, image[idx], meanval, sigma

   lowval=meanval-3.0*sigma
   hival=meanval+5.0*sigma

end;
