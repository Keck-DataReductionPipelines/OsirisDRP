;-----------------------------------------------------------------------
; NAME:  save_dataset 
;
; PURPOSE: save the dataset
;
; INPUT :  DataSet     : the DataSet pointer.
;          nFrames     : number of datasets 
;          s_OutputDir : the output directory
;          s_Ext       : output filename extension
;          /DEBUG      : initializes debugging mode
;
; OUTPUT : updates the Dataset
;
; STATUS : untested
;
; HISTORY : 23.1.2005, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

function save_dataset, DataSet, nFrames, s_OutputDir, s_Ext, DEBUG=DEBUG

    COMMON APP_CONSTANTS

    functionName = 'save_dataset'

    for i=0, nFrames-1 do begin

       c_File = make_filename ( DataSet.Headers[i], s_OutputDir, s_Ext )
       if ( NOT bool_is_string(c_File) ) then $
          return, error('FAILURE ('+functionName+'): Output filename creation failed.')

       if ( strpos(c_File ,'.fits' ) ne -1 ) then $
;          c_File1 = strmid(c_File,0,strlen(c_File)-5)+'_'+strg(i)+'.fits' $
          c_File1 = strmid(c_File,0,strlen(c_File)-5)+'.fits' $
       else begin 
          warning, 'WARNING('+functionName+'): Filename is not fits compatible. Adding .fits.'
          c_File1 = c_File+'_'+strg(i)+'.fits'
       end

       writefits, c_File1, float(*DataSet.Frames(i)), *DataSet.Headers[i]
       writefits, c_File1, float(*DataSet.IntFrames(i)), /APPEND
       writefits, c_File1, byte(*DataSet.IntAuxFrames(i)), /APPEND

       if ( keyword_set ( DEBUG ) ) then begin
          debug_info, 'DEBUG INFO ('+functionName+'): File '+c_File1+' successfully written.'
          fits_help, c_File1
       end

    end

    return, OK

end
