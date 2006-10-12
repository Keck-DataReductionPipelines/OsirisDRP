
COMMON MAKE_DOC, COMMON_MAKE_DOC_START,$
                 COMMON_MAKE_DOC_KEY


function strg, s

   return, strtrim(string(s),2)

end


function make_doc_replace, s

   ss = ''
   for i=0, strlen(s)-1 do begin
      is = strmid(s,i,1)
      case is of 
         '_'  : ss = ss + '\_'
         '#'  : ss = ss + '\#'
         ';'  : ss = ss + ' '
         else : ss = ss + is
      endcase

   end

   return, ss

end


function make_doc_get_between_key, s, key

   COMMON MAKE_DOC
  
   mask_key = strpos( s, key ) ne -1
   mask     = strpos( s, COMMON_MAKE_DOC_KEY(0) ) ne -1
   for i=1, n_elements(COMMON_MAKE_DOC_KEY)-1 do $
      mask = mask or strpos( s, COMMON_MAKE_DOC_KEY(i) ) ne -1

   mask = mask + mask_key

   s_Lines = ''
   i=0
   while ( i lt n_elements(s) ) do begin
      if ( mask(i) eq 2 ) then begin
         s_Lines = [ s_Lines, s(i) ]
         i = i + 1
         while ( i lt n_elements(s) ) do begin
            if ( mask(i) ne 1 ) then begin
               s_Lines = [ s_Lines, s(i) ]
               i = i + 1
            endif else $
               break
         endwhile
      endif else $
         i = i + 1
   end

   return, s_Lines

end


function make_doc_read_line, s

   COMMON MAKE_DOC
  
   if ( strpos ( strupcase(s), "@BEGIN" ) ne -1 ) then $
      COMMON_MAKE_DOC_START = 1 $
   else $
      if ( COMMON_MAKE_DOC_START eq 1 ) then return, 1 else return, 0

end

function make_doc_end, s

   if ( strpos ( strupcase(s), "@END" ) eq -1 ) then $
      return, 1

end


; this program only works under linux and has been extended to prepare
; the documentation for OSIRIS modules


;make_doc, '.', 'corrtilt_000.pro', OUT='corrtilt_000', AUTHOR='Christof Iserlohe', TITLE = 'corrtilt$\_$000', /TEXIT

; --- how to use it :

; This line is ignored
;
; @BEGIN                               ; all keywords must be enclosed by @BEGIN and @END
;                                      ;    everything between two keywords belongs to the first keyword
;                                      ;    and must be latex safe (e.g. '\_' instead of '_').
;                                      ;    pure latex is allowed also.
;                                      ;    ALL ; ARE REMOVED.
; @NAME name                           ; the keywords in here are recognized.
;                                      ;    keywords always start with @ 
;
; @PURPOSE purpose
;
; @@@PARAMETERS                        ; table keywords start with @@@, the delimiter is ' : '
;                                      ;    any keyword can be a table keyword
;    Param 1  : blablabla
;    Param 2  : blablabla
;
; @@@DRF-PARAMETERS
;
;    DRF-Param 1  : blablabla
;    DRF-Param 2  : blablabla
;
; @CALIBRATION-FILES calibration files
;
; @INPUT input
;
; @OUTPUT output
;
; @MAIN the main routine
;
; @QBITS  about the quality bits
;
; @DEBUG  debugging
;
; @@@SAVES
;          SAVES 1  : whatever
;          SAVES 2  : nothing
;
; @@@@NOTES                             ; list keywords start with @@@@, the delimiter is ' - '
;                                       ;   all keywords can be list keywords
;   - note 1 \\\\
;   - note 2\\\\
;  
; @STATUS  status
;
; @HISTORY  history
;
; @AUTHOR me
;
; @END
;
; this line is ignored


pro make_doc, dir, files, WEB=WEB, OUT=OUT, AUTHOR=AUTHOR, TITLE=TITLE, $
              TEXIT=TEXIT, TOC=TOC

COMMON MAKE_DOC

COMMON_MAKE_DOC_START = 0
COMMON_MAKE_DOC_KEY = [ '@BEGIN', '@END', '@NAME', '@PURPOSE', $
                        '@PARAMETERS', '@DRF-PARAMETERS', '@CALIBRATION-FILES', $
                        '@INPUT', '@OUTPUT', '@MAIN', '@QBITS', '@DEBUG', '@SAVES', $
                        '@NOTES', '@STATUS', '@HISTORY', '@AUTHOR' ]

if ( NOT file_test(dir,/DIRECTORY) ) then begin
   print, 'Cannot open directory.'
   return
end

s_Files = FINDFILE(files)
if ( n_elements(s_Files) eq 0 ) then begin
   print, 'No files found.'
   return
end

MAKE_DOC_VERSION = '1.1'

texfilename = (keyword_set(OUT)?(OUT):'make_doc')

openw, 10, texfilename+'.tex'
printf,10,'\documentclass[10pt,twoside,a4paper]{article}'
printf,10,'\usepackage{amsmath}'
printf,10,'\usepackage[dvips]{epsfig,rotating}'
printf,10,'\usepackage{graphicx}'
printf,10,'\usepackage{float}'
printf,10,'\restylefloat{table}'

printf,10,'\setlength{\textwidth}{150mm}'
printf,10,'\setlength{\textheight}{210mm}'
printf,10,'\setlength{\headsep}{1cm}'
printf,10,'\setlength{\oddsidemargin}{.25cm}'
printf,10,'\setlength{\evensidemargin}{.5cm}'

