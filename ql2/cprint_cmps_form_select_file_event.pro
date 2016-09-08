Pro cprint_cmps_form_Select_File_event, event

   ; Allows the user to select a filename for writing.

Widget_Control, event.top, Get_UValue=info, /No_Copy

   ; Start with the name in the filename widget.

Widget_Control, info.idfilename, Get_Value=initialFilename
initialFilename = initialFilename(0)
filename = Pickfile(/Write, File=initialFilename)
IF filename NE '' THEN $
   Widget_Control, info.idfilename, Set_Value=filename
Widget_Control, event.top, Set_UValue=info, /No_Copy
END ;*******************************************************************


