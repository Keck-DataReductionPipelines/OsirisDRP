;+
; NAME: cconfigs__define 
;
; PURPOSE: 
;
; CALLING SEQUENCE: 
;                   
; INPUTS:  
;
; OPTIONAL INPUTS:                     
;
; OPTIONAL KEYWORD INPUTS:
;
; OUTPUTS: 
;
; OPTIONAL OUTPUTS;
;
; EXAMPLE:
;
; NOTES: 
; 
; PROCEDURES USED:
;
; REVISION HISTORY: 28MAY2004 - MWM: edited header
; 	2007-07-03	MDP: Fix multiple pointer leaks on startup.
; 	2007-07-12  MDP: Return to user's original working directory after
; 				     reading in config file.
;- 

function CConfigs::Init, wid_leader=conbase_id, inst_cfg=configs

print, 'initializing configs object'

; set filename
if keyword_set(configs) then begin
    ; populate member variables from the config file
    self.cfg_name=configs.cfg_name
    ; FITS Header Keywords
    self.inst_fitskw=configs.inst_fitskw
    self.itime_fitskw=configs.itime_fitskw
    self.coadds_fitskw=configs.coadds_fitskw
    self.pa_fitskw=configs.pa_fitskw
    self.object_fitskw=configs.object_fitskw
    self.sampmode_fitskw=configs.sampmode_fitskw
    self.numreads_fitskw=configs.numreads_fitskw
    self.platescale_fitskw=configs.platescale_fitskw
    self.array_index_fitskw=configs.array_index_fitskw
    self.lin_disp_fitskw=configs.lin_disp_fitskw
    self.reference_fitskw=configs.reference_fitskw
    self.unit_fitskw=configs.unit_fitskw
    ; Polling functions
    self.polling_rate=configs.polling_rate
    self.testserver=configs.testserver
    self.isframeready=configs.isframeready
    self.getfilename=configs.getfilename
    self.openfiles=configs.openfiles
    self.transition=configs.transition
    self.dir_polling_on=configs.dir_polling_on
    self.poll_dir=configs.poll_dir
    self.server_polling_on=configs.server_polling_on
    self.poll_server=configs.poll_server
	ptr_free,self.dir_arr, self.new_file
    self.dir_arr=ptr_new('', /allocate_heap)
    self.new_files=ptr_new('', /allocate_heap)
    self.conbase_dir=configs.conbase_dir
    ; Image Window parameters
    self.draw_xs=configs.draw_xs
    self.draw_ys=configs.draw_ys
    self.diagonal=configs.diagonal
    ; Session Info
    self.color_table=configs.color_table
    self.pointer_type=configs.pointer_type 
    ptr_free, self.axes_labels2d
    ptr_free, self.axes_labels3d
    self.axes_labels2d=configs.axes_labels2d
    self.axes_labels3d=configs.axes_labels3d
    self.imscalemaxcon=configs.imscalemaxcon
    self.imscalemincon=configs.imscalemincon
    self.displayasdn=configs.displayasdn
    self.collapse=configs.collapse
    ; QL2 info
    self.pa_function=cconfigs.pa_function
    self.exit_question=cconfigs.exit_question
    self.ParentBaseId=conbase_id

