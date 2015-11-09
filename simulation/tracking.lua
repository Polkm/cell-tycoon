--This is where we do our data tracking
--TODO :
--Save POPs
--Load POPs
--MAKE G-HUI

--Didn't want to learn your GUI, imported old version from concrete crucible
--feel free to remove it after this project

local fs = love.filesystem

paused = false -- this needs to b used for pausing the game

require("simulation/disposable/panel")

local w = love.graphics.getWidth() / 2
local h = love.graphics.getHeight() - 100

local treb = love.graphics.newFont("fonts/trebuchet.ttf",18)

local mainmenu = {
  --trying a new way to manage a menu, its a table of panels
  save = panel.new({
    x = -105, y = simulation.size + 10,
    size = {100,50},
    text = "save",
    font = treb,
  }),
  load = panel.new({
    x = 5, y = simulation.size + 10,
    size = {100,50},
    text = "load",
    font = treb,
  }),
  pause = panel.new({
    x = 5, y = simulation.size + 70,
    size = {100,50},
    text = "pause",
    font = treb,
  }),
  resume = panel.new({
    x = -105, y = simulation.size + 70,
    size = {100,50},
    text = "resume",
    font = treb,
  }),
}

local save = mainmenu.save
local load = mainmenu.load
local pause = mainmenu.pause
local resume = mainmenu.resume

function saveGame()
  paused = true
  local file, errorstr = fs.newFile("results.txt", "w")
  if (errorstr) then print(errorstr) return end
  print("written")

  file:write("Agent Count : " .. #simulation.agents .. "\r\n")
  file:flush()
  file:close()

  print(fs.getWorkingDirectory())
  print(result)
end

save.onClick = saveGame

for key,panel in pairs(mainmenu) do
  panel.setVisible(false)
end

hook(love, "keyreleased", function(key, unicode)
  if key == "escape" then
    for key,panel in pairs(mainmenu) do
      panel.setVisible(not panel.isVisible())
    end
  end
end)
