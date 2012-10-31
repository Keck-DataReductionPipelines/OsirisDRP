;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; @BEGIN
;
; @NAME extracstar_000
;
; @PURPOSE Takes a reduced data cube and finds the brightest object in
;          the field and then uses aperture photometry to extract a 1-d
;          spectrum. The most common use is to extract a telluric spectrum
;          to divide into data cubes.
;
;
; @@@PARAMETERS
;
;   none
;
; @CALIBRATION-FILES none
;
; @INPUT assembled cubes
;
; @OUTPUT 1-d spectrum
;
; @QBITS all bits checked
;
; @DEBUG nothing special
;
; @SAVES nothing
;
; @NOTES  Simple aperture photometry is never the perfect answer for
; extracting a stellar spectrum, but given the small fields of view
; that are typical for OSIRIS, a curve of growth analysis is
; impossible and variable aperture sizes will often introduce hard to
; model color effects since the halo is getting smaller at longer
; wavelengths and has less power, while the core is increasing in size
; and power. So the goal of the routine is to provide a simple
; extraction with relatively easy to model color effects. Its up to a
; sophisticated user to understand for this aperture photometry does
; to their particular PSF.
;
; If the star is found near the edge of the field, then the routine
; fails. This is again just being conservative so a user is warned
; that their is a problem with their star. It is then up to the user
; to model how the loss of one side of the halo will affect the color
; of the star.
;
; @STATUS not tested
;
; @HISTORY 05.25.2007, created
; 	2010-01-13   Added Method= keyword, and various multiple methods
; 	             for extraction. - M Perrin
;       2010-09-20   Added user-defined centers (for APER methods), which 
;                    requires Centers= keyword
;                    Added BOX method, which requires BoxCoords= keyword
;                    - N McConnell
;
; @AUTHOR  James Larkin
;          Based on Extract Telluric Spectrum by Shelley Wright
;
; @END
;
;-----------------------------------------------------------------------

