function dfti, data
 return, centre(fft(decentre(data), 1))
end
