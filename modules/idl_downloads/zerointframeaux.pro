PRO zerointframeaux
dummyarray=bytarr(2048,2048)
name = drpXlateFileName(GETENV('ZERODATADIR')) + "/" + "zeroData.fits"
mkhdr, header, dummyarray, /IMAGE
SXADDPAR, header, "EXTNAME", "QUALITY", "Quality frame for zeroData.fits"
writefits, name, dummyarray, header, /APPEND
END
