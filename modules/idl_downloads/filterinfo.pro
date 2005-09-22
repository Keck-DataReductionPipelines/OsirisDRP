Function filterinfo,filter=filter
; For a given filter, this routine calculates wavelength at the
; pupil image location, dispersion, min/max wavelengths, and 
; min/max pixel coordinates of left/right edges of spectra.
; Using J. Larkin's input for exact dispersion as of 2004 June.
;
; Inseok Song (2004)
;=============================================================================
  filter_template = { VERSION:1.00000, DATASTART:1L, DELIMITER:' ', $
      MISSINGVALUE:!VALUES.F_NAN, COMMENTSYMBOL:'#', FIELDCOUNT:4L, $ 
      FIELDTYPES:[7L,2L,2L,2L], FIELDNAMES:['name','npxls','minwl','maxwl'], $
      FIELDLOCATIONS:[0L, 8L, 14L, 18L],FIELDGROUPS:[0L, 1L, 2L, 3L] }
  filters_fname=GETENV('DATADIR')+'filters'
  filters=read_ascii(filters_fname,template=filter_template)

  if (not keyword_set(filter)) then begin
     print,'FILTER keyword is not set or incorrect!'
     return,-1
  endif else begin
     filtpos=where(filter EQ filters.name,nfilt)
     if (nfilt NE 1) then begin
        print,'FILTER keyword error'
        return,-2
     endif
  endelse

  lamcenter = 6500.0  ; for 0th order
  lamscale  = 0.873
; The TMA's have a slight difference in x and y magnification so
; the width of each lenslet is less than the height as seen by the
; detector. A lenslet appears as a 32x29 pixel box at the detector.
; This helps to fit more spectra onto the array.
  lensaspect = 29.0/32.0 ; the aspect ratio of a square defined by
                         ; neighboring lenslets projected onto the detector.

  ; output variable.
  filterinfo = {lamcenter:0.0, lamscale:0.000, lammin:0.0, lammax:0.0, $
    dxpmin:0, $  ; delta(xp) of blue-end spectrum from the detector center
                 ; dxpmin := (lammin-lamcenter)/lamscale*lensaspect
    dxpmax:0}    ; delta(xp) of red-end spectrum from the detector center
                 ; dxpmin := (lammax-lamcenter)/lamscale*lensaspect
  
  filterinfo.lammin    = filters.minwl[filtpos]
  filterinfo.lammax    = filters.maxwl[filtpos]

  npixel=700 ; for narrow-band mode <CHECK>.
  if (strmid(filter,1,1) EQ 'b') then begin
     npixel=2600
  endif

  CASE strupcase(strmid(filter,0,1)) of
    'Z': order=6
    'J': order=5
    'H': order=4
    'K': order=3
  ENDCASE

  lamscale = lamscale/float(order)
  lamcenter= lamcenter/float(order)
  filterinfo.lamcenter = lamcenter
  filterinfo.lamscale  = lamscale 
  filterinfo.dxpmin    = (filterinfo.lammin-lamcenter)/lamscale*lensaspect
  filterinfo.dxpmax    = (filterinfo.lammax-lamcenter)/lamscale*lensaspect

  return,filterinfo
end
