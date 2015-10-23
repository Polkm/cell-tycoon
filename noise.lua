local ffi = require("ffi")
local bit = require("bit")

-- math.randomseed(os.time())
-- math.random()
-- math.random()
-- local seed = math.random(0, 10000)

local perms = ffi.new("uint8_t[512]", {
  151, 160, 137, 91, 90, 15, 131, 13, 201, 95, 96, 53, 194, 233, 7, 225,
  140, 36, 103, 30, 69, 142, 8, 99, 37, 240, 21, 10, 23, 190, 6, 148,
  247, 120, 234, 75, 0, 26, 197, 62, 94, 252, 219, 203, 117, 35, 11, 32,
  57, 177, 33, 88, 237, 149, 56, 87, 174, 20, 125, 136, 171, 168, 68, 175,
  74, 165, 71, 134, 139, 48, 27, 166, 77, 146, 158, 231, 83, 111, 229, 122,
  60, 211, 133, 230, 220, 105, 92, 41, 55, 46, 245, 40, 244, 102, 143, 54,
  65, 25, 63, 161, 1, 216, 80, 73, 209, 76, 132, 187, 208, 89, 18, 169,
  200, 196, 135, 130, 116, 188, 159, 86, 164, 100, 109, 198, 173, 186, 3, 64,
  52, 217, 226, 250, 124, 123, 5, 202, 38, 147, 118, 126, 255, 82, 85, 212,
  207, 206, 59, 227, 47, 16, 58, 17, 182, 189, 28, 42, 223, 183, 170, 213,
  119, 248, 152, 2, 44, 154, 163, 70, 221, 153, 101, 155, 167, 43, 172, 9,
  129, 22, 39, 253, 19, 98, 108, 110, 79, 113, 224, 232, 178, 185, 112, 104,
  218, 246, 97, 228, 251, 34, 242, 193, 238, 210, 144, 12, 191, 179, 162, 241,
  81, 51, 145, 235, 249, 14, 239, 107, 49, 192, 214, 31, 181, 199, 106, 157,
  184, 84, 204, 176, 115, 121, 50, 45, 127, 4, 150, 254, 138, 236, 205, 93,
  222, 114, 67, 29, 24, 72, 243, 141, 128, 195, 78, 66, 215, 61, 156, 180
})
ffi.copy(perms + 256, perms, 256)

local perms12 = ffi.new("uint8_t[512]")
for i=0,255 do local x = perms[i] % 12; perms12[i] = x; perms12[i+256] = x; end

local grads2 = ffi.new("const double[12][4]",
  {1,1,0},{-1,1,0},{1,-1,0},{-1,-1,0},
  {1,0,1},{-1,0,1},{1,0,-1},{-1,0,-1},
  {0,1,1},{0,-1,1},{0,1,-1},{0,-1,-1})

do
  local function getN(ix, iy, x, y)
    local t = .5 - x * x - y * y
    local index = perms12[ix + perms[iy]]
    return math.max(0, (t*t) * (t*t)) * (grads2[index][0] * x + grads2[index][1] * y)
  end

  function math.pureNoise(x, y)
    local s = (x + y) * 0.366025403
    local ix, iy = math.floor(x + s), math.floor(y + s)
    local t = (ix + iy) * 0.211324865
    local x0 = x + t - ix
    local y0 = y + t - iy
    ix, iy = bit.band(ix, 255), bit.band(iy, 255)
    local n0 = getN(ix, iy, x0, y0)
    local n2 = getN(ix+1, iy+1, x0 - 0.577350270, y0 - 0.577350270)
    local a = bit.rshift(math.floor(y0 - x0), 31)
    local n1 = getN(ix+a, iy+(1-a), x0+0.211324865-a, y0-0.788675135+a)
    return 70 * (n0 + n1 + n2)
  end

  function math.sharpNoise(x, y)
    return 1 - math.abs(love.math.noise(x, y) * 2 - 1)
  end
  function math.sharpSimplexNoise(x, y, octaves, amplitude, gain, frequency, lacunarity, s)
    s = s or 0
    local sum = 0.0
    for i = 0, octaves - 1, 1 do
      sum = sum + math.sharpNoise(x * frequency + s, y * frequency + s) * amplitude
      amplitude = amplitude * gain
      frequency = frequency * lacunarity
    end
    return sum
  end
  function math.simplexNoise(x, y, octaves, amplitude, gain, frequency, lacunarity, s)
    s = s or 0
    local sum = 0.0
    for i = 0, octaves - 1, 1 do
      sum = sum + math.pureNoise(x * frequency + s, y * frequency + s) * amplitude
      amplitude = amplitude * gain
      frequency = frequency * lacunarity
    end
    return sum
  end

  function math.simplex3(octaves, amplitude, gain, frequency, lacunarity, x, y, z)
    local sum = 0
    for i = 1, octaves do
      sum = sum + (love.math.noise(x * frequency, y * frequency, z * frequency) * 2 - 1) * amplitude
      amplitude, frequency = amplitude * gain, frequency * lacunarity
    end
    return sum
  end
end

-- test code
-- local S = math.pureNoise
-- local mmin, mmax = math.min, math.max
-- local fmin, fmax = 10000, -10000
-- local t1 = os.clock()
-- for i=1,5000 do
--   for j=1,5000 do
--     local f = S(i + .5, j + .3)
--     fmin = mmin(fmin, f)
--     fmax = mmax(fmax, f)
--   end
-- end
-- print(string.format("math.pureNoise: time / call = %.9f, min = %f, max = %f",
--       (os.clock() - t1) / (5000 * 5000), fmin, fmax))
