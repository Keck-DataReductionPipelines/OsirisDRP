; The purpose of this function is to return the central
; wavelength of a given filter.

function osiris_spec_effwave, filter

filter=strtrim(filter,2)

case filter of
    'Zbb':cenwave=1.0895
    'Jbb':cenwave=1.3097
    'Hbb':cenwave=1.6379
    'Kbb':cenwave=2.1728
    'Zn2':cenwave=1.0445
    'Zn3':cenwave=1.0867
    'Zn4':cenwave=1.1305
    'Zn5':cenwave=1.1762
    'Jn1':cenwave=1.2028
    'Jn2':cenwave=1.2583
    'Jn3':cenwave=1.3069
    'Jn4':cenwave=1.3563
    'Hn1':cenwave=1.5033
    'Hn2':cenwave=1.5708
    'Hn3':cenwave=1.6348
    'Hn4':cenwave=1.6941
    'Hn5':cenwave=1.7644
    'Kn1':cenwave=2.0048
    'Kn2':cenwave=2.0884
    'Kn3':cenwave=2.1754
    'Kn4':cenwave=2.2638
    'Kn5':cenwave=2.3499
    else:cenwave=0
endcase 

return, cenwave

end