endif else begin

    ; set the OSIRIS default member values 
    self.cfg_name='OSIRIS'
    ; FITS Header Keywords
    self.inst_fitskw='INSTRUME'
    self.itime_fitskw='ITIME'
    self.coadds_fitskw='COADDS'
    self.pa_fitskw='SCAMPA'
    self.object_fitskw='OBJECT'
    self.sampmode_fitskw='SAMPMODE'
    self.numreads_fitskw='MULTISCA'
    self.platescale_fitskw='SS1NAME'
    self.array_index_fitskw='CRPIX1'
    self.reference_fitskw='CRVAL1'
    self.unit_fitskw='CUNIT1'
    self.lin_disp_fitskw='CDELT1'
    ; Polling functions
    self.polling_rate=1.
    self.testserver='osiris_testserver'
    self.isframeready='osiris_isframeready'
    self.getfilename='osiris_getfilename'
    self.openfiles='osiris_openfiles'
    self.transition=1
    self.dir_polling_on=0.
    self.poll_dir=''
    self.server_polling_on=0.
    self.poll_server=''
	ptr_free,self.dir_arr, self.new_files
    self.dir_arr=ptr_new('', /allocate_heap)
    self.new_files=ptr_new('', /allocate_heap)
    self.conbase_dir=''

    ; Image Window parameters
    self.draw_xs=512.0
    self.draw_ys=512.0
    self.diagonal=10.
    ; Session Info
    self.color_table=1
    self.pointer_type=24
	ptr_free, self.axes_labels2d, self.axes_labels3d
    self.axes_labels2d=ptr_new(['AXIS 1', 'AXIS 2', 'AXIS 3'], /allocate_heap)
    self.axes_labels3d=ptr_new(['AXIS 1', 'AXIS 2', 'AXIS 3'], /allocate_heap)
    self.imscalemaxcon=5.
    self.imscalemincon=-3.
    self.displayasdn='As DN/s'
    self.collapse=0
    self.pa_function='osiris_calc_pa'
    self.exit_question=0
    ; QL2 info
    self.ParentBaseId=conbase_id

endelse

return, 1

end

function CConfigs::CheckConfigFile, filename

error_flag=0
cd, curr=currentdir

; check file's existance
file=(ql_file_search(filename))[0]
if file eq '' then begin
    ; error
    error_flag=1
endif else begin
    ; file exists -> break down name
    dir=ql_getpath(file)
    config_name=ql_getfilename(file)
    ; get the name without the extension
    config_namenext=ql_get_namenext(config_name)

    ; go to dir where file is
    cd, dir
    ; set up error handler
    catch, error_status
    if error_status ne 0 then begin
        print, 'error caught'
        error_flag=1
        goto, DONE
    endif
    ; run file
    inst_config=call_function(config_namenext)
    ; make sure inst_config is a valid structure 
    if (tag_names(inst_config, /structure_name) eq 'CCONFIGS') then begin
        config_valid=1
    endif else begin
        error_flag=1
    endelse    
endelse

DONE:
if error_flag eq 1 then begin
    ; display error message
    answer=dialog_message('Error loading configuration file.  Please try again.', /error, $
                          dialog_parent=self.ParentBaseId)
    config_valid=0
endif

cd, currentdir

; return structure
return, config_valid

end

pro CConfigs::LoadConfigFile, filename

; get the name of the file without the extension
config_name=ql_getfilename(filename)
config_namenext=ql_get_namenext(config_name)

inst_config=call_function(config_namenext, error)

