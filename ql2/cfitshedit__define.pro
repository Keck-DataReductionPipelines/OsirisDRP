;+
; NAME: cfitshedit__define 
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
; 	2007-07-03	MDP: Fix multiple pointer leaks.
;- 

function CFitsHedit::Init, winbase_id=cimwin_id, conbase_id=conbase_id

print, 'initializing fits header editor object'

; set values of members of object
self.cimwin_id=cimwin_id
self.conbase_id=conbase_id

return, 1

end

pro CFitsHedit::Cleanup
; MWM : Fixed to make sure the ID is valid
if widget_info(self.cfitshedit_id, /valid_id) then begin
    widget_control, self.cfitshedit_id, get_uval=uval
    ptr_free,uval.reserved_ptr,uval.hd_ptr, uval.im_ptr
endif
end

pro CFitsHedit::EditHeader, base_id

  widget_control, base_id, get_uval=cimwin_uval

  ; create new pointer to image
  im_ptr=ptr_new()
  ; create new pointer to header
  hd_ptr=ptr_new()

  ; create array for possible datatypes (for droplist)
  datatypes=["Boolean", "Integer", "Long", "Float", "Double", "String"]

  ; create widgets
  ; main base widget
  base=widget_base(title="FITS Header Editor", /col, xs=650, $
                   /tlb_size_events, group_leader=base_id, $
                   /tlb_kill_request_events)

  ; button base for file control
  file_base=widget_base(base, /row)
  save_button=widget_button(file_base, value="Save")
  saveas_button=widget_button(file_base, value="Save As")
  ; print_button=widget_button(file_base, value="Print")
  quit_button=widget_button(file_base, value="Quit")

  ; field to display filename
  filename_field=widget_text(base)

  ; list of keywords
  header_list=widget_list(base, ys=20)

  ; base for line editing controls
  line_edit_base=widget_base(base, /col, frame=2)
  line_edit_top_base=widget_base(line_edit_base, /row)
  line_edit_bottom_base=widget_base(line_edit_base, /row)
  ; fields for editing line
  line_name_field=cw_field(line_edit_top_base, title="NAME:", value="", xs=8)
  line_value_field=cw_field(line_edit_top_base, title="VALUE:", value="")
  line_datatype_menu=widget_droplist(line_edit_top_base, title="DATATYPE:", value=datatypes)
  line_comment_field=cw_field(line_edit_bottom_base, title="COMMENT:", value="", xs=30)
  ; set button to update line in list
  line_set_button=widget_button(line_edit_bottom_base, value="SET")
  find_keyword_field=cw_field(line_edit_bottom_base, title="FIND KEYWORD:", value="", xs=8)
  find_button=widget_button(line_edit_bottom_base, value="FIND")

  ; button base for moving, adding, removing lines
  button_base=widget_base(base, /row, frame=2)
  movetotop_button=widget_button(button_base, value="Move to top")
  moveup_button=widget_button(button_base, value="Move up")
  movedown_button=widget_button(button_base, value="Move down")
  movetobottom_button=widget_button(button_base, value="Move to bottom")
  insert_button=widget_button(button_base, value="Insert New")
  remove_button=widget_button(button_base, value="Remove")
  
  ; store widget id's in a structure
  wids={name:line_name_field, $
        value:line_value_field, $
        comment:line_comment_field, $
        datatype:line_datatype_menu, $
        set:line_set_button, $
        find_field:find_keyword_field, $
        find:find_button, $
        insert:insert_button, $
        remove:remove_button, $
        movetotop:movetotop_button, $
        movetobottom:movetobottom_button, $
        moveup:moveup_button, $
        movedown:movedown_button, $
        save:save_button, $
        saveas:saveas_button, $
        quit:quit_button, $
        filename:filename_field, $
        list:header_list}
   
  
  ; put all accessible info in uval
  uval={base_id:base_id, $
        im_ptr:im_ptr, $
        hd_ptr:hd_ptr, $
        reserved_ptr:ptr_new(), $
        newpath:'', $
        filename:'', $
        savefilename:'', $
        modified:0, $
        fileopen:0, $
        wids:wids, $
        num_reserved:1, $
        bscale:0, $
        bzero:0, $
        selected:0, $
        keyword_exist_index:0, $
        curname:'', $
        curvalue:'', $
        curcomment:'', $
        curdatatype:0}
  
  ; realize gui and set uval
  widget_control, base, /realize, set_uval=uval

  ; register events with xmanager
  xmanager, 'cfitshedit_base', base, /no_block, /just_reg
  xmanager, 'cfitshedit_header_list', header_list, /no_block, /just_reg
  xmanager, 'cfitshedit_line_set_button', line_set_button, /no_block, /just_reg
  xmanager, 'cfitshedit_find_button', find_button, /no_block, /just_reg
  xmanager, 'cfitshedit_insert_button', insert_button, /no_block, /just_reg
  xmanager, 'cfitshedit_remove_button', remove_button, /no_block, /just_reg
  xmanager, 'cfitshedit_movetotop_button', movetotop_button, /no_block, /just_reg
  xmanager, 'cfitshedit_movetobottom_button', movetobottom_button, /no_block, /just_reg
  xmanager, 'cfitshedit_moveup_button', moveup_button, /no_block, /just_reg
  xmanager, 'cfitshedit_movedown_button', movedown_button, /no_block, /just_reg
  xmanager, 'cfitshedit_save_button', save_button, /no_bloc, /just_reg
  xmanager, 'cfitshedit_saveas_button', saveas_button, /no_bloc, /just_reg
  xmanager, 'cfitshedit_quit_button', quit_button, /no_bloc, /just_reg

  ; set that the fitshedit widget has been created
  cimwin_uval.exist.fitshedit=base
  self.cfitshedit_id=base
  ; open the header to the image file displayed in the cimwin
  self->OpenFile
  ; set the base uval
  widget_control, base_id, set_uval=cimwin_uval

