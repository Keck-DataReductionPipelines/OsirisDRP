pro smile
a = lonarr(64,64)
get_lun, myunit
openr, myunit, "C:\TMG\simcolhist\Debug\acqu0d.txt"
readf, myunit, a
close, myunit
free_lun, myunit
b = transpose(a[0:15,0:15])
b = congrid(b, 384, 384)
tv, b
get_lun, myunit
openw, myunit, "C:\TMG\simcolhist\Debug\acqu0d_print.txt"
printf, myunit, a[0:15,0:15], FORMAT='(16I7/)'
close, myunit
free_lun, myunit
end