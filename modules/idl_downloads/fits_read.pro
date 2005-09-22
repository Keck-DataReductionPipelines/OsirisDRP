pro fits_read,file_or_fcb,data,header,group_par,noscale=noscale, $
                NaNvalue=NaNvalue, exten_no=exten_no, extname=extname, $
                extver=extver, extlevel=extlevel, xtension=xtension, $
                no_abort=no_abort, message=message, first=first, last=last, $
                group=group, header_only=header_only,data_only=data_only, $
                no_pdu=no_pdu, enum = enum, no_unsigned = no_unsigned

;+
; NAME:
;       FITS_READ
;*PURPOSE:
;       To read a FITS file.
;
;*CATEGORY:
;       INPUT/OUTPUT
;
;*CALLING SEQUENCE:
;       FITS_READ, filename_or_fcb, data [,header, group_par]
;
;*INPUTS:
;       FILENAME_OR_FCB - this parameter can be the FITS Control Block (FCB)
;               returned by FITS_OPEN or the file name of the FITS file.  If
;               a file name is supplied, FITS_READ will open the file with
;               FITS_OPEN and close the file with FITS_CLOSE before exiting.
;               When multiple extensions are to be read from the file, it is
;               more efficient for the user to call FITS_OPEN and leave the
;               file open until all extensions are read.
;
;*OUTPUTS:
;       DATA - data array.  If /NOSCALE is specified, BSCALE and BZERO
;               (if present in the header) will not be used to scale the data.
;               If Keywords FIRST and LAST are used to read a portion of the
;               data or the heap portion of an extension, no scaling is done
;               and data is returned as a 1-D vector. The user can use the IDL
;               function REFORM to convert the data to the correct dimensions
;               if desired.  If /DATA_ONLY is specified, no scaling is done.
;       HEADER - FITS Header.  If an extension is read, and the /NO_PDU keyword
;               parameter is not supplied, the primary data unit header
;               and the extension header will be combined.  The header will have
;               the form:
;
;                       <required keywords for the extension: XTENSION, BITPIX,
;                               NAXIS, ...>
;                       BEGIN MAIN HEADER --------------------------------
;                       <PDU header keyword and history less required keywords:
;                               SIMPLE, BITPIX, NAXIS, ...>
;                       BEGIN EXTENSION HEADER ---------------------------
;                       <extension header less required keywords that were
;                               placed at the beginning of the header.
;                       END
;               
;               The structure of the header is such that if a keyword is
;               duplicated in both the PDU and extension headers, routine
;               SXPAR will print a warning and return the extension value of
;               the keyword. SXADDPAR and SXADDHIST will add new keywords and
;               history to the extension portion of the header unless the
;               parameter /PDU is supplied in the calling sequence.
;
;       GROUP_PAR - Group parameter block for FITS random groups format files
;               Any scale factors in the header (PSCALn and PZEROn) are not
;               applied to the group parameters.
;
;*INPUT KEYWORD PARAMETERS:
;
;       /NOSCALE: Set to return the FITS data without applying the scale
;               factors BZERO and BSCALE.
;       /HEADER_ONLY: set to read the header only.
;       /DATA_ONLY: set to read the data only.  If set, if any scale factors
;               are present (BSCALE or BZERO), they will not be applied.
;       /NO_PDU: Set to not add the primary data unit header keywords to the
;               output header.
;       /NO_ABORT: Set to return to calling program instead of a RETALL
;               when an I/O error is encountered.  If set, the routine will
;               return  a non-null string (containing the error message) in the
;               keyword MESSAGE.    (For backward compatibility, the obsolete 
;               system variable !ERR is also set to -1 in case of an error.)   
;               If /NO_ABORT not set, then FITS_READ will print the message and
;               issue a RETALL
;       /NO_UNSIGNED - By default, if the IDL Version is 5.2 or greater, and the
;               header indicates an unsigned integer (BITPIX = 16, BZERO=2^15,
;               BSCALE=1) then FITS_READ will output an IDL unsigned integer 
;               data type (UINT).   But if /NO_UNSIGNED is set, or the IDL 
;               version is before 5.2, then the data is converted to type LONG.  
;       EXTEN_NO - extension number to read.  If not set, the next extension
;               in the file is read.  Set to 0 to read the primary data unit.
;       XTENSION - string name of the xtension to read
;       EXTNAME - string name of the extname to read
;       EXTVER - integer version number to read
;       EXTLEVEL - integer extension level to read
;       FIRST - set this keyword to only read a portion of the data.  It gives
;               the first word of the data to read
;       LAST - set this keyword to only read a portion of the data.  It gives
;               the last word number of the data to read
;       GROUP - group number to read for GCOUNT>1.  (Default=0, the first group)
;       NaNvalue - On non-IEEE floating point machines, it gives the value
;               to place into words with IEEE NaN.
;       
;*OUTPUT KEYWORD PARAMETERS:
;       ENUM - Output extension number that was read.  
;       MESSAGE = value: Output error message
;
;*NOTES:
;       Determination or which extension to read.
;               case 1: EXTEN_NO specified. EXTEN_NO will give the number of the
;                       extension to read.  The primary data unit is refered
;                       to as extension 0. If EXTEN_NO is specified, XTENSION,
;                       EXTNAME, EXTVER, and EXTLEVEL parameters are ignored.
;               case 2: if EXTEN_NO is not specified, the first extension
;                       with the specified XTENSION, EXTNAME, EXTVER, and
;                       EXTLEVEL will be read.  If any of the 4 parameters
;                       are not specified, they will not be used in the search.
;                       Setting EXTLEVEL=0, EXTVER=0, EXTNAME='', or
;                       XTENSION='' is the same as not supplying them.
;               case 3: if none of the keyword parameters, EXTEN_NO, XTENSION,
;                       EXTNAME, EXTVER, or EXTLEVEL are supplied.  FITS_READ
;                       will read the next extension in the file.  If the
;                       primary data unit (PDU), extension 0, is null, the
;                       first call to FITS_READ will read the first extension
;                       of the file.
;
;               The only way to read a null PDU is to use EXTEN_NO = 0.
;
;       If FIRST and LAST are specified, the data is returned without applying
;       any scale factors (BSCALE and BZERO) and the data is returned in a
;       1-D vector.  This will allow you to read any portion of a multiple
;       dimension data set.  Once returned, the IDL function REFORM can be
;       used to place the correct dimensions on the data.
;
;       IMPLICIT IMAGES: FITS_READ will construct an implicit image
;               for cases where NAXIS=0 and the NPIX1, NPIX2, and PIXVALUE
;               keywords are present.  The output image will be:
;                       image = replicate(PIXVALUE,NPIX1,NPIX2)
;
;*EXAMPLES:
;       Read the primary data unit of a FITS file, if it is null read the
;       first extension:
;               FITS_READ, 'myfile.fits', data, header
;
;       Read the first two extensions of a FITS file and the extension with
;       EXTNAME = 'FLUX' and EXTVER = 4
;               FITS_OPEN, 'myfile.fits', fcb
;               FITS_READ, fcb,data1, header2, exten_no = 1
;               FITS_READ, fcb,data1, header2, exten_no = 2
;               FITS_READ, fcb,data3, header3, extname='flux', extver=4
;               FITS_CLOSE, fcb
;       
;       Read the sixth image in a data cube for the fourth extension.
;
;               FITS_OPEN, 'myfile.fits', fcb
;               image_number = 6
;               ns = fcb.axis(0,4)
;               nl = fcb.axis(1,4)
;               i1 = (ns*nl)*(image_number-1)
;               i2 = i2 + ns*nl-1
;               FITS_READ,fcb,image,header,first=i1,last=i2
;               image = reform(image,ns,nl,/overwrite)
;               FITS_CLOSE
;
;*PROCEDURES USED:
;       FITS_CLOSE, FITS_OPEN, IEEE_TO_HOST, IS_IEEE_BIG() 
;       SXADDPAR, SXDELPAR, SXPAR(), WHERENAN()
;*HISTORY:
;       Written by:     D. Lindler, August 1995
;       Converted to IDL V5.0   W. Landsman   September 1997
;       Avoid use of !ERR       W. Landsman   August 1999
;       Read unsigned datatypes, added /no_unsigned   W. Landsman December 1999
;       Don't call FITS_CLOSE unless fcb is defined   W. Landsman January 2000
;       Set BZERO = 0 for unsigned integer data   W. Landsman  January 2000
;       Only call IEEE_TO_HOST if needed          W. Landsman February 2000
;       Ensure EXTEND keyword in primary header   W. Landsman April 2001
;       Don't erase ERROR message when closing file  W. Landsman April 2002
;-
;
;-----------------------------------------------------------------------------
;
; print calling sequence
;
        if N_params() eq 0 then begin
          print,'Syntax - FITS_READ,file_or_fcb,data,header,group_par'
          print,' Input Keywords: /noscale, NaNvalue=, exten_no=, extname=, '
          print,'                 extver=, extlevel=, xtension=, /no_abort, '
          print,'                 first, last, group, /header_only, /no_pdu'
          print,' Output Keywords: enum =, message='
          return
        endif
