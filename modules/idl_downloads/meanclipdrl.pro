FUNCTION MEANCLIPDRL, Image, CLIPSIG=clipsig, MAXITER=maxiter, $
    CONVERGE_NUM=converge_num, VERBOSE=verbose, SUBS=subs
;
; Like regular meanclip, but it returns mean as a function would do
;
;+
; NAME:
;	MEANCLIP
;
; PURPOSE:
;	Computes an iteratively sigma-clipped mean on a data set
; EXPLANATION:
;       Clipping is done about median, but mean is returned.
;       Called by SKYADJ_CUBE
;
; CATEGORY:
;	Statistics
;
; CALLING SEQUENCE:
;	MEANCLIP, Data, Mean, Sigma
;
; INPUT POSITIONAL PARAMETERS:
;	Data: 	  Input data, any numeric array
;	
; OUTPUT POSITIONAL PARAMETERS:
;       Mean:     N-sigma clipped mean.
;       Sigma:    Standard deviation of remaining pixels.
;
; INPUT KEYWORD PARAMETERS:
;       CLIPSIG:  Number of sigma at which to clip.  Default=3
;	MAXITER:  Ceiling on number of clipping iterations.  Default=5
;       CONVERGE_NUM:  If the proportion of rejected pixels is less
;           than this fraction, the iterations stop.  Default=0.02, i.e.,
;           iteration stops if fewer than 2% of pixels excluded.
;       /VERBOSE:  Set this flag to get messages.
;
; OUTPUT KEYWORD PARAMETER:
;       SUBS:     Subscript array for pixels finally used.
;
;
; MODIFICATION HISTORY:
; 	Written by:	RSH, RITSS, 21 Oct 98
;       20 Jan 99 - Added SUBS, fixed misplaced paren on float call, 
;                   improved doc.  RSH
;-

IF n_params(0) LT 1 THEN BEGIN
    print, 'CALLING SEQUENCE:  MEANCLIP, Image, Mean, Sigma'
    print, 'KEYWORD PARAMETERS:  CLIPSIG, MAXITER, CONVERGE_NUM, ' $
        + 'VERBOSE, SUBS'
    RETALL
ENDIF

prf = 'MEANCLIP:  '

verbose = keyword_set(verbose)
IF n_elements(maxiter) LT 1 THEN maxiter = 5
IF n_elements(clipsig) LT 1 THEN clipsig = 3
IF n_elements(converge_num) LT 1 THEN converge_num = 0.02

subs = where(finite(image),ct)
iter=0
REPEAT BEGIN
    skpix = image[subs]
    iter = iter + 1
    lastct = ct
    medval = median(skpix)
    sig = stdev(skpix)
    wsm = where(abs(skpix-medval) LT clipsig*sig,ct)
    IF ct GT 0 THEN subs = subs[wsm]
ENDREP UNTIL (float(abs(ct-lastct))/lastct LT converge_num) $
          OR (iter GT maxiter)
mom = moment(image[subs])
mean = mom[0]
sigma = sqrt(mom[1])
IF verbose THEN BEGIN
    print, prf+strn(clipsig)+'-sigma clipped mean'
    print, prf+'Mean computed in ',iter,' iterations'
    print, prf+'Mean = ',mean,',  sigma = ',sigma
ENDIF

RETURN,mean
END
