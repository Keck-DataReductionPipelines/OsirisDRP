PRO oneintframe
dummyarray=MAKE_ARRAY(2048,2048, /FLOAT, VALUE=1.0)
name = drpXlateFileName(GETENV('ONEDATADIR')) + "/" + "oneData.fits"
mkhdr, header, dummyarray, /IMAGE
SXADDPAR, header, "EXTNAME", "NOISE", "Noise frame for oneData.fits"
writefits, name, dummyarray, header, /APPEND
END
