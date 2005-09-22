
;-----------------------------------------------------------------------
; NAME: average_frames
;
; PURPOSE: average frames
;
; INPUT : Frames                : pointer array with the data frames
;         IntFrames             : pointer array with the noise frames
;         IntAuxFrames          : pointer array with the quality frames
;         nFrames               : number of valid frames 
;         [vb_Status=vb_Status] : boolean vector of length nFrames
;                                 indicating if a frame shall be used
;                                 (1) or not (0)
;         [dc=dc]               : if set an averaged pixel is only
;                                 valid (0th qbit=1) if all individual
;                                 pixels have been valid (acc. to valid.pro)
;         [/DEBUG]              : initializes the debugging mode
;         [/VALIDS]             : if set, the inside bit is ignored
;                                 for calculations. The result has the
;                                 correct inside bits set.
;         [/MED]                : Median instead of averaging
;
;
; OUTPUT : returns a structure with four elements:
;         { NFrame      : ..., $       The number of individual pixels that have
;                                      been used for averaging
;           Frame       : ..., $       The averaged frame
;           IntFrame    : ..., $       The new noise frame
;           IntAuxFrame : ...    }     The new quality frame
;
; ON ERROR : returns ERR_UNKNOWN from APP_CONSTANTS
;
; ALGORITHM : The averaged frame is calculated weighted acc. OSDN 49.15
;             Individual pixels are valid according to valid.pro
;
; NOTES : - A pixel is valid as defined in valid.pro
;         - It does not matter whether a cube is EURO3D compliant or not.
;         - Meaning of the bits
;
;              0th : status good ( of use ) or bad (not of use)
;              1st : interpolated (0:no,1:yes)
;              2nd : good interpolated (0:no,1:yes)
;              3rd : inside (0:no, 1:yes)
;
;           The actions take place in the following order:
;
;           Individual pixels are regarded as valid according to
;           valid.pro. In case of having the dc keyword set an
;           averaged pixel is regarded as valid (0th qbit set to 1) if
;           all individual pixels have been valid (acc. to valid.pro)
;
;           the NFrame value is the number of valid pixels that have
;           been used for averaging.
;
;           0th bit : If keyword DC is (not) set an averaged pixel
;                     gets 0th bit set to 1 if (at least one) all 
;                     individual pixels are valid. 
;           1st bit : is set to 1 if at least one valid (acc. to
;                     valid.pro) pixel has been used for
;                     averaging which has been interpolated
;           2nd bit : is set to 1 if the number of valid (acc. to
;                     valid.pro) bad interpolated pixels is less than
;                     25% of the numbers of valid and valid
;                     good interpolated pixels. 
;           3rd bit : is set to 1 where at least one pixel
;                     (independent of other criteria) was inside
;
;           Pixel with 0th bit set to 0 get:
;              Frame           : 0.
;              IntFrame        : 1.
;              NFrame          : 0
;              1st and 2nd bit : 0
;
;            Therefore pixels that have a 0th qbit after averaging
;            have no 1st and 2nd qbit set.
;
;         - Although not tested this routine works for input variables
;           of any dimensions
;
;         - if MED is set :
;            - uses cmapply
;            - the data frames are rearranged and invalid values are
;              replaced by NANs. When medianing NANs are ignored. If a
;              medianed value is NAN the frame and intframe value of the pixel gets 0 and the
;              pixel is set to invalid (0th bit is set to 0).
;            - medianing works for up to 2 dimensions (so images)
;
; STATUS : not tested
;
; HISTORY : 7.8.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------

