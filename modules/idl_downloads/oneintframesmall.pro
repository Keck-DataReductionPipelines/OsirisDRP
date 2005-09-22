PRO oneintframesmall
dummyarray=MAKE_ARRAY(64,64, /FLOAT, VALUE=1.0)
name = drpXlateFileName(GETENV('ONEDATADIR')) + "/" + "oneDatasmall.fits"
mkhdr, header, dummyarray, /IMAGE
SXADDPAR, header, "EXTNAME", "NOISE", "Noise frame for oneDatasmall.fits"
writefits, name, dummyarray, header, /APPEND
END
