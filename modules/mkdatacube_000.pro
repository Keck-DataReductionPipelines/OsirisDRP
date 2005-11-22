;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;@BEGIN
; @NAME:  mkdatacube_000
;
; @PURPOSE: create a 3D cube data from a spaitially rectified 2D frame
;
; @STATUS : prototype
;
; @@@@NOTES : 
;         It is assumed that input frames are spatially rectified
;         through spatrectif_000.pro routine. 
;
;         Filter passband data should be available. The name of
;         filter information file is 'filters' and it should be
;         accessible by `DATADIR' environmental variable.
;         Currently, the file is under DRP/backbone/data/
;
; @ALGORITHM :
;         - re-ordering spectra so that the final output has a 3-D format of
;           1st dim: wavelength
;           2nd dim: lenslet X-coord (left->right)
;           3rd dim: lenslet Y-coord (up->down)
;           lenslet [0,0] is the upper-left corner of the lenslet array.
;           ;; the above order of 3-axes conforms the Euro-3D structure.
; @REQUIRED ROUTINE :
;         - lenslets.pro  : calculates locations of lenslet pupil iamges 
;                           on the detector
;         - filterinfo.pro: for a given filter, this routine calculates
;                           wavelength at the pupil image location, dispersion,
;                           min/max wavelengths, and min/max pixel coordinates 
;                           of left/right edges of spectra.
;         These two routines are at DRP/backbone/code/idl_downloads/
;
; @HISTORY : Aug 2004    created.
;           Sep 2004    changed to conform DRP module structure.
;
; @AUTHOR : created by Inseok Song (song@gemini.edu)
;          geometry and extraction redone from Oct.04-June 05 - Larkin
;@END
;-----------------------------------------------------------------------
FUNCTION mkdatacube_000, DataSet, Modules, Backbone

        COMMON APP_CONSTANTS

	functionName = 'mkdatacube_000'

	drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1

        stModule =  check_module( DataSet, Modules, Backbone, functionName )
        if ( NOT bool_is_struct ( stModule ) ) then $
           return, error ('ERROR IN CALL ('+strtrim(functionName)+'): Integrity check failed.')

        nFrames = Backbone->getValidFrameCount(DataSet.Name)

        for i = 0, nFrames-1 do begin

           ; Spectral offsets and extraction areas added 10/12/2004 (JEL)
           filter_name = STRUPCASE(strg(sxpar( *DataSet.Headers[i], 'SFILTER')))
           if (strlen(filter_name) NE 3) then $
               return, error ( ['FAILURE (' + strtrim(functionName,2) + '):', $
                                '        In Set ' + strtrim(string(i+1),2) + $
                                ' filter name ('+strg(filter_name)+') is invalid.'] )

           debug_info, 'DEBUG INFO ('+strtrim(functionName)+'): Working on '$
              +strg(filter_name)+' data.'

           if ( filter_name EQ 'ZN5') then begin
               narrow = 1
               lam_offset = -454   ; 1st valid pixel in 1st spectrum
               delta = 472        ; distance in pixels to next spectrum in same row of rectified data
               print, "Zn5 filter identified"
               nrows = 66
               ncols = 51
               nwave = 400
               nspec = 1024       ; == 16*64 (narrowband data comes in compressed into 1024 rows)
           endif else if ( filter_name EQ 'ZN2') then begin
               narrow = 1
               lam_offset = 480   ; 1st valid pixel in 1st spectrum
               delta = 472        ; distance in pixels to next spectrum in same row of rectified data
               print, "Zn2 filter identified"
               nrows = 66
               ncols = 51
               nwave = 500
               nspec = 1024       ; == 16*64 (narrowband data comes in compressed into 1024 rows)
           endif else if ( filter_name EQ 'ZN3') then begin
               narrow = 1
               lam_offset = 180   ; 1st valid pixel in 1st spectrum
               delta = 472        ; distance in pixels to next spectrum in same row of rectified data
               print, "Zn3 filter identified"
               nrows = 66
               ncols = 51
               nwave = 500
               nspec = 1024       ; == 16*64 (narrowband data comes in compressed into 1024 rows)
           endif else if ( filter_name EQ 'ZN4') then begin
               narrow = 1
               lam_offset = -133   ; 1st valid pixel in 1st spectrum
               delta = 472        ; distance in pixels to next spectrum in same row of rectified data
               print, "Zn4 filter identified"
               nrows = 66
               ncols = 51
               nwave = 500
               nspec = 1024       ; == 16*64 (narrowband data comes in compressed into 1024 rows)
           endif else if ( filter_name EQ 'JN1') then begin
               narrow = 1
               lam_offset = 783   ; 1st valid pixel in 1st spectrum
               delta = 472        ; distance in pixels to next spectrum in same row of rectified data
               print, "Jn1 filter identified"
               nrows = 66
               ncols = 51
               nwave = 500
               nspec = 1024       ; == 16*64 (narrowband data comes in compressed into 1024 rows)
           endif else if ( filter_name EQ 'JN2') then begin
               narrow = 1
               lam_offset = 451   ; 1st valid pixel in 1st spectrum
               delta = 472        ; distance in pixels to next spectrum in same row of rectified data
               print, "Jn2 filter identified"
               nrows = 66
               ncols = 51
               nwave = 500
               nspec = 1024       ; == 16*64 (narrowband data comes in compressed into 1024 rows)
           endif else if ( filter_name EQ 'JN3') then begin
               narrow = 1
               lam_offset = 161   ; 1st valid pixel in 1st spectrum
               delta = 472        ; distance in pixels to next spectrum in same row of rectified data
               print, "Jn3 filter identified"
               nrows = 66
               ncols = 51
               nwave = 500
               nspec = 1024       ; == 16*64 (narrowband data comes in compressed into 1024 rows)
           endif else if ( filter_name EQ 'JN4') then begin
               narrow = 1
               lam_offset = -130   ; 1st valid pixel in 1st spectrum
               delta = 472        ; distance in pixels to next spectrum in same row of rectified data
               print, "Jn4 filter identified"
               nrows = 66
               ncols = 51
               nwave = 500
               nspec = 1024       ; == 16*64 (narrowband data comes in compressed into 1024 rows)
           endif else if ( filter_name EQ 'HN1') then begin
               narrow = 1
               lam_offset = 778   ; 1st valid pixel in 1st spectrum
               delta = 472        ; distance in pixels to next spectrum in same row of rectified data
               print, "Hn1 filter identified"
               nrows = 66
               ncols = 51
               nwave = 500
               nspec = 1024       ; == 16*64 (narrowband data comes in compressed into 1024 rows)
           endif else if ( filter_name EQ 'HN2') then begin
               narrow = 1
               lam_offset = 457   ; 1st valid pixel in 1st spectrum
               delta = 472        ; distance in pixels to next spectrum in same row of rectified data
               print, "Hn2 filter identified"
               nrows = 66
               ncols = 51
               nwave = 500
               nspec = 1024       ; == 16*64 (narrowband data comes in compressed into 1024 rows)
           endif else if ( filter_name EQ 'HN3') then begin
               narrow = 1
               lam_offset = 150   ; 1st valid pixel in 1st spectrum
               delta = 472        ; distance in pixels to next spectrum in same row of rectified data
               print, "Hn3 filter identified"
               nrows = 66
               ncols = 51
               nwave = 500
               nspec = 1024       ; == 16*64 (narrowband data comes in compressed into 1024 rows)
           endif else if ( filter_name EQ 'HN4') then begin
               narrow = 1
               lam_offset = -133   ; 1st valid pixel in 1st spectrum
               delta = 472        ; distance in pixels to next spectrum in same row of rectified data
               print, "Hn4 filter identified"
               nrows = 66
               ncols = 51
               nwave = 500
               nspec = 1024       ; == 16*64 (narrowband data comes in compressed into 1024 rows)
           endif else if ( filter_name EQ 'HN5') then begin
               narrow = 1
               lam_offset = -463   ; 1st valid pixel in 1st spectrum
               delta = 472        ; distance in pixels to next spectrum in same row of rectified data
               print, "Hn5 filter identified"
               nrows = 66
               ncols = 51
               nwave = 500
               nspec = 1024       ; == 16*64 (narrowband data comes in compressed into 1024 rows)
           endif else if ( filter_name EQ 'KN1') then begin
               narrow = 1
               lam_offset = 777   ; 1st valid pixel in 1st spectrum
               delta = 472        ; distance in pixels to next spectrum in same row of rectified data
               print, "Kn1 filter identified"
               nrows = 66
               ncols = 51
               nwave = 500
               nspec = 1024       ; == 16*64 (narrowband data comes in compressed into 1024 rows)
           endif else if ( filter_name EQ 'KN2') then begin
               narrow = 1
               lam_offset = 470   ; 1st valid pixel in 1st spectrum
               delta = 472        ; distance in pixels to next spectrum in same row of rectified data
               print, "Kn2 filter identified"
               nrows = 66
               ncols = 51
               nwave = 500
               nspec = 1024       ; == 16*64 (narrowband data comes in compressed into 1024 rows)
           endif else if ( filter_name EQ 'KN3') then begin
               narrow = 1
               lam_offset = 170   ; 1st valid pixel in 1st spectrum
               delta = 472        ; distance in pixels to next spectrum in same row of rectified data
               print, "Kn3 filter identified"
               nrows = 66
               ncols = 51
               nwave = 500
               nspec = 1024       ; == 16*64 (narrowband data comes in compressed into 1024 rows)
           endif else if ( filter_name EQ 'KN4') then begin
               narrow = 1
               lam_offset = -130   ; 1st valid pixel in 1st spectrum
               delta = 472        ; distance in pixels to next spectrum in same row of rectified data
               print, "Kn4 filter identified"
               nrows = 66
               ncols = 51
               nwave = 500
               nspec = 1024       ; == 16*64 (narrowband data comes in compressed into 1024 rows)
           endif else if ( filter_name EQ 'KN5') then begin
               narrow = 1
               lam_offset = -454   ; 1st valid pixel in 1st spectrum
               delta = 472        ; distance in pixels to next spectrum in same row of rectified data
               print, "Kn5 filter identified"
               nrows = 66
               ncols = 51
               nwave = 500
               nspec = 1024       ; == 16*64 (narrowband data comes in compressed into 1024 rows)
           endif else if ( filter_name EQ 'KBB' ) then begin
               narrow = 0
               lam_offset = -30   ; 1st valid pixel in 1st spectrum
               print, "Kbb filter identified"
               nrows = 64         
               ncols = 19
               nwave = 1700
               nspec = 1216       ; == 19*64 (whole broadband lenslet array including unilluminated lenslets)
           endif else if ( filter_name EQ 'HBB' ) then begin
               narrow = 0
               lam_offset = -30   ; 1st valid pixel in 1st spectrum
               print, "Hbb filter identified"
               nrows = 64         
               ncols = 19
               nwave = 1700
               nspec = 1216       ; == 19*64 (whole broadband lenslet array including unilluminated lenslets)
           endif else begin
               narrow = 0         ; default case is broad-band
               lam_offset = 0
               nrows = 64         
               ncols = 19         
               nwave = 1700
               nspec = 1216       ; == 19*64 (whole broadband lenslet array including unilluminated lenslets)
;        if (strupcase(strmid(filter_name,1,1)) NE 'N') then narrow=1
           end

           Frame       = make_array(nwave,nrows,ncols,/FLOAT)
           IntFrame    = make_array(nwave,nrows,ncols,/FLOAT)
           IntAuxFrame = make_array(nwave,nrows,ncols,/BYTE)
                     
           if (not narrow) then begin
              print, "Broad band cube"
              for sp = 0, nspec-1 do begin
                 row = sp mod nrows
                 col = floor(sp/nrows)

                 ; Changed indexing to ~align spectra
;                for ix = filter_info.dxpmin, filter_info.dxpmax do begin
;                   p = lens_pxy[0,sp] + ix
                 for l = 0, nwave-1 do begin
                    p = l-(row*2)+fix(col*29.625)+lam_offset
                    if ((p GE 0) AND (p LE 2047)) then begin
                       Frame[l,row,col]       = (*DataSet.Frames[i])[p,sp]
                       IntFrame[l,row,col]    = (*DataSet.IntFrames[i])[p,sp]
                       IntAuxFrame[l,row,col] = (*DataSet.IntAuxFrames[i])[p,sp]
                    endif
                  endfor
               endfor
            ; narrrowband case.
            endif else if (narrow) then begin
            ; Narrow-Band spectra extraction algorithm.
            ;
            ; need to extract narrow band spectra from the compact format!!!
            ; first, for each central-region lenslets (e.g., common lenslets of
            ; broadband and narrowband), look for lenslets used only in narrowband which have
            ; the same detector-Y pixel coordinate as the central-region lenslets. 
            ; There should be two such lenslets per one given central-region lenslet.
            ; 
            ; Then, read in narrowband spectral overlap information (see NBpackCAL.c for details),
            ; compare dxpmin, dxpmax, spectral overlap location to choose a range of spectrum
            ; extraction for three spectra from one compact NB spectrum.
            ;
            ; Finally, such extractions should be done on Frames, IntFrames, and IntAuxFrames.
               for sp = 0, nspec-1 do begin
                  for l = 0, nwave-1 do begin
                  ; Extract 1st block of 16x64 spectra
                     row = (sp mod (nrows-2))
                     col = floor(sp/(nrows-2))
                     p = l-(row*2)+fix(col*29.625)+lam_offset
                     row = row+2
                     col = col+3
                     if ((p GE 0) AND (p LE 2047) AND (row lt nrows) ) then begin
                         Frame[l,row,col]       = (*DataSet.Frames[i])[p,sp]
                         IntFrame[l,row,col]    = (*DataSet.IntFrames[i])[p,sp]
                         IntAuxFrame[l,row,col] = (*DataSet.IntAuxFrames[i])[p,sp]
                     endif
                     ; Extract 2nd block of 16x64 spectra
                     row = (sp mod (nrows-2))
                     col = floor(sp/(nrows-2))
                     p = l-(row*2)+fix(col*29.625)+lam_offset+delta
                     row = row+1
                     col = col + 16 +3
                     if ((p GE 0) AND (p LE 2047) AND (row lt nrows) AND (col lt ncols)) then begin
                        Frame[l,row,col]       = (*DataSet.Frames[i])[p,sp]
                        IntFrame[l,row,col]    = (*DataSet.IntFrames[i])[p,sp]
                        IntAuxFrame[l,row,col] = (*DataSet.IntAuxFrames[i])[p,sp]
                     endif
                     ; Extract 3rd block of 16x64 spectra
                     row = (sp mod (nrows-2))
                     col = floor(sp/(nrows-2))
                     p = l-(row*2)+fix(col*29.625)+lam_offset+2*delta
                     row = row
                     col = col + 32 +3
                     if ((p GE 0) AND (p LE 2047) AND (col lt ncols)) then begin
                        Frame[l,row,col]       = (*DataSet.Frames[i])[p,sp]
                        IntFrame[l,row,col]    = (*DataSet.IntFrames[i])[p,sp]
                        IntAuxFrame[l,row,col] = (*DataSet.IntAuxFrames[i])[p,sp]
                     endif
                     ; Extract tidbit of 4th block of 16x64 spectra
                     if ( sp gt 831 ) then begin
                         row = (sp mod (nrows-2))
                         col = floor(sp/(nrows-2))
                         p = l-(row*2)+fix(col*29.625)+lam_offset-delta
                         row = row+2
                         col = col-16+3
                         if ((col lt 3) and (col ge 0) AND (p GE 0) AND (p LE 2047) AND (row lt nrows) AND (col lt ncols)) then begin
                             Frame[l,row,col]       = (*DataSet.Frames[i])[p,sp]
                             IntFrame[l,row,col]    = (*DataSet.IntFrames[i])[p,sp]
                             IntAuxFrame[l,row,col] = (*DataSet.IntAuxFrames[i])[p,sp]
                         endif
                     endif
                endfor
            endfor

               endif ;narrowband if

               ; returning new data by using old pointers.
               ; Image Frames
               tempPtr = PTR_NEW(/ALLOCATE_HEAP)     ; Create a new, temporary, pointer variable
               *tempPtr = *DataSet.Frames[i]         ; Use it to save a pointer to the old data
               *DataSet.Frames[i] = Frame
               PTR_FREE, tempPtr

               ; Integration Frames
               tempPtr = PTR_NEW(/ALLOCATE_HEAP)     ; Create a new, temporary, pointer variable
               *tempPtr = *DataSet.IntFrames[i]      ; Use it to save a pointer to the old data
               *DataSet.IntFrames[i] = IntFrame
               PTR_FREE, tempPtr

               ; Quality Frames (Integration Auxiliary Frames)
               tempPtr = PTR_NEW(/ALLOCATE_HEAP)     ; Create a new, temporary, pointer variable
               *tempPtr = *DataSet.IntAuxFrames[i]   ; Use it to save a pointer to the old data
               *DataSet.IntAuxFrames[i] = IntAuxFrame
               PTR_FREE, tempPtr

               n_dims = size(*DataSet.Frames[i])

   	       SXADDPAR, *DataSet.Headers[i], "NAXIS", n_dims(0),AFTER='BITPIX'
   	       SXADDPAR, *DataSet.Headers[i], "NAXIS1", n_dims(1),AFTER='NAXIS'
   	       SXADDPAR, *DataSet.Headers[i], "NAXIS2", n_dims(2),AFTER='NAXIS1'
	       SXADDPAR, *DataSet.Headers[i], "NAXIS3", n_dims(3),AFTER='NAXIS2'

            endfor ; repeat on nFrames
	 END ; end case of BranchID...

      ELSE: drpLog, 'FUNCTION '+ functionName +': CASE error: Bad Type = ' + BranchID, /DRF, DEPTH = 2
;	ENDCASE

      RETURN, OK

END
