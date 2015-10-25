background = {}

local backgroundShader = love.graphics.newShader("simulation/background.frag")
local pixelImage = love.graphics.newImage(love.image.newImageData(1, 1))

function background.draw()
  local screenW, screenY = love.graphics.getDimensions()
  love.graphics.setShader(backgroundShader)
  backgroundShader:send("screen", {screenW, screenY})
  backgroundShader:send("center", {love.graphics.getWidth() * 0.5 - camera.x * camera.z, love.graphics.getHeight() * 0.5 - camera.y * camera.z})
  backgroundShader:send("radius", simulation.size)
  backgroundShader:send("zoom", camera.z)
  backgroundShader:send("rt", love.timer.getTime())
  love.graphics.draw(pixelImage, 0, 0, 0, screenW, screenY)
  love.graphics.setShader()
end
