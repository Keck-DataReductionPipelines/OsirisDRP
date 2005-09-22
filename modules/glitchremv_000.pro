;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; NAME:  glitchremv_000
;
; PURPOSE: sets quality bit of glitchy pixels to zero or return a mask
;
; PARAMETERS IN RPBCONFIG.XML :
;
;    glitchremv_COMMON___Debug         : initialize debugging mode 
;    glitchremv_COMMON___Mask          : set 1 to get the mask or 0 to
;                                        mark the pixels
;    glitchremv_COMMON___LowerLimit    : pixels with values less than
;                                        glitchremv_COMMON___LowerLimit are marked as bad
;    glitchremv_COMMON___BoxHalfSize   : half size of the box around
;                                        the current pixel to determine the median value 
;    glitchremv_COMMON___BoxSigma      : Sigma 
;    glitchremv_COMMON___LineHalfSize  : half size of the line around
;                                        the current pixel to determine the median value 
;    glitchremv_COMMON___LineSigma     : Sigma
; 
; 
; INPUT-FILES : None
;
; OUTPUT : None
;
; DATASET : updates datsaet
;
; QUALITY BITS : ignored
;
; DEBUG : nothing special
;
; MAIN ROUTINE : 
;
; SAVES : see Output
;
; NOTES : None
;
; STATUS : not tested
;
; HISTORY : 13.3.2005, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION glitchremv_000, DataSet, Modules, Backbone

    COMMON APP_CONSTANTS

    functionName = 'glitchremv_000'

    ; save the starting time
    T = systime(1)

    drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1

    ; check integrity
    stModule =  check_module( DataSet, Modules, Backbone, functionName )
    if ( NOT bool_is_struct ( stModule ) ) then $
       return, error ('ERROR IN CALL ('+strtrim(functionName)+'): Integrity check failed.')

    b_Debug        = fix(Backbone->getParameter('glitchremv_COMMON___Debug'))
    b_Mask         = fix(Backbone->getParameter('glitchremv_COMMON___Mask'))    
    d_LowerLimit   = float(Backbone->getParameter('glitchremv_COMMON___LowerLimit'))    
    i_BoxHalfSize  = fix(Backbone->getParameter('glitchremv_COMMON___BoxHalfSize'))   
    d_BoxSigma     = float(Backbone->getParameter('glitchremv_COMMON___BoxSigma'))    
    i_LineHalfSize = fix(Backbone->getParameter('glitchremv_COMMON___LineHalfSize'))  
    d_LineSigma    = float(Backbone->getParameter('glitchremv_COMMON___LineSigma'))

    i_MedWidth     = fix(Backbone->getParameter('glitchremv_COMMON___Cube_MedianWidth'))
    i_StdDevWidth  = fix(Backbone->getParameter('glitchremv_COMMON___Cube_StdDevWidth'))
    d_CubeSigma    = fix(Backbone->getParameter('glitchremv_COMMON___Cube_Sigma'))

    nFrames = Backbone->getValidFrameCount(DataSet.Name)

    for i=0, nFrames-1 do begin

       ; check for optional parameters in header
       dummy = sxpar(*DataSet.Headers(i), 'GR_LL', count=n)
       if ( n eq 1 ) then begin
          info, 'INFO (glitchremv_000.pro): Overriding LowerLimit from RPBConfig.xml.'
          d_LowerLimit = float(dummy)  
       end

       dummy = sxpar(*DataSet.Headers(i), 'GR_BHS', count=n)
       if ( n eq 1 ) then begin
          info, 'INFO (glitchremv_000.pro): Overriding BoxHalfSize from RPBConfig.xml.'
          i_BoxHalfSize = fix(dummy)
       end

       dummy = sxpar(*DataSet.Headers(i), 'GR_BS', count=n)
       if ( n eq 1 ) then begin
          info, 'INFO (glitchremv_000.pro): Overriding BoxSigma from RPBConfig.xml.'
          d_BoxSigma = float(dummy)  
       end

       dummy = sxpar(*DataSet.Headers(i), 'GR_LHS', count=n)
       if ( n eq 1 ) then begin
          info, 'INFO (glitchremv_000.pro): Overriding LineHalfSize from RPBConfig.xml.'
          i_LineHalfSize = fix(dummy)  
       end

       dummy = sxpar(*DataSet.Headers(i), 'GR_LS', count=n)
       if ( n eq 1 ) then begin
          info, 'INFO (glitchremv_000.pro): Overriding LineSigma from RPBConfig.xml.'
          d_LineSigma = float(dummy)  
       end

       dummy = sxpar(*DataSet.Headers(i), 'GR_CMW', count=n)
       if ( n eq 1 ) then begin
          info, 'INFO (glitchremv_000.pro): Overriding MedWidth (cubes only) from RPBConfig.xml.'
          i_MedWidth = fix(dummy)  
       end

       dummy = sxpar(*DataSet.Headers(i), 'GR_CSDW', count=n)
       if ( n eq 1 ) then begin
          info, 'INFO (glitchremv_000.pro): Overriding StdDevWidth (cubes only) from RPBConfig.xml.'
          i_StdDevWidth = fix(dummy)  
       end

       dummy = sxpar(*DataSet.Headers(i), 'GR_CS', count=n)
       if ( n eq 1 ) then begin
          info, 'INFO (glitchremv_000.pro): Overriding CubeSigma (cubes only) from RPBConfig.xml.'
          d_CubeSigma = float(dummy)  
       end


       info, ['INFO (glitchremv_000.pro): Starting with :', $
              '   LowerLimit            : '+strg(d_LowerLimit), $
              '   BoxHalfSize           : '+strg(i_BoxHalfSize), $
              '   BoxSigma              : '+strg(d_BoxSigma), $
              '   LineHalfSize          : '+strg(i_LineHalfSize), $
              '   LineSigma             : '+strg(d_LineSigma), $
              '   MedWidth (cubes only) : '+strg(i_MedWidth), $
              '   StdWidth (cubes only) : '+strg(i_StdDevWidth), $
              '   Sigma (cubes only)    : '+strg(d_CubeSigma) ]

       n_dims = size(*DataSet.Frames(i))

       vn_glitch = make_array(n_dims(2),n_dims(3),value=0,/int)

       if ( n_dims(0) eq 3 ) then begin

          info,'INFO (glitchremv_000.pro): Detecting glitches in cube '+strtrim(string(i),2)          

          mb_Inside = valid ( *DataSet.Frames(i),*DataSet.IntFrames(i),*DataSet.IntAuxFrames(i), /INSIDE ) 
          mb_Valid  = valid ( *DataSet.Frames(i),*DataSet.IntFrames(i),*DataSet.IntAuxFrames(i) ) 

          ; check lower limit for inside pixels
          mb_Mask = make_array(/BYTE, size=n_dims, Value=0b)
          Mask = where (*DataSet.Frames(i) lt d_LowerLimit and mb_Inside , n)
          if ( n gt 0 ) then $
             mb_Mask ( Mask ) = 1b
          info, 'INFO (glitchremv_000.pro): '+strg(total(long(mb_Mask)))+' pixel have signal lower than limit: '+strg(d_LowerLimit)+'.'

          for x=0, n_dims(2)-1 do begin
             info, 'INFO (glitchremv_000.pro): In line '+strg(x)+' now.'
             for y=0, n_dims(3)-1 do begin

                vi_Valid = where ( mb_Valid(*,x,y) eq 1, n_Valid )

                if ( n_Valid gt (i_MedWidth > i_StdDevWidth) ) then begin

                   vd_Spec     = (reform((*DataSet.Frames(i))(*,x,y)))(vi_Valid)
                   vd_SpecMed  = median( vd_Spec, i_MedWidth )

                   vd_Local_Std = make_array(/FLOAT, n_Valid, value=0.)
                   vd_Local_Med = make_array(/FLOAT, n_Valid, value=0.)
  
                   for l=0L, n_Valid-1 do begin

                      ll = (l-i_StdDevWidth)>0
                      ul = (l+i_StdDevWidth)<(n_elements(vd_Spec)-1)

                      vd_Local_Std(l) = stddev(vd_SpecMed(ll:ul))
                      vd_Local_Med(l) = median(vd_Spec(ll:ul))

                   end

                   vd_Local_Std = median(vd_Local_Std, 75 < (n_elements(vd_Spec)-1))

                   vi_Mask = where ( vd_Local_Med ne 0. and abs( vd_Spec - vd_Local_Med ) gt $
                                     d_CubeSigma * vd_Local_Std, n )

                   vn_glitch(x,y) = n

                   if ( n gt 0 ) then $
                      mb_Mask(vi_Valid(vi_Mask),x,y) = 1b

                   info,'INFO (glitchremv_000.pro): Found '+strg(total(mb_Mask(*,x,y)))+' crazy channels in pixel ['+strg(x)+','+strg(y)+'].'

                   if ( b_Debug eq 1 ) then begin
                      dummy = where( finite(vd_Spec), nnn)
                      if ( nnn gt 2 ) then begin
                         plot, vd_Spec, /xst,/yst, title='Pixel ['+strg(x)+','+strg(y)+']'
                         oplot, vd_Local_Med, color=1
                         oplot, vd_Local_Med + d_CubeSigma * vd_Local_Std, color=2
                         oplot, vd_Local_Med - d_CubeSigma * vd_Local_Std, color=2
                         empty 
                      end
                   end
                end
             end
          end

          info,'INFO (glitchremv_000.pro): Detected '+strg(mean(vn_glitch))+' (mean) and ' + $
             strg(median(vn_glitch))+' (median) glitches per spectrum.'


       endif else begin

          ; check lower limit 
          mb_Mask = make_array(/BYTE, size=n_dims, Value=0b)
          Mask = where (*DataSet.Frames(i) lt d_LowerLimit , n)
          if ( n gt 0 ) then $
             mb_Mask ( Mask ) = 1b

          dummy = where ( mb_Mask ne 0, n ) 
          debug_info,'DEBUG INFO ('+strg(functionName)+'): '+strg(n)+' pixel lower than limit.'

          if ( d_BoxSigma gt 0 ) then begin
 
             mb_Mask2 = make_array(/BYTE, size=n_dims, Value=0b)

             for x=0, n_dims(1)-1 do begin

                lx = (x-i_BoxHalfSize)>0
                ux = (x+i_BoxHalfSize)<n_dims(1)-1

                if ( ( x Mod (n_dims(1)/10) ) eq 0 ) then begin
                   dummy = where ( mb_Mask ne 0, n )
                   debug_info,' DEBUG INFO ('+functionName+'): Step 2 ' + strg(fix(100.*float(x)/(float(n_dims(1))))) + $
                      '% done, ' + strg(n) + ' pixel now declared as bad.'
                end

                for y=0, n_dims(2)-1 do begin

                   ly = (y-i_BoxHalfSize)>0
                   uy = (y+i_BoxHalfSize)<n_dims(2)-1

                   mb_Mask2(x,ly:uy) = 1b
                   mb_Mask2(lx:ux,y) = 1b

                   vi_Valid = where( mb_Mask(lx:ux,ly:uy) eq 0 and mb_Mask2(lx:ux,ly:uy) eq 0, nn )

                   if ( nn gt 1 ) then begin
                      m = ((*DataSet.Frames(i))(lx:ux,ly:uy))(vi_Valid)

                      sdev_local = stdev(m)
                      med_local = median(m)

                      if ( abs( (*DataSet.Frames(i))(x,y) - med_local ) gt d_BoxSigma*sdev_local ) then mb_Mask(x,y) = mb_Mask(x,y) + 2b

                   end

                   mb_Mask2(x,ly:uy) = 0b
                   mb_Mask2(lx:ux,y) = 0b

                end

             end

             delvarx, mb_Mask2

             dummy = where ( mb_Mask ne 0, n )
             debug_info, 'DEBUG INFO ('+strg(functionName)+'): After local noise '+strg(n) + $
                         ' pixel declared as bad.'
          end

          if ( d_LineSigma gt 0 ) then begin

             for x=0, n_dims(1)-1 do begin

                lx = (x-i_LineHalfSize)>0
                ux = (x+i_LineHalfSize)<n_dims(1)-1

                if ( ( x Mod (n_dims(1)/10) ) eq 0 ) then begin
                   dummy = where ( mb_Mask ne 0, n )
                   debug_info,' DEBUG INFO ('+functionName+'): Step 3 ' + strg(fix(100.*float(x)/(float(n_dims(1))))) + $
                      '% done, ' + strg(n) + ' pixel now declared as bad.'
                end
 
                for y=0, n_dims(2)-1 do begin

                   if ( mb_Mask(x,y) eq 0 ) then begin

                      v_Line = (*DataSet.Frames(i))(lx:ux,y)
                      vi_Mask = where ( mb_Mask(lx:ux,y) eq 0, n )
                      if ( n gt 2 ) then begin
                         line_sdev = stdev(v_Line(vi_Mask))
                         line_med  = median(v_Line(vi_Mask))
                         if ( abs ((*DataSet.Frames(i))(x,y) - line_med) gt d_LineSigma*line_sdev ) then $
                            mb_Mask(x,y) = mb_Mask(x,y) + 4b
                      endif
                   end
 
                end

             end

             dummy = where ( mb_Mask ne 0, n )
             debug_info, 'DEBUG INFO ('+strg(functionName)+'): After line noise '+strg(n) + $
                         ' pixel declared as bad.'
          end

       end

       thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
       if ( ( b_Mask eq 1 or Modules[thisModuleIndex].Save eq 1 ) ) then begin

          ; Now, save the data
          thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
          c_File = make_filename ( DataSet.Headers[i], Modules[thisModuleIndex].OutputDir, stModule.SaveExt )
          if ( NOT bool_is_string(c_File) ) then $
             return, error('FAILURE ('+strtrim(functionName)+'): Output filename creation failed.')

          h_H = *DataSet.Headers[i]
          sxaddpar, h_H, 'EXTEND', 'T'
          sxaddpar, h_H, 'COMMNT0', 'This is a glitch mask created by ' + functionName
          ; this is a hack for reducing SINFONI data in HK mode, in this region Pa alpha 
          ; is a very prominent feature
;          mb_Mask(1240:1300,*,*) = 0b
          writefits, c_File, byte(mb_Mask)

          if ( b_Debug ) then begin
             debug_info, 'DEBUG INFO ('+strtrim(functionName)+'): File '+c_File+' successfully written.'
             fits_help, c_File
          end

       endif

       if ( b_Mask eq 0 ) then begin

          vi_Mask = where ( mb_Mask ne 0, n )
          if ( n gt 0 ) then $
             (*DataSet.IntAuxFrames(i))(vi_Mask) = setbit( (*DataSet.IntAuxFrames(i))(vi_Mask), 0, 0 )

       end

    end

    report_success, functionName, T

    return, OK

END
