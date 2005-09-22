;-----------------------------------------------------------------------
; NAME:  resize_dataset 
;
; PURPOSE: resize spatial dimensions of images or cubes in Dataset to 
;          the size of the biggest spatial dimension
;
; INPUT :  DataSet : the DataSet pointer. The Naxis keywords must be
;                    set properly. Either all DataSet pointers must
;                    point to images or cubes. The size of the
;                    images/cubes must not be the same.
;          n_Sets  : number of sets
;
; OUTPUT : updates DataSet
;
; NOTES : Ensure that DataSet is ok acc. to bool_pointer_integrity.pro
;
; STATUS : untested
;
; HISTORY : 23.1.2005, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

function resize_dataset, DataSet, n_Sets

    common APP_CONSTANTS

    n_Dim = (size(*DataSet.Frames(0)))(0)

    if ( n_Dim ne 2 and n_Dim ne 3 ) then $
       return, error ('ERROR IN CALL (resize_dataset): Only for images or cubes.')

    vn_Sizes = make_array( n_Dim+1, n_Sets, /INT, VALUE=0 )

    for i=0, n_Sets-1 do $
       vn_Sizes(*,i) = (size(*DataSet.Frames(i)))(0:n_Dim)   ; naxes, spectral channels, x, y

    unx = max(vn_Sizes(n_Dim-1,*))
    uny = max(vn_Sizes(n_Dim,*))
    lnx = min(vn_Sizes(n_Dim-1,*))
    lny = min(vn_Sizes(n_Dim,*))

    if ( unx ne lnx or uny ne lny ) then begin

       for i=0, n_Sets-1 do begin

          v_Size = ( ( bool_is_cube ( *DataSet.Frames(i) ) ) ? [vn_Sizes(1,i),unx,uny] : [unx,uny] )

          cf_Frame       = make_array(v_Size,/FLOAT,Value=0.)
          cf_IntFrame    = make_array(v_Size,/FLOAT,Value=0.)
          cb_IntAuxFrame = make_array(v_Size,/BYTE,Value=8b)

          n1 = vn_Sizes(1,i)
          n2 = vn_Sizes(2,i)
          n3 = (n_Dim eq 3)?(vn_Sizes(3,i)):1

          cf_Frame       (0:n1-1, 0:n2-1, 0:n3-1) = *DataSet.Frames(i)
          cf_IntFrame    (0:n1-1, 0:n2-1, 0:n3-1) = *DataSet.IntFrames(i)
          cb_IntAuxFrame (0:n1-1, 0:n2-1, 0:n3-1) = *DataSet.IntAuxFrames(i)

          *DataSet.Frames(i)       = cf_Frame		
          *DataSet.IntFrames(i)    = cf_IntFrame		
          *DataSet.IntAuxFrames(i) = cb_IntAuxFrame		

          sxaddpar, *DataSet.Headers(i), 'NAXIS'+strg(n_Dim-1), unx
          sxaddpar, *DataSet.Headers(i), 'NAXIS'+strg(n_Dim), uny

       end

    end

    return, OK

end