function average_frames, p_Frames, p_IntFrames, p_IntAuxFrames, nFrames, STATUS=vb_Status, $
                         dc = dc, DEBUG = DEBUG, VALIDS = VALIDS, MED = MED

   COMMON APP_CONSTANTS

   if ( NOT keyword_set(STATUS) ) then vb_Status = intarr(nFrames)+1 $
   else begin 
      if ( n_elements(vb_Status) ne nFrames ) then $
         return, error ('ERROR IN CALL (average_frames.pro): vb_Status has not a length of nFrames.')
      if ( total(vb_Status) eq 0 ) then $
         return, error ('ERROR IN CALL (average_frames.pro): vb_Status is completely 0. Nothing to average.')
   end

   if ( keyword_set ( MED ) ) then begin
      if ( keyword_set ( DEBUG ) ) then $
         debug_info, 'DEBUG INFO (average_frames.pro): Medianing.'

      if ( (size(*p_Frames(0)))(0) gt 2 ) then $
         return, error ('ERROR IN CALL (average_frames.pro): Medianing works only up to images.')
   endif else $
      if ( keyword_set ( DEBUG ) ) then $
         debug_info, 'DEBUG INFO (average_frames.pro): Averaging.'

   if ( bool_pointer_integrity( p_Frames, p_IntFrames, p_IntAuxFrames, nFrames, 'average_frames.pro' ) ne OK ) then $
      return, error('ERROR IN CALL (average_frames.pro): Integrity check failed.')

   ; integrity ok

   ; ----- calculate averages ---------------------------------------------------------------

   n_Dims = size(*p_Frames(0))

   ; create memory for the results
   mi_Frame       = make_array(/INT, SIZE=n_Dims)
   md_Frame       = make_array(/FLOAT, SIZE=n_Dims)
   md_IntFrame    = make_array(/FLOAT, SIZE=n_Dims)
   mb_IntAuxFrame = make_array(/BYTE, SIZE=n_Dims)

   ; mask where at least one valid pixel has been found
   mb_Mask_Valid  = make_array(/BYTE, SIZE=n_Dims)

   ; counters for the quality status 
   ; # of valid pixel
   mby_Mask_Valid        = make_array(/BYTE, SIZE=n_Dims)
   ; # of valid pixel that have been interpolated
   mby_Mask_Valid_Int    = make_array(/BYTE, SIZE=n_Dims)
   ; # of valid pixel that have been badly interpolated
   mby_Mask_Valid_BadInt = make_array(/BYTE, SIZE=n_Dims)
   ; # of pixel that are inside
   mby_Mask_Inside       = make_array(/BYTE, SIZE=n_Dims)

   delvarx, cd_Frame_Internal

   for i=0, nFrames-1 do begin

      if ( vb_Status(i) eq 1 ) then begin

         if ( keyword_set (MED) ) then $
            if ( n_elements(cd_Frame_Internal) eq 0 ) then $
               cd_Frame_Internal = *p_Frames[i] $
            else $
               cd_Frame_Internal = [[[cd_Frame_Internal]],[[*p_Frames[i]]]]

         mb_Mask = byte(valid ( *p_Frames[i], *p_IntFrames[i], *p_IntAuxFrames[i], VALIDS=keyword_set(VALIDS) ))
         vb_Mask = where(mb_Mask, n_Valid)

         if ( n_Valid gt 0 ) then begin
            md_Tmp               = (*p_IntFrames(i))(vb_Mask)^2
            md_Frame(vb_Mask)    = temporary(md_Frame(vb_Mask)) + (*p_Frames(i))(vb_Mask) / md_Tmp
            md_IntFrame(vb_Mask) = temporary(md_IntFrame(vb_Mask)) + 1. / md_Tmp
         endif else warning, 'WARNING (average_frames.pro): Set ' + strg(i) + $
                       ' all pixel invalid acc. to valid(' + (keyword_set(VALIDS)?'/VALIDS':'') + ').'

         if ( keyword_set ( DEBUG ) ) then $
            debug_info, 'DEBUG INFO (average_frames.pro): Number of valid pixels in set ' + $
                        strg(i)+': '+strg(n_Valid)

         ; counters for the quality status

         mb_B1 = byte(extbit( *p_IntAuxFrames[i], 1 ))
         mb_B2 = byte(extbit( *p_IntAuxFrames[i], 2 ))
         mb_B3 = byte(extbit( *p_IntAuxFrames[i], 3 ))

         mby_Mask_Valid        = temporary(mby_Mask_Valid) + mb_Mask
         mby_Mask_Valid_Int    = temporary(mby_Mask_Valid_Int) + ( mb_Mask and mb_B1 )
         mby_Mask_Valid_BadInt = temporary(mby_Mask_Valid_BadInt) + ( mb_Mask and mb_B1 and (mb_B2 ne 1b) )
         mby_Mask_Inside       = temporary(mby_Mask_Inside) + mb_B3

      endif

      if ( keyword_set ( DEBUG ) ) then $
         debug_info, 'DEBUG INFO (average_frames.pro): '+strg(fix(100.*(i+1)/nFrames))+$
                     '% of the calculations done.'

   end

   if ( n_elements(cd_Frame_Internal) ne 0 ) then cd_Frame_Internal = reform ( cd_Frame_Internal )

   vi_MaskValid = where (mby_Mask_Valid, n_Valid )
   if ( n_Valid gt 0 ) then begin
      if ( keyword_set ( MED ) ) then $
         md_Frame (vi_MaskValid) = (cmapply ( 'USER:MEDIAN', cd_Frame_Internal, (size(cd_Frame_Internal))(0) ))(vi_MaskValid) $
      else $
         md_Frame(vi_MaskValid) = temporary(md_Frame(vi_MaskValid)) / md_IntFrame(vi_MaskValid) 
   endif else return, error( 'FAILURE (average_frames.pro): Averaging failed. No valid pixel found.' )

   md_IntFrame(vi_MaskValid) = 1. / sqrt ( temporary(md_IntFrame(vi_MaskValid)) )


   ; ----- done with the calculations --------------------------------------------------------
   ; ----- now set the bits ------------------------------------------------------------------

   ; set the pixel counter frame
   if ( keyword_set ( dc ) ) then $
      mi_Frame = mi_Frame * 0 + total(vb_Status) $
   else $
      mi_Frame = mby_Mask_Valid

   if ( keyword_set ( DEBUG ) ) then $
      debug_info, 'DEBUG INFO (average_frames.pro): Starting to set the bits'

   ;----- now define new quality bits -----

   ; mask where pixels are valid and not valid
   if ( keyword_set ( dc ) ) then $
      mb_Mask_Valid = mby_Mask_Valid eq total(vb_Status) $
   else $
      mb_Mask_Valid = mby_Mask_Valid gt 0
   mb_Mask_NotValid = byte(bool_invert(mb_Mask_Valid))


   ; set the 0th bit to 1 where valid
   vi_Mask = where ( mb_Mask_Valid, n_Mask )
   if ( n_Mask gt 0 ) then $
      mb_IntAuxFrame(vi_Mask) = setbit(mb_IntAuxFrame(vi_Mask),0,1) $
   else $
      warning, 'WARNING (average_frames.pro): No valid pixels found after averaging.'


   ; set the 1st bit to 1 where valid and interpolated pixels occur
   vi_Mask = where ( ( mby_Mask_Valid_Int gt 0 ) and mb_Mask_Valid, n_Mask )
   if ( n_Mask gt 0 ) then $
      mb_IntAuxFrame(vi_Mask) = setbit(mb_IntAuxFrame(vi_Mask),1,1)


   ; set the 2nd bit to 1 where valid and where less than 25% of all valid and
   ; valid good interpolated pixels are badly interpolated
   vi_Mask = where ( (4*mby_Mask_Valid_BadInt lt mby_Mask_Valid) and $
                     ( mby_Mask_Valid_Int gt 0 ) and mb_Mask_Valid, n_Mask )
   if ( n_Mask gt 0 ) then $
      mb_IntAuxFrame(vi_Mask) = setbit(mb_IntAuxFrame(vi_Mask),2,1)


   ; set the 3rd bit where at least one inside pixel is detected
   vi_Mask = where ( mby_Mask_Inside, n_Mask )
   if ( n_Mask gt 0 ) then $
      mb_IntAuxFrame(vi_Mask) = setbit(mb_IntAuxFrame(vi_Mask),3,1)


   ; set frame values to 0, intframe values to 1 and nframe to 0 where not valid
   vi_Mask = where ( mb_Mask_NotValid, n_Mask )
   if ( n_Mask gt 0 ) then begin
      md_Frame(vi_Mask)    = 0.
      md_IntFrame(vi_Mask) = 1.
      mi_Frame(vi_Mask)    = 0
   end


   ; last check where 2nd bit is 1 and 1st bit is 0
   mb_Mask = where( (extbit(mb_IntAuxFrame,1) eq 0) and extbit(mb_IntAuxFrame,2), n_Mask )
   if ( n_Mask gt 0 ) then $
      warning, 'FATAL WARNING (average_frame.pro): At least one pixel has 1st bit=0 and 2nd bit=1' 

   if ( keyword_set ( MED ) ) then begin
      vi_Mask = where(finite(md_Frame,/NAN) eq 1, n)
      if ( n gt 0 ) then begin
         md_Frame(vi_Mask)       = 0.
         md_IntFrame(vi_Mask)    = 0.      
         mb_IntAuxFrame(vi_Mask) = setbit(mb_IntAuxFrame(vi_Mask),0,0)     
      end
   end

   if ( keyword_set ( DEBUG ) ) then $
      debug_info, 'DEBUG INFO (average_frames.pro): Returning succesfully.'

   return, { NFrame      : mi_Frame       , $
             Frame       : md_Frame       , $
             IntFrame    : md_IntFrame    , $
             IntAuxFrame : mb_IntAuxFrame  }

end
