pro fix_nb_scan

nframes = 51
basename = "/u/osrseng/spec_data/2004-12-06/s041207_"
firstfile = 81
; For the first scan position, specify the rough horizontal area of the detector
; for the spectrum. 
first_pix = 1450
last_pix = 2100
; Also specify the average offset in horizontal pixels for subsequent spectra.
step = 31

; First create a dark frame
darkname = strarr(10)
for i = 0, 4 do begin
    number = firstfile + i
    if number lt 10 then begin
        darkname[i]=strcompress(basename+"a00000"+string(number)+".fits",/REMOVE_ALL)
    endif else begin
        if number lt 100 then begin
            darkname[i]=strcompress(basename+"a0000"+string(number)+".fits",/REMOVE_ALL)
        endif else begin
            darkname[i]=strcompress(basename+"a000"+string(number)+".fits",/REMOVE_ALL)
        endelse
    end
    number = firstfile + i + nframes+5
    if number lt 10 then begin
        darkname[i+5]=strcompress(basename+"a00000"+string(number)+".fits",/REMOVE_ALL)
    endif else begin
        if number lt 100 then begin
            darkname[i+5]=strcompress(basename+"a0000"+string(number)+".fits",/REMOVE_ALL)
        endif else begin
            darkname[i+5]=strcompress(basename+"a000"+string(number)+".fits",/REMOVE_ALL)
        endelse
    end
end

; Make combined dark frame
cube = fltarr(2048,2048,10)
for i = 0, 9 do begin
    cube[*,*,i] = readfits(darkname[i])
end

dark = fltarr(2048,2048)
for i = 0, 2047 do begin
    for j = 0, 2047 do begin
        dark[i,j] = median(cube[i,j,*])
    end
end

; Now read in data and make "compressed" scans where 3 files are added
; into one.
filename = strarr(nframes,3)
outfile = strarr(nframes)
for i = 0, 18 do begin
    number = firstfile + i+5
    if number lt 10 then begin
        filename[i,0]=strcompress(basename+"a00000"+string(number)+".fits",/REMOVE_ALL)
        outfile[i]=strcompress(basename+"c01000"+string(number)+".fits",/REMOVE_ALL)
    endif else begin
        if number lt 100 then begin
            filename[i,0]=strcompress(basename+"a0000"+string(number)+".fits",/REMOVE_ALL)
            outfile[i]=strcompress(basename+"c0100"+string(number)+".fits",/REMOVE_ALL)
        endif else begin
            filename[i,0]=strcompress(basename+"a000"+string(number)+".fits",/REMOVE_ALL)
            outfile[i]=strcompress(basename+"c010"+string(number)+".fits",/REMOVE_ALL)
        endelse
    end
    number = firstfile + 16+i+5
    if number lt 10 then begin
        filename[i,1]=strcompress(basename+"a00000"+string(number)+".fits",/REMOVE_ALL)
    endif else begin
        if number lt 100 then begin
            filename[i,1]=strcompress(basename+"a0000"+string(number)+".fits",/REMOVE_ALL)
        endif else begin
            filename[i,1]=strcompress(basename+"a000"+string(number)+".fits",/REMOVE_ALL)
        endelse
    end
    number = firstfile + 32+i+5
    if number lt 10 then begin
        filename[i,2]=strcompress(basename+"a00000"+string(number)+".fits",/REMOVE_ALL)
    endif else begin
        if number lt 100 then begin
            filename[i,2]=strcompress(basename+"a0000"+string(number)+".fits",/REMOVE_ALL)
        endif else begin
            filename[i,2]=strcompress(basename+"a000"+string(number)+".fits",/REMOVE_ALL)
        endelse
    end
end


for i = 0, 15 do begin
    fp = 0 > (first_pix - step*i) < 2047
    lp = 0 > (last_pix - step*i) < 2047
    tdata = readfits(filename[i,0],header) - dark
    tdata[0:fp,*] = 0
    tdata[lp:2047,*] = 0
    data = tdata
    tvar = readfits(filename[i,0],EXTEN_NO=1)
    tvar[0:fp,*] = 0
    tvar[lp:2047,*] = 0
    var = tvar
    tqual = readfits(filename[i,0],EXTEN_NO=2)
    tqual[0:fp,*] = 9
    tqual[lp:2047,*] = 9
    qual = tqual

    fp = 0 > (first_pix - step*(i+16)) < 2047
    lp = 0 > (last_pix - step*(i+16)) < 2047
    tdata = readfits(filename[i,1],header) - dark
    tdata[0:fp,*] = 0
    tdata[lp:2047,*] = 0
    data = data+tdata
    tvar = readfits(filename[i,1],EXTEN_NO=1)
    tvar[0:fp,*] = 0
    tvar[lp:2047,*] = 0
    var = var + tvar
    tqual = readfits(filename[i,1],EXTEN_NO=2)
    tqual[0:fp,*] = 9
    tqual[lp:2047,*] = 9
    qual = qual AND tqual

    fp = 0 > (first_pix - step*(i+32)) < 2047
    lp = 0 > (last_pix - step*(i+32)) < 2047
    tdata = readfits(filename[i,2],header) - dark
    tdata[0:fp,*] = 0
    tdata[lp:2047,*] = 0
    data = data+tdata
    tvar = readfits(filename[i,2],EXTEN_NO=1)
    tvar[0:fp,*] = 0
    tvar[lp:2047,*] = 0
    var = var + tvar
    tqual = readfits(filename[i,2],EXTEN_NO=2)
    tqual[0:fp,*] = 9
    tqual[lp:2047,*] = 9
    qual = qual AND tqual

    if ( i lt 3 ) then begin
        fp = 0 > (first_pix - step*(i+48)) < 2047
        lp = 0 > (last_pix - step*(i+48)) < 2047
        tdata = readfits(filename[i+16,2],header) - dark
        tdata[0:fp,*] = 0
        tdata[lp:2047,*] = 0
        data = data+tdata
        tvar = readfits(filename[i+16,2],EXTEN_NO=1)
        tvar[0:fp,*] = 0
        tvar[lp:2047,*] = 0
        var = var + tvar
        tqual = readfits(filename[i+16,2],EXTEN_NO=2)
        tqual[0:fp,*] = 9
        tqual[lp:2047,*] = 9
        qual = qual AND tqual
    end
;    valid = median(var[900:1100,900:1100])
;    index = where( (var gt 3.0) )

;Temporarily make entire array valid
    qual[*,*]=9

    writefits, outfile[i], data, header
    writefits, outfile[i], var, /append
    writefits, outfile[i], qual, /append
end

end
