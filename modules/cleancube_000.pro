;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; NAME:  cleancube_000
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
FUNCTION cleancube_000, DataSet, Modules, Backbone

COMMON APP_CONSTANTS

functionName = 'cleancube_000'
thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
T = systime(1)
neigh = fltarr(5) ; A temporary array to hold the nearest neighbors of a pixel

drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1

; get the parameters
upper_limit=float(Modules[thisModuleIndex].upper_limit)
lower_limit=float(Modules[thisModuleIndex].lower_limit)

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

    ; assume this cube is not rotated
    ; rotate the cube to have the spatial dimensions forward
    axesorder=[2,1,0]
    im=transpose(Frame, axesorder)
    newim=im
    cube_sz=size(im, /dimensions)    
    for k=0,cube_sz[2]-1 do begin
        ; clean each channel
        for i2=0,cube_sz[0]-1 do begin
            for j=0,cube_sz[1]-1 do begin
                ; see which pixels are valid around this point
                inc=1
                xstart=i2-inc
                if (xstart lt 0) then xstart=0
                xend=i2+inc
                if (xend gt cube_sz[0]-1) then xend=cube_sz[0]-1
                ystart=j-inc
                if (ystart lt 0) then ystart=0
                yend=j+inc
                if (yend gt cube_sz[1]-1) then yend=cube_sz[1]-1
                ; make a subaperture
                subap_im=im[xstart:xend,ystart:yend,k]
                ind=where((subap_im ne im[i2,j,k]) and (subap_im ne 0.))
                if ind[0] eq -1 then ind[0]=0
                ; check for a minimum number of pixels
                if (size(subap_im[ind], /n_elements) gt 6) then begin
                    ; calc the stdev and mean
                    im_stdev=stddev(subap_im[ind])
                    im_mean=mean(subap_im[ind])
                    ; fix bad pixels
                    if ((im[i2,j,k]-im_mean) gt (upper_limit*im_stdev)) then begin
                        newim[i2,j,k]=im_mean
                    endif
                    if ((im[i2,j,k]-im_mean) lt (lower_limit*im_stdev)) then begin
                        newim[i2,j,k]=im_mean
                    endif
                endif                
            endfor
        endfor
    endfor

    print, '*** cleaning cube finished 2 ***'

    axesorder=[2,1,0]
    tim=transpose(newim, axesorder)
    *DataSet.Frames[i] = tim
endfor

report_success, functionName, T
RETURN, OK

END
