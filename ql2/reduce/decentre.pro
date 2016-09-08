;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
function decentre, image
 o = origin(image)
  s = size(image)
  if (s(0) eq 1) then $
    return, shift(image, -o(0)) $
  else $
    return, shift(image, -o(0), -o(1))
end
