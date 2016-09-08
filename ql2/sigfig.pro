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
;
; 24 Oct 2007 - If result is a single number, return scalar value
;               instead of an 1-element array. Thanks Mike Liu.
;  2 Apr 2008 - Fixed 1-element array issue, but for real this time.
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
move = move < (len-1)

;;; Create a string with just the digits, no decimal
nodec = strmid(numin, 0, 1)+strmid(numin, 2, len)

;;; Move the decimal, so nsig digits are to the left of the new
;;; decimal position
num0 = strmid(nodec,0,1+move)+'.'+strmid(nodec,1+move,len)

;;; Round the new number
num1 = sf_str(round(double(num0),/l64))
len1 = strlen(num1)

;;; If the number increases an order of magnitude after rounding, set
;;; order_inc=1 so the calling routine knows to add one to the order 
;;; of magnitude
order_inc = len1 gt nsig
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

;;; What are the orders of magnitude of the values?
Order = fix(sf_str(strmid(TestString, Epos+2, 2)))

;;; Convert all values to order unity for rounding
NumUnit = strmid(TestString,0,epos)

;;; Use TRANS_DEC to round unit values
NumTrans = sf_trans_dec(NumUnit, Nfig, order_inc=Order_Inc)
Order = order + Osign*order_inc
Len = strlen(NumTrans[0])

;;; Exit early without looping for /NUMERICAL or /SCIENTIFIC
if keyword_set(numerical) then begin
    NumRound = NegSign+NumTrans+'e'+StrOsign+sf_str(Order)
    if n_elements(NumRound) eq 1 then return, double(NumRound[0]) else $
      return, double(NumRound)
endif
if keyword_set(scientific) then begin
    NumRound = NegSign+NumTrans+'e'+StrOsign+sf_str(Order)
    if n_elements(NumRound) eq 1 then return, NumRound[0] else $
      return, NumRound
endif

NumRound = strarr(Nel)
for i = 0, Nel-1 do begin
    if Osign[i]*Order[i]+1 gt Nfig then Format = '(I40)' else begin
        d = sf_str(fix(Nfig-(Osign[i]*Order[i])-1) > 0)
        Format = '(F40.' + d + ')'
    endelse
    New = NumTrans[i] * 10d^(Osign[i] * Order[i])
    NumRound[i] = NegSign[i]+sf_str(New, format=Format)
endfor
if n_elements(NumRound) eq 1 then return, NumRound[0]
return, NumRound
end
