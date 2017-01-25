;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; @BEGIN
;
; @NAME assembcube_000
;
; @PURPOSE resample the spectra to a regular wavelength grid by cubic
;          spline interpolation
;
; @@@PARAMETERS
;
;   assembcube_COMMON___CoeffFile    : File that contains the
;                                      wavelength solutions for each lenslet.
;   assembcube_COMMON___Filterfile   : File that contains filter info.
;
; @CALIBRATION-FILES wavelength fit coefficients cube
;
; @INPUT rectified frames
;
; @OUTPUT The dataset contains a 2-d set of images that have all been extracted.
;
; @QBITS all bits checked
;
; @DEBUG nothing special
;
; @SAVES see Output
;
; @NOTES This module reads a spatially rectified frame containing the
;        wavelengths for each pixel of the dataframes
;
; @STATUS not tested
;
; @HISTORY 11.12.2005, created
;          21 march, 2008 modified by saw and jel for kc filters
;
; @AUTHOR  James Larkin
;
; @Modified Shelley Wright & James Larkin (July 2009)
; 	Made the wavelength soln follow as a funcation of tempertaure
;	And Fixed Quality Bits to retain bytes 
;
; @Modified Shelley Wright (July 2010)
;	Put new wavelength solution from Tuan Do's shifts
;	in after Oct 2009 servicing mission
;	Julian date called post Oct 2009 
; @Modified Jim Lyke (May 2013)
;       Added additional wavelength solutions for several dates and
;       updated naming conventions of the wavelength solutions to 
;       include dates
; @Modified Etsuko Mieda (July 2014)
;       Fixed WCS header keywords:
;             1) lambda-y-x orientation 
;             2) pointing origin change due to Keck-II to Keck-I move
;             3) rotation matrix
; @Modified Jim Lyke (Apr 2016)
;       Added additional wavelength solutions for 13-15, new SPEC: 16-
;
;
; @END
;
;-----------------------------------------------------------------------

