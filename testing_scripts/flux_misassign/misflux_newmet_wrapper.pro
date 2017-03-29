pro misflux_newmet_wrapper,infile,datatype=datatype

; wrapper for the misflux_newmet routine. Takes in the input reduced
; cube, and a string for the data type ('arc','sky'). Based on that,
; chooses a reference spectral channel and whether to sum all spaxels
; or not. Output is printed to screen.

cube = mrdfits(infile,0,hdr,/silent)
filter = sxpar(hdr,'SFILTER')
filter = strtrim(filter,2)
print, 'Filter is: '+filter

if datatype eq 'arc' then begin
   sumspax = 0
   case filter of
      'Kbb': refchannel = 904
   endcase
endif else if datatype eq 'sky' then begin
   sumspax = 1
   print,'Summing spaxels before calculating'
   case filter of
      'Jn2': refchannel = 96
      'Jbb': refchannel = 1482 ;737
      'Hbb': refchannel = 989 ; 351, 650, 753, 989, 1575
      'Kbb': refchannel = 432
      'Kcb': refchannel = 432
      'Kn3': refchannel = 131
      'Kc3': refchannel = 131
      'Kn5': print,'No isolated sky lines available'
   endcase
endif else print, 'Please specify arc or sky as the data type.'

print,'Spectral channel used is: '+string(refchannel)

misflux_newmet,infile,refchannel=refchannel,sumspax=sumspax

end
