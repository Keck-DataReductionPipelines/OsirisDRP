pro ql_conmath_calculate_event, event

widget_control, event.top, get_uval=uval
widget_control, uval.wids.base_id, get_uval=conbase_uval

case uval.left_toggle of
    0: begin
        invalid_path=0
        widget_control, uval.wids.file1_box, get_value=filename1
        if (filename1[0] ne '') then begin 
            ; make sure the user specified a file
            filename=ql_getfilename(filename1[0])            
            if ((filename ne '') and ((ql_file_search(filename1[0]))[0]) ne '') then begin
                filename=(ql_file_search(filename1[0]))[0]
                im1=readfits(filename, hd1) 
                f_filename1=ql_getfilename(filename)
            endif else invalid_path=1
        endif else invalid_path=1

        if (invalid_path) then begin
                message='Could not find file1: '+filename1[0]
                answer=dialog_message(message, dialog_parent=event.id, /error)
                return
        endif
    end
    1: begin
        widget_control, uval.wids.num1_box, get_value=num1
        if num1[0] ne '' then begin
            im1=float(num1[0]) 
            f_filename1=strtrim(string(num1[0]),2)
            endif else begin
            message=['You must enter a number for operand 1', $
                     'if you are not using an image.']
            answer=dialog_message(message, dialog_parent=event.id, /error)
            return
        endelse
    end
    2: begin
        invalid_ptr=0
        ; get the active window image and filename
        if ptr_valid(conbase_uval.p_curwin) then begin
        ; checks to see if the object is valid, and makes sure that object
        ; is of the class 'CImWin'
            if obj_valid(*(conbase_uval.p_curwin)) then begin
                if obj_isa(*(conbase_uval.p_curwin), 'CImWin') then begin
                    actwin_obj=*(conbase_uval.p_curwin)
                    actim_obj=*(actwin_obj->GetImObj())
                    im_ptr=actim_obj->GetData()
                    hd1=*(actim_obj->GetHeader())
                    im1=*im_ptr
                    filename1=actim_obj->GetFilename()
                    f_filename1=ql_getfilename(filename1)
                endif else invalid_ptr=1
            endif else invalid_ptr=1
        endif else invalid_ptr=1
 
        if (invalid_ptr) then begin
            message=['QL2 encountered a problem accessing the active image.', $
                     'Please make sure an active window is open.']
            answer=dialog_message(message, dialog_parent=event.id, /error)
            return
        end
    end
end

case uval.right_toggle of
    0: begin
        invalid_path=0
        widget_control, uval.wids.file2_box, get_value=filename2
        if (filename2[0] ne '') then begin 
            ; make sure the user specified a file
            filename=ql_getfilename(filename2[0])            
            if ((filename ne '') and ((ql_file_search(filename2[0]))[0]) ne '') then begin
                filename=(ql_file_search(filename2[0]))[0]
                im2=readfits(filename2[0], hd2) 
                f_filename2=ql_getfilename(filename)
            endif else invalid_path=1
        endif else invalid_path=1
        
        if (invalid_path) then begin
            message='Could not find file2: '+filename2[0]
            answer=dialog_message(message, dialog_parent=event.id, /error)
            return
        endif
    end
    1: begin
        widget_control, uval.wids.num2_box, get_value=num2
        if num2[0] ne '' then begin 
            im2=float(num2[0]) 
            f_filename2=strtrim(string(num2[0]),2)
        endif else begin
            message=['You must enter a number for operand 2', $
                     'if you are not using an image.']
            answer=dialog_message(message, dialog_parent=event.id, /error)
            return
        endelse
    end
    2: begin
        invalid_ptr=0
        ; get the active window image and filename
        if ptr_valid(conbase_uval.p_curwin) then begin
        ; checks to see if the object is valid, and makes sure that object
        ; is of the class 'CImWin'
            if obj_valid(*(conbase_uval.p_curwin)) then begin
                if obj_isa(*(conbase_uval.p_curwin), 'CImWin') then begin
                    actwin_obj=*(conbase_uval.p_curwin)
                    actim_obj=*(actwin_obj->GetImObj())
                    im_ptr=actim_obj->GetData()
                    hd2=*(actim_obj->GetHeader())
                    im2=*im_ptr
                    filename2=actim_obj->GetFilename()
                    f_filename2=ql_getfilename(filename2)
                endif else invalid_ptr=1
            endif else invalid_ptr=1
        endif else invalid_ptr=1

        if (invalid_ptr) then begin
            message=['QL2 encountered a problem accessing the active image.', $
                     'Please make sure an active window is open.']
            answer=dialog_message(message, dialog_parent=event.id, /error)
            return
        endif
    end

