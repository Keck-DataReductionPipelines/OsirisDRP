function strn, number, LENGTH = length, PADTYPE = padtype, PADCHAR = padchar, $
                       FORMAT = Format
;+
; NAME:
;	STRN
; PURPOSE:
;	Convert a number to a string and remove padded blanks.
; EXPLANATION:
;	The main and original purpose of this procedure is to convert a number
;	to an unpadded string (i.e. with no blanks around it.)  However, it 
;	has been expanded to be a multi-purpose formatting tool.  You may 
;	specify a length for the output string; the returned string is either 
;	set to that length or padded to be that length.  You may specify 
;	characters to be used in padding and which side to be padded.  Finally,
;	you may also specify a format for the number.  NOTE that the input 
;	"number" need not be a number; it may be a string, or anything.  It is
;	converted to string.
;
; CALLING SEQEUNCE:
;	tmp = STRN( number, [ LENGTH=, PADTYPE=, PADCHAR=, FORMAT = ] )
;
; INPUT:
;	NUMBER    This is the input variable to be operated on.  Traditionally,
;		 it was a number, but it may be any scalar type.
;
; OPTIONAL INPUT:
;	LENGTH    This KEYWORD specifies the length of the returned string.  
;		If the output would have been longer, it is truncated.  If 
;		the output would have been shorter, it is padded to the right 
;		length.
;	PADTYPE   This KEYWORD specifies the type of padding to be used, if any.
;		0=Padded at End, 1=Padded at front, 2=Centered (pad front/end)
;		IF not specified, PADTYPE=1
;	PADCHAR   This KEYWORD specifies the character to be used when padding.
;		The default is a space (' ').
;	FORMAT    This keyword allows the FORTRAN type formatting of the input
;		number (e.g. '(f6.2)')
;
; OUTPUT:
;	tmp       The formatted string
;
; USEFUL EXAMPLES:
;	print,'Used ',strn(stars),' stars.'  ==> 'Used 22 stars.'
;	print,'Attempted ',strn(ret,leng=6,padt=1,padch='0'),' retries.'
;		==> 'Attempted 000043 retries.'
;	print,strn('M81 Star List',length=80,padtype=2)
;		==> an 80 character line with 'M81 Star List' centered.
;	print,'Error: ',strn(err,format='(f15.2)')
;		==> 'Error: 3.24'     or ==> 'Error: 323535.22'
;
; HISTORY:
;	03-JUL-90 Version 1 written by Eric W. Deutsch
;	10-JUL-90 Trimming and padding options added         (E. Deutsch)
;	29-JUL-91 Changed to keywords and header spiffed up     (E. Deutsch)
;	Ma7 92 Work correctly for byte values (W. Landsman)
;	19-NOV-92 Added Patch to work around IDL 2.4.0 bug which caused an
;	error when STRN('(123)') was encountered.            (E. Deutsch)
;	Converted to IDL V5.0   W. Landsman   September 1997
;-
 On_error,2
  if ( N_params() LT 1 ) then begin
    print,'Call: IDL> tmp=STRN(number,[length=,padtype=,padchar=,format=])'
    print,"e.g.: IDL> print,'Executed ',strn(ret,leng=6,padt=1,padch='0'),' retries.'"
    return,''
    endif
  if (N_elements(padtype) eq 0) then padtype=1
  if (N_elements(padchar) eq 0) then padchar=' '
  if (N_elements(Format) eq 0) then Format=''

  padc = byte(padchar)
  pad = string(replicate(padc[0],200))

  ss=size(number) & PRN=1 & if (ss[1] eq 7) then PRN=0
  if ( Format EQ '') then tmp = strtrim( string(number, PRINT=PRN),2) $
    else tmp = strtrim( string( number, FORMAT=Format, PRINT=PRN),2)

  if (N_elements(length) eq 0) then length=strlen(tmp)

  if (strlen(tmp) gt length) then tmp=strmid(tmp,0,length)

  if (strlen(tmp) lt length) and (padtype eq 0) then begin
    tmp = tmp+strmid(pad,0,length-strlen(tmp))
    endif

  if (strlen(tmp) lt length) and (padtype eq 1) then begin
    tmp = strmid(pad,0,length-strlen(tmp))+tmp
    endif

  if (strlen(tmp) lt length) and (padtype eq 2) then begin
    padln=length-strlen(tmp) & padfr=padln/2 & padend=padln-padfr
    tmp=strmid(pad,0,padfr)+tmp+strmid(pad,0,padend)
    endif

  return,tmp
end
