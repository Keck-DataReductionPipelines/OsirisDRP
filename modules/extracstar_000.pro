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
			   gaus = gauss2dfit(image[2:(sz[2]-2),2:(sz[3]-2)],A)
			   xcen=A[4]+2.0
			   ycen=A[5]+2.0
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
           SXADDPAR, *DataSet.Headers[q], "NAXIS", n_dims[0],AFTER='BITPIX'
           SXADDPAR, *DataSet.Headers[q], "NAXIS1", n_dims[1],AFTER='NAXIS'

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
