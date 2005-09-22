function mosaicdith_imag_integrity, Frames, IntFrames, IntAuxFrames, n_Sets, error_status

    ; Check integrity

    if ( NOT bool_ptr_valid ( Frames, /ARR ) or $
         NOT bool_ptr_valid ( IntFrames, /ARR ) or $
         NOT bool_ptr_valid ( IntAuxFrames, /ARR )    ) then $
       return, error ( ['FAILURE (data integrity):', $
                        '        Input pointers invalid or not consistent'], error_status )

    for i = 0, n_Sets-1 do $
       if ( NOT bool_is_image(*Frames[i]) or $
            NOT bool_is_image(*IntFrames[i]) or $
            NOT bool_is_image(*IntAuxFrames[i]) ) then $
          return, error ( ['FAILURE (data integrity):', $
                           '        In Set '+strtrim(string(i+1),2)+' not an image'], error_status )

    for i = 0, n_Sets-1 do $
       if ( bool_contains_nan(*Frames[i]) or $
            bool_contains_inf(*Frames[i]) ) then $
          return, error ( ['FAILURE (data integrity):', $
                           '        Data image in Set '+strtrim(string(i+1),2)+' contains NaNs or INFs'], error_status )

    for i = 0, n_Sets-1 do $
       if ( bool_contains_nan(*IntFrames[i]) or $
            bool_contains_inf(*IntFrames[i]) ) then $
          return, error ( ['FAILURE (data integrity):', $
                           '        Data integrity check: IntFrame cube in Set '+strtrim(string(i+1),2)+' contains NaNs or INFs'] )
    for i = 0, n_Sets-1 do begin
       nx = (size(*Frames(i)))(1)
       ny = (size(*Frames(i)))(2)
       if ( nx ne (size(*IntFrames(i)))(1) or $
            ny ne (size(*IntFrames(i)))(2) or $
            nx ne (size(*IntAuxFrames(i)))(1) or $
            ny ne (size(*IntAuxFrames(i)))(2)  ) then $
          return, error ( ['FAILURE (data integrity):', $
                           '        In Set '+strtrim(string(i+1),2)+$
                           ' image x-y-dimensions not compatible'], error_status )
    end

    ; the integrity is ok

    return, 1

end   
