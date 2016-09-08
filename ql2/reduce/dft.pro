function dft, data
 return, centre(fft(decentre(data), -1))
end
