local maxSize = 64
love.graphics.setDefaultFilter("nearest")
love.physics.setMeter(32)
local world = love.physics.newWorld(0, 0, true)
function beginContact(a, b, coll)
end
function endContact(a, b, coll)
end
function preSolve(a, b, coll)
end
function postSolve(a, b, coll, normalimpulse1, tangentimpulse1, normalimpulse2, tangentimpulse2)
  if a:getBody():getUserData() then a:getBody():getUserData().postSolve(b:getBody(), coll, normalimpulse1, tangentimpulse1, normalimpulse2, tangentimpulse2) end
  if b:getBody():getUserData() then b:getBody():getUserData().postSolve(a:getBody(), coll, normalimpulse1, tangentimpulse1, normalimpulse2, tangentimpulse2) end
end
world:setCallbacks(beginContact, endContact, preSolve, postSolve)
local function rect(x, y, w, h, type)
  return love.physics.newFixture(love.physics.newBody(world, x, y, type or "dynamic"), love.physics.newRectangleShape(0, 0, w, h)):getBody()
end
local function circ(x, y, w, h, type)
  local body = love.physics.newBody(world, x, y, type or "dynamic")
  local fixture
  local function reshape(px, py, r)
    if fixture and not fixture:isDestroyed() then fixture:destroy() end
    local shape = love.physics.newCircleShape(clamp(px, -100, 100), clamp(py, -100, 100), math.min(math.max(r, 2), 100))
    fixture = love.physics.newFixture(body, shape)
    fixture:setCategory(1)
    fixture:setFriction(0)
    return fixture, shape
  end
  return reshape, body, reshape(0, 0, math.max(w, h))
