-- Bellow is crazy shit that needs to be rewritten in a good way

local guis = {}

local function newGUI(x, y, text)
  local p = {}
  local r, g, b, a = 255, 255, 255, 255
  function p.update(nx, ny, ntext)
    local dt = delta()
    x, y, text = lerp(x, nx, 0.9), lerp(y, ny, 0.9), ntext
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
