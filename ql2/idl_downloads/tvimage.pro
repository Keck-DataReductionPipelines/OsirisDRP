;+
; NAME:
;     TVIMAGE
;
; PURPOSE:
;     This purpose of TVIMAGE is to enable the TV command in IDL
;     to be a completely device-independent and color-decomposition-
;     state independent command. On 24-bit displays color decomposition
;     is always turned off for 8-bit images and on for 24-bit images.
;     The color decomposition state is restored for those versions of
;     IDL that support it (> 5.2). Moreover, TVIMAGE adds features
;     that TV lacks. For example, images can be positioned in windows
;     using the POSITION keyword like other IDL graphics commands.
;     TVIMAGE also supports the !P.MULTI system variable, unlike the
;     TV command. TVIMAGE was written to work especially well in
;     resizeable graphics windows. Note that if you wish to preserve
;     the aspect ratio of images in resizeable windows, you should set
;     the KEEP_ASPECT_RATIO keyword, described below. TVIMAGE works
;     equally well on the display, in the PostScript device, and in
;     the Printer and Z-Graphics Buffer devices. The TRUE keyword is
;     set automatically to the correct value for 24-bit images, so you
;     don't need to specify it when using TVIMAGE.
;
; AUTHOR:
;       FANNING SOFTWARE CONSULTING:
;       David Fanning, Ph.D.
;       1645 Sheely Drive
;       Fort Collins, CO 80526 USA
;       Phone: 970-221-0438
;       E-mail: davidf@dfanning.com
;       Coyote's Guide to IDL Programming: http://www.dfanning.com/
;
; CATEGORY:
;     Graphics display.
;
; CALLING SEQUENCE:
;
;     TVIMAGE, image
;
; INPUTS:
;     image:    A 2D or 3D image array. It should be byte data.
;
;       x  :    The X position of the lower-left corner of the image.
;               This parameter is only recognized if the TV keyword is set.
;               If the Y position is not used, X is taken to be the image
;               "position" in the window. See the TV command documenation
;               for details.
;
;       y  :    The Y position of the lower-left corner of the image.
;               This parameter is only recognized if the TV keyword is set.
;
; KEYWORD PARAMETERS:
;
;     BACKGROUND:   This keyword specifies the background color. Note that
;               the keyword ONLY has effect if the ERASE keyword is also
;               set or !P.MULTI is set to multiple plots and TVIMAGE is
;               used to place the *first* plot.
;
;     ERASE:    If this keyword is set an ERASE command is issued
;               before the image is displayed. Note that the ERASE
;               command puts the image on a new page in PostScript
;               output.
;
;     _EXTRA:   This keyword picks up any TV keywords you wish to use.
;
;     HALF_HALF: If set, will tell CONGRID to extrapolate a *half* row
;               and column on either side, rather than the default of
;               one full row/column at the ends of the array.  If you
;               are interpolating images with few rows, then the
;               output will be more consistent with this technique.
;               This keyword is intended as a replacement for
;               MINUS_ONE, and both keywords probably should not be
;               used in the same call to CONGRID.
;
;     KEEP_ASPECT_RATIO: Normally, the image will be resized to fit the
;               specified position in the window. If you prefer, you can
;               force the image to maintain its aspect ratio in the window
;               (although not its natural size) by setting this keyword.
;               The image width is fitted first. If, after setting the
;               image width, the image height is too big for the window,
;               then the image height is fitted into the window. The
;               appropriate values of the POSITION keyword are honored
;               during this fitting process. Once a fit is made, the
;               POSITION coordiates are re-calculated to center the image
;               in the window. You can recover these new position coordinates
;               as the output from the POSITION keyword.
;
;     MARGIN:   A single value, expressed as a normalized coordinate, that
;               can easily be used to calculate a position in the window.
;               The margin is used to calculate a POSITION that gives
;               the image an equal margin around the edge of the window.
;               The margin must be a number in the range 0.0 to 0.333. This
;               keyword is ignored if the POSITION or OVERPLOT keywords are
;               used. It is also ignormed when TVImage is executed in a
;               multi-plot window, EXCEPT if it's value is zero. In this
;               special case, the image will be drawn into its position in
;               the multi-plot window with no margins whatsoever. (The
;               default is to have a slight margin about the image to separate
;               it from other images or graphics.
;
;
;     MINUS_ONE: The value of this keyword is passed along to the CONGRID
;               command. It prevents CONGRID from adding an extra row and
;               column to the resulting array, which can be a problem with
;               small image arrays.
;
;     NOINTERPOLATION: Setting this keyword disables the default bilinear
;               interpolation done to the image when it is resized. Nearest
;               neighbor interpolation is done instead. This is preferred
;               when you do not wish to change the pixel values of the image.
;               This keyword must be set, for example, when you are displaying
;               GIF files that come with their own non-IDL color table vectors.
;
;     NORMAL:   Setting this keyword means image position coordinates x and y
;               are interpreted as being in normalized coordinates. This keyword
;               is only valid if the TV keyword is set.
;
;     OVERPLOT: Setting this keyword causes the POSITION keyword to be ignored
;               and the image is positioned in the location established by the
;               last graphics command. For example:
;
;                    Plot, Findgen(11), Position=[0.1, 0.3, 0.8, 0.95]
;                    TVImage, image, /Overplot
;
;     POSITION: The location of the image in the output window. This is
;               a four-element floating array of normalized coordinates of
;               the type given by !P.POSITION or the POSITION keyword to
;               other IDL graphics commands. The form is [x0, y0, x1, y1].
;               The default is [0.0, 0.0, 1.0, 1.0]. Note that this can
;               be an output parameter if the KEEP_ASPECT_RATIO keyword is
;               used.
;
;     TV:       Setting this keyword makes the TVIMAGE command work much
;               like the TV command, although better. That is to say, it
;               will still set the correct DECOMPOSED state depending upon
;               the kind of image to be displayed (8-bit or 24-bit). It will
;               also allow the image to be "positioned" in the window by
;               specifying the coordinates of the lower-left corner of the
;               image. The NORMAL keyword is activated when the TV keyword
;               is set, which will indicate that the position coordinates
;               are given in normalized coordinates rather than device
;               coordinates.
;
;               Setting this keyword will ensure that the keywords
;               KEEP_ASPECT_RATIO, MARGIN, MINUS_ONE, MULTI, and POSITION
;               are ignored.
;
; OUTPUTS:
;     None.
;
; SIDE EFFECTS:
;     Unless the KEEP_ASPECT_RATIO keyword is set, the displayed image
;     may not have the same aspect ratio as the input data set.
;
; RESTRICTIONS:
;     If the POSITION keyword and the KEEP_ASPECT_RATIO keyword are
;     used together, there is an excellent chance the POSITION
;     parameters will change. If the POSITION is passed in as a
;     variable, the new positions will be returned in the same variable
;     as an output parameter.
;
;     If a 24-bit image is displayed on an 8-bit display, the
;     24-bit image must be converted to an 8-bit image and the
;     appropriate color table vectors. This is done with the COLOR_QUAN
;     function. The TVIMAGE command will load the color table vectors
;     and set the NOINTERPOLATION keyword if this is done. Note that the
;     resulting color table vectors are normally incompatible with other
;     IDL-supplied color tables. Hence, other graphics windows open at
;     the time the image is display are likely to look strange.
;
; EXAMPLE:
;     To display an image with a contour plot on top of it, type:
;
;        filename = FILEPATH(SUBDIR=['examples','data'], 'worldelv.dat')
;        image = BYTARR(360,360)
;        OPENR, lun, filename, /GET_LUN
;        READU, lun, image
;        FREE_LUN, lun
;
;        TVIMAGE, image, POSITION=thisPosition, /KEEP_ASPECT_RATIO
;        CONTOUR, image, POSITION=thisPosition, /NOERASE, XSTYLE=1, $
;            YSTYLE=1, XRANGE=[0,360], YRANGE=[0,360], NLEVELS=10
;
;     To display four images in a window without spacing between them:
;
;     !P.Multi=[0,2,2]
;     TVImage, image, Margin=0
;     TVImage, image, Margin=0
;     TVImage, image, Margin=0
;     TVImage, image, Margin=0
;     !P.Multi = 0
;
; MODIFICATION HISTORY:
;      Written by:     David Fanning, 20 NOV 1996.
;      Fixed a small bug with the resizing of the image. 17 Feb 1997. DWF.
;      Removed BOTTOM and NCOLORS keywords. This reflects my growing belief
;         that this program should act more like TV and less like a "color
;         aware" application. I leave "color awareness" to the program
;         using TVIMAGE. Added 24-bit image capability. 15 April 1997. DWF.
;      Fixed a small bug that prevented this program from working in the
;          Z-buffer. 17 April 1997. DWF.
;      Fixed a subtle bug that caused me to think I was going crazy!
;          Lession learned: Be sure you know the *current* graphics
;          window! 17 April 1997. DWF.
;      Added support for the PRINTER device. 25 June 1997. DWF.
;      Extensive modifications. 27 Oct 1997. DWF
;          1) Removed PRINTER support, which didn't work as expected.
;          2) Modified Keep_Aspect_Ratio code to work with POSITION keyword.
;          3) Added check for window-able devices (!D.Flags AND 256).
;          4) Modified PostScript color handling.
;      Craig Markwart points out that Congrid adds an extra row and column
;          onto an array. When viewing small images (e.g., 20x20) this can be
;          a problem. Added a Minus_One keyword whose value can be passed
;          along to the Congrid keyword of the same name. 28 Oct 1997. DWF
;      Changed default POSITION to fill entire window. 30 July 1998. DWF.
;      Made sure color decomposition is OFF for 2D images. 6 Aug 1998. DWF.
;      Added limited PRINTER portrait mode support. The correct aspect ratio
;          of the image is always maintained when outputting to the
;          PRINTER device and POSITION coordinates are ignored. 6 Aug 1998. DWF
;      Removed 6 August 98 fixes (Device, Decomposed=0) after realizing that
;          they interfere with operation in the Z-graphics buffer. 9 Oct 1998. DWF
;      Added a MARGIN keyword. 18 Oct 1998. DWF.
;      Re-established Device, Decomposed=0 keyword for devices that
;         support it. 18 Oct 1998. DWF.
;      Added support for the !P.Multi system variable. 3 March 99. DWF
;      Added DEVICE, DECOMPOSED=1 command for all 24-bit images. 2 April 99. DWF.
;      Added ability to preserve DECOMPOSED state for IDL 5.2 and higher. 4 April 99. DWF.
;      Added TV keyword to allow TVIMAGE to work like the TV command. 11 May 99. DWF.
;      Added the OVERPLOT keyword to allow plotting on POSITION coordinates
;         estabished by the preceding graphics command. 11 Oct 99. DWF.
;      Added automatic recognition of !P.Multi. Setting MULTI keyword is no
;         longer required. 18 Nov 99. DWF.
;      Added NOINTERPOLATION keyword so that nearest neighbor interpolation
;         is performed rather than bilinear. 3 Dec 99. DWF
;      Changed ON_ERROR condition from 1 to 2. 19 Dec 99. DWF.
;      Added Craig Markwardt's CMCongrid program and removed RSI's. 24 Feb 2000. DWF.
;      Added HALF_HALF keyword to support CMCONGRID. 24 Feb 2000. DWF.
;      Fixed a small problem with image start position by adding ROUND function. 19 March 2000. DWF.
;      Updated the PRINTER device code to take advantage of available keywords. 2 April 2000. DWF.
;      Reorganized the code to handle 24-bit images on 8-bit displays better. 2 April 2000. DWF.
;      Added BACKGROUND keyword. 20 April 2000. DWF.
;      Fixed a small problem in where the ERASE was occuring. 6 May 2000. DWF.
;      Rearranged the PLOT part of code to occur before decomposition state
;         is changed to fix Background color bug in multiple plots. 23 Sept 2000. DWF.
;      Removed MULTI keyword, which is no longer needed. 23 Sept 2000. DWF.
;      Fixed a small problem with handling images that are slices from 3D image cubes. 5 Oct 2000. DWF.
;      Added fix for brain-dead Macs from Ben Tupper that restores Macs ability to
;         display images. 8 June 2001. DWF.
;      Fixed small problem with multiple plots and map projections. 29 June 2003. DWF.
;      Converted all array subscripts to square brackets. 29 June 2003. DWF.
;      Removed obsolete STR_SEP and replaced with STRSPLIT. 27 Oct 2004. DWF.
;      Small modification at suggestion of Karsten Rodenacker to increase size of
;         images in !P.MULTI mode. 8 December 2004. DWF.
;      Minor modifications on Karsten Rodenacker's own account concerning margination
;         and TV behaviour. 8 December 2004. KaRo
;-
;
;###########################################################################
;
; LICENSE
;
; This software is OSI Certified Open Source Software.
; OSI Certified is a certification mark of the Open Source Initiative.
;
; Copyright � 2000-2004 Fanning Software Consulting.
;
; This software is provided "as-is", without any express or
; implied warranty. In no event will the authors be held liable
; for any damages arising from the use of this software.
;
; Permission is granted to anyone to use this software for any
; purpose, including commercial applications, and to alter it and
; redistribute it freely, subject to the following restrictions:
;
; 1. The origin of this software must not be misrepresented; you must
;    not claim you wrote the original software. If you use this software
;    in a product, an acknowledgment in the product documentation
;    would be appreciated, but is not required.
;
; 2. Altered source versions must be plainly marked as such, and must
;    not be misrepresented as being the original software.
;
; 3. This notice may not be removed or altered from any source distribution.
;
; For more information on Open Source Software, visit the Open Source
; web site: http://www.opensource.org.
;
;###########################################################################
;
; NAME:
;  CMCONGRID
;
; PURPOSE:
;       Shrink or expand the size of an array by an arbitrary amount.
;       This IDL procedure simulates the action of the VAX/VMS
;       CONGRID/CONGRIDI function.
;
;  This function is similar to "REBIN" in that it can resize a
;       one, two, or three dimensional array.   "REBIN", however,
;       requires that the new array size must be an integer multiple
;       of the original size.   CONGRID will resize an array to any
;       arbitrary size (REBIN is somewhat faster, however).
;       REBIN averages multiple points when shrinking an array,
;       while CONGRID just resamples the array.
;
; CATEGORY:
;       Array Manipulation.
;
; CALLING SEQUENCE:
;  array = CONGRID(array, x, y, z)
;
; INPUTS:
;       array:  A 1, 2, or 3 dimensional array to resize.
;               Data Type : Any type except string or structure.
;
;       x:      The new X dimension of the resized array.
;               Data Type : Int or Long (greater than or equal to 2).
;
; OPTIONAL INPUTS:
;       y:      The new Y dimension of the resized array.   If the original
;               array has only 1 dimension then y is ignored.   If the
;               original array has 2 or 3 dimensions then y MUST be present.
;
;       z:      The new Z dimension of the resized array.   If the original
;               array has only 1 or 2 dimensions then z is ignored.   If the
;               original array has 3 dimensions then z MUST be present.
;
; KEYWORD PARAMETERS:
;       INTERP: If set, causes linear interpolation to be used.
;               Otherwise, the nearest-neighbor method is used.
;
;       CUBIC:  If set, uses "Cubic convolution" interpolation.  A more
;               accurate, but more time-consuming, form of interpolation.
;               CUBIC has no effect when used with 3 dimensional arrays.
;
;       MINUS_ONE:
;               If set, will prevent CONGRID from extrapolating one row or
;               column beyond the bounds of the input array.   For example,
;               If the input array has the dimensions (i, j) and the
;               output array has the dimensions (x, y), then by
;               default the array is resampled by a factor of (i/x)
;               in the X direction and (j/y) in the Y direction.
;               If MINUS_ONE is present (AND IS NON-ZERO) then the array
;               will be resampled by the factors (i-1)/(x-1) and
;               (j-1)/(y-1).
;
;       HALF_HALF:
;               If set, will tell CONGRID to extrapolate a *half* row
;               and column on either side, rather than the default of
;               one full row/column at the ends of the array.  If you
;               are interpolating images with few rows, then the
;               output will be more consistent with this technique.
;               This keyword is intended as a replacement for
;               MINUS_ONE, and both keywords probably should not be
;               used in the same call to CONGRID.
;
; OUTPUTS:
;  The returned array has the same number of dimensions as the original
;       array and is of the same data type.   The returned array will have
;       the dimensions (x), (x, y), or (x, y, z) depending on how many
;       dimensions the input array had.
;
; PROCEDURE:
;       IF the input array has three dimensions, or if INTERP is set,
;       then the IDL interpolate function is used to interpolate the
;       data values.
;       If the input array has two dimensions, and INTERP is NOT set,
;       then the IDL POLY_2D function is used for nearest neighbor sampling.
;       If the input array has one dimension, and INTERP is NOT set,
;       then nearest neighbor sampling is used.
;
; EXAMPLE:
;       ; vol is a 3-D array with the dimensions (80, 100, 57)
;       ; Resize vol to be a (90, 90, 80) array
;       vol = CONGRID(vol, 90, 90, 80)
;
; MODIFICATION HISTORY:
;       DMS, Sept. 1988.
;       DMS, Added the MINUS_ONE keyword, Sept. 1992.
;  Daniel Carr. Re-wrote to handle one and three dimensional arrays
;                    using INTERPOLATE function.
;  DMS, RSI, Nov, 1993.  Added CUBIC keyword.
;       Craig Markwardt, Dec, 1997.  Added halfhalf keyword to
;                        more evenly distribute "dead" pixel row
;       Use uniformly spaced grid points for half_half W. Landsman   Feb. 2000
;              (and slightly modified by C. Markwardt 14 Feb 2000)
;


