;-----------------------------------------------------------------------
; NAME: rename_000 
;
; PURPOSE: To rename a file to something better than the default name
;
; PARAMETERS IN RPBCONFIG.XML : None
;
; INPUT-FILES : None
;
; OUTPUT : Renames the previously-saved dataset file, to something of the user's
; choice. Use this module immediately after 'Save Dataset' to replace the
; default file name. The parameters it accepts are OutputDir, for the new 
; output directory (which can be the same as the old one) and OutputFilename,
; for the new filename. 
;
; INPUT : 
;
; DATASET : not changed
;
; QUALITY BITS : ignored
;
; DEBUG : nothing special
;
; MAIN ROUTINE : None
;
; SAVES : see OUTPUT
;
; NOTES : None
;
; STATUS : works OK
;
; HISTORY : 2006-03-02, created
; 			2007-06-25  Updated to work on Pipeline version 2.0
;
; AUTHOR : Marshall Perrin <mperrin@berkeley.edu>
;  based loosely on savedatset.pro by Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION rename_000, DataSet, Modules, Backbone

    COMMON APP_CONSTANTS

    functionName = 'savedatset_000' ; masquerade! Do this to ensure we compute
									; the exact same filename as was just used
									; by the real savedatset_000
									; to save the data originally.
    ; save starting time
    T = systime(1)

    drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1

    ; check integrity
    stModule =  check_module( DataSet, Modules, Backbone, functionName )
    if ( NOT bool_is_struct ( stModule ) ) then $
       return, error ('ERROR IN CALL ('+strtrim(functionName)+'): Integrity check failed.')

    b_Debug = fix(Backbone->getParameter('savedatset_COMMON___Debug')) eq 1 

    

	; Ugly hack: Figure out what file name was used by default in savedatset
	i=0 ; only one frame!
    thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
	c_File = make_filename ( DataSet.Headers[i], Modules[thisModuleIndex].OutputDir, stModule.SaveExt )
	nFrames = Backbone->getValidFrameCount(DataSet.Name)
	if nFrames gt 1 then message,"Don't know how to handle multiple frames!!"
    if ( strpos(c_File ,'.fits' ) ne -1 ) then $
          c_File1 = strmid(c_File,0,strlen(c_File)-5)+'.fits' $
       else begin 
          warning, 'WARNING('+functionName+'): Filename is not fits compatible. Adding .fits.'
          c_File1 = c_File+'_'+strg(i)+'.fits'
       end
	message,/info,"Guessed file is at "+c_File1

	; now we need to move the file to the user-requested name
	functionName = 'rename_000' ; stop masquerading as savedatset.
	
    thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
	outputdir = Modules[thisModuleIndex].OutputDir
	if ( strmid(outputdir, strlen(outputdir)-1,1) ne "/") then outputdir=outputdir+"/"
	if tag_exist( Modules[thisModuleIndex], "OutputFilename") then OutputFilename = Modules[thisModuleIndex].OutputFilename else OutputFilename="OutputFile.fits"
		
    new_File = outputdir + drpXlateFileName(OutputFilename)

	message,/info, "Going to move "+c_File1+" to "+new_file

	; by default we allow overwriting. TODO: make this a user-selectable
	; parameter. 
	file_move, c_File1, new_file,/overwrite 

	; hack; IDL provides no easy way to check the status of file_move. 
	; So just assume it succeeded.
	b_stat = OK
	

    if ( b_Stat eq OK ) then begin
       report_success, functionName, T
       return, OK
    endif else return, b_Stat

end
