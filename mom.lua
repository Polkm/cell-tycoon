local inputChannel, outputChannel = ...
local socket = require("socket")
local udp = socket.udp()
udp:settimeout(0)
udp:setsockname('*', 12345)

local children = {}

while not stoped do
  local input = inputChannel:pop()
  if input then
    if input == "die" then
      return
    end
  end

  local data, msg_or_ip, port_or_nil = udp:receivefrom()
  if data then
    peers[msg_or_ip] = port_or_nil

  end

  socket.sleep(0.01)
end
