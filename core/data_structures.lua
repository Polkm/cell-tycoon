-- Quasi-experimental data structures

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