end

pro CFitsHedit::OpenFile
; open a file, make sure it's valid, and update list

  ; get uval struct
  widget_control, self.cfitshedit_id, get_uval=uval
  widget_control, uval.base_id, get_uval=cimwin_uval

  CImWin_Obj=*(cimwin_uval.self_ptr)

  ; get image object
  ImObj_ptr=CImWin_Obj->GetImObj()
  ImObj=*ImObj_ptr

  ; get the image header
  uval.filename=ImObj->GetPathFilename()
  hd=*(ImObj->GetHeader())

  ; get number of keywords in header
  num_keywords=n_elements(hd)
  ; initialize number of reserved keywords.  variable 
      ; because of NAXIS1, NAXIS2, ..., NAXISN, 
      ; where N is number of image axis (value of NAXIS keyword)
  num_reserved=4    ; SIMPLE, BITPIX, BSCALE, BZERO... NAXIS to follow
  num_reserved=num_reserved+sxpar(hd, "NAXIS")

  ; determine where the reserved keywords exist
  reserved_elements=-1

  for i=0,num_keywords-1 do begin
      ; extract the keyword from the header
      keyword=strmid(hd[i],0,8)
      case keyword of
          'SIMPLE  ': begin
              if (reserved_elements[0] eq -1) then begin
                  reserved_elements[0]=i
              endif else begin
                  reserved_elements=[[reserved_elements], [i]]
              endelse
          end
          'XTENSION': begin
              if (reserved_elements[0] eq -1) then begin
                  reserved_elements[0]=i
              endif else begin
                  reserved_elements=[[reserved_elements], [i]]
              endelse
          end
          'BITPIX  ': begin
              if (reserved_elements[0] eq -1) then begin
                  reserved_elements[0]=i
              endif else begin
                  reserved_elements=[[reserved_elements], [i]]
              endelse
          end
          'NAXIS   ': begin
              num_axes=sxpar(hd, "NAXIS")
              if (reserved_elements[0] eq -1) then begin
                  reserved_elements[0]=i
                  for j=0,num_axes-1 do begin
                  reserved_elements=[[reserved_elements], [i+j+1]]  
                  endfor
              endif else begin
                  reserved_elements=[[reserved_elements], [i]]
                  for j=0,num_axes-1 do begin
                  reserved_elements=[[reserved_elements], [i+j+1]]  
                  endfor
              endelse
          end
          'BSCALE  ': begin
              uval.bscale=i
              if (reserved_elements[0] eq -1) then begin
                  reserved_elements[0]=i
              endif else begin
                  reserved_elements=[[reserved_elements], [i]]
              endelse
          end
          'BZERO   ': begin
              uval.bzero=i
              if (reserved_elements[0] eq -1) then begin
                  reserved_elements[0]=i
              endif else begin
                  reserved_elements=[[reserved_elements], [i]]
              endelse
          end
          else:
      endcase
  endfor

  ; set these values in uval
  ptr_free, uval.hd_ptr, uval.im_ptr, uval.reserved_ptr
  uval.hd_ptr=ptr_new(hd)
  uval.im_ptr=ptr_new(im)
  uval.reserved_ptr=ptr_new(reserved_elements)
  uval.num_reserved=n_elements(reserved_elements)
  uval.selected=0
  uval.fileopen=1
  uval.modified=0
  
  widget_control, uval.wids.filename, set_value=uval.filename

  ; set uval
  widget_control, self.cfitshedit_id, set_uval=uval

  ; set selected item in uval
  self->SetSelected, self.cfitshedit_id, uval.selected

  ; update list
  self->UpdateList, self.cfitshedit_id

