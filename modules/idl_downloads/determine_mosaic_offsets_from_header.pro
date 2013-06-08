;-----------------------------------------------------------------------
; NAME: coord2det
;
; PURPOSE: determine offsets used for mosaicing from coordinates
;
; INPUT :   md_Coords : matrix (2,number of offsets) with the coordinates
;                       index 0 : 'x-coord', index 1 : 'y-coord'
;           s_Type    : string indicating the method:
;                       'TEL'  : determine offsets from telescope
;                                coordinates
;                      'NGS'   : determine offsets from AO (OBFM)
;                      'LGS'  : determine offset from LGS (AOTS)
;
;           d_Scale   : scale in arcsec per spatial element
;           d_PA      : position angle in degrees
;
; OUTPUT : matrix with offsets, matrix(2,number of offset positions),
;          index 0 : x-offsets, index 1 : y-offsets
;
; ON ERROR : returns ERR_UNKNOWN from APP_CONSTANTS else OK
;
; NOTES : 
;
; STATUS : untested
;
; HISTORY : 25.8.2005, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;	Modified by Shelley Wright for AO offsets Dec 2006
;
;-----------------------------------------------------------------------

function coord2det, md_Coords, s_Type, d_Scale, d_PA, vd_InstAngl

;   COMMON APP_CONSTANTS

   functionName = 'determine_mosaic_offsets_from_header/coord2det'

   n_Dims = size ( md_Coords )

   if ( n_Dims(0) ne 2 or n_Dims(1) ne 2 ) then $
      return, error('ERROR IN CALL (' + functionName + '): md_Coords must be a matrix (2,number of offsets).')

;;;--------------------

   if ( s_Type eq 'TEL' ) then begin

      ; coordinates are right ascencion and declination in degrees
      vd_CoordsDec =   (md_Coords(1,0) - md_Coords(1,*)) * 3600. / d_Scale
      vd_CoordsRA  =   (md_Coords(0,0) - md_Coords(0,*)) * 3600. / d_Scale * $
                       cos ( md_Coords(1,*) * !pi/180. )

      md_Offsets = transpose( [[[-1.*(vd_CoordsRA * sin(d_PA) + vd_CoordsDec * cos(d_PA))]], $
                               [[vd_CoordsRA * cos(d_PA) - vd_CoordsDec * sin(d_PA)]]] )

   endif

;;;--------------------

  if ( s_Type eq 'NGS' ) then begin

      ; coordinates are NGS 
      ; need to find conversion to plate scale
      vd_CoordsNX =   (md_Coords(0,0) - md_Coords(0,*)) * (35.6 * (0.0397/d_Scale))  
      vd_CoordsNY  =  (md_Coords(1,0) - md_Coords(1,*)) * (35.6 * (0.0397/d_Scale))

      vd_InstAngl = (vd_InstAngl* !pi/180)
      md_Offsets = [vd_CoordsNX * cos(vd_InstAngl) + vd_CoordsNY * sin(vd_InstAngl), $
                               (-1.)*vd_CoordsNX * sin(vd_InstAngl) + vd_CoordsNY * cos(vd_InstAngl)] 

      ;  NJM 12/5/08: original formula for md_Offsets is below
      ;  I suspect there should be 2 cos terms and 2 sin terms (hence the version in place above).
      ;
      ;md_Offsets = [vd_CoordsNX * cos(vd_InstAngl) + vd_CoordsNY * sin(vd_InstAngl), $
                                ;(-1.)*vd_CoordsNX * cos(vd_InstAngl) + vd_CoordsNY * cos(vd_InstAngl)] 

   endif

