;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; @BEGIN
;
; @NAME oplipy_000
;
; @PURPOSE Takes a 3-D cube and extensions and flips 
; the cube in the y dimension. This module is needed 
; for data after Feb 2012 when OSIRIS moved to Keck I 
; in order to get the handedness correct with one less
; mirro in the path to OSIRIS.
;
;
; @@@PARAMETERS
;
;   none
;
; @CALIBRATION-FILES none
;
; @INPUT 3-d cube and extensions
;
; @OUTPUT 3-d cube and extensions (flipped)
;
; @QBITS all bits checked
;
; @DEBUG nothing special
;
; @SAVES nothing
;
; @NOTES 
;
; @STATUS not tested
;
; @HISTORY 04.10.2012, created
;
; @AUTHOR  R. D. Campbell
;          J. E. Lyke
;
; @END
;
;-----------------------------------------------------------------------

FUNCTION oflipy_000, DataSet, Modules, Backbone

   COMMON APP_CONSTANTS

   functionName = 'oflipy_000'

   ; save starting time
   T = systime(1)

   drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1


   BranchID = Backbone->getType()
   nFrames  = Backbone->getValidFrameCount(DataSet.Name)

   for i=0, nFrames-1 do begin
      tel = strtrim(sxpar(*DataSet.Headers[i], 'TELESCOP', count = n))
      if tel eq 'Keck II' then begin
            sxaddpar, *DataSet.Headers[i],'FLIP','FALSE', $
                 'OSIRIS move to Keck I necessitates a flip'
            sxaddhist, 'Cube was acquired on Keck II, thus not flipped', *DataSet.Headers[i]
            print, 'oflip Y ignored, keck II data'
      endif else begin
           
      
;
; flip cubes in the Y dimension (rows) to make the handedness correct on Keck I
; Change made in March of 2012 as part of the recommissioning on Keck I
; JL and RDC
;
        *DataSet.Frames[i] = reverse(*DataSet.Frames[i],2,/overwrite)         ; data
        *DataSet.IntFrames[i] = reverse(*DataSet.IntFrames[i],2,/overwrite)   ; noise
        *DataSet.IntAuxFrames[i] = reverse(*DataSet.IntAuxFrames[i],2,/overwrite)  ; quality      
        sxaddpar, *DataSet.Headers[i],'FLIP','TRUE', 'OSIRIS move to Keck I necessitates a flip'
        sxaddhist, 'Cube was acquired on Keck I, thus has been flipped', *DataSet.Headers[i]
        print, 'Cube flipped in Y , Keck I data'
     endelse
 
   endfor

   return, OK

end
