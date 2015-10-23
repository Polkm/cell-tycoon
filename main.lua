require("god")

require("sim")

local serverIn, serverOut, serverThread = love.thread.newChannel(), love.thread.newChannel(), love.thread.newThread("server.lua")
local clientIn, clientOut, clientThread = love.thread.newChannel(), love.thread.newChannel(), love.thread.newThread("client.lua")

function love.load()
  serverThread:start(serverIn, serverOut)
  clientThread:start(clientIn, clientOut)
end

function love.quit()
  serverIn:push("die")
  serverThread:wait()
  clientIn:push("die")
  clientThread:wait()
end

function love.threaderror(thread, errorstr)
  assert(false, errorstr)
end