printf,10,'\begin{document}'

printf,10,'\pagestyle{headings}'
printf,10,'\begin{titlepage}'
printf,10,'\begin{center}'
printf,10,'\Huge{\begin{verbatim}' + (keyword_set(TITLE)?TITLE:'A document without name') + '\end{verbatim}}'
printf,10,'\vspace{1.0cm}'
printf,10,'\large{\begin{verbatim}'+(keyword_set(AUTHOR)?('By '+ AUTHOR):'A document without author')+'\end{verbatim}}'
printf,10,'\vspace{1.0cm}'
printf,10,'\begin{verbatim}prepared by make_doc Version ' + strg(MAKE_DOC_VERSION) + $
          ' on ' + strjoin((strsplit(strg(systime()),/EXTRACT))([0,1,2,4]),' ') + '\end{verbatim}'
printf,10,'\end{center}'
printf,10,'\end{titlepage}'

if ( keyword_set ( TOC ) ) then begin
   printf,10,'\clearpage'
   printf,10,'\tableofcontents'
   printf,10,'\clearpage'
end

for n=0, n_elements(s_Files)-1 do begin

   openr, 11, s_Files(n)

   s_Line     = ''
   s_Lines    = ''
   n_Lines    = 0
   b_Verbatim = 0

   while ( NOT eof(11) and make_doc_end (s_Line) ) do begin

      readf,11,s_Line
      if ( make_doc_read_line ( s_Line ) ) then begin
         if ( strpos ( strupcase(strtrim(s_Line,2)), '\END{VERBATIM}' ) ne -1 ) then b_Verbatim=0
         s_Lines = [ s_Lines, (b_Verbatim ? s_Line : make_doc_replace(s_Line)) ]
         if ( strpos ( strupcase(strtrim(s_Line,2)), '\BEGIN{VERBATIM}' ) ne -1 ) then b_Verbatim=1
         n_Lines = n_Lines + 1
      end

   endwhile

   close, 11

   if ( keyword_set ( TOC ) ) then $
      printf,10, '\subsection{' + make_doc_replace(s_Files(n)) + '}'

   for i=3, n_elements(COMMON_MAKE_DOC_KEY)-1 do begin

      printf,10, '\subsubsection*{'+strmid(COMMON_MAKE_DOC_KEY(i),1)+'}'

      ; get the lines between two keywords
      s_KeyLine = make_doc_get_between_key (s_Lines, COMMON_MAKE_DOC_KEY(i))

      b_Table = 0
      b_List  = 0

      for j=0,n_elements(s_KeyLine)-1 do begin

         if ( strpos ( s_Keyline(j), '@@@'+COMMON_MAKE_DOC_KEY(i) ) ne -1 ) then begin
            ; a list is coming
            b_List = 1
            printf,10, '\begin{itemize}'
            s_Line = strmid ( s_Keyline(j), strpos ( s_Keyline(j), '@@@' ) + 2 )

         endif else $

            if ( strpos ( s_Keyline(j), '@@'+COMMON_MAKE_DOC_KEY(i) ) ne -1 ) then begin
               ; a table is coming
               b_Table = 1
               printf,10, '\begin{table}[H]'
               printf,10, '\begin{tabular}{ll}'
               s_Line = strmid ( s_Keyline(j), strpos ( s_Keyline(j), '@@' ) + 2 )

            end

         ; get everything behind the key from the line
         if ( strpos(s_KeyLine(j), COMMON_MAKE_DOC_KEY(i) ) ne -1 ) then $
            s_Line = strmid ( s_Keyline(j), strpos ( s_Keyline(j), COMMON_MAKE_DOC_KEY(i) ) + $
                                            strlen(COMMON_MAKE_DOC_KEY(i)) ) $
         else $
            s_Line = s_KeyLine(j)

         if ( strjoin ( strsplit ( s_Line, ' ', /EXTRACT ) )  ne '' ) then begin
            if ( b_Table ) then begin
               if ( strpos ( s_Line,' : ' ) eq -1 ) then $
                  s_Line = ' & ' + strtrim(s_Line,2) + ' \\' $
               else $
                  s_Line = strtrim(strjoin((strsplit(s_Line,':',/EXTRACT)),' & ') + '\\',2)
            endif else begin
               if ( b_List ) then $
                  if ( strpos ( s_Line,' - ' ) ne -1 ) then $
                     s_Line = '\item ' + strtrim(strjoin((strsplit(s_Line,'-',/EXTRACT))),2)

            end

            printf,10, strtrim(s_Line,2)

         end 

      end

      if ( b_Table ) then begin
         printf,10, '\end{tabular}'
         printf,10, '\end{table}'
         printf,10, ' '
      endif else $
         if ( b_List ) then begin
            printf,10,'\end{itemize}'
            printf,10, ' '
         end
   end

   delvarx, stModule

   printf,10,'\clearpage'

end

printf,10,'\end{document}'

close,10


if ( keyword_set(TEXIT) ) then begin
   spawn, 'latex ' + texfilename + '.tex'
   spawn, 'dvips ' + texfilename + '.dvi -o ' + texfilename + '.ps'
end

if ( keyword_set ( WEB ) ) then $
   spawn, 'latex2html -auto_navigation -index_in_navigation ' + texfilename + '.tex'


end
