require("love.timer")
require("love.graphics")
require("love.image")
require("love.math")
require("love.physics")
require("love.filesystem")
require("core/noise")

inputChannel, outputChannel, cellImage, props, body = ...

local startTime = love.timer.getTime()
local cells = {}
local maxSize = 64
local lifetime = 1

local cellCount = 0
local massEaten = 0
local massX, massY = 0, 0
local forX, forY = 0, 0

math.randomseed(props.seed)
math.random()
math.random()
math.random()

local function clamp(v, l, h)
  if not v or not l or not h then return v end
  return math.min(math.max(v, l), h)
end
local function lerp(a, b, d) return a + (b - a) * d end

local function setCell(x, y, v)
  x, y = math.floor(clamp(x, 0, maxSize - 1)), math.floor(clamp(y, 0, maxSize - 1))
  cells[x + y * maxSize] = v
end
local function getCell(x, y)
  x, y = math.floor(clamp(x, 0, maxSize - 1)), math.floor(clamp(y, 0, maxSize - 1))
  return cells[x + y * maxSize]
end

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
  local time = love.timer.getTime()
  local data = cellImage:getData()
  data:mapPixel(function(x, y, r, g, b, a)
    local v = getCell(x, y)
    if v then
      -- assert(v - startTime == 0, (v - startTime))
      local d = 1 - v.en
      -- local age = math.min(time - v.time, lifetime)
      -- local d = math.max(((age / lifetime)))
      local ra, ga, ba, rb, gb, bb = getTypeColor(v.type)
      local r, g, b = clamp(lerp(ra, rb, d), 0, 255), clamp(lerp(ga, gb, d), 0, 255), clamp(lerp(ba, bb, d), 0, 255)

      return r, g, b, 150
    end
    return 0, 0, 0, 0
  end)
  -- cellImage:refresh()
end

setCell(maxSize * 0.5, maxSize * 0.5, {["time"] = love.timer.getTime(), type = "brain", en = 10})

local function growthDirection(x, y)
  local r = math.random()
  if r < 0.5 then
    return x + (r < 0.25 and 1 or -1), y
  else
    return x, y + (r > 0.75 and 1 or -1)
  end
end

local size = props.seed * 0.5 + 0.5

-- local octaves, amplitude, gain, frequency, lacunarity = math.random(1, 8), 1, 1 - math.random(), 0.05, 1.5 + math.random()
local octaves, amplitude, gain, frequency, lacunarity = 2, 1, 0.8, 0.05, 2

local function cull(x, y)
  local s = 1--math.min(props.seed, 1)
  -- local s = math.max(math.min(((love.timer.getTime() - startTime) / 4), 1), 0)
  local r = math.simplexNoise(math.abs(x - maxSize * 0.5) / s, (y - maxSize * 0.5) / s, octaves, amplitude, gain, frequency, lacunarity, props.seed)
  local fx, fy = x - maxSize * 0.5, y - maxSize * 0.5
  local dist = math.floor(math.sqrt(fx * fx + fy * fy))
  local v = getCell(x, y)
  if v and love.timer.getTime() - v.time > 2 and v.en <= 0 then return true end
  return cellCount > 4 and dist > 0 and (r < -0.2 + (dist / (maxSize * 0.5)) or dist > math.ceil(maxSize * 0.5))
end


local function growthLimit(x, y, nx, ny, age)
  -- if age > lifetime * 0.1 and age < lifetime * 0.5 then
  --   local fx, fy = x - maxSize * 0.5, y - maxSize * 0.5
  --   local old = getCell(nx, ny)
  --
  --   local s = 1 --math.min(size, 1)
  --   -- local s = math.min((love.timer.getTime() - startTime) / 4 + 0.5, 1)
  --   local octaves, amplitude, gain, frequency, lacunarity = 2, 1, 0.5, 0.2, 2
  --
  --   -- local r = math.simplexNoise(math.abs(nx - maxSize * 0.5) * s, (ny - maxSize * 0.5) * s, octaves, amplitude, gain, frequency, lacunarity, 0)
  --   local r = math.simplexNoise(math.abs(x - maxSize * 0.5) / s, (y - maxSize * 0.5) / s, octaves, amplitude, gain, frequency, lacunarity, props.seed)
  --
  --   -- local r = love.math.noise()
  --   if cellCount > 4 and r > -0.15 then return false end
  --   -- if cellCount > 4 and (age < 0.5 or age > 0.5) and r > 0 then return false end
  --
  --   return not old and math.floor(math.sqrt(fx * fx + fy * fy)) < math.ceil(maxSize * 0.5 - 2)
  --   -- return (not old or love.timer.getTime() - old.time > lifetime) and math.floor(math.sqrt(fx * fx + fy * fy)) < math.ceil(maxSize * 0.5 - 2)
  -- end
  return not getCell(nx, ny) and not cull(nx, ny)
end

-- local function growth

local typeMap = {}
local function setTypeRange(low, high, type)
  for i = low, high do
    typeMap[i] = type
  end
end
local function setRandomTypeRange(type)
  local low = math.random(11, 64)
  local high = math.random(low + 1, low + 64)
  setTypeRange(low, high, type)
end
setTypeRange(0, 10, "brain")
for i = 1, math.random(1, 3) do
  setRandomTypeRange("plast")
end

local alive = true

while alive do
  local input = inputChannel:demand()
  while input ~= "think" do
    if input == "die" then return end

    if input.func == "set" then
      setCell(input.x, input.y, {["time"] = love.timer.getTime(), type = "brain", en = 0})
    elseif input.func == "bite" then
      -- assert(false)
      local removedMass = 0
      for xx = -input.r, input.r do
        for yy = -input.r, input.r do
          if math.sqrt(xx * xx + yy * yy) < input.r then
            local x, y = clamp(input.x + xx, 0, maxSize - 1), clamp(input.y + yy, 0, maxSize - 1)
            if getCell(x, y) then
              setCell(x, y, nil)
              removedMass = removedMass + 1
              cellCount = cellCount - 1
              massX, massY = massX - (x - maxSize * 0.5), massY - (y - maxSize * 0.5)
            end
          end
        end
      end
      outputChannel:push({func = "feed", id = input.id, removedMass = removedMass})
      -- agents[input.id].feed(removedMass)
      -- if input.body and not input.body:isDestroyed() and input.body:getUserData() then
        -- input.body:getUserData().feed(removedMass)
      -- end
    elseif input.func == "feed" then
      massEaten = massEaten + input.cellMass
    end
    input = inputChannel:demand()
  end

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
        local a = body:getAngle() - math.pi * 0.5
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
        if typeMap[cellCount] then
          type = typeMap[cellCount]
        end
        setCell(gx, gy, {["time"] = time, type = type, en = 0})
        cellCount = cellCount + 1
        massX, massY = massX + (gx - maxSize * 0.5), massY + (gy - maxSize * 0.5)
      end
    -- end

    if cull(x, y) then
      setCell(x, y, nil)
      cellCount = cellCount - 1
      massX, massY = massX - (x - maxSize * 0.5), massY - (y - maxSize * 0.5)
    end
  end

  renderCells()

  local avgX, avgY = 0, 0
  local count = 0
  for i, cell in pairs(cells) do
    avgX, avgY = avgX + (i % maxSize), avgY + math.floor(i / maxSize)
    count = count + 1
  end


  outputChannel:push({cellCount = cellCount, massEaten = massEaten, massX = avgX, massY = avgY, forX = forX, forY = forY})
end
