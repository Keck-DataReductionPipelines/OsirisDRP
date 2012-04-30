;-----------------------------------------------------------------------
; NAME: frame_op
;
; PURPOSE: operates on frames with master frame
;
; INPUT : p_Frames                : pointer array with the data frames
;         p_IntFrames             : pointer array with the noise frames
;         p_IntAuxFrames          : pointer array with the quality frames
;         p_Frame                 : pointer with the master frame
;         p_IntFrame              : pointer with the master noise frame
;         p_IntAuxFrame           : pointer array the master quality frame
;         nFrames                 : number of valid frames in the
;                                   pointer arrays
;         s_Op                    : Operator '-', '+', '/'
;         [d_MinDiv=d_MinDiv]     : Minimum divisor, absolute (only
;                                   together with s_Op='/' otherwise
;                                   ignored). If set to 0 or 0. the
;                                   keyword will be ignored. In that
;                                   case choose something like 1.d-20.
;         [Debug=Debug]           : initializes the debugging mode
;         [/VALIDS]               : the inside bit is ignored for
;                                   calculation if set but still
;                                   calculated from the input
;
; OUTPUT : returns a boolean vector of length nFrames indicating
;          whether the ith operation was succesful (1) or not (0)
;
; ON ERROR : returns ERR_UNKNOWN from APP_CONSTANTS
;
; NOTES : - The input pointer arrays are changed
;
;         - an operation fails if the pixel or/and the master pixel are
;           invalid (acc. to valid.pro and d_MinDiv in case of
;           dividing). The frame/intframe values are untouched if the operation failed. 
;
;         - QBits are set according to below rules. If the operation
;           was succesful all bits are set. If the operation was not
;           successful the 1st and the 2nd bit are not set.
;              0th bit : 1 if both pixels are valid (acc. valid.pro or
;                        d_MinDiv), 0 else
;              1st bit : 1 if one or both pixel (both valid) were interpolated, 0 else 
;              2nd bit : 1 if one or both pixel (both valid) were interpolated and
;                        badly interpolated, 0 else
;              3rd bit : 1 if both pixels were inside, 0 else
;
;         - This routine works for input variables of any dimensions
;
; STATUS : not tested
;
; HISTORY : 10.8.2004, created
;           18.8.2004, implemented full set of quality bits
;           2008-03-18	Enforce consistency by masking out any invalid pixels
;           			after the operation is completed. 
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

