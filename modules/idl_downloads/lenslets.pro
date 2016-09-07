Function lenslets,all=all,filter=filter,graph=graph,indx=indx
; This routine calculates locations of lenslet pupil iamges on the detector.
;
; syntax: pxy=lenslets(filter='Hbb',indx=indx,/all,/graph)
;
; pxy is a 2D array: pxy[0,*]=x-pixel coords, pxy[1,*]=y-pixel coords
; if indx variable is given, similar to pxy, but it will contains lenslet array indices 
; instead of pixel coordinates.
;
; It chooses an appropriate mask stage based on the given filter keyword. 
; If /all keyword is given, then the filter and /graph keywords will be ignored.
;
; Inseok Song (2004)
;===============================================================================
   if (not keyword_set(all)) then all=0
   if (not keyword_set(graph)) then graph=0
   if (not keyword_set(filter) and not keyword_set(all)) then begin
      print,'Filter is not specified!'
      return,-1
   endif

   ncols=51 & nrows=66 ; for 48x64 wide-field (narrow-band) lenslet mask case!
   useful = intarr(ncols,nrows)         ; 0=unuseful lenslet, 1=useful lenslet
   pixpos = ulong(fltarr(ncols,nrows))  ; to keep pixel locations of lenslet pupils
   idx    = ulong(fltarr(ncols,nrows))  ; contains indices of lenslets
   pxy    = intarr(2,ncols*nrows)       ; pxy[0,*]:x-coord, pxy[1,*]=y-coord
   indx   = intarr(2,ncols*nrows)       ; indx[0,*]:col, indx[1,*]=row

; In calculation of pxy and idx, unsigned long integer variables are used.
; For example, to record pixel positions of lenslet[col,row] into 'pixpos'
; px and py will be assigned into one variable, e.g., 
; px=993, py=1042 --> pxy = ulong(px + 10000UL*(py+1000)) = 20420993UL
; similar for lenslet index variable, idx

   xorigin=800.0
   yorigin=2050.0

   ; all lenslets
   i0=xorigin - 512.0 + 2.0
   j0=yorigin + 64.0
   for col=0,50 do begin
     for row=0,65 do begin
        ix = fix(i0-2*row)
        iy = fix(j0-32*row)
        pixpos[col,row]=ulong(ix + 10000UL*(iy+1000))
        idx[col,row] = ulong(col + 10000UL*row)
     endfor
     i0 += 32.0
     j0 += -2.0
   endfor
   if (all) then begin
      pxy[0,*]  = fix(pixpos MOD 10000UL-1024)*29.0/32.0 + 1024
      pxy[1,*]  = fix(pixpos/10000UL) - 1000
      indx[0,*] = idx MOD 10000UL
      indx[1,*] = fix(idx/10000UL)
      return,pxy
   endif

   ; central lenslets for broad-band and narrow-band imaging
   i0=xorigin
   j0=yorigin
   for l=0,15 do begin
     for m=0,3 do begin
       for n=0,15 do begin
          k = 64*l + 16*m + n
          ix=i0-2*n
          iy=j0-512*m - 32*n
          if (iy LE 2048 OR iy GE 1 ) THEN begin
             pixelxy = ulong(ix + 10000UL*(iy+1000))
             whichone= where(pixpos EQ pixelxy, nsuch)
             if (nsuch NE 1) then begin
                print,"Error: more than one (or none) matching lenslet at",ix,iy,pixelxy,nsuch
                return,-1
             endif else begin
                useful[whichone] = 1
             endelse
          endif
       endfor
       j0 -= 2.0
      endfor
      j0 += 6.0
      i0 += 32.0
   endfor

   ; lenslets only for narrow-band imaging
   ; all narrow-band filter names have 'n' as their 2nd character.
   if (strupcase(strmid(filter,1,1)) EQ 'N') then begin
       i0=xorigin - 512.0 - 2.0
       j0=yorigin
       nend=[15,16,16,17]
       for m=0,3 do begin
         for l=0,15 do begin
           for n=0,nend[m]-1 do begin
              ix=i0-2*n
              iy=j0-32*n
              if (iy LE 2048 OR iy GE 1 ) THEN begin
                 pixelxy = ulong(ix + 10000UL*(iy+1000))
                 whichone= where(pixpos EQ pixelxy, nsuch)
                 if (nsuch NE 1) then begin
                    print,"Error: more than one (or none) matching lenslet at",ix,iy,pixelxy,nsuch
                    return,-1
                 endif else begin
                    useful[whichone] = 1
                 endelse
              endif
           endfor
           j0 -= 2.0
           i0 += 32.0
         endfor
         j0 -= 32*(nend[m]-1)+2.0
         i0 -= 512 + (m-1)*2.0 - fix(m / 2.0)*2.0
       endfor
    
       i0=xorigin + 512.0 + 2.0
       j0=yorigin
       nend=[17,16,16,15]
       for m=0,3 do begin
         for l=0,15 do begin
           for n=0,nend[m]-1 do begin
              ix=i0-2*n
              iy=j0-32*n
              if (iy LE 2048 OR iy GE 1 ) THEN begin
                 pixelxy = ulong(ix + 10000UL*(iy+1000))
                 whichone= where(pixpos EQ pixelxy, nsuch)
                 if (nsuch NE 1) then begin
                    print,"Error: more than one (or none) matching lenslet at",ix,iy,pixelxy,nsuch
                    return,-1
                 endif else begin
                    useful[whichone] = 1
                 endelse
              endif
           endfor
           j0 -= 2.0
           i0 += 32.0
         endfor
         j0 -= 32*(nend[m]-1) + 2.0
         i0 -= 512 - (m-1)*2.0 + fix(m / 2.0)*2.0
       endfor
   endif
   ; plot only useful lenslets
   dummyidx = where(useful,nuseful)
   useful_idx = idx[dummyidx]
   useful_pxy = pixpos[dummyidx]
   
   pxy=intarr(2,nuseful)
   if (keyword_set(indx)) then indx=intarr(2,nuseful)
   pxy[0,*]  = fix(useful_pxy MOD 10000UL - 1024)*29.0/32.0 + 1024
   pxy[1,*]  = fix(useful_pxy/10000UL) - 1000
   indx[0,*] = useful_idx MOD 10000UL
   indx[1,*] = fix(useful_idx/10000UL)

   if (graph) then begin
       chsize=0.5
       plot,xrange=[-190,2150],yrange=[-190,2150],/NODATA,[0,1],[0,1],$
            xstyle=1,ystyle=1,xtitle="detector X",ytitle="detector Y", $
            title="OSIRIS lenslets pupils"
       oplot,[-190,2268],[1024,1024],color='777777'x
       oplot,[1024,1024],[ -90,2168],color='777777'x
       oplot,[   1,2048],[   1,   1],color='AA2222'x,linestyle=1
       oplot,[   1,2048],[2048,2048],color='AA2222'x,linestyle=1
       oplot,[   1,   1],[   1,2048],color='AA2222'x,linestyle=1
       oplot,[2048,2048],[   1,2048],color='AA2222'x,linestyle=1
       arrow,50,0,-100,0,/DATA
       xyouts,80,-15,"Disp. Axis"
       if (all) then plots,pixpos MOD 10000UL, fix(pixpos/10000UL)-1000,psym=1,symsize=chsize,color='555555'x
       plots,useful_pxy MOD 10000UL, fix(useful_pxy/10000UL)-1000,psym=1,symsize=chsize,color='5555FF'x
   endif

   return,pxy
end
