function agent(size, seed)
  local p = {}
  local cells, cellids = {}, {}
  local cellImage = love.graphics.newImage(love.image.newImageData(size, size))
  local x, y, z = 0, 0, 0
  local reshape, body, fixture, shape = physics.circle(x, y, 1, 1, "dynamic")
  body:setUserData(p)
  body:setLinearDamping(5)
  body:setBullet(true)
  body:setAngularDamping(50)
  body:setAngle(math.random() * math.pi * 2)
  local rot = 0
  local thread = love.thread.newThread("simulation/agent_thread.lua")
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

  p.name = "" .. seed
  p.age = 0
  p.mass = 0
  p.points = 0

  simulation.agents[#simulation.agents + 1] = p
  local id = #simulation.agents


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
    inputChannel:push({func = "bite", x = math.cos(an) * rad + size * 0.5, y = math.sin(an) * rad + size * 0.5, r = r, id = id})
  end

  function p.feed(cellMass)
    inputChannel:push({func = "feed", cellMass = cellMass})
    -- assert(false, cellMass)
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

      p.age = p.age + dt

      local msg = outputChannel:pop()
      while msg do
        if msg.func == "feed" then
          if simulation.agents[msg.id] then
            simulation.agents[msg.id].feed(msg.removedMass or 0)
          end
        else
          info = msg
          p.mass = info.cellCount
          p.points = info.massEaten / math.max(p.age, 3)
          local avgX, avgY = info.massX / info.cellCount, info.massY / info.cellCount
          -- assert(avgX == 0)
          fixture, shape = reshape(avgX - size * 0.5, avgY - size * 0.5, math.max(math.sqrt(info.cellCount) * 0.8, 1))
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
      if p.age > 0.5 and info.cellCount <= 5 then
        p.remove()
      end
    end
  end

  local ringAlpha = 0

  function p.draw()
    if hoverAgent == p or sellected or simulation.sortedAgents[1] == p then
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
    for _, agent in pairs(simulation.agents) do
      if agent == p then
        simulation.agents[_] = nil
      end
    end
  end

  return p
end
