; get KROOT envvar
kroot_dir=getenv('KROOT')
if (kroot_dir eq '') then $
  kroot_dir='/kroot'

drs_idl_root = getenv('OSIRIS_IDL_BASE')

if (drs_idl_root EQ '') and (kroot_dir ne '') then $
    drs_idl_root=kroot_dir+'/rel/default/idl/odrs/'

IF (drs_idl_root NE '') THEN $
    backbone_dir=drs_idl_root+'/backbone/' & $
    module_dir=drs_idl_root+'/modules/' & $
    idl_downloads_dir=module_dir+'idl_downloads/' & $
    test_dir=drs_idl_root+'/tests/'

IF (drs_idl_root EQ '') THEN print, "OSIRIS_IDL_BASE=", drs_idl_root
IF (drs_idl_root EQ '') THEN print, "The OSIRIS DRP cannot locate the correct source code directory."
IF (drs_idl_root EQ '') THEN print, "Did you forget to set the environment variable OSIRIS_IDL_BASE?"
IF (drs_idl_root EQ '') THEN print, "You should run scripts/osirisSetup.sh to set environment variables"
IF (drs_idl_root EQ '') THEN EXIT, /NO_CONFIRM

!PATH=test_dir+':'+backbone_dir+':'+module_dir+':'+'+'+idl_downloads_dir+':'+'<IDL_DEFAULT>'
!PATH=expand_path(!PATH)

readcol_path = FILE_WHICH('readcol.pro')
IF (readcol_path EQ '') THEN print, "The OSIRIS DRP cannot locate readcol.pro, part of the IDL astrolib"
IF (readcol_path EQ '') THEN EXIT, /NO_CONFIRM

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
