
;-----------------------------------------------------------------------
; NAME: blackbody
;
; PURPOSE: create a blackbody spectrum
;
; INPUT :   l   : wavelengths in meters, vector, float
;           T   : temperature in Kelvin, scalar, float
;
; OUTPUT : returns a scalar or vector of same length as l of type
;          float with the blackbody spectrum
;
; ON ERROR : no error checking
;
; NOTES : the unit is 
;
; STATUS : tested
;
; HISTORY : 10.8.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

function blackbody, l, T

   h = 6.626E-34   ; Plnacks constant
   k = 1.381E-23   ; Boltzmann constant
   c = 2.998E8     ; speed of light

   return,(8.E7*!PI*h*c/float(l^5))/(exp(h*c/(k*float(T)*float(l)))-1.)

end
