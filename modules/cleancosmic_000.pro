;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; NAME:  cleancosmic_000
;
; PURPOSE: Attempts to identify and remove pixele that are damaged by
; cosmic rays. It only works on 2-d cubes.
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
; OPTIONAL ARGUMENTS: 
;                      Faint_Extended:  If set, routine applies a simple 3-sigma cut 
;				        (computed over 100x100-pixel subregions)
;                                       after the primary cleaning iterations. 
;
;                                    WARNING:  Faint_Extended can cause serious data artifacts with
;                                              bright sources!!  Use is recommended only for
;                                              faint sources with long exposure times.
;
;                                    In XML files, call Faint_Extended with the tag:
;                                    <module Name="Clean Cosmic Rays" Faint_Extended="YES") />
;
;                      Mask:  Name of file with a mask for pixels that should be ignored
;			      in cleaning step (this is an optional file to use if Faint_Extended
;                             is set; it will only be used with Faint_Extended). 
;                             Good for ignoring bright OH line regions when computing 3-sigma
;                             cut.  In mask file, 1 = OK ; 0 = IGNORE.
;
;                             In XML files, specify a mask file with the tag:
;                             <module Name="Clean Cosmic Rays" Faint_Extended="YES" Mask="[filename]" />
;
;
; HISTORY : Oct 3, 2005    created
;           June 8, 2006   modified to work on raw data instead of cubes
;           Aug 25, 2008   Faint_Extended and Mask arguments added: N. McConnell
;
; AUTHOR : created by James Larkin
;-----------------------------------------------------------------------
FUNCTION cleancosmic_000, DataSet, Modules, Backbone

COMMON APP_CONSTANTS

functionName = 'cleancosmic_000'

drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1

nFrames = Backbone->getValidFrameCount(DataSet.Name)
indx = lindgen(100)

thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)

;Optional Arguments
if tag_exist( Modules[thisModuleIndex], "Faint_Extended") then $
  exclean = string(Modules[thisModuleIndex].Faint_Extended) $
else $
  exclean="NO"
print,""
print,"Faint Extended step: "+exclean
if strupcase(exclean) eq "YES" then begin
    warning, ' WARNING ('+ functionName + '): Faint_Extended is an aggressive cleaning step ' $
              +'recommended ONLY for faint, extended targets.' 
    warning, ' WARNING ('+ functionName + '): Faint_Extended can ruin bright or compact objects.'
endif

if tag_exist( Modules[thisModuleIndex], "Mask") then begin
    maskf = drpXlateFileName(Modules[thisModuleIndex].Mask) 
    ;mask = string(Modules[thisModuleIndex].Mask)
    mask = readfits(maskf,/silent)  
endif else begin 
    maskf = "none"
    mask = bytarr(2048,2048)+1b
endelse
print,"Mask file: "+maskf
print,""


