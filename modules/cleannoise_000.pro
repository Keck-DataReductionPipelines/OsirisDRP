;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; NAME:  cleannoise_000
;
; PURPOSE: sets noise, 0th and 3rd bit
;
; PARAMETERS IN RPBCONFIG.XML :
;
;    cleannoise_COMMON___SetIntFrame    : set the intframe values (1)
;                                         or not (0)
;    cleannoise_COMMON___ValIntFrame    : set the intframe value to
;                                         this value
;    cleannoise_COMMON___SetBit0        : set the 0th quality bit (1)
;                                         or not (0)
;    cleannoise_COMMON___SetBit1        : set the 1st quality bit (1)
;                                         or not (0)
;    cleannoise_COMMON___SetBit2        : set the 2nd quality bit (1)
;                                         or not (0)
;    cleannoise_COMMON___SetBit3        : set the 3rd quality bit (1)
;                                         or not (0)
;    cleannoise_COMMON___ValBit0        : set 0th quality bit to
;                                         this value (0b or 1b)
;    cleannoise_COMMON___ValBit1        : set 1st quality bit to
;                                         this value (0b or 1b)
;    cleannoise_COMMON___ValBit2        : set 2nd quality bit to
;                                         this value (0b or 1b)
;    cleannoise_COMMON___ValBit3        : set 3rd quality bit to
;                                         this value (0b or 1b)
;    cleannoise_COMMON___Noise2Weight   : assume intframe values are
;                                         equal to noise values. convert noise values to
;                                         weights (=1/noise^2)
;    cleannoise_COMMON___Weight2Noise   : assume intframe values are
;                                         equal to weights. convert weights to
;                                         noise values.
;    cleannoise_COMMON___Keywords       : string with fits keywords to
;                                         be added,
;                                         e.g. 'SFILTER,DATAFILE',
;                                         separated by kommas
;    cleannoise_COMMON___KeywordsVal    : string with fits values to
;                                         be added,
;                                         e.g. 'Kbb, testfile',
;                                         separated by kommas
;    cleannoise_COMMON___KeywordsType   : string with types of fits
;                                         keywords: a,A : string
;                                                   b,B : byte
;                                                   d,D : double
;                                                   f,F : float
;                                                   i,I : integer
;                                         e.g. 'a,a'
; 
; INPUT-FILES : None
;
; OUTPUT : None
;
; DATASET : updates datsaet
;
; QUALITY BITS : ignored
;
; DEBUG : nothing special
;
; MAIN ROUTINE : intauxframe_compatibility.pro
;                set_header.pro
;
; SAVES : see Output
;
; NOTES : None
;
; STATUS : not tested
;
; HISTORY : 12.8.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION cleannoise_000, DataSet, Modules, Backbone

    COMMON APP_CONSTANTS

    functionName = 'cleannoise_000'

    ; save the starting time
    T = systime(1)

    drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1

    ; check integrity
    stModule =  check_module( DataSet, Modules, Backbone, functionName )
    if ( NOT bool_is_struct ( stModule ) ) then $
       return, error ('ERROR IN CALL ('+strtrim(functionName)+'): Integrity check failed.')

    b_IntFrame     = fix(Backbone->getParameter( 'cleannoise_COMMON___SetIntFrame')) eq 1b
    d_IntFrame     = float(Backbone->getParameter('cleannoise_COMMON___ValIntFrame'))
    b_B0           = fix(Backbone->getParameter( 'cleannoise_COMMON___ValBit0')) eq 1b
    b_B1           = fix(Backbone->getParameter( 'cleannoise_COMMON___ValBit1')) eq 1b
    b_B2           = fix(Backbone->getParameter( 'cleannoise_COMMON___ValBit2')) eq 1b
    b_B3           = fix(Backbone->getParameter( 'cleannoise_COMMON___ValBit3')) eq 1b
    b_BB0          = fix(Backbone->getParameter( 'cleannoise_COMMON___SetBit0')) eq 1b
    b_BB1          = fix(Backbone->getParameter( 'cleannoise_COMMON___SetBit1')) eq 1b
    b_BB2          = fix(Backbone->getParameter( 'cleannoise_COMMON___SetBit2')) eq 1b
    b_BB3          = fix(Backbone->getParameter( 'cleannoise_COMMON___SetBit3')) eq 1b
    b_Noise2Weight = fix(Backbone->getParameter( 'cleannoise_COMMON___Noise2Weight')) eq 1b
    b_Weight2Noise = fix(Backbone->getParameter( 'cleannoise_COMMON___Weight2Noise')) eq 1b
    vs_Keywords    = strsplit(Backbone->getParameter( 'cleannoise_COMMON___Keywords'),',',/extract)
    v_KeywordsVal  = strsplit(Backbone->getParameter( 'cleannoise_COMMON___KeywordsVal'),',',/extract)
    v_KeywordsType = strsplit(Backbone->getParameter( 'cleannoise_COMMON___KeywordsType'),',',/extract)

    if ( d_IntFrame le 0. ) then $
       return, error ('WARNING (cleannoise_000.pro): intframe values must be gt 0.')

    if ( n_elements(vs_Keywords) ne n_elements(v_KeywordsVal) or $
         n_elements(vs_Keywords) ne n_elements(v_KeywordsType) ) then begin
       print, vs_Keywords
       print, v_KeywordsVal
       print, v_KeywordsType
       return, error('ERROR IN CALL (cleannoise_000.pro): Parameters in RPBconfig.xml not consistent.')
    end

    n_Sets = Backbone->getValidFrameCount(DataSet.Name)

    intauxframe_compatibility, DataSet, n_Sets, SETNOISE=b_IntFrame, VALNOISE=d_IntFrame, $
                               WEIGHT2NOISE=b_Weight2Noise, NOISE2WEIGHT=b_Noise2Weight, $
                               VALB0=b_B0, VALB1=b_B1, VALB2=b_B2, VALB3=b_B3, $
                               SETB0=b_BB0, SETB1=b_BB1, SETB2=b_BB2, SETB3=b_BB3

    add_fitskwd_to_header, DataSet.Headers, n_Sets, vs_Keywords, v_KeywordsVal, v_KeywordsType

    report_success, functionName, T

    return, OK

END