;
; I/O error processing
;
        on_ioerror,ioerror
;
; set defaults
;
        message = ''
        if n_elements(noscale) eq 0 then noscale = 0
        if n_elements(exten_no) eq 0 then exten_no = -1
        if n_elements(extname) eq 0 then extname = ''
        if n_elements(extver) eq 0 then extver = 0
        if n_elements(extlevel) eq 0 then extlevel = 0
        if n_elements(first) eq 0 then first = 0
        if n_elements(last) eq 0 then last = 0
        if n_elements(no_abort) eq 0 then no_abort = 0
        if n_elements(group) eq 0 then group = 0
        if n_elements(header_only) eq 0 then header_only = 0
        if n_elements(data_only) eq 0 then data_only = 0
        if n_elements(no_pdu) eq 0 then no_pdu = 0
        if n_elements(xtension) eq 0 then xtension = ''
        bswap = 1 - is_ieee_big()          ;Need to byte swap
;
; Open file if file name is supplied
;
        s = size(file_or_fcb) & fcbtype = s[s[0]+1]
        fcbsize = n_elements(file_or_fcb)
        if (fcbsize ne 1) or ((fcbtype ne 7) and (fcbtype ne 8)) then begin
                message = 'Invalid Filename or FCB supplied'
                goto,error_exit
        end

        if fcbtype eq 7 then begin
                fits_open,file_or_fcb,fcb,no_abort=no_abort,message=message
                if message NE '' then goto,error_exit
           end else fcb = file_or_fcb
