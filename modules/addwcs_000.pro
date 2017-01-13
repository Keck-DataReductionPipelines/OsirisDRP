;-----------------------------------------------------------------------
; THIS IS A **USER-WRITTEN**DRP MODULE
;
; @BEGIN
;
; @NAME addwcs_000
;
; @PURPOSE  Add or update WCS coordinates to the FITS header, compliant
; 	with the various WCS standards papers.
; 
; @PARAMETERS None
;
; @CALIBRATION-FILES None
;
; @INPUT None
;
; @OUTPUT contains the adjusted data. The number of valid pointers 
;         is not changed.
;
; @@@QBITS  0th     : checked
;           1st-3rd : ignored
;
; @DEBUG nothing special
;
; @MAIN None
;
; @SAVES Nothing
;
; @@@@NOTES  - The inside bit is ignored.
;            - Input frames must be 2d.
;
; @STATUS  sorta tested
;
; @HISTORY  2007-07-03, created
;           21 march, 2008 modified by saw and jel for kc filters.
;
; @AUTHOR  Marshall Perrin
;
; @END
;
;-----------------------------------------------------------------------

FUNCTION addwcs_000, DataSet, Modules, Backbone

    COMMON APP_CONSTANTS

    functionName = 'addwcs_000'
    ; save the starting time
    T = systime(1)

    drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1

    nFrames = Backbone->getValidFrameCount(DataSet.Name)
    n_Dims = size( *DataSet.Frames[0])
	
	if n_dims[0] eq 3 then begin
		; image cube! lambda, Y, X format.
	

	
	; TODO??
	; we only update the FIRST FITS header
	; Are there any circumstances under which we should update more?
	 
	   ; Retrieve header information (1st frame)
	   RA = double(sxpar(*DataSet.Headers[0], 'RA', count=ra_count))
	   DEC = double(sxpar(*DataSet.Headers[0], 'DEC', count=dec_count))
	   pixelScale = float(sxpar(*DataSet.Headers[0], 'SSCALE',count=found_pixelscale))
	   if (not found_pixelscale) then pixelscale = float(sxpar(*DataSet.Headers[0],'SSSCALE'))
	   pixelscale_str =  strcompress(pixelscale,/remove_all)
	   naxis1 = sxpar(*DataSet.Headers[0],'NAXIS1')
	   d_PA  = float(sxpar(*DataSet.Headers[0], 'PA_SPEC', count=pa_count))
	   PA_str  = strcompress(d_PA,/remove_all)
	   d_PA = d_PA * !pi / 180d
	   s_filter = sxpar(*DataSet.Headers[0],'SFILTER',count=n_sf)

	   if (ra_count eq 0 or dec_count eq 0 or pa_count eq 0 or n_sf eq 0) then begin
    		warning, 'WARNING (' + functionName + '): Some crucial keywords missing from header! '
    		warning, 'WARNING (' + functionName + '): Therefore the resulting WCS information will surely be wrong. '
    		sxaddhist, 'WARNING (' + functionName + '): Some crucial keywords missing from header! ', *DataSet.Headers[0]
    		sxaddhist, 'WARNING (' + functionName + '): Therefore the resulting WCS information will surely be wrong. ', *DataSet.Headers[0]
		endif

   ; the following is from mosaic_000.pro:
   ; Make default center the broad band values
   pnt_cen=[32.0,9.0]
   if ( n_sf eq 1 ) then begin
       bb = strcmp('b',strmid(s_filter,2,1))
       if ( strcmp('Zn2',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,25.0]
       if ( strcmp('Zn3',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,25.0]
       if ( strcmp('Zn4',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,33.0]
       if ( strcmp('Zn5',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,33.0]
       if ( strcmp('Jn1',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,17.0]
       if ( strcmp('Jn2',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,22.0]
       if ( strcmp('Jn3',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,25.0]
       if ( strcmp('Jn4',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,28.0]
       if ( strcmp('Hn1',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,19.0]
       if ( strcmp('Hn2',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,23.0]
       if ( strcmp('Hn3',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,25.0]
       if ( strcmp('Hn4',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,28.0]
       if ( strcmp('Hn5',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,33.0]
       if ( strcmp('Kn1',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,19.0]
       if ( strcmp('Kn2',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,23.0]
       if ( strcmp('Kn3',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,25.0]
       if ( strcmp('Kn4',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,28.0]
       if ( strcmp('Kn5',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,33.0]
       if ( strcmp('Kc3',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,25.0]
       if ( strcmp('Kc4',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,28.0]
       if ( strcmp('Kc5',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,33.0]
   end
   print, "Pointing center is", pnt_cen
 	
   ; Update RA and DEC header keywords
	sxaddhist, functionName+":  Updating FITS header WCS keywords.", *DataSet.Headers[0]
    sxaddpar, *DataSet.Headers[0], "INSTRUME", "OSIRIS", "Instrument: OSIRIS on Keck II" ; FITS-compliant instrument name, too
    sxaddpar, *DataSet.Headers[0], "WCSAXES", 3, "Number of axes in WCS system"
;;;;;; axis one: already added by assembcube
	;sxaddpar, *DataSet.Headers[0], "CRVAL1", 		already done!
	;sxaddpar, *DataSet.Headers[0], "CRPIX1", 		already done!
	;sxaddpar, *DataSet.Headers[0], "CDELT1", 		already done!
	sxaddpar, *DataSet.Headers[0], "CTYPE1", "WAVE", "Vacuum wavelength."
	sxaddpar, *DataSet.Headers[0], "CTYPE2", "RA---TAN", "Right Ascension."
	sxaddpar, *DataSet.Headers[0], "CTYPE3", "DEC--TAN", "Declination."
	sxaddpar, *DataSet.Headers[0], "CUNIT1", "nm", "Vacuum wavelength unit is microns"
	sxaddpar, *DataSet.Headers[0], "CUNIT2", "deg", "R.A. unit is degrees, always"
	sxaddpar, *DataSet.Headers[0], "CUNIT3", "deg", "Declination unit is degrees, always"
	sxaddpar, *DataSet.Headers[0], "CRVAL2", sxpar(*DataSet.Headers[0],"RA"), "R.A. at reference pixel"
	sxaddpar, *DataSet.Headers[0], "CRVAL3", sxpar(*DataSet.Headers[0],"DEC"), "Declination at reference pixel"
	sxaddpar, *DataSet.Headers[0], "CRPIX2", pnt_cen[0],     	"Reference pixel location"
	sxaddpar, *DataSet.Headers[0], "CRPIX3", pnt_cen[1],     	"Reference pixel location"
	sxaddpar, *DataSet.Headers[0], "CDELT2", pixelscale/3600., "Pixel scale is "+pixelscale_str+" arcsec/pixel"
	sxaddpar, *DataSet.Headers[0], "CDELT3", pixelscale/3600., "Pixel scale is "+pixelscale_str+" arcsec/pixel"

	; rotation matrix.
	pc = [[cos(d_PA), -sin(d_PA)], $
		  [sin(d_PA), cos(d_PA)]]

	sxaddpar, *DataSet.Headers[0], "PC1_1", 1, "Spectral axis is unrotated"
	sxaddpar, *DataSet.Headers[0], "PC2_2", pc[0,0], "RA, Dec axes rotated by "+PA_str+" degr."
	sxaddpar, *DataSet.Headers[0], "PC2_3", pc[0,1], "RA, Dec axes rotated by "+PA_str+" degr."
	sxaddpar, *DataSet.Headers[0], "PC3_2", pc[1,0], "RA, Dec axes rotated by "+PA_str+" degr."
	sxaddpar, *DataSet.Headers[0], "PC3_3", pc[1,1], "RA, Dec axes rotated by "+PA_str+" degr."
    
    ; The spectral axis is in topocentric coordiantes (i.e. constant)
	sxaddpar, *DataSet.Headers[0], "SPECSYS", "TOPOCENT", "Spec axis ref frame is in topocentric coordinates."
	; The spectral axis reference frame does not vary with the celestial axes
	sxaddpar, *DataSet.Headers[0], "SSYSOBS", "TOPOCENT", "Spec axis ref frame is constant across RADEC axes."
	
    ; TODO WCS paper III suggests adding MJD-AVG to specify midpoint of
	; observations for conversions to barycentric.
	sxaddpar, *DataSet.Headers[0], "RADESYS", "FK5", "RA and Dec are in FK5"
	sxaddpar, *DataSet.Headers[0], "EQUINOX", 2000.0, "RA, Dec equinox is J2000, I think"
	
	;sxaddpar, *DataSet.Headers[0], 'RA', RA_new,' RA at spatial [0,0] in mosaic'
	;sxaddpar, *DataSet.Headers[0], 'DEC', DEC_new,' DEC at spatial [0,0] in mosaic'
	 report_success, functionName, T

    RETURN, OK


	endif else if n_Dims[0] eq 2 then begin
		; TODO make this work!
		print, "*** ADD WCS currently does not work on 2D images!! ***"
        return, error('FAILURE ('+strtrim(functionName)+'): Does not work on 2D images.')
	endif

   
END
