FUNCTION Scale_Vector, vector, minRange, maxRange, $
   MAXVALUE=vectorMax, MINVALUE=vectorMin, NAN=nan

On_Error, 1

   ; Check positional parameters.

CASE N_Params() OF
   0: Message, 'Incorrect number of arguments.'
   1: BEGIN
      minRange = 0.0
      maxRange = 1.0
      ENDCASE
   2: BEGIN
      maxRange = 1.0 > (minRange + 0.0001)
      ENDCASE
   ELSE:
ENDCASE

   ; Make sure we are working with floating point numbers.

minRange = Float( minRange )
maxRange = Float( maxRange )

   ; Make sure we have a valid range.
IF maxRange EQ minRange THEN Message, 'Range max and min are coincidental'

   ; Check keyword parameters.

IF N_Elements(vectorMin) EQ 0 THEN vectorMin = Float( Min(vector, NAN=Keyword_Set(nan)) ) $
   ELSE vectorMin = Float( vectorMin )
IF N_Elements(vectorMax) EQ 0 THEN vectorMax = Float( Max(vector, NAN=Keyword_Set(nan)) ) $
   ELSE vectorMax = Float( vectorMax )

   ; Trim vector before scaling.

index = Where(Finite(vector) EQ 1, count)
IF count NE 0 THEN BEGIN
   trimVector = vector
   trimVector[index]  =  vectorMin >  (vector[index]) < vectorMax
ENDIF ELSE trimVector = vectorMin > vector < vectorMax

   ; Calculate the scaling factors.

scaleFactor = [((minRange * vectorMax)-(maxRange * vectorMin)) / $
    (vectorMax - vectorMin), (maxRange - minRange) / (vectorMax - vectorMin)]

   ; Return the scaled vector.

RETURN, trimVector * scaleFactor[1] + scaleFactor[0]

END ;-------------------------------------------------------------------------

FUNCTION WaveNumberFormat, axis, index, value
   RETURN, String(1.0/(value * 1e-5), Format='(I9)') ; Format as an integer.
END ;--------------------------------------------------------------------------------

PRO test

   xdata = Findgen(11)+1
   xdata = Scale_Vector(xdata, 0.534, 6.23) ; Wavelength between 0.534mm and 6.23mm.
   ydata = RandomU(seed, 11) * 30

   xwavelengthRange = [0.534, 6.23] ; In millimeters

   Window, XSize=750, YSize=300
   Plot, xdata, ydata, XStyle=9, XTitle='Wave Length (mm)', $
      Position=[0.15, 0.15, 0.9, 0.85], XRange=xwavelengthRange, Charsize=1.25
   Axis, XAxis=1.0, XTitle='Wave Number (' + String(197B) + ')', $
      XRange=xwavelengthRange, XStyle=1, Charsize=1.25, XTickFormat='WaveNumberFormat'

END
