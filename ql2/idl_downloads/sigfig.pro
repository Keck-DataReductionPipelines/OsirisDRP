;+
; NAME:
;        SIGFIG
;
;
; PURPOSE:
;        Accept a scalar numerical value or an array of numbers and
;        return the numbers as strings with the specified number of
;        significant figures.
;
; CALLING SEQUENCE:
;        RESULT = SigFig(Number, Nfig [, /SCIENTIFIC, /PLUSSES, /NUMERICAL)
;
; INPUTS:
;        Number - Scalar or array of numerical values (float, double, int)
;        Nfig   - Number of signficant figures desired in the output
;
; OUTPUTS:
;        String representation of the input with the specified number
;        of signficant figures.
;
; KEYWORD PARAMTERS:
;        /SCIENTIFIC - return the numbers in scientific notation
;        /PLUSSES    - Include plus signs for positive numbers 
;        /NUMERICAL  - Return numerical, rather than string, values
;
; RESTRICTIONS:
;        This only works with IDL 6.0 or later. Use Erik Rosolosky's
;        SIGFIG for earlier versions of IDL.
;
; EXAMPLE:
;        IDL> print, sigfig(-0.0001234, 2)      
;        -0.00012
;        IDL> print, sigfig(1.234, 1)
;        1.
;        IDL> print, sigfig(1234, 1) 
;        1000
;        IDL> print, sigfig(-0.0001234, 2, /sci)
;        -1.2e-4
;        IDL> print, sigfig(1234, 2, /plus)
;        +1200
;        IDL> print, sigfig(1234, 2, /plus, /sci)
;        +1.2e+3
;
; MODIFICATION HISTORY:
; Inspired long ago by Erik Rosolowsky's SIGFIG:
;     http://www.cfa.harvard.edu/~erosolow/idl/lib/lib.html#SIGFIG
;
; This version written by JohnJohn Sept 29, 2005
;-

;;; SF_STR - The way STRING() should behave by default
function sf_str, stringin, format=format
return, strcompress(string(stringin, format=format), /rem)
end

;;; SF_TRANS_DEC - TRANSlate the DECimal point in a number of order
;;;                unity, round it, and translate back. 
function sf_trans_dec, numin, nsigin, order_inc=order_inc
nel = n_elements(numin)

;;; Double precision can't handle more than 19 sig figs
nsig = nsigin < 19

;;; Gonna have to move the decimal nsig-1 places to the right before rounding
move = nsig-1
len = max(strlen(numin))

;;; Pad with zeros if the move is too large
move = move < (len-1)

;;; Create a string with just the digits, no decimal
;nodec = strjoin(strsplit(num,'.',/ext), '')
nodec = strmid(numin, 0, 1)+strmid(numin, 2, len)

;;; Move the decimal, so nsig digits are to the left of the new
;;; decimal position
num0 = strmid(nodec,0,1+move)+'.'+strmid(nodec,1+move,len)

;;; Round the new number
num1 = strcompress(round(double(num0),/l64), /rem)
len1 = strlen(num1)

;;; If the number needs to be rounded up to 10., then set the
;;; order_inc keyword so the calling routine knows to add one to the
;;; order of magnitude
test1 = string(round(double(num0)))
test2 = string(fix(double(num0)))
cond = strmid(test1, 0, 1) eq '1' and strmid(test2, 0, 1) eq '9'
order_inc = fltarr(nel)
w = where(cond, nc)
if nc gt 0 then order_inc[w] = 1
;;; Move the decimal back and return to sender
num  = strmid(num1, 0, 1)+'.'+strmid(num1, 1, nsig-1)
return, num
end

function sigfig, NumIn, Nfig $
                 , string_return=string_return $
                 , scientific=scientific $
                 , numerical=numerical $
                 , plusses=plusses

Num = double(NumIn)
Nel = n_elements(Num)

;;; Convert the input number to scientific notation
TestString = sf_str(abs(double(Num)), format='(e)')
Epos = strpos(TestString[0], 'e')

;;; Test sign of the order
Osign = intarr(Nel)+1
StrOsign = strmid(TestString, Epos+1, 1)
Wneg = where(strosign eq '-', Nneg) 
if Nneg gt 0 then Osign[Wneg] = -1

;;; Test sign of numbers, form string of minus signs for negative vals
NegSign = strarr(Nel) + (keyword_set(plusses) ? '+' : '')
Negative = where(Num lt 0, Nneg)
if Nneg gt 0 then NegSign[Negative] = '-'

;;; What's the order of magnitude of the values?
Order = fix(sf_str(strmid(TestString, Epos+2, 2)))

;;; Initialize some parameters
;;; Make all values of order unity for rounding
NumUnit = strmid(teststring,0,epos)

;;; Use TRANS_DEC to round unit values
NumTrans = sf_trans_dec(NumUnit, Nfig)
Len = strlen(NumTrans[0])

if keyword_set(numerical) then begin
    NumRound = NegSign+NumTrans+'e'+StrOsign+sf_str(order)
    return, double(NumRound)
endif
if keyword_set(scientific) then begin
    NumRound = NegSign+NumTrans+'e'+StrOsign+sf_str(order)
    return, NumRound
endif

;;; Make all values of order unity for rounding
NumUnit = strmid(teststring,0,epos)

;;; Use TRANS_DEC to round unit values
NumTrans = sf_trans_dec(NumUnit, Nfig, order_inc=order_inc)
order=order+order_inc

;;; Remove decimal point
NumNoDec = strmid(NumTrans,0,1)+strmid(NuMTrans,2,Len)

;;; Initialize the output array
NumRound = strarr(Nel)

;;; There are four cases to test:

w = where(order eq 0, nw)
if nw gt 0 then NumRound[w] = NegSign[w]+NumTrans[w]

w = where(order eq 1 and osign lt 0, nw)
if nw gt 0 then NumRound[w] = NegSign[w]+'0.'+NumNoDec[w]

w = where(order gt 1 and osign lt 0, nw)
if nw gt 0 then begin
    Dif = order[w] - 1 
    NumRound[w] = NegSign[w]+'0.'+strjoin(strarr(Dif)+'0','')+NumNoDec[w]
endif

w = where(order lt Len - 1 and osign gt 0, nw)
if nw gt 0 then begin
    NumRound[w] = NegSign[w]+strmid(NumNoDec[w], 0, transpose(order[w])+1)
    w1 = where(len gt order[w]+1, nw1, comp=comp)
    if nw1 gt 0 then $
      NumRound[w[w1]]=NumRound[w[w1]]+'.'+strmid(NumNoDec[w[w1]], transpose(order[w[w1]])+1, Len)
endif

w = where(order ge Len - 1 and osign gt 0, nw)
if nw gt 0 then begin
    NumNoDec=NumNoDec+strjoin(strarr((order[w]-Len+2)[0])+'0','')
    NumRound[w] = NegSign[w]+strmid(NumNoDec[w], 0, transpose(order[w])+1)
    w1 = where(len gt order+1, nw1, comp=comp)
    if nw1 gt 0 then $
      NumRound[w[w1]]=NumRound[w[w1]]+'.'+strmid(NumNoDec[w[w1]], transpose(order[w[w1]])+1, Len)
endif

;;; Return an array or a scalar depending on input
if Nel eq 1 then return,NumRound[0] else return, NumRound
end
