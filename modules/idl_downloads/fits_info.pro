pro fits_info, filename, SILENT=silent,TEXTOUT=textout, N_ext=n_ext
;+
; NAME:
;     FITS_INFO
; PURPOSE:
;     Provide information about the contents of a FITS file
; EXPLANATION:
;     Information includes number of header records and size of data array.
;     Applies to primary header and all extensions.    Information can be 
;     printed at the terminal and/or stored in a common block
;
; CALLING SEQUENCE:
;     FITS_INFO, Filename, [ /SILENT , TEXTOUT = , N_ext = ]
;
; INPUT:
;     Filename - Scalar string giving the name of the FITS file(s)
;               Can include wildcards such as '*.fits'.   In IDL V5.5 one can
;               use the regular expressions allowed by the FILE_SEARCH()
;               function.
;
; OPTIONAL INPUT KEYWORDS:
;     /SILENT - If set, then the display of the file description on the 
;                terminal will be suppressed
;
;      TEXTOUT - specifies output device.
;               textout=1        TERMINAL using /more option
;               textout=2        TERMINAL without /more option
;               textout=3        <program>.prt
;               textout=4        laser.tmp
;               textout=5        user must open file, see TEXTOPEN
;               textout=7       append to existing <program.prt> file
;               textout = filename (default extension of .prt)
;
;               If TEXTOUT is not supplied, then !TEXTOUT is used
; OPTIONAL OUTPUT KEYWORD:
;       N_ext - Returns an integer scalar giving the number of extensions in
;               the FITS file
;
; COMMON BLOCKS
;       DESCRIPTOR =  File descriptor string of the form N_hdrrec Naxis IDL_type
;               Naxis1 Naxis2 ... Naxisn [N_hdrrec table_type Naxis
;               IDL_type Naxis1 ... Naxisn] (repeated for each extension) 
;               See the procedure RDFITS_STRUCT for an example of the
;               use of this common block
;
; EXAMPLE:
;       Display info about all FITS files of the form '*.fit' in the current
;               directory
;
;               IDL> fits_info, '*.fit'
;
;       Any time a *.fit file is found which is *not* in FITS format, an error 
;       message is displayed at the terminal and the program continues
;
; PROCEDURES USED:
;       GETTOK(), STRN(), SXPAR(), TEXTOPEN, TEXTCLOSE 
;
; SYSTEM VARIABLES:
;       The non-standard system variables !TEXTOUT and !TEXTUNIT will be  
;       created by FITS_INFO if they are not previously defined.   
;
;       DEFSYSV,'!TEXTOUT',1
;       DEFSYSV,'!TEXTUNIT',0
;
;       See TEXTOPEN.PRO for more info
; MODIFICATION HISTORY:
;       Written, K. Venkatakrishna, Hughes STX, May 1992
;       Added N_ext keyword, and table_name info, G. Reichert
;       Work on *very* large FITS files   October 92
;       More checks to recognize corrupted FITS files     February, 1993
;       Proper check for END keyword    December 1994
;       Correctly size variable length binary tables  WBL December 1994
;       EXTNAME keyword can be anywhere in extension header WBL  January 1998
;       Correctly skip past extensions with no data   WBL   April 1998
;       Converted to IDL V5.0, W. Landsman, April 1998
;       No need for !TEXTOUT if /SILENT D.Finkbeiner   February 2002
;	Define !TEXTOUT if needed.  R. Sterner, 2002 Aug 27
;-
 COMMON descriptor,fdescript
 FORWARD_FUNCTION FILE_SEARCH       ;For pre-V5.5 compatibility

 if N_params() lt 1 then begin
     print,'Syntax - FITS_INFO, filename, [/SILENT, TEXTOUT =, N_ext = ]'
     return
 endif

  defsysv,'!TEXTOUT',exists=ex                  ; Check if !TEXTOUT exists.
  if ex eq 0 then defsysv,'!TEXTOUT',1          ; If not define it.

 if !VERSION.RELEASE GE '5.5' then $
    fil = file_search( filename, COUNT = nfiles) else $
    fil = findfile( filename, COUNT = nfiles)
 if nfiles EQ 0 then message,'No files found'

 silent = keyword_set( SILENT )
 if not silent then begin 
    if not keyword_set( TEXTOUT ) then textout = !TEXTOUT    
    textopen, 'FITS_INFO', TEXTOUT=textout
 endif

 for nf = 0, nfiles-1 do begin

    file = fil[nf]

    openr, lun1, file, /GET_LUN, /BLOCK

    N_ext = -1
    fdescript = ''
    extname = ['']

   START:  
   ON_IOerror, BAD_FILE
   descript = ''
   
   point_lun, -lun1, pointlun
   test = bytarr(8)
   readu, lun1, test

   if N_ext EQ -1 then begin
        if string(test) NE 'SIMPLE  ' then goto, BAD_FILE
   endif else begin
        if string(test) NE 'XTENSION' then goto, END_OF_FILE
   endelse
   point_lun, lun1, pointlun

;                               Read the header
   hdr = bytarr(80, 36, /NOZERO)
   N_hdrblock = 1
   readu, lun1, hdr
   hd = string( hdr > 32b)
