PRO onedatasmall
dummyarray=MAKE_ARRAY(64,64, /FLOAT, VALUE=1.0)
name = drpXlateFileName(GETENV('ONEDATADIR')) + "/" + "oneDatasmall.fits"
writefits, name, dummyarray
END
