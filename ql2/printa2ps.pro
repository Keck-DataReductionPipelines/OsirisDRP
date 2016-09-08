PRO PrintA2PS, file, NOPROMPT=noprompt, OUTDRIVE=outdrive

;+
;---------------------------------------------------------------------
; Andrew D. Cool
; Electromagnetics & Propagation Group
; Surveillance Systems Division
; Defence Science & Technology Organisation (DSTO)
; PO Box 1500, Salisbury
; South Australia 5108
;
; Phone : 061 8 8259 5740     Fax : 061 8 8259 6673
; Email  : andrew.cool@dsto.defence.gov.au
;
; http://www.rsinc.com/AppProfile/idl_es_dsto.cfm
; ---------------------------------------------------------------------
;
; NAME:
;	PrintA2PS
;
; PURPOSE:
;	Calls A2PS utility to allow colour printing of chroma-code IDL source
;   code in IDLDE on PC's.
;
; CATEGORY:
;   Utility. Macro.
;
; CALLING SEQUENCE:
;   PrintA2PS, "%F"
;
; INPUTS:
;   Name of curerntly hightlighted source code is returned in "%F".
;;
; KEYWORD PARAMETERS:
;	KEY1: /NOPROMPT
;            Suppresses dialog warning if the composed DOS command
;            is > 127 characters.
;
;	KEY2: OUTDRIVE=outdrive
;            Optional. Which drive to store temporary work files on.
;
; OUTPUTS:
;   Copy of desired source code is created as outdrive\:t.pro
;   A2PS creates PS output outdrive:\t.ps.
;   These working files are cleaned up.
;
; SIDE EFFECTS:
;   Pretty, colour prints of your IDL source code. :-)
;
; RESTRICTIONS:
;   Some effort may be required to establish the right network name
;   for the desired printer.
;
; PROCEDURE:
;   Source the Self exracting Exe A2PS-DOS.EXE from the site
;   http://ftp.darenet.dk/mirror/ftp.enst.fr/a2ps/dos-and-windows-ports/A2PS-DOS.EXE
;   and extract that into c:\a2ps\
;   Create a new macro in IDLDE called PrintA2PS.
;   Make the IDL command : PrintA2PS,"%F",[/NOPROMPT],[OUTDRIVE=outdrive]
;
; MODIFICATION HISTORY:
;
;... 27-Sept-2001  A.D. Cool      v1.00   Baseline. A2PS doesn't handle "modern"
;...                                      long Windows filenames containing spaces.
;...                                      This routine takes accepts the fully
;...                                      qualified filename of the IDL source code
;...                                      file currently being edited in IDLDE, renames
;...                                      it to T.PRO in the HD top level directory, and
;...                                      passes that name to A2PS for pretty printing.
;...                                      The IDL procedure name is passed to A2PS as
;...                                      the title, whilst the original directory spec
;...                                      is shown in the Footer on each page.
;
;... 27-Sep-2001   A.D. Cool      v1.01   Added /NOPROMPT.
;... 02-Oct-2001   A.D. Cool      v1.02   Added OUTDRIVE=outdrive to forcibly copy files
;...                                      to a particular HD, e.g. OURDRIVE='c:\'
;... 03-Oct-2001   A.D. Cool      v1.03   Added CD before spawn of A2PS so that A2PS can
;...                                      find its own files. CD back to original dir after.
;... 08-Oct-2001   A.D. Cool      v1.04   Fixed bug with no dir slashes in footer heading
;...                                      with short dir path.
;-


; Gosh, don't you just hate DOS! Most of this is kludging around DOS limitations ;-(

  ON_ERROR,0

