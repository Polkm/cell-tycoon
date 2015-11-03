require("core/global")
require("simulation/culture")

local p = {}
p.inputChannel, p.outputChannel = ...
p.cultures = {}

function p.update(dt)
  for _, cult in pairs(p.cultures) do cult.update(dt) end
end

local alive = true
while alive do
  local inputs = {}
  repeat
    local input = p.inputChannel:pop()
    if input then
      inputs[#inputs + 1] = input
    end
  until not input

  for i = #inputs, 1, -1 do
    local input = inputs[i]
    local func = input.func
    local id = input.id
    input.func = nil
    input.id = nil
    if id and func then
      if not p.cultures[id] then p.cultures[id] = culture({}, p, id) end
      p.cultures[id][func](unpack(input))
    elseif func then
      p[func](unpack(input))
    end
  end

  -- assert(table.count(p.cultures) < 15)
end
