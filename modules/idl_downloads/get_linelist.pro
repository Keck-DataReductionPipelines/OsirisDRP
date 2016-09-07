;-----------------------------------------------------------------------
; NAME:  get_linelist
;
; PURPOSE: get the calibration line list for the lamps as described in
;          the headers
;
; INPUT :  p_Headers   : pointer or pointer array with headers
;          nFrames     : number of valid headers in p_Headers
;          s_LineFile  : absolute path with the line list
;          [/DEBUG]    : debug
;
; ADDITIONAL INPUT : 
;                The format of the arc line file should be :
;                Usage  | air wavelength | rel. intensity | Precision   | Description                
;                         double           double           integer       string
;                0 or 1 | nm               adu              # of digits
;                Usage indicates whether the line shall be
;                read/returned (1) or not (0)
;                The description must contain the name of the
;                calibration lamp, Ar, Kr, Ne, Xe (2-letter upper-
;                and/or lowercase). The rest of the string is ignored.
;                Example : "Ne blablabla"
;                The " are required!!!
;
; OUTPUT : structure { vd_Lines_nm   : linelist with wavelengths in nm
;                      vd_Lines_adu  : linelist with intensities in
;                                      relative units
;                      vi_Prec       : precision in digits
;                      vs_Name       : name of the line }
;
; ON ERROR : returns ERR_UNKNOWN from APP_CONSTANTS
;
; ALGORITHM : 1. Read the fitskeywords describing the lamp status:
;                "Cal_Lamp_Ar_On", "Cal_Lamp_Kr_On", "Cal_Lamp_Ne_On", "Cal_Lamp_Xe_On"
;                Their values must be 1 (lamp on) or 0 (lamp off).
;             2. If no frame has the lamp on a calibration linelist
;                with OH lines is returned.
;             3. Read the linelist file. 
;             4. This procedure returns all calibration lines that are
;                requested by the header.
;  
; NOTES : In order to find the calibration file 'cal_line.list' an
;         environment variable $OSIRIS_DRS_CAL_FILES must be declared
;         containing the directory where the calibration files are stored.
;
; STATUS : untested
;
; HISTORY : 28.9.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

