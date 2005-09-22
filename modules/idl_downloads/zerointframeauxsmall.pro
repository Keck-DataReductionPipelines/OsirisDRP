PRO zerointframeauxsmall
dummyarray=bytarr(64,64)
name = drpXlateFileName(GETENV('ZERODATADIR')) + "/" + "zeroDatasmall.fits"
mkhdr, header, dummyarray, /IMAGE
SXADDPAR, header, "EXTNAME", "QUALITY", "Quality frame for zeroDatasmall.fits"
writefits, name, dummyarray, header, /APPEND
END
