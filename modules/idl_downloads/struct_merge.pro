;+
; NAME: struct_merge
;
; 	Given two structures, A and B, each of which may be an array, and
; 	which may have different tag names, create a new structure C
; 	which is the union of both A and B. 
;
;	Fields present in each of A and B will be copied into C. Fields present
;	in one but not the other will be copied from that one where present, 
;	and filled with blanks or zeros for the one where not present.
;
; 	i.e. if one = {name: 'one', value=4}
; 		    two = {name: 'two', something="test"}
;
; 		  then struct_merge(one,two) is the array:
; 		  	    [{name: 'one', value=4, something=''}, 
; 		  	     {name: 'two', value=0, something='test'}]
;
;	This is sort of like Dave Schlegel's 'struct_append.pro', but it
;	handles gracefully the case where the structures have partially-overlapping
;	lists of tag names, and also appends the second structure onto the first
;	to build an array.
;
;
; INPUTS:
; 		two structures
; OUTPUTS:	
; 		the merged structure, as described above
;
; WARNINGS:
;
; 	This will fail if structures A and B have conflicting types for the
; 	same tag name.
;
; 	This will also fail if either of the structures themselves contain a
; 	substructure as a member.
;
; HISTORY:
; 	Began 2006-04-20 20:55:24 by Marshall Perrin 
;-

FUNCTION struct_merge, one0, two0

; make copies so as to not overwrite original variables
one = one0
two = two0

names1 = tag_names(one)
names2 = tag_names(two)

union = cmset_op(names1, "or", names2)
oneonly = cmset_op(names1, "and", /not2, names2,count=onecount)
twoonly = cmset_op(/not1, names1, "and", names2,count=twocount)

;print, "both:", union
;print, "one only: ", oneonly
;print, "two only: ", twoonly

; Extract the fields which are unique to each one. 
;
; There are two similar routines for this in the IDLUTILS
; library from David Schlegel. 
; struct trimtags is preferable to struct_selecttags
; since it ensures that the column order matches the
; order of the fields in select.
twotrim = struct_trimtags(two,select=twoonly)
onetrim = struct_trimtags(one,select=oneonly)

; add columns from struct 2 onto struct one
for i=0L,twocount-1 do begin
	val = twotrim.(i)
	; create a generic variable of that type
	blankvar = (make_array(1,type=size(twotrim.(i),/type)))[0]
	n = n_elements(one)

	; now add that column onto struct one. 
	if n eq 1 then begin
		; this is easy if it's just 1D
		one = create_struct(one,twoonly[i],blankvar)
	endif else begin
		; it's a bit trickier if one is an array, since now
		; we have to iterate over each element.
		; WARNING: this code only works for 1D arrays right now!
		oneB = one
		one = create_struct(oneb[0],twoonly[i],blankvar)
		for j = 1,n-1 do begin
			one = [one,create_struct(oneb[j],twoonly[i],blankvar)]
		endfor
			
	endelse
endfor 
for i=0L,onecount-1 do begin
	val = onetrim.(i)
	; create a generic variable of that type
	blankvar = (make_array(1,type=size(onetrim.(i),/type)))[0]
	; now add that column onto struct two. 
	n = n_elements(two)
	if n eq 1 then begin
		; this is easy if it's just 1D
		two = create_struct(two,oneonly[i],blankvar)
	endif else begin
		; it's a bit trickier if two is an array, since now
		; we have to iterate over each element.
		; WARNING: this code only works for 1D arrays right now!
		twoB = two
		two = create_struct(oneb[0],oneonly[i],blankvar)
		for j = 1,n-1 do begin
			two = [one,create_struct(oneb[j],oneonly[i],blankvar)]
		endfor
			
	endelse

endfor 
; reorder both to have the same order of columns
one = struct_trimtags(one,select=union)
two = struct_trimtags(two,select=union)


return, [one,two]

end
