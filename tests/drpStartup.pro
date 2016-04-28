drs_idl_root = getenv('OSIRIS_IDL_BASE')

if (drs_idl_root ne '') then $
    backbone_dir=drs_idl_root+'/backbone/' & $
    module_dir=drs_idl_root+'/modules/' & $
    idl_downloads_dir=module_dir+'idl_downloads/' & $
    test_dir=drs_idl_root+'/tests/'

!PATH=test_dir+':'+backbone_dir+':'+module_dir+':'+idl_downloads_dir+':'+!PATH
!PATH=expand_path(!PATH)

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
.compile drpTest.pro
