;-----------------------------------------------------------------------------
; NAME:  make_filename
;
; PURPOSE: creates filenames according to OSDN 39.07
;
; INPUT : p_DataHeader   : pointer to a single data header
;         s_OutputDir    : output directory (optionally with
;                          environment variables)
;         s_Type         : file name extension
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
; STATUS : tested
;
; EXAMPLES :  thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
;             c_File = make_filename ( DataSet.Headers[0], Modules[thisModuleIndex].OutputDir, $
;                                     'MOSAIC', IMAG=( BranchID eq 'SRP_IMAG' or BranchID eq 'ORP_IMAG' ) )
;             if ( NOT bool_is_string(c_File) ) then begin
;                writefits, c_File, *DataSet.Frames[0], DataSet.Headers[0]
;                ...
;
; HISTORY : 27.5.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------------


function make_filename, p_DataHeader, s_OutputDir, s_Type, IMAG=IMAG

    COMMON APP_CONSTANTS

    ; get keywords from header

    stat = OK

    s_file = SXPAR(*p_DataHeader, "DATAFILE", /SILENT, count=ncount)
    if ( ncount ne 1 ) then begin
       warning, 'WARNING (make_filename.pro): keyword DATAFILE not found in header.'
       s_file = strjoin(strsplit(systime(),/extract,escape=':'),'_')
    endif ELSE BEGIN
       ; Chop the frame number off of the file name since we only want the name
       ; through the set number
       s_file_full = s_file  ; save the full name for possible later use
       s_file = STRMID(s_file, 0, STRLEN(s_file)-3)
    ENDELSE

    if ( keyword_set ( IMAG ) ) then begin
       s_filter = SXPAR(*p_DataHeader, "FILTER", /SILENT, count=ncount) 
       if ( ncount ne 1 ) then begin
          warning, 'WARNING (make_filename.pro): keyword FILTER not found in header.'
          s_filter = 'nofilter'
       end
    endif else begin
       s_filter = SXPAR(*p_DataHeader, "SFILTER", /SILENT, count=ncount)
       if ( ncount ne 1 ) then begin
          warning, 'WARNING (make_filename.pro): keyword SFILTER not found in header.'
          s_filter = 'nosfilter'
       end
    end

    s_scale = STRMID(strg(SXPAR(*p_DataHeader, "SSCALE", /SILENT, count=ncount))+'00',2,3)
    if ( ncount ne 1 ) then begin
       warning,'WARNING (make_filename.pro): keyword SSCALE not found in header.'
       s_scale = 'nosscale'
    end

    ; translate environment variables into readable paths
    if ( stat eq OK ) then BEGIN
        IF s_Type EQ 'datset' THEN BEGIN
            filename = strtrim(drpXlateFileName(s_OutputDir),2)+'/'+ strg(s_file_full) + '_' + $
                       strg(s_filter) + '_' + strg(s_scale) + '.fits'
            if ( strg(s_filter) EQ 'Drk' ) then $
              filename = strtrim(drpXlateFileName(s_OutputDir),2)+'/'+ strg(s_file_full) + '_' + $
                         strg(s_filter) + '.fits'
        ENDIF ELSE BEGIN
            filename = strtrim(drpXlateFileName(s_OutputDir),2)+'/'+ strg(s_file) + $
                       s_Type + '_' + strg(s_filter) + '_' + strg(s_scale) + '.fits'
            if ( strg(s_filter) EQ 'Drk' ) then $
              filename = strtrim(drpXlateFileName(s_OutputDir),2)+'/'+ strg(s_file) + $
                         s_Type + '_' + strg(s_filter) + '.fits'
        ENDELSE
    ENDIF else filename = ERR_UNKNOWN

    if ( file_test ( filename ) ) then begin
       ; the file already exists
       info, 'INFO (make_filename.pro): The filename you created already exists.' 
    end

    return, filename

end