;;;--------------------

  if ( s_Type eq 'LGS' ) then begin

      ; coordinates are LGS 
      ; need to find conversion to plate scale 
      vd_CoordsLX =   (md_Coords(0,0) - md_Coords(0,*)) * (1/d_Scale) * (1/0.727) 
      vd_CoordsLY  =  (md_Coords(1,0) - md_Coords(1,*)) * (1/d_Scale) * (1/0.727) 

    
      ;original version: vd_InstAngl = !pi/2 - (vd_InstAngl*!pi/180)
      vd_InstAngl = !pi - (vd_InstAngl*!dtor)   ;NJM 11/14/08

      md_Offsets = [(vd_CoordsLX * cos(vd_InstAngl) + vd_CoordsLY * sin(vd_InstAngl)), $
                               ((-1.)*vd_CoordsLX * sin(vd_InstAngl) + vd_CoordsLY * cos(vd_InstAngl))] 

      ;NJM 11/14/08  (line below is absent from original version
      md_Offsets = (-1)*[md_Offsets[1,*],md_Offsets[0,*]]

   endif

;;;--------------------

   return, md_Offsets

end

;-----------------------------------------------------------------------
; NAME: determine_mosaic_offsets_from_header
;
; PURPOSE: determine offsets used for mosaicing from header informations 
;
; INPUT :   p_H      : pointer to header array
;           b_Format : boolean, mosaic cubes (1) or images (0)
;           s_Type   : string indicating the method:
;                      'TEL'  : determine offsets from telescope
;                               coordinates
;                      'NGS'   : determine offsets from AO (OBFM)
;		       'LGS'  : determine offset from LGS (AOTS)
;
;           n_Sets   : number of headers
;           NOPA = NOPA : ignore checking for the position angle
;
; OUTPUT : matrix with offsets, matrix(2,number of offset positions),
;          index 0 : x-offsets, index 1 : y-offsets
;
; ON ERROR : returns ERR_UNKNOWN from APP_CONSTANTS else OK
;
; NOTES : - The determined offsets are written to the individual
;           headers. The keywords are X_OFF and Y_OFF (float) in units
;           of spatial elements. The first header always gets 
;           offset 0,0 (reference frame).
;         - All headers must have the same SSCALE keyword in arcsec
;         - All headers must have the same position angle
;         - Headers must not have the same filter keyword, so it is
;           possible to determine the offsets for a mixed dataset.
;         - SSCALE, PA_SPEC, PA_IMAG
;
; STATUS : untested
;
; HISTORY : 25.8.2005, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;	Modified by Shelley Wright to add AO offset 2006 dec 
;
;-----------------------------------------------------------------------

function determine_mosaic_offsets_from_header, p_H, b_Format, s_Type, n_Sets, NOPA = NOPA

   COMMON APP_CONSTANTS

   functionName = 'determine_mosaic_offsets_from_header.pro'

   ; integrity checks
   if ( s_Type ne 'TEL' and s_Type ne 'NGS' and s_Type ne 'LGS' ) then $
      return, error('ERROR IN CALL (' + functionName + '): Unknown Type ' + strg(s_Type) )
   if ( b_Format ne 1 and b_Format ne 0 ) then $
      return, error('ERROR IN CALL (' + functionName + '): Unknown Format ' + strg(b_Format) )

   if ( n_Sets eq 1 ) then $
      return, error('ERROR IN CALL (' + functionName + '): Cannot determine offsets from only 1 dataset.' )

   ; all headers must have the same SSCALE keyword in case of cubes
   if ( b_Format eq 1 ) then begin
      ; get the SSCALE keywords
      vd_Scale = float(get_kwd (p_H, n_Sets, 'SSCALE', /NOCONTINUE))
      ; ensure that the scales are all the same
      if ( array_equal( vd_Scale, vd_Scale(0) ne 1 ) ) then $
         return, error('ERROR IN CALL (' + functionName + '): Headers have different SSCALE keywords.')
      case vd_Scale(0) of
         0.020 : d_Scale = 0.0203d
         0.035 : d_Scale = 0.0350d
         0.050 : d_Scale = 0.0500d
         0.100 : d_Scale = 0.1009d
         else  : return, error('ERROR IN CALL (' + functionName + '): Unrecognized SSCALE keyword. Must be in arcsec/px ' + strg(vd_Scale(0)) )
      endcase

   endif else $
      d_Scale = 0.0203d  ; for images the scale is 0.0203 arcseconds per pixel

   info, 'INFO : ('+functionName+'): Actual scale: '+strg(d_Scale)

   if ( b_Format eq 0 ) then $
      info, 'INFO : ('+functionName+'): Determining offsets for imaging.' $
   else $
      info, 'INFO : ('+functionName+'): Determining offsets for spectrograph.'         

   ; determine the position angle
   if ( NOT keyword_set ( NOPA ) ) then begin

      vd_RotPosn  = double(get_kwd (p_H, n_Sets, 'ROTPOSN', /NOCONTINUE))
      vd_InstAngl = double(get_kwd (p_H, n_Sets, 'INSTANGL', /NOCONTINUE))

      info, 'INFO : ('+functionName+'): Found rotator and instrument angle (in deg) positions to be :'
      for i=0, n_elements(vd_InstAngl)-1 do $
         print, vd_RotPosn(i), vd_InstAngl(i)

      ; position angles in radian
      vd_PA = ( vd_RotPosn - vd_InstAngl + (( b_Format eq 1 ) ? 0.d : 47.5d) ) * !pi / 180d

      dummy = where ( abs(vd_PA - vd_PA(0)) gt 0.01745d, n )

      if ( n gt 0 ) then $
         return, error( [ 'ERROR IN CALL (' + functionName + '): Headers seem to have different position angles. ', $
                          '   At least one of them deviates by more than 1 degree from the reference position angle.'] )

      info, 'INFO : ('+functionName+'): Found rotator positions (in rad) to be :'
      for i=0, n_elements(vd_PA)-1 do $
         print, vd_PA(i)

      d_PA = vd_PA(0)
      info, 'INFO : ('+functionName+'): Found position angle determined to be :'+strg(d_PA)

   endif else $
      d_PA = 0.

;;;--------------------

   ; read the coordinates from the individual TEL headers
   if ( s_Type eq 'TEL' ) then begin
      vd_C0 = double(get_kwd (p_H, n_Sets, 'RA', /NOCONTINUE))
      vd_C1 = double(get_kwd (p_H, n_Sets, 'DEC', /NOCONTINUE))
   end;if else begin
      ;vd_C0 = double(get_kwd (p_H, n_Sets, '', /NOCONTINUE))
      ;vd_C1 = double(get_kwd (p_H, n_Sets, '', /NOCONTINUE))
   ;end

;;;--------------------

   ; read the coordinates from the individual NGS headers
   if ( s_Type eq 'NGS' ) then begin
      vd_C0 = double(get_kwd (p_H, n_Sets, 'OBFMXIM', /NOCONTINUE))
      vd_C1 = double(get_kwd (p_H, n_Sets, 'OBFMYIM', /NOCONTINUE))
   end

;;;--------------------


  ; read the coordinates from the individual LGS headers
   if ( s_Type eq 'LGS' ) then begin
      vd_C0 = double(get_kwd (p_H, n_Sets, 'AOTSX', /NOCONTINUE))
      vd_C1 = double(get_kwd (p_H, n_Sets, 'AOTSY', /NOCONTINUE))
   end

;;;--------------------


   if ( NOT bool_is_vector ( vd_C0 ) or NOT bool_is_vector ( vd_C1 ) ) then $
      return, error('FAILURE (' + strtrim(functionName) + '): Determination of instruments coordinates failed (1).')

   if ( n_elements ( vd_C0 ) ne n_elements ( vd_C1 ) or $
        n_elements ( vd_C0 ) ne n_Sets ) then $
      return, error('FAILURE (' + strtrim(functionName) + '): Determination of instruments coordinates failed (2).')

   md_Coords =  transpose([[vd_C0], [vd_C1]]) 

   info, 'INFO : ('+functionName+'): Found coordinates to be :'
   for i=0, n_elements(vd_C1)-1 do $
      print, vd_C0(i), vd_C1(i)

   ; convert coordinates to offsets
   md_Offsets = coord2det( md_Coords, s_Type, d_Scale, d_PA, vd_InstAngl )
   if ( NOT bool_is_image( md_Offsets ) ) then $
      return, error('FAILURE (' + strtrim(functionName) + '): Determination of offsets failed.')

   info, 'INFO : ('+functionName+'): Found shifts to be :'
   for i=0, n_elements(vd_C1)-1 do $
      print, md_Offsets(0,i), md_Offsets(1,i)
   

   return, md_Offsets

end
