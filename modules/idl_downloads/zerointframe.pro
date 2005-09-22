PRO zerointframe
dummyarray=fltarr(2048,2048)
name = drpXlateFileName(GETENV('ZERODATADIR')) + "/" + "zeroData.fits"
mkhdr, header, dummyarray, /IMAGE
SXADDPAR, header, "EXTNAME", "NOISE", "Noise frame for zeroData.fits"
writefits, name, dummyarray, header, /APPEND
END
