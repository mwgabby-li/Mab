local common = require 'common'

local module = {}

-- For if we want to align array elements by printed length
local function calculatePad(array)
  return 0
end

local function printValue(array, depth, pad, last)
  pad = pad or calculatePad(array)
  
  if type(array) ~= 'table' then
    io.write(tostring(array))
    return
  end

  depth = depth or 0
  if depth > 0 then
    io.write '\n'
  end
  io.write( (' '):rep(depth) .. '[' )
  
  for i = 1,#array - 1 do
    printValue(array[i], depth + 1, pad)
    io.write ','
    if type(array[i]) ~= 'table' then
      io.write ' '
    end
  end
  printValue(array[#array], depth + 1, pad, true)

  io.write ']'
  
  if last then
    io.write('\n' .. (' '):rep(depth - 1))
  end
end

local StackVM = {}

function StackVM:new(o)
  o = o or {
    stack = {},
    top = 0,
    memory = {},
  }
  self.__index = self
  setmetatable(o, self)
  return o
end

function StackVM:addError(...)
  if self.errorReporter then
    self.errorReporter:addError(...)
  end
end

function StackVM:traceUnaryOp(operator)
  if self.trace then
    self.trace[#self.trace + 1] = operator .. ' ' .. tostring(self.stack[self.top])
  end
end

function StackVM:traceBinaryOp(operator)
  if self.trace then
    self.trace[#self.trace + 1] = operator .. ' ' .. tostring(self.stack[self.top - 1]) .. ' ' .. tostring(self.stack[self.top])
  end
end

function StackVM:traceTwoCodes(code, pc)
  if self.trace then
    self.trace[#self.trace + 1] = code[pc] .. ' ' .. tostring(code[pc + 1])
  end
end

function StackVM:traceTwoCodesAndStack(code, pc)
  if self.trace then
    self.trace[#self.trace + 1] = code[pc] .. ' ' .. tostring(code[pc + 1]) .. ' ' .. tostring(self.stack[self.top])
  end
end

function StackVM:traceCustom(string)
  if self.trace then
    self.trace[#self.trace + 1] = string
  end
end

function StackVM:traceStack()
  if self.trace then
    local result = {}
    for k,v in ipairs(self.stack) do
      result[k] = v
    end

    self.trace.stack[#self.trace] = result
  end
end

function StackVM:popStack(amount)
  for i = self.top + amount - 1, self.top, -1 do
    self.stack[self.top] = nil
    self.top = self.top - 1
  end
end

function StackVM:run(code)
  local pc = 1
  local base = self.top
  while pc <= #code do
    --[[
    io.write '--> '
    for i = 1, self.top do io.write(self.stack[i], ' ') end
    io.write '\n'
    --]]
    if code[pc] == 'push' then
      self:traceTwoCodes(code, pc)
      pc = pc + 1
      self.top = self.top + 1
      self.stack[self.top] = code[pc]
    elseif code[pc] == 'pop' then
      self:traceTwoCodes(code, pc)
      pc = pc + 1
      self:popStack(code[pc])
    elseif code[pc] == 'add' then
      self:traceBinaryOp(code[pc])
      self.stack[self.top - 1] = self.stack[self.top - 1] + self.stack[self.top]
      self:popStack(1)
    elseif code[pc] == 'subtract' then
      self:traceBinaryOp(code[pc])
      self.stack[self.top - 1] = self.stack[self.top - 1] - self.stack[self.top]
      self:popStack(1)
    elseif code[pc] == 'multiply' then
      self:traceBinaryOp(code[pc])
      self.stack[self.top - 1] = self.stack[self.top - 1] * self.stack[self.top]
      self:popStack(1)
    elseif code[pc] == 'divide' then
      self:traceBinaryOp(code[pc])
      self.stack[self.top - 1] = self.stack[self.top - 1] / self.stack[self.top]
      self:popStack(1)
    elseif code[pc] == 'modulus' then
      self:traceBinaryOp(code[pc])
      self.stack[self.top - 1] = self.stack[self.top - 1] % self.stack[self.top]
      self:popStack(1)
    elseif code[pc] == 'exponent' then
      self:traceBinaryOp(code[pc])
      self.stack[self.top - 1] = self.stack[self.top - 1] ^ self.stack[self.top]
      self:popStack(1)
    elseif code[pc] == 'greater' then
      self:traceBinaryOp(code[pc])
      self.stack[self.top - 1] = self.stack[self.top - 1] > self.stack[self.top]
      self:popStack(1)
    elseif code[pc] == 'less' then
      self:traceBinaryOp(code[pc])
      self.stack[self.top - 1] = self.stack[self.top - 1] < self.stack[self.top]
      self:popStack(1)
    elseif code[pc] == 'greaterOrEqual' then
      self:traceBinaryOp(code[pc])
      self.stack[self.top - 1] = self.stack[self.top - 1] >= self.stack[self.top]
      self:popStack(1)
    elseif code[pc] == 'lessOrEqual' then
      self:traceBinaryOp(code[pc])
      self.stack[self.top - 1] = self.stack[self.top - 1] <= self.stack[self.top]
      self:popStack(1)
    elseif code[pc] == 'equal' then
      self:traceBinaryOp(code[pc])
      self.stack[self.top - 1] = self.stack[self.top - 1] == self.stack[self.top]
      self:popStack(1)
    elseif code[pc] == 'notEqual' then
      self:traceBinaryOp(code[pc])
      self.stack[self.top - 1] = self.stack[self.top - 1] ~= self.stack[self.top]
      self:popStack(1)
    elseif code[pc] == 'negate' then
      self:traceUnaryOp(code[pc])
      self.stack[self.top] = -self.stack[self.top]
    elseif code[pc] == 'not' then
      self:traceUnaryOp(code[pc])
      self.stack[self.top] = not self.stack[self.top]
    elseif code[pc] == 'load' then
      self:traceTwoCodes(code, pc)
      self.top = self.top + 1
      pc = pc + 1
      self.stack[self.top] = self.memory[code[pc] ]
    elseif code[pc] == 'loadLocal' then
      self:traceTwoCodes(code, pc)
      -- Get the stack ready to place the value
      self.top = self.top + 1
      -- Get the next instruction, which will have the local's index
      pc = pc + 1
      -- Set the top of the stack to the local variable from our frame
      self.stack[self.top] = self.stack[base + code[pc] ]
    elseif code[pc] == 'store' then
      self:traceTwoCodesAndStack(code, pc)
      pc = pc + 1
      self.memory[code[pc] ] = self.stack[self.top]
      self:popStack(1)
    elseif code[pc] == 'storeLocal' then
      self:traceTwoCodesAndStack(code, pc)
      pc = pc + 1
      self.stack[base + code[pc] ] = self.stack[self.top]
      self:popStack(1)
    elseif code[pc] == 'newArray' then
      self:traceCustom(code[pc])
      -- Our size is on the top of the stack
      local size = self.stack[self.top]
      -- The default value for all our elements is the next stack element
      local defaultValue = self.stack[self.top - 1]

      local array = {size=size}
      for i = 1,size do
        array[i] = common.copyObjectNoSelfReferences(defaultValue)
      end

      -- We take two elements, but we are about to add one, so pop one element,
      self:popStack(1)
      -- then overwrite the next one!
      self.stack[self.top] = array
      -- We consumed our default value from the stack, then pushed ourself, so no changes to the stack size.
    elseif code[pc] == 'setArray' then
      -- Which array we're getting is two elements below
      local array = self.stack[self.top - 2]
      -- The index in the array is one element below
      local index = self.stack[self.top - 1]
      -- Finally, the value we're setting to the array is at the top.
      local value = self.stack[self.top - 0]
      
      self:traceCustom(code[pc] .. ' ' .. '[' .. index .. '] = ' .. tostring(value))

      if index > array.size or index < 1 then
        self:addError('Out of range. Array is size ' .. array.size .. ' but indexed at ' .. index .. '.')
      end
      
      -- Set the array to this value
      array[index] = value

      -- Pop the three things
       self:popStack(3)
   elseif code[pc] == 'getArray' then
      -- The array we are getting is one element below 
      local array = self.stack[self.top - 1]
      -- The index we're getting from the array is at the top
      local index = self.stack[self.top - 0]

      self:traceCustom(code[pc] .. ' ' .. '[' .. index .. ']')
      
      -- We have consumed two things, but we're about to add one:
      -- so just decrement by one to simulate popping two and pushing one.
      self:popStack(1)
      
      if index > array.size or index < 1 then
        self:addError('Out of range. Array is size ' .. array.size .. ' but indexed at ' .. index .. '.')
      end
      
      -- Set the top of the stack to the value of this index of the array.
      -- This is also now the index of where the array we loaded from was located,
      -- so it has the benefit of removing the reference to that array from the stack.
      self.stack[self.top] = array[index]
    elseif code[pc] == 'jump' then
      self:traceTwoCodes(code, pc)
      pc = pc + 1
      pc = pc + code[pc]
    elseif code[pc] == 'jumpIfFalse' then
      self:traceTwoCodesAndStack(code, pc)
      pc = pc + 1
      if not self.stack[self.top] then
        pc = pc + code[pc]
      end
      self:popStack(1)
    elseif code[pc] == 'jumpIfFalseJumpNoPop' then
      self:traceTwoCodesAndStack(code, pc)
      pc = pc + 1
      if not self.stack[self.top] then
        pc = pc + code[pc]
      else
        self:popStack(1)
      end
    elseif code[pc] == 'jumpIfTrueJumpNoPop' then
      self:traceTwoCodesAndStack(code, pc)
      pc = pc + 1
      if self.stack[self.top] then
        pc = pc + code[pc]
      else
        self:popStack(1)
      end
    elseif code[pc] == 'print' then
      self:traceUnaryOp(code[pc])
      printValue(self.stack[self.top])
      io.write '\n'
      self:popStack(1)
    elseif code[pc] == 'return' then
      self:traceCustom('return' .. (code[pc] == 0 and '' or ', pop ' .. code[pc + 1]))
      pc = pc + 1
      local pop = code[pc]
      for i=self.top - pop,self.top do
        self.stack[i] = self.stack[i + pop]
      end
      self:popStack(pop)
      self:traceStack()
      return
    elseif code[pc] == 'callFunction' then
      self:traceCustom(code[pc])
      self:traceStack()
      pc = pc + 1
      self:run(code[pc])
    else
      self:addError('Unknown instruction "'..code[pc]..'."')
    end
    self:traceStack()
    pc = pc + 1
  end
end

function StackVM:execute(code)
  self:run(code)
  
  if self.top ~= 1 then
    self:addError('Internal error: Expected stack size of one at the end of the program, but stack size is '..
                  common.toReadableNumber(self.top)..'.')
  end
  
  return self.stack[self.top]
end

function module.execute(code, parameters)
  local interpreter = StackVM:new()
  interpreter.errorReporter = common.ErrorReporter:new()
  if parameters then
    interpreter.errorReporter.stopAtFirstError = parameters.stopAtFirstError
    if parameters.show.trace ~= nil then
      interpreter.trace = {stack = {}}
    end
  end

  return interpreter.errorReporter,
         interpreter.errorReporter:pcallAddErrorOnFailure(interpreter.execute, interpreter, code),
         interpreter.trace
end

return module