; separate out the IDL .PRO filename from the directory hierachy
  slash = STRPOS(file,'\',/reverse_search)
  filename = STRMID(file,slash+1,50)
  short_file = STRMID(file,0,slash)


  IF Keyword_Set(outdrive) EQ 0 THEN BEGIN
    HD = STRMID(file,0,3)
    new_dir = STRMID(file,0,2)
  ENDIF ELSE BEGIN
    HD = outdrive
    new_dir = STRMID(HD,0,2)
  ENDELSE

  orig_file = file

; Remove any garbage
  cmd = 'DEL ' + HD + 't.PRO'
  spawn,/hide,cmd
  cmd = 'DEL ' + HD + 't.ps'
  spawn,/hide,cmd

; copy the IDL .PRO file to a temporary file

  cmd = 'copy  "' + file + '" ' + new_dir + '\t.pro'

  spawn,/log, cmd,result,ERR_COPY,exit=e

  IF ERR_COPY(0) NE '' THEN BEGIN
    IF KEYWORD_SET(noprompt) EQ 0 THEN BEGIN
      x=DIALOG_MESSAGE(['Error in copying file to c:\t.pro : ',$
                         ERR_COPY],/INFO)
    ENDIF
    del_cmd = 'DEL ' + new_dir + '\' + file
    SPAWN,/hide,/log,del_cmd
  ENDIF

; A2PS deletes '\' characters from the title string, so we have
; to duplicate these

  file =  STRJOIN(STRSPLIT(file, "\", /EXTRACT), "\\" )

; v1.04 Duplicate \\ in short filename too!

  short_file =  STRJOIN(STRSPLIT(short_file, "\", /EXTRACT), "\\" )

; setup A2PS cmd with double quotes to preserve spaces in filenames

; NB : Use *really* short filenames to save characters, e.g. t.pro, t.ps

; Strip off the filename from the fully qualified dir/file spec for the footer
; IF the total length of the cmd  GT 127 characters, which is the DOS limit.
  cmd2a = 'a2ps --pre=idl --pro=color --cen="' + filename +'"'
  cmd2a_len = STRLEN(cmd2a)

  cmd2c = ' ' + HD + 't.pro -o ' + HD + 't.ps'

  cmd2c_len = STRLEN(cmd2c)
  main_len = cmd2a_len + cmd2c_len + STRLEN(' --foo="') +1
  IF main_len + STRLEN(file) GT 127 THEN BEGIN
    file_spec = short_file
  ENDIF ELSE BEGIN
    file_spec = file
  ENDELSE

; Build up the A2PS DOS command incorporating footer
  cmd2 = cmd2a + ' --foo="' + file_spec + '"' + cmd2c

; Now check the length again. If GT 127 still, then we remove from the
; of the dir spec the number of excess characters required to bring the
; total line length back to 127 charcaters.
  cmd2_len = STRLEN(cmd2)
  IF cmd2_len GT 127 THEN BEGIN
    excess = cmd2_len - 127
    fs_len = STRLEN(file_spec)
    IF KEYWORD_SET(noprompt) EQ 0 THEN BEGIN
      x=DIALOG_MESSAGE(['Too many characters in directory name : ' + STRING(STRLEN(cmd2)),$
                         file_spec + ' ' + STRING(fs_len)],/INFO)
    ENDIF
    fs_start = STRMID(file_spec,0,3) + '..' ; 5 chars at start, inc dir, e.g. 'c:\..'
    fs_end_offset = excess + 5
    fs_end = STRMID(file_spec,fs_end_offset,fs_len)
    new_file_spec = fs_start + fs_end

; Now double up on dir separators , i.e. '\' -> '\\'

  temp_file =  STRJOIN(STRSPLIT(new_file_spec, "\", /EXTRACT), "\\" )

; Having doubled those bastards, we've increased the length of the filename string,
; and hence the A2PS cmd string too. Figure out how many chars we added, and
; take this off the front of the dir spec *after* the drive id string e.g. 'c:\..'
    N_Extra_chars = STRLEN(temp_file) - STRLEN(new_file_spec)

    fs_start = STRMID(temp_file,0,6)  ; 6 chars at start, inc dir, e.g. 'c:\\..'
    fs_end = STRMID(temp_file,6,STRLEN(new_file_spec))

    snip = STRMID(fs_end,0,N_Extra_chars)

; If the last of the characters in the bit to be snipped off is a '\', then
; we'll need to snip 1 more to get rid of single '\' left behind...
    IF STRMID(snip,1,1) NE '\' AND $
       STRMID(snip,2,1) EQ '\' THEN N_Extra_chars = N_Extra_chars + 1

; And at last we have a short enough, valid string for A2PS and DOS!
    new_file_spec = fs_start + STRMID(fs_end,N_Extra_chars,STRLEN(fs_end))

    cmd2 = cmd2a + ' --foo="' + new_file_spec + '"' + cmd2c

  ENDIF

; If the user has set the IDLDE Preferences to Change Directory when
; opening a file, then the O/S may be looking at another drive other
; than the drive where A2PS is installed. In this case, A2PS will fail
; as it assumes that the current drive is where its own files are to
; be found. For example, if editing a file A:\idl\my_prog.pro, then the
; system sees A:\ as the current dir, whilst A2PS is probably installed
; on C:\

; Temporarily change directory to specified OUTDRIVE, or default C:\
  CD, HD, CURRENT = orig_file_dir

; Phew! Submit the final A2PS command

  spawn,/log,cmd2,result,ERR_A2PS,exit=e

; Having Spawned, return the directory to where the file lives.
  CD, orig_file_dir

  IF N_ELEMENTS(ERR_A2PS) EQ 1 THEN BEGIN
    x=DIALOG_MESSAGE(ERR_A2PS)
    GOTO,exit
  ENDIF

  IF STRPOS(ERR_A2PS(1),'saved into the file') EQ -1 THEN BEGIN
    x=DIALOG_MESSAGE(ERR_A2PS)
    GOTO,exit
  ENDIF

; Spawn a call to the PrintFile executable

  cmd3 = 'prfile32/q/- c:\t.ps'

;... For a popup to control printer selection & settings, remove the /q/-
; cmd3 = 'prfile32  c:\t.ps'


  ENDIF

exit:

; clean up files
  cmd4 = 'DEL ' + HD + 't.PRO'
  spawn,/hide,cmd4
  cmd5 = 'DEL ' + HD + 't.ps'
  spawn,/hide,cmd5
  ;cmd6 = 'DEL ' + HD + '"' + filename + '"'
  ;spawn,/hide,cmd6


END
