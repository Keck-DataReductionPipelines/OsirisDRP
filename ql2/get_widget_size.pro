function get_widget_size, wid

geom=widget_info(wid, /geom)
xs=geom.xsize+2*(geom.xpad)
ys=geom.ysize+2*(geom.ypad)

return, [xs, ys]

end
