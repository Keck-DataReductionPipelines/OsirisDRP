;-----------------------------------------------------------------------
; NAME:  check_median
;
; PURPOSE: clip frames
;
; INPUT :  p_Frames   : pointer array of frames to clip
;          nFrames    : number of frames
;          nMinFrames : minimum number of frames that shall survive
;                       the clipping
;          d_Dev      : maximum deviation
;          [vb_Status=vb_Status] : boolean vector (!) of length nFrames. 1 stands for valid ('of
;                                  use') 0 stands for invalid ('not to use')
;
; OUTPUT : boolean vector of length nFrames. 1 stands for valid ('of
;          use') 0 stands for invalid ('not to use')
;
; ALGORITHM : 
;             - calculate median values of valid frames
;             - Loop 
;                - calculate mean of median values
;                - the frame with the median with maximum deviation
;                  from mean is checked against d_Dev (in percent).
;                - if the deviation is higher than d_Dev the frame is
;                  declared as not to use.
;             - until no frame is clipped or the number of frames that
;               are declared to use is le nMinFrames 
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

function check_median, p_Frames, nFrames, nMinFrames, d_Dev, STATUS = vb_Status, DEBUG = DEBUG

     ; create vector indicating which frame is valid if not parsed
     if ( NOT keyword_set ( STATUS ) ) then vb_Status = intarr(nFrames) + 1
 
     if ( n_elements(vb_Status) ne nFrames ) then begin
        warning, ['FATAL ERROR (check_median.pro): vb_Status has not a length of nFrames', $
                  '                                Continuing without further median checking and without guarantee']

        return, vb_Status
     end

     ; calculate median values of each frames
     vd_Median=fltarr(nFrames)
     for i=0, nFrames-1 do begin
        vd_Median[i] = median (*p_Frames[i])
        if ( keyword_set (DEBUG) ) then debug_info, 'DEBUG INFO (clip_frames.pro): Median in frame '+ strtrim(string(i),2) + $
                                                       ' : ' + strtrim(string(vd_Median(i)),2)
     end


     n_Loop = 0
     n_Status1 = total ( vb_Status ) 

     repeat begin

        if ( keyword_set (DEBUG) ) then $
           debug_info, 'DEBUG INFO (clip_median.pro): Loop '+ strtrim(string(n_Loop),2)

        vi_StatusMask  = where(vb_Status, n_Valid1)
        ; calculate mean of valid medians
        d_MeanOfMedian = MEAN( vd_Median( vi_StatusMask ) )

        ; check if division can be done
        if ( abs(d_MeanOfMedian) lt 1d-6 ) then begin
           warning, ['FAILURE (check_median.pro): Mean of stddevs is to low for division', $
                     '                            Continuing without further median checking and without guarantee']
           return, vb_Status
        end

        vd_NormMeanOfMedian = abs( ( d_MeanOfMedian - vd_Median( vi_StatusMask ) ) / d_MeanOfMedian)

        if ( keyword_set (DEBUG) ) then $
           debug_info, 'DEBUG INFO (check_median.pro): Normed mean of medians '+ strtrim(string(vd_NormMeanOfMedian),2)

        ; check 
        if ( max(vd_NormMeanOfMedian,i_Index) gt d_Dev ) then begin
           if ( keyword_set (DEBUG) ) then $
              debug_info, 'DEBUG INFO (check_median.pro): Clipping frame '+ strtrim(string(i_Index),2) + ' (' + $
                 strtrim(string(max(vd_NormMeanOfMedian,i_Index)),2) + '>'+strtrim(string(d_Dev),2) + ')'
           vb_Status(vi_StatusMask(i_Index)) = 0
        end

        n_Valid2 = total(vb_Status)

        n_Loop = n_Loop + 1

        ; repeat until no frame is clipped anymore or the number of frames is
        ; lower then nMinFrames
     endrep until ( (n_Valid1 eq n_Valid2) or n_Valid2 le nMinFrames )

     n_Status2 = total ( vb_Status ) 

     if ( keyword_set (DEBUG) ) then $
        debug_info, 'DEBUG INFO (check_median.pro): # of clipped frames '+ strtrim(string(fix(n_Status1-n_Status2)),2)

     return, vb_Status

END
