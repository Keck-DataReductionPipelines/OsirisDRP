pro CImWin_MakeMovie_Base_event, event

widget_control, event.top, get_uval=movie_uval
widget_control, movie_uval.base_id, get_uval=cimwin_uval

ImWin=*(cimwin_uval.self_ptr)

; check to see if the normalize button was pressed
widget_control, movie_uval.wids.norm_id, get_value=norm_val

if (norm_val) then begin
    ; update the display on the movie widget
    widget_control, movie_uval.wids.minval_id, set_value=strtrim(-0.1,2)
    widget_control, movie_uval.wids.maxval_id, set_value=strtrim(1.1,2)

    ImWin->SetMovieMinValue, -0.1
    ImWin->SetMovieMaxValue, 1.1

endif else begin
    ; get the imwin displayed min and max 
    min=ImWin->GetDispMin()
    max=ImWin->GetDispMax()

    ; make this the display min and max for the movie
    ImWin->SetMovieMinValue, min
    ImWin->SetMovieMaxValue, max

    ; update the display on the movie widget
    widget_control, movie_uval.wids.minval_id, set_value=strtrim(min,2)
    widget_control, movie_uval.wids.maxval_id, set_value=strtrim(max,2)

endelse

; check to see what filetype is selected
widget_control, movie_uval.wids.filetype_id, get_value=filetype_val

if (filetype_val) then begin
    ; change the type to .gif
    widget_control, movie_uval.wids.output_filename_id, get_value=path_filename

    ; find last '.'
    dot_number = STRPOS(path_filename, '.', /REVERSE_SEARCH)
    ; if there is a dot
    if dot_number ne -1 then begin
        ; get everything before it
        new_string=STRMID(path_filename, 0, dot_number)
        fname=new_string+'.gif' 
    ; otherwise return the current directory
    endif else begin
        cd, '.', current=cur
        fname=cur+'/file.gif'
    endelse

    widget_control, movie_uval.wids.output_filename_id, set_value=fname
endif else begin
    ; change the type to .mpg
    widget_control, movie_uval.wids.output_filename_id, get_value=path_filename

    ; find last '.'
    dot_number = STRPOS(path_filename, '.', /REVERSE_SEARCH)
    ; if there is a dot
    if dot_number ne -1 then begin
        ; get everything before it
        new_string=STRMID(path_filename, 0, dot_number)
        fname=new_string+'.mpg' 
    ; otherwise return the current directory
    endif else begin
        cd, '.', current=cur
        fname=cur+'/file.mpg'
    endelse

    widget_control, movie_uval.wids.output_filename_id, set_value=fname
endelse

if tag_names(event, /structure_name) eq 'WIDGET_KILL_REQUEST' then $
    widget_control, event.top, /destroy
    return
end
