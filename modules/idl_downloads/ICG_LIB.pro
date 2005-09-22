
;
; Copyright (c) 1999, Forschungszentrum Juelich GmbH ICG-1
; All rights reserved.
; Unauthorized reproduction prohibited.
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.
;
;+
; NAME:
;	call_help
;
; PURPOSE:
;	The result of this function is the text below CALLING SEQUENCE from a called routine
;
; CATEGORY:
;   CASE_TOOLS
;
; CALLING SEQUENCE:
;   result=call_help()
;
; EXAMPLE:
;   message,call_help(),/info
;
; MODIFICATION HISTORY:
; 	Written by	R.Bauer (ICG-1), 1999-Nov-06
;   1999-Nov-06 help added
;
;-

FUNCTION call_help
   HELP,call=call

   IF N_ELEMENTS(call) GT 2 THEN $
   file=(STR_SEP((STR_SEP(call[1],'<'))[1],'('))[0] $
   ELSE $
   file=(STR_SEP((STR_SEP(call[0],'<'))[1],'('))[0]

   RETURN,get_template_one_value(file,'CALLING SEQUENCE:')
END


;
; Copyright (c) 1997, Forschungszentrum Juelich GmbH ICG-1
; All rights reserved.
; Unauthorized reproduction prohibited.
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.
;
;+
; NAME:
;	get_dir
;
; PURPOSE:
;   This function finds all subdirectories of a given path
;
; CATEGORY:
;   DATAFILES/FILE
;
; CALLING SEQUENCE:
;   Result=get_dir([path],[/all],[/sort])
;
; OPTIONAL INPUTS:
;	path: The start path where get_dir should look for subdirectories
;
; KEYWORD PARAMETERS:
;	all:  in addition to the normal subdirectories the entries . and ..
;   sort: sorts the output
;
; OUTPUTS:
;	The result of this function is a string array of subdirectories
;
; EXAMPLE:
;   Result=get_dir('/usr/local')
;   or
;   Result=get_dir('\windows')
;
; MODIFICATION HISTORY:
; 	Written by:	R.Bauer (ICG-1), May 1997
;   1999-Nov-06 help added
;   2001-Jun-14 : now for linux too
;-

FUNCTION get_dir,inpath,SORT=sort,all=all



   IF N_PARAMS() LT 1 THEN BEGIN
      MESSAGE,call_help(), /CONTINUE
      RETURN,''
   ENDIF

   IF N_ELEMENTS(inpath) GT 0 THEN BEGIN
      CD,current=oldpath        ; alten path saven
      CD,inpath
   ENDIF

   IF STRUPCASE(!version.os) EQ 'WIN32' OR STRUPCASE(!version.os) EQ 'WIN' THEN delim = '*.*' ELSE delim='-Fd *'
   alle_ein=FINDFILE(delim)


   IF N_ELEMENTS(inpath) GT 0 THEN CD,oldpath ; alten path restoren

   IF STRUPCASE(!version.os_family) EQ 'UNIX' THEN delim = '/' ELSE delim = '\'

   IF STRUPCASE(!version.os_family) EQ 'UNIX' THEN alle_ein = ['./','../',alle_ein]


   subs=WHERE(STRPOS(alle_ein,delim) GE 0,count)

   IF count GT 0 THEN BEGIN
      nur_subdirs=alle_ein(subs)

      n_Anz=N_ELEMENTS(nur_subdirs)-1

      FOR i=0,n_anz DO BEGIN
         nur_subdirs(i)=replace_String(nur_subdirs(i),delim,'')
      ENDFOR



      IF KEYWORD_SET(SORT) THEN $
      nur_subdirs=nur_subdirs(SORT(nur_subdirs))

      IF KEYWORD_SET(all) THEN RETURN, nur_subdirs

      IF n_anz GE  2 THEN nur_subdirs=nur_subdirs(2:n_anz) ELSE nur_subdirs=''

      RETURN,nur_subdirs
   ENDIF

   IF count EQ -1 THEN RETURN,''

END

