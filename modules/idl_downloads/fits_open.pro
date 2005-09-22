pro fits_open,filename,fcb,write=write,append=append,update=update, $
                 no_abort=no_abort,message=message,hprint=hprint
;+
; NAME:
;       FITS_OPEN
;
;*PURPOSE:
;       Opens a FITS (Flexible Image Transport System) data file.
;
;*CATEGORY:
;       INPUT/OUTPUT
;
;*CALLING SEQUENCE:
;       FITS_OPEN, filename, fcb
;
;*INPUTS:
;       filename : name of the FITS file to open, scalar string
;
;*OUTPUTS:
;       fcb : (FITS Control Block) a IDL structure containing information
;               concerning the file.  It is an input to FITS_READ, FITS_WRITE
;               and FITS_CLOSE
;
; INPUT KEYWORD PARAMETERS:
;       /APPEND: Set to append to an existing file.
;       /HPRINT - print headers with routine HPRINT as they are read.
;               (useful for debugging a strange file)
;       /NO_ABORT: Set to return to calling program instead of a RETALL
;               when an I/O error is encountered.  If set, the routine will
;               return  a non-null string (containing the error message) in the
;               keyword MESSAGE.    (For backward compatibility, the obsolete 
;               system variable !ERR is also set to -1 in case of an error.)   
;               If /NO_ABORT not set, then FITS_OPEN will print the message and
;               issue a RETALL
;       /UPDATE Set this keyword to open an existing file for update
;       /WRITE: Set this keyword to open a new file for writing. 
;
; OUTPUT KEYWORD PARAMETERS:
;       MESSAGE = value: Output error message.    If the FITS file was opened
;               successfully, then message = ''.
;       
;*NOTES:
;       The output FCB should be passed to the other FITS routines (FITS_OPEN,
;       FITS_READ, FITS_HELP, and FITS_WRITE).  It has the following structure
;       when FITS_OPEN is called without /WRITE or /APPEND keywords set.
;
;           FCB.FILENAME - name of the input file
;               .UNIT - unit number the file is opened to
;               .NEXTEND - number of extensions in the file.
;               .XTENSION - string array giving the extension type for each
;                       extension.
;               .EXTNAME - string array giving the extension name for each
;                       extension. (null string if not defined the extension)
;               .EXTVER - vector of extension version numbers (0 if not
;                       defined)
;               .EXTLEVEL - vector of extension levels (0 if not defined)
;               .GCOUNT - vector with the number of groups in each extension.
;               .PCOUNT - vector with parameter count for each group
;               .BITPIX - BITPIX for each extension with values
;                                  8    byte data
;                                16     short word integers
;                                32     long word integers
;                               -32     IEEE floating point
;                               -64     IEEE double precision floating point
;               .NAXIS - number of axes for each extension.  (0 for null data
;                       units)
;               .AXIS - 2-D array where axis(*,N) gives the size of each axes
;                       for extension N
;               .START_HEADER - vector giving the starting byte in the file
;                               where each extension header begins
;               .START_DATA - vector giving the starting byte in the file
;                               where the data for each extension begins
;
;               .HMAIN - keyword parameters (less standard required FITS
;                               keywords) for the primary data unit.
;               .OPEN_FOR_WRITE - flag (0= open for read, 1=open for write, 
;                                                2=open for update)
;               .LAST_EXTENSION - last extension number read.
;               .RANDOM_GROUPS - 1 if the PDU is random groups format,
;                               0 otherwise
;
;       When FITS open is called with the /WRITE or /APPEND option, FCB
;       contains:
;
;           FCB.FILENAME - name of the input file
;               .UNIT - unit number the file is opened to
;               .NEXTEND - number of extensions in the file.
;               .OPEN_FOR_WRITE - flag (1=open for write, 2=open for append
;                                       3=open for update)
;
;
;*EXAMPLES:
;       Open a FITS file for reading:
;               FITS_OPEN,'myfile.fits',fcb
;
;       Open a new FITS file for output:
;               FITS_OPEN,'newfile.fits',fcb,/write
; PROCEDURES USED:
;       HPRINT, SXDELPAR, SXPAR()
;*HISTORY:
;       Written by:     D. Lindler      August, 1995
;       July, 1996      NICMOS  Modified to allow open for overwrite
;                               to allow primary header to be modified
;       DJL Oct. 15, 1996   corrected to properly extend AXIS when more
;                       than 100 extensions present
;       Converted to IDL V5.0   W. Landsman   September 1997
;       Use Message = '' rather than !ERR =1 as preferred signal of normal
;           operation   W. Landsman  November 2000
;     	Lindler, Dec, 2001, Modified to use 64 bit words for storing byte
;             positions within the file to allow support for very large
;             files 
;-
;--------------------------------------------------------------------
;
; if no parameters supplied, print calling sequence
;
       if N_params() LT 1 then begin
          print,'Syntax - FITS_OPEN, filename, fcb'
          print,' Input Keywords:  /Append, /Hprint, /No_abort, /Update, /Write'
          print,' Output Keyword:  Message= '
          return
       endif
