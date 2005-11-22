;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; @BEGIN
;
; @NAME srtrectdat_000 
;
; @PURPOSE Read in the frames of data from a rectification matrix scan set that
;          are used to generate the actual rectification matrix.  In the case of
;          a narrowband scan, re-order and combine the frames as needed
;
; @@@PARAMETERS
;    srtrectdat_COMMON___Debug : bool, initialize debugging mode
;
; @CALIBRATION-FILES None
;
; @INPUT Defined by DataSet
;
; @OUTPUT None. The DataSet pointers are modified and new data resides in
;         memory
;
; @MAIN None
;
; @QBITS ignored
;
; @SAVES nothing
;
; @NOTES Christof, thanks for the header format :)
;
; @STATUS Tested 2005-01-25
;
; @HISTORY 2005-01-11, created
;
; @AUTHOR T. Gasaway (tgasaway@ucsd.edu)
;
; @END
;
;-----------------------------------------------------------------------

FUNCTION srtrectdat_000, DataSet, Modules, Backbone

  COMMON APP_CONSTANTS

  functionName = 'srtrectdat_000'

  drpLog, 'Module: ' + functionName + ' - Received data set: ' + DataSet.Name, /GENERAL, /DRF, DEPTH = 1

  ; Get all COMMON parameter values
  b_Debug = fix(Backbone->getParameter('srtrectdat_COMMON___Debug')) eq 1 
  nframes = fix(Backbone->getParameter('srtrectdat_COMMON___nframesInNBMode')) 
  first_pix = fix(Backbone->getParameter('srtrectdat_COMMON___first_pixInNBMode')) 
  last_pix = fix(Backbone->getParameter('srtrectdat_COMMON___last_pixInNBMode')) 
  step = fix(Backbone->getParameter('srtrectdat_COMMON___stepInNBMode')) 
  
; Each filter actually needs its own first and last pixel. The ones in
; the RPBconfig file are only used if no valid filter is found.
  filters=["ZN2","ZN3","ZN4","ZN5","JN1","JN2","JN3","JN4","HN1","HN2","HN3","HN4","HN5","KN1","KN2","KN3","KN4","KN5"]
  fpix=[1766,1461,1141,814,2074,1737,1441,1145,2069,1742,1470,1141,805,2068,1763,1450,1126,814]