; Copyright (c) 1998, Forschungszentrum Juelich GmbH ICG-3
; All rights reserved.
; Unauthorized reproduction prohibited.
;
;+
; NAME:
;   resolve_file_path
;
; PURPOSE:
;   This function will expand completely any relative path/file
;
; CATEGORY:
;   PROG_TOOLS
;
; CALLING SEQUENCE:
;   resolve_file_path,file
;
; KEYWORD PARAMETERS:
;   Keywords:
;      start_dir: current directory befor start of the function
;      path     : full path of file
;      file_name: filename without path
;
; OUTPUTS:
;   result: completely expanded filename including path
;
; EXAMPLE:
;   file=resolve_file_path('..\daten\test.pro',start_dir=start_dir,path=path,file_name=file_name)
;   will give file     :'d:/daten/test.pro'
;             start_dir:'d:/temp'
;             path     :'d:/daten'
;             filename :'test.pro'
;
; MODIFICATION HISTORY:
;   Written by Franz Rohrer Aug 1998
;   Modified
;-

function resolve_file_path,file,start_dir=start_dir,path=path,file_name=file_name

file_new=file
if strmid(file,0,2) eq '\\' then begin
   doublebackslash='\\'
   file_new=strmid(file_new,2,5000)
endif  else doublebackslash=''

cd,current=start_dir
start_dir =repl_character(start_dir)
file_new  =repl_character(file_new)
temp      =reverse_string(file_new)
pos=strpos(temp,'/')
if pos ge 0 then begin
   file_path=reverse_string(strmid(temp,pos,5000))
   file_name=reverse_string(strmid(temp,0    ,pos) )
endif else begin
   file_path=''
   file_name=reverse_string(temp)
endelse

if file_path ne '' then begin
   file_path=doublebackslash+file_path
   cd,file_path
endif
cd,current=path
cd,start_dir

;result=path+'/'+file_name
result=combine_path_file(path,file_name)
return,result
end


