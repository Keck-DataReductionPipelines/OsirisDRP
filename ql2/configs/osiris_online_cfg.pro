function osiris_online_cfg, error

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
         cfg_name:'OSIRIS ONLINE', $ ; instrument configuration
         inst_fitskw:'CURRINST', $ ; instrument fits keyword
         itime_fitskw:'ITIME', $ ; integration time
         coadds_fitskw:'COADDS', $ ; # of coadds
         pa_fitskw:'ROTPOSN', $ ; rotator position
         object_fitskw:'OBJECT', $ ; object kw
         sampmode_fitskw:'SAMPMODE', $      
         numreads_fitskw:'NUMREADS', $ ; number of reads
         platescale_fitskw:'SSCALE', $ ; platescale            
         array_index_fitskw:'CRPIX1', $ ; starting wavelength in dispersion
         lin_disp_fitskw:'CDELT1', $ ; linear dispersion in z axis
         reference_fitskw:'CRVAL1', $ ; reference pixel
         unit_fitskw:'CUNIT1', $ ; units that accompany the starting wavelength
         polling_rate:1.0, $         
         testserver:'osiris_testserver', $ ; function checks to see if the server is up
         isframeready:'osiris_isframeready', $ ; function checks for frame
         getfilename:'osiris_getfilename', $ ; function gets the filename
         openfiles:'osiris_openfiles', $ ; function that opens new files
         transition:1., $ ; get filename when transition changes from 0 -> 1
         dir_polling_on:1., $ ; turn the directory polling on
         poll_dir:'~/osiris/spec_orp', $ ; set the initial polling directory
         server_polling_on:0., $ ; does not turn on server polling
         poll_server:'osiris', $ ; sets the polling server name
         dir_arr:ptr_new('', /allocate_heap), $
         new_files:ptr_new('', /allocate_heap), $
         conbase_dir:'~/osiris/spec_orp', $ ; set the initial conbase directory
         draw_xs:512., $
         draw_ys:512., $
         diagonal:10., $ ; diagonal width
         color_table:8, $
         pointer_type:24, $
         axes_labels2d:axes_labels2d, $
         axes_labels3d:axes_labels3d, $
         imscalemaxcon:5., $
         imscalemincon:-3., $
         displayasdn:'As DN/s', $
         collapse:1, $ ; 'Median' (0), 'Average' (1)
         pa_function:'osiris_calc_pa', $
         exit_question:0., $
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