FUNCTION CMCONGRID, arr, x, y, z, Interp=int, Minus_One=m1, Cubic = cubic, $
                    Half_Half=hh

ON_ERROR, 2    ;Return to caller if error
s = Size(arr)

IF ((s[0] EQ 0) OR (s[0] GT 3)) THEN $
   Message, 'Array must have 1, 2, or 3 dimensions.'

;  Supply defaults = no interpolate, and no minus_one.
if n_elements(int) le 0 then int = 0 else int = keyword_set(int)
if n_elements(m1) le 0 then m1 = 0 else m1 = keyword_set(m1)

; Compute offsets pixel offsets for half_half
halfx = 0.0 & halfy = 0.0 & halfz = 0.0
if keyword_set(hh) then begin
    if s[0] GE 1 then halfx = -0.5 + (float(s[1])/x)
    if s[0] GE 2 then halfy = -0.5 + (float(s[2])/y)
    if s[0] GE 3 then halfz = -0.5 + (float(s[3])/z)
endif
cub = KEYWORD_SET(cubic)
if cub THEN int = 1  ;Cubic implies interpolate


CASE s[0] OF
   1: BEGIN          ; *** ONE DIMENSIONAL ARRAY
   srx = float(s[1] - m1)/(x-m1) * findgen(x) + halfx
      IF int THEN $
         RETURN, INTERPOLATE(arr, srx, CUBIC = cub) ELSE $
         RETURN, arr(ROUND(srx))
   ENDCASE
   2: BEGIN ; *** TWO DIMENSIONAL ARRAY
   IF int THEN BEGIN
     srx = float(s[1] - m1) / (x-m1) * findgen(x) + halfx
     sry = float(s[2] - m1) / (y-m1) * findgen(y) + halfy
          RETURN, INTERPOLATE(arr, srx, sry, /GRID, CUBIC=cub)
   ENDIF ELSE $
     RETURN, POLY_2D(arr, $
      [[0,0],[(s[1]-m1)/float(x-m1),0]], $ ;Use poly_2d
      [[0,(s[2]-m1)/float(y-m1)],[0,0]],int,x,y)

   ENDCASE
   3: BEGIN ; *** THREE DIMENSIONAL ARRAY
   srx = float(s[1] - m1) / (x-m1) * findgen(x) + halfx
   sry = float(s[2] - m1) / (y-m1) * findgen(y) + halfy
   srz = float(s[3] - m1) / (z-m1) * findgen(z) + halfz
   RETURN, interpolate(arr, srx, sry, srz, /grid)
   ENDCASE
