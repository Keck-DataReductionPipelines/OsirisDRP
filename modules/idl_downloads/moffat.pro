


;      MOFFAT        A(0) + A(1)/(u + 1)^A(7)
;      u = ( (x-A(4))/A(2) )^2 + ( (y-A(5))/A(3) )^2

function moffat, x, y, p

  u = ((x-p(0))/p(2))^2 + ((y-p(1))/p(2))^2
  f = p(3) / (u+1.)^p(4)
  return, f
end