FUNCTION assembcube_000, DataSet, Modules, Backbone

   COMMON APP_CONSTANTS

   functionName = 'assembcube_000'

   ; save starting time
   T = systime(1)

   drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1


   BranchID = Backbone->getType()
   nFrames  = Backbone->getValidFrameCount(DataSet.Name)

   p_Filter = sxpar(*DataSet.Headers[0], "SFILTER", count=n_SF)
   ; some checks
   for i=0, nFrames-1 do begin
      ; check that the SFilter keyword occurs exactly 1 time
      s_Filter = sxpar(*DataSet.Headers[i], "SFILTER", count=n_SF)
      if ( n_SF ne 1 ) then $
         return, error('ERROR IN CALL ('+strtrim(functionName)+'): SFILTER keyword not or multiply defined.')
      if ( s_Filter ne p_Filter ) then $
         return, error('ERROR IN CALL ('+strtrim(functionName)+'): SFILTER keyword must be the same for all frames.')
   end

   ; Store common variables into local ones.
   s_FilterFile  = strg(Backbone->getParameter('assembcube_COMMON___Filterfile'))
   s_CoeffFile   = strg(Backbone->getParameter('assembcube_COMMON___CoeffFile'))
   s05_06CoeffFile   = strg(Backbone->getParameter('assembcube_COMMON___05_06CoeffFile'))
   s06_09CoeffFile   = strg(Backbone->getParameter('assembcube_COMMON___06_09CoeffFile'))
   s09_12CoeffFile   = strg(Backbone->getParameter('assembcube_COMMON___09_12CoeffFile'))
   s12_12CoeffFile   = strg(Backbone->getParameter('assembcube_COMMON___12_12CoeffFile'))
   s13_15CoeffFile   = strg(Backbone->getParameter('assembcube_COMMON___13_15CoeffFile'))

   ; midwave is a wavelength offset used to make the poly fit symmetric in wavelength
   ; This must match what is in the routine that fits raw spectra: plot_fwhm
   midwave = 2200

                                ; Determine if this is broad band or
                                ; narrow band data. Modified by Saw
                                ; and JEL to include Kcb on March 21, 2008
   bb = strcmp('b',strmid(s_Filter,2,1))
   print, s_Filter, bb

   ; Call the routine to extract the parameters for this filter from the
   ; filter file. It returns a structure s_Res containing the filter half
   ; power points, and the desired new wavelength spacing.
   s_Res = get_filter_param( s_Filter, s_FilterFile )
   npix = s_Res.n_RegPix(0)
   disp = s_Res.d_RegDisp_nmperpix(0)
   minl = s_Res.d_RegMinWL_nm(0)
   print, "Number of spectral channels =", npix
   print, "Resampled dispersion =", disp
   print, "Minimum wavelength in resampled grid =", minl

   ; Decide which order of the grating should be used.
   order = 3                              ; K Band or shorter
   if ( minl lt 1900.0 ) then order = 4   ; H Band or shorter
   if ( minl lt 1450.0 ) then order = 5   ; J Band or shorter
   if ( minl lt 1160.0 ) then order = 6   ; Z band

   ; Coefficents of thermal expansion of Al for a given temperature (K) 
   CTE = [[90,-0.003763785],$
	[89,-0.003774049],$
	[88,-0.003784192],$
	[87,-0.003794211],$
	[86,-0.003804107],$
	[85,-0.003813879],$
	[84,-0.003823527],$
	[83,-0.003833049],$
	[82,-0.003842445],$
	[81,-0.003851715],$
	[80,-0.003860858],$
	[79,-0.003869873],$
	[78,-0.00387876],$
	[77,-0.003887518],$
	[76,-0.003896146],$
	[75,-0.003904645],$
	[74,-0.003913012],$
	[73,-0.003921249],$
	[72,-0.003929353],$
	[71,-0.003937326],$
	[70,-0.003945165],$
	[69,-0.00395287],$
	[68,-0.003960441],$
	[67,-0.003967877],$
	[66,-0.003975178],$
	[65,-0.003982343],$
	[64,-0.00398937],$
	[63,-0.003996261],$
	[62,-0.004003014],$
	[61,-0.004009628],$
	[60,-0.004016103],$
	[59,-0.004022438],$
	[58,-0.004028633],$
	[57,-0.004034687],$
	[56,-0.0040406],$
	[55,-0.00404637],$
	[54,-0.004051998],$
	[53,-0.004057482],$
	[52,-0.004062822],$
	[51,-0.004068018],$
	[50,-0.004073069],$
	[49,-0.004077974],$
	[48,-0.004082732],$
	[47,-0.004087344],$
	[46,-0.004091808],$
	[45,-0.004096124]]

   ; Read in header to get temperatures of TMA housing 
   TMA = sxpar(*DataSet.Headers[0],'DTMP7')

   ; Now find the coefficent given the current temperature data
   cotemp = interpol(CTE[1,*],CTE[0,*],TMA)

   ; Now find the coefficent to the reference wavelength soln (060701) where T=50.73K
   coref = interpol(CTE[1,*],CTE[0,*],50.73)

   ; Fraction of expansion/shrinking of the Al grating 
   frac_expan = (1 + cotemp) / (1 + coref) 

   ; Create a look-up table of wavelengths for each of the spectral slices.
   lambda = disp*findgen(npix)+minl

   ; Scale the wavelength to the 3rd order where the fit was determined
   lambda = lambda * float(order) / 3.0

   ; Apply temperature dependence to wavelength soln (found from Al coefficents above)
   lambda = lambda / frac_expan 

   ; and add midwave defined above
   lambda = lambda - midwave

   ; Read in the matrix of coefficients used for fitting pixel as a function
   ; of wavelength
   jul_date = sxpar(*DataSet.Headers[0], "MJD-OBS", count=num)
   print,'Julian Date of Observations =',jul_date
   ; Check to see if the date is set and if it is prior to the service
   ; mission in February 2006. If so, then use the old calib
   ; file. Otherwise the default is the new file. 
   if ( (num eq 1) and (jul_date lt 53790.0) ) then begin
       print, "Using wavelength coefficients from before 2006"
       coeffFile = s05_06CoeffFile
   endif
   ;finds coeffs between Feb 2006 and Oct 2009
   if ( (num eq 1) and (jul_date ge 53790.0 and jul_date lt 55110.0) ) then begin
       print, "Using wavelength coefficient solution from Feb 23, 2006 - Oct 4, 2009"
       coeffFile = s06_09CoeffFile
   endif
   ;finds coeffs between Oct 2009 and Jan 2012
   if ( (num eq 1) and (jul_date ge 55110.0 and jul_date lt 55930.0) ) then begin
       print, "Using wavelength coefficient solution from Oct 4, 2009 - Jan 3, 2012"
       coeffFile = s09_12CoeffFile
   endif
   ;finds coeffs between Jan 2012 and Nov 2012
   if ( (num eq 1) and (jul_date ge 55930.0 and jul_date lt 56242.0) ) then begin
       print, "Using wavelength coefficient solution from Jan 3, 2012 - Nov 9, 2012"
       coeffFile = s12_12CoeffFile
   endif
   ; finds coeffs between Nov 2012 and Dec 2015
   if ( (num eq 1) and (jul_date ge 56242.0 and jul_date lt 57388.0)) then begin
        print, "Using wavelength coefficient solution from Nov 9, 2012 - Dec 31, 2015"
       coeffFile = s13_15CoeffFile
   endif
   ; use current coeff file for dates Jan 1, 2016 and after
   if ( (num eq 1) and (jul_date ge 57388.0 )) then begin
        coeffFile = s_CoeffFile
   endif

   dum = strsplit(coeffFile, '/', /extract)
   coeffFileNoPath = dum[n_elements(dum)-1]
   coeffs = readfits(coeffFile)

   sz = size(coeffs)
   complete = intarr(sz[2],sz[3])

   ; For each lenslet find out if its
   ; complete spectrum is on the detector
   first_col = sz[2]-1 ; Keep track of the left most valid column
   last_col = 0        ; Keep track of the right most valid column
   for i = 0, sz[2]-1 do begin
       for j = 0, sz[3]-1 do begin
           if (coeffs[0,i,j] gt 100.0 ) then begin ; Validity check
               first_pix = poly(lambda[npix-1],coeffs[*,i,j])
               if ( first_pix ge 0.0 ) then begin  ; Starts right of left edge
                   last_pix = poly(lambda[0],coeffs[*,i,j])
                   if ( last_pix le 2047 ) then begin
                       complete[i,j] = 1
                       if ( i lt first_col ) then first_col = i
                       if ( i gt last_col ) then last_col = i
                   end
               end
           end
       end
   end
   ; Mask out lenslets corresponding to the BB mask for BB data
   if ( bb eq 1 ) then begin
       first_col=16
       last_col=34
       complete[0:15,*]=0
       complete[35:(sz[2]-1),*]=0
       complete[16,17:(sz[3]-1)]=0
       complete[17,33:(sz[3]-1)]=0
       complete[18,49:(sz[3]-1)]=0
       complete[32,0:16]=0
       complete[33,0:32]=0
       complete[34,0:48]=0
   end
   ; Filters where order overlap occurs are special.
   if ( strcmp('Zn2',strmid(s_Filter,0,3)) eq 1) then begin
       first_col=16
       last_col=34
       complete[0:15,*]=0
       complete[35:(sz[2]-1),*]=0
       complete[16,17:(sz[3]-1)]=0
       complete[17,33:(sz[3]-1)]=0
       complete[18,49:(sz[3]-1)]=0
       complete[32,0:16]=0
       complete[33,0:32]=0
       complete[34,0:48]=0
   end
   if ( strcmp('Zn3',strmid(s_Filter,0,3)) eq 1) then begin
       first_col=16
       last_col=34
       complete[0:15,*]=0
       complete[35:(sz[2]-1),*]=0
       complete[16,17:(sz[3]-1)]=0
       complete[17,33:(sz[3]-1)]=0
       complete[18,49:(sz[3]-1)]=0
       complete[32,0:16]=0
       complete[33,0:32]=0
       complete[34,0:48]=0
   end
   if ( strcmp('Zn4',strmid(s_Filter,0,3)) eq 1) then begin
       first_col=16
       complete[0:15,*]=0
       complete[16,17:(sz[3]-1)]=0
       complete[17,33:(sz[3]-1)]=0
       complete[18,49:(sz[3]-1)]=0
   end
   if ( strcmp('Zn5',strmid(s_Filter,0,3)) eq 1) then begin
       first_col=16
       complete[0:15,*]=0
       complete[16,17:(sz[3]-1)]=0
       complete[17,33:(sz[3]-1)]=0
       complete[18,49:(sz[3]-1)]=0
   end

   print, "Valid columns=", first_col, last_col

   nrows = 66
   ncols = 51
   nspec = 1024 ; Narrow band data is in compressed form after extraction.
   if ( bb eq 1 ) then begin
       nrows = 64
       ncols = 19
       nspec = 1216   ; 19x64, full broadband lenslet storage.
   end

   ; create final arrays for storing data.
   Frame       = make_array(npix,nrows,ncols,/FLOAT)
   IntFrame    = make_array(npix,nrows,ncols,/FLOAT)
   IntAuxFrame = make_array(npix,nrows,ncols,/BYTE)

   for q=0, nFrames-1 do begin
       abscissa = findgen(2048) ; Look up table for interpolated values

       print, "Assembling cube ", q
       if ( bb eq 1 ) then begin
           ; Broad band data.
           for sp = 0, nspec-1 do begin
               row = sp mod nrows ; Where in final cube to place data
               col = floor(sp/nrows) ; Where in final cube to place data
               j = row + 1           ; Where to look in coeffs for solution
               i = col + first_col   ; Where to look in coeffs for solution
               if ( complete[i,j] eq 1 ) then begin ; Valid pixel
                   pixels = poly(lambda,coeffs[*,i,j]) ; Map the desired wavelengths into the original pixels
                   ; Use valid pixels to interpolate pixel values
                   good = where( (*DataSet.IntAuxFrames[q])[*,sp] eq 9 )
                   if ( good[0] ne -1 ) then begin
                       Frame[*,row,col]=interpol((*DataSet.Frames[q])[good,sp],abscissa[good],pixels)
                       IntFrame[*,row,col]=interpol((*DataSet.IntFrames[q])[good,sp],abscissa[good],pixels)
                       ; Initially interpolate bad pixel map
                   endif
                   IntAuxFrame[*,row,col]= interpol((*DataSet.IntAuxFrames[q])[*,sp],abscissa[*],pixels)
                   ;IntAuxFrame[*,row,col]=9
               end
           end
        endif else begin
            ; Narrow band data.
            for sp = 0, nspec-1 do begin
                ; Extract 1st block of 16x64 spectra
                row = (sp mod (nrows-2))+2
                col = floor(sp/(nrows-2))+3
                j = row
                i = col
                if ( complete[i,j] eq 1 ) then begin
                    pixels = poly(lambda,coeffs[*,i,j]) ; Map the desired wavelengths into the original pixels
                    good = where( (*DataSet.IntAuxFrames[q])[*,sp] eq 9 )
                    if ( good[0] ne -1 ) then begin
                        Frame[*,row,col]=interpol((*DataSet.Frames[q])[good,sp],abscissa[good],pixels)
                        IntFrame[*,row,col]=interpol((*DataSet.IntFrames[q])[good,sp],abscissa[good],pixels)
	            endif
                    IntAuxFrame[*,row,col]= interpol((*DataSet.IntAuxFrames[q])[*,sp],abscissa[*],pixels)
                    ;IntAuxFrame[*,row,col]=9
                endif
                ; Extract 2nd block of 16x64 spectra
                row = (sp mod (nrows-2))+1
                col = floor(sp/(nrows-2))+16+3
                j = row
                i = col
                if ( complete[i,j] eq 1 ) then begin
                    pixels = poly(lambda,coeffs[*,i,j]) ; Map the desired wavelengths into the original pixels
                    good = where( (*DataSet.IntAuxFrames[q])[*,sp] eq 9 )
                    if ( good[0] ne -1 ) then begin
                        Frame[*,row,col]=interpol((*DataSet.Frames[q])[good,sp],abscissa[good],pixels)
                        IntFrame[*,row,col]=interpol((*DataSet.IntFrames[q])[good,sp],abscissa[good],pixels)
		    endif
                    IntAuxFrame[*,row,col]= interpol((*DataSet.IntAuxFrames[q])[*,sp],abscissa[*],pixels)
                    ;IntAuxFrame[*,row,col]=9
                endif
                ; Extract 3rd block of 16x64 spectra
                row = (sp mod (nrows-2))
                col = floor(sp/(nrows-2))+32+3
                j = row
                i = col
                if ( complete[i,j] eq 1 ) then begin
                    pixels = poly(lambda,coeffs[*,i,j]) ; Map the desired wavelengths into the original pixels
                    good = where( (*DataSet.IntAuxFrames[q])[*,sp] eq 9 )
                    if ( good[0] ne -1 ) then begin
                        Frame[*,row,col]=interpol((*DataSet.Frames[q])[good,sp],abscissa[good],pixels)
                        IntFrame[*,row,col]=interpol((*DataSet.IntFrames[q])[good,sp],abscissa[good],pixels)
			endif
                    IntAuxFrame[*,row,col]= interpol((*DataSet.IntAuxFrames[q])[*,sp],abscissa[*],pixels)
                    ;IntAuxFrame[*,row,col]=9
                endif
                ; Extract extract few spectra
                if ( sp gt 831 ) then begin
                    row = ((sp mod (nrows-2))+3) < (nrows-1)
                    col = floor(sp/(nrows-2))-16+3
                    j = row
                    i = col
                    if ( complete[i,j] eq 1 ) then begin
                        pixels = poly(lambda,coeffs[*,i,j]) ; Map the desired wavelengths into the original pixels
                        good = where( (*DataSet.IntAuxFrames[q])[*,sp] eq 9 )
                        if ( good[0] ne -1 ) then begin
                            Frame[*,row,col]=interpol((*DataSet.Frames[q])[good,sp],abscissa[good],pixels)
                            IntFrame[*,row,col]=interpol((*DataSet.IntFrames[q])[good,sp],abscissa[good],pixels)
			endif
                        IntAuxFrame[*,row,col]= interpol((*DataSet.IntAuxFrames[q])[*,sp],abscissa[*],pixels)
			;IntAuxFrame[*,row,col]=9
                    endif
                endif
            end
        end

        ; If a final pixel was next to a bad pixel, then it's
        ; interpolated value will be less than  9. Set such a pixel to 0 to mark it
        ; as bad. This means one bad pixel in the unstretched cubes will become at
        ; least 2 bad pixels in the end.
	bad = where(IntAuxFrame ne 9)
	if ( bad[0] ne -1 ) then begin
            IntAuxFrame[bad] = 0
        endif

        ;good = where(IntAuxFrame gt 0 )
        ;if ( good[0] ne -1 ) then begin
        ;    IntAuxFrame[good] = 9
        ;endif

        ; Make the new cubes the valid data frames.
        tempPtr = PTR_NEW(/ALLOCATE_HEAP) ; Create a temporary reference pointer
        *tempPtr = *DataSet.Frames[q]     ; Point it at the old location
        *DataSet.Frames[q]=Frame          ; Set the Frames pointer to the new location
        PTR_FREE, tempPtr                 ; Free the memory at the old location

        ; Make the new cubes the valid integration frames.
        tempPtr = PTR_NEW(/ALLOCATE_HEAP) ; Create a temporary reference pointer
        *tempPtr = *DataSet.IntFrames[q]     ; Point it at the old location
        *DataSet.IntFrames[q]=IntFrame          ; Set the Frames pointer to the new location
        PTR_FREE, tempPtr                 ; Free the memory at the old location

        ; Make the new cubes the valid quality frames.
        tempPtr = PTR_NEW(/ALLOCATE_HEAP) ; Create a temporary reference pointer
        *tempPtr = *DataSet.IntAuxFrames[q]     ; Point it at the old location
        *DataSet.IntAuxFrames[q]=IntAuxFrame   ; Set the Frames pointer to the new location
        PTR_FREE, tempPtr                 ; Free the memory at the old location

        n_dims = size(*DataSet.Frames[q])

        ; Set the correct header keywords for the array size
        SXADDPAR, *DataSet.Headers[q], "NAXIS", n_dims(0),AFTER='BITPIX'
        SXADDPAR, *DataSet.Headers[q], "NAXIS1", n_dims(1),AFTER='NAXIS'
        SXADDPAR, *DataSet.Headers[q], "NAXIS2", n_dims(2),AFTER='NAXIS1'
        SXADDPAR, *DataSet.Headers[q], "NAXIS3", n_dims(3),AFTER='NAXIS2'

        ; Remove any existing wavelength information
        sxdelpar, *DataSet.Headers[q], 'CDELT1'
        sxdelpar, *DataSet.Headers[q], 'CRVAL1'
        sxdelpar, *DataSet.Headers[q], 'CRPIX1'
        sxdelpar, *DataSet.Headers[q], 'CUNIT1'
       

	; FIX for Keck I orientation (this is from Lyke and Randy's oflipy module
	; addding into assemble so it's hard coded 	
	; flip cubes in the Y dimension (rows) to make the handedness correct on Keck I
	; Change made in March of 2012 as part of the recommissioning on Keck I
	; JL and RDC
	;
	;for i=0, nFrames-1 do begin
     		 jul_date = sxpar(*DataSet.Headers[q],"MJD-OBS", count=num)
    		 if jul_date gt 55942.5 then begin
   			*DataSet.Frames[q] = reverse(*DataSet.Frames[q],2,/overwrite)
       			*DataSet.IntFrames[q] = reverse(*DataSet.IntFrames[q],2,/overwrite)   
       			*DataSet.IntAuxFrames[q] = reverse(*DataSet.IntAuxFrames[q],2,/overwrite) 
      		 	sxaddpar, *DataSet.Headers[q],'FLIP','TRUE', 'OSIRIS move to Keck I necessitates a flip'
   		 	sxaddhist, 'Cube was acquired on Keck I, thus has been flipped', *DataSet.Headers[q]
       	 		print, 'Julian date indicates this is Keck I data, Cube fliped in Y'
    		endif else begin
          		print, 'Julian date is before move to Keck I, using Keck II orientation'
		endelse
 	;endfor


;	for i=0, nFrames-1 do begin
;     		tel = strtrim(sxpar(*DataSet.Headers[i], 'TELESCOP', count = n))
;    		 if tel eq 'Keck II' then begin
;      		     sxaddpar, *DataSet.Headers[i],'FLIP','FALSE', $
;        		        'OSIRIS move to Keck I necessitates a flip'
;       	 	     sxaddhist, 'Cube was acquired on Keck II, thus not flipped', *DataSet.Headers[i]
;          		 print, 'oflip Y ignored, keck II data'
;    		 endif else begin
;   			*DataSet.Frames[i] = reverse(*DataSet.Frames[i],2,/overwrite)
;       			*DataSet.IntFrames[i] = reverse(*DataSet.IntFrames[i],2,/overwrite)   
;       			*DataSet.IntAuxFrames[i] = reverse(*DataSet.IntAuxFrames[i],2,/overwrite) 
;      		 	sxaddpar, *DataSet.Headers[i],'FLIP','TRUE', 'OSIRIS move to Keck I necessitates a flip'
;   		 	sxaddhist, 'Cube was acquired on Keck I, thus has been flipped', *DataSet.Headers[i]
;       	 		 print, 'Cube fliped in Y , Keck I data'
;    		endelse
;
; 	 endfor
 
    
		; Now actually update with a full WCS-compliant header for all axes
		;  Code by M. Perrin from addwcs_000.pro
	   RA = double(sxpar(*DataSet.Headers[q], 'RA', count=ra_count))
	   DEC = double(sxpar(*DataSet.Headers[q], 'DEC', count=dec_count))
	   pixelScale = float(sxpar(*DataSet.Headers[q], 'SSCALE',count=found_pixelscale))
	   if (not found_pixelscale) then pixelscale = float(sxpar(*DataSet.Headers[q],'SSSCALE'))
	   pixelscale_str =  strcompress(pixelscale,/remove_all)
	   naxis1 = sxpar(*DataSet.Headers[q],'NAXIS1')
	   d_PA  = float(sxpar(*DataSet.Headers[q], 'PA_SPEC', count=pa_count))
	   PA_str  = strcompress(d_PA,/remove_all)
	   d_PA = d_PA * !pi / 180d
	   s_filter = sxpar(*DataSet.Headers[q],'SFILTER',count=n_sf)

	   if (ra_count eq 0 or dec_count eq 0 or pa_count eq 0 or n_sf eq 0) then begin
    		warning, 'WARNING (' + functionName + '): Some crucial keywords missing from header! '
print,'cotemp ',cotemp
    		warning, 'WARNING (' + functionName + '): Therefore the resulting WCS information will surely be wrong. '
			sxaddhist, 'WARNING (' + functionName + '): Some crucial keywords missing from header! ', *DataSet.Headers[q]
    		sxaddhist, 'WARNING (' + functionName + '): Therefore the resulting WCS information will surely be wrong. ', *DataSet.Headers[q]
		endif
	   ; the following is from mosaic_000.pro:
	   ; Make default center the broad band values
       if jul_date lt 55942.5 then begin ; (Mieda-201407: x reference pixel correction for x flip due to Keck-I optics)
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
           endif else begin
               pnt_cen=[32.0,n_dims[3]-1-9.0]
               if ( n_sf eq 1 ) then begin
                   bb = strcmp('b',strmid(s_filter,2,1))
                   if ( strcmp('Zn2',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,n_dims[3]-1-25.0]
                   if ( strcmp('Zn3',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,n_dims[3]-1-25.0]
                   if ( strcmp('Zn4',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,n_dims[3]-1-33.0]
		   if ( strcmp('Zn5',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,n_dims[3]-1-33.0]
		   if ( strcmp('Jn1',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,n_dims[3]-1-17.0]
		   if ( strcmp('Jn2',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,n_dims[3]-1-22.0]
		   if ( strcmp('Jn3',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,n_dims[3]-1-25.0]
		   if ( strcmp('Jn4',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,n_dims[3]-1-28.0]
		   if ( strcmp('Hn1',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,n_dims[3]-1-19.0]
		   if ( strcmp('Hn2',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,n_dims[3]-1-23.0]
		   if ( strcmp('Hn3',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,n_dims[3]-1-25.0]
		   if ( strcmp('Hn4',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,n_dims[3]-1-28.0]
		   if ( strcmp('Hn5',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,n_dims[3]-1-33.0]
		   if ( strcmp('Kn1',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,n_dims[3]-1-19.0]
		   if ( strcmp('Kn2',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,n_dims[3]-1-23.0]
		   if ( strcmp('Kn3',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,n_dims[3]-1-25.0]
		   if ( strcmp('Kn4',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,n_dims[3]-1-28.0]
		   if ( strcmp('Kn5',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,n_dims[3]-1-33.0]
		   if ( strcmp('Kc3',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,n_dims[3]-1-25.0]
		   if ( strcmp('Kc4',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,n_dims[3]-1-28.0]
		   if ( strcmp('Kc5',strmid(s_filter,0,3)) eq 1 ) then pnt_cen=[32.0,n_dims[3]-1-33.0]
               endif
           endelse
	   print, "Pointing center is", pnt_cen
   
   ; Update RA and DEC header keywords
	sxaddhist, functionName+":  Updating FITS header WCS keywords.", *DataSet.Headers[q]
        sxaddpar, *DataSet.Headers[q], "INSTRUME", "OSIRIS", "Instrument: OSIRIS on Keck I" ; FITS-compliant instrument name, too
        sxaddpar, *DataSet.Headers[q], "WAVEFILE", coeffFileNoPath, "Wavelength Solution File"
        sxaddpar, *DataSet.Headers[q], "WCSAXES", 3, "Number of axes in WCS system"
	sxaddpar, *DataSet.Headers[q], "CTYPE1", "WAVE", "Vacuum wavelength."
        ; (Mieda-201407: CTYPE, CUNIT, CRVAL are supposed to be 2 for RA and 3 for Dec
	sxaddpar, *DataSet.Headers[q], "CTYPE2", "DEC--TAN", "Declination."
	sxaddpar, *DataSet.Headers[q], "CTYPE3", "RA---TAN", "Right Ascension."
	sxaddpar, *DataSet.Headers[q], "CUNIT1", "nm", "Vacuum wavelength unit is nanometers"
	sxaddpar, *DataSet.Headers[q], "CUNIT2", "deg", "Declination unit is degrees, always"
	sxaddpar, *DataSet.Headers[q], "CUNIT3", "deg", "R.A. unit is degrees, always"
        sxaddpar, *DataSet.Headers[q], 'CRVAL1', minl, " [nm] Wavelength at reference pixel"
        sxaddpar, *DataSet.Headers[q], "CRVAL2", sxpar(*DataSet.Headers[q],"DEC"), " [deg] Declination at reference pixel"
	sxaddpar, *DataSet.Headers[q], "CRVAL3", sxpar(*DataSet.Headers[q],"RA"), " [deg] R.A. at reference pixel"
        sxaddpar, *DataSet.Headers[q], 'CRPIX1', 1, "Reference pixel location"
	sxaddpar, *DataSet.Headers[q], "CRPIX2", pnt_cen[0],     	"Reference pixel location"
	sxaddpar, *DataSet.Headers[q], "CRPIX3", pnt_cen[1],     	"Reference pixel location"
    sxaddpar, *DataSet.Headers[q], 'CDELT1', disp , "Wavelength scale is "+string(disp)+" nm/channel "
	sxaddpar, *DataSet.Headers[q], "CDELT2", pixelscale/3600., "Pixel scale is "+pixelscale_str+" arcsec/pixel"
	sxaddpar, *DataSet.Headers[q], "CDELT3", pixelscale/3600., "Pixel scale is "+pixelscale_str+" arcsec/pixel"

	; rotation matrix.
        pc = [[cos(d_PA), sin(d_PA)], $
                [sin(d_PA), -cos(d_PA)]]  ; (Mieda-201407: Rotation matrix correction

	sxaddpar, *DataSet.Headers[q], "PC1_1", 1, "Spectral axis is unrotated"
	sxaddpar, *DataSet.Headers[q], "PC2_2", pc[0,0], "RA, Dec axes rotated by "+PA_str+" degr."
	sxaddpar, *DataSet.Headers[q], "PC2_3", pc[0,1], "RA, Dec axes rotated by "+PA_str+" degr."
	sxaddpar, *DataSet.Headers[q], "PC3_2", pc[1,0], "RA, Dec axes rotated by "+PA_str+" degr."
	sxaddpar, *DataSet.Headers[q], "PC3_3", pc[1,1], "RA, Dec axes rotated by "+PA_str+" degr."
    ; The spectral axis is in topocentric coordiantes (i.e. constant)
	sxaddpar, *DataSet.Headers[q], "SPECSYS", "TOPOCENT", "Spec axis ref frame is in topocentric coordinates."
	; The spectral axis reference frame does not vary with the celestial axes
	sxaddpar, *DataSet.Headers[q], "SSYSOBS", "TOPOCENT", "Spec axis ref frame is constant across RADEC axes."
    
	; TODO WCS paper III suggests adding MJD-AVG to specify midpoint of
	; observations for conversions to barycentric.
	sxaddpar, *DataSet.Headers[q], "RADESYS", "FK5", "RA and Dec are in FK5"
	sxaddpar, *DataSet.Headers[q], "EQUINOX", 2000.0, "RA, Dec equinox is J2000 (I think)"
 
;stop
    endfor

   ; update the header
;   for i=0, nFrames-1 do begin
;       if ( verify_naxis ( DataSet.Frames(i), DataSet.Headers(i), /UPDATE ) ne OK ) then begin
;           return, error('FAILURE ('+strtrim(functionName)+'): Update of header failed.')
;       end
;   end
 



   report_success, functionName, T

   return, OK

end
