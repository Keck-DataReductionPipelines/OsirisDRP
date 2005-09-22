;-----------------------------------------------------------------------------
; NAME:  add_fitskwd_to_header
;
; PURPOSE: add fits keywords to the header
;
; INPUT : p_DataHeader   : pointer to a single data header
;         s_OutputDir    : output directory (optionally with
;                          environment variables)
;         s_Type         : file type designator :
;                          CORDISP      : output from corrdisper_000.pro
;                          FITDISP      : calibration output from
;                                         fitdispers_000.pro
;                          MOSAIC       : mosaiced data
;                          SPEC         : extracted stellar spectrum
;                          DIVSTAR      : division by a stellar spectrum    
;                          SUBSKY       : sky subtracted images
;                          DARK         : dark images
;                          DARKC        : dark current
;                          SFLAT        : spatially rectified flatfield
;                          IFLAT        : not spatially rectified flatfield
;                          BPIXN        : bad pixel mask
;                          DETRES       : detector response
;
;         /IMAG          : use the imager filter keyword FILTER
;
; OUTPUT : filename (string)
;
; ON ERROR : returns ERR_UNKNOWN 
;
; ALGORITHM : creates a filename based on the output directory name,
;             the filename as specified by the DATAFILE keyword in the
;             header, the filter and scale as specified by the SFILTER
;             and SSCALE keywords (or optionally the FILTER keyword if
;             /IMAG is set) and the file type designator.
;
; STATUS : untested
;
; HISTORY : 18.10.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------------


pro add_fitskwd_to_header, DataSet, n_Sets, vs_Keywords, v_KeywordsVal, v_KeywordsType

    for i=0, n_Sets-1 do begin

       for j = 0, n_elements(vs_Keywords)-1 do begin

          case strupcase(v_KeywordsType(j)) of

             'D'  : val = double(v_KeywordsVal(j))
             'F'  : val = float(v_KeywordsVal(j))
             'A'  : val = strg(v_KeywordsVal(j))
             'I'  : val = fix(v_KeywordsVal(j))
             'B'  : val = byte(v_KeywordsVal(j))
             else : warning,'WARNING (set_header.pro): Unknown format (' + strg(v_KeywordsType(j)) + ').'

          end

          if ( strupcase(vs_Keywords(j)) eq 'DATAFILE' ) then $
             val = val + '_' + strg(i)

          sxaddpar, *DataSet.Headers[i], vs_Keywords(j), val
          info, 'INFO (set_header.pro): Setting ' + vs_Keywords(j) + ' to ' + strg(val) + ' in set ' + strg(i)

       end

   end

end
