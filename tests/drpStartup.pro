!quiet=1
drs_idl_root=getenv('OSIRIS_IDL_BASE')
!PATH=drs_idl_root+"/backbone/"
@drpStartup
!PATH=expand_path('+'+drs_idl_root+'/tests/')+":"+!PATH
.compile drpTest.pro
!quiet=0

PRINT, !PATH