;
; determine which extension to read ==========================================
;
; case 1: exten_no specified
;

        enum = exten_no
        if exten_no le -1 then begin
;
; case 2: extname, extver, or extlevel specified
;
           if (extname ne '') or (extlevel ne 0) or (extver ne 0) or $
              (xtension ne '') then begin
;
; find extensions with supplied extname, extver, extlevel, and xtension
;
                good = replicate(1b,fcb.nextend+1)
                if extname ne '' then good = good and $
                         (strtrim(strupcase(extname)) eq strupcase(fcb.extname))
                if xtension ne '' then good = good and $
                       (strtrim(strupcase(xtension)) eq strupcase(fcb.xtension))
                if extver ne 0 then good = good and (extver eq fcb.extver)
                if extlevel ne 0 then good = good and (extlevel eq fcb.extlevel)
                good = where(good,ngood)
;
; select first one
;
                if ngood le 0 then begin
                    message='No extension for given extname, extver, and/or' + $
                            ' extlevel found'
                    goto,error_exit
                endif
                enum = good[0]
              end else begin
;
;       case 3: read next extension
;
                enum = fcb.last_extension + 1
                if (enum eq 0) and (fcb.naxis[0] eq 0) then enum = 1
            end
        end
;
; check to see if it is a valid extension
;
        if enum gt fcb.nextend then begin
                message='EOF encountered'
                goto,error_exit
        end
;
; extract information from FCB for the extension
;
        bitpix = fcb.bitpix[enum]
        naxis = fcb.naxis[enum]
        if naxis gt 0 then axis = fcb.axis[0:naxis-1,enum]
        gcount = fcb.gcount[enum]
        pcount = fcb.pcount[enum]
        xtension = fcb.xtension[enum]
;
; read header ================================================================
;
        if data_only then goto,read_data
        h = bytarr(80,36,/nozero)
        file = fstat(fcb.unit)
        nbytes_in_file = file.size
        position = fcb.start_header[enum]
        point_lun,fcb.unit,position
        first_block = 1         ; first block in header flag
        repeat begin
             if position ge nbytes_in_file then begin
                 message = 'EOF ecountered while reading header'
                 goto,error_exit
             endif

             readu,fcb.unit,h
             position = position + 2880
             hdr = string(h>32b)
             endline = where(strmid(hdr,0,8) eq 'END     ',nend)
             if nend gt 0 then hdr = hdr[0:endline[0]]
             if first_block then header = hdr else header = [header,hdr]
             first_block = 0
        end until (nend gt 0)
