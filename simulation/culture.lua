require("simulation/cell")

function culture(p, worker, id)
  local cells = {}
  local typeMap = {}
  local maxSize = 64
  p.maxSize = maxSize
  local maxAngles = 256
  p.id = id
  p.forwardForce = 0

  function p.init(imageData, seed, id)
    p.startTime = love.timer.getTime()
    p.lifetime = 1

    p.cellCount = 0
    p.massEaten = 0
    p.massX, p.massY = 0, 0

    p.imageData = imageData
    p.seed = seed
    p.id = id

    math.randomseed(seed)
    math.random()
    math.random()
    math.random()

    p.setCell(p.maxSize * 0.5, p.maxSize * 0.5, cell({type = "brain", energy = 1}, p))
    p.setTypeRange(0, 1, "brain")
    for i = 1, math.random(1, 5) do
      p.setRandomTypeRange("plast")
    end
  end

  function p.remove()
    worker.cultures[id] = nil
    p.imageData = nil
  end

  local function setCell(x, y, v)
    x, y = math.floor(clamp(x, 0, maxSize - 1)), math.floor(clamp(y, 0, maxSize - 1))
    cells[x + y * maxSize] = v
  end
  p.setCell = setCell
  local function getCell(x, y)
    x, y = math.floor(clamp(x, 0, maxSize - 1)), math.floor(clamp(y, 0, maxSize - 1))
    return cells[x + y * maxSize]
  end
  p.getCell = getCell

  local function renderCells()
    if p.imageData then
      p.imageData:mapPixel(function(x, y, r, g, b, a)
        local v = getCell(x, y)
        if v then
          local d = 1 - v.energy
          local ra, ga, ba, rb, gb, bb = v.getColors()
          local r, g, b = clamp(lerp(ra, rb, d), 0, 255), clamp(lerp(ga, gb, d), 0, 255), clamp(lerp(ba, bb, d), 0, 255)
          return r, g, b, 150
        end
        return 0, 0, 0, 0
      end)
    end
  end

  local function growthDirection(x, y)
    local r = math.random()
    if r < 0.5 then
      return x + (r < 0.25 and 1 or -1), y
    else
      return x, y + (r > 0.75 and 1 or -1)
    end
  end

  local octaves, amplitude, gain, frequency, lacunarity = 2, 1, 0.8, 0.05, 2

  function p.setTypeRange(low, high, type)
    for i = low, high do
      typeMap[i] = type
    end
  end
  function p.setRandomTypeRange(type)
    local low = math.random(0, maxSize * maxSize * 0.1)
    local high = math.random(low + 1, low + maxSize * maxSize * 0.1)
    p.setTypeRange(low, high, type)
  end

  function p.bite(bitterid, x, y, r)
    local removedMass = 0
    for xx = -r, r do
      for yy = -r, r do
        if math.sqrt(xx * xx + yy * yy) < r then
          local rx, ry = clamp(x + xx, 0, p.maxSize - 1), clamp(y + yy, 0, p.maxSize - 1)
          if getCell(rx, ry) then
            setCell(rx, ry, nil)
            removedMass = removedMass + 1
            p.cellCount = p.cellCount - 1
            p.massX, p.massY = p.massX - (rx - p.maxSize * 0.5), p.massY - (ry - p.maxSize * 0.5)
          end
        end
      end
    end
    worker.outputChannel:push({func = "feed", id = bitterid, removedMass})
  end

  function p.feed(id, mass)
    -- println("fed")
  end

  function p.update(dt)
    local time = love.timer.getTime()

    p.forwardForce = 0

    local count = 0
    for i, v in pairs(cells) do
      count = count + 1
      local age = v.age
      local x, y = math.floor(i % maxSize), math.floor(i / maxSize)

      v.metabolize(dt)

      local gx, gy = growthDirection(x, y)
      if v.energy > 0 then
        local gv = getCell(gx, gy)
        if gv then
          local enGiven = math.min(v.energy * 0.5, 1 - gv.energy)
          gv.energy = gv.energy + enGiven
          v.energy = v.energy - enGiven
        end
      end

      -- if age > 0.1 and age < lifetime then
      if v.energy > 0.1 and not getCell(gx, gy) then
        -- setCell(x, y, {["time"] = time})
        local type = "mover"
        if typeMap[p.cellCount] then
          type = typeMap[p.cellCount]
        end
        setCell(gx, gy, cell({type = type}, p))
        p.cellCount = p.cellCount + 1
        p.massX, p.massY = p.massX + (gx - maxSize * 0.5), p.massY + (gy - maxSize * 0.5)

        v.energy = v.energy * 0.9
      end

      if not v.alive then
        setCell(x, y, nil)
        p.cellCount = p.cellCount - 1
        p.massX, p.massY = p.massX - (x - maxSize * 0.5), p.massY - (y - maxSize * 0.5)
      end
    end

    renderCells()

    local avgX, avgY = 0, 0
    local count = 0
    for i, cell in pairs(cells) do
      avgX, avgY = avgX + (i % maxSize), avgY + math.floor(i / maxSize)
      count = count + 1
    end
    if count > 0 then
      avgX, avgY = avgX / count, avgY / count
    end

    worker.outputChannel:push({func = "cultureUpdate", id = id, p.cellCount, p.massEaten, avgX, avgY, p.forwardForce})
  end

  function p.evaluate()
    -- gets us a breakdown of how this cell is structured
    local stem = 0
    local brain = 0
    local plast = 0
    local mover = 0
    for _, c in pairs(cells) do
      if c.type == "stem" then
        stem = stem + 1
      elseif c.type == "brain" then
        brain = brain + 1
      elseif c.type == "plast" then
        plast = plast + 1
      elseif c.type == "mover" then
        mover = mover + 1
      end
    end
    worker.outputChannel:push({func = "updateCellCount", id = id, stem, brain, plast, mover})
  end


  return p
end