function get_linelist, p_Headers, nFrames, s_LineFile, DEBUG=DEBUG

    ; status of the ar kr ne xe lamp, 1 is on 0 is off
    sb_Lamp = { Argon:0,    Krypton:0,    Neon:0,    Xenon:0 }
    ss_Lamp = { N1:'AR', N2:'KR', N3:'NE', N4:'XE' }   ; must be uppercase
    ; names of the fits keywords describing the lamp status
    vs_Lamp = ["Ar_On", "Kr_On", "Ne_On", "Xe_On"] 

    if ( keyword_set ( DEBUG ) ) then $
       debug_info, 'DEBUG INFO (get_linelist.pro): Getting calibration lines from '+strg(s_LineFile)

    ; here it goes

    ; some internal checks
    if ( n_tags(sb_Lamp) ne n_tags(ss_Lamp) or $
         n_tags(sb_Lamp) ne n_elements(vs_Lamp) ) then $
       return, error('FATAL ERROR (get_linelist.pro): Internal error.')

    ; get the lamps that are switched on
    b_FoundCalFrame = 0   ; indicator if any of the files have a lamp on

    for i=0, nFrames-1 do begin
       for j=0, n_elements(vs_Lamp)-1 do begin
          b_Lamp = SXPAR(*p_Headers[i], vs_Lamp(j), /SILENT, count=ncount)
          if ( ncount ne 1 ) then $
             return, error( 'ERROR IN CALL (get_linelist.pro): keyword '+strg(vs_Lamp(i))+' defined '+ $
                strg(ncount)+ ' times in header '+strg(i)+'.' )
          if ( b_Lamp eq 1 ) then begin
             sb_Lamp.(j) = 1
             b_FoundCalFrame = 1
          end
       end
    end

   if ( b_FoundCalFrame eq 0 ) then begin
      ; you want OH line calibration
      info, 'INFO (get_linelist.pro): No input file has a lamp on. Assuming OH-line calibration.'
      return, error ('ERROR IN CALL (get_linelist.pro): Sorry, OH calibration currently not supported.')
   end

   ; read the calibration line file
   if ( NOT file_test(s_LineFile) ) then $
      return, error ('FAILURE (get_linelist.pro): File '+strg(s_LineFile)+ $
         ' with calibration lines not found.')

   vd_WL = [0.d]  &  vd_Int = [0.d]  &  vi_Prec = [0]  &  vs_Name = ['']
   a = 0.d  &  b = 0.d  &  c = 0  &  d = ''  &  e = 0

   n = 0
   openr,10,s_LineFile
   while not eof(10) do begin
      readf,10,e,a,b,c,d
      if ( e eq 1 ) then begin
         vd_WL   = [vd_WL, a]
         vd_Int  = [vd_Int,b]
         vi_Prec = [vi_Prec,c]
         vs_Name = [vs_Name,d]
         n       = n + 1
      endif
   endwhile
   close,10

   if ( n eq 0 ) then $
      return, eror ('FAILURE (get_linelist.pro): No valid (acc. to first row if line list) calibration line found.')

   vd_WL   = vd_WL[1:*]
   vd_Int  = vd_Int[1:*]
   vi_Prec = vi_Prec[1:*]
   vs_Name = vs_Name[1:*]

   if ( b_FoundCalFrame eq 0 ) then begin

      ; wavelength calibration with OH lines
      vs_NameCut = strupcase(strmid(strg(vs_Name),1,2))
      vi_Mask    = where ( vs_NameCut eq 'OH', n_Lines )

      if ( n_Lines eq 0 ) then $
         return, error ('ERROR IN CALL (get_linelist.pro): None of the requested OH calibration lines found in '+ $
            strg(s_LineFile)+'.')

      vd_AllWL   = vd_WL(vi_Mask)
      vd_AllInt  = vd_Int(vi_Mask)
      vi_AllPrec = vi_Prec(vi_Mask)
      vs_AllName = vs_Name(vi_Mask)

   endif else begin

      vd_AllWL = [0.d]  &  vd_AllInt = [0.d]  &  vi_AllPrec = [0]  &  vs_AllName = ['']

      n_Lines = 0     ; total number of lines found

      for i=0, n_elements(vs_Lamp)-1 do begin

         if ( sb_Lamp.(i) eq 1 ) then begin

            vs_NameCut = strupcase(strmid(strg(vs_Name),1,2))

            vi_Mask   = where ( vs_NameCut eq ss_Lamp.(i), n_LinesTmp )

            if ( n_LinesTmp eq 0 ) then $
               return, error ('ERROR IN CALL (get_linelist.pro): '+strg(ss_Lamp.(i))+$
                  '-lines requested but not found in '+strg(s_LineFile))

            info, 'INFO (get_linelist.pro): Found '+strg(n_LinesTmp)+' '+strg(ss_Lamp.(i))+$
               ' calibration lines in the list.'

            n_Lines = n_Lines + n_LinesTmp

            vd_AllWL   = [vd_AllWL, vd_WL(vi_Mask)]
            vd_AllInt  = [vd_AllInt, vd_Int(vi_Mask)]
            vi_AllPrec = [vi_AllPrec, vi_Prec(vi_Mask)]
            vs_AllName = [vs_AllName, vs_Name(vi_Mask)]

         end

      end

      vd_AllWL   = vd_AllWL[1:*]
      vd_AllInt  = vd_AllInt[1:*]
      vi_AllPrec = vi_AllPrec[1:*]
      vs_AllName = vs_AllName[1:*]

      if ( n_Lines eq 0 ) then $
         return, error ('ERROR IN CALL (get_linelist.pro): None of the requested calibration lines found in '+ $
            strg(s_LineFile)+'.')

   end

   ; return the list

   return, { vd_Lines_nm   : vd_AllWL, $
             vd_Lines_adu  : vd_AllInt, $
             vi_Prec       : vi_AllPrec, $
             vs_Name       : vs_AllName }

end