end

s1=size(im1)
s2=size(im2)

widget_control, uval.wids.operations, get_value=oper

; checks to see if the datatypes are unsigned ints, and if they are,
; then the data is changed before performing the arithmetic
s1_type=size(im1, /type)
s2_type=size(im2, /type)

if (s1_type eq 12) then begin
    if ((oper eq 2) or (oper eq 3)) then begin
        ; division/multiplication, so cast data type as float
        im1=float(im1)
    endif else begin
        ; cast data type as long
        im1=long(im1)
    endelse
endif

if (s2_type eq 12) then begin
    if ((oper eq 2) or (oper eq 3)) then begin
        ; division/multiplication, so cast data type as float
        im2=float(im2)
    endif else begin
        ; cast data type as long
        im2=long(im2)
    endelse
endif

; make sure same size if both 2-D
if (s1[0] eq 2) and (s2[0] eq 2) and (s1[1] ne s2[1]) then begin
    message=['Images not the same size!  Continue?', $
       '(Result will have the size of the smallest dimensions.)']
    answer=dialog_message(message, dialog_parent=event.id, /cancel)
    if answer eq 'Cancel' then return
endif

case oper of
    0: begin 
        final=im1+im2           ; +
        title='('+f_filename1+' + '+f_filename2+')'
    end
    1: begin 
        final=im1-im2           ; -
        title='('+f_filename1+' - '+f_filename2+')'
    end
    2: begin 
        final=im1*im2           ; *
        title='('+f_filename1+' * '+f_filename2+')'
    end
    3: begin 
        ; make sure you don't divide by zero
        im1_zero=where(im1 eq 0)
        im2_zero=where(im2 eq 0)

;        if ((im1_zero[0] gt -1) or (im2_zero[0] gt -1)) then begin
;            message=['Error in arithmetic:', $
;                     ' Can not perform operation due to division by zero.']
;            answer=dialog_message(message, dialog_parent=$
;                                  event.id)
;            return
;        endif else begin
            final=im1/im2       ; /
            title='('+f_filename1+' / '+f_filename2+')'
;        endif
;        endelse
    end
endcase

; make sure the image gets a header
if (n_elements(hd1) eq 0) then begin
    if (n_elements(hd2) ne 0) then begin
        hd_ptr=ptr_new(hd2, /allocate_heap)
    endif
endif else begin
        hd_ptr=ptr_new(hd1, /allocate_heap)
endelse

imsize=size(final)
data_ptr=ptr_new(final, /allocate_heap)
im=obj_new('CImage', filename='', data=data_ptr, header=hd_ptr, $
    xs=imsize[1], ys=imsize[2])

if obj_isa(im, 'CImage') then begin
    p_ImObj=ptr_new(im, /allocate_heap)
    im=*p_ImObj
    ext=im->GetExt()
    file_var=1
    im->SetFilename, title, file_var
    if conbase_uval.newwin eq 0 then $
          ql_display_new_image, uval.wids.base_id, p_ImObj, $
          p_WinObj=conbase_uval.p_curwin, ext $
        else $
          ql_display_new_image, uval.wids.base_id, p_ImObj, ext
endif else begin
    message=['Error in arithmetic:', $
       ' Error creating CImage object']
    answer=dialog_message(message, dialog_parent=$
       event.id)
endelse
end

pro ql_conmath_left_toggle_event, event

widget_control, event.top, get_uval=uval
uval.left_toggle=event.value

case event.value of
    0: begin
        widget_control, uval.wids.file1_base, sensitive=1-event.value
        widget_control, uval.wids.num1_box, sensitive=event.value
    end
    1: begin
        widget_control, uval.wids.num1_box, sensitive=1
        widget_control, uval.wids.file1_base, sensitive=0
        ; get the right toggle value
        widget_control, uval.wids.right_toggle, get_value=rt_toggle_val
        if (rt_toggle_val eq 1) then begin
            widget_control, uval.wids.right_toggle, set_value=0
            uval.right_toggle=0
            widget_control, uval.wids.file2_base, sensitive=1
            widget_control, uval.wids.num2_box, sensitive=0
        endif
    end
    2: begin
        widget_control, uval.wids.file1_base, sensitive=0
        widget_control, uval.wids.num1_box, sensitive=0     
    end
end

widget_control, event.top, set_uval=uval

end

