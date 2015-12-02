function genome(p)
  local typeMap = {}
  local maxSize = p.maxSize

  p.fatStartEnergy = 1000
  p.maxPlastEnegry = 1000

  local function setTypeMap(x, y, v)
    typeMap[math.floor(x) + math.floor(y) * maxSize] = v
  end
  p.setTypeMap = setTypeMap

  local function getTypeMap(x, y)
    return typeMap[math.floor(x) + math.floor(y) * maxSize]
  end
  p.getTypeMap = getTypeMap

  function p.setRandomTypeMap()
    local types = {"fat", "mover"}

    setTypeMap(p.maxSize * 0.5, p.maxSize * 0.5, "brain")

    for i = 1, math.randomn(100, 10) do
      local i, randType = table.random(typeMap)
      local x, y = i % maxSize + math.random(-1, 1), math.floor(i / maxSize) + math.random(-1, 1)
      if not getTypeMap(x, y) then
        local _, randType = table.random(types)
        setTypeMap(x, y, randType)
        if randType == "fat" then
          p.fatStartEnergy = p.fatStartEnergy * 0.5
        end
      end
    end
  end

  return p
end