;
; extract some header information
;
        bscale = sxpar(header,'bscale', Count = N_bscale)
        if (N_bscale gt 0) and (noscale eq 0) and (data_only eq 0) and $
           (last eq 0) and (header_only eq 0) then sxaddpar,header,'bscale',1.0
        if bscale eq 0.0 then bscale = 1.0
        bzero = sxpar(header,'bzero', Count = N_bzero)
        if (N_bzero gt 0) and (noscale eq 0) and (data_only eq 0) and $
           (last eq 0) and (header_only eq 0) then sxaddpar,header,'bzero',0.0
        groups = sxpar(header,'groups')
;
; delete required keywords
;
        sxdelpar,header,['SIMPLE','BITPIX','NAXIS','NAXIS1', $
                         'NAXIS2','NAXIS3','NAXIS4','NAXIS5', $
                         'NAXIS6','NAXIS7','NAXIS8','EXTEND', $
                         'PCOUNT','GCOUNT','GROUPS', $
                         'XTENSION']
;
; create header with form:
;       ! Required Keywords
;       ! BEGIN MAIN HEADER ------------------------------------------
;       ! Primary data unit header keywords
;       ! BEGIN EXTENSION HEADER -------------------------------------
;       ! Extension header keywords
;       ! END           
;
; create required keywords
;
        hreq = strarr(20)
        hreq[0] = 'END     '

        if enum eq 0 then $
                sxaddpar,hreq,'SIMPLE','T','image conforms to FITS standard' $
           else sxaddpar,hreq,'XTENSION',xtension,'extension type'

        sxaddpar,hreq,'bitpix',bitpix,'bits per data value'
        sxaddpar,hreq,'naxis',naxis,'number of axes'
        if naxis gt 0 then for i=1,naxis do $
                sxaddpar,hreq,'naxis'+strtrim(i,2),axis[i-1]
        if (enum eq 0)and (fcb.nextend GE 1) then $
                sxaddpar,hreq,'EXTEND','T','file may contain extensions'
        if groups then sxaddpar,hreq,'GROUPS','T','Group format'
        if (enum gt 0) or (pcount gt 0) then $
                     sxaddpar,hreq,'PCOUNT',pcount,'Number of group parameters'
        if (enum gt 0) or (gcount gt 0) then $
                    sxaddpar,hreq,'GCOUNT',gcount,'Number of groups'
       n0 = where(strmid(hreq,0,8) eq 'END     ') & n0=n0[0]
;
; add Primary Data Unit header to it portion of the header to it
;
        if (no_pdu eq 0) and (enum gt 0) then begin
            hpdu = fcb.hmain
            n1 = n_elements(hpdu)
            if n1 gt 1 then begin               
                hreq = [hreq[0:n0-1], $
                        'BEGIN MAIN HEADER ---------------------------------', $
                        hpdu[0:n1-2], $
                        'BEGIN EXTENSION HEADER ----------------------------', $
                        'END     ']
                n0 = n0 + n1 + 1
            end
        end
;
; add extension header
;
        header = [hreq[0:n0-1],header]
        if header_only then begin
                data = 0
                goto,done
        endif
;
; Read Data ===================================================================
;
read_data:
        if naxis eq 0 then begin        ;null image?
                data = 0
;
; check for implicit data specified by NPIX1, NPIX2, and PIXVALUE (provided
; the header was red, i.e. data_only was not specified)
;
                if data_only eq 0 then begin
                        NPIX1 = sxpar(header,'NPIX1')
                        NPIX2 = sxpar(header,'NPIX2')
                        PIXVALUE = sxpar(header,'PIXVALUE')
                        if (NPIX1*NPIX2) gt 0 then $
                                data = replicate(pixvalue,npix1,npix2)
                end
                goto,done
        endif

        case BITPIX of
           8:   IDL_type = 1          ; Byte
          16:   IDL_type = 2          ; Integer*2
          32:   IDL_type = 3          ; Integer*4
         -32:   IDL_type = 4          ; Real*4
         -64:   IDL_type = 5          ; Real*8
        else:   begin
                message = 'ERROR - Illegal value of BITPIX (= ' +  $
                               strtrim(bitpix,2) + ') in FITS header'
                goto,error_exit
                end
        endcase

        ndata = axis[0]
        bytes_per_word = (abs(bitpix)/8)
        if naxis gt 1 then $
           for i=2,naxis do ndata = ndata*axis[i-1]
        nbytes_per_group = bytes_per_word * (pcount + ndata)
        nbytes = (gcount>1) * nbytes_per_group
        nwords = nbytes / bytes_per_word