for i = 0, nFrames-1 do begin
    ; Setup local pointers to the frames
    Frame       = *DataSet.Frames[i]
    IntFrame    = *DataSet.IntFrames[i]
    IntAuxFrame = *DataSet.IntAuxFrames[i]
    sz = size(Frame)
    if ( sz[0] ne 2 ) then $
      return, error ( ['FAILURE (' + strtrim(functionName,2) + '):', $
                       '        In Set ' + strtrim(string(i+1),2) + $
                       ' Frame must be 2 dimensional.'] )
    if ( sz[1] ne 2048 ) then $
      return, error ( ['FAILURE (' + strtrim(functionName,2) + '):', $
                       '        In Set ' + strtrim(string(i+1),2) + $
                       ' X-Spatial axis is not 2048 pixels.'] )
    if ( sz[2] ne 2048 ) then $
      return, error ( ['FAILURE (' + strtrim(functionName,2) + '):', $
                       '        In Set ' + strtrim(string(i+1),2) + $
                       ' Y-Spatial axis is not 2048 pixels.'] )


    ; Primary Cleaning Steps
    ; Repeat search for bad pixels twice
    ;  NJM TODO: add iteration # as an option for this module
    for qq = 0, 1 do begin

        ; Step through the array horizontally in 97 pixel increments
        for j = 0, 2047 do begin

            for ii = 0, 1947, 97 do begin
                smalla=Frame[ii:ii+99, j] ; 100 pixel strip of data
                smallb=IntAuxFrame[ii:ii+99, j] ; Bad pixel strip
                isok = where( smallb eq 9 )
                notok = where( smallb ne 9)
                if ( isok[0] ne -1 ) then begin
                    osz = size(isok)
                    if ( osz[1] gt 20 ) then begin
                        srt = sort(smalla[isok])
                        sz = size(srt)
                        q = srt[10:sz[1]-10]
                        std = stddev(smalla[q])
                        compare = abs(smalla) > 3.0*std

                        if ( notok[0] ne -1) then compare[notok]=3.0*std
                        rat = abs(smalla[indx]) / (compare[0>indx-1]+compare[99<indx+1])
                        bad = where(rat gt 1.2)
                        rat[*] = 1.0
                        if ( bad[0] ne -1 ) then rat[bad]=0.0
                        IntAuxFrame[ii+1:ii+98,j] = intAuxFrame[ii+1:ii+98,j]*rat[1:98]
                    end
                end
            end
        end
        bad = where(IntAuxFrame ne 9)
        Frame[bad] = 0.0
    end


    ;Faint_Extended Step
    if strupcase(exclean) eq "YES" then begin

        ; Step through the array in 97*97 pixel increments
        for j = 0, 1947, 97 do begin

            for ii = 0, 1947, 97 do begin
                smalla=Frame[ii:ii+99, j:j+99] ; 100 x 100 pixel box
                smallb=IntAuxFrame[ii:ii+99, j:j+99] ; Bad pixel box
                isok = where( smallb eq 9 AND mask ne 0)
                notok = where( smallb ne 9 OR mask eq 0)
                if ( isok[0] ne -1 ) then begin
                    osz = size(isok)
                    if ( osz[1] gt 200 ) then begin
                        srt = sort(smalla[isok])
                        sz = size(srt)
                        q = srt[100:sz[1]-100]
                        std = stddev(smalla[q])
                        medij = median(smalla[isok])
                        compare = abs(smalla-medij) > 3.0*std

                        if ( notok[0] ne -1) then compare[notok]=0
                        bad = where(compare gt 3.0*std)
                        compare[*,*] = 1.0
                        if ( bad[0] ne -1 ) then compare[bad] = 0.0

                        ;DeBugging
                        ;if ( bad[0] ne -1 ) then begin 
                        ;    compare[bad]=0.0
                        ;    if (size(bad))[3] gt 0.1*(size(smalla))[4] then begin
                        ;        print,"Suspicious number of bad pix detected near "$
                        ;          +string(ii+50,format="(i4)")+", "+string(j+50,format="(i4)")
                        ;        print,"Median = "+string(medij,format="(f7.5)")
                                ;print,"Nominal Median from "$
                                ;  +string(smalla[srt[0.5*sz[1]-1]],format="(f7.5)")+" "$
                                ;  +string(smalla[srt[0.5*sz[1]]],format="(f7.5)")+" "$
                                ;  +string(smalla[srt[0.5*sz[1]+1]],format="(f7.5)")
                                ;print,"Sort Size: ",sz
    			;	print,"StDev = "+string(std,format="(f6.4)")
                        ;        print,""
                        ;    endif
                        ;    if (ii eq 970 AND j eq 970) OR (ii eq 970 AND j eq 1067) OR $
                        ;     (ii eq 970 AND j eq 1164) then begin
                        ;        print,"Normal box near "$
                        ;          +string(ii+50,format="(i4)")+", "+string(j+50,format="(i4)")
                        ;        print,"Median = "+string(medij,format="(f7.5)")
                                ;print,"Nominal Median from "$
                                ;  +string(smalla[srt[0.5*sz[1]-1]],format="(f7.5)")+" "$
                                ;  +string(smalla[srt[0.5*sz[1]]],format="(f7.5)")+" "$
                                ;  +string(smalla[srt[0.5*sz[1]+1]],format="(f7.5)")
                                ;print,"Sort Size: ",sz
    			;	print,"StDev = "+string(std,format="(f6.4)")
                        ;        print,""
                        ;    endif
                        ;endif
                        ;end DeBugging 

                        IntAuxFrame[ii+1:ii+98,j+1:j+98] = $ 
                          intAuxFrame[ii+1:ii+98,j+1:j+98]*compare[1:98,1:98]
                    endif
                endif
            endfor
        endfor
        bad = where(IntAuxFrame ne 9)
        Frame[bad] = 0.0
    endif
    *DataSet.IntAuxFrames[i] = IntAuxFrame
    *DataSet.Frames[i] = Frame

endfor                          ; repeat on nFrames

RETURN, OK

END
