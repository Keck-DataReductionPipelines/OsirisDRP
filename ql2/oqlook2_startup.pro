; +
; NAME:  qlook2_startup
;
; PURPOSE:  startup procedures for all versions of qlook2
;
; CALLING SEQUENCE:
;
; INPUTS:
;
; OPTIONAL INPUTS:
;
; OPTIONAL KEYWORD INPUTS:
;
; EXAMPLE:
;
; NOTES: called by run_ql2
;
; PROCEDURES USED:
;
; REVISION HISTORY: 07SEPT2001 - JLW
; - 

; setup number of bits per color and change the cursor to an arrow
device, true_color=24, decomposed=0
; set up number of colors
window, 0, xs=2, ys=2, colors=-1
wdelete, 0

; get KROOT envvar
kroot_dir=getenv('KROOT')
if ( kroot_dir eq '' ) then kroot_dir='/kroot'

; set kidl path
kidlpath = kroot_dir+'/rel/default/lib/'
!path=kidlpath+':'+!path

; compile kidl.pro to get access to show and modify                                         
find_kidl = file_test(kidlpath+'kidl.pro')
.r kidl.pro


; get qlook directory from environment variable
qlook_dir=getenv('QL_FILEDIR')
; if env var not set, use default
if qlook_dir eq '' then $
  qlook_dir=kroot_dir+'/kss/qlook2/'

; set up idl path
!path=qlook_dir+':'+qlook_dir+'../idllib'+':'+qlook_dir+'/idl_downloads'+':'+!path

; load color table
loadct, 1

; call ql
ql, /xwin, configs=qlook_dir+'/configs/osiris_online_cfg.pro'
