;-----------------------------------------------------------------------
; NAME: calc_reg_wl_grid
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

function calc_reg_wl_grid, s_Filter

   COMMON APP_CONSTANTS

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
                 [ 'Kn5',     '700',      '2278',	'2407' ]    ]
             

   i_FiltPos = where( reform(m_Filters[0,*]) EQ vs_Name, nFilt)
   if (n_Filt ne 1) then
      return, error('ERROR (calculate_wavelength.pro): s_Filter not unambigous') 


  d_CenterL = 6500.0  ; for 0th order
  d_ScaleL  = 0.873

  n_Pix  = float(m_Filters[1,i_FiltPos])
  d_MinL = float(m_Filters[2,i_FiltPos])
  d_MaxL = float(m_Filters[3,i_FiltPos])

  CASE strupcase(strmid(s_Filter,0,1)) of
    'Z': i_Order=6
    'J': i_Order=5
    'H': i_Order=4
    'K': i_Order=3
    else : return,error('FATAL ERROR (calculate_wavelength.pro): Strange s_Filter keyword.')
  ENDCASE

  d_ScaleL  = d_ScaleL / float(i_Order)
  d_CenterL = d_CenterL / float(i_Order)

  vd_L = d_MinL + findgen(n_Pix) * d_ScaleL

  if ( min(vd_L) gt d_CenterL or max(vd_L) lt d_CenterL ) then $
     return, error('FATAL ERROR (calculate_wavelength.pro): Calculated center of wavelength not within MinL and MaxL.') 

  return, vd_L 

end