ENDCASE

RETURN, arr_r
END
;--------------------------------------------------------------------------



FUNCTION TVIMAGE_ERROR, theMessage, Traceback=traceback, NoName=noName, _Extra=extra

On_Error, 2

   ; Check for presence and type of message.

IF N_Elements(theMessage) EQ 0 THEN theMessage = !Error_State.Msg
s = Size(theMessage)
messageType = s[s[0]+1]
IF messageType NE 7 THEN BEGIN
   Message, "The message parameter must be a string.", _Extra=extra
ENDIF

   ; Get the call stack and the calling routine's name.

Help, Calls=callStack
callingRoutine = (StrSplit(StrCompress(callStack[1])," ", /Extract))[0]

   ; Are widgets supported? Doesn't matter in IDL 5.3 and higher.

widgetsSupported = ((!D.Flags AND 65536L) NE 0) OR Float(!Version.Release) GE 5.3
IF widgetsSupported THEN BEGIN
   IF Keyword_Set(noName) THEN answer = Dialog_Message(theMessage, _Extra=extra) ELSE BEGIN
      IF StrUpCase(callingRoutine) EQ "$MAIN$" THEN answer = Dialog_Message(theMessage, _Extra=extra) ELSE $
         answer = Dialog_Message(StrUpCase(callingRoutine) + ": " + theMessage, _Extra=extra)
   ENDELSE
