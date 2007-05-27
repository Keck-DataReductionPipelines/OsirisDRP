;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; @BEGIN
;
; @NAME remhydr_000
;
; @PURPOSE Takes a 1-D spectrum and attempts to remove absorption
; lines due to hydrogen. The primary purpose is to remove hydrogen
; absorption lines from telluric standard stars. Because there are
; sometimes atmospheric and instrumental features at the same
; wavelengths, we must fit the line and a local background and
; subtract the line fit. This should leave higher frequency features
; alone.
;
;
; @@@PARAMETERS
;
;   none
;
; @CALIBRATION-FILES none
;
; @INPUT 1-d spectrum
;
; @OUTPUT 1-d spectrum
;
; @QBITS all bits checked
;
; @DEBUG nothing special
;
; @SAVES nothing
;
; @NOTES 
;
; @STATUS not tested
;
; @HISTORY 05.25.2007, created
;
; @AUTHOR  James Larkin
;          Based on Extract Telluric Spectrum by Shelley Wright which
;          in turn borrowed from Conor Laver
;
; @END
;
;-----------------------------------------------------------------------

FUNCTION remhydr_000, DataSet, Modules, Backbone

   COMMON APP_CONSTANTS

   functionName = 'extracstar_000'

   ; save starting time
   T = systime(1)

   drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1


   BranchID = Backbone->getType()
   nFrames  = Backbone->getValidFrameCount(DataSet.Name)

   ; Define Hydrogen line locations in nm
   lines = [901.2,922.6,954.3,1004.6,1093.5, 1281.4, 1874.5, $                       ; Paschen series
            1570.7, 1588.7, 1611.5, 1641.3, 1681.3, 1736.9, 1818.1, 1945.1, 2166.1]  ; Brackett series
   numlines=size(lines,/dimensions)
   startpix=intarr(numlines[0])
   endpix = intarr(numlines[0])

   for q=0, nFrames-1 do begin
       sz = size(*DataSet.Frames[q])
       if ( sz[0] ne 1 ) then return, error('ERROR IN CALL ('+strtrim(functionName)+'): Data must be 1-d spectra.')
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
       
       ; Loop through each line location
       for line = 0, numlines[0]-1 do begin
                                ; Calculate pixel locations for all of
                                ; the hydrogen lines within the
                                ; spectrum. Fit between lam/1.007 and
                                ; lam*1.007.
           startpix[line] = fix( (((lines[line]/1.007)-firstlam)/dlam) + firstpix )
           endpix[line]   = fix( (((lines[line]*1.007)-firstlam)/dlam) + firstpix )
           if ( (startpix[line] ge 0) and (endpix[line] lt sz[1]) ) then begin ; Line is in the spectrum
               data = (*DataSet.Frames[q])[startpix[line]:endpix[line]]
               model = gaussfit(x[startpix[line]:endpix[line]],data,A)
                                ; Now set the baseline parabolic fit
                                ; to 0, but preserve the line fit.
               model = A[0]*exp(-0.5*((x-A[1])/A[2])^2)
               ; Remove Gaussian from spectrum.
               (*DataSet.Frames[q]) = (*DataSet.Frames[q])-model
           endif
       endfor
   endfor

   report_success, functionName, T

   return, OK

end
