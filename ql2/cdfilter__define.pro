;+
; NAME: cdfilter__define
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
; REVISION HISTORY: 20JUL2004 - MWM: added comments.
; 	2007-07-03	MDP: Fix multiple pointer leaks on startup.
;-

function CDFilter::Init, winbase_id=winbase_id, filename=filename, path=path

; set keywords
if keyword_set(winbase_id) then winid=winbase_id else winid=0L
if keyword_set(filename) then file=filename else file=''
if keyword_set(path) then pathname=path else pathname=''

ptr_free,self.filter_list
self.filter_list=[ptr_new(0, /allocate_heap), ptr_new(0, /allocate_heap), $
                  ptr_new(0, /allocate_heap), ptr_new(0, /allocate_heap), $
                  ptr_new(0, /allocate_heap)]


; set values of members of object

self.baseid=winid
self.filename=file
self.path=pathname

return, 1

end

pro CDFilter::FilterBrowse, base_id

filename=dialog_pickfile(dialog_parent=self.baseid, filter='*.dat', $
    path=self.path, get_path=newpath, /read, /must_exist)

self.filename=filename
self.path=newpath

end

pro CDFilter::LoadFilter, filename

openr, Unit, filename, /GET_LUN
i=0
a=0.d

readf, Unit, a
data=[[a]]

while not eof(Unit) do begin
      readf, Unit, a
      data=[[data],[a]]
      i=i+1
  endwhile

; store data in available member variable
filter_ptr=ptr_new(data)

; update apply digital filter list
nfiles=4
;ql_conupdate_recent_file_list, self.baseid, filename, nfiles
self->UpdateFilterList, filename, filter_ptr

end

pro CDFilter::UpdateFilterList, filename, filter_ptr

; get conbase uval
widget_control, self.baseid, get_uval=uval

; shifts the recent file list array one space to the right
uval.recent_file_list=shift(uval.recent_file_list, 1)

; makes the first element in the recent file list the new filename
uval.recent_file_list[0]=filename

widget_control, self.baseid, set_uval=uval

for i=0, 4 do begin
        ; makes the menu unsensitive if there is no filename in the element
	if uval.recent_file_list[i] eq 'None' then sens=0 else sens=1
        ; updates the menu selections with the filenames
	widget_control, uval.wids.menu+uval.recent_file_index+i, $
		sensitive=sens, set_value=uval.recent_file_list[i] 
endfor

; sets conbase uvalwith updated recent filter list
widget_control, self.baseid, set_uval=uval

; make a temporary list that holds the current buffer list
temp_list=self.filter_list
wh=where(self.filter_lock eq 0)
if (wh[0] ne -1) then begin
	temp_list[wh]=shift(self.filter_list[wh], 1)
;	if obj_valid(*(self.filter_list[wh[n_elements(wh)-1]])) then $
;		obj_destroy, *(self.filter_list[wh[0]])
	temp_list[wh[0]]=filter_ptr
	self.filter_list=temp_list
endif

end

pro CDFilter::DrawFilterPlot, filterid, p_PlotWin

widget_control, self.baseid, uval=winbase_uval

; set values in plot window object
plot_win=*p_PlotWin
plot_win->SetXData_Range, [x0pix, x1pix]
plot_win->SetYData_Range, [y0pix, y1pix]
plot_win->SetXRange, [x0pix, x1pix]
plot_win->SetYRange, [y0pix, y1pix]
plot_win->SetResetRanges, 1

case filter_no of
    1: begin 
        ; get the filter data
        selectionid=filterid-(winbase_uval.wids.menu+winbase_uval.recent_file_index)
        filter_no=selectionid
        filter=*self.filter_list[filter_no]
        plot_win->DrawFilterPlot, self.filter_list[filter_no]
    end
endcase

end

pro CDFilter::ApplyFilter, filterid, filtername

widget_control, self.baseid, get_uval=winbase_uval

; get the imwin obj, image object, image data
p_ImWinObj=self.p_ImWinObj
ImWinObj=*p_ImWinObj
p_ImObj=ImWinObj->GetImObj()
ImObj=*p_ImObj
imdata_ptr=ImObj->GetData()
imdata=*imdata_ptr