ENDIF ELSE BEGIN
      Message, theMessage, /Continue, /NoPrint, /NoName, /NoPrefix, _Extra=extra
      Print, '%' + callingRoutine + ': ' + theMessage
      answer = 'OK'
ENDELSE

   ; Provide traceback information if requested.

IF Keyword_Set(traceback) THEN BEGIN
   Help, /Last_Message, Output=traceback
   Print,''
   Print, 'Traceback Report from ' + StrUpCase(callingRoutine) + ':'
   Print, ''
   FOR j=0,N_Elements(traceback)-1 DO Print, "     " + traceback[j]
   Print, ''
ENDIF

RETURN, answer
END



pro tvimage, image, x, y, $
   BACKGROUND=background, $
   ERASE=eraseit, $
   HALF_HALF=half_half, $
   KEEP_ASPECT_RATIO=keep, $
   MARGIN=margin, $
   MINUS_ONE=minusOne, $
   NOINTERPOLATION=nointerp, $
   NORMAL=normal, $
   POSITION=position, $
   OVERPLOT=overplot, $
   TV=tv, $
   _EXTRA=extra

   ; Error handling.

Catch, theError
IF theError NE 0 THEN BEGIN
   Catch, /Cancel
   ok = TVIMAGE_ERROR(Traceback=1, /Error)
   RETURN