; Copyright (c) 1998, Forschungszentrum Juelich GmbH ICG
;   All rights reserved.
;   Unauthorized reproduction prohibited.
;+
; NAME:
;   REPL_CHARACTER
;
; PURPOSE:
;   this function replaces in a given string a single character to a new single character
;   ( default: backslash to slash )
;
; CATEGORY:
;   DATAFILES/ZCHN
;
; CALLING SEQUENCE:
;   Result = REPL_CHARACTER(string)
;
; INPUTS:
;   string: string variable or string array
;
; KEYWORD PARAMETERS:
;   OLDSIGN: the sign which should be replaced in string (default= '\')
;   NEWSIGN: the new sign  (default='/')
;   LASTSIGN:the sign which should be the last sign
;
; OUTPUTS:
;   string with replaced signs (default: path with slash)
;
; EXAMPLE:
;   path=repl_character('\home3\ich388\IDL\')
;
; MODIFICATION HISTORY:
;   Written by:      Marsy Lisken  august 1998
;-
FUNCTION repl_character, string, OLDSIGN=oldsign, NEWSIGN=newsign, LASTSIGN=lastsign

IF N_ELEMENTS(oldsign) EQ 0 THEN oldsign='\'
IF N_ELEMENTS(newsign) EQ 0 THEN newsign='/'

oldsign=BYTE(oldsign)
newsign=BYTE(newsign)
nd=N_ELEMENTS(string)
FOR i=0,nd-1 DO BEGIN
  bstring=BYTE(string[i])
  xxx=WHERE(bstring EQ oldsign[0],cnt)
  IF cnt GT 0 THEN bstring[xxx] = newsign[0]
  string[i]=STRING(bstring)

ENDFOR
IF N_ELEMENTS(lastsign) NE 0 THEN BEGIN
   b=STRMID(REVERSE_STRING(string),0,1)
   notsl=WHERE(b NE lastsign, cnt)
   IF cnt GT 0 THEN string[notsl]=string[notsl]+lastsign
ENDIF
RETURN,string
END


; Copyright (c) 1998, Theo Brauers, Forschungszentrum Juelich GmbH ICG-3
; All rights reserved. Unauthorized reproduction prohibited.
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever. Email bug reports to th.brauers@fz-juelich.de
;
;+
; NAME:
;   reverse_string
;
; PURPOSE:
;   This function returns the string reversed
;
; CATEGORY:
;   PROG_TOOLS/STRINGS
;
; CALLING SEQUENCE:
;   Result = REVERSE_STRING(String)
;
; INPUTS:
;   String:  Input string or string array
;
; OUTPUTS:
;   This function returns the reversed string
;
; EXAMPLE:
;   str=['{t}est[123]=5', 'test{[123456]}={1}']
;   print, transpose(reverse_string(str))
;   IDL prints:
;       5=]321[tse}t{
;       }1{=}]654321[{tset
;
; MODIFICATION HISTORY:
;   Written by: Theo Brauers, 1998-JAN-14
;-
FUNCTION reverse_string, str

size_str=SIZE(str)
IF size_str[0] LE 0 THEN RETURN, STRING( REVERSE( BYTE(str)))

s2 = MAKE_ARRAY(SIZE=size_str)
FOR i=0L, N_ELEMENTS(str)-1 DO s2[i]=STRING(REVERSE(BYTE(str[i])))

RETURN, s2
END


; Copyright (c) 1998, Forschungszentrum Juelich GmbH ICG-3
; All rights reserved.
; Unauthorized reproduction prohibited.
;
;+
; USERLEVEL:
;   TOPLEVEL
;
; NAME:
;   combine_path_file
;
; PURPOSE:
;   This function will combine path and file, change '\' to '/' and add '/' to the path if necessaray
;
; CATEGORY:
;   PROG_TOOLS/STRINGS
;
; CALLING SEQUENCE:
;   result=combine_path_file(path,file)
;
; INPUTS:
;   path,file : scalar strings
;
; OUTPUTS:
;    result: correct combination of path and file
;
; SIDE EFFECTS
;   will resolve multiple // into /
;
; EXAMPLE:
;   result=combine_path_file('d:\/temp','test.xxx')
;   will return result:'d:/temp/test.xxx'
;
;   result=combine_path_file('d:\/temp','')
;   will return result:'d:/temp/'
;
;   result=combine_path_file('','test.pro')
;   will return result: 'test.pro'
;
; MODIFICATION HISTORY:
;   Written by Franz Rohrer Aug 1998
;   Modified June 2001 : path and file are converted to scalars prior to handling
;   2002-04-13 : Syntax changed to replace_string() (saves 30 lines)
;   2002-04-24 : FR special handling of '\\' at the begin of the path reintroduced
;-
FUNCTION combine_path_file,path_in,file_in
   path=path_in[0]
   file=file_in[0]
   flag=''
   if strpos(path,'\\') eq 0 then begin
     path=strmid(path,2)
     flag='\\'
   endif
   IF STRLEN(path) GT 0 THEN  new=path+'/'+file ELSE new=file
   new=replace_string(new,'\','/')
   new=replace_string(new,'//','/')
   new=flag+new
   RETURN,new
END


;
; Copyright (c) 1998, Forschungszentrum Juelich GmbH ICG-1
; All rights reserved.
; Unauthorized reproduction prohibited.
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.
;
;+
; NAME:
;  replace_string
;
; PURPOSE:
;   This function replaces in a given string or vector of strings all values by an other. Length or only one char didn't matter.
;   It could also be used to delete a substring from a string.
;
; CATEGORY:
;   PROG_TOOLS/STRINGS
;
; CALLING SEQUENCE:
;   Result=replace_string(text,in_string,rep_string,[no_of_replaces=no_of_replaces],[pos=pos],[count=count])
;
; INPUTS:
;   text:       the text where to replace some informations
;   in_string:  the search string
;   rep_string: the string which should replace in_string
;
; KEYWORD PARAMETERS:
;   no_of_replace: if set two a number, this means in text as many times of no_of_replace in_string is reaplced by rep_string
;   pos:           if set to a number the replacement starts at this string position
;   count:         this argument returns the number of replaces
;
; OUTPUTS:
;   Result is the new text
;
; EXAMPLE:
;   help,replace_string('Dies ist ein Test',' ','_')
;   <Expression>    STRING    = 'Dies_ist_ein_Test'
;   help,replace_string('Dies ist ein Test',' ','_',pos=5)
;   <Expression>    STRING    = 'Dies ist_ein_Test'
;   help,replace_string('Dies ist ein Test',' ','_',pos=5,no=1)
;   <Expression>    STRING    = 'Dies ist_ein Test'
;   help,replace_string('Dies ist ein Test','ist','ist')
;   <Expression>    STRING    = 'Dies ist ein Test'
;   help,replace_string('Dies ist ein Test, ist ein','ist','ist nicht')
;   <Expression>    STRING    = 'Dies ist nicht ein Test, ist nicht ein'
;   help,replace_string('\\\\\\\\\','\','/')
;   <Expression>    STRING    = '/////////'
;   help,replace_string('["..\idl_html\idl_work_cat.htm"]','cat','cat_org')
;   <Expression>    STRING    = '["..\idl_html\idl_work_cat_org.htm"]'
;   print,replace_string(['12:33:00','12:33:00','12:33:00'],':','')
;   123300 123300 123300
;   print,replace_string(['12:33:00','12:33:00','12:33:00'],':','',pos=5)
;   12:3300 12:3300 12:3300
;   print,replace_string( 'asdf___ertz_j','__', '')
;   asdf_ertz_j
;   print,replace_string(['12:33:00','12:33:00','12:33:00'],':','',pos=5,count=c),c
;   12:3300 12:3300 12:3300
;   3
;   print,replace_string(['12:33:00','12:33:00','12:33:00'],':','',count=c),c
;   123300 123300 123300
;   6
;
;
; MODIFICATION HISTORY:
; 	Written by:	R.Bauer (ICG-1) , 1998-Sep-06
;   1998-09-26 bug removed with start_pos and a vector of strings
;   1998-09-26 special replacement include if a sign should be replaced by an other by n times
;   1999-09-07 bug removed with replacing '___' by '_'
;   1999-10-01 count added
;   2000-03-08 bug with no_of_replaces removed
;              if text is an array no_of_replaces is used for each element
;   2001-02-13 Loop in LONG
;-


FUNCTION replace_string,text,in_string,rep_string,pos=pos,no_of_replaces=no_of_replaces,count=count_n_replace

   IF N_PARAMS() LT 3 THEN BEGIN

      MESSAGE,call_help(),/cont
      RETURN,''
   ENDIF
   counter=0
   count_n_replace=0

   IF N_ELEMENTS(no_of_replaces) GT 0 THEN number=no_of_replaces ELSE number=1E+30

   length_in_string=STRLEN(in_string)
   length_rep_string=STRLEN(rep_string)

; Sonderfall, wenn genau 1 Zeichen der Lanege 1 durch 1 anderes Zeichen der Laenge 1 und n mal ersetzt werden soll
; Dieses Verfahren ist einfach schneller
   IF length_rep_string NE 0 THEN BEGIN
      IF length_in_string + length_rep_string EQ 2 AND number EQ 1E+30 THEN BEGIN
         new_text=BYTE(text)
         IF N_ELEMENTS(pos) EQ 0 THEN BEGIN
            change=WHERE(new_text EQ ((BYTE(in_string))[0]),count_change)
            IF count_change GT 0 THEN new_text[change]=(BYTE(rep_string))[0]
            ENDIF ELSE BEGIN
            change=WHERE(new_text[pos:*] EQ ((BYTE(in_string))[0]),count_change)
            IF count_change GT 0 THEN new_text[pos+change]=(BYTE(rep_string))[0]
         ENDELSE
         count_n_replace=count_change
         RETURN,STRING(new_text)
      ENDIF
   ENDIF

; alle anderen Faelle werden so behandelt
   IF N_ELEMENTS(pos) EQ 0 THEN start_pos=0 ELSE start_pos=pos

   n_text=N_ELEMENTS(text)-1

   FOR i=0L,n_text DO BEGIN
   counter=0
      new_text=text[i]
      IF STRPOS(new_text,in_string) NE -1 AND in_string NE rep_string THEN  BEGIN
         pos_in_string=1
         text_length=STRLEN(new_text)
         WHILE pos_in_string NE -1 AND counter LT number DO BEGIN
            pos_in_string=STRPOS(new_text,in_string,start_pos)
            IF pos_in_string GT -1 THEN BEGIN
               count_n_replace=count_n_replace+1
               new_text=STRMID(new_text,0,pos_in_string)+rep_string+STRMID(new_text,pos_in_string+length_in_string,text_length)
               start_pos=pos_in_string+length_rep_string
            ENDIF
            counter=counter+1
         ENDWHILE
         if n_elements(result) eq 0 then result=new_text else result=[result,new_text]
         IF N_ELEMENTS(pos) EQ 0 THEN start_pos=0 ELSE start_pos=pos
         ENDIF ELSE BEGIN
         if n_elements(result) eq 0 then result=new_text else result=[result,new_text]
         IF N_ELEMENTS(pos) EQ 0 THEN start_pos=0 ELSE start_pos=pos
      ENDELSE

   ENDFOR
   RETURN,result

END

; Copyright (c) 1998, Theo Brauers, Forschungszentrum Juelich GmbH ICG-3
; All rights reserved. Unauthorized reproduction prohibited.
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever. Email bug reports to th.brauers@fz-juelich.de
;
;+
; NAME:
;   file_path_name_ext
;
; PURPOSE:
;   This function returns path, name, and extension of a file in a structure
;   (handles arrays as well)
;
; CATEGORY:
;   PROG_TOOLS/STRINGS
;
; CALLING SEQUENCE:
;   Result = FILE_PATH_NAME_EXT(string)
;
; INPUTS:
;   string:  filename with path
;
; KEYWORD PARAMETERS:
;   OUT_WINDOWS:    if set '\' instead of '/' are used on output
;
; OUTPUTS:
;   Result: structure with name, path, and ext tags
;
; EXAMPLE:
;   file='d:\alpha\beta\filen.ext
;   f=file_path_name_ext(file)
;   print, f.path, f.name, f.ext
;
; REVISION HISTORY:
;   Written             Theo Brauers, Nov 1997
;   Modified            T.B. 2000-Sep-11
;                       disregard '\\' at first position of string when
;                       changing from '\' to '/'
; 2001-07-04 : rstrpos is obsolete so i changed it to strpos(/reverse_search)
;-
FUNCTION FILE_PATH_NAME_EXT, strng, OUT_WINDOWS=out_windows

fs = {PATH_NAME_EXT, path:'', name:'', ext:''}
nf = N_ELEMENTS(strng)

; do array input
IF nf GT 1 THEN BEGIN
    fn = REPLICATE(fs, nf)
    FOR i=0L, nf-1 DO fn[i]=file_path_name_ext(strng[i], OUT_W=out_windows)
    RETURN, fn
ENDIF

IF nf NE 1 THEN BEGIN
    MESSAGE, 'input string required', /INFORMATION
    RETURN, fs
ENDIF

st2 = strng[0]
sl = '/'
IF STRPOS(st2, '\\') EQ 0 THEN pos=2 ELSE pos=0
st2 = replace_string(st2, '\', '/', POS=pos)

IF STRPOS(st2,sl) NE -1 THEN BEGIN
    pos = strpos(st2, sl,/reverse_search)
    fs.path = STRMID(st2, 0, pos+1)
    fs.name = STRMID(st2, pos+1, 256)
ENDIF ELSE fs.name = st2

st2 = fs.name
IF STRPOS(st2,'.') NE -1 THEN BEGIN
    pos = strpos(st2, '.',/reverse_search)
    fs.name = STRMID(st2, 0, pos)
    fs.ext  = STRMID(st2, pos, 256)
ENDIF

IF KEYWORD_SET (out_windows) THEN fs.path=replace_string(fs.path, '/', '\')
RETURN, fs
END
