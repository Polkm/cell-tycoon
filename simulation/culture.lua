require("simulation/cell")

function culture(p, worker, id)
  local cells = {}
  local typeMap = {}
  local maxSize = 64
  p.maxSize = maxSize

  p.id = id
  p.forwardForce = 0
  p.angleForce = 0
  p.symmetry = 2

  p.cellCount = 0
  p.massEaten = 0
  p.massX, p.massY = 0, 0
  p.exhausted = false

  p.fatStartEnergy = 1000

  function p.init(imageData, genome)
    p.startTime = love.timer.getTime()
    p.imageData = imageData

    p.setCell(p.maxSize * 0.5, p.maxSize * 0.5, cell({type = "brain", energy = 1}, p))
    if genome then
      typeMap = genome.typeMap
    else
      p.setRandomTypeMap()
    end

    worker.outputChannel:push({func = "updateTypeMap", id = id, encode(typeMap)})
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

  local function setTypeMap(x, y, v)
    typeMap[math.floor(x) + math.floor(y) * maxSize] = v
  end
  p.setTypeMap = setTypeMap

  local function getTypeMap(x, y)
    return typeMap[math.floor(x) + math.floor(y) * maxSize]
  end
  p.getTypeMap = getTypeMap

  function p.setRandomTypeMap()
    local types = {"fat", "mover", "plast"}

    setTypeMap(p.maxSize * 0.5, p.maxSize * 0.5, "brain")

    for i = 1, clamp(math.randomn(20, 200), 2, 500) do
      local i, randType = table.random(typeMap)
      local x, y = i % maxSize + math.random(-1, 1), math.floor(i / maxSize) + math.random(-1, 1)
      if not getTypeMap(x, y) then
        local _, randType = table.random(types)
        setTypeMap(x, y, randType)

        if randType == "fat" then
          p.fatStartEnergy = p.fatStartEnergy * 0.5
        end
      end
    end
  end

  local function renderCells()
    if p.imageData then
      p.imageData:mapPixel(function(x, y, r, g, b, a)
        local v = getCell(x, y)
        if v then return v.getColor() end
        return 0, 0, 0, 0
      end)
    end
  end

  function p.update(dt)
    local time = love.timer.getTime()

    p.forwardForce = 0

    local count = 0
    for i, v in pairs(cells) do
      count = count + 1
      local x, y = math.floor(i % maxSize), math.floor(i / maxSize)
      v.metabolize(dt, x, y)
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

    worker.outputChannel:push({func = "cultureUpdate", id = id, p.cellCount, p.massEaten, avgX, avgY, p.forwardForce, p.angleForce})
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

  function p.feed(mass)
    -- assert(mass, mass)
    local fatCount = 0
    for _, cell in pairs(cells) do
      if cell.type == "fat" then fatCount = fatCount + 1 end
    end
    for _, cell in pairs(cells) do
      if cell.type == "fat" then
        cell.energy = cell.energy + (mass * 10) / fatCount
      end
    end
  end

  function p.recieveTypeMap(max)
    p.maxSize = max or maxSize
    p.setRandomTypeMap()
  end

  function p.decay(cost, rate)
    for i, v in pairs(cells) do
      if math.random(0,1000) < cost then
        cells[i].alive = false
      end
    end
    if (math.random(0,rate) == 0) then
      p.exhausted = true
      worker.outputChannel:push({func = "exhaust", id = id})
    end
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
