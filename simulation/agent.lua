function agent(p)
  p.maxSize = 64
  p.seed = math.random() * 5436436
  p.id = math.random(0, 432905239867584)
  simulation.agents[p.id] = p
  p.x, p.y, p.z = 0, 0, 0
  p.rot = 0
  p.cellImage = love.graphics.newImage(love.image.newImageData(p.maxSize, p.maxSize))

  local reshape, newBody, fixture, shape = physics.circle(x, y, 0.5, 0.5, "dynamic")
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
  p.celldata = {}

  -- reproduction
  p.maxStrain = 50000
  p.strain = math.random(0,p.maxStrain)
  p.tolerance = 10000
  p.stableAge = 5
  p.rCost = 900
  p.eRate = 6
  p.rRate = 1000
  p.mutateRate = 12
  p.active = true

  foreman.push({func = "init", id = p.id, p.cellImage:getData()})

  -- local thread = love.thread.newThread("simulation/agent_thread.lua")
  -- local inputChannel = love.thread.newChannel()
  -- local outputChannel = love.thread.newChannel()
  -- thread:start(inputChannel, outputChannel, p.cellImage, {seed = p.seed}, p.body)

  function p.setXYZ(nx, ny, nz)
    p.body:setPosition(nx, ny)
    x, y, z = nx, ny, nz or z
  end
  function p.getXYZ() return x, y, z end

  -- Cell manipulation
  function p.setCell(x, y, v)
    foreman.push({func = "set", id = p.id, p.x, p.y, v})
  end

  function p.bite(wx, wy, r, biter)
    local dx, dy = p.x - wx, p.y - wy
    local an = math.atan2(dy, dx) - p.body:getAngle() - math.pi
    local rad = math.sqrt(dx * dx + dy * dy)
    p.body:setUserData(p)
    if not biter or ((not biter.active) or (p.active and math.abs(p.strain - biter.strain) > p.tolerance)) then
      foreman.push({func = "bite", id = p.id, biter ~= nil and biter.id, math.cos(an) * rad + p.maxSize * 0.5, math.sin(an) * rad + p.maxSize * 0.5, r})
    end
  end

  function p.feed(cellMass)
    p.massEaten = p.massEaten + cellMass
    foreman.push({func = "feed", id = p.id, cellMass})
  end

  local function mutate(chance, def, minrange, maxrange)
    if math.random(0,chance) == 0 then
      return def + math.random() * (maxrange-minrange) + minrange
    end
    return def
  end

  function p.reproduce()
    local children = 1

    for i = 1, children do
      local x,y = p.x + math.random() * 2 + -1, p.y + math.random() * 2 + -1
      local child = agent({})
      child.setXYZ(x,y,0)
      child.strain = mutate(8, p.strain, 0, p.maxStrain)
      child.maxStrain = mutate(16, p.maxStrain, 0, p.maxStrain)

      child.tolerance = math.max(p.tolerance - p.massEaten + mutate(p.massEaten, 0, 0, p.maxStrain/100),0)

      local newTypeMap = {}
      local types = {"fat", "mover", "plast", "none"}
      for _, t in pairs(p.typeMap) do
        if math.random(0,p.mutateRate) == 0 then
          local _, randType = table.random(types)
          if (randType == "none") then
            newTypeMap[_] = nil
          else
            newTypeMap[_] = randType
          end
        else
          newTypeMap[_] = t
        end
      end

      foreman.push({func = "recieveTypeMap", id = child.id, p.maxSize, encode(newTypeMap)})
      if (true) then
        foreman.push({func = "decay", id = p.id, p.rCost, p.eRate,})
      end
    end
  end

  function p.update(dt)
    if paused then return end
    if p.body and not p.body:isDestroyed() then
      p.age = p.age + dt

      p.x, p.y = p.body:getPosition()
      p.rot = p.body:getAngle()
      if (p.active and p.age > p.stableAge) then
        if (p.active and math.random(0,p.rRate) == 1) then
          p.reproduce()
        end
      end
      -- Kill yourself if you suck ass at growing or are ded already
      if p.age > 0.5 and p.mass <= 1 then p.remove() return end
    end
  end

  function p.cultureUpdate(cellCount, massEaten, massX, massY, forwardForce, angleForce)
      p.mass = math.max(cellCount or 1, 1)
      p.massEaten = p.massEaten
      p.points = p.massEaten / math.max(p.age, 3)

      massX, massY = massX - p.maxSize * 0.5, massY - p.maxSize * 0.5

      fixture, shape = reshape(massX, massY, math.max(math.sqrt(p.mass) * 0.7, 1))
      p.body:setBullet(true)

      local velX, velY = p.body:getLinearVelocity()
      local angle = p.body:getAngle() - math.pi * 0.5
      local tarX, tarY = math.cos(angle) * forwardForce, math.sin(angle) * forwardForce
      local mass = p.body:getMass()
      p.body:applyLinearImpulse(mass * (tarX - velX), mass * (tarY - velY))
      p.body:applyAngularImpulse(mass * angleForce)
    end

  function p.postSolve(b, coll, normalimpulse1, tangentimpulse1, normalimpulse2, tangentimpulse2)
    if b:getUserData() then
        if b and not b:isDestroyed() and b:getUserData() and not coll:isDestroyed() then
          local x1, y1, x2, y2 = coll:getPositions()
          b:getUserData().bite(x1, y1, 5, p)
        end
    else
      -- Spin around when you hit a wall
      p.body:applyAngularImpulse(1000 * p.body:getMass() * (math.random() < 0.5 and -1 or 1))
    end
  end

  function p.exhaust()
    p.active = false
    p.strain = -50000
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

    p.cellImage:refresh()
    love.graphics.draw(p.cellImage, p.x, p.y, p.rot, 1, 1, p.cellImage:getWidth() * 0.5, p.cellImage:getHeight() * 0.5)
  end

  function p.remove()
    foreman.push({func = "remove", id = p.id})
    p.body:destroy()
    p.body = nil
    for _, agent in pairs(simulation.agents) do
      if agent == p then
        simulation.agents[_] = nil
      end
    end
  end

  function p.updateTypeMap(typeMap)
    p.typeMap = dencode(typeMap)
  end

  function p.updateCellCount(stem, brain, plast, mover)
    p.celldata['numcells'] = (stem + brain + plast + mover)
    p.celldata['stem'] = stem
    p.celldata['brain'] = brain
    p.celldata['plast'] = plast
    p.celldata['mover'] = mover
  end

  return p
end
