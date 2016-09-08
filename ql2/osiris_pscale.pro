function osiris_pscale, hd

; check to see if this is an imager or spec frame
instr_str=sxpar(hd, 'INSTR', count=instr_cnt)
instr=strtrim(instr_str,2)
if (instr_cnt ne 0) then begin
    case instr of
        'spec': begin
            ; get the spectrograph effective wavelength
            filter=sxpar(hd, 'SFILTER', count=sfilter_cnt)
            ; effwave=osiris_spec_effwave(strtrim(filter,2))

            ; get the spectrograph scale
            camname_str=sxpar(hd, 'SSCALE', count=sscale_cnt)
            camname_float=float(camname_str)
            case camname_float of
                0.02:camname='0.020'
                0.035:camname='0.035'
                0.05:camname='0.050'
                0.1:camname='0.100'
                else: camname='0'
            endcase            
        end
        'imag': begin
            ; get the spectrograph effective wavelength
            filter=sxpar(hd, 'IFILTER', count=ifilter_cnt)
            ; effwave=osiris_spec_effwave(strtrim(filter,2))
            camname='0.020'
        end
    endcase
endif else begin
    camname='0'
endelse

return, camname

end