ENDIF

   ; Check for image parameter and keywords.

IF N_Elements(image) EQ 0 THEN MESSAGE, 'You must pass a valid image argument.', /NoName
interp = 1.0 - Keyword_Set(nointerp)
half_half = Keyword_Set(half_half)
minusOne = Keyword_Set(minusOne)
IF N_Elements(background) EQ 0 THEN background = !P.Background
IF Keyword_Set(eraseit) THEN Erase, Color=background
IF (N_Elements(margin) GT 0) AND (Keyword_Set(margin) EQ 0) THEN vmargin=[0.,0.] ELSE vmargin=[1.,1.]

   ; Check image size.

s = Size(image)
IF s[0] LT 2 OR s[0] GT 3 THEN $
   MESSAGE, 'Argument does not appear to be an image. Returning...', /NoName

   ; Allow 24-bit images and 2D images that are sent in as 3D
   ; arrays where one dimension is a 1.

IF s[0] EQ 3 THEN BEGIN
   IF (s[1] NE 3L) AND (s[2] NE 3L) AND (s[3] NE 3L) THEN BEGIN
      IF (s[1] NE 1L) AND (s[2] NE 1L) AND (s[3] NE 1L) THEN BEGIN
         MESSAGE, 'Argument does not appear to be a 24-bit image. Returning...', /NoName
      ENDIF ELSE BEGIN
         IF s[1] EQ 1 THEN single = 1
         IF s[2] EQ 1 THEN single = 2
         IF s[3] EQ 1 THEN single = 3
         CASE single OF
            1: image = Reform(image, s[2], s[3])
            2: image = Reform(image, s[1], s[3])
            3: image = Reform(image, s[1], s[2])
         ENDCASE
         s = Size(image)
      ENDELSE
   ENDIF