FUNCTION extracstar_000, DataSet, Modules, Backbone

   COMMON APP_CONSTANTS

   functionName = 'extracstar_000'
   thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
   if tag_exist( Modules[thisModuleIndex], "Method") then Method=strupcase(strtrim(Modules[thisModuleIndex].Method, 2)) else Method="APER_RADIUS7"
   ; don't let program crash for Box method without Boxcoords keyword
   if (Method eq "BOX" AND ~tag_exist( Modules[thisModuleIndex], "BoxCoords")) then begin 
       Method = "APER_RADIUS7"
       warning, " WARNING ("+ functionName + "): BOX method requires input file.  Specify filename with BoxCoords tag in DRF." 
       warning, " WARNING ("+ functionName + "): Reverting to APER_RADIUS7 extraction method."
   endif 

   ; save starting time
   T = systime(1)

   drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1


   BranchID = Backbone->getType()
   nFrames  = Backbone->getValidFrameCount(DataSet.Name)

   if Method eq "APER_RADIUS7" then begin
	   radius = 7.0 ; Aperture radius to use
	   skyradii= [8,9]
   endif else if Method eq "APER_RADIUS10" then begin
		radius = 10.0 ; Aperture radius to use
	    skyradii= [15,20]
	endif

   for q=0, nFrames-1 do begin
       sz = size(*DataSet.Frames[q])
       if ( sz[0] ne 3 ) then begin
           warning, ' WARNING ('+ functionName + '): Stellar extraction requires a 3-d cube.'
       endif else if (sz[1] lt 5) then begin
           warning, ' WARNING ('+ functionName + '): Stellar extraction requires at least 5 spectral channels.'
       endif else begin
       ; create final 1-d arrays for storing data.
           	Frame       = make_array(sz[1],/FLOAT)
           	IntFrame    = make_array(sz[1],/FLOAT)
           	IntAuxFrame = make_array(sz[1],/BYTE)
           	image = make_array(sz[2],sz[3],/FLOAT) ; Temporary 2-d image to store partially collapsed cubes.
		   	;---------------------------------------------------------------

			;--- extract via aperture photometry
			if Method eq "APER_RADIUS7" or Method eq "APER_RADIUS10" then begin
			   image = median((*DataSet.Frames[q])[*,*,*],dimension=1) ; Create collapsed 2-d frame

			   ; -- Centers keyword --
			   ;  Nicholas McConnell 9/20/2010
                           ;Centers = 2D array of pre-determined object centers (1 object per frame)
		 	   ;centers[0,*] = x positions (long axis)
			   ;centers[1,*] = y positions (short axis)
			   ;The array must be saved in a FITS file.
			   ;In the XML file, add the keyword Centers="Directory/Filename"
                           if tag_exist(Modules[thisModuleIndex], "Centers") then begin 
       			       cenfile = string(Modules[thisModuleIndex].Centers)
       			       drpLog, "Using object centers from file " + cenfile, /DRF, DEPTH=1
       			       print,"Using object centers from file " + cenfile
       			       cen = readfits(cenfile,/silent)
       			       if ((size(cen))[0] eq 2 AND (size(cen))[2] ne nFrames) OR $
          			 ((size(cen))[0] eq 1 AND (size(cen))[1] ne 2) OR $
          			 ((size(cen))[0] ne 2 and (size(cen))[0] ne 1) then begin
           		           return, error("ERROR in "+strtrim(functionName)+ $
     			                         " Input: Centers array has wrong dimensions")
           		       end
			       xcen = cen[0,q]
                               ycen = cen[1,q]
   			   endif else begin
                               ;The following 3 lines are from Marshall's original code.
			       gaus = gauss2dfit(image[2:(sz[2]-2),2:(sz[3]-2)],A)
			       xcen=A[4]+2.0
			       ycen=A[5]+2.0
			   endelse
			   ; -- end Centers keyword portion --

			   thresh = ceil(radius/2)
			   if ( (xcen lt thresh) or (xcen gt (sz[2]-thresh)) or (ycen lt thresh) or $
					(ycen gt (sz[3]-thresh)) ) then begin
					  print, xcen, (sz[2]-thresh), ycen, (sz[3]-thresh)
					  return, error('ERROR IN CALL ('+strtrim(functionName)+ $
				   '): Star is too close to edge for simple aperture extraction.;)')
				  end
			   for k = 0, sz[1]-1 do begin
				   image = reform((*DataSet.Frames[q])[k,*,*])
				   aper,image,xcen,ycen,flux,errap,sky,skyerr,1.0,radius,[8,9],[-32000,32000],setskyval=0.0,/FLUX,/SILENT
				   Frame[k]=flux
				   IntFrame[k]=0.0
				   IntAuxFrame[k]=9
			   endfor
			endif
			
			;--- just total the whole cube:
			if Method eq "TOTAL" then begin
				Frame = total(total(  (*DataSet.Frames[q]), 3), 2)
				IntFrame = Frame*0
				IntAuxFrame += 9b
                        endif


			;--- PSF Fitting via Gaussian/Moffat profiles
			;    a la Conor Laver's method
			if Method eq "PSFFIT" then begin
				message, "Not implemented yet!"

			endif


                    	;---  sum a box within the cube ---
			;   Nicholas McConnell, 9/20/2010
			;This method uses an additional keyword, BoxCoords: 
			;a 2D array of coordinates specifying corners of a box
			;from which to extract a spectrum. 
                        ; 
			;The array (boxcoords) must be saved in a FITS file.
			;boxcoords[0,*] = minimum x values  (long axis)
			;boxcoords[1,*] = maximum x values
			;boxcoords[2,*] = minimum y values  (short axis)
			;boxcoords[3,*] = maximum y values
			;In the XML file, add the keyword BoxCoords="Directory/Filename"  
                        ;
                        ;This method includes replacing bad pixels (as previously
                        ;flagged in the 2nd FITS extension) with nearby values,
                        ;but does not consider PSF structure at all.
                        ;Hence, the APER methods might be better for absolute photometry.

			if Method eq "BOX" then begin 
       			    boxfile = string(Modules[thisModuleIndex].BoxCoords)
       			    drpLog, "Using box corners from file " + boxfile, /DRF, DEPTH=1
       			    print,"Using box corners from file " + boxfile
       			    box = readfits(boxfile,/silent)
       			    if ((size(box))[0] eq 2 AND ((size(box))[1] ne 4 OR (size(box))[2] ne nFrames)) OR $
          			((size(box))[0] eq 1 AND (size(box))[1] ne 4) OR $
          			((size(box))[0] ne 2 and (size(box))[0] ne 1) then begin
           			return, error("ERROR in "+strtrim(functionName)+ $
				              " Input: BoxCoords array has wrong dimensions")
           		    end
                            for k = 0, sz[1]-1 do begin
				image = reform((*DataSet.Frames[q])[k,*,*])
				bad = reform((*DataSet.IntAuxFrames[q])[k,*,*])

		                image_cut = image[box[0,q]:box[1,q],box[2,q]:box[3,q]]
                  		bad_cut = bad[box[0,q]:box[1,q],box[2,q]:box[3,q]]
                   		wbc = where(bad_cut ne 9,wbct)
                   		if wbct gt 0 then begin
                       		    image_cut[wbc] = !values.f_nan
                       		    wbx = wbc mod (box[1,q]-box[0,q]+1)
                       		    wby = wbc/(box[1,q]-box[0,q]+1)
                       		    for i=0,wbct-1 do begin
                           	    	wbx1 = wbx[i]-1 > 0 
				    	wby1 = wby[i]-1 > 0
                           	    	wbx2 = wbx[i]+1 < (box[1,q]-box[0,q]) 
				    	wby2 = wby[i]+1 < (box[3,q]-box[2,q])
                           	    	image_cut[wbx[i],wby[i]] = mean(image_cut[wbx1:wbx2,wby1:wby2],/nan)
                       		    endfor
                   		endif
                   		flux = total(image_cut,/nan)
				Frame[k]=flux
				IntFrame[k]=0.0
				IntAuxFrame[k]=9b
			    endfor
			endif

           	SXADDHIST, functionname+": Extracted star via method "+method,  *DataSet.Headers[q]

		   ;---------------------------------------------------------------

           ; Make the new cubes the valid data frames.
           tempPtr = PTR_NEW(/ALLOCATE_HEAP) ; Create a temporary reference pointer
           *tempPtr = *DataSet.Frames[q] ; Point it at the old location
           *DataSet.Frames[q]=Frame ; Set the Frames pointer to the new location
           PTR_FREE, tempPtr    ; Free the memory at the old location

           ; Make the new cubes the valid integration frames.
           tempPtr = PTR_NEW(/ALLOCATE_HEAP) ; Create a temporary reference pointer
           *tempPtr = *DataSet.IntFrames[q] ; Point it at the old location
           *DataSet.IntFrames[q]=IntFrame ; Set the Frames pointer to the new location
           PTR_FREE, tempPtr    ; Free the memory at the old location

           ; Make the new cubes the valid quality frames.
           tempPtr = PTR_NEW(/ALLOCATE_HEAP) ; Create a temporary reference pointer
           *tempPtr = *DataSet.IntAuxFrames[q] ; Point it at the old location
           *DataSet.IntAuxFrames[q]=IntAuxFrame ; Set the Frames pointer to the new location
           PTR_FREE, tempPtr    ; Free the memory at the old location

           n_dims = size(*DataSet.Frames[q])

           ; Set the correct header keywords for the array size
           SXADDPAR, *DataSet.Headers[q], "NAXIS", n_dims(0),AFTER='BITPIX'
           SXADDPAR, *DataSet.Headers[q], "NAXIS1", n_dims(1),AFTER='NAXIS'

           ; Edit file name in header to replace datset with calstar
           fname = sxpar(*DataSet.Headers[q],'DATAFILE')
           fname = fname + '_1d'
           print, fname
           SXADDPAR, *DataSet.Headers[q], "DATAFILE", fname

       end

       report_success, functionName, T
   end  ; end of for loop over files

   return, OK

end