;  fpix=[1450,1450,1450,1450,1450,1450,1450,1450,1450,1450,1450,1450,1450,2023,1750,1450,1150,860]
  BranchID = Backbone->getType()
  CASE BranchID OF
    'CRP_SPEC':  BEGIN
      ; Get the file name from the header.  This file name does not include the
      ; .fits file extension
      filename = STRTRIM(SXPAR(*DataSet.Headers[0], 'DATAFILE', /SILENT), 2)
      sfilter = STRTRIM(SXPAR(*DataSet.Headers[0], 'SFILTER', /SILENT), 2)
      firstFrameNum = FIX(STRMID(filename, STRLEN(filename)-3))
      fileNameThruDSN = STRMID(filename, 0, STRLEN(filename)-3)
      rectType = 'nb'  ; Assume Narrowband
      IF STRPOS( sfilter, 'bb') GT -1 THEN rectType = 'bb'  ; Reset if we are doing a Broadband case
      CASE rectType OF
        ; Broadband
        'bb': BEGIN
          ; Reset the valid frame count
          DataSet.ValidFrameCount = 0
          ; Read the frames in reverse order
          FOR i = 23,  5, -1 DO BEGIN
            currFileName = fileNameThruDSN + strwithzeroes(STRTRIM(STRING(firstFrameNum+i), 2), 3, -1) + '.fits'
            *DataSet.Frames[DataSet.ValidFrameCount] = FLOAT(READFITS(drpXlateFileName(DataSet.InputDir + '/' + currFileName), Header, /SILENT)) 
            *DataSet.Headers[DataSet.ValidFrameCount] = Header
            *DataSet.IntFrames[DataSet.ValidFrameCount] = FLOAT(READFITS(drpXlateFileName(DataSet.InputDir + '/' + currFileName), Header, EXTEN_NO=1, /SILENT))
            *DataSet.IntAuxFrames[DataSet.ValidFrameCount] = BYTE(READFITS(drpXlateFileName(DataSet.InputDir + '/' + currFileName), Header, EXTEN_NO=2, /SILENT))
            DataSet.ValidFrameCount = DataSet.ValidFrameCount + 1
            PRINT, FORMAT='(I2, " ",$)', DataSet.ValidFrameCount
          ENDFOR
          PRINT, ''
          ; Set the global valid frame count to the new, and improved!, local value
          RetVal = Backbone->setValidFrameCount(DataSet.Name, DataSet.ValidFrameCount)
        END  ; CASE 'bb'
        ; Narrowband
        'nb': BEGIN
            sf = STRUPCASE(sfilter)
            for i = 0, 17 do begin
                if STRCMP(sf,filters[i]) eq 1 then begin
                    first_pix=fpix[i]
                    print, 'Filter = ', filters[i], 'First_pix = ',first_pix
                end

            end
            last_pix = first_pix+650

            DataSet.ValidFrameCount = 0            
          ; Now read in the data and make 'compressed' scans where 3 files are added
          ; into one.  Each compressed scan will be stored in the DataSet for further
          ; processing

          ; Create a list of the file names grouped in the correct order
          filename = STRARR(nframes,3)

          FOR i = 0, 18 DO BEGIN
            number = firstFrameNum + i + 5
            mynumstr = strn(number)
            filename[i,0]=strcompress(drpXlateFileName(DataSet.InputDir + '/' + $
            fileNameThruDSN + strwithzeroes(mynumstr, 3, -1) + '.fits'),/REMOVE_ALL)
            number = firstFrameNum + 16 + i + 5
            mynumstr = strn(number)
            filename[i,1]=strcompress(drpXlateFileName(DataSet.InputDir + '/' + $
            fileNameThruDSN + strwithzeroes(mynumstr, 3, -1) + '.fits'),/REMOVE_ALL)
            number = firstFrameNum + 32 + i + 5
            mynumstr = strn(number)
            filename[i,2]=strcompress(drpXlateFileName(DataSet.InputDir + '/' + $
            fileNameThruDSN + strwithzeroes(mynumstr, 3, -1) + '.fits'),/REMOVE_ALL)
          ENDFOR
          FOR i = 0, 18 DO BEGIN
            FOR j = 0, 2 DO BEGIN
              PRINT, filename[i,j]
            ENDFOR
            PRINT, ''
          ENDFOR
          FOR i = 15, 0, -1 DO BEGIN

            fp = 0 > (first_pix - step*i) < 2047
            lp = 0 > (last_pix - step*i) < 2047

            *DataSet.Frames[1] = FLOAT(READFITS(filename[i,0],*DataSet.Headers[0], /SILENT))
            (*DataSet.Frames[1])[0:fp,*] = 0
            (*DataSet.Frames[1])[lp:2047,*] = 0
            *DataSet.Frames[0] = *DataSet.Frames[1]
            
            *DataSet.IntFrames[1] = FLOAT(READFITS(filename[i,0],EXTEN_NO=1, /SILENT))
            (*DataSet.IntFrames[1])[0:fp,*] = 0
            (*DataSet.IntFrames[1])[lp:2047,*] = 0
            *DataSet.IntFrames[0] = *DataSet.IntFrames[1]
            
            *DataSet.IntAuxFrames[1] = BYTE(READFITS(filename[i,0],EXTEN_NO=2, /SILENT))
            (*DataSet.IntAuxFrames[1])[0:fp,*] = 9
            (*DataSet.IntAuxFrames[1])[lp:2047,*] = 9
            *DataSet.IntAuxFrames[0] = *DataSet.IntAuxFrames[1]

            fp = 0 > (first_pix - step*(i+16)) < 2047
            lp = 0 > (last_pix - step*(i+16)) < 2047

            *DataSet.Frames[1] = FLOAT(READFITS(filename[i,1], *DataSet.Headers[1], /SILENT))
            (*DataSet.Frames[1])[0:fp,*] = 0
            (*DataSet.Frames[1])[lp:2047,*] = 0
            *DataSet.Frames[0] = *DataSet.Frames[0]+(*DataSet.Frames[1])

            *DataSet.IntFrames[1] = FLOAT(READFITS(filename[i,1],EXTEN_NO=1, /SILENT))
            (*DataSet.IntFrames[1])[0:fp,*] = 0
            (*DataSet.IntFrames[1])[lp:2047,*] = 0
            *DataSet.IntFrames[0] = *DataSet.IntFrames[0] + (*DataSet.IntFrames[1])
            
            *DataSet.IntAuxFrames[1] = BYTE(READFITS(filename[i,1],EXTEN_NO=2, /SILENT))
            (*DataSet.IntAuxFrames[1])[0:fp,*] = 9
            (*DataSet.IntAuxFrames[1])[lp:2047,*] = 9
            *DataSet.IntAuxFrames[0] = (*DataSet.IntAuxFrames[0]) AND (*DataSet.IntAuxFrames[1])

            fp = 0 > (first_pix - step*(i+32)) < 2047
            lp = 0 > (last_pix - step*(i+32)) < 2047

            *DataSet.Frames[1] = FLOAT(READFITS(filename[i,2], *DataSet.Headers[1], /SILENT))
            (*DataSet.Frames[1])[0:fp,*] = 0
            (*DataSet.Frames[1])[lp:2047,*] = 0
            *DataSet.Frames[0] = *DataSet.Frames[0]+(*DataSet.Frames[1])

            *DataSet.IntFrames[1] = FLOAT(READFITS(filename[i,2],EXTEN_NO=1, /SILENT))
            (*DataSet.IntFrames[1])[0:fp,*] = 0
            (*DataSet.IntFrames[1])[lp:2047,*] = 0
            *DataSet.IntFrames[0] = *DataSet.IntFrames[0] + (*DataSet.IntFrames[1])

            *DataSet.IntAuxFrames[1] = BYTE(READFITS(filename[i,2],EXTEN_NO=2, /SILENT))
            (*DataSet.IntAuxFrames[1])[0:fp,*] = 9
            (*DataSet.IntAuxFrames[1])[lp:2047,*] = 9
            *DataSet.IntAuxFrames[0] = (*DataSet.IntAuxFrames[0]) AND (*DataSet.IntAuxFrames[1])

            IF ( i lt 3 ) THEN BEGIN
              fp = 0 > (first_pix - step*(i+48)) < 2047
              lp = 0 > (last_pix - step*(i+48)) < 2047

              *DataSet.Frames[1] = FLOAT(READFITS(filename[i+16,2], *DataSet.Headers[1], /SILENT))
              (*DataSet.Frames[1])[0:fp,*] = 0
              (*DataSet.Frames[1])[lp:2047,*] = 0
              *DataSet.Frames[0] = *DataSet.Frames[0]+(*DataSet.Frames[1])

              *DataSet.IntFrames[1] = FLOAT(READFITS(filename[i+16,2],EXTEN_NO=1, /SILENT))
              (*DataSet.IntFrames[1])[0:fp,*] = 0
              (*DataSet.IntFrames[1])[lp:2047,*] = 0
              *DataSet.IntFrames[0] = *DataSet.IntFrames[0] + (*DataSet.IntFrames[1])

              *DataSet.IntAuxFrames[1] = BYTE(READFITS(filename[i+16,2],EXTEN_NO=2, /SILENT))
              (*DataSet.IntAuxFrames[1])[0:fp,*] = 9
              (*DataSet.IntAuxFrames[1])[lp:2047,*] = 9
              *DataSet.IntAuxFrames[0] = (*DataSet.IntAuxFrames[0]) AND (*DataSet.IntAuxFrames[1])
            ENDIF
            ; Store the created frames in 'reverse' order in the DataSet memory
            *DataSet.Frames[18-i] = *DataSet.Frames[0]
            *DataSet.Headers[18-i] = *DataSet.Headers[0]
            *DataSet.IntFrames[18-i] = *DataSet.IntFrames[0]
            *DataSet.IntAuxFrames[18-i] = *DataSet.IntAuxFrames[0]
            DataSet.ValidFrameCount = DataSet.ValidFrameCount + 1
            PRINT, FORMAT='(I2, " ",$)', DataSet.ValidFrameCount
          ENDFOR

          ; Copy the last 3 frames into the first 3 (of 19) slots
          FOR i = 0, 15 DO BEGIN
            *DataSet.Frames[i] = *DataSet.Frames[i+3]
            *DataSet.Headers[i] = *DataSet.Headers[i+3]
            *DataSet.IntFrames[i] = *DataSet.IntFrames[i+3]
            *DataSet.IntAuxFrames[i] = *DataSet.IntAuxFrames[i+3]
;            DataSet.ValidFrameCount = DataSet.ValidFrameCount + 1
            PRINT, FORMAT='(I2, " ",$)', DataSet.ValidFrameCount
          ENDFOR
          DataSet.ValidFrameCount = DataSet.ValidFrameCount + 3
          PRINT, ''
          ; Set the global valid frame count to the new, and improved!, local value
          RetVal = Backbone->setValidFrameCount(DataSet.Name, DataSet.ValidFrameCount)
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

  PRINT, FORMAT='(A, " ", $)', functionName
  HELP, /MEMORY
  RETURN, 0

END
