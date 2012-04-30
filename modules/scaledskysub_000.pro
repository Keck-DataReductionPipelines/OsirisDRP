;+-----------------------------------------------------------------------
; THIS IS A DRP MODULE
;
; NAME: scaledskysub_000 
;
; PURPOSE: subtract a sky cube, scaling it to compensate for changes in
; 	atmospheric emission lines based on the algorithm of Davies (2007)
;  
;  In somewhat more detail:
;  Correct residual over/under subtracted OH sky emission lines in JHK
;  spectra, by applying numerical scaling factors to the sky cube prior to
;  subtraction. In the process, the code creates masks of:
;    'sky' pixels  (or if no sky, pixels consistent with minimum flux)
;    'good' pixels (where at least half of spectral pixels in each
;                   spaxel have finite values)
;
; NOTE: this is designed to work with datacubes for which the spectral
;  axis is assumed to be 1, in OSIRIS convention. Internally, the code 
;  re-arranges the cube to have the spectral axis last, then re-arranges
;  it again before writing out data.
;
; PARAMETERS IN RPBCONFIG.XML :
;
; INPUT-FILES : dark-subtracted sky cube
;
; OUTPUT : None
;
; DATASET : contains the cube-subtracted data afterwards. The number of
;           valid pointers is not changed.
;
; QUALITY BITS : 0th     : checked
;                1st-3rd : ignored
;
; DEBUG : nothing special
;
; MAIN ROUTINE : 
;
; SAVES : Nothing
;
; OPTIONAL ARGUMENTS: 
;  min_sky_fraction=  the minimum fraction of spaxels to select as 'sky'
;            (as fraction; default=0.1). It is spectra
;            of these spaxels that are combined to derive the OH
;            scaling function.
;
;  max_sky_fraction= the maximum fraction of spaxels to select as sky.
;  			(as fraction, default=0.25). 
;
;  line_halfwidth = w is the half width in pixels out to which OH lines
;            should be traced (typically half width zero
;            intensity). The default is 4 pixels.
;
;  /show_plots	flag for whether or not to show plots. Default is 1, True.
;
; Scale_K_Continuum = allow for continuum scaling in K band via
;                     smoothing the sky spectra vs. fitting a thermal
;                     function.  (Default = YES)
;
; STATUS : tested on a limited amount of Jbb, Hbb, Kbb data. 
;		   Seems to work reasonably well, but NOT YET EXTENSIVELY TESTED.
;
; AUTHOR : Marshall Perrin, mperrin@ucla.edu
; 		   Code developed 2007-10-14 through 2007-12-06
; 		   Based on skysub.pro by R. Davies. See Davies 2007 MNRAS.
;
; HISTORY : 2007-12-05, created
;	           - Now includes scaling of thermal (J. Lu May 2009)
;		   - Fixed scaling of thermal to add back in to final cube (S. Wright May 2009)
;		   - Fixed which sky spaxels are used for scaling (S. Wright June 2009)
;		   - Fixed Quality bit and NAN handling (Q. Konopacky / S.Wright Jan 2010)
;		   - Includes Z-band range as well (S. Wright Feb 2010)
;                  - Added continuum scaling for proper thermal scaling
;                  in K band, added Scale_K_Continuum variable,
;                  commented out thermal_method variable and thermal
;                  fitting (Q. Konopacky Feb 2010)
;		   - Fixed the case sensitive aspect of the cont fitting 
;		   and reform problem in cont.(S. Wright March 4,2010)
;
;-----------------------------------------------------------------------
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FUNCTION alogscale,image,minval,maxval,min=min,print=print,$
    auto=auto

    if n_elements(min) gt 0 then minval=min

    if keyword_set(auto) then begin
        med = median(image)
        sig = stddev(image,/NaN)
        maxval = (med + (10 * sig)) < max(image,/nan)
        minval = (med - (2 * sig))  > min(image,/nan)
    endif


    if (n_elements(minval) eq 0) then minval = min(image,/nan)
    if (n_elements(maxval) eq 0) then maxval = max(image,/nan)

    minval=float(minval)
    maxval=float(maxval)


    offset = minval - (maxval - minval) * 0.01


    if keyword_set(print) then print,minval,maxval,offset

     scaled_image = $
          bytscl( alog10(image - offset), $
                  min=alog10(minval - offset), /nan, $
                  max=alog10(maxval - offset))

   return,scaled_image

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


function scaledskysub_fitsky, p
	; Merit function for fitting the scaling factors
	; Algorithm:
	; 	Subtract the continuum from both the object and the sky, 
	; 	by interpolating across the lines. 
	; 	Then compute the difference between the object and the sky
	; 	and return the RMS.
	;
	; 	This function minimizes the difference on the lines, without
	; 	caring at all about the continuum.
common fitsky_par, objlr,skylr,llr,line_regions,cont_regions

conts = interpol(skylr[cont_regions],llr[cont_regions],llr[line_regions])
conto = interpol(objlr[cont_regions],llr[cont_regions],llr[line_regions])
diff = (objlr[line_regions]-conto)-(skylr[line_regions]-conts)*p[0]
rms = stddev(diff)

return,rms
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

function scaledskysub_fitbkg, p
	; Fit the thermal background of the spectrum
	; with a function of the form
	;
	; bkg  = A +  x^-5/exp(14387 / (x*B) - 1) / C
	;
	;  where A, B, and C are free parameters
	;
	;  x is in microns?
	common fitbkg_par, xlr,ylr,wlr,temp,thermal
	
	tmp = xlr^(-5.)/(exp(14387.7/(xlr*abs(p[2])))-1)
	if (max(tmp) gt 0) then $
		thermal = p[0] + tmp / max(tmp)*abs(p[1]) $
	else thermal = tmp
	chi2 = total( (ylr[wlr]-thermal[wlr])^2. )
	
	return,chi2
end

;================================================================================

FUNCTION scaledskysub_000, DataSet, Modules, Backbone

        COMMON APP_CONSTANTS
	common fitsky_par, objlr,skylr,llr,line_regions,cont_regions
	common fitbkg_par, xlr,ylr,wlr,temp,thermal


