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
;
; @AUTHOR  James Larkin
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

   ; midwave is a wavelength offset used to make the poly fit symmetric in wavelength
   ; This must match what is in the routine that fits raw spectra: plot_fwhm
   midwave = 2200

   ; Determine if this is broad band or narrow band data.
   bb = strcmp('bb',strmid(s_Filter,1,2))
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

   ; Create a lookup table of wavelengths for each of the spectral slices.
   lambda = disp*findgen(npix)+minl

   ; Scale the wavelength to the 3rd order where the fit was determined
   ; and add midwave.
   lambda = lambda * float(order) / 3.0
   lambda = lambda - midwave

   ; Read in the matrix of coefficients used for fitting pixel as a function
   ; of wavelength
   coeffs = readfits(s_CoeffFile)
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
   abscissa = findgen(2048)  ; Look up table for interpolated values

   for q=0, nFrames-1 do begin
       if ( bb eq 1 ) then begin
           ; Broad band data.
           for sp = 0, nspec-1 do begin
               row = sp mod nrows ; Where in final cube to place data
               col = floor(sp/nrows) ; Where in final cube to place data
               j = row + 1           ; Where to look in coeffs for solution
               i = col + first_col   ; Where to look in coeffs for solution
               if ( complete[i,j] eq 1 ) then begin ; Valid pixel
                   pixels = poly(lambda,coeffs[*,i,j]) ; Map the desired wavelengths into the original pixels
                   good = where( (*DataSet.IntAuxFrames[q])[*,sp] eq 9 )
                   Frame[*,row,col]=interpol((*DataSet.Frames[q])[good,sp],abscissa[good],pixels)
                   IntFrame[*,row,col]=interpol((*DataSet.IntFrames[q])[good,sp],abscissa[good],pixels)
                   IntAuxFrame[*,row,col]=9
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
                    Frame[*,row,col]=interpol((*DataSet.Frames[q])[good,sp],abscissa[good],pixels)
                    IntFrame[*,row,col]=interpol((*DataSet.IntFrames[q])[good,sp],abscissa[good],pixels)
                    IntAuxFrame[*,row,col]=9
                endif
                ; Extract 2nd block of 16x64 spectra
                row = (sp mod (nrows-2))+1
                col = floor(sp/(nrows-2))+16+3
                j = row
                i = col
                if ( complete[i,j] eq 1 ) then begin
                    pixels = poly(lambda,coeffs[*,i,j]) ; Map the desired wavelengths into the original pixels
                    good = where( (*DataSet.IntAuxFrames[q])[*,sp] eq 9 )
                    Frame[*,row,col]=interpol((*DataSet.Frames[q])[good,sp],abscissa[good],pixels)
                    IntFrame[*,row,col]=interpol((*DataSet.IntFrames[q])[good,sp],abscissa[good],pixels)
                    IntAuxFrame[*,row,col]=9
                endif
                ; Extract 3rd block of 16x64 spectra
                row = (sp mod (nrows-2))
                col = floor(sp/(nrows-2))+32+3
                j = row
                i = col
                if ( complete[i,j] eq 1 ) then begin
                    pixels = poly(lambda,coeffs[*,i,j]) ; Map the desired wavelengths into the original pixels
                    good = where( (*DataSet.IntAuxFrames[q])[*,sp] eq 9 )
                    Frame[*,row,col]=interpol((*DataSet.Frames[q])[good,sp],abscissa[good],pixels)
                    IntFrame[*,row,col]=interpol((*DataSet.IntFrames[q])[good,sp],abscissa[good],pixels)
                    IntAuxFrame[*,row,col]=9
                endif
                ; Extract extract few spectra
                if ( sp gt 831 ) then begin
                    row = (sp mod (nrows-2))+2
                    col = floor(sp/(nrows-2))-16+3
                    j = row
                    i = col
                    if ( complete[i,j] eq 1 ) then begin
                        pixels = poly(lambda,coeffs[*,i,j]) ; Map the desired wavelengths into the original pixels
                        good = where( (*DataSet.IntAuxFrames[q])[*,sp] eq 9 )
                        Frame[*,row,col]=interpol((*DataSet.Frames[q])[good,sp],abscissa[good],pixels)
                        IntFrame[*,row,col]=interpol((*DataSet.IntFrames[q])[good,sp],abscissa[good],pixels)
                        IntAuxFrame[*,row,col]=9
                    endif
                endif
            end
        end

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
        *DataSet.IntAuxFrames[q]=IntAuxFrame          ; Set the Frames pointer to the new location
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
        
        ; Set the wavelength keywords.
        sxaddpar, *DataSet.Headers[q], 'CDELT1', disp
        sxaddpar, *DataSet.Headers[q], 'CRVAL1', minl
        sxaddpar, *DataSet.Headers[q], 'CRPIX1', 1
        sxaddpar, *DataSet.Headers[q], 'CUNIT1', 'nm'

    end


   ; update the header
;   for i=0, nFrames-1 do begin
;       if ( verify_naxis ( DataSet.Frames(i), DataSet.Headers(i), /UPDATE ) ne OK ) then begin
;           return, error('FAILURE ('+strtrim(functionName)+'): Update of header failed.')
;       end
;   end
  
   report_success, functionName, T

   return, OK

end
