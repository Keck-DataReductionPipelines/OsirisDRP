function origin, frame
 
  n = size(frame)
  result = intarr(2)
  result(0) = n(1)/2
  if (n(0) eq 2) then result(1) = n(2)/2 else result(1) = 0
  return, result
end
