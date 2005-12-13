;-----------------------------------------------------------------------
; NAME:  define_module
;
; PURPOSE : define modules
;
; INPUT :  /NOCHECK : the correctness of the module definition is not checked
;
; STATUS : untested
;
; HISTORY : 27.2.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;
;-----------------------------------------------------------------------
function define_module, NOCHECK = NOCHECK

   COMMON APP_CONSTANTS

   functionName = 'check_module.pro'

   Branches  = ['CRP_SPEC', 'CRP_IMAG', 'TEST_IMAG', 'TEST_SPEC', $
                'ARP_SPEC', 'ARP_IMAG', 'ORP_IMAG', 'ORP_SPEC', 'SRP_SPEC', 'SRP_IMAG'] ; occuring branches
   NMaxInput = 99                     ; maximum number of input sets
   Number    = ['Odd', 'Even', 'All'] ; do not change

   stModule = { $
                Module001 : { Name     : 'badpixnois_000', $          ; the name of the module (without .pro)
                              Branches : ['CRP_SPEC', 'CRP_IMAG'], $  ; the allowed branches
                              IInput   : 1, $                         ; Should the dataset be checked for images?
                              CInput   : 0, $                         ; Should the dataset be checked for cubes?
                                                                      ; IInput and CInput must not be 1 the
                                                                      ; same time
                              NInput   : [5,NMaxInput], $             ; the min and max number of input sets
                              Number   : 'All', $                     ; the number of input dataset must be 
                                                                      ; odd (Odd), even (Even) or it doesnt
                                                                      ; matter (ALL)
                              SaveExt  : '_bpixn', $                  ; the file extension if a result is saved
                              Save     : '______' }, $                ; the file extension if intermediate results 
                                                                      ; are to be saved requested by the SAVE tag

                Module002 : { Name     : 'calibrwave_000', $
                              Branches : ['ARP_SPEC', 'SRP_SPEC', 'ORP_SPEC'], $
                              IInput   : 0, $
                              CInput   : 1, $
                              NInput   : [1,NMaxInput] , $
                              Number   : 'All', $
                              SaveExt  : '______', $
                              Save     : '__wcal'  }, $

                Module003 : { Name     : 'cleannoise_000', $
                              Branches : ['CRP_SPEC', 'CRP_IMAG', 'TEST_IMAG', 'TEST_SPEC', $
                                          'ARP_SPEC', 'ARP_IMAG', 'ORP_IMAG', 'ORP_SPEC', $
                                          'SRP_SPEC', 'SRP_IMAG'], $
                              IInput   : 0, $
                              CInput   : 0, $
                              NInput   : [1,NMaxInput] , $
                              Number   : 'All', $
                              SaveExt  : '______', $
                              Save     : '______'  }, $

                Module004 : { Name     : 'computspec_000', $
                              Branches : ['SRP_SPEC'], $
                              IInput   : 0, $
                              CInput   : 1, $
                              NInput   : [1,NMaxInput] , $
                              Number   : 'All', $
                              SaveExt  : '_sspec', $
                              Save     : '______'  }, $

                Module005 : { Name     : 'corrdisper_000', $
                              Branches : ['ARP_SPEC', 'ORP_SPEC'], $
                              IInput   : 0, $
                              CInput   : 1, $
                              NInput   : [1,NMaxInput] , $
                              Number   : 'All', $
                              SaveExt  : '______', $
                              Save     : 'cordis'  }, $

                Module006 : { Name     : 'detspecres_000', $
                              Branches : ['CRP_SPEC', 'CRP_IMAG', 'TEST_IMAG', 'TEST_SPEC', $
                                          'ARP_SPEC', 'ARP_IMAG', 'ORP_IMAG', 'ORP_SPEC', $
                                          'SRP_SPEC', 'SRP_IMAG'], $
                              IInput   : 0, $
                              CInput   : 1, $
                              NInput   : [1,1] , $
                              Number   : 'All', $
                              SaveExt  : 'detres', $
                              Save     : '______'   }, $

                Module007 : { Name     : 'divblackbo_000', $
                              Branches : ['CRP_SPEC', 'TEST_SPEC', 'ARP_SPEC', 'ORP_SPEC', 'SRP_SPEC' ], $
                              IInput   : 0, $
                              CInput   : 1, $
                              NInput   : [1,NMaxInput] , $
                              Number   : 'All', $
                              SaveExt  : '______', $
                              Save     : '____bb'   }, $

                Module008 : { Name     : 'divideflat_000', $
                              Branches : ['CRP_SPEC', 'CRP_IMAG', 'TEST_IMAG', 'TEST_SPEC', $
                                          'ARP_SPEC', 'ARP_IMAG', 'ORP_IMAG', 'ORP_SPEC', $
                                          'SRP_SPEC', 'SRP_IMAG'], $
                              IInput   : 0, $
                              CInput   : 0, $
                              NInput   : [1,NMaxInput] , $
                              Number   : 'All', $
                              SaveExt  : '______', $
                              Save     : '__fdiv'   }, $

                Module009 : { Name     : 'divstarspe_000', $
                              Branches : ['CRP_SPEC', 'TEST_SPEC', 'ARP_SPEC', 'ORP_SPEC', 'SRP_SPEC'], $
                              IInput   : 0, $
                              CInput   : 1, $
                              NInput   : [1,NMaxInput] , $
                              Number   : 'All', $
                              SaveExt  : '______', $
                              Save     : '_dspec'   }, $

                Module010 : { Name     : 'fitdispers_000', $
                              Branches : ['SRP_SPEC'], $
                              IInput   : 0, $
                              CInput   : 1, $
                              NInput   : [1,NMaxInput] , $
                              Number   : 'All', $
                              SaveExt  : '__dfit', $
                              Save     : '______'   }, $

                Module011 : { Name     : 'interponed_000', $
                              Branches : ['CRP_SPEC', 'CRP_IMAG', 'TEST_IMAG', 'TEST_SPEC', $
                                          'ARP_SPEC', 'ARP_IMAG', 'ORP_IMAG', 'ORP_SPEC', $
                                          'SRP_SPEC', 'SRP_IMAG'], $
                              IInput   : 0, $
                              CInput   : 0, $
                              NInput   : [1,NMaxInput] , $
                              Number   : 'All', $
                              SaveExt  : '______', $
                              Save     : 'interp' }, $

                Module012 : { Name     : 'makedarkfr_000', $
                              Branches : ['CRP_SPEC', 'CRP_IMAG'], $
                              IInput   : 1, $
                              CInput   : 0, $
                              NInput   : [1,NMaxInput] , $
                              Number   : 'All', $
                              SaveExt  : '__dark', $
                              Save     : '______'   }, $

                Module013 : { Name     : 'makeflatfi_000', $
                              Branches : ['CRP_SPEC', 'CRP_IMAG'], $
                              IInput   : 1, $
                              CInput   : 0, $
                              NInput   : [2,NMaxInput] , $
                              Number   : 'Even', $
                              SaveExt  : '_iflat', $
                              Save     : '______'   }, $

                Module014 : { Name     : 'mkwavcalfr_000', $
                              Branches : ['CRP_SPEC', 'CRP_IMAG', 'TEST_IMAG', 'TEST_SPEC', $
                                          'ARP_SPEC', 'ARP_IMAG', 'ORP_IMAG', 'ORP_SPEC', $
                                          'SRP_SPEC', 'SRP_IMAG'], $
                              IInput   : 0, $
                              CInput   : 1, $
                              NInput   : [1,NMaxInput] , $
                              Number   : 'All', $
                              SaveExt  : '__wmap', $
                              Save     : 'cfwmap'   }, $

                Module015 : { Name     : 'mosaicdith_000', $
                              Branches : ['TEST_IMAG', 'TEST_SPEC', $
                                          'ARP_SPEC', 'ARP_IMAG', 'ORP_IMAG', 'ORP_SPEC', $
                                          'SRP_SPEC', 'SRP_IMAG'], $
                              IInput   : 0, $
                              CInput   : 0, $
                              NInput   : [1,30] , $
                              Number   : 'All', $
                              SaveExt  : 'mosaic', $
                              Save     : '______'   }, $
 
                Module016 : { Name     : 'mosaicdpos_000', $
                              Branches : ['TEST_IMAG', 'TEST_SPEC', $
                                          'ARP_SPEC', 'ARP_IMAG', 'ORP_IMAG', 'ORP_SPEC', $
                                          'SRP_SPEC', 'SRP_IMAG'], $
                              IInput   : 0, $
                              CInput   : 0, $
                              NInput   : [1,30] , $
                              Number   : 'All', $
                              SaveExt  : 'mosoff', $
                              Save     : 'mosimg'   }, $
 
                Module017 : { Name     : 'nrmflxdens_000', $
                              Branches : ['CRP_SPEC', 'TEST_SPEC', 'ARP_SPEC', 'ORP_SPEC', 'SRP_SPEC' ], $
                              IInput   : 0, $
                              CInput   : 1, $
                              NInput   : [1,NMaxInput] , $
                              Number   : 'All', $
                              SaveExt  : '__norm', $
                              Save     : '______'   }, $
 
                Module018 : { Name     : 'nrmflxmagn_000', $
                              Branches : ['CRP_SPEC', 'TEST_SPEC', 'ARP_SPEC', 'ORP_SPEC', 'SRP_SPEC' ], $
                              IInput   : 0, $
                              CInput   : 1, $
                              NInput   : [1,NMaxInput] , $
                              Number   : 'All', $
                              SaveExt  : '_mnorm', $
                              Save     : '______'   }, $
 
                Module019 : { Name     : 'savedatset_000', $
                              Branches : ['CRP_SPEC', 'CRP_IMAG', 'TEST_IMAG', 'TEST_SPEC', $
                                          'ARP_SPEC', 'ARP_IMAG', 'ORP_IMAG', 'ORP_SPEC', $
                                          'SRP_SPEC', 'SRP_IMAG' ], $
                              IInput   : 0, $
                              CInput   : 0, $
                              NInput   : [1,NMaxInput] , $
                              Number   : 'All', $
                              SaveExt  : 'datset', $
                              Save     : '______'   }, $

                Module020 : { Name     : 'saveflatfi_000', $
                              Branches : ['CRP_SPEC' ], $
                              IInput   : 0, $
                              CInput   : 1, $
                              NInput   : [1,NMaxInput] , $
                              Number   : 'All', $
                              SaveExt  : '_sflat', $
                              Save     : '______'   }, $
 
                Module021 : { Name     : 'sinfoni2os_000', $
                              Branches : ['CRP_SPEC', 'CRP_IMAG', 'TEST_IMAG', 'TEST_SPEC', $
                                          'ARP_SPEC', 'ARP_IMAG', 'ORP_IMAG', 'ORP_SPEC', $
                                          'SRP_SPEC', 'SRP_IMAG' ], $
                              IInput   : 0, $
                              CInput   : 0, $
                              NInput   : [1,NMaxInput] , $
                              Number   : 'All', $
                              SaveExt  : '______', $
                              Save     : '______'   }, $

                Module022 : { Name     : 'subbackgrd_000', $
                              Branches : [ 'TEST_SPEC', 'ARP_SPEC' ], $
                              IInput   : 0, $
                              CInput   : 1, $
                              NInput   : [1,NMaxInput] , $
                              Number   : 'All', $
                              SaveExt  : '______', $
                              Save     : '__bgdc'   }, $

                Module023 : { Name     : 'subtradark_000', $
                              Branches : ['CRP_SPEC', 'CRP_IMAG', 'TEST_IMAG', 'TEST_SPEC', $
                                          'ARP_SPEC', 'ARP_IMAG', 'ORP_IMAG', 'ORP_SPEC', $
                                          'SRP_SPEC', 'SRP_IMAG' ], $
                              IInput   : 1, $
                              CInput   : 0, $
                              NInput   : [1,NMaxInput] , $
                              Number   : 'All', $
                              SaveExt  : '______', $
                              Save     : '__dark'   }, $

                Module024 : { Name     : 'glitchremv_000', $
                              Branches : ['CRP_SPEC', 'CRP_IMAG', 'TEST_IMAG', 'TEST_SPEC', $
                                          'ARP_SPEC', 'ARP_IMAG', 'ORP_IMAG', 'ORP_SPEC', $
                                          'SRP_SPEC', 'SRP_IMAG' ], $
                              IInput   : 0, $
                              CInput   : 0, $
                              NInput   : [1,NMaxInput] , $
                              Number   : 'All', $
                              SaveExt  : 'glitch', $
                              Save     : '______'   }, $

                Module025 : { Name     : 'mkdatacube_000', $
                              Branches : ['CRP_SPEC', 'CRP_IMAG', 'TEST_IMAG', 'TEST_SPEC', $
                                          'ARP_SPEC', 'ARP_IMAG', 'ORP_IMAG', 'ORP_SPEC', $
                                          'SRP_SPEC', 'SRP_IMAG' ], $
                              IInput   : 1, $
                              CInput   : 0, $
                              NInput   : [1,NMaxInput] , $
                              Number   : 'All', $
                              SaveExt  : '__cube', $
                              Save     : '______'   }, $

                Module026 : { Name     : 'mkwavsmo_000', $
                              Branches : ['CRP_SPEC', 'TEST_SPEC', 'ARP_SPEC', 'ORP_SPEC', 'SRP_SPEC'], $
                              IInput   : 0, $
                              CInput   : 0, $
                              NInput   : [0,0] , $
                              Number   : 'All', $
                              SaveExt  : '_swmap', $
                              Save     : '______'   } $

   }

   if ( NOT keyword_set ( NOCHECK ) ) then begin

   ; check module definition

   for i=0, n_tags(stModule)-1 do begin

      ; check branch definitions
      for j=0, n_elements(stModule.(i).Branches)-1 do begin
         n = where ( Branches eq stModule.(i).Branches(j) )
         if ( n(0) lt 0 ) then $
            return, error ( 'INTERNAL ERROR ('+strtrim(string(functionName),2)+'): Check of branches failed in module definition '+string(i)+'.')
      end

      ; check input format
      if ( stModule.(i).IInput eq 1 and stModule.(i).CInput eq 1 ) then $
         return, error ( 'INTERNAL ERROR ('+strtrim(functionName)+'): IInput and CInput must not be 1 together in module definition '+string(i)+'.')

      ; check size of input number vector
      if ( n_elements(stModule.(i).NInput ne 2 ) ) then $
         return, error ( 'INTERNAL ERROR ('+strtrim(string(functionName),2)+'): Check of input numbers failed in module definition.'+string(i)+'. Not a 2-element vector.')

      ; check definition of input numbers 
      if ( stModule.(i).NInput(0) lt 0 or stModule.(i).NInput(1) gt NMaxInput or $
           stModule.(i).NInput(0) gt stModule.(i).NInput(1) ) then $
            return, error ( 'INTERNAL ERROR ('+strtrim(string(functionName),2)+'): Check of input numbers failed in module definition.'+string(i)+'.')
         
      ; check number
      n = where ( Number eq stModule.(i).Number )
      if ( n(0) lt 0 ) then $
         return, error ( 'INTERNAL ERROR ('+strtrim(string(functionName),2)+'): Check of number failed in module definition '+string(i)+'.')

      ; check filename extension
      if ( strlen(stModule.(i).SaveExt) ne 6 ) then $
         return, error ( 'INTERNAL ERROR ('+strtrim(string(functionName),2)+'): Check of length of filename extension (SaveExt) failed in module definition '+string(i)+'. Not a 6-element string.')

      if ( strlen(stModule.(i).Save) ne 6 ) then $
         return, error ( 'INTERNAL ERROR ('+strtrim(string(functionName),2)+'): Check of length of filename extension (Save) failed in module definition '+string(i)+'. Not a 6-element string.')

   end

   end

   return, stModule

end
