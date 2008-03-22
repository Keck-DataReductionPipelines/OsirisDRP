;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; @BEGIN
;
; @NAME mkrectdark_000 
;
; @PURPOSE Read in the frames of data from a rectification matrix scan set that
;          are used to generate the scan set's dark frame
;
; @@@PARAMETERS IN RPBCONFIG.XML
;    mkrectdark_COMMON___Debug : BOOL, initialize debugging mode
;
; @CALIBRATION-FILES None
;
; @INPUT 
;
; @OUTPUT None.  The DataSet pointers are modified and new data resides in
;         memory
;
; @MAIN None
;
; @QBITS ignored
;
; @DEBUG Nothing special
;
; @SAVES see OUTPUT
;
; @NOTES Christof, thanks for the header format :)
;
; @STATUS Tested successfully 2005-01-06
;
; @HISTORY 2005-01-06, created
;
; @AUTHOR T. Gasaway (tgasaway@ucsd.edu)
;
; @END
;
;-----------------------------------------------------------------------

FUNCTION mkrectdark_000, DataSet, Modules, Backbone

  COMMON APP_CONSTANTS

  functionName = 'mkrectdark_000'

  drpLog, 'Module: ' + functionName + ' - Received data set: ' + DataSet.Name, /GENERAL, /DRF, DEPTH = 1

  ; Get all COMMON parameter values
  b_Debug = fix(Backbone->getParameter('mkrectdark_COMMON___Debug')) eq 1 
  frmsInDark = fix(Backbone->getParameter('mkrectdark_COMMON___framesInDark')) 

  BranchID = Backbone->getType()
  CASE BranchID OF
    'CRP_SPEC':  BEGIN
      ; Get the file name from the header.
      filename = STRTRIM(SXPAR(*DataSet.Headers[0], "DATAFILE", /SILENT), 2)
      sfilter = STRTRIM(SXPAR(*DataSet.Headers[0], "SFILTER", /SILENT), 2)
      firstFrameNum = FIX(STRMID(filename, STRLEN(filename)-3))
      fileNameThruDSN = STRMID(filename, 0, STRLEN(filename)-3)
      rectType = 'nb'  ; Assume Narrowband
      IF STRPOS( sfilter, 'b') GT -1 THEN rectType = 'bb'  ; Reset if we are doing a Broadband case
      CASE rectType OF
        ; Broadband
        'bb': BEGIN
          ; Start at 1 instead of 0 since we have already read in the 0th data frame
          ; just to get started with this module
          FOR i =  1,  4 DO BEGIN
            currFileName = fileNameThruDSN + strwithzeroes(STRTRIM(STRING(firstFrameNum+i), 2), 3, -1) + '.fits'
            *DataSet.Frames[DataSet.ValidFrameCount] = FLOAT(READFITS(drpXlateFileName(DataSet.InputDir + '/' + currFileName), Header, /SILENT)) 
            *DataSet.Headers[DataSet.ValidFrameCount] = Header
            *DataSet.IntFrames[DataSet.ValidFrameCount] = FLOAT(READFITS(drpXlateFileName(DataSet.InputDir + '/' + currFileName), Header, EXTEN_NO=1, /SILENT))
            *DataSet.IntAuxFrames[DataSet.ValidFrameCount] = BYTE(READFITS(drpXlateFileName(DataSet.InputDir + '/' + currFileName), Header, EXTEN_NO=2, /SILENT))
            DataSet.ValidFrameCount = DataSet.ValidFrameCount + 1
            PRINT, FORMAT='(".",$)'
          ENDFOR
          FOR i = 24, 28 DO BEGIN
            currFileName = fileNameThruDSN + strwithzeroes(STRTRIM(STRING(firstFrameNum+i), 2), 3, -1) + '.fits'
            *DataSet.Frames[DataSet.ValidFrameCount] = FLOAT(READFITS(drpXlateFileName(DataSet.InputDir + '/' + currFileName), Header, /SILENT)) 
            *DataSet.Headers[DataSet.ValidFrameCount] = Header
            *DataSet.IntFrames[DataSet.ValidFrameCount] = FLOAT(READFITS(drpXlateFileName(DataSet.InputDir + '/' + currFileName), Header, EXTEN_NO=1, /SILENT))
            *DataSet.IntAuxFrames[DataSet.ValidFrameCount] = BYTE(READFITS(drpXlateFileName(DataSet.InputDir + '/' + currFileName), Header, EXTEN_NO=2, /SILENT))
            DataSet.ValidFrameCount = DataSet.ValidFrameCount + 1
            PRINT, FORMAT='(".",$)'
          ENDFOR
          PRINT, ""
        END  ; CASE 'bb'
        ; Narrowband
        'nb': BEGIN
          ; Start at 1 instead of 0 since we have already read in the 0th data frame
          ; just to get started with this module
          FOR i =  1,  4 DO BEGIN
            currFileName = fileNameThruDSN + strwithzeroes(STRTRIM(STRING(firstFrameNum+i), 2), 3, -1) + '.fits'
            *DataSet.Frames[DataSet.ValidFrameCount] = FLOAT(READFITS(drpXlateFileName(DataSet.InputDir + '/' + currFileName), Header, /SILENT)) 
            *DataSet.Headers[DataSet.ValidFrameCount] = Header
            *DataSet.IntFrames[DataSet.ValidFrameCount] = FLOAT(READFITS(drpXlateFileName(DataSet.InputDir + '/' + currFileName), Header, EXTEN_NO=1, /SILENT))
            *DataSet.IntAuxFrames[DataSet.ValidFrameCount] = BYTE(READFITS(drpXlateFileName(DataSet.InputDir + '/' + currFileName), Header, EXTEN_NO=2, /SILENT))
            DataSet.ValidFrameCount = DataSet.ValidFrameCount + 1
            PRINT, FORMAT='(".",$)'
          ENDFOR
          FOR i = 56, 60 DO BEGIN
            currFileName = fileNameThruDSN + strwithzeroes(STRTRIM(STRING(firstFrameNum+i), 2), 3, -1) + '.fits'
            *DataSet.Frames[DataSet.ValidFrameCount] = FLOAT(READFITS(drpXlateFileName(DataSet.InputDir + '/' + currFileName), Header, /SILENT)) 
            *DataSet.Headers[DataSet.ValidFrameCount] = Header
            *DataSet.IntFrames[DataSet.ValidFrameCount] = FLOAT(READFITS(drpXlateFileName(DataSet.InputDir + '/' + currFileName), Header, EXTEN_NO=1, /SILENT))
            *DataSet.IntAuxFrames[DataSet.ValidFrameCount] = BYTE(READFITS(drpXlateFileName(DataSet.InputDir + '/' + currFileName), Header, EXTEN_NO=2, /SILENT))
            DataSet.ValidFrameCount = DataSet.ValidFrameCount + 1
            PRINT, FORMAT='(".",$)'
          ENDFOR
          PRINT, ""
        END  ; CASE 'nb'
      ELSE:  BEGIN
        drpLog, 'FUNCTION '+ functionName + ': CASE error: Unrecognizable filter = ' + rectType, /DRF, DEPTH = 2
        RETURN, ERR_BADCASE
      END  ; CASE Unrecognizable filter
      ENDCASE
    END    
  ELSE: BEGIN
    drpLog, 'FUNCTION '+ functionName + ': CASE error: Bad Type = ' + BranchID, /DRF, DEPTH = 2
    RETURN, ERR_BADCASE
  END  ; CASE BadType
  ENDCASE

  ; Reset the global DataSet.ValidFrameCount so that the following module can use it
  RetVal = Backbone->setValidFrameCount(DataSet.Name, frmsInDark)

  RETURN, 0

END