end

pro CFitsHedit::SetSelected, base_id, index
; set new selected index in uval, and update accessibility on buttons
; accordingly.  
; rules imposed:
;   - Reserved keywords cannot be moved
;   - Reserved keywords are not modifyable, except for the value
;       only for BSCALE and BZERO
;   - END keyword cannot be moved (must always be last)
;   - END keyword cannot be modified
;   - Keywords cannot be moved into reserved space
;   - Keywords cannot be moved below END

  ; get uval
  widget_control, base_id, get_uval=uval
  ; get header
  hd=*(uval.hd_ptr)
  ; set index of selected row in uval
  uval.selected=index
  ; set uval
  widget_control, base_id, set_uval=uval

  ; check to see what was selected, and enforce appropiate 
  ; control accessibility
  
  match=where(*(uval.reserved_ptr) eq uval.selected)

  if (match[0] ne -1) then begin
      ; if selected item is one of reserved keywords, disallow all options
      widget_control, uval.wids.insert, sensitive=0
      widget_control, uval.wids.remove, sensitive=0
      widget_control, uval.wids.movetotop, sensitive=0
      widget_control, uval.wids.movetobottom, sensitive=0
      widget_control, uval.wids.moveup, sensitive=0
      widget_control, uval.wids.movedown, sensitive=0
      widget_control, uval.wids.name, sensitive=0
      widget_control, uval.wids.comment, sensitive=0
      widget_control, uval.wids.value, sensitive=0
      widget_control, uval.wids.datatype, sensitive=0
      widget_control, uval.wids.set, sensitive=0
  endif else if (uval.selected eq n_elements(hd)-1) then begin
      ; if selected item is END, disallow all but insert
      widget_control, uval.wids.insert, sensitive=1
      widget_control, uval.wids.remove, sensitive=0
      widget_control, uval.wids.movetotop, sensitive=0
      widget_control, uval.wids.movetobottom, sensitive=0
      widget_control, uval.wids.moveup, sensitive=0
      widget_control, uval.wids.movedown, sensitive=0
      widget_control, uval.wids.name, sensitive=0
      widget_control, uval.wids.value, sensitive=0
      widget_control, uval.wids.comment, sensitive=0
      widget_control, uval.wids.datatype, sensitive=0
      widget_control, uval.wids.set, sensitive=0
  endif else begin
      ; for all others, allow everything else, with some more
      ; restrictions below
      widget_control, uval.wids.insert, sensitive=1
      widget_control, uval.wids.remove, sensitive=1
      widget_control, uval.wids.movetotop, sensitive=1
      widget_control, uval.wids.movetobottom, sensitive=1
      widget_control, uval.wids.moveup, sensitive=1
      widget_control, uval.wids.movedown, sensitive=1
      widget_control, uval.wids.name, sensitive=1
      widget_control, uval.wids.value, sensitive=1
      widget_control, uval.wids.comment, sensitive=1
      widget_control, uval.wids.datatype, sensitive=1
      widget_control, uval.wids.set, sensitive=1
  endelse

  ; enable value editing for bscale and bzero
  if ((uval.selected eq uval.bscale) or $ 
      (uval.selected eq uval.bzero)) then begin
      widget_control, uval.wids.value, sensitive=1
      widget_control, uval.wids.set, sensitive=1
  endif

  ; don't allow keywords to be moved into reserved space
  if (uval.selected eq uval.num_reserved) then begin
      widget_control, uval.wids.moveup, sensitive=0
      widget_control, uval.wids.movetotop, sensitive=0
  endif
  
  ; don't allow keywords to be moved below END keyword
  if (uval.selected eq n_elements(hd)-2) then begin
      widget_control, uval.wids.movedown, sensitive=0
      widget_control, uval.wids.movetobottom, sensitive=0
  endif

