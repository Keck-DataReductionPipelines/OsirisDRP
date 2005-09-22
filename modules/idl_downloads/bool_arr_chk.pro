;-----------------------------------------------------------------------
; NAME:  arr_chk
;
; PURPOSE: Check input pointer array for dimensions. 
;
; INPUT :  In      : input pointer array. The pointers must
;                    be valid.
;           n      : number of input pointers to check (>1)
;          /DIMS   : do not check the spatial dimensions
;
; NOTES : Returns the dimensions of each pointer on success,
;         ERR_UNKNOWN from APP_CONSTANTS else
;          - All input pointers describe the same dimensionality.
;            (Either all vectors, images or cubes.)
;          - Cubes   : the spectral dimensions must be the same.
;                      the spatial dimensions must be the same unless
;                      the DIMS keyword is set.
;          - Images  : the spatial dimensions must be the same unless
;                      the DIMS keyword is set.
;          - Vectors : the length must be the same
;
; STATUS : untested
;
; HISTORY : 27.2.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION arr_chk, In, n, DIMS=DIMS

   common APP_CONSTANTS

   if ( n eq 1 ) then return, error ('ERROR IN CALL (arr_chk): Number of input pointers must be greater than 1.')

   ; first check that allpointers have the same dimensions
   v_Dims = make_array(n,/INTEGER,VALUE=0)
   for i=0, n-1 do $
      vn_Dims(i) = size(*In(i))(0)
   if ( NOT array_equal ( vn_Dims(*), vn_Dims(0) ) ) then $
      return, error ('FAILURE (bool_arr_chk): Dimensions not the same.')

   ; now check the individual dimensions
   v_Dims  = make_array(vn_Dims(0)+1,n,/INTEGER,VALUE=0)   ; number of axes, spectral channels, x-dim, y-dim
   for i=0, n-1 do $
      v_Dims(*,i) = size(*In(i))(0:vn_Dims(0))

   if ( NOT keyword_set ( DIMS ) ) then begin

      case vn_Dims(0) of

         1 : if ( NOT array_equal ( v_Dims(1,*), reform(v_Dims(1,0)) ) ) then $
                return, error ('FAILURE (bool_arr_chk): Input vectors have different lengths.')

         2 : if ( NOT array_equal ( v_Dims(1,*), reform(v_Dims(1,0)) ) or $
                  NOT array_equal ( v_Dims(2,*), reform(v_Dims(2,0)) ) ) then $
                return, error ('FAILURE (bool_arr_chk): Input images have different spatial dimensions.')

         3 : begin
                if ( NOT array_equal ( v_Dims(1,*), reform(v_Dims(1,0)) ) ) then $
                   return, error ('FAILURE (bool_arr_chk): Input cubes have different spectral dimensions.')
                if ( NOT array_equal ( v_Dims(2,*), reform(v_Dims(2,0)) ) or $
                     NOT array_equal ( v_Dims(3,*), reform(v_Dims(3,0)) ) ) then $
                return, error ('FAILURE (bool_arr_chk): Input cubes have different spatial dimensions.')
             end

         else : return, error ('ERROR IN CALL (bool_arr_chk): Dimension not supported.')

      endcase

   end

   return, v_Dims

END 
