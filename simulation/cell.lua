function cell(p)
  p.type = p.type or "stem"
  p.age = p.age or 0
  p.energy = p.energy or 0

  function p.getColors()
    local type = p.type
    if type == "stem" then
      return 255, 68, 114, 68, 52, 101
    elseif type == "brain" then
      return 77, 213, 145, 93, 153, 111
    elseif type == "plast" then
      return 132, 219, 44, 50, 128, 50
    end
  end

  return p
end
