physics = {}

love.physics.setMeter(32)

world = love.physics.newWorld(0, 0, true)

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


function physics.rectangle(x, y, w, h, type)
  return love.physics.newFixture(love.physics.newBody(world, x, y, type or "dynamic"), love.physics.newRectangleShape(0, 0, w, h)):getBody()
end

function physics.circle(x, y, w, h, type)
  local body = love.physics.newBody(world, x, y, type or "dynamic")
  local fixture
  local function reshape(px, py, r)
    if fixture and not fixture:isDestroyed() then fixture:destroy() end
    local shape = love.physics.newCircleShape(clamp(px, -100, 100), clamp(py, -100, 100), math.min(math.max(r, 1.0), 100))
    fixture = love.physics.newFixture(body, shape)
    fixture:setCategory(1)
    fixture:setFriction(0)
    return fixture, shape
  end
  return reshape, body, reshape(0, 0, math.max(w, h))
end
