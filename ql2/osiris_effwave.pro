function osiris_effwave, hd

; check to see if this is an imager or spec frame
instr_str=sxpar(hd, 'INSTR', count=instr_cnt)
instr=strtrim(instr_str,2)
if (instr_cnt ne 0) then begin
    case instr of
        'spec': begin
            ; get the spectrograph effective wavelength
            filter=sxpar(hd, 'SFILTER', count=sfilter_cnt)
            effwave=osiris_spec_effwave(strtrim(filter,2))
        end
        'imag': begin
            ; get the spectrograph effective wavelength
            filter=sxpar(hd, 'IFILTER', count=ifilter_cnt)
            effwave=osiris_spec_effwave(strtrim(filter,2))
        end
    endcase
endif else begin
    effwave=0
endelse

return, effwave

end
