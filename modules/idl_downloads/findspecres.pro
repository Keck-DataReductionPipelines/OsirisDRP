;-------------------------------------------------------------------------
; NAME: findspecres
;
; PURPOSE: wavelength calibration
;
; INPUT : p_WFrame           : pointer with the frame values
;         p_WIntFrame        : pointer with the intframe values
;         p_WIntAuxFrame     : pointer with the quality values
;         p_Header           : pointer to header for this cube
;         s_LineFile         : absolute path to the lines file (for
;                              the definition of this file see get_linelist.pro)
;         i_FitHalfWindow    : half size of the fit window (10 is good)
;         s_FitFunction      : name of the fit function :
;                              "GAUSSIAN", "LORENTZIAN", "MOFFAT"
;                              ("GAUSSIAN" is good)
;         n_FitTerms         : NTERMS of GAUSSFIT (4 is good)
;         n_FitOrder         : dispersion fit order
;
;   Other parameter
;
;         [DEBUG=DEBUG]      : initialize the debugging mode
;
; OUTPUT : { cd_Center_um     : the measured center positions at the should be center
;            cd_DCenter_um    : the difference bewtween the measured center and the should be position
;            cd_Disp_px       : the dispersion at the measured position
;            vd_Disp_px       : the dispersion as function of wavelength
;            vd_W_um          : the corresponding wavelength 
;            vd_PtsDisp_px    : fit points Dispersions
;            vd_PtsW_um       : fit points Wavelengths
;            vd_PtsDCenter_px : fit points error in center }
;
; ALGORITHM : 
;
; NOTES : - This routine works on cubes only
;         - The debugging option should be enabled always. Then you
;           get some plots that are useful to quickly check whether
;           the wavelength calibration is good or not.
;         - to fit the dispersion as function of wavelength you need
;           at least n_FitOrder+2 measured lines.
;
; ON ERROR : returns ERR_UNKNOWN
;
; STATUS : untested
;
; HISTORY : 24.9.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-------------------------------------------------------------------------

