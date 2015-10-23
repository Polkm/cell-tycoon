require("cache")

bind = setmetatable({}, {
  __index = function(t, state)
    return setmetatable({}, {
      __index = function(tt, key)
        return function(action)
          local actions = cache.get.binds(state, key)
          if not actions then actions = {} end
          table.insert(actions, action)
          cache.set.binds(state, key, actions)
        end
      end
    })
  end
})

local function trigger(state, key, input)
  local actions = cache.get.binds(state, key)
  if actions then
    for _, action in pairs(actions) do
      action(input)
    end
  end
end

function love.keypressed(key, isrepeat)
  trigger("pressed", key, {isrepeat = isrepeat})
end

function love.keyreleased(key)
  trigger("released", key, {isrepeat = isrepeat})
end

function love.mousepressed(x, y, button)
  trigger("pressed", button .. "mouse", {x = x, y = y})
end

function love.mousereleased(x, y, button)
  trigger("released", button .. "mouse", {x = x, y= y})
end




bind.released.q(function(input)
  assert(false, encode({test = "hiworld", makeme = {hapy = "plz"}}))
end)
