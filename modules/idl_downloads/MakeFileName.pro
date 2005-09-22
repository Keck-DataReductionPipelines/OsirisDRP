;-----------------------------------------------------------------------------
;
; input : p_DataHeader   : pointer to a single data header
;         s_OutputDir    : output directory, without any environment variables
;         s_Type         : file type designator :
;                          CORDISP      : output from corrdisper_000.pro
;                          FITDISP      : calibration output from
;                                         fitdispers_000.pro
;                          MOSAIC       : mosaiced data
;                          SPEC         : extracted stellar spectrum
;                          DIVSTAR      : division by a stellar spectrum
;         /IMAG          : use the imager filter keyword FILTER
;         STAT=stat      : a named variable that is 0 if no error
;                          occured, otherwise 1
;
;-----------------------------------------------------------------------------


function MakeFileName, p_DataHeader, s_OutputDir, s_Type, IMAG=IMAG, STAT=stat

    stat = 0

    s_file = SXPAR(*p_DataHeader, "FILENAME", /SILENT, count=filecount)
    if ( filecount eq 0 ) then begin
       stat = 1
       dummy = error('FAILURE (MakeFileName.pro): keyword FILENAME not found in header')
    end

    if ( keyword_set ( IMAG ) ) then $
       s_filter = SXPAR(*p_DataHeader, "FILTER", /SILENT, count=fcount) $
    else $
       s_filter = SXPAR(*p_DataHeader, "SFILTER", /SILENT, count=fcount)

    if ( fcount eq 0 ) then begin
       stat = 1
       dummy = error('FAILURE (MakeFileName.pro): keyword SFILTER or FILTER not found in header')
    end

    s_scale = SXPAR(*p_DataHeader, "SSCALE", /SILENT, count=scount)
    if ( scount eq 0 ) then begin
       stat = 1
       dummy = error('FAILURE (MakeFileName.pro): keyword SSCALE not found in header')
    end

    case s_Type of

       'FITDISP' : s_ftd = '__dfit'
       'CORDISP' : s_ftd = 'dcalib'
       'MOSAIC'  : s_ftd = 'mosaic'
       'SPEC'    : s_ftd = '_sspec'
       'DIVSTAR' : s_ftd = '_dspec'

    else : begin
              stat = 1
              dummy = error('ERROR IN CALL (MakeFileName.pro): Unknown file type designator')
           end
    endcase

    ; translate environment variables into readable paths
    if ( stat eq 0 ) then $
       filename = strtrim(s_OutputDir,2)+'/'+ STRMID(strtrim(s_file,2), 0, 12) + s_ftd + '_' + strtrim(s_filter,2) + $
                  '_' + STRMID(STRTRIM(STRING(s_scale), 2), 2, 3) + '.fits' $
    else filename = 'no_filename_created.fits'

    return, filename

end
