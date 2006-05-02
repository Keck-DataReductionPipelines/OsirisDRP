pro clear_frame, DataSet, i, ALL=ALL, DATA=DATA, NOISE=NOISE, Q=Q, HEADER=HEADER

   if ( keyword_set ( ALL ) or keyword_Set ( DATA ) ) then begin
	*DataSet.Frames[i]=0.0  
   endif

   if ( keyword_set ( ALL ) or keyword_Set ( NOISE ) ) then begin
	*DataSet.IntFrames[i]=0.0 
   endif

   if ( keyword_set ( ALL ) or keyword_Set ( Q ) ) then begin
	*DataSet.IntAuxFrames[i]=0.0 	
   endif

   if ( keyword_set ( ALL ) or keyword_Set ( HEADER ) ) then begin
	*DataSet.Headers[i]=0.0 
   endif

end