function findspecres, p_WFrame, p_WIntFrame, p_WIntAuxFrame, p_Header, s_LineFile, $
                      i_FitHalfWindow, s_FitFunction, n_FitTerms, n_FitOrder, DEBUG=DEBUG

   functionName = 'findspecres.pro'

   ; parameter checks
   if ( NOT ( s_FitFunction eq "GAUSSIAN" or s_FitFunction eq "LORENTZIAN" or $
              s_FitFunction eq "MOFFAT" ) ) then $
      return, error('ERROR IN CALL (findspecres.pro): Unknown fit function.')

   if ( n_FitTerms le 2 or n_FitTerms ge 7 ) then $
      return, error('ERROR IN CALL (findspecres.pro): n_FitTerms<=6 ('+strg(n_FitTerms)+')')

   if ( n_FitOrder ge 7 ) then $
      return, error('ERROR IN CALL (findspecres.pro): 3<=n_FitOrder<=6 ('+strg(n_FitOrder)+')')

   if ( i_FitHalfWindow le 2 ) then $
      return, error('ERROR IN CALL (findspecres.pro): FitHalfWindow must be ge 2 ('+strg(i_FitHalfWindow)+')')
   ; parameter checks done

   ; create wavelength vector
   vd_L = get_wave_axis ( p_Header, DEBUG=DEBUG )  ; wavelength axis in meter
   vd_L = vd_L * 1.d9 ; in nm
   d_LL = min ( vd_L )
   d_UL = max ( vd_L )

   if ( keyword_set (DEBUG) ) then $
      debug_info,'DEBUG INFO (findspecres.pro): Wavelength : '+strg(d_LL)+','+strg(d_UL)+'nm'

   ; get the lines
   s_Lines = get_linelist( p_Header, 1, s_LineFile, DEBUG=keyword_set(DEBUG) )

   ; get the lines that are in the range
   vi_Mask = where ( s_Lines.vd_Lines_nm gt d_LL and s_Lines.vd_Lines_nm lt d_UL, nLines ) 

   if ( nLines eq 0 ) then $
      return, error ('FAILURE ('+strg(functionName)+'): No lines in range found.')

   vd_Lines_um = s_Lines.vd_Lines_nm(vi_Mask)/1.d3
   d_LL        = d_LL/1.d3
   d_UL        = d_UL/1.d3
   vd_L        = vd_L/1.d3

   if ( keyword_set (DEBUG) ) then $
      debug_info,[ 'DEBUG INFO (findspecres.pro): Wavelength : '+strg(d_LL)+','+strg(d_UL)+'um', $
                   '                              Axis       : '+strg(min(vd_L))+','+strg(max(d_UL))+'um', $
                   '                              NAxis      : '+strg(n_elements(vd_L)) ]

   n_Dims = size (*p_WFrame)
   ; parameters of the individual lines
   d_Blank    = -10000.
   cd_Center  = make_array(/FLOAT,SIZE=n_Dims,VALUE=d_Blank)
   cd_DCenter = make_array(/FLOAT,SIZE=n_Dims,VALUE=d_Blank)
   cd_Disp    = make_array(/FLOAT,SIZE=n_Dims,VALUE=d_Blank)

   vd_LineDisp    = [0.]
   vd_LineDCenter = [0.]
   vd_W           = [0.]

   ; loop over the individual lines
   for j = 0, nLines-1 do begin

      ; find the position of the line in the spectrum
      i_Pos = my_index(vd_L, vd_Lines_um(j))
      i_LPos  = (i_Pos - i_FitHalfWindow) > 0
      i_UPos  = (i_Pos + i_FitHalfWindow) < (n_elements(vd_L)-1)

      info,'INFO (findspecres.pro): Fitting line at '+strg(vd_Lines_um(j))+' microns.'

      vd_Disp = [0.]

      ; loop over the individual spectra
      for i1=0, n_Dims(2)-1 do begin

         for i2=0, n_Dims(3)-1 do begin

            ; find where the pixels are valid
            v_Data  = reform((*p_WFrame)(i_LPos:i_UPos,i1,i2))
            v_Noise = reform((*p_WIntFrame)(i_LPos:i_UPos,i1,i2))
            v_Qual  = reform((*p_WIntAuxFrame)(i_LPos:i_UPos,i1,i2))
