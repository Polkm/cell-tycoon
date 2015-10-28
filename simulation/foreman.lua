local idealThreads = love.system.getProcessorCount()

foreman = {}

local workers = {}

local function newWorkerThread()
  local input, output = love.thread.newChannel(), love.thread.newChannel()
  local thread = love.thread.newThread("simulation/worker.lua")
  table.insert(workers, {thread = thread, input = input, output = output})
  thread:start(input, output)
end

function foreman.push(event)
  workers[(event.id % #workers) + 1].input:push(event)
end

hook(love, "load", function()
  for i = 1, idealThreads do newWorkerThread() end
end)

hook(love, "update", function(dt)
  local rad = math.max(love.graphics.getDimensions())

  -- Push updates
  for _, worker in pairs(workers) do
    worker.input:push({func = "update", dt})
  end

  -- Get worker output
  for _, worker in pairs(workers) do
    local inputs = {}
    repeat
      local input = worker.output:pop()
      if input then
        inputs[#inputs + 1] = input
      end
    until not input

    for i = #inputs, 1, -1 do
      local input = inputs[i]
      local func = input.func
      local id = input.id
      -- assert(false, input.func)
      input.func = nil
      input.id = nil

      if id and func and simulation.agents[id] then
        simulation.agents[id][func](unpack(input))
      -- elseif func then
      --   p[func](unpack(input))
      end
    end
  end
end)
