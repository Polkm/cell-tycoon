local dragJoint
local hoverAgent

hook(love, "update", function(dt)
  if dragJoint and not dragJoint:isDestroyed() then
    local mx, my = camera.getMouseWorldPosition()
    local len = math.sqrt(mx * mx + my * my)
    if len > simulation.size then
      mx, my = mx / len * simulation.size, my / len * simulation.size
    end
    dragJoint:setTarget(mx, my)
  end

  hoverAgent = nil
  local mx, my = camera.getMouseWorldPosition()
  local closest
  world:queryBoundingBox(mx - 5, my - 5, mx + 5, my + 5, function(fixture)
    local bx, by = fixture:getBody():getPosition()
    local dx, dy = mx - bx, my - by
    local dist = math.sqrt(dx * dx + dy * dy)
    if not closest or closest > dist then
      closest = dist
      hoverAgent = fixture:getBody():getUserData()
    end
    return true
  end)
  if hoverAgent then
    love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
  else
    love.mouse.setCursor()
  end
end)

local lastClick
hook(love, "mousepressed", function(x, y, button)
  local mx, my = camera.getMouseWorldPosition()
  if button == "l" then
    if hoverAgent then
      if lastClick and lastClick + 0.2 > love.timer.getTime() then
        hoverAgent.bite(mx, my, 5, nil)
      else
        if dragJoint and not dragJoint:isDestroyed() then
          dragJoint:destroy()
          dragJoint = nil
        end
        dragJoint = love.physics.newMouseJoint(hoverAgent.body(), mx, my)
      end
    end
    lastClick = love.timer.getTime()
  end
  if button == "r" then
    if hoverAgent then
      hoverAgent.setSellected(not hoverAgent.getSellected())
    end
  end
end)

hook(love, "mousereleased", function(x, y, button)
  if button == "l" then
    if dragJoint and not dragJoint:isDestroyed() then
      dragJoint:destroy()
      dragJoint = nil
    end
  end
end)
