function osiris_spec_cfg, error

; set up a catch to make sure there isn't a problem when
; trying to poll the server
catch, error_status

;This statement begins the error handler:
if error_status ne 0 then begin
   print, 'Error index: ', error_status
   print, 'Error message: ', !ERROR_STATE.MSG
endif

axes_labels2d=ptr_new(['X', 'Y', 'Z'], /allocate_heap)
axes_labels3d=ptr_new(['Wavelength', 'Y', 'X'], /allocate_heap)

error=0

if (error_status eq 0) then begin

struct={ cconfigs, $
         cfg_name:'OSIRIS SPEC', $ ; instrument configuration
         inst_fitskw:'CURRINST', $ ; instrument fits keyword
         itime_fitskw:'ITIME', $ ; integration time
         coadds_fitskw:'COADDS', $ ; # of coadds
         pa_fitskw:'ROTPOSN', $ ; rotator position
         object_fitskw:'OBJECT', $ ; object kw
         sampmode_fitskw:'SAMPMODE', $ ; detector sampling mode     
         numreads_fitskw:'NUMREADS', $ ; number of reads
         platescale_fitskw:'SSCALE', $ ; platescale            
         array_index_fitskw:'CRPIX1', $ ; starting wavelength in dispersion
         lin_disp_fitskw:'CDELT1', $ ; linear dispersion in z axis
         reference_fitskw:'CRVAL1', $ ; reference pixel
         unit_fitskw:'CUNIT1', $ ; units that accompany the starting wavelength
         polling_rate:1.0, $ ; polling rate in seconds        
         testserver:'osiris_testserver', $ ; function checks to see if the server is up
         isframeready:'osiris_isframeready', $ ; function checks for frame
         getfilename:'osiris_getfilename', $ ; function gets the filename
         openfiles:'osiris_openfiles', $ ; function that opens new files
         transition:1., $ ; get filename when transition changes from 0 -> 1
         dir_polling_on:1., $ ; 0. directory polling off, 1. directory polling on
         poll_dir:'~/osiris/spec_raw', $ ; set the initial polling directory
         server_polling_on:0., $ ; 0. server polling off, 1. server polling on 
         poll_server:'osiris', $ ; sets the polling server name 
         dir_arr:ptr_new('', /allocate_heap), $
         new_files:ptr_new('', /allocate_heap), $
         conbase_dir:'~/osiris/spec_raw', $ ; set the initial conbase directory
         draw_xs:512., $ ; x size of the draw window
         draw_ys:512., $ ; y size of the draw window
         diagonal:2., $ ; diagonal width
         color_table:1, $ ; loadct color table value
         pointer_type:24, $ ; IDL pointer type value.  40, 24, 54
         axes_labels2d:axes_labels2d, $
         axes_labels3d:axes_labels3d, $
         imscalemaxcon:5., $ ; default image stretch max imscalemaxcon*im_sigma
         imscalemincon:-3., $ ; default image stretch min imscalemincon*im_sigma
         displayasdn:'As DN/s', $ ; sets member variable as "As DN/s" or "As Total DN", how the image is displayed
         collapse:1, $ ; sets collapse member var to 'Median' (0) or 'Average' (1)
         pa_function:'osiris_calc_pa', $ ; function that calculates the position angle
         exit_question:0., $ ; 1 if you want QL2 to ask about keeping IDL running when exiting
         ParentBaseId:0L $
       }

return, struct

endif else begin
    print, 'There was an error loading the config file.'
    ; return the default array of member variables
    error=-1
    return, -1
endelse

end
