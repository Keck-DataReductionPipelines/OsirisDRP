function mosaicdith_integrity, DataSet.Frames, DataSet.IntFrames, DataSet.IntAuxFrames, error_status

    n_Sets = DataSet.NextAvailableSlot

    ; Check integrity

    if ( NOT bool_ptr_valid ( DataSet.Frames, /ARR ) or $
         NOT bool_ptr_valid ( DataSet.IntFrames, /ARR ) or $
         NOT bool_ptr_valid ( DataSet.IntAuxFrames, /ARR )    ) then $
       return, error ( ['FAILURE (mosaicdith_000.pro: XYZ_SPEC):', $
                        '        Input pointers invalid or not consistent'], error_status )

    for i = 0, n_Sets-1 do $
       if ( NOT bool_is_cube(*DataSet.Frames[i]) or $
            NOT bool_is_cube(*DataSet.IntFrames[i]) or $
            NOT bool_is_cube(*DataSet.IntAuxFrames[i]) ) then $
          return, error ( ['FAILURE (mosaicdith_000.pro: XYZ_SPEC):', $
                           '        In Set '+strtrim(string(i+1),2)+' not a cube'], error_status )

    for i = 0, n_Sets-1 do $
       if ( bool_contains_nan(*DataSet.Frames[i]) or $
            bool_contains_inf(*DataSet.Frames[i]) ) then $
          return, error ( ['FAILURE (mosaicdith_000.pro: XYZ_SPEC):', $
                           '        Data cube in Set '+strtrim(string(i+1),2)+' contains NaNs or INFs'], error_status )

    nz = (size(*DataSet.Frames(0)))(3)
    for i = 0, n_Sets-1 do $
       if ( nz ne (size(*DataSet.Frames(i)))(3) or $
            nz ne (size(*DataSet.IntFrames(i)))(3) or $
            nz ne (size(*DataSet.IntAuxFrames(i)))(3)   ) then $
          return, error ( ['FAILURE (mosaicdith_000.pro: XYZ_SPEC):', $
                           '        In Set '+strtrim(string(i+1),2)+' cubes z-dimensions not compatible'], error_status )

    for i = 0, n_Sets-1 do begin
       nx = (size(*p_data(i)))(1)
       ny = (size(*p_data(i)))(2)
       if ( nx ne (size(*p_intframe(i)))(1) or $
            ny ne (size(*p_intframe(i)))(2) or $
            nx ne (size(*p_intauxframe(i)))(1) or $
            ny ne (size(*p_intauxframe(i)))(2)  ) then $
          return, error ( ['FAILURE (mosaicdith_000.pro: XYZ_SPEC):', $
                           '        In Set '+strtrim(string(i+1),2)+$
                           ' cubes x-y-dimensions not compatible'], error_status )
    end

    ; the integrity is ok

    return, 1

end   
