require("core/global")

require("simulation/simulation")

function love.threaderror(thread, errorstr)
  assert(false, errorstr)
end
