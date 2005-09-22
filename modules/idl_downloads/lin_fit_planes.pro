
FUNCTION lin_fit_planes, p_Frames, p_IntFrames, p_IntAuxFrames, nFrames, vf_X, nPoints

   COMMON APP_CONSTANTS

   if ( nFrames lt nPoints ) then $
      return, error('ERROR IN CALL (lin_fit_planes.pro): nFrames lt nPoints.')

   if ( bool_pointer_integrity ( p_Frames, p_IntFrames, p_IntAuxFrames, $
                                 nFrames, 'lin_fit_planes.pro', /IMAGE ) ne OK ) then $
      return, error ( 'ERROR IN CALL (lin_fit_planes.pro): Integrity check failed (2).')

   n_Dims = size ( *p_Frames(0) )

   mf_A     = make_array ( size = n_Dims )
   mf_B     = make_array ( size = n_Dims )
   mf_SA    = make_array ( size = n_Dims )
   mf_SB    = make_array ( size = n_Dims )
   mf_Prob  = make_array ( size = n_Dims )
   mb_Count = make_array ( /BYTE, size = n_Dims )

   vf_Y = fltarr ( nFrames )
   vf_N = fltarr ( nFrames )
   vb_S = bytarr ( nFrames )

   for i=0, n_Dims(1)-1 do begin
      for j=0, n_Dims(2)-1 do begin

         for k=0, nPoints-1 do begin
            vf_Y(k) = (*p_Frames(k))(i,j)
            vf_N(k) = (*p_IntFrames(k))(i,j)
            vb_S(k) = (*p_IntAuxFrames(k))(i,j)
         end

         vi_Valid = where ( valid ( vf_Y, vf_N, vb_S ), n_Valid )
 
         mb_Count(i,j) = n_Valid    

         if ( n_Valid gt 0 ) then begin
            v_Res        = linfit ( vf_X(vi_Valid), vf_Y(vi_Valid), MEASURE_ERRORS=vf_N(vi_Valid), SIGMA=sigma, PROB=prob )
            mf_A(i,j)    = v_Res(0)
            mf_B(i,j)    = v_Res(1)
            mf_SA(i,j)   = sigma(0)
            mf_SB(i,j)   = sigma(1)
            mf_Prob(i,j) = prob
         end
      end
   end

   return, {mf_A:mf_A,mf_B:mf_B,mf_SA:mf_SA,mf_SB:mf_SB,mf_Prob:mf_Prob,mb_Count:mb_Count}

end
