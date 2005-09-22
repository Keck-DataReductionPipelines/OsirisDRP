PRO onedata
dummyarray=MAKE_ARRAY(2048,2048, /FLOAT, VALUE=1.0)
name = drpXlateFileName(GETENV('ONEDATADIR')) + "/" + "oneData.fits"
writefits, name, dummyarray
END