end

pro CFitsHedit::UpdateFields, base_id

; updates the line fields (Name, value, comment, datatype) for the
; selected line

; get uval struct
widget_control, base_id, get_uval=uval
; get header
hd=*(uval.hd_ptr)

; initialize comments.  though not supported in this program, 
; comments may be an array, so make this one
comments=strarr(1)

;   - COMMENT AND HISTORY keywords are read in without values

; get current name (always first 8 chars of line)
uval.curname=strmid(hd[uval.selected], 0, 8)
; get value using FITS I/O (astron library)
case strtrim(uval.curname,2) of
    'HISTORY': begin
        value='UNDEFINED'
        comments=sxpar(hd,'HISTORY')
        ; find out which history this is
        history_indicies=where(strtrim(strmid(hd[*],0,8),2) eq 'HISTORY')
        index=where(uval.selected eq history_indicies[*])        
        comment=comments[index]

    end
    'COMMENT': begin
        value='UNDEFINED'
        comments=sxpar(hd,'COMMENT')
        ; find out which comment this is
        comment_indicies=where(strtrim(strmid(hd[*],0,8),2) eq 'COMMENT')
        index=where(uval.selected eq comment_indicies[*])        
        comment=comments[index]
    end
    else: begin
        value=sxpar(hd, uval.curname, comment=comments)
        comment=comments[0]
    end
endcase

; value is of datatype determined by sxpar. we need to find
; out what it is.  use idl size() function to do this.
; the datatype is the second to last item returned from size. 
size_value=size(value)
datatype=size_value[n_elements(size_value)-2]

; set the datatype in the uval corresponding to our
; own mapping of integers to datatypes
case datatype of
    1: begin                    ; byte / boolean
        uval.curdatatype=0
    end
    2: begin                    ; integer
        uval.curdatatype=1
    end
    3: begin                    ; long
        uval.curdatatype=2
    end
    4: begin                    ; float
        uval.curdatatype=3
    end
    5: begin                    ; double
        uval.curdatatype=4
    end
    else: begin                 ; string
        uval.curdatatype=5
    end
endcase

; set new value in uval
uval.curvalue=string(value)
; set new comments in uval
uval.curcomment=comment