ENDIF ELSE s = Size(image)

   ; Which release of IDL is this?

thisRelease = Float(!Version.Release)

   ; Doing multiple plots?

IF Total(!P.Multi) GT 0 THEN multi = 1 ELSE multi = 0

   ; Check for position and overplot keywords.

IF N_Elements(position) EQ 0 THEN BEGIN
   IF Keyword_Set(multi) AND (Keyword_Set(overplot) NE 1) THEN BEGIN
      Plot, Findgen(11), XStyle=4, YStyle=4, /NoData, Background=background, XMargin=vmargin, YMargin=vmargin
      position = [!X.Window[0], !Y.Window[0], !X.Window[1], !Y.Window[1]]
   ENDIF ELSE BEGIN
      IF Keyword_Set(overplot) THEN BEGIN
         position = [!X.Window[0], !Y.Window[0], !X.Window[1], !Y.Window[1]]
      ENDIF ELSE position = [0.0, 0.0, 1.0, 1.0]
   ENDELSE
ENDIF ELSE BEGIN
   IF Keyword_Set(multi) AND (Keyword_Set(overplot) NE 1)THEN BEGIN
      Plot, Findgen(11), XStyle=4, YStyle=4, /NoData, Background=background, XMargin=vmargin, YMargin=vmargin
      position = [!X.Window[0], !Y.Window[0], !X.Window[1], !Y.Window[1]]
   ENDIF ELSE BEGIN
      IF Keyword_Set(overplot) THEN BEGIN
         position = [!X.Window[0], !Y.Window[0], !X.Window[1], !Y.Window[1]]
      ENDIF ELSE position = Float(position)
   ENDELSE
ENDELSE

   ; Check for margin keyword.


IF (Keyword_Set(multi) EQ 0) AND (Keyword_Set(overplot) EQ 0) THEN BEGIN
   IF N_Elements(margin) NE 0 THEN BEGIN
           margin = 0.0 > margin < 0.33
           position = [position[0] + margin, position[1] + margin, $
                       position[2] - margin, position[3] - margin]
   ENDIF
