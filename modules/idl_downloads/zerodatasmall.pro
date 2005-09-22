PRO zerodatasmall
dummyarray=fltarr(64,64)
name = drpXlateFileName(GETENV('ZERODATADIR')) + "/" + "zeroDatasmall.fits"
writefits, name, dummyarray
END