if (error ne -1) then begin

    error_message=''
    error_flag=0

    ; populate member variables from the loaded config file
    if ((size(inst_config.cfg_name))[1] eq 7) then begin
        self.cfg_name=inst_config.cfg_name
    endif else begin
        error_message=error_message+' cfg_name'
        error_flag=1    
    endelse

    ; FITS Header Keywords
    if ((size(inst_config.inst_fitskw))[1] eq 7) then begin
        self.inst_fitskw=inst_config.inst_fitskw
    endif else begin
        error_message=error_message+' inst_fitskw'
        error_flag=1    
    endelse

    if ((size(inst_config.itime_fitskw))[1] eq 7) then begin
        self.itime_fitskw=inst_config.itime_fitskw
    endif else begin
        error_message=error_message+' itime_fitskw'
        error_flag=1    
    endelse

    if ((size(inst_config.coadds_fitskw))[1] eq 7) then begin
        self.coadds_fitskw=inst_config.coadds_fitskw
    endif else begin
        error_message=error_message+' coadds_fitskw'
        error_flag=1    
    endelse

    if ((size(inst_config.pa_fitskw))[1] eq 7) then begin
        self.pa_fitskw=inst_config.pa_fitskw
    endif else begin
        error_message=error_message+' pa_fitskw'
        error_flag=1    
    endelse

    if ((size(inst_config.object_fitskw))[1] eq 7) then begin
        self.object_fitskw=inst_config.object_fitskw
    endif else begin
        error_message=error_message+' object_fitskw'
        error_flag=1    
    endelse

    if ((size(inst_config.sampmode_fitskw))[1] eq 7) then begin
        self.sampmode_fitskw=inst_config.sampmode_fitskw
    endif else begin
        error_message=error_message+' sampmode_fitskw'
        error_flag=1    
    endelse

    if ((size(inst_config.numreads_fitskw))[1] eq 7) then begin
        self.numreads_fitskw=inst_config.numreads_fitskw
    endif else begin
        error_message=error_message+' numreads_fitskw'
        error_flag=1    
    endelse

    if ((size(inst_config.platescale_fitskw))[1] eq 7) then begin
        self.platescale_fitskw=inst_config.platescale_fitskw
    endif else begin
        error_message=error_message+' platescale_fitskw'
        error_flag=1    
    endelse

    if ((size(inst_config.array_index_fitskw))[1] eq 7) then begin
        self.array_index_fitskw=inst_config.array_index_fitskw
    endif else begin
        error_message=error_message+' array_index_fitskw'
        error_flag=1    
    endelse

    if ((size(inst_config.lin_disp_fitskw))[1] eq 7) then begin
        self.lin_disp_fitskw=inst_config.lin_disp_fitskw
    endif else begin
        error_message=error_message+' lin_disp_fitskw'
        error_flag=1    
    endelse

    if ((size(inst_config.reference_fitskw))[1] eq 7) then begin
        self.reference_fitskw=inst_config.reference_fitskw
    endif else begin
        error_message=error_message+' reference_fitskw'
        error_flag=1    
    endelse

    if ((size(inst_config.unit_fitskw))[1] eq 7) then begin
        self.unit_fitskw=inst_config.unit_fitskw
    endif else begin
        error_message=error_message+' unit_fitskw'
        error_flag=1    
    endelse

    ; Polling functions

    if ((size(inst_config.polling_rate))[1] eq 4) then begin
        self.polling_rate=inst_config.polling_rate
    endif else begin
        error_message=error_message+' polling_rate'
        error_flag=1    
    endelse

    if ((size(inst_config.testserver))[1] eq 7) then begin
        self.testserver=inst_config.testserver
    endif else begin
        error_message=error_message+' testserver'
        error_flag=1    
    endelse
    
    if ((size(inst_config.isframeready))[1] eq 7) then begin
        self.isframeready=inst_config.isframeready
    endif else begin
        error_message=error_message+' isframeready'
        error_flag=1    
    endelse
    
    if ((size(inst_config.getfilename))[1] eq 7) then begin
        self.getfilename=inst_config.getfilename
    endif else begin
        error_message=error_message+' getfilename'
        error_flag=1    
    endelse

    if ((size(inst_config.openfiles))[1] eq 7) then begin
        self.openfiles=inst_config.openfiles
    endif else begin
        error_message=error_message+' openfiles'
        error_flag=1    
    endelse

    if ((size(inst_config.transition))[1] eq 4) then begin
        self.transition=inst_config.transition
    endif else begin
        error_message=error_message+' transition'
        error_flag=1    
    endelse

    if ((size(inst_config.dir_polling_on))[1] eq 4) then begin
        self.dir_polling_on=inst_config.dir_polling_on
    endif else begin
        error_message=error_message+' dir_polling_on'
        error_flag=1    
    endelse

    if ((size(inst_config.poll_dir))[1] eq 7) then begin
        self.poll_dir=inst_config.poll_dir
    endif else begin
        error_message=error_message+' poll_dir'
        error_flag=1    
    endelse

    if ((size(inst_config.server_polling_on))[1] eq 4) then begin
        self.server_polling_on=inst_config.server_polling_on
    endif else begin
        error_message=error_message+' server_polling_on'
        error_flag=1    
    endelse

    if ((size(inst_config.poll_server))[1] eq 7) then begin
        self.poll_server=inst_config.poll_server
    endif else begin
        error_message=error_message+' poll_server'
        error_flag=1    
    endelse

    if ((size(inst_config.dir_arr))[1] eq 10) then begin
        ptr_free, self.dir_arr
        self.dir_arr=inst_config.dir_arr
    endif else begin
        error_message=error_message+' dir_arr'
        error_flag=1    
    endelse

    if ((size(inst_config.new_files))[1] eq 10) then begin
        ptr_free, self.new_files
        self.new_files=inst_config.new_files
    endif else begin
        error_message=error_message+' new_files'
        error_flag=1    
    endelse

    if ((size(inst_config.conbase_dir))[1] eq 7) then begin
        self.conbase_dir=inst_config.conbase_dir
    endif else begin
        error_message=error_message+' conbase_dir'
        error_flag=1    
    endelse
   
    if ((size(inst_config.draw_xs))[1] eq 4) then begin
        self.draw_xs=inst_config.draw_xs
    endif else begin
        error_message=error_message+' draw_xs'
        error_flag=1    
    endelse
    
    if ((size(inst_config.draw_ys))[1] eq 4) then begin
        self.draw_ys=inst_config.draw_ys
    endif else begin
        error_message=error_message+' draw_ys'
        error_flag=1    
    endelse

    if ((size(inst_config.diagonal))[1] eq 4) then begin
        self.diagonal=inst_config.diagonal
    endif else begin
        error_message=error_message+' diagonal'
        error_flag=1    
    endelse
    
    if ((size(inst_config.color_table))[1] eq 4) then begin
        self.color_table=inst_config.color_table
    endif else begin
        error_message=error_message+' color_table'
        error_flag=1    
    endelse

    if ((size(inst_config.pointer_type))[1] eq 4) then begin
        self.pointer_type=inst_config.pointer_type
    endif else begin
        error_message=error_message+' pointer_type'
        error_flag=1    
    endelse

    if ((size(inst_config.axes_labels2d))[1] eq 10) then begin
        self.axes_labels2d=inst_config.axes_labels2d
    endif else begin
        error_message=error_message+' axes_labels2d'
        error_flag=1    
    endelse

    if ((size(inst_config.axes_labels3d))[1] eq 10) then begin
        self.axes_labels3d=inst_config.axes_labels3d
    endif else begin
        error_message=error_message+' axes_labels3d'
        error_flag=1    
    endelse

    if ((size(inst_config.imscalemaxcon))[1] eq 4) then begin
        self.imscalemaxcon=inst_config.imscalemaxcon
    endif else begin
        error_message=error_message+' imscalemaxcon'
        error_flag=1    
    endelse

    if ((size(inst_config.imscalemincon))[1] eq 4) then begin
        self.imscalemincon=inst_config.imscalemincon
    endif else begin
        error_message=error_message+' imscalemincon'
        error_flag=1    
    endelse

    if ((size(inst_config.displayasdn))[1] eq 7) then begin
        self.displayasdn=inst_config.displayasdn
    endif else begin
        error_message=error_message+' displayasdn'
        error_flag=1    
    endelse

    if ((size(inst_config.collapse))[1] eq 4) then begin
        ; make sure collapse eq 0 or 1
        if ((inst_config.collapse ne 0) and (inst_config.collapse ne 1)) then begin
        error_message=error_message+' collapse not 0. or 1.'
        error_flag=1    
        endif else begin
            self.collapse=inst_config.collapse
        endelse
    endif else begin
        error_message=error_message+' collapse'
        error_flag=1    
    endelse

    if ((size(inst_config.pa_function))[1] eq 7) then begin
        self.pa_function=inst_config.pa_function
    endif else begin
        error_message=error_message+' pa_function'
        error_flag=1    
    endelse

    if ((size(inst_config.exit_question))[1] eq 4) then begin
        self.exit_question=inst_config.exit_question
    endif else begin
        error_message=error_message+' exit_question'
        error_flag=1    
    endelse



    ; print the error message if there was a problem importing any of the
    ; variables
    if (error_flag eq 1) then begin
        message=['There was a problem importing ', error_message, '.', $
                 'These files were not imported to your QL2 session.']
        answer=dialog_message(message, dialog_parent=self.ParentBaseId, /error)
    endif
    
    ; set title bar of display to new config name
    widget_control, self.ParentBaseId, get_uval=conbase_uval
    ;title=self.cfg_name+ ' Quicklook v2.0'
    title=self.cfg_name+ ' Quicklook v2.0'
    widget_control, self.ParentBaseId, tlb_set_title=title

