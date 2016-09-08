pro CPlotWin_Print, base_id

print, 'printing plot'
widget_control, base_id, get_uval=uval

self=*(uval.self_ptr)

; get filename or printer name
ps_filename=dialog_print(group=base_id, 

set_plot, 'ps'
device, /landscape, filename=ps_filename

self->DrawPlot

device, /close
set_plot, 'x'



end
