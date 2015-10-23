math.tau = math.pi * 2

love.graphics.setDefaultFilter("nearest", "nearest")

function istable(x) return type(x) == "table" end
function isnttable(x) return type(x) ~= "table" end

-- Returns a random float between low (l) and high (h) arguments
function math.randomr(l, h) return l + ((h - l) * math.random()) end
--
function math.randome(e) return math.random() ^ e end
-- Returns a random float between low (l) and high (h) arguments with exp (e) weight curve
function math.randomer(l, h, e) return l + (h - l) * math.randome(e) end

function math.randomn(mean, sd)
  return math.sqrt(-2 * math.log(math.random())) * math.cos(2 * math.pi * math.random()) * sd + mean
end

function math.clamp(x, l, h)
  return math.min(math.max(x, l), h)
end

function math.distanceFromLine(x0, y0, x1, y1, x2, y2)
  return math.abs((y2 - y1) * x0 - (x2 - x1) * y0 + x2 * y1 - y2 * x1) / math.sqrt((y2 - y1) ^ 2 + (x2 - x1) ^ 2)
end

-- Returns a random key based on its value (weight)
-- example: math.weightedRandom({foo = 20, bar = 10, polkm = 1}))
-- Weights are NOT percents, they get "normalized"
function math.weightedRandom(tbl)
  local weightSum = 0

  for choice, weight in pairs(tbl) do
    weightSum = weightSum + weight
  end

  local threshold = math.random(0, weightSum)
  local last_choice, last_weight

  for choice, weight in pairs(tbl) do
    threshold = threshold - weight
    if threshold <= 0 then return choice, weight end
    last_choice, last_weight = choice, weight
  end
  return last_choice, last_weight
end

function math.lerp(a, b, t) return a + (b - a) * t end

function math.alerp(a, b, t)
  local slerp = vec(math.cos(a), math.sin(a)).slerp(vec(math.cos(b), math.sin(b)), t)
	return math.atan2(slerp.y, slerp.x)
end

function math.squeeze4(s, a, b, c, d)
  return math.floor(a) + math.floor(b) * s + math.floor(c) * s * s + math.floor(d) * s * s * s
end

function math.unsqueeze4(s, v)
  local s2, s3 = s * s, s * s * s
  local a = math.floor(v / s3)
  local b = math.floor((v - a * s3) / s2)
  local g = math.floor((v - a * s3 - b * s2) / s)
  -- return v % s, 0, 0, 255
  return v % s, g, b, a
end


function table.count(tbl)
  local c = 0
  for _, __ in pairs(tbl) do c = c + 1 end
  return c
end

-- Returns a random value from the table
function table.random(tbl)
  if type(tbl) ~= "table" then return end

  local count = table.count(tbl)
  if count <= 0 then return end

  local rndKey = math.random(1, count)
  local i = 1
  for k, v in pairs(tbl) do
    if i == rndKey then return k, v end
    i = i + 1
  end
end

function table.randomw(tbl, weights)
  local ran = math.random()
  local sum = 0
  for k, v in pairs(weights) do
    if ran > sum and ran <= sum + v then
      return tbl[k]
    end
    sum = sum + v
  end
end

local function deafultSort(a, b) return a > b end
function table.insertSort(tbl, func)
  func = func or deafultSort
  local len = #tbl
  for j = 2, len do
    local key, i = tbl[j], j - 1
    while i > 0 and not func(tbl[i], key) do
      tbl[i + 1] = tbl[i]
      i = i - 1
    end
    tbl[i + 1] = key
  end
  return tbl
end

function love.image.eachPixel(img, callback)
  if not img then return end
  local imageData = img:getData()
  for ix = 0, imageData:getWidth() - 1 do
    for iy = 0, imageData:getHeight() - 1 do
      local r, g, b, a = imageData:getPixel(ix, iy)
      -- if a > 0 then println(r) end
      callback(vec(ix, iy), color(r, g, b, a))
    end
  end
end

function love.image.minmax(img)
  local minx, miny, maxx, maxy
  love.image.eachPixel(img, function(pos, clr)
    if clr.a == 255 then
      if not minx or minx > pos.x then minx = pos.x end
      if not maxx or maxx < pos.x then maxx = pos.x end
      if not miny or miny > pos.y then miny = pos.y end
      if not maxy or maxy < pos.y then maxy = pos.y end
    end
  end)
  return vec(minx, miny), vec(maxx, maxy)
end
