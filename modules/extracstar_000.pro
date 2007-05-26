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

FUNCTION extracstar_000, DataSet, Modules, Backbone

   COMMON APP_CONSTANTS

   functionName = 'extracstar_000'

   ; save starting time
   T = systime(1)

   drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1


   BranchID = Backbone->getType()
   nFrames  = Backbone->getValidFrameCount(DataSet.Name)

   radius = 7.0 ; Aperture radius to use

   sz = size(*DataSet.Frames[0])
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

       for q=0, nFrames-1 do begin
           image = median((*DataSet.Frames[q])[*,*,*],1) ; Create collapsed 2-d frame
           gaus = gauss2dfit(image[2:(sz[2]-2),2:(sz[3]-2)],A)
           xcen=A[4]+2.0
           ycen=A[5]+2.0
           for k = 0, s[0]-1 do begin
               aper,(*DataSet.Frames[q])[k,*,*],xcen,ycen,flux,errap,sky,skyerr,1.0,radius,[8,9],[-32000,32000],setskyval=0.0,/FLUX,/SILENT
               Frame[k]=flux
               IntFrame[k]=0.0
               IntAuxFrame[k]=9
           endfor

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

       end

       report_success, functionName, T
   end


   return, OK

end