;
; set default keyword parameters
;
        message = ''
        open_for_read = 1
        open_for_update = 0
        open_for_write = 0
        open_for_overwrite = 0
        if keyword_set(write) then begin
                open_for_read = 0
                open_for_update = 0
                open_for_write = 1
                open_for_overwrite = 0
        end
        if keyword_set(append) then begin
                open_for_read = 0
                open_for_write = 0
                open_for_update = 1
                open_for_overwrite = 0
        end     
        if keyword_set(update) then begin
                open_for_read = 1 
                open_for_write = 0
                open_for_update = 0 
                open_for_overwrite = 1 
        end     
;
; on I/O errors goto statement ioerror:
;
        on_ioerror,ioerror
;
; open file
;
        get_lun,unit
        case 1 of
                keyword_set(append): openu,unit,filename,/block
                keyword_set(update): openu,unit,filename,/block
                keyword_set(write) : if !version.os eq 'vms' then $
                                         openw,unit,filename,/block,/none,2880 $
                                     else openw,unit,filename
                else               : openr,unit,filename,/block
        endcase

        file = fstat(unit)
        nbytes_in_file = file.size
;
; create vectors needed to store header information for each extension
;
        n = 100
        xtension = strarr(n)
        extname = strarr(n)
        extver = lonarr(n)
        extlevel = lonarr(n)
        gcount = lonarr(n)
        pcount = lonarr(n)
        bitpix = lonarr(n)
        naxis  = lonarr(n)
        axis = lonarr(20,n)
        if !VERSION.RELEASE GE '5.2' then begin
          start_header = lon64arr(n)        ; starting byte in file for header
          start_data = lon64arr(n)          ; starting byte in file for data
          position = long64(0)             ; current byte position in file
        endif else begin
          start_header = lonarr(n)
          start_data = lonarr(n)
          position = 0L
       endelse 
;
; read and process each header in the file if open for read or update
;
        extend_number = 0               ; current extension number being
                                        ; processed
 
        if open_for_read or open_for_update then begin
            main_header = 1             ; first header in file flag
            h = bytarr(80,36,/nozero)   ; read buffer
;
; loop on headers in the file
;
            repeat begin
            point_lun,unit,position
            start = position
;
; loop on header blocks
;
                first_block = 1         ; first block in header flag
                repeat begin

                    if position+2879 ge nbytes_in_file then begin
                        if extend_number eq 0 then begin
                                message = 'EOF encountered while reading header'
                                goto,error_exit
                        endif
                        print,'EOF encountered reading extension header'
                        print,'Only '+strtrim(extend_number-1,2) + $
                                ' extensions processed'
                        goto,done_headers
                    endif

                    readu,unit,h
                    position = position + 2880
                    hdr = string(h>32b)
                    endline = where(strmid(hdr,0,8) eq 'END     ',nend)
                    if nend gt 0 then hdr = hdr[0:endline[0]]
                    if first_block then begin
