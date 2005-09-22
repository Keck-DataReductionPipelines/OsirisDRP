;-----------------------------------------------------------------------
; NAME:  findlines_read_calline_file
;
; PURPOSE: read the file with the calibration lines
;
; INPUT :   s_LineFile  : absolute path with the line list
;           AIR=AIR     : convert vacuum wavelengths to air wavelenths
;
; OUTPUT :    structure { vi_Valid    : 1 if line shall be used
;                         vi_Trust    : 1 if line position can be trusted
;                         vd_WL_um    : wavelength of line in microns
;                         vd_Int_adu  : intensity in adu
;                         vs_Name     : Name of the line
;                         vs_Cmt      : Comment
;                         vs_Source   : Source of the line information }
;
; NOTES : - The conversion from vacuum to air wavelengths is done using
;           vactoair.pro from the astrolib
;         - The output is sorted by ascending air wavelengths
;         - The name of the lines is converted to uppercase
;         - the format of the line file is (sorted by columns):
;           vi_Valid        : 1 or 0 whether line shall be used or not
;           vd_WLVac_nm     : vacuum wavelength in nm
;           vd_WLAir_nm     : air wavelength in nm (or -1. if not
;                             available), currently ignored
;           vd_Int_adu      : intensity of a line (relative)
;           vs_Name         : Name of the species (Ne, Ar, Kr, Xe)
;           vs_Source       : Source of the wavelength (literature)
;           vd_IntSource    : literature value of the intensity
;           vi_Trust        : 1 or 0 whether the line identification
;                             can be trusted (currently ignored)
;           vs_Cmt          : any comment in ""
;
; STATUS : untested
;
; HISTORY : 28.9.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

function findlines_read_calline_file, s_LineFile, AIR=AIR

   readcol, s_LineFile, vi_Valid, vd_WLVac_nm, vd_WLAir_nm, vd_Int_adu, vs_Name, vs_Source, vd_IntSource, $
            vi_Trust, vs_Cmt, format='(I,F,F,F,A,A,F,I,A)'

   vs_Name = strupcase(vs_Name)

   if ( keyword_set ( AIR ) ) then begin
      ; convert vacuum wavelengths to air wavelengths
      v = double(vd_WLVac_nm) * 10.d
      vactoair, v
      vd_WL_um = v/10000.d
   endif else $
      vd_WL_um = vd_WLVac_nm / 1000.d

   vi_Mask = sort ( vd_WL_um ) 

   return, { vi_Valid      : vi_Valid(vi_Mask), $
             vi_Trust      : vi_Trust(vi_Mask), $
             vd_WL_um      : vd_WL_um(vi_Mask), $
             vd_Int_adu    : vd_Int_adu(vi_Mask), $
             vs_Name       : vs_Name(vi_Mask), $
             vs_Cmt        : vs_Cmt(vi_Mask), $
             vs_Source     : vs_Source(vi_Mask) }

end