; and now for some constants which describe the various OH spectral bands.

l_boundary = [0.998, 1.067,1.125,1.196,1.252,1.289,1.400,1.472,1.5543,1.6356,1.7253,1.840,1.9570,2.095,2.30d, 2.40]


              ; wavelengths of boundaries between line groups
              ; corresponding to transitions 5-2 to 9-7

; OSIRIS filter ranges, slightly oversized to avoid floating point roundoff
; issues when checking boundary values.
Kbb_range = [1.964, 2.382d]
Hbb_range = [1.472, 1.804d]
Jbb_range = [1.181, 1.417d]
Zbb_range = [0.998, 1.177d]

; Rotational Transitions
description_strings = ['4-1', '5-2', '6-3', '7-4', 'O2', '8-5', '2-0', '3-1', '4-2', '5-3', '6-4', '7-5', '8-6', '9-7', 'final bit', 'end']
l_rotlow = [1.00852,1.03757,1.09264,1.15388,1.22293,1.30216,1.45190,1.52410,1.60308,1.69037,1.78803,2.02758,2.18023,1.02895,1.08343,1.14399,1.21226,1.29057,1.43444,1.50555,1.58333,1.66924,1.76532,2.00082,2.15073d]
l_rotmed = [1.00282,1.02139,1.04212,1.07539,1.09753,1.13542,1.15917,1.20309,1.22870,1.28070,1.30853,1.41861,1.46048,1.48877,1.53324,1.56550,1.61286,1.65024,1.70088,1.74500,1.79940,1.97719,2.04127,2.12496,2.19956d]

;----------------------------


    functionName = 'scaledskysub_000'
    thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
    ; save the starting time
    T = systime(1)

    drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1

    ; check integrity
	; no, don't do this 'cause it requires you to modify define_module...
;    stModule =  check_module( DataSet, Modules, Backbone, functionName )
;    if ( NOT bool_is_struct ( stModule ) ) then $
;       return, error ('ERROR IN CALL ('+strtrim(functionName)+'): Integrity check failed.')
;    ; verify the bits (checks the flags are consistent etc)
    nFrames = Backbone->getValidFrameCount(DataSet.Name)
    check_bits, DataSet.Frames, DataSet.IntFrames, DataSet.IntAuxFrames, nFrames



