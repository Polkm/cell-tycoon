scoreboard = {}

local stats = gui.list({
  x = simulation.size + 16, y = -simulation.size,
  vertical = false,
  padding = 10,
  list = {{text = "name"}, {text = "age"}, {text = "mass"}, {text = "massEaten"}},
  child = function(tbl)
    return gui.column({
      text = tbl.text,
      child = function(agent)
        local label = gui.label({})
        hook(label, "update", function(dt)
          label.text = math.floor(agent[tbl.text])
        end)
        return label
      end
    })
  end
})

hook(stats, "update", function(dt)
  local columnWidths = {}
  simulation.sortedAgents = {}

  for _, agent in pairs(simulation.agents) do
    simulation.sortedAgents[#simulation.sortedAgents + 1] = agent
  end

  local bufferY = 50
  local lineHeight = 18 --math.min((love.graphics.getHeight() - bufferY * 2) / (7*7), 16)
  local sortStat = "points"
  table.sort(simulation.sortedAgents, function(a, b)
    return (a[sortStat] or 0) > (b[sortStat] or 0)
  end)

  for _, column in pairs(stats.children) do
    column.list = simulation.sortedAgents
  end
end)

function scoreboard.update(dt)
  local screenW, screenY = love.graphics.getDimensions()

  -- love.graphics.setColor(255, 255, 255, 255)
  -- love.graphics.setInvertedStencil(function()
  --   love.graphics.push()
  --   love.graphics.clear()
  --   love.graphics.translate(love.graphics.getWidth() * 0.5, love.graphics.getHeight() * 0.5)
  --   love.graphics.scale(camera.z, camera.z)
  --   love.graphics.translate(-camera.x, -camera.y)
  --   love.graphics.circle("fill", 0, 0, simulation.size, 100)
  --   love.graphics.pop()
  -- end)

  -- if simulation.agents[1] then
  --   local x = screenW - 300
  --   love.graphics.setColor(180, 180, 180, 255)
  --   for ii, stat in pairs(simulation.agents[1].getStats()) do
  --     gui(x, bufferY, translate(statsToNames[ii]))
  --     x = x + columnWidths[ii] + 10
  --   end
  --   for _, agent in pairs(simulation.agents) do
  --     local c = 1
  --     for i, check in pairs(simulation.sortedAgents) do
  --       if agent == check then break end
  --       c = c + 1
  --     end
  --     x = screenW - 300
  --     for ii, stat in pairs(simulation.agents[1].getStats()) do
  --       if hoverAgent == agent then
  --         love.graphics.setColor(255, 255, 255, 255)
  --       elseif agent.getSellected() then
  --         love.graphics.setColor(230, 230, 230, 255)
  --       else
  --         love.graphics.setColor(180, 180, 180, 255)
  --       end
  --       gui(x, bufferY + c * lineHeight, (agent.getStats())[ii])
  --       x = x + columnWidths[ii] + 10
  --     end
  --   end
  -- end
  --
  -- guisDraw()

  -- love.graphics.setInvertedStencil(nil)
end
