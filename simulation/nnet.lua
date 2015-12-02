function nnet(p)
  p.inputs = p.inputs or {}
  p.layers = p.layers or {}
  p.outputs = p.outputs or {}

  function p.randomize()
    for k, v in pairs(p.inputs) do
      p.inputs[k] = {math.random()}
    end
    for _, layer in pairs(p.layers) do
      for k, v in pairs(layer) do
        layer[k] = {math.random()}
      end
    end
  end

  function p.activation(x)
    return math.tanh(x)
  end

  function p.forward(input)
    
  end

  p.forward({sense1 = 0.5, sense2 = 0, sense3 = 0.2})


  return p
end
