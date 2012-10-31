; define backbone code location

; get KROOT envvar
kroot_dir=getenv('KROOT')
if (kroot_dir eq '') then $
  kroot_dir='/kroot'


drs_idl_root = getenv('OSIRIS_IDL_BASE')
; begin and else statements are not supported in batch mode.
if (drs_idl_root eq '') then $
    drs_idl_root=kroot_dir+'/rel/default/idl/odrs/' & $
    backbone_dir=drs_idl_root+'backbone/' & $
    module_dir=drs_idl_root+'modules/' & $
    idl_downloads_dir=module_dir+'idl_downloads/'

if (drs_idl_root ne '') then $
    backbone_dir=drs_idl_root+'/backbone/' & $
    module_dir=drs_idl_root+'/modules/' & $
    idl_downloads_dir=module_dir+'idl_downloads/' 


; put backbone code in idl path
!path=backbone_dir+':'+module_dir+':'+idl_downloads_dir+':'+!path

; compile procedures
.compile skysclim.pro
.compile strn.pro
.compile buie_avgclip.pro
.compile strnumber.pro
.compile ICG_LIB.pro
.compile break_path.pro
.compile daycnv.pro
.compile detabify.pro
.compile fxhmodify.pro
.compile fxhread.pro
.compile gettok.pro
.compile valid_num.pro
.compile fxpar.pro
.compile check_fits.pro
.compile fxparpos.pro
.compile fxaddpar.pro
.compile get_date.pro
.compile is_ieee_big.pro
.compile mkhdr.pro
.compile mpfit.pro
.compile mpfitfun.pro
.compile mrd_hread.pro
.compile mrd_skip.pro
.compile sxaddpar.pro
.compile sxdelpar.pro
.compile sxpar.pro
.compile readfits.pro
.compile writefits.pro
.compile meanclipdrl.pro
.compile general_log_name.pro
.compile drpMain.pro
.compile drpBackbone__define.pro
.compile drpConfigParser__define.pro
.compile drpDRFParser__define.pro
.compile drpDRFPipeline__define.pro
.compile drpPipeline__define.pro
.compile drpRun.pro


; Check to see if we need to use an alternate DRF queue
alt_drf_queue = GETENV('OSIRIS_ALTERNATE_DRF_QUEUE_DIR')
;PRINT, ''
;PRINT, 'To change the DRF queue directory set the environment variable'
;PRINT, 'OSIRIS_ALTERNATE_DRF_QUEUE_DIR to the new queue directory and then'
;PRINT, 're-run the pipeline'
;PRINT, ''
; start backbone
IF alt_drf_queue eq '' THEN $
  drpRun $
ELSE $
  drpRun, QUEUE_DIR=alt_drf_queue