ENDIF

   ; 2D image.

IF s[0] EQ 2 THEN BEGIN

   imgXsize = FLOAT(s[1])
   imgYsize = FLOAT(s[2])
   true = 0

      ; Decomposed color off if device supports it.

   CASE  StrUpCase(!D.NAME) OF
        'X': BEGIN
            Device, Get_Visual_Depth=thisDepth
            IF thisRelease GE 5.2 THEN Device, Get_Decomposed=thisDecomposed
            Device, Decomposed=0
            ENDCASE
        'WIN': BEGIN

            Device, Get_Visual_Depth=thisDepth
            IF thisRelease GE 5.2 THEN Device, Get_Decomposed=thisDecomposed
            Device, Decomposed=0
            ENDCASE
        'MAC': BEGIN
            Device, Get_Visual_Depth=thisDepth
            IF thisRelease GE 5.2 THEN Device, Get_Decomposed=thisDecomposed
            Device, Decomposed=0
            ENDCASE
        ELSE: thisDepth = 8
   ENDCASE

ENDIF

   ; 3D image.

IF s[0] EQ 3 THEN BEGIN

   IF s[1] EQ 3 THEN true = 1 ; Pixel interleaved
   IF s[2] EQ 3 THEN true = 2 ; Row interleaved
   IF s[3] EQ 3 THEN true = 3 ; Band interleaved

   ; Decomposed color on if device supports it.

   CASE StrUpCase(!D.NAME) OF
      'X': BEGIN
         Device, Get_Visual_Depth=thisDepth
         IF thisRelease GE 5.2 THEN Device, Get_Decomposed=thisDecomposed
         IF thisDepth GT 8 THEN Device, Decomposed=1
         ENDCASE
      'WIN': BEGIN
         Device, Get_Visual_Depth=thisDepth
         IF thisRelease GE 5.2 THEN Device, Get_Decomposed=thisDecomposed
         IF thisDepth GT 8 THEN Device, Decomposed=1
         ENDCASE
      'MAC': BEGIN
         Device, Get_Visual_Depth=thisDepth
         IF thisRelease GE 5.2 THEN Device, Get_Decomposed=thisDecomposed
         IF thisDepth GT 8 THEN Device, Decomposed=1
         ENDCASE
      ELSE: thisDepth = 8
   ENDCASE

   CASE true OF
      1: BEGIN
         imgXsize = FLOAT(s[2])
         imgYsize = FLOAT(s[3])
         ENDCASE
      2: BEGIN
         imgXsize = FLOAT(s[1])
         imgYsize = FLOAT(s[3])
         ENDCASE
      3: BEGIN
         imgXsize = FLOAT(s[1])
         imgYsize = FLOAT(s[2])
         ENDCASE
   ENDCASE

ENDIF

   ; Check for TV keyword. If present, then act like a TV command.

IF Keyword_Set(tv) THEN BEGIN

   IF N_Params() GE 3 OR N_Params() EQ 1 THEN BEGIN
     IF N_Elements(x) EQ 0 THEN x = 0
     IF N_Elements(y) EQ 0 THEN y = 0
     IF Keyword_Set(normal) THEN TV, image, x, y, True=true, _Extra=extra, /Normal ELSE $
                                 TV, image, x, y, True=true, _Extra=extra, /Device
   ENDIF ELSE IF N_Params() GE 2 THEN BEGIN
     IF Keyword_Set(normal) THEN TV, image, x, True=true, _Extra=extra, /Normal ELSE $
                                 TV, image, x, True=true, _Extra=extra, /Device
   ENDIF
   GoTo, restoreDecomposed

ENDIF

   ; Maintain aspect ratio (ratio of height to width)?

IF KEYWORD_SET(keep) THEN BEGIN

      ; Find aspect ratio of image.

   ratio = FLOAT(imgYsize) / imgXSize

      ; Find the proposed size of the image in pixels without aspect
      ; considerations.

   xpixSize = (position(2) - position(0)) * !D.X_VSize
   ypixSize = (position(3) - position(1)) * !D.Y_VSize

      ; Try to fit the image width. If you can't maintain
      ; the aspect ratio, fit the image height.

   trialX = xpixSize
   trialY = trialX * ratio
   IF trialY GT ypixSize THEN BEGIN
      trialY = ypixSize
      trialX = trialY / ratio
   ENDIF

      ; Recalculate the position of the image in the window.

   position(0) = (((xpixSize - trialX) / 2.0) / !D.X_VSize) + position(0)
   position(2) = position(0) + (trialX/FLOAT(!D.X_VSize))
   position(1) = (((ypixSize - trialY) / 2.0) / !D.Y_VSize)  + position(1)
   position(3) = position(1) + (trialY/FLOAT(!D.Y_VSize))

