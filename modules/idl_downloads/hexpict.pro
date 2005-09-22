pro hexpict
a = lonarr(16,16)
get_lun, myunit
openr, myunit, "HexPict.txt"
readf, myunit, a, FORMAT='(16Z0)'
close, myunit
free_lun, myunit
a = transpose(a)
a = congrid(a, 384, 384)
PRINT, MIN(a), MAX(a)
tv, BYTSCL(a, MIN=MIN(a), MAX=MAX(a))
end
