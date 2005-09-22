;-------------------------------------------------------------------------------------
; NAME :  div_by_vector.pro
; 
; PURPOSE : divide vector, set of vector, cube or set of cubes by
;           a vector.
;
; INPUT :  Frames             : pointer or pointerarray to input frames 
;          IntFrames          : pointer or pointerarray to input intframes
;          IntAuxFrames       : pointer or pointerarray to input intauxframes
;          v_StarFrame        : vector with the spectrum which is used for division
;          v_StarIntAuxFrame  : vector with the spectrum which is used
;                               for division
;          /DEBUG             : initializes the debugging mode
;
; OUTPUT : The input data is changed
;
; RETURN VALUE : returns OK if succesful, ERR_UNKNOWN else
;
; NOTES : - The divison is not performed if v_StarIntAuxFrame is invalid
;           or the absolute value is less than 1d-10. In that case the
;           corresponding IntAuxFrames 0th bit is set to 0.
;         - The input sets may be mixed, that means that the input
;           pointers may point to vectors and cubes.
;         - The IntFrames values are multiplied by v_StarFrame^2
;
; STATUS : not tested at all
;
; HISTORY : 13.5.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;--------------------------------------------------------------------------------------

function div_by_vector, Frames, IntFrames, IntAuxFrames, v_StarFrame, v_StarIntAuxFrame, DEBUG = DEBUG

   COMMON APP_CONSTANTS

   d_MinDivisor = 1d-10

   ; check if there is more than 1 input set
   n_Sets = size( Frames, /N_ELEMENTS )

   if ( size ( v_StarFrame, /N_DIMENSIONS ) ne 1 ) then $
      return, error (['ERROR IN CALL (div_by_vector.pro): Input vector not a vector, ' + $
              strtrim(string(size ( v_StarFrame, /N_DIMENSIONS )),2)+' elements.' ])

   ; loop over the input sets
   for i = 0, n_Sets-1 do begin

      if ( keyword_set ( DEBUG ) ) then $
         debug_info, 'DEBUG INFO (div_by_vector.pro): Working on dataset '+strtrim(string(i+1),2)+' of '+strtrim(string(n_Sets),2)

      n_Dim = size ( *Frames[i] )

      case n_Dim(0) of

         3 : begin ; input is a cube
                if ( n_Dim(3) eq size ( v_StarFrame, /N_ELEMENTS ) ) then begin
                   for nnx=0, n_Dim(1)-1 do $
                      for nny=0, n_Dim(2)-1 do $
                         for nnz=0, n_Dim(3)-1 do $
                            if ( extbit( v_StarIntAuxFrame(nnz), 0 ) and $
                                 extbit( (*IntAuxFrames(i))(nnx,nny,nnz), 0) and $
                                 abs(v_StarFrame(nnz)) gt d_MinDivisor             ) then begin
                               (*Frames[i])(nnx,nny,nnz)    = (*Frames[i])(nnx,nny,nnz) / v_StarFrame(nnz) 
                               (*IntFrames[i])(nnx,nny,nnz) = (*IntFrames[i])(nnx,nny,nnz) * v_StarFrame(nnz)^2
                            endif else (*IntAuxFrames[i])(nnx,nny,nnz) = setbit( (*IntAuxFrames[i])(nnx,nny,nnz), 0, 0) 
                endif else $
                   return, error ('ERROR IN CALL (div_by_vector.pro): Input star vector and input cube not compatible in length')
            end
         1 : begin ; input is a vector
                if ( n_Dim(1) eq size ( v_StarFrame, /N_ELEMENTS ) ) then begin
                   for nnz=0, n_Dim(1)-1 do $
                      if ( extbit( v_StarIntAuxFrame(nnz), 0 ) and $
                           extbit( (*IntAuxFrames(i))(nnz), 0) and $
                           abs(v_StarFrame(nnz)) gt d_MinDivisor     ) then begin
                         (*Frames[i])(nnz)    = (*Frames[i])(nnz) / v_StarFrame(nnz)
                         (*IntFrames[i])(nnz) = (*IntFrames[i])(nnz) * v_StarFrame(nnz)^2
                      endif else (*IntAuxFrames[i])(nnz) = setbit((*IntAuxFrames[i])(nnz), 0, 0)
                endif else $
                   return, error ('ERROR IN CALL (div_by_vector.pro): Input star vector and input vector not compatible in length')
             end

         else : return, error (['ERROR IN CALL (div_by_vector.pro): Input is neither 1d nor 3d'])

      endcase

   end

   return, OK

end