pro ql_conmath_right_toggle_event, event

widget_control, event.top, get_uval=uval
uval.right_toggle=event.value

case event.value of
    0: begin
        widget_control, uval.wids.file2_base, sensitive=1-event.value
        widget_control, uval.wids.num2_box, sensitive=event.value
    end
    1: begin
        widget_control, uval.wids.num2_box, sensitive=1
        widget_control, uval.wids.file2_base, sensitive=0
        ; get the left toggle value
        widget_control, uval.wids.left_toggle, get_value=left_toggle_val
        if (left_toggle_val eq 1) then begin
            widget_control, uval.wids.left_toggle, set_value=0
            uval.left_toggle=0
            widget_control, uval.wids.file1_base, sensitive=1
            widget_control, uval.wids.num1_box, sensitive=0
        endif
    end
    2: begin
        widget_control, uval.wids.file2_base, sensitive=0
        widget_control, uval.wids.num2_box, sensitive=0     
    end
end

widget_control, event.top, set_uval=uval

end

pro ql_conmath_close_button_event, event

widget_control, event.top, get_uval=uval
widget_control, uval.wids.base_id, get_uval=base_uval
base_uval.exist.arithmetic=0L
widget_control, uval.wids.base_id, set_uval=base_uval
widget_control, event.top, /destroy

end

pro ql_conmath, conbase_id

widget_control, conbase_id, get_uval=base_uval

base=widget_base(title='Image Arithmetic', /col, /tlb_kill_request_events)
main_base=widget_base(base, /col, /base_align_center)
left_base=widget_base(main_base, /row)
left_toggle=cw_bgroup(left_base, ['File', 'Number', 'Active Image'], /col, $
                      /exclusive, set_value=0, label_top='Operand 1')
left_main_base=widget_base(left_base, /col)
left_file_base=widget_base(left_main_base, /row)
left_file_box=cw_field(left_file_base, value='', title='Filename:', xs=36)
left_browse_button=widget_button(left_file_base, value='Browse')
left_number_box=cw_field(left_main_base, value='0', title='Number:', xs=48)
operations=cw_bgroup(main_base, ['+', '-', '*', '/'], set_value=1, $
    /return_name, /exclusive, /row, label_left='Operation:')
right_base=widget_base(main_base, /row)
right_toggle=cw_bgroup(right_base, ['File', 'Number', 'Active Image'], /col, $
                       /exclusive, set_value=0, label_top='Operand 2')
right_main_base=widget_base(right_base, /col)
right_file_base=widget_base(right_main_base, /row)
right_file_box=cw_field(right_file_base, value='', title='Filename:', xs=36)
right_browse_button=widget_button(right_file_base, value='Browse')
right_number_box=cw_field(right_main_base, value='0', title='Number:', xs=48)

calculate_button=widget_button(base, value='Calculate')
close_button=widget_button(base, value='Close')

wids={base_id:conbase_id, $
      file1_box:left_file_box, $
      num1_box:left_number_box, $
      file2_box:right_file_box, $
      num2_box:right_number_box, $
      operations:operations, $
      left_toggle:left_toggle, $
      right_toggle:right_toggle, $
      file1_base:left_file_base, $
      file2_base:right_file_base}
uval={base_id:conbase_id, $
      wids:wids, $
      inbox:0L, $
      left_toggle:0, $
      right_toggle:0, $
      path:base_uval.current_data_directory}

widget_control, base, /realize, set_uval=uval
widget_control, left_file_box+2, /tracking_events
widget_control, right_file_box+2, /tracking_events
widget_control, left_number_box, sensitive=0
widget_control, right_number_box, sensitive=0

base_uval.exist.arithmetic=base
widget_control, conbase_id, set_uval=base_uval

xmanager, 'ql_conmath_tlb', base, /just_reg, /no_block, cleanup='ql_subbase_death'
xmanager, 'ql_conmath_close_button', close_button, /just_reg, /no_block
xmanager, 'ql_file_browse', left_browse_button, /just_reg, /no_block
xmanager, 'ql_file_browse', right_browse_button, /just_reg, /no_block
xmanager, 'ql_filename_box', left_file_box, /just_reg, /no_block
xmanager, 'ql_filename_box', right_file_box, /just_reg, /no_block
xmanager, 'ql_conmath_left_toggle', left_toggle, /just_reg, /no_block
xmanager, 'ql_conmath_right_toggle', right_toggle, /just_reg, /no_block
xmanager, 'ql_conmath_calculate', calculate_button, /just_reg, /no_block

end