ENDIF

   ; Calculate the image size and start locations.

xsize = (position(2) - position(0)) * !D.X_VSIZE
ysize = (position(3) - position(1)) * !D.Y_VSIZE
xstart = position(0) * !D.X_VSIZE
ystart = position(1) * !D.Y_VSIZE

   ; Display the image. Sizing different for scalable pixels devices.

IF (!D.Flags AND 1) NE 0 THEN BEGIN

      ; Need a gray-scale color table if this is a true
      ; color image.

   IF true GT 0 THEN LOADCT, 0, /Silent
   TV, image, xstart, ystart, XSIZE=xsize, $
      YSIZE=ysize, _EXTRA=extra, True=true

ENDIF ELSE BEGIN ; All other devices.

   CASE true OF
      0: TV, CMCONGRID(image, CEIL(xsize), CEIL(ysize), INTERP=interp, $
            MINUS_ONE=minusOne, HALF_HALF=half_half), ROUND(xstart), $
            ROUND(ystart), _EXTRA=extra
      1: IF thisDepth GT 8 THEN BEGIN
            TV, CMCONGRID(image, 3, CEIL(xsize), CEIL(ysize), INTERP=interp, $
               MINUS_ONE=minusOne, HALF_HALF=half_half), ROUND(xstart), $
               ROUND(ystart), _EXTRA=extra, True=1
         ENDIF ELSE BEGIN
            image2d = Color_Quan(image, 1, r, g, b, _Extra=extra)
            TVLCT, r, g, b
            TV, CMCONGRID(image2d, CEIL(xsize), CEIL(ysize), INTERP=0, $
               MINUS_ONE=minusOne, HALF_HALF=half_half), ROUND(xstart), $
               ROUND(ystart), _EXTRA=extra, True=0
         ENDELSE
      2: IF thisDepth GT 8 THEN BEGIN
            TV, CMCONGRID(image, CEIL(xsize), 3, CEIL(ysize), INTERP=interp, $
               MINUS_ONE=minusOne, HALF_HALF=half_half), ROUND(xstart), $
               ROUND(ystart), _EXTRA=extra, True=2
         ENDIF ELSE BEGIN
            image2d = Color_Quan(image, 2, r, g, b, _Extra=extra)
            TVLCT, r, g, b
            TV, CMCONGRID(image2d, CEIL(xsize), CEIL(ysize), INTERP=0, $
               MINUS_ONE=minusOne, HALF_HALF=half_half), ROUND(xstart), $
               ROUND(ystart), _EXTRA=extra, True=0
         ENDELSE
      3: IF thisDepth GT 8 THEN BEGIN
            TV, CMCONGRID(image, CEIL(xsize), CEIL(ysize), 3, INTERP=interp, $
               MINUS_ONE=minusOne, HALF_HALF=half_half), ROUND(xstart), $
               ROUND(ystart), _EXTRA=extra, True=3
         ENDIF ELSE BEGIN
            image2d = Color_Quan(image, 3, r, g, b, _Extra=extra)
            TVLCT, r, g, b
            TV, CMCONGRID(image2d, CEIL(xsize), CEIL(ysize), INTERP=0, $
               MINUS_ONE=minusOne, HALF_HALF=half_half), ROUND(xstart), $
               ROUND(ystart), _EXTRA=extra, True=0
         ENDELSE
  ENDCASE
ENDELSE

   ; Restore Decomposed state if necessary.

RestoreDecomposed:

CASE StrUpCase(!D.NAME) OF
   'X': BEGIN
      IF thisRelease GE 5.2 THEN Device, Decomposed=thisDecomposed
      ENDCASE
   'WIN': BEGIN
      IF thisRelease GE 5.2 THEN Device, Decomposed=thisDecomposed
      ENDCASE
   'MAC': BEGIN
      IF thisRelease GE 5.2 THEN BEGIN
         Device, Decomposed=thisDecomposed

         ; Here is a hack that fixes a longstanding Mac problem with
         ; color tables after changing the decomposed state.

         TV, [0]
      ENDIF
      ENDCASE
   ELSE:
ENDCASE

END