; update values in fields
widget_control, uval.wids.name, set_value=uval.curname
widget_control, uval.wids.value, set_value=uval.curvalue
widget_control, uval.wids.comment, set_value=uval.curcomment
; set datatype droplist
widget_control, uval.wids.datatype, set_droplist_select=uval.curdatatype

; set uval
widget_control, base_id, set_uval=uval

end

pro CFitsHedit::UpdateLine, base_id, keyword_exist=keyword_exist
; update an entire line in the list

  ; get uval struct
  widget_control, base_id, get_uval=uval
  ; get header
  hd=*(uval.hd_ptr)

  ; make a line template
  newline="        ='                  ' /                               "
  ; put name in line
  strput, newline, uval.curname, 0
  ; put comment in line
  strput, newline, uval.curcomment, 33

  answer='Yes'

  new_keyword=0

  if keyword_set(keyword_exist) then begin
      ; if the keyword is the same as the line that you're on, then
      ; don't remove that keyword
      new_keyword=(uval.selected ne uval.keyword_exist_index)
  endif

  if (new_keyword) then begin

      ; remove the new line that was added to the header
      new_hd=[hd[0:uval.selected-1], hd[uval.selected+1:*]]  
      ; update header in uval
	  ptr_free, uval.hd_ptr
      uval.hd_ptr=ptr_new(new_hd)
      widget_control, base_id, set_uval=uval
      ; re-get header
      hd=*(uval.hd_ptr)

      ; find out where the new keyword exist index is
      if (uval.selected lt uval.keyword_exist_index) then begin
          uval.keyword_exist_index=uval.keyword_exist_index-1
      endif

      ; go to the line where this keyword exists
      self->SetSelected, base_id, uval.keyword_exist_index 
      self->UpdateList, self.cfitshedit_id
      uval.selected=uval.keyword_exist_index 

      ; see if the user intentionally tried to change this value
      message=['This keyword already exists.', $
               'Do you want to update the fields in that record?']
      answer=dialog_message(message, dialog_parent=base_id, /question)
  endif else begin
      ; update selected line in header with new line
      hd[uval.selected]=newline
  endelse

  ; cast new value to appropiate datatype
  case uval.curdatatype of
      0: begin  ; byte / boolean
          value=(byte(uval.curvalue))[0]
      end
      1: begin  ; integer
          value=fix(uval.curvalue)
      end
      2: begin  ; long
          value=long(fix(uval.curvalue))
      end
      3: begin  ; float
          value=float(uval.curvalue)
      end
      4: begin  ; double
          value=double(uval.curvalue)
      end
      else: begin ; string
          value=uval.curvalue
      end
  endcase

  if (answer eq 'Yes') then begin
  ; update line using FITS I/O tools (astron library)
  ; this makes sure the value is properly formatted
      sxaddpar, hd, uval.curname, value, uval.curcomment
  endif

  ; set header in uval
  *(uval.hd_ptr)=hd

  ; set that header has been modified
  uval.modified=1

  ; set uval
  widget_control, base_id, set_uval=uval

  ; update list in view
  self->UpdateList, base_id

end


pro CFitsHedit::UpdateCommentLine, base_id, value
; update a comment line in the list

  ; get uval struct
widget_control, base_id, get_uval=uval
  ; get header
hd=*(uval.hd_ptr)

case strtrim(value,2) of
    'HISTORY': begin
        ; add the history line to the header
        ; make a line template
        newline="                                                              "
        ; put name in line
        strput, newline, uval.curname, 0
        ; put comment in line
        strput, newline, uval.curcomment, 9
        ; update selected line in header with new line
        hd[uval.selected]=newline
    end
    'COMMENT': begin
        ; add the comment line to the header
        ; make a line template
        newline="                                                              "
        ; put name in line
        strput, newline, uval.curname, 0
        ; put comment in line
        strput, newline, uval.curcomment, 9
        ; update selected line in header with new line
        hd[uval.selected]=newline
    end
    else: begin
    end
