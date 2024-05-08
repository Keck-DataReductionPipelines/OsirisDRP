; +
; NAME: ql_create_cimage
;
; PURPOSE: checks the dimension of the file, makes pointers to the
;          image data and header, and then creates a new instance of
;          the 'CImage' class.         
;
; CALLING SEQUENCE: ql_create_cimage, base_id, filename, extension
;
; INPUTS: filename (string) - path of the file to be opened
;
; OPTIONAL INPUTS:                     
;
; OPTIONAL KEYWORD INPUTS:
;
; OUTPUTS: im -- what it does
;
; OPTIONAL OUTPUTS;
;
; EXAMPLE:
;
; NOTES: returns the parameter im
; 
; PROCEDURES USED:
;
; REVISION HISTORY: 17DEC2002 - MWM: added comments.
;2007-06-28 Added mode to check for GMOS data cube format and adjust accordingly. M.D.Perrin
;2024-05-07 Now compatible with data that is not in the zeroth extension. This is common with other IFU instruments. - Tuan Do. 
;- 

function ql_create_cimage, base_id, filename, extension, message=message


; get the number of extensions in the fits header
fits_info, filename, n_ext=n_ext, /silent

h = headfits(filename)
instrume = strcompress(sxpar(h,'INSTRUME',count=count),/remove_all) ;; HACK IN GMOS SUPPORT - MDP
if count eq 1 then if instrume eq 'GMOS-N' then extension=1

;; assume that if there is nothing in the first extension, we should go to the second extension
naxis = sxpar(h, 'NAXIS')
if naxis eq 0 then extension = 1

if arg_present(extension) then begin
    ; check to make sure this extension exists
    if (extension gt n_ext) then begin
        print, 'Extension undefined, opening file'
        extension=0
    endif 
endif else begin
    extension=0
endelse

; reads in the file and gets its size (dim, xs, ys, zs)
imdata=ql_readfits(filename, hd, EXTEN_NO=extension)
imsize = size(imdata)


if count eq 1 then if instrume eq 'GMOS-N' then begin
	; re-read in the FITS header, inheriting from the PDU header, as is the
	; GMOS convention.
	fits_read, filename, exten=extension, temp, hd, /PDU
	sxaddpar, hd, "COADDS", 1 ; no coadds keyword present by default...
endif

; if the image has
case imsize[0] of
    3: zsize=imsize[3]
    2: zsize=1
    else: begin
        ; issue an error message
        message='QL2 can not handle '+strtrim(imsize[0],2)+' dimension images.'
        ; answer=dialog_message(message, dialog_parent=base_id, /error)
        im=obj_new()
        return, im
    end
endcase


; gets the size in the z dimension, if there is no z dimension the z
; size is given a value of 1

; if not a valid fits file, readfits returns a single -1
if (imdata[0] eq -1 and n_elements(imdata) eq 1) then begin 
	im=-1.0  ;  set return value to -1
endif else begin
       ; makes pointers to the data and header
	data_ptr=ptr_new(imdata)
	hd_ptr=ptr_new(hd)
       ; makes a new instance of the 'CImage' class with the 
       ; appropriate parameters
	im=obj_new('CImage', filename=filename, data=data_ptr, $
		header=hd_ptr, xs=imsize[1], ys=imsize[2], zs=zsize, $
                n_ext=n_ext, ext=ext)
endelse


; returns a pointer to new instance
return, im

end
