;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; NAME:  subtracsky_000
;
; PURPOSE: subtract sky
;
; ALLOWED BRANCH IDS: ARP_SPEC, SRP_SPEC, ORP_SPEC, ORP_IMAG, SRP_IMAG
;
; PARAMETERS IN RPBCONFIG.XML : 
;    subtracsky_COMMON___Debug : bool, initializes the debugging mode
;
; MINIMUM/MAXIMUM NUMBER OF ALLOWED INPUT DATASETS : 1/-
;
; INPUT-FILES : Optional external sky frame
;
; OUTPUT : None, updates Dataset
;
; INPUT : 2d frames
;
; DATASET : the sky subtracted images are put at the beginning of the
;           dataset pointer array.
;
; QUALITY BITS : 0th     : checked
;                1st-3rd : ignored
;
; SPECIAL FITSKEYWORDS :
;
;          SKY : specifying the observing mode 
;                   STARE    : stare mode (not supported yet)
;                   NOD_ODD  : nodding mode, 0th frame is object
;                   NOD_EVEN : nodding mode, 0th frame is sky
;
;          The SKY keyword is ignored if an external sky is provided
;          (as calibration file).
;
;          ISSKY : 0, 1 
;          ISOBJ : 0, 1
;
; DEBUG : nothing special
;
; MAIN ROUTINE : frame_op.pro
;
; SAVES : see OUTPUT
;
; NOTES : - if a calibration file is given it is assumed that this
;           file is the sky frame to be subtracted from all object frames.
;
;         - all datasets must have the same SKY keyword. A mixing of 
;           skymodes is not allowed.
;
;         - the STARE mode (keyword SKY) is not supported yet
;
;         - if the SKY keyword equals NOD_EVEN or NOD_ODD than the
;           frame following a sky frame is assumed to be an object
;           frame. 
;
; STATUS : not tested
;
; HISTORY : 13.5.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION subtracsky_000, DataSet, Modules, Backbone

    COMMON APP_CONSTANTS

    functionName = 'subtracsky_000'
    ; save starting time
    T = systime(1)

    drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1

    ; check integrity

    BranchID = Backbone->getType()

    if ( NOT ( BranchID eq 'ARP_SPEC' or BranchID eq 'SRP_SPEC' or BranchID eq 'ORP_SPEC' or $
         BranchID eq 'ORP_IMAG' or BranchID eq 'SRP_IMAG' ) ) then $
       return, error('ERROR IN CALL (' + functionName + '): Wrong Branch ID.')

    n_Sets = Backbone->getValidFrameCount(DataSet.Name)

    ; check integrity
    if ( bool_dataset_integrity( DataSet, Backbone, functionName, /IMAGE ) ne OK ) then $
       return, error ('ERROR IN CALL ('+functionName+'): integrity check failed.')

    ; integrity ok
    b_Debug = fix(Backbone->getParameter('subtracsky_COMMON___Debug')) eq 1

    vi_issky = where(fix( get_kwd( DataSet.Headers, n_Sets, 'ISSKY' )), n_Sky)
    vi_isobj = where(fix( get_kwd( DataSet.Headers, n_Sets, 'ISOBJ' )), n_Obj)

    if ( n_Sky eq 0 or n_Obj eq 0 ) then $
       return, error ('ERROR IN CALL (subtracsky_000.pro): ISSKY or ISOBJ keyword not properly set.')

    ; check if an external sky needs to be loaded
    thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
    c_File = drpXlateFileName(Modules[thisModuleIndex].CalibrationFile)

    if ( strg(c_File) ne '/' ) then begin

       ; an external sky frame is given

       if ( NOT file_test ( c_File ) ) then $
          return, error ('ERROR IN CALL (subtracsky_000.pro): Sky frame ' + strg(c_File) + ' not found.' )

       pmd_SkyFrame       = ptr_new(READFITS(c_File, /SILENT))
       pmd_SkyIntFrame    = ptr_new(READFITS(c_File, /SILENT, EXT=1))
       pmb_SkyIntAuxFrame = ptr_new(READFITS(c_File, /SILENT, EXT=2))

       if ( b_Debug ) then $
          debug_info, 'DEBUG INFO (subtracsky_000.pro): Sky frame loaded from '+ c_File

       for i=0, n_Obj-1 do begin

          vb_Status = frame_op( DataSet.Frames(vi_isobj(i)), DataSet.IntFrames(vi_isobj(i)), $
                                DataSet.IntAuxFrames(vi_isobj(i)), '-', $
                                pmd_SkyFrame, pmb_SkyIntFrame, pmb_SkyIntAuxFrame, 1, /VALIDS )

          if ( NOT bool_is_vector ( vb_Status ) ) then $
             warning, 'WARNING (subtracsky_000.pro): Sky subtraction on object ' + strg(vi_isobj(i)) + ' failed.'

       end

       ; now delete the sky frames and put the subtracted frames into place
       FOR i = 0, n_Obj-1 DO BEGIN
  
          *DataSet.Frames(i)       = float(*DataSet.Frames(vi_isobj(i)))
          *DataSet.IntFrames(i)    = float(*DataSet.IntFrames(vi_isobj(i)))
          *DataSet.IntAuxFrames(i) = byte(*DataSet.IntAuxFrames(vi_isobj(i)))
          *DataSet.Headers(i)      = *DataSet.Headers(vi_isobj(i))

       ENDFOR

       FOR i = n_Obj, n_Sets-1 DO BEGIN
          tempPtr = PTR_NEW(/ALLOCATE_HEAP)	; Create a new, temporary, pointer variable
          *tempPtr = *DataSet.Frames[i]		; Use it to save a pointer to the old data
          PTR_FREE, tempPtr			; Free the old data using the temporary pointer
    
          tempPtr = PTR_NEW(/ALLOCATE_HEAP)	
          *tempPtr = *DataSet.IntFrames[i]	
          PTR_FREE, tempPtr			
    
          tempPtr = PTR_NEW(/ALLOCATE_HEAP)	
          *tempPtr = *DataSet.IntAuxFrames[i]
          PTR_FREE, tempPtr			
    
          tempPtr = PTR_NEW(/ALLOCATE_HEAP)	
          *tempPtr = *DataSet.Headers[i]	
          PTR_FREE, tempPtr

       end

       ; and reset the ValidFrameCounter
       dummy   = Backbone->setValidFrameCount(DataSet.Name,n_Obj)
       nFrames = Backbone->getValidFrameCount(DataSet.Name)

       if ( nFrames ne n_Obj ) then $
          return, error('FAILURE (subtracsky_000.pro): Failed to reset ValidFrameCount')

    endif else begin

       ; do the scheme that is identified by the SKY keyword

       ; check the SKY keyword
       c_skymode = sxpar ( *DataSet.Headers[0], 'SKY', count=n )
       if ( n ne 1 ) then $
          return, error('ERROR IN CALL (subtracsky_000.pro): Multiple or missing definition of SKY keyword in set 0.')

       if NOT ( c_skymode eq 'STARE' or $
                c_skymode eq 'NOD_EVEN' or c_skymode eq 'NOD_ODD' ) then $
          return, error ('ERROR IN CALL (subtracsky_000.pro): SKY keyword has improper value.' )

       info,'INFO (subtracsky_000.pro): SKY keyword found to be ' + c_skymode + '.'

       ; these modes are not supported yet
       if ( c_skymode eq 'STARE' ) then $
       return, error('ERROR (subtracsky_000.pro): Stare mode not supported yet. Exiting.')

       ; these modes are supported
       if ( c_skymode eq 'NOD_EVEN' or c_skymode eq 'NOD_ODD'  ) then begin

          if ( n_Sky ne n_Obj ) then
             return, error ('ERROR IN CALL (subtracsky_000.pro): Number of Skys is different from number of Objects.')
          if ( n_Sky ne n_Sets/2 or n_Obj ne n_Sets/2  ) then
             return, error ('ERROR IN CALL (subtracsky_000.pro): Number of Skys/Objects inconsistent.')

          if ( c_skymode eq 'NOD_EVEN' ) then begin
             ; assuming that the 0th frame is a skyframe
             vi_sky = 2*indgen(n_Sets/2)
             vi_obj = 2*indgen(n_Sets/2)+1
          end

          if ( c_skymode eq 'NOD_ODD' ) then begin
             ; assuming that the 1st frame is a skyframe
             vi_obj = 2*indgen(n_Sets/2)
             vi_sky = 2*indgen(n_Sets/2)+1
          end

          if ( NOT array_equal ( vi_issky, vi_sky ) ) then $
             return, error ('ERROR IN CALL (subtracsky_000.pro): Skys are not given in specified order.')
          if ( NOT array_equal ( vi_isobj, vi_obj ) ) then $
             return, error ('ERROR IN CALL (subtracsky_000.pro): Objects are not given in specified order.')

          for i=0, n_Sets/2-1 do begin

             if ( b_DEBUG ) then $
                debug_info, 'DEBUG INFO (subtracsky_000.pro): Set ' + strg(vi_sky(i)) + ' is sky ' + 
                   ' Set ' + strg(vi_obj(i)) + ' is object'

             vb_Status = frame_op( DataSet.Frames(vi_obj(i)), DataSet.IntFrames(vi_obj(i)), $
                                   DataSet.IntAuxFrames(vi_obj(i)), '-', $
                                   DataSet.Frames(vi_sky(i)), DataSet.IntFrames(vi_sky(i)), $
                                   DataSet.IntAuxFrames(vi_sky(i)), 1, /VALIDS )

             if ( NOT bool_is_vector ( vb_Status ) ) then $
                warning, 'WARNING (subtracsky_000.pro): Sky subtraction in set ' + strg(vi_obj(i)) + ' failed.'

          end

          ; now delete the sky frames and put the subtracted frames into place
          FOR i = 0, n_Sets/2-1 DO BEGIN
  
             *DataSet.Frames(i)       = float(*DataSet.Frames(vi_obj(i)))
             *DataSet.IntFrames(i)    = float(*DataSet.IntFrames(vi_obj(i)))
             *DataSet.IntAuxFrames(i) = byte(*DataSet.IntAuxFrames(vi_obj(i)))
             *DataSet.Headers(i)      = *DataSet.Headers(vi_obj(i))

          ENDFOR

          FOR i = n_Sets/2, n_Sets-1 DO BEGIN
             tempPtr = PTR_NEW(/ALLOCATE_HEAP)	; Create a new, temporary, pointer variable
             *tempPtr = *DataSet.Frames[i]		; Use it to save a pointer to the old data
             PTR_FREE, tempPtr			; Free the old data using the temporary pointer
    
             tempPtr = PTR_NEW(/ALLOCATE_HEAP)	
             *tempPtr = *DataSet.IntFrames[i]	
             PTR_FREE, tempPtr			
    
             tempPtr = PTR_NEW(/ALLOCATE_HEAP)	
             *tempPtr = *DataSet.IntAuxFrames[i]
             PTR_FREE, tempPtr			
    
             tempPtr = PTR_NEW(/ALLOCATE_HEAP)	
             *tempPtr = *DataSet.Headers[i]	
             PTR_FREE, tempPtr

          end

          ; and reset the ValidFrameCounter
          dummy   = Backbone->setValidFrameCount(DataSet.Name,n_Sets/2)
          nFrames = Backbone->getValidFrameCount(DataSet.Name)

          if ( nFrames ne n_Sets/2 ) then $
             return, error('FAILURE (subtracsky_000.pro): Failed to reset ValidFrameCount')

      end

    end

    drpLog, functionName+' succesfully completed after ' + strg(systime(1)-T) + ' seconds.', /DRF, DEPTH = 1

    return, OK

END