endcase

; set header in uval
*(uval.hd_ptr)=hd

; set that header has been modified
uval.modified=1

; set uval
widget_control, base_id, set_uval=uval

; update list in view
self->UpdateList, base_id

end


pro CFitsHedit::UpdateList, base_id
; updates the list in the widget_list

  ; get uval struct
  widget_control, base_id, get_uval=uval
  ; get header
  hd=*(uval.hd_ptr)
  
  ; save the current top of the list in view
  list_top=widget_info(uval.wids.list, /list_top)

  ; set list in view
  widget_control, uval.wids.list, set_value=hd
  ; reset the top of the list
  widget_control, uval.wids.list, set_list_top=list_top
  ; reset the selected item
  widget_control, uval.wids.list, set_list_select=uval.selected

  ; update the line fields, since selected may have changed
  self->UpdateFields, base_id

end

function CFitsHedit::CheckKeyword, base_id, up_newname
; updates the list in the widget_list
  ; get uval struct
  widget_control, base_id, get_uval=uval
  ; get header
  hd=*(uval.hd_ptr)

  case (up_newname[0]) of
      'HISTORY': begin
          ; check the fits header to see if this keyword already exists, and
          ; start at the current header line
          nheader=n_elements(hd)
          if (uval.keyword_exist_index+1 le nheader-1) then start=uval.keyword_exist_index+1
          for i=start,nheader-1 do begin
              keyword=strtrim(strmid(hd[i],0,8),2)
              if (keyword eq up_newname[0]) then begin
                  uval.keyword_exist_index=i
                  widget_control, base_id, set_uval=uval
                  return, 1
              endif
          endfor
          for i=0,uval.keyword_exist_index do begin
              keyword=strtrim(strmid(hd[i],0,8),2)
              if (keyword eq up_newname[0]) then begin
                  uval.keyword_exist_index=i
                  widget_control, base_id, set_uval=uval
                  return, 1
              endif
          endfor
      end
      'COMMENT': begin
          ; check the fits header to see if this keyword already exists, and
          ; start at the current header line
          nheader=n_elements(hd)
          if (uval.keyword_exist_index+1 le nheader-1) then start=uval.keyword_exist_index+1
          for i=start,nheader-1 do begin
              keyword=strtrim(strmid(hd[i],0,8),2)
              if (keyword eq up_newname[0]) then begin
                  uval.keyword_exist_index=i
                  widget_control, base_id, set_uval=uval
                  return, 2
              endif
          endfor
          for i=0,uval.keyword_exist_index do begin
              keyword=strtrim(strmid(hd[i],0,8),2)
              if (keyword eq up_newname[0]) then begin
                  uval.keyword_exist_index=i
                  widget_control, base_id, set_uval=uval
                  return, 2
              endif
          endfor
      end
      else: begin
          ; check the fits header to see if this keyword already exists
          nheader=n_elements(hd)
          for i=0,nheader-1 do begin
              keyword=strtrim(strmid(hd[i],0,8),2)
              if (keyword eq up_newname[0]) then begin
                  uval.keyword_exist_index=i
                  widget_control, base_id, set_uval=uval
                  return, 3
              endif
          endfor
      endelse
  endcase

  return, 0

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  BEGIN CIMAGE WINDOW ACCESSOR/MUTATOR FUNCTIONS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

function CImWin::GetFitsHeditId
return, self.cfitshedit_id
end

pro CImWin::SetFitsHeditId, newFitsHeditId
self.cfitshedit_id=newFitsHeditId
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  END CIMAGE WINDOW ACCESSOR/MUTATOR FUNCTIONS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pro CFitsHedit__define

; create a structure that holds an instance's information 
struct={cfitshedit, $        
        cimwin_id:0L, $
        conbase_id:0L, $
        cfitshedit_id:0L $
       }

end
