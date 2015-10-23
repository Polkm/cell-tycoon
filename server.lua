local inputChannel, outputChannel = ...
local socket = require("socket")
local udp = socket.udp()
udp:settimeout(0)
udp:setsockname('*', 12345)
local peers = {}
while not stoped do
  repeat
    local input = inputChannel:pop()
    if input then
      if input == "die" then return end

      if #peers <= 0 then
        -- Ask mom for more friends to play with
        peers["localhost"] = 12345
      else
        -- Tell all your friends about you're world state
        for address, port in pairs(peers) do
          udp:setpeername(address, port)
          udp:send(input)
        end
      end
    end
  until not input

  socket.sleep(0.01)
end
