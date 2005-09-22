PRO oneintframeaux
dummyarray=MAKE_ARRAY(2048,2048, /BYTE, VALUE=1)
name = drpXlateFileName(GETENV('ONEDATADIR')) + "/" + "oneData.fits"
mkhdr, header, dummyarray, /IMAGE
SXADDPAR, header, "EXTNAME", "QUALITY", "Quality frame for oneData.fits"
writefits, name, dummyarray, header, /APPEND
END
