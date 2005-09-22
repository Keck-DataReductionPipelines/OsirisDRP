;-----------------------------------------------------------------------
; NAME: replicate_vector
;
; PURPOSE: replicates a vector to an image or a cube. 
;
; INPUT : v        : vector
;         n1, [n2] : y and z dimensions of the image/cube to create
;
; OUTPUT : matrix or cube with the first axis having the same length as
;          the input vector.
;
; ON ERROR : returns ERR_UNKNOWN from APP_CONSTANTS
;
; STATUS : untested
;
; HISTORY : 12.8.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

function replicate_vector, v, n1, n2

   COMMON APP_CONSTANTS

   if ( NOT bool_is_vector(v) ) then $
      return, error('ERROR IN CALL (replicate_vector.pro): Not a vector.')

   n_Dims = size ( v )
   i_Type = size(v,/TYPE)

   if ( n_params() eq 2 ) then begin
      res = make_array(TYPE=i_Type, n_Dims(1), n1 )
      for i=0, n1-1 do res(*,i) = v
   end

   if ( n_params() eq 3 ) then begin
      res = make_array(TYPE=i_Type, n_Dims(1), n1, n2 )
      for i=0, n1-1 do for j=0, n2-1 do res(*,i,j) = v
   end

   return, res

end

