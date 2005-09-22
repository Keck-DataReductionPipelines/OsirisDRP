
function image_stat_on_rect, p_Im, p_ImQ, loReject, hiReject, llx,  lly,  urx,  ury

;    COMMON APP_CONSTANTS

    if ( NOT bool_ptr_valid ( p_Im ) ) then $
       return, error('ERROR IN CALL (image_stat_on_rect.pro): Image pointer invalid.')

    if ( NOT bool_ptr_valid ( p_ImQ ) ) then $
       return, error('ERROR IN CALL (image_stat_on_rect.pro): Image Quality pointer invalid.')

    if ( NOT bool_is_image ( *p_Im ) ) then $
       return, error('ERROR IN CALL (image_stat_on_rect.pro): Image pointer not an image.')

    if ( NOT bool_is_image ( *p_ImQ ) ) then $
       return, error('ERROR IN CALL (image_stat_on_rect.pro): Image Quality pointer not an image.')

    if ( NOT bool_dim_match ( *p_ImQ, *p_Im ) ) then $
       return, error('ERROR IN CALL (image_stat_on_rect.pro): Image and image quality image do not match in size.')

    if ( loReject+hiReject ge 100. ) then $
       return, error('ERROR IN CALL (image_stat_on_rect.pro): Too much pixel recected.')

    if ( loReject lt 0. or loReject gt 100. or hiReject lt 0. or hiReject ge 100. ) then $
       return, error('ERROR IN CALL (image_stat_on_rect.pro): Invalid rejection values.')

    n_Dims = size(*p_Im)

    llx = llx > 0 
    lly = lly > 0 
    urx = urx < (n_Dims(1)-1)
    ury = ury < (n_Dims(2)-1)
    llx = llx < urx
    lly = lly < ury
    urx = urx > llx
    ury = ury > lly

    In    = (*p_Im)(llx:urx,lly:ury)
    InQ   = (*p_ImQ)(llx:urx,lly:ury)

    d_CleanMean = clean_op( In, InQ, loReject, hiReject, 'MEAN' )

    if ( NOT bool_is_vector(d_CleanMean) ) then $
       return, error('FAILURE (image_stat_on_rect.pro): The clean mean could not be calculated.')

    d_CleanStdev = clean_op ( In, InQ, loReject, hiReject, 'STD' )

    if ( NOT bool_is_vector(d_CleanStdev) ) then $
       return, error('FAILURE (image_stat_on_rect.pro): The clean stdev could not be calculated.')

    return, {CMEAN: d_CleanMean(0), CSTDEV : d_CleanStdev(0)}

end