;
; check for valid header (SIMPLE keyword must be first for PDU and
; XTENSION keyword for the extensions.
;
                        header = hdr 
                        keyword = strmid(header[0],0,8)
                        if (extend_number eq 0) and $
                           (keyword ne 'SIMPLE  ') then begin
                                message = 'Invalid header, no SIMPLE keyword'
                                goto,error_exit
                        endif

                        if (extend_number gt 0) and $
                           (keyword ne 'XTENSION') then begin
                                print,'Invalid extension header encountered'
                                print,'XTENSION keyword missing'
                                print,'Only '+strtrim(extend_number-1,2) + $
                                        ' extensions processed'
                                goto,done_headers
                        endif

                    end else header = [header,hdr]

                    first_block = 0
                end until (nend gt 0)   
;
; print header if hprint set
;
                if keyword_set(hprint) then hprint,header
;
; end of loop on header blocks
;
; Increase size of vectors if needed
;
                if extend_number ge n then begin
                        xtension = [xtension,strarr(n)]
                        extname = [extname,strarr(n)]
                        extver = [extver,lonarr(n)]
                        extlevel = [extver,lonarr(n)]
                        gcount = [gcount,lonarr(n)]
                        pcount = [pcount,lonarr(n)]
                        bitpix = [bitpix,lonarr(n)]
                        naxis  = [naxis,lonarr(n)]
                        old_axis = axis
                        axis = lonarr(20,n*2)
                        axis[0,0] = old_axis
                        start_header = [start_header,lonarr(n)]
                        start_data = [start_data,lonarr(n)]
                        n = n*2
                end
;
; extract information from header
;
                xtension[extend_number] = strtrim(sxpar(header,'xtension'))
                st = sxpar(header,'extname', Count = N_extname)
                if N_extname EQ 0 then st = ''
                extname[extend_number] = strtrim(st,2)  
                extver[extend_number] = sxpar(header,'extver')          
                extlevel[extend_number] = sxpar(header,'extlevel')              
                gcount[extend_number] = sxpar(header,'gcount')
                pcount[extend_number] = sxpar(header,'pcount')
                bitpix[extend_number] = sxpar(header,'bitpix')
                nax = sxpar(header,'naxis')
                naxis[extend_number] = nax
                if nax gt 0 then for i=1,nax do $
                    axis[i-1,extend_number] = sxpar(header,'naxis'+strtrim(i,2))
                start_data[extend_number] = position    
                start_header[extend_number] = start
;
; if first header, save without FITS required keywords
;
                if extend_number eq 0 then begin
                    hmain = header
                    random_groups = sxpar(header,'groups')
                    sxdelpar,hmain,['SIMPLE','BITPIX','NAXIS','NAXIS1', $
                                    'NAXIS2','NAXIS3','NAXIS4','NAXIS5', $
                                    'NAXIS6','NAXIS7','NAXIS8','EXTEND', $
                                    'PCOUNT','GCOUNT','GROUPS','BSCALE', $
                                    'BZERO','NPIX1','NPIX2','PIXVALUE']
                        if (pcount[0] gt 0) then for i=1,pcount[0] do $
                        sxdelpar,hmain,['ptype','pscal','pzero']+strtrim(i,2)
                endif
;
; skip past data to go to next header
;
                ndata = axis[0,extend_number]
                if naxis[extend_number] gt 1 then $
                                for i=2,naxis[extend_number] do $
                                    ndata = ndata*axis[i-1,extend_number]
                nbytes = (abs(bitpix[extend_number])/8) * $
                       (gcount[extend_number]>1)*(pcount[extend_number] + ndata)
                position = position + (nbytes + 2879)/2880 * 2880
;
; end loop on headers
;           
                extend_number = extend_number + 1
            end until (position ge nbytes_in_file-2879)
        end
;
; point at end of file in /extend
;
done_headers:
        if open_for_update then point_lun,unit,nbytes_in_file
;
; number of extensions
;
        if open_for_write then nextend = -1 $
                          else nextend = extend_number - 1
;
; set up blank hmain if open for write
;
        if open_for_write then begin
                hmain = strarr(1)
                hmain[0] = 'END     '
        end
;
; create output structure for the file control block
;
        if open_for_write or open_for_update then begin
                fcb = {filename:filename,unit:unit,nextend:nextend, $
                        open_for_write:open_for_write + open_for_update*2}
           end else begin
                nx = nextend
                fcb = {filename:filename,unit:unit,nextend:nextend, $
                        xtension:xtension[0:nx],extname:extname[0:nx], $
                        extver:extver[0:nx],extlevel:extlevel[0:nx], $
                        gcount:gcount[0:nx],pcount:pcount[0:nx], $
                        bitpix:bitpix[0:nx],naxis:naxis[0:nx], $
                        axis:axis[*,0:nx], $
                        start_header:start_header[0:nx], $
                        start_data:start_data[0:nx],hmain:hmain, $
                        open_for_write:open_for_overwrite*3,$
                        last_extension:-1, $
                        random_groups:random_groups}
        end
        !err = 1
        return
;
; error exit
;
ioerror: 
        message = !err_string
error_exit:
        free_lun,unit
        !err = -1
        if keyword_set(no_abort) then return
        print,'FITS_OPEN ERROR: '+message
        retall
end

