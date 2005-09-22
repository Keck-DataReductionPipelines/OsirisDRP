;-----------------------------------------------------------------------
; NAME:  findlines_get_index
;
; PURPOSE: get the tag indices from the s_Lines structure
;
; INPUT :   s_Lines      : the sLines structure as delivered by findlines_read_calline_file
;           WAVE=WAVE    : a two-element vector describing the minimum
;                          and maximum wavelength in microns to be
;                          read (e.g. [1.9,2.2])
;           NAME=NAME    : a string or vector of strings with the
;                          lamps that shall be read (e.g. 'Xe' or
;                          ['Xe','Ne']). This vector can be created
;                          using the findlines_get_lamp_status function.
;           INT=INT      : the minimum (osiris) intensity to be read.
;            
; OUTPUT :  vector with array indices where the line is valid.
;
; STATUS : untested
;
; HISTORY : 25.3.2005, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

function findlines_get_index, s_Lines, WAVE = WAVE, NAME = NAME, INT=INT

   ; limit wavelength range
   if ( keyword_set (WAVE) ) then begin
      if ( bool_is_vector ( WAVE, LEN=2 ) ) then begin
         d_MinL_um = WAVE(0)
         d_MaxL_um = WAVE(1)
      endif else return, error('ERROR IN CALL (get_line_index.pro): WAVE must be a 2-element vector.')
   endif else begin
      d_MinL_um = -1.d99
      d_MaxL_um = +1.d99
   end

   n_Lines = n_elements(s_Lines.vi_Valid)

   ; check for names
   if ( keyword_set ( NAME ) ) then begin
      vs_Name = [NAME]
      vb_StatusName = make_array(/INT, n_Lines, VALUE=0)
      for i=0, n_elements(vs_Name)-1 do $
         vb_StatusName = vb_StatusName or (s_Lines.vs_Name eq vs_Name(i) )
   endif else $
      vb_StatusName = make_array(/INT, n_Lines, VALUE=1)


   ; check for intensities
   if ( keyword_set ( INT ) ) then begin
      vb_StatusInt = make_array(/INT, n_Lines, VALUE=0)
      vi_MaskInt   = where ( s_Lines.vd_Int_adu gt INT, n_Int )
      if ( n_Int gt 0 ) then $
         vb_StatusInt(vi_MaskInt) = 1
   endif else $
      vb_StatusInt = make_array(/INT, n_Lines, VALUE=1)

   ; search the indices of the lines now
   vi_Mask = where ( s_Lines.vd_WL_um ge d_MinL_um and s_Lines.vd_WL_um le d_MaxL_um and $ 
                     vb_StatusName eq 1 and s_Lines.vi_Valid eq 1 and vb_StatusInt eq 1, n ) 

   if ( n eq 0 ) then $
      return, 0 $
   else $
      return, vi_Mask

end
