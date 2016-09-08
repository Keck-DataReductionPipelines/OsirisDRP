;+
; NAME: cimage__define 
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
; REVISION HISTORY: 18DEC2002 - MWM: added comments.
; 	2007-07-03	MDP: Fix multiple pointer leaks on startup.
; 				also added support for FITS astrometry structures
;- 

function CImage::Init, filename=filename, data=data_ptr, header=header_ptr, xs=xs, $
	ys=ys, zs=zs, n_ext=n_ext, ext=ext

; set filename
if keyword_set(filename) then file=filename else file=''
path_filename=file
file=ql_getfilename(file)

; get data and image size
if keyword_set(data_ptr) then begin
	s=size(*data_ptr)
	xsize=s[1]
	ysize=s[2]
        case s[0] of
            3: zsize=s[3]
            2: zsize=1
            else: zsize=1 
        endcase

        max=max(*data_ptr, min=min)

        ; set number of total extensions in the FITS data
		if n_elements(n_ext) eq 0 then n_ext=0 

        ; set extension number of this instance
		if not (keyword_set(ext)) then ext=0

; if not defined, create default image
endif else begin
	data_ptr=ptr_new() ; null pointer...
	xsize=1
	ysize=1
	zsize=1
	max=0.0
	min=0.0
    n_ext=0
    ext=0
endelse

; get or create FITS header
if not (keyword_set(header_ptr)) then  header_ptr=ptr_new() ; null pointer!

; override image size if set
if keyword_set(xs) then x=xs else x=xsize
if keyword_set(ys) then y=ys else y=ysize
if keyword_set(zs) then z=zs else z=zsize

; set values of members of object
self.filename=file
self.path_filename=path_filename
ptr_free, self.data, self.origdata, self.header, self.astr ; Free pointers!
self.data=data_ptr
self.OrigData=data_ptr
self.header=header_ptr
astr_ptr=ptr_new()
self.xs=x
self.ys=y
self.zs=z
self.MinVal=min
self.MaxVal=max
self.n_ext=n_ext
self.ext=ext

if keyword_set(header_ptr) then begin 
	extast3, *header_ptr, astr, nparams, /silent
	if nparams ne -1 then self->SetAstr, ptr_new(astr)
	; don't just directly set self.astr 
	; call the SetAstr procedure, which validates the astrometry header before 
	; setting it.
endif

return, 1

end


pro CImage::Cleanup
	ptr_free, self.data, self.origdata, self.header, self.astr ; Free pointers!
	
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  BEGIN CIMAGE ACCESSOR/MUTATOR FUNCTIONS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pro CImage::SetFilename, filename, file
; set the path + filename and the filename member variables
self.path_filename=filename

if keyword_set(file) then self.filename=filename else $
self.filename=ql_getfilename(filename)

end

function CImage::GetFilename
return, self.filename

end

function CImage::GetPathFilename
return, self.path_filename

end

pro CImage::SetData, data_ptr

self.data=data_ptr

end

function CImage::GetData

return, self.data

end

pro CImage::SetOrigData, data_ptr

self.OrigData=data_ptr

end

function CImage::GetOrigData

return, self.OrigData

end

pro CImage::SetHeader, header_ptr

self.header=header_ptr

end

function CImage::GetHeader

return, self.header

end

; MDP additions for WCS
pro CImage::SetAstr, astr_ptr

	; validate the astrometry
	; 0) is the pointer valid?
	
	if ~ptr_valid(astr_ptr) then return
	
	;
	; 1) check that the dimensions of the astrometry match the
	;    dimensions of the image
	
	image_naxes = (size(*self.data))[0]
	wcsheader_naxes = n_elements((*astr_ptr).ctype)
	if image_naxes ne wcsheader_naxes then begin
		message, "WCS Header number of axes does not match image number of axes - ignoring WCS header for this file!",/info
		return
	endif

	; 2) For data cubes, check that the header matches the WCS
	;    spec in terms of the proper wavelength axis CTYPE 

	if wcsheader_naxes eq 3 then begin
	 	wave_axes_types = ["FREQ", "ENER", "WAVN", "VRAD", "WAVE", "VOPT", "ZOPT", $
	    	"AWAV", "VELO", "BETA"]
	  	for i = 0,n_elements(wave_axes_types)-1 do begin
	    	axis_lambda = where( strmid((*astr_ptr).ctype,0,4) eq wave_axes_types[i], lambdact)
	    	if lambdact eq 1 then break
		endfor
		if lambdact eq 0 then begin
			message, ' 3D WCS Header is not compliant with WCS standard - ignoring WCS header for this file!',/info
			return
		endif
	endif
	
	self.astr=astr_ptr
end

function CImage::GetAstr,valid=valid
	; Is there an astrometry structure?
	valid = ptr_valid(self.astr)
	if valid then return, self.astr else return, 0
end
;end MDP

pro CImage::SetXS, xs

self.xs=xs

end

function CImage::GetXS

return, self.xs

end

pro CImage::SetYS, ys

self.ys=ys

end

function CImage::GetYS

return, self.ys

end

pro CImage::SetZS, zs

self.zs=zs

end

function CImage::GetZS

return, self.zs

end

pro CImage::SetMinVal, MinVal

self.MinVal=MinVal

end

function CImage::GetMinVal

return, self.MinVal

end

pro CImage::SetMaxVal, MaxVal

self.MaxVal=MaxVal

end

function CImage::GetMaxVal

return, self.MaxVal

end

function CImage::GetN_Ext
	return, self.n_ext
end

pro CImage::SetN_Ext, newN_Ext
	self.N_Ext=newN_Ext
end

function CImage::GetExt
	return, self.ext
end

pro CImage::SetExt, newExt
	self.ext=newExt
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  END CIMAGE ACCESSOR/MUTATOR FUNCTIONS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pro CImage__define

; data, header and OrigData point at undefined heap variable
; MDP: do NOT allocate heap variables here! This is a memory leak
; because in the INIT routine above we just assign pointers to 
; these object member variables WITHOUT freeing the pre-existing
; allocated heap variables.
data=ptr_new()
header=ptr_new()
OrigData=ptr_new()
astr=ptr_new() ; astrometry structure

; create a structure that holds an instance's information 
struct={CImage, $
        filename:'', $        ; image filename
        path_filename:'', $   ; image path and filename
        data:data, $          ; image data 
        header:header, $      ; header of the fits file
        astr:astr, $          ; astrometry structure of the fits file
        xs:0L, $              ; x size of the image data
        ys:0L, $              ; y size of the image data
        zs:0L, $              ; z size of the image data
	OrigData:OrigData, $  ; original image data
        MinVal:0.0, $         ; minimum image value
        MaxVal:0.0, $         ; maximum image value
        n_ext:0, $            ; number of extensions in this FITS
        ext:0 $              ; extension of this image
       }

end

