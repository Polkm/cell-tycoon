function cell(p, culture)
  p.type = p.type or "stem"
  p.age = p.age or 0
  p.energy = p.energy or 0.1
  p.alive = p.alive or true

  function p.getColors()
    local type = p.type
    if type == "stem" then
      return 255, 68, 114, 68, 52, 101
    elseif type == "brain" then
      return 77, 213, 145, 93, 153, 111
    elseif type == "plast" then
      return 132, 219, 44, 50, 128, 50
    elseif type == "mover" then
      return 113, 54, 246, 71, 105, 159
    end
  end

  function p.metabolize(dt)
    p.age = p.age + dt
    p.energy = math.max(p.energy - 1 * dt, 0)

    -- Photosynthesis
    if p.type == "plast" then
      p.energy = math.min(p.energy + 1000 * dt, 1)
    end

    -- Pushing
    if p.type == "mover" and p.energy >= 0.5 then
      culture.forwardForce = culture.forwardForce + 100 * dt
    end

    if p.age > 0.8 then
      if p.energy <= 0 then
        p.alive = false
      end
    end
  end

  return p
end
