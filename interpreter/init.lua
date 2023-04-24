local module = {}

local function traceUnaryOp(trace, operator, value)
  if trace then
    trace[#trace + 1] = operator .. ' ' .. value
  end
end

local function traceBinaryOp(trace, operator, stack, top)
  if trace then
    trace[#trace + 1] = operator .. ' ' .. stack[top - 1] .. ' ' .. stack[top]
  end
end

-- Output the code at the given pc and the next num instructions.
local function traceTwoCodes(trace, code, pc)
  if type(trace) == 'table' then
    trace[#trace + 1] = code[pc] .. ' ' .. code[pc + 1]
  end
end

local function popStack(stack, top, amount)
  for i = top + amount - 1, top, -1 do
    stack[top] = nil
    top = top - 1
  end
  return top
end

function module.run(code, trace)
  local stack = {}
  local memory = {}
  local pc = 1
  local top = 0
  while pc <= #code do
    --[[
    io.write '--> '
    for i = 1, top do io.write(stack[i], ' ') end
    io.write '\n'
    ]]
    if code[pc] == 'push' then
      traceTwoCodes(trace, code, pc)
      pc = pc + 1
      top = top + 1
      stack[top] = code[pc]
    elseif code[pc] == 'add' then
      traceBinaryOp(trace, code[pc], stack, top)
      stack[top - 1] = stack[top - 1] + stack[top]
      top = popStack(stack, top, 1)
    elseif code[pc] == 'subtract' then
      traceBinaryOp(trace, code[pc], stack, top)
      stack[top - 1] = stack[top - 1] - stack[top]
      top = popStack(stack, top, 1)
    elseif code[pc] == 'multiply' then
      traceBinaryOp(trace, code[pc], stack, top)
      stack[top - 1] = stack[top - 1] * stack[top]
      top = popStack(stack, top, 1)
    elseif code[pc] == 'divide' then
      traceBinaryOp(trace, code[pc], stack, top)
      stack[top - 1] = stack[top - 1] / stack[top]
      top = popStack(stack, top, 1)
    elseif code[pc] == 'modulus' then
      traceBinaryOp(trace, code[pc], stack, top)
      stack[top - 1] = stack[top - 1] % stack[top]
      top = popStack(stack, top, 1)
    elseif code[pc] == 'exponent' then
      traceBinaryOp(trace, code[pc], stack, top)
      stack[top - 1] = stack[top - 1] ^ stack[top]
      top = popStack(stack, top, 1)
    elseif code[pc] == 'greater' then
      traceBinaryOp(trace, code[pc], stack, top)
      stack[top - 1] = stack[top - 1] > stack[top] and 1 or 0
      top = popStack(stack, top, 1)
    elseif code[pc] == 'less' then
      traceBinaryOp(trace, code[pc], stack, top)
      stack[top - 1] = stack[top - 1] < stack[top] and 1 or 0
      top = popStack(stack, top, 1)
    elseif code[pc] == 'greaterOrEqual' then
      traceBinaryOp(trace, code[pc], stack, top)
      stack[top - 1] = stack[top - 1] >= stack[top] and 1 or 0
      top = popStack(stack, top, 1)
    elseif code[pc] == 'lessOrEqual' then
      traceBinaryOp(trace, code[pc], stack, top)
      stack[top - 1] = stack[top - 1] <= stack[top] and 1 or 0
      top = popStack(stack, top, 1)
    elseif code[pc] == 'equal' then
      traceBinaryOp(trace, code[pc], stack, top)
      stack[top - 1] = stack[top - 1] == stack[top] and 1 or 0
      top = popStack(stack, top, 1)
    elseif code[pc] == 'notEqual' then
      traceBinaryOp(trace, code[pc], stack, top)
      stack[top - 1] = stack[top - 1] ~= stack[top] and 1 or 0
      top = popStack(stack, top, 1)
    elseif code[pc] == 'negate' then
      traceUnaryOp(trace, code[pc], stack[top])
      stack[top] = -stack[top]
    elseif code[pc] == 'not' then
      traceUnaryOp(trace, code[pc], stack[top])
      if stack[top] == 0 then
        stack[top] = 1
      else
        stack[top] = 0
      end
    elseif code[pc] == 'load' then
      traceTwoCodes(trace, code, pc)
      top = top + 1
      pc = pc + 1
      stack[top] = memory[code[pc] ]
    elseif code[pc] == 'store' then
      traceTwoCodes(trace, code, pc)
      pc = pc + 1
      memory[code[pc] ] = stack[top]
      top = popStack(stack, top, 1)
    elseif code[pc] == 'newArray' then
      -- The size of the new array is on the top of the stack
      local size = stack[top]
      -- We replace the top of the stack with the new array
      stack[top] = { size = size }
      for i = 1,10 do
        stack[top][i] = 0
      end
    elseif code[pc] == 'setArray' then
      -- Which array we're getting is two elements below
      local array = stack[top - 2]
      -- The index in the array is one element below
      local index = stack[top - 1]
      -- Finally, the value we're setting to the array is at the top.
      local value = stack[top - 0]
      
      if index > array.size or index < 1 then
        error('Out of range. Array is size ' .. array.size .. ' but indexed at ' .. index .. '.')
      end
      
      -- Set the array to this value
      array[index] = value

      -- Pop the three things
       top = popStack(stack, top, 3)
   elseif code[pc] == 'getArray' then
      -- The array we are getting is one element below 
      local array = stack[top - 1]
      -- The index we're getting from the array is at the top
      local index = stack[top - 0]
      -- We have consumed two things, but we're about to add one:
      -- so just decrement by one to simulate popping two and pushing one.
      top = popStack(stack, top, 1)
      
      if index > array.size or index < 1 then
        error('Out of range. Array is size ' .. array.size .. ' but indexed at ' .. index .. '.')
      end
      
      -- Set the top of the stack to the value of this index of the array.
      -- This is also now the index of where the array we loaded from was located,
      -- so it has the benefit of removing the reference to that array from the stack.
      stack[top] = array[index]
    elseif code[pc] == 'jumpIfZero' then
      traceTwoCodes(trace, code, pc)
      pc = pc + 1
      if stack[top] == 0 then
        pc = pc + code[pc]
      end
      top = popStack(stack, top, 1)
    elseif code[pc] == 'jump' then
      traceTwoCodes(trace, code, pc)
      pc = pc + 1
      pc = pc + code[pc]
    elseif code[pc] == 'jumpIfZeroJumpNoPop' then
      traceTwoCodes(trace, code, pc)
      pc = pc + 1
      if stack[top] == 0 then
        pc = pc + code[pc]
      else
        top = popStack(stack, top, 1)
      end
    elseif code[pc] == 'jumpIfNonzeroJumpNoPop' then
      traceTwoCodes(trace, code, pc)
      pc = pc + 1
      if stack[top] ~= 0 then
        pc = pc + code[pc]
      else
        top = popStack(stack, top, 1)
      end
    elseif code[pc] == 'print' then
      traceUnaryOp(trace, code[pc], stack[top])
      if type(stack[top]) == 'table' then
        io.write '['
        for i = 1, stack[top].size - 1 do
          io.write(stack[top][i] .. ', ')
        end
        io.write(stack[top][stack[top].size] .. ']')
      else
        print(stack[top])
      end
      top = popStack(stack, top, 1)
    elseif code[pc] == 'return' then
      traceUnaryOp(trace, code[pc], stack[top])
      -- Do it this way because return will probably not always exit the program...
      local returnValue = stack[top]
      top = popStack(stack, top, 1)
      return returnValue
    else error 'unknown instruction'
    end
    pc = pc + 1
  end
end

return module