;
; starting data position
;
        position = fcb.start_data[enum]
;
; find correct group
;
        if last eq 0 then begin
                if group ge (gcount>1) then begin
                        message='INVALID group number specified'
                        goto,error_exit
                end
                position = position + group * nbytes_per_group 
        end
;
; read group parameters
;
        if (enum eq 0) and (fcb.random_groups eq 1) and (pcount gt 0) and $
           (last eq 0) then begin
            if n_params(0) gt 3 then begin
                group_par = make_array( dim = [pcount], type = idl_type, /nozero)
                point_lun,fcb.unit,position
                readu,fcb.unit,group_par
                if bswap then ieee_to_host,group_par
            endif
            position = position + pcount * bytes_per_word
        endif
;
; create data array
;
        if last gt 0 then begin
;
; user specified first and last
;
                if (first lt 0) or (last le 1) or (first gt last) or $
                   (last gt nwords-1) then begin
                        message = 'INVALID value for parameters FIRST & LAST'
                        goto,error_exit
                endif
                data = make_array(dim = [last-first+1], type=idl_type, /nozero)
                position = position + first * bytes_per_word
            end else begin
;
; full array
;
                if ndata eq 0 then begin
                        data = 0
                        goto,done
                endif 
                if naxis gt 8 then begin
                        message = 'Maximum value of NAXIS allowed is 8'
                        goto,error_exit
                endif
                data = make_array(dim = axis, type = idl_type, /nozero)
        end
;
; read array
;
        point_lun,fcb.unit,position
        readu,fcb.unit,data
        if (n_elements(NaNvalue) gt 0) then NaNpts = whereNaN(data,count)
        if bswap then ieee_to_host,data
        if (n_elements(NaNvalue) gt 0) then if (count gt 0) then $
                                                data[NaNpts] = NaNvalue
;
; scale data if header was read and first and last not used.   Do a special
; check of an unsigned integer (BZERO = 2^15) or unsigned long (BZERO = 2^31) 
;
        if (data_only eq 0) and (last eq 0) and (noscale eq 0) then begin

        if not keyword_set(No_Unsigned) and $
               !VERSION.RELEASE GE '5.2' then begin
        unsgn_int = (bitpix EQ 16) and (Bzero EQ 32768) and (bscale EQ 1)
        unsgn_lng = (bitpix EQ 32) and (Bzero EQ 2147483648) and (bscale EQ 1)
        if unsgn_int then begin 
                data =  uint(data) - uint(32768) 
                sxaddpar, header, 'O_BZERO',32768, $
                          ' Original Data is Unsigned Integer'
        endif else if unsgn_lng then begin 
                data = ulong(data) - ulong(2147483648)
                sxaddpar, header,'O_BZERO', 2147483648, $
                          ' Original Data is Unsigned Long'
        endif
        if unsgn_int or unsgn_lng then goto, DONE
        endif

                if bitpix lt 32 then begin      ;use real*4 for bitpix<32
                        bscale = float(bscale)
                        bzero = float(bzero)
                endif
                if bscale ne 1.0 then data = temporary(data)*bscale
                if bzero ne 0.0 then data = temporary(data) + bzero
        end
;
; done
;
done:   
        if fcbtype eq 7 then fits_close,fcb else file_or_fcb.last_extension=enum
        !err = 1
        return

;
; error exit
;
ioerror:
        message = !err_string
error_exit:
        if (fcbtype eq 7) and (N_elements(fcb) GT 0) then  $
                   fits_close,fcb, no_abort=no_abort
        !err = -1
        if keyword_set(no_abort) then return
        print,'FITS_READ ERROR: '+message
        retall
end
