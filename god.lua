require("cache")
require("bind")
require("noise")

console = ""
function print(str) console = console .. tostring(str) end
function println(str) print(str) print("\n") end
function command(str) print(">") println(str) return loadstring("return " .. str)() end
language = "jap"
function translate(english) return cache.get.code("lang")[language][english] end
function time() return love.timer.getTime() end
function delta() return love.timer.getDelta() end
function clamp(v, l, h) return math.min(math.max(v, l), h) end
function lerp(a, b, d) return a + (b - a) * clamp(d, 0, 1) end
function lerp3(ax, ay, az, bx, by, bz, d) return lerp(a, b, d), lerp(a, b, d), lerp(a, b, d) end
function hook(tbl, key, fnc)
  local old = tbl[key]
  tbl[key] = function(...)
    local result = old(...)
    fnc(...)
    return result
  end
end
local oldToString = tostring
function tostring(any)
  if type(any) == "table" and type(any.str) == "function" then return any.str() end
  return oldToString(any)
end
function tolua(x)
  if type(x) == "table" and type(x.lua) == "function" then return x.lua() end
  if type(x) == "string" then return "\"" .. tostring(x) .. "\"" end
  return tostring(x)
end
function encode(tbl)
  local str = "{"
  for key, value in pairs(tbl) do
    local vstr = type(value) == "table" and encode(value) or tolua(value)
    local kstr = type(key) == "table" and encode(key) or tolua(key)
    str = str .. "[" .. kstr .. "]=" .. vstr .. ","
  end
  return str .. "}"
end

do
  local p = {}
  function p.set(s) return setmetatable({}, {__index = function(t, k)

  end }) end
  function p.remove(s) return function()
    -- assert(false)
  end end
  function p.clone(s) return function()
    return setmetatable({}, {__index = function(t, k) return p[k](t) end})
  end end
  function p.meta(s) return function() return p end end
  function object() return p.clone()() end
end

do
  local p = object().meta()
  function p.spawn(s) return function()
    -- assert(false)
    return s
  end end
  function entity() return p.clone()() end
end

local a = entity().spawn()





local guis = {}

local function newGUI(x, y, text)
  local p = {}
  local r, g, b, a = 255, 255, 255, 255
  function p.update(nx, ny, ntext)
    local dt = delta()
    x, y, text = lerp(x, nx, 0.9), lerp(y, ny, 0.9), ntext
    -- x, y, text = lerp(x, nx, dt * 20), lerp(y, ny, dt * 20), ntext
    local nr, ng, nb, na = love.graphics.getColor()
    r, g, b, a = lerp(r, nr, dt * 10), lerp(g, ng, dt * 10), lerp(b, nb, dt * 10), lerp(a, na, dt * 10)
  end
  function p.draw()
    love.graphics.setColor(r * 0.1, g * 0.1, b * 0.1, a * 0.5)
    love.graphics.printf(text, x + 1, y + 2, 9999999)
    love.graphics.setColor(r, g, b, a)
    love.graphics.printf(text, x, y, 9999999)
  end
  function p.remove()
    for i, ui in pairs(guis) do if p == ui then guis[i] = nil end end
  end
  table.insert(guis, p)
  return p
end

local guiCount = 0

-- I need "age", "name", "kills", "deaths", "points"

function gui(x, y, text)
  local ui = guis[guiCount + 1]
  if not ui then
    guis[guiCount + 1] = newGUI(x, y, text)
  else
    ui.update(x, y, text)
  end

  guiCount = guiCount + 1
end

function guisUpdate(dt)

end

function guisDraw()
  for _, ui in pairs(guis) do
    ui.draw()
  end
  guiCount = 0
end

do
  local p = setmetatable({}, {__index = function() return function() end end})
  local meta = {__index = p}
  function p.str() return "struct()" end
  function p.lua() return "struct()" end
  function p.clone() return struct() end
  function struct() return setmetatable({}, meta) end
