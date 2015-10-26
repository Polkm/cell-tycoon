math.tau = math.pi * 2

-- Returns a random float between low and high
function math.randomf(low, high) return low + ((high - low) * math.random()) end
--
function math.randome(exp) return math.random() ^ exp end

-- Returns a random float between low and high arguments with exponential weight curve
function math.randomer(low, high, exp) return low + (high - low) * math.randome(exp) end

-- Random normal distribution sample 0-1
function math.randomn(mean, sd)
  return math.sqrt(-2 * math.log(math.random())) * math.cos(2 * math.pi * math.random()) * sd + mean
end

function math.randomDiscXY(x, y, r)
  local a, d = math.random() * math.pi * 2, math.sqrt(math.random()) * r
  return x + math.cos(a) * d, y + math.sin(a) * d
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

function table.contains(tbl, element)
  for _, v in pairs(tbl) do if v == element then return true end end
  return false
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