;	if tag_exist( Modules[thisModuleIndex], "Thermal_Method") then Thermal_Method = string(Modules[thisModuleIndex].Thermal_Method) else Thermal_Method="IGNORE"
	if tag_exist( Modules[thisModuleIndex], "Scale_K_Continuum") then Scale_K_Continuum = string(Modules[thisModuleIndex].Scale_K_Continuum) else Scale_K_Continuum="YES"
        if tag_exist( Modules[thisModuleIndex], "max_sky_fraction") then maxfrac = float(Modules[thisModuleIndex].max_sky_fraction) else maxfrac=0.25
	if tag_exist( Modules[thisModuleIndex], "min_sky_fraction") then minfrac = float(Modules[thisModuleIndex].min_sky_fraction) else minfrac=0.10
	if tag_exist( Modules[thisModuleIndex], "line_halfwidth") then linehalfwidth = fix(Modules[thisModuleIndex].line_halfwidth) else linehalfwidth=4
	if tag_exist( Modules[thisModuleIndex], "show_plots") then show_plots = strupcase(strtrim(Modules[thisModuleIndex].show_plots, 2)) eq "YES" else show_plots=1
	; TODO what is the optimum default for OSIRIS???




	pm_y = 5  ; how many panels in the plot?

	;===== First, read in the sky cube which is to be subtracted. ===== 
	
    skyfilename = drpXlateFileName(Modules[thisModuleIndex].CalibrationFile)
    if ( NOT file_test ( skyfilename ) ) then $
       return, error ('ERROR IN CALL ('+strtrim(functionName)+'): Sky cube ' + $
                      strtrim(string(skyfilename),2) + ' not found.' )
	if (strmid(skyfilename,4,5,/reverse_offset) ne '.fits') then skyfilename += ".fits" 
	sky = float(readfits(skyfilename,hdrs))
	sky_hold = sky
        sky_IntFrame = readfits(skyfilename, ext=1) 
	sky_IntAuxFrame = readfits(skyfilename, ext=2) ; mask out bad pixels (outside FoV, etc) using OSIRIS quality flag extension
	wbad = where(sky_IntAuxFrame eq 0, badct)
	if badct gt 0 then sky[wbad] = !values.f_nan
	
	sky = transpose(sky, [1,2,0]) ; re-arrange to wavelength last.
        sky_hold = transpose(sky_hold, [1,2,0])

	skyfilter = sxpar(hdrs, 'SFILTER')
	crvals = sxpar(hdrs,'CRVAL1') ; get wavelength solution for sky
	cdelts = sxpar(hdrs,'CDELT1')
	crpixs = sxpar(hdrs,'CRPIX1')
	naxiss = sxpar(hdrs,'NAXIS1')
	lambdas = ((dindgen(naxiss)+1-crpixs)*cdelts+crvals) /1000.0
	skyinterp=0

	
    ;====== loop over the input sets =====
    for i=0, nFrames-1 do begin

	;=== Read in the Input data ===
		obj=*DataSet.Frames[i] 
                quality= *DataSet.IntAuxFrames[i] 
		wbad = where(quality eq 0, badct)
		;obj0 = *DataSet.Frames[i]
		if badct gt 0 then obj[wbad] = !values.f_nan 
		;atv, [transpose(obj ne 0), transpose(quality)],/bl
                
		delvarx, quality
		obj = transpose(obj, [1,2,0]) ; re-arrange to wavelength last.
                

		; TODO re-work this using EXTAST3 for generality.
		

		;objfilter = sxpar(*Dataset.Headers[i], 'SFILTER')
		objfilter = sxpar(*DataSet.Headers[i], 'SFILTER')
		if objfilter ne skyfilter then $
	       return, error ('ERROR IN INPUT DATA ('+strtrim(functionName)+'): Sky cube ' + $
	                      strtrim(string(skyfilename),2) + ' has filter '+skyfilter+', but the object data is '+objfilter+'. These must match!' )
	
		crvalo = sxpar(*DataSet.Headers[i],'CRVAL1')
		cdelto = sxpar(*DataSet.Headers[i],'CDELT1')
		crpixo = sxpar(*DataSet.Headers[i],'CRPIX1')
		xsize  = sxpar(*DataSet.Headers[i],'NAXIS2')
		ysize  = sxpar(*DataSet.Headers[i],'NAXIS3')
		zsize  = sxpar(*DataSet.Headers[i],'NAXIS1')
		lambda = ((dindgen(zsize)+1-crpixo)*cdelto+crvalo) / 1000.0 ; wavelen in microns
	
		lrange = where((lambda ge zbb_range[0] and lambda le zbb_range[1]) or (lambda ge jbb_range[0] and lambda le jbb_range[1]) or (lambda ge hbb_range[0] and lambda le hbb_range[1]) or (lambda ge kbb_range[0] and lambda le kbb_range[1]))
		if (n_elements(lambdamask) eq 0) then mrange = lrange else  mrange = where(lambda ge lambdamask[0] and lambda le lambdamask[1])
		
		;estimate noise in object cube
		objf = obj[where(finite(obj))]
		sky, objf, centre, sigma
		; TODO take advantage of the uncertainty image to compute the threshhold
		; that way?
		message, /info,'background level = '+strtrim(string(centre),2)
		message, /info,'std deviation = '+strtrim(string(sigma),2)
		
		
	;=== flag 'sky' spaxels in the object data cube ===
		; Algorithm:
		; 1. Determine how many spectral pixels are < 2 sigma for each spaxel.
		; 2. determine how many spectral pixels are finite for each spaxel, and
		;     mark as 'good' those which have at least half the pixels finite 
		; 3. then figure out how many have been 'flagged' above, as having low values
		; 4. compute the ratio of #flagged/#good for each spaxel
		; 5. The spaxels which have the highest ratio are probably sky.
		; 6. If necessary, adjust the threshholds to ensure there are a
		;    reasonable number of sky spaxels selected.


		;create array to hold flags and intermediate quantities
		flagdata = fltarr(xsize,ysize,zsize)
		ratio_im = fltarr(xsize,ysize) ; ratio of 'sky' to total pixels 
		good_im = fltarr(xsize,ysize) ; good pixels
		image = fltarr(xsize,ysize) ; collapsed image


		; Account for edge effects (saw edited in)
		edge = obj

		for iii=0, xsize-1 do begin
			for jjj=0, ysize-1 do begin
					specabs = abs(edge[iii,jjj,*]) 
					if min(specabs) eq 0.0 then edge[iii,jjj,*] = 0.0		
			endfor
                     endfor


		;flag voxels which have LOW values, no more than 2 sigma above the cube mean.
		flag = where(finite(obj) and obj lt centre+2*sigma and edge ne 0.0) ;saw edited here
		;flag = where(finite(obj) and obj lt centre+2*sigma) ; old 
		flagdata[flag] = 1


	
		; which spaxels have at least half the spectral pixels finite?
		finite_count_im = total(finite(obj[*,*,mrange]),3)
		good_im = (finite_count_im gt n_elements(mrange)/2) 
		; MDP addition for OSIRIS: Also discard all pixels within 1 pixel of the
		; edge of the FOV. This is because those edge pixels are not always properly
		; illuminated.
		good_im =  erode(good_im , replicate(1,5,3))	; SAW edited where edges on long sides are treated better
		;good_im =  erode(good_im , replicate(1,3,3))
		if (total(good_im) lt 1) then return, error('no good spaxels in the object cube!')


		
		flag_im = total((flagdata[*,*,mrange] gt 0.5),3)
		ratio_im = (float(flag_im)/finite_count_im) * good_im   ; what is ratio of flagged low (sky) vs. good pixels?
		image = total(obj[*,*,mrange],3,/nan) / finite_count_im * good_im
	
		;choose pixels which seem to be sky (ie >95% of spectral pixels are flagged)
		thresh = 0.80	;0.95 - saw edited
		mask = fltarr(xsize,ysize)
		r2 = where(ratio_im ge thresh,r2i)
		if (r2i gt 0) then mask[r2] = 1
		r_str = string(format='(f5.1)',100.*r2i/total(good_im))
		message, /info,strtrim(string(r2i),2)+' spaxels ('+r_str+ '% of good pixels) are designated as sky'
	
		;threshold ratio for fraction 'minfrac' of spatial pixels to be 'sky'
		if (1.*r2i/total(good_im) lt minfrac) then begin
		    r_str = string(format='(f4.1)',100.*minfrac)
		    message, /info,'this is too small - will increase it to '+r_str+'%'
		    xcum = findgen(xsize*ysize)+1
			wnan = where(~finite(ratio_im),nanct)
			if nanct gt 0 then ratio_im[wnan]=0
		    hcum = ratio_im(sort(ratio_im))
			; TODO FIXME
			; I think this threshhold is computed bogusly. - MDP
			; Or at least, it's not doing what it says it does, though what it
			; actually does may well be OK.
			; This finds pixels within 10% of the peak, as opposed to
			; the best 10% total of the pixels. 
			; Ignoring for now.
		    thresh = hcum[where(xcum/max(xcum) ge 1.-minfrac)]
		    thresh = thresh[0]
		    mask= ratio_im ge thresh
		endif
	
		if (1.*r2i/total(good_im) gt maxfrac) then begin
			message, /info, " That is too large a fraction of the image marked as sky!"
			message,/info,  "Decreasing it to "+strtrim(string(maxfrac),2)+" of the total pixels."
	
			; algorithm: select the ratios, sort them to find the threshhold, then
			; use that to select the pixels.
			ratios = ratio_im[where(good_im, goodcount)]
			sorted_ratios = ratios[sort(ratios)]
			thresh = sorted_ratios[  (1-maxfrac)*goodcount+1 ]

			
			mask = ratio_im ge thresh
			r2i = total(mask)
			r_str = string(format='(f5.1)',100.*r2i/total(good_im))
			message, /info,strtrim(string(r2i),2)+' spaxels ('+r_str+ '% of good pixels) are designated as sky'
			; TODO another way of doing this would be
			;highest_ratios = sorted_ratios[ ( (1-maxfrac)*goodcount+1):*]
			;highest_indices_ratios = (sort(ratios))[((1-maxfrac)*goodcount+1):* ] ; those are the indices into 'ratios'
			;highest_indices_ratioim= (where(good_im))[highest_indices_ratios]
			;mask2 = ratio_im*0
			;mask2[highest_indices_ratioim]=1
		
			; for one test case, this doesn't make much difference. SO leave the
			; code as-is for now.
			
		endif
	
	;=== Extract the summed spectra of flagged spaxels.
		;  This uses the same spaxel mask for both the sky and object cubes.
		; TODO matrix-ize this!!!
		objspectrum = dblarr(zsize)
		skyspectrum = dblarr(zsize)
		loop = where(mask gt 0.5)
		for j=0,zsize-1 do begin
		    objslice = obj[*,*,j]
		    pos = where(mask gt 0.5 and finite(objslice),pos_count)
		    if (pos_count ge 1) then begin
		        if (pos_count) lt 3 then begin
		            objspectrum[j] = mean(objslice[pos])
		        endif else begin
		            gslice = objslice[pos]
		            med = median(gslice)
		            sdv = stddev(gslice)
		            avg = mean(gslice[where(gslice lt med+3*sdv and gslice gt med-3*sdv)])
		            objspectrum[j] = avg
		        endelse
		    endif
                    skyslice = sky[*,*,j]
		    pos = where(mask gt 0.5 and finite(skyslice),pos_count)
		    if (pos_count ge 1) then begin
		        if (pos_count) lt 3 then begin
		            skyspectrum[j] = mean(skyslice[pos])
		        endif else begin
		            gslice = skyslice[pos]
		            med = median(gslice)
		            sdv = stddev(gslice)
		            avg = mean(gslice[where(gslice lt med+3*sdv and gslice gt med-3*sdv)])
		            skyspectrum[j] = avg
		        endelse
		    endif
		endfor
		
                ;=== remove thermal background from integrated OH spectrum ===
                                ;QMK agrees with MDP that this does
                                ;not produce an accurate
                                ;representation of the K band
                                ;background.  Instead follow method of
                                ;JLu and find continuum via
                                ;smoothing.  Have implemented optional
                                ;continuum scaling below

	
