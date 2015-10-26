camera = {}

camera.x, camera.y, camera.z = 0, 0, 2
camera.speed = 500

local targetZ = camera.z

hook(love, "update", function(dt)
  if love.keyboard.isDown("a") then camera.x = camera.x - camera.speed * dt / math.min(camera.z, 1) end
  if love.keyboard.isDown("d") then camera.x = camera.x + camera.speed * dt / math.min(camera.z, 1) end
  if love.keyboard.isDown("w") then camera.y = camera.y - camera.speed * dt / math.min(camera.z, 1) end
  if love.keyboard.isDown("s") then camera.y = camera.y + camera.speed * dt / math.min(camera.z, 1) end

  -- local scrX, scrY = love.graphics.getDimensions()
  -- local minX = math.min(-simulation.size + (scrX / camera.z * 0.5), 0)
  -- local maxX = math.max(simulation.size - (scrX / camera.z * 0.5), 0)
  -- local minY = math.min(-simulation.size + (scrY / camera.z * 0.5), 0)
  -- local maxY = math.max(simulation.size - (scrY / camera.z * 0.5), 0)
  -- camera.x = math.min(math.max(camera.x, minX), maxX)
  -- camera.y = math.min(math.max(camera.y, minY), maxY)

  local mx, my = camera.getMouseWorldPosition()
  local dz = camera.z
  camera.z = lerp(camera.z, targetZ, 0.2)
  dz = (camera.z - dz) / camera.z
  camera.x = camera.x - (camera.x - mx) * dz
  camera.y = camera.y - (camera.y - my) * dz
end)

hook(love, "mousepressed", function(x, y, button)
  if button == "wu" then
    targetZ = math.min(camera.z + 0.3, 6)
  end
  if button == "wd" then
    targetZ = math.max(camera.z - 0.3, 0.3)
  end
end)

hook(love, "mousemoved", function(x, y, dx, dy)
  if love.mouse.isDown("r") then
    camera.x, camera.y = camera.x - dx / camera.z, camera.y - dy / camera.z
  end
end)

function camera.getMouseWorldPosition()
  local mx, my = love.mouse.getPosition()
  local sx, sy = love.graphics.getWidth() * 0.5, love.graphics.getHeight() * 0.5
  return (mx - sx) / camera.z + camera.x, (my - sy) / camera.z + camera.y
end
