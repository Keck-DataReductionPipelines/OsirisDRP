
;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; NAME:  subtradark_000
;
; PURPOSE: subtract the master dark frame
;
; PARAMETERS IN RPBCONFIG.XML :
;
;    subtradark_COMMON___Debug : bool, initializes the debugging mode
;
; INPUT-FILES : master dark 
;
; OUTPUT : None
;
; DATASET : contains the dark subtracted data afterwards. The number of
;           valid pointers is not changed.
;
; QUALITY BITS : 0th     : checked
;                1st-3rd : ignored
;
; DEBUG : nothing special
;
; MAIN ROUTINE : frame_op.pro
;
; SAVES : Nothing
;
; NOTES : - The inside bit is ignored.
;
;         - Input frames must be 2d.
;
; STATUS : not tested
;
; HISTORY : 6.8.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
; 	Added julian date for fixing pixel offset problem 
; 	that developed after a leach board change Sep 27, 2011 
;		Made - July 1, 2013 (JEL/SAW)
;
;-----------------------------------------------------------------------

FUNCTION subtradark_000, DataSet, Modules, Backbone

    COMMON APP_CONSTANTS

    functionName = 'subtradark_000'
    ; save the starting time
    T = systime(1)

    drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1

    ; check integrity
    stModule =  check_module( DataSet, Modules, Backbone, functionName )
    if ( NOT bool_is_struct ( stModule ) ) then $
       return, error ('ERROR IN CALL ('+strtrim(functionName)+'): Integrity check failed.')

    ; get the parameters
    b_Debug = fix(Backbone->getParameter('subtradark_COMMON___Debug')) eq 1

    ; get the master dark
    thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
    c_File = drpXlateFileName(Modules[thisModuleIndex].CalibrationFile)
    if ( NOT file_test ( c_File ) ) then $
       return, error ('ERROR IN CALL ('+strtrim(functionName)+'): Master dark ' + $
                      strtrim(string(c_File),2) + ' not found.' )

    pmd_DarkFrame       = ptr_new(READFITS(c_File, Header, /SILENT))
    pmd_DarkIntFrame    = ptr_new(READFITS(c_File, ext1Header, EXT=1, /SILENT))
    pmb_DarkIntAuxFrame = ptr_new(READFITS(c_File, ext2Header, EXT=2, /SILENT))

    if ( b_Debug ) then $
       debug_info, 'DEBUG INFO ('+strtrim(functionName)+'): Master dark loaded from '+ c_File

    if ( bool_pointer_integrity( pmd_DarkFrame, pmd_DarkIntFrame, pmb_DarkIntAuxFrame, 1, $
                                 functionName ) ne OK ) then $
       return, error('ERROR IN CALL ('+strtrim(functionName)+'): Integrity check of master dark failed.')

    ; check master darks and data frames dimensions
    if ( NOT bool_dim_match ( *pmd_DarkFrame, *DataSet.Frames[0] ) ) then $
       return, error('ERROR ('+strtrim(functionName)+'): Master dark and data frames not compatible in size')

    nFrames = Backbone->getValidFrameCount(DataSet.Name)
    
    ; This takes a raw OSIRIS file and shifts one of the output
    ; channels by one pixel. This appears to be needed after a board
    ; change in the Leach electronics on Sep 27, 2011. Its a one pixel shift
    ; of the entire 128x1024 array when its treated as a linear sequence
    ; of pixels.

    ; Get julian date from frame
 
   jul_date_frame = sxpar(*DataSet.Headers[0],"MJD-OBS", count=num)
   if ( jul_date_frame eq 0 ) then begin
       ; bogus mjd-obs, try to parse filename
       datafile = sxpar(*DataSet.Headers[0],"DATAFILE", count=num)
       datestring = strmid(datafile, 1, 6)
       year = '20' + strmid(datestring, 0,2)
       month = strmid(datestring, 2,2)
       day = strmid(datestring,4,2)
       jul_date_frame = julday(month, day, year) - 2400000. 
   endif

   nFrames = Backbone->getValidFrameCount(DataSet.Name)

    ; Check to make sure this hasn't been performed once before
   fixdetec = sxpar(*DataSet.Headers[0],"FIXDETEC") 
   
   if fixdetec eq 0 then begin

   	for n = 0, (nFrames-1) do begin
  		 if (jul_date_frame ge 55831.5) then begin
			print, 'Julian date is after Sep 27, 2011 perform adjust pixel offset on object frames'
			; DataSet.Frames
 			    quad_f = (*Dataset.Frames[n])[1408:1535,0:1024] 	; Grab the bad output channel
 			    quad_f[0:131070]=quad_f[1:131071]		; Shift it by one pixel linearly
 			    (*Dataset.Frames[n])[1408:1535,0:1024] = quad_f	; Stick it back into the file
			; DataSet.IntFrames
			    quad_intf = (*Dataset.IntFrames[n])[1408:1535,0:1024] 	
			    quad_intf[0:131070]=quad_intf[1:131071]	
			    (*Dataset.IntFrames[n])[1408:1535,0:1024] = quad_intf 
			; DataSet.IntAuxFrames
			    quad_intaf = (*Dataset.IntAuxFrames[n])[1408:1535,0:1024] 	
			    quad_intaf[0:131070]=quad_intaf[1:131071]	
			    (*Dataset.IntAuxFrames[n])[1408:1535,0:1024] = quad_intaf 
			; Add header keyword saying this is performed
			    sxaddpar, *DataSet.Headers[n], 'FIXDETEC',1.0, 'Shifted output channel by one pixel'
		    endif else begin
			print,'Julian date is before Sept 27, 2011'
		    endelse
  	  endfor

   	 ; Get julian date from dark
    	jul_date_dark = sxpar(Header,"MJD-OBS", count=num)
        if ( jul_date_dark eq 0 ) then begin
          ; bogus mjd-obs, try to parse filename
          datafile = sxpar(Header,"DATAFILE", count=num)
          datestring = strmid(datafile, 1, 6)
          year = '20' + strmid(datestring, 0,2)
          month = strmid(datestring, 2,2)
          day = strmid(datestring,4,2)
          jul_date_dark = julday(month, day, year) - 2400000. 
         endif
   	 if (jul_date_dark ge 55831.5) then begin
		print, 'Julian date is after Sep 27, 2011 perform adjust pixel offset on dark frames'
		; pmd_DarkFrames
		    quad_d = (*pmd_DarkFrame)[1408:1535,0:1024] 	
		    quad_d[0:131070]=quad_d[1:131071]	
		    (*pmd_DarkFrame)[1408:1535,0:1024] = quad_d 
		; pmd_DarkIntFrame
		    quad_intd = (*pmd_DarkIntFrame)[1408:1535,0:1024] 	
		    quad_intd[0:131070]=quad_intd[1:131071]	
		    (*pmd_DarkIntFrame)[1408:1535,0:1024] = quad_intd 
		; pmb_DarkIntAuxFrame
		    quad_intad = (*pmb_DarkIntAuxFrame)[1408:1535,0:1024] 	
		    quad_intad[0:131070]=quad_intad[1:131071]	
		    (*pmb_DarkIntAuxFrame)[1408:1535,0:1024] = quad_intad
  	  endif

     endif else begin
	print,'Not fixing bad offset since this routine has been run before OR frame is before Sep 27, 2011'
	;;;
     endelse

    ; now do the simple subtraction
    vb_Status = frame_op( DataSet.Frames, DataSet.IntFrames, DataSet.IntAuxFrames, '-', $
                          pmd_DarkFrame, pmd_DarkIntFrame, pmb_DarkIntAuxFrame, nFrames, Debug=b_Debug, /VALIDS )

    if ( NOT bool_is_vector ( vb_Status ) ) then $
       return, error('FAILURE ('+strtrim(functionName)+'): Dark subtraction failed')

    ; it is not neccessary to change the dataset pointer

    report_success, functionName, T
    ptr_free,pmd_DarkFrame,pmd_DarkIntFrame,pmb_DarkIntAuxFrame


    RETURN, OK

END
