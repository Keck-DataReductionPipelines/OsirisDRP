;-----------------------------------------------------------------------------
; NAME:  add_fitskwd_to_header
;
; PURPOSE: add fits keywords to the header
;
; INPUT : p_Header       : pointer or pointer array with the headers
;         n_Sets         : number of valid sets in dataset
;         vs_Keywords    : vector (string) of keywords to add, string with fits keywords to
;                          be added, e.g. 'SFILTER,DATAFILE', separated by kommas
;         v_KeywordsVal  : vector (string) of keywords values to add, string with fits values to
;                          be added, e.g. 'Kbb, testfile', separated by kommas
;         v_KeywordsType : vector (string) of keywords types, string with types of fits
;                          keywords: a,A : string
;                                    b,B : byte
;                                    d,D : double
;                                    f,F : float
;                                    i,I : integer
;                          e.g. 'a,a'
;         [/REPL]        : checks if the keyword already exists and
;                          deletes it (useful if the keyword is
;                          multiply defined)
;         [/DEL]         : deletes the specified keywords from the header
;
; OUTPUT : none
;
; ON ERROR : returns ERR_UNKNOWN 
;
; STATUS : untested
;
; HISTORY : 18.10.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------------

pro add_fitskwd_to_header, p_Headers, n_Sets, vs_Keywords, v_KeywordsVal, v_KeywordsType, $
                           REPL=REPL, DEL=DEL, DEBUG=DEBUG

    if ( keyword_set (DEL) and keyword_set (REPL) ) then $
       warning,'WARNING (add_fitskwd_to_header): Either REPL or DEL.'

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

          if ( keyword_set (DEL) ) then begin
             sxdelpar, *p_Headers[i], vs_Keywords(j)
             info, 'INFO (set_header.pro): Deleting ' + vs_Keywords(j) + ' from set ' + strg(i)
          end
         
          if ( NOT keyword_set (DEL) ) then begin

             if ( keyword_set (REPL) ) then $
                sxdelpar, *p_Headers[i], vs_Keywords(j)

             sxaddpar, *p_Headers[i], vs_Keywords(j), val

             if ( keyword_set (DEBUG ) ) then $
                debug_info, 'DEBUG INFO (add_fitskwd_to_header): Setting ' + vs_Keywords(j) + ' to ' + strg(val) + ' in set ' + strg(i)

          end

       end

   end

end