; get the filter data
selectionid=filterid-(winbase_uval.wids.menu+winbase_uval.recent_file_index)
filter_no=selectionid
filter=*self.filter_list[filter_no]
filter_size=n_elements(filter)

; check to make sure the filter is the same size as the data cube
axesorder=ImWinObj->GetAxesOrder()

; get dimensions of image
im_xs=ImObj->GetXS()
im_ys=ImObj->GetYS()
im_zs=ImObj->GetZS()
naxis=ImWinObj->GetNAxis()

; transpose image
im=transpose(imdata, axesorder[0:naxis-1])
; initialize a new image the same size & orientation as the image data
filteredim=im
im_s=([im_xs, im_ys, im_zs])[axesorder]

; applying filter to the data cube
if (filter_size ne im_s[2]) then begin
    message=['Data filter must have the same number of Z elements as the displayed image']
    answer=dialog_message(message, dialog_parent=$
       self.baseid)
    return
endif else begin
    for i=0, im_s[0]-1 do begin
        for j=0, im_s[1]-1 do begin
            filteredim[i,j,*]=im[i,j,*]*filter
        endfor
    endfor
endelse

ptr_free, self.solution_data
self.solution_data=ptr_new(filteredim)

; get the image header information to set in the new cimage
hd_ptr=ImObj->GetHeader()

; get the conbase uval to read the image opening parameters
conbase_id=ImWinObj->GetParentBaseId()
widget_control, conbase_id, get_uval=conbase_uval

; make a new instance
filtered_image=obj_new('CImage', filename='', data=self.solution_data, header=hd_ptr, $
    xs=im_s[0], ys=im_s[1])

if obj_isa(filtered_image, 'CImage') then begin
    p_ImObj=ptr_new(filtered_image, /allocate_heap)
    filter_im=*p_ImObj
    ext=filter_im->GetExt()
    filter_im->setFilename, filtername
    if conbase_uval.newwin eq 0 then $
          ql_display_new_image, conbase_id, p_ImObj, $
          p_WinObj=conbase_uval.p_curwin, ext $
        else $
          ql_display_new_image, conbase_id, p_ImObj, ext

endif else begin
    message=['Error in filtering data cube:', $
       ' Error creating CImage object']
    answer=dialog_message(message, dialog_parent=$
       self.baseid)
endelse

end

pro CDFilter::RemoveFilter

; removing the filter from the data cube

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  BEGIN CIMAGE ACCESSOR/MUTATOR FUNCTIONS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pro CDFilter::SetFilename, filename

self.filename=filename

end

function CDFilter::GetFilename

return, self.filename

end

pro CDFilter::SetPath, path

self.path=path

end

function CDFilter::GetPath

return, self.path

end

pro CDFilter::SetImWinObj, newImWinObj

self.p_ImWinObj=newImWinObj

end

function CDFilter::GetImWinObj

return, self.p_ImWinObj

end

pro CDFilter::SetSolutionData, solution_data

self.solution_data=solution_data

end

function CDFilter::GetSolutionData

return, self.solution_data

end

pro CDFilter::SetFilterList, filter_list

self.filter_list=filter_list

end

function CDFilter::GetFilterList

return, self.filter_list

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  END CIMAGE ACCESSOR/MUTATOR FUNCTIONS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pro CDFilter__define

; data, header and OrigData point at undefined heap variable
p_ImWinObj=ptr_new(/allocate_heap)
solution_data=ptr_new(/allocate_heap)
filter_list=[ptr_new(0, /allocate_heap), $
             ptr_new(0, /allocate_heap), $
             ptr_new(0, /allocate_heap), $
             ptr_new(0, /allocate_heap), $
             ptr_new(0, /allocate_heap)]

; create a structure that holds an instance's information
struct={CDFilter, $
        baseid:0L, $               ; wid of window base
        filename:'', $             ; image filename
        path:'', $                 ; path of the previous search directory
        p_ImWinObj:p_ImWinObj, $   ; pointer to the image window
        solution_data:solution_data, $ ; data product after filtering
        filter_list:filter_list, $
        filter_lock:bytarr(5) $
       }
end
