; The purpose of this function is to return the central
; wavelength of a given filter.

function osiris_imag_effwave, filter

filter=strtrim(filter,2)

case filter of
    'Zbb':cenwave=1.0915
    'Jbb':cenwave=1.3094
    'Hbb':cenwave=1.6383
    'Kbb':cenwave=2.1717
    'Zn3':cenwave=1.0868
    'Jn1':cenwave=1.2029
    'Jn2':cenwave=1.2581
    'Jn3':cenwave=1.3060
    'Hn1':cenwave=1.5037
    'Hn2':cenwave=1.5700
    'Hn3':cenwave=1.6351
    'Hn4':cenwave=1.6951
    'Hn5':cenwave=1.7642
    'Kn1':cenwave=2.0044
    'Kn2':cenwave=2.0905
    'Kn3':cenwave=2.1756
    'Kn4':cenwave=2.2648
    'Kn5':cenwave=2.3498
    else:cenwave=0
endcase 

return, cenwave

end
