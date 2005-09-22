function bool_invert, In

;   mm = In

;   m1 = where( In eq 1, nm1 )
;   m2 = where( In eq 0, nm2 )
;   if ( nm1 gt 0 ) then mm(m1)=0
;   if ( nm2 gt 0 ) then mm(m2)=1

;   return, mm

   return, In ne 1

end
