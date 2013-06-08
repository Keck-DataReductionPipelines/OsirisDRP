
;-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; NAME:  mosaicdpos_000
;
; PURPOSE: determine offset positions from cross corelations for mosaicing
;
; PARAMETERS IN RPBCONFIG.XML :
;
;    mosaicdpos_COMMON___Debug           : initializes the debugging mode
;    mosaicdpos_COMMON___Channels        : the percentage of the cube
;                                          (counting from the middle of the cube) to collapse
;    mosaicdpos_COMMON___Mode            : the collapsing mode in case of cubes 
;                                         'MED' : pixel in image is the median value
;                                                 of the spectrum (unweighted)
;                                         'AVRG': pixel in image is the mean value
;                                                 of the spectrum (weighted).
;                                         'SUM' : pixel in image is the sum
;                                                 of the spectrum (unweighted) 
;    mosaicdpos_COMMON___Magnification   : magnification of the images
;                                          (for subpixel accuracy).
;    mosaicdpos_COMMON___PlateauTreshold : Threshold for plateau detection
;
; INPUT-FILES : None
;
; OUTPUT : the offset positions
;
; DATASET : unchanged
;
; DEBUG : nothing special
;
; MAIN ROUTINE : correl_optimize.pro
;
; SAVES : - the offset possitions as an array of [2,n_Sets] with the
;           first index describing the direction 0=x, 1=y. 
;
;         - If Save tag in drf file is set to 1, the images used to
;           determine the offset positions are saved.
;
; NOTES : 
;
; STATUS : not tested
;
; HISTORY : 19.10.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

FUNCTION mosaicdpos_000, DataSet, Modules, Backbone

    COMMON APP_CONSTANTS

    functionName = 'mosaicdpos_000'
    ; save the starting time
    T = systime(1)

    drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1

    ; check integrity
    stModule =  check_module( DataSet, Modules, Backbone, functionName, /DIMS )
    if ( NOT bool_is_struct ( stModule ) ) then $
       return, error ('ERROR IN CALL ('+strtrim(functionName)+'): Integrity check failed.')

    ; Get all COMMON parameter values
    b_Debug        = fix(Backbone->getParameter('mosaicdpos_COMMON___Debug')) eq 1
    d_Mag          = float(Backbone->getParameter('mosaicdpos_COMMON___Magnification'))
    d_Plateau      = float(Backbone->getParameter('mosaicdpos_COMMON___PlateauTreshold'))
    d_SpecChannels = float(Backbone->getParameter('mosaicdpos_COMMON___Channels'))
    if ( d_SpecChannels lt 0. or d_SpecChannels gt 1. ) then $
       return, error ('ERROR IN CALL ('+strtrim(functionName)+'): channels out of range' )
    s_Mode = Backbone->getParameter('mosaicdpos_COMMON___Mode')
    if ( NOT ( s_Mode eq 'MED' or s_Mode eq 'AVRG' or s_Mode eq 'SUM' ) ) then $
       return, error ( 'ERROR IN CALL('+strtrim(functionName)+'): unknown Mode ' + strg(s_Mode) )

    ; resize the dataset, that all images cubes have the same spatial dimensions
     n_Sets = Backbone->getValidFrameCount(DataSet.Name)
    if ( resize_dataset( DataSet, n_Sets ) ne OK ) then $
       return, error ('FAILURE ('+strtrim(functionName)+'): Resizing of dataset failed.')

    ; extract images for offset determination
    n_Dims = size(*DataSet.Frames[0])

    if ( bool_is_cube( *DataSet.Frames[0]) ) then begin

       cd_Images = make_array(n_Dims[2], n_Dims[3], n_Sets, /FLOAT)

       for i=0, n_Sets-1 do begin

          s_Res = img_cube2image ( DataSet.Frames[i], DataSet.IntFrames[i], DataSet.IntAuxFrames[i], $
                                   d_SpecChannels, s_Mode, DEBUG=b_Debug )
          if ( NOT bool_is_struct ( s_Res ) ) then $
             return, 'FAILURE ('+strtrim(functionName)+'): Failed to extract image of set '+strg(i)+'.' $
          else $
             cd_Images(*,*,i) = s_Res.md_Image

       end

    endif else begin

       if ( bool_is_image(*DataSet.Frames[0]) ) then begin

          cd_Images = make_array(n_Dims(1), n_Dims(2), n_Sets, /FLOAT)
          for i=0, n_Sets-1 do $
             cd_Images(*,*,i) = *DataSet.Frames[i]

       endif else return, error ('ERROR IN CALL ('+strg(functionName)+'): Input is neither cube nor image.')

    end

    ; now determine the offsets
    vd_Positions = fltarr(2,n_Sets)

    for i=1, n_Sets-1 do begin

       correl_optimize, reform( cd_Images(*,*,0)), reform(cd_Images(*,*,i)), $
                                xoffset_optimum, yoffset_optimum, $
                                XOFF_INIT = 0,   $
                                YOFF_INIT = 0,   $
                                MONITOR = b_Debug, $
                                /NUMPIX, $
                                MAGNIFICATION = d_Mag, $
                                PLATEAU_TRESH = d_Plateau

       vd_Positions(0,i) = xoffset_optimum
       vd_Positions(1,i) = yoffset_optimum

    end

    stModule =  check_module( DataSet, Modules, Backbone, functionName )
    if ( NOT bool_is_struct ( stModule ) ) then $
       return, error ('ERROR IN CALL ('+strtrim(functionName)+'): Post Integrity check failed.')

    ; Now, save the data
    thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
    c_File = make_filename ( DataSet.Headers[0], Modules[thisModuleIndex].OutputDir, stModule.SaveExt )
    if ( NOT bool_is_string(c_File) ) then $
       return, error('FAILURE ('+strtrim(functionName)+'): Output filename creation failed.')

    h_H = *DataSet.Headers[0]
    sxaddpar, h_H, 'COMMNT', 'Offset positions for mosaicing'
    writefits, c_File, vd_Positions, h_H

    if ( b_Debug ) then begin
       debug_info, 'DEBUG INFO ('+strtrim(functionName)+'): File ' + c_File + ' successfully written.'
       fits_help, c_File
    end

    if ( Modules[thisModuleIndex].Save eq 1 ) then begin

       ; now save the data
       c_File = make_filename ( DataSet.Headers[0], Modules[thisModuleIndex].OutputDir, stModule.Save )
       if ( bool_is_string(c_File) ) then begin

          h_H = *DataSet.Headers[0]
          sxaddpar, h_H, 'COMMNT', 'Images for determining offset positions for mosaicing.'
          writefits, c_File, cd_Images, h_H
 
          info, 'INFO ('+strtrim(functionName)+'): File '+c_File+' successfully written.'
          if ( keyword_set ( b_Debug ) ) then fits_info, c_File

       endif else warning,'WARNING ('+strtrim(functionName)+'): Output filename creation failed.'

    end

    report_success, functionName, T

    return, OK

end
