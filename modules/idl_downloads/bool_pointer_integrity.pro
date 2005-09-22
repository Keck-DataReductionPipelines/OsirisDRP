;-----------------------------------------------------------------------
; NAME: bool_pointer_integrity
;
; PURPOSE: check the integrity of the pointer or pointer arrays in DataSet
;
; INPUT : p_Frames                : pointer array with the data frames
;         p_IntFrames             : pointer array with the noise frames
;         p_IntAuxFrames          : pointer array with the quality frames
;         nFrames                 : number of valid frames 
;         functionName            : name of the calling function
;
;         Either
;         [/VECTOR]               : check if input pointer or pointer
;            or                     arrays are pointing to vectors
;         [/IMAGE]                : check if input pointer or pointer
;            or                     arrays are pointing to images
;         [/CUBE]                 : check if input pointer or pointer
;                                   arrays are pointing to cubes
;         [/DIMS]                 : if set, the input datasets may
;                                   have different spatial dimensions
;                                   (only for cubes and images).
;
; OUTPUT : None
;
; ON ERROR : returns ERR_UNKNOWN from APP_CONSTANTS
;
; ALGORITHM : Returns ERR_UNKNOWN if any of the following conditions
;             is not fullfilled :
;               - nFrames greater than 0
;               - all pointers in the pointer array are valid
;               - the dimensions are the same (All frame,
;                 intframe and intauxframe pointers must be vectors,
;                 images or cubes)
;               - the spatial dimensions are the same unless the
;                 DIMS keyword is set.
;               - in case of vectors the vector lengths are the
;                 same.
;               - in case of cubes the length of the spectral
;                 dimension are the same.
;               - if VECTOR is set all frame,
;                 intframe and intauxframe pointers are vectors
;               - if IMAGE is set all frame,
;                 intframe and intauxframe pointers are images
;               - if CUBE is set all frame,
;                 intframe and intauxframe pointers are cubes
;             A warning occurs if :
;               - the frame values contain NANs or INFs
;               - the intframe values contain NANs or INFs or negative values
;               - the frame values contain NANs or INFs and are not
;                 masked as bad (0th bit = 0)
;               - the intframe values contain NANs or INFs or negative
;                 values and are not masked as bad (0th bit = 0)
;               - if cubes, the number of spectral channels must be greater
;                 than 300.
;
; NOTES : None
;
; STATUS : not tested
;
; HISTORY : 7.8.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------
function bool_pointer_integrity, p_Frames, p_IntFrames, p_IntAuxFrames, nFrames, $
                                 functionName, VECTOR=VECTOR, IMAGE=IMAGE, CUBE=CUBE, DIMS=DIMS

    COMMON APP_CONSTANTS

    if ( ( keyword_set(CUBE) + keyword_set(IMAGE) + keyword_set(VECTOR) ) gt 1 ) then $
       return, error ('ERROR IN CALL ('+strg(functionName)+'): Set either VECTOR, IMAGE or CUBE.')

    if ( nFrames eq 0 ) then $
       return, error ('ERROR IN CALL ('+strg(functionName)+'): nFrames must be > 0.')

    ; check if ptrarrays are valid
    if ( NOT bool_ptr_valid ( p_Frames, /ARR ) or $
         NOT bool_ptr_valid ( p_IntFrames, /ARR ) or $
         NOT bool_ptr_valid ( p_IntAuxFrames, /ARR )    ) then $
       return, error ( 'FAILURE ('+strg(functionName)+'): At least one input pointer invalid.' )

    v_DimsF   = arr_chk ( p_Frames, nFrames, DIMS=keyword_set(DIMS) )
    v_DimsIF  = arr_chk ( p_IntFrames, nFrames, DIMS=keyword_set(DIMS) )
    v_DimsIAF = arr_chk ( p_IntAuxFrames, nFrames, DIMS=keyword_set(DIMS) )

    if ( bool_is_scalar (v_DimsF) or bool_is_scalar (v_DimsIF) or bool_is_scalar (v_DimsIAF) ) then $
       return, error ('FAILURE ('+strg(functionName)+'): Dimensionality between the various input pointer sets not compatible.')
    
    if ( NOT ( array_equal ( v_DimsF, v_DimsIF ) and array_equal ( v_DimsF, v_DimsIAF ) ) ) then $
       return, error ('FAILURE ('+strg(functionName)+'): Dimensionality between the various input pointers not compatible.')

    if ( keyword_set ( VECTOR ) ) then $
       if ( NOT bool_is_vector ( *p_Frames(0) ) ) then $
          return, error ('FAILURE ('+strg(functionName)+'): Input not 1d.')

    if ( keyword_set ( IMAGE ) ) then $
       if ( NOT bool_is_image ( *p_Frames(0) ) ) then $
          return, error ('FAILURE ('+strg(functionName)+'): Input not 2d.')

    if ( keyword_set ( CUBE ) ) then $
       if ( NOT bool_is_cube ( *p_Frames(0) ) ) then $
          return, error ('FAILURE ('+strg(functionName)+'): Input not 3d.')

    ; check for NANs and INFs in data values
    for i = 0, nFrames-1 do $
       if ( bool_contains_nan(*p_Frames[i]) or $
            bool_contains_inf(*p_Frames[i]) ) then $
          warning, 'WARNING ('+strg(functionName)+'): Input frame pointer contains NaNs or INFs in set '+strg(i)+'.'

     ; check for NANs, INFs and negative values in noise values
     for i = 0, nFrames-1 do $
       if ( bool_contains_nan(*p_IntFrames[i]) or $
            bool_contains_inf(*p_IntFrames[i]) or $
            bool_contains_neg(*p_IntFrames[i])      ) then $
          warning, 'WARNING ('+strg(functionName)+$
                   '): Input intframe pointer contain NaNs or INFs or negative values in set '+ strg(i)+'.'

    ; check for NANs and INFs in data and noise values where not masked as bad
    for i=0, nFrames-1 do begin

       if ( NOT bool_is_byte ( *p_IntAuxFrames[i] ) ) then $
          return, error('FAILURE ('+strg(functionName) + '): Input intauxframe is not of type byte in set '+strg(i)+'.')

       vb_Mask = where(extbit(*p_IntAuxFrames[i],0), n_Valid)

       if ( n_Valid gt 0 ) then begin

          if ( bool_contains_nan ( (*p_IntFrames[i])(vb_Mask) ) or $
               bool_contains_inf ( (*p_IntFrames[i])(vb_Mask) ) or $
               bool_contains_neg ( (*p_IntFrames[i])(vb_Mask) )     ) then $
             warning, 'SEVERE WARNING ('+strg(functionName)+ $
                      '): At least one intframe value is not finite or NAN or negative and has the 0th quality bit equal to 1 in set '+ strg(i)+'.'

          if ( bool_contains_nan ( (*p_Frames[i])(vb_Mask) ) or $
               bool_contains_inf ( (*p_Frames[i])(vb_Mask) )     ) then $
             warning, 'SEVERE WARNING ('+strg(functionName)+ $
                      '): At least one frame value is not finite or NAN and has the 0th quality bit equal to 1 in set '+ strg(i)+'.'

       endif else warning, 'SEVERE WARNING ('+strg(functionName)+'): Frame completely invalid according to the 0th bit in set ' + strg(i)+'.'

    end

    return, OK

end
