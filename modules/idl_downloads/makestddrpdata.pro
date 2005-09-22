PRO makestddrpdata, directory, filename1, filename2, outfilename, csetnum, cframnum, nuframes, framtype, applyfix
realname1 = drpXlateFileName(GETENV(directory)) + "/" + filename1
realname2 = drpXlateFileName(GETENV(directory)) + "/" + filename2
data1 = READFITS(realname1, hdr1, /SILENT)
data2 = READFITS(realname2, hdr2, /SILENT)

realoutfilename = drpXlateFileName(GETENV(directory)) + "/" + outfilename
; Create a header and add a few keywords
SXADDPAR, hdr2, 'FRAMTYPE', framtype, BEFORE='EXTEND'
SXADDPAR, hdr2, 'NUFRAMES', nuframes, BEFORE='FRAMTYPE'
SXADDPAR, hdr2, 'CFRAMNUM', cframnum, BEFORE='NUFRAMES'
SXADDPAR, hdr2, 'CSETNUM' , csetnum, BEFORE='CFRAMNUM'
diff=data2-data1
fdiff=FLOAT(diff)

; If necessary, fix the "data is in the wrong place in the array" problem
IF applyfix EQ 1 THEN BEGIN
  temp8 = fdiff[1024:2047, 1024:1151]
  temp1to7 = fdiff[1024:2047, 1152:2047]
  fdiff[1024:2047, 1024:1919] = temp1to7
  fdiff[1024:2047, 1920:2047] = temp8
ENDIF

writefits, realoutfilename, fdiff, hdr2

; Make and append noise array
dummyarray=MAKE_ARRAY(2048,2048, /FLOAT, VALUE=1.0)
mkhdr, newheader1, dummyarray, /IMAGE
SXADDPAR, newheader1, "EXTNAME", "NOISE", " Noise frame for " + outfilename
writefits, realoutfilename, dummyarray, newheader1, /APPEND

; Make and append quality array
dummyarray=bytarr(2048,2048)
mkhdr, newheader2, dummyarray, /IMAGE
SXADDPAR, newheader2, "EXTNAME", "QUALITY", " Quality frame for " + outfilename
writefits, realoutfilename, dummyarray, newheader2, /APPEND
END
