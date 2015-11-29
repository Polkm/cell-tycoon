simulation = {}
simulation.agents = {}
simulation.sortedAgents = {}
simulation.size = 50
simulation.agentSize = 16

require("simulation/camera")
require("simulation/physics")
require("simulation/gui")
require("simulation/agent")
require("simulation/dragdrop")
require("simulation/background")
require("simulation/scoreboard")
require("simulation/foreman")
require("simulation/tracking")
require("simulation/disposable/panel")

math.randomseed(5000)
math.random()
math.random()
math.random()

hook(love, "load", function()
  for j = 0, 3 do
    local points = {}
    for i = 0, math.pi * 2, math.pi * 2 / 30 do
      points[#points + 1] = math.cos(i) * (simulation.size + j * 4)
      points[#points + 1] = math.sin(i) * (simulation.size + j * 4)
    end
    love.physics.newFixture(love.physics.newBody(world, x, y, type or "static"), love.physics.newChainShape(true, points)):getBody()
  end

  local pos = {}
  local count = 0
  while count < simulation.agentSize do

  local x,y = math.randomDiscXY(0, 0, simulation.size * 0.9)
  local canAdd = true
  for _,coord in pairs(pos) do
    if dist(coord[1], coord[2], x, y) < 0.01 then
      canAdd = false
    end
  end
  if canAdd then
    pos[count] = {x,y}
    count = count + 1
  end

  end


  local i = 0
  for _,coord in pairs(pos) do
    local x, y = coord[1], coord[2]
    agent({}).setXYZ(x,y,0)
    i = i + 1
  end


end)

local lastSpawn
hook(love, "update", function(dt)
  world:update(dt)

  for _, agent in pairs(simulation.agents) do
    agent.update(dt)
  end

  gui.update(dt)
end)

function love.draw()
  local screenW, screenY = love.graphics.getDimensions()

  love.graphics.setLineWidth(0.1 * camera.z)

  background.draw()

  love.graphics.push()
  love.graphics.translate(love.graphics.getWidth() * 0.5, love.graphics.getHeight() * 0.5)
  love.graphics.scale(camera.z, camera.z)
  love.graphics.translate(-camera.x, -camera.y)

  gui.draw()
  panel.draw()

  love.graphics.setStencil(function()
    love.graphics.circle("fill", 0, 0, simulation.size, 100)
  end)

  love.graphics.setColor(255, 255, 255, 255)
  for _, agent in pairs(simulation.agents) do
    agent.draw()
  end

  love.graphics.setStencil(nil)

  -- Debug drawing
  love.graphics.setColor(255, 255, 255, 255)
  if love.keyboard.isDown("`") then
    love.graphics.point(camera.getMouseWorldPosition())
    for _, body in pairs(world:getBodyList()) do
      if not body:isDestroyed() then
        love.graphics.push()
        love.graphics.translate(body:getPosition())
        love.graphics.rotate(body:getAngle())

        local fixtures = body:getFixtureList()
        for _, fixture in pairs(fixtures) do
          local shape = fixture:getShape()
          if shape.getPoints then
            love.graphics.polygon("line", shape:getPoints())
          else
            love.graphics.translate(shape:getPoint())
            love.graphics.circle("line", 0, 0, shape:getRadius())
          end
        end

        love.graphics.pop()
      end
    end
  end

  love.graphics.pop()

  -- Finaly top left console
  love.graphics.setColor(255, 255, 255, 255)
  local display = ""
  display = display .. love.timer.getFPS() .. "\n"
  love.graphics.setFont(cache.get.font("fonts/boku2.otf", 12))
  love.graphics.printf(display .. console, 0, 0, 9999999)
end
