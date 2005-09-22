

pro intauxframe_compatibility, DataSet, n_Sets, SETNOISE=SETNOISE, VALNOISE=VALNOISE, $
   VALB0=VALB0, VALB1=VALB1, VALB2=VALB2, VALB3=VALB3, $
   SETB0=SETB0, SETB1=SETB1, SETB2=SETB2, SETB3=SETB3, $
   NOISE2WEIGHT=NOISE2WEIGHT, WEIGHT2NOISE=WEIGHT2NOISE

    for i=0, n_Sets-1 do begin

      if ( keyword_set ( SETNOISE ) ) then begin
         *DataSet.IntFrames[i] = make_array(SIZE=size(*DataSet.IntFrames[i]), VALUE=float(VALNOISE))
         print, 'Setting intframe values to ',VALNOISE
      end
      if ( keyword_set ( SETB0 ) ) then begin
         *DataSet.IntAuxFrames[i] = setbit(*DataSet.IntAuxFrames[i],0,VALB0)
         print, 'Setting Bit 0 to ',VALB0
      end
      if ( keyword_set ( SETB1 ) ) then begin
         *DataSet.IntAuxFrames[i] = setbit(*DataSet.IntAuxFrames[i],1,VALB1)
         print, 'Setting Bit 1 to ',VALB1
      end
      if ( keyword_set ( SETB2 ) ) then begin
         *DataSet.IntAuxFrames[i] = setbit(*DataSet.IntAuxFrames[i],2,VALB2)
          print, 'Setting Bit 2 to ',VALB2
     end 
      if ( keyword_set ( SETB3 ) ) then begin
         *DataSet.IntAuxFrames[i] = setbit(*DataSet.IntAuxFrames[i],3,VALB3)
         print, 'Setting Bit 3 to ',VALB3
      end
      if ( keyword_set ( NOISE2WEIGHT ) ) then begin
         mi_Valid = where ( valid(*DataSet.Frames, *DataSet.IntFrames[i], *DataSet.IntAuxFrames), n_Valid )
         if ( n_Valid gt 0 ) then $
            (*DataSet.IntFrames[i])(mi_Valid) = 1./(*DataSet.IntFrames[i])(mi_Valid)^2
         print, 'Converting '+strg(n_Valid)+' pixel from noise to weight.'
      end

      if ( keyword_set ( WEIGHT2NOISE ) ) then begin
         mi_Valid = where ( valid(*DataSet.Frames, *DataSet.IntFrames[i], *DataSet.IntAuxFrames), n_Valid )
         if ( n_Valid gt 0 ) then $
            (*DataSet.IntFrames[i])(mi_Valid) = 1./sqrt((*DataSet.IntFrames[i])(mi_Valid))
         print, 'Converting '+strg(n_Valid)+' pixel from noise to weight.'

      end

   end

end
