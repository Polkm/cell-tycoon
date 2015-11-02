gui = {}

local guis = {}

local function base(p)
  table.insert(guis, p)

  function p.update(dt) end

  function p.draw() end

  function p.remove()
    for k, g in pairs(guis) do
      if g == p then guis[k] = nil end
    end
  end

  return p
end

function gui.label(p)
  p = base(p)

  p.text = p.text or ""
  p.font = p.font or "fonts/boku2.otf"
  p.x, p.y = p.x or 0, p.y or 0
  p.r, p.g, p.b, p.a = p.r or 255, p.g or 255, p.b or 255, p.a or 255

  local superSize = 50
  local ratio = 10 / superSize
  local function font() return cache.get.font(p.font, superSize) end

  function p.draw()
    love.graphics.push()
    love.graphics.scale(ratio, ratio)
    love.graphics.translate(p.x / ratio, p.y / ratio)
    love.graphics.setFont(font())
    love.graphics.setColor(p.r * 0.1, p.g * 0.1, p.b * 0.1, p.a * 0.5)
    love.graphics.printf(p.text, 1, 2, 9999999)
    love.graphics.setColor(p.r, p.g, p.b, p.a)
    love.graphics.printf(p.text, 0, 0, 9999999)
    love.graphics.pop()
  end

  function p.getHeight()
    return font():getHeight() * ratio
  end

  function p.getWidth()
    return font():getWidth(p.text) * ratio
  end

  return p
end

function gui.list(p)
  p = base(p)

  p.list = p.list or {}
  p.child = p.child or gui.label
  if p.vertical == nil then p.vertical = true end
  p.children = p.children or {}
  p.x, p.y = p.x or 0, p.y or 0
  p.padding = p.padding or 0

  function p.update(dt)
    -- Remove children that are no longer in the list
    for k, child in pairs(p.children) do
      if not table.contains(p.list, k) then
        child.remove()
        p.children[k] = nil
      end
    end

    -- Create children that are on the list but don't exist
    for _, elm in pairs(p.list) do
      if not p.children[elm] then
        p.children[elm] = p.child(elm)
      end
    end

    p.layout(0, 0)
  end

  -- Position the children
  function p.layout(x, y)
    local ox, oy = x + p.x, y + p.y
    for i, elm in ipairs(p.list) do
      local child = p.children[elm]
      if child then
        if p.vertical then
          child.x = ox
          child.y = oy
          oy = oy + child.getHeight() + p.padding
        else
          child.x = ox
          child.y = oy
          ox = ox + child.getWidth() + p.padding
        end
      end
    end
  end

  function p.getHeight()
    return 0
  end

  function p.getWidth()
    local maxWidth

    for _, child in pairs(p.children) do
      local width = child.getWidth()
      if not maxWidth or maxWidth < width then
        maxWidth = width
      end
    end

    return maxWidth or 0
  end

  hook(p, "remove", function()
    for _, child in pairs(p.children) do
      child.remove()
    end
  end)

  return p
end

function gui.column(p)
  p = gui.list(p)

  p.title = gui.label({text = p.text or ""})

  hook(p, "update", function(dt)
    p.title.x = p.x
    p.title.y = p.y

    p.layout(0, p.title.getHeight())
  end)

  local oldWidth = p.getWidth
  function p.getWidth()
    local maxWidth = oldWidth()
    local width = p.title.getWidth()
    if not maxWidth or maxWidth < width then maxWidth = width end
    return maxWidth
  end

  return p
end

function gui.update(dt)
  for _, g in pairs(guis) do g.update(dt) end
end

function gui.draw()
  for _, g in pairs(guis) do g.draw() end
end



-- Bellow is crazy shit that needs to be rewritten in a good way
--
-- local guis = {}
--
-- local function newGUI(x, y, text)
--   local p = {}
--   local r, g, b, a = 255, 255, 255, 255
--   function p.update(nx, ny, ntext)
--     local dt = delta()
--     x, y, text = lerp(x, nx, 0.9), lerp(y, ny, 0.9), ntext
--     local nr, ng, nb, na = love.graphics.getColor()
--     r, g, b, a = lerp(r, nr, dt * 10), lerp(g, ng, dt * 10), lerp(b, nb, dt * 10), lerp(a, na, dt * 10)
--   end
--   function p.draw()
--     love.graphics.setColor(r * 0.1, g * 0.1, b * 0.1, a * 0.5)
--     love.graphics.printf(text, x + 1, y + 2, 9999999)
--     love.graphics.setColor(r, g, b, a)
--     love.graphics.printf(text, x, y, 9999999)
--   end
--   function p.remove()
--     for i, ui in pairs(guis) do if p == ui then guis[i] = nil end end
--   end
--   table.insert(guis, p)
--   return p
-- end
--
-- local guiCount = 0
--
-- function gui(x, y, text)
--   local ui = guis[guiCount + 1]
--   if not ui then
--     guis[guiCount + 1] = newGUI(x, y, text)
--   else
--     ui.update(x, y, text)
--   end
--
--   guiCount = guiCount + 1
-- end
--
-- function guisUpdate(dt)
--
-- end
--
-- function guisDraw()
--   for _, ui in pairs(guis) do
--     ui.draw()
--   end
--   guiCount = 0
-- end
