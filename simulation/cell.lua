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
      return {249, 22, 213}, {214, 86, 241}
    elseif type == "plast" then
      return {132, 219, 44}, {50, 128, 50}
    elseif type == "mover" then
      return {27, 101, 255}, {68, 119, 162}
    elseif type == "fat" then
      return {255, 162, 0}, {151, 133, 73}
    elseif type == "sense" then
      return {239, 244, 25}, {224, 227, 77}
    elseif type == "cancer" then
      return {52, 27, 32}, {52, 27, 32}
    end
    return {255, 255, 255}, {255, 255, 255}
  end

  function p.getColor()
    local d = 1 - (p.energy / p.maxEnergy())
    local aliveCol, deadCol = p.getColors()
    local r, g, b = lerp3t(aliveCol, deadCol, d)
    return r, g, b, 255
  end

  local function randomDirection(x, y)
    local r = math.random()
    if r < 0.5 then
      return x + (r < 0.25 and 1 or -1), y
    else
      return x, y + (r > 0.75 and 1 or -1)
    end
  end

  function p.maxEnergy()
    if type == "fat" then
      return 100
    else
      return 1
    end
  end

  function p.addEnergy(amount)
    p.energy = clamp(p.energy + amount, 0, p.maxEnergy())
  end

  function p.livingEnergyCost()
    if p.type == "sense" then
      return -0.05
    elseif p.type == "brain" then
      return -0.05
    elseif p.type == "plast" then
      return 1
    end
    return -0.02
  end

  local moveForce = 200

  function p.metabolize(dt, x, y)
    p.age = p.age + dt

    -- Cost of life
    p.addEnergy(p.livingEnergyCost() * dt)

    -- Pushing
    if p.type == "mover" and p.energy > 0.1 then
      cult.forwardForce = clamp(cult.forwardForce + moveForce * dt, 0, 1000)
      -- cult.angleForce = math.cos(p.age) * 100
    end

    -- Stopping
    if p.type == "plast" then
      cult.forwardForce = clamp(cult.forwardForce - moveForce * dt, 0, 1000)
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
    local growCost = 0.5
    if p.energy >= growCost and not cult.getCell(gx, gy) then
      if cult.cellCount >= 5 then
        p.addEnergy(-growCost)
      end

      local type = cult.getTypeMap(gx, gy)
      if type and (type ~= "plast" or not cult.exhausted) then
        cult.setCell(gx, gy, cell({type = type}, cult))
        cult.cellCount = cult.cellCount + 1
        cult.massX, cult.massY = cult.massX + (gx - cult.maxSize * 0.5), cult.massY + (gy - cult.maxSize * 0.5)
      end
    end

    -- Death
    if p.age > 0.8 and p.energy <= 0.001 then
      p.alive = false
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
