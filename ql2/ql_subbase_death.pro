; +
; NAME: ql_subbase_death
;
; PURPOSE:  This routine handles the death of all sub bases.
; It is used so the children base are not recreated when called again.
; when a child base is created, a structure called exist in the 
; parent uval keeps track of the base widget ID.  when the child base
; if destroyed, the value that holds the base id is reset to 0. 
; when the command to create the base is called again, if the value in the 
; exist structure is not zero, that value is the id of the base that
; already exists, so it is brought to the front using widget_control, /show
; instead of being recreated.
;
; CALLING SEQUENCE: ql_subbase_death, id
;
; INPUTS: id, pass in the ID of the base that is dying
;
; OPTIONAL INPUTS: 
;                  
;
; OPTIONAL KEYWORD INPUTS: 
;
; EXAMPLE:
;
; NOTES:  
;   base_id must be a member of the dying base's uval representing the base id
;   of the parent base
;
;   ex. widget_control, child_base, set_uval={base_id:parent_base_id}
;
; parent must have a member of its uval called exist which is a structure
;   containing the children's base widget ID's
;
;   ex. widget_control, parent_base, $
;		set_uval={exist:{child_base_name:child_base_id}}
;
; child must make this routine the cleanup routine when the child dies
;
;   ex. xmanager, 'child_base', child_base, /just_reg, /no_block, $
;		cleanup='ql_subbase_death'
;
;   this command requires an event handler for child_base events, but
;   the event handler may be empty
;
;   ex. pro child_base_event, event
;	end
; 
; PROCEDURES USED:
;
; REVISION HISTORY: 24FEB2003 - MWM: added comments.
; - 

pro ql_subbase_death, id

; get uval of dying base
widget_control, id, get_uval=sub_uval

; if parent no longer exists, just exit
if widget_info(sub_uval.base_id, /valid_id) eq 0 then return

; get uval of parent base for access to exist struct
widget_control, sub_uval.base_id, get_uval=uval

; create an array to hold wids
temp_arr=lonarr(n_tags(uval.exist))

; copy wids from exist struct into array
for i=0, n_tags(uval.exist)-1 do temp_arr[i]=uval.exist.(i)

; find dying widget id in arrary
loc=where(temp_arr eq id)

; if wid is found, reset that value to 0 in the exist struct
if loc[0] ne -1 then $
        uval.exist.(loc[0])=0L

; reset parent base uval with updated exist struct
widget_control, sub_uval.base_id, set_uval=uval

end