endif

end

pro CConfigs::RemoveNewFile, filename

; this method takes 'filename' and removes that item from the
; stack in self.new_files
tmp_arr=*(self.new_files)

n_modes=size(tmp_arr, /n_elements)
    
exist=where(tmp_arr[*] eq filename)
exist_index=long(exist[0])
    
if (exist_index ne -1) then begin
    nfile_arr=tmp_arr[0]
    cnt1=exist_index-1
    cnt2=exist_index+1
    print, 'adding first element'
    print, nfile_arr
    print, 'exist= ', exist_index, 'cnt1 = ', cnt1, 'cnt2 = ', cnt2


    if ((exist_index ne 0) and (n_elements(tmp_arr) gt 1)) then begin
        ; add the elements prior to the mode you remove
        for i=1,cnt1 do begin
            nfile_arr=[[nfile_arr],[tmp_arr[i]]]
        endfor

        ; add the elements after to the mode you remove
        for i=cnt2,n_modes-1 do begin
            nfile_arr=[[nfile_arr],[tmp_arr[i]]]
        endfor
        *(self.new_files)=nfile_arr
    endif else begin
        *(self.new_files)=''
    endelse
endif

end

pro CConfigs::UpdateParams

widget_control, self.ParentBaseId, get_uval=conbase_uval

