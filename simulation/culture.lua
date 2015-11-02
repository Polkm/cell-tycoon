function culture(p, worker, id)
  local cells = {}
  local typeMap = {}
  local maxSize = 64
  p.maxSize = maxSize
  p.id = id

  function p.init(cellImage, body, seed, id)
    p.startTime = love.timer.getTime()
    p.lifetime = 1

    p.cellCount = 0
    p.massEaten = 0
    p.massX, p.massY = 0, 0
    p.forX, p.forY = 0, 0

    p.cellImage = cellImage
    p.body = body
    p.seed = seed
    p.id = id

    math.randomseed(seed)
    math.random()
    math.random()
    math.random()

    p.setCell(p.maxSize * 0.5, p.maxSize * 0.5, {["time"] = love.timer.getTime(), type = "brain", en = 10})
    p.setTypeRange(0, 10, "brain")
    for i = 1, math.random(1, 3) do
      p.setRandomTypeRange("plast")
    end
  end

  function p.remove()
    worker.cultures[id] = nil
    p.cellImage = nil
    p.body = nil
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

  local ra, ga, ba = 255, 68, 114
  local rb, gb, bb = 68, 52, 101

  local function getTypeColor(type)
    if type == "stem" then
      return 255, 68, 114, 68, 52, 101
    elseif type == "brain" then
      return 77, 213, 145, 93, 153, 111
    elseif type == "plast" then
      return 132, 219, 44, 50, 128, 50
    end
  end

  local function renderCells()
    if p.cellImage then
      local data = p.cellImage:getData()
      data:mapPixel(function(x, y, r, g, b, a)
        local v = getCell(x, y)
        if v then
          local d = 1 - v.en
          local ra, ga, ba, rb, gb, bb = getTypeColor(v.type)
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

  local function cull(x, y)
    local s = 1
    local r = math.simplexNoise(math.abs(x - maxSize * 0.5) / s, (y - maxSize * 0.5) / s, octaves, amplitude, gain, frequency, lacunarity, p.seed)
    local fx, fy = x - maxSize * 0.5, y - maxSize * 0.5
    local dist = math.floor(math.sqrt(fx * fx + fy * fy))
    local v = getCell(x, y)
    if v and love.timer.getTime() - v.time > 2 and v.en <= 0 then return true end
    return p.cellCount > 4 and dist > 0 and (r < -0.2 + (dist / (maxSize * 0.5)) or dist > math.ceil(maxSize * 0.5))
  end

  local function growthLimit(x, y, nx, ny, age)
    return not getCell(nx, ny) and not cull(nx, ny)
  end

  function p.setTypeRange(low, high, type)
    for i = low, high do
      typeMap[i] = type
    end
  end
  function p.setRandomTypeRange(type)
    local low = math.random(11, 64)
    local high = math.random(low + 1, low + 64)
    p.setTypeRange(low, high, type)
  end

  function p.bite(bitterid, x, y, r)
    local removedMass = 0
    for xx = -r, r do
      for yy = -r, r do
        if math.sqrt(xx * xx + yy * yy) < r then
          local rx, ry = clamp(x + xx, 0, p.maxSize - 1), clamp(y + yy, 0, p.maxSize - 1)
          if p.getCell(rx, ry) then
            p.setCell(rx, ry, nil)
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

    forX, forY = 0, 0

    local count = 0
    for i, v in pairs(cells) do
      count = count + 1
      local age = time - v.time
      local x, y = i % maxSize, math.floor(i / maxSize)
      x, y = math.floor(x), math.floor(y)

      if v.type == "plast" then
        setCell(x, y, {["time"] = v.time, type = v.type, en = 1})
      end

      if v.type == "stem" then
        if v.en >= 0.5 then
          setCell(x, y, {["time"] = v.time, type = v.type, en = v.en - 0.5})
          local a = 0
          if p.body and not p.body:isDestroyed() then
            a = p.body:getAngle() - math.pi * 0.5
          end
          local forwardX, forwardY = math.cos(a), math.sin(a)
          forX, forY = forX + forwardX * 5, forY + forwardY * 5
        end
      end

      if v.type ~= "plast" and v.en > 0 then
        setCell(x, y, {["time"] = v.time, type = v.type, en = math.max(v.en - 0.01, 0)})
      end

      if v.en > 0 then
        local gx, gy = growthDirection(x, y)
        local gv = getCell(gx, gy)
        if gv then
          setCell(gx, gy, {["time"] = gv.time, type = gv.type, en = gv.en + v.en * 0.5})
          setCell(x, y, {["time"] = v.time, type = v.type, en = v.en * 0.5})
        end
      end

      -- if age > 0.1 and age < lifetime then
        local gx, gy = growthDirection(x, y)
        if v.en > 0.5 and growthLimit(x, y, gx, gy, age) then
          -- setCell(x, y, {["time"] = time})
          local type = "stem"
          if typeMap[p.cellCount] then
            type = typeMap[p.cellCount]
          end
          setCell(gx, gy, {["time"] = time, type = type, en = 0})
          p.cellCount = p.cellCount + 1
          p.massX, p.massY = p.massX + (gx - maxSize * 0.5), p.massY + (gy - maxSize * 0.5)
        end
      -- end

      if cull(x, y) then
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

    worker.outputChannel:push({func = "cultureUpdate", id = id, p.cellCount, p.massEaten, avgX, avgY, forX, forY})
  end

  return p
end