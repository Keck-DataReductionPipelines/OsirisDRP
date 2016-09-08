; NAME: gif_cube
;        
; PURPOSE: 
;  This program creates an animated gif from a 3D fits file and 
;  specified bin size(x,y) and bin step(z) using the unix proram whirlgif 
;
; INPUT: Cubefits - 3D fits images in single quotes
;	 Objectname - prefix name for output gif file in single quotes
;	 Chanstart - Starting pixel position in Lamda space
;	 Chanstop - Ending pixel position in Lamda space	 
;	 Binsize - mulitple of column and rows of fits array
;	 Binstep - bin the z dimension of the fits image
;	 Minval - minimum value for the stretch
; 	 Maxval - maximum value for the stretch
;	 Normalize - normalize each bin step to the same scale
;	 Tloop - time interval for movie loop
;	 Color - load color table 'loadct', default red	
;
; OUTPUT: Animated Gif file
;
; WRITTEN: S. Wright Feb 2005 
;
PRO gif_cube, cubefits, objectname, chanstart=chanstart, chanstop=chanstop, $
binsize=binsize, binstep=binstep, minval=minval, maxval=maxval, normalize=normalize,$
tloop=tloop,color=color

;;; Set defaults

if not KEYWORD_SET(chanstart) then chanstart = 100
if not KEYWORD_SET(chanstop) then chanstop = 1100
if not KEYWORD_SET(binsize) then binsize = 4 
if not KEYWORD_SET(binstep) then binstep = 20
if not KEYWORD_SET(minval) then minval = -0.1
if not KEYWORD_SET(maxval) then maxval = 1.1
if not KEYWORD_SET(tloop) then tloop = 0.1
if not KEYWORD_SET(color) then color = 3 
if not KEYWORD_SET(normalize) then normalize = 1

;;;load color table
loadct, color

;;;Read fits images and input size
cube = READFITS(cubefits)
sz = size(cube)

;;;median the pixel values and invert x,y,z indices
if ( sz[0] eq 3 ) then begin
    cubemed = fltarr(sz[3],sz[2],sz[1])
    for i = 1, sz[1]-2 do begin
        for j = 1, sz[2]-2 do begin
            for k = 1, sz[3]-2 do begin
                vect = [cube[i-1,j,k],cube[i+1,j,k],cube[i,j-1,k],$
		cube[i,j+1,k],cube[i,j,k-1],cube[i,j,k+1]]
                cubemed[k,j,i] = median(vect)
            endfor 
        endfor 
   endfor 
endif

;;;normalize cube
if (normalize eq 1) then begin 
	sz = size(cubemed)
	for z = 0, sz[3]-1 do begin
   		 c = max(cubemed[*,*,z])
   		 cubemed[*,*,z] = cubemed[*,*,z]/c
	endfor	
endif

;;;apply binsize and binstep
cubemed = cubemed[*,*,chanstart:chanstop]
s = SIZE(cubemed)
xbin = s[1]*binsize
ybin = s[2]*binsize
zbin = s[3]/binstep
print,s[1],s[2],s[3],xbin,ybin,zbin
intimg = fltarr(xbin,ybin,s[3])
for i = 0, s[1]-1 do begin
    for j = 0, s[2]-1 do begin
        for k = 0, s[3]-1 do begin
            intimg[(i*binsize):(((i+1)*binsize)-1),$
		(j*binsize):(((j+1)*binsize)-1),k]=cubemed[i,j,k]
        end
    end
end
imbin = CONGRID(intimg,xbin,ybin,zbin)
z = zbin


;;;create temp bitmap to temp gif files	
for k=0, z -1 DO begin   	
	j=strcompress(k,/remove)
	if k le 9 then j='000'+j else if k le 99 then j='00'+j
	write_bmp,'anim'+j+'.bmp',bytscl(imbin[*,*,k],$
		min=minval, max=maxval,top=!D.TABLE_SIZE)
    	spawn,'bmptoppm anim'+j+'.bmp | ppmtogif > loopanim'+j+'.gif'
endfor

;;;create animated gif and delete temp bmp and gif files
spawn,'whirlgif -loop -time '+strtrim(tloop,2)+' -o '+objectname+' loopanim*.gif'
spawn,'rm -f anim*.bmp'
spawn,'rm -f loopanim*.gif' 

end