; update the color table
loadct, self.color_table
ql_refresh_all, self.ParentBaseId

; update the pointer type
case !version.os_family of
    'unix':     device, cursor_standard=self.pointer_type
    'Windows': device, cursor_standard=32515
    'vms':
    'macos':
    else:
endcase

; set the conbase directory path
if (self.conbase_dir ne '') then begin
    conbase_uval.current_data_directory=self.conbase_dir
    widget_control, self.ParentBaseId, set_uval=conbase_uval
endif

; set the server polling information
cpolling_ptr=conbase_uval.cpolling_ptr
cpolling_obj=*cpolling_ptr

if (self.poll_server ne '') then begin
    cpolling_obj->SetServerName, self.poll_server
endif
        
if (self.server_polling_on eq 1) then begin
    cpolling_obj->SetPollingStatus, 1.
    testserver=cpolling_obj->TestServer()
    if (testserver eq -1) then begin
        cpolling_obj->ReportError, 'server'
    endif else begin
        cpolling_obj->StartTimer, conbase_uval.wids.base
        if (conbase_uval.exist.polling ne 0L) then begin
            widget_control, conbase_uval.exist.polling, get_uval=polling_uval
            widget_control, polling_uval.wids.polling_on, set_value=1
            widget_control, polling_uval.wids.polling_server, set_value=self.poll_server
        endif
    endelse
endif 

; set the directory polling information
if (self.poll_dir ne '') then begin
    cpolling_obj->SetDirectoryName, self.poll_dir
endif

if (self.dir_polling_on eq 1) then begin
    cpolling_obj->SetDirectoryPollingStatus, 1.
    if (ql_file_search(self.poll_dir) eq '') then begin
        cpolling_obj->ReportError, 'directory'
    endif else begin
        cpolling_obj->StartTimer, conbase_uval.wids.base
        newdir_arr=ql_file_search(self.poll_dir+'/*.fits')
        dir_arr_ptr=self->GetDirArr()
        *dir_arr_ptr=newdir_arr
        if (conbase_uval.exist.polling ne 0L) then begin
            widget_control, conbase_uval.exist.polling, get_uval=polling_uval
            widget_control, polling_uval.wids.polling_directory_on, set_value=1
            widget_control, polling_uval.wids.polling_directory_box, set_value=self.poll_dir     
        endif
    endelse
endif

; update the information in the polling gui
cpolling_obj->SetPollingRate, self.polling_rate
if (conbase_uval.exist.polling ne 0L) then begin
    widget_control, conbase_uval.exist.polling, get_uval=polling_uval
    widget_control, polling_uval.wids.polling_interval, set_value=self.polling_rate
endif

end

pro CConfigs::SetCfgName, cfgname
self.cfg_name=cfgname
end

function CConfigs::GetCfgName
return, self.cfg_name
end

pro CConfigs::SetInstFitskw, inst_fitskw
self.inst_fitskw=inst_fitskw
end

function CConfigs::GetInstFitskw
return, self.inst_fitskw
end

pro CConfigs::SetItimeFitskw, itime_fitskw
self.itime_fitskw=itime_fitskw
end

function CConfigs::GetItimeFitskw
return, self.itime_fitskw
end

