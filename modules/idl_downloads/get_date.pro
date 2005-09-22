pro get_date, dte, in_date, OLD = old, TIMETAG = timetag, LOCAL_DIFF = local_diff
;+
; NAME:
;       GET_DATE
; PURPOSE:
;       Return the (current) UTC date in CCYY-MM-DD format for FITS headers
; EXPLANATION:
;       This is the format required by the DATE and DATE-OBS keywords in a 
;       FITS header.
;
; CALLING SEQUENCE:
;       GET_DATE, FITS_date, [ in_date, /OLD, /TIMETAG, LOCAL_DIFF=]
; OPTIONAL INPUTS:
;       in_date - string (scalar or vector) containing dates in IDL
;            systime() format (e.g. 'Tue Sep 25 14:56:14 2001')
; OUTPUTS:
;       FITS_date = A scalar character string giving the current date.    Actual
;               appearance of dte depends on which keywords are supplied.
;       
;       No Keywords supplied - dte is a 10 character string with the format
;               CCYY-MM-DD where <CCYY> represents a calendar year, <MM> the
;               ordinal number of a calendar month within the calendar year, 
;               and <DD> the ordinal number of a day within the calendar month.
;       /TIMETAG set - dte is a 19 character string with the format
;               CCYY-MM-DDThh:mm:ss where <hh> represents the hour in the day,
;                <mm> the minutes, <ss> the seconds, and the literal 'T' the 
;               ISO 8601 time designator
;       /OLD set - dte is an 8 character string in DD/MM/YY format
;
; INPUT KEYWORDS:
;       /TIMETAG - Specify the time to the nearest second in the DATE format
;       /OLD - Return the DATE format formerly (pre-1997) recommended for FITS
;               Note that this format is now deprecated because it uses only
;               a 2 digit representation of the year. 
;       LOCAL_DIFF - numeric scalar giving the difference between local time
;               and Greenwich Mean Time (GMT) in hours.   This keyword is only
;               needed for non-Unix users prior to V5.4.  Unix users should not 
;               use this keyword because under Unix (or since V5.4 with any OS),
;               SYSTIME(1) returns the UTC (=GMT) time directly.
;               Users on other machines must either supply a LOCAL_DIFF keyword,
;               or use the TIME_CONV environment variable discussed below.    
;               For example, a user on U.S. Eastern Standard Time should set 
;               LOCAL_DIFF = -5
; EXAMPLE:
;       Add the current date to the DATE keyword in a FITS header,h
;     
;       IDL> GET_DATE,dte
;       IDL> sxaddpar, h, 'DATE', dte, 'Date header was created'
; ENVIRONMENT VARIABLE:
;       An alternate method of inputing the difference between local and GMT 
;       time for non-Unix machines is to specify this information in a file 
;       named local_diff.dat in a directory specified with the environment 
;       variable TIME_CONV.       For example, a user in EST should write -5 
;       on this first (and only) line of this file.
;
; NOTES:
;       (1) A discussion of the DATExxx syntax in FITS headers can be found in
;       http://www.cv.nrao.edu/fits/documents/standards/year2000.txt
;
;       (2) Those who wish to use need further flexibility in their date 
;       formats (e.g. to use TAI time) should look at Bill Thompson's time
;       routines in http://sohowww.nascom.nasa.gov/solarsoft/gen/idl/time
;
; PROCEDURES USED:
;       DAYCNV - Convert Julian date to Gregorian calendar date
; REVISION HISTORY:
;       Written      W. Landsman          March 1991
;       Major rewrite to write new DATExxx syntax  W. Landsman  August 1997
;       Converted to IDL V5.0   W. Landsman   September 1997
;       Work after year 2000 even with /OLD keyword W. Landsman January 2000
;       Don't need to worry about TIME_DIFF since V5.4 W. Landsman July 2001
;-
 On_error,2
 
 if N_params() LT 1 then begin
     print,'Syntax - Get_date, FITS_date, [ in_date, /TIMETAG, /OLD ]'
     print,'  FITS_date - output string giving date(s) in FITS format'
     print,'  in-date - Optional input string giving date in systime() format'
     return
 endif

 if N_elements(in_date) GT 0 then begin
     mn = strmid(in_date,4,3)
     month = month_cnv(mn)
     day = fix(strmid(in_date,8,2))
     ihr = fix(strmid(in_date,11,2))
     imn = fix(strmid(in_date,14,2))
     sec = fix(strmid(in_date,17,2))
     yr = fix(strmid(in_date,20,4))
     if N_elements(local_diff) GT 0 then ihr = ihr - local_diff
 endif else begin 
     seconds = systime(1)          ;Number of seconds since Jan 1, 1970

 if (not keyword_set(LOCAL_DIFF)) and (!VERSION.RELEASE LT '5.4') then begin
 if getenv('TIME_CONV') NE '' then begin
        filename = FIND_WITH_DEF('local_diff.dat','TIME_CONV')
        if filename NE '' then begin
                openr, unit, filename, /GET_LUN
                diff = 0.0D0
                readf, unit, local_diff
                test = ""
                if not eof(unit) then readf,unit,test
                free_lun,unit
                if strupcase(strmid(test,0,3)) EQ 'GMT' then local_diff = 0.0
                        
        endif
  endif
  endif
 if N_elements(local_diff) GT 0 then seconds = seconds - local_diff*3600.

 dayseconds = 86400.D0               ;Number of seconds in a day
 mjd = seconds/dayseconds + 40587.0D
 jd =  2400000.5D + mjd
 DAYCNV, jd, yr, month, day, hr
 endelse 

 if keyword_set(old) then begin

 if yr GE 2000 then yr = yr - 100
 dte =  string(day,f='(I2.2)') + '/' + string(month,f='(i2.2)') +  $
        '/' + string( yr-1900,f='(I2.2)')                          

 endif else $ 

 dte =  string(yr,f='(I4.4)') + '-' + string(month,f='(i2.2)') + '-' + $
        string(day,f='(I2.2)')

 if keyword_set(TIMETAG) then begin
 if N_elements(in_date) EQ 0 then begin
   ihr = fix(hr)
   mn = (hr - ihr)*60.
   imn = fix(mn)
   sec = round((mn - imn)*60.)
 endif 

 dte =  dte + 'T' + string(ihr,f='(I2.2)') + ':' + string(imn,f='(I2.2)') +  $
               ':' + string(round(sec),f='(I2.2)')
 endif
         
 return
 end
