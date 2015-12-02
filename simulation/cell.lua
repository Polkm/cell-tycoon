function cell(p, cult)
  p.type = p.type or "stem"
  p.age = p.age or 0
  p.energy = p.energy or 0.1
  p.alive = p.alive or true

  if p.type == "fat" then
    p.energy = cult.fatStartEnergy
  end

  function p.getColors()
    local type = p.type
    if type == "stem" then
      return {255, 68, 114}, {68, 52, 101}
    elseif type == "brain" then
      return {255, 0, 0}, {255, 0, 0}
    elseif type == "plast" then
      return {132, 219, 44}, {50, 128, 50}
    elseif type == "mover" then
      return {113, 54, 246}, {71, 105, 159}
    elseif type == "fat" then
      return {255, 162, 0}, {137, 87, 0}
    elseif type == "sense" then
      return {239, 244, 25}, {224, 227, 77}
    elseif type == "cancer" then
      return {52, 27, 32}, {52, 27, 32}
    end
    return {255, 255, 255}, {255, 255, 255}
  end

  local function randomDirection(x, y)
    local r = math.random()
    if r < 0.5 then
      return x + (r < 0.25 and 1 or -1), y
    else
      return x, y + (r > 0.75 and 1 or -1)
    end
  end

  function p.metabolize(dt, x, y)
    p.age = p.age + dt
    p.energy = math.max(p.energy - 0 * dt, 0)

    -- Photosynthesis
    if p.type == "plast" then
      p.energy = math.min(p.energy + 20 * dt, 1)
    end

    -- Pushing
    if p.type == "mover" and p.energy > 0.1 then
      cult.forwardForce = cult.forwardForce + 200 * dt * p.energy
      -- cult.angleForce = math.cos(p.age) * 100
    end

    if p.age > 0.8 then
      if p.energy <= 0.001 then
        p.alive = false
      end
    end

    -- Spread energy
    local gx, gy = randomDirection(x, y)
    if p.energy > 0 then
      local gv = cult.getCell(gx, gy)
      if gv then
        local enGiven = math.min(p.energy * 0.5, 1 - gv.energy)
        gv.energy = gv.energy + enGiven
        p.energy = p.energy - enGiven
      end
    end

    -- Growing
    if p.energy > 0.01 and not cult.getCell(gx, gy) then
      if cult.cellCount >= 5 then
        p.energy = p.energy * 0.5
      end

      local type = cult.getTypeMap(x, y)
      if type then
        if type ~= "plast" or not cult.exhausted then
          cult.setCell(gx, gy, cell({type = type}, cult))
          cult.cellCount = cult.cellCount + 1
          cult.massX, cult.massY = cult.massX + (gx - cult.maxSize * 0.5), cult.massY + (gy - cult.maxSize * 0.5)
        end
      end
    end

    -- Decaying
    if not p.alive then
      cult.setCell(x, y, nil)
      cult.cellCount = cult.cellCount - 1
      cult.massX, cult.massY = cult.massX - (x - cult.maxSize * 0.5), cult.massY - (y - cult.maxSize * 0.5)
    end
  end

  return p
end