pro CConfigs::SetCoaddsFitskw, coadds_fitskw
self.coadds_fitskw=coadds_fitskw
end

function CConfigs::GetCoaddsFitskw
return, self.coadds_fitskw
end

pro CConfigs::SetPAFitskw, pa_fitskw 
self.pa_fitskw=pa_fitskw
end

function CConfigs::GetPAFitskw
return, self.pa_fitskw
end

pro CConfigs::SetObjectFitskw, object_fitskw 
self.object_fitskw=object_fitskw
end

function CConfigs::GetObjectFitskw
return, self.object_fitskw
end

pro CConfigs::SetSampModeFitskw, sampmode_fitskw 
self.sampmode_fitskw=sampmode_fitskw
end

function CConfigs::GetSampModeFitskw
return, self.sampmode_fitskw
end

pro CConfigs::SetNumReadsFitskw, numreads_fitskw 
self.numreads_fitskw=numreads_fitskw
end

function CConfigs::GetNumReadsFitskw
return, self.numreads_fitskw
end

pro CConfigs::SetPlatescalekw, platescale_fitskw
self.platescale_fitskw=platescale_fitskw
end

function CConfigs::GetPlateScalekw
return, self.platescale_fitskw
end

pro CConfigs::SetArrayIndexkw, array_index_fitskw
self.array_index_fitskw=array_index_fitskw
end

function CConfigs::GetArrayIndexkw
return, self.array_index_fitskw
end

pro CConfigs::SetLinDispkw, lin_disp_fitskw
self.lin_disp_fitskw=lin_disp_fitskw
end

function CConfigs::GetLinDispkw
return, self.lin_disp_fitskw
end

pro CConfigs::SetReferencekw, reference_fitskw
self.reference_fitskw=reference_fitskw
end

function CConfigs::GetReferencekw
return, self.reference_fitskw
end

pro CConfigs::SetUnitkw, unit_fitskw
self.unit_fitskw=unit_fitskw
end

function CConfigs::GetUnitkw
return, self.unit_fitskw
end

pro CConfigs::SetTestServer, testserver
self.testserver=testserver
end

function CConfigs::GetTestServer
return, self.testserver
end

pro CConfigs::SetIsFrameReady, isframeready
self.isframeready=isframeready
end

function CConfigs::GetIsFrameReady
return, self.isframeready
end

pro CConfigs::SetGetFilename, getfilename
self.getfilename=getfilename
end

function CConfigs::GetFilename
return, self.getfilename
end

pro CConfigs::SetOpenFiles, openfiles
self.openfiles=openfiles
end

function CConfigs::GetOpenFiles
return, self.openfiles
end

pro CConfigs::SetDirArr, dirarr
self.dir_arr=dirarr
end

function CConfigs::GetDirArr
return, self.dir_arr
end

pro CConfigs::SetTransition, transition
self.transition=transition
end

function CConfigs::GetTransition
return, self.transition
end

pro CConfigs::SetDirPollingOn, dir_polling_on
self.dir_polling_on=dir_polling_on
end

function CConfigs::GetDirPollingOn
return, self.dir_polling_on
end

pro CConfigs::SetPollDir, poll_dir
self.poll_dir=poll_dir
end

function CConfigs::GetPollDir
return, self.poll_dir
end

pro CConfigs::SetServerPollingOn, server_polling_on
self.server_polling_on=server_polling_on
end

function CConfigs::GetServerPollingOn
return, self.server_polling_on
end

pro CConfigs::SetPollServer, poll_server
self.poll_server=poll_server
end

function CConfigs::GetPollServer
return, self.poll_server
end

pro CConfigs::SetDrawXs, draw_xs
self.draw_xs=draw_xs
end

function CConfigs::GetDrawXs
return, self.draw_xs
end

pro CConfigs::SetDrawYs, draw_ys
self.draw_ys=draw_ys
end

function CConfigs::GetDrawYs
return, self.draw_ys
end

pro CConfigs::SetDiagonal, diagonal
self.diagonal=diagonal
end

function CConfigs::GetDiagonal
return, self.diagonal
end

pro CConfigs::SetNewFiles, new_files_ptr
self.new_files=new_files_ptr
end

