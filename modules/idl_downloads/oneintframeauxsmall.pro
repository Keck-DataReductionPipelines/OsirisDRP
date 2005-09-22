PRO oneintframeauxsmall
dummyarray=MAKE_ARRAY(64,64, /BYTE, VALUE=1)
name = drpXlateFileName(GETENV('ONEDATADIR')) + "/" + "oneDatasmall.fits"
mkhdr, header, dummyarray, /IMAGE
SXADDPAR, header, "EXTNAME", "QUALITY", "Quality frame for oneDatasmall.fits"
writefits, name, dummyarray, header, /APPEND
END
