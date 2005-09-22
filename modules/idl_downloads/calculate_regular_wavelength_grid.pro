;-----------------------------------------------------------------------
; NAME: calculate_regular_wavelength_grid
;
; PURPOSE: calculate regular wavelength grid for interpolation
;
; INPUT : s_Filter : string with the filtername
;
; OUTPUT : returns a float vector with wavelengths between minimum and
;          maximum wavelength
;
; ON ERROR : returns ERR_UNKNOWN from APP_CONSTANTS
;
; STATUS : untested
;
; HISTORY : 11.8.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

function calculate_regular_wavelength_grid, s_Filter, DEBUG=DEBUG

   COMMON APP_CONSTANTS

   ;            filtername  # of pixels   min lambda    max lambda

   m_Filters = [ [ 'Zbb',     '2600',     '980',	'1200' ], $
                 [ 'Jbb',     '2600',     '1180',	'1440' ], $
                 [ 'Hbb',     '2600',     '1470',	'1800' ], $
                 [ 'Kbb',     '2600',     '1960',	'2400' ], $
                 [ 'Zn1',     '700',      '980',	'1036' ], $
                 [ 'Zn2',     '700',      '1021',	'1079' ], $
                 [ 'Zn3',     '700',      '1065',	'1125' ], $
                 [ 'Zn4',     '700',      '1110',	'1172' ], $
                 [ 'Jn1',     '700',      '1156',	'1222' ], $
                 [ 'Jn2',     '700',      '1205',	'1274' ], $
                 [ 'Jn3',     '700',      '1256',	'1327' ], $
                 [ 'Jn4',     '700',      '1309',	'1383' ], $
                 [ 'Jn5',     '700',      '1365',	'1442' ], $
                 [ 'Hn1',     '700',      '1470',	'1553' ], $
                 [ 'Hn2',     '700',      '1526',	'1613' ], $
                 [ 'Hn3',     '700',      '1585',	'1674' ], $
                 [ 'Jn4',     '700',      '1645',	'1739' ], $
                 [ 'Hn5',     '700',      '1708',	'1805' ], $
                 [ 'Kn1',     '700',      '1960',	'2071' ], $
                 [ 'Kn2',     '700',      '2035',	'2150' ], $
                 [ 'Kn3',     '700',      '2113',	'2233' ], $
                 [ 'Kn4',     '700',      '2194',	'2318' ], $
                 [ 'Kn5',     '700',      '2278',	'2407' ] ]
             

  if ( s_Filter eq 'TEST' ) then return, dindgen(20)/2.
  if ( s_Filter eq 'SPIFFIK' ) then return, dindgen(2560)*0.000244975+1.88616


  i_FiltPos = where( reform(m_Filters[0,*]) EQ strtrim(s_Filter,2), n_Filt)
  if (n_Filt ne 1) then $
     return, error('ERROR (calculate_regular_wavelength_grid.pro): s_Filter defined ' + strg(n_Filt) + ' times.') 

  d_CenterL = 6500.0  ; for 0th order
  d_ScaleL  = 0.873

  n_Pix  = (fix(reform(m_Filters[1,i_FiltPos])))(0)
  d_MinL = (float(reform(m_Filters[2,i_FiltPos])))(0)
  d_MaxL = (float(reform(m_Filters[3,i_FiltPos])))(0)

  CASE strupcase(strmid(s_Filter,0,1)) of
    'Z': i_Order=6
    'J': i_Order=5
    'H': i_Order=4
    'K': i_Order=3
    else : return,error('FATAL ERROR (calculate_regular_wavelength_grid.pro): Strange s_Filter keyword.')
  ENDCASE

  d_ScaleL  = d_ScaleL / float(i_Order)
  d_CenterL = d_CenterL / float(i_Order)

  vd_L = (dindgen(n_Pix) * d_ScaleL) + d_MinL

  if ( keyword_Set ( DEBUG ) ) then begin
     debug_info, 'DEBUG INFO (calculate_regular_wavelength_grid.pro): Filter ' +strg(s_Filter)
     debug_info, 'DEBUG INFO (calculate_regular_wavelength_grid.pro): Min WL ' +strg(min(vd_L)) +', max WL '+strg(max(vd_L))
     debug_info, 'DEBUG INFO (calculate_regular_wavelength_grid.pro): Center WL ' +strg(d_CenterL)
     debug_info, 'DEBUG INFO (calculate_regular_wavelength_grid.pro): # of pix ' +strg(n_Pix)

  end

  if ( min(vd_L) gt d_CenterL or max(vd_L) lt d_CenterL ) then $
     return, error('FATAL ERROR (calculate_regular_wavelength_grid.pro): Calculated center of wavelength not within MinL and MaxL.') 

  return, vd_L 

end