function CConfigs::GetNewFiles
return, self.new_files
end

pro CConfigs::SetConbaseDirectory, conbase_dir
self.conbase_dir=conbase_dir
end

function CConfigs::GetConbaseDirectory
return, self.conbase_dir
end

pro CConfigs::SetAxesLabels2d, axes_labels2d
self.axes_labels2d=axes_labels2d
end

function CConfigs::GetAxesLabels2d
return, self.axes_labels2d
end

pro CConfigs::SetAxesLabels3d, axes_labels3d
self.axes_labels3d=axes_labels3d
end

function CConfigs::GetAxesLabels3d
return, self.axes_labels3d
end

pro CConfigs::SetImScaleMaxCon, imscalemaxcon
self.imscalemaxcon=imscalemaxcon
end

function CConfigs::GetImScaleMaxCon
return, self.imscalemaxcon
end

pro CConfigs::SetImScaleMinCon, imscalemincon
self.imscalemincon=imscalemincon
end

function CConfigs::GetImScaleMinCon
return, self.imscalemincon
end

pro CConfigs::SetDisplayAsDN, displayasdn
self.displayasdn=displayasdn
end

function CConfigs::GetDisplayAsDN
return, self.displayasdn
end

pro CConfigs::SetCollapse, collapse
self.collapse=collapse
end

function CConfigs::GetCollapse
return, self.collapse
end

pro CConfigs::SetCalcPA, pa_function
self.pa_function=pa_function
end

function CConfigs::GetCalcPA
return, self.pa_function
end

pro CConfigs::SetExitQuestion, exit_question
self.exit_question=exit_question
end

function CConfigs::GetExitQuestion
return, self.exit_question
end


pro cconfigs__define

; create a structure that holds an instance's information 
struct={ cconfigs, $
         cfg_name:'', $         ; instrument configuration
         inst_fitskw:'', $      ; instrument fits keyword
         itime_fitskw:'', $     ; integration time
         coadds_fitskw:'', $    ; # of coadds
         pa_fitskw:'', $        ; sky pa
         object_fitskw:'', $    ; object kw
         sampmode_fitskw:'', $      
         numreads_fitskw:'', $  ; number of reads
         platescale_fitskw:'', $ ; platescale            
         array_index_fitskw:'', $ ; starting wavelength in dispersion
         lin_disp_fitskw:'', $  ; linear dispersion in z axis
         reference_fitskw:'', $ ; reference pixel
         unit_fitskw:'', $      ; units that accompany the starting wavelength
         polling_rate:0.0, $         
         testserver:'', $        ; function checks to see if the server is up
         isframeready:'', $            ; function checks for frame
         getfilename:'', $             ; function gets the filename
         openfiles:'', $               ; function opens new files
         transition:0.0, $ ; get filename when transition changes from 0 -> 1
         dir_polling_on:0., $ ; determines whether or not to turn on directory polling
         poll_dir:'', $    ; sets the initial polling directory
         server_polling_on:0., $ ; determines whether or not to turn on server polling
         poll_server:'', $ ; sets the polling server name 
         dir_arr:ptr_new(), $ ; keeps a ptr to an array containing directory listings
         new_files:ptr_new(), $  ; keeps a ptr to an array containing files to be opened
         conbase_dir:'', $ ; sets the initial conbase directory
         draw_xs:0.0, $
         draw_ys:0.0, $
         diagonal:0.0, $
         color_table:0.0, $
         pointer_type:0.0, $   ; 40, 24, 54
         axes_labels2d:ptr_new(), $ ; labels for the cimwin axes
         axes_labels3d:ptr_new(), $ ; labels for the cimwin axes
         imscalemaxcon:0.0, $ ; constant to multiply by im stddev to get the scale max
         imscalemincon:0.0, $ ; constant to multiply by im stddev to get the scale min
         displayasdn:'', $    ; sets member variable as "As DN/s" or "As Total DN", how the image is displayed
         collapse:0.0, $    ; sets collapse member var to "Median" (0) or "Average" (1)
         pa_function:'', $    ; function that calculates the position angle
         exit_question:0.0, $  ; 1 if you want QL2 to ask about keeping IDL running when exiting
         ParentBaseId:0L $
  }

end

