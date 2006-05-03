;+
; NAME:
;   struct_trimtags
;
; PURPOSE:
;   Trim a structure to a list of selected and/or excluded tags
;
; CALLING SEQUENCE:
;   outstruct = struct_trimtags(instruct, [ select_tags=, except_tags=, $
;    format= ]
;
; INPUTS:
;   instruct   - Input structure, which can be an array
;
; OPTIONAL INPUTS:
;   select_tags- List of tag names to include; this can use wildcards.
;   except_tags- List of tag names to exclude; this can use wildcards.
;   format     - If set, then convert all tags to strings using this
;                array of format codes (one per output tag).  These format
;                codes should not include parentheses.  For example,
;                they could be ['f7.2','a'].
;
; OUTPUTS:
;   outstruct  - Ouput structure array
;
; OPTIONAL OUTPUTS:
;
; COMMENTS:
;   The selection based upon SELECT_TAGS is performed before excluding
;   tags based upon EXCEPT_TAGS.  The order of the tags in the output
;   structure is the same as the order set by SELECT_TAGS, which allows
;   one to re-order the tags in a structure.
;
; EXAMPLES:
;
; BUGS:
;   No checks are done to assure that tags are not selected multiple
;   times (which will crash this code).
;   No checks are done that FORMAT has the correct number of elements,
;   which could also crash this code.
;
; PROCEDURES CALLED:
;   copy_struct
;   copy_struct_inx
;
; REVISION HISTORY:
;   05-Jun-2002  Written by D. Schlegel, Princeton
;------------------------------------------------------------------------------
function struct_trimtags, instruct, select_tags=select_tags, $
 except_tags=except_tags, format=format

   nout = n_elements(instruct)
   if (nout EQ 0) then return, 0
   if (NOT keyword_set(select_tags) AND NOT keyword_set(except_tags)) then $
    return, instruct

   tags = tag_names(instruct)
   ntag = n_elements(tags)

   ;----------
   ; Select which tags are wanted according to SELECT_TAGS.

   indx = -1L
   if (keyword_set(select_tags)) then begin
      for jtag=0, n_elements(select_tags)-1 do begin
         jj = where(strmatch(tags, strupcase(select_tags[jtag])))
         if (jj[0] NE -1) then begin
            if (indx[0] EQ -1) then indx = jj $
             else indx = [indx, jj]
         endif
      endfor
   endif else begin
      indx = lindgen(ntag)
   endelse

   if (indx[0] EQ -1) then return, 0

   ;----------
   ; De-select which tags are excluded according to EXCEPT_TAGS.

   if (keyword_set(except_tags)) then begin
      qkeep = bytarr(n_elements(indx)) + 1B
      for ktag=0, n_elements(except_tags)-1 do begin
         iexc = where(strmatch(tags[indx], strupcase(except_tags[ktag])), nexc)
         if (nexc GT 0) then qkeep[iexc] = 0B
      endfor
      ikeep = where(qkeep, nkeep)
      if (nkeep EQ 0) then return, 0
      indx = indx[ikeep]
   endif else begin
      nkeep = n_elements(indx)
   endelse

   ;----------
   ; Create the output structure

   if (keyword_set(format)) then begin
      outstruct = create_struct(tags[indx[0]], $
       strarr(n_elements(instruct[0].(indx[0]))))
      for ii=1, nkeep-1 do $
       outstruct = create_struct(outstruct, tags[indx[ii]], $
        strarr(n_elements(instruct[0].(indx[ii]))))
   endif else begin
      outstruct = create_struct(tags[indx[0]], instruct[0].(indx[0]))
      for ii=1, nkeep-1 do $
       outstruct = create_struct(outstruct, tags[indx[ii]], $
        instruct[0].(indx[ii]))
   endelse

   ;----------
   ; Copy the requested tags

   struct_assign, {junk:0}, outstruct ; Zero-out all elements
   outstruct = replicate(outstruct, nout)
   if (keyword_set(format)) then begin
      for ii=0, nkeep-1 do begin
;         outstruct[*].(ii) = string(instruct.(indx[ii]), $
;          format='('+format[ii]+')')
; The STRING() function will drop from its output any elements that
; are simply blank strings.  I consider this a bug, but one that can
; be avoided by looping through one element (structure row) at a time.
         for irow=0, nout-1 do $
          outstruct[irow].(ii) = string(instruct[irow].(indx[ii]), $
           format='('+format[ii]+')')
      endfor
   endif else begin
      struct_assign, instruct, outstruct
   endelse

   return, outstruct
end
;------------------------------------------------------------------------------
