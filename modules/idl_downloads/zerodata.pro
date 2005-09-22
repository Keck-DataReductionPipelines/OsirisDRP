PRO zerodata
dummyarray=fltarr(2048,2048)
name = drpXlateFileName(GETENV('ZERODATADIR')) + "/" + "zeroData.fits"
writefits, name, dummyarray
END