end

function list(...)
  local p, d = struct(), {...}
  function p.tbl() return d end
  function p.clear() d = {} end
  function p.empty() return p.count() <= 0 end
  function p.set(k, v) d[k] = v end
  function p.get(k) return d[k] end
  function p.add(v) table.insert(d, v) return p end
  function p.insert(i, v) table.insert(d, i, v) return p end
  function p.remove(k) return table.remove(d, k) end
  function p.fill(n, f) for i = 1, n do p.add(f()) end return p end
  function p.all(f) for k, v in pairs(d) do f(k, v) end end
  function p.allall(f) p.all(function(k, v) c.all(function(l, b) f(k, v, l, b) end) end) end
  function p.expel(x) p.all(function(k, v) if x == v then p.set(k, nil) end end) end
  function p.fold(s, f) p.all(function(k, v) s = f(s, k, v) or s end) return s end
  function p.concat(sep) sep = sep or "" return p.fold("", function(s, k, v) return s .. (k ~= 1 and sep or "") .. tostring(v) end) end
  -- function p.count() return p.fold(0, function(s, k, v) return s + 1 end) end
  function p.count() local c = 0 for _,_ in pairs(d) do c = c + 1 end return c end
  function p.getn() return table.getn(d) end
  function p.map(f) return p.fold(list(), function(s, k, v) s.add(f(k, v)) end) end
  function p.union(b) return b.fold(list(unpack(d)), function(s, k, v) s.add(v) end) end
  function p.sort(f) table.sort(d, f) return p end
  function p.unpack() return unpack(p.tbl()) end
  function p.random()
    local k, v = table.random(p.tbl())
    return v
  end
  function p.str() return p.fold("list( ", function(s, k, v) return s .. tostring(k) .. ":" .. tostring(v) .. " " end) .. ")" end
  function p.lua() return p.fold("list(", function(s, k, v) return s .. (k ~= 1 and "," or "") .. tolua(v) end) .. ")" end
  function p.clone(recursive)
    return p.fold(list(), function(s, k, v)
      if recursive and type(v) == "table" and type(v.clone) == "function" then
        s.add(v.clone())
      else
        s.add(v)
      end
    end)
  end
  function p.default(default)
    local mt = getmetatable(p)
    mt.__index = function(t, k)
      if p.get(k) == nil then p.set(k, default()) end
      return p.get(k)
    end,
    setmetatable(p, mt)
    return p
  end
  function p.contains(value)
    for k, v in pairs(d) do if v == value then return true end end
    return false
  end
  -- function p.random()
  --   local V = {}
  --   for _, v in pairs(d) do V[#V + 1] = v end
  --   return V[math.random()]
  -- end
  return setmetatable(p, {
    __index = function(t, k) return p.get(k) end,
    __newindex = function(t, k, v) return p.set(k, v) end,
    __add = function(a, b) return a.union(b) end,
    __concat = function(a, b) return tostring(a) .. tostring(b) end,
  })
end

function map(t)
  local p = list()
  function p.union(b) return b.fold(p.clone(), function(s, k, v) s[k] = v end) end
  function p.map(f) return p.fold(map(), function(s, k, v) s.set(k, f(k, v)) end) end
  function p.clone(recursive)
    return p.fold(map(), function(s, k, v)
      if recursive and type(v) == "table" and type(v.clone) == "function" then
        s.set(k, v.clone())
      else
        s.set(k, v)
      end
    end)
  end
  function p.str() return p.fold("map( ", function(s, k, v) return s .. tostring(k) .. ":" .. tostring(v) .. " " end) .. ")" end
  function p.lua() return p.fold("map({", function(s, k, v) return s .. "[" .. tolua(k) .. "]=" .. tolua(v) .. "," end) .. "})" end
  for k, v in pairs(t or {}) do p.set(k, v) end
  return p
end