function frame_op_ssr, p_Frames, p_IntFrames, p_IntAuxFrames, s_Op, p_Frame, p_IntFrame, p_IntAuxFrame, nFrames, $
                   MinDiv = MinDiv, Debug = Debug, VALIDS = VALIDS

    COMMON APP_CONSTANTS

    if ( s_Op ne '+' and s_Op ne '-' and s_Op ne '/' and s_Op ne '*' ) then $
       return, error('ERROR IN CALL (frame_op.pro): Unknown operator')

    if ( bool_pointer_integrity( p_Frame, p_IntFrame, p_IntAuxFrame, 1, 'frame_op.pro' ) ne OK ) then $
       return, error('ERROR IN CALL (frame_op.pro): 2. operand integrity check failed.')

    if ( bool_pointer_integrity( p_Frames, p_IntFrames, p_IntAuxFrames, nFrames, 'frame_op.pro' ) ne OK ) then $
       return, error('ERROR IN CALL (frame_op.pro): 1. operand integrity check failed.')

    for i=0, nFrames-1 do $
       if ( NOT bool_dim_match ( p_Frames(0), p_Frame ) or $
            NOT bool_dim_match ( p_IntFrames(0), p_IntFrame ) or $
            NOT bool_dim_match ( p_IntAuxFrames(0), p_IntAuxFrame ) ) then $
          return, error ('ERROR IN CALL (frame_op.pro): Operands not compatible in size in set '+strg(i)+'.')

    if ( keyword_set ( DEBUG ) ) then $
       debug_info,'DEBUG INFO (frame_op.pro): Operator is ' + s_Op

    ; when dividing the minimum divisor must be declared
    if ( s_Op eq '/' ) then $
       if ( keyword_set ( MinDiv ) ) then d_MinDiv = MinDiv else d_MinDiv = 1.d-10

    if ( keyword_set ( DEBUG ) and s_Op eq '/' ) then $
       debug_info,'DEBUG INFO (frame_op.pro): Minimum absolute divisor ' + strg(d_MinDiv)

    ; indicator whether the ith operation was successful or not
    vb_Status = intarr(nFrames)

    ; 2d masks where the pixels are valid, when dividing
    ; the absolute divisor must be at least d_MinDiv 
    if ( s_Op ne '/' ) then mb_Mask = valid ( *p_Frame, *p_IntFrame, *p_IntAuxFrame, VALIDS=keyword_set(VALIDS) )
    if ( s_Op eq '/' ) then mb_Mask = valid ( *p_Frame, *p_IntFrame, *p_IntAuxFrame, VALIDS=keyword_set(VALIDS) ) and $
                                      int_valid (*p_Frame, MIN=d_MinDiv, /ABSOLUT)

    if ( keyword_set ( DEBUG ) ) then $
       debug_info,'DEBUG INFO (frame_op.pro): Number of valid pixels in master ' + strtrim(string(total(mb_Mask)),2)

    if ( total(mb_Mask) eq 0 ) then $
       return, error('ERROR (frame_op.pro): 2. operand completely invalid.')

    ; quality bits of the master
    mb_B1  = byte(extbit ( *p_IntAuxFrame, 1 ))
    mb_B2  = byte(extbit ( *p_IntAuxFrame, 2 ))
    mb_B3  = byte(extbit ( *p_IntAuxFrame, 3 ))

    ; now loop over the data frames
    for i=0, nFrames-1 do begin

       if ( keyword_set ( Debug ) ) then $
          debug_info, 'DEBUG INFO (frame_op.pro): Working on set ' + strg(i) + ' now'

       ; combined 'valid' masks where dataset and master are valid
       mb_Masks = mb_Mask and valid ( *p_Frames(i), *p_IntFrames(i), *p_IntAuxFrames(i), VALIDS=keyword_set(VALIDS) )
       v_Masks  = where ( mb_Masks, n_Total ) 

       if ( keyword_set ( DEBUG ) ) then $
          debug_info,'DEBUG INFO (frame_op.pro): Number of valid pixels for operation ' + strg(n_Total)

       if ( n_Total eq 0 ) then $
          warning, 'WARNING (frame_op.pro): Frame operation failed in set ' + strg(i) + '. No valid pixels. Operation not done.' $
       else begin

          ; the ith operation was successful
          vb_Status(i) = 1

          ; calculate new noise frame
          case s_Op of

             '+' : (*p_IntFrames[i])(v_Masks) = sqrt ( (*p_IntFrames[i])(v_Masks)^2 + (*p_IntFrame)(v_Masks)^2 ) 
             '-' : (*p_IntFrames[i])(v_Masks) = sqrt ( (*p_IntFrames[i])(v_Masks)^2 + (*p_IntFrame)(v_Masks)^2 )

             '*' : begin
                      a  = (*p_Frames[i])(v_Masks)
                      b  = (*p_Frame)(v_Masks)
                      wa = (*p_IntFrames[i])(v_Masks)
                      wb = (*p_IntFrame)(v_Masks)
                      (*p_IntFrames[i])(v_Masks) = sqrt ( (a*wb)^2 + (b*wa)^2 )
                   end

             '/' : begin
                      a  = (*p_Frames[i])(v_Masks)
                      b  = (*p_Frame)(v_Masks)
                      wa = (*p_IntFrames[i])(v_Masks)
                      wb = (*p_IntFrame)(v_Masks)
                      (*p_IntFrames[i])(v_Masks) = sqrt ( (wa/b)^2 + a^2/b^4*wb^2 )
                   end
          endcase

          ; operate on data frames
          case s_Op of
             '+' : (*p_Frames[i])(v_Masks) = temporary((*p_Frames[i])(v_Masks)) + (*p_Frame)(v_Masks)
             '-' : (*p_Frames[i]) = temporary((*p_Frames[i])) - (*p_Frame)
             ;'-' : (*p_Frames[i])(v_Masks) = temporary((*p_Frames[i])(v_Masks)) - (*p_Frame)(v_Masks)
             '*' : (*p_Frames[i])(v_Masks) = temporary((*p_Frames[i])(v_Masks)) * (*p_Frame)(v_Masks)
             '/' : (*p_Frames[i])(v_Masks) = temporary((*p_Frames[i])(v_Masks)) / (*p_Frame)(v_Masks)
          endcase

          ; update quality frame

          mb_B1s = byte(extbit ( *p_IntAuxFrames(i), 1 ))
          mb_B2s = byte(extbit ( *p_IntAuxFrames(i), 2 ))
          mb_B3s = byte(extbit ( *p_IntAuxFrames(i), 3 ))

          mb_Valid_Int      = (mb_B1s or mb_B1) and mb_Masks
          mb_Valid_Good_Int = ((mb_B1s and mb_B2s) or (mb_B1 and mb_B2)) and mb_Masks
          mb_Inside         = (mb_B3s and mb_B3)

          (*p_IntAuxFrames[i]) = byte(mb_Masks + 2b*mb_Valid_Int + 4b*mb_Valid_Good_Int + 8b*mb_Inside)

		  ; enforce consistency:
		  ;   apply updated quality frame to mask out any bad pixels in the image
		  ;   This is necessary because if the two frames' masks do not match,
		  ;   above, then the pixels which are not valid in both are simply left
		  ;   untouched in the p_Frames. They really should be zeroed out as
		  ;   invalid. - MDP, JEL, & SAW 2008-03-18
                  ;   commented out by QMK, 2010-01-22
		  ;wbad = where(*p_IntAuxFrames[i] eq 0, badcount  ) 
		  ;if badcount gt 0 then begin
		  ;		(*p_Frames[i])[wbad] = 0
		  ;endif

       end

    endfor

    if ( keyword_set ( DEBUG ) ) then debug_info, 'DEBUG INFO (frame_op.pro): Returning succesfully.'

    return, vb_Status

END
