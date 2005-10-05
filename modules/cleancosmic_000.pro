;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; NAME:  cleancosmic_000
;
; PURPOSE: Attempts to identify and remove pixele that are damaged by
; cosmic rays. It only works on 3-d cubes.
;
; STATUS : prototype
;
; NOTES : 
;         It is assumed that input frames have been made into cubes and
;         are linear in wavelength. This allows it to compare pixels
;         within the same slice.
;
; ALGORITHM :
; REQUIRED ROUTINE :
;
; HISTORY : Oct 3, 2005    created
;
; AUTHOR : created by James Larkin
;-----------------------------------------------------------------------
FUNCTION cleancosmic_000, DataSet, Modules, Backbone

COMMON APP_CONSTANTS

functionName = 'cleancosmic_000'
neigh = fltarr(5) ; A temporary array to hold the nearest neighbors of a pixel

drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1

nFrames = Backbone->getValidFrameCount(DataSet.Name)

; Check the first file to see if this is broad or narrowband data.
filter_name = STRUPCASE(strg(sxpar( *DataSet.Headers[0], 'SFILTER')))
if (strlen(filter_name) NE 3) then $
  return, error ( ['FAILURE (' + strtrim(functionName,2) + '):', $
                   '        In Set ' + strtrim(string(i+1),2) + $
                   ' filter name ('+strg(filter_name)+') is invalid.'] )
print, 'Filter_name=',filter_name
    
; Determine if the cube is a narrow band or broad band cube.
if ( STRMID(filter_name, 1,2) EQ 'BB') then begin
    nrows=19
    ncols=64
endif else begin
    nrows=66
    ncols=51
end

for i = 0, nFrames-1 do begin
    ; Setup local pointers to the frames
    Frame       = *DataSet.Frames[i]
    IntFrame    = *DataSet.IntFrames[i]
    IntAuxFrame = *DataSet.IntAuxFrames[i]
    sz = size(Frame)
    if ( sz[0] ne 3 ) then $
      return, error ( ['FAILURE (' + strtrim(functionName,2) + '):', $
                       '        In Set ' + strtrim(string(i+1),2) + $
                       ' Frame must be 3 dimensional.'] )
    if ( sz[2] lt 15 ) then $
      return, error ( ['FAILURE (' + strtrim(functionName,2) + '):', $
                       '        In Set ' + strtrim(string(i+1),2) + $
                       ' X-Spatial axis is smaller than 10 pixels.'] )
    if ( sz[3] lt 15 ) then $
      return, error ( ['FAILURE (' + strtrim(functionName,2) + '):', $
                       '        In Set ' + strtrim(string(i+1),2) + $
                       ' Y-Spatial axis is smaller than 10 pixels.'] )
    ; Setup an array that contains the boundaries for a measurement of the
    ; noise in each slice of the frame
    sarr=[4, (sz[2]-5), 4, (sz[3]-5)]
    for lam = 0, (sz[1]-1) do begin
        q = Frame[lam, sarr[0]:sarr[1], sarr[2]:sarr[3]]
        iq = IntFrame[lam, sarr[0]:sarr[1], sarr[2]:sarr[3]]
        iaq = IntAuxFrame[lam, sarr[0]:sarr[1], sarr[2]:sarr[3]]
        nsz = size(q,/N_ELEMENTS)
        if (nsz gt 50) then begin
            ind = sort(q)
            med = median(q[ind[24:nsz-24]])
            stdev = stddev(q[ind[24:nsz-24]])
            ; Write the gloabl stdev and med in the upper left corner.
            for j = 0, sz[2]-1 do begin
                for k = 0, sz[3]-1 do begin
                                ; For each pixel, create an array
                                ; containing its closest valid
                                ; neighbors
                    numb=0
                    if ( (j-1) ge 0 ) then begin
                        if ( IntAuxFrame[lam,j-1,k] ne 0 ) then begin
                            neigh[numb]=Frame[lam,j-1,k]
                            numb=numb+1
                        end
                    end
                    if ( (j+1) lt sz[2] ) then begin
                        if ( IntAuxFrame[lam,j+1,k] ne 0 ) then begin
                            neigh[numb]=Frame[lam,j+1,k]
                            numb=numb+1
                        end
                    end
                    if ( (k-1) ge 0 ) then begin
                        if ( IntAuxFrame[lam,j,k-1] ne 0 ) then begin
                            neigh[numb]=Frame[lam,j,k-1]
                            numb=numb+1
                        end
                    end
                    if ( (k+1) lt sz[3] ) then begin
                        if ( IntAuxFrame[lam,j,k+1] ne 0 ) then begin
                            neigh[numb]=Frame[lam,j,k+1]
                            numb=numb+1
                        end
                    end
                    if ( IntAuxFrame[lam,j,k] ne 0 ) then begin
                        neigh[numb]=Frame[lam,j,k]
                        numb=numb+1
                    end
                    if ( numb gt 3 ) then begin
                        m = median(neigh[0:(numb-1)])
                        testm = 3.0*abs(m)
                        if ( IntAuxFrame[lam,j,k] eq 0) then begin
                            Frame[lam,j,k]=m
                        endif else begin
                            if ( abs(Frame[lam,j,k]) gt (testm>(3.0*stdev)) ) then begin
                                Frame[lam,j,k]=m
                            end
                        end
                    end

                end
            end
            Frame[lam,sz[2]-2,0] = stdev
            Frame[lam,sz[2]-1,0] = med
        end
    end
    *DataSet.Frames[i] = Frame

endfor                          ; repeat on nFrames

RETURN, OK

END
