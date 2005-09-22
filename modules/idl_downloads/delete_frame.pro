pro delete_frame, DataSet, i, ALL=ALL, DATA=DATA, NOISE=NOISE, Q=Q, HEADER=HEADER

   if ( keyword_set ( ALL ) or keyword_Set ( DATA ) ) then begin
      tempPtr = PTR_NEW(/ALLOCATE_HEAP)	; Create a new, temporary, pointer variable
      *tempPtr = *DataSet.Frames[i]        ; Use it to save a pointer to the old data
      PTR_FREE, tempPtr			; Free the old data using the temporary pointer
   end

   if ( keyword_set ( ALL ) or keyword_Set ( NOISE ) ) then begin
      tempPtr = PTR_NEW(/ALLOCATE_HEAP)	
      *tempPtr = *DataSet.IntFrames[i]	
      PTR_FREE, tempPtr			
   end

   if ( keyword_set ( ALL ) or keyword_Set ( Q ) ) then begin
      tempPtr = PTR_NEW(/ALLOCATE_HEAP)	
      *tempPtr = *DataSet.IntAuxFrames[i]
      PTR_FREE, tempPtr			
   end

   if ( keyword_set ( ALL ) or keyword_Set ( HEADER ) ) then begin
      tempPtr = PTR_NEW(/ALLOCATE_HEAP)	
      *tempPtr = *DataSet.Headers[i]	
      PTR_FREE, tempPtr
   end

end
