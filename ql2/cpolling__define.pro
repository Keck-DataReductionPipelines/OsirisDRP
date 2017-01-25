; +
; NAME: cpolling__define 
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
; REVISION HISTORY: 30APR2004 - MWM: wrote class
; - 

function CPolling::Init, wid_leader=conbase_id

print, 'initializing polling object'

; set values of members of object
self.polling_status=0.
self.kill_ql=0.
self.polling_rate=1.
self.directory_polling_rate=1.
self.conbase_id=conbase_id
self.server_name='osiris'
self.directory_name='/home/osrsdev/kroot/kss/qlook2'

return, 1

end

pro CPolling::StartTimer, conbase_id

widget_control, conbase_id, get_uval=conbase_uval

;this tells xmanager to register the frame_ready_widget 
xmanager, 'ql_conbase_cpoll_timer', conbase_uval.wids.base, /just_reg, /no_block
widget_control, conbase_uval.wids.base, timer=self.polling_rate

end

pro CPolling::PollLoop

; the IsFrameReady function will return 1 if the frame is ready
; and 0 if the frame is not ready
if (self->IsFrameReady() eq 1) then begin
    filenames=self->GetFilenames()
    self->OpenNewFiles, filenames
endif

end

function CPolling::TestServer
widget_control, self.conbase_id, get_uval=conbase_uval
cconfigs_obj=*(conbase_uval.cconfigs_ptr)

testserver=call_function(cconfigs_obj->GetTestServer(), self.conbase_id)
return, testserver

end

function CPolling::IsFrameReady

widget_control, self.conbase_id, get_uval=conbase_uval
cconfigs_obj=*(conbase_uval.cconfigs_ptr)

frameready=call_function(cconfigs_obj->GetIsFrameReady(), self.conbase_id)

if (frameready eq -1) then begin
    self->ReportError, 'frameready'
    return, 0
endif else begin
    return, frameready
end

end

function CPolling::GetFilenames

widget_control, self.conbase_id, get_uval=conbase_uval
cconfigs_obj=*(conbase_uval.cconfigs_ptr)

filenames=call_function(cconfigs_obj->GetFilename(), self.conbase_id)

if (filenames[0] eq 'error') then begin
    self->ReportError, 'getfilename'
endif else begin
    return, filenames
endelse

end

pro CPolling::OpenNewFiles, filenames

widget_control, self.conbase_id, get_uval=conbase_uval
cconfigs_obj=*(conbase_uval.cconfigs_ptr)

call_procedure, cconfigs_obj->GetOpenFiles(), filenames, self.conbase_id

end

pro CPolling::ReportError, error

; set the polling toggle to off
widget_control, self.conbase_id, get_uval=conbase_uval

; report the error
case error of
    'server': begin
        message=['Polling terminated:', $
                 'Check server name.', $
                 'You must restart server polling manually.']
        if (conbase_uval.exist.polling ne 0L) then begin
            widget_control, conbase_uval.exist.polling, get_uval=polling_uval
            widget_control, polling_uval.wids.polling_on, set_value=0
        endif
        self.polling_status=0.
    end
    'frameready': begin
        message=['Polling terminated:', $
                 'Error determining frame ready.', $
                 'You must restart polling manually.'] 
        if (conbase_uval.exist.polling ne 0L) then begin
            widget_control, conbase_uval.exist.polling, get_uval=polling_uval
            widget_control, polling_uval.wids.polling_on, set_value=0
            widget_control, polling_uval.wids.polling_directory_on, set_value=0
        endif
        self.polling_status=0.
        self.directory_polling_status=0.
    end
    'getfilename': begin
        message=['Polling terminated:', $
                 'Error determining filename.', $
                 'You must restart polling manually.'] 
        if (conbase_uval.exist.polling ne 0L) then begin
            widget_control, conbase_uval.exist.polling, get_uval=polling_uval
            widget_control, polling_uval.wids.polling_on, set_value=0
            widget_control, polling_uval.wids.polling_directory_on, set_value=0
        endif
        self.polling_status=0.
        self.directory_polling_status=0.
    end
    'directory': begin 
        message=['Polling terminated:', $
                 'Error accessing directory.', $
                 'You must restart directory polling manually.'] 
        if (conbase_uval.exist.polling ne 0L) then begin
            widget_control, conbase_uval.exist.polling, get_uval=polling_uval
            widget_control, polling_uval.wids.polling_directory_on, set_value=0
        endif
        self.directory_polling_status=0.
        end
endcase

; display the error message
answer=dialog_message(message, dialog_parent=self.conbase_id) 

end

pro CPolling::KillQL2

ql_conquit, self.conbase_id

end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  BEGIN CPRINT ACCESSOR/MUTATOR FUNCTIONS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pro CPolling::SetServerName, server_name

self.server_name=server_name

end

function CPolling::GetServerName

return, self.server_name

end

pro CPolling::SetDirectoryName, directory_name

self.directory_name=directory_name

end

function CPolling::GetDirectoryName

return, self.directory_name

end

pro CPolling::SetPollingRate, polling_rate

self.polling_rate=polling_rate

end

function CPolling::GetPollingRate

return, self.polling_rate

end

pro CPolling::SetDirectoryPollingRate, directory_polling_rate

self.directory_polling_rate=directory_polling_rate

end

function CPolling::GetDirectoryPollingRate

return, self.directory_polling_rate

end

pro CPolling::SetPollingStatus, polling_status

self.polling_status=polling_status

end

function CPolling::GetPollingStatus

return, self.polling_status

end

pro CPolling::SetDirectoryPollingStatus, directory_polling_status

self.directory_polling_status=directory_polling_status

end

function CPolling::GetDirectoryPollingStatus

return, self.directory_polling_status

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  END CPRINT ACCESSOR/MUTATOR FUNCTIONS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pro cpolling__define

; create a structure that holds an instance's information 
struct={cpolling, $
        polling_status:0.0, $
        directory_polling_status:0.0, $
        conbase_id:0L, $
        kill_ql:0.0, $
        polling_rate:0.0, $
        directory_polling_rate:0.0, $
        server_name:'', $
        directory_name:'' $
       }

end
