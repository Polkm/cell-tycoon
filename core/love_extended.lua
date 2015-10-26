love.graphics.setDefaultFilter("nearest", "nearest")

function love.image.eachPixel(img, callback)
  if not img then return end
  local imageData = img:getData()
  for ix = 0, imageData:getWidth() - 1 do
    for iy = 0, imageData:getHeight() - 1 do
      local r, g, b, a = imageData:getPixel(ix, iy)
      callback(ix, iy, r, g, b, a)
    end
  end
end

function love.image.minmax(img)
  local minx, miny, maxx, maxy
  love.image.eachPixel(img, function(x, y, r, g, b, a)
    if a == 255 then
      if not minx or minx > x then minx = x end
      if not maxx or maxx < x then maxx = x end
      if not miny or miny > y then miny = y end
      if not maxy or maxy < y then maxy = y end
    end
  end)
  return minx, miny, maxx, maxy
end

function love.load() end
function love.update(dt) end
function love.draw() end
function love.mousepressed(x, y, button) end
function love.mousereleased(x, y, button) end
function love.mousemoved(x, y, dx, dy) end
