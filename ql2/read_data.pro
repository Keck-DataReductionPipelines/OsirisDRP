function read_data, filename, arr1, arr2

openr, unit, filename, /get_lun

; initialize variables
line = ''
num_lines = 0

; read line at a time until end of file
while not eof(unit) do begin
  ; read line
  readf, unit, line
  ; get first char
  a = strmid(line, 0, 1)
  ; if first char is a #, ignore (comment)
  if ( a ne "#") then begin

    ; otherwise, trim up line
    line = strcompress(strtrim(line, 2))
    ; separate using ' ' (space) as token
    parts = str_sep(line, ' ')

    ; first time through, set value of variables
    if (num_lines eq 0) then begin
        tarr1=double(parts[0])
        tarr2=double(parts[1])
    endif else begin
        ; rest of the time, add new values to array
        tarr1 = [tarr1, double(parts[0])]
        tarr2 = [tarr2, double(parts[1])]
    endelse
    num_lines = num_lines + 1
  endif
endwhile

free_lun, unit


; copy values of temp vars to function arguments to be passed out
arr1=tarr1
arr2=tarr2

; return number of lines read
return, num_lines
end