;		sxaddhist, 'IFS_OH_SCALESKY: using thermal background method = '+thermal_method, *dataset.headers[i]
;		case strupcase(thermal_method) of
;		"REMOVE_BOTH":  begin
;			; fit the sky's thermal component, remove it, and leave it out when
;			; you're done.
;			; **and do the same for the science data, too!!***
;		
;			message, /info,'removing thermal component from OH spectrum'
;			temp = 280
;			xlr = lambda[lrange]
;			ylr = skyspectrum[lrange]
;			wlr = where(finite(ylr) and ylr ne 0)
;			; TODO where does 19 come from??!?
;			for j=0,19 do begin
;				message, /info, "Fitting thermal background, iteration = "+string(j, format="(I2)")
;				; model parameters are
;				;   0: constant offset
;				;   1: normalization factor
;				;   2: temperature
;			    p_init = [min(ylr[wlr]),skyspectrum[max(lrange[wlr])],temp]
;			    result = amoeba(1.e-5,function_name='scaledskysub_fitbkg',p0=[p_init],scale=[p_init/5.])
;			    diff = ylr - thermal
;				; mask out all the lines - only fit on the continuum here!
;			    wlrnew = where(finite(ylr) and ylr ne 0 and diff lt median(diff[wlr])+2.0*stddev(diff[wlr]))
;				; stop iterating if we've converged on a consistent set of pixels to
;				; mask out.
;				if n_elements(wlr) eq n_elements(wlrnew) then break
;				;print, "Iter:"+strc(i)+"  ", n_elements(wlrnew), n_elements(wlr)
;				;print, "       ", result
;			    wlr = wlrnew
;			endfor
;			tmp1 = lambda^(-5.)/(exp(14387.7/(lambda*abs(result[2])))-1)
;			tmp2 = xlr^(-5.)/(exp(14387.7/(xlr*abs(result[2])))-1)
;			thermal = result[0] + tmp1 / max(tmp2)*abs(result[1])
;                        plot, lambda, skyspectrum, yr=[-0.05, 0.05], $
;		   		xrange=[min(lambda[mrange]),max(lambda[mrange])]
;			oplot, lambda, thermal, color='0000FF'x; fsc_color('red')
;			; MDP
;			;thermal *=0
;			skyspectrum0 = skyspectrum
;			skyspectrum = skyspectrum - thermal
;		end
;		"LEAVE": begin
;			; remove the thermal background at first, so you can properly fit the
;			; scaling parameters for the sky, then add it back in at the end?
;			message, "This option not yet implemented."
;		end
;		"IGNORE": begin
;			; Do nothing about the thermal background at all. Appropriate for
;			; short-wavelength observations.
;			;
;			; 2007-12-05: Actually, the 'IGNORE' option seems to do a relatively
;			; decent job for my Kbb data as well. I'm not entirely 100% sure whether
;			; it's scaling the continuum inappropriately here - I think the code
;			; does end up affecting the final continuum values of the subtracted
;			; cube via this method. But actually it seems to work surprisingly well
;			; to ignore the thermal component even for Kbb. 
;			thermal = fltarr(n_elements(skyspectrum))
;		end
;		endcase
	;=== some plotting (do this right before the sky subtraction optimization so that code can overplot)
		if keyword_set(show_plots) then begin
			window, xs=600, ys=800
			pm_y = 5
			!p.multi=[0,3,pm_y,0]
		
			; PLOT 1
			;imdisp, alogscale(image), /axis, /xs, /ys, charsize=1.3, title="Image (log scale)"
			;sky, image, s1, s2
			;plotmin = s1-s2
			plotmin=min(image,/nan)
			imdisp, alogscale(image, plotmin, max(image,/nan)), /axis, /xs, /ys, charsize=1.3, title="Image (log scale)"
			imdisp, good_im, /axis, /xs, /ys, charsize=1.3, title="Good spaxels"
			imdisp, mask, /axis, /xs, /ys, charsize=1.3, title="Spaxels used for sky"

			xyouts, 0.2, 0.98, /normal, "Scaled Sky Subtraction for "+Dataset.Name, charsize=1.3
			
			; PLOT 2
			!p.multi=[pm_y-1,1,pm_y,0]
			;plot sky spectrum
			plot,[lambda,lambda],[skyspectrum,objspectrum],charsize=1.5,/nodata,$
			  xstyle=1,  $
			   xrange=[min(lambda[mrange]),max(lambda[mrange])],$
			  ; xrange=[min(lambda[lrange]),max(lambda[lrange])],$
			  ystyle=3, title="Input Spectra:    SKY=green/purple    OBJ=cyan/blue", xtitle="Wavelength (micron)", ytitle="Counts"

			for iz=0,n_elements(l_boundary)-1 do begin
				oplot,[l_boundary[iz],l_boundary[iz]],[-1e5,1e5],linestyle=1
				xyouts, l_boundary[iz]+0.005, (!y.crange[1]*0.8+!y.crange[0]*0.2), description_strings[iz],/clip
			endfor
			oplot,lambda,skyspectrum
			; label the spectra. The precise plot positions are pretty arbitrary.
			xyouts, lambda[min(lambda[lrange])+20], skyspectrum[min(lambda[lrange])+20]+0.01, "SKY", color='00FF00'x,/clip; fsc_color('green'),/clip
			xyouts, lambda[min(lambda[lrange])+20], objspectrum[min(lambda[lrange])+20]+0.01, "OBJ", color='FFFF00'x,/clip; fsc_color('cyan'),/clip
		endif
		
	;=====  optimise sky subtraction =====
		; Here at last, the heart of the routine.
		; Algorithm:
		;   For each spectral band range,  check if there are pixels in that
		;   range with finite sky and object values. If not, continue. 
		;   If so, find pixels which are > 1 sigma in the sky (i.e. are lines)
		;   Make a mask which selects those pixels, convolved by the line width. 
		;   Then call the fitsky routine, which attempts to minimize
		;     the residuals in the lines, after the continuum in the lines has 
		;     been subtracted by linearly interpolating the continuum on either side.
		;   	

		npixw=2*linehalfwidth ; full width in pixels of unresolved emission line 
		rscale0 = dblarr(n_elements(skyspectrum))*0.
	
		; revise this to ignore the broad sky thermal background
		backgnd = median(skyspectrum, 10*linehalfwidth)
                skyspectrum2 = skyspectrum - backgnd
                
                r = 1.0 ; QMK
                
		for j=0L,14 do begin
			lr = where(lambda ge l_boundary[j] and lambda lt l_boundary[j+1] $
					   and finite(skyspectrum) and finite(objspectrum), range_count)
			if range_count eq 0 then continue
			skylr = skyspectrum[ lr ] 
			skylr2 = skyspectrum2[ lr ] 
			objlr = objspectrum[ lr ] 
			llr =  lambda[ lr ] 
                        
                        rhold = r; QMK to check to "final bit"

			; find pixels > 1 sigma
	        ;w_skylines = where(skylr gt median(skylr)+stddev(skylr),skylines_count)
			; Use the version with the continuum removed to determine where the
			; lines are.
	        w_skylines = where(skylr2 gt 10*median(skylr2)+stddev(skyspectrum2),skylines_count)
			
	        if (skylines_count gt 0) then begin
	            line_mask = skylr*0.
	            line_mask[w_skylines] = 10.
				; make a mask for where line regions are, and for where the
				; continuum is. 
	            line_mask = convol(line_mask,replicate(1,npixw),/edge_truncate,/center)
	            line_regions = where(line_mask gt 0,line_count, complement=cont_regions, ncompl = cont_count)
	

				
	            if (line_count ge 3 and cont_count ge 3) then begin
					print, 'optimising '+description_strings[i]+' transitions'
					; plot each region in color, skipping the gaps (rather than
					; drawing straight lines to connect across them, which is IDL
					; plot's default behavior)
					if keyword_set(show_plots) then begin
		                tmpy = skylr & tmpy[line_regions]=!values.f_nan
		                oplot,llr,tmpy,min_value=-9999, color='00FF00'x ; fsc_color('green')
		                tmpy = skylr & tmpy[cont_regions]=-1.e5
		                oplot,llr,tmpy,min_value=-9999,color='FF00FF'x; fsc_color('purple')
                                tmpy = objlr & tmpy[line_regions]=-1.e5
		                oplot,llr,tmpy,min_value=-9999, color='FFFF00'x; fsc_color('cyan');, /lines
		                tmpy = objlr & tmpy[cont_regions]=-1.e5
		                oplot,llr,tmpy,min_value=-9999,color='FF0000'x; fsc_color('blue');, /lines
                               	endif
	
					; call the fitting routine
	                r = amoeba(1.e-5,function_name='scaledskysub_fitsky',p0=[1.],scale=[0.5])
	                flineres = (objlr[line_regions] - $
	                  interpol(objlr[cont_regions],llr[cont_regions],llr[line_regions])) - $
	                  (skylr[line_regions] - $
	                   interpol(skylr[cont_regions],llr[cont_regions],llr[line_regions]))*r[0]
	                fmed = median(flineres)
	                fsdv = stddev(flineres)
	                fclip = where(abs(flineres) gt fmed+3*fsdv,fclip_count)
	                if (fclip_count gt 0) then begin
	                    line_regions = line_regions[where(abs(flineres) le fmed+3*fsdv)]
	                    if (n_elements(line_regions) ge 3) then $
	                      r = amoeba(1.e-5,function_name='scaledskysub_fitsky',p0=[1.],scale=[0.5])
	                endif
	
                        if(llr[0] ge 2.3) then begin  ;QMK added
                           print,'Setting scaling for final bit to value for 9-7'
                           r = rhold
                        endif
					
	                print,'    using ',strtrim(string(n_elements(line_regions)),2),$
	                  ' pixels for lines and ',strtrim(string(n_elements(cont_regions)),2),$
	                  ' for continuum estimation'
	                print,'    OH spectrum scaling = ',strtrim(string(r),2)

                                        rscale0[lr] = r
					sxaddhist, "IFS_OH_SCALESKY: Wavelength range = "+sigfig(l_boundary[j], 4)+$
								" - "+sigfig(l_boundary[j+1], 4), *Dataset.Headers[i]
					sxaddhist, "IFS_OH_SCALESKY:  Scaling factor is "+sigfig(r, 3), *Dataset.Headers[i]
					;stop
	            endif
		    endif ; if skylines_count gt 0
		endfor
		range0 = where(rscale0 ne 0.,range0_count)
		if (range0_count gt 0) then $
		  rscale = interpol(rscale0[range0],lambda[range0],lambda) else $
		  rscale = rscale0
		skyspectrumr = skyspectrum*rscale


	;=====  new bit - do simple rotational correction ======
		do_rot = 'yes'
		do_rot = 'NO' ; MDP debugging - skip the rotational bit for now, until the rest is 100% working!
		if (do_rot eq 'yes') then begin
				message, /info, "Calculating scaling for rotational terms"
			
			finitepix = where(finite(skyspectrum) and finite(objspectrum),finitepix_count)
			if (finitepix_count gt npixw) then begin
			    ;was finitepix = finitepix[where(finitepix gt min(lrange) and finitepix lt max(lrange))]
			    finitepix = finitepix[where(finitepix ge min(lrange) and finitepix le max(lrange))]
			    skylr = skyspectrumr[finitepix]
			    objlr = objspectrum[finitepix]
			    llr = lambda[finitepix]
				; xx1 is indices of pixels which are greater than 1 sigma
			    xxx1 = where(abs(skylr) gt 10*median(skylr)+stddev(skylr),xxx1_count)
			    if (xxx1_count gt 0) then begin
			
			        lowpos = [0]
			        for j=0,n_elements(l_rotlow)-1 do begin
			            x = where(llr[xxx1] gt l_rotlow[j]-npixw*cdelto and llr[xxx1] lt l_rotlow[j]+npixw*cdelto,x_count)
			            if (x_count gt 0) then lowpos = [lowpos,x]
			        endfor
			        lowpos = lowpos[1:n_elements(lowpos)-1]
			
			        medpos = [0]
			        for j=0,n_elements(l_rotmed)-1 do begin
			            x = where(llr[xxx1] gt l_rotmed[j]-npixw*cdelto and llr[xxx1] lt l_rotmed[j]+npixw*cdelto,x_count)
			            if (x_count gt 0) then medpos = [medpos,x]
			        endfor
			        medpos = medpos[1:n_elements(medpos)-1]
			
					; hipos should be everything that is neither lowpos nor medpos?
			        hipos = [0]
			        for j=0,n_elements(xxx1)-1 do begin
			            x1 = where(lowpos eq j,x1_count)
			            x2 = where(medpos eq j,x2_count)
			            if (x1_count eq 0 and x2_count eq 0) then hipos = [hipos,j]
			        endfor
			        hipos = hipos[1:n_elements(hipos)-1]
			
			        line_mask = skylr*0.
			        line_mask[xxx1] = 10.
			        line_mask = convol(line_mask,replicate(1,npixw),/edge_truncate,/center)
			        cont_regions = where(line_mask eq 0,cont_count)
			        line_mask = skylr*0
			        line_mask[xxx1[lowpos]] = 10.
			        line_mask = convol(line_mask,replicate(1,npixw),/edge_truncate,/center)
			        low_regions = where(line_mask gt 0,low_count)
			        line_mask = skylr*0
			        line_mask[xxx1[medpos]] = 10.
			        line_mask = convol(line_mask,replicate(1,npixw),/edge_truncate,/center)
			        med_regions = where(line_mask gt 0,med_count)
			        line_mask = skylr*0
			        line_mask[xxx1[hipos]] = 10.
			        line_mask = convol(line_mask,replicate(1,npixw),/edge_truncate,/center)
			        hi_regions = where(line_mask gt 0,hi_count)
			
			if (hi_count ge 3 and med_count ge 3 and low_count ge 3 and cont_count ge 3) then begin
			    
			    line_regions = hi_regions
			    r = amoeba(1.e-5,function_name='scaledskysub_fitsky',p0=[1.],scale=[0.1])
			    flineres = (objlr[line_regions] - $
			                interpol(objlr[cont_regions],llr[cont_regions],llr[line_regions])) - $
			      (skylr[line_regions] - $
			       interpol(skylr[cont_regions],llr[cont_regions],llr[line_regions]))*r[0]
			    fmed = median(flineres)
			    fsdv = stddev(flineres)
			    fclip = where(abs(flineres) gt fmed+3*fsdv,fclip_count)
			    if (fclip_count gt 0) then begin
				fclop = where(abs(flineres) lt fmed+3*fsdv, fclop_count)
			        if (fclop_count gt 0) then begin 	; added in SAW/JONELLE IN CASE CLOP NOT FOUND	 
					line_regions = line_regions[fclop]
			        	if (n_elements(line_regions) ge 3) then $
			         	 r = amoeba(1.e-5,function_name='scaledskysub_fitsky',p0=[1.],scale=[0.1])
				endif
			    endif
			    rhi = abs(r[0])
			    print,'high rotational OH scaling ',rhi
			
			    line_regions = med_regions
			    r = amoeba(1.e-5,function_name='scaledsksub_fitsky',p0=[1.],scale=[0.1])
			    flineres = (objlr[line_regions] - $
			                interpol(objlr[cont_regions],llr[cont_regions],llr[line_regions])) - $
			      (skylr[line_regions] - $
			       interpol(skylr[cont_regions],llr[cont_regions],llr[line_regions]))*r[0]
			    fmed = median(flineres)
			    fsdv = stddev(flineres)
			    fclip = where(abs(flineres) gt fmed+3*fsdv,fclip_count)
			    if (fclip_count gt 0) then begin
				fclop = where(abs(flineres) lt fmed+3*fsdv, fclop_count)
			        if (fclop_count gt 0) then begin 
					line_regions = line_regions[fclop]
			        	if (n_elements(line_regions) ge 3) then $
			         	 r = amoeba(1.e-5,function_name='scaledskysub_fitsky',p0=[1.],scale=[0.1])
				endif
			    endif
			    rmed = abs(r[0])
			    print,'P1(3.5) & R1(1.5) rotational OH scaling ',rmed
			    
			    line_regions = low_regions
			    r = amoeba(1.e-5,function_name='scaledskysub_fitsky',p0=[1.],scale=[0.1])
			    flineres = (objlr[line_regions] - $
			                interpol(objlr[cont_regions],llr[cont_regions],llr[line_regions])) - $
			      (skylr[line_regions] - $
			       interpol(skylr[cont_regions],llr[cont_regions],llr[line_regions]))*r[0]
			    fmed = median(flineres)
			    fsdv = stddev(flineres)
			    fclip = where(abs(flineres) gt fmed+3*fsdv,fclip_count)
			    if (fclip_count gt 0) then begin
				fclop = where(abs(flineres) lt fmed+3*fsdv, fclop_count)
			       if (fclop_count gt 0) then begin 
					line_regions = line_regions[fclop]
			        	if (n_elements(line_regions) ge 3) then $
			         	 r = amoeba(1.e-5,function_name='scaledskysub_fitsky',p0=[1.],scale=[0.1])
				endif
			    endif
			    rlow = abs(r[0])
			    print,'P1(2.5) & Q1(1.5) rotational OH scaling ',rlow
			    
			    lowscale = [0]
			    for j=0,n_elements(l_rotlow)-1 do begin
			        x = where(lambda gt l_rotlow[j]-npixw*cdelto and lambda lt l_rotlow[j]+npixw*cdelto,x_count)
			        if (x_count gt 0) then lowscale = [lowscale,x]
			    endfor
			    lowscale = lowscale[1:n_elements(lowscale)-1]
			
			    medscale = [0]
			    for j=0,n_elements(l_rotmed)-1 do begin
			        x = where(lambda gt l_rotmed[j]-npixw*cdelto and lambda lt l_rotmed[j]+npixw*cdelto,x_count)
			        if (x_count gt 0) then medscale = [medscale,x]
			    endfor
			    medscale = medscale[1:n_elements(medscale)-1]
			
			    rscale_x = rscale * rhi
			    rscale_x[medscale] = rscale_x[medscale]*rmed/rhi
			    rscale_x[lowscale] = rscale_x[lowscale]*rlow/rhi
			    rscale = rscale_x
			    
			endif
			    endif                       ; xxx1_count > 0
			endif                           ; finitepix > npixw
		endif else begin ; do_rot
			message, /info, "NOT adjusting for rotational term changes!"
		endelse
		;---  end of new rotational bit
	
			
	;=====  plot image & masks =====

                
		;;; Perform continuum background fitting for only Kband observations

		if crvalo gt 1900.0 and Scale_K_Continuum eq 'YES' then begin 
			smskyRaw = smooth(skyspectrum, 40)
			smobjRaw = smooth(objspectrum, 40) ; QMK
                        contscale = smobjRaw / smskyRaw ; QMK
                                ;to deal with possible telluric in obj
                                ;sky which should be ok because
                                ;continuum is pretty flat here -  QMK
                        ;if(skyfilter eq 'Kbb') then contscale[0:400] = median(smobjRaw[0:400]) / median(smskyRaw[0:400]) ; QMK                        		       skyspectrumr = (skyspectrum - smskyRaw)*rscale + smskyRaw*contscale ;QMK
			print,'Performing scaled continuum for K band observations'
			print,''
		endif 
                if crvalo gt 1900.0 and Scale_K_Continuum eq 'NO' then begin
                        skyspectrumr = skyspectrum*rscale
                        print,'Not scaling K band continuum'
                   endif
                if crvalo le 1900.0 then begin
			skyspectrumr = skyspectrum*rscale 
			print,'Observations are below 1.9 microns - no continuum sky subtraction'	
                        Scale_K_Continuum = 'No'
		endif
                
                sxaddhist, 'IFS_OH_SCALESKY: using continuum scaling = '+Scale_K_Continuum, *dataset.headers[i]
                
		if keyword_set(show_plots) then begin
		
			; PLOT 3
			fullsize = max(rscale) - min(rscale) ; used to draw plot conveniently scaled
			plot, lambda, rscale, /xs, charsize=1.5, xrange=[min(lambda[lrange]),max(lambda[lrange])], $
				yrange = [min(rscale)-fullsize*0.5, max(rscale)+fullsize*0.5],/ys, $
				title="Scaling Factor", ytitle="Ratio"
		
			; PLOT 4
                        colors = [!p.color, '0000FF'x, 'FF0000'x]
			colors = [!p.color, '0000FF'x, 'FFFF00'x]
			
                        plot,[lambda,lambda],[objspectrum,objspectrum-skyspectrumr],/nodata,charsize=1.5,$
			  ystyle=3,$
			  xstyle=1,xrange=[min(lambda[mrange]),max(lambda[mrange])], $
			  xtitle="Wavelength (microns)", ytitle="Counts", title="Comparison of regular & scaled skys"
			oplot,lambda,objspectrum
			oplot,lambda,objspectrum-skyspectrum,color=colors[1]
			oplot,lambda,objspectrum-skyspectrumr,color=colors[2]
	
		
			smobj = smooth(objspectrum-skyspectrum, 80)
			rms1 = stddev(objspectrum-skyspectrum - smobj)
			smobj2 = smooth(objspectrum-skyspectrumr, 80)
			rms2 = stddev(objspectrum-skyspectrumr - smobj2)
				message, /info, "continuum-suppressed spectrum RMS BEFORE: "+ sigfig(rms1,3)
				message, /info, "continuum-suppressed spectrum RMS AFTER:  "+ sigfig(rms2,3)
		
		
			legend, /top, /right, $
				["Original Object Cube Spectrum", "Obj - Orig. Sky (RMS="+sigfig(rms1,3)+")", "Obj - Scaled Sky (RMS="+sigfig(rms2,3)+")"],$
				colors = colors, $
				lines=[0,0,0], psym=[-3,-3, -3], box=0, textcolors = replicate('00FFFF'x,4)
			wshow
			
			; PLOT 5
			plot, lambda, objspectrum-skyspectrum - smobj, /nodata, xrange=[min(lambda[mrange]),max(lambda[mrange])], /xs, $
				xtitle = "Wavelength (micron)", ytitle = "Continuum-subtracted spectrum", charsize=1.5
			oplot, lambda, objspectrum-skyspectrum - smobj, color= colors[1]; fsc_color('red')
			oplot, lambda, objspectrum-skyspectrumr - smobj2, color=colors[2]; fsc_color('blue')
			xyouts, (0.2*!x.crange[1]+0.8*!x.crange[0]), (0.8*!y.crange[1]+0.2*!y.crange[0]), "Regular Subtraction", color=colors[1];fsc_color('red')
			xyouts, (0.6*!x.crange[1]+0.4*!x.crange[0]), (0.8*!y.crange[1]+0.2*!y.crange[0]), "Scaled Subtraction", color=colors[2];fsc_color('blue')
	
		endif
	

	;===== now actually apply the scaling to the data cube! =====
		if not(keyword_set(test_keyword)) then begin

			; NEW version for PIPELINE: 
			; re-arrange the scaled sky cube into the pipeline format with
			; pointers etc, then use frame_op to subtract it. 

			;apply same scaling to whole cubes
			print,'subtracting OH lines from entire cube'
			;therm_cube = rebin(reform(thermal, [1,1,zsize]), xsize, ysize, zsize)
			rscale_cube = rebin(reform(rscale, [1,1,zsize]), xsize, ysize, zsize)

			if crvalo gt 1900.0 and Scale_K_Continuum eq 'YES' then begin 
                            print, 'Performing Scaled K Continuum '
			    contscale_cube = rebin(reform(contscale, [1,1,zsize]), xsize, ysize, zsize)

                    	    smsky_cube = smooth(sky_hold, [1,1,40], /NAN)
                           
                            smsky_out = smsky_cube*contscale_cube

                    	    smsky_cube = rebin(reform(smsky_cube, [xsize,ysize,zsize]), xsize, ysize, zsize)
;	  		    scaledsky = (sky_hold - smsky_cube - therm_cube)*rscale_cube + smsky_cube*contscale_cube + therm_cube  
                            scaledsky = (sky_hold - smsky_cube)*rscale_cube + smsky_cube*contscale_cube 


			endif else if crvalo le 1900.0 or Scale_K_Continuum eq 'NO' then begin
			    ;scaledsky = (sky_hold-therm_cube)*rscale_cube 
  			    scaledsky = (sky_hold)*rscale_cube
      			endif

			; re-arrange to OSIRIS axis order, and set all NaNs to zero, per OSIRIS
			; convention
			scaledsky = transpose(scaledsky,  [2,0,1])
                        
                        wnan = where(~finite(scaledsky ), nanct)
			if nanct gt 0 then scaledsky[wnan]=0
			rscale_cube = transpose(rscale_cube,  [2,0,1])
                        
                        
			pcd_scaledskyFrame = ptr_new(scaledsky)
			; TODO proper error propagation here!
			pcd_scaledskyIntFrame = ptr_new(sky_IntFrame*rscale_cube)
			pcb_scaledskyIntAuxFrame = ptr_new(sky_IntAuxFrame)
			if nanct gt 0 then (*pcb_scaledskyIntAuxFrame)[wnan]=0
	
	;tmp0 = transpose(*DataSet.Frames[i])
	;tmp0q = transpose(*DataSet.IntAuxFrames[i])
			
                        
                        

	     	v_Status = frame_op_ssr( DataSet.Frames[i], DataSet.IntFrames[i], DataSet.IntAuxFrames[i], $
			                      '-', pcd_scaledskyFrame, pcd_scaledskyIntFrame, pcb_scaledskyIntAuxFrame, 1 )

	;tmp2 = transpose(*DataSet.Frames[i])
	;tmp2q = transpose(*DataSet.IntAuxFrames[i])
	;tmpsky = transpose(*pcd_scaledskyFrame)
	;tmpskyq = transpose(*pcb_scaledskyIntAuxFrame)
	
	;atv, [tmp0, tmpsky, tmp2, tmp0q, tmpskyq, tmp2q],/bl
	;atv, tmp,/bl
			ptr_free, pcd_scaledskyFrame, pcd_scaledskyIntFrame, pcb_scaledskyIntAuxFrame

			if ( NOT bool_is_vector (v_Status) ) then begin
                warning,'WARNING ('+strtrim(functionName)+'): Scaled sky subtraction of dataset '+strg(i)+' failed (0).' 
        	endif else begin
				if ( v_Status(0) ne 1 ) then begin
                     error,'ERROR ('+strtrim(functionName)+'): Scaled sky subtraction of dataset '+strg(i)+' failed (1).' 
                endif else begin
                     add_fitskwd_to_header, DataSet.Headers(i), 1, ['SCALESKY'], ['This cube has been sky-subtracted using Scaled Sky Sub'],['a']
                     add_fitskwd_to_header, DataSet.Headers(i), 1, ['SKYFILE'], [skyfilename], ['a']
                     info,'INFO ('+strtrim(functionName)+'): Scaled sky subtraction of dataset '+strg(i)+' successfully done.'
                endelse
			endelse

			; note: frame_op actually changes the frames in the Dataset
			; structure. So there's no need to update them here; they've
			; already been updated with the subtracted version.
			
			message,/info, "Optimized subtracted cube done!"

		endif
			

	endfor


    RETURN, OK

END
