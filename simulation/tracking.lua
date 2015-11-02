--This is where we do our data tracking
--TODO :
--Save POPs
--Load POPs
--MAKE G-HUI

--Didn't want to learn your GUI, imported old version from concrete crucible
--feel free to remove it after this project

require("simulation/disposable/panel")

local w = love.graphics.getWidth() / 2
local h = love.graphics.getHeight() - 100

local treb = love.graphics.newFont("fonts/trebuchet.ttf",18)

local mainmenu = {
  --trying a new way to manage a menu, its a table of panels
  save = panel.new({
    x = w - 150 , y = h,
    size = {100,50},
    text = "save",
    font = treb,
  }),
  load = panel.new({
    x = w + 50 , y = h,
    size = {100,50},
    text = "load",
    font = treb,
  }),
}

local save = mainmenu.save
local load = mainmenu.load

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
