pro check_kn3_sky2017, makecorr = makecorr, psfile = psfile
;+
; NAME: check_kn3_sky2017
;
; PURPOSE: Check wavelength solution using the rectification created in July 2010
;
; HISTORY: 2015-08-05 - T. Do
;-

;skycubes = [
  dir = 'reduced/'
;;  skycubes = dir+ ['sky_cube_20100505_Kn3_35mas_NewSol5.fits']
;skycubes = dir+ ['sky_cube_20120608_kn3_35mas.fits', 'sky_cube_20120609_kn3_20mas.fits']
skycubes = dir+['sky_cube_20170517_kn3_35mas_2017sol.fits.gz']
outdir = '2017_CorrMaps_new/'

ohfile = '/u/tdo/idl/osiris/ohlines_kn3.dat'

;; get a spectrum from somewhere near the center

   loadct, 39
   !p.multi = [0, 2, 1]
   if n_elements(psfile) ne 0 then begin
      ps_open, psfile, /color, /ps_fonts, thick = 3, ratio = 2.5
      charsize = 1.0
   endif else charsize = 2.0

for i = 0, n_elements(skycubes) - 1 do begin
   skycube = skycubes[i]
   sky = cube_extract2(skycube, [10, 33], radius = 1, wave = w)
   w = w*1d4

;fit = calibspec(w, sky, file = ohfile, /plot)
;   refRange = [-0.5, 0.5]
   refRange = [-0.5, 0.5]
   refPos = [10, 33]
   width = 3
   filePart = extractfile(skycube, '.fits')
   if keyword_set(makecorr) then begin
      ;; make the correlation maps
      cheight = corr_map(skycube, refPos, width = width, savefile = outdir+filePart+'_height.fits', $
                       /reflines, reffile = ohfile, /height, linewidth = 15)
      c1 = corr_map(skycube, refPos, width = width, savefile = outdir+filePart+'_corr.fits')


      c2 = corr_map(skycube, refPos, width = width, savefile = outdir+filePart+'_reflines.fits', $
                    /reflines, reffile = ohfile)
      cfwhm = corr_map(skycube, refPos, width = width, savefile = outdir+filePart+'_fwhm.fits', $
                       /reflines, reffile = ohfile, /fwhm, linewidth = 15)
      c3 = corr_map(skycube, refPos, width = width, savefile = outdir+filePart+'_reflines_poly1.fits', $
                    /reflines, reffile = ohfile, order = 1)
      c4 = corr_map(skycube, refPos, width = width, savefile = outdir+filePart+'_diffLines.fits', $
                  /reflines, reffile = ohfile, /diffCube)
      
   endif else begin
      c1 = readfits(outdir+filePart+'_corr.fits', hc1)
      c2 = readfits(outdir+filePart+'_reflines.fits', hc2)
      c3 = readfits(outdir+filePart+'_reflines_poly1.fits', hc3)
      cheight = readfits(outdir+filePart+'_height.fits', hc3)
   endelse
   
;; do some plotting
   
   m1 = moment(c1[10:45, 30:40])
   m2 = moment(c2[10:45, 30:40])
   displayimg, c1, range = [-0.5, .5], unit = 'pixel', title = filePart+' Corr', /axis, $
               xtitle = 'Mean: '+scomp(m1[0], 2)+' sigma: '+scomp(sqrt(m1[1]), 2), $
               charsize = charsize
   displayimg, c2, range = refRange, unit = 'Ang', title = filePart+' Ref', /axis, $
               xtitle = 'Mean: '+scomp(m2[0], 2)+' sigma: '+scomp(sqrt(m2[1]), 2), $
               charsize = charsize
   
endfor 
   if n_elements(psfile) ne 0 then ps_close
end

pro plot_fwhm_map, psfile = psfile
  outdir = '/u/tdo/osiris/rectification/corrMaps/2012/'
;  outFile = outdir+'sky_cube_20100505_Kn3_35mas_NewSol5_fwhm.fits'
  outFile = outdir+'sky_cube_20100513_Kc3_100mas_NewSol5_fwhm.fits'
  filePart = extractfile(outFile, '.fits')
  img = readfits(outfile)
  good = where(finite(img), ngood)
  m1 = moment(img[good])

  resolution = img
  resolution[good] = (2.1*1d4)/(img[good]) ;; only for K-band
  m2 = moment(resolution[good])
  if n_elements(psfile) ne 0 then begin
     ps_open, psfile, /color, thick = 3, /ps_font, ratio = 3
     charsize = .65
  endif else charsize = 1.0
  !p.multi = [0, 2, 1]
   displayimg, img, units = 'Ang', title = filePart+' FWHM', /axis, $
               xtitle = 'Mean: '+scomp(m1[0], 2)+' sigma: '+scomp(sqrt(m1[1]), 2), $
               charsize = charsize, range = [2, 5], format = '(F4.2)'
   displayimg, resolution, title = filePart+' Resolution', /axis, $
               xtitle = 'Mean: '+scomp(m2[0], 2)+' sigma: '+scomp(sqrt(m2[1]), 2), $
               charsize = charsize, range = [4000, 9000], format = '(I4)'
   

   if n_elements(psfile) ne 0 then ps_close

end
pro kn3_ohlines_fit, psfile = psfile
; PURPOSE: load in a cube and do a fit to the OH lines with calibspec

file = '/u/tdo/osiris/rectification/skycubes/2010NewSol5/sky_cube_20100505_Kn3_35mas_NewSol5.fits'
ohfile = '/u/tdo/idl/osiris/ohlines_kn3.dat'

s = cube_extract2(file, [5, 30], radius = 2, wave = w)

if n_elements(psfile) ne 0 then ps_open, psfile, /color, /ps_font, thick = 4
c = calibspec(w*1d4, s, file = ohfile, /plot, /shift)

if n_elements(psfile) ne 0 then ps_close
end