;            vb_Mask = where ( byte(extbit( v_Qual, 3 )) and byte(extbit( v_Qual, 0 )) , n_Valid )
            vb_Mask = valid ( v_Data, v_Noise, v_Qual )
            vi_Mask = where ( vb_Mask, n_Valid )
 
            if ( n_Valid gt i_FitHalfWindow ) then begin

               vd_Fit = mpfitpeak ( (vd_L(i_LPos:i_UPos))(vi_Mask), $
                                    v_Data(vi_Mask), vd_Coeff, NTERMS=n_FitTerms, $
                                    GAUSSIAN=s_FitFunction eq "GAUSSIAN", $
                                    LORENTZIAN=s_FitFunction eq "LORENTZIAN", $
                                    MOFFAT=s_FitFunction eq "MOFFAT", $
                                    MEASURE_ERRORS = v_Noise(vi_Mask), perror=vd_Errors )

               cd_Center(i_Pos,i1,i2)  = vd_Coeff(1)
               cd_DCenter(i_Pos,i1,i2) = vd_Coeff(1) - vd_Lines_um(j)
               cd_Disp(i_Pos,i1,i2)    = vd_Coeff(2)

               vd_Disp = [vd_Disp,vd_Coeff(2)]

            endif else $
               warning, 'WARNING ('+strg(functionName)+'): Line '+strg(j)+' fit failed in spectrum '+$
                        strg(i1)+','+strg(i2)+'. Too few valid pixel.'

         end

      end

      if ( keyword_set ( DEBUG ) ) then $
         debug_info,'DEBUG INFO (findspecres.pro): Done with line ' +strg(j)+'.'

      vi_Mask = where ( cd_DCenter(i_Pos,*,*) ne d_Blank, n_Valid )

      if ( n_Valid gt 0 ) then begin

         d_DCenter = median( (cd_DCenter(i_Pos,*,*))(vi_Mask) )
         d_Disp    = median( vd_Disp(1:*) )

         vd_LineDisp    = [vd_LineDisp, d_Disp]
         vd_LineDCenter = [vd_LineDCenter, d_DCenter]
         vd_W           = [vd_W, vd_Lines_um(j)]

         if ( keyword_set (DEBUG) ) then begin
            h_H = histogram (cd_DCenter(i_Pos,*,*), min=-0.002, max=0.002, binsize=0.00001)
            plot, (findgen(400)-200.)*0.00001, h_H, /XST, $
               title='Accuracy at ' + strg(vd_Lines_um(j)) + 'microns, Median: '+strg(d_DCenter)+' '+strg(n_Valid)+' lines', $
               xtitle='Deviation from should be position [microns]', $
               ytitle='Number of lines'
            end

         info, 'INFO ('+strg(functionName)+'): Median of Dispersion of line at ' + strg(vd_Lines_um(j)) + $
               'microns = '+strg(d_Disp) + 'microns'
         info, 'INFO ('+strg(functionName)+'): Median of Error in center of line at ' + strg(vd_Lines_um(j)) + $
               'microns = '+strg(d_DCenter) + 'microns.'
      endif else $
         warning, 'WARNING ('+functionName+'): Too few valid lines found at '+strg(vd_Lines_um(j))+'microns.'

   end

   if ( n_elements ( vd_W ) gt n_FitOrder+2 ) then begin

      vd_LineDisp    = vd_LineDisp(1:*)
      vd_LineDCenter = vd_LineDCenter(1:*)
      vd_W           = vd_W(1:*)

      ; the dispersion in FWHM is asked for
      vd_LineDisp = vd_LineDisp*2.35

      if ( keyword_set (DEBUG) ) then begin

         !p.multi=[0,1,2]
          plot, vd_W, vd_LineDisp, xrange=[d_LL,d_UL], /XST, PSYM=2, SYMSIZE=2, $
                                  title='Wavelength dependence of dispersion', $
                                  xtitle='Wavelength [microns]', $
                                  ytitle='FWHM of arc lines [microns]'
      end

      ; fit the dispersion as a function of wavelength
      vd_Coeff = my_SVDFIT( vd_W, vd_LineDisp, n_FitOrder+1 )
      if ( bool_is_vector ( vd_Coeff ) ) then begin
         vd_Disp = poly ( vd_L, vd_Coeff ) 
         if ( keyword_set (DEBUG) ) then oplot, vd_L, vd_Disp
      endif else $
         vd_Disp = vd_L*0.d

      if ( keyword_set (DEBUG) ) then begin
         plot, vd_W, vd_LineDCenter, xrange=[d_LL,d_UL], /XST, PSYM=2, SYMSIZE=2, $
                                     title='Deviation from should be position', $
                                     xtitle='Wavelength [microns]', $
                                     ytitle='Deviation [microns]'
         !p.multi=[0,1,0]
      end

      return, { cd_Center_um  : cd_Center, $  ; the measured center positions at the should be center
                cd_DCenter_um : cd_DCenter, $ ; the difference bewtween the measured center and the should be position
                cd_Disp_um       : cd_Disp, $       ; the dispersion at the measured position
                vd_Disp_um       : vd_Disp, $       ; the FWHM as function of wavelength
                vd_W_um          : vd_L, $          ; the corresponding wavelength 
                vd_PtsDisp_um    : vd_W, $          ; fit points Dispersions
                vd_PtsW_um       : vd_LineDisp, $   ; fit points Wavelengths
                vd_PtsDCenter_um : vd_LineDCenter } ; fit points error in center
   endif else $
      return, error ('FAILURE (findspecres.pro): Found too few lines to fit.') 

end
