;-----------------------------------------------------------------------
; NAME: valid
;
; PURPOSE : checks if pixels are valid
;
; INPUT : d_Frame                : float image/cube/... with frame values
;         d_IntFrame             : float image/cube/... with intframe values
;         b_IntAuxFrame          : byte  image/cube/... with intauxframe values
;         [/INSIDES]             : check only where the inside bit is set
;         [/VALIDS]              : check only where valid not where inside
;
; ALGORITHM :
;
;        a pixel is valid if all of the following conditions are fullfiled:
;
;        0th bit        : 1
;        3rd bit        : 1
;        intframe value : finite and gt d_Min as defined in int_valid.pro
;        frame value    : finite
;
;   /INSIDE
;        a pixel is valid if all of the following conditions are fullfiled:
;
;        3rd bit        : 1
;
;   /VALIDS
;
;        a pixel is valid if all of the following conditions are fullfilled:
;
;        0th bit        : 1
;        intframe value : finite and gt d_Min as defined in int_valid.pro
;        frame value    : finite
;
;   /GOODINT
;
;        a pixel is valid if all of the following conditions are fullfiled:
;
;        0th bit        : 1
;        1st bit        : 1
;        2nd bit        : 1
;        intframe value : finite and gt d_Min as defined in int_valid.pro
;        frame value    : finite
;
;   /BADINT
;
;        a pixel is valid if all of the following conditions are fullfiled:
;
;        0th bit        : 1
;        1st bit        : 1
;        2nd bit        : 0
;        intframe value : finite and gt d_Min as defined in int_valid.pro
;        frame value    : finite
;
;
; NOTES : - User has to verify that d_Frame, d_IntFrame, b_IntAuxFrame
;           have the same size and dimensions.
;
; RETURNS : returns a mask of same size as d_Frame/d_IntFrame/b_IntAuxFrame with 1 where valid
;           and 0 where not.
;
;-----------------------------------------------------------------------

function valid, d_Frame, d_IntFrame, b_IntAuxFrame, INSIDES=INSIDES, VALIDS=VALIDS, $
                GOODINT=GOODINT, BADINT=BADINT

   if ( keyword_set ( INSIDES ) ) then $
      return, byte(extbit ( b_IntAuxFrame, 3 )) 

   if ( keyword_set ( VALIDS ) ) then begin
      mb_ValidIntAux  = byte(extbit ( b_IntAuxFrame, 0 ))
      mb_ValidInt     = byte(int_valid  ( d_IntFrame ))
      mb_ValidDataInt = byte(data_valid ( d_IntFrame ))
      mb_ValidData    = byte(data_valid ( d_Frame ))
      return, byte(mb_ValidIntAux and mb_ValidInt and mb_ValidDataInt and mb_ValidData)
   end

   if ( keyword_set ( GOODINT ) ) then begin
      mb_B0           = byte(extbit ( b_IntAuxFrame, 0 ))
      mb_B1           = byte(extbit ( b_IntAuxFrame, 1 ))
      mb_B2           = byte(extbit ( b_IntAuxFrame, 2 ))
      mb_ValidInt     = byte(int_valid  ( d_IntFrame ))
      mb_ValidDataInt = byte(data_valid ( d_IntFrame ))
      mb_ValidData    = byte(data_valid ( d_Frame ))
      return, byte(mb_B0 and mb_B1 and mb_B2 and mb_ValidInt and mb_ValidDataInt and mb_ValidData)
   end

   if ( keyword_set ( BADINT ) ) then begin
      mb_B0           = byte(extbit ( b_IntAuxFrame, 0 ))
      mb_B1           = byte(extbit ( b_IntAuxFrame, 1 ))
      mb_B2           = bool_invert(byte(extbit ( b_IntAuxFrame, 2 )))
      mb_ValidInt     = byte(int_valid  ( d_IntFrame ))
      mb_ValidDataInt = byte(data_valid ( d_IntFrame ))
      mb_ValidData    = byte(data_valid ( d_Frame ))
      return, byte(mb_B0 and mb_B1 and mb_B2 and mb_ValidInt and mb_ValidDataInt and mb_ValidData)
   end

   mb_ValidIntAux  = byte(extbit ( b_IntAuxFrame, 0 ))
   mb_ValidInt     = byte(int_valid  ( d_IntFrame ))
   mb_ValidDataInt = byte(data_valid ( d_IntFrame ))
   mb_ValidData    = byte(data_valid ( d_Frame ))
   mb_Inside       = byte(extbit ( b_IntAuxFrame, 3 )) 
   return, byte(mb_ValidIntAux and mb_ValidInt and mb_ValidDataInt and mb_ValidData and mb_Inside)

end
