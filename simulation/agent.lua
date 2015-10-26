function agent(p)
  p.maxSize = 64
  p.seed = math.random() * 5436436
  simulation.agents[#simulation.agents + 1] = p
  p.id = #simulation.agents
  p.x, p.y, p.z = 0, 0, 0
  p.rot = 0
  p.cellImage = love.graphics.newImage(love.image.newImageData(p.maxSize, p.maxSize))

  local reshape, newBody, fixture, shape = physics.circle(x, y, 1, 1, "dynamic")
  newBody:setUserData(p)
  newBody:setLinearDamping(5)
  newBody:setBullet(true)
  newBody:setAngularDamping(50)
  newBody:setAngle(math.random() * math.pi * 2)
  p.body = newBody

  -- Stats
  p.name = "" .. p.seed
  p.age = 0
  p.mass = 0
  p.massEaten = 0
  p.points = 0
  p.sellected = false

  local thread = love.thread.newThread("simulation/agent_thread.lua")
  local inputChannel = love.thread.newChannel()
  local outputChannel = love.thread.newChannel()
  thread:start(inputChannel, outputChannel, p.cellImage, {seed = p.seed}, p.body)

  function p.setXYZ(nx, ny, nz)
    p.body:setPosition(nx, ny)
    x, y, z = nx, ny, nz or z
  end
  function p.getXYZ() return x, y, z end

  -- Cell manipulation
  function p.setCell(x, y, v)
    inputChannel:push({func = "set", x = p.x, y = p.y, v = v})
  end

  function p.bite(wx, wy, r, biter)
    local dx, dy = p.x - wx, p.y - wy
    local an = math.atan2(dy, dx) - p.body:getAngle() - math.pi
    local rad = math.sqrt(dx * dx + dy * dy)
    p.body:setUserData(p)
    inputChannel:push({func = "bite", x = math.cos(an) * rad + p.maxSize * 0.5, y = math.sin(an) * rad + p.maxSize * 0.5, r = r, id = p.id})
  end

  function p.feed(cellMass)
    inputChannel:push({func = "feed", cellMass = cellMass})
  end

  function p.update(dt)
    if p.body and not p.body:isDestroyed() then
      inputChannel:push("think")

      p.cellImage:refresh()

      p.age = p.age + dt

      repeat
        local msg = outputChannel:pop()
        if msg then
          if msg.func == "feed" then
            if simulation.agents[msg.id] then
              simulation.agents[msg.id].feed(msg.removedMass or 0)
            end
          else
            p.mass = msg.cellCount
            p.massEaten = msg.massEaten
            p.points = msg.massEaten / math.max(p.age, 3)

            local avgX, avgY = msg.massX / msg.cellCount, msg.massY / msg.cellCount
            fixture, shape = reshape(avgX - p.maxSize * 0.5, avgY - p.maxSize * 0.5, math.max(math.sqrt(msg.cellCount) * 0.8, 1))
            p.body:setBullet(true)
            p.body:applyForce(msg.forX, msg.forY)

            p.x, p.y = p.body:getPosition()
            p.rot = p.body:getAngle()
          end
        end
      until not msg

      -- Kill yourself if you suck ass at growing
      -- if p.age > 1 and p.mass <= 5 then p.remove() end

      if p.age > 0.5 and p.mass <= 0 then p.remove() return end
    end
  end

  function p.postSolve(b, coll, normalimpulse1, tangentimpulse1, normalimpulse2, tangentimpulse2)
    if b:getUserData() then
        if b and not b:isDestroyed() and b:getUserData() and not coll:isDestroyed() then
          local x1, y1, x2, y2 = coll:getPositions()
          b:getUserData().bite(x1, y1, 5, p.body)
        end
    else
      -- Spin around when you hit a wall
      p.body:applyAngularImpulse(1000 * p.body:getMass() * (math.random() < 0.5 and -1 or 1))
    end
  end

  local ringAlpha = 0

  function p.draw()
    if hoverAgent == p or p.sellected or simulation.sortedAgents[1] == p then
      ringAlpha = math.min(ringAlpha + love.timer.getDelta() * 250, 50)
    else
      ringAlpha = math.max(ringAlpha - love.timer.getDelta() * 250, 0)
    end
    if ringAlpha > 0 then
      love.graphics.setColor(255, 255, 255, ringAlpha)

      if p.body and not p.body:isDestroyed() then
        love.graphics.push()
        love.graphics.translate(p.body:getPosition())
        love.graphics.rotate(p.body:getAngle())

        local fixtures = p.body:getFixtureList()
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

    love.graphics.draw(p.cellImage, p.x, p.y, p.rot, 1, 1, p.cellImage:getWidth() * 0.5, p.cellImage:getHeight() * 0.5)
  end

  function p.remove()
    inputChannel:push("die")
    thread:wait()
    p.body:destroy()
    p.body = nil
    -- thread:kill()
    for _, agent in pairs(simulation.agents) do
      if agent == p then
        simulation.agents[_] = nil
      end
    end
  end

  return p
end
