;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; NAME:   divblackbo_000
;
; PURPOSE:  divide a 1-d, 2-d or 3-d spectra by a black body of given temperature
;           primarily useful to fix telluric spectra. Each frame can
;           have a different wavelength range.
;
; PARAMETERS IN RPBCONFIG.XML :
;    None
;    But it accepts temperature as a parameter
;
; INPUT-FILES : None
;
; OUTPUT : None
;
; INPUT : 1d,2d or 3d frames
;
; DATASET : Contains the divided data afterwards. The pointers are
;           not changed
;
; QUALITY BITS :
;          0th     : passed along
;          1st-2nd : ignored
;          3rd     : passed along
;
; NOTES : 
;         - The blackbody over the whole spectral range as specified
;           by the keywords CRVAL1, CDELT1 and CRVAL1 is normalized to
;           unit flux.
;
; STATUS : not tested
;
; HISTORY : 13.5.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;          Heavily modified by James Larkin for generic dimensionality
;          and to pass in the temperature parameter instead of common blocks
;
;-----------------------------------------------------------------------

FUNCTION divblackbo_000, DataSet, Modules, Backbone

    COMMON APP_CONSTANTS

    functionName = 'divblackbo_000'
    ; save starting time
    T = systime(1)

    drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1

    nFrames = Backbone->getValidFrameCount(DataSet.Name)

    ; Temperature must be a parameter.
    functionName = 'divblackbo_000'
    thisModuleIndex = drpModuleIndexFromCallSequence(Modules,functionName)
    temperature = Modules[thisModuleIndex].temperature
    if ( temperature lt 0. ) then $
       return, error('ERROR IN CALL ('+strtrim(functionName)+'): Temperatures must be positive.')


    ; now loop over the input data sets
   for q=0, nFrames-1 do begin
       sz = size(*DataSet.Frames[q])
       x = findgen(sz[1]) ; location of data
       firstlam=sxpar(*DataSet.Headers[q],'CRVAL1',count=n)
       if ( n ne 1 ) then return, error('ERROR IN CALL ('+strtrim(functionName)+'): CRVAL1 keyword not uniquely defined.')
       firstpix=sxpar(*DataSet.Headers[q],'CRPIX1', count=n)
       if ( n ne 1 ) then return, error('ERROR IN CALL ('+strtrim(functionName)+'): CRPIX1 keyword not uniquely defined.')
       units = sxpar(*DataSet.Headers[q],'CUNIT1',n)
       if ( n ne 1 ) then return, error('ERROR IN CALL ('+strtrim(functionName)+'): CUNIT1 keyword not uniquely defined.')
       if ( strtrim(units) ne 'nm' ) then return, error('ERROR IN CALL ('+strtrim(functionName)+'): units must be nm.')
       dlam = sxpar(*DataSet.Headers[q],'CDELT1',n)
       if ( n ne 1 ) then return, error('ERROR IN CALL ('+strtrim(functionName)+'): CDELT1 keyword not uniquely defined.')
       
       ; Now compute the blackbody spectrum for each frame.
       lam = dlam*(x-firstpix)+firstlam  ; Wavelength at each pixel
       lam = lam/1000000000.0 ; Wavelengths in meters
       dlam=dlam/1000000000.0 ; delta lam in meters
       hcokt = 0.014397/temperature
       bb = 1.0/(lam*lam*lam*lam*lam)
       bb = bb / (exp(hcokt/lam)-1.0)  ; This is proportional to flux
       mn = mean(bb) ; Calculate mean of bb
       bb = bb / mn

       ; Divide every lenslets spectrum by the blackbody
       if (sz[0] eq 1) then begin
           (*DataSet.Frames[q])[*]=(*DataSet.Frames[q])[*]/bb
       endif else if (sz[0] eq 2) then begin
           for x = 0, sz[2]-1 do begin
               (*DataSet.Frames[q])[*,x]=(*DataSet.Frames[q])[*,x]/bb
           endfor
       endif else if (sz[0] eq 3) then begin
           for x = 0, sz[2]-1 do begin
               for y = 0, sz[3]-1 do begin
                   (*DataSet.Frames[q])[*,x,y]=(*DataSet.Frames[q])[*,x,y]/bb
               endfor
           endfor
       endif
   end

   report_success, functionName, T

   return, OK

end
