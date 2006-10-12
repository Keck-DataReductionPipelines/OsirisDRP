pro init_colors

   device, decomposed=0
   rtiny   = [0, 1, 0, 0, 0, 1, 1, 1]
   gtiny = [0, 0, 1, 0, 1, 0, 1, 1]
   btiny  = [0, 0, 0, 1, 1, 1, 0, 1]
   tvlct, 255*rtiny, 255*gtiny, 255*btiny
   tvlct, [255],[255],[255], !d.table_size-1

end