end
local levelBounds = 400
local points = {}
for i = 0, math.pi * 2, math.pi * 2 / 30 do
  points[#points + 1] = math.cos(i) * (levelBounds)
  points[#points + 1] = math.sin(i) * (levelBounds)
end
love.physics.newFixture(love.physics.newBody(world, x, y, type or "static"), love.physics.newChainShape(true, points)):getBody()
points = {}
for i = 0, math.pi * 2, math.pi * 2 / 30 do
  points[#points + 1] = math.cos(i) * (levelBounds + 4)
  points[#points + 1] = math.sin(i) * (levelBounds + 4)
end
love.physics.newFixture(love.physics.newBody(world, x, y, type or "static"), love.physics.newChainShape(true, points)):getBody()
points = {}
for i = 0, math.pi * 2, math.pi * 2 / 30 do
  points[#points + 1] = math.cos(i) * (levelBounds + 8)
  points[#points + 1] = math.sin(i) * (levelBounds + 8)
end
love.physics.newFixture(love.physics.newBody(world, x, y, type or "static"), love.physics.newChainShape(true, points)):getBody()
math.randomseed(os.time())
math.random()
math.random()
math.random()


agents = {}
sortedAgents = {}
local camx, camy, camz = 0, 0, 2
local camSpeed = 500
local dragJoint
local hoverAgent

function agent(seed)
  local p = {}
  local cells, cellids = {}, {}
  local cellImage = love.graphics.newImage(love.image.newImageData(maxSize, maxSize))
  local x, y, z = 0, 0, 0
  local reshape, body, fixture, shape = circ(x, y, 1, 1, "dynamic")
  body:setUserData(p)
  body:setLinearDamping(5)
  body:setBullet(true)
  body:setAngularDamping(50)
  body:setAngle(math.random() * math.pi * 2)
  local rot = 0
  local thread = love.thread.newThread("thread.lua")
  local inputChannel = love.thread.newChannel()
  local outputChannel = love.thread.newChannel()
  local info = {
    cellCount = 1,
    massEaten = 0,
  }
  local props = {
    seed = seed,
    -- seedp = seed
    seedp = math.random(),
  }
  local age = 0

  agents[#agents + 1] = p
  local id = #agents


  thread:start(inputChannel, outputChannel, cellImage, props, body)

  inputChannel:push(cells)

  function p.body() return body end

  local sellected = false
  function p.setSellected(sel)
    sellected = sel
    if sellected then
      -- body:setType("static")
      -- fixture:setMask(1, 2, 3, 4)
    else
      -- body:setType("dynamic")
    end
  end
  function p.getSellected()
    return sellected
  end

  function p.setXYZ(nx, ny, nz)
    body:setPosition(nx, ny)
    x, y, z = nx, ny, nz or z
  end
  function p.getXYZ() return x, y, z end
  function p.age() return age end

  function p.setCell(x, y, v)
    inputChannel:push({func = "set", x = x, y = y, v = v})
  end
  function p.bite(wx, wy, r, biter)
    -- inputChannel:push("")
    -- inputChannel:push({func = "set", x = x, y = y, v = nil})
    local dx, dy = x - wx, y - wy
    local an = math.atan2(dy, dx) - body:getAngle() - math.pi
    local rad = math.sqrt(dx * dx + dy * dy) --body:getFixtureList()[1]:getShape():getRadius() * 1.2
    body:setUserData(p)
    inputChannel:push({func = "bite", x = math.cos(an) * rad + maxSize * 0.5, y = math.sin(an) * rad + maxSize * 0.5, r = r, id = id})
  end

  function p.feed(cellMass)
    inputChannel:push({func = "feed", cellMass = cellMass})
    -- assert(false, cellMass)
  end

  function p.getStats()
    return {math.floor(props.seed), math.floor(age or 0), math.floor(info.cellCount or 0), math.floor(math.max(info.massEaten / age, 0))}
  end

  function p.postSolve(b, coll, normalimpulse1, tangentimpulse1, normalimpulse2, tangentimpulse2)
    if b:getUserData() then
      -- async(function()
        if b and not b:isDestroyed() and b:getUserData() and not coll:isDestroyed() then
          local x1, y1, x2, y2 = coll:getPositions()
          local cellMass = 0
          -- body:setUserData(p)
          b:getUserData().bite(x1, y1, 5, body)
        end
      -- end)
    else
      body:applyAngularImpulse(1000 * body:getMass() * (math.random() < 0.5 and -1 or 1))
    end
  end

  function p.update(dt)
    if body and not body:isDestroyed() then
      inputChannel:push("think")

      cellImage:refresh()

      age = age + dt

      local msg = outputChannel:pop()
      while msg do
        if msg.func == "feed" then
          if agents[msg.id] then
            agents[msg.id].feed(msg.removedMass or 0)
          end
        else
          info = msg
          local avgX, avgY = info.massX / info.cellCount, info.massY / info.cellCount
          -- assert(avgX == 0)
          fixture, shape = reshape(avgX - maxSize * 0.5, avgY - maxSize * 0.5, math.max(math.sqrt(info.cellCount) * 0.8, 1))
          body:setBullet(true)
          -- shape:setPoint(avgX, avgY)
          -- p.renderCells(cells)
          body:applyForce(info.forX, info.forY)
          -- local vx, vy = body:getLinearVelocityFromWorldPoint(0, 0)
          -- if math.sqrt(vx * vx + vy * vy) < 50 then
            -- body:applyForce(-info.forX, -info.forY)

          -- end

          x, y = body:getPosition()
          rot = body:getAngle()
        end

        -- outputChannel:clear()
        msg = outputChannel:pop()
      end
      if age > 0.5 and info.cellCount <= 5 then
        p.remove()
      end
    end
  end

  local ringAlpha = 0

  function p.draw()
    if hoverAgent == p or sellected or sortedAgents[1] == p then
      ringAlpha = math.min(ringAlpha + love.timer.getDelta() * 250, 50)
    else
      ringAlpha = math.max(ringAlpha - love.timer.getDelta() * 250, 0)
    end
    if ringAlpha > 0 then
      love.graphics.setColor(255, 255, 255, ringAlpha)

      if body and not body:isDestroyed() then
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
            love.graphics.circle("line", 0, 0, shape:getRadius() * 2, 50)
          end
        end

        love.graphics.pop()
      end
    end
    love.graphics.setColor(255, 255, 255, 255)

    love.graphics.draw(cellImage, x, y, rot, 1, 1, cellImage:getWidth() * 0.5, cellImage:getHeight() * 0.5)
    -- love.graphics.draw(cellImage, x, y, rot, 1, 1, cellImage:getWidth() * 0.5, cellImage:getHeight() * 0.5)
  end

  function p.remove()
    inputChannel:push("die")
    thread:wait()
    body:destroy()
    body = nil
    -- thread:kill()
    for _, agent in pairs(agents) do
      if agent == p then
        agents[_] = nil
      end
    end
  end

  return p
end


local lastClick
function love.mousepressed(x, y, button)
  local mx, my = love.mouse.getWorldPosition()
  if button == "wu" then
    local dz = camz
    camz = math.min(camz + 0.3, 6)
    dz = (camz - dz) / camz
    camx = camx - (camx - mx) * dz
    camy = camy - (camy - my) * dz
  end
  if button == "wd" then
    local dz = camz
    camz = math.max(camz - 0.3, 0.3)
    dz = (camz - dz) / camz
    camx = camx - (camx - mx) * dz
    camy = camy - (camy - my) * dz
  end
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
end

function love.mousereleased(x, y, button)
  if button == "l" then
    if dragJoint and not dragJoint:isDestroyed() then
      dragJoint:destroy()
      dragJoint = nil
    end
  end
end

function love.mousemoved(x, y, dx, dy)
  if love.mouse.isDown("r") then
    camx, camy = camx - dx / camz, camy - dy / camz
  end
end

local lastSpawn

function love.update(dt)
  if love.keyboard.isDown("a") then camx = camx - camSpeed * dt / math.min(camz, 1) end
  if love.keyboard.isDown("d") then camx = camx + camSpeed * dt / math.min(camz, 1) end
  if love.keyboard.isDown("w") then camy = camy - camSpeed * dt / math.min(camz, 1) end
  if love.keyboard.isDown("s") then camy = camy + camSpeed * dt / math.min(camz, 1) end

  if dragJoint and not dragJoint:isDestroyed() then
    local mx, my = love.mouse.getWorldPosition()
    local len = math.sqrt(mx * mx + my * my)
    if len > levelBounds then
      mx, my = mx / len * levelBounds, my / len * levelBounds
    end
    dragJoint:setTarget(mx, my)
  end

  local agentCount = 0
  for _, agent in pairs(agents) do agentCount = agentCount + 1 end
  local n = math.pow(7, 2)
  if (not lastSpawn or lastSpawn + 0 < love.timer.getTime()) and agentCount < n then
    lastSpawn = love.timer.getTime()
    local w = math.floor(math.sqrt(n))
    local ww = w * maxSize * 0.25
    local ag = agent(math.random() * 4375834)
    -- local ag = agent(seeda + love.math.noise(math.floor(i / 10) / 100) * 25235)
    -- local ag = agent(love.math.noise(seeda + math.floor(i / 10)) * 342)
    -- local x, y = (i % w) * (maxSize * 1) - ww, math.floor(i / w) * (maxSize * 1) - ww
    local a, d = math.random() * math.pi * 2, math.random() * (levelBounds * 0.9 - maxSize)
    local x, y = math.cos(a) * d, math.sin(a) * d
    ag.setXYZ(x, y)
  end

  world:update(dt)

  hoverAgent = nil
  local mx, my = love.mouse.getWorldPosition()
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

  for _, agent in pairs(agents) do
    agent.update(dt)
  end

  guisUpdate(dt)
end

function love.mouse.getWorldPosition()
  local mx, my = love.mouse.getPosition()
  local sx, sy = love.graphics.getWidth() * 0.5, love.graphics.getHeight() * 0.5
  return (mx - sx) / camz + camx, (my - sy) / camz + camy
end

local grad = love.graphics.newShader("grad.frag")
local pixelImg = love.graphics.newImage(love.image.newImageData(1, 1))

function love.draw()
  love.graphics.setLineWidth(0.1 * camz)
  local scrX, scrY = love.graphics.getDimensions()
  local minX = math.min(-levelBounds + (scrX / camz * 0.5), 0)
  local maxX = math.max(levelBounds - (scrX / camz * 0.5), 0)
  local minY = math.min(-levelBounds + (scrY / camz * 0.5), 0)
  local maxY = math.max(levelBounds - (scrY / camz * 0.5), 0)
  camx = math.min(math.max(camx, minX), maxX)
  camy = math.min(math.max(camy, minY), maxY)


  love.graphics.setShader(grad)
  grad:send("screen", {love.graphics.getDimensions()})
  local center = {love.graphics.getWidth() * 0.5 - camx * camz, love.graphics.getHeight() * 0.5 - camy * camz}
  grad:send("center", center)
  grad:send("radius", levelBounds)
  grad:send("zoom", camz)
  grad:send("rt", love.timer.getTime())
  love.graphics.draw(pixelImg, 0, 0, 0, scrX, scrY)
  -- love.graphics.rectangle("fill", 0, 0, scrX, scrY)
  love.graphics.setShader()

  if not love.keyboard.isDown("`") then
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.setInvertedStencil(function()
      love.graphics.push()
      love.graphics.clear()
      love.graphics.translate(love.graphics.getWidth() * 0.5, love.graphics.getHeight() * 0.5)
      love.graphics.scale(camz, camz)
      love.graphics.translate(-camx, -camy)
      love.graphics.circle("fill", 0, 0, levelBounds, 100)
      love.graphics.pop()
    end)

    local agentCount = 0
    local firstAgent
    local columnWidths = {}
    local statsToNames = {"name", "age", "mass", "points"}
    sortedAgents = {}
    for _, agent in pairs(agents) do
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
      sortedAgents[#sortedAgents + 1] = agent
    end
    for ii, stat in pairs(firstAgent.getStats()) do
      local width = love.graphics.getFont():getWidth(translate(statsToNames[ii]))
      if not columnWidths[ii] or columnWidths[ii] < width then
        columnWidths[ii] = width
      end
    end
    local bufferY = 50
    local lineHeight = 18 --math.min((love.graphics.getHeight() - bufferY * 2) / (7*7), 16)
    love.graphics.setFont(cache.get.font("boku2.otf", lineHeight))
    local sortStat = 4
    table.sort(sortedAgents, function(a, b)
      local aStats = a.getStats()
      local bStats = b.getStats()
      return (aStats[sortStat] or 0) > (bStats[sortStat] or 0)
    end)
    if firstAgent then
      local x = scrX - 300
      love.graphics.setColor(180, 180, 180, 255)
      for ii, stat in pairs(firstAgent.getStats()) do
        gui(x, bufferY, translate(statsToNames[ii]))
        x = x + columnWidths[ii] + 10
      end
      for _, agent in pairs(agents) do
        local c = 1
        for i, check in pairs(sortedAgents) do
          if agent == check then break end
          c = c + 1
        end
        x = scrX - 300
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
  end



  love.graphics.push()
  love.graphics.translate(love.graphics.getWidth() * 0.5, love.graphics.getHeight() * 0.5)
  love.graphics.scale(camz, camz)
  love.graphics.translate(-camx, -camy)

  love.graphics.setStencil(function()
    love.graphics.circle("fill", 0, 0, levelBounds, 100)
  end)

  love.graphics.setColor(255, 255, 255, 255)
  for _, agent in pairs(agents) do
    agent.draw()
  end

  love.graphics.setStencil(nil)

  love.graphics.setColor(255, 255, 255, 255)
  if love.keyboard.isDown("`") then
    love.graphics.point(love.mouse.getWorldPosition())
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

  love.graphics.setColor(255, 255, 255, 255)
  love.graphics.printf(console, 0, 0, 9999999)
end
