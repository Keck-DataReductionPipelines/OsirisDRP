PRO zerointframesmall
dummyarray=fltarr(64,64)
name = drpXlateFileName(GETENV('ZERODATADIR')) + "/" + "zeroDatasmall.fits"
mkhdr, header, dummyarray, /IMAGE
SXADDPAR, header, "EXTNAME", "NOISE", "Noise frame for zeroDatasmall.fits"
writefits, name, dummyarray, header, /APPEND
END
