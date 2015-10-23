local inputChannel, outputChannel = ...
local socket = require("socket")
local address, port = "localhost", 12345
local udp = socket.udp()
udp:settimeout(0)
local peers = {}
while not stoped do
  local input = inputChannel:pop()
  if input then
    if input == "die" then return end
  end

  repeat
    local state, msg_or_ip, port_or_nil = udp:receivefrom()
    if state then
      outputChannel:push({state = state, ip = msg_or_ip, port = port_or_nil})
    end
  until not state

  socket.sleep(0.01)
end