;                               Get values of BITPIX, NAXIS etc.
   bitpix = sxpar(hd, 'BITPIX', Count = N_BITPIX)
   if N_BITPIX EQ 0 then $ 
          message, 'WARNING - FITS header missing BITPIX keyword',/CON
   Naxis = sxpar( hd, 'NAXIS', Count = N_NAXIS)
   if N_NAXIS EQ 0 then message, $ 
           'WARNING - FITS header missing NAXIS keyword',/CON
   simple = sxpar( hd, 'SIMPLE')
   exten = sxpar( hd, 'XTENSION')
   Ext_type = strmid( strtrim( exten ,2), 0, 8)      ;Use only first 8 char
   gcount = sxpar( hd, 'GCOUNT') > 1
   pcount = sxpar( hd, 'PCOUNT')

   if strn(Ext_type) NE '0' then begin
        if (gcount NE 1) or (pcount NE 0) then $
             ext_type = 'VAR_' + ext_type
        descript = descript + ' ' + Ext_type
  endif

   descript = descript + ' ' + strn(Naxis)

   case BITPIX of
      8:   IDL_type = 1     ; Byte
     16:   IDL_type = 2     ; Integer*2
     32:   IDL_type = 3     ; Integer*4
    -32:   IDL_type = 4     ; Real*4 
    -64:   IDL_type = 5     ; Real*8
   ELSE: begin 
         message, ' Illegal value of BITPIX = ' + strn(bitpix) + $
         ' in header',/CON
         goto, SKIP
         end
   endcase

  if Naxis GT 0 then begin
         descript = descript + ' ' + strn(IDL_type)
         Nax = sxpar( hd, 'NAXIS*')
         if N_elements(Nax) LT Naxis then begin 
              message, $
                 'ERROR - Missing required NAXISi keyword in FITS header',/CON
                  goto, SKIP
         endif
         for i = 1, Naxis do descript = descript + ' '+strn(Nax[i-1])
  endif

  end_rec = where( strtrim(strmid(hd,0,8),2) EQ  'END')

;  Read header records, till end of header is reached

 while (end_rec[0] EQ -1) and (not eof(lun1) ) do begin
       hdr = bytarr(80, 36, /NOZERO)
       readu,lun1,hdr
       hd1 = string( hdr > 32b)
       end_rec = where( strtrim(strmid(hd1,0,8),2) EQ  'END')
       hd = [hd,hd1]
       n_hdrblock = n_hdrblock + 1
 endwhile

   isel = where( strpos(hd,'EXTNAME =') GE 0, N_extname)  ;find extension name
   if ( N_extname GE 1 ) then begin
            hdd = hd[ isel[0] ]
            dum = gettok( hdd, '=' )
            extname = [ extname, strtrim(hdd,2) ]
   endif else extname = [ extname, '' ]

 n_hdrec = 36*(n_hdrblock-1) + end_rec[0] + 1         ; size of header
 descript = strn( n_hdrec ) + descript

;  If there is data associated with primary header, then find out the size

 if Naxis GT 0 then begin
         ndata = Nax[0] 
         if naxis GT 1 then for i = 2, naxis do ndata=ndata*Nax[i-1]
 endif else ndata = 0

 nbytes = (abs(bitpix)/8) * gcount * (pcount + ndata)
 nrec = long(( nbytes +2879)/ 2880)

; Skip the headers and data records

   point_lun, -lun1, pointlun
   pointlun = pointlun + nrec*2880L
   point_lun, lun1, pointlun

; Check if all headers have been read 

 if ( simple EQ 0 ) AND ( strlen(strn(exten)) EQ 1) then goto, END_OF_FILE  

    N_ext = N_ext + 1

; Append information concerning the current extension to descriptor

    fdescript = fdescript + ' ' + descript

; Check for EOF
    if not eof(lun1) then goto, START
;
 END_OF_FILE:  
 extname = extname[1:*]            ;strip off bogus first value
                                  ;otherwise will end up with '' at end

 if not (SILENT) then begin
 printf,!textunit,file,' has ',strn(N_ext),' extensions'
 printf,!textunit,'Primary header: ',gettok(fdescript,' '),' records'

 Naxis = gettok( fdescript,' ' ) 

 If Naxis NE '0' then begin

 case gettok(fdescript,' ') of

 '1': image_type = 'Byte'
 '2': image_type = 'Integer*2'    
 '3': image_type = 'Integer*4'
 '4': image_type = 'Real*4'
 '5': image_type = 'Real*8'

 endcase

 image_desc = 'Image -- ' + image_type + ' array ('
 for i = 0,fix(Naxis)-1 do image_desc = image_desc + ' '+ gettok(fdescript,' ')
 image_desc = image_desc+' )'

 endif else image_desc = 'No data'
 printf,!textunit, format='(a)',image_desc

 if N_ext GT 0 then begin
  for i = 1,N_ext do begin

  printf, !TEXTUNIT, 'Extension ' + strn(i) + ' -- '+extname[i]

  header_desc = '               Header : '+gettok(fdescript,' ')+' records'
  printf, !textunit, format = '(a)',header_desc

  table_type = gettok(fdescript,' ')

  case table_type of
   'A3DTABLE' : table_desc = 'Binary Table'
   'BINTABLE' : table_desc = 'Binary Table'
   'VAR_BINTABLE': table_desc = 'Variable length Binary Table'
   'TABLE':     table_desc = 'ASCII Table'
    ELSE:       table_desc = table_type
  endcase

  table_desc = '               ' + table_desc + ' ( '
  table_dim = fix( gettok( fdescript,' ') )
  if table_dim GT 0 then begin
          table_type = gettok(fdescript,' ')
          for j = 0, table_dim-1 do $
                table_desc = table_desc + gettok(fdescript,' ') + ' '
  endif
  table_desc = table_desc + ')'

  printf,!textunit, format='(a)',table_desc
 endfor
 endif

  printf, !TEXTUNIT, ' '
  endif 
  SKIP: free_lun, lun1
  endfor
  if not silent then textclose, TEXTOUT=textout
  return

 BAD_FILE:
     message, 'Error reading FITS file ' + file, /CON
    goto,SKIP
 end
