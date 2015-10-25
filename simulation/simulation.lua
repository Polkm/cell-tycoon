require("simulation/camera")
require("simulation/physics")
require("simulation/agent")
require("simulation/dragdrop")
require("simulation/background")

math.randomseed(os.time())
math.random()
math.random()
math.random()

simulation = {}
simulation.agents = {}
simulation.sortedAgents = {}
simulation.size = 400
simulation.agentSize = 64

function love.load()
  local points = {}
  for i = 0, math.pi * 2, math.pi * 2 / 30 do
    points[#points + 1] = math.cos(i) * (simulation.size)
    points[#points + 1] = math.sin(i) * (simulation.size)
  end
  love.physics.newFixture(love.physics.newBody(world, x, y, type or "static"), love.physics.newChainShape(true, points)):getBody()
  points = {}
  for i = 0, math.pi * 2, math.pi * 2 / 30 do
    points[#points + 1] = math.cos(i) * (simulation.size + 4)
    points[#points + 1] = math.sin(i) * (simulation.size + 4)
  end
  love.physics.newFixture(love.physics.newBody(world, x, y, type or "static"), love.physics.newChainShape(true, points)):getBody()
  points = {}
  for i = 0, math.pi * 2, math.pi * 2 / 30 do
    points[#points + 1] = math.cos(i) * (simulation.size + 8)
    points[#points + 1] = math.sin(i) * (simulation.size + 8)
  end
  love.physics.newFixture(love.physics.newBody(world, x, y, type or "static"), love.physics.newChainShape(true, points)):getBody()
end

local lastSpawn
hook(love, "update", function(dt)
  local agentCount = 0
  for _, agent in pairs(simulation.agents) do agentCount = agentCount + 1 end
  local n = math.pow(7, 2)
  if (not lastSpawn or lastSpawn + 0 < love.timer.getTime()) and agentCount < n then
    lastSpawn = love.timer.getTime()
    local w = math.floor(math.sqrt(n))
    local ww = w * simulation.agentSize * 0.25
    local ag = agent(simulation.agentSize, math.random() * 4375834)
    -- local ag = agent(seeda + love.math.noise(math.floor(i / 10) / 100) * 25235)
    -- local ag = agent(love.math.noise(seeda + math.floor(i / 10)) * 342)
    -- local x, y = (i % w) * (simulation.agentSize * 1) - ww, math.floor(i / w) * (simulation.agentSize * 1) - ww
    local a, d = math.random() * math.pi * 2, math.random() * (simulation.size * 0.9 - simulation.agentSize)
    local x, y = math.cos(a) * d, math.sin(a) * d
    ag.setXYZ(x, y)
  end

  world:update(dt)

  for _, agent in pairs(simulation.agents) do
    agent.update(dt)
  end

  guisUpdate(dt)
end)

function love.draw()
  local screenW, screenY = love.graphics.getDimensions()

  love.graphics.setLineWidth(0.1 * camera.z)

  background.draw()

  love.graphics.setColor(255, 255, 255, 255)
  love.graphics.setInvertedStencil(function()
    love.graphics.push()
    love.graphics.clear()
    love.graphics.translate(love.graphics.getWidth() * 0.5, love.graphics.getHeight() * 0.5)
    love.graphics.scale(camera.z, camera.z)
    love.graphics.translate(-camera.x, -camera.y)
    love.graphics.circle("fill", 0, 0, simulation.size, 100)
    love.graphics.pop()
  end)

  local agentCount = 0
  local firstAgent
  local columnWidths = {}
  local statsToNames = {"name", "age", "mass", "points"}
  simulation.sortedAgents = {}
  for _, agent in pairs(simulation.agents) do
    if not firstAgent then
      firstAgent = agent
    end
    for ii, stat in pairs(firstAgent.getStats()) do
      local width = love.graphics.getFont():getWidth(agent.getStats()[ii])
      if not columnWidths[ii] or columnWidths[ii] < width then
        columnWidths[ii] = width
      end
    end
    agentCount = agentCount + 1
    simulation.sortedAgents[#simulation.sortedAgents + 1] = agent
  end
  for ii, stat in pairs(firstAgent.getStats()) do
    local width = love.graphics.getFont():getWidth(translate(statsToNames[ii]))
    if not columnWidths[ii] or columnWidths[ii] < width then
      columnWidths[ii] = width
    end
  end
  local bufferY = 50
  local lineHeight = 18 --math.min((love.graphics.getHeight() - bufferY * 2) / (7*7), 16)
  love.graphics.setFont(cache.get.font("fonts/boku2.otf", lineHeight))
  local sortStat = 4
  table.sort(simulation.sortedAgents, function(a, b)
    local aStats = a.getStats()
    local bStats = b.getStats()
    return (aStats[sortStat] or 0) > (bStats[sortStat] or 0)
  end)
  if firstAgent then
    local x = screenW - 300
    love.graphics.setColor(180, 180, 180, 255)
    for ii, stat in pairs(firstAgent.getStats()) do
      gui(x, bufferY, translate(statsToNames[ii]))
      x = x + columnWidths[ii] + 10
    end
    for _, agent in pairs(simulation.agents) do
      local c = 1
      for i, check in pairs(simulation.sortedAgents) do
        if agent == check then break end
        c = c + 1
      end
      x = screenW - 300
      for ii, stat in pairs(firstAgent.getStats()) do
        if hoverAgent == agent then
          love.graphics.setColor(255, 255, 255, 255)
        elseif agent.getSellected() then
          love.graphics.setColor(230, 230, 230, 255)
        else
          love.graphics.setColor(180, 180, 180, 255)
        end
        gui(x, bufferY + c * lineHeight, (agent.getStats())[ii])
        x = x + columnWidths[ii] + 10
      end
    end
  end

  guisDraw()

  love.graphics.setInvertedStencil(nil)



  love.graphics.push()
  love.graphics.translate(love.graphics.getWidth() * 0.5, love.graphics.getHeight() * 0.5)
  love.graphics.scale(camera.z, camera.z)
  love.graphics.translate(-camera.x, -camera.y)

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
  love.graphics.printf(console, 0, 0, 9999999)
end
