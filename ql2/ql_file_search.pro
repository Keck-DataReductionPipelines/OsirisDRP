function ql_file_search, path_var, dir=dir

if (!version.release ge '5.5') then begin
    if keyword_set(dir) then begin
        path=ql_getpath(path_var)
        junk=file_test(path, /directory)
        if (junk) then filename=path else filename=''
    endif else begin
        filename=file_search(path_var)
    endelse
endif else begin 
    if keyword_set(dir) then begin
        junk=findfile(path_var)
        filename=ql_getpath(junk[0])
    endif else begin
        filename=findfile(path_var)
    endelse
endelse

return, filename

end
