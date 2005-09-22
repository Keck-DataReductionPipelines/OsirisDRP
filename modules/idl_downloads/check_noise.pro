;-----------------------------------------------------------------------
; NAME:  check_noise
;
; PURPOSE: check for noisy frames
;
; INPUT :  Frames     : pointer array of frames to clip
;          nFrames    : number of frames
;          nMinFrames : minimum number of frames that shall survive
;                       the clipping
;          d_SDV      : 
;          d_Noise    :
;          d_Low      :
;          [vb_Status=vb_Status] : boolean vector of length nFrames. 1 stands for valid ('of
;                                  use') 0 stands for invalid ('not to use')
;
; OUTPUT : boolean vector of length nFrames. 1 stands for valid ('of
;          use') 0 stands for invalid ('not to use')
;
; NOTES : the kernel algorithm is originally from Inseok Song
;
; STATUS : untested
;
; HISTORY : 6.8.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

function check_noise, p_Frames, nFrames, nMinFrames, d_SDV, d_Noise, d_Low, STATUS = vb_Status, DEBUG = b_Debug

     ; create vector indicating which frame is valid if not parsed
     if ( NOT keyword_set ( STATUS ) ) then vb_Status = intarr(nFrames)+1

     if ( NOT keyword_set ( DEBUG ) ) then b_Debug = 0 else b_Debug = b_Debug

     if ( n_elements(vb_Status) ne nFrames ) then $
        return, error ('FATAL ERROR (check_median.pro): vb_Status has not a length of nFrames')

     repeat begin

        vi_StatusMask = where(vb_Status, n_Valid1)

        md_AveragedFrame = 0.
        for i=0, nFrames-1 do if ( vb_Status(i) eq 1 ) then md_AveragedFrame = temporary(md_AveragedFrame) + *p_Frames(i)
        md_AveragedFrame = temporary(md_AveragedFrame) / double(total(vb_Status))

        d_MedianOfAverage = median (md_AveragedFrame)

        if ( abs (d_MedianOfAverage) lt 1d-6 ) then begin
           warning, ['WARNING (check_noise.pro): Median of averaged frame is to low for division.',$
                     '                           Continuing without further noise checking and without guarantee']
           return, vb_Status
        end

        md_NormAverage = abs ( (md_AveragedFrame - d_MedianOfAverage) / d_MedianOfAverage)
        vb_MaskValid   = where( md_NormAverage < (d_Noise/2.0), n_ValidPixels )

        if (n_ValidPixels le 0) then begin
           warning, ['FAILURE (check_noise.pro): There are no valid pixels!', $
                     '                           Continuing without further noise checking and without guarantee']
           return, vb_Status
        end

        vd_SDV      = FLTARR(n_Valid1)

        for i=0, n_Valid1-1 do $
           vd_SDV[i] = stddev((*p_Frames(vi_StatusMask(i)))(vb_MaskValid))

        d_MeanOfSDV  = mean( vd_SDV )
        if ( abs(d_MeanOfSDV) le 1d-6 ) then begin
           warning, ['FAILURE (check_noise.pro): Mean of stddevs is to low for division', $
                     '                           Continuing without further noise checking and without guarantee']
           return, vb_Status
        end

        vd_Deviates = ( vd_SDV - d_MeanOfSDV ) / d_MeanOfSDV
        vi_SortDevs = sort ( vd_Deviates )

        IF ( vd_Deviates[vi_SortDevs[n_Valid1-1]] gt (d_SDV/2.0)) THEN BEGIN
               if ( keyword_set ( b_Debug ) ) then $
                  debug_info, 'DEBUG INFO (check_noise.pro): One noisy frame discarded...'
            vb_Status[ vi_StatusMask[vi_SortDevs[n_Valid1-1]] ] = 0
        ENDIF 

        IF (vd_Deviates[vi_SortDevs[0]] lt (-d_SDV/2.0)) THEN BEGIN
           IF (vd_SDV[vi_SortDevs[0]] lt ( d_Low * d_MeanOfSDV ) ) THEN BEGIN
               if ( keyword_set ( b_Debug ) ) then $
                  debug_info, 'DEBUG INFO (check_noise.pro): One quiet frame discarded...'
               vb_Status[ vi_StatusMask[vi_SortDevs[0]] ] = 0
           ENDIF $
           ELSE BEGIN
               IF ( (vd_SDV[vi_SortDevs[1]] ge d_Low * d_MeanOfSDV) AND $
                    (vd_Deviates[vi_SortDevs[1]] lt (-d_SDV/2.0)) ) THEN BEGIN
                  if ( keyword_set ( b_Debug ) ) then $
                     debug_info, 'DEBUG INFO (check_noise.pro): One noisy frame discarded...'
                  vb_Status[ vi_StatusMask[vi_SortDevs[0]] ] = 0
               ENDIF 
           ENDELSE
        ENDIF

        n_Valid2 = total(vb_Status)

     ; repeat until no frame is clipped anymore or the number of frames is
     ; lower then nMinFrames
     endrep until ( ( n_Valid1 eq n_Valid2 ) or n_Valid2 le nMinFrames )

     return, vb_Status

END
