;+
; NAME:
;	CW_LABEL
;
; PURPOSE:
;	This widget cluster function manages a two label widget.
;	The cluster consists of two label widgets.  CW_LABEL is built so that
;	the first label is fixed, and the second label is changable via
;	widget_control calls.
;
; CATEGORY:
;	Widget Clusters.
;
; CALLING SEQUENCE:
;	Result = CW_LABEL(Parent)
;
; INPUTS:
;	Parent:	The widget ID of the widget to be the label's parent.
;
; KEYWORD PARAMETERS:
;	TITLE:	A string containing the text to be used as the label for the
;		widget.  The default is "Value:".
;
;	VALUE:	The initial value in the second label widget.
;
;	UVALUE:	A user value to assign to the label cluster.  This value
;		can be of any type.
;
;	FRAME:	The width, in pixels, of a frame to be drawn around the
;		entire label cluster.  The default is no frame.
;
;	COLUMN:	Set this keyword to center the label above the cluster.
;		The default is to position the label to the left of the 
;		cluster.
;
;	ROW:	Set this keyword to position the label to the left of the 
;		cluster.  This is the default.
;
;	XSIZE:	An explicit horizontal size (in pixels) for the second label
;		area.  The default is to let the window manager size the
;		widget.  Using the XSIZE keyword is not recommended.
;
;	YSIZE:	An explicit vertical size (in pixels) for the second label
;		area.  The default is 0. (height of font)
;
;	FONT:	A string containing the name of the X Windows font to use
;		for the TITLE of the widget.
;
;    VALFONT:	A string containing the name of the X Windows font to use
;		for the VALUE part of the widget.
;
; OUTPUTS:
;	This function returns the widget ID of the newly-created cluster.
;
; COMMON BLOCKS:
;	None.
;
; PROCEDURE:
;	Create the widgets, set up the appropriate event handlers, and return
;	the widget ID of the newly-created cluster.
;
; EXAMPLE:
;	The code below creates a main base with a label cluster attached
;	to it.  The cluster accepts string input, has the title "Name:", and
;	has a frame around it:
;
;		base = WIDGET_BASE()
;		label = CW_LABEL(base, TITLE="Name:", /FRAME)
;		WIDGET_CONTROL, base, /REALIZE
;
; MODIFICATION HISTORY:
; 	Written by:  Jason L. Weiss (UCLA) Dec. 09, 1999
;			-- modified from cw_field
;-

;
;	Procedure to set the value of a CW_LABEL
;
PRO CW_LABEL_SET, Base, Value

	sValue	= Value		; Prevent alteration from reaching back to caller

	Sz	= SIZE(sValue)
	IF Sz[0] NE 7 THEN sValue = STRTRIM(Value,2)

	Child	= WIDGET_INFO(Base, /CHILD)
	WIDGET_CONTROL, Child, GET_UVALUE=State, /NO_COPY
	WIDGET_CONTROL, State.TextId, $
		SET_VALUE=STRTRIM(sValue ,2)
	WIDGET_CONTROL, Child, SET_UVALUE=State, /NO_COPY
END

;
;	Function to get the value of a CW_LABEL
;
FUNCTION CW_LABEL_GET, Base

	Child	= WIDGET_INFO(Base, /CHILD)
	WIDGET_CONTROL, Child, GET_UVALUE=State, /NO_COPY
	WIDGET_CONTROL, State.TextId, GET_VALUE=Value

	Ret	= Value

	WIDGET_CONTROL, Child, SET_UVALUE=State, /NO_COPY
	RETURN, Ret
END

FUNCTION CW_LABEL, Parent, COLUMN=Column, ROW=Row, $
	FONT=LabelFont, FRAME=Frame, TITLE=Title, UVALUE=UValue, VALUE=Value, $
	VALFONT=ValueFont, TEXT_FRAME=TextFrame, $
	XSIZE=XSize, YSIZE=YSize

	;	Examine our keyword list and set default values
	;	for keywords that are not explicitly set.

    Column		= KEYWORD_SET(Column)
    Row			= 1 - Column

    IF KEYWORD_SET(ValueFont) EQ 0 THEN ValueFont=''
    IF KEYWORD_SET(Frame) EQ 0 THEN Frame=0
    IF KEYWORD_SET(LabelFont) EQ 0 THEN LabelFont=''
    IF KEYWORD_SET(Title) EQ 0 THEN Title="Value:"
    IF N_Elements(value) EQ 0 THEN value=''
    IF KEYWORD_SET(UValue) EQ 0 THEN UValue=0
    IF KEYWORD_SET(XSize) EQ 0 THEN XSize=0
    IF KEYWORD_SET(YSize) EQ 0 THEN YSize=0

    TextFrame	= KEYWORD_SET( TextFrame )

	;	Build Widget

    Base	= WIDGET_BASE(Parent, ROW=Row, COLUMN=Column, UVALUE=UValue, $
			PRO_SET_VALUE='CW_LABEL_SET', $
			FUNC_GET_VALUE='CW_LABEL_GET', $
			FRAME=Frame )
    Label	= WIDGET_LABEL(Base, VALUE=Title, FONT=LabelFont)
    Text	= WIDGET_LABEL(Base, VALUE=STRTRIM(Value,2), $
			XSIZE=XSize, YSIZE=YSize, FONT=ValueFont, $
			FRAME=TextFrame )

	; Save our internal state in the first child widget
    State	= {		$
	TextId:Text,		$
	Title:Title		$
    }
    WIDGET_CONTROL, WIDGET_INFO(Base, /CHILD), SET_UVALUE=State, /NO_COPY
    RETURN, Base
END
