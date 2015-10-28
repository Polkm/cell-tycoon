require("love.timer")
require("love.graphics")
require("love.image")
require("love.math")
require("love.physics")
require("love.filesystem")

require("core/lua_extended")
require("core/love_extended")
require("core/cache")
require("core/noise")

require("core/data_structures")

console = ""
language = "en"

function print(str) console = console .. tostring(str) end
function println(str) print(str) print("\n") end

function command(str) print(">") println(str) return loadstring("return " .. str)() end

function translate(english) return cache.get.code("core/translations")[language][english] end

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

function istable(x) return type(x) == "table" end

function encode(tbl)
  local str = "{"
  for key, value in pairs(tbl) do
    local vstr = type(value) == "table" and encode(value) or tolua(value)
    local kstr = type(key) == "table" and encode(key) or tolua(key)
    str = str .. "[" .. kstr .. "]=" .. vstr .. ","
  end
  return str .. "}"
end
function dencode(str)
  -- TODO